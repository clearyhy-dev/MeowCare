"""Create in-app notifications + bump users.notificationUnreadCount (Admin SDK only)."""

from __future__ import annotations

from typing import Any

from firebase_admin import firestore

db = firestore.client()

NOTIFICATION_TYPES = frozenset({
    "comment_on_post",
    "reply_to_comment",
    "post_approved",
    "post_rejected",
    "post_liked",
    "system",
})


def create_notification(
    *,
    recipient_user_id: str,
    notif_type: str,
    actor_user_id: str | None,
    actor_display_name: str | None,
    target_post_id: str,
    target_comment_id: str | None,
    title: str,
    body: str,
) -> str:
    if notif_type not in NOTIFICATION_TYPES:
        notif_type = "system"
    ref = db.collection("notifications").document()
    ref.set(
        {
            "recipientUserId": recipient_user_id,
            "type": notif_type,
            "actorUserId": actor_user_id,
            "actorDisplayName": (actor_display_name or "")[:200],
            "targetPostId": target_post_id,
            "targetCommentId": target_comment_id,
            "title": title[:200],
            "body": body[:500],
            "isRead": False,
            "createdAt": firestore.SERVER_TIMESTAMP,
        }
    )
    db.collection("users").document(recipient_user_id).set(
        {"notificationUnreadCount": firestore.Increment(1)},
        merge=True,
    )
    return ref.id


def notify_post_moderation(*, post_id: str, approved: bool) -> None:
    post_ref = db.collection("posts").document(post_id)
    snap = post_ref.get()
    if not snap.exists:
        return
    data: dict[str, Any] = snap.to_dict() or {}
    author = str(data.get("authorId") or "").strip()
    if not author:
        return
    title_text = str(data.get("title") or "")[:120]
    if approved:
        create_notification(
            recipient_user_id=author,
            notif_type="post_approved",
            actor_user_id=None,
            actor_display_name=None,
            target_post_id=post_id,
            target_comment_id=None,
            title="Post approved",
            body=f"Your post is now live: {title_text}" if title_text else "Your post is now live.",
        )
    else:
        create_notification(
            recipient_user_id=author,
            notif_type="post_rejected",
            actor_user_id=None,
            actor_display_name=None,
            target_post_id=post_id,
            target_comment_id=None,
            title="Post not approved",
            body=f"Your post did not pass review: {title_text}" if title_text else "Your post did not pass review.",
        )
