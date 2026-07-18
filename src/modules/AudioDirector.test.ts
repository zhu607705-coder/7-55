import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { EventBus } from "../core/EventBus";
import bikeContent from "../data/bike-arcade.content.json";
import libraryContent from "../data/library-finals.content.json";
import { AudioDirector, textFeedbackDuration, visibleGraphemeCount } from "./AudioDirector";
import { PRESENTATION_CUE_EVENT } from "./PresentationDirector";

class MockAudio {
  static instances: MockAudio[] = [];

  currentTime = 0;
  loop = false;
  playbackRate = 1;
  volume = 1;
  paused = false;
  readonly src: string;

  constructor(src = "") {
    this.src = src;
    MockAudio.instances.push(this);
  }

  addEventListener() {}
  pause() {
    this.paused = true;
  }
  play() {
    return Promise.resolve();
  }
}

function emitCue(events: EventBus, cueId: string, payload: Record<string, unknown> = {}) {
  events.emit(PRESENTATION_CUE_EVENT, { cueId, source: "event", ...payload });
}

describe("AudioDirector act one timeline", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    MockAudio.instances = [];
    vi.stubGlobal("Audio", MockAudio as unknown as typeof Audio);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it("keeps an operation result as timed Chinese text with no voice instance", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "act1_identity_verified", { studentId: "3250100755" });
    vi.advanceTimersByTime(220);

    expect(MockAudio.instances).toHaveLength(1);
    expect(events.getHistory()).toContainEqual({
      name: "toast",
      payload: {
        text: "登录成功。这个角色终于有名字了，仍然没联网。",
        tone: "xiaoying",
        durationMs: textFeedbackDuration("登录成功。这个角色终于有名字了，仍然没联网。")
      }
    });

    detach();
  });

  it("plays the locked-entry narration once even if the scene announces it twice", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "act1_locked_entry");
    emitCue(events, "act1_locked_entry");
    vi.advanceTimersByTime(300);

    expect(MockAudio.instances).toHaveLength(0);
    expect(events.getHistory().filter((event) => event.name === "toast")).toHaveLength(1);

    detach();
  });

  it("leaves a scene-owned Chinese subtitle to the scene while still playing its English voice", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "prologue_narrator_intro");
    vi.advanceTimersByTime(300);

    expect(MockAudio.instances).toHaveLength(3);
    expect(events.getHistory().filter((event) => event.name === "toast")).toHaveLength(0);

    detach();
  });

  it("shows the bike chapter intro as unvoiced text while retaining music", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "bike_arcade_opened");
    vi.advanceTimersByTime(250);

    expect(MockAudio.instances).toHaveLength(1);
    expect(events.getHistory()).toContainEqual({
      name: "toast",
      payload: {
        text: bikeContent.subtitles.bike_arcade_voice_start,
        tone: "xiaoying",
        durationMs: textFeedbackDuration(bikeContent.subtitles.bike_arcade_voice_start)
      }
    });

    detach();
  });

  it("shows a catalog result as text and retains only its sound effect", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "library_catalog_match_found", { callNumber: "I247.55 / 755" });
    vi.advanceTimersByTime(300);

    expect(MockAudio.instances).toHaveLength(1);
    expect(events.getHistory()).toContainEqual({
      name: "toast",
      payload: {
        text: libraryContent.narration.library_catalog_match_found.subtitleZh,
        tone: "task",
        durationMs: textFeedbackDuration(libraryContent.narration.library_catalog_match_found.subtitleZh)
      }
    });

    detach();
  });

  it("cancels queued bike cues when the chapter closes", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "bike_arcade_opened");
    emitCue(events, "bike_arcade_closed");
    vi.advanceTimersByTime(500);

    expect(MockAudio.instances).toHaveLength(0);
    expect(events.getHistory().some((event) => event.name === "toast")).toBe(false);

    detach();
  });

  it("allows the unvoiced last-life text to appear again on a replay", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    emitCue(events, "bike_arcade_last_life");
    vi.advanceTimersByTime(200);
    emitCue(events, "bike_arcade_last_life");
    vi.advanceTimersByTime(200);

    expect(MockAudio.instances).toHaveLength(0);
    expect(events.getHistory().filter((event) => event.name === "toast")).toHaveLength(2);

    detach();
  });

  it("does not bind playback to a raw component action event", () => {
    const events = new EventBus();
    const director = new AudioDirector();
    const detach = director.attach(events);

    events.emit("bike_arcade_opened");
    vi.advanceTimersByTime(300);
    expect(MockAudio.instances).toHaveLength(0);

    emitCue(events, "bike_arcade_opened");
    vi.advanceTimersByTime(300);
    expect(MockAudio.instances).toHaveLength(1);

    detach();
  });

  it("uses grapheme-aware text timing with the required bounds", () => {
    expect(visibleGraphemeCount("A👨‍👩‍👧‍👦中")).toBe(3);
    expect(textFeedbackDuration("短句")).toBe(2400);
    expect(textFeedbackDuration("字".repeat(100))).toBe(6500);
    expect(textFeedbackDuration("这是一条长度适中的提示")).toBe(1600 + 120 * 11);
  });
});
