import { useEffect, useRef, useState } from "react";
import type { EventBus } from "../../core/EventBus";

interface ChapterFourStairPuzzleOverlayProps {
  events: EventBus;
  feedback: string | null;
  onComplete: () => void;
  onExit: () => void;
}

export function ChapterFourStairPuzzleOverlay({
  events,
  feedback,
  onComplete,
  onExit
}: ChapterFourStairPuzzleOverlayProps) {
  const rootRef = useRef<HTMLDivElement | null>(null);
  const onCompleteRef = useRef(onComplete);
  const [status, setStatus] = useState<"loading" | "ready" | "failed">("loading");
  onCompleteRef.current = onComplete;

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    let disposed = false;
    let disposeDemo: (() => void) | null = null;
    void import("../../tools/ChapterFourMonumentStairDemo")
      .then(({ mountChapterFourMonumentStairDemo }) => {
        if (disposed) return;
        disposeDemo = mountChapterFourMonumentStairDemo(root, {
          onComplete: () => onCompleteRef.current(),
          subscribeDirection: (listener) => events.subscribe((event) => {
            if (event.name !== "rpg_direction_changed") return;
            listener({
              x: Number(event.payload?.x ?? 0),
              y: Number(event.payload?.y ?? 0)
            });
          })
        });
        setStatus("ready");
      })
      .catch((error: unknown) => {
        console.error("[chapter4-stair] mount failed", error);
        if (!disposed) setStatus("failed");
      });
    return () => {
      disposed = true;
      disposeDemo?.();
      root.replaceChildren();
    };
  }, [events]);

  return (
    <section className="rpg-stair3d-host" aria-label="错位楼梯空间校准" data-stair-status={status}>
      <div id="stair-demo" ref={rootRef} />
      {status === "loading" ? <p className="rpg-stair3d-status">正在载入楼梯空间…</p> : null}
      {status === "failed" ? (
        <div className="rpg-stair3d-error" role="alert">
          <strong>楼梯空间启动失败</strong>
          <span>返回三楼后可以重新进入。</span>
        </div>
      ) : null}
      {feedback ? <p className="rpg-stair3d-feedback" role="status">{feedback}</p> : null}
      <button className="rpg-stair3d-exit" type="button" onClick={onExit}>返回三楼</button>
    </section>
  );
}
