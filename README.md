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

- spec v2：HarmonyOS 优先 + 单屏拍摄 + 双机互联（伴侣屏）
- M1 plan：6 个 TDD 任务，覆盖 DevEco 工程脚手架到模板列表/详情
- M2 plan：单屏导拍 + 同系统双机导拍 Beta，含会话状态机与协议最小集
- Windows / macOS 环境配置文档已就绪
- 代码尚未开始落盘；下一步在 macOS 或 Windows 装好 DevEco 后按 M1 Task 1 创建工程
