# 7:55 — native Godot migration (work in progress)

This is an independent, native Godot 4.6 migration of the existing game. It uses Godot Controls and Canvas rendering, not a browser, WebView, Phaser wrapper or remote service. Original web source and delivery remain available at repository root.

**Status:** playable native migration under verification, not feature-complete and not a release candidate. Authored story/data/assets are retained, but native behavior, layouts, save compatibility and end-to-end chapter progression require the acceptance work recorded in `docs/INDEPENDENT_PARITY_AUDIT.md`. A rendered page or a chapter action list is not evidence of gameplay parity.

## Open locally

1. A downloaded self-contained source ZIP already includes `assets/` and `data/source/`: open its `project.godot` directly. For a Git checkout only, run `node godot_native/tools/sync_source.mjs` from repository root to copy original assets/JSON and export source initial state. Copies are build inputs, intentionally excluded from Git.
2. Install Godot 4.6.3 from https://godotengine.org/download/archive/4.6.3-stable/ . Open `godot_native/project.godot`.
3. Wait for the one-time asset import, then press F6/F5 or run `godot --path godot_native`.
4. The portable source package includes the native Ogg/Theora movies. For a fresh Git checkout, run `bash godot_native/tools/convert_media.sh` with ffmpeg installed. Both original MP4s remain unchanged.

Controls: P opens the phone from the world; Esc returns after child dialogs are closed; WASD/arrows move; Space interacts; mouse selects phone controls; scroll wheel zooms the world; right-drag pans; lake kayak uses alternating A/D strokes (hold S to reverse); Ctrl+Shift+D opens isolated DEV checkpoints. Preview mode does not overwrite formal saves. Phone geometry is 430×860. Desktop exploration fits the original 960×540 world to the available area; compact exploration adapts to portrait/landscape. Phone and world are separate visible modes. See `docs/NATIVE_CHAPTER4_ENTRY_FLOW.md`.

## Validation

`node godot_native/tools/validate_native.mjs` runs native project import/parse, a startup smoke and any checked-in Godot test scripts. It fails on Godot's script-error output as well as nonzero exit codes. Root `npm run validate:critical` remains the original web regression suite; passing it does not prove native parity. Source-differential Node checks need the complete original repository and its locked dependencies; the portable native-only source ZIP is self-contained for importing, running and editing the game, not for executing those original-TypeScript comparison tools.

## Current intentional limitations

- Browser SaveStore versions2–35 import through the original source-generated normalizer. Differential verification and actual import/reload/Chapter2 continuation are covered by native tests. Invalid native domains recover from the validated previous snapshot; transport/stair/closure proof remains required. See `docs/SAVE_COMPATIBILITY.md`.
- Distinct native phone reconstruction, source-backed audio, two native movie decoders, responsive phone/world input and source collision layers are implemented and under integrated acceptance. Full manual chapter traversals and browser pixel-diff remain unverified; the source browser preview is blocked by the environment extension.
- DEV contains117 exact source checkpoint snapshots in an isolated session, plus clearly separated raw scene previews. Checkpoints are testing tools and never overwrite formal saves.
- Concrete presentation work still open is listed in `docs/REMAINING_PRESENTATION.md`: remaining phone VFX, some world/device near-views, Library ambience and selected Chapter4 effects. No claim of feature parity is made until the independent matrix is checked against executable tests and real interaction.

## Source provenance and portability

Base commit: `39ccde029b0cd25a6011739a4e4f98f8c898b2c3`. `data/asset_manifest.json` records every original asset hash; `data/worlds.json` records exact authored map/collision constants and their source hashes. All 718 source asset files (625,907,429 bytes) are copied by sync. A release archive must include the generated `assets/` and `data/source/` directories; a Git checkout uses the sync command first. No absolute cloud-workspace path is required at runtime.

## Verified native milestones (2026-10-01)

