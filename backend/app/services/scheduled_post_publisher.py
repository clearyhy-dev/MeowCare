"""Promote posts from scheduled to published when scheduledPublishAt <= now."""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from firebase_admin import firestore

from app.firestore_utils import datetime_to_timestamp

logger = logging.getLogger(__name__)

db = firestore.client()


def publish_due_scheduled_posts(*, limit: int = 50, now: datetime | None = None) -> int:
    """
    Query scheduled posts with scheduledPublishAt <= now_utc, set status=published and publishedAt.
    Returns number of documents updated.
    """
    now = now or datetime.now(timezone.utc)
    now_ts = datetime_to_timestamp(now)
    limit = max(1, min(int(limit), 200))
    q = (
        db.collection("posts")
        .where("status", "==", "scheduled")
        .where("scheduledPublishAt", "<=", now_ts)
        .order_by("scheduledPublishAt")
        .limit(limit)
    )
    updated = 0
    for doc in q.stream():
        ref = doc.reference
        try:
            ref.update(
                {
                    "status": "published",
                    "publishedAt": firestore.SERVER_TIMESTAMP,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                }
            )
            updated += 1
        except Exception as e:
            logger.warning("publish scheduled post %s failed: %s", ref.id, e)
    if updated:
        logger.info("Published %s scheduled post(s)", updated)
    return updated


async def publish_due_scheduled_posts_async(*, limit: int = 50, now: datetime | None = None) -> int:
    import asyncio

    return await asyncio.to_thread(publish_due_scheduled_posts, limit=limit, now=now)
