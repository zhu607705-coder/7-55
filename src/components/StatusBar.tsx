import type { GameState } from "../core/types";
import { formatClockSeconds } from "../core/ClockTime";
import { kit } from "../modules/GameKit";

interface StatusBarProps {
  state: GameState;
}

/**
 * 全局统一状态栏：时间恒为 07:55，网络指示随 networkMode 变化，点击右侧打开控制中心。
 * 第四章（启真湖完成，与 FeatureAccess 的 chapterFourActive 同一事实来源）时间仍被
 * 冻结在 07:55；校时完成（clockCalibration.phase === "aligned"）后恢复显示当前
 * 校时结果的 hh:mm。
 */
export function StatusBar({ state }: StatusBarProps) {
  const network = state.networkMode;
  const chapterFourActive = state.qizhenLake.phase === "complete";
  const aligned = chapterFourActive && state.clockCalibration.phase === "aligned";
  const clock = formatClockSeconds(state.clockCalibration.displayedSeconds);
  const timeText = aligned ? `${clock.hh}:${clock.mm}` : "07:55";

  return (
    <header className="status-bar-global" aria-label="状态栏">
      <span className="sb-time">{timeText}</span>
      <button
        type="button"
        className="sb-right"
        aria-label="打开控制中心"
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
        <span className="sb-batt-num">17%</span>
        <span className="sb-battery" aria-hidden="true">
          <i />
        </span>
      </button>
    </header>
  );
}