- Native chapter1–2, chapter3/3.5 and chapter4 controllers with source evidence chains and terminal validation; authentic60-second canteen defense replaces the inactive legacy cart path
- Source-shape eight-world geometry, source sprites and layered foreground occlusion; dynamic tray/program/lake objects, uniform camera scaling, scene/mode transitions, kayak strokes and guard/pursuit models
- Native semantic phone views, evidence photo selection/brightness, WeChat, source CC98 flows, record recovery, audio memo order, network filtering and explicit publication/confirmation steps
- Real native3D four-level projection stair campaign uses source geometry, materials, character frames and route replay; source H3 video has a derived native-playback copy; final lamp uses approved five-layer artwork and source camera/star timing
- All native test/smoke scripts passed together; independent original TypeScript validators accepted all four native fishing traces and identical chase statistics; canteen defense matched3600 source ticks and82 interceptions (float difference under0.0004px)
- Actual cloud Godot Editor F5 interaction verified alarm→wake→home→WeChat and native canteen walking. Subsequent batches add source Settings/CC98 documents and login, native Library nested navigation, source phone-shell/home geometry, optional journal capture/publication and portable images, source Chapter3 opening/canteen discovery, exact rain-rescue media and Chapter4 dynamic props. Full manual chapter traversals, per-app side-by-side pixel comparison and remaining environmental presentation review remain open. See chapter-specific port docs; do not treat unit passes as complete visual parity

Source checkpoint regeneration uses `node godot_native/tools/export_checkpoints.mjs` after `npm ci`; compressed data is checked in. Source project packaging uses `node godot_native/tools/package_project.mjs /path/to/archive.zip`. The generated package includes all assets and JSON so it opens independently of the original repository.

## Current integrated verification (2026-10-01)

- Browser source normalizer: focused569 cases and earlier exhaustive4223 cases; current native actual persistence1805 checks/233 imports, including imported Chapter2 continuation. Save domain guard1014 checks rejects corrupt primary enums instead of accepting a softlocked save
- Rain rescue: actual route, native Theora playback and source skip/dock hold;17 checks. Journal PNG export/import and browser composition recipes:14 checks. Source kayak hull/water-area geometry:9 checks
- Chapter3 opening/canteen timelines: original TypeScript beat fixtures and81 native model/controller/real-shell checks
- Current source-backed phone Library/CC98/home and Chapter4 presentation work has focused tests. The required ordinary CC98/Library/WeChat/map/Weather entrances now have actual compact input coverage; older milestone archives do not contain these fixes
- Linux x86_64 and Windows x86_64 export presets are included. Windows executable verification is limited to build/artifact checks unless a Windows runtime is available; a Linux cloud run must not be called a Windows runtime test

Native journal exports carry their verified PNG bytes (48MiB export envelope cap). Browser recipe photos render from their actual saved composition. See `docs/LAKE_RECOVERY_AND_PHOTO_PORT.md`. Tests and build-time TypeScript oracles do not run in the game.

### Standalone builds

- Windows: run the supplied `7-55-native-windows.exe`; resources are embedded and no Node/browser/Godot installation is needed. The build is unsigned. A cloud Linux build/export check is not a Windows execution test
- Linux: keep the supplied executable and its `.pck` sibling together, then run the executable. The Compatibility renderer requires an ordinary OpenGL-capable graphical session. `--headless --audio-driver Dummy --quit-after 15 -- --fresh` is a startup smoke only
- WASD/arrows and Space are the source world controls; A/D alternate lake paddles, with S held for reverse. Touch-native controls use the same intents. Desktop keyboard/touch-event emulation and scaled390×844 rendering do not constitute a physical Android/iPhone test

Godot Engine license and third-party notices are preserved in docs/GODOT_ENGINE_LICENSE.txt and docs/GODOT_THIRDPARTY_NOTICES.txt, copied from the official 4.6.3-stable source. They apply to the engine, not a new license for the game’s original content/assets.

## Tested migration milestones

See `docs/MILESTONE_VALIDATION.md` for historical milestone evidence and `docs/LAKE_APP_VALIDATION.json` for the latest ordinary-app batch. The current continuous fresh campaign passes768 checks through the final acknowledgement, including genuine compact evidence/dryer drags and app controls. Distribution manifests identify the exact exported-pack tests and immutable build hashes. Windows remains cross-export-only; phone eligibility/loading, some interruption/audio/timing, option-order and presentation parity remain open in `docs/REMAINING_PRESENTATION.md`. Chinese launch instructions are in `打开说明.txt`.

### Low-memory first import

Open only one Godot editor and avoid simultaneous heavy builds for the initial718-asset import. If the host terminates parallel import for resource pressure, a temporary project-root `override.cfg` can set `[editor] import/use_multiple_threads=false` and `[threading] worker_pool/max_threads=2`. Do not overwrite an existing override. Remove the temporary override after import, before normal startup; this does not change source assets or runtime rules. See `打开说明.txt` for the exact file contents and [Godot's project-setting documentation](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html#class-projectsettings-property-editor-import-use-multiple-threads). Prebuilt executable packages do not need asset import.
