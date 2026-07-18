import { eventBus } from "../core/EventBus";
import voMap from "../data/vo.map.json";
import { isVoicedDialogue, storyLineForKey } from "../data/storyLines";
import { textFeedbackDuration } from "./AudioDirector";

/**
 * 台词配音播放器：逐句文件（src/assets/audio/vo/all_shadow_vo_XXX.mp3），
 * 由 src/data/vo.map.json 把台词 key 映射到文件编号。
 * - 默认同步弹出中文字幕气泡，显示时长跟随音频时长
 * - onEnded 在播放结束后回调（播放失败时按 fallbackMs 兜底触发）
 * 同一时间只播一句（新台词打断上一句）。所有失败静默降级。
 */
const voUrls = import.meta.glob("../assets/audio/vo/*.mp3", {
  eager: true,
  query: "?url",
  import: "default"
}) as Record<string, string>;

export type VoKey = keyof typeof voMap.lines;

export interface PlayVoOptions {
  /** 同步显示字幕气泡；默认开启，文本取自 vo.map.json */
  subtitle?: boolean;
  tone?: "system" | "xiaoying" | "task";
  /** 音频播完（或失败兜底）后的回调 */
  onEnded?: () => void;
  /** 播放失败/无时长信息时的兜底时长 */
  fallbackMs?: number;
}

export interface VoPlaybackHandle {
  /** 提前结束当前台词，并按正常结束继续剧情。 */
  skip: () => void;
  /** 静默停止当前台词，不触发后续剧情。 */
  cancel: () => void;
}

let current: VoPlaybackHandle | null = null;

function createTimedHandle(
  durationMs: number,
  onEnded?: () => void,
  registerAsCurrent = false
): VoPlaybackHandle {
  let active = true;
  let timer: number | null = null;
  let handle: VoPlaybackHandle;

  const settle = (continueStory: boolean) => {
    if (!active) {
      return;
    }
    active = false;
    if (timer !== null) {
      window.clearTimeout(timer);
      timer = null;
    }
    if (current === handle) {
      current = null;
    }
    if (continueStory) {
      onEnded?.();
    }
  };

  handle = {
    skip: () => settle(true),
    cancel: () => settle(false)
  };
  timer = window.setTimeout(() => settle(true), durationMs);
  if (registerAsCurrent) {
    current = handle;
  }
  return handle;
}

function urlFor(key: VoKey): string | null {
  const suffix = (voMap.files as Record<string, string>)[key];
  if (!suffix) {
    return null;
  }
  const entry = Object.entries(voUrls).find(([path]) => path.endsWith(`_${suffix}.mp3`));
  return entry?.[1] ?? null;
}

export function voiceRoleForVoKey(key: VoKey): "male_narrator" | "female_system" | null {
  return storyLineForKey(key)?.voiceRole ?? null;
}

export function playVo(key: VoKey, opts: PlayVoOptions = {}): VoPlaybackHandle {
  const fallbackMs = opts.fallbackMs ?? 3200;
  const text = voMap.lines[key];
  const subtitleEnabled = opts.subtitle ?? true;
  const storyLine = storyLineForKey(key);

  const emitSubtitle = (durationMs: number) => {
    if (subtitleEnabled && text) {
      eventBus.emit("toast", {
        text,
        tone: opts.tone ?? (storyLine?.speaker === "narrator" ? "system" : "xiaoying"),
        durationMs
      });
    }
  };

  if (!isVoicedDialogue(storyLine)) {
    const durationMs = textFeedbackDuration(text);
    emitSubtitle(durationMs);
    return createTimedHandle(durationMs, opts.onEnded);
  }

  current?.cancel();

  try {
    if (typeof Audio === "undefined") {
      emitSubtitle(fallbackMs);
      return createTimedHandle(fallbackMs, opts.onEnded, true);
    }
    const url = urlFor(key);
    if (!url) {
      emitSubtitle(fallbackMs);
      return createTimedHandle(fallbackMs, opts.onEnded, true);
    }

    const audio = new Audio(url);
    audio.volume = 1;

    let settled = false;
    let safety: number | null = null;
    let subtitleFallback: number | null = null;
    let handle: VoPlaybackHandle;
    const clearTimers = () => {
      if (safety !== null) {
        window.clearTimeout(safety);
        safety = null;
      }
      if (subtitleFallback !== null) {
        window.clearTimeout(subtitleFallback);
        subtitleFallback = null;
      }
    };
    const finish = () => {
      if (settled) {
        return;
      }
      settled = true;
      clearTimers();
      if (current === handle) {
        current = null;
      }
      opts.onEnded?.();
    };
    const cancel = () => {
      if (settled) {
        return;
      }
      settled = true;
      clearTimers();
      audio.pause();
      if (current === handle) {
        current = null;
      }
    };
    handle = {
      skip: () => {
        if (settled) {
          return;
        }
        audio.pause();
        finish();
      },
      cancel
    };
    current = handle;

    // 时长已知后再发字幕，展示到音频结束；元数据迟迟不来则兜底
    let subtitleSent = false;
    const sendSubtitleOnce = (durationMs: number) => {
      if (subtitleSent) {
        return;
      }
      subtitleSent = true;
      emitSubtitle(durationMs);
    };

    // 保底结束定时器：无论播放/事件是否可用，onEnded 一定会被触发一次
    safety = window.setTimeout(finish, fallbackMs + 800);

    audio.addEventListener("loadedmetadata", () => {
      if (settled) {
        return;
      }
      if (Number.isFinite(audio.duration)) {
        const ms = audio.duration * 1000;
        sendSubtitleOnce(ms + 500);
        if (safety !== null) {
          window.clearTimeout(safety);
        }
        safety = window.setTimeout(finish, ms + 800);
      } else {
        sendSubtitleOnce(fallbackMs);
      }
    });
    audio.addEventListener("ended", () => {
      finish();
    });
    audio.addEventListener("error", () => {
      if (settled) {
        return;
      }
      sendSubtitleOnce(fallbackMs);
    });
    subtitleFallback = window.setTimeout(() => sendSubtitleOnce(fallbackMs), 600);

    const result = audio.play();
    if (result && typeof result.catch === "function") {
      result.catch(() => {
        sendSubtitleOnce(fallbackMs);
      });
    }
    return handle;
  } catch {
    emitSubtitle(fallbackMs);
    return createTimedHandle(fallbackMs, opts.onEnded, true);
  }
}

/** 预热：在首次用户交互后调用，提前拉取音频文件避免第一句延迟 */
export function preloadVo(): void {
  try {
    if (typeof Audio === "undefined") {
      return;
    }
    const voicedSuffixes = new Set(
      (Object.keys(voMap.lines) as VoKey[])
        .filter((key) => voiceRoleForVoKey(key) !== null)
        .map((key) => (voMap.files as Record<string, string>)[key])
    );
    Object.entries(voUrls).filter(([path]) => (
      Array.from(voicedSuffixes).some((suffix) => path.endsWith(`_${suffix}.mp3`))
    )).forEach(([, url]) => {
      const audio = new Audio();
      audio.preload = "auto";
      audio.src = url;
    });
  } catch {
    /* ignore */
  }
}
