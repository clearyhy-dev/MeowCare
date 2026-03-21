"""Hourly tick: at configured UTC hour, generate daily posts once per day (Firestore lock)."""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from firebase_admin import firestore

from app.services.daily_generator import generate_daily_posts, get_content_generation_settings

logger = logging.getLogger(__name__)

db = firestore.client()
scheduler = AsyncIOScheduler()


def _try_acquire_daily_lock(today_iso: str) -> bool:
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


async def run_daily_generation() -> None:
    cfg = get_content_generation_settings()
    if not cfg.get("enabled", True):
        return
    now = datetime.now(timezone.utc)
    if now.hour != int(cfg.get("publishHourUtc", 1)):
        return
    today = now.date().isoformat()
    if not _try_acquire_daily_lock(today):
        logger.info("Daily content generation already ran for %s", today)
        return
    count = int(cfg.get("dailyCount", 5))
    topics = cfg.get("topics") or []
    use_gemini = bool(cfg.get("useGemini", True))
    try:
        created = await generate_daily_posts(count, topics, use_gemini=use_gemini)
        logger.info("Daily content generation finished: created=%s (requested=%s)", created, count)
    except Exception:
        logger.exception("Daily content generation failed")
        try:
            db.collection("_scheduler_locks").document(f"content_daily_{today}").delete()
        except Exception:
            pass


def start_scheduler() -> None:
    if scheduler.running:
        return
    scheduler.add_job(
        run_daily_generation,
        CronTrigger(minute=0),
        id="content_daily_hourly",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("APScheduler started (content daily check every hour at :00 UTC)")


def shutdown_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler shut down")
