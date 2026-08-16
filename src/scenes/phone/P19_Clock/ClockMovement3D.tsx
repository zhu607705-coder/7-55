import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type KeyboardEvent as ReactKeyboardEvent,
  type PointerEvent as ReactPointerEvent,
} from "react";
import { useMediaQuery } from "../../../components/useMediaQuery";

export interface ClockMovement3DStrings {
  hourMovement: string;
  minuteMovement: string;
  lock: string;
  locked: string;
  explode: string;
  assemble: string;
  resetView: string;
  adjustHint: string;
  targetLabel: string;
}

export interface ClockMovement3DProps {
  hours: number;
  minutes: number;
  hourLocked: boolean;
  minuteLocked: boolean;
  onAdjust: (unit: "hour" | "minute", delta: number) => void;
  onLock: (unit: "hour" | "minute") => void;
  strings: ClockMovement3DStrings;
}

type MovementUnit = "hour" | "minute";

const TARGET_HOUR = 8;
const TARGET_MINUTE = 0;
const DRAG_STEP_PX = 24;
const MIN_ROT_X = 20;
const MAX_ROT_X = 65;
const MAX_ROT_Y = 45;
const DEFAULT_ROT_X = 52;
const DEFAULT_ROT_Y = -16;
const MIN_SPACING = 8;
const SPACING_RANGE = 36;
const SCENE_SCALE = 0.8;
const ORBIT_SPEED = 0.3;
const DIAL_TICKS = Array.from({ length: 12 }, (_, index) => index);
const PLATE_SCREW_ANGLES = [45, 135, 225, 315];

function pad2(value: number): string {
  return String(value).padStart(2, "0");
}

function polar(radius: number, angle: number): [number, number] {
  return [radius * Math.cos(angle), radius * Math.sin(angle)];
}

/** 程序化生成硬边多边形齿形,贴合像素终端质感,不使用位图。 */
function buildGearPath(teeth: number, outerRadius: number, rootRadius: number): string {
  const step = (Math.PI * 2) / teeth;
  const segments: string[] = [];
  for (let i = 0; i < teeth; i += 1) {
    const base = i * step;
    const anchors = [
      polar(rootRadius, base),
      polar(rootRadius, base + step * 0.3),
      polar(outerRadius, base + step * 0.4),
      polar(outerRadius, base + step * 0.6),
      polar(rootRadius, base + step * 0.7),
    ];
    segments.push(`${i === 0 ? "M" : "L"}${anchors.map(([x, y]) => `${x.toFixed(2)} ${y.toFixed(2)}`).join("L")}`);
  }
  return `${segments.join("")}Z`;
}

function buildSpokes(count: number, from: number, to: number): string {
  const parts: string[] = [];
  for (let i = 0; i < count; i += 1) {
    const angle = (i * Math.PI * 2) / count;
    const [x1, y1] = polar(from, angle);
    const [x2, y2] = polar(to, angle);
    parts.push(`M${x1.toFixed(2)} ${y1.toFixed(2)}L${x2.toFixed(2)} ${y2.toFixed(2)}`);
  }
  return parts.join("");
}

const BIG_GEAR_PATH = buildGearPath(40, 100, 88);
const BIG_GEAR_SPOKES = buildSpokes(5, 24, 81);
const MID_GEAR_PATH_A = buildGearPath(14, 34, 28);
const MID_GEAR_SPOKES_A = buildSpokes(4, 9, 24);
const MID_GEAR_PATH_B = buildGearPath(12, 29, 23.5);
const MID_GEAR_SPOKES_B = buildSpokes(4, 8, 20);

function clampRotation(x: number, y: number): { x: number; y: number } {
  return {
    x: Math.min(MAX_ROT_X, Math.max(MIN_ROT_X, x)),
    y: Math.max(-MAX_ROT_Y, Math.min(MAX_ROT_Y, y)),
  };
}

interface GearSvgProps {
  path: string;
  spokes: string;
  hubRadius: number;
  viewBox: string;
  svgClassName: string;
  hand?: { length: number; width: number; className: string };
}

