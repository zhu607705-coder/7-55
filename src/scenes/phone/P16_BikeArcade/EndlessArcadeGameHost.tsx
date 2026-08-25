import {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState
} from "react";
import type Phaser from "phaser";
import type { EndlessChallengeModeId } from "../../../core/types";
import { getDeveloperBikeStart } from "../../../modules/DeveloperChannel";
import type { EndlessArcadeRunTicket } from "../../../modules/EndlessArcadeController";
import { getEndlessChallengeDefinition } from "./EndlessChallengeRegistry";
import {
  EndlessArcadeRuntimeError,
  cleanupEndlessArcadeScene,
  destroyEndlessArcadeRuntime,
  mountEndlessArcadeRuntime,
  normalizeEndlessRunSnapshot,
  normalizeEndlessRunSummary,
  releaseEndlessArcadeSceneControls,
  type EndlessArcadeControllableScene,
  type EndlessArcadeControlAction,
  type EndlessArcadeHostStatus,
  type EndlessArcadePauseReason,
  type EndlessArcadeRunSnapshot,
  type EndlessArcadeRunSummary,
  type EndlessArcadeSceneBridge
} from "./EndlessArcadeRuntime";

const ENDLESS_HOST_WIDTH = 390;
const ENDLESS_HOST_HEIGHT = 650;
const ENDLESS_BOOT_TIMEOUT_MS = 5_000;

export interface EndlessArcadeGameHostHandle {
  pause: (reason?: EndlessArcadePauseReason) => void;
  resume: () => void;
  releaseControls: () => void;
  sendControl: (action: EndlessArcadeControlAction) => void;
  setAim: (normalizedX: number) => void;
  destroy: () => void;
}

interface EndlessArcadeGameHostProps {
  mode: EndlessChallengeModeId;
  run: EndlessArcadeRunTicket;
  runKey: number;
  externalPause?: boolean;
  onStatusChange: (status: EndlessArcadeHostStatus) => void;
  onSnapshot: (snapshot: EndlessArcadeRunSnapshot) => void;
}

function asRuntimeError(mode: EndlessChallengeModeId, error: unknown): EndlessArcadeRuntimeError {
  if (error instanceof EndlessArcadeRuntimeError) return error;
  return new EndlessArcadeRuntimeError(
    "boot_failed",
    mode,
    error instanceof Error ? error.message : "Unknown endless arcade boot failure"
  );
}

export const EndlessArcadeGameHost = forwardRef<
  EndlessArcadeGameHostHandle,
  EndlessArcadeGameHostProps
