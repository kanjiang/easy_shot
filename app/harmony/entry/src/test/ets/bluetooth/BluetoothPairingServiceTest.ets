import { describe, expect, it } from '@ohos/hypium';
import { ble } from '@kit.ConnectivityKit';

import {
  BleDiscoveryState,
  BluetoothPairingService,
  BluetoothPeer,
} from '../../../main/ets/features/bluetooth/BluetoothPairingService';

class FakeGattClient {
  private connectionCallback: ((state: ble.BLEConnectionChangeState) => void) | null = null;
  public connectCalls: number = 0;

  on(_event: string, callback: (state: ble.BLEConnectionChangeState) => void): void {
    this.connectionCallback = callback;
  }

  connect(): void {
    this.connectCalls++;
  }

  emitConnectionState(state: ble.ProfileConnectionState): void {
    if (this.connectionCallback !== null) {
      this.connectionCallback({ state } as ble.BLEConnectionChangeState);
    }
  }
}

class BluetoothPairingServiceDouble extends BluetoothPairingService {
  public registeredDeviceFindCallback: ((results: Array<ble.ScanResult>) => void) | null = null;
  public startScanShouldFail: boolean = false;
  public stopScanCalls: number = 0;
  public createGattClientShouldFail: boolean = false;
  public readonly gattClientDouble: FakeGattClient = new FakeGattClient();

  protected registerBleDeviceFind(callback: (results: Array<ble.ScanResult>) => void): void {
    this.registeredDeviceFindCallback = callback;
  }

  protected unregisterBleDeviceFind(): void {
    this.registeredDeviceFindCallback = null;
  }

  protected startBleScan(_filters: ble.ScanFilter[], _options: ble.ScanOptions): void {
    if (this.startScanShouldFail) {
      throw { code: 501 };
    }
  }

  protected stopBleScan(): void {
    this.stopScanCalls++;
  }

  protected createGattClient(_deviceId: string): ble.GattClientDevice {
    if (this.createGattClientShouldFail) {
      throw { code: 502 };
    }
    return this.gattClientDouble as Object as ble.GattClientDevice;
  }
}

export default function bluetoothPairingServiceTest(): void {
  describe('BluetoothPairingServiceTest', () => {
    it('startScan exposes scan failure context when BLE scan throws', 0, () => {
      const service: BluetoothPairingServiceDouble = new BluetoothPairingServiceDouble();
      service.startScanShouldFail = true;

      service.startScan();

      expect(service.getState()).assertEqual(BleDiscoveryState.ERROR);
      expect(service.getLastFailureContext()).assertEqual('scan');
    });

    it('deduplicates discovered peers and updates RSSI on repeated findings', 0, () => {
      const service: BluetoothPairingServiceDouble = new BluetoothPairingServiceDouble();
      let latestPeers: BluetoothPeer[] = [];
      service.setOnPeersUpdate((peers: BluetoothPeer[]) => {
        latestPeers = peers;
      });

      service.startScan();
      service.registeredDeviceFindCallback?.([
        { deviceId: 'peer-1', localName: 'Peer One', rssi: -52 } as ble.ScanResult,
        { deviceId: 'peer-1', localName: 'Peer One', rssi: -41 } as ble.ScanResult,
      ]);

      expect(service.getState()).assertEqual(BleDiscoveryState.SCANNING);
      expect(latestPeers.length).assertEqual(1);
      expect(latestPeers[0].deviceName).assertEqual('Peer One');
      expect(latestPeers[0].rssi).assertEqual(-41);
    });

    it('treats disconnect while connecting as a connect failure', 0, () => {
      const service: BluetoothPairingServiceDouble = new BluetoothPairingServiceDouble();

      service.connectToPeer('peer-2');
      service.gattClientDouble.emitConnectionState(ble.ProfileConnectionState.STATE_DISCONNECTED);

      expect(service.gattClientDouble.connectCalls).assertEqual(1);
      expect(service.getState()).assertEqual(BleDiscoveryState.ERROR);
      expect(service.getLastFailureContext()).assertEqual('connect');
    });
  });
}
