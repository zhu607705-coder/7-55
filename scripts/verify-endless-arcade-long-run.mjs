import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { performance } from "node:perf_hooks";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { build } from "esbuild";

export const ENDLESS_ARCADE_LONG_RUN_DURATION_MS = 30 * 60 * 1_000;

const MIDPOINT_MS = ENDLESS_ARCADE_LONG_RUN_DURATION_MS / 2;
const PRIMARY_SEED = 755;
const ALTERNATE_SEED = 756;
const BIKE_STEP_MS = 100;
const MODELED_MEMORY_MODEL_ID = "pure-rules-resident-units-v1";
const MODELED_MEMORY_UNIT = "modeled_resident_unit";
const MODELED_MEMORY_WEIGHTS = Object.freeze({
  activeRuntimeCount: 64,
  activeObjects: 8,
  activeEntries: 3,
  activeContainers: 12,
  history: 2,
  listeners: 4,
  timers: 4,
});
const RETAINED_RESULT_LISTENER_COUNT = 8;

const SOURCE_PATHS = Object.freeze({
  fishingRules: "src/scenes/phone/P16_BikeArcade/EndlessFishingRules.ts",
  spotlightRules: "src/scenes/phone/P16_BikeArcade/EndlessSpotlightRules.ts",
  bikeRules: "src/scenes/phone/P16_BikeArcade/BikeArcadeRules.ts",
  limits: "src/core/EndlessArcadeLimits.ts",
  runtime: "src/scenes/phone/P16_BikeArcade/EndlessArcadeRuntime.ts",
  controller: "src/modules/EndlessArcadeController.ts",
  gameState: "src/core/GameState.ts",
  saveStore: "src/core/SaveStore.ts",
  fishingScene: "src/scenes/phone/P16_BikeArcade/EndlessFishingScene.ts",
  spotlightScene: "src/scenes/phone/P16_BikeArcade/EndlessSpotlightScene.ts",
  bikeScene: "src/scenes/phone/P16_BikeArcade/BikeRushScene.ts",
  host: "src/scenes/phone/P16_BikeArcade/EndlessArcadeGameHost.tsx",
});

const MODE_LISTENER_COUNTS = Object.freeze({
  // P16 pointer/lifecycle fallback (5), Host visibility/blur/pagehide (3),
  // scene keyboard down/up plus shutdown and destroy (4).
  fishing: 12,
  spotlight: 12,
  // P16 fallback (5), Host lifecycle (3), scene visibility/blur/focus (3),
  // four keys, pointer, shutdown and destroy (7).
  bike: 18,
});

function calculateModeledResidentUnits(counts) {
  return Object.entries(MODELED_MEMORY_WEIGHTS).reduce(
    (total, [key, weight]) => total + counts[key] * weight,
    0
  );
}

class ActiveRuntimeFleet {
  #active = new Set();
  #sequence = 0;

  mount(mode) {
    const token = `${mode}:${this.#sequence += 1}`;
    this.#active.add(token);
    return token;
  }

  release(token) {
    this.#active.delete(token);
  }

  get activeRuntimeCount() {
    return this.#active.size;
  }
}

class RuntimeResourceProbe {
  #fleet;
  #token = null;
  #mode;
  #caps;
  #counts = {
    activeObjects: 0,
    activeEntries: 0,
    activeContainers: 0,
    history: 0,
    listeners: 0,
    timers: 0,
    modeledResidentUnits: 0,
  };
  #max = {
    activeObjects: 0,
    activeEntries: 0,
    activeContainers: 0,
    history: 0,
    listeners: 0,
    timers: 0,
    modeledResidentUnits: 0,
  };

  constructor(fleet, mode, caps) {
    this.#fleet = fleet;
    this.#mode = mode;
    this.#caps = Object.freeze({
      ...caps,
      modeledResidentUnits: calculateModeledResidentUnits({
        activeRuntimeCount: 1,
        ...caps,
      }),
    });
  }

  mount() {
    if (this.#token !== null) throw new Error(`${this.#mode} probe mounted twice`);
    this.#token = this.#fleet.mount(this.#mode);
    this.#counts.listeners = this.#caps.listeners;
    this.#counts.timers = 1;
    this.#observe();
    // The host boot timeout is cleared once the scene reaches running.
    this.#counts.timers = 0;
    this.#observe();
  }

  update({ activeObjects, activeEntries, activeContainers, history, timers = 0 }) {
    if (this.#token === null) throw new Error(`${this.#mode} resource update without an active runtime`);
    this.#counts.activeObjects = activeObjects;
    this.#counts.activeEntries = activeEntries;
    this.#counts.activeContainers = activeContainers;
    this.#counts.history = history;
    this.#counts.timers = timers;
    this.#observe();
  }

  sample(label, elapsedMs) {
    return Object.freeze({
      label,
      elapsedMs: Math.round(elapsedMs),
      activeRuntimeCount: this.#fleet.activeRuntimeCount,
      ...this.#counts,
    });
  }

  cleanup(kind, retainedListeners = 0) {
    if (this.#token !== null) {
      this.#fleet.release(this.#token);
      this.#token = null;
    }
    this.#counts = {
      activeObjects: 0,
      activeEntries: 0,
      activeContainers: 0,
      history: 0,
      listeners: retainedListeners,
      timers: 0,
      modeledResidentUnits: calculateModeledResidentUnits({
        activeRuntimeCount: 0,
        activeObjects: 0,
        activeEntries: 0,
        activeContainers: 0,
        history: 0,
        listeners: retainedListeners,
        timers: 0,
      }),
    };
    return this.sample(kind, ENDLESS_ARCADE_LONG_RUN_DURATION_MS);
  }

  get maximums() {
    return Object.freeze({ ...this.#max });
  }

  get caps() {
    return this.#caps;
  }

  #observe() {
    this.#counts.modeledResidentUnits = calculateModeledResidentUnits({
      activeRuntimeCount: this.#token === null ? 0 : 1,
      ...this.#counts,
    });
    for (const key of Object.keys(this.#max)) {
      const value = this.#counts[key];
      if (!Number.isSafeInteger(value) || value < 0) {
        throw new Error(`${this.#mode} ${key} must remain a non-negative safe integer`);
      }
      this.#max[key] = Math.max(this.#max[key], value);
    }
  }
}

function updateFingerprint(hash, value) {
  const text = typeof value === "string" ? value : JSON.stringify(value);
  let next = hash >>> 0;
  for (let index = 0; index < text.length; index += 1) {
    next ^= text.charCodeAt(index);
    next = Math.imul(next, 16_777_619);
  }
  return next >>> 0;
}

