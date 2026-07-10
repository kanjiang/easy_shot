import { util } from '@kit.ArkTS';
import { describe, expect, it } from '@ohos/hypium';

import {
  CameraFacing,
  Difficulty,
  PoseTemplate,
  ShotType,
  parsePoseTemplate,
} from '../../../main/ets/features/poseTemplate/model/PoseTemplate';
import { PoseTemplateRepository } from '../../../main/ets/features/poseTemplate/data/PoseTemplateRepository';
import { RawfilePoseTemplateRepository } from '../../../main/ets/features/poseTemplate/data/RawfilePoseTemplateRepository';
import { RawfileResourceManagerLike } from '../../../main/ets/features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplateStore } from '../../../main/ets/features/poseTemplate/state/PoseTemplateStore';
import { CustomPoseTemplateStorage } from '../../../main/ets/features/poseTemplate/state/CustomPoseTemplateStorage';

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

class FakeCustomPoseTemplateStorage implements CustomPoseTemplateStorage {
  private templates: PoseTemplate[];

  constructor(templates: PoseTemplate[] = []) {
    this.templates = [...templates];
  }

  loadTemplates(): PoseTemplate[] {
    return [...this.templates];
  }

  saveTemplate(_context: Object, template: PoseTemplate): PoseTemplate[] {
    this.templates = [template, ...this.templates.filter((item: PoseTemplate) => item.id !== template.id)];
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

class FakeRawfileResourceManager implements RawfileResourceManagerLike {
  constructor(private readonly contents: Record<string, string>) {
  }

  getRawFd(): never {
    throw new Error('getRawFd should not be used in this test');
  }

  getRawFileContentSync(path: string): Uint8Array {
    const content: string | undefined = this.contents[path];
    if (content === undefined) {
      throw new Error('Missing rawfile: ' + path);
    }
    const encoder = new util.TextEncoder('utf-8');
    return encoder.encodeInto(content);
  }
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

    it('merges custom templates ahead of rawfile templates', 0, () => {
      const rawTemplate: PoseTemplate = parsePoseTemplate(createTemplateJson());
      const customTemplate: PoseTemplate = {
        ...rawTemplate,
        id: 'custom_test_template',
        title: '我的模板',
      };
      const repository: PoseTemplateRepository = new FakePoseTemplateRepository([rawTemplate]);
      const customStorage: CustomPoseTemplateStorage = new FakeCustomPoseTemplateStorage([customTemplate]);
      const store: PoseTemplateStore = new PoseTemplateStore(repository, customStorage);

      const state = store.loadTemplatesFromRawfile({} as Object as never, {} as Object as never);

      expect(state.templates.length).assertEqual(2);
      expect(state.templates[0].id).assertEqual('custom_test_template');
      expect(state.templates[1].id).assertEqual('pose_sweet_scissors_cheek_v1');
    });

    it('addCustomTemplate selects saved custom template', 0, () => {
      const rawTemplate: PoseTemplate = parsePoseTemplate(createTemplateJson());
      const customTemplate: PoseTemplate = {
        ...rawTemplate,
        id: 'custom_saved_template',
        title: '保存后的模板',
      };
      const repository: PoseTemplateRepository = new FakePoseTemplateRepository([rawTemplate]);
      const customStorage: CustomPoseTemplateStorage = new FakeCustomPoseTemplateStorage();
      const store: PoseTemplateStore = new PoseTemplateStore(repository, customStorage);

      store.loadTemplatesFromRawfile({} as Object as never, {} as Object as never);
      const state = store.addCustomTemplate({} as Object as never, customTemplate);

      expect(state.templates.length).assertEqual(2);
      expect(state.featuredTemplate?.id).assertEqual('custom_saved_template');
      expect(state.selectedTemplateId).assertEqual('custom_saved_template');
    });

    it('selectTemplate can select a custom template already merged into state', 0, () => {
      const rawTemplate: PoseTemplate = parsePoseTemplate(createTemplateJson());
      const customTemplate: PoseTemplate = {
        ...rawTemplate,
        id: 'custom_selectable_template',
        title: '可选中的自定义模板',
      };
      const repository: PoseTemplateRepository = new FakePoseTemplateRepository([rawTemplate]);
      const customStorage: CustomPoseTemplateStorage = new FakeCustomPoseTemplateStorage([customTemplate]);
      const store: PoseTemplateStore = new PoseTemplateStore(repository, customStorage);

      store.loadTemplatesFromRawfile({} as Object as never, {} as Object as never);
      const state = store.selectTemplate('custom_selectable_template');

      expect(state.featuredTemplate?.id).assertEqual('custom_selectable_template');
      expect(state.selectedTemplateId).assertEqual('custom_selectable_template');
    });

    it('downgrades missing avatar rawfile to empty string during repository load', 0, () => {
      const repository = new RawfilePoseTemplateRepository();
      const resourceManager = new FakeRawfileResourceManager({
        'templates/manifest.json': JSON.stringify({ templates: ['pose.json'] }),
        'templates/pose.json': JSON.stringify(createTemplateJson()),
      });

      const templates = repository.loadTemplatesFromRawfile(resourceManager);

      expect(templates.length).assertEqual(1);
      expect(templates[0].avatarImage).assertEqual('');
    });
  });
}
