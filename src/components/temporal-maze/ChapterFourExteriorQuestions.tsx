import { useEffect, useMemo, useState, type CSSProperties } from "react";
import lampDarkUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png";
import type {
  ChapterFourZhuPersonAnswerId,
  ChapterFourZhuPurposeAnswerId
} from "../../core/types";
import { CHAPTER_FOUR_ZHU_QUESTIONS } from "../../data/ChapterFourAlumniHonorWall";
import { useMediaQuery } from "../useMediaQuery";

interface ChapterFourExteriorQuestionsProps {
  answered: boolean;
  pending: boolean;
  feedback?: string | null;
  onSubmit: (
    purposeAnswer: ChapterFourZhuPurposeAnswerId,
    personAnswer: ChapterFourZhuPersonAnswerId
  ) => void;
  onConfirmationComplete: () => void;
}

type QuestionStage =
  | "purpose_entering"
  | "purpose_ready"
  | "purpose_dissolving"
  | "person_entering"
  | "person_ready"
  | "person_dissolving"
  | "submitting";

interface QuestionSparkStyle extends CSSProperties {
  "--question-spark-dx": string;
  "--question-spark-dy": string;
  "--question-spark-delay": string;
  "--question-spark-size": string;
}

const QUESTION_ENTER_DURATION_MS = 1150;
const QUESTION_DISSOLVE_DURATION_MS = 980;

const QUESTION_SPARKS = Object.freeze(Array.from({ length: 54 }, (_, index) => {
  const angle = ((index * 137.508) % 360) * (Math.PI / 180);
  const distance = 48 + (index % 9) * 13;
  return {
    id: index,
    left: 4 + ((index * 37) % 92),
    top: 8 + ((index * 53) % 84),
    dx: Math.cos(angle) * distance,
    dy: Math.sin(angle) * distance,
    delay: (index % 12) * 24,
    size: 2 + (index % 4)
  };
}));

