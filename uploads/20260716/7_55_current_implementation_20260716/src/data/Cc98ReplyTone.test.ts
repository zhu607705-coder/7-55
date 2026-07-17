import { describe, expect, it } from "vitest";
import posts from "./cc98.posts.json";
import libraryFinalsContent from "./library-finals.content.json";

describe("CC98 reply tone contract", () => {
  it("keeps six distinct, topic-aware campus water replies on every ordinary post", () => {
    const allReplies = posts.flatMap((post) => post.threadReplies);

    expect(posts).toHaveLength(5);
    expect(allReplies).toHaveLength(30);
    expect(new Set(allReplies.map(({ text }) => text)).size).toBe(30);
    for (const post of posts) {
      expect(post.threadReplies).toHaveLength(6);
      expect(new Set(post.threadReplies.map(({ personaId }) => personaId)).size).toBe(6);
      expect(post.threadReplies.every(({ role, text }) => role.length > 0 && text.length >= 12)).toBe(true);
    }

    expect(allReplies.map(({ text }) => text).join("\n")).not.toMatch(/目前有效路线有|恢复页需要|结论可复现|建议保留教师/u);
  });

  it("keeps optional and rejected library replies playful without turning them into clues", () => {
    const cc98 = libraryFinalsContent.cc98;
    const rejected = cc98.bdOptions.filter(({ valid }) => !valid);

    expect(cc98.optionalAc01Replies).toHaveLength(5);
    expect(cc98.optionalAc01Replies.every(({ text }) => text.includes("ac01"))).toBe(true);
    expect(new Set(cc98.optionalAc01Replies.map(({ author }) => author)).size).toBe(5);
    expect(new Set(cc98.fillerReplies.texts).size).toBe(cc98.fillerReplies.texts.length);
    expect(rejected.map(({ key }) => key)).toEqual(["B", "D"]);
    expect(rejected.map(({ text }) => text).join(" ")).toMatch(/书包/u);
    expect(rejected.map(({ text }) => text).join(" ")).toMatch(/bd|空调/u);
  });
});
