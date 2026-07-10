import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';

const STYLE_ADVICE_MANIFEST_RAW_PATH: string = 'style_advice/manifest.json';

export interface CloudStyleAdviceConfig {
  apiBase: string;
}

export function createDefaultCloudStyleAdviceConfig(): CloudStyleAdviceConfig {
  return {
    apiBase: '',
  };
}

export function normalizeCloudStyleAdviceApiBase(apiBase: string): string {
  const trimmed: string = apiBase.trim();
  if (trimmed.length === 0) {
    return '';
  }

  return trimmed.replace(/\/+$/, '');
}

export function isCloudStyleAdviceApiBaseConfigured(apiBase: string): boolean {
  const normalized: string = normalizeCloudStyleAdviceApiBase(apiBase);
  if (normalized.length === 0) {
    return false;
  }

  if (!/^https?:\/\//.test(normalized)) {
    return false;
  }

  return !/\.example\.com(?:\/|$)/.test(normalized);
}

export function loadCloudStyleAdviceConfig(resMgr: resourceManager.ResourceManager): CloudStyleAdviceConfig {
  try {
    const rawContent: Uint8Array = resMgr.getRawFileContentSync(STYLE_ADVICE_MANIFEST_RAW_PATH);
    const decoder = new util.TextDecoder('utf-8');
    const content: string = decoder.decodeToString(rawContent);
    const parsed = JSON.parse(content) as Record<string, unknown>;
    const apiBase: string = typeof parsed['apiBase'] === 'string' ? parsed['apiBase'] as string : '';
    return {
      apiBase: normalizeCloudStyleAdviceApiBase(apiBase),
    };
  } catch (_error) {
    return createDefaultCloudStyleAdviceConfig();
  }
}
