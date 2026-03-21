"""Multilingual daily posts: one Cat API fetch per slot, Wikipedia thumb, optional Gemini."""

from __future__ import annotations

import asyncio
import json
import logging
import random
import re
from datetime import datetime, timezone
from typing import Any

from firebase_admin import firestore

from app.config import GEMINI_API_KEY
from app.services.cat_sources import fetch_cat_image, fetch_wiki_summary_and_thumbnail

logger = logging.getLogger(__name__)

db = firestore.client()

SOURCE_TYPE_VALUE = "meowcare:auto:thecatapi_wikipedia_gemini"

ALLOWED_LANGUAGES = frozenset({"en", "zh", "ja", "es", "fr", "de", "pt", "ru", "ko"})

LANGUAGE_NAMES = {
    "en": "English",
    "zh": "Simplified Chinese (简体中文)",
    "ja": "Japanese (日本語)",
    "es": "Spanish (Español)",
    "fr": "French (Français)",
    "de": "German (Deutsch)",
    "pt": "Portuguese (Português)",
    "ru": "Russian (Русский)",
    "ko": "Korean (한국어)",
}

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

# English angles for prompts / EN fallbacks (Gemini translates for other output langs)
TOPIC_ANGLE_EN: dict[str, str] = {
    "care": "daily care, hygiene, and comfortable routines at home",
    "behavior": "reading body language, stress signals, and positive routines",
    "feeding": "meal rhythm, portions, transitions, and appetite observation",
    "health": "early warning signs and when to call a veterinarian",
    "grooming": "brushing, coat care, and low-stress handling",
    "kitten": "kitten life stage basics and gentle habit building",
    "senior_cat": "senior cats: slower pace, comfort, and monitoring",
    "indoor_cat": "indoor enrichment, vertical space, and safety",
    "hydration": "encouraging water intake and clean water habits",
    "litter_box": "litter box setup, cleaning cadence, and stress links",
}


def normalize_language(raw: Any) -> str:
    s = (str(raw).strip().lower() if raw is not None else "en")
    return s if s in ALLOWED_LANGUAGES else "en"


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
        "language": normalize_language(r.get("language")),
        "useGemini": bool(r.get("useGemini", True)),
        "minContentLength": min_len,
        "imageRequired": bool(r.get("imageRequired", False)),
    }


def get_content_generation_settings() -> dict:
    snap = db.collection("settings").document("content_generation").get()
    return content_generation_doc_defaults(snap.to_dict())


def build_source_key(breed: str, topic: str, language: str, date_iso: str) -> str:
    b = (breed or "Cat").strip()
    t = (topic or "care").strip()
    lang = normalize_language(language)
    return f"breed:{b}|topic:{t}|lang:{lang}|date:{date_iso}"


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


def _clamp_title_chars(s: str, lo: int = 40, hi: int = 90) -> str:
    s = re.sub(r"\s+", " ", (s or "").strip())
    if len(s) > hi:
        s = s[: hi - 1] + "…"
    if len(s) < lo:
        pad = " — practical tips for cat parents"
        s = (s + pad)[:hi]
        if len(s) < lo:
            s = (s + " MeowCare.").strip()[:hi]
    return s


def _clamp_summary_chars(s: str, lo: int = 120, hi: int = 220) -> str:
    s = re.sub(r"\s+", " ", (s or "").strip())
    if len(s) < lo:
        s = (s + " Observe your cat daily and adjust routines gradually.").strip()[:hi]
    if len(s) > hi:
        s = s[: hi - 1] + "…"
    return s


def _ensure_paragraphs(content: str, min_paragraphs: int = 5, max_paragraphs: int = 8) -> str:
    parts = [p.strip() for p in re.split(r"\n\s*\n", content) if p.strip()]
    if len(parts) >= min_paragraphs:
        return "\n\n".join(parts[:max_paragraphs])
    filler = (
        "If anything seems off, keep notes for a few days and contact your veterinarian with clear observations."
    )
    while len(parts) < min_paragraphs:
        parts.append(filler)
    return "\n\n".join(parts[:max_paragraphs])


