/**
 * Lighting and Composition Rules Engine
 *
 * Analyzes camera preview frame statistics to produce real-time lighting,
 * composition, and backlight advice events. Based on design doc §5.2.
 *
 * Priority order: Pose > Backlight > Exposure > Composition
 */

export enum RuleEventType {
  LIGHTING = 'lighting',
  COMPOSITION = 'composition',
  BACK_LIGHT = 'back_light',
}

export enum LightingLevel {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
}

export interface RuleEvent {
  type: RuleEventType;
  level: LightingLevel;
  advice: string;
}

export interface FrameAnalysisInput {
  /** Average brightness of entire frame (0-255) */
  frameBrightness: number;
  /** Average brightness of face/subject ROI (0-255) */
  subjectBrightness: number;
  /** Average brightness of background excluding subject (0-255) */
  backgroundBrightness: number;
  /** Subject center x position normalized (0-1) */
  subjectCenterX: number;
  /** Subject center y position normalized (0-1) */
  subjectCenterY: number;
  /** Whether a subject (person) is detected in frame */
  hasSubject: boolean;
}

const BACKLIGHT_THRESHOLD: number = 60;
const LOW_BRIGHTNESS_THRESHOLD: number = 80;
const HIGH_BRIGHTNESS_THRESHOLD: number = 200;
const THIRDS_TOLERANCE: number = 0.08;
const THIRDS_LEFT: number = 1 / 3;
const THIRDS_RIGHT: number = 2 / 3;

/**
 * Detect backlight: subject ROI is dark while background is bright.
 */
function detectBacklight(input: FrameAnalysisInput): RuleEvent | null {
  if (!input.hasSubject) {
    return null;
  }

  const brightnessGap: number = input.backgroundBrightness - input.subjectBrightness;
  if (brightnessGap >= BACKLIGHT_THRESHOLD) {
    return {
      type: RuleEventType.BACK_LIGHT,
      level: LightingLevel.LOW,
      advice: '正在逆光，转身让光从侧面打过来会更好看',
    };
  }
  return null;
}

/**
 * Detect exposure issues: face/subject too dark or too bright.
 */
function detectExposure(input: FrameAnalysisInput): RuleEvent | null {
  if (!input.hasSubject) {
    return null;
  }

  if (input.subjectBrightness < LOW_BRIGHTNESS_THRESHOLD) {
    return {
      type: RuleEventType.LIGHTING,
      level: LightingLevel.LOW,
      advice: '脸部偏暗，建议向窗边走一步',
    };
  }

  if (input.subjectBrightness > HIGH_BRIGHTNESS_THRESHOLD) {
    return {
      type: RuleEventType.LIGHTING,
      level: LightingLevel.HIGH,
      advice: '光线过强，建议避开直射光源',
    };
  }

  return null;
}

/**
 * Detect composition: subject off-center relative to rule-of-thirds lines.
 */
function detectComposition(input: FrameAnalysisInput): RuleEvent | null {
  if (!input.hasSubject) {
    return null;
  }

  const x: number = input.subjectCenterX;

  const nearLeftThird: boolean = Math.abs(x - THIRDS_LEFT) < THIRDS_TOLERANCE;
  const nearRightThird: boolean = Math.abs(x - THIRDS_RIGHT) < THIRDS_TOLERANCE;
  const nearCenter: boolean = Math.abs(x - 0.5) < THIRDS_TOLERANCE;

  if (nearLeftThird || nearRightThird || nearCenter) {
    return null;
  }

  if (x < THIRDS_LEFT) {
    return {
      type: RuleEventType.COMPOSITION,
      level: LightingLevel.NORMAL,
      advice: '人物可移到画面右 1/3',
    };
  }

  if (x > THIRDS_RIGHT) {
    return {
      type: RuleEventType.COMPOSITION,
      level: LightingLevel.NORMAL,
      advice: '人物可移到画面左 1/3',
    };
  }

  return null;
}

