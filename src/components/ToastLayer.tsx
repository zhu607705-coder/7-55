import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import type { EventBus } from "../core/EventBus";
import type { GameState } from "../core/types";
import { NoticeQueue, type Notice } from "../core/NoticeQueue";
import { textFeedbackDuration } from "../modules/AudioDirector";
import { GameSubtitleFrame, type GameSubtitleTone } from "./GameSubtitleFrame";

interface ToastLayerProps {
  events: EventBus;
  state: GameState;
  surface?: "phone" | "rpg";
  blocked?: boolean;
}

const SUBTITLE_TONE_BY_TOAST: Readonly<Record<Notice["tone"], GameSubtitleTone>> = {
  system: "system",
  xiaoying: "narrator",
  task: "task"
};

// Phone/RPG surface remounts share transient presentation, never saved progress.
interface Caption {
  id: number;
  text: string;
  tone: GameSubtitleTone;
  speaker?: string;
  durationMs: number;
  deadline: number;
}
interface FeedbackSession { notices: NoticeQueue; caption: Caption | null; nextId: number; }
const sessions = new WeakMap<EventBus, FeedbackSession>();
const SPEAKER_LABELS: Readonly<Record<string, string>> = {
  narrator: "旁白", system: "系统", player: "我", seat022: "022", cleaner: "保洁员", guard: "保安"
};
function sessionFor(events: EventBus): FeedbackSession {
  let session = sessions.get(events);
  if (!session) { session = { notices: new NoticeQueue(), caption: null, nextId: 1 }; sessions.set(events, session); }
  return session;
}

/** One notification at a time; scene-owned dialogue and games keep their space. */
export function ToastLayer({ events, state, surface = "phone", blocked = false }: ToastLayerProps) {
  const [active, setActive] = useState<Notice | null>(null);
  const [caption, setCaption] = useState<Caption | null>(null);
  const session = sessionFor(events);
  const queue = session.notices;
  const suspended = blocked || state.currentScene === "ending";
  const suspendedRef = useRef(suspended);
  suspendedRef.current = suspended;
  const refreshRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    let timer: number | null = null;
    const refresh = () => {
      if (timer !== null) window.clearTimeout(timer);
      timer = null;
      const now = performance.now();
      if (session.caption && session.caption.deadline <= now) session.caption = null;
      const currentCaption = session.caption ? { ...session.caption, durationMs: session.caption.deadline - now } : null;
      setCaption(currentCaption);
      queue.setPaused(suspendedRef.current || document.hidden || Boolean(currentCaption), now);
      const notice = queue.visible(now);
      setActive(notice);
      const remaining = currentCaption?.durationMs ?? notice?.durationMs;
      if (remaining) timer = window.setTimeout(refresh, remaining);
    };
    refreshRef.current = refresh;
    const detach = events.subscribe((event) => {
      if (event.name !== "toast") {
        return;
      }
      const text = String(event.payload?.text ?? "");
      const requestedTone = event.payload?.tone;
      const tone: Notice["tone"] = requestedTone === "xiaoying" || requestedTone === "task" ? requestedTone : "system";
      if (!text) {
        return;
      }

      const id = session.nextId++;
      const requestedDuration = Number(event.payload?.durationMs);
      const durationMs = Number.isFinite(requestedDuration) && requestedDuration > 0 ? requestedDuration : textFeedbackDuration(text);
      if (event.payload?.presentationRole === "dialogue") {
        // Authored speech stays on its own clock; it must not wait in a toast FIFO.
        const rawSpeaker = String(event.payload.speaker ?? "system");
        session.caption = { id, text, durationMs, deadline: performance.now() + durationMs,
          tone: rawSpeaker === "narrator" ? "narrator" : rawSpeaker === "player" ? "player" : "system",
          speaker: SPEAKER_LABELS[rawSpeaker] ?? "系统" };
        refresh();
        return;
      }
      queue.enqueue({ id, text, tone, durationMs }, performance.now());
      refresh();
    });
    document.addEventListener("visibilitychange", refresh);
    refresh();
    return () => {
      detach();
      document.removeEventListener("visibilitychange", refresh);
      if (timer !== null) window.clearTimeout(timer);
      queue.setPaused(true, performance.now());
      refreshRef.current = null;
    };
  }, [events, queue, session]);

  useEffect(() => { refreshRef.current?.(); }, [suspended]);

  if ((!active && !caption) || suspended) return null;

  const text = caption?.text ?? active!.text;
  const tone = caption?.tone ?? SUBTITLE_TONE_BY_TOAST[active!.tone];
  const speaker = caption?.speaker ?? (active?.tone === "xiaoying" ? "小影" : undefined);

  const layer = (
    <div className={`${caption ? "dialogue-caption-layer" : "toast-layer"} subtitle-layer--${surface}`} data-presentation-role={caption ? "dialogue" : "notification"} role="status" aria-live="polite" aria-atomic="true">
        <GameSubtitleFrame
          key={caption?.id ?? active!.id}
          text={text}
          tone={tone}
          speaker={speaker}
          state={state}
          durationMs={caption?.durationMs ?? active!.durationMs}
          className={caption ? "story-caption" : `px-toast tone-${active!.tone}`}
        />
    </div>
  );

  const phoneFrame = surface === "phone" ? document.querySelector(".phone-frame") : null;
  return phoneFrame ? createPortal(layer, phoneFrame) : layer;
}
