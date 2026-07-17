import type { GameEvent } from "./types";

type EventHandler = (event: GameEvent) => void;

export class EventBus {
  private readonly handlers = new Set<EventHandler>();
  private readonly history: GameEvent[] = [];

  emit(name: string, payload?: Record<string, unknown>): void {
    const event = payload === undefined ? { name } : { name, payload };
    this.history.push(event);
    this.handlers.forEach((handler) => handler(event));
  }

  subscribe(handler: EventHandler): () => void {
    this.handlers.add(handler);
    return () => this.handlers.delete(handler);
  }

  getHistory(): GameEvent[] {
    return [...this.history];
  }

  clearHistory(): void {
    this.history.length = 0;
  }
}

export const eventBus = new EventBus();
