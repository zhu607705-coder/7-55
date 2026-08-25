import type { EventBus } from "../core/EventBus";
import type { GameEvent, StoryLine } from "../core/types";
import actOneTimelineData from "../data/act-one.audio.json";
import actOneGeneratedAudioData from "../data/act-one.audio.generated.json";
import bikeArcadeTimelineData from "../data/bike-arcade.audio.json";
import bikeArcadeGeneratedAudioData from "../data/bike-arcade.audio.generated.json";
import chapterThreeCanteenTimelineData from "../data/chapter3-canteen.audio.json";
import chapterThreeCanteenGeneratedAudioData from "../data/chapter3-canteen.audio.generated.json";
import chapterThreeTheaterTimelineData from "../data/chapter3-theater.audio.json";
import chapterThreeTheaterGeneratedAudioData from "../data/chapter3-theater.audio.generated.json";
import chapterThreeQizhenTimelineData from "../data/chapter3-qizhen.audio.json";
import chapterThreeQizhenGeneratedAudioData from "../data/chapter3-qizhen.audio.generated.json";
import chapterThreeQizhenSfxGeneratedAudioData from "../data/chapter3-qizhen-sfx.audio.generated.json";
import chapter3InterludeVoiceMemosGeneratedAudioData from "../data/chapter3-interlude-voice-memos.audio.generated.json";
import chapterThreeStoryTimelineData from "../data/chapter3-story.audio.json";
import chapterThreeStoryGeneratedAudioData from "../data/chapter3-story.audio.generated.json";
import chapterFourPrologueTimelineData from "../data/chapter4-prologue.audio.json";
import chapterFour755TimelineData from "../data/chapter4-755.audio.json";
import endlessArcadeTimelineData from "../data/endless-arcade.audio.json";
import audioTimelineData from "../data/library-finals.audio.json";
import generatedAudioData from "../data/library-finals.audio.generated.json";
import { isVoicedDialogue, storyLineForKey } from "../data/storyLines";
import { PRESENTATION_CUE_EVENT } from "./PresentationDirector";

type AudioChannel = "music" | "ambient" | "sfx" | "voice" | "text";
type MusicAction = "play" | "update" | "stop";

interface AudioCue {
  channel: AudioChannel;
  asset?: string;
  action?: MusicAction;
  offsetMs?: number;
  startMs?: number;
  durationMs?: number;
  volume?: number;
  loop?: boolean;
  playbackRate?: number;
  owner?: string;
  subtitleKey?: string;
  subtitleSurface?: "toast" | "scene";
  duckMusicTo?: number;
  once?: boolean;
}

interface AudioTimeline {
  events: Record<string, { cues: AudioCue[] }>;
}

interface GeneratedAsset {
  durationMs?: number;
}

