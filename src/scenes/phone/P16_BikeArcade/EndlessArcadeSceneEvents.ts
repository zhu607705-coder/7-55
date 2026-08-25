import type { EndlessChallengeModeId } from "../../../core/types";
import type { EndlessArcadeHostStatus, EndlessArcadeViewPhase } from "./EndlessArcadeRuntime";

interface EndlessArcadeSceneEventBus {
  emit: (eventName: string, payload?: Record<string, unknown>) => void;
}

export function emitEndlessArcadePauseEvent(
  eventBus: EndlessArcadeSceneEventBus,
  mode: EndlessChallengeModeId,
  reason: string
): { mode: EndlessChallengeModeId; reason: string } {
  const payload = { mode, reason };
  eventBus.emit("endless_arcade_runtime_paused", payload);
  return payload;
}

export function emitEndlessArcadeRuntimeErrorPause(
  eventBus: EndlessArcadeSceneEventBus,
  mode: EndlessChallengeModeId
): { mode: EndlessChallengeModeId; reason: string } {
  return emitEndlessArcadePauseEvent(eventBus, mode, "runtime_error");
}

export function emitEndlessArcadeConfirmExitPause(
  eventBus: EndlessArcadeSceneEventBus,
  phase: EndlessArcadeViewPhase,
  mode: EndlessChallengeModeId | null
): boolean {
  if (phase !== "running" || !mode) return false;
  emitEndlessArcadePauseEvent(eventBus, mode, "player");
  return true;
}

export function createEndlessArcadeClosedEmitter(
  eventBus: EndlessArcadeSceneEventBus
): () => boolean {
  let emitted = false;
  return () => {
    if (emitted) return false;
    emitted = true;
    eventBus.emit("endless_arcade_closed");
    return true;
  };
}

export function consumePendingEndlessArcadeResume(
  pending: boolean,
  hostStatusKind: EndlessArcadeHostStatus["kind"]
): { pending: boolean; shouldEmit: boolean } {
  if (!pending) return { pending: false, shouldEmit: false };
  if (hostStatusKind === "running") return { pending: false, shouldEmit: true };
  if (hostStatusKind === "paused" || hostStatusKind === "loading") {
    return { pending: true, shouldEmit: false };
  }
  return { pending: false, shouldEmit: false };
}
