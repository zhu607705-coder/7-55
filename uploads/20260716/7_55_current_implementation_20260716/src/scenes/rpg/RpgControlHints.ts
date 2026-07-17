export const RPG_CONTROL_HINTS = {
  movement: "WASD 移动",
  interactionKey: "空格键",
  libraryGate: "WASD 移动 · 空格键进入",
  continueDialogue: "空格键继续",
  touchInteraction: "空格"
} as const;

export function formatRpgInteractionHint(label: string): string {
  return `${RPG_CONTROL_HINTS.interactionKey}  ${label}`;
}
