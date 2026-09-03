import type Phaser from "phaser";
import type { GameState } from "../../core/types";
import teachingBuildingElevatorDoorsUrl from "../../assets/rpg/interiors/finale/teaching_building_elevator_doors.png";
import canruoStarLampCoreUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_core.png";
import canruoStarLampDarkUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png";
import canruoStarLampGlowUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_glow.png";
import canruoStarLampLedsUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_leds.png";
import canruoStarLampOutlineUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_outline.png";
import canteenCounterAuntiesSheetUrl from "../../assets/rpg/npcs/canteen/counter_aunties_2frame.png";
import frontDeskStaffSheetUrl from "../../assets/rpg/npcs/library/front_desk_staff_2frame.png";
import { CHAPTER_FOUR_ALUMNI_HONOR_WALL } from "../../data/ChapterFourAlumniHonorWall";
import {
  CHAPTER_FOUR_755_PLATES,
  CHAPTER_FOUR_755_SPRITESHEETS,
  type ChapterFour755PlateId,
  type ChapterFour755SpritesheetId
} from "./FinaleEnvironmentTextures";
import {
  FINALE_NPC_ANIMATIONS,
  type FinaleNpcAnimationId
} from "./FinaleNpcTextures";
import { CHAPTER_FOUR_INSERTED_PUZZLE_ASSETS } from "./ChapterFourInsertedPuzzleAssets";

export const CHAPTER_FOUR_WARMUP_PHASES = Object.freeze([
  "entry",
  "transport",
  "maintenance",
  "closure"
] as const);

export type ChapterFourWarmupPhase = typeof CHAPTER_FOUR_WARMUP_PHASES[number];

export type ChapterFourWarmupAsset = Readonly<{
  key: string;
  url: string;
  kind: "image" | "spritesheet";
  frameWidth?: number;
  frameHeight?: number;
  sourceSize?: Readonly<{ width: number; height: number }>;
}>;

export const CHAPTER_FOUR_ELEVATOR_TEXTURE_KEY = "teaching-building-elevator-doors";
export const CHAPTER_FOUR_BAKERY_STAFF_TEXTURE_KEY = "chapter-four-bakery-counter-auntie";
export const CHAPTER_FOUR_FRONT_DESK_TEXTURE_KEY = "chapter-four-front-desk-staff";

const ENTRY_PLATE_IDS = Object.freeze([
  "a1_base",
  "a1_2245_opening"
] satisfies readonly ChapterFour755PlateId[]);

const TRANSPORT_PLATE_IDS = Object.freeze([
  "a2_base",
  "a3_base",
  "a1_1225_bakery",
  "a2_1850_evening",
  "a3_1850_reference"
] satisfies readonly ChapterFour755PlateId[]);

const MAINTENANCE_PLATE_IDS = Object.freeze([
  "a1_2245_maintenance",
  "a1_0754_blackout",
  "a2_0754_chase"
] satisfies readonly ChapterFour755PlateId[]);

const CLOSURE_PLATE_IDS = Object.freeze([
  "a2_202_final_minute",
  "a1_0755_morning"
] satisfies readonly ChapterFour755PlateId[]);

const CLOSURE_LAMP_ASSETS = Object.freeze([
  { key: "canruo-star-lamp-dark", url: canruoStarLampDarkUrl },
  { key: "canruo-star-lamp-outline", url: canruoStarLampOutlineUrl },
  { key: "canruo-star-lamp-leds", url: canruoStarLampLedsUrl },
  { key: "canruo-star-lamp-core", url: canruoStarLampCoreUrl },
  { key: "canruo-star-lamp-glow", url: canruoStarLampGlowUrl }
].map((asset) => Object.freeze({
  ...asset,
  kind: "image" as const,
  sourceSize: Object.freeze({ width: 1024, height: 1536 })
})));

const ENTRY_SPRITESHEET_IDS = Object.freeze([
  "chapter4_clock_states",
  "chapter4_story_items"
] satisfies readonly ChapterFour755SpritesheetId[]);

const TRANSPORT_SPRITESHEET_IDS = Object.freeze([
  "chapter4_room204_furniture",
  "chapter4_room204_residual"
] satisfies readonly ChapterFour755SpritesheetId[]);

const MAINTENANCE_SPRITESHEET_IDS = Object.freeze([
  "chapter4_power_panel_states"
] satisfies readonly ChapterFour755SpritesheetId[]);

const TRANSPORT_NPC_IDS = Object.freeze([
  "student_walk",
  "student_phone_glance",
  "student_adjust_bag",
  "student_push_door",
  "student_idle",
  "guard_check_watch"
] satisfies readonly FinaleNpcAnimationId[]);

const MAINTENANCE_NPC_IDS = Object.freeze([
  "cleaner_push_cart",
  "cleaner_push_cart_down",
  "cleaner_push_cart_up",
  "cleaner_mop",
  "cleaning_cart",
  "cleaner_place_sign",
  "cleaner_toggle_lights",
  "cleaner_rest",
  "cleaner_idle",
  "guard_walk",
  "guard_walk_down",
  "guard_walk_up",
  "guard_check_list",
  "guard_flashlight_down",
  "guard_radio"
] satisfies readonly FinaleNpcAnimationId[]);

function plateAsset(id: ChapterFour755PlateId): ChapterFourWarmupAsset {
  const asset = CHAPTER_FOUR_755_PLATES[id];
  return {
    key: asset.id,
    url: asset.url,
    kind: "image",
    sourceSize: asset.sourceSize
  };
}

