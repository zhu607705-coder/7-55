import type { CSSProperties } from "react";
import { selectIdentityReadable } from "../core/IdentityAccess";
import type { GameState } from "../core/types";
import actOneContent from "../data/act-one-bootstrap.content.json";

export type GameSubtitleTone =
  | "system"
  | "narrator"
  | "task"
  | "player"
  | "success"
  | "error"
  | "broadcast";

const DEFAULT_SPEAKER: Readonly<Record<GameSubtitleTone, string>> = {
  system: "系统",
  narrator: "旁白",
  task: "任务",
  player: "我",
  success: "记录",
  error: "提示",
  broadcast: "广播"
};

interface GameSubtitleFrameProps {
  text: string;
  tone: GameSubtitleTone;
  state?: GameState;
  speaker?: string;
  durationMs?: number;
  className?: string;
}

function visibleSubtitleText(text: string, state?: GameState): string {
  if (!state || selectIdentityReadable(state)) return text;
  return text
    .replaceAll(actOneContent.studentName, "身份信息")
    .replaceAll(actOneContent.studentId, "身份编号");
}

/** Shared transient subtitle frame for phone, desktop, and RPG surfaces. */
export function GameSubtitleFrame({
  text,
  tone,
  state,
  speaker = DEFAULT_SPEAKER[tone],
  durationMs,
  className = ""
}: GameSubtitleFrameProps) {
  const timed = typeof durationMs === "number" && Number.isFinite(durationMs) && durationMs > 0;
  const style = timed
    ? ({ "--subtitle-duration": `${durationMs}ms` } as CSSProperties)
    : undefined;

  return (
    <p
      className={`game-subtitle-frame subtitle-tone-${tone} ${timed ? "is-timed" : "is-line-entering"} ${className}`.trim()}
      style={style}
    >
      <small className="game-subtitle-speaker">{speaker}</small>
      <span>{visibleSubtitleText(text, state)}</span>
    </p>
  );
}
