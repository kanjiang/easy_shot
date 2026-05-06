import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

export interface PhotoHistoryEntry {
  id: string;
  photoPath: string;
  templateId: string;
  templateTitle: string;
  alignmentScore: number;
  timestamp: number;
  latitude: number;
  longitude: number;
}

export interface PhotoStats {
  totalPhotos: number;
  averageScore: number;
  bestScore: number;
  totalTemplatesUsed: number;
  streakDays: number;
}

const HISTORY_PREFS_NAME: string = 'easy_shot_history';
const MAX_HISTORY: number = 200;

export class PhotoHistoryService {
  private entries: PhotoHistoryEntry[] = [];
  private prefs: preferences.Preferences | null = null;

  initialize(context: Context): void {
    const options: preferences.Options = { name: HISTORY_PREFS_NAME };
    this.prefs = preferences.getPreferencesSync(context, options);
    const raw: string = this.prefs.getSync('entries', '[]') as string;
    try {
      this.entries = JSON.parse(raw) as PhotoHistoryEntry[];
    } catch (_e) {
      this.entries = [];
    }
  }

  addEntry(entry: PhotoHistoryEntry): void {
    this.entries.push(entry);
    if (this.entries.length > MAX_HISTORY) {
      this.entries = this.entries.slice(this.entries.length - MAX_HISTORY);
    }
    this.persist();
  }

  getEntries(): PhotoHistoryEntry[] {
    return [...this.entries];
  }

  getRecentEntries(count: number): PhotoHistoryEntry[] {
    return this.entries.slice(-count).reverse();
  }

  getStats(): PhotoStats {
    if (this.entries.length === 0) {
      return { totalPhotos: 0, averageScore: 0, bestScore: 0, totalTemplatesUsed: 0, streakDays: 0 };
    }

    const scores = this.entries.map((e: PhotoHistoryEntry) => e.alignmentScore);
    const avgScore = scores.reduce((a: number, b: number) => a + b, 0) / scores.length;
    const bestScore = Math.max(...scores);
    const templateIds = new Set(this.entries.map((e: PhotoHistoryEntry) => e.templateId));

    // Calculate streak
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    let streak = 0;
    for (let i = 0; i < 365; i++) {
      const checkDate = new Date(today.getTime() - i * 86400000);
      const dayStart = checkDate.getTime();
      const dayEnd = dayStart + 86400000;
      const hasEntry = this.entries.some((e: PhotoHistoryEntry) => e.timestamp >= dayStart && e.timestamp < dayEnd);
      if (hasEntry) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return {
      totalPhotos: this.entries.length,
      averageScore: avgScore,
      bestScore: bestScore,
      totalTemplatesUsed: templateIds.size,
      streakDays: streak,
    };
  }

  private persist(): void {
    if (this.prefs === null) return;
    this.prefs.putSync('entries', JSON.stringify(this.entries));
    this.prefs.flush(() => {});
  }
}

export const photoHistoryService = new PhotoHistoryService();
