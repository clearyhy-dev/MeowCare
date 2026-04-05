import json
import logging
import re
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends
from firebase_admin import firestore
from pydantic import BaseModel, Field, model_validator

from app.config import GEMINI_API_KEY

logger = logging.getLogger(__name__)

MAX_CONTENT_LENGTH = 50000
MAX_SYMPTOM_LENGTH = 10000
from app.dependencies import require_admin, require_uid

router = APIRouter()
db = firestore.client()

MODEL_ID = "gemini-2.5-flash"


class RewriteBody(BaseModel):
    content: str = Field(..., max_length=MAX_CONTENT_LENGTH)
    locale: str = ""


def _rewrite_prompt(body: RewriteBody) -> str:
    lang_hint = ""
    if body.locale:
        lang_map = {
            "zh": "Simplified Chinese",
            "en": "English",
            "ja": "Japanese",
            "ko": "Korean",
            "de": "German",
            "es": "Spanish",
            "fr": "French",
            "ru": "Russian",
            "pt": "Portuguese",
        }
        lang_hint = (
            f"\nTARGET OUTPUT LANGUAGE: {lang_map.get(body.locale[:2].lower(), body.locale)} — "
            "use this if the input language is ambiguous or very short."
        )
    return f"""You help cat owners polish short text for a pet app (community posts, notes). Educational context only.

RULES:
- Keep the user's meaning, facts, and emotional tone. Do NOT add new medical claims, diagnoses, or invented symptoms.
- If the text is already clear, change lightly or return it nearly unchanged.
- Prefer the DOMINANT language of the input (mixed-language → match the main clause).{lang_hint}
- Avoid generic AI phrases ("I'd be happy to", "In conclusion"). Sound like a real person.
- Do not expand a short note into a long essay; keep similar length unless the original is unclear.
- No hashtags unless the user used them.

Return ONLY valid JSON (no markdown fences), exactly:
{{"rewritten": "<polished text>"}}"""


@router.post("/rewrite")
async def rewrite(body: RewriteBody, uid: str = Depends(require_uid)):
    """Return rewritten content; JSON shape stable. Falls back to original text on failure."""
    out: Dict[str, Any] = {
        "content": body.content,
        "ok": True,
        "fallback": False,
        "detected_locale": "",
    }
    if not GEMINI_API_KEY:
        logger.warning("rewrite: GEMINI_API_KEY missing, passthrough")
        out["fallback"] = True
        return out
    if not body.content.strip():
        return out
    try:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        prompt = _rewrite_prompt(body)
        json_cfg: Dict[str, Any] = {"response_mime_type": "application/json", "temperature": 0.25}
        try:
            model = genai.GenerativeModel(MODEL_ID, generation_config=json_cfg)
        except (TypeError, ValueError):
            model = genai.GenerativeModel(MODEL_ID)
        r = model.generate_content(prompt)
        raw = (r.text or "").strip()
        data = _parse_json_loose(raw)
        text_out = body.content
        if isinstance(data, dict):
            rw = data.get("rewritten")
            if isinstance(rw, str) and rw.strip():
                text_out = rw.strip()
            out["detected_locale"] = str(data.get("detected_locale") or "")[:12]
        if text_out == body.content and raw:
            # Retry plain: some SDKs drop JSON mode output
            model2 = genai.GenerativeModel(MODEL_ID)
            r2 = model2.generate_content(
                prompt + '\nIf you cannot output JSON, output ONLY the rewritten paragraph, nothing else.'
            )
            t2 = (r2.text or "").strip()
            if t2 and not t2.startswith("{"):
                text_out = t2
        out["content"] = text_out
        return out
    except Exception as e:
        logger.exception("rewrite failed: %s", e)
        return {**out, "ok": False, "fallback": True, "error": str(e)[:500]}