def _fallback_content(
    breed: str,
    topic: str,
    wiki_extract: str,
    cat: dict,
    language: str,
    *,
    min_len: int,
) -> tuple[str, str, str]:
    angle = TOPIC_ANGLE_EN.get(topic, TOPIC_ANGLE_EN["care"])
    fact = (cat.get("description") or cat.get("temperament") or "").strip()
    if len(fact) > 280:
        fact = fact[:280] + "…"
    wiki = (wiki_extract or "")[:900]

    lang = normalize_language(language)

    if lang == "zh":
        title = _clamp_title_chars(f"{breed}｜{topic}照护要点与日常节奏", 40, 90)
        summary = _clamp_summary_chars(
            f"围绕「{angle}」：从观察到执行，把{breed}的日常照护拆成小步骤，减少应激与失误。{fact[:80]}",
            120,
            220,
        )
        p1 = f"如果你正在照顾「{breed}」，可以从「{topic}」这个角度重新梳理日常：先观察，再小步调整，而不是一次改太多。"
        p2 = f"为什么重要？猫咪往往用细微变化表达不适；稳定的作息、干净的水与猫砂、可预测的互动，能显著降低压力与行为问题。{('参考：' + wiki[:220] + '…') if wiki else ''}"
        p3 = "实操建议：一次只改一个变量（粮、砂、摆放位置）；记录饮水、排尿、食欲与精神；优先提供藏身处与垂直空间。"
        p4 = "常见误区：把「偶尔不吃」长期忽视；频繁换粮/换砂导致肠胃不适；用惩罚处理焦虑，反而加重应激。"
        p5 = "温和提醒：本文仅供科普与日常照护参考，不能替代兽医诊断。若出现持续呕吐、尿闭迹象、呼吸异常或精神萎靡，请尽快就医。"
        p6 = f"品种线索（可能为英文资料）：{fact}" if fact else "若有个体病史或用药方案，请以兽医指导为准。"
        content = "\n\n".join([p1, p2, p3, p4, p5, p6])
    elif lang == "ja":
        title = _clamp_title_chars(f"{breed}の{topic}｜毎日のケアのコツ", 40, 90)
        summary = _clamp_summary_chars(
            f"{breed}向けに「{topic}」を中心に、観察→小さな改善の順で進めるとストレスを減らしやすいです。{fact[:60]}",
            120,
            220,
        )
        p1 = f"この記事では、{breed}を対象に「{topic}」に関する日常ケアの考え方を、無理のないペースで整理します。"
        p2 = "なぜ大切か：猫は小さな変化で不快感や痛みを示します。生活リズムと環境の安定が、行動問題の予防にもつながります。"
        p3 = "実践のコツ：一度に変えるのは一つだけ。食事・トイレ・遊びの時間をなるべく固定し、様子を記録しましょう。"
        p4 = "よくある誤解：食欲不振を長く放置する、砂やフードを短周期で頻繁に変える、などは負担になりやすいです。"
        p5 = "注意：これは一般的な情報であり、診断や治療の代替ではありません。異常が続く場合は早めに獣医師へ相談してください。"
        p6 = (wiki[:400] + "…") if wiki else "個体差があるため、既往歴がある場合は必ず獣医師の指示を優先してください。"
        content = "\n\n".join([p1, p2, p3, p4, p5, p6])
    elif lang == "ko":
        title = _clamp_title_chars(f"{breed} {topic} 케어｜집에서 실천하는 팁", 40, 90)
        summary = _clamp_summary_chars(
            f"{breed}와 함께하는 일상에서 '{topic}'를 다룰 때는 관찰 후 작은 변화부터 적용하는 것이 스트레스를 줄입니다. {fact[:60]}",
            120,
            220,
        )
        p1 = f"이 글은 {breed}를 위한 '{topic}' 관련 실천 팁을, 하루아침에 바꾸지 않고 점진적으로 적용하는 관점에서 정리합니다."
        p2 = "왜 중요한가요: 고양이는 미세한 변화로 불편을 표현합니다. 루틴과 환경 안정은 행동 문제 예방에도 도움이 됩니다."
        p3 = "실천 팁: 한 번에 바꿀 항목은 하나만. 식사·화장실·놀이 시간을 규칙적으로 두고, 물 섭취와 배변을 기록하세요."
        p4 = "흔한 오해: 가끔 안 먹는 것을 오래 방치하거나, 사료/모래를 너무 자주 바꿔 소화 부담을 키우는 경우가 있습니다."
        p5 = "안내: 이 글은 일반 정보이며 진단·치료를 대체하지 않습니다. 이상 징후가 지속되면 수의사와 상담하세요."
        p6 = (wiki[:400] + "…") if wiki else "기저 질환이 있다면 반드시 수의사 지침을 우선하세요."
        content = "\n\n".join([p1, p2, p3, p4, p5, p6])
    else:
        # en + es/fr/de/pt/ru: English body (Gemini should localize when enabled)
        title = _clamp_title_chars(
            f"{breed}: {topic.replace('_', ' ')} — {angle.split(',')[0]}",
            40,
            90,
        )
        summary = _clamp_summary_chars(
            f"A practical, cat-parent-friendly guide focused on {angle} for {breed}. "
            f"Small steps beat big sudden changes. {fact[:100]}",
            120,
            220,
        )
        p1 = f"This article focuses on {topic.replace('_', ' ')} for cats like {breed}: we'll start with observation, then apply small, reversible changes."
        p2 = (
            f"Why it matters: cats often show discomfort through subtle shifts in appetite, litter habits, hiding, or vocalization. "
            f"{('Context from reference material: ' + wiki[:260] + '…') if wiki else 'Stable routines usually reduce stress and prevent behavior issues.'}"
        )
        p3 = "Practical tips: change one variable at a time; keep meal and play times consistent; add hiding spots and vertical space; track water intake and litter output for a few days."
        p4 = "Common mistakes: ignoring reduced eating for too long; rotating foods or litter too aggressively; using punishment for fear-based behaviors."
        p5 = "Gentle reminder: this is educational guidance, not a diagnosis. If you notice persistent vomiting, straining to urinate, labored breathing, or sudden lethargy, contact a veterinarian promptly."
        p6 = f"Breed notes (may be English-only source text): {fact}" if fact else "If your cat has medical conditions, follow your veterinarian's plan first."
        content = "\n\n".join([p1, p2, p3, p4, p5, p6])

    content = _ensure_paragraphs(content, 5, 8)
    while len(content) < min_len:
        content += "\n\nKeep a simple weekly checklist: cords/plants/windows safety, litter freshness, and water bowl cleaning."
    return title, summary, content


