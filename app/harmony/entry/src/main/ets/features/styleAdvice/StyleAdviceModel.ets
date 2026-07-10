export interface StyleAdviceRequest {
  templateId: string;
  styleTag: string;
  alignmentScore: number;
  matchedPoints: number;
  totalPoints: number;
  photoBase64?: string;
}

export interface StyleAdvice {
  overallScore: number;
  compositionAdvice: string;
  poseAdvice: string;
  suggestions: string[];
  styleMatch: number;
}

export type StyleAdviceSource = 'cloud' | 'mock';

export type StyleAdviceDeliveryMode =
  | 'cloud'
  | 'local_only'
  | 'cloud_disabled'
  | 'api_unconfigured'
  | 'cloud_failed';

export interface StyleAdviceResolution {
  advice: StyleAdvice;
  source: StyleAdviceSource;
  deliveryMode: StyleAdviceDeliveryMode;
}

export enum StyleAdviceStatus {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error',
}
