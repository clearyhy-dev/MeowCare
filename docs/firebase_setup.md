# Firebase 配置说明（MeowCare）

## 一、当前已集成

- **Android**：`android/app/google-services.json` 已放入项目（Firebase 项目 `meowcare-d8391`，包名 `com.meowcare.meowcare`）。
- **Gradle**：根目录 `settings.gradle.kts` 已应用 `com.google.gms.google-services` 插件；`app/build.gradle.kts` 已启用该插件，构建时会自动读取 `google-services.json`。

无需再手动配置 Android 端 JSON，直接构建即可。

---

## 二、Firebase Console 必做配置

在 [Firebase Console](https://console.firebase.google.com) 选择项目 **meowcare-d8391**，完成以下项：

### 1. Authentication（身份认证）

1. 打开 **Build → Authentication**，如未启用则先“Get started”。
2. **Sign-in method** 中启用：
   - **Google**：用于“Sign in with Google”。
   - **Email/Password**：用于邮箱注册/登录。
3. 若使用 Google 登录，在 [Google Cloud Console](https://console.cloud.google.com) 同一项目中配置 OAuth 同意屏幕和凭据（Web 应用类型的客户端 ID 等），并按 Firebase 文档填写 SHA-1（可选，用于 Google Sign-In）。

### 2. Firestore Database（「同步资料失败」多半是这里没创建对）

**必须**在项目 **meowcare-d8391** 里创建。详细步骤见下方 **「Firestore 创建详细步骤」**。

---

### Firestore Database 创建详细步骤

**第 1 步：打开 Firebase 并选对项目**

1. 浏览器打开：<https://console.firebase.google.com>
2. 登录你的 Google 账号。
3. 在页面**左上角**看当前项目名称；若不是 **meowcare-d8391**，点击项目名，在列表里选择 **meowcare-d8391**（或你创建 MeowCare 时用的那个项目）。

**第 2 步：进入 Firestore 页面**

1. 在左侧边栏找到 **「构建」/ Build**，点击展开（若已展开可跳过）。
2. 点击 **「Firestore Database」/「Firestore 数据库」**。
3. 若你**从未创建过** Firestore，会看到中间大按钮 **「创建数据库」/「Create database」**；若有 **「开始集合」/「添加集合」** 等，说明已经创建过，只需检查规则（见第 5 步）。

**第 3 步：创建数据库（第一次时）**

1. 点击 **「创建数据库」/「Create database」**。
2. **选择安全规则**（第一步）：
   - 选择 **「在测试模式下启动」/「Start in test mode」**（先保证能读写，后面再改规则）。
   - 底部点击 **「下一步」/「Next」**。
3. **选择位置**（第二步）：
   - 在下拉列表选一个**离你或用户较近**的位置，例如：
     - **europe-west1** 或 **eur3**（欧洲）
     - **asia-southeast1**（东南亚）
     - **asia-northeast1**（东亚）
   - 选好后点击 **「启用」/「Enable」**。
4. 等待几十秒，直到页面显示 Firestore 的**数据 / 规则 / 索引**等标签，即表示创建完成。

**第 4 步：确认数据库已就绪**

- 若左侧或顶部出现 **「数据」/「规则」/「索引」** 等标签，且没有再次提示「创建数据库」，说明 Firestore 已创建好。
- 此时应用就可以连接并写入用户数据（在测试模式下）。

**第 5 步：若之前选的是「生产模式」或想改用正式规则**

1. 在 Firestore 页面顶部点 **「规则」/「Rules」** 标签。
2. 在规则编辑器中：
   - **方式 A（推荐，与项目一致）**：打开本仓库根目录的 **`firestore.rules`** 文件，复制全部内容，粘贴到编辑器中，覆盖原有内容。
   - **方式 B（仅开发用）**：粘贴下面这段，允许已登录用户读写所有文档：
     ```text
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} { allow read, write: if request.auth != null; }
       }
     }
     ```
3. 点击 **「发布」/「Publish」**，等待提示发布成功。

**第 6 步：在手机上重试登录**

- 打开 MeowCare 应用，再次点击 **「Sign in with Google」**。
- 若 Firestore 已创建且规则允许，登录后应能正常进入应用，不再报「同步资料失败」。

**若出现「The query requires an index」— 具体操作**

应用报错里会有一行可点击的链接（或需要你复制整段 URL）。任选下面一种方式即可。

**方式 A：用错误里的链接一键创建（推荐）**

1. 在手机或电脑上**长按 / 选中**错误信息里的整段 URL（从 `https://` 到末尾的 `EAI` 等字符）。
2. **复制**该链接，在电脑浏览器中**粘贴并打开**（或把链接发到电脑上再打开）。确保已登录与 MeowCare 相同的 Google 账号。
3. 打开后会进入 Firebase Console 的 Firestore **索引** 页面，且会**自动带出**要创建的复合索引（集合：`cats`，字段：`familyId`、`createdAt` 等）。
4. 在页面上点击 **「创建索引」/「Create index」**（或类似按钮），等待状态变为「已启用」（通常 1～5 分钟）。
5. 索引建好后，回到 MeowCare 应用，**重新进入首页**或下拉刷新，报错会消失。

**方式 B：在控制台里从文件导入索引**

1. 电脑打开 [Firebase Console](https://console.firebase.google.com)，选中项目 **meowcare-d8391**。
2. 左侧点 **构建 → Firestore Database**，再点顶部的 **「索引」/「Indexes」** 标签。
3. 在索引页面找到 **「从文件导入」/「Import from file」** 或 **「添加索引」** 旁的更多选项。
4. 选择本仓库根目录下的 **`firestore.indexes.json`** 文件（与 `firestore.rules` 同级），上传。
5. 确认列表中出现 `cats` 集合的复合索引（`familyId` 升序、`createdAt` 降序），点击 **部署** 或等待自动部署。状态变为「已启用」后，回到应用刷新即可。

**说明**：索引构建可能需要几分钟，期间应用若再次进入首页可能仍报错，等索引状态为「已启用」后再试。



---

### Firestore 已创建完毕 — 后续操作

当控制台显示「您的数据库已设置完毕，添加数据即可」时：

1. **不需要在控制台里点「启动集合」**  
   MeowCare 应用会在用户登录、创建家庭、添加猫咪等操作时**自动**创建 `users`、`families`、`cats`、`tasks` 等集合，无需在 Firebase 里手动建集合。

2. **确认规则已发布**  
   - 点顶部的 **「规则」/「Rules」** 标签。  
   - 若是测试模式创建，规则里应已有 `allow read, write` 相关配置；若为空或过严，请粘贴本项目的 `firestore.rules` 或上文测试规则后点击 **「发布」**。

3. **在手机上登录**  
   打开 MeowCare → **Sign in with Google**，登录成功后应用会写入用户文档，Firestore 的「数据」里会出现 `users` 等集合。

4. **可选：配置 App Check**  
   控制台若提示「配置 App Check」可先跳过，上线前再按需开启，用于防滥用。

---

**常见问题：**


- **找不到 Firestore Database 菜单**：确认当前选中的是 Firebase 项目（不是 Google Cloud Console），左侧是「构建 / Build」下的 Firestore Database。
- **创建时没有「测试模式」**：在第一步安全规则里选带 “test mode” 或「测试」字样的选项即可。
- **仍然报错**：确认项目是 **meowcare-d8391**（与 `google-services.json` 中 `project_id` 一致），且规则已点「发布」。



### 3. 安全与密钥（可选）

- 在 **Project settings → General** 可查看/管理 Android 应用与 `google-services.json`。
- API 密钥建议在 [Google Cloud Console](https://console.cloud.google.com) → API 和服务 → 凭据 中为 Android 应用设置“应用限制”（按包名 + SHA-1 限制），避免滥用。

---

## 三、iOS 配置（如需上架或调试 iOS）

1. 在 Firebase Console 中为同一项目 **添加 iOS 应用**，Bundle ID 与 Xcode 中一致（如 `com.meowcare.meowcare`）。
2. 下载 **GoogleService-Info.plist**，用 Xcode 打开 `ios/Runner.xcworkspace`，将 plist 拖入 `Runner` 目标并勾选 “Copy items if needed”。
3. 若使用 Google 登录，在 Xcode 的 Runner 目标 → Signing & Capabilities 中配置 URL Scheme（从 Firebase/GoogleService-Info.plist 中的 `CLIENT_ID` 生成）。

---

## 四、本地运行与打包

```bash
flutter pub get
flutter run
# 或 release 构建
flutter build apk --release
```

若 `google-services.json` 已放在 `android/app/` 且包名与 Firebase 中一致，无需再改 Gradle 即可正常连接 Firebase（Auth、Firestore 等）。

---

## 五、Google 登录不能使用：逐项排查

按下面顺序检查，**多数问题出在 1、2、4、5**。

| 步骤 | 位置 | 检查项 |
|------|------|--------|
| **1** | **Firebase Console** | **Build → Authentication → Sign-in method** 中 **Google** 必须为「已启用」。若未启用，点 Google → 启用 → 保存。 |
| **2** | **Firebase Console** | **项目设置（齿轮）→ 您的应用 → Android 应用** 中，**SHA 证书指纹** 必须包含你当前安装包所用密钥的 SHA-1。debug 安装用 debug 密钥的 SHA-1；release/封闭测试用 release 或 Play 应用签名密钥的 SHA-1。缺了会报 `10`、`12501` 等。 |
| **3** | **应用内** | 安装的 APK 包名必须是 `com.meowcare.meowcare`，且由已加入 Firebase 的 SHA-1 对应密钥签名。 |
| **4** | **google-services.json** | 使用「下载最新的配置文件」得到的、带 **oauth_client** 的 `google-services.json`，并已替换到 `android/app/google-services.json`（你已配置过）。若在 Firebase 里新加了 SHA-1 或重配了 Google 登录，需重新下载并替换。 |
| **5** | **Firestore** | 若报错是 **cloud_firestore/unavailable**，说明 Google 账号已登录成功，但**写入用户资料到 Firestore 时失败**。需在 **Build → Firestore Database** 创建数据库并发布规则；关 VPN、换网络后重试。详见下文「Google 登录报 cloud_firestore/unavailable」。 |
| **6** | **网络** | 设备需能访问 Google / Firebase。若在中国大陆且未翻墙，或 VPN 不稳定，可能无法完成 Google 登录或 Firestore 请求。 |

**常见错误码含义**（在应用里若看到类似信息可对照）：

- **10** / **12501**：通常为 SHA-1 未在 Firebase 中配置，或包名/签名与 Firebase 中不一致。
- **7**：网络或权限问题，或客户端未正确配置。
- **cloud_firestore/unavailable**：Firestore 未创建、规则未发布，或网络/VPN 导致无法访问 Firestore。

---

## 六、常见问题（其他）

- **包名不一致**：`android/app/build.gradle.kts` 中 `applicationId` 必须与 `google-services.json` 里 `client.client_info.android_client_info.package_name` 一致（当前均为 `com.meowcare.meowcare`）。
- **找不到 google-services.json**：确认文件路径为 `android/app/google-services.json`，且未在 `.gitignore` 中排除（若团队共用一个 Firebase 项目可提交；若每人自有项目，可忽略该文件并各自放置）。
- **Auth 报错**：检查 Console 中对应登录方式已启用，且 iOS/Android 的 OAuth 与 SHA-1 已按文档配置。

### Google 登录报「cloud_firestore/unavailable」
（属于上文「Google 登录不能使用」中的 Firestore 环节）


该提示表示 **Firestore 暂时不可用**，通常出现在登录后写入用户数据时。请按下面顺序排查：

1. **确认已创建 Firestore**  
   在 [Firebase Console](https://console.firebase.google.com) → 项目 **meowcare-d8391** → **Build → Firestore Database**。若未创建，点击「Create database」，选区域后先选「Start in test mode」再发布。创建后需在 **Rules** 中发布项目根目录的 `firestore.rules` 内容（正式环境再收紧规则）。

2. **网络与 VPN**  
   若设备开了 VPN 或处于受限网络，可能无法访问 Firestore。可关闭 VPN、换 Wi‑Fi 或移动网络后**重试登录**。

3. **重试**  
   应用已对 Firestore 的「unavailable」做自动重试（最多 3 次）。若仍报错，隔几秒再点一次「Sign in with Google」或邮箱登录。

4. **规则与区域**  
   确保 Firestore 规则已发布且允许已登录用户读写自己的 `users/{uid}` 文档（见 `firestore.rules`）。若 Firestore 所在区域与用户距离过远，偶发延迟也会触发 unavailable，多试几次即可。