async def _generate_with_gemini(
    breed: str,
    topic: str,
    cat: dict,
    wiki_extract: str,
    language: str,
) -> dict[str, str] | None:
    if not GEMINI_API_KEY:
        return None

    lang_name = LANGUAGE_NAMES.get(normalize_language(language), "English")
    angle = TOPIC_ANGLE_EN.get(topic, TOPIC_ANGLE_EN["care"])

    def _run() -> dict[str, str] | None:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-flash")
        desc = (cat.get("description") or "")[:600]
        temp = (cat.get("temperament") or "")[:200]
        origin = (cat.get("origin") or "")[:120]
        wiki = (wiki_extract or "")[:1200]

        prompt = f"""You are an experienced cat-care writer.

Write ONE article for cat parents.

Output language (must match fully): {lang_name}
Topic tag: {topic}
Focus angle (English reference, translate into the output language): {angle}
Breed / label: {breed}
Breed description (may be English; integrate naturally in the output language): {desc}
Temperament notes: {temp}
Origin hint: {origin}
Wikipedia extract reference (English; paraphrase/translate as needed): {wiki}

STRICT OUTPUT RULES:
1) Return ONLY a single JSON object. No markdown fences. No extra text.
2) Keys: "title", "summary", "content" (all strings).
3) title: 40–90 characters (count characters as Unicode code points).
4) summary: 120–220 characters (same counting).
5) content: 5–8 paragraphs separated by TWO newline characters \\n\\n.
   Each paragraph must contain 2–4 sentences.
6) content MUST cover these sections in order (plain paragraphs, no markdown headings):
   - introduction
   - why it matters
   - practical tips
   - common mistakes
   - gentle reminder (explicitly state this is not a substitute for veterinary care)
7) Do NOT invent specific drug names or dosages. Do not claim a definitive diagnosis.

Vary wording and avoid repeating the same opening templates across articles.
"""
        try:
            r = model.generate_content(prompt)
            text = (r.text or "").strip()
            parsed = _parse_gemini_json(text)
            if not parsed:
                return None
            title = _clamp_title_chars(parsed.get("title", ""), 40, 90)
            summary = _clamp_summary_chars(parsed.get("summary", ""), 120, 220)
            content = _ensure_paragraphs(parsed.get("content", ""), 5, 8)
            if not title or not summary or not content:
                return None
            return {"title": title, "summary": summary, "content": content}
        except Exception as e:
            logger.warning("Gemini generation failed: %s", e)
            return None

    return await asyncio.to_thread(_run)


