import { mkdir, rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const outputDirectory = resolve(process.cwd(), "public/godot");
await rm(outputDirectory, { recursive: true, force: true });
await mkdir(outputDirectory, { recursive: true });

const result = spawnSync(process.execPath, [
  "scripts/run-godot.mjs",
  "--headless",
  "--path",
  "godot",
  "--export-release",
  "Web",
  "../public/godot/index.html"
], {
  cwd: process.cwd(),
  env: process.env,
  stdio: "inherit"
});

if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);
