import { useEffect, useState } from "react";
import tiyiLoadingUrl from "../../../assets/ui/tiyi_loading.png";
import tiyiMainUrl from "../../../assets/ui/tiyi_main.png";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { playSfx } from "../../../modules/Sfx";
import { playVo } from "../../../modules/VoicePlayer";
import { RouteAuditPanel } from "./RouteAuditPanel";
import "../../../styles/library-v2-phone.css";

const CRASH_DELAY_MS = 3000;
const LOAD_DELAY_MS = 1400;

/**
 * P06 浙大体艺：
 * - 校园网：加载页停 3 秒 → 闪退回主屏（≥3 次触发嘲讽）
 * - 流量：正常进入，打卡次数 47 高亮为黄色，点击获得 d2=7
 */
export function TiyiScene({ state, router, events }: SceneComponentProps) {
  const [phase, setPhase] = useState<"loading" | "main" | "crashing">("loading");
  const { flags } = state;
  const finalsPhase = state.ui.libraryFinalsPhase;
  const finalsPuzzle = state.ui.libraryFinalsPuzzle;
  const actOnePhase = state.actOne.phase;
  const movementQuestActive = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready"].includes(actOnePhase);
  const finalsAuditActive = finalsPhase === "evidence_gathering" && finalsPuzzle.investigationOpened;

  useEffect(() => {
    if (phase !== "loading") {
      return undefined;
    }

    const onCampusWifi = !kit.network.canOpenTiyi() && !finalsAuditActive && !movementQuestActive;
    const timer = window.setTimeout(
      () => {
        if (onCampusWifi) {
          setPhase("crashing");
          playSfx("12_");
          const crashes = kit.flags.bumpTiyiCrash();
          events.emit("tiyi_crashed", { crashes });
          window.setTimeout(() => {
            router.goTo("phone_home");
            if (crashes >= 3) {
              playVo("sys_net_try", {
                subtitle: true,
                onEnded: () => playVo("sys_no_money", { subtitle: true, tone: "xiaoying" })
              });
            } else {
              kit.flags.toast(crashes === 1 ? "「浙大体艺」已停止运行。" : "「浙大体艺」又双叒停止运行了。");
            }
          }, 620);
        } else {
          setPhase("main");
        }
      },
      onCampusWifi ? CRASH_DELAY_MS : LOAD_DELAY_MS
    );

    return () => window.clearTimeout(timer);
  }, [phase, router, events, finalsAuditActive, movementQuestActive]);

  function collectSeven() {
    if (flags.tiyiCountTaken) {
      kit.flags.toast("47 次。它已经把 7 交出来了。");
      return;
    }
    playSfx("10_");
    playVo("tiyi_47", { subtitle: true });
    kit.digits.collectDigit(2, "7", "tiyi");
    kit.flags.setFlag("tiyiCountTaken", true);
    kit.flags.toast("获得第 2 位：7", "task");
  }

  function startActOneExercise() {
    const alreadyStarted = state.actOne.exerciseStarted;
    if (!kit.actOne.startExercise()) {
      kit.flags.toast("锻炼对象没有姓名。先去部门黄页叫出他的名字。", "system");
      return;
    }
    if (alreadyStarted) {
      kit.flags.toast("课外锻炼已经在记录。", "system");
    }
  }

  if (phase !== "main") {
    return (
      <section className={`app-screen tiyi-loading ${phase === "crashing" ? "is-crashing" : ""}`} aria-label="浙大体艺加载中">
        <img className="app-bg" src={tiyiLoadingUrl} alt="" aria-hidden="true" />
        <span className="loading-dots" aria-hidden="true">
          <i />
          <i />
          <i />
        </span>
        <button type="button" className="app-exit px-btn paper" onClick={() => router.goTo("phone_home")}>
          退出
        </button>
      </section>
    );
  }

  return (
    <section className="app-screen tiyi-main" aria-label="浙大体艺">
      <div className="app-bg-crop tiyi-crop">
        <img className="app-bg" src={tiyiMainUrl} alt="" aria-hidden="true" />
        {!finalsAuditActive ? (
          <button
            type="button"
            className={`tiyi-47 ${flags.tiyiCountTaken ? "is-taken" : ""}`}
            aria-label="运动打卡次数 47"
            onClick={collectSeven}
          >
            47
          </button>
        ) : null}
      </div>
      {finalsAuditActive ? (
        <RouteAuditPanel phase={finalsPhase} puzzle={finalsPuzzle} router={router} />
      ) : null}
      {movementQuestActive && finalsPhase === "idle" ? (
        <button
          type="button"
          className={`tiyi-act1-exercise-button ${state.actOne.exerciseStarted ? "is-active" : ""}`}
          disabled={state.actOne.exerciseStarted}
          onClick={startActOneExercise}
        >
          <strong>{state.actOne.exerciseStarted ? "课外锻炼进行中" : "开始课外锻炼"}</strong>
          <span>{state.actOne.exerciseStarted
            ? "小人正在寝室内自动来回走动"
            : state.actOne.characterNamed
              ? "参加者已确认"
              : "请先在部门黄页确认参加者"}</span>
        </button>
      ) : null}
      <PhoneNavButton kind="exit" className="app-back px-btn paper" onClick={() => router.goTo("phone_home")} label="退出浙大体艺，返回手机主页" />
    </section>
  );
}
