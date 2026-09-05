import voiceMemoAudioContent from "./chapter3-interlude-voice-memos.audio.content.json";
import type {
  ChapterThreeInterludeDecoyId,
  ChapterThreeInterludeEvidenceId,
  ChapterThreeInterludePhotoFrameId,
  ChapterThreeInterludeVoiceClipId
} from "../core/types";

export type ChapterThreeInterludeVoiceCandidateId =
  | ChapterThreeInterludeVoiceClipId
  | "decoy_canteen"
  | "decoy_theater"
  | "decoy_library";

export type ChapterThreeInterludeDestinationCandidateId =
  | "qizhen_lake_dock"
  | "theater_lobby"
  | "basic_library_south"
  | "duan_yongping_a1";

export type ChapterThreeInterludeDecoyReasonId =
  | "number_not_time"
  | "earlier_independent_event"
  | "frozen_local_clock";

export type ChapterThreeInterludeRouteMessageId =
  | "computer_left_on"
  | "guard_east"
  | "east_closed"
  | "west_cleaner"
  | "withdrawn";

export type ChapterThreeInterludeNetworkRecordId =
  | "record_qizhen_dock"
  | "record_theater_hall"
  | "record_library_south"
  | "record_0755";

export type ChapterThreeInterludeDestinationConflictId =
  | "indoor_end_conflict"
  | "access_point_conflict"
  | "entry_route_conflict";

export interface ChapterThreeInterludePublicRecording {
  id: ChapterThreeInterludeVoiceCandidateId;
  asset: string;
  code: string;
  time: string;
  revealZh: string;
  targetDurationMs: number;
}

const recordings = voiceMemoAudioContent.recordings.map((recording) => ({
  id: recording.id as ChapterThreeInterludeVoiceCandidateId,
  asset: recording.asset,
  code: recording.code,
  time: recording.time,
  revealZh: recording.revealZh,
  targetDurationMs: recording.targetDurationMs
})) satisfies ChapterThreeInterludePublicRecording[];

export const chapterThreeInterludePublicContent = {
  unresolvedTime: "待恢复",
  timeWindowLabel: "待核验时间窗",
  recordings,
  evidence: {
    journal_start: {
      label: "CC98 划船记录",
      timeLabel: "22:37:05",
      summary: "最后一条离湖回复提供了记录起点。",
      sourceLabel: "CC98"
    },
    photo_direction: {
      label: "恢复照片",
      timeLabel: "时间缺失",
      summary: "三张残片记录了纸条位置的连续变化。",
      sourceLabel: "照片"
    },
    network_destination: {
      label: "夜间接入记录",
      timeLabel: "区间末段",
      summary: "通知、路线截图和短会话共同缩小了地点范围。",
      sourceLabel: "微信与校园网络"
    },
    broadcast_end: {
      label: "广播录音",
      timeLabel: "22:45:00",
      summary: "广播和断电声提供了记录终点。",
      sourceLabel: "录音"
    }
  } satisfies Record<ChapterThreeInterludeEvidenceId, {
    label: string;
    timeLabel: string;
    summary: string;
    sourceLabel: string;
  }>,
  destinationCandidates: [
    { id: "qizhen_lake_dock", label: "启真湖小码头" },
    { id: "theater_lobby", label: "剧场前厅" },
    { id: "basic_library_south", label: "基础图书馆南侧" },
    { id: "duan_yongping_a1", label: "段永平教学楼 A 楼一层" }
  ] satisfies ReadonlyArray<{ id: ChapterThreeInterludeDestinationCandidateId; label: string }>,
  destinationConflictCopy: {
    qizhen_lake_dock: "录音末段出现室内广播和断电声，湖面环境无法解释这组声音。",
    theater_lobby: "末段短会话的接入点编号与剧场网络记录不一致。",
    basic_library_south: "闭楼通知和入口截图指向另一组楼宇入口规则。"
  } satisfies Readonly<Record<
    Exclude<ChapterThreeInterludeDestinationCandidateId, "duan_yongping_a1">,
    string
  >>,
  oldTimeCandidates: [
    { id: "canteen_0755", label: "食堂 0755", source: "取餐编号" },
    { id: "theater_0832", label: "剧场 08:32", source: "更早的独立记录" },
    { id: "status_clock_075523", label: "状态栏 07:55:23", source: "未同步的本机时钟" }
  ] satisfies ReadonlyArray<{ id: ChapterThreeInterludeDecoyId; label: string; source: string }>
} as const;

