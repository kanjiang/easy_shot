import { AppSettings } from './SettingsModel';
import { RuntimeResourceReadinessStatus } from './RuntimeResourceReadinessService';
import { OrientationLock } from '../device/ScreenOrientationService';

export interface SettingsCloudUiState {
  readonly capabilityAvailable: boolean;
  readonly toggleEnabled: boolean;
  readonly toggleOpacity: number;
  readonly showUnavailableHint: boolean;
}

export function deriveSettingsCloudUiState(
  settings: AppSettings,
  resourceReadiness: RuntimeResourceReadinessStatus,
): SettingsCloudUiState {
  const capabilityAvailable = resourceReadiness.cloudAdviceApiConfigured;
  const toggleEnabled = !settings.localOnlyMode && capabilityAvailable;
  return {
    capabilityAvailable,
    toggleEnabled,
    toggleOpacity: toggleEnabled ? 1.0 : 0.45,
    showUnavailableHint: !capabilityAvailable,
  };
}

export function formatSettingsMissingPathSummary(paths: string[]): string {
  if (paths.length === 0) {
    return '';
  }

  if (paths.length <= 2) {
    return paths.join('、');
  }

  return paths.slice(0, 2).join('、') + ' 等 ' + paths.length + ' 项';
}

export function resolveSettingsOrientationLock(
  currentLock: string,
  requestedLock: OrientationLock,
  applied: boolean,
): string {
  return applied ? requestedLock : currentLock;
}
