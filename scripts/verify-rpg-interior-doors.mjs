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
const library = read("src/scenes/rpg/LibraryInteriorScene.ts");
const canteen = read("src/scenes/rpg/CanteenInteriorScene.ts");
const canteenModel = read("src/scenes/rpg/CanteenInteriorModel.ts");
const theater = read("src/scenes/rpg/TheaterInteriorScene.ts");
const debugContract = read("src/scenes/rpg/RpgRuntimeDebug.ts");

assert(sharedDoor.includes("export class RpgInteriorDoorRuntime"), "shared interior door runtime is missing");
assert(sharedDoor.includes("passableDelayMs"), "shared door does not expose the passable timing contract");
assert(sharedDoor.includes("setBarrierEnabled(false)"), "shared door never disables its blocker while opening");
assert(sharedDoor.includes("updateRpgDoorForeground"), "shared door has no actor occlusion helper");
assert(sharedDoor.includes('motion: RpgInteriorDoorLeafMotion'), "shared door does not require an authored leaf motion");

assert(dorm.includes('id: "dorm_center_exit"'), "dorm centered exit is not registered");
assert(dorm.includes("this.exitDoor.open()"), "dorm exit does not animate open");
assert(dorm.includes("this.exitDoor.updateActorOcclusion(this.player)"), "dorm exit does not update actor occlusion");

assert(library.includes("private openEntranceDoor()"), "library entrance opening animation is missing");
assert(library.includes("setEntranceBarrierEnabled(false)"), "library entrance does not become passable while opening");
assert(library.includes("createRpgDoorForeground"), "library entrance does not create a foreground occluder");
assert(library.includes("updateRpgDoorForeground"), "library entrance does not update actor occlusion");

assert(canteen.includes('id: "canteen_southeast_exit"'), "canteen player exit is not registered");
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

assert(theater.includes('id: "theater_center_exit"'), "theater centered exit is not registered");
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
