# Direct manipulation: actual GUI observations

2026-10-30, Godot 4.7.1 official, real X11/Mesa viewport 960×540. Before uses frozen `flc-2f-reverse-20261030`; after uses `flc-direct-manipulation-20261030`. All gestures used native desktop mouse via CUA. A read-only SceneTree observer saved viewport PNGs after rendered frames and logged pointer, mouse-down, and visible/model pose. It did not inject events or assign model state. Frame sequences are not a realtime video; rendering/screenshot I/O affects sampling cadence. Cursor itself is a desktop overlay and is not embedded in viewport PNGs; coordinates and held status are in logs.

| Room | Observed before | Observed after | Evidence frames |
|---|---|---|---|
| projection | Shared B slider 195,434→325,434: body and slider remain at depth0 while held; release commits2 | Same gesture: rendered pose .338→1→1.569→2 while still held; release stays2. Separate body drag390,230→390,266 follows correct front-view depth axis | before406–408; after406–409 (observe_slot.log) |
| rail | pointer336,310 while cart remains160,310; release starts travel | pointer340,310 and cart340,310 while held; reaches400 without post-release run. Further drag900 stops at720 against other cart. Returning to200 preserves half-grid location on release | before022–025; after019–022,031,048 |
| solid_projection | Held bar remains in rack, flat rectangle follows pointer; release creates placed bar | Same solid bar leaves rack and follows pointer in mid-drag. Release at470,283 gives only <0.5px projected settling to470.456,283.186 | before224–226; after061,064–065,070 |
| balance | Last held center750,413 → first release315,288; starts transport replay | Correct grip-offset destination pointer750,254 has tray center750,307.95 before AND after release, then local settling to750,308 and completed | before286–287; after122–123,130 |
| platform | Continuous GUI input already stops near obstacle614,278 | Stops at612.72,277.516 and preserves on release | before110; after146. Do not claim old GUI stayed at origin: that was a single-large-step model case |
| coupled | Continuous GUI drag already reaches y360 contact | Linked pair still reaches y360 and cannot enter narrow throat | before132; after171. Large single-event sweep regression is covered by model tests, not a visually dramatic difference here |
| recording | At carriage x436, held baffle ghost passes through carriage; release returns to150 | Solid baffle moves209, stops224 while pointer reaches300, and release preserves224 | before182–183; after212–213 |
| robotics | No fresh before sequence in this pass | Drag up stays up; right previews0rad then returns to original up because not a detent; down previews/commitsπ/2. Physical switch previews12 then commits16 | after225–230,234–235 |
| formula | No fresh before sequence in this pass | Small6px gesture returns to0 rather than jumping30. Larger gesture previews5→30 while model tilt index remains0; release commits index1 | after243–245 |

Recording setup used actual baffle drag to150 and 12 right handwheel clicks (18px each), not fixture model assignment. Robotics and formula were manipulation checks, not new full timed trial completions; experiment rates and durations were not changed.

GUI did not exercise touch devices or inject a held-drag cancellation. Cancellation, multitouch ownership, and restoration are supported by the independent automated input regressions; do not label them real-device GUI coverage.

The first after observer run had missing isolated font import metadata and fell back to readable fonts; these warnings remain in `after/observe.log`. Isolated asset metadata was then repaired without editing either gameplay tree. The shared-slider reruns (`observe_slot.log`) have no resource/script errors, only the display-driver VSync warning. Earlier captured Chinese text is visibly readable. All observer windows were closed after capture.
