# Godot 浏览器版本构建与发布

此交付从 `godot_native/project.godot` 导出独立 Godot 游戏，以 WebAssembly 运行 GDScript 和原生控制器。保留的 `src/`、`demo/`、React/Phaser 构建仍可独立构建，但不是本次 Pages 发布输入，也不是浏览器启动失败时的替代运行时。

## 固定工具与本地构建

使用官方非 .NET **Godot 4.7.1 stable**，以及同版官方 `web_nothreads_release.zip`。Linux/Windows 导出预设保持不变。Web 预设使用已有的 Compatibility 渲染器、WebGL 2、单线程和 `755_production,755_web,755_story_only` 特征。GitHub Pages 无需配置 COOP/COEP，也不安装缓存整个游戏的 service worker。

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

发布根目录直接包含 `index.html`、`index.js`、`index.wasm`、首章 `index.pck`、`content-loader.js`、`scene-orientation.js` 及引擎音频工作脚本。后续主线章节位于 `content/<分组>-<内容摘要>.pck`，资源仍使用原来的 `res://` 路径。HTML shell 和引擎都使用相对路径，在根目录和 GitHub Pages 的 `/7-55/` 下保持相同部署结构。拆包的全量覆盖验证见 [内容包构建](WEB_CONTENT_BUILD.md)。

开场美术遵循[统一像素规范](art/ART_BIBLE.md)，网页生成和格网处理来源见[设计记录](OPENING_WEB_DESIGN_20261021.json)。`web/boot_intro.js`在构建时按原字节内联进HTML，并标记源SHA；不再额外请求`boot-intro.js`。一张浏览器专用无损WebP以`boot-art/morning_room.<sha256>.webp`输出，记录在`bootIntroPresentation.assets`中；`verify-only`同时验证源图、输出、唯一HTML引用、文件清单及PCK排除。原始下载与试样不进入PCK。

插画是独立的非阻塞请求，不进入WASM/PCK下载、校验或就绪Promise，也不计入真实进度。浏览器可按内容哈希URL及正常HTTP策略复用图片缓存；不承诺永久保留。全屏构图、暂停、减少动态效果、后台可见性、真实下载失败重试，以及插画挂起/404时仍可启动引擎，均须对实际导出包验收。图片格网检查、带stub的UI预览与Godot浏览器验收分别记录。

脚本验证 HTML 引擎标识、真实 WASM 魔数、PCK 目录/范围/格式、原生主入口、主线发行策略以及真实生产特征。禁止 iframe、React/Phaser 替代运行时、线程/PWA 脚本、开发目录和未替换的模板占位符。发布产物记录：

- `build-manifest.json`：源提交、源树、未提交变更、输入摘要、各运行文件 SHA-256、引擎/预设及体积；本地未提交构建会如实标记 dirty，不能伪称属于 HEAD。
- `source-inputs.json`：参与构建的源文件哈希和有意排除的文件/字节量；忽略可由编辑器生成且跨机器可能不同的 `.import`、`.uid` sidecar，真实导出字节另有 PCK 哈希。
- `pack-inventory.json`：真实 PCK 内部文件目录及内容范围。
- `content-manifest.json`：启动包及后续章节包的路径、字节数、SHA-256 和后台加载顺序。
- `content-inventory.json`：完整导出中每个资源的唯一所属包及原始内容摘要，证明拆包没有遗漏。

首包与 WASM 另生成 `boot/` 下至多 1 MiB 的独立静态文件，`build-manifest.json.bootChunks` 记录每块原始偏移、字节数、SHA-256 以及整份资源摘要。浏览器完整下载各块并逐块校验后才缓存，最多三块并发；退出后可复用已完成的块。新版缓存按每块 SHA-256 与长度寻址，后续构建中身份相同的块可跨整包版本复用；旧格式缓存仅能在整包身份仍相同时迁移，首次改变 core 的升级不承诺复用全部旧块。逐块和整份摘要均保留；可用 WebCrypto 时异步校验，普通 HTTP 回退按有界块让出主线程。此路径不依赖 HTTP Range，避免原网站为大文件返回 gzip 字节范围时无法独立解压的问题。导出后的原 `index.pck`、`index.wasm` 原样保留，供引擎独立验证与回滚。构建及 `--verify-only` 重新比较每块与原文件，校验首尾边界、连续覆盖、无重复遗漏和重组后的完整摘要，不改写冻结产物。

