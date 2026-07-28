# M3 Implementation Plan - Week 1 & 2

## 🎯 目标

**Week 1-2**: 完成本地闭环（不依赖云端），用户拍照后获得 1-3 条可执行建议。

- ✅ 规则引擎实现 (光线/构图/姿势)
- ✅ PhotoReview 页面 UI
- ✅ 本地静态文案库与 fallback 机制

---

## 📁 文件结构与代码框架

### 新建文件

```
app/harmony/entry/src/main/ets/
  ├─ pages/
  │  └─ PhotoReview.ets              [NEW] 拍后复盘页面
  │
  ├─ features/
  │  ├─ review/
  │  │  ├─ data/
  │  │  │  └─ PhotoReviewRepository.ets  [NEW] 照片与建议数据源
  │  │  ├─ model/
  │  │  │  ├─ ReviewAdvice.ets          [NEW] 建议数据模型
  │  │  │  └─ ReviewContext.ets         [NEW] 复盘上下文
  │  │  └─ state/
  │  │     └─ ReviewStore.ets           [NEW] 复盘状态管理
  │  │
  │  ├─ rules/                        [ENHANCE]
  │  │  ├─ LightingCompositionRules.ets  [现有，需实现]
  │  │  └─ data/
  │  │     └─ ReviewAdviceLibrary.ets    [NEW] 本地静态文案库
  │  │
  │  └─ camera/
  │     └─ [MODIFY] 在拍照后路由到 PhotoReview
  │
  └─ test/ets/
     ├─ review/
     │  ├─ ReviewAdviceTest.ets       [NEW]
     │  └─ PhotoReviewViewActionsTest.ets [NEW]
     └─ rules/
        └─ LightingCompositionRulesTest.ets [NEW]
```

---

## 📋 Week 1 详细任务拆分

### Task 1.1: 数据模型定义 (0.5 天)

#### File: `features/review/model/ReviewAdvice.ets`

```typescript
/**
 * 单条复盘建议
 */
export interface ReviewAdvice {
  // 唯一标识
  id: string;

  // 建议类型: lighting | composition | pose | style_summary
  type: 'lighting' | 'composition' | 'pose' | 'style_summary';

  // 建议级别: critical | important | nice_to_have
  level: 'critical' | 'important' | 'nice_to_have';

  // 显示文案（1-2句，不超过40字）
  title: string;

  // 详细文案（可选，用于展开或 tooltip）
  description?: string;

  // 可执行步骤（例如"向窗边走一步"）
  actionableSteps?: string[];

  // 关键度评分 (0-1)
  confidence: number;

  // 优先级 (1-10)
  priority: number;

  // 关联的原始数据（用于调试或重放）
  metadata?: {
    faceAverageBrightness?: number;  // 脸部ROI平均亮度
    personPositionX?: number;         // 人体中心X (0-1)
    personPositionY?: number;         // 人体中心Y (0-1)
    estimatedBacklightRatio?: number; // 逆光估计 (0-1)
    poseAlignmentScore?: number;      // 姿势完成度 (0-1)
    keyPointDetails?: Record<string, number>; // 各部位得分
  };
}

/**
 * 拍摄会话的复盘上下文
 */
export interface ReviewContext {
  // 照片元数据
  photoPath: string;
  photoTimestamp: number;

  // 使用的模板
  templateId: string;
  templateTitle: string;

  // 拍摄过程数据（由 CameraGuide 收集）
  sessionData: {
    totalFramesProcessed: number;
    maxPoseScore: number;
    avgLighting: number;
    detectedScenes: string[];  // e.g., ["indoor", "backlit"]
    hasHandGesture: boolean;
  };

  // 最终建议列表
  advice: ReviewAdvice[];

  // 用户操作
  userRating?: number;  // 1-5 star rating
  userFeedback?: string;
}
```

#### File: `features/review/model/ReviewAdvice.ets` (continued)

