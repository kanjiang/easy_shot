import { describe, expect, it } from '@ohos/hypium';

import {
  deriveBluetoothPairingErrorKind,
  resolveBluetoothPairingConnectionTarget,
} from '../../../main/ets/features/bluetooth/BluetoothPairingActions';
import { BleDiscoveryState, BluetoothPeer } from '../../../main/ets/features/bluetooth/BluetoothPairingService';

function createPeer(deviceId: string, deviceName: string, rssi: number): BluetoothPeer {
  return {
    deviceId,
    deviceName,
    rssi,
  };
}

export default function bluetoothPairingActionsTest(): void {
  describe('BluetoothPairingActionsTest', () => {
    it('returns null connection target before bluetooth connection completes', 0, () => {
      const target = resolveBluetoothPairingConnectionTarget(
        BleDiscoveryState.CONNECTING,
        [createPeer('peer-1', 'Peer One', -45)],
        'peer-1',
      );

      expect(target).assertNull();
    });

    it('uses discovered peer name when bluetooth connection completes', 0, () => {
      const target = resolveBluetoothPairingConnectionTarget(
        BleDiscoveryState.CONNECTED,
        [createPeer('peer-1', 'Peer One', -45)],
        'peer-1',
      );

      expect(target?.deviceId as string).assertEqual('peer-1');
      expect(target?.deviceName as string).assertEqual('Peer One');
    });

    it('falls back to truncated device id when connected peer name is unavailable', 0, () => {
      const target = resolveBluetoothPairingConnectionTarget(
        BleDiscoveryState.CONNECTED,
        [],
        'peer-device-1234',
      );

      expect(target?.deviceName as string).assertEqual('peer-dev');
    });

    it('maps connect failures separately from scan failures', 0, () => {
      expect(deriveBluetoothPairingErrorKind('connect')).assertEqual('connect');
      expect(deriveBluetoothPairingErrorKind('scan')).assertEqual('scan');
      expect(deriveBluetoothPairingErrorKind('none')).assertEqual('scan');
    });
  });
}
