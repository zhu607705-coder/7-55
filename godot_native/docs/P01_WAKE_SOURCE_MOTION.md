# P01 wake warning: source motion restored

This is a local, bounded source-presentation repair on top of
`49a167f5d0aa132a4bafee33218954818b9bbabd`. It is not one of the 54 object anchors
in the animation design book and is not counted toward that list.

## Confirmed discrepancy and repair

`src/styles/scenes/p01-desktop.css` specifies a 420 ms, `steps(2,end)` loop.
At its midpoint the warning is 1.06 scale and 0.24 opacity. The old native
control only interpolated opacity smoothly and omitted scale, the 4 px ink
shadow and the separate punctuation spacing.

`native_opening_presentation.gd` now draws the unchanged two-line Chinese text
with the bundled pixel font. It keeps the source responsive 36.4–59.8 logical
font size, 1.15 line height, 8 px punctuation spacing and 10 px punctuation
shift. A scene-owned, presentation-only clock applies the four source poses.
The phone, status text and continuation button do not move. Reduced motion
keeps the warning fully opaque and stationary.

The existing `c1_wake` action still accepts the choice. No chapter controller,
flag, item, save schema or audio route is changed. Removing the page frees the
only clock. Reentry/rebuild creates one display from the existing accepted
state; no animation callback can grant a fact or advance the story.

## Verification

- `test_wake_flash_source.gd`: 329 passing checks, with native Main mouse and
  synthetic ScreenTouch input at 390×844, 430×860 and 1180×812
- Includes exact source poses, responsive resize, stationary hit areas,
  cancellation, modal blocking by mouse, continuation after modal dismissal,
  reentry/rebuild, reduced motion and real isolated disk save/reload
- Existing opening source suite: 544 checks, zero failures
- Existing phone mechanism suite: 6806 checks across 117 source checkpoints,
  zero failures; the complete 49a167f gear/tower/compact-home repair is retained
- Existing entry lifecycle 208, phone effects four timelines, pages 30 layouts,
  navigation 197, chrome 60 and loading/notice 170 checks all pass
- Actual cloud Linux native operation at 1180×812: fresh alarm Start, Close,
  sleep choice, visible warning and Enter Home. Eight runtime PNGs and the
  four actual action records are in the companion source/evidence archive
- The warning PNG filenames identify requested capture quarters, not verified
  rendered phases: step0 and step3 are byte-identical. These images do not
  establish all four distinct poses. Exact420ms/four-pose timing is covered by
  the deterministic focused tests, separately from actual desktop interaction

The actual desktop driver has no ALSA sound device and fell back to Dummy.
No hearing acceptance, Windows execution or physical Android/iPhone test is
claimed. These focused suites are not the repository's complete aggregate
suite. The actual capture harness only observes ordinary input and state; it
never injects warning or completion flags.

## Separate discovered issue

Synthetic touch on a settings-modal action which rebuilds that modal can emit
Godot `can_process: !is_inside_tree()` during engine mouse emulation. Story
navigation remains blocked. This predates and lies outside the warning art
repair; mouse modal coverage is clean. It is retained as a separate follow-up,
not hidden or counted as a passing touch-modal assertion.

No GitHub upload, pull request, merge or deployment was performed.
