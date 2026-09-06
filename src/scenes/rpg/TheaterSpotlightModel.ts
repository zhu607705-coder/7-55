/** Deterministic rules for 追光灯辞职以后. No Phaser, DOM, assets or save writes. */
export const THEATER_SHOW_STEP_MS = 50;
export const THEATER_SHOW_MAX_TICKS = 1600;
export const THEATER_SHOW_BOUNDS = { left: 58, right: 902, top: 132, bottom: 409 } as const;
export const THEATER_SHOW_ACTS = [
  { title: "椅子申请当月亮", subtitle: "吃掉逗号。椅子会自己走路，别让它坐到你身上。", glyph: "，", color: 0xffcf68, count: 4 },
  { title: "你的影子迟到了", subtitle: "吃掉问号。影子沿着你三秒前的路线追过来。", glyph: "？", color: 0x94f3d0, count: 5 },
  { title: "观众席正在退潮", subtitle: "吃掉感叹号。掌声会把光推走；集齐后钻进谢幕的大嘴。", glyph: "！", color: 0xff94bc, count: 6 }
] as const;
export interface TheaterShowPoint { x: number; y: number }
export interface TheaterShowInput { x: number; y: number; dash: boolean }
export interface TheaterSpotlightAttempt {
  version: 2;
  round: number;
  attempt: number;
  inputs: TheaterShowInput[];
}
export interface TheaterShowState {
  round: number;
  attempt: number;
  tick: number;
  status: "running" | "won" | "lost";
  head: TheaterShowPoint;
  trail: TheaterShowPoint[];
  history: TheaterShowPoint[];
  collected: number[];
  lives: number;
  invulnerable: number;
  dashTicks: number;
  dashCooldown: number;
  dashHeld: boolean;
  lastDirection: TheaterShowPoint;
  lastEvent: "none" | "eat" | "hurt" | "dash" | "exit";
}
export interface TheaterShowHazard extends TheaterShowPoint { id: string; radius: number; kind: "chair" | "shadow" | "eye" }
const FOOD_POINTS: readonly TheaterShowPoint[] = [
  { x: 300, y: 193 }, { x: 515, y: 341 }, { x: 738, y: 187 },
  { x: 800, y: 361 }, { x: 346, y: 344 }, { x: 567, y: 178 }
];
export function createTheaterShow(round: number, attempt = 0): TheaterShowState {
  if (!Number.isInteger(round) || round < 0 || round >= THEATER_SHOW_ACTS.length) throw new Error("Invalid theater act");
  const head = { x: 156, y: 280 };
  return { round, attempt, tick: 0, status: "running", head, trail: [{ ...head }], history: [{ ...head }], collected: [],
    lives: 3, invulnerable: 0, dashTicks: 0, dashCooldown: 0, dashHeld: false, lastDirection: { x: 1, y: 0 }, lastEvent: "none" };
}
export function getTheaterShowFood(state: TheaterShowState): (TheaterShowPoint & { id: number })[] {
  return FOOD_POINTS.slice(0, THEATER_SHOW_ACTS[state.round].count)
    .map((p, id) => ({ ...p, id }))
    .filter(p => !state.collected.includes(p.id));
}
export function getTheaterShowMouth(state: TheaterShowState): TheaterShowPoint {
  return { x: 839, y: state.round === 2 ? 266 + Math.sin(state.tick * 0.035) * 36 : 274 };
}
export function getTheaterShowHazards(state: TheaterShowState): TheaterShowHazard[] {
  const t = state.tick * 0.05 * Math.max(0.72, 1 - state.attempt * 0.045);
  const hazards: TheaterShowHazard[] = [
    { id: "chair-0", kind: "chair", x: 421 + Math.sin(t * 0.8) * 40, y: 264 + Math.sin(t * 1.3) * 87, radius: 21 },
    { id: "chair-1", kind: "chair", x: 655 + Math.sin(t * 0.67 + 2) * 49, y: 281 + Math.cos(t * 1.1) * 69, radius: 21 }
  ];
  if (state.round >= 1 && state.history.length > 60) {
    const p = state.history[state.history.length - 61];
    hazards.push({ id: "late-shadow", kind: "shadow", ...p, radius: 22 });
  }
  if (state.round === 2) hazards.push({ id: "audience-eye", kind: "eye", x: 495 + Math.cos(t * 0.9) * 125, y: 255 + Math.sin(t * 1.5) * 88, radius: 23 });
  return hazards;
}
const clamp = (value: number, min: number, max: number) => Math.max(min, Math.min(max, value));
export function stepTheaterShow(state: TheaterShowState, input: TheaterShowInput): TheaterShowState {
  if (state.status !== "running") return state;
  const next: TheaterShowState = { ...state, tick: state.tick + 1, head: { ...state.head }, collected: [...state.collected],
    invulnerable: Math.max(0, state.invulnerable - 1), dashTicks: Math.max(0, state.dashTicks - 1),
    dashCooldown: Math.max(0, state.dashCooldown - 1), dashHeld: input.dash, lastEvent: "none" };
  let dx = clamp(input.x, -1, 1), dy = clamp(input.y, -1, 1);
  const length = Math.hypot(dx, dy);
  if (length > 0.001) { dx /= length; dy /= length; next.lastDirection = { x: dx, y: dy }; }
  if (input.dash && !state.dashHeld && next.dashCooldown === 0) {
    next.dashTicks = 9; next.dashCooldown = 100; next.lastEvent = "dash";
  }
  const speed = next.dashTicks > 0 ? 330 : 166;
  if (next.dashTicks > 0 && length < 0.001) { dx = state.lastDirection.x; dy = state.lastDirection.y; }
  next.head.x += dx * speed * 0.05;
  next.head.y += dy * speed * 0.05;
  if (state.round === 2 && next.dashTicks === 0) {
    next.head.y += Math.sin(next.tick * 0.028) * 1.5;
    next.head.x += Math.cos(next.tick * 0.019) * 0.7;
  }
  next.head.x = clamp(next.head.x, THEATER_SHOW_BOUNDS.left + 13, THEATER_SHOW_BOUNDS.right - 13);
  next.head.y = clamp(next.head.y, THEATER_SHOW_BOUNDS.top + 13, THEATER_SHOW_BOUNDS.bottom - 13);
  next.history = [...state.history, { ...next.head }].slice(-100);
  next.trail = Math.hypot(next.head.x - state.trail[0].x, next.head.y - state.trail[0].y) > 3
    ? [{ ...next.head }, ...state.trail].slice(0, 24 + next.collected.length * 5)
    : state.trail;
  for (const food of getTheaterShowFood(next)) {
    if (Math.hypot(food.x - next.head.x, food.y - next.head.y) < 25) {
      next.collected.push(food.id); next.lastEvent = "eat";
    }
  }
  // The exit wins on a shared frame before hazards are checked.
  const mouth = getTheaterShowMouth(next);
  if (next.collected.length >= THEATER_SHOW_ACTS[next.round].count && Math.hypot(mouth.x - next.head.x, mouth.y - next.head.y) < 35) {
    next.status = "won"; next.lastEvent = "exit"; return next;
  }
  if (next.invulnerable === 0 && next.dashTicks === 0) {
    const hazard = getTheaterShowHazards(next).find(h => Math.hypot(h.x - next.head.x, h.y - next.head.y) < h.radius + 10);
    if (hazard) { next.lives -= 1; next.invulnerable = 36; next.lastEvent = "hurt"; }
  }
  if (next.lives <= 0 || next.tick >= THEATER_SHOW_MAX_TICKS) next.status = "lost";
  return next;
}
/** Replay the actual bounded movement trace; UI outcome flags are never accepted. */
export function validateTheaterSpotlightAttempt(value: unknown, round: number, attempt: number): TheaterShowState | null {
  if (!value || typeof value !== "object") return null;
  const candidate = value as Partial<TheaterSpotlightAttempt>;
  if (candidate.version !== 2 || candidate.round !== round || candidate.attempt !== attempt
    || !Array.isArray(candidate.inputs) || candidate.inputs.length < 1 || candidate.inputs.length > THEATER_SHOW_MAX_TICKS) return null;
  let state = createTheaterShow(round, attempt);
  for (const input of candidate.inputs) {
    if (state.status !== "running" || !input || typeof input.x !== "number" || typeof input.y !== "number"
      || !Number.isFinite(input.x) || !Number.isFinite(input.y) || Math.abs(input.x) > 1 || Math.abs(input.y) > 1 || typeof input.dash !== "boolean") return null;
    state = stepTheaterShow(state, input);
  }
  return state.status === "running" ? null : state;
}
