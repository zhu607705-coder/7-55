import type {
  LibraryEvidenceId,
  LibraryFinalsAuditValues,
  LibraryFinalsBdPostId,
  LibraryFinalsBdReplyId,
  LibraryRecoveryEvidenceId
} from "../../core/types";
import puzzleConfig from "../../data/library-finals.puzzle.json";

export interface LibraryFinalsPuzzleConfigView {
  readonly targetSeat: string;
  readonly threadFloorCount: number;
  readonly optionalAc01Count: number;
  readonly catalogQuery: string;
  readonly callNumber: string;
  readonly photoMaxBrightness: number;
  readonly bdPasswordPostIds: readonly LibraryFinalsBdPostId[];
  readonly audit: Readonly<LibraryFinalsAuditValues>;
  readonly requiredEvidence: readonly LibraryEvidenceId[];
  readonly recoveryEvidence: readonly LibraryRecoveryEvidenceId[];
}

const EVIDENCE_IDS = new Set<LibraryEvidenceId>([
  "archived_leave_rule",
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
]);
const RECOVERY_EVIDENCE_IDS = new Set<LibraryRecoveryEvidenceId>([
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
]);
const BD_POST_IDS = new Set<LibraryFinalsBdPostId>([
  "bd-notice-tens",
  "bd-rule-count",
  "bd-rank-first",
  "bd-identity-zero",
  "bd-call-number-tail",
  "bd-seat-tail",
  "bd-reply-count",
  "bd-arrival-minutes"
]);

function positiveInteger(value: number, field: string): number {
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`library-finals.puzzle.json contains an invalid ${field}`);
  }
  return value;
}

function evidenceList(values: readonly string[]): readonly LibraryEvidenceId[] {
  if (!values.every((value) => EVIDENCE_IDS.has(value as LibraryEvidenceId))) {
    throw new Error("library-finals.puzzle.json contains invalid requiredEvidence");
  }
  return Object.freeze(values as LibraryEvidenceId[]);
}

function recoveryEvidenceList(values: readonly string[]): readonly LibraryRecoveryEvidenceId[] {
  if (!values.every((value) => RECOVERY_EVIDENCE_IDS.has(value as LibraryRecoveryEvidenceId))) {
    throw new Error("library-finals.puzzle.json contains invalid recoveryEvidence");
  }
  return Object.freeze(values as LibraryRecoveryEvidenceId[]);
}

function bdPasswordPostList(values: readonly string[]): readonly LibraryFinalsBdPostId[] {
  if (values.length !== 4 || !values.every((value) => BD_POST_IDS.has(value as LibraryFinalsBdPostId))) {
    throw new Error("library-finals.puzzle.json contains an invalid bdPasswordPostIds");
  }
  return Object.freeze(values as LibraryFinalsBdPostId[]);
}

export const LIBRARY_FINALS_PUZZLE_CONFIG: LibraryFinalsPuzzleConfigView = Object.freeze({
  targetSeat: puzzleConfig.targetSeat,
  threadFloorCount: positiveInteger(puzzleConfig.threadFloorCount, "threadFloorCount"),
  optionalAc01Count: positiveInteger(puzzleConfig.optionalAc01Count, "optionalAc01Count"),
  catalogQuery: puzzleConfig.catalogQuery,
  callNumber: puzzleConfig.callNumber,
  photoMaxBrightness: puzzleConfig.photoMaxBrightness,
  bdPasswordPostIds: bdPasswordPostList(puzzleConfig.bdPasswordPostIds),
  audit: Object.freeze({ ...puzzleConfig.audit }),
  requiredEvidence: evidenceList(puzzleConfig.requiredEvidence),
  recoveryEvidence: recoveryEvidenceList(puzzleConfig.recoveryEvidence)
});

export const LIBRARY_FINALS_VALID_BD_REPLY_IDS = Object.freeze([
  "reply-seat-ticket",
  "reply-visit-proof",
  "reply-bag-nonperson"
] as const satisfies readonly LibraryFinalsBdReplyId[]);

export function isLibraryFinalsBdReplyId(value: string): value is LibraryFinalsBdReplyId {
  return LIBRARY_FINALS_VALID_BD_REPLY_IDS.includes(value as LibraryFinalsBdReplyId);
}

export function isLibraryFinalsBdPostId(value: string): value is LibraryFinalsBdPostId {
  return BD_POST_IDS.has(value as LibraryFinalsBdPostId);
}

export function validateBdPassword(values: readonly LibraryFinalsBdPostId[]): boolean {
  const expected = LIBRARY_FINALS_PUZZLE_CONFIG.bdPasswordPostIds;
  return values.length === expected.length && expected.every((value, index) => values[index] === value);
}

export function isLibraryEvidenceId(value: string): value is LibraryEvidenceId {
  return EVIDENCE_IDS.has(value as LibraryEvidenceId);
}

export function isLibraryRecoveryEvidenceId(value: string): value is LibraryRecoveryEvidenceId {
  return RECOVERY_EVIDENCE_IDS.has(value as LibraryRecoveryEvidenceId);
}

export function hasAllEvidence(values: readonly LibraryEvidenceId[]): boolean {
  return LIBRARY_FINALS_PUZZLE_CONFIG.requiredEvidence.every((value) => values.includes(value));
}

export function hasRecoveryEvidence(values: readonly LibraryRecoveryEvidenceId[]): boolean {
  return LIBRARY_FINALS_PUZZLE_CONFIG.recoveryEvidence.every((value) => values.includes(value));
}

export function validateAudit(values: Readonly<LibraryFinalsAuditValues>): boolean {
  const expected = LIBRARY_FINALS_PUZZLE_CONFIG.audit;
  return values.arrivalMinutes === expected.arrivalMinutes
    && values.publicNoticeFloor === expected.publicNoticeFloor
    && values.proofCount === expected.proofCount;
}

export function isPhotoReadable(brightness: number): boolean {
  return Number.isFinite(brightness) && brightness <= LIBRARY_FINALS_PUZZLE_CONFIG.photoMaxBrightness;
}

export function normalizeCatalogQuery(value: string): string {
  return value
    .normalize("NFKC")
    .trim()
    .toLowerCase()
    .replace(/[\s·•・—–_.,，。:：;；'"“”‘’《》<>（）()\[\]【】/\\-]+/gu, "");
}

export function isCatalogClueQuery(value: string): boolean {
  const query = normalizeCatalogQuery(value);
  const expected = normalizeCatalogQuery(LIBRARY_FINALS_PUZZLE_CONFIG.catalogQuery);
  return query === expected || query.startsWith(expected);
}
