"""电脑生成的合成用户（无 Firebase Auth）：用于自动发文、批量评论等。"""

from __future__ import annotations

import logging
import random
import uuid
from typing import Any

from firebase_admin import firestore

logger = logging.getLogger(__name__)

SYNTHETIC_PREFIX = "syn_"
SETTINGS_POOL_DOC = "synthetic_user_pool"
SETTINGS_COLLECTION = "settings"


def rebuild_pool_from_firestore(db: firestore.Client | None = None) -> int:
    """从 users 文档 ID 前缀 syn_ 重建 settings/synthetic_user_pool（迁移用）。"""
    db = db or _db()
    uids: list[str] = []
    for d in db.collection("users").stream():
        if d.id.startswith(SYNTHETIC_PREFIX):
            uids.append(d.id)
    if uids:
        db.collection(SETTINGS_COLLECTION).document(SETTINGS_POOL_DOC).set({"uids": uids}, merge=True)
    return len(uids)

# 与 daily_generator 中社区昵称风格一致，多语言混合池
_DISPLAY_NAME_POOL: list[str] = [
    "tabby_and_me",
    "橘座铲屎官",
    "しろちゃんの記録",
    "quiet_cat_home",
    "MochisHuman",
    "三花家长",
    "gato_naranja_casa",
    "chat_gris_du_salon",
    "stubentiger_mia",
    "laranja_no_sofa",
    "рыжий_диван",
    "캣맘_기록",
    "凌晨跑酷选手",
    "领养第三年",
]

COMMENT_LINES_ZH = [
    "学到了，感谢分享～",
    "我家猫也是这样😂",
    "收藏了",
    "马克",
    "正需要这个",
    "太真实了",
    "已转发",
    "同款焦虑",
    "先观察两天",
    "问下楼主用的什么粮？",
    "有帮助！",
]

COMMENT_LINES_EN = [
    "Same here, thanks for sharing.",
    "Saved this post.",
    "Helpful, appreciate it.",
    "My cat does this too lol",
    "Good reminder.",
    "Will try this at home.",
]


def _db() -> firestore.Client:
    return firestore.client()


def random_display_name() -> str:
    return random.choice(_DISPLAY_NAME_POOL)


def _user_doc(uid: str, display_name: str) -> dict[str, Any]:
    return {
        "uid": uid,
        "email": "",
        "displayName": display_name,
        "photoUrl": "",
        "accountKind": "synthetic",
        "accountLabel": "电脑生成",
        "subscriptionStatus": "free",
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }


def _append_pool(db: firestore.Client, uid: str) -> None:
    ref = db.collection(SETTINGS_COLLECTION).document(SETTINGS_POOL_DOC)
    ref.set({"uids": firestore.ArrayUnion([uid])}, merge=True)


def create_synthetic_user(db: firestore.Client | None = None, display_name: str | None = None) -> str:
    db = db or _db()
    uid = f"{SYNTHETIC_PREFIX}{uuid.uuid4().hex[:18]}"
    name = (display_name or "").strip() or random_display_name()
    db.collection("users").document(uid).set(_user_doc(uid, name))
    _append_pool(db, uid)
    logger.info("Created synthetic user %s (%s)", uid, name)
    return uid


def create_synthetic_users_batch(db: firestore.Client | None = None, count: int = 10) -> list[str]:
    db = db or _db()
    count = max(1, min(int(count), 200))
    out: list[str] = []
    for _ in range(count):
        out.append(create_synthetic_user(db))
    return out


def _pool_uids(db: firestore.Client) -> list[str]:
    snap = db.collection(SETTINGS_COLLECTION).document(SETTINGS_POOL_DOC).get()
    data = snap.to_dict() if snap.exists else None
    uids = list(data.get("uids") or []) if isinstance(data, dict) else []
    return [str(u).strip() for u in uids if str(u).strip()]


def ensure_min_synthetic_users(db: firestore.Client | None = None, minimum: int = 5) -> list[str]:
    """若池中空或过少，自动补齐。"""
    db = db or _db()
    pool = _pool_uids(db)
    need = max(0, minimum - len(pool))
    created: list[str] = []
    for _ in range(need):
        created.append(create_synthetic_user(db))
    return pool + created