function manifestSpritesheetAsset(id: ChapterFour755SpritesheetId): ChapterFourWarmupAsset {
  const asset = CHAPTER_FOUR_755_SPRITESHEETS[id];
  return {
    key: asset.id,
    url: asset.url,
    kind: "image",
    sourceSize: asset.sourceSize
  };
}

function npcAsset(id: FinaleNpcAnimationId): ChapterFourWarmupAsset {
  const asset = FINALE_NPC_ANIMATIONS[id];
  return {
    key: asset.id,
    url: asset.url,
    kind: "spritesheet",
    frameWidth: asset.frameWidth,
    frameHeight: asset.frameHeight
  };
}

export const CHAPTER_FOUR_WARMUP_ASSETS = Object.freeze({
  entry: Object.freeze([
    ...ENTRY_PLATE_IDS.map(plateAsset),
    ...ENTRY_SPRITESHEET_IDS.map(manifestSpritesheetAsset),
    {
      key: CHAPTER_FOUR_ELEVATOR_TEXTURE_KEY,
      url: teachingBuildingElevatorDoorsUrl,
      kind: "spritesheet",
      frameWidth: 72,
      frameHeight: 96
    },
    {
      key: CHAPTER_FOUR_FRONT_DESK_TEXTURE_KEY,
      url: frontDeskStaffSheetUrl,
      kind: "spritesheet",
      frameWidth: 96,
      frameHeight: 128
    }
  ]),
  transport: Object.freeze([
    ...TRANSPORT_PLATE_IDS.map(plateAsset),
    ...TRANSPORT_SPRITESHEET_IDS.map(manifestSpritesheetAsset),
    ...TRANSPORT_NPC_IDS.map(npcAsset),
    ...CHAPTER_FOUR_INSERTED_PUZZLE_ASSETS.map((asset) => ({
      key: asset.textureKey,
      url: asset.url,
      kind: "image" as const,
      sourceSize: asset.sourceSize
    })),
    {
      key: CHAPTER_FOUR_BAKERY_STAFF_TEXTURE_KEY,
      url: canteenCounterAuntiesSheetUrl,
      kind: "spritesheet",
      frameWidth: 96,
      frameHeight: 128
    },
    ...CHAPTER_FOUR_ALUMNI_HONOR_WALL.map((figure) => ({
      key: figure.portraitTextureKey,
      url: figure.portraitUrl,
      kind: "image" as const
    }))
  ]),
  maintenance: Object.freeze([
    ...MAINTENANCE_PLATE_IDS.map(plateAsset),
    ...MAINTENANCE_SPRITESHEET_IDS.map(manifestSpritesheetAsset),
    ...MAINTENANCE_NPC_IDS.map(npcAsset)
  ]),
  closure: Object.freeze([
    ...CLOSURE_PLATE_IDS.map(plateAsset),
    ...CLOSURE_LAMP_ASSETS
  ])
} satisfies Readonly<Record<ChapterFourWarmupPhase, readonly ChapterFourWarmupAsset[]>>);

const PHASE_INDEX = new Map<ChapterFourWarmupPhase, number>(
  CHAPTER_FOUR_WARMUP_PHASES.map((phase, index) => [phase, index])
);

export function isChapterFourWarmupPhase(value: unknown): value is ChapterFourWarmupPhase {
  return typeof value === "string" && PHASE_INDEX.has(value as ChapterFourWarmupPhase);
}

export function getChapterFourWarmupPhaseAssets(
  phase: ChapterFourWarmupPhase
): readonly ChapterFourWarmupAsset[] {
  return CHAPTER_FOUR_WARMUP_ASSETS[phase];
}

export function getChapterFourWarmupAssetsThroughPhase(
  phase: ChapterFourWarmupPhase
): readonly ChapterFourWarmupAsset[] {
  const targetIndex = PHASE_INDEX.get(phase) ?? 0;
  const assets = CHAPTER_FOUR_WARMUP_PHASES
    .slice(0, targetIndex + 1)
    .flatMap((candidate) => CHAPTER_FOUR_WARMUP_ASSETS[candidate]);
  return [...new Map(assets.map((asset) => [asset.key, asset])).values()];
}

export function getNextChapterFourWarmupPhase(
  phase: ChapterFourWarmupPhase
): ChapterFourWarmupPhase | null {
  const index = PHASE_INDEX.get(phase) ?? 0;
  return CHAPTER_FOUR_WARMUP_PHASES[index + 1] ?? null;
}

export function chapterFourWarmupPhaseForChapterPhase(
  phase: GameState["chapter4"]["phase"]
): ChapterFourWarmupPhase {
  switch (phase) {
    case "bakery_hour_hand":
    case "room204_restore":
      return "transport";
    case "maintenance_repair":
    case "blackout_light_grid":
    case "final_chase":
    case "return_to_clock":
      return "maintenance";
    case "final_minute_recovery":
    case "morning_checkin":
    case "exterior_closure":
    case "complete":
      return "closure";
    default:
      return "entry";
  }
}

export function chapterFourWarmupPhaseForState(state: GameState): ChapterFourWarmupPhase {
  return chapterFourWarmupPhaseForChapterPhase(state.chapter4.phase);
}

export function queueChapterFourWarmupAsset(
  scene: Phaser.Scene,
  asset: ChapterFourWarmupAsset
): boolean {
  if (scene.textures.exists(asset.key)) return false;
  if (asset.kind === "spritesheet") {
    scene.load.spritesheet(asset.key, asset.url, {
      frameWidth: asset.frameWidth!,
      frameHeight: asset.frameHeight!
    });
  } else {
    scene.load.image(asset.key, asset.url);
  }
  return true;
}
