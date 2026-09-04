#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");
const failures = [];
let assertions = 0;

function assert(condition, message) {
  assertions += 1;
  if (!condition) failures.push(message);
}

function sameJson(actual, expected) {
  return JSON.stringify(actual) === JSON.stringify(expected);
}

function approximately(actual, expected, epsilon = 1e-9) {
  return Math.abs(actual - expected) <= epsilon;
}

const component = read(
  "src/components/temporal-maze/ChapterFourStarLampClosure.tsx"
);
const renderer = read(
  "src/components/temporal-maze/ChapterFourStarLampThreeRenderer.ts"
);
const sequenceSource = read(
  "src/components/temporal-maze/ChapterFourStarLampSequence.ts"
);
const contractSource = read("src/modules/ChapterFourClosureContract.ts");
const registrySource = read("src/modules/ChapterFourClosureSessionRegistry.ts");
const styles = read("src/styles/chapter4-755.css");
const readme = read(
  "src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/README.md"
);

const expectedLayerAssets = [
  "lamp_dark.png",
  "lamp_outline.png",
  "lamp_leds.png",
  "lamp_core.png",
  "lamp_glow.png"
];

for (const asset of expectedLayerAssets) {
  const assetPath = path.join(
    root,
    "src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp",
    asset
  );
  assert(fs.existsSync(assetPath), `approved layered asset is missing: ${asset}`);
  if (fs.existsSync(assetPath)) {
    assert(fs.statSync(assetPath).size > 0, `approved layered asset is empty: ${asset}`);
  }
  assert(component.includes(asset), `closure component must import ${asset}`);
  assert(contractSource.includes(`"${asset}"`), `closure contract must register ${asset}`);
  assert(readme.includes(`\`${asset}\``), `closure README must document ${asset}`);
}

