"""Daily auto posts: The Cat API + Wikipedia + optional Gemini; single cat fetch per post."""

from __future__ import annotations

import asyncio
import json
import logging
import re
from datetime import datetime, timezone
from typing import Any

from firebase_admin import firestore

from app.config import GEMINI_API_KEY
from app.services.cat_sources import fetch_cat_image, fetch_wiki_summary_and_thumbnail

logger = logging.getLogger(__name__)

db = firestore.client()

SOURCE_TYPE_VALUE = "meowcare:auto:thecatapi_wikipedia_gemini"

ALLOWED_TOPICS = frozenset({
    "care",
    "behavior",
    "feeding",
    "health",
    "grooming",
    "kitten",
    "senior_cat",
    "indoor_cat",
    "hydration",
    "litter_box",
})

DEFAULT_TOPICS = [
    "care", "behavior", "feeding", "health", "grooming",
    "kitten", "senior_cat", "indoor_cat", "hydration", "litter_box",
]

TOPIC_STYLE: dict[str, str] = {
    "care": "日常护理与居家照护，语气亲切实用",
    "behavior": "行为解读与情绪理解，避免惩罚式表述",
    "feeding": "饮食与营养节奏，强调循序渐进与观察",
    "health": "健康观察与风险信号，强调不能替代兽医",
    "grooming": "美容梳理与被毛护理，结合居家操作",
    "kitten": "幼猫阶段特点与循序渐进建立习惯",
    "senior_cat": "老年猫节奏变慢与舒适照护重点",
    "indoor_cat": "室内丰容、活动与安全环境",
    "hydration": "饮水动机与清洁水源维护",
    "litter_box": "猫砂盆位置、清洁频率与压力关联",
}

TITLE_TEMPLATES: dict[str, list[str]] = {
    "care": ["{breed}居家护理小抄：", "给铲屎官的照护笔记｜{breed}"],
    "behavior": ["读懂{breed}的行为信号：", "{breed}行为背后的小心思："],
    "feeding": ["{breed}吃饭这件事：", "喂食节奏怎么更稳｜{breed}"],
    "health": ["{breed}健康观察清单：", "别忽略这些信号｜{breed}"],
    "grooming": ["{breed}被毛护理指南：", "梳理不费力｜{breed}"],
    "kitten": ["幼猫家长必看｜{breed}", "{breed}幼猫阶段的温柔提醒："],
    "senior_cat": ["老年{breed}更需要慢下来：", "陪伴老伙计｜{breed}"],
    "indoor_cat": ["室内{breed}的生活质量：", "让宅家猫更自在｜{breed}"],
    "hydration": ["让{breed}更爱喝水的思路：", "补水从细节开始｜{breed}"],
    "litter_box": ["猫砂盆这件事｜{breed}", "{breed}如厕舒适度的关键："],
}


def _normalize_topic_list(raw: list[str] | None) -> list[str]:
    if not raw:
        return list(DEFAULT_TOPICS)
    out: list[str] = []
    for t in raw:
        s = str(t).strip()
        if s in ALLOWED_TOPICS:
            out.append(s)
        elif s:
            out.append("care")
    return out if out else list(DEFAULT_TOPICS)


def normalize_content_topics(raw: Any) -> list[str]:
    if not isinstance(raw, list):
        return list(DEFAULT_TOPICS)
    return _normalize_topic_list([str(x).strip() for x in raw if str(x).strip()])


def content_generation_doc_defaults(raw: dict | None) -> dict:
    r = raw or {}
    topics = r.get("topics")
    if not topics or not isinstance(topics, list):
        topics_norm = list(DEFAULT_TOPICS)
    else:
        topics_norm = _normalize_topic_list([str(x).strip() for x in topics if str(x).strip()])
    daily = int(r.get("dailyCount", 5))
    daily = min(max(daily, 1), 20)
    hour = int(r.get("publishHourUtc", 1))
    hour = hour % 24
    min_len = int(r.get("minContentLength", 400))
    min_len = min(max(min_len, 100), 8000)
    return {
        "enabled": bool(r.get("enabled", True)),
        "dailyCount": daily,
        "publishHourUtc": hour,
        "topics": topics_norm,
        "useGemini": bool(r.get("useGemini", True)),
        "minContentLength": min_len,
        "imageRequired": bool(r.get("imageRequired", False)),
    }


def get_content_generation_settings() -> dict:
    snap = db.collection("settings").document("content_generation").get()
    return content_generation_doc_defaults(snap.to_dict())


def build_source_key(breed: str, topic: str, date_iso: str) -> str:
    b = (breed or "猫").strip()
    t = (topic or "care").strip()
    return f"breed:{b}|topic:{t}|date:{date_iso}"


def source_key_exists(source_key: str) -> bool:
    q = db.collection("posts").where("sourceKey", "==", source_key).limit(1)
    return any(q.stream())


