/**
 * M3 拍后复盘建议文案库
 *
 * 根据规则引擎诊断结果，生成本地化的建议文案
 * 支持多语言和 fallback 降级
 */

import { ReviewAdvice } from '../../review/model/ReviewAdvice';
import { ReviewDiagnosis } from '../../../core/rules/LightingCompositionRules';
import hilog from '@ohos.hilog';

const TAG = 'ReviewAdviceLibrary';

export class ReviewAdviceLibrary {

  private static readonly ADVICE_TEMPLATES = {
    // ===== 光线建议 =====
    lighting: {
      backlit: [
        {
          title: '正在逆光，建议改变角度',
          description: '背景太亮，脸部偏暗。可试试转身让光线从侧面打过来',
          actionableSteps: ['转身 45°，让光从侧面打过来', '或者向背景走近，减少背景亮度'],
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
          actionableSteps: ['靠近窗户，获取自然光', '或打开房间灯光进行补光'],
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
          actionableSteps: ['避开直接阳光', '寻找半阴影区域'],
          priority: 7,
        },
      ],
      adequate: [] // 光线充足时可不显示光线建议
    },

    // ===== 构图建议 =====
    composition: {
      notInRule3rdLine: [
        {
          title: '人物可往画面右 1/3 移动',
          description: '黄金分割构图会让照片更耐看',
          actionableSteps: ['调整身体位置至画面右侧 1/3 线'],
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
          actionableSteps: ['参考顶部示范图调整手部位置'],
          priority: 9,
        },
      ],
      face_misaligned: [
        {
          title: '脸的角度还差一点',
          description: '试试下巴微收或抬起',
          actionableSteps: ['下巴微收，显得脸更小', '或抬头 15°，角度更好看'],
          priority: 9,
        },
      ],
      shoulder_misaligned: [
        {
          title: '肩膀位置可以更放松',
          description: '肩膀下沉会显得更自然',
          actionableSteps: ['肩膀放松下沉', '头微微后仰，显得气质更好'],
          priority: 7,
        },
      ],
      leg_misaligned: [
        {
          title: '腿部站姿还可以优化',
          description: '重心向前移会显得更有气场',
          actionableSteps: ['重心前移至脚尖', '或两脚分开与肩同宽'],
          priority: 5,
        },
      ],
    },
  };

  /**
   * 基于诊断结果，生成优先级排序的建议文案
   *
   * M3 核心功能：将规则引擎的诊断结果转化为用户友好的建议
   *
   * 建议优先级顺序：
   * 1. 光线问题（逆光/过暗/过亮）- 影响基础质量
   * 2. 姿势问题（手臂/脸部/身体错位）- 影响构图完成度
   * 3. 构图问题（位置/天空比例/背景）- 影响美感
   *
   * 工作流程：
   * 1. 为每个诊断维度生成候选建议
   * 2. 按优先级排序
   * 3. 返回前 N 条最重要的建议
   * 4. 附加元数据用于后续分析
   *
   * 性能：
   * - 诊断结果 → 建议映射：O(1)
   * - 排序：O(k log k)，k ≤ 3（通常 < 10 ms）
   * - 执行时间：5-10 ms
   *
   * @param diagnosis - ReviewRulesEngine 的诊断结果
   *   - lighting: {type, confidence, brightness}
   *   - composition: {centerX, centerY, isInRule3rdLine}
   *   - pose: {overallScore, mostMisalignedPart, perPartScores}
   *
   * @param templateId - 当前使用的风格模板 ID
   *   - 用于个性化建议和统计
   *
   * @param maxAdviceCount - 最多返回几条建议（默认 3）
   *   - 太多会分散用户注意力
   *   - 太少可能遗漏重要问题
   *
   * @returns ReviewAdvice[] - 排序后的建议列表
   *   - 每条建议包含：标题、描述、可操作步骤、置信度、优先级
   *   - 附加元数据用于分析和反馈
   *
   * @example
   * const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'template_1', 3);
   * // 返回：[
   * //   {
   * //     id: 'advice_0',
   * //     type: 'lighting',
   * //     level: 'critical',
   * //     title: '正在逆光...',
   * //     priority: 9,
   * //     metadata: { faceAverageBrightness: 65, ... }
   * //   },
   * //   ...
   * // ]
   */
  static generateAdvice(
    diagnosis: ReviewDiagnosis,
    templateId: string,
    maxAdviceCount: number = 3
  ): ReviewAdvice[] {
    // ============ 第一步：生成各类建议候选 ============
    const candidates: ReviewAdvice[] = [];

    // 光线建议（优先级最高 - 影响基础曝光）
    const lightingAdvice = this.generateLightingAdvice(diagnosis.lighting);
    if (lightingAdvice) {
      candidates.push(lightingAdvice);
    }

    // 姿势建议（优先级次高 - 影响模板完成度）
    const poseAdvice = this.generatePoseAdvice(diagnosis.pose);
    if (poseAdvice) {
      candidates.push(poseAdvice);
    }

    // 构图建议（优先级较低 - 影响美学）
    const compositionAdvice = this.generateCompositionAdvice(diagnosis.composition);
    if (compositionAdvice) {
      candidates.push(compositionAdvice);
    }

    // ============ 第二步：按优先级排序和截取 ============
    // 按 priority 从高到低排序，然后取前 maxAdviceCount 条
    // 例如：[9, 8, 8, 7, 6] → [9, 8, 8]（最多3条）
    const sorted = candidates
      .sort((a, b) => b.priority - a.priority)
      .slice(0, maxAdviceCount)
      .map((advice, idx) => ({
        ...advice,
        id: `advice_${idx}`,  // 赋予唯一 ID

        // ============ 第三步：附加诊断元数据 ============
        // 这些元数据用于：
        // 1. UI 显示时的上下文信息
        // 2. 用户反馈统计
        // 3. 模型优化
        metadata: {
          ...advice.metadata,
          faceAverageBrightness: diagnosis.lighting.faceROIBrightness,
          personPositionX: diagnosis.composition.personCenterX,
          personPositionY: diagnosis.composition.personCenterY,
          poseAlignmentScore: diagnosis.pose.overallScore,
          keyPointDetails: diagnosis.pose.perPartScores,
        },
      }));

    hilog.info(0x0000, TAG, `Generated ${sorted.length} advice items`);
    return sorted;
  }

