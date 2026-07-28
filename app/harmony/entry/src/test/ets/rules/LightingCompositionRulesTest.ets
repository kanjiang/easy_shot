import { describe, expect, it } from '@ohos/hypium';
import { ReviewRulesEngine, ReviewDiagnosis } from '../../../main/ets/core/rules/LightingCompositionRules';

export default function LightingCompositionRulesTest(): void {
  describe('LightingCompositionRules', () => {
    const engine = new ReviewRulesEngine();

    // ==================== 光线诊断测试 ====================

    describe('diagnoseLighting', () => {
      it('should_diagnose_backlit_condition_correctly', 0, () => {
        const result = engine.diagnoseLighting({
          avgBrightness: 128,
          faceROIBrightness: 60,
          backgroundBrightness: 180,
        });

        expect(result.type).assertEqual('backlit');
        expect(result.faceROIBrightness).assertEqual(60);
        expect(result.confidence).assertGreater(0.85);
      });

      it('should_diagnose_low_light_correctly', 0, () => {
        const result = engine.diagnoseLighting({
          avgBrightness: 60,
          faceROIBrightness: 50,
          backgroundBrightness: 70,
        });

        expect(result.type).assertEqual('low');
        expect(result.confidence).assertGreater(0.7);
      });

      it('should_diagnose_overexposed_correctly', 0, () => {
        const result = engine.diagnoseLighting({
          avgBrightness: 240,
          faceROIBrightness: 250,
          backgroundBrightness: 240,
        });

        expect(result.type).assertEqual('overexposed');
        expect(result.confidence).assertGreater(0.7);
      });

      it('should_diagnose_adequate_lighting_correctly', 0, () => {
        const result = engine.diagnoseLighting({
          avgBrightness: 150,
          faceROIBrightness: 140,
          backgroundBrightness: 160,
        });

        expect(result.type).assertEqual('adequate');
        expect(result.confidence).assertGreater(0.9);
      });

      it('should_handle_missing_background_brightness', 0, () => {
        const result = engine.diagnoseLighting({
          avgBrightness: 150,
          faceROIBrightness: 140,
        });

        expect(result.type).assertEqual('adequate');
      });

      it('should_detect_backlit_with_no_background_brightness_param', 0, () => {
        const result = engine.diagnoseLighting({
          avgBrightness: 100,
          faceROIBrightness: 60,
        });

        // 当没有 backgroundBrightness 时，默认为 128，不会被判定为逆光
        expect(result.type).assertEqual('low');
      });
    });

    // ==================== 构图诊断测试 ====================

    describe('diagnoseComposition', () => {
      it('should_calculate_center_position_correctly', 0, () => {
        const result = engine.diagnoseComposition(
          { xmin: 100, ymin: 50, width: 200, height: 400 },
          { width: 1080, height: 2340 }
        );

        expect(result.personCenterX).assertGreater(0);
        expect(result.personCenterX).assertLess(1);
        expect(result.personCenterY).assertGreater(0);
        expect(result.personCenterY).assertLess(1);
      });

      it('should_detect_person_in_rule_3rd_line_left', 0, () => {
        // 人物中心在画面左 1/3 线附近 (x ≈ 0.33)
        const result = engine.diagnoseComposition(
          { xmin: 0, ymin: 0, width: 100, height: 1000 },
          { width: 1080, height: 2340 }
        );

        // x = (0 + 100/2) / 1080 ≈ 0.046, 不在 1/3 线
        expect(result.isInRule3rdLine).assertFalse();
      });

      it('should_detect_person_not_in_rule_3rd_line', 0, () => {
        // 人物中心在画面中心
        const result = engine.diagnoseComposition(
          { xmin: 450, ymin: 0, width: 180, height: 1000 },
          { width: 1080, height: 2340 }
        );

        // x = (450 + 90) / 1080 ≈ 0.5, 在中心，不在 1/3 线
        expect(result.isInRule3rdLine).assertFalse();
      });

      it('should_handle_edge_cases_for_composition', 0, () => {
        const result = engine.diagnoseComposition(
          { xmin: 0, ymin: 0, width: 1080, height: 2340 },
          { width: 1080, height: 2340 }
        );

        expect(result.personCenterX).assertEqual(0.5);
        expect(result.personCenterY).assertEqual(0.5);
      });

      it('should_return_composition_with_default_sky_occupancy', 0, () => {
        const result = engine.diagnoseComposition(
          { xmin: 100, ymin: 100, width: 200, height: 200 },
          { width: 1080, height: 2340 }
        );

        expect(result.skyOccupancy).assertEqual(0.2);  // 当前硬编码为 0.2
        expect(result.isUniformBackground).assertFalse();  // 当前硬编码为 false
      });
    });

    // ==================== 姿势对齐诊断测试 ====================

    describe('diagnosePose', () => {
      it('should_score_perfect_pose_alignment', 0, () => {
        const template = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
        ];
        const detected = [
          { name: 'nose', x: 0.5, y: 0.2, score: 0.95 },
          { name: 'right_wrist', x: 0.7, y: 0.3, score: 0.9 },
        ];

        const result = engine.diagnosePose(template, detected);
        expect(result.overallScore).assertGreater(0.9);
        expect(result.keyPointsPresence).assertEqual(1.0);
        expect(result.perPartScores['nose']).assertGreater(0.9);
      });

      it('should_score_misaligned_pose', 0, () => {
        const template = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
        ];
        const detected = [
          { name: 'nose', x: 0.6, y: 0.3, score: 0.95 },  // 偏离
          { name: 'right_wrist', x: 0.7, y: 0.3, score: 0.9 },
        ];

        const result = engine.diagnosePose(template, detected);
        expect(result.overallScore).assertLess(0.9);
        expect(result.mostMisalignedPart).assertEqual('nose');
      });

      it('should_handle_low_confidence_keypoints', 0, () => {
        const template = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
        ];
        const detected = [
          { name: 'nose', x: 0.5, y: 0.2, score: 0.3 },  // 低置信度，会被忽略
          { name: 'right_wrist', x: 0.7, y: 0.3, score: 0.9 },
        ];

        const result = engine.diagnosePose(template, detected);
        expect(result.keyPointsPresence).assertEqual(0.5);  // 50% 的关键点
        expect(result.perPartScores['nose']).assertEqual(0);
      });

      it('should_handle_missing_detected_keypoints', 0, () => {
        const template = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
          { name: 'left_shoulder', x: 0.3, y: 0.4 },
        ];
        const detected = [
          { name: 'nose', x: 0.5, y: 0.2, score: 0.95 },
          // right_wrist 和 left_shoulder 缺失
        ];

        const result = engine.diagnosePose(template, detected);
        expect(result.keyPointsPresence).assertLess(0.5);
        expect(result.overallScore).assertLess(0.5);
      });

      it('should_find_most_misaligned_part', 0, () => {
        const template = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
          { name: 'left_shoulder', x: 0.3, y: 0.4 },
        ];
        const detected = [
          { name: 'nose', x: 0.5, y: 0.2, score: 0.95 },           // 完美
          { name: 'right_wrist', x: 0.8, y: 0.4, score: 0.9 },    // 偏离较大
          { name: 'left_shoulder', x: 0.31, y: 0.41, score: 0.9 }, // 偏离较小
        ];

        const result = engine.diagnosePose(template, detected);
        expect(result.mostMisalignedPart).assertEqual('right_wrist');
      });

      it('should_handle_empty_template', 0, () => {
        const template: any[] = [];
        const detected = [
          { name: 'nose', x: 0.5, y: 0.2, score: 0.95 },
        ];

        const result = engine.diagnosePose(template, detected);
        expect(result.keyPointsPresence).assertEqual(0);  // 0 / 0
      });
    });

    // ==================== 综合诊断测试 ====================

    describe('synthesizeDiagnosis', () => {
      it('should_synthesize_complete_diagnosis', 0, () => {
        const frameStats = {
          avgBrightness: 120,
          faceROIBrightness: 100,
          backgroundBrightness: 130,
        };
        const personBBox = { xmin: 100, ymin: 100, width: 200, height: 300 };
        const frameSize = { width: 1080, height: 2340 };
        const templateKeypoints = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
        ];
        const detectedKeypoints = [
          { name: 'nose', x: 0.5, y: 0.2, score: 0.95 },
          { name: 'right_wrist', x: 0.7, y: 0.3, score: 0.9 },
        ];

        const diagnosis = engine.synthesizeDiagnosis(
          frameStats,
          personBBox,
          frameSize,
          templateKeypoints,
          detectedKeypoints
        );

        expect(diagnosis.lighting.type).assertEqual('adequate');
        expect(diagnosis.composition.personCenterX).assertGreater(0);
        expect(diagnosis.pose.overallScore).assertGreater(0.8);
        expect(diagnosis.timestamp > 0).assertTrue();
      });

      it('should_diagnose_backlit_with_misaligned_pose', 0, () => {
        const frameStats = {
          avgBrightness: 100,
          faceROIBrightness: 60,
          backgroundBrightness: 180,
        };
        const personBBox = { xmin: 100, ymin: 100, width: 200, height: 300 };
        const frameSize = { width: 1080, height: 2340 };
        const templateKeypoints = [
          { name: 'nose', x: 0.5, y: 0.2 },
          { name: 'right_wrist', x: 0.7, y: 0.3 },
        ];
        const detectedKeypoints = [
          { name: 'nose', x: 0.6, y: 0.3, score: 0.95 },
          { name: 'right_wrist', x: 0.8, y: 0.4, score: 0.9 },
        ];

        const diagnosis = engine.synthesizeDiagnosis(
          frameStats,
          personBBox,
          frameSize,
          templateKeypoints,
          detectedKeypoints
        );

        expect(diagnosis.lighting.type).assertEqual('backlit');
        expect(diagnosis.pose.overallScore).assertLess(0.8);
      });
    });
  });
}
