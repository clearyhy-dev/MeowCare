from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

from app.dependencies import require_admin

router = APIRouter()
db = firestore.client()


def _get_post_ref(post_id: str):
    if not post_id or not post_id.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="post_id required")
    ref = db.collection("posts").document(post_id.strip())
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return ref


@router.get("/pending")
async def list_pending(uid: str = Depends(require_admin)):
    docs = db.collection("posts").where("type", "==", "ugc").where("status", "==", "pending").limit(50).stream()
    return [{"postId": d.id, **d.to_dict()} for d in docs]


@router.post("/{post_id}/approve")
async def approve(post_id: str, uid: str = Depends(require_admin)):
    ref = _get_post_ref(post_id)
    ref.update({"status": "published", "updatedAt": firestore.SERVER_TIMESTAMP})
    return {"ok": True}


@router.post("/{post_id}/reject")
async def reject(post_id: str, uid: str = Depends(require_admin)):
    ref = _get_post_ref(post_id)
    ref.update({"status": "rejected", "updatedAt": firestore.SERVER_TIMESTAMP})
    return {"ok": True}
