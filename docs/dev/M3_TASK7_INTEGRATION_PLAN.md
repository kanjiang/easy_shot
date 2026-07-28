# Task 7 实现计划：集成规则引擎到 PhotoReview.ets

## 📋 任务概述

**目标**：将本地规则引擎诊断功能集成到 PhotoReview 页面，实现本地建议与云端建议的混合展示

**范围**：
- ✅ 规则引擎集成（ReviewRulesEngine）
- ✅ 本地文案库集成（ReviewAdviceLibrary）
- ✅ 诊断数据流传递
- ✅ 混合建议 UI 展示

**预期收益**：
- 🚀 应用启动本地诊断，无需等待云端
- 🚀 降级方案：云端失败时自动显示本地建议
- 🚀 给用户快速反馈，优化体验

---

## 🔍 现状分析

### PhotoReview.ets 当前实现
```
aboutToAppear()
  └─ 加载云端 StyleAdvice (resolveStyleAdvice)
     └─ 显示 compositionAdvice + poseAdvice + suggestions
```

**缺失**：
- 本地诊断逻辑（光线、构图、姿势）
- 本地建议生成与显示
- 诊断数据的接收与处理

### CameraGuide.ets 数据收集现状
- ✅ 已有 PoseTemplate（模板关键点）
- ✅ 已有实时姿势检测（MindSpore）
- ✅ 已有帧分析接口 `analyzeFrame()`
- ❌ 尚未收集光线数据（faceROIBrightness）
- ❌ 尚未收集人物边界框（personBBox）
- ❌ 尚未将诊断数据传递给 PhotoReview

---

## 📊 数据流设计

### 拍照时的数据流
```
CameraGuide (拍照时收集)
  ├─ 光线数据: {avgBrightness, faceROIBrightness, backgroundBrightness}
  ├─ 构图数据: {personBBox, frameSize}
  ├─ 姿势数据: {templateKeypoints, detectedKeypoints}
  └─ 元数据: {templateId, timestamp, location}
        ↓
 buildCameraGuideCaptureReviewParams() (路由参数编码)
        ↓
 PhotoReview.ets (接收)
        ↓
 reviewDiagnosisData 参数解析
        ↓
 ReviewRulesEngine.synthesizeDiagnosis()
        ↓
 ReviewAdviceLibrary.generateAdvice()
        ↓
 本地建议显示
```

---

## 🛠️ 实现步骤

### 阶段 1：参数扩展 (PhotoReviewParams)

**目标**：为 PhotoReviewParams 接口添加诊断数据参数

**修改文件**：`pages/PhotoReview.ets`

**变更内容**：
```typescript
// 旧版
interface PhotoReviewParams {
  photoFilePath: string;
  templateTitle: string;
  // ...现有参数
}

// 新版
interface PhotoReviewParams {
  photoFilePath: string;
  templateTitle: string;
  // ...现有参数

  // 新增诊断数据参数
  reviewAvgBrightness?: string;           // 平均亮度
  reviewFaceROIBrightness?: string;       // 脸部 ROI 亮度
  reviewBackgroundBrightness?: string;    // 背景亮度
  reviewPersonBBoxJson?: string;          // 人物边界框 JSON: {xmin, ymin, width, height}
  reviewDetectedKeypointsJson?: string;   // 检测到的关键点 JSON: [{name, x, y, score}, ...]
}
```

**实现代码片段**：
```typescript
interface PhotoReviewParams {
  photoFilePath: string;
  templateTitle: string;
  templateId: string;
  styleTag: string;
  alignmentScore: string;
  matchedPoints: string;
  totalPoints: string;
  keypointDistances: string;
  tolerance: string;
  latitude: string;
  longitude: string;
  captureTimestamp: string;
  isVideo?: string;
  // 新增本地诊断相关参数
  reviewAvgBrightness?: string;
  reviewFaceROIBrightness?: string;
  reviewBackgroundBrightness?: string;
  reviewPersonBBoxJson?: string;
  reviewDetectedKeypointsJson?: string;
}
```

---

### 阶段 2：组件状态扩展

**目标**：为 PhotoReview 组件添加诊断和本地建议相关的状态

**修改文件**：`pages/PhotoReview.ets` (struct PhotoReview)

**新增状态**：
```typescript
// 本地诊断数据
@State private reviewDiagnosisData: ReviewDiagnosis | null = null;
@State private localAdvice: ReviewAdvice[] = [];
@State private localAdviceStatus: 'idle' | 'loading' | 'success' | 'error' = 'idle';

// 诊断原始数据
@State private reviewFrameStats: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number} | null = null;
@State private reviewPersonBBox: {xmin: number, ymin: number, width: number, height: number} | null = null;
@State private reviewDetectedKeypoints: Array<{name: string, x: number, y: number, score: number}> | null = null;
```

---

### 阶段 3：诊断初始化逻辑

**目标**：在 aboutToAppear() 中添加本地诊断逻辑

**修改文件**：`pages/PhotoReview.ets` (aboutToAppear 方法)

