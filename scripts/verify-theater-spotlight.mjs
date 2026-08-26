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
    await build({ entryPoints: [path.join(root, "src/scenes/rpg/TheaterSpotlightModel.ts")], outfile: modelOutput, bundle: true, format: "esm", platform: "node", target: "node20" });
    const model = await import(pathToFileURL(modelOutput).href);
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
    console.log("Theater spotlight story validation PASS rounds=3 failures=3");
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

await main();
