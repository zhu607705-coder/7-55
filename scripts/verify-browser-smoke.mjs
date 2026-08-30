#!/usr/bin/env node

import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readdirSync } from "node:fs";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const host = "127.0.0.1";
const port = 4173;
const origin = `http://${host}:${port}`;
const viteBinary = path.join(
  root,
  "node_modules",
  ".bin",
  process.platform === "win32" ? "vite.cmd" : "vite"
);

const cases = Object.freeze([
  Object.freeze({
    id: "phone-mobile",
    path: "/?dev=1",
    width: 390,
    height: 844,
    surface: "phone",
    virtualTimeMs: 8_000
  }),
  Object.freeze({
    id: "theater-rpg",
    path: "/?devCheckpoint=c3-theater-entry&dev=1",
    width: 1440,
    height: 900,
    surface: "rpg",
    virtualTimeMs: 14_000
  }),
  Object.freeze({
    id: "chapter4-rpg",
    path: "/?devCheckpoint=c4-755-opening&dev=1",
    width: 1440,
    height: 900,
    surface: "rpg",
    virtualTimeMs: 16_000
  })
]);

const tempRoot = await mkdtemp(path.join(tmpdir(), "seven-fifty-five-browser-smoke-"));
let previewOutput = "";
let preview;

try {
  const chrome = findChrome();
  preview = spawn(viteBinary, [
    "preview",
    "--mode",
    "demo",
    "--host",
    host,
    "--port",
    String(port),
    "--strictPort"
  ], {
    cwd: root,
    env: { ...process.env, CI: process.env.CI ?? "true" },
    stdio: ["ignore", "pipe", "pipe"]
  });

  preview.stdout.on("data", (chunk) => { previewOutput = appendBounded(previewOutput, chunk); });
  preview.stderr.on("data", (chunk) => { previewOutput = appendBounded(previewOutput, chunk); });

  await waitForPreview(preview);
  const results = [];

  for (const testCase of cases) {
    const profileDir = path.join(tempRoot, `${testCase.id}-profile`);
    const screenshotPath = path.join(tempRoot, `${testCase.id}.png`);
    const url = new URL(testCase.path, origin).href;
    const chromeResult = await runChromeSmoke(chrome, [
      "--headless=new",
      "--no-sandbox",
      "--disable-dev-shm-usage",
      "--disable-background-networking",
      "--disable-default-apps",
      "--disable-extensions",
      "--disable-sync",
      "--mute-audio",
      "--autoplay-policy=no-user-gesture-required",
      "--hide-scrollbars",
      "--force-device-scale-factor=1",
      `--window-size=${testCase.width},${testCase.height}`,
      `--user-data-dir=${profileDir}`,
      `--virtual-time-budget=${testCase.virtualTimeMs}`,
      `--screenshot=${screenshotPath}`,
      url
    ], {
      cwd: root,
      timeoutMs: 90_000
    });

    if (chromeResult.error) {
      throw new Error(`${testCase.id}: Chromium launch failed: ${chromeResult.error.message}`);
    }
    if (chromeResult.status !== 0) {
      throw new Error(
        `${testCase.id}: Chromium exited with status ${chromeResult.status}\n${chromeResult.stderr}`
      );
    }

    const screenshot = await readFile(screenshotPath);
    const dimensions = readPngDimensions(screenshot);
    if (!dimensions) {
      throw new Error(`${testCase.id}: Chromium did not produce a valid PNG screenshot`);
    }
    if (dimensions.width !== testCase.width || dimensions.height !== testCase.height) {
      throw new Error(
        `${testCase.id}: screenshot dimensions ${dimensions.width}x${dimensions.height} differ from ${testCase.width}x${testCase.height}`
      );
    }
    if (screenshot.length < 8_000) {
      throw new Error(`${testCase.id}: screenshot is unexpectedly small (${screenshot.length} bytes)`);
    }

    results.push({
      id: testCase.id,
      surface: testCase.surface,
      bytes: screenshot.length,
      width: dimensions.width,
      height: dimensions.height,
      sha256: createHash("sha256").update(screenshot).digest("hex")
    });
  }

  const uniqueScreenshots = new Set(results.map((result) => result.sha256));
  if (uniqueScreenshots.size !== results.length) {
    throw new Error("browser smoke cases produced duplicate screenshots; checkpoint routing may not have applied");
  }

  console.log(
    `Browser smoke PASS cases=${results.length} ` +
    results.map((result) => (
      `${result.id}:${result.width}x${result.height}:surface=${result.surface}:bytes=${result.bytes}`
    )).join(" ")
  );
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  if (previewOutput.trim()) {
    console.error(`\nVite preview output:\n${previewOutput.trim()}`);
  }
  process.exitCode = 1;
} finally {
  await stopProcess(preview);
  await rm(tempRoot, { recursive: true, force: true });
}

