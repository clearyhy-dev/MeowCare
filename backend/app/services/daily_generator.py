"""Minimal daily official posts: local cat-care facts (no external APIs)."""

from __future__ import annotations

import random
from typing import Any

from firebase_admin import firestore

db = firestore.client()

DEFAULT_TOPICS = ["care", "health", "behavior", "feeding"]

CAT_FACTS: dict[str, list[tuple[str, str]]] = {
    "care": [
        ("Keep fresh water available every day.", "Hydration is one of the simplest ways to support a cat’s health."),
        ("Clean the litter box frequently.", "A clean litter box helps reduce stress and encourages good habits."),
    ],
    "health": [
        ("Watch for sudden appetite changes.", "A noticeable change in eating can be an early signal worth checking."),
        ("Regular grooming helps skin and coat health.", "Even short-haired cats benefit from basic grooming."),
    ],
    "behavior": [
        ("Cats often prefer routine.", "Stable feeding and play times can help cats feel more secure."),
        ("Scratching is natural behavior.", "Scratching helps cats stretch and mark territory."),
    ],
    "feeding": [
        ("Measure food portions consistently.", "Consistent portions help avoid overfeeding."),
        ("Some cats prefer moving water.", "Cat fountains can encourage drinking in some households."),
    ],
}


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
    daily = min(max(daily, 1), 20)
    hour = int(r.get("publishHourUtc", 1))
    hour = hour % 24
    return {
        "enabled": bool(r.get("enabled", True)),
        "dailyCount": daily,
        "publishHourUtc": hour,
        "topics": topics,
    }


def get_content_generation_settings() -> dict:
    snap = db.collection("settings").document("content_generation").get()
    return content_generation_doc_defaults(snap.to_dict())


async def generate_daily_posts(count: int, topics: list[str] | None = None, **_kwargs: Any) -> int:
    """Create `count` published official posts. Extra kwargs ignored (scheduler compatibility)."""
    count = min(max(int(count), 0), 50)
    if count == 0:
        return 0
    selected = topics if topics else list(DEFAULT_TOPICS)
    if not selected:
        selected = list(DEFAULT_TOPICS)

    created = 0
    for i in range(count):
        topic = selected[i % len(selected)]
        pool = CAT_FACTS.get(topic) or CAT_FACTS["care"]
        fact, summary = random.choice(pool)
        doc = {
            "type": "official",
            "status": "published",
            "title": f"Daily Cat Tip: {fact}",
            "summary": summary,
            "content": f"{fact}\n\n{summary}",
            "coverUrl": "",
            "breedIds": [],
            "topics": [topic],
            "authorId": "admin",
            "likeCount": 0,
            "commentCount": 0,
            "score": 0.0,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        db.collection("posts").document().set(doc)
        created += 1
    return created
