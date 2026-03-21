#!/usr/bin/env python3
"""
将「每日内容」等默认配置写入 Firestore。

用法（在 backend 目录下）:
  py -3 scripts/seed_firestore.py
  py -3 scripts/seed_firestore.py --dry-run

依赖:
  - 已配置 GOOGLE_APPLICATION_CREDENTIALS（服务账号 JSON），或本机已 gcloud auth application-default login
  - 可选 FIREBASE_PROJECT_ID / GOOGLE_CLOUD_PROJECT
  - 可选加载 backend/.env（脚本会自动 load_dotenv）
"""

from __future__ import annotations

import argparse
import json
import os
import sys

BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BACKEND_ROOT not in sys.path:
    sys.path.insert(0, BACKEND_ROOT)

from dotenv import load_dotenv

load_dotenv(os.path.join(BACKEND_ROOT, ".env"))

# .env 里常指向本地 JSON；若文件不存在则不要用，否则 google.auth 直接报错
_gac = (os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or "").strip()
if _gac and not os.path.isfile(_gac):
    os.environ.pop("GOOGLE_APPLICATION_CREDENTIALS", None)

import firebase_admin
from firebase_admin import firestore


def _init_firebase() -> None:
    if firebase_admin._apps:
        return
    cred_path = (os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or "").strip()
    project_id = (os.getenv("FIREBASE_PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT") or "").strip()
    if cred_path and os.path.isfile(cred_path):
        if project_id:
            firebase_admin.initialize_app(options={"projectId": project_id})
        else:
            firebase_admin.initialize_app()
    elif project_id:
        firebase_admin.initialize_app(options={"projectId": project_id})
    else:
        firebase_admin.initialize_app()


DEFAULT_CONTENT_GENERATION = {
    "enabled": True,
    "dailyCount": 5,
    "publishHourUtc": 1,
    "language": "en",
    "topics": [
        "care", "behavior", "feeding", "health", "grooming",
        "kitten", "senior_cat", "indoor_cat", "hydration", "litter_box",
    ],
    "useGemini": True,
    "minContentLength": 400,
    "imageRequired": False,
}


def seed_content_generation(*, dry_run: bool) -> None:
    ref = firestore.client().collection("settings").document("content_generation")
    if dry_run:
        print("[dry-run] would merge set:", ref.path)
        print(json.dumps(DEFAULT_CONTENT_GENERATION, ensure_ascii=False, indent=2))
        return
    ref.set(DEFAULT_CONTENT_GENERATION, merge=True)
    print("OK:", ref.path, "merged with defaults.")


def backfill_posts_fields(*, dry_run: bool, limit: int = 1000) -> None:
    """
    回填 posts 中缺失的关键字段，避免旧数据在后台列表/前端渲染时出现空值。
    仅补缺失字段，不覆盖已有值。
    """
    db = firestore.client()
    docs = list(db.collection("posts").limit(limit).stream())
    touched = 0
    for d in docs:
        data = d.to_dict() or {}
        upd = {}
        if "type" not in data:
            upd["type"] = "official"
        if "status" not in data:
            upd["status"] = "published"
        if "coverUrl" not in data:
            upd["coverUrl"] = ""
        if "breedIds" not in data:
            upd["breedIds"] = []
        if "topics" not in data:
            upd["topics"] = ["care"]
        if "authorId" not in data:
            upd["authorId"] = "admin"
        if "likeCount" not in data:
            upd["likeCount"] = 0
        if "commentCount" not in data:
            upd["commentCount"] = 0
        if "score" not in data:
            upd["score"] = 0.0
        if "updatedAt" not in data:
            upd["updatedAt"] = firestore.SERVER_TIMESTAMP
        if not upd:
            continue
        touched += 1
        if dry_run:
            print(f"[dry-run] would update posts/{d.id}: {json.dumps(upd, ensure_ascii=False)}")
        else:
            d.reference.update(upd)
    print(f"OK: posts backfill done. scanned={len(docs)} touched={touched}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed Firestore (MeowCare)")
    parser.add_argument("--dry-run", action="store_true", help="只打印将要写入的数据，不写库")
    parser.add_argument("--backfill-posts", action="store_true", help="回填 posts 集合缺失字段")
    parser.add_argument("--limit", type=int, default=1000, help="回填扫描的 posts 文档上限")
    args = parser.parse_args()

    _init_firebase()
    seed_content_generation(dry_run=args.dry_run)
    if args.backfill_posts:
        backfill_posts_fields(dry_run=args.dry_run, limit=max(1, args.limit))


if __name__ == "__main__":
    main()
