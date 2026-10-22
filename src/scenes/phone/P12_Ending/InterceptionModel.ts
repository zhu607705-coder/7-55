import content from "../../../data/prologue-interception.content.json";

export const INTERCEPTION_STAGES = content.stages;
export const ARENA = { left: 18, right: 412, top: 270, bottom: 744 } as const;
export const WINDOW_BODY = { width: 164, height: 58, y: 658, speed: 440 } as const;
export type FailureReason = "not_moved" | "late" | "wrong_side" | "wrong_word" | "wrong_order";
export type InterceptionPhase = "clue" | "playing" | "hint" | "review" | "stage_complete" | "complete";
export interface WordBody {
  id: number; text: string; target: boolean; x: number; y: number;
  vx: number; vy: number; width: number; height: number; angle: number; contacted: boolean;
  demonstration?: boolean;
}
export interface InterceptionState {
  phase: InterceptionPhase; stage: number; completedStages: number; collected: string[];
  clueIndex: number; clueElapsedMs: number; elapsedMs: number; nextSpawnMs: number;
  serial: number; spawnIndex: number; targetIndex: number; words: WordBody[];
  boardX: number; boardVelocity: number; boardAngle: number; moved: boolean;
  failures: number; stageFailures: number; failure: FailureReason | null;
  lastWord: string; assist: boolean; ring: { x: number; y: number; remainingMs: number } | null;
  resumePhase: "clue" | "playing";
}
export interface MotionInput { direction?: number; targetX?: number | null }
export interface RectBody { x: number; y: number; width: number; height: number; angle: number }
export interface Contact { time: number; nx: number; ny: number }
export const clamp = (value: number, low: number, high: number) => Math.max(low, Math.min(high, value));

export function createInterceptionState(): InterceptionState {
  return {
    phase: "clue", stage: 0, completedStages: 0, collected: [], clueIndex: 0, clueElapsedMs: 0,
    elapsedMs: 0, nextSpawnMs: 0, serial: 0, spawnIndex: 0, targetIndex: 0, words: [],
    boardX: 215, boardVelocity: 0, boardAngle: 0, moved: false,
    failures: 0, stageFailures: 0, failure: null, lastWord: "", assist: false, ring: null, resumePhase: "clue"
  };
}

/** Continuous separating-axis test for two translating, oriented rectangles.
 * Angles are fixed for this 1/120s substep; both rendered bodies use these same angles. */
export function sweepRectangles(a: RectBody, dx: number, dy: number, b: RectBody, bx = 0, by = 0): Contact | null {
  const basis = (angle: number) => {
    const r = angle * Math.PI / 180;
    return [{ x: Math.cos(r), y: Math.sin(r) }, { x: -Math.sin(r), y: Math.cos(r) }];
  };
  const aa = basis(a.angle), bb = basis(b.angle);
  let enter = -Infinity, exit = Infinity, normal = { x: 0, y: -1 };
  for (const axis of [...aa, ...bb]) {
    const radius = (r: RectBody, axes: typeof aa) =>
      Math.abs(axis.x * axes[0].x + axis.y * axes[0].y) * r.width / 2 +
      Math.abs(axis.x * axes[1].x + axis.y * axes[1].y) * r.height / 2;
    const extent = radius(a, aa) + radius(b, bb);
    const separation = (a.x - b.x) * axis.x + (a.y - b.y) * axis.y;
    const speed = (dx - bx) * axis.x + (dy - by) * axis.y;
    if (Math.abs(speed) < 1e-10) { if (Math.abs(separation) > extent) return null; continue; }
    const t1 = (-extent - separation) / speed, t2 = (extent - separation) / speed;
    const near = Math.min(t1, t2), far = Math.max(t1, t2);
    if (near > enter) {
      enter = near;
      const sign = speed > 0 ? -1 : 1;
      normal = { x: axis.x * sign, y: axis.y * sign };
    }
    exit = Math.min(exit, far);
    if (enter > exit) return null;
  }
  if (exit < 0 || enter > 1) return null;
  return { time: Math.max(0, enter), nx: normal.x, ny: normal.y };
}

export function missingTargets(s: InterceptionState): string[] {
  return INTERCEPTION_STAGES[s.stage].targets.filter((text) => !s.collected.includes(text));
}
export function clueDuration(text: string): number { return Math.max(1800, text.length * 180); }
export function wordWidth(text: string): number { return Math.max(64, Array.from(text).length * 24 + 32); }

function fail(s: InterceptionState, reason: FailureReason, word: string): void {
  s.failure = reason; s.lastWord = word; s.failures += 1; s.stageFailures += 1;
  s.phase = "hint"; s.boardVelocity = 0; s.boardAngle = 0;
}

