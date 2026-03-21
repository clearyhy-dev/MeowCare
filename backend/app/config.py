import os

from dotenv import load_dotenv

load_dotenv()

GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
# The Cat API（可选）：提高免费额度与稳定性 https://thecatapi.com/
THE_CAT_API_KEY = (os.getenv("THE_CAT_API_KEY") or "").strip()
PORT = int(os.getenv("PORT", "8000"))
ENV = (os.getenv("ENV") or "development").strip().lower()
IS_PRODUCTION = ENV == "production"

# 后台管理系统账号密码（仅用于 /admin 页面登录）
_admin_user = os.getenv("ADMIN_USERNAME")
ADMIN_USERNAME = (_admin_user or "admin").strip() or "admin"
_admin_pass = os.getenv("ADMIN_PASSWORD")
if IS_PRODUCTION and (not _admin_pass or _admin_pass.strip() == ""):
    raise ValueError("ADMIN_PASSWORD must be set in production (set ENV=production)")
ADMIN_PASSWORD = (_admin_pass if _admin_pass is not None and _admin_pass != "" else "wu2612103")

_secret = os.getenv("SECRET_KEY")
if IS_PRODUCTION and (not _secret or _secret.strip() == ""):
    raise ValueError("SECRET_KEY must be set in production (set ENV=production)")
SECRET_KEY = (_secret or "meowcare-admin-secret-change-in-production").strip() or "meowcare-admin-secret-change-in-production"

# CORS: production 应从环境变量读取允许的源，如 CORS_ORIGINS=https://app.example.com,https://admin.example.com
CORS_ORIGINS_RAW = os.getenv("CORS_ORIGINS", "").strip()
CORS_ORIGINS = [o.strip() for o in CORS_ORIGINS_RAW.split(",") if o.strip()] if CORS_ORIGINS_RAW else []


