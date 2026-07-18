const DESKTOP_MIN_WIDTH = 768;

function isDesktopPointer(): boolean {
  if (typeof window === "undefined") {
    return false;
  }
  const pointerIsFine = typeof window.matchMedia === "function" && window.matchMedia("(pointer: fine)").matches;
  return window.innerWidth >= DESKTOP_MIN_WIDTH && pointerIsFine;
}

export function requestDesktopRpgFullscreen(): void {
  if (typeof document === "undefined" || !isDesktopPointer() || document.fullscreenElement) {
    return;
  }
  try {
    const result = document.documentElement.requestFullscreen?.();
    result?.catch(() => undefined);
  } catch {
    // CSS full-viewport mode remains available when the browser blocks fullscreen.
  }
}

export function exitRpgFullscreen(): void {
  if (typeof document === "undefined" || !document.fullscreenElement) {
    return;
  }
  try {
    const result = document.exitFullscreen?.();
    result?.catch(() => undefined);
  } catch {
    // Native Escape and the viewport layout remain usable.
  }
}

export function toggleRpgFullscreen(): void {
  if (typeof document === "undefined") {
    return;
  }
  if (document.fullscreenElement) {
    exitRpgFullscreen();
    return;
  }
  requestDesktopRpgFullscreen();
}
