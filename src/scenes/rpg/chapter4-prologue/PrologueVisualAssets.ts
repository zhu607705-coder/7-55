import arcadeAUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/arcade_a.png";
import arcadeBUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/arcade_b.png";
import entranceAUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/entrance_a.png";
import entranceBUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/entrance_b.png";
import lakeExitAUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/lake_exit_a.png";
import lakeExitBUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/lake_exit_b.png";
import lobbyAUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/lobby_a.png";
import lobbyBUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/lobby_b.png";
import closingAUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/closing_a.png";
import closingBUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/closing_b.png";
import snapAUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/snap_a.png";
import snapBUrl from "../../../assets/rpg/cinematics/chapter4-prologue/pixel/snap_b.png";
import paperFlight0Url from "../../../assets/rpg/theater/generated/paper/paper_flight_0.png";
import paperFlight1Url from "../../../assets/rpg/theater/generated/paper/paper_flight_1.png";
import paperFlight2Url from "../../../assets/rpg/theater/generated/paper/paper_flight_2.png";
import paperFlight3Url from "../../../assets/rpg/theater/generated/paper/paper_flight_3.png";
import paperFlight4Url from "../../../assets/rpg/theater/generated/paper/paper_flight_4.png";
import type { ProloguePhaseId } from "./PrologueTimeline";

type PrologueFramePair = readonly [string, string];
const MAX_CACHED_IMAGES = 6;

const FRAME_URLS: Readonly<Record<ProloguePhaseId, PrologueFramePair>> = {
  snap: [snapAUrl, snapBUrl],
  lake_exit: [lakeExitAUrl, lakeExitBUrl],
  arcade: [arcadeAUrl, arcadeBUrl],
  entrance: [entranceAUrl, entranceBUrl],
  lobby: [lobbyAUrl, lobbyBUrl],
  closing: [closingAUrl, closingBUrl]
};

const PAPER_FLIGHT_URLS = [
  paperFlight0Url,
  paperFlight1Url,
  paperFlight2Url,
  paperFlight3Url,
  paperFlight4Url
] as const;

/**
 * 第四章序幕场景图的加载边界。图片只负责环境画面，纸条、人物、门和灯光仍由运行时绘制。
 */
export class PrologueVisualAssets {
  private readonly frames = new Map<string, HTMLImageElement>();

  getFrame(phase: ProloguePhaseId, alternate: boolean): HTMLImageElement | null {
    const url = FRAME_URLS[phase][alternate ? 1 : 0];
    const image = this.getOrRegister(url);
    if (!image || !image.complete || image.naturalWidth === 0) return null;
    return image;
  }

  getImage(url: string): HTMLImageElement | null {
    const image = this.getOrRegister(url);
    if (!image || !image.complete || image.naturalWidth === 0) return null;
    return image;
  }

  getPaperFrame(frame: number): HTMLImageElement | null {
    const url = PAPER_FLIGHT_URLS[Math.abs(frame) % PAPER_FLIGHT_URLS.length];
    return this.getImage(url);
  }

  private getOrRegister(url: string): HTMLImageElement {
    const cached = this.frames.get(url);
    if (cached) {
      this.frames.delete(url);
      this.frames.set(url, cached);
      return cached;
    }
    while (this.frames.size >= MAX_CACHED_IMAGES) {
      const oldestUrl = this.frames.keys().next().value as string | undefined;
      if (!oldestUrl) break;
      this.frames.delete(oldestUrl);
    }
    const image = new Image();
    image.decoding = "async";
    image.src = url;
    this.frames.set(url, image);
    return image;
  }
}
