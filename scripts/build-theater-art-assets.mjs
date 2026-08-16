import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = resolve(repoRoot, "src/assets/rpg/theater/source");
const outputRoot = resolve(repoRoot, "src/assets/rpg/theater/generated");

const sources = {
  characters: "theater_characters_paper_source.png",
  facilities: "theater_facilities_props_source.png",
  effects: "theater_dark_spotlight_source.png",
  portraits: "theater_portraits_source.png"
};

const actor = (id, crop, fit = "88x120", source = "characters") => ({
  id,
  source,
  crop,
  fit,
  canvas: "96x128",
  gravity: "south",
  group: "actors"
});

const paper = (id, crop, fit = "56x56", source = "characters") => ({
  id,
  source,
  crop,
  fit,
  canvas: "64x64",
  gravity: "center",
  group: "paper"
});

const icon = (id, crop, fit = "54x54") => ({
  id,
  source: "facilities",
  crop,
  fit,
  canvas: "64x64",
  gravity: "center",
  group: "icons"
});

const effect = (id, crop, fit, canvas) => ({
  id,
  source: "effects",
  crop,
  fit,
  canvas,
  gravity: "center",
  group: "effects"
});

const assets = [
  actor("ticket_inspector_idle_front", "160x300+58+44"),
  actor("ticket_inspector_idle_left", "165x305+316+41"),
  actor("ticket_inspector_idle_right", "165x305+549+41"),
  actor("ticket_inspector_idle_back", "158x307+820+41"),
  actor("ticket_inspector_scan_front", "188x303+1028+48"),
  actor("ticket_inspector_scan_side", "217x306+1285+45"),
  actor("stage_manager_ghost_idle", "183x303+149+372"),
  actor("stage_manager_ghost_point", "260x302+454+373", "94x120"),
  actor("stage_manager_ghost_warn", "210x299+761+376"),
  actor("stage_manager_ghost_fade", "273x291+1074+378", "94x116"),

  paper("paper_flight_0", "93x110+31+716"),
  paper("paper_flight_1", "96x112+148+716"),
  paper("paper_flight_2", "97x113+277+714"),
  paper("paper_flight_3", "106x114+384+709"),
  paper("paper_flight_4", "91x116+521+713"),
  paper("paper_residual", "124x121+768+715", "60x56"),
  paper("paper_fluorescent", "127x122+1024+712", "58x56"),
  paper("paper_locked", "113x125+1155+715", "56x58"),
  paper("paper_reverse", "118x97+76+883"),
  paper("paper_cracked", "112x102+281+876"),
  paper("paper_escape", "172x96+1302+884", "62x48"),

  icon("item_theater_ticket_half_a", "88x105+36+793"),
  icon("item_theater_ticket_half_b", "90x105+136+793"),
  icon("item_temporary_theater_ticket", "191x103+256+795", "58x42"),
  icon("item_theater_program_opening", "105x154+482+771"),
  icon("item_theater_program_spotlight", "80x155+611+770"),
  icon("item_theater_program_finale", "133x157+701+771"),
  icon("item_spotlight_remote", "95x153+845+772"),
  icon("item_fluorescent_brush", "118x141+961+766"),
  icon("item_decoy_paper", "118x152+1092+774"),
  icon("item_wet_program", "136x160+1221+770"),

  effect("clue_ticket_hidden_mark", "179x148+42+122", "112x90", "128x96"),
  effect("clue_ticket_code_0832", "150x115+250+144", "128x78", "144x96"),
  effect("clue_program_back_1", "146x186+551+97", "70x90", "80x96"),
  effect("clue_program_back_2", "153x186+711+97", "74x90", "80x96"),
  effect("clue_program_back_3", "142x186+870+97", "70x90", "80x96"),
  effect("clue_prop_box_ghost", "223x159+1025+123", "122x84", "128x96"),
  effect("clue_paper_future_path", "250x180+1260+115", "154x104", "160x112"),
  effect("spotlight_beam", "180x240+210+380", "148x220", "160x224"),
  effect("spotlight_hit_ring", "230x220+690+390", "142x136", "160x144"),
  effect("spotlight_sparks", "220x270+1030+360", "132x164", "144x176"),
  effect("spotlight_fault_strip", "270x150+1230+420", "210x112", "224x128"),
  effect("paper_reversal_locked", "160x170+400+730", "58x60", "64x64"),
  effect("paper_reversal_cracked", "160x160+780+740", "58x58", "64x64"),
  effect("paper_reversal_fragments", "200x190+940+720", "74x62", "80x72"),
  effect("paper_reversal_escape", "210x170+1120+730", "72x58", "80x64"),
  effect("paper_reversal_decoy", "160x170+1340+740", "58x58", "64x64")
];

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function repoPath(path) {
  return relative(repoRoot, path).split("\\").join("/");
}

async function buildAsset(asset) {
  const sourcePath = resolve(sourceRoot, sources[asset.source]);
  const outputPath = resolve(outputRoot, asset.group, `${asset.id}.png`);
  const preserveAuthoredGreen = asset.group === "actors"
    || asset.id === "paper_fluorescent"
    || asset.id === "item_fluorescent_brush";
  const chromaExpression = preserveAuthoredGreen
    ? "(g>0.38 && g>r*1.45 && g>b*1.45)?0:u"
    : "(g>0.18 && g>r*1.22 && g>b*1.22)?0:u";
  await mkdir(dirname(outputPath), { recursive: true });
  await execFileAsync("magick", [
    sourcePath,
    "-crop", asset.crop,
    "+repage",
    "-alpha", "on",
    "-fx", chromaExpression,
    "-trim",
    "+repage",
    "-filter", "point",
    "-resize", asset.fit,
    "-gravity", asset.gravity,
    "-background", "none",
    "-extent", asset.canvas,
    outputPath
  ]);
  const bytes = await readFile(outputPath);
  const { stdout: channels } = await execFileAsync("magick", [
    outputPath,
    "-format", "%[channels]",
    "info:"
  ]);
  if (!channels.toLowerCase().includes("a")) {
    throw new Error(`${asset.id} was generated without an alpha channel.`);
  }
  return {
    id: asset.id,
    group: asset.group,
    source: repoPath(sourcePath),
    crop: asset.crop,
    fit: asset.fit,
    canvas: asset.canvas,
    output: repoPath(outputPath),
    bytes: bytes.byteLength,
    sha256: sha256(bytes)
  };
}

await mkdir(outputRoot, { recursive: true });
const manifestAssets = [];
for (const asset of assets) {
  manifestAssets.push(await buildAsset(asset));
}

const sourceHashes = {};
for (const [id, file] of Object.entries(sources)) {
  const bytes = await readFile(resolve(sourceRoot, file));
  sourceHashes[id] = { file: `src/assets/rpg/theater/source/${file}`, sha256: sha256(bytes) };
}

const manifest = {
  schemaVersion: 1,
  generatedAt: "deterministic",
  chromaKeyRule: "adaptive green removal; actor and fluorescent assets preserve authored green details",
  sources: sourceHashes,
  assets: manifestAssets
};
await writeFile(
  resolve(outputRoot, "theater_art_manifest.json"),
  `${JSON.stringify(manifest, null, 2)}\n`
);

console.log(`built theater art assets=${manifestAssets.length}`);
