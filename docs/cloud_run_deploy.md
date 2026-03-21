# Cloud Run 重新部署说明

Cloud Run 没有“重启”概念，只有：重新部署代码、更新环境变量、强制创建新 revision、删除重建。按需选择下面一种方式。

---

## 一句话总结

| 需求         | 做法                         |
|--------------|------------------------------|
| 改了代码     | 重新 `deploy --source .`     |
| 只改环境变量/Secret | `services update --set-secrets` / `--update-env-vars` |
| 强制“重启”   | `services update --update-env-vars=RESTART=...` |
| 彻底重建     | 先 `delete` 再 `deploy`      |

---

## 情况 1：改了代码 → 重新部署（最常见）

改了 backend 代码后：

```bash
cd D:\googleplay\MeowCare\backend
gcloud run deploy meowcare-api --source . --region asia-east1 --allow-unauthenticated --quiet
```

会重新构建、创建新 revision、自动把流量切到新版本。旧 revision 保留，可回滚。

---

## 情况 2：只改了环境变量 / Secret

例如更新 GEMINI_API_KEY：

```bash
gcloud run services update meowcare-api --region asia-east1 --set-secrets="GEMINI_API_KEY=gemini-api-key:latest"
```

不会重新 build，只创建新 revision。

---

## 后台管理员密码（默认 admin / wu2612103）

当前默认密码为 **wu2612103**（无特殊字符，可直接用 `--update-env-vars`）。若密码含 `!` 等特殊字符，Windows 下会被解释，请用 Secret Manager 存密码。

### 方式 A：直接设环境变量（适合无特殊字符的密码）

```bash
gcloud run services update meowcare-api --region asia-east1 --update-env-vars="ADMIN_USERNAME=admin,ADMIN_PASSWORD=wu2612103"
```

### 方式 B：用 Secret Manager（推荐生产环境或含特殊字符时）

**步骤 1 — 创建 Secret**

- 在 [Secret Manager](https://console.cloud.google.com/security/secret-manager) 创建密钥 `admin-password`，密钥值填 `wu2612103`；或 PowerShell：
  ```powershell
  [System.IO.File]::WriteAllText("pass.txt", "wu2612103")
  gcloud secrets create admin-password --data-file=pass.txt
  Remove-Item pass.txt
  ```

**步骤 2 — 授权**（将 `PROJECT_NUMBER` 换成项目编号）

```bash
gcloud secrets add-iam-policy-binding admin-password --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"
```

**步骤 3 — 使用该 Secret**

```bash
gcloud run services update meowcare-api --region asia-east1 --set-secrets="ADMIN_PASSWORD=admin-password:latest"
```



---

## 情况 3：强制“重启”服务（不改代码）

Cloud Run 没有 `restart` 命令，可通过加一个无用环境变量强制出新 revision：

**Linux / macOS：**

```bash
gcloud run services update meowcare-api --region asia-east1 --update-env-vars=RESTART=$(date +%s)
```

**Windows CMD：**

```bash
gcloud run services update meowcare-api --region asia-east1 --update-env-vars=RESTART=%RANDOM%
```

会创建新 revision，容器会重新启动。

---

## 情况 4：彻底删除重建

完全重新来一遍：

```bash
gcloud run services delete meowcare-api --region asia-east1
```

然后重新部署：

```bash
cd D:\googleplay\MeowCare\backend
gcloud run deploy meowcare-api --source . --region asia-east1 --allow-unauthenticated --quiet
```

注意：会删除历史 revision。

---

## 查看当前状态

```bash
# 服务列表
gcloud run services list --region asia-east1

# revision 列表
gcloud run revisions list --region asia-east1

# 最近日志
gcloud logs read --limit=50
```

---

## 如何选择

| 目的       | 建议操作                         |
|------------|----------------------------------|
| 代码更新   | 情况 1：直接 `deploy --source .` |
| 解决 bug   | 先试情况 1；必要时情况 3 或 4     |
| 强制重启   | 情况 3                           |
| 彻底重建   | 情况 4                           |

当前服务正常时，若只改了 backend 代码，直接重新执行 **情况 1** 的 deploy 即可。

