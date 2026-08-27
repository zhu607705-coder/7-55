import type { EventBus } from "../core/EventBus";
import type { GameStore, TheaterMode, TheaterProgramId } from "../core/types";
import {
  getRequiredTheaterSpotlightLockMs,
  getTheaterSpotlightAssist,
  getTheaterSpotlightRound,
  validateTheaterSpotlightAttempt,
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

export type TheaterTicketReleaseResult =
  | "first_wave_slow"
  | "cellular_required"
  | "won_first_wave"
  | "won_second_wave"
  | "already_won"
  | "inactive";

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
    const shouldPublishCommission = state.theaterHunt.cc98TicketCommissionPhase === "locked";
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
        mode: current.theaterHunt.mode,
        cc98TicketCommissionPhase: current.theaterHunt.cc98TicketCommissionPhase === "locked"
          ? "posted"
          : current.theaterHunt.cc98TicketCommissionPhase
      }
    }));
    this.events.emit("theater_entered");
    if (shouldPublishCommission) {
      this.events.emit("cc98_ticket_commission_posted");
    }
    return true;
  }

  acceptCc98TicketCommission(): boolean {
    const state = this.store.getState();
    const phase = state.theaterHunt.cc98TicketCommissionPhase;
    if (phase === "accepted" || phase === "first_wave_failed" || phase === "delivered") return true;
    if (!state.theaterHunt.active || state.theaterHunt.phase !== "entry_ticket" || phase !== "posted") return false;
    this.store.setState((current) => ({
      ...current,
      theaterHunt: {
        ...current.theaterHunt,
        cc98TicketCommissionPhase: "accepted"
      }
    }));
    this.events.emit("cc98_ticket_commission_accepted");
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
      items: { ...current.items, greaseTissue: false, theaterTicketHalfA: true },
      ui: current.ui.selectedItem === "greaseTissue"
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      theaterHunt: { ...current.theaterHunt, posterCleaned: true }
    }));
    this.events.emit("use_item", { itemId: "greaseTissue", targetId: "theater-poster-glass", result: "consume" });
    this.events.emit("get_item", { itemId: "theaterTicketHalfA", sourceScene: "phone_home" });
    this.events.emit("theater_poster_cleaned");
    this.publishTicketHalvesReady();
    return true;
  }

  attemptCc98TicketRelease(): TheaterTicketReleaseResult {
    const state = this.store.getState();
    if (
      !state.theaterHunt.active
      || state.theaterHunt.phase !== "entry_ticket"
    ) return "inactive";
    const commissionPhase = state.theaterHunt.cc98TicketCommissionPhase;
    if (commissionPhase === "delivered") return "already_won";
    if (commissionPhase === "accepted") {
      if (state.networkMode === "cellular") {
        this.completeTicketCommission(1);
        return "won_first_wave";
      }
      this.store.setState((current) => ({
        ...current,
        theaterHunt: {
          ...current.theaterHunt,
          cc98TicketCommissionPhase: "first_wave_failed"
        }
      }));
      this.events.emit("theater_ticket_first_wave_slow", { releaseWave: 1, surface: "phone" });
      return "first_wave_slow";
    }
    if (commissionPhase === "first_wave_failed") {
      if (state.networkMode !== "cellular") {
        this.events.emit("theater_ticket_cellular_required", { releaseWave: 2, surface: "phone" });
        return "cellular_required";
      }
      this.completeTicketCommission(2);
      return "won_second_wave";
    }
    return "inactive";
  }

  inspectTicketKiosk(): "code_read" | "code_panel" | "phone_release_required" | "already_printed" | "inactive" {
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
    if (state.theaterHunt.cc98TicketCommissionPhase !== "delivered") {
      this.events.emit("theater_ticket_phone_release_required");
      return "phone_release_required";
    }
    if (state.items.theaterTicketHalfB || state.items.temporaryTheaterTicket) {
      this.events.emit("theater_ticket_already_delivered");
      return "already_printed";
    }
    this.events.emit("theater_ticket_code_panel_opened");
    return "code_panel";
  }

  submitTicketCode(code: string): boolean {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "entry_ticket" || state.theaterHunt.mode !== "light") return false;
    const codeMatches = code === "0832";
    if (!codeMatches) {
      this.store.setState((current) => ({
        ...current,
        theaterHunt: {
          ...current.theaterHunt,
          ticketCodeAttempts: current.theaterHunt.ticketCodeAttempts + 1
        }
      }));
      this.events.emit("theater_ticket_code_wrong", { code });
      return false;
    }
    if (state.theaterHunt.cc98TicketCommissionPhase !== "delivered") {
      this.store.setState((current) => ({
        ...current,
        theaterHunt: {
          ...current.theaterHunt,
          ticketCodeAttempts: current.theaterHunt.ticketCodeAttempts + 1
        }
      }));
      this.events.emit("theater_ticket_phone_release_required", { code });
      return false;
    }
    if (state.items.theaterTicketHalfB || state.items.temporaryTheaterTicket) {
      this.events.emit("theater_ticket_already_delivered");
      return true;
    }
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, theaterTicketHalfB: true },
      theaterHunt: {
        ...current.theaterHunt,
        ticketCodeAttempts: current.theaterHunt.ticketCodeAttempts + 1,
        ticketCodeRead: true
      }
    }));
    this.events.emit("theater_ticket_printed", { code });
    this.events.emit("get_item", { itemId: "theaterTicketHalfB", sourceScene: "phone_home" });
    this.publishTicketHalvesReady();
    return true;
  }

  private completeTicketCommission(releaseWave: 1 | 2): void {
    this.store.setState((current) => ({
      ...current,
      theaterHunt: {
        ...current.theaterHunt,
        cc98TicketCommissionPhase: "delivered",
        cc98TicketClaimedWave: releaseWave
      }
    }));
    this.events.emit(
      releaseWave === 1 ? "theater_ticket_first_wave_cellular_success" : "theater_ticket_second_wave_success",
      { releaseWave, surface: "phone" }
    );
    this.events.emit("cc98_ticket_commission_delivered", { releaseWave });
  }

  recoverTicketCombination(): boolean {
    const state = this.store.getState();
    if (!state.items.theaterTicketHalfA || !state.items.theaterTicketHalfB || state.items.temporaryTheaterTicket) {
      return false;
    }
    return this.combineTicketHalves();
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
      },
      ui: current.ui.selectedItem === "theaterTicketHalfA" || current.ui.selectedItem === "theaterTicketHalfB"
        ? { ...current.ui, selectedItem: null }
        : current.ui
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
    if (
      state.theaterHunt.phase !== "entry_ticket"
      || state.theaterHunt.mode !== "light"
      || !state.items.temporaryTheaterTicket
    ) return false;
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: "theater_auditorium",
      theaterHunt: { ...current.theaterHunt, admitted: true, phase: "program_search" }
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
      ui: current.ui.selectedItem && [
        "theaterProgramOpening",
        "theaterProgramSpotlight",
        "theaterProgramFinale"
      ].includes(current.ui.selectedItem)
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      theaterHunt: { ...current.theaterHunt, phase: "prop_setup", programOrder: [...THEATER_PROGRAM_ORDER] }
    }));
    this.events.emit("get_item", { itemId: "spotlightRemote", sourceScene: "phone_home" });
    this.events.emit("theater_program_order_solved");
    return true;
  }

  inspectPropBox(): "ghost" | "locked" | "opened" | "inactive" {
    const state = this.store.getState();
    if (state.theaterHunt.phase !== "prop_setup") return "inactive";
    if (state.theaterHunt.mode === "dark") {
      this.store.setState((current) => ({
        ...current,
        theaterHunt: { ...current.theaterHunt, propGhostRead: true, managerHintRead: true }
      }));
      this.events.emit("theater_prop_ghost_read");
      return "ghost";
    }
    if (state.theaterHunt.propBoxOpened) return "opened";
    this.events.emit("theater_prop_box_locked");
    return "locked";
  }

  openPropBoxWithTicket(): boolean {
    const state = this.store.getState();
    if (
      state.theaterHunt.phase !== "prop_setup"
      || state.theaterHunt.mode !== "light"
      || !state.items.temporaryTheaterTicket
    ) return false;
    this.store.setState((current) => ({
      ...current,
      items: {
        ...current.items,
        temporaryTheaterTicket: false,
        fluorescentBrush: true
      },
      ui: current.ui.selectedItem === "temporaryTheaterTicket"
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      theaterHunt: { ...current.theaterHunt, propBoxOpened: true }
    }));
    this.events.emit("use_item", { itemId: "temporaryTheaterTicket", targetId: "theater-prop-scanner", result: "consume" });
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
      items: { ...current.items, fluorescentBrush: false },
      ui: current.ui.selectedItem === "fluorescentBrush"
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      theaterHunt: { ...current.theaterHunt, paperDusted: true, phase: "spotlight_ready" }
    }));
    this.events.emit("use_item", { itemId: "fluorescentBrush", targetId: "theater-backstage-vent", result: "consume" });
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
      items: { ...current.items, spotlightRemote: false },
      ui: current.ui.selectedItem === "spotlightRemote"
        ? { ...current.ui, selectedItem: null }
        : current.ui,
      theaterHunt: { ...current.theaterHunt, phase: "spotlight_hunt" }
    }));
    this.events.emit("use_item", { itemId: "spotlightRemote", targetId: "theater-spotlight-console", result: "consume" });
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
    const failureReason = validateTheaterSpotlightAttempt(attempt, round, requiredLockMs);
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
      theaterHunt: { ...current.theaterHunt, phase: "complete", decoyRevealed: true },
      qizhenLake: {
        ...current.qizhenLake,
        active: true,
        phase: current.qizhenLake.phase === "inactive" ? "location_search" : current.qizhenLake.phase
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
      rpgScene: "campus_qizhen_loop",
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
