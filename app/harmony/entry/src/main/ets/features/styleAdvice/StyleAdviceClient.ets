import { StyleAdvice, StyleAdviceRequest } from './StyleAdviceModel';

export interface StyleAdviceClient {
  fetchAdvice(request: StyleAdviceRequest): Promise<StyleAdvice>;
}