const audioTimeline: AudioTimeline = {
  events: {
    ...(actOneTimelineData as AudioTimeline).events,
    ...(audioTimelineData as AudioTimeline).events,
    ...(bikeArcadeTimelineData as AudioTimeline).events,
    ...(endlessArcadeTimelineData as AudioTimeline).events,
    ...(chapterThreeCanteenTimelineData as AudioTimeline).events,
    ...(chapterThreeTheaterTimelineData as AudioTimeline).events,
    ...(chapterThreeQizhenTimelineData as AudioTimeline).events,
    ...(chapterThreeStoryTimelineData as AudioTimeline).events,
    ...(chapterFourPrologueTimelineData as AudioTimeline).events,
    ...(chapterFour755TimelineData as AudioTimeline).events
  }
};
const chapterFour755CueIds = new Set(
  Object.keys((chapterFour755TimelineData as AudioTimeline).events)
);
const endlessArcadeCueIds = new Set(
  Object.keys((endlessArcadeTimelineData as AudioTimeline).events)
);
const generatedAssets = {
  ...(actOneGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(generatedAudioData.assets as Record<string, GeneratedAsset>),
  ...(bikeArcadeGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(chapterThreeCanteenGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(chapterThreeTheaterGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(chapterThreeQizhenGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(chapterThreeQizhenSfxGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(chapter3InterludeVoiceMemosGeneratedAudioData.assets as Record<string, GeneratedAsset>),
  ...(chapterThreeStoryGeneratedAudioData.assets as Record<string, GeneratedAsset>)
};
const audioUrls = import.meta.glob("../assets/audio/**/*.mp3", {
  eager: true,
  query: "?url",
  import: "default"
}) as Record<string, string>;

const audioUrlsByAsset = new Map<string, string>();
for (const [path, url] of Object.entries(audioUrls)) {
  const pathParts = path.split("/");
  const filename = pathParts[pathParts.length - 1];
  if (filename?.endsWith(".mp3")) audioUrlsByAsset.set(filename.slice(0, -4), url);
}

function urlForAsset(asset: string): string | null {
  return audioUrlsByAsset.get(asset) ?? null;
}

export function visibleGraphemeCount(text: string): number {
  type SegmenterConstructor = new (
    locale: string,
    options: { granularity: "grapheme" }
  ) => { segment(input: string): Iterable<{ segment: string }> };
  const Segmenter = (Intl as unknown as { Segmenter?: SegmenterConstructor }).Segmenter;
  if (typeof Segmenter === "function") {
    return Array.from(new Segmenter("zh", { granularity: "grapheme" }).segment(text))
      .filter(({ segment }) => segment.trim().length > 0).length;
  }
  return Array.from(text).filter((character) => character.trim().length > 0).length;
}

export function textFeedbackDuration(text: string): number {
  return Math.max(2400, Math.min(6500, 1600 + 120 * visibleGraphemeCount(text)));
}

function toastTone(kind: "dialogue" | "taunt" | "task", speaker?: StoryLine["speaker"]) {
  if (kind === "task") return "task" as const;
  return speaker === "narrator" ? "system" as const : "xiaoying" as const;
}

/**
 * 全局音频调度器。它只消费领域事件，不参与任何关卡状态变化。
 * 音频缺失、自动播放受限或播放失败时，游戏逻辑仍会继续。
 */
export class AudioDirector {
  private currentVoice: HTMLAudioElement | null = null;
  private music: HTMLAudioElement | null = null;
  private musicAsset: string | null = null;
  private musicTargetVolume = 0.2;
  private musicMuted = false;
  private readonly ambients = new Map<string, { asset: string; audio: HTMLAudioElement }>();
  private readonly scheduled = new Map<number, string>();
  private readonly playedOnce = new Set<string>();
  private voiceRestoreTimer: number | null = null;

  attach(events: EventBus): () => void {
    const unsubscribe = events.subscribe((event) => this.onEvent(events, event));
    return () => {
      unsubscribe();
      this.scheduled.forEach((_eventName, timer) => window.clearTimeout(timer));
      this.scheduled.clear();
      this.stopVoice();
      this.stopAmbients();
      this.music?.pause();
      this.music = null;
      this.musicAsset = null;
    };
  }

  setMusicMuted(muted: boolean): void {
    this.musicMuted = muted;
    if (this.music) {
      this.music.muted = muted;
    }
  }

  private onEvent(events: EventBus, event: GameEvent): void {
    if (event.name !== PRESENTATION_CUE_EVENT) {
      return;
    }
    const cueId = String(event.payload?.cueId ?? "");
    if (!cueId) {
      return;
    }
    if (cueId === "bike_arcade_closed") {
      this.cancelScheduled("bike_arcade_");
      this.stopVoice();
    }
    if (cueId === "endless_arcade_closed" || cueId === "endless_arcade_hub_returned") {
      this.cancelScheduledCueIds(endlessArcadeCueIds);
      this.stopVoice();
    }
    // 第四章序幕：跳过、完成或中途离开时取消未播音效并停止人声；音乐由
    // chapter4_prologue_finished / chapter4_prologue_closed 的 music stop 接管。
    if (
      cueId === "chapter4_prologue_skip"
      || cueId === "chapter4_prologue_finished"
      || cueId === "chapter4_prologue_closed"
    ) {
      this.cancelScheduled("chapter4_prologue_");
      this.stopVoice();
    }
    if (cueId === "chapter4_755_scene_closed") {
      this.cancelScheduledCueIds(chapterFour755CueIds);
      this.stopVoice();
      this.stopAmbients("chapter4_");
    }
    if (cueId === "chapter35_voice_audition_stop") {
      this.cancelScheduled("chapter35_voice_audition_");
      this.stopVoice();
      return;
    }
    const beat = audioTimeline.events[cueId];
    if (!beat) {
      return;
    }
    const dynamicSubtitleKey = typeof event.payload?.subtitleKey === "string"
      ? event.payload.subtitleKey
      : null;
    const eventPreview = cueId.startsWith("chapter35_voice_audition_")
      && event.payload?.previewKind === "event";
    const eventStartMs = eventPreview && typeof event.payload?.startMs === "number"
      && Number.isFinite(event.payload.startMs)
      ? Math.max(0, event.payload.startMs)
      : null;
    const eventDurationMs = eventPreview && typeof event.payload?.durationMs === "number"
      && Number.isFinite(event.payload.durationMs)
      ? Math.max(120, Math.min(10_000, event.payload.durationMs))
      : null;
    const cues = beat.cues.map((cue) => {
      const subtitleKey = dynamicSubtitleKey ?? cue.subtitleKey;
      const storyLine = storyLineForKey(subtitleKey);
      return {
        ...cue,
        subtitleKey,
        ...(eventStartMs === null ? {} : { startMs: eventStartMs }),
        ...(eventDurationMs === null ? {} : { durationMs: eventDurationMs }),
        asset: cue.asset ?? (cue.channel === "voice" ? storyLine?.voiceAsset : undefined)
      };
    });
    cues.forEach((cue) => {
      const onceKey = cue.asset ?? `${cueId}:${cue.subtitleKey ?? cue.channel}`;
      if (cue.once && this.playedOnce.has(onceKey)) {
        return;
      }
      if (cue.once) {
        this.playedOnce.add(onceKey);
      }
      const timer = window.setTimeout(() => {
        this.scheduled.delete(timer);
        this.playCue(events, cue);
      }, cue.offsetMs ?? 0);
      this.scheduled.set(timer, cueId);
    });
  }

  private cancelScheduled(eventPrefix: string): void {
    this.scheduled.forEach((eventName, timer) => {
      if (!eventName.startsWith(eventPrefix)) {
        return;
      }
      window.clearTimeout(timer);
      this.scheduled.delete(timer);
    });
  }

  private cancelScheduledCueIds(cueIds: ReadonlySet<string>): void {
    this.scheduled.forEach((eventName, timer) => {
      if (!cueIds.has(eventName)) return;
      window.clearTimeout(timer);
      this.scheduled.delete(timer);
    });
  }

  private playCue(events: EventBus, cue: AudioCue): void {
    if (cue.channel === "text") {
      this.playText(events, cue);
      return;
    }
    if (cue.channel === "music") {
      this.updateMusic(cue);
      return;
    }
    if (cue.channel === "ambient") {
      this.updateAmbient(cue);
      return;
    }
    if (cue.channel === "voice") {
      if (cue.asset && !cue.subtitleKey) {
        this.playVoice(events, cue);
        return;
      }
      const storyLine = storyLineForKey(cue.subtitleKey);
      if (!isVoicedDialogue(storyLine)) {
        this.playText(events, cue);
        return;
      }
      this.playVoice(events, cue);
      return;
    }
    this.playOneShot(cue);
  }

  private playText(events: EventBus, cue: AudioCue): void {
    const storyLine = storyLineForKey(cue.subtitleKey);
    if (!storyLine || cue.subtitleSurface === "scene") return;
    events.emit("toast", {
      text: storyLine.subtitleZh,
      tone: toastTone(storyLine.kind, storyLine.speaker),
      durationMs: textFeedbackDuration(storyLine.subtitleZh)
    });
  }

  private updateMusic(cue: AudioCue): void {
    try {
      if (typeof Audio === "undefined") {
        return;
      }
      if (cue.action === "stop") {
        this.music?.pause();
        this.music = null;
        this.musicAsset = null;
        return;
      }

      const volume = cue.volume ?? this.musicTargetVolume;
      this.musicTargetVolume = volume;
      if (!this.music || this.musicAsset !== cue.asset) {
        if (!cue.asset) return;
        const url = urlForAsset(cue.asset);
        if (!url) {
          return;
        }
        this.music?.pause();
        this.music = new Audio(url);
        this.music.muted = this.musicMuted;
        this.musicAsset = cue.asset;
      }

      this.music.volume = volume;
      this.music.loop = cue.loop ?? this.music.loop;
      this.music.playbackRate = cue.playbackRate ?? this.music.playbackRate;
      const result = this.music.play();
      result?.catch(() => undefined);
    } catch {
      /* Audio is optional for gameplay. */
    }
  }

  private updateAmbient(cue: AudioCue): void {
    try {
      if (typeof Audio === "undefined") return;
      const owner = cue.owner ?? cue.asset ?? "ambient_default";
      const current = this.ambients.get(owner);
      if (cue.action === "stop") {
        current?.audio.pause();
        this.ambients.delete(owner);
        return;
      }
      if (!cue.asset) return;
      const url = urlForAsset(cue.asset);
      if (!url) return;
      let audio: HTMLAudioElement;
      if (!current || current.asset !== cue.asset) {
        current?.audio.pause();
        audio = new Audio(url);
        this.ambients.set(owner, { asset: cue.asset, audio });
      } else {
        audio = current.audio;
      }
      audio.volume = cue.volume ?? 0.18;
      audio.loop = cue.loop ?? true;
      audio.playbackRate = cue.playbackRate ?? 1;
      const result = audio.play();
      result?.catch(() => undefined);
    } catch {
      /* Ambient audio is optional for gameplay. */
    }
  }

  private stopAmbients(ownerPrefix?: string): void {
    this.ambients.forEach(({ audio }, owner) => {
      if (ownerPrefix && !owner.startsWith(ownerPrefix)) return;
      audio.pause();
      this.ambients.delete(owner);
    });
  }

  private playVoice(events: EventBus, cue: AudioCue): void {
    if (!cue.asset) return;
    const generatedDuration = generatedAssets[cue.asset]?.durationMs;
    const durationMs = cue.durationMs ?? generatedDuration ?? 3600;
    const narration = storyLineForKey(cue.subtitleKey);
    if (narration && cue.subtitleSurface !== "scene") {
      events.emit("toast", {
        text: narration.subtitleZh,
        tone: toastTone(narration.kind, narration.speaker),
        durationMs: durationMs + 450
      });
    }

    const restoreMusic = () => {
      if (this.music) {
        this.music.volume = this.musicTargetVolume;
      }
    };

    try {
      if (typeof Audio === "undefined") {
        return;
      }
      const url = urlForAsset(cue.asset);
      if (!url) {
        return;
      }
      this.stopVoice();
      const audio = new Audio(url);
      this.currentVoice = audio;
      audio.volume = cue.volume ?? 1;
      const startAtSeconds = Math.max(0, cue.startMs ?? 0) / 1000;
      if (startAtSeconds > 0) {
        const applySeek = () => {
          try {
            audio.currentTime = startAtSeconds;
          } catch {
            // A failed optional seek falls back to the beginning of the clip.
          }
        };
        if (audio.readyState >= 1) applySeek();
        else audio.addEventListener("loadedmetadata", applySeek, { once: true });
      }
      if (this.music && cue.duckMusicTo !== undefined) {
        this.music.volume = cue.duckMusicTo;
      }
      const finishVoice = () => {
        if (this.currentVoice === audio) this.currentVoice = null;
        if (this.voiceRestoreTimer !== null) {
          window.clearTimeout(this.voiceRestoreTimer);
          this.voiceRestoreTimer = null;
        }
        restoreMusic();
      };
      audio.addEventListener("ended", finishVoice, { once: true });
      audio.addEventListener("error", finishVoice, { once: true });
      this.voiceRestoreTimer = window.setTimeout(() => {
        if (this.currentVoice === audio) audio.pause();
        finishVoice();
      }, durationMs);
      const result = audio.play();
      result?.catch(finishVoice);
    } catch {
      restoreMusic();
    }
  }

  private stopVoice(): void {
    this.currentVoice?.pause();
    this.currentVoice = null;
    if (this.voiceRestoreTimer !== null) {
      window.clearTimeout(this.voiceRestoreTimer);
      this.voiceRestoreTimer = null;
    }
    if (this.music) {
      this.music.volume = this.musicTargetVolume;
    }
  }

  private playOneShot(cue: AudioCue): void {
    if (!cue.asset) return;
    try {
      if (typeof Audio === "undefined") {
        return;
      }
      const url = urlForAsset(cue.asset);
      if (!url) {
        return;
      }
      const audio = new Audio(url);
      audio.volume = cue.volume ?? 0.8;
      if (cue.playbackRate) {
        audio.playbackRate = cue.playbackRate;
      }
      if (cue.startMs) {
        audio.currentTime = cue.startMs / 1000;
      }
      const result = audio.play();
      result?.catch(() => undefined);
      if (cue.durationMs) {
        window.setTimeout(() => {
          audio.pause();
          audio.currentTime = 0;
        }, cue.durationMs);
      }
    } catch {
      /* Audio is optional for gameplay. */
    }
  }
}

export const audioDirector = new AudioDirector();
