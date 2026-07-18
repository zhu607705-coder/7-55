import { fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createInitialGameState } from "../../../core/GameState";
import { kit } from "../../../modules/GameKit";
import { RouteAuditPanel } from "./RouteAuditPanel";

const router = { goTo: vi.fn() };

describe("RouteAuditPanel", () => {
  beforeEach(() => {
    router.goTo.mockReset();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("keeps submission disabled until all three source records are ready", () => {
    render(
      <RouteAuditPanel
        phase="evidence_gathering"
        puzzle={createInitialGameState().ui.libraryFinalsPuzzle}
        router={router}
      />
    );

    expect(screen.getByRole("button", { name: "提交补录" })).toBeDisabled();
    expect(screen.getByText("三份依据还没有齐全，表格拒绝替你编事实。")).toBeInTheDocument();
    expect(screen.getByLabelText("公示编号")).toBeInTheDocument();
    expect(screen.queryByLabelText("公示楼层")).not.toBeInTheDocument();
  });

  it("submits the authored 7 / 47 / 3 values", () => {
    const submit = vi.spyOn(kit.libraryFinals, "submitAudit").mockReturnValue(true);
    const puzzle = {
      ...createInitialGameState().ui.libraryFinalsPuzzle,
      entranceRecordRead: true,
      investigationOpened: true,
      archivedRuleCollected: true,
      auditArrivalMinutes: 7,
      auditPublicNoticeFloor: 47,
      auditProofCount: 3
    };
    render(<RouteAuditPanel phase="evidence_gathering" puzzle={puzzle} router={router} />);

    fireEvent.click(screen.getByRole("button", { name: "提交补录" }));
    expect(submit).toHaveBeenCalledWith({ arrivalMinutes: 7, publicNoticeFloor: 47, proofCount: 3 });
  });

  it("keeps exact values out of source cards and failure hints before validation", () => {
    vi.spyOn(kit.libraryFinals, "submitAudit").mockReturnValue(false);
    const puzzle = {
      ...createInitialGameState().ui.libraryFinalsPuzzle,
      entranceRecordRead: true,
      investigationOpened: true,
      archivedRuleCollected: true
    };
    render(<RouteAuditPanel phase="evidence_gathering" puzzle={puzzle} router={router} />);

    expect(screen.getAllByText(/来源已/)).toHaveLength(3);
    expect(screen.queryByText(/47 楼/)).not.toBeInTheDocument();
    expect(screen.queryByText(/7 分钟/)).not.toBeInTheDocument();
    expect(screen.queryByText(/3 项证明/)).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "提交补录" }));
    expect(screen.getByText("至少一个字段与已保存的来源不一致。")).toBeInTheDocument();
  });

  it("confirms the verified values only after the presence proof is issued", () => {
    const puzzle = {
      ...createInitialGameState().ui.libraryFinalsPuzzle,
      entranceRecordRead: true,
      investigationOpened: true,
      archivedRuleCollected: true,
      presenceProofCollected: true,
      auditArrivalMinutes: 7,
      auditPublicNoticeFloor: 47,
      auditProofCount: 3
    };
    render(<RouteAuditPanel phase="evidence_gathering" puzzle={puzzle} router={router} />);

    expect(screen.getByLabelText("已验证补录值")).toHaveTextContent("7 分钟");
    expect(screen.getByLabelText("已验证补录值")).toHaveTextContent("47");
    expect(screen.getByLabelText("已验证补录值")).toHaveTextContent("3 项");
  });
});