```typescript
/**
 * 规则引擎生成的诊断结果
 */
export interface ReviewDiagnosis {
  // 光线诊断
  lighting: {
    type: 'adequate' | 'low' | 'overexposed' | 'backlit';
    averageBrightness: number;      // 0-255
    faceROIBrightness: number;      // 0-255
    confidence: number;
  };

  // 构图诊断
  composition: {
    personCenterX: number;          // 0-1
    personCenterY: number;          // 0-1
    isInRule3rdLine: boolean;       // 是否靠近1/3线
    skyOccupancy: number;           // 天空占比 0-1
    isUniformBackground: boolean;
  };

  // 姿势诊断
  pose: {
    overallScore: number;           // 0-1
    perPartScores: Record<string, number>;  // 脸、手、肩、腿等
    mostMisalignedPart: string;     // 最需要纠正的部位
    keyPointsPresence: number;      // 检测到的关键点比例
  };

  // 时间戳
  timestamp: number;
}
```

**关键约束**:
- 所有文案字段不超过 60 字（原型先用中文）
- `confidence` 用于排序和过滤低置信建议
- metadata 仅用于调试和后续云端优化，前端不展示

---

### Task 1.2: 规则引擎实现 (2 天)

#### File: `core/rules/LightingCompositionRules.ets`

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ReviewDiagnosis } from '../features/review/model/ReviewAdvice';

const TAG = 'LightingCompositionRules';

/**
 * 端侧规则引擎：基于相机帧、人体框、关键点，诊断光线、构图、姿势
 *
 * 输入:
 *   - 直方图或帧亮度统计
 *   - 人体检测框 (xmin, ymin, width, height, confidence)
 *   - 脸部ROI (可选，若有专门人脸检测)
 *   - 关键点 (x, y, score)
 *
 * 输出:
 *   - ReviewDiagnosis JSON
 */
export class LightingCompositionRules {

  private readonly config = {
    // 光线阈值
    MIN_FACE_BRIGHTNESS: 80,           // 脸部最低亮度
    MAX_FACE_BRIGHTNESS: 240,          // 脸部最高亮度
    BACKLIT_FACE_THRESHOLD: 70,        // 逆光判断：脸部＜70 且背景＞150
    BACKLIT_BACKGROUND_THRESHOLD: 150,

    // 构图阈值
    RULE_3RD_LINE_TOLERANCE: 0.15,     // 距离1/3线的容差
    RULE_3RD_LINES: [0.33, 0.67],      // 黄金分割线位置
    MIN_SKY_OCCUPANCY: 0.1,            // 至少保留10%天空
    MAX_SKY_OCCUPANCY: 0.5,            // 天空最多50%

    // 姿势阈值
    POSE_TOLERANCE_STRICT: 0.08,       // 严格模式
    POSE_TOLERANCE_LOOSE: 0.12,        // 宽松模式
    MIN_KEYPOINT_PRESENCE: 0.7,        // 至少70%关键点

    // 部位权重 (用于综合评分)
    partWeights: {
      'face': 0.4,
      'hands': 0.3,
      'shoulders': 0.2,
      'legs': 0.1,
    },
  };

  /**
   * 诊断光线情况
   *
   * @param frameStats - 帧统计 {avgBrightness, faceROIBrightness, backgroundBrightness}
   * @returns 光线诊断结果
   */
  diagnoseLighting(frameStats: {
    avgBrightness: number;
    faceROIBrightness: number;
    backgroundBrightness?: number;
  }): ReviewDiagnosis['lighting'] {
    const { faceROIBrightness, backgroundBrightness = 128 } = frameStats;

    // 逆光检测
    if (
      faceROIBrightness < this.config.BACKLIT_FACE_THRESHOLD &&
      backgroundBrightness > this.config.BACKLIT_BACKGROUND_THRESHOLD
    ) {
      return {
        type: 'backlit',
        averageBrightness: frameStats.avgBrightness,
        faceROIBrightness,
        confidence: 0.9,
      };
    }

    // 曝光不足
    if (faceROIBrightness < this.config.MIN_FACE_BRIGHTNESS) {
      return {
        type: 'low',
        averageBrightness: frameStats.avgBrightness,
        faceROIBrightness,
        confidence: 0.8,
      };
    }

    // 曝光过度
    if (faceROIBrightness > this.config.MAX_FACE_BRIGHTNESS) {
      return {
        type: 'overexposed',
        averageBrightness: frameStats.avgBrightness,
        faceROIBrightness,
        confidence: 0.8,
      };
    }

    // 光线充足
    return {
      type: 'adequate',
      averageBrightness: frameStats.avgBrightness,
      faceROIBrightness,
      confidence: 0.95,
    };
  }

