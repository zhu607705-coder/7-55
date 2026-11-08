import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export function changedProducts(paths) {
  let game = false;
  let platform = false;
  for (const file of paths) {
    if (['AGENTS.md', 'README.md', 'CONTRIBUTING.md', '.gitignore', '.github/workflows/product-scope.yml'].includes(file)
        || file.startsWith('.github/scripts/product-scope')
        || ['godot_native/web/player-account.js', 'godot_native/web/cloud-saves.js'].includes(file)) {
      game = platform = true;
    } else if (file.startsWith('platform/') || file === '.github/workflows/platform-ci.yml') {
      platform = true;
    } else {
      game = true;
    }
  }
  return { game, platform };
}

// Keep product ownership separate from retained React/Phaser validation. Unknown
// game paths stay conservative; only explicit native and documentation paths skip it.
const nativeWorkflows = new Set([
  '.github/workflows/godot-native-ci.yml',
  '.github/workflows/deploy-pages.yml',
  '.github/workflows/native-pr-integration.yml',
  '.github/workflows/native-source-ab.yml',
  '.github/workflows/native-source-measure.yml',
]);

// These native-owned files are also imported by retained-Web code or release tests.
// Audit any new cross-runtime dependency here instead of assuming directory isolation.
const retainedNativeDependencies = new Set([
  'godot_native/web/button.css', // src/components/Button.tsx
  'godot_native/tools/theater-review-route.mjs', // scripts/verify-theater-spotlight.mjs
]);

export function changedScopes(paths) {
  const products = changedProducts(paths);
  const retained_web = paths.some(file => {
    // Shared routing and root policies must exercise every affected validator.
    if (['AGENTS.md', 'README.md', 'CONTRIBUTING.md', '.gitignore', '.github/workflows/product-scope.yml'].includes(file)
        || file.startsWith('.github/scripts/product-scope')
        || retainedNativeDependencies.has(file)) return true;
    if (file.startsWith('platform/') || file === '.github/workflows/platform-ci.yml'
        || file.startsWith('godot_native/') || nativeWorkflows.has(file)
        || file.startsWith('docs/') || file.endsWith('.md')) return false;
    return true;
  });
  return { ...products, retained_web };
}

export function compareRange(eventName, event, triggerSha) {
  if (eventName === 'pull_request') {
    const base = event.pull_request?.base?.sha;
    // GITHUB_SHA is the synthetic merge actually tested by PR workflows. Comparing
    // the two branch tips would misclassify newer base-only changes as PR changes.
    if (!/^[a-f0-9]{40}$/.test(base ?? '') || !/^[a-f0-9]{40}$/.test(triggerSha ?? '')) return null;
    return { base, head: triggerSha };
  }
  if (eventName === 'push' && event.before && !/^0+$/.test(event.before)) return { base: event.before, head: event.after };
  return null; // Manual dispatch, new branches and missing PR SHAs run all scopes.
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
  const range = compareRange(process.env.GITHUB_EVENT_NAME, event, process.env.GITHUB_SHA);
  let result = { game: true, platform: true, retained_web: true };
  if (range) {
    for (const sha of [range.base, range.head]) {
      if (!/^[a-f0-9]{40}$/.test(sha)) throw new Error('Invalid event commit');
      // Fetch only commits/trees; source assets are not needed for path classification.
      execFileSync('git', ['fetch', '--no-tags', '--depth=1', '--filter=blob:none', 'origin', sha], { stdio: 'pipe' });
    }
    const names = execFileSync('git', ['diff', '--no-renames', '--name-only', '-z', range.base, range.head], {
      encoding: 'utf8', maxBuffer: 16 * 1024 * 1024
    }).split('\0').filter(Boolean);
    result = changedScopes(names);
  }
  for (const [product, changed] of Object.entries(result)) appendFileSync(process.env.GITHUB_OUTPUT, `${product}=${changed}\n`);
  console.log(JSON.stringify(result));
}
