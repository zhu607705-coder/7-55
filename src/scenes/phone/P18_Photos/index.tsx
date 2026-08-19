import { useEffect, useRef, useState } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import { QizhenRecipeFrame } from "../../../components/QizhenRecipeFrame";
import type { ChapterThreeInterludePhotoFrameId, QizhenPhotoRecord } from "../../../core/types";
import { kit } from "../../../modules/GameKit";
import { PhotoEvidenceOverlay } from "../P13_PhoneHome/PhotoEvidenceOverlay";
import lakeMemoryAUrl from "../../../assets/ui/photo-evidence/chapter35_live_lake_memory_a.webp";
import lakeMemoryBUrl from "../../../assets/ui/photo-evidence/chapter35_live_lake_memory_b.webp";
import paperLeftUrl from "../../../assets/ui/photo-evidence/chapter35_live_paper_left.webp";
import paperMiddleUrl from "../../../assets/ui/photo-evidence/chapter35_live_paper_middle.webp";
import paperRightUrl from "../../../assets/ui/photo-evidence/chapter35_live_paper_right.webp";

type RecoveredFrameId = ChapterThreeInterludePhotoFrameId
  | "lake_memory_a"
  | "lake_memory_b"
  | "mirrored_a"
  | "mirrored_b";

const RECOVERED_FRAMES: ReadonlyArray<{
  id: RecoveredFrameId;
  label: string;
  time: string;
  imageUrl: string;
  mirrored?: boolean;
}> = [
  { id: "lake_memory_a", label: "FRM 3A", time: "07:55:23", imageUrl: lakeMemoryAUrl },
  { id: "paper_middle", label: "FRM 91", time: "07:55:23", imageUrl: paperMiddleUrl },
  { id: "mirrored_a", label: "FRM D7", time: "07:55:23", imageUrl: paperRightUrl, mirrored: true },
  { id: "paper_right", label: "FRM 4C", time: "07:55:23", imageUrl: paperRightUrl },
  { id: "lake_memory_b", label: "FRM 0F", time: "07:55:23", imageUrl: lakeMemoryBUrl },
  { id: "paper_left", label: "FRM B2", time: "07:55:23", imageUrl: paperLeftUrl },
  { id: "mirrored_b", label: "FRM E8", time: "07:55:23", imageUrl: paperLeftUrl, mirrored: true }
];

const VALID_FRAME_IDS = new Set<RecoveredFrameId>(["paper_left", "paper_middle", "paper_right"]);

