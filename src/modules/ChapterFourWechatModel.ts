import type { GameState } from "../core/types";
import { isLegacyChapterFourPhoneGatePhase } from "../core/FeatureAccess";
import { CHAPTER_FOUR_CC98_CLUES } from "./ChapterFourCc98Model";

export const CHAPTER_FOUR_WECHAT_CLUES = Object.freeze({
  officialNoticeRead: "wechat_official_notice_read",
  elevatorAudioArchived: "wechat_elevator_audio_archived",
  studentRouteSaved: "wechat_student_route_saved",
  wayfindingPhotosArchived: "wechat_wayfinding_photos_archived",
  wayfindingCompared: "wechat_wayfinding_compared"
});

export type ChapterFourWechatClueId =
  typeof CHAPTER_FOUR_WECHAT_CLUES[keyof typeof CHAPTER_FOUR_WECHAT_CLUES];

export interface ChapterFourWechatProjection {
  active: boolean;
  officialNoticeRead: boolean;
  elevatorAudioAvailable: boolean;
  elevatorAudioArchived: boolean;
  studentRouteAvailable: boolean;
  studentRouteSaved: boolean;
  wayfindingPhotosAvailable: boolean;
  wayfindingPhotosArchived: boolean;
  wayfindingCompared: boolean;
  archiveCount: number;
}

export interface ChapterFourWechatObjective {
  id: "official_notice" | "elevator_audio" | "study_index" | "student_route" | "wayfinding_photos" | "wayfinding_compare";
  label: string;
  hint: string;
}

export function selectChapterFourWechatProjection(
  state: GameState["chapter4"]
): ChapterFourWechatProjection {
  const clues = new Set(state.clueIds);
  const active = state.prologueSeen && isLegacyChapterFourPhoneGatePhase(state.phase);
  const officialNoticeRead = clues.has(CHAPTER_FOUR_WECHAT_CLUES.officialNoticeRead);
  const elevatorAudioArchived = clues.has(CHAPTER_FOUR_WECHAT_CLUES.elevatorAudioArchived);
  const studentRouteSaved = clues.has(CHAPTER_FOUR_WECHAT_CLUES.studentRouteSaved);
  const wayfindingPhotosArchived = clues.has(CHAPTER_FOUR_WECHAT_CLUES.wayfindingPhotosArchived);
  const wayfindingCompared = clues.has(CHAPTER_FOUR_WECHAT_CLUES.wayfindingCompared);

  return {
    active,
    officialNoticeRead,
    elevatorAudioAvailable: state.elevatorHistoryObserved
      || state.solvedPuzzleIds.includes("elevator_track_sync"),
    elevatorAudioArchived,
    studentRouteAvailable: officialNoticeRead
      && clues.has(CHAPTER_FOUR_CC98_CLUES.studyIndexImported)
      && state.floor === "A2"
      && state.phase === "npc_schedule_route",
    studentRouteSaved,
    wayfindingPhotosAvailable: clues.has("a3_old_signage_observed")
      || state.solvedPuzzleIds.includes("wayfinding_fragment_board"),
    wayfindingPhotosArchived,
    wayfindingCompared,
    archiveCount: [
      officialNoticeRead,
      elevatorAudioArchived,
      studentRouteSaved,
      wayfindingPhotosArchived
    ].filter(Boolean).length
  };
}

export function selectChapterFourWechatObjective(
  state: GameState["chapter4"]
): ChapterFourWechatObjective | null {
  const projection = selectChapterFourWechatProjection(state);
  if (!projection.active) return null;

  if (state.phase === "elevator_track_sync") {
    if (!projection.officialNoticeRead) {
      return {
        id: "official_notice",
        label: "查看校园后勤服务的夜间运行通知",
        hint: "打开微信中的“校园后勤服务”公众号，保存段永平教学楼夜间运行提醒。"
      };
    }
    if (state.elevatorHistoryObserved && !projection.elevatorAudioArchived) {
      return {
        id: "elevator_audio",
        label: "归档主电梯历史提示音",
        hint: "打开微信的文件传输助手，保存刚刚在深色观察中记录的电梯提示音。"
      };
    }
  }

  if (state.phase === "npc_schedule_route" && !projection.studentRouteSaved) {
    if (cluesRequireCc98Import(state)) {
      return {
        id: "study_index",
        label: "从 CC98 导入学习天地资料索引",
        hint: "打开 CC98 的学习天地资料索引帖，选出课程年份、旧讨论和现场核验三项，再导入自习群。"
      };
    }
    return {
      id: "student_route",
      label: "保存麦斯威夜间自习群的路线讨论",
      hint: "打开微信学生群，保存包含东西两侧矛盾描述的群聊截图。"
    };
  }

  if (state.phase === "wayfinding_fragment_board" && projection.wayfindingPhotosAvailable) {
    if (!projection.wayfindingPhotosArchived) {
      return {
        id: "wayfinding_photos",
        label: "归档三楼新旧导视板照片",
        hint: "打开文件传输助手，将当前导视板和深色残影保存在同一组记录中。"
      };
    }
    if (!projection.wayfindingCompared) {
      return {
        id: "wayfinding_compare",
        label: "请朋友对照新旧导视板",
        hint: "在微信朋友聊天中对照两张照片，记下二楼箭头的方向差异。"
      };
    }
  }

  return null;
}

function cluesRequireCc98Import(state: GameState["chapter4"]): boolean {
  return !state.clueIds.includes(CHAPTER_FOUR_CC98_CLUES.studyIndexImported);
}
