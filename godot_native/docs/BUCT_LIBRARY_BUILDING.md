# BUCT library: one genuine layered building

This change builds on the BUCT walk entry. It replaces **only the connected Chaoyang library**. Its world anchor remains `(749,570)` and the complete body frame remains `[620,419,251,160]` in the original 1448×1086 campus coordinates. The other **43 groups remain legacy source-campus UV groups**. They are not counted as completed transparent building reconstructions.

## Actual assets and source limits

| Layer | PNG dimensions | Registered world rectangle |
|---|---:|---:|
| True-alpha library body | 1570×1001 | [620,419,251,160] |
| Continuous opaque repaired ground | 1528×1029 | [620,410,251,169] |
| Independent translucent north/west shadow | 1528×1029 | [620,410,251,169] |

The three original PNG files are retained byte-for-byte. Body alpha below 0.04 is discarded at runtime and body alpha at or above 0.95 is clamped solid. The independent shadow remains translucent. The body retains the curved south facade, side wings, southwest attached rounded mass and dark central equipment roof. There is no invented courtyard opening or verified interior entrance.

These assets were reconstructed in the style of the supplied campus illustration using webpage image generation on 2026-10-12. This is **not source-pixel identity**: the body envelope differs by approximately 1–3 original pixels. Repaired hidden ground is conceptual paving, and peripheral trees/paths were regenerated. The expanded repair begins at y=410 so the original north shadow at y=416–418 cannot remain as a baked remnant. The original source image remains unchanged outside the overlaid repair.

### Bounded ground-edge integration

The generated ground PNG is not placed as an opaque rectangular tile in the campus. `library-ground-coverage.bin` is a 251×169 single-channel **geometry coverage mask**, built from the old library silhouette and its two old cast-shadow polygons. Every protected source-pixel center is fully replaced, with a two-source-pixel opaque guard. Coverage tapers only between two and six pixels beyond those polygons. This restores the original peripheral trees and paths wherever replacement is unnecessary. The dependency-free `campuses/buct/tools/build_ground_coverage.py --check` reproduces every binary byte from the authored polygons. Nothing is rendered outside the registered `[620,410,251,169]` patch. The mask does not rewrite any source or generated PNG.

### Static repair cache

The inherited scene contains a 6188-cell paving TileMap rendered into a SubViewport. The standalone debug scene retains `UPDATE_ALWAYS`. The playable scene requests `UPDATE_ONCE` after attaching the campus. The first frame generates the static repair texture; the retained ViewportTexture continues to supply all legacy repair polygons, including when objects are hidden. No cells, textures, collisions or repair polygons are deleted.

`tests/verify_buct_repair_performance.gd` compares uncapped actual frame timing and draw calls at the same 1440×900 overview, with both update modes. The same fixture is run against the exact #119 campus baseline. It also compares visible and hidden-library pixels before/after caching. Performance results describe the measured llvmpipe environment only.

The small information-card font is a Noto Sans CJK SC subset. Its full OFL notice is retained in the export-included `library-assets.json` and beside the font as `FONT-LICENSE.txt`.

Public provenance is limited to the method/date, source dimensions, registration and asset hashes in `campuses/buct/data/library-profile.json`. No private conversation links, Library references, account details or machine paths are included.

## Runtime retirement and replacement

The old library `SourcePixelSilhouette`, both source-baked shadow polygons and four old physics bodies are removed from the packed scene. The old library-specific placeholder underlays are removed. The library is also removed from the old silhouette hit-test dictionary and old four-footprint navigation blockers.

The replacement owns one `StaticBody2D` with six source-inferred collision polygons. A closed central solid prevents traversal through the equipment-roof region. These are gameplay inferences, not a surveyed floor plan. Navigation uses the same six new footprints with its existing clearance, and responds to the replacement object's visibility and transform. The closed walking corridor and existing 3-pixel-foot visitor are otherwise unchanged.

The continuous ground Sprite is outside the movable building. Hiding the library turns off its body, shadow, native physics and navigation blockers. It leaves the ground fixed. Library information contains touch-sized Hide/Show and Reset controls beside Return. Map and overview clicks use actual building alpha. Transparent background and shadow pixels do not count as building selection. The nearby-label button can still intentionally open information about a hidden building.

## Native whole-campus depth

The isolated inspection prototype's two global z passes are not used to render the full campus. They would be incompatible with old trees sharing native Y-sort.

Instead, the full-campus adapter partitions the **new independent RGBA building image** into source-pixel-width quads. Each quad's depth is its measured local facade foot. Exactly equal adjacent depths are merged without geometric approximation. The resulting **140 native Polygon2D strips share one unchanged texture and one material**. There is no per-strip image copy, no original-campus UV extraction and no additional wrapper Node for each strip. They remain one building object.

All body strips, existing old UV objects, old tree crowns and the existing visitor remain at z=0 under the same native Y-sort. Terrain is behind them, and ground shadows stay below actors. Source UV boundaries are shared exactly between adjacent strips to avoid transparent seams. Soft-alpha-only outer columns inherit their nearest solid-edge depth so antialiasing pixels are not dropped.

