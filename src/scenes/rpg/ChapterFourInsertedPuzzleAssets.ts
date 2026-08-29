import dutyBoardUrl from "../../assets/rpg/interiors/finale/chapter4-755/props/chapter4_front_desk_duty_board_v01.png";
import archiveFilmUrl from "../../assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png";
import alignmentScannerUrl from "../../assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_alignment_scanner_v01.png";
import calibrationJigUrl from "../../assets/rpg/interiors/finale/chapter4-755/props/chapter4_a2_calibration_jig_v01.png";
import circuitTerminalUrl from "../../assets/rpg/interiors/finale/chapter4-755/props/chapter4_a2_circuit_terminal_v01.png";
import evacuationMapUrl from "../../assets/rpg/interiors/finale/chapter4-755/props/chapter4_a2_evacuation_map_v01.png";
import type {
  ChapterFourInsertedPuzzleId,
  ChapterFourInsertedPuzzleTargetId
} from "../../modules/ChapterFourInsertedPuzzleModel";

export interface ChapterFourInsertedPuzzleAsset {
  puzzleId: ChapterFourInsertedPuzzleId;
  targetId: ChapterFourInsertedPuzzleTargetId;
  textureKey: string;
  url: string;
  floor: "A1" | "A2" | "A3";
  center: Readonly<{ x: number; y: number }>;
  sourceSize: Readonly<{ width: number; height: number }>;
  depth: number;
}

/**
 * The six image2 props are authored as transparent, source-pixel overlays.
 * Their centers and dimensions match the corresponding layout anchors so the
 * visible object and interaction area remain traceable to the same rectangle.
 * They deliberately create no physics body or air wall.
 */
export const CHAPTER_FOUR_INSERTED_PUZZLE_ASSETS = Object.freeze([
  {
    puzzleId: "duty_board",
    targetId: "a1_front_desk_duty_board_context",
    textureKey: "chapter4-front-desk-duty-board-v01",
    url: dutyBoardUrl,
    floor: "A1",
    center: { x: 750, y: 600 },
    sourceSize: { width: 152, height: 100 },
    depth: 24
  },
  {
    puzzleId: "positioning_calibration",
    targetId: "a2_maker_workshop_201_context",
    textureKey: "chapter4-a2-calibration-jig-v01",
    url: calibrationJigUrl,
    floor: "A2",
    center: { x: 290, y: 230.5 },
    sourceSize: { width: 116, height: 105 },
    depth: 24
  },
  {
    puzzleId: "power_topology",
    targetId: "a2_computer_room_203_context",
    textureKey: "chapter4-a2-circuit-terminal-v01",
    url: circuitTerminalUrl,
    floor: "A2",
    center: { x: 1340, y: 600 },
    sourceSize: { width: 136, height: 104 },
    depth: 24
  },
  {
    puzzleId: "evacuation_route",
    targetId: "a2_open_study_evacuation_context",
    textureKey: "chapter4-a2-evacuation-map-v01",
    url: evacuationMapUrl,
    floor: "A2",
    center: { x: 850, y: 646.5 },
    sourceSize: { width: 128, height: 93 },
    depth: 24
  },
  {
    puzzleId: "archive_index",
    targetId: "a3_archive_exhibition_301_context",
    textureKey: "chapter4-a3-archive-film-v01",
    url: archiveFilmUrl,
    floor: "A3",
    center: { x: 290, y: 350 },
    sourceSize: { width: 96, height: 82 },
    depth: 24
  },
  {
    puzzleId: "media_alignment",
    targetId: "a3_media_studio_302_context",
    textureKey: "chapter4-a3-alignment-scanner-v01",
    url: alignmentScannerUrl,
    floor: "A3",
    center: { x: 270, y: 670 },
    sourceSize: { width: 132, height: 124 },
    depth: 24
  }
] as const satisfies readonly ChapterFourInsertedPuzzleAsset[]);

export const CHAPTER_FOUR_INSERTED_PUZZLE_ASSET_BY_ID = Object.freeze(
  Object.fromEntries(CHAPTER_FOUR_INSERTED_PUZZLE_ASSETS.map((asset) => [asset.puzzleId, asset]))
) as Readonly<Record<ChapterFourInsertedPuzzleId, ChapterFourInsertedPuzzleAsset>>;
