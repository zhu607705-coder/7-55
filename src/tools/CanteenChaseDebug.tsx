// Manual art-direction harness for the canteen bike chase.
// Open via `npm run dev` then /canteen-chase-debug.html
//
// Query params (renderer mode, default):
//   distance=377     world distance in metres (deterministic obstacles)
//   lane=1           rider lane 0..2
//   collisions=0     collision count (drives the red flash on first frames)
//   invulnerable=0   invulnerability window in ms (rider blink)
//   state=running    running | won | lost
//   animate=1        advance distance in real time instead of a static frame
//   reduced=1        force reduced-motion rendering
//
// mode=overlay mounts the real CanteenChaseOverlay (HUD + narration + input).
import React from "react";
import { createRoot } from "react-dom/client";
import "../styles.css";
import { EventBus } from "../core/EventBus";
import { CanteenChaseOverlay } from "../scenes/rpg/CanteenChaseOverlay";
import { ChaseRenderer, type ChaseRenderState } from "../scenes/rpg/canteen-chase/ChaseRenderer";

function numberParam(params: URLSearchParams, name: string, fallback: number): number {
  const raw = params.get(name);
  if (raw === null) return fallback;
  const value = Number(raw);
  return Number.isFinite(value) ? value : fallback;
}

function mountRenderer(params: URLSearchParams): void {
  const host = document.getElementById("canteen-chase-debug");
  if (!host) return;
  document.body.style.margin = "0";
  document.body.style.background = "#111";
  const canvas = document.createElement("canvas");
  canvas.style.width = "960px";
  canvas.style.height = "540px";
  canvas.style.display = "block";
  host.appendChild(canvas);

  const renderer = new ChaseRenderer(canvas);
  renderer.setReducedMotion(params.get("reduced") === "1");

  const stateParam = params.get("state");
  const state: ChaseRenderState = {
    runState: stateParam === "won" || stateParam === "lost" ? stateParam : "running",
    distance: numberParam(params, "distance", 0),
    lane: Math.max(0, Math.min(2, numberParam(params, "lane", 1))),
    invulnerableMs: numberParam(params, "invulnerable", 0),
    collisions: numberParam(params, "collisions", 0),
    paused: false
  };

  if (params.get("animate") === "1") {
    let last = performance.now();
    const tick = (now: number) => {
      const delta = Math.min(48, Math.max(0, now - last));
      last = now;
      if (state.runState === "running") {
        state.distance = Math.min(755, state.distance + delta * 0.04);
        state.invulnerableMs = Math.max(0, state.invulnerableMs - delta);
      }
      renderer.render(state);
      window.requestAnimationFrame(tick);
    };
    window.requestAnimationFrame(tick);
    return;
  }

  // Static frame: render enough frames for the rider lane-lerp to settle so
  // screenshots are deterministic.
  let frames = 0;
  const settle = () => {
    renderer.render(state);
    frames += 1;
    if (frames < 90) window.requestAnimationFrame(settle);
  };
  window.requestAnimationFrame(settle);
}

function mountOverlay(): void {
  const host = document.getElementById("canteen-chase-debug");
  if (!host) return;
  document.body.style.margin = "0";
  // Mirror the production .rpg-stage > .rpg-shell wrapper so the portrait
  // media query can resolve --rpg-mobile-canvas-height.
  host.className = "rpg-stage";
  const shell = document.createElement("div");
  shell.className = "rpg-shell";
  shell.style.position = "relative";
  host.appendChild(shell);
  const events = new EventBus();
  const root = createRoot(shell);
  root.render(
    <React.StrictMode>
      <CanteenChaseOverlay events={events} onAttempt={() => undefined} onContinue={() => undefined} />
    </React.StrictMode>
  );
}

const params = new URLSearchParams(window.location.search);
if (params.get("mode") === "overlay") mountOverlay();
else mountRenderer(params);
