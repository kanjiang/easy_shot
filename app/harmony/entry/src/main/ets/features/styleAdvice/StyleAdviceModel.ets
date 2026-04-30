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

export enum StyleAdviceStatus {
  IDLE = 'idle',
  LOADING = 'loading',
  SUCCESS = 'success',
  ERROR = 'error',
}
