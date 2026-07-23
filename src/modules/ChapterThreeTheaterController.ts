import type { EventBus } from "../core/EventBus";
import type { GameStore, TheaterMode, TheaterProgramId } from "../core/types";
import {
  getRequiredTheaterSpotlightLockMs,
  getTheaterSpotlightAssist,
  getTheaterSpotlightRound,
  THEATER_SPOTLIGHT_ROUNDS,
  THEATER_SPOTLIGHT_SEQUENCE
} from "../scenes/rpg/TheaterSpotlightModel";
import type {
  TheaterSpotlightAttempt,
  TheaterSpotlightFailureReason,
  TheaterSpotlightLane,
  TheaterSpotlightRoundConfig
} from "../scenes/rpg/TheaterSpotlightModel";

export { THEATER_SPOTLIGHT_ROUNDS, THEATER_SPOTLIGHT_SEQUENCE };
export type {
  TheaterSpotlightAttempt,
  TheaterSpotlightFailureReason,
  TheaterSpotlightLane
};

export const THEATER_PROGRAM_ORDER: readonly TheaterProgramId[] = ["spotlight", "opening", "finale"];

const PROGRAM_ITEMS: Record<TheaterProgramId, "theaterProgramOpening" | "theaterProgramSpotlight" | "theaterProgramFinale"> = {
  opening: "theaterProgramOpening",
  spotlight: "theaterProgramSpotlight",
  finale: "theaterProgramFinale"
};