export const chapterThreeInterludePresentationCopy = {
  title: "未同步的七分五十五秒",
  tasks: {
    reboot: {
      id: "chapter_three_interlude_reboot",
      label: "打开未同步记录",
      hints: [
        "手机首页出现了一条记录恢复通知。",
        "打开记录恢复页，查看目前缺失的时间与证据。",
        "进入“记录恢复”，开始核对离湖后的记录。"
      ],
      recommendedScene: "timeline_recovery"
    },
    journal: {
      id: "chapter_three_interlude_journal",
      label: "查清离开湖边的时间",
      hints: [
        "离开湖边时有没有留下带时间的记录？",
        "CC98 划船记录保留了带时间的最后回复。",
        "打开划船记录帖并保存最后一条离湖回复。"
      ],
      recommendedScene: "cc98"
    },
    evidence: {
      id: "chapter_three_interlude_evidence",
      label: "查清离湖后去了哪里",
      hints: [
        "照片拍到了哪里，录音里又有哪些声音？先从手边的一项看起。",
        "消息与网络记录也留着线索；任务栏可以打开对应应用。",
        "四项都查过以后，回记录恢复页核对时间。"
      ],
      recommendedScene: "phone_home"
    },
    exclusions: {
      id: "chapter_three_interlude_exclusions",
      label: "排除旧时间记录",
      hints: [
        "这些数字分别记的是什么？其中有一条只是取餐编号。",
        "再看记录发生在什么时候、本机时钟有没有同步。",
        "给每条不能采用的时间选择理由。写着数字，不等于能拿来校时。"
      ],
      recommendedScene: "timeline_recovery"
    },
    destination: {
      id: "chapter_three_interlude_destination",
      label: "根据证据确认目的地",
      hints: [
        "比较每个候选地点与四项证据是否存在冲突。",
        "同时核对水面离开、室内路线、网络记录和闭楼广播。",
        "回到记录恢复页，选一个能解释全部记录的地点。"
      ],
      recommendedScene: "timeline_recovery"
    },
    replay: {
      id: "chapter_three_interlude_replay",
      label: "回看离湖后的那段路",
      hints: [
        "去向已经查清，可以把记录连起来看了。",
        "这段路有照片和声音留下，你的手机却没记准时间。",
        "在记录恢复页开始回放。"
      ],
      recommendedScene: "timeline_recovery"
    }
  }
} as const;

export const chapterThreeInterludeValidationContract = {
  manifestVersion: voiceMemoAudioContent.version,
  photoOrder: ["paper_left", "paper_middle", "paper_right"] satisfies readonly ChapterThreeInterludePhotoFrameId[],
  voiceOrder: ["lake", "stone", "lobby", "broadcast"] satisfies readonly ChapterThreeInterludeVoiceClipId[],
  voiceCandidateIds: recordings.map((recording) => recording.id),
  evidenceOrder: [
    "journal_start",
    "photo_direction",
    "network_destination",
    "broadcast_end"
  ] satisfies readonly ChapterThreeInterludeEvidenceId[],
  decoyReasonById: {
    canteen_0755: "number_not_time",
    theater_0832: "earlier_independent_event",
    status_clock_075523: "frozen_local_clock"
  } satisfies Readonly<Record<ChapterThreeInterludeDecoyId, ChapterThreeInterludeDecoyReasonId>>,
  routeMessageOrder: ["east_closed", "west_cleaner"] satisfies readonly ChapterThreeInterludeRouteMessageId[],
  destinationConflictById: {
    qizhen_lake_dock: "indoor_end_conflict",
    theater_lobby: "access_point_conflict",
    basic_library_south: "entry_route_conflict"
  } satisfies Readonly<Record<
    Exclude<ChapterThreeInterludeDestinationCandidateId, "duan_yongping_a1">,
    ChapterThreeInterludeDestinationConflictId
  >>,
  destinationId: "duan_yongping_a1" as const,
  destinationExplanationId: "c" as const
} as const;
