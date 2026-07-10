import { util } from '@kit.ArkTS';
import { describe, expect, it } from '@ohos/hypium';

import { AppSettings, createDefaultSettings } from '../../../main/ets/features/settings/SettingsModel';
import {
  inspectRuntimeResourceReadiness,
  RuntimeResourceReadinessStatus,
} from '../../../main/ets/features/settings/RuntimeResourceReadinessService';
import { RawfileResourceManagerLike } from '../../../main/ets/features/poseTemplate/data/PoseTemplateRepository';

class FakeRawfileResourceManager implements RawfileResourceManagerLike {
  constructor(private readonly contents: Record<string, string>) {
  }

  getRawFd(): never {
    throw new Error('getRawFd should not be used in this test');
  }

  getRawFileContentSync(path: string): Uint8Array {
    const content: string | undefined = this.contents[path];
    if (content === undefined) {
      throw new Error('Missing rawfile: ' + path);
    }

    const encoder = new util.TextEncoder('utf-8');
    return encoder.encodeInto(content);
  }
}

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

    it('runtime readiness reports missing external assets and unconfigured cloud api', 0, () => {
      const status: RuntimeResourceReadinessStatus = inspectRuntimeResourceReadiness(new FakeRawfileResourceManager({
        'models/manifest.json': JSON.stringify({ rawfilePath: 'models/pose_estimation.ms' }),
        'style_advice/manifest.json': JSON.stringify({ apiBase: '' }),
        'templates/manifest.json': JSON.stringify({ templates: ['pose.json'] }),
        'templates/pose.json': JSON.stringify({ avatar_image: 'avatars/sweet/test.png' }),
      }));

      expect(status.mindSporeModelAvailable).assertFalse();
      expect(status.expectedModelPath).assertEqual('models/pose_estimation.ms');
      expect(status.cloudAdviceApiBase).assertEqual('');
      expect(status.cloudAdviceApiConfigured).assertFalse();
      expect(status.totalAudioCueCount).assertEqual(3);
      expect(status.missingAudioCueCount).assertEqual(3);
      expect(status.missingAudioCuePaths[0]).assertEqual('audio/shutter.ogg');
      expect(status.referencedAvatarCount).assertEqual(1);
      expect(status.missingAvatarCount).assertEqual(1);
      expect(status.missingAvatarPaths[0]).assertEqual('avatars/sweet/test.png');
    });

    it('runtime readiness reports ready when model, audio, avatar and cloud api are present', 0, () => {
      const status: RuntimeResourceReadinessStatus = inspectRuntimeResourceReadiness(new FakeRawfileResourceManager({
        'models/manifest.json': JSON.stringify({ rawfilePath: 'models/pose_estimation.ms' }),
        'models/pose_estimation.ms': 'model',
        'style_advice/manifest.json': JSON.stringify({ apiBase: 'https://api.easyshot.dev/v1' }),
        'templates/manifest.json': JSON.stringify({ templates: ['pose.json'] }),
        'templates/pose.json': JSON.stringify({ avatar_image: 'avatars/sweet/test.png' }),
        'avatars/sweet/test.png': 'png',
        'audio/shutter.ogg': 'ogg',
        'audio/countdown_tick.ogg': 'ogg',
        'audio/countdown_end.ogg': 'ogg',
      }));

      expect(status.mindSporeModelAvailable).assertTrue();
      expect(status.cloudAdviceApiBase).assertEqual('https://api.easyshot.dev/v1');
      expect(status.cloudAdviceApiConfigured).assertTrue();
      expect(status.missingAudioCueCount).assertEqual(0);
      expect(status.missingAudioCuePaths.length).assertEqual(0);
      expect(status.referencedAvatarCount).assertEqual(1);
      expect(status.missingAvatarCount).assertEqual(0);
      expect(status.missingAvatarPaths.length).assertEqual(0);
    });
  });
}
