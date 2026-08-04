import {
  RPG_REALITY_MODE_CONTRACT,
  type RpgRealityMode
} from "./RpgInteractionContract";

interface RpgRealityModeToggleProps {
  mode: RpgRealityMode;
  onToggle: () => void;
  className?: string;
}

export function RpgRealityModeToggle({
  mode,
  onToggle,
  className = ""
}: RpgRealityModeToggleProps) {
  const current = RPG_REALITY_MODE_CONTRACT[mode];
  const nextMode: RpgRealityMode = mode === "dark" ? "light" : "dark";
  const next = RPG_REALITY_MODE_CONTRACT[nextMode];
  return (
    <button
      type="button"
      className={`rpg-canteen-mode-toggle rpg-reality-mode-toggle is-${mode} ${className}`.trim()}
      aria-pressed={mode === "dark"}
      aria-label={`当前${current.label}。点击切换到${next.label}`}
      title={`${current.shortHint} 点击切换到${next.label}。`}
      onClick={(event) => {
        onToggle();
        // Return keyboard control to the RPG surface. Otherwise Space activates
        // this focused button again instead of the nearby world interaction.
        event.currentTarget.blur();
      }}
    >
      <span>当前模式</span>
      <strong>{current.label}</strong>
      <small>切换：{next.label}</small>
    </button>
  );
}
