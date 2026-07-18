import { describe, expect, it, vi } from "vitest";
import { EventBus } from "../../core/EventBus";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

class LifecycleStub {
  private readonly listeners = new Map<string, Array<() => void>>();

  once(event: string, listener: () => void): void {
    this.listeners.set(event, [...(this.listeners.get(event) ?? []), listener]);
  }

  emit(event: string): void {
    const listeners = this.listeners.get(event) ?? [];
    this.listeners.delete(event);
    listeners.forEach((listener) => listener());
  }
}

describe("subscribeRpgSceneBridge", () => {
  it.each(["shutdown", "destroy"])("detaches the bridge listener on %s", (lifecycleEvent) => {
    const events = new EventBus();
    const lifecycle = new LifecycleStub();
    const listener = vi.fn();
    const cleanup = vi.fn();

    subscribeRpgSceneBridge(lifecycle, { subscribe: events.subscribe.bind(events) }, listener, cleanup);
    events.emit("rpg_interact");
    lifecycle.emit(lifecycleEvent);
    events.emit("rpg_interact");
    lifecycle.emit(lifecycleEvent === "shutdown" ? "destroy" : "shutdown");

    expect(listener).toHaveBeenCalledTimes(1);
    expect(cleanup).toHaveBeenCalledTimes(1);
  });
});
