import { useEffect, useMemo, useRef, useState } from "react";
import qizhenContent from "../data/chapter3-qizhen-lake.content.json";
import type {
  QizhenJournalDraft,
  QizhenPhotoRecord,
  QizhenPhotoRecipe,
  QizhenPhotoSpotId
} from "../core/types";
import { QizhenRecipeFrame } from "./QizhenRecipeFrame";

export interface QizhenJournalCameraSession {
  spotId: QizhenPhotoSpotId;
  recipe: QizhenPhotoRecipe;
  speed: number;
  roll: number;
  kind: "main" | "spot";
}

export interface QizhenJournalCameraProps {
  session: QizhenJournalCameraSession;
  photo: QizhenPhotoRecord | null;
  draft: QizhenJournalDraft | null;
  onShutter: () => void;
  onUpdateDraft: (
    patch: Partial<Pick<QizhenJournalDraft, "titleId" | "statusId" | "captionId">>
  ) => void;
  onSaveDraft: () => void;
  onRetake: () => void;
  onClose: () => void;
}

/* ===== 取景 HUD 常量 =====
   配方 → 画面的投影(底图裁切、皮划艇、黑天鹅、水纹)已抽至 QizhenRecipeFrame。 */
/* 侧倾快照(翻船阈值 |roll| ≈ 0.92)到指示器角度的映射,满阈值约 28°。 */
const ROLL_TO_DEGREES = 30;
const MAX_ROLL_INDICATOR_DEGREES = 45;

/* ===== content JSON journal 节读取 =====
   journal 节由内容代理并行落地;这里只做防御性归一,结构未就位时得到空文案,
   组件不自行编造任何用户可见文字。 */

interface JournalOption {
  id: string;
  text: string;
}

interface JournalCameraCopy {
  title: string;
  shutter: string;
  close: string;
  retake: string;
  draftMainTitle: string;
  draftMainStatus: string;
  draftSpotCaption: string;
  saveDraft: string;
  draftSaved: string;
  speedLabel: string;
  rollLabel: string;
  hint: string;
}

