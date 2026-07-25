import { mkdir, stat } from "node:fs/promises";
import { resolve } from "node:path";
import { chromium } from "playwright";

const baseUrl = process.env.GODOT_VISUAL_BASE_URL ?? "http://127.0.0.1:4173";
const outputDirectory = resolve(process.cwd(), "artifacts/godot-migration");
await mkdir(outputDirectory, { recursive: true });
await waitForServer(baseUrl);

const browser = await chromium.launch({ headless: true, args: ["--disable-dev-shm-usage"] });
const failures = [];

try {
  await runDesktopCheck();
  await runMobileCheck();
} finally {
  await browser.close();
}

if (failures.length > 0) {
  console.error("Godot visual smoke failed:\n" + failures.map((failure) => `- ${failure}`).join("\n"));
  process.exit(1);
}
console.log("Godot Playwright visual smoke passed for desktop and 390x844 touch layouts.");

async function runDesktopCheck() {
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    deviceScaleFactor: 1,
    reducedMotion: "no-preference"
  });
  const page = await context.newPage();
  const diagnostics = collectDiagnostics(page, "desktop");
  try {
    await page.goto(`${baseUrl}/?engine=godot&dev=0&devCheckpoint=c2-library-gate`, {
      waitUntil: "domcontentloaded",
      timeout: 45_000
    });
    const host = page.locator('.godot-rpg-stage[data-godot-status="ready"]');
    await host.waitFor({ state: "visible", timeout: 35_000 });
    const frame = await waitForGodotFrame(page);
    const canvas = frame.locator("canvas");
    await canvas.waitFor({ state: "visible", timeout: 20_000 });

    await verifyNoOverflow(page, "desktop");
    await verifyAspectRatio(page.locator(".godot-rpg-frame"), 16 / 9, "desktop Godot canvas");
    await verifyCanvasScreenshot(canvas, resolve(outputDirectory, "desktop-canvas.png"), "desktop canvas");
    await page.screenshot({ path: resolve(outputDirectory, "desktop-page.png"), fullPage: false });

    const startX = await readNumberAttribute(host, "data-godot-player-x");
    await canvas.click({ position: { x: 480, y: 270 } });
    await page.keyboard.down("d");
    await page.waitForTimeout(650);
    await page.keyboard.up("d");
    await waitForNumberAttribute(host, "data-godot-player-x", (value) => value > startX + 20);

    const startZoom = await readNumberAttribute(host, "data-godot-camera-zoom");
    await page.getByRole("button", { name: "放大地图" }).click();
    await waitForNumberAttribute(host, "data-godot-camera-zoom", (value) => value > startZoom);

    const stateText = await page.evaluate(() => window.render_game_to_text?.() ?? "");
    const state = JSON.parse(stateText);
    if (state.rpgCheckpoint !== "campus_library_gate") {
      failures.push(`desktop React state checkpoint mismatch: ${state.rpgCheckpoint}`);
    }
    if (state.desktopGameplay?.godotFrameCount !== 1) {
      failures.push(`desktop expected one Godot iframe, found ${state.desktopGameplay?.godotFrameCount}`);
    }
    if (state.desktopGameplay?.phaserCanvasCount !== 0) {
      failures.push(`desktop Phaser canvas should be absent in Godot mode, found ${state.desktopGameplay?.phaserCanvasCount}`);
    }
    if (state.desktopGameplay?.activeRpgSurfaceCount !== 1) {
      failures.push(`desktop expected one active RPG surface, found ${state.desktopGameplay?.activeRpgSurfaceCount}`);
    }
  } catch (error) {
    failures.push(`desktop: ${formatError(error)}`);
  } finally {
    failures.push(...diagnostics());
    await context.close();
  }
}

async function runMobileCheck() {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    hasTouch: true,
    isMobile: true,
    reducedMotion: "reduce"
  });
  const page = await context.newPage();
  const diagnostics = collectDiagnostics(page, "mobile");
  try {
    await page.goto(`${baseUrl}/?engine=godot&dev=0&devCheckpoint=c2-library-gate`, {
      waitUntil: "domcontentloaded",
      timeout: 45_000
    });
    const host = page.locator('.godot-rpg-stage[data-godot-status="ready"]');
    await host.waitFor({ state: "visible", timeout: 35_000 });
    const frame = await waitForGodotFrame(page);
    const canvas = frame.locator("canvas");
    await canvas.waitFor({ state: "visible", timeout: 20_000 });

    await verifyNoOverflow(page, "mobile");
    await verifyAspectRatio(page.locator(".godot-rpg-frame"), 16 / 9, "mobile Godot canvas");
    const touchControls = page.locator(".godot-touch-controls button");
    const touchCount = await touchControls.count();
    if (touchCount !== 5) failures.push(`mobile expected five touch controls, found ${touchCount}`);

    const status = page.locator(".godot-runtime-status");
    const controls = page.locator(".godot-touch-controls");
    if (await rectanglesOverlap(status, controls)) {
      failures.push("mobile runtime status overlaps touch controls");
    }

    const startX = await readNumberAttribute(host, "data-godot-player-x");
    const right = page.getByRole("button", { name: "向右" });
    await right.dispatchEvent("pointerdown", {
      pointerId: 11,
      pointerType: "touch",
      isPrimary: true,
      buttons: 1
    });
    await page.waitForTimeout(650);
    await page.locator("body").dispatchEvent("pointerup", {
      pointerId: 11,
      pointerType: "touch",
      isPrimary: true,
      buttons: 0
    });
    await waitForNumberAttribute(host, "data-godot-player-x", (value) => value > startX + 20);

    await verifyCanvasScreenshot(canvas, resolve(outputDirectory, "mobile-canvas.png"), "mobile canvas");
    await page.screenshot({ path: resolve(outputDirectory, "mobile-page.png"), fullPage: false });
  } catch (error) {
    failures.push(`mobile: ${formatError(error)}`);
  } finally {
    failures.push(...diagnostics());
    await context.close();
  }
}

