import { useEffect, useRef, useState } from "react";
import type { KeyboardEvent as ReactKeyboardEvent } from "react";
import type { ChapterFourActionResult } from "../../modules/ChapterFourTemporalMazeController";
import { CHAPTER_FOUR_MAZE_IDS } from "../../modules/ChapterFourMazeProjection";
import "../../styles/wayfinding-board.css";

export type WayfindingFragmentId = typeof CHAPTER_FOUR_MAZE_IDS.fragments[number];
export type WayfindingBoardEntry = WayfindingFragmentId | "empty";

interface WayfindingBoardGameProps {
  onConfirm: (order: readonly WayfindingBoardEntry[]) => ChapterFourActionResult;
  onCancel: () => void;
}

type WayfindingSlot = WayfindingFragmentId | null;

const FRAGMENT_LABELS: Record<WayfindingFragmentId, string> = {
  a2_fragment_west: "碎片 A · 箭头端",
  a2_fragment_east: "碎片 B · 2F 字样端"
};

const INITIAL_SLOTS: readonly WayfindingSlot[] = [
  CHAPTER_FOUR_MAZE_IDS.fragments[1],
  CHAPTER_FOUR_MAZE_IDS.fragments[0],
  null
];

function feedbackForResult(result: ChapterFourActionResult): string {
  if (result === "accepted") return "当前历史片段已经恢复。";
  if (result === "already_complete") return "这一段导视记录已经恢复。";
  if (result === "misaligned") return "碎片顺序与已记录的历史痕迹不一致。";
  if (result === "wrong_mode") return "切回浅色操作后再调整导视板。";
  if (result === "inactive") return "第四章教学楼流程尚未开始。";
  return "仍缺当前排列所需的历史证据。";
}

