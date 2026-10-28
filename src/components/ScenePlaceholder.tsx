import { Button } from "./Button";
import type { EventBus } from "../core/EventBus";
import type { SceneRouter } from "../core/SceneRouter";
import type { GameState, SceneId } from "../core/types";

export interface SceneComponentProps {
  state: GameState;
  router: SceneRouter;
  events: EventBus;
}

interface ScenePlaceholderProps extends SceneComponentProps {
  sceneId: SceneId;
  label: string;
  contract: string;
}

export function ScenePlaceholder({ sceneId, label, contract, router }: ScenePlaceholderProps) {
  return (
    <article className="scene-placeholder">
      <p className="scene-kicker">{sceneId}</p>
      <h1>{label}</h1>
      <p>{contract}</p>
      <Button variant="text" type="button" onClick={() => router.goTo("desktop")}>
        Back to desktop
      </Button>
    </article>
  );
}
