import { util } from '@kit.ArkTS';

import { RawfileResourceManagerLike } from '../poseTemplate/data/PoseTemplateRepository';
import {
  isCloudStyleAdviceApiBaseConfigured,
  normalizeCloudStyleAdviceApiBase,
} from '../styleAdvice/StyleAdviceConfig';

const MODEL_MANIFEST_RAW_PATH: string = 'models/manifest.json';
const DEFAULT_MODEL_RAW_PATH: string = 'models/pose_estimation.ms';
const STYLE_ADVICE_MANIFEST_RAW_PATH: string = 'style_advice/manifest.json';
const TEMPLATE_MANIFEST_RAW_PATH: string = 'templates/manifest.json';
const AUDIO_CUE_RAWFILES: string[] = [
  'audio/shutter.ogg',
  'audio/countdown_tick.ogg',
  'audio/countdown_end.ogg',
];

interface ModelManifest {
  rawfilePath?: string;
}

interface StyleAdviceManifest {
  apiBase?: string;
}

interface TemplateManifest {
  templates?: string[];
}

export interface RuntimeResourceReadinessStatus {
  expectedModelPath: string;
  mindSporeModelAvailable: boolean;
  cloudAdviceApiBase: string;
  cloudAdviceApiConfigured: boolean;
  totalAudioCueCount: number;
  missingAudioCueCount: number;
  missingAudioCuePaths: string[];
  referencedAvatarCount: number;
  missingAvatarCount: number;
  missingAvatarPaths: string[];
}

export function createDefaultRuntimeResourceReadinessStatus(): RuntimeResourceReadinessStatus {
  return {
    expectedModelPath: DEFAULT_MODEL_RAW_PATH,
    mindSporeModelAvailable: false,
    cloudAdviceApiBase: '',
    cloudAdviceApiConfigured: false,
    totalAudioCueCount: AUDIO_CUE_RAWFILES.length,
    missingAudioCueCount: AUDIO_CUE_RAWFILES.length,
    missingAudioCuePaths: [...AUDIO_CUE_RAWFILES],
    referencedAvatarCount: 0,
    missingAvatarCount: 0,
    missingAvatarPaths: [],
  };
}

export function inspectRuntimeResourceReadiness(
  resourceManager: RawfileResourceManagerLike,
): RuntimeResourceReadinessStatus {
  const modelManifest: ModelManifest = readRawfileJson<ModelManifest>(resourceManager, MODEL_MANIFEST_RAW_PATH);
  const modelPath: string = typeof modelManifest.rawfilePath === 'string' && modelManifest.rawfilePath.trim().length > 0
    ? modelManifest.rawfilePath.trim()
    : DEFAULT_MODEL_RAW_PATH;

  const styleAdviceManifest: StyleAdviceManifest = readRawfileJson<StyleAdviceManifest>(
    resourceManager,
    STYLE_ADVICE_MANIFEST_RAW_PATH,
  );
  const apiBase: string = normalizeCloudStyleAdviceApiBase(
    typeof styleAdviceManifest.apiBase === 'string' ? styleAdviceManifest.apiBase : '',
  );

  const avatarPaths: string[] = collectAvatarPaths(resourceManager);
  const missingAvatarPaths: string[] = avatarPaths.filter((path: string) => !hasRawfile(resourceManager, path));
  const missingAudioCuePaths: string[] = AUDIO_CUE_RAWFILES.filter((path: string) => !hasRawfile(resourceManager, path));

  return {
    expectedModelPath: modelPath,
    mindSporeModelAvailable: hasRawfile(resourceManager, modelPath),
    cloudAdviceApiBase: apiBase,
    cloudAdviceApiConfigured: isCloudStyleAdviceApiBaseConfigured(apiBase),
    totalAudioCueCount: AUDIO_CUE_RAWFILES.length,
    missingAudioCueCount: missingAudioCuePaths.length,
    missingAudioCuePaths,
    referencedAvatarCount: avatarPaths.length,
    missingAvatarCount: missingAvatarPaths.length,
    missingAvatarPaths,
  };
}

function collectAvatarPaths(resourceManager: RawfileResourceManagerLike): string[] {
  const manifest: TemplateManifest = readRawfileJson<TemplateManifest>(resourceManager, TEMPLATE_MANIFEST_RAW_PATH);
  if (!Array.isArray(manifest.templates)) {
    return [];
  }

  const avatarPaths: Set<string> = new Set();
  for (const templateFileName of manifest.templates) {
    if (typeof templateFileName !== 'string' || templateFileName.trim().length === 0) {
      continue;
    }

    const template = readRawfileJson<Record<string, unknown>>(resourceManager, 'templates/' + templateFileName);
    const avatarPath: string = typeof template['avatar_image'] === 'string' ? template['avatar_image'] as string : '';
    if (avatarPath.trim().length > 0) {
      avatarPaths.add(avatarPath.trim());
    }
  }

  return Array.from(avatarPaths.values());
}

function readRawfileJson<T extends Object>(resourceManager: RawfileResourceManagerLike, rawfilePath: string): T {
  const content: string = readRawfileText(resourceManager, rawfilePath);
  if (content.length === 0) {
    return {} as T;
  }

  try {
    return JSON.parse(content) as T;
  } catch (_error) {
    return {} as T;
  }
}

function readRawfileText(resourceManager: RawfileResourceManagerLike, rawfilePath: string): string {
  if (typeof resourceManager.getRawFileContentSync !== 'function') {
    return '';
  }

  try {
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decodeToString(resourceManager.getRawFileContentSync(rawfilePath));
  } catch (_error) {
    return '';
  }
}

function hasRawfile(resourceManager: RawfileResourceManagerLike, rawfilePath: string): boolean {
  try {
    if (typeof resourceManager.getRawFileContentSync === 'function') {
      resourceManager.getRawFileContentSync(rawfilePath);
      return true;
    }

    const descriptor = resourceManager.getRawFd(rawfilePath);
    return descriptor.length >= 0;
  } catch (_error) {
    return false;
  }
}
