#!/usr/bin/env node

import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readdirSync } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const host = "127.0.0.1";
const port = 4173;
const origin = `http://${host}:${port}`;
const viteCliPath = path.join(root, "node_modules", "vite", "bin", "vite.js");

const cases = Object.freeze([
  Object.freeze({
    id: "cc98-stale-session",
    path: "/?devCheckpoint=c4-755-opening&dev=1",
    fixture: "c2-cc98-upload",
    width: 390,
    height: 844,
    surface: "phone",
    verifyPersistence: true,
    virtualTimeMs: 8_000
  }),
  Object.freeze({
    id: "phone-mobile",
    path: "/?devCheckpoint=c4-755-opening&dev=1",
    width: 390,
    height: 844,
    surface: "phone",
    virtualTimeMs: 8_000
  }),
  Object.freeze({
    id: "theater-rpg",
    path: "/?devCheckpoint=c4-755-opening&dev=1",
    fixture: "c3-theater-entry",
    width: 1440,
    height: 900,
    surface: "rpg",
    virtualTimeMs: 14_000
  }),
  Object.freeze({
    id: "chapter4-rpg",
    path: "/?devCheckpoint=c3-theater-entry&dev=1",
    fixture: "c4-755-opening",
    width: 1440,
    height: 900,
    surface: "rpg",
    virtualTimeMs: 16_000
  })
]);

const tempRoot = await mkdtemp(path.join(tmpdir(), "seven-fifty-five-browser-smoke-"));
const artifactRoot = process.env.BROWSER_SMOKE_ARTIFACT_DIR
  ? path.resolve(process.env.BROWSER_SMOKE_ARTIFACT_DIR) : tempRoot;
let previewOutput = "";
let preview;

try {
  const chrome = findChrome();
  preview = spawn(process.execPath, [
    viteCliPath,
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
  await mkdir(artifactRoot, { recursive: true });
  const fixtures = await createSaveFixtures();
  const results = [];

  for (const testCase of cases) {
    const profileDir = path.join(tempRoot, `${testCase.id}-profile`);
    const screenshotPath = path.join(artifactRoot, `${testCase.id}.png`);
    const url = new URL(testCase.path, origin).href;
    const fixture = fixtures.get(testCase.fixture ?? "initial");
    const browserEvidence = await runChromeSmoke(chrome, [
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
      "--remote-debugging-port=0",
      "about:blank"
    ], { profileDir, screenshotPath, url, testCase, fixture });

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
      sha256: createHash("sha256").update(screenshot).digest("hex"),
      ...browserEvidence
    });
  }

  const uniqueScreenshots = new Set(results.map((result) => result.sha256));
  if (uniqueScreenshots.size !== results.length) {
    throw new Error("browser smoke cases produced duplicate screenshots; saved chapter fixtures may not have loaded");
  }

  await writeFile(path.join(artifactRoot, "browser-smoke.json"), JSON.stringify({
    passed: true, artifact: "demo/index.html", developerEntryPolicy: "production rejects URL and keyboard checkpoint entry",
    fixtureMethod: "External CDP storage initialization using SaveStore.save/load validated envelopes; no product QA hook",
    results
  }, null, 2) + "\n");

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

async function createSaveFixtures() {
  // This factory executes only in the external test process. The shipped game
  // receives an ordinary versioned save through its existing storage boundary.
  const bundle = await build({
    stdin: { contents: `export {createDeveloperCheckpointState} from './src/modules/DeveloperChannel.ts';
      export {createInitialGameState} from './src/core/GameState.ts';
      export {SaveStore} from './src/core/SaveStore.ts';
      export * from './src/core/StorageKeys.ts';
      export {selectFeatureAccess} from './src/core/FeatureAccess.ts';`, resolveDir: root },
    bundle: true, platform: "node", format: "esm", write: false, logLevel: "silent"
  });
  const api = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);
  const fixtures = new Map();
  const staleSession = [
    [api.DEVELOPER_ACTIVE_KEY, "c4-755-opening"], [api.DEVELOPER_SOURCE_KEY, "url"],
    [api.DEVELOPER_BACKUP_KEY, JSON.stringify(api.createDeveloperCheckpointState("c4-755-opening"))],
    [api.DEVELOPER_PANEL_OPEN_KEY, "1"], [api.DEVELOPER_CANTEEN_DEFENSE_START_KEY, "50000"],
    [api.DEVELOPER_CHAPTER4_PROLOGUE_OFFSET_KEY, "123"],
    [api.DEVELOPER_CHAPTER4_TASK_CARD_CONFIRMED_KEY, "1"], [api.DEVELOPER_QIZHEN_RHYTHM_SPAWN_KEY, "key"]
  ];
  for (const id of ["initial", "c2-cc98-upload", "c3-theater-entry", "c4-755-opening"]) {
    const state = id === "initial" ? api.createInitialGameState() : api.createDeveloperCheckpointState(id);
    const values = new Map();
    const storage = { getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, String(value)) };
    const saves = new api.SaveStore(storage);
    if (!saves.save(state)) throw new Error(`${id}: SaveStore refused fixture serialization`);
    const loaded = saves.load(api.createInitialGameState());
    if (!loaded || loaded.runtimeMode !== state.runtimeMode || loaded.rpgScene !== state.rpgScene || loaded.currentScene !== state.currentScene) {
      throw new Error(`${id}: SaveStore validation changed the required fixture route`);
    }
    if (!saves.save(loaded) || JSON.stringify(saves.load(api.createInitialGameState())) !== JSON.stringify(loaded)) {
      throw new Error(`${id}: normalized fixture is not stable across SaveStore save/load`);
    }
    const envelope = values.get(api.GAME_SAVE_KEY);
    fixtures.set(id, { id, key: api.GAME_SAVE_KEY, envelope: id === "initial" ? null : envelope, staleSession,
      saveVersion: JSON.parse(envelope).version, saveSha256: createHash("sha256").update(envelope).digest("hex"),
      expected: { runtimeMode: loaded.runtimeMode, rpgScene: loaded.rpgScene, currentScene: loaded.currentScene, chapter: api.selectFeatureAccess(loaded).chapter } });
  }
  return fixtures;
}

