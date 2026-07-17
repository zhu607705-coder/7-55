import { useEffect, useState } from "react";
import bonsaiBloomUrl from "../../../assets/ui/bonsai_bloom.png";
import bonsaiBudUrl from "../../../assets/ui/bonsai_bud.png";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { PixelIcon } from "../../../components/PixelIcon";
import { kit } from "../../../modules/GameKit";
import { playSfx } from "../../../modules/Sfx";

/**
 * P10 盆栽：把[盛水的耳机]/[一袋肥料]拖到盆栽上；亮度拉高后自动照光。
 * 三步平行完成 → 开花 → 点花吐出数字 8。
 */
export function BonsaiScene({ state, router, events }: SceneComponentProps) {
  const { flags } = state;
  const [eightVisible, setEightVisible] = useState(false);
  const bloomed = flags.flowerBloomed;
  const stage = kit.plant.growthStage();

  useEffect(() => {
    events.emit("enter_bonsai");
  }, [events]);

  // 亮度拉高后自动照光
  useEffect(() => {
    if (flags.plantLit || state.ui.brightness < 80) {
      return;
    }
    if (kit.plant.apply("light") === "done") {
      playSfx("23_");
      kit.flags.toast("已照光");
    }
  }, [state.ui.brightness, flags.plantLit]);

  // 物品拖到盆栽上
  useEffect(() => {
    return events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "bonsai") {
        return;
      }
      const item = event.payload?.item;

      if (item === "wateredHeadphone") {
        if (kit.plant.apply("water") === "done") {
          playSfx("22_");
          kit.inventory.removeItem("wateredHeadphone");
          kit.flags.toast("已浇水");
        } else {
          playSfx("04_", { volume: 0.5 });
        }
        return;
      }

      if (item === "fertilizer") {
        if (kit.plant.apply("fertilize") === "done") {
          playSfx("24_");
          kit.inventory.removeItem("fertilizer");
          kit.flags.toast("已施肥");
        } else {
          playSfx("04_", { volume: 0.5 });
        }
        return;
      }

      playSfx("04_", { volume: 0.5 });
      kit.flags.toast("没什么反应。");
    });
  }, [events]);

  function clickPlant() {
    if (bloomed && !flags.flowerEightTaken) {
      playSfx("02_");
      setEightVisible(true);
      kit.flags.shake();
      return;
    }
    if (flags.flowerEightTaken) {
      kit.flags.toast("花心空空的。");
      return;
    }
    kit.flags.toast("它绝对不会开花。");
  }

  function collectEight() {
    if (flags.flowerEightTaken) {
      return;
    }
    playSfx("10_");
    kit.digits.collectDigit(4, "8", "bonsai");
    kit.flags.setFlag("flowerEightTaken", true);
    setEightVisible(false);
    kit.flags.toast("获得第 4 位：8", "task");
  }

  const statusText = bloomed ? "开花了？！" : stage === 0 ? "它绝对不会开花" : "好像有点想开花";

  return (
    <section className={`app-screen bonsai-scene ${bloomed ? "is-bloomed" : ""}`} aria-label="盆栽">
      <div className="bonsai-stage" style={{ transform: `scale(${1 + stage * 0.045})` }}>
        <button
          type="button"
          className="bonsai-plant"
          data-drop-target="bonsai"
          aria-label={bloomed ? "盛开的盆栽" : "盆栽"}
          onClick={clickPlant}
        >
          <img className="app-bg bonsai-img" src={bloomed ? bonsaiBloomUrl : bonsaiBudUrl} alt="" aria-hidden="true" />
        </button>
      </div>

      <p className="bonsai-status px-chip">{statusText}</p>

      {eightVisible ? (
        <button type="button" className="flower-eight" aria-label="数字 8" onClick={collectEight}>
          8
        </button>
      ) : null}

      <div className="bonsai-actions" aria-hidden="true">
        <span className={`bonsai-act ${flags.plantWatered ? "is-done" : ""}`}>
          <PixelIcon name="waterDrop" size={30} />
        </span>
        <span className={`bonsai-act ${flags.plantLit ? "is-done" : ""}`}>
          <PixelIcon name="sun" size={30} />
        </span>
        <span className={`bonsai-act ${flags.plantFertilized ? "is-done" : ""}`}>
          <PixelIcon name="fertilizer" size={30} />
        </span>
      </div>

      <PhoneNavButton kind="exit" className="app-back px-btn paper" onClick={() => router.goTo("phone_home")} label="退出盆栽，返回手机主页" />
    </section>
  );
}
