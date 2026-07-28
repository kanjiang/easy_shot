# Task 8 实现计划：CameraGuide 数据收集与传递

## 📋 任务概述

**目标**：在 CameraGuide 拍照时收集诊断数据（光线、构图、姿势），并通过路由参数传递给 PhotoReview

**范围**：
- ✅ 光线数据提取
- ✅ 构图数据收集
- ✅ 姿势数据收集
- ✅ 诊断参数编码
- ✅ 路由参数传递

**约束条件**：
- 需要在拍照时刻有有效的诊断数据
- 数据编码必须与 PhotoReview 参数接口匹配
- 不能阻塞拍照流程

---

## 🔍 现状分析

### CameraGuide.ets 当前数据收集能力

**已有**：
- ✅ `frameAnalysisInput`: 帧分析输入
- ✅ `analyzeFrame()`: 帧分析方法
- ✅ 实时姿势检测（MindSpore）
- ✅ 模板关键点（poseTemplate）
- ✅ 检测到的关键点

**缺失**：
- ❌ 显式的光线数据采集点
- ❌ 构图数据的累积
- ❌ 诊断数据的缓存

### CameraGuideActions.ts 当前状态

**当前函数**：
```typescript
buildCameraGuideCaptureReviewParams(templateId: string, advice?: StyleAdvice)
// 返回包含 templateId, adviceHint 等参数
```

**需要修改**：
- 扩展参数接收方式
- 添加诊断数据编码逻辑

---

## 🛠️ 实现步骤

### 阶段 1：数据收集点识别

**目标**：找出在 CameraGuide 中最合适的数据收集点

**分析**：
1. **光线数据**：来自 `analyzeFrame()` 的结果
   - `avgBrightness`, `faceROIBrightness`, `backgroundBrightness`
   - 在帧分析回调中可获得

2. **构图数据**：来自人物检测
   - `personBBox`: {xmin, ymin, width, height}
   - `frameSize`: {width, height}
   - 在人物检测结果中

3. **姿势数据**：来自姿势检测
   - `templateKeypoints`: 从 poseTemplate 获得
   - `detectedKeypoints`: 从姿势检测结果获得
   - `score`: 关键点置信度

**收集时机**：
- 每一帧都收集这些数据
- 在拍照时使用最后一帧的数据

### 阶段 2：CameraGuide.ets 中添加数据缓存

**目标**：在 CameraGuide 组件中缓存最新的诊断数据

**修改文件**：`pages/CameraGuide.ets`

**新增状态**：
```typescript
// M3: 诊断数据缓存
@State private lastFrameStats: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number} | null = null;
@State private lastPersonBBox: {xmin: number, ymin: number, width: number, height: number} | null = null;
@State private lastDetectedKeypoints: Array<{name: string, x: number, y: number, score: number}> | null = null;
@State private lastFrameSize: {width: number, height: number} | null = null;
```

**修改帧分析回调**：
```typescript
// 在现有帧分析处理中添加

// 当接收到 frameAnalysisInput 的结果时
this.lastFrameStats = {
  avgBrightness: frameStats.avgBrightness,
  faceROIBrightness: frameStats.faceROIBrightness,
  backgroundBrightness: frameStats.backgroundBrightness,
};

// 当人物检测完成时
if (personBBox) {
  this.lastPersonBBox = personBBox;
  this.lastFrameSize = {width: previewWidth, height: previewHeight};
}

// 当姿势检测完成时
if (detectedKeypoints) {
  this.lastDetectedKeypoints = detectedKeypoints;
}
```

### 阶段 3：拍照时刻的数据编码

**目标**：在调用 `buildCameraGuideCaptureReviewParams()` 时，将缓存的数据编码进去

**修改文件**：`features/camera/CameraGuideActions.ts`

**扩展函数签名**：
```typescript
export function buildCameraGuideCaptureReviewParams(
  templateId: string,
  advice?: StyleAdvice,
  // M3: 新增诊断数据参数
  frameStats?: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number},
  personBBox?: {xmin: number, ymin: number, width: number, height: number},
  detectedKeypoints?: Array<{name: string, x: number, y: number, score: number}>
): Record<string, string> | null
```

