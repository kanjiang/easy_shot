import { StyleAdvice, StyleAdviceRequest } from './StyleAdviceModel';
import { StyleAdviceClient } from './StyleAdviceClient';
import { localeHelper } from '../../core/locale/LocaleHelper';

export class MockStyleAdviceClient implements StyleAdviceClient {
  async fetchAdvice(request: StyleAdviceRequest): Promise<StyleAdvice> {
    const score: number = Math.round(request.alignmentScore * 100);
    const styleMatch: number = Math.min(100, score + Math.round(Math.random() * 15));

    const compositionAdvice: string = score >= 80
      ? localeHelper.getString('mock_composition_excellent')
      : score >= 50
        ? localeHelper.getString('mock_composition_good')
        : localeHelper.getString('mock_composition_needs_work');

    const poseAdvice: string = this.generatePoseAdvice(request);
    const suggestions: string[] = this.generateSuggestions(score, request.styleTag);

    return {
      overallScore: score,
      compositionAdvice,
      poseAdvice,
      suggestions,
      styleMatch,
    };
  }

  private generatePoseAdvice(request: StyleAdviceRequest): string {
    const ratio: number = request.totalPoints > 0 ? request.matchedPoints / request.totalPoints : 0;

    if (ratio >= 0.8) {
      return localeHelper.getString('mock_pose_excellent');
    } else if (ratio >= 0.5) {
      return localeHelper.getString('mock_pose_good');
    }
    return localeHelper.getString('mock_pose_needs_work');
  }

  private generateSuggestions(score: number, styleTag: string): string[] {
    const tips: string[] = [];

    if (score < 60) {
      tips.push(localeHelper.getString('mock_tip_follow_skeleton'));
    }
    if (score < 80) {
      tips.push(localeHelper.getString('mock_tip_relax_shoulders'));
    }

    if (styleTag === 'sweet_daily') {
      tips.push(localeHelper.getString('mock_tip_sweet_daily'));
    } else if (styleTag === 'cool_street') {
      tips.push(localeHelper.getString('mock_tip_cool_street'));
    } else if (styleTag === 'campus_vibes') {
      tips.push(localeHelper.getString('mock_tip_campus_vibes'));
    } else if (styleTag === 'travel_mood') {
      tips.push(localeHelper.getString('mock_tip_travel_mood'));
    }

    tips.push(localeHelper.getString('mock_tip_experiment'));
    return tips;
  }
}
