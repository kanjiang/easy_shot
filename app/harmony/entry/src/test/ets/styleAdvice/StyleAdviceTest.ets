import { describe, expect, it } from '@ohos/hypium';

import { MockStyleAdviceClient } from '../../../main/ets/features/styleAdvice/MockStyleAdviceClient';
import { StyleAdvice, StyleAdviceRequest } from '../../../main/ets/features/styleAdvice/StyleAdviceModel';

export default function styleAdviceTest(): void {
  describe('StyleAdviceTest', () => {
    it('high_alignment_returns_high_score', 0, async () => {
      const client: MockStyleAdviceClient = new MockStyleAdviceClient();
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: 'sweet_daily',
        alignmentScore: 0.9,
        matchedPoints: 9,
        totalPoints: 10,
      };

      const advice: StyleAdvice = await client.fetchAdvice(request);

      expect(advice.overallScore).assertEqual(90);
      expect(advice.styleMatch).assertLargerOrEqual(90);
      expect(advice.compositionAdvice.length > 0).assertTrue();
      expect(advice.poseAdvice.length > 0).assertTrue();
      expect(advice.suggestions.length > 0).assertTrue();
    });

    it('low_alignment_returns_low_score', 0, async () => {
      const client: MockStyleAdviceClient = new MockStyleAdviceClient();
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: 'cool_street',
        alignmentScore: 0.3,
        matchedPoints: 3,
        totalPoints: 10,
      };

      const advice: StyleAdvice = await client.fetchAdvice(request);

      expect(advice.overallScore).assertEqual(30);
      expect(advice.suggestions.length >= 2).assertTrue();
    });

    it('zero_alignment_returns_zero_score', 0, async () => {
      const client: MockStyleAdviceClient = new MockStyleAdviceClient();
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: '',
        alignmentScore: 0,
        matchedPoints: 0,
        totalPoints: 0,
      };

      const advice: StyleAdvice = await client.fetchAdvice(request);

      expect(advice.overallScore).assertEqual(0);
    });

    it('different_styles_produce_relevant_tips', 0, async () => {
      const client: MockStyleAdviceClient = new MockStyleAdviceClient();

      const sweetReq: StyleAdviceRequest = {
        templateId: 'test',
        styleTag: 'sweet_daily',
        alignmentScore: 0.7,
        matchedPoints: 7,
        totalPoints: 10,
      };
      const coolReq: StyleAdviceRequest = {
        templateId: 'test',
        styleTag: 'cool_street',
        alignmentScore: 0.7,
        matchedPoints: 7,
        totalPoints: 10,
      };

      const sweetAdvice: StyleAdvice = await client.fetchAdvice(sweetReq);
      const coolAdvice: StyleAdvice = await client.fetchAdvice(coolReq);

      const sweetTips: string = sweetAdvice.suggestions.join(' ');
      const coolTips: string = coolAdvice.suggestions.join(' ');

      expect(sweetTips.includes('灵动')).assertTrue();
      expect(coolTips.includes('氛围感')).assertTrue();
    });
  });
}
