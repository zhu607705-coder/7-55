import { useEffect, useRef } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import "../../../styles/library-v2-phone.css";

interface PhotoEvidenceOverlayProps {
  available: boolean;
  brightness: number;
  dimmed: boolean;
  reportGenerated: boolean;
  onBrightnessChange: (value: number) => void;
  onGenerate: () => void;
  onClose: () => void;
}

/** IMG_0755.JPG 只展示识别状态；亮度与报告进度由共享状态持有。 */
export function PhotoEvidenceOverlay({
  available,
  brightness,
  dimmed,
  reportGenerated,
  onBrightnessChange,
  onGenerate,
  onClose
}: PhotoEvidenceOverlayProps) {
  const closeRef = useRef<HTMLButtonElement>(null);
  const readable = available && brightness <= 20 && dimmed;

  useEffect(() => {
    closeRef.current?.focus();
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        onClose();
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  return (
    <section className="photo-evidence-layer photo-library-layer" aria-label="照片 IMG_0755.JPG">
      <header>
        <PhoneNavButton ref={closeRef} kind="close" label="关闭照片" onClick={onClose} />
        <h2>照片</h2>
        <span>08:07</span>
      </header>
      <main>
        <section className="photo-library-viewer">
          <header><strong>IMG_0755.JPG</strong><span>022 · 二楼南区</span></header>
          <div className={`photo-backpack-frame ${readable ? "is-readable" : ""}`} aria-label={readable ? "可读的书包标签" : "反光的书包标签"}>
            <div className="photo-library-desk" aria-hidden="true" />
            <div className="photo-library-backpack" aria-hidden="true"><i /><b>022</b></div>
            <section className="photo-bag-label">
              {readable ? (
                <>
                  <strong>书包标签</strong>
                  <span>高数教材 x1</span>
                  <span>水杯 x1　充电器 x1</span>
                  <span>半包纸 x1</span>
                  <b>姓名：未检测到</b>
                  <b>学号：未检测到</b>
                  <em>人格：加载失败</em>
                </>
              ) : <strong>标签反光，无法识别</strong>}
            </section>
            {!readable ? <span className="photo-glare" aria-hidden="true" /> : null}
          </div>

          <label className="photo-brightness-control">
            <span>识别亮度</span>
            <input
              type="range"
              min="0"
              max="100"
              value={brightness}
              aria-label="调整照片识别亮度"
              onChange={(event) => onBrightnessChange(Number(event.target.value))}
            />
            <strong>{brightness}%</strong>
          </label>
          <p className="photo-threshold-copy" aria-live="polite">
            {!available
              ? "还没有拍到 022 上的书包。"
              : readable
                ? "反光已消失，标签内容可读。"
                : "标签仍在反光。继续降低识别亮度，直到反光完全消失。"}
          </p>
        </section>

        {readable ? (
          <section className={`photo-recognition-result ${reportGenerated ? "is-generated" : ""}`}>
            <strong>{reportGenerated ? "物品识别报告已生成" : "未检测到可签到主体"}</strong>
            <p>{reportGenerated ? "报告已放入道具栏，可交给图书馆物品身份登记机。" : "检测到大量期末周怨气。是否生成识别报告？"}</p>
            <button type="button" disabled={reportGenerated} onClick={onGenerate}>
              {reportGenerated ? "已生成" : "生成识别报告"}
            </button>
          </section>
        ) : null}

        <section className="photo-joke-grid" aria-label="其他照片">
          {Array.from({ length: 6 }, (_, index) => <div key={index} className={index === 5 ? "is-plant" : "is-takeout"} aria-hidden="true"><i /></div>)}
        </section>
        <p className="photo-joke-caption">37 张外卖截图，以及一张没有开花的盆栽。</p>
      </main>
    </section>
  );
}
