import { fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { LibraryEvidenceId } from "../../../core/types";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";
import { TopTenRisePuzzle } from "./TopTenRisePuzzle";

const ALL_EVIDENCE: LibraryEvidenceId[] = [
  "archived_leave_rule",
  "bag_non_person_proof",
  "seat_022_receipt",
  "library_presence_proof"
];

describe("TopTenRisePuzzle V2", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("uploads the four evidence items through V2 controller commands", () => {
    const upload = vi.spyOn(kit.libraryFinals, "uploadEvidence").mockReturnValue(true);
    render(
      <TopTenRisePuzzle
        appliedReplyIds={[]}
        bdCount={0}
        phase="evidence_gathering"
        ownedEvidenceIds={ALL_EVIDENCE}
        uploadedEvidenceIds={[]}
      />
    );

    screen.getAllByRole("button", { name: "上传" }).forEach((button) => fireEvent.click(button));
    expect(upload.mock.calls.map(([evidenceId]) => evidenceId)).toEqual(ALL_EVIDENCE);
    libraryFinalsContent.cc98.evidenceSlots.forEach((slot) => {
      expect(screen.getByText(slot.label)).toBeInTheDocument();
    });
  });

  it("maps only A, C and E to the three accepted bd reply ids", () => {
    const applyBd = vi.spyOn(kit.libraryFinals, "applyBd").mockReturnValue(true);
    render(
      <TopTenRisePuzzle
        appliedReplyIds={[]}
        bdCount={0}
        phase="top_ten_rising"
        ownedEvidenceIds={ALL_EVIDENCE}
        uploadedEvidenceIds={ALL_EVIDENCE}
      />
    );

    fireEvent.click(screen.getByRole("button", { name: "对 A 回复 bd" }));
    fireEvent.click(screen.getByRole("button", { name: "对 C 回复 bd" }));
    fireEvent.click(screen.getByRole("button", { name: "对 E 回复 bd" }));

    expect(applyBd.mock.calls.map(([replyId]) => replyId)).toEqual([
      "reply-seat-ticket",
      "reply-visit-proof",
      "reply-bag-nonperson"
    ]);
  });

  it("rejects decoy replies locally and advances visible rank from 04 to 01", () => {
    const applyBd = vi.spyOn(kit.libraryFinals, "applyBd").mockReturnValue(true);
    const view = render(
      <TopTenRisePuzzle
        appliedReplyIds={[]}
        bdCount={0}
        phase="top_ten_rising"
        ownedEvidenceIds={ALL_EVIDENCE}
        uploadedEvidenceIds={ALL_EVIDENCE}
      />
    );

    expect(screen.getByText("04")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "对 B 回复 bd" }));
    expect(screen.getByText(libraryFinalsContent.cc98.bdOptions[1].rejection ?? "")).toBeInTheDocument();
    expect(applyBd).not.toHaveBeenCalled();

    view.rerender(
      <TopTenRisePuzzle
        appliedReplyIds={["reply-seat-ticket", "reply-visit-proof", "reply-bag-nonperson"]}
        bdCount={3}
        phase="top_ten_reached"
        ownedEvidenceIds={ALL_EVIDENCE}
        uploadedEvidenceIds={ALL_EVIDENCE}
      />
    );
    expect(screen.getByText("01")).toBeInTheDocument();
    expect(screen.getByText(/图书馆 App 已放出 022 恢复申请入口/)).toBeInTheDocument();
  });
});
