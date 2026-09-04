import { Fragment, useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { GameStore } from "../core/types";
import { isRecordingMode } from "../core/RecordingMode";
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
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCheckpointApplied?: () => void;
}

type DeveloperChapter = DeveloperCheckpoint["chapter"];

interface DeveloperLevel {
  id: string;
  chapter: DeveloperChapter;
  label: string;
  checkpointIds: readonly DeveloperCheckpointId[];
}

const DEVELOPER_CHAPTERS: readonly DeveloperChapter[] = ["第一章", "第二章", "第三章", "3.5章", "第四章"];

const DEVELOPER_LEVELS: readonly DeveloperLevel[] = [
  { id: "1-1", chapter: "第一章", label: "闹钟与散码", checkpointIds: ["c1-alarm", "c1-home", "c1-code-hunt", "c1-dorm-card"] },
  { id: "1-2", chapter: "第一章", label: "签到失控", checkpointIds: ["c1-checkin", "c1-narrator-block"] },
  { id: "2-1", chapter: "第二章", label: "寝室苏醒", checkpointIds: ["c2-friend", "c2-system", "c2-inventory", "c2-system-return", "c2-name"] },
  { id: "2-2", chapter: "第二章", label: "取得移动权限", checkpointIds: ["c2-exercise", "c2-triangle", "c2-weather-water", "c2-mentor-line", "c2-arrow-assembly", "c2-balance-shift"] },
  { id: "2-3", chapter: "第二章", label: "CC98 与手柄", checkpointIds: ["c2-cc98-login", "c2-gamepad-market", "c2-manual-movement", "c2-reservation-briefing", "c2-seat-reservation", "c2-dorm-exit"] },
  { id: "2-4", chapter: "第二章", label: "022 调查取证", checkpointIds: ["c2-library-gate", "c2-entrance-record", "c2-seat-arrival", "c2-occupancy-note", "c2-catalog", "c2-archived-rule", "c2-photo-report", "c2-nonperson-stamp", "c2-seat-receipt", "c2-tiyi-proof", "c2-cc98-upload"] },
  { id: "2-5", chapter: "第二章", label: "恢复座位", checkpointIds: ["c2-bd-rise", "c2-recovery-form", "c2-pass-generate", "c2-pass-apply", "c2-seat-sit", "c2-seat-dialogue"] },
  { id: "2-6", chapter: "第二章", label: "追往食堂", checkpointIds: ["c2-chapter-exit", "campus-canteen-entry"] },
  { id: "3-1", chapter: "第三章", label: "东区食堂追踪", checkpointIds: ["canteen-hunt", "c3-canteen-entry", "c3-canteen-drinks", "c3-canteen-menu", "c3-canteen-pickup", "c3-canteen-block", "c3-canteen-block-2", "c3-canteen-block-3", "c3-canteen-bike", "c3-canteen-chase", "c3-canteen-theater"] },
  { id: "3-2", chapter: "第三章", label: "剧场追踪", checkpointIds: ["c3-theater-entry", "c3-theater-ticket-request", "c3-theater-ticket-accepted", "c3-theater-ticket-first-wave", "c3-theater-ticket-first-wave-won", "c3-theater-ticket-delivered", "c3-theater-code", "c3-theater-program", "c3-theater-prop", "c3-theater-spotlight", "c3-theater-spotlight-round", "c3-theater-complete"] },
  { id: "3-3", chapter: "第三章", label: "寻找启真湖", checkpointIds: ["c3-qizhen-transition", "c3-qizhen-location", "c3-qizhen-map", "c3-qizhen-gate"] },
  { id: "3-4", chapter: "第三章", label: "雨后登船", checkpointIds: ["c3-qizhen-dock", "c3-qizhen-rain-hold", "c3-qizhen-rescue-dorm", "c3-qizhen-hair-dryer", "c3-qizhen-weather-control", "c3-qizhen-overcast", "c3-qizhen-boarding"] },
  { id: "3-5", chapter: "第三章", label: "湖区道具链", checkpointIds: ["c3-qizhen-open-water", "c3-qizhen-rhythm-key", "c3-qizhen-rhythm-net", "c3-qizhen-rhythm-fish", "c3-qizhen-rhythm-paper", "c3-qizhen-tool-chain", "c3-qizhen-swan", "c3-qizhen-paper"] },
  { id: "3-6", chapter: "第三章", label: "黑天鹅追逐", checkpointIds: ["c3-qizhen-chase", "c3-qizhen-complete"] },
  { id: "3.5-1", chapter: "3.5章", label: "未同步记录", checkpointIds: ["c3-interlude-reboot", "c3-interlude-journal", "c3-interlude-photos", "c3-interlude-voice", "c3-interlude-network", "c3-interlude-timeline", "c3-interlude-destination", "c3-interlude-replay"] },
  { id: "3.5-2", chapter: "3.5章", label: "教学楼过渡", checkpointIds: ["c4-prologue", "c4-prologue-lake-exit", "c4-prologue-arcade", "c4-prologue-entrance", "c4-prologue-lobby", "c4-prologue-closing", "c4-prologue-task-card"] },
  { id: "4-1", chapter: "第四章", label: "入楼与旧钟", checkpointIds: ["c4-755-opening", "c4-755-hall-clock"] },
  { id: "4-2", chapter: "第四章", label: "12:25 面包坊", checkpointIds: ["c4-755-bakery-1225", "c4-755-clock-1850-ready"] },
  { id: "4-3", chapter: "第四章", label: "18:50 差分校验", checkpointIds: ["c4-755-classrooms-1850", "c4-755-elevator-history"] },
  { id: "4-4", chapter: "第四章", label: "错位楼梯与二楼记录", checkpointIds: ["c4-755-room204-1850", "c4-755-a2-field-records"] },
  { id: "4-5", chapter: "第四章", label: "22:45 维修链", checkpointIds: ["c4-755-clock-2245-ready", "c4-755-maintenance-2245"] },
  { id: "4-6", chapter: "第四章", label: "07:54 停电追逐", checkpointIds: ["c4-755-blackout-0754", "c4-755-chase"] },
  { id: "4-7", chapter: "第四章", label: "最后一分钟", checkpointIds: ["c4-755-final-minute", "c4-755-return-clock"] },
  { id: "4-8", chapter: "第四章", label: "07:55 签到与收束", checkpointIds: ["c4-755-checkin", "c4-755-closure"] }
];

