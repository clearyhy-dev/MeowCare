"""Firestore-backed settings and manual trigger for daily content generation."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from firebase_admin import firestore

from app.dependencies import require_admin
from app.services.daily_generator import generate_daily_posts

router = APIRouter()
db = firestore.client()

_DEFAULT_TOPICS = ["care", "health", "behavior", "feeding"]


def _normalize_topics(raw: Any) -> list[str]:
    if not isinstance(raw, list):
        return list(_DEFAULT_TOPICS)
    out = [str(t).strip() for t in raw if str(t).strip()]
    return out if out else list(_DEFAULT_TOPICS)


@router.get("/settings")
async def get_settings(_uid: str = Depends(require_admin)) -> dict[str, Any]:
    doc = db.collection("settings").document("content_generation").get()
    data = doc.to_dict() if doc.exists else {}
    return {
        "enabled": bool(data.get("enabled", True)),
        "dailyCount": max(1, min(int(data.get("dailyCount", 5)), 20)),
        "publishHourUtc": max(0, min(int(data.get("publishHourUtc", 1)), 23)),
        "topics": _normalize_topics(data.get("topics")),
    }


@router.post("/settings")
async def update_settings(body: dict[str, Any], _uid: str = Depends(require_admin)) -> dict[str, Any]:
    payload = {
        "enabled": bool(body.get("enabled", True)),
        "dailyCount": max(1, min(int(body.get("dailyCount", 5)), 20)),
        "publishHourUtc": max(0, min(int(body.get("publishHourUtc", 1)), 23)),
        "topics": _normalize_topics(body.get("topics")),
    }
    db.collection("settings").document("content_generation").set(payload, merge=True)
    return {"ok": True, **payload}


@router.post("/generate-now")
async def generate_now(body: dict[str, Any], _uid: str = Depends(require_admin)) -> dict[str, Any]:
    count = max(1, min(int(body.get("count", 3)), 20))
    topics = _normalize_topics(body.get("topics"))
    created = await generate_daily_posts(count, topics)
    return {"ok": True, "created": created}