>(function EndlessArcadeGameHost(
  { mode, run, runKey, externalPause = false, onStatusChange, onSnapshot },
  forwardedRef
) {
  const hostRef = useRef<HTMLDivElement>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const sceneRef = useRef<EndlessArcadeControllableScene | null>(null);
  const sceneKeyRef = useRef<string | null>(null);
  const bootSessionRef = useRef(0);
  const runStartedAtRef = useRef(0);
  const pausedReasonRef = useRef<EndlessArcadePauseReason | null>(null);
  const externalPauseRef = useRef(externalPause);
  const snapshotRef = useRef<EndlessArcadeRunSnapshot>(
    normalizeEndlessRunSnapshot(mode, {})
  );
  const statusCallbackRef = useRef(onStatusChange);
  const snapshotCallbackRef = useRef(onSnapshot);
  const [statusKind, setStatusKind] = useState<EndlessArcadeHostStatus["kind"]>("loading");
  const statusKindRef = useRef<EndlessArcadeHostStatus["kind"]>("loading");

  statusCallbackRef.current = onStatusChange;
  snapshotCallbackRef.current = onSnapshot;
  externalPauseRef.current = externalPause;

  function publishStatus(status: EndlessArcadeHostStatus): void {
    statusKindRef.current = status.kind;
    setStatusKind(status.kind);
    statusCallbackRef.current(status);
  }

  function releaseActiveControls(): void {
    releaseEndlessArcadeSceneControls(sceneRef.current);
  }

  function destroyActiveGame(): void {
    releaseActiveControls();
    cleanupEndlessArcadeScene(sceneRef.current);
    sceneRef.current = null;
    sceneKeyRef.current = null;
    pausedReasonRef.current = null;
    destroyEndlessArcadeRuntime(gameRef);
    hostRef.current?.replaceChildren();
  }

  function pauseActiveGame(reason: EndlessArcadePauseReason = "player"): void {
    if (["game_over", "error"].includes(statusKindRef.current)) return;
    releaseActiveControls();
    const pendingReason = pausedReasonRef.current ?? reason;
    pausedReasonRef.current = pendingReason;
    const game = gameRef.current;
    const sceneKey = sceneKeyRef.current;
    if (game && sceneKey && game.scene.isActive(sceneKey)) game.scene.pause(sceneKey);
    if (statusKindRef.current !== "paused") {
      publishStatus({ kind: "paused", reason: pendingReason });
    }
  }

  function resumeActiveGame(): void {
    const game = gameRef.current;
    const sceneKey = sceneKeyRef.current;
    if (pausedReasonRef.current === null || ["game_over", "error"].includes(statusKindRef.current)) return;
    const blockedReason = externalPauseRef.current
      ? "control_center"
      : document.hidden
        ? "document_hidden"
        : document.hasFocus()
          ? null
          : "window_blur";
    if (blockedReason) {
      pausedReasonRef.current = blockedReason;
      publishStatus({ kind: "paused", reason: blockedReason });
      return;
    }
    pausedReasonRef.current = null;
    if (!game || !sceneKey) {
      publishStatus({ kind: "loading" });
      return;
    }
    if (game.scene.isPaused(sceneKey)) game.scene.resume(sceneKey);
    publishStatus({ kind: "running" });
  }

  function sendControl(action: EndlessArcadeControlAction): void {
    const scene = sceneRef.current;
    if (!scene || pausedReasonRef.current !== null || statusKindRef.current !== "running") return;
    if (scene.handleEndlessControl) {
      scene.handleEndlessControl(action);
      return;
    }
    if (action === "left") scene.moveLane?.(-1);
    if (action === "right") scene.moveLane?.(1);
  }

  function setAim(normalizedX: number): void {
    const scene = sceneRef.current;
    if (!scene || pausedReasonRef.current !== null || statusKindRef.current !== "running") return;
    scene.setEndlessAim?.(Math.min(1, Math.max(0, Number.isFinite(normalizedX) ? normalizedX : 0.5)));
  }

  useImperativeHandle(forwardedRef, () => ({
    pause: pauseActiveGame,
    resume: resumeActiveGame,
    releaseControls: releaseActiveControls,
    sendControl,
    setAim,
    destroy: destroyActiveGame
  }));

  useEffect(() => {
    const bootSession = bootSessionRef.current + 1;
    bootSessionRef.current = bootSession;
    let disposed = false;
    let booted = false;
    runStartedAtRef.current = performance.now();
    snapshotRef.current = normalizeEndlessRunSnapshot(mode, {});
    statusKindRef.current = "loading";
    setStatusKind("loading");
    statusCallbackRef.current({ kind: "loading" });
    destroyActiveGame();

    const publishSnapshot = (partial: Partial<EndlessArcadeRunSnapshot>) => {
      const snapshot = normalizeEndlessRunSnapshot(mode, {
        ...snapshotRef.current,
        ...partial,
        mode
      });
      snapshotRef.current = snapshot;
      snapshotCallbackRef.current(snapshot);
    };
    const finish = (partial: Partial<EndlessArcadeRunSummary>) => {
      if (disposed || bootSessionRef.current !== bootSession) return;
      const summary = normalizeEndlessRunSummary(mode, {
        ...snapshotRef.current,
        ...partial,
        mode,
        durationMs: partial.durationMs ?? Math.round(performance.now() - runStartedAtRef.current)
      });
      pausedReasonRef.current = null;
      try {
        publishStatus({ kind: "game_over", summary });
        const game = gameRef.current;
        const sceneKey = sceneKeyRef.current;
        if (game && sceneKey && (game.scene.isActive(sceneKey) || game.scene.isPaused(sceneKey))) {
          game.scene.stop(sceneKey);
        }
      } finally {
        destroyActiveGame();
      }
    };
    const sceneBridge: EndlessArcadeSceneBridge = {
      mode,
      runId: run.runId,
      seed: run.seed,
      reducedMotion: window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true,
      publishSnapshot,
      finish,
      requestPause: pauseActiveGame
    };

    const bootTimer = window.setTimeout(() => {
      if (disposed || booted || bootSessionRef.current !== bootSession) return;
      bootSessionRef.current = bootSession + 1;
      destroyActiveGame();
      publishStatus({
        kind: "error",
        error: new EndlessArcadeRuntimeError(
          "boot_timeout",
          mode,
          `Endless ${mode} runtime exceeded ${ENDLESS_BOOT_TIMEOUT_MS}ms boot timeout`
        )
      });
    }, ENDLESS_BOOT_TIMEOUT_MS);

    const handleVisibilityChange = () => {
      if (document.hidden) pauseActiveGame("document_hidden");
    };
    const handleWindowBlur = () => pauseActiveGame("window_blur");
    const handlePageHide = () => pauseActiveGame("document_hidden");
    document.addEventListener("visibilitychange", handleVisibilityChange);
    window.addEventListener("blur", handleWindowBlur);
    window.addEventListener("pagehide", handlePageHide);

    void Promise.all([
      import("phaser"),
      getEndlessChallengeDefinition(mode).loadScene()
    ]).then(([phaserModule, sceneModule]) => {
      if (disposed || bootSessionRef.current !== bootSession || !hostRef.current) return;
      const PhaserRuntime = phaserModule.default;
      const game = new PhaserRuntime.Game({
        type: PhaserRuntime.CANVAS,
        parent: hostRef.current,
        width: ENDLESS_HOST_WIDTH,
        height: ENDLESS_HOST_HEIGHT,
        backgroundColor: "#18222a",
        pixelArt: true,
        roundPixels: true,
        physics: { default: "arcade", arcade: { debug: false } },
        scale: {
          mode: PhaserRuntime.Scale.FIT,
          autoCenter: PhaserRuntime.Scale.CENTER_BOTH
        },
        scene: [sceneModule.Scene],
        callbacks: {
          preBoot: (phaserGame) => {
            phaserGame.registry.set("endlessArcadeBridge", sceneBridge);
            phaserGame.registry.set("endlessArcadeMode", mode);
            phaserGame.registry.set("endlessArcadeRunId", run.runId);
            phaserGame.registry.set("endlessArcadeSeed", run.seed);
            if (mode === "bike") {
              phaserGame.registry.set("bikeArcadeRunConfig", {
                mode: "endless",
                seed: run.seed
              });
              phaserGame.registry.set("bikeArcadeReducedMotion", sceneBridge.reducedMotion);
              phaserGame.registry.set("bikeArcadeStartDistance", getDeveloperBikeStart());
            }
          },
          postBoot: (phaserGame) => {
            if (disposed || bootSessionRef.current !== bootSession) return;
            booted = true;
            window.clearTimeout(bootTimer);
            sceneKeyRef.current = sceneModule.sceneKey;
            sceneRef.current = phaserGame.scene.getScene(sceneModule.sceneKey) as EndlessArcadeControllableScene;
            const pendingPauseReason = pausedReasonRef.current
              ?? (externalPauseRef.current ? "control_center" : null)
              ?? (document.hidden ? "document_hidden" : null)
              ?? (document.hasFocus() ? null : "window_blur");
            if (pendingPauseReason) {
              pausedReasonRef.current = pendingPauseReason;
              if (phaserGame.scene.isActive(sceneModule.sceneKey)) {
                phaserGame.scene.pause(sceneModule.sceneKey);
              }
              publishStatus({ kind: "paused", reason: pendingPauseReason });
            } else {
              publishStatus({ kind: "running" });
            }
          }
        }
      });
      mountEndlessArcadeRuntime(gameRef, game);
      if (
        disposed
        || bootSessionRef.current !== bootSession
        || statusKindRef.current === "game_over"
        || statusKindRef.current === "error"
      ) {
        destroyActiveGame();
      }
    }).catch((error: unknown) => {
      if (disposed || bootSessionRef.current !== bootSession) return;
      window.clearTimeout(bootTimer);
      destroyActiveGame();
      publishStatus({ kind: "error", error: asRuntimeError(mode, error) });
    });

    return () => {
      disposed = true;
      window.clearTimeout(bootTimer);
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      window.removeEventListener("blur", handleWindowBlur);
      window.removeEventListener("pagehide", handlePageHide);
      if (bootSessionRef.current === bootSession) destroyActiveGame();
    };
  }, [mode, run.runId, run.seed, runKey]);

  useEffect(() => {
    if (externalPause) pauseActiveGame("control_center");
  }, [externalPause]);

  return (
    <div
      ref={hostRef}
      className="endless-arcade-canvas-host"
      data-endless-mode={mode}
      data-endless-host-status={statusKind}
      aria-label={`${getEndlessChallengeDefinition(mode).title}游戏区域`}
    />
  );
});