function spawn(s: InterceptionState): void {
  const stage = INTERCEPTION_STAGES[s.stage];
  const missing = missingTargets(s);
  if (!missing.length) return;
  const target = s.spawnIndex % 2 === 0;
  let text = stage.distractors[Math.floor(s.spawnIndex / 2) % stage.distractors.length];
  if (target) {
    do { text = stage.targets[s.targetIndex++ % stage.targets.length]; } while (s.collected.includes(text));
  }
  const width = wordWidth(text);
  const half = width / 2;
  // Alternating edge lanes leave the original centered window visibly short of the first target.
  const targetFromLeft = Math.floor(s.spawnIndex / 2) % 2 === 0;
  const fromLeft = target ? targetFromLeft : !targetFromLeft;
  const demonstration = s.stage === 0 && s.spawnIndex === 1 && s.failures === 0;
  const x = demonstration ? 215 : fromLeft ? ARENA.left + half + 4 : ARENA.right - half - 4;
  const travelSeconds = 3 + Array.from(text).length * 0.35;
  s.words.push({ id: ++s.serial, text, target, demonstration, x, y: 294, vx: demonstration ? 0 : fromLeft ? 4 : -4,
    vy: (WINDOW_BODY.y - WINDOW_BODY.height / 2 - 24 - 294) / travelSeconds,
    width, height: 48, angle: fromLeft ? -3 : 3, contacted: false });
  s.spawnIndex += 1;
}

function reflectSideWalls(word: WordBody): void {
  const extent = word.width / 2 * Math.cos(word.angle * Math.PI / 180) + word.height / 2 * Math.abs(Math.sin(word.angle * Math.PI / 180));
  if (word.x < ARENA.left + extent) { word.x = ARENA.left + extent; word.vx = Math.abs(word.vx); }
  if (word.x > ARENA.right - extent) { word.x = ARENA.right - extent; word.vx = -Math.abs(word.vx); }
}

