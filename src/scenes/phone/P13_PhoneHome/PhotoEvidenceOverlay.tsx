import { useEffect, useRef, useState, type CSSProperties } from "react";
import library022ReflectionUrl from "../../../assets/ui/photo-evidence/library_022_reflection.webp";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import { PhoneActionSheet, PhoneSegmentedControl } from "../../../components/PhoneAppUi";
import {
  LIBRARY_CLUE_PHOTO_ID,
  selectLibraryRollPhotos
} from "../../../data/phonePhotoCatalog";
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

const LIBRARY_ROLL_PHOTOS = selectLibraryRollPhotos();

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
  const [selectedRollPhotoId, setSelectedRollPhotoId] = useState<string | null>(null);
  const selectedRollPhotoTriggerRef = useRef<HTMLButtonElement | null>(null);
  const [rollFilter, setRollFilter] = useState<"recent" | "campus_life">("recent");
  const shutterTimerRef = useRef<number | null>(null);
  const readable = available && captured && brightness <= 20 && dimmed;
  const selectedRollPhoto = LIBRARY_ROLL_PHOTOS.find((photo) => photo.id === selectedRollPhotoId) ?? null;
  const visibleRollPhotos = rollFilter === "campus_life"
    ? LIBRARY_ROLL_PHOTOS.filter((photo) => photo.albumId === "campus_life")
    : LIBRARY_ROLL_PHOTOS;
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
            <img
              className="photo-evidence-illustration"
              src={library022ReflectionUrl}
              alt=""
              aria-hidden="true"
            />
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
            <strong>{reportGenerated ? "物品识别报告已生成" : "旧相册里还有一张同场景照片"}</strong>
            {!reportGenerated ? <p>找到同一只 022 书包的旧照，核对半包纸出现的时间。</p> : null}
            <button type="button" disabled={reportGenerated} onClick={(event) => {
              selectedRollPhotoTriggerRef.current = event.currentTarget;
              setRollFilter("recent");
              setSelectedRollPhotoId(LIBRARY_CLUE_PHOTO_ID);
            }}>
              {reportGenerated ? "已写入报告" : "查看 022 旧照"}
            </button>
          </section>
        ) : null}

        {captured && !shutterAnimating ? <PhoneSegmentedControl
          className="photo-roll-filter"
          label="照片筛选"
          value={rollFilter}
          options={[
            { value: "recent", label: `最近 ${LIBRARY_ROLL_PHOTOS.length} 张` },
            { value: "campus_life", label: "校园与日常" }
          ]}
          onChange={(value) => {
            setRollFilter(value);
            setSelectedRollPhotoId(null);
          }}
        /> : null}

        {captured && !shutterAnimating ? <section className="photo-joke-grid" aria-label={rollFilter === "campus_life" ? "校园与日常照片" : "最近照片"}>
          {visibleRollPhotos.map((photo) => (
            <button
              key={photo.id}
              type="button"
              className={selectedRollPhotoId === photo.id ? "is-selected" : ""}
              aria-label={`预览 ${photo.title}`}
              aria-pressed={selectedRollPhotoId === photo.id}
              onClick={(event) => {
                selectedRollPhotoTriggerRef.current = event.currentTarget;
                setSelectedRollPhotoId(photo.id);
              }}
            >
              <img src={photo.imageUrl} alt="" aria-hidden="true" />
              <span>{photo.file.slice(4, 8)}</span>
            </button>
          ))}
        </section> : null}
        {captured && !shutterAnimating ? (
          <p className="photo-joke-caption">
            {rollFilter === "campus_life"
              ? "6 张校园与日常照片。它们只用于补足相册内容，不参与证据判定。"
              : `${LIBRARY_ROLL_PHOTOS.length} 张最近照片。点开可以查看细节。`}
          </p>
        ) : null}
      </main>
      {selectedRollPhoto ? (
        <PhoneActionSheet
          title={selectedRollPhoto.title}
          description={`${selectedRollPhoto.file} · ${selectedRollPhoto.location}`}
          className={`photo-roll-sheet ${selectedRollPhoto.storyRole === "library_clue" ? "is-clue" : ""}`}
          onClose={() => setSelectedRollPhotoId(null)}
          returnFocusElement={selectedRollPhotoTriggerRef.current}
        >
          <img className="photo-roll-sheet__image" src={selectedRollPhoto.imageUrl} alt={`${selectedRollPhoto.title}，${selectedRollPhoto.detail}`} />
          <p className="photo-roll-sheet__detail">{selectedRollPhoto.capturedAt} · {selectedRollPhoto.detail}</p>
          {selectedRollPhoto.storyRole === "library_clue" ? (
            <div className="photo-roll-clue-action">
              <span>{readable ? "旧照与刚拍下的标签内容一致。" : "先把刚拍下的主照片亮度降到 20% 以下。"}</span>
              <button type="button" disabled={!readable || reportGenerated} onClick={onGenerate}>
                {reportGenerated ? "已写入物品报告" : "用旧照补全物品报告"}
              </button>
            </div>
          ) : null}
        </PhoneActionSheet>
      ) : null}
    </section>
  );
}
