import { useEffect, useRef, useState, type CSSProperties } from "react";
import type { EventBus } from "../core/EventBus";
import type { GameState } from "../core/types";
import { RPG_HUD_LAYOUT } from "../scenes/rpg/RpgHudLayout";
import { GameSubtitleFrame, type GameSubtitleTone } from "./GameSubtitleFrame";

interface RpgSubtitleLayerProps {
  events: EventBus;
  state: GameState;
  blocked?: boolean;
}

interface ActiveRpgSubtitle {
  id: number;
  text: string;
  tone: GameSubtitleTone;
  durationMs: number;
}

const RPG_SUBTITLE_TONES = new Set<GameSubtitleTone>([
  "system",
  "narrator",
  "task",
  "player",
  "success",
  "error",
  "broadcast"
]);

export function RpgSubtitleLayer({ events, state, blocked = false }: RpgSubtitleLayerProps) {
  const [active, setActive] = useState<ActiveRpgSubtitle | null>(null);
  const nextId = useRef(1);

  useEffect(() => {
    let timer: number | null = null;
    const clear = () => {
      if (timer !== null) window.clearTimeout(timer);
      timer = null;
      setActive(null);
    };
    const detach = events.subscribe((event) => {
      if (event.name === "rpg_subtitle_clear") {
        clear();
        return;
      }
      if (event.name !== "rpg_subtitle") return;
      const text = String(event.payload?.text ?? "");
      if (!text) return;
      const requestedTone = String(event.payload?.tone ?? "system") as GameSubtitleTone;
      const tone = RPG_SUBTITLE_TONES.has(requestedTone) ? requestedTone : "system";
      const requestedDuration = Number(event.payload?.durationMs);
      const durationMs = Number.isFinite(requestedDuration) && requestedDuration > 0
        ? requestedDuration
        : tone === "task" ? 4200 : 3000;
      if (timer !== null) window.clearTimeout(timer);
      const subtitle = { id: nextId.current++, text, tone, durationMs };
      setActive(subtitle);
      timer = window.setTimeout(() => {
        timer = null;
        setActive((current) => current?.id === subtitle.id ? null : current);
      }, durationMs);
    });
    return () => {
      detach();
      if (timer !== null) window.clearTimeout(timer);
    };
  }, [events]);

  useEffect(() => {
    if (blocked) setActive(null);
  }, [blocked]);

  if (!active || blocked) return null;

  return (
    <div
      className="rpg-subtitle-layer"
      style={{ "--rpg-subtitle-bottom": `${RPG_HUD_LAYOUT.subtitleBottomInset}px` } as CSSProperties}
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      <GameSubtitleFrame
        key={active.id}
        text={active.text}
        tone={active.tone}
        state={state}
        durationMs={active.durationMs}
      />
    </div>
  );
}