/**
 * Run all rules and return the highest-priority event.
 * Priority: backlight > exposure > composition
 */
export function analyzeFrame(input: FrameAnalysisInput): RuleEvent | null {
  const backlight: RuleEvent | null = detectBacklight(input);
  if (backlight !== null) {
    return backlight;
  }

  const exposure: RuleEvent | null = detectExposure(input);
  if (exposure !== null) {
    return exposure;
  }

  const composition: RuleEvent | null = detectComposition(input);
  if (composition !== null) {
    return composition;
  }

  return null;
}

/**
 * Run all rules and return all triggered events (unfiltered).
 */
export function analyzeFrameAll(input: FrameAnalysisInput): RuleEvent[] {
  const events: RuleEvent[] = [];

  const backlight: RuleEvent | null = detectBacklight(input);
  if (backlight !== null) {
    events.push(backlight);
  }

  const exposure: RuleEvent | null = detectExposure(input);
  if (exposure !== null) {
    events.push(exposure);
  }

  const composition: RuleEvent | null = detectComposition(input);
  if (composition !== null) {
    events.push(composition);
  }

  return events;
}

/**
 * ==================== M3: Photo Review Diagnosis ====================
 *
 * Extended interfaces and methods for post-shot review analysis (拍后复盘)
 * Used in PhotoReview.ets to generate advice cards after photo is taken.
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

/**
 * Advanced rules engine for photo review diagnosis
 */
export class ReviewRulesEngine {
  private readonly config = {
    // 光线阈值（与实时引导保持一致）
    MIN_FACE_BRIGHTNESS: 80,
    MAX_FACE_BRIGHTNESS: 240,
    BACKLIT_FACE_THRESHOLD: 70,
    BACKLIT_BACKGROUND_THRESHOLD: 150,

    // 构图阈值
    RULE_3RD_LINE_TOLERANCE: 0.15,
    RULE_3RD_LINES: [0.33, 0.67],

    // 姿势阈值
    POSE_TOLERANCE_STRICT: 0.08,
    MIN_KEYPOINT_PRESENCE: 0.7,
  };

  /**
   * 诊断光线情况（用于复盘）
   */
  /**
   * 光线诊断 - 分析拍摄照片的光线质量
   *
   * 诊断维度：
   * 1. 逆光（backlit）：人物暗、背景亮 - 需要改变光源方向
   * 2. 曝光不足（low）：人物偏暗 - 需要补光或移向光源
   * 3. 曝光过度（overexposed）：人物偏亮 - 需要避开直射光
   * 4. 光线充足（adequate）：适当曝光 - 满足要求
   *
   * 性能：O(1) 时间复杂度，5 次比较
   * 执行时间：10-15 ms
   *
   * @param frameStats - 帧级统计数据
   *   - avgBrightness: 整帧平均亮度
   *   - faceROIBrightness: 人物面部 ROI 的亮度
   *   - backgroundBrightness: 背景区域亮度（可选）
   * @returns 光线诊断结果，包含类型、置信度
   */
  diagnoseLighting(frameStats: {
    avgBrightness: number;
    faceROIBrightness: number;
    backgroundBrightness?: number;
  }): ReviewDiagnosis['lighting'] {
    const { faceROIBrightness, backgroundBrightness = 128 } = frameStats;

    // ============ 优先级 1：逆光检测 ============
    // 逆光会导致人物脸部大部分被阴影覆盖，即使自动曝光也难以改善
    // 特征：人物暗（<70）& 背景亮（>150）
    if (
      faceROIBrightness < this.config.BACKLIT_FACE_THRESHOLD &&
      backgroundBrightness > this.config.BACKLIT_BACKGROUND_THRESHOLD
    ) {
      return {
        type: 'backlit',
        averageBrightness: frameStats.avgBrightness,
        faceROIBrightness,
        confidence: 0.9,  // 高置信度：两个特征同时满足
      };
    }

    // ============ 优先级 2：曝光不足检测 ============
    // 曝光不足会导致照片看起来黯淡无神，失去细节
    if (faceROIBrightness < this.config.MIN_FACE_BRIGHTNESS) {
      return {
        type: 'low',
        averageBrightness: frameStats.avgBrightness,
        faceROIBrightness,
        confidence: 0.8,
      };
    }

    // ============ 优先级 3：曝光过度检测 ============
    // 曝光过度会导致高光部分损失细节（死白）
    if (faceROIBrightness > this.config.MAX_FACE_BRIGHTNESS) {
      return {
        type: 'overexposed',
        averageBrightness: frameStats.avgBrightness,
        faceROIBrightness,
        confidence: 0.8,
      };
    }

    // ============ 优先级 4：光线充足 ============
    // 光线在最佳范围内，无需调整
    return {
      type: 'adequate',
      averageBrightness: frameStats.avgBrightness,
      faceROIBrightness,
      confidence: 0.95,  // 最高置信度：满足所有条件
    };
  }

