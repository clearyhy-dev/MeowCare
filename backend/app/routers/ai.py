import json
import re
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends
from firebase_admin import firestore
from pydantic import BaseModel, Field, model_validator

from app.config import GEMINI_API_KEY

MAX_CONTENT_LENGTH = 50000
MAX_SYMPTOM_LENGTH = 10000
from app.dependencies import require_admin, require_uid

router = APIRouter()
db = firestore.client()


class RewriteBody(BaseModel):
    content: str = Field(..., max_length=MAX_CONTENT_LENGTH)
    locale: str = ""


@router.post("/rewrite")
async def rewrite(body: RewriteBody, uid: str = Depends(require_uid)):
    """Return rewritten content in the requested locale; does not write to DB."""
    lang_hint = ""
    if body.locale:
        lang_map = {"zh": "简体中文", "en": "English", "ja": "日本語", "ko": "한국어", "de": "Deutsch", "es": "Español", "fr": "Français", "ru": "Русский"}
        lang_hint = f" Output in {lang_map.get(body.locale, body.locale)}."
    if not GEMINI_API_KEY:
        return {"content": body.content}
    try:
        import google.generativeai as genai
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-flash")
        out_content = body.content
        if body.content.strip():
            r = model.generate_content(
                f"Rewrite the following text to be clearer and more polished. Keep the same meaning.{lang_hint}\n\n{body.content}"
            )
            out_content = r.text or body.content
        return {"content": out_content}
    except Exception:
        return {"content": body.content}


class SymptomBody(BaseModel):
    symptom: str = Field("", max_length=MAX_SYMPTOM_LENGTH)
    severity: str = "green"  # green | yellow | red
    locale: str = "en"  # BCP 47 tag from client (e.g. zh-CN); legacy clients send short code too
    app_language: str = ""  # App UI code: en, zh, ja, … (Flutter effectiveUILanguageCodeProvider)
    user_language: str = ""  # Optional hint from client script heuristics; empty = detect from symptom only

    @model_validator(mode="after")
    def normalize_app_language(self) -> "SymptomBody":
        # Old clients only send `locale`: derive app_language from first subtag (zh-CN -> zh).
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


def _build_symptom_prompt(body: SymptomBody) -> str:
    """Instructions for multilingual, structured cat symptom guidance (not veterinary diagnosis)."""
    app_lang_name = _lang_name_for_code(body.app_language)
    user_hint = ""
    if body.user_language and body.user_language.strip():
        user_hint = (
            f"The client suggests the user's primary language may be {body.user_language.strip()!r}; "
            "use this only if the symptom text is ambiguous. "
        )
    return f"""You are a professional, warm cat care assistant (educational only). You are NOT a veterinarian.

TASK — LANGUAGE (critical):
1) Detect the user's PRIMARY language from their symptom description (including mixed-language input; pick the dominant language).
2) Write the ENTIRE response in that SAME language. Do NOT default to English.
3) Do NOT translate the user's message into English unless they wrote primarily in English or explicitly asked for English.
4) If you truly cannot detect language from the text, write in {_lang_name_for_code(body.app_language)!r} (app UI language).
5) If that is still unclear, use English.
{user_hint}
SEVERITY (from app): {body.severity!r} (green=mild, yellow=moderate concern, red=urgent concern).

SYMPTOM TEXT:
{body.symptom!r}

OUTPUT FORMAT — respond with ONLY valid JSON (no markdown fences), exactly this shape:
{{
  "detected_language": "<ISO 639-1 or same short code as input, e.g. zh, en, es, ja>",
  "response_language": "<language you actually wrote in; must match user unless fallback rule 4/5>",
  "advice_sections": {{
    "summary": "<1-3 sentences: brief impression / what it might suggest, non-diagnostic>",
    "risk_warnings": "<red flags / what to watch; if severity is red, stress caution>",
    "home_care": "<gentle home observation steps; safe, non-invasive>",
    "vet_when": "<clear criteria for when they must see a vet soon or urgently>",
    "reassurance": "<one short calming sentence>",
    "disclaimer": "<one sentence: educational only, not a substitute for a licensed veterinarian>"
  }}
}}

STYLE: professional, empathetic, natural in the target language (not machine translation tone)."""


def _parse_symptom_json(text: str) -> Optional[Dict[str, Any]]:
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


def _empty_sections() -> Dict[str, str]:
    return {
        "summary": "",
        "risk_warnings": "",
        "home_care": "",
        "vet_when": "",
        "reassurance": "",
        "disclaimer": "",
    }


@router.post("/symptom")
async def symptom_advice(body: SymptomBody, uid: str = Depends(require_uid)):
    """Structured multilingual AI symptom guidance. Same language as user; not a substitute for a vet."""
    model_id = "gemini-2.5-flash"
    empty_resp = {
        "advice": "",
        "model": "",
        "detected_language": "",
        "response_language": "",
        "advice_sections": _empty_sections(),
    }
    if not GEMINI_API_KEY:
        return empty_resp

    prompt = _build_symptom_prompt(body)
    try:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        json_cfg: Dict[str, Any] = {"response_mime_type": "application/json", "temperature": 0.35}
        try:
            model = genai.GenerativeModel(model_id, generation_config=json_cfg)
        except (TypeError, ValueError):
            model = genai.GenerativeModel(model_id)
        r = model.generate_content(prompt)
        raw = (r.text or "").strip()
        data = _parse_symptom_json(raw)
        if not data:
            # Retry once without JSON mode (older SDK / model quirk)
            model_plain = genai.GenerativeModel(model_id)
            r2 = model_plain.generate_content(prompt + "\n\nOutput raw JSON only, no markdown.")
            data = _parse_symptom_json(r2.text or "")

        sections = _empty_sections()
        detected = ""
        response_lang = ""
        if data and isinstance(data, dict):
            detected = str(data.get("detected_language") or "").strip().lower()[:12]
            response_lang = str(data.get("response_language") or "").strip().lower()[:12]
            adv = data.get("advice_sections")
            if isinstance(adv, dict):
                for k in sections:
                    if k in adv and adv[k] is not None:
                        sections[k] = str(adv[k]).strip()

        if not any(v.strip() for v in sections.values()) and raw:
            sections["summary"] = raw[:8000]

        # Flatten for legacy clients
        parts = [
            sections["summary"],
            sections["risk_warnings"],
            sections["home_care"],
            sections["vet_when"],
            sections["reassurance"],
            sections["disclaimer"],
        ]
        advice = "\n\n".join(p for p in parts if p)

        return {
            "advice": advice,
            "model": model_id,
            "detected_language": detected,
            "response_language": response_lang or detected or body.app_language,
            "advice_sections": sections,
        }
    except Exception:
        return {**empty_resp, "model": model_id}


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