def _parse_gemini_json(text: str) -> dict[str, str] | None:
    if not text:
        return None
    t = text.strip()
    m = re.search(r"\{[\s\S]*\}", t)
    if m:
        t = m.group(0)
    try:
        obj = json.loads(t)
    except json.JSONDecodeError:
        return None
    if not isinstance(obj, dict):
        return None
    return {
        "title": str(obj.get("title", "")).strip(),
        "summary": str(obj.get("summary", "")).strip(),
        "content": str(obj.get("content", "")).strip(),
    }


def _clamp_title(s: str, max_len: int = 80) -> str:
    s = s.strip()
    return s[:max_len] if len(s) > max_len else s


def _clamp_summary(s: str, lo: int = 120, hi: int = 220) -> str:
    s = re.sub(r"\s+", " ", s.strip())
    if len(s) < lo:
        s = (s + "。更多细节请结合猫咪个体情况观察调整。")[:hi]
    if len(s) > hi:
        s = s[: hi - 1] + "…"
    return s


def _ensure_paragraphs(content: str, min_paragraphs: int = 5) -> str:
    parts = [p.strip() for p in re.split(r"\n\s*\n", content) if p.strip()]
    if len(parts) >= min_paragraphs:
        return "\n\n".join(parts)
    while len(parts) < min_paragraphs:
        parts.append("若猫咪出现异常或症状持续，请及时咨询专业兽医，以获得针对性评估。")
    return "\n\n".join(parts[:8])


def _fallback_long_content_zh(
    breed: str,
    topic: str,
    wiki_extract: str,
    cat: dict,
    *,
    min_len: int,
) -> tuple[str, str, str]:
    templates = TITLE_TEMPLATES.get(topic, TITLE_TEMPLATES["care"])
    import random

    head = random.choice(templates).format(breed=breed)
    title = _clamp_title(head + "｜铲屎官必读")
    fact = (cat.get("description") or cat.get("temperament") or "").strip()
    if len(fact) > 200:
        fact = fact[:200] + "…"
    base = wiki_extract[:1200] if wiki_extract else ""
    summary_src = f"{breed}相关的{topic}照护要点：{fact or base[:400]}"
    summary = _clamp_summary(summary_src)

    p1 = f"许多铲屎官会关心「{breed}」在日常中如何更舒适、更安全。围绕「{TOPIC_STYLE.get(topic, '照护')}」这一主题，我们可以从观察与节奏入手，把照护拆成可执行的小步骤。"
    p2 = f"为什么这很重要？因为猫咪往往通过细微变化表达压力、疼痛或不适。{('参考信息：' + base[:300] + '…') if base else '稳定的作息与干净的环境，通常能显著降低应激与行为问题的概率。'}"
    p3 = f"实操建议：先固定喂食与互动时间，再逐步调整环境（例如藏身处、垂直空间、玩具轮换）。若涉及饮食改变，建议小步替换并观察排便与食欲。"
    p4 = f"另一个关键是记录：连续几天记录饮水、排尿、精神状态与呕吐情况，有助于你在需要时向兽医提供有效信息。"
    p5 = f"常见误区：把「偶尔不吃」当成小事长期忽视；或频繁更换猫砂/粮导致肠胃不适。更稳妥的做法是每次只改一个变量，并留出观察窗口。"
    p6 = f"温和提醒：本文仅供科普与日常照护参考，不能替代兽医诊断与治疗。若出现呼吸急促、持续呕吐、尿闭迹象、精神萎靡等，请尽快就医。"
    if fact:
        p_extra = f"品种线索：{fact}"
    else:
        p_extra = "如果你家猫咪有个性化病史（慢性病、用药史），务必以兽医方案为准。"
    content = "\n\n".join([p1, p2, p3, p4, p5, p_extra, p6])
    content = _ensure_paragraphs(content, 5)
    while len(content) < min_len:
        content += "\n\n此外，建议把居家风险点（线绳、百合科植物、开窗安全）纳入每周一次的快速巡检。"
    return title, summary, content