function getCheckpointLevel(checkpoint: DeveloperCheckpoint): DeveloperLevel {
  return DEVELOPER_LEVELS.find((level) => level.checkpointIds.includes(checkpoint.id)) ?? {
    id: "未分组",
    chapter: checkpoint.chapter,
    label: "待划分节点",
    checkpointIds: [checkpoint.id]
  };
}

function getChapterLevels(chapter: DeveloperChapter): DeveloperLevel[] {
  return DEVELOPER_LEVELS.filter((level) => level.chapter === chapter);
}

function getInitialDeveloperSelection(active: DeveloperCheckpointId | null): {
  chapter: DeveloperChapter;
  levelId: string;
} {
  const activeCheckpoint = DEVELOPER_CHECKPOINTS.find((checkpoint) => checkpoint.id === active);
  if (activeCheckpoint) {
    return { chapter: activeCheckpoint.chapter, levelId: getCheckpointLevel(activeCheckpoint).id };
  }
  const chapter: DeveloperChapter = "第三章";
  const levels = getChapterLevels(chapter);
  return { chapter, levelId: levels[0]?.id ?? "全部" };
}

export function DeveloperChannel({
  store,
  open,
  onOpenChange,
  onCheckpointApplied
}: DeveloperChannelProps) {
  const params = new URLSearchParams(window.location.search);
  const explicitlyDisabled = params.get("dev") === "0";
  const recordingMode = isRecordingMode(window.location.search);
  const initialAvailability = isDeveloperChannelAvailable(window.location.search, import.meta.env.DEV);
  const [available, setAvailable] = useState(initialAvailability || open);
  const [active, setActive] = useState(() => getActiveDeveloperCheckpoint());
  const channelRef = useRef<HTMLElement>(null);
  const initialSelection = useMemo(() => getInitialDeveloperSelection(active), []);
  const [selectedChapter, setSelectedChapter] = useState<DeveloperChapter>(initialSelection.chapter);
  const [selectedLevelId, setSelectedLevelId] = useState(initialSelection.levelId);
  const chapterCheckpoints = useMemo(
    () => DEVELOPER_CHECKPOINTS.filter((checkpoint) => checkpoint.chapter === selectedChapter),
    [selectedChapter]
  );
  const chapterLevels = useMemo(() => getChapterLevels(selectedChapter), [selectedChapter]);
  const selectedLevel = chapterLevels.find((level) => level.id === selectedLevelId) ?? null;
  const closeButtonLabel = recordingMode ? "关闭录制检查点面板" : "关闭开发者通道";
  const visibleCheckpoints = useMemo(
    () => selectedLevelId === "全部"
      ? chapterCheckpoints
      : chapterCheckpoints.filter((checkpoint) => getCheckpointLevel(checkpoint).id === selectedLevelId),
    [chapterCheckpoints, selectedLevelId]
  );
  const setChannelOpen = useCallback((nextOpen: boolean) => {
    onOpenChange(nextOpen);
  }, [onOpenChange]);
  const closeAndResume = useCallback(() => {
    if (recordingMode) {
      const nextUrl = new URL(window.location.href);
      nextUrl.searchParams.delete("dev");
      window.history.replaceState(window.history.state, "", nextUrl);
    }
    setChannelOpen(false);
  }, [recordingMode, setChannelOpen]);
  useEffect(() => {
    if (explicitlyDisabled) return undefined;
    const onKeyDown = (event: KeyboardEvent) => {
      if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key.toLowerCase() === "d") {
        event.preventDefault();
        event.stopImmediatePropagation();
        if (event.repeat) return;
        setAvailable(true);
        if (open) closeAndResume();
        else setChannelOpen(true);
        return;
      }
      if (open && event.key === "Escape") {
        event.preventDefault();
        event.stopImmediatePropagation();
        if (event.repeat) return;
        closeAndResume();
      }
    };
    window.addEventListener("keydown", onKeyDown, true);
    return () => window.removeEventListener("keydown", onKeyDown, true);
  }, [closeAndResume, explicitlyDisabled, open, setChannelOpen]);
  useEffect(() => {
    if (!open) return undefined;
    const frame = window.requestAnimationFrame(() => {
      channelRef.current?.querySelector<HTMLButtonElement>(`button[aria-label='${closeButtonLabel}']`)
        ?.focus({ preventScroll: true });
    });
    return () => window.cancelAnimationFrame(frame);
  }, [closeButtonLabel, open]);
  const stopPointerPropagation = (event: React.SyntheticEvent) => event.stopPropagation();
  if (!available) return null;
  if (!open) {
    if (recordingMode) return null;
    return <button type="button" className="developer-channel-trigger" aria-label="打开开发者通道" onPointerDown={stopPointerPropagation} onPointerUp={stopPointerPropagation} onClick={(event) => { stopPointerPropagation(event); setChannelOpen(true); }}>DEV</button>;
  }
  const dismissBackdrop = (event: React.SyntheticEvent) => {
    event.preventDefault();
    event.stopPropagation();
    closeAndResume();
  };
  return <Fragment>
    <div
      className="developer-channel-backdrop"
      aria-hidden="true"
      onPointerDown={(event) => {
        event.preventDefault();
        event.stopPropagation();
      }}
      onPointerUp={stopPointerPropagation}
      onClick={dismissBackdrop}
    />
    <aside ref={channelRef} data-developer-channel-root data-recording-mode={recordingMode ? "true" : undefined} className="developer-channel" aria-label={recordingMode ? "录制检查点面板" : "开发者通道"} onPointerDown={stopPointerPropagation} onPointerUp={stopPointerPropagation} onClick={stopPointerPropagation}>
    <header><div><small>{recordingMode ? "7:55 录制准备" : "7:55 DEV"} · {DEVELOPER_CHAPTERS.length} 章 · {DEVELOPER_LEVELS.length} 关 · {DEVELOPER_CHECKPOINTS.length} 节点</small><strong>{recordingMode ? "录制检查点切换" : "章节与关卡直达"}</strong></div><button type="button" aria-label={closeButtonLabel} onClick={closeAndResume}>×</button></header>
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
            const levels = getChapterLevels(chapter);
            setSelectedChapter(chapter);
            setSelectedLevelId(levels[0]?.id ?? "全部");
          }}
        ><strong>{chapter}</strong><span>{count}</span></button>;
      })}
    </nav>
    <div className="developer-channel-levels" aria-label="选择关卡">
      <span>关卡</span>
      <div>
        {chapterLevels.map((level) => <button
          key={level.id}
          type="button"
          data-dev-level={level.id}
          className={selectedLevelId === level.id ? "is-active" : ""}
          aria-pressed={selectedLevelId === level.id}
          onClick={() => setSelectedLevelId(level.id)}
        ><b>{level.id}</b><span>{level.label}</span><i>{level.checkpointIds.length}</i></button>)}
        {chapterLevels.length > 1 && <button
          type="button"
          data-dev-level="全部"
          className={selectedLevelId === "全部" ? "is-active" : ""}
          aria-pressed={selectedLevelId === "全部"}
          onClick={() => setSelectedLevelId("全部")}
        ><b>ALL</b><span>全部关卡</span><i>{chapterCheckpoints.length}</i></button>}
      </div>
    </div>
    <div className="developer-channel-scroll">
      <section>
        <h2><span>{selectedChapter} · {selectedLevel ? `${selectedLevel.id} ${selectedLevel.label}` : "全部关卡"}</span><small>{visibleCheckpoints.length} 个节点</small></h2>
        {visibleCheckpoints.map((item) => <button
          key={item.id}
          type="button"
          data-dev-checkpoint={item.id}
          className={active === item.id ? "is-active" : ""}
          onClick={() => {
            setChannelOpen(false);
            applyDeveloperCheckpoint(store, item.id as DeveloperCheckpointId);
            if (recordingMode) {
              const nextUrl = new URL(window.location.href);
              nextUrl.searchParams.set("devCheckpoint", item.id);
              nextUrl.searchParams.delete("dev");
              window.history.replaceState(window.history.state, "", nextUrl);
            }
            setActive(item.id);
            onCheckpointApplied?.();
          }}
        ><strong>{item.label}</strong><span>{item.detail}</span></button>)}
      </section>
    </div>
    <footer><button type="button" onClick={() => {
      closeAndResume();
      if (restoreDeveloperBackup(store)) {
        setActive(null);
        onCheckpointApplied?.();
      } else {
        setChannelOpen(true);
      }
    }}>恢复进入前存档</button><span>{recordingMode ? "选择节点后自动清屏 · Esc 关闭" : "Ctrl/Cmd Shift D"}</span></footer>
    </aside>
  </Fragment>;
}

export function isDeveloperChannelAvailable(search: string, _devMode: boolean): boolean {
  const params = new URLSearchParams(search);
  return params.get("dev") !== "0";
}
