import { build } from "esbuild";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function main() {
  const bundleDir = await mkdtemp(path.join(tmpdir(), "theater-spotlight-validator-"));
  try {
    const modelOutput = path.join(bundleDir, "model.mjs");
    const rulesOutput = path.join(bundleDir, "rules.mjs");
    await Promise.all([
      build({ entryPoints: [path.join(root, "src/scenes/rpg/TheaterSpotlightModel.ts")], outfile: modelOutput, bundle: true, format: "esm", platform: "node", target: "node20" }),
      build({ entryPoints: [path.join(root, "src/scenes/phone/P16_BikeArcade/EndlessSpotlightRules.ts")], outfile: rulesOutput, bundle: true, format: "esm", platform: "node", target: "node20" }),
    ]);
    const model = await import(pathToFileURL(modelOutput).href);
    const rules = await import(pathToFileURL(rulesOutput).href);
    for (const round of model.THEATER_SPOTLIGHT_ROUNDS) {
      const requiredLockMs = model.getRequiredTheaterSpotlightLockMs(round, 0);
      const valid = {
        round: round.round,
        lane: round.lane,
        maxContinuousLockMs: requiredLockMs,
        beamActivated: true,
        firstBeamAtMs: round.actionMs * 0.25,
        actionMs: round.actionMs,
        submittedAtMs: round.actionMs * 0.75,
      };
      assert(model.validateTheaterSpotlightAttempt(valid, round, requiredLockMs) === null, `round ${round.round} valid path drifted`);
      assert(model.validateTheaterSpotlightAttempt({ ...valid, lane: "center" }, round, requiredLockMs) === (round.lane === "center" ? null : "wrong_lane"), `round ${round.round} lane check drifted`);
      assert(model.validateTheaterSpotlightAttempt({ ...valid, maxContinuousLockMs: requiredLockMs - 1, firstBeamAtMs: 0 }, round, requiredLockMs) === "early", `round ${round.round} early lock check drifted`);
      assert(model.validateTheaterSpotlightAttempt({ ...valid, maxContinuousLockMs: requiredLockMs - 1, firstBeamAtMs: round.actionMs - requiredLockMs + 1 }, round, requiredLockMs) === "late", `round ${round.round} late lock check drifted`);
      assert(model.validateTheaterSpotlightAttempt({ ...valid, maxContinuousLockMs: requiredLockMs - 1 }, round, requiredLockMs) === "interrupted", `round ${round.round} interruption check drifted`);
    }
    const replay = rules.createEndlessSpotlightWave(755, 6);
    const same = rules.createEndlessSpotlightWave(755, 6);
    const changed = rules.createEndlessSpotlightWave(756, 6);
    assert(JSON.stringify(replay) === JSON.stringify(same), "spotlight seed replay drifted");
    assert(JSON.stringify(replay) !== JSON.stringify(changed), "spotlight seed did not vary");
    for (const index of [0, 3, 12, 999]) {
      const wave = rules.createEndlessSpotlightWave(755, index);
      assert(wave.pathPoints.length >= 4 && wave.pathPoints.length <= rules.MAX_SPOTLIGHT_PATH_POINTS, "spotlight path bound drifted");
      assert(wave.decoyPathPoints.length <= rules.MAX_SPOTLIGHT_DECOY_POINTS, "spotlight decoy bound drifted");
      assert(Number.isFinite(wave.previewMs) && wave.previewMs >= 500, "spotlight preview bound drifted");
      assert(Number.isFinite(wave.actionMs) && Number.isFinite(wave.requiredLockMs) && Number.isFinite(wave.beamRadius), "spotlight numeric bound drifted");
    }
    assert(
      rules.createEndlessSpotlightWave(755, 12).previewMs <= rules.createEndlessSpotlightWave(755, 0).previewMs,
      "spotlight preview did not shorten with tier",
    );
    const history = Array.from({ length: 20 }, (_, index) => index).reduce((items, item) => rules.appendSpotlightHistory(items, item), []);
    assert(history.length === rules.MAX_SPOTLIGHT_HISTORY, "spotlight history cap drifted");
    console.log("Theater spotlight extraction PASS rounds=3 failures=3 seeded-waves=4");
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

await main();
