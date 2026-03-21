# MeowCare 应用图标规范

本文档描述应用图标的视觉方案与资源尺寸，便于设计导出或后续替换。

## 方案（方案 1）

- **概念**：极简猫头 + 中心爱心 + 橙色渐变  
- **调性**：温暖、关爱、现代、远距离可识别  
- **规范**：符合 Material 自适应图标（Android）与 iOS 要求

### 色值（与 app 主题一致）

| 用途       | 色值       | 说明           |
|------------|------------|----------------|
| 主色/渐变  | `#F4A261`  | Warm Orange    |
| 辅助/高光  | `#FFF8E7`  | Soft Cream     |
| 强调       | `#2A9D8F`  | Deep Teal（可选） |

渐变建议：主色到浅色（如 `#F4A261` → `#FFF0E0`）营造柔和感。

---

## Android

### 标准 launcher 图标（mipmap）

| 密度   | 目录            | 尺寸 (px) |
|--------|-----------------|-----------|
| mdpi   | `mipmap-mdpi`   | 48×48     |
| hdpi   | `mipmap-hdpi`   | 72×72     |
| xhdpi  | `mipmap-xhdpi`  | 96×96     |
| xxhdpi | `mipmap-xxhdpi` | 144×144   |
| xxxhdpi| `mipmap-xxxhdpi`| 192×192   |

资源路径：`android/app/src/main/res/<mipmap-*>/ic_launcher.png`

### 自适应图标（Android 8+）

- **前景图（foreground）**：仅猫头+爱心图形，透明背景；画布 108×108 dp，安全区居中 72×72 dp。  
- **背景**：单色或渐变（如 `#F4A261` 或上述渐变）；或 `res/drawable` 中背景图。  
- 资源路径示例：  
  - `res/mipmap-*/ic_launcher_foreground.png`  
  - `res/mipmap-*/ic_launcher_background.png`  
  或在 `res/drawable` 中定义 `ic_launcher_foreground.xml` / `ic_launcher_background.xml`。

---

## iOS

- **AppIcon.appiconset** 路径：`ios/Runner/Assets.xcassets/AppIcon.appiconset/`  
- 常用尺寸（px）：  
  - 20×20, 29×29, 40×40, 60×60  
  - 76×76, 83.5×83.5  
  - 1024×1024（App Store）

按 Xcode 中 AppIcon 槽位导出对应尺寸即可。

---

## 交付清单

- [ ] Android：各 mipmap 密度 `ic_launcher.png`；自适应图标前景/背景（若使用）。  
- [ ] iOS：`AppIcon.appiconset` 内各尺寸 PNG。  
- [ ] 设计源文件（可选）保留猫头+爱心线稿与色板，便于后续迭代。