async def build_post_dict(
    topic: str,
    cat: dict,
    *,
    cfg: dict,
    language: str,
) -> dict[str, Any]:
    """
    Build one post from a single `cat` payload (already fetched). Does NOT call fetch_cat_image().
    """
    lang = normalize_language(language)
    breed = (cat.get("breed_name") or "Cat").strip() or "Cat"
    wiki_extract, wiki_thumb = await fetch_wiki_summary_and_thumbnail(cat, breed)

    cat_img = (cat.get("image_url") or "").strip()
    if not cat_img.startswith("http"):
        cat_img = ""
    wt = wiki_thumb if wiki_thumb.startswith("http") else ""

    cover_url = cat_img or wt
    thumbnail_url = wt or cat_img
    has_image = bool(cover_url.startswith("http"))

    use_gemini = bool(cfg.get("useGemini", True))
    min_len = int(cfg.get("minContentLength", 400))
    image_required = bool(cfg.get("imageRequired", False))

    used_gemini = False
    gem = await _generate_with_gemini(breed, topic, cat, wiki_extract, lang) if use_gemini else None
    if gem:
        title, summary, content = gem["title"], gem["summary"], gem["content"]
        used_gemini = True
    else:
        title, summary, content = _fallback_content(
            breed, topic, wiki_extract, cat, lang, min_len=min_len
        )

    while len(content) < min_len:
        content += "\n\nAdd gentle observation notes for 2–3 days before changing multiple habits at once."

    today = datetime.now(timezone.utc).date().isoformat()
    source_key = build_source_key(breed, topic, lang, today)

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
        "thumbnailUrl": (thumbnail_url[:2000] if thumbnail_url else ""),
        "hasImage": has_image,
        "language": lang,
        "topic": topic,
        "category": topic,
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
    cfg = dict(cfg_override or get_content_generation_settings())
    cfg["language"] = normalize_language(cfg.get("language"))

    count = min(max(int(count), 0), 50)
    if count == 0:
        return 0

    selected = _normalize_topic_list(topics if topics else cfg.get("topics"))
    lang = normalize_language(cfg.get("language"))
    today = datetime.now(timezone.utc).date().isoformat()

    created = 0
    max_attempts_per_slot = 10

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

            breed = (cat.get("breed_name") or "Cat").strip() or "Cat"
            sk = build_source_key(breed, topic, lang, today)
            if source_key_exists(sk):
                continue

            try:
                doc = await build_post_dict(topic, cat, cfg=cfg, language=lang)
            except Exception as e:
                logger.warning("build_post_dict failed: %s", e)
                continue

            db.collection("posts").document().set(doc)
            created += 1
            break

    return created
