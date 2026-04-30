import { http } from '@kit.NetworkKit';
import { StyleAdvice, StyleAdviceRequest } from './StyleAdviceModel';
import { StyleAdviceClient } from './StyleAdviceClient';

const DEFAULT_API_BASE: string = 'https://api.easyshot.example.com/v1';
const REQUEST_TIMEOUT_MS: number = 15000;

export class CloudStyleAdviceClient implements StyleAdviceClient {
  private apiBase: string;

  constructor(apiBase: string = DEFAULT_API_BASE) {
    this.apiBase = apiBase;
  }

  async fetchAdvice(request: StyleAdviceRequest): Promise<StyleAdvice> {
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

      const result: StyleAdvice = JSON.parse(response.result as string) as StyleAdvice;
      return result;
    } finally {
      httpRequest.destroy();
    }
  }
}
