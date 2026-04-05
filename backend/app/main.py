import logging
import time
from collections import defaultdict
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse


from app.config import CORS_ORIGINS, IS_PRODUCTION
from app.routers import admin, ai, breeds, content_jobs, posts, reports, ugc

logger = logging.getLogger(__name__)

# Cloud Run 上容器可能不常驻，APScheduler 不一定准时；在 API 有流量时顺带推进定时帖（节流）。
_last_scheduled_publish_mono = 0.0
_SCHEDULED_PUBLISH_INTERVAL_SEC = 90.0


@asynccontextmanager
async def lifespan(_app: FastAPI):
    from app.services.scheduler import shutdown_scheduler, start_scheduler

    start_scheduler()
    yield
    shutdown_scheduler()


app = FastAPI(lifespan=lifespan)

# Simple in-memory rate limit: key -> list of request timestamps (pruned to last 60s)
_rate_store = defaultdict(list)
_RATE_WINDOW = 60
_AI_LIMIT = 30
_ADMIN_LOGIN_LIMIT = 10


def _client_ip(request: Request) -> str:
    return request.client.host if request.client else "unknown"


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        raise exc
    logger.exception("Unhandled exception: %s", exc)
    return JSONResponse(status_code=500, content={"detail": "Internal error"})



@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    path = request.url.path
    ip = _client_ip(request)
    now = time.time()
    key = f"{path}:{ip}"
    if path.startswith("/ai/"):
        _rate_store[key] = [t for t in _rate_store[key] if now - t < _RATE_WINDOW]
        if len(_rate_store[key]) >= _AI_LIMIT:
            return JSONResponse(status_code=429, content={"detail": "Too many requests"})
        _rate_store[key].append(now)
    elif path == "/admin/login" and request.method == "POST":
        _rate_store[key] = [t for t in _rate_store[key] if now - t < _RATE_WINDOW]
        if len(_rate_store[key]) >= _ADMIN_LOGIN_LIMIT:
            return JSONResponse(status_code=429, content={"detail": "Too many login attempts"})
        _rate_store[key].append(now)
    return await call_next(request)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    response = await call_next(request)
    if response.status_code >= 400:
        logger.warning("%s %s -> %s", request.method, request.url.path, response.status_code)
    return response


@app.middleware("http")
async def promote_scheduled_posts_on_traffic(request: Request, call_next):
    """当 Admin/AI 等请求命中 API 时，顺带将到期的 scheduled 帖改为 published（不替代 Cloud Scheduler）。"""
    import asyncio

    global _last_scheduled_publish_mono
    response = await call_next(request)
    now = time.monotonic()
    if now - _last_scheduled_publish_mono < _SCHEDULED_PUBLISH_INTERVAL_SEC:
        return response
    _last_scheduled_publish_mono = now
    try:
        from app.services.scheduled_post_publisher import publish_due_scheduled_posts_async

        asyncio.create_task(publish_due_scheduled_posts_async(limit=80))
    except Exception:
        logger.debug("promote_scheduled_posts_on_traffic skipped", exc_info=True)
    return response


_origins = CORS_ORIGINS if (IS_PRODUCTION and CORS_ORIGINS) else ["*"]
app.add_middleware(CORSMiddleware, allow_origins=_origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
app.include_router(admin.router, prefix="/admin", tags=["admin"])

app.include_router(breeds.router, prefix="/breeds", tags=["breeds"])
app.include_router(posts.router, prefix="/posts", tags=["posts"])
app.include_router(ugc.router, prefix="/ugc", tags=["ugc"])
app.include_router(reports.router, prefix="/reports", tags=["reports"])
app.include_router(ai.router, prefix="/ai", tags=["ai"])
app.include_router(content_jobs.router, prefix="/content-jobs", tags=["content-jobs"])

