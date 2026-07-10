import { describe, expect, it } from '@ohos/hypium';

import { PreviewMode } from '../../../main/ets/core/session/SessionState';
import {
  buildCompanionPreviewSyncParams,
  deriveCompanionPreviewHintKind,
} from '../../../main/ets/features/companion/CompanionSessionPreviewActions';
import {
  CameraFacing,
  Difficulty,
  PoseTemplate,
  ShotType,
} from '../../../main/ets/features/poseTemplate/model/PoseTemplate';

function createTemplate(id: string): PoseTemplate {
  return {
    id,
    title: `Template ${id}`,
    styleTags: [],
    sceneTags: [],
    shotType: ShotType.FULL_BODY,
    cameraFacing: CameraFacing.FRONT,
    difficulty: Difficulty.EASY,
    description: '',
    verbalSteps: [],
    avatarImage: '',
    annotations: [],
    skeleton: {
      tolerance: 0.1,
      keypoints: [],
    },
  };
}

export default function companionSessionPreviewActionsTest(): void {
  describe('CompanionSessionPreviewActionsTest', () => {
    it('maps preview modes to the expected toast hint kinds', 0, () => {
      expect(deriveCompanionPreviewHintKind(PreviewMode.LIVE)).assertEqual('none');
      expect(deriveCompanionPreviewHintKind(PreviewMode.THUMBNAIL)).assertEqual('thumbnail');
      expect(deriveCompanionPreviewHintKind(PreviewMode.STATE_ONLY)).assertEqual('state_only');
    });

    it('prefers the selected template when opening CameraGuide for preview sync', 0, () => {
      const params = buildCompanionPreviewSyncParams(
        1,
        [createTemplate('template-a'), createTemplate('template-b')],
        'snapshot-template',
      );

      expect(params.templateId).assertEqual('template-b');
    });

    it('falls back to the first template when selected index is out of range', 0, () => {
      const params = buildCompanionPreviewSyncParams(
        5,
        [createTemplate('template-a')],
        'snapshot-template',
      );

      expect(params.templateId).assertEqual('template-a');
    });

    it('falls back to guide state template id when local templates are unavailable', 0, () => {
      const params = buildCompanionPreviewSyncParams(0, [], 'snapshot-template');

      expect(params.templateId).assertEqual('snapshot-template');
    });

    it('returns empty params when no template is available anywhere', 0, () => {
      const params = buildCompanionPreviewSyncParams(0, [], 'unselected');

      expect(Object.keys(params).length).assertEqual(0);
    });
  });
}
