"""Firestore-backed settings and manual trigger for daily content generation."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Body, Depends, HTTPException, Request, status
from firebase_admin import firestore

from app.config import CONTENT_JOB_SECRET
from app.dependencies import require_admin
from app.services.content_generation_job import run_daily_content_pipeline
from app.services.daily_generator import (
    ALLOWED_LANGUAGES,
    content_generation_doc_defaults,
    generate_daily_posts,
    normalize_content_topics,
    normalize_hemisphere,
    normalize_language,
    normalize_schedule_windows,
    normalize_voice_mode,
)
from app.services.scheduled_post_publisher import publish_due_scheduled_posts_async

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
    if "voiceMode" in body:
        current["voiceMode"] = normalize_voice_mode(body["voiceMode"])
    if "useGemini" in body:
        current["useGemini"] = bool(body["useGemini"])
    if "minContentLength" in body:
        current["minContentLength"] = max(100, min(int(body["minContentLength"]), 8000))
    if "imageRequired" in body:
        current["imageRequired"] = bool(body["imageRequired"])
    if "seasonHemisphere" in body:
        current["seasonHemisphere"] = normalize_hemisphere(body["seasonHemisphere"])
    if "publisher" in body and isinstance(body["publisher"], dict):
        p = body["publisher"]
        merged_pub = dict(current.get("publisher") or {})
        if "authorId" in p:
            merged_pub["authorId"] = str(p["authorId"] or "").strip() or merged_pub.get(
                "authorId", "meowcare_editorial"
            )
        if "authorAvatarUrl" in p:
            merged_pub["authorAvatarUrl"] = str(p.get("authorAvatarUrl") or "").strip()
        if "displayNames" in p and isinstance(p["displayNames"], dict):
            dns = dict(merged_pub.get("displayNames") or {})
            for k, v in p["displayNames"].items():
                kk = str(k).strip().lower()
                if kk in ALLOWED_LANGUAGES:
                    dns[kk] = str(v).strip()
            merged_pub["displayNames"] = dns
        current["publisher"] = merged_pub
    if "scheduleWindowsUtc" in body:
        current["scheduleWindowsUtc"] = normalize_schedule_windows(body["scheduleWindowsUtc"])
    if "minMinutesBetweenPosts" in body:
        try:
            m = int(body["minMinutesBetweenPosts"])
            current["minMinutesBetweenPosts"] = max(1, min(m, 720))
        except (TypeError, ValueError):
            pass
    if "publishScheduleTimezone" in body:
        current["publishScheduleTimezone"] = str(body.get("publishScheduleTimezone") or "").strip()

    final = content_generation_doc_defaults(current)
    db.collection("settings").document("content_generation").set(final, merge=True)
    return {"ok": True, **final}


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
    if "voiceMode" in body:
        cfg["voiceMode"] = normalize_voice_mode(body["voiceMode"])
    topics = normalize_content_topics(body["topics"]) if "topics" in body else cfg["topics"]
    created = await generate_daily_posts(count, topics, cfg_override=cfg)
    out: dict[str, Any] = {"ok": True, "created": created}
    if created == 0:
        out["hint"] = (
            "未写入新帖：常见为当日同 sourceKey 已存在（重复点生成）；"
            "或 14 次尝试内未抽到可用品种/话题组合。可改话题勾选或次日再试。"
            "若开启「必须配图」且无 THE_CAT_API_KEY，帖子可能进 draft，请在「每日内容」表格或帖子管理中查看。"
        )
    return out


def _verify_content_job_secret(request: Request) -> None:
    if not CONTENT_JOB_SECRET:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    auth = request.headers.get("Authorization") or ""
    token = auth[7:].strip() if auth.startswith("Bearer ") else ""
    header_key = (request.headers.get("X-MeowCare-Job-Key") or "").strip()
    if token != CONTENT_JOB_SECRET and header_key != CONTENT_JOB_SECRET:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")


@router.post("/daily-run")
async def daily_run_for_cron(request: Request) -> dict[str, Any]:
    """
    For Cloud Scheduler / external cron: same Firestore daily lock + batch as in-process scheduler,
    without requiring admin JWT. Set CONTENT_JOB_SECRET and send:
    Authorization: Bearer <secret>  OR  X-MeowCare-Job-Key: <secret>
    """
    _verify_content_job_secret(request)
    result = await run_daily_content_pipeline(check_publish_hour=False)
    if result is None:
        result = {"skipped": True, "reason": "internal", "created": 0, "requested": 0}
    return {"ok": True, **result}


@router.post("/publish-scheduled")
async def publish_scheduled_for_cron(
    request: Request,
    body: dict[str, Any] = Body(default_factory=dict),
) -> dict[str, Any]:
    """Promote due scheduled posts (same auth as /daily-run). Optional JSON body: {\"limit\": 80}"""
    _verify_content_job_secret(request)
    limit = 80
    if isinstance(body.get("limit"), int):
        limit = max(1, min(int(body["limit"]), 200))
    n = await publish_due_scheduled_posts_async(limit=limit)
    return {"ok": True, "published": n}
