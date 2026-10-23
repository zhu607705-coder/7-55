# 7:55 Release Assets

## 20261024 — Original-repository merge delivery

- Delivery: [7-55 PR #164](https://github.com/zhu607705-coder/7-55/pull/164), target [main](https://github.com/zhu607705-coder/7-55/tree/main); implementation [godot_native](godot_native/README.md). This merge carries the 20261023 source and asset batch, plus a bounded async test-wait correction and current delivery records.
- No new artwork, font, third-party dependency or archive is introduced on this date. Original asset provenance, source hashes and earlier acceptance dates below remain historical evidence. Source merge does not establish a successful production deployment.

## 20261023 — Current Godot source review

- Current source: [merged Godot PR #2](https://github.com/zhu607705-coder/7-55-godot/pull/2), merge `e66550c2be4f8d17eed0fcb2454d9a0730eda9fb`; original-repository sync: [7-55 PR #164](https://github.com/zhu607705-coder/7-55/pull/164). Implementation directory: [godot_native](godot_native/README.md). Both repositories are currently public.
- The selected source includes current runtime assets, original font/art sources, authoring tools and provenance records. Local RodinBridge editor installation, its activation setting, Python bytecode and Blender automatic backup are excluded. Existing third-party licenses remain attached to their assets; the original project source uses Apache-2.0.
- [Lazy-loading evidence](godot_native/docs/PERFORMANCE_LAZY_LOADING_20261023.md) and [native Learn reconstruction](godot_native/docs/NATIVE_LEARN_REBUILD_20261023.md) identify their exact tested inputs and limitations. WASM/PCK exports and temporary QA output remain outside the source submission. This delivery creates no new Release archive or production deployment.
- The frozen `examples/qizhen_blender_nearshore/source/qizhen_north_bank.blend` is restored to its existing `SOURCE_SHA256.json` receipt in the current review tree. The local working Blender revision remains untouched; it has not replaced the accepted frozen sample.

## 20261022 — Two-repository integration and local preview

- PR sources, merge commits and preservation scope: [two-repository receipt](godot_native/docs/TWO_REPOSITORY_MERGES_20261022.json). The current local Godot Web candidate is `godot_native/exports/web-pr160-integrated-20261022/`; its exact source-input digest, engine and desktop/touch evidence are in [the adaptation receipt](godot_native/docs/PR160_LOCAL_ADAPTATION_20261022.json).
- The isolated dorm sample reuses its original player texture with uniform scale1.0 and a calibrated source-foot pivot. No new character master was generated for this adjustment. [Measured sizes and render review](godot_native/docs/DORM_CHARACTER_SCALE_20261022.json). The debug-only sample scene and consumer script remain excluded from production presets.
- Exported WASM/PCK, formal-save copies, logs, temporary screenshots and raw generation files are not added to ordinary Git submission. Selected actual-render review copies are kept outside the repository. Existing third-party artwork and licenses are unchanged by these merges.

## 20261021 — Morning opening artwork

- Webpage-generated dorm/player opening and original design provenance: [opening design record](godot_native/docs/OPENING_WEB_DESIGN_20261021.json).
- `godot_native/web/boot_art/morning_room.webp` is a browser-only lossless derivative of the webpage-generated oblique dorm master: `160 × 160` logical pixels, integer4x source `640 × 640`, `7004` bytes. It uses19 colors from the locked32-color palette; all25,600 source4×4 blocks are uniform. Exact hashes and original PNGs stay in the design/verification record; the WebP is the production source.
- The scene uses the existing pixel dorm and player as references. The user selected warm morning sunlight falling on the sleeping protagonist and an opening that fills the available screen. [First-batch acceptance](godot_native/docs/ART_DIRECTION_ACCEPTANCE_20261021.json) records20 actual Godot browser cases/421 checks and separate persistence, raster and UI evidence.
- The image has a content-hashed browser URL, stays outside the PCK and cannot gate verified Godot readiness. This entry does not indicate a public deployment.

## 20261021 — Library, theater and direct-touch local candidate

- Implementation and design: [library/theater and direct touch](godot_native/docs/LIBRARY_THEATER_DIRECT_TOUCH_20261021.md).
- Frozen build and validation scope: [20261021 acceptance](godot_native/docs/LIBRARY_THEATER_ACCEPTANCE_20261021.json).
- Independent generated objects: [prompt, alpha and SHA-256 provenance](godot_native/docs/LIBRARY_THEATER_ART_PROMPTS_20261020.json); [web High copy provenance](godot_native/docs/THEATER_REHEARSAL_COPY_PROVENANCE_20261020.json).
- Godot Web build output is local under `godot_native/exports/web-library-theater-tiled-20261021/`. It is a candidate under acceptance, not a published Release asset. Exported PCK/WASM files, raw generation downloads, screenshots, test saves and logs remain outside ordinary Git submission.
- Seven lossless panorama tiles are regenerated by `native:sync` from the original source plate. The generator and manifest belong to source control; the derived PNGs are included in the portable build and Chapter3.5 content packs.
- The private review destination is [PR #1](https://github.com/zhu607705-coder/7-55-godot-20261020/pull/1); this entry does not claim that the new working-tree changes have been pushed or merged. Original public hosting is unchanged.

## 20261019 — Native integration review candidate

- Source branch: [codex/godot-complete-20261019](https://github.com/zhu607705-coder/7-55/tree/codex/godot-complete-20261019), targeting `godot-version` for review. No merge to `main` or replacement release is claimed.
- Runtime and handoff evidence: [integration report](godot_native/docs/FULL_INTEGRATION_20261019.md), [push acceptance](godot_native/docs/PUSH_ACCEPTANCE_20261019.md).
- Rebuild the complete native source archive with `npm run native:package:all`; it includes generated source assets and all registered original prototype evidence. The ZIP, PCK, checksums and package validation are local outputs under `godot_native/exports/`, not ordinary Git blobs or published Release attachments.
- Retained Web release validation: 36/36. Native latest evidence: 413 passing stages, with original runs and focused reruns recorded separately. Exact-head Linux CI, manual full chapters and physical-device acceptance remain separate gates.

## 20260905 — branch prerelease, not merged into main

- Release: [7:55 Demo 20260905 — 未合并 main](https://github.com/zhu607705-coder/7-55/releases/tag/demo-20260905)
- Source and resources: [codex/release-20260905](https://github.com/zhu607705-coder/7-55/tree/codex/release-20260905)
- Single-file game: [7-55-demo-20260905.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260905/7-55-demo-20260905.html)
- Single-file checksum: [7-55-demo-20260905.html.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260905/7-55-demo-20260905.html.sha256)
- Implementation archive: [7-55-implementation-20260905.zip](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260905/7-55-implementation-20260905.zip)
- Implementation checksum: [7-55-implementation-20260905.zip.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260905/7-55-implementation-20260905.zip.sha256)
- Single-file size: `234383011` bytes
- Single-file SHA-256: `f1718c141da897c5595c4d8f00ee6ef17059ec8bd45324377772e4b45a00ce28`
- Implementation source: the commit tagged `demo-20260905`, including all tracked source, assets, scripts and documentation. The archive root is `7-55-implementation-20260905/`. Exact ZIP hash is supplied in the attached checksum; it is intentionally not embedded into a file inside the ZIP.
- Local release gate: `npm run validate:release`, **34/34**, `199487ms`, including typecheck, story/map/audio contracts, production build, single-file build and three browser smoke routes.
- Targeted wall validation: Chromium and Firefox desktop plus WebKit `390×844`; real keyboard traversal across the bakery north wall, classroom 104 north wall and classroom 104/105 partition. Foot-box bottoms stop at source `y=264/248/584`. Covered player pixels retain 22% visibility; front-side pixels recover fully. Final production WebKit and offline Chromium repeat these paths with no page/console errors or document overflow.
- Scope also includes the already recorded loading improvements, lossless runtime maps, theater entrance/charging changes, inventory simplification, fishing rhythm rewrite and A-version item/story copy. Detailed evidence and limits are in `project-development-report.md`.
- This is a branch prerelease. No merge or new `main` CI result is claimed.

## 20260904

- Release: [7:55 Demo 20260904](https://github.com/zhu607705-coder/7-55/releases/tag/demo-20260904)
- Single-file game: [7-55-demo-20260904.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260904/7-55-demo-20260904.html)
- Single-file checksum: [7-55-demo-20260904.html.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260904/7-55-demo-20260904.html.sha256)
- Implementation archive: [7-55-implementation-20260904.zip](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260904/7-55-implementation-20260904.zip)
- Implementation checksum: [7-55-implementation-20260904.zip.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260904/7-55-implementation-20260904.zip.sha256)
- Single-file size: `269164832` bytes
- Single-file SHA-256: `79297b91ac4b4c2e43617a4ed29d184e4bc20b76eccadc921e0f8ff77e0ccb08`
- Implementation archive size: `572766151` bytes
- Implementation archive SHA-256: `a5aa5408e1dde9bfe4f0e8ddfbe46041af12083e5c8fd8a8ad10c2b32836b828`
- Implementation source commit: `37d5ca6b8b044d1304a9674db4609da3c0254277`
- Pull request validation: [Web CI 33873949256](https://github.com/zhu607705-coder/7-55/actions/runs/33873949256) — success
- `main` validation: [Web CI 33874278561](https://github.com/zhu607705-coder/7-55/actions/runs/33874278561) — success
- Build: `npm run validate:critical`, `npm run validate:release`, `npm run build:single`, `npm run verify:recording-mode`
- Runtime checks: `390×844` phone, `1440×900` theater RPG, and `1440×900` Chapter 4 RPG browser smoke routes passed. The standalone HTML contains `2` inline scripts and `1` inline style. The implementation archive contains all `1243/1243` tracked files and passes `unzip -t` plus local SHA-256 verification.

## 20260903

- Release: [7:55 Demo 20260903](https://github.com/zhu607705-coder/7-55/releases/tag/demo-20260903)
- Single-file game: [7-55-demo-20260903.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260903/7-55-demo-20260903.html)
- Single-file checksum: [7-55-demo-20260903.html.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260903/7-55-demo-20260903.html.sha256)
- Implementation archive: [7-55-implementation-20260903.zip](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260903/7-55-implementation-20260903.zip)
- Implementation checksum: [7-55-implementation-20260903.zip.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260903/7-55-implementation-20260903.zip.sha256)
- Single-file size: `268864910 bytes`
- Single-file SHA-256: `ce7734e3071e112d38b9363ad48863bcb1c8431446f0e99d8576760807825041`
- Implementation size: `569681321 bytes`
- Implementation SHA-256: `9db27dc7dc7fa226334df02d8167351ca2dc8cc3cae38d9fa8b64279859c891e`
- Implementation source commit: `75fec8a3ef12c77bb164dfad1fe5cc5f16038a9e`
- Pull request Web CI: [run 33742422443](https://github.com/zhu607705-coder/7-55/actions/runs/33742422443) (`success`)
- Main Web CI: [run 33742760526](https://github.com/zhu607705-coder/7-55/actions/runs/33742760526) (`success`)
- Build commands: `npm run validate:critical`, `npm run validate:release`, `npm run build:single` and `npm run verify:single`
- Runtime checks: phone mobile, theater RPG, Chapter 4 RPG, source-pixel editor data, direct single-file structure, source archive integrity, and SHA-256 verification

## 20260830

- Release: [7:55 Demo 20260830](https://github.com/zhu607705-coder/7-55/releases/tag/demo-20260830)
- Single-file game: [7-55-demo-20260830.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260830/7-55-demo-20260830.html)
- Single-file checksum: [7-55-demo-20260830.html.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260830/7-55-demo-20260830.html.sha256)
- Implementation archive: [7-55-implementation-20260830.zip](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260830/7-55-implementation-20260830.zip)
- Implementation checksum: [7-55-implementation-20260830.zip.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260830/7-55-implementation-20260830.zip.sha256)
- Single-file size: `258674356 bytes`
- Single-file SHA-256: `938084a731b44b3f2e0641499899071d3c0a13158e31ef33a177527cdfc00001`
- Implementation size: `555758982 bytes`
- Implementation SHA-256: `462e158fb18f3aa50bd1ebc29709b75395482cd5c4ccd7d29b58434a5646b7fa`
- Implementation source commit: `f41e78b4c9d34f7b1559e2fadc53a7a76d17bec5`
- Main Web CI: [run 33286229966](https://github.com/zhu607705-coder/7-55/actions/runs/33286229966) (`success`)
- Build commands: `npm run validate:release`, `npm run build:single` and `npm run verify:single`
- Runtime checks: phone mobile, theater RPG, Chapter 4 RPG, direct single-file structure, source archive integrity, and SHA-256 verification

## 20260827

- Release: [7:55 Demo 20260827](https://github.com/zhu607705-coder/7-55/releases/tag/demo-20260827)
- Single-file game: [7-55-demo-20260827.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260827/7-55-demo-20260827.html)
- Single-file checksum: [7-55-demo-20260827.html.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260827/7-55-demo-20260827.html.sha256)
- Implementation archive: [7-55-implementation-20260827.zip](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260827/7-55-implementation-20260827.zip)
- Implementation checksum: [7-55-implementation-20260827.zip.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260827/7-55-implementation-20260827.zip.sha256)
- Single-file size: `252403148 bytes`
- Single-file SHA-256: `1b6d6909cc22507614e37b65629c8eb2cd1f640ab00a4b54ef51171275ba38ec`
- Implementation size: `551053650 bytes`
- Implementation SHA-256: `bb263c0b674e5fe5e126988bae21e6997cdc3139e20c4b93741871d087698bff`
- Implementation source commit: `7f1f5e5a9ff0fb7d1cb904d13f96604298ec01c5`
- Main Web CI: [run 33086839856](https://github.com/zhu607705-coder/7-55/actions/runs/33086839856) (`success`)
- Build commands: `npm run build:single` and `npm run verify:single`
- Runtime checks: direct `file://`, Chapter 4 Phaser checkpoint, source-pixel collisions, and player depth

## 20260826

- Release: [7:55 Demo 20260826](https://github.com/zhu607705-coder/7-55/releases/tag/demo-20260826)
- Single-file game: [7-55-demo-20260826.html](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260826/7-55-demo-20260826.html)
- Single-file checksum: [7-55-demo-20260826.html.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260826/7-55-demo-20260826.html.sha256)
- Implementation archive: [7-55-implementation-20260826.zip](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260826/7-55-implementation-20260826.zip)
- Implementation checksum: [7-55-implementation-20260826.zip.sha256](https://github.com/zhu607705-coder/7-55/releases/download/demo-20260826/7-55-implementation-20260826.zip.sha256)
- Size: `252290377 bytes`
- SHA-256: `8dbd57ee42f5acadcc4de0cb07006486a918bc97f9b80759508e902981467073`
- Build commands: `npm run build:single` and `npm run verify:single`
- Runtime checks: local HTTP, direct `file://`, story navigation, and RPG checkpoint recovery

The HTML and implementation archive are generated Release assets and are intentionally excluded from ordinary Git history.

## 20260906 源码整合

当前主线与第四章细节任务的合并范围、来源和验证状态见 [整合记录](docs/releases/20260906-integration.md)。本次为源码上传，既有 Release 下载链接仍对应其原始日期，未生成 20260906 单文件游戏包。


## 20261021 梁祝细像素舞台、演员与一桌二椅

- 规范升级为 `godot_native/docs/art/ART_BIBLE.md` v1.1：旧构图单位内绘制5倍线性细节，舞台原生1200×675、角色单格120×160；原世界坐标与玩家碰撞未变。本批没有把整库旧素材冒称为已重绘。
- 通过已授权的ChatGPT网页生图与Remove Background制作原创匿名演员、空舞台和桌椅。两张真实剧照只作服装/水袖/台面参考；原照片、面孔和原唱未打包进游戏。来源、提示词、原稿SHA及派生步骤见 `godot_native/docs/LIANGZHU_ART_PROVENANCE_20261021.json` / `LIANGZHU_PHOTO_RESEARCH_20261021.json`。
- 实际消费者为 `godot_native/scripts/presentation/liangzhu_performance.gd` 与共享StagePlate，排练场也用同一舞台和左翼桌椅。`godot_native/assets/native/liangzhu_performance_20261021/` 含stage.png、actors.png、table.png、chair_left.png、chair_right.png及家具manifest；32色锁定色板、角色每人跨四姿势≤24色、alpha0/255。独立脚基线与深度排序保留完整桌腿、水袖与椅背，不用桌子假造坐姿。
- 演员使用每人15个真实Bone2D与左右腕挂点的cel/rig组合；参考固定MIT Godot官方骨骼示例的结构原则，没有复制示例美术，也不是已完成网格蒙皮。见 `godot_native/docs/LIANGZHU_ACTOR_RIG.md`。
- 演出内容唯一数据为 `godot_native/data/native/liangzhu-performance.content.json`：54秒原创浓缩三场、15条中文对白/短词cue及三处互动。用户确认先交付可玩QTE，唱段后接；当前没有新增唱段音轨。视频是独立GPU被动观看预览，不是玩家QTE通过回放。最终交付与核验入口见 `godot_native/docs/LIANGZHU_QTE_ACCEPTANCE_20261021.json`。

## 20261021 Revised ZJU rider and reusable Rodin campus modules

- Runtime assets: `godot_native/assets/native_755/ride/rodin/`. Original fictional adult rider v2 uses 90,612 triangles, white lace-up running sneakers and a navy crewneck campus sweatshirt. The exact published ZJU standard seal is applied to a skinned back-cloth patch. Apparel references guide an original game costume; this is not an exact official product replica.
- Hyper3D / Rodin generated the rider and three static module types: glass-canopy frontage, willow-side bench/rail and theater foyer. First human was superseded after user feedback. Total generation consumed3 existing credits; balance220. Non-secret task/hash receipts, exact built-in imagegen reference prompt and source links are under `godot_native/docs/art/RODIN_*20261021.json` and `reference/`. Credentials, signed download URLs and private subscription keys remain outside the project.
- Blender5.2.2 heat-weighted15-bone skin, at most4 normalized influences, zero unweighted vertices; native Godot4.7.2 applies bind-length IK to real palm/sole contacts. Source bike simulation, lanes, collision, controllers and saves retain their authority. Public pelican demo informed movement/camera only; no unlicensed code or model copied.
- The original generated willow was bare; native authored hanging leaves complete that silhouette. Generic road trees and props remain procedural. Architectural compositions reference public ZJU photos rather than claiming exact campus surveying. All34 new model/texture/remap runtime entries are in deferred third-chapter packs.
- Local evidence: `godot_native/docs/art/RODIN_CAMPUS_ACCEPTANCE_20261021.json`,19 native stages plus533 actual desktop Chromium checks, with front/back Godot screenshots. Physical mobile, full campaign and broad performance acceptance remain separate.

## 20261021 Rodin v2 art rejection and multiview candidate

The user rejected the prior rider shoulder/back silhouette and adjacent campus scenery. Prior runtime test counts do not constitute art approval. `godot_native/docs/art/RODIN_SHOULDER_MULTIVIEW_REVIEW_20261021.json` records the rejection, actual rest/ride comparison, coherent imagegen references and a separate four-view Rodin reconstruction. The new19-bone candidate and normalized unrigged GLB remain under `docs/art/reference/student_v3/candidate/`; no active model replacement or new browser export has occurred. `cycling_back.png` is the requested posed back/garment/shoulder reference. Exact built-in prompts and non-secret generation receipts are retained. Top/bottom images remain supplementary because the generated pole projections are imperfect; only F/B/L/R were submitted. New task consumed1 existing credit; balance219.

## 20261021 Pelican cycling direction

The current native cycling avatar is an original17-bone weighted pelican with warm white feathers, slate wing tips, a long golden bill/pouch and webbed feet. Original source is `godot_native/scripts/presentation/chase3d/campus_pelican_rig.gd`; paper-feather handoff and fine-resolution32-color rendering share the existing clock and do not own gameplay progression. This is pixel-rendered3D in the authored cycling-camera exception, not a hand-painted sprite atlas. Existing pixel protagonist walk frames bookend the transformation. No pelican demo code/model was copied and no new Rodin credit was spent. The superseded human v3 remains in local art_source/reference files but is excluded, together with its unused textures, from the Web production preset. Full provenance, hashes and scoped desktop/touch/native evidence: `godot_native/docs/art/PELICAN_RIDER_20261021.json`. Broad scenery/art acceptance and physical mobile testing remain separate.

## 2026-10-21 · 本地上游 UI 整合与原应用图标保留

#156 的字体与 UI 资源按原许可整合；#157 模块寝室只作候选保留，正式导出排除。手机主页恢复整合前项目自有彩色应用图案、名称及独立设置齿轮，不使用上游线框 launcher 替换它们。地图工具使用项目内原生绘制图标，物品行继续使用原物品资源及原 catalog 名称。未为本次修正提交任何 Rodin 生成任务。

项目原始代码采用根 `LICENSE` 的 Apache-2.0；`NOTICE` 和原始第三方资源、字体、Godot 许可分开保留。新 Godot 正式 core 包包含 LICENSE/NOTICE。资源与包验证摘要见 `godot_native/docs/UPSTREAM156_157_INTEGRATION_20261021.json`。

### 彩色系统图标补充

`godot_native/scripts/ui/world_phone_launcher.gd` 原生绘制项目自有彩色手机、折叠地图、纸页手记、太阳/月牙图案；隐藏的旧背包也保留同族图案。80×80 母版仅使用既定 32 色，二值透明、最近邻，图案 34px、命中区 44px。未引入外部图片或生成模型。来源、规格和明暗/移动渲染记录见 `godot_native/docs/COLORED_CORNER_ICONS_20261021.json`。

## 2026-10-22 · 像素羊皮纸签到回执

`godot_native/scripts/ui/checkin_success_view.gd::paint_parchment` 在304×420原生像素上生成项目自有羊皮纸：二值透明毛边，既定暖纸配色，中央保持低纹理以供实时文字/印章。最近邻显示，字与章不烘焙入图、不改变剧情状态。原 `assets/native/checkin/checkin_receipt_v1.png` 保留为历史素材，活动回执不再使用其写实纸面。签到表单恢复原版本像素表现；字体复用既有 Fusion Pixel，原字体许可保留。来源与验收见 `godot_native/docs/CHECKIN_PIXEL_RESTORATION_20261022.json`。

### Prologue character flow — 2026-10-22

- Original procedural glyph field and trails: `godot_native/scripts/games/prologue_character_flow.gd`; existing bundled Fusion Pixel lettering, project paper/ink colors. No new external image/font assets.
- Visual/architecture reference inspected: [stackedlol/ascii-sharks](https://github.com/stackedlol/ascii-sharks/tree/c521e24a787e6d4cc460d4cf2b9815f25e4fe453), README plus `src/engine.ts` and glyph-cell drawing in `src/renderer.ts`, read 2026-10-22. Continuous stable-glyph motion and a separate rendering clock informed the direction; no repository code, geometry, shark art, or package was copied or bundled.
- Deliberate motion preview (`755-tools/review/character-flow-native-fixture-20261022.mp4` and `.gif`, outside delivery) uses 264 real Godot Compatibility-rendered fixture frames at 24fps. It previews presentation without asserting a controller-earned campaign; real exported-browser input acceptance is separate.

- Actual browser review media: `755-tools/review/character-flow-20261022.mp4` / `.gif`, captured through computer use from the final 5241 production export, using the current ordinary unfinished-interception save. Original 301 frame timestamps are preserved with verification evidence. The clip removes the preceding seven-second blackout for review only; the game retains it.

### Dense ASCII Hanzi terminal — 2026-10-22

- User-approved scope is the prologue coordinate-error/interception/hold/dialogue presentation. The preceding pixel parchment receipt remains separate.
- Original built-in `image_gen` reference drafts: `godot_native/art_source/prologue_terminal_20261022/terminal_ascii_concept.png` and the density revision `terminal_ascii_dense_concept.png`. The final prompt is `dense_prompt.txt` beside them; art_source is excluded with `.gdignore`, and neither concept is a runtime background.
- Runtime assets: `assets/native/prologue_terminal_20261022/ascii_glyph_atlas.png` (6×8 cells) and `ascii_fine_glyph_atlas.png` (3×4 coverage-preserving cells), plus `data/native/prologue-ascii-masks.json` (66 original-font masks, covering authored clues and physical targets). Deterministic builder: `tools/build_prologue_ascii_masks.py`. Source: bundled Fusion Pixel font, its original OFL-1.1 notice and recorded SHA-256. No third-party code or copied shark art.
- Original `scripts/games/prologue_ascii_field.gdshader` advects a continuous 95%-occupied glyph field; source-mask strokes brighten with denser glyphs (initial draft fourfold; final smaller-field revision twofold). Hanzi are not conventionally drawn underneath, and opaque standalone word tiles have been removed. Shader masks track the actual model word positions, sizes and rotation; all progression still requires physical contact and semantic validation.

- Continuous clue cloud follow-up: all moving clue fragments and physical target words share the same sampled ASCII construction. Six dimmer cloud slots flow through the original reading/spawn handoff; two brighter slots track actual colliders. Full-clue review and fixed narration remain accessible ordinary text.

- Four-sided assembly follow-up: background cells shrink to4×6; stroke symbols stay at their readable3×4 floor. An original shader moves stable glyph cells from four directions into each Hanzi over0.28s, settling before real contact can occur. No additional generated raster asset, third-party code, or progression write. ERROR face uses the existing Fusion Pixel font.

### Illustrated interception continuation — 2026-10-22

- Original built-in `image_gen` illustration: `godot_native/art_source/ending_resume_20261022/terminal_original.png`; retained under the existing `.gdignore`, excluded from runtime packs. No external game artwork, logos or third-party code copied. The generation service does not expose a model version.
- Runtime vignette: `godot_native/assets/native/ending_resume/terminal_signal_20261022.png`,756×504 native pixels,378×252 authored UI placement, nearest filtering and unchanged3:2 aspect. Deterministic16-color normalization uses the existing terminal ramp plus campus metal/paper/ink colors. It depicts a terminal, paper receipt and suspended glyph window; it contains no actionable interface text.
- Reproduction: `godot_native/tools/prepare_ending_resume_art.py`; exact generation prompt: `godot_native/docs/art/prompts/ending_resume_terminal_20261022.txt`; original/runtime SHA-256, dimensions and Pillow version: `godot_native/docs/art/ENDING_RESUME_ART_20261022.json`. Real headings, labels and controls remain native Godot elements.
