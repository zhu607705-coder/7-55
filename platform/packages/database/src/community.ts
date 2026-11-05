import { randomUUID } from "node:crypto";
import type pg from "pg";
import {
  ideaSchema,
  type User,
  type CreateIdea,
  type IdeaListQuery,
  type Idea,
  type OperatorUpdate,
  type Permission,
} from "@755/contracts";

export class CommunityError extends Error {
  constructor(
    public statusCode: number,
    public code:
      | "NOT_FOUND"
      | "CONFLICT"
      | "FORBIDDEN"
      | "UNAUTHENTICATED"
      | "INVALID_REQUEST"
      | "RATE_LIMITED",
    message: string,
  ) {
    super(message);
  }
}
export interface AuthTransaction {
  stateHash: string;
  browserHash: string;
  verifier: string;
  nonce: string;
  returnTo: string;
  issuer: string;
  clientId: string;
}
const selection = `SELECT i.id, i.title, i.body, i.chapter_id AS "chapterId", i.category, i.spoiler,
  (i.production_started_at IS NOT NULL) AS "hasProductionStarted",
  i.anonymous, i.channel, i.status, i.revision, i.adaptation_consent AS "adaptationConsent",
  json_build_object('mode',i.credit_mode,'name',i.credit_name) AS credit,
  json_build_object('id',m.id,'nickname',m.nickname) AS author,
  i.created_at AS "createdAt", COALESCE(l.n,0)::int AS "likeCount",
  r.average AS "ratingAverage", COALESCE(r.n,0)::int AS "ratingCount",
  (i.hidden_at IS NOT NULL) AS moderated,
  EXISTS (SELECT 1 FROM idea_likes mine WHERE mine.idea_id=i.id AND mine.member_id=$1::uuid) AS "myLiked",
  (SELECT score FROM idea_ratings mine WHERE mine.idea_id=i.id AND mine.member_id=$1::uuid) AS "myRating"
  FROM ideas i JOIN members m ON m.id=i.author_id JOIN chapters c ON c.id=i.chapter_id
  LEFT JOIN LATERAL (SELECT count(*) AS n FROM idea_likes x WHERE x.idea_id=i.id) l ON true
  LEFT JOIN LATERAL (SELECT count(*) AS n,avg(score)::float8 AS average FROM idea_ratings x WHERE x.idea_id=i.id) r ON true`;
const visible = `i.deleted_at IS NULL AND c.is_public=true AND (i.hidden_at IS NULL OR $2::boolean OR i.author_id=$1::uuid)
  AND (i.channel <> 'chapter' OR $2::boolean OR i.author_id=$1::uuid OR
    c.sort_order <= COALESCE((SELECT progress_order FROM members WHERE id=$1::uuid),0))`;
function asIdea(
  row: Record<string, unknown>,
  viewerId: string | null,
  operator = false,
  reveal = false,
): Idea {
  const author = row.author as { id: string; nickname: string };
  const isOwner = author.id === viewerId;
  const contentHidden =
    Boolean(row.spoiler) && !isOwner && !operator && !reveal;
  return ideaSchema.parse({
    ...row,
    title: contentHidden ? "包含剧情细节的投稿" : row.title,
    body: contentHidden ? "" : row.body,
    author: row.anonymous ? { id: null, nickname: "匿名同学" } : author,
    isOwner,
    contentHidden,
    canWithdraw: isOwner && !row.hasProductionStarted,
    adaptationConsent: isOwner || operator ? row.adaptationConsent : null,
    credit: isOwner || operator ? row.credit : null,
    createdAt: new Date(row.createdAt as string | Date).toISOString(),
  });
}

