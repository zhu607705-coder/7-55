import { describe, expect, it } from "vitest";
import puzzleConfig from "../../data/library-finals.puzzle.json";
import {
  hasAllEvidence,
  hasRecoveryEvidence,
  isCatalogClueQuery,
  isLibraryEvidenceId,
  isLibraryFinalsBdReplyId,
  isLibraryRecoveryEvidenceId,
  isPhotoReadable,
  LIBRARY_FINALS_PUZZLE_CONFIG,
  LIBRARY_FINALS_VALID_BD_REPLY_IDS,
  normalizeCatalogQuery,
  validateAudit
} from "./puzzleRules";

describe("library finals V2 puzzle rules", () => {
  it("uses the JSON contract for seat 022, 23 floors, five optional ac01 and the correct catalog book", () => {
    expect(LIBRARY_FINALS_PUZZLE_CONFIG).toMatchObject({
      targetSeat: "022",
      threadFloorCount: 23,
      optionalAc01Count: 5,
      catalogQuery: "三分钟离座法",
      callNumber: "I247.55 / 755",
      photoMaxBrightness: 20,
      bdRequired: 3,
      audit: { arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 }
    });
    expect(LIBRARY_FINALS_PUZZLE_CONFIG.requiredEvidence).toEqual(puzzleConfig.requiredEvidence);
    expect(LIBRARY_FINALS_PUZZLE_CONFIG.recoveryEvidence).toEqual(puzzleConfig.recoveryEvidence);
  });

  it("normalizes catalog punctuation and accepts the clue title with its authored suffix", () => {
    expect(normalizeCatalogQuery("《 三分钟离座法 及其例外 》")).toBe("三分钟离座法及其例外");
    expect(isCatalogClueQuery("三分钟离座法")).toBe(true);
    expect(isCatalogClueQuery("《三分钟离座法及其例外》")).toBe(true);
    expect(isCatalogClueQuery("三分钟")).toBe(false);
    expect(isCatalogClueQuery("三分钟离席法")).toBe(false);
  });

  it("recognizes exactly four public evidence types and three recovery evidence types", () => {
    const allEvidence = [
      "archived_leave_rule",
      "bag_non_person_proof",
      "seat_022_receipt",
      "library_presence_proof"
    ] as const;
    allEvidence.forEach((value) => expect(isLibraryEvidenceId(value)).toBe(true));
    expect(isLibraryEvidenceId("route_screenshot")).toBe(false);
    expect(hasAllEvidence([...allEvidence])).toBe(true);
    expect(hasAllEvidence(allEvidence.slice(0, 3))).toBe(false);

    const recoveryEvidence = [
      "bag_non_person_proof",
      "seat_022_receipt",
      "library_presence_proof"
    ] as const;
    recoveryEvidence.forEach((value) => expect(isLibraryRecoveryEvidenceId(value)).toBe(true));
    expect(isLibraryRecoveryEvidenceId("archived_leave_rule")).toBe(false);
    expect(hasRecoveryEvidence([...recoveryEvidence])).toBe(true);
    expect(hasRecoveryEvidence(recoveryEvidence.slice(0, 2))).toBe(false);
  });

  it("accepts only A/C/E bd reply IDs", () => {
    expect(LIBRARY_FINALS_VALID_BD_REPLY_IDS).toEqual([
      "reply-seat-ticket",
      "reply-visit-proof",
      "reply-bag-nonperson"
    ]);
    LIBRARY_FINALS_VALID_BD_REPLY_IDS.forEach((value) => expect(isLibraryFinalsBdReplyId(value)).toBe(true));
    expect(isLibraryFinalsBdReplyId("reply-route")).toBe(false);
    expect(isLibraryFinalsBdReplyId("ac01")).toBe(false);
  });

  it("requires the presence-proof values 7 / 47 / 3", () => {
    expect(validateAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 })).toBe(true);
    expect(validateAudit({ arrivalMinutes: 6, publicNoticeFloor: 47, proofCount: 3 })).toBe(false);
    expect(validateAudit({ arrivalMinutes: 7, publicNoticeFloor: 23, proofCount: 3 })).toBe(false);
    expect(validateAudit({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 2 })).toBe(false);
  });

  it("reveals the backpack label only at or below the configured brightness threshold", () => {
    expect(isPhotoReadable(21)).toBe(false);
    expect(isPhotoReadable(20)).toBe(true);
    expect(isPhotoReadable(0)).toBe(true);
    expect(isPhotoReadable(Number.NaN)).toBe(false);
  });
});