export function ChapterFourExteriorQuestions({
  answered,
  pending,
  feedback = null,
  onSubmit,
  onConfirmationComplete
}: ChapterFourExteriorQuestionsProps) {
  const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const [purposeAnswer, setPurposeAnswer] = useState<ChapterFourZhuPurposeAnswerId | null>(null);
  const [personAnswer, setPersonAnswer] = useState<ChapterFourZhuPersonAnswerId | null>(null);
  const [stage, setStage] = useState<QuestionStage>("purpose_entering");

  const questionIndex = stage.startsWith("person") ? 1 : 0;
  const question = CHAPTER_FOUR_ZHU_QUESTIONS[questionIndex];
  const entering = stage.endsWith("entering");
  const ready = stage.endsWith("ready");
  const dissolving = stage.endsWith("dissolving");
  const selectedAnswer = question.id === "purpose" ? purposeAnswer : personAnswer;
  const progressText = questionIndex === 0 ? "第一问 · 01 / 02" : "第二问 · 02 / 02";

  const sparkStyles = useMemo(() => QUESTION_SPARKS.map((spark) => ({
    id: spark.id,
    left: `${spark.left}%`,
    top: `${spark.top}%`,
    style: {
      "--question-spark-dx": `${spark.dx.toFixed(1)}px`,
      "--question-spark-dy": `${spark.dy.toFixed(1)}px`,
      "--question-spark-delay": `${spark.delay}ms`,
      "--question-spark-size": `${spark.size}px`
    } satisfies QuestionSparkStyle
  })), []);

  useEffect(() => {
    if (answered || !entering) return;
    const timer = window.setTimeout(
      () => setStage(questionIndex === 0 ? "purpose_ready" : "person_ready"),
      reducedMotion ? 120 : QUESTION_ENTER_DURATION_MS
    );
    return () => window.clearTimeout(timer);
  }, [answered, entering, questionIndex, reducedMotion]);

  useEffect(() => {
    if (answered || !dissolving) return;
    const timer = window.setTimeout(() => {
      if (stage === "purpose_dissolving") {
        setStage("person_entering");
        return;
      }
      if (!purposeAnswer || !personAnswer) return;
      setStage("submitting");
      onSubmit(purposeAnswer, personAnswer);
    }, reducedMotion ? 160 : QUESTION_DISSOLVE_DURATION_MS);
    return () => window.clearTimeout(timer);
  }, [answered, dissolving, onSubmit, personAnswer, purposeAnswer, reducedMotion, stage]);

  useEffect(() => {
    if (answered || stage !== "submitting" || pending || !feedback || feedback === "回答已保存") return;
    setStage("person_entering");
  }, [answered, feedback, pending, stage]);

  useEffect(() => {
    if (!answered) return;
    const timer = window.setTimeout(onConfirmationComplete, reducedMotion ? 240 : 1100);
    return () => window.clearTimeout(timer);
  }, [answered, onConfirmationComplete, reducedMotion]);

  const selectAnswer = (optionId: string) => {
    if (!ready || pending) return;
    if (question.id === "purpose") {
      setPurposeAnswer(optionId as ChapterFourZhuPurposeAnswerId);
      setStage("purpose_dissolving");
      return;
    }
    setPersonAnswer(optionId as ChapterFourZhuPersonAnswerId);
    setStage("person_dissolving");
  };

  return (
    <section
      className="chapter4-exterior-questions"
      role="dialog"
      aria-modal="true"
      aria-labelledby="chapter4-exterior-questions-title"
      data-question-stage={answered ? "answered" : stage}
    >
      <img src={lampDarkUrl} alt="未点亮的灿若星辰灯" />
      <div className="chapter4-exterior-questions__vignette" aria-hidden="true" />
      <div className="chapter4-exterior-questions__ambient-stars" aria-hidden="true" />
      <div className="chapter4-exterior-questions__panel">
        {answered ? (
          <div className="chapter4-exterior-questions__saved-wrap">
            <div className="chapter4-exterior-questions__sparks is-final" aria-hidden="true">
              {sparkStyles.map((spark) => (
                <i key={spark.id} style={{ left: spark.left, top: spark.top, ...spark.style }} />
              ))}
            </div>
            <p className="chapter4-exterior-questions__saved" role="status">回答已保存</p>
          </div>
        ) : stage === "submitting" ? (
          <div className="chapter4-exterior-questions__submitting" role="status">
            <span aria-hidden="true">✦</span>
            <strong>{pending ? "正在保存两项回答" : "正在确认回答"}</strong>
            {feedback ? <small>{feedback}</small> : null}
          </div>
        ) : (
          <>
            <header>
              <small>07:55 · 校史墙留下的两项问题</small>
              <h2 id="chapter4-exterior-questions-title">灯仍未点亮</h2>
            </header>
            <div
              className={`chapter4-exterior-questions__question${entering ? " is-entering" : ""}${dissolving ? " is-dissolving" : ""}`}
              key={question.id}
            >
              <div
                className={`chapter4-exterior-questions__sparks${entering ? " is-entering" : ""}${dissolving ? " is-dissolving" : ""}`}
                aria-hidden="true"
              >
                {sparkStyles.map((spark) => (
                  <i key={spark.id} style={{ left: spark.left, top: spark.top, ...spark.style }} />
                ))}
              </div>
              <div className="chapter4-exterior-questions__question-content">
                <p className="chapter4-exterior-questions__progress">{progressText}</p>
                <fieldset disabled={!ready || pending}>
                  <legend>{question.prompt}</legend>
                  <div>
                    {question.options.map((option) => {
                      const selected = selectedAnswer === option.id;
                      return (
                        <button
                          key={option.id}
                          type="button"
                          className={selected ? "is-selected" : undefined}
                          aria-pressed={selected}
                          onClick={() => selectAnswer(option.id)}
                        >
                          {option.label}
                        </button>
                      );
                    })}
                  </div>
                </fieldset>
                <p className="chapter4-exterior-questions__instruction">
                  {ready ? "选择你的回答" : dissolving ? "星光粒子消散中" : "问题正在浮现"}
                </p>
              </div>
            </div>
            {feedback ? <p className="chapter4-exterior-questions__feedback" role="status">{feedback}</p> : null}
            <p className="chapter4-exterior-questions__sr-status" aria-live="polite">
              {dissolving ? `${question.prompt}回答完成` : `${question.prompt}正在显示`}
            </p>
          </>
        )}
      </div>
    </section>
  );
}
