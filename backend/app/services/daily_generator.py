"""Build official published posts from The Cat API + Wikipedia, optional Gemini polish."""

from __future__ import annotations

import asyncio
import json
import logging
import re
from datetime import datetime, timezone

from firebase_admin import firestore

from app.config import GEMINI_API_KEY
from app.services.cat_sources import fetch_cat_image, fetch_wiki_summary

logger = logging.getLogger(__name__)

db = firestore.client()

TOPIC_TEMPLATES = {
    "care": "Daily cat care tip",
    "behavior": "Cat behavior you should know",
    "feeding": "Feeding advice for cat owners",
    "health": "Basic cat health fact",
}

DEFAULT_TOPICS = ["care", "behavior", "feeding", "health"]
SOURCE_TYPE = "thecatapi+wikipedia"


def content_generation_doc_defaults(raw: dict | None) -> dict:
    r = raw or {}
    topics = r.get("topics")
    if not topics or not isinstance(topics, list):
        topics = list(DEFAULT_TOPICS)
    else:
        topics = [str(t).strip() for t in topics if str(t).strip()]
        if not topics:
            topics = list(DEFAULT_TOPICS)
    daily = int(r.get("dailyCount", 5))
    daily = min(max(daily, 1), 50)
    hour = int(r.get("publishHourUtc", 1))
    hour = hour % 24
    return {
        "enabled": bool(r.get("enabled", True)),
        "dailyCount": daily,
        "publishHourUtc": hour,
        "topics": topics,
        "useGemini": bool(r.get("useGemini", True)),
    }


def get_content_generation_settings() -> dict:
    snap = db.collection("settings").document("content_generation").get()
    return content_generation_doc_defaults(snap.to_dict())


def build_source_key(breed: str, topic: str, date_iso: str) -> str:
    b = (breed or "Cat").strip()
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


async def polish_with_gemini(title: str, summary: str, content: str, topic: str, breed: str) -> tuple[str, str, str]:
    if not GEMINI_API_KEY:
        return title, summary, content

    def _run() -> tuple[str, str, str]:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-flash")
        prompt = (
            "You write short cat-care articles for a mobile app. Given facts below, output ONLY valid JSON with keys "
            'title, summary, content. Use 简体中文 for all strings. title: max 60 chars; summary: max 180 chars; '
            "content: 2–5 short paragraphs, plain text inside the JSON string, no markdown.\n\n"
            f"topic_tag: {topic}\n"
            f"breed: {breed}\n"
            f"draft_title: {title}\n"
            f"draft_summary: {summary}\n"
            f"draft_content: {content[:8000]}"
        )
        try:
            r = model.generate_content(prompt)
            text = (r.text or "").strip()
            parsed = _parse_gemini_json(text)
            if not parsed:
                return title, summary, content
            nt = parsed.get("title") or title
            ns = parsed.get("summary") or summary
            nc = parsed.get("content") or content
            return nt[:200], ns[:500], nc[:50000]
        except Exception as e:
            logger.warning("Gemini polish failed: %s", e)
            return title, summary, content

    return await asyncio.to_thread(_run)


async def build_post_dict(topic: str, *, use_gemini: bool) -> dict | None:
    cat = await fetch_cat_image()
    breed = cat["breed_name"] or "Cat"
    wiki = await fetch_wiki_summary(breed)

    template = TOPIC_TEMPLATES.get(topic, "Cat tip")
    title = f"{template}: {breed}"
    base_summary = (wiki or cat.get("description") or f"Learn something useful about {breed}.")[:180]
    content = "\n\n".join(
        [
            f"Breed: {breed}",
            f"Origin: {cat.get('origin', '')}",
            f"Temperament: {cat.get('temperament', '')}",
            "",
            wiki
            or cat.get("description")
            or "Cats need stable routines, clean water, and regular observation.",
        ]
    ).strip()

    if use_gemini and GEMINI_API_KEY:
        title, base_summary, content = await polish_with_gemini(title, base_summary, content, topic, breed)

    cover = (cat.get("image_url") or "").strip()
    return {
        "type": "official",
        "status": "published",
        "title": title[:200],
        "summary": base_summary[:500],
        "content": content[:50000],
        "coverUrl": cover[:2000],
        "breedIds": [],
        "topics": [topic],
        "authorId": "admin",
        "likeCount": 0,
        "commentCount": 0,
        "score": 0.0,
        "countryCode": "US",
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }


async def generate_daily_posts(
    count: int,
    topics: list[str],
    *,
    use_gemini: bool = True,
) -> int:
    """Create up to `count` posts; skip duplicates by sourceKey for the same UTC day."""
    count = min(max(int(count), 0), 50)
    if count == 0:
        return 0
    if not topics:
        topics = list(DEFAULT_TOPICS)

    today = datetime.now(timezone.utc).date().isoformat()
    created = 0
    attempts = 0
    max_attempts = max(count * 10, count + 5)

    while created < count and attempts < max_attempts:
        attempts += 1
        topic = topics[created % len(topics)]
        try:
            cat = await fetch_cat_image()
        except Exception as e:
            logger.warning("fetch_cat_image failed: %s", e)
            continue
        breed = (cat.get("breed_name") or "Cat").strip() or "Cat"
        source_key = build_source_key(breed, topic, today)
        if source_key_exists(source_key):
            continue
        try:
            doc = await build_post_dict(topic, use_gemini=use_gemini)
        except Exception as e:
            logger.warning("build_post_dict failed: %s", e)
            continue
        if not doc:
            continue
        doc["sourceKey"] = source_key
        doc["sourceType"] = SOURCE_TYPE
        db.collection("posts").document().set(doc)
        created += 1

    return created
