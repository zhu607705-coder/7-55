import { execFileSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export function changedProducts(paths) {
  let game = false;
  let platform = false;
  for (const file of paths) {
    if (['AGENTS.md', 'README.md', 'CONTRIBUTING.md', '.gitignore', '.github/workflows/product-scope.yml'].includes(file)
        || file.startsWith('.github/scripts/product-scope')) {
      game = platform = true;
    } else if (file.startsWith('platform/') || file === '.github/workflows/platform-ci.yml') {
      platform = true;
    } else {
      game = true;
    }
  }
  return { game, platform };
}

export function compareRange(eventName, event) {
  if (eventName === 'pull_request') return { base: event.pull_request.base.sha, head: event.pull_request.head.sha };
  if (eventName === 'push' && event.before && !/^0+$/.test(event.before)) return { base: event.before, head: event.after };
  return null; // Manual dispatch and new branches run both products.
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
  const range = compareRange(process.env.GITHUB_EVENT_NAME, event);
  let result = { game: true, platform: true };
  if (range) {
    for (const sha of [range.base, range.head]) {
      if (!/^[a-f0-9]{40}$/.test(sha)) throw new Error('Invalid event commit');
      // Fetch only commits/trees; source assets are not needed for path classification.
      execFileSync('git', ['fetch', '--no-tags', '--depth=1', '--filter=blob:none', 'origin', sha], { stdio: 'pipe' });
    }
    const names = execFileSync('git', ['diff', '--no-renames', '--name-only', '-z', range.base, range.head], {
      encoding: 'utf8', maxBuffer: 16 * 1024 * 1024
    }).split('\0').filter(Boolean);
    result = changedProducts(names);
  }
  for (const [product, changed] of Object.entries(result)) appendFileSync(process.env.GITHUB_OUTPUT, `${product}=${changed}\n`);
  console.log(JSON.stringify(result));
}
