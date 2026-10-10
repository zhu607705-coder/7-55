# Chapter 4 chase stair presentation

The earned route reached the original stair activity, but its generic fitted
960 x 540 panel was reduced to a thin strip on a 390 x 844 window. Text and
actors became too small to use, while the previous world's stair prompt remained
visible below it. The initial activity also built two Return buttons.

## Restored presentation and input

The activity now participates in Main's existing full-area activity contract.
Main hides the underlying world during the activity and restores it on Return.
The title, instructions and buttons use physical dimensions independently of the
map. Actions have 44 px minimum heights; desktop retains keyboard/mouse input and
a visible optional joystick switch. Actual touch capability or a real field
touch enables the joystick. Viewport width alone does not select touch input.

The original `finale_stairwell.png` is retained. The active view restores a
960 x 540 follow camera, the source 150 x 80 deadzone, 0.18 follow interpolation
and camera-only -190 upper headroom. The view uses original player direction
frames and guard up/down/side sheets. Their foot registration follows the
original sprite/body formulas; the guard sheets use their declared 9 fps.
No generated art or rebuilt collision boxes are used.

Portrait adds a separate read-only full-floor overview of the same original
plate and live actors. It submits no input and owns no simulation, proof, clock,
save or progression. The main field preserves its aspect and maps pointer
coordinates through the same source camera used for rendering.

One pointer or finger owns the field or joystick until release. Release outside
the viewport, field drag-out, resize, focus loss, Retry, Return, completion and
disposal clear held input. Emulated mouse events cannot duplicate a touch and a
second finger cannot steal the gesture. A first toolbar touch does not rebuild
the button beneath that press. Existing movement speed, collision, model clock,
failure count and final path validation remain unchanged.

## Actual evidence

The input is the unchanged earned stair-admission save from 2026-10-05 13:18:13,
SHA-256 `7419b5780e92f2c6e356d78c0cd28f88692dfa9784e9655c7f0be92882c874b1`.
It was reached with source navigation knowledge and Tasks pause assistance. Its
attempt counter includes unattended admissions during tool delays; it is not a
count of player skill attempts.

Ordinary reload opened the existing phone page. The actual Return to world
reached the retained stair entrance and opened one activity. Desktop, 390 x 844,
426 x 860 and 844 x 390 layouts were observed. The joystick fallback was opened
with a real pointer, then used to reach the first platform before capture. The
camera and original direction frames followed the actual movement. Return
restored the original world; pressing its stair interaction opened a fresh
activity. The process closed normally with exit 0.

The first actual set predates only the final correction from the inherited
110 ms guard frame interval to the source manifest's 9 fps. It retains its exact
source snapshot. The final cadence revision then passed 119 focused checks and
was ordinarily reloaded again from the same earned input. Actual 390 entry,
Retry and keyboard movement were observed and captured, followed by exit 0.
The other affected checks passed earlier: 115 Chapter 4 progression/proof, 38
device/Main and 7 modal/world input checks. This is 279 focused checks, not a
full aggregate acceptance result.
Exact 430 x 860 is automated coverage; window-manager attempts in this session
produced 426 x 860. Desktop pointer simulation is not physical-touch acceptance.
Dummy audio is not hearing acceptance. No full stair escape, fresh export or
aggregate gate is claimed by this presentation slice.

## Remaining original-rule differences

Source review identified inherited differences outside this bounded change:

- The original guard lead/delay uses the scene handoff; the current native
  activity uses a fixed two-second delay
- The original controller records intermediate stair landings; the native
  activity currently submits a validated whole-route path at its exit
- Original stair capture uses the timed guard dialogue/controller callback;
  this activity retains its existing local caught/Retry behavior
- The native player's existing walkability samples use a 16 x 10 foot box;
  the original shared player body is 19.5 x 14.625. No collision dimensions are
  changed by this view restoration

These are recorded for a separate original-behavior restoration. This candidate
must not be described as complete stair gameplay parity or as a difficulty fix.
The previous 50 proposed paths are frozen separately. No exact Git submission
scope has been selected; no staging, commit or publication is authorized here.
