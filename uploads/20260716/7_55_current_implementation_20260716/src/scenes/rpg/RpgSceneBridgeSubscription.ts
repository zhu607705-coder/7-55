import type { GameEvent } from "../../core/types";
import type { RpgBridge } from "./RpgBridge";

interface SceneLifecycleEvents {
  once(event: string, listener: () => void): unknown;
}

/** Keeps a scene's global bridge listener alive only for that scene lifecycle. */
export function subscribeRpgSceneBridge(
  lifecycle: SceneLifecycleEvents,
  bridge: Pick<RpgBridge, "subscribe">,
  listener: (event: GameEvent) => void,
  onCleanup?: () => void
): () => void {
  let active = true;
  const unsubscribe = bridge.subscribe((event) => {
    if (active) {
      listener(event);
    }
  });
  const cleanup = () => {
    if (!active) {
      return;
    }
    active = false;
    unsubscribe();
    onCleanup?.();
  };

  lifecycle.once("shutdown", cleanup);
  lifecycle.once("destroy", cleanup);
  return cleanup;
}
