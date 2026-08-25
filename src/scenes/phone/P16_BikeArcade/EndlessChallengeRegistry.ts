import type {
  EndlessChallengeModeId,
  EndlessChallengeRecord
} from "../../../core/types";
import content from "../../../data/endless-arcade.content.json";
import {
  EndlessArcadeRuntimeError,
  type EndlessArcadeSceneConstructor,
  type EndlessArcadeSceneModule
} from "./EndlessArcadeRuntime";

interface EndlessSceneExports {
  EndlessFishingScene?: EndlessArcadeSceneConstructor;
  EndlessSpotlightScene?: EndlessArcadeSceneConstructor;
  BikeRushScene?: EndlessArcadeSceneConstructor;
}

export interface EndlessChallengeDefinition {
  id: EndlessChallengeModeId;
  title: string;
  shortRule: string;
  input: string;
  progressUnit: string;
  accent: "aqua" | "amber" | "green";
  loadScene: () => Promise<EndlessArcadeSceneModule>;
  formatRecord: (record: EndlessChallengeRecord) => string;
}

const sceneModuleLoaders = import.meta.glob<EndlessSceneExports>("./*Scene.ts");

const sceneContracts: Record<EndlessChallengeModeId, {
  path: string;
  exportName: keyof EndlessSceneExports;
  sceneKey: string;
}> = {
  fishing: {
    path: "./EndlessFishingScene.ts",
    exportName: "EndlessFishingScene",
    sceneKey: "endless-fishing"
  },
  spotlight: {
    path: "./EndlessSpotlightScene.ts",
    exportName: "EndlessSpotlightScene",
    sceneKey: "endless-spotlight"
  },
  bike: {
    path: "./BikeRushScene.ts",
    exportName: "BikeRushScene",
    sceneKey: "bike-rush"
  }
};

async function loadRegisteredScene(mode: EndlessChallengeModeId): Promise<EndlessArcadeSceneModule> {
  const contract = sceneContracts[mode];
  const loadModule = sceneModuleLoaders[contract.path];
  if (!loadModule) {
    throw new EndlessArcadeRuntimeError(
      "runtime_unavailable",
      mode,
      `Runtime module unavailable for ${mode}`
    );
  }
  const module = await loadModule();
  const Scene = module[contract.exportName];
  if (typeof Scene !== "function") {
    throw new EndlessArcadeRuntimeError(
      "invalid_scene_module",
      mode,
      `Runtime module for ${mode} does not export ${contract.exportName}`
    );
  }
  return { Scene, sceneKey: contract.sceneKey };
}

function formatRecord(mode: EndlessChallengeModeId, record: EndlessChallengeRecord): string {
  if (record.attemptCount === 0) return "尚无记录";
  if (mode === "fishing") {
    return `${record.bestProgress} 次收线 · ${record.bestScore.toLocaleString("zh-CN")} 分`;
  }
  if (mode === "spotlight") {
    return `${record.bestProgress} 轮 · ${record.bestScore.toLocaleString("zh-CN")} 分`;
  }
  return `${record.bestProgress.toLocaleString("zh-CN")} 米 · ${record.bestScore.toLocaleString("zh-CN")} 分`;
}

const modes = content.modes;

export const ENDLESS_CHALLENGE_REGISTRY: Readonly<Record<EndlessChallengeModeId, EndlessChallengeDefinition>> = Object.freeze({
  fishing: Object.freeze({
    id: "fishing",
    ...modes.fishing,
    accent: modes.fishing.accent as "aqua",
    loadScene: () => loadRegisteredScene("fishing"),
    formatRecord: (record: EndlessChallengeRecord) => formatRecord("fishing", record)
  }),
  spotlight: Object.freeze({
    id: "spotlight",
    ...modes.spotlight,
    accent: modes.spotlight.accent as "amber",
    loadScene: () => loadRegisteredScene("spotlight"),
    formatRecord: (record: EndlessChallengeRecord) => formatRecord("spotlight", record)
  }),
  bike: Object.freeze({
    id: "bike",
    ...modes.bike,
    accent: modes.bike.accent as "green",
    loadScene: () => loadRegisteredScene("bike"),
    formatRecord: (record: EndlessChallengeRecord) => formatRecord("bike", record)
  })
});

export const ENDLESS_CHALLENGE_MODE_IDS = Object.freeze([
  "fishing",
  "spotlight",
  "bike"
] satisfies EndlessChallengeModeId[]);

export function getEndlessChallengeDefinition(mode: EndlessChallengeModeId): EndlessChallengeDefinition {
  return ENDLESS_CHALLENGE_REGISTRY[mode];
}
