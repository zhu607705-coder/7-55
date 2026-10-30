---
name: Future Learning Center — Physical Miniatures
description: Four native apparatus closeups built around visible parts, shared lighting, and reversible manipulation.
colors:
  equipment-teal: "#36777b"
  grip-orange: "#db8248"
  recess-graphite: "#263f47"
  rubber: "#202d32"
  bench-ivory: "#e2e2d5"
  brushed-metal: "#a5b4b1"
  surround-sage: "#c7ccc8"
  annotation-ink: "#253e46"
  notebook-paper: "#f6edd7"
  notebook-ink: "#202b35"
  readout-paper: "#f4eddb"
  navigation-slate: "#344452"
  navigation-paper: "#e8e0c8"
  feedback-paper: "#f5f1e4"
  contact-ochre: "#c79b62"
  solar-ground: "#abb5ab"
typography:
  display:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "30px"
    fontWeight: 400
  title:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "24px"
    fontWeight: 400
  notebook:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "23px"
    fontWeight: 400
  feedback:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "21px"
    fontWeight: 400
  body:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "20px"
    fontWeight: 400
  label:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "18px"
    fontWeight: 400
  caption:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "17px"
    fontWeight: 400
  small:
    fontFamily: '"Noto Sans CJK SC", "Selected UI Coverage"'
    fontSize: "16px"
    fontWeight: 400
rounded:
  square: "0px"
components:
  exit-navigation:
    backgroundColor: "{colors.navigation-slate}"
    textColor: "{colors.navigation-paper}"
    typography: "{typography.body}"
    rounded: "{rounded.square}"
    width: "144px"
    height: "40px"
  transient-feedback:
    backgroundColor: "{colors.annotation-ink}"
    textColor: "{colors.feedback-paper}"
    typography: "{typography.feedback}"
    rounded: "{rounded.square}"
    width: "928px"
    height: "46px"
  notebook-open:
    backgroundColor: "{colors.notebook-paper}"
    textColor: "{colors.notebook-ink}"
    typography: "{typography.notebook}"
    rounded: "{rounded.square}"
    width: "476px"
    height: "266px"
  distance-instrument:
    backgroundColor: "{colors.recess-graphite}"
    textColor: "{colors.readout-paper}"
    typography: "{typography.display}"
    width: "182px"
    height: "164px"
  parts-tray:
    backgroundColor: "{colors.equipment-teal}"
  run-grip:
    backgroundColor: "{colors.grip-orange}"
  rewind-grip:
    backgroundColor: "{colors.grip-orange}"
---

# Design System: Future Learning Center — Physical Miniatures

## Overview

**Creative North Star: "The Working Miniature"**

These four closeups turn a tabletop apparatus into the playing surface. Solid parts, warm working surfaces, teal equipment, dark recesses, orange grips, and shared directional light make the next manipulation visible. Players compare physical results, change one part, and run the apparatus again. The named metaphor describes the implemented direction in the [local brief](../../../../../.impeccable/flc-miniatures-brief.md); it is not a new identity for 7:55.

This document applies only to the solar endurance race, reversible robot delivery route, two-screen synchronization apparatus, and mechanical gear/belt bench. The user approved non-pixel, fixed pseudo-3D closeups here. Existing pixel floors, room-scale art, the whole-product art bible, and other UI systems retain their own authority. There is no supplied PRODUCT.md or approved composition to reproduce. New closeup raster count is zero: the apparatus is native geometry; the retained vehicle atlas and monitor artwork serve room-scale or legacy rendering paths.

**Key Characteristics:**

- One fixed orthographic apparatus plane, with visible thickness and shared light.
- Physical parts and handles carry the main actions.
- Restrained native text names objects and reads instruments.
- Reversible assembly, owned gestures, and model-driven outcomes.
- Optional movable notes and brief feedback keep the apparatus visible.

The implementation sources are [miniature_bench.gd](../../scripts/miniature_bench.gd), [physical_bench.gd](../../scripts/physical_bench.gd), [motion_lab_view.gd](../../scripts/motion_lab_view.gd), [signal_sync_view.gd](../../scripts/signal_sync_view.gd), [workbench_view.gd](../../scripts/workbench_view.gd), [bench_projection.gd](../../scripts/bench_projection.gd), and [motion_prop_metrics.gd](../../scripts/motion_prop_metrics.gd). Source values govern the tokens; captured pixels include illumination and scaling.

