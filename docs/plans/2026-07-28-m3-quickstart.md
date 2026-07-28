# M3 快速开始指南 (2026-07-28)

## ✅ 已完成的工作

### 1. **数据模型** ✓
- 文件: `features/review/model/ReviewAdvice.ets`
- 内容:
  - `ReviewAdvice` - 单条建议接口
  - `ReviewContext` - 拍摄会话上下文
  - `ReviewDiagnosis` - 规则引擎诊断结果

### 2. **规则引擎扩展** ✓
- 文件: `core/rules/LightingCompositionRules.ets` (已扩展)
- 新增:
  - `ReviewDiagnosis` 接口
  - `ReviewRulesEngine` 类
  - 三个诊断方法: `diagnoseLighting()`, `diagnoseComposition()`, `diagnosePose()`
  - 综合诊断方法: `synthesizeDiagnosis()`

### 3. **建议文案库** ✓
- 文件: `features/rules/data/ReviewAdviceLibrary.ets`
- 内容:
  - 光线、构图、姿势的建议文案模板
  - `generateAdvice()` 方法 - 基于诊断生成 1-3 条优先级最高的建议
  - `getFallbackAdvice()` - 云端失败时的降级方案

### 4. **状态管理** ✓
- 文件: `features/review/state/ReviewStore.ets`
- 内容:
  - 单例模式管理当前复盘上下文
  - 支持保存用户反馈 (rating, feedback)

### 5. **数据访问层** ✓
- 文件: `features/review/data/PhotoReviewRepository.ets`
- 内容:
  - `IPhotoReviewRepository` 接口定义
  - `PhotoReviewRepository` 实现 (TODO: 完成存储逻辑)

---

## 🎯 下一步任务 (按优先级)

### Phase 1: 测试与验证 (1-2 天)

#### Task 1: 编写规则引擎单元测试
```
文件: test/ets/rules/LightingCompositionRulesTest.ets
内容:
  - 光线诊断测试 (逆光、低光、过曝、充足)
  - 构图诊断测试 (位置计算、1/3线判断)
  - 姿势对齐测试 (关键点距离计算、评分)
```

**预估**: 2-3 小时

#### Task 2: 编写文案库单元测试
```
文件: test/ets/rules/ReviewAdviceTest.ets
内容:
  - 建议生成测试 (各类型建议输出)
  - 优先级排序测试
  - Fallback 测试
```

**预估**: 2-3 小时

#### Task 3: 手动验证集成
```
步骤:
  1. 用 mock 数据在模拟器上运行 PhotoReview 页面
  2. 验证建议卡片的显示、展开/折叠、优先级排序
  3. 验证各建议类型的视觉效果 (颜色标签、图标)
```

**预估**: 1-2 小时

### Phase 2: 与现有 PhotoReview 集成 (2-3 天)

#### 背景
现有 `PhotoReview.ets` 已经完整实现了：
- ✅ 照片加载与显示
- ✅ StyleAdvice 云端调用
- ✅ 分享功能
- ✅ 地理位置和时间戳保存
- ✅ 通知和 Toast

**需要扩展的**:
- ⏳ 集成规则引擎诊断（添加到现有的 StyleAdvice 前/后）
- ⏳ 选择性使用本地建议 vs 云端建议

#### Task 4: 扩展 PhotoReview 集成规则引擎
```
修改文件: pages/PhotoReview.ets

步骤:
  1. 导入: ReviewRulesEngine, ReviewAdviceLibrary
  2. 在 aboutToAppear() 中调用诊断
  3. 若启用本地建议，使用 ReviewAdviceLibrary.generateAdvice()
  4. 若启用云端，继续调用现有的 resolveStyleAdvice()
  5. 修改 UI 同时展示规则引擎建议 + StyleAdvice（可选）

新增状态变量:
  @State adviceLocal: ReviewAdvice[] = [];  // 本地诊断建议
  @State adviceCloud: StyleAdvice | null = null; // 云端建议
```

**预估**: 4-5 小时

#### Task 5: 修改 CameraGuide 以支持诊断数据收集
```
修改文件: pages/CameraGuide.ets 或 features/camera/CameraGuideActions.ets

需要传递给 PhotoReview 的诊断数据:
  - faceROIBrightness (来自光线检测)
  - backgroundBrightness (来自光线检测)
  - personBBox (来自人体检测)
  - frameSize (相机分辨率)
  - 实时累积的关键点数据 (maxPoseScore 等)

修改现有的路由参数构造，添加诊断数据字段
```

**预估**: 3-4 小时

### Phase 3: 测试与调优 (2-3 天)

#### Task 6: UI 集成测试
```
文件: test/ets/review/PhotoReviewViewActionsTest.ets

测试场景:
  - 本地建议显示
  - 云端建议回退
  - 建议卡片展开/折叠
  - 底部按钮交互 (再拍、保存)
  - 网络超时降级
```

**预估**: 3-4 小时

#### Task 7: E2E 流程测试
```
步骤:
  1. 选择模板
  2. 进入相机指导
  3. 正常拍摄 (或 mock 生成诊断数据)
  4. 进入 PhotoReview
  5. 验证:
     - 建议正确显示
     - 优先级排序正确
     - UI 布局合理
     - 用户交互流畅
```

