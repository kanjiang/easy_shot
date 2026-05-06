import { distributedDeviceManager } from '@kit.DistributedServiceKit';

import { companionSessionService } from './CompanionSessionService';
import { SessionPhase, createIdleSessionState, SessionState } from '../../core/session/SessionState';

const RECONNECT_MAX_ATTEMPTS: number = 5;
const RECONNECT_BASE_DELAY_MS: number = 1000;
const RECONNECT_MAX_DELAY_MS: number = 16000;

export enum ReconnectStatus {
  IDLE = 'idle',
  ATTEMPTING = 'attempting',
  SUCCEEDED = 'succeeded',
  FAILED = 'failed',
}

export interface ReconnectState {
  status: ReconnectStatus;
  attempt: number;
  maxAttempts: number;
  lastPeerDeviceId: string;
}

export class SessionReconnectService {
  private status: ReconnectStatus = ReconnectStatus.IDLE;
  private attempt: number = 0;
  private lastPeerDeviceId: string = '';
  private lastPeerDeviceName: string = '';
  private timerId: number = -1;
  private onStatusChange: ((state: ReconnectState) => void) | null = null;

  setOnStatusChange(cb: (state: ReconnectState) => void): void {
    this.onStatusChange = cb;
  }

  getState(): ReconnectState {
    return {
      status: this.status,
      attempt: this.attempt,
      maxAttempts: RECONNECT_MAX_ATTEMPTS,
      lastPeerDeviceId: this.lastPeerDeviceId,
    };
  }

  onDisconnected(peerDeviceId: string, peerDeviceName: string): void {
    this.lastPeerDeviceId = peerDeviceId;
    this.lastPeerDeviceName = peerDeviceName;
    this.attempt = 0;
    this.scheduleReconnect();
  }

  cancel(): void {
    clearTimeout(this.timerId);
    this.status = ReconnectStatus.IDLE;
    this.attempt = 0;
    this.notifyChange();
  }

  private scheduleReconnect(): void {
    if (this.attempt >= RECONNECT_MAX_ATTEMPTS) {
      this.status = ReconnectStatus.FAILED;
      this.notifyChange();
      return;
    }

    this.status = ReconnectStatus.ATTEMPTING;
    this.attempt++;
    this.notifyChange();

    const delay = Math.min(
      RECONNECT_BASE_DELAY_MS * Math.pow(2, this.attempt - 1),
      RECONNECT_MAX_DELAY_MS
    );

    this.timerId = setTimeout(() => {
      this.tryReconnect();
    }, delay);
  }

  private tryReconnect(): void {
    // Check if the peer device is visible again
    const sessionState: SessionState = companionSessionService.getSessionState();
    if (sessionState.isConnected && sessionState.peerDeviceId === this.lastPeerDeviceId) {
      this.status = ReconnectStatus.SUCCEEDED;
      this.notifyChange();
      return;
    }

    // Attempt to reconnect by triggering pairing to the known device
    companionSessionService.connectToDevice(this.lastPeerDeviceId, this.lastPeerDeviceName);

    // Check after a short timeout if connection succeeded
    setTimeout(() => {
      const state = companionSessionService.getSessionState();
      if (state.isConnected && state.peerDeviceId === this.lastPeerDeviceId) {
        this.status = ReconnectStatus.SUCCEEDED;
        this.notifyChange();
      } else {
        this.scheduleReconnect();
      }
    }, 2000);
  }

  private notifyChange(): void {
    if (this.onStatusChange !== null) {
      this.onStatusChange(this.getState());
    }
  }
}

export const sessionReconnectService = new SessionReconnectService();