class SymptomBody(BaseModel):
    symptom: str = Field("", max_length=MAX_SYMPTOM_LENGTH)
    severity: str = "green"  # green | yellow | red
    locale: str = "en"
    app_language: str = ""
    user_language: str = ""

    @model_validator(mode="after")
    def normalize_app_language(self) -> "SymptomBody":
        if self.app_language and self.app_language.strip():
            return self.model_copy(update={"app_language": self.app_language.strip().lower()[:8]})
        raw = (self.locale or "en").replace("_", "-").strip()
        if not raw:
            return self.model_copy(update={"app_language": "en"})
        first = raw.split("-")[0].lower()
        return self.model_copy(update={"app_language": first if first else "en"})


def _lang_name_for_code(code: str) -> str:
    lang_map = {
        "zh": "Simplified Chinese",
        "en": "English",
        "ja": "Japanese",
        "ko": "Korean",
        "de": "German",
        "es": "Spanish",
        "fr": "French",
        "ru": "Russian",
        "pt": "Portuguese",
    }
    return lang_map.get((code or "en").lower()[:2], code or "English")


def _heuristic_script_hint(text: str) -> str:
    """Rough hint for prompt: is CJK / Latin dominant."""
    if not text or not text.strip():
        return ""
    sample = text.strip()[:800]
    cjk = sum(1 for ch in sample if "\u4e00" <= ch <= "\u9fff" or "\u3040" <= ch <= "\u30ff" or "\uac00" <= ch <= "\ud7af")
    lat = sum(1 for ch in sample if "a" <= ch.lower() <= "z")
    if cjk >= 3 and cjk >= lat:
        return "The input appears to be primarily CJK (Chinese/Japanese/Korean) script — respond in that language family, not English."
    if lat >= 8 and cjk == 0:
        return "The input appears primarily Latin-script — respond in that language (e.g. English if the text is English)."
    return ""


def _build_symptom_prompt(body: SymptomBody) -> str:
    app_lang_name = _lang_name_for_code(body.app_language)
    user_hint = ""
    if body.user_language and body.user_language.strip():
        user_hint = (
            f"Optional client hint: user may prefer {body.user_language.strip()!r} — use only if symptom language is ambiguous.\n"
        )
    script_hint = _heuristic_script_hint(body.symptom)
    sev = body.severity or "green"
    return f"""You are a careful, professional cat health EDUCATION assistant. You are NOT a veterinarian and must NOT diagnose.

OUTPUT LANGUAGE (strict priority):
1) Match the DOMINANT language of the user's symptom text (including CJK: Chinese vs Japanese vs Korean — choose correctly from characters and wording).
2) If the symptom is too short to tell, use {_lang_name_for_code(body.app_language)!r} (app UI language).
3) Do NOT default to English when the user wrote clearly in another language.

{user_hint}{script_hint}
USER-SELECTED URGENCY (from app UI): {sev!r}
- green = mild / monitoring
- yellow = moderate concern
- red = high concern / possible emergency
You must set JSON field "severity" to one of: "green", "yellow", "red". It may match the user's selection or be ONE step higher if red flags in the text justify it; never downplay clear emergencies.

CONTENT RULES:
- Be concise and stable in length: summary 2–4 sentences; lists limited (causes ≤6 short items; next_questions ≤5).
- "possible_causes" = common NON-diagnostic possibilities only; use cautious wording ("may", "could").
- "watch_at_home" = safe observation steps only.
- "seek_vet_now" = clear criteria for urgent or emergency veterinary care.
- "next_questions" = short questions the owner could answer for a vet or in a follow-up message.
- "disclaimer" = one mandatory sentence: educational only; not a substitute for a licensed veterinarian.

SYMPTOM TEXT:
{body.symptom!r}

Return ONLY valid JSON (no markdown), exactly this shape:
{{
  "detected_language": "<ISO 639-1 code, e.g. zh, en, ja, ko>",
  "severity": "green|yellow|red",
  "summary": "<string>",
  "possible_causes": ["<string>", "..."],
  "watch_at_home": "<string>",
  "seek_vet_now": "<string>",
  "next_questions": ["<string>", "..."],
  "disclaimer": "<string>"
}}"""