async def _generate_with_gemini(
    breed: str,
    topic: str,
    cat: dict,
    wiki_extract: str,
) -> dict[str, str] | None:
    if not GEMINI_API_KEY:
        return None

    def _run() -> dict[str, str] | None:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-flash")
        style = TOPIC_STYLE.get(topic, TOPIC_STYLE["care"])
        desc = (cat.get("description") or "")[:600]
        temp = (cat.get("temperament") or "")[:200]
        origin = (cat.get("origin") or "")[:120]
        wiki = (wiki_extract or "")[:1200]
        prompt = f"""你是资深猫咪科普作者。请根据素材写一篇给铲屎官阅读的简体中文文章。

主题标签：{topic}
写作风格：{style}
品种/线索：{breed}
品种描述（可能为英文，可翻译融入）：{desc}
性格特点：{temp}
原产地线索：{origin}
维基摘要参考（英文可翻译使用）：{wiki}

输出要求（必须严格遵守）：
1) 只输出一个 JSON 对象，不要 markdown，不要代码块。
2) 键：title, summary, content（均为字符串）。
3) title：最长 80 个字符（中文按字计），自然吸引人。
4) summary：120-220 个字符（中文按字计），信息密度高。
5) content：5-8 段，段与段之间用两个换行符 \\n\\n 分隔；每段 2-4 句。
6) content 必须依次覆盖这些板块（可用小标题语气但不要用 markdown 标题符号）：
   - 介绍
   - 为什么重要
   - 实操建议
   - 常见误区
   - 温和提醒（明确不能替代兽医）
7) 不要编造具体药物名称与剂量；不做诊断断言。
"""
        try:
            r = model.generate_content(prompt)
            text = (r.text or "").strip()
            parsed = _parse_gemini_json(text)
            if not parsed:
                return None
            title = _clamp_title(parsed.get("title", ""), 80)
            summary = _clamp_summary(parsed.get("summary", ""), 120, 220)
            content = _ensure_paragraphs(parsed.get("content", ""), 5)
            if not title or not summary or not content:
                return None
            return {"title": title, "summary": summary, "content": content}
        except Exception as e:
            logger.warning("Gemini generation failed: %s", e)
            return None

    return await asyncio.to_thread(_run)


async def build_post_dict(topic: str, cat: dict, *, cfg: dict) -> dict[str, Any] | None:
    """
    使用已抓取的一条 cat 数据构建帖子文档；不在此函数内再次请求 The Cat API。
    会请求 Wikipedia（文本+缩略图）与可选 Gemini。
    """
    breed = (cat.get("breed_name") or "猫").strip() or "猫"
    wiki_extract, wiki_thumb = await fetch_wiki_summary_and_thumbnail(cat, breed)

    cover_url = (cat.get("image_url") or "").strip()
    if not cover_url.startswith("http"):
        cover_url = ""
    if not cover_url and wiki_thumb.startswith("http"):
        cover_url = wiki_thumb[:2000]

    has_image = bool(cover_url.startswith("http"))
    use_gemini = bool(cfg.get("useGemini", True))
    min_len = int(cfg.get("minContentLength", 400))
    image_required = bool(cfg.get("imageRequired", False))

    used_gemini = False
    gem = await _generate_with_gemini(breed, topic, cat, wiki_extract) if use_gemini else None
    if gem:
        title, summary, content = gem["title"], gem["summary"], gem["content"]
        used_gemini = True
    else:
        title, summary, content = _fallback_long_content_zh(
            breed, topic, wiki_extract, cat, min_len=min_len
        )

    while len(content) < min_len:
        content += "\n\n补充建议：保持观察记录，遇到不确定症状优先咨询兽医。"

    today = datetime.now(timezone.utc).date().isoformat()
    source_key = build_source_key(breed, topic, today)

    status = "published"
    if image_required and not has_image:
        status = "draft"

    content_len = len(content)

    return {
        "type": "official",
        "status": status,
        "title": title[:200],
        "summary": summary[:500],
        "content": content[:50000],
        "coverUrl": cover_url[:2000],
        "breedIds": [],
        "topics": [topic],
        "authorId": "admin",
        "likeCount": 0,
        "commentCount": 0,
        "score": 0.0,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "autoGenerated": True,
        "sourceType": SOURCE_TYPE_VALUE,
        "sourceKey": source_key,
        "contentQuality": {
            "hasImage": has_image,
            "contentLength": content_len,
            "usedGemini": used_gemini,
        },
    }


async def generate_daily_posts(
    count: int,
    topics: list[str] | None = None,
    *,
    cfg_override: dict[str, Any] | None = None,
    **_kwargs: Any,
) -> int:
    cfg = cfg_override or get_content_generation_settings()
    count = min(max(int(count), 0), 50)
    if count == 0:
        return 0

    selected = _normalize_topic_list(topics if topics else cfg.get("topics"))

    created = 0
    max_attempts_per_slot = 8
    today = datetime.now(timezone.utc).date().isoformat()

    for i in range(count):
        topic = selected[i % len(selected)]
        attempts = 0
        while attempts < max_attempts_per_slot:
            attempts += 1
            try:
                cat = await fetch_cat_image()
            except Exception as e:
                logger.warning("fetch_cat_image failed: %s", e)
                continue

            breed = (cat.get("breed_name") or "猫").strip() or "猫"
            sk = build_source_key(breed, topic, today)
            if source_key_exists(sk):
                continue

            try:
                doc = await build_post_dict(topic, cat, cfg=cfg)
            except Exception as e:
                logger.warning("build_post_dict failed: %s", e)
                continue

            if doc is None:
                continue

            db.collection("posts").document().set(doc)
            created += 1
            break

    return created
