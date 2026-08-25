import { build } from "esbuild";
import { createHash } from "node:crypto";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const chartPath = path.join(root, "src/data/chapter3-qizhen-fishing.charts.json");
const expectedChartHash = "aa7e820faee753a9cb84f82d6dbedaa39353af72a268152102e9640cda6275af";
const expectedNoteCounts = Object.freeze({ locker_key: [8, 8], net_frame: [14, 14], fish: [20, 8], paper: [26, 20] });

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function createEvents(log) {
  return {
    onNoteJudged: (note, judgment, errorMs, tension) => log.push({ type: "note", index: note.index, judgment, errorMs, tension }),
    onHoldBroken: (note, tension) => log.push({ type: "hold_broken", index: note.index, tension }),
    onWarning: (kind, tension) => log.push({ type: "warning", kind, tension }),
    onCompleted: (result) => log.push({ type: "completed", result }),
    onFailed: (reason, tension) => log.push({ type: "failed", reason, tension }),
  };
}

function playPerfect(Model, chartId, assist, origin = 0) {
  let now = origin;
  const events = [];
  const model = new Model({ chartId, assist, now: () => now, events: createEvents(events) });
  model.start();
  for (const note of model.notes) {
    now = origin + note.timeSec;
    model.handlePress(note.action);
    if (note.holdBeats > 0) {
      now = origin + note.timeSec + note.holdSec - 0.079;
      model.update();
      model.handleRelease(note.action);
    }
  }
  now = origin + 30;
  model.update();
  const completion = events.find((event) => event.type === "completed");
  assert(completion, `${chartId} ${assist ? "assist" : "normal"} must complete`);
  return { model, events, result: completion.result };
}

