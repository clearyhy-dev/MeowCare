# 封闭测试 / 正式上架：签名密钥说明

封闭测试和正式版必须用 **release 签名**，不能再用 debug 密钥。下面分两种方式说明如何「获取」和配置密钥。

---

## 一、两种方式概览

| 方式 | 谁持有密钥 | 适用 |
|------|------------|------|
| **自己生成并保管 keystore** | 你本地/CI | 未启用 Play 应用签名，或作为「上传密钥」 |
| **Play 应用签名（推荐）** | Google 保管应用签名密钥；你可选上传密钥 | 封闭测试 + 正式版，SHA-1 在 Console 看 |

封闭测试和正式版用的是**同一套 release 签名**（要么你自己的 keystore，要么 Play 应用签名 + 上传密钥）。

---

## 二、方式 A：自己生成 release keystore（获取秘钥 = 生成并保管）

### 1. 生成 keystore（仅做一次）

在本地执行（PowerShell 或 CMD），路径和密码按需修改：

```powershell
keytool -genkey -v -keystore D:\dev-config\android\meowcare-release.keystore -alias meowcare -keyalg RSA -keysize 2048 -validity 10000
```

按提示输入：
- **keystore 密码**、**密钥密码**（可设成相同）
- 姓名、组织等（可填应用名或公司名）

**重要**：  
- 把 `meowcare-release.keystore` 和密码**安全备份**（丢失无法再上传更新）。  
- **不要**把 `.keystore` 文件或密码提交到 Git。

### 2. 从该 keystore 获取 SHA-1（用于 Firebase）

```powershell
keytool -list -v -keystore D:\dev-config\android\meowcare-release.keystore -alias meowcare
```

输入 keystore 密码后，在输出里找到 **SHA1**，复制到 Firebase Console → 项目设置 → 您的应用 → Android 应用 → 添加指纹。

### 3. 让 Gradle 用这个 keystore 打 release 包

**不要**在仓库里写死密码。推荐用**环境变量**或 **local.properties**（且不要提交 `local.properties` 中的敏感行）。

在 `android/` 目录下创建 `key.properties`（项目已将该文件加入 `.gitignore`），例如：

```properties
storePassword=你的keystore密码
keyPassword=你的密钥密码
keyAlias=meowcare
storeFile=D:\\dev-config\\android\\meowcare-release.keystore
```

然后在 `android/app/build.gradle.kts` 中配置 release 使用该文件（见下一节示例）。

---

## 三、方式 B：Play 应用签名（封闭测试的秘钥在 Console 里“看”）

1. 在 [Google Play Console](https://play.google.com/console) 选择应用 → **设置** → **应用完整性**（或 **Setup → App signing**）。
2. 若启用 **Play 应用签名**：
   - **应用签名密钥**由 Google 托管，你在这里可以看到**证书指纹（SHA-1、SHA-256）**。
   - 封闭测试/正式版安装包都由该密钥签名，所以 **Firebase 里填的 SHA-1 要用这里显示的「应用签名密钥」的 SHA-1**。
3. **上传密钥**：
   - 你本机用**上传密钥**对 AAB 签名后上传。
   - 上传密钥可以是你自己生成的 keystore（按上面方式 A 生成），也可以让 Play 生成。
   - 若「获取封闭测试的秘钥」是指**要填到 Firebase 的 SHA-1**：用 **应用签名密钥** 的 SHA-1，在 Console 的「应用签名」页面复制即可。

---

## 四、在 build.gradle.kts 里使用自己的 release keystore

在 `android/app/build.gradle.kts` 中，用 `key.properties` 配置 release（该文件已在 `android/.gitignore` 中，不会提交）：

```kotlin
// 在 android { } 之前添加
import java.util.Properties

val keyPropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keyPropertiesFile.exists()) {
    keystoreProperties.load(keyPropertiesFile.inputStream())
}

android {
    // ...
    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

`key.properties` 放在 **android/key.properties**（与 `build.gradle.kts` 同级上一级目录）。

这样封闭测试和正式版都会用同一套 release 签名；**获取封闭测试的秘钥** = 要么用自建 keystore 的 SHA-1，要么用 Play Console 里「应用签名密钥」的 SHA-1。

---

## 五、小结

- **封闭测试**必须用 release 签名（不能是 debug）。
- **秘钥怎么“获取”**：  
  - 自建 keystore：自己用 `keytool` 生成，用 `keytool -list -v` 看 SHA-1。  
  - Play 应用签名：在 Play Console → 应用完整性 / App signing 里查看应用签名密钥的 SHA-1。
- 把 **release 用的 SHA-1** 填到 Firebase 的 Android 应用指纹里，Google 登录在封闭测试包中才能正常使用。

