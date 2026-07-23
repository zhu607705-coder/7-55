import type { EventBus } from "../core/EventBus";
import type {
  GameStore,
  ItemId,
  QizhenDecoyTargetId,
  QizhenLakePhase,
  QizhenLakeMode,
  QizhenMapClueId,
  RpgCheckpointId
} from "../core/types";

export type QizhenMapClueResult = "added" | "already_added" | "location_solved" | "wrong_item" | "inactive";
export type QizhenReflectionResult = "correct" | "wrong" | "complete" | "wrong_mode" | "inactive";
export type QizhenSignResult = "rotated" | "complete" | "wrong_mode" | "inactive";
export type QizhenDecoyResult = "correct" | "wrong" | "missing_coordinate" | "wrong_mode" | "inactive";
export type QizhenMistResult = "correct" | "wrong" | "unread" | "wrong_mode" | "inactive";

export const QIZHEN_REFLECTION_REAL_SEQUENCE = ["right", "center", "left"] as const;
export const QIZHEN_SIGN_TARGET_ROTATIONS: readonly [number, number, number] = [1, 2, 3];

const MAP_CLUE_ITEMS: Readonly<Record<QizhenMapClueId, ItemId>> = {
  bridge: "bridgeKeyword",
  reflection: "reflectionKeyword",
  lake: "lakeKeyword"
};

const ITEM_TO_MAP_CLUE: Partial<Record<ItemId, QizhenMapClueId>> = {
  bridgeKeyword: "bridge",
  reflectionKeyword: "reflection",
  lakeKeyword: "lake"
};

export class ChapterThreeQizhenLakeController {
  constructor(private readonly store: GameStore, private readonly events: EventBus) {}

  acknowledgeLocationBriefing(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search") return false;
    if (!state.qizhenLake.locationBriefingSeen) {
      this.store.setState((current) => ({
        ...current,
        qizhenLake: { ...current.qizhenLake, locationBriefingSeen: true }
      }));
    }
    this.events.emit("qizhen_location_briefing_seen");
    return true;
  }

  collectBridgeClue(): boolean {
    return this.collectClue("bridge", "qizhen_bridge_clue_found");
  }

  collectReflectionClue(): boolean {
    return this.collectClue("reflection", "qizhen_reflection_clue_found");
  }

  collectLakeClue(): boolean {
    return this.collectClue("lake", "qizhen_lake_clue_found");
  }

