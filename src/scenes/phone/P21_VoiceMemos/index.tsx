import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import voiceMemoContentData from "../../../data/chapter3-interlude-voice-memos.audio.content.json";
import voiceMemoGeneratedData from "../../../data/chapter3-interlude-voice-memos.audio.generated.json";
import {
  clearChapterThreeInterludeVoiceDraft,
  loadChapterThreeInterludeVoiceDraft,
  saveChapterThreeInterludeVoiceDraft,
  type ChapterThreeInterludeVoiceDraft,
  type ChapterThreeInterludeVoiceDraftStage
} from "../../../modules/ChapterThreeInterludeDraftStore";
import { kit } from "../../../modules/GameKit";
import type { ChapterThreeInterludeVoiceCandidateId } from "../../../modules/ChapterThreePhoneInterludeController";

interface VoiceMemoSoundEvent {
  startMs: number;
  endMs: number;
  category: string;
  labelZh: string;
  distance: "near" | "mid" | "far";
}

interface VoiceMemoCatalogRecording {
  id: ChapterThreeInterludeVoiceCandidateId;
  asset: string;
  code: string;
  time: string;
  revealZh: string;
  targetDurationMs: number;
  soundEvents?: readonly VoiceMemoSoundEvent[];
}

interface VoiceMemoClip extends VoiceMemoCatalogRecording {
  cueId: string;
  durationMs: number;
  waveform: readonly number[];
}

interface VoiceMemoGeneratedManifest {
  version?: string | number;
  assets: Record<string, {
    durationMs?: number;
    waveform?: readonly number[];
    waveformBins?: readonly number[];
    waveformRms?: readonly number[];
  }>;
}

interface VoiceMemoContentManifest {
  version: string | number;
  recordings: VoiceMemoCatalogRecording[];
}

const DISPLAY_ORDER: readonly ChapterThreeInterludeVoiceCandidateId[] = [
  "decoy_theater",
  "lake",
  "decoy_library",
  "stone",
  "decoy_canteen",
  "lobby",
  "broadcast"
];
const CORRECT_CLIP_IDS = new Set<ChapterThreeInterludeVoiceCandidateId>([
  "lake",
  "stone",
  "lobby",
  "broadcast"
]);
const generatedManifest = voiceMemoGeneratedData as VoiceMemoGeneratedManifest;
const contentManifest = voiceMemoContentData as VoiceMemoContentManifest;
const catalogRecordings = contentManifest.recordings;
const catalogById = new Map(catalogRecordings.map((recording) => [recording.id, recording]));
const CLIPS: readonly VoiceMemoClip[] = DISPLAY_ORDER.map((id) => {
  const recording = catalogById.get(id);
  if (!recording) throw new Error(`Missing Chapter 3.5 voice memo catalog entry: ${id}`);
  const generated = generatedManifest.assets[recording.asset];
  return {
    ...recording,
    cueId: `chapter35_voice_audition_${id}`,
    durationMs: generated?.durationMs ?? recording.targetDurationMs,
    waveform: generated?.waveform ?? generated?.waveformBins ?? generated?.waveformRms ?? []
  };
});
const CANDIDATE_IDS = CLIPS.map((clip) => clip.id);
const MANIFEST_VERSION = `${contentManifest.version}:${generatedManifest.version ?? contentManifest.version}`;
const HEARD_THRESHOLD = 0.8;
const EVENT_REPLAY_LEAD_MS = 180;
const EVENT_REPLAY_TAIL_MS = 220;

const DISTANCE_LABELS: Readonly<Record<VoiceMemoSoundEvent["distance"], string>> = {
  near: "近",
  mid: "中",
  far: "远"
};

function emptyDraft(): ChapterThreeInterludeVoiceDraft {
  return { stage: "selection", heardIds: [], selectedIds: [], orderedIds: [] };
}

function waveformHeight(value: number): number {
  if (!Number.isFinite(value)) return 4;
  const scaled = value >= 0 && value <= 1 ? value * 28 : value;
  return Math.max(4, Math.min(28, Math.round(scaled)));
}

function clipFor(id: ChapterThreeInterludeVoiceCandidateId): VoiceMemoClip {
  const clip = CLIPS.find((item) => item.id === id);
  if (!clip) throw new Error(`Missing Chapter 3.5 voice memo UI entry: ${id}`);
  return clip;
}

