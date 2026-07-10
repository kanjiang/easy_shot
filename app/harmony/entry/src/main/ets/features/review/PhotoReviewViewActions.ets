import { StyleAdvice, StyleAdviceDeliveryMode, StyleAdviceStatus } from '../styleAdvice/StyleAdviceModel';

export type PhotoReviewSaveToastKind = 'save_success' | 'save_failed';

export interface PhotoReviewSaveOutcome {
  readonly isSaved: boolean;
  readonly toastKind: PhotoReviewSaveToastKind;
}

export type PhotoReviewAdviceSectionKind = 'loading' | 'error' | 'content' | 'placeholder';

export type PhotoReviewAdviceModeKind = StyleAdviceDeliveryMode;

export interface PhotoReviewAdviceViewState {
  readonly sectionKind: PhotoReviewAdviceSectionKind;
  readonly modeKind: PhotoReviewAdviceModeKind | null;
  readonly useCloudAccent: boolean;
}

export function resolvePhotoReviewSaveOutcome(success: boolean, currentSaved: boolean = false): PhotoReviewSaveOutcome {
  return {
    isSaved: currentSaved || success,
    toastKind: success ? 'save_success' : 'save_failed',
  };
}

export function resolvePhotoReviewAdviceViewState(
  status: StyleAdviceStatus,
  advice: StyleAdvice | null,
  deliveryMode: StyleAdviceDeliveryMode,
): PhotoReviewAdviceViewState {
  if (status === StyleAdviceStatus.LOADING) {
    return {
      sectionKind: 'loading',
      modeKind: null,
      useCloudAccent: false,
    };
  }

  if (status === StyleAdviceStatus.ERROR) {
    return {
      sectionKind: 'error',
      modeKind: null,
      useCloudAccent: false,
    };
  }

  if (advice !== null) {
    return {
      sectionKind: 'content',
      modeKind: deliveryMode,
      useCloudAccent: deliveryMode === 'cloud',
    };
  }

  return {
    sectionKind: 'placeholder',
    modeKind: deliveryMode,
    useCloudAccent: deliveryMode === 'cloud',
  };
}

export function shouldShowPhotoReviewRetakeWithAdvice(isVideo: boolean, advice: StyleAdvice | null): boolean {
  return !isVideo && advice !== null && advice.suggestions.length > 0;
}

export function buildPhotoReviewRetakeWithAdviceParams(
  templateId: string,
  advice: StyleAdvice | null,
): Record<string, string> | null {
  if (!shouldShowPhotoReviewRetakeWithAdvice(false, advice)) {
    return null;
  }

  return {
    templateId,
    adviceHint: advice!.suggestions[0],
  };
}

export function buildPhotoReviewTemplateDetailParams(templateId: string): Record<string, string> | null {
  if (templateId.length === 0) {
    return null;
  }

  return {
    openTemplateId: templateId,
  };
}
