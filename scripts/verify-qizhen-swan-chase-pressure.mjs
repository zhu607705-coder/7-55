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

const modelSource = fs.readFileSync(
  new URL("../src/modules/QizhenSwanChasePressureModel.ts", import.meta.url),
  "utf8"
);
const sceneSource = fs.readFileSync(
  new URL("../src/scenes/rpg/QizhenLakeScene.ts", import.meta.url),
  "utf8"
);
const content = JSON.parse(fs.readFileSync(
  new URL("../src/data/chapter3-qizhen-lake.content.json", import.meta.url),
  "utf8"
));

const server = await createServer({
  configFile: false,
  appType: "custom",
  logLevel: "error",
  optimizeDeps: { noDiscovery: true, include: [] },
  server: { middlewareMode: true, ws: false }
});

try {
  const model = await server.ssrLoadModule("/src/modules/QizhenSwanChasePressureModel.ts");
  const {
    QIZHEN_SWAN_CHASE_PRESSURE_RULES,
    createQizhenSwanChasePressureState,
    resolveQizhenSwanChaseDanger,
    resolveQizhenSwanChaseSegment,
    resolveQizhenSwanChaseSpeedProfile,
    stepQizhenSwanChasePressure
  } = model;

  assert(
    !/(emitDomain|SaveStore|GameStore|requestStoryIntent|chaseDistance\s*:|chaseAttempts\s*:)/.test(modelSource),
    "pressure model must not own progression, persistence, attempts, or story events"
  );
  assert(
    sceneSource.includes("stepQizhenSwanChasePressure(this.chasePressureState"),
    "QizhenLakeScene must step the shared pressure model"
  );
  assert(
    sceneSource.includes("this.chaseActualGap <= SWAN_CHASE_CATCH_DISTANCE"),
    "physical center gap must remain the catch authority"
  );
  assert(
    sceneSource.indexOf("this.player.x <= SWAN_CHASE_FINISH_X")
      < sceneSource.indexOf("this.chaseActualGap <= SWAN_CHASE_CATCH_DISTANCE"),
    "finish evaluation must remain before contact failure on the same frame"
  );
  assert(
    sceneSource.includes("this.chaseElapsedSeconds >= SWAN_CHASE_GRACE_SECONDS"),
    "the original start grace must remain in the catch condition"
  );

  for (const phase of ["release_warning", "tracking", "charge_warning", "charge", "recovery"]) {
    for (const segment of ["opening", "mid_channel", "final_bank"]) {
      const profile = resolveQizhenSwanChaseSpeedProfile(phase, segment);
      assert(profile.near < 340, `${phase}/${segment} near speed must remain below kayak max`);
      assert(profile.far > 340, `${phase}/${segment} far speed must remain above kayak max`);
      assert(profile.far > profile.near, `${phase}/${segment} speed must increase with gap`);
    }
  }

  assert(resolveQizhenSwanChaseSegment(0.1) === "opening", "early progress must use opening segment");
  assert(resolveQizhenSwanChaseSegment(0.45) === "mid_channel", "middle progress must use mid-channel segment");
  assert(resolveQizhenSwanChaseSegment(0.9) === "final_bank", "late progress must use final-bank segment");

  assert(
    resolveQizhenSwanChaseDanger(330, 104, 150, 360).dangerBand === "safe",
    "large gap must read as safe"
  );
  assert(
    resolveQizhenSwanChaseDanger(220, 104, 150, 360).dangerBand === "pressured",
    "middle gap must read as pressured"
  );
  assert(
    resolveQizhenSwanChaseDanger(160, 104, 150, 360).dangerBand === "critical",
    "near gap must read as critical"
  );
  const riskSamples = [360, 300, 240, 180, 120].map((gap) => (
    resolveQizhenSwanChaseDanger(gap, 104, 150, 360).riskRatio
  ));
  assert(
    riskSamples.every((risk, index) => index === 0 || risk >= riskSamples[index - 1]),
    "risk ratio must increase monotonically as the swan closes the gap"
  );

  const input = (overrides = {}) => ({
    deltaMs: 16,
    elapsedSeconds: 0.2,
    actualGap: 230,
    catchDistance: 104,
    nearDistance: 150,
    farDistance: 360,
    catchReady: false,
    progressRatio: 0.05,
    playerY: 680,
    ...overrides
  });

  let state = createQizhenSwanChasePressureState(680);
  const initialSnapshot = clone(state);
  let result = stepQizhenSwanChasePressure(state, input({ deltaMs: 600, elapsedSeconds: 0.6 }));
  assert(result.state.phase === "release_warning", "opening must retain a readable release warning");
  assert(JSON.stringify(state) === JSON.stringify(initialSnapshot), "pressure stepping must not mutate its source state");

  state = result.state;
  result = stepQizhenSwanChasePressure(
    state,
    input({ deltaMs: 600, elapsedSeconds: 1.2, playerY: 650 })
  );
  assert(result.state.phase === "tracking", "release warning must advance to tracking");
  assert(result.phaseChanged, "tracking entry must be exposed as a phase change");

  state = result.state;
  result = stepQizhenSwanChasePressure(
    state,
    input({
      deltaMs: 16,
      elapsedSeconds: QIZHEN_SWAN_CHASE_PRESSURE_RULES.firstTelegraphAtMs / 1000 + 0.01,
      actualGap: 122,
      catchReady: false,
      playerY: 612
    })
  );
  assert(result.state.phase === "charge_warning", "the first charge warning must begin before contact becomes active");
  assert(result.cue === "telegraph", "charge warning must emit one telegraph cue");
  assert(result.state.aimY === 612, "telegraph must lock the player's current lane");

  state = result.state;
  result = stepQizhenSwanChasePressure(
    { ...state, phaseElapsedMs: QIZHEN_SWAN_CHASE_PRESSURE_RULES.chargeWarningMs + 200 },
    input({ deltaMs: 16, elapsedSeconds: 3.7, actualGap: 122, catchReady: false, playerY: 740 })
  );
  assert(result.state.phase === "charge_warning", "the swan must not surge before the contact grace ends");
  assert(result.state.aimY === 612, "late-grace warning must keep the original telegraphed lane");

  state = result.state;
  result = stepQizhenSwanChasePressure(
    state,
    input({ deltaMs: 16, elapsedSeconds: 4.01, actualGap: 122, catchReady: true, playerY: 740 })
  );
  assert(result.state.phase === "charge", "the completed grace must release the already-telegraphed charge");
  assert(result.cue === "surge", "charge entry must emit one surge cue");
  assert(result.state.aimY === 612, "charge must keep the telegraphed lane instead of homing every frame");

  state = result.state;
  result = stepQizhenSwanChasePressure(
    { ...state, phaseElapsedMs: QIZHEN_SWAN_CHASE_PRESSURE_RULES.chargeMs - 8 },
    input({ deltaMs: 16, elapsedSeconds: 5.5, catchReady: true, playerY: 740 })
  );
  assert(result.state.phase === "recovery", "charge must end in a bounded recovery window");
  assert(result.targetSpeed < 440, "recovery must visibly reduce the current pursuit target speed");

  state = result.state;
  result = stepQizhenSwanChasePressure(
    { ...state, phaseElapsedMs: QIZHEN_SWAN_CHASE_PRESSURE_RULES.recoveryMs - 8 },
    input({ deltaMs: 16, elapsedSeconds: 6.3, catchReady: true, playerY: 700 })
  );
  assert(result.state.phase === "tracking", "recovery must return to tracking");
  assert(result.state.cycleIndex === 1, "one complete pressure cycle must increment the cycle index once");

  result = stepQizhenSwanChasePressure(
    result.state,
    input({ deltaMs: 16, elapsedSeconds: 7, catchReady: true, progressRatio: 0.82 })
  );
  assert(result.state.segment === "final_bank", "late chase must enter final-bank pressure segment");
  assert(result.cue === "final_bank", "final-bank entry must emit one finish-pressure cue");

  for (const key of ["release_warning", "tracking", "charge_warning", "charge", "recovery"]) {
    assert(typeof content.chase.phaseLabels?.[key] === "string", `phase ${key} must have player-facing copy`);
  }
  for (const key of ["safe", "pressured", "critical"]) {
    assert(typeof content.chase.dangerLabels?.[key] === "string", `danger ${key} must have player-facing copy`);
  }
  for (const key of ["opening", "mid_channel", "final_bank"]) {
    assert(typeof content.chase.segmentLabels?.[key] === "string", `segment ${key} must have player-facing copy`);
  }
} finally {
  await server.close();
}

if (errors.length > 0) {
  console.error(`Qizhen swan chase pressure validation failed (${errors.length}/${assertionCount})`);
  errors.forEach((error) => console.error(`- ${error}`));
  process.exitCode = 1;
} else {
  console.log(`Qizhen swan chase pressure validation passed (${assertionCount} assertions).`);
}
