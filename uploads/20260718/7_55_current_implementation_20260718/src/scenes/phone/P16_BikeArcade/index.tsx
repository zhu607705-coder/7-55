import { useEffect, useRef, useState } from "react";
import type Phaser from "phaser";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import {
  BIKE_ARCADE_GOAL,
  BIKE_ARCADE_MAX_LIVES,
  type BikeArcadeMilestone
} from "./BikeArcadeRules";
import { clearBikeArcadeSnapshot, type BikeArcadePhase } from "./BikeArcadeRuntime";
import { getDeveloperBikeStart } from "../../../modules/DeveloperChannel";
import type { BikeArcadeBridge, BikeRushScene } from "./BikeRushScene";

type BikeArcadeLoadState = "idle" | "loading" | "ready" | "error";

const LOAD_TIMEOUT_MS = 3000;
const RESUME_NOTICE_MS = 1000;

function paddedDistance(distance: number): string {
  return String(Math.min(BIKE_ARCADE_GOAL, Math.max(0, Math.floor(distance)))).padStart(3, "0");
}

export function BikeArcadeScene({ state, router, events }: SceneComponentProps) {
  const developerStartDistance = getDeveloperBikeStart();
  const hostRef = useRef<HTMLDivElement | null>(null);
  const gameRef = useRef<Phaser.Game | null>(null);
  const sceneRef = useRef<BikeRushScene | null>(null);
  const distanceRef = useRef(developerStartDistance);
  const livesRef = useRef(BIKE_ARCADE_MAX_LIVES);
  const lastLifeAnnouncedRef = useRef(false);
  const resumeTimerRef = useRef<number | null>(null);
  const [phase, setPhase] = useState<BikeArcadePhase>("intro");
  const [distance, setDistance] = useState(developerStartDistance);
  const [lives, setLives] = useState(BIKE_ARCADE_MAX_LIVES);
  const [runId, setRunId] = useState(0);
  const [loadState, setLoadState] = useState<BikeArcadeLoadState>("idle");
  const [paused, setPaused] = useState(false);
  const [resumeNotice, setResumeNotice] = useState(false);
  const [milestone, setMilestone] = useState<BikeArcadeMilestone | null>(null);
  const unlocked = state.bikeArcade.unlocked;

  useEffect(() => {
    if (!unlocked) {
      return undefined;
    }
    kit.bikeArcade.syncUnlock();
    return () => {
      if (resumeTimerRef.current !== null) {
        window.clearTimeout(resumeTimerRef.current);
      }
      if (kit.bikeArcade.cancelAttempt()) {
        events.emit("bike_arcade_closed");
      }
    };
  }, [events, unlocked]);

  useEffect(() => {
    if (!unlocked || runId === 0 || !hostRef.current) {
      return undefined;
    }

    let cancelled = false;
    let booted = false;
    const loadTimer = window.setTimeout(() => {
      if (!booted && !cancelled) {
        setLoadState("error");
      }
    }, LOAD_TIMEOUT_MS);
    const reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    const bridge: BikeArcadeBridge = {
      reducedMotion,
      onDistance: (nextDistance) => {
        distanceRef.current = nextDistance;
        setDistance(nextDistance);
        if (nextDistance > 0 && nextDistance % 25 === 0) {
          kit.bikeArcade.recordProgress(nextDistance, livesRef.current);
        }
      },
      onLives: (nextLives) => {
        livesRef.current = nextLives;
        setLives(nextLives);
      },
      onLaneChanged: ({ from, to }) => {
        events.emit("bike_arcade_lane_changed", { from, to });
      },
      onNearMiss: ({ obstacleType, lane }) => {
        events.emit("bike_arcade_near_miss", { obstacleType, lane });
      },
      onCollision: (collision) => {
        livesRef.current = collision.lives;
        setLives(collision.lives);
        kit.bikeArcade.recordProgress(distanceRef.current, collision.lives);
        events.emit("bike_arcade_collision", { ...collision });
        if (collision.lives === 1 && !lastLifeAnnouncedRef.current) {
          lastLifeAnnouncedRef.current = true;
          events.emit("bike_arcade_last_life");
        }
        if (!reducedMotion) {
          events.emit("screen_shake");
        }
      },
      onMilestone: (nextMilestone) => {
        setMilestone(nextMilestone);
        events.emit("bike_arcade_milestone", { distance: nextMilestone });
        if (nextMilestone === 377) {
          events.emit("bike_arcade_congestion_started", { distance: nextMilestone });
        }
        if (nextMilestone === 566) {
          events.emit("bike_arcade_sprint_started", { distance: nextMilestone });
        }
        window.setTimeout(() => setMilestone((current) => current === nextMilestone ? null : current), 900);
      },
      onPauseChange: (isPaused) => {
        setPaused(isPaused);
        if (isPaused) {
          setResumeNotice(false);
          events.emit("bike_arcade_paused");
          return;
        }
        setResumeNotice(true);
        events.emit("bike_arcade_resumed");
        if (resumeTimerRef.current !== null) {
          window.clearTimeout(resumeTimerRef.current);
        }
        resumeTimerRef.current = window.setTimeout(() => setResumeNotice(false), RESUME_NOTICE_MS);
      },
      onFinish: (result, summary) => {
        distanceRef.current = summary.distance;
        livesRef.current = summary.lives;
        setDistance(summary.distance);
        setLives(summary.lives);
        kit.bikeArcade.recordProgress(summary.distance, summary.lives);
        if (result === "won") {
          kit.bikeArcade.completeAttempt(summary.lives);
        } else {
          kit.bikeArcade.failAttempt(summary.distance);
        }
        setPaused(false);
        setPhase(result);
      }
    };

    void Promise.all([import("phaser"), import("./BikeRushScene")])
      .then(([phaserModule, sceneModule]) => {
        if (cancelled || !hostRef.current) {
          return;
        }
        const PhaserRuntime = phaserModule.default;
        const game = new PhaserRuntime.Game({
          type: PhaserRuntime.CANVAS,
          parent: hostRef.current,
          width: 390,
          height: 650,
          backgroundColor: "#73945f",
          pixelArt: true,
          roundPixels: true,
          physics: { default: "arcade", arcade: { debug: false } },
          scale: { mode: PhaserRuntime.Scale.FIT, autoCenter: PhaserRuntime.Scale.CENTER_BOTH },
          scene: [sceneModule.BikeRushScene],
          callbacks: {
            preBoot: (phaserGame) => {
              phaserGame.registry.set("bikeArcadeBridge", bridge);
              phaserGame.registry.set("bikeArcadeReducedMotion", reducedMotion);
              phaserGame.registry.set("bikeArcadeStartDistance", getDeveloperBikeStart());
            },
            postBoot: (phaserGame) => {
              booted = true;
              window.clearTimeout(loadTimer);
              sceneRef.current = phaserGame.scene.getScene("bike-rush") as BikeRushScene;
              setLoadState("ready");
            }
          }
        });
        gameRef.current = game;
      })
      .catch(() => {
        if (!cancelled) {
          window.clearTimeout(loadTimer);
          setLoadState("error");
        }
      });

    return () => {
      cancelled = true;
      window.clearTimeout(loadTimer);
      sceneRef.current = null;
      clearBikeArcadeSnapshot();
      gameRef.current?.destroy(true);
      gameRef.current = null;
    };
  }, [events, runId, unlocked]);

  function startRun() {
    if (!unlocked) {
      return;
    }
    if (runId > 0) {
      kit.bikeArcade.cancelAttempt();
      events.emit("bike_arcade_restarted");
    }
    if (!kit.bikeArcade.startAttempt()) {
      return;
    }
    const startDistance = getDeveloperBikeStart();
    distanceRef.current = startDistance;
    livesRef.current = BIKE_ARCADE_MAX_LIVES;
    lastLifeAnnouncedRef.current = false;
    setDistance(startDistance);
    setLives(BIKE_ARCADE_MAX_LIVES);
    setMilestone(null);
    setPaused(false);
    setResumeNotice(false);
    setLoadState("loading");
    setPhase("playing");
    setRunId((current) => current + 1);
  }

  function closeChapter() {
    kit.bikeArcade.cancelAttempt();
    events.emit("bike_arcade_closed");
    events.emit("bike_arcade_button_pressed");
    router.goTo("phone_home");
  }

  function continueChapter() {
    events.emit("bike_arcade_button_pressed");
    events.emit("bike_arcade_next_chapter_requested", { chapter: 4 });
    events.emit("bike_arcade_closed");
    router.goTo("chapter_transition");
  }

  if (!unlocked) {
    return (
      <section className="bike-arcade-screen is-locked" aria-label="求是潮755未解锁">
        <main className="bike-arcade-locked">
          <span>LOCKED</span>
          <h1>求是潮 755</h1>
          <p>恢复图书馆 022 座位后开放。</p>
          <button type="button" onClick={closeChapter}>返回手机桌面</button>
        </main>
      </section>
    );
  }

  const statusLabel = paused
    ? "PAUSE"
    : loadState === "loading"
      ? "LOAD"
      : phase === "playing"
        ? "RUN"
        : phase === "won"
          ? "CLEAR"
          : phase === "lost"
            ? "STOP"
            : "READY";
  const controlsDisabled = phase !== "playing" || loadState !== "ready" || paused;

  return (
    <section
      className={`bike-arcade-screen phase-${phase} load-${loadState}${paused ? " is-paused" : ""}`}
      aria-label="求是潮755"
    >
      <header className="bike-arcade-header">
        <PhoneNavButton kind="exit" label="退出求是潮 755，返回手机桌面" onClick={closeChapter} />
        <div>
          <span>GAME 07:55</span>
          <h1>求是潮 755</h1>
        </div>
        <b key={`${statusLabel}-${runId}`}>{statusLabel}</b>
      </header>

      <section className="bike-arcade-hud">
        <div><span>距离</span><strong className="bike-distance-value">{paddedDistance(distance)} / {BIKE_ARCADE_GOAL}m</strong></div>
        <div><span>机会</span><strong key={lives} className="bike-lives-value">{"■".repeat(lives)}{"□".repeat(BIKE_ARCADE_MAX_LIVES - lives)}</strong></div>
        <output className="sr-only" aria-live="polite">
          {milestone ? `已到达 ${milestone} 米` : phase === "won" ? "已通过" : phase === "lost" ? "机会耗尽" : ""}
        </output>
      </section>

      <main className="bike-arcade-arena" aria-busy={loadState === "loading"}>
        <div ref={hostRef} className="bike-arcade-canvas-host" aria-label="三车道骑行区域" />
        {phase === "playing" && loadState === "ready" ? (
          <div className="bike-arcade-speed-lines" aria-hidden="true">
            <i /><i /><i /><i /><i /><i />
          </div>
        ) : null}

        {phase === "intro" ? (
          <section className="bike-arcade-intro">
            <div className="bike-arcade-road-preview" aria-hidden="true">
              <i /><i /><i />
              <span className="bike-preview-rider">骑</span>
              <span className="bike-preview-block">堵</span>
              <b className="bike-preview-sign">755m</b>
            </div>
            <p>骑过 755 米。三次机会，左右换道。</p>
            <small>
              最佳 {paddedDistance(state.bikeArcade.bestDistance)}m · 尝试 {state.bikeArcade.attemptCount} 次
            </small>
            <button type="button" aria-label="开始骑行" onClick={startRun}>开始骑行</button>
          </section>
        ) : null}

        {loadState === "loading" ? (
          <section className="bike-arcade-loading" role="status">
            <span>LOADING</span>
            <i /><i /><i />
          </section>
        ) : null}

        {loadState === "error" ? (
          <section className="bike-arcade-load-error" role="alert">
            <strong>赛道加载失败</strong>
            <button type="button" onClick={startRun}>重新加载游戏</button>
            <button type="button" className="secondary" onClick={closeChapter}>返回桌面</button>
          </section>
        ) : null}

        {milestone && milestone < BIKE_ARCADE_GOAL ? (
          <div className="bike-arcade-milestone" role="status">
            <span>{milestone}m</span>
            <small>{milestone === 188 ? "节奏提升" : milestone === 377 ? "拥堵升级" : "最后冲刺"}</small>
          </div>
        ) : null}

        {paused || resumeNotice ? (
          <div className={`bike-arcade-pause ${resumeNotice ? "is-resuming" : ""}`} role="status">
            {resumeNotice ? "继续骑行" : "已暂停"}
          </div>
        ) : null}

        {phase === "won" || phase === "lost" ? (
          <section className={`bike-arcade-result is-${phase}`} role="dialog" aria-modal="true" aria-label={phase === "won" ? "骑行完成" : "骑行失败"}>
            <span>{phase === "won" ? "07:55:00" : "07:55:01"}</span>
            <h2>{phase === "won" ? "已通过" : "原地结算"}</h2>
            <p>{phase === "won" ? "已抵达 755 米，第三章完成记录已保存。" : `本次抵达 ${paddedDistance(distance)} 米，最高记录已保存。`}</p>
            {phase === "won" ? <button type="button" onClick={continueChapter}>继续下一章</button> : null}
            <button type="button" onClick={startRun}>再骑一次</button>
            <button type="button" className="secondary" onClick={closeChapter}>返回桌面</button>
          </section>
        ) : null}
      </main>

      <nav className="bike-arcade-controls" aria-label="骑行操作">
        <button type="button" aria-label="向左换道" disabled={controlsDisabled} onClick={() => sceneRef.current?.moveLane(-1)}>←</button>
        <div aria-hidden="true"><span>A</span><span>D</span></div>
        <button type="button" aria-label="向右换道" disabled={controlsDisabled} onClick={() => sceneRef.current?.moveLane(1)}>→</button>
      </nav>
    </section>
  );
}
