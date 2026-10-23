# Pixel font test review — 2026-10-23

The current request replaces the previous sans-font choice with the project's
`755 Morning Note` pixel family. Tests should protect the delivered behavior,
coverage and readability, rather than make the former typeface permanent.

The following earlier assumptions are retired in this change:

- `Campus UI Sans` must be the primary face and all text must use linear filtering.
- Body, headings and digits must share the exact same Font instance. The new
  family has real Regular400 and Medium500 faces; both roles remain cached.
- The selected HUD must mix `boutique`, `legacy` and `sans`, and its heading must
  load the former700 face. Selected surface sizes, colors, leading, shadows,
  button geometry and input behavior remain checked.
- All six previous UI fonts and all three previous license files must occupy
  the production boot core. Core ownership now requires the two current faces,
  the explicit Fusion symbol fallback, the project/base/Fusion license files and each actual import
  payload. Historical font files remain source/preview references.
- Dorm modular candidate art/scenes/scripts must be retained inside every full
  Web export. This was a historical review-sample rule, but all current export
  presets explicitly exclude those candidates. A production/story-only manifest
  now requires their absence from every pack, including import metadata and
  anonymous `.godot/imported` / `.godot/exported` payloads identified by the MD5
  of the complete original `res://` source path. Explicit non-production,
  non-story-only samples keep a separately named retained-reference check.

The following checks remain required:

- Actual font family/weight metadata, distinct authored face bytes, explicit
  bundled fallback, no hidden system-font dependency or synthetic bold.
- Authored Chinese, Latin, punctuation and UI sample glyph coverage. The glyph
  specimen is a presentation review, not proof that arbitrary user text is covered.
- A font adapter leaves control geometry and non-text artwork filtering alone.
- Actual wrapped line height, page bounds, text/button separation, keyboard
  focus, input transparency and unchanged gameplay/save authority.
- Font metadata and its imported payload enter core together. The split-export
  validator still reads real PCK imports and retains full MD5/SHA/content-delivery
  validation. The100MB initial-payload budget is unchanged.
- Optional reference-export comparison still checks every original resource's
  path, byte length, MD5 and SHA256. Correcting the retired candidate-retention
  assumption does not exempt packed bytes from integrity or coverage validation.
- ASCII Hanzi sampling provenance must match its actual source font. Its20-cell
  grid is a renderer contract; replace that assertion only if the sampling layout
  itself changes. Physical word contacts, reaction time and progression remain
  separate from decorative font/mask changes.

The focused acceptance consists of font construction/coverage checks, affected
native text/layout/input tests, real core-pack verification, and actual rendered
phone/world/text-flow views at desktop and mobile sizes with high-DPI coverage.
Unrelated four-chapter controller campaigns do not add evidence for a font-only
presentation change. Headless geometry checks cannot establish aesthetic quality,
crispness at fractional scales, physical-phone behavior or browser-engine parity.
