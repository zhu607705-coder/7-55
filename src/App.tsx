import { lazy, Suspense, useEffect, useRef, useState, useSyncExternalStore } from "react";
import { eventBus } from "./core/EventBus";
import { gameStore } from "./core/GameState";
import { SceneRouter } from "./core/SceneRouter";
import { selectFeatureAccess } from "./core/FeatureAccess";
import type { GameState, QuestViewModel } from "./core/types";
import { PhoneShell } from "./components/PhoneShell";
import { DeveloperChannel } from "./components/DeveloperChannel";
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
              onWheelCapture={focusRpg}
              onFocusCapture={focusRpg}
            >
              <Suspense fallback={<main className="rpg-stage is-embedded">Loading RPG runtime</main>}>
                <RpgGameHost
                  store={gameStore}
                  router={router}
                  events={eventBus}
                  inputBlocked={developerChannelOpen}
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
            inputBlocked={developerChannelOpen}
            onTaskNavigate={navigateFromTask}
          />
        </Suspense>
        <PresentationLayer events={eventBus} />
        <ToastLayer events={eventBus} />
        {chapterIntro}
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
      <DeveloperChannel store={gameStore} onVisibilityChange={setDeveloperChannelOpen} />
    </>
  );
}