function formatFingerprint(hash) {
  return (hash >>> 0).toString(16).padStart(8, "0");
}

function countFishingVisualObjects(segment) {
  return segment.notes.reduce((count, note) => count + 2 + (note.hold === undefined ? 0 : 1), 0);
}

function createModeledMemoryReport(probe, samples) {
  const byLabel = Object.fromEntries(samples.map((sample) => [sample.label, sample]));
  const start = byLabel.start?.modeledResidentUnits ?? 0;
  const mid = byLabel.mid?.modeledResidentUnits ?? 0;
  const end = byLabel.end?.modeledResidentUnits ?? 0;
  const maximum = probe.maximums.modeledResidentUnits;
  const budget = probe.caps.modeledResidentUnits;
  const bounded = maximum <= budget && end <= budget;
  const trend = !bounded
    ? "unbounded_growth"
    : end <= mid
      ? "plateau_or_down"
      : "bounded_fluctuation";
  return Object.freeze({
    model: MODELED_MEMORY_MODEL_ID,
    scope: "pure_rules_resource_counts_only",
    unit: MODELED_MEMORY_UNIT,
    browserHeapMeasured: false,
    start,
    mid,
    end,
    maximum,
    budget,
    midToEndDelta: end - mid,
    bounded,
    trend,
  });
}

function createRunResult({
  mode,
  seed,
  summary,
  fingerprint,
  probe,
  samples,
  details,
}) {
  const modeledMemory = createModeledMemoryReport(probe, samples);
  const afterExit = probe.cleanup("after_exit");
  const afterRepeatedExit = probe.cleanup("after_repeated_exit");
  return Object.freeze({
    mode,
    seed,
    summary: Object.freeze(summary),
    fingerprint: formatFingerprint(fingerprint),
    resources: Object.freeze({
      maximums: probe.maximums,
      caps: probe.caps,
      samples: Object.freeze([...samples, afterExit]),
      afterRepeatedExit,
      modeledMemory,
    }),
    details: Object.freeze(details),
  });
}

function simulateFishing(rules, seed, fleet) {
  const probe = new RuntimeResourceProbe(fleet, "fishing", {
    activeObjects: rules.MAX_FISHING_NOTES_PER_SEGMENT * 3,
    activeEntries: rules.MAX_FISHING_NOTES_PER_SEGMENT,
    activeContainers: rules.MAX_BUFFERED_FISHING_SEGMENTS,
    history: rules.MAX_FISHING_SEGMENT_HISTORY,
    listeners: MODE_LISTENER_COUNTS.fishing,
    timers: 1,
  });
  probe.mount();

  let elapsedMs = 0;
  let completedSegments = 0;
  let segmentIndex = 0;
  let score = 0;
  let combo = 0;
  let maxCombo = 0;
  let tier = 1;
  let history = [];
  let fingerprint = 2_166_136_261;
  let midpointSample = null;
  let lastSegment = null;
  const samples = [];

  while (elapsedMs < ENDLESS_ARCADE_LONG_RUN_DURATION_MS) {
    const segment = rules.createEndlessFishingSegment(seed, segmentIndex);
    lastSegment = segment;
    tier = segment.tier;
    probe.update({
      activeObjects: countFishingVisualObjects(segment),
      activeEntries: segment.notes.length,
      activeContainers: 1,
      history: history.length,
    });
    if (samples.length === 0) samples.push(probe.sample("start", 0));

    fingerprint = updateFingerprint(fingerprint, {
      id: segment.id,
      bpm: segment.bpm,
      bars: segment.bars,
      notes: segment.notes,
    });
    const segmentDurationMs = segment.durationSeconds * 1_000;
    const remainingMs = ENDLESS_ARCADE_LONG_RUN_DURATION_MS - elapsedMs;
    const activeDurationMs = Math.min(segmentDurationMs, remainingMs);

    for (const note of segment.notes) {
      const noteTimeMs = note.beat * segment.beatSec * 1_000;
      if (noteTimeMs > activeDurationMs) break;
      combo = Math.min(rules.MAX_ENDLESS_FISHING_COMBO, combo + 1);
      maxCombo = Math.max(maxCombo, combo);
      score = Math.min(
        rules.MAX_ENDLESS_FISHING_SCORE,
        score + rules.calculateEndlessFishingScore({
          tier,
          combo,
          judgment: "perfect",
        })
      );
    }

    if (midpointSample === null && elapsedMs <= MIDPOINT_MS && elapsedMs + activeDurationMs >= MIDPOINT_MS) {
      midpointSample = probe.sample("mid", MIDPOINT_MS);
    }

    elapsedMs += activeDurationMs;
    if (activeDurationMs + Number.EPSILON >= segmentDurationMs) {
      completedSegments += 1;
      history = rules.appendFishingSegmentHistory(history, segmentIndex);
      segmentIndex += 1;
    }
  }

  if (midpointSample === null) midpointSample = probe.sample("mid", MIDPOINT_MS);
  probe.update({
    activeObjects: lastSegment ? countFishingVisualObjects(lastSegment) : 0,
    activeEntries: lastSegment?.notes.length ?? 0,
    activeContainers: lastSegment ? 1 : 0,
    history: history.length,
  });
  samples.push(midpointSample, probe.sample("end", ENDLESS_ARCADE_LONG_RUN_DURATION_MS));

  return createRunResult({
    mode: "fishing",
    seed,
    summary: {
      score,
      progress: completedSegments,
      tier,
      combo: maxCombo,
      durationMs: ENDLESS_ARCADE_LONG_RUN_DURATION_MS,
    },
    fingerprint,
    probe,
    samples,
    details: {
      completedSegments,
      generatedSegments: segmentIndex + (lastSegment ? 1 : 0),
      maxActiveNoteVisuals: probe.maximums.activeObjects,
      maxActiveNotes: probe.maximums.activeEntries,
      historyLength: history.length,
    },
  });
}

