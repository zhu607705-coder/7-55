import type { EventBus } from "../../core/EventBus";
import type { SceneRouter } from "../../core/SceneRouter";
import type {
  GameEvent,
  GameState,
  GameStore,
  RpgCheckpointId,
  RpgSceneId,
  SceneId
} from "../../core/types";

export interface RpgBridge {
  getState: () => GameState;
  goToPhoneScene: (sceneId: SceneId) => void;
  setCheckpoint: (checkpoint: RpgCheckpointId) => void;
  setRpgLocation: (scene: RpgSceneId, checkpoint: RpgCheckpointId) => void;
  emit: (name: GameEvent["name"], payload?: GameEvent["payload"]) => void;
  subscribe: (listener: (event: GameEvent) => void) => () => void;
}

export function createRpgBridge(store: GameStore, router: SceneRouter, events: EventBus): RpgBridge {
  return {
    getState: store.getState,
    goToPhoneScene: (sceneId) => {
      store.setState((state) => ({ ...state, runtimeMode: "phone" }));
      router.goTo(sceneId);
    },
    setCheckpoint: (checkpoint) => {
      const previous = store.getState().rpgCheckpoint;
      if (previous === checkpoint) {
        return;
      }
      store.setState((state) => ({ ...state, rpgCheckpoint: checkpoint }));
      events.emit("rpg_checkpoint_changed", { checkpoint, previous });
    },
    setRpgLocation: (scene, checkpoint) => {
      const state = store.getState();
      if (state.rpgScene === scene && state.rpgCheckpoint === checkpoint) {
        return;
      }
      store.setState((current) => ({ ...current, rpgScene: scene, rpgCheckpoint: checkpoint }));
      events.emit("rpg_location_changed", { scene, checkpoint });
    },
    emit: (name, payload) => events.emit(name, payload),
    subscribe: (listener) => events.subscribe(listener)
  };
}
