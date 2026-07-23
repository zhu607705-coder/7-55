# Zijingang Campus Artwork

## Runtime ownership

- `zijingang_campus_plate.png` is the only campus map image loaded by Phaser. Its approved dimensions are `4516 × 3420`; it renders in one north-up, top-down source-pixel coordinate system without stretching.
- The plate owns buildings, roads, water, landscaping, plazas, and other static artwork. Phaser owns the player, fixed foot collision, subtle uniform depth scaling, camera, labels, interactions, story transitions, and the verified Basic Library and Moon Building occlusion crops.
- The campus keeps a `960 × 540` logical coordinate system but raises its canvas backing store to the displayed CSS size and device-pixel ratio, up to `3×`. Camera values receive the same multiplier, so native-resolution rendering does not change the visible world extent or interaction coordinates.
- The overview minimap remains intentionally absent.

## Calibration sources

- `source/topdown/campus_roads_source.png` supplies the primary connected road mask.
- `source/topdown/campus_water_source.png` blocks water inside manually opened areas.
- `source/topdown/campus_buildings_source.png` is retained for building-bound and occlusion calibration.
- `source/topdown/zijingang_schematic_reference.jpg` records the real-building correspondence used to identify `紫云碧峰`, `东区大食堂`, and the story destination `基础图书馆`.
- Source layers share the plate's `4516 × 3420` coordinate system and must not be positioned as separate runtime scenes.

## Movement, collision, and occlusion

- `zijingang_road_walkability_mask.png` is the reviewable nearest-neighbor expansion of the compressed runtime `4px` grid.
- Roads are walkable by default. Only the manually verified Basic Library east/south forecourt is added. Dense planting, water, buildings, and uncertain open-looking regions remain blocked.
- Landmark bounding boxes are visual metadata only and are never added as physics rectangles. The Basic Library solid is a measured polygon subtracted from its open forecourt. Purple Cloud/Bifeng and East Canteen use the separated road layer without additional collision polygons.
- The spawn is `(2550,650)`, on the road immediately south of `紫云碧峰`.
- The story library is `基础图书馆`. Its gate is `(3706,1696)` with radius `112`; the safe approach checkpoint is `(3805,1680)`.
- The `东区大食堂` campus gate remains `(3120,620)` with approach checkpoint `(3120,650)`. Normal exploration enters `canteen_interior / canteen_entrance`; its southeast exit returns to `campus_bootstrap / campus_canteen_gate` without resetting story progress.
- `基础图书馆` and `月牙楼` currently use clipped silhouettes from the same plate. `紫云碧峰` and `东区大食堂` occlusion are disabled until their silhouettes are manually recalibrated.
- The actor has half the former campus world size and the nominal default camera zoom is doubled to `1.1`. This doubles the map-to-actor ratio while preserving the actor's initial absolute screen size. Campus walk/run speeds are `110/160` world pixels per second.
- The camera deadzone is `300/960` of the current visible world width and `180/540` of its height. It is recomputed whenever zoom or backing resolution changes.
- Landmark labels use `18px` high-resolution text without a stroke. Their top edge starts `12px` inside the measured building roof so they remain attached to the building and clear the shared task bar.
- Manual collision polygons are authored in `scripts/calibrate-topdown-campus-runtime.py`. Landmark bounds, label anchors, occlusion polygons, and each building's `occlusionEnabled` switch are authored in `src/scenes/rpg/ZijingangCampusLayout.ts`.

## 手动修改方法

1. 建筑身份先以 `source/topdown/zijingang_schematic_reference.jpg` 为准，再到 `zijingang_campus_plate.png` 中测量运行时像素坐标；不要根据外形猜建筑名称。
2. 道路以外需要额外开放的广场写入 `scripts/calibrate-topdown-campus-runtime.py` 的 `WALKABLE_POLYGONS`；开放区内的建筑实体写入 `SOLID_POLYGONS`。修改后运行 `npm run map:zijingang:walkability`，不要直接编辑生成的 PNG 或 JSON。
3. 建筑遮挡统一写在 `src/scenes/rpg/ZijingangCampusLayout.ts`。`worldCenter` 和 `visualFootprint` 定义同源裁片范围，`occlusionPolygons` 描出实际轮廓，确认后把 `occlusionEnabled` 设为 `true`。
4. 建筑名称也读取同一个布局文件。标签位置由建筑实测顶部和 `CAMPUS_LANDMARK_LABEL_TOP_INSET` 计算，不要在场景文件中另写坐标。
5. 月牙楼当前只增加遮挡，不增加特殊碰撞。其北侧道路可行走范围约为 `x=3324..3399, y<=1130`，所以遮挡只需覆盖从该道路向南接近建筑的角色。
6. 修改后依次运行 `npm run map:zijingang`、`npm run typecheck`、`npm run build:single` 和 `npm run verify:single`，并在浏览器中从实际道路方向检查人物脚点和建筑前后层级。

## Rebuild and verification

- `npm run map:zijingang:rebuild` and `npm run map:zijingang:walkability` run `scripts/calibrate-topdown-campus-runtime.py`. They preserve the approved artwork, rebuild the compressed bitset and review mask, and synchronize all hashes.
- `npm run map:zijingang` is read-only. It verifies dimensions, hashes, story points, solid samples, entrance proximity, and connected routes from the spawn to the library, canteen, and canteen-hunt region.
- Retired wide-panorama and square-map builders must not overwrite this plate.

## Current selected asset

- Plate SHA-256: `57e27997d0c24a77dd758869bcc1bab8665b10496a77ec0f802986461ceb116d`.
- Mask SHA-256: `04f45dfe97cd7eab30cc5a4a170c7e2778536ec7c0f84245145b6d2dbf74824d`.
- Runtime manifest: `src/data/maps/zijingang-campus-runtime.json`.
- World: `4516 × 3420`; walkability grid: `1129 × 855`; cell size: `4px`; walkable cells: `158952`.
