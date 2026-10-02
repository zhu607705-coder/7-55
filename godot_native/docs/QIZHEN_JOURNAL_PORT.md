# Qizhen optional camera and single-thread journal

## Scope and sources

New native ownership is `scripts/chapters/c3_journal.gd`,
`scripts/media/c3_capture_session.gd`, and `scripts/ui/c3_journal_pages.gd`.
The Chapter 3 owner integrates the module before lake dispatch and delegates the
existing phone builder to the independent journal builder. Web source remains
unmodified. No Git submission or publication was performed.

Authoritative executable references:

- `src/modules/ChapterThreeQizhenLakeController.ts`, photo precheck/capture,
  save/discard draft, main/reply precheck and publication methods
- `src/modules/QizhenJournalModel.ts`, exact tag derivation and deterministic
  FNV-1a / seed mixing / mulberry32 / Fisher–Yates thread projection
- `src/scenes/rpg/QizhenLakeModel.ts`, source-pixel photo standing areas, framing
  recipe, eight-way heading quantization, swan/ripple buckets
- `src/components/QizhenJournalCamera.tsx` and
  `src/scenes/phone/P02_CC98/QizhenJournalThread.tsx`
- `src/data/chapter3-qizhen-lake.content.json` and
  `src/data/cc98.thread-personas.json`, original authored copy/personas
- `src/modules/ChapterThreePhoneInterludeController.ts`, journal closeout and
  memory-card fact ownership

## Implemented behavior

- Four source-measured photo locations, with the two separate dock standing
  areas, exclusive open-water locations, and no channel photo target
- Facing-agnostic capture; correct scene, live coordinates, zone, vehicle,
  boarding-complete compatibility, chase rejection and archive rejection
- Runtime-only two-phase capability capture; no photo or draft fact is written
  by the request, failed/hidden host, cancellation, stale receipt, arbitrary
  dictionary, or an unrelated capability object
- Actual PNG persistence and hash-checked display. No background-map,
  recovery-frame, library-evidence, or stock-photo substitute is rendered when
  a journal image is absent. Opaque black/uniform and transparent framebuffers
  are rejected using a bounded 17×11 color-variance sample
- Source photo/draft IDs, one photo per spot, capture idempotence, main/spot
  classification, previous title/status restoration on retake, and source
  recipe/tags. Tags use the source rounded speed/roll snapshot while recipe
  clarity uses actual motion inputs
- Authored title/status/caption choices only. Full-draft submissions verify
  draft ID, stored-photo identity, derived kind, and source option membership
- Source close/retake rollback: close keeps saved drafts; unsaved close and
  explicit retake remove the matching unposted photo; published photos survive
  rollback. Camera back button sends the close intent rather than navigating
  around rollback
- Unique persisted main thread/seed, campus-Wi-Fi publication, offline draft
  retention, one reply per optional location, and duplicate checks before the
  network gate. Chase/archive rejection remains before duplicate publication
- Source deterministic reply selection, fictional personas, contiguous floors,
  published-order interleaving, owner-only display filter, authored photo labels
  and real captured-image review
- Read-only shared save-owner hooks `validate_photo_record(value)` and
  `validate_journal_snapshot(journal)`, covering finite source coordinates,
  buckets/tags, nullable string IDs, unique spots, photo/draft identity, image paths/digests,
  and native capture metadata

## Runtime host contract

`c3_photo` produces `{handled:true,capture:{session,on_success,on_cancel,scene,
zone,spotId}}`. The session is a `RefCounted` object retained privately by the
journal module and must never enter persistent state.

1. Host must require a visible, current lake world, no competing modal/minigame,
   and a valid native graphics surface. Freeze the world for the capture frame,
   hide HUD/touch controls, and wait for `RenderingServer.frame_post_draw`.
2. Save the actual world framebuffer PNG under `user://qizhen_journal/`.
3. Call `session.receive_capture(path, metadata)`.
4. Call `State.act(config.on_success, session)` with that exact object.
5. On failure call `session.fail_from_host(reason)` and
   `State.act(config.on_cancel, session)`; do not synthesize image data.

