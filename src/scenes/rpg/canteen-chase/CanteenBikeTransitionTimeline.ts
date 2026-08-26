import type { ChaseRiderPoseName } from "./ChaseRiderRig";

export const TRANSITION_FPS = 24;

export type CanteenBikeTransitionStage = "start" | "finish";
export type CanteenBikeTransitionCameraShot =
  | "canteen_departure_wide"
  | "mount_wide"
  | "grip_pedal_macro"
  | "ride_handoff"
  | "finish_755_wide"
  | "brake_wheel_macro"
  | "dismount_wide"
  | "theater_parking_wide"
  | "theater_door_occlusion";

export interface CanteenBikeTransitionSegment {
  id: string;
  frameStart: number;
  frameEnd: number;
  source: "native" | "hailuo_or_native";
  camera: CanteenBikeTransitionCameraShot;
}

export const START_TRANSITION_SEGMENTS = Object.freeze([
  { id: "O1", frameStart: 0, frameEnd: 9, source: "native", camera: "canteen_departure_wide" },
  { id: "O2", frameStart: 10, frameEnd: 40, source: "native", camera: "mount_wide" },
  { id: "O3", frameStart: 41, frameEnd: 70, source: "hailuo_or_native", camera: "grip_pedal_macro" },
  { id: "O4", frameStart: 71, frameEnd: 90, source: "native", camera: "ride_handoff" }
] as const satisfies readonly CanteenBikeTransitionSegment[]);

export const FINISH_TRANSITION_SEGMENTS = Object.freeze([
  { id: "E1", frameStart: 0, frameEnd: 9, source: "native", camera: "finish_755_wide" },
  { id: "E2", frameStart: 10, frameEnd: 39, source: "hailuo_or_native", camera: "brake_wheel_macro" },
  { id: "E3", frameStart: 40, frameEnd: 90, source: "native", camera: "dismount_wide" },
  { id: "E4", frameStart: 91, frameEnd: 120, source: "native", camera: "theater_parking_wide" },
  { id: "E5", frameStart: 121, frameEnd: 132, source: "native", camera: "theater_door_occlusion" }
] as const satisfies readonly CanteenBikeTransitionSegment[]);

export type CanteenBikeTransitionSegmentId =
  | (typeof START_TRANSITION_SEGMENTS)[number]["id"]
  | (typeof FINISH_TRANSITION_SEGMENTS)[number]["id"];

export const START_TRANSITION_FRAME_COUNT = 91;
export const FINISH_TRANSITION_FRAME_COUNT = 133;
export const START_TRANSITION_LAST_FRAME = START_TRANSITION_FRAME_COUNT - 1;
export const FINISH_TRANSITION_LAST_FRAME = FINISH_TRANSITION_FRAME_COUNT - 1;

export const HAILUO_TRANSITION_FRAME_RANGES = Object.freeze({
  start: Object.freeze({ frameStart: 41, frameEnd: 70 }),
  finish: Object.freeze({ frameStart: 10, frameEnd: 39 })
});

export const TRANSITION_REDUCED_MOTION_ENDPOINTS = Object.freeze({
  start: START_TRANSITION_LAST_FRAME,
  finish: FINISH_TRANSITION_LAST_FRAME
});

export interface CanteenBikeTransitionPose {
  pose: ChaseRiderPoseName;
  poseProgress: number;
  pedalPhaseRadians: number;
  wheelRotationRadians: number;
  wheelSpeedRatio: number;
  rootX: number;
  rootY: number;
  rootZ: number;
  bicycleOffsetX: number;
  bicycleOffsetZ: number;
  riderOffsetX: number;
  riderOffsetZ: number;
  paperX: number;
  paperY: number;
  paperZ: number;
  paperVisible: boolean;
  npcVisible: boolean;
  doorOcclusion: number;
}

export interface CanteenBikeTransitionCamera {
  shot: CanteenBikeTransitionCameraShot;
  position: readonly [number, number, number];
  lookAt: readonly [number, number, number];
  fov: number;
}

