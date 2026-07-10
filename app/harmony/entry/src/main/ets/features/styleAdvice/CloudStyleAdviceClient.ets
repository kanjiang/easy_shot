import { http } from '@kit.NetworkKit';
import { StyleAdvice, StyleAdviceRequest } from './StyleAdviceModel';
import { StyleAdviceClient } from './StyleAdviceClient';
import {
  isCloudStyleAdviceApiBaseConfigured,
  normalizeCloudStyleAdviceApiBase,
} from './StyleAdviceConfig';

const REQUEST_TIMEOUT_MS: number = 15000;

export class CloudStyleAdviceClient implements StyleAdviceClient {
  private apiBase: string;

  constructor(apiBase: string) {
    this.apiBase = normalizeCloudStyleAdviceApiBase(apiBase);
  }

  async fetchAdvice(request: StyleAdviceRequest): Promise<StyleAdvice> {
    if (!isCloudStyleAdviceApiBaseConfigured(this.apiBase)) {
      throw new Error('Cloud style advice API base is not configured');
    }

    const httpRequest: http.HttpRequest = http.createHttp();

    try {
      const body: object = {
        templateId: request.templateId,
        styleTag: request.styleTag,
        alignmentScore: request.alignmentScore,
        matchedPoints: request.matchedPoints,
        totalPoints: request.totalPoints,
      };

      const response: http.HttpResponse = await httpRequest.request(
        `${this.apiBase}/style-advice`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify(body),
          connectTimeout: REQUEST_TIMEOUT_MS,
          readTimeout: REQUEST_TIMEOUT_MS,
        },
      );

      if (response.responseCode !== http.ResponseCode.OK) {
        throw new Error(`API returned status ${response.responseCode}`);
      }

      const raw: object = JSON.parse(response.result as string) as object;
      const result: StyleAdvice = this.validateAdvice(raw);
      return result;
    } finally {
      httpRequest.destroy();
    }
  }

  private validateAdvice(raw: object): StyleAdvice {
    const data = raw as Record<string, unknown>;

    const overallScore = typeof data['overallScore'] === 'number' ? data['overallScore'] as number : 0;
    const styleMatch = typeof data['styleMatch'] === 'number' ? data['styleMatch'] as number : 0;
    const compositionAdvice = typeof data['compositionAdvice'] === 'string' ? data['compositionAdvice'] as string : '';
    const poseAdvice = typeof data['poseAdvice'] === 'string' ? data['poseAdvice'] as string : '';
    const rawSuggestions = Array.isArray(data['suggestions']) ? data['suggestions'] as unknown[] : [];
    const suggestions: string[] = rawSuggestions
      .filter((item: unknown): boolean => typeof item === 'string')
      .map((item: unknown): string => item as string);

    return {
      overallScore: Math.max(0, Math.min(100, Math.round(overallScore))),
      styleMatch: Math.max(0, Math.min(100, Math.round(styleMatch))),
      compositionAdvice,
      poseAdvice,
      suggestions,
    };
  }
}
