import { createRef } from "react";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { PhoneNavButton } from "./PhoneNavButton";

describe("PhoneNavButton", () => {
  it.each([
    ["back", "‹"],
    ["exit", "×"],
    ["close", "×"]
  ] as const)("exposes the %s navigation contract", (kind, glyph) => {
    const onClick = vi.fn();
    render(<PhoneNavButton kind={kind} label={`${kind} action`} onClick={onClick} />);

    const button = screen.getByRole("button", { name: `${kind} action` });
    expect(button).toHaveAttribute("data-phone-nav", kind);
    expect(button).toHaveTextContent(glyph);
    fireEvent.click(button);
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it("forwards its button ref so overlays can focus the close action", () => {
    const ref = createRef<HTMLButtonElement>();
    render(<PhoneNavButton ref={ref} kind="close" label="关闭照片" />);

    expect(ref.current).toBe(screen.getByRole("button", { name: "关闭照片" }));
    ref.current?.focus();
    expect(ref.current).toHaveFocus();
  });
});
