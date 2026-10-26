import fs from 'node:fs';
import path from 'node:path';

/** Keep every nested project, but resolve its resources against its own res:// root.
 * .gdignore is not an excuse to skip source verification: independent previews
 * are still visited. Only the engine-generated .godot cache stays excluded.
 */
export function collectGodotProjectNamespaces(projectRoots) {
  const projects = new Map();
  function scanProject(project) {
    project = path.resolve(project);
    if (projects.has(project)) return;
    const files = [];
    projects.set(project, files);
    function walk(directory) {
      for (const entry of fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
        if (entry.name === '.godot') continue;
        const file = path.join(directory, entry.name);
        if (entry.isDirectory()) {
          if (fs.existsSync(path.join(file, 'project.godot'))) scanProject(file);
          else walk(file);
        } else files.push(file);
      }
    }
    walk(project);
  }
  for (const root of projectRoots) scanProject(root);
  return projects;
}

export function isExistingLocalGodotResource(project, reference) {
  if (!reference.startsWith('res://')) return false;
  project = path.resolve(project);
  const target = path.resolve(project, reference.slice(6));
  return target.startsWith(project + path.sep) && fs.existsSync(target);
}

/** Runtime tests belong to a named project, never to a mutable array position. */
export function appendTestsToGodotProject(suites, project, tests) {
  const matches = suites.filter(([candidate]) => candidate === project);
  if (matches.length !== 1) throw new Error(`Expected exactly one test suite for ${project}`);
  matches[0][1].push(...tests);
}
