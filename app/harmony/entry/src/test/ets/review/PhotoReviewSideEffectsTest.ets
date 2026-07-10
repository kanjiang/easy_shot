import { describe, expect, it } from '@ohos/hypium';
import { Context } from '@kit.AbilityKit';

import {
  notifyPhotoReviewCapture,
  persistPhotoReviewMetadata,
  PhotoReviewSideEffectDependencies,
  PhotoReviewSideEffectParams,
} from '../../../main/ets/features/review/PhotoReviewSideEffects';
import { PhotoHistoryEntry } from '../../../main/ets/features/history/PhotoHistoryService';
import { PhotoMapPin } from '../../../main/ets/features/map/PhotoMapService';

class HistoryServiceDouble {
  public initializeResult: boolean = true;
  public addEntryResult: boolean = true;
  public initializeCalls: number = 0;
  public entries: PhotoHistoryEntry[] = [];

  initialize(_context: Context): boolean {
    this.initializeCalls++;
    return this.initializeResult;
  }

  addEntry(entry: PhotoHistoryEntry): boolean {
    this.entries.push(entry);
    return this.addEntryResult;
  }
}

class MapServiceDouble {
  public initializeResult: boolean = true;
  public addPinResult: boolean = true;
  public initializeCalls: number = 0;
  public pins: PhotoMapPin[] = [];

  initialize(_context: Context): boolean {
    this.initializeCalls++;
    return this.initializeResult;
  }

  addPin(pin: PhotoMapPin): boolean {
    this.pins.push(pin);
    return this.addPinResult;
  }
}

class ReviewNotificationServiceDouble {
  public notifyResult: boolean = true;
  public calls: Array<{ templateTitle: string; alignmentScore: number }> = [];

  async notifyCaptureComplete(templateTitle: string, alignmentScore: number): Promise<boolean> {
    this.calls.push({ templateTitle, alignmentScore });
    return this.notifyResult;
  }
}

function createParams(overrides?: Partial<PhotoReviewSideEffectParams>): PhotoReviewSideEffectParams {
  return {
    photoFilePath: '/data/storage/el2/base/haps/entry/files/review.jpg',
    templateTitle: 'Template Review',
    templateId: 'template_review',
    alignmentScore: 0.84,
    latitude: 39.9042,
    longitude: 116.4074,
    captureTimestamp: 1710000000000,
    isVideo: false,
    ...overrides,
  };
}

function createDependencies(): {
  dependencies: PhotoReviewSideEffectDependencies;
  historyService: HistoryServiceDouble;
  mapService: MapServiceDouble;
  notificationService: ReviewNotificationServiceDouble;
} {
  const historyService: HistoryServiceDouble = new HistoryServiceDouble();
  const mapService: MapServiceDouble = new MapServiceDouble();
  const notificationService: ReviewNotificationServiceDouble = new ReviewNotificationServiceDouble();

  return {
    historyService,
    mapService,
    notificationService,
    dependencies: {
      historyService,
      mapService,
      notificationService,
      now: (): number => 1710001234567,
      createSuffix: (): string => 'abc12',
    },
  };
}

export default function photoReviewSideEffectsTest(): void {
  describe('PhotoReviewSideEffectsTest', () => {
    it('skips map persistence when location is unavailable and still saves history', 0, () => {
      const { dependencies, historyService, mapService } = createDependencies();

      const saved = persistPhotoReviewMetadata(
        {} as Context,
        createParams({ latitude: 0, longitude: 0 }),
        dependencies,
      );

      expect(saved).assertTrue();
      expect(mapService.initializeCalls).assertEqual(0);
      expect(mapService.pins.length).assertEqual(0);
      expect(historyService.initializeCalls).assertEqual(1);
      expect(historyService.entries.length).assertEqual(1);
      expect(historyService.entries[0].timestamp).assertEqual(1710000000000);
    });

    it('returns false when map persistence fails after location metadata is available', 0, () => {
      const { dependencies, mapService, historyService } = createDependencies();
      mapService.addPinResult = false;

      const saved = persistPhotoReviewMetadata({} as Context, createParams(), dependencies);

      expect(saved).assertFalse();
      expect(mapService.initializeCalls).assertEqual(1);
      expect(mapService.pins.length).assertEqual(1);
      expect(historyService.entries.length).assertEqual(1);
    });

    it('returns false when history persistence fails even if map save succeeds', 0, () => {
      const { dependencies, historyService, mapService } = createDependencies();
      historyService.addEntryResult = false;

      const saved = persistPhotoReviewMetadata({} as Context, createParams({ isVideo: true }), dependencies);

      expect(saved).assertFalse();
      expect(mapService.pins[0].mediaType).assertEqual('video');
      expect(historyService.entries[0].mediaType).assertEqual('video');
      expect(historyService.entries[0].id).assertEqual('hist_1710001234567_abc12');
    });

    it('notifyPhotoReviewCapture forwards notification result', 0, async () => {
      const { dependencies, notificationService } = createDependencies();
      notificationService.notifyResult = false;

      const notified = await notifyPhotoReviewCapture('Template Review', 0.51, dependencies);

      expect(notified).assertFalse();
      expect(notificationService.calls.length).assertEqual(1);
      expect(notificationService.calls[0].templateTitle).assertEqual('Template Review');
      expect(notificationService.calls[0].alignmentScore).assertEqual(0.51);
    });
  });
}
