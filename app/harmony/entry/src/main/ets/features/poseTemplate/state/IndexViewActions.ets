import { Difficulty, PoseTemplate } from '../model/PoseTemplate';

export interface IndexFilterOptions {
  readonly styles: string[];
  readonly scenes: string[];
}

export function buildIndexFilterOptions(templates: PoseTemplate[]): IndexFilterOptions {
  const styles: Set<string> = new Set<string>();
  const scenes: Set<string> = new Set<string>();
  for (const template of templates) {
    for (const style of template.styleTags) {
      styles.add(style);
    }
    for (const scene of template.sceneTags) {
      scenes.add(scene);
    }
  }

  return {
    styles: Array.from(styles),
    scenes: Array.from(scenes),
  };
}

export function filterIndexTemplates(
  templates: PoseTemplate[],
  filterStyle: string,
  filterScene: string,
  filterDifficulty: string,
  allFilter: string,
): PoseTemplate[] {
  return templates.filter((template: PoseTemplate): boolean => {
    if (filterStyle !== allFilter && !template.styleTags.includes(filterStyle)) {
      return false;
    }
    if (filterScene !== allFilter && !template.sceneTags.includes(filterScene)) {
      return false;
    }
    if (filterDifficulty !== allFilter && template.difficulty !== filterDifficulty as Difficulty) {
      return false;
    }
    return true;
  });
}
