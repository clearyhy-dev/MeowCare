"""Daily batch content generation: Firestore lock + shared entry for scheduler / HTTP cron."""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any

from firebase_admin import firestore

from app.services.daily_generator import generate_daily_posts, get_content_generation_settings

logger = logging.getLogger(__name__)

db = firestore.client()


def try_acquire_daily_lock(today_iso: str) -> bool:
    ref = db.collection("_scheduler_locks").document(f"content_daily_{today_iso}")
    try:
        ref.create({"at": firestore.SERVER_TIMESTAMP})
        return True
    except Exception as e:
        name = type(e).__name__
        msg = str(e).lower()
        if name in ("AlreadyExists", "Conflict") or "already exists" in msg or "409" in msg:
            return False
        logger.exception("Daily lock acquire error")
        raise


def release_daily_lock(today_iso: str) -> None:
    try:
        db.collection("_scheduler_locks").document(f"content_daily_{today_iso}").delete()
    except Exception:
        pass


async def execute_daily_batch(
    *,
    cfg_override: dict[str, Any] | None = None,
    count: int | None = None,
    topics: list[str] | None = None,
) -> dict[str, Any]:
    cfg = dict(cfg_override or get_content_generation_settings())
    n = int(count if count is not None else cfg.get("dailyCount", 5))
    n = min(max(n, 0), 50)
    tlist = topics if topics is not None else cfg.get("topics")
    created = await generate_daily_posts(n, tlist, cfg_override=cfg)
    return {"created": created, "requested": n}


async def run_daily_content_pipeline(*, check_publish_hour: bool = True) -> dict[str, Any] | None:
    """
    If check_publish_hour is True, only runs at settings.publishHourUtc (UTC), matching in-process scheduler.
    Returns None when skipped due to hour (scheduler should stay quiet).
    """
    cfg = get_content_generation_settings()
    if not cfg.get("enabled", True):
        logger.info("Daily content generation skipped: disabled")
        return {"skipped": True, "reason": "disabled", "created": 0, "requested": 0}

    now = datetime.now(timezone.utc)
    if check_publish_hour and now.hour != int(cfg.get("publishHourUtc", 1)):
        return None

    today = now.date().isoformat()
    if not try_acquire_daily_lock(today):
        logger.info("Daily content generation already ran for %s", today)
        return {"skipped": True, "reason": "already_ran", "created": 0, "requested": int(cfg.get("dailyCount", 5))}

    try:
        result = await execute_daily_batch()
        logger.info(
            "Daily content generation finished: created=%s (requested=%s)",
            result["created"],
            result["requested"],
        )
        return {**result, "skipped": False}
    except Exception:
        logger.exception("Daily content generation failed")
        release_daily_lock(today)
        raise