async function main() {
  const chartHash = createHash("sha256").update(await readFile(chartPath)).digest("hex");
  assert(chartHash === expectedChartHash, "authored Chapter 3 fishing chart hash changed; update parity evidence deliberately");

  const bundleDir = await mkdtemp(path.join(tmpdir(), "qizhen-fishing-validator-"));
  try {
    const modelBundle = path.join(bundleDir, "model.mjs");
    const engineBundle = path.join(bundleDir, "engine.mjs");
    await Promise.all([
      build({ entryPoints: [path.join(root, "src/scenes/rpg/QizhenFishingRhythmModel.ts")], outfile: modelBundle, bundle: true, format: "esm", platform: "node", target: "node20" }),
      build({ entryPoints: [path.join(root, "src/modules/RhythmFishingEngine.ts")], outfile: engineBundle, bundle: true, format: "esm", platform: "node", target: "node20" }),
    ]);
    const { QizhenFishingRhythmModel, QIZHEN_FISHING_TIMING, QIZHEN_FISHING_TENSION } = await import(pathToFileURL(modelBundle).href);
    const { RhythmFishingEngine } = await import(pathToFileURL(engineBundle).href);

    for (const [chartId, counts] of Object.entries(expectedNoteCounts)) {
      const normal = playPerfect(QizhenFishingRhythmModel, chartId, false);
      const assist = playPerfect(QizhenFishingRhythmModel, chartId, true);
      const timeShifted = playPerfect(QizhenFishingRhythmModel, chartId, false, 1_000);
      assert(normal.model.totalNotes === counts[0], `${chartId} normal note count drifted`);
      assert(assist.model.totalNotes === counts[1], `${chartId} assist note count drifted`);
      assert(normal.result.grade === "S" && normal.result.passed, `${chartId} normal all-perfect result drifted`);
      assert(assist.result.grade === "S" && assist.result.passed, `${chartId} assist all-perfect result drifted`);
      assert(JSON.stringify(normal.result) === JSON.stringify(timeShifted.result), `${chartId} timing origin changed result`);
    }

    for (const [offsetMs, expected] of [[70, "perfect"], [130, "great"], [190, "good"]]) {
      let now = 0;
      const events = [];
      const model = new QizhenFishingRhythmModel({ chartId: "locker_key", now: () => now, events: createEvents(events) });
      model.start();
      now = model.notes[0].timeSec + offsetMs / 1000;
      model.handlePress("hook");
      assert(events[0]?.judgment === expected, `judgment boundary ${offsetMs}ms drifted`);
    }

    let wrongNow = 0;
    const wrongEvents = [];
    const wrong = new QizhenFishingRhythmModel({ chartId: "locker_key", now: () => wrongNow, events: createEvents(wrongEvents) });
    wrong.start();
    wrongNow = wrong.notes[0].timeSec;
    wrong.handlePress("left");
    assert(wrongEvents[0]?.judgment === "miss" && wrong.tension === 66, "wrong action penalty drifted");

    let holdNow = 0;
    const holdEvents = [];
    const hold = new QizhenFishingRhythmModel({ chartId: "net_frame", now: () => holdNow, events: createEvents(holdEvents) });
    hold.start();
    const holdNote = hold.notes.find((note) => note.holdBeats > 0);
    assert(holdNote, "net_frame must retain authored hold note");
    holdNow = holdNote.timeSec;
    hold.handlePress(holdNote.action);
    holdNow = holdNote.timeSec + holdNote.holdSec - QIZHEN_FISHING_TIMING.holdReleaseSlackSec - 0.001;
    hold.handleRelease(holdNote.action);
    assert(holdEvents[0]?.type === "note" && holdEvents[1]?.type === "hold_broken", "hold break event order drifted");

    for (const assist of [false, true]) {
      let now = 0;
      const failures = [];
      const model = new RhythmFishingEngine({
        chartId: "sustain",
        chart: {
          durationSeconds: 20,
          notes: [
            { beat: 1, action: "left" },
            { beat: 2, action: "left" },
            { beat: 3, action: "left" },
            { beat: 4, action: "left" },
          ],
        },
        assist,
        now: () => now,
        timing: QIZHEN_FISHING_TIMING,
        tension: QIZHEN_FISHING_TENSION,
        events: createEvents(failures),
      });
      model.start();
      now = 3;
      model.update();
      const sustainMs = assist ? QIZHEN_FISHING_TENSION.assistFailSustainMs : QIZHEN_FISHING_TENSION.failSustainMs;
      now += sustainMs / 1000 - 0.001;
      model.update();
      assert(model.phase === "running", `${assist ? "assist" : "normal"} tension failed before sustain window`);
      now += 0.002;
      model.update();
      assert(model.phase === "failed" && failures.at(-1)?.type === "failed", `${assist ? "assist" : "normal"} tension sustain failure drifted`);
    }

    let cancelNow = 0;
    const cancelledEvents = [];
    const cancelled = new QizhenFishingRhythmModel({ chartId: "fish", now: () => cancelNow, events: createEvents(cancelledEvents) });
    cancelled.start();
    cancelled.cancel();
    cancelNow = 30;
    cancelled.update();
    assert(cancelled.phase === "cancelled" && cancelledEvents.length === 0, "cancel must not emit terminal callbacks");

    let nearestNow = 0;
    const nearestEvents = [];
    const nearest = new RhythmFishingEngine({
      chartId: "nearest",
      chart: { durationSeconds: 3, notes: [{ beat: 4, action: "left" }, { beat: 4.4, action: "right" }] },
      now: () => nearestNow,
      timing: QIZHEN_FISHING_TIMING,
      tension: QIZHEN_FISHING_TENSION,
      events: createEvents(nearestEvents),
    });
    nearest.start();
    nearestNow = (4.2 * QIZHEN_FISHING_TIMING.beatSec);
    nearest.handlePress("left");
    assert(nearestEvents[0]?.index === 0 && nearestEvents[0]?.judgment === "great", "equal-distance note matching must retain first authored note");

    console.log("Qizhen fishing rhythm parity PASS charts=4 boundaries=3 hold=1 sustain=2 cancel=1 nearest=1");
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

await main();
