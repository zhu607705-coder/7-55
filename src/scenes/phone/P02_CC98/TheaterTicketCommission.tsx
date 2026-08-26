import { useEffect, useState } from "react";
import type { NetworkMode, TheaterTicketCommissionPhase } from "../../../core/types";
import theaterContent from "../../../data/chapter3-theater.content.json";
import { kit } from "../../../modules/GameKit";
import { playSfx } from "../../../modules/Sfx";

interface TheaterTicketCommissionProps {
  phase: Exclude<TheaterTicketCommissionPhase, "locked">;
  networkMode: NetworkMode;
  claimedWave: 1 | 2 | null;
  ticketCodeRead: boolean;
}

const copy = theaterContent.cc98TicketCommission;
const SECOND_WAVE_COUNTDOWN_SECONDS = 5;

function getNetworkLabel(networkMode: NetworkMode) {
  if (networkMode === "cellular") return copy.networkCellular;
  if (networkMode === "campus_wifi") return copy.networkCampusWifi;
  return copy.networkOffline;
}

export function TheaterTicketCommission({
  phase,
  networkMode,
  claimedWave,
  ticketCodeRead
}: TheaterTicketCommissionProps) {
  const [secondWaveSeconds, setSecondWaveSeconds] = useState(() => (
    phase === "first_wave_failed" ? SECOND_WAVE_COUNTDOWN_SECONDS : 0
  ));
  const [releaseFeedback, setReleaseFeedback] = useState("");

  useEffect(() => {
    setReleaseFeedback("");
  }, [networkMode, phase]);

  useEffect(() => {
    if (phase !== "first_wave_failed") {
      setSecondWaveSeconds(0);
      return;
    }

    const endsAt = Date.now() + SECOND_WAVE_COUNTDOWN_SECONDS * 1000;
    setSecondWaveSeconds(SECOND_WAVE_COUNTDOWN_SECONDS);
    const interval = window.setInterval(() => {
      const remaining = Math.max(0, Math.ceil((endsAt - Date.now()) / 1000));
      setSecondWaveSeconds(remaining);
      if (remaining === 0) window.clearInterval(interval);
    }, 200);
    return () => window.clearInterval(interval);
  }, [phase]);

  const status = phase === "posted"
    ? copy.postedStatus
    : phase === "accepted"
      ? ticketCodeRead ? copy.acceptedStatus : copy.timeRequiredStatus
      : phase === "first_wave_failed"
        ? secondWaveSeconds > 0
          ? `${copy.secondWaveCountdownStatus}${secondWaveSeconds} 秒`
          : networkMode === "cellular" ? copy.cellularReadyStatus : copy.firstWaveStatus
        : claimedWave === 1 ? copy.deliveredFirstWaveStatus : copy.deliveredStatus;

  function acceptCommission() {
    if (!kit.theater.acceptCc98TicketCommission()) {
      playSfx("04_", { volume: 0.55 });
      kit.flags.toast("这条委托当前无法接取。", "system");
      return;
    }
    playSfx("07_", { volume: 0.65 });
    kit.flags.toast("学生剧现场帮抢委托已接取。", "task");
  }

  function openControlCenter() {
    playSfx("02_", { volume: 0.55 });
    kit.flags.setUi("controlCenterOpen", true);
  }

  function attemptTicketRelease() {
    const result = kit.theater.attemptCc98TicketRelease();
    if (result === "first_wave_slow") {
      playSfx("04_", { volume: 0.65 });
      setReleaseFeedback(copy.firstWaveStatus);
      kit.flags.toast("第一波结束：网速过慢。请切换到移动数据。", "system");
      return;
    }
    if (result === "cellular_required") {
      playSfx("04_", { volume: 0.55 });
      setReleaseFeedback(copy.cellularRequiredStatus);
      kit.flags.toast("第二波要求使用移动数据。", "system");
      return;
    }
    if (result === "won_first_wave") {
      playSfx("07_", { volume: 0.72 });
      setReleaseFeedback(copy.firstWaveCellularComment);
      kit.flags.toast(copy.firstWaveCellularComment, "task");
      return;
    }
    if (result === "won_second_wave") {
      playSfx("07_", { volume: 0.72 });
      setReleaseFeedback(copy.secondWaveSuccessStatus);
      kit.flags.toast("第二波抢票成功，取票码已生成。", "task");
      return;
    }
    if (result === "already_won") {
      setReleaseFeedback(copy.pickupInstruction);
      return;
    }
    playSfx("04_", { volume: 0.5 });
    setReleaseFeedback(ticketCodeRead ? "当前放票尚未开放。" : copy.timeRequiredStatus);
  }

  const firstWaveFinished = phase === "first_wave_failed" || phase === "delivered";
  const secondWaveReady = phase === "first_wave_failed"
    && secondWaveSeconds === 0
    && networkMode === "cellular";
  const networkLabel = getNetworkLabel(networkMode);

  return (
    <section className={`cc98-ticket-commission phase-${phase}`} aria-label="学生剧手机帮抢委托">
      <header>
        <span>{copy.phonePortalLabel}</span>
        <strong>
          {phase === "posted"
            ? "待接"
            : phase === "accepted"
              ? ticketCodeRead ? "第一波开放" : "待核对时间"
              : phase === "first_wave_failed"
                ? secondWaveReady ? "第二波开放" : "第二波等待"
                : claimedWave === 1 ? "第一波已中" : "第二波已中"}
        </strong>
      </header>

      <div className="cc98-ticket-commission-steps" aria-label="委托进度">
        <span className={phase !== "posted" ? "is-done" : "is-current"}>1 接单</span>
        <span className={ticketCodeRead ? "is-done" : phase !== "posted" ? "is-current" : ""}>2 核对 08:32</span>
        <span className={phase === "accepted" && ticketCodeRead ? "is-current" : firstWaveFinished ? "is-done" : ""}>3 第一波</span>
        <span className={phase === "first_wave_failed" ? "is-current" : phase === "delivered" ? "is-done" : ""}>
          {phase === "delivered" && claimedWave === 1 ? "4 已抢到" : "4 第二波"}
        </span>
      </div>

      <div className={`cc98-ticket-network is-${networkMode}`} aria-label={`当前网络：${networkLabel}`}>
        <span>当前网络</span>
        <strong>{networkLabel}</strong>
      </div>

      <p className="cc98-ticket-status" aria-live="polite">{releaseFeedback || status}</p>

      {phase === "posted" ? (
        <button type="button" className="cc98-ticket-primary" onClick={acceptCommission}>{copy.acceptLabel}</button>
      ) : null}

      {phase === "accepted" ? (
        <div className="cc98-ticket-release-actions">
          <div className="cc98-ticket-release-time" aria-label="第一波放票时间">
            <span>第一波放票</span>
            <strong>{ticketCodeRead ? "08:32" : "--:--"}</strong>
          </div>
          <button
            type="button"
            className="cc98-ticket-primary"
            onClick={attemptTicketRelease}
            disabled={!ticketCodeRead}
          >
            {ticketCodeRead ? copy.firstWaveLabel : copy.confirmTimeLabel}
          </button>
          <button type="button" className="cc98-ticket-secondary" onClick={openControlCenter}>
            {copy.controlCenterLabel}
          </button>
        </div>
      ) : null}

      {phase === "first_wave_failed" ? (
        <div className="cc98-ticket-release-actions">
          <div className={`cc98-ticket-countdown ${secondWaveSeconds === 0 ? "is-ready" : ""}`} aria-live="polite">
            <span>{secondWaveSeconds > 0 ? copy.countdownLabel : copy.secondWaveOpenLabel}</span>
            <strong>{secondWaveSeconds > 0 ? secondWaveSeconds : "08:32"}</strong>
          </div>
          <button
            type="button"
            className="cc98-ticket-primary"
            onClick={attemptTicketRelease}
            disabled={!secondWaveReady}
          >
            {networkMode !== "cellular"
              ? copy.cellularRequiredLabel
              : secondWaveSeconds > 0 ? `${secondWaveSeconds} 秒后开放` : copy.secondWaveLabel}
          </button>
          <button type="button" className="cc98-ticket-secondary" onClick={openControlCenter}>
            {copy.controlCenterLabel}
          </button>
        </div>
      ) : null}

      {phase === "delivered" ? (
        <div className="cc98-ticket-receipt" aria-label="抢票成功回执">
          <span>{copy.pickupCodeLabel}</span>
          <strong>0832</strong>
          <p>{copy.pickupInstruction}</p>
        </div>
      ) : null}
    </section>
  );
}
