import { describe, expect, it } from "vitest";
import { consumeFriendChatIntent, requestFriendChat } from "./NavIntent";

describe("NavIntent", () => {
  it("survives React StrictMode's immediate double initializer and then expires", async () => {
    requestFriendChat();

    expect(consumeFriendChatIntent()).toBe(true);
    expect(consumeFriendChatIntent()).toBe(true);

    await Promise.resolve();
    expect(consumeFriendChatIntent()).toBe(false);
  });
});
