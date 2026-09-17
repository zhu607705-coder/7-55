# State write policy review (2026-09-17)

Base: `39ccde029b0cd25a6011739a4e4f98f8c898b2c3`.

The old subscription serializes all of GameState before checking the developer
session. It advances lastSnapshot before SaveStore.save returns. Since save
returns false on storage failure, the same state cannot be retried on a later
notification. Hydration's normalization write can fail for the same reason.

`core/state/JsonSnapshotWriter.ts` owns the synchronous write policy. It checks
permission first, uses shallow structural sharing for immutable no-op updates,
retains JSON value comparison for equivalent allocations, and advances its cache
only after a successful write. Failed and skipped attempts do not count as
saved. Hydration failure explicitly requests a retry on the next notification.
No automatic background retry, debounce, save schema change, dropped UI fields,
or changed domain transaction ordering is introduced. SaveStore still owns
version 35 migration, normalization, backup and storage I/O.

The shallow fast path requires immutable nested updates. In-place mutation is
unsupported. Keep controller updates immutable and retain the release regression
suite before merging. This change does not optimize JSON work on every genuine
state change, backup validation, scene rendering, or the initial asset payload.

## Evidence and limits

Dynamic tests: nine cases pass, including 100,000 no-op updates, deep-equal
allocations, false/throw storage failures and identical-state retries,
developer-session isolation, added/removed keys, serialization failure, failed
hydration, and 2,000 synchronously ordered progress writes.

Synthetic 20,000 no-op benchmark: full serialization count changes from 20,000
to one initial serialization. One local run measured 358.99 ms vs 2.10 ms on a
256-entry synthetic history object. These are microbenchmark observations, not
full-game speedups or FPS measurements. Timing is deliberately not a CI gate.

Chromium executed the actual transpiled helper in an isolated document at
1280x720, 1024x768 and 390x844: each ran 100,000 no-op updates, retry/skip checks
and 200 synchronous writes to a test sink. No page/console errors or horizontal
overflow were observed; screenshots were inspected. Browser policy blocked HTTP
navigation, so actual localStorage reload and full-game rendering were NOT
verified. This harness is not a Godot or gameplay visual test.

After dynamic checks: strict TypeScript checking of the helper passed. Reversing
only the intended import/subscription diff reconstructs the original GameState
blob SHA `cf9d625717942ac60f8cfa51c7385f9d30edc3b7`, confirming byte-identical
initial state and untouched surrounding logic. Full repository checks belong to
existing Web CI; they were not runnable locally without the complete checkout.

Run: `node scripts/verify-state-write-policy.mjs` after `npm ci`.
