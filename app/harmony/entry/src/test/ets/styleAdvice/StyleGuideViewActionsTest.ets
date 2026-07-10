import { describe, expect, it } from '@ohos/hypium';

import {
  formatStyleGuideMatchedKeywords,
  formatStyleGuideTemplateTags,
  matchesStyleGuideTagQuery,
  searchStyleGuideTemplates,
} from '../../../main/ets/features/poseTemplate/state/StyleGuideViewActions';
import {
  CameraFacing,
  Difficulty,
  PoseTemplate,
  ShotType,
} from '../../../main/ets/features/poseTemplate/model/PoseTemplate';

function createTemplate(
  id: string,
  title: string,
  styleTags: string[],
  sceneTags: string[],
  description: string,
): PoseTemplate {
  return {
    id,
    title,
    styleTags,
    sceneTags,
    shotType: ShotType.FULL_BODY,
    cameraFacing: CameraFacing.FRONT,
    difficulty: Difficulty.EASY,
    description,
    verbalSteps: [],
    avatarImage: '',
    annotations: [],
    skeleton: {
      tolerance: 0.1,
      keypoints: [],
    },
  };
}

function resolveStyleLabel(styleValue: string): string {
  switch (styleValue) {
    case 'sweet_daily':
      return 'Sweet Daily';
    case 'cool_street':
      return 'Cool Street';
    case 'campus_vibes':
      return 'Campus Vibes';
    case 'travel_mood':
      return 'Travel Mood';
    default:
      return styleValue;
  }
}

export default function styleGuideViewActionsTest(): void {
  describe('StyleGuideViewActionsTest', () => {
    it('matches style guide query against both raw tags and localized labels', 0, () => {
      expect(matchesStyleGuideTagQuery('sweet', 'sweet_daily', resolveStyleLabel)).assertTrue();
      expect(matchesStyleGuideTagQuery('street', 'cool_street', resolveStyleLabel)).assertTrue();
      expect(matchesStyleGuideTagQuery('travel', 'campus_vibes', resolveStyleLabel)).assertFalse();
    });

    it('formats matched keywords with localized labels in original order', 0, () => {
      const formatted = formatStyleGuideMatchedKeywords(
        ['sweet_daily', 'cool_street', 'campus_vibes'],
        resolveStyleLabel,
      );

      expect(formatted).assertEqual('Sweet Daily / Cool Street / Campus Vibes');
    });

    it('formats template tags with localized style labels and scene tags', 0, () => {
      const formatted = formatStyleGuideTemplateTags(
        createTemplate('a', 'Template A', ['sweet_daily', 'cool_street'], ['campus', 'night'], 'desc'),
        resolveStyleLabel,
      );

      expect(formatted).assertEqual('Sweet Daily · Cool Street · campus · night');
    });

    it('returns empty style guide search results for blank queries', 0, () => {
      const result = searchStyleGuideTemplates('   ', [
        createTemplate('a', 'Template A', ['sweet_daily'], ['campus'], 'desc'),
      ], resolveStyleLabel);

      expect(result.matchedTags.length).assertEqual(0);
      expect(result.matchedTemplates.length).assertEqual(0);
    });

    it('deduplicates matched tags and limits them to the first three discovered', 0, () => {
      const result = searchStyleGuideTemplates('a', [
        createTemplate('a', 'Template A', ['sweet_daily', 'campus_vibes'], ['campus'], 'desc'),
        createTemplate('b', 'Template B', ['travel_mood', 'campus_vibes'], ['arcade'], 'desc'),
        createTemplate('c', 'Template C', ['cool_street'], ['garden'], 'desc'),
      ], resolveStyleLabel);

      expect(result.matchedTags.length).assertEqual(3);
      expect(result.matchedTags[0]).assertEqual('sweet_daily');
      expect(result.matchedTags[1]).assertEqual('campus_vibes');
      expect(result.matchedTags[2]).assertEqual('travel_mood');
    });

    it('matches templates by localized style labels, scene tags, titles, and descriptions', 0, () => {
      const templates = [
        createTemplate('a', 'Template A', ['sweet_daily'], ['campus'], 'Sunny portrait walk'),
        createTemplate('b', 'Night Street Mood', ['cool_street'], ['city'], 'Urban motion blur'),
        createTemplate('c', 'Template C', ['travel_mood'], ['beach'], 'Sunset postcard framing'),
      ];

      const localizedStyleResult = searchStyleGuideTemplates('sweet', templates, resolveStyleLabel);
      const titleResult = searchStyleGuideTemplates('night', templates, resolveStyleLabel);
      const descriptionResult = searchStyleGuideTemplates('postcard', templates, resolveStyleLabel);
      const sceneResult = searchStyleGuideTemplates('beach', templates, resolveStyleLabel);

      expect(localizedStyleResult.matchedTemplates.length).assertEqual(1);
      expect(localizedStyleResult.matchedTemplates[0].id).assertEqual('a');
      expect(titleResult.matchedTemplates[0].id).assertEqual('b');
      expect(descriptionResult.matchedTemplates[0].id).assertEqual('c');
      expect(sceneResult.matchedTemplates[0].id).assertEqual('c');
    });
  });
}