export function createCommunityStore(pool: pg.Pool) {
  let nextLimitCleanup = 0;
  return {
    async identity(
      issuer: string,
      subject: string,
    ): Promise<{ user: User; identityId: string }> {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        // Serializes first logins for this external identity without merging unrelated emails.
        await client.query(
          "SELECT pg_advisory_xact_lock(hashtextextended($1,0))",
          [JSON.stringify([issuer, subject])],
        );
        let result = await client.query(
          "SELECT m.id,m.username,m.nickname,m.progress_order, e.id AS identity_id FROM external_identities e JOIN members m ON m.id=e.member_id WHERE e.issuer=$1 AND e.subject=$2",
          [issuer, subject],
        );
        if (!result.rowCount) {
          const id = randomUUID();
          const username = "u_" + randomUUID().replaceAll("-", "").slice(0, 20);
          const identityId = randomUUID();
          await client.query(
            "INSERT INTO members(id,username,nickname) VALUES($1,$2,$3)",
            [id, username, "校园同学"],
          );
          await client.query(
            "INSERT INTO external_identities(id,member_id,issuer,subject) VALUES($1,$2,$3,$4)",
            [identityId, id, issuer, subject],
          );
          result = await client.query(
            "SELECT id,username,nickname,progress_order,$2::text AS identity_id FROM members WHERE id=$1",
            [id, identityId],
          );
        }
        await client.query("COMMIT");
        const row = result.rows[0];
        return {
          user: {
            id: row.id,
            username: row.username,
            nickname: row.nickname,
            progressOrder: row.progress_order,
            isOperator: false,
          },
          identityId: row.identity_id,
        };
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
    },
    async createSession(
      memberId: string,
      identityId: string,
      tokenHash: string,
      expiresAt: Date,
    ) {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        // Serialize logins for one member so concurrent callbacks keep the session cap.
        await client.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
          "session:" + memberId,
        ]);
        await client.query(
          "DELETE FROM sessions WHERE member_id=$1 AND (expires_at <= now() OR token_hash IN (SELECT token_hash FROM sessions WHERE member_id=$1 ORDER BY created_at DESC, token_hash DESC OFFSET 9))",
          [memberId],
        );
        const inserted = await client.query(
          "INSERT INTO sessions(token_hash,member_id,identity_id,expires_at) SELECT $1,$2,id,$4 FROM external_identities WHERE id=$3 AND member_id=$2",
          [tokenHash, memberId, identityId, expiresAt],
        );
        if (inserted.rowCount !== 1) throw new Error("Session identity mismatch");
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
    },
    async session(
      tokenHash: string,
      issuer = "",
      operators: string[] = [],
    ): Promise<User | null> {
      const result = await pool.query(
        `SELECT m.id,m.username,m.nickname,m.progress_order AS "progressOrder",
        (e.issuer=$2 AND e.subject=ANY($3::text[])) AS "isOperator"
        FROM sessions s JOIN members m ON m.id=s.member_id JOIN external_identities e ON e.id=s.identity_id
        WHERE s.token_hash=$1 AND s.expires_at > now()`,
        [tokenHash, issuer, operators],
      );
      return result.rows[0] ?? null;
    },
    async logout(tokenHash: string) {
      await pool.query("DELETE FROM sessions WHERE token_hash=$1", [tokenHash]);
    },
    async saveAuthTransaction(input: AuthTransaction, expiresAt: Date) {
      await pool.query(
        "DELETE FROM auth_transactions WHERE expires_at <= now() OR browser_hash=$1",
        [input.browserHash],
      );
      await pool.query(
        `INSERT INTO auth_transactions(state_hash,browser_hash,verifier,nonce,return_to,issuer,client_id,expires_at)
        VALUES($1,$2,$3,$4,$5,$6,$7,$8)`,
        [
          input.stateHash,
          input.browserHash,
          input.verifier,
          input.nonce,
          input.returnTo,
          input.issuer,
          input.clientId,
          expiresAt,
        ],
      );
    },
    async consumeAuthTransaction(
      stateHash: string,
      browserHash: string,
    ): Promise<AuthTransaction | null> {
      const result = await pool.query(
        `DELETE FROM auth_transactions WHERE state_hash=$1 AND browser_hash=$2 AND expires_at>now()
        RETURNING state_hash AS "stateHash",browser_hash AS "browserHash",verifier,nonce,return_to AS "returnTo",issuer,client_id AS "clientId"`,
        [stateHash, browserHash],
      );
      return result.rows[0] ?? null;
    },
    async profile(
      memberId: string,
      nickname: string,
      chapterId: string | null,
    ) {
      if (chapterId === null)
        await pool.query(
          "UPDATE members SET nickname=$2,progress_order=0 WHERE id=$1",
          [memberId, nickname],
        );
      else {
        const result = await pool.query(
          `UPDATE members SET nickname=$2,progress_order=c.sort_order FROM chapters c WHERE members.id=$1 AND c.id=$3 AND c.kind='chapter' AND c.is_public RETURNING members.id`,
          [memberId, nickname, chapterId],
        );
        if (!result.rowCount)
          throw new CommunityError(
            400,
            "INVALID_REQUEST",
            "请选择已公开的游戏章节。",
          );
      }
    },
    async rateLimit(
      key: string,
      max: number,
      seconds: number,
    ): Promise<boolean> {
      // Avoid a global expiry DELETE for every write in a traffic burst.
      if (Date.now() >= nextLimitCleanup) {
        nextLimitCleanup = Date.now() + 60_000;
        await pool.query("DELETE FROM request_limits WHERE key IN (SELECT key FROM request_limits WHERE expires_at <= now() LIMIT 1000)");
      }
      const result = await pool.query(
        `INSERT INTO request_limits (key, hits, expires_at) VALUES ($1,1,now() + $3 * interval '1 second')
        ON CONFLICT (key) DO UPDATE SET hits = CASE WHEN request_limits.expires_at <= now() THEN 1 ELSE LEAST(request_limits.hits + 1, $2 + 1) END,
        expires_at = CASE WHEN request_limits.expires_at <= now() THEN now() + $3 * interval '1 second' ELSE request_limits.expires_at END RETURNING hits`,
        [key, max, seconds],
      );
      return result.rows[0].hits <= max;
    },
    async list(
      query: IdeaListQuery,
      viewerId: string | null,
      operator = false,
    ) {
      const values: unknown[] = [viewerId, operator];
      const filters = [visible];
      for (const field of ["channel", "status"] as const) {
        if (query[field]) {
          values.push(query[field]);
          filters.push(`i.${field}=$${values.length}`);
        }
      }
      if (query.chapterId) {
        values.push(query.chapterId);
        filters.push(`i.chapter_id = $${values.length}`);
      }
      if (query.q) {
        values.push(query.q);
        filters.push(
          `((NOT i.spoiler OR i.author_id=$1 OR $2::boolean) AND (strpos(lower(i.title), lower($${values.length})) > 0 OR strpos(lower(i.body), lower($${values.length})) > 0))`,
        );
      }
      if (query.mine) {
        filters.push("i.author_id = $1::uuid");
      }
      const where = filters.join(" AND ");
      // Count and rows use one statement snapshot so pagination metadata cannot race new posts.
      const order =
        query.sort === "likes"
          ? '"likeCount" DESC, "ratingCount" DESC, "createdAt" DESC, id DESC'
          : query.sort === "rating"
            ? '"ratingAverage" DESC NULLS LAST, "ratingCount" DESC, "likeCount" DESC, "createdAt" DESC, id DESC'
            : '"createdAt" DESC, id DESC';
      values.push((query.page - 1) * 12);
      const result = await pool.query(
        `WITH matching AS (${selection} WHERE ${where}), paged AS (SELECT * FROM matching ORDER BY ${order} LIMIT 12 OFFSET $${values.length})
        SELECT (SELECT count(*)::int FROM matching) AS total, COALESCE((SELECT json_agg(paged) FROM paged), '[]'::json) AS items`,
        values,
      );
      const row = result.rows[0];
      return {
        items: (row.items as Record<string, unknown>[]).map((item) =>
          asIdea(item, viewerId, operator),
        ),
        total: row.total as number,
        page: query.page,
        pageSize: 12 as const,
      };
    },
    async get(
      id: string,
      viewerId: string | null,
      operator = false,
      reveal = false,
    ): Promise<Idea> {
      const result = await pool.query(
        `${selection} WHERE ${visible} AND i.id = $3`,
        [viewerId, operator, id],
      );
      if (!result.rows[0])
        throw new CommunityError(
          404,
          "NOT_FOUND",
          "这个想法不存在或已被删除。",
        );
      return asIdea(result.rows[0], viewerId, operator, reveal);
    },
    async create(authorId: string, input: CreateIdea): Promise<string> {
      const id = randomUUID();
      const result = await pool.query(
        `WITH created AS (INSERT INTO ideas (id, author_id, chapter_id, title, body, category, spoiler, channel, anonymous, terms_version, adaptation_consent, credit_mode, credit_name)
        SELECT $1,$2,c.id,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13 FROM chapters c WHERE c.id = $3 AND c.is_public = true
        AND ($8 <> 'chapter' OR (c.kind='chapter' AND c.sort_order <= (SELECT progress_order FROM members WHERE id=$2))) RETURNING id), logged AS (
          INSERT INTO permission_events(id,idea_id,author_id,adaptation_consent,credit_mode,credit_name,terms_version)
          SELECT $14,created.id,$2,$11,$12,$13,$10 FROM created RETURNING idea_id
        ) SELECT id FROM created`,
        [
          id,
          authorId,
          input.chapterId,
          input.title,
          input.body,
          input.category,
          input.spoiler,
          input.channel,
          input.anonymous,
          input.termsVersion,
          input.adaptationConsent,
          input.credit.mode,
          input.credit.name,
          randomUUID(),
        ],
      );
      if (!result.rowCount)
        throw new CommunityError(
          400,
          "INVALID_REQUEST",
          "本章说需要先设置已玩到的章节；卡点反馈和故事分享不要求通关。",
        );
      return id;
    },
    async react(
      id: string,
      memberId: string,
      change: { liked: boolean } | { score: number | null },
    ) {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        // Row locking serializes moderation/deletion with reactions, while unique keys prevent duplicates.
        const result = await client.query(
          `SELECT i.id FROM ideas i JOIN chapters c ON c.id = i.chapter_id WHERE ${visible} AND i.hidden_at IS NULL AND i.id = $3 FOR UPDATE OF i`,
          [memberId, false, id],
        );
        if (!result.rowCount)
          throw new CommunityError(
            404,
            "NOT_FOUND",
            "这个想法不存在或已被删除。",
          );
        if ("liked" in change) {
          if (change.liked)
            await client.query(
              "INSERT INTO idea_likes (idea_id, member_id) VALUES ($1,$2) ON CONFLICT DO NOTHING",
              [id, memberId],
            );
          else
            await client.query(
              "DELETE FROM idea_likes WHERE idea_id=$1 AND member_id=$2",
              [id, memberId],
            );
        } else if (change.score === null) {
          await client.query(
            "DELETE FROM idea_ratings WHERE idea_id=$1 AND member_id=$2",
            [id, memberId],
          );
        } else {
          await client.query(
            "INSERT INTO idea_ratings (idea_id,member_id,score) VALUES ($1,$2,$3) ON CONFLICT (idea_id,member_id) DO UPDATE SET score=EXCLUDED.score, updated_at=now()",
            [id, memberId, change.score],
          );
        }
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
    },
    async remove(id: string, authorId: string) {
      const result = await pool.query(
        "UPDATE ideas SET deleted_at=now() WHERE id=$1 AND author_id=$2 AND deleted_at IS NULL AND production_started_at IS NULL RETURNING id",
        [id, authorId],
      );
      if (!result.rowCount)
        throw new CommunityError(
          409,
          "CONFLICT",
          "无法撤稿；请确认它属于你。已经进入制作的投稿需要与团队协商处理。",
        );
    },
    async updates(
      id: string,
      viewerId: string | null,
      operator = false,
      reveal = false,
    ) {
      const idea = await this.get(id, viewerId, operator, reveal);
      if (idea.contentHidden) return { items: [] };
      const result = await pool.query(
        `SELECT u.id,u.status,u.note,u.play_url AS "playUrl",u.version,u.credit,u.created_at AS "createdAt"
        FROM idea_updates u JOIN ideas i ON i.id=u.idea_id JOIN chapters c ON c.id=i.chapter_id
        WHERE ${visible} AND i.id=$3 AND (NOT i.spoiler OR i.author_id=$1 OR $2::boolean OR $4::boolean)
        ORDER BY u.created_at,u.id`,
        [viewerId, operator, id, reveal],
      );
      return {
        items: result.rows.map((row) => ({
          ...row,
          createdAt: row.createdAt.toISOString(),
        })),
      };
    },
    async permissions(id: string, authorId: string, input: Permission) {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        const result = await client.query(
          `UPDATE ideas SET adaptation_consent=$3,credit_mode=$4,credit_name=$5,revision=revision+1
          WHERE id=$1 AND author_id=$2 AND deleted_at IS NULL AND
          (production_started_at IS NULL OR adaptation_consent=$3) RETURNING id`,
          [
            id,
            authorId,
            input.adaptationConsent,
            input.credit.mode,
            input.credit.name,
          ],
        );
        if (!result.rowCount)
          throw new CommunityError(
            409,
            "CONFLICT",
            "进入制作后，改编授权的变更需要与团队协商。",
          );
        await client.query(
          `INSERT INTO permission_events(id,idea_id,author_id,adaptation_consent,credit_mode,credit_name,terms_version)
          VALUES($1,$2,$3,$4,$5,$6,'2026-10-24')`,
          [
            randomUUID(),
            id,
            authorId,
            input.adaptationConsent,
            input.credit.mode,
            input.credit.name,
          ],
        );
        const member = await client.query(
          "SELECT nickname FROM members WHERE id=$1",
          [authorId],
        );
        const credit =
          input.credit.mode === "anonymous"
            ? null
            : input.credit.mode === "custom"
              ? input.credit.name
              : member.rows[0].nickname;
        await client.query(
          `UPDATE idea_updates SET credit=$2 WHERE idea_id=$1 AND status IN ('playable','published')`,
          [id, credit],
        );
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
    },
    async operatorUpdate(
      id: string,
      operatorId: string,
      input: OperatorUpdate,
    ) {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        const result = await client.query(
          `SELECT i.*,m.nickname FROM ideas i JOIN members m ON m.id=i.author_id JOIN chapters c ON c.id=i.chapter_id WHERE i.id=$1 AND i.deleted_at IS NULL AND c.is_public FOR UPDATE OF i`,
          [id],
        );
        const row = result.rows[0];
        if (!row) throw new CommunityError(404, "NOT_FOUND", "投稿不存在。");
        if (row.revision !== input.expectedRevision)
          throw new CommunityError(
            409,
            "CONFLICT",
            "投稿已被更新，请刷新后再处理。",
          );
        const paths: Record<string, string[]> = {
          received: ["received", "discussion", "closed"],
          discussion: ["discussion", "received", "production", "closed"],
          production: ["production", "discussion", "playable", "closed"],
          playable: ["playable", "production", "published", "closed"],
          published: ["published", "playable"],
          closed: ["closed", "discussion"],
        };
        if (!paths[row.status]?.includes(input.status))
          throw new CommunityError(
            409,
            "CONFLICT",
            "请按讨论、制作、试玩、发布的顺序推进。",
          );
        if (
          ["production", "playable", "published"].includes(input.status) &&
          !row.adaptation_consent &&
          row.channel === "story"
        )
          throw new CommunityError(
            409,
            "CONFLICT",
            "作者尚未确认游戏改编授权，请先联系作者确认。",
          );
        if (row.hidden_at)
          throw new CommunityError(
            409,
            "CONFLICT",
            "请先恢复这份被隐藏的投稿，再发布进展。",
          );
        const credit =
          row.credit_mode === "anonymous"
            ? null
            : row.credit_mode === "custom"
              ? row.credit_name
              : row.nickname;
        await client.query(
          `UPDATE ideas SET status=$2,spoiler=spoiler OR $3,revision=revision+1,production_started_at=CASE WHEN $2 IN ('production','playable','published') THEN COALESCE(production_started_at,now()) ELSE production_started_at END WHERE id=$1`,
          [id, input.status, input.spoiler],
        );
        await client.query(
          `INSERT INTO idea_updates(id,idea_id,operator_id,status,note,play_url,version,credit) VALUES($1,$2,$3,$4,$5,$6,$7,$8)`,
          [
            randomUUID(),
            id,
            operatorId,
            input.status,
            input.note,
            input.playUrl,
            input.version,
            ["playable", "published"].includes(input.status) ? credit : null,
          ],
        );
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
    },
    async moderate(
      id: string,
      operatorId: string,
      hidden: boolean,
      reason: string,
    ) {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        const result = await client.query(
          "UPDATE ideas SET hidden_at=CASE WHEN $2 THEN now() ELSE NULL END,revision=revision+1 WHERE id=$1 AND deleted_at IS NULL RETURNING id",
          [id, hidden],
        );
        if (!result.rowCount)
          throw new CommunityError(404, "NOT_FOUND", "投稿不存在。");
        await client.query(
          "INSERT INTO operator_audit(id,idea_id,operator_id,action,reason) VALUES($1,$2,$3,$4,$5)",
          [randomUUID(), id, operatorId, hidden ? "hide" : "restore", reason],
        );
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
    },
    async stats(viewerId: string | null = null) {
      const result = await pool.query(
        `SELECT (SELECT count(*)::int FROM ideas i JOIN chapters c ON c.id=i.chapter_id WHERE ${visible}) AS "ideaCount",
        (SELECT count(*)::int FROM members) AS "memberCount",
        (SELECT count(*)::int FROM idea_likes l JOIN ideas i ON i.id=l.idea_id JOIN chapters c ON c.id=i.chapter_id WHERE ${visible}) AS "likeCount"`,
        [viewerId, false],
      );
      return result.rows[0] as {
        ideaCount: number;
        memberCount: number;
        likeCount: number;
      };
    },
  };
}
export type CommunityStore = ReturnType<typeof createCommunityStore>;
