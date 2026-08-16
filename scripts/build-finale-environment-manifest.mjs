import { createHash } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const assetRoot = resolve(repoRoot, "src/assets/rpg/interiors/finale");
const expectedSize = { width: 1672, height: 941 };
const elevatorDoorSheet = {
  id: "teaching_building_elevator_doors",
  title: "教学楼单电梯门六档动画",
  file: "teaching_building_elevator_doors.png",
  size: { width: 432, height: 96 },
  frameSize: { width: 72, height: 96 },
  frameCount: 6,
  purpose: "覆盖三层母图中的关闭门，按关闭至全开六档播放同源像素门动画。"
};

const sceneDefinitions = [
  {
    id: "finale_arrival_arcade",
    title: "启真湖至教学楼拱廊",
    file: "finale_arrival_arcade.png",
    projection: "pseudo_2_5d_side",
    temporalCellId: null,
    purpose: "只用于启真湖追逐结束后的低机位纸条追踪序幕。",
    dynamicLayers: ["wet_paper", "student", "rain_drops", "glass_door_pressure"]
  },
  {
    id: "finale_1f_lobby_maxwell",
    title: "一楼门厅与迈斯威",
    file: "finale_1f_lobby_maxwell.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_floor1_maxwell",
    purpose: "承担入楼、气流轨迹教学、纸张干燥与整楼复位演出。",
    dynamicLayers: ["glass_doors", "maxwell_shutter", "warm_air", "wet_floor", "paper_trail"]
  },
  {
    id: "finale_stairwell",
    title: "楼梯间",
    file: "finale_stairwell.png",
    projection: "top_down_orthographic",
    temporalCellId: null,
    purpose: "玩家跨楼层通行与保安位置声学预警；大型签到板无法通过转角。",
    dynamicLayers: ["floor_doors", "guard_audio_zone"]
  },
  {
    id: "finale_vertical_core",
    title: "电梯竖向交通核",
    file: "finale_vertical_core.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_vertical_core",
    purpose: "承担第一次历史电梯、服务模式锚定和大型签到板运输。",
    dynamicLayers: ["elevator_doors", "elevator_car", "service_panel", "floor_indicator"]
  },
  {
    id: "finale_2f_activity",
    title: "二楼开放自习与活动区",
    file: "finale_2f_activity.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_floor2_activity",
    purpose: "承载影片拼接、活动器材、签到板组合和第二轮通行。",
    dynamicLayers: ["activity_equipment", "attendance_board", "paper", "door_labels", "study_lights"]
  },
  {
    id: "finale_final_classroom",
    title: "N3-214 智慧教室",
    file: "finale_final_classroom.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_final_classroom",
    purpose: "承担 07:55 局部时间合成、课程校验与签到成功结局。",
    dynamicLayers: ["morning_light", "smart_screens", "wall_clock", "scanner", "attendance_board"]
  },
  {
    id: "teaching_building_floor_1",
    title: "教学楼 1F · 麦思威与校友廊",
    file: "teaching_building_floor_1.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_teaching_floor_1",
    purpose: "作为三层拼接教学楼的一楼底图，承载主入口、麦思威面包坊餐厅、104/105 教室门厅和校友头像长廊。",
    dynamicLayers: ["player", "elevator_selection", "story_hotspots", "classroom_doors", "alumni_portrait_clues"]
  },
  {
    id: "teaching_building_floor_2",
    title: "教学楼 2F · 教室与开放学习区",
    file: "teaching_building_floor_2.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_teaching_floor_2",
    purpose: "作为三层拼接教学楼的二楼底图，承载创客工坊、研讨教室、阶梯教室、计算机教室和开放学习区。",
    dynamicLayers: ["player", "elevator_selection", "story_hotspots", "classroom_doors", "alumni_portrait_clues"]
  },
  {
    id: "teaching_building_floor_3",
    title: "教学楼 3F · 校友荣誉门厅",
    file: "teaching_building_floor_3.png",
    projection: "top_down_orthographic",
    temporalCellId: "cell_teaching_floor_3",
    purpose: "作为三层拼接教学楼的三楼底图，承载校史档案展、媒体工作室、报告厅、智慧教室和校友荣誉门厅。",
    dynamicLayers: ["player", "elevator_selection", "story_hotspots", "classroom_doors", "alumni_portrait_clues"]
  }
];

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function readPngSize(bytes, file) {
  const signature = bytes.subarray(0, 8).toString("hex");
  if (signature !== "89504e470d0a1a0a" || bytes.subarray(12, 16).toString("ascii") !== "IHDR") {
    throw new Error(`${file} is not a PNG with a readable IHDR header.`);
  }
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

const scenes = [];
for (const definition of sceneDefinitions) {
  const path = resolve(assetRoot, definition.file);
  const bytes = await readFile(path);
  const size = readPngSize(bytes, definition.file);
  if (size.width !== expectedSize.width || size.height !== expectedSize.height) {
    throw new Error(
      `${definition.file} must remain ${expectedSize.width}x${expectedSize.height}; got ${size.width}x${size.height}.`
    );
  }
  scenes.push({
    ...definition,
    sourceSize: size,
    logicalViewport: { width: 960, height: 540 },
    baseLayerOnly: true,
    sourceFile: `src/assets/rpg/interiors/finale/${definition.file}`,
    sha256: sha256(bytes)
  });
}

const elevatorDoorBytes = await readFile(resolve(assetRoot, elevatorDoorSheet.file));
const elevatorDoorSize = readPngSize(elevatorDoorBytes, elevatorDoorSheet.file);
if (
  elevatorDoorSize.width !== elevatorDoorSheet.size.width
  || elevatorDoorSize.height !== elevatorDoorSheet.size.height
) {
  throw new Error(
    `${elevatorDoorSheet.file} must remain ${elevatorDoorSheet.size.width}x${elevatorDoorSheet.size.height}; got ${elevatorDoorSize.width}x${elevatorDoorSize.height}.`
  );
}

const spritesheets = [{
  ...elevatorDoorSheet,
  sourceSize: elevatorDoorSize,
  sourceFile: `src/assets/rpg/interiors/finale/${elevatorDoorSheet.file}`,
  sha256: sha256(elevatorDoorBytes)
}];

const manifest = {
  schemaVersion: 2,
  generatedAt: "source-derived",
  runtimeAuthority: "phaser",
  progressionAuthority: "typescript",
  sourceProjectionRule: "interiors_top_down_arrival_only_pseudo_2_5d",
  scenes,
  spritesheets
};

await writeFile(
  resolve(assetRoot, "finale_environment_manifest.json"),
  `${JSON.stringify(manifest, null, 2)}\n`
);

console.log(
  `built finale environment manifest scenes=${scenes.length} spritesheets=${spritesheets.length} size=${expectedSize.width}x${expectedSize.height}`
);
