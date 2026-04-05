"""电脑生成的合成用户（无 Firebase Auth）：用于自动发文、批量评论等。"""

from __future__ import annotations

import logging
import random
import uuid
from typing import Any

from firebase_admin import firestore

from app.config import GEMINI_API_KEY

logger = logging.getLogger(__name__)

# 与 daily_generator 一致；评论短生成够用
GEMINI_COMMENT_MODEL = "gemini-2.5-flash"
# 用户约定：日常约 10 字、专业约 30 字（Unicode 字符数）
MAX_COMMENT_CHARS_CASUAL = 10
MAX_COMMENT_CHARS_PROFESSIONAL = 30

_COMMENT_LANG_NAMES: dict[str, str] = {
    "en": "English",
    "zh": "Simplified Chinese",
    "ja": "Japanese",
    "ko": "Korean",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "pt": "Portuguese",
    "ru": "Russian",
}

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

COMMENT_LINES_ZH_PRO = [
    "从日常护理角度，建议先连续记录一周饮食与排泄再判断趋势。",
    "若症状反复，请带齐病历与视频咨询兽医，不要自行用药。",
    "同意楼主，环境压力有时也会放大行为变化，可先减少刺激源。",
    "补充：换粮/换砂建议单次只改一个变量，便于排查原因。",
]

COMMENT_LINES_EN = [
    "Same here, thanks for sharing.",
    "Saved this post.",
    "Helpful, appreciate it.",
    "My cat does this too lol",
    "Good reminder.",
    "Will try this at home.",
]

COMMENT_LINES_EN_PRO = [
    "From a care perspective, I'd log food and litter for a week before changing anything.",
    "If signs persist, bring videos and a timeline to your veterinarian.",
    "Agree—reduce one variable at a time so you can tell what helped.",
]

COMMENT_LINES_JA = [
    "参考になりました",
    "うちも同じです",
    "保存しました",
    "助かります",
]

COMMENT_LINES_JA_PRO = [
    "ケアの観点では、まず1〜2週間の観察記録があると獣医さんも判断しやすいです。",
    "症状が続く場合は、自己判断で薬を使わず早めに受診を。",
]

COMMENT_LINES_KO = [
    "도움 됐어요",
    "저희 집도 그래요",
    "저장했어요",
]

COMMENT_LINES_KO_PRO = [
    "관점상 일주일 이상 식사·배변·활동을 기록해두면 진료 시 도움이 됩니다.",
    "증상이 지속되면 자가 진단보다 수의사 상담을 권합니다.",
]

COMMENT_LINES_ES = [
    "Gracias por compartir.",
    "A nosotros nos pasa igual.",
    "Muy útil.",
]

COMMENT_LINES_ES_PRO = [
    "Desde cuidados básicos: anota comida y caja una semana antes de cambiar reglas.",
    "Si persiste, mejor vídeo + historial para el veterinario.",
]

COMMENT_LINES_FR = [
    "Merci pour le partage.",
    "Pareil ici.",
    "Très utile.",
]

COMMENT_LINES_FR_PRO = [
    "Côté soins : notez eau/croquettes/litière sur 7–10 jours avant de conclure.",
    "Si ça dure, évitez l’automédication et consultez un vétérinaire.",
]

COMMENT_LINES_DE = [
    "Danke fürs Teilen.",
    "Genau unser Problem auch.",
    "Hilfreich.",
]

COMMENT_LINES_DE_PRO = [
    "Pflege-Tipp: eine Woche lang protokollieren, dann erst Routine ändern.",
    "Bei anhaltenden Symptomen bitte zum Tierarzt statt selbst medizinieren.",
]

COMMENT_LINES_PT = [
    "Obrigado por compartilhar.",
    "Aqui é igual.",
    "Muito útil.",
]

COMMENT_LINES_PT_PRO = [
    "Em cuidados: registre comida e caixa por uma semana antes de mudar tudo.",
    "Se continuar, leve histórico ao veterinário em vez de medicar em casa.",
]

COMMENT_LINES_RU = [
    "Спасибо за пост.",
    "У нас то же самое.",
    "Полезно.",
]

