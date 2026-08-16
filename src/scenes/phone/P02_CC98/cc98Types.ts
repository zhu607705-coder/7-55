/**
 * CC98 通用帖子类型。index.tsx 的列表/编辑流与 ThreadPage.tsx 的详情页共用;
 * 启真湖划船记录帖(journal 单帖)复用同一形状,但不侵入通用 ThreadPage 的数据来源。
 */

export type AvatarVariant = "warrior" | "blonde" | "anonymous";

export interface Cc98Post {
  id: string;
  author: string;
  avatar: AvatarVariant;
  rank: string;
  board: string;
  title: string;
  replies: string;
  views: string;
  time: string;
  body: string;
  threadOperation?: { user: string; action: string; reason: string };
  threadMetrics?: { favorites: string; likes: string; dislikes: string };
  threadReplies?: Array<{
    personaId: string;
    time: string;
    floor: string;
    role?: string;
    text: string;
    image?: "cc98_forum_treasure";
    caption?: string;
    likes: string;
    dislikes: string;
  }>;
}

export interface ThreadReply {
  personaId: string;
  time: string;
  floor: string;
  role?: string;
  text: string;
  image?: string;
  caption?: string;
  likes: string;
  dislikes: string;
}

export interface ThreadPost {
  author: string;
  title: string;
  body: string;
  board: string;
  time: string;
  avatar?: string;
  views?: string;
  threadOperation?: { user: string; action: string; reason: string };
  threadMetrics?: { favorites: string; likes: string; dislikes: string };
  threadReplies?: ThreadReply[];
}

/** 启真湖划船记录帖的唯一 thread id;journal 投影、controller 与单帖 UI 共用。 */
export const QIZHEN_JOURNAL_THREAD_ID = "qizhen-journal-thread";
