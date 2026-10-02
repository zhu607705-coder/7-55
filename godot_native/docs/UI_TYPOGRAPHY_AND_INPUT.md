# Native typography and shared controls

The native UI keeps the original Fusion Pixel font and the source applications' distinct palettes. The shared rules follow `src/styles/base.css` and `docs/ui-motion-typography-standard.md`: body13, control label14, title18 and display24. The bundled font was compared with the original asset; replacing the font is not part of this change.

## Theme boundaries

`scripts/ui/native_ui_theme.gd` owns sharp borders, spacing, input colors and the complete normal, hover, pressed, disabled and focus states. A blue interlude button keeps its own palette and corner shape when pressed or focused. Editable text, placeholders and carets have explicit colors against their actual background.

The phone has its own13/14 theme. Early phone pages are authored at378px and scaled to424px; their default control label is compensated for this scale, while explicitly sized source headers and artwork remain unchanged. The Library reservation page retains its intentional platform-sans exception. The world SubViewport receives a font-only theme because Control theme inheritance stops at that boundary; it does not inherit phone typography or button styling. Charging captions explicitly use the bundled font.

The outer phone remains430×860. App pages own their internal scrolling. The outer shell can scroll long fallback pages without reserving a second scrollbar gutter that would widen the phone during a page transition.

Opening-dialogue controls, investigation-ring nodes and the spotlight pause control also own their state colors. Hovering or pressing them no longer inherits the shell's unrelated background. Their existing local palettes, labels and geometry are retained.

## Compact world and chase overlays

The world HUD derives its display scale from the actual SubViewportContainer. Small displays keep the scene title at least14 physical pixels and the mode, instruction and touch captions at least12. The mode label and its clickable area share the same layout rectangle. Map, actor, collision and camera coordinates are unchanged.

At390×844 and430×860, the chase uses portrait letterbox space for its header, status and controls while retaining the960×540 playfield. Body/control labels are at least14 physical pixels; toolbar/start targets are44px high and riding controls are52px high. Actual pointer/touch tests cover start, steering, charged jump, pause, resume, retry and resizing during held input. Short toolbar labels remain on one line so stale wrapping minima cannot overlap the status row. The existing desktop layout remains separate.

## Modal input and layout

Generic modals capture keyboard focus, keep Tab and Shift+Tab inside their controls, and restore the previous live control when dismissed. Text fields and choice popups retain their own keyboard input. A modal opened on desktop is recentered and resized when the window becomes narrow. A phone document blocks held world movement and camera input for its entire visible lifetime.

Closed choice controls fit the modal and may ellipsize their selected label; expanded menus retain the full source choices. The longest checkpoint-exposed route choice and the developer selector are checked at390px. Opening dialogue yields keyboard input to a focused shell modal and resumes ordinary continuation after dismissal. Active minigames already block phone-chrome actions; the native F10 settings shortcut now follows that exclusive-input rule too.

These are presentation and input-ownership changes. Controller actions, dialogue text, puzzle answers, scene coordinates and minigame proof rules remain authoritative in their existing modules.

## Acceptance boundaries

The native tests exercise actual Control trees, page transitions, keyboard/pointer input and responsive bounds. Native cloud screenshots are reviewed separately from numerical layout checks. Neither establishes a live browser pixel comparison or physical Android/iPhone acceptance. The original application-specific lifecycle and near-view gaps remain listed in `REMAINING_PRESENTATION.md`.

## Native-only exported verification

`tools/verify_exported_runtime.gd` is an external Godot verification script, excluded from exports. Run it with the exported PCK mounted as the main pack, from an empty working directory, using an isolated user-data directory and an empty executable search PATH. Set `NATIVE_EMPTY_PATH` to that empty directory and `NATIVE_ONLY_REPORT` to a writable report path. Run once for fresh-state/source-action/save checks, then again with the same user-data directory and `-- --reload` for a second-process save check.

It inventories the packed resources, rejects JavaScript/TypeScript/HTML/WASM runtime files or an npm project, instantiates the native scene/world, and exercises the native save path. The continuous campaign runs against the same PCK with only its test-harness references relocated externally. Game scripts, data and assets resolve from the pack. Node-based source-oracle tests compare the port with the original implementation during development; they are not game-runtime dependencies.
