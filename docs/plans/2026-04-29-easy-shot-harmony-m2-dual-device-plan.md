# Easy Shot HarmonyOS NEXT M2 Plan

> 目标：在 M1 模板系统基础上，交付单屏实时引导相机，以及同系统双机导拍 Beta。主拍机负责拍照与端侧 AI，辅助机负责导演视角预览、关键提示和远程控制。

## 1. 范围

M2 覆盖两条能力线：

- 单屏实时引导：Camera Kit 预览、姿势影子、局部提示框、一句实时提示、完成度
- 双机导拍 Beta：设备发现、配对、辅助机导拍界面、远程拍摄、倒计时、切模板、断连降级

不在 M2 范围：

- 多人协同导拍
- 跨系统互联（HarmonyOS 与 Android 混连）
- 辅助机查看完整相册或原图导出
- 拍照地图与 POI 推荐

## 2. 技术原则

- 主拍机单点持有相机与 AI 计算资源，避免双端重复推理
- 会话协议先定义为平台无关的数据结构，后续 Android 侧可复用
- 先保证控制链路稳定，再追求实时预览体验
- 预览同步必须有降级路径：实时流 → 低帧率缩略图 → 仅状态文本
- 所有双机能力都不能影响主拍机单机拍摄闭环

## 3. 建议工程落点

基于现有 `app/harmony` 工程，新增或扩展下列模块：

```text
app/harmony/entry/src/main/ets/
  pages/
    CameraGuide.ets
    CompanionSession.ets
    DevicePairing.ets
  features/
    camera/
      CameraController.ets
      PreviewFrameAdapter.ets
    realtimeGuide/
      GuideOverlayRenderer.ets
      GuidePromptSelector.ets
      PoseAlignmentService.ets
    companion/
      CompanionSessionService.ets
      CompanionCommandHandler.ets
      DeviceDiscoveryService.ets
      PreviewSyncService.ets
  core/
    session/
      SessionMessage.ets
      SessionState.ets
      SessionSerializer.ets
      SessionFallbackPolicy.ets
```

## 4. 里程碑拆分

### M2.1 相机与单屏实时引导 Spike

目标：验证 HarmonyOS NEXT 上相机预览、人体关键点检测、Overlay 渲染的性能边界。

任务：

- 接入 Camera Kit，打通主拍机预览与拍照
- 验证姿态检测 API 或候选替代方案的实时性
- 基于模板关键点绘制姿势影子与局部对齐框
- 输出一条最关键纠正提示与完成度

验收：

- 真机预览稳定
- 端侧推理与渲染链路达到可交互水平
- 明确性能瓶颈与后续优化点

### M2.2 双机会话层

目标：先打通信令，不急于完整预览。

任务：

- 设计会话消息结构：发现、握手、心跳、导拍状态、远程命令、异常事件
- 封装设备发现与配对 API
- 建立主拍机 / 辅助机角色状态机
- 支持辅助机发起拍摄、倒计时、切模板命令

验收：

- 两台同系统设备能稳定建立会话
- 远程命令能驱动主拍机行为
- 断连后主拍机可自动回到单机模式

### M2.3 导拍预览同步

目标：让辅助机获得足够有用的导演视角。

任务：

- 优先验证低延迟预览流方案
- 若链路不稳，补充低帧率缩略图方案
- 同步完成度、关键提示、构图框和连接质量
- 辅助机 UI 支持极简控制面板

验收：

- 辅助机能看到可用的实时或准实时画面
- 控制按钮和提示状态一致
- 连接波动时能自动降级且不丢失控制链路

### M2.4 测试与发布准备

目标：补齐基础测试、权限流程和体验守护。

任务：

- 为 `core/session` 和 `realtimeGuide` 增加单元测试
- 为设备发现、角色切换、断连回退补 UI/集成测试
- 梳理权限与隐私提示文案
- 输出机型兼容性矩阵和 Beta 开关策略

验收：

- 关键状态机和序列化逻辑有自动化测试覆盖
- 双机模式可灰度发布
- 风险点有明确 fallback

## 5. 协议最小集合

建议 M2 先定义以下消息类型：