构建对导出 HTML 中的 `content-loader.js` 和 `index.js` 地址加入各自实际脚本的完整 SHA-256 查询参数，并记录 `contentLoader`、`engineLoader`；`--verify-only` 逐项核对，避免新 HTML 命中仍在缓存有效期内的旧加载器或引擎脚本。源码模板及源输入摘要仍保留真实内容。

剧场到启真湖的 `13668×1084` 全景使用七张物理尺寸不超过 `2048` 的无损分片，地图和剧情插图都通过同一源坐标适配器绘制。`native:sync` 从原图生成分片；构建与只读验证执行 `build_panorama_tiles.mjs --check`，核对完整像素重组与派生摘要。分片属于第三章后续 `chapter35` 包；Web 预设排除原超宽 PNG，自检同时拒绝它的导入指针和实际纹理载荷。原图仍保留在源仓库及同步输入中，碰撞、通行掩码、场景尺寸和剧情交接不变。

固定的官方 4.7.1 引擎脚本在通用音频初始化中无条件加载 Sample 位置 Worklet，普通 HTTP 缺少 `audioWorklet` 时会在选择音频驱动前抛错。本项目已经使用 Stream 播放，构建工具只为这一个可选加载增加能力检查，使引擎继续选择其自带的 ScriptProcessor 驱动。`web_audio_compat.mjs` 要求官方原始脚本的精确 SHA-256、单一匹配和精确输出摘要，并记录 `engineAudioCompatibility`；模板发生变化时拒绝猜测性修补。验证模式还原后比较官方原始摘要。没有伪造 Worklet、静音替代或修改 WASM。参见 [固定版本的音频初始化](https://github.com/godotengine/godot/blob/4.7.1-stable/platform/web/js/libs/library_godot_audio.js) 和 [原有 Web 驱动回退](https://github.com/godotengine/godot/blob/4.7.1-stable/platform/web/audio_driver_web.cpp)。

`totalPayloadBytes` 计入托管的原文件和块文件，反映实际站点空间；`logicalPayloadBytes` 去除这份重复副本；`initialPayloadBytes` 按浏览器使用的块计算，避免把原文件重复计入首次传输。这些静态字节统计不代替真实网络计时、压缩传输量或内存验收。

脚本拒绝 PCK 超过 800,000,000 字节、WASM 超过 70,000,000 字节或主要发布文件合计超过 950,000,000 字节的构建，为 GitHub Pages 的 1 GB 站点限制留余量。这是托管体积保护，不代表首次下载体验或手机内存验收通过。

Web 包排除测试、工具、文档、验证截图/日志、原型样例和构建导出目录；另排除无原生正式消费者的校园/室内源图目录、只供保留 Web 使用的 `assets/rpg/optimized` 重复图，以及已有 OGV 替代的原 MP4。此次 Web 发行还排除整个 `campuses/` 北化研究目录：朝阳、海淀、昌平、共享学生和朝阳树木原型。真实 `755_story_only` 特征使入口不创建这三个按钮，直接调用入口及内容包请求也会拒绝北化；导出自检同时拒绝逻辑路径和由原资源路径标识的匿名 `.godot/imported`、`.godot/exported` 载荷。浙大主线 `assets/rpg/campus/`、湖区、教学楼及其存档门槛保持原有范围。源仓库、编辑器及独立原生研究包保留北化素材和测试。脚本仍拒绝后来对其他被排除源图目录新增原生代码/场景消费者，避免悄悄漏资源。

## 用户启动与验收

自定义 `web/index.html` 显示中文下载进度、加载失败与重试。引擎和游戏包异步准备完成后出现“进入游戏”；用户点击后启动引擎并进入原生入口，确保浏览器音频的用户手势。没有 URL 参数转发、章节选择或测试入口。canvas 按实际浏览器窗口调整渲染尺寸，场景布局和等比视图仍由 Godot 项目负责。

启动仅等待引擎和首章依赖。食堂物件在首次入场时创建，北教和图书馆纹理延迟到对应场景加载，避免后续场景资源进入第一章启动闭包。进入主线后，只单流预取下一章：第一章预取第二章，第二章预取第三章，以此类推；原生内容协调器在当前章节资源就绪后推进窗口。前台必需资源始终优先，已开始的单包下载先完成并校验；页面隐藏时暂停发起新的后台请求，恢复可见后继续。开启浏览器省流量模式时改为按需下载。北化地图以前仅在选择漫游后才请求，因此本次剥离减少完整部署及可选漫游流量，不代表普通主线首包或后台下载减少了同样大小。每个包最多 24,000,000 字节，确认长度、SHA-256 和 Godot 挂载成功后才缓存。浏览器不支持持久缓存或 WebCrypto 时，仍由原生协调器校验并挂载，缓存失败不阻止游玩。

旧存档恢复、章节切换、剧情媒体与音频共享资源就绪门槛。到达尚未准备好的章节时显示进度与可重试提示，暂停当前游戏和呈现时钟；不会重置剧情或跳过影片。若旧页面缓存与新首包混用，缺少内容加载器时会显示“重新加载”，由玩家点击恢复；正式 Web 不能静默将首包当成完整游戏。下载等待与标签页隐藏共用音频暂停所有权，恢复后保留手动暂停。部署自有服务器的隔离目录、压缩、缓存和原子回滚见 [服务器交付](SERVER_WEB_DELIVERY.md)。实际首次传输量、计时和内存以浏览器验收为准。

供浏览器测试读取的 `document.documentElement.dataset.bootState` 只有 `loading`、`ready`、`running`、`error`，只是 HTML 加载状态，不是剧情状态或剧情写入端口。`running` 仅代表引擎启动 Promise 成功；不能将它当作场景、地图、存档或章节衔接已经通过的证据。

Web 的持久 `WebDisplay` 平台适配器在入口场景前，将根 Window 的 `content_scale_factor` 同步到引擎实际使用的显示密度；窗口调整、跨屏和浏览器缩放时继续更新。高清 canvas 的物理尺寸保持原样，布局与点击统一使用 CSS 像素，支持分数密度及低于 100% 的缩放。原生平台不启用此适配；手机 `430×860`、小游戏和 RPG 的逻辑比例与剧情状态保持原契约。验收同时比较 DPR=1/2 的 CSS/画布尺寸、实际控件点击和原有存档流程，不能只用 DPR=1 截图证明高 DPI 正常。

## 手机场景与直接触摸（2026-10-21）

手机应用继续使用竖屏框架。原生只读呈现快照说明当前地图或活动是否适合横屏；`scene-orientation.js` 在粗指针、竖屏、横向场景同时满足时提供横屏入口。只有玩家点击才请求全屏和可用的方向锁定，能力缺失时保留手动旋转与“暂用竖屏”。返回手机释放本入口持有的全屏和方向锁；异步返回结果须核对当前场景代次。脚本的实际 SHA-256 地址与文件摘要纳入构建和冻结产物验证。

地图通过点地行走、点物件查看及双指平移/缩放操作，不常驻方向盘和交互按钮。远处物件沿真实碰撞路径走近，在原控制器允许的距离内提交一次原交互；换场景、模式、状态、目标、弹窗、失焦或取消会退休待执行动作。桨直接使用可见桨和水面区域。剧场扇影排练使用实体拖动、点灯试演、长按观察、双指轻点撤回，以及双指按住打开的排练单。桌面键盘与鼠标保留。设计研究及固定版本来源见 [Touchable 输入研究](TOUCHABLE_INPUT_RESEARCH_20261020.json)；游戏未引入其运行代码或第二套状态控制器。

DOM 能力测试只验证入口及异步所有权；真实浏览器的旋转、触摸、路径、存档与刷新须对具体导出另行验收。浏览器触摸模拟仍不等于 Android/iPhone 真机验收。

## 手机阅读与加载开场（2026-10-21）

CC98 帖子按实际字体与剩余宽度测量正文和回复高度；首屏阅读、证据区入口仅移动原滚动容器，不取得线索或提交证据。正文避开收起的道具栏。手机与弹窗在引擎支持时启用按实际缩放重新采样字体，保留原字体、逻辑尺寸和命中坐标；不降低高清 canvas 的 DPR。实现和具体导出验收见 [手机阅读验收](PHONE_LEGIBILITY_ACCEPTANCE_20261021.json)。

加载开场目前只有真实进度、暂停状态及原进入/重试流程的展示接口；动画未启用。用户要求先交网页端设计，但电脑控制返回 Mac 锁屏，尚未收到网页方案。状态、接口摘要和待验项见 [开场状态](OPENING_PRESENTATION_STATUS_20261021.json)。它不构成开场视觉完成或公开发布。

## 保存完成边界（历史修复与当前发行验收分开记录）

提交 `95f21403aeeac346b94bb862fb08aedc0fe0e5b9` 的 Linux CI 暴露了真实的 Web 持久化问题：触摸 `390×844` 场景中，Godot 内存与已关闭的本地文件已经是深色模式，但只读 IndexedDB 主存档仍是此前的浅色模式；实际重载恢复了浅色模式。该候选没有发布，桌面用例通过也不能消除这个失败。

Godot 4.7.2 的文件关闭回调和 `force_fs_sync()` 只是登记待同步，由主循环异步发起持久化；`is_userfs_persistent()` 说明存储可用，不是本次保存完成。参见固定版本的 [OS_Web 同步调度](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp#L70-L85) 和 [GodotFS 异步同步](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/library_godot_os.js#L178-L192)。因此，MEMFS 中的 `saveDigest`、旧的同步 Promise、等待 350 ms 或 1.6 s 都不能单独当作本次 IndexedDB 提交的回执。

以下保存协议已随 `a3598adf` 的先前 Pages 交付上线，并有独立浏览器落盘与重载凭据。本次静态分块与界面候选仍须核对其自身构建和浏览器结果，不能直接继承旧字节的验收：

- `State` 的保存逻辑和信号保持不变，仍是唯一存档写入者，负责已有完整包络、校验、临时文件与原子替换。两个手动保存入口统一调用 `request_save`，先执行原有 `State.save_game()`，再请求文件系统同步；自动保存通过既有快照发布观察 MEMFS 文件摘要变化。浏览器适配器不直接写 IndexedDB，不另建存档格式、钱包、物品或剧情状态。
- 本次保存使用具体文件字节的 SHA-256 与请求 token 关联。私有 Web 回调只读 `/userfs` 的 `FILE_DATA` 主存档并返回实际字节，由 GDScript 计算摘要；只有摘要精确匹配且 token 仍属于当前请求，才允许确认。它不依赖原始 IP HTTP 环境可能缺失的 WebCrypto。较旧请求的回执不能替较新保存确认。
- 手动保存按钮立即显示“正在保存…”并禁用重复点击，精确 ACK 后才在该按钮显示“已保存”。反馈留在操作旁，不通过可能排队的剧情 toast 假定本次成功。20 秒超时、持久存储不可用或读取失败不能显示成功；失败后可再点保存重试，或通过已有便携导出保留当前进度。未确认写入会保留浏览器允许的 `beforeunload` 提示，dispose 会取消计时器、回调与提示；这不是强行终止浏览器仍保证保存的承诺。
- 正式 browser gate 必须等待真实成功状态，再通过测试侧独立只读 IndexedDB 检查精确摘要，随后真实重载并保留原有路线、现实模式及剧情标记断言。不能靠增加固定 sleep 或删去断言让失败变绿。

2026-10-20，候选 `c1528f89` 的 Pages run `39411755479` 在保存 gate 失败：报告记录 173 项已完成检查、4 个已进入的视口用例；前三个用例完成精确保存与真实重载，第四个 `retina-1440`（CSS `1440×900`、DPR=2）等待当前保存回执超时。失败时当前 MEMFS 摘要为 `764fe4bb…`，只读回调观察的摘要仍为旧的 `42efec34…`，按钮显示“保存未完成·重试”。原报告没有失败时的独立 IDB 字节、mtime 或逐次 generation 记录，不能据此确定旧字节始终未提交、回执晚到或主线程调度的具体原因。该用例只走首次进入、设置与保存，没有触发本次 Journal 返回回调。Publish job 已跳过；记录时线上仍为已发布的 `a2517a6a`。

随后新增的恢复能力在同一次 pending attempt 内，按真实 `Time.get_ticks_msec()` 每 500ms 再请求一次官方 `force_fs_sync()`，包含首次请求最多 40 次。续推不重新执行 `State.save_game()`，不直接写 IndexedDB，也不重置 token、摘要、`startedMs` 或原来的 JS 20 秒 watchdog。精确 ACK、超时、失败或 dispose 后停止续推；达到原期限或请求上限后也不再请求。只读 `syncRequests` 表示请求次数，`lastSyncMs` 表示最后请求时间，二者都不构成提交回执。已有 token 与实际字节 SHA-256 一致仍是唯一成功条件。

正式 verifier 同时保留每次等待的回执历史；失败后补采独立只读 `failureDisk`，包括 `FILE_DATA` 字节摘要和 `timestampMs`，然后保留原失败。诊断不重试游戏保存、不延长产品 watchdog、不改变精确 ACK 或重载断言。

该恢复能力已通过隔离原生 35 项检查（保留原 20 项并新增 15 项）及原 JS transport 39 项检查，独立只读审查未发现阻塞问题。独立的真实 Chromium/官方 IDBFS 18 项负控证明，同 mtime、不同字节可以被同步算法跳过，重复同步也无法修复这一受控情况；它没有证明本次云端失败发生了 mtime 碰撞。旧 `36ba4391…` 包的本地调度诊断也没有复现云端 20 秒超时，不能用本地通过替换原失败。完整范围、来源和 SHA 见 [保存续推证据](../verification/save_sync_renewal_20261020/summary.json)。新不可变包 source-input `02d7c7b5288cf580c2523dea47f6a17355dbc607f8a26bee9c056d0a4aa7b8ac` 已在本机六视口/DPR 场景完成 737 项实际检查，用时 142325ms，每个用例的 native ACK、独立只读 IDB 摘要和新 document 重载均通过，6 张截图检查后已留 SHA 并清理。新包另通过实际普通 HTTP 的 DPR=2 场景 16 项检查：`isSecureContext=false`、`crypto.subtle` 不可用、IndexedDB 可用，真实模式切换、手动保存、native 精确 ACK、测试侧 Node 计算的独立 IDB 摘要与新 document 重载均通过；该次保存观察用时 116ms，仍只有 1 次同步请求。这不继承旧版三次启动缓存测试的结论。这些常规用例仅用到首次同步请求，不能作为续推恢复的证明。另一次受控对照在相同 DPR=2、4 倍 CPU 降速及原 20 秒期限下，仅丢弃一次符合条件的官方 flush：旧 `36ba4391…` 包保持旧 IDB 摘要并触发产品超时；新包经 8 次官方请求，在 6149ms 的保存观察窗口内达到 native/IDB 精确 ACK，27 项检查及真实新 document Continue 恢复均通过。两侧使用相同临时诊断 engine hook（`6ce274f3…`，原 engine 为 `649986c2…`），没有额外 Save 点击、第二写入者或时钟改动。这证明受控丢 flush 机制的恢复，仍不能证明原 clean Linux CI 失败由同一原因导致。旧对照在保存失败记录完成后另有 `Page.navigate` 超时，没有记录 dialog 事件，旧版重载及其超时原因均未验明。新 clean Linux CI 与部署仍待完成。

具体实现、超时与负控结果随 `progress.md` 和独立产物收据记录。历史短间隔导入探针仅说明当时特定样本的观察结果，不构成耐久保证。

发布前还须对导出的真实 WASM 页面验收：桌面/手机窗口和非 16:9、主线首次进入、触摸和键盘、手机与横屏地图切换、存档/重载、失焦中断、剧情音视频、章节边界、生产无测试跳转，以及 Blink/Gecko/WebKit。用独立浏览器配置与测试存档，不覆盖用户存档。HTTP 验证包含 `/7-55/` 相对路径、WASM 正确 MIME 类型、PCK 完整字节和缺失资源；仅通过本脚本不算游戏验收通过。

## GitHub Pages

`.github/workflows/deploy-pages.yml` 为相关 PR 提供仅构建/验收的路径：build 只有 contents:read，PR 不配置 Pages、不上传 Pages 整包、不部署，且与生产并发组隔离。发布仍只由原有 `main`、`codex/godot-complete-20261019` 推送或这些分支的手动运行进入受保护的 deploy job；合入 main 会触发这条既有发布链。构建使用锁定依赖、官方 Godot/模板的固定 SHA-512 校验、源素材同步、影片转换、真实 Godot export、产物/来源校验。随后在真实 `/7-55/` HTTP 子路径，用 Linux Chrome/SwiftShader 执行 `tools/verify_web_export.mjs`：六个桌面/手机视口与 DPR 场景、真实输入、音频状态、IndexedDB 刷新恢复、正式无跳转、WASM/PCK HTTP SHA-256 校验通过后，才上传 `godot_native/exports/web-release/`。不调用根 `npm run build`，不上传 `dist/`。这项 CI 为实际 Chromium gate，不代替 Gecko/WebKit 和人工媒体验收。

GitHub `github-pages` 环境的发布分支权限继续限于原来允许的 `main` 和这一唯一候选分支。本轮不拓展发布分支权限；相关历史 PR 的外部合并事实见 [当前整合记录](BRANCH_CONSOLIDATION.md)。PR 构建通过不等于已经部署；历史 4.7.2 证据不作为新 4.7.1 验收。

官方参考：

- [Godot Web 导出与平台限制](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Godot 自定义 HTML shell](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html)
- [Godot 4.7 Web 导出预设实现](https://github.com/godotengine/godot/blob/4.7-stable/platform/web/export/export_plugin.cpp)
- [Godot 4.7.1 官方下载与校验文件](https://github.com/godotengine/godot-builds/releases/tag/4.7.1-stable)
- [GitHub Pages 容量限制](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)
