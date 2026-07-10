import { describe, expect, it } from '@ohos/hypium';

import { PhotoHistoryEntry, PhotoHistoryService } from '../../../main/ets/features/history/PhotoHistoryService';

interface FakePreferencesLike {
  putSync(key: string, value: string): void;
  flush(callback: () => void): void;
}

function createEntry(
  id: string,
  alignmentScore: number,
  timestamp: number,
  mediaType: string = 'photo',
): PhotoHistoryEntry {
  return {
    id,
    photoPath: `/tmp/${id}`,
    templateId: 'template-1',
    templateTitle: 'Template One',
    alignmentScore,
    timestamp,
    latitude: 0,
    longitude: 0,
    mediaType,
  };
}

export default function photoHistoryServiceTest(): void {
  describe('PhotoHistoryService', () => {
    it('excludes video entries from score statistics', 0, () => {
      const service = new PhotoHistoryService() as PhotoHistoryService & { entries: PhotoHistoryEntry[] };
      service.entries = [
        createEntry('photo-a', 0.9, 1, 'photo'),
        createEntry('video-a', 0, 2, 'video'),
        createEntry('photo-b', 0.6, 3, 'photo'),
      ];

      const stats = service.getStats();

      expect(stats.totalPhotos).assertEqual(3);
      expect(stats.averageScore).assertEqual(0.75);
      expect(stats.bestScore).assertEqual(0.9);
    });

    it('falls back to zero scores when only videos exist', 0, () => {
      const service = new PhotoHistoryService() as PhotoHistoryService & { entries: PhotoHistoryEntry[] };
      service.entries = [
        createEntry('video-a', 0, 1, 'video'),
        createEntry('video-b', 0, 2, 'video'),
      ];

      const stats = service.getStats();

      expect(stats.totalPhotos).assertEqual(2);
      expect(stats.averageScore).assertEqual(0);
      expect(stats.bestScore).assertEqual(0);
    });

    it('addEntry returns false when preferences are unavailable', 0, () => {
      const service = new PhotoHistoryService() as PhotoHistoryService & {
        entries: PhotoHistoryEntry[];
        prefs: FakePreferencesLike | null;
      };
      service.entries = [];
      service.prefs = null;

      const persisted = service.addEntry(createEntry('photo-a', 0.8, 1));

      expect(persisted).assertFalse();
      expect(service.entries.length).assertEqual(1);
    });

    it('addEntry returns true after persisting to preferences', 0, () => {
      let storedValue = '';
      let flushed = false;
      const service = new PhotoHistoryService() as PhotoHistoryService & {
        entries: PhotoHistoryEntry[];
        prefs: FakePreferencesLike | null;
      };
      service.entries = [];
      service.prefs = {
        putSync: (_key: string, value: string) => {
          storedValue = value;
        },
        flush: (callback: () => void) => {
          flushed = true;
          callback();
        },
      };

      const persisted = service.addEntry(createEntry('photo-b', 0.9, 2));

      expect(persisted).assertTrue();
      expect(storedValue.includes('photo-b')).assertTrue();
      expect(flushed).assertTrue();
    });
  });
}