interface JournalContent {
  titles: JournalOption[];
  statuses: JournalOption[];
  spotCaptions: Record<string, JournalOption[]>;
  tagLabels: Record<string, string>;
  spotNames: Record<string, string>;
  camera: JournalCameraCopy;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function readOptions(value: unknown): JournalOption[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const options: JournalOption[] = [];
  value.forEach((item, index) => {
    if (typeof item === "string") {
      options.push({ id: item, text: item });
      return;
    }
    const record = asRecord(item);
    if (!record) {
      return;
    }
    const text = asString(record.text ?? record.label);
    if (!text) {
      return;
    }
    options.push({ id: asString(record.id) || `option_${index}`, text });
  });
  return options;
}

function readStringMap(value: unknown): Record<string, string> {
  const record = asRecord(value);
  if (!record) {
    return {};
  }
  const map: Record<string, string> = {};
  for (const [key, entry] of Object.entries(record)) {
    if (typeof entry === "string") {
      map[key] = entry;
    }
  }
  return map;
}

function readOptionGroups(value: unknown): Record<string, JournalOption[]> {
  const record = asRecord(value);
  if (!record) {
    return {};
  }
  const groups: Record<string, JournalOption[]> = {};
  for (const [key, entry] of Object.entries(record)) {
    groups[key] = readOptions(entry);
  }
  return groups;
}

const CAMERA_COPY_KEYS = [
  "title",
  "shutter",
  "close",
  "retake",
  "draftMainTitle",
  "draftMainStatus",
  "draftSpotCaption",
  "saveDraft",
  "draftSaved",
  "speedLabel",
  "rollLabel",
  "hint"
] as const;

function readJournalContent(): JournalContent {
  const journal = asRecord((qizhenContent as { journal?: unknown }).journal);
  const cameraRecord = asRecord(journal?.camera);
  const camera = {} as Record<(typeof CAMERA_COPY_KEYS)[number], string>;
  for (const key of CAMERA_COPY_KEYS) {
    camera[key] = asString(cameraRecord?.[key]);
  }
  return {
    titles: readOptions(journal?.titles),
    statuses: readOptions(journal?.statuses),
    spotCaptions: readOptionGroups(journal?.spotCaptions),
    tagLabels: readStringMap(journal?.tagLabels),
    spotNames: readStringMap(journal?.spotNames),
    camera
  };
}

const JOURNAL = readJournalContent();

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

interface DraftOptionGroupProps {
  label: string;
  options: JournalOption[];
  selectedId: string | null;
  onSelect: (id: string) => void;
}

function DraftOptionGroup({ label, options, selectedId, onSelect }: DraftOptionGroupProps) {
  return (
    <fieldset className="qizhen-journal-camera-option-group">
      <legend>{label}</legend>
      <div className="qizhen-journal-camera-options">
        {options.map((option) => (
          <button
            aria-pressed={option.id === selectedId}
            className={`qizhen-journal-camera-option${
              option.id === selectedId ? " is-selected" : ""
            }`}
            key={option.id}
            onClick={() => onSelect(option.id)}
            type="button"
          >
            {option.text}
          </button>
        ))}
      </div>
    </fieldset>
  );
}

export function QizhenJournalCamera(props: QizhenJournalCameraProps) {
  const { session, photo, draft, onShutter, onUpdateDraft, onSaveDraft, onRetake, onClose } =
    props;
  const copy = JOURNAL.camera;
  const drafting = photo !== null;
  const isMain = session.kind === "main";
  const spotName = JOURNAL.spotNames[session.spotId] ?? "";

  const [savedVisible, setSavedVisible] = useState(false);
  const [flashVisible, setFlashVisible] = useState(false);
  const shutterButtonRef = useRef<HTMLButtonElement>(null);
  const flashTimerRef = useRef<number | null>(null);

  const photoId = photo?.id ?? null;
  useEffect(() => {
    setSavedVisible(false);
  }, [photoId]);

  useEffect(() => {
    if (!drafting) {
      shutterButtonRef.current?.focus();
    }
  }, [drafting, photoId]);

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key !== "Escape") {
        return;
      }
      event.preventDefault();
      onClose();
    }
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [onClose]);

  useEffect(
    () => () => {
      if (flashTimerRef.current !== null) {
        window.clearTimeout(flashTimerRef.current);
      }
    },
    []
  );

  const tagChips = useMemo(() => {
    if (!photo) {
      return [];
    }
    return photo.tags
      .map((tag) => ({ id: String(tag), label: JOURNAL.tagLabels[String(tag)] ?? "" }))
      .filter((chip) => chip.label.length > 0);
  }, [photo]);

  const canSaveDraft = isMain
    ? Boolean(draft?.titleId && draft?.statusId)
    : Boolean(draft?.captionId);

  const spotCaptionOptions = JOURNAL.spotCaptions[session.spotId] ?? [];

  const rollIndicatorDegrees = clamp(
    session.roll * ROLL_TO_DEGREES,
    -MAX_ROLL_INDICATOR_DEGREES,
    MAX_ROLL_INDICATOR_DEGREES
  );

  const handleShutter = () => {
    if (flashTimerRef.current !== null) {
      window.clearTimeout(flashTimerRef.current);
    }
    setFlashVisible(true);
    flashTimerRef.current = window.setTimeout(() => {
      setFlashVisible(false);
      flashTimerRef.current = null;
    }, 180);
    onShutter();
  };

  const handleUpdateDraft = (
    patch: Partial<Pick<QizhenJournalDraft, "titleId" | "statusId" | "captionId">>
  ) => {
    setSavedVisible(false);
    onUpdateDraft(patch);
  };

  const handleSaveDraft = () => {
    if (!canSaveDraft) {
      return;
    }
    onSaveDraft();
    setSavedVisible(true);
  };

  return (
    <section
      aria-label={copy.title}
      className={`qizhen-journal-camera ${
        drafting ? "qizhen-journal-camera--draft" : "qizhen-journal-camera--live"
      }`}
    >
      <header className="qizhen-journal-camera-header">
        <div className="qizhen-journal-camera-heading">
          <small>{spotName}</small>
          <h2>{copy.title}</h2>
        </div>
        <button
          className="qizhen-journal-camera-close"
          onClick={onClose}
          type="button"
        >
          {copy.close}
        </button>
      </header>

      {drafting ? (
        <>
          <div className="qizhen-journal-camera-review">
            <div className="qizhen-journal-camera-review-frame">
              <QizhenRecipeFrame recipe={photo.recipe} />
            </div>
            {tagChips.length > 0 ? (
              <ul className="qizhen-journal-camera-tags">
                {tagChips.map((chip) => (
                  <li key={chip.id}>{chip.label}</li>
                ))}
              </ul>
            ) : null}
          </div>

          <div className="qizhen-journal-camera-draft-form">
            {isMain ? (
              <>
                <DraftOptionGroup
                  label={copy.draftMainTitle}
                  onSelect={(titleId) => handleUpdateDraft({ titleId })}
                  options={JOURNAL.titles}
                  selectedId={draft?.titleId ?? null}
                />
                <DraftOptionGroup
                  label={copy.draftMainStatus}
                  onSelect={(statusId) => handleUpdateDraft({ statusId })}
                  options={JOURNAL.statuses}
                  selectedId={draft?.statusId ?? null}
                />
              </>
            ) : (
              <DraftOptionGroup
                label={copy.draftSpotCaption}
                onSelect={(captionId) => handleUpdateDraft({ captionId })}
                options={spotCaptionOptions}
                selectedId={draft?.captionId ?? null}
              />
            )}
          </div>

          {savedVisible ? (
            <p className="qizhen-journal-camera-saved" role="status">
              {copy.draftSaved}
            </p>
          ) : null}

          <footer className="qizhen-journal-camera-actions">
            <button
              className="qizhen-journal-camera-retake"
              onClick={onRetake}
              type="button"
            >
              {copy.retake}
            </button>
            <button
              className="qizhen-journal-camera-save"
              disabled={!canSaveDraft}
              onClick={handleSaveDraft}
              type="button"
            >
              {copy.saveDraft}
            </button>
          </footer>
        </>
      ) : (
        <>
          <div className="qizhen-journal-camera-viewfinder">
            <QizhenRecipeFrame recipe={session.recipe} />
            <div className="qizhen-journal-camera-hud" aria-hidden="true">
              <i className="qizhen-journal-camera-hud-frame" />
              <i className="qizhen-journal-camera-hud-level" />
              <i
                className="qizhen-journal-camera-hud-roll"
                style={{
                  transform: `translate(-50%, -50%) rotate(${rollIndicatorDegrees}deg)`
                }}
              />
            </div>
            {flashVisible ? (
              <i className="qizhen-journal-camera-flash" aria-hidden="true" />
            ) : null}
          </div>

          <div className="qizhen-journal-camera-readouts">
            <span>
              {copy.speedLabel} {Math.round(session.speed)}
            </span>
            <span>
              {copy.rollLabel} {session.roll.toFixed(2)}
            </span>
            <span>{spotName}</span>
          </div>

          <p className="qizhen-journal-camera-hint">{copy.hint}</p>

          <footer className="qizhen-journal-camera-shutter-row">
            <button
              className="qizhen-journal-camera-shutter"
              onClick={handleShutter}
              ref={shutterButtonRef}
              type="button"
            >
              {copy.shutter}
            </button>
          </footer>
        </>
      )}
    </section>
  );
}
