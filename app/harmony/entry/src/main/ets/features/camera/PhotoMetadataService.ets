import { geoLocationManager } from '@kit.LocationKit';

export interface PhotoMetadata {
  latitude: number;
  longitude: number;
  captureTimestamp: number;
}

export async function capturePhotoMetadata(): Promise<PhotoMetadata> {
  const timestamp: number = Date.now();
  let latitude: number = 0;
  let longitude: number = 0;

  try {
    const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation({
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      maxAccuracy: 100,
      timeoutMs: 3000,
    });
    latitude = location.latitude;
    longitude = location.longitude;
  } catch (_e) {
    // Location is optional; proceed without it
  }

  return { latitude, longitude, captureTimestamp: timestamp };
}
