import { describe, expect, it } from '@ohos/hypium';

import {
  resolvePhotoReviewAdviceViewState,
  buildPhotoReviewRetakeWithAdviceParams,
  buildPhotoReviewTemplateDetailParams,
  resolvePhotoReviewSaveOutcome,
  shouldShowPhotoReviewRetakeWithAdvice,
} from '../../../main/ets/features/review/PhotoReviewViewActions';
import { StyleAdvice, StyleAdviceStatus } from '../../../main/ets/features/styleAdvice/StyleAdviceModel';

function createAdvice(suggestions: string[]): StyleAdvice {
  return {
    overallScore: 0.88,
    compositionAdvice: 'Keep the subject centered.',
    poseAdvice: 'Lift the chin slightly.',
    suggestions,
    styleMatch: 0.92,
  };
}

export default function photoReviewViewActionsTest(): void {
  describe('PhotoReviewViewActionsTest', () => {
    it('marks media as saved and returns success toast on export success', 0, () => {
      const outcome = resolvePhotoReviewSaveOutcome(true, false);

      expect(outcome.isSaved).assertTrue();
      expect(outcome.toastKind).assertEqual('save_success');
    });

    it('preserves saved state when a later export attempt fails', 0, () => {
      const outcome = resolvePhotoReviewSaveOutcome(false, true);

      expect(outcome.isSaved).assertTrue();
      expect(outcome.toastKind).assertEqual('save_failed');
    });

    it('returns loading advice view state without mode banner', 0, () => {
      const state = resolvePhotoReviewAdviceViewState(
        StyleAdviceStatus.LOADING,
        null,
        'cloud',
      );

      expect(state.sectionKind).assertEqual('loading');
      expect(state.modeKind).assertNull();
      expect(state.useCloudAccent).assertFalse();
    });

    it('returns content advice view state with cloud accent when advice is available', 0, () => {
      const state = resolvePhotoReviewAdviceViewState(
        StyleAdviceStatus.SUCCESS,
        createAdvice(['Raise the camera angle']),
        'cloud',
      );

      expect(state.sectionKind).assertEqual('content');
      expect(state.modeKind).assertEqual('cloud');
      expect(state.useCloudAccent).assertTrue();
    });

    it('returns placeholder advice view state when no advice is available after load', 0, () => {
      const state = resolvePhotoReviewAdviceViewState(
        StyleAdviceStatus.SUCCESS,
        null,
        'cloud_failed',
      );

      expect(state.sectionKind).assertEqual('placeholder');
      expect(state.modeKind).assertEqual('cloud_failed');
      expect(state.useCloudAccent).assertFalse();
    });

    it('shows retake with advice only for still photos with suggestions', 0, () => {
      expect(shouldShowPhotoReviewRetakeWithAdvice(false, createAdvice(['Tilt the camera upward']))).assertTrue();
      expect(shouldShowPhotoReviewRetakeWithAdvice(false, createAdvice([]))).assertFalse();
      expect(shouldShowPhotoReviewRetakeWithAdvice(false, null)).assertFalse();
    });

    it('hides retake with advice for videos even when suggestions exist', 0, () => {
      expect(shouldShowPhotoReviewRetakeWithAdvice(true, createAdvice(['Move closer to the light']))).assertFalse();
    });

    it('builds retake params with the first advice suggestion', 0, () => {
      const params = buildPhotoReviewRetakeWithAdviceParams(
        'template_review',
        createAdvice(['Raise the camera angle', 'Relax shoulders']),
      );

      expect(params !== null).assertTrue();
      expect(params!.templateId).assertEqual('template_review');
      expect(params!.adviceHint).assertEqual('Raise the camera angle');
    });

    it('returns template detail params only when a template id is available', 0, () => {
      expect(buildPhotoReviewTemplateDetailParams('')).assertNull();

      const params = buildPhotoReviewTemplateDetailParams('template_review');
      expect(params !== null).assertTrue();
      expect(params!.openTemplateId).assertEqual('template_review');
    });
  });
}