export type CanteenBikeTransitionFrameEvent =
  | "bike_unlock"
  | "cut_mount_wide"
  | "cut_grip_pedal_macro"
  | "cut_ride_handoff"
  | "start_gate_complete"
  | "cut_brake_wheel_macro"
  | "cut_dismount_wide"
  | "cut_theater_parking"
  | "cut_door_occlusion"
  | "finish_gate_complete";

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

function clamp01(value: number): number {
  return clamp(value, 0, 1);
}

function rangeProgress(frame: number, start: number, end: number): number {
  if (end <= start) return frame >= end ? 1 : 0;
  return clamp01((frame - start) / (end - start));
}

function smoothstep(value: number): number {
  const progress = clamp01(value);
  return progress * progress * (3 - 2 * progress);
}

function lerp(from: number, to: number, progress: number): number {
  return from + (to - from) * clamp01(progress);
}

export function getCanteenBikeTransitionLastFrame(stage: CanteenBikeTransitionStage): number {
  return stage === "start" ? START_TRANSITION_LAST_FRAME : FINISH_TRANSITION_LAST_FRAME;
}

export function clampCanteenBikeTransitionFrame(stage: CanteenBikeTransitionStage, frame: number): number {
  return clamp(Math.round(frame), 0, getCanteenBikeTransitionLastFrame(stage));
}

export function getCanteenBikeTransitionSegment(
  stage: CanteenBikeTransitionStage,
  frame: number
): CanteenBikeTransitionSegment {
  const normalizedFrame = clampCanteenBikeTransitionFrame(stage, frame);
  const segments = stage === "start" ? START_TRANSITION_SEGMENTS : FINISH_TRANSITION_SEGMENTS;
  return segments.find((segment) => normalizedFrame >= segment.frameStart && normalizedFrame <= segment.frameEnd)
    ?? segments[segments.length - 1];
}

function basePose(): CanteenBikeTransitionPose {
  return {
    pose: "ride",
    poseProgress: 1,
    pedalPhaseRadians: 0,
    wheelRotationRadians: 0,
    wheelSpeedRatio: 0,
    rootX: 0,
    rootY: 0.08,
    rootZ: 0,
    bicycleOffsetX: 0,
    bicycleOffsetZ: 0,
    riderOffsetX: 0,
    riderOffsetZ: 0,
    paperX: 0.5,
    paperY: 2.7,
    paperZ: -9,
    paperVisible: true,
    npcVisible: true,
    doorOcclusion: 0
  };
}

