import { display } from '@kit.ArkUI';

export enum DevicePosture {
  NORMAL = 'normal',
  HALF_FOLDED = 'half_folded',
  FULLY_FOLDED = 'fully_folded',
}

export interface FoldableLayoutState {
  isFoldable: boolean;
  posture: DevicePosture;
  foldAngle: number;
  displayWidth: number;
  displayHeight: number;
  isTabletop: boolean; // half-folded with hinge horizontal
}

export class FoldableLayoutService {
  private state: FoldableLayoutState = {
    isFoldable: false,
    posture: DevicePosture.NORMAL,
    foldAngle: 180,
    displayWidth: 0,
    displayHeight: 0,
    isTabletop: false,
  };
  private onChange: ((state: FoldableLayoutState) => void) | null = null;

  initialize(): void {
    try {
      const defaultDisplay: display.Display = display.getDefaultDisplaySync();
      this.state.displayWidth = defaultDisplay.width;
      this.state.displayHeight = defaultDisplay.height;

      const foldStatus: display.FoldStatus = display.getFoldStatus();
      this.updateFromFoldStatus(foldStatus);

      display.on('foldStatusChange', (status: display.FoldStatus) => {
        this.updateFromFoldStatus(status);
        if (this.onChange !== null) {
          this.onChange(this.getState());
        }
      });

      this.state.isFoldable = true;
    } catch (_e) {
      // Not a foldable device
      this.state.isFoldable = false;
    }
  }

  setOnChange(cb: (state: FoldableLayoutState) => void): void {
    this.onChange = cb;
  }

  getState(): FoldableLayoutState {
    return { ...this.state };
  }

  private updateFromFoldStatus(status: display.FoldStatus): void {
    switch (status) {
      case display.FoldStatus.FOLD_STATUS_EXPANDED:
        this.state.posture = DevicePosture.NORMAL;
        this.state.foldAngle = 180;
        this.state.isTabletop = false;
        break;
      case display.FoldStatus.FOLD_STATUS_HALF_FOLDED:
        this.state.posture = DevicePosture.HALF_FOLDED;
        this.state.foldAngle = 90;
        this.state.isTabletop = true;
        break;
      case display.FoldStatus.FOLD_STATUS_FOLDED:
        this.state.posture = DevicePosture.FULLY_FOLDED;
        this.state.foldAngle = 0;
        this.state.isTabletop = false;
        break;
      default:
        this.state.posture = DevicePosture.NORMAL;
        this.state.foldAngle = 180;
        this.state.isTabletop = false;
    }

    const currentDisplay: display.Display = display.getDefaultDisplaySync();
    this.state.displayWidth = currentDisplay.width;
    this.state.displayHeight = currentDisplay.height;
  }
}

export const foldableLayoutService = new FoldableLayoutService();
