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
import { presentationDirector } from "./modules/PresentationDirector";
import { getPhoneScene } from "./scenes/phone/registry";

const router = new SceneRouter(gameStore, eventBus);
const RpgGameHost = lazy(() =>
  import("./scenes/rpg/RpgGameHost").then((module) => ({ default: module.RpgGameHost }))
);

const LIBRARY_STORY_SEQUENCE_BY_EVENT: Record<string, string> = {
  library_route_unlocked: "library_route_unlocked",
  library_entered: "library_entered",
  library_occupied_seat_found: "library_occupied_seat_found",
  cc98_occupation_post_opened: "cc98_occupation_post_opened",
  library_catalog_match_found: "library_catalog_match_found",
  library_bag_nonperson_proof_issued: "library_bag_nonperson_proof_issued",
  tiyi_presence_proof_issued: "tiyi_presence_proof_issued",
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
  const showChapterTwoIntro = access.chapter !== "chapter_one"
    && !state.ui.seenChapterIntros.includes("chapter_two");

  useEffect(() => {
    const detachAudio = audioDirector.attach(eventBus);
    const detachPresentation = presentationDirector.attach(gameStore, eventBus);
    return () => {
      detachPresentation();
      detachAudio();
    };
  }, []);

  useEffect(() => {
    const startStory = (sequenceId: string) => {
      if (libraryStorySequenceRef.current) {
        if (!libraryStoryQueueRef.current.includes(sequenceId)) {
          libraryStoryQueueRef.current.push(sequenceId);
        }
        return;
      }
      libraryStorySequenceRef.current = sequenceId;
      setLibraryStorySequence(sequenceId);
    };

    return eventBus.subscribe((event) => {
      const sequenceId = event.name === "library_story_request"
        ? String(event.payload?.sequenceId ?? "")
        : LIBRARY_STORY_SEQUENCE_BY_EVENT[event.name];
      if (sequenceId) {
        startStory(sequenceId);
      }
    });
  }, []);

  const finishLibraryStory = useCallback(() => {
    const sequenceId = libraryStorySequenceRef.current;
    if (!sequenceId) {
      return;
    }
    eventBus.emit("library_story_finished", { sequenceId });
    const nextSequenceId = libraryStoryQueueRef.current.shift() ?? null;
    if (nextSequenceId) {
      libraryStorySequenceRef.current = nextSequenceId;
      setLibraryStorySequence(nextSequenceId);
      return;
    }
    libraryStorySequenceRef.current = null;
    setLibraryStorySequence(null);
  }, []);

  function focusRpg() {
    const focused = document.activeElement;
    if (focused instanceof HTMLElement && phonePaneRef.current?.contains(focused)) focused.blur();
    setActiveSurface("rpg");
  }

  function navigateFromTask(quest: QuestViewModel) {
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

  const libraryStoryLayer = libraryStorySequence ? (
    <LibraryStoryOverlay
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
            >
              <Suspense fallback={<main className="rpg-stage is-embedded">Loading RPG runtime</main>}>
                <RpgGameHost
                  store={gameStore}
                  router={router}
                  events={eventBus}
                  inputBlocked={developerChannelOpen || libraryStorySequence !== null}
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
            <ToastLayer events={eventBus} />
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
            inputBlocked={developerChannelOpen || libraryStorySequence !== null}
            onTaskNavigate={navigateFromTask}
          />
        </Suspense>
        <PresentationLayer events={eventBus} />
        <ToastLayer events={eventBus} />
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
