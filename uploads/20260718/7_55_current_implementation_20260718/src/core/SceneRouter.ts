import type { EventBus } from "./EventBus";
import type { GameStore, SceneId } from "./types";
import { canEnterScene } from "./FeatureAccess";

export class SceneRouter {
  private readonly history: SceneId[] = [];

  constructor(
    private readonly store: GameStore,
    private readonly events: EventBus
  ) {}

  goTo(sceneId: SceneId): boolean {
    if (!canEnterScene(this.store.getState(), sceneId)) {
      this.events.emit("feature_access_denied", { sceneId });
      return false;
    }
    const previousScene = this.store.getState().currentScene;
    this.history.push(previousScene);
    this.store.setState((state) => ({ ...state, currentScene: sceneId }));
    this.events.emit("enter_scene", { sceneId });
    return true;
  }

  back(): void {
    const previousScene = this.history.pop();
    if (previousScene) {
      this.goTo(previousScene);
    }
  }

  reload(): void {
    this.events.emit("enter_scene", { sceneId: this.getCurrentScene() });
  }

  getCurrentScene(): SceneId {
    return this.store.getState().currentScene;
  }
}