The 2026-10-30 evidence records 52 desktop input checks, 58 simulated-touch input checks, and 40 presentation checks, all with zero failures. Input reports contain zero keyboard events. The independent [fix verdict](../../../../../.impeccable/review/flc_miniatures_20261030/fix_verdict.md) resolves F1–F3 from the [finish review](../../../../../.impeccable/review/flc_miniatures_20261030/finish_review.md): shared sunlight, visible belt travel, and moving-label occlusion. That limited verdict does not establish physical-device validation, formal campaign/save integration, completion of the 25-room design plan, or a whole-release acceptance.

## Colors

Muted equipment colors separate a calm work surface from the parts that can be held, connected, or measured. Frontmatter values are exact source colors; mesh colors are albedos rather than a promise of identical screenshot RGB values. The sidecar's synthesized tonal ramps are swatch previews only, not additional runtime palette tokens.

### Primary

- **Equipment Teal** (`equipment-teal`): apparatus frames, trays, lever bases, monitor housings, and notebook cover. It groups related physical equipment without turning every object into a panel.
- **Grip Orange** (`grip-orange`): lever and crank handles, rotary grips, selected physical parts, cargo, and moving signal packets. It makes active material and small moving elements recognizable; it is not a universal success color.

### Secondary

- **Contact Ochre** (`contact-ochre`): brief contact arcs, brake cues, and the notebook page fold. It marks a local event or a physical paper affordance.

### Neutral

- **Bench Ivory** (`bench-ivory`) and **Solar Ground** (`solar-ground`): material bases for the work surface. Solar uses the darker base to leave room for a visible shared illuminated area.
- **Recess Graphite** (`recess-graphite`): molded wells, tracks, instrument face, and dark monitor glass. **Rubber** (`rubber`) distinguishes wheels, cables, and belts from metal.
- **Brushed Metal** (`brushed-metal`): shafts, rails, hubs, rims, and supports. Its lit appearance comes from the same material/light system as the rest of the apparatus.
- **Surround Sage** (`surround-sage`): the 3D environment behind the table.
- **Annotation Ink** (`annotation-ink`): labels on the light surface and the background of temporary feedback. **Feedback Paper** (`feedback-paper`) supplies the feedback text.
- **Notebook Paper** (`notebook-paper`) with **Notebook Ink** (`notebook-ink`): the opened record. **Readout Paper** (`readout-paper`) labels the dark meter and splitter.
- **Navigation Slate** (`navigation-slate`) with **Navigation Paper** (`navigation-paper`): the exit control. The notebook's record/guide caption also uses Navigation Slate.

### Named Rules

**The Shared Light Rule.** Solar illumination must change the visible shared field, both belt surfaces, and both cars together. A percentage caption cannot be the sole evidence of full light, partial shadow, or a closed shutter.

**The Material Meaning Rule.** Use teal for equipment, graphite for recesses, rubber for flexible or rolling parts, and orange for grips or active material. Keep color attached to an identifiable object or physical state.

## Typography

**Display, Body, and Label Font:** the bundled `SelectedSans-Regular.otf` identifies itself as **Noto Sans CJK SC Regular**. Its bundled companion is `SelectedCoverage-Regular.otf`, family **Selected UI Coverage**. `physical_bench.gd` loads this pair directly through a `FontVariation`; system fallback is disabled. The primary face uses grayscale antialiasing. This local choice does not change the project's other typography.

**Character:** one regular sans face supports Chinese apparatus labels and numerical comparisons. Hierarchy comes from size and placement, with no additional display or monospaced face.

### Hierarchy

- **Display:** the two main distance values inside the single solar instrument.
- **Title:** the top-left apparatus title.
- **Notebook:** record title and reading text. Reading lines have an explicit baseline step (27 logical px); the current compact note column wraps six characters per line, up to six lines.
- **Feedback:** one concise sentence on the temporary lower strip.
- **Body:** general drawing default, notebook record/guide caption, and exit navigation.
- **Label:** object identities and the three lever positions.
- **Caption:** rewind label and instrument heading/time.
- **Small:** notebook cover label and secondary instrument captions. The solar operating cue is an isolated smaller annotation (15 logical px), not a general body size.

These sizes are logical Godot draw sizes. Most text is positioned by baselines, so no browser line-height scale or letter-spacing system is inferred.

### Named Rules

**The Attached Identity Rule.** Labels follow the objects they identify. During receiver overlap, suppress a stationary name that would be painted across the dragged screen; keep the dragged receiver's own identity readable. Place the solar operating cue outside the handle and shutter path.