export function VoiceMemosScene({ state, router, events }: SceneComponentProps) {
  const initialDraftRef = useRef<ChapterThreeInterludeVoiceDraft | null>(null);
  if (initialDraftRef.current === null) {
    const interlude = state.chapterThreeInterlude;
    const formalOrder = [...new Set(
      interlude.voiceClipOrder as readonly ChapterThreeInterludeVoiceCandidateId[]
    )].filter((id) => CANDIDATE_IDS.includes(id));
    if (interlude.completed || interlude.voiceSequenceSolved) {
      clearChapterThreeInterludeVoiceDraft();
      initialDraftRef.current = formalOrder.length === 4
        ? { stage: "ordering", heardIds: formalOrder, selectedIds: formalOrder, orderedIds: formalOrder }
        : emptyDraft();
    } else if (!interlude.recoveryOpened) {
      clearChapterThreeInterludeVoiceDraft();
      initialDraftRef.current = emptyDraft();
    } else {
      initialDraftRef.current = loadChapterThreeInterludeVoiceDraft({
        manifestVersion: MANIFEST_VERSION,
        candidateIds: CANDIDATE_IDS
      }) ?? emptyDraft();
    }
  }
  const initialDraft = initialDraftRef.current;
  const [stage, setStage] = useState<ChapterThreeInterludeVoiceDraftStage>(initialDraft.stage);
  const [selected, setSelected] = useState<ChapterThreeInterludeVoiceCandidateId[]>(initialDraft.selectedIds);
  const [order, setOrder] = useState<ChapterThreeInterludeVoiceCandidateId[]>(initialDraft.orderedIds);
  const [playing, setPlaying] = useState<ChapterThreeInterludeVoiceCandidateId | null>(null);
  const [heard, setHeard] = useState<ChapterThreeInterludeVoiceCandidateId[]>(initialDraft.heardIds);
  const [feedback, setFeedback] = useState("");
  const playTimerRef = useRef<number | null>(null);
  const playbackRef = useRef<{
    clipId: ChapterThreeInterludeVoiceCandidateId;
    startedAtMs: number;
    durationMs: number;
  } | null>(null);
  const stageRef = useRef(stage);
  const heardRef = useRef(heard);
  const selectedRef = useRef(selected);
  const orderRef = useRef(order);
  const draftPersistenceEnabledRef = useRef(
    state.chapterThreeInterlude.recoveryOpened
      && !state.chapterThreeInterlude.completed
      && !state.chapterThreeInterlude.voiceSequenceSolved
  );

  const selectedClips = useMemo(() => order.map(clipFor), [order]);

  const persistCurrentDraft = useCallback(() => {
    if (!draftPersistenceEnabledRef.current) return;
    saveChapterThreeInterludeVoiceDraft({
      stage: stageRef.current,
      heardIds: heardRef.current,
      selectedIds: selectedRef.current,
      orderedIds: orderRef.current
    }, {
      manifestVersion: MANIFEST_VERSION,
      candidateIds: CANDIDATE_IDS
    });
  }, []);

  const markClipHeard = useCallback((clipId: ChapterThreeInterludeVoiceCandidateId, updateUi: boolean) => {
    if (heardRef.current.includes(clipId)) return;
    const next = [...heardRef.current, clipId];
    heardRef.current = next;
    if (updateUi) setHeard(next);
    persistCurrentDraft();
  }, [persistCurrentDraft]);

  const stopPreview = useCallback((updateUi = true) => {
    const playback = playbackRef.current;
    if (playback) {
      const listenedMs = performance.now() - playback.startedAtMs;
      if (listenedMs >= playback.durationMs * HEARD_THRESHOLD) {
        markClipHeard(playback.clipId, updateUi);
      }
    }
    playbackRef.current = null;
    if (playTimerRef.current !== null) window.clearTimeout(playTimerRef.current);
    playTimerRef.current = null;
    events.emit("chapter35_voice_audition_stop");
    if (updateUi) setPlaying(null);
  }, [events, markClipHeard]);

  useEffect(() => {
    stageRef.current = stage;
    heardRef.current = heard;
    selectedRef.current = selected;
    orderRef.current = order;
    persistCurrentDraft();
  }, [heard, order, persistCurrentDraft, selected, stage]);

  useEffect(() => {
    const interlude = state.chapterThreeInterlude;
    if (interlude.completed || interlude.voiceSequenceSolved || !interlude.recoveryOpened) {
      draftPersistenceEnabledRef.current = false;
      clearChapterThreeInterludeVoiceDraft();
      return;
    }
    draftPersistenceEnabledRef.current = true;
    persistCurrentDraft();
  }, [persistCurrentDraft, state.chapterThreeInterlude.completed, state.chapterThreeInterlude.recoveryOpened, state.chapterThreeInterlude.voiceSequenceSolved]);

  useEffect(() => {
    const handleVisibility = () => {
      if (document.hidden) stopPreview();
    };
    const unsubscribe = events.subscribe((event) => {
      if (event.name !== "game_progress_reset") return;
      draftPersistenceEnabledRef.current = false;
      stopPreview();
      clearChapterThreeInterludeVoiceDraft();
    });
    document.addEventListener("visibilitychange", handleVisibility);
    return () => {
      unsubscribe();
      document.removeEventListener("visibilitychange", handleVisibility);
      stopPreview(false);
    };
  }, [events, stopPreview]);

  function auditionClip(clip: VoiceMemoClip) {
    if (playing === clip.id) {
      stopPreview();
      return;
    }
    stopPreview();
    setPlaying(clip.id);
    playbackRef.current = {
      clipId: clip.id,
      startedAtMs: performance.now(),
      durationMs: clip.durationMs
    };
    events.emit(clip.cueId, { clipId: clip.id, previewKind: "full" });
    playTimerRef.current = window.setTimeout(() => {
      if (playbackRef.current?.clipId === clip.id) {
        markClipHeard(clip.id, true);
        playbackRef.current = null;
      }
      setPlaying((current) => current === clip.id ? null : current);
      playTimerRef.current = null;
    }, clip.durationMs);
  }

  function replaySoundEvent(clip: VoiceMemoClip, soundEvent: VoiceMemoSoundEvent, eventIndex: number) {
    stopPreview();
    const startMs = Math.max(0, soundEvent.startMs - EVENT_REPLAY_LEAD_MS);
    const endMs = Math.min(clip.durationMs, soundEvent.endMs + EVENT_REPLAY_TAIL_MS);
    const durationMs = Math.max(240, endMs - startMs);
    setPlaying(clip.id);
    events.emit(clip.cueId, {
      clipId: clip.id,
      previewKind: "event",
      soundEventIndex: eventIndex,
      startMs,
      endMs,
      durationMs
    });
    playTimerRef.current = window.setTimeout(() => {
      events.emit("chapter35_voice_audition_stop");
      setPlaying((current) => current === clip.id ? null : current);
      playTimerRef.current = null;
    }, durationMs);
  }

  function toggleSelected(id: ChapterThreeInterludeVoiceCandidateId) {
    if (!heard.includes(id)) {
      setFeedback("先试听这段录音，再决定是否保留。");
      return;
    }
    if (selected.includes(id)) {
      setSelected((current) => current.filter((value) => value !== id));
      setFeedback("");
      return;
    }
    if (selected.length >= 4) {
      setFeedback("已经选满四段。先移出一段，再加入新的录音。");
      return;
    }
    setSelected((current) => [...current, id]);
    setFeedback("");
  }

  function beginOrdering() {
    if (selected.length !== 4) {
      setFeedback("需要先选满四段录音。");
      return;
    }
    stopPreview();
    setOrder([...selected]);
    setStage("ordering");
    setFeedback("用上下按钮调整四段录音的发生顺序。");
  }

  function moveClip(index: number, offset: -1 | 1) {
    const nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= order.length) return;
    setOrder((current) => {
      const next = [...current];
      [next[index], next[nextIndex]] = [next[nextIndex], next[index]];
      return next;
    });
    setFeedback("");
  }

  function returnToSelection() {
    stopPreview();
    setSelected([...order]);
    setStage("selection");
    setFeedback("");
  }

  function submit() {
    const result = kit.chapterThreeInterlude.submitVoiceSequence(order);
    if (result === "accepted" || result === "already_complete") {
      draftPersistenceEnabledRef.current = false;
      clearChapterThreeInterludeVoiceDraft();
    }
    const correctSet = order.length === 4 && order.every((id) => CORRECT_CLIP_IDS.has(id));
    setFeedback(result === "accepted" || result === "already_complete"
      ? "录音已接成连续路线，末段在 22:45:00 结束。"
      : result === "locked"
        ? "先完成 CC98 记录收尾。"
        : correctSet
          ? "四段都来自这条路线，前后声场仍有一处接不上。"
          : "其中至少一段属于别的夜间记录。重新比较背景声。"
    );
  }

  return (
    <section className="voice-memos-scene app-screen" aria-label="语音备忘录">
      <header className="interlude-app-header">
        <PhoneNavButton
          kind="exit"
          label="退出语音备忘录"
          onClick={() => { stopPreview(); router.goTo("timeline_recovery"); }}
        />
        <div><small>VOICE MEMOS</small><h1>语音备忘录</h1></div>
        <span>{stage === "selection" ? `${selected.length}/4` : "排序"}</span>
      </header>
      <main className="interlude-scroll">
        <section className="voice-stage-summary" aria-label="录音整理步骤">
          <b>{stage === "selection" ? "1 / 2 筛选录音" : "2 / 2 排列顺序"}</b>
          <p>{stage === "selection"
            ? "逐段试听，从七段恢复文件中留下同一次移动过程的四段。"
            : "根据环境声的连续变化，调整四段录音的先后位置。"}</p>
        </section>

        {stage === "selection" ? (
          <section className="voice-clip-list is-selection" aria-label="七段恢复录音">
            {CLIPS.map((clip) => {
              const listened = heard.includes(clip.id);
              const isSelected = selected.includes(clip.id);
              return (
                <article
                  key={clip.id}
                  className={`${playing === clip.id ? "is-playing" : ""} ${isSelected ? "is-selected" : ""}`.trim()}
                >
                  <button type="button" className="voice-play-dot" aria-label={`${playing === clip.id ? "停止" : "试听"} ${clip.code}`} onClick={() => auditionClip(clip)}>
                    {playing === clip.id ? "■" : "▶"}
                  </button>
                  <div><strong>{clip.code}</strong><small>{listened ? `${clip.revealZh} · ${clip.time}` : "未试听"}</small></div>
                  {clip.waveform.length > 0 ? (
                    <span className="voice-wave" aria-hidden="true">
                      {clip.waveform.map((height, index) => <i key={index} style={{ height: `${waveformHeight(height)}px` }} />)}
                    </span>
                  ) : null}
                  <button
                    type="button"
                    className="voice-add-button"
                    aria-pressed={isSelected}
                    onClick={() => toggleSelected(clip.id)}
                  >{isSelected ? "移出候选" : listened ? "保留这段" : "试听后可选"}</button>
                  {listened && clip.soundEvents?.length ? (
                    <div className="voice-event-chips" aria-label={`${clip.code} 可听事件`}>
                      {clip.soundEvents.map((soundEvent, eventIndex) => (
                        <button
                          key={`${soundEvent.startMs}-${soundEvent.endMs}-${soundEvent.category}`}
                          type="button"
                          title={`${soundEvent.category} · ${soundEvent.startMs}–${soundEvent.endMs}ms`}
                          onClick={() => replaySoundEvent(clip, soundEvent, eventIndex)}
                        >{soundEvent.labelZh}<small>{DISTANCE_LABELS[soundEvent.distance]}距</small></button>
                      ))}
                    </div>
                  ) : null}
                </article>
              );
            })}
          </section>
        ) : (
          <section className="voice-order-list" aria-label="当前录音顺序">
            {selectedClips.map((clip, index) => (
              <article key={clip.id} className={playing === clip.id ? "is-playing" : ""}>
                <b>{index + 1}</b>
                <button type="button" className="voice-play-dot" aria-label={`${playing === clip.id ? "停止" : "试听"} ${clip.code}`} onClick={() => auditionClip(clip)}>
                  {playing === clip.id ? "■" : "▶"}
                </button>
                <div><strong>{clip.code}</strong><small>{clip.revealZh}</small></div>
                <span className="voice-order-controls">
                  <button type="button" aria-label={`${clip.code} 上移`} disabled={index === 0} onClick={() => moveClip(index, -1)}>↑</button>
                  <button type="button" aria-label={`${clip.code} 下移`} disabled={index === order.length - 1} onClick={() => moveClip(index, 1)}>↓</button>
                </span>
                {clip.soundEvents?.length ? (
                  <div className="voice-event-chips" aria-label={`${clip.code} 可听事件`}>
                    {clip.soundEvents.map((soundEvent, eventIndex) => (
                      <button
                        key={`${soundEvent.startMs}-${soundEvent.endMs}-${soundEvent.category}`}
                        type="button"
                        title={`${soundEvent.category} · ${soundEvent.startMs}–${soundEvent.endMs}ms`}
                        onClick={() => replaySoundEvent(clip, soundEvent, eventIndex)}
                      >{soundEvent.labelZh}<small>{DISTANCE_LABELS[soundEvent.distance]}距</small></button>
                    ))}
                  </div>
                ) : null}
              </article>
            ))}
          </section>
        )}

        <div className="voice-actions">
          {stage === "selection" ? (
            <>
              <button type="button" onClick={() => { setSelected([]); setOrder([]); setFeedback(""); }}>清空选择</button>
              <button type="button" disabled={selected.length !== 4} onClick={beginOrdering}>进入排序</button>
            </>
          ) : (
            <>
              <button type="button" onClick={returnToSelection}>返回重选</button>
              <button type="button" onClick={submit}>核对录音</button>
            </>
          )}
        </div>
        {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
      </main>
    </section>
  );
}
