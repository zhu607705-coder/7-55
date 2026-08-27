import fs from "node:fs";
import { createServer } from "vite";

const errors = [];
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

const presentationSource = fs.readFileSync(
  new URL("../src/modules/ChapterFourGuardPresentationModel.ts", import.meta.url),
  "utf8"
);
const sceneSource = fs.readFileSync(
  new URL("../src/scenes/rpg/ChapterFourTemporalMazeScene.ts", import.meta.url),
  "utf8"
);

const server = await createServer({
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

try {
  const [presentationModule, authorityModule] = await Promise.all([
    server.ssrLoadModule("/src/modules/ChapterFourGuardPresentationModel.ts"),
    server.ssrLoadModule("/src/modules/ChapterFourGuardModel.ts")
  ]);
  const {
    CHAPTER_FOUR_GUARD_PRESENTATION_RULES,
    createChapterFourGuardPresentationState,
    stepChapterFourGuardPresentation
  } = presentationModule;
  const {
    createChapterFourMaintenanceGuardState,
    stepChapterFourMaintenanceGuard
  } = authorityModule;

  assert(
    !/(setVelocity|requestStoryIntent|SaveStore|GameStore|chapterFourGuardFootContact)/.test(
      presentationSource
    ),
    "presentation model must not mutate velocity, progression, saves, or capture authority"
  );
  assert(
    !/\b(position|desiredVelocity)\s*:/.test(
      presentationSource.slice(
        presentationSource.indexOf("export interface ChapterFourGuardPresentationResult"),
        presentationSource.indexOf("export const CHAPTER_FOUR_GUARD_PRESENTATION_RULES")
      )
    ),
    "presentation result must not expose position or velocity authority"
  );
  assert(
    sceneSource.includes("stepChapterFourMaintenanceGuard(this.maintenanceGuardState"),
    "Scene must continue using the original guard authority step"
  );
  assert(
    sceneSource.includes(".setVelocity(next.desiredVelocity.x, next.desiredVelocity.y)"),
    "Scene movement must continue using authority desired velocity"
  );
  assert(
    sceneSource.includes("stepChapterFourGuardPresentation("),
    "Scene must project authority output through the presentation model"
  );
  assert(
    !sceneSource.includes("maintenanceGuardRadioUntilMs"),
    "Scene must not retain the competing per-frame radio animation timer"
  );
  assert(
    !sceneSource.includes("resolveGuardTravelAnimation("),
    "maintenance presentation must not retain the old shared per-frame direction resolver"
  );

  const input = (overrides = {}) => ({
    deltaMs: 16,
    authorityMode: "patrol",
    playerVisible: false,
    enteredPursuit: false,
    disengaged: false,
    desiredMotion: { x: 84, y: 0 },
    authorityHeading: { x: 1, y: 0 },
    patrolIdleVariant: "list",
    ...overrides
  });

  let result = stepChapterFourGuardPresentation(
    createChapterFourGuardPresentationState(),
    input({ authorityMode: "confirming", playerVisible: true, authorityHeading: { x: 1, y: 0 } })
  );
  assert(result.state.phase === "notice", "first sight must enter notice presentation");
  assert(result.alertVisible && result.alertText === "!", "notice must show one alert marker");
  assert(result.animationId === "guard_check_list", "notice must use a readable check animation");
  assert(result.state.direction === "side" && !result.state.flipX, "notice must turn once toward player");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({
      deltaMs: CHAPTER_FOUR_GUARD_PRESENTATION_RULES.noticeMs - 20,
      authorityMode: "confirming",
      playerVisible: true,
      authorityHeading: { x: -1, y: 0 }
    })
  );
  assert(result.state.phase === "notice", "notice dwell must not be skipped");
  assert(!result.state.flipX, "confirming must hold its initial turn instead of per-frame head flips");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({ deltaMs: 24, authorityMode: "confirming", playerVisible: true })
  );
  assert(result.state.phase === "turn_confirm", "notice must advance to turn confirmation");
  assert(result.animationId === "guard_flashlight_down", "turn confirmation must use flashlight search");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({
      authorityMode: "pursuit",
      playerVisible: true,
      enteredPursuit: true,
      desiredMotion: { x: 140, y: 0 }
    })
  );
  assert(result.state.phase === "pursue", "confirmed detection must enter pursuit presentation");
  assert(result.animationId === "guard_radio", "pursuit entry must use a bounded radio cue");
  assert(!result.alertVisible, "steady pursuit must not keep a permanent exclamation mark");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({
      deltaMs: CHAPTER_FOUR_GUARD_PRESENTATION_RULES.radioMs + 1,
      authorityMode: "pursuit",
      playerVisible: true,
      desiredMotion: { x: 140, y: 0 }
    })
  );
  assert(result.animationId === "guard_walk", "pursuit must return to directional travel animation");

  const facingBeforeSightLoss = clone(result.state);
  result = stepChapterFourGuardPresentation(
    result.state,
    input({
      authorityMode: "pursuit",
      playerVisible: false,
      desiredMotion: { x: -140, y: 0 }
    })
  );
  assert(result.state.phase === "short_sight_loss", "lost LOS must enter short sight-loss presentation");
  assert(result.alertText === "?", "short sight loss must replace alert with a question marker");
  assert(
    result.state.direction === facingBeforeSightLoss.direction
      && result.state.flipX === facingBeforeSightLoss.flipX,
    "sight loss must hold the last readable facing"
  );

  result = stepChapterFourGuardPresentation(
    result.state,
    input({ authorityMode: "pursuit", playerVisible: true, desiredMotion: { x: -140, y: 0 } })
  );
  assert(result.state.phase === "reacquire", "restored LOS must show a short reacquire presentation");
  assert(result.animationId === "guard_radio", "reacquire must use the readable radio cue");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({ authorityMode: "returning", disengaged: true, desiredMotion: { x: 96, y: 0 } })
  );
  assert(result.state.phase === "last_seen_search", "disengage must search the last seen area first");
  assert(result.alertText === "?", "last-seen search must remain visibly uncertain");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({
      deltaMs: CHAPTER_FOUR_GUARD_PRESENTATION_RULES.lastSeenSearchMs + 1,
      authorityMode: "returning",
      desiredMotion: { x: 96, y: 0 }
    })
  );
  assert(result.state.phase === "return_to_patrol", "search dwell must advance to patrol return");
  assert(result.animationId === "guard_walk", "patrol return must use travel animation");

  result = stepChapterFourGuardPresentation(
    result.state,
    input({ authorityMode: "patrol", desiredMotion: { x: 0, y: 0 }, patrolIdleVariant: "watch" })
  );
  assert(result.state.phase === "patrol_walk", "authority patrol must restore patrol presentation");
  assert(result.animationId === "guard_check_watch", "patrol pause must keep authored idle variation");

  let stable = createChapterFourGuardPresentationState();
  stable = stepChapterFourGuardPresentation(stable, input({ desiredMotion: { x: 100, y: 0 } })).state;
  const stableFacing = { direction: stable.direction, flipX: stable.flipX };
  for (const x of [-4, 4, -6, 6, -7, 7]) {
    stable = stepChapterFourGuardPresentation(
      stable,
      input({ desiredMotion: { x, y: 0 } })
    ).state;
    assert(
      stable.direction === stableFacing.direction && stable.flipX === stableFacing.flipX,
      `sub-threshold motion ${x} must not flip the guard`
    );
  }
  stable = stepChapterFourGuardPresentation(
    stable,
    input({ desiredMotion: { x: 70, y: 75 } })
  ).state;
  assert(stable.direction === "side", "near-diagonal motion must not thrash the dominant axis");
  stable = stepChapterFourGuardPresentation(
    stable,
    input({ desiredMotion: { x: 30, y: -100 } })
  ).state;
  assert(stable.direction === "up" && stable.flipX === false, "clear vertical motion must switch once");

  const authorityInitial = createChapterFourMaintenanceGuardState(0x7552245);
  const authoritySnapshot = clone(authorityInitial);
  stepChapterFourGuardPresentation(
    createChapterFourGuardPresentationState(),
    input({ authorityMode: authorityInitial.mode, authorityHeading: authorityInitial.heading })
  );
  assert(
    JSON.stringify(authorityInitial) === JSON.stringify(authoritySnapshot),
    "presentation stepping must not mutate the authority state passed alongside it"
  );
  const authorityInput = {
    deltaMs: 50,
    guardPosition: authorityInitial.position,
    playerPosition: { x: authorityInitial.position.x + 500, y: authorityInitial.position.y },
    walls: []
  };
  const authorityA = stepChapterFourMaintenanceGuard(authorityInitial, authorityInput);
  stepChapterFourGuardPresentation(
    createChapterFourGuardPresentationState(),
    input({
      authorityMode: authorityA.state.mode,
      playerVisible: authorityA.playerVisible,
      enteredPursuit: authorityA.enteredPursuit,
      disengaged: authorityA.disengaged,
      desiredMotion: authorityA.desiredVelocity,
      authorityHeading: authorityA.state.heading
    })
  );
  const authorityB = stepChapterFourMaintenanceGuard(authorityInitial, authorityInput);
  assert(
    JSON.stringify(authorityA) === JSON.stringify(authorityB),
    "presentation projection must not alter deterministic authority results"
  );
} finally {
  await server.close();
}

if (errors.length > 0) {
  console.error(`Chapter 4 guard presentation validation failed (${errors.length}/${assertionCount})`);
  errors.forEach((error) => console.error(`- ${error}`));
  process.exitCode = 1;
} else {
  console.log(`Chapter 4 guard presentation validation passed (${assertionCount} assertions).`);
}
