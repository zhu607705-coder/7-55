import qizhenContent from "../data/chapter3-qizhen-lake.content.json";
import personaData from "../data/cc98.thread-personas.json";
import type {
  QizhenJournalDraft,
  QizhenJournalState,
  QizhenJournalStatus,
  QizhenPhotoRecipe,
  QizhenPhotoRecord,
  QizhenPhotoSpotId,
  QizhenPhotoTag
} from "../core/types";

/**
 * 启真湖拍照记录(CC98 单帖)的纯函数模型。不依赖 store;controller 与 UI 共享。
 *
 * 单位约定(与 QizhenLakeScene 的皮划艇 runtime 一致):
 * - speed 单位 px/s,前进上限 340(KAYAK_MAX_SPEED);
 * - roll 为归一化侧倾,|roll| ∈ [0, 0.92),0.92 即翻船(KAYAK_CAPSIZE_THRESHOLD),
 *   HUD 上显示为百分比。
 */

/** 船速绝对值超过该阈值时记 "high_speed"。约为一桨冲量(104 px/s)以内的滑行速度。 */
export const QIZHEN_PHOTO_SPEED_TAG_THRESHOLD = 90;

/** 侧倾绝对值超过该阈值时记 "tilted"(≈ HUD 侧倾表 18%,远低于 70% 危险线)。 */
export const QIZHEN_PHOTO_ROLL_TAG_THRESHOLD = 0.18;

/** 全部照片标签,validateJournalContent 用它检查 tagLabels 覆盖。 */
export const QIZHEN_PHOTO_TAGS: readonly QizhenPhotoTag[] = [
  "composition_ok",
  "tilted",
  "high_speed",
  "ripple_clear",
  "ripple_broken",
  "swan_near",
  "swan_far",
  "swan_aftermath"
];

/** 四个拍摄点;lake_center 是主帖用图,其余为可选补拍。 */
export const QIZHEN_PHOTO_SPOT_IDS: readonly QizhenPhotoSpotId[] = [
  "lake_center",
  "dock",
  "reflection",
  "swan_cove"
];

export const QIZHEN_OPTIONAL_SPOT_IDS = ["dock", "reflection", "swan_cove"] as const;

/** 相机 UI 文案里值被合同钉死的键;title 与 hint 为内容侧自写文案。 */
export const QIZHEN_JOURNAL_CAMERA_PINNED_COPY: Readonly<Record<string, string>> = {
  shutter: "拍摄",
  close: "收起相机",
  retake: "重拍",
  draftMainTitle: "选择主帖标题",
  draftMainStatus: "选择主帖状态",
  draftSpotCaption: "选择补拍说明",
  saveDraft: "存为草稿",
  draftSaved: "草稿已保存,可前往 CC98 发布。",
  speedLabel: "速度",
  rollLabel: "侧倾"
};

export const QIZHEN_JOURNAL_CAMERA_KEYS: readonly string[] = [
  "title",
  "shutter",
  "close",
  "retake",
  "draftMainTitle",
  "draftMainStatus",
  "draftSpotCaption",
  "saveDraft",
  "draftSaved",
  "speedLabel",
  "rollLabel",
  "hint"
];

/** 单帖 UI 文案里值被合同钉死的键;board 与 networkError.title/body 为内容侧自写文案。 */
export const QIZHEN_JOURNAL_THREAD_PINNED_COPY: Readonly<Record<string, string>> = {
  authorRole: "楼主",
  draftBadge: "草稿",
  publishMain: "发布主帖",
  publishing: "发布中…",
  publishReply: "追加到帖子",
  ownerOnly: "只看楼主",
  showAll: "查看全部",
  continueSupplement: "继续补充",
  returnToLake: "返回湖面",
  archivedNotice: "帖子已归档,仅供查看。",
  mainPhotoAlt: "湖心主图",
  replyPhotoAlt: "补拍照片"
};

export const QIZHEN_JOURNAL_THREAD_KEYS: readonly string[] = [
  "board",
  ...Object.keys(QIZHEN_JOURNAL_THREAD_PINNED_COPY)
];

export const QIZHEN_JOURNAL_NETWORK_ERROR_PINNED_COPY: Readonly<Record<string, string>> = {
  openControlCenter: "打开控制中心",
  returnToLake: "返回湖面",
  keepEditing: "继续编辑"
};

