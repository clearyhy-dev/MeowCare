"""Free cat image/breed metadata (The Cat API) + Wikipedia summary."""

from __future__ import annotations

import urllib.parse

import httpx

from app.config import THE_CAT_API_KEY

CAT_API_BASE = "https://api.thecatapi.com/v1"
USER_AGENT = "MeowCare/1.0 (daily content; contact: app)"


async def fetch_cat_image() -> dict:
    """Random image with breed info when available."""
    headers = {"User-Agent": USER_AGENT}
    if THE_CAT_API_KEY:
        headers["x-api-key"] = THE_CAT_API_KEY
    url = f"{CAT_API_BASE}/images/search?has_breeds=1"
    async with httpx.AsyncClient(timeout=20.0) as client:
        r = await client.get(url, headers=headers)
        r.raise_for_status()
        data = r.json()
    if not data:
        return {
            "image_url": "",
            "breed_name": "Cat",
            "temperament": "",
            "origin": "",
            "description": "",
            "wikipedia_url": "",
        }
    row = data[0]
    breed = (row.get("breeds") or [{}])[0]
    return {
        "image_url": (row.get("url") or "").strip(),
        "breed_name": (breed.get("name") or "Cat").strip() or "Cat",
        "temperament": (breed.get("temperament") or "").strip(),
        "origin": (breed.get("origin") or "").strip(),
        "description": (breed.get("description") or "").strip(),
        "wikipedia_url": (breed.get("wikipedia_url") or "").strip(),
    }


async def fetch_wiki_summary(title: str) -> str:
    if not title or not title.strip():
        return ""
    slug = title.strip().replace(" ", "_")
    path = urllib.parse.quote(slug, safe="/_")
    url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{path}"
    headers = {"User-Agent": USER_AGENT}
    async with httpx.AsyncClient(timeout=20.0) as client:
        r = await client.get(url, headers=headers)
        if r.status_code != 200:
            return ""
        data = r.json()
    return (data.get("extract") or "").strip()
