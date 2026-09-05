// Share already decoded source images with Phaser; no second texture or save owner.
// This pool is short-lived and bounded independently of the engine's active textures.
const MAX_AGE_MS = 60_000;
const images = new Map<string, { image: HTMLImageElement; bytes: number; expires: number }>();
let totalBytes = 0;
let cleanupTimer: ReturnType<typeof setTimeout> | undefined;

function budgetBytes(): number {
  const memory = typeof navigator === "undefined" ? undefined
    : (navigator as Navigator & { deviceMemory?: number }).deviceMemory;
  return (memory && memory <= 4 ? 16 : 64) * 1024 * 1024;
}

function remove(url: string): void {
  const entry = images.get(url);
  if (!entry) return;
  totalBytes -= entry.bytes;
  images.delete(url);
}

function prune(): void {
  const now = Date.now();
  for (const [url, entry] of images) if (entry.expires <= now) remove(url);
}

function scheduleCleanup(): void {
  if (cleanupTimer !== undefined) clearTimeout(cleanupTimer);
  cleanupTimer = undefined;
  if (!images.size) return;
  const expiry = Math.min(...[...images.values()].map(entry => entry.expires));
  cleanupTimer = setTimeout(() => { prune(); scheduleCleanup(); }, Math.max(1, expiry - Date.now()));
}

export function clearRpgDecodedImages(): void {
  images.clear();
  totalBytes = 0;
  if (cleanupTimer !== undefined) clearTimeout(cleanupTimer);
  cleanupTimer = undefined;
}

export function retainRpgDecodedImage(url: string, image: HTMLImageElement): void {
  if (!image.complete || image.naturalWidth <= 0 || image.naturalHeight <= 0) return;
  if (typeof document !== "undefined" && document.hidden) return;
  const bytes = image.naturalWidth * image.naturalHeight * 4;
  const budget = budgetBytes();
  if (bytes > budget) return;
  prune();
  remove(url);
  while (totalBytes + bytes > budget && images.size) remove(images.keys().next().value!);
  images.set(url, { image, bytes, expires: Date.now() + MAX_AGE_MS });
  totalBytes += bytes;
  scheduleCleanup();
}

export function getRpgDecodedImage(url: string): HTMLImageElement | undefined {
  prune();
  const entry = images.get(url);
  if (!entry) return undefined;
  // Refresh LRU order and expiry when the player actually uses the image.
  images.delete(url);
  images.set(url, { ...entry, expires: Date.now() + MAX_AGE_MS });
  scheduleCleanup();
  return entry.image;
}

export function getRpgDecodedImageCacheSnapshot() {
  prune();
  return { count: images.size, bytes: totalBytes, budgetBytes: budgetBytes(), maxAgeMs: MAX_AGE_MS };
}

if (typeof document !== "undefined") {
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) clearRpgDecodedImages();
  });
}
