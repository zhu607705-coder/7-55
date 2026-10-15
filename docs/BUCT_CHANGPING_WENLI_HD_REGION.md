# Wenli outdoor region: default high-detail replacement

This change is stacked on Draft #138, commit `72fcafd285dd388eed2735be71b60fa23f428548`. It does not merge #138 or #137. The Changping outdoor entry now enables the bounded region by default. Zhejiang story, interiors, route permissions and the student are unchanged.

## Scope and visible limits

- Source region: `[630,615,240,240]` in the original 950×1656 map, **3.66% of the campus image**. Full-detail core: `[642,627,216,216]`.
- Two genuine generated masters are **1254×1254 RGB**, not 4K. One fixed **1200×1200** runtime image contains coherent ground and tree-canopy detail. It does not repeat material strips.
- All nine existing east-road leaf masks remain source-resolution silhouettes. Their RGB within the enhancement samples the same final ground texture. Their masks, feet and world bounds do not move.
- The two-source-pixel outer collar is original RGB. The next ten pixels use a smooth transition. The new-to-old clarity transition remains visible, especially west/south at 4.8×. This is not a seamless whole-campus replacement.
- Courtyard A retains an approximately half-source-pixel boundary discrepancy. Its visible building aperture contains leaves and soil. The fixed green/dark color proxy is 88.8%; it also classifies some pale foliage and brown soil as non-vegetation. B and C proxy scores are 92.28% and 99.89%. The proxy thresholds were not loosened.
- Under-building ground is inferred, not surveyed. The original body, body transform, source-removal ownership and three physical colliders remain immutable.

## Art derivation and geometry

The first coherent master was retained. One bounded correction removed an unsupported northern tree/brick spur and lane paint, and expanded courtyard B's planting. The corrected webpage output repainted much of its exterior, so **only the predeclared local edit mask was composited**; every outside pixel remains identical to the first master. The allowed mask covers 27,904 master pixels (1.77448%).

A single smooth texture-only inverse displacement field aligns B's lower planted tip. Its compact support is `[684,750,62,72]`; it is zero outside the support, including all roads and leaf masks. It does not change world geometry, object coordinates, collision or the building texture. It is a regularized thin-plate field with a C1 boundary taper, smoothing 10 selected by the bounded distortion gate. A was not warped to improve its color proxy.

All 1,440,000 runtime texel centers were checked at 0.2-source-pixel pitch:

| Measurement | Result | Bound |
|---|---:|---:|
| Maximum texture displacement | 2.60375 source px | ≤3 |
| Minimum/maximum Jacobian singular value | 0.80224 / 1.21156 | 0.8–1.25 |
| Minimum determinant | 0.79560 | >0 |
| Maximum adjacent displacement delta / source px | 0.21139 | ≤0.25 |

The 21 fixed road cross-sections were never used to fit the field. On the final derivative, 18/21 full profiles have correlation ≥0.8, RMS drift 0.1472 source px, maximum 0.3. Three profiles cross the deliberately removed old body/shadow and remain explicitly low-confidence. Excluding only that frozen ownership yields 21/21, RMS 0.1574, maximum 0.3. This exclusion is not an error-shaped road mask and does not replace the disclosed full-profile results.

The source body/shadow clear union is forced to full new coverage. Its nearest ROI edge is 16.5 source px away, so its intersection with the transition collar is zero. Hiding the independent building also hides the new cast shadow; old body/shadow RGB does not reappear.

## Runtime and rollback

`wenli_hd_region.gd` prepares the profile, imported ground mip chain, exact decoded RGBA hash, R8 shadow and all nine original owners before changing the scene. A malformed/missing asset or profile leaves the #138 ground and original foliage intact. It rejects invalid types/nonfinite values and duplicate/missing leaf owners, including a duplicate substitution that preserves the misleading aggregate 798-pixel count.

On commit it hides the old inferred body ground, inserts the coherent ground and independent shadow, and assigns nine lightweight materials. On uninstall/exit it restores every old material/filter and ground visibility, releases its new resources, and hides its drawing children. Repeated installation is a no-op; detach/re-add safely restores legacy state until an explicit reinstall replaces the retired component.

- Original leaf alpha: 798 source pixels, including 17 outside the ROI
- Original leaf depth baselines: 680, 701, 722, 744, 764, 785, 796, 842, 858
- New collision bodies/navigation polygons/derived leaf RGB textures: **0 / 0 / 0**
- Fixed texture budget including all mip levels: 7,679,680 bytes RGBA8 ground + 1,919,920 bytes R8 shadow = **9,599,600 bytes**, below 12 MB
- Component-owned retained CPU RGB images: zero in steady state. This is not a claim that the engine retains no image data. Verification temporarily duplicates the imported image, reads decoded RGBA (5,760,000 bytes), and constructs the shadow mip chain. `get_image()` may expose a shared engine cache, so verification duplicates before clearing mips; a dedicated test guards this.
- The final manual movement/selection/entry-return/re-entry process peaked at **485,486,592 bytes RSS** and exited normally with no errors. The native GPU test's whole-process maximum RSS was 495,837,184 bytes before the validation-image duplication fix. This includes the entire campus, renderer and test viewports and is not the component's incremental memory or the final post-fix peak.

