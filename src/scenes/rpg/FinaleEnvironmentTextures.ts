import type Phaser from "phaser";
import manifest from "../../assets/rpg/interiors/finale/finale_environment_manifest.json";

import arrivalArcadeUrl from "../../assets/rpg/interiors/finale/finale_arrival_arcade.png";
import firstFloorLobbyUrl from "../../assets/rpg/interiors/finale/finale_1f_lobby_maxwell.png";
import stairwellUrl from "../../assets/rpg/interiors/finale/finale_stairwell.png";
import verticalCoreUrl from "../../assets/rpg/interiors/finale/finale_vertical_core.png";
import secondFloorActivityUrl from "../../assets/rpg/interiors/finale/finale_2f_activity.png";
import finalClassroomUrl from "../../assets/rpg/interiors/finale/finale_final_classroom.png";
import teachingBuildingFloor1Url from "../../assets/rpg/interiors/finale/teaching_building_floor_1.png";
import teachingBuildingFloor2Url from "../../assets/rpg/interiors/finale/teaching_building_floor_2.png";
import teachingBuildingFloor3Url from "../../assets/rpg/interiors/finale/teaching_building_floor_3.png";
import chapter4A1BaseUrl from "../../assets/rpg/interiors/finale/chapter4-755/base/a1.png";
import chapter4A2BaseUrl from "../../assets/rpg/interiors/finale/chapter4-755/base/a2.png";
import chapter4A3BaseUrl from "../../assets/rpg/interiors/finale/chapter4-755/base/a3.png";
import chapter4A1OpeningUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a1_2245_opening.png";
import chapter4A1BakeryUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a1_1225_bakery.png";
import chapter4A2EveningUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a2_1850_evening.png";
import chapter4A3ReferenceUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a3_1850_reference.png";
import chapter4A1MaintenanceUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a1_2245_maintenance.png";
import chapter4A1BlackoutUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a1_0754_blackout.png";
import chapter4A2ChaseUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a2_0754_chase.png";
import chapter4A2202FinalMinuteUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a2_202_final_minute.png";
import chapter4A1MorningUrl from "../../assets/rpg/interiors/finale/chapter4-755/states/a1_0755_morning.png";
import chapter4ClockStatesUrl from "../../assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_clock_states_v01.png";
import chapter4PowerPanelStatesUrl from "../../assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_power_panel_states_v01.png";
import chapter4StoryItemsUrl from "../../assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_story_items_v01.png";
import chapter4Room204FurnitureUrl from "../../assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_a2_room204_furniture_v02.png";
import chapter4Room204ResidualUrl from "../../assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_a2_room204_dark_residual_v02.png";
import { preloadRpgImage } from "./RpgAssetLoader";

export type FinaleEnvironmentId = typeof manifest.scenes[number]["id"];

export interface FinaleEnvironmentAsset {
  id: FinaleEnvironmentId;
  title: string;
  url: string;
  projection: string;
  temporalCellId: string | null;
  purpose: string;
  dynamicLayers: readonly string[];
  sourceSize: { width: number; height: number };
  logicalViewport: { width: number; height: number };
  baseLayerOnly: boolean;
  sha256: string;
}

type ChapterFour755BasePlateEntry = typeof manifest.basePlates[number];
type ChapterFour755StatePlateEntry = typeof manifest.statePlates[number];
type ChapterFour755SpritesheetEntry = typeof manifest.spritesheets[number];
export type ChapterFour755PlateId = ChapterFour755BasePlateEntry["id"] | ChapterFour755StatePlateEntry["id"];
const CHAPTER_FOUR_755_SPRITESHEET_IDS = [
  "chapter4_clock_states",
  "chapter4_power_panel_states",
  "chapter4_story_items",
  "chapter4_room204_furniture",
  "chapter4_room204_residual"
] as const;
export type ChapterFour755SpritesheetId = typeof CHAPTER_FOUR_755_SPRITESHEET_IDS[number];

export interface ChapterFour755PlateAsset extends Omit<
  ChapterFour755BasePlateEntry | ChapterFour755StatePlateEntry,
  "file"
