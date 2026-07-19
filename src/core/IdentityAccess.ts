import type { GameState } from "./types";

type IdentityAccessState = Pick<GameState, "actOne" | "items">;

/** Identity fields stay private until the recovered campus card is actually owned. */
export function selectIdentityReadable(state: IdentityAccessState): boolean {
  return state.actOne.inventoryRecovered && state.items.campusCard;
}
