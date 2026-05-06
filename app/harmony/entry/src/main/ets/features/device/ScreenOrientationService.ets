import { window } from '@kit.ArkUI';

export enum OrientationLock {
  AUTO = 'auto',
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape',
}

export class ScreenOrientationService {
  private currentLock: OrientationLock = OrientationLock.AUTO;
  private windowStage: window.Window | null = null;

  async initialize(windowInstance: window.Window): Promise<void> {
    this.windowStage = windowInstance;
  }

  getCurrentLock(): OrientationLock {
    return this.currentLock;
  }

  async setOrientation(lock: OrientationLock): Promise<void> {
    if (this.windowStage === null) return;
    this.currentLock = lock;

    let orientation: window.Orientation;
    switch (lock) {
      case OrientationLock.PORTRAIT:
        orientation = window.Orientation.PORTRAIT;
        break;
      case OrientationLock.LANDSCAPE:
        orientation = window.Orientation.LANDSCAPE;
        break;
      case OrientationLock.AUTO:
      default:
        orientation = window.Orientation.UNSPECIFIED;
        break;
    }

    await this.windowStage.setPreferredOrientation(orientation);
  }

  async lockToPortrait(): Promise<void> {
    await this.setOrientation(OrientationLock.PORTRAIT);
  }

  async lockToLandscape(): Promise<void> {
    await this.setOrientation(OrientationLock.LANDSCAPE);
  }

  async unlock(): Promise<void> {
    await this.setOrientation(OrientationLock.AUTO);
  }
}

export const screenOrientationService = new ScreenOrientationService();
