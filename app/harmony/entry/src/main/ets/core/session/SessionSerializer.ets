import { SessionMessageEnvelope } from './SessionMessage';

export function serializeSessionMessage<T>(message: SessionMessageEnvelope<T>): string {
  return JSON.stringify(message);
}

export function deserializeSessionMessage<T>(raw: string): SessionMessageEnvelope<T> | null {
  try {
    return JSON.parse(raw) as SessionMessageEnvelope<T>;
  } catch (_error) {
    return null;
  }
}
