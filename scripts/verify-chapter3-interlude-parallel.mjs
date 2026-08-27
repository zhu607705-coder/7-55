import fs from "node:fs";
import { createServer } from "vite";

const errors = [];
let assertionCount = 0;
let successfulOrderCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function sameMembers(actual, expected) {
  return actual.length === expected.length && expected.every((value) => actual.includes(value));
}

function sameOrder(actual, expected) {
  return actual.length === expected.length && actual.every((value, index) => value === expected[index]);
}

function permutations(values) {
  if (values.length <= 1) return [values];
  return values.flatMap((value, index) => permutations([
    ...values.slice(0, index),
    ...values.slice(index + 1)
  ]).map((tail) => [value, ...tail]));
}

class MemoryStorage {
  #values = new Map();
  get length() { return this.#values.size; }
  clear() { this.#values.clear(); }
  getItem(key) { return this.#values.has(key) ? this.#values.get(key) : null; }
  key(index) { return [...this.#values.keys()][index] ?? null; }
  removeItem(key) { this.#values.delete(key); }
  setItem(key, value) { this.#values.set(String(key), String(value)); }
}

const server = await createServer({
  logLevel: "error",
  server: { middlewareMode: true },
  appType: "custom"
});

try {
  const [
    gameStateModule,
    eventBusModule,
    developerModule,
    controllerModule,
    interludeModelModule,
    questModule,
    saveStoreModule,
    storageKeysModule
  ] = await Promise.all([
    server.ssrLoadModule("/src/core/GameState.ts"),
    server.ssrLoadModule("/src/core/EventBus.ts"),
    server.ssrLoadModule("/src/modules/DeveloperChannel.ts"),
    server.ssrLoadModule("/src/modules/ChapterThreePhoneInterludeController.ts"),
    server.ssrLoadModule("/src/modules/ChapterThreeInterludeModel.ts"),
    server.ssrLoadModule("/src/core/QuestModel.ts"),
    server.ssrLoadModule("/src/core/SaveStore.ts"),
    server.ssrLoadModule("/src/core/StorageKeys.ts")
  ]);

  const { createGameStore, createInitialGameState } = gameStateModule;
  const { EventBus } = eventBusModule;
  const { createDeveloperCheckpointState } = developerModule;
  const { ChapterThreePhoneInterludeController } = controllerModule;
  const { selectChapterThreeInterludeViewModel } = interludeModelModule;
  const { selectQuestViewModel } = questModule;
  const { SaveStore } = saveStoreModule;
  const { GAME_SAVE_KEY } = storageKeysModule;

  const canonicalEvidenceOrder = [
    "journal_start",
    "photo_direction",
    "network_destination",
    "broadcast_end"
  ];
  const canonicalTimelineOrder = [...canonicalEvidenceOrder];
  const canonicalDecoyOrder = ["canteen_0755", "theater_0832", "status_clock_075523"];
  const branchNames = ["photos", "voice", "messages", "network"];
  const messageOrders = ["notice_first", "route_first"];

  const pendingState = createDeveloperCheckpointState("c3-interlude-photos");
  const pendingView = selectChapterThreeInterludeViewModel(pendingState);
  const pendingQuest = selectQuestViewModel(pendingState);
  assert(pendingView.currentObjective.id === "chapter_three_interlude_evidence", "journal start must open one aggregate evidence objective");
  assert(pendingView.branchProgress.completed === 0 && pendingView.branchProgress.total === 4, "aggregate evidence progress must start at 0/4");
  assert(pendingView.parallelBranches.length === 4, "aggregate evidence objective must expose four parallel branches");
  assert(
    pendingView.parallelBranches.map(({ id }) => id).join(",") === "photos,voice,messages,network",
    "parallel branches must remain photos, voice, messages and network"
  );
  assert(pendingQuest.objective === "恢复剩余证据", "quest objective must use the aggregate evidence label");
  assert(pendingQuest.recommendedScene === "phone_home", "aggregate evidence objective must not imply a first app");
  assert(pendingQuest.parallelProgress?.completed === 0 && pendingQuest.parallelProgress?.total === 4, "quest projection must expose 0/4 progress");
  assert(pendingQuest.parallelBranches?.length === 4, "quest projection must expose four clickable branch rows");
  assert(
    pendingQuest.parallelBranches?.every(({ status }) => status === "pending"),
    "all four branch rows must initially be pending"
  );

  const forbiddenAnswerFragments = [
    "paper_left",
    "paper_middle",
    "paper_right",
    "record_0755",
    "east_closed",
    "west_cleaner",
    "duan_yongping",
    "段永平教学楼",
    "AP-DYP",
    "22:45:00"
  ];
  const visibleAggregateCopy = JSON.stringify({
    objective: pendingQuest.objective,
    hints: pendingQuest.hints,
    branches: pendingQuest.parallelBranches
  });
  for (const fragment of forbiddenAnswerFragments) {
    assert(!visibleAggregateCopy.includes(fragment), `aggregate quest must not reveal answer fragment ${fragment}`);
  }

  function runBranch(controller, store, branch, messageOrder) {
    if (branch === "photos") {
      return controller.submitPhotoSequence(["paper_left", "paper_middle", "paper_right"]);
    }
    if (branch === "voice") {
      return controller.submitVoiceSequence(["lake", "stone", "lobby", "broadcast"]);
    }
    if (branch === "network") {
      return controller.readNetworkRecord("record_0755");
    }
    const first = messageOrder === "notice_first"
      ? controller.saveOfficialNotice()
      : controller.saveRouteScreenshot(["east_closed", "west_cleaner"]);
    assert(first === "accepted", `${messageOrder} first message action must be accepted`);
    const partialMessages = selectChapterThreeInterludeViewModel(store.getState())
      .parallelBranches.find(({ id }) => id === "messages");
    assert(partialMessages?.completed === false, `${messageOrder} must keep messages pending until both records are saved`);
    return messageOrder === "notice_first"
      ? controller.saveRouteScreenshot(["east_closed", "west_cleaner"])
      : controller.saveOfficialNotice();
  }

  for (const order of permutations(branchNames)) {
    for (const messageOrder of messageOrders) {
      const store = createGameStore(createDeveloperCheckpointState("c3-interlude-photos"));
      const controller = new ChapterThreePhoneInterludeController(store, new EventBus());
      const completedBranches = new Set();
      for (const branch of order) {
        const result = runBranch(controller, store, branch, messageOrder);
        assert(result === "accepted", `${order.join("->")} / ${messageOrder}: ${branch} must be accepted`);
        completedBranches.add(branch);
        const view = selectChapterThreeInterludeViewModel(store.getState());
        assert(
          view.branchProgress.completed === completedBranches.size,
          `${order.join("->")} / ${messageOrder}: aggregate progress must advance once per completed branch`
        );
        for (const row of view.parallelBranches) {
          assert(
            row.completed === completedBranches.has(row.id),
            `${order.join("->")} / ${messageOrder}: ${row.id} row status is inconsistent`
          );
        }
      }

      const collected = store.getState().chapterThreeInterlude;
      const completedView = selectChapterThreeInterludeViewModel(store.getState());
      assert(completedView.branchProgress.completed === 4, `${order.join("->")} / ${messageOrder}: all four branches must complete`);
      assert(completedView.currentObjective.id === "chapter_three_interlude_exclusions", `${order.join("->")} / ${messageOrder}: exclusions must follow parallel collection directly`);
      assert(sameMembers(collected.evidenceIds, canonicalEvidenceOrder), `${order.join("->")} / ${messageOrder}: all four evidence summaries must be collected`);
      assert(collected.timelineOrder.length === 0, `${order.join("->")} / ${messageOrder}: collection must not require a manual timeline action`);

      assert(controller.rejectDecoy("canteen_0755", "number_not_time") === "accepted", "canteen decoy must be rejectable");
      assert(controller.rejectDecoy("theater_0832", "earlier_independent_event") === "accepted", "theater decoy must be rejectable");
      assert(controller.rejectDecoy("status_clock_075523", "frozen_local_clock") === "accepted", "status-clock decoy must be rejectable");
      store.setState((current) => ({
        ...current,
        chapterThreeInterlude: {
          ...current.chapterThreeInterlude,
          timelineOrder: ["broadcast_end"]
        }
      }));
      const destinationView = selectChapterThreeInterludeViewModel(store.getState());
      assert(destinationView.destinationSelectionUnlocked, "destination selection must not depend on a stored timeline order");
      assert(destinationView.currentObjective.id === "chapter_three_interlude_destination", "formal selector must skip the removed timeline task");
      assert(controller.verifyDestination("qizhen_lake_dock") === "incorrect", "wrong destination must remain rejected");
      assert(store.getState().chapterThreeInterlude.destinationId === null, "wrong destination must not write progress");
      assert(controller.verifyDestination("duan_yongping_a1") === "accepted", "correct destination must be accepted after exclusions");
      assert(
        sameOrder(store.getState().chapterThreeInterlude.timelineOrder, canonicalTimelineOrder),
        "accepted destination must normalize the canonical timeline order"
      );
      successfulOrderCount += 1;
    }
  }

  assert(successfulOrderCount === 48, "validator must exercise all 4! branch orders and both message-internal orders");

  const lockedStore = createGameStore(createDeveloperCheckpointState("c3-interlude-journal"));
  const lockedController = new ChapterThreePhoneInterludeController(lockedStore, new EventBus());
  assert(lockedController.submitPhotoSequence(["paper_left", "paper_middle", "paper_right"]) === "locked", "photo recovery must stay locked before journal start");
  assert(lockedController.submitVoiceSequence(["lake", "stone", "lobby", "broadcast"]) === "locked", "voice recovery must stay locked before journal start");
  assert(lockedController.saveOfficialNotice() === "locked", "message notice must stay locked before journal start");
  assert(lockedController.saveRouteScreenshot(["east_closed", "west_cleaner"]) === "locked", "message screenshot must stay locked before journal start");
  assert(lockedController.readNetworkRecord("record_0755") === "locked", "network record must stay locked before journal start");
  assert(lockedStore.getState().chapterThreeInterlude.evidenceIds.length === 0, "locked pre-journal actions must not write evidence");

  const incorrectStore = createGameStore(createDeveloperCheckpointState("c3-interlude-photos"));
  const incorrectController = new ChapterThreePhoneInterludeController(incorrectStore, new EventBus());
  assert(incorrectController.submitPhotoSequence(["paper_right", "paper_left"]) === "incorrect", "wrong photo order must be rejected");
  assert(incorrectController.submitVoiceSequence(["decoy_library"]) === "incorrect", "wrong voice selection must be rejected");
  assert(incorrectController.saveRouteScreenshot(["computer_left_on"]) === "incorrect", "wrong message selection must be rejected");
  assert(incorrectController.readNetworkRecord("record_library_south") === "incorrect", "wrong network record must be rejected");
  const incorrectState = incorrectStore.getState().chapterThreeInterlude;
  assert(!incorrectState.photoSequenceSolved && !incorrectState.voiceSequenceSolved, "wrong sequence inputs must not write solved facts");
  assert(!incorrectState.routeScreenshotSaved && !incorrectState.networkRecordRead, "wrong message/network inputs must not write completion facts");
  assert(selectChapterThreeInterludeViewModel(incorrectStore.getState()).branchProgress.completed === 0, "wrong inputs must leave branch progress at 0/4");

  const completedPhotoStore = createGameStore(createDeveloperCheckpointState("c3-interlude-photos"));
  const completedPhotoController = new ChapterThreePhoneInterludeController(
    completedPhotoStore,
    new EventBus()
  );
  assert(
    completedPhotoController.submitPhotoSequence(["paper_left", "paper_middle", "paper_right"]) === "accepted",
    "the first correct photo sequence must be accepted"
  );
  assert(
    completedPhotoController.submitPhotoSequence(["paper_right", "paper_left"]) === "already_complete",
    "reopening a completed photo branch must not overwrite the confirmed fact"
  );
  assert(
    completedPhotoStore.getState().chapterThreeInterlude.photoSequenceSolved,
    "an incorrect replay must not regress completed photo evidence"
  );
  assert(
    completedPhotoStore.getState().chapterThreeInterlude.evidenceIds.includes("photo_direction"),
    "an incorrect replay must preserve the photo summary evidence"
  );

  function hydrateInterlude(overrides) {
    const storage = new MemoryStorage();
    const saveStore = new SaveStore(storage);
    const savedState = createDeveloperCheckpointState("c3-interlude-photos");
    assert(saveStore.save(savedState), "legacy fixture base save must persist");
    const envelope = JSON.parse(storage.getItem(GAME_SAVE_KEY));
    envelope.state.chapterThreeInterlude = {
      ...envelope.state.chapterThreeInterlude,
      phase: "timeline_assembly",
      rejectedDecoyIds: [...canonicalDecoyOrder],
      statusClockMarkedUntrusted: true,
      destinationId: null,
      completed: false,
      ...overrides
    };
    storage.setItem(GAME_SAVE_KEY, JSON.stringify(envelope));
    return saveStore.load(createInitialGameState());
  }

  const detailedOnly = hydrateInterlude({
    photoFrameIds: [],
    photoSequenceSolved: true,
    voiceClipOrder: [],
    voiceSequenceSolved: true,
    officialNoticeSaved: true,
    routeScreenshotSaved: true,
    networkRecordRead: true,
    evidenceIds: ["journal_start"],
    timelineOrder: []
  });
  assert(detailedOnly !== null, "detailed-only legacy save must hydrate");
  assert(sameOrder(detailedOnly.chapterThreeInterlude.evidenceIds, canonicalEvidenceOrder), "detailed facts must rebuild summary evidence IDs");
  assert(sameOrder(detailedOnly.chapterThreeInterlude.timelineOrder, canonicalTimelineOrder), "empty legacy timeline must normalize when prerequisites are ready");
  assert(sameOrder(detailedOnly.chapterThreeInterlude.photoFrameIds, ["paper_left", "paper_middle", "paper_right"]), "solved photo fact must restore canonical frame order");
  assert(sameOrder(detailedOnly.chapterThreeInterlude.voiceClipOrder, ["lake", "stone", "lobby", "broadcast"]), "solved voice fact must restore canonical clip order");

  const wrongTimeline = hydrateInterlude({
    photoSequenceSolved: true,
    voiceSequenceSolved: true,
    officialNoticeSaved: true,
    routeScreenshotSaved: true,
    networkRecordRead: true,
    evidenceIds: [...canonicalEvidenceOrder],
    timelineOrder: [...canonicalTimelineOrder].reverse()
  });
  assert(wrongTimeline !== null, "wrong-order legacy timeline must hydrate");
  assert(sameOrder(wrongTimeline.chapterThreeInterlude.timelineOrder, canonicalTimelineOrder), "wrong legacy timeline order must normalize canonically");

  const recoveryStorage = new MemoryStorage();
  const recoverySaveStore = new SaveStore(recoveryStorage);
  const recoveryStore = createGameStore(createDeveloperCheckpointState("c3-interlude-journal"));
  const recoveryController = new ChapterThreePhoneInterludeController(recoveryStore, new EventBus());
  assert(recoveryController.beginRecovery() === "accepted", "recovery entry must open before journal closeout");
  assert(recoverySaveStore.save(recoveryStore.getState()), "pre-closeout recovery state must persist");
  const recoveryReloaded = recoverySaveStore.load(createInitialGameState());
  assert(recoveryReloaded !== null, "pre-closeout recovery state must reload");
  assert(
    !recoveryReloaded.chapterThreeInterlude.evidenceIds.includes("journal_start"),
    "reloading an opened recovery page must not fabricate journal-start evidence"
  );
  assert(
    recoveryReloaded.qizhenLake.journal.status !== "archived",
    "reloading before closeout must keep the journal unarchived"
  );
  const recoveryReloadedStore = createGameStore(recoveryReloaded);
  const recoveryReloadedController = new ChapterThreePhoneInterludeController(
    recoveryReloadedStore,
    new EventBus()
  );
  assert(
    recoveryReloadedController.completeJournalCloseout("details_withheld") === "accepted",
    "journal closeout must remain completable after a reload"
  );
  assert(
    recoveryReloadedStore.getState().qizhenLake.journal.status === "archived"
      && recoveryReloadedStore.getState().chapterThreeInterlude.evidenceIds.includes("journal_start"),
    "journal evidence must be written only by the completed closeout transaction"
  );

  const summariesOnly = hydrateInterlude({
    photoFrameIds: [],
    photoSequenceSolved: false,
    voiceClipOrder: [],
    voiceSequenceSolved: false,
    officialNoticeSaved: false,
    routeScreenshotSaved: false,
    networkRecordRead: false,
    evidenceIds: [...canonicalEvidenceOrder],
    timelineOrder: []
  });
  assert(summariesOnly !== null, "summary-only legacy save must hydrate");
  assert(summariesOnly.chapterThreeInterlude.photoSequenceSolved, "photo summary must restore the detailed solved fact");
  assert(summariesOnly.chapterThreeInterlude.voiceSequenceSolved, "voice summary must restore the detailed solved fact");
  assert(
    summariesOnly.chapterThreeInterlude.officialNoticeSaved
      && summariesOnly.chapterThreeInterlude.routeScreenshotSaved
      && summariesOnly.chapterThreeInterlude.networkRecordRead,
    "network summary must restore all three detailed facts"
  );
  assert(sameOrder(summariesOnly.chapterThreeInterlude.timelineOrder, canonicalTimelineOrder), "summary-only save must restore the canonical timeline");
  assert(selectChapterThreeInterludeViewModel(summariesOnly).destinationSelectionUnlocked, "hydrated legacy save must continue at destination selection");

  const chapterFourStorage = new MemoryStorage();
  const chapterFourSaveStore = new SaveStore(chapterFourStorage);
  const chapterFourCheckpointState = createDeveloperCheckpointState("c4-755-room204-1850");
  const chapterFourState = {
    ...chapterFourCheckpointState,
    chapter4: {
      ...chapterFourCheckpointState.chapter4,
      prologueSeen: true
    }
  };
  assert(chapterFourSaveStore.save(chapterFourState), "started-Chapter-4 fixture base save must persist");
  const chapterFourEnvelope = JSON.parse(chapterFourStorage.getItem(GAME_SAVE_KEY));
  chapterFourEnvelope.state.chapter4 = {
    ...chapterFourEnvelope.state.chapter4,
    prologueSeen: true,
    phase: "opening_paper_caught"
  };
  chapterFourEnvelope.state.chapterThreeInterlude = {
    ...createInitialGameState().chapterThreeInterlude,
    phase: "inactive"
  };
  chapterFourStorage.setItem(GAME_SAVE_KEY, JSON.stringify(chapterFourEnvelope));
  const chapterFourHydrated = chapterFourSaveStore.load(createInitialGameState());
  assert(chapterFourHydrated !== null, "started-Chapter-4 legacy save must hydrate");
  assert(chapterFourHydrated.chapterThreeInterlude.completed, "started Chapter 4 must keep the interlude complete");
  assert(chapterFourHydrated.chapterThreeInterlude.destinationId === "duan_yongping_a1", "started Chapter 4 must restore the confirmed destination");
  assert(sameOrder(chapterFourHydrated.chapterThreeInterlude.evidenceIds, canonicalEvidenceOrder), "started Chapter 4 must restore all evidence summaries");
  assert(sameOrder(chapterFourHydrated.chapterThreeInterlude.timelineOrder, canonicalTimelineOrder), "started Chapter 4 must restore the canonical timeline");

  const compatibilityStore = createGameStore({
    ...createDeveloperCheckpointState("c3-interlude-destination"),
    chapterThreeInterlude: {
      ...createDeveloperCheckpointState("c3-interlude-destination").chapterThreeInterlude,
      timelineOrder: []
    }
  });
  const compatibilityController = new ChapterThreePhoneInterludeController(compatibilityStore, new EventBus());
  assert(compatibilityController.assembleTimeline() === "accepted", "assembleTimeline must remain a compatible DEV/legacy entry point");
  assert(sameOrder(compatibilityStore.getState().chapterThreeInterlude.timelineOrder, canonicalTimelineOrder), "compatibility timeline action must remain canonical");

  const contentSource = fs.readFileSync(new URL("../src/data/chapter3InterludeContent.ts", import.meta.url), "utf8");
  const modelSource = fs.readFileSync(new URL("../src/modules/ChapterThreeInterludeModel.ts", import.meta.url), "utf8");
  const taskUiSource = fs.readFileSync(new URL("../src/components/QuestClueStrip.tsx", import.meta.url), "utf8");
  assert(!contentSource.includes("chapter_three_interlude_timeline"), "formal task copy must remove the dead timeline objective");
  assert(!modelSource.includes('taskKey = "timeline"'), "formal selector must not select a timeline objective");
  assert(taskUiSource.includes("quest.parallelBranches.map"), "task drawer must render every parallel branch row");
  assert(taskUiSource.includes("navigateToParallelBranch"), "parallel branch rows must provide direct app navigation");
} finally {
  await server.close();
}

if (errors.length > 0) {
  console.error(`Chapter 3.5 parallel interlude validation failed (${errors.length}/${assertionCount}):`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Chapter 3.5 parallel interlude validation passed (${assertionCount} assertions, ${successfulOrderCount} completion orders).`);
