import {
  lazy,
  Suspense,
  useCallback,
  useEffect,
  useRef,
  useState,
  useSyncExternalStore,
  type ComponentProps,
  type ComponentType
} from "react";
import { eventBus } from "./core/EventBus";
import { gameStore } from "./core/GameState";
import { SceneRouter } from "./core/SceneRouter";
import { selectFeatureAccess } from "./core/FeatureAccess";
import type { GameState, QuestViewModel } from "./core/types";
import { PhoneShell } from "./components/PhoneShell";
import { DeveloperChannel } from "./components/DeveloperChannel";
import { ChapterThreeOpeningOverlay } from "./components/ChapterThreeOpeningOverlay";
import { LibraryStoryOverlay } from "./components/LibraryStoryOverlay";
import { PresentationLayer } from "./components/PresentationLayer";
import { ToastLayer } from "./components/ToastLayer";
import { useMediaQuery } from "./components/useMediaQuery";
import { QuestTaskBar } from "./components/QuestClueStrip";
import { audioDirector } from "./modules/AudioDirector";
import { kit } from "./modules/GameKit";
import { presentationDirector } from "./modules/PresentationDirector";
import { getPhoneScene } from "./scenes/phone/registry";
import { LIBRARY_STORY_SEQUENCES } from "./data/libraryFinalsStory";
import { requestCc98Thread } from "./modules/NavIntent";
import { preloadRpgGameHost } from "./scenes/rpg/RpgRuntimePreload";
import { scheduleRpgRuntimeWarmup } from "./scenes/rpg/RpgRuntimePreload";
import {
  getPreloadedRpgGameHostModule,
  subscribePreloadedRpgGameHostModule
} from "./scenes/rpg/RpgRuntimePreload";
import { Chapter4PrologueRuntimeGate } from "./components/Chapter4PrologueRuntimeGate";

const router = new SceneRouter(gameStore, eventBus);
const RpgGameHost = lazy(() =>
  preloadRpgGameHost().then((module) => ({ default: module.RpgGameHost }))
);

const LIBRARY_STORY_SEQUENCE_BY_EVENT: Readonly<Record<string, string>> = {
  library_route_unlocked: "library_route_unlocked",
  library_entered: "library_entered",
  library_occupied_seat_found: "library_occupied_seat_found",
  cc98_occupation_post_opened: "cc98_occupation_post_opened",
  library_catalog_match_found: "library_catalog_match_found",
  library_archived_rule_recovered: "library_archived_rule_recovered",
  library_front_desk_proof_request: "library_front_desk_proof_request",
  library_bag_nonperson_proof_issued: "library_bag_nonperson_proof_issued",
  tiyi_presence_proof_issued: "tiyi_presence_proof_issued",
  cc98_evidence_set_completed: "cc98_evidence_set_completed",
  cc98_top_ten_reached: "cc98_top_ten_reached",
  library_seat_release_pass_issued: "library_seat_release_pass_issued",
  library_backpack_evicted: "library_backpack_evicted",
  library_seat_recovered: "library_friend_contacted"
};

const LIBRARY_STORY_DELAY_BY_EVENT: Readonly<Partial<Record<string, number>>> = {
  library_bag_nonperson_proof_issued: 900
};

function getSnapshot(): GameState {
  return gameStore.getState();
}

const DESKTOP_GAMEPLAY_QUERY = "(min-width: 1100px) and (orientation: landscape) and (any-pointer: fine) and (any-hover: hover)";

