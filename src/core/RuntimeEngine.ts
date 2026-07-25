export type RpgRuntimeEngine = "phaser" | "godot";

export function resolveRpgRuntimeEngine(search: string): RpgRuntimeEngine {
  const params = new URLSearchParams(search);
  return params.get("engine")?.toLowerCase() === "godot" ? "godot" : "phaser";
}