  addMapClue(itemId: ItemId): QizhenMapClueResult {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search") return "inactive";
    const clueId = ITEM_TO_MAP_CLUE[itemId];
    if (!clueId || !state.items[itemId]) return "wrong_item";
    if (state.qizhenLake.mapClueIds.includes(clueId)) return "already_added";
    const mapClueIds = [...state.qizhenLake.mapClueIds, clueId];
    const solved = mapClueIds.length === 3;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        mapClueIds,
        phase: solved ? "lake_unlocked" : current.qizhenLake.phase
      }
    }));
    this.events.emit(solved ? "qizhen_location_solved" : "qizhen_map_clue_added", {
      clueId,
      count: mapClueIds.length
    });
    return solved ? "location_solved" : "added";
  }

  getMapClueCount(): number {
    return this.store.getState().qizhenLake.mapClueIds.length;
  }

  enterLake(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || ["inactive", "location_search"].includes(state.qizhenLake.phase)) return false;
    const phase = state.qizhenLake.phase === "lake_unlocked" ? "reflection_hunt" : state.qizhenLake.phase;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "qizhen_lake",
      rpgCheckpoint: checkpointForPhase(phase),
      qizhenLake: {
        ...current.qizhenLake,
        active: true,
        phase,
        mode: current.qizhenLake.phase === "lake_unlocked" ? "light" : current.qizhenLake.mode
      }
    }));
    this.events.emit("qizhen_lake_entered", { phase });
    return true;
  }

  enterCampusApproach(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || ["inactive", "location_search"].includes(state.qizhenLake.phase)) return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_qizhen_gate",
      ui: { ...current.ui, inventoryOpen: false, selectedItem: null, zjudingPage: "hub" }
    }));
    this.events.emit("qizhen_campus_approach_entered", { checkpoint: "campus_qizhen_gate" });
    return true;
  }

  leaveLake(): boolean {
    const state = this.store.getState();
    if (state.rpgScene !== "qizhen_lake") return false;
    this.store.setState((current) => ({
      ...current,
      runtimeMode: "rpg",
      rpgScene: "campus_bootstrap",
      rpgCheckpoint: "campus_qizhen_gate"
    }));
    this.events.emit("qizhen_lake_left");
    return true;
  }

  markIntroSeen(): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.introSeen) return false;
    this.store.setState((current) => ({
      ...current,
      qizhenLake: { ...current.qizhenLake, introSeen: true }
    }));
    return true;
  }

  setMode(mode: QizhenLakeMode): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || ["inactive", "location_search", "lake_unlocked", "chase_ready"].includes(state.qizhenLake.phase)) {
      return false;
    }
    if (state.qizhenLake.mode === mode) return true;
    const revealDecoy = state.qizhenLake.phase === "decoy_setup"
      && state.qizhenLake.decoyPlacedAt === "lamp"
      && mode === "dark";
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: revealDecoy ? "qizhen_mist" : current.rpgCheckpoint,
      qizhenLake: {
        ...current.qizhenLake,
        mode,
        phase: revealDecoy ? "mist_timing" : current.qizhenLake.phase
      }
    }));
    this.events.emit("qizhen_mode_changed", { mode });
    this.events.emit(mode === "dark" ? "qizhen_dark_mode_enabled" : "qizhen_light_mode_enabled", { mode });
    if (revealDecoy) this.events.emit("qizhen_decoy_revealed");
    return true;
  }

  interceptReflection(positionId: string): QizhenReflectionResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "reflection_hunt") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    const expected = QIZHEN_REFLECTION_REAL_SEQUENCE[state.qizhenLake.reflectionRound];
    if (positionId !== expected) {
      this.store.setState((current) => ({
        ...current,
        qizhenLake: {
          ...current.qizhenLake,
          reflectionMistakes: current.qizhenLake.reflectionMistakes + 1
        }
      }));
      this.events.emit("qizhen_reflection_wrong", { positionId, round: state.qizhenLake.reflectionRound + 1 });
      return "wrong";
    }
    const reflectionRound = state.qizhenLake.reflectionRound + 1;
    const complete = reflectionRound >= QIZHEN_REFLECTION_REAL_SEQUENCE.length;
    this.store.setState((current) => ({
      ...current,
      rpgCheckpoint: complete ? "qizhen_signs" : current.rpgCheckpoint,
      qizhenLake: {
        ...current.qizhenLake,
        reflectionRound,
        phase: complete ? "sign_alignment" : current.qizhenLake.phase,
        mode: complete ? "dark" : current.qizhenLake.mode
      }
    }));
    this.events.emit(complete ? "qizhen_reflection_completed" : "qizhen_reflection_correct", {
      positionId,
      round: reflectionRound
    });
    return complete ? "complete" : "correct";
  }

  rotateSign(signIndex: number): QizhenSignResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "sign_alignment") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!Number.isInteger(signIndex) || signIndex < 0 || signIndex > 2) return "inactive";
    const signRotations = [...state.qizhenLake.signRotations] as [number, number, number];
    signRotations[signIndex] = (signRotations[signIndex] + 1) % 4;
    const complete = signRotations.every((rotation, index) => rotation === QIZHEN_SIGN_TARGET_ROTATIONS[index]);
    this.store.setState((current) => ({
      ...current,
      items: complete ? { ...current.items, reflectionCoordinate: true } : current.items,
      rpgCheckpoint: complete ? "qizhen_decoy" : current.rpgCheckpoint,
      qizhenLake: {
        ...current.qizhenLake,
        signRotations,
        signsSolved: complete,
        phase: complete ? "decoy_setup" : current.qizhenLake.phase,
        mode: complete ? "light" : current.qizhenLake.mode
      }
    }));
    this.events.emit(complete ? "qizhen_signs_completed" : "qizhen_sign_rotated", { signIndex, rotation: signRotations[signIndex] });
    if (complete) this.events.emit("get_item", { itemId: "reflectionCoordinate", sourceScene: "qizhen_lake" });
    return complete ? "complete" : "rotated";
  }

  placeDecoy(targetId: QizhenDecoyTargetId): QizhenDecoyResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "decoy_setup" || !state.items.decoyPaper) return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.items.reflectionCoordinate || !state.qizhenLake.signsSolved) return "missing_coordinate";
    const correct = targetId === "lamp";
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        decoyPlacedAt: correct ? targetId : current.qizhenLake.decoyPlacedAt,
        decoyAttempts: current.qizhenLake.decoyAttempts + (correct ? 0 : 1)
      }
    }));
    this.events.emit(correct ? "qizhen_decoy_placed" : "qizhen_decoy_wrong", { targetId });
    return correct ? "correct" : "wrong";
  }

  observeMistRhythm(): boolean {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "mist_timing" || state.qizhenLake.mode !== "dark") return false;
    if (!state.qizhenLake.mistRhythmRead) {
      this.store.setState((current) => ({
        ...current,
        qizhenLake: { ...current.qizhenLake, mistRhythmRead: true }
      }));
    }
    this.events.emit("qizhen_mist_rhythm_read");
    return true;
  }

  triggerMist(success: boolean): QizhenMistResult {
    const state = this.store.getState();
    if (state.qizhenLake.phase !== "mist_timing") return "inactive";
    if (state.qizhenLake.mode !== "light") return "wrong_mode";
    if (!state.qizhenLake.mistRhythmRead) return "unread";
    this.store.setState((current) => ({
      ...current,
      qizhenLake: {
        ...current.qizhenLake,
        mistAttempts: current.qizhenLake.mistAttempts + 1,
        phase: success ? "chase_ready" : current.qizhenLake.phase,
        paperReleased: success
      }
    }));
    this.events.emit(success ? "qizhen_mist_completed" : "qizhen_mist_wrong", {
      attempt: state.qizhenLake.mistAttempts + 1
    });
    return success ? "correct" : "wrong";
  }

  private collectClue(clueId: QizhenMapClueId, eventName: string): boolean {
    const state = this.store.getState();
    if (!state.qizhenLake.active || state.qizhenLake.phase !== "location_search" || !state.items.wetProgram) return false;
    const flagName = `${clueId}ClueFound` as "bridgeClueFound" | "reflectionClueFound" | "lakeClueFound";
    if (state.qizhenLake[flagName]) return true;
    const itemId = MAP_CLUE_ITEMS[clueId];
    this.store.setState((current) => ({
      ...current,
      items: { ...current.items, [itemId]: true },
      qizhenLake: { ...current.qizhenLake, [flagName]: true }
    }));
    this.events.emit("get_item", { itemId, sourceScene: clueId === "bridge" ? "cc98" : clueId === "reflection" ? "zjuding" : "wechat" });
    this.events.emit(eventName, { clueId });
    return true;
  }
}

function checkpointForPhase(phase: QizhenLakePhase): RpgCheckpointId {
  if (phase === "sign_alignment") return "qizhen_signs";
  if (phase === "decoy_setup") return "qizhen_decoy";
  if (phase === "mist_timing" || phase === "chase_ready") return "qizhen_mist";
  return "qizhen_reflection";
}
