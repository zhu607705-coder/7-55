import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const faces = [
  { weight: 400, style: 'Regular', placeholder: '__755_BOOT_FONT_REGULAR__' },
  { weight: 500, style: 'Medium', placeholder: '__755_BOOT_FONT_MEDIUM__' },
];
const licenses = ['ui_assets/fonts/MORNING_NOTE_OFL.txt', 'ui_assets/fonts/OFL.txt', 'assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt'];
export const bootTypographySources = [
  'ui_assets/fonts/morning_note_manifest.json', ...licenses,
  ...faces.flatMap(({ style }) => [`ui_assets/fonts/MorningNote-${style}.ttf`, `art_source/fonts/morning_note_v1/web/MorningNote-${style}.woff2`]),
];
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

export function planBootTypography(project) {
  const manifest = JSON.parse(fs.readFileSync(path.join(project, 'ui_assets/fonts/morning_note_manifest.json'), 'utf8'));
  if (manifest.family !== '755 Morning Note' || !manifest.version) throw new Error('Unexpected boot font family manifest');
  const assets = faces.map(({ weight, style, placeholder }) => {
    const source = `art_source/fonts/morning_note_v1/web/MorningNote-${style}.woff2`;
    const bytes = fs.readFileSync(path.join(project, source));
    const ttf = fs.readFileSync(path.join(project, `ui_assets/fonts/MorningNote-${style}.ttf`));
    const record = manifest.files.find(file => file.file === `MorningNote-${style}.ttf`);
    const sha256 = hash(bytes);
    if (bytes.toString('ascii', 0, 4) !== 'wOF2' || !record || record.weight !== weight || record.woff2Sha256 !== sha256 || record.woff2Bytes !== bytes.length || record.sha256 !== hash(ttf) || record.bytes !== ttf.length) throw new Error(`Boot ${style} font differs from its actual family manifest`);
    const file = `boot-fonts/MorningNote-${style}.${sha256}.woff2`;
    return { source, file, url: file, weight, placeholder, bytes: bytes.length, sha256 };
  });
  for (const source of licenses) {
    const bytes = fs.readFileSync(path.join(project, source));
    if (!bytes.toString('utf8').includes('SIL OPEN FONT LICENSE Version 1.1')) throw new Error('Boot font license is incomplete: ' + source);
    const file = `boot-fonts/${path.basename(source)}`;
    assets.push({ source, file, bytes: bytes.length, sha256: hash(bytes) });
  }
  return { family: manifest.family, version: manifest.version, loading: 'font-display:swap; no readiness dependency', assets };
}

export function installBootTypography(project, output) {
  const plan = planBootTypography(project);
  const filename = path.join(output, 'index.html');
  let html = fs.readFileSync(filename, 'utf8');
  for (const asset of plan.assets) {
    fs.mkdirSync(path.dirname(path.join(output, asset.file)), { recursive: true });
    fs.copyFileSync(path.join(project, asset.source), path.join(output, asset.file));
    if (asset.placeholder) {
      if (html.split(asset.placeholder).length !== 2) throw new Error('Expected one boot font placeholder: ' + asset.placeholder);
      html = html.replace(asset.placeholder, () => asset.url);
    }
  }
  fs.writeFileSync(filename, html);
  return plan;
}

export function verifyBootTypography(project, output, html) {
  const plan = planBootTypography(project);
  const directory = path.join(output, 'boot-fonts');
  const actual = fs.readdirSync(directory, { withFileTypes: true }).map(entry => {
    if (!entry.isFile() || entry.isSymbolicLink()) throw new Error('Unexpected boot font asset type: ' + entry.name);
    return 'boot-fonts/' + entry.name;
  }).sort();
  if (JSON.stringify(actual) !== JSON.stringify(plan.assets.map(asset => asset.file).sort())) throw new Error('Missing or unexpected boot font asset');
  for (const asset of plan.assets) {
    const bytes = fs.readFileSync(path.join(output, asset.file));
    if (bytes.length !== asset.bytes || hash(bytes) !== asset.sha256) throw new Error('Boot font asset differs from its exact source: ' + asset.file);
    if (asset.placeholder && (html.includes(asset.placeholder) || html.split(asset.url).length !== 2)) throw new Error('Boot font HTML reference differs from its exact content-hashed URL');
  }
  return plan;
}