  /**
   * 诊断构图
   *
   * @param personBBox - 人体框 {xmin, ymin, width, height}
   * @param frameSize - 画面尺寸 {width, height}
   * @returns 构图诊断
   */
  diagnoseComposition(
    personBBox: { xmin: number; ymin: number; width: number; height: number },
    frameSize: { width: number; height: number }
  ): ReviewDiagnosis['composition'] {
    // 计算人体中心相对坐标
    const centerX = (personBBox.xmin + personBBox.width / 2) / frameSize.width;
    const centerY = (personBBox.ymin + personBBox.height / 2) / frameSize.height;

    // 检查是否靠近1/3线
    const isInRule3rdLine = this.config.RULE_3RD_LINES.some(
      line => Math.abs(centerX - line) < this.config.RULE_3RD_LINE_TOLERANCE
    );

    // TODO: 实现天空检测（可用轻量分类模型或颜色分析）
    const skyOccupancy = 0.2;
    const isUniformBackground = false;

    return {
      personCenterX: centerX,
      personCenterY: centerY,
      isInRule3rdLine,
      skyOccupancy,
      isUniformBackground,
    };
  }

  /**
   * 诊断姿势对齐
   *
   * @param templateKeypoints - 模板关键点 (归一化)
   * @param detectedKeypoints - 检测到的关键点 (归一化)
   * @returns 姿势诊断
   */
  diagnosePose(
    templateKeypoints: Array<{ name: string; x: number; y: number }>,
    detectedKeypoints: Array<{ name: string; x: number; y: number; score: number }>,
    tolerance: number = this.config.POSE_TOLERANCE_STRICT
  ): ReviewDiagnosis['pose'] {
    // 按关键点名称建立映射
    const detectedMap = new Map(detectedKeypoints.map(kp => [kp.name, kp]));

    const perPartScores: Record<string, number> = {};
    let totalScore = 0;
    let validKeypoints = 0;

    for (const template of templateKeypoints) {
      const detected = detectedMap.get(template.name);
      if (!detected || detected.score < 0.5) {
        perPartScores[template.name] = 0;
        continue;
      }

      // 欧氏距离
      const dx = template.x - detected.x;
      const dy = template.y - detected.y;
      const distance = Math.sqrt(dx * dx + dy * dy);

      // 转换为0-1评分
      const score = Math.max(0, 1 - distance / tolerance);
      perPartScores[template.name] = score;

      totalScore += score;
      validKeypoints++;
    }

    const keypointPresence = validKeypoints / templateKeypoints.length;
    const overallScore = validKeypoints > 0 ? totalScore / validKeypoints : 0;

    // 找出最需要纠正的部位
    const mostMisalignedPart = Object.entries(perPartScores)
      .sort(([, a], [, b]) => a - b)[0]?.[0] || 'unknown';

    return {
      overallScore: Math.min(1, overallScore * keypointPresence),
      perPartScores,
      mostMisalignedPart,
      keyPointsPresence: keypointPresence,
    };
  }

  /**
   * 综合诊断：合并光线、构图、姿势
   */
  synthesizeDiagnosis(
    frameStats: any,
    personBBox: any,
    frameSize: any,
    templateKeypoints: any,
    detectedKeypoints: any
  ): ReviewDiagnosis {
    return {
      lighting: this.diagnoseLighting(frameStats),
      composition: this.diagnoseComposition(personBBox, frameSize),
      pose: this.diagnosePose(templateKeypoints, detectedKeypoints),
      timestamp: Date.now(),
    };
  }
}

export default new LightingCompositionRules();
```

**关键点**:
- 参数化所有阈值（便于后续 A/B 测试调整）
- 每个诊断方法单独可测试
- 输出结构化数据，便于生成文案

---

### Task 1.3: 建议文案库 (0.5 天)

#### File: `features/rules/data/ReviewAdviceLibrary.ets`

```typescript
import { ReviewAdvice } from '../../review/model/ReviewAdvice';
import { ReviewDiagnosis } from '../../../core/rules/LightingCompositionRules';