> {
  url: string;
}

export interface ChapterFour755SpritesheetAsset extends Omit<ChapterFour755SpritesheetEntry, "file"> {
  url: string;
}

export interface ChapterFour755ManifestRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ChapterFour755ManifestPivot {
  x: number;
  y: number;
  coordinateSpace: "source_sheet";
}

export interface ChapterFour755ManifestFrame {
  id: string;
  sourceCell: ChapterFour755ManifestRect | null;
  sourceRect: ChapterFour755ManifestRect;
  sourceTrim: ChapterFour755ManifestRect | null;
  pivot: ChapterFour755ManifestPivot | null;
  collisionBounds?: readonly {
    id: string;
    coordinateSpace: "source_sheet";
    bounds: ChapterFour755ManifestRect;
  }[];
  interactionBounds?: readonly {
    id: string;
    coordinateSpace: "source_sheet";
    bounds: ChapterFour755ManifestRect;
  }[];
}

export interface ChapterFour755FrameRegistrationReport {
  manifestFrameCount: number;
  registeredFrameCount: number;
  reusedFrameCount: number;
  skippedEmptyFrameCount: number;
  frameKeys: readonly string[];
  contractFailures: readonly string[];
}

const urls: Record<FinaleEnvironmentId, string> = {
  finale_arrival_arcade: arrivalArcadeUrl,
  finale_1f_lobby_maxwell: firstFloorLobbyUrl,
  finale_stairwell: stairwellUrl,
  finale_vertical_core: verticalCoreUrl,
  finale_2f_activity: secondFloorActivityUrl,
  finale_final_classroom: finalClassroomUrl,
  teaching_building_floor_1: teachingBuildingFloor1Url,
  teaching_building_floor_2: teachingBuildingFloor2Url,
  teaching_building_floor_3: teachingBuildingFloor3Url
};

const chapterFour755PlateUrls: Record<ChapterFour755PlateId, string> = {
  a1_base: chapter4A1BaseUrl,
  a2_base: chapter4A2BaseUrl,
  a3_base: chapter4A3BaseUrl,
  a1_2245_opening: chapter4A1OpeningUrl,
  a1_1225_bakery: chapter4A1BakeryUrl,
  a2_1850_evening: chapter4A2EveningUrl,
  a3_1850_reference: chapter4A3ReferenceUrl,
  a1_2245_maintenance: chapter4A1MaintenanceUrl,
  a1_0754_blackout: chapter4A1BlackoutUrl,
  a2_0754_chase: chapter4A2ChaseUrl,
  a2_202_final_minute: chapter4A2202FinalMinuteUrl,
  a1_0755_morning: chapter4A1MorningUrl
};

const chapterFour755SpritesheetUrls: Record<ChapterFour755SpritesheetId, string> = {
  chapter4_clock_states: chapter4ClockStatesUrl,
  chapter4_power_panel_states: chapter4PowerPanelStatesUrl,
  chapter4_story_items: chapter4StoryItemsUrl,
  chapter4_room204_furniture: chapter4Room204FurnitureUrl,
  chapter4_room204_residual: chapter4Room204ResidualUrl
};

export const FINALE_ENVIRONMENTS = Object.freeze(
  Object.fromEntries(
    manifest.scenes.map((entry) => [
      entry.id,
      {
        ...entry,
        url: resolveFinaleEnvironmentUrl(entry.id)
      }
    ])
  ) as Record<FinaleEnvironmentId, FinaleEnvironmentAsset>
);

function resolveFinaleEnvironmentUrl(id: FinaleEnvironmentId): string {
  const url = urls[id];
  if (typeof url !== "string" || url.length === 0) {
    throw new Error(`Missing legacy finale environment URL: ${id}`);
  }
  return url;
}

export const CHAPTER_FOUR_755_PLATES = Object.freeze(
  Object.fromEntries(
    [...manifest.basePlates, ...manifest.statePlates].map((entry) => [
      entry.id,
      {
        ...entry,
        url: chapterFour755PlateUrls[entry.id as ChapterFour755PlateId]
      }
    ])
  ) as Record<ChapterFour755PlateId, ChapterFour755PlateAsset>
);

