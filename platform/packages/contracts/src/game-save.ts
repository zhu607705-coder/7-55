import { z } from "zod";

export const SAVE_LIMITS = { state: 8 * 1024 ** 2, document: 8 * 1024 ** 2,
  image: 12 * 1024 ** 2, images: 32 * 1024 ** 2, quota: 256 * 1024 ** 2 } as const;
export const saveShaSchema = z.string().regex(/^[a-f0-9]{64}$/);
export const gameSaveBundleSchema = z.object({
  bundleVersion: z.literal(1),
  // Exact native envelope bytes. The game, not the platform, validates story facts.
  stateText: z.string().min(2).max(SAVE_LIMITS.state),
  stores: z.object({ posts: z.string().max(SAVE_LIMITS.document),
    questPostOverrides: z.string().max(SAVE_LIMITS.document) }).strict(),
  assets: z.array(saveShaSchema).max(4),
  summary: z.object({ chapter: z.number().int().min(1).max(99), task: z.string().max(200) }).strict(),
}).strict();
export const gameSaveWriteSchema = z.object({
  expectedMemberId: z.uuid(), expectedRevision: z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER),
  operationId: z.uuid(), bundle: gameSaveBundleSchema,
}).strict();
export const gameSaveRestoreSchema = gameSaveWriteSchema.omit({bundle:true}).extend({ snapshotId: z.uuid() });
export type GameSaveBundle = z.infer<typeof gameSaveBundleSchema>;
export type GameSaveWrite = z.infer<typeof gameSaveWriteSchema>;
export type GameSaveRestore = z.infer<typeof gameSaveRestoreSchema>;
export const gameSaveSummarySchema = z.object({
  id: z.uuid(), digest: saveShaSchema, savedAt: z.string(), sourceVersion: z.number().int(),
  chapter: z.number().int(), task: z.string(),
}).strict();
export const gameSaveHeadSchema = z.object({
  revision: z.number().int().nonnegative(), memberId: z.uuid(),
  current: gameSaveSummarySchema.nullable(), previous: gameSaveSummarySchema.nullable(),
  beforeRestart: gameSaveSummarySchema.nullable(),
}).strict();
export type GameSaveHead = z.infer<typeof gameSaveHeadSchema>;
