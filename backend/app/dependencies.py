"""Firebase auth and admin check; admin panel JWT."""
import os
from typing import Annotated

import firebase_admin
from firebase_admin import auth
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import GOOGLE_APPLICATION_CREDENTIALS, SECRET_KEY

if not firebase_admin._apps:
    if GOOGLE_APPLICATION_CREDENTIALS and os.path.isfile(GOOGLE_APPLICATION_CREDENTIALS):
        firebase_admin.initialize_app(options={"projectId": os.getenv("FIREBASE_PROJECT_ID")})
    else:
        project_id = os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("FIREBASE_PROJECT_ID")
        if project_id:
            firebase_admin.initialize_app(options={"projectId": project_id})
        else:
            firebase_admin.initialize_app()


security = HTTPBearer(auto_error=False)


def _verify_admin_jwt(token: str) -> str | None:
    """Verify admin panel JWT; return 'admin' if valid else None."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        if payload.get("sub") == "admin":
            return "admin"
    except Exception:
        pass
    return None


async def get_identity(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> str | None:
    """Return Firebase uid, or 'admin' if valid admin JWT, else None."""
    if not credentials or not credentials.credentials:
        return None
    raw = credentials.credentials
    # Admin JWT: try first (no Firebase token has exactly 3 base64 parts with our secret)
    identity = _verify_admin_jwt(raw)
    if identity:
        return identity
    try:
        decoded = auth.verify_id_token(raw)
        return decoded.get("uid")
    except Exception:
        return None


async def get_uid(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> str | None:
    """Legacy: same as get_identity for compatibility."""
    return await get_identity(credentials)


async def require_uid(identity: Annotated[str | None, Depends(get_identity)]) -> str:
    if not identity:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or missing token")
    return identity


def is_admin(uid: str) -> bool:
    """Check admin: panel identity or Firebase custom claims / admins collection."""
    if uid == "admin":
        return True
    try:
        user = auth.get_user(uid)
        return user.custom_claims.get("admin") is True
    except Exception:
        pass
    try:
        from firebase_admin import firestore
        db = firestore.client()
        return db.collection("admins").document(uid).get().exists
    except Exception:
        return False


async def require_admin(identity: Annotated[str | None, Depends(get_identity)]) -> str:
    if not identity:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    if not is_admin(identity):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin required")
    return identity


