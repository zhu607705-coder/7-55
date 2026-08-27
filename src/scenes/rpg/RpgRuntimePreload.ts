type RpgGameHostModule = typeof import("./RpgGameHost");

import type { RpgSceneId } from "../../core/types";
import type { ChapterFourWarmupPhase } from "./ChapterFourWarmupAssets";
import { chapterFourWarmupAttemptMetrics } from "./ChapterFourWarmupLoadPolicy";

let rpgGameHostModulePromise: Promise<RpgGameHostModule> | null = null;
let resolvedRpgGameHostModule: RpgGameHostModule | null = null;
const rpgGameHostModuleListeners = new Set<(module: RpgGameHostModule) => void>();

/**
 * 复用同一份动态导入 Promise，让手机侧可以在切换 runtimeMode 前完成 RPG 模块求值。
 * 单文件 WebKit 对大型延迟模块的同步切换开销较高，因此恢复回放入口会先等待本函数完成。
 */
export function preloadRpgGameHost(): Promise<RpgGameHostModule> {
  if (!rpgGameHostModulePromise) {
    rpgGameHostModulePromise = import("./RpgGameHost").catch((error: unknown) => {
      rpgGameHostModulePromise = null;
      throw error;
    });
  }
  return rpgGameHostModulePromise;
}

export function getPreloadedRpgGameHostModule(): RpgGameHostModule | null {
  return resolvedRpgGameHostModule;
}

export function subscribePreloadedRpgGameHostModule(
  listener: (module: RpgGameHostModule) => void
): () => void {
  rpgGameHostModuleListeners.add(listener);
  if (resolvedRpgGameHostModule) listener(resolvedRpgGameHostModule);
  return () => rpgGameHostModuleListeners.delete(listener);
}

function publishPreloadedRpgGameHostModule(module: RpgGameHostModule): void {
  if (resolvedRpgGameHostModule === module) return;
  resolvedRpgGameHostModule = module;
  rpgGameHostModuleListeners.forEach((listener) => listener(module));
}

type RpgWarmupStatus =
  | "idle"
  | "scheduled"
  | "loading_module"
  | "loading"
  | "ready"
  | "degraded"
  | "failed";

export interface RpgWarmupPhaseSnapshot {
  sceneId: RpgSceneId;
  phase: ChapterFourWarmupPhase | "scene";
  status: RpgWarmupStatus;
  strategy: "idle" | "immediate" | null;
  moduleReady: boolean;
  assetCount: number;
  loadedCount: number;
  reusedCount: number;
  failedUrls: string[];
  estimatedTransferBytes: number;
  measuredTransferBytes: number;
  estimatedDecodedBytes: number;
  elapsedMs: number;
  degradationReason: "constrained_network" | "low_memory" | "decode_failure" | null;
  transferMeasurement: "measured" | "estimated" | "unknown";
  warmedAssetCount: number;
  failedAssetCount: number;
  constrainedNetwork: boolean;
  lowMemory: boolean;
  startedAtMs: number | null;
  completedAtMs: number | null;
}

export interface RpgRuntimeWarmupSnapshot extends RpgWarmupPhaseSnapshot {
  phaseSnapshots: RpgWarmupPhaseSnapshot[];
}

type IdleCallbackWindow = Window & {
  requestIdleCallback?: (callback: () => void, options?: { timeout: number }) => number;
  cancelIdleCallback?: (handle: number) => void;
};
type NavigatorWithConnection = Navigator & {
  connection?: { saveData?: boolean; effectiveType?: string };
  deviceMemory?: number;
};

const EMPTY_SCENE_ID: RpgSceneId = "campus_bootstrap";
const emptyPhaseSnapshot: RpgWarmupPhaseSnapshot = {
  sceneId: EMPTY_SCENE_ID,
  phase: "scene",
  status: "idle",
  strategy: null,
  moduleReady: false,
  assetCount: 0,
  loadedCount: 0,
  reusedCount: 0,
  failedUrls: [],
  estimatedTransferBytes: 0,
  measuredTransferBytes: 0,
  estimatedDecodedBytes: 0,
  elapsedMs: 0,
  degradationReason: null,
  transferMeasurement: "unknown",
  warmedAssetCount: 0,
  failedAssetCount: 0,
  constrainedNetwork: false,
  lowMemory: false,
  startedAtMs: null,
  completedAtMs: null
};
let latestPhaseSnapshot: RpgWarmupPhaseSnapshot = { ...emptyPhaseSnapshot };
const phaseSnapshots = new Map<string, RpgWarmupPhaseSnapshot>();