function simulateSpotlight(rules, seed, fleet) {
  const probe = new RuntimeResourceProbe(fleet, "spotlight", {
    activeObjects: 11,
    activeEntries: rules.MAX_SPOTLIGHT_PATH_POINTS + rules.MAX_SPOTLIGHT_DECOY_POINTS,
    activeContainers: 1,
    history: rules.MAX_SPOTLIGHT_HISTORY,
    listeners: MODE_LISTENER_COUNTS.spotlight,
    timers: 1,
  });
  probe.mount();

  let elapsedMs = 0;
  let completedWaves = 0;
  let waveIndex = 0;
  let score = 0;
  let combo = 0;
  let maxCombo = 0;
  let tier = 1;
  let history = [];
  let fingerprint = 2_166_136_261;
  let midpointSample = null;
  let lastWave = null;
  const samples = [];

  while (elapsedMs < ENDLESS_ARCADE_LONG_RUN_DURATION_MS) {
    const wave = rules.createEndlessSpotlightWave(seed, waveIndex);
    lastWave = wave;
    tier = wave.tier;
    const activePoints = wave.pathPoints.length + wave.decoyPathPoints.length;
    probe.update({
      activeObjects: 11,
      activeEntries: activePoints,
      activeContainers: 1,
      history: history.length,
    });
    if (samples.length === 0) samples.push(probe.sample("start", 0));

    fingerprint = updateFingerprint(fingerprint, {
      id: wave.id,
      lane: wave.lane,
      previewMs: wave.previewMs,
      actionMs: wave.actionMs,
      requiredLockMs: wave.requiredLockMs,
      pathPoints: wave.pathPoints,
      decoyPathPoints: wave.decoyPathPoints,
    });
    // Use the complete authored action window plus transition time. This is a
    // conservative pure-rule workload oracle and does not assume an instant
    // beam lock or attempt to replay Phaser pointer movement in Node.
    const completedWaveBudgetMs = wave.previewMs + wave.actionMs + 400;
    const remainingMs = ENDLESS_ARCADE_LONG_RUN_DURATION_MS - elapsedMs;
    const activeDurationMs = Math.min(completedWaveBudgetMs, remainingMs);
    if (midpointSample === null && elapsedMs <= MIDPOINT_MS && elapsedMs + activeDurationMs >= MIDPOINT_MS) {
      midpointSample = probe.sample("mid", MIDPOINT_MS);
    }
    elapsedMs += activeDurationMs;

    if (activeDurationMs >= completedWaveBudgetMs) {
      completedWaves += 1;
      combo = Math.min(1_000_000, combo + 1);
      maxCombo = Math.max(maxCombo, combo);
      score = Math.min(
        rules.MAX_ENDLESS_SPOTLIGHT_SCORE,
        score + rules.scoreEndlessSpotlight(tier, wave.requiredLockMs, combo)
      );
      history = rules.appendSpotlightHistory(history, waveIndex);
      waveIndex += 1;
    }
  }

  if (midpointSample === null) midpointSample = probe.sample("mid", MIDPOINT_MS);
  probe.update({
    activeObjects: lastWave ? 11 : 0,
    activeEntries: lastWave ? lastWave.pathPoints.length + lastWave.decoyPathPoints.length : 0,
    activeContainers: lastWave ? 1 : 0,
    history: history.length,
  });
  samples.push(midpointSample, probe.sample("end", ENDLESS_ARCADE_LONG_RUN_DURATION_MS));

  return createRunResult({
    mode: "spotlight",
    seed,
    summary: {
      score,
      progress: completedWaves,
      tier,
      combo: maxCombo,
      durationMs: ENDLESS_ARCADE_LONG_RUN_DURATION_MS,
    },
    fingerprint,
    probe,
    samples,
    details: {
      completedWaves,
      generatedWaves: waveIndex + (lastWave ? 1 : 0),
      maxActiveGameObjects: probe.maximums.activeObjects,
      maxActivePathEntries: probe.maximums.activeEntries,
      historyLength: history.length,
    },
  });
}

function simulateBike(rules, seed, fleet) {
  const probe = new RuntimeResourceProbe(fleet, "bike", {
    activeObjects: rules.MAX_BIKE_ARCADE_OBSTACLES + rules.MAX_BIKE_ARCADE_IMPACT_PARTICLES + 3,
    activeEntries: rules.MAX_BIKE_ARCADE_OBSTACLES,
    activeContainers: 1,
    history: rules.MAX_BIKE_ARCADE_WAVE_HISTORY,
    listeners: MODE_LISTENER_COUNTS.bike,
    timers: 1,
  });
  probe.mount();

  let elapsedMs = 0;
  let distance = 0;
  let scoreBonus = 0;
  let combo = 0;
  let maxCombo = 0;
  let waveIndex = 0;
  let safeLane = 1;
  let playerLane = 1;
  let spawnDelayMs = 720;
  let history = [];
  let obstacles = [];
  let lapBoards = [];
  let unsolvableWaves = 0;
  let fingerprint = 2_166_136_261;
  let midpointSample = null;
  const samples = [];

  probe.update({ activeObjects: 0, activeEntries: 0, activeContainers: 1, history: 0 });
  samples.push(probe.sample("start", 0));

  while (elapsedMs < ENDLESS_ARCADE_LONG_RUN_DURATION_MS) {
    const deltaMs = Math.min(BIKE_STEP_MS, ENDLESS_ARCADE_LONG_RUN_DURATION_MS - elapsedMs);
    const previousDistance = distance;
    distance = rules.advanceBikeDistance(distance, deltaMs, "endless");
    lapBoards = lapBoards
      .map((remainingMs) => remainingMs - deltaMs)
      .filter((remainingMs) => remainingMs > 0);
    const previousCompletedLaps = Math.floor(previousDistance / rules.BIKE_ARCADE_GOAL);
    const nextCompletedLaps = Math.floor(distance / rules.BIKE_ARCADE_GOAL);
    for (let lap = previousCompletedLaps; lap < nextCompletedLaps; lap += 1) {
      // One container + panel + label, retained for the 900ms tween and 360ms hold.
      lapBoards.push(1_260);
    }
    const speed = rules.bikeObstacleSpeed(distance, "endless");
    const nextObstacles = [];
    for (const obstacle of obstacles) {
      const nextY = obstacle.y + speed * deltaMs / 1_000;
      if (nextY > 720) {
        if (Math.abs(obstacle.lane - playerLane) === 1) {
          combo = Math.min(rules.BIKE_ARCADE_MAX_COMBO, combo + 1);
          maxCombo = Math.max(maxCombo, combo);
          scoreBonus = Math.min(
            rules.BIKE_ARCADE_MAX_DISTANCE,
            scoreBonus + rules.scoreBikeNearMiss(combo, rules.getBikeArcadeTier(distance))
          );
        }
      } else {
        nextObstacles.push({ ...obstacle, y: nextY });
      }
    }
    obstacles = nextObstacles;

    spawnDelayMs -= deltaMs;
    if (spawnDelayMs <= 0) {
      const plan = rules.planSeededBikeObstacleWave({
        distance,
        previousSafeLane: safeLane,
        mode: "endless",
        seed,
        waveIndex,
      });
      if (!rules.isBikeObstacleWaveSolvable(plan, safeLane, "endless")) {
        unsolvableWaves += 1;
      }
      fingerprint = updateFingerprint(fingerprint, {
        waveIndex,
        safeLane: plan.safeLane,
        spawnDelayMs: plan.spawnDelayMs,
        obstacles: plan.obstacles,
      });
      const availableSlots = Math.max(0, rules.MAX_BIKE_ARCADE_OBSTACLES - obstacles.length);
      for (const obstacle of plan.obstacles.slice(0, availableSlots)) {
        obstacles.push({ lane: obstacle.lane, type: obstacle.type, y: -55 });
      }
      safeLane = plan.safeLane;
      playerLane = safeLane;
      spawnDelayMs = plan.spawnDelayMs;
      history = rules.appendBikeWaveHistory(history, waveIndex);
      waveIndex = Math.min(rules.BIKE_ARCADE_MAX_DISTANCE, waveIndex + 1);
    }

    elapsedMs += deltaMs;
    probe.update({
      activeObjects: obstacles.length + lapBoards.length * 3,
      activeEntries: obstacles.length,
      activeContainers: 1,
      history: history.length,
    });
    if (midpointSample === null && elapsedMs >= MIDPOINT_MS) {
      midpointSample = probe.sample("mid", MIDPOINT_MS);
    }
  }

  if (midpointSample === null) midpointSample = probe.sample("mid", MIDPOINT_MS);
  samples.push(midpointSample, probe.sample("end", ENDLESS_ARCADE_LONG_RUN_DURATION_MS));
  const tier = rules.getBikeArcadeTier(distance);
  const score = Math.min(rules.BIKE_ARCADE_MAX_SCORE, Math.floor(distance) + scoreBonus);

  return createRunResult({
    mode: "bike",
    seed,
    summary: {
      score,
      progress: Math.floor(distance),
      tier,
      combo: maxCombo,
      durationMs: ENDLESS_ARCADE_LONG_RUN_DURATION_MS,
    },
    fingerprint,
    probe,
    samples,
    details: {
      generatedWaves: waveIndex,
      maxActiveDynamicObjects: probe.maximums.activeObjects,
      maxActiveObstacles: probe.maximums.activeEntries,
      maxImpactParticles: 0,
      historyLength: history.length,
      unsolvableWaves,
      distance: Number(distance.toFixed(3)),
    },
  });
}

