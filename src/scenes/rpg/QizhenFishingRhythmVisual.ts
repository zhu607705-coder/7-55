import { LakeFishingRitualVisual, type LakeFishingRitualOptions } from "./LakeFishingRitualVisual";
import type { QizhenFishingChartId } from "./QizhenFishingRhythmModel";

/** Story adapter only. All drawing, cues and pointer behavior are shared with endless fishing. */
export type QizhenFishingRhythmVisualOptions = Omit<LakeFishingRitualOptions<QizhenFishingChartId>, "width" | "height">;
export class QizhenFishingRhythmVisual extends LakeFishingRitualVisual<QizhenFishingChartId> {
  constructor(options: QizhenFishingRhythmVisualOptions) { super({ ...options, width: 960, height: 540 }); }
}