def _parse_json_loose(text: str) -> Any:
    if not text or not text.strip():
        return None
    s = text.strip()
    if s.startswith("```"):
        s = re.sub(r"^```(?:json)?\s*", "", s)
        s = re.sub(r"\s*```\s*$", "", s)
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        return None


def _as_str_list(val: Any, *, max_items: int = 8, max_len: int = 400) -> List[str]:
    out: List[str] = []
    if isinstance(val, list):
        for x in val[:max_items]:
            t = str(x).strip()
            if t:
                out.append(t[:max_len])
    elif isinstance(val, str) and val.strip():
        out = [val.strip()[:max_len]]
    return out


def _normalize_severity(raw: Any, fallback: str) -> str:
    s = str(raw or "").strip().lower()
    if s in ("green", "yellow", "red"):
        return s
    if s in ("1", "2", "3"):
        return {"1": "green", "2": "yellow", "3": "red"}[s]
    return fallback if fallback in ("green", "yellow", "red") else "yellow"


def _legacy_advice_sections(
    summary: str,
    possible_causes: List[str],
    watch_at_home: str,
    seek_vet_now: str,
    next_questions: List[str],
    disclaimer: str,
) -> Dict[str, str]:
    causes_txt = "; ".join(possible_causes) if possible_causes else ""
    _ = next_questions  # retained for signature compatibility with older callers
    return {
        "summary": summary,
        "risk_warnings": causes_txt[:8000],
        "home_care": watch_at_home,
        "vet_when": seek_vet_now,
        "reassurance": "",
        "disclaimer": disclaimer,
    }


def _flatten_advice(
    summary: str,
    possible_causes: List[str],
    watch_at_home: str,
    seek_vet_now: str,
    next_questions: List[str],
    disclaimer: str,
) -> str:
    parts: List[str] = []
    if summary:
        parts.append(summary)
    if possible_causes:
        parts.append("Possible causes (non-diagnostic): " + "; ".join(possible_causes))
    if watch_at_home:
        parts.append("Home observation: " + watch_at_home)
    if seek_vet_now:
        parts.append("When to seek a vet urgently: " + seek_vet_now)
    if next_questions:
        parts.append("Questions to consider: " + " | ".join(next_questions))
    if disclaimer:
        parts.append(disclaimer)
    return "\n\n".join(parts)


