import {
  createIdeaSchema,
  consentVersion,
  type CreateIdea,
  type Idea,
  type User,
} from "@755/contracts";
export const CHANNELS = {
  chapter: "本章说",
  feedback: "反馈卡点",
  story: "分享经历",
};
export const STATUSES = {
  received: "已收录",
  discussion: "待讨论",
  production: "制作中",
  playable: "可试玩",
  published: "已发布",
  closed: "暂缓处理",
};
export const CATEGORIES = {
  story: "故事与剧情",
  gameplay: "玩法脑洞",
  experience: "操作与体验",
};
export type Channel = keyof typeof CHANNELS;
export type Status = keyof typeof STATUSES;
export type Intent =
  | { kind: "none" }
  | { kind: "compose" }
  | { kind: "mine" }
  | { kind: "profile" }
  | { kind: "like"; id: string; value: boolean }
  | { kind: "rating"; id: string; value: number | null };
export type Draft = CreateIdea & { accepted: boolean };
export const emptyDraft: Draft = {
  title: "",
  body: "",
  chapterId: "general",
  channel: "story",
  category: "story",
  spoiler: false,
  anonymous: false,
  termsVersion: consentVersion,
  adaptationConsent: false,
  credit: { mode: "anonymous", name: "" },
  accepted: false,
};
const draftKey = "755-draft-v2",
  intentKey = "755-login-intent-v1";
function read(key: string) {
  try {
    const item = JSON.parse(sessionStorage.getItem(key) ?? "null");
    if (
      !item ||
      typeof item.expires !== "number" ||
      item.expires < Date.now()
    ) {
      sessionStorage.removeItem(key);
      return null;
    }
    return item.value;
  } catch {
    return null;
  }
}
function save(key: string, value: unknown, ttl: number) {
  try {
    sessionStorage.setItem(
      key,
      JSON.stringify({ expires: Date.now() + ttl, value }),
    );
  } catch {
    /* Storage can be unavailable in a private browser. */
  }
}
export function readDraft(): Draft {
  const value = read(draftKey);
  // Validate a draft without persisting a confirmed agreement across schema versions.
  if (!value || typeof value !== "object") return { ...emptyDraft };
  const { accepted, ...input } = value;
  if (typeof input.title !== "string" || typeof input.body !== "string")
    return { ...emptyDraft };
  const checked = createIdeaSchema.safeParse({
    ...input,
    title: input.title || "草稿",
    body: input.body || "草稿",
  });
  if (!checked.success) return { ...emptyDraft };
  return {
    ...checked.data,
    title: input.title,
    body: input.body,
    accepted: accepted === true,
  };
}
export function saveDraft(value: Draft) {
  save(draftKey, value, 2 * 60 * 60 * 1000);
}
export function clearDraft() {
  try {
    sessionStorage.removeItem(draftKey);
  } catch {}
}
export function saveIntent(value: Intent) {
  save(intentKey, value, 10 * 60 * 1000);
}
export function takeIntent(): Intent | null {
  const value = read(intentKey);
  try {
    sessionStorage.removeItem(intentKey);
  } catch {}
  if (!value || typeof value !== "object") return null;
  if (
    value.kind === "none" ||
    value.kind === "compose" ||
    value.kind === "mine" ||
    value.kind === "profile"
  )
    return { kind: value.kind };
  if (!/^[a-f0-9-]{36}$/.test(value.id ?? "")) return null;
  if (value.kind === "like" && typeof value.value === "boolean") return value;
  if (
    value.kind === "rating" &&
    (value.value === null ||
      (Number.isInteger(value.value) && value.value >= 1 && value.value <= 5))
  )
    return value;
  return null;
}
export function entryDraft(): Draft {
  const draft = readDraft(),
    params = new URLSearchParams(location.search),
    entry = params.get("entry");
  if (entry && entry in CHANNELS)
    return {
      ...draft,
      channel: entry as Channel,
      chapterId: /^[a-z0-9-]+$/.test(params.get("chapter") ?? "")
        ? params.get("chapter")!
        : "general",
    };
  return draft;
}
export const errorMessages: Record<string, string> = {
  cancelled: "这次登录已取消，草稿仍保留在当前标签页。",
  failed: "登录没有完成或链接已过期，请重新点击登录。",
};
export const canReadChapter = (user: User | null, order: number) =>
  Boolean(user && user.progressOrder >= order);
export const date = (value: string) =>
  new Date(value).toLocaleString("zh-CN", {
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
export const statusOf = (idea: Idea) => STATUSES[idea.status];
