import { useEffect, useRef, useState, type CSSProperties } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import "../../../styles/library-v2-phone.css";

interface PhotoEvidenceOverlayProps {
  available: boolean;
  brightness: number;
  captured: boolean;
  dimmed: boolean;
  reportGenerated: boolean;
  onCapture: () => boolean;
  onGenerate: () => void;
  onClose: () => void;
}

/** IMG_0755.JPG 只展示识别状态；亮度与报告进度由共享状态持有。 */
export function PhotoEvidenceOverlay({
  available,
  brightness,
  captured,
  dimmed,
  reportGenerated,
  onCapture,
  onGenerate,
  onClose
}: PhotoEvidenceOverlayProps) {
  const closeRef = useRef<HTMLButtonElement>(null);
  const previousReadableRef = useRef(false);
  const revealTimerRef = useRef<number | null>(null);
  const [revealAnimating, setRevealAnimating] = useState(false);
  const [shutterAnimating, setShutterAnimating] = useState(false);
  const shutterTimerRef = useRef<number | null>(null);
  const readable = available && captured && brightness <= 20 && dimmed;
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

  useEffect(() => () => {
    if (shutterTimerRef.current !== null) window.clearTimeout(shutterTimerRef.current);
  }, []);

  function capture() {
    if (shutterAnimating || captured || !available || !onCapture()) return;
    setShutterAnimating(true);
    shutterTimerRef.current = window.setTimeout(() => {
      shutterTimerRef.current = null;
      setShutterAnimating(false);
    }, 360);
  }

  return (
    <section className="photo-evidence-layer photo-library-layer" aria-label="照片 IMG_0755.JPG">
      <header>
        <PhoneNavButton ref={closeRef} kind="close" label="关闭照片" onClick={onClose} />
        <h2>照片</h2>
        <span>08:07</span>
      </header>
      <main>
        {!captured || shutterAnimating ? (
          <section className="photo-camera-capture" aria-label="022书包拍摄界面">
            <header><strong>对准 022 书包</strong><span>保持画面居中</span></header>
            <div className="photo-camera-frame">
              <div className="photo-library-desk" aria-hidden="true" />
              <div className="photo-library-backpack" aria-hidden="true"><i /><b>022</b></div>
              <span className="photo-camera-reticle" aria-hidden="true"><i /><i /><i /><i /></span>
            </div>
            <p>{available ? "目标已对准，点击快门。" : "还没有在 022 现场确认书包。"}</p>
            <button type="button" className="photo-shutter-button" disabled={!available || shutterAnimating} aria-label="拍摄 022 书包" onClick={capture}>
              <span aria-hidden="true" />
            </button>
            {shutterAnimating ? <span className="photo-shutter-flash" aria-hidden="true" /> : null}
          </section>
        ) : (
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

          <div className="photo-shared-brightness" role="status">
            <span>控制中心亮度</span>
            <strong>{brightness}%</strong>
            <small>照片直接读取系统亮度</small>
          </div>
          <p className="photo-threshold-copy" aria-live="polite">
            {!available
              ? "还没有拍到 022 上的书包。"
              : readable
                ? "识别稳定，标签内容已锁定。"
                : brightness <= 56
                  ? "标签边缘已出现，识别信号仍不稳定。"
                  : "光照太亮了，识别器无法对焦。"}
          </p>
        </section>
        )}

        {captured && !shutterAnimating && readable ? (
          <section className={`photo-recognition-result ${reportGenerated ? "is-generated" : ""}`}>
            <strong>{reportGenerated ? "物品识别报告已生成" : "未检测到可签到主体"}</strong>
            {!reportGenerated ? <p>检测到大量期末周怨气。是否生成识别报告？</p> : null}
            <button type="button" disabled={reportGenerated} onClick={onGenerate}>
              {reportGenerated ? "已生成" : "生成识别报告"}
            </button>
          </section>
        ) : null}

        {captured && !shutterAnimating ? <section className="photo-joke-grid" aria-label="其他照片">
          {Array.from({ length: 6 }, (_, index) => <div key={index} className={index === 5 ? "is-plant" : "is-takeout"} aria-hidden="true"><i /></div>)}
        </section> : null}
        {captured && !shutterAnimating ? <p className="photo-joke-caption">37 张外卖截图，以及一张没有开花的盆栽。</p> : null}
      </main>
    </section>
  );
}
