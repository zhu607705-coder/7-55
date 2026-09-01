import { build } from "esbuild";
import { mkdtemp, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const tempDir = await mkdtemp(path.join(os.tmpdir(), "cc98-unified-login-"));
const bundlePath = path.join(tempDir, "runtime.mjs");

class MemoryStorage {
  #values = new Map();
  get length() { return this.#values.size; }
  clear() { this.#values.clear(); }
  getItem(key) { return this.#values.has(key) ? this.#values.get(key) : null; }
  key(index) { return [...this.#values.keys()][index] ?? null; }
  removeItem(key) { this.#values.delete(key); }
  setItem(key, value) { this.#values.set(String(key), String(value)); }
}

try {
  await build({
    stdin: {
      contents: [
        'export { ActOneBootstrapController } from "./src/modules/ActOneBootstrapController.ts";',
        'export { LibraryFinalsController } from "./src/modules/LibraryFinalsController.ts";',
        'export { CC98_LOGIN_HINTS, CC98_LOGIN_PASSWORD, CC98_LOGIN_STUDENT_ID, evaluateCc98LoginAttempt, getCc98LoginLockDurationMs } from "./src/modules/Cc98UnifiedLoginModel.ts";',
        'export { createInitialGameState } from "./src/core/GameState.ts";',
        'export { SaveStore } from "./src/core/SaveStore.ts";',
        'export { GAME_SAVE_KEY } from "./src/core/StorageKeys.ts";',
        'export { createDeveloperCheckpointState } from "./src/modules/DeveloperChannel.ts";',
        'export { selectQuestViewModel } from "./src/core/QuestModel.ts";',
        'export { default as actOneContent } from "./src/data/act-one-bootstrap.content.json";'
      ].join("\n"),
      resolveDir: root,
      sourcefile: "cc98-unified-login-entry.ts"
    },
    outfile: bundlePath,
    bundle: true,
    format: "esm",
    platform: "node",
    target: "node20"
  });

  const runtime = await import(`${pathToFileURL(bundlePath).href}?v=${Date.now()}`);
  const {
    ActOneBootstrapController,
    CC98_LOGIN_HINTS,
    CC98_LOGIN_PASSWORD,
    CC98_LOGIN_STUDENT_ID,
    GAME_SAVE_KEY,
    LibraryFinalsController,
    SaveStore,
    actOneContent,
    createDeveloperCheckpointState,
    createInitialGameState,
    evaluateCc98LoginAttempt,
    getCc98LoginLockDurationMs,
    selectQuestViewModel
  } = runtime;

  if (CC98_LOGIN_STUDENT_ID !== actOneContent.studentId || CC98_LOGIN_STUDENT_ID !== "3250100755") {
    throw new Error("CC98 login must reuse the protagonist student ID authored on the campus card");
  }
  if (CC98_LOGIN_HINTS.map((hint) => hint.fragment).join("") !== CC98_LOGIN_PASSWORD
    || CC98_LOGIN_PASSWORD !== "ZJU1897!") {
    throw new Error("the three symbolic hints must derive exactly one password");
  }
  if (getCc98LoginLockDurationMs(1) !== 0
    || getCc98LoginLockDurationMs(2) !== 0
    || getCc98LoginLockDurationMs(3) !== 30_000
    || getCc98LoginLockDurationMs(4) !== 60_000
    || getCc98LoginLockDurationMs(5) !== 90_000) {
    throw new Error("lock duration must start after three immediate attempts and grow in 30-second steps");
  }

  let inventoryTaskState = createDeveloperCheckpointState("c2-system");
  const inventoryTaskStore = {
    getState: () => inventoryTaskState,
    setState: (update) => { inventoryTaskState = typeof update === "function" ? update(inventoryTaskState) : update; }
  };
  const inventoryTaskController = new ActOneBootstrapController(inventoryTaskStore, { emit: () => undefined });
  if (!inventoryTaskController.confrontSystem()
    || inventoryTaskState.actOne.phase !== "inventory_required"
    || inventoryTaskState.rpgScene !== "dorm_hub"
    || inventoryTaskState.rpgCheckpoint !== "dorm_spawn"
    || inventoryTaskState.runtimeMode !== "phone") {
    throw new Error("the first Chapter 2 RPG task must prepare the dorm scene without leaving the phone immediately");
  }
  const inventoryQuest = selectQuestViewModel(inventoryTaskState);
  if (inventoryQuest.id !== "chapter_two_character_response"
    || inventoryQuest.objective !== "找到道具栏"
    || inventoryQuest.targetSurface !== "rpg") {
    throw new Error("the first Chapter 2 return-to-task action must point at the prepared dorm inventory task");
  }

  let postBdState = createDeveloperCheckpointState("c2-recovery-form");
  postBdState.ui.libraryFinalsPhase = "top_ten_reached";
  postBdState.ui.zjudingPage = "hub";
  const postBdStore = {
    getState: () => postBdState,
    setState: (update) => { postBdState = typeof update === "function" ? update(postBdState) : update; }
  };
  const postBdQuest = selectQuestViewModel(postBdState);
  if (postBdQuest.id !== "chapter_two_submit_recovery"
    || postBdQuest.recommendedScene !== "zjuding") {
    throw new Error("successful BD must advance the task drawer to the ZJU Ding recovery application");
  }
  const postBdController = new LibraryFinalsController(postBdStore, { emit: () => undefined });
  if (!postBdController.openRecoveryApplication()
    || postBdState.ui.libraryFinalsPhase !== "recovery_application") {
    throw new Error("the post-BD task route must be able to open the recovery materials workflow");
  }

  let state = createDeveloperCheckpointState("c2-cc98-login");
  const events = [];
  const store = {
    getState: () => state,
    setState: (update) => { state = typeof update === "function" ? update(state) : update; }
  };
  const controller = new ActOneBootstrapController(store, {
    emit: (name, payload) => events.push({ name, payload })
  });

  if (state.currentScene !== "cc98" || state.actOne.cc98Login.authenticated) {
    throw new Error("login checkpoint must stop at the unauthenticated CC98 gate");
  }
  if (selectQuestViewModel(state).id !== "chapter_two_cc98_unified_login") {
    throw new Error("task drawer must point to the identity gate before the market post");
  }
  if (controller.discoverCc98StudentId() !== "discovered" || !state.actOne.cc98Login.studentIdDiscovered) {
    throw new Error("the campus card must reveal the protagonist student ID");
  }
  if ([controller.revealCc98LoginHint(), controller.revealCc98LoginHint(), controller.revealCc98LoginHint()].join(",") !== "1,2,3") {
    throw new Error("password hints must reveal in a bounded three-step order");
  }

  const t0 = 1_800_000_000_000;
  const first = controller.submitCc98Login(CC98_LOGIN_STUDENT_ID, "wrong-1", t0);
  const second = controller.submitCc98Login(CC98_LOGIN_STUDENT_ID, "wrong-2", t0 + 1);
  const third = controller.submitCc98Login(CC98_LOGIN_STUDENT_ID, "wrong-3", t0 + 2);
  if (first.status !== "rejected" || first.lockDurationMs !== 0
    || second.status !== "rejected" || second.lockDurationMs !== 0
    || third.status !== "rejected" || third.lockDurationMs !== 30_000) {
    throw new Error("three immediate failures must end with one 30-second lock");
  }
  const blocked = controller.submitCc98Login(CC98_LOGIN_STUDENT_ID, CC98_LOGIN_PASSWORD, t0 + 3);
  if (blocked.status !== "locked" || state.actOne.cc98Login.failureCount !== 3) {
    throw new Error("submitting during lock must preserve the failure count and reject correct credentials");
  }
  const fourth = controller.submitCc98Login(CC98_LOGIN_STUDENT_ID, "wrong-4", t0 + 30_003);
  if (fourth.status !== "rejected" || fourth.lockDurationMs !== 60_000 || fourth.failureCount !== 4) {
    throw new Error("the fourth failure after expiry must accumulate a 60-second wait");
  }
  const accepted = controller.submitCc98Login(CC98_LOGIN_STUDENT_ID, CC98_LOGIN_PASSWORD, t0 + 90_004);
  if (accepted.status !== "authenticated" || !state.actOne.cc98Login.authenticated || state.actOne.cc98Login.lockUntilMs !== null) {
    throw new Error("correct credentials after expiry must authenticate and clear the lock");
  }
  if (selectQuestViewModel(state).id !== "chapter_two_direction_purchase_gamepad") {
    throw new Error("successful authentication must return the task drawer to the gamepad purchase");
  }

  const persistedStorage = new MemoryStorage();
  const saveStore = new SaveStore(persistedStorage);
  if (!saveStore.save(state)) throw new Error("authenticated state must save");
  const reloaded = saveStore.load(createInitialGameState());
  if (!reloaded?.actOne.cc98Login.authenticated || reloaded.actOne.cc98Login.failureCount !== 4) {
    throw new Error("authenticated state and attempt history must survive save/reload");
  }

  const legacyState = createInitialGameState();
  legacyState.actOne.phase = "movement_required";
  legacyState.actOne.gamepadPurchased = true;
  legacyState.items.gamepad = true;
  delete legacyState.actOne.cc98Login;
  const legacyStorage = new MemoryStorage();
  legacyStorage.setItem(GAME_SAVE_KEY, JSON.stringify({ version: 27, state: legacyState, savedAt: t0 }));
  const migrated = new SaveStore(legacyStorage).load(createInitialGameState());
  if (!migrated?.actOne.cc98Login.authenticated || !migrated.actOne.cc98Login.studentIdDiscovered) {
    throw new Error("pre-login saves that already own the gamepad must migrate past the new gate");
  }

  const marketCheckpoint = createDeveloperCheckpointState("c2-gamepad-market");
  if (!marketCheckpoint.actOne.cc98Login.authenticated || marketCheckpoint.currentScene !== "cc98") {
    throw new Error("market checkpoint must bypass the completed authentication gate");
  }

  const pureLocked = evaluateCc98LoginAttempt(
    { studentIdDiscovered: true, revealedHintCount: 3, failureCount: 3, lockUntilMs: t0 + 30_000, authenticated: false },
    CC98_LOGIN_STUDENT_ID,
    CC98_LOGIN_PASSWORD,
    t0 + 10_000
  );
  if (pureLocked.status !== "locked" || pureLocked.remainingMs !== 20_000) {
    throw new Error("pure attempt evaluator must use an absolute monotonic lock deadline");
  }

  if (!events.some((event) => event.name === "cc98_login_authenticated")
    || !events.some((event) => event.name === "cc98_login_attempt_locked")) {
    throw new Error("authentication and lock outcomes must emit presentation events");
  }

  console.log("CC98 unified login PASS student=3250100755 password=ZJU1897! immediate-attempts=3 lock-sequence=30/60/90s save-migration=v27 dev-checkpoints=2 quest-handoff=dorm+recovery-materials");
} finally {
  await rm(tempDir, { recursive: true, force: true });
}
