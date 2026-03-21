"""The Cat API (breed + image) + Wikipedia summary + thumbnail."""

from __future__ import annotations

import urllib.parse
from urllib.parse import unquote, urlparse

import httpx

from app.config import THE_CAT_API_KEY

CAT_API_BASE = "https://api.thecatapi.com/v1"
USER_AGENT = "MeowCare/1.0 (content; contact: app)"


async def fetch_cat_image() -> dict:
    """Random image with breed metadata when available."""
    headers = {"User-Agent": USER_AGENT}
    if THE_CAT_API_KEY:
        headers["x-api-key"] = THE_CAT_API_KEY
    url = f"{CAT_API_BASE}/images/search?has_breeds=1"
    async with httpx.AsyncClient(timeout=25.0) as client:
        r = await client.get(url, headers=headers)
        r.raise_for_status()
        data = r.json()
    if not data:
        return {
            "image_url": "",
            "breed_name": "猫",
            "temperament": "",
            "origin": "",
            "description": "",
            "wikipedia_url": "",
        }
    row = data[0]
    breed = (row.get("breeds") or [{}])[0]
    return {
        "image_url": (row.get("url") or "").strip(),
        "breed_name": (breed.get("name") or "猫").strip() or "猫",
        "temperament": (breed.get("temperament") or "").strip(),
        "origin": (breed.get("origin") or "").strip(),
        "description": (breed.get("description") or "").strip(),
        "wikipedia_url": (breed.get("wikipedia_url") or "").strip(),
    }


def _wiki_title_for_request(cat: dict, breed: str) -> str:
    wu = (cat.get("wikipedia_url") or "").strip()
    if wu:
        try:
            path = urlparse(wu).path.rstrip("/").split("/")[-1]
            if path:
                return unquote(path.replace("_", " "))
        except Exception:
            pass
    return breed


async def fetch_wiki_summary_and_thumbnail(cat: dict, breed: str) -> tuple[str, str]:
    """
    English Wikipedia REST summary: extract + optional thumbnail URL.
    Returns (extract_plain, thumbnail_https_or_empty).
    """
    title = _wiki_title_for_request(cat, breed)
    if not title:
        return "", ""
    slug = title.strip().replace(" ", "_")
    path = urllib.parse.quote(slug, safe="/_")
    url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{path}"
    headers = {"User-Agent": USER_AGENT}
    async with httpx.AsyncClient(timeout=20.0) as client:
        r = await client.get(url, headers=headers)
        if r.status_code != 200:
            return "", ""
        data = r.json()
    extract = (data.get("extract") or "").strip()
    thumb = (data.get("thumbnail") or {}).get("source") or ""
    thumb = str(thumb).strip()
    if thumb and not thumb.startswith("http"):
        thumb = ""
    return extract, thumb
