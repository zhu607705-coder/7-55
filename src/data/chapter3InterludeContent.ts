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
      label: "恢复时间窗起点",
      hints: [
        "先寻找能够证明离湖时刻的原始记录。",
        "CC98 划船记录保留了带时间的最后回复。",
        "打开划船记录帖并保存最后一条离湖回复。"
      ],
      recommendedScene: "cc98"
    },
    photos: {
      id: "chapter_three_interlude_photos",
      label: "恢复三张照片的先后关系",
      hints: [
        "留意三张照片中发生跳变的位置。",
        "用画面中不移动的参照物比较纸条位置。",
        "选择能形成一次连续水平移动的照片顺序。"
      ],
      recommendedScene: "photos"
    },
    voice: {
      id: "chapter_three_interlude_voice",
      label: "从七段录音中恢复移动过程",
      hints: [
        "先比较各段录音中的空间和环境声是否连续。",
        "筛出属于同一次移动过程的四段录音。",
        "再依据水声、进门声和广播声的变化排列四段录音。"
      ],
      recommendedScene: "voice_memos"
    },
    wechat: {
      id: "chapter_three_interlude_wechat",
      label: "保存两条地点约束",
      hints: [
        "微信里有两条需要打开后才能确认的记录。",
        "分别检查楼宇通知与群聊中的路线图片。",
        "打开相关消息，并保存闭楼通知和入口截图。"
      ],
      recommendedScene: "wechat"
    },
    network: {
      id: "chapter_three_interlude_network",
      label: "核对校园网络记录",
      hints: [
        "用已经保存的两条约束逐步缩小网络记录范围。",
        "每个有效筛选条件都会让候选记录数量下降。",
        "完成三项筛选，再打开唯一保留下来的短会话记录。"
      ],
      recommendedScene: "zjuding"
    },
    exclusions: {
      id: "chapter_three_interlude_exclusions",
      label: "排除旧时间记录",
      hints: [
        "三条旧记录中，数字的含义和时钟可信度并不相同。",
        "分别判断编号、独立事件和未同步时钟能否作为本次时间。",
        "为三条旧时间各选择对应的排除理由。"
      ],
      recommendedScene: "timeline_recovery"
    },
    timeline: {
      id: "chapter_three_interlude_timeline",
      label: "核对自动恢复的时间线",
      hints: [
        "证据齐全后，系统会按记录来源自动汇总时间线。",
        "检查四项证据是否都已进入恢复结果。",
        "返回记录恢复页，核对自动生成的四行时间线。"
      ],
      recommendedScene: "timeline_recovery"
    },
    destination: {
      id: "chapter_three_interlude_destination",
      label: "根据证据确认目的地",
      hints: [
        "比较每个候选地点与四项证据是否存在冲突。",
        "同时核对水面离开、室内路线、网络记录和闭楼广播。",
        "在记录恢复页选择唯一没有证据冲突的地点。"
      ],
      recommendedScene: "timeline_recovery"
    },
    replay: {
      id: "chapter_three_interlude_replay",
      label: "播放恢复回放",
      hints: [
        "目的地已经确认，可以播放恢复结果。",
        "回放结束后会进入第四章任务卡。",
        "在记录恢复页启动回放。"
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
