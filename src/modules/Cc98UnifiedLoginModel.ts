import type { Cc98UnifiedLoginState } from "../core/types";

export const CC98_LOGIN_STUDENT_ID = "3250100755";
export const CC98_LOGIN_PASSWORD = "ZJU1897!";
export const CC98_LOGIN_FREE_ATTEMPTS = 3;
export const CC98_LOGIN_LOCK_STEP_MS = 30_000;

export const CC98_LOGIN_HINTS = [
  {
    id: "school_abbreviation",
    label: "校名缩写",
    clue: "取浙江大学英文名的三个大写字母。",
    fragment: "ZJU"
  },
  {
    id: "founding_year",
    label: "校史年份",
    clue: "接上求是书院创办的四位年份。",
    fragment: "1897"
  },
  {
    id: "final_mark",
    label: "结尾标点",
    clue: "保留认证公告最后的感叹号。",
    fragment: "!"
  }
] as const;

export type Cc98LoginAttemptResult =
  | { status: "authenticated" }
  | { status: "already_authenticated" }
  | { status: "identity_unavailable" }
  | { status: "locked"; remainingMs: number }
  | {
      status: "rejected";
      reason: "student_id" | "password" | "both";
      failureCount: number;
      lockDurationMs: number;
      lockUntilMs: number | null;
    };

export function normalizeCc98StudentId(value: string): string {
  return value.normalize("NFKC").replace(/\D/g, "");
}

export function normalizeCc98Password(value: string): string {
  return value.normalize("NFKC").trim();
}

/**
 * The first three submissions are the player's immediate attempts. Once the
 * third failure consumes that allowance, the next submission waits 30 seconds.
 * Every later failure adds another 30-second step.
 */
export function getCc98LoginLockDurationMs(failureCount: number): number {
  if (!Number.isFinite(failureCount) || failureCount < CC98_LOGIN_FREE_ATTEMPTS) {
    return 0;
  }
  return (Math.floor(failureCount) - CC98_LOGIN_FREE_ATTEMPTS + 1) * CC98_LOGIN_LOCK_STEP_MS;
}

export function getCc98LoginRemainingMs(
  state: Pick<Cc98UnifiedLoginState, "lockUntilMs">,
  nowMs: number
): number {
  if (state.lockUntilMs === null || !Number.isFinite(state.lockUntilMs)) return 0;
  return Math.max(0, state.lockUntilMs - nowMs);
}

export function evaluateCc98LoginAttempt(
  state: Cc98UnifiedLoginState,
  studentId: string,
  password: string,
  nowMs: number
): Cc98LoginAttemptResult {
  if (state.authenticated) return { status: "already_authenticated" };
  if (!state.studentIdDiscovered) return { status: "identity_unavailable" };

  const remainingMs = getCc98LoginRemainingMs(state, nowMs);
  if (remainingMs > 0) return { status: "locked", remainingMs };

  const studentIdMatches = normalizeCc98StudentId(studentId) === CC98_LOGIN_STUDENT_ID;
  const passwordMatches = normalizeCc98Password(password) === CC98_LOGIN_PASSWORD;
  if (studentIdMatches && passwordMatches) return { status: "authenticated" };

  const failureCount = Math.max(0, Math.floor(state.failureCount)) + 1;
  const lockDurationMs = getCc98LoginLockDurationMs(failureCount);
  return {
    status: "rejected",
    reason: studentIdMatches ? "password" : passwordMatches ? "student_id" : "both",
    failureCount,
    lockDurationMs,
    lockUntilMs: lockDurationMs > 0 ? nowMs + lockDurationMs : null
  };
}
