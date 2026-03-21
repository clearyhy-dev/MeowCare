# MeowCare

Flutter 家庭养猫护理应用：Feed、猫档案、任务与健康提醒、7 天计划、UGC 发帖与审核、FastAPI 后台与 AI 润色。

## 1. Firebase 配置

1. **创建项目**：在 [Firebase Console](https://console.firebase.google.com) 创建项目，启用 **Authentication**、**Firestore**、**Storage**。
2. **认证**：在 Authentication 中启用 **Google** 登录（Flutter 用户端仅使用 Google；Email/Password 可在控制台关闭，不影响 FastAPI 管理页账号密码）。
3. **应用**：为 Android/iOS/Web 添加应用，下载 `google-services.json`（Android）与 `GoogleService-Info.plist`（iOS），放入项目对应位置。
4. **详细步骤**：见 [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)。

## 2. 管理员（后台鉴权）

**后台管理页面（账号密码登录）**：访问 `https://你的后端地址/admin`，使用账号 **admin**、密码 **wu2612103** 登录（可在 `.env` 中通过 `ADMIN_USERNAME`、`ADMIN_PASSWORD` 修改）。登录后可管理品种、待审 UGC、举报等。  
**Cloud Run 上若用 `--update-env-vars` 设密码仍无法登录**：Windows 下密码里的 `!` 会被解释，请改用 Secret Manager 存密码，见 [docs/CLOUD_RUN_DEPLOY.md#后台管理员密码](docs/CLOUD_RUN_DEPLOY.md)。


**API 鉴权**：后台 API 同时支持 (1) 上述管理页登录后获得的 JWT，和 (2) Firebase ID Token + Firestore/custom claim 管理员。  
- **方式 A**：在 Firebase Auth 中为该用户设置 **Custom Claim** `admin: true`（通过 Admin SDK 或云函数）。  
- **方式 B**：在 Firestore 中创建 **admins** 集合，文档 ID 为管理员 uid。

仅管理员可访问：breeds 写、官方 post、UGC 审核、reports 处理。


## 3. Firestore 规则与索引

在项目根目录执行：

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

确保根目录存在 `firestore.rules` 与 `firestore.indexes.json`。索引与查询一一对应（见 `firestore.indexes.json`）。

## 4. Storage 规则

在 Firebase Console → Storage → 规则中，允许认证用户按路径读写本人资源，例如：

- `avatars/{uid}/{id}.jpg`：仅 uid 可写；
- `covers/{postId}.jpg`：创建者或约定规则。

具体与项目 `firestore.rules` 中 Storage 部分一致（若已单独配置）。

## 5. Flutter 运行

```bash
flutter pub get
flutter run
```

默认已使用 Cloud Run 后端（如 `https://meowcare-api-xxx.asia-east1.run.app`），发帖页「AI 润色」会请求该地址。如需改用本地后端：

```bash
flutter run --dart-define=MEOWCARE_BACKEND_URL=http://10.0.2.2:8000
```

（Android 模拟器用 `10.0.2.2` 表示本机；iOS 模拟器可用 `http://localhost:8000`。）

分享功能使用 `share_plus`；应用下载链接与帖子 Web 链接可在构建时覆盖：

- `MEOWCARE_APP_URL`：默认 Google Play 包名链接；
- `MEOWCARE_POST_WEB_BASE`：默认 `https://meowcare.app/post`（占位，有正式站点后替换）。

## 6. FastAPI 后台运行

```bash
cd backend
pip install -r requirements.txt
```

复制 `.env.example` 为 `.env`，配置：

- `GOOGLE_APPLICATION_CREDENTIALS`：Firebase 服务账号 JSON 路径；
- `GEMINI_API_KEY`（可选）：用于 AI 润色与生成；
- `PORT`（可选）：默认 8000。

启动：

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

CORS 已允许 Flutter 域名/本地访问；生产环境请按需限制 `allow_origins`。

**Cloud Run 重新部署**（改代码、改环境变量、强制重启、删除重建）：见 [docs/CLOUD_RUN_DEPLOY.md](docs/CLOUD_RUN_DEPLOY.md)。

---

## 验收清单（按功能）


| 功能 | 验收方式 |
|------|----------|
| **猫档案** | 创建猫可选品种、上传头像、勾选公开、填写 ownerNotes；列表仅显示本人的猫；公开猫可被其他用户看到（若做「发现猫」列表）。 |
| **Feed** | 首页为帖子流；可筛品种、主题；可切最新/热门；滚动加载更多（limit+startAfter）；卡片显示点赞数、评论数。 |
| **点赞** | 详情页点赞/取消，post.likeCount 同步变化；列表刷新后数量一致。 |
| **评论** | 详情页评论列表分页；发表评论后 commentCount +1，新评论出现。 |
| **收藏** | 详情页收藏/取消；收藏列表页仅显示已收藏且 published 的帖子；分页。 |
| **7 天计划** | 首次进入可触发 7 天计划；标记某天完成，users.planProgress 更新。 |
| **提醒** | 为某猫设置驱虫/洗澡周期或疫苗日期；首页或提醒页显示今日待办。 |
| **UGC 发帖** | 提交后 status=pending；后台审核通过后 Feed 可见；AI 润色仅回填不发布。 |
| **后台** | 使用 ID Token + admin 可访问 breeds、官方 post、ugc 审核、reports 处理；`POST /ai/rewrite` 返回润色文本。 |

---

## 项目结构摘要

- **Flutter**：`lib/` — 路由、Repository、Feed/帖子/猫/收藏/计划/提醒页面；`lib/core/constants/app_constants.dart` 含集合名与 `backendBaseUrl`。
- **Firestore**：`firestore.rules`、`firestore.indexes.json`；种子数据 `scripts/seed_breeds.json`。
- **FastAPI**：`backend/app/` — `main.py`、`dependencies.py`（鉴权与 admin）、`routers/`（breeds、posts、ugc、reports、ai）。

