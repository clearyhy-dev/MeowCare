from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore
from pydantic import BaseModel

from app.dependencies import require_admin

router = APIRouter()
db = firestore.client()


def _get_report_ref(report_id: str):
    if not report_id or not report_id.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="report_id required")
    ref = db.collection("reports").document(report_id.strip())
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return ref


class ResolveBody(BaseModel):
    adminNote: str | None = None


@router.get("/open")
async def list_open(uid: str = Depends(require_admin)):
    docs = db.collection("reports").where("status", "==", "open").limit(50).stream()
    return [{"reportId": d.id, **d.to_dict()} for d in docs]


@router.post("/{report_id}/resolve")
async def resolve(report_id: str, body: ResolveBody, uid: str = Depends(require_admin)):
    ref = _get_report_ref(report_id)
    ref.update({"status": "resolved", "adminNote": body.adminNote})
    return {"ok": True}

