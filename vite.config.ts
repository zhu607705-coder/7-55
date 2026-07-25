import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";
import { defineConfig, type Plugin } from "vite";
import { resolve } from "node:path";

const BROWSER_BUILD_TARGET = ["chrome90", "edge90", "firefox91", "safari15"];

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

// Single-file modes inline JS and CSS into demo/*.html. Each demo remains an
// independent entry while sharing the same Vite and browser compatibility baseline.
export default defineConfig(({ mode }) => {
  const isDemo = mode === "demo";
  const isCampusMapDemo = mode === "campus-demo";
  const isProjectPreview = mode === "project-preview";
  const isSingleFileDemo = isDemo || isCampusMapDemo || isProjectPreview;
  const singleFileInput = isCampusMapDemo
    ? resolve(import.meta.dirname, "campus-map-demo.html")
    : isProjectPreview
      ? resolve(import.meta.dirname, "project-preview.html")
      : null;

  return {
    ...(isSingleFileDemo
      ? {
          base: "./",
          plugins: [react(), viteSingleFile({ removeViteModuleLoader: true }), moveSingleFileRuntimeAfterShell()],
          build: {
            outDir: "demo",
            // Formal game, map demo and repository portal are generated side by side.
            emptyOutDir: false,
            chunkSizeWarningLimit: 8000,
            target: BROWSER_BUILD_TARGET,
            ...(singleFileInput ? { rollupOptions: { input: singleFileInput } } : {})
          }
        }
      : {
          plugins: [react()],
          build: {
            target: BROWSER_BUILD_TARGET
          }
        })
  };
});
