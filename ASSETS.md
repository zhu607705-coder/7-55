# 7:55 Release Assets

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
