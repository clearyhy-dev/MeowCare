"""Multilingual daily posts: Cat API + Wikipedia + Gemini, multi-style community tone."""

from __future__ import annotations

import asyncio
import json
import logging
import random
import re
from collections import deque
from datetime import date, datetime, timedelta, timezone
from typing import Any

from firebase_admin import firestore
from google.protobuf.timestamp_pb2 import Timestamp as PbTimestamp

from app.config import GEMINI_API_KEY
from app.services.cat_sources import fetch_cat_image, fetch_wiki_summary_and_thumbnail

logger = logging.getLogger(__name__)

db = firestore.client()


def _coerce_value_for_firestore(obj: Any) -> Any:
    """Firestore Python SDK 无法编码 protobuf Timestamp；递归转为带 UTC 的 datetime。"""
    if isinstance(obj, dict):
        return {k: _coerce_value_for_firestore(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_coerce_value_for_firestore(v) for v in obj]
    if isinstance(obj, PbTimestamp):
        return obj.ToDatetime(tzinfo=timezone.utc)
    if isinstance(obj, datetime):
        if obj.tzinfo is None:
            return obj.replace(tzinfo=timezone.utc)
        return obj.astimezone(timezone.utc)
    return obj


SOURCE_TYPE_VALUE = "meowcare:auto:thecatapi_wikipedia_gemini"
GEMINI_MODEL_ID = "gemini-2.5-flash"
GENERATOR_VERSION = "v2"

ALLOWED_LANGUAGES = frozenset({"en", "zh", "ja", "es", "fr", "de", "pt", "ru", "ko"})

LANGUAGE_NAMES = {
    "en": "English",
    "zh": "Simplified Chinese (简体中文)",
    "ja": "Japanese (日本語)",
    "es": "Spanish (Español)",
    "fr": "French (Français)",
    "de": "German (Deutsch)",
    "pt": "Portuguese (Português)",
    "ru": "Russian (Русский)",
    "ko": "Korean (한국어)",
}

ALLOWED_TOPICS = frozenset({
    "care",
    "behavior",
    "feeding",
    "health",
    "grooming",
    "kitten",
    "senior_cat",
    "indoor_cat",
    "hydration",
    "litter_box",
})

DEFAULT_TOPICS = [
    "care", "behavior", "feeding", "health", "grooming",
    "kitten", "senior_cat", "indoor_cat", "hydration", "litter_box",
]

CONTENT_STYLES: tuple[str, ...] = (
    "professional_care",
    "cat_daily_story",
    "owner_journal",
    "seasonal_care",
    "short_experience_share",
    "warm_healing",
)

TONES: tuple[str, ...] = (
    "warm",
    "casual",
    "reflective",
    "playful",
    "calm_supportive",
    "neighborly",
    "gentle_humor",
)

DEFAULT_PUBLISHER_NAMES: dict[str, str] = {
    "en": "MeowCare Editorial",
    "zh": "MeowCare 编辑部",
    "ja": "MeowCare 編集部",
    "es": "Redacción MeowCare",
    "fr": "Rédaction MeowCare",
    "de": "MeowCare Redaktion",
    "pt": "Redação MeowCare",
    "ru": "Редакция MeowCare",
    "ko": "MeowCare 편집부",
}

# English angles for prompts / EN fallbacks (Gemini translates for other output langs)
TOPIC_ANGLE_EN: dict[str, str] = {
    "care": "daily care, hygiene, and comfortable routines at home",
    "behavior": "reading body language, stress signals, and positive routines",
    "feeding": "meal rhythm, portions, transitions, and appetite observation",
    "health": "early warning signs and when to call a veterinarian",
    "grooming": "brushing, coat care, and low-stress handling",
    "kitten": "kitten life stage basics and gentle habit building",
    "senior_cat": "senior cats: slower pace, comfort, and monitoring",
    "indoor_cat": "indoor enrichment, vertical space, and safety",
    "hydration": "encouraging water intake and clean water habits",
    "litter_box": "litter box setup, cleaning cadence, and stress links",
}

# The Cat API 限流/网络失败时用占位数据，避免整日 0 条。
_EMPTY_CAT_FOR_GENERATION: dict[str, str] = {
    "image_url": "",
    "breed_name": "Cat",
    "temperament": "",
    "origin": "",
    "description": "",
    "wikipedia_url": "",
}

DEFAULT_SCHEDULE_WINDOWS_UTC: list[dict[str, Any]] = [
    {"label": "morning", "weight": 0.30, "startHour": 6, "endHour": 11},
    {"label": "noon", "weight": 0.25, "startHour": 11, "endHour": 15},
    {"label": "evening", "weight": 0.30, "startHour": 15, "endHour": 20},
    {"label": "night", "weight": 0.15, "startHour": 20, "endHour": 24},
]

_SCENARIO_SEEDS_EN = [
    "Sunday afternoon sunbeam on the carpet",
    "A rainy evening when the cat refuses the new bowl",
    "Moving apartments and hiding under the bed for two days",
    "The first week after adopting a shy adult cat",
    "A busy work-from-home day with back-to-back calls",
    "Winter dry air and static-y fur",
    "A neighbor's fireworks night",
    "Introducing a second cat through a baby gate",
    "The cat suddenly ignoring the favorite window perch",
    "Meal prep chaos in a small kitchen",
]


def normalize_language(raw: Any) -> str:
    s = (str(raw).strip().lower() if raw is not None else "en")
    return s if s in ALLOWED_LANGUAGES else "en"


def normalize_content_style(raw: Any) -> str:
    s = (str(raw).strip().lower() if raw is not None else "")
    return s if s in CONTENT_STYLES else "professional_care"


def normalize_hemisphere(raw: Any) -> str:
    s = (str(raw).strip().lower() if raw is not None else "north")
    return "south" if s == "south" else "north"


def _normalize_topic_list(raw: list[str] | None) -> list[str]:
    if not raw:
        return list(DEFAULT_TOPICS)
    out: list[str] = []
    for t in raw:
        s = str(t).strip()
        if s in ALLOWED_TOPICS:
            out.append(s)
        elif s:
            out.append("care")
    return out if out else list(DEFAULT_TOPICS)


def normalize_content_topics(raw: Any) -> list[str]:
    if not isinstance(raw, list):
        return list(DEFAULT_TOPICS)
    return _normalize_topic_list([str(x).strip() for x in raw if str(x).strip()])


def normalize_schedule_windows(raw: Any) -> list[dict[str, Any]]:
    if not isinstance(raw, list) or len(raw) == 0:
        return [dict(w) for w in DEFAULT_SCHEDULE_WINDOWS_UTC]
    out: list[dict[str, Any]] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        try:
            w = float(item.get("weight", 0))
        except (TypeError, ValueError):
            w = 0.0
        try:
            sh = int(item.get("startHour", 0))
            eh = int(item.get("endHour", sh + 1))
        except (TypeError, ValueError):
            continue
        sh = max(0, min(23, sh))
        eh = max(sh + 1, min(24, eh))
        label = str(item.get("label") or "slot").strip() or "slot"
        if w <= 0:
            continue
        out.append({"label": label, "weight": w, "startHour": sh, "endHour": eh})
    return out if out else [dict(w) for w in DEFAULT_SCHEDULE_WINDOWS_UTC]


def content_generation_doc_defaults(raw: dict | None) -> dict:
    r = raw or {}
    topics = r.get("topics")
    if not topics or not isinstance(topics, list):
        topics_norm = list(DEFAULT_TOPICS)
    else:
        topics_norm = _normalize_topic_list([str(x).strip() for x in topics if str(x).strip()])
    daily = int(r.get("dailyCount", 5))
    daily = min(max(daily, 1), 20)
    hour = int(r.get("publishHourUtc", 1))
    hour = hour % 24
    min_len = int(r.get("minContentLength", 400))
    min_len = min(max(min_len, 100), 8000)
    pub_merged = {
        "authorId": "meowcare_editorial",
        "displayNames": dict(DEFAULT_PUBLISHER_NAMES),
        "authorAvatarUrl": "",
    }
    pub_raw = r.get("publisher")
    if isinstance(pub_raw, dict):
        if pub_raw.get("authorId"):
            pub_merged["authorId"] = str(pub_raw["authorId"]).strip() or pub_merged["authorId"]
        dn = pub_raw.get("displayNames")
        if isinstance(dn, dict):
            for k, v in dn.items():
                kk = str(k).strip().lower()
                if kk in ALLOWED_LANGUAGES:
                    pub_merged["displayNames"][kk] = str(v).strip()
        if pub_raw.get("authorAvatarUrl") is not None:
            pub_merged["authorAvatarUrl"] = str(pub_raw.get("authorAvatarUrl") or "").strip()
    sched_raw = r.get("scheduleWindowsUtc")
    schedule_windows = normalize_schedule_windows(sched_raw if sched_raw is not None else None)
    mmb = r.get("minMinutesBetweenPosts")
    try:
        min_btwn = int(mmb) if mmb is not None else None
    except (TypeError, ValueError):
        min_btwn = None
    if min_btwn is not None:
        min_btwn = max(1, min(min_btwn, 720))
    pstz = str(r.get("publishScheduleTimezone") or "").strip()
    out: dict[str, Any] = {
        "enabled": bool(r.get("enabled", True)),
        "dailyCount": daily,
        "publishHourUtc": hour,
        "topics": topics_norm,
        "language": normalize_language(r.get("language")),
        "useGemini": bool(r.get("useGemini", True)),
        "minContentLength": min_len,
        "imageRequired": bool(r.get("imageRequired", False)),
        "seasonHemisphere": normalize_hemisphere(r.get("seasonHemisphere")),
        "publisher": pub_merged,
        "scheduleWindowsUtc": schedule_windows,
        "publishScheduleTimezone": pstz,
    }
    if min_btwn is not None:
        out["minMinutesBetweenPosts"] = min_btwn
    return out


def get_content_generation_settings() -> dict:
    snap = db.collection("settings").document("content_generation").get()
    return content_generation_doc_defaults(snap.to_dict())


def resolve_publisher_for_language(cfg: dict, lang: str) -> tuple[str, str, str]:
    lang = normalize_language(lang)
    pub = cfg.get("publisher")
    author_id = "meowcare_editorial"
    display_name = DEFAULT_PUBLISHER_NAMES.get(lang, DEFAULT_PUBLISHER_NAMES["en"])
    avatar = ""
    if isinstance(pub, dict):
        author_id = str(pub.get("authorId") or author_id).strip() or author_id
        avatar = str(pub.get("authorAvatarUrl") or "").strip()
        dns = pub.get("displayNames")
        if isinstance(dns, dict):
            dn = str(dns.get(lang) or dns.get("en") or "").strip()
            if dn:
                display_name = dn
    return author_id, display_name, avatar


def build_source_key(breed: str, topic: str, language: str, content_style: str, date_iso: str) -> str:
    b = (breed or "Cat").strip()
    t = (topic or "care").strip()
    lang = normalize_language(language)
    st = normalize_content_style(content_style)
    return f"breed:{b}|topic:{t}|lang:{lang}|style:{st}|date:{date_iso}"


def source_key_exists(source_key: str) -> bool:
    q = db.collection("posts").where("sourceKey", "==", source_key).limit(1)
    return any(q.stream())


def _month_for_season_hemisphere(month: int, hemisphere: str) -> int:
    if hemisphere == "south":
        return (month + 5) % 12 + 1
    return month


def _season_word(month: int) -> str:
    if month in (12, 1, 2):
        return "winter"
    if month in (3, 4, 5):
        return "spring"
    if month in (6, 7, 8):
        return "summer"
    return "autumn"


def build_seasonal_context(now: datetime | None, hemisphere: str) -> str:
    now = now or datetime.now(timezone.utc)
    hem = normalize_hemisphere(hemisphere)
    m = _month_for_season_hemisphere(now.month, hem)
    season = _season_word(m)
    return (
        f"Calendar month (UTC): {now.month}. "
        f"For seasonal advice use {hem}ern-hemisphere framing: effective season ≈ {season} "
        f"(indoor-cat focus: temperature swings, hydration, shedding, holidays/stress)."
    )


def compute_scheduled_publish_timestamp(cfg: dict, now: datetime | None = None) -> datetime:
    """Legacy single-slot anchor (same calendar day UTC as publishHourUtc)."""
    now = now or datetime.now(timezone.utc)
    h = int(cfg.get("publishHourUtc", 1)) % 24
    return datetime(now.year, now.month, now.day, h, 0, 0, tzinfo=timezone.utc)


def _seconds_in_window(start_hour: int, end_hour_exclusive: int) -> int:
    lo = max(0, min(23, start_hour)) * 3600
    hi = max(lo + 1, min(24, end_hour_exclusive) * 3600)
    return random.randint(lo, hi - 1)


def _jitter_avoid_neat_wall_clock(dt: datetime) -> datetime:
    if dt.minute in (0, 30) and dt.second == 0:
        dt = dt + timedelta(seconds=random.randint(17, 283))
    elif dt.second == 0:
        dt = dt + timedelta(seconds=random.randint(1, 59))
    return dt


def build_batch_utc_publish_slots(count: int, cfg: dict, day: date) -> list[datetime]:
    """
    Random publish times on the given UTC calendar day: weighted windows, min spacing, avoid neat :00/:30.
    """
    count = max(0, int(count))
    if count == 0:
        return []
    windows = normalize_schedule_windows(cfg.get("scheduleWindowsUtc"))
    weights = [float(w.get("weight", 0.25)) for w in windows]
    ws = sum(weights) or 1.0
    weights = [w / ws for w in weights]
    day0 = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
    day_end = day0 + timedelta(days=1) - timedelta(seconds=1)
    slots: list[datetime] = []
    for _ in range(count):
        w = random.choices(windows, weights=weights, k=1)[0]
        sh = int(w["startHour"])
        eh = int(w["endHour"])
        sec = _seconds_in_window(sh, eh)
        dt = day0 + timedelta(seconds=sec)
        dt = _jitter_avoid_neat_wall_clock(dt)
        if dt > day_end:
            dt = day_end
        slots.append(dt)
    slots.sort()
    mmb = cfg.get("minMinutesBetweenPosts")
    if mmb is None:
        gap_min = max(8, 120 // max(count, 1))
    else:
        gap_min = max(1, int(mmb))
    gap_sec = gap_min * 60
    for i in range(1, len(slots)):
        prev = slots[i - 1]
        if (slots[i] - prev).total_seconds() < gap_sec:
            slots[i] = prev + timedelta(seconds=gap_sec)
    for i in range(len(slots)):
        if slots[i] > day_end:
            slots[i] = day_end
    for i in range(1, len(slots)):
        if slots[i] <= slots[i - 1]:
            slots[i] = min(slots[i - 1] + timedelta(seconds=random.randint(45, 200)), day_end)
    return slots


def _parse_gemini_json(text: str) -> dict[str, str] | None:
    if not text:
        return None
    t = text.strip()
    m = re.search(r"\{[\s\S]*\}", t)
    if m:
        t = m.group(0)
    try:
        obj = json.loads(t)
    except json.JSONDecodeError:
        return None
    if not isinstance(obj, dict):
        return None
    return {
        "title": str(obj.get("title", "")).strip(),
        "summary": str(obj.get("summary", "")).strip(),
        "content": str(obj.get("content", "")).strip(),
    }


def _title_suffix_for_style(lang: str, content_style: str) -> str:
    st = normalize_content_style(content_style)
    if st == "professional_care":
        if lang == "zh":
            return "｜日常小抄"
        if lang == "ja":
            return "｜今日のひと工夫"
        if lang == "ko":
            return "｜오늘의 팁"
        return " — notes from the hallway"
    if st == "cat_daily_story":
        if lang == "zh":
            return "｜今天的小剧场"
        if lang == "ja":
            return "｜今日のひと幕"
        if lang == "ko":
            return "｜오늘의 한 장면"
        return " — a small scene"
    if st == "owner_journal":
        if lang == "zh":
            return "｜铲屎官手记"
        if lang == "ja":
            return "｜飼い主メモ"
        if lang == "ko":
            return "｜집사 메모"
        return " — from my living room"
    if st == "seasonal_care":
        if lang == "zh":
            return "｜换季提醒"
        if lang == "ja":
            return "｜季節のひとこと"
        if lang == "ko":
            return "｜계절 체크"
        return " — season check-in"
    if st == "short_experience_share":
        if lang == "zh":
            return "｜经验碎碎念"
        if lang == "ja":
            return "｜短い共有"
        if lang == "ko":
            return "｜짧은 공유"
        return " — quick share"
    if st == "warm_healing":
        if lang == "zh":
            return "｜陪你一下"
        if lang == "ja":
            return "｜そっと寄り添う"
        if lang == "ko":
            return "｜함께 숨 쉬기"
        return " — a soft pause"
    return ""


def _clamp_title_chars(
    s: str,
    content_style: str,
    language: str,
    *,
    lo: int = 40,
    hi: int = 90,
) -> str:
    s = re.sub(r"\s+", " ", (s or "").strip())
    lang = normalize_language(language)
    if len(s) > hi:
        s = s[: hi - 1] + "…"
    if len(s) < lo:
        pad = _title_suffix_for_style(lang, content_style)
        s = (s + pad)[:hi]
        if len(s) < lo:
            s = (s + " · MeowCare").strip()[:hi]
    return s


def _clamp_summary_chars(s: str, lo: int = 120, hi: int = 220) -> str:
    s = re.sub(r"\s+", " ", (s or "").strip())
    if len(s) < lo:
        s = (s + " Observe your cat daily and adjust routines gradually.").strip()[:hi]
    if len(s) > hi:
        s = s[: hi - 1] + "…"
    return s


def _ensure_paragraphs(
    content: str,
    min_paragraphs: int = 5,
    max_paragraphs: int = 8,
) -> str:
    parts = [p.strip() for p in re.split(r"\n\s*\n", content) if p.strip()]
    if len(parts) >= min_paragraphs:
        return "\n\n".join(parts[:max_paragraphs])
    filler = (
        "If anything seems off, keep notes for a few days and contact your veterinarian with clear observations."
    )
    while len(parts) < min_paragraphs:
        parts.append(filler)
    return "\n\n".join(parts[:max_paragraphs])


def _paragraph_bounds_for_style(content_style: str) -> tuple[int, int]:
    st = normalize_content_style(content_style)
    if st == "short_experience_share":
        return 4, 6
    if st in ("warm_healing", "cat_daily_story", "owner_journal"):
        return 5, 7
    return 5, 8


def normalize_title_fingerprint(title: str, max_chars: int = 48) -> str:
    t = (title or "").lower()
    t = re.sub(r"[\s\W_]+", "", t, flags=re.UNICODE)
    return t[:max_chars]


def _build_shared_json_rules(lang_name: str) -> str:
    return f"""
STRICT OUTPUT RULES (all styles):
1) Return ONLY a single JSON object. No markdown fences. No extra text.
2) Keys: "title", "summary", "content" (all strings).
3) Output language (every field): {lang_name} — fully, naturally.
4) title: 40–90 characters (Unicode code points). Must NOT read like a dry manual headline every time
   (mix: question, moment, feeling, scene, or gentle advice — vary across posts).
5) summary: 120–220 characters. Sound like a community blurb, not a textbook abstract.
6) Do NOT start title or first paragraph with clichés such as: "Here are some tips", "In this article",
   "Today we will", "As a cat owner", "It's important to note". Open from a concrete cat-home moment instead.
7) Do NOT invent drug names or dosages. No definitive diagnosis. Include a brief non-medical disclaimer
   somewhere in the body (not necessarily the opening).
8) Keep guidance practical and cat-parent realistic; avoid sounding like a robot manual.
"""


def _build_style_instructions(
    content_style: str,
    tone: str,
    topic: str,
    angle: str,
    breed: str,
    seasonal_context: str,
    scenario_seed: str,
    min_p: int,
    max_p: int,
) -> str:
    st = normalize_content_style(content_style)
    base = f"""
Content style (pick this voice consistently): {st}
Tone hint (English label; apply in the output language): {tone}
Topic tag: {topic}
Focus angle (English; weave in naturally in the output language): {angle}
Breed / label: {breed}
Optional scene seed (weave in if it fits; do not contradict breed/topic): {scenario_seed}
Seasonal context for reminders: {seasonal_context}
Body: {min_p}–{max_p} paragraphs separated by TWO newlines (\\n\\n). Each paragraph 2–4 sentences unless
short_experience style says otherwise. Plain paragraphs only — no markdown headings.
"""
    if st == "professional_care":
        return (
            base
            + """
Write like a trusted community columnist: warm but clear. Cover in order (as paragraphs, not labels):
hook from daily life → why it matters → practical tips → common mistakes → gentle vet-care disclaimer.
"""
        )
    if st == "cat_daily_story":
        return (
            base
            + """
Write a believable everyday mini-story centered on a cat at home; third-person or close-cat POV is fine.
Let personality show. Weave 1–2 actionable care ideas naturally (not a listicle).
"""
        )
    if st == "owner_journal":
        return (
            base
            + """
Write as a forum-style journal entry from the human's voice (first person). Honest, specific, a little messy is OK.
Include one or two practical takeaways without turning into a lecture.
"""
        )
    if st == "seasonal_care":
        return (
            base
            + """
Lead with the current season's indoor-cat realities (comfort, water, shedding, routines, stress triggers).
Stay practical; avoid alarmism. Mention when to call a vet only as general guidance.
"""
        )
    if st == "short_experience_share":
        return (
            base
            + """
Write like a short community post: slightly informal, one anecdote + lessons learned + invite empathy.
4–6 paragraphs; paragraphs may be a bit shorter if it feels natural.
"""
        )
    if st == "warm_healing":
        return (
            base
            + """
Prioritize emotional validation for tired cat parents; soft, hopeful language. Still include 1–2 gentle, realistic care habits.
Avoid toxic positivity; no medical claims.
"""
        )
    return base


def _fallback_content(
    breed: str,
    topic: str,
    wiki_extract: str,
    cat: dict,
    language: str,
    content_style: str,
    *,
    min_len: int,
    seasonal_context: str,
) -> tuple[str, str, str]:
    angle = TOPIC_ANGLE_EN.get(topic, TOPIC_ANGLE_EN["care"])
    fact = (cat.get("description") or cat.get("temperament") or "").strip()
    if len(fact) > 280:
        fact = fact[:280] + "…"
    wiki = (wiki_extract or "")[:900]
    lang = normalize_language(language)
    st = normalize_content_style(content_style)
    min_p, max_p = _paragraph_bounds_for_style(st)

    def _disclaimer() -> str:
        if lang == "zh":
            return "提醒：这是日常陪伴向分享，不能替代兽医诊断；若猫咪持续不适请及时就医。"
        if lang == "ja":
            return "注意：一般的な情報であり診断の代わりにはなりません。異常が続く場合は獣医師へ。"
        if lang == "ko":
            return "안내: 일반 정보이며 진단을 대체하지 않습니다. 이상이 지속되면 수의사와 상담하세요."
        return (
            "Gentle reminder: this is community-style guidance, not a diagnosis. "
            "Contact your veterinarian if something worries you."
        )

    if st == "professional_care":
        if lang == "zh":
            title = _clamp_title_chars(f"{breed}｜{topic}：把照护拆成小步骤", st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(
                f"像社区帖一样聊聊「{angle}」：先观察再微调，{breed}在家更自在。{fact[:80]}",
                120,
                220,
            )
            p1 = f"昨晚我又蹲在那儿看了五分钟——不是矫情，是{breed}喝水的方式变了点，我就想先把「{topic}」这件事理顺。"
            p2 = f"为什么我会在意：猫很少大喊不舒服，更多藏在食欲、如厕和躲藏里。{('参考：' + wiki[:200] + '…') if wiki else ''}"
            p3 = "我会这样做：一次只改一个变量；把吃饭、铲屎、陪玩时间尽量固定；给藏身处和高处跳台。"
            p4 = "也说说容易踩的坑：长期忽视吃得少、频繁换粮换砂、用惩罚处理害怕。"
            p5 = _disclaimer()
            p6 = f"品种线索（资料可能为英文）：{fact}" if fact else "有个体差异，既往病史以兽医方案为准。"
            content = "\n\n".join([p1, p2, p3, p4, p5, p6])
        elif lang == "ja":
            title = _clamp_title_chars(f"{breed}の{topic}｜観察から始める家トレ", st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(
                f"{breed}と暮らす日常に「{topic}」を社区っぽく。{fact[:60]}",
                120,
                220,
            )
            p1 = f"今日のメモから入るね。{breed}の「{topic}」、いきなり全部変えずに、まず観察から。"
            p2 = "小さな変化がサインになりやすい。リズムと環境が安定すると、行動のトラブルも減りやすい。"
            p3 = "一度に変えるのは一つ。食事・トイレ・遊びの時間をなるべく固定し、メモを残す。"
            p4 = "よくある落とし穴：食欲不振の放置、フード/砂の短周期ローテ、恐怖への叱り。"
            p5 = _disclaimer()
            p6 = (wiki[:400] + "…") if wiki else "既往がある場合は獣医指示を優先。"
            content = "\n\n".join([p1, p2, p3, p4, p5, p6])
        elif lang == "ko":
            title = _clamp_title_chars(f"{breed} {topic}｜관찰부터 천천히", st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(
                f"{breed}와의 일상에서 '{topic}'를 커뮤니티 글처럼 정리해봤어요. {fact[:60]}",
                120,
                220,
            )
            p1 = f"오늘 적어둔 메모로 시작할게요. {breed}의 '{topic}'는 한 번에 다 바꾸기보다 관찰부터."
            p2 = "작은 변화가 신호일 수 있어요. 루틴과 환경이 안정되면 스트레스도 줄어듭니다."
            p3 = "한 번에 바꿀 건 하나. 식사·화장실·놀이 시간을 규칙적으로."
            p4 = "흔한 실수: 식욕 저하 방치, 사료/모래 과잉 변경, 두려움에 대한 벌."
            p5 = _disclaimer()
            p6 = (wiki[:400] + "…") if wiki else "기저질환은 수의사 지침 우선."
            content = "\n\n".join([p1, p2, p3, p4, p5, p6])
        else:
            title = _clamp_title_chars(
                f"{breed} and {topic.replace('_', ' ')} — small steps, calmer days",
                st,
                lang,
                lo=40,
                hi=90,
            )
            summary = _clamp_summary_chars(
                f"A community-style note on {angle} for {breed}. Start with watching, then tweak one thing. {fact[:100]}",
                120,
                220,
            )
            p1 = f"I'll start with last night: I noticed something tiny about how my {breed} moves through the day—so let's talk {topic.replace('_', ' ')} without turning it into a lecture."
            p2 = (
                f"Why it matters: cats telegraph stress in small ways—eating, litter, hiding, voice. "
                f"{('Context: ' + wiki[:240] + '…') if wiki else 'Predictable routines usually help.'}"
            )
            p3 = "What I actually do: change one variable at a time; keep meal/play rhythms steady; add hideouts and vertical space."
            p4 = "Common slip-ups: ignoring a quieter appetite for too long; rotating food/litter too fast; punishing fear."
            p5 = _disclaimer()
            p6 = f"Breed notes: {fact}" if fact else "If your cat has conditions, follow your vet's plan first."
            content = "\n\n".join([p1, p2, p3, p4, p5, p6])
    else:
        seed = random.choice(_SCENARIO_SEEDS_EN)
        if lang == "zh":
            title = _clamp_title_chars(f"{breed}｜{topic}：{seed[:18]}…", st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(
                f"像帖子一样记录一个小片段，顺便聊聊「{angle}」。{seasonal_context[:60]}… {fact[:50]}",
                120,
                220,
            )
            p1 = f"今天家里有点像这样：{seed}。我看着{breed}，又想到「{topic}」其实就藏在细节里。"
            p2 = "我不会装专家，只是把最近试过的两件事写下来：一次只改一点点；把观察记成几句话，比凭感觉靠谱。"
            p3 = f"季节/室温变化时，猫会更敏感——{seasonal_context[:120]}"
            p4 = _disclaimer()
            content = "\n\n".join([p1, p2, p3, p4])
        elif lang == "ja":
            title = _clamp_title_chars(f"{breed}｜{topic}のひとコマ", st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(
                f"社区みたいな短い記録。{angle}。{fact[:50]}",
                120,
                220,
            )
            p1 = f"今日の空気はこんな感じ：{seed}。そんな日の{breed}と「{topic}」。"
            p2 = "大げさな結論は避けて、試せる小さなこと：一つずつ変える／短いメモを残す。"
            p3 = seasonal_context[:200]
            p4 = _disclaimer()
            content = "\n\n".join([p1, p2, p3, p4])
        elif lang == "ko":
            title = _clamp_title_chars(f"{breed}｜{topic} 한 컷", st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(
                f"커뮤니티 글처럼 짧게. {angle}. {fact[:50]}",
                120,
                220,
            )
            p1 = f"오늘 집 분위기: {seed}. 그런 날의 {breed}와 '{topic}'."
            p2 = "한 번에 하나만 바꾸고, 짧게 메모 남기기."
            p3 = seasonal_context[:200]
            p4 = _disclaimer()
            content = "\n\n".join([p1, p2, p3, p4])
        else:
            title = _clamp_title_chars(
                f"{breed}, {topic.replace('_', ' ')} — {seed[:24]}",
                st,
                lang,
                lo=40,
                hi=90,
            )
            summary = _clamp_summary_chars(
                f"A community-style snippet about {angle} with {breed}. {fact[:100]}",
                120,
                220,
            )
            p1 = f"Scene: {seed}. If you share your home with a {breed}, {topic.replace('_', ' ')} often shows up in quiet moments like this."
            p2 = "Two habits that help me: change one thing at a time; keep a tiny log for a few days (food, water, litter, mood)."
            p3 = seasonal_context[:280]
            p4 = _disclaimer()
            content = "\n\n".join([p1, p2, p3, p4])

    content = _ensure_paragraphs(content, min_p, max_p)
    while len(content) < min_len:
        content += "\n\nKeep a simple weekly checklist: cords/plants/windows safety, litter freshness, and water bowl cleaning."
    return title, summary, content


async def _generate_with_gemini(
    breed: str,
    topic: str,
    cat: dict,
    wiki_extract: str,
    language: str,
    content_style: str,
    tone: str,
    scenario_seed: str,
    seasonal_context: str,
) -> dict[str, str] | None:
    if not GEMINI_API_KEY:
        return None

    lang_name = LANGUAGE_NAMES.get(normalize_language(language), "English")
    angle = TOPIC_ANGLE_EN.get(topic, TOPIC_ANGLE_EN["care"])
    min_p, max_p = _paragraph_bounds_for_style(content_style)
    shared = _build_shared_json_rules(lang_name)
    style_block = _build_style_instructions(
        content_style, tone, topic, angle, breed, seasonal_context, scenario_seed, min_p, max_p
    )

    def _run() -> dict[str, str] | None:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel(GEMINI_MODEL_ID)
        desc = (cat.get("description") or "")[:600]
        temp = (cat.get("temperament") or "")[:200]
        origin = (cat.get("origin") or "")[:120]
        wiki = (wiki_extract or "")[:1200]

        prompt = f"""You write for a warm cat-parent community app (not a corporate manual).

{shared}

Breed description (may be English; integrate naturally): {desc}
Temperament notes: {temp}
Origin hint: {origin}
Wikipedia extract reference (English; paraphrase/translate as needed): {wiki}

{style_block}

Vary sentence openings; do not mirror phrasing from your previous outputs.
"""
        try:
            r = model.generate_content(prompt)
            text = (r.text or "").strip()
            parsed = _parse_gemini_json(text)
            if not parsed:
                return None
            lang = normalize_language(language)
            st = normalize_content_style(content_style)
            title = _clamp_title_chars(parsed.get("title", ""), st, lang, lo=40, hi=90)
            summary = _clamp_summary_chars(parsed.get("summary", ""), 120, 220)
            content = _ensure_paragraphs(parsed.get("content", ""), min_p, max_p)
            if not title or not summary or not content:
                return None
            return {"title": title, "summary": summary, "content": content}
        except Exception as e:
            logger.warning("Gemini generation failed: %s", e)
            return None

    return await asyncio.to_thread(_run)


def _pick_topic_and_style(
    selected_topics: list[str],
    recent_pairs: deque[tuple[str, str]],
) -> tuple[str, str]:
    styles = list(CONTENT_STYLES)
    topics = list(selected_topics)
    recent_list = list(recent_pairs)
    banned = set(recent_list[-3:]) if recent_list else set()
    for _ in range(24):
        t = random.choice(topics)
        s = random.choice(styles)
        if (t, s) in banned:
            continue
        if len(recent_list) >= 1 and (t, s) == recent_list[-1]:
            continue
        return t, s
    return random.choice(topics), random.choice(styles)


async def build_post_dict(
    topic: str,
    cat: dict,
    *,
    cfg: dict,
    language: str,
    content_style: str,
    tone: str,
    scenario_seed: str = "",
    scheduled_publish_at: datetime | None = None,
) -> dict[str, Any]:
    lang = normalize_language(language)
    st = normalize_content_style(content_style)
    breed = (cat.get("breed_name") or "Cat").strip() or "Cat"
    wiki_extract, wiki_thumb = await fetch_wiki_summary_and_thumbnail(cat, breed)

    cat_img = (cat.get("image_url") or "").strip()
    if not cat_img.startswith("http"):
        cat_img = ""
    wt = wiki_thumb if wiki_thumb.startswith("http") else ""

    cover_url = cat_img or wt
    thumbnail_url = wt or cat_img
    has_image = bool(cover_url.startswith("http"))

    use_gemini = bool(cfg.get("useGemini", True))
    min_len = int(cfg.get("minContentLength", 400))
    image_required = bool(cfg.get("imageRequired", False))
    hem = normalize_hemisphere(cfg.get("seasonHemisphere"))
    seasonal_context = build_seasonal_context(datetime.now(timezone.utc), hem)
    seed = scenario_seed or random.choice(_SCENARIO_SEEDS_EN)

    used_gemini = False
    if use_gemini:
        gem = await _generate_with_gemini(
            breed, topic, cat, wiki_extract, lang, st, tone, seed, seasonal_context
        )
    else:
        gem = None
    if gem:
        title, summary, content = gem["title"], gem["summary"], gem["content"]
        used_gemini = True
    else:
        title, summary, content = _fallback_content(
            breed, topic, wiki_extract, cat, lang, st, min_len=min_len, seasonal_context=seasonal_context
        )

    while len(content) < min_len:
        content += "\n\nAdd gentle observation notes for 2–3 days before changing multiple habits at once."

    today = datetime.now(timezone.utc).date().isoformat()
    source_key = build_source_key(breed, topic, lang, st, today)

    if image_required and not has_image:
        status = "draft"
        sched_publish_at: datetime | None = None
    else:
        status = "scheduled"
        sched_publish_at = scheduled_publish_at or compute_scheduled_publish_timestamp(cfg)
        if sched_publish_at.tzinfo is None:
            sched_publish_at = sched_publish_at.replace(tzinfo=timezone.utc)
        else:
            sched_publish_at = sched_publish_at.astimezone(timezone.utc)

    content_len = len(content)
    author_id, author_display, author_avatar = resolve_publisher_for_language(cfg, lang)
    generated_by = f"meowcare:daily_generator:{GENERATOR_VERSION}|{GEMINI_MODEL_ID}"

    doc: dict[str, Any] = {
        "type": "official",
        "status": status,
        "title": title[:200],
        "summary": summary[:500],
        "content": content[:50000],
        "coverUrl": cover_url[:2000],
        "thumbnailUrl": (thumbnail_url[:2000] if thumbnail_url else ""),
        "hasImage": has_image,
        "language": lang,
        "topic": topic,
        "category": topic,
        "breedIds": [],
        "topics": [topic],
        "authorId": author_id[:128],
        "authorDisplayName": author_display[:200],
        "authorAvatarUrl": author_avatar[:2000],
        "likeCount": 0,
        "commentCount": 0,
        "score": 0.0,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "generatedAt": firestore.SERVER_TIMESTAMP,
        "autoGenerated": True,
        "isOfficialDailyContent": True,
        "contentStyle": st,
        "tone": tone[:64],
        "generatedBy": generated_by[:300],
        "sourceType": SOURCE_TYPE_VALUE,
        "sourceKey": source_key,
        "contentQuality": {
            "contentLength": content_len,
            "usedGemini": used_gemini,
        },
    }
    if sched_publish_at is not None:
        # Firestore set() 需要 datetime，不能用 protobuf Timestamp（会触发 encode 报错）。
        doc["scheduledPublishAt"] = sched_publish_at
    return doc


async def generate_daily_posts(
    count: int,
    topics: list[str] | None = None,
    *,
    cfg_override: dict[str, Any] | None = None,
    **_kwargs: Any,
) -> int:
    cfg = dict(cfg_override or get_content_generation_settings())
    cfg["language"] = normalize_language(cfg.get("language"))

    count = min(max(int(count), 0), 50)
    if count == 0:
        return 0

    selected = _normalize_topic_list(topics if topics else cfg.get("topics"))
    lang = normalize_language(cfg.get("language"))
    now_utc = datetime.now(timezone.utc)
    today = now_utc.date().isoformat()
    day_date = now_utc.date()
    slot_times = build_batch_utc_publish_slots(count, cfg, day_date)

    created = 0
    max_attempts_per_slot = 14
    recent_pairs: deque[tuple[str, str]] = deque(maxlen=3)
    title_fingerprints: set[str] = set()

    for batch_index in range(count):
        topic, content_style = _pick_topic_and_style(selected, recent_pairs)
        tone = random.choice(TONES)
        sched_at = slot_times[batch_index] if batch_index < len(slot_times) else None
        attempts = 0
        placed = False
        while attempts < max_attempts_per_slot and not placed:
            attempts += 1
            try:
                cat = await fetch_cat_image()
            except Exception as e:
                logger.warning(
                    "fetch_cat_image failed, using generic breed (TheCatAPI/network?): %s",
                    e,
                )
                cat = dict(_EMPTY_CAT_FOR_GENERATION)

            breed = (cat.get("breed_name") or "Cat").strip() or "Cat"
            st = normalize_content_style(content_style)
            sk = build_source_key(breed, topic, lang, st, today)
            if source_key_exists(sk):
                continue

            doc_final: dict[str, Any] | None = None
            for sub_try in range(3):
                seed = random.choice(_SCENARIO_SEEDS_EN)
                try:
                    doc_try = await build_post_dict(
                        topic,
                        cat,
                        cfg=cfg,
                        language=lang,
                        content_style=st,
                        tone=tone,
                        scenario_seed=seed,
                        scheduled_publish_at=sched_at,
                    )
                except Exception as e:
                    logger.warning("build_post_dict failed: %s", e)
                    doc_final = None
                    break
                fp = normalize_title_fingerprint(str(doc_try.get("title", "")))
                if fp and fp in title_fingerprints:
                    if bool(cfg.get("useGemini", True)) and sub_try < 2:
                        continue
                    doc_final = None
                    break
                doc_final = doc_try
                if fp:
                    title_fingerprints.add(fp)
                break

            if not doc_final:
                continue

            db.collection("posts").document().set(_coerce_value_for_firestore(doc_final))
            created += 1
            recent_pairs.append((topic, content_style))
            placed = True

        if not placed:
            logger.warning(
                "daily slot skipped after %s attempts (topic=%s style=%s)",
                max_attempts_per_slot,
                topic,
                content_style,
            )

    return created
