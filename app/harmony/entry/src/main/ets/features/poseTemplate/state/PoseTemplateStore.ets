import { Context } from '@kit.AbilityKit';

import { PoseTemplate } from '../model/PoseTemplate';
import { RawfilePoseTemplateRepository } from '../data/RawfilePoseTemplateRepository';
import { PoseTemplateRepository, RawfileResourceManagerLike } from '../data/PoseTemplateRepository';
import {
  CustomPoseTemplateStorage,
  PreferencesCustomPoseTemplateStorage,
} from './CustomPoseTemplateStorage';

export interface PoseTemplateState {
  templates: PoseTemplate[];
  featuredTemplate: PoseTemplate | null;
  selectedTemplateId: string;
}

export class PoseTemplateStore {
  private readonly repository: PoseTemplateRepository;
  private readonly customTemplateStorage: CustomPoseTemplateStorage;
  private state: PoseTemplateState = {
    templates: [],
    featuredTemplate: null,
    selectedTemplateId: '',
  };

  constructor(
    repository: PoseTemplateRepository = new RawfilePoseTemplateRepository(),
    customTemplateStorage: CustomPoseTemplateStorage = new PreferencesCustomPoseTemplateStorage(),
  ) {
    this.repository = repository;
    this.customTemplateStorage = customTemplateStorage;
  }

  loadTemplates(): PoseTemplateState {
    return this.setTemplates(this.repository.listTemplates());
  }

  loadTemplatesFromRawfile(resourceManager: RawfileResourceManagerLike, context?: Context): PoseTemplateState {
    try {
      const templates: PoseTemplate[] = this.repository.loadTemplatesFromRawfile(resourceManager);
      return this.setTemplates(this.mergeTemplates(templates, this.loadCustomTemplates(context)));
    } catch (_error) {
      return this.setTemplates(this.mergeTemplates(this.repository.listTemplates(), this.loadCustomTemplates(context)));
    }
  }

  addCustomTemplate(context: Context, template: PoseTemplate): PoseTemplateState {
    const customTemplates: PoseTemplate[] = this.customTemplateStorage.saveTemplate(context, template);
    const baseTemplates: PoseTemplate[] = this.repository.listTemplates().length > 0
      ? this.repository.listTemplates()
      : this.state.templates.filter((item: PoseTemplate) => !this.isCustomTemplate(item.id));
    return this.setTemplates(this.mergeTemplates(baseTemplates, customTemplates), template.id);
  }

  private setTemplates(templates: PoseTemplate[], preferredTemplateId: string = this.state.selectedTemplateId): PoseTemplateState {
    const featuredTemplate: PoseTemplate | null = templates.find((template: PoseTemplate) => template.id === preferredTemplateId)
      ?? (templates.length > 0 ? templates[0] : null);
    this.state = {
      templates,
      featuredTemplate,
      selectedTemplateId: featuredTemplate ? featuredTemplate.id : '',
    };
    return this.getState();
  }

  selectTemplate(templateId: string): PoseTemplateState {
    const selectedTemplate: PoseTemplate | null = this.repository.getTemplateById(templateId)
      ?? this.state.templates.find((template: PoseTemplate) => template.id === templateId)
      ?? null;
    if (!selectedTemplate) {
      return this.getState();
    }

    this.state = {
      templates: [...this.state.templates],
      featuredTemplate: selectedTemplate,
      selectedTemplateId: selectedTemplate.id,
    };
    return this.getState();
  }

  getState(): PoseTemplateState {
    return {
      templates: [...this.state.templates],
      featuredTemplate: this.state.featuredTemplate,
      selectedTemplateId: this.state.selectedTemplateId,
    };
  }

  private loadCustomTemplates(context?: Context): PoseTemplate[] {
    if (context === undefined) {
      return this.state.templates.filter((template: PoseTemplate) => this.isCustomTemplate(template.id));
    }

    return this.customTemplateStorage.loadTemplates(context);
  }

  private mergeTemplates(baseTemplates: PoseTemplate[], customTemplates: PoseTemplate[]): PoseTemplate[] {
    const merged: PoseTemplate[] = [];
    const seenIds: Set<string> = new Set<string>();

    for (const template of [...customTemplates, ...baseTemplates]) {
      if (!seenIds.has(template.id)) {
        seenIds.add(template.id);
        merged.push(template);
      }
    }

    return merged;
  }

  private isCustomTemplate(templateId: string): boolean {
    return templateId.startsWith('custom_');
  }
}

export const poseTemplateStore: PoseTemplateStore = new PoseTemplateStore();
