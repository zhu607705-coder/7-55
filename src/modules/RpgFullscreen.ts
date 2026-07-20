import { detectInputProfile } from "../core/ClientCompatibility";

const DESKTOP_MIN_WIDTH = 768;

type WebkitFullscreenDocument = Document & {
  webkitExitFullscreen?: () => Promise<void> | void;
  webkitFullscreenElement?: Element | null;
};

type WebkitFullscreenElement = HTMLElement & {
  webkitRequestFullscreen?: () => Promise<void> | void;
};

function isDesktopPointer(): boolean {
  if (typeof window === "undefined") {
    return false;
  }
  const inputProfile = detectInputProfile();
  const pointerIsFine = inputProfile === "fine" || inputProfile === "hybrid";
  return window.innerWidth >= DESKTOP_MIN_WIDTH && pointerIsFine;
}

function getFullscreenElement(): Element | null {
  if (typeof document === "undefined") return null;
  return document.fullscreenElement ?? (document as WebkitFullscreenDocument).webkitFullscreenElement ?? null;
}

export function requestDesktopRpgFullscreen(): void {
  if (typeof document === "undefined" || !isDesktopPointer() || getFullscreenElement()) {
    return;
  }
  try {
    const target = document.documentElement as WebkitFullscreenElement;
    const request = target.requestFullscreen ?? target.webkitRequestFullscreen;
    const result = request?.call(target);
    if (result) Promise.resolve(result).catch(() => undefined);
  } catch {
    // CSS full-viewport mode remains available when the browser blocks fullscreen.
  }
}

export function exitRpgFullscreen(): void {
  if (typeof document === "undefined" || !getFullscreenElement()) {
    return;
  }
  try {
    const fullscreenDocument = document as WebkitFullscreenDocument;
    const exit = fullscreenDocument.exitFullscreen ?? fullscreenDocument.webkitExitFullscreen;
    const result = exit?.call(fullscreenDocument);
    if (result) Promise.resolve(result).catch(() => undefined);
  } catch {
    // Native Escape and the viewport layout remain usable.
  }
}

export function toggleRpgFullscreen(): void {
  if (typeof document === "undefined") {
    return;
  }
  if (getFullscreenElement()) {
    exitRpgFullscreen();
    return;
  }
  requestDesktopRpgFullscreen();
}
