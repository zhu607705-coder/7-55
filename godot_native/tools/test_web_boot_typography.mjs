// Actual bundled font bytes and disposable exported files; no browser/gameplay claim.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { planBootTypography, installBootTypography, verifyBootTypography } from './web_boot_typography.mjs';

const project = path.resolve(import.meta.dirname, '..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-boot-font-test-'));
let checks = 0;
const check = (value, label) => { assert.ok(value, label); checks++; };
const reject = (fn, pattern) => { assert.throws(fn, pattern); checks++; };
try {
  const plan = planBootTypography(project);
  check(plan.family === '755 Morning Note' && plan.assets.filter(asset => asset.weight).length === 2, 'Actual regular/medium project faces have browser delivery');
  check(plan.assets.filter(asset => !asset.weight).map(asset => path.basename(asset.file)).sort().join(',') === 'FUSION_PIXEL_FONT_OFL.txt,MORNING_NOTE_OFL.txt,OFL.txt', 'Project, original Noto and original Fusion notices are present');
  const htmlFile = path.join(temporary, 'index.html');
  fs.copyFileSync(path.join(project, 'web/index.html'), htmlFile);
  installBootTypography(project, temporary);
  const html = fs.readFileSync(htmlFile, 'utf8');
  assert.deepEqual(verifyBootTypography(project, temporary, html), plan); checks++;
  for (const asset of plan.assets) {
    check(fs.readFileSync(path.join(temporary, asset.file)).equals(fs.readFileSync(path.join(project, asset.source))), 'Exported font/license bytes retain source identity: ' + asset.file);
  }
  const font = plan.assets.find(asset => asset.weight === 400), license = plan.assets.find(asset => !asset.weight);
  const fontPath = path.join(temporary, font.file), fontBytes = fs.readFileSync(fontPath);
  fs.writeFileSync(fontPath, Buffer.concat([fontBytes, Buffer.from('modified')]));
  reject(() => verifyBootTypography(project, temporary, html), /differs from its exact source/);
  fs.writeFileSync(fontPath, fontBytes);
  const licensePath = path.join(temporary, license.file), licenseBytes = fs.readFileSync(licensePath);
  fs.writeFileSync(licensePath, 'SIL license heading without original notices');
  reject(() => verifyBootTypography(project, temporary, html), /differs from its exact source/);
  fs.writeFileSync(licensePath, licenseBytes);
  reject(() => verifyBootTypography(project, temporary, html.replace(font.url, 'https://example.invalid/font.woff2')), /HTML reference differs/);
  const extra = path.join(temporary, 'boot-fonts/unused.woff2');
  fs.writeFileSync(extra, 'not a font');
  reject(() => verifyBootTypography(project, temporary, html), /Missing or unexpected/);
  fs.unlinkSync(extra);
  fs.unlinkSync(fontPath);
  reject(() => verifyBootTypography(project, temporary, html), /Missing or unexpected/);
  fs.writeFileSync(fontPath, fontBytes);
  check(html.includes('font-display: swap') && html.includes('font-synthesis: none'), 'Browser displays fallback while the real pixel face loads and cannot synthesize a weight');
  check(!/document\.fonts|FontFace\s*\(/.test(html), 'Actual shell has no font-readiness API or scripted font dependency');
  check(html.includes('<h1 class="boot-title">7:55</h1>') && !html.includes('id="boot-digit-five"'), 'Opening time is text from the accepted numeral design');
  console.log(JSON.stringify({ passed: true, checks, fontBytes: plan.assets.filter(asset => asset.weight).reduce((sum, asset) => sum + asset.bytes, 0), licenseBytes: plan.assets.filter(asset => !asset.weight).reduce((sum, asset) => sum + asset.bytes, 0), scope: 'Actual local font/license copy, provenance and corruption controls; browser layout and font-network failure remain actual-browser checks.' }));
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
