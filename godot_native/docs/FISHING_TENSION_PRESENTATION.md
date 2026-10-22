# Native fishing presentation and tension-linked motion

This bounded source change targets `godot-version` from `81a91082e3d25a1ca290091b5108470175814edb`. It updates the fishing view and its existing host layout, adds read-only motion math and six separate PNGs, and extends three focused tests. The original environment and player/skiff images remain intact. Other regional animation, object, phone UI, campus and chase candidates are excluded.

## Presentation

- A clean background plate and independent target fish, distant swan and submerged creature preserve the original scene composition. These are new native-only files; original source artwork is not overwritten.
- The compact HUD reserves a 50-pixel toolbar. The water remains the direct pointer/touch interaction surface; keyboard input remains available. The redundant simulated pad row and its T toggle are retired.
- The existing model's four-beat phase drives fish anticipation, thrust, player pull and recovery. The actual model tension controls rod bend and line slack. Releasing input cannot invent an immediate tension decrease.
- Painted pull/release upper-body poses provide a real elbow change. The lower body and skiff remain fixed. The fish's gameplay anchor is unchanged while its body and tail deform.
- Reduced motion suppresses secondary body/tail movement. Rendering does not advance model time, score notes, award items or save state.

## Authority and dependency checks

The live remote fishing view and host were byte-identical to the original visual-package baseline before this change. No unreviewed regional host snapshot was introduced. The rhythm model, lake chapter controller, chart JSON, save system, audio director, Main and World remain unchanged from the remote base.

The isolated test project uses the remote's tracked native files. All 718 original asset SHA-256 values match the checked-in source manifest; every original source JSON was checked against its Git blob at the remote base. The six new PNGs are explicitly included in the commit, despite the generated-assets ignore rule. Exactly three actor `.import` configuration files are tracked to preserve `mipmaps/generate=true`. A fresh default import was verified to disable mipmaps, which would change the approved minified actor rendering. These portable settings are intentional build inputs. Other generated import metadata, caches, movies and unrelated assets are excluded.

## Verification on 2026-10-08

Godot 4.6.3 import/editor parse passed. Twelve targeted scripts passed with no script, parse, engine-error or failure markers:

| Test | Checks / result |
| --- | --- |
| Fishing motion | 149 / 0 failures |
| Fishing view | 202 / 0 failures |
| Control scheme | 264 / 0 failures |
| Pointer following | 76 / 0 failures |
| Main focus/return | 32 / 0 failures |
| Audio lifecycle | 23 / 0 failures |
| Terminal feedback | 21 / 0 failures |
| Failure body | 48 / 0 failures |
| Minigame models | All four charts solve and replay; 0 failures |
| Chapter 3 | 72 / 0 failures |
| Qizhen source branches | 416 checks, 25 isolated native disk saves, 0 failures |
| Lake reload boundary | 0 failures |

Each script used a fresh isolated profile. All four checked-in rhythm replay fixtures remained byte-identical afterward. The native GitHub Actions aggregate and independent review are separate publication gates and must be checked for the exact PR head before merging.

## Evidence boundaries

The targeted suite is automated model, input-fixture, lifecycle and replay coverage. It is not a manual fresh-campaign completion, physical-phone acceptance or subjective audio review. Fixed-state pose captures demonstrate appearance, not earned catches. Ordinary lake save reload does not restore an in-progress fishing beat. No new platform export or release package is included in this PR.
