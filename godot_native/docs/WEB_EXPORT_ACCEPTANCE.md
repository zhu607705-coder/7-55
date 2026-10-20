# Independent Godot Web acceptance

`tools/verify_web_export.mjs` accepts a served Godot export. It does not build or
test the retained React/Phaser browser runtime. It requires Node 22 or later and
an installed Chrome/Chromium binary; no additional npm package is required.

Serve the export directory with a static HTTP server that sends `.wasm` as
`application/wasm`. Run from the repository root:

```sh
node godot_native/tools/verify_web_export.mjs \
  --url http://127.0.0.1:5209/7-55/ \
  --export-dir godot_native/exports/web-release-accepted \
  --chrome /path/to/chrome \
  --output godot_native/exports/verification/web-acceptance
```

The default CI scope uses separate disposable browser profiles at `1280×720`,
`1440×900`, and touch `390×844`. It exercises the real engine loader and entry,
alarm/start/wake/phone buttons, selected reality mode, native persistence across
actual page reload, portable JSON download and ordinary file-picker re-import,
malformed-file rejection without changing progress, and native PNG screenshot
download. The non-16:9 case also supplies historical developer URL arguments and
must still open the fresh production alarm. It checks the real WebGL 2 context,
read-only snapshot boundary, developer controls, document/canvas bounds, browser
errors, and actual `.wasm` and `.pck` network loads. It independently downloads
and hashes observed engine/core/deferred files, comparing their full relative
paths and bytes with `--export-dir` when set.
`web-acceptance.json` records the runner hash, export manifest, renderer, cold
startup timings, input cases, failures, screenshots, asset hashes and limitations.

## Persistence correction under acceptance

The Linux CI candidate at commit
`95f21403aeeac346b94bb862fb08aedc0fe0e5b9` failed the real touch
`390×844` reload case. Its in-memory state and MEMFS save were dark, while an
independent read of the IndexedDB primary save still contained light mode;
the new document restored that older mode. This was a persistence failure, not
an accepted timing variation. That candidate was not published. Passing desktop
cases and earlier local checks do not supersede this negative evidence.

