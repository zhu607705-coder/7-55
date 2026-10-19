# Three-outlet, cup-actuated drink machine

Three independent nozzles each have a fixed horizontal hinge and a rear cup paddle. The shuffled ingredient controls retain their existing controller identities. A selected cup first aligns at the front of the tray, then pushes forward into the machine. Its rear wall pushes only that outlet’s paddle backward. There is no hold-duration or timing challenge.

## Continuous local phases

| Normalized time | Cup and selected paddle | Liquid |
| --- | --- | --- |
| 0–0.14 | Transfer laterally at full front clearance | Off |
| 0.14–0.26 | Move forward toward the resting paddle | Off |
| 0.26–0.36 | Rear cup wall pushes paddle back about its horizontal hinge | Off |
| 0.36–0.38 | Settle in contact | Off |
| 0.38–0.66 | Hold forward contact | Selected outlet streams; original glass fills |
| 0.66–0.76 | Withdraw slightly while catching the final drop | Stream stops; one final drop |
| 0.76–0.88 | Withdraw as the paddle springs forward | Off |
| 0.88–0.96 | Return to the front edge of the tray | Off |
| 0.96–1.00 | Settle before the next transfer or result | Off |

The next accepted ingredient starts from the cup’s actual current lane. Every cycle finishes at front clearance before lateral transfer. The three nozzle positions and hinge nodes remain fixed. Only the active textured paddle is projected through depth; no paddle node rotates in the image plane. Other paddles stay at rest.

Normal ordinary/terminal clocks are 1050/1350 local milliseconds, or 1.4/1.8 seconds at the existing local 0.75 rate. Reduced-motion clocks remain 140/220 ms and keep the cup and paddles still, show accepted fill, and omit streams and drops. Engine time scale is unchanged.

## Authority and interruption

- Original Chapter 3 proximity, light-mode, ownership, recipe and reward authority are unchanged
- Selecting a slot immediately commits its original controller transaction; presentation observes accepted before/after facts
- Rapid accepted choices queue their visual cycles in actual input order. Missing ingredients do not interrupt valid flow
- Escape, reload, scene change and teardown stop the visual tail without rolling back or replaying inventory
- The completed glass settles, shows the controller’s result, then the existing panel return transition releases world input

## Authored raster art and registration

The original canteen background and transparent glass are retained byte-for-byte. The generated machine close-up uses the original gray-black canteen dispenser as its visual reference, adds visible tray depth, and separates three outlets from three independently moving paddles. Liquid remains clipped inside the original glass.

The built-in image-generation tool made `drink_fountain_body.png` and `drink_fountain_paddle.png`. Its prompts requested coarse gray-black pixel-metal art matching the supplied original machine, three distinct nozzle assemblies above a deep tray, neutral selector inserts, fixed hinges, and a separately isolated rear cup paddle. They excluded cups, liquid, hands, text and baked scene backgrounds. Generated PNG bytes remain unchanged; provenance and SHA-256 are saved beside each asset.

`drink_fountain_rig.gd` registers the 1536×1024 machine source at origin `(768,800)` with uniform scale `0.4`, source region `(240,60,1040,900)`, and source outlets `(531,394)`, `(755,394)`, `(1003,394)`. Its shader discards alpha below 0.70 to suppress the generator’s exterior glow. Neutral selector inserts are tinted with the existing source ingredient colors.

The separate 1536×1024 paddle uses source region `(484,250,568,714)`, hinge `(768,260)`, contact point `(768,704)`, and scale `0.1`. Region cropping excludes an unwanted upper cylinder without rewriting pixels. The same rigid paddle artwork is projected continuously about its fixed hinge: rest angle `0.55`, pressed angle `-0.12`, screen depth axis `(-0.22,0.4)`. This conveys forward/back motion rather than lateral lever rotation.

The cup remains uniformly scaled from the original 346×557 crop. Its nominal height is 120, radius is derived from that same aspect, and perspective scale changes uniformly with depth. Its foot follows the tray plane with back-floor origin `-60`; independent tests compare that foot with the visible source grille polygon `(446,660), (1135,678), (1113,788), (271,767)`. Contact is the rear cup wall meeting the opaque paddle face. The nozzle remains within the cup opening during every flowing or dripping phase.

The ingredient pickup view reuses the three-outlet rig, its original thin-bottle eight-frame atlas, and its original 640/160 ms clocks. Blue/white/black map to separate fixed outlets. Only dry frames translate in depth; flowing atlas frames stay registered to the selected nozzle. The pickup bottle does not replace the mixer’s glass.

## Verification and preview scope

Tests cover three independent assemblies, shuffled source mapping, original raster identity, fixed hinges/nozzles, depth projection, tray support, contact and nozzle containment, all phase boundaries, front-only queued transfer, cancellation/reopen, reduced motion, recipe/reward parity, responsive controls and phase-derived wait budgets. The native fixture renders the real panel with its real controller at 1100×800, 390×844 and 844×390. A deterministic 30 fps capture runs the actual presentation clock and queue, not unrelated hand-selected poses.

The preview is an isolated native panel fixture, not a fresh campaign traversal or a physical mobile-device test. Its standalone blank background is not the live return scene. The inherited compact/inset panel layout remains unchanged in scope.