Metadata is `{source:"world_viewport_crop",scene:"qizhen_lake",zone,
player:{x,y},speed,roll,heading,capturedAtSeconds,camera?:{x,y,zoom}}`.
`capturedAtSeconds` must be a nonnegative integer monotonic second, as in the
source; a fractional wall/frame time is invalid. The capture dimensions must be
320×180 through 3840×2160. The name `world_viewport_crop` remains the agreed
receipt discriminator even when the host now reads an actual world SubViewport.

The controller validates object identity, completion, source, zone, unchanged
player position, finite motion/time, dimensions and image variance. It owns the
accepted photo PNG/digest. `nativeCapture` records actual pixel dimensions and
camera transform separately from the preserved source recipe's recommended crop.
The native actual-world photo is not claimed to be a reconstruction of that
fixed source recipe composition.

## Source nuances deliberately preserved

The selected optional caption is validated and retained in `pendingDraft`.
Actual source `projectJournalThread` chooses displayed owner-caption copy by
hashing `photo.id`; it does not render the pending caption despite a controller
comment saying otherwise. Native projection follows executable source exactly.

`fishingAssistUnlocked` and `fishingAssistConsumed` have no production source
writer or consumer. A model comment mentions rewards for optional-photo counts,
but no corresponding transaction is implemented in the authoritative source.
Native journal does not invent assistance, rewards or story gates.
`memoryCardUnlocked` belongs to the existing Chapter 3.5 closeout transaction,
not to optional photo count.

After publishing the main thread, the source runtime permits a new lake-center
capture as kind `spot`, but supplies no lake-center caption choices; close/retake
remains available. Native preserves that behavior. The native typed validator
retains this legitimate runtime pending draft safely; the web `SaveStore`
currently discards it during rehydration. This is an explicit persistence
compatibility repair, not a new reward or progression rule.

Native capture and draft-authoring actions validate authored options. Persistence
validation deliberately follows source `SaveStore`: main title/status and draft
title/status/caption IDs are nullable strings, including strings absent from the
current catalog. Source photo capture times are nonnegative finite integers;
only the thread seed has the safe-integer bound. Restoring these strings never
creates a capture receipt or bypasses live capture/publish validation. Native
image paths, hashes, dimensions, and capability receipt checks remain intact.

## Verification and current limitations

Run from repository root with Godot user data isolated under `/tmp`:

```
node godot_native/tests/export_journal_source_fixtures.mjs
HOME=/tmp/c3-journal-home XDG_CACHE_HOME=/tmp/c3-journal-home/.cache \
XDG_CONFIG_HOME=/tmp/c3-journal-home/.config \
XDG_DATA_HOME=/tmp/c3-journal-home/.local/share \
godot --headless --path godot_native --script res://tests/test_qizhen_journal.gd
```

Verified on Godot 4.6.3: **105 checks, 0 errors**. Fixtures are generated by
bundling/importing the original, unmodified TypeScript modules into temporary
storage: seven recipe/tag cases and five complete deterministic thread
projections match. Tests also cover measured boundaries, source gates, forged
receipts, failed captures, draft validation, cancellation/rollback,
Wi-Fi/idempotence, snapshot validation, JSON roundtrip, and native UI construction.

Test PNGs are explicitly synthetic unit inputs used only to exercise image
transport and validation. They are not gameplay captures or evidence of visual
QA. Tests remove only their own tracked temporary files.

A separate integration regression is provided:

```
HOME=/tmp/c3-journal-save-home XDG_CACHE_HOME=/tmp/c3-journal-save-home/.cache \
XDG_CONFIG_HOME=/tmp/c3-journal-save-home/.config \
XDG_DATA_HOME=/tmp/c3-journal-save-home/.local/share \
godot --headless --path godot_native --script res://tests/test_qizhen_journal_save.gd
```

The shared State validator now delegates nullable journal photo/draft records to
the typed journal validator. The actual native save/reload regression passes with
**0 failures**, alongside the 105-check journal suite. The broader
`test_save_integration.gd` additionally restores source-normalized nullable string
IDs, source-valid capture timestamps, all 117 developer checkpoints, browser
versions 2–35, native exports, and primary/backup recovery through actual files.

Native framebuffer/UI visual inspection and shared-host hidden-world
cancellation require separate integrated-shell coverage; this focused save suite does not establish them. The journal builder
currently renders source publication failure copy through shared feedback; it does not reproduce the source's dedicated
three-action network-error modal or photo-detail lightbox. No full native
migration claim is made by these focused checks.
