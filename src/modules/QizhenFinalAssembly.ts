import type { GameState, ItemId } from "../core/types";

export const QIZHEN_FINAL_RIG_PARTS = Object.freeze([
  "nylonCord", "brokenNetFrame", "swanMagnet", "fishingRod"
] as const satisfies readonly ItemId[]);

type AssemblyState = Pick<GameState, "items" | "qizhenLake">;

/** The old net already consumed cord/frame. This receipt is never an item grant. */
export function hasQizhenLegacyNetMaterials(state: AssemblyState): boolean {
  const lake = state.qizhenLake;
  return lake.legacyNetMaterialsConsumed === true
    && lake.netCombined && lake.lockerOpened && lake.feedTinRetrieved
    && !lake.magneticRodCombined;
}

export function hasQizhenFinalAssemblyMaterials(state: AssemblyState): boolean {
  const legacy = hasQizhenLegacyNetMaterials(state);
  return QIZHEN_FINAL_RIG_PARTS.every((id) => state.items[id]
    || (legacy && (id === "nylonCord" || id === "brokenNetFrame")));
}
