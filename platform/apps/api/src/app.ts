import { randomUUID } from "node:crypto";
import { resolve } from "node:path";
import { access, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import Fastify from "fastify";
import fastifyStatic from "@fastify/static";
import { healthSchema, readinessSchema, type ApiError } from "@755/contracts";
import {
  registerCatalog,
  type CatalogReader,
} from "./modules/catalog/routes.js";

import { CommunityError, type CommunityStore, type GameSaveStore } from "@755/database";
import { registerCommunity } from "./modules/community/routes.js";
import type { AuthingProvider } from "./modules/auth/authing.js";

export class ServiceUnavailable extends Error {}
interface AppOptions {
  authing?: AuthingProvider;
  operators?: string[];
  gameUrl?: string;
  gameExportDir?: string;
  catalog: CatalogReader;
  checkReady: () => Promise<void>;
  close?: () => Promise<void>;
  logger?: boolean;
  serveWeb?: boolean;
  community?: CommunityStore;
  gameSaves?: GameSaveStore;
  publicOrigin?: string;
  secureCookies?: boolean;
  trustProxy?: false | 1;
}

export async function buildApp(options: AppOptions) {
  const app = Fastify({
    logger: options.logger
      ? {
          redact: ["req.headers.authorization", "req.headers.cookie"],
          serializers: {
            req: (request) => ({
              method: request.method,
              url: request.url?.split("?")[0],
              id: request.id,
            }),
          },
        }
      : false,
    requestIdHeader: false,
    genReqId: () => randomUUID(),
    bodyLimit: 64 * 1024,
    requestTimeout: 15_000,
    trustProxy: options.trustProxy === 1 ? (_address, hop) => hop < 1 : false,
  });
  app.addHook("onSend", async (request, reply) => {
    reply.header("X-Content-Type-Options", "nosniff");
    reply.header("X-Frame-Options", "DENY");
    if (options.serveWeb)
      reply.header(
        "Content-Security-Policy",
        options.gameExportDir && request.url.startsWith("/game/")
          // The native Godot bridge runs fixed engine JavaScript via eval.
          ? "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; worker-src 'self' blob:; media-src 'self' blob:; object-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"
          : "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'",
      );
    reply.header(
      "Referrer-Policy",
      request.url.startsWith("/api/v1/auth/callback")
        ? "no-referrer"
        : "strict-origin-when-cross-origin",
    );
    reply.header("X-Request-Id", request.id);
    if (request.url.startsWith("/api"))
      reply.header("Cache-Control", "no-store");
  });
  app.setErrorHandler((error, request, reply) => {
    const unavailable = error instanceof ServiceUnavailable;
    const statusCode =
      error instanceof Error &&
      "statusCode" in error &&
      typeof error.statusCode === "number"
        ? error.statusCode
        : 500;
    const invalid = statusCode >= 400 && statusCode < 500;
    const status = unavailable ? 503 : invalid ? statusCode : 500;
    if (status >= 500)
      request.log.error(
        { requestId: request.id, status },
        "Platform request failed",
      );
    if (error instanceof CommunityError) {
      return reply.code(error.statusCode).send({
        error: {
          code: error.code,
          message: error.message,
          requestId: request.id,
        },
      } satisfies ApiError);
    }
    const response: ApiError = {
      error: {
        code: unavailable
          ? "SERVICE_UNAVAILABLE"
          : invalid
            ? "INVALID_REQUEST"
            : "INTERNAL_ERROR",
        message: unavailable
          ? "内容暂时无法加载，请稍后重试。"
          : invalid
            ? "请求格式不正确。"
            : "服务暂时出现问题，请稍后重试。",
        requestId: request.id,
      },
    };
    return reply.code(status).send(response);
  });
  app.get("/api/health", async () =>
    healthSchema.parse({ status: "ok", service: "755-platform" }),
  );
  app.get("/api/ready", async () => {
    try {
      await options.checkReady();
    } catch {
      throw new ServiceUnavailable();
    }
    return readinessSchema.parse({ status: "ready" });
  });
  registerCatalog(app, options.catalog);
  app.get("/api/v1/auth/config", async () => ({
    provider: "authing",
    configured: Boolean(options.authing),
    gameUrl: options.gameUrl ?? null,
  }));
  if (options.community)
    registerCommunity(app, {
      store: options.community,
      publicOrigin: options.publicOrigin ?? "http://127.0.0.1:3001",
      secureCookies:
        options.secureCookies ??
        options.publicOrigin?.startsWith("https:") ??
        false,
      authing: options.authing,
      operators: options.operators,
      gameSaves: options.gameSaves,
    });

  if (options.serveWeb) {
    const root = fileURLToPath(new URL("../../web/dist/", import.meta.url));
    await access(new URL("../../web/dist/index.html", import.meta.url));
    await app.register(fastifyStatic, {
      root,
      index: ["index.html"],
      maxAge: 0,
    });
  }
  if (options.gameExportDir) {
    const root = resolve(options.gameExportDir);
    const manifest = JSON.parse(await readFile(resolve(root, "build-manifest.json"), "utf8"));
    if (!manifest.cloudSaves) throw new Error("A verified game export with cloud saves is required.");
    await access(resolve(root, "index.html"));
    await app.register(fastifyStatic, { root, prefix: "/game/", decorateReply: !options.serveWeb, maxAge: 0 });
    app.get("/game", (_request, reply) => reply.redirect("/game/"));
  }
  // Missing APIs and missing assets must never receive an HTML fallback.
  app.setNotFoundHandler((request, reply) =>
    reply.code(404).send({
      error: {
        code: "NOT_FOUND",
        message: "没有找到这个地址。",
        requestId: request.id,
      },
    } satisfies ApiError),
  );
  if (options.close) app.addHook("onClose", options.close);
  return app;
}