/** Pure frame-to-pose mapping. It contains presentation values only. */
export function getCanteenBikeTransitionPose(
  stage: CanteenBikeTransitionStage,
  frame: number
): CanteenBikeTransitionPose {
  const current = clampCanteenBikeTransitionFrame(stage, frame);
  const result = basePose();

  if (stage === "start") {
    result.paperZ = -10.5;
    if (current <= 16) {
      result.pose = "stand_left";
      result.poseProgress = 1;
    } else if (current <= 23) {
      result.pose = "grip";
      result.poseProgress = smoothstep(rangeProgress(current, 17, 23));
    } else if (current <= 33) {
      result.pose = "leg_over";
      result.poseProgress = smoothstep(rangeProgress(current, 24, 33));
    } else if (current <= 40) {
      result.pose = "seated_balance";
      result.poseProgress = smoothstep(rangeProgress(current, 34, 40));
    } else if (current <= 70) {
      const macroProgress = smoothstep(rangeProgress(current, 41, 70));
      result.pose = "pedal_press";
      result.poseProgress = macroProgress;
      result.pedalPhaseRadians = lerp(0, -Math.PI / 4, macroProgress);
      result.wheelSpeedRatio = lerp(0, 0.22, macroProgress);
      result.wheelRotationRadians = -macroProgress * 0.35;
      result.npcVisible = false;
      result.paperVisible = false;
    } else {
      const launchProgress = smoothstep(rangeProgress(current, 71, 90));
      result.pose = "ride";
      result.poseProgress = launchProgress;
      result.pedalPhaseRadians = -Math.PI / 4 - launchProgress * Math.PI * 1.25;
      result.wheelSpeedRatio = lerp(0.22, 1, launchProgress);
      result.wheelRotationRadians = -0.35 - launchProgress * Math.PI * 2.6;
      result.rootZ = -launchProgress * 4.2;
      result.paperZ = -11.5 - launchProgress * 2;
    }
    return result;
  }

  result.rootZ = 0;
  result.paperZ = -10.6;
  result.paperY = 2.85;
  if (current <= 9) {
    const openingProgress = rangeProgress(current, 0, 9);
    result.pose = "brake";
    result.poseProgress = 0;
    result.pedalPhaseRadians = -Math.PI / 4;
    result.wheelSpeedRatio = 1;
    result.wheelRotationRadians = -openingProgress * Math.PI * 1.6;
  } else if (current <= 39) {
    const macroProgress = smoothstep(rangeProgress(current, 10, 39));
    result.pose = "brake";
    result.poseProgress = macroProgress;
    result.pedalPhaseRadians = -Math.PI / 4;
    result.wheelSpeedRatio = lerp(1, 0.35, macroProgress);
    result.wheelRotationRadians = -Math.PI * 1.6 - macroProgress * Math.PI * 2.1;
    result.npcVisible = false;
    result.paperVisible = false;
  } else if (current <= 55) {
    const stopProgress = smoothstep(rangeProgress(current, 40, 55));
    result.pose = "brake";
    result.poseProgress = 1;
    result.pedalPhaseRadians = -Math.PI / 4;
    result.wheelSpeedRatio = lerp(0.35, 0, stopProgress);
    result.wheelRotationRadians = -Math.PI * 3.7 - stopProgress * 0.8;
    result.rootZ = -stopProgress * 1.4;
  } else if (current <= 66) {
    result.pose = "left_foot_down";
    result.poseProgress = smoothstep(rangeProgress(current, 56, 66));
    result.wheelRotationRadians = -Math.PI * 3.7 - 0.8;
    result.rootZ = -1.4;
  } else if (current <= 82) {
    result.pose = "dismount_leg_over";
    result.poseProgress = smoothstep(rangeProgress(current, 67, 82));
    result.wheelRotationRadians = -Math.PI * 3.7 - 0.8;
    result.rootZ = -1.4;
  } else if (current <= 90) {
    result.pose = "stand_with_bike";
    result.poseProgress = smoothstep(rangeProgress(current, 83, 90));
    result.wheelRotationRadians = -Math.PI * 3.7 - 0.8;
    result.rootZ = -1.4;
  } else if (current <= 107) {
    const parkingProgress = smoothstep(rangeProgress(current, 91, 107));
    result.pose = "push_bike";
    result.poseProgress = parkingProgress;
    result.rootX = parkingProgress * 4.8;
    result.rootZ = -1.4 - parkingProgress * 1.2;
    result.wheelRotationRadians = -Math.PI * 3.7 - 0.8 - parkingProgress * Math.PI * 1.1;
    result.paperZ = lerp(-10.6, -15.2, parkingProgress);
    result.paperY = lerp(2.85, 2.15, parkingProgress);
  } else if (current <= 120) {
    const walkProgress = smoothstep(rangeProgress(current, 108, 120));
    result.pose = "stand_left";
    result.poseProgress = 1;
    result.rootX = 4.8;
    result.rootZ = -2.6;
    result.bicycleOffsetX = 0.55;
    result.riderOffsetX = lerp(0, -3.97, walkProgress);
    result.riderOffsetZ = lerp(-0.32, -4.98, walkProgress);
    result.paperZ = lerp(-15.2, -17.2, walkProgress);
    result.paperY = lerp(2.15, 1.75, walkProgress);
  } else {
    const coverProgress = smoothstep(rangeProgress(current, 121, 126));
    result.pose = "stand_left";
    result.poseProgress = 1;
    result.rootX = 4.8;
    result.rootZ = -2.6;
    result.bicycleOffsetX = 0.55;
    result.riderOffsetX = -3.97;
    result.riderOffsetZ = -4.98;
    result.paperZ = -17.2;
    result.paperY = 1.75;
    result.doorOcclusion = coverProgress;
  }
  return result;
}

