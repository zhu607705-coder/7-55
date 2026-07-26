import { useEffect, useMemo, useState } from "react";
import type { GameStore } from "../core/types";
import {
  applyDeveloperCheckpoint,
  DEVELOPER_CHECKPOINTS,
  getActiveDeveloperCheckpoint,
  restoreDeveloperBackup,
  type DeveloperCheckpoint,
  type DeveloperCheckpointId
} from "../modules/DeveloperChannel";

interface DeveloperChannelProps {
  store: GameStore;
  onVisibilityChange?: (open: boolean) => void;
}

type DeveloperChapter = DeveloperCheckpoint["chapter"];

const DEVELOPER_CHAPTERS: readonly DeveloperChapter[] = ["第一章", "第二章", "第三章"];

function getCheckpointLane(checkpoint: DeveloperCheckpoint): string {
  if (checkpoint.chapter === "第一章") return "签到失控";
  if (checkpoint.chapter === "第二章") {
    return checkpoint.id.startsWith("c2-library-")
      || [
        "c2-entrance-record", "c2-seat-arrival", "c2-occupancy-note", "c2-catalog",
        "c2-archived-rule", "c2-photo-report", "c2-nonperson-stamp", "c2-seat-receipt",
        "c2-tiyi-proof", "c2-cc98-upload", "c2-bd-rise", "c2-recovery-form",
        "c2-pass-generate", "c2-pass-apply", "c2-seat-sit", "c2-seat-dialogue",
        "c2-chapter-exit"
      ].includes(checkpoint.id)
      ? "图书馆 022"
      : "寝室与移动";
  }
  if (checkpoint.id === "canteen-hunt" || checkpoint.id.startsWith("c3-canteen-")) return "食堂";
  if (checkpoint.id.startsWith("c3-theater-")) return "剧场";
  if (checkpoint.id.startsWith("c3-qizhen-")) return "启真湖";
  return "第三章";
}

function getChapterLanes(chapter: DeveloperChapter): string[] {
  return DEVELOPER_CHECKPOINTS
    .filter((checkpoint) => checkpoint.chapter === chapter)
    .map(getCheckpointLane)
    .filter((lane, index, lanes) => lanes.indexOf(lane) === index);
}

function getInitialDeveloperSelection(active: DeveloperCheckpointId | null): {
  chapter: DeveloperChapter;
  lane: string;
} {
  const activeCheckpoint = DEVELOPER_CHECKPOINTS.find((checkpoint) => checkpoint.id === active);
  if (activeCheckpoint) {
    return { chapter: activeCheckpoint.chapter, lane: getCheckpointLane(activeCheckpoint) };
  }
  const chapter: DeveloperChapter = "第三章";
  const lanes = getChapterLanes(chapter);
  return { chapter, lane: lanes[0] ?? "全部" };
}

