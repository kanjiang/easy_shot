import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

import { PoseTemplate } from '../model/PoseTemplate';

const CUSTOM_TEMPLATE_PREFS_NAME: string = 'easy_shot_custom_templates';
const CUSTOM_TEMPLATE_KEY: string = 'templates';

export interface CustomPoseTemplateStorage {
  loadTemplates(context: Context): PoseTemplate[];
  saveTemplate(context: Context, template: PoseTemplate): PoseTemplate[];
}

export class PreferencesCustomPoseTemplateStorage implements CustomPoseTemplateStorage {
  loadTemplates(context: Context): PoseTemplate[] {
    const prefs: preferences.Preferences = preferences.getPreferencesSync(context, { name: CUSTOM_TEMPLATE_PREFS_NAME });
    const raw: string = prefs.getSync(CUSTOM_TEMPLATE_KEY, '[]') as string;

    try {
      const parsed: PoseTemplate[] = JSON.parse(raw) as PoseTemplate[];
      return Array.isArray(parsed) ? parsed : [];
    } catch (_error) {
      return [];
    }
  }

  saveTemplate(context: Context, template: PoseTemplate): PoseTemplate[] {
    const prefs: preferences.Preferences = preferences.getPreferencesSync(context, { name: CUSTOM_TEMPLATE_PREFS_NAME });
    const templates: PoseTemplate[] = this.loadTemplates(context)
      .filter((item: PoseTemplate) => item.id !== template.id);
    templates.unshift(template);

    prefs.putSync(CUSTOM_TEMPLATE_KEY, JSON.stringify(templates));
    prefs.flush((err) => {
      if (err) {
        console.error('CustomPoseTemplateStorage: flush failed with code ' + err.code);
      }
    });

    return [...templates];
  }
}
