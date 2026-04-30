import { resourceManager } from '@kit.LocalizationKit';

class LocaleHelperImpl {
  private resMgr: resourceManager.ResourceManager | null = null;

  setResourceManager(mgr: resourceManager.ResourceManager): void {
    this.resMgr = mgr;
  }

  getString(name: string): string {
    if (this.resMgr === null) {
      return name;
    }
    try {
      return this.resMgr.getStringByNameSync(name);
    } catch (_error) {
      return name;
    }
  }
}

export const localeHelper: LocaleHelperImpl = new LocaleHelperImpl();