This avoids a globally foreground library pass covering trees that should be in front of it. It also lets the west annex and different x positions along the curved facade sort at their actual local feet. The current library has no verified open interior courtyard. An open courtyard would require separately authored multiple depth surfaces rather than pretending one bottom edge per x represents every wall.

## Verification and compatibility

- Focused native source-layer, actual-route and isolated entry/mobile tests cover the replacement, original South gate → Main building → Library route, keyboard/touch controls, information return, hide/reset, navigation and save isolation
- The existing story scene, State autoload, save schema, visitor implementation and BUCT action ownership remain unchanged
- The five existing viewport sizes remain covered: 1440×900, 1280×720, 390×844, 844×390 and 667×375
- `tests/verify_buct_library_render.gd` is an actual graphics-context fixture. It records outside-repair preservation, strip/full-texture comparison, local wall and existing tree/actor ordering, hide/absent comparison, and measured rendering/node cost
- Pixel equality of the new texture's alternative renderings is **not** equality to the original campus library artwork
- Native OpenGL proof on llvmpipe means actual software OpenGL rendering, not a claim of hardware GPU acceleration or physical mobile-device testing

Use the existing isolated runners:

```sh
node godot_native/tools/sync_source.mjs
node godot_native/tools/test_buct.mjs
GODOT_TEST_REPORT=/tmp/buct-library-report.json node godot_native/tools/validate_native.mjs
```

Do not invoke the save-writing entry fixture against normal user data. The runner creates and checks fresh disposable save directories. Public graphics results are summarized separately once captured; image files and private review paths are not shipped as runtime assets.

## Measured first-building cost

Actual Godot 4.6.3 Compatibility rendering on llvmpipe, at the same 1440×900 overview camera, with vsync disabled. These are measured software-renderer timings, not a hardware or all-buildings guarantee.

| Exact campus variant | Repair update | Draw calls | Median frame ms | p95 ms |
|---|---|---:|---:|---:|
| #119 baseline `b6f3f260` | ALWAYS | 5917 | 45.424 | 57.872 |
| #119 baseline `b6f3f260` | ONCE/cache | 178 | 13.457 | 26.589 |
| Genuine library integration | ALWAYS | 6053 | 53.420 | 77.154 |
| Genuine library integration | ONCE/cache | 314 | 16.659 | 31.673 |

Caching removes **5739 inherited static draw calls**. The library replacement adds **136 net draw calls**; in the cached comparison its observed median cost is **+3.202 ms**. Whole-scene node count changes from 432 to 573 (+141). The library owns 152 nodes, including 140 merged rendering strips, compared with 12 nodes in its legacy object. This first building is usable; hundreds of similarly segmented buildings have not been tested.

In both variants, visible and hidden-library images before/after caching differ by zero pixels. Changing TileMap visibility while cached leaves the repair texture unchanged; explicit refresh changes 1,572,528 pixels, confirming that it is a retained texture rather than a hidden repair layer. Godot's scene-side property still reports UPDATE_ONCE after consumption; that property is not used as a cache-success assertion.

The new strips and a single complete sprite of the same new RGBA differ at 52 pixels by at most one 8-bit channel level. No pixels outside the repair rectangle change, and hidden-body versus absent-object rendering is identical. This compares two renderings of the new asset, not the original artwork. Full results are in `BUCT_LIBRARY_VALIDATION.json`.

## Release-safe initialization

Configuration calls execute as ordinary statements, followed by explicit failure handling. No production initialization depends on `assert()`, which release builds can omit. Static regressions check this contract. The exported native PCK was loaded independently and verified for all new assets, mask bytes, strips, collision, selection and hide/reset. That probe used the available debug engine. Release templates were not installed, so a release executable was not tested; this limitation is not hidden by the packed-resource result.

## Final local verification record

- Initial full native aggregate: 310 stages, 286 passed, 24 failed, exit 1. Failures include missing source dependencies, an unconverted OGV, and the full-campaign rescue assertion
- An interrupted retry has only 14 confirmed passes, 2 failures and 14 unconfirmed stages; its incomplete JSON is not used as a pass
- First complete workspace retry: 30 stages, 29 passed, 1 failed, exit 1. The lake fixture correctly refused its formerly unsupported temporary-root location
- A narrowly scoped two-file test adaptation adds declared/actual normalized path checks, a launcher creation receipt and rejection of existing primary, backup or pending saves. Seventeen rejection cases preserve sentinel bytes; the fresh lake parity case passes 416 checks and 25 native saves, exit 0
- Final complete rerun of all 24 original failed stages plus six affected/setup checks: **30 passed, 0 failed, exit 0**. Source layers 284, playable route 115 and entry/mobile 312 assertions pass. This is a split-run result, not a clean single 310-stage run
- Actual native UI covers full-campus selection, hide/reset/return, route 3/3, portrait and landscape controls, two human campus/menu round trips and normal shutdown. The final reset status was manually verified as “图书馆楼体已复位”
- The immutable commit's remote CI is checked separately after publication. No release executable or physical mobile-device test is claimed

The test-only lake adaptation supports a fresh workspace-backed temporary root when ordinary temporary storage is constrained. It does not authorize arbitrary user directories, and it does not change runtime saves or gameplay. Other legacy test fixtures may retain their own temporary-root assumptions. The public machine-readable record retains each run's counts and exits without private machine paths.
