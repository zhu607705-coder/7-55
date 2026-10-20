# Godot 浏览器版本构建与发布

此交付从 `godot_native/project.godot` 导出独立 Godot 游戏，以 WebAssembly 运行 GDScript 和原生控制器。保留的 `src/`、`demo/`、React/Phaser 构建仍可独立构建，但不是本次 Pages 发布输入，也不是浏览器启动失败时的替代运行时。

## 固定工具与本地构建

使用官方非 .NET **Godot 4.7.2 stable**，以及同版官方 `web_nothreads_release.zip`。Linux/Windows 导出预设保持不变。Web 预设使用已有的 Compatibility 渲染器、WebGL 2、单线程和 `755_production,755_web` 特征。GitHub Pages 无需配置 COOP/COEP，也不安装缓存整个游戏的 service worker。

从仓库根目录运行：

```sh
npm ci --ignore-scripts
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node godot_native/tools/build_web.mjs
```

构建脚本同步源资产/JSON，使用现有 `convert_media.sh` 转换剧情影片，导入 Godot 资源后运行 `--export-release 'Web production'`。必须安装 ffmpeg。Linux 可使用 `GODOT_BIN=godot` 或默认的 `godot`。Node 固定 22.23.3，满足同步工具的 TypeScript 源模型解析需求。导入/导出使用 quiet 模式，完整日志保存在 `exports/verification/godot-web-build/`；检测到 `SCRIPT ERROR:` 或 `ERROR:` 时，即使 Godot 返回码为 0 也拒绝发布。

媒体转换同时需要 FFmpeg 自带的 `ffprobe`。先保持 Theora q8；只有实际文件超过 23,500,000 字节才逐级降低视频编码质量，最低 q4 仍超预算则拒绝。不截时、删帧、变速、缩放或删除音轨；完整帧数、尺寸、帧率、时长和音轨后检通过后才原子替换生成 OGV，原 MP4 保留。可用 `FFMPEG_BIN`、`FFPROBE_BIN` 指定已有工具；构建脚本将自身 Node 路径通过 `NODE_BIN` 传入转换器，避免桌面应用 PATH 缺少 Node 时失败。转换器本身也纳入发布源摘要。

父进程已完成准备/导入且没有其他 Godot 进程写同一工程时，可用 `--skip-prepare --skip-import`。这两个参数不会生成遗漏的输入，脚本会验证关键输入存在。重复构建加 `--replace`，先将既有目录重命名为带时间戳的备份。不要并行导入或导出同一工程。

默认输出 `godot_native/exports/web-release/`；可用 `--output=godot_native/exports/<独立目录>` 指定工程 exports 内的目录。只检查已有产物：

```sh
node godot_native/tools/build_web.mjs --verify-only
```

## 发布结构与可验证来源

发布根目录直接包含 `index.html`、`index.js`、`index.wasm`、首章 `index.pck`、`content-loader.js` 及引擎音频工作脚本。后续章节与独立校园位于 `content/<分组>-<内容摘要>.pck`，资源仍使用原来的 `res://` 路径。HTML shell 和引擎都使用相对路径，在根目录和 GitHub Pages 的 `/7-55/` 下保持相同部署结构。拆包的全量覆盖验证见 [内容包构建](WEB_CONTENT_BUILD.md)。

脚本验证 HTML 引擎标识、真实 WASM 魔数、PCK 目录/范围/格式、原生主入口与三校园依赖以及生产特征。禁止 iframe、React/Phaser 替代运行时、线程/PWA 脚本、开发目录和未替换的模板占位符。发布产物记录：

- `build-manifest.json`：源提交、源树、未提交变更、输入摘要、各运行文件 SHA-256、引擎/预设及体积；本地未提交构建会如实标记 dirty，不能伪称属于 HEAD。
- `source-inputs.json`：参与构建的源文件哈希和有意排除的文件/字节量；忽略可由编辑器生成且跨机器可能不同的 `.import`、`.uid` sidecar，真实导出字节另有 PCK 哈希。
- `pack-inventory.json`：真实 PCK 内部文件目录及内容范围。
- `content-manifest.json`：启动包及后续章节包的路径、字节数、SHA-256 和后台加载顺序。
- `content-inventory.json`：完整导出中每个资源的唯一所属包及原始内容摘要，证明拆包没有遗漏。

