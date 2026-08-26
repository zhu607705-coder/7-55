import type { EventBus } from "../core/EventBus";
import type { GameState, GameStore } from "../core/types";
import actOneTimelineData from "../data/act-one.audio.json";
import chapterThreeCanteenTimelineData from "../data/chapter3-canteen.audio.json";
import chapterThreeTheaterTimelineData from "../data/chapter3-theater.audio.json";
import chapterThreeQizhenTimelineData from "../data/chapter3-qizhen.audio.json";
import chapterThreeStoryTimelineData from "../data/chapter3-story.audio.json";
import chapterFourPrologueTimelineData from "../data/chapter4-prologue.audio.json";
import chapterFour755TimelineData from "../data/chapter4-755.audio.json";
import libraryFinalsTimelineData from "../data/library-finals.audio.json";
import { PRESENTATION_VISUAL_CUE_IDS } from "../data/presentation-cues";

interface AudioTimelineShape {
  events: Record<string, unknown>;
}

interface PendingCue {
  cueId: string;
  payload?: Record<string, unknown>;
}

export const PRESENTATION_CUE_EVENT = "presentation_cue";

const TIMELINE_CUE_IDS = new Set([
  ...Object.keys((actOneTimelineData as AudioTimelineShape).events),
  ...Object.keys((libraryFinalsTimelineData as AudioTimelineShape).events),
  ...Object.keys((chapterThreeCanteenTimelineData as AudioTimelineShape).events),
  ...Object.keys((chapterThreeTheaterTimelineData as AudioTimelineShape).events),
  ...Object.keys((chapterThreeQizhenTimelineData as AudioTimelineShape).events),
  ...Object.keys((chapterThreeStoryTimelineData as AudioTimelineShape).events),
  ...Object.keys((chapterFourPrologueTimelineData as AudioTimelineShape).events),
  ...Object.keys((chapterFour755TimelineData as AudioTimelineShape).events),
  ...PRESENTATION_VISUAL_CUE_IDS
]);

/**
 * Converts mutable UI/domain sources into stable presentation cues.
 * Audio and animation consume the cue independently and never call one another.
 */
export class PresentationDirector {
  private readonly emittedThisTurn = new Set<string>();

  attach(store: GameStore, events: EventBus): () => void {
    let previous = store.getState();
    let detached = false;

    const unsubscribeStore = store.subscribe(() => {
      const next = store.getState();
      this.deriveStateCues(previous, next).forEach((cue) => this.publish(events, cue, "state"));
      previous = next;
    });

    const unsubscribeEvents = events.subscribe((event) => {
      if (event.name === PRESENTATION_CUE_EVENT || !TIMELINE_CUE_IDS.has(event.name)) {
        return;
      }
      this.publish(events, { cueId: event.name, payload: event.payload }, "event");
    });

    queueMicrotask(() => {
      if (detached) {
        return;
      }
      const entryCue = sceneEntryCue(previous);
      if (entryCue) {
        this.publish(events, entryCue, "state");
      }
    });

    return () => {
      detached = true;
      unsubscribeStore();
      unsubscribeEvents();
    };
  }

  private deriveStateCues(previous: GameState, next: GameState): PendingCue[] {
    const cues: PendingCue[] = [];

    if (previous.currentScene !== next.currentScene) {
      const entryCue = sceneEntryCue(next);
      if (entryCue) {
        cues.push(entryCue);
      }
    }
    const previousInChapterFour755 = isChapterFour755RpgState(previous);
    const nextInChapterFour755 = isChapterFour755RpgState(next);
    if (previousInChapterFour755 && !nextInChapterFour755) {
      cues.push({ cueId: "chapter4_755_scene_closed" });
    }
    if (nextInChapterFour755
      && (!previousInChapterFour755 || previous.chapter4.phase !== "final_chase")
      && next.chapter4.phase === "final_chase") {
      cues.push({ cueId: "final_chase_started" });
    }
    if (nextInChapterFour755
      && next.chapter4.phase === "maintenance_repair"
      && (!previousInChapterFour755 || previous.chapter4.phase !== "maintenance_repair")) {
      cues.push({
        cueId: next.chapter4.factIds.includes("clock_gear_repaired")
          ? "clock_stable_started"
          : "clock_stutter_started"
      });
    }
    if (previousInChapterFour755
      && nextInChapterFour755
      && !previous.chapter4.factIds.includes("clock_gear_repaired")
      && next.chapter4.factIds.includes("clock_gear_repaired")) {
      cues.push({ cueId: "clock_stable_started" });
    }
    if (previousInChapterFour755
      && nextInChapterFour755
      && previous.chapter4.phase === "final_chase"
      && next.chapter4.phase === "final_chase"
      && next.chapter4.chaseAttempt > previous.chapter4.chaseAttempt) {
      cues.push({ cueId: "final_chase_failed" });
      cues.push({ cueId: "final_chase_started" });
    }
    if (previousInChapterFour755
      && previous.chapter4.phase === "final_chase"
      && next.chapter4.phase === "final_minute_recovery") {
      cues.push({ cueId: "final_chase_succeeded" });
    }

    return cues;
  }

  private publish(events: EventBus, cue: PendingCue, source: "state" | "event"): void {
    const token = cueToken(cue.cueId, cue.payload);
    if (this.emittedThisTurn.has(token)) {
      return;
    }
    this.emittedThisTurn.add(token);
    queueMicrotask(() => this.emittedThisTurn.delete(token));
    events.emit(PRESENTATION_CUE_EVENT, {
      cueId: cue.cueId,
      source,
      ...(cue.payload ?? {})
    });
  }
}

function sceneEntryCue(state: GameState): PendingCue | null {
  if (isChapterFour755RpgState(state) && state.chapter4.phase === "maintenance_repair") {
    return {
      cueId: state.chapter4.factIds.includes("clock_gear_repaired")
        ? "clock_stable_started"
        : "clock_stutter_started"
    };
  }
  if (isChapterFour755RpgState(state) && state.chapter4.phase === "final_chase") {
    return { cueId: "final_chase_started" };
  }
  return null;
}

function isChapterFour755RpgState(state: GameState): boolean {
  return state.runtimeMode === "rpg"
    && state.rpgScene === "duan_yongping_temporal_maze";
}

function cueToken(cueId: string, payload?: Record<string, unknown>): string {
  const normalized = payload
    ? Object.fromEntries(Object.entries(payload).sort(([left], [right]) => left.localeCompare(right)))
    : {};
  return `${cueId}:${JSON.stringify(normalized)}`;
}

export const presentationDirector = new PresentationDirector();