**预估**: 2-3 小时

---

## 🔧 关键集成点详解

### 1. 诊断数据流

```
CameraGuide (实时收集数据)
  ↓
  成功拍照后：序列化诊断数据
  ↓
PhotoReview 路由参数
  ↓
ReviewStore.setContext()
  ↓
ReviewRulesEngine.synthesizeDiagnosis()
  ↓
ReviewAdviceLibrary.generateAdvice()
  ↓
PhotoReview UI 展示建议
```

### 2. 建议优先级排序

```
优先级顺序 (降序):
  1. 光线问题 (priority 7-9)
  2. 姿势问题 (priority 5-9)
  3. 构图问题 (priority 5-6)

最终显示: 最多 3 条，按优先级从高到低
```

### 3. 云端 vs 本地

```
Settings 中的开关:
  ☑ 启用云端建议 → 调用 StyleAdviceService + 使用本地文案库作 fallback
  ☐ 仅本地建议   → 只使用 ReviewAdviceLibrary (零成本)

推荐策略:
  - 开发/测试: 仅本地 (快速反馈)
  - Beta: 本地 + 云端 (对比效果)
  - 生产: 由用户选择
```

---

## 📝 代码清单

### 已创建的文件

| 文件 | 类/接口 | 行数 | 状态 |
|------|--------|------|------|
| `features/review/model/ReviewAdvice.ets` | ReviewAdvice, ReviewContext, ReviewDiagnosis | 85 | ✅ |
| `core/rules/LightingCompositionRules.ets` | ReviewRulesEngine (扩展) | +180 | ✅ |
| `features/rules/data/ReviewAdviceLibrary.ets` | ReviewAdviceLibrary | 250 | ✅ |
| `features/review/state/ReviewStore.ets` | ReviewStore | 60 | ✅ |
| `features/review/data/PhotoReviewRepository.ets` | PhotoReviewRepository | 60 | ✅ |

### 需要扩展的文件

| 文件 | 修改点 | 优先级 | 预估工作量 |
|------|--------|--------|----------|
| `pages/PhotoReview.ets` | 集成规则引擎、本地建议显示 | P0 | 4-5 小时 |
| `pages/CameraGuide.ets` | 传递诊断数据给 PhotoReview | P0 | 3-4 小时 |
| `test/ets/rules/LightingCompositionRulesTest.ets` | 单元测试 | P0 | 2-3 小时 |
| `test/ets/rules/ReviewAdviceTest.ets` | 单元测试 | P0 | 2-3 小时 |
| `test/ets/review/PhotoReviewViewActionsTest.ets` | UI 集成测试 | P1 | 3-4 小时 |

---

## 🚀 立即开始

### 步骤 1: 编译验证
```bash
cd app/harmony
hvigorw assemble --mode module -p product=default
```

验证检查项:
- ✅ 所有新文件编译通过
- ✅ 无类型错误或缺少导入

### 步骤 2: 单元测试
```bash
# 在 DevEco 中运行测试
hvigorw test --module entry
```

验证检查项:
- ✅ ReviewAdviceLibrary 生成正确的建议
- ✅ ReviewRulesEngine 诊断逻辑正确

### 步骤 3: 手动测试
1. 打开模拟器
2. 在 PhotoReview.ets 中启用 mock 数据 (见代码中的 `loadMockData()`)
3. 验证 UI 显示正确

---

## 📊 进度跟踪

```
Week 1 完成度:
  ☑ 数据模型设计
  ☑ 规则引擎实现
  ☑ 文案库实现
  ☑ 状态管理
  ☑ 数据访问层
  ⏳ 单元测试编写
  ⏳ PhotoReview 集成
  ⏳ CameraGuide 集成
  ⏳ E2E 验证

预计 Week 1 末尾: 本地闭环可用，准备与现有系统集成
```

---

## ⚠️ 已知限制与 TODO

1. **持久化存储** - ReviewRepository 中的保存逻辑还需完成 (ArkData 集成)
2. **天空检测** - 构图诊断中的 skyOccupancy 当前是硬编码 (需实现轻量分类模型)
3. **关键点来源** - diagnosePose() 需从 CameraGuide 传入实时关键点数据
4. **i18n** - 当前所有文案为中文，后续需完成多语言支持
5. **后端集成** - Week 2 才开始云端 LLM 集成

---

## 📞 常见问题 & 调试

### Q: 诊断结果为空/不准确？
A: 检查 CameraGuide 是否正确传入了诊断数据。在 PhotoReview 中启用 hilog 查看日志。

### Q: 建议文案不符合预期？
A: 检查 ReviewAdviceLibrary.ets 中的阈值配置是否满足业务需求。当前阈值已在注释中详细说明。

### Q: 如何测试 fallback 降级？
A: 在 ReviewAdviceLibrary.ets 中调用 `getFallbackAdvice()` 方法进行测试。

---

**下一个检查点**: 编译验证 + 单元测试 (预计 2026-07-29)

祝编码愉快！🎉
