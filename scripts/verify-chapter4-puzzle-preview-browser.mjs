import assert from "node:assert/strict";
import { mkdir } from "node:fs/promises";
const { chromium, firefox, webkit } = await import(process.env.PLAYWRIGHT_MODULE || "playwright");
const engine = process.env.PREVIEW_ENGINE || "chromium";
const mobile = process.argv.includes("--mobile");
const output = process.env.PREVIEW_OUTPUT || "/tmp/755-puzzle-preview";
await mkdir(output, { recursive: true });
const browser = await ({ chromium, firefox, webkit }[engine]).launch({ headless: true, ...(engine === "chromium" ? { channel: "chrome" } : {}) });
const page = await browser.newPage(mobile ? { viewport: { width: 390, height: 844 }, isMobile: engine !== "firefox", hasTouch: true } : { viewport: { width: 1063, height: 739 } });
const errors = [];
page.on("pageerror", error => errors.push(error.message));
const dialog = page.locator(".chapter4-inserted-puzzle");
const preview = page.locator(".puzzle-preview");
async function open(puzzleId, extra = {}) {
  // Exercise the real Host/React overlay through its presentation event. This does
  // not assert world reachability; no checkpoint facts or controller answers are forged.
  await page.evaluate(async ({ puzzleId, extra }) => {
    const { CHAPTER_FOUR_INSERTED_PUZZLES } = await import("/src/modules/ChapterFourInsertedPuzzleModel.ts");
    __game.bus.emit("chapter4_inserted_puzzle_requested", { puzzleId, targetId: CHAPTER_FOUR_INSERTED_PUZZLES[puzzleId].targetId, mode: "light", prerequisiteReady: true, completed: false, ...extra });
  }, { puzzleId, extra });
  await dialog.waitFor();
}
async function close() { await dialog.getByRole("button", { name: "返回现场", exact: true }).first().click(); await dialog.waitFor({ state: "detached" }); }
async function click(name, times = 1) {
  for (let i = 0; i < times; i++) await dialog.getByRole("button", { name, exact: true }).click();
  await page.waitForTimeout(50);
  await page.waitForFunction(() => !document.querySelector(".puzzle-preview").getAnimations({ subtree: true }).some(animation => animation.playState === "running"));
}
async function matrix(part) { return page.locator(`[data-preview-part="${part}"]`).evaluate(el => { const m = new DOMMatrix(getComputedStyle(el).transform); return [m.a, m.b, m.c, m.d, m.e, m.f].map(n => Math.round(n * 1000) / 1000); }); }
async function shot(name) { await page.screenshot({ path: `${output}/${engine}-${mobile ? "mobile" : "desktop"}-${name}.png` }); }
async function layout() {
  const dimensions = await page.evaluate(() => {
    const shell = document.querySelector(".rpg-shell").getBoundingClientRect();
    const p = document.querySelector(".chapter4-inserted-puzzle").getBoundingClientRect();
    const svg = document.querySelector(".puzzle-preview svg").getBoundingClientRect();
    const clip = document.querySelector(".chapter4-inserted-puzzle__asset").getBoundingClientRect();
    return { shell: { x: shell.x, y: shell.y, right: shell.right, bottom: shell.bottom }, panel: { x: p.x, y: p.y, right: p.right, bottom: p.bottom }, svg: { width: svg.width, height: svg.height }, clip: { height: clip.height }, overflow: document.documentElement.scrollWidth > innerWidth };
  });
  assert(!dimensions.overflow, "document overflow");
  assert(dimensions.panel.x >= dimensions.shell.x - 1 && dimensions.panel.right <= dimensions.shell.right + 1, JSON.stringify(dimensions));
  assert(dimensions.panel.y >= dimensions.shell.y - 1 && dimensions.panel.bottom <= dimensions.shell.bottom + 1, JSON.stringify(dimensions));
  console.log("LAYOUT", JSON.stringify(dimensions));
}
try {
  await page.goto(`${process.env.BASE_URL || "http://127.0.0.1:4183"}/?devCheckpoint=c4-755-a2-field-records`);
  await page.waitForFunction(() => window.__game?.rpg?.scene.getScene("chapter-four-temporal-maze")?.player, null, { timeout: 60000 });
  await page.waitForTimeout(1600);
  const facts = await page.evaluate(() => JSON.stringify(__game.store.getState().chapter4.factIds));
  await open("media_alignment");
  assert.deepEqual(await matrix("film-position"), [1, 0, 0, 1, 0, 0]);
  await click("水平向右1格", 2); await click("垂直向上1格");
  await click("旋转顺时针90°");
  assert.deepEqual(await matrix("film-position"), [1, 0, 0, 1, 40, -20]);
  assert.deepEqual(await matrix("film-rotation"), [0, 1, -1, 0, 0, 0]);
  await layout(); await shot("film");
  await click("旋转顺时针90°", 2);
  assert.deepEqual(await matrix("film-rotation"), [0, -1, 1, 0, 0, 0]);
  assert(await dialog.getByRole("button", { name: "旋转顺时针90°", exact: true }).isDisabled());
  await click("旋转逆时针90°", 3);
  assert.deepEqual(await matrix("film-rotation"), [1, 0, 0, 1, 0, 0]);
  await close();
  await open("positioning_calibration");
  await click("横向向左1格", 2); await click("纵向向下1格"); await click("压力压下1档", 3);
  assert.deepEqual(await matrix("calibration-stage"), [1, 0, 0, 1, -32, 16]);
  assert.deepEqual(await matrix("calibration-press"), [1, 0, 0, 1, 0, 69]);
  await shot("calibration"); await click("压力抬起1档");
  assert.deepEqual(await matrix("calibration-press"), [1, 0, 0, 1, 0, 46]); await close();
  await open("power_topology");
  await click("大厅 — 西侧走廊");
  assert.equal(await page.locator('[data-preview-edge][data-connected="true"]').count(), 1);
  await click("大厅 — 西侧走廊"); assert.equal(await page.locator('[data-preview-edge][data-connected="true"]').count(), 0);
  for (const name of ["大厅 — 西侧走廊", "大厅 — 东侧走廊", "西侧走廊 — 后区", "东侧走廊 — 教室区", "后区 — 教室区"]) await click(name);
  assert.equal(await page.locator('[data-preview-edge][data-connected="true"]').count(), 5);
  await shot("wires"); await close();
  await open("archive_index");
  for (const [index, value] of ["1991_1998", "A3", "wayfinding"].entries()) await dialog.locator("select").nth(index).selectOption(value);
  assert.match(await preview.textContent(), /1991–1998/); assert.match(await preview.textContent(), /入口导视/);
  await close();
  for (const [id, name, part, offset] of [["duty_board", "主电梯下移", "main_elevator", 74], ["evacuation_route", "交通核心下移", "transport_core", 58]]) {
    await open(id); await click(name);
    const value = await page.locator(`[data-preview-order="${part}"]`).evaluate(el => new DOMMatrix(getComputedStyle(el).transform).f);
    assert.equal(value, offset); await close();
  }
  for (const extra of [{ mode: "dark" }, { prerequisiteReady: false }, { completed: true }]) {
    await open("media_alignment", extra); assert.equal(await preview.count(), 0); await close();
  }
  assert.equal(await page.evaluate(() => JSON.stringify(__game.store.getState().chapter4.factIds)), facts, "adjustments alone never write progression");
  await page.goto(`${process.env.BASE_URL || "http://127.0.0.1:4183"}/?devCheckpoint=c4-755-maintenance-2245`);
  await page.waitForFunction(() => window.__game?.rpg?.scene.getScene("chapter-four-temporal-maze")?.player, null, { timeout: 60000 });
  await page.waitForTimeout(1600);
  await page.evaluate(() => __game.bus.emit("chapter4_maintenance_diagnosis_requested", {}));
  const maintenance = page.locator(".chapter4-maintenance-diagnosis");
  await maintenance.waitFor({ timeout: 5000 });
  await maintenance.locator("select").nth(1).selectOption("gear_offset");
  assert.equal(await page.locator(".maintenance-preview").getAttribute("data-symptom"), "clock_jam");
  assert.match(await page.locator(".maintenance-preview output").textContent(), /齿轮偏位/);
  await shot("maintenance");
  await maintenance.locator("select").nth(2).selectOption("oil_shortage");
  assert.equal(await page.locator(".maintenance-preview").getAttribute("data-symptom"), "oil_trace");
  assert.deepEqual(errors, []);
  console.log("PASS six actual Host previews, axis direction/rotation/ranges, choices, dark/locked/completed boundaries, maintenance diagnosis and no story writes", engine, mobile);
} catch (error) { await shot("failure"); throw error; }
finally { await browser.close(); }