/** Pure frame-to-camera mapping used by the renderer and anchor capture harness. */
export function getCanteenBikeTransitionCamera(
  stage: CanteenBikeTransitionStage,
  frame: number
): CanteenBikeTransitionCamera {
  const segment = getCanteenBikeTransitionSegment(stage, frame);
  switch (segment.camera) {
    case "canteen_departure_wide":
      return { shot: segment.camera, position: [7.6, 4.5, 8.2], lookAt: [-0.15, 1.35, -0.4], fov: 46 };
    case "mount_wide":
      return { shot: segment.camera, position: [6.8, 3.45, 6.2], lookAt: [-0.1, 1.32, -0.2], fov: 42 };
    case "grip_pedal_macro":
      return { shot: segment.camera, position: [5.15, 2.75, 5.05], lookAt: [0.12, 1.28, -0.08], fov: 31 };
    case "ride_handoff": {
      const progress = smoothstep(rangeProgress(clampCanteenBikeTransitionFrame(stage, frame), 71, 90));
      return {
        shot: segment.camera,
        position: [lerp(6.5, 0.25, progress), lerp(3.65, 4.82, progress), lerp(6.7, 8.45, progress)],
        lookAt: [0, lerp(1.3, 1.12, progress), lerp(-0.6, -12.8, progress)],
        fov: lerp(43, 55, progress)
      };
    }
    case "finish_755_wide":
      return { shot: segment.camera, position: [6.8, 4.2, 8.5], lookAt: [0, 1.25, -6.6], fov: 45 };
    case "brake_wheel_macro":
      return { shot: segment.camera, position: [5.1, 2.72, 4.55], lookAt: [0.14, 1.3, -0.42], fov: 31 };
    case "dismount_wide":
      return { shot: segment.camera, position: [7.2, 3.7, 7.4], lookAt: [0, 1.25, -3.2], fov: 43 };
    case "theater_parking_wide":
      return { shot: segment.camera, position: [8.8, 4.6, 9.8], lookAt: [0.4, 1.55, -8.4], fov: 47 };
    default:
      return { shot: segment.camera, position: [8.8, 4.6, 9.8], lookAt: [0.4, 1.55, -8.4], fov: 47 };
  }
}

/** Pure frame-to-event mapping. Events describe cuts and presentation endpoints only. */
export function getCanteenBikeTransitionEvents(
  stage: CanteenBikeTransitionStage,
  frame: number
): readonly CanteenBikeTransitionFrameEvent[] {
  const current = clampCanteenBikeTransitionFrame(stage, frame);
  const events: CanteenBikeTransitionFrameEvent[] = [];
  if (stage === "start") {
    if (current === 4) events.push("bike_unlock");
    if (current === 10) events.push("cut_mount_wide");
    if (current === 41) events.push("cut_grip_pedal_macro");
    if (current === 71) events.push("cut_ride_handoff");
    if (current === START_TRANSITION_LAST_FRAME) events.push("start_gate_complete");
  } else {
    if (current === 10) events.push("cut_brake_wheel_macro");
    if (current === 40) events.push("cut_dismount_wide");
    if (current === 91) events.push("cut_theater_parking");
    if (current === 121) events.push("cut_door_occlusion");
    if (current === FINISH_TRANSITION_LAST_FRAME) events.push("finish_gate_complete");
  }
  return events;
}
