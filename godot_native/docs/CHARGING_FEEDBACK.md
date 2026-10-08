# Native station charging feedback

This bounded presentation change applies only to the existing theater charging station. It is not a new phone app, operating-system charging screen, or whole-phone redesign.

## Authority

- `c3_charging_session.gd` retains its exact station rectangle, proximity, light-mode, scene, visibility, focus, phone/modal and minigame guards, plus the 2200 ms monotonic transaction
- The original Chapter 3 controller remains the only owner of receipt consumption, battery restoration to45%, and `rechargeCount`
- `c3_charging.gd` reports the existing receipt once, then reads back the synchronous result. Success requires a consumed receipt, exactly one recharge-count increment, and actual battery45. Elapsed time alone cannot show success
- Opening another surface retires the view immediately. Proximity/mode cancellation gets a short withdrawal on the live original world. It cannot add battery

## Presentation

The 248×138 pixel-phone close-up is tethered to source station point(595,773). It accepts no input or focus and opts into the existing responsive exploration contract. The first180ms aligns/inserts the connector. Pixel current then follows the connection. Actual battery and connection progress have separate labels and separate fills. Reduced motion uses static current indicators. The accepted result holds briefly before withdrawal; early cancellation withdraws from its actual insertion pose.

## Acceptance

- `test_charging_feedback.gd`: real source clock/controller success, one-use receipt, rejection boundaries and interruptions, partial/forged transaction presentation, reduced motion, pause, disposal, view bounds and early cancellation
- `test_charging_main.gd`: real Main ownership at390×844,844×390,1180×812; inventory-open and rotation geometry; phone/settings interruption; actual completion and phone opening during its success tail
- Manual fixture: run `test_charging_main.gd -- --fresh --manual`, optionally `--portrait`. Space or the original touch interaction uses the real station. F8 resets only this isolated fixture. Use a matching initial `--resolution390x844` on the cloud X11 driver for portrait. It captures actual rendered current/success/cancellation frames to the isolated user directory

A controller-backed fixture is not a complete earned campaign traversal. Desktop-rendered portrait and mouse-driven touch controls are not physical-phone testing. Existing Chapter 3 media/charging regressions also remain required.
