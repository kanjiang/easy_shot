import { deviceManager } from '@kit.DistributedServiceKit';

export interface CompanionDevice {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  discoverySource?: 'distributed' | 'mock';
}

const MOCK_DEVICES: CompanionDevice[] = [
  { deviceId: 'mock-phone-a', deviceName: 'Pura Demo A', deviceType: 'phone', discoverySource: 'mock' },
  { deviceId: 'mock-phone-b', deviceName: 'Pura Demo B', deviceType: 'phone', discoverySource: 'mock' },
];

export class DeviceDiscoveryService {
  private dm: deviceManager.DeviceManager | null = null;
  private isDistributedReady: boolean = false;

  initialize(): void {
    try {
      this.dm = deviceManager.createDeviceManager('com.easyshot.app');
      this.isDistributedReady = true;
    } catch (_error) {
      this.isDistributedReady = false;
    }
  }

  listCandidateDevices(): CompanionDevice[] {
    if (!this.isDistributedReady || this.dm === null) {
      return MOCK_DEVICES;
    }

    try {
      const trusted: deviceManager.DeviceBasicInfo[] = this.dm.getAvailableDeviceListSync();
      if (trusted.length === 0) {
        return MOCK_DEVICES;
      }

      return trusted.map((info: deviceManager.DeviceBasicInfo): CompanionDevice => ({
        deviceId: info.deviceId,
        deviceName: info.deviceName,
        deviceType: String(info.deviceTypeId),
        discoverySource: 'distributed',
      }));
    } catch (_error) {
      return MOCK_DEVICES;
    }
  }

  release(): void {
    this.dm = null;
    this.isDistributedReady = false;
  }
}