interface PhaseWarmupRun {
  promise: Promise<RpgRuntimeWarmupSnapshot>;
  cancelled: boolean;
  required: boolean;
  pendingCancellationSettlers: Set<() => void>;
}

const phaseWarmupRuns = new Map<string, PhaseWarmupRun>();

interface WarmImageResult {
  success: boolean;
  measuredTransferBytes: number;
  estimatedDecodedBytes: number;
  transferMeasurement: "measured" | "estimated" | "unknown";
}

const imageWarmupPromises = new Map<string, Promise<WarmImageResult>>();

function nowMs(): number {
  return typeof performance === "undefined" ? Date.now() : performance.now();
}

function isConstrainedNetwork(): boolean {
  if (typeof navigator === "undefined") return false;
  const connection = (navigator as NavigatorWithConnection).connection;
  return connection?.saveData === true || connection?.effectiveType === "slow-2g" || connection?.effectiveType === "2g";
}

function isLowMemoryDevice(): boolean {
  if (typeof navigator === "undefined") return false;
  const deviceMemory = (navigator as NavigatorWithConnection).deviceMemory;
  return typeof deviceMemory === "number" && deviceMemory > 0 && deviceMemory <= 4;
}

function estimateDataUrlBytes(url: string): number {
  if (!url.startsWith("data:")) return 0;
  const comma = url.indexOf(",");
  if (comma < 0) return 0;
  const metadata = url.slice(0, comma);
  const payload = url.slice(comma + 1);
  if (metadata.includes(";base64")) {
    const padding = payload.endsWith("==") ? 2 : payload.endsWith("=") ? 1 : 0;
    return Math.max(0, Math.floor(payload.length * 3 / 4) - padding);
  }
  try {
    return new TextEncoder().encode(decodeURIComponent(payload)).byteLength;
  } catch {
    return payload.length;
  }
}

function measuredResourceBytes(url: string): number {
  if (typeof performance === "undefined" || typeof performance.getEntriesByName !== "function") return 0;
  const entries = performance.getEntriesByName(url) as PerformanceResourceTiming[];
  const entry = entries[entries.length - 1];
  return Math.max(0, entry?.transferSize || entry?.encodedBodySize || 0);
}

function reportableWarmupAssetUrl(key: string, url: string): string {
  return url.startsWith("data:") ? `inline:${key}` : url;
}

function warmImageUrl(
  url: string,
  fallbackDecodedBytes: number
): { promise: Promise<WarmImageResult>; reused: boolean } {
  const existing = imageWarmupPromises.get(url);
  if (existing) return { promise: existing, reused: true };
  const promise = new Promise<WarmImageResult>((resolve) => {
    if (typeof Image === "undefined") {
      resolve({
        success: true,
        measuredTransferBytes: 0,
        estimatedDecodedBytes: fallbackDecodedBytes,
        transferMeasurement: estimateDataUrlBytes(url) > 0 ? "estimated" : "unknown"
      });
      return;
    }
    const image = new Image();
    let settled = false;
    const finish = (success: boolean) => {
      if (settled) return;
      settled = true;
      window.clearTimeout(timeout);
      image.onload = null;
      image.onerror = null;
      const measuredTransferBytes = measuredResourceBytes(url);
      const estimatedTransferBytes = estimateDataUrlBytes(url);
      resolve({
        success,
        measuredTransferBytes,
        estimatedDecodedBytes: image.naturalWidth > 0 && image.naturalHeight > 0
          ? image.naturalWidth * image.naturalHeight * 4
          : fallbackDecodedBytes,
        transferMeasurement: measuredTransferBytes > 0
          ? "measured"
          : estimatedTransferBytes > 0
            ? "estimated"
            : "unknown"
      });
    };
    const timeout = window.setTimeout(() => finish(false), 15_000);
    image.decoding = "async";
    image.onload = () => {
      if (typeof image.decode !== "function") {
        finish(true);
        return;
      }
      void image.decode().then(() => finish(true), () => finish(false));
    };
    image.onerror = () => finish(false);
    image.src = url;
  }).then((result) => {
    if (!result.success) imageWarmupPromises.delete(url);
    return result;
  });
  imageWarmupPromises.set(url, promise);
  return { promise, reused: false };
}

