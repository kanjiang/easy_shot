import { ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface BluetoothPeer {
  deviceId: string;
  deviceName: string;
  rssi: number;
}

export enum BleDiscoveryState {
  IDLE = 'idle',
  SCANNING = 'scanning',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  ERROR = 'error',
}

export type BleFailureContext = 'none' | 'scan' | 'connect';

const EASY_SHOT_SERVICE_UUID: string = '0000fff0-0000-1000-8000-00805f9b34fb';

export class BluetoothPairingService {
  private state: BleDiscoveryState = BleDiscoveryState.IDLE;
  private lastFailureContext: BleFailureContext = 'none';
  private discoveredPeers: BluetoothPeer[] = [];
  private onPeersUpdate: ((peers: BluetoothPeer[]) => void) | null = null;
  private onStateChange: ((state: BleDiscoveryState) => void) | null = null;

  getState(): BleDiscoveryState {
    return this.state;
  }

  getPeers(): BluetoothPeer[] {
    return [...this.discoveredPeers];
  }

  getLastFailureContext(): BleFailureContext {
    return this.lastFailureContext;
  }

  setOnPeersUpdate(cb: (peers: BluetoothPeer[]) => void): void {
    this.onPeersUpdate = cb;
  }

  setOnStateChange(cb: (state: BleDiscoveryState) => void): void {
    this.onStateChange = cb;
  }

  startScan(): void {
    try {
      this.lastFailureContext = 'none';
      this.state = BleDiscoveryState.SCANNING;
      this.discoveredPeers = [];
      this.notifyState();

      const scanFilter: ble.ScanFilter = {
        serviceUuid: EASY_SHOT_SERVICE_UUID,
      };

      this.registerBleDeviceFind((results: Array<ble.ScanResult>) => {
        for (const result of results) {
          const existing = this.discoveredPeers.find(
            (p: BluetoothPeer) => p.deviceId === result.deviceId
          );
          if (existing === undefined) {
            this.discoveredPeers.push({
              deviceId: result.deviceId,
              deviceName: result.localName || result.deviceId.substring(0, 8),
              rssi: result.rssi,
            });
          } else {
            existing.rssi = result.rssi;
          }
        }
        if (this.onPeersUpdate !== null) {
          this.onPeersUpdate(this.getPeers());
        }
      });

      this.startBleScan([scanFilter], {
        interval: 2000,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_LATENCY,
      });
    } catch (e) {
      const err = e as BusinessError;
      console.error('BluetoothPairingService: scan error ' + err.code);
      this.lastFailureContext = 'scan';
      this.state = BleDiscoveryState.ERROR;
      this.notifyState();
    }
  }

  stopScan(): void {
    try {
      this.stopBleScan();
      this.unregisterBleDeviceFind();
    } catch (_e) {
      // Ignore
    }
    this.lastFailureContext = 'none';
    this.state = BleDiscoveryState.IDLE;
    this.notifyState();
  }

  connectToPeer(deviceId: string): void {
    this.lastFailureContext = 'none';
    this.state = BleDiscoveryState.CONNECTING;
    this.notifyState();

    try {
      const gattClient: ble.GattClientDevice = this.createGattClient(deviceId);
      gattClient.on('BLEConnectionStateChange', (state: ble.BLEConnectionChangeState) => {
        if (state.state === ble.ProfileConnectionState.STATE_CONNECTED) {
          this.lastFailureContext = 'none';
          this.state = BleDiscoveryState.CONNECTED;
          this.notifyState();
        } else if (state.state === ble.ProfileConnectionState.STATE_DISCONNECTED) {
          if (this.state === BleDiscoveryState.CONNECTING) {
            this.lastFailureContext = 'connect';
            this.state = BleDiscoveryState.ERROR;
          } else {
            this.lastFailureContext = 'none';
            this.state = BleDiscoveryState.IDLE;
          }
          this.notifyState();
        }
      });
      gattClient.connect();
    } catch (e) {
      const err = e as BusinessError;
      console.error('BluetoothPairingService: connect error ' + err.code);
      this.lastFailureContext = 'connect';
      this.state = BleDiscoveryState.ERROR;
      this.notifyState();
    }
  }

  private notifyState(): void {
    if (this.onStateChange !== null) {
      this.onStateChange(this.state);
    }
  }

  protected registerBleDeviceFind(callback: (results: Array<ble.ScanResult>) => void): void {
    ble.on('BLEDeviceFind', callback);
  }

  protected unregisterBleDeviceFind(): void {
    ble.off('BLEDeviceFind');
  }

  protected startBleScan(filters: ble.ScanFilter[], options: ble.ScanOptions): void {
    ble.startBLEScan(filters, options);
  }

  protected stopBleScan(): void {
    ble.stopBLEScan();
  }

  protected createGattClient(deviceId: string): ble.GattClientDevice {
    return ble.createGattClientDevice(deviceId);
  }
}

export const bluetoothPairingService = new BluetoothPairingService();