**实现代码**：
```typescript
export function buildCameraGuideCaptureReviewParams(
  templateId: string,
  advice?: StyleAdvice,
  frameStats?: {avgBrightness: number, faceROIBrightness: number, backgroundBrightness?: number},
  personBBox?: {xmin: number, ymin: number, width: number, height: number},
  detectedKeypoints?: Array<{name: string, x: number, y: number, score: number}>
): Record<string, string> | null {
  // 现有逻辑...
  const params: Record<string, string> = {
    // ...现有参数...
    adviceHint: advice?.adviceHint ?? '',
  };

  // M3: 添加诊断参数编码
  if (frameStats) {
    params.reviewAvgBrightness = frameStats.avgBrightness.toString();
    params.reviewFaceROIBrightness = frameStats.faceROIBrightness.toString();
    if (frameStats.backgroundBrightness !== undefined) {
      params.reviewBackgroundBrightness = frameStats.backgroundBrightness.toString();
    }
  }

  if (personBBox) {
    params.reviewPersonBBoxJson = JSON.stringify(personBBox);
  }

  if (detectedKeypoints && detectedKeypoints.length > 0) {
    params.reviewDetectedKeypointsJson = JSON.stringify(detectedKeypoints);
  }

  return params;
}
```

### 阶段 4：CameraGuide 中调用时的修改

**目标**：在 CameraGuide.ets 中调用函数时传入诊断数据

**修改文件**：`pages/CameraGuide.ets`

**找到拍照逻辑**：
```typescript
// 当用户点击拍照按钮或触发远程拍照时
private async capturePhoto(): Promise<void> {
  // ... 现有拍照逻辑...

  // 构建路由参数（修改此部分）
  const reviewParams = buildCameraGuideCaptureReviewParams(
    this.templateState.templates[this.templateIndex]?.id ?? '',
    this.adviceFromCloud,
    // M3: 新增诊断数据参数
    this.lastFrameStats,
    this.lastPersonBBox,
    this.lastDetectedKeypoints
  );

  // ... 路由导航...
}
```

### 阶段 5：数据提取具体位置识别

**需要在 CameraGuide.ets 中找到**：

1. **帧分析结果处理**
   - 当前代码中的 `analyzeFrame()` 回调
   - 或 `handleFrameAnalysis()` 方法
   - 提取其中的亮度数据

2. **人物检测结果**
   - 通常在姿势检测后
   - 获取人物边界框坐标

3. **关键点检测结果**
   - 在 `lastAlignmentResult` 或类似的结构中
   - 包含检测到的关键点及其分数

4. **帧尺寸信息**
   - 通常在初始化摄像头时确定
   - 或从 XComponent 的尺寸获得

---

## 📊 数据映射表

### 光线数据来源
```
CameraGuide 帧分析
  └─ analyzeFrame() 输出
     ├─ avgBrightness → reviewAvgBrightness
     ├─ faceROIBrightness → reviewFaceROIBrightness
     └─ backgroundBrightness → reviewBackgroundBrightness
```

### 构图数据来源
```
CameraGuide 人物检测
  └─ 人物边界框检测结果
     ├─ xmin, ymin, width, height → reviewPersonBBoxJson
     └─ frameSize (width, height) → 在诊断时使用
```

### 姿势数据来源
```
CameraGuide 姿势检测
  └─ MindSpore 检测结果
     ├─ templateKeypoints → 从 poseTemplate 获得
     └─ detectedKeypoints → ReviewDetectedKeypointsJson
        ├─ name: "nose" | "left_shoulder" | ...
        ├─ x, y: 标准化坐标 (0-1)
        └─ score: 置信度 (0-1)
```

---

## 🔗 代码修改检查清单