async function waitForGodotFrame(page) {
  const deadline = Date.now() + 30_000;
  while (Date.now() < deadline) {
    const frame = page.frames().find((candidate) => candidate.url().includes("/godot/index.html"));
    if (frame) return frame;
    await page.waitForTimeout(100);
  }
  throw new Error("Godot iframe did not attach");
}

async function verifyNoOverflow(page, label) {
  const dimensions = await page.evaluate(() => ({
    width: document.documentElement.scrollWidth,
    height: document.documentElement.scrollHeight,
    innerWidth: window.innerWidth,
    innerHeight: window.innerHeight
  }));
  if (dimensions.width > dimensions.innerWidth + 1) {
    failures.push(`${label} horizontal overflow ${dimensions.width} > ${dimensions.innerWidth}`);
  }
  if (dimensions.height > dimensions.innerHeight + 1) {
    failures.push(`${label} vertical overflow ${dimensions.height} > ${dimensions.innerHeight}`);
  }
}

async function verifyAspectRatio(locator, expected, label) {
  const box = await locator.boundingBox();
  if (!box || box.width <= 0 || box.height <= 0) {
    failures.push(`${label} has no visible bounds`);
    return;
  }
  const ratio = box.width / box.height;
  if (Math.abs(ratio - expected) > 0.035) {
    failures.push(`${label} ratio ${ratio.toFixed(3)} differs from ${expected.toFixed(3)}`);
  }
}

async function verifyCanvasScreenshot(canvas, path, label) {
  await canvas.screenshot({ path });
  const screenshot = await stat(path);
  if (screenshot.size < 20_000) {
    failures.push(`${label} screenshot is suspiciously small: ${screenshot.size} bytes`);
  }
}

async function rectanglesOverlap(a, b) {
  if (await a.count() === 0 || await b.count() === 0) return false;
  const [aBox, bBox] = await Promise.all([a.boundingBox(), b.boundingBox()]);
  if (!aBox || !bBox) return false;
  const width = Math.min(aBox.x + aBox.width, bBox.x + bBox.width) - Math.max(aBox.x, bBox.x);
  const height = Math.min(aBox.y + aBox.height, bBox.y + bBox.height) - Math.max(aBox.y, bBox.y);
  return width > 1 && height > 1;
}

async function readNumberAttribute(locator, attribute) {
  const raw = await locator.getAttribute(attribute);
  const value = Number(raw);
  if (!Number.isFinite(value)) throw new Error(`invalid ${attribute}: ${raw}`);
  return value;
}

async function waitForNumberAttribute(locator, attribute, predicate) {
  const deadline = Date.now() + 10_000;
  while (Date.now() < deadline) {
    const raw = await locator.getAttribute(attribute);
    const value = Number(raw);
    if (Number.isFinite(value) && predicate(value)) return value;
    await new Promise((resolvePromise) => setTimeout(resolvePromise, 100));
  }
  throw new Error(`${attribute} did not reach the expected condition`);
}

function collectDiagnostics(page, label) {
  const messages = [];
  page.on("pageerror", (error) => messages.push(`${label} pageerror: ${error.message}`));
  page.on("console", (message) => {
    if (message.type() === "error") messages.push(`${label} console: ${message.text()}`);
  });
  page.on("requestfailed", (request) => {
    messages.push(`${label} request failed: ${request.url()} ${request.failure()?.errorText ?? "unknown"}`);
  });
  return () => messages;
}

async function waitForServer(url) {
  const deadline = Date.now() + 30_000;
  let lastError = "";
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url, { redirect: "manual" });
      if (response.ok || response.status === 304) return;
      lastError = `HTTP ${response.status}`;
    } catch (error) {
      lastError = formatError(error);
    }
    await new Promise((resolvePromise) => setTimeout(resolvePromise, 250));
  }
  throw new Error(`Vite preview did not become ready: ${lastError}`);
}

function formatError(error) {
  return error instanceof Error ? error.stack ?? error.message : String(error);
}
