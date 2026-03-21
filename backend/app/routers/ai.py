from typing import Any

from fastapi import APIRouter, Depends
from firebase_admin import firestore
from pydantic import BaseModel, Field

from app.config import GEMINI_API_KEY

MAX_CONTENT_LENGTH = 50000
MAX_SYMPTOM_LENGTH = 10000
from app.dependencies import require_admin, require_uid

router = APIRouter()
db = firestore.client()


class RewriteBody(BaseModel):
    content: str = Field(..., max_length=MAX_CONTENT_LENGTH)
    summary: str = Field("", max_length=MAX_CONTENT_LENGTH)
    locale: str = ""


@router.post("/rewrite")
async def rewrite(body: RewriteBody, uid: str = Depends(require_uid)):
    """Return rewritten content (and optionally summary) in the requested locale; does not write to DB."""
    lang_hint = ""
    if body.locale:
        lang_map = {"zh": "简体中文", "en": "English", "ja": "日本語", "ko": "한국어", "de": "Deutsch", "es": "Español", "fr": "Français", "ru": "Русский"}
        lang_hint = f" Output in {lang_map.get(body.locale, body.locale)}."
    if not GEMINI_API_KEY:
        return {"content": body.content, "summary": body.summary}
    try:
        import google.generativeai as genai
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-2.5-flash")
        out_content = body.content
        out_summary = body.summary
        if body.content.strip():
            r = model.generate_content(
                f"Rewrite the following text to be clearer and more polished. Keep the same meaning.{lang_hint}\n\n{body.content}"
            )
            out_content = r.text or body.content
        if body.summary.strip():
            r2 = model.generate_content(
                f"Rewrite the following short summary to be clearer and concise. Keep the same meaning.{lang_hint}\n\n{body.summary}"
            )
            out_summary = r2.text or body.summary
        return {"content": out_content, "summary": out_summary}
    except Exception:
        return {"content": body.content, "summary": body.summary}


class SymptomBody(BaseModel):
    symptom: str = Field("", max_length=MAX_SYMPTOM_LENGTH)
    severity: str = "green"  # green | yellow | red
    locale: str = "en"



@router.post("/symptom")
async def symptom_advice(body: SymptomBody, uid: str = Depends(require_uid)):
    """Return AI advice for the given symptom in the requested language. Not a substitute for vet."""
    lang_map = {
        "zh": "简体中文",
        "en": "English",
        "ja": "日本語",
        "ko": "한국어",
        "de": "Deutsch",
        "es": "Español",
        "fr": "Français",
        "ru": "Русский",
    }
    lang_hint = f" Respond in {lang_map.get(body.locale, body.locale or 'English')} only."
    if not GEMINI_API_KEY:
        return {"advice": "", "model": ""}
    try:
        import google.generativeai as genai

        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel("gemini-1.5-flash")
        prompt = (
            "You are a pet care assistant. Give brief informational guidance only; this is NOT a substitute for veterinary care. "
            f"User's cat symptom: {body.symptom!r}. Severity: {body.severity}.{lang_hint} "
            "Keep the response short (2–4 sentences)."
        )
        r = model.generate_content(prompt)
        advice = (r.text or "").strip()
        return {"advice": advice, "model": "gemini-2.5-flash"}
    except Exception:
        return {"advice": "", "model": "gemini-2.5-flash"}


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
            prompt = f"Write a short cat care article. Breed: {body.breed or 'any'}. Topic: {body.topic or 'general care'}. Output JSON with keys: title, summary, content (plain text)."
            r = model.generate_content(prompt)
            text = r.text or "{}"
            if "title" in text and "summary" in text:
                import json
                try:
                    data = json.loads(text) if text.strip().startswith("{") else {"title": "Generated", "summary": "", "content": text}
                except json.JSONDecodeError:
                    data = {"title": "Generated", "summary": "", "content": text}
                ref = db.collection("posts").document()
                ref.set({
                    "type": "official",
                    "status": "draft",
                    "title": data.get("title", "Generated"),
                    "summary": data.get("summary", ""),
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