function runChromeSmoke(executable, args, { cwd, timeoutMs }) {
  return new Promise((resolve) => {
    const child = spawn(executable, args, {
      cwd,
      stdio: ["ignore", "pipe", "pipe"]
    });
    let settled = false;
    let error = null;
    let stderr = "";

    const finish = (status) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolve({
        status,
        error,
        stderr: trimDiagnostic(stderr)
      });
    };

    child.stdout.resume();
    child.stderr.on("data", (chunk) => { stderr = appendBounded(stderr, chunk); });
    child.on("error", (nextError) => {
      error = nextError;
      finish(null);
    });
    child.on("close", (status) => finish(status));

    const timer = setTimeout(() => {
      error = new Error(`Chromium smoke timed out after ${timeoutMs}ms`);
      child.kill("SIGKILL");
      finish(null);
    }, timeoutMs);
  });
}

function findChrome() {
  const candidates = [
    process.env.CHROME_BIN,
    process.env.GOOGLE_CHROME_BIN,
    ...findPlaywrightHeadlessShells(),
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/usr/bin/google-chrome-stable",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "google-chrome-stable",
    "google-chrome",
    "chromium",
    "chromium-browser"
  ].filter(Boolean);

  for (const candidate of [...new Set(candidates)]) {
    const probe = spawnSync(candidate, ["--version"], {
      encoding: "utf8",
      timeout: 10_000
    });
    if (!probe.error && probe.status === 0) return candidate;
  }

  throw new Error(
    "No supported Chromium executable was found. Set CHROME_BIN to google-chrome, google-chrome-stable, chromium, or chromium-browser."
  );
}

function findPlaywrightHeadlessShells() {
  const roots = [
    process.env.PLAYWRIGHT_BROWSERS_PATH,
    path.join(homedir(), "Library", "Caches", "ms-playwright"),
    path.join(homedir(), ".cache", "ms-playwright")
  ].filter((value) => value && existsSync(value));
  const executables = [];

  for (const rootPath of roots) {
    let versions = [];
    try {
      versions = readdirSync(rootPath)
        .filter((entry) => entry.startsWith("chromium_headless_shell-"))
        .sort()
        .reverse();
    } catch {
      continue;
    }
    for (const version of versions) {
      const versionRoot = path.join(rootPath, version);
      executables.push(
        path.join(versionRoot, "chrome-headless-shell-mac-arm64", "chrome-headless-shell"),
        path.join(versionRoot, "chrome-headless-shell-mac-x64", "chrome-headless-shell"),
        path.join(versionRoot, "chrome-headless-shell-linux64", "chrome-headless-shell"),
        path.join(versionRoot, "chrome-headless-shell-win64", "chrome-headless-shell.exe")
      );
    }
  }

  return executables.filter((candidate) => existsSync(candidate));
}

async function waitForPreview(child) {
  const deadline = Date.now() + 25_000;
  let lastError = null;

  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      throw new Error(`Vite preview exited before readiness with code ${child.exitCode}`);
    }
    try {
      const response = await fetch(`${origin}/`, { signal: AbortSignal.timeout(1_500) });
      if (response.ok) return;
      lastError = new Error(`HTTP ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }

  throw new Error(
    `Vite preview did not become ready at ${origin}: ${lastError instanceof Error ? lastError.message : String(lastError)}`
  );
}

function readPngDimensions(buffer) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (buffer.length < 24 || !buffer.subarray(0, 8).equals(signature)) return null;
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20)
  };
}

function appendBounded(current, chunk) {
  const next = current + String(chunk);
  return next.length > 32_000 ? next.slice(-32_000) : next;
}

function trimDiagnostic(value) {
  const text = String(value ?? "").trim();
  return text.length > 8_000 ? text.slice(-8_000) : text;
}

async function stopProcess(child) {
  if (!child || child.exitCode !== null) return;
  child.kill("SIGTERM");
  const exited = await Promise.race([
    new Promise((resolve) => child.once("exit", () => resolve(true))),
    new Promise((resolve) => setTimeout(() => resolve(false), 2_000))
  ]);
  if (!exited && child.exitCode === null) child.kill("SIGKILL");
}