def _fallback_symptom_payload(body: SymptomBody, reason: str, exc: Optional[BaseException] = None) -> Dict[str, Any]:
    if exc is not None:
        logger.warning("symptom fallback (%s): %s", reason, exc, exc_info=exc)
    else:
        logger.warning("symptom fallback (%s)", reason)
    code = (body.app_language or "en").lower()[:2]
    sev = _normalize_severity(body.severity, "yellow")
    sym = (body.symptom or "").strip()[:500]

    templates = {
        "zh": {
            "summary": f"无法生成完整 AI 分析（{reason}）。以下为安全提示，不能替代兽医诊断。您描述的情况：「{sym}」。",
            "causes": ["环境刺激", "轻度胃肠不适", "应激反应（需结合个体情况）"],
            "watch": "保持环境安静、提供清水，记录食欲/精神/呕吐/排便变化；避免自行用药。",
            "vet": "若出现呼吸困难、持续呕吐、精神极差、超过24小时拒食、排尿困难或疼痛加剧，请尽快就医或急诊。",
            "nq": ["症状从何时开始？", "是否接触过新食物或新环境？", "是否同时有多只动物不适？"],
            "dis": "以上内容仅供教育参考，不能替代执业兽医的面对面诊断与治疗。",
        },
        "ja": {
            "summary": f"AI の詳細分析を生成できませんでした（{reason}）。以下は安全上の参考です。症状：「{sym}」。",
            "causes": ["環境要因", "軽い胃腸の不調", "ストレス（個体差あり）"],
            "watch": "静かな環境と水を確保し、食欲・精神・嘔吐・排泄の変化を記録してください。自己判断での投薬は避けてください。",
            "vet": "呼吸困難、嘔吐が続く、極度の無気力、24時間以上の拒食、排尿困難や痛みの増強がある場合は早急に受診してください。",
            "nq": ["いつから症状がありますか？", "新しい食物や環境の変化はありますか？", "他の動物にも症状はありますか？"],
            "dis": "教育目的の情報であり、獣医師の診断・治療に代わるものではありません。",
        },
        "ko": {
            "summary": f"AI 분석을 완성할 수 없습니다({reason}). 아래는 안전 안내이며 수의사 진단을 대체하지 않습니다. 증상: 「{sym}」.",
            "causes": ["환경 자극", "경미한 소화기 불편", "스트레스(개체차 있음)"],
            "watch": "조용한 환경과 물을 제공하고 식욕/활력/구토/배변 변화를 기록하세요. 임의 투약은 피하세요.",
            "vet": "호흡 곤란, 구토 지속, 극심한 무기력, 24시간 이상 식욕 부진, 배뇨 곤란 또는 통증 악화 시 즉시 병원에 가세요.",
            "nq": ["언제부터 증상이 있나요?", "새 사료나 환경 변화가 있었나요?", "다른 반려동물에도 증상이 있나요?"],
            "dis": "교육 목적의 정보이며 면허 수의사의 진단·치료를 대체하지 않습니다.",
        },
        "en": {
            "summary": f"We couldn't complete the AI analysis ({reason}). This is safety guidance only, not a diagnosis. You described: \"{sym}\".",
            "causes": ["Environmental factors", "Mild GI upset", "Stress (individual variation)"],
            "watch": "Keep the area calm, offer fresh water, and track appetite, energy, vomiting, and litter box changes. Avoid medications without veterinary guidance.",
            "vet": "Seek urgent care if you notice labored breathing, repeated vomiting, extreme lethargy, no eating for over 24 hours, trouble urinating, or escalating pain.",
            "nq": ["When did this start?", "Any new food or environment changes?", "Other pets affected?"],
            "dis": "Educational information only; not a substitute for diagnosis or treatment by a licensed veterinarian.",
        },
    }
    lang_key = code if code in templates else "en"
    t = templates[lang_key]

    summary = t["summary"]
    causes = t["causes"]
    watch = t["watch"]
    vet = t["vet"]
    nq = t["nq"]
    dis = t["dis"]
    detected = code if code in ("zh", "ja", "ko", "en") else "en"
    sections = _legacy_advice_sections(summary, causes, watch, vet, nq, dis)
    advice = _flatten_advice(summary, causes, watch, vet, nq, dis)
    return {
        "ok": False,
        "fallback": True,
        "error_detail": reason[:500],
        "model": MODEL_ID,
        "detected_language": lang_key,
        "response_language": lang_key,
        "severity": sev,
        "summary": summary,
        "possible_causes": causes,
        "watch_at_home": watch,
        "seek_vet_now": vet,
        "next_questions": nq,
        "disclaimer": dis,
        "advice": advice,
        "advice_sections": sections,
    }


def _merge_model_dict(data: Dict[str, Any], body: SymptomBody) -> Optional[Dict[str, Any]]:
    if not isinstance(data, dict):
        return None
    summary = str(data.get("summary") or "").strip()
    sev_fb = body.severity or "green"
    severity = _normalize_severity(data.get("severity"), sev_fb)
    detected = str(data.get("detected_language") or "").strip().lower()[:12]
    causes = _as_str_list(data.get("possible_causes"))
    watch = str(data.get("watch_at_home") or "").strip()
    vet = str(data.get("seek_vet_now") or "").strip()
    nq = _as_str_list(data.get("next_questions"))
    dis = str(data.get("disclaimer") or "").strip()

    if not summary and not causes and not watch and not vet:
        return None

    if not dis:
        dis = (
            "This information is educational only and not a substitute for diagnosis or treatment by a licensed veterinarian."
        )

    sections = _legacy_advice_sections(summary, causes, watch, vet, nq, dis)
    advice = _flatten_advice(summary, causes, watch, vet, nq, dis)
    resp_lang = detected or (body.app_language or "en")[:2]
    return {
        "ok": True,
        "fallback": False,
        "error_detail": None,
        "model": MODEL_ID,
        "detected_language": resp_lang,
        "response_language": resp_lang,
        "severity": severity,
        "summary": summary,
        "possible_causes": causes,
        "watch_at_home": watch,
        "seek_vet_now": vet,
        "next_questions": nq,
        "disclaimer": dis,
        "advice": advice,
        "advice_sections": sections,
    }


