/**
 * M3 拍后复盘数据模型
 *
 * 定义复盘建议、诊断结果等核心数据结构
 */

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
