export type SnapshotWriteResult = "unchanged" | "saved" | "skipped" | "failed";

export interface JsonSnapshotWriterOptions<T extends object> {
  initial: T;
  initialPersisted?: boolean;
  write: (state: T) => boolean;
  canWrite?: () => boolean;
  serialize?: (state: T) => string;
}

/**
 * Synchronous persistence gate for immutable, JSON-serializable state.
 * Shallow structural sharing is the fast path; a JSON comparison preserves
 * value-level deduplication for newly allocated but equivalent state.
 * A failed/skipped write NEVER advances the last-successful fingerprint.
 * In-place nested mutation is unsupported, matching the store's immutable
 * updater contract. No timers, listeners, engine objects or global state.
 */
export function createJsonSnapshotWriter<T extends object>(
  options: JsonSnapshotWriterOptions<T>
): (state: T) => SnapshotWriteResult {
  const serialize = options.serialize ?? ((state: T) => JSON.stringify(state));
  let lastJson = serialize(options.initial);
  let lastFields: T = { ...options.initial };
  let hasPersisted = options.initialPersisted !== false;

  return (state: T): SnapshotWriteResult => {
    try {
      // Check first: developer sessions must not serialize or persist progress.
      if (options.canWrite && !options.canWrite()) return "skipped";
      const keys = Object.keys(state) as (keyof T)[];
      if (hasPersisted && keys.length === Object.keys(lastFields).length && keys.every((key) =>
        Object.prototype.hasOwnProperty.call(lastFields, key)
        && Object.is(state[key], lastFields[key])
      )) return "unchanged";

      const json = serialize(state);
      // Capture before calling the writer; the writer must not mutate state.
      const fields = { ...state };
      if (hasPersisted && json === lastJson) {
        lastFields = fields;
        return "unchanged";
      }
      if (!options.write(state)) return "failed";
      hasPersisted = true;
      lastJson = json;
      lastFields = fields;
      return "saved";
    } catch {
      // Storage failures must not interrupt game-state publication.
      return "failed";
    }
  };
}
