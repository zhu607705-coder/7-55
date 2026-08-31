import { readFile } from "node:fs/promises";

const componentSource = await readFile(
  new URL("../src/components/DeveloperChannel.tsx", import.meta.url),
  "utf8"
);
const checkpointSource = await readFile(
  new URL("../src/modules/DeveloperChannel.ts", import.meta.url),
  "utf8"
);
const rpgHostSource = await readFile(
  new URL("../src/scenes/rpg/RpgGameHost.tsx", import.meta.url),
  "utf8"
);

const failures = [];
let assertions = 0;
function assert(condition, message) {
  assertions += 1;
  if (!condition) failures.push(message);
}

const checkpointBlock = checkpointSource.slice(
  checkpointSource.indexOf("export const DEVELOPER_CHECKPOINTS"),
  checkpointSource.indexOf("const CHECKPOINT_IDS")
);
const checkpoints = [...checkpointBlock.matchAll(
  /\{\s*id:\s*"([^"]+)",\s*chapter:\s*"([^"]+)"/g
)].map((match) => ({ id: match[1], chapter: match[2] }));

const levelBlock = componentSource.slice(
  componentSource.indexOf("const DEVELOPER_LEVELS"),
  componentSource.indexOf("function getCheckpointLevel")
);
const levels = [...levelBlock.matchAll(
  /\{\s*id:\s*"([^"]+)",\s*chapter:\s*"([^"]+)",\s*label:\s*"([^"]+)",\s*checkpointIds:\s*\[([^\]]*)\]\s*\}/g
)].map((match) => ({
  id: match[1],
  chapter: match[2],
  label: match[3],
  checkpointIds: [...match[4].matchAll(/"([^"]+)"/g)].map((idMatch) => idMatch[1])
}));

const checkpointById = new Map(checkpoints.map((checkpoint) => [checkpoint.id, checkpoint]));
const assignments = new Map();
for (const level of levels) {
  assert(level.label.trim().length > 0, `${level.id} must have a visible label`);
  assert(level.checkpointIds.length > 0, `${level.id} must own at least one checkpoint`);
  for (const checkpointId of level.checkpointIds) {
    const checkpoint = checkpointById.get(checkpointId);
    assert(Boolean(checkpoint), `${level.id} references unknown checkpoint ${checkpointId}`);
    assert(
      checkpoint?.chapter === level.chapter,
      `${checkpointId} chapter mismatch: checkpoint=${checkpoint?.chapter} level=${level.chapter}`
    );
    assignments.set(checkpointId, (assignments.get(checkpointId) ?? 0) + 1);
  }
}

for (const checkpoint of checkpoints) {
  assert(assignments.get(checkpoint.id) === 1, `${checkpoint.id} must belong to exactly one level`);
}
for (const checkpointId of assignments.keys()) {
  assert(checkpointById.has(checkpointId), `level assignment contains extra checkpoint ${checkpointId}`);
}

const levelIds = levels.map((level) => level.id);
assert(new Set(levelIds).size === levelIds.length, "level ids must be unique");
assert(levels.length === 24, `expected 24 levels, received ${levels.length}`);
assert(checkpoints.length === 115, `expected 115 checkpoints, received ${checkpoints.length}`);

const expectedChapterLevelCounts = {
  "第一章": 2,
  "第二章": 6,
  "第三章": 6,
  "3.5章": 2,
  "第四章": 8
};
for (const [chapter, expectedCount] of Object.entries(expectedChapterLevelCounts)) {
  assert(
    levels.filter((level) => level.chapter === chapter).length === expectedCount,
    `${chapter} must expose ${expectedCount} levels`
  );
}

assert(componentSource.includes("章节与关卡直达"), "DEV header must name the chapter/level hierarchy");
assert(componentSource.includes('aria-label="选择章节"'), "chapter navigation must retain an accessible label");
assert(componentSource.includes('aria-label="选择关卡"'), "level navigation must expose an accessible label");
assert(componentSource.includes("data-dev-level={level.id}"), "level buttons must expose stable selectors");
assert(componentSource.includes("data-dev-checkpoint={item.id}"), "checkpoint buttons must retain stable selectors");
assert(
  checkpointSource.includes('const beforeEntryPaperEscape = ["canteen-hunt", "c3-canteen-entry"].includes(id);')
    && checkpointSource.includes("entryPaperEscaped: !beforeEntryPaperEscape"),
  "canteen tracking and entry checkpoints must preserve the first-entry paper animation"
);
assert(
  rpgHostSource.includes("developerCheckpointInputRestoreSerialRef")
    && rpgHostSource.includes("restoreDeveloperCheckpointInput(12)")
    && rpgHostSource.includes("if (inputBlockedRef.current)"),
  "DEV checkpoint restart must retry input recovery until the overlay state has committed"
);
assert(
  rpgHostSource.includes("syncActivatedSceneInput")
    && rpgHostSource.includes("A stopped Phaser Scene retains its KeyboardPlugin.enabled value")
    && rpgHostSource.includes("const frame = window.requestAnimationFrame(syncActivatedSceneInput);"),
  "a Scene activated after DEV closes must inherit the current host input state"
);

if (failures.length > 0) {
  console.error(`Developer level validation FAIL assertions=${assertions}`);
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(
  `Developer level validation PASS assertions=${assertions} chapters=5 levels=${levels.length} checkpoints=${checkpoints.length} coverage=exactly-once`
);
