# Easy Shot

拍照姿势助手 App。帮助不会摆姿势的用户在拍照时获得清晰、可执行的姿势、构图、光线建议；并支持两台同系统鸿蒙手机互联做“伴侣屏”导拍。

- 平台：V1 HarmonyOS NEXT (ArkTS + ArkUI)，V2 扩展 Android (Kotlin + Compose)
- AI：端侧（姿态、手势、场景、规则引擎）+ 云端（风格化文案、复盘总结）
- 内容：原创 AI 虚拟模特图 + 局部标注 + 动作口令；不使用明星姓名/照片，不刻意做明星相似脸
- 互联：V1 Beta 支持两台鸿蒙手机局域网内分布式互联，主拍 / 伴侣屏角色

## 文档导航

- 设计：[`docs/specs/2026-04-28-pose-coach-app-design.md`](docs/specs/2026-04-28-pose-coach-app-design.md)
- M1（HarmonyOS 工程基础 + 模板系统）：[`docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md`](docs/plans/2026-04-28-easy-shot-harmony-m1-plan.md)
- M2（单屏实时引导 + 双机导拍 Beta）：[`docs/plans/2026-04-29-easy-shot-harmony-m2-dual-device-plan.md`](docs/plans/2026-04-29-easy-shot-harmony-m2-dual-device-plan.md)
- 开发指南（Windows）：[`docs/dev/windows-setup.md`](docs/dev/windows-setup.md)
- 开发指南（macOS）：见 M1 plan 顶部 “前置：macOS 鸿蒙开发环境配置” 章节

## 工程目录

```
app/
  harmony/    HarmonyOS NEXT DevEco 工程（V1 主体）
  android/    Android 工程（V2 占位）
core/         跨端共享算法层（V2 启用）
backend/      云端服务（M3+ 启用）
docs/         所有文档
```

## 当前状态

HarmonyOS NEXT V1 代码已落盘，覆盖 M1 + M2 所有核心函数。

### 模块概览

| 模块 | 文件数 | 说明 |
|------|--------|------|
| pages | 7 | Index（含筛选） / TemplateDetail / CameraGuide / PhotoReview / DevicePairing / CompanionSession / Settings |
| components | 1 | KeypointHeatmap |
| core/session | 4 | SessionState / SessionMessage（15 种消息） / SessionSerializer / SessionFallbackPolicy |
| core/style | 1 | StyleTags |
| core/locale | 1 | LocaleHelper |
| core/rules | 1 | LightingCompositionRules（逆光/曝光/构图规则引擎） |
| features/camera | 1 | CameraController（Camera Kit + 预览缩略图） |
| features/companion | 5 | DeviceDiscoveryService / CompanionSessionService / CompanionCommandHandler / DistributedTransport / PreviewSyncService |
| features/poseDetection | 4 | PoseDetector 接口 / MockPoseDetector / MindSporePoseDetector / KeypointMatcher |
| features/poseTemplate | 3 | 模型 / Repository / Store |
| features/realtimeGuide | 3 | GuideOverlayRenderer / GuidePromptSelector / PoseAlignmentService |
| features/settings | 2 | SettingsModel / SettingsStore |
| features/styleAdvice | 5 | 模型 / 接口 / Mock / Cloud / Service |
| entryability | 1 | EntryAbility |

### 资源

- i18n：168+ 条字符串（zh-CN + en-US）
- 颜色主题：25 色 × 2（light / dark）
- 姿势模板：5 套（standing / sitting / campus_wave / travel_lean_wall / selfie_heart_hands）
- 图标：3 个 PNG（app / camera / template）

### 测试

13 个测试套件，55+ 个用例：

| 测试套件 | 用例数 |
|----------|--------|
| CameraControllerTest | 4 |
| CompanionSessionServiceTest | 4 |
| RemoteShutterTest | 4 |
| DistributedTransportTest | 4 |
| DeviceDiscoveryServiceTest | 4 |
| PreviewSyncServiceTest | 4 |
| NavigationFlowTest | 3 |
| KeypointMatcherTest | 6 |
| PoseDetectionTest | 8 |
| PoseAlignmentServiceTest | 4 |
| PoseTemplateTest | 3 |
| SettingsTest | 3 |
| StyleAdviceTest | 4 |

### 权限

- `ohos.permission.CAMERA`
- `ohos.permission.DISTRIBUTED_DATASYNC`
- `ohos.permission.INTERNET`

### 统计

- 源文件：40 个 .ets（main）+ 14 个 .ets（test）
- 总文件：68+ 个（含 JSON / JSON5 资源配置）
- 代码行数：~9500+
