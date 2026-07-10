import { SessionPhase } from '../../core/session/SessionState';
import { CompanionDevice } from './DeviceDiscoveryService';
import { companionSessionService } from './CompanionSessionService';

export interface DevicePairingUiState {
  readonly showBluetoothFallback: boolean;
  readonly showMockDiscoveryHint: boolean;
  readonly showScanningIndicator: boolean;
}

export interface DevicePairingActionDependencies {
  readonly sessionService: {
    startGuiding(): void;
    sendGuideStateUpdate(): boolean;
  };
}

const defaultDevicePairingActionDependencies: DevicePairingActionDependencies = {
  sessionService: companionSessionService,
};

export function deriveDevicePairingUiState(
  distributedInitChecked: boolean,
  distributedReady: boolean,
  devices: CompanionDevice[],
  phase: SessionPhase,
): DevicePairingUiState {
  const hasDevices = devices.length > 0;
  const showMockDiscoveryHint = hasDevices && devices.every((device: CompanionDevice) => device.discoverySource === 'mock');

  return {
    showBluetoothFallback: distributedInitChecked && !distributedReady,
    showMockDiscoveryHint,
    showScanningIndicator: !hasDevices && phase !== SessionPhase.IDLE,
  };
}

export function startDevicePairingGuiding(
  dependencies: DevicePairingActionDependencies = defaultDevicePairingActionDependencies,
): boolean {
  dependencies.sessionService.startGuiding();
  return dependencies.sessionService.sendGuideStateUpdate();
}
