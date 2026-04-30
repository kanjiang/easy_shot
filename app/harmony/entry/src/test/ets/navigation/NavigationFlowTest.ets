import { describe, expect, it } from '@ohos/hypium';

import { PoseTemplate, parsePoseTemplate } from '../../../main/ets/features/poseTemplate/model/PoseTemplate';
import { PoseTemplateRepository } from '../../../main/ets/features/poseTemplate/data/PoseTemplateRepository';
import { PoseTemplateStore, PoseTemplateState } from '../../../main/ets/features/poseTemplate/state/PoseTemplateStore';

class NavigationFakeRepo implements PoseTemplateRepository {
  constructor(private readonly templates: PoseTemplate[]) {
  }

  listTemplates(): PoseTemplate[] {
    return [...this.templates];
  }

  getTemplateById(templateId: string): PoseTemplate | null {
    const matched: PoseTemplate | undefined = this.templates.find((t: PoseTemplate) => t.id === templateId);
    return matched ? matched : null;
  }

  loadTemplatesFromRawfile(): PoseTemplate[] {
    return [...this.templates];
  }
}

function makeTemplate(
  id: string,
  title: string,
): PoseTemplate {
  return parsePoseTemplate({
    id,
    title,
    style_tags: ['sweet_daily'],
    scene_tags: ['室内'],
    shot_type: 'half_body',
    camera_facing: 'front_or_rear',
    difficulty: 'easy',
    description: 'Test template for ' + title,
    verbal_steps: ['Step 1'],
    avatar_image: 'avatars/test.png',
    annotations: [{ label: 'label', anchor: { x: 0.5, y: 0.5 } }],
    skeleton: { tolerance: 0.1, keypoints: [{ name: 'nose', x: 0.5, y: 0.2 }] },
  });
}

export default function navigationFlowTest(): void {
  describe('NavigationFlow', () => {
    it('selectTemplate switches featured template for CameraGuide params', 0, () => {
      const templateA: PoseTemplate = makeTemplate('pose_a', 'Template A');
      const templateB: PoseTemplate = makeTemplate('pose_b', 'Template B');
      const store: PoseTemplateStore = new PoseTemplateStore(new NavigationFakeRepo([templateA, templateB]));
      store.loadTemplates();

      const state: PoseTemplateState = store.selectTemplate('pose_b');

      expect(state.selectedTemplateId).assertEqual('pose_b');
      expect(state.featuredTemplate !== null).assertTrue();
      expect(state.featuredTemplate?.id).assertEqual('pose_b');
      expect(state.featuredTemplate?.title).assertEqual('Template B');
    });

    it('selectTemplate with invalid ID keeps current state unchanged', 0, () => {
      const template: PoseTemplate = makeTemplate('pose_valid', 'Valid Template');
      const store: PoseTemplateStore = new PoseTemplateStore(new NavigationFakeRepo([template]));
      store.loadTemplates();

      const state: PoseTemplateState = store.selectTemplate('nonexistent_id');

      expect(state.selectedTemplateId).assertEqual('pose_valid');
      expect(state.featuredTemplate !== null).assertTrue();
      expect(state.featuredTemplate?.id).assertEqual('pose_valid');
      expect(state.templates.length).assertEqual(1);
    });

    it('selectTemplate on empty store does not crash', 0, () => {
      const store: PoseTemplateStore = new PoseTemplateStore(new NavigationFakeRepo([]));
      store.loadTemplates();

      const state: PoseTemplateState = store.selectTemplate('any_id');

      expect(state.templates.length).assertEqual(0);
      expect(state.selectedTemplateId).assertEqual('');
      expect(state.featuredTemplate === null).assertTrue();
    });
  });
}