function GearSvg({ path, spokes, hubRadius, viewBox, svgClassName, hand }: GearSvgProps) {
  return (
    <svg className={svgClassName} viewBox={viewBox} aria-hidden="true" focusable="false">
      <path className="clock-movement-3d-gear-teeth" d={path} />
      <path className="clock-movement-3d-gear-spokes" d={spokes} />
      <circle className="clock-movement-3d-gear-hub" cx={0} cy={0} r={hubRadius} />
      <circle className="clock-movement-3d-gear-axle" cx={0} cy={0} r={Math.max(3, hubRadius * 0.3)} />
      {hand ? (
        <g className={hand.className}>
          <line x1={0} y1={12} x2={0} y2={-hand.length} strokeWidth={hand.width} />
          <circle cx={0} cy={-hand.length} r={hand.width * 0.8} />
        </g>
      ) : null}
    </svg>
  );
}

interface UnitDragState {
  active: boolean;
  pointerId: number;
  lastY: number;
  acc: number;
}

/**
 * 第四章校时第 2 关「锁定双机芯」的 3D 爆炸图调节组件。
 * 纯 CSS 3D 变换 + SVG 齿轮;纯受控组件,读数与锁定状态由外部控制器持有,
 * 组件只通过 onAdjust / onLock 上报意图,内部 state 仅管理视角、爆炸程度与拖动累积。
 */
