export type BrowserEngine = "blink" | "webkit" | "gecko" | "unknown";
export type ClientPlatform = "ios" | "android" | "desktop";
export type InputProfile = "fine" | "coarse" | "hybrid" | "unknown";

export interface ClientViewportMetrics {
  width: number;
  height: number;
  layoutWidth: number;
  layoutHeight: number;
  scale: number;
}

export interface ClientCompatibilitySnapshot {
  engine: BrowserEngine;
  platform: ClientPlatform;
  inputProfile: InputProfile;
  viewport: ClientViewportMetrics;
  capabilities: {
    pointerEvents: boolean;
    visualViewport: boolean;
    resizeObserver: boolean;
    inert: boolean;
    structuredClone: boolean;
    fullscreen: "standard" | "webkit" | "none";
    webAudio: "standard" | "webkit" | "none";
    dynamicViewportUnits: boolean;
    containerQueryUnits: boolean;
  };
}

type WebkitAudioWindow = Window & typeof globalThis & {
  webkitAudioContext?: typeof AudioContext;
};

type WebkitFullscreenElement = HTMLElement & {
  webkitRequestFullscreen?: () => Promise<void> | void;
};

function mediaMatches(query: string): boolean {
  return typeof window !== "undefined"
    && typeof window.matchMedia === "function"
    && window.matchMedia(query).matches;
}

function isIosPlatform(): boolean {
  if (typeof navigator === "undefined") return false;
  return /iPad|iPhone|iPod/i.test(navigator.userAgent)
    || (/Mac/i.test(navigator.platform) && navigator.maxTouchPoints > 1);
}

