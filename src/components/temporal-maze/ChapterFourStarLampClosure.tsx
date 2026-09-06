import { ChapterFourStarLampPlayback } from "./ChapterFourStarLampPlayback";
import { ChapterFourExteriorQuestions } from "./ChapterFourExteriorQuestions";
import { useCallback, useEffect, useRef, useState } from "react";
import lampCoreUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_core.png";
import lampDarkUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png";
import lampGlowUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_glow.png";
import lampLedsUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_leds.png";
import lampOutlineUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_outline.png";
import type {
  ChapterFourZhuPersonAnswerId,
  ChapterFourZhuPurposeAnswerId,
  ChapterFourZhuQuestionAnswers
} from "../../core/types";

export { CHAPTER_FOUR_STAR_LAMP_SEQUENCE_DURATION_MS } from "./ChapterFourStarLampPlayback";
export const CHAPTER_FOUR_STAR_LAMP_FINAL_MESSAGE =
  "从此，你将与历史上众多灿若星辰的名字一起，共享'浙大人'这个无上荣光的称号！";

type ChapterFourStarLampQuestionOption<AnswerId extends string> = Readonly<{
  id: AnswerId;
  label: string;
}>;

export type ChapterFourStarLampQuestions = readonly [
  purpose: Readonly<{
    id: "purpose";
    prompt: string;
    options: readonly ChapterFourStarLampQuestionOption<ChapterFourZhuPurposeAnswerId>[];
  }>,
  person: Readonly<{
    id: "person";
    prompt: string;
    options: readonly ChapterFourStarLampQuestionOption<ChapterFourZhuPersonAnswerId>[];
  }>
];

export type ChapterFourStarLampSavedAnswers = Readonly<{
  purpose: ChapterFourZhuPurposeAnswerId;
  person: ChapterFourZhuPersonAnswerId;
}>;

export interface ChapterFourStarLampClosureProps {
  sessionId: string;
  questions: ChapterFourStarLampQuestions;
  selectedAnswers: ChapterFourZhuQuestionAnswers;
  answersSaved: boolean;
  saving?: boolean;
  saveError?: string | null;
  feedback?: string | null;
  onSaveAnswers: (answers: ChapterFourStarLampSavedAnswers) => void;
  onComplete: (sessionId: string) => void;
}

type ChapterFourStarLampStage = "questions" | "playback" | "final";