@router.post("/symptom")
async def symptom_advice(body: SymptomBody, uid: str = Depends(require_uid)):
    """Structured symptom guidance JSON; stable shape; always returns 200 with safe payload when possible."""
    if not GEMINI_API_KEY:
        return _fallback_symptom_payload(body, "GEMINI_API_KEY not configured")

    prompt = _build_symptom_prompt(body)
    try:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        json_cfg: Dict[str, Any] = {"response_mime_type": "application/json", "temperature": 0.35}
        try:
            model = genai.GenerativeModel(MODEL_ID, generation_config=json_cfg)
        except (TypeError, ValueError):
            model = genai.GenerativeModel(MODEL_ID)
        r = model.generate_content(prompt)
        raw = (r.text or "").strip()
        data = _parse_json_loose(raw)
        merged: Optional[Dict[str, Any]] = None
        if isinstance(data, dict):
            merged = _merge_model_dict(data, body)
        if merged is None and raw:
            r2 = genai.GenerativeModel(MODEL_ID).generate_content(
                prompt + "\n\nOutput valid JSON only. No markdown. No extra keys."
            )
            data2 = _parse_json_loose(r2.text or "")
            if isinstance(data2, dict):
                merged = _merge_model_dict(data2, body)
        if merged is None:
            # Last resort: stuff raw text into summary for display
            if raw:
                fake = {
                    "detected_language": (body.app_language or "en")[:2],
                    "severity": body.severity,
                    "summary": raw[:8000],
                    "possible_causes": [],
                    "watch_at_home": "",
                    "seek_vet_now": "",
                    "next_questions": [],
                    "disclaimer": (
                        "Educational only; not a substitute for a licensed veterinarian."
                    ),
                }
                merged = _merge_model_dict(fake, body)
        if merged is None:
            return _fallback_symptom_payload(body, "empty_or_unparseable_model_output")

        return merged
    except Exception as e:
        logger.exception("symptom_advice model error: %s", e)
        return _fallback_symptom_payload(body, "model_or_network_error", e)


class GenerateBody(BaseModel):
    breed: str = ""
    topic: str = ""
    count: int = 1


@router.post("/generate")

async def generate(body: GenerateBody, uid: str = Depends(require_admin)):
    """Generate draft official posts and write to Firestore."""
    if not GEMINI_API_KEY:
        return {"created": 0, "message": "GEMINI_API_KEY not set"}
    try:
        import google.generativeai as genai
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-1.5-flash")
        created = 0
        for _ in range(min(body.count, 5)):
            prompt = f"Write a short cat care article. Breed: {body.breed or 'any'}. Topic: {body.topic or 'general care'}. Output JSON with keys: title, content (plain text)."
            r = model.generate_content(prompt)
            text = r.text or "{}"
            if "title" in text:
                import json
                try:
                    data = json.loads(text) if text.strip().startswith("{") else {"title": "Generated", "content": text}
                except json.JSONDecodeError:
                    data = {"title": "Generated", "content": text}
                ref = db.collection("posts").document()
                ref.set({
                    "type": "official",
                    "status": "draft",
                    "title": data.get("title", "Generated"),
                    "content": data.get("content", ""),
                    "coverUrl": "",
                    "breedIds": [body.breed] if body.breed else [],
                    "topics": [body.topic] if body.topic else [],
                    "authorId": uid,
                    "likeCount": 0,
                    "commentCount": 0,
                    "score": 0.0,
                    "createdAt": firestore.SERVER_TIMESTAMP,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })
                created += 1
        return {"created": created}
    except Exception as e:
        return {"created": 0, "error": str(e)}
