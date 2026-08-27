import type {
  ChapterThreeInterludeEvidenceId,
  GameState,
  SceneId
} from "../core/types";
import {
  chapterThreeInterludePresentationCopy,
  chapterThreeInterludePublicContent,
  chapterThreeInterludeValidationContract,
  type ChapterThreeInterludeDestinationCandidateId
} from "../data/chapter3InterludeContent";

export interface ChapterThreeInterludeTimeWindowView {
  startLabel: string;
  endLabel: string;
  label: string;
  startResolved: boolean;
  endResolved: boolean;
}

export interface ChapterThreeInterludeTimelineRowView {
  id: ChapterThreeInterludeEvidenceId;
  label: string;
  timeLabel: string;
  summary: string;
  sourceLabel: string;
}

export interface ChapterThreeInterludeTaskView {
  id: string;
  label: string;
  hints: readonly string[];
  targetSurface: "phone";
  recommendedScene: SceneId;
}

export interface ChapterThreeInterludeParallelBranchView {
  id: "photos" | "voice" | "messages" | "network";
  label: string;
  completed: boolean;
  recommendedScene: SceneId;
}

export interface ChapterThreeInterludeViewModel {
  title: string;
  timeWindow: ChapterThreeInterludeTimeWindowView;
  notificationTimeLabel: string;
  notificationMessage: string;
  evidenceProgress: { completed: number; total: number };
  branchProgress: { completed: number; total: 4 };
  parallelBranches: readonly ChapterThreeInterludeParallelBranchView[];
  networkProgress: { completed: number; total: 3 };
  sourceSummaries: readonly ChapterThreeInterludeTimelineRowView[];
  autoTimelineRows: readonly ChapterThreeInterludeTimelineRowView[];
  destinationSelectionUnlocked: boolean;
  destinationCandidates: readonly { id: ChapterThreeInterludeDestinationCandidateId; label: string }[];
  currentObjective: ChapterThreeInterludeTaskView;
  derivedReasoning: string;
}

function asTaskView(
  task: (typeof chapterThreeInterludePresentationCopy.tasks)[keyof typeof chapterThreeInterludePresentationCopy.tasks]
): ChapterThreeInterludeTaskView {
  return {
    id: task.id,
    label: task.label,
    hints: task.hints,
    targetSurface: "phone",
    recommendedScene: task.recommendedScene as SceneId
  };
}

