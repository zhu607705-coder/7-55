import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";
import { defineConfig, normalizePath, type Plugin } from "vite";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { losslessRuntimeAssets } from "./scripts/lossless-runtime-assets";

const BROWSER_BUILD_TARGET = ["chrome90", "edge90", "firefox91", "safari15"];
const CHAPTER4_H3_EMBEDDED_QUERY = "chapter4-h3-embedded";
const CHAPTER4_H3_BASE64_CHUNK_SIZE = 256 * 1024;
const CHAPTER4_H3_SOURCE_PATH = normalizePath(resolve(
  import.meta.dirname,
  "src/assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.mp4"
));

function embedChapter4H3AsChunks(): Plugin {
  return {
    name: "embed-chapter4-h3-as-chunks",
    apply: "build",
    enforce: "pre",
    load(id) {
      const queryIndex = id.indexOf("?");
      if (queryIndex < 0) return null;
      const filePath = normalizePath(id.slice(0, queryIndex));
      const query = new URLSearchParams(id.slice(queryIndex + 1));
      if (!query.has(CHAPTER4_H3_EMBEDDED_QUERY)) return null;
      if (filePath !== CHAPTER4_H3_SOURCE_PATH) {
        this.error(`Unexpected Chapter 4 H3 embedded source: ${filePath}`);
      }
      this.addWatchFile(filePath);

      const base64 = readFileSync(filePath).toString("base64");
      const chunks: string[] = [];
      for (let offset = 0; offset < base64.length; offset += CHAPTER4_H3_BASE64_CHUNK_SIZE) {
        chunks.push(base64.slice(offset, offset + CHAPTER4_H3_BASE64_CHUNK_SIZE));
      }
      if (chunks.length === 0) {
        this.error(`Chapter 4 H3 source is empty: ${filePath}`);
      }
      return {
        code: `export default ${JSON.stringify({
          kind: "embedded_chunks",
          mimeType: "video/mp4; codecs=\"avc1.640028\"",
          chunks
        })};`,
        map: null,
        moduleSideEffects: false
      };
    }
  };
}

function moveSingleFileRuntimeAfterShell(): Plugin {
  return {
    name: "move-single-file-runtime-after-shell",
    enforce: "post",
    generateBundle(_options, bundle) {
      Object.values(bundle).forEach((asset) => {
        if (asset.type !== "asset" || !asset.fileName.endsWith(".html") || typeof asset.source !== "string") {
          return;
        }
        const html = asset.source;
        const scriptStart = html.indexOf("<script type=\"module\"");
        const scriptClose = scriptStart >= 0 ? html.indexOf("</script>", scriptStart) : -1;
        const bodyClose = html.lastIndexOf("</body>");
        if (scriptStart < 0 || scriptClose < 0 || bodyClose < 0) {
          this.error("Single-file HTML does not contain the expected inline module and body.");
          return;
        }
        const scriptEnd = scriptClose + "</script>".length;
        const inlineRuntime = html.slice(scriptStart, scriptEnd);
        const withoutScript = html.slice(0, scriptStart) + html.slice(scriptEnd);
        const styleStart = withoutScript.indexOf("<style");
        const styleClose = styleStart >= 0 ? withoutScript.indexOf("</style>", styleStart) : -1;
        if (styleStart < 0 || styleClose < 0) {
          this.error("Single-file HTML does not contain the expected inline style.");
          return;
        }
        const styleEnd = styleClose + "</style>".length;
        const inlineStyle = withoutScript.slice(styleStart, styleEnd);
        const shellFirst = withoutScript.slice(0, styleStart) + withoutScript.slice(styleEnd);
        const nextBodyClose = shellFirst.lastIndexOf("</body>");
        asset.source = `${shellFirst.slice(0, nextBodyClose)}${inlineStyle}\n${inlineRuntime}\n${shellFirst.slice(nextBodyClose)}`;
      });
    }
  };
}

// 仅当 mode === "demo"（npm run build:demo）时启用单文件打包：
// JS/CSS 内联进 index.html、相对路径、输出到 demo/，双击即可运行。
// 正常 dev / build 行为与原配置完全一致。
export default defineConfig(({ mode }) => {
  const isDemo = mode === "demo";
  const isCampusMapDemo = mode === "campus-demo";
  const isSingleFileDemo = isDemo || isCampusMapDemo;

  return {
    // The active browser build owns every shipped asset through explicit imports.
    // `public/` only contains the retired Godot web export, so copying it into a
    // normal Vite build adds roughly 58 MB without an active runtime consumer.
    publicDir: false,
    ...(isSingleFileDemo
      ? {
          base: "./",
          plugins: [
            losslessRuntimeAssets(import.meta.dirname, true),
            embedChapter4H3AsChunks(),
            react(),
            viteSingleFile({ removeViteModuleLoader: true }),
            moveSingleFileRuntimeAfterShell()
          ],
          build: {
            outDir: "demo",
            // Keep the formal game and the map-only demo side by side. Both artifacts are self-contained.
            emptyOutDir: false,
            // The embedded assets dominate this roughly 260 MB artifact. Running
            // esbuild minification over that final inline payload creates several
            // full-size copies and can exhaust Windows commit memory even with a
            // large V8 heap. Syntax is still transpiled to BROWSER_BUILD_TARGET;
            // skipping minification adds only a small amount of script text.
            minify: false,
            chunkSizeWarningLimit: 8000,
            target: BROWSER_BUILD_TARGET,
            ...(isCampusMapDemo
              ? { rollupOptions: { input: resolve(import.meta.dirname, "campus-map-demo.html") } }
              : {})
          }
        }
      : {
          plugins: [losslessRuntimeAssets(import.meta.dirname, false), react()],
          build: {
            target: BROWSER_BUILD_TARGET
          }
        })
  };
});
