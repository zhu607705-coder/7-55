import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { EventBus } from "../core/EventBus";
import {
  LIBRARY_STORY_SEQUENCES,
  libraryStoryLineKey
} from "../data/libraryFinalsStory";
import { textFeedbackDuration } from "../modules/AudioDirector";
import { PRESENTATION_CUE_EVENT } from "../modules/PresentationDirector";
import { GameSubtitleContent } from "./GameSubtitleFrame";

interface LibraryStoryOverlayProps {
  events: EventBus;
  sequenceId: string;
  onFinished: () => void;
}

const CONFIRMATION_REQUIRED_SEQUENCES = new Set([
  "cc98_evidence_set_completed"
]);

/** 第二章剧情对白层：点击任意位置逐句快进，并拦住底层游戏操作。 */
export function LibraryStoryOverlay({ events, sequenceId, onFinished }: LibraryStoryOverlayProps) {
  const sequence = LIBRARY_STORY_SEQUENCES[sequenceId] ?? [];
  const [lineIndex, setLineIndex] = useState(0);
  const overlayRef = useRef<HTMLElement>(null);
  const line = sequence[lineIndex];
  const lineKey = useMemo(
    () => line ? libraryStoryLineKey(sequenceId, lineIndex) : "",
    [line, lineIndex, sequenceId]
  );
  const durationMs = line ? textFeedbackDuration(line.text) : 0;
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
    overlayRef.current?.focus();
  }, [sequenceId]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      if (event.key === "Tab") {
        overlayRef.current?.focus();
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

  const subtitleTone = line.speaker === "玩家" ? "player" : line.speaker === "旁白" ? "narrator" : "system";

  return (
    <section
      ref={overlayRef}
      className="library-story-overlay"
      role="dialog"
      aria-modal="true"
      aria-label="第二章剧情对白，点击任意位置继续"
      tabIndex={-1}
      onPointerDown={(event) => event.stopPropagation()}
      onClick={(event) => {
        event.stopPropagation();
        advance("user");
      }}
    >
      <div
        key={lineKey}
        className={`library-story-dialogue game-subtitle-frame subtitle-tone-${subtitleTone} is-line-entering`}
      >
        <GameSubtitleContent speaker={line.speaker} text={line.text} />
      </div>
    </section>
  );
}