## Layout

The apparatus uses a fixed landscape playfield (960 × 540 logical px). The 3D scene renders into a proportional SubViewport (1440 × 810) and is drawn into that playfield with linear texture filtering. Uniform scaling and letterboxing preserve its proportions; there is no alternate portrait arrangement or breakpoint-based component reflow. Supplied evidence includes desktop (1280 × 720), simulated touch landscape (844 × 390), and the actual browser extent (903 × 862).

The common title baseline is at (32, 39). Exit navigation occupies (808, 7, 144, 40). Shared physical controls keep stable anchors: lever base (832, 365), rewind center (704, 403), and closed notebook around (884, 105). These are apparatus coordinates, not independent responsive percentages. The working mechanism occupies the remaining central and left area, with loose parts on shallow trays below it. Solar reserves one right-side meter centered at (722, 246); its two cars remain visible at fixed lane positions while the belts carry the travel.

The notebook starts closed. Its open paper is movable and stays within the apparatus bounds; it does not create a new navigation page. Temporary feedback occupies (16, 486, 928, 46), then clears after five seconds. No page-wide spacing scale is inferred from these authored placements.

### Named Rules

**The Same Plane Rule.** Rendered parts, their visible handles, their hit regions, and their motion must agree under the same fixed projection. Derive manipulation from the same geometry; do not tune an independent perspective or screen-position guess for one object.

**The One Instrument Rule.** Solar distance and elapsed time belong to one side instrument. Unnumbered belt seams show movement; they do not become a second ruler or a second distance display.

## Elevation & Depth

Depth comes from actual native meshes, bevels, material response, and shared cast shadows. The fixed orthographic camera has a 45-degree elevation and zero yaw, with size (5.4 native units). Logical construction uses a scale (0.01 native units per logical unit) and a shared depth/height factor (`sqrt(0.5)`). All apparatus meshes live in the same 3D world; no per-object vanishing point is introduced.

The key directional light uses rotation (-48°, -28°, 0°), energy (0.8), and enabled shadows. Ambient energy is (0.48); ordinary material roughness is (0.52). Metallic shafts and braces use explicit metallic values in the renderer. The solar rig adds model-driven light, a shared golden field, and a physical dark shutter. These are native lighting values, not CSS elevation or drop-shadow tokens.

Seats, grips, and invalid drops use short local feedback. The lever settles with cubic-out easing (0.14 seconds); returned parts use a cubic-out path (0.22 seconds); contact cues last (0.28 seconds), or (0.4 seconds) for a brake cue. Panel tilt follows an exponential settle (`1 - exp(-20 × dt)`). Reduced motion removes the lever tween and part-return travel, clears optional motion, and uses immediate panel poses. It retains the model's necessary apparatus motion and results. Hidden closeups disable their 3D viewport updates.

### Named Rules

**The Visible Surface Rule.** Moving marks must render above the surface they explain. Solar belt seams sit above both decks, move from each car's model distance, and remain legible at touch scale.

**The Model Motion Rule.** Presentation follows the current model state. A hinge settle, gear spin, packet, contact arc, shadow, or completion animation cannot award progress or supply missing puzzle evidence.

## Shapes

Equipment uses shallow, solid boxes with cut corners and softened edges. The mesh helper caps its footprint corner cut at three logical units, or nine percent of the smaller footprint dimension; bevel rise is capped at two units, or twenty-four percent of height. This is mesh construction, not a global CSS radius. Shafts, handles, ports, wheels, and dials use round sections. Molded dark wells give each loose part a physical resting location.

The 2D exit, feedback strip, and open notebook paper have square corners. Thick paper, the center fold, and a folded page corner distinguish the notebook from a generic modal card. No invented rounded-card scale or broad decorative texture is part of this closeup system.

Robot route pieces are square in the ground plane, projected through the shared depth ratio. Their center spacing is (114, 114 × `sqrt(0.5)`) logical units. Its front sensor reach (41.5 ground units) and stop margin (2 logical units) come from the same miniature metrics used for braking; the legacy atlas cannot define the closeup's physical footprint.

## Components

The sidecar offers self-contained schematic gallery previews of these native components. HTML/SVG/CSS is documentation only: it does not replace Godot geometry, input ownership, lighting, or puzzle logic. Gallery-only hover/focus outlines are not new runtime states. Native exit hover/focus styling remains inherited; the closeup defines its normal face explicitly.

### Exit Navigation