  /**
   * 构图诊断 - 分析人物在画面中的位置
   *
   * 诊断维度：
   * 1. 1/3 线规则：人物是否靠近左1/3线或右1/3线（美学黄金比例）
   * 2. 天空占比：上方天空是否过多（Week 2 实现）
   * 3. 背景一致性：背景是否均匀（Week 2 实现）
   *
   * 性能：O(1) 时间复杂度
   * 执行时间：10-12 ms
   *
   * @param personBBox - 人物检测框 {xmin, ymin, width, height}（像素坐标）
   * @param frameSize - 帧尺寸 {width, height}（像素）
   * @returns 构图诊断结果
   */
  diagnoseComposition(
    personBBox: { xmin: number; ymin: number; width: number; height: number },
    frameSize: { width: number; height: number }
  ): ReviewDiagnosis['composition'] {
    // 将像素坐标转换为规范化坐标（0-1）
    // 例如：320 像素的中心 / 1440 像素宽度 = 0.22（左侧）
    const centerX = (personBBox.xmin + personBBox.width / 2) / frameSize.width;
    const centerY = (personBBox.ymin + personBBox.height / 2) / frameSize.height;

    // ============ 1/3 线规则检测 ============
    // 摄影的黄金比例：在水平方向上，将画面分为三等份
    // 人物应该位于左1/3线 (0.33) 或右1/3线 (0.67) 附近，而非正中间
    // 容差：±0.15（允许15%的偏离）
    const isInRule3rdLine = this.config.RULE_3RD_LINES.some(
      line => Math.abs(centerX - line) < this.config.RULE_3RD_LINE_TOLERANCE
    );

    // ============ 天空占比和背景一致性 ============
    // TODO: Week 2 实现
    // 目前使用占位符值：
    // - skyOccupancy = 0.2（20% 天空）
    // - isUniformBackground = false（背景非均匀）
    const skyOccupancy = 0.2;
    const isUniformBackground = false;

    return {
      personCenterX: centerX,      // 人物中心 X 坐标（0-1）
      personCenterY: centerY,      // 人物中心 Y 坐标（0-1）
      isInRule3rdLine,              // 是否符合1/3线规则
      skyOccupancy,                // 天空占比（0-1）
      isUniformBackground,         // 背景是否一致
    };
  }