export function DeveloperChannel({ store, onVisibilityChange }: DeveloperChannelProps) {
  const params = new URLSearchParams(window.location.search);
  const explicitlyRequested = params.get("dev") === "1" || params.has("devCheckpoint");
  const [available, setAvailable] = useState(() => isDeveloperChannelAvailable(window.location.search, import.meta.env.DEV));
  const [open, setOpen] = useState(() => explicitlyRequested && isDeveloperChannelAvailable(window.location.search, import.meta.env.DEV));
  const [active, setActive] = useState(() => getActiveDeveloperCheckpoint());
  const initialSelection = useMemo(() => getInitialDeveloperSelection(active), []);
  const [selectedChapter, setSelectedChapter] = useState<DeveloperChapter>(initialSelection.chapter);
  const [selectedLane, setSelectedLane] = useState(initialSelection.lane);
  const chapterCheckpoints = useMemo(
    () => DEVELOPER_CHECKPOINTS.filter((checkpoint) => checkpoint.chapter === selectedChapter),
    [selectedChapter]
  );
  const chapterLanes = useMemo(() => getChapterLanes(selectedChapter), [selectedChapter]);
  const visibleCheckpoints = useMemo(
    () => selectedLane === "全部"
      ? chapterCheckpoints
      : chapterCheckpoints.filter((checkpoint) => getCheckpointLane(checkpoint) === selectedLane),
    [chapterCheckpoints, selectedLane]
  );
  useEffect(() => {
    onVisibilityChange?.(open);
  }, [onVisibilityChange, open]);
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.ctrlKey && event.shiftKey && event.key.toLowerCase() === "d") {
        event.preventDefault();
        setAvailable(true);
        setOpen((value) => !value);
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);
  const stopPointerPropagation = (event: React.SyntheticEvent) => event.stopPropagation();
  if (!available) return null;
  if (!open) return <button type="button" className="developer-channel-trigger" aria-label="打开开发者通道" onPointerDown={stopPointerPropagation} onPointerUp={stopPointerPropagation} onClick={(event) => { stopPointerPropagation(event); setOpen(true); }}>DEV</button>;
  return <aside className="developer-channel" aria-label="开发者通道" onPointerDown={stopPointerPropagation} onPointerUp={stopPointerPropagation} onClick={stopPointerPropagation}>
    <header><div><small>7:55 DEV · {DEVELOPER_CHECKPOINTS.length} 个节点</small><strong>玩法节点直达</strong></div><button type="button" aria-label="关闭开发者通道" onClick={() => setOpen(false)}>×</button></header>
    <nav className="developer-channel-chapters" aria-label="选择章节">
      {DEVELOPER_CHAPTERS.map((chapter) => {
        const count = DEVELOPER_CHECKPOINTS.filter((checkpoint) => checkpoint.chapter === chapter).length;
        return <button
          key={chapter}
          type="button"
          data-dev-chapter={chapter}
          className={selectedChapter === chapter ? "is-active" : ""}
          aria-pressed={selectedChapter === chapter}
          onClick={() => {
            const lanes = getChapterLanes(chapter);
            setSelectedChapter(chapter);
            setSelectedLane(lanes[0] ?? "全部");
          }}
        ><strong>{chapter}</strong><span>{count}</span></button>;
      })}
    </nav>
    <div className="developer-channel-lanes" aria-label="选择玩法段落">
      <span>玩法段落</span>
      <div>
        {chapterLanes.map((lane) => <button
          key={lane}
          type="button"
          data-dev-lane={lane}
          className={selectedLane === lane ? "is-active" : ""}
          aria-pressed={selectedLane === lane}
          onClick={() => setSelectedLane(lane)}
        >{lane}</button>)}
        {chapterLanes.length > 1 && <button
          type="button"
          data-dev-lane="全部"
          className={selectedLane === "全部" ? "is-active" : ""}
          aria-pressed={selectedLane === "全部"}
          onClick={() => setSelectedLane("全部")}
        >全部</button>}
      </div>
    </div>
    <div className="developer-channel-scroll">
      <section>
        <h2><span>{selectedChapter} · {selectedLane}</span><small>{visibleCheckpoints.length} 个节点</small></h2>
        {visibleCheckpoints.map((item) => <button key={item.id} type="button" data-dev-checkpoint={item.id} className={active === item.id ? "is-active" : ""} onClick={() => { applyDeveloperCheckpoint(store, item.id as DeveloperCheckpointId); setActive(item.id); }}><strong>{item.label}</strong><span>{item.detail}</span></button>)}
      </section>
    </div>
    <footer><button type="button" onClick={() => { if (restoreDeveloperBackup(store)) setActive(null); }}>恢复进入前存档</button><span>Ctrl Shift D</span></footer>
  </aside>;
}

export function isDeveloperChannelAvailable(search: string, _devMode: boolean): boolean {
  const params = new URLSearchParams(search);
  return params.get("dev") !== "0";
}
