import { describe, expect, it } from '@ohos/hypium';

import {
  SessionMessageEnvelope,
  SessionMessageType,
  createSessionEnvelope,
  RemoteShutterPayload,
} from '../../../main/ets/core/session/SessionMessage';
import { SessionRole } from '../../../main/ets/core/session/SessionState';
import {
  serializeSessionMessage,
  deserializeSessionMessage,
} from '../../../main/ets/core/session/SessionSerializer';

export default function distributedTransportTest(): void {
  describe('DistributedTransportTest', () => {
    it('serialize_and_deserialize_roundtrip', 0, () => {
      const original: SessionMessageEnvelope<RemoteShutterPayload> = createSessionEnvelope(
        SessionMessageType.REMOTE_SHUTTER,
        'session-42',
        SessionRole.HOST,
        { triggerId: 'trigger-1234' },
      );

      const serialized: string = serializeSessionMessage(original);
      const restored: SessionMessageEnvelope<RemoteShutterPayload> | null =
        deserializeSessionMessage<RemoteShutterPayload>(serialized);

      expect(restored !== null).assertTrue();
      expect(restored!.type).assertEqual(SessionMessageType.REMOTE_SHUTTER);
      expect(restored!.sessionId).assertEqual('session-42');
      expect(restored!.role).assertEqual(SessionRole.HOST);
      expect(restored!.payload.triggerId).assertEqual('trigger-1234');
    });

    it('deserialize_invalid_json_returns_null', 0, () => {
      const result = deserializeSessionMessage<object>('not valid json {{{');
      expect(result).assertNull();
    });

    it('deserialize_empty_string_returns_null', 0, () => {
      const result = deserializeSessionMessage<object>('');
      expect(result).assertNull();
    });

    it('serialized_message_contains_sentAt_timestamp', 0, () => {
      const before: number = Date.now();
      const message = createSessionEnvelope(
        SessionMessageType.GUIDE_STATE_UPDATE,
        'session-99',
        SessionRole.COMPANION,
        { data: 'test' },
      );
      const after: number = Date.now();

      expect(message.sentAt).assertLargerOrEqual(before);
      expect(message.sentAt).assertLessOrEqual(after);

      const serialized: string = serializeSessionMessage(message);
      expect(serialized.includes('"sentAt"')).assertTrue();
    });
  });
}