**新增代码**：
```typescript
aboutToAppear(): void {
  const params = router.getParams() as PhotoReviewParams | undefined;
  if (params) {
    // ...现有代码保持不变...

    // 新增：提取诊断数据参数
    if (params.reviewAvgBrightness && params.reviewFaceROIBrightness) {
      this.reviewFrameStats = {
        avgBrightness: Number.parseFloat(params.reviewAvgBrightness),
        faceROIBrightness: Number.parseFloat(params.reviewFaceROIBrightness),
        backgroundBrightness: params.reviewBackgroundBrightness
          ? Number.parseFloat(params.reviewBackgroundBrightness)
          : undefined,
      };
    }

    if (params.reviewPersonBBoxJson) {
      try {
        this.reviewPersonBBox = JSON.parse(params.reviewPersonBBoxJson);
      } catch (e) {
        // 无效 JSON，忽略
      }
    }

    if (params.reviewDetectedKeypointsJson) {
      try {
        this.reviewDetectedKeypoints = JSON.parse(params.reviewDetectedKeypointsJson);
      } catch (e) {
        // 无效 JSON，忽略
      }
    }
  }

  if (!this.isVideo) {
    // 并行执行：云端建议 + 本地诊断
    void this.loadAdvice();                    // 云端诊断
    void this.performLocalDiagnosis();         // 本地诊断（新增）
  }

  this.savePhotoPin();
}
```

---

### 阶段 4：本地诊断实现

**目标**：实现本地诊断方法

**修改文件**：`pages/PhotoReview.ets` (新增方法)

**新增方法代码**：
```typescript
private async performLocalDiagnosis(): Promise<void> {
  if (!this.reviewFrameStats || this.isVideo) {
    return;
  }

  this.localAdviceStatus = 'loading';

  try {
    // 1. 执行综合诊断
    const engine = new ReviewRulesEngine();
    const diagnosis = engine.synthesizeDiagnosis(
      this.reviewFrameStats,
      this.reviewPersonBBox || {xmin: 0, ymin: 0, width: 0, height: 0},
      {width: 1080, height: 2340},  // 标准屏幕尺寸，可从 display 获取
      this.templateState.templates[this.templateIndex]?.keypoints || [],
      this.reviewDetectedKeypoints || []
    );

    this.reviewDiagnosisData = diagnosis;

    // 2. 生成本地建议
    const advice = ReviewAdviceLibrary.generateAdvice(
      diagnosis,
      this.templateId,
      3  // 最多返回 3 条建议
    );

    this.localAdvice = advice;
    this.localAdviceStatus = 'success';

  } catch (error) {
    this.localAdviceStatus = 'error';
  }
}
```

---

### 阶段 5：UI 展示集成

**目标**：在 UI 中展示本地建议与云端建议

**修改文件**：`pages/PhotoReview.ets` (build 方法的建议区域)

**修改策略**：
- 如果有本地建议 → 优先显示本地建议
- 如果有云端建议 → 在本地建议后显示云端建议
- 如果都有 → 分开显示（本地在前，云端在后）

**新增 UI 代码**：
```typescript
// 在 build() 方法中的建议区域添加

// 新增：本地建议卡片
if (this.localAdviceStatus === 'loading') {
  Column({ space: 8 }) {
    Text($r('app.string.local_advice_title'))  // "本地快速诊断"
      .fontSize(18)
      .fontWeight(FontWeight.Medium)

    LoadingProgress()
      .width(32)
      .height(32)

    Text($r('app.string.local_advice_loading'))  // "正在分析..."
      .fontSize(14)
      .opacity(0.65)
  }
  .width('100%')
  .padding(16)
  .backgroundColor($r('app.color.easy_shot_background_secondary'))
  .borderRadius(8)
  .margin({bottom: 12})
}

if (this.localAdviceStatus === 'success' && this.localAdvice.length > 0) {
  Column({ space: 8 }) {
    Text($r('app.string.local_advice_title'))  // "本地快速诊断"
      .fontSize(18)
      .fontWeight(FontWeight.Medium)

    ForEach(this.localAdvice, (item: ReviewAdvice) => {
      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(item.title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)

          // 等级标签
          Text(item.level)
            .fontSize(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.getAdviceLevelColor(item.level))
            .borderRadius(4)
            .fontColor(Color.White)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Text(item.description)
          .fontSize(13)
          .opacity(0.78)

        if (item.actionableSteps.length > 0) {
          ForEach(item.actionableSteps, (step: string, index: number) => {
            Text(`${index + 1}. ${step}`)
              .fontSize(12)
              .opacity(0.65)
          })
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.easy_shot_card_background'))
      .borderRadius(8)
    })
  }
  .width('100%')
  .padding(16)
  .backgroundColor($r('app.color.easy_shot_background_secondary'))
  .borderRadius(8)
  .margin({bottom: 12})
}

if (this.localAdviceStatus === 'error') {
  Column({ space: 8 }) {
    Text($r('app.string.local_advice_failed'))  // "本地诊断失败"
      .fontSize(14)
      .fontColor($r('app.color.easy_shot_error'))
  }
  .width('100%')
  .padding(16)
  .backgroundColor($r('app.color.easy_shot_background_secondary'))
  .borderRadius(8)
  .margin({bottom: 12})
}

// 保持现有云端建议代码...
```

