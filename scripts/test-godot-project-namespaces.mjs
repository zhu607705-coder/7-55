import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import { collectGodotProjectNamespaces, isExistingLocalGodotResource, appendTestsToGodotProject } from './godot-project-namespaces.mjs';

const temp = fs.mkdtempSync(path.join(os.tmpdir(), '755-project-namespaces-'));
let checks = 0;
const check = (condition, label) => { assert.ok(condition, label); checks++; };
try {
  const parent = path.join(temp, 'game');
  const child = path.join(parent, 'samples', 'study', 'preview');
  const grandchild = path.join(child, 'nested');
  function write(file, content = '') { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, content); }
  for (const root of [parent, child, grandchild]) write(path.join(root, 'project.godot'), 'config_version=5');
  write(path.join(parent, 'main.gd'), 'extends Node');
  write(path.join(parent, 'parent_only.gd'));
  write(path.join(parent, 'samples', 'study', '.gdignore'));
  write(path.join(child, 'local.gd'), 'extends Node');
  write(path.join(child, 'broken.gd'), 'extends Node\nconst missing = preload("res://parent_only.gd")');
  write(path.join(child, '.godot', 'cache.gd'));
  write(path.join(grandchild, 'third.gd'));
  const namespaces = collectGodotProjectNamespaces([parent, child]);
  check(namespaces.size === 3, 'nested roots discovered once, including below .gdignore');
  check(namespaces.get(parent).includes(path.join(parent, 'main.gd')), 'parent sources remain checked');
  check(!namespaces.get(parent).includes(path.join(child, 'local.gd')), 'child not resolved against parent');
  check(namespaces.get(child).includes(path.join(child, 'local.gd')), 'ignored preview is still checked in own namespace');
  check(namespaces.get(child).includes(path.join(child, 'broken.gd')), 'broken child source cannot disappear from checks');
  check(!namespaces.get(child).includes(path.join(grandchild, 'third.gd')), 'grandchild has own namespace');
  check(namespaces.get(grandchild).includes(path.join(grandchild, 'third.gd')), 'grandchild source remains checked');
  check(!namespaces.get(child).some(file => file.includes(`${path.sep}.godot${path.sep}`)), 'engine cache remains excluded');
  check(isExistingLocalGodotResource(child, 'res://local.gd'), 'child-local reference resolves');
  check(!isExistingLocalGodotResource(parent, 'res://local.gd'), 'missing parent resource fails');
  check(!isExistingLocalGodotResource(child, 'res://parent_only.gd'), 'negative: parent file cannot mask broken child reference');
  check(!isExistingLocalGodotResource(child, 'res://../../../../outside.gd'), 'namespace traversal remains rejected');
  check(!isExistingLocalGodotResource(child, 'user://save.json'), 'user data never treated as project resource');
  for (const reversed of [false, true]) {
    const suites = [['preview', ['test_preview.gd']], ['godot_native', ['test_story.gd']]];
    if (reversed) suites.reverse();
    appendTestsToGodotProject(suites, 'godot_native', ['test_discovered.gd']);
    check(suites.find(([root]) => root === 'godot_native')[1].includes('test_discovered.gd'), 'formal tests bind by identity regardless of suite order');
    check(suites.find(([root]) => root === 'preview')[1].join(',') === 'test_preview.gd', 'preview never inherits formal tests');
  }
  assert.throws(() => appendTestsToGodotProject([['preview', []]], 'godot_native', ['test.gd']), /exactly one/); checks++;
  assert.throws(() => appendTestsToGodotProject([['godot_native', []], ['godot_native', []]], 'godot_native', ['test.gd']), /exactly one/); checks++;
  console.log(`GODOT_PROJECT_NAMESPACES checks=${checks} failures=0`);
} finally { fs.rmSync(temp, { recursive: true, force: true }); }
