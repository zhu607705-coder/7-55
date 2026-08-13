import { useEffect, useRef, useState } from "react";
import zjudingUrl from "../../../assets/ui/zjuding.png";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { requestCc98Thread, requestFriendChat } from "../../../modules/NavIntent";
import theaterContent from "../../../data/chapter3-theater.content.json";
import { playSfx } from "../../../modules/Sfx";
import { playVo } from "../../../modules/VoicePlayer";
import { selectFeatureAccess } from "../../../core/FeatureAccess";
import { selectChapterFourWechatObjective } from "../../../modules/ChapterFourWechatModel";

/**
 * P13 手机主界面：像素浙大校园壁纸。
 * 机关：设置齿轮（自动旋转→掉落→9）、塔楼钥匙孔（→肥料）、
 * 天气组件水滴、湖边盆栽入口、微信弹窗通知。
 */
export function PhoneHomeScene({ state, router, events }: SceneComponentProps) {
  const [noticeStep, setNoticeStep] = useState(0);
  const [gearSpinning, setGearSpinning] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [towerPhase, setTowerPhase] = useState<"idle" | "inserting" | "rotating">("idle");
  const towerTimersRef = useRef<number[]>([]);
  const towerInFlightRef = useRef(false);
  const { flags, ui } = state;
  const access = selectFeatureAccess(state);
  const friendFollowupPending = state.actOne.phase === "friend_message_required";
  const chapterServicesOpen = state.actOne.phase !== "prologue";
  const movementQuestActive = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready"].includes(state.actOne.phase);
  const bikeArcadeUnlocked = state.bikeArcade.unlocked;
  const chapterFourWechatObjective = selectChapterFourWechatObjective(state.chapter4);

  // 微信弹窗：1s 出第一条，2.4s 出第二条（散码前）
  useEffect(() => {
    if (flags.codeScattered || flags.checkinDone || friendFollowupPending) {
      return undefined;
    }
    const t1 = window.setTimeout(() => {
      setNoticeStep(1);
      playSfx("07_");
    }, 1000);
    const t2 = window.setTimeout(() => {
      setNoticeStep(2);
      playSfx("07_");
    }, 2400);
    return () => {
      window.clearTimeout(t1);
      window.clearTimeout(t2);
    };
  }, [flags.checkinDone, flags.codeScattered, friendFollowupPending]);

  useEffect(() => {
    if (!friendFollowupPending) {
      return undefined;
    }
    const timer = window.setTimeout(() => {
      setNoticeStep(3);
      playSfx("07_");
    }, 900);
    return () => window.clearTimeout(timer);
  }, [friendFollowupPending]);

  // 自动旋转开启时，齿轮转 180° 后掉落；掉落后自动旋转自动关闭
  useEffect(() => {
    if (!ui.autoRotate || flags.gearFallen || flags.gearNineTaken) {
      return undefined;
    }
    setGearSpinning(true);
    playSfx("16_");
    const timer = window.setTimeout(() => {
      setGearSpinning(false);
      kit.flags.setFlag("gearFallen", true);
      kit.flags.setUi("autoRotate", false);
      kit.flags.shake();
      playSfx("17_");
      kit.flags.toast("哐当——齿轮转了半圈，掉下来了。背面朝外。");
    }, 1500);
    return () => window.clearTimeout(timer);
  }, [ui.autoRotate, flags.gearFallen, flags.gearNineTaken]);

  // 钥匙拖到塔楼锁孔上
  useEffect(() => {
    const unsubscribe = events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "tower") {
        return;
      }
      if (event.payload?.item !== "towerKey") {
        playSfx("04_", { volume: 0.5 });
        kit.flags.toast("塞不进去。");
        return;
      }
      if (
        kit.flags.getFlag("towerOpened") ||
        towerInFlightRef.current ||
        !kit.inventory.hasItem("towerKey")
      ) {
        return;
      }
      towerInFlightRef.current = true;
      setTowerPhase("inserting");
      const rotateTimer = window.setTimeout(() => {
        setTowerPhase("rotating");
        playSfx("21_");
      }, 650);
      const completeTimer = window.setTimeout(() => {
        towerTimersRef.current = [];
        towerInFlightRef.current = false;
        setTowerPhase("idle");
        if (!kit.inventory.consumeItem("towerKey", "tower_slot")) {
          return;
        }
        kit.flags.setFlag("towerOpened", true);
        kit.flags.setUi("selectedItem", null);
        kit.inventory.addItem("fertilizer", "phone_home");
        kit.flags.toast("钥匙旋转 90°——咔哒。塔楼吐出[一袋肥料]。", "task");
      }, 1700);
      towerTimersRef.current = [rotateTimer, completeTimer];
    });
    return () => {
      unsubscribe();
      towerTimersRef.current.forEach((timer) => window.clearTimeout(timer));
      towerTimersRef.current = [];
      towerInFlightRef.current = false;
    };
  }, [events]);

  useEffect(() => {
    if (!settingsOpen) return undefined;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSettingsOpen(false);
    };
    window.addEventListener("keydown", closeOnEscape);
    return () => window.removeEventListener("keydown", closeOnEscape);
  }, [settingsOpen]);

  function enterWechat(openFriendChat = false) {
    playSfx("02_");
    if (openFriendChat) {
      requestFriendChat();
    }
    router.goTo("wechat");
  }

  function openApp(sceneId: "tiyi" | "zjuding" | "cc98") {
    playSfx("02_");
    if (sceneId === "zjuding") {
      kit.flags.setUi("zjudingPage", "hub");
    }
    router.goTo(sceneId);
  }

  function openTheaterTicketCommission() {
    const ticketPortalCanUseCellular = state.networkMode === "cellular"
      && ["accepted", "first_wave_failed", "delivered"].includes(
        state.theaterHunt.cc98TicketCommissionPhase
      );
    if (state.networkMode !== "campus_wifi" && !ticketPortalCanUseCellular) {
      kit.flags.toast(
        "CC98 需要校园网；已经载入的手机票务页面可在移动数据下继续。",
        "task"
      );
      return;
    }
    requestCc98Thread(theaterContent.cc98TicketCommission.id);
    openApp("cc98");
  }

  function openWeather() {
    playSfx("02_");
    router.goTo("weather");
  }

  function collectPushTriangle() {
    const result = kit.actOne.collectPushTriangle();
    if (result === "collected") {
      return;
    }
    if (result === "already_owned" || (result === "inactive" && !state.actOne.exerciseStarted)) {
      return;
    }
    const feedback = {
      inactive: "这条推送现在只负责占位置。",
      hint_one: "头像边缘松了一点，再点一次。",
      hint_two: "三角形已经翘起，再点一次就能取下。"
    }[result];
    kit.flags.toast(feedback, "system");
  }

  function openBikeArcade() {
    playSfx("02_");
    router.goTo("bike_arcade");
  }

  function clickGearIcon() {
    if (flags.gearNineTaken) {
      kit.flags.toast("设置图标只剩一个空位，风从里面吹过。");
      return;
    }
    if (flags.gearFallen) {
      kit.flags.toast("齿轮已经掉在下面了。");
      return;
    }
    events.emit("gear_hint");
    kit.flags.toast(ui.autoRotate ? "它转起来了！" : "它看起来很想转转。");
  }

  function openSettings() {
    playSfx("02_");
    if (access.chapter === "chapter_one") {
      clickGearIcon();
      return;
    }
    setSettingsOpen(true);
  }

  function toggleBackgroundMusic() {
    playSfx("02_", { volume: 0.5 });
    const nextMuted = !ui.musicMuted;
    kit.flags.setUi("musicMuted", nextMuted);
    kit.flags.toast(nextMuted ? "背景音乐已关闭。语音和操作音效保留。" : "背景音乐已开启。");
  }

  function collectGearNine() {
    if (flags.gearNineTaken) {
      return;
    }
    playSfx("10_");
    playVo("gear_pickup", { subtitle: true, tone: "xiaoying" });
    kit.digits.collectDigit(3, "9", "phone_home");
    kit.flags.setFlag("gearNineTaken", true);
    kit.inventory.addItem("reverseGear", "phone_home");
    kit.flags.toast("获得第 3 位：9", "task");
  }

  function clickTower() {
    if (towerPhase !== "idle") {
      return;
    }
    if (flags.towerOpened) {
      kit.flags.toast("钟楼已经把秘密交出去了。");
      return;
    }
    playSfx("03_");
    kit.flags.toast("钟楼大门紧锁。锁孔的形状有点奇怪。");
  }

  function collectWaterDrop() {
    if (flags.waterDropTaken) {
      return;
    }
    playSfx("18_");
    kit.flags.setFlag("waterDropTaken", true);
    kit.inventory.addItem("waterDrop", "phone_home");
    kit.flags.toast("接住了一滴早八雨。", "task");
  }

  function enterBonsai() {
    playSfx("02_");
    if (!flags.bonsaiHintShown) {
      kit.flags.setFlag("bonsaiHintShown", true);
      kit.flags.toast("它绝对不会开花。");
    }
    router.goTo("bonsai");
  }

  function openPhotos() {
    playSfx("02_");
    router.goTo("photos");
  }

  function openClock() {
    playSfx("02_");
    router.goTo("clock");
  }

  const gearClass = flags.gearNineTaken
    ? "is-gone"
    : gearSpinning
      ? "is-spinning"
      : flags.gearFallen
        ? "is-gone"
        : ui.autoRotate
          ? "is-restless"
          : "";

  return (
    <main className="phone" aria-label="像素风浙大首页">
      <div className="background" aria-hidden="true">
        <div className="cloud c1" />
        <div className="cloud c2" />
        <div className="cloud c3" />
        <div className="small-cloud" />
        <div className="campus-base" />
        <div className="portal" />
        <div className="steps">
          <span />
          <span />
          <span />
          <span />
          <span />
          <span />
        </div>
        <div className="plinth" />
        <div className="trees">
          <div className="trunk" />
          <div className="leaf l1" />
          <div className="leaf l2" />
          <div className="leaf l3" />
          <div className="leaf l4" />
        </div>
        <div className="lake" />
      </div>

      <button
        type="button"
        className={`tower tower-button ${towerPhase !== "idle" ? "is-working" : ""}`}
        data-drop-target="tower"
        aria-label="钟楼"
        onClick={clickTower}
      >
        <span className="tower-top">
          <i className="slot" />
          <i className="slot" />
        </span>
        <span className="tower-body">
          <span className="clock" />
          {!flags.towerOpened ? <span className="tower-keyhole" aria-hidden="true" /> : null}
          {!flags.towerOpened ? <span className="tower-drop-zone" data-drop-target="tower" aria-hidden="true" /> : null}
        </span>
        {towerPhase !== "idle" ? (
          <span className={`tower-key ${towerPhase === "rotating" ? "is-rotating" : ""}`} aria-hidden="true" />
        ) : null}
      </button>

      <button type="button" className="bonsai-pot" aria-label="湖边盆栽" onClick={enterBonsai}>
        <i className="pot-plant" />
        <i className="pot-body" />
      </button>

      <section className="weather-card" aria-label="天气：小雨，18 摄氏度">
        {access.weather ? (
          <button type="button" className="weather-card-open" aria-label="打开天气" onClick={openWeather} />
        ) : null}
        <div className="weather-top">
          <div className="rain-icon pixelated">
            <div className="cloud-pixel" />
            <i className="drop d1" />
            <i className="drop d2" />
            <i className="drop d3" />
            {flags.codeScattered && !flags.waterDropTaken ? (
              <button type="button" className="drop drop-live" aria-label="收集水滴" onClick={collectWaterDrop} />
            ) : null}
          </div>
          <div className="temp-title">
            <div className="cond">小雨</div>
            <div className="temp">
              18<small>°C</small>
            </div>
          </div>
        </div>
        <div className="weather-range">最高 20°C / 最低 15°C</div>
        <div className="divider" />
        <div className="weather-meta">
          <span>空气湿度 88%</span>
          <span>西南风 2级</span>
        </div>
      </section>

      <section className="apps" aria-label="应用">
        <button
          type="button"
          className={`app chapter-four-wechat-app ${chapterFourWechatObjective ? "is-pending" : ""}`.trim()}
          aria-label={chapterFourWechatObjective ? `微信，待处理：${chapterFourWechatObjective.label}` : "微信"}
          onClick={() => enterWechat(false)}
        >
          <div className="app-icon b-green">
            <div className="wechat-icon">
              <i className="bubble one" />
              <i className="bubble two" />
              <i className="eye e1" />
              <i className="eye e2" />
              <i className="eye e3" />
              <i className="eye e4" />
            </div>
          </div>
          <span className="label">微信</span>
        </button>
        <button type="button" className="app" aria-label="浙大体艺" onClick={() => openApp("tiyi")}>
          <div className="app-icon b-orange">
            <div className="runner">
              <i className="body" />
              <i className="arm1" />
              <i className="arm2" />
              <i className="leg1" />
              <i className="leg2" />
            </div>
          </div>
          <span className="label">浙大体艺</span>
        </button>
        <button type="button" className={`app ${chapterServicesOpen ? "is-chapter-open" : ""}`} aria-label="浙大钉" onClick={() => openApp("zjuding")}>
          <div className="app-icon b-light">
            <img className="zjuding-img" alt="" src={zjudingUrl} />
          </div>
          <span className="label">浙大钉</span>
        </button>
        <button type="button" className="app" aria-label="设置" onClick={openSettings}>
          <div className="app-icon b-gray gear-slot">
            <span className={`gear-sprite ${gearClass}`} aria-hidden="true">
              ✱
            </span>
          </div>
          <span className="label">设置</span>
        </button>
        {access.photos ? (
          <button type="button" className="app is-chapter-open" aria-label="照片" onClick={openPhotos}>
            <div className="app-icon b-light"><i className="photo-flower" /></div>
            <span className="label">照片</span>
          </button>
        ) : (
          <div className="app app-locked" data-locked-app="照片" aria-hidden="true">
            <div className="app-icon b-light"><i className="photo-flower" /></div>
            <span className="label">照片</span>
          </div>
        )}
        {access.cc98 ? (
          <button type="button" className="app is-chapter-open" aria-label="CC98" onClick={() => openApp("cc98")}>
            <div className="app-icon b-blue"><b className="cc98-text">CC98</b></div>
            <span className="label">CC98</span>
          </button>
        ) : (
          <div className="app app-locked" data-locked-app="CC98" aria-hidden="true">
            <div className="app-icon b-blue"><b className="cc98-text">CC98</b></div>
            <span className="label">CC98</span>
          </div>
        )}
        {bikeArcadeUnlocked && access.bikeArcade ? (
          <button
            type="button"
            className={`app bike-game-app ${state.bikeArcade.completed ? "is-complete" : "is-new"}`}
            aria-label="游戏"
            onClick={openBikeArcade}
          >
            <div className="app-icon game-app-icon">
              <span aria-hidden="true">7:55</span>
              <i aria-hidden="true" />
              <b className="game-app-badge" aria-hidden="true">
                {state.bikeArcade.completed ? "✓" : "1"}
              </b>
            </div>
            <span className="label">游戏</span>
          </button>
        ) : (
          <div className="app app-locked" data-locked-app="游戏" aria-hidden="true">
            <div className="app-icon game-app-icon">
              <span aria-hidden="true">7:55</span>
              <i aria-hidden="true" />
            </div>
            <span className="label">游戏</span>
          </div>
        )}
        <button
          type="button"
          className="app"
          aria-label="控制中心"
          onClick={() => {
            playSfx("02_");
            kit.flags.setUi("controlCenterOpen", true);
          }}
        >
          <div className="app-icon b-purple">
            <i className="control" />
          </div>
          <span className="label">控制中心</span>
        </button>
        {access.clockCalibration ? (
          <button
            type="button"
            className={`app is-chapter-open clock-app ${state.clockCalibration.phase === "aligned" ? "is-aligned" : ""}`}
            aria-label="时钟"
            onClick={openClock}
          >
            <div className="app-icon clock-app-icon"><i className="clock-app-face" /></div>
            <span className="label">时钟</span>
          </button>
        ) : (
          <div className="app app-locked" data-locked-app="时钟" aria-hidden="true">
            <div className="app-icon clock-app-icon"><i className="clock-app-face" /></div>
            <span className="label">时钟</span>
          </div>
        )}
      </section>

      {settingsOpen ? (
        <section className="phone-settings-backdrop" role="presentation" onMouseDown={(event) => {
          if (event.target === event.currentTarget) setSettingsOpen(false);
        }}>
          <section className="phone-settings-panel" role="dialog" aria-modal="true" aria-labelledby="phone-settings-title">
            <header>
              <div>
                <small>PHONE SETTINGS</small>
                <h2 id="phone-settings-title">设置</h2>
              </div>
              <button type="button" className="phone-settings-close" aria-label="关闭设置" onClick={() => setSettingsOpen(false)}>×</button>
            </header>
            <div className="phone-settings-row">
              <span className="phone-settings-music-icon" aria-hidden="true">♪</span>
              <span className="phone-settings-copy">
                <strong>背景音乐</strong>
                <small>语音和操作音效不会关闭</small>
              </span>
              <button
                type="button"
                className={`phone-settings-switch ${ui.musicMuted ? "is-off" : "is-on"}`}
                aria-label={ui.musicMuted ? "开启背景音乐" : "关闭背景音乐"}
                aria-pressed={!ui.musicMuted}
                onClick={toggleBackgroundMusic}
              >
                <span aria-hidden="true" />
                <b>{ui.musicMuted ? "关闭" : "开启"}</b>
              </button>
            </div>
            <p className="phone-settings-note">音乐设置会自动保存。</p>
          </section>
        </section>
      ) : null}

      {flags.gearFallen && !flags.gearNineTaken ? (
        <button type="button" className="fallen-gear" aria-label="掉落的齿轮，背面刻着 9" onClick={collectGearNine}>
          <span className="fallen-gear-face">✱</span>
          <span className="fallen-gear-nine">9</span>
        </button>
      ) : null}

      <section className="notifications" aria-label="通知列表">
        {access.chapter === "chapter_three" ? (
          <>
            {state.theaterHunt.cc98TicketCommissionPhase !== "locked" ? (
              <button
                type="button"
                className="note theater-ticket-note"
                onClick={openTheaterTicketCommission}
                aria-label="打开 CC98 学生剧现场帮抢帖"
              >
                <div className="mini b-blue" aria-hidden="true"><b className="cc98-text">98</b></div>
                <div>
                  <div className="note-title">CC98 · 学生剧《7:55》</div>
                  <div className="note-msg">
                    {state.theaterHunt.cc98TicketCommissionPhase === "posted"
                      ? "现场帮抢委托待接"
                      : state.theaterHunt.cc98TicketCommissionPhase === "accepted"
                        ? "已接单，第一波待开始"
                        : state.theaterHunt.cc98TicketCommissionPhase === "first_wave_failed"
                          ? state.networkMode === "cellular"
                            ? "流量已开启，返回手机票务页抢第二波"
                            : "第一波结束：网速过慢，开启流量"
                          : state.theaterHunt.cc98TicketClaimedWave === 1
                            ? "第一波抢票成功，运气很好，钱包没那么好"
                            : "08:32 第二波取票回执已同步"}
                  </div>
                </div>
                <time className="note-time">
                  {state.theaterHunt.cc98TicketClaimedWave === 1
                    ? "08:31"
                    : state.theaterHunt.cc98TicketCommissionPhase === "posted"
                    ? "08:29"
                    : state.theaterHunt.cc98TicketCommissionPhase === "accepted"
                      ? "08:30"
                      : state.theaterHunt.cc98TicketCommissionPhase === "first_wave_failed" ? "08:31" : "08:32"}
                </time>
              </button>
            ) : null}
            <article className="note" aria-label="图书馆：您有一本书已逾期 755 天">
              <div className="mini b-blue" aria-hidden="true"><i className="schedule-mini" /></div>
              <div><div className="note-title">图书馆</div><div className="note-msg">您有一本书已逾期 755 天</div></div>
              <time className="note-time">08:25</time>
            </article>
            <article className="note" aria-label="CC98：Re: 三楼书架是不是多了一层？">
              <div className="mini b-blue" aria-hidden="true"><b className="cc98-text">98</b></div>
              <div><div className="note-title">CC98</div><div className="note-msg">Re: 三楼书架是不是多了一层？</div></div>
              <time className="note-time">08:24</time>
            </article>
            <article className="note" aria-label="照片：新增照片「看不清的书脊」">
              <div className="mini b-light" aria-hidden="true"><i className="photo-flower" /></div>
              <div><div className="note-title">照片</div><div className="note-msg">新增照片「看不清的书脊」</div></div>
              <time className="note-time">08:23</time>
            </article>
          </>
        ) : (
          <>
            {bikeArcadeUnlocked && !state.bikeArcade.completed ? (
              <article className="note bike-arcade-task-note">
                <div className="mini game-app-icon" aria-hidden="true"><span>755</span></div>
                <div><div className="note-title">求是潮 755</div><div className="note-msg">穿过求是潮，距离 755 米。</div></div>
                <time className="note-time">07:55</time>
              </article>
            ) : null}
            <button
              type="button"
              className={`note act2-triangle-note ${state.actOne.pushTriangleTaken ? "is-collected" : ""}`}
              onClick={collectPushTriangle}
              disabled={!movementQuestActive || !state.actOne.exerciseStarted || state.actOne.pushTriangleTaken}
              aria-label={state.actOne.pushTriangleTaken ? "三角形已收集" : "系统方向推送"}
            >
              <div className="mini b-blue">{movementQuestActive && state.actOne.exerciseStarted ? <i className="push-triangle-mini" /> : <i className="schedule-mini" />}</div>
              <div>
                <div className="note-title">{movementQuestActive && state.actOne.exerciseStarted ? "方向校准" : "课程提醒"}</div>
                <div className="note-msg">{movementQuestActive && state.actOne.exerciseStarted ? "头像方向正确，正文方向未知。" : "签到记录未更新。你本人仍未抵达。"}</div>
              </div>
              <time className="note-time">07:50</time>
            </button>
            {access.fullCampusMap ? (
              <article className="note">
                <div className="mini b-light"><img className="note-zjuding-img" alt="" src={zjudingUrl} aria-hidden="true" /></div>
                <div><div className="note-title">浙大钉</div><div className="note-msg">校园地图已恢复访问，寝室入口可用。</div></div>
                <time className="note-time">07:45</time>
              </article>
            ) : (
              <article className="note">
                <div className="mini b-light"><img className="note-zjuding-img" alt="" src={zjudingUrl} aria-hidden="true" /></div>
                <div><div className="note-title">学在浙大</div><div className="note-msg">课堂签到仍在等待四位代码。</div></div>
                <time className="note-time">07:45</time>
              </article>
            )}
            {access.weather ? (
              <button
                type="button"
                className="note weather-notification"
                aria-label="天气：小雨，局部黏着物可能松动"
                onClick={openWeather}
              >
                <div className="mini mini-rain"><div className="rain-icon mini-rain-icon"><div className="cloud-pixel" /><i className="drop d1" /><i className="drop d2" /><i className="drop d3" /></div></div>
                <div><div className="note-title">天气</div><div className="note-msg">小雨。局部黏着物可能松动。</div></div>
                <time className="note-time">07:35</time>
              </button>
            ) : (
              <article className="note" aria-label="天气：小雨，局部黏着物可能松动">
                <div className="mini mini-rain"><div className="rain-icon mini-rain-icon"><div className="cloud-pixel" /><i className="drop d1" /><i className="drop d2" /><i className="drop d3" /></div></div>
                <div><div className="note-title">天气</div><div className="note-msg">小雨。局部黏着物可能松动。</div></div>
                <time className="note-time">07:35</time>
              </article>
            )}
          </>
        )}
      </section>

      <nav className="page-dots" aria-label="页面切换">
        <button type="button" className="dot active" aria-label="第 1 页" />
        <button type="button" className="dot" aria-label="第 2 页" />
        <button type="button" className="dot" aria-label="第 3 页" />
      </nav>

      {friendFollowupPending && noticeStep >= 3 ? (
        <button type="button" className="phone-top-notice is-followup" onClick={() => enterWechat(true)} aria-label="朋友：成功了吗">
          <span className="notice-app-icon">
            <span className="wechat-icon mini-wechat">
              <i className="bubble one" />
              <i className="bubble two" />
              <i className="eye e1" />
              <i className="eye e2" />
              <i className="eye e3" />
              <i className="eye e4" />
            </span>
          </span>
          <span className="notice-copy"><strong>朋友</strong><span>成功了吗</span></span>
          <time>现在</time>
        </button>
      ) : !flags.codeScattered && noticeStep > 0 ? (
        <button type="button" className="phone-top-notice" onClick={() => enterWechat(true)} aria-label="朋友发来的微信消息">
          <span className="notice-app-icon">
            <span className="wechat-icon mini-wechat">
              <i className="bubble one" />
              <i className="bubble two" />
              <i className="eye e1" />
              <i className="eye e2" />
              <i className="eye e3" />
              <i className="eye e4" />
            </span>
          </span>
          <span className="notice-copy">
            <strong>朋友</strong>
            <span>快快老师在点名，学在浙大</span>
            {noticeStep >= 2 ? <span className="notice-second">这是签到码：XX……</span> : null}
          </span>
          <time>现在</time>
        </button>
      ) : null}
    </main>
  );
}