- `session_invite`
- `session_accept`
- `session_reject`
- `guide_state_update`
- `remote_shutter`               // 携带 `delaySeconds`（0/3/5/10），辅助机按下立即下发
- `remote_shutter_cancel`        // 倒计时未结束前取消
- `remote_countdown`             // 主拍机回播倒计时，辅助机据此 tick
- `remote_switch_template`
- `remote_pause_preview`         // 辅助机请求暂停预览同步以省电
- `remote_resume_preview`
- `remote_ready_signal`          // 辅助机举手反馈“已就位”，主拍机浮提示
- `session_warning`
- `session_disconnect`

`guide_state_update` 最小字段：

- `templateId`
- `templateTitle`
- `guideScore`
- `primaryPrompt`
- `subjectBox`
- `compositionBox`
- `connectionQuality`
- `previewMode`，取值为 `live`、`thumbnail`、`state_only`

建议再补 4 个控制字段，避免 UI 状态不一致：

- `countdownStatus`，取值为 `idle`、`running`、`capturing`
- `countdownRemainingMs`，主拍机权威下发剩余毫秒，辅助机用作 UI 倒计时基线
- `sessionRole`，取值为 `host`、`companion`
- `templateRevision`，用于避免切模板时辅助机展示旧数据
- `hostMode`，取值为 `interactive`（朋友帮拍）、`tripod`（一人模式，主拍机自动进入支架视图）

## 6. 会话状态机

建议把双机会话状态固定为有限状态机，先避免页面层各自维护分散布尔值：

```text
idle
  → discovering
  → pairing
  → connected
  → guiding
  → countdown
  → capturing
  → review_sync
  → ended
```

状态说明：

- `idle`：未进入双机模式
- `discovering`：扫描同系统可连接设备
- `pairing`：等待用户确认配对与授权
- `connected`：控制链路建立，尚未进入正式导拍
- `guiding`：主拍机持续发送导拍状态，辅助机展示导演视图
- `countdown`：辅助机或主拍机发起倒计时
- `capturing`：主拍机拍摄中，辅助机进入只读等待态
- `review_sync`：拍后结果与复拍建议同步到辅助机
- `ended`：会话结束，可回到单机相机或重新配对

状态迁移约束：

- 任何状态收到断连事件都可跳转到 `ended`，主拍机同时回落到单机拍摄模式
- `remote_shutter` 只能在 `guiding` 或 `countdown` 状态触发；`delaySeconds == 0` 时跳过 `countdown` 直接进入 `capturing`
- `remote_shutter_cancel` 只能在 `countdown` 状态生效；执行后回退到 `guiding`，并广播 `countdownStatus = idle`
- `remote_switch_template` 只能在 `connected` 或 `guiding` 状态触发
- `remote_pause_preview` / `remote_resume_preview` 不改变状态机，只切换 `previewMode`
- `remote_ready_signal` 不改变状态机，只在主拍机 UI 浮一个 1.5s 的 `已就位` 提示
- `review_sync` 完成后默认回到 `guiding`，方便用户继续拍下一张

## 7. 页面流程

### 7.1 主拍机页面流转

```text
首页 / 模板详情
  → CameraGuide
  → 选择“双机导拍”
  → DevicePairing（主拍机模式）
  → CameraGuideHost
  → CaptureReview
  → CameraGuideHost 或结束会话
```

主拍机页面职责：

- `CameraGuide`：单机模式入口与模板预热
- `DevicePairing`：展示可连接设备、发起邀请、处理授权
- `CameraGuideHost`：真正持有 Camera Kit、AI、导拍状态发布与命令执行
  - 当 `hostMode = tripod` 时进入支架视图：隐藏底部多余按钮，只保留 `当前模板 / 完成度 / 倒计时 / 解除支架模式` 四项，避免误触
  - 接收 `remote_shutter` 时按 `delaySeconds` 启动倒计时；倒计时期间播放声音 + 屏幕短暂高亮，方便被拍者感知
- `CaptureReview`：显示照片、建议，并决定是否把复拍建议同步给辅助机

### 7.2 辅助机页面流转

```text
首页
  → DevicePairing（辅助机模式）
  → CompanionSession
  → CompanionReviewCard
  → CompanionSession 或结束会话
```