async function runChromeSmoke(executable, args, { profileDir, screenshotPath, url, testCase, fixture }) {
  const child = spawn(executable, args, { cwd: root, stdio: ["ignore", "pipe", "pipe"] });
  let diagnostics = "";
  let launchError;
  child.stdout.resume();
  child.stderr.on("data", chunk => { diagnostics = appendBounded(diagnostics, chunk); });
  child.on("error", error => { launchError = error; });
  let cdp;
  try {
    const active = await waitForValue(async () => {
      if (launchError) throw launchError;
      if (child.exitCode !== null) throw new Error(`Chromium exited ${child.exitCode}`);
      try { return await readFile(path.join(profileDir, "DevToolsActivePort"), "utf8"); } catch { return null; }
    }, 20_000, "Chromium debugging endpoint");
    const debugOrigin = `http://127.0.0.1:${active.split("\n")[0]}`;
    const target = await waitForValue(async () => (await (await fetch(debugOrigin + "/json/list")).json()).find(item => item.type === "page"), 10_000, "Chromium page");
    cdp = await connectCdp(target.webSocketDebuggerUrl);
    await cdp.send("Page.enable");
    await cdp.send("Runtime.enable");
    await cdp.send("Emulation.setDeviceMetricsOverride", { width: testCase.width, height: testCase.height, deviceScaleFactor: 1, mobile: false });
    // Seed once only. A real reload must read the application's newly saved
    // envelope, not silently receive the original fixture a second time.
    await cdp.send("Page.addScriptToEvaluateOnNewDocument", { source: `if(location.origin===${JSON.stringify(origin)}&&sessionStorage.getItem('smoke.fixture.initialized')!=='1'){localStorage.clear();sessionStorage.clear();${fixture.envelope ? `localStorage.setItem(${JSON.stringify(fixture.key)},${JSON.stringify(fixture.envelope)});` : ""}for(const [key,value] of ${JSON.stringify(fixture.staleSession)})sessionStorage.setItem(key,value);sessionStorage.setItem('smoke.fixture.initialized','1');}` });
    await cdp.send("Page.navigate", { url });
    const read = async () => {
      const response = await cdp.send("Runtime.evaluate", { expression: `typeof window.render_game_to_text==='function' ? JSON.parse(window.render_game_to_text()) : null`, returnByValue: true });
      return response.result?.value ?? null;
    };
    const state = await waitForValue(async () => {
      try { const value = await read(); return value && (testCase.surface !== "rpg" || value.desktopGameplay?.phaserCanvasCount > 0) ? value : null; } catch { return null; }
    }, 70_000, `${testCase.id} production runtime`);
    const assertRoute = value => {
      for (const [key, expected] of Object.entries(fixture.expected)) {
        if (value[key] !== expected) throw new Error(`${testCase.id}: ${key}=${JSON.stringify(value[key])}, expected saved fixture ${JSON.stringify(expected)}; dev URL must be ignored`);
      }
      if (value.recordingMode?.developerChannelOpen || value.recordingMode?.developerLauncherVisible) throw new Error(`${testCase.id}: production developer UI is visible`);
    };
    assertRoute(state);
    let chapter4Readiness;
    if (testCase.id === "chapter4-rpg") {
      const started = Date.now();
      const ready = await waitForValue(async () => {
        const value = await read();
        const entry = value?.rpgWarmup?.phaseSnapshots?.find(phase => (
          phase.sceneId === "duan_yongping_temporal_maze" && phase.phase === "entry"
        ));
        const input = value?.rpgRuntime?.input;
        if (entry?.status !== "ready" || entry.failedUrls.length
          || value?.rpgRuntime?.scene !== "duan_yongping_temporal_maze"
          || !input?.gameEnabled || !input.sceneEnabled || !input.keyboardEnabled) return null;
        const overlay = await cdp.send("Runtime.evaluate", {
          expression: "document.querySelector('.chapter4-prologue-overlay') !== null",
          returnByValue: true
        });
        return overlay.result?.value === false ? value : null;
      }, 70_000, "Chapter 4 entry warmup, live map input and released prologue overlay");
      chapter4Readiness = {
        waitedMs: Date.now() - started,
        scene: ready.rpgRuntime.scene,
        input: ready.rpgRuntime.input,
        entry: ready.rpgWarmup.phaseSnapshots.find(phase => (
          phase.sceneId === "duan_yongping_temporal_maze" && phase.phase === "entry"
        )),
        prologueOverlayVisible: false
      };
    }
    for (const modifiers of [10, 12]) {
      await cdp.send("Input.dispatchKeyEvent", { type: "rawKeyDown", key: "D", code: "KeyD", windowsVirtualKeyCode: 68, modifiers });
      await cdp.send("Input.dispatchKeyEvent", { type: "keyUp", key: "D", code: "KeyD", windowsVirtualKeyCode: 68, modifiers });
    }
    await new Promise(resolve => setTimeout(resolve, 300));
    assertRoute(await read());
    const dev = await cdp.send("Runtime.evaluate", { expression: `({controller:typeof window.__game,panel:document.querySelector('[data-developer-channel-root]')!==null})`, returnByValue: true });
    if (dev.result.value.controller !== "undefined" || dev.result.value.panel) throw new Error(`${testCase.id}: production developer controller/panel is exposed`);
    await new Promise(resolve => setTimeout(resolve, Math.min(testCase.virtualTimeMs, 3_000)));
    const shot = await cdp.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false, fromSurface: true });
    await writeFile(screenshotPath, Buffer.from(shot.data, "base64"));
    const session = await cdp.send("Runtime.evaluate", { expression: `({remaining:${JSON.stringify(fixture.staleSession.map(([key]) => key))}.filter(key=>sessionStorage.getItem(key)!==null),maintenance:document.querySelector('[aria-label="开发者帖子维护"]')!==null})`, returnByValue: true });
    let persistence;
    if (testCase.verifyPersistence) {
      const button = await cdp.send("Runtime.evaluate", { expression: `(()=>{const b=document.querySelector('button[aria-label="退出 CC98，返回手机主页"]');if(!b)return null;const r=b.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};})()`, returnByValue: true });
      if (!button.result.value) throw new Error("CC98 ordinary exit control is missing");
      const point = button.result.value;
      await cdp.send("Input.dispatchMouseEvent", { type: "mousePressed", button: "left", clickCount: 1, ...point });
      await cdp.send("Input.dispatchMouseEvent", { type: "mouseReleased", button: "left", clickCount: 1, ...point });
      await waitForValue(async () => { const value = await read(); return value?.currentScene === "phone_home" ? value : null; }, 10_000, "ordinary CC98 return to phone home");
      const saved = await cdp.send("Runtime.evaluate", { expression: `JSON.parse(localStorage.getItem(${JSON.stringify(fixture.key)})||'null')`, returnByValue: true });
      if (saved.result.value?.state?.currentScene !== "phone_home") {
        throw new Error("Ordinary CC98 exit was not persisted: a stale developer session must not suppress formal saves");
      }
      await cdp.send("Page.reload", { ignoreCache: true });
      const reloaded = await waitForValue(async () => { try { return await read(); } catch { return null; } }, 70_000, "saved formal state after real reload");
      if (reloaded.currentScene !== "phone_home" || reloaded.chapter !== fixture.expected.chapter) throw new Error("Ordinary saved progress did not survive reload");
      persistence = { action: "actual CC98 exit button", savedScene: "phone_home", realReloadRetained: true };
    }
    if (session.result.value.remaining.length || session.result.value.maintenance) {
      throw new Error(`Production retained QA session flags or CC98 maintenance UI: ${JSON.stringify(session.result.value)}`);
    }
    return { fixture: fixture.id, fixtureSource: "external factory → SaveStore.save/load → ordinary persisted envelope",
      saveVersion: fixture.saveVersion, saveSha256: fixture.saveSha256, expectedRoute: fixture.expected,
      devUrlRejected: true, ctrlAndMetaShiftDRejected: true, productControllerExposed: false,
      staleDeveloperSessionCleared: true, cc98MaintenanceHidden: !session.result.value.maintenance,
      chapter4Readiness, persistence };
  } catch (error) {
    throw new Error(`${testCase.id}: ${error.message}\n${trimDiagnostic(diagnostics)}`);
  } finally {
    cdp?.close();
    await stopProcess(child);
  }
}

