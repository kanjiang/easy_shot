import { describe, expect, it } from '@ohos/hypium';

import { SessionPhase } from '../../../main/ets/core/session/SessionState';
import { CompanionDevice } from '../../../main/ets/features/companion/DeviceDiscoveryService';
import {
  deriveDevicePairingUiState,
  DevicePairingActionDependencies,
  startDevicePairingGuiding,
} from '../../../main/ets/features/companion/DevicePairingActions';

class DevicePairingSessionServiceDouble {
  public guideStateAccepted: boolean = true;
  public startGuidingCalls: number = 0;
  public sendGuideStateUpdateCalls: number = 0;

  startGuiding(): void {
    this.startGuidingCalls++;
  }

  sendGuideStateUpdate(): boolean {
    this.sendGuideStateUpdateCalls++;
    return this.guideStateAccepted;
  }
}

function createDependencies(): {
  dependencies: DevicePairingActionDependencies;
  sessionService: DevicePairingSessionServiceDouble;
} {
  const sessionService: DevicePairingSessionServiceDouble = new DevicePairingSessionServiceDouble();
  return {
    sessionService,
    dependencies: {
      sessionService,
    },
  };
}

function createDevice(id: string, source: 'distributed' | 'mock'): CompanionDevice {
  return {
    deviceId: id,
    deviceName: `Device ${id}`,
    deviceType: 'phone',
    discoverySource: source,
    lastSeenAt: 1710000000000,
  };
}

export default function devicePairingActionsTest(): void {
  describe('DevicePairingActionsTest', () => {
    it('shows bluetooth fallback only after distributed init check fails', 0, () => {
      const unchecked = deriveDevicePairingUiState(false, false, [], SessionPhase.IDLE);
      expect(unchecked.showBluetoothFallback).assertFalse();

      const ready = deriveDevicePairingUiState(true, true, [], SessionPhase.IDLE);
      expect(ready.showBluetoothFallback).assertFalse();

      const fallback = deriveDevicePairingUiState(true, false, [], SessionPhase.IDLE);
      expect(fallback.showBluetoothFallback).assertTrue();
    });

    it('shows mock discovery hint only when every discovered device is mock', 0, () => {
      const allMock = deriveDevicePairingUiState(
        true,
        true,
        [createDevice('1', 'mock'), createDevice('2', 'mock')],
        SessionPhase.SCANNING,
      );
      expect(allMock.showMockDiscoveryHint).assertTrue();

      const mixed = deriveDevicePairingUiState(
        true,
        true,
        [createDevice('1', 'mock'), createDevice('2', 'distributed')],
        SessionPhase.SCANNING,
      );
      expect(mixed.showMockDiscoveryHint).assertFalse();

      const empty = deriveDevicePairingUiState(true, true, [], SessionPhase.SCANNING);
      expect(empty.showMockDiscoveryHint).assertFalse();
    });

    it('shows scanning indicator only while phase is active and list is empty', 0, () => {
      const scanning = deriveDevicePairingUiState(true, true, [], SessionPhase.SCANNING);
      expect(scanning.showScanningIndicator).assertTrue();

      const idle = deriveDevicePairingUiState(true, true, [], SessionPhase.IDLE);
      expect(idle.showScanningIndicator).assertFalse();

      const withDevices = deriveDevicePairingUiState(
        true,
        true,
        [createDevice('1', 'distributed')],
        SessionPhase.SCANNING,
      );
      expect(withDevices.showScanningIndicator).assertFalse();
    });

    it('startDevicePairingGuiding starts guiding before returning accepted result', 0, () => {
      const accepted = createDependencies();
      const acceptedResult = startDevicePairingGuiding(accepted.dependencies);

      expect(acceptedResult).assertTrue();
      expect(accepted.sessionService.startGuidingCalls).assertEqual(1);
      expect(accepted.sessionService.sendGuideStateUpdateCalls).assertEqual(1);

      const rejected = createDependencies();
      rejected.sessionService.guideStateAccepted = false;
      const rejectedResult = startDevicePairingGuiding(rejected.dependencies);

      expect(rejectedResult).assertFalse();
      expect(rejected.sessionService.startGuidingCalls).assertEqual(1);
      expect(rejected.sessionService.sendGuideStateUpdateCalls).assertEqual(1);
    });
  });
}
