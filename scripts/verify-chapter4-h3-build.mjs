import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadConfigFromFile, normalizePath } from "vite";

const ROOT = fileURLToPath(new URL("../", import.meta.url));
const SOURCE_PATH = normalizePath(path.resolve(
  ROOT,
  "src/assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.mp4"
));
const QUERY = "chapter4-h3-embedded";
const CHUNK_SIZE = 256 * 1024;
const MIME_TYPE = "video/mp4; codecs=\"avc1.640028\"";

// Inspect the loaded config and exercise its real hook. Unrelated properties
// such as a deployment base must not invalidate the H3 media contract.
export async function validateChapter4H3Build() {
  const previousBase = process.env.VITE_BASE_PATH;
  try {
    for (const [mode, command, base] of [
      ["development", "serve", undefined],
      ["production", "build", "/7-55/"],
      ["demo", "build", "/7-55/"],
      ["campus-demo", "build", "/7-55/"]
    ]) {
      if (base === undefined) delete process.env.VITE_BASE_PATH;
      else process.env.VITE_BASE_PATH = base;
      const loaded = await loadConfigFromFile({ command, mode }, path.join(ROOT, "vite.config.ts"));
      assert(loaded, `${mode}: Vite config must load`);
      const plugins = loaded.config.plugins.flat(Infinity).filter(Boolean);
      const embeddedPlugins = plugins.filter((plugin) => plugin.name === "embed-chapter4-h3-as-chunks");
      const singleFile = mode === "demo" || mode === "campus-demo";
      assert.equal(loaded.config.base, singleFile ? "./" : base ?? "/", `${mode}: deployment base`);
      assert.equal(embeddedPlugins.length, singleFile ? 1 : 0, `${mode}: only offline builds embed H3`);
      assert.equal(plugins.some((plugin) => plugin.name === "vite:singlefile"), singleFile, `${mode}: single-file plugin`);
      if (!singleFile) continue;

      const plugin = embeddedPlugins[0];
      assert.equal(plugin.apply, "build", `${mode}: embedding must be build-only`);
      assert.equal(plugin.enforce, "pre", `${mode}: embedding must precede Vite asset handling`);
      assert(plugins.indexOf(plugin) < plugins.findIndex((entry) => entry.name === "vite:singlefile"));
      const load = typeof plugin.load === "function" ? plugin.load : plugin.load?.handler;
      assert.equal(typeof load, "function", `${mode}: embedding needs a load hook`);
      const watched = [];
      const context = {
        addWatchFile(file) { watched.push(file); },
        error(message) { throw new Error(message); }
      };
      for (const id of [SOURCE_PATH, `${SOURCE_PATH}?url`, `${SOURCE_PATH}?not-${QUERY}`]) {
        assert.equal(await load.call(context, id), null, `${mode}: unrelated imports stay with Vite`);
      }
      await assert.rejects(async () => load.call(context, `${ROOT}unexpected.mp4?${QUERY}`), /Unexpected Chapter 4 H3 embedded source/);
      assert.deepEqual(watched, [], `${mode}: rejected imports cannot watch or read a different source`);
      const result = await load.call(context, `${SOURCE_PATH}?${QUERY}`);
      assert.deepEqual(watched, [SOURCE_PATH], `${mode}: approved source must be watched`);
      assert.equal(result.moduleSideEffects, false);
      assert.equal(result.map, null);
      assert.match(result.code, /^export default /);
      const source = JSON.parse(result.code.slice("export default ".length).replace(/;\s*$/, ""));
      assert.equal(source.kind, "embedded_chunks");
      assert.equal(source.mimeType, MIME_TYPE);
      assert(Array.isArray(source.chunks) && source.chunks.length > 1);
      const bytes = fs.readFileSync(SOURCE_PATH);
      assert.equal(source.chunks.length, Math.ceil(bytes.toString("base64").length / CHUNK_SIZE));
      const decoded = source.chunks.map((chunk, index) => {
        assert.equal(typeof chunk, "string");
        assert(chunk.length > 0 && chunk.length <= CHUNK_SIZE);
        assert.equal(chunk.length % 4, 0, `${mode}: each chunk must decode independently`);
        if (index < source.chunks.length - 1) assert.equal(chunk.length, CHUNK_SIZE);
        const part = Buffer.from(chunk, "base64");
        assert.equal(part.toString("base64"), chunk, `${mode}: valid independent base64`);
        return part;
      });
      assert.deepEqual(Buffer.concat(decoded), bytes, `${mode}: chunks must preserve every approved MP4 byte`);
    }
  } finally {
    if (previousBase === undefined) delete process.env.VITE_BASE_PATH;
    else process.env.VITE_BASE_PATH = previousBase;
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await validateChapter4H3Build();
  console.log("Chapter 4 H3 build contract PASS: dev/production URLs, both offline modes, exact query/path isolation and independent 256KiB base64 chunks.");
}
