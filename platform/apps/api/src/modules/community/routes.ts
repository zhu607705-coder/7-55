import type { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import {
  authStartSchema,
  profileSchema,
  operatorUpdateSchema,
  permissionSchema,
  updatesSchema,
  createIdeaSchema,
  ideaListQuerySchema,
  sessionSchema,
  ideaListSchema,
  ideaResponseSchema,
  statsSchema,
  type User,
} from "@755/contracts";
import { CommunityError, type CommunityStore } from "@755/database";
import { digest, newSessionToken } from "./tokens.js";

import type { AuthingProvider } from "../auth/authing.js";
import type { GameSaveStore } from "@755/database";
import { registerGameSaves } from "../game-saves/routes.js";
interface CommunityOptions {
  authing?: AuthingProvider;
  operators?: string[];
  store: CommunityStore;
  publicOrigin: string;
  secureCookies: boolean;
  gameSaves?: GameSaveStore;
}
function parse<T>(schema: z.ZodType<T>, value: unknown): T {
  const result = schema.safeParse(value);
  if (!result.success)
    throw new CommunityError(
      400,
      "INVALID_REQUEST",
      "填写内容不符合要求，请检查长度和格式。",
    );
  return result.data;
}
const idSchema = z.object({ id: z.uuid() }).strict();
const likeSchema = z.object({ liked: z.boolean() }).strict();
const ratingSchema = z
  .object({ score: z.number().int().min(1).max(5).nullable() })
  .strict();
const lifetimeSeconds = 8 * 60 * 60;
const authLifetimeSeconds = 10 * 60;

export function registerCommunity(
  app: FastifyInstance,
  options: CommunityOptions,
) {
  const { store, publicOrigin, secureCookies } = options;
  const cookieName = secureCookies ? "__Host-755_session" : "755_session";
  function token(request: FastifyRequest) {
    const cookies = (request.headers.cookie ?? "")
      .split(";")
      .map((part) => part.trim())
      .filter((part) => part.startsWith(`${cookieName}=`));
    if (cookies.length !== 1) return null;
    const value = cookies[0]!.slice(cookieName.length + 1);
    return /^[a-f0-9]{64}$/.test(value) ? value : null;
  }
  function setCookie(reply: FastifyReply, value: string, maxAge: number) {
    reply.header(
      "Set-Cookie",
      `${cookieName}=${value}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secureCookies ? "; Secure" : ""}`,
    );
  }
  const viewers = new WeakMap<FastifyRequest, Promise<User | null>>();
  async function viewer(request: FastifyRequest): Promise<User | null> {
    if (!options.authing) return null;
    const existing = viewers.get(request);
    if (existing) return existing;
    const raw = token(request);
    const result = raw
      ? store.session(digest(raw), options.authing?.issuer, options.operators)
      : Promise.resolve(null);
    viewers.set(request, result);
    return result;
  }
  async function member(request: FastifyRequest): Promise<User> {
    const user = await viewer(request);
    if (!user)
      throw new CommunityError(
        401,
        "UNAUTHENTICATED",
        "登录后就可以参与共创。",
      );
    return user;
  }
  async function limit(
    key: string,
    max: number,
    seconds: number,
    reply: FastifyReply,
  ) {
    if (!(await store.rateLimit(digest(key), max, seconds))) {
      reply.header("Retry-After", String(seconds));
      throw new CommunityError(
        429,
        "RATE_LIMITED",
        "操作有点频繁，请稍后再试。",
      );
    }
  }
  async function protect(request: FastifyRequest, reply: FastifyReply) {
    if (
      request.headers.origin !== publicOrigin ||
      request.headers["x-requested-with"] !== "755-platform"
    ) {
      throw new CommunityError(
        403,
        "FORBIDDEN",
        "请求来源不正确，请从平台页面重新操作。",
      );
    }
    await limit(`write-ip:${request.ip}`, 1200, 60, reply);
  }
  async function writeMember(request: FastifyRequest, reply: FastifyReply) {
    const user = await member(request);
    await limit(`write-user:${user.id}`, 60, 60, reply);
    return user;
  }
  if (options.gameSaves) registerGameSaves(app,options.gameSaves,{member,protect,writeMember});
  const authCookieName = secureCookies ? "__Host-755_auth" : "755_auth";
  function cookie(
    reply: FastifyReply,
    name: string,
    value: string,
    maxAge: number,
  ) {
    const next = `${name}=${value}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${maxAge}${secureCookies ? "; Secure" : ""}`;
    const old = reply.getHeader("Set-Cookie");
    reply.header("Set-Cookie", [
      ...(Array.isArray(old) ? old : old ? [String(old)] : []),
      next,
    ]);
  }
  function browserToken(request: FastifyRequest) {
    const values = (request.headers.cookie ?? "")
      .split(";")
      .map((v) => v.trim())
      .filter((v) => v.startsWith(`${authCookieName}=`));
    const value =
      values.length === 1 ? values[0]!.slice(authCookieName.length + 1) : "";
    return /^[a-f0-9]{64}$/.test(value) ? value : null;
  }
  function returnPath(value: string) {
    const url = new URL(value, publicOrigin);
    // Only the community home and the independently served game entry may receive
    // a login result. Never accept an arbitrary path, external URL or API endpoint.
    if (
      /[\u0000-\u001f\u007f]/.test(value) ||
      !value.startsWith("/") ||
      value.startsWith("//") ||
      value.includes("\\") ||
      url.origin !== publicOrigin ||
      (url.pathname !== "/" && url.pathname !== "/game/")
    )
      throw new CommunityError(
        400,
        "INVALID_REQUEST",
        "登录后返回地址不正确。",
      );
    url.searchParams.delete("authError");
    return url.pathname + url.search + url.hash;
  }
  app.get("/api/v1/session", async (request) =>
    sessionSchema.parse({ user: await viewer(request) }),
  );
  app.post(
    "/api/v1/auth/start",
    { preHandler: protect },
    async (request, reply) => {
      if (!options.authing) {
        reply.code(503);
        return {
          error: {
            code: "SERVICE_UNAVAILABLE",
            message: "登录服务尚未配置，请稍后再来。",
            requestId: request.id,
          },
        };
      }
      await limit(`auth-ip:${request.ip}`, 300, 900, reply);
      const { returnTo } = parse(authStartSchema, request.body);
      const path = returnPath(returnTo);
      const state = newSessionToken(),
        browser = newSessionToken(),
        verifier = newSessionToken(),
        nonce = newSessionToken();
      let url: string;
      try {
        url = await options.authing.start(
          `${publicOrigin}/api/v1/auth/callback`,
          { state, verifier, nonce },
        );
      } catch {
        reply.code(503);
        return {
          error: {
            code: "SERVICE_UNAVAILABLE",
            message: "登录服务暂时没有连上，请稍后重试。",
            requestId: request.id,
          },
        };
      }
      await store.saveAuthTransaction(
        {
          stateHash: digest(state),
          browserHash: digest(browser),
          verifier,
          nonce,
          returnTo: path,
          issuer: options.authing.issuer,
          clientId: options.authing.clientId,
        },
        new Date(Date.now() + authLifetimeSeconds * 1000),
      );
      cookie(reply, authCookieName, browser, authLifetimeSeconds);
      return { url };
    },
  );
  app.get("/api/v1/auth/callback", async (request, reply) => {
    reply.header("Referrer-Policy", "no-referrer");
    const browser = browserToken(request);
    cookie(reply, authCookieName, "", 0);
    let path = "/";
    try {
      if (!options.authing || !browser) throw new Error("Invalid transaction.");
      const url = new URL(request.url, publicOrigin);
      const states = url.searchParams.getAll("state");
      if (states.length !== 1 || !/^[a-f0-9]{64}$/.test(states[0]!))
        throw new Error("Invalid state.");
      const transaction = await store.consumeAuthTransaction(
        digest(states[0]!),
        digest(browser),
      );
      if (
        !transaction ||
        transaction.issuer !== options.authing.issuer ||
        transaction.clientId !== options.authing.clientId
      )
        throw new Error("Expired transaction.");
      path = returnPath(transaction.returnTo);
      if (url.searchParams.has("error")) {
        const back = new URL(path, publicOrigin);
        back.searchParams.set("authError", "cancelled");
        return reply.redirect(back.href);
      }
      const { subject } = await options.authing.complete(url, {
        state: states[0]!,
        verifier: transaction.verifier,
        nonce: transaction.nonce,
      });
      const { user, identityId } = await store.identity(
        options.authing.issuer,
        subject,
      );
      const old = token(request);
      if (old) await store.logout(digest(old));
      const raw = newSessionToken();
      await store.createSession(
        user.id,
        identityId,
        digest(raw),
        new Date(Date.now() + lifetimeSeconds * 1000),
      );
      cookie(reply, cookieName, raw, lifetimeSeconds);
      return reply.redirect(new URL(path, publicOrigin).href);
    } catch {
      const back = new URL(path, publicOrigin);
      back.searchParams.set("authError", "failed");
      return reply.redirect(back.href);
    }
  });
  app.post(
    "/api/v1/auth/logout",
    { preHandler: protect },
    async (request, reply) => {
      const raw = token(request);
      if (raw) await store.logout(digest(raw));
      setCookie(reply, "", 0);
      cookie(reply, authCookieName, "", 0);
      return {
        ok: true,
        redirectUrl: options.authing?.logout(publicOrigin + "/") ?? null,
      };
    },
  );
  app.put(
    "/api/v1/profile",
    { preHandler: protect },
    async (request, reply) => {
      const user = await writeMember(request, reply);
      const input = parse(profileSchema, request.body);
      await store.profile(user.id, input.nickname, input.chapterId);
      return sessionSchema.parse({ user: await viewer(request) });
    },
  );
  async function operator(request: FastifyRequest, reply: FastifyReply) {
    const user = await writeMember(request, reply);
    if (!user.isOperator)
      throw new CommunityError(
        403,
        "FORBIDDEN",
        "只有项目运营账号可以处理投稿。",
      );
    return user;
  }
  app.get("/api/v1/operator/ideas", async (request, reply) => {
    const user = await operator(request, reply);
    return ideaListSchema.parse(
      await store.list(
        parse(ideaListQuerySchema, request.query),
        user.id,
        true,
      ),
    );
  });
  app.post(
    "/api/v1/operator/ideas/:id/updates",
    { preHandler: protect },
    async (request, reply) => {
      const user = await operator(request, reply),
        { id } = parse(idSchema, request.params);
      await store.operatorUpdate(
        id,
        user.id,
        parse(operatorUpdateSchema, request.body),
      );
      return ideaResponseSchema.parse({
        idea: await store.get(id, user.id, true, true),
      });
    },
  );
  app.put(
    "/api/v1/operator/ideas/:id/moderation",
    { preHandler: protect },
    async (request, reply) => {
      const user = await operator(request, reply),
        { id } = parse(idSchema, request.params);
      const input = parse(
        z
          .object({
            hidden: z.boolean(),
            reason: z.string().trim().min(1).max(1000),
          })
          .strict(),
        request.body,
      );
      await store.moderate(id, user.id, input.hidden, input.reason);
      return { ok: true };
    },
  );
  app.put(
    "/api/v1/ideas/:id/permissions",
    { preHandler: protect },
    async (request, reply) => {
      const user = await writeMember(request, reply),
        { id } = parse(idSchema, request.params);
      await store.permissions(
        id,
        user.id,
        parse(permissionSchema, request.body),
      );
      return ideaResponseSchema.parse({ idea: await store.get(id, user.id) });
    },
  );
  app.get("/api/v1/ideas/:id/updates", async (request) => {
    const { id } = parse(idSchema, request.params),
      user = await viewer(request);
    const { reveal } = parse(
      z.object({ reveal: z.enum(["true", "false"]).default("false") }).strict(),
      request.query,
    );
    return updatesSchema.parse(
      await store.updates(
        id,
        user?.id ?? null,
        user?.isOperator,
        reveal === "true",
      ),
    );
  });
  app.get("/api/v1/stats", async (request) =>
    statsSchema.parse(await store.stats((await viewer(request))?.id)),
  );
  app.get("/api/v1/ideas", async (request) => {
    const query = parse(ideaListQuerySchema, request.query);
    const user = query.mine ? await member(request) : await viewer(request);
    return ideaListSchema.parse(await store.list(query, user?.id ?? null));
  });
  app.get("/api/v1/ideas/:id", async (request) => {
    const { id } = parse(idSchema, request.params);
    const user = await viewer(request);
    const { reveal } = parse(
      z.object({ reveal: z.enum(["true", "false"]).default("false") }).strict(),
      request.query,
    );
    return ideaResponseSchema.parse({
      idea: await store.get(
        id,
        user?.id ?? null,
        user?.isOperator,
        reveal === "true",
      ),
    });
  });
  app.post("/api/v1/ideas", { preHandler: protect }, async (request, reply) => {
    const user = await writeMember(request, reply);
    await limit(`publish-user:${user.id}`, 10, 3600, reply);
    const input = parse(createIdeaSchema, request.body);
    const id = await store.create(user.id, input);
    reply.code(201);
    return ideaResponseSchema.parse({ idea: await store.get(id, user.id) });
  });
  app.put(
    "/api/v1/ideas/:id/like",
    { preHandler: protect },
    async (request, reply) => {
      const user = await writeMember(request, reply);
      const { id } = parse(idSchema, request.params);
      const input = parse(likeSchema, request.body);
      await store.react(id, user.id, input);
      return ideaResponseSchema.parse({ idea: await store.get(id, user.id) });
    },
  );
  app.put(
    "/api/v1/ideas/:id/rating",
    { preHandler: protect },
    async (request, reply) => {
      const user = await writeMember(request, reply);
      const { id } = parse(idSchema, request.params);
      const input = parse(ratingSchema, request.body);
      await store.react(id, user.id, input);
      return ideaResponseSchema.parse({ idea: await store.get(id, user.id) });
    },
  );
  app.delete(
    "/api/v1/ideas/:id",
    { preHandler: protect },
    async (request, reply) => {
      const user = await writeMember(request, reply);
      const { id } = parse(idSchema, request.params);
      await store.remove(id, user.id);
      return { ok: true };
    },
  );
}