  /**
   * 根据光线诊断生成建议
   *
   * 逻辑：
   * - 光线充足 → 无建议（adequate 时返回 null）
   * - 逆光 → 改变角度建议（critical 级别）
   * - 曝光不足 → 补光建议（important 级别）
   * - 曝光过度 → 避光建议（important 级别）
   *
   * 性能：O(1)，2-3 次查表
   *
   * @param lighting - 光线诊断结果 {type, confidence}
   * @returns ReviewAdvice 或 null（如果光线充足则返回 null）
   */
  private static generateLightingAdvice(lighting: ReviewDiagnosis['lighting']): ReviewAdvice | null {
    // 光线充足时，不需要光线方面的建议
    if (lighting.type === 'adequate') {
      return null;
    }

    // 从文案模板库中查询该类型的建议
    // 例如：lighting.type = 'backlit' → 返回 ADVICE_TEMPLATES.lighting.backlit[]
    const templates = (this.ADVICE_TEMPLATES.lighting as any)[lighting.type];
    if (!templates || templates.length === 0) {
      return null;  // 如果没有对应的文案模板，返回 null
    }

    // 取第一条建议（因为它是优先级最高的）
    const template = templates[0];
    return {
      id: '',  // 将在 generateAdvice 中赋值
      type: 'lighting',  // 建议类型

      // 根据严重程度分级
      // - 逆光（backlit）：critical 级别（需要立即改变）
      // - 其他光线问题（low/overexposed）：important 级别（建议改进）
      level: lighting.type === 'backlit' ? 'critical' : 'important',

      title: template.title,               // 建议标题
      description: template.description,   // 详细描述
      actionableSteps: template.actionableSteps,  // 可操作的具体步骤
      confidence: lighting.confidence,     // 诊断置信度（0-1）
      priority: template.priority,         // 优先级（1-10）
    };
  }

  private static generatePoseAdvice(pose: ReviewDiagnosis['pose']): ReviewAdvice | null {
    if (pose.overallScore > 0.8) {
      return null;
    }

    const misalignedPart = pose.mostMisalignedPart;
    if (!misalignedPart || misalignedPart === 'unknown') {
      return null;
    }

    const adviceKey = `${misalignedPart}_misaligned`;
    const templates = (this.ADVICE_TEMPLATES.pose as any)[adviceKey];

    if (!templates || templates.length === 0) {
      return null;
    }

    const template = templates[0];
    return {
      id: '',
      type: 'pose',
      level: 'critical',
      title: template.title,
      description: template.description,
      actionableSteps: template.actionableSteps,
      confidence: pose.overallScore,
      priority: template.priority,
    };
  }

  private static generateCompositionAdvice(composition: ReviewDiagnosis['composition']): ReviewAdvice | null {
    if (composition.isInRule3rdLine) {
      return null;
    }

    const templates = this.ADVICE_TEMPLATES.composition.notInRule3rdLine;
    if (!templates || templates.length === 0) {
      return null;
    }

    const template = templates[0];
    return {
      id: '',
      type: 'composition',
      level: 'important',
      title: template.title,
      description: template.description,
      actionableSteps: template.actionableSteps,
      confidence: 0.7,
      priority: template.priority,
    };
  }

  /**
   * Fallback：当诊断失败时返回通用鼓励文案
   */
  static getFallbackAdvice(): ReviewAdvice[] {
    return [
      {
        id: 'fallback_0',
        type: 'style_summary',
        level: 'nice_to_have',
        title: '拍摄完成！',
        description: '您的表现很棒，保持这个状态继续创作吧',
        confidence: 1.0,
        priority: 1,
      },
    ];
  }
}

export default ReviewAdviceLibrary;
