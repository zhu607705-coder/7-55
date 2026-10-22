import { useEffect, useRef, useState } from "react";
import dockUrl from "../../../assets/ui/home_charging_dock.png";
import { canReturnToHomeDesk } from "../../../core/PhoneChargingStation";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import { kit } from "../../../modules/GameKit";
import type { HomeDeskChargingReceipt } from "../../../modules/PhoneBatteryController";
import "../../../styles/scenes/early-desk-charging.css";

/** A small C1 navigation affordance, not an alternate chapter/world entrance. */
export function PutPhoneOnDesk({ state, router }: SceneComponentProps) {
  if (!canReturnToHomeDesk(state)) return null;
  return <PhoneNavButton kind="close" className="early-desk-put-down" data-testid="PutPhoneOnDesk"
    title="放下手机，回到桌面" label="放下手机，回到桌面"
    onClick={() => { if (kit.battery.prepareHomeDeskReturn(state.currentScene)) router.goTo("desktop"); }}
    glyph={<svg width="23" height="25" viewBox="0 0 23 25" aria-hidden="true"><rect x="2" y="1" width="12" height="21" rx="2" fill="none" stroke="currentColor" strokeWidth="2" /><path d="M18 13v9m-4-4 4 4 4-4M6 18h4" fill="none" stroke="currentColor" strokeWidth="2" /></svg>} />;
}

/** Art, contact hotspot, phone pickup and transient charging status are separate layers. */
export function EarlyDeskCharging({ state, router }: SceneComponentProps) {
  const receipt = useRef<HomeDeskChargingReceipt | null>(null);
  const frame = useRef<number | null>(null);
  const [progress, setProgress] = useState<number | null>(null);
  const [notice, setNotice] = useState("");
  function cancel() {
    if (frame.current !== null) cancelAnimationFrame(frame.current);
    frame.current = null;
    if (receipt.current) kit.battery.cancelHomeDeskCharging(receipt.current);
    receipt.current = null;
    setProgress(null);
  }
  useEffect(() => {
    const onBlur = () => { cancel(); setNotice(""); };
    const onVisibility = () => { if (document.hidden) onBlur(); };
    window.addEventListener("blur", onBlur);
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      window.removeEventListener("blur", onBlur);
      document.removeEventListener("visibilitychange", onVisibility);
      if (frame.current !== null) cancelAnimationFrame(frame.current);
      if (receipt.current) kit.battery.cancelHomeDeskCharging(receipt.current);
      receipt.current = null;
    };
  }, []);
  function tick() {
    const owned = receipt.current;
    if (!owned) return;
    const next = kit.battery.getHomeDeskChargingProgress(owned);
    if (next === null) { cancel(); setNotice(""); return; }
    setProgress(next);
    if (next < 1) { frame.current = requestAnimationFrame(tick); return; }
    const result = kit.battery.completeHomeDeskCharging(owned);
    cancel();
    setNotice(result === "charged" ? "充电完成" : "");
  }
  function connect() {
    const result = kit.battery.beginHomeDeskCharging();
    if (typeof result === "string") {
      setNotice(result === "already_sufficient" ? "电量充足" : "");
      return;
    }
    // Duplicate click/touch delivery reuses the original owner and timeline.
    if (receipt.current === result) return;
    receipt.current = result;
    setProgress(0); setNotice("");
    frame.current = requestAnimationFrame(tick);
  }
  if (!canReturnToHomeDesk(state) || state.currentScene !== "desktop") return null;
  return <div className="early-desk-objects" aria-label="桌面物件">
    <div className="early-desk-dock">
      <img className="early-desk-dock-art" src={dockUrl} alt="" aria-hidden="true" draggable={false} />
      <button type="button" className="early-desk-contact" data-testid="DeskDockContact" title="连接桌面充电座" aria-label="连接桌面充电座" onClick={connect} />
      <div className="early-desk-charge-status" data-testid="DeskChargingStatus" role="status" aria-live="polite">
        {progress !== null ? <><progress max={1} value={progress} aria-label="充电进度" /><span>连接{Math.floor(progress * 100)}% · 电量{state.phoneBattery.percent}%</span></> : <span>{notice || `${state.phoneBattery.percent}%`}</span>}
      </div>
    </div>
    {kit.battery.hasHomeDeskReturn() ? <button type="button" className="early-desk-phone" data-testid="DeskPhonePickup" title="拿起手机" aria-label="拿起手机"
      onClick={() => { cancel(); router.goTo(kit.battery.takePhoneFromDesk()); }}>
      <svg viewBox="0 0 52 78" aria-hidden="true"><rect x="4" y="2" width="44" height="73" rx="5" fill="#48464b" stroke="#29262d" strokeWidth="3" /><rect x="8" y="11" width="36" height="52" fill="#e4dbc8" /><path d="M20 7h12M22 69h8" stroke="#ddd4c0" strokeWidth="2" /><text x="26" y="39" textAnchor="middle" fontSize="10" fill="#48464b">07:55</text></svg>
    </button> : null}
    {progress !== null ? <button type="button" className="early-desk-unplug" data-testid="DeskUnplug" title="拔下充电线" aria-label="拔下充电线" onClick={() => { cancel(); setNotice("已断开"); }}>×</button> : null}
  </div>;
}
