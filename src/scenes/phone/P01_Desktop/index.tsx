import { useEffect, useState } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { playSfx } from "../../../modules/Sfx";
import { playVo } from "../../../modules/VoicePlayer";

/** P01 手机主屏幕 07:55：……再睡5分钟…… → 旁白 → 巨大字幕“起床蠢货！！！” */
export function WakeScene({ router, events }: SceneComponentProps) {
  const [warned, setWarned] = useState(false);

  // 底部旁白与进场同步
  useEffect(() => {
    const timer = window.setTimeout(() => playVo("wake_narration", { subtitle: false }), 400);
    return () => window.clearTimeout(timer);
  }, []);

  function sleepMore() {
    setWarned(true);
    events.emit("sleep_five_minutes");
    window.navigator.vibrate?.([90, 50, 90]);
    playSfx("06_");
    playVo("wake_flash", { subtitle: false });
  }

  function enterHome() {
    playSfx("01_");
    router.goTo("phone_home");
  }

  return (
    <section className="wake-scene">
      <header className="wake-status" aria-hidden="true">
        <strong>07:55</strong>
        <span>ZJUWLAN · 17%</span>
      </header>
      <div className="wake-center">
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
      </div>
      {!warned ? (
        <p className="bottom-narration game-subtitle-frame subtitle-tone-narrator is-line-entering">
          <small className="game-subtitle-speaker">旁白</small>
          <span>你没有5分钟了，但你很有勇气</span>
        </p>
      ) : null}
    </section>
  );
}
