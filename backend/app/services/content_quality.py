"""Quality gates for auto-generated posts: template blocklist, similarity, empty-field checks."""

from __future__ import annotations

import re
from typing import Iterable

# Titles / phrases that read as SEO spam or daily-repeat templates (substring match, case-insensitive for Latin).
GENERIC_TITLE_BLOCKLIST: tuple[str, ...] = (
    "突然不吃饭",
    "不吃饭怎么办",
    "不爱吃饭怎么办",
    "猫咪不吃饭",
    "猫不吃饭",
    "here are some tips",
    "in this article",
    "today we will",
    "ultimate guide to",
    "everything you need to know",
    "what to do if your cat stops eating",
    "5 ways to",
    "10 tips",
)

# Opening lines that scream generic AI (first ~200 chars of body).
GENERIC_BODY_PREFIX_BLOCKLIST: tuple[str, ...] = (
    "here are some tips",
    "in this article",
    "today we will discuss",
    "as a responsible cat owner",
    "it's important to note that",
    "本文将",
    "以下是几个小贴士",
    "在本文中",
    "首先，我们需要了解",
)

# Minimum quality thresholds
MIN_TITLE_LEN = 12
MIN_SUMMARY_LEN = 80
MIN_CONTENT_LEN = 400
MIN_PARAGRAPHS = 4
MAX_PARAGRAPHS = 10


def normalize_for_similarity(text: str) -> str:
    t = (text or "").lower()
    t = re.sub(r"[\s\W_]+", " ", t, flags=re.UNICODE)
    return " ".join(t.split())


def jaccard_shingles(a: str, b: str, k: int = 4) -> float:
    """Character-level shingle Jaccard in [0,1]."""
    def shingles(s: str) -> set[str]:
        s = re.sub(r"\s+", "", s.lower())
        if len(s) < k:
            return {s} if s else set()
        return {s[i : i + k] for i in range(len(s) - k + 1)}

    sa, sb = shingles(a), shingles(b)
    if not sa or not sb:
        return 0.0
    return len(sa & sb) / len(sa | sb)


def max_similarity_to_corpus(text: str, corpus: Iterable[str]) -> float:
    """Max similarity of `text` to any string in corpus."""
    best = 0.0
    for other in corpus:
        if not other:
            continue
        best = max(best, jaccard_shingles(text, other))
    return best


def is_blocked_template_title(title: str) -> bool:
    t = (title or "").strip().lower()
    if len(t) < MIN_TITLE_LEN:
        return True
    for pat in GENERIC_TITLE_BLOCKLIST:
        if pat.lower() in t:
            return True
    return False


def is_blocked_template_body_prefix(content: str) -> bool:
    head = (content or "")[:240].lower()
    for pat in GENERIC_BODY_PREFIX_BLOCKLIST:
        if pat in head:
            return True
    return False


def count_paragraphs(content: str) -> int:
    parts = [p.strip() for p in re.split(r"\n\s*\n", content or "") if p.strip()]
    return len(parts)


def validate_generated_fields(
    title: str,
    summary: str,
    content: str,
    *,
    min_p: int = MIN_PARAGRAPHS,
    max_p: int = MAX_PARAGRAPHS,
    min_body_len: int = MIN_CONTENT_LEN,
    min_summary_len: int = MIN_SUMMARY_LEN,
) -> tuple[bool, str]:
    if not (title or "").strip():
        return False, "empty_title"
    if not (summary or "").strip():
        return False, "empty_summary"
    if not (content or "").strip():
        return False, "empty_content"
    if is_blocked_template_title(title):
        return False, "template_title"
    if is_blocked_template_body_prefix(content):
        return False, "template_body_opening"
    n = count_paragraphs(content)
    if n < min_p or n > max_p:
        return False, f"paragraph_count_{n}"
    if len(content.strip()) < min_body_len:
        return False, "content_too_short"
    if len(summary.strip()) < min_summary_len:
        return False, "summary_too_short"
    return True, "ok"


def should_reject_by_similarity(
    title: str,
    summary: str,
    content: str,
    recent_titles: list[str],
    recent_summaries: list[str],
    *,
    title_threshold: float = 0.42,
    text_threshold: float = 0.38,
) -> tuple[bool, str]:
    """
    Reject if title too similar to another title today, or summary/content too similar to recent.
    """
    t = normalize_for_similarity(title)
    for other in recent_titles:
        if jaccard_shingles(t, normalize_for_similarity(other)) >= title_threshold:
            return True, "similar_title"
    s = normalize_for_similarity(summary)
    for other in recent_summaries:
        sim = jaccard_shingles(s, normalize_for_similarity(other))
        if sim >= text_threshold:
            return True, "similar_summary"
    # Light check: first 400 chars of content vs recent summaries (catch copy-paste)
    head = (content or "")[:400]
    for other in recent_summaries:
        if jaccard_shingles(head, other[:400]) >= text_threshold:
            return True, "similar_content_to_summary"
    return False, "ok"
