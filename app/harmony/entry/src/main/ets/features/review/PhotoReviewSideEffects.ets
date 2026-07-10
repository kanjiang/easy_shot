import { Context } from '@kit.AbilityKit';

import { PhotoHistoryEntry, photoHistoryService } from '../history/PhotoHistoryService';
import { PhotoMapPin, photoMapService } from '../map/PhotoMapService';
import { notificationService } from '../notification/NotificationService';

export interface PhotoReviewSideEffectParams {
  photoFilePath: string;
  templateTitle: string;
  templateId: string;
  alignmentScore: number;
  latitude: number;
  longitude: number;
  captureTimestamp: number;
  isVideo: boolean;
}

export interface PhotoReviewSideEffectDependencies {
  readonly historyService: {
    initialize(context: Context): boolean;
    addEntry(entry: PhotoHistoryEntry): boolean;
  };
  readonly mapService: {
    initialize(context: Context): boolean;
    addPin(pin: PhotoMapPin): boolean;
  };
  readonly notificationService: {
    notifyCaptureComplete(templateTitle: string, score: number): Promise<boolean>;
  };
  readonly now: () => number;
  readonly createSuffix: () => string;
}

const defaultSideEffectDependencies: PhotoReviewSideEffectDependencies = {
  historyService: photoHistoryService,
  mapService: photoMapService,
  notificationService,
  now: (): number => Date.now(),
  createSuffix: (): string => Math.random().toString(36).substring(2, 7),
};

export function persistPhotoReviewMetadata(
  context: Context,
  params: PhotoReviewSideEffectParams,
  dependencies: PhotoReviewSideEffectDependencies = defaultSideEffectDependencies,
): boolean {
  let metadataSaved: boolean = true;
  const effectiveTimestamp: number = params.captureTimestamp || dependencies.now();

  if (params.latitude !== 0 || params.longitude !== 0) {
    const mapInitialized = dependencies.mapService.initialize(context);
    const mapSaved = mapInitialized && dependencies.mapService.addPin({
      id: `pin_${effectiveTimestamp}_${dependencies.createSuffix()}`,
      latitude: params.latitude,
      longitude: params.longitude,
      photoPath: params.photoFilePath,
      timestamp: effectiveTimestamp,
      templateId: params.templateId,
      mediaType: params.isVideo ? 'video' : 'photo',
    });
    if (!mapSaved) {
      metadataSaved = false;
    }
  }

  const historyInitialized = dependencies.historyService.initialize(context);
  const historySaved = historyInitialized && dependencies.historyService.addEntry({
    id: `hist_${dependencies.now()}_${dependencies.createSuffix()}`,
    photoPath: params.photoFilePath,
    templateId: params.templateId,
    templateTitle: params.templateTitle,
    alignmentScore: params.alignmentScore,
    timestamp: effectiveTimestamp,
    latitude: params.latitude,
    longitude: params.longitude,
    mediaType: params.isVideo ? 'video' : 'photo',
  });
  if (!historySaved) {
    metadataSaved = false;
  }

  return metadataSaved;
}

export async function notifyPhotoReviewCapture(
  templateTitle: string,
  alignmentScore: number,
  dependencies: PhotoReviewSideEffectDependencies = defaultSideEffectDependencies,
): Promise<boolean> {
  return await dependencies.notificationService.notifyCaptureComplete(templateTitle, alignmentScore);
}
