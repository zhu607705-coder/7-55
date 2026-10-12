# Chaoyang west-inner L: genuine fixed-position object

The current user-authorized BUCT Godot exception applies to this separate campus entry. The repository's older no-new-Godot instruction is retained as historical context; the Zhejiang main story is unchanged.

## What changed

- The west-inner L proxy is replaced by the unchanged web-generated 1558 × 1010 RGBA image, registered at one scale `179/1558`, origin `(426, 591.9801026957638)`.
- Main bar, deep eastern return, western low annex and both exterior recesses remain distinct. Actual alpha controls picking. No invented building name, use, entrance or interior is added.
- One exact 1558-column foot-depth texture drives two complementary whole-PNG Y-sort passes. Three ground-contact polygons replace the old overfilled south-recess rectangles. Contact-chain simplification is bounded to 0.15 source pixels; rear contacts remain inferred.
- Four original-source leaf fragments restore 2,300 RGB pixels. Existing canopy ownership is excluded. No new trunk or canopy collider is invented.
- One web-generated narrow ground patch replaces 366 old-wall pixels inside `[476,675,95,22]`. Every source pixel outside that mask is retained. No whole-campus repaint or whole-footprint erased base is claimed.

## Fixed-object limitation

The approved complete campus image remains below this ordinary building. Full hiding, arbitrary movement and removal are unsupported and have no UI controls. The information card says so. The old UV body and its approximate full-silhouette paving are retired, but this is not a fully erased background.

## Interaction and character

The visual label is “西侧L形楼（场景对象）”. Object inspection does not increment visited, add a tour pin or change the original three-landmark route. Existing library and main-building cards remain usable. Original story state, 29 route waypoints, walkable paving, student assets, 18-source-pixel height, radius three, speed 88 and animation geometry remain unchanged.

## Verified

- Native object/selection/physics/card/state: 115 checks, zero failures
- Native source layers: 284 checks, zero failures
- Existing complete Chaoyang route and interactions: 115 checks, zero failures; continuous guided route completed in 743 physics ticks
- GPU whole PNG vs two passes: 63 pixels differ by at most one LSB; identical nonzero-alpha coverage
- 32 actual four-direction student depth samples across annex, main/east inner corner, return and western join: maximum difference one LSB, no out-of-tolerance overlap pixels
- Component measured delta: seven nodes and 8,402,492 texture bytes, using two body passes; these are not full-scene net performance figures
- Normal full-campus, neighborhood and neutral info card were visually inspected; the narrow repair has no obvious bright rectangle or old facade residue
- Final production-import GUI review passed: actual roof click opens neutral info without incrementing 0/3, close returns to map, actual north exterior-notch click does not select the building, and return reaches the chooser; no ERROR/RID diagnostics

## Tests

Use the existing isolated test runner after combined changes are installed. The new focused scene test is `tests/test_buct_l_building.gd`; GPU fixture is `tests/capture_buct_l_building.gd`. The final capture fixture uses the same imported Texture2D instance as production and asserts that mipmaps are present. Its final run has no raw-image export warning. The required body `.png.import` sets mipmaps on and alpha-border repair off; it must be tracked despite the repository’s general import-metadata ignore rule.

The first fixture incorrectly rebuilt raw-PNG mipmaps while production used default no-mipmap import. That proof was superseded after review. The final import-corrected proof and normal-map images were rerun; the original PNG is byte-identical.

The coordinator ran the combined Rongmao + L entry test: 1,236 assertions passed, but the limited stage lacked original-story assets and logged 47 ERROR plus two SCRIPT ERROR lines. That run is not a clean full-game acceptance. No full PCK export, whole-building relocation demonstration, interior, or median/p95 performance acceptance is claimed.
