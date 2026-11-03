// Walking uses small collision steps. Furniture follows active wall-clock time.
// Only explicit lifecycle pause signals suspend furniture; a slow frame does not.
export function frameTimeSteps(now, previous, paused = false) {
  const gapMs = previous === null ? 0 : Math.max(0, now - previous);
  const elapsed = Number.isFinite(gapMs) ? gapMs / 1000 : 0;
  return {
    previous: paused ? null : now,
    gapMs,
    walkDt: paused ? 0 : Math.min(.05, elapsed),
    deskDt: paused ? 0 : elapsed,
  };
}
