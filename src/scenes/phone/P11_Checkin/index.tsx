import { useEffect, useRef, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { playSfx, type SfxHandle } from "../../../modules/Sfx";

type FinalePhase = "none" | "stamp1" | "stamp2" | "geoerror" | "redflash" | "blackout";

const GEO_NOTIFICATION_MS = 1900;

/**
 * P11 校务签到（学在浙大）：4 位签到码输入 + 像素数字键盘。
 * 流量 → 提示请连接校园网；错码 → 报错；0798 → “签”“到”逐字跳出 → 红闪 → 黑屏序章演出。
 */
export function CheckinScene({ state, router, events }: SceneComponentProps) {
  const [code, setCode] = useState("");
  const [error, setError] = useState(false);
  const [entryPulse, setEntryPulse] = useState<{ id: number; digit: string; slot: number } | null>(null);
  const [finale, setFinale] = useState<FinalePhase>("none");
  const heartbeat = useRef<SfxHandle | null>(null);
  const entryPulseId = useRef(0);

  useEffect(() => {
    if (!entryPulse) {
      return undefined;
    }
    const timer = window.setTimeout(() => setEntryPulse(null), 540);
    return () => window.clearTimeout(timer);
  }, [entryPulse]);

  useEffect(() => {
    if (finale === "none") {
      return undefined;
    }
    const timers: number[] = [];
    if (finale === "stamp1") {
      heartbeat.current = playSfx("28_", { loop: true, volume: 0.7 });
      timers.push(window.setTimeout(() => setFinale("stamp2"), 750));
    }
    if (finale === "stamp2") {
      timers.push(window.setTimeout(() => setFinale("geoerror"), 900));
    }
    if (finale === "geoerror") {
      kit.flags.shake();
      events.emit("checkin_geo_error_presented", { longitude: null, latitude: null });
      timers.push(window.setTimeout(() => setFinale("redflash"), GEO_NOTIFICATION_MS));
    }
    if (finale === "redflash") {
      kit.flags.shake(true);
      timers.push(window.setTimeout(() => setFinale("blackout"), 1200));
    }
    if (finale === "blackout") {
      heartbeat.current?.stop();
      heartbeat.current = null;
      playSfx("29_");
      timers.push(window.setTimeout(() => router.goTo("ending"), 500));
    }
    return () => timers.forEach((t) => window.clearTimeout(t));
  }, [finale, router]);

  // 场景卸载时确保心跳停止
  useEffect(() => {
    return () => {
      heartbeat.current?.stop();
      heartbeat.current = null;
    };
  }, []);

  function pressDigit(d: string) {
    if (finale !== "none" || code.length >= 4) {
      return;
    }
    playSfx("25_");
    setError(false);
    entryPulseId.current += 1;
    setEntryPulse({ id: entryPulseId.current, digit: d, slot: Math.min(code.length, 3) });
    setCode((prev) => (prev.length >= 4 ? prev : prev + d));
  }

  function backspace() {
    playSfx("02_");
    setError(false);
    setCode((prev) => prev.slice(0, -1));
  }

  function submit() {
    if (code.length < 4 || finale !== "none") {
      return;
    }
    playSfx("27_");
    const result = kit.checkin.submit(code);
    if (result === "need_campus_wifi") {
      kit.flags.toast("请连接校园网。", "system");
      kit.flags.shake();
      return;
    }
    if (result === "wrong_code") {
      playSfx("26_");
      setError(true);
      setCode("");
      kit.flags.shake();
      kit.flags.toast("签到码错误。");
      return;
    }
    events.emit("checkin_stamped");
    setFinale("stamp1");
  }

  function collectAbsenceZero() {
    if (!state.flags.codeScattered || state.flags.cardZeroTaken) return;
    playSfx("11_");
    kit.digits.collectDigit(1, "0", "checkin");
    kit.flags.setFlag("cardZeroTaken", true);
    events.emit("checkin_absence_zero_taken");
    kit.flags.toast("获得第 1 位：0", "task");
  }

  const slots = [0, 1, 2, 3].map((i) => code[i] ?? "");

  function returnToZjuding() {
    kit.flags.setUi("zjudingPage", "learn");
    router.goTo("zjuding");
  }

  return (
    <section className="app-screen checkin-scene" aria-label="校务签到">
      <header className="checkin-header">
        <PhoneNavButton kind="back" className="wx-back" onClick={returnToZjuding} label="返回学在浙大" />
        <h1>学在浙大 · 课堂签到</h1>
      </header>

      <article className="checkin-course px-panel">
        <div className="course-line">
          <strong>高等数学（早八特供版）</strong>
          <span className="live-dot" aria-hidden="true" />
        </div>
        <p>快快老师 · 紫金港西1-201 · 08:00</p>
        <p className="calling">正在点名中……</p>
        <div className={`checkin-absence ${state.flags.cardZeroTaken ? "is-collected" : ""}`}>
          <span>本周缺勤</span>
          {state.flags.codeScattered && !state.flags.cardZeroTaken ? (
            <button type="button" aria-label="收集本周缺勤次数零" onClick={collectAbsenceZero}>0</button>
          ) : (
            <strong>0</strong>
          )}
          <span>次</span>
        </div>
      </article>

      <div className={`checkin-slots ${error ? "is-error" : ""} ${code.length === 4 ? "is-ready" : ""}`.trim()} aria-label="签到码输入">
        {slots.map((ch, i) => (
          <span key={i} className={`code-slot ${ch ? "is-filled" : ""}`}>
            {ch}
          </span>
        ))}
        {entryPulse ? (
          <span
            key={entryPulse.id}
            className="checkin-entry-pulse"
            data-slot={entryPulse.slot}
            aria-hidden="true"
          >
            <b>{entryPulse.digit}</b>
            <i /><i /><i />
          </span>
        ) : null}
      </div>
      {error ? <p className="checkin-error">签到码错误，请重新输入</p> : null}

      <div className="checkin-pad" role="group" aria-label="数字键盘">
        {["1", "2", "3", "4", "5", "6", "7", "8", "9"].map((d) => (
          <button key={d} type="button" className="pad-key" onClick={() => pressDigit(d)}>
            {d}
          </button>
        ))}
        <button type="button" className="pad-key pad-del" onClick={backspace} aria-label="删除">
          ⌫
        </button>
        <button type="button" className="pad-key" onClick={() => pressDigit("0")}>
          0
        </button>
        <button type="button" className="pad-key pad-ok" onClick={submit} disabled={code.length < 4}>
          签到
        </button>
      </div>

      {finale !== "none" ? (
        <div className={`checkin-finale phase-${finale}`} aria-live="polite">
          {finale === "stamp1" || finale === "stamp2" ? (
            <div className="stamp-chars">
              <span className="stamp-pixels" aria-hidden="true">
                <i /><i /><i /><i /><i /><i /><i /><i />
              </span>
              <span className="stamp-char">签</span>
              {finale === "stamp2" ? <span className="stamp-char delay">到</span> : null}
            </div>
          ) : null}
          {finale === "geoerror" ? (
            <section className="checkin-geo-error" role="alertdialog" aria-labelledby="checkin-geo-error-title">
              <header><span>系统通知 · LOCATION ERROR</span><i aria-hidden="true">×</i></header>
              <strong id="checkin-geo-error-title">经度与纬度不存在</strong>
              <p>longitude: null · latitude: null</p>
              <small>ERR_GEO_0798</small>
            </section>
          ) : null}
          {finale === "redflash" ? <div className="red-flash" aria-hidden="true" /> : null}
          {finale === "blackout" ? (
            <div className="blackout" aria-label="黑屏" />
          ) : null}
        </div>
      ) : null}
    </section>
  );
}
