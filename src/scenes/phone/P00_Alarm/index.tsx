import { useEffect, useRef, useState } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { playSfx, type SfxHandle } from "../../../modules/Sfx";
import { preloadVo } from "../../../modules/VoicePlayer";

/** 闹钟响铃时的方波警报音 */
function useAlarmTone(active: boolean) {
  const audioRef = useRef<AudioContext | null>(null);
  const oscillatorRef = useRef<OscillatorNode | null>(null);

  useEffect(() => {
    if (!active || typeof window === "undefined") {
      return undefined;
    }

    const AudioCtor = window.AudioContext;
    if (!AudioCtor) {
      return undefined;
    }

    const audio = new AudioCtor();
    const oscillator = audio.createOscillator();
    const gain = audio.createGain();
    oscillator.type = "square";
    oscillator.frequency.value = 880;
    gain.gain.value = 0.035;
    oscillator.connect(gain);
    gain.connect(audio.destination);
    oscillator.start();

    const wobble = window.setInterval(() => {
      oscillator.frequency.value = oscillator.frequency.value === 880 ? 660 : 880;
    }, 260);

    audioRef.current = audio;
    oscillatorRef.current = oscillator;

    return () => {
      window.clearInterval(wobble);
      oscillatorRef.current?.stop();
      oscillatorRef.current?.disconnect();
      audioRef.current?.close();
      oscillatorRef.current = null;
      audioRef.current = null;
    };
  }, [active]);
}

/** P00 闹钟主界面：振动 + 音效，点击“关闭”进入下一场景 */
export function AlarmScene({ router, events }: SceneComponentProps) {
  const [ringing, setRinging] = useState(false);
  const vibrateLoop = useRef<SfxHandle | null>(null);
  useAlarmTone(ringing);

  function startAlarm() {
    setRinging(true);
    window.navigator.vibrate?.([160, 80, 160, 80, 240]);
    vibrateLoop.current = playSfx("05_", { loop: true, volume: 0.8 });
    preloadVo();
    events.emit("alarm_started");
  }

  function closeAlarm() {
    setRinging(false);
    window.navigator.vibrate?.(0);
    vibrateLoop.current?.stop();
    vibrateLoop.current = null;
    playSfx("01_");
    events.emit("alarm_closed");
    router.goTo("desktop");
  }

  return (
    <section className={`alarm-scene ${ringing ? "is-ringing" : ""}`}>
      <div className="alarm-bell" aria-hidden="true">
        <i className="bell-body" />
        <i className="bell-wave w1" />
        <i className="bell-wave w2" />
      </div>
      <div className="alarm-face">
        <p className="alarm-label px-chip">早八闹钟</p>
        <h1>07:55</h1>
        <p className="alarm-sub">学在浙大签到还剩 5 分钟</p>
      </div>
      <div className="alarm-actions">
        {!ringing ? (
          <button type="button" className="px-btn primary big" onClick={startAlarm}>
            开始游戏
          </button>
        ) : (
          <button type="button" className="px-btn danger big" onClick={closeAlarm}>
            关闭
          </button>
        )}
      </div>
    </section>
  );
}