export const QIZHEN_JOURNAL_NETWORK_ERROR_KEYS: readonly string[] = [
  "title",
  "body",
  ...Object.keys(QIZHEN_JOURNAL_NETWORK_ERROR_PINNED_COPY)
];

/** 路人回复池规模下限:主帖池 6 条,三个补拍池各 3 条。 */
export const QIZHEN_JOURNAL_REPLY_POOL_MIN: Readonly<Record<"main" | "dock" | "reflection" | "swan_cove", number>> = {
  main: 6,
  dock: 3,
  reflection: 3,
  swan_cove: 3
};

/** replyPools 的单条路人回复;personaId 必须存在于 cc98.thread-personas.json。 */
export interface QizhenJournalPasserbyReply {
  id: string;
  personaId: string;
  text: string;
  likes: string;
}

export function createInitialJournalState(): QizhenJournalState {
  return {
    status: "locked",
    threadId: "",
    threadSeed: 0,
    mainPhoto: null,
    optionalPhotos: {},
    mainTitleId: null,
    mainStatusId: null,
    publishedSpotIds: [],
    pendingDraft: null,
    summaryChoice: null,
    summaryPublished: false,
    fishingAssistUnlocked: false,
    fishingAssistConsumed: false,
    memoryCardUnlocked: false
  };
}

export interface QizhenPhotoTagInput {
  recipe: QizhenPhotoRecipe;
  speed: number;
  roll: number;
}

/**
 * 拍摄瞬间的标签推导,输出顺序固定:速度/侧倾/构图 → 水纹 → 黑天鹅。
 * 速度与侧倾都在阈值内才记 "composition_ok";bucket 缺省时不产生对应标签,
 * 所以湖心照可以没有黑天鹅标签、码头照可以没有水纹标签。
 */
export function derivePhotoTags(input: QizhenPhotoTagInput): QizhenPhotoTag[] {
  const tags: QizhenPhotoTag[] = [];
  const overSpeed = Math.abs(input.speed) > QIZHEN_PHOTO_SPEED_TAG_THRESHOLD;
  const overRoll = Math.abs(input.roll) > QIZHEN_PHOTO_ROLL_TAG_THRESHOLD;
  if (overSpeed) tags.push("high_speed");
  if (overRoll) tags.push("tilted");
  if (!overSpeed && !overRoll) tags.push("composition_ok");
  const ripple = input.recipe.rippleClarityBucket;
  if (ripple === "clear") {
    tags.push("ripple_clear");
  } else if (ripple === "partial" || ripple === "lost") {
    tags.push("ripple_broken");
  }
  const swan = input.recipe.swanDistanceBucket;
  if (swan === "near") {
    tags.push("swan_near");
  } else if (swan === "far") {
    tags.push("swan_far");
  } else if (swan === "gone") {
    tags.push("swan_aftermath");
  }
  return tags;
}

/**
 * 幂等键:同一拍摄点、同一捕获时刻重试得到同一 id。capturedAtSeconds 应取
 * 湖区会话的单调秒数而不是墙钟,保证网络重试与重复点击不会生成重复楼层。
 */
export function photoIdFor(spotId: QizhenPhotoSpotId, capturedAtSeconds: number): string {
  return `qizhen-photo-${spotId}-${capturedAtSeconds}`;
}

export function draftIdFor(photoId: string): string {
  return `qizhen-draft-${photoId}`;
}

export type QizhenCaptureCheck = { ok: true } | { ok: false; reason: string };

/**
 * 每地点只保留一条(upsert 覆盖),所以解锁后任何地点都可拍摄;主帖发布前
 * lake_center 之外同样可自由拍。锁定只在帖子未开启或已归档时发生;追逐期间
 * 的拒绝由 controller 按 phase 处理,不在 journal 状态内。
 */
export function canCaptureSpot(journal: QizhenJournalState, spotId: QizhenPhotoSpotId): QizhenCaptureCheck {
  if (!QIZHEN_PHOTO_SPOT_IDS.includes(spotId)) return { ok: false, reason: "unknown_spot" };
  if (journal.status === "locked") return { ok: false, reason: "journal_locked" };
  if (journal.status === "archived") return { ok: false, reason: "journal_archived" };
  return { ok: true };
}

/** 不可变写入一张照片:lake_center 进 mainPhoto,其余进 optionalPhotos。 */
export function upsertPhoto(journal: QizhenJournalState, photo: QizhenPhotoRecord): QizhenJournalState {
  if (photo.spotId === "lake_center") {
    return { ...journal, mainPhoto: photo };
  }
  return {
    ...journal,
    optionalPhotos: { ...journal.optionalPhotos, [photo.spotId]: photo }
  };
}