辅助机页面职责：

- `DevicePairing`：接收邀请、确认连接、展示主拍机名称与权限范围
- `CompanionSession`：导演视图，展示预览、关键提示、完成度、连接质量、远程控制
  - 底部固定 **快门按钮**（圆形大按钮，最低误触面积 64dp），长按弹出 0/3/5/10s 倒计时菜单，单击使用上次选择的延时
  - 倒计时显示为辅助机中央大数字 + 同步震动；倒计时未结束前显示 `取消` 按钮，按下发送 `remote_shutter_cancel`
  - 顶部右侧菜单：切前后摄（如远端允许）、暂停/恢复预览、切换横/竖屏布局
  - 辅助机角色为唯一可触发 `remote_ready_signal` 的入口（“已就位”按钮）
- `CompanionReviewCard`：只显示拍后缩略结果和复拍建议，不暴露完整原图浏览能力

### 7.3 页面级交互规则

- 辅助机横竖屏都要能用，但导演视图优先横屏布局
- 主拍机一旦进入 `capturing`，辅助机的切模板按钮、快门按钮立即置灰；倒计时按钮变为 `取消`
- 会话结束后，辅助机不能停留在旧的导演页，必须回到配对页或首页
- 任何需要用户确认的高风险操作只在主拍机弹框，例如切前后摄、退出会话、删除照片
- 一人模式由辅助机进入 `CompanionSession` 时显式选择，主拍机收到后切到支架视图；解除支架模式必须由主拍机本地操作完成，避免远端误触关闭

### 7.4 一人自拍模式 (Solo Mode)

一人模式不是新页面，而是 `CompanionSession` + `CameraGuideHost` 的一种联合状态：

- 进入条件：辅助机 → `CompanionSession` 顶部切换 `一人模式` 开关 → 下发 `hostMode = tripod`
- 主拍机响应：UI 切到支架视图，禁用本地拍照/切模板按钮（除非用户主动点 “解除支架模式”）
- 拍摄：辅助机快门按钮触发 `remote_shutter`，强制最小 3s 倒计时（让被拍者放下手机），过程中辅助机自动 mute 自身预览音效，避免与主拍机重复
- 结束：辅助机退回首页或主拍机解除支架，双方都能取消

## 8. 服务接口建议

为了避免页面和连接实现耦合，建议先定义 5 个核心接口：

- `DeviceDiscoveryService`：发现、筛选、邀请设备
- `CompanionSessionService`：管理状态机、消息收发、心跳与重连
- `PreviewSyncService`：负责预览流或缩略图同步与降级
- `CompanionCommandHandler`：把远程控制命令转换成主拍机本地动作
- `RemoteShutterController`：仅在主拍机存在，订阅 `remote_shutter` / `remote_shutter_cancel` / `remote_countdown` 事件，调用 `CameraController` 执行倒计时、拍摄、取消，并广播权威 `countdownRemainingMs` 给辅助机

页面层只订阅只读状态：

- `sessionState`
- `guideState`
- `previewState`
- `connectionQuality`

这样后续 Android 侧接入时，只需要替换服务实现，不需要重写页面状态逻辑。

## 9. 风险优先级

最高优先验证项：

1. 同系统设备发现与连接稳定性
2. 主拍机相机预览 + AI 推理 + Overlay 同时运行时的帧率
3. 辅助机预览同步延迟是否足够支撑远程导演体验

如第 3 项不达标，M2 Beta 直接退化为“辅助机看状态卡片 + 发远程指令”，不阻塞主拍机上线。

## 10. 交付顺序建议

1. 先完成单屏 CameraGuide 页面，确保一台手机闭环可用
2. 做双机会话信令，把远程切模板和远程快门（不带预览同步）打通
   - 重点验证：辅助机按快门 → 主拍机倒计时 → 拍摄 → 双端 UI 状态对齐
3. 启用一人模式（支架视图 + 强制最小倒计时 + 提示音/震动）
4. 叠加辅助机预览同步与体验优化（清晰度/帧率/降级策略）

这样即使预览同步延后，**辅助机快门 + 一人自拍** 也能在 Beta 内可用，不阻塞主拍机上线。