export class ChapterThreeTheaterController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  enterTheater(): boolean {
    const state = this.store.getState();
    const canStart = state.canteenHunt.phase === "theater_reached";
    if (!canStart && !state.theaterHunt.active) return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "theater_interior",
      rpgCheckpoint: current.theaterHunt.phase === "complete"
        ? "theater_lobby"
        : current.theaterHunt.admitted ? "theater_auditorium" : "theater_lobby",
      theaterHunt: {
        ...current.theaterHunt,
        active: true,
        phase: current.theaterHunt.active ? current.theaterHunt.phase : "entry_ticket",
        mode: current.theaterHunt.active ? current.theaterHunt.mode : "light"
      }
    }));
    this.events.emit("theater_entered");
    return true;
  }

  setMode(mode: TheaterMode): boolean {
    const state = this.store.getState();
    if (!state.theaterHunt.active || state.theaterHunt.phase === "complete") return false;
    if (state.theaterHunt.mode === mode) return true;
    this.store.setState((current) => ({
      ...current,
      theaterHunt: { ...current.theaterHunt, mode }
    }));
    this.events.emit("theater_mode_changed", { mode });
    return true;
  }

  cleanPoster(): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "entry_ticket"
      || state.theaterHunt.mode !== "light"
      || !state.items.greaseTissue
      || state.theaterHunt.posterCleaned
    ) return false;
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, theaterTicketHalfA: true },
      theaterHunt: { ...current.theaterHunt, posterCleaned: true }
    }));
    this.events.emit("use_item", { itemId: "greaseTissue", targetId: "theater-poster-glass", result: "retain" });
    this.events.emit("get_item", { itemId: "theaterTicketHalfA", sourceScene: "phone_home" });
    this.events.emit("theater_poster_cleaned");
    this.publishTicketHalvesReady();
    return true;
  }

  inspectTicketKiosk(): "code_read" | "code_panel" | "inactive" {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "entry_ticket") return "inactive";
    if (state.theaterHunt.mode === "dark") {
      if (!state.theaterHunt.ticketCodeRead) {
        this.store.setState((current) => ({
          ...current,
          theaterHunt: { ...current.theaterHunt, ticketCodeRead: true }
        }));
      }
      this.events.emit("theater_ticket_code_read");
      return "code_read";
    }
    this.events.emit("theater_ticket_code_panel_opened");
    return "code_panel";
  }

  submitTicketCode(code: string): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "entry_ticket" || state.theaterHunt.mode !== "light") return false;
    const correct = code === "0832" && state.theaterHunt.ticketCodeRead;
    this.store.setState((current) => ({
      ...current,
      items: correct ? { ...current.items, theaterTicketHalfB: true } : current.items,
      theaterHunt: {
        ...current.theaterHunt,
        ticketCodeAttempts: current.theaterHunt.ticketCodeAttempts + 1
      }
    }));
    this.events.emit(correct ? "theater_ticket_print_failed" : "theater_ticket_code_wrong", { code });
    if (correct) {
      this.events.emit("get_item", { itemId: "theaterTicketHalfB", sourceScene: "phone_home" });
      this.publishTicketHalvesReady();
    }
    return correct;
  }

  combineTicketHalves(): boolean {
    const state = this.store.getState();
    if (!state.items.theaterTicketHalfA || !state.items.theaterTicketHalfB || state.items.temporaryTheaterTicket) return false;
    this.store.setState((current) => ({
      ...current,
      items: {
        ...current.items,
        theaterTicketHalfA: false,
        theaterTicketHalfB: false,
        temporaryTheaterTicket: true
      }
    }));
    this.events.emit("combine_item", {
      a: "theaterTicketHalfA",
      b: "theaterTicketHalfB",
      result: "temporaryTheaterTicket"
    });
    this.events.emit("get_item", { itemId: "temporaryTheaterTicket", sourceScene: "phone_home" });
    this.events.emit("theater_ticket_combined");
    return true;
  }

  admitWithTicket(): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "entry_ticket" || !state.items.temporaryTheaterTicket) return false;
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "theater_auditorium",
      theaterHunt: { ...current.theaterHunt, admitted: true, phase: "program_search", mode: "light" }
    }));
    this.events.emit("use_item", { itemId: "temporaryTheaterTicket", targetId: "theater-ticket-gate", result: "retain" });
    this.events.emit("theater_ticket_admitted");
    return true;
  }

  collectProgram(programId: TheaterProgramId): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "program_search"
      || state.theaterHunt.mode !== "light"
      || state.theaterHunt.collectedProgramIds.includes(programId)
    ) return false;
    const itemId = PROGRAM_ITEMS[programId];
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [itemId]: true },
      theaterHunt: {
        ...current.theaterHunt,
        collectedProgramIds: [...current.theaterHunt.collectedProgramIds, programId]
      }
    }));
    this.events.emit("get_item", { itemId, sourceScene: "phone_home" });
    this.events.emit("theater_program_collected", { programId });
    return true;
  }

  readProgramOrder(): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "program_search"
      || state.theaterHunt.mode !== "dark"
      || state.theaterHunt.collectedProgramIds.length < 3
    ) return false;
    this.events.emit("theater_program_order_read");
    return true;
  }

  setProgramOrder(order: TheaterProgramId[]): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "program_search" || state.theaterHunt.mode !== "light") return false;
    if (order.length > 3 || new Set(order).size !== order.length || order.some((id) => !state.theaterHunt.collectedProgramIds.includes(id))) return false;
    this.store.setState((current) => ({
      ...current,
      theaterHunt: { ...current.theaterHunt, programOrder: [...order] }
    }));
    this.events.emit("theater_program_order_changed", { order: [...order] });
    return true;
  }

  submitProgramOrder(): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "program_search" || state.theaterHunt.programOrder.length !== 3) return false;
    const correct = THEATER_PROGRAM_ORDER.every((id, index) => state.theaterHunt.programOrder[index] === id);
    if (!correct) {
      this.store.setState((current) => ({
        ...current,
        theaterHunt: {
          ...current.theaterHunt,
          programOrder: current.theaterHunt.programOrder.slice(0, -1),
          programWrongAttempts: current.theaterHunt.programWrongAttempts + 1
        }
      }));
      this.events.emit("theater_program_order_wrong");
      return false;
    }
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "theater_stage",
      items: {
        ...current.items,
        theaterProgramOpening: false,
        theaterProgramSpotlight: false,
        theaterProgramFinale: false,
        spotlightRemote: true
      },
      theaterHunt: { ...current.theaterHunt, phase: "prop_setup", programOrder: [...THEATER_PROGRAM_ORDER] }
    }));
    this.events.emit("get_item", { itemId: "spotlightRemote", sourceScene: "phone_home" });
    this.events.emit("theater_program_order_solved");
    return true;
  }

  inspectPropBox(): "ghost" | "locked" | "opened" | "inactive" {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "prop_setup") return "inactive";
    if (state.theaterHunt.propBoxOpened) return "opened";
    if (state.theaterHunt.mode === "dark") {
      this.store.setState((current) => ({
        ...current,
        theaterHunt: { ...current.theaterHunt, propGhostRead: true, managerHintRead: true }
      }));
      this.events.emit("theater_prop_ghost_read");
      return "ghost";
    }
    this.events.emit("theater_prop_box_locked");
    return "locked";
  }

  openPropBoxWithTicket(): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "prop_setup"
      || state.theaterHunt.mode !== "light"
      || !state.items.temporaryTheaterTicket
      || !state.theaterHunt.managerHintRead
    ) return false;
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, fluorescentBrush: true },
      theaterHunt: { ...current.theaterHunt, propBoxOpened: true }
    }));
    this.events.emit("use_item", { itemId: "temporaryTheaterTicket", targetId: "theater-prop-scanner", result: "retain" });
    this.events.emit("get_item", { itemId: "fluorescentBrush", sourceScene: "phone_home" });
    this.events.emit("theater_prop_box_opened");
    return true;
  }

  dustPaperAtVent(): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "prop_setup"
      || state.theaterHunt.mode !== "light"
      || !state.items.fluorescentBrush
      || !state.theaterHunt.propBoxOpened
    ) return false;
    this.store.setState((current) => ({
      ...current,
      theaterHunt: { ...current.theaterHunt, paperDusted: true, phase: "spotlight_ready" }
    }));
    this.events.emit("use_item", { itemId: "fluorescentBrush", targetId: "theater-backstage-vent", result: "retain" });
    this.events.emit("theater_paper_dusted");
    return true;
  }

  startSpotlightHunt(): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "spotlight_ready"
      || !state.theaterHunt.paperDusted
      || !state.items.spotlightRemote
    ) return false;
    this.store.setState((current) => ({
      ...current,
      theaterHunt: { ...current.theaterHunt, phase: "spotlight_hunt", mode: "dark" }
    }));
    this.events.emit("use_item", { itemId: "spotlightRemote", targetId: "theater-spotlight-console", result: "retain" });
    this.events.emit("theater_spotlight_started");
    return true;
  }

  resolveSpotlightAttempt(attempt: TheaterSpotlightAttempt): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "spotlight_hunt" || state.theaterHunt.mode !== "light") return false;
    const round = getTheaterSpotlightRound(state.theaterHunt.spotlightRound);
    if (!round) return false;
    const requiredLockMs = getRequiredTheaterSpotlightLockMs(
      round,
      state.theaterHunt.spotlightMistakes
    );
    const failureReason = this.validateSpotlightAttempt(attempt, round, requiredLockMs);
    if (failureReason) {
      return this.rejectSpotlightAttempt(attempt, round, requiredLockMs, failureReason);
    }

    const spotlightRound = state.theaterHunt.spotlightRound + 1;
    const complete = spotlightRound >= THEATER_SPOTLIGHT_ROUNDS.length;
    this.store.setState((current) => ({
      ...current,
      theaterHunt: {
        ...current.theaterHunt,
        spotlightRound,
        mode: complete ? "light" : "dark",
        phase: complete ? "reversal" : "spotlight_hunt"
      }
    }));
    this.events.emit(complete ? "theater_spotlight_third_hit" : "theater_spotlight_hit", {
      lane: attempt.lane,
      round: spotlightRound,
      roundIndex: round.round,
      maxContinuousLockMs: attempt.maxContinuousLockMs,
      requiredLockMs,
      assistEnabled: getTheaterSpotlightAssist(state.theaterHunt.spotlightMistakes).enabled
    });
    return true;
  }

  /**
   * Compatibility lane for older theater scenes. New scenes must submit the
   * measured `rpg_theater_spotlight_attempt` payload.
   */
  resolveSpotlightChoice(lane: TheaterSpotlightLane): boolean {
    const state = this.store.getState();
    const round = getTheaterSpotlightRound(state.theaterHunt.spotlightRound);
    if (!round) return false;
    const requiredLockMs = getRequiredTheaterSpotlightLockMs(
      round,
      state.theaterHunt.spotlightMistakes
    );
    return this.resolveSpotlightAttempt({
      round: round.round,
      lane,
      maxContinuousLockMs: requiredLockMs,
      beamActivated: true,
      firstBeamAtMs: 0,
      actionMs: round.actionMs,
      submittedAtMs: requiredLockMs
    });
  }

  missSpotlightRound(): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "spotlight_hunt" || state.theaterHunt.mode !== "light") return false;
    const round = getTheaterSpotlightRound(state.theaterHunt.spotlightRound);
    if (!round) return false;
    const requiredLockMs = getRequiredTheaterSpotlightLockMs(
      round,
      state.theaterHunt.spotlightMistakes
    );
    this.rejectSpotlightAttempt({
      round: round.round,
      lane: round.lane,
      maxContinuousLockMs: 0,
      beamActivated: false,
      firstBeamAtMs: null,
      actionMs: round.actionMs,
      submittedAtMs: round.actionMs
    }, round, requiredLockMs, "timeout");
    return true;
  }

  completeReversal(): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "reversal" || state.theaterHunt.spotlightRound < 3) return false;
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, decoyPaper: true, wetProgram: true },
      theaterHunt: { ...current.theaterHunt, phase: "complete", decoyRevealed: true, mode: "light" },
      qizhenLake: {
        ...current.qizhenLake,
        active: true,
        phase: current.qizhenLake.phase === "inactive" ? "location_search" : current.qizhenLake.phase,
        mode: "light"
      }
    }));
    this.events.emit("get_item", { itemId: "decoyPaper", sourceScene: "phone_home" });
    this.events.emit("get_item", { itemId: "wetProgram", sourceScene: "phone_home" });
    this.events.emit("theater_reversal_completed");
    return true;
  }

  leaveTheater(): boolean {
    const state = this.store.getState();
    if (state.rpgScene !== "theater_interior" || state.theaterHunt.phase !== "complete") return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_theater_junction",
      qizhenLake: {
        ...current.qizhenLake,
        active: true,
        phase: current.qizhenLake.phase === "inactive" ? "location_search" : current.qizhenLake.phase
      }
    }));
    this.events.emit("theater_left_for_location_search");
    return true;
  }

  private validateSpotlightAttempt(
    attempt: TheaterSpotlightAttempt,
    round: TheaterSpotlightRoundConfig,
    requiredLockMs: number
  ): TheaterSpotlightFailureReason | null {
    if (!Number.isInteger(attempt.round) || attempt.round !== round.round) {
      return "round_mismatch";
    }
    if (
      !Number.isFinite(attempt.maxContinuousLockMs)
      || attempt.maxContinuousLockMs < 0
      || !Number.isFinite(attempt.actionMs)
      || attempt.actionMs <= 0
      || attempt.actionMs !== round.actionMs
      || !Number.isFinite(attempt.submittedAtMs)
      || attempt.submittedAtMs < 0
    ) {
      return "invalid_attempt";
    }
    if (!attempt.beamActivated || attempt.firstBeamAtMs === null) {
      return "beam_not_activated";
    }
    if (attempt.lane !== round.lane) return "wrong_lane";
    if (!Number.isFinite(attempt.firstBeamAtMs)) return "invalid_attempt";
    if (attempt.firstBeamAtMs < 0) return "early";
    if (
      attempt.firstBeamAtMs > attempt.submittedAtMs
      || attempt.firstBeamAtMs >= round.actionMs
      || attempt.submittedAtMs > round.actionMs
    ) {
      return "late";
    }
    if (attempt.maxContinuousLockMs < requiredLockMs) {
      if (attempt.firstBeamAtMs <= round.actionMs * 0.1) return "early";
      if (attempt.firstBeamAtMs + requiredLockMs > round.actionMs) return "late";
      return "interrupted";
    }
    return null;
  }

  private rejectSpotlightAttempt(
    attempt: TheaterSpotlightAttempt,
    round: TheaterSpotlightRoundConfig,
    requiredLockMs: number,
    failureReason: TheaterSpotlightFailureReason
  ): false {
    const state = this.store.getState();
    const assist = getTheaterSpotlightAssist(state.theaterHunt.spotlightMistakes + 1);
    this.store.setState((current) => ({
      ...current,
      theaterHunt: {
        ...current.theaterHunt,
        mode: "dark",
        spotlightMistakes: current.theaterHunt.spotlightMistakes + 1
      }
    }));
    this.events.emit("theater_spotlight_missed", {
      lane: attempt.lane,
      round: round.round + 1,
      roundIndex: round.round,
      attemptedRound: attempt.round,
      maxContinuousLockMs: attempt.maxContinuousLockMs,
      requiredLockMs,
      beamActivated: attempt.beamActivated,
      firstBeamAtMs: attempt.firstBeamAtMs,
      actionMs: attempt.actionMs,
      submittedAtMs: attempt.submittedAtMs,
      timeout: failureReason === "timeout",
      failureReason,
      retryRound: round.round + 1,
      assistEnabled: assist.enabled
    });
    return false;
  }

  private publishTicketHalvesReady(): void {
    queueMicrotask(() => {
      const items = this.store.getState().items;
      if (items.theaterTicketHalfA && items.theaterTicketHalfB && !items.temporaryTheaterTicket) {
        this.events.emit("theater_ticket_halves_ready");
      }
    });
  }
}
