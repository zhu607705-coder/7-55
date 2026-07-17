import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(fileURLToPath(import.meta.url));
const plan = JSON.parse(readFileSync(join(root, "generation-plan.json"), "utf8"));
const matrixPath = join(root, "style-matrix.json");
const matrix = JSON.parse(readFileSync(matrixPath, "utf8"));

const audioStyles = {
  music: {
    classic_pixel: { labelZh: "像素脉冲", description: "compact 16-bit chiptune, square-wave pulse, crisp menu ticks, short loop, no vocals" },
    paper_ambient: { labelZh: "纸张环境", description: "quiet analog campus ambience, muted electric piano, brushed percussion, paper and clock textures, restrained mystery, no vocals" },
    rainy_glitch: { labelZh: "雨夜故障", description: "dark rainy CRT electronica, cyan glitch pulses, low sub bass, sparse radio noise, controlled tension, no vocals" }
  },
  voice: {
    baseline: { labelZh: "基准演绎", description: "clear English game dialogue, natural pauses, preserve the assigned character role" },
    low_deadpan: { labelZh: "低沉克制", description: "slower delivery, dry deadpan pauses, understated irony, never theatrical" },
    clipped_comic: { labelZh: "短促冷幽默", description: "slightly brisk delivery, clipped phrases, restrained comic timing, never excited" }
  },
  sfx: {
    clean_ui: { labelZh: "清晰界面", description: "clean dry pixel UI sound, short transient, readable confirmation, no melody" },
    paper_mechanical: { labelZh: "纸张机械", description: "paper texture, small mechanical click, warm room resonance, short and usable" },
    radio_glitch: { labelZh: "无线电故障", description: "narrow radio shimmer, low pulse, restrained digital glitch, short and usable" }
  }
};

function slug(path) {
  return path.split("/").pop().replace(/_candidate_a\.mp3$/, "");
}

function existing(path) {
  return existsSync(join(root, path));
}

function audioPath(kind, style, id) {
  return `audio/styles/${kind}/${style}/${id}__${style}.mp3`;
}

function makeEntry(kind, entry) {
  const [path, second, third] = entry;
  const role = kind === "voice" ? second : undefined;
  const prompt = kind === "voice" ? third : second;
  const id = slug(path);
  const variants = {};
  const styleKeys = Object.keys(audioStyles[kind]);
  for (const style of styleKeys) {
    if (style === "classic_pixel" || style === "baseline" || style === "clean_ui") {
      variants[style] = {
        path,
        status: existing(path) ? "existing" : "missing",
        prompt,
        ...(role ? { voiceRole: role } : {})
      };
    } else {
      const stylePrompt = `${prompt}; ${audioStyles[kind][style].description}`;
      variants[style] = {
        path: audioPath(kind === "music" ? "music" : kind, style, id),
        prompt: stylePrompt,
        status: existing(audioPath(kind === "music" ? "music" : kind, style, id)) ? "existing" : "planned",
        ...(role ? { voiceRole: role } : {})
      };
    }
  }
  return { id, variants, sourcePath: path, sourcePrompt: prompt, ...(role ? { voiceRole: role } : {}) };
}

matrix.audioStyles = audioStyles;
matrix.audio = {
  music: plan.musicCandidates.map((entry) => makeEntry("music", entry)),
  voice: plan.voiceCandidates.map((entry) => makeEntry("voice", entry)),
  sfx: plan.sfxCandidates.map((entry) => makeEntry("sfx", entry))
};
matrix.generatedAt = new Date().toISOString();
writeFileSync(matrixPath, `${JSON.stringify(matrix, null, 2)}\n`);
process.stdout.write(`music=${matrix.audio.music.length} voice=${matrix.audio.voice.length} sfx=${matrix.audio.sfx.length}\n`);
