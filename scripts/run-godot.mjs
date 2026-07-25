import { access } from "node:fs/promises";
import { constants } from "node:fs";
import { spawnSync } from "node:child_process";

const requestedArgs = process.argv.slice(2);
if (requestedArgs.length === 0) {
  console.error("Usage: node scripts/run-godot.mjs <godot arguments...>");
  process.exit(2);
}

const candidates = [
  process.env.GODOT_BIN,
  process.platform === "darwin" ? "/Applications/Godot.app/Contents/MacOS/Godot" : null,
  process.platform === "darwin" ? `${process.env.HOME ?? ""}/Applications/Godot.app/Contents/MacOS/Godot` : null,
  process.platform === "win32" ? "Godot_v4.7.1-stable_win64.exe" : null,
  "godot4",
  "godot"
].filter(Boolean);

let selected = null;
for (const candidate of candidates) {
  const pathLike = candidate.includes("/") || candidate.includes("\\");
  if (pathLike) {
    try {
      await access(candidate, constants.X_OK);
    } catch {
      continue;
    }
  }
  const probe = spawnSync(candidate, ["--version"], {
    encoding: "utf8",
    shell: false,
    stdio: ["ignore", "pipe", "pipe"]
  });
  if (probe.status === 0) {
    selected = candidate;
    const version = (probe.stdout || probe.stderr).trim().split(/\r?\n/, 1)[0];
    console.log(`using Godot binary=${candidate} version=${version}`);
    break;
  }
}

if (!selected) {
  console.error([
    "Godot 4.7.1 was not found.",
    "Install Godot on macOS in /Applications/Godot.app, add godot4/godot to PATH,",
    "or set GODOT_BIN to the executable path."
  ].join("\n"));
  process.exit(1);
}

const result = spawnSync(selected, requestedArgs, {
  cwd: process.cwd(),
  env: process.env,
  stdio: "inherit",
  shell: false
});

if (result.error) {
  console.error(result.error);
  process.exit(1);
}
process.exit(result.status ?? 1);
