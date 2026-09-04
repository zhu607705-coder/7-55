import { readFile } from "node:fs/promises";
import { createServer } from "vite";

const [appSource, channelSource, mainSource] = await Promise.all([
  readFile(new URL("../src/App.tsx", import.meta.url), "utf8"),
  readFile(new URL("../src/components/DeveloperChannel.tsx", import.meta.url), "utf8"),
  readFile(new URL("../src/main.tsx", import.meta.url), "utf8")
]);

const failures = [];
let assertions = 0;

function assert(condition, message) {
  assertions += 1;
  if (!condition) failures.push(message);
}

const server = await createServer({
  logLevel: "error",
  optimizeDeps: { noDiscovery: true },
  server: { middlewareMode: true },
  appType: "custom"
});

try {
  const { isRecordingMode } = await server.ssrLoadModule("/src/core/RecordingMode.ts");
  assert(isRecordingMode("?recording=1"), "recording=1 must enable clean recording mode");
  assert(isRecordingMode("?devCheckpoint=c4-755-closure&recording=1"), "recording mode must coexist with direct checkpoint URLs");
  assert(!isRecordingMode("?recording=0"), "recording=0 must not enable recording mode");
  assert(!isRecordingMode("?recording=true"), "only the documented recording=1 flag may enable recording mode");
  assert(!isRecordingMode(""), "normal gameplay must stay outside recording mode");

  assert(
    appSource.includes('if (isRecordingMode(window.location.search) && params.get("dev") !== "1") return false;'),
    "recording mode must ignore a stale persisted-open panel unless dev=1 explicitly opens it"
  );
  assert(
    channelSource.includes("const recordingMode = isRecordingMode(window.location.search);")
      && channelSource.includes("if (recordingMode) return null;"),
    "the closed recording-mode channel must render no DEV launcher"
  );
  assert(
    channelSource.includes("(event.ctrlKey || event.metaKey)")
      && channelSource.includes('event.key.toLowerCase() === "d"'),
    "recording jumps must remain reachable through Ctrl/Cmd+Shift+D"
  );
  assert(
    channelSource.includes('nextUrl.searchParams.set("devCheckpoint", item.id);')
      && channelSource.includes('nextUrl.searchParams.delete("dev");')
      && channelSource.includes('window.history.replaceState(window.history.state, "", nextUrl);'),
    "a recording-mode panel jump must keep the current clean URL reload-safe"
  );
  assert(
    channelSource.includes('<footer><button type="button" onClick={() => {\n      closeAndResume();\n      if (restoreDeveloperBackup(store))'),
    "restoring the pre-DEV save must use the same recording-safe close path"
  );
  assert(
    channelSource.includes('recordingMode ? "录制检查点切换" : "章节与关卡直达"')
      && channelSource.includes('recordingMode ? "选择节点后自动清屏 · Esc 关闭" : "Ctrl/Cmd Shift D"'),
    "the integrated page must explain its recording setup state without showing the normal DEV title"
  );
  assert(
    mainSource.includes("recordingMode:")
      && mainSource.includes("developerLauncherVisible:")
      && mainSource.includes("developerChannelOpen:"),
    "render_game_to_text must expose recording cleanliness and temporary panel state"
  );
} finally {
  await server.close();
}

if (failures.length > 0) {
  console.error(`Recording mode validation FAIL assertions=${assertions}`);
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(`Recording mode validation PASS assertions=${assertions}`);
