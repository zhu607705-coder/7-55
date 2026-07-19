import { lazy, Suspense, useCallback, useEffect, useRef, useState, useSyncExternalStore } from "react";
import { eventBus } from "./core/EventBus";
import { gameStore } from "./core/GameState";
import { SceneRouter } from "./core/SceneRouter";
import { selectFeatureAccess } from "./core/FeatureAccess";
import type { GameState, QuestViewModel } from "./core/types";
import { PhoneShell } from "./components/PhoneShell";
import { DeveloperChannel } from "./components/DeveloperChannel";
import { LibraryStoryOverlay } from "./components/LibraryStoryOverlay";
import { PresentationLayer } from "./components/PresentationLayer";
import { ToastLayer } from "./components/ToastLayer";
import { QuestTaskBar } from "./components/QuestClueStrip";
import { audioDirector } from "./modules/AudioDirector";
import { kit } from "./modules/GameKit";
import { presentationDirector } from "./modules/PresentationDirector";
import { getPhoneScene } from "./scenes/phone/registry";
import { LIBRARY_STORY_SEQUENCES } from "./data/libraryFinalsStory";

const router = new SceneRouter(gameStore, eventBus);
const RpgGameHost = lazy(() =>
  import("./scenes/rpg/RpgGameHost").then((module) => ({ default: module.RpgGameHost }))
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

function getSnapshot(): GameState {
  return gameStore.getState();
}

const DESKTOP_GAMEPLAY_QUERY = "(min-width: 1100px) and (orientation: landscape) and (pointer: fine)";

function useDesktopGameplayLayout(): boolean {
  const [matches, setMatches] = useState(() => (
    typeof window !== "undefined" && typeof window.matchMedia === "function"
      ? window.matchMedia(DESKTOP_GAMEPLAY_QUERY).matches
      : false
  ));

  useEffect(() => {
    if (typeof window.matchMedia !== "function") return undefined;
    const query = window.matchMedia(DESKTOP_GAMEPLAY_QUERY);
    const update = () => setMatches(query.matches);
    update();
    query.addEventListener?.("change", update);
    return () => query.removeEventListener?.("change", update);
  }, []);

  return matches;
}

export function App() {
  const state = useSyncExternalStore(gameStore.subscribe, getSnapshot, getSnapshot);
  const [developerChannelOpen, setDeveloperChannelOpen] = useState(false);
  const [libraryStorySequence, setLibraryStorySequence] = useState<string | null>(null);
  const libraryStorySequenceRef = useRef<string | null>(null);
  const libraryStoryQueueRef = useRef<string[]>([]);
  const [activeSurface, setActiveSurface] = useState<"phone" | "rpg">("rpg");
  const desktopGameplay = useDesktopGameplayLayout();
  const phonePaneRef = useRef<HTMLElement>(null);
  const Scene = getPhoneScene(state.currentScene);
  const access = selectFeatureAccess(state);
  const campusCardInspectionActive = state.actOne.phase === "system_return_required";
  const showChapterTwoIntro = access.chapter !== "chapter_one"
    && !state.ui.seenChapterIntros.includes("chapter_two");
  const libraryStoryVisible = libraryStorySequence !== null && !showChapterTwoIntro;

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
      if (["act2_rpg_entered", "library_entered", "library_reentered"].includes(event.name)) {
        setActiveSurface("rpg");
      }
    });
    return () => {
      detachSurfaceSync();
      detachPresentation();
      detachAudio();
    };
  }, []);

  useEffect(() => eventBus.subscribe((event) => {
    if (event.name === "library_entered" && event.payload?.firstEntry === true) {
      startLibraryStory("library_route_unlocked");
      startLibraryStory("library_entered");
      return;
    }
    const sequenceId = event.name === "library_story_request"
      ? String(event.payload?.sequenceId ?? "")
      : LIBRARY_STORY_SEQUENCE_BY_EVENT[event.name];
    if (sequenceId) {
      startLibraryStory(sequenceId);
    }
  }), [startLibraryStory]);

  useEffect(() => {
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (
      !puzzle.preBdBriefingSeen
      && puzzle.cc98UploadedEvidenceIds.length === 4
      && ["bd_briefing", "top_ten_rising"].includes(state.ui.libraryFinalsPhase)
    ) {
      startLibraryStory("cc98_evidence_set_completed");
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
    state.ui.libraryFinalsPuzzle.cc98UploadedEvidenceIds.length,
    state.ui.libraryFinalsPuzzle.nextQuestId,
    state.ui.libraryFinalsPuzzle.playerSeated,
    state.ui.libraryFinalsPuzzle.preBdBriefingSeen
  ]);

  useEffect(() => {
    const phonePane = phonePaneRef.current;
    if (!phonePane) return;
    if (campusCardInspectionActive) {
      phonePane.setAttribute("inert", "");
      const focused = document.activeElement;
      if (focused instanceof HTMLElement && phonePane.contains(focused)) focused.blur();
      return;
    }
    phonePane.removeAttribute("inert");
  }, [campusCardInspectionActive, desktopGameplay]);

  function focusRpg() {
    const focused = document.activeElement;
    if (focused instanceof HTMLElement && phonePaneRef.current?.contains(focused)) focused.blur();
    setActiveSurface("rpg");
  }

  function navigateFromTask(quest: QuestViewModel) {
    if (campusCardInspectionActive) return;
    if (quest.targetSurface === "phone") {
      if (!desktopGameplay) {
        gameStore.setState((current) => ({ ...current, runtimeMode: "phone" }));
      }
      setActiveSurface("phone");
      if (quest.recommendedScene) router.goTo(quest.recommendedScene);
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

  const libraryStoryLayer = libraryStoryVisible && libraryStorySequence ? (
    <LibraryStoryOverlay
      key={libraryStorySequence}
      events={eventBus}
      sequenceId={libraryStorySequence}
      onFinished={finishLibraryStory}
    />
  ) : null;

  if (state.runtimeMode === "rpg") {
    if (desktopGameplay) {
      return (
        <>
          <main className="desktop-gameplay-shell" data-active-surface={activeSurface}>
            <QuestTaskBar
              state={state}
              events={eventBus}
              router={router}
              variant="desktop"
              onNavigate={navigateFromTask}
            />
            <section
              ref={phonePaneRef}
              className="desktop-phone-pane"
              aria-label="手机交互区"
              aria-hidden={campusCardInspectionActive ? true : undefined}
              onPointerDownCapture={() => setActiveSurface("phone")}
              onFocusCapture={() => setActiveSurface("phone")}
            >
              <PhoneShell
                state={state}
                router={router}
                events={eventBus}
                embedded
                showTaskBar={false}
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
                <RpgGameHost
                  store={gameStore}
                  router={router}
                  events={eventBus}
                  inputBlocked={developerChannelOpen || libraryStoryVisible}
                  keyboardBlocked={activeSurface !== "rpg"}
                  embedded
                  showTaskBar={false}
                  desktopSplit
                  onFocusPhone={() => setActiveSurface("phone")}
                  onTaskNavigate={navigateFromTask}
                />
              </Suspense>
            </section>
            <PresentationLayer events={eventBus} />
            <ToastLayer events={eventBus} state={state} />
            {chapterIntro}
            {libraryStoryLayer}
          </main>
          <DeveloperChannel store={gameStore} onVisibilityChange={setDeveloperChannelOpen} />
        </>
      );
    }
    return (
      <>
        <Suspense fallback={<main className="rpg-stage">Loading RPG runtime</main>}>
          <RpgGameHost
            store={gameStore}
            router={router}
            events={eventBus}
            inputBlocked={developerChannelOpen || libraryStoryVisible}
            onTaskNavigate={navigateFromTask}
          />
        </Suspense>
        <PresentationLayer events={eventBus} />
        <ToastLayer events={eventBus} state={state} />
        {chapterIntro}
        {libraryStoryLayer}
        <DeveloperChannel store={gameStore} onVisibilityChange={setDeveloperChannelOpen} />
      </>
    );
  }

  return (
    <>
      <PhoneShell state={state} router={router} events={eventBus} onTaskNavigate={navigateFromTask}>
        <Scene state={state} router={router} events={eventBus} />
      </PhoneShell>
      {chapterIntro}
      {libraryStoryLayer}
      <DeveloperChannel store={gameStore} onVisibilityChange={setDeveloperChannelOpen} />
    </>
  );
}
