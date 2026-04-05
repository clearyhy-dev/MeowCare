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

# Product-style moderation copy by post language (not literal translation of English).
_MODERATION_APPROVED: dict[str, tuple[str, str]] = {
    "zh": ("帖子已通过", "你的帖子已发布到社区，欢迎其他铲屎官来交流。"),
    "en": ("Your post is live", "It’s now visible in the community. Thanks for sharing."),
    "ja": ("投稿が公開されました", "コミュニティに表示されました。ぜひ交流してみてください。"),
    "ko": ("게시물이 공개되었습니다", "커뮤니티에 게시되었어요. 다른 집사님들과 소통해 보세요."),
    "es": ("Publicación aprobada", "Ya está visible en la comunidad. Gracias por compartir."),
    "fr": ("Publication validée", "Elle est visible dans la communauté. Merci pour le partage."),
    "de": ("Beitrag veröffentlicht", "Er ist jetzt in der Community sichtbar. Danke fürs Teilen."),
    "pt": ("Publicação aprovada", "Já está visível na comunidade. Obrigado por compartilhar."),
    "ru": ("Публикация одобрена", "Она уже видна в сообществе. Спасибо, что поделились."),
}

_MODERATION_REJECTED: dict[str, tuple[str, str]] = {
    "zh": ("帖子未通过审核", "内容与社区规范不完全相符。可修改后重新提交，如有疑问请查看社区指南。"),
    "en": (
        "Post wasn’t approved",
        "It doesn’t fully meet our community guidelines. You can edit and submit again.",
    ),
    "ja": (
        "投稿は承認されませんでした",
        "コミュニティガイドラインに沿っていない可能性があります。修正のうえ、再度お試しください。",
    ),
    "ko": (
        "게시물이 승인되지 않았습니다",
        "커뮤니티 가이드라인과 맞지 않을 수 있어요. 수정 후 다시 제출해 주세요.",
    ),
    "es": (
        "Publicación no aprobada",
        "No cumple del todo las normas de la comunidad. Puedes editarla y enviarla de nuevo.",
    ),
    "fr": (
        "Publication non validée",
        "Elle ne correspond pas entièrement aux règles. Vous pouvez la modifier et renvoyer.",
    ),
    "de": (
        "Beitrag nicht freigegeben",
        "Er entspricht nicht vollständig den Richtlinien. Sie können ihn anpassen und erneut einreichen.",
    ),
    "pt": (
        "Publicação não aprovada",
        "Não está totalmente de acordo com as regras. Edite e envie novamente.",
    ),
    "ru": (
        "Публикация не прошла модерацию",
        "Она не полностью соответствует правилам. Отредактируйте и отправьте снова.",
    ),
}


def _post_language(data: dict[str, Any]) -> str:
    raw = data.get("language")
    s = (str(raw).strip().lower() if raw is not None else "en")[:8]
    allowed = frozenset(_MODERATION_APPROVED.keys())
    return s if s in allowed else "en"


def _moderation_title_body(*, lang: str, approved: bool, title_preview: str) -> tuple[str, str]:
    title_preview = (title_preview or "").strip()
    if approved:
        t, b = _MODERATION_APPROVED.get(lang, _MODERATION_APPROVED["en"])
        if title_preview:
            if lang == "zh":
                b = f"{b}《{title_preview[:100]}》"
            elif lang in ("ja", "ko"):
                b = f"{b}（{title_preview[:100]}）"
            else:
                b = f"{b} — {title_preview[:100]}"
        return t, b
    t, b = _MODERATION_REJECTED.get(lang, _MODERATION_REJECTED["en"])
    if title_preview:
        if lang == "zh":
            b = f"{b}《{title_preview[:100]}》"
        elif lang in ("ja", "ko"):
            b = f"{b}（{title_preview[:100]}）"
        else:
            b = f"{b} — {title_preview[:100]}"
    return t, b


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
    lang = _post_language(data)
    title_text = str(data.get("title") or "")[:120]
    nt, nb = _moderation_title_body(lang=lang, approved=approved, title_preview=title_text)
    create_notification(
        recipient_user_id=author,
        notif_type="post_approved" if approved else "post_rejected",
        actor_user_id=None,
        actor_display_name=None,
        target_post_id=post_id,
        target_comment_id=None,
        title=nt,
        body=nb,
    )
