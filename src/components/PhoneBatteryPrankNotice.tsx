import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import type { EventBus } from "../core/EventBus";
import type { GameState } from "../core/types";
import { PhoneBatteryPrank, type BatteryPrankNotice } from "../modules/PhoneBatteryPrank";
import { playSfx, type SfxHandle } from "../modules/Sfx";
import { GameSubtitleFrame } from "./GameSubtitleFrame";

/** Owned by App so changing phone pages or RPG scenes cannot restart the clock. */
export function usePhoneBatteryPrank(events: EventBus, state: GameState) {
  const model = useRef(new PhoneBatteryPrank());
  const percent = useRef(state.phoneBattery.percent);
  percent.current = state.phoneBattery.percent;
  const [notice, setNotice] = useState<BatteryPrankNotice | null>(null);
  useEffect(() => {
    let timer: ReturnType<typeof setInterval> | undefined;
    let sound: SfxHandle | null = null;
    const stop = () => { clearInterval(timer); timer = undefined; sound?.stop(); sound = null; };
    const reset = () => { stop(); model.current.reset(); setNotice(null); };
    const unsubscribe = events.subscribe(event => {
      if (event.name === "phone_battery_recharged" || event.name === "developer_checkpoint_applied") { reset(); return; }
      if (event.name !== "phone_battery_reserve_used" || !model.current.consumeReserve(performance.now(), percent.current)) return;
      sound = playSfx("07_p14_chat_message_notification_ping.mp3", { volume: 0.8 });
      const tick = () => {
        if (percent.current > 1) { reset(); return; }
        const next = model.current.view(performance.now());
        setNotice(previous => previous?.kind === next?.kind && previous?.seconds === next?.seconds ? previous : next);
        if (!next) stop();
      };
      tick();
      timer = setInterval(tick, 100);
    });
    return () => { unsubscribe(); stop(); model.current.reset(); };
  }, [events]);
  useEffect(() => {
    if (state.phoneBattery.percent > 1) { model.current.reset(); setNotice(null); }
  }, [state.phoneBattery.percent]);
  return notice;
}

export function PhoneBatteryPrankNotice({notice, state, surface}: {
  notice: BatteryPrankNotice | null; state: GameState; surface: "phone" | "rpg";
}) {
  if (!notice) return null;
  const phone = surface === "phone" ? document.querySelector(".phone-frame") : null;
  return createPortal(
    <div className={`toast-layer subtitle-layer--${phone ? "phone" : "rpg"}`}
      data-battery-prank={notice.kind} role="alert"
      style={{ position: phone ? "absolute" : "fixed", top: phone ? 52 : 20, bottom: "auto", zIndex: 10000, pointerEvents: "none" }}>
      <GameSubtitleFrame state={state} tone="system" speaker="手机系统" className="px-toast"
        text={notice.kind === "warning" ? `${notice.text}\n剩余 ${notice.seconds} 秒` : notice.text} />
    </div>, phone ?? document.body
  );
}
