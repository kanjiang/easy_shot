import { describe, expect, it } from '@ohos/hypium';

import {
  CameraFacing,
  Difficulty,
  PoseTemplate,
  ShotType,
  parsePoseTemplate,
} from '../../../main/ets/features/poseTemplate/model/PoseTemplate';
import { PoseTemplateRepository } from '../../../main/ets/features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplateStore } from '../../../main/ets/features/poseTemplate/state/PoseTemplateStore';

class FakePoseTemplateRepository implements PoseTemplateRepository {
  constructor(private readonly templates: PoseTemplate[]) {
  }

  listTemplates(): PoseTemplate[] {
    return [...this.templates];
  }

  getTemplateById(templateId: string): PoseTemplate | null {
    const matchedTemplate: PoseTemplate | undefined = this.templates.find((template: PoseTemplate) => template.id === templateId);
    return matchedTemplate ? matchedTemplate : null;
  }

  loadTemplatesFromRawfile(): PoseTemplate[] {
    return [...this.templates];
  }
}

function createTemplateJson(): Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>> {
  return {
    id: 'pose_sweet_scissors_cheek_v1',
    title: '剪刀手脸颊边',
    style_tags: ['sweet_daily'],
    scene_tags: ['室内', '咖啡店'],
    shot_type: 'half_body',
    camera_facing: 'front_or_rear',
    difficulty: 'easy',
    description: '右手剪刀手放在右脸颊旁。',
    verbal_steps: ['身体侧 15° 朝镜头', '右手贴脸颊'],
    avatar_image: 'avatars/sweet/scissors_cheek_v1.png',
    annotations: [
      {
        label: '剪刀手贴脸颊',
        anchor: { x: 0.74, y: 0.18 },
      },
    ],
    skeleton: {
      tolerance: 0.08,
      keypoints: [
        {
          name: 'nose',
          x: 0.5,
          y: 0.2,
        },
      ],
    },
  };
}

export default function poseTemplateTest(): void {
  describe('PoseTemplate', () => {
    it('parses required fields from valid JSON', 0, () => {
      const parsedTemplate: PoseTemplate = parsePoseTemplate(createTemplateJson());

      expect(parsedTemplate.id).assertEqual('pose_sweet_scissors_cheek_v1');
      expect(parsedTemplate.styleTags[0]).assertEqual('sweet_daily');
      expect(parsedTemplate.shotType).assertEqual(ShotType.HALF_BODY);
      expect(parsedTemplate.cameraFacing).assertEqual(CameraFacing.FRONT_OR_REAR);
      expect(parsedTemplate.difficulty).assertEqual(Difficulty.EASY);
      expect(parsedTemplate.verbalSteps.length).assertEqual(2);
      expect(parsedTemplate.annotations[0].anchor.x).assertEqual(0.74);
      expect(parsedTemplate.skeleton.keypoints[0].name).assertEqual('nose');
    });

    it('throws when required field missing', 0, () => {
      let threw: boolean = false;
      try {
        parsePoseTemplate({ id: 'only_id' });
      } catch (_error) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('loads store state from repository data', 0, () => {
      const repository: PoseTemplateRepository = new FakePoseTemplateRepository([parsePoseTemplate(createTemplateJson())]);
      const store: PoseTemplateStore = new PoseTemplateStore(repository);
      const state = store.loadTemplates();

      expect(state.templates.length).assertEqual(1);
      expect(state.featuredTemplate?.id).assertEqual('pose_sweet_scissors_cheek_v1');
      expect(state.selectedTemplateId).assertEqual('pose_sweet_scissors_cheek_v1');
    });
  });
}
