import type { ZjudingPage } from "../../../core/types";

export type ZjudingAppId =
  | "learn"
  | "smart_classroom"
  | "campus_map"
  | "network_account"
  | "logistics"
  | "lost_found"
  | "visitor_preview"
  | "library"
  | "language_cards"
  | "feedback_draft"
  | "all_apps";

export type ZjudingUtilityPanelId =
  | "smart_classroom"
  | "network_account"
  | "logistics"
  | "lost_found"
  | "visitor_preview"
  | "language_cards"
  | "feedback_draft"
  | "all_apps"
  | "contacts"
  | "messages"
  | "profile";

export type ZjudingAppTarget =
  | { kind: "page"; page: ZjudingPage }
  | { kind: "campus_map" }
  | { kind: "utility"; panel: ZjudingUtilityPanelId };

export interface ZjudingAppDefinition {
  id: ZjudingAppId;
  label: string;
  icon: string;
  tone: string;
  category: "learning" | "campus" | "service" | "library";
  keywords: readonly string[];
  target: ZjudingAppTarget;
  availability: "always" | "identity" | "campus_map" | "library";
  badge?: string;
}

export interface ZjudingAppAccessContext {
  identityReadable: boolean;
  fullCampusMap: boolean;
  library: boolean;
}

export const ZJUDING_APP_REGISTRY: readonly ZjudingAppDefinition[] = [
  {
    id: "learn",
    label: "学在浙大",
    icon: "学",
    tone: "paper",
    category: "learning",
    keywords: ["学习", "签到", "课程"],
    target: { kind: "page", page: "learn" },
    availability: "always"
  },
  {
    id: "smart_classroom",
    label: "智云课堂",
    icon: "云",
    tone: "violet",
    category: "learning",
    keywords: ["课程", "课堂", "课件", "日程"],
    target: { kind: "utility", panel: "smart_classroom" },
    availability: "identity"
  },
  {
    id: "campus_map",
    label: "校园地图",
    icon: "位",
    tone: "sky",
    category: "campus",
    keywords: ["地图", "导航", "教学楼", "图书馆", "启真湖"],
    target: { kind: "campus_map" },
    availability: "campus_map"
  },
  {
    id: "network_account",
    label: "网络缴费",
    icon: "¥",
    tone: "aqua",
    category: "service",
    keywords: ["校园网", "流量", "账户", "连接"],
    target: { kind: "utility", panel: "network_account" },
    availability: "identity"
  },
  {
    id: "logistics",
    label: "后勤服务",
    icon: "勤",
    tone: "orange",
    category: "service",
    keywords: ["后勤", "报修", "服务", "网络", "图书馆"],
    target: { kind: "utility", panel: "logistics" },
    availability: "identity"
  },
  {
    id: "lost_found",
    label: "失物招领",
    icon: "寻",
    tone: "green",
    category: "service",
    keywords: ["失物", "书包", "证明", "档案"],
    target: { kind: "utility", panel: "lost_found" },
    availability: "identity"
  },
  {
    id: "visitor_preview",
    label: "访客预约",
    icon: "访",
    tone: "cyan",
    category: "service",
    keywords: ["访客", "预约", "入校", "草稿"],
    target: { kind: "utility", panel: "visitor_preview" },
    availability: "identity"
  },
  {
    id: "library",
    label: "图书馆",
    icon: "图",
    tone: "navy",
    category: "library",
    keywords: ["馆藏", "座位", "预约", "图书", "022"],
    target: { kind: "page", page: "library" },
    availability: "library"
  },
  {
    id: "language_cards",
    label: "慧学外语",
    icon: "F",
    tone: "silver",
    category: "learning",
    keywords: ["外语", "英语", "词汇", "卡片"],
    target: { kind: "utility", panel: "language_cards" },
    availability: "identity"
  },
  {
    id: "feedback_draft",
    label: "开发反馈",
    icon: "信",
    tone: "blue",
    category: "service",
    keywords: ["意见", "反馈", "建议", "开发者", "GitHub", "Issue"],
    target: { kind: "utility", panel: "feedback_draft" },
    availability: "identity",
    badge: "新"
  },
  {
    id: "all_apps",
    label: "全部",
    icon: "▦",
    tone: "grid",
    category: "campus",
    keywords: ["全部", "应用", "工作台"],
    target: { kind: "utility", panel: "all_apps" },
    availability: "identity"
  }
] satisfies readonly ZjudingAppDefinition[];

const appById = {} as Record<ZjudingAppId, ZjudingAppDefinition>;
for (const app of ZJUDING_APP_REGISTRY) {
  appById[app.id] = app;
}
export const ZJUDING_APP_BY_ID: Readonly<Record<ZjudingAppId, ZjudingAppDefinition>> = appById;

export function isZjudingAppAvailable(
  app: ZjudingAppDefinition,
  context: ZjudingAppAccessContext
): boolean {
  if (app.availability === "always") return true;
  if (app.availability === "identity") return context.identityReadable;
  if (app.availability === "campus_map") return context.fullCampusMap;
  return context.library;
}

export function matchesZjudingAppQuery(app: ZjudingAppDefinition, query: string): boolean {
  const normalized = query.trim().toLocaleLowerCase("zh-CN");
  if (!normalized) return true;
  return [app.label, app.id, ...app.keywords]
    .some((value) => value.toLocaleLowerCase("zh-CN").includes(normalized));
}