/**
 * 本地静态文案库：用规则引擎诊断结果生成建议文案
 */
export class ReviewAdviceLibrary {
  private static readonly ADVICE_TEMPLATES = {
    // ===== 光线建议 =====
    lighting: {
      backlit: [
        {
          title: '正在逆光，建议改变角度',
          description: '背景太亮，脸部偏暗。可试试转身让光线从侧面打过来',
          priority: 9,
        },
        {
          title: '逆光下可加前置补光',
          description: '使用手机补光灯或白纸反光会更好看',
          priority: 7,
        },
      ],
      low: [
        {
          title: '光线不足，脸部有点暗',
          description: '建议靠近窗户或打开室内灯',
          priority: 8,
        },
        {
          title: '走向亮处会更出镜',
          description: '移动到窗边或光线充足的地方重拍',
          priority: 8,
        },
      ],
      overexposed: [
        {
          title: '曝光过度，脸部太亮',
          description: '建议远离直接光源或降低屏幕亮度',
          priority: 7,
        },
      ],
      adequate: [
        // 光线充足时可不显示光线建议，或给鼓励
        {
          title: '光线很棒！',
          description: '',
          priority: 2,
        },
      ],
    },

    // ===== 构图建议 =====
    composition: {
      notInRule3rdLine: [
        {
          title: '人物可往画面右 1/3 移动',
          description: '黄金分割构图会让照片更耐看',
          priority: 6,
        },
        {
          title: '调整位置让人物靠近 1/3 线',
          description: '这样的构图更符合审美规律',
          priority: 6,
        },
      ],
      tooMuchSky: [
        {
          title: '天空占比偏大，可调低相机角度',
          description: '让人物和背景比例更均衡',
          priority: 5,
        },
      ],
      tooMuchBackground: [
        {
          title: '背景干扰较多，建议靠近主体',
          description: '或者找个更简洁的背景',
          priority: 5,
        },
      ],
    },

    // ===== 姿势建议 =====
    pose: {
      hand_misaligned: [
        {
          title: '手部位置可调整得更贴近',
          description: '按示范图对齐手的位置',
          priority: 9,
        },
      ],
      face_misaligned: [
        {
          title: '脸的角度还差一点',
          description: '试试下巴微收或抬起',
          priority: 9,
        },
      ],
      shoulder_misaligned: [
        {
          title: '肩膀位置可以更放松',
          description: '肩膀下沉会显得更自然',
          priority: 7,
        },
      ],
      leg_misaligned: [
        {
          title: '腿部站姿还可以优化',
          description: '重心向前移会显得更有气场',
          priority: 5,
        },
      ],
    },
  };

  /**
   * 基于诊断结果，生成 1-3 条优先级最高的建议
   *
   * @param diagnosis - 规则引擎诊断结果
   * @param templateId - 当前使用的模板
   * @param maxAdviceCount - 最多返回几条建议（默认3）
   * @returns 排序后的建议列表
   */
  static generateAdvice(
    diagnosis: ReviewDiagnosis,
    templateId: string,
    maxAdviceCount: number = 3
  ): ReviewAdvice[] {
    const candidates: ReviewAdvice[] = [];

    // 1. 光线建议（优先级最高）
    const lightingAdvice = this.generateLightingAdvice(diagnosis.lighting);
    if (lightingAdvice) candidates.push(lightingAdvice);

    // 2. 构图建议
    const compositionAdvice = this.generateCompositionAdvice(diagnosis.composition);
    if (compositionAdvice) candidates.push(compositionAdvice);

    // 3. 姿势建议
    const poseAdvice = this.generatePoseAdvice(diagnosis.pose);
    if (poseAdvice) candidates.push(poseAdvice);

    // 按优先级排序并截取前 N 条
    return candidates
      .sort((a, b) => b.priority - a.priority)
      .slice(0, maxAdviceCount)
      .map((advice, idx) => ({
        ...advice,
        id: `advice_${idx}`,
        metadata: {
          ...advice.metadata,
          faceAverageBrightness: diagnosis.lighting.faceROIBrightness,
          personPositionX: diagnosis.composition.personCenterX,
          personPositionY: diagnosis.composition.personCenterY,
          poseAlignmentScore: diagnosis.pose.overallScore,
          keyPointDetails: diagnosis.pose.perPartScores,
        },
      }));
  }

