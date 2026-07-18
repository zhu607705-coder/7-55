import { fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";
import { Ac01FilterPuzzle } from "./Ac01FilterPuzzle";

describe("Ac01FilterPuzzle V2", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renders 23 floors and exactly five optional ac01 replies", () => {
    const { container } = render(<Ac01FilterPuzzle optionalAc01Floors={[]} />);

    expect(container.querySelectorAll("[data-investigation-floor]")).toHaveLength(23);
    libraryFinalsContent.cc98.optionalAc01Replies.forEach((reply) => {
      expect(screen.getByText(reply.text)).toBeInTheDocument();
    });
    expect(screen.getAllByRole("button", { name: "读一下（可选）" })).toHaveLength(5);
    expect(screen.getByText("5 条 ac01 全部为可选内容；证据进度不会因此变化。")).toBeInTheDocument();
  });

  it("records an optional reply without exposing a gating action", () => {
    const inspect = vi.spyOn(kit.libraryFinals, "inspectOptionalAc01").mockReturnValue(true);
    const view = render(<Ac01FilterPuzzle optionalAc01Floors={[]} />);

    fireEvent.click(screen.getAllByRole("button", { name: "读一下（可选）" })[0]);
    expect(inspect).toHaveBeenCalledWith(3);

    view.rerender(<Ac01FilterPuzzle optionalAc01Floors={[3]} />);
    expect(screen.getByRole("button", { name: "已记下这条水帖" })).toBeDisabled();
    expect(screen.queryByRole("switch")).not.toBeInTheDocument();
  });

  it("keeps the 47-floor public notice clue in a fictional reply", () => {
    render(<Ac01FilterPuzzle optionalAc01Floors={[]} />);
    const publicNoticeReply = libraryFinalsContent.cc98.storyReplies.find((reply) => reply.floor === 23);

    expect(screen.getByText(publicNoticeReply?.text ?? "")).toBeInTheDocument();
    expect(screen.getAllByText(publicNoticeReply?.author ?? "").length).toBeGreaterThan(0);
  });

  it("shows the forum treasure only after the bd gate opens", () => {
    const { container } = render(<Ac01FilterPuzzle optionalAc01Floors={[]} showBdContent />);

    expect(screen.getByAltText("CC98 bd 表情包")).toBeInTheDocument();
    expect(screen.getByText("bd")).toBeInTheDocument();
    expect(container.querySelector("[data-investigation-floor='16'] button")).toBeNull();
  });

  it("replaces early bd references with static xxx content", () => {
    const { container } = render(<Ac01FilterPuzzle optionalAc01Floors={[]} />);

    expect(screen.queryByAltText("CC98 bd 表情包")).not.toBeInTheDocument();
    expect(screen.queryByText(/^bd$/)).not.toBeInTheDocument();
    expect(container.querySelector("[data-investigation-floor='16']")).toHaveTextContent("xxx");
  });
});
