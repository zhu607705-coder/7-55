import type { EventBus } from "../core/EventBus";
import type { GameStore } from "../core/types";

export type PlantStep = "water" | "light" | "fertilize";
export type PlantActionResult = "done" | "already" | "missing_requirement";

/**
 * 盆栽三个平行步骤：
 * - 浇水：把[盛水的耳机]（水滴+耳机合成）拖到盆栽上
 * - 照光：控制中心亮度拉高（>= 80）后自动照到
 * - 施肥：把[一袋肥料]拖到盆栽上
 * 三项完成 → 开花。
 */
export class PlantController {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  canWater(): boolean {
    return this.store.getState().items.wateredHeadphone;
  }

  canLight(): boolean {
    return this.store.getState().ui.brightness >= 80;
  }

  canFertilize(): boolean {
    return this.store.getState().items.fertilizer;
  }

  apply(step: PlantStep): PlantActionResult {
    const { flags } = this.store.getState();

    if (step === "water") {
      if (flags.plantWatered) return "already";
      if (!this.canWater()) return "missing_requirement";
      this.setFlagAndCheck("plantWatered");
      return "done";
    }

    if (step === "light") {
      if (flags.plantLit) return "already";
      if (!this.canLight()) return "missing_requirement";
      this.setFlagAndCheck("plantLit");
      return "done";
    }

    if (flags.plantFertilized) return "already";
    if (!this.canFertilize()) return "missing_requirement";
    this.setFlagAndCheck("plantFertilized");
    return "done";
  }

  /** 已完成的步骤数（0-3），用于植株长高档位 */
  growthStage(): number {
    const { flags } = this.store.getState();
    return [flags.plantWatered, flags.plantLit, flags.plantFertilized].filter(Boolean).length;
  }

  isBloomed(): boolean {
    return this.store.getState().flags.flowerBloomed;
  }

  private setFlagAndCheck(flag: "plantWatered" | "plantLit" | "plantFertilized"): void {
    this.store.setState((s) => ({
      ...s,
      flags: { ...s.flags, [flag]: true }
    }));
    this.events.emit("plant_step", { step: flag });

    const { plantWatered, plantLit, plantFertilized } = this.store.getState().flags;
    if (plantWatered && plantLit && plantFertilized) {
      this.store.setState((s) => ({
        ...s,
        flags: { ...s.flags, flowerBloomed: true }
      }));
      this.events.emit("flower_bloomed");
    }
  }
}
