import { useEffect, useMemo, useState } from "react";
import type { ChapterFourRealityMode } from "../../core/types";
import type { ChapterFourActionResult } from "../../modules/ChapterFourTemporalMazeController";
import { CHAPTER_FOUR_ELEVATOR } from "../../modules/ChapterFourElevatorModel";

const TIMELINE_START = CHAPTER_FOUR_ELEVATOR.timelineStartSeconds;
const TIMELINE_END = CHAPTER_FOUR_ELEVATOR.timelineEndSeconds;

interface ElevatorTrackSyncGameProps {
  mode: ChapterFourRealityMode;
  observed: boolean;
  initialStartSeconds: number | null;
  attempts: number;
  onSwitchToLight: () => void;
  onConfirm: (startSeconds: number) => ChapterFourActionResult;
  onClose: () => void;
}

function formatClock(totalSeconds: number): string {
  const normalized = ((totalSeconds % 86400) + 86400) % 86400;
  const hours = Math.floor(normalized / 3600);
  const minutes = Math.floor((normalized % 3600) / 60);
  const seconds = normalized % 60;
  return [hours, minutes, seconds].map((part) => String(part).padStart(2, "0")).join(":");
}

function toPercent(seconds: number): number {
  return ((seconds - TIMELINE_START) / (TIMELINE_END - TIMELINE_START)) * 100;
}

function segmentStyle(startSeconds: number, endSeconds: number) {
  return {
    left: `${toPercent(startSeconds)}%`,
    width: `${Math.max(1.5, toPercent(endSeconds) - toPercent(startSeconds))}%`
  };
}

export function ElevatorTrackSyncGame({
  mode,
  observed,
  initialStartSeconds,
  attempts,
  onSwitchToLight,
  onConfirm,
  onClose
}: ElevatorTrackSyncGameProps) {
  const [startSeconds, setStartSeconds] = useState(initialStartSeconds ?? CHAPTER_FOUR_ELEVATOR.selectableStartMaxSeconds - 1);
  const [result, setResult] = useState<ChapterFourActionResult | null>(null);
  const carEvents = useMemo(() => ({
    firstFloorOpenStart: startSeconds,
    firstFloorOpenEnd: startSeconds + CHAPTER_FOUR_ELEVATOR.firstFloorDoorOpenDurationSeconds,
    riseStart: startSeconds + CHAPTER_FOUR_ELEVATOR.riseOffsetSeconds,
    secondFloorOpen: startSeconds + CHAPTER_FOUR_ELEVATOR.secondFloorDoorOpenOffsetSeconds
  }), [startSeconds]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  const feedback = result === "accepted"
    ? "三条轨道已经对齐，主电梯开始重放这一段历史。"
    : result === "already_complete"
      ? "这一段历史已经对齐，可以返回主电梯厅。"
      : result === "misaligned"
        ? "开门区间没有完整覆盖黄色进入窗口。继续移动整段轿厢历史。"
        : result === "wrong_mode"
          ? "当前仍在深色观察。切回浅色操作后才能启动历史重放。"
          : result === "locked" || result === "inactive"
            ? "三条历史轨道尚未完成读取。"
            : "拖动下方时间游标，三条轨道会保持同一历史偏移。";

  return (
    <section
      className={`chapter4-elevator-sync is-${mode}`}
      role="dialog"
      aria-modal="true"
      aria-labelledby="elevator-sync-title"
      aria-describedby="elevator-sync-feedback"
      data-mode={mode}
      data-observed={observed ? "true" : "false"}
      data-result={result ?? "idle"}
    >
      <div className="chapter4-elevator-sync__scan" aria-hidden="true" />
      <header>
        <div>
          <span>HISTORY REPLAY / A-LIFT</span>
          <h2 id="elevator-sync-title">主电梯三轨同步</h2>
        </div>
        <button type="button" className="chapter4-elevator-sync__close" onClick={onClose} aria-label="关闭三轨同步面板">×</button>
      </header>

      <div className="chapter4-elevator-sync__summary">
        <span>当前模式</span>
        <strong>{mode === "dark" ? "深色观察" : "浅色操作"}</strong>
        <span>重放起点</span>
        <strong>{formatClock(startSeconds)}</strong>
        <span>尝试</span>
        <strong>{String(attempts).padStart(2, "0")}</strong>
      </div>

      <div className="chapter4-elevator-sync__timeline" aria-label="电梯历史三轨">
        <div className="chapter4-elevator-sync__ticks" aria-hidden="true">
          {[81807, 81811, 81815, 81819, 81823, 81827, 81831, 81835].map((tick) => (
            <span key={tick} style={{ left: `${toPercent(tick)}%` }}>{formatClock(tick).slice(-2)}</span>
          ))}
        </div>

        <div className="chapter4-elevator-track">
          <b>轿厢</b>
          <div className="chapter4-elevator-track__rail">
            <i className="is-floor-one" style={segmentStyle(carEvents.firstFloorOpenStart, carEvents.riseStart)}>1F</i>
            <i className="is-rising" style={segmentStyle(carEvents.riseStart, carEvents.secondFloorOpen)}>↑</i>
            <i className="is-floor-two" style={segmentStyle(carEvents.secondFloorOpen, carEvents.secondFloorOpen + 4)}>2F</i>
          </div>
        </div>

        <div className="chapter4-elevator-track">
          <b>门体</b>
          <div className="chapter4-elevator-track__rail">
            <i className="is-door-open" style={segmentStyle(carEvents.firstFloorOpenStart, carEvents.firstFloorOpenEnd)}>开门</i>
            <i className="is-door-closed" style={segmentStyle(carEvents.firstFloorOpenEnd, carEvents.secondFloorOpen)}>关闭</i>
            <i className="is-door-open" style={segmentStyle(carEvents.secondFloorOpen, carEvents.secondFloorOpen + 4)}>开门</i>
          </div>
        </div>

        <div className="chapter4-elevator-track">
          <b>进入</b>
          <div className="chapter4-elevator-track__rail">
            <i className="is-entry-window" style={segmentStyle(CHAPTER_FOUR_ELEVATOR.playerWindowStartSeconds, CHAPTER_FOUR_ELEVATOR.playerWindowEndSeconds)}>6 秒窗口</i>
          </div>
        </div>

        <div className="chapter4-elevator-sync__cursor" style={{ left: `${toPercent(startSeconds)}%` }} aria-hidden="true">
          <span>{formatClock(startSeconds)}</span>
        </div>
      </div>

      <label className="chapter4-elevator-sync__slider">
        <span>拖动轿厢历史</span>
        <input
          type="range"
          min={CHAPTER_FOUR_ELEVATOR.selectableStartMinSeconds}
          max={CHAPTER_FOUR_ELEVATOR.selectableStartMaxSeconds}
          step={1}
          value={startSeconds}
          disabled={mode !== "light" || !observed}
          onChange={(event) => {
            setStartSeconds(Number(event.currentTarget.value));
            setResult(null);
          }}
          aria-label="调整电梯历史重放起点"
        />
      </label>

      <p id="elevator-sync-feedback" className={`chapter4-elevator-sync__feedback${result ? ` is-${result}` : ""}`} role="status">{feedback}</p>

      <footer>
        {mode === "dark" ? (
          <button type="button" onClick={onSwitchToLight}>切到浅色操作</button>
        ) : (
          <button
            type="button"
            className="is-primary"
            disabled={!observed}
            onClick={() => setResult(onConfirm(startSeconds))}
          >
            启动历史重放
          </button>
        )}
        <small>目标：让一楼开门区间完整覆盖进入窗口</small>
      </footer>
    </section>
  );
}
