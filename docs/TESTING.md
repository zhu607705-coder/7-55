# Testing Strategy

The repository uses executable contract validators rather than a conventional Jest or Vitest suite. Assertion counts from these scripts are diagnostic output only. They do not represent line, branch, or user-journey coverage.

## Blocking validation layers

Every pull request and every non-documentation push to `main` runs three distinct layers.

### Critical gameplay behavior

```bash
node scripts/run-test-suite.mjs critical
```

This suite executes production TypeScript through Vite SSR or esbuild and checks observable state transitions, rejected actions, idempotency, save/reload behavior, migration behavior, order independence, cancellation, retry, and failure recovery.

| Surface | Blocking behavior evidence |
| --- | --- |
| Chapter 2 | CC98 identity gate, bounded lockout, task handoff, save migration |
| Chapter 3 | Theater spotlight timing, Qizhen rain safety, fishing rhythm engine |
| Chapter 3.5 | All parallel evidence orders, invalid attempts, persistence normalization |
| Cross-chapter RPG | Light/dark operation order and truthful save semantics |
| Chapter 4 | Warmup readiness and recovery, guard presentation isolation, optional effective interactions |

### Repository contracts

The existing map, media, asset, topology, story, runtime, interaction, type-check, and artifact validators remain blocking. These protect authored datasets and deployment contracts. Source-text searches, exact counts, hashes, and file-shape checks belong to this layer and must not be described as gameplay coverage.

### Browser smoke

After the production bundle is built, `scripts/verify-browser-smoke.mjs` launches the checked-in build through Vite preview and system Chromium. It checks:

- mobile phone boot at `390 × 844`;
- the Chapter 3 theater RPG checkpoint at `1440 × 900`;
- the Chapter 4 opening RPG checkpoint at `1440 × 900`;
- React replacement of the loading fallback;
- RPG canvas creation;
- valid, non-trivial screenshots with the requested dimensions;
- distinct screenshots for distinct checkpoints.

The browser smoke proves production-bundle startup and routing in Chromium. It does not establish full playthrough correctness, pixel-level visual equivalence, audio audibility, or Firefox and WebKit compatibility.

## Extended authoring audit

The manual `workflow_dispatch` run additionally executes:

```bash
node scripts/run-test-suite.mjs extended
```

This suite checks generated text freshness, task-guidance ownership, developer checkpoint assignment, canteen transition evidence, Qizhen journal authoring, and Chapter 4 stair-material integrity. These checks are valuable during content and release audits. Running them manually avoids turning every implementation refactor into a source-shape maintenance event.

## Test-case design rules

A blocking behavior test should identify one product risk and include the relevant combinations of:

1. valid progression;
2. invalid or locked input with zero unintended writes;
3. repeated execution and idempotency;
4. save and reload;
5. legacy migration when stored formats are involved;
6. alternate action order when the design permits it;
7. cancellation, retry, or recovery for lifecycle-sensitive behavior.

Prefer exported models and controllers over source-code regular expressions. Use source scans only for repository policies that cannot be observed through runtime behavior. Avoid fixed assertion totals as a success criterion unless the exact cardinality is itself a published contract.

## Remaining gaps

The current suite still lacks an automated start-to-finish playthrough, pointer and keyboard input replay inside Phaser, collision replay against rendered worlds, audio playback verification, visual-diff baselines, and automated Firefox/WebKit runs. Those require a dedicated end-to-end harness and should be introduced as a release-grade suite with explicit runtime and artifact budgets.
