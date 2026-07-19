import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { EventBus } from "../core/EventBus";
import {
  LIBRARY_STORY_SEQUENCES,
  libraryStoryLineKey
} from "../data/libraryFinalsStory";
import { textFeedbackDuration } from "../modules/AudioDirector";
import { PRESENTATION_CUE_EVENT } from "../modules/PresentationDirector";

interface LibraryStoryOverlayProps {
  events: EventBus;
  sequenceId: string;
  onFinished: () => void;
}

const CONFIRMATION_REQUIRED_SEQUENCES = new Set([
  "cc98_evidence_set_completed",
  "library_friend_contacted"
]);

/** 第二章剧情对白层：剧情期间吞掉底层操作，只保留逐句快进。 */
export function LibraryStoryOverlay({ events, sequenceId, onFinished }: LibraryStoryOverlayProps) {
  const sequence = LIBRARY_STORY_SEQUENCES[sequenceId] ?? [];
  const [lineIndex, setLineIndex] = useState(0);
  const continueButtonRef = useRef<HTMLButtonElement>(null);
  const line = sequence[lineIndex];
  const lineKey = useMemo(
    () => line ? libraryStoryLineKey(sequenceId, lineIndex) : "",
    [line, lineIndex, sequenceId]
  );
  const durationMs = line ? textFeedbackDuration(line.text) : 0;
  const finalLine = lineIndex >= sequence.length - 1;
  const requiresConfirmation = CONFIRMATION_REQUIRED_SEQUENCES.has(sequenceId);

  const advance = useCallback((source: "timer" | "user") => {
    if (lineIndex >= sequence.length - 1) {
      if (source === "timer" && requiresConfirmation) {
        return;
      }
      onFinished();
      return;
    }
    setLineIndex(lineIndex + 1);
  }, [lineIndex, onFinished, requiresConfirmation, sequence.length]);

  useEffect(() => {
    setLineIndex(0);
  }, [sequenceId]);

  useEffect(() => {
    if (!line || !lineKey) {
      onFinished();
      return undefined;
    }

    events.emit(PRESENTATION_CUE_EVENT, {
      cueId: "library_story_line",
      subtitleKey: lineKey
    });
    const timer = window.setTimeout(() => advance("timer"), durationMs);
    return () => window.clearTimeout(timer);
  }, [advance, durationMs, events, line, lineKey, onFinished]);

  useEffect(() => {
    continueButtonRef.current?.focus();
  }, [sequenceId]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      if (event.key === "Tab") {
        continueButtonRef.current?.focus();
        return;
      }
      if (event.key !== "Enter" && event.key !== " ") {
        return;
      }
      advance("user");
    };
    window.addEventListener("keydown", onKeyDown, true);
    return () => window.removeEventListener("keydown", onKeyDown, true);
  }, [advance]);

  if (!line) {
    return null;
  }

  const speakerClass = line.speaker === "玩家" ? "is-player" : line.speaker === "旁白" ? "is-narrator" : "is-system";
  const subtitleTone = line.speaker === "玩家" ? "player" : line.speaker === "旁白" ? "narrator" : "system";

  return (
    <section className="library-story-overlay" role="dialog" aria-modal="true" aria-label="第二章剧情对白">
      <div
        key={lineKey}
        className={`library-story-dialogue game-subtitle-frame subtitle-tone-${subtitleTone} is-line-entering`}
      >
        <div className="library-story-dialogue-header">
          <small>剧情播放中 · {lineIndex + 1}/{sequence.length}</small>
          <span aria-hidden="true">{finalLine && requiresConfirmation ? "等待确认" : "自动播放 · 可快进"}</span>
        </div>
        <div className={`library-story-dialogue-box ${speakerClass}`}>
          <strong className="game-subtitle-speaker">{line.speaker}</strong>
          <p>{line.text}</p>
        </div>
        <div className="library-story-dialogue-actions">
          <span>操作已暂停 · Enter / Space</span>
          <button ref={continueButtonRef} type="button" onClick={() => advance("user")}>
            {finalLine && requiresConfirmation ? "确认并继续" : finalLine ? "继续" : "快进"} ›
          </button>
        </div>
      </div>
    </section>
  );
}
