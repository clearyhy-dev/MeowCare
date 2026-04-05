"""Hourly tick: daily batch + frequent promotion of scheduled posts."""

from __future__ import annotations

import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.services.content_generation_job import run_daily_content_pipeline
from app.services.scheduled_post_publisher import publish_due_scheduled_posts_async

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def run_daily_generation() -> None:
    try:
        result = await run_daily_content_pipeline(check_publish_hour=True)
        if result is None:
            logger.debug(
                "content_daily_hourly: skipped until publishHourUtc (see settings/content_generation)"
            )
        elif result.get("error") or result.get("reason") == "generation_failed":
            logger.error("content_daily_hourly: pipeline reported failure: %s", result)
    except Exception:
        logger.exception("run_daily_generation: unexpected error (isolated from scheduler)")


async def run_publish_scheduled_tick() -> None:
    try:
        n = await publish_due_scheduled_posts_async(limit=80)
        if n:
            logger.debug("publish_scheduled_tick: promoted %s post(s)", n)
    except Exception:
        logger.exception("run_publish_scheduled_tick: failed (isolated from scheduler)")


def start_scheduler() -> None:
    if scheduler.running:
        return
    scheduler.add_job(
        run_daily_generation,
        CronTrigger(minute=0),
        id="content_daily_hourly",
        replace_existing=True,
    )
    scheduler.add_job(
        run_publish_scheduled_tick,
        CronTrigger(minute="*/5"),
        id="publish_scheduled_every_5m",
        replace_existing=True,
    )
    scheduler.start()
    logger.info(
        "APScheduler started (content daily at :00 UTC; publish scheduled every 5 min)"
    )


def shutdown_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler shut down")
