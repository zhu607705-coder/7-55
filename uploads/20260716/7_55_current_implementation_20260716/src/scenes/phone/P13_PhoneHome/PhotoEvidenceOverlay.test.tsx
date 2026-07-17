import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { PhotoEvidenceOverlay } from "./PhotoEvidenceOverlay";

function renderPhoto(overrides: Partial<Parameters<typeof PhotoEvidenceOverlay>[0]> = {}) {
  const props: Parameters<typeof PhotoEvidenceOverlay>[0] = {
    available: true,
    brightness: 80,
    dimmed: false,
    reportGenerated: false,
    onBrightnessChange: vi.fn(),
    onGenerate: vi.fn(),
    onClose: vi.fn(),
    ...overrides
  };
  render(<PhotoEvidenceOverlay {...props} />);
  return props;
}

describe("PhotoEvidenceOverlay", () => {
  it("keeps the backpack label hidden while the photo is overexposed", () => {
    renderPhoto();

    expect(screen.getByLabelText("反光的书包标签")).toBeInTheDocument();
    expect(screen.getByText(/继续降低识别亮度/)).toBeInTheDocument();
    expect(screen.queryByText(/不高于 20%/)).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "生成识别报告" })).not.toBeInTheDocument();
  });

  it("reveals the label at 20 percent and generates a local item report", () => {
    const props = renderPhoto({ brightness: 20, dimmed: true });

    expect(screen.getByLabelText("可读的书包标签")).toBeInTheDocument();
    expect(screen.getByText("人格：加载失败")).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "生成识别报告" }));
    expect(props.onGenerate).toHaveBeenCalledTimes(1);
  });

  it("closes on Escape", () => {
    const props = renderPhoto();
    fireEvent.keyDown(window, { key: "Escape" });
    expect(props.onClose).toHaveBeenCalledTimes(1);
  });
});
