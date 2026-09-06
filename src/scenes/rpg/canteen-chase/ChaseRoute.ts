/** Shared stage locations for art and UI. ChaseStuntModel owns active movement and speed. */
export const CHASE_GOAL_METERS = 755;
export const CHASE_WORLD_PER_METER = 1.05;
export const CHASE_ROUTE_STAGES = Object.freeze([
  { id: "departure", label: "食堂出口", start: 0, end: 188 },
  { id: "avenue", label: "林荫主路", start: 188, end: 377 },
  { id: "construction", label: "施工绕行", start: 377, end: 566 },
  { id: "theater", label: "剧场冲刺", start: 566, end: 755 }
] as const);

export function chaseStageAt(distance: number) {
  return CHASE_ROUTE_STAGES.find((stage) => distance < stage.end) ?? CHASE_ROUTE_STAGES[3];
}

