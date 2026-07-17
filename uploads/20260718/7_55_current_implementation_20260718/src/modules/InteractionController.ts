export type InteractionKind = "click" | "drag" | "slider" | "puzzle" | "rotation";

export interface InteractionEvent {
  kind: InteractionKind;
  targetId: string;
}

export class InteractionController {
  private readonly history: InteractionEvent[] = [];

  record(event: InteractionEvent): void {
    this.history.push(event);
  }

  getHistory(): InteractionEvent[] {
    return [...this.history];
  }
}