### CameraGuide.ets
- [ ] 添加 4 个数据缓存状态
- [ ] 在帧分析回调中更新 `lastFrameStats`
- [ ] 在人物检测时更新 `lastPersonBBox` 和 `lastFrameSize`
- [ ] 在姿势检测时更新 `lastDetectedKeypoints`
- [ ] 在 `capturePhoto()` 中传入诊断数据参数

### CameraGuideActions.ts
- [ ] 扩展 `buildCameraGuideCaptureReviewParams()` 函数签名
- [ ] 添加诊断参数编码逻辑
- [ ] JSON 序列化数据
- [ ] 字符串转换处理

### 导入/导出
- [ ] 确保 CameraGuide 可以访问修改后的函数
- [ ] 检查类型定义是否完整

---

## 🎯 验收标准

### 数据完整性
- [ ] 每个诊断参数都正确编码
- [ ] JSON 序列化/反序列化无误
- [ ] 数值精度保持（小数点处理）

### 功能完整性
- [ ] 拍照时成功收集所有数据
- [ ] PhotoReview 能正确接收参数
- [ ] 本地诊断正常执行

### 兼容性
- [ ] 数据不完整时仍能工作（降级）
- [ ] 无诊断数据时仍能拍照和分享
- [ ] 不影响现有云端建议功能

### 性能
- [ ] 数据收集不阻塞帧分析
- [ ] JSON 序列化耗时 < 10ms
- [ ] 路由参数编码耗时 < 5ms

---

## ⚠️ 已知挑战

### 1. 数据同步问题
- 光线、构图、姿势数据来自不同的处理流
- 需要缓存最新的组合数据
- 可能存在时序不一致

**解决方案**：
- 使用最后一帧的数据
- 接受轻微的时间差异（< 100ms）

### 2. 可用性不确保
- 如果帧分析失败，可能没有光线数据
- 如果人物检测失败，可能没有构图数据
- 如果姿势检测失败，可能没有关键点数据

**解决方案**：
- 所有数据都是可选的
- PhotoReview 中已有处理缺失数据的逻辑
- 使用 fallback 诊断

### 3. 屏幕尺寸变化
- 如果设备旋转或折叠，帧尺寸可能改变
- 需要动态获取帧尺寸

**解决方案**：
- 在每一帧更新帧尺寸
- 在拍照时使用当前的帧尺寸

---

## 📈 实现顺序

### 优先级 1（必须）
1. 在 CameraGuide 中添加数据缓存状态
2. 修改 buildCameraGuideCaptureReviewParams() 函数
3. 在拍照时传入诊断参数

### 优先级 2（应该）
1. 在帧分析中更新光线数据缓存
2. 在人物检测中更新构图数据缓存
3. 在姿势检测中更新关键点数据缓存

### 优先级 3（可选）
1. 添加诊断数据验证逻辑
2. 添加日志记录（调试用）
3. 性能优化

---

## 📚 相关代码位置

**需要查看的文件**：
1. `pages/CameraGuide.ets` - 主要修改点
2. `features/camera/CameraGuideActions.ts` - 函数修改
3. `features/camera/PhotoMetadataService.ts` - 数据模型参考
4. `pages/PhotoReview.ets` - 参数接收端（已完成）

**需要理解的代码**：
1. 帧分析流程（如何获得 avgBrightness）
2. 人物检测流程（如何获得 personBBox）
3. 姿势检测流程（如何获得 detectedKeypoints）
4. 路由参数编码方式

---

## 🚀 下一步

### 实现步骤
1. ⏳ 查看 CameraGuide.ets 源代码（帧分析部分）
2. ⏳ 识别具体的数据提取点
3. ⏳ 添加数据缓存状态和更新逻辑
4. ⏳ 修改 CameraGuideActions 函数
5. ⏳ 修改拍照调用处的参数传递
6. ⏳ 集成测试验证

### 预计时间
- 代码分析：30 分钟
- 实现编码：60 分钟
- 测试调试：30 分钟
- **总计**：2 小时

---

**任务准备完毕**，等待开始实现！
