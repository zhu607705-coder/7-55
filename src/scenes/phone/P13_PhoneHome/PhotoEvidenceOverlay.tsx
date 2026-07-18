import { useEffect, useRef, useState, type CSSProperties } from "react";
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
  const previousReadableRef = useRef(false);
  const revealTimerRef = useRef<number | null>(null);
  const [revealAnimating, setRevealAnimating] = useState(false);
  const readable = available && brightness <= 20 && dimmed;
  const revealProgress = available ? Math.max(0, Math.min(1, (72 - brightness) / 52)) : 0;
  const exposurePhase = !available
    ? "is-unavailable"
    : readable
      ? "is-readable"
      : brightness <= 56
        ? "is-scanning"
        : "is-overexposed";
  const frameStyle = {
    "--photo-contrast": (0.9 + revealProgress * 0.18).toFixed(2),
    "--photo-saturation": (0.72 + revealProgress * 0.3).toFixed(2),
    "--photo-glare-opacity": readable ? "0" : Math.max(0.08, 0.94 - revealProgress * 0.78).toFixed(2),
    "--photo-noise-opacity": readable ? "0.08" : (0.42 - revealProgress * 0.2).toFixed(2),
    "--photo-scan-y": `${Math.round(14 + revealProgress * 72)}%`
  } as CSSProperties;
  const controlStyle = { "--photo-level": `${brightness}%` } as CSSProperties;

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

  useEffect(() => {
    const wasReadable = previousReadableRef.current;
    previousReadableRef.current = readable;

    if (!readable) {
      setRevealAnimating(false);
      return;
    }
    if (wasReadable) return;

    setRevealAnimating(true);
    revealTimerRef.current = window.setTimeout(() => {
      revealTimerRef.current = null;
      setRevealAnimating(false);
    }, 1450);

    return () => {
      if (revealTimerRef.current !== null) {
        window.clearTimeout(revealTimerRef.current);
        revealTimerRef.current = null;
      }
    };
  }, [readable]);

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
          <div
            className={`photo-backpack-frame ${exposurePhase} ${revealAnimating ? "is-revealing" : ""}`}
            style={frameStyle}
            aria-label={readable ? "可读的书包标签" : "反光的书包标签"}
          >
            <div className="photo-library-desk" aria-hidden="true" />
            <div className="photo-library-backpack" aria-hidden="true"><i /><b>022</b></div>
            <span className="photo-frame-exposure" aria-hidden="true" />
            <span className="photo-pixel-noise" aria-hidden="true" />
            <section className={`photo-bag-label ${readable ? "is-readable" : ""}`}>
              <header className="photo-label-status" aria-hidden="true">
                <span>OCR</span>
                <b>{readable ? "LOCK" : "SCAN"}</b>
              </header>
              {readable ? (
                <div className="photo-label-content">
                  <strong>书包标签</strong>
                  <span>高数教材 x1</span>
                  <span>水杯 x1　充电器 x1</span>
                  <span>半包纸 x1</span>
                  <b>姓名：未检测到</b>
                  <b>学号：未检测到</b>
                  <em>人格：加载失败</em>
                </div>
              ) : (
                <div className="photo-label-obscured" aria-hidden="true">
                  <strong>标签反光，无法识别</strong>
                  <span /><span /><span /><span />
                </div>
              )}
            </section>
            <span className="photo-focus-corners" aria-hidden="true"><i /><i /><i /><i /></span>
            <span className="photo-glare" aria-hidden="true" />
            <span className="photo-scan-line" aria-hidden="true" />
            {revealAnimating ? (
              <span className="photo-decode-burst" aria-hidden="true">
                {Array.from({ length: 8 }, (_, index) => <i key={index} />)}
              </span>
            ) : null}
          </div>

          <label className="photo-brightness-control" style={controlStyle}>
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
                ? "识别稳定，标签内容已锁定。"
                : brightness <= 56
                  ? "标签边缘已出现，识别信号仍不稳定。"
                  : "高光覆盖标签，识别器无法对焦。"}
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