/** Presentation-only model: it emits no controller intent and owns no persisted progress. */
export function stepInterception(s: InterceptionState, requestedMs: number, input: MotionInput = {}): void {
  let remaining = clamp(Number.isFinite(requestedMs) ? requestedMs : 0, 0, 10000);
  while (remaining > 0) {
    const ms = Math.min(remaining, 1000 / 120); remaining -= ms;
    if (["hint", "review", "complete"].includes(s.phase)) continue;
    const dt = ms / 1000;
    s.elapsedMs += ms;
    if (s.ring) { s.ring.remainingMs -= ms; if (s.ring.remainingMs <= 0) s.ring = null; }
    if (s.phase === "clue") {
      s.clueElapsedMs += ms;
      if (s.clueElapsedMs >= clueDuration(INTERCEPTION_STAGES[s.stage].fragments[s.clueIndex])) {
        s.clueElapsedMs = 0; s.clueIndex += 1;
        if (s.clueIndex >= INTERCEPTION_STAGES[s.stage].fragments.length) {
          s.clueIndex -= 1; s.phase = "playing"; s.nextSpawnMs = s.elapsedMs + 350;
        }
      }
    }
    if (s.phase === "stage_complete") {
      if (s.clueElapsedMs > 0) {
        s.clueElapsedMs -= ms;
        // Let the retained card visibly rebound during the short stage handoff.
        for (const word of s.words.filter((w) => w.contacted)) {
          word.x += word.vx * dt; word.y += word.vy * dt; reflectSideWalls(word);
        }
        continue;
      }
      s.completedStages += 1;
      if (s.completedStages === INTERCEPTION_STAGES.length) { s.phase = "complete"; continue; }
      s.stage += 1; s.collected = []; s.stageFailures = 0; s.failure = null; s.clueIndex = 0;
      s.clueElapsedMs = 0; s.phase = "clue"; s.spawnIndex = 0; s.targetIndex = 0; s.words = [];
      continue;
    }
    const oldX = s.boardX;
    const direction = clamp(Number.isFinite(input.direction) ? input.direction! : 0, -1, 1);
    const desired = direction ? s.boardX + direction * WINDOW_BODY.speed * dt : Number.isFinite(input.targetX) ? input.targetX! : s.boardX;
    // Whole rotated window stays in the authored arena at either ±6 degree extreme.
    const extent = WINDOW_BODY.width / 2 * Math.cos(Math.PI / 30) + WINDOW_BODY.height / 2 * Math.sin(Math.PI / 30);
    s.boardX = clamp(s.boardX + clamp(desired - s.boardX, -WINDOW_BODY.speed * dt, WINDOW_BODY.speed * dt), ARENA.left + extent, ARENA.right - extent);
    s.boardVelocity = (s.boardX - oldX) / dt;
    s.boardAngle = s.boardVelocity / WINDOW_BODY.speed * 6;
    if (Math.abs(s.boardX - oldX) > 0.001) s.moved = true;
    if (s.phase !== "playing") continue;
    if (s.elapsedMs >= s.nextSpawnMs && s.words.filter((w) => !w.contacted).length < 2 && s.words.length < 2) {
      spawn(s);
      // The first passive scrape must occur before the untouched target exits.
      s.nextSpawnMs = s.elapsedMs + (s.stage === 0 && s.spawnIndex === 1 && s.failures === 0 ? 1000 : 1900);
    }
    for (const word of s.words) {
      const dx = word.vx * dt, dy = word.vy * dt;
      const hit = !word.contacted ? sweepRectangles(word, dx, dy,
        { x: oldX, y: WINDOW_BODY.y, width: WINDOW_BODY.width, height: WINDOW_BODY.height, angle: s.boardAngle }, s.boardX - oldX) : null;
      if (hit) {
        word.x += dx * hit.time; word.y += dy * hit.time; word.contacted = true;
        const relativeX = word.vx - s.boardVelocity;
        const dot = relativeX * hit.nx + word.vy * hit.ny;
        word.vx = relativeX - 2 * dot * hit.nx + s.boardVelocity;
        word.vy -= 2 * dot * hit.ny;
        // Render the reflected remainder too; there is no terminal-X hit check.
        word.x += word.vx * dt * (1 - hit.time); word.y += word.vy * dt * (1 - hit.time);
        s.ring = { x: word.x - hit.nx * word.width / 2, y: word.y - hit.ny * word.height / 2, remainingMs: 300 };
        if (!word.target) {
          // The untouched original window passively demonstrates a real bounce once.
          // This grants no target and never gates a valid target contact on movement.
          if (word.demonstration && !s.moved) continue;
          fail(s, "wrong_word", word.text); break;
        }
        const missing = missingTargets(s);
        if (INTERCEPTION_STAGES[s.stage].ordered && word.text !== missing[0]) { fail(s, "wrong_order", word.text); break; }
        if (!s.collected.includes(word.text)) s.collected.push(word.text);
        s.lastWord = word.text;
        if (!missingTargets(s).length) { s.phase = "stage_complete"; s.clueElapsedMs = 650; break; }
      } else { word.x += dx; word.y += dy; }
      reflectSideWalls(word);
      if (!word.contacted && word.target && word.y - word.height / 2 > ARENA.bottom) {
        fail(s, !s.moved ? "not_moved" : Math.abs(s.boardX - word.x) > WINDOW_BODY.width / 2 + word.width / 2 ? "wrong_side" : "late", word.text);
        break;
      }
    }
    s.words = s.words.filter((word) => word.y + word.height / 2 >= ARENA.top && word.y - word.height / 2 <= ARENA.bottom + 60);
  }
}

export function continueInterception(s: InterceptionState): void {
  if (s.phase !== "hint") return;
  s.phase = "playing"; s.words = []; s.nextSpawnMs = s.elapsedMs + 700; s.spawnIndex = 0; s.targetIndex = 0;
  s.boardVelocity = 0; s.boardAngle = 0; s.ring = null; s.failure = null;
}
export function toggleClueReview(s: InterceptionState): void {
  if (s.phase === "review") { s.phase = s.resumePhase; return; }
  if (s.phase !== "playing" && s.phase !== "clue") return;
  s.resumePhase = s.phase; s.phase = "review"; s.boardVelocity = 0; s.boardAngle = 0;
}
export function failureHint(s: InterceptionState): string {
  const reason: Record<FailureReason, string> = {
    not_moved: "窗口还在原处，那个字已经走了。", late: "窗口到得晚了，目标已经从下方离开。",
    wrong_side: "窗口停在另一侧，目标从旁边离开了。", wrong_word: `“${s.lastWord}”不是这段话要留下的字。`,
    wrong_order: `“${s.lastWord}”来早了，原句的先后还没接上。`
  };
  const first = reason[s.failure ?? "late"];
  if (s.stageFailures < 2) return first;
  const relation = ["让“等”留在窗口上。", "留下的是两个坐标名，先后不限。", "按照原句，把三段依次接回。"][s.stage];
  if (s.stageFailures === 2) return `${first} ${relation} 试着拖动窗口的标题栏；也可用 A/D 或 ←/→。`;
  const missing = missingTargets(s);
  return `${first} ${relation} ${INTERCEPTION_STAGES[s.stage].ordered ? "下一段" : "仍缺"}：“${INTERCEPTION_STAGES[s.stage].ordered ? missing[0] : missing.join("、")}”。可开启落点助视，再继续这一段。`;
}