export function ChapterFourStarLampClosure({
  sessionId,
  questions,
  selectedAnswers,
  answersSaved,
  saving = false,
  saveError = null,
  feedback = null,
  onSaveAnswers,
  onComplete
}: ChapterFourStarLampClosureProps) {
  const [stage, setStage] = useState<ChapterFourStarLampStage>("questions");
  const dialogRef = useRef<HTMLElement | null>(null);
  const completedRef = useRef(false);

  const [purposeQuestion, personQuestion] = questions;
  const savedAnswers = completeAnswers(selectedAnswers);

  useEffect(() => {
    completedRef.current = false;
    setStage("questions");
  }, [sessionId]);

  const submitQuestions = useCallback((
    purpose: ChapterFourZhuPurposeAnswerId,
    person: ChapterFourZhuPersonAnswerId
  ) => onSaveAnswers({ purpose, person }), [onSaveAnswers]);

  const confirmQuestions = useCallback(() => {
    if (!answersSaved || !selectedAnswers.purpose || !selectedAnswers.person) return;
    setStage((current) => current === "questions" ? "playback" : current);
  }, [answersSaved, selectedAnswers.person, selectedAnswers.purpose]);

  const finishPlayback = useCallback(() => {
    setStage((current) => current === "playback" ? "final" : current);
  }, []);


  const completeOnce = useCallback(() => {
    if (stage !== "final" || completedRef.current) return;
    completedRef.current = true;
    onComplete(sessionId);
  }, [onComplete, sessionId, stage]);

  useEffect(() => {
    if (stage !== "final") return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.repeat || (event.key !== "Enter" && event.key !== " ")) return;
      event.preventDefault();
      completeOnce();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [completeOnce, stage]);

  useEffect(() => {
    const root = dialogRef.current;
    if (!root) return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Tab") return;
      const focusables = Array.from(
        root.querySelectorAll<HTMLElement>(
          'button:not(:disabled), [href], input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex]:not([tabindex="-1"])'
        )
      ).filter((element) => !element.hasAttribute("aria-hidden"));
      if (focusables.length === 0) {
        event.preventDefault();
        root.focus({ preventScroll: true });
        return;
      }
      const currentIndex = focusables.indexOf(document.activeElement as HTMLElement);
      const nextIndex = event.shiftKey
        ? (currentIndex <= 0 ? focusables.length - 1 : currentIndex - 1)
        : (currentIndex === -1 || currentIndex >= focusables.length - 1 ? 0 : currentIndex + 1);
      event.preventDefault();
      focusables[nextIndex]?.focus();
    };
    root.addEventListener("keydown", handleKeyDown);
    return () => root.removeEventListener("keydown", handleKeyDown);
  }, [stage]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    const focusTarget = stage === "final"
        ? dialog.querySelector<HTMLButtonElement>(".chapter4-star-lamp-closure__final > button")
        : null;
    (focusTarget ?? dialog).focus({ preventScroll: true });
  }, [stage]);

  const displayedAnswers = savedAnswers;
  const purposeLabel = displayedAnswers
    ? labelForAnswer(purposeQuestion.options, displayedAnswers.purpose)
    : "";
  const personLabel = displayedAnswers
    ? labelForAnswer(personQuestion.options, displayedAnswers.person)
    : "";

  if (stage === "questions") {
    return <ChapterFourExteriorQuestions
      key={sessionId}
      answered={answersSaved && savedAnswers !== null}
      pending={saving}
      feedback={saveError}
      onSubmit={submitQuestions}
      onConfirmationComplete={confirmQuestions}
    />;
  }

  if (stage === "playback") {
    return <ChapterFourStarLampPlayback sessionId={sessionId} feedback={feedback} onComplete={finishPlayback} />;
  }

  return (
    <section
      ref={dialogRef}
      className={`chapter4-star-lamp-closure is-${stage}`}
      role="dialog"
      aria-modal="true"
      aria-label="灿若星辰灯点亮"
      aria-busy={saving ? "true" : "false"}
      data-session-id={sessionId}
      data-stage={stage}
      tabIndex={-1}
    >
      <LampLayers stage={stage} onPlaybackFinished={finishPlayback} />
      <div className="chapter4-star-lamp-closure__vignette" aria-hidden="true" />

      {stage === "final" ? (
        <div className="chapter4-star-lamp-closure__final" aria-live="polite">
          <header>
            <strong>07:55</strong>
            <span>灿若星辰</span>
          </header>
          <p className="chapter4-star-lamp-closure__final-message">
            {CHAPTER_FOUR_STAR_LAMP_FINAL_MESSAGE}
          </p>
          <dl className="chapter4-star-lamp-closure__answer-summary">
            <div>
              <dt>求学所向</dt>
              <dd>{purposeLabel}</dd>
            </div>
            <div>
              <dt>成人所守</dt>
              <dd>{personLabel}</dd>
            </div>
          </dl>
          {feedback ? (
            <p className="chapter4-star-lamp-closure__final-feedback" role="status">
              {feedback}
            </p>
          ) : null}
          <button type="button" onClick={completeOnce}>继续</button>
          <small>按 Space 或 Enter 继续</small>
        </div>
      ) : null}
    </section>
  );
}

function LampLayers({
  stage,
  onPlaybackFinished
}: Readonly<{
  stage: ChapterFourStarLampStage;
  onPlaybackFinished: () => void;
}>) {
  const cameraState = stage === "playback"
    ? "is-playback"
    : stage === "final"
      ? "is-final"
      : "is-unlit";
  return (
    <div
      className={`chapter4-star-lamp-closure__camera ${cameraState}`}
      aria-hidden="true"
      onAnimationEnd={(event) => {
        if (stage === "playback"
          && event.currentTarget === event.target
          && (event.animationName === "chapter4-star-lamp-camera"
            || event.animationName === "chapter4-star-lamp-camera-reduced")) {
          onPlaybackFinished();
        }
      }}
    >
      <img className="chapter4-star-lamp-closure__layer is-dark" src={lampDarkUrl} alt="" />
      <img className="chapter4-star-lamp-closure__layer is-outline" src={lampOutlineUrl} alt="" />
      <img className="chapter4-star-lamp-closure__layer is-glow" src={lampGlowUrl} alt="" />
      <img className="chapter4-star-lamp-closure__layer is-core" src={lampCoreUrl} alt="" />
      <img className="chapter4-star-lamp-closure__layer is-leds" src={lampLedsUrl} alt="" />
      <div className="chapter4-star-lamp-closure__flare" />
    </div>
  );
}

function completeAnswers(
  answers: ChapterFourZhuQuestionAnswers
): ChapterFourStarLampSavedAnswers | null {
  if (!answers.purpose || !answers.person) return null;
  return { purpose: answers.purpose, person: answers.person };
}

function labelForAnswer<AnswerId extends string>(
  options: readonly ChapterFourStarLampQuestionOption<AnswerId>[],
  answer: AnswerId
): string {
  return options.find((option) => option.id === answer)?.label ?? answer;
}
