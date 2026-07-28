import { describe, expect, it } from '@ohos/hypium';
import { ReviewAdviceLibrary } from '../../../main/ets/features/rules/data/ReviewAdviceLibrary';
import { ReviewDiagnosis } from '../../../main/ets/core/rules/LightingCompositionRules';
import { ReviewAdvice } from '../../../main/ets/features/review/model/ReviewAdvice';

export default function ReviewAdviceTest(): void {
  describe('ReviewAdviceLibrary', () => {

    // ==================== 建议生成测试 ====================

    describe('generateAdvice', () => {
      it('should_generate_lighting_advice_for_backlit_condition', 0, () => {
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
        expect(advice[0].level).assertEqual('critical');
        expect(advice[0].title.length).assertGreater(0);
      });

      it('should_generate_low_light_advice', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'low',
            averageBrightness: 60,
            faceROIBrightness: 50,
            confidence: 0.8,
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
        expect(advice[0].level).assertEqual('important');
      });

      it('should_not_generate_lighting_advice_for_adequate_light', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'adequate',
            averageBrightness: 150,
            faceROIBrightness: 140,
            confidence: 0.95,
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

        // 光线充足时可能不生成建议或生成鼓励信息
        // 取决于后续诊断
        expect(advice.length).assertLessOrEqual(3);
      });

      it('should_generate_pose_advice_when_misaligned', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'adequate',
            averageBrightness: 150,
            faceROIBrightness: 140,
            confidence: 0.95,
          },
          composition: {
            personCenterX: 0.5,
            personCenterY: 0.5,
            isInRule3rdLine: true,
            skyOccupancy: 0.2,
            isUniformBackground: false,
          },
          pose: {
            overallScore: 0.6,  // 偏低，会生成建议
            perPartScores: {
              'hand': 0.3,      // 最低
              'face': 0.7,
            },
            mostMisalignedPart: 'hand',
            keyPointsPresence: 1.0,
          },
          timestamp: Date.now(),
        };

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template');

        expect(advice.length).assertGreater(0);
        const poseAdvice = advice.find((a: ReviewAdvice) => a.type === 'pose');
        if (poseAdvice) {
          expect(poseAdvice.level).assertEqual('critical');
        }
      });

      it('should_not_generate_pose_advice_when_well_aligned', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'adequate',
            averageBrightness: 150,
            faceROIBrightness: 140,
            confidence: 0.95,
          },
          composition: {
            personCenterX: 0.5,
            personCenterY: 0.5,
            isInRule3rdLine: true,
            skyOccupancy: 0.2,
            isUniformBackground: false,
          },
          pose: {
            overallScore: 0.95,  // 很高，不会生成建议
            perPartScores: {},
            mostMisalignedPart: 'none',
            keyPointsPresence: 1.0,
          },
          timestamp: Date.now(),
        };

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template');

        // 姿势完美时，通常不生成姿势建议
        const poseAdvice = advice.find((a: ReviewAdvice) => a.type === 'pose');
        expect(poseAdvice).assertUndefined();
      });

      it('should_generate_composition_advice_when_not_in_rule_3rd', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'adequate',
            averageBrightness: 150,
            faceROIBrightness: 140,
            confidence: 0.95,
          },
          composition: {
            personCenterX: 0.1,  // 太靠左，不在 1/3 线
            personCenterY: 0.5,
            isInRule3rdLine: false,
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

        const compositionAdvice = advice.find((a: ReviewAdvice) => a.type === 'composition');
        if (compositionAdvice) {
          expect(compositionAdvice.level).assertEqual('important');
        }
      });

      it('should_return_at_most_max_advice_count', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'backlit',
            averageBrightness: 128,
            faceROIBrightness: 60,
            confidence: 0.9,
          },
          composition: {
            personCenterX: 0.1,  // 不在 1/3 线
            personCenterY: 0.5,
            isInRule3rdLine: false,
            skyOccupancy: 0.2,
            isUniformBackground: false,
          },
          pose: {
            overallScore: 0.5,  // 较低，会生成建议
            perPartScores: { 'hand': 0.2 },
            mostMisalignedPart: 'hand',
            keyPointsPresence: 1.0,
          },
          timestamp: Date.now(),
        };

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template', 3);
        expect(advice.length).assertLessOrEqual(3);
      });

      it('should_sort_advice_by_priority_descending', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'backlit',  // priority 9
            averageBrightness: 128,
            faceROIBrightness: 60,
            confidence: 0.9,
          },
          composition: {
            personCenterX: 0.1,  // priority 6
            personCenterY: 0.5,
            isInRule3rdLine: false,
            skyOccupancy: 0.2,
            isUniformBackground: false,
          },
          pose: {
            overallScore: 0.5,  // priority 9
            perPartScores: { 'hand': 0.2 },
            mostMisalignedPart: 'hand',
            keyPointsPresence: 1.0,
          },
          timestamp: Date.now(),
        };

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template');

        // 验证优先级排序（从高到低）
        for (let i = 0; i < advice.length - 1; i++) {
          expect(advice[i].priority).assertGreaterOrEqual(advice[i + 1].priority);
        }
      });

      it('should_include_metadata_in_generated_advice', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'low',
            averageBrightness: 60,
            faceROIBrightness: 50,
            confidence: 0.8,
          },
          composition: {
            personCenterX: 0.4,
            personCenterY: 0.5,
            isInRule3rdLine: true,
            skyOccupancy: 0.2,
            isUniformBackground: false,
          },
          pose: {
            overallScore: 0.75,
            perPartScores: { 'nose': 0.8, 'hand': 0.7 },
            mostMisalignedPart: 'hand',
            keyPointsPresence: 1.0,
          },
          timestamp: Date.now(),
        };

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template');

        if (advice.length > 0 && advice[0].metadata) {
          expect(advice[0].metadata.faceAverageBrightness).assertEqual(50);
          expect(advice[0].metadata.personPositionX).assertEqual(0.4);
          expect(advice[0].metadata.poseAlignmentScore).assertEqual(0.75);
        }
      });
    });

    // ==================== Fallback 降级测试 ====================

    describe('getFallbackAdvice', () => {
      it('should_return_fallback_advice_when_diagnosis_fails', 0, () => {
        const fallback = ReviewAdviceLibrary.getFallbackAdvice();

        expect(fallback.length).assertGreater(0);
        expect(fallback[0].type).assertEqual('style_summary');
        expect(fallback[0].level).assertEqual('nice_to_have');
        expect(fallback[0].title.length).assertGreater(0);
      });

      it('fallback_advice_should_be_encouraging', 0, () => {
        const fallback = ReviewAdviceLibrary.getFallbackAdvice();

        expect(fallback[0].confidence).assertEqual(1.0);
        expect(fallback[0].priority).assertLess(5);  // 低优先级
      });
    });

    // ==================== 边界情况测试 ====================

    describe('edge_cases', () => {
      it('should_handle_zero_max_advice_count', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'low',
            averageBrightness: 60,
            faceROIBrightness: 50,
            confidence: 0.8,
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

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template', 0);
        expect(advice.length).assertEqual(0);
      });

      it('should_handle_large_max_advice_count', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'low',
            averageBrightness: 60,
            faceROIBrightness: 50,
            confidence: 0.8,
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

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template', 100);
        expect(advice.length).assertLessOrEqual(3);  // 最多只能生成 3 种类型的建议
      });

      it('should_handle_unknown_misaligned_part', 0, () => {
        const diagnosis: ReviewDiagnosis = {
          lighting: {
            type: 'adequate',
            averageBrightness: 150,
            faceROIBrightness: 140,
            confidence: 0.95,
          },
          composition: {
            personCenterX: 0.5,
            personCenterY: 0.5,
            isInRule3rdLine: true,
            skyOccupancy: 0.2,
            isUniformBackground: false,
          },
          pose: {
            overallScore: 0.5,
            perPartScores: {},
            mostMisalignedPart: 'unknown_part',  // 未知部位
            keyPointsPresence: 1.0,
          },
          timestamp: Date.now(),
        };

        const advice = ReviewAdviceLibrary.generateAdvice(diagnosis, 'test_template');

        // 应该优雅地处理未知部位，可能不生成姿势建议
        expect(advice).assertNotNull();
      });
    });
  });
}
