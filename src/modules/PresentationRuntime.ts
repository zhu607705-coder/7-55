import type { PresentationCueKind } from "../data/presentation-cues";

export interface PresentationRuntimeSnapshot {
  cueId: string;
  kind: PresentationCueKind;
  title: string;
  mark: string;
}

let snapshot: PresentationRuntimeSnapshot | null = null;

export function setPresentationRuntimeSnapshot(next: PresentationRuntimeSnapshot | null): void {
  snapshot = next ? { ...next } : null;
}

export function getPresentationRuntimeSnapshot(): PresentationRuntimeSnapshot | null {
  return snapshot ? { ...snapshot } : null;
}
