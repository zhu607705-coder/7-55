import { useEffect, useState } from "react";
import lampDarkUrl from "../../assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_dark.png";
import type {
  ChapterFourZhuPersonAnswerId,
  ChapterFourZhuPurposeAnswerId
} from "../../core/types";
import { CHAPTER_FOUR_ZHU_QUESTIONS } from "../../data/ChapterFourAlumniHonorWall";

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

export function ChapterFourExteriorQuestions({
  answered,
  pending,
  feedback = null,
  onSubmit,
  onConfirmationComplete
}: ChapterFourExteriorQuestionsProps) {
  const [purposeAnswer, setPurposeAnswer] = useState<ChapterFourZhuPurposeAnswerId | null>(null);
  const [personAnswer, setPersonAnswer] = useState<ChapterFourZhuPersonAnswerId | null>(null);

  useEffect(() => {
    if (!answered) return;
    const timer = window.setTimeout(onConfirmationComplete, 900);
    return () => window.clearTimeout(timer);
  }, [answered, onConfirmationComplete]);

  return (
    <section
      className="chapter4-exterior-questions"
      role="dialog"
      aria-modal="true"
      aria-labelledby="chapter4-exterior-questions-title"
    >
      <img src={lampDarkUrl} alt="未点亮的灿若星辰灯" />
      <div className="chapter4-exterior-questions__vignette" aria-hidden="true" />
      <div className="chapter4-exterior-questions__panel">
        {answered ? (
          <p className="chapter4-exterior-questions__saved" role="status">回答已保存</p>
        ) : (
          <>
            <header>
              <small>07:55 · 校史墙留下的两项问题</small>
              <h2 id="chapter4-exterior-questions-title">灯仍未点亮</h2>
            </header>
            {[CHAPTER_FOUR_ZHU_QUESTIONS[0], CHAPTER_FOUR_ZHU_QUESTIONS[1]].map((question) => (
              <fieldset key={question.id}>
                <legend>{question.prompt}</legend>
                <div>
                  {question.options.map((option) => {
                    const selected = question.id === "purpose"
                      ? purposeAnswer === option.id
                      : personAnswer === option.id;
                    return (
                      <button
                        key={option.id}
                        type="button"
                        className={selected ? "is-selected" : undefined}
                        aria-pressed={selected}
                        disabled={pending}
                        onClick={() => {
                          if (question.id === "purpose") {
                            setPurposeAnswer(option.id as ChapterFourZhuPurposeAnswerId);
                          } else {
                            setPersonAnswer(option.id as ChapterFourZhuPersonAnswerId);
                          }
                        }}
                      >
                        {option.label}
                      </button>
                    );
                  })}
                </div>
              </fieldset>
            ))}
            {feedback ? <p className="chapter4-exterior-questions__feedback" role="status">{feedback}</p> : null}
            <button
              type="button"
              className="chapter4-exterior-questions__submit"
              disabled={pending || !purposeAnswer || !personAnswer}
              onClick={() => {
                if (purposeAnswer && personAnswer) onSubmit(purposeAnswer, personAnswer);
              }}
            >
              {pending ? "保存中……" : "保存两项回答"}
            </button>
          </>
        )}
      </div>
    </section>
  );
}
