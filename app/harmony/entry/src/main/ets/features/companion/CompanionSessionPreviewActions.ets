import { PreviewMode } from '../../core/session/SessionState';
import { PoseTemplate } from '../poseTemplate/model/PoseTemplate';

export type CompanionPreviewHintKind = 'none' | 'thumbnail' | 'state_only';

export function deriveCompanionPreviewHintKind(previewMode: PreviewMode): CompanionPreviewHintKind {
  switch (previewMode) {
    case PreviewMode.THUMBNAIL:
      return 'thumbnail';
    case PreviewMode.STATE_ONLY:
      return 'state_only';
    default:
      return 'none';
  }
}

export function buildCompanionPreviewSyncParams(
  selectedTemplateIndex: number,
  templates: PoseTemplate[],
  guideStateTemplateId: string,
): Record<string, string> {
  const preferredTemplate = templates[selectedTemplateIndex] ?? templates[0];
  const fallbackTemplateId = guideStateTemplateId !== 'unselected' ? guideStateTemplateId : '';
  const templateId = preferredTemplate?.id ?? fallbackTemplateId;
  const params: Record<string, string> = {};
  if (templateId.length > 0) {
    params.templateId = templateId;
  }
  return params;
}
