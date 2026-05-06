import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

export enum FontScale {
  SMALL = 0.85,
  NORMAL = 1.0,
  LARGE = 1.2,
  EXTRA_LARGE = 1.4,
}

export interface AccessibilitySettings {
  fontScale: number;
  highContrast: boolean;
  reduceMotion: boolean;
}

const A11Y_PREFS_NAME: string = 'easy_shot_accessibility';

export class AccessibilityService {
  private settings: AccessibilitySettings = {
    fontScale: FontScale.NORMAL,
    highContrast: false,
    reduceMotion: false,
  };
  private prefs: preferences.Preferences | null = null;

  initialize(context: Context): void {
    const options: preferences.Options = { name: A11Y_PREFS_NAME };
    this.prefs = preferences.getPreferencesSync(context, options);
    this.settings = {
      fontScale: this.prefs.getSync('fontScale', FontScale.NORMAL) as number,
      highContrast: this.prefs.getSync('highContrast', false) as boolean,
      reduceMotion: this.prefs.getSync('reduceMotion', false) as boolean,
    };
  }

  getSettings(): AccessibilitySettings {
    return { ...this.settings };
  }

  setFontScale(scale: number): void {
    this.settings.fontScale = scale;
    this.persist();
  }

  setHighContrast(enabled: boolean): void {
    this.settings.highContrast = enabled;
    this.persist();
  }

  setReduceMotion(enabled: boolean): void {
    this.settings.reduceMotion = enabled;
    this.persist();
  }

  scaledFontSize(baseFp: number): number {
    return baseFp * this.settings.fontScale;
  }

  private persist(): void {
    if (this.prefs === null) return;
    this.prefs.putSync('fontScale', this.settings.fontScale);
    this.prefs.putSync('highContrast', this.settings.highContrast);
    this.prefs.putSync('reduceMotion', this.settings.reduceMotion);
    this.prefs.flush(() => {});
  }
}

export const accessibilityService = new AccessibilityService();
