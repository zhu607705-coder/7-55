import fs from "node:fs";

const errors = [];
let assertionCount = 0;

function assert(condition, message) {
  assertionCount += 1;
  if (!condition) errors.push(message);
}

function read(relativePath) {
  return fs.readFileSync(new URL(`../${relativePath}`, import.meta.url), "utf8");
}

const sharedDoor = read("src/scenes/rpg/RpgInteriorDoor.ts");
const dorm = read("src/scenes/rpg/DormHubScene.ts");
const dormModel = read("src/scenes/rpg/DormHubModel.ts");
const playerTextures = read("src/scenes/rpg/RpgPlayerTextures.ts");
const library = read("src/scenes/rpg/LibraryInteriorScene.ts");
const canteen = read("src/scenes/rpg/CanteenInteriorScene.ts");
const canteenModel = read("src/scenes/rpg/CanteenInteriorModel.ts");
const theater = read("src/scenes/rpg/TheaterInteriorScene.ts");
const debugContract = read("src/scenes/rpg/RpgRuntimeDebug.ts");

assert(sharedDoor.includes("export class RpgInteriorDoorRuntime"), "shared interior door runtime is missing");
assert(sharedDoor.includes("passableDelayMs"), "shared door does not expose the passable timing contract");
assert(!sharedDoor.includes("blockerY: number"), "shared animated door still requires an invisible blocker");
assert(!sharedDoor.includes("setBarrierEnabled"), "shared animated door still toggles an invisible collision barrier");
assert(!sharedDoor.includes("obstacles: Phaser.Physics.Arcade.StaticGroup"), "shared door constructor still accepts a collision group");
assert(sharedDoor.includes("updateRpgDoorForeground"), "shared door has no actor occlusion helper");
assert(sharedDoor.includes('motion: RpgInteriorDoorLeafMotion'), "shared door does not require an authored leaf motion");
assert(sharedDoor.includes('textureKey, "__BASE"'), "door foreground crops do not pin the source texture base frame");

assert(dorm.includes('id: "dorm_center_exit"'), "dorm centered exit is not registered");
assert(!dorm.includes("blockerY:"), "dorm shared animated exit still declares an invisible blocker");
assert(dorm.includes("this.exitDoor.open()"), "dorm exit does not animate open");
assert(dorm.includes("this.exitDoor.updateActorOcclusion(this.player)"), "dorm exit does not update actor occlusion");
assert(
  dorm.includes("configureRpgPlayerSprite(this.player)")
    && playerTextures.includes("export const RPG_PLAYER_DISPLAY_SCALE = 0.65;"),
  "dorm does not reuse the shared indoor player scale"
);
assert(
  dormModel.includes("export const DORM_HUB_ENVIRONMENT_SCALE = 0.5;")
    && dorm.includes(".setScale(DORM_HUB_ENVIRONMENT_SCALE)"),
  "dorm environment is not uniformly presented at half scale"
);
assert(
  dormModel.includes("DORM_SOURCE_STATIC_COLLISION_RECTS.map")
    && dormModel.includes("DORM_SOURCE_INTERACTION_TARGETS.map"),
  "dorm collision or interaction geometry does not follow the source-to-world transform"
);
assert(
  sharedDoor.includes("sourceCrop?:")
    && dorm.includes("displayScale: DORM_HUB_ENVIRONMENT_SCALE"),
  "dorm doorway foreground does not follow the scaled source crop"
);

assert(library.includes("private openEntranceDoor()"), "library entrance opening animation is missing");
assert(
  library.includes('LIBRARY_INTERIOR_MAP_KEY, "__BASE"'),
  "library background does not pin the base frame across same-scene developer restarts"
);
assert(library.includes("setEntranceBarrierEnabled(false)"), "library entrance does not become passable while opening");
assert(library.includes("createRpgDoorForeground"), "library entrance does not create a foreground occluder");
assert(library.includes("updateRpgDoorForeground"), "library entrance does not update actor occlusion");

assert(canteen.includes('id: "canteen_southeast_exit"'), "canteen player exit is not registered");
assert(!canteen.includes("doorObstacles"), "canteen shared animated exit still owns an invisible collision group");
assert(canteen.includes("private beginCanteenExit()"), "canteen exit does not use a physical door transition");
assert(canteen.includes("this.exitDoor.open()"), "canteen exit does not animate open");
assert(!canteen.includes("createCanteenExitButton"), "canteen still exposes a floating exit button");
assert(!canteen.includes('label = this.add.text(8, 0, "出门"'), "canteen floating exit label still exists");
assert(
  !canteenModel.includes('{ id: "southeast_wall_east", left: 1254, top: 760, right: 1643, bottom: 925 }'),
  "canteen static wall still fills the southeast doorway"
);
assert(
  canteenModel.includes('{ id: "southeast_exit_east_frame", left: 1450, top: 760, right: 1643, bottom: 925 }'),
  "canteen southeast door has no solid east frame"
);
assert(
  canteen.includes("create(): void {\n    this.resetRestartLifecycleState();"),
  "canteen does not clear retained Scene state before a restart"
);
assert(canteen.includes("this.entryPaperTriggered = false;"), "canteen restart keeps the old entry animation trigger");
assert(canteen.includes("this.paperBusy = false;"), "canteen restart keeps the old paper movement lock");
assert(canteen.includes("this.dialogueLocked = false;"), "canteen restart keeps the old dialogue lock");
assert(canteen.includes("this.exitTransitioning = false;"), "canteen restart keeps the old exit lock");
assert(
  !canteen.includes("entryPaperAutoStartTimer")
    && canteen.includes("<= ENTRY_PAPER_TRIGGER_RADIUS")
    && canteen.includes("this.startEntryPaperDiscovery();"),
  "canteen entry animation must remain bound to its authored proximity trigger"
);
assert(
  canteen.includes('this.input.off("pointerdown", handleScenePointer);')
    && canteen.includes("this.resetRestartLifecycleState();\n    });"),
  "canteen shutdown does not detach input and clear retained lifecycle state"
);
assert(canteen.includes("movementBlockers:"), "canteen debug state does not expose movement blockers");
assert(
  !canteen.includes("const vignette")
    && !canteen.includes("setStrokeStyle(70, 0x000000"),
  "canteen pickup cutscene still draws the dark perimeter frame"
);

assert(theater.includes('id: "theater_center_exit"'), "theater centered exit is not registered");
assert(!theater.includes("blockerY:"), "theater shared animated exit still declares an invisible blocker");
assert(theater.includes("private beginTheaterExit()"), "theater exit does not use a physical door transition");
assert(theater.includes("this.exitDoor.open()"), "theater exit does not animate open");
assert(theater.includes("this.exitDoor.updateActorOcclusion(this.player)"), "theater exit does not update actor occlusion");

[dorm, library, canteen, theater].forEach((scene, index) => {
  assert(scene.includes("interiorDoor:"), `scene ${index + 1} does not publish interior door debug state`);
});
assert(debugContract.includes("interiorDoor?:"), "runtime debug contract has no interior door snapshot");

if (errors.length > 0) {
  console.error(`RPG interior door verification failed (${errors.length}/${assertionCount}):`);
  errors.forEach((error) => console.error(`- ${error}`));
  process.exit(1);
}

console.log(`RPG interior door verification passed (${assertionCount} assertions).`);