async function waitForValue(read, timeoutMs, label) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const value = await read();
    if (value) return value;
    await new Promise(resolve => setTimeout(resolve, 150));
  }
  throw new Error(`Timed out waiting for ${label}`);
}

async function connectCdp(url) {
  const socket = new WebSocket(url);
  await new Promise((resolve, reject) => { socket.addEventListener("open", resolve, { once: true }); socket.addEventListener("error", reject, { once: true }); });
  let sequence = 0;
  const pending = new Map();
  socket.addEventListener("message", event => {
    const message = JSON.parse(String(event.data));
    if (!message.id || !pending.has(message.id)) return;
    const item = pending.get(message.id); pending.delete(message.id); clearTimeout(item.timer);
    if (message.error) item.reject(new Error(message.error.message)); else item.resolve(message.result);
  });
  return { send(method, params = {}) { return new Promise((resolve, reject) => {
    const id = ++sequence;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`CDP timeout: ${method}`)); }, 30_000);
    pending.set(id, { resolve, reject, timer }); socket.send(JSON.stringify({ id, method, params }));
  }); }, close() { for (const item of pending.values()) { clearTimeout(item.timer); item.reject(new Error("CDP closed")); } pending.clear(); socket.close(); } };
}

function findChrome() {
  const candidates = [
    process.env.CHROME_BIN,
    process.env.GOOGLE_CHROME_BIN,
    ...findPlaywrightHeadlessShells(),
    process.env.PROGRAMFILES && path.join(process.env.PROGRAMFILES, "Google", "Chrome", "Application", "chrome.exe"),
    process.env["PROGRAMFILES(X86)"] && path.join(process.env["PROGRAMFILES(X86)"], "Google", "Chrome", "Application", "chrome.exe"),
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, "Google", "Chrome", "Application", "chrome.exe"),
    process.env.PROGRAMFILES && path.join(process.env.PROGRAMFILES, "Microsoft", "Edge", "Application", "msedge.exe"),
    process.env["PROGRAMFILES(X86)"] && path.join(process.env["PROGRAMFILES(X86)"], "Microsoft", "Edge", "Application", "msedge.exe"),
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
    path.join(homedir(), ".cache", "ms-playwright"),
    path.join(homedir(), "AppData", "Local", "ms-playwright")
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
      // Readiness only needs headers. GET starts transferring the complete
      // embedded game (~236MB) and can time out before a ready server responds.
      // The three browser cases below still load and render the entire page.
      const response = await fetch(`${origin}/`, { method: "HEAD", signal: AbortSignal.timeout(5_000) });
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
