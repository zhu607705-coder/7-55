import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import posts from "../../../data/cc98.posts.json";
import personas from "../../../data/cc98.thread-personas.json";
import { Cc98ThreadPage } from "./ThreadPage";

describe("Cc98ThreadPage", () => {
  it("renders six distinct fictional commenters with topic-specific replies", () => {
    const { container } = render(<Cc98ThreadPage post={posts[0]} onBack={() => undefined} />);
    for (const persona of personas) expect(screen.getByText(persona.nickname)).toBeInTheDocument();
    expect(container.querySelectorAll('.cc98-thread-avatar[class*="persona-"]')).toHaveLength(6);
    expect(screen.getByText(/求是潮中段/)).toBeInTheDocument();
  });

  it("keeps the bd image only in its contextual library reply", () => {
    render(<Cc98ThreadPage post={posts[1]} onBack={() => undefined} showBdContent />);
    expect(screen.getByAltText("CC98 bd 表情包")).toBeInTheDocument();
    expect(screen.getByText("bd")).toBeInTheDocument();
    expect(screen.getByText(/队形必须先完整/)).toBeInTheDocument();
  });

  it("hides every bd reference before the forum gate opens", () => {
    render(<Cc98ThreadPage post={posts[1]} onBack={() => undefined} />);
    expect(screen.queryByAltText("CC98 bd 表情包")).not.toBeInTheDocument();
    expect(screen.queryByText(/^bd$/)).not.toBeInTheDocument();
  });

  it("returns to the topic list from the capsule close button", () => {
    const onBack = vi.fn();
    render(<Cc98ThreadPage post={posts[1]} onBack={onBack} />);

    fireEvent.click(screen.getByRole("button", { name: "退出帖子，返回热门话题" }));

    expect(onBack).toHaveBeenCalledTimes(1);
  });
});
