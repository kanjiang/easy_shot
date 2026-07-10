import { geoLocationManager } from '@kit.LocationKit';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

export interface PhotoMapPin {
  id: string;
  latitude: number;
  longitude: number;
  photoPath: string;
  timestamp: number;
  templateId: string;
  mediaType?: string;
}

export interface POIRecommendation {
  name: string;
  latitude: number;
  longitude: number;
  category: string;
  distanceMeters: number;
}

const PINS_PREFS_NAME: string = 'easy_shot_photo_map';
const MAX_PINS: number = 500;

export class PhotoMapService {
  private pins: PhotoMapPin[] = [];
  private prefs: preferences.Preferences | null = null;

    try {
      const options: preferences.Options = { name: PINS_PREFS_NAME };
      this.prefs = preferences.getPreferencesSync(context, options);
      const raw: string = this.prefs.getSync('pins', '[]') as string;
      this.pins = JSON.parse(raw) as PhotoMapPin[];
      return true;
    } catch (_e) {
      this.prefs = null;
      this.pins = [];
      return false;
    }
  }

  addPin(pin: PhotoMapPin): boolean {
    this.pins.push(pin);
    if (this.pins.length > MAX_PINS) {
      this.pins = this.pins.slice(this.pins.length - MAX_PINS);
    }
    return this.persist();
  }

  getPins(): PhotoMapPin[] {
    return [...this.pins];
  }

  getPinsNear(lat: number, lon: number, radiusKm: number): PhotoMapPin[] {
    return this.pins.filter((pin: PhotoMapPin) => {
      const dist = this.haversineKm(lat, lon, pin.latitude, pin.longitude);
      return dist <= radiusKm;
    });
  }

  getRecommendedPOIs(lat: number, lon: number): POIRecommendation[] {
    // Group existing pins by proximity to form POI clusters
    const clusters: Map<string, { lat: number; lon: number; count: number }> = new Map();
    for (const pin of this.pins) {
      const key = `${Math.round(pin.latitude * 100)}_${Math.round(pin.longitude * 100)}`;
      const existing = clusters.get(key);
      if (existing !== undefined) {
        existing.count++;
      } else {
        clusters.set(key, { lat: pin.latitude, lon: pin.longitude, count: 1 });
      }
    }

    const recommendations: POIRecommendation[] = [];
    clusters.forEach((cluster, _key) => {
      if (cluster.count >= 2) {
        const dist = this.haversineKm(lat, lon, cluster.lat, cluster.lon);
        if (dist <= 50) {
          recommendations.push({
            name: `热门拍摄点 (${cluster.count}次)`,
            latitude: cluster.lat,
            longitude: cluster.lon,
            category: 'user_hotspot',
            distanceMeters: Math.round(dist * 1000),
          });
        }
      }
    });

    return recommendations.sort((a, b) => a.distanceMeters - b.distanceMeters).slice(0, 10);
  }

  private haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private persist(): boolean {
    if (this.prefs === null) {
      return false;
    }
    try {
      this.prefs.putSync('pins', JSON.stringify(this.pins));
      this.prefs.flush(() => {});
      return true;
    } catch (_e) {
      return false;
    }
  }
}

export const photoMapService = new PhotoMapService();
