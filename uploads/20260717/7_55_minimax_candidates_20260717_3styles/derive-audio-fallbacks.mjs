import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const matrixPath = join(root, "style-matrix.json");
const matrix = JSON.parse(readFileSync(matrixPath, "utf8"));
const results = [];

function run(args, label) {
  return new Promise((resolve, reject) => {
    const child = spawn("ffmpeg", ["-y", "-hide_banner", "-loglevel", "error", ...args], { cwd: root });
    let stderr = "";
    child.stderr?.on("data", (chunk) => { stderr += chunk.toString(); });
    child.on("error", (error) => reject(new Error(`${label}: ${error.message}`)));
    child.on("close", (code) => code === 0 ? resolve() : reject(new Error(`${label}: exit ${code}; ${stderr.trim()}`)));
  });
}

function absolute(path) { return join(root, path); }
function has(path) { return existsSync(absolute(path)) && statSync(absolute(path)).size > 0; }
function remember(variant, result) {
  variant.status = result.status;
  if (result.derivedFrom) variant.derivedFrom = result.derivedFrom;
  if (result.note) variant.note = result.note;
  results.push(result);
}

async function deriveVoice(entry, style, variant) {
  if (has(variant.path)) { if (!variant.derivedFrom) variant.status = "existing"; return; }
  const source = has(entry.sourcePath) ? entry.sourcePath : null;
  if (!source) { remember(variant, { kind: "voice", style, path: variant.path, status: "failed", error: "no voice source" }); return; }
  mkdirSync(dirname(absolute(variant.path)), { recursive: true });
  const filter = style === "low_deadpan"
    ? "atempo=0.88,volume=0.96,acompressor=threshold=-18dB:ratio=2:attack=20:release=120"
    : "atempo=1.06,volume=0.98,highpass=f=90,acompressor=threshold=-18dB:ratio=2:attack=8:release=80";
  try {
    await run(["-i", absolute(source), "-filter:a", filter, "-ar", "32000", "-ac", "1", "-b:a", "128k", absolute(variant.path)], `voice ${variant.path}`);
    remember(variant, { kind: "voice", style, path: variant.path, status: "derived", derivedFrom: source, note: "MiniMax 频控后使用同角色基准音频做速度与动态处理" });
  } catch (error) {
    remember(variant, { kind: "voice", style, path: variant.path, status: "failed", error: String(error) });
  }
}

const fallbackSfx = "audio/sfx/fx_catalog_match_candidate_a.mp3";
async function deriveSfx(entry, style, variant) {
  if (has(variant.path)) { if (!variant.derivedFrom) variant.status = "existing"; return; }
  const source = has(entry.sourcePath) ? entry.sourcePath : fallbackSfx;
  if (!has(source)) { remember(variant, { kind: "sfx", style, path: variant.path, status: "failed", error: "no sfx source" }); return; }
  mkdirSync(dirname(absolute(variant.path)), { recursive: true });
  const filter = style === "paper_mechanical"
    ? "aformat=sample_rates=44100,highpass=f=180,lowpass=f=6800,acompressor=threshold=-20dB:ratio=3:attack=5:release=80,afade=t=in:st=0:d=0.03,afade=t=out:st=1.62:d=0.18"
    : "aformat=sample_rates=44100,highpass=f=500,lowpass=f=5200,aecho=0.8:0.88:35:0.2,volume=0.82,afade=t=in:st=0:d=0.03,afade=t=out:st=1.62:d=0.18";
  try {
    await run(["-i", absolute(source), "-t", "1.8", "-filter:a", filter, "-ar", "44100", "-ac", "2", "-b:a", "192k", absolute(variant.path)], `sfx ${variant.path}`);
    remember(variant, { kind: "sfx", style, path: variant.path, status: "derived", derivedFrom: source, note: source === fallbackSfx ? "022 信号缺少新生成额度，使用目录检索确认音做无线电滤波变体" : "MiniMax 用量上限后使用成功音效做滤波变体" });
  } catch (error) {
    remember(variant, { kind: "sfx", style, path: variant.path, status: "failed", error: String(error) });
  }
}

for (const entry of matrix.audio.voice) {
  for (const style of ["low_deadpan", "clipped_comic"]) await deriveVoice(entry, style, entry.variants[style]);
}
for (const entry of matrix.audio.sfx) {
  for (const style of ["clean_ui", "paper_mechanical", "radio_glitch"]) await deriveSfx(entry, style, entry.variants[style]);
}

matrix.generatedAt = new Date().toISOString();
writeFileSync(matrixPath, `${JSON.stringify(matrix, null, 2)}\n`);
const derived = [];
for (const [kind, entries] of Object.entries(matrix.audio)) {
  for (const entry of entries) {
    for (const [style, variant] of Object.entries(entry.variants)) {
      if (variant.derivedFrom) {
        variant.status = "derived";
        derived.push({ kind, style, path: variant.path, status: "derived", derivedFrom: variant.derivedFrom, note: variant.note });
      }
    }
  }
}
writeFileSync(join(root, "reports/style-audio-derived-manifest.json"), `${JSON.stringify({ generatedAt: matrix.generatedAt, results: derived }, null, 2)}\n`);
const counts = derived.reduce((acc, item) => { acc[item.status] = (acc[item.status] || 0) + 1; return acc; }, {});
process.stdout.write(`derived audio ${JSON.stringify(counts)}\n`);
