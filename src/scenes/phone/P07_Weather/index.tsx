import { useState, type CSSProperties } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { selectCampusWeather } from "../../../modules/CampusWeatherModel";
import { kit } from "../../../modules/GameKit";
import {
  getQizhenWeatherAlignedBandCount,
  isQizhenWeatherCloudAligned,
  moveQizhenWeatherCloud,
  QIZHEN_WEATHER_CLOUD_INITIAL,
  QIZHEN_WEATHER_CLOUD_TARGET,
  type QizhenWeatherCloudOffsets
} from "../../../modules/QizhenWeatherControlModel";

const WEATHER_CLOUD_BANDS = ["低层", "中层", "高层"] as const;

/** Shared weather app for the chapter-two water clue and the Qizhen Lake safety workflow. */
export function WeatherScene({ state, router }: SceneComponentProps) {
  const [controlStarted, setControlStarted] = useState(false);
  const [cloudOffsets, setCloudOffsets] = useState<QizhenWeatherCloudOffsets>(QIZHEN_WEATHER_CLOUD_INITIAL);
  const [controlMoves, setControlMoves] = useState(0);
  const collected = state.actOne.weatherWaterTaken;
  const waterAvailable = state.actOne.exerciseStarted;
  const weather = selectCampusWeather(state);
  const qizhenWeatherContext = state.qizhenLake.active
    && !["inactive", "location_search", "lake_unlocked"].includes(state.qizhenLake.phase);
  const adjustmentRequested = state.qizhenLake.weatherAdjustmentRequested;
  const adjustmentComplete = state.qizhenLake.rainSafetyCleared;
  const adjustmentAvailable = state.qizhenLake.phase === "boarding_tutorial"
    && adjustmentRequested
    && !adjustmentComplete;

  function collectWater() {
    if (!kit.actOne.collectWeatherWater()) {
      kit.flags.toast("现在没有需要带走的水。", "system");
      return;
    }
  }

  const alignedBandCount = getQizhenWeatherAlignedBandCount(cloudOffsets);
  const cloudControlAligned = isQizhenWeatherCloudAligned(cloudOffsets);

  function startQizhenWeatherControl() {
    const result = kit.qizhenLake.beginDockWeatherAdjustment();
    if (result === "accepted") {
      setCloudOffsets(QIZHEN_WEATHER_CLOUD_INITIAL);
      setControlMoves(0);
      setControlStarted(true);
      return;
    }
    if (result === "already_complete") {
      kit.flags.toast("湖区状态已经更新。", "system");
      return;
    }
    if (result === "locked") {
      kit.flags.toast("当前没有待处理的湖区记录。", "system");
      return;
    }
    kit.flags.toast("当前无法开始校准。", "system");
  }

  function shiftCloudBand(bandIndex: number, direction: -1 | 1) {
    setCloudOffsets((current) => moveQizhenWeatherCloud(current, bandIndex, direction));
    setControlMoves((current) => current + 1);
  }

  function submitQizhenWeatherControl() {
    if (!cloudControlAligned) {
      kit.flags.toast("三层云带还没有对齐。", "system");
      return;
    }
    const result = kit.qizhenLake.applyDockWeatherAdjustment({
      moves: controlMoves,
      cloudOffsets
    });
    if (result === "accepted") {
      setControlStarted(false);
      kit.flags.toast("湖区状态已更新。", "task");
      return;
    }
    if (result === "already_complete") {
      setControlStarted(false);
      kit.flags.toast("湖区状态已经更新。", "system");
      return;
    }
    kit.flags.toast("校准记录无效，请重新对齐。", "system");
  }

  return (
    <section className="app-screen act2-weather-page" aria-label="天气">
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
            ? adjustmentComplete ? "返回码头确认" : adjustmentRequested ? "查看湖区记录" : "暂不适合下水"
            : "处理黏着物"}</strong></article>
        </section>

        {qizhenWeatherContext ? (
          controlStarted && adjustmentAvailable ? (
            <section className="qizhen-weather-calibration" aria-label="湖区云层校准">
              <header>
                <div><strong>云层校准</strong><span>把三层云带移入虚线框</span></div>
                <output aria-live="polite">{alignedBandCount}/3 · {controlMoves} 步</output>
              </header>
              <div className="qizhen-weather-bands">
                {WEATHER_CLOUD_BANDS.map((label, index) => (
                  <div className="qizhen-weather-band" key={label}>
                    <span>{label}</span>
                    <button type="button" aria-label={`${label}云带向左移动`} onClick={() => shiftCloudBand(index, -1)}>‹</button>
                    <div className="qizhen-weather-track" aria-hidden="true">
                      <i
                        className="qizhen-weather-target"
                        style={{ "--cloud-slot": QIZHEN_WEATHER_CLOUD_TARGET[index] } as CSSProperties}
                      />
                      <b
                        className={cloudOffsets[index] === QIZHEN_WEATHER_CLOUD_TARGET[index] ? "is-aligned" : ""}
                        style={{ "--cloud-slot": cloudOffsets[index] } as CSSProperties}
                      ><em /><em /><em /></b>
                    </div>
                    <button type="button" aria-label={`${label}云带向右移动`} onClick={() => shiftCloudBand(index, 1)}>›</button>
                  </div>
                ))}
              </div>
              <button
                type="button"
                className="qizhen-weather-submit"
                disabled={!cloudControlAligned}
                onClick={submitQizhenWeatherControl}
              >提交云图</button>
            </section>
          ) : (
            <button
              type="button"
              className={`qizhen-weather-control ${adjustmentComplete ? "is-complete" : ""}`}
              aria-label={adjustmentComplete ? "湖区状态已更新" : adjustmentAvailable ? "开始湖区云层校准" : "湖区记录尚未开放"}
              disabled={!adjustmentAvailable}
              onClick={startQizhenWeatherControl}
            >
              <i aria-hidden="true" />
              <strong>{adjustmentComplete ? "湖区状态已更新" : adjustmentRequested ? "校准湖区云图" : "暂无湖区记录"}</strong>
              <span>{adjustmentComplete
                ? `返回码头确认${state.qizhenLake.weatherControlBestMoves > 0 ? ` · 最少 ${state.qizhenLake.weatherControlBestMoves} 步` : ""}`
                : adjustmentRequested
                  ? "对齐低、中、高三层云带"
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