export function selectChapterThreeInterludeViewModel(
  state: GameState
): ChapterThreeInterludeViewModel {
  const interlude = state.chapterThreeInterlude;
  const evidenceOrder = chapterThreeInterludeValidationContract.evidenceOrder;
  const evidenceSet = new Set(interlude.evidenceIds);
  const startResolved = evidenceSet.has("journal_start");
  const endResolved = evidenceSet.has("broadcast_end");
  const startLabel = startResolved
    ? chapterThreeInterludePublicContent.evidence.journal_start.timeLabel
    : chapterThreeInterludePublicContent.unresolvedTime;
  const endLabel = endResolved
    ? chapterThreeInterludePublicContent.evidence.broadcast_end.timeLabel
    : chapterThreeInterludePublicContent.unresolvedTime;
  const timeWindow: ChapterThreeInterludeTimeWindowView = {
    startLabel,
    endLabel,
    label: `${startLabel} — ${endLabel}`,
    startResolved,
    endResolved
  };
  const evidenceProgress = {
    completed: evidenceOrder.filter((id) => evidenceSet.has(id)).length,
    total: evidenceOrder.length
  };
  const networkProgress = {
    completed: [
      interlude.officialNoticeSaved,
      interlude.routeScreenshotSaved,
      interlude.networkRecordRead
    ].filter(Boolean).length,
    total: 3 as const
  };
  const parallelBranches: readonly ChapterThreeInterludeParallelBranchView[] = [
    {
      id: "photos",
      label: "照片线索",
      completed: interlude.photoSequenceSolved,
      recommendedScene: "photos"
    },
    {
      id: "voice",
      label: "录音线索",
      completed: interlude.voiceSequenceSolved,
      recommendedScene: "voice_memos"
    },
    {
      id: "messages",
      label: "消息线索",
      completed: interlude.officialNoticeSaved && interlude.routeScreenshotSaved,
      recommendedScene: "wechat"
    },
    {
      id: "network",
      label: "网络记录",
      completed: interlude.networkRecordRead,
      recommendedScene: "zjuding"
    }
  ];
  const branchProgress = {
    completed: parallelBranches.filter((branch) => branch.completed).length,
    total: 4 as const
  };
  const sourceSummaries = evidenceOrder
    .filter((id) => evidenceSet.has(id))
    .map((id) => ({ id, ...chapterThreeInterludePublicContent.evidence[id] }));
  const allEvidenceReady = evidenceProgress.completed === evidenceProgress.total;
  const allDecoysRejected = Object.keys(chapterThreeInterludeValidationContract.decoyReasonById)
    .every((id) => interlude.rejectedDecoyIds.includes(id as keyof typeof chapterThreeInterludeValidationContract.decoyReasonById));
  const exclusionsReady = allEvidenceReady && allDecoysRejected && interlude.statusClockMarkedUntrusted;
  const autoTimelineRows = exclusionsReady
    ? evidenceOrder.map((id) => ({ id, ...chapterThreeInterludePublicContent.evidence[id] }))
    : [];
  const destinationSelectionUnlocked = exclusionsReady && interlude.destinationId === null;

  let taskKey: keyof typeof chapterThreeInterludePresentationCopy.tasks;
  if (!interlude.recoveryOpened || interlude.phase === "reboot" || interlude.phase === "inactive") {
    taskKey = "reboot";
  } else if (!startResolved) {
    taskKey = "journal";
  } else if (branchProgress.completed < branchProgress.total) {
    taskKey = "evidence";
  } else if (!exclusionsReady) {
    taskKey = "exclusions";
  } else if (interlude.destinationId === null) {
    taskKey = "destination";
  } else {
    taskKey = "replay";
  }

  let derivedReasoning: string;
  if (!startResolved) {
    derivedReasoning = "时间窗起点仍待恢复。";
  } else if (branchProgress.completed < branchProgress.total) {
    derivedReasoning = `还有 ${branchProgress.total - branchProgress.completed} 类证据待恢复。`;
  } else if (!exclusionsReady) {
    derivedReasoning = `还有 ${3 - interlude.rejectedDecoyIds.length} 条旧时间需要核验。`;
  } else if (interlude.destinationId === null) {
    derivedReasoning = `还需从 ${chapterThreeInterludePublicContent.destinationCandidates.length} 个候选地点中排除冲突。`;
  } else {
    derivedReasoning = "时间与地点已经完成交叉核验。";
  }

  return {
    title: chapterThreeInterludePresentationCopy.title,
    timeWindow,
    notificationTimeLabel: endResolved
      ? chapterThreeInterludePublicContent.evidence.broadcast_end.timeLabel.slice(0, 5)
      : chapterThreeInterludePublicContent.unresolvedTime,
    notificationMessage: interlude.recoveryOpened
      ? `${chapterThreeInterludePublicContent.timeWindowLabel}：${timeWindow.label}`
      : "检测到 7 分 55 秒未同步记录。",
    evidenceProgress,
    branchProgress,
    parallelBranches,
    networkProgress,
    sourceSummaries,
    autoTimelineRows,
    destinationSelectionUnlocked,
    destinationCandidates: destinationSelectionUnlocked
      ? chapterThreeInterludePublicContent.destinationCandidates
      : [],
    currentObjective: asTaskView(chapterThreeInterludePresentationCopy.tasks[taskKey]),
    derivedReasoning
  };
}
