import { useEffect, useState, type CSSProperties } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { selectCampusWeather } from "../../../modules/CampusWeatherModel";
import { kit } from "../../../modules/GameKit";
import type { QizhenWeatherControlSummary } from "../../../modules/QizhenWeatherControlModel";
import { QizhenWeatherCalibration } from "./QizhenWeatherCalibration";

/** Shared weather app for the chapter-two water clue and the Qizhen Lake safety workflow. */
export function WeatherScene({ state, router, events }: SceneComponentProps) {
  const [controlStarted, setControlStarted] = useState(false);
  const [deviceFeedback, setDeviceFeedback] = useState<string | null>(null);
  const collected = state.actOne.weatherWaterTaken;
  const waterAvailable = state.actOne.exerciseStarted;
  const weather = selectCampusWeather(state);
  const qizhenWeatherContext = state.qizhenLake.active
    && !["inactive", "location_search", "lake_unlocked"].includes(state.qizhenLake.phase);
  const adjustmentRequested = state.qizhenLake.weatherAdjustmentRequested;
  const adjustmentComplete = state.qizhenLake.rainSafetyCleared;
  const hasHairDryer = state.items.hairDryer;
  const adjustmentAvailable = state.qizhenLake.phase === "rain_recovery"
    && state.qizhenLake.rainRescueCompleted
    && adjustmentRequested
    && hasHairDryer
    && !adjustmentComplete;

  function collectWater() {
    if (!kit.actOne.collectWeatherWater()) {
      kit.flags.toast("现在没有需要带走的水。", "system");
      return;
    }
  }

  function startQizhenWeatherControl() {
    const result = kit.qizhenLake.beginDockWeatherAdjustment();
    if (result === "accepted") {
      setDeviceFeedback(null);
      kit.flags.setUi("selectedItem", null);
      kit.flags.setUi("inventoryOpen", false);
      setControlStarted(true);
      return;
    }
    if (result === "already_complete") {
      kit.flags.toast("湖区状态已经更新。", "system");
      return;
    }
    if (result === "locked") {
      kit.flags.toast(hasHairDryer ? "当前没有待处理的湖区记录。" : "先从寝室书桌拿到吹风机。", "system");
      return;
    }
    kit.flags.toast("当前无法开始校准。", "system");
  }

  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "qizhen-weather-clouds") {
        return;
      }
      if (event.payload?.item !== "hairDryer") {
        setDeviceFeedback("这件道具无法送风 · 请拖入寝室吹风机");
        return;
      }
      setDeviceFeedback(null);
      startQizhenWeatherControl();
    });
  }, [events, hasHairDryer]);

  function activateQizhenWeatherTarget() {
    if (state.ui.selectedItem === "hairDryer") {
      startQizhenWeatherControl();
      return;
    }
    if (state.ui.selectedItem) {
      setDeviceFeedback("当前道具无法送风 · 请改用寝室吹风机");
      return;
    }
    kit.flags.setUi("inventoryOpen", true);
    setDeviceFeedback("道具栏已展开 · 拖入吹风机，键盘可按空格选中");
  }

  function submitQizhenWeatherControl(summary: QizhenWeatherControlSummary): boolean {
    const result = kit.qizhenLake.applyDockWeatherAdjustment(summary);
    if (result === "accepted") {
      setControlStarted(false);
      kit.flags.toast("湖区状态已更新。", "task");
      return true;
    }
    if (result === "already_complete") {
      setControlStarted(false);
      kit.flags.toast("湖区状态已经更新。", "system");
      return true;
    }
    kit.flags.toast("校准记录无效，请重新对齐。", "system");
    return false;
  }

  return (
    <section className={`app-screen act2-weather-page ${controlStarted ? "is-calibrating" : ""}`} aria-label="天气">
      <header>
        <PhoneNavButton kind="exit" label="退出天气，返回手机主页" onClick={() => router.goTo("phone_home")} />
        <h1>杭州 · 紫金港</h1>
        <span>07:55</span>
      </header>

      <main>
        <section className={`act2-weather-hero ${weather.condition === "overcast" ? "is-overcast" : ""}`}>
          <div className="act2-weather-cloud" aria-hidden="true">
            {Array.from({ length: 7 }, (_, index) => <i key={index} />)}
          </div>
          {weather.condition === "light_rain" ? (
            <div className="act2-weather-rain" aria-hidden="true">
              {Array.from({ length: 18 }, (_, index) => (
                <i
                  key={index}
                  style={{
                    "--rain-index": index,
                    "--rain-left": `${(index * 19 + index % 3 * 7) % 292}px`,
                    "--rain-length": `${12 + index % 4 * 4}px`
                  } as CSSProperties}
                />
              ))}
            </div>
          ) : null}
          <p>{weather.label}</p>
          <strong>{weather.condition === "light_rain" ? 18 : 19}<small>°C</small></strong>
          <span>体感温度 {weather.condition === "light_rain" ? 17 : 19}°C</span>
        </section>

        <section className="act2-weather-grid" aria-label="天气详情">
          <article><span>湿度</span><strong>{weather.condition === "light_rain" ? "88%" : "76%"}</strong></article>
          <article><span>风向</span><strong>西南风 2级</strong></article>
          <article><span>降水</span><strong>{weather.condition === "light_rain" ? "正在发生" : "已经停止"}</strong></article>
          <article><span>建议</span><strong>{qizhenWeatherContext
            ? adjustmentComplete ? "返回码头确认" : adjustmentRequested ? hasHairDryer ? "处理湖区云图" : "暂不适合下水" : "暂不适合下水"
            : "处理黏着物"}</strong></article>
        </section>

        {qizhenWeatherContext ? (
          controlStarted && adjustmentAvailable ? (
            <QizhenWeatherCalibration onComplete={submitQizhenWeatherControl} />
          ) : (
            <button
              type="button"
              className={`qizhen-weather-control ${adjustmentComplete ? "is-complete" : adjustmentAvailable ? "is-awaiting-item" : ""} ${deviceFeedback ? "has-device-feedback" : ""}`}
              data-drop-target={adjustmentAvailable ? "qizhen-weather-clouds" : undefined}
              aria-label={adjustmentComplete
                ? "湖区状态已更新"
                : adjustmentAvailable
                  ? "吹风机校准接口，从道具栏拖入寝室吹风机；键盘可先选中吹风机后确认此接口"
                  : "湖区记录尚未开放"}
              disabled={!adjustmentAvailable}
              onClick={activateQizhenWeatherTarget}
            >
              {adjustmentComplete ? (
                <i aria-hidden="true" />
              ) : (
                <span className="qizhen-weather-device-slot" aria-hidden="true"><b>+</b></span>
              )}
              <strong>{adjustmentComplete ? "湖区状态已更新" : adjustmentRequested ? hasHairDryer ? "接入寝室吹风机" : "缺少可用设备" : "暂无湖区记录"}</strong>
              <span>{adjustmentComplete
                ? `返回码头确认${state.qizhenLake.weatherControlBestMoves > 0 ? ` · 最少 ${state.qizhenLake.weatherControlBestMoves} 次校正` : ""}`
                : adjustmentRequested
                  ? hasHairDryer ? deviceFeedback ?? "从左侧道具栏拖到此接口" : "先检查寝室书桌"
                  : "完成码头检查后再查看"}</span>
            </button>
          )
        ) : (
          <button
            type="button"
            className={`act2-weather-drop ${collected ? "is-collected" : ""}`}
            aria-label={collected ? "天气水滴已收集" : waterAvailable ? "收集天气水滴" : "天气水滴尚未开放"}
            disabled={!waterAvailable && !collected}
            onClick={collectWater}
          >
            <i aria-hidden="true" />
            <strong>{collected ? "水滴已收集" : waterAvailable ? "接住一滴水" : "还没有开始外出打卡"}</strong>
            <span>{collected ? "它正在道具栏里等着被使用" : waterAvailable ? "这滴水看起来比天气预报更有用" : "你都还没有开始外出打卡，一滴雨都不会落到你身上。"}</span>
          </button>
        )}
      </main>
    </section>
  );
}
