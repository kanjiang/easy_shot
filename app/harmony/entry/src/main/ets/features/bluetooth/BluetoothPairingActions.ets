import {
  BleDiscoveryState,
  BleFailureContext,
  BluetoothPeer,
} from './BluetoothPairingService';

export type BluetoothPairingErrorKind = 'scan' | 'connect';

export interface BluetoothPairingConnectionTarget {
  readonly deviceId: string;
  readonly deviceName: string;
}

export function resolveBluetoothPairingConnectionTarget(
  state: BleDiscoveryState,
  peers: BluetoothPeer[],
  connectingDeviceId: string,
): BluetoothPairingConnectionTarget | null {
  if (state !== BleDiscoveryState.CONNECTED || connectingDeviceId.length === 0) {
    return null;
  }

  const connectedPeer = peers.find((peer: BluetoothPeer) => peer.deviceId === connectingDeviceId);
  return {
    deviceId: connectingDeviceId,
    deviceName: connectedPeer?.deviceName ?? connectingDeviceId.substring(0, 8),
  };
}

export function deriveBluetoothPairingErrorKind(failureContext: BleFailureContext): BluetoothPairingErrorKind {
  return failureContext === 'connect' ? 'connect' : 'scan';
}
