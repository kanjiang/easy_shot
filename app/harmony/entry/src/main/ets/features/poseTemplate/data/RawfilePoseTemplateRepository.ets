import { util } from '@kit.ArkTS';
import { fileIo as fs } from '@kit.CoreFileKit';

import { PoseTemplate, parsePoseTemplate } from '../model/PoseTemplate';
import { PoseTemplateRepository, RawFileDescriptorLike, RawfileResourceManagerLike } from './PoseTemplateRepository';

interface TemplateManifest {
  templates: string[];
}

export class RawfilePoseTemplateRepository implements PoseTemplateRepository {
  private templates: PoseTemplate[] = [];

  constructor() {
  }

  listTemplates(): PoseTemplate[] {
    return [...this.templates];
  }

  getTemplateById(templateId: string): PoseTemplate | null {
    const matchedTemplate: PoseTemplate | undefined = this.templates.find((template: PoseTemplate) => template.id === templateId);
    return matchedTemplate ? matchedTemplate : null;
  }

  loadTemplatesFromRawfile(resourceManager: RawfileResourceManagerLike): PoseTemplate[] {
    const manifestContent: string = this.readRawfileText(resourceManager, 'templates/manifest.json');
    const manifest: TemplateManifest = JSON.parse(manifestContent) as TemplateManifest;
    this.templates = manifest.templates.map((templateFileName: string) => this.parseTemplate(resourceManager, templateFileName));
    return [...this.templates];
  }

  private parseTemplate(resourceManager: RawfileResourceManagerLike, templateFileName: string): PoseTemplate {
    const templateContent: string = this.readRawfileText(resourceManager, 'templates/' + templateFileName);
    const parsedContent: Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>> =
      JSON.parse(templateContent) as Record<string, Object | string | number | boolean | Array<Object | string | number | boolean>>;
    const template: PoseTemplate = parsePoseTemplate(parsedContent);
    return {
      ...template,
      avatarImage: this.resolveAvatarImage(resourceManager, template.avatarImage),
    };
  }

  private readRawfileText(resourceManager: RawfileResourceManagerLike, rawfilePath: string): string {
    if (typeof resourceManager.getRawFileContentSync === 'function') {
      const decoder = new util.TextDecoder('utf-8');
      return decoder.decodeToString(resourceManager.getRawFileContentSync(rawfilePath));
    }

    const rawFileDescriptor: RawFileDescriptorLike = resourceManager.getRawFd(rawfilePath);
    const buffer: ArrayBuffer = new ArrayBuffer(rawFileDescriptor.length);
    const readLength: number = fs.readSync(rawFileDescriptor.fd, buffer, {
      offset: 0,
      length: rawFileDescriptor.length,
      position: rawFileDescriptor.offset,
    });
    fs.closeSync(rawFileDescriptor.fd);

    const byteView: Uint8Array = new Uint8Array(buffer.slice(0, readLength));
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decodeToString(byteView);
  }

  private resolveAvatarImage(resourceManager: RawfileResourceManagerLike, avatarImage: string): string {
    if (avatarImage.length === 0) {
      return '';
    }

    try {
      if (typeof resourceManager.getRawFileContentSync === 'function') {
        resourceManager.getRawFileContentSync(avatarImage);
        return avatarImage;
      }

      const rawFileDescriptor: RawFileDescriptorLike = resourceManager.getRawFd(avatarImage);
      fs.closeSync(rawFileDescriptor.fd);
      return avatarImage;
    } catch (_error) {
      return '';
    }
  }
}