/** 暂存草稿;主帖草稿同步标题/状态选择,并把 capture_ready 推进到 main_draft。 */
export function applyDraft(journal: QizhenJournalState, draft: QizhenJournalDraft): QizhenJournalState {
  if (draft.kind === "main") {
    return {
      ...journal,
      status: journal.status === "capture_ready" ? "main_draft" : journal.status,
      mainTitleId: draft.titleId,
      mainStatusId: draft.statusId,
      pendingDraft: draft
    };
  }
  return { ...journal, pendingDraft: draft };
}

export function clearPendingDraft(journal: QizhenJournalState): QizhenJournalState {
  return journal.pendingDraft === null ? journal : { ...journal, pendingDraft: null };
}

/** 已拍补拍地点数(0–3),用于两处钓鱼辅助、三处记录卡的奖励投影。 */
export function countOptionalPhotos(journal: QizhenJournalState): number {
  return QIZHEN_OPTIONAL_SPOT_IDS.filter((spotId) => journal.optionalPhotos[spotId] !== undefined).length;
}

/** 标记某地点的楼主回复已发布;每地点只追加一次,重复调用不产生重复项。 */
export function markSpotPublished(journal: QizhenJournalState, spotId: QizhenPhotoSpotId): QizhenJournalState {
  if (journal.publishedSpotIds.includes(spotId)) return journal;
  return { ...journal, publishedSpotIds: [...journal.publishedSpotIds, spotId] };
}

