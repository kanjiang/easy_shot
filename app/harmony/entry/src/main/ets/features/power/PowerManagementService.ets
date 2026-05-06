import { batteryInfo } from '@kit.BasicServicesKit';

export enum PowerLevel {
  NORMAL = 'normal',
  LOW = 'low',
  CRITICAL = 'critical',
}

export interface PowerModeState {
  batteryPercent: number;
  isCharging: boolean;
  powerLevel: PowerLevel;
  shouldReduceFrameRate: boolean;
  shouldDisablePreviewSync: boolean;
  shouldDimScreen: boolean;
}

const LOW_BATTERY_THRESHOLD: number = 20;
const CRITICAL_BATTERY_THRESHOLD: number = 10;
const CHECK_INTERVAL_MS: number = 30000;

export class PowerManagementService {
  private state: PowerModeState = {
    batteryPercent: 100,
    isCharging: false,
    powerLevel: PowerLevel.NORMAL,
    shouldReduceFrameRate: false,
    shouldDisablePreviewSync: false,
    shouldDimScreen: false,
  };
  private timerId: number = -1;
  private onChange: ((state: PowerModeState) => void) | null = null;

  getState(): PowerModeState {
    return { ...this.state };
  }

  setOnChange(cb: (state: PowerModeState) => void): void {
    this.onChange = cb;
  }

  startMonitoring(): void {
    this.checkBattery();
    this.timerId = setInterval(() => {
      this.checkBattery();
    }, CHECK_INTERVAL_MS);
  }

  stopMonitoring(): void {
    clearInterval(this.timerId);
  }

  private checkBattery(): void {
    try {
      const soc: number = batteryInfo.batterySOC;
      const charging: boolean = batteryInfo.chargingStatus !== batteryInfo.BatteryChargeState.NONE;

      this.state.batteryPercent = soc;
      this.state.isCharging = charging;

      if (charging) {
        this.state.powerLevel = PowerLevel.NORMAL;
      } else if (soc <= CRITICAL_BATTERY_THRESHOLD) {
        this.state.powerLevel = PowerLevel.CRITICAL;
      } else if (soc <= LOW_BATTERY_THRESHOLD) {
        this.state.powerLevel = PowerLevel.LOW;
      } else {
        this.state.powerLevel = PowerLevel.NORMAL;
      }

      this.state.shouldReduceFrameRate = this.state.powerLevel !== PowerLevel.NORMAL;
      this.state.shouldDisablePreviewSync = this.state.powerLevel === PowerLevel.CRITICAL;
      this.state.shouldDimScreen = this.state.powerLevel === PowerLevel.CRITICAL;

      if (this.onChange !== null) {
        this.onChange(this.state);
      }
    } catch (_e) {
      // batteryInfo may not be available in simulator
    }
  }
}

export const powerManagementService = new PowerManagementService();