function deterministicProjection(result) {
  return {
    mode: result.mode,
    seed: result.seed,
    summary: result.summary,
    fingerprint: result.fingerprint,
    resources: result.resources,
    details: result.details,
  };
}

function isSafeSummary(summary) {
  return ["score", "progress", "tier", "combo", "durationMs"].every((key) => (
    Number.isSafeInteger(summary[key]) && summary[key] >= 0
  ));
}

function resourcesAreBounded(result) {
  const { maximums } = result.resources;
  const { caps } = result.resources;
  return Object.keys(maximums).every((key) => maximums[key] <= caps[key]);
}

function samplesShowBoundedTrend(result) {
  const runningSamples = result.resources.samples.filter((sample) => sample.label !== "after_exit");
  const labels = runningSamples.map((sample) => sample.label);
  const { caps } = result.resources;
  return JSON.stringify(labels) === JSON.stringify(["start", "mid", "end"])
    && runningSamples.every((sample) => (
      sample.activeRuntimeCount === 1
      && sample.activeObjects <= caps.activeObjects
      && sample.activeEntries <= caps.activeEntries
      && sample.activeContainers <= caps.activeContainers
      && sample.history <= caps.history
      && sample.listeners === caps.listeners
      && sample.timers <= caps.timers
      && sample.modeledResidentUnits <= caps.modeledResidentUnits
    ))
    && runningSamples[1].history === caps.history
    && runningSamples[2].history === caps.history;
}

function modeledMemoryTrendIsBounded(result) {
  const modeled = result.resources.modeledMemory;
  const runningSamples = result.resources.samples.filter((sample) => sample.label !== "after_exit");
  return modeled.model === MODELED_MEMORY_MODEL_ID
    && modeled.scope === "pure_rules_resource_counts_only"
    && modeled.unit === MODELED_MEMORY_UNIT
    && modeled.browserHeapMeasured === false
    && Number.isSafeInteger(modeled.start)
    && Number.isSafeInteger(modeled.mid)
    && Number.isSafeInteger(modeled.end)
    && Number.isSafeInteger(modeled.maximum)
    && Number.isSafeInteger(modeled.budget)
    && modeled.start === runningSamples[0]?.modeledResidentUnits
    && modeled.mid === runningSamples[1]?.modeledResidentUnits
    && modeled.end === runningSamples[2]?.modeledResidentUnits
    && modeled.maximum <= modeled.budget
    && modeled.end <= modeled.budget
    && modeled.bounded === true
    && modeled.trend !== "unbounded_growth";
}

function simulateFailureCleanup(mode, fleet, caps) {
  const probe = new RuntimeResourceProbe(fleet, mode, caps);
  probe.mount();
  probe.update({
    activeObjects: caps.activeObjects,
    activeEntries: caps.activeEntries,
    activeContainers: caps.activeContainers,
    history: caps.history,
    timers: caps.timers,
  });
  const beforeFailure = probe.sample("before_failure", 0);
  // The result/error UI intentionally keeps the Host mounted. Its fixed
  // visibility and blur listeners remain until retry, return or unmount.
  const afterFailure = probe.cleanup("after_failure", RETAINED_RESULT_LISTENER_COUNT);
  const afterRepeatedFailure = probe.cleanup("after_repeated_failure", RETAINED_RESULT_LISTENER_COUNT);
  return { beforeFailure, afterFailure, afterRepeatedFailure };
}

function formatSamples(samples) {
  return samples.map((sample) => (
    `${sample.label}@${sample.elapsedMs}ms`
      + `(runtime=${sample.activeRuntimeCount},objects=${sample.activeObjects},containers=${sample.activeContainers}`
      + `,entries=${sample.activeEntries},history=${sample.history}`
      + `,listeners=${sample.listeners},timers=${sample.timers}`
      + `,modeledResidentUnits=${sample.modeledResidentUnits})`
  )).join("; ");
}