export function ClockMovement3D({ hours, minutes, hourLocked, minuteLocked, onAdjust, onLock, strings }: ClockMovement3DProps) {
  const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const [explode, setExplode] = useState(0.35);
  const [rotation, setRotation] = useState({ x: DEFAULT_ROT_X, y: DEFAULT_ROT_Y });
  const [orbiting, setOrbiting] = useState(false);

  const latest = useRef({ hourLocked, minuteLocked, onAdjust });
  latest.current = { hourLocked, minuteLocked, onAdjust };

  const orbit = useRef({ active: false, pointerId: -1, lastX: 0, lastY: 0, vx: 0, vy: 0, lastT: 0 });
  const inertiaFrame = useRef<number | null>(null);
  const gearDrag = useRef<Record<MovementUnit, UnitDragState>>({
    hour: { active: false, pointerId: -1, lastY: 0, acc: 0 },
    minute: { active: false, pointerId: -1, lastY: 0, acc: 0 },
  });
  const hourHitRef = useRef<HTMLDivElement | null>(null);
  const minuteHitRef = useRef<HTMLDivElement | null>(null);

  const stopInertia = useCallback(() => {
    if (inertiaFrame.current !== null) {
      window.cancelAnimationFrame(inertiaFrame.current);
      inertiaFrame.current = null;
    }
  }, []);

  useEffect(() => stopInertia, [stopInertia]);

  /* React 根事件中的 onWheel 是被动监听,无法阻止页面滚动,这里显式挂非被动 wheel。 */
  useEffect(() => {
    const targets: Array<[MovementUnit, HTMLDivElement | null]> = [
      ["hour", hourHitRef.current],
      ["minute", minuteHitRef.current],
    ];
    const cleanups: Array<() => void> = [];
    for (const [unit, node] of targets) {
      if (!node) continue;
      const handleWheel = (event: WheelEvent) => {
        const lockedNow = unit === "hour" ? latest.current.hourLocked : latest.current.minuteLocked;
        if (lockedNow) return;
        event.preventDefault();
        latest.current.onAdjust(unit, event.deltaY < 0 ? 1 : -1);
      };
      node.addEventListener("wheel", handleWheel, { passive: false });
      cleanups.push(() => node.removeEventListener("wheel", handleWheel));
    }
    return () => {
      for (const cleanup of cleanups) cleanup();
    };
  }, []);

  const beginInertia = useCallback(() => {
    if (reducedMotion) {
      setOrbiting(false);
      return;
    }
    let { vx, vy } = orbit.current;
    if (Math.hypot(vx, vy) < 0.06) {
      setOrbiting(false);
      return;
    }
    let prev = performance.now();
    const step = (now: number) => {
      const dt = Math.min(48, Math.max(1, now - prev));
      prev = now;
      setRotation((current) => clampRotation(current.x - vy * dt, current.y + vx * dt));
      const decay = Math.pow(0.92, dt / 16.7);
      vx *= decay;
      vy *= decay;
      if (Math.hypot(vx, vy) > 0.01) {
        inertiaFrame.current = window.requestAnimationFrame(step);
      } else {
        inertiaFrame.current = null;
        setOrbiting(false);
      }
    };
    inertiaFrame.current = window.requestAnimationFrame(step);
  }, [reducedMotion]);

  const handleViewportPointerDown = (event: ReactPointerEvent<HTMLDivElement>) => {
    stopInertia();
    orbit.current = {
      active: true,
      pointerId: event.pointerId,
      lastX: event.clientX,
      lastY: event.clientY,
      vx: 0,
      vy: 0,
      lastT: performance.now(),
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    setOrbiting(true);
  };

  const handleViewportPointerMove = (event: ReactPointerEvent<HTMLDivElement>) => {
    const current = orbit.current;
    if (!current.active || current.pointerId !== event.pointerId) return;
    const now = performance.now();
    const dt = Math.max(1, now - current.lastT);
    const dx = event.clientX - current.lastX;
    const dy = event.clientY - current.lastY;
    current.vx = current.vx * 0.65 + ((dx * ORBIT_SPEED) / dt) * 0.35;
    current.vy = current.vy * 0.65 + ((dy * ORBIT_SPEED) / dt) * 0.35;
    current.lastX = event.clientX;
    current.lastY = event.clientY;
    current.lastT = now;
    setRotation((previous) => clampRotation(previous.x - dy * ORBIT_SPEED, previous.y + dx * ORBIT_SPEED));
  };

  const handleViewportPointerEnd = (event: ReactPointerEvent<HTMLDivElement>) => {
    const current = orbit.current;
    if (!current.active || current.pointerId !== event.pointerId) return;
    current.active = false;
    beginInertia();
  };

  const resetView = () => {
    stopInertia();
    orbit.current.active = false;
    setOrbiting(false);
    setRotation({ x: DEFAULT_ROT_X, y: DEFAULT_ROT_Y });
  };

  const handleGearPointerDown = (unit: MovementUnit) => (event: ReactPointerEvent<HTMLDivElement>) => {
    const lockedNow = unit === "hour" ? latest.current.hourLocked : latest.current.minuteLocked;
    if (lockedNow) return;
    event.stopPropagation();
    const drag = gearDrag.current[unit];
    drag.active = true;
    drag.pointerId = event.pointerId;
    drag.lastY = event.clientY;
    drag.acc = 0;
    event.currentTarget.setPointerCapture(event.pointerId);
  };

  const handleGearPointerMove = (unit: MovementUnit) => (event: ReactPointerEvent<HTMLDivElement>) => {
    const drag = gearDrag.current[unit];
    if (!drag.active || drag.pointerId !== event.pointerId) return;
    event.stopPropagation();
    const dy = drag.lastY - event.clientY;
    drag.lastY = event.clientY;
    drag.acc += dy;
    while (drag.acc >= DRAG_STEP_PX) {
      drag.acc -= DRAG_STEP_PX;
      latest.current.onAdjust(unit, 1);
    }
    while (drag.acc <= -DRAG_STEP_PX) {
      drag.acc += DRAG_STEP_PX;
      latest.current.onAdjust(unit, -1);
    }
  };

  const handleGearPointerEnd = (unit: MovementUnit) => (event: ReactPointerEvent<HTMLDivElement>) => {
    const drag = gearDrag.current[unit];
    if (!drag.active || drag.pointerId !== event.pointerId) return;
    event.stopPropagation();
    drag.active = false;
  };

  const handleGearKeyDown = (unit: MovementUnit) => (event: ReactKeyboardEvent<HTMLDivElement>) => {
    const lockedNow = unit === "hour" ? latest.current.hourLocked : latest.current.minuteLocked;
    if (lockedNow) return;
    if (event.key === "ArrowUp") {
      event.preventDefault();
      latest.current.onAdjust(unit, 1);
    } else if (event.key === "ArrowDown") {
      event.preventDefault();
      latest.current.onAdjust(unit, -1);
    }
  };

  const spacing = MIN_SPACING + explode * SPACING_RANGE;
  const hourDegrees = hours * 30 + minutes * 0.5;
  const minuteDegrees = minutes * 6;
  const hourOnTarget = hours === TARGET_HOUR;
  const minuteOnTarget = minutes === TARGET_MINUTE;

  const renderGear = (unit: MovementUnit) => {
    const locked = unit === "hour" ? hourLocked : minuteLocked;
    const onTarget = unit === "hour" ? hourOnTarget : minuteOnTarget;
    const value = unit === "hour" ? hours : minutes;
    const label = unit === "hour" ? strings.hourMovement : strings.minuteMovement;
    const degrees = unit === "hour" ? hourDegrees : minuteDegrees;
    return (
      <div
        ref={unit === "hour" ? hourHitRef : minuteHitRef}
        className={`clock-movement-3d-gear clock-movement-3d-gear-${unit}${locked ? " is-locked" : ""}${onTarget ? " is-target" : ""}`}
        role="spinbutton"
        tabIndex={locked ? -1 : 0}
        aria-valuemin={0}
        aria-valuemax={unit === "hour" ? 23 : 59}
        aria-valuenow={value}
        aria-label={label}
        aria-disabled={locked || undefined}
        onPointerDown={handleGearPointerDown(unit)}
        onPointerMove={handleGearPointerMove(unit)}
        onPointerUp={handleGearPointerEnd(unit)}
        onPointerCancel={handleGearPointerEnd(unit)}
        onKeyDown={handleGearKeyDown(unit)}
        onContextMenu={(event) => event.preventDefault()}
      >
        <div className="clock-movement-3d-rotor" style={{ transform: `rotate(${degrees}deg)` }}>
          <GearSvg
            path={BIG_GEAR_PATH}
            spokes={BIG_GEAR_SPOKES}
            hubRadius={24}
            viewBox="-104 -104 208 208"
            svgClassName="clock-movement-3d-gear-svg"
            hand={
              unit === "hour"
                ? { length: 54, width: 8, className: "clock-movement-3d-hand clock-movement-3d-hand-hour" }
                : { length: 78, width: 5.5, className: "clock-movement-3d-hand clock-movement-3d-hand-minute" }
            }
          />
        </div>
        <i className="clock-movement-3d-lockpin" aria-hidden="true" />
      </div>
    );
  };

  const renderUnitPanel = (unit: MovementUnit) => {
    const locked = unit === "hour" ? hourLocked : minuteLocked;
    const onTarget = unit === "hour" ? hourOnTarget : minuteOnTarget;
    const value = unit === "hour" ? hours : minutes;
    const label = unit === "hour" ? strings.hourMovement : strings.minuteMovement;
    return (
      <section
        className={`clock-movement-3d-unit${locked ? " is-locked" : ""}${onTarget ? " is-target" : ""}`}
        aria-label={label}
      >
        <div className="clock-movement-3d-unit-head">
          <span>{label}</span>
          <small>{strings.targetLabel}</small>
        </div>
        <div className="clock-movement-3d-unit-main">
          <button
            type="button"
            className="clock-movement-3d-step"
            disabled={locked}
            aria-label={`${label} −`}
            onClick={() => onAdjust(unit, -1)}
          >
            −
          </button>
          <strong className="clock-movement-3d-readout">{pad2(value)}</strong>
          <button
            type="button"
            className="clock-movement-3d-step"
            disabled={locked}
            aria-label={`${label} +`}
            onClick={() => onAdjust(unit, 1)}
          >
            +
          </button>
        </div>
        <button type="button" className="clock-movement-3d-lock" disabled={locked} onClick={() => onLock(unit)}>
          {locked ? strings.locked : strings.lock}
        </button>
      </section>
    );
  };

  return (
    <div className="clock-movement-3d">
      <div
        className={`clock-movement-3d-viewport${orbiting ? " is-orbiting" : ""}`}
        onPointerDown={handleViewportPointerDown}
        onPointerMove={handleViewportPointerMove}
        onPointerUp={handleViewportPointerEnd}
        onPointerCancel={handleViewportPointerEnd}
        onLostPointerCapture={handleViewportPointerEnd}
        onContextMenu={(event) => event.preventDefault()}
      >
        <div className="clock-movement-3d-lens">
          <div
            className="clock-movement-3d-scene"
            style={{
              transform: `rotateX(${rotation.x}deg) rotateY(${rotation.y}deg) scale3d(${SCENE_SCALE}, ${SCENE_SCALE}, ${SCENE_SCALE})`,
            }}
          >
            <div className="clock-movement-3d-axis" style={{ height: Math.round(4 * spacing + 56) }} aria-hidden="true" />

            <div className="clock-movement-3d-layer" style={{ transform: `translateZ(${-2 * spacing}px)` }}>
              <div className="clock-movement-3d-plate">
                {PLATE_SCREW_ANGLES.map((angle) => (
                  <i
                    key={angle}
                    className="clock-movement-3d-screw"
                    style={{ transform: `translate(-50%, -50%) rotate(${angle}deg) translateY(-76px)` }}
                  />
                ))}
              </div>
            </div>

            <div className="clock-movement-3d-layer" style={{ transform: `translateZ(${-spacing}px)` }}>
              {renderGear("hour")}
            </div>

            <div className="clock-movement-3d-layer" style={{ transform: "translateZ(0px)" }}>
              <div className="clock-movement-3d-midgear clock-movement-3d-midgear-a" aria-hidden="true">
                <div className="clock-movement-3d-rotor" style={{ transform: `rotate(${-minuteDegrees * 2}deg)` }}>
                  <GearSvg
                    path={MID_GEAR_PATH_A}
                    spokes={MID_GEAR_SPOKES_A}
                    hubRadius={9}
                    viewBox="-38 -38 76 76"
                    svgClassName="clock-movement-3d-gear-svg clock-movement-3d-gear-svg-mid"
                  />
                </div>
              </div>
              <div className="clock-movement-3d-midgear clock-movement-3d-midgear-b" aria-hidden="true">
                <div className="clock-movement-3d-rotor" style={{ transform: `rotate(${-hourDegrees * 1.5}deg)` }}>
                  <GearSvg
                    path={MID_GEAR_PATH_B}
                    spokes={MID_GEAR_SPOKES_B}
                    hubRadius={8}
                    viewBox="-33 -33 66 66"
                    svgClassName="clock-movement-3d-gear-svg clock-movement-3d-gear-svg-mid"
                  />
                </div>
              </div>
            </div>

            <div className="clock-movement-3d-layer" style={{ transform: `translateZ(${spacing}px)` }}>
              {renderGear("minute")}
            </div>

            <div className="clock-movement-3d-layer" style={{ transform: `translateZ(${2 * spacing}px)` }}>
              <div className="clock-movement-3d-dial">
                {DIAL_TICKS.map((tick) => (
                  <i
                    key={tick}
                    className={`clock-movement-3d-tick${tick % 3 === 0 ? " is-major" : ""}${tick === TARGET_HOUR ? " is-target" : ""}`}
                    style={{ transform: `translate(-50%, -50%) rotate(${tick * 30}deg) translateY(-96px)` }}
                  />
                ))}
                <i
                  className="clock-movement-3d-target-marker"
                  style={{ transform: `translate(-50%, -50%) rotate(${TARGET_HOUR * 30}deg) translateY(-110px)` }}
                />
              </div>
            </div>
          </div>
        </div>

        <span
          className={`clock-movement-3d-chip clock-movement-3d-chip-hour${hourLocked ? " is-locked" : ""}${hourOnTarget ? " is-target" : ""}`}
        >
          {strings.hourMovement} {pad2(hours)}
        </span>
        <span
          className={`clock-movement-3d-chip clock-movement-3d-chip-minute${minuteLocked ? " is-locked" : ""}${minuteOnTarget ? " is-target" : ""}`}
        >
          {strings.minuteMovement} {pad2(minutes)}
        </span>
      </div>

      <div className="clock-movement-3d-toolbar">
        <button
          type="button"
          className="clock-movement-3d-view-btn"
          aria-pressed={explode <= 0.001}
          onClick={() => setExplode(0)}
        >
          {strings.assemble}
        </button>
        <input
          type="range"
          className="clock-movement-3d-explode-range"
          min={0}
          max={100}
          step={1}
          value={Math.round(explode * 100)}
          aria-label={`${strings.assemble} / ${strings.explode}`}
          onChange={(event) => setExplode(Number(event.target.value) / 100)}
        />
        <button
          type="button"
          className="clock-movement-3d-view-btn"
          aria-pressed={explode >= 0.999}
          onClick={() => setExplode(1)}
        >
          {strings.explode}
        </button>
        <button type="button" className="clock-movement-3d-view-btn clock-movement-3d-reset" onClick={resetView}>
          {strings.resetView}
        </button>
      </div>

      <div className="clock-movement-3d-units">
        {renderUnitPanel("hour")}
        {renderUnitPanel("minute")}
      </div>

      <p className="clock-movement-3d-hint">{strings.adjustHint}</p>
    </div>
  );
}
