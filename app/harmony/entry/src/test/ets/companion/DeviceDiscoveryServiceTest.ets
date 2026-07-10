import { describe, it, expect } from '@ohos/hypium';
import { DeviceDiscoveryService, CompanionDevice } from '../../../main/ets/features/companion/DeviceDiscoveryService';

export default function deviceDiscoveryServiceTest() {
  describe('DeviceDiscoveryService', () => {
    it('listCandidateDevices returns mock devices when not initialized', 0, () => {
      const service = new DeviceDiscoveryService();
      const devices: CompanionDevice[] = service.listCandidateDevices();
      expect(devices.length).assertLarger(0);
    });

    it('mock devices have valid deviceId and deviceName', 0, () => {
      const service = new DeviceDiscoveryService();
      const devices: CompanionDevice[] = service.listCandidateDevices();
      for (const device of devices) {
        expect(device.deviceId.length).assertLarger(0);
        expect(device.deviceName.length).assertLarger(0);
        expect(device.deviceType.length).assertLarger(0);
        expect(device.discoverySource).assertEqual('mock');
      }
    });

    it('release resets state without errors', 0, () => {
      const service = new DeviceDiscoveryService();
      service.release();
      const devices: CompanionDevice[] = service.listCandidateDevices();
      expect(devices.length).assertLarger(0);
    });

    it('initialize and release cycle does not throw', 0, () => {
      const service = new DeviceDiscoveryService();
      service.initialize();
      service.release();
    });

    it('listCandidateDevices returns mock devices after init fails on non-device', 0, () => {
      const service = new DeviceDiscoveryService();
      service.initialize();
      const devices: CompanionDevice[] = service.listCandidateDevices();
      expect(devices.length).assertLarger(0);
      service.release();
    });
  });
}
