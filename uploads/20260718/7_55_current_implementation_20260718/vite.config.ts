import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";
import { defineConfig, type Plugin } from "vite";

function moveSingleFileRuntimeAfterShell(): Plugin {
  return {
    name: "move-single-file-runtime-after-shell",
    enforce: "post",
    generateBundle(_options, bundle) {
      const htmlAsset = bundle["index.html"];
      if (!htmlAsset || htmlAsset.type !== "asset" || typeof htmlAsset.source !== "string") {
        return;
      }
      const html = htmlAsset.source;
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
      htmlAsset.source = `${shellFirst.slice(0, nextBodyClose)}${inlineStyle}\n${inlineRuntime}\n${shellFirst.slice(nextBodyClose)}`;
    }
  };
}

// 仅当 mode === "demo"（npm run build:demo）时启用单文件打包：
// JS/CSS 内联进 index.html、相对路径、输出到 demo/，双击即可运行。
// 正常 dev / build 行为与原配置完全一致。
export default defineConfig(({ mode }) => {
  const isDemo = mode === "demo";

  return {
    ...(isDemo
      ? {
          base: "./",
          plugins: [react(), viteSingleFile({ removeViteModuleLoader: true }), moveSingleFileRuntimeAfterShell()],
          build: {
            outDir: "demo",
            chunkSizeWarningLimit: 8000
          }
        }
      : {
          plugins: [react()]
        })
  };
});
