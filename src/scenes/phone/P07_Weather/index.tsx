import type { CSSProperties } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { selectCampusWeather } from "../../../modules/CampusWeatherModel";
import { kit } from "../../../modules/GameKit";

/** Shared weather app for the chapter-two water clue and the Qizhen Lake safety workflow. */
export function WeatherScene({ state, router }: SceneComponentProps) {
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

  function adjustQizhenWeather() {
    const result = kit.qizhenLake.applyDockWeatherAdjustment();
    if (result === "accepted") {
      kit.flags.toast("启真湖小码头已调为多云。雨天禁航状态解除。", "task");
      return;
    }
    if (result === "already_complete") {
      kit.flags.toast("启真湖当前已经是多云。", "system");
      return;
    }
    if (result === "locked") {
      kit.flags.toast("安全员尚未提交天气调控申请。", "system");
      return;
    }
    kit.flags.toast("当前没有可执行的启真湖天气调控任务。", "system");
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
          <div className="act2-weather-cloud" aria-hidden="true"><i /><i /><i /></div>
          {weather.condition === "light_rain" ? (
            <div className="act2-weather-rain" aria-hidden="true">
              {Array.from({ length: 12 }, (_, index) => <i key={index} style={{ "--rain-index": index } as CSSProperties} />)}
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
            ? adjustmentComplete ? "可以前往小码头" : adjustmentRequested ? "可执行湖区调控" : "等待安全员申请"
            : "处理黏着物"}</strong></article>
        </section>

        {qizhenWeatherContext ? (
          <button
            type="button"
            className={`qizhen-weather-control ${adjustmentComplete ? "is-complete" : ""}`}
            aria-label={adjustmentComplete ? "启真湖天气已调整为多云" : "执行启真湖小码头天气调控"}
            disabled={!adjustmentAvailable}
            onClick={adjustQizhenWeather}
          >
            <i aria-hidden="true" />
            <strong>{adjustmentComplete ? "启真湖已调整为多云" : adjustmentRequested ? "执行湖区天气调控" : "等待安全员提交申请"}</strong>
            <span>{adjustmentComplete
              ? "雨天禁航状态已解除"
              : adjustmentRequested
                ? "调控范围：启真湖小码头"
                : "器材核对完成后才会开放调控"}</span>
          </button>
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
