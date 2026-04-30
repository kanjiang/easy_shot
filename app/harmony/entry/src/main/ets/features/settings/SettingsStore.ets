import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

import { AppSettings, createDefaultSettings } from './SettingsModel';

const PREFERENCES_NAME: string = 'easy_shot_settings';

export class SettingsStore {
  private settings: AppSettings = createDefaultSettings();
  private prefs: preferences.Preferences | null = null;

  load(context: Context): AppSettings {
    const options: preferences.Options = { name: PREFERENCES_NAME };
    this.prefs = preferences.getPreferencesSync(context, options);

    this.settings = {
      enableCloudAdvice: this.prefs.getSync('enableCloudAdvice', false) as boolean,
      allowPhotoUpload: this.prefs.getSync('allowPhotoUpload', false) as boolean,
      localOnlyMode: this.prefs.getSync('localOnlyMode', true) as boolean,
      defaultCameraFacing: this.prefs.getSync('defaultCameraFacing', 'rear') as string,
    };

    return this.getSettings();
  }

  getSettings(): AppSettings {
    return { ...this.settings };
  }

  updateBoolean(key: string, value: boolean): AppSettings {
    if (key === 'enableCloudAdvice') {
      this.settings.enableCloudAdvice = value;
    } else if (key === 'allowPhotoUpload') {
      this.settings.allowPhotoUpload = value;
    } else if (key === 'localOnlyMode') {
      this.settings.localOnlyMode = value;
      if (value) {
        this.settings.enableCloudAdvice = false;
        this.settings.allowPhotoUpload = false;
      }
    }

    this.persist();
    return this.getSettings();
  }

  updateString(key: string, value: string): AppSettings {
    if (key === 'defaultCameraFacing') {
      this.settings.defaultCameraFacing = value;
    }

    this.persist();
    return this.getSettings();
  }

  private persist(): void {
    if (this.prefs === null) {
      return;
    }

    this.prefs.putSync('enableCloudAdvice', this.settings.enableCloudAdvice);
    this.prefs.putSync('allowPhotoUpload', this.settings.allowPhotoUpload);
    this.prefs.putSync('localOnlyMode', this.settings.localOnlyMode);
    this.prefs.putSync('defaultCameraFacing', this.settings.defaultCameraFacing);
    this.prefs.flush(() => {});
  }
}

export const settingsStore: SettingsStore = new SettingsStore();
