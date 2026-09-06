import assert from "node:assert/strict";
const { chromium, firefox, webkit } = await import(process.env.PLAYWRIGHT_MODULE || "playwright");

const engine = process.env.QIZHEN_ENGINE ?? "chromium";
const browser = await ({ chromium, firefox, webkit }[engine]).launch({
  headless: true,
  ...(engine === "chromium" ? { channel: "chrome" } : {})
});
const page = await browser.newPage(
  engine === "webkit"
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1063, height: 739 } }
);
const errors = [];
page.on("pageerror", (error) => errors.push(error.message));

try {
  await page.goto(`${process.env.BASE_URL ?? "http://127.0.0.1:4183"}/?devCheckpoint=c3-qizhen-paper`);
  await page.waitForFunction(() => window.__game?.rpg?.scene.getScene("qizhen-lake")?.player, null, { timeout: 60000 });
  await page.waitForTimeout(1200);
  const state = await page.evaluate(() => __game.store.getState());
  for (const itemId of ["nylonCord", "brokenNetFrame", "swanMagnet", "fishingRod"]) {
    assert.equal(state.items[itemId], true, `${itemId} must remain available before final assembly`);
  }
  assert.equal(state.items.magneticFishingRod, false, "paper checkpoint must wait for final assembly");
  const assemble = page.getByRole("button", { name: "组合四件材料", exact: true });
  await assemble.waitFor({ timeout: 5000 });
  await page.screenshot({ path: `/tmp/qizhen-inventory-combine-${engine}-before.png` });
  await assemble.click();
  await page.waitForFunction(() => {
    const next = __game.store.getState();
    return next.items.magneticFishingRod
      && !next.items.nylonCord
      && !next.items.brokenNetFrame
      && !next.items.swanMagnet
      && !next.items.fishingRod
      && next.qizhenLake.magneticRodCombined;
  }, null, { timeout: 5000 });
  await page.screenshot({ path: `/tmp/qizhen-inventory-combine-${engine}-after.png` });
  await page.goto(`${process.env.BASE_URL ?? "http://127.0.0.1:4183"}/?devCheckpoint=c3-qizhen-swan`);
  await page.waitForFunction(() => window.__game?.rpg?.scene.getScene("qizhen-lake")?.player, null, { timeout: 60000 });
  await page.waitForTimeout(900);
  await page.evaluate(() => {
    __game.bus.emit("rpg_qizhen_swan_feed_requested", {
      itemId: "smallCarp",
      targetId: "qizhen_black_swan"
    });
  });
  await page.waitForFunction(() => {
    const next = __game.store.getState();
    return !next.items.smallCarp
      && next.items.fishingRod
      && next.items.swanMagnet
      && !next.items.magneticFishingRod
      && !next.qizhenLake.magneticRodCombined
      && next.qizhenLake.phase === "tool_chain";
  }, null, { timeout: 5000 });
  assert.deepEqual(errors, []);
  console.log(`Qizhen independent materials and final inventory assembly PASS engine=${engine}`);
} finally {
  await browser.close();
}
