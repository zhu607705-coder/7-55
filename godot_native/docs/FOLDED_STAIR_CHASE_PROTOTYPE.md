# Four-flight stair chase: fresh reconstruction preview

## Provenance and boundary (2026-10-10)

This is a new reconstruction on `fe92e00dec390324d32fdb230e3469e273ff80f7`.
The earlier local-only checkpoint `7c682da96e698f0a13da6be16a2e02bb6ec48f27`
was not found in the currently accessible filesystem, Git objects, or GitHub.
The implementation was rebuilt from the retained specification, not recovered
byte-for-byte. Historical test totals are not evidence for this code.

The user explicitly requested restarting the preview with a physical guard
flashlight and the player's phone revealing only a small face/near-body area.
The generated four-pose jump atlas is currently unavailable. The optional AtlasTexture
interface retains its original 1086×1448 layout and anchors, but the diagnostic
preview uses original full-body walking/idle frames until the actual asset is recovered
or a replacement is separately approved. Do not describe those frames as jump poses.

This is a finite four-flight development slice, not the requested complete long chase.
There is no campaign entry, completion grant, save mutation, or next-floor maze.
Only the standalone preview scene and its fixed-tick model are added. User preview
is required before any merge decision. Existing PR99 was an earlier flat prototype;
it is not this implementation.

## Scene and controls

Open `scenes/chapter4_folded_chase_preview.tscn` after the repository's ordinary
source-asset sync. Desktop: A/D or arrow keys move; Space jumps; Escape pauses.
Touch: hold left/right of the actor to move; swipe up or tap with a second finger
to jump. No permanent virtual direction pad is drawn.

A held horizontal input retains route-forward/back intent through a stair turn.
Release stops and clears that intent. A new press maps against the current camera;
a continuous opposite input reverses immediately. This is not a claim of invariant
screen-space left/right at every point on a folded route. Real playtesting remains
necessary. A short Space press/release is queued to exactly one physics step;
a held key or repeat echo must not produce automatic repeated jumps.

The player and guard share swept collision, gravity and jump rules. Normal 0.165 m
risers are walkable; the 0.6 m landing barrier, broken second-flight treads and
last-flight fallen frame require meaningful jumps. The guard is not teleported.
Speeds are 3.25 m/s player and 2.71875 m/s guard. Proofs use canonical geometry,
fixed 60 Hz raw inputs and bounded run-length records, never claimed positions.

## Lighting and camera

The oblique orthographic camera follows ascent with a forward view and fades
remote levels into a black surround. There is no distance/debug meter.
The guard carries a visible flashlight case and lens. Its real SpotLight3D origin
is ahead of the case at hand height, follows guard facing and has a 6 m range,
11 degree cone and geometry shadows. Architecture remains on lighting layer 1.
The player carries a small emissive phone screen. Its 0.55 m point light originates
at that screen and affects character layer 2 only, so it cannot reveal the route.
This intentionally keeps the too-far darkness / too-close capture tradeoff.

Real source player front/back/side frames are selected from world heading projected
through the camera basis. Left-facing side art remains mirrored; no new complete
turning animation is claimed. The source textures are loaded without modifying them.

## Verification

Fresh test outcomes are written to the recovery delivery report after execution.
Headless model/input/layout checks do not establish visual quality, flashlight
shadow quality, phone-face readability, manual completion, or campaign integration.

### Fresh baseline verification, 2026-10-10

- Godot 4.6.3 model suite: 125 checks, zero failures
- Reference raw-input replay: 1192 ticks / 19.8667 seconds, three jumps, four gates,
  grounded exit; this is automated model input, not a manual playthrough
- Standalone scene startup: three headless frames, clean parse and no script errors
- View/input regression, graphical review, actual human-input route completion,
  extended long chase and story integration are still pending at this snapshot

### Input/layout verification increment, 2026-10-10

The fresh standalone view suite passes **474 checks, zero failures**, including
native-dispatched key/touch events, short-tap queuing, held-key non-repeat, focus
pause/resume, folded controls, all 89 physical bodies, source sprite pixels,
three viewport sizes and seven route positions, handset/light attachment and
architecture-excluding phone lighting. The same test supports optional State
and verifies campaign dictionaries and save files remain unchanged when present.
The full-project execution of this added test is left to CI; only the isolated
standalone execution has been run locally. Verified jump atlas poses: **zero**.

Graphical capture is blocked in the current executor: allocation of an AF_UNIX
socket returns `EPERM`, so its installed Xorg dummy server cannot create a private
display. Godot's headless display supports the dummy renderer only. No actual
rendered image or manual run is claimed for this increment. The existing cloud
login desktop was left untouched; no permissions or network settings were changed.

### Hand-aligned short light / blue phone increment

The user reviewed the first real native screenshot and requested a smaller guard
pool, corrected physical light origin, and visibly blue phone illumination.
The guard cone is now **3.2 m / 7 degrees**, with barrel/lens attached to per-frame
hand/wrist pixels transformed through the actual billboard camera basis. The
previous abstract 0.65 m forward / 1.1 m high offset did not align with the source
hand and is superseded. The phone uses the same per-frame hand/wrist approach;
back-view frame 4 uses its covered cuff without switching hands. These remain
walking frames, not newly authored phone-holding or jump poses.

Phone screen color is cool blue `286bff`. Its small face-directed spot reaches
from the hand to the face (1.05 m range, 18-degree cone), plus a 0.16 m hand-only
point fill. Both exclude all architecture. Camera, ambient darkness, movement,
gravity, capture speeds, and winning conditions are unchanged for comparison.

Imported and exported art now uses ResourceLoader. A raw-image fallback is only
for the pre-import diagnostic setup. Fresh tests: **125 model checks + 790 view
checks, zero failures**. The 28 source PNG hashes are unchanged; imported RGBA
matches the exact configured Godot alpha-border transform, with raw alpha exact
everywhere and raw RGB exact for alpha >= 20. All 48 directional socket samples
are checked. No jump atlas poses are claimed.

The original executor's socket restriction remains, but official cloud desktop
Godot successfully opened this shared project and rendered it. The first screenshot
is an actual native run. The UI debugger badge was inspected: audio/VSync backend
messages, GDScript warnings, and imported-image loading warnings were present.
The source loader and source-code warnings are corrected in this increment;
audio/VSync availability is environment-specific. Visual lighting comparisons
are separate fixed-pose rendered fixtures, not manual-route completion evidence.