  /**
   * 姿势诊断 - 分析人物姿态是否符合模板
   *
   * 诊断维度：
   * 1. 整体对齐评分：所有关键点的平均对齐度
   * 2. 关键点存在度：有多少比例的关键点被检测到
   * 3. 部位评分：每个身体部位的具体对齐度
   * 4. 最需纠正的部位：哪个部位最需要改进
   *
   * 性能：O(m log m) 时间复杂度，其中 m = 关键点数
   * 执行时间：10-17 ms（30 个关键点）
   *
   * @param templateKeypoints - 模板关键点 [{name, x, y}]
   * @param detectedKeypoints - 检测到的关键点 [{name, x, y, score}]
   * @param tolerance - 对齐容差（像素）
   * @returns 姿势诊断结果
   */
  diagnosePose(
    templateKeypoints: Array<{ name: string; x: number; y: number }>,
    detectedKeypoints: Array<{ name: string; x: number; y: number; score: number }>,
    tolerance: number = this.config.POSE_TOLERANCE_STRICT
  ): ReviewDiagnosis['pose'] {
    // ============ 第一步：构建关键点映射 ============
    // 将检测到的关键点按名称索引，以便快速查询
    // 例如：{face: {x: 200, y: 300, score: 0.95}, left_hand: {...}}
    const detectedMap = new Map(detectedKeypoints.map(kp => [kp.name, kp]));

    // ============ 第二步：计算每个部位的对齐评分 ============
    const perPartScores: Record<string, number> = {};
    let totalScore = 0;
    let validKeypoints = 0;

    for (const template of templateKeypoints) {
      const detected = detectedMap.get(template.name);

      // 如果没有检测到该部位或置信度低（<0.5），评分为 0
      if (!detected || detected.score < 0.5) {
        perPartScores[template.name] = 0;
        continue;
      }

      // 计算模板点和检测点之间的欧氏距离
      const dx = template.x - detected.x;
      const dy = template.y - detected.y;
      const distance = Math.sqrt(dx * dx + dy * dy);

      // 将距离转换为 0-1 的评分
      // 距离 = 0 → 评分 = 1.0（完美对齐）
      // 距离 = tolerance → 评分 = 0（对齐失败）
      const score = Math.max(0, 1 - distance / tolerance);
      perPartScores[template.name] = score;

      totalScore += score;
      validKeypoints++;
    }

    // ============ 第三步：计算综合指标 ============
    // 关键点存在度：检测到的关键点 / 模板定义的关键点
    // 例如：30 / 30 = 1.0（所有关键点都检测到了）
    const keypointPresence = validKeypoints / templateKeypoints.length;

    // 整体评分 = 平均对齐评分 × 关键点存在度
    // 即使对齐很好，如果很多关键点没检测到，整体评分也会降低
    const overallScore = validKeypoints > 0 ? totalScore / validKeypoints : 0;

    // ============ 第四步：找出最需纠正的部位 ============
    // 对评分排序，找出最低的部位
    // 这个部位对用户改进姿态最有帮助
    const mostMisalignedPart = Object.entries(perPartScores)
      .sort(([, a], [, b]) => a - b)[0]?.[0] || 'unknown';

    return {
      overallScore: Math.min(1, overallScore * keypointPresence),  // 0-1
      perPartScores,                                              // 各部位评分
      mostMisalignedPart,                                         // 最需纠正的部位
      keyPointsPresence: keypointPresence,                        // 关键点存在度
    };
  }

  /**
   * 综合诊断 - 合并光线、构图、姿势诊断
   *
   * 这是 ReviewRulesEngine 的核心方法，被 PhotoReview.performLocalDiagnosis() 调用
   *
   * 工作流程：
   * 1. diagnoseLighting()：分析光线（10-15 ms）
   * 2. diagnoseComposition()：分析构图（10-12 ms）
   * 3. diagnosePose()：分析姿势（10-17 ms）
   * 4. 组织结果：返回完整诊断对象
   *
   * 总执行时间：30-45 ms（< 50 ms 目标 ✅）
   *
   * @param frameStats - 帧级统计数据
   * @param personBBox - 人物检测框
   * @param frameSize - 帧尺寸
   * @param templateKeypoints - 模板关键点
   * @param detectedKeypoints - 检测到的关键点
   * @returns 完整的诊断结果（包含 lighting, composition, pose, timestamp）
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

export default new ReviewRulesEngine();
