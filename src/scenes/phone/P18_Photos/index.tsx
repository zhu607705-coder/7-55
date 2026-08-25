import { useEffect, useRef, useState } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import {
  PhoneActionSheet,
  PhoneAppHeader,
  PhoneAppScaffold,
  PhoneListRow
} from "../../../components/PhoneAppUi";
import { QizhenRecipeFrame } from "../../../components/QizhenRecipeFrame";
import type { ChapterThreeInterludePhotoFrameId, QizhenPhotoRecord } from "../../../core/types";
import { selectPhonePhotos } from "../../../data/phonePhotoCatalog";
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
const CAMPUS_LIFE_PHOTOS = selectPhonePhotos("campus_life");

function InterludeRecoveredAlbum({ state, router }: Pick<SceneComponentProps, "state" | "router">) {
  const [albumView, setAlbumView] = useState<"shelf" | "qizhen" | "recovered" | "campus_life">("shelf");
  const [order, setOrder] = useState<RecoveredFrameId[]>(
    () => [...state.chapterThreeInterlude.photoFrameIds]
  );
  const [feedback, setFeedback] = useState("");
  const [attempts, setAttempts] = useState(0);
  const [selectedCampusPhotoId, setSelectedCampusPhotoId] = useState<string | null>(null);
  const selectedCampusPhotoTriggerRef = useRef<HTMLButtonElement | null>(null);
  const selectedCampusPhoto = CAMPUS_LIFE_PHOTOS.find((photo) => photo.id === selectedCampusPhotoId) ?? null;
  const journalPhotos = [
    state.qizhenLake.journal.mainPhoto,
    ...Object.values(state.qizhenLake.journal.optionalPhotos)
  ].filter((photo): photo is QizhenPhotoRecord => photo !== null && photo !== undefined);

  if (albumView === "shelf") {
    return (
      <PhoneAppScaffold
        label="照片相簿"
        className="recovered-album-scene"
        contentClassName="interlude-scroll interlude-album-shelf"
        header={(
          <PhoneAppHeader
            eyebrow="PHOTOS"
            title="相簿"
            navigation={{ kind: "exit", label: "退出照片", onClick: () => router.goTo("timeline_recovery") }}
            end={<span className="interlude-header-count">{journalPhotos.length + 7 + CAMPUS_LIFE_PHOTOS.length}</span>}
          />
        )}
      >
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
          <button type="button" className="interlude-album-card" onClick={() => setAlbumView("campus_life")}>
            <span className="interlude-album-cover">
              <img src={CAMPUS_LIFE_PHOTOS[1]?.imageUrl ?? CAMPUS_LIFE_PHOTOS[0]?.imageUrl} alt="" aria-hidden="true" />
            </span>
            <strong>校园与日常</strong>
            <small>{CAMPUS_LIFE_PHOTOS.length} 张 · 普通照片</small>
          </button>
          <p className="interlude-album-note">相机照片、恢复帧和普通生活照分开归档。普通照片不会进入时间线或证据判定。</p>
      </PhoneAppScaffold>
    );
  }

  if (albumView === "qizhen") {
    return (
      <PhoneAppScaffold
        label="启真湖划船相簿"
        className="recovered-album-scene"
        contentClassName="interlude-scroll"
        header={(
          <PhoneAppHeader
            eyebrow="CAMERA ROLL"
            title="启真湖划船"
            navigation={{ kind: "back", label: "返回相簿", onClick: () => setAlbumView("shelf") }}
            end={<span className="interlude-header-count">{journalPhotos.length}</span>}
          />
        )}
      >
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
      </PhoneAppScaffold>
    );
  }

  if (albumView === "campus_life") {
    return (
      <>
        <PhoneAppScaffold
          label="校园与日常相簿"
          className="recovered-album-scene"
          contentClassName="interlude-scroll campus-life-album"
          header={(
            <PhoneAppHeader
              eyebrow="CAMPUS LIFE"
              title="校园与日常"
              navigation={{ kind: "back", label: "返回相簿", onClick: () => setAlbumView("shelf") }}
              end={<span className="interlude-header-count">{CAMPUS_LIFE_PHOTOS.length}</span>}
            />
          )}
        >
          <p className="campus-life-album__note">这些照片用于补足手机相册的生活层次，不会触发剧情进度。</p>
          <section className="campus-life-photo-grid" aria-label="校园与日常照片">
            {CAMPUS_LIFE_PHOTOS.map((photo) => (
              <button
                key={photo.id}
                type="button"
                onClick={(event) => {
                  selectedCampusPhotoTriggerRef.current = event.currentTarget;
                  setSelectedCampusPhotoId(photo.id);
                }}
              >
                <img src={photo.imageUrl} alt="" aria-hidden="true" />
                <span><strong>{photo.title}</strong><small>{photo.location}</small></span>
              </button>
            ))}
          </section>
        </PhoneAppScaffold>
        {selectedCampusPhoto ? (
          <PhoneActionSheet
            title={selectedCampusPhoto.title}
            description={`${selectedCampusPhoto.capturedAt} · ${selectedCampusPhoto.location}`}
            className="campus-life-photo-sheet"
            onClose={() => setSelectedCampusPhotoId(null)}
            returnFocusElement={selectedCampusPhotoTriggerRef.current}
          >
            <img src={selectedCampusPhoto.imageUrl} alt={`${selectedCampusPhoto.title}，${selectedCampusPhoto.detail}`} />
            <p>{selectedCampusPhoto.detail}</p>
            <PhoneListRow
              title="普通照片"
              description="不参与时间线、地点判断或物品识别。"
              leading="照"
              onClick={() => setSelectedCampusPhotoId(null)}
              trailing="关闭"
            />
          </PhoneActionSheet>
        ) : null}
      </>
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
      ? "三帧已经恢复为一次连续的水平移动。"
      : result === "locked"
        ? "先完成 CC98 记录收尾。"
        : nextAttempts === 1
          ? "这三帧的运动方向没有连续起来。"
          : nextAttempts === 2
            ? "对比纸条与同一根湖岸灯柱的相对位置。"
            : "排除镜像和无关帧，选择能形成连续水平移动的三张照片。"
    );
  }

  return (
    <PhoneAppScaffold
      label="已恢复相册"
      className="recovered-album-scene"
      contentClassName="interlude-scroll"
      header={(
        <PhoneAppHeader
          eyebrow="RECOVERED ALBUM"
          title="最近删除 · 已恢复"
          navigation={{ kind: "back", label: "返回相簿", onClick: () => setAlbumView("shelf") }}
          end={<span className="interlude-header-count">{order.length}/3</span>}
        />
      )}
    >
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
            <span>连续帧已恢复</span>
          </section>
        ) : null}
        <button type="button" className="interlude-primary-action" disabled={order.length !== 3} onClick={submit}>确认照片顺序</button>
        {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
    </PhoneAppScaffold>
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