function yieldToBrowser(): Promise<void> {
  if (typeof window === "undefined") return Promise.resolve();
  return new Promise((resolve) => window.setTimeout(resolve, 0));
}

function cancelSpeculativePhaseWarmup(key: string): void {
  const run = phaseWarmupRuns.get(key);
  if (!run || run.required) return;
  run.cancelled = true;
  for (const settle of [...run.pendingCancellationSettlers]) settle();
}

function waitForWarmupIdleSlice(run: PhaseWarmupRun): Promise<boolean> {
  if (run.cancelled) return Promise.resolve(false);
  if (typeof window === "undefined") return Promise.resolve(true);
  return new Promise<boolean>((resolve) => {
    const idleWindow = window as IdleCallbackWindow;
    let settled = false;
    let idleHandle: number | null = null;
    let timeoutHandle: number | null = null;
    const finish = (ready: boolean) => {
      if (settled) return;
      settled = true;
      if (idleHandle !== null) idleWindow.cancelIdleCallback?.(idleHandle);
      if (timeoutHandle !== null) window.clearTimeout(timeoutHandle);
      run.pendingCancellationSettlers.delete(cancel);
      resolve(ready && !run.cancelled);
    };
    const cancel = () => finish(false);
    run.pendingCancellationSettlers.add(cancel);
    if (idleWindow.requestIdleCallback) {
      idleHandle = idleWindow.requestIdleCallback(() => finish(true), { timeout: 800 });
    } else {
      timeoutHandle = window.setTimeout(() => finish(true), 32);
    }
  });
}

const WARMUP_CANCELLED = Symbol("warmup-cancelled");

function awaitWarmupResult<T>(
  promise: Promise<T>,
  run: PhaseWarmupRun
): Promise<T | typeof WARMUP_CANCELLED> {
  if (run.cancelled) return Promise.resolve(WARMUP_CANCELLED);
  return new Promise((resolve, reject) => {
    let settled = false;
    const finish = (value: T | typeof WARMUP_CANCELLED) => {
      if (settled) return;
      settled = true;
      run.pendingCancellationSettlers.delete(cancel);
      resolve(value);
    };
    const cancel = () => finish(WARMUP_CANCELLED);
    run.pendingCancellationSettlers.add(cancel);
    void promise.then(finish, (error: unknown) => {
      if (settled) return;
      settled = true;
      run.pendingCancellationSettlers.delete(cancel);
      reject(error);
    });
  });
}

export function getRpgRuntimeWarmupSnapshot(): RpgRuntimeWarmupSnapshot {
  return {
    ...latestPhaseSnapshot,
    failedUrls: [...latestPhaseSnapshot.failedUrls],
    phaseSnapshots: [...phaseSnapshots.values()].map((snapshot) => ({
      ...snapshot,
      failedUrls: [...snapshot.failedUrls]
    }))
  };
}

function warmupPhaseForScene(
  sceneId: RpgSceneId,
  phase?: ChapterFourWarmupPhase
): ChapterFourWarmupPhase | "scene" {
  return sceneId === "duan_yongping_temporal_maze" ? phase ?? "entry" : "scene";
}

function phaseKey(sceneId: RpgSceneId, phase: ChapterFourWarmupPhase | "scene"): string {
  return `${sceneId}:${phase}`;
}

function publishPhaseSnapshot(snapshot: RpgWarmupPhaseSnapshot): void {
  latestPhaseSnapshot = snapshot;
  phaseSnapshots.set(phaseKey(snapshot.sceneId, snapshot.phase), snapshot);
}

