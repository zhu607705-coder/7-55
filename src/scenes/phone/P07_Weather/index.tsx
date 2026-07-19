import type { CSSProperties } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";

/** Reuses the home weather card as a full page for the chapter-two adhesive-water clue. */
export function WeatherScene({ state, router }: SceneComponentProps) {
  const collected = state.actOne.weatherWaterTaken;
  const waterAvailable = state.actOne.exerciseStarted;

  function collectWater() {
    if (!kit.actOne.collectWeatherWater()) {
      kit.flags.toast(collected ? "水滴已经在道具栏里。" : "现在没有需要带走的水。", "system");
      return;
    }
  }

  return (
    <section className="app-screen act2-weather-page" aria-label="天气">
      <header>
        <PhoneNavButton kind="exit" label="退出天气，返回手机主页" onClick={() => router.goTo("phone_home")} />
        <h1>杭州 · 紫金港</h1>
        <span>07:55</span>
      </header>

      <main>
        <section className="act2-weather-hero">
          <div className="act2-weather-cloud" aria-hidden="true"><i /><i /><i /></div>
          <div className="act2-weather-rain" aria-hidden="true">
            {Array.from({ length: 12 }, (_, index) => <i key={index} style={{ "--rain-index": index } as CSSProperties} />)}
          </div>
          <p>小雨</p>
          <strong>18<small>°C</small></strong>
          <span>体感温度 17°C</span>
        </section>

        <section className="act2-weather-grid" aria-label="天气详情">
          <article><span>湿度</span><strong>88%</strong></article>
          <article><span>风向</span><strong>西南风 2级</strong></article>
          <article><span>降水</span><strong>正在发生</strong></article>
          <article><span>建议</span><strong>处理黏着物</strong></article>
        </section>

        <button
          type="button"
          className={`act2-weather-drop ${collected ? "is-collected" : ""}`}
          aria-label={collected ? "天气水滴已收集" : waterAvailable ? "收集天气水滴" : "天气水滴尚未开放"}
          disabled={!waterAvailable && !collected}
          onClick={collectWater}
        >
          <i aria-hidden="true" />
          <strong>{collected ? "水滴已收集" : waterAvailable ? "接住一滴水" : "先开始课外锻炼"}</strong>
          <span>{collected ? "它正在道具栏里等着被使用" : waterAvailable ? "这滴水看起来比天气预报更有用" : "锻炼记录同步后，这里的雨滴会变得可取"}</span>
        </button>
      </main>
    </section>
  );
}
