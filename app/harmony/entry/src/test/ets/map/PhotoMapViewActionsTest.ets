import { describe, it, expect } from '@ohos/hypium';
import {
  resolvePhotoMapRecommendations,
  PhotoMapPin,
  POIRecommendation,
} from '../../main/ets/features/map/PhotoMapViewActions';

export default function PhotoMapViewActionsTest() {
  describe('PhotoMapViewActionsTest', () => {

    function makePin(id: string, lat: number, lon: number, ts: number): PhotoMapPin {
      return { id, latitude: lat, longitude: lon, timestamp: ts, mediaType: 'photo' };
    }

    const stubPOIs: POIRecommendation[] = [
      { name: 'Cafe', latitude: 39.9, longitude: 116.4, distanceMeters: 200 },
    ];

    it('returns_empty_when_no_pins', 0, () => {
      const result = resolvePhotoMapRecommendations([], () => stubPOIs);
      expect(result.latestPin).assertNull();
      expect(result.recommendations.length).assertEqual(0);
    });

    it('uses_latest_pin_by_timestamp', 0, () => {
      const pins = [
        makePin('a', 30.0, 120.0, 1000),
        makePin('b', 31.0, 121.0, 3000),
        makePin('c', 32.0, 122.0, 2000),
      ];
      let calledLat = 0;
      let calledLon = 0;
      const result = resolvePhotoMapRecommendations(pins, (lat, lon) => {
        calledLat = lat;
        calledLon = lon;
        return stubPOIs;
      });
      expect(result.latestPin!.id).assertEqual('b');
      expect(calledLat).assertEqual(31.0);
      expect(calledLon).assertEqual(121.0);
      expect(result.recommendations.length).assertEqual(1);
    });

    it('single_pin_is_used_as_latest', 0, () => {
      const pins = [makePin('x', 40.0, 116.0, 5000)];
      const result = resolvePhotoMapRecommendations(pins, () => stubPOIs);
      expect(result.latestPin!.id).assertEqual('x');
      expect(result.recommendations.length).assertEqual(1);
    });

    it('passes_empty_pois_through', 0, () => {
      const pins = [makePin('a', 30.0, 120.0, 1000)];
      const result = resolvePhotoMapRecommendations(pins, () => []);
      expect(result.latestPin!.id).assertEqual('a');
      expect(result.recommendations.length).assertEqual(0);
    });
  });
}
