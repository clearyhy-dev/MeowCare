from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore
from google.cloud.firestore_v1.query import Query as FirestoreQuery

from app.dependencies import require_admin

router = APIRouter()
db = firestore.client()


def _get_post_ref(post_id: str):
    if not post_id or not post_id.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="post_id required")
    ref = db.collection("posts").document(post_id.strip())
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return ref


@router.post("")
async def create_official_post(body: dict[str, Any], uid: str = Depends(require_admin)):
    ref = db.collection("posts").document()
    data = {
        "type": "official",
        "status": body.get("status", "draft"),
        "title": body.get("title", ""),
        "summary": body.get("summary", ""),
        "content": body.get("content", ""),
        "coverUrl": body.get("coverUrl", ""),
        "breedIds": body.get("breedIds", []),
        "topics": body.get("topics", []),
        "authorId": uid,
        "likeCount": 0,
        "commentCount": 0,
        "score": 0.0,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }
    ref.set(data)
    return {"postId": ref.id}


@router.put("/{post_id}")
async def update_post(post_id: str, body: dict[str, Any], uid: str = Depends(require_admin)):
    ref = _get_post_ref(post_id)
    upd = {"updatedAt": firestore.SERVER_TIMESTAMP}
    for key in ("title", "summary", "content", "coverUrl", "breedIds", "topics"):
        if key in body:
            upd[key] = body[key]
    ref.update(upd)
    return {"ok": True}


@router.post("/{post_id}/publish")
async def publish_post(post_id: str, uid: str = Depends(require_admin)):
    ref = _get_post_ref(post_id)
    ref.update({"status": "published", "updatedAt": firestore.SERVER_TIMESTAMP})
    return {"ok": True}


@router.post("/{post_id}/unpublish")
async def unpublish_post(post_id: str, uid: str = Depends(require_admin)):
    ref = _get_post_ref(post_id)
    ref.update({"status": "draft", "updatedAt": firestore.SERVER_TIMESTAMP})
    return {"ok": True}


@router.get("")
async def list_posts_admin(
    limit: int = 20,
    order: str = "latest",
    start_after_id: str | None = None,
    uid: str = Depends(require_admin),
):
    """管理员分页拉取帖子列表（最新或热门），用于后台「最新/热门管理」."""
    limit = min(max(1, limit), 100)
    coll = db.collection("posts")
    q = coll.where("status", "==", "published")
    if order == "hot":
        q = q.order_by("score", direction=FirestoreQuery.DESCENDING)
    else:
        q = q.order_by("createdAt", direction=FirestoreQuery.DESCENDING)

    if start_after_id:
        start_ref = coll.document(start_after_id)
        start_doc = start_ref.get()
        if start_doc.exists:
            q = q.start_after(start_doc)
    q = q.limit(limit)
    docs = list(q.stream())
    items = []
    for d in docs:
        data = d.to_dict() or {}
        created = data.get("createdAt")
        if hasattr(created, "isoformat"):
            created = created.isoformat()
        items.append({
            "postId": d.id,
            "title": data.get("title", ""),
            "summary": data.get("summary", ""),
            "status": data.get("status", ""),
            "createdAt": created,
            "score": data.get("score", 0),
            "likeCount": data.get("likeCount", 0),
        })
    return {"items": items, "nextStartAfterId": docs[-1].id if len(docs) == limit else None}


@router.delete("/{post_id}")
async def delete_post(post_id: str, uid: str = Depends(require_admin)):
    """管理员删除帖子（从最新/热门中移除该条数据）."""
    ref = _get_post_ref(post_id)
    ref.delete()
    return {"ok": True}


