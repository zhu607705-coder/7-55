import { useEffect, useState } from "react";
import type { CSSProperties } from "react";
import type { EventBus } from "../core/EventBus";
import {
  resolvePresentationCue,
  type ResolvedPresentationCue
} from "../data/presentation-cues";
import { PRESENTATION_CUE_EVENT } from "../modules/PresentationDirector";
import { setPresentationRuntimeSnapshot } from "../modules/PresentationRuntime";

interface PresentationLayerProps {
  events: EventBus;
}

interface ActivePresentationCue extends ResolvedPresentationCue {
  instanceId: number;
}

export function PresentationLayer({ events }: PresentationLayerProps) {
  const [active, setActive] = useState<ActivePresentationCue | null>(null);

  useEffect(() => {
    let current: ActivePresentationCue | null = null;
    let timer: number | null = null;
    let nextId = 1;
    const queue: ActivePresentationCue[] = [];

    const start = (cue: ActivePresentationCue) => {
      if (timer !== null) {
        window.clearTimeout(timer);
      }
      current = cue;
      setActive(cue);
      setPresentationRuntimeSnapshot({
        cueId: cue.id,
        kind: cue.kind,
        title: cue.title,
        mark: cue.mark
      });
      timer = window.setTimeout(() => {
        timer = null;
        current = null;
        setActive(null);
        setPresentationRuntimeSnapshot(null);
        const next = queue.shift();
        if (next) {
          start(next);
        }
      }, cue.durationMs);
    };

    const unsubscribe = events.subscribe((event) => {
      if (event.name !== PRESENTATION_CUE_EVENT) {
        return;
      }
      const cueId = String(event.payload?.cueId ?? "");
      const resolved = resolvePresentationCue(cueId, event.payload);
      if (!resolved) {
        return;
      }
      const cue = { ...resolved, instanceId: nextId++ };

      if (current?.id === cue.id && cue.priority < 3) {
        return;
      }
      if (cue.priority === 3) {
        queue.length = 0;
        start(cue);
        return;
      }
      if (!current) {
        start(cue);
        return;
      }
      if (cue.priority === 1 && current.priority >= 2) {
        return;
      }
      queue.push(cue);
      if (queue.length > 4) {
        queue.shift();
      }
    });

    return () => {
      unsubscribe();
      if (timer !== null) {
        window.clearTimeout(timer);
      }
      queue.length = 0;
      setPresentationRuntimeSnapshot(null);
    };
  }, [events]);

  if (!active) {
    return null;
  }

  const style = { "--presentation-duration": `${active.durationMs}ms` } as CSSProperties;
  return (
    <div
      className={`presentation-layer cue-${active.kind}`}
      style={style}
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      <section key={active.instanceId} className="presentation-cue" data-cue-id={active.id}>
        <div className="presentation-pixels" aria-hidden="true">
          <i /><i /><i /><i /><i /><i />
        </div>
        {active.kind === "route" ? (
          <div className="presentation-route" aria-hidden="true">
            <i><b>记录 A</b></i><span /><i><b>记录 B</b></i><span /><i><b>记录 C</b></i>
          </div>
        ) : null}
        <div className="presentation-panel">
          <small>{active.kind === "chapter" || active.kind === "result" ? "7:55 SYSTEM" : "TASK UPDATE"}</small>
          <em>{active.mark}</em>
          <strong>{active.title}</strong>
          <p>{active.detail}</p>
        </div>
      </section>
    </div>
  );
}
