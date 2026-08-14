import { chromium, firefox, webkit } from "playwright";
import { mkdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const baseUrl = process.env.QA_BASE_URL ?? "http://127.0.0.1:4173";
const outputDir = resolve(process.env.QA_OUTPUT_DIR ?? "artifacts/human-copy-playwright");
mkdirSync(outputDir, { recursive: true });

const browsers = [
  ["chromium", chromium],
  ["firefox", firefox],
  ["webkit", webkit]
];

const viewports = [
  ["desktop", { width: 1280, height: 720 }],
  ["tall", { width: 1000, height: 900 }],
  ["mobile", { width: 390, height: 844 }]
];

const checkpoints = [
  "c2-gamepad-market",
  "c3-canteen-entry",
  "c3-theater-ticket-request",
  "c3-qizhen-location",
  "c3-qizhen-boarding",
  "c3-qizhen-swan",
  "c3-qizhen-chase"
];

const results = [];
const failures = [];

for (const [browserName, browserType] of browsers) {
  const browser = await browserType.launch({ headless: true });
  try {
    for (const [viewportName, viewport] of viewports) {
      const context = await browser.newContext({ viewport, reducedMotion: "reduce" });
      for (const checkpoint of checkpoints) {
        const page = await context.newPage();
        const errors = [];
        page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));
        page.on("console", (message) => {
          if (message.type() === "error") errors.push(`console.error: ${message.text()}`);
        });

        const url = `${baseUrl}/?devCheckpoint=${encodeURIComponent(checkpoint)}`;
        let state = null;
        let layout = null;
        try {
          const response = await page.goto(url, { waitUntil: "domcontentloaded", timeout: 45_000 });
          if (!response?.ok()) throw new Error(`HTTP ${response?.status() ?? "no-response"}`);
          await page.waitForFunction(() => typeof window.render_game_to_text === "function", null, { timeout: 20_000 });
          await page.waitForTimeout(900);

          state = await page.evaluate(() => JSON.parse(window.render_game_to_text()));
          layout = await page.evaluate(() => {
            const root = document.documentElement;
            const body = document.body;
            const frame = document.querySelector(".phone-frame");
            const rect = frame?.getBoundingClientRect();
            return {
              innerWidth: window.innerWidth,
              innerHeight: window.innerHeight,
              scrollWidth: Math.max(root.scrollWidth, body.scrollWidth),
              scrollHeight: Math.max(root.scrollHeight, body.scrollHeight),
              phoneFrames: document.querySelectorAll(".phone-frame").length,
              phoneRect: rect ? { width: rect.width, height: rect.height } : null
            };
          });

          if (layout.scrollWidth > layout.innerWidth + 2) {
            errors.push(`horizontal overflow ${layout.scrollWidth} > ${layout.innerWidth}`);
          }
          if (layout.scrollHeight > layout.innerHeight + 2) {
            errors.push(`document overflow ${layout.scrollHeight} > ${layout.innerHeight}`);
          }
          if (state.runtimeMode === "phone") {
            if (layout.phoneFrames !== 1) errors.push(`phone frame count ${layout.phoneFrames}`);
            if (layout.phoneRect) {
              const ratio = layout.phoneRect.width / layout.phoneRect.height;
              if (Math.abs(ratio - 0.5) > 0.025) errors.push(`phone ratio drift ${ratio.toFixed(4)}`);
            }
          }

          if (browserName === "chromium") {
            const shotName = `${checkpoint}-${viewportName}.png`;
            await page.screenshot({ path: join(outputDir, shotName), fullPage: true });
          }
        } catch (error) {
          errors.push(`exception: ${error instanceof Error ? error.message : String(error)}`);
        }

        const record = { browserName, viewportName, checkpoint, state, layout, errors };
        results.push(record);
        if (errors.length) failures.push(record);
        await page.close();
      }
      await context.close();
    }
  } finally {
    await browser.close();
  }
}

const summary = {
  baseUrl,
  cases: results.length,
  failedCases: failures.length,
  failures,
  results
};
writeFileSync(join(outputDir, "report.json"), JSON.stringify(summary, null, 2));
process.stdout.write(`${JSON.stringify({ cases: summary.cases, failedCases: summary.failedCases }, null, 2)}\n`);
if (failures.length) process.exitCode = 1;