function formatModeLine(report) {
  const result = report.primary;
  const summary = result.summary;
  const maximums = result.resources.maximums;
  const caps = result.resources.caps;
  const modeledMemory = result.resources.modeledMemory;
  const resourceLabels = {
    fishing: { objects: "noteVisuals", entries: "notes", containers: "segments" },
    spotlight: { objects: "sceneObjects", entries: "pathPoints", containers: "waves" },
    bike: { objects: "dynamicObjects", entries: "obstacles", containers: "waveSchedulers" },
  }[result.mode];
  return `- 30min ${result.mode}: seed=${result.seed} replay=${report.replayMatches ? "PASS" : "FAIL"}`
    + ` variant=${report.alternateDiffers ? "PASS" : "FAIL"} fingerprint=${result.fingerprint}`
    + ` summary(score=${summary.score},progress=${summary.progress},tier=${summary.tier}`
    + `,combo=${summary.combo},durationMs=${summary.durationMs})`
    + ` modelMax(${resourceLabels.objects}=${maximums.activeObjects}/${caps.activeObjects}`
    + `,${resourceLabels.entries}=${maximums.activeEntries}/${caps.activeEntries}`
    + `,${resourceLabels.containers}=${maximums.activeContainers}/${caps.activeContainers}`
    + `,history=${maximums.history}/${caps.history}`
    + `,listeners=${maximums.listeners}/${caps.listeners},timers=${maximums.timers}/${caps.timers})`
    + ` modeledMemory(model=${modeledMemory.model},scope=${modeledMemory.scope},unit=${modeledMemory.unit}`
    + `,start=${modeledMemory.start},mid=${modeledMemory.mid},end=${modeledMemory.end}`
    + `,max=${modeledMemory.maximum}/${modeledMemory.budget}`
    + `,midToEndDelta=${modeledMemory.midToEndDelta},trend=${modeledMemory.trend}`
    + `,browserHeapMeasured=${modeledMemory.browserHeapMeasured})`
    + ` modelSamples=[${formatSamples(result.resources.samples)}]`
    + ` modeledFailureCleanup(activeRuntime=${report.failureCleanup.afterFailure.activeRuntimeCount}`
    + `,objects=${report.failureCleanup.afterFailure.activeObjects}`
    + `,retainedHostListeners=${report.failureCleanup.afterFailure.listeners}`
    + `,timers=${report.failureCleanup.afterFailure.timers})`;
}

async function loadBundledModules(repositoryRoot) {
  const bundleDirectory = await mkdtemp(path.join(tmpdir(), "endless-arcade-long-run-"));
  try {
    const entries = [
      "fishingRules",
      "spotlightRules",
      "bikeRules",
      "limits",
      "runtime",
      "controller",
      "gameState",
      "saveStore",
    ];
    const outputPaths = Object.fromEntries(entries.map((key) => [key, path.join(bundleDirectory, `${key}.mjs`)]));
    await Promise.all(entries.map((key) => build({
      entryPoints: [path.join(repositoryRoot, SOURCE_PATHS[key])],
      outfile: outputPaths[key],
      bundle: true,
      format: "esm",
      platform: "node",
      target: "node20",
    })));
    const nonce = `${process.pid}-${Date.now()}`;
    const modules = await Promise.all(entries.map((key) => (
      import(`${pathToFileURL(outputPaths[key]).href}?v=${nonce}-${key}`)
    )));
    return {
      modules: Object.fromEntries(entries.map((key, index) => [key, modules[index]])),
      dispose: () => rm(bundleDirectory, { recursive: true, force: true }),
    };
  } catch (error) {
    await rm(bundleDirectory, { recursive: true, force: true });
    throw error;
  }
}

class MemoryStorage {
  #entries = new Map();

  get length() {
    return this.#entries.size;
  }

  clear() {
    this.#entries.clear();
  }

  getItem(key) {
    return this.#entries.has(key) ? this.#entries.get(key) : null;
  }