export const CHAPTER_FOUR_755_SPRITESHEETS = Object.freeze(
  {
    chapter4_clock_states: resolveChapterFour755Spritesheet("chapter4_clock_states"),
    chapter4_power_panel_states: resolveChapterFour755Spritesheet("chapter4_power_panel_states"),
    chapter4_story_items: resolveChapterFour755Spritesheet("chapter4_story_items"),
    chapter4_room204_furniture: resolveChapterFour755Spritesheet("chapter4_room204_furniture"),
    chapter4_room204_residual: resolveChapterFour755Spritesheet("chapter4_room204_residual")
  } satisfies Record<ChapterFour755SpritesheetId, ChapterFour755SpritesheetAsset>
);

function resolveChapterFour755Spritesheet(
  id: ChapterFour755SpritesheetId
): ChapterFour755SpritesheetAsset {
  const entry = manifest.spritesheets.find((candidate) => (
    candidate.id === id && candidate.activeChapter4Contract === true
  ));
  if (!entry) throw new Error(`Missing active Chapter 4 spritesheet: ${id}`);
  return {
    ...entry,
    url: chapterFour755SpritesheetUrls[id]
  };
}

export const FINALE_ENVIRONMENT_SOURCE_MANIFEST = manifest;

export const CHAPTER_FOUR_755_MANIFEST_FRAME_COUNT = Object.values(
  CHAPTER_FOUR_755_SPRITESHEETS
).reduce((count, sheet) => count + sheet.frames.length, 0);

export function getChapterFour755ManifestFrame(
  spritesheetId: ChapterFour755SpritesheetId,
  frameId: string
): ChapterFour755ManifestFrame | null {
  const sheet = CHAPTER_FOUR_755_SPRITESHEETS[spritesheetId];
  return (sheet?.frames.find((frame) => frame.id === frameId) as ChapterFour755ManifestFrame | undefined)
    ?? null;
}

export function preloadFinaleEnvironmentTextures(scene: Phaser.Scene): void {
  Object.values(FINALE_ENVIRONMENTS).forEach((asset) => {
    preloadRpgImage(scene, asset.id, asset.url);
  });
  Object.values(CHAPTER_FOUR_755_PLATES).forEach((asset) => {
    preloadRpgImage(scene, asset.id, asset.url);
  });
  Object.values(CHAPTER_FOUR_755_SPRITESHEETS).forEach((asset) => {
    preloadRpgImage(scene, asset.id, asset.url);
  });
}

/**
 * Registers the active Chapter 4 art as explicit trimmed Phaser frames.
 *
 * The manifest stores `sourceTrim` in absolute sheet coordinates. Phaser's
 * `setTrim` destination is relative to the untrimmed source cell, so this is
 * deliberately not implemented with `load.spritesheet` or a guessed grid.
 * The function is idempotent across Phaser scene restarts and treats a
 * pre-existing frame with different geometry as a contract failure.
 */
