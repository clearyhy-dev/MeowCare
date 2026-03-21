"""Firestore-backed settings and manual trigger for daily content generation."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from firebase_admin import firestore

from app.dependencies import require_admin
from app.services.daily_generator import (
    content_generation_doc_defaults,
    generate_daily_posts,
    normalize_content_topics,
    normalize_language,
)

router = APIRouter()
db = firestore.client()


@router.get("/settings")
async def get_settings(_uid: str = Depends(require_admin)) -> dict[str, Any]:
    doc = db.collection("settings").document("content_generation").get()
    data = doc.to_dict() if doc.exists else {}
    return content_generation_doc_defaults(data)


@router.post("/settings")
async def update_settings(body: dict[str, Any], _uid: str = Depends(require_admin)) -> dict[str, Any]:
    snap = db.collection("settings").document("content_generation").get()
    current = content_generation_doc_defaults(snap.to_dict() if snap.exists else {})

    if "enabled" in body:
        current["enabled"] = bool(body["enabled"])
    if "dailyCount" in body:
        current["dailyCount"] = max(1, min(int(body["dailyCount"]), 20))
    if "publishHourUtc" in body:
        current["publishHourUtc"] = max(0, min(int(body["publishHourUtc"]), 23))
    if "topics" in body:
        current["topics"] = normalize_content_topics(body["topics"])
    if "language" in body:
        current["language"] = normalize_language(body["language"])
    if "useGemini" in body:
        current["useGemini"] = bool(body["useGemini"])
    if "minContentLength" in body:
        current["minContentLength"] = max(100, min(int(body["minContentLength"]), 8000))
    if "imageRequired" in body:
        current["imageRequired"] = bool(body["imageRequired"])

    db.collection("settings").document("content_generation").set(current, merge=True)
    return {"ok": True, **current}


@router.post("/generate-now")
async def generate_now(body: dict[str, Any], _uid: str = Depends(require_admin)) -> dict[str, Any]:
    count = max(1, min(int(body.get("count", 3)), 20))
    snap = db.collection("settings").document("content_generation").get()
    base = content_generation_doc_defaults(snap.to_dict() if snap.exists else {})
    cfg = dict(base)
    if "language" in body:
        cfg["language"] = normalize_language(body["language"])
    if "useGemini" in body:
        cfg["useGemini"] = bool(body["useGemini"])
    if "minContentLength" in body:
        cfg["minContentLength"] = max(100, min(int(body["minContentLength"]), 8000))
    if "imageRequired" in body:
        cfg["imageRequired"] = bool(body["imageRequired"])
    topics = normalize_content_topics(body["topics"]) if "topics" in body else cfg["topics"]
    created = await generate_daily_posts(count, topics, cfg_override=cfg)
    return {"ok": True, "created": created}
