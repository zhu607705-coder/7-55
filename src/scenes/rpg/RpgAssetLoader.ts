import type Phaser from "phaser";

type RpgTextureKey = string;

export const RPG_ASSET_LOAD_REPORTER_REGISTRY_KEY = "rpgAssetLoadReporter";

export interface RpgAssetLoadFailure {
  key: string;
  url: string;
}

export interface RpgAssetLoadReport {
  sceneKey: string;
  status: "loading" | "ready" | "failed";
  progress: number;
  failedAssets: readonly RpgAssetLoadFailure[];
}

export type RpgAssetLoadReporter = (report: RpgAssetLoadReport) => void;

const configuredLoaders = new WeakSet<Phaser.Loader.LoaderPlugin>();

function resolveReporter(scene: Phaser.Scene): RpgAssetLoadReporter | null {
  const reporter = scene.registry.get(RPG_ASSET_LOAD_REPORTER_REGISTRY_KEY) as unknown;
  return typeof reporter === "function" ? reporter as RpgAssetLoadReporter : null;
}

function reportAssetLoad(scene: Phaser.Scene, report: Omit<RpgAssetLoadReport, "sceneKey">): void {
  const reporter = resolveReporter(scene);
  if (!reporter) return;
  reporter({
    ...report,
    sceneKey: scene.scene.key
  });
}

/**
 * Each Phaser Scene owns one LoaderPlugin. Install reporting once per loader so
 * every scene-local preload, including direct `scene.load.*` calls, follows the
 * same visible loading and recovery contract.
 */
export function configureRpgSceneAssetLoading(scene: Phaser.Scene): void {
  const loader = scene.load;
  if (configuredLoaders.has(loader)) return;
  configuredLoaders.add(loader);

  let blockingStartupLoad = false;
  let progress = 0;
  let failures: RpgAssetLoadFailure[] = [];
  loader.on("start", () => {
    // Runtime-only speculative loads run after the Scene reaches RUNNING and
    // must stay silent. The full-screen boundary is reserved for startup loads
    // that are required before create() can present a complete map.
    blockingStartupLoad = !scene.sys.isActive();
    if (!blockingStartupLoad) return;
    progress = 0;
    failures = [];
    reportAssetLoad(scene, { status: "loading", progress, failedAssets: failures });
  });
  loader.on("progress", (value: number) => {
    if (!blockingStartupLoad) return;
    progress = Math.max(0, Math.min(1, Number.isFinite(value) ? value : 0));
    reportAssetLoad(scene, { status: "loading", progress, failedAssets: failures });
  });
  loader.on("loaderror", (file: Phaser.Loader.File) => {
    if (!blockingStartupLoad) return;
    const failure = {
      key: String(file.key ?? "unknown"),
      url: typeof file.url === "string" ? file.url : "unknown"
    };
    if (!failures.some((candidate) => candidate.key === failure.key && candidate.url === failure.url)) {
      failures = [...failures, failure];
    }
    reportAssetLoad(scene, { status: "loading", progress, failedAssets: failures });
  });
  loader.on("complete", () => {
    if (!blockingStartupLoad) return;
    reportAssetLoad(scene, {
      status: failures.length > 0 ? "failed" : "ready",
      progress: failures.length > 0 ? progress : 1,
      failedAssets: failures
    });
    blockingStartupLoad = false;
  });
}

/**
 * Shared idempotent asset-loading helpers for Phaser RPG scenes. Keeping the
 * texture-existence guard here prevents scene-local preload code from drifting
 * and avoids duplicate queue entries when a scene is restarted.
 */
export function preloadRpgImage(
  scene: Phaser.Scene,
  key: RpgTextureKey,
  url: string
): void {
  configureRpgSceneAssetLoading(scene);
  if (!scene.textures.exists(key)) {
    scene.load.setCORS("anonymous");
    scene.load.image(key, url);
  }
}

export function preloadRpgImages(
  scene: Phaser.Scene,
  entries: Iterable<readonly [RpgTextureKey, string]>
): void {
  configureRpgSceneAssetLoading(scene);
  for (const [key, url] of entries) {
    preloadRpgImage(scene, key, url);
  }
}

export function preloadRpgSpriteSheet(
  scene: Phaser.Scene,
  key: RpgTextureKey,
  url: string,
  frameConfig: Phaser.Types.Loader.FileTypes.ImageFrameConfig
): void {
  configureRpgSceneAssetLoading(scene);
  if (!scene.textures.exists(key)) {
    scene.load.setCORS("anonymous");
    scene.load.spritesheet(key, url, frameConfig);
  }
}