export function registerChapterFour755ManifestFrames(
  scene: Phaser.Scene
): ChapterFour755FrameRegistrationReport {
  const frameKeys: string[] = [];
  const contractFailures: string[] = [];
  let registeredFrameCount = 0;
  let reusedFrameCount = 0;
  let skippedEmptyFrameCount = 0;

  for (const sheet of Object.values(CHAPTER_FOUR_755_SPRITESHEETS)) {
    const texture = scene.textures.exists(sheet.id)
      ? scene.textures.get(sheet.id)
      : null;
    if (!texture) {
      contractFailures.push(`spritesheet_missing:${sheet.id}`);
      continue;
    }
    const source = texture.getSourceImage() as { width?: number; height?: number };
    if (source.width !== sheet.sourceSize.width || source.height !== sheet.sourceSize.height) {
      contractFailures.push(
        `spritesheet_size:${sheet.id}:${String(source.width)}x${String(source.height)}`
      );
      continue;
    }

    const manifestFrames = sheet.frames as readonly unknown[] as readonly ChapterFour755ManifestFrame[];
    const manifestIds = new Set<string>();
    for (const definition of manifestFrames) {
      const qualifiedKey = `${sheet.id}:${definition.id}`;
      if (manifestIds.has(definition.id)) {
        contractFailures.push(`frame_duplicate:${qualifiedKey}`);
        continue;
      }
      manifestIds.add(definition.id);

      if (definition.id === "empty" && definition.sourceTrim === null) {
        skippedEmptyFrameCount += 1;
        continue;
      }
      const trim = definition.sourceTrim;
      const cell = definition.sourceCell ?? definition.sourceRect;
      if (!trim || !isValidManifestRect(trim) || !isValidManifestRect(cell)) {
        contractFailures.push(`frame_geometry:${qualifiedKey}`);
        continue;
      }
      if (!rectInside(trim, sheet.sourceSize)
        || trim.x < cell.x
        || trim.y < cell.y
        || trim.x + trim.width > cell.x + cell.width
        || trim.y + trim.height > cell.y + cell.height) {
        contractFailures.push(`frame_out_of_bounds:${qualifiedKey}`);
        continue;
      }
      const pivot = definition.pivot;
      if (!pivot || pivot.coordinateSpace !== "source_sheet") {
        contractFailures.push(`frame_pivot:${qualifiedKey}`);
        continue;
      }
      const pivotX = (pivot.x - cell.x) / cell.width;
      const pivotY = (pivot.y - cell.y) / cell.height;
      if (!Number.isFinite(pivotX)
        || !Number.isFinite(pivotY)
        || pivotX < 0
        || pivotX > 1
        || pivotY < 0
        || pivotY > 1) {
        contractFailures.push(`frame_pivot_out_of_bounds:${qualifiedKey}`);
        continue;
      }

      if (texture.has(definition.id)) {
        const existing = texture.get(definition.id);
        const matches = existing.cutX === trim.x
          && existing.cutY === trim.y
          && existing.cutWidth === trim.width
          && existing.cutHeight === trim.height
          && existing.realWidth === cell.width
          && existing.realHeight === cell.height
          && existing.customPivot
          && Math.abs(existing.pivotX - pivotX) < 0.000001
          && Math.abs(existing.pivotY - pivotY) < 0.000001;
        if (!matches) contractFailures.push(`frame_existing_mismatch:${qualifiedKey}`);
        else {
          reusedFrameCount += 1;
          frameKeys.push(qualifiedKey);
        }
        continue;
      }

      const frame = texture.add(
        definition.id,
        0,
        trim.x,
        trim.y,
        trim.width,
        trim.height
      );
      if (!frame) {
        contractFailures.push(`frame_registration:${qualifiedKey}`);
        continue;
      }
      frame.setTrim(
        cell.width,
        cell.height,
        trim.x - cell.x,
        trim.y - cell.y,
        trim.width,
        trim.height
      );
      frame.pivotX = pivotX;
      frame.pivotY = pivotY;
      frame.customPivot = true;
      registeredFrameCount += 1;
      frameKeys.push(qualifiedKey);
    }
  }

  return Object.freeze({
    manifestFrameCount: CHAPTER_FOUR_755_MANIFEST_FRAME_COUNT,
    registeredFrameCount,
    reusedFrameCount,
    skippedEmptyFrameCount,
    frameKeys: Object.freeze(frameKeys),
    contractFailures: Object.freeze(contractFailures)
  });
}

function isValidManifestRect(rect: ChapterFour755ManifestRect): boolean {
  return Number.isInteger(rect.x)
    && Number.isInteger(rect.y)
    && Number.isInteger(rect.width)
    && Number.isInteger(rect.height)
    && rect.width > 0
    && rect.height > 0;
}

function rectInside(
  rect: ChapterFour755ManifestRect,
  size: { width: number; height: number }
): boolean {
  return rect.x >= 0
    && rect.y >= 0
    && rect.x + rect.width <= size.width
    && rect.y + rect.height <= size.height;
}