interface JournalContentEntry {
  id: string;
  text: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function validateEntries(value: unknown, label: string, errors: string[]): JournalContentEntry[] {
  if (!Array.isArray(value)) {
    errors.push(`journal.${label} must be an array`);
    return [];
  }
  const entries: JournalContentEntry[] = [];
  value.forEach((item, index) => {
    if (!isRecord(item) || typeof item.id !== "string" || item.id.length === 0) {
      errors.push(`journal.${label}[${index}].id must be a non-empty string`);
      return;
    }
    if (typeof item.text !== "string" || item.text.length === 0) {
      errors.push(`journal.${label}[${index}].text must be a non-empty string`);
      return;
    }
    entries.push({ id: item.id, text: item.text });
  });
  return entries;
}

/**
 * 校验 content JSON 的 journal 节,返回错误列表(空数组 = 通过)。
 * scripts/verify-qizhen-journal.mjs 做等价检查,二者判定必须一致。
 */
export function validateJournalContent(content: unknown): string[] {
  const errors: string[] = [];
  const journal = isRecord(content) ? content.journal : undefined;
  if (!isRecord(journal)) {
    return ["journal section is missing or not an object"];
  }

  const titles = validateEntries(journal.titles, "titles", errors);
  if (Array.isArray(journal.titles) && titles.length !== 3) {
    errors.push(`journal.titles must contain exactly 3 entries, got ${titles.length}`);
  }
  const statuses = validateEntries(journal.statuses, "statuses", errors);
  if (Array.isArray(journal.statuses) && statuses.length !== 3) {
    errors.push(`journal.statuses must contain exactly 3 entries, got ${statuses.length}`);
  }

  const allEntries: Array<{ label: string; entry: JournalContentEntry }> = [
    ...titles.map((entry) => ({ label: "titles", entry })),
    ...statuses.map((entry) => ({ label: "statuses", entry }))
  ];
  const spotCaptions = journal.spotCaptions;
  if (!isRecord(spotCaptions)) {
    errors.push("journal.spotCaptions must be an object");
  } else {
    for (const spotId of QIZHEN_OPTIONAL_SPOT_IDS) {
      const entries = validateEntries(spotCaptions[spotId], `spotCaptions.${spotId}`, errors);
      if (Array.isArray(spotCaptions[spotId]) && entries.length === 0) {
        errors.push(`journal.spotCaptions.${spotId} must not be empty`);
      }
      for (const entry of entries) {
        allEntries.push({ label: `spotCaptions.${spotId}`, entry });
      }
    }
  }

  const replyPools = journal.replyPools;
  if (!isRecord(replyPools)) {
    errors.push("journal.replyPools must be an object");
  } else {
    const personaIds = new Set(personaData.map((persona) => persona.id));
    for (const [poolKey, minSize] of Object.entries(QIZHEN_JOURNAL_REPLY_POOL_MIN)) {
      const pool = replyPools[poolKey];
      const entries = validateEntries(pool, `replyPools.${poolKey}`, errors);
      if (Array.isArray(pool) && entries.length < minSize) {
        errors.push(`journal.replyPools.${poolKey} must contain at least ${minSize} entries, got ${entries.length}`);
      }
      if (Array.isArray(pool)) {
        pool.forEach((item, index) => {
          if (!isRecord(item)) return;
          if (typeof item.personaId !== "string" || !personaIds.has(item.personaId)) {
            errors.push(`journal.replyPools.${poolKey}[${index}].personaId must be an id from cc98.thread-personas.json`);
          }
          if (typeof item.likes !== "string" || item.likes.length === 0) {
            errors.push(`journal.replyPools.${poolKey}[${index}].likes must be a non-empty string`);
          }
        });
      }
      for (const entry of entries) {
        allEntries.push({ label: `replyPools.${poolKey}`, entry });
      }
    }
  }

  const seenIds = new Map<string, string>();
  for (const { label, entry } of allEntries) {
    const existing = seenIds.get(entry.id);
    if (existing !== undefined) {
      errors.push(`duplicate id "${entry.id}" in journal.${label} and journal.${existing}`);
    } else {
      seenIds.set(entry.id, label);
    }
  }

  const tagLabels = journal.tagLabels;
  if (!isRecord(tagLabels)) {
    errors.push("journal.tagLabels must be an object");
  } else {
    for (const tag of QIZHEN_PHOTO_TAGS) {
      if (typeof tagLabels[tag] !== "string" || (tagLabels[tag] as string).length === 0) {
        errors.push(`journal.tagLabels is missing a label for tag "${tag}"`);
      }
    }
    for (const key of Object.keys(tagLabels)) {
      if (!QIZHEN_PHOTO_TAGS.includes(key as QizhenPhotoTag)) {
        errors.push(`journal.tagLabels has unknown tag "${key}"`);
      }
    }
  }

  const spotNames = journal.spotNames;
  if (!isRecord(spotNames)) {
    errors.push("journal.spotNames must be an object");
  } else {
    for (const spotId of QIZHEN_PHOTO_SPOT_IDS) {
      if (typeof spotNames[spotId] !== "string" || (spotNames[spotId] as string).length === 0) {
        errors.push(`journal.spotNames is missing a name for spot "${spotId}"`);
      }
    }
    for (const key of Object.keys(spotNames)) {
      if (!QIZHEN_PHOTO_SPOT_IDS.includes(key as QizhenPhotoSpotId)) {
        errors.push(`journal.spotNames has unknown spot "${key}"`);
      }
    }
  }

  const camera = journal.camera;
  if (!isRecord(camera)) {
    errors.push("journal.camera must be an object");
  } else {
    for (const key of QIZHEN_JOURNAL_CAMERA_KEYS) {
      if (typeof camera[key] !== "string" || (camera[key] as string).length === 0) {
        errors.push(`journal.camera.${key} must be a non-empty string`);
      }
    }
    for (const [key, pinned] of Object.entries(QIZHEN_JOURNAL_CAMERA_PINNED_COPY)) {
      if (camera[key] !== undefined && camera[key] !== pinned) {
        errors.push(`journal.camera.${key} must be the pinned copy "${pinned}"`);
      }
    }
  }

  const thread = journal.thread;
  if (!isRecord(thread)) {
    errors.push("journal.thread must be an object");
  } else {
    for (const key of QIZHEN_JOURNAL_THREAD_KEYS) {
      if (typeof thread[key] !== "string" || (thread[key] as string).length === 0) {
        errors.push(`journal.thread.${key} must be a non-empty string`);
      }
    }
    for (const [key, pinned] of Object.entries(QIZHEN_JOURNAL_THREAD_PINNED_COPY)) {
      if (thread[key] !== undefined && thread[key] !== pinned) {
        errors.push(`journal.thread.${key} must be the pinned copy "${pinned}"`);
      }
    }
    const networkError = thread.networkError;
    if (!isRecord(networkError)) {
      errors.push("journal.thread.networkError must be an object");
    } else {
      for (const key of QIZHEN_JOURNAL_NETWORK_ERROR_KEYS) {
        if (typeof networkError[key] !== "string" || (networkError[key] as string).length === 0) {
          errors.push(`journal.thread.networkError.${key} must be a non-empty string`);
        }
      }
      for (const [key, pinned] of Object.entries(QIZHEN_JOURNAL_NETWORK_ERROR_PINNED_COPY)) {
        if (networkError[key] !== undefined && networkError[key] !== pinned) {
          errors.push(`journal.thread.networkError.${key} must be the pinned copy "${pinned}"`);
        }
      }
    }
  }

  return errors;
}


/* ---------------------------------------------------------------------------
 * CC98 单帖投影:回复选择与楼层分配全部是纯确定性推导,只读存档事实与
 * seed,不写回任何选中结果;同一存档刷新后得到相同帖子。
 * ------------------------------------------------------------------------- */

/** 与 cc98Types.QIZHEN_JOURNAL_THREAD_ID 同值;modules 不反向依赖 scenes,保留字面量。 */
const QIZHEN_JOURNAL_THREAD_ID_LITERAL = "qizhen-journal-thread";

const journalContent = qizhenContent.journal;

/** FNV-1a 32-bit,把标签与计数折叠成一个整数 salt。 */
function fnv1a(text: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

/** seed 与 salt 的混合,保证相邻 salt 也产生不相关的洗牌序列。 */
function mixSeedSalt(seed: number, salt: number): number {
  let h = (seed >>> 0) ^ 0x9e3779b9;
  h = Math.imul(h ^ (salt >>> 0), 0x85ebca6b);
  h ^= h >>> 13;
  h = Math.imul(h, 0xc2b2ae35);
  h ^= h >>> 16;
  return h >>> 0;
}

function mulberry32(state: number): () => number {
  let a = state >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * 确定性路人回复选择:mixSeedSalt(seed, salt) 作为 mulberry32 种子做
 * Fisher–Yates 洗牌,取前 count 条(超出池规模时截断)。同一 seed/salt
 * 输出完全一致;不同 seed 产生受控变化。回复文本不落盘。
 */
export function selectJournalPasserbyReplies(
  pool: readonly QizhenJournalPasserbyReply[],
  seed: number,
  count: number,
  salt: number
): QizhenJournalPasserbyReply[] {
  const limit = Math.max(0, Math.min(count, pool.length));
  const indices = pool.map((_, index) => index);
  const random = mulberry32(mixSeedSalt(seed, salt));
  for (let i = indices.length - 1; i > 0; i -= 1) {
    const j = Math.floor(random() * (i + 1));
    const held = indices[i];
    indices[i] = indices[j];
    indices[j] = held;
  }
  return indices.slice(0, limit).map((index) => pool[index]);
}

/** 单个发布时刻的 salt:照片标签 + 翻船/碰撞/警戒计数 + 发布顺序。 */
function journalReplySalt(
  tags: readonly QizhenPhotoTag[],
  input: { capsizeCount: number; dockCollisionCount: number; swanAlertLevel: number },
  publishOrder: number
): number {
  return fnv1a([
    ...tags,
    `capsize:${input.capsizeCount}`,
    `dockCollision:${input.dockCollisionCount}`,
    `swanAlert:${input.swanAlertLevel}`,
    `order:${publishOrder}`
  ].join("\n"));
}

/** 楼主补拍回复的 caption 投影:按 photo.id 哈希在该地点说明中定选,刷新不变。 */
function journalSpotCaption(photo: QizhenPhotoRecord): string {
  if (photo.spotId === "lake_center") return "";
  const entries = journalContent.spotCaptions[photo.spotId];
  if (entries.length === 0) return "";
  return entries[fnv1a(photo.id) % entries.length].text;
}

/** 主帖正文:状态文案 + 主图标签,组合成一两句楼主口吻。 */
function journalMainCaption(statusText: string, mainPhoto: QizhenPhotoRecord | null): string {
  if (mainPhoto === null) {
    return `${statusText}。主图还没拍，等我先把船划到湖心。`;
  }
  const labels = mainPhoto.tags
    .map((tag) => journalContent.tagLabels[tag])
    .filter((label) => label.length > 0);
  const tagPart = labels.length > 0 ? `标签：${labels.join("、")}。` : "";
  return `${statusText}。主图是在湖心按的快门，${tagPart}先占 1 楼，后面慢慢补。`;
}

export interface QizhenJournalThreadReplyView {
  id: string;
  kind: "owner" | "passerby";
  floor: number;
  personaId: string | null;
  text: string;
  photo: QizhenPhotoRecord | null;
  likes: string;
}
export interface QizhenJournalThreadView {
  status: QizhenJournalStatus;
  threadId: string;
  title: string;
  statusText: string;
  board: string;
  mainPhoto: QizhenPhotoRecord | null;
  mainCaption: string;
  replies: QizhenJournalThreadReplyView[];
  pendingDraft: QizhenJournalDraft | null;
  unpublishedSpotIds: QizhenPhotoSpotId[];
  archived: boolean;
}

/**
 * 从 journal 事实投影唯一主帖视图。纯函数:同一 journal + input 输出完全一致,
 * 刷新与"只看楼主"筛选不改变楼层。
 *
 * 楼层规则:主帖固定 1 楼(视图主体,不在 replies 内);主帖发出后先排 2–3 条
 * 主帖池路人回复;之后按 publishedSpotIds 顺序交错,每个地点先排一条楼主补拍
 * 回复(带照片),再排 1–2 条该地点池的路人反应,楼层从 2 起连续编号。
 * 路人选择读 threadSeed、照片 tags、capsizeCount/dockCollisionCount/swanAlertLevel
 * 与发布顺序;补拍 caption 按 photo.id 投影。status 为 main_draft(或更早)时
 * title/statusText 给「未定」占位。
 */
export function projectJournalThread(
  journal: QizhenJournalState,
  input: { capsizeCount: number; dockCollisionCount: number; swanAlertLevel: number }
): QizhenJournalThreadView {
  const mainPublished =
    journal.status === "open" || journal.status === "summary_ready" || journal.status === "archived";
  const titleEntry = journalContent.titles.find((entry) => entry.id === journal.mainTitleId);
  const statusEntry = journalContent.statuses.find((entry) => entry.id === journal.mainStatusId);
  const title = mainPublished && titleEntry !== undefined ? titleEntry.text : "（标题未定）";
  const statusText = mainPublished && statusEntry !== undefined ? statusEntry.text : "（状态未定）";

  const replies: QizhenJournalThreadReplyView[] = [];
  let nextFloor = 2;
  if (mainPublished && journal.mainPhoto !== null) {
    const mainSalt = journalReplySalt(journal.mainPhoto.tags, input, 0);
    const mainPicked = selectJournalPasserbyReplies(
      journalContent.replyPools.main,
      journal.threadSeed,
      2 + (mainSalt % 2),
      mainSalt
    );
    for (const picked of mainPicked) {
      replies.push({
        id: picked.id,
        kind: "passerby",
        floor: nextFloor,
        personaId: picked.personaId,
        text: picked.text,
        photo: null,
        likes: picked.likes
      });
      nextFloor += 1;
    }
    journal.publishedSpotIds.forEach((spotId, publishIndex) => {
      if (spotId === "lake_center") return;
      const photo = journal.optionalPhotos[spotId];
      if (photo === undefined) return;
      replies.push({
        id: `owner-${photo.id}`,
        kind: "owner",
        floor: nextFloor,
        personaId: null,
        text: journalSpotCaption(photo),
        photo,
        likes: String(2 + (fnv1a(photo.id) % 30))
      });
      nextFloor += 1;
      const salt = journalReplySalt(photo.tags, input, publishIndex + 1);
      const spotPicked = selectJournalPasserbyReplies(
        journalContent.replyPools[spotId],
        journal.threadSeed,
        1 + (salt % 2),
        salt
      );
      for (const picked of spotPicked) {
        replies.push({
          id: picked.id,
          kind: "passerby",
          floor: nextFloor,
          personaId: picked.personaId,
          text: picked.text,
          photo: null,
          likes: picked.likes
        });
        nextFloor += 1;
      }
    });
  }

  return {
    status: journal.status,
    threadId: journal.threadId !== "" ? journal.threadId : QIZHEN_JOURNAL_THREAD_ID_LITERAL,
    title,
    statusText,
    board: journalContent.thread.board,
    mainPhoto: journal.mainPhoto,
    mainCaption: journalMainCaption(statusText, journal.mainPhoto),
    replies,
    pendingDraft: journal.pendingDraft,
    unpublishedSpotIds: QIZHEN_OPTIONAL_SPOT_IDS.filter(
      (spotId) => journal.optionalPhotos[spotId] !== undefined && !journal.publishedSpotIds.includes(spotId)
    ),
    archived: journal.status === "archived"
  };
}
