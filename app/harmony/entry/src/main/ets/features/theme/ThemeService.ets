import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

export enum AppTheme {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system',
}

export enum AppLocale {
  ZH_CN = 'zh-CN',
  EN_US = 'en-US',
  SYSTEM = 'system',
}

export interface ThemeConfig {
  theme: AppTheme;
  locale: AppLocale;
}

const THEME_PREFS_NAME: string = 'easy_shot_theme';

export class ThemeService {
  private config: ThemeConfig = { theme: AppTheme.SYSTEM, locale: AppLocale.SYSTEM };
  private prefs: preferences.Preferences | null = null;
  private onChange: ((config: ThemeConfig) => void) | null = null;

  initialize(context: Context): void {
    const options: preferences.Options = { name: THEME_PREFS_NAME };
    this.prefs = preferences.getPreferencesSync(context, options);
    this.config = {
      theme: (this.prefs.getSync('theme', AppTheme.SYSTEM) as string) as AppTheme,
      locale: (this.prefs.getSync('locale', AppLocale.SYSTEM) as string) as AppLocale,
    };
  }

  getConfig(): ThemeConfig {
    return { ...this.config };
  }

  setOnChange(cb: (config: ThemeConfig) => void): void {
    this.onChange = cb;
  }

  setTheme(theme: AppTheme): void {
    this.config.theme = theme;
    this.persist();
    if (this.onChange !== null) {
      this.onChange(this.config);
    }
  }

  setLocale(locale: AppLocale): void {
    this.config.locale = locale;
    this.persist();
    if (this.onChange !== null) {
      this.onChange(this.config);
    }
  }

  isDark(): boolean {
    // In SYSTEM mode, would check system setting; simplified here
    return this.config.theme === AppTheme.DARK;
  }

  private persist(): void {
    if (this.prefs === null) return;
    this.prefs.putSync('theme', this.config.theme);
    this.prefs.putSync('locale', this.config.locale);
    this.prefs.flush(() => {});
  }
}

export const themeService = new ThemeService();
