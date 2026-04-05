# MeowCare

家庭养猫护理与社区应用：**Flutter** 客户端 + **Firebase**（Auth / Firestore / Storage / Analytics）+ **FastAPI** 后台（管理、UGC 审核、AI、每日内容）+ **Cloud Functions**（通知与定时发帖辅助）。

---

## 功能概览

| 模块 | 说明 |
|------|------|
| **Feed** | 帖子流；最新 / 热门；品种与话题筛选；搜索 |
| **UGC** | 发帖、点赞、评论、收藏、举报；待审核 / 已发布 |
| **账号与社区** | 设置内：我的帖子、我的评论、收藏、通知；Feed 头像未读角标 |
| **通知** | Firestore `notifications`；评论 / 回复 / 点赞 / 审核结果；Callable 标记已读（`asia-east1`） |
| **猫与家庭** | 多猫档案、家庭与邀请码、任务与健康记录 |
| **计划与提醒** | 7 天新手计划、本地提醒 |
| **AI** | 症状引导（仅供参考）；发帖润色走后端 |
| **后台** | `/admin` 管理品种、UGC、举报、Reddit 导入、**每日内容生成**配置与手动触发 |

---

## 仓库结构

```
lib/                    # Flutter 源码（路由、Repository、页面、l10n）
android/ ios/ web/ …    # 各端工程
backend/app/            # FastAPI：main、routers、services
functions/              # Firebase Cloud Functions（TypeScript，编译输出在 lib/，勿提交）
firestore.rules         # Firestore 安全规则
firestore.indexes.json # 复合索引
docs/                   # 部署与排障说明
```

---

## 1. Firebase 与客户端

1. 在 [Firebase Console](https://console.firebase.google.com) 创建项目，启用 **Authentication（Google）**、**Firestore**、**Storage**。
2. 添加 Android / iOS 应用，放入 `google-services.json`、`GoogleService-Info.plist`。
3. 详细步骤：[docs/firebase_setup.md](docs/firebase_setup.md)。

### Flutter 运行

```bash
flutter pub get
flutter gen-l10n   # 若修改了 lib/l10n/*.arb
flutter run
```

指定后端（默认见 `lib/core/constants/app_constants.dart`）：

```bash
flutter run --dart-define=MEOWCARE_BACKEND_URL=https://你的-api.run.app
```

模拟器访问本机后端：`http://10.0.2.2:8000`（Android）或 `http://localhost:8000`（iOS）。

### 部署 Firebase（规则、索引、Functions）

```bash
# 首次在 functions/ 目录：npm install && npm run build
firebase deploy --only "firestore:rules,firestore:indexes,functions"
```

Cloud Functions **第 2 代** 每个导出函数在 Cloud Run 中会显示为**独立服务**，属正常现象。

---

## 2. FastAPI 后台

### 本地运行

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env   # 按说明填写
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 发布到 Cloud Run（后续均按此方式）

后端必须部署在 **与 Firebase 同一 GCP 项目**（`meowcare-d8391`）。若省略 `--project`，`gcloud` 可能把服务发到错误账号下的项目。

在仓库根目录执行：

```bash
cd backend
gcloud run deploy meowcare-api --source . --region asia-east1 --allow-unauthenticated --quiet --project meowcare-d8391
```

- 发布前需已安装 [Google Cloud SDK](https://cloud.google.com/sdk) 并 `gcloud auth login`，且账号对 `meowcare-d8391` 有部署权限。
- 更多场景（只改环境变量、Secret、强制重启等）见 [docs/cloud_run_deploy.md](docs/cloud_run_deploy.md)。

管理页：`https://meowcare-api-394032854754.asia-east1.run.app/admin`（与下方默认 API 同源）。

常见环境变量：

| 变量 | 说明 |
|------|------|
| `GOOGLE_APPLICATION_CREDENTIALS` | 服务账号 JSON 路径（本地） |
| `GEMINI_API_KEY` | AI 润色、每日多语言生成、后台「合成用户」批量评论短评（可选但推荐；日常≤10 字 / 专业≤30 字；无密钥则回退话术池） |
| `THE_CAT_API_KEY` | The Cat API（每日配图，可选） |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | 管理页登录；生产须强密码 |
| `SECRET_KEY` | JWT 签名；生产必填 |
| `ENV=production` | 生产校验上述必填项 |
| `CONTENT_JOB_SECRET` | `POST /content-jobs/daily-run` 等 Cron 鉴权（可选） |

客户端默认 API 基址：`lib/core/constants/app_constants.dart` 中 `MEOWCARE_BACKEND_URL` 默认值（`https://meowcare-api-394032854754.asia-east1.run.app`）。本地或换地址时用 `--dart-define=MEOWCARE_BACKEND_URL=...` 覆盖。

---

## 3. 每日官方内容

- **内容调性**（`voiceMode`）：`casual` = 日常随手动态风；`professional` = 专业科普专栏风。后台「每日内容」可选；生成帖会写入 `posts.voiceMode`。
- 配置写入 Firestore：`settings/content_generation`（后台「每日内容」页保存）。
- **手动生成**：后台按钮调用 `POST /content-jobs/generate-now`。
- **定时**：进程内 APScheduler（容器存活时）+ 可选 Cloud Scheduler 调 `POST /content-jobs/daily-run`（需 `CONTENT_JOB_SECRET`）。
- **生成结果**：默认写入 **`status: published`** 并带 **`publishedAt`**，生成后即可在 App **最新**（按 `createdAt`）中出现；若开启「必须配图」且无图，则写入 **`draft`**。客户端对 **`publishedAt` 晚于当前时间** 的帖会隐藏（见 `PostModel.isPubliclyVisibleInFeed`）。
- 历史上或其它途径写入的 **`scheduled`** 帖，仍由 `publish_due_scheduled_posts`（约每 5 分钟）+ 可选 Cloud Scheduler `POST /content-jobs/publish-scheduled` + API 中间件（节流）推进为 `published`。

---

## 4. 通知与规则要点

- 客户端**不可**直接创建/修改 `notifications` 文档；已读通过 **Callable**：`markNotificationRead`、`markAllNotificationsRead`。
- `users.notificationUnreadCount` 仅可信端（Functions / Admin SDK）递增；客户端规则限制篡改。
- Flutter 需使用 `FirebaseFunctions.instanceFor(region: 'asia-east1')` 与函数区域一致。

---

## 5. 验收与测试建议

| 能力 | 建议自测 |
|------|----------|
| Feed | 最新 / 热门、筛选、分页、详情跳转 |
| 社区入口 | 设置内四项 + 通知角标 |
| 通知 | 双账号评论 / 回复 / 点赞；审核通过/拒绝；已读与全部已读 |
| UGC | pending → 后台通过 → Feed 可见 |
| 每日内容 | 后台生成；列表含 `scheduled` / `draft`；到期变 `published` |

---

## 相关文档

- [docs/firebase_setup.md](docs/firebase_setup.md)
- [docs/cloud_run_deploy.md](docs/cloud_run_deploy.md)
- [docs/admin_login_debug.md](docs/admin_login_debug.md)

---

## 许可证与说明

内部 / 私有项目用途；对外分发请自行补充许可证与隐私政策。AI 与社区内容仅为信息参考，不能替代兽医诊疗。
