import { describe, expect, it } from '@ohos/hypium';

import { AppSettings, createDefaultSettings } from '../../../main/ets/features/settings/SettingsModel';

export default function settingsTest(): void {
  describe('Settings', () => {
    it('default settings have local-only mode enabled', 0, () => {
      const settings: AppSettings = createDefaultSettings();

      expect(settings.localOnlyMode).assertEqual(true);
      expect(settings.enableCloudAdvice).assertEqual(false);
      expect(settings.allowPhotoUpload).assertEqual(false);
      expect(settings.defaultCameraFacing).assertEqual('rear');
    });

    it('default settings object is a new instance each call', 0, () => {
      const settingsA: AppSettings = createDefaultSettings();
      const settingsB: AppSettings = createDefaultSettings();

      settingsA.localOnlyMode = false;

      expect(settingsB.localOnlyMode).assertEqual(true);
    });

    it('settings interface accepts valid camera facing values', 0, () => {
      const settings: AppSettings = createDefaultSettings();

      settings.defaultCameraFacing = 'front';
      expect(settings.defaultCameraFacing).assertEqual('front');

      settings.defaultCameraFacing = 'rear';
      expect(settings.defaultCameraFacing).assertEqual('rear');
    });
  });
}
