import { useEffect, useMemo, useRef } from "react";
import powerPanelSheetUrl from "../../assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_power_panel_states_v01.png";
import type { ChapterFourLightZoneId } from "../../core/types";
import {
  CHAPTER_FOUR_LIGHT_GRID,
  isChapterFourLightGridSolved
} from "../../modules/ChapterFourLightGridModel";

interface ChapterFourPowerPanelGameProps {
  mask: number;
  locked: boolean;
  pending: boolean;
  feedback: string | null;
  onToggle: (zoneId: ChapterFourLightZoneId) => void;
  onLock: () => void;
  onClose: () => void;
}

interface PowerPanelZonePosition {
  column: number;
  row: number;
  x: number;
  y: number;
}

const POWER_PANEL_ZONE_ORDER = Object.freeze([
  "hall",
  "west_corridor",
  "bakery_back_area",
  "classroom_zone",
  "east_corridor"
] as const satisfies readonly ChapterFourLightZoneId[]);

const POWER_PANEL_ZONE_POSITIONS: Readonly<Record<
  ChapterFourLightZoneId,
  Readonly<PowerPanelZonePosition>
>> = Object.freeze({
  hall: Object.freeze({ column: 2, row: 1, x: 50, y: 13 }),
  west_corridor: Object.freeze({ column: 1, row: 2, x: 20, y: 41 }),
  east_corridor: Object.freeze({ column: 3, row: 2, x: 80, y: 41 }),
  bakery_back_area: Object.freeze({ column: 1, row: 3, x: 28, y: 84 }),
  classroom_zone: Object.freeze({ column: 3, row: 3, x: 72, y: 84 })
});

const POWER_PANEL_ZONE_BY_ID = new Map(
  CHAPTER_FOUR_LIGHT_GRID.zones.map((zone) => [zone.id, zone] as const)
);

const POWER_PANEL_CONNECTIONS = Object.freeze(
  CHAPTER_FOUR_LIGHT_GRID.zones.flatMap((zone) => (
    zone.adjacentZoneIds.flatMap((adjacentId) => {
      const adjacent = POWER_PANEL_ZONE_BY_ID.get(adjacentId);
      return adjacent && zone.bit < adjacent.bit
        ? [Object.freeze({ from: zone.id, to: adjacentId })]
        : [];
    })
  ))
);

type PowerGridDirection = "left" | "right" | "up" | "down";