function InterludeRecoveredAlbum({ state, router }: Pick<SceneComponentProps, "state" | "router">) {
  const [albumView, setAlbumView] = useState<"shelf" | "qizhen" | "recovered">("shelf");
  const [order, setOrder] = useState<RecoveredFrameId[]>(
    () => [...state.chapterThreeInterlude.photoFrameIds]
  );
  const [feedback, setFeedback] = useState("");
  const [attempts, setAttempts] = useState(0);
  const journalPhotos = [
    state.qizhenLake.journal.mainPhoto,
    ...Object.values(state.qizhenLake.journal.optionalPhotos)
  ].filter((photo): photo is QizhenPhotoRecord => photo !== null && photo !== undefined);

  if (albumView === "shelf") {
    return (
      <section className="recovered-album-scene app-screen" aria-label="照片相簿">
        <header className="interlude-app-header">
          <PhoneNavButton kind="exit" label="退出照片" onClick={() => router.goTo("timeline_recovery")} />
          <div><small>PHOTOS</small><h1>相簿</h1></div>
          <span>{journalPhotos.length + 7}</span>
        </header>
        <main className="interlude-scroll interlude-album-shelf">
          <button type="button" className="interlude-album-card" onClick={() => setAlbumView("qizhen")}>
            <span className="interlude-album-cover is-qizhen">
              {journalPhotos[0] ? <QizhenRecipeFrame recipe={journalPhotos[0].recipe} variant="thumb" /> : <i aria-hidden="true" />}
            </span>
            <strong>启真湖划船</strong>
            <small>{journalPhotos.length} 张 · 来自相机</small>
          </button>
          <button type="button" className="interlude-album-card" onClick={() => setAlbumView("recovered")}>
            <span className="interlude-album-cover"><img src={paperMiddleUrl} alt="" aria-hidden="true" /></span>
            <strong>恢复的项目</strong>
            <small>7 张 · 帧顺序损坏</small>
          </button>
          <p className="interlude-album-note">相机拍下的启真湖照片仍按原顺序保留；恢复工具另找回了一段没有时间顺序的动态照片。</p>
        </main>
      </section>
    );
  }

  if (albumView === "qizhen") {
    return (
      <section className="recovered-album-scene app-screen" aria-label="启真湖划船相簿">
        <header className="interlude-app-header">
          <PhoneNavButton kind="back" label="返回相簿" onClick={() => setAlbumView("shelf")} />
          <div><small>CAMERA ROLL</small><h1>启真湖划船</h1></div>
          <span>{journalPhotos.length}</span>
        </header>
        <main className="interlude-scroll">
          {journalPhotos.length ? (
            <section className="interlude-qizhen-album-grid">
              {journalPhotos.map((photo) => (
                <article key={photo.id}>
                  <QizhenRecipeFrame recipe={photo.recipe} variant="thumb" alt={`${photo.spotId} 相机照片`} />
                  <span><strong>{photo.spotId}</strong><small>{photo.capturedAtSeconds}s</small></span>
                </article>
              ))}
            </section>
          ) : <p className="interlude-album-note">这份存档没有保留相机照片。恢复的动态照片仍可继续核验。</p>}
        </main>
      </section>
    );
  }

  function selectFrame(id: RecoveredFrameId) {
    if (order.includes(id) || order.length >= 3) return;
    setOrder((current) => [...current, id]);
    setFeedback("");
  }

  function submit() {
    const validOrder = order.filter((id): id is ChapterThreeInterludePhotoFrameId => VALID_FRAME_IDS.has(id));
    const result = kit.chapterThreeInterlude.submitPhotoSequence(validOrder);
    const nextAttempts = attempts + 1;
    setAttempts(nextAttempts);
    setFeedback(result === "accepted"
      ? "方向已恢复：纸条从湖面左侧进入画面，随后向东离岸。"
      : result === "locked"
        ? "先完成 CC98 记录收尾。"
        : nextAttempts === 1
          ? "这三帧的运动方向没有连续起来。"
          : nextAttempts === 2
            ? "对比纸条与同一根湖岸灯柱的相对位置。"
            : "找出纸条依次经过灯柱左侧、中部和右侧的三张帧。"
    );
  }

  return (
    <section className="recovered-album-scene app-screen" aria-label="已恢复相册">
      <header className="interlude-app-header">
        <PhoneNavButton kind="back" label="返回相簿" onClick={() => setAlbumView("shelf")} />
        <div><small>RECOVERED ALBUM</small><h1>最近删除 · 已恢复</h1></div>
        <span>{order.length}/3</span>
      </header>
      <main className="interlude-scroll">
        <section className="recovered-photo-stage">
          <header><strong>IMG_0755_LIVE · 帧顺序损坏</strong><button type="button" onClick={() => setOrder([])}>重排</button></header>
          <p>选出同一段运动中连续的三帧，再按先后顺序放入。</p>
          <div className="recovered-photo-order">
            {[0, 1, 2].map((slot) => {
              const id = order[slot];
              const frame = RECOVERED_FRAMES.find((item) => item.id === id);
              return <span key={slot}>{frame ? `${slot + 1} · ${frame.label}` : `${slot + 1} · 待选择`}</span>;
            })}
          </div>
        </section>
        <section className="recovered-photo-grid">
          {RECOVERED_FRAMES.map((frame) => (
            <button
              key={frame.id}
              type="button"
              disabled={order.includes(frame.id) || order.length >= 3}
              onClick={() => selectFrame(frame.id)}
            >
              <img
                className={frame.mirrored ? "is-mirrored" : ""}
                src={frame.imageUrl}
                alt={`${frame.label}，恢复照片帧`}
              />
              <span><strong>{frame.label}</strong><small>{frame.time}</small></span>
            </button>
          ))}
        </section>
        {state.chapterThreeInterlude.photoSequenceSolved ? (
          <section className="recovered-photo-preview" aria-label="已恢复的连续帧">
            {["paper_left", "paper_middle", "paper_right"].map((id, index) => {
              const frame = RECOVERED_FRAMES.find((item) => item.id === id)!;
              return <img key={id} src={frame.imageUrl} alt="" aria-hidden="true" style={{ animationDelay: `${index * 0.55}s` }} />;
            })}
            <span>恢复结果：湖区东侧</span>
          </section>
        ) : null}
        <button type="button" className="interlude-primary-action" disabled={order.length !== 3} onClick={submit}>确认照片顺序</button>
        {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
      </main>
    </section>
  );
}

export function PhotosScene({ state, router }: SceneComponentProps) {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const brightnessAtCaptureRef = useRef<number | null>(
    puzzle.photoCaptured && !puzzle.photoDimmed ? state.ui.brightness : null
  );
  const previousBrightnessRef = useRef(state.ui.brightness);

  useEffect(() => {
    const previousBrightness = previousBrightnessRef.current;
    previousBrightnessRef.current = state.ui.brightness;
    if (!puzzle.photoCaptured || puzzle.photoDimmed) return;
    if (brightnessAtCaptureRef.current === null) {
      brightnessAtCaptureRef.current = state.ui.brightness;
      return;
    }
    const adjustedAfterCapture = state.ui.brightness !== previousBrightness
      && state.ui.brightness !== brightnessAtCaptureRef.current;
    if (adjustedAfterCapture && state.ui.brightness <= 20) {
      kit.libraryFinals.dimPhoto(state.ui.brightness);
    }
  }, [puzzle.photoCaptured, puzzle.photoDimmed, state.ui.brightness]);

  function capturePhoto() {
    const wasCaptured = puzzle.photoCaptured;
    const brightnessAtCapture = state.ui.brightness;
    const captured = kit.libraryFinals.capturePhoto();
    if (captured && !wasCaptured) {
      brightnessAtCaptureRef.current = brightnessAtCapture;
      previousBrightnessRef.current = brightnessAtCapture;
    }
    return captured;
  }

  function generateReport() {
    kit.libraryFinals.generateItemReport();
  }

  if (state.qizhenLake.phase === "complete" && !state.chapterThreeInterlude.completed) {
    return <InterludeRecoveredAlbum state={state} router={router} />;
  }

  return (
    <PhotoEvidenceOverlay
      available={puzzle.backpackInspected}
      brightness={state.ui.brightness}
      captured={puzzle.photoCaptured}
      dimmed={puzzle.photoDimmed}
      reportGenerated={puzzle.itemReportGenerated}
      onCapture={capturePhoto}
      onGenerate={generateReport}
      onClose={() => router.goTo("phone_home")}
    />
  );
}