**辅助方法**：
```typescript
private getAdviceLevelColor(level: string): Resource | Color {
  switch (level) {
    case 'critical':
      return $r('app.color.easy_shot_error');
    case 'important':
      return $r('app.color.easy_shot_warning');
    case 'nice_to_have':
    default:
      return $r('app.color.easy_shot_secondary');
  }
}
```

---

### 阶段 6：导入语句

**目标**：添加必要的导入

**修改文件**：`pages/PhotoReview.ets` (文件顶部)

**新增导入**：
```typescript
import { ReviewRulesEngine, ReviewDiagnosis } from '../core/rules/LightingCompositionRules';
import { ReviewAdviceLibrary } from '../features/rules/data/ReviewAdviceLibrary';
import { ReviewAdvice } from '../features/review/model/ReviewAdvice';
```

---

## 🔗 依赖检查清单

| 依赖 | 文件 | 状态 | 备注 |
|------|------|------|------|
| ReviewRulesEngine | `core/rules/LightingCompositionRules.ets` | ✅ 存在 | 已在单元测试中验证 |
| ReviewAdviceLibrary | `features/rules/data/ReviewAdviceLibrary.ets` | ✅ 存在 | 已在单元测试中验证 |
| ReviewAdvice 接口 | `features/review/model/ReviewAdvice.ets` | ✅ 存在 | 用于类型定义 |
| ReviewDiagnosis 接口 | `core/rules/LightingCompositionRules.ets` | ✅ 存在 | 用于类型定义 |
| poseTemplateStore | `features/poseTemplate/state/PoseTemplateStore` | ✅ 存在 | 获取模板关键点 |

---

## 🎯 验收标准

### 功能验收
- [ ] PhotoReview 接收诊断数据参数无误
- [ ] 本地诊断在 aboutToAppear() 中执行成功
- [ ] 生成本地建议并存储在组件状态中
- [ ] UI 正确显示本地建议（包括等级、描述、步骤）
- [ ] 云端建议与本地建议并存展示

### 兼容性验收
- [ ] 无诊断参数时（现有工作流）仍能正常工作
- [ ] 视频模式下不执行诊断
- [ ] 参数解析异常时优雅降级

### 性能验收
- [ ] 本地诊断耗时 < 100ms
- [ ] 不阻塞 UI 线程
- [ ] 内存占用 < 5MB

### 测试验收
- [ ] 编译无错误
- [ ] 运行无崩溃
- [ ] 单元测试全部通过

---

## ⚠️ 已知约束

1. **屏幕尺寸硬编码**
   - 当前代码中 frameSize 使用 {width: 1080, height: 2340}
   - 后期应从 Display API 获取实际尺寸

2. **模板关键点获取**
   - 从 templateState.templates[templateIndex].keypoints 获取
   - 需确保在 aboutToAppear() 时 templateState 已加载

3. **诊断数据完整性**
   - 如果数据缺失，仍能运行但准确度降低
   - 使用 fallback 建议补偿

4. **并行执行**
   - 本地诊断与云端请求并行执行
   - 可能导致显示时序问题（待后续优化）

---

## 📅 预计时间

| 阶段 | 工作内容 | 预计时间 |
|------|---------|--------|
| 1 | 参数扩展 | 15 分钟 |
| 2 | 状态扩展 | 10 分钟 |
| 3 | 初始化逻辑 | 20 分钟 |
| 4 | 诊断实现 | 30 分钟 |
| 5 | UI 集成 | 40 分钟 |
| 6 | 导入+测试 | 20 分钟 |
| **总计** | **集成 PhotoReview** | **2.5 小时** |

---

## 🚀 后续工作（Week 1 Day 6）

### Task 8：CameraGuide 数据收集
- 提取并传递光线数据（faceROIBrightness）
- 提取并传递人物边界框（personBBox）
- 提取并传递检测关键点数据
- 更新 buildCameraGuideCaptureReviewParams() 以包含诊断参数

### Task 9：端到端测试
- 完整工作流测试（拍照 → 诊断 → 建议展示）
- 本地+云端混合建议验证
- 降级方案验证

---

## 📚 相关文档

- **规则引擎测试**：[M3_UNIT_TEST_GUIDE.md](./M3_UNIT_TEST_GUIDE.md)
- **单元测试验证**：[M3_UNIT_TEST_VERIFICATION.md](./M3_UNIT_TEST_VERIFICATION.md)
- **DevEco 执行**：[DEVECO_TEST_EXECUTION.md](./DEVECO_TEST_EXECUTION.md)
- **Week 1 完整计划**：[2026-07-28-m3-week1-implementation.md](../plans/2026-07-28-m3-week1-implementation.md)

---

**此规划文档完成时间**：2026-07-28
**状态**：✅ 就绪开始实现
