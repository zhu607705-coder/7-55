import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { normalizePath, type Plugin } from 'vite';

/** Preserve authored source imports while shipping byte-verified lossless maps. */
export function losslessRuntimeAssets(root: string, inline: boolean): Plugin {
  const manifestPath = path.join(root, 'src/assets/rpg/optimized/manifest.json');
  const assets = new Map<string, {file:string; sourceSha256:string; sha256:string}>();
  const hash = (data: Buffer) => createHash('sha256').update(data).digest('hex');
  return {
    name: 'lossless-runtime-assets',
    apply: 'build',
    enforce: 'pre',
    buildStart() {
      assets.clear();
      this.addWatchFile(manifestPath);
      const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
      for (const asset of manifest.assets) assets.set(normalizePath(path.resolve(root, asset.source)), asset);
    },
    load(id) {
      const [sourcePath, query] = id.split('?');
      if (query && query !== 'url') return null;
      const asset = assets.get(sourcePath);
      if (!asset) return null;
      const file = path.resolve(root, asset.file);
      this.addWatchFile(sourcePath);
      this.addWatchFile(file);
      const source = readFileSync(file);
      if (hash(readFileSync(sourcePath)) !== asset.sourceSha256 || hash(source) !== asset.sha256) {
        this.error(`Stale lossless map: ${sourcePath}. Run node scripts/build-lossless-runtime-maps.mjs.`);
      }
      if (inline) return `export default ${JSON.stringify(`data:image/webp;base64,${source.toString('base64')}`)};`;
      const reference = this.emitFile({type:'asset', name:path.basename(file), source});
      return `export default import.meta.ROLLUP_FILE_URL_${reference};`;
    }
  };
}