COMMENT_LINES_RU_PRO = [
    "По уходу: неделю ведите дневник корма и туалета — так ветеринару проще.",
    "При стойких симптомах лучше очередь к врачу, чем самолечение.",
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


def _normalize_comment_voice(raw: str | None) -> str:
    s = (raw or "casual").strip().lower()
    return s if s in ("casual", "professional") else "casual"


def _post_snippet_for_ai(post_data: dict[str, Any]) -> str:
    s = str(post_data.get("summary") or "").strip()
    if s:
        return s[:500]
    c = str(post_data.get("content") or "").strip()
    return c[:500]


def _clamp_comment_unicode(text: str, max_chars: int) -> str:
    t = (text or "").strip().replace("\n", " ")
    while "  " in t:
        t = t.replace("  ", " ")
    if len(t) <= max_chars:
        return t
    return t[: max_chars - 1] + "…"


def _generate_comment_with_ai(
    *,
    lang: str,
    voice: str,
    post_title: str,
    post_snippet: str,
) -> str | None:
    """调用 Gemini 生成极短评论；失败返回 None。"""
    if not GEMINI_API_KEY:
        return None
    vm = _normalize_comment_voice(voice)
    max_chars = MAX_COMMENT_CHARS_PROFESSIONAL if vm == "professional" else MAX_COMMENT_CHARS_CASUAL
    raw = (lang or "en").strip().lower()
    lang_key = raw[:2] if len(raw) >= 2 else "en"
    if raw.startswith("zh"):
        lang_key = "zh"
    lang_name = _COMMENT_LANG_NAMES.get(lang_key, "English")
    if vm == "professional":
        mode = (
            f"Write in {lang_name}. Tone: brief, professional, care-oriented "
            f"(like a knowledgeable cat parent). Max {max_chars} Unicode characters. One line only."
        )
    else:
        mode = (
            f"Write in {lang_name}. Tone: very casual, like a quick forum reply or reaction. "
            f"Emoji allowed. Max {max_chars} Unicode characters. One line only."
        )
    prompt = f"""{mode}

Hard rule: output must be at most {max_chars} characters. No quotes around the text. No newlines.

Post title: {(post_title or '')[:180]}
Post excerpt: {(post_snippet or '')[:450]}

Output ONLY the comment text, nothing else."""
    try:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel(
            GEMINI_COMMENT_MODEL,
            generation_config={"temperature": 0.75, "max_output_tokens": 128},
        )
        r = model.generate_content(prompt)
        text = (r.text or "").strip()
        if text.startswith('"') and text.endswith('"'):
            text = text[1:-1].strip()
        if text.startswith("'") and text.endswith("'"):
            text = text[1:-1].strip()
        text = text.replace("\n", " ").strip()
        if not text:
            return None
        return _clamp_comment_unicode(text, max_chars)
    except Exception:
        logger.exception("Gemini short comment generation failed")
        return None


def _resolve_comment_text(
    lang: str,
    voice: str,
    use_ai: bool,
    post_data: dict[str, Any],
) -> tuple[str, str]:
    """返回 (正文, 来源 template|ai)。"""
    if use_ai:
        ai = _generate_comment_with_ai(
            lang=lang,
            voice=voice,
            post_title=str(post_data.get("title") or ""),
            post_snippet=_post_snippet_for_ai(post_data),
        )
        if ai:
            return ai, "ai"
    return _comment_line(lang, voice), "template"


def _comment_line(lang: str, voice: str = "casual") -> str:
    """按语言 + 调性（日常/专业）选评论池。"""
    vm = _normalize_comment_voice(voice)
    pro = vm == "professional"
    raw = (lang or "en").strip().lower()
    if raw.startswith("zh"):
        return random.choice(COMMENT_LINES_ZH_PRO if pro else COMMENT_LINES_ZH)
    if raw.startswith("ja"):
        return random.choice(COMMENT_LINES_JA_PRO if pro else COMMENT_LINES_JA)
    if raw.startswith("ko"):
        return random.choice(COMMENT_LINES_KO_PRO if pro else COMMENT_LINES_KO)
    if raw.startswith("es"):
        return random.choice(COMMENT_LINES_ES_PRO if pro else COMMENT_LINES_ES)
    if raw.startswith("fr"):
        return random.choice(COMMENT_LINES_FR_PRO if pro else COMMENT_LINES_FR)
    if raw.startswith("de"):
        return random.choice(COMMENT_LINES_DE_PRO if pro else COMMENT_LINES_DE)
    if raw.startswith("pt"):
        return random.choice(COMMENT_LINES_PT_PRO if pro else COMMENT_LINES_PT)
    if raw.startswith("ru"):
        return random.choice(COMMENT_LINES_RU_PRO if pro else COMMENT_LINES_RU)
    return random.choice(COMMENT_LINES_EN_PRO if pro else COMMENT_LINES_EN)


def add_synthetic_comment(
    db: firestore.Client,
    *,
    post_id: str,
    author_id: str,
    author_display_name: str,
    content: str,
    parent_comment_id: str | None = None,
    reply_to_author: str | None = None,
    comment_voice: str = "casual",
    comment_source: str = "template",
) -> str:
    """写入评论（Admin SDK，绕过客户端规则）。"""
    posts_ref = db.collection("posts").document(post_id)
    comments_ref = db.collection("comments")
    cref = comments_ref.document()
    cid = cref.id
    cv = _normalize_comment_voice(comment_voice)
    src = (comment_source or "template").strip().lower()
    if src not in ("ai", "template"):
        src = "template"
    payload: dict[str, Any] = {
        "postId": post_id,
        "authorId": author_id,
        "content": content,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "authorDisplayName": author_display_name,
        "authorAccountKind": "synthetic",
        "commentVoice": cv,
        "commentSource": src,
    }
    if parent_comment_id:
        payload["parentCommentId"] = parent_comment_id
    if reply_to_author:
        payload["replyToAuthor"] = reply_to_author

    @firestore.transactional
    def _txn(transaction, comment_ref, post_ref, pl):
        # Firestore：同一事务内必须先读后写，否则会报 Attempted read after write in a transaction
        psnap = post_ref.get(transaction=transaction)
        if not psnap.exists:
            raise ValueError("post not found")
        transaction.set(comment_ref, pl)
        cur = (psnap.to_dict() or {}).get("commentCount")
        n = int(cur) + 1 if isinstance(cur, (int, float)) else 1
        transaction.update(
            post_ref,
            {"commentCount": n, "updatedAt": firestore.SERVER_TIMESTAMP},
        )

    transaction = db.transaction()
    _txn(transaction, cref, posts_ref, payload)
    return cid


def batch_comments_on_published_posts(
    db: firestore.Client | None = None,
    *,
    max_posts: int = 20,
    comments_per_post: int = 2,
    lang: str = "zh",
    voice: str = "casual",
    use_ai: bool = True,
    reply_probability: float = 0.25,
) -> dict[str, Any]:
    """
    对最近一批已发布帖子，用随机合成用户发表评论（可含少量回复）。
    voice: casual=日常口语风，professional=偏护理/就医提醒的短评。
    use_ai: 为 True 且配置了 GEMINI_API_KEY 时，优先生成 AI 短评（日常≤10 字、专业≤30 字），失败则回落话术池。
    """
    db = db or _db()
    voice_n = _normalize_comment_voice(voice)
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
                text1, src1 = _resolve_comment_text(lang, voice_n, use_ai, data)
                cid = add_synthetic_comment(
                    db,
                    post_id=pid,
                    author_id=uid,
                    author_display_name=dname,
                    content=text1,
                    comment_voice=voice_n,
                    comment_source=src1,
                )
                total_comments += 1
                if random.random() < reply_probability:
                    uid2 = random.choice([u for u in pool_uids if u != uid] or pool_uids)
                    udoc2 = db.collection("users").document(uid2).get()
                    dname2 = str((udoc2.to_dict() or {}).get("displayName") or "").strip() or random_display_name()
                    text2, src2 = _resolve_comment_text(lang, voice_n, use_ai, data)
                    add_synthetic_comment(
                        db,
                        post_id=pid,
                        author_id=uid2,
                        author_display_name=dname2,
                        content=text2,
                        parent_comment_id=cid,
                        reply_to_author=dname,
                        comment_voice=voice_n,
                        comment_source=src2,
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
