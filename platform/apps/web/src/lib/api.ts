import {
  errorSchema,
  authConfigSchema,
  authStartResponseSchema,
  logoutSchema,
  updatesSchema,
  ideaListSchema,
  ideaResponseSchema,
  okSchema,
  sessionSchema,
  statsSchema,
} from "@755/contracts";
export type { User, Idea } from "@755/contracts";
export type IdeaList = ReturnType<typeof ideaListSchema.parse>;
export type Stats = ReturnType<typeof statsSchema.parse>;
export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}
export async function api<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const controller = new AbortController();
  const abort = () => controller.abort();
  if (options.signal?.aborted) controller.abort();
  options.signal?.addEventListener("abort", abort, { once: true });
  const timer = window.setTimeout(abort, 15_000);
  try {
    const response = await fetch(`/api/v1${path}`, {
      ...options,
      credentials: "same-origin",
      signal: controller.signal,
      headers: {
        Accept: "application/json",
        ...(options.method && options.method !== "GET"
          ? {
              "Content-Type": "application/json",
              "X-Requested-With": "755-platform",
            }
          : {}),
        ...options.headers,
      },
    });
    const data: unknown = await response.json().catch(() => null);
    if (!response.ok) {
      const parsed = errorSchema.safeParse(data);
      throw new ApiError(
        parsed.success
          ? parsed.data.error.message
          : "暂时无法完成操作，请稍后重试。",
        response.status,
      );
    }
    const route = path.split("?")[0];
    const schema =
      route === "/auth/config"
        ? authConfigSchema
        : route === "/auth/start"
          ? authStartResponseSchema
          : route === "/auth/logout"
            ? logoutSchema
            : route === "/session" || route === "/profile"
              ? sessionSchema
              : route === "/stats"
                ? statsSchema
                : (route === "/ideas" &&
                      (!options.method || options.method === "GET")) ||
                    route === "/operator/ideas"
                  ? ideaListSchema
                  : route?.endsWith("/updates") &&
                      (!options.method || options.method === "GET")
                    ? updatesSchema
                    : route?.includes("/ideas") &&
                        options.method !== "DELETE" &&
                        !route.endsWith("/moderation")
                      ? ideaResponseSchema
                      : okSchema;
    const parsed = schema.safeParse(data);
    if (!parsed.success)
      throw new Error("服务器返回的数据暂时无法读取，请重新加载。");
    return parsed.data as T;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (error instanceof Error && error.message.includes("服务器返回"))
      throw error;
    throw new Error("连接暂时中断了，请检查网络后重试。");
  } finally {
    window.clearTimeout(timer);
    options.signal?.removeEventListener("abort", abort);
  }
}
export const messageOf = (error: unknown) =>
  error instanceof Error ? error.message : "操作没有完成，请重试。";
