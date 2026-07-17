import { existsSync, mkdirSync, readFileSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const matrixPath = join(root, "style-matrix.json");
const matrix = JSON.parse(readFileSync(matrixPath, "utf8"));
const model = process.env.MINIMAX_MUSIC_MODEL || "music-2.5+";
const concurrency = Number(process.env.MINIMAX_AUDIO_CONCURRENCY || 3);
const requested = new Set(process.argv.filter((arg) => arg.startsWith("--kind=")).map((arg) => arg.slice(7)));
const kinds = requested.size ? requested : new Set(["voice", "music", "sfx"]);
const force = process.argv.includes("--force");
const results = [];

function run(command, args, label) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd: root });
    let stdout = "";
    let stderr = "";
    child.stdout?.on("data", (chunk) => { stdout += chunk.toString(); });
    child.stderr?.on("data", (chunk) => { stderr += chunk.toString(); });
    child.on("error", (error) => reject(new Error(`${label}: ${error.message}`)));
    child.on("close", (code) => {
      if (code === 0) resolve(stdout);
      else reject(new Error(`${label}: exit ${code}; ${(stderr || stdout).trim().slice(-1800)}`));
    });
  });
}

function musicStylePrompt(entry, style) {
  return `${entry.sourcePrompt}; ${matrix.audioStyles.music[style].description}; keep the campus mystery tone and make it an instrumental game loop with no vocals`;
}

function sfxStylePrompt(entry, style) {
  return `${entry.sourcePrompt}; ${matrix.audioStyles.sfx[style].description}; keep the event recognizable and under two seconds`;
}

const jobs = [];
for (const entry of matrix.audio.voice) {
  for (const style of ["low_deadpan", "clipped_comic"]) {
    const variant = entry.variants[style];
    jobs.push({ kind: "voice", entry, style, variant });
  }
}
for (const entry of matrix.audio.music) {
  for (const style of ["classic_pixel", "paper_ambient", "rainy_glitch"]) {
    const variant = entry.variants[style];
    if (style === "classic_pixel" && variant.status === "existing" && !force) continue;
    if (style !== "classic_pixel" && variant.status === "existing" && !force) continue;
    jobs.push({ kind: "music", entry, style, variant });
  }
}
for (const entry of matrix.audio.sfx) {
  for (const style of ["clean_ui", "paper_mechanical", "radio_glitch"]) {
    const variant = entry.variants[style];
    if (style === "clean_ui" && variant.status === "existing" && !force) continue;
    if (style !== "clean_ui" && variant.status === "existing" && !force) continue;
    jobs.push({ kind: "sfx", entry, style, variant });
  }
}

function voiceArgs(entry, style, output) {
  const female = entry.voiceRole === "female_system";
  const settings = style === "low_deadpan"
    ? { speed: female ? "0.92" : "0.86", pitch: female ? "-2" : "-5" }
    : { speed: female ? "1.04" : "0.98", pitch: female ? "0" : "-3" };
  return [
    "speech", "synthesize", "--model", "speech-2.8-hd", "--voice",
    female ? "English_Graceful_Lady" : "English_expressive_narrator",
    "--text", entry.sourcePrompt, "--speed", settings.speed, "--pitch", settings.pitch,
    "--language", "en", "--format", "mp3", "--sample-rate", "32000", "--bitrate", "128000",
    "--channels", "1", "--out", output, "--timeout", "90", "--non-interactive", "--quiet"
  ];
}

async function generate(job) {
  const { kind, entry, style, variant } = job;
  const output = join(root, variant.path);
  if (!force && existsSync(output) && statSync(output).size > 0) {
    variant.status = "existing";
    return { kind, style, path: variant.path, status: "existing", bytes: statSync(output).size };
  }
  mkdirSync(dirname(output), { recursive: true });
  try {
    if (kind === "voice") {
      await run("mmx", voiceArgs(entry, style, output), `voice ${variant.path}`);
    } else {
      const prompt = kind === "music" ? musicStylePrompt(entry, style) : sfxStylePrompt(entry, style);
      const stem = kind === "sfx" ? `${output}.stem.mp3` : output;
      await run("mmx", ["music", "generate", "--model", model, "--prompt", prompt, "--instrumental", "--format", "mp3", "--out", stem, "--timeout", "180", "--non-interactive", "--quiet"], `${kind} ${variant.path}`);
      if (kind === "sfx") {
        await run("ffmpeg", ["-y", "-hide_banner", "-loglevel", "error", "-i", stem, "-t", "1.8", "-af", "afade=t=in:st=0:d=0.03,afade=t=out:st=1.62:d=0.18", "-ar", "44100", "-ac", "2", "-b:a", "192k", output], `cut ${variant.path}`);
        unlinkSync(stem);
      }
    }
    variant.status = "generated";
    return { kind, style, path: variant.path, status: "generated", bytes: statSync(output).size };
  } catch (error) {
    variant.status = "failed";
    variant.error = error instanceof Error ? error.message : String(error);
    return { kind, style, path: variant.path, status: "failed", error: variant.error };
  }
}

let cursor = 0;
async function worker() {
  while (cursor < jobs.length) {
    const job = jobs[cursor++];
    process.stdout.write(`[${job.kind}/${job.style}] ${job.variant.path}\n`);
    results.push(await generate(job));
  }
}

const filteredJobs = jobs.filter((job) => kinds.has(job.kind));
jobs.length = 0;
jobs.push(...filteredJobs);
await Promise.all(Array.from({ length: Math.min(concurrency, jobs.length) }, () => worker()));

matrix.generatedAt = new Date().toISOString();
writeFileSync(matrixPath, `${JSON.stringify(matrix, null, 2)}\n`);
writeFileSync(join(root, "reports/style-audio-manifest.json"), `${JSON.stringify({ generatedAt: matrix.generatedAt, model, concurrency, kinds: [...kinds], results }, null, 2)}\n`);
const counts = results.reduce((acc, item) => { acc[item.status] = (acc[item.status] || 0) + 1; return acc; }, {});
process.stdout.write(`completed ${results.length} audio variants ${JSON.stringify(counts)}\n`);
