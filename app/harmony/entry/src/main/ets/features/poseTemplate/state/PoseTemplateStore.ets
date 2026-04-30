import { PoseTemplate } from '../model/PoseTemplate';
import { RawfilePoseTemplateRepository } from '../data/RawfilePoseTemplateRepository';
import { PoseTemplateRepository, RawfileResourceManagerLike } from '../data/PoseTemplateRepository';

export interface PoseTemplateState {
  templates: PoseTemplate[];
  featuredTemplate: PoseTemplate | null;
  selectedTemplateId: string;
}

export class PoseTemplateStore {
  private readonly repository: PoseTemplateRepository;
  private state: PoseTemplateState = {
    templates: [],
    featuredTemplate: null,
    selectedTemplateId: '',
  };

  constructor(repository: PoseTemplateRepository = new RawfilePoseTemplateRepository()) {
    this.repository = repository;
  }

  loadTemplates(): PoseTemplateState {
    return this.setTemplates(this.repository.listTemplates());
  }

  loadTemplatesFromRawfile(resourceManager: RawfileResourceManagerLike): PoseTemplateState {
    try {
      const templates: PoseTemplate[] = this.repository.loadTemplatesFromRawfile(resourceManager);
      return this.setTemplates(templates);
    } catch (_error) {
      return this.loadTemplates();
    }
  }

  private setTemplates(templates: PoseTemplate[]): PoseTemplateState {
    const featuredTemplate: PoseTemplate | null = templates.length > 0 ? templates[0] : null;
    this.state = {
      templates,
      featuredTemplate,
      selectedTemplateId: featuredTemplate ? featuredTemplate.id : '',
    };
    return this.getState();
  }

  selectTemplate(templateId: string): PoseTemplateState {
    const selectedTemplate: PoseTemplate | null = this.repository.getTemplateById(templateId);
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
}

export const poseTemplateStore: PoseTemplateStore = new PoseTemplateStore();
