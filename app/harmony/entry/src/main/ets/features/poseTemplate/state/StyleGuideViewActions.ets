import { PoseTemplate } from '../model/PoseTemplate';

export interface StyleGuideSearchResult {
  readonly matchedTags: string[];
  readonly matchedTemplates: PoseTemplate[];
}

export function matchesStyleGuideTagQuery(
  query: string,
  styleTag: string,
  resolveStyleLabel: (styleValue: string) => string,
): boolean {
  const normalizedQuery: string = query.toLowerCase();
  return styleTag.toLowerCase().includes(normalizedQuery)
    || resolveStyleLabel(styleTag).toLowerCase().includes(normalizedQuery);
}

export function formatStyleGuideMatchedKeywords(
  matchedTags: string[],
  resolveStyleLabel: (styleValue: string) => string,
): string {
  return matchedTags.map((keyword: string) => resolveStyleLabel(keyword)).join(' / ');
}

export function formatStyleGuideTemplateTags(
  template: PoseTemplate,
  resolveStyleLabel: (styleValue: string) => string,
): string {
  return template.styleTags.map((tag: string) => resolveStyleLabel(tag)).concat(template.sceneTags).join(' · ');
}

export function searchStyleGuideTemplates(
  query: string,
  templates: PoseTemplate[],
  resolveStyleLabel: (styleValue: string) => string,
): StyleGuideSearchResult {
  if (query.trim().length === 0) {
    return {
      matchedTags: [],
      matchedTemplates: [],
    };
  }

  const lowerQuery: string = query.toLowerCase();
  const matched: string[] = [];
  for (const template of templates) {
    for (const tag of template.styleTags) {
      if (matchesStyleGuideTagQuery(query, tag, resolveStyleLabel) && !matched.includes(tag)) {
        matched.push(tag);
      }
    }
    for (const tag of template.sceneTags) {
      if (tag.toLowerCase().includes(lowerQuery) && !matched.includes(tag)) {
        matched.push(tag);
      }
    }
  }

  const matchedTemplates: PoseTemplate[] = templates.filter((template: PoseTemplate) => {
    const localizedStyleTags: string = template.styleTags
      .map((tag: string) => resolveStyleLabel(tag))
      .join(' ')
      .toLowerCase();
    const allTags: string = template.styleTags.concat(template.sceneTags).join(' ').toLowerCase();
    return allTags.includes(lowerQuery)
      || localizedStyleTags.includes(lowerQuery)
      || template.title.toLowerCase().includes(lowerQuery)
      || template.description.toLowerCase().includes(lowerQuery);
  });

  return {
    matchedTags: matched.slice(0, 3),
    matchedTemplates,
  };
}
