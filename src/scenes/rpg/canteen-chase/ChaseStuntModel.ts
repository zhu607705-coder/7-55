import { obstaclesBetween, type ChaseObstacle, type ChaseObstacleKind } from "./ChaseGeometry";
export type ChaseStuntAction = "left" | "right" | "jump" | "bell" | "item";
export type ChasePowerup = "tray" | "gust";
export interface ChaseStuntEvent {
    type: "jump" | "bell" | "collect" | "item" | "stunt" | "collision" | "finish";
    text: string;
    value?: number;
}
export const STUNT_RAMPS = [
    { id: "ramp-canteen", distance: 76, lane: 0 }, { id: "ramp-avenue", distance: 245, lane: 2 },
    { id: "ramp-construction", distance: 434, lane: 0 }, { id: "ramp-theater", distance: 610, lane: 2 }
] as const;
export const STUNT_PICKUPS: ReadonlyArray<{
    id: string;
    distance: number;
    lane: number;
    kind: ChasePowerup;
}> = [
    { id: "tray-1", distance: 26, lane: 1, kind: "tray" }, { id: "gust-1", distance: 151, lane: 0, kind: "gust" },
    { id: "tray-2", distance: 330, lane: 2, kind: "tray" }, { id: "gust-2", distance: 490, lane: 1, kind: "gust" }, { id: "tray-3", distance: 680, lane: 0, kind: "tray" }
];
const hurdles: ChaseObstacle[] = [96, 274, 454, 630].flatMap((distance, i) => [0, 1, 2].map(lane => ({ id: `stunt-hurdle-${i}-${lane}`, distance, lane, kind: "barrier", crossingSide: lane === 0 ? -1 : 1 })));
export function stuntObstaclesBetween(start: number, end: number): ChaseObstacle[] { return [...obstaclesBetween(start, end), ...hurdles.filter(o => o.distance >= start && o.distance <= end)].sort((a, b) => a.distance - b.distance); }
export function visibleStuntObstacles(distance: number): ChaseObstacle[] { return stuntObstaclesBetween(distance + .01, distance + 96).sort((a, b) => b.distance - a.distance); }
const clamp = (v: number, min: number, max: number) => Math.max(min, Math.min(max, v));
const HEIGHTS: Record<ChaseObstacleKind, number> = { cone: .65, barrier: .95, bicycle: 1.05, car: 1.7, crowd: 2.1, runner: 2.1 };
const SOFT = new Set<ChaseObstacleKind>(["cone", "bicycle", "crowd", "runner"]);
/** Runtime-only stunt/combat state. Only the chapter controller awards story completion. */
export class ChaseStuntModel {
    runState: "running" | "won" | "lost" = "running";
    started = false;
    paused = false;
    distance = 0;
    lane = 1;
    lives = 3;
    collisions = 0;
    invulnerableMs = 0;
    airHeight = 0;
    airVelocity = 0;
    charge = 0;
    bellCooldown = 0;
    bellPulse = 0;
    boostSeconds = 0;
    shield = false;
    powerup: ChasePowerup | null = null;
    combo = 0;
    bestCombo = 0;
    stunts = 0;
    score = 0;
    speed = 13.2;
    paperLane = 1;
    paperGap = 27;
    feedback = "起跳越过路障，响铃让纸障让路";
    feedbackSeconds = 0;
    elapsedSeconds = 0;
    readonly clearedObstacleIds = new Set<string>();
    readonly collectedPickupIds = new Set<string>();
    private readonly held = new Set<ChaseStuntAction>();
    private readonly crossed = new Set<string>();
    private readonly ramps = new Set<string>();
    private velocity = 0;
    private jumpCooldown = 0;
    private remainder = 0;
    private airborneTrick = false;
    constructor(private readonly onEvent: (event: ChaseStuntEvent) => void = () => { }) { }
    start(): void { if (!this.started && this.runState === "running") {
        this.started = true;
        this.held.clear();
    } }
    press(action: ChaseStuntAction): void {
        if (!this.started || this.paused || this.runState !== "running" || this.held.has(action))
            return;
        this.held.add(action);
        if (action === "bell")
            this.ringBell();
        if (action === "item")
            this.useItem();
    }
    release(action: ChaseStuntAction): void {
        if (!this.held.delete(action))
            return;
        if (action === "jump" && this.started && !this.paused && this.airHeight <= .001 && this.jumpCooldown <= 0) {
            this.airVelocity = 5.6 + this.charge * 2.4;
            this.jumpCooldown = .22;
            this.airborneTrick = false;
            this.emit("jump", this.charge > .45 ? "蓄力飞跃！" : "轻跳", this.charge);
            this.charge = 0;
        }
    }
    releaseControls(): void { this.held.clear(); this.charge = 0; this.velocity = 0; }
    setPaused(paused: boolean): void { this.paused = paused; if (paused)
        this.releaseControls(); }
    restart(): void {
        this.releaseControls();
        this.runState = "running";
        this.started = true;
        this.paused = false;
        this.distance = 0;
        this.lane = 1;
        this.lives = 3;
        this.collisions = 0;
        this.invulnerableMs = 0;
        this.airHeight = 0;
        this.airVelocity = 0;
        this.bellCooldown = 0;
        this.bellPulse = 0;
        this.boostSeconds = 0;
        this.shield = false;
        this.powerup = null;
        this.combo = 0;
        this.bestCombo = 0;
        this.stunts = 0;
        this.score = 0;
        this.speed = 13.2;
        this.paperLane = 1;
        this.paperGap = 27;
        this.elapsedSeconds = 0;
        this.feedbackSeconds = 0;
        this.clearedObstacleIds.clear();
        this.collectedPickupIds.clear();
        this.crossed.clear();
        this.ramps.clear();
        this.remainder = 0;
        this.jumpCooldown = 0;
    }
    update(milliseconds: number): void {
        if (!this.started || this.paused || this.runState !== "running" || !Number.isFinite(milliseconds))
            return;
        this.remainder += clamp(milliseconds, 0, 5000) / 1000;
        while (this.remainder >= 1 / 120 && this.runState === "running") {
            this.step(1 / 120);
            this.remainder -= 1 / 120;
        }
    }
    private step(dt: number): void {
        this.elapsedSeconds += dt;
        this.invulnerableMs = Math.max(0, this.invulnerableMs - dt * 1000);
        this.bellCooldown = Math.max(0, this.bellCooldown - dt);
        this.bellPulse = Math.max(0, this.bellPulse - dt * 1.8);
        this.jumpCooldown = Math.max(0, this.jumpCooldown - dt);
        this.feedbackSeconds = Math.max(0, this.feedbackSeconds - dt);
        this.boostSeconds = Math.max(0, this.boostSeconds - dt);
        const axis = Number(this.held.has("right")) - Number(this.held.has("left"));
        this.velocity += (axis * 1.9 - this.velocity) * Math.min(1, dt * 12);
        this.lane = clamp(this.lane + this.velocity * dt, 0, 2);
        if (this.airHeight <= 0 && this.held.has("jump"))
            this.charge = clamp(this.charge + dt * 1.5, 0, 1);
        if (this.airHeight > 0 || this.airVelocity > 0) {
            this.airVelocity -= 11.6 * dt;
            this.airHeight += this.airVelocity * dt;
            if (this.airHeight <= 0) {
                this.airHeight = 0;
                this.airVelocity = 0;
                if (this.airborneTrick)
                    this.reward("稳稳落地", 35);
            }
        }
        const targetSpeed = this.boostSeconds > 0 ? 21.5 : 13.2 + Math.min(2.4, this.combo * .25);
        this.speed += (targetSpeed - this.speed) * Math.min(1, dt * 4);
        const before = this.distance;
        this.distance = Math.min(755, this.distance + this.speed * dt);
        for (const marker of [188, 377, 566])
            if (before < marker && this.distance >= marker && this.lives < 3) {
                this.lives++;
                this.emit("item", "路边补给 · 恢复一次机会");
            }
        this.paperLane = clamp(1 + Math.sin(this.distance * .029) * .82 + Math.sin(this.elapsedSeconds * 1.7) * .1, 0, 2);
        this.paperGap = Math.max(6, 27 - this.distance / 755 * 16 - Math.min(4, this.combo * .5) - (this.boostSeconds > 0 ? 3 : 0));
        for (const pickup of STUNT_PICKUPS) {
            if (this.collectedPickupIds.has(pickup.id) || Math.abs(this.distance - pickup.distance) > 1.6 || Math.abs(this.lane - pickup.lane) > .35)
                continue;
            this.collectedPickupIds.add(pickup.id);
            if (!this.powerup) {
                this.powerup = pickup.kind;
                this.emit("collect", pickup.kind === "tray" ? "捡到餐盘护具 · E 使用" : "捡到顺风纸团 · E 使用");
            }
            else
                this.reward("顺手一捞", 20);
        }
        for (const ramp of STUNT_RAMPS) {
            if (this.ramps.has(ramp.id) || ramp.distance < before || ramp.distance > this.distance)
                continue;
            this.ramps.add(ramp.id);
            if (Math.abs(this.lane - ramp.lane) < .45) {
                this.airVelocity = 8.4;
                this.airHeight = Math.max(.08, this.airHeight);
                this.boostSeconds = Math.max(this.boostSeconds, 1.6);
                this.airborneTrick = true;
                this.stunts++;
                this.reward("飞跃捷径！", 100);
            }
        }
        for (const obstacle of stuntObstaclesBetween(before, this.distance)) {
            if (this.crossed.has(obstacle.id))
                continue;
            this.crossed.add(obstacle.id);
            if (this.clearedObstacleIds.has(obstacle.id))
                continue;
            const lateral = Math.abs(this.lane - obstacle.lane);
            if (lateral < .36) {
                if (this.airHeight >= HEIGHTS[obstacle.kind]) {
                    this.clearedObstacleIds.add(obstacle.id);
                    this.airborneTrick = true;
                    this.stunts++;
                    this.reward("飞越路障", 65);
                }
                else if (this.invulnerableMs <= 0) {
                    if (this.shield) {
                        this.shield = false;
                        this.invulnerableMs = 900;
                        this.emit("item", "餐盘弹开了这次碰撞");
                    }
                    else {
                        this.lives--;
                        this.collisions++;
                        this.combo = 0;
                        this.speed = 8;
                        this.invulnerableMs = 1050;
                        this.emit("collision", "撞到了！稳住，再追", this.lives);
                        if (this.lives <= 0) {
                            this.finish("lost");
                            return;
                        }
                    }
                }
            }
            else if (lateral < .68)
                this.reward("擦身而过", 18);
        }
        if (this.distance >= 755)
            this.finish("won");
    }
    private ringBell(): void {
        if (this.bellCooldown > 0) {
            this.feedback = "车铃还在回响";
            this.feedbackSeconds = .55;
            return;
        }
        this.bellCooldown = 2.6;
        this.bellPulse = 1;
        let count = 0;
        for (const o of stuntObstaclesBetween(this.distance, this.distance + 27))
            if (SOFT.has(o.kind) && Math.abs(o.lane - this.lane) < 1.15 && !this.clearedObstacleIds.has(o.id)) {
                this.clearedObstacleIds.add(o.id);
                count++;
            }
        this.emit("bell", count ? `叮——借过！震开 ${count} 处围堵` : "叮——纸条抖了一下", count);
        if (count)
            this.reward("车铃开路", count * 20);
    }
    private useItem(): void {
        if (!this.powerup) {
            this.feedback = "先捡起路上的道具";
            this.feedbackSeconds = 1;
            return;
        }
        if (this.powerup === "tray") {
            this.shield = true;
            this.emit("item", "餐盘护体 · 抵挡一次碰撞");
        }
        else {
            this.boostSeconds = 3.2;
            this.emit("item", "顺风起飞 · 加速追纸！");
        }
        this.powerup = null;
    }
    private reward(text: string, points: number): void { this.combo++; this.bestCombo = Math.max(this.combo, this.bestCombo); this.score += points; this.feedback = text; this.feedbackSeconds = 1.15; if (this.combo % 4 === 0)
        this.boostSeconds = Math.max(this.boostSeconds, 1.2); this.onEvent({ type: "stunt", text, value: points }); }
    private finish(state: "won" | "lost"): void { if (this.runState !== "running")
        return; this.runState = state; this.releaseControls(); if (state === "won")
        this.distance = 755; this.onEvent({ type: "finish", text: state === "won" ? "追上了！" : "再骑一次", value: this.distance }); }
    private emit(type: ChaseStuntEvent["type"], text: string, value?: number): void { this.feedback = text; this.feedbackSeconds = 1.3; this.onEvent({ type, text, value }); }
}