assert(
  /new THREE\.PerspectiveCamera\(/.test(renderer)
    && /new THREE\.WebGLRenderer\(/.test(renderer)
    && /this\.camera\.position\.set\(/.test(renderer)
    && /const cameraRiseProgress = smootherStep/.test(sequenceSource)
    && /this\.lookAtTarget\.set\(/.test(renderer),
  "primary closure must move a real Three.js perspective camera upward from the lamp base"
);
assert(
  !/buildLamp|lampRoot|LatheGeometry|TorusGeometry|TubeGeometry|InstancedMesh|OctahedronGeometry/.test(renderer)
    && !/\.rotation\.(x|y|z)\s*=/.test(renderer)
    && /lampRotationY:\s*0/.test(renderer)
    && /dataset\.lampRotationY\s*=\s*"0\.0000"/.test(renderer),
  "Three.js stage must not rebuild or rotate the approved layered lamp"
);
assert(
  /chapter4-star-lamp-closure__artwork/.test(component)
    && /layered-original-v1/.test(component)
    && !/chapter4-star-lamp-closure__fallback-camera/.test(component),
  "the five original layers must remain the primary artwork in every renderer mode"
);
for (const starCount of [4200, 1600, 520]) {
  assert(
    renderer.includes(`this.createStarLayer(${starCount},`),
    `3D starfield is missing the ${starCount}-point depth layer`
  );
}
assert(
  /new THREE\.PointsMaterial\(/.test(renderer)
    && /new THREE\.Points\(geometry, material\)/.test(renderer)
    && !/points\.rotation/.test(renderer),
  "starfield layers must be fixed Three.js point geometry so only the camera orbits"
);

assert(
  /ResizeObserver/.test(component)
    && /window\.addEventListener\("resize", resizeRenderer\)/.test(component)
    && /window\.removeEventListener\("resize", resizeRenderer\)/.test(component),
  "closure must resize its perspective renderer and detach the resize listener"
);
assert(
  /useMediaQuery\("\(prefers-reduced-motion: reduce\)"\)/.test(component)
    && /CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE/.test(sequenceSource),
  "closure must provide a reduced-motion sequence"
);
assert(
  /document\.visibilityState === "hidden"/.test(component)
    && /document\.visibilityState === "hidden"/.test(renderer),
  "Three.js and fallback timelines must pause while the page is hidden"
);
assert(
  /cancelAnimationFrame/.test(renderer)
    && /removeEventListener\("webglcontextlost"/.test(renderer)
    && /geometry\.dispose\(\)/.test(renderer)
    && /material\.dispose\(\)/.test(renderer)
    && /texture\.dispose\(\)/.test(renderer)
    && /this\.renderer\.dispose\(\)/.test(renderer),
  "Three.js teardown must release RAF, listener, renderer, geometry, material and texture"
);
assert(
  !/setTimeout\(/.test(component)
    && /if \(frame\.phase === "complete"\)[\s\S]*?completeOnce\(\)/.test(component)
    && /onComplete:\s*completeOnce/.test(component),
  "completion must come from the completed timeline instead of an unconditional timeout"
);
assert(
  /renderer\.start\(\{[\s\S]*?onFailure:\s*startFallback/.test(component)
    && /if \(!canCreateWebGlContext\(\)\)[\s\S]*?startFallback\("star_lamp_webgl_unavailable"\)/.test(component)
    && /fallbackElapsedMs = 0/.test(component)
    && /requestAnimationFrame\(tickFallback\)/.test(component),
  "WebGL failure must restart one complete timed fallback sequence"
);
assert(
  /object-fit:\s*contain/.test(styles)
    && !/scaleX\(|scaleY\(/.test(styles)
    && !/@keyframes chapter4-star-lamp-camera/.test(styles),
  "original artwork must preserve aspect ratio and CSS must not run a separate camera animation"
);
assert(
  /--chapter4-star-lamp-camera-offset-y/.test(component)
    && /--chapter4-star-lamp-camera-scale/.test(component)
    && /translateY\(var\(--chapter4-star-lamp-camera-offset-y\)\)/.test(styles)
    && /scale\(var\(--chapter4-star-lamp-camera-scale\)\)/.test(styles),
  "the fixed layered artwork must follow the executable camera-rise projection"
);
assert(
  /\.chapter4-star-lamp-closure\.is-three[\s\S]*?__canvas/.test(styles)
    && /\.chapter4-star-lamp-closure\.is-fallback[\s\S]*?__fallback/.test(styles)
    && /\.chapter4-star-lamp-closure__artwork\s*\{[\s\S]*?z-index:\s*2/.test(styles),
  "closure styles must place the original layered artwork above either star background"
);
assert(
  registrySource.includes("if (!session || session.completed || session.consumed) return null")
    && registrySource.includes("session.consumed = true"),
  "closure registry must preserve one completion issue and one proof consumption"
);

let vite;
try {
  vite = await createServer({
    root,
    logLevel: "silent",
    appType: "custom",
    server: { middlewareMode: true, ws: false }
  });

  const sequenceModule = await vite.ssrLoadModule(
    "/src/components/temporal-maze/ChapterFourStarLampSequence.ts"
  );
  const contractModule = await vite.ssrLoadModule(
    "/src/modules/ChapterFourClosureContract.ts"
  );
  const registryModule = await vite.ssrLoadModule(
    "/src/modules/ChapterFourClosureSessionRegistry.ts"
  );

  const normal = sequenceModule.CHAPTER_FOUR_STAR_LAMP_SEQUENCE;
  const reduced = sequenceModule.CHAPTER_FOUR_STAR_LAMP_REDUCED_SEQUENCE;
  const resolveFrame = sequenceModule.resolveChapterFourStarLampSequenceFrame;
  const resolveCameraPose = sequenceModule.resolveChapterFourStarLampCameraPose;
  const reference = contractModule.CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE;

  assert(
    sameJson(normal, {
      durationMs: 5_800,
      revealEndMs: 260,
      riseStartMs: 120,
      riseEndMs: 2_200,
      lightStartMs: 2_350,
      coreStartMs: 2_750,
      fullyLitMs: 4_050,
      captionStartMs: 4_150
    }),
    "normal sequence timing contract changed"
  );
  assert(
    sameJson(reduced, {
      durationMs: 3_600,
      revealEndMs: 200,
      lightStartMs: 850,
      coreStartMs: 1_300,
      fullyLitMs: 2_500,
      captionStartMs: 2_650
    }),
    "reduced-motion sequence timing contract changed"
  );
  assert(
    sameJson(reference.presentation, {
      engine: "three",
      artwork: "layered-original",
      cameraMotion: "position-rise",
      lampRotationY: 0,
      durationMs: normal.durationMs,
      riseStartMs: normal.riseStartMs,
      riseEndMs: normal.riseEndMs,
      lightStartMs: normal.lightStartMs,
      fullyLitMs: normal.fullyLitMs,
      maximumLightLevels: {
        leds: 0.7,
        core: 0.62,
        glow: 0.26
      },
      starfieldLayers: 3
    }),
    "approved closure reference must match the executable Three.js sequence"
  );
  assert(
    reference.sequenceId === "chapter4_755_canruo_star_lamp_5800ms_camera_rise_layered_v4"
      && reference.rendererModule.endsWith("ChapterFourStarLampThreeRenderer.ts")
      && sameJson([...reference.layerAssets], expectedLayerAssets),
    "approved closure identity, renderer or original layer list changed"
  );

  const riseStartFrame = resolveFrame(normal.riseStartMs, false);
  const riseMiddleFrame = resolveFrame(
    normal.riseStartMs + (normal.riseEndMs - normal.riseStartMs) * 0.5,
    false
  );
  const riseEndFrame = resolveFrame(normal.riseEndMs, false);
  const riseStartPose = resolveCameraPose(riseStartFrame);
  const riseMiddlePose = resolveCameraPose(riseMiddleFrame);
  const riseEndPose = resolveCameraPose(riseEndFrame);
  assert(
    riseStartPose.y < riseMiddlePose.y
      && riseMiddlePose.y < riseEndPose.y
      && riseStartPose.z > riseEndPose.z,
    "camera must rise continuously from a close base view to the final front view"
  );
  assert(
    approximately(riseStartFrame.artworkOffsetY, -22)
      && approximately(riseStartFrame.artworkScale, 1.16)
      && approximately(riseEndFrame.artworkOffsetY, 0)
      && approximately(riseEndFrame.artworkScale, 0.92),
    "layered lamp projection must visibly travel from its base crop to the full front view"
  );

  for (let elapsedMs = 0; elapsedMs <= normal.riseEndMs; elapsedMs += 37) {
    const frame = resolveFrame(elapsedMs, false);
    assert(
      frame.ledLevel === 0 && frame.coreLevel === 0 && frame.glowLevel === 0,
      `normal sequence emitted light before completing the camera rise at ${elapsedMs}ms`
    );
  }
  const riseComplete = resolveFrame(normal.riseEndMs, false);
  assert(
    approximately(riseComplete.cameraRiseProgress, 1)
      && riseComplete.phase === "front_dark_hold"
      && riseComplete.ledLevel === 0
      && riseComplete.coreLevel === 0
      && riseComplete.glowLevel === 0,
    "the camera must complete the dark upward move before lighting begins"
  );
  for (let elapsedMs = normal.riseEndMs; elapsedMs <= normal.lightStartMs; elapsedMs += 13) {
    const frame = resolveFrame(elapsedMs, false);
    assert(
      frame.ledLevel === 0 && frame.coreLevel === 0 && frame.glowLevel === 0,
      `front hold emitted light before ${normal.lightStartMs}ms at ${elapsedMs}ms`
    );
  }
  const lightBoundary = resolveFrame(normal.lightStartMs, false);
  const lightAfterBoundary = resolveFrame(normal.lightStartMs + 220, false);
  assert(
    lightBoundary.ledLevel === 0
      && lightBoundary.coreLevel === 0
      && lightBoundary.glowLevel === 0
      && lightAfterBoundary.ledLevel > 0
      && lightAfterBoundary.coreLevel === 0
      && lightAfterBoundary.glowLevel === 0,
    "lamp LEDs must begin only after the declared dark camera-rise hold"
  );
  const normalFinal = resolveFrame(normal.durationMs, false);
  assert(
    normalFinal.phase === "complete"
      && approximately(normalFinal.cameraRiseProgress, 1)
      && approximately(normalFinal.ledLevel, 0.7)
      && approximately(normalFinal.coreLevel, 0.62)
      && approximately(normalFinal.glowLevel, 0.26)
      && normalFinal.captionLevel === 1,
    "normal sequence must finish with capped lighting after the upward camera move"
  );

  for (let elapsedMs = 0; elapsedMs <= reduced.lightStartMs; elapsedMs += 29) {
    const frame = resolveFrame(elapsedMs, true);
    assert(frame.cameraRiseProgress === 1, `reduced sequence moved the camera at ${elapsedMs}ms`);
    assert(
      frame.ledLevel === 0 && frame.coreLevel === 0 && frame.glowLevel === 0,
      `reduced sequence emitted light before its dark hold at ${elapsedMs}ms`
    );
  }
  const reducedFinal = resolveFrame(reduced.durationMs, true);
  assert(
    reducedFinal.phase === "complete"
      && reducedFinal.cameraRiseProgress === 1
      && approximately(reducedFinal.ledLevel, 0.7)
      && approximately(reducedFinal.coreLevel, 0.62)
      && approximately(reducedFinal.glowLevel, 0.26)
      && reducedFinal.captionLevel === 1,
    "reduced-motion fallback must still finish the complete staged lighting sequence"
  );

  const registry = new registryModule.ChapterFourClosureSessionRegistry();
  const sessionId = registry.beginSession();
  const prematureProof = {
    assetId: reference.assetId,
    sequenceId: reference.sequenceId,
    consumerModule: reference.consumerModule,
    sessionId,
    completionEventId: `${sessionId}:sequence-complete`
  };
  assert(
    registry.verifyCompletedSession(prematureProof) === false,
    "registry must reject a proof before the visual sequence completes"
  );
  const proof = registry.completeSession(sessionId);
  assert(proof !== null, "completed visual sequence must issue one proof");
  assert(
    registry.completeSession(sessionId) === null,
    "the same visual session must not issue a second proof"
  );
  assert(
    proof !== null && registry.verifyCompletedSession(proof) === true,
    "the first exact completed proof must verify"
  );
  assert(
    proof !== null && registry.verifyCompletedSession(proof) === false,
    "a completed proof must be consumed exactly once"
  );
} catch (error) {
  failures.push(error instanceof Error ? error.stack ?? error.message : String(error));
} finally {
  await vite?.close();
}

if (failures.length > 0) {
  console.error(`Chapter 4 star-lamp closure validation failed (${failures.length}/${assertions}).`);
  failures.forEach((failure) => console.error(`- ${failure}`));
  process.exit(1);
}

console.log(
  `Chapter 4 star-lamp closure validation PASS (${assertions} assertions): `
    + "original layered lamp, upward Three.js camera, fixed lamp rotation, short dark hold, capped ignition, cleanup and one-time proof."
);
