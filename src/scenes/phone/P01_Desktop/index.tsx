import { useEffect, useState } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { playSfx } from "../../../modules/Sfx";
import { playVo } from "../../../modules/VoicePlayer";
import { kit } from "../../../modules/GameKit";
import { EarlyDeskCharging } from "./EarlyDeskCharging";
import { GameSubtitleContent } from "../../../components/GameSubtitleFrame";

/** P01 手机主屏幕 07:55：……再睡5分钟…… → 旁白 → 巨大字幕“起床蠢货！！！” */
export function WakeScene({ state, router, events }: SceneComponentProps) {
  const [warned, setWarned] = useState(false);
  const returningToDesk = kit.battery.hasHomeDeskReturn();

  // 底部旁白与进场同步
  useEffect(() => {
    if (returningToDesk) return;
    const timer = window.setTimeout(() => playVo("wake_narration", { subtitle: false }), 400);
    return () => window.clearTimeout(timer);
  }, [returningToDesk]);

  function sleepMore() {
    setWarned(true);
    events.emit("sleep_five_minutes");
    window.navigator.vibrate?.([90, 50, 90]);
    playSfx("06_");
    playVo("wake_flash", { subtitle: false });
  }

  function enterHome() {
    playSfx("01_");
    router.goTo(kit.battery.takePhoneFromDesk());
  }

  return (
    <section className="wake-scene">
      <header className="wake-status" aria-hidden="true">
        <strong>07:55</strong>
        <span>ZJUWLAN · {state.phoneBattery.percent}%</span>
      </header>
      {!returningToDesk ? <div className="wake-center">
        {!warned ? (
          <div className="sleep-choice">
            <p className="wake-me px-chip">（我）</p>
            <button type="button" className="px-btn paper big" onClick={sleepMore}>
              ……再睡5分钟……
            </button>
          </div>
        ) : (
          <>
            <h1 className="wake-flash">
              起床蠢货
              <span className="wake-flash-marks">！！！</span>
            </h1>
            <button type="button" className="px-btn primary big" onClick={enterHome}>
              进入手机主界面
            </button>
          </>
        )}
      </div> : null}
      <EarlyDeskCharging state={state} router={router} events={events} />
      {!warned && !returningToDesk ? (
        <p className="bottom-narration game-subtitle-frame subtitle-tone-narrator is-line-entering">
          <GameSubtitleContent speaker="旁白" text="你没有5分钟了，但你很有勇气" />
        </p>
      ) : null}
    </section>
  );
}
