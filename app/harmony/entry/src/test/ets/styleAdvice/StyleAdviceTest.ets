import { describe, expect, it } from '@ohos/hypium';

import { MockStyleAdviceClient } from '../../../main/ets/features/styleAdvice/MockStyleAdviceClient';
import { getStyleAdvice, resolveStyleAdvice } from '../../../main/ets/features/styleAdvice/StyleAdviceService';
import {
  isCloudStyleAdviceApiBaseConfigured,
  normalizeCloudStyleAdviceApiBase,
} from '../../../main/ets/features/styleAdvice/StyleAdviceConfig';
import { StyleAdvice, StyleAdviceRequest } from '../../../main/ets/features/styleAdvice/StyleAdviceModel';
import { createDefaultSettings } from '../../../main/ets/features/settings/SettingsModel';

class RejectingStyleAdviceClient extends MockStyleAdviceClient {
  async fetchAdvice(_request: StyleAdviceRequest): Promise<StyleAdvice> {
    throw new Error('network down');
  }
}

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

    it('style_advice_api_base_is_normalized_before_use', 0, () => {
      const normalized: string = normalizeCloudStyleAdviceApiBase(' https://api.easyshot.dev/v1/ ');
      expect(normalized).assertEqual('https://api.easyshot.dev/v1');
    });

    it('placeholder_or_empty_style_advice_api_base_is_treated_as_unconfigured', 0, () => {
      expect(isCloudStyleAdviceApiBaseConfigured('')).assertFalse();
      expect(isCloudStyleAdviceApiBaseConfigured('https://api.easyshot.example.com/v1')).assertFalse();
      expect(isCloudStyleAdviceApiBaseConfigured('https://api.easyshot.dev/v1')).assertTrue();
    });

    it('style_advice_service_returns_mock_advice_when_cloud_is_disabled', 0, async () => {
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: 'sweet_daily',
        alignmentScore: 0.8,
        matchedPoints: 8,
        totalPoints: 10,
      };

      const advice: StyleAdvice = await getStyleAdvice(request, '');

      expect(advice.overallScore).assertEqual(80);
      expect(advice.styleMatch).assertLargerOrEqual(80);
      expect(advice.suggestions.length).assertLarger(0);
    });

    it('resolve_style_advice_reports_local_only_mode', 0, async () => {
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: 'sweet_daily',
        alignmentScore: 0.8,
        matchedPoints: 8,
        totalPoints: 10,
      };

      const resolution = await resolveStyleAdvice(request, 'https://api.easyshot.dev/v1', {
        settingsOverride: createDefaultSettings(),
      });

      expect(resolution.deliveryMode).assertEqual('local_only');
      expect(resolution.source).assertEqual('mock');
    });

    it('resolve_style_advice_reports_unconfigured_api_base', 0, async () => {
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: 'sweet_daily',
        alignmentScore: 0.8,
        matchedPoints: 8,
        totalPoints: 10,
      };
      const settings = createDefaultSettings();
      settings.localOnlyMode = false;
      settings.enableCloudAdvice = true;

      const resolution = await resolveStyleAdvice(request, '', {
        settingsOverride: settings,
      });

      expect(resolution.deliveryMode).assertEqual('api_unconfigured');
      expect(resolution.source).assertEqual('mock');
    });

    it('resolve_style_advice_reports_cloud_failure_fallback', 0, async () => {
      const request: StyleAdviceRequest = {
        templateId: 'test_template',
        styleTag: 'sweet_daily',
        alignmentScore: 0.8,
        matchedPoints: 8,
        totalPoints: 10,
      };
      const settings = createDefaultSettings();
      settings.localOnlyMode = false;
      settings.enableCloudAdvice = true;

      const resolution = await resolveStyleAdvice(request, 'https://api.easyshot.dev/v1', {
        settingsOverride: settings,
        cloudClientOverride: new RejectingStyleAdviceClient(),
      });

      expect(resolution.deliveryMode).assertEqual('cloud_failed');
      expect(resolution.source).assertEqual('mock');
      expect(resolution.advice.suggestions.length).assertLarger(0);
    });
  });
}