export function App() {
  const state = useSyncExternalStore(gameStore.subscribe, getSnapshot, getSnapshot);
  const [developerChannelOpen, setDeveloperChannelOpen] = useState(false);
  const [libraryStorySequence, setLibraryStorySequence] = useState<string | null>(null);
  const libraryStorySequenceRef = useRef<string | null>(null);
  const libraryStoryQueueRef = useRef<string[]>([]);
  const [activeSurface, setActiveSurface] = useState<"phone" | "rpg">("rpg");
  const [resolvedRpgGameHost, setResolvedRpgGameHost] = useState<
    ComponentType<ComponentProps<typeof RpgGameHost>> | null
  >(() => getPreloadedRpgGameHostModule()?.RpgGameHost ?? null);
  const desktopGameplay = useMediaQuery(DESKTOP_GAMEPLAY_QUERY);
  const phonePaneRef = useRef<HTMLElement>(null);
  const Scene = getPhoneScene(state.currentScene);
  const access = selectFeatureAccess(state);
  // 第四章校时：桌面 RPG 模式下打开手机时钟页时，左右两栏真分屏并排
  const clockSplit = access.clockCalibration && state.currentScene === "clock";
  const showChapterTwoIntro = access.chapter !== "chapter_one"
    && !state.ui.seenChapterIntros.includes("chapter_two");
  const libraryStoryVisible = libraryStorySequence !== null && !showChapterTwoIntro;
  const ActiveRpgGameHost = resolvedRpgGameHost ?? RpgGameHost;

  useEffect(() => subscribePreloadedRpgGameHostModule((module) => {
    setResolvedRpgGameHost(() => module.RpgGameHost);
  }), []);

  useEffect(() => {
    if (state.runtimeMode !== "phone") return undefined;
    // 3.5 章在玩家确认目的地前不求值第四章 RPG；确认回放后由过渡 Gate
    // 立即预热 A1。其他手机流程则在当前交互的空闲片段预取下一张 RPG 场景。
    if (state.currentScene === "timeline_recovery") return undefined;
    return scheduleRpgRuntimeWarmup(
      state.rpgScene,
      state.rpgScene === "duan_yongping_temporal_maze" ? "entry" : undefined
    );
  }, [state.currentScene, state.rpgScene, state.runtimeMode]);

  const startLibraryStory = useCallback((sequenceId: string) => {
    if (!Object.prototype.hasOwnProperty.call(LIBRARY_STORY_SEQUENCES, sequenceId)) {
      return;
    }
    const activeSequence = libraryStorySequenceRef.current;
    if (activeSequence === sequenceId || libraryStoryQueueRef.current.includes(sequenceId)) {
      return;
    }
    if (activeSequence) {
      libraryStoryQueueRef.current.push(sequenceId);
      return;
    }
    libraryStorySequenceRef.current = sequenceId;
    setLibraryStorySequence(sequenceId);
  }, []);

  const finishLibraryStory = useCallback(() => {
    const sequenceId = libraryStorySequenceRef.current;
    if (!sequenceId) {
      return;
    }

    const progressionAccepted = sequenceId === "cc98_evidence_set_completed"
      ? kit.libraryFinals.acknowledgeBdBriefing()
      : sequenceId === "library_archived_rule_recovered"
        ? kit.libraryFinals.acknowledgeArchivedRuleBriefing()
      : sequenceId === "library_front_desk_proof_request"
        ? kit.libraryFinals.acknowledgeFrontDeskProofRequest()
      : sequenceId === "library_seat_release_pass_issued"
        ? kit.libraryFinals.acknowledgePassBriefing()
      : sequenceId === "library_friend_contacted"
        ? kit.libraryFinals.complete022Dialogue()
        : true;
    if (!progressionAccepted) {
      eventBus.emit("toast", {
        text: "当前剧情条件已变化，请返回任务目标后重试。",
        tone: "system",
        durationMs: 3600
      });
      libraryStoryQueueRef.current = [];
      libraryStorySequenceRef.current = null;
      setLibraryStorySequence(null);
      return;
    }

    eventBus.emit("library_story_finished", { sequenceId });
    const nextSequenceId = libraryStoryQueueRef.current.shift() ?? null;
    libraryStorySequenceRef.current = nextSequenceId;
    setLibraryStorySequence(nextSequenceId);
  }, []);

  useEffect(() => {
    const detachAudio = audioDirector.attach(eventBus);
    const detachPresentation = presentationDirector.attach(gameStore, eventBus);
    const detachSurfaceSync = eventBus.subscribe((event) => {
      if ([
        "act2_rpg_entered",
        "library_entered",
        "library_reentered",
        "qizhen_campus_approach_entered",
        "qizhen_lake_entered",
        "qizhen_rpg_resumed"
      ].includes(event.name)) {
        setActiveSurface("rpg");
      }
    });
    return () => {
      detachSurfaceSync();
      detachPresentation();
      detachAudio();
    };
  }, []);

  useEffect(() => {
    audioDirector.setMusicMuted(state.ui.musicMuted);
  }, [state.ui.musicMuted]);

  useEffect(() => {
    const pendingTimers = new Set<number>();
    const detach = eventBus.subscribe((event) => {
      if (event.name === "library_entered" && event.payload?.firstEntry === true) {
        startLibraryStory("library_route_unlocked");
        startLibraryStory("library_entered");
        return;
      }
      const sequenceId = event.name === "library_story_request"
        ? String(event.payload?.sequenceId ?? "")
        : LIBRARY_STORY_SEQUENCE_BY_EVENT[event.name];
      if (!sequenceId) {
        return;
      }
      const delayMs = LIBRARY_STORY_DELAY_BY_EVENT[event.name] ?? 0;
      if (delayMs <= 0) {
        startLibraryStory(sequenceId);
        return;
      }
      const timer = window.setTimeout(() => {
        pendingTimers.delete(timer);
        startLibraryStory(sequenceId);
      }, delayMs);
      pendingTimers.add(timer);
    });
    return () => {
      detach();
      pendingTimers.forEach((timer) => window.clearTimeout(timer));
    };
  }, [startLibraryStory]);

  useEffect(() => {
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (
      puzzle.archivedRuleRead
      && !puzzle.archivedRuleBriefingSeen
      && state.ui.libraryFinalsPhase === "evidence_gathering"
    ) {
      startLibraryStory("library_archived_rule_recovered");
      return;
    }
    if (
      !puzzle.preBdBriefingSeen
      && puzzle.cc98UploadedEvidenceIds.length === 4
      && ["bd_briefing", "top_ten_rising"].includes(state.ui.libraryFinalsPhase)
    ) {
      startLibraryStory("cc98_evidence_set_completed");
      return;
    }
    if (
      state.ui.libraryFinalsPhase === "pass_ready"
      && puzzle.evictionPassGenerated
      && !puzzle.passBriefingSeen
    ) {
      startLibraryStory("library_seat_release_pass_issued");
      return;
    }
    if (
      state.ui.libraryFinalsPhase === "seat_recovered"
      && puzzle.playerSeated
      && puzzle.nextQuestId === null
    ) {
      startLibraryStory("library_friend_contacted");
    }
  }, [
    startLibraryStory,
    state.ui.libraryFinalsPhase,
    state.ui.libraryFinalsPuzzle.archivedRuleBriefingSeen,
    state.ui.libraryFinalsPuzzle.archivedRuleRead,
    state.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds.length,
    state.ui.libraryFinalsPuzzle.evictionPassGenerated,
    state.ui.libraryFinalsPuzzle.nextQuestId,
    state.ui.libraryFinalsPuzzle.playerSeated,
    state.ui.libraryFinalsPuzzle.passBriefingSeen,
    state.ui.libraryFinalsPuzzle.preBdBriefingSeen
  ]);

  function focusRpg() {
    const focused = document.activeElement;
    if (focused instanceof HTMLElement && phonePaneRef.current?.contains(focused)) focused.blur();
    setActiveSurface("rpg");
  }

  function focusDeveloperCheckpointTarget() {
    setActiveSurface(gameStore.getState().runtimeMode === "rpg" ? "rpg" : "phone");
  }

  function navigateFromTask(quest: QuestViewModel) {
    if (quest.targetSurface === "phone") {
      if (!desktopGameplay) {
        gameStore.setState((current) => ({ ...current, runtimeMode: "phone" }));
      }
      setActiveSurface("phone");
      if (quest.recommendedScene) {
        if (
          quest.recommendedScene === "cc98"
          && ["accepted", "first_wave_failed", "delivered"].includes(
            gameStore.getState().theaterHunt.cc98TicketCommissionPhase
          )
        ) {
          requestCc98Thread("theater-755-ticket-commission");
        }
        router.goTo(quest.recommendedScene);
      }
      return;
    }
    gameStore.setState((current) => ({ ...current, runtimeMode: "rpg" }));
    focusRpg();
  }

  function acknowledgeChapterTwo() {
    gameStore.setState((current) => ({
      ...current,
      ui: {
        ...current.ui,
        seenChapterIntros: current.ui.seenChapterIntros.includes("chapter_two")
          ? current.ui.seenChapterIntros
          : [...current.ui.seenChapterIntros, "chapter_two"]
      }
    }));
    eventBus.emit("chapter_intro_confirmed", { chapter: "chapter_two" });
  }

  const chapterIntro = showChapterTwoIntro ? (
    <section className="chapter-intro-overlay" role="dialog" aria-modal="true" aria-labelledby="chapter-two-title">
      <div>
        <small>CHAPTER 02</small>
        <h1 id="chapter-two-title">第 2 章</h1>
        <p>找到移动的办法</p>
        <button type="button" onClick={acknowledgeChapterTwo}>进入第二章</button>
      </div>
    </section>
  ) : null;

  const libraryStoryLayer = libraryStoryVisible && libraryStorySequence
    ? libraryStorySequence === "library_friend_contacted"
      ? (
          <ChapterThreeOpeningOverlay
            key={libraryStorySequence}
            events={eventBus}
            onFinished={finishLibraryStory}
          />
        )
      : (
          <LibraryStoryOverlay
            key={libraryStorySequence}
            events={eventBus}
            sequenceId={libraryStorySequence}
            onFinished={finishLibraryStory}
          />
        )
    : null;

  if (state.runtimeMode === "rpg") {
    if (desktopGameplay) {
      return (
        <Chapter4PrologueRuntimeGate store={gameStore} events={eventBus}>
          <main
            className={`desktop-gameplay-shell ${state.rpgScene === "qizhen_lake" ? "is-qizhen-lake" : ""}`.trim()}
            data-active-surface={activeSurface}
            data-split={clockSplit ? "clock" : undefined}
          >
            {activeSurface === "rpg" && state.rpgScene !== "duan_yongping_temporal_maze" ? (
              <QuestTaskBar
                state={state}
                events={eventBus}
                router={router}
                variant="desktop"
                onNavigate={navigateFromTask}
              />
            ) : null}
            <section
              ref={phonePaneRef}
              className="desktop-phone-pane"
              aria-label="手机交互区"
              onPointerDownCapture={() => setActiveSurface("phone")}
              onFocusCapture={() => setActiveSurface("phone")}
            >
              <PhoneShell
                state={state}
                router={router}
                events={eventBus}
                embedded
                showTaskBar={activeSurface === "phone"}
                showGlobalLayers={false}
                onTaskNavigate={navigateFromTask}
              >
                <Scene state={state} router={router} events={eventBus} />
              </PhoneShell>
            </section>
            <section
              className="desktop-rpg-pane"
              aria-label="地图交互区"
              onPointerDownCapture={focusRpg}
              onWheelCapture={focusRpg}
              onFocusCapture={focusRpg}
            >
              <Suspense fallback={<main className="rpg-stage is-embedded">Loading RPG runtime</main>}>
                <ActiveRpgGameHost
                  store={gameStore}
                  router={router}
                  events={eventBus}
                  inputBlocked={developerChannelOpen || libraryStoryVisible}
                  keyboardBlocked={activeSurface !== "rpg"}
                  embedded
                  showTaskBar={state.rpgScene === "duan_yongping_temporal_maze"}
                  desktopSplit
                  onFocusPhone={() => setActiveSurface("phone")}
                  onTaskNavigate={navigateFromTask}
                />
              </Suspense>
            </section>
            <PresentationLayer events={eventBus} />
            <ToastLayer events={eventBus} state={state} surface={activeSurface === "phone" ? "phone" : "rpg"} />
            {chapterIntro}
            {libraryStoryLayer}
          </main>
          <DeveloperChannel
            store={gameStore}
            onVisibilityChange={setDeveloperChannelOpen}
            onCheckpointApplied={focusDeveloperCheckpointTarget}
          />
        </Chapter4PrologueRuntimeGate>
      );
    }
    return (
      <Chapter4PrologueRuntimeGate store={gameStore} events={eventBus}>
        <Suspense fallback={<main className="rpg-stage">Loading RPG runtime</main>}>
          <ActiveRpgGameHost
            store={gameStore}
            router={router}
            events={eventBus}
            inputBlocked={developerChannelOpen || libraryStoryVisible}
            onTaskNavigate={navigateFromTask}
          />
        </Suspense>
        <PresentationLayer events={eventBus} />
        <ToastLayer events={eventBus} state={state} surface="rpg" />
        {chapterIntro}
        {libraryStoryLayer}
        <DeveloperChannel
          store={gameStore}
          onVisibilityChange={setDeveloperChannelOpen}
          onCheckpointApplied={focusDeveloperCheckpointTarget}
        />
      </Chapter4PrologueRuntimeGate>
    );
  }

  return (
    <Chapter4PrologueRuntimeGate store={gameStore} events={eventBus}>
      <PhoneShell state={state} router={router} events={eventBus} onTaskNavigate={navigateFromTask}>
        <Scene state={state} router={router} events={eventBus} />
      </PhoneShell>
      {chapterIntro}
      {libraryStoryLayer}
      <DeveloperChannel
        store={gameStore}
        onVisibilityChange={setDeveloperChannelOpen}
        onCheckpointApplied={focusDeveloperCheckpointTarget}
      />
    </Chapter4PrologueRuntimeGate>
  );
}
