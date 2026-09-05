import type { ComponentType } from "react";
import type { SceneComponentProps } from "../../components/ScenePlaceholder";

type SceneModule = { default: ComponentType<SceneComponentProps> };
function reusableLoader(load: () => Promise<SceneModule>) {
  let promise: Promise<SceneModule> | undefined;
  return () => {
    promise ??= load().catch((error: unknown) => {
      promise = undefined;
      throw error;
    });
    return promise;
  };
}

export const loadCc98Scene = reusableLoader(() => import("./P02_CC98").then(m => ({ default: m.Cc98Scene })));
export const loadTimelineRecoveryScene = reusableLoader(() => import("./P20_TimelineRecovery").then(m => ({ default: m.TimelineRecoveryScene })));
export const loadVoiceMemosScene = reusableLoader(() => import("./P21_VoiceMemos").then(m => ({ default: m.VoiceMemosScene })));

function loaderFor(id: string) {
  switch (id) {
    case "cc98": return loadCc98Scene;
    case "timeline_recovery": return loadTimelineRecoveryScene;
    case "voice_memos": return loadVoiceMemosScene;
    default: return undefined;
  }
}

// Intent warming performs no navigation, battery consumption or progression write.
export function preloadPhoneScene(id: string): void {
  void loaderFor(id)?.().catch(() => undefined);
}

/** Only the caller's unlocked home apps are eligible; no startup/alarm prefetch. */
export function schedulePhoneSceneWarmup(ids: readonly string[]): () => void {
  const connection = (navigator as Navigator & {
    connection?: { saveData?: boolean; effectiveType?: string };
    deviceMemory?: number;
  });
  if (connection.connection?.saveData || /^(slow-)?2g$/.test(connection.connection?.effectiveType ?? "")) {
    return () => undefined;
  }
  const queue = connection.deviceMemory && connection.deviceMemory <= 4 ? ids.slice(0, 1) : [...ids];
  const idleWindow = window as Window & {
    requestIdleCallback?: (callback: () => void, options: { timeout: number }) => number;
    cancelIdleCallback?: (handle: number) => void;
  };
  let cancelled = false;
  let idleHandle: number | undefined;
  let timer: number;
  const next = () => {
    if (cancelled || document.hidden) return;
    const id = queue.shift();
    if (!id) return;
    const run = () => {
      if (cancelled || document.hidden) return;
      const load = loaderFor(id);
      void (load ? load().catch(() => undefined) : Promise.resolve()).then(() => {
        if (!cancelled) timer = window.setTimeout(next, 180);
      });
    };
    if (idleWindow.requestIdleCallback) idleHandle = idleWindow.requestIdleCallback(run, { timeout: 1200 });
    else run();
  };
  timer = window.setTimeout(next, 700);
  return () => {
    cancelled = true;
    window.clearTimeout(timer);
    if (idleHandle !== undefined) idleWindow.cancelIdleCallback?.(idleHandle);
  };
}
