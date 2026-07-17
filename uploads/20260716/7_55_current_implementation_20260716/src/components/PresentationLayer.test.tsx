import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../core/EventBus";
import { PRESENTATION_CUE_EVENT } from "../modules/PresentationDirector";
import { PresentationLayer } from "./PresentationLayer";

describe("PresentationLayer", () => {
  afterEach(() => {
    cleanup();
    vi.useRealTimers();
  });

  it("renders a state cue without emitting audio or gameplay events", () => {
    vi.useFakeTimers();
    const events = new EventBus();
    render(<PresentationLayer events={events} />);

    act(() => {
      events.emit(PRESENTATION_CUE_EVENT, {
        cueId: "library_occupied_seat_found",
        source: "event",
        seat: "022"
      });
    });

    expect(screen.getByText("022 被书包占用")).toBeTruthy();
    expect(events.getHistory()).toHaveLength(1);
  });

  it("queues ordinary cues and lets a critical cue interrupt", () => {
    vi.useFakeTimers();
    const events = new EventBus();
    render(<PresentationLayer events={events} />);

    act(() => {
      events.emit(PRESENTATION_CUE_EVENT, { cueId: "library_occupancy_note_collected" });
      events.emit(PRESENTATION_CUE_EVENT, { cueId: "cc98_bd_applied", bdCount: 1 });
    });
    expect(screen.getByText("获得占座纸条")).toBeTruthy();

    act(() => {
      events.emit(PRESENTATION_CUE_EVENT, { cueId: "library_seat_recovered" });
    });
    expect(screen.getByText("022 已恢复")).toBeTruthy();

    act(() => vi.advanceTimersByTime(2400));
    expect(screen.queryByText("有效回复")).toBeNull();
  });

  it("does not render an audio-only chapter transition cue", () => {
    vi.useFakeTimers();
    const events = new EventBus();
    render(<PresentationLayer events={events} />);

    act(() => {
      events.emit(PRESENTATION_CUE_EVENT, { cueId: "chapter_transition_opened", source: "state" });
    });

    expect(screen.queryByRole("status")).toBeNull();
    expect(events.getHistory()).toHaveLength(1);
  });
});
