# Cup-actuated drink machine

The three shuffled controls select existing ingredients. They do not physically dispense liquid. After an accepted `c3_mix:<item>` action, the original glass slides along the tray, contacts a paddle below the nozzle, and pushes it about its fixed hinge. Only that contact opens the visual valve. No hold-duration or timing puzzle is added.

## Continuous local phases

| Normalized time | Cup and machine | Liquid |
| --- | --- | --- |
| 0–0.16 | Cup approaches the released paddle | Off |
| 0.16–0.28 | Cup wall pushes paddle about its fixed hinge | Off |
| 0.28–0.30 | Contact settles at full pressure | Off |
| 0.30–0.65 | Cup remains in physical contact | Matching stream and fill |
| 0.65–0.76 | Cup separates slowly but stays under the last drop | Stream off, final drop falls |
| 0.76–0.88 | Paddle springs back; cup continues out | Off |
| 0.88–0.96 | Cup reaches its waiting position | Off |
| 0.96–1.00 | Settled cup; next accepted presentation or result | Off |

The cup position during push is solved from the registered right edge of the paddle and the original glass's left wall. The nozzle and hinge never translate. Rest is -0.42 radians and pressed is +0.22 radians, making their different physical poses legible. Contact uses the visible metal and bright glass rims rather than their dark alpha fringes. A queued next ingredient returns only to the nearby waiting position; its next approach starts at the actual current cup position. Late queued input still starts continuously from the completed return position.

Ordinary/terminal normal-motion clocks are 1050/1350 local milliseconds, or 1.4/1.8 real seconds at the existing local 0.75 rate. This longer presentation makes contact and transfer legible. The 140/220 ms reduced-motion clocks retain a stationary cup and resting lever, accepted layer fill, and no continuous stream or falling drops. Engine time scale is unchanged.

## Controller and interruption

- Original Chapter 3 proximity, light-mode, ownership, recipe and reward authority remain unchanged
- Clicking a slot commits its original controller transaction immediately; presentation observes accepted before/after facts
- Rapid valid choices queue visual cycles in actual input order. Repeated missing ingredients cannot interrupt a valid flow
- Escape, reload, scene change and teardown stop the visual tail without rolling back or replaying inventory
- The completed glass settles, displays the controller's result, then the existing panel return transition releases world input

## Original art and independent layers

The original canteen backdrop, transparent glass, dispenser frame, nozzle and tray are retained. Liquid layers remain clipped to the moving glass. The old generated color modules now use only their idle frame as selectors; they never depress to impersonate the mechanical valve.

`assets/native/canteen_animation/drink_cup_paddle.png` is newly generated transparent raster artwork, guided by the actual original dispenser. The built-in image-generation prompt requested one gray-black steel/plastic soda-fountain cup-actuated paddle: round upper hinge, slender stem, lower push pad, vertical rigid rest pose, matching coarse pixel clusters, and no nozzle, machine housing, liquid, cup, hands or text. The engine rotates that same rigid artwork continuously to produce rest/pressed/rebound poses. This avoids frame-to-frame pivot drift.

Generated PNG bytes are preserved unchanged (1254×1254 RGBA). The used region is `(488,150,280,960)`, hinge `(627,240)`, visible metal pad contact `(733,950)`, and uniform scale `66/710`. Provenance and SHA-256 are saved beside the asset. Sparse transparent-canvas noise outside the registered region is excluded by the sprite region, not raster modification.

The ingredient pickup view uses the same paddle and preserves its original thin-bottle eight-frame atlas and 640/160 ms clocks. Only dry frames translate. Every flowing frame remains registered under the fixed nozzle; withdrawal precedes spring return. The pickup bottle does not replace the mixer's original glass.

## Verification and preview scope

Tests cover generated RGBA registration, fixed hinge/nozzle, contact throughout push and flow, every phase boundary, flow shutoff, queued and late-queued continuity, reduced motion, cancellation/reopen, source recipe/reward parity, responsive controls, and phase-derived integration wait budgets. The native preview fixture renders the real panel with the real controller at 1100×800, 390×844 and 844×390 and writes deterministic 30 fps native frames for a motion preview. This is not a fresh campaign traversal or a physical mobile-device test; its standalone background is not the live return scene.
