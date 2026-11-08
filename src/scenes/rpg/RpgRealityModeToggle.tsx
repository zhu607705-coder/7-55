import { Button } from "../../components/Button";
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
  return (
    <Button variant="ghost" data-layout="content"
      type="button"
      className={`rpg-canteen-mode-toggle rpg-reality-mode-toggle is-${mode} ${className}`.trim()}
      aria-pressed={mode === "dark"}
      aria-label={current.label}
      title={current.label}
      onClick={(event) => {
        onToggle();
        // Return keyboard control to the RPG surface. Otherwise Space activates
        // this focused button again instead of the nearby world interaction.
        event.currentTarget.blur();
      }}
    >
      <strong>{current.label}</strong>
    </Button>
  );
}