A small, stable way back to the room. The square slate button has a thin border and a single label, “离开操作台.” It is the only screen-space action control. Closing cancels the current gesture and presentation motion, and the room handoff preserves the existing player location contract.

### Run Lever

A substantial orange grip on a metal shaft and teal base. Its three labeled positions are run, stop, and return. The grip has a generous circular hit region (32 logical px radius); dragging past the authored forward or backward thresholds submits the corresponding model operation. A tap supplies brief recovery guidance rather than secretly starting a trial. Running state has a distinct settled physical pose.

The common gesture does not imply identical model semantics: solar and robot can resume or return; the mechanical bench preserves assembled parts when returning the test piece; the signal apparatus resets its wiring when returned. Those meanings remain in their existing models and view adapters.

### Rewind Handwheel

A metal ring with a teal spoke and orange grip. Its hit radius is (35 logical px); a turn greater than (0.8 radians) invokes the current apparatus undo. A small tap explains the motion. The wheel is a physical recovery path, not a persistent toolbar button.

### Optional Notebook

A teal-bound record with warm paper and dark ink. Tap the closed book to read; drag the open book to move it; tap the page fold to request the next clue tier; tap elsewhere on the book to put it away. The model supplies records, and three voluntary clue pages supply additional guidance. Opening or turning a page does not complete the puzzle.

### Parts and Recesses

Loose panels, gears, track modules, pattern cards, and belts have visible thickness. Drag previews hold the actual part above the table, leaving its well or source position understandable. A valid target commits through the model. Invalid or canceled part drops retain the current assembly and may animate back to the tray. Rotating modules, panel hinges, and dials changes the visible component before a release commits the edit.

### Single Distance Instrument

One dark side instrument contains the modified car's distance, the reference car's distance, and elapsed trial time. Both cars remain in view over separate moving belts. The solar light carriage and its shutter affect a shared source; visible field, belts, and cars convey the result before the user reads the small percentage annotation.

### Temporary Feedback

A full-width lower strip gives one concise goal, accepted result, or recovery sentence. It expires automatically. It does not replace the apparatus with a result card or keep a control manual on the playfield.

### Gesture Ownership and Mechanism Feedback

One pointer or touch owns each active gesture. A second finger cannot operate a different physical control through that ownership; emulated mouse input does not steal a real touch. Releasing outside the playfield or canceling a touch must not commit its preview. Focus loss clears gesture state and pauses or cancels the appropriate model operation. Keyboard equivalents remain secondary, with no default hotkey strip.

Robot wheels, cargo transfer, and a local brake cue show route state. Signal packets follow the physical cables; moving a receiver also moves its socket while preserving receiver identity. Mechanical wheels, belt seams, and the feed block reveal transmission state. Their result remains observable in the mechanism.

### Named Rules

**The Reversible Hand Rule.** A preview is not a committed edit. Preserve the assembly on canceled or invalid drops, respect the active pointer owner, and keep undo, return, and exit available through their existing physical or navigation controls.

## Do's and Don'ts

### Do:

- **Do** keep these rules scoped to the four miniature closeups and preserve the surrounding pixel floors and existing UI systems.
- **Do** use the Same Plane Rule for geometry, visible grips, manipulation anchors, and robot braking metrics.
- **Do** make light, belt movement, signal propagation, and mechanical transmission readable in the apparatus itself.
- **Do** retain the one side instrument and both visible solar cars.
- **Do** keep labels clear during drag and shutter movement, following the Attached Identity Rule.
- **Do** preserve pointer ownership, cancellation, focus recovery, optional notes, and model-controlled outcomes.
- **Do** check the authored landscape playfield at desktop, touch scale, and the supplied browser extent; distinguish simulated touch from physical-device evidence.

### Don't:

- **Don't** replace object manipulation with an action-button row, numbered-port buttons, or a permanent hotkey/control panel.
- **Don't** introduce a second camera projection, unequal image scaling, or hit areas detached from the visible mechanism.
- **Don't** hide moving belt seams below the deck or use distance text as the only movement evidence.
- **Don't** use a numeric light caption as the only distinction between full light, shadow, and the closed shutter.
- **Don't** paint a stationary receiver name over a dragged receiver or place the solar cue in the handle path.
- **Don't** turn animation, rendering, or a clue-page action into an independent progression authority.
- **Don't** treat the local non-pixel exception, these token previews, or the F1–F3 verdict as a whole-product art migration, campaign integration, all-room completion, or release approval.
