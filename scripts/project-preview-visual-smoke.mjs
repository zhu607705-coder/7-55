import { mkdir, stat } from "node:fs/promises";
import { resolve } from "node:path";
import { chromium } from "playwright";

const baseUrl = process.env.PROJECT_PREVIEW_BASE_URL ?? "http://127.0.0.1:4175";
const outputDirectory = resolve(process.cwd(), "artifacts/project-preview");
await mkdir(outputDirectory, { recursive: true });
await waitForServer(`${baseUrl}/project-preview.html`);

const browser = await chromium.launch({ headless: true, args: ["--disable-dev-shm-usage"] });
const failures = [];

try {
  await runViewport("desktop", { width: 1440, height: 900 }, false);
  await runViewport("mobile", { width: 390, height: 844 }, true);
} finally {
  await browser.close();
}

if (failures.length > 0) {
  console.error("Project preview visual smoke failed:\n" + failures.map((failure) => `- ${failure}`).join("\n"));
  process.exit(1);
}

console.log("Project preview Playwright smoke passed for 1440x900 and 390x844.");

async function runViewport(label, viewport, mobile) {
  const context = await browser.newContext({
    viewport,
    deviceScaleFactor: mobile ? 2 : 1,
    hasTouch: mobile,
    isMobile: mobile,
    reducedMotion: mobile ? "reduce" : "no-preference"
  });
  const page = await context.newPage();
  const diagnostics = collectDiagnostics(page, label);

  try {
    await page.goto(`${baseUrl}/project-preview.html`, { waitUntil: "networkidle", timeout: 30_000 });
    await page.getByRole("heading", { name: "仓库预览与四人协作门户" }).waitFor({ state: "visible" });
    await verifyNoHorizontalOverflow(page, label);

    const launchCards = page.locator(".launch-card");
    if (await launchCards.count() !== 4) failures.push(`${label} expected 4 launch cards`);
    const lanes = page.locator(".lane-card");
    if (await lanes.count() !== 4) failures.push(`${label} expected 4 ownership lanes`);
    const versionCards = page.locator(".version-grid article");
    if (await versionCards.count() !== 4) failures.push(`${label} expected 4 version cards`);

    await waitForLinkProbe(page);
    const missingLinks = await page.locator('.launch-card i[data-state="missing"]').count();
    if (missingLinks > 0) failures.push(`${label} has ${missingLinks} unavailable preview links`);

    const search = page.getByPlaceholder("输入 Godot、存档、测试…");
    await search.fill("Godot");
    const filteredRows = page.locator(".structure-row");
    const filteredCount = await filteredRows.count();
    if (filteredCount < 1 || filteredCount > 3) failures.push(`${label} Godot filter returned ${filteredCount} rows`);
    await search.fill("");
    if (await page.locator(".structure-row").count() !== 9) failures.push(`${label} structure list did not restore 9 rows`);

    await page.getByRole("button", { name: "四人分工" }).click();
    await page.getByRole("heading", { name: "四人并行开发通道" }).waitFor({ state: "visible" });
    await page.getByRole("button", { name: "PR 流程" }).click();
    await page.getByRole("heading", { name: "分支、拉取与合并方式" }).waitFor({ state: "visible" });

    const commandCards = page.locator(".command-grid article");
    if (await commandCards.count() !== 4) failures.push(`${label} expected 4 command cards`);
    await page.getByRole("button", { name: "复制" }).first().click();

    await verifyNoElementOverlap(page.locator(".preview-hero"), page.locator(".preview-section").first(), `${label} hero and first section`);
    await verifyGridChildrenDoNotOverlap(launchCards, `${label} launch cards`);
    await verifyGridChildrenDoNotOverlap(lanes, `${label} ownership lanes`);
    await verifyNoHorizontalOverflow(page, `${label} after interactions`);

    const screenshotPath = resolve(outputDirectory, `${label}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    const screenshot = await stat(screenshotPath);
    if (screenshot.size < 40_000) failures.push(`${label} screenshot is suspiciously small: ${screenshot.size}`);
  } catch (error) {
    failures.push(`${label}: ${formatError(error)}`);
  } finally {
    failures.push(...diagnostics());
    await context.close();
  }
}

async function waitForLinkProbe(page) {
  const deadline = Date.now() + 8_000;
  while (Date.now() < deadline) {
    const checking = await page.locator('.launch-card i[data-state="checking"]').count();
    if (checking === 0) return;
    await page.waitForTimeout(100);
  }
  failures.push("preview link availability checks did not finish");
}

async function verifyNoHorizontalOverflow(page, label) {
  const dimensions = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    bodyScrollWidth: document.body.scrollWidth
  }));
  const widest = Math.max(dimensions.scrollWidth, dimensions.bodyScrollWidth);
  if (widest > dimensions.clientWidth + 1) {
    failures.push(`${label} horizontal overflow ${widest} > ${dimensions.clientWidth}`);
  }
}

async function verifyNoElementOverlap(first, second, label) {
  const [a, b] = await Promise.all([first.boundingBox(), second.boundingBox()]);
  if (!a || !b) {
    failures.push(`${label} lacks visible bounds`);
    return;
  }
  const overlapX = Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x);
  const overlapY = Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y);
  if (overlapX > 1 && overlapY > 1) failures.push(`${label} overlap detected`);
}

async function verifyGridChildrenDoNotOverlap(locator, label) {
  const boxes = [];
  for (let index = 0; index < await locator.count(); index += 1) {
    const box = await locator.nth(index).boundingBox();
    if (box) boxes.push(box);
  }
  for (let i = 0; i < boxes.length; i += 1) {
    for (let j = i + 1; j < boxes.length; j += 1) {
      const a = boxes[i];
      const b = boxes[j];
      const overlapX = Math.min(a.x + a.width, b.x + b.width) - Math.max(a.x, b.x);
      const overlapY = Math.min(a.y + a.height, b.y + b.height) - Math.max(a.y, b.y);
      if (overlapX > 1 && overlapY > 1) {
        failures.push(`${label} items ${i + 1} and ${j + 1} overlap`);
        return;
      }
    }
  }
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
  throw new Error(`project preview server did not become ready: ${lastError}`);
}

function formatError(error) {
  return error instanceof Error ? error.stack ?? error.message : String(error);
}
