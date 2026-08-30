let developerInputBlocked = false;

function isDeveloperChannelTarget(target: EventTarget | null): boolean {
  return target instanceof Element && target.closest("[data-developer-channel-root]") !== null;
}

function blockBackgroundKeyboardEvent(event: KeyboardEvent): void {
  if (!developerInputBlocked) return;
  if (!isDeveloperChannelTarget(event.target)) event.preventDefault();
  event.stopImmediatePropagation();
}

if (typeof document !== "undefined") {
  document.addEventListener("keydown", blockBackgroundKeyboardEvent);
  document.addEventListener("keyup", blockBackgroundKeyboardEvent);
}

export function setDeveloperInputBlocked(blocked: boolean): void {
  developerInputBlocked = blocked;
  if (typeof document !== "undefined") {
    document.documentElement.dataset.developerInputBlocked = blocked ? "true" : "false";
  }
}

export function isDeveloperInputBlocked(): boolean {
  return developerInputBlocked;
}
