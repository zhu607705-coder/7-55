import type { GameState } from "../core/types";
import { formatClockSeconds } from "../core/ClockTime";
import { kit } from "../modules/GameKit";

interface StatusBarProps {
  state: GameState;
}

/**
 * 全局统一状态栏。第四章从 ChapterFourState 只读时间：首次拉旧钟前显示冻结的
 * 07:55:23 且标记为不可信，拉钟后与世界时间共用同一个 timeState。其他章节继续显示
 * 既有的 07:55。
 */
export function StatusBar({ state }: StatusBarProps) {
  const network = state.networkMode;
  const batteryPercent = state.phoneBattery.percent;
  const batteryTone = batteryPercent <= 5 ? "is-critical" : batteryPercent <= 20 ? "is-low" : "is-normal";
  const chapterFourActive = state.chapterThreeInterlude.completed
    && (state.chapter4.prologueSeen
      || state.chapter4.completed
      || state.rpgScene === "duan_yongping_temporal_maze");
  const clock = formatClockSeconds(
    chapterFourActive ? state.chapter4.phoneStatusTimeSeconds : 28_500
  );
  const timeText = chapterFourActive
    ? `${clock.hh}:${clock.mm}:${clock.ss}`
    : `${clock.hh}:${clock.mm}`;
  const timeTrusted = !chapterFourActive || state.chapter4.phoneStatusTimeTrusted;

  return (
    <header className="status-bar-global" aria-label="状态栏">
      <span
        className="sb-time"
        data-time-trusted={timeTrusted ? "true" : "false"}
        title={timeTrusted ? undefined : "状态时间已冻结，等待旧钟成为时间来源"}
      >
        {timeText}
        {!timeTrusted ? (
          <span className="sb-time-untrusted" role="status" aria-label="时间不可信">
            {" "}不可信
          </span>
        ) : null}
      </span>
      <button
        type="button"
        className={`sb-right ${batteryTone} ${state.phoneBattery.lowPowerMode ? "is-saving" : ""}`}
        aria-label={`打开控制中心，当前电量 ${batteryPercent}%${state.phoneBattery.lowPowerMode ? "，低电量模式已开启" : ""}`}
        onClick={() => kit.flags.setUi("controlCenterOpen", true)}
      >
        {network === "campus_wifi" ? (
          <>
            <strong>ZJUWLAN</strong>
            <span className="sb-wifi" aria-hidden="true">
              <i />
              <i />
              <i />
            </span>
          </>
        ) : network === "cellular" ? (
          <>
            <strong>流量</strong>
            <span className="sb-bars" aria-hidden="true">
              <i />
              <i />
              <i />
              <i />
            </span>
            <em className="sb-5g">5G</em>
          </>
        ) : (
          <strong>无服务</strong>
        )}
        <span className="sb-batt-num">{batteryPercent}%</span>
        <span className="sb-battery" aria-hidden="true">
          <i style={{ width: `${batteryPercent}%` }} />
        </span>
      </button>
    </header>
  );
}
