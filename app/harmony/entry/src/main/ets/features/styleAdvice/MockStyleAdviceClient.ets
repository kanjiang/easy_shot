import { StyleAdvice, StyleAdviceRequest } from './StyleAdviceModel';
import { StyleAdviceClient } from './StyleAdviceClient';

export class MockStyleAdviceClient implements StyleAdviceClient {
  async fetchAdvice(request: StyleAdviceRequest): Promise<StyleAdvice> {
    const score: number = Math.round(request.alignmentScore * 100);
    const styleMatch: number = Math.min(100, score + Math.round(Math.random() * 15));

    const compositionAdvice: string = score >= 80
      ? '构图非常出色！主体位置合理，画面平衡。'
      : score >= 50
        ? '构图基本到位，建议稍微调整角度以获得更佳效果。'
        : '建议重新调整站位，使身体主体位于画面黄金分割位置。';

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
      return '姿势标准，与模板高度匹配！表情再自然一些会更好。';
    } else if (ratio >= 0.5) {
      return '整体姿势不错，部分关键点偏离较大，注意手臂和肩部的位置。';
    }
    return '姿势与模板差异较大，建议参考模板引导逐步调整身体各部位。';
  }

  private generateSuggestions(score: number, styleTag: string): string[] {
    const tips: string[] = [];

    if (score < 60) {
      tips.push('尝试跟随骨架引导调整站位');
    }
    if (score < 80) {
      tips.push('注意保持肩部放松、背部挺直');
    }

    if (styleTag === 'sweet_daily') {
      tips.push('微微侧身可以让画面更灵动');
    } else if (styleTag === 'cool_street') {
      tips.push('可以尝试目光看向远方，增加氛围感');
    } else if (styleTag === 'campus_vibes') {
      tips.push('自然走动的抓拍效果会更好');
    } else if (styleTag === 'travel_mood') {
      tips.push('多利用环境元素作为前景');
    }

    tips.push('多尝试不同角度，找到最佳上镜感');
    return tips;
  }
}
