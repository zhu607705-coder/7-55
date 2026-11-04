import { z } from "zod";
export * from "./game-save.js";

export const API_VERSION = "v1" as const;
export const chapterSchema = z
  .object({
    id: z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
    title: z.string().min(1).max(80),
    description: z.string().max(500),
    sortOrder: z.number().int().nonnegative(),
    kind: z.enum(["chapter", "future", "general"]),
  })
  .strict();
export type Chapter = z.infer<typeof chapterSchema>;
export const chapterListSchema = z
  .object({ items: z.array(chapterSchema) })
  .strict();
export type ChapterList = z.infer<typeof chapterListSchema>;

export const healthSchema = z.object({
  status: z.literal("ok"),
  service: z.literal("755-platform"),
});
export const readinessSchema = z.object({ status: z.literal("ready") });
export const errorSchema = z.object({
  error: z.object({
    code: z.enum([
      "NOT_FOUND",
      "SERVICE_UNAVAILABLE",
      "INVALID_REQUEST",
      "INTERNAL_ERROR",
      "UNAUTHENTICATED",
      "FORBIDDEN",
      "CONFLICT",
      "RATE_LIMITED",
    ]),
    message: z.string(),
    requestId: z.string(),
  }),
});
export type ApiError = z.infer<typeof errorSchema>;

export const userSchema = z
  .object({
    id: z.uuid(),
    username: z.string(),
    nickname: z.string(),
    isOperator: z.boolean(),
    progressOrder: z.number().int().nonnegative(),
  })
  .strict();
export type User = z.infer<typeof userSchema>;
export const sessionSchema = z.object({ user: userSchema.nullable() }).strict();
export const authConfigSchema = z
  .object({
    provider: z.literal("authing"),
    configured: z.boolean(),
    gameUrl: z.string().url().nullable(),
  })
  .strict();
export const authStartSchema = z
  .object({ returnTo: z.string().max(2048).default("/") })
  .strict();
export const authStartResponseSchema = z
  .object({ url: z.string().url() })
  .strict();
export const logoutSchema = z
  .object({ ok: z.literal(true), redirectUrl: z.string().url().nullable() })
  .strict();
export const profileSchema = z
  .object({
    nickname: z.string().trim().min(1).max(24),
    chapterId: chapterSchema.shape.id.nullable(),
  })
  .strict();
export const channelSchema = z.enum(["chapter", "feedback", "story"]);
export const statusSchema = z.enum([
  "received",
  "discussion",
  "production",
  "playable",
  "published",
  "closed",
]);
export const consentVersion = "2026-10-24" as const;
export const safeLinkSchema = z
  .string()
  .url()
  .max(2000)
  .refine((value) => {
    const url = new URL(value);
    return url.protocol === "https:" && !url.username && !url.password;
  }, "请填写 HTTPS 链接。");
export const creditSchema = z
  .object({
    mode: z.enum(["anonymous", "nickname", "custom"]),
    name: z.string().trim().max(40).default(""),
  })
  .strict()
  .refine((value) => value.mode !== "custom" || value.name.length > 0);
export const ideaCategorySchema = z.enum(["story", "gameplay", "experience"]);
export const createIdeaSchema = z
  .object({
    title: z.string().trim().min(1).max(100),
    body: z.string().trim().min(1).max(10000),
    chapterId: chapterSchema.shape.id,
    category: ideaCategorySchema,
    spoiler: z.boolean(),
    channel: channelSchema,
    anonymous: z.boolean(),
    termsVersion: z.literal(consentVersion),
    adaptationConsent: z.boolean(),
    credit: creditSchema,
  })
  .strict();
export type CreateIdea = z.infer<typeof createIdeaSchema>;
export const ideaSchema = z
  .object({
    id: z.uuid(),
    title: z.string(),
    body: z.string(),
    chapterId: z.string(),
    category: ideaCategorySchema,
    spoiler: z.boolean(),
    author: z
      .object({ id: z.uuid().nullable(), nickname: z.string() })
      .strict(),
    isOwner: z.boolean(),
    anonymous: z.boolean(),
    moderated: z.boolean(),
    channel: channelSchema,
    status: statusSchema,
    revision: z.number().int().nonnegative(),
    contentHidden: z.boolean(),
    canWithdraw: z.boolean(),
    hasProductionStarted: z.boolean(),
    adaptationConsent: z.boolean().nullable(),
    credit: creditSchema.nullable(),
    createdAt: z.iso.datetime(),
    likeCount: z.number().int().nonnegative(),
    ratingAverage: z.number().min(1).max(5).nullable(),
    ratingCount: z.number().int().nonnegative(),
    myLiked: z.boolean(),
    myRating: z.number().int().min(1).max(5).nullable(),
  })
  .strict();
export type Idea = z.infer<typeof ideaSchema>;
export const ideaResponseSchema = z.object({ idea: ideaSchema }).strict();
export const updateSchema = z
  .object({
    id: z.uuid(),
    status: statusSchema,
    note: z.string(),
    playUrl: z.string().url().nullable(),
    version: z.string().nullable(),
    credit: z.string().nullable(),
    createdAt: z.iso.datetime(),
  })
  .strict();
export const updatesSchema = z
  .object({ items: z.array(updateSchema) })
  .strict();
export const operatorUpdateSchema = z
  .object({
    expectedRevision: z.number().int().nonnegative(),
    status: statusSchema,
    spoiler: z.boolean().default(false),
    note: z.string().trim().min(1).max(3000),
    playUrl: safeLinkSchema.nullable(),
    version: z.string().trim().min(1).max(80).nullable(),
  })
  .strict()
  .refine(
    (value) =>
      !["playable", "published"].includes(value.status) ||
      (value.playUrl !== null && value.version !== null),
    "试玩和发布需要链接与版本说明。",
  );
export const permissionSchema = z
  .object({ adaptationConsent: z.boolean(), credit: creditSchema })
  .strict();
export const ideaListSchema = z
  .object({
    items: z.array(ideaSchema),
    total: z.number().int().nonnegative(),
    page: z.number().int().positive(),
    pageSize: z.literal(12),
  })
  .strict();
export const ideaListQuerySchema = z
  .object({
    sort: z.enum(["likes", "rating", "new"]).default("likes"),
    chapterId: chapterSchema.shape.id.optional(),
    channel: channelSchema.optional(),
    status: statusSchema.optional(),
    q: z.string().trim().max(100).optional(),
    mine: z
      .enum(["true", "false"])
      .default("false")
      .transform((value) => value === "true"),
    page: z.coerce.number().int().min(1).max(10000).default(1),
  })
  .strict();
export type IdeaListQuery = z.infer<typeof ideaListQuerySchema>;
export const statsSchema = z
  .object({
    ideaCount: z.number().int().nonnegative(),
    memberCount: z.number().int().nonnegative(),
    likeCount: z.number().int().nonnegative(),
  })
  .strict();
export const okSchema = z.object({ ok: z.literal(true) }).strict();

export type OperatorUpdate = z.infer<typeof operatorUpdateSchema>;
export type Permission = z.infer<typeof permissionSchema>;