export function WayfindingBoardGame({ onConfirm, onCancel }: WayfindingBoardGameProps) {
  const [slots, setSlots] = useState<WayfindingSlot[]>(() => [...INITIAL_SLOTS]);
  const [pickedSlot, setPickedSlot] = useState<number | null>(null);
  const [focusedSlot, setFocusedSlot] = useState(0);
  const [result, setResult] = useState<ChapterFourActionResult | null>(null);
  const [statusText, setStatusText] = useState("比较三份现场材料后，选择一块碎片，再选择目标槽位。");
  const dialogRef = useRef<HTMLElement | null>(null);
  const slotRefs = useRef<Array<HTMLButtonElement | null>>([]);

  useEffect(() => {
    slotRefs.current[0]?.focus();
  }, []);

  useEffect(() => {
    const onWindowKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      onCancel();
    };
    window.addEventListener("keydown", onWindowKeyDown);
    return () => window.removeEventListener("keydown", onWindowKeyDown);
  }, [onCancel]);

  const focusSlot = (index: number) => {
    const normalized = (index + slots.length) % slots.length;
    setFocusedSlot(normalized);
    slotRefs.current[normalized]?.focus();
  };

  const activateSlot = (index: number) => {
    setResult(null);
    if (pickedSlot === null) {
      const fragment = slots[index];
      if (!fragment) {
        setStatusText("该槽位为空。先选择一块导视碎片。");
        return;
      }
      setPickedSlot(index);
      setStatusText(`已选择${FRAGMENT_LABELS[fragment]}，请选择目标槽位。`);
      return;
    }
    if (pickedSlot === index) {
      setPickedSlot(null);
      setStatusText("已取消当前选择。");
      return;
    }
    const nextSlots = [...slots];
    [nextSlots[pickedSlot], nextSlots[index]] = [nextSlots[index], nextSlots[pickedSlot]];
    setSlots(nextSlots);
    setPickedSlot(null);
    setStatusText("槽位已交换。确认前可以继续调整。");
  };

  const submit = () => {
    const order: WayfindingBoardEntry[] = slots.map((fragment) => fragment ?? "empty");
    const nextResult = onConfirm(order);
    setResult(nextResult);
    setStatusText(feedbackForResult(nextResult));
  };

  const handleDialogKeyDown = (event: ReactKeyboardEvent<HTMLElement>) => {
    if (event.key !== "Tab") return;
    const buttons = Array.from(dialogRef.current?.querySelectorAll<HTMLButtonElement>("button:not(:disabled)") ?? []);
    if (buttons.length === 0) return;
    const activeIndex = buttons.indexOf(document.activeElement as HTMLButtonElement);
    if (event.shiftKey && activeIndex <= 0) {
      event.preventDefault();
      buttons[buttons.length - 1].focus();
    } else if (!event.shiftKey && activeIndex === buttons.length - 1) {
      event.preventDefault();
      buttons[0].focus();
    }
  };

  return (
    <section
      ref={dialogRef}
      className="chapter4-wayfinding-board"
      role="dialog"
      aria-modal="true"
      aria-labelledby="wayfinding-board-title"
      aria-describedby="wayfinding-board-objective wayfinding-board-status"
      data-result={result ?? "idle"}
      onKeyDown={handleDialogKeyDown}
    >
      <header>
        <div>
          <span>ARCHIVED SIGNAGE / A3</span>
          <h2 id="wayfinding-board-title">残缺导视板</h2>
        </div>
        <button type="button" className="chapter4-wayfinding-board__close" onClick={onCancel} aria-label="取消并关闭导视板">×</button>
      </header>

      <p id="wayfinding-board-objective" className="chapter4-wayfinding-board__objective">
        <strong>当前目标</strong>
        比较当前导视照片、旧残影和二楼入口方向，判断两块碎片及缺失槽位的位置。
      </p>

      <div className="chapter4-wayfinding-board__evidence" aria-label="导视板比对材料">
        <article>
          <span>当前导视照片</span>
          <p>完整板面由三段等宽槽位组成；两块残片并拢后宽度仍不足。</p>
        </article>
        <article>
          <span>旧导视残影</span>
          <p>箭头端贴近左侧磨损边；“2F”字样端与箭头之间留有断续胶痕。</p>
        </article>
        <article>
          <span>二楼入口方向</span>
          <p>从交通核心进入二楼时，入口位于左侧导向一边。</p>
        </article>
      </div>

      <div className="chapter4-wayfinding-board__slots" role="group" aria-label="三个导视板槽位">
        {slots.map((fragment, index) => {
          const label = fragment ? FRAGMENT_LABELS[fragment] : "当前空槽";
          const picked = pickedSlot === index;
          return (
            <button
              key={`slot-${index + 1}`}
              ref={(node) => { slotRefs.current[index] = node; }}
              type="button"
              className={`chapter4-wayfinding-slot${fragment ? " is-filled" : " is-empty"}${picked ? " is-picked" : ""}`}
              tabIndex={focusedSlot === index ? 0 : -1}
              aria-label={`槽位 ${index + 1}：${label}${picked ? "，已选择" : ""}`}
              aria-pressed={picked}
              onFocus={() => setFocusedSlot(index)}
              onClick={() => activateSlot(index)}
              onKeyDown={(event) => {
                if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
                  event.preventDefault();
                  focusSlot(index - 1);
                } else if (event.key === "ArrowRight" || event.key === "ArrowDown") {
                  event.preventDefault();
                  focusSlot(index + 1);
                } else if (event.key === "Home") {
                  event.preventDefault();
                  focusSlot(0);
                } else if (event.key === "End") {
                  event.preventDefault();
                  focusSlot(slots.length - 1);
                } else if (event.key === "Enter" || event.key === " ") {
                  event.preventDefault();
                  activateSlot(index);
                }
              }}
            >
              <span className="chapter4-wayfinding-slot__number">槽位 {index + 1}</span>
              <strong>{label}</strong>
              <small>{fragment ? "选择后放入另一槽位" : "当前没有装入碎片"}</small>
            </button>
          );
        })}
      </div>

      <p id="wayfinding-board-status" className={`chapter4-wayfinding-board__status${result ? ` is-${result}` : ""}`} role="status" aria-live="polite">
        {statusText}
      </p>

      <footer>
        <button type="button" onClick={onCancel}>取消</button>
        <span>方向键切换槽位，Enter 或空格选择</span>
        <button type="button" className="is-primary" onClick={submit}>确认当前排列</button>
      </footer>
    </section>
  );
}
