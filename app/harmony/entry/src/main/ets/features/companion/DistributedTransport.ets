import { distributedKVStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

import { SessionMessageEnvelope } from '../../core/session/SessionMessage';
import { serializeSessionMessage, deserializeSessionMessage } from '../../core/session/SessionSerializer';

const KV_STORE_ID: string = 'easy_shot_session';
const MESSAGE_KEY_PREFIX: string = 'msg_';
const MAX_STORED_MESSAGES: number = 50;

export type OnRemoteMessageCallback = (message: SessionMessageEnvelope<object>) => void;

export class DistributedTransport {
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private onRemoteMessage: OnRemoteMessageCallback | null = null;
  private isInitialized: boolean = false;
  private localDeviceId: string = '';
  private messageSeq: number = 0;

  async initialize(context: Context): Promise<boolean> {
    try {
      const config: distributedKVStore.KVManagerConfig = {
        bundleName: 'com.easyshot.app',
        context,
      };
      this.kvManager = distributedKVStore.createKVManager(config);

      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: true,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1,
      };
      this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(KV_STORE_ID, options);

      this.localDeviceId = 'local_' + Date.now().toString();
      this.subscribeRemoteChanges();
      this.isInitialized = true;
      return true;
    } catch (_error) {
      this.isInitialized = false;
      return false;
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.kvStore !== null;
  }

  setOnRemoteMessage(callback: OnRemoteMessageCallback | null): void {
    this.onRemoteMessage = callback;
  }

  async sendMessage<T>(message: SessionMessageEnvelope<T>): Promise<boolean> {
    if (this.kvStore === null) {
      return false;
    }

    try {
      this.messageSeq++;
      const key: string = MESSAGE_KEY_PREFIX + this.localDeviceId + '_' + this.messageSeq.toString();
      const value: string = serializeSessionMessage(message);
      await this.kvStore.put(key, value);
      await this.pruneOldMessages();
      return true;
    } catch (_error) {
      return false;
    }
  }

  private async pruneOldMessages(): Promise<void> {
    if (this.kvStore === null) {
      return;
    }
    try {
      const allEntries = await this.kvStore.getEntries(MESSAGE_KEY_PREFIX + this.localDeviceId);
      if (allEntries.length > MAX_STORED_MESSAGES) {
        const toDelete = allEntries.slice(0, allEntries.length - MAX_STORED_MESSAGES);
        for (const entry of toDelete) {
          await this.kvStore.delete(entry.key.toString());
        }
      }
    } catch (_error) {
      // ignore prune errors
    }
  }

  async cleanup(): Promise<void> {
    if (this.kvStore !== null) {
      try {
        this.kvStore.off('dataChange');
      } catch (_error) {
        // ignore cleanup errors
      }
    }

    if (this.kvManager !== null) {
      try {
        await this.kvManager.closeKVStore('com.easyshot.app', KV_STORE_ID);
      } catch (_error) {
        // ignore cleanup errors
      }
    }

    this.kvStore = null;
    this.kvManager = null;
    this.isInitialized = false;
  }

  private subscribeRemoteChanges(): void {
    if (this.kvStore === null) {
      return;
    }

    this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE, (changeData) => {
      if (this.onRemoteMessage === null) {
        return;
      }

      const insertEntries: distributedKVStore.Entry[] = changeData.insertEntries;
      const updateEntries: distributedKVStore.Entry[] = changeData.updateEntries;
      const allEntries: distributedKVStore.Entry[] = [...insertEntries, ...updateEntries];

      for (const entry of allEntries) {
        const key: string = entry.key.toString();
        if (!key.startsWith(MESSAGE_KEY_PREFIX)) {
          continue;
        }

        const raw: string = entry.value.value as string;
        if (typeof raw !== 'string') {
          continue;
        }
        const parsed: SessionMessageEnvelope<object> | null = deserializeSessionMessage<object>(raw);
        if (parsed !== null) {
          this.onRemoteMessage(parsed);
        }
      }
    });
  }
}

export const distributedTransport: DistributedTransport = new DistributedTransport();