export function warmRpgRuntime(
  sceneId: RpgSceneId,
  strategy: "idle" | "immediate" = "immediate",
  requestedPhase?: ChapterFourWarmupPhase
): Promise<RpgRuntimeWarmupSnapshot> {
  const phase = warmupPhaseForScene(sceneId, requestedPhase);
  const key = phaseKey(sceneId, phase);
  const completed = phaseSnapshots.get(key);
  if (completed?.status === "ready") return Promise.resolve(getRpgRuntimeWarmupSnapshot());
  const existing = phaseWarmupRuns.get(key);
  if (existing) {
    if (strategy === "immediate") {
      existing.required = true;
      if (existing.cancelled) {
        return existing.promise.then(() => warmRpgRuntime(sceneId, strategy, requestedPhase));
      }
    }
    return existing.promise;
  }

  const run: PhaseWarmupRun = {
    promise: Promise.resolve(getRpgRuntimeWarmupSnapshot()),
    cancelled: false,
    required: strategy === "immediate",
    pendingCancellationSettlers: new Set()
  };

  const promise = (async () => {
    const constrainedNetwork = isConstrainedNetwork();
    const lowMemory = isLowMemoryDevice();
    const startedAtMs = nowMs();
    let snapshot: RpgWarmupPhaseSnapshot = {
      sceneId,
      phase,
      status: "loading_module",
      strategy,
      moduleReady: false,
      assetCount: 0,
      loadedCount: 0,
      reusedCount: 0,
      failedUrls: [],
      estimatedTransferBytes: 0,
      measuredTransferBytes: 0,
      estimatedDecodedBytes: 0,
      elapsedMs: 0,
      degradationReason: null,
      transferMeasurement: "unknown",
      warmedAssetCount: 0,
      failedAssetCount: 0,
      constrainedNetwork,
      lowMemory,
      startedAtMs,
      completedAtMs: null
    };
    publishPhaseSnapshot(snapshot);
    try {
      const moduleResult = await awaitWarmupResult(preloadRpgGameHost(), run);
      if (moduleResult === WARMUP_CANCELLED || run.cancelled) {
        const completedAtMs = nowMs();
        snapshot = {
          ...snapshot,
          status: "idle",
          elapsedMs: Math.max(0, completedAtMs - startedAtMs),
          completedAtMs
        };
        publishPhaseSnapshot(snapshot);
        return getRpgRuntimeWarmupSnapshot();
      }
      const module = moduleResult;
      publishPreloadedRpgGameHostModule(module);
      const assets = module.getRpgSceneWarmAssets(
        sceneId,
        phase === "scene" ? undefined : phase
      );
      let speculativeAssetCount = 0;
      let speculativeDegradation = false;
      snapshot = {
        ...snapshot,
        moduleReady: true,
        status: "loading",
        assetCount: assets.length,
        estimatedTransferBytes: assets.reduce((total, asset) => (
          total + estimateDataUrlBytes(asset.url)
        ), 0)
      };
      publishPhaseSnapshot(snapshot);
      for (const asset of assets) {
        if (!run.required && strategy === "idle" && (constrainedNetwork || lowMemory)
          && speculativeAssetCount >= 2) {
          speculativeDegradation = true;
          break;
        }
        if (!run.required && strategy === "idle") {
          const idle = await waitForWarmupIdleSlice(run);
          if (!idle) break;
        }
        if (run.cancelled) break;
        speculativeAssetCount += 1;
        try {
          const fallbackDecodedBytes = asset.sourceSize
            ? asset.sourceSize.width * asset.sourceSize.height * 4
            : 0;
          const warmed = warmImageUrl(asset.url, fallbackDecodedBytes);
          const warmedResult = await awaitWarmupResult(warmed.promise, run);
          if (warmedResult === WARMUP_CANCELLED) break;
          const result = warmedResult;
          const attemptMetrics = chapterFourWarmupAttemptMetrics(result, warmed.reused);
          snapshot = {
            ...snapshot,
            loadedCount: snapshot.loadedCount + (result.success ? 1 : 0),
            reusedCount: snapshot.reusedCount + (warmed.reused && result.success ? 1 : 0),
            warmedAssetCount: snapshot.warmedAssetCount + (result.success ? 1 : 0),
            failedAssetCount: snapshot.failedAssetCount + (result.success ? 0 : 1),
            failedUrls: result.success
              ? snapshot.failedUrls
              : [...snapshot.failedUrls, reportableWarmupAssetUrl(asset.key, asset.url)],
            measuredTransferBytes: snapshot.measuredTransferBytes + attemptMetrics.measuredTransferBytes,
            estimatedDecodedBytes: snapshot.estimatedDecodedBytes + attemptMetrics.estimatedDecodedBytes,
            transferMeasurement: snapshot.transferMeasurement === "measured" || attemptMetrics.transferMeasurement === "measured"
              ? "measured"
              : snapshot.transferMeasurement === "estimated" || attemptMetrics.transferMeasurement === "estimated"
                ? "estimated"
                : "unknown"
          };
          publishPhaseSnapshot(snapshot);
        } catch {
          snapshot = {
            ...snapshot,
            failedAssetCount: snapshot.failedAssetCount + 1,
            failedUrls: [
              ...snapshot.failedUrls,
              reportableWarmupAssetUrl(asset.key, asset.url)
            ]
          };
          publishPhaseSnapshot(snapshot);
        }
        if (run.cancelled) break;
        await yieldToBrowser();
      }
      const completedAtMs = nowMs();
      if (run.cancelled) {
        snapshot = {
          ...snapshot,
          status: "idle",
          elapsedMs: Math.max(0, completedAtMs - startedAtMs),
          completedAtMs
        };
        publishPhaseSnapshot(snapshot);
        return getRpgRuntimeWarmupSnapshot();
      }
      snapshot = {
        ...snapshot,
        status: snapshot.failedAssetCount > 0 || speculativeDegradation ? "degraded" : "ready",
        degradationReason: snapshot.failedAssetCount > 0
          ? "decode_failure"
          : speculativeDegradation
            ? constrainedNetwork ? "constrained_network" : "low_memory"
            : null,
        elapsedMs: Math.max(0, completedAtMs - startedAtMs),
        completedAtMs
      };
      publishPhaseSnapshot(snapshot);
      return getRpgRuntimeWarmupSnapshot();
    } catch {
      const completedAtMs = nowMs();
      snapshot = {
        ...snapshot,
        status: "failed",
        elapsedMs: Math.max(0, completedAtMs - startedAtMs),
        completedAtMs
      };
      publishPhaseSnapshot(snapshot);
      return getRpgRuntimeWarmupSnapshot();
    } finally {
      for (const settle of [...run.pendingCancellationSettlers]) settle();
      phaseWarmupRuns.delete(key);
    }
  })();
  run.promise = promise;
  phaseWarmupRuns.set(key, run);
  return promise;
}

