import { describe, expect, it } from '@ohos/hypium';

import { SessionPhase, SessionRole } from '../../../main/ets/core/session/SessionState';
import { CompanionSessionService } from '../../../main/ets/features/companion/CompanionSessionService';

export default function remoteShutterTest(): void {
  describe('RemoteShutter', () => {
    it('remote shutter fires capture callback when in guiding phase', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      service.startHostSession('peer-1', 'Peer Phone');
      service.startGuiding();

      let callbackFired: boolean = false;
      service.onRemoteCapture(() => {
        callbackFired = true;
      });

      const accepted: boolean = service.sendRemoteShutter();

      expect(accepted).assertTrue();
      expect(callbackFired).assertTrue();
      expect(service.getSessionState().phase).assertEqual(SessionPhase.CAPTURING);
    });

    it('remote shutter is rejected when session is idle', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();

      let callbackFired: boolean = false;
      service.onRemoteCapture(() => {
        callbackFired = true;
      });

      const accepted: boolean = service.sendRemoteShutter();

      expect(accepted).assertEqual(false);
      expect(callbackFired).assertEqual(false);
    });

    it('clearing remote capture callback prevents firing', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      service.startHostSession('peer-1', 'Peer Phone');
      service.startGuiding();

      let callbackFired: boolean = false;
      service.onRemoteCapture(() => {
        callbackFired = true;
      });
      service.onRemoteCapture(null);

      service.sendRemoteShutter();

      expect(callbackFired).assertEqual(false);
    });

    it('countdown followed by shutter transitions through phases', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      service.startHostSession('peer-1', 'Peer Phone');
      service.startGuiding();

      const countdownAccepted: boolean = service.sendRemoteCountdown(3);
      expect(countdownAccepted).assertTrue();
      expect(service.getSessionState().phase).assertEqual(SessionPhase.COUNTDOWN);

      let captured: boolean = false;
      service.onRemoteCapture(() => {
        captured = true;
      });

      const shutterAccepted: boolean = service.sendRemoteShutter();
      expect(shutterAccepted).assertTrue();
      expect(captured).assertTrue();
      expect(service.getSessionState().phase).assertEqual(SessionPhase.CAPTURING);
    });
  });
}
