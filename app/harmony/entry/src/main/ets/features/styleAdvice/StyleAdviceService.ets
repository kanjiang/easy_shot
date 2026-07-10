import { StyleAdvice, StyleAdviceRequest, StyleAdviceResolution } from './StyleAdviceModel';
import { StyleAdviceClient } from './StyleAdviceClient';
import { MockStyleAdviceClient } from './MockStyleAdviceClient';
import { CloudStyleAdviceClient } from './CloudStyleAdviceClient';
import {
  isCloudStyleAdviceApiBaseConfigured,
  normalizeCloudStyleAdviceApiBase,
} from './StyleAdviceConfig';
import { settingsStore } from '../settings/SettingsStore';
import { AppSettings } from '../settings/SettingsModel';

const mockClient: StyleAdviceClient = new MockStyleAdviceClient();

export interface StyleAdviceResolutionOptions {
  settingsOverride?: AppSettings;
  cloudClientOverride?: StyleAdviceClient;
}

export async function resolveStyleAdvice(
  request: StyleAdviceRequest,
  apiBase: string = '',
  options?: StyleAdviceResolutionOptions,
): Promise<StyleAdviceResolution> {
  const settings: AppSettings = options?.settingsOverride ?? settingsStore.getSettings();
  const normalizedApiBase: string = normalizeCloudStyleAdviceApiBase(apiBase);

  if (settings.localOnlyMode) {
    return {
      advice: await mockClient.fetchAdvice(request),
      source: 'mock',
      deliveryMode: 'local_only',
    };
  }

  if (!settings.enableCloudAdvice) {
    return {
      advice: await mockClient.fetchAdvice(request),
      source: 'mock',
      deliveryMode: 'cloud_disabled',
    };
  }

  if (!isCloudStyleAdviceApiBaseConfigured(normalizedApiBase)) {
    return {
      advice: await mockClient.fetchAdvice(request),
      source: 'mock',
      deliveryMode: 'api_unconfigured',
    };
  }

  const cloudClient: StyleAdviceClient = options?.cloudClientOverride ?? new CloudStyleAdviceClient(normalizedApiBase);

  try {
    return {
      advice: await cloudClient.fetchAdvice(request),
      source: 'cloud',
      deliveryMode: 'cloud',
    };
  } catch (_error) {
    return {
      advice: await mockClient.fetchAdvice(request),
      source: 'mock',
      deliveryMode: 'cloud_failed',
    };
  }
}

export async function getStyleAdvice(request: StyleAdviceRequest, apiBase: string = ''): Promise<StyleAdvice> {
  const resolution: StyleAdviceResolution = await resolveStyleAdvice(request, apiBase);
  return resolution.advice;
}