/**
 * 在手机交互的空闲片段预热下一张 RPG 场景。Safari 15 没有
 * requestIdleCallback，因此保留零侵入的短延迟回退。
 */
export function scheduleRpgRuntimeWarmup(
  sceneId: RpgSceneId,
  requestedPhase?: ChapterFourWarmupPhase
): () => void {
  const phase = warmupPhaseForScene(sceneId, requestedPhase);
  const key = phaseKey(sceneId, phase);
  if (phaseWarmupRuns.has(key) || phaseSnapshots.get(key)?.status === "ready") return () => undefined;
  const scheduledSnapshot: RpgWarmupPhaseSnapshot = {
    ...(phaseSnapshots.get(key) ?? emptyPhaseSnapshot),
    sceneId,
    phase,
    status: "scheduled",
    strategy: "idle"
  };
  publishPhaseSnapshot(scheduledSnapshot);
  const idleWindow = window as IdleCallbackWindow;
  let cancelled = false;
  const start = () => {
    if (cancelled || document.visibilityState === "hidden") return;
    void warmRpgRuntime(sceneId, "idle", phase === "scene" ? undefined : phase);
  };
  if (idleWindow.requestIdleCallback) {
    const handle = idleWindow.requestIdleCallback(start, { timeout: 1_200 });
    return () => {
      cancelled = true;
      idleWindow.cancelIdleCallback?.(handle);
      cancelSpeculativePhaseWarmup(key);
    };
  }
  const handle = window.setTimeout(start, 180);
  return () => {
    cancelled = true;
    window.clearTimeout(handle);
    cancelSpeculativePhaseWarmup(key);
  };
}
