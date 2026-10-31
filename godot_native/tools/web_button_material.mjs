import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
export const buttonMaterialSource = 'web/button.css';
const digest = source => crypto.createHash('sha256').update(source).digest('hex');
export function inlineButtonMaterial(project, output) {
  const source = fs.readFileSync(path.join(project, buttonMaterialSource), 'utf8');
  if (/<\/style[\s/>]/i.test(source)) throw Error('Unsafe button stylesheet terminator');
  const file = path.join(output, 'index.html');
  const html = fs.readFileSync(file, 'utf8');
  const tag = '<link rel="stylesheet" href="button.css">';
  if (html.split(tag).length !== 2) throw Error('Expected one button material link');
  fs.writeFileSync(file, html.replace(tag, () => `<style id="button-material" data-source-sha256="${digest(source)}">${source}</style>`));
}
export function verifyButtonMaterial(project, html) {
  const source = fs.readFileSync(path.join(project, buttonMaterialSource), 'utf8');
  const matches = [...html.matchAll(/<style id="button-material" data-source-sha256="([a-f0-9]{64})">([\s\S]*?)<\/style>/g)];
  if (matches.length !== 1 || matches[0][1] !== digest(source) || matches[0][2] !== source) throw Error('Button material differs from source');
  if (/href=["']button\.css/.test(html)) throw Error('Button material must be inline in export');
  return { mode: 'inline', source: buttonMaterialSource, sha256: digest(source) };
}
