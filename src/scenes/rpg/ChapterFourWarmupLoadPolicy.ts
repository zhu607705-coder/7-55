import {
  CHAPTER_FOUR_WARMUP_ASSETS,
  type ChapterFourWarmupAsset,
  type ChapterFourWarmupPhase
} from "./ChapterFourWarmupAssets";

export type ChapterFourWarmupPriority = "required" | "speculative";

export interface ChapterFourWarmupConstraints {
  constrainedNetwork: boolean;
  lowMemory: boolean;
}

export interface ChapterFourWarmupReadiness {
  readyPhases: ChapterFourWarmupPhase[];
  missingByPhase: Record<ChapterFourWarmupPhase, string[]>;
}

export interface ChapterFourWarmupRetryBlocker {
  phase: ChapterFourWarmupPhase;
  retryAfterMs: number;
}

export interface ChapterFourWarmupBatchOptions {
  assets: readonly ChapterFourWarmupAsset[];
  priority: ChapterFourWarmupPriority;
  constraints: ChapterFourWarmupConstraints;
  isCancelled: () => boolean;
  isLoaded: (asset: ChapterFourWarmupAsset) => boolean;
  waitForIdle: () => Promise<boolean>;
  loadAsset: (asset: ChapterFourWarmupAsset) => Promise<boolean>;
}

export interface ChapterFourWarmupBatchResult {
  ready: boolean;
  limited: boolean;
  cancelled: boolean;
  attemptedKeys: string[];
  failedUrls: string[];
}

export interface ChapterFourWarmupImageMetrics {
  measuredTransferBytes: number;
  estimatedDecodedBytes: number;
  transferMeasurement: "measured" | "estimated" | "unknown";
}

export function inspectChapterFourWarmupPhaseReadiness(
  phases: readonly ChapterFourWarmupPhase[],
  hasTexture: (key: string) => boolean
): ChapterFourWarmupReadiness {
  const missingByPhase = Object.fromEntries(
    (Object.keys(CHAPTER_FOUR_WARMUP_ASSETS) as ChapterFourWarmupPhase[])
      .map((phase) => [phase, [] as string[]])
  ) as Record<ChapterFourWarmupPhase, string[]>;
  const readyPhases: ChapterFourWarmupPhase[] = [];

  for (const phase of phases) {
    const missing = CHAPTER_FOUR_WARMUP_ASSETS[phase]
      .filter((asset) => !hasTexture(asset.key))
      .map((asset) => asset.key);
    missingByPhase[phase] = missing;
    if (missing.length === 0) readyPhases.push(phase);
  }

  return { readyPhases, missingByPhase };
}

export function selectChapterFourWarmupRetryBlocker(
  phases: readonly ChapterFourWarmupPhase[],
  isLoaded: (phase: ChapterFourWarmupPhase) => boolean,
  retryNotBeforeMs: ReadonlyMap<ChapterFourWarmupPhase, number>,
  nowMs: number
): ChapterFourWarmupRetryBlocker | null {
  for (const phase of phases) {
    if (isLoaded(phase)) continue;
    return {
      phase,
      retryAfterMs: Math.max(0, (retryNotBeforeMs.get(phase) ?? 0) - nowMs)
    };
  }
  return null;
}

export function chapterFourWarmupAttemptMetrics(
  result: ChapterFourWarmupImageMetrics,
  reused: boolean
): ChapterFourWarmupImageMetrics {
  if (!reused) return result;
  return {
    measuredTransferBytes: 0,
    estimatedDecodedBytes: 0,
    transferMeasurement: "unknown"
  };
}

export async function runChapterFourWarmupAssetBatch(
  options: ChapterFourWarmupBatchOptions
): Promise<ChapterFourWarmupBatchResult> {
  const pendingAssets = options.assets.filter((asset) => !options.isLoaded(asset));
  const shouldLimit = options.priority === "speculative"
    && (options.constraints.constrainedNetwork || options.constraints.lowMemory)
    && pendingAssets.length > 2;
  const selectedAssets = shouldLimit ? pendingAssets.slice(0, 2) : pendingAssets;
  const attemptedKeys: string[] = [];
  const failedUrls: string[] = [];

  for (const asset of selectedAssets) {
    if (options.isCancelled()) {
      return { ready: false, limited: shouldLimit, cancelled: true, attemptedKeys, failedUrls };
    }
    if (options.priority === "speculative") {
      const idle = await options.waitForIdle();
      if (!idle || options.isCancelled()) {
        return { ready: false, limited: shouldLimit, cancelled: true, attemptedKeys, failedUrls };
      }
    }
    attemptedKeys.push(asset.key);
    const loaded = await options.loadAsset(asset);
    if (!loaded) failedUrls.push(asset.url);
    if (options.isCancelled()) {
      return { ready: false, limited: shouldLimit, cancelled: true, attemptedKeys, failedUrls };
    }
  }

  const ready = !shouldLimit
    && failedUrls.length === 0
    && options.assets.every((asset) => options.isLoaded(asset));
  return {
    ready,
    limited: shouldLimit,
    cancelled: false,
    attemptedKeys,
    failedUrls
  };
}
