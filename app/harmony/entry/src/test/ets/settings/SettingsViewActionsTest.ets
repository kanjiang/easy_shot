import { describe, expect, it } from '@ohos/hypium';

import { OrientationLock } from '../../../main/ets/features/device/ScreenOrientationService';
import { createDefaultSettings } from '../../../main/ets/features/settings/SettingsModel';
import {
  createDefaultRuntimeResourceReadinessStatus,
  RuntimeResourceReadinessStatus,
} from '../../../main/ets/features/settings/RuntimeResourceReadinessService';
import {
  deriveSettingsCloudUiState,
  formatSettingsMissingPathSummary,
  resolveSettingsOrientationLock,
} from '../../../main/ets/features/settings/SettingsViewActions';

function createReadinessStatus(overrides?: Partial<RuntimeResourceReadinessStatus>): RuntimeResourceReadinessStatus {
  return {
    ...createDefaultRuntimeResourceReadinessStatus(),
    ...overrides,
  };
}

export default function settingsViewActionsTest(): void {
  describe('SettingsViewActionsTest', () => {
    it('disables cloud toggles when local-only mode is enabled even if cloud api is configured', 0, () => {
      const settings = createDefaultSettings();
      settings.localOnlyMode = true;
      const uiState = deriveSettingsCloudUiState(settings, createReadinessStatus({ cloudAdviceApiConfigured: true }));

      expect(uiState.capabilityAvailable).assertTrue();
      expect(uiState.toggleEnabled).assertFalse();
      expect(uiState.toggleOpacity).assertEqual(0.45);
      expect(uiState.showUnavailableHint).assertFalse();
    });

    it('shows unavailable hint when cloud api base is not configured', 0, () => {
      const settings = createDefaultSettings();
      settings.localOnlyMode = false;
      const uiState = deriveSettingsCloudUiState(settings, createReadinessStatus({ cloudAdviceApiConfigured: false }));

      expect(uiState.capabilityAvailable).assertFalse();
      expect(uiState.toggleEnabled).assertFalse();
      expect(uiState.toggleOpacity).assertEqual(0.45);
      expect(uiState.showUnavailableHint).assertTrue();
    });

    it('enables cloud toggles when local-only mode is off and cloud api is configured', 0, () => {
      const settings = createDefaultSettings();
      settings.localOnlyMode = false;
      const uiState = deriveSettingsCloudUiState(settings, createReadinessStatus({ cloudAdviceApiConfigured: true }));

      expect(uiState.capabilityAvailable).assertTrue();
      expect(uiState.toggleEnabled).assertTrue();
      expect(uiState.toggleOpacity).assertEqual(1);
      expect(uiState.showUnavailableHint).assertFalse();
    });

    it('formats missing path summary for zero, one or two paths without truncation', 0, () => {
      expect(formatSettingsMissingPathSummary([])).assertEqual('');
      expect(formatSettingsMissingPathSummary(['audio/shutter.ogg'])).assertEqual('audio/shutter.ogg');
      expect(formatSettingsMissingPathSummary(['a', 'b'])).assertEqual('a、b');
    });

    it('formats missing path summary with truncation when more than two paths are missing', 0, () => {
      const summary = formatSettingsMissingPathSummary(['a', 'b', 'c']);

      expect(summary).assertEqual('a、b 等 3 项');
    });

    it('keeps current orientation lock when setOrientation fails and updates it on success', 0, () => {
      expect(resolveSettingsOrientationLock(OrientationLock.AUTO, OrientationLock.PORTRAIT, false))
        .assertEqual(OrientationLock.AUTO);
      expect(resolveSettingsOrientationLock(OrientationLock.AUTO, OrientationLock.PORTRAIT, true))
        .assertEqual(OrientationLock.PORTRAIT);
    });
  });
}