## Validation and reproducible commands

Run from the repository root after the standard Godot import:

```sh
bash scripts/test-buct-changping-hd-region.sh godot_native headless
xvfb-run -a bash scripts/test-buct-changping-hd-region.sh godot_native proof
# Existing isolated object contract is still strict:
xvfb-run -a bash scripts/test-buct-changping-wenli.sh godot_native proof
```

The existing native CI workflow explicitly runs the new source/headless/GPU checks and uploads their results. The standard native scanner also discovers `test_buct_changping_hd_region.gd`. The old Wenli test/capture explicitly disable only the new region; their 7,685-pixel ownership and all original assertions are unchanged.

Local results before publication:

- New source checks: **28/28**; old Wenli source checks: **16/16**
- New default/fallback/lifecycle/physics checks: **584/584**
- Related original headless suites: Wenli 1032, east road 41, first teaching 948, library 1068, Liu Lake 59, south bridge 50, all zero failures
- Native rendered checks: **16/16**, including default scene, actual settled body LOD, all nine leaf layers at both zooms, exact ROI exterior ownership and nine actual-student before/behind foot fixtures
- Entire default-scene comparison: **0 changed pixels outside the ROI**; 210,811 changed pixels inside, at the fixed 2.1× framing
- All-nine isolated same-texture comparison: 2.1× has six pixels differing by one RGB LSB; 4.8× is exact
- Clean new-resource import and packed 28 MB minimal-stage export/load: passed. The packed default scene loads the R8 bin, all nine materials and the unmodified imported mip chain. This is a scoped export test, not a claim of a complete game distribution

The automated continuous-walk recording contains 223 frames at 1280×720, 11.15 seconds, H.264, 2,957,660 bytes. It covers 958.09 source pixels with zero off-route frames, unchanged speed 88 and student height 18. The first section is the default 2.1× framing; the final two seconds are explicitly labelled 4.8×. This is fixed-20-FPS offline sampling, not a real-time FPS benchmark (llvmpipe recording took about 59 seconds).

Actual desktop acceptance also passed: Up450ms/Down250ms with visible motion and facing, roof selection, Escape close, return to entry, Changping re-entry at the normal south gate, and normal window close. Nine screenshots and an error-free process log were retained separately.

### Preserved diagnostic failures

The first capture froze normal scene processing and changed camera zoom without refreshing the independent building's RGB LOD. It therefore showed a falsely soft 4.8× building. The fixture now waits for the actual canvas and calls the existing update function. The settled scales/LODs are 2.1 / 2.45114 and 4.8 / 1.25849. Production updates this every frame; no body/shader/art change was made.

A full-scene “hide all leaves” comparison yielded 113 changed pixels, maximum 25 LSB. That is not a valid pure-ground RGB oracle. CPU localization found 96 pixels in the last leaf's old-source south collar/outside area (`y=853..858`): the existing leaf uses NEAREST, while `StaticUnseparatedCampus` uses inherited LINEAR sampling. The underlying RGB matches a bilinear sample of the original source within one LSB. Four screen pixels lie exactly on source row 855's nearest-sampling boundary and use row 854 after GPU rounding. The other 17 differences are ≤1 LSB in enhanced sampling. No building/shadow overlaps these points; the earlier possible-object-overlap hypothesis was rejected. The old sampling behavior is preserved, supported by the exact zero exterior-change test. The first failed render report remains a failure, not rewritten as a pass.

The first packed probe caught validation mutating the returned CPU image's mip metadata. The corrected code duplicates the validation image and the 584-check suite plus packed probe pass. Neither the texture RGB nor GPU sampling changed.

## Provenance

| Asset | SHA-256 |
|---|---|
| First generated 1254² master | `73744c50370cebbcaa0bb6fd5d010370e8b844309a63dadea1e2504c0e8c5ab3` |
| Local-correction 1254² master | `eab760185cb767964c8240c55b5e68526f5cb4a163e9444f658fb73d4098faa3` |
| Final runtime PNG | `2f1a8caa6e406cd8ad16113acf402b94a220013aeea69650f9056c7ad3e3ac63` |
| Final decoded RGBA | `30a828313e2f7649b4fd99db07b4f5b631c2d119bcebfdc4cee9e93c42298ff0` |
| Independent R8 shadow | `5dd2f13b01127c909927c54dece86e3d8a66f6c181d5d6e15eb4b65056b956ed` |

Original generated masters, prompts, rejected experiments and native movie frames are retained with the working evidence, not shipped as game resources. Runtime uses only the approved fixed derivative and R8 shadow. Detailed geometry/provenance is in `wenli_hd_region.json`; machine-readable acceptance is in `BUCT_CHANGPING_WENLI_HD_REGION_VALIDATION.json`.
