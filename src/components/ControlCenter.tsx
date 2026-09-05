import { useEffect, useRef, useState } from "react";
import type { GameState } from "../core/types";
import { kit } from "../modules/GameKit";
import { playSfx } from "../modules/Sfx";
import { PixelIcon } from "./PixelIcon";

interface ControlCenterProps {
  state: GameState;
}

/**
 * 控制中心下拉层（P05，参照 pageexample/control_center.html）。
 * 承担剧情机关：切网、播放音乐掉耳机、亮度照光、自动旋转。
 * （音乐旋律由 PhoneShell 全局播放）
 */
export function ControlCenter({ state }: ControlCenterProps) {
  const open = state.ui.controlCenterOpen;
  const [headphoneFalling, setHeadphoneFalling] = useState(false);
  const [resetConfirmOpen, setResetConfirmOpen] = useState(false);
  const sliderRef = useRef<HTMLDivElement | null>(null);
  const sliderPointerRef = useRef<number | null>(null);

  useEffect(() => {
    if (!open) {
      setHeadphoneFalling(false);
      setResetConfirmOpen(false);
    }
  }, [open]);

  if (!open) {
    return null;
  }

  function close() {
    kit.flags.setUi("controlCenterOpen", false);
  }

  function setNetwork(mode: "campus_wifi" | "cellular") {
    if (state.networkMode === mode) {
      return;
    }
    playSfx("13_");
    kit.network.setMode(mode);
    kit.battery.consumeForNetworkSwitch();
    kit.flags.toast(
      mode === "campus_wifi"
        ? "已连接 ZJUWLAN，网络切换消耗 1% 电量。"
        : "已切换到移动数据，网络切换消耗 1% 电量。"
    );
  }

  function toggleMusic() {
    if (state.phoneBattery.lowPowerMode && !state.ui.musicPlaying) {
      playSfx("03_");
      kit.flags.toast("低电量模式下音乐已暂停。关闭低电量模式后可以播放。", "task");
      return;
    }
    playSfx("02_");
    const next = !state.ui.musicPlaying;
    kit.flags.setUi("musicPlaying", next);
  }

  function grabHeadphone() {
    if (!state.ui.musicPlaying) {
      playSfx("03_");
      kit.flags.toast("耳机安静地挂着，不理你。");
      return;
    }
    if (headphoneFalling || state.flags.headphoneFallen) {
      return;
    }
    setHeadphoneFalling(true);
    playSfx("15_");
    window.setTimeout(() => {
      kit.flags.setFlag("headphoneFallen", true);
      kit.inventory.addItem("headphone", state.currentScene);
      kit.flags.toast("耳机掉了下来，背面朝下。", "task");
    }, 550);
  }

  function updateBrightness(clientY: number) {
    const el = sliderRef.current;
    if (!el) {
      return;
    }
    const rect = el.getBoundingClientRect();
    const ratio = 1 - (clientY - rect.top) / rect.height;
    const maxBrightness = state.phoneBattery.lowPowerMode ? 45 : 100;
    const value = Math.round(Math.max(0, Math.min(maxBrightness, ratio * 100)));
    kit.flags.setUi("brightness", value);
  }

  function onSliderPointerDown(e: React.PointerEvent) {
    sliderPointerRef.current = e.pointerId;
    try {
      (e.currentTarget as HTMLElement).setPointerCapture?.(e.pointerId);
    } catch {
      // Pointer capture can be unavailable in older WebKit or synthetic events.
    }
    updateBrightness(e.clientY);
    e.preventDefault();
  }

  function onSliderPointerMove(e: React.PointerEvent) {
    if (sliderPointerRef.current === e.pointerId) {
      updateBrightness(e.clientY);
      e.preventDefault();
    }
  }

  function finishSliderPointer(e: React.PointerEvent, playFeedback: boolean) {
    if (sliderPointerRef.current !== e.pointerId) return;
    sliderPointerRef.current = null;
    try {
      (e.currentTarget as HTMLElement).releasePointerCapture?.(e.pointerId);
    } catch {
      // The browser may already have released the pointer.
    }
    if (playFeedback) playSfx("14_", { volume: 0.6 });
  }

  function onSliderPointerUp(e: React.PointerEvent) {
    finishSliderPointer(e, true);
  }

  function onSliderPointerCancel(e: React.PointerEvent) {
    finishSliderPointer(e, false);
  }

  function toggleAutoRotate() {
    const next = !state.ui.autoRotate;
    playSfx("16_");
    kit.flags.setUi("autoRotate", next);
    kit.flags.toast(next ? "自动旋转已开启。" : "自动旋转已关闭。");
  }

  function saveNow() {
    playSfx("02_");
    kit.flags.toast(kit.save.saveNow() ? "进度已保存。" : "存档写入失败，请检查浏览器存储权限。", "task");
  }

  function resetProgress() {
    playSfx("03_");
    kit.save.resetProgress();
  }

  function toggleLowPowerMode() {
    playSfx("02_");
    kit.battery.setLowPowerMode(!state.phoneBattery.lowPowerMode);
  }

  const brightness = state.ui.brightness;
  const batteryPercent = state.phoneBattery.percent;

  return (
    <div className="cc-overlay" role="dialog" aria-modal="true" aria-label="控制中心">
      <button type="button" className="cc-backdrop" aria-label="关闭控制中心" onClick={close} />
      <section className="cc-panel">
        <header className="cc-header">
          <strong>7月9日 周四</strong>
          <button type="button" className="cc-close" onClick={close} aria-label="收起">
            ×
          </button>
        </header>

        <div className="cc-quick">
          <button
            type="button"
            className={`cc-card ${state.networkMode === "campus_wifi" ? "is-active" : ""}`}
            onClick={() => setNetwork("campus_wifi")}
            aria-pressed={state.networkMode === "campus_wifi"}
          >
            <span className="cc-bubble cc-wifi-icon" aria-hidden="true">
              <i />
              <i />
              <i />
            </span>
            <span className="cc-card-text">
              <strong>ZJUWLAN</strong>
              <em>{state.networkMode === "campus_wifi" ? "已连接" : "未连接"}</em>
            </span>
          </button>
          <button
            type="button"
            className={`cc-card ${state.networkMode === "cellular" ? "is-active" : ""}`}
            onClick={() => setNetwork("cellular")}
            aria-pressed={state.networkMode === "cellular"}
          >
            <span className="cc-bubble cc-data-icon" aria-hidden="true">
              <i />
              <i />
              <i />
              <i />
            </span>
            <span className="cc-card-text">
              <strong>移动数据</strong>
              <em>{state.networkMode === "cellular" ? "使用中" : "已关闭"}</em>
            </span>
          </button>
        </div>

        <div className="cc-middle">
          <div className="cc-music">
            <div className="cc-music-head">
              <PixelIcon name="music" size={30} />
              <strong>{state.ui.musicPlaying ? "正在播放：早八进行曲" : "未在播放"}</strong>
            </div>
            <div className="cc-music-row">
              <button type="button" className="cc-play" onClick={toggleMusic} aria-label={state.ui.musicPlaying ? "暂停" : "播放音乐"}>
                {state.ui.musicPlaying ? "❚❚" : "▶"}
              </button>
              {!state.flags.headphoneFallen ? (
                <button
                  type="button"
                  className={`cc-headphone ${state.ui.musicPlaying ? "is-shaking" : ""} ${headphoneFalling ? "is-falling" : ""}`}
                  onClick={grabHeadphone}
                  aria-label="耳机"
                >
                  <PixelIcon name="headphone" size={32} />
                </button>
              ) : (
                <span className="cc-headphone-gone">耳机不见了</span>
              )}
            </div>
          </div>

          <div
            ref={sliderRef}
            className="cc-slider"
            role="slider"
            aria-label="亮度"
            aria-valuenow={brightness}
            aria-valuemin={0}
            aria-valuemax={state.phoneBattery.lowPowerMode ? 45 : 100}
            tabIndex={0}
            onPointerDown={onSliderPointerDown}
            onPointerMove={onSliderPointerMove}
            onPointerUp={onSliderPointerUp}
            onPointerCancel={onSliderPointerCancel}
            onLostPointerCapture={() => {
              sliderPointerRef.current = null;
            }}
            onKeyDown={(e) => {
              if (e.key === "ArrowUp") {
                const maxBrightness = state.phoneBattery.lowPowerMode ? 45 : 100;
                kit.flags.setUi("brightness", Math.min(maxBrightness, brightness + 10));
              }
              if (e.key === "ArrowDown") {
                kit.flags.setUi("brightness", Math.max(0, brightness - 10));
              }
            }}
          >
            <div className="cc-slider-fill" style={{ height: `${brightness}%` }} />
            <span className="cc-slider-icon">
              <PixelIcon name="sun" size={26} />
            </span>
          </div>
        </div>

        <div className="cc-toggles">
          <button
            type="button"
            className={`cc-toggle ${state.ui.autoRotate ? "is-on" : ""}`}
            onClick={toggleAutoRotate}
            aria-pressed={state.ui.autoRotate}
          >
            <i className="cc-toggle-icon rotate" aria-hidden="true">
              ⟳
            </i>
            <span>自动旋转</span>
          </button>
          <button type="button" className="cc-toggle is-on" onClick={() => kit.flags.toast("振动一直开着。它见证了闹钟的一切。")}>
            <i className="cc-toggle-icon" aria-hidden="true">
              ≋
            </i>
            <span>振动</span>
          </button>
          <button type="button" className="cc-toggle" onClick={() => kit.flags.toast("飞行模式？你连教室都飞不到。")}>
            <i className="cc-toggle-icon" aria-hidden="true">
              ✈
            </i>
            <span>飞行模式</span>
          </button>
          <button type="button" className="cc-toggle" onClick={() => kit.flags.toast("勿扰模式无法阻挡早八。")}>
            <i className="cc-toggle-icon" aria-hidden="true">
              ☾
            </i>
            <span>勿扰</span>
          </button>
        </div>

        <section
          className={`cc-power ${state.phoneBattery.lowPowerMode ? "is-saving" : ""} ${batteryPercent <= 5 ? "is-critical" : ""}`}
          aria-label="电量管理"
        >
          <header>
            <div>
              <strong>电池 {batteryPercent}%</strong>
              <span>打开应用：{state.phoneBattery.lowPowerMode ? "1%" : "2%"} / 次</span>
            </div>
            <i aria-hidden="true">BAT</i>
          </header>
          <div
            className="cc-power-meter"
            role="meter"
            aria-label="手机电量"
            aria-valuemin={1}
            aria-valuemax={100}
            aria-valuenow={batteryPercent}
          >
            <i style={{ width: `${batteryPercent}%` }} />
          </div>
          <button
            type="button"
            className={`cc-low-power ${state.phoneBattery.lowPowerMode ? "is-on" : ""}`}
            onClick={toggleLowPowerMode}
            aria-pressed={state.phoneBattery.lowPowerMode}
          >
            <strong>{state.phoneBattery.lowPowerMode ? "关闭低电量模式" : "开启低电量模式"}</strong>
            <span>{state.phoneBattery.lowPowerMode ? "恢复每次 2% 耗电" : "每次只耗 1%；亮度限至 45%，暂停音乐"}</span>
          </button>
          <p className="cc-power-location">
            {state.rpgScene === "theater_interior"
              ? "剧场入口左侧设有充电服务站，需走到设备旁接线。"
              : "充电需要在现场与充电服务站交互。"}
          </p>
          {batteryPercent === 1 ? (
            <p className="cc-power-reserve" role="status">1% 为任务保底电量，主线功能仍可使用。</p>
          ) : null}
        </section>

        <section className="cc-save-manager" aria-label="存档管理">
          <header>
            <div>
              <strong>游戏进度</strong>
              <span>自动保存已开启</span>
            </div>
            <i aria-hidden="true">SAVE</i>
          </header>
          {!resetConfirmOpen ? (
            <div className="cc-save-actions">
              <button type="button" onClick={saveNow}>立即保存</button>
              <button type="button" className="is-danger" onClick={() => setResetConfirmOpen(true)}>重置剧情进度</button>
            </div>
          ) : (
            <div className="cc-reset-confirm" role="alert">
              <p>将清除章节、道具和谜题进度。编辑过的 CC98 帖子会保留。</p>
              <button type="button" onClick={() => setResetConfirmOpen(false)}>取消</button>
              <button type="button" className="is-danger" onClick={resetProgress}>确认重置</button>
            </div>
          )}
        </section>
      </section>
    </div>
  );
}
