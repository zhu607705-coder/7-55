import { build } from "esbuild";
import { createHash } from "node:crypto";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const chartPath = path.join(root, "src/data/chapter3-qizhen-fishing.charts.json");
const audioTimelinePath = path.join(root, "src/data/chapter3-qizhen.audio.json");
const hostPath = path.join(root, "src/scenes/rpg/RpgGameHost.tsx");
const scenePath = path.join(root, "src/scenes/rpg/QizhenLakeScene.ts");
const lakeModelPath = path.join(root, "src/scenes/rpg/QizhenLakeModel.ts");
const developerChannelPath = path.join(root, "src/modules/DeveloperChannel.ts");
const questModelPath = path.join(root, "src/core/QuestModel.ts");
const lakeContentPath = path.join(root, "src/data/chapter3-qizhen-lake.content.json");
const expectedChartHash = "ba470319fff851a3821467f62397d2d94753804a4e9991d74d02582c665a6b23";
const expectedCharts = Object.freeze({
  locker_key: { notes: [8, 8], durationSec: 10, experience: "tutorial_full" },
  net_frame: { notes: [4, 4], durationSec: 7.5, experience: "quick_hold" },
  fish: { notes: [1, 1], durationSec: 5, experience: "quick_strike" },
  paper: { notes: [26, 20], durationSec: 20, experience: "finale_full" },
});

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
    const layoutBundle = path.join(bundleDir, "layout.mjs");
    await Promise.all([
      build({ entryPoints: [path.join(root, "src/scenes/rpg/QizhenFishingRhythmModel.ts")], outfile: modelBundle, bundle: true, format: "esm", platform: "node", target: "node20" }),
      build({ entryPoints: [path.join(root, "src/modules/RhythmFishingEngine.ts")], outfile: engineBundle, bundle: true, format: "esm", platform: "node", target: "node20" }),
      build({ entryPoints: [path.join(root, "src/scenes/rpg/QizhenFishingRhythmLayout.ts")], outfile: layoutBundle, bundle: true, format: "esm", platform: "node", target: "node20" }),
    ]);
    const {
      QizhenFishingRhythmModel,
      QIZHEN_FISHING_TIMING,
      QIZHEN_FISHING_TENSION,
      getQizhenFishingNoteTravelProgress,
    } = await import(pathToFileURL(modelBundle).href);
    const { RhythmFishingEngine } = await import(pathToFileURL(engineBundle).href);
    const { FISHING_BOARD: board, FISHING_LANES: lanes, fishingTileGeometry } = await import(pathToFileURL(layoutBundle).href);
    assert(lanes.map((lane) => lane.key).join("") === "ASD", "fixed lane order must be A/S/D");
    assert(board.noteBottom < board.keyTop, "falling notes must never overlap the fixed keys");
    for (const chartId of Object.keys(expectedCharts)) {
      const visualProbe = new QizhenFishingRhythmModel({ chartId, now: () => 0, events: createEvents([]) });
      for (const note of visualProbe.notes) {
        for (const firstVisible of [0, note.spawnSec]) {
          const hit = fishingTileGeometry(note, note.timeSec, firstVisible);
          assert(Math.abs(hit.headY - board.judgmentY) < 0.001, `${chartId}/${note.index}: note must reach the line at the authored instant`);
          for (let elapsed = 0; elapsed < note.timeSec + note.holdSec + 1; elapsed += 0.047) {
            const tile = fishingTileGeometry(note, elapsed, firstVisible);
            assert(tile.height >= 0 && Number.isFinite(tile.height), "tile clipping must stay finite");
            assert(tile.x > board.left && tile.x + tile.width < board.right, "both tile edges must stay inside board, including D");
            if (tile.height > 0) assert(tile.y >= board.noteTop && tile.y + tile.height <= board.noteBottom + 0.001, "tile clipping must preserve the note/key separation");
          }
          if (note.holdSec > 0) {
            const held = { ...note, holding: true };
            const early = fishingTileGeometry(held, note.timeSec, firstVisible);
            const late = fishingTileGeometry(held, note.timeSec + note.holdSec * 0.8, firstVisible);
            assert(early.height > late.height && late.headY === board.judgmentY, "hold tail must shorten while head stays on the judgment line");
          }
        }
      }
    }
    const visualSource = await readFile(path.join(root, "src/scenes/rpg/QizhenFishingRhythmVisual.ts"), "utf8");
    assert(!/createGeometryMask|createBitmapMask|\.setMask\(/.test(visualSource), "screen-space fishing tiles must not restore independently transformed masks");
    assert((visualSource.match(/setScrollFactor\(0\)/g) ?? []).length === 1 && visualSource.includes("this.root.add(object)"), "all fishing HUD objects must share one logical screen-space root");

    for (const [chartId, expectation] of Object.entries(expectedCharts)) {
      const normal = playPerfect(QizhenFishingRhythmModel, chartId, false);
      const assist = playPerfect(QizhenFishingRhythmModel, chartId, true);
      const timeShifted = playPerfect(QizhenFishingRhythmModel, chartId, false, 1_000);
      assert(normal.model.totalNotes === expectation.notes[0], `${chartId} normal note count drifted`);
      assert(assist.model.totalNotes === expectation.notes[1], `${chartId} assist note count drifted`);
      assert(normal.model.durationSec === expectation.durationSec, `${chartId} duration drifted`);
      assert(normal.model.experience === expectation.experience, `${chartId} experience tier drifted`);
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

    const fishProbe = new QizhenFishingRhythmModel({ chartId: "fish", now: () => 0, events: createEvents([]) });
    assert(fishProbe.totalNotes === 1 && fishProbe.notes[0]?.action === "hook", "fish must remain one visible hook judgment");
    const fishNote = fishProbe.notes[0];
    const firstRenderedAtSec = 0.4;
    const earlyTravel = getQizhenFishingNoteTravelProgress(fishNote, 1.4, firstRenderedAtSec);
    const laterTravel = getQizhenFishingNoteTravelProgress(fishNote, 2.4, firstRenderedAtSec);
    assert(earlyTravel > 0 && laterTravel > earlyTravel, "fish cue must visibly descend throughout the opening quiet gap");
    assert(getQizhenFishingNoteTravelProgress(fishNote, fishNote.timeSec, firstRenderedAtSec) === 1, "early cue travel must still reach the authored judgment time exactly");

    const paperProbe = new QizhenFishingRhythmModel({ chartId: "paper", now: () => 0, events: createEvents([]) });
    assert(paperProbe.totalNotes > expectedCharts.locker_key.notes[0], "paper must remain the highest-density chart");
    assert(paperProbe.notes.filter((note) => note.holdBeats > 0).length === 2, "paper must retain two hold notes");
    assert(paperProbe.notes.some((note) => !Number.isInteger(note.beat)), "paper must retain off-beat tension notes");

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

    const audioTimeline = JSON.parse(await readFile(audioTimelinePath, "utf8"));
    const startedAssets = audioTimeline.events.qizhen_fishing_started.cues.map((cue) => cue.asset).filter(Boolean);
    assert(startedAssets.includes("music_qizhen_fishing"), "fishing must use its authored rhythm music");
    assert(audioTimeline.events.qizhen_fishing_final_tension_started.cues.some((cue) => cue.action === "update" && cue.channel === "music"), "paper finale must raise the music tension");
    assert(audioTimeline.events.qizhen_fishing_catch_completed.cues.some((cue) => cue.asset === "music_qizhen_lakeside"), "ordinary catches must return to the lakeside bed");
    assert(!audioTimeline.events.qizhen_fishing_paper_completed.cues.some((cue) => cue.asset === "music_qizhen_lakeside"), "paper completion must not resume calm music before the chase");
    assert(audioTimeline.events.qizhen_fishing_paper_completed.cues.some((cue) => cue.asset === "fx_qizhen_paper_release"), "paper completion must include the release sound");

    const [hostSource, sceneSource, lakeModelSource, developerChannelSource, questModelSource, lakeContentSource] = await Promise.all([
      readFile(hostPath, "utf8"),
      readFile(scenePath, "utf8"),
      readFile(lakeModelPath, "utf8"),
      readFile(developerChannelPath, "utf8"),
      readFile(questModelPath, "utf8"),
      readFile(lakeContentPath, "utf8"),
    ]);
    assert(hostSource.includes('spotId === "paper" ? "qizhen_fishing_paper_completed" : "qizhen_fishing_catch_completed"'), "host must route ordinary and paper completion separately");
    assert(sceneSource.includes('this.emitDomain("qizhen_fishing_final_tension_started"'), "paper chart must emit its tension prelude event");
    assert(lakeModelSource.includes('id: "qizhen_fishing_fish"') && lakeModelSource.includes('acceptedItem: "fishFeedPellets"'), "fish quick strike must own a real item-use target");
    assert(sceneSource.includes('if (target.value === "fish")') && sceneSource.includes('hasItem(state, CHAIN_ITEMS.pellets)'), "fish quick strike must become active when pellets are available");
    assert(!sceneSource.includes("三处分支素材"), "successful rig assembly feedback must name the concrete materials");
    assert(developerChannelSource.includes('rhythmNet\n      ? "channel"') && developerChannelSource.includes('? "qizhen_channel"'), "net quick-hold checkpoint must seed the channel plate");
    assert(questModelSource.includes("查看湖边三处线索") && questModelSource.includes("浮排") && questModelSource.includes("黑天鹅"), "tool-chain task must identify visible leads without naming uncollected rewards");
    assert(!questModelSource.includes("完成湖区三处分支"), "tool-chain task must not expose abstract branch terminology");
    assert(!lakeContentSource.includes("三处分支材料") && !lakeContentSource.includes("三处分支"), "lake guidance must describe concrete items and locations");

    console.log("Qizhen fishing tiered flow PASS tutorial=8 quick_hold=4 quick_strike=1 finale=26 audio=split recovery=preserved geometry=bounded_ASD single_root=mask_free");
  } finally {
    await rm(bundleDir, { recursive: true, force: true });
  }
}

await main();