  private static generateLightingAdvice(lighting: ReviewDiagnosis['lighting']): ReviewAdvice | null {
    if (lighting.type === 'adequate') return null;

    const template = this.ADVICE_TEMPLATES.lighting[lighting.type]?.[0];
    if (!template) return null;

    return {
      id: '',
      type: 'lighting',
      level: lighting.type === 'backlit' ? 'critical' : 'important',
      title: template.title,
      description: template.description,
      confidence: lighting.confidence,
      priority: template.priority,
    };
  }

  private static generateCompositionAdvice(composition: ReviewDiagnosis['composition']): ReviewAdvice | null {
    if (composition.isInRule3rdLine) return null;

    const template = this.ADVICE_TEMPLATES.composition.notInRule3rdLine?.[0];
    if (!template) return null;

    return {
      id: '',
      type: 'composition',
      level: 'important',
      title: template.title,
      description: template.description,
      confidence: 0.7,
      priority: template.priority,
    };
  }

  private static generatePoseAdvice(pose: ReviewDiagnosis['pose']): ReviewAdvice | null {
    if (pose.overallScore > 0.8) return null;

    const misalignedPart = pose.mostMisalignedPart;
    const adviceKey = `${misalignedPart}_misaligned`;

    const template = (this.ADVICE_TEMPLATES.pose as any)[adviceKey]?.[0];
    if (!template) return null;

    return {
      id: '',
      type: 'pose',
      level: 'critical',
      title: template.title,
      description: template.description,
      confidence: pose.overallScore,
      priority: template.priority,
    };
  }
}
```

**关键点**:
- 所有文案为中文原型（后续可做多语言）
- 每条建议包含 title + description（可选），便于两层展示
- priority 用于排序（光线 > 姿势 > 构图）

---

### Task 1.4: PhotoReview 页面 UI (1.5 天)

#### File: `pages/PhotoReview.ets`

```typescript
import { router } from '@kit.ArkUI';
import hilog from '@ohos.hilog';
import { ReviewStore } from '../features/review/state/ReviewStore';
import { ReviewContext, ReviewAdvice } from '../features/review/model/ReviewAdvice';

const TAG = 'PhotoReview';

@Entry
@Component
struct PhotoReviewPage {
  @State reviewContext: ReviewContext | null = null;
  @State isLoading: boolean = false;
  @State showDetailAt: number = -1;  // 展开详情的建议索引

  private reviewStore: ReviewStore = new ReviewStore();

  aboutToAppear() {
    // 从路由参数获取 reviewContext (由 CameraGuide 传入)
    const params = router.getParams() as any;
    if (params?.reviewContext) {
      this.reviewContext = params.reviewContext;
    } else {
      this.loadMockData();  // 开发用
    }
  }

  private loadMockData() {
    this.reviewContext = {
      photoPath: '/data/mock/photo.jpg',
      photoTimestamp: Date.now(),
      templateId: 'pose_sweet_scissors_cheek_v1',
      templateTitle: '剪刀手脸颊边',
      sessionData: {
        totalFramesProcessed: 300,
        maxPoseScore: 0.75,
        avgLighting: 120,
        detectedScenes: ['indoor'],
        hasHandGesture: true,
      },
      advice: [
        {
          id: 'advice_0',
          type: 'lighting',
          level: 'important',
          title: '光线不足，脸部有点暗',
          description: '建议靠近窗户或打开室内灯',
          confidence: 0.8,
          priority: 8,
        },
        {
          id: 'advice_1',
          type: 'pose',
          level: 'critical',
          title: '手部位置可调整得更贴近',
          description: '按示范图对齐手的位置',
          confidence: 0.75,
          priority: 9,
        },
      ],
    };
  }

