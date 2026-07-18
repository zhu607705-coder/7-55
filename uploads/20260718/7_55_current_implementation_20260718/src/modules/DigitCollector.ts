import type { EventBus } from "../core/EventBus";
import type { DigitIndex, DigitValue, GameStore, SceneId } from "../core/types";

const INDEX_TO_KEY: Record<1 | 2 | 3 | 4, DigitIndex> = {
  1: "d1",
  2: "d2",
  3: "d3",
  4: "d4"
};

export class DigitCollector {
  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  collectDigit(index: 1 | 2 | 3 | 4, value: DigitValue, sourceScene: SceneId): void {
    const key = INDEX_TO_KEY[index];
    this.store.setState((state) => ({
      ...state,
      digits: {
        ...state.digits,
        [key]: value
      }
    }));
    this.events.emit("collect_digit", { index: key, value, sourceScene });
  }

  hasAllDigits(): boolean {
    const digits = this.store.getState().digits;
    return Boolean(digits.d1 && digits.d2 && digits.d3 && digits.d4);
  }

  getCode(): string {
    const { d1, d2, d3, d4 } = this.store.getState().digits;
    return [d1, d2, d3, d4].filter(Boolean).join("");
  }
}