  key(index) {
    return [...this.#entries.keys()][index] ?? null;
  }

  removeItem(key) {
    this.#entries.delete(key);
  }

  setItem(key, value) {
    this.#entries.set(key, String(value));
  }
}

function createControllerHarness(controllerModule, gameStateModule) {
  const store = gameStateModule.createGameStore(gameStateModule.createInitialGameState());
  const events = [];
  const eventBus = {
    emit(eventName, payload) {
      events.push({ eventName, payload });
    },
  };
  return {
    store,
    events,
    controller: new controllerModule.EndlessArcadeController(store, eventBus, () => true),
  };
}

function validateControllerRuntime({
  controllerModule,
  gameStateModule,
  saveStoreModule,
  runtimeModule,
  limitsModule,
  modeReports,
}) {
  const checks = [];
  const check = (id, passed, message) => checks.push({ id, passed: Boolean(passed), message });
  const { controller, store, events } = createControllerHarness(controllerModule, gameStateModule);
  const scoreLimit = limitsModule.ENDLESS_ARCADE_SCORE_LIMIT;

  const firstTicket = controller.startAttempt("fishing");
  const validSummary = firstTicket ? {
    runId: firstTicket.runId,
    mode: firstTicket.mode,
    score: 12_345,
    progress: 321,
    tier: 13,
    combo: 99,
    durationMs: ENDLESS_ARCADE_LONG_RUN_DURATION_MS,
  } : null;
  const invalidSummaries = validSummary ? [
    { ...validSummary, score: Number.NaN },
    { ...validSummary, progress: Number.POSITIVE_INFINITY },
    { ...validSummary, tier: Number.MAX_SAFE_INTEGER + 1 },
    { ...validSummary, combo: -1 },
    { ...validSummary, durationMs: 1.5 },
    { ...validSummary, runId: "stale-run" },
    { ...validSummary, mode: "bike" },
  ] : [];
  const invalidRejected = firstTicket !== null
    && invalidSummaries.every((summary) => controller.settleAttempt(summary) === null)
    && controller.getActiveRun()?.runId === firstTicket.runId;
  check(
    "controller.invalid-summary-matrix",
    invalidRejected,
    "NaN, Infinity, unsafe, negative, fractional, stale-run and wrong-mode summaries must be rejected without clearing the live ticket"
  );

  const wrongCancel = controller.cancelAttempt("stale-run");
  const firstCancel = firstTicket ? controller.cancelAttempt(firstTicket.runId) : false;
  const repeatedCancel = firstTicket ? controller.cancelAttempt(firstTicket.runId) : true;
  check(
    "controller.cancel-once",
    wrongCancel === false
      && firstCancel === true
      && repeatedCancel === false
      && controller.getActiveRun() === null,
    "cancel must accept the current run once, reject stale/repeated cancellation, and leave zero active controller runs"
  );

  const secondTicket = controller.startAttempt("fishing");
  const secondSummary = secondTicket ? {
    runId: secondTicket.runId,
    mode: secondTicket.mode,
    score: scoreLimit,
    progress: 654,
    tier: 13,
    combo: 199,
    durationMs: ENDLESS_ARCADE_LONG_RUN_DURATION_MS,
  } : null;
  const settled = secondSummary ? controller.settleAttempt(secondSummary) : null;
  const stateAfterSettlement = JSON.stringify(store.getState().endlessArcade);
  const repeatedSettlement = secondSummary ? controller.settleAttempt(secondSummary) : undefined;
  const stateAfterRepeatedSettlement = JSON.stringify(store.getState().endlessArcade);
  const settledEvents = events.filter((entry) => entry.eventName === "endless_arcade_attempt_settled");
  check(
    "controller.settle-once-runtime",
    secondTicket !== null
      && settled?.attemptCount === 2
      && settled?.bestScore === scoreLimit
      && repeatedSettlement === null
      && controller.cancelAttempt(secondTicket.runId) === false
      && stateAfterSettlement === stateAfterRepeatedSettlement
      && settledEvents.length === 1
      && controller.getActiveRun() === null,
    "the canonical score ceiling must settle once; repeated settle/cancel must be ignored and leave zero active controller runs"
  );
  check(
    "controller.mode-record-isolation",
    store.getState().endlessArcade.records.spotlight.attemptCount === 0
      && store.getState().endlessArcade.records.bike.attemptCount === 0,
    "fishing settlement and cancellation must not mutate spotlight or bike records"
  );

  const overLimitHarness = createControllerHarness(controllerModule, gameStateModule);
  const overLimitTicket = overLimitHarness.controller.startAttempt("spotlight");
  const overLimitSettlement = overLimitTicket ? {
    runId: overLimitTicket.runId,
    mode: overLimitTicket.mode,
    score: scoreLimit + 1,
    progress: 1,
    tier: 1,
    combo: 1,
    durationMs: ENDLESS_ARCADE_LONG_RUN_DURATION_MS,
  } : null;
  check(
    "controller.score-limit-plus-one",
    overLimitSettlement !== null
      && overLimitHarness.controller.settleAttempt(overLimitSettlement) === null
      && overLimitHarness.controller.getActiveRun()?.runId === overLimitTicket.runId
      && overLimitHarness.controller.cancelAttempt(overLimitTicket.runId) === true
      && overLimitHarness.controller.getActiveRun() === null,
    "score ceiling + 1 must be rejected without consuming the ticket, then remain cancellable"
  );

  const normalizedExact = runtimeModule.normalizeEndlessRunSummary("spotlight", {
    score: scoreLimit,
    progress: 1,
    tier: 1,
    combo: 1,
    durationMs: 1,
  });
  const normalizedOver = runtimeModule.normalizeEndlessRunSummary("spotlight", {
    score: scoreLimit + 1,
    progress: 1,
    tier: 1,
    combo: 1,
    durationMs: 1,
  });
  check(
    "runtime.canonical-score-normalize",
    saveStoreModule.ENDLESS_RECORD_LIMITS.bestScore === scoreLimit
      && normalizedExact.score === scoreLimit
      && normalizedOver.score === scoreLimit,
    "runtime normalization and controller/save record validation must share the one canonical score ceiling"
  );

  const initial = gameStateModule.createInitialGameState();
  const exactState = structuredClone(initial);
  exactState.endlessArcade.records.fishing.bestScore = scoreLimit;
  const exactSave = new saveStoreModule.SaveStore(new MemoryStorage());
  const exactSaved = exactSave.save(exactState);
  const exactLoaded = exactSave.load(initial);
  const overState = structuredClone(initial);
  overState.endlessArcade.records.fishing.bestScore = scoreLimit + 1;
  const overSave = new saveStoreModule.SaveStore(new MemoryStorage());
  const overSaved = overSave.save(overState);
  const overLoaded = overSave.load(initial);
  check(
    "save.score-limit-boundary",
    exactSaved === true
      && exactLoaded?.endlessArcade.records.fishing.bestScore === scoreLimit
      && overSaved === true
      && overLoaded?.endlessArcade.records.fishing.bestScore === 0,
    "SaveStore must preserve the canonical score ceiling and sanitize ceiling + 1 to the safe initial record"
  );

  const longRunHarness = createControllerHarness(controllerModule, gameStateModule);
  const longRunSettlements = modeReports.map((report) => {
    const ticket = longRunHarness.controller.startAttempt(report.mode);
    if (!ticket) return null;
    return longRunHarness.controller.settleAttempt({
      runId: ticket.runId,
      mode: ticket.mode,
      ...report.primary.summary,
    });
  });
  check(
    "controller.three-mode-30min-settlement",
    longRunSettlements.every((record, index) => (
      record !== null
      && record.bestScore === modeReports[index].primary.summary.score
      && record.bestProgress === modeReports[index].primary.summary.progress
      && record.bestTier === modeReports[index].primary.summary.tier
      && record.bestCombo === modeReports[index].primary.summary.combo
      && record.bestDurationMs === ENDLESS_ARCADE_LONG_RUN_DURATION_MS
    ))
      && longRunHarness.controller.getActiveRun() === null,
    "the actual fishing, spotlight and bike 30-minute summaries must each settle successfully and leave no active ticket"
  );
  return checks;
}

function validateInstanceLifecycleRuntime(runtimeModule) {
  const checks = [];
  const check = (id, passed, message) => checks.push({ id, passed: Boolean(passed), message });
  const outcomes = [];

  for (const mode of ["fishing", "spotlight", "bike"]) {
    for (const reason of ["failure", "exit", "error", "unmount"]) {
      const slot = { current: null };
      const calls = [];
      const runtime = {
        destroy(removeCanvas) {
          calls.push(removeCanvas);
        },
      };
      runtimeModule.mountEndlessArcadeRuntime(slot, runtime);
      const activeBefore = runtimeModule.countActiveEndlessArcadeRuntimes(slot);
      const destroyed = runtimeModule.destroyEndlessArcadeRuntime(slot);
      const activeAfter = runtimeModule.countActiveEndlessArcadeRuntimes(slot);
      const repeated = runtimeModule.destroyEndlessArcadeRuntime(slot);
      outcomes.push({ mode, reason, activeBefore, destroyed, activeAfter, repeated, calls });
    }
  }
  check(
    "runtime.instance-terminal-paths",
    outcomes.every((outcome) => (
      outcome.activeBefore === 1
      && outcome.destroyed === true
      && outcome.activeAfter === 0
      && outcome.repeated === false
      && JSON.stringify(outcome.calls) === JSON.stringify([true])
    )),
    "actual lifecycle helper must reduce failure, exit, error and unmount to zero instances for all modes and make repeated destroy a no-op"
  );

  const replacementSlot = { current: null };
  let firstDestroyCount = 0;
  let secondDestroyCount = 0;
  runtimeModule.mountEndlessArcadeRuntime(replacementSlot, {
    destroy() {
      firstDestroyCount += 1;
    },
  });
  runtimeModule.mountEndlessArcadeRuntime(replacementSlot, {
    destroy() {
      secondDestroyCount += 1;
    },
  });
  const activeAfterReplacement = runtimeModule.countActiveEndlessArcadeRuntimes(replacementSlot);
  runtimeModule.destroyEndlessArcadeRuntime(replacementSlot);
  check(
    "runtime.instance-replacement",
    firstDestroyCount === 1
      && activeAfterReplacement === 1
      && secondDestroyCount === 1
      && runtimeModule.countActiveEndlessArcadeRuntimes(replacementSlot) === 0,
    "mounting a replacement must destroy the stale instance first and retain at most one active runtime"
  );

  const resultSlot = { current: null };
  const independentSummary = runtimeModule.normalizeEndlessRunSummary("spotlight", {
    score: 123,
    progress: 4,
    tier: 2,
    combo: 3,
    durationMs: 5_000,
    status: "complete",
  });
  runtimeModule.mountEndlessArcadeRuntime(resultSlot, { destroy() {} });
  runtimeModule.destroyEndlessArcadeRuntime(resultSlot);
  check(
    "runtime.summary-survives-destroy",
    runtimeModule.countActiveEndlessArcadeRuntimes(resultSlot) === 0
      && independentSummary.mode === "spotlight"
      && independentSummary.score === 123
      && independentSummary.status === "complete",
    "normalized result data must remain independently renderable after its Phaser instance is destroyed"
  );
  return checks;
}

async function validateCleanupSourceContracts(repositoryRoot) {
  const entries = ["fishingScene", "spotlightScene", "bikeScene", "host"];
  const sources = Object.fromEntries(await Promise.all(entries.map(async (key) => [
    key,
    await readFile(path.join(repositoryRoot, SOURCE_PATHS[key]), "utf8"),
  ])));
  const finishStart = sources.host.indexOf("const finish =");
  const finishEnd = sources.host.indexOf("const sceneBridge", finishStart);
  const finishBlock = finishStart >= 0 && finishEnd > finishStart
    ? sources.host.slice(finishStart, finishEnd)
    : "";
  const timeoutStart = sources.host.indexOf("const bootTimer =");
  const timeoutEnd = sources.host.indexOf("const handleVisibilityChange", timeoutStart);
  const timeoutBlock = timeoutStart >= 0 && timeoutEnd > timeoutStart
    ? sources.host.slice(timeoutStart, timeoutEnd)
    : "";
  const catchStart = sources.host.indexOf("}).catch((error: unknown)");
  const cleanupEnd = sources.host.indexOf("}, [mode, run.runId", catchStart);
  const catchAndCleanupBlock = catchStart >= 0 && cleanupEnd > catchStart
    ? sources.host.slice(catchStart, cleanupEnd)
    : "";
  return [
    {
      id: "cleanup-source.fishing",
      passed: [
        "Phaser.Scenes.Events.SHUTDOWN",
        "Phaser.Scenes.Events.DESTROY",
        "if (this.cleanupComplete) return",
        "cleanupEndlessScene()",
        'off("keydown", this.keyboardDown)',
        'off("keyup", this.keyboardUp)',
        "this.clearNotes()",
        "this.model?.cancel()",
        "this.model = null",
      ].every((value) => sources.fishingScene.includes(value)),
      message: "fishing shutdown must detach both keyboard listeners, destroy note objects and cancel the rhythm model",
    },
    {
      id: "cleanup-source.spotlight",
      passed: [
        "Phaser.Scenes.Events.SHUTDOWN",
        "Phaser.Scenes.Events.DESTROY",
        "if (this.cleanupComplete) return",
        "cleanupEndlessScene()",
        'off("keydown", this.keyboardDown)',
        'off("keyup", this.keyboardUp)',
        "this.previousRenderEndlessSpotlightToText",
        "window.render_endless_spotlight_to_text = this.previousRenderEndlessSpotlightToText",
        "delete window.render_endless_spotlight_to_text",
        "delete window.advanceTime",
      ].every((value) => sources.spotlightScene.includes(value)),
      message: "spotlight shutdown must detach keyboard listeners and restore/remove its dedicated inspection hook plus advanceTime",
    },
    {
      id: "cleanup-source.bike",
      passed: [
        "Phaser.Scenes.Events.SHUTDOWN",
        "Phaser.Scenes.Events.DESTROY",
        'removeEventListener("visibilitychange"',
        'removeEventListener("blur"',
        'removeEventListener("focus"',
        'this.input.off("pointerdown"',
        "this.invulnerabilityTimer?.remove(false)",
        "this.time.removeAllEvents()",
        "this.obstacles?.clear(true, true)",
        "this.impactShards.clear()",
        "this.waveHistory = []",
      ].every((value) => sources.bikeScene.includes(value)),
      message: "bike shutdown/destroy must detach input and lifecycle listeners and clear timers, pools, particles and history",
    },
    {
      id: "cleanup-source.host",
      passed: sources.host.includes("destroyEndlessArcadeRuntime(gameRef)")
        && sources.host.includes("mountEndlessArcadeRuntime(gameRef, game)")
        && sources.host.includes("cleanupEndlessArcadeScene(sceneRef.current)")
        && sources.host.includes('statusKindRef.current === "game_over"')
        && sources.host.includes('statusKindRef.current === "error"')
        && finishBlock.includes('publishStatus({ kind: "game_over", summary })')
        && finishBlock.includes("game.scene.stop(sceneKey)")
        && finishBlock.indexOf('publishStatus({ kind: "game_over", summary })')
          < finishBlock.indexOf("destroyActiveGame()")
        && timeoutBlock.includes("destroyActiveGame()")
        && catchAndCleanupBlock.includes("destroyActiveGame()")
        && catchAndCleanupBlock.includes("window.clearTimeout(bootTimer)")
        && catchAndCleanupBlock.includes('document.removeEventListener("visibilitychange"')
        && catchAndCleanupBlock.includes('window.removeEventListener("blur"'),
      message: "Host must wire the executable instance helper into mount, failure, timeout, error and unmount after publishing an independent result summary",
    },
  ];
}

export async function runEndlessArcadeLongRunValidation({ repositoryRoot }) {
  const startedAt = performance.now();
  const fleet = new ActiveRuntimeFleet();
  const checks = [];
  const check = (id, passed, message) => checks.push({ id, passed: Boolean(passed), message });
  const bundle = await loadBundledModules(repositoryRoot);
  try {
    const {
      fishingRules,
      spotlightRules,
      bikeRules,
      limits,
      runtime,
      controller,
      gameState,
      saveStore,
    } = bundle.modules;
    const simulations = [
      ["fishing", fishingRules, simulateFishing],
      ["spotlight", spotlightRules, simulateSpotlight],
      ["bike", bikeRules, simulateBike],
    ];
    const modeReports = [];

    for (const [mode, rules, simulate] of simulations) {
      const primary = simulate(rules, PRIMARY_SEED, fleet);
      const replay = simulate(rules, PRIMARY_SEED, fleet);
      const alternate = simulate(rules, ALTERNATE_SEED, fleet);
      const replayMatches = JSON.stringify(deterministicProjection(primary))
        === JSON.stringify(deterministicProjection(replay));
      const alternateDiffers = primary.fingerprint !== alternate.fingerprint;
      const failureCleanup = simulateFailureCleanup(mode, fleet, primary.resources.caps);
      const report = { mode, primary, replay, alternate, replayMatches, alternateDiffers, failureCleanup };
      modeReports.push(report);

      check(
        `${mode}.duration-30min`,
        [primary, replay, alternate].every((result) => result.summary.durationMs === ENDLESS_ARCADE_LONG_RUN_DURATION_MS),
        `${mode} must execute three virtual 30-minute runs without wall-clock waiting`
      );
      check(
        `${mode}.seed-replay`,
        replayMatches,
        `${mode} must reproduce the full summary, fingerprint, resources and samples for the same seed`
      );
      check(
        `${mode}.seed-variation`,
        alternateDiffers,
        `${mode} must produce a different generated-content fingerprint for a different seed`
      );
      check(
        `${mode}.safe-summary`,
        [primary, replay, alternate].every((result) => isSafeSummary(result.summary)),
        `${mode} score, progress, tier, combo and duration must remain non-negative finite safe integers`
      );
      check(
        `${mode}.resource-bounds`,
        [primary, replay, alternate].every(resourcesAreBounded),
        `${mode} active objects/entries/containers, history, listeners and timers must remain within exported or authored caps`
      );
      check(
        `${mode}.resource-trend`,
        [primary, replay, alternate].every(samplesShowBoundedTrend),
        `${mode} start/mid/end samples must keep listeners stable and history plateaued at its finite cap`
      );
      check(
        `${mode}.modeled-memory-trend`,
        [primary, replay, alternate].every(modeledMemoryTrendIsBounded),
        `${mode} pure-rules modeled resident units must report deterministic start/mid/end/max/budget fields and no unbounded mid-to-end trend`
      );
      check(
        `${mode}.resource-model-exit-zero`,
        primary.resources.samples.at(-1)?.activeRuntimeCount === 0
          && primary.resources.afterRepeatedExit.activeRuntimeCount === 0
          && primary.resources.samples.at(-1)?.activeObjects === 0
          && primary.resources.samples.at(-1)?.listeners === 0
          && primary.resources.samples.at(-1)?.timers === 0,
        `${mode} offline resource-probe exit and repeated-exit transitions must leave zero active runtimes and resources`
      );
      check(
        `${mode}.resource-model-failure-zero`,
        failureCleanup.beforeFailure.activeRuntimeCount === 1
          && failureCleanup.afterFailure.activeRuntimeCount === 0
          && failureCleanup.afterRepeatedFailure.activeRuntimeCount === 0
          && failureCleanup.afterFailure.activeObjects === 0
          && failureCleanup.afterFailure.listeners === RETAINED_RESULT_LISTENER_COUNT
          && failureCleanup.afterRepeatedFailure.listeners === RETAINED_RESULT_LISTENER_COUNT
          && failureCleanup.afterFailure.timers === 0,
        `${mode} offline resource model must leave zero active runtimes and scene resources while retaining only the fixed P16 and result-Host listeners`
      );
    }

    check(
      "score-limit.rule-alignment",
      fishingRules.MAX_ENDLESS_FISHING_SCORE === limits.ENDLESS_ARCADE_SCORE_LIMIT
        && spotlightRules.MAX_ENDLESS_SPOTLIGHT_SCORE === limits.ENDLESS_ARCADE_SCORE_LIMIT
        && bikeRules.BIKE_ARCADE_MAX_SCORE === limits.ENDLESS_ARCADE_SCORE_LIMIT,
      "fishing, spotlight and bike generators must share the canonical score ceiling"
    );
    check(
      "bike.generated-waves-solvable",
      (() => {
        const bikeReport = modeReports.find((report) => report.mode === "bike");
        return bikeReport !== undefined
          && [bikeReport.primary, bikeReport.replay, bikeReport.alternate]
            .every((run) => run.details.unsolvableWaves === 0);
      })(),
      "every generated bike wave in all three virtual 30-minute runs must satisfy the exported solvability contract"
    );
    checks.push(...validateControllerRuntime({
      controllerModule: controller,
      gameStateModule: gameState,
      saveStoreModule: saveStore,
      runtimeModule: runtime,
      limitsModule: limits,
      modeReports,
    }));
    checks.push(...validateInstanceLifecycleRuntime(runtime));
    checks.push(...await validateCleanupSourceContracts(repositoryRoot));
    check(
      "lifecycle.fleet-empty",
      fleet.activeRuntimeCount === 0,
      "all nine long runs plus three failure probes must leave the shared active-runtime fleet empty"
    );

    const wallDurationMs = Math.round(performance.now() - startedAt);
    return Object.freeze({
      checks: Object.freeze(checks),
      modeReports: Object.freeze(modeReports),
      wallDurationMs,
      outputLines: Object.freeze([
        `Endless arcade 30min offline simulations virtualMs=${ENDLESS_ARCADE_LONG_RUN_DURATION_MS}`
          + ` runsPerMode=3 seeds=${PRIMARY_SEED},${PRIMARY_SEED},${ALTERNATE_SEED}`
          + ` wallMs=${wallDurationMs} resourceModel=pure-rules lifecycleHelperCases=12`
          + ` modeledMemory=${MODELED_MEMORY_MODEL_ID} browserHeapMeasured=false`
          + ` controllerSettlementModes=3 networkRequests=0 newDependencies=0`,
        ...modeReports.map(formatModeLine),
      ]),
    });
  } finally {
    await bundle.dispose();
  }
}