export function detectBrowserEngine(): BrowserEngine {
  if (typeof navigator === "undefined") return "unknown";
  const userAgent = navigator.userAgent;
  if (isIosPlatform()) return "webkit";
  if (/Firefox\//i.test(userAgent)) return "gecko";
  if (/AppleWebKit/i.test(userAgent) && !/(Chrome|Chromium|Edg|OPR)\//i.test(userAgent)) {
    return "webkit";
  }
  if (/(Chrome|Chromium|Edg|OPR)\//i.test(userAgent)) return "blink";
  return "unknown";
}

export function detectClientPlatform(): ClientPlatform {
  if (isIosPlatform()) return "ios";
  if (typeof navigator !== "undefined" && /Android/i.test(navigator.userAgent)) return "android";
  return "desktop";
}

export function detectInputProfile(): InputProfile {
  if (typeof window === "undefined") return "unknown";
  const hasFine = mediaMatches("(any-pointer: fine)") || mediaMatches("(pointer: fine)");
  const hasCoarse = mediaMatches("(any-pointer: coarse)")
    || mediaMatches("(pointer: coarse)")
    || (typeof navigator !== "undefined" && navigator.maxTouchPoints > 0);
  if (hasFine && hasCoarse) return "hybrid";
  if (hasCoarse) return "coarse";
  if (hasFine) return "fine";
  return "unknown";
}

export function getClientViewportMetrics(): ClientViewportMetrics {
  if (typeof window === "undefined") {
    return { width: 0, height: 0, layoutWidth: 0, layoutHeight: 0, scale: 1 };
  }
  const viewport = window.visualViewport;
  const scale = viewport?.scale ?? 1;
  const layoutWidth = document.documentElement.clientWidth || window.innerWidth;
  const layoutHeight = document.documentElement.clientHeight || window.innerHeight;
  return {
    width: Math.max(1, Math.round(viewport ? viewport.width * scale : window.innerWidth ?? layoutWidth)),
    height: Math.max(1, Math.round(viewport ? viewport.height * scale : window.innerHeight ?? layoutHeight)),
    layoutWidth: Math.max(1, Math.round(layoutWidth)),
    layoutHeight: Math.max(1, Math.round(layoutHeight)),
    scale
  };
}

export function getAudioContextConstructor(): typeof AudioContext | undefined {
  if (typeof window === "undefined") return undefined;
  const audioWindow = window as WebkitAudioWindow;
  return audioWindow.AudioContext ?? audioWindow.webkitAudioContext;
}

export function cloneSerializable<T>(value: T): T {
  if (typeof structuredClone === "function") return structuredClone(value);
  return JSON.parse(JSON.stringify(value)) as T;
}

export function getClientCompatibilitySnapshot(): ClientCompatibilitySnapshot {
  const root = typeof document === "undefined" ? undefined : document.documentElement;
  const fullscreenElement = root as WebkitFullscreenElement | undefined;
  const fullscreen = typeof root?.requestFullscreen === "function"
    ? "standard"
    : typeof fullscreenElement?.webkitRequestFullscreen === "function"
      ? "webkit"
      : "none";
  const audioWindow = typeof window === "undefined" ? undefined : window as WebkitAudioWindow;
  const webAudio = typeof audioWindow?.AudioContext === "function"
    ? "standard"
    : typeof audioWindow?.webkitAudioContext === "function"
      ? "webkit"
      : "none";
  const supportsCss = typeof CSS !== "undefined" && typeof CSS.supports === "function";

  return {
    engine: detectBrowserEngine(),
    platform: detectClientPlatform(),
    inputProfile: detectInputProfile(),
    viewport: getClientViewportMetrics(),
    capabilities: {
      pointerEvents: typeof window !== "undefined" && "PointerEvent" in window,
      visualViewport: typeof window !== "undefined" && window.visualViewport !== undefined,
      resizeObserver: typeof window !== "undefined" && "ResizeObserver" in window,
      inert: typeof HTMLElement !== "undefined" && "inert" in HTMLElement.prototype,
      structuredClone: typeof structuredClone === "function",
      fullscreen,
      webAudio,
      dynamicViewportUnits: supportsCss && CSS.supports("height", "100dvh"),
      containerQueryUnits: supportsCss && CSS.supports("width", "1cqw")
    }
  };
}

export function subscribeMediaQuery(query: string, onChange: (matches: boolean) => void): () => void {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") {
    return () => undefined;
  }
  const media = window.matchMedia(query);
  const update = () => onChange(media.matches);
  if (typeof media.addEventListener === "function") {
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }
  media.addListener(update);
  return () => media.removeListener(update);
}

export function readMediaQuery(query: string, fallback = false): boolean {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") return fallback;
  return window.matchMedia(query).matches;
}

export function installClientCompatibility(): () => void {
  if (typeof window === "undefined" || typeof document === "undefined") return () => undefined;
  const root = document.documentElement;
  const update = () => {
    const snapshot = getClientCompatibilitySnapshot();
    root.dataset.browserEngine = snapshot.engine;
    root.dataset.clientPlatform = snapshot.platform;
    root.dataset.inputProfile = snapshot.inputProfile;
    root.style.setProperty("--app-viewport-width", `${snapshot.viewport.width}px`);
    root.style.setProperty("--app-viewport-height", `${snapshot.viewport.height}px`);
    root.style.setProperty("--app-vw", `${snapshot.viewport.width / 100}px`);
    root.style.setProperty("--app-vh", `${snapshot.viewport.height / 100}px`);
  };

  window.addEventListener("resize", update, { passive: true });
  window.addEventListener("orientationchange", update, { passive: true });
  window.visualViewport?.addEventListener("resize", update, { passive: true });
  window.visualViewport?.addEventListener("scroll", update, { passive: true });
  const stopFine = subscribeMediaQuery("(any-pointer: fine)", update);
  const stopCoarse = subscribeMediaQuery("(any-pointer: coarse)", update);
  const stopHover = subscribeMediaQuery("(any-hover: hover)", update);
  update();

  return () => {
    window.removeEventListener("resize", update);
    window.removeEventListener("orientationchange", update);
    window.visualViewport?.removeEventListener("resize", update);
    window.visualViewport?.removeEventListener("scroll", update);
    stopFine();
    stopCoarse();
    stopHover();
  };
}