export function ChapterFourPowerPanelGame({
  mask,
  locked,
  pending,
  feedback,
  onToggle,
  onLock,
  onClose
}: ChapterFourPowerPanelGameProps) {
  const buttonRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const lastAutoLockMaskRef = useRef<number | null>(null);
  const solved = useMemo(() => isChapterFourLightGridSolved(mask), [mask]);
  const frame = locked || solved
    ? "open_restored"
    : mask === CHAPTER_FOUR_LIGHT_GRID.initialMask
      ? "open_powered"
      : "open_partial";
  const canRetryLock = solved
    && !locked
    && !pending
    && lastAutoLockMaskRef.current === mask;

  useEffect(() => {
    if (locked || pending || !solved || lastAutoLockMaskRef.current === mask) return;
    lastAutoLockMaskRef.current = mask;
    onLock();
  }, [locked, mask, onLock, pending, solved]);

  useEffect(() => {
    if (!solved) lastAutoLockMaskRef.current = null;
  }, [solved]);

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => buttonRefs.current[0]?.focus());
    return () => window.cancelAnimationFrame(frame);
  }, []);

  function focusInDirection(index: number, direction: PowerGridDirection): void {
    const currentZoneId = POWER_PANEL_ZONE_ORDER[index];
    const current = POWER_PANEL_ZONE_POSITIONS[currentZoneId];
    const candidates = POWER_PANEL_ZONE_ORDER
      .map((zoneId, candidateIndex) => ({
        candidateIndex,
        position: POWER_PANEL_ZONE_POSITIONS[zoneId]
      }))
      .filter(({ position }) => {
        if (direction === "left") return position.column < current.column;
        if (direction === "right") return position.column > current.column;
        if (direction === "up") return position.row < current.row;
        return position.row > current.row;
      })
      .sort((a, b) => {
        const aColumnDistance = a.position.column - current.column;
        const aRowDistance = a.position.row - current.row;
        const bColumnDistance = b.position.column - current.column;
        const bRowDistance = b.position.row - current.row;
        const aDistanceSquared = aColumnDistance ** 2 + aRowDistance ** 2;
        const bDistanceSquared = bColumnDistance ** 2 + bRowDistance ** 2;
        return aDistanceSquared - bDistanceSquared || a.candidateIndex - b.candidateIndex;
      });
    buttonRefs.current[candidates[0]?.candidateIndex ?? index]?.focus();
  }

  return (
    <div
      className="rpg-overlay-layer chapter4-power-panel-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="chapter4-power-panel-title"
      data-mask={mask}
      data-locked={locked ? "true" : "false"}
      data-pending={pending ? "true" : "false"}
      onKeyDown={(event) => {
        if (event.key === "Escape" && !locked) {
          event.preventDefault();
          onClose();
        }
      }}
    >
      <section className="chapter4-power-panel">
        <div
          className={`chapter4-power-panel__frame is-${frame}`}
          style={{ backgroundImage: `url(${powerPanelSheetUrl})` }}
          aria-hidden="true"
        />
        <header>
          <p>五区配电箱</p>
          <h2 id="chapter4-power-panel-title">让必要路线亮起</h2>
        </header>

        <div className="chapter4-power-panel__grid" role="group" aria-label="五区配电线路拓扑">
          <svg
            className="chapter4-power-panel__connections"
            viewBox="0 0 100 100"
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            {POWER_PANEL_CONNECTIONS.map((connection) => {
              const from = POWER_PANEL_ZONE_POSITIONS[connection.from];
              const to = POWER_PANEL_ZONE_POSITIONS[connection.to];
              return (
                <line
                  key={`${connection.from}-${connection.to}`}
                  x1={from.x}
                  y1={from.y}
                  x2={to.x}
                  y2={to.y}
                />
              );
            })}
          </svg>
          {POWER_PANEL_ZONE_ORDER.map((zoneId, index) => {
            const zone = POWER_PANEL_ZONE_BY_ID.get(zoneId);
            if (!zone) return null;
            const on = (mask & (1 << zone.bit)) !== 0;
            const position = POWER_PANEL_ZONE_POSITIONS[zone.id];
            const adjacentLabels = zone.adjacentZoneIds
              .map((adjacentId) => POWER_PANEL_ZONE_BY_ID.get(adjacentId)?.label)
              .filter((label): label is string => Boolean(label))
              .join("、");
            return (
              <button
                key={zone.id}
                ref={(node) => { buttonRefs.current[index] = node; }}
                type="button"
                className={on ? "is-on" : "is-off"}
                data-zone-id={zone.id}
                style={{ left: `${position.x}%`, top: `${position.y}%` }}
                aria-pressed={on}
                aria-label={`${zone.label}当前${on ? "亮" : "暗"}，连接${adjacentLabels}`}
                disabled={pending || locked}
                onClick={() => onToggle(zone.id)}
                onKeyDown={(event) => {
                  if (event.key === "ArrowLeft") {
                    event.preventDefault();
                    focusInDirection(index, "left");
                  } else if (event.key === "ArrowRight") {
                    event.preventDefault();
                    focusInDirection(index, "right");
                  } else if (event.key === "ArrowUp") {
                    event.preventDefault();
                    focusInDirection(index, "up");
                  } else if (event.key === "ArrowDown") {
                    event.preventDefault();
                    focusInDirection(index, "down");
                  }
                }}
              >
                <span className="chapter4-power-panel__lamp" aria-hidden="true" />
                <span>{zone.label}</span>
                <small>{on ? "亮" : "暗"}</small>
              </button>
            );
          })}
        </div>

        <p className="chapter4-power-panel__status" role="status" aria-live="polite">
          {feedback ?? (pending
            ? "正在同步配电状态……"
            : locked
              ? "配电结果已锁定。"
              : "按下一区，会切换它自身和连线直接相接的区域。")}
        </p>
        <p className="chapter4-power-panel__controls">
          方向键移动焦点 · Enter / Space 切换 · Esc 关闭
        </p>
        {canRetryLock ? (
          <button
            type="button"
            className="chapter4-power-panel__retry"
            aria-label="重试锁定配电结果"
            onClick={onLock}
          >
            重试锁定
          </button>
        ) : null}
        {!locked ? (
          <button
            type="button"
            className="chapter4-power-panel__close"
            onClick={onClose}
            disabled={pending}
          >
            关闭箱门
          </button>
        ) : null}
      </section>
    </div>
  );
}
