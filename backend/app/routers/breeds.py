from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import firestore

from app.dependencies import is_admin, require_admin, require_uid

# Compatibility-only router:
# kept to avoid breaking old clients/admin scripts, but no longer part of
# primary product flow.
router = APIRouter(
    deprecated=True,
)
db = firestore.client()

ALLOWED_BREED_UPDATE_KEYS = frozenset({"name", "localeNames", "enabled", "order"})


def _get_breed_ref(breed_id: str):
    if not breed_id or not breed_id.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="breed_id required")
    ref = db.collection("breeds").document(breed_id.strip())
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    return ref

# 常用品种：id -> { name, order }，后台一键写入 Firestore，App 从 Firestore 直接读
DEFAULT_BREEDS = [
    {"id": "british_shorthair", "name": "英国短毛猫", "order": 1},
    {"id": "american_shorthair", "name": "美国短毛猫", "order": 2},
    {"id": "ragdoll", "name": "布偶猫", "order": 3},
    {"id": "maine_coon", "name": "缅因猫", "order": 4},
    {"id": "persian", "name": "波斯猫", "order": 5},
    {"id": "siamese", "name": "暹罗猫", "order": 6},
    {"id": "scottish_fold", "name": "苏格兰折耳猫", "order": 7},
    {"id": "russian_blue", "name": "俄罗斯蓝猫", "order": 8},
    {"id": "bombay", "name": "孟买猫", "order": 9},
    {"id": "dragon_li", "name": "狸花猫", "order": 10},
    {"id": "orange_tabby", "name": "橘猫", "order": 11},
    {"id": "exotic_shorthair", "name": "异国短毛猫", "order": 12},
    {"id": "norwegian_forest", "name": "挪威森林猫", "order": 13},
    {"id": "abyssinian", "name": "阿比西尼亚猫", "order": 14},
    {"id": "sphynx", "name": "斯芬克斯猫", "order": 15},
    {"id": "domestic_shorthair", "name": "中华田园猫", "order": 16},
]


def _sort_breeds(items: list[dict]) -> list[dict]:
    items.sort(key=lambda x: (x.get("order") is None, x.get("order", 0)))
    return items


@router.get("")
async def list_breeds(uid: str = Depends(require_uid)):
    """Compatibility endpoint (deprecated)."""
    # 管理员看全部品种，普通用户只看 enabled；不用 order_by 避免未部署复合索引时 500
    if is_admin(uid):
        ref = db.collection("breeds")
    else:
        ref = db.collection("breeds").where("enabled", "==", True)
    docs = list(ref.stream())
    items = [{"breedId": d.id, **d.to_dict()} for d in docs]
    return _sort_breeds(items)




@router.post("")
async def create_breed(body: dict[str, Any], uid: str = Depends(require_admin)):
    """Compatibility endpoint (deprecated)."""
    ref = db.collection("breeds").document()
    ref.set({"name": body.get("name", ""), "localeNames": body.get("localeNames", {}), "enabled": body.get("enabled", True), "order": body.get("order", 0)})
    return {"breedId": ref.id}


@router.put("/{breed_id}")
async def update_breed(breed_id: str, body: dict[str, Any], uid: str = Depends(require_admin)):
    """Compatibility endpoint (deprecated)."""
    ref = _get_breed_ref(breed_id)
    upd = {k: v for k, v in body.items() if k in ALLOWED_BREED_UPDATE_KEYS}
    if not upd:
        return {"ok": True}
    ref.update(upd)
    return {"ok": True}


@router.delete("/{breed_id}")
async def delete_breed(breed_id: str, uid: str = Depends(require_admin)):
    """Compatibility endpoint (deprecated)."""
    ref = _get_breed_ref(breed_id)
    ref.delete()
    return {"ok": True}



@router.post("/seed")
async def seed_default_breeds(uid: str = Depends(require_admin)):
    """Compatibility endpoint (deprecated)."""
    coll = db.collection("breeds")
    added = 0
    for b in DEFAULT_BREEDS:
        doc = coll.document(b["id"])
        if not doc.get().exists:
            doc.set({"name": b["name"], "localeNames": {}, "enabled": True, "order": b["order"]})
            added += 1
    return {"ok": True, "added": added, "total": len(DEFAULT_BREEDS)}

