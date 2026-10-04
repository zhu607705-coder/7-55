# Recovery 03.5 photo presentation

The recovered photo task squeezed portrait evidence into 100 × 80 landscape previews. It also omitted the original ordering instruction, Reorder control, and the continuous-frame playback after a successful submission. The original paper positions and mirrored landmarks were consequently difficult to compare.

This change restores those photo-page features using the five unchanged original WebP assets. Three columns fill the available phone content width; every image keeps the source 0.78 portrait ratio, uniform cover crop, nearest filtering, and authored mirror flag. Each portrait reserves its full height before its caption. The source instruction and three numbered slots precede the grid. Reorder clears only draft choices, while accepted photo evidence remains controller-owned and immutable. Selected cards and a full three-card selection use the source disabled state.

After an accepted result, a page-owned native TextureRect cycles the original left, middle, and right frames every 0.55 seconds. Its 1.65-second loop is presentation only. Hidden pages stop their clock, closed pages free the owner, and reduced motion keeps the first frame. The preview never submits a puzzle result or writes progress.

## Source correspondence

| Original | Native restoration |
| --- | --- |
| `src/scenes/phone/P18_Photos/index.tsx`, recovered-photo-stage | Original instruction, numbered order slots, Reorder |
| `src/styles/chapter-three-interlude.css`, recovered-photo-grid | Three columns, 0.78 portrait crop, pixel filtering, mirrored decoys and disabled choices |
| Same CSS, recovered-frame-preview | Original three-frame order and 0.55-second timing |
| Source reduced-motion rule | First original frame, stationary |
| Source `setOrder([])` | Controller-routed draft reset; no evidence mutation |

The ordinary album shelf, the existing app header/navigation, shared inventory rail and global typography are outside this bounded change. The original recovered-frame grid selects directly; this change does not claim that the source had a missing zoom inspector.

## Validation

- Final focused tests pass: 185 portrait/layout/animation checks, 57 actual routed retry/save checks, 56 Home-photo entry checks, and 72 Chapter 3 controller checks. The complete graph parses 338 scripts without failure
- All five native photo assets match the original source files byte for byte
- An initial narrow-width overflow and first graphical Reorder-width/caption-spacing defects were retained in the review history, corrected, and covered by strengthened tests
- Ordinary earned-save desktop input resets a prior wrong selection, selects and submits the three frames, and receives accepted photo evidence. Two native frames show the restored animation advancing. The source audit had already exposed the answer; this is assisted interaction verification, not blind puzzle discovery
- Exact native 430 × 860 and 390 × 844 windows verify card selection, Reorder, scrolling to the preview, return to the recovery summary, and ordinary reload. Accepted evidence remains 1/4 and the cleared draft remains separate from the accepted frame order
- The old collapsed inventory rail still overlaps some left-side text. These checks do not approve all typography, physical touch, audio, or complete visual equivalence of the entire Photos application

Fresh Linux export passes the packaged Chapter 1–4 automated campaign, native-only first start/reload, and all 185 packaged photo checks. A separate actual 390 × 844 run of that standalone executable uses an unchanged earned save copy: photo entry, decoy selection, Reorder, visible animation, Return and normal Save preserve all accepted evidence. The main profile remains unchanged by that copy. No whole-suite aggregate or new Windows export is claimed.
