export function selectPrimaryPrompt(candidates: string[]): string {
  if (candidates.length === 0) {
    return 'Move into the frame to start pose guidance.';
  }

  return candidates[0];
}
