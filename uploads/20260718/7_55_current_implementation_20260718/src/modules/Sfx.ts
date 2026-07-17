/**
 * 音效播放器：src/assets/audio/sfx 下的 mp3 按文件名前缀调用。
 * playSfx("17_") 会匹配 17_p08_settings_gear_drop_flip.mp3。
 * 所有失败静默忽略（jsdom / 自动播放策略受限时不影响玩法）。
 */
const sfxUrls = import.meta.glob("../assets/audio/sfx/*.mp3", {
  eager: true,
  query: "?url",
  import: "default"
}) as Record<string, string>;

export interface SfxHandle {
  stop: () => void;
}

export function playSfx(fragment: string, opts?: { volume?: number; loop?: boolean }): SfxHandle | null {
  try {
    const entry = Object.entries(sfxUrls).find(([path]) => path.includes(`/${fragment}`) || path.includes(fragment));
    if (!entry || typeof Audio === "undefined") {
      return null;
    }
    const audio = new Audio(entry[1]);
    audio.volume = opts?.volume ?? 0.9;
    audio.loop = opts?.loop ?? false;
    const result = audio.play();
    if (result && typeof result.catch === "function") {
      result.catch(() => undefined);
    }
    return {
      stop() {
        try {
          audio.pause();
          audio.currentTime = 0;
        } catch {
          /* ignore */
        }
      }
    };
  } catch {
    return null;
  }
}