In pinned Godot 4.7.2,
[OS_Web schedules filesystem synchronization asynchronously](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp#L70-L85),
and [GodotFS completes through an asynchronous IDBFS callback](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/library_godot_os.js#L178-L192).
An available persistent filesystem, a successful native file close, the MEMFS
`saveDigest`, or an older sync Promise is not an exact receipt for the latest
save. Earlier 350 ms and 1.6 s probes remain historical observations; neither
interval establishes a durable-write contract.

The replacement protocol is implemented and undergoing acceptance; it is not
yet a passing or deployed result. `State` save logic and signals are unchanged:
it remains the sole save writer and validator. Both manual entry points call
`request_save`, which invokes the original `State.save_game()` and then requests
filesystem synchronization. Existing snapshot publication observes changed
MEMFS digests for automatic saves; it does not create another write authority.

The private Web watcher only reads the `/userfs` `FILE_DATA` primary file and
returns its actual bytes. GDScript computes the complete byte SHA-256, matches
the current digest and request token, and only then acknowledges that request.
This also works without browser WebCrypto. The adapter does not write IndexedDB,
seed state, change save format, or commit story progress. A stale acknowledgement
cannot certify a newer request. The clicked button shows pending immediately,
disables duplicate clicks, and shows saved only after its acknowledgement;
queued story toasts are not the success oracle. A 20-second timeout or read
failure leaves an explicit retry/export path and an uncommitted-write warning.
Disposal cancels watcher timers, callbacks and the pending `beforeunload` warning;
that browser warning is best effort, not a guarantee after forced termination.

The runner revision must observe the real successful save state and separately
read IndexedDB to require the exact requested digest before issuing the same
ordinary document reload. Original route, selected-mode, story-flag and input
assertions remain in place. Failure diagnostics retain memory digest/state and
the primary/backup persistence observations. Do not replace this boundary with
a longer fixed sleep, relaxed state comparisons or a JavaScript write to the
store. Actual timeout, stale-token and blocked-storage controls require their
own evidence before this section can be marked accepted.

Linux CI without a GPU may explicitly select its isolated software renderer:

```sh
node godot_native/tools/verify_web_export.mjs \
  --url http://127.0.0.1:5208/7-55/ \
  --export-dir godot_native/exports/web-release \
  --chrome /usr/bin/google-chrome \
  --chrome-arg=--use-angle=swiftshader \
  --chrome-arg=--enable-unsafe-swiftshader \
  --output godot_native/exports/verification/web-ci
```

These arguments apply only to the disposable test browser. The product does not
ask users to change browser security settings. The runner never uses the user's
Chrome profile and terminates its browser and removes the profile on completion.

For deeper release acceptance, pass `--fixtures /absolute/path/to/earned` with
portable native saves from `tests/campaign_continuity_recorder.gd`. Required files
are `after_c1_checkin.json`, `after_c2_dorm_exit.json`,
`after_c3_defense_result.json`, `after_c3_enter_theater.json`,
`after_c3_target_theater_exit.json`, `action_c4_prologue_end.json`, and
`after_c35_replay.json`, plus `before_c3_chase_result.json` for the 3D ride. The runner imports them through the ordinary shipped file
picker, never a chapter route, mutable snapshot, controller call or QA action.

This extended scope tests C1's real-time stationary failure, same-stage continue,
clue-review pause, six target-word contacts, all three semantic stages, interrupted
and successful keyboard hold, authored dialogue/whiteout, C2 handoff and reload.
It separately exercises real scaled touch drag and cancellation. It also accepts
C2 keyboard world movement, C3 escape/theater/lake narrative handoffs, C4 A1 entry,
and each completed handoff's persistence. The recovered-timeline case verifies
actual OGV and audio playhead growth, real hidden-tab pause/resume, ordinary
Return/re-entry, and the explicit task acknowledgement before C4 progression.
`--scenarios media --only desktop-1280` narrows an extended diagnostic run to
basic/file acceptance plus that earned media sequence; it does not alter the game.

The 3D ride case imports the earned paid-but-unfinished chase and enters it by
ordinary reload. It requires a real presented `SourceChase3D` SubViewport with
source meshes, then uses actual steering and hold/release jump input. It checks
that visibility restoration preserves a player-owned pause, and that Exit and
native save/reload retain inventory, wallet and the unfinished ride. It does not
claim to complete the full 755 metres. `--scenarios bike --only desktop-1280`
isolates this GPU diagnostic while retaining the basic/file checks.

For split-delivery fault acceptance, use `--scenarios streaming --only
desktop-1280 --fixtures /absolute/path/to/earned`. The runner blocks only the
manifest's exact deferred URLs, leaving engine/core requests available. It
accepts ordinary first-chapter phone input and save/reload, imports the earned
C2 save through the shipped picker, requires a visible Retry control and stable
State/save bytes, then restores HTTP and clicks Retry. Every C2 block must mount
before the real campus map and keyboard movement resume. After actual
CacheStorage writes, another real reload with all deferred HTTP blocked must
restore C2 with zero C2 network requests. This scope does not claim an entire
offline four-chapter campaign.

Injected `Network.setBlockedURLs` failures are recorded separately only when
their request URL exactly matches the current manifest block set and CDP reports
`blockedReason: inspector` with empty or `ERR_BLOCKED_BY_CLIENT` text. Other page,
script and network errors remain fatal. Boot evidence records zero deferred
requests before the user starts; nested pack HTTP hashes retain `content/` in
their local artifact paths. `--self-test-paths` checks that mapping and rejects
foreign origins, bases and encoded path traversal without opening a browser.

The hidden-tab media check uses actual playback positions after returning to the
foreground. A hidden page may stop the snapshot publisher's animation frame, so
its cached `.paused` property is not a live playback oracle. The procedural tune
loops every 3.12 seconds; a lower raw playhead must be unwrapped using the stream
length and must never count as a successful pause. The hidden interval is shorter
than that loop. C4's exact music cue prefix and OGV must also retain aligned
visible-time advancement. Ordinary Return must retire the cue prefix.

`--legacy-save /absolute/path/to/browser-save.json` adds a supported original
Web `SaveStore` envelope to both old localStorage keys outside the product. It
verifies no automatic overwrite of existing native progress, explicit ordinary
“导入原网页存档”, preservation of original story facts and both old key byte
strings, and the imported native save's actual page reload. No old key is deleted.

All gameplay uses real mouse, keyboard or touch events and the actual monotonic
game clock. The only game bridge is `window.__GODOT_755__.snapshot()`, a detached
read-only copy used for observation and hit geometry. It has no write/seed/action
method. Screenshots must still be visually reviewed. These automated cases do
not prove human audio audibility, physical mobile acceptance, other browser
engines, a fresh manual four-chapter campaign, or every authored puzzle solution.
Record separate evidence for those scopes; do not relabel native headless tests
or retained-Web tests as Godot-in-browser acceptance.

## Historical monolithic evidence

The earlier locally accepted monolithic artifact on 2026-10-20 used Godot `4.7.2.stable.official`,
source-input SHA-256
`0dfafbba30cbe89fb356b9cb861af192450a3c54ac8f5133fc466d9a40b9be62`.
The complete Chromium run passed **242/242 checks and 3/3 viewport cases** using
runner SHA-256
`0ad27e2f179c74433e3dcc5fbc4addcb6323304ffe0d42822b063d9c46d0f5f1`.
The separate SwiftShader CI-equivalent basic run passed **106/106 checks and
3/3 cases** with its retained earlier runner; its scope excludes chapter fixtures
and hidden-tab media. These overlapping runs must not be summed as unique tests.
The compact evidence index is
[`verification/web_20261020/final_manifest.json`](../verification/web_20261020/final_manifest.json).
It records exact report, runner, WASM and PCK hashes, companion diagnostics and
the effective old audio-lifecycle negative that the accepted package fixes.

Historical save probes observed successful reloads for a small C2 import at
approximately 350 ms, a 1.6-second control, and an early-C4-map-to-bike import
whose IndexedDB primary and backup bytes matched the new engine digest before
a 356 ms reload. They did not establish a durable-write contract for later
saves, as the confirmed `95f21403` touch failure demonstrates. An earlier
late-C4-lamp-to-bike observation also retains its timing/scene-owner ambiguity.
Keep these reports as sample-specific history, not proof that a fixed delay or
forced browser termination preserves the latest write.

The accepted artifact was exported from recorded dirty source inputs. A clean
CI prepare adds one unconsumed JSON duplicate, as documented in
`fresh_prepare_comparison.json`; its output therefore needs its own artifact and
deployment verification. Prior native CI, the retained Web suite, and an invalid
native invocation without `GODOT_BIN` are not acceptance evidence for these Web
changes. Audio evidence proves visible growth and loop-aware background clock
preservation; an additional independent post-return audio-growth interval and
human audibility are outside this recorded scope.
