import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { ItemInspectDialog, ITEM_INSPECT_META } from "./ItemInspectDialog";
import { ITEM_META } from "./PixelIcon";

describe("ItemInspectDialog", () => {
  it("renders every item id with icon text and inspect metadata", () => {
    for (const itemId of Object.keys(ITEM_INSPECT_META) as Array<keyof typeof ITEM_INSPECT_META>) {
      const { unmount } = render(
        <ItemInspectDialog open itemId={itemId} variant="phone" onClose={() => undefined} />
      );

      expect(screen.getByRole("dialog")).toHaveTextContent(ITEM_META[itemId].name);
      expect(screen.getByRole("dialog")).toHaveTextContent(ITEM_META[itemId].desc);
      expect(screen.getByRole("dialog")).toHaveTextContent(ITEM_INSPECT_META[itemId].category);
      expect(screen.getByRole("dialog")).toHaveTextContent(ITEM_INSPECT_META[itemId].source);
      expect(screen.getByRole("dialog")).toHaveTextContent(ITEM_INSPECT_META[itemId].intro);

      unmount();
    }
  });

  it("presents the clue field as an intro instead of an explicit usage guide", () => {
    render(<ItemInspectDialog open itemId="rightArrow" variant="rpg" onClose={() => undefined} />);

    expect(screen.getByRole("dialog")).toHaveTextContent("简介");
    expect(screen.queryByText("用途")).toBeNull();
    expect(screen.getByRole("dialog")).toHaveTextContent("它只规定向右，不规定对象");
    expect(screen.getByRole("dialog")).not.toHaveTextContent("图书馆里可取出 022 小票");
  });

  it("keeps every item intro indirect and free of exact solution instructions", () => {
    const explicitSolutionPhrases = [
      "与耳机组合",
      "用于打开塔楼锁孔",
      "生成右移箭头",
      "把目标向右推出",
      "图书馆里可取出 022 小票",
      "拖到失物身份登记机",
      "提交到恢复申请",
      "拖到 022 书包",
      "触发正式清退"
    ];

    for (const [itemId, meta] of Object.entries(ITEM_INSPECT_META)) {
      expect(meta.intro, `${itemId} should have a useful intro`).toMatch(/\S.{12,}/u);
      for (const phrase of explicitSolutionPhrases) {
        expect(meta.intro, `${itemId} should not reveal: ${phrase}`).not.toContain(phrase);
      }
    }
  });

  it("supports both phone and rpg variants", () => {
    const { rerender } = render(
      <ItemInspectDialog open itemId="campusCard" variant="phone" onClose={() => undefined} />
    );

    expect(screen.getByRole("dialog")).toHaveClass("item-inspect-dialog--phone");

    rerender(<ItemInspectDialog open itemId="campusCard" variant="rpg" onClose={() => undefined} />);
    expect(screen.getByRole("dialog")).toHaveClass("item-inspect-dialog--rpg");
  });

  it("closes from the close button, backdrop click, and Escape", () => {
    const onClose = vi.fn();
    const { rerender } = render(
      <ItemInspectDialog open itemId="seatReleasePass" variant="rpg" onClose={onClose} />
    );

    fireEvent.click(screen.getByRole("button", { name: "关闭离座清退 PASS详情" }));
    expect(onClose).toHaveBeenCalledTimes(1);

    rerender(<ItemInspectDialog open itemId="seatReleasePass" variant="rpg" onClose={onClose} />);
    fireEvent.click(screen.getByRole("presentation"));
    expect(onClose).toHaveBeenCalledTimes(2);

    rerender(<ItemInspectDialog open itemId="seatReleasePass" variant="rpg" onClose={onClose} />);
    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).toHaveBeenCalledTimes(3);
  });

  it("does not close when clicking inside the dialog body and focuses the close control", () => {
    const onClose = vi.fn();
    render(<ItemInspectDialog open itemId="occupancyNote" variant="phone" onClose={onClose} />);

    const closeButton = screen.getByRole("button", { name: "关闭占座纸条详情" });
    expect(closeButton).toHaveFocus();

    fireEvent.click(screen.getByText("占座纸条"));
    expect(onClose).not.toHaveBeenCalled();
  });

  it("renders nothing when closed or missing an item id", () => {
    const { rerender } = render(
      <ItemInspectDialog open={false} itemId="gamepad" variant="phone" onClose={() => undefined} />
    );

    expect(screen.queryByRole("dialog")).toBeNull();

    rerender(<ItemInspectDialog open itemId={null} variant="phone" onClose={() => undefined} />);
    expect(screen.queryByRole("dialog")).toBeNull();
  });
});
