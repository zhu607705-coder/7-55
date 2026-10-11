# Native bonsai petal growth

The third accepted water/light/fertilizer condition starts a 4.8-second visual
sequence on the mounted bonsai page. The original Chapter 1 controller still
commits all conditions immediately. No new save key, item, reward, audio cue,
completion callback or progression gate is added.

## Artwork and timing

- Reuses the previously supplied closed-bud illustration and 6 × 4 purple-flower
  opening sheet. The sheet contains 24 distinct key poses. This is key-pose
  playback, not a claim of 24 newly hand-drawn frames per second.
- The four blossoms have separate pivots, orientations and 160 ms start offsets.
  A closed bud anticipates, the actual outer-petal/cup drawings open, and a small
  stem-tip settle finishes. The pot, room, phone frame and controls never scale.
- Only each sheet cell's largest connected purple component, plus its enclosed
  stamens, is used. Adjacent cropped buds are discarded rather than becoming
  floating petal fragments.
- A generated flower-free backing is sampled only inside four bounded blossom
  regions. All pixels outside those regions come from the original final PNG.
  The pot, shelf, window and unaffected foliage retain their original pixels.
- Each blossom restores its exact original local art between 4.05 and 4.25 s,
  plus its offset. The last is restored by 4.73 s. At 4.8 s each native blossom shows its exact original patch. The composed
  endpoint is pixel-identical to the original bloom, with no shader or scaling.
- Reduced motion keeps the pose changes but removes anticipation displacement
  and stem-tip oscillation. It does not change source action eligibility.

## Native object structure

`BonsaiArtwork` retains TextureRect dimensions for the existing silhouette hit
mapping but does not paint a second copy. `BonsaiObjects` contains a room/foliage
Sprite2D, a separate `PotBase` Sprite2D, and `Blossom1` through `Blossom4` Node2D
instances. Each blossom owns its pivot, visibility, transform and key-pose draw.
`PotBase` owns a bounded original pot/root-base patch, removed from the room
texture; hiding it cannot leave a duplicated pot underneath. Its region includes
nearby root foliage/background, not an invented transparent full-plant asset.
A transient bud-scene handoff lasts only 320 ms. All layers use native lifecycle
and nearest-neighbor texture resources, without adding physics to the phone UI.
The original semantic plant DropButton remains the sole controller action owner.

## Lifetime and input

The session observes a bloom rising edge only while mounted. Rebuilding the
page preserves the running clock. A newly loaded state or a later visit renders
the saved endpoint and does not replay the animation. Leaving cancels the
presentation; it cannot undo the already accepted third condition.

Clicking or keyboard-activating the plant immediately finishes the visual and
submits the original `c1_flower` reveal. The digit still requires the separate
`c1_collect_flower` action. Returning, cancelling, repeated clicks, rejected
items and repeated refreshes cannot manufacture a digit or replay a success
sound. The original mounted-page brightness check is unchanged.

## Verification

`test_bonsai_growth.gd` checks all six condition orders, repeated rebuild/drop,
re-entry, actual isolated save/reload before and after digit collection, reduced
motion, distinct source poses, fixed original pixels and exact final texture.
The existing native bonsai input suite covers actual inventory drags, Control
Center brightness, Enter/Space, mouse reveal, page exit and one-time collection
at 390 × 844, 430 × 860 and 1280 × 720. The existing bonsai audio parity suite
checks the original once-only sounds.

`preview_bonsai_growth.gd` is an explicitly isolated Main fixture: two conditions
are pre-satisfied, then the original fertilizer action triggers the ordinary
renderer. With `BONSAI_CAPTURE_DIR`, it captures native viewport PNGs and exits.
Without that variable, it leaves the real plant reveal/exit controls available.
It does not write a formal save. This fixture is not a fresh full-game playthrough.

No full native aggregate, Windows execution or physical-mobile validation is
implied by these focused tests. This feature is based on official native commit
`913bd512c19c70e842461e0357091dca3635d389` and is independent of the concurrent
animation-integration branch.
