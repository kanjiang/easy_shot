import { describe, expect, it } from '@ohos/hypium';

import { buildIndexFilterOptions, filterIndexTemplates } from '../../../main/ets/features/poseTemplate/state/IndexViewActions';
import {
  CameraFacing,
  Difficulty,
  PoseTemplate,
  ShotType,
} from '../../../main/ets/features/poseTemplate/model/PoseTemplate';

const ALL_FILTER: string = 'all';

function createTemplate(
  id: string,
  styleTags: string[],
  sceneTags: string[],
  difficulty: Difficulty,
): PoseTemplate {
  return {
    id,
    title: `Template ${id}`,
    styleTags,
    sceneTags,
    shotType: ShotType.FULL_BODY,
    cameraFacing: CameraFacing.FRONT,
    difficulty,
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

export default function indexViewActionsTest(): void {
  describe('IndexViewActionsTest', () => {
    it('builds deduplicated filter options while preserving discovery order', 0, () => {
      const options = buildIndexFilterOptions([
        createTemplate('a', ['sweet', 'fresh'], ['campus'], Difficulty.EASY),
        createTemplate('b', ['fresh', 'street'], ['night', 'campus'], Difficulty.MEDIUM),
      ]);

      expect(options.styles.length).assertEqual(3);
      expect(options.styles[0]).assertEqual('sweet');
      expect(options.styles[1]).assertEqual('fresh');
      expect(options.styles[2]).assertEqual('street');
      expect(options.scenes.length).assertEqual(2);
      expect(options.scenes[0]).assertEqual('campus');
      expect(options.scenes[1]).assertEqual('night');
    });

    it('returns every template when all filters are selected', 0, () => {
      const templates = [
        createTemplate('a', ['sweet'], ['campus'], Difficulty.EASY),
        createTemplate('b', ['street'], ['night'], Difficulty.HARD),
      ];

      const filtered = filterIndexTemplates(templates, ALL_FILTER, ALL_FILTER, ALL_FILTER, ALL_FILTER);

      expect(filtered.length).assertEqual(2);
    });

    it('filters templates by style and scene together', 0, () => {
      const templates = [
        createTemplate('a', ['sweet'], ['campus'], Difficulty.EASY),
        createTemplate('b', ['sweet'], ['night'], Difficulty.MEDIUM),
        createTemplate('c', ['street'], ['campus'], Difficulty.EASY),
      ];

      const filtered = filterIndexTemplates(templates, 'sweet', 'campus', ALL_FILTER, ALL_FILTER);

      expect(filtered.length).assertEqual(1);
      expect(filtered[0].id).assertEqual('a');
    });

    it('filters templates by difficulty', 0, () => {
      const templates = [
        createTemplate('a', ['sweet'], ['campus'], Difficulty.EASY),
        createTemplate('b', ['sweet'], ['campus'], Difficulty.HARD),
      ];

      const filtered = filterIndexTemplates(templates, ALL_FILTER, ALL_FILTER, Difficulty.HARD, ALL_FILTER);

      expect(filtered.length).assertEqual(1);
      expect(filtered[0].id).assertEqual('b');
    });

    it('returns an empty list when filters do not match any template', 0, () => {
      const templates = [
        createTemplate('a', ['sweet'], ['campus'], Difficulty.EASY),
      ];

      const filtered = filterIndexTemplates(templates, 'street', 'night', Difficulty.HARD, ALL_FILTER);

      expect(filtered.length).assertEqual(0);
    });
  });
}