  build() {
    Column({ space: 0 }) {
      // ===== Header =====
      Row() {
        Text('拍摄完成').fontSize(18).fontWeight(FontWeight.Bold);
        Spacer();
        Image($r('app.media.icon_close'))
          .width(24)
          .height(24)
          .onClick(() => router.back());
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.bg_primary'))

      // ===== 照片预览 =====
      if (this.reviewContext) {
        Image(this.reviewContext.photoPath)
          .width('100%')
          .height(300)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.bg_secondary'))
      }

      // ===== 模板信息 =====
      if (this.reviewContext) {
        Row() {
          Column({ space: 4 }) {
            Text('当前姿势').fontSize(12).fontColor($r('app.color.text_secondary'));
            Text(this.reviewContext.templateTitle).fontSize(14).fontWeight(FontWeight.SemiBold);
          }
          Spacer();
          Text(`${Math.round(this.reviewContext.sessionData.maxPoseScore * 100)}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.accent_primary'));
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.bg_secondary'))
      }

      // ===== 建议卡片列表 =====
      if (this.reviewContext && this.reviewContext.advice.length > 0) {
        List({ space: 8 }) {
          ForEach(this.reviewContext.advice, (advice: ReviewAdvice, idx: number) => {
            ListItem() {
              this.adviceCard(advice, idx);
            };
          });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Off)
      } else {
        Text('完美！保持这个状态继续拍摄').fontSize(14).textAlign(TextAlign.Center).margin(32);
      }

      // ===== 底部按钮 =====
      Row({ space: 12 }) {
        Button('再拍一张').width('48%').height(44).onClick(() => {
          router.back();
        });
        Button('保存').width('48%').height(44).onClick(() => {
          this.savePhoto();
        });
      }
      .width('100%')
      .padding(16)
      .margin({ top: 'auto' })

      Spacer().layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_primary'));
  }

  @Builder
  adviceCard(advice: ReviewAdvice, idx: number) {
    Column() {
      // 卡片头
      Row({ space: 8 }) {
        // 类型标签
        this.adviceTypeBadge(advice.type);

        // 标题
        Text(advice.title)
          .fontSize(14)
          .fontWeight(FontWeight.SemiBold)
          .layoutWeight(1);

        // 展开按钮
        if (advice.description) {
          Image(this.showDetailAt === idx ? $r('app.media.icon_collapse') : $r('app.media.icon_expand'))
            .width(20)
            .height(20)
            .onClick(() => {
              this.showDetailAt = this.showDetailAt === idx ? -1 : idx;
            });
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12 });

      // 详情（可选展开）
      if (advice.description && this.showDetailAt === idx) {
        Text(advice.description)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(1.6)
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 });
      }

      // 底部操作
      if (this.showDetailAt === idx && advice.actionableSteps && advice.actionableSteps.length > 0) {
        Button('按建议再拍一张')
          .width('100%')
          .height(36)
          .margin({ left: 12, right: 12, top: 12, bottom: 12 })
          .onClick(() => {
            // 回到 CameraGuide，带上建议信息
            router.back();
          });
      } else {
        Divider().margin(12);
      }
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor($r('app.color.card_bg'))
    .clip(true);
  }

  @Builder
  adviceTypeBadge(type: string) {
    Text(this.adviceTypeLabel(type))
      .fontSize(11)
      .fontColor($r('app.color.text_on_accent'))
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .borderRadius(4)
      .backgroundColor(this.adviceTypeColor(type));
  }

  private adviceTypeLabel(type: string): string {
    const labels: Record<string, string> = {
      'lighting': '光线',
      'composition': '构图',
      'pose': '姿势',
      'style_summary': '风格',
    };
    return labels[type] || type;
  }

  private adviceTypeColor(type: string): ResourceColor {
    switch (type) {
      case 'lighting': return $r('app.color.accent_warning');
      case 'composition': return $r('app.color.accent_info');
      case 'pose': return $r('app.color.accent_primary');
      case 'style_summary': return $r('app.color.accent_success');
      default: return $r('app.color.accent_primary');
    }
  }

  private savePhoto() {
    hilog.info(0x0000, TAG, `Photo saved: ${this.reviewContext?.photoPath}`);
    // TODO: 调用 PhotoHistoryService 保存照片
    // TODO: 跳转回首页或其他目标
  }
}
```

**关键点**:
- 照片预览（使用传入的路径）
- 建议卡片列表（可展开/折叠详情）
- "再拍一张" / "保存" 底部按钮
- 类型标签和优先级视觉区分

---

### Task 1.5: 状态管理与数据源 (1 天)

#### File: `features/review/state/ReviewStore.ets`

```typescript
import { ReviewContext, ReviewAdvice } from '../model/ReviewAdvice';

/**
 * 简单的单例 store，管理当前复盘上下文
 */
export class ReviewStore {
  private static instance: ReviewStore;

  private currentContext: ReviewContext | null = null;

  private constructor() {}

  static getInstance(): ReviewStore {
    if (!ReviewStore.instance) {
      ReviewStore.instance = new ReviewStore();
    }
    return ReviewStore.instance;
  }

  setContext(context: ReviewContext) {
    this.currentContext = context;
  }

  getContext(): ReviewContext | null {
    return this.currentContext;
  }

  clearContext() {
    this.currentContext = null;
  }

  /**
   * 保存用户反馈（rating、feedback）
   */
  updateUserFeedback(rating?: number, feedback?: string) {
    if (this.currentContext) {
      this.currentContext.userRating = rating;
      this.currentContext.userFeedback = feedback;
    }
  }
}
```

#### File: `features/review/data/PhotoReviewRepository.ets`

```typescript
import { ReviewContext } from '../model/ReviewAdvice';

/**
 * 照片与复盘数据访问层
 */
export interface IPhotoReviewRepository {
  // 保存复盘上下文
  saveReviewContext(context: ReviewContext): Promise<boolean>;

  // 获取历史复盘
  getReviewHistory(templateId?: string): Promise<ReviewContext[]>;
}

export class PhotoReviewRepository implements IPhotoReviewRepository {
  async saveReviewContext(context: ReviewContext): Promise<boolean> {
    try {
      // TODO: 使用 ArkData 或文件系统保存
      return true;
    } catch (err) {
      console.error('Failed to save review context', err);
      return false;
    }
  }

  async getReviewHistory(templateId?: string): Promise<ReviewContext[]> {
    try {
      // TODO: 从存储读取
      return [];
    } catch (err) {
      console.error('Failed to load review history', err);
      return [];
    }
  }
}
```

---

### Task 1.6: 单元测试 (1 天)

#### File: `test/ets/rules/LightingCompositionRulesTest.ets`

```typescript
import { describe, it, expect } from '@ohos/hypium';
import LightingCompositionRules from '../../../features/core/rules/LightingCompositionRules';

export default function LightingCompositionRulesTest() {
  describe('LightingCompositionRules', () => {

    it('should diagnose backlit condition correctly', () => {
      const result = LightingCompositionRules.diagnoseLighting({
        avgBrightness: 128,
        faceROIBrightness: 60,
        backgroundBrightness: 180,
      });

      expect(result.type).assertEqual('backlit');
      expect(result.confidence).assertGreater(0.85);
    });

    it('should diagnose low light correctly', () => {
      const result = LightingCompositionRules.diagnoseLighting({
        avgBrightness: 60,
        faceROIBrightness: 50,
      });

      expect(result.type).assertEqual('low');
    });

    it('should diagnose adequate lighting correctly', () => {
      const result = LightingCompositionRules.diagnoseLighting({
        avgBrightness: 150,
        faceROIBrightness: 140,
      });

      expect(result.type).assertEqual('adequate');
    });

    it('should calculate composition correctly', () => {
      const result = LightingCompositionRules.diagnoseComposition(
        { xmin: 100, ymin: 50, width: 200, height: 400 },
        { width: 1080, height: 2340 }
      );

      expect(result.personCenterX).assertGreater(0);
      expect(result.personCenterX).assertLess(1);
      expect(result.personCenterY).assertGreater(0);
      expect(result.personCenterY).assertLess(1);
    });

    it('should score pose alignment correctly', () => {
      const template = [
        { name: 'nose', x: 0.5, y: 0.2 },
        { name: 'right_wrist', x: 0.7, y: 0.3 },
      ];
      const detected = [
        { name: 'nose', x: 0.51, y: 0.21, score: 0.95 },
        { name: 'right_wrist', x: 0.7, y: 0.3, score: 0.9 },
      ];

      const result = LightingCompositionRules.diagnosePose(template, detected);
      expect(result.overallScore).assertGreater(0.8);
      expect(result.keyPointsPresence).assertEqual(1.0);
    });
  });
}
```

#### File: `test/ets/review/ReviewAdviceTest.ets`

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { ReviewAdviceLibrary } from '../../../features/rules/data/ReviewAdviceLibrary';
import { ReviewDiagnosis } from '../../../core/rules/LightingCompositionRules';

export default function ReviewAdviceTest() {
  describe('ReviewAdviceLibrary', () => {

    it('should generate lighting advice for backlit condition', () => {
      const diagnosis: ReviewDiagnosis = {
        lighting: {
          type: 'backlit',
          averageBrightness: 128,
          faceROIBrightness: 60,
          confidence: 0.9,
        },
        composition: {
          personCenterX: 0.5,
          personCenterY: 0.5,
          isInRule3rdLine: true,
          skyOccupancy: 0.2,
          isUniformBackground: false,
        },
        pose: {
          overallScore: 0.85,
          perPartScores: {},
          mostMisalignedPart: 'none',
          keyPointsPresence: 1.0,
        },
        timestamp: Date.now(),
      };

      const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template');

      expect(advice.length).assertGreater(0);
      expect(advice[0].type).assertEqual('lighting');
    });

    it('should generate at most 3 advice items', () => {
      // ... 构造 diagnosis 同时触发多个问题
      // ...

      const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template', 3);
      expect(advice.length).assertLessOrEqual(3);
    });
  });
}
```

---

## 📋 Task Summary Table

| Task | File | 工作量 | 关键点 | 测试 |
|------|------|--------|--------|------|
| 1.1 | ReviewAdvice.ets | 0.5 天 | 数据模型设计 | ReviewAdviceTest |
| 1.2 | LightingCompositionRules.ets | 2 天 | 规则引擎核心实现 | LightingCompositionRulesTest |
| 1.3 | ReviewAdviceLibrary.ets | 0.5 天 | 文案映射 | ReviewAdviceTest |
| 1.4 | PhotoReview.ets | 1.5 天 | UI 布局、交互 | PhotoReviewViewActionsTest |
| 1.5 | ReviewStore + Repository | 1 天 | 数据持久化接口 | 单体测试 |
| 1.6 | 单元测试 | 1 天 | 关键路径覆盖 | 自验 |
| **小计** | | **6 天** | | |

---

## 🚀 Week 1 验收标准

- [ ] 所有新文件编译通过，无语法错误
- [ ] `LightingCompositionRules` 单元测试通过率 ≥ 90%
- [ ] `ReviewAdviceLibrary` 生成的文案符合业务需求（长度、优先级排序）
- [ ] `PhotoReview` 页面在模拟器上可正常显示（可用 mock 数据）
- [ ] 照片 → 规则诊断 → 建议生成 的完整流程可手动测试
- [ ] i18n 资源文件更新（新增中文字符串）

---

## 📝 Week 2 计划预告

**Week 2 (3-4 天)**:

1. **CameraGuide 集成** - 修改拍摄流程，拍照后自动跳 PhotoReview，传递诊断结果
2. **本地持久化** - 用 ArkData 保存复盘历史
3. **PhotoHistory 扩展** - 显示历史照片及其对应建议
4. **E2E 测试** - 模板选择 → 拍照 → 复盘 → 保存 的完整闭环
5. **性能调优** - 诊断延迟、内存占用优化

---

## ✅ 立即开始的 Action Items

1. **创建分支**: `feature/m3-photo-review`
2. **新建目录结构**: 按上述文件树创建所有文件
3. **实现 Task 1.1-1.3**: 数据模型 + 规则引擎 + 文案库（周一/二完成）
4. **编写测试**: 同步编写单元测试
5. **UI 实现**: Task 1.4 PhotoReview 页面（周二/三完成）
6. **集成验证**: 周四进行端到端测试

---

**预估总工作量**: **6 天** (单人高效开发，每天 8-10 小时)

**假设开始日期**: 2026-07-28 (周一)
**预计完成**: 2026-08-02 (周五)

---

欢迎提出问题或需要调整工作量！🚀
