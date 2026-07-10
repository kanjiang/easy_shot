import { PoseTemplate } from '../model/PoseTemplate';

export interface RawFileDescriptorLike {
  fd: number;
  offset: number;
  length: number;
}

export interface RawfileResourceManagerLike {
  getRawFd(path: string): RawFileDescriptorLike;
  getRawFileContentSync?(path: string): Uint8Array;
}

export interface PoseTemplateRepository {
  listTemplates(): PoseTemplate[];
  getTemplateById(templateId: string): PoseTemplate | null;
  loadTemplatesFromRawfile(resourceManager: RawfileResourceManagerLike): PoseTemplate[];
}
