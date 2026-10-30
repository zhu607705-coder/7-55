# Actual GUI acceptance, 2026-10-30

Engine: Godot 4.7.1 official, real desktop OpenGL compatibility / Mesa llvmpipe. Input: actual desktop mouse via CUA. Not physical mobile acceptance. Helpers observe model state and save viewport frames; they do not set model state.

- platform: dragged board from (740,210) to (700,430), took light A photograph, routed around camera via y370 to (260,430), switched physical B lamp, took B photograph. Both four-corner-visible receipts passed with different revisions/layouts.
- signal_sync: observed old-cache mismatch; dragged receiver B socket to live B; changed source; moved receiver A; changed source again. Distinct patterns 2 and 0 passed under revision 1.
- scaled team: actual standalone at 780x438, clicked existing desk; rewired and completed two changes through scaled coordinates; returned. Player (668.9423,3653.036) unchanged in floor/puzzle/floor snapshots.
- robotics: default actual run unloaded but stopped against reverse lip. Dragged direction ring down and selector right, ran again; same cargo unloaded and empty carrier returned to start. Real motion, no model jump.
- electrical: medium gear dragged to axle, physical belt flipped parallel, tension seated, target sign flipped left, power started. Actual run reached left mark, passed.
- koala: modules 5,4,3 dragged to slots 0,1,2, crank run; second input card dragged into clamp, crank run again. Both input receipts passed under revision 3.
- solid_projection: long block and two cubes dragged to slots (0,0),(1,0),(1,1); actual shutter run passed all three projection receipts.
- machinery: three cuts performed in inner-slot/outer-notch/bridge order. Sample drag hit right clamp. Moved same clamp to upper mount, continued pulling same sample out; passed.

Evidence: captures/gui_*platform.png, gui_*signal_sync.png; captures/integrated_scaled_*.png; captures/actual_*ROOM.png. Logs gui_platform_signal.log, integrated_scaled.log, gui_remaining2.log. Robotics successful segment is in gui_remaining.log; that temporary harness then used the wrong path for legacy electrical and raised load/freed-view errors. The corrected harness uses workbench_view.gd; use gui_remaining2.log for subsequent rooms, not the earlier harness failure as a game pass.
- formula: large solar panel + medium (1.6) gear physically installed; knob dragged to 30 degrees; car dragged to track; physical release lever pressed. Actual uninterrupted 30-s simulation finished 62.52 vs baseline52.35, completed=true. No accelerated timer or model assignment.

The repository keeps the eight final rest renders and seven representative completed frames (`completed_*.png`), plus the three scaled entry/return frames. Platform completion is documented above; its final rest image includes the later lamp-label readability correction, which passed its 17 relevant checks again. The full local capture directory also contains intermediate frames and is not required by the runtime.
