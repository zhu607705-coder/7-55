import type { ChapterThreeInterludeVoiceCandidateId } from "../data/chapter3InterludeContent";

export type ChapterThreeInterludeVoiceDraftStage = "selection" | "ordering";

export interface ChapterThreeInterludeVoiceDraft {
  stage: ChapterThreeInterludeVoiceDraftStage;
  heardIds: ChapterThreeInterludeVoiceCandidateId[];
  selectedIds: ChapterThreeInterludeVoiceCandidateId[];
  orderedIds: ChapterThreeInterludeVoiceCandidateId[];
}

interface StoredChapterThreeInterludeVoiceDraft extends ChapterThreeInterludeVoiceDraft {
  schemaVersion: number;
  manifestVersion: string;
}

interface ChapterThreeInterludeVoiceDraftContext {
  manifestVersion: string | number;
  candidateIds: readonly ChapterThreeInterludeVoiceCandidateId[];
  storage?: Storage;
}

export const CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY =
  "seven-fifty-five.chapter-three-interlude.voice-draft";
export const CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_SCHEMA_VERSION = 1;

function resolveStorage(storage?: Storage): Storage | null {
  if (storage) return storage;
  if (typeof window === "undefined") return null;
  try {
    return window.sessionStorage;
  } catch {
    return null;
  }
}

function uniqueCandidateIds(
  value: unknown,
  allowedIds: ReadonlySet<ChapterThreeInterludeVoiceCandidateId>
): ChapterThreeInterludeVoiceCandidateId[] {
  if (!Array.isArray(value)) return [];
  const seen = new Set<ChapterThreeInterludeVoiceCandidateId>();
  const normalized: ChapterThreeInterludeVoiceCandidateId[] = [];
  for (const item of value) {
    if (typeof item !== "string") continue;
    const id = item as ChapterThreeInterludeVoiceCandidateId;
    if (!allowedIds.has(id) || seen.has(id)) continue;
    seen.add(id);
    normalized.push(id);
  }
  return normalized;
}

function sameMembers(
  left: readonly ChapterThreeInterludeVoiceCandidateId[],
  right: readonly ChapterThreeInterludeVoiceCandidateId[]
): boolean {
  return left.length === right.length && left.every((id) => right.includes(id));
}

function normalizeDraft(
  value: unknown,
  candidateIds: readonly ChapterThreeInterludeVoiceCandidateId[]
): ChapterThreeInterludeVoiceDraft | null {
  if (!value || typeof value !== "object") return null;
  const draft = value as Partial<ChapterThreeInterludeVoiceDraft>;
  if (draft.stage !== "selection" && draft.stage !== "ordering") return null;

  const allowedIds = new Set(candidateIds);
  const heardIds = uniqueCandidateIds(draft.heardIds, allowedIds);
  const heardSet = new Set(heardIds);
  const selectedIds = uniqueCandidateIds(draft.selectedIds, allowedIds)
    .filter((id) => heardSet.has(id))
    .slice(0, 4);
  const selectedSet = new Set(selectedIds);
  const orderedIds = uniqueCandidateIds(draft.orderedIds, allowedIds)
    .filter((id) => selectedSet.has(id))
    .slice(0, 4);
  const orderingIsRestorable = selectedIds.length === 4
    && orderedIds.length === 4
    && sameMembers(orderedIds, selectedIds);

  return {
    stage: draft.stage === "ordering" && orderingIsRestorable ? "ordering" : "selection",
    heardIds,
    selectedIds,
    orderedIds
  };
}

export function loadChapterThreeInterludeVoiceDraft(
  context: ChapterThreeInterludeVoiceDraftContext
): ChapterThreeInterludeVoiceDraft | null {
  const storage = resolveStorage(context.storage);
  if (!storage) return null;
  try {
    const raw = storage.getItem(CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY);
    if (!raw) return null;
    const stored = JSON.parse(raw) as Partial<StoredChapterThreeInterludeVoiceDraft>;
    if (stored.schemaVersion !== CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_SCHEMA_VERSION
      || stored.manifestVersion !== String(context.manifestVersion)) {
      storage.removeItem(CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY);
      return null;
    }
    const normalized = normalizeDraft(stored, context.candidateIds);
    if (!normalized) {
      storage.removeItem(CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY);
      return null;
    }
    return normalized;
  } catch {
    try {
      storage.removeItem(CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY);
    } catch {
      // Session storage is optional; a denied write must not block the puzzle.
    }
    return null;
  }
}

export function saveChapterThreeInterludeVoiceDraft(
  draft: ChapterThreeInterludeVoiceDraft,
  context: ChapterThreeInterludeVoiceDraftContext
): boolean {
  const storage = resolveStorage(context.storage);
  if (!storage) return false;
  const normalized = normalizeDraft(draft, context.candidateIds);
  if (!normalized) return false;
  const stored: StoredChapterThreeInterludeVoiceDraft = {
    schemaVersion: CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_SCHEMA_VERSION,
    manifestVersion: String(context.manifestVersion),
    ...normalized
  };
  try {
    storage.setItem(CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY, JSON.stringify(stored));
    return true;
  } catch {
    return false;
  }
}

export function clearChapterThreeInterludeVoiceDraft(storage?: Storage): void {
  const resolved = resolveStorage(storage);
  if (!resolved) return;
  try {
    resolved.removeItem(CHAPTER_THREE_INTERLUDE_VOICE_DRAFT_STORAGE_KEY);
  } catch {
    // Session storage is optional; clearing failure must not block story reset.
  }
}