脚本拒绝 PCK 超过 800,000,000 字节、WASM 超过 70,000,000 字节或主要发布文件合计超过 950,000,000 字节的构建，为 GitHub Pages 的 1 GB 站点限制留余量。这是托管体积保护，不代表首次下载体验或手机内存验收通过。

Web 包排除测试、工具、文档、验证截图/日志、原型样例和构建导出目录；另排除无原生正式消费者的校园/室内源图目录、只供保留 Web 使用的 `assets/rpg/optimized` 重复图，以及已有 OGV 替代的原 MP4。源仓库和完整源 ZIP 保留原素材。独立校园漫游仍为正式入口，`campuses/` 不排除。脚本拒绝后来对被排除源图目录新增原生代码/场景消费者，避免悄悄漏资源。

## 用户启动与验收

自定义 `web/index.html` 显示中文下载进度、加载失败与重试。引擎和游戏包异步准备完成后出现“进入游戏”；用户点击后启动引擎并进入原生入口，确保浏览器音频的用户手势。没有 URL 参数转发、章节选择或测试入口。canvas 按实际浏览器窗口调整渲染尺寸，场景布局和等比视图仍由 Godot 项目负责。

启动仅等待引擎和首章依赖。进入主线后，章节 2、3、3.5、4 按顺序单流后台下载；开启浏览器省流量模式时改为按需下载。独立校园选择后才请求对应内容。每个包最多 24,000,000 字节，确认长度、SHA-256 和 Godot 挂载成功后才缓存。浏览器不支持持久缓存或 WebCrypto 时，仍由原生协调器校验并挂载，缓存失败不阻止游玩。

旧存档恢复、章节切换、剧情媒体与音频共享资源就绪门槛。到达尚未准备好的章节时显示进度与可重试提示，暂停当前游戏和呈现时钟；不会重置剧情或跳过影片。若旧页面缓存与新首包混用，缺少内容加载器时会显示“重新加载”，由玩家点击恢复；正式 Web 不能静默将首包当成完整游戏。下载等待与标签页隐藏共用音频暂停所有权，恢复后保留手动暂停。部署自有服务器的隔离目录、压缩、缓存和原子回滚见 [服务器交付](SERVER_WEB_DELIVERY.md)。实际首次传输量、计时和内存以浏览器验收为准。

供浏览器测试读取的 `document.documentElement.dataset.bootState` 只有 `loading`、`ready`、`running`、`error`，只是 HTML 加载状态，不是剧情状态或剧情写入端口。`running` 仅代表引擎启动 Promise 成功；不能将它当作场景、地图、存档或章节衔接已经通过的证据。

发布前还须对导出的真实 WASM 页面验收：桌面/手机窗口和非 16:9、主线首次进入、触摸和键盘、手机与横屏地图切换、存档/重载、失焦中断、剧情音视频、章节边界、生产无测试跳转，以及 Blink/Gecko/WebKit。用独立浏览器配置与测试存档，不覆盖用户存档。HTTP 验证包含 `/7-55/` 相对路径、WASM 正确 MIME 类型、PCK 完整字节和缺失资源；仅通过本脚本不算游戏验收通过。

## GitHub Pages

`.github/workflows/deploy-pages.yml` 仅由 `main` 和已获用户明确授权的 `codex/godot-complete-20261019` 推送或手动启动。构建使用锁定依赖、官方 Godot/模板的固定 SHA-512 校验、源素材同步、影片转换、真实 Godot export、产物/来源校验。随后在真实 `/7-55/` HTTP 子路径，用 Linux Chrome/SwiftShader 执行 `tools/verify_web_export.mjs`：三个桌面/手机视口、真实输入、音频状态、IndexedDB 刷新恢复、正式无跳转、WASM/PCK HTTP SHA-256 校验通过后，才上传 `godot_native/exports/web-release/`。不调用根 `npm run build`，不上传 `dist/`。这项 CI 为实际 Chromium gate，不代替 Gecko/WebKit 和人工媒体验收。

GitHub `github-pages` 环境的发布分支权限继续限于原来允许的 `main` 和这一唯一候选分支。此次工作不拓展部署权限、不合并迁移 PR、不宣称 Godot 替代发布已经正式验收。

官方参考：

- [Godot Web 导出与平台限制](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Godot 自定义 HTML shell](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html)
- [Godot 4.7 Web 导出预设实现](https://github.com/godotengine/godot/blob/4.7-stable/platform/web/export/export_plugin.cpp)
- [Godot 4.7.2 官方下载与校验文件](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
- [GitHub Pages 容量限制](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)
