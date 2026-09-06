import { build } from "esbuild";
import { mkdtemp, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const entry = fileURLToPath(new URL("./verify-mode-order-flexibility.mjs", import.meta.url));
const tempDir = await mkdtemp(path.join(os.tmpdir(), "755-mode-order-"));
const outfile = path.join(tempDir, "verify-mode-order-flexibility.bundle.mjs");

try {
  await build({
    entryPoints: [entry],
    outfile,
    bundle: true,
    platform: "node",
    format: "esm",
    target: "node22",
    logLevel: "silent"
  });
  await import(pathToFileURL(outfile).href);
} finally {
  await rm(tempDir, { recursive: true, force: true });
}
