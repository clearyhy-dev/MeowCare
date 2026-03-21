# Google Play 上架检查清单（MeowCare）

代码与配置侧准备项，发布前逐项核对。

## 版本与构建

- [ ] **版本号**：在 `pubspec.yaml` 中设置 `version: 1.0.0+2`（或当前发布版本），保持 versionName / versionCode 与商店一致；发布前按需递增。
- [ ] **Android 签名**：在 `android/app/build.gradle.kts` 的 release 构建中配置 `signingConfig`，使用正式 keystore。**不要将 keystore 或密码提交到仓库**。封闭测试/正式版密钥获取与配置见 [docs/PLAY_SIGNING.md](PLAY_SIGNING.md)。


## 商店与合规

- [ ] **标题与描述**：使用 [docs/GOOGLE_PLAY_ASO.md](GOOGLE_PLAY_ASO.md) 中的标题、短描述与完整描述。
- [ ] **AI 免责**：应用内（如 AI 结果页）已保留「Informational guidance only. Not a substitute for veterinary care.」并已接入 l10n。
- [ ] **隐私政策**：准备隐私政策 URL，在 Play Console 与应用内（若需）填写。

## 多语言

- [ ] 应用内 l10n 已支持 en / ja / ko / de。
- [ ] Play Console 中为 en、ja、ko、de 分别填写商店描述与截图，与 l10n 语言一致，以提升覆盖与 ASO。

## 图标与资源

- [ ] 按 [docs/APP_ICON_SPEC.md](APP_ICON_SPEC.md) 替换 Android 与 iOS 应用图标后再提交商店。

完成以上项后即可提交审核。

