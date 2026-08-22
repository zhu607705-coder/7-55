/**
 * Stable identity for the approved Chapter 4 exterior closing material.
 *
 * Task 13 deliberately leaves the active reference unset until the existing
 * “灿若星辰” asset and its real consumer can be identified. A generated image,
 * another chapter's closing frame, or an arbitrary callback must never fill
 * this slot.
 */
export interface ChapterFourClosureAssetReference {
  assetId: string;
  sourcePath: string;
  sequenceId: string;
  consumerModule: string;
  coordinateSpace: Readonly<{ width: number; height: number }>;
  lampTarget: Readonly<{
    targetId: string;
    entityId: string;
    bounds: Readonly<{ x: number; y: number; width: number; height: number }>;
  }>;
}

/** Completion receipt returned by the approved exterior consumer. */
export interface ChapterFourClosureSessionProof {
  assetId: string;
  sequenceId: string;
  consumerModule: string;
  sessionId: string;
  completionEventId: string;
}

/**
 * The controller accepts a closing acknowledgement only through a verifier
 * owned by the approved consumer. Shape validation alone is insufficient:
 * the verifier must also know that the named session reached its completion
 * callback exactly once.
 */
export interface ChapterFourClosureSessionVerifier {
  readonly reference: ChapterFourClosureAssetReference | null;
  verifyCompletedSession(proof: ChapterFourClosureSessionProof): boolean;
}

export const CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE:
  ChapterFourClosureAssetReference | null = null;

export const BLOCKED_CHAPTER_FOUR_CLOSURE_SESSION_VERIFIER:
  ChapterFourClosureSessionVerifier = Object.freeze({
    reference: CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE,
    verifyCompletedSession: (_proof: ChapterFourClosureSessionProof) => false
  });

export function isChapterFourClosureSessionProof(
  value: unknown
): value is ChapterFourClosureSessionProof {
  if (!isRecord(value)) return false;
  const keys = Object.keys(value).sort();
  const expected = [
    "assetId",
    "completionEventId",
    "consumerModule",
    "sequenceId",
    "sessionId"
  ];
  if (keys.length !== expected.length || keys.some((key, index) => key !== expected[index])) {
    return false;
  }
  return expected.every((key) => isNonEmptyTrimmedString(value[key]));
}

export function closureProofMatchesReference(
  proof: ChapterFourClosureSessionProof,
  reference: ChapterFourClosureAssetReference
): boolean {
  return proof.assetId === reference.assetId
    && proof.sequenceId === reference.sequenceId
    && proof.consumerModule === reference.consumerModule;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNonEmptyTrimmedString(value: unknown): value is string {
  return typeof value === "string" && value.length > 0 && value === value.trim();
}
