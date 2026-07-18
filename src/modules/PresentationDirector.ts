import type { EventBus } from "../core/EventBus";
import type { GameState, GameStore } from "../core/types";
import actOneTimelineData from "../data/act-one.audio.json";
import bikeArcadeTimelineData from "../data/bike-arcade.audio.json";
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
  ...Object.keys((bikeArcadeTimelineData as AudioTimelineShape).events),
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

    if (!previous.bikeArcade.unlocked && next.bikeArcade.unlocked) {
      cues.push({ cueId: "bike_arcade_unlocked" });
    }
    if (!previous.bikeArcade.completed && next.bikeArcade.completed) {
      cues.push({
        cueId: "bike_arcade_won",
        payload: {
          attempt: next.bikeArcade.attemptCount,
          lives: next.bikeArcade.bestLives
        }
      });
      cues.push({ cueId: "bike_arcade_completed" });
    }
    if (previous.currentScene !== next.currentScene) {
      const entryCue = sceneEntryCue(next);
      if (entryCue) {
        cues.push(entryCue);
      }
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
  if (state.currentScene === "bike_arcade") {
    return { cueId: "bike_arcade_opened" };
  }
  if (state.currentScene === "chapter_transition") {
    return { cueId: "chapter_transition_opened" };
  }
  return null;
}

function cueToken(cueId: string, payload?: Record<string, unknown>): string {
  const normalized = payload
    ? Object.fromEntries(Object.entries(payload).sort(([left], [right]) => left.localeCompare(right)))
    : {};
  return `${cueId}:${JSON.stringify(normalized)}`;
}

export const presentationDirector = new PresentationDirector();
