import { describe, expect, it } from '@ohos/hypium';

import { SessionPhase, SessionRole } from '../../../main/ets/core/session/SessionState';
import { CompanionSessionService } from '../../../main/ets/features/companion/CompanionSessionService';

export default function companionSessionServiceTest(): void {
  describe('CompanionSessionService', () => {
    it('discovers devices for host role', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      const devices = service.startDiscovery(SessionRole.HOST);
      const snapshot = service.getSnapshot();

      expect(devices.length > 0).assertTrue();
      expect(snapshot.sessionState.phase).assertEqual(SessionPhase.DISCOVERING);
      expect(snapshot.sessionState.role).assertEqual(SessionRole.HOST);
    });

    it('moves to connected after pairing confirmation', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      const device = service.startDiscovery(SessionRole.HOST)[0];

      service.inviteDevice(device);
      const sessionState = service.confirmPairing();

      expect(sessionState.phase).assertEqual(SessionPhase.CONNECTED);
      expect(sessionState.isConnected).assertTrue();
    });

    it('enters guiding and updates prompt', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      service.startHostSession('mock-peer', 'Mock Peer');
      const guideState = service.startGuiding();

      expect(service.getSessionState().phase).assertEqual(SessionPhase.GUIDING);
      expect(guideState.templateId).assertEqual('pose_sweet_scissors_cheek_v1');
      expect(guideState.primaryPrompt.length > 0).assertTrue();
    });

    it('transitions to countdown and capturing from remote commands', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();
      service.startHostSession('mock-peer', 'Mock Peer');
      service.startGuiding();

      const countdownAccepted = service.sendRemoteCountdown(3);
      const shutterAccepted = service.sendRemoteShutter();
      const snapshot = service.getSnapshot();

      expect(countdownAccepted).assertTrue();
      expect(shutterAccepted).assertTrue();
      expect(snapshot.sessionState.phase).assertEqual(SessionPhase.CAPTURING);
      expect(snapshot.recentEvents.length > 0).assertTrue();
    });

    it('connectToDevice restores a connected session snapshot', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();

      service.connectToDevice('ble-peer-1', 'BLE Peer');
      const snapshot = service.getSnapshot();

      expect(snapshot.sessionState.peerDeviceId).assertEqual('ble-peer-1');
      expect(snapshot.sessionState.peerDeviceName).assertEqual('BLE Peer');
      expect(snapshot.sessionState.phase).assertEqual(SessionPhase.CONNECTED);
      expect(snapshot.sessionState.isConnected).assertTrue();
      expect(snapshot.sessionState.sessionId.length > 0).assertTrue();
    });

    it('stores review sync summary and enters review phase', 0, () => {
      const service: CompanionSessionService = new CompanionSessionService();

      service.startHostSession('mock-peer', 'Mock Peer');
      const accepted = service.sendReviewSync({
        templateId: 'pose-1',
        templateTitle: 'Pose One',
        styleTag: 'sweet_daily',
        alignmentScore: 0.92,
        matchedPoints: 15,
        totalPoints: 17,
        captureTimestamp: 1710000000000,
        retakeHint: 'Lift the right shoulder slightly.',
        thumbnailBase64: 'mock-thumb',
      });
      const snapshot = service.getSnapshot();

      expect(accepted).assertTrue();
      expect(snapshot.sessionState.phase).assertEqual(SessionPhase.REVIEW_SYNC);
      expect(snapshot.reviewSync !== null).assertTrue();
      expect(snapshot.reviewSync?.templateTitle).assertEqual('Pose One');
      expect(snapshot.reviewSync?.matchedPoints).assertEqual(15);
    });
  });
}
