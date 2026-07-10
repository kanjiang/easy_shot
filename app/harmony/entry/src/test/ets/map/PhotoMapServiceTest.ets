import { describe, expect, it } from '@ohos/hypium';

import { PhotoMapPin, PhotoMapService } from '../../../main/ets/features/map/PhotoMapService';

interface FakePreferencesLike {
  putSync(key: string, value: string): void;
  flush(callback: () => void): void;
}

function createPin(id: string, latitude: number, longitude: number, timestamp: number): PhotoMapPin {
  return {
    id,
    latitude,
    longitude,
    photoPath: `/tmp/${id}.jpg`,
    timestamp,
    templateId: 'template-1',
  };
}

export default function photoMapServiceTest(): void {
  describe('PhotoMapService', () => {
    it('returns clustered hotspot recommendations near the latest location', 0, () => {
      const service = new PhotoMapService() as PhotoMapService & { pins: PhotoMapPin[] };
      service.pins = [
        createPin('a', 39.9001, 116.3001, 1),
        createPin('b', 39.9002, 116.3002, 2),
        createPin('c', 39.9003, 116.3001, 3),
        createPin('d', 31.2304, 121.4737, 4),
      ];

      const recommendations = service.getRecommendedPOIs(39.9002, 116.3002);

      expect(recommendations.length).assertEqual(1);
      expect(recommendations[0].category).assertEqual('user_hotspot');
      expect(recommendations[0].name.includes('3')).assertTrue();
    });

    it('filters out sparse or distant clusters', 0, () => {
      const service = new PhotoMapService() as PhotoMapService & { pins: PhotoMapPin[] };
      service.pins = [
        createPin('a', 39.9001, 116.3001, 1),
        createPin('b', 39.9101, 116.3101, 2),
        createPin('c', 31.2304, 121.4737, 3),
        createPin('d', 31.2305, 121.4738, 4),
      ];

      const recommendations = service.getRecommendedPOIs(39.9002, 116.3002);

      expect(recommendations.length).assertEqual(0);
    });

    it('addPin returns false when preferences are unavailable', 0, () => {
      const service = new PhotoMapService() as PhotoMapService & {
        pins: PhotoMapPin[];
        prefs: FakePreferencesLike | null;
      };
      service.pins = [];
      service.prefs = null;

      const persisted = service.addPin(createPin('e', 39.9001, 116.3001, 5));

      expect(persisted).assertFalse();
      expect(service.pins.length).assertEqual(1);
    });

    it('addPin returns true after persisting to preferences', 0, () => {
      let storedValue = '';
      let flushed = false;
      const service = new PhotoMapService() as PhotoMapService & {
        pins: PhotoMapPin[];
        prefs: FakePreferencesLike | null;
      };
      service.pins = [];
      service.prefs = {
        putSync: (_key: string, value: string) => {
          storedValue = value;
        },
        flush: (callback: () => void) => {
          flushed = true;
          callback();
        },
      };

      const persisted = service.addPin(createPin('f', 39.9002, 116.3002, 6));

      expect(persisted).assertTrue();
      expect(storedValue.includes('f')).assertTrue();
      expect(flushed).assertTrue();
    });
  });
}
