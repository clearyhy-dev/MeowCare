# 后台登录排查说明

## 为什么之前一直有问题

1. **第一次方案（前端 POST 登录）**：用链接打开页面时，由前端 JS 发 `POST /admin/login`。但浏览器可能缓存了「不带 token」的登录页 HTML，或脚本执行顺序导致 POST 根本没发出去，所以日志里只有 GET、没有 POST，登录不生效。
2. **第二次方案（服务端在 HTML 里注 token）**：GET 时服务端校验通过后直接返回带 `window.__INIT_ADMIN_TOKEN__` 的 HTML。服务端已返回 200 且 `X-Admin-Login: ok`，但浏览器可能仍用了**缓存的旧 HTML**（没有 token），所以页面还是登录框，没有 302、也没有后续的 GET /breeds。
3. **当前方案（302 + Cookie）**：带账号密码的 GET 不再直接返回 HTML，而是 **302 重定向到 /admin** 并设置 Cookie；浏览器第二次请求 GET /admin（带 Cookie）时，服务端从 Cookie 取 token 再注入 HTML。这样「带 token 的那份 HTML」来自第二次请求，不受第一次响应缓存影响。

**你没看到 302 的常见原因：**

- **部署的不是最新代码**：当前接流量的修订版本仍是旧逻辑（返回 200+HTML 而不是 302）。需要从 `backend/` 目录执行一次 **带源码的部署**，确保新镜像生效。
- **浏览器强缓存了旧响应**：之前同一条 URL 返回过 200，被缓存后，再点链接时浏览器可能直接读缓存、不向服务器发请求，所以看不到 302。需要**强刷（Ctrl+Shift+R）或无痕窗口**再试。

---

## 如何确认服务端已更新（能看到 302）

1. **必须从 backend 目录部署**（会重新构建镜像）：
   ```bash
   cd D:\googleplay\MeowCare\backend
   gcloud run deploy meowcare-api --source . --region asia-east1 --allow-unauthenticated --update-env-vars="ADMIN_USERNAME=admin,ADMIN_PASSWORD=wu2612103"
   ```
   等部署完成、新修订版本接流量后再测。

2. **避免用旧缓存**：用无痕窗口，或打开 DevTools → Network 勾选 **Disable cache**，再访问：
   ```text
   https://meowcare-api-394032854754.asia-east1.run.app/admin?username=admin&password=wu2612103
   ```

3. **在 Network 里看第一次请求**：
   - 若**状态码是 302**，且响应头里有 **X-Admin-Action: redirect**，说明新逻辑已生效；接着应出现第二次请求 **admin**（无 query），状态 200，头里 **X-Admin-Action: cookie-login**，然后应进入后台。
   - 若**状态码是 200**，且 **X-Admin-Action: form**（或无该头）：说明当前跑的仍是「直接返回登录页」的旧逻辑，或请求里没带 `username`/`password`，需要再确认部署和 URL。

---

## 响应头含义（便于排查）

| 响应头 | 含义 |
|--------|------|
| **X-Admin-Action: redirect** | 校验通过，已 302 并设置 Cookie，应紧跟第二次 GET /admin |
| **X-Admin-Action: cookie-login** | 从 Cookie 取出 token 并注入页面，本次返回的 HTML 会带 token |
| **X-Admin-Action: form** | 无参数或无效 Cookie，返回普通登录页 |
| **X-Admin-Login: ok** | URL 账号密码校验通过（会 302） |
| **X-Admin-Login: fail** | URL 带了账号密码但校验失败 |

