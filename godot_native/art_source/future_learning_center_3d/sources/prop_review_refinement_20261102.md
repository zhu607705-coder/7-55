# Six-prop review and controlled CPU render refinement

Base: a8fcc8e8bad878894e53234472492fa3916dfe9f. Independent art-review work only.

## Decisions from inspected images and source

- Enclosure glass shows visible Monte Carlo speckle at 64 CPU samples. Compare 64 and 512 samples with identical source geometry, glass, lights, camera, exposure and seed. No denoising, image enhancement, modified transparency or hidden glass in this comparison.
- Metal already has bounded PBR factors and modeled bevels. Do not arbitrarily increase metalness or add unsupported manufacturer details. The standalone web review uses local studio lighting so metal and bevels can be inspected rather than judged against an unlit background.
- Existing isolated sample loaders load all Draco assets as one promise. A missing asset/decoder can reject the whole group. The new independent review loads selected assets, offers plain-GLB fallback and per-asset errors/retry, and shares geometry/materials between instances.

## Reproduction

From this art directory:

```sh
blender -b --factory-startup -t 4 --python scripts/render_prop_comparison.py
python3 scripts/compose_prop_comparison.py
```

The render script reads independent Blender 4.3.2 sample files. It never saves them, rebuilds GLBs, or opens the original 5.2.2 building source. Output is `review/prop_refinement/`; the original submitted images remain untouched. The montage script only adds text and places the complete original pixels side by side.

Open `web/props_review.html` through a normal static HTTP server rooted at this art directory (not at `web/`, so source-document links also resolve). It is a separate review entry, not a game/main-building integration. Refer to the page's source notices: the enclosure shapes are dimension-led design studies, not verified H2C/P2S manufacturer replicas. Power-supply terminals are unconnected static geometry, with no specified electrical ratings or operational simulation.

For local review on an authorized machine, start `python3 -m http.server 8142 --bind 127.0.0.1` in this art directory, then open `http://127.0.0.1:8142/web/props_review.html`. This command was not run in the restricted cloud environment.

## Acceptance boundary

- Existing 435 non-browser checks passed (collision 88, floors 40, existing asset geometry 54, table dimension contracts 52, small props 90, equipment/real Draco decode 105, default encoding byte identity 6).
- New review tests: 95 passed using actual Three.js transforms/clone sharing with injected network loaders, plus a local dependency/path walk (11 modules, 36 GLBs). Total non-browser assertions: 530. This does not assert actual GLTFLoader browser/worker behavior.
- Browser launch is unavailable under the current sandbox's socket restrictions. No bypass or user-Mac access was attempted. Node tests and import/path checks do not prove WebGL appearance or pointer behavior.
- CPU comparisons are not browser screenshots. Higher sampling reduces stochastic noise but does not establish noise-free rendering, browser performance, physical material accuracy or exact manufacturer shape.
- No main-building, runtime Godot, dialogue, sign-in or progression/UI changes. No new tools, paid generation, external HDR download or geometry additions.

## Observed comparison

Both complete CPU image pairs were visually inspected. Speckle is reduced, not eliminated. The fixed glass-patch high-frequency residual (gray8 minus radius-2 Gaussian blur) drops 12.93→4.82 for the printer and 11.49→3.73 for the laser enclosure. This spatial statistic contains scene detail and is not an unbiased Monte Carlo variance estimate. It is recorded in `review/prop_refinement/glass_patch_metrics.json`; no filter was applied to delivered image pixels.

Sampling counts are maximum budgets: the saved source uses adaptive sampling (threshold 0.01), retained identically for both runs. They are not a claim that every pixel takes exactly 64 or 512 samples.
