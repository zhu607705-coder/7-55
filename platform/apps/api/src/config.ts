import { z } from "zod";

const environmentSchema = z.object({
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  HOST: z.string().min(1).default("127.0.0.1"),
  PORT: z.coerce.number().int().min(1).max(65535).default(3001),
  DATABASE_URL: z
    .string()
    .url()
    .refine((url) => /^postgres(ql)?:\/\//.test(url))
    .optional(),
  LOCAL_GAME_EXPORT_DIR: z.string().min(1).optional(),
  SERVE_WEB: z.enum(["true", "false"]).optional(),
  PUBLIC_ORIGIN: z.string().url().optional(),
  TRUST_PROXY: z.enum(["false", "1"]).default("false"),
  AUTHING_ISSUER: z.preprocess(
    (value) => (value === "" ? undefined : value),
    z.string().url().optional(),
  ),
  AUTHING_CLIENT_ID: z.preprocess(
    (value) => (value === "" ? undefined : value),
    z.string().min(1).max(200).optional(),
  ),
  AUTHING_CLIENT_SECRET: z.preprocess(
    (value) => (value === "" ? undefined : value),
    z.string().min(1).optional(),
  ),
  OPERATOR_SUBJECTS: z.string().default(""),
  GAME_URL: z.preprocess(
    (value) => (value === "" ? undefined : value),
    z.string().url().optional(),
  ),
});

export function readConfig(env: NodeJS.ProcessEnv = process.env) {
  const parsed = environmentSchema.safeParse(env);
  if (!parsed.success) {
    throw new Error(
      `Invalid configuration: ${parsed.error.issues.map((issue) => issue.path.join(".")).join(", ")}`,
    );
  }
  const value = parsed.data;
  const authValues = [
    value.AUTHING_ISSUER,
    value.AUTHING_CLIENT_ID,
    value.AUTHING_CLIENT_SECRET,
  ];
  if (authValues.some(Boolean) && !authValues.every(Boolean))
    throw new Error(
      "Set all three AUTHING variables together, or leave all unset.",
    );
  if (value.AUTHING_ISSUER) {
    const issuer = new URL(value.AUTHING_ISSUER);
    if (
      issuer.protocol !== "https:" ||
      issuer.username ||
      issuer.password ||
      issuer.search ||
      issuer.hash ||
      issuer.pathname.endsWith("/")
    )
      throw new Error(
        "AUTHING_ISSUER must be the exact HTTPS issuer, without a trailing slash.",
      );
  }
  if (value.LOCAL_GAME_EXPORT_DIR && value.NODE_ENV === "production")
    throw new Error("LOCAL_GAME_EXPORT_DIR is development-only; use the game deployment proxy in production.");
  if (value.GAME_URL) {
    const game = new URL(value.GAME_URL);
    if (game.protocol !== "https:" || game.username || game.password)
      throw new Error("GAME_URL must be a public HTTPS URL.");
  }
  if (value.NODE_ENV === "production" && !value.DATABASE_URL) {
    throw new Error("DATABASE_URL is required in production.");
  }
  if (value.NODE_ENV === "production" && !value.PUBLIC_ORIGIN)
    throw new Error("PUBLIC_ORIGIN is required in production.");
  const publicOrigin =
    value.PUBLIC_ORIGIN ??
    (value.NODE_ENV === "development"
      ? "http://127.0.0.1:5174"
      : `http://127.0.0.1:${value.PORT}`);
  const origin = new URL(publicOrigin);
  if (
    origin.origin !== publicOrigin ||
    origin.username ||
    origin.password ||
    !["http:", "https:"].includes(origin.protocol)
  )
    throw new Error(
      "PUBLIC_ORIGIN must be an exact HTTP(S) origin without a path.",
    );
  if (
    value.NODE_ENV === "production" &&
    origin.protocol !== "https:" &&
    !["localhost", "127.0.0.1", "[::1]"].includes(origin.hostname)
  )
    throw new Error("PUBLIC_ORIGIN requires HTTPS in production.");
  return {
    authing: value.AUTHING_ISSUER
      ? {
          issuer: value.AUTHING_ISSUER,
          clientId: value.AUTHING_CLIENT_ID!,
          clientSecret: value.AUTHING_CLIENT_SECRET!,
        }
      : undefined,
    operators: value.OPERATOR_SUBJECTS.split(",")
      .map((value) => value.trim())
      .filter(Boolean),
    gameUrl: value.LOCAL_GAME_EXPORT_DIR ? publicOrigin + "/game/" : value.GAME_URL,
    gameExportDir: value.LOCAL_GAME_EXPORT_DIR,
    publicOrigin,
    secureCookies: origin.protocol === "https:",
    trustProxy: value.TRUST_PROXY === "1" ? (1 as const) : (false as const),
    host: value.HOST,
    port: value.PORT,
    databaseUrl: value.DATABASE_URL,
    serveWeb: value.SERVE_WEB
      ? value.SERVE_WEB === "true"
      : value.NODE_ENV === "production",
  };
}
