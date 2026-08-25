import { selectFeatureAccess } from "../core/FeatureAccess";
import { ENDLESS_RECORD_LIMITS } from "../core/SaveStore";
import type {
  EndlessChallengeModeId,
  EndlessChallengeRecord,
  GameStore
} from "../core/types";
import type { EventBus } from "../core/EventBus";

const MODE_IDS: readonly EndlessChallengeModeId[] = ["fishing", "spotlight", "bike"];
const SEED_SALT = "7:55:endless:v1";

export interface EndlessArcadeRunTicket {
  readonly runId: string;
  readonly mode: EndlessChallengeModeId;
  readonly seed: number;
  readonly attempt: number;
  readonly sessionOnly: boolean;
}

export interface EndlessArcadeSettlement {
  readonly runId: string;
  readonly mode: EndlessChallengeModeId;
  readonly score: number;
  readonly progress: number;
  readonly tier: number;
  readonly combo: number;
  readonly durationMs: number;
}

interface ActiveEndlessRun extends EndlessArcadeRunTicket {}

type DevelopmentSessionAccess = () => boolean;

/**
 * Owns one runtime-only endless attempt and persists only its compact record.
 * Scene code receives a ticket, then can only settle or cancel that exact ticket.
 */
export class EndlessArcadeController {
  private activeRun: ActiveEndlessRun | null = null;
  private runSequence = 0;

  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus,
    private readonly hasDevelopmentSessionAccess: DevelopmentSessionAccess = () => false
  ) {}

  startAttempt(mode: EndlessChallengeModeId): EndlessArcadeRunTicket | null {
    if (!isMode(mode) || this.activeRun !== null || !this.canStart()) return null;

    const record = this.store.getState().endlessArcade.records[mode];
    if (!isBoundedInteger(record.attemptCount, 0, ENDLESS_RECORD_LIMITS.attemptCount - 1)) return null;

    const attempt = record.attemptCount + 1;
    this.runSequence = this.runSequence >= Number.MAX_SAFE_INTEGER ? 1 : this.runSequence + 1;
    const runId = `${mode}:${attempt}:${this.runSequence}`;
    const sessionOnly = !selectFeatureAccess(this.store.getState()).endlessChallenge;
    const ticket: ActiveEndlessRun = {
      runId,
      mode,
      seed: deriveEndlessSeed(mode, attempt, this.runSequence),
      attempt,
      sessionOnly
    };

    this.store.setState((state) => ({
      ...state,
      endlessArcade: {
        ...state.endlessArcade,
        records: {
          ...state.endlessArcade.records,
          [mode]: {
            ...state.endlessArcade.records[mode],
            attemptCount: attempt
          }
        }
      }
    }));
    this.activeRun = ticket;
    this.events.emit("endless_arcade_attempt_started", {
      runId: ticket.runId,
      mode: ticket.mode,
      seed: ticket.seed,
      attempt: ticket.attempt,
      sessionOnly: ticket.sessionOnly
    });
    return ticket;
  }

  settleAttempt(summary: EndlessArcadeSettlement): EndlessChallengeRecord | null {
    const active = this.activeRun;
    if (active === null || !isValidSettlement(summary) || summary.runId !== active.runId || summary.mode !== active.mode) {
      return null;
    }

    const currentRecord = this.store.getState().endlessArcade.records[active.mode];
    if (currentRecord.attemptCount !== active.attempt) return null;
    const nextRecord: EndlessChallengeRecord = {
      attemptCount: currentRecord.attemptCount,
      bestScore: Math.max(currentRecord.bestScore, summary.score),
      bestProgress: Math.max(currentRecord.bestProgress, summary.progress),
      bestTier: Math.max(currentRecord.bestTier, summary.tier),
      bestCombo: Math.max(currentRecord.bestCombo, summary.combo),
      bestDurationMs: Math.max(currentRecord.bestDurationMs, summary.durationMs)
    };
    this.activeRun = null;
    this.store.setState((state) => ({
      ...state,
      endlessArcade: {
        ...state.endlessArcade,
        records: {
          ...state.endlessArcade.records,
          [active.mode]: nextRecord
        }
      }
    }));
    this.events.emit("endless_arcade_attempt_settled", {
      runId: active.runId,
      mode: active.mode,
      score: summary.score,
      progress: summary.progress,
      tier: summary.tier,
      combo: summary.combo,
      durationMs: summary.durationMs,
      sessionOnly: active.sessionOnly
    });
    return nextRecord;
  }

  cancelAttempt(runId: string): boolean {
    const active = this.activeRun;
    if (active === null || active.runId !== runId) return false;
    this.activeRun = null;
    this.events.emit("endless_arcade_attempt_cancelled", {
      runId: active.runId,
      mode: active.mode,
      attempt: active.attempt,
      sessionOnly: active.sessionOnly
    });
    return true;
  }

  getActiveRun(): EndlessArcadeRunTicket | null {
    return this.activeRun;
  }

  private canStart(): boolean {
    return selectFeatureAccess(this.store.getState()).endlessChallenge || this.hasDevelopmentSessionAccess();
  }
}

export function deriveEndlessSeed(mode: EndlessChallengeModeId, attempt: number, sequence: number): number {
  let hash = 2_166_136_261;
  const input = `${SEED_SALT}:${mode}:${attempt}:${sequence}`;
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index);
    hash = Math.imul(hash, 16_777_619);
  }
  return (hash >>> 0) || 1;
}

function isMode(value: unknown): value is EndlessChallengeModeId {
  return typeof value === "string" && MODE_IDS.includes(value as EndlessChallengeModeId);
}

function isBoundedInteger(value: unknown, minimum: number, maximum: number): value is number {
  return Number.isFinite(value)
    && Number.isSafeInteger(value)
    && typeof value === "number"
    && value >= minimum
    && value <= maximum;
}

function isValidSettlement(value: unknown): value is EndlessArcadeSettlement {
  if (typeof value !== "object" || value === null) return false;
  const summary = value as Partial<EndlessArcadeSettlement>;
  return typeof summary.runId === "string"
    && summary.runId.length > 0
    && isMode(summary.mode)
    && isBoundedInteger(summary.score, 0, ENDLESS_RECORD_LIMITS.bestScore)
    && isBoundedInteger(summary.progress, 0, ENDLESS_RECORD_LIMITS.bestProgress)
    && isBoundedInteger(summary.tier, 0, ENDLESS_RECORD_LIMITS.bestTier)
    && isBoundedInteger(summary.combo, 0, ENDLESS_RECORD_LIMITS.bestCombo)
    && isBoundedInteger(summary.durationMs, 0, ENDLESS_RECORD_LIMITS.bestDurationMs);
}
