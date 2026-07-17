import { useEffect, useRef } from "react";

/** 音乐播放时的简易 8bit 循环旋律（全局，跟随 ui.musicPlaying） */
export function useChiptune(playing: boolean) {
  const ctxRef = useRef<AudioContext | null>(null);
  const timerRef = useRef<number | null>(null);

  useEffect(() => {
    if (!playing || typeof window === "undefined" || !window.AudioContext) {
      return undefined;
    }

    const ctx = new window.AudioContext();
    ctxRef.current = ctx;
    const melody = [523, 587, 659, 587, 523, 440, 494, 523, 392, 440, 494, 523];
    let step = 0;

    const tick = () => {
      try {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "square";
        osc.frequency.value = melody[step % melody.length];
        gain.gain.setValueAtTime(0.03, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.22);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.24);
        step += 1;
      } catch {
        /* 音频失败不阻塞玩法 */
      }
    };

    tick();
    timerRef.current = window.setInterval(tick, 260);

    return () => {
      if (timerRef.current !== null) {
        window.clearInterval(timerRef.current);
        timerRef.current = null;
      }
      ctx.close().catch(() => undefined);
      ctxRef.current = null;
    };
  }, [playing]);
}
