type RpgGameHostModule = typeof import("./RpgGameHost");

import type { RpgSceneId } from "../../core/types";

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
  | "loading_assets"
  | "ready"
  | "degraded"
  | "failed";

export interface RpgRuntimeWarmupSnapshot {
  sceneId: RpgSceneId | null;
  status: RpgWarmupStatus;
  strategy: "idle" | "immediate" | null;
  moduleReady: boolean;
  assetCount: number;
  warmedAssetCount: number;
  failedAssetCount: number;
  constrainedNetwork: boolean;
  startedAtMs: number | null;
  completedAtMs: number | null;
}

type IdleCallbackWindow = Window & {
  requestIdleCallback?: (callback: () => void, options?: { timeout: number }) => number;
  cancelIdleCallback?: (handle: number) => void;
};
type NavigatorWithConnection = Navigator & {
  connection?: { saveData?: boolean; effectiveType?: string };
};

let warmupSnapshot: RpgRuntimeWarmupSnapshot = {
  sceneId: null,
  status: "idle",
  strategy: null,
  moduleReady: false,
  assetCount: 0,
  warmedAssetCount: 0,
  failedAssetCount: 0,
  constrainedNetwork: false,
  startedAtMs: null,
  completedAtMs: null
};
const sceneWarmupPromises = new Map<RpgSceneId, Promise<RpgRuntimeWarmupSnapshot>>();
const imageWarmupPromises = new Map<string, Promise<boolean>>();

function nowMs(): number {
  return typeof performance === "undefined" ? Date.now() : performance.now();
}

function isConstrainedNetwork(): boolean {
  if (typeof navigator === "undefined") return false;
  const connection = (navigator as NavigatorWithConnection).connection;
  return connection?.saveData === true || connection?.effectiveType === "slow-2g" || connection?.effectiveType === "2g";
}

function warmImageUrl(url: string): Promise<boolean> {
  const existing = imageWarmupPromises.get(url);
  if (existing) return existing;
  const promise = new Promise<boolean>((resolve) => {
    if (typeof Image === "undefined") {
      resolve(true);
      return;
    }
    const image = new Image();
    let settled = false;
    const finish = (result: boolean) => {
      if (settled) return;
      settled = true;
      window.clearTimeout(timeout);
      image.onload = null;
      image.onerror = null;
      resolve(result);
    };
    const timeout = window.setTimeout(() => finish(false), 15_000);
    image.decoding = "async";
    image.onload = () => {
      if (typeof image.decode !== "function") {
        finish(true);
        return;
      }
      void image.decode().then(() => finish(true), () => finish(true));
    };
    image.onerror = () => finish(false);
    image.src = url;
  }).then((result) => {
    if (!result) imageWarmupPromises.delete(url);
    return result;
  });
  imageWarmupPromises.set(url, promise);
  return promise;
}

function yieldToBrowser(): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, 0));
}

export function getRpgRuntimeWarmupSnapshot(): RpgRuntimeWarmupSnapshot {
  return { ...warmupSnapshot };
}

export function warmRpgRuntime(
  sceneId: RpgSceneId,
  strategy: "idle" | "immediate" = "immediate"
): Promise<RpgRuntimeWarmupSnapshot> {
  const existing = sceneWarmupPromises.get(sceneId);
  if (existing) return existing;

  const promise = (async () => {
    const constrainedNetwork = isConstrainedNetwork();
    warmupSnapshot = {
      sceneId,
      status: "loading_module",
      strategy,
      moduleReady: false,
      assetCount: 0,
      warmedAssetCount: 0,
      failedAssetCount: 0,
      constrainedNetwork,
      startedAtMs: nowMs(),
      completedAtMs: null
    };
    try {
      const module = await preloadRpgGameHost();
      publishPreloadedRpgGameHostModule(module);
      warmupSnapshot = { ...warmupSnapshot, moduleReady: true };
      if (constrainedNetwork) {
        warmupSnapshot = {
          ...warmupSnapshot,
          status: "degraded",
          completedAtMs: nowMs()
        };
        return getRpgRuntimeWarmupSnapshot();
      }
      const urls = module.getRpgSceneWarmAssetUrls(sceneId);
      warmupSnapshot = {
        ...warmupSnapshot,
        status: "loading_assets",
        assetCount: urls.length
      };
      for (const url of urls) {
        try {
          const warmed = await warmImageUrl(url);
          warmupSnapshot = {
            ...warmupSnapshot,
            warmedAssetCount: warmupSnapshot.warmedAssetCount + (warmed ? 1 : 0),
            failedAssetCount: warmupSnapshot.failedAssetCount + (warmed ? 0 : 1)
          };
        } catch {
          warmupSnapshot = {
            ...warmupSnapshot,
            failedAssetCount: warmupSnapshot.failedAssetCount + 1
          };
        }
        await yieldToBrowser();
      }
      warmupSnapshot = {
        ...warmupSnapshot,
        status: warmupSnapshot.failedAssetCount > 0 ? "degraded" : "ready",
        completedAtMs: nowMs()
      };
      return getRpgRuntimeWarmupSnapshot();
    } catch {
      warmupSnapshot = {
        ...warmupSnapshot,
        status: "failed",
        completedAtMs: nowMs()
      };
      sceneWarmupPromises.delete(sceneId);
      return getRpgRuntimeWarmupSnapshot();
    }
  })();
  sceneWarmupPromises.set(sceneId, promise);
  return promise;
}

/**
 * 在手机交互的空闲片段预热下一张 RPG 场景。Safari 15 没有
 * requestIdleCallback，因此保留零侵入的短延迟回退。
 */
export function scheduleRpgRuntimeWarmup(sceneId: RpgSceneId): () => void {
  if (sceneWarmupPromises.has(sceneId)) return () => undefined;
  warmupSnapshot = {
    ...warmupSnapshot,
    sceneId,
    status: "scheduled",
    strategy: "idle"
  };
  const idleWindow = window as IdleCallbackWindow;
  let cancelled = false;
  const start = () => {
    if (cancelled || document.visibilityState === "hidden") return;
    void warmRpgRuntime(sceneId, "idle");
  };
  if (idleWindow.requestIdleCallback) {
    const handle = idleWindow.requestIdleCallback(start, { timeout: 1_200 });
    return () => {
      cancelled = true;
      idleWindow.cancelIdleCallback?.(handle);
    };
  }
  const handle = window.setTimeout(start, 180);
  return () => {
    cancelled = true;
    window.clearTimeout(handle);
  };
}
