/**
 * Pure helper for PhotoMap page decisions.
 */

export interface PhotoMapPin {
  id: string;
  latitude: number;
  longitude: number;
  timestamp: number;
  mediaType: string;
}

export interface POIRecommendation {
  name: string;
  latitude: number;
  longitude: number;
  distanceMeters: number;
}

export interface PhotoMapRecommendationResult {
  latestPin: PhotoMapPin | null;
  recommendations: POIRecommendation[];
}

/**
 * Resolve POI recommendations from pins.
 * Pure logic: if no pins → empty; otherwise find latest pin by timestamp, then call getPOIs callback.
 */
export function resolvePhotoMapRecommendations(
  pins: PhotoMapPin[],
  getPOIs: (lat: number, lon: number) => POIRecommendation[]
): PhotoMapRecommendationResult {
  if (pins.length === 0) {
    return { latestPin: null, recommendations: [] };
  }

  const latestPin = pins.reduce((latest: PhotoMapPin, pin: PhotoMapPin) => {
    return pin.timestamp > latest.timestamp ? pin : latest;
  }, pins[0]);

  const recommendations = getPOIs(latestPin.latitude, latestPin.longitude);
  return { latestPin, recommendations };
}