def pick_random_author(db: firestore.Client | None = None) -> tuple[str, str, str]:
    """返回 (authorId, authorDisplayName, authorAvatarUrl)。"""
    db = db or _db()
    pool = ensure_min_synthetic_users(db, minimum=5)
    uid = random.choice(pool)
    doc = db.collection("users").document(uid).get()
    data = doc.to_dict() or {}
    name = str(data.get("displayName") or "").strip() or random_display_name()
    photo = str(data.get("photoUrl") or "").strip()
    return uid, name, photo


def _comment_line(lang: str) -> str:
    lang = (lang or "zh").lower()
    if lang.startswith("zh"):
        return random.choice(COMMENT_LINES_ZH)
    return random.choice(COMMENT_LINES_EN)


def add_synthetic_comment(
    db: firestore.Client,
    *,
    post_id: str,
    author_id: str,
    author_display_name: str,
    content: str,
    parent_comment_id: str | None = None,
    reply_to_author: str | None = None,
) -> str:
    """写入评论（Admin SDK，绕过客户端规则）。"""
    posts_ref = db.collection("posts").document(post_id)
    comments_ref = db.collection("comments")
    cref = comments_ref.document()
    cid = cref.id
    payload: dict[str, Any] = {
        "postId": post_id,
        "authorId": author_id,
        "content": content,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "authorDisplayName": author_display_name,
        "authorAccountKind": "synthetic",
    }
    if parent_comment_id:
        payload["parentCommentId"] = parent_comment_id
    if reply_to_author:
        payload["replyToAuthor"] = reply_to_author

    @firestore.transactional
    def _txn(transaction, comment_ref, post_ref, pl):
        transaction.set(comment_ref, pl)
        psnap = post_ref.get(transaction=transaction)
        cur = (psnap.to_dict() or {}).get("commentCount")
        n = int(cur) + 1 if isinstance(cur, (int, float)) else 1
        transaction.update(post_ref, {"commentCount": n})

    transaction = db.transaction()
    _txn(transaction, cref, posts_ref, payload)
    return cid


def batch_comments_on_published_posts(
    db: firestore.Client | None = None,
    *,
    max_posts: int = 20,
    comments_per_post: int = 2,
    lang: str = "zh",
    reply_probability: float = 0.25,
) -> dict[str, Any]:
    """
    对最近一批已发布帖子，用随机合成用户发表评论（可含少量回复）。
    """
    db = db or _db()
    ensure_min_synthetic_users(db, minimum=max(5, comments_per_post + 1))
    pool_uids = _pool_uids(db)
    if not pool_uids:
        pool_uids = [create_synthetic_user(db) for _ in range(5)]

    q = db.collection("posts").where("status", "==", "published").limit(max_posts)
    docs = list(q.stream())
    total_comments = 0
    errors: list[str] = []

    for doc in docs:
        pid = doc.id
        data = doc.to_dict() or {}
        for _ in range(max(1, comments_per_post)):
            uid = random.choice(pool_uids)
            udoc = db.collection("users").document(uid).get()
            ud = udoc.to_dict() or {}
            dname = str(ud.get("displayName") or "").strip() or random_display_name()
            try:
                cid = add_synthetic_comment(
                    db,
                    post_id=pid,
                    author_id=uid,
                    author_display_name=dname,
                    content=_comment_line(lang),
                )
                total_comments += 1
                if random.random() < reply_probability:
                    uid2 = random.choice([u for u in pool_uids if u != uid] or pool_uids)
                    udoc2 = db.collection("users").document(uid2).get()
                    dname2 = str((udoc2.to_dict() or {}).get("displayName") or "").strip() or random_display_name()
                    add_synthetic_comment(
                        db,
                        post_id=pid,
                        author_id=uid2,
                        author_display_name=dname2,
                        content=_comment_line(lang),
                        parent_comment_id=cid,
                        reply_to_author=dname,
                    )
                    total_comments += 1
            except Exception as e:
                errors.append(f"{pid}: {e!s}")

    return {"posts": len(docs), "comments": total_comments, "errors": errors}


def randomize_synthetic_display_names(db: firestore.Client | None = None) -> int:
    """仅合成用户：随机换昵称。"""
    db = db or _db()
    n = 0
    for uid in _pool_uids(db):
        name = random_display_name()
        db.collection("users").document(uid).set(
            {"displayName": name, "updatedAt": firestore.SERVER_TIMESTAMP},
            merge=True,
        )
        n += 1
    return n
