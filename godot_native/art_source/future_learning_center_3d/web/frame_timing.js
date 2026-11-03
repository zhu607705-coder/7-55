// Walking uses small collision steps. Furniture follows active wall-clock time.
// A gap over five seconds is treated as a suspended frame, not catch-up work.
export function frameTimeSteps(now, previous, paused = false) {
  const gapMs = previous === null ? 0 : Math.max(0, now - previous);
  const elapsed = Number.isFinite(gapMs) ? gapMs / 1000 : 0;
  return {
    previous: paused ? null : now,
    gapMs,
    walkDt: paused ? 0 : Math.min(.05, elapsed),
    deskDt: paused || elapsed > 5 ? 0 : elapsed,
  };
}
