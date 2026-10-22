#!/usr/bin/env node
import assert from "node:assert/strict";
import { build } from "esbuild";

const bundle = await build({ entryPoints: ["src/core/NoticeQueue.ts"], bundle: true, platform: "node", format: "esm", write: false });
const { NoticeQueue } = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);
let checks = 0;
const equal = (actual, expected, message) => { assert.deepEqual(actual, expected, message); checks += 1; };
const notice = (id, text = String(id), tone = "system", durationMs = 3000) => ({ id, text, tone, durationMs });

// The former three-card slice removed the first unread message on a burst.
const q = new NoticeQueue();
for (let id = 1; id <= 5; id++) q.enqueue(notice(id), 0);
for (let id = 1; id <= 5; id++) {
  equal(q.visible((id - 1) * 3000)?.id, id, "Every burst message gets its own reading window");
}
equal(q.visible(15000), null, "Queue ends after all five visible durations");

const paused = new NoticeQueue();
paused.enqueue(notice(1), 0); paused.enqueue(notice(2), 0);
paused.setPaused(true, 1000);
equal(paused.visible(90000), null, "Scene-owned dialogue hides ordinary notices");
paused.enqueue(notice(3), 90000);
paused.setPaused(false, 90000);
equal(paused.visible(90000)?.durationMs, 2000, "Resume preserves the remaining two seconds");
equal(paused.visible(91999)?.id, 1, "A hidden interval never consumes reading time");
equal(paused.visible(92000)?.id, 2, "Pending notice begins only after the visible one finishes");
equal(paused.visible(92000)?.durationMs, 3000, "Unseen pending notice retains its full duration");
equal(paused.visible(95000)?.id, 3, "Notice arriving during a game remains queued");

const hidden = new NoticeQueue();
hidden.setPaused(true, 0); hidden.enqueue(notice(1), 0);
hidden.setPaused(false, 100000);
equal(hidden.visible(100000)?.durationMs, 3000, "Enqueue while blocked receives full time on first display");
hidden.enqueue(notice(2, "1"), 100100);
hidden.enqueue(notice(3, "1", "task"), 100100);
equal(hidden.visible(103000)?.id, 3, "Coalesce exact repeats, preserve a different message role");

const late = new NoticeQueue();
late.enqueue(notice(1), 0); late.enqueue(notice(2), 0); late.enqueue(notice(3), 0);
equal(late.visible(300000)?.id, 2, "A delayed timer cannot expire an unseen backlog");
equal(late.visible(300000)?.durationMs, 3000, "Next visible notice starts with full reading time");
late.setPaused(true, 301000); late.setPaused(true, 400000); late.setPaused(false, 400000);
equal(late.visible(400000)?.durationMs, 2000, "Repeated blocked refreshes do not reset or consume the remainder");

const repeated = new NoticeQueue();
repeated.enqueue(notice(1, "Again"), 0);
repeated.enqueue(notice(2, "Again"), 3001);
equal(repeated.visible(3001)?.id, 2, "A new identical action after expiry is still reported");
console.log(`NOTICE_QUEUE PASS checks=${checks}`);
