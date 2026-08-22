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

  function focusByDelta(index: number, delta: number): void {
    const count = CHAPTER_FOUR_LIGHT_GRID.zones.length;
    buttonRefs.current[(index + delta + count) % count]?.focus();
  }

  return (
    <div
      className="chapter4-power-panel-overlay"
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

        <div className="chapter4-power-panel__grid" role="group" aria-label="五个供电区域">
          {CHAPTER_FOUR_LIGHT_GRID.zones.map((zone, index) => {
            const on = (mask & (1 << zone.bit)) !== 0;
            return (
              <button
                key={zone.id}
                ref={(node) => { buttonRefs.current[index] = node; }}
                type="button"
                className={on ? "is-on" : "is-off"}
                aria-pressed={on}
                aria-label={`${zone.label}当前${on ? "亮" : "暗"}`}
                disabled={pending || locked}
                onClick={() => onToggle(zone.id)}
                onKeyDown={(event) => {
                  if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
                    event.preventDefault();
                    focusByDelta(index, -1);
                  } else if (event.key === "ArrowRight" || event.key === "ArrowDown") {
                    event.preventDefault();
                    focusByDelta(index, 1);
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
              : "每次操作会同时改变相邻区域。")}
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
