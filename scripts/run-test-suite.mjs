#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { performance } from "node:perf_hooks";
import process from "node:process";

const SUITES = Object.freeze({
  critical: Object.freeze([
    Object.freeze({ area: "chapter-2", script: "verify:cc98-login", risk: "identity gate, lockout, save migration" }),
    Object.freeze({ area: "chapter-3.5", script: "chapter3:validate-interlude", risk: "parallel evidence order, rejection, save migration" }),
    Object.freeze({ area: "cross-chapter", script: "verify:rpg-reality-mode-order", risk: "mode-order independence and truthful persistence" }),
    Object.freeze({ area: "chapter-3", script: "theater:validate-spotlight", risk: "spotlight timing boundaries and failure classification" }),
    Object.freeze({ area: "chapter-3", script: "qizhen:validate-rain-safety", risk: "weather safety gate, checkpoint resume, save/reload" }),
    Object.freeze({ area: "chapter-3", script: "qizhen:validate-fishing", risk: "rhythm timing, hold, failure, cancellation" }),
    Object.freeze({ area: "chapter-4", script: "chapter4:validate-warmup", risk: "asset readiness, retry, cancellation and degradation" }),
    Object.freeze({ area: "chapter-4", script: "chapter4:validate-guard-presentation", risk: "guard presentation state without authority mutation" }),
    Object.freeze({ area: "chapter-4", script: "chapter4:validate-effective-interactions", risk: "optional interactions across floor, mode and phase" })
  ]),
  extended: Object.freeze([
    Object.freeze({ area: "generated-text", script: "text:check", risk: "generated player-facing text inventory freshness" }),
    Object.freeze({ area: "task-ui", script: "verify:task-guidance", risk: "single owner for persistent route guidance" }),
    Object.freeze({ area: "developer-tools", script: "verify:developer-levels", risk: "checkpoint coverage and unique assignment" }),
    Object.freeze({ area: "chapter-3", script: "verify:canteen-bike-transition", risk: "transition timeline, assets and retired-path exclusion" }),
    Object.freeze({ area: "chapter-3", script: "qizhen:validate-journal", risk: "journal schema, authored copy and persona references" }),
    Object.freeze({ area: "chapter-4", script: "chapter4:validate-stair-materials", risk: "offline material integrity and provenance" })
  ])
});

const requestedSuite = process.argv[2] ?? "critical";
const selected = SUITES[requestedSuite];

if (!selected) {
  console.error(`Unknown test suite ${JSON.stringify(requestedSuite)}. Expected one of: ${Object.keys(SUITES).join(", ")}.`);
  process.exit(2);
}

const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";
const failures = [];
const startedAt = performance.now();

console.log(`Running ${requestedSuite} test suite (${selected.length} validators).`);

for (const test of selected) {
  const testStartedAt = performance.now();
  console.log(`\n[${test.area}] npm run ${test.script}`);
  console.log(`Risk: ${test.risk}`);

  const result = spawnSync(npmCommand, ["run", test.script], {
    cwd: process.cwd(),
    env: { ...process.env, CI: process.env.CI ?? "true" },
    stdio: "inherit"
  });

  const elapsedMs = Math.round(performance.now() - testStartedAt);
  if (result.error || result.status !== 0) {
    failures.push({
      ...test,
      status: result.status,
      signal: result.signal,
      error: result.error?.message ?? null,
      elapsedMs
    });
    console.error(`[FAIL] ${test.script} (${elapsedMs} ms)`);
    continue;
  }

  console.log(`[PASS] ${test.script} (${elapsedMs} ms)`);
}

const totalMs = Math.round(performance.now() - startedAt);
if (failures.length > 0) {
  console.error(`\n${requestedSuite} test suite failed: ${failures.length}/${selected.length} validators failed in ${totalMs} ms.`);
  for (const failure of failures) {
    const detail = [
      `status=${failure.status ?? "null"}`,
      failure.signal ? `signal=${failure.signal}` : null,
      failure.error ? `error=${failure.error}` : null,
      `elapsedMs=${failure.elapsedMs}`
    ].filter(Boolean).join(" ");
    console.error(`- ${failure.script}: ${detail}`);
  }
  process.exit(1);
}

console.log(`\n${requestedSuite} test suite PASS validators=${selected.length} elapsedMs=${totalMs}`);
