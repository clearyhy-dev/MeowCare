"""Admin APIs: Firestore settings for automated content + manual generation."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from firebase_admin import firestore
from pydantic import BaseModel, Field

from app.dependencies import require_admin
from app.services.daily_generator import (
    content_generation_doc_defaults,
    generate_daily_posts,
    get_content_generation_settings,
)

router = APIRouter()
db = firestore.client()


class UpdateSettingsBody(BaseModel):
    enabled: bool | None = None
    dailyCount: int | None = Field(default=None, ge=1, le=20)
    publishHourUtc: int | None = Field(default=None, ge=0, le=23)
    topics: list[str] | None = None
    useGemini: bool | None = None


class GenerateNowBody(BaseModel):
    count: int = Field(default=3, ge=1, le=20)
    topics: list[str] | None = None
    useGemini: bool | None = None


@router.get("/settings")
async def read_settings(_uid: str = Depends(require_admin)) -> dict[str, Any]:
    snap = db.collection("settings").document("content_generation").get()
    return content_generation_doc_defaults(snap.to_dict())


@router.post("/settings")
async def update_settings(body: UpdateSettingsBody, _uid: str = Depends(require_admin)) -> dict[str, bool]:
    snap = db.collection("settings").document("content_generation").get()
    current = content_generation_doc_defaults(snap.to_dict())
    if body.enabled is not None:
        current["enabled"] = body.enabled
    if body.dailyCount is not None:
        current["dailyCount"] = body.dailyCount
    if body.publishHourUtc is not None:
        current["publishHourUtc"] = body.publishHourUtc
    if body.topics is not None:
        cleaned = [str(t).strip() for t in body.topics if str(t).strip()]
        if cleaned:
            current["topics"] = cleaned
    if body.useGemini is not None:
        current["useGemini"] = body.useGemini
    db.collection("settings").document("content_generation").set(current, merge=True)
    return {"ok": True}


@router.post("/generate-now")
async def generate_now(body: GenerateNowBody, _uid: str = Depends(require_admin)) -> dict[str, Any]:
    cfg = get_content_generation_settings()
    topics = body.topics if body.topics else cfg["topics"]
    use_gemini = cfg["useGemini"] if body.useGemini is None else body.useGemini
    created = await generate_daily_posts(body.count, topics, use_gemini=use_gemini)
    return {"ok": True, "created": created}
