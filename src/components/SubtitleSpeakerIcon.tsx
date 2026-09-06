const ICON_PATHS = {
  system: "M4 3h8v10H4z M2 1h2v3H2z M6 0h1v3H6z M9 0h1v3H9z M12 1h2v3h-2z M0 5h3v1H0z M0 9h3v1H0z M13 5h3v1h-3z M13 9h3v1h-3z M5 14h1v2H5z M10 14h1v2h-1z",
  player: "M6 1h4v1h2v5h-2v2H6V7H4V2h2z M4 10h8v2h2v3H2v-3h2z",
  narrator: "M1 2h6v6H4v3H1V7h1V5H1z M9 2h6v6h-3v3H9V7h1V5H9z",
  xiaoying: "M7 0h2v4h2v2h4v2h-4v2H9v5H7v-5H5V8H1V6h4V4h2z M13 12h2v2h-2z",
  seat: "M4 1h8v7H4z M2 7h2v4h8V7h2v6H2z M3 13h2v3H3z M11 13h2v3h-2z",
  paper: "M3 1h7v4h4v10H3z M11 1h1v1h1v1h1v1h-3z",
  bag: "M5 1h6v3h2v2h1v9H2V6h1V4h2z M6 2v2h4V2z",
  book: "M1 2h5v1h1v11H6v-1H1z M10 2h5v11h-5v1H9V3h1z",
  desk: "M1 8h14v3h-1v4h-2v-4H4v4H2v-4H1z M5 1h6v5H5z M4 6h8v1H4z",
  badge: "M4 1h8v2h2v11H2V3h2z M6 0h4v4H6z",
  guard: "M5 1h6v1h2v2H3V2h2z M2 5h12v2H2z M5 8h6v4H5z M3 13h10v3H3z",
  teacher: "M1 1h14v9H1z M3 3v5h10V3z M7 10h2v2h3v2H4v-2h3z",
  sport: "M7 1h5v1h2v2h1v5h-2v2H8V9H6V4h1z M5 9h2v2H5z M3 11h2v2H3z M1 13h2v2H1z",
  baker: "M2 4h1V2h3V1h4v1h3v2h1v8H2z M3 13h10v2H3z",
  cleaner: "M11 0h2v5h-2v3H9v2H7v-2h2V5h2z M4 9h3v2h2v2H7v2H1v-4h3z",
  projection: "M3 1h10v2H3z M4 4h8v2h-2v4h2v3H4v-3h2V6H4z M3 14h10v2H3z",
  task: "M4 1h8v2h2v12H2V3h2z M6 0h4v4H6z",
  error: "M7 1h2v8H7z M7 12h2v3H7z",
  broadcast: "M1 6h4l5-4h2v12h-2l-5-4H1z M4 11h2v4H4z M14 5h2v6h-2z",
  clock: "M4 1h8v2h2v2h1v6h-2v2h-2v2H5v-2H3v-2H1V5h2V3h1z"
} as const;

type IconId = keyof typeof ICON_PATHS;
const SPEAKER_ICONS: Readonly<Record<string, IconId>> = {
  系统: "system", system: "system", 我: "player", 玩家: "player", player: "player",
  旁白: "narrator", narrator: "narrator", 小影: "xiaoying", xiaoying: "xiaoying",
  "022": "seat", 纸条: "paper", paper: "paper", 书包: "bag",
  图书馆提示: "book", 前台: "desk", 值班助理: "badge", 安全员: "guard", guard: "guard",
  教师: "teacher", 体艺: "sport", 面包师: "baker", baker: "baker",
  清洁工: "cleaner", cleaner: "cleaner", 投影: "projection", projection: "projection",
  任务: "task", 记录: "book", 提示: "error", 广播: "broadcast", 地点: "desk",
  剧情: "narrator", "07:55": "clock"
};

/** Authored 16×16 silhouettes; unknown names receive stable, distinct pixel portraits. */
export function SubtitleSpeakerIcon({ speaker }: { speaker: string }) {
  const iconId = SPEAKER_ICONS[speaker];
  let signature = 2166136261;
  for (const character of speaker) signature = Math.imul(signature ^ character.charCodeAt(0), 16777619);
  const fallbackPixels = Array.from({ length: 15 }, (_, index) => {
    if (!((signature >>> index) & 1)) return null;
    const x = index % 3;
    const y = Math.floor(index / 3);
    return <path key={index} d={`M${3 + x * 2} ${3 + y * 2}h2v2h-2z M${11 - x * 2} ${3 + y * 2}h2v2h-2z`} />;
  });

  return (
    <span className="game-subtitle-avatar" data-speaker-icon={iconId ?? `speaker-${signature >>> 0}`} aria-hidden="true">
      <svg viewBox="0 0 16 16" fill="currentColor" shapeRendering="crispEdges" focusable="false">
        {iconId ? <path d={ICON_PATHS[iconId]} fillRule="evenodd" /> : fallbackPixels}
        {iconId === "system" ? <path d="M6 5h4v6H6z" fill="var(--subtitle-avatar-cutout)" /> : null}
        {iconId === "paper" || iconId === "task" || iconId === "badge" ? <path d="M5 7h6v1H5z M5 10h5v1H5z" fill="var(--subtitle-avatar-cutout)" /> : null}
        {iconId === "clock" ? <path d="M7 4h2v4h3v2H7z" fill="var(--subtitle-avatar-cutout)" /> : null}
      </svg>
    </span>
  );
}
