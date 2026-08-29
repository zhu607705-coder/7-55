Original prompt: 现在不用管讲稿了，你需要对于其来进行完善

## 2026-08-29 A 范围主分支上传前质量门收口

- 提交范围：用户确认 A 后，按三视图中列明的 `25` 个修改文件与 `19` 个新增文件准备直接提交到当前 `main`。继续排除被忽略的 `demo/`、`dist/`、外部 ZIP 与恢复副本、Godot 归档和临时浏览器检查文件；没有新增测试文件或测试依赖。
- 远端基线：上传前两次执行 `git fetch origin main --prune`，本地与远端共同基线均为 `a7790f4da13e`，本地和远端互相缺少的提交均为 `0`，没有发现需要再次比较的合作者提交。
- 质量门根因：首次 `pre-push` 的前十项验证通过，第十一项仍按旧合同要求“六个环境点全部只读”。当前正式结构已经扩展为六个控制器托管谜题点和两个只读环境点，旧验证还把紧随其后的 `complete_inserted_puzzle` 写状态分支截入只读分支，并错误要求桌面终端中心必须位于可行走地面。
- 合同修正：现有 effective-interactions 验证器改为分别核对六个谜题点与两个只读点、A1/A2/A3 楼层投影、控制器谜题请求、任意深浅模式进入、只读零写入，以及桌面谜题周围的无碰撞站位。Phaser 场景在谜题弹窗打开时不再额外显示“当前教室没有新增状态记录”的通用字幕。
- 复核结果：`npm run typecheck` 通过；关键玩法套件 `11/11` 通过，其中第四章有效交互为 `624` 项断言；`NODE_OPTIONS=--max-old-space-size=6144 npm run build:single` 与 `npm run verify:single` 通过。离线单文件为 `258649617` 字节，含 `2` 个内联脚本和 `1` 个内联样式；`git diff --check` 通过。最终远端 SHA 与 GitHub Web CI 以推送后的读取结果为准。

## 2026-08-29 “灿若星辰灯”正式素材归档、接入与旧版清理

- 素材判定：用户提供的 `灿若星辰灯.zip` 原包为 `304494554` 字节、`33155` 个条目、解压后 `805997402` 字节，SHA-256 为 `5401308d838eed37466cc59b5485b0aed0d6bc0b1f785a9700c08b9cb2c674e7`。唯一需要的运行时内容是五张同画布透明分层 PNG：`lamp_dark`、`lamp_outline`、`lamp_leds`、`lamp_core`、`lamp_glow`，合计 `632195` 字节；Godot、Three.js、Next.js、`node_modules`、构建缓存、Git 历史、预览和重复副本属于旧版范围。
- 可恢复清理：先把原包完整备份到 `.folder-organizer-backups/20260829-163543/灿若星辰灯.original.zip`，再把被替换的原包移动到 `.folder-organizer-trash/20260829-163543/灿若星辰灯.original.zip`；两份恢复副本的 SHA-256 均与原包一致。原路径已替换为 `598155` 字节精简包，SHA-256 为 `89d45b542b8f8e58deaad7ea5802366fe659b7ac69a17fe7b4df7fc4bc7ea47c`，只含五张正式素材、README 和 JSON 清单。外部恢复清单位于 `.folder-organizer-manifests/20260829-163543-canruo-star-lamp.json`。
- 项目接入：五张正式素材复制到 `src/assets/rpg/cinematics/chapter4-755/canruo-star-lamp/` 并逐项复核哈希。新增 `ChapterFourStarLampClosure`，按正式 `6200ms` 序列完成暗场、轮廓、LED、灯芯、光晕和镜头拉远；`ChapterFourClosureSessionRegistry` 只为真实播放完成回调签发一次性 runtime proof，控制器验证后才允许 `acknowledge_exterior_closure` 写入完成状态。
- 存档收口：SaveStore 升级到 v32。只有 v32 且 `phase=complete`、双签到、配电锁定、最后一分钟装回、灯光准备和外景回执全部一致时才恢复正式完成；旧版、裸布尔值或不完整字段继续降级到安全的 `exterior_closure`。正式回执会保留 `exterior_closure_acknowledged=true / completed=true`，并返回手机主页。
- 文案与预热：DEV 节点改名为“灿若星辰正式收束”；任务提示改为播放完成后自动结算；五张分层素材加入第四章收束阶段预热。章节文本重新导出并通过 `text:check`，总计 `6513` 条。
- 验证：`npm run typecheck`、`NODE_OPTIONS=--max-old-space-size=6144 npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。离线单文件为 `258649544` 字节、两个内联脚本和一个内联样式，SHA-256 为 `3ff9e53b71b65a5f2125ef0fc28ff8160440415b7bbaa7e9b9794ad708f1e355`。应用内浏览器在本地 HTTP 完整播放正式灯光，画面中五层按原坐标组合；结束后返回手机主页，任务显示“章节完成 1/1”，console/page error 为 `0`。`file://` 自动控制受浏览器安全策略禁止，单文件通过结构、资源内嵌与哈希验证。
- 交付边界：本轮没有新增测试文件或测试依赖，没有执行 Git 暂存、提交、合并、推送或上传。`demo/index.html` 只由构建命令生成；其他既有未提交改动均保留。

## 2026-08-29 启真湖石块与浮标碰撞核心化

- 用户指出黑天鹅追逐河道的石块与浮标空气墙明显大于可见物体，并要求继续核对其他启真湖地图。本轮仅校准水面上的离散小型障碍；岸线、码头、木排、围栏和大型水草仍使用各自的源像素碰撞。
- 河道三组石块由原来的三个大矩形改为四个逐石块核心框：西侧单石、东部双石分别拆开、最东侧单石。碰撞只覆盖露出水面的岩石轮廓，不再包含浅色水底、涟漪和两石之间的水面。
- 河道五个浮标由约 `24–25×38–39px` 收紧到 `16×23–26px`。同时补齐码头五个和大湖四个可见浮标的精准核心碰撞；启真湖四图现在共有十四个浮标碰撞，黑天鹅围栏图没有独立水面浮标。
- 数据权威集中到 `QIZHEN_LAKE_DISCRETE_KAYAK_COLLISIONS`，四张 `1672×941` 母图按地图维护同一套小型障碍矩形。追逐验证器增加数量、尺寸、世界边界和运行时引用一致性检查。
- 自动验证：`qizhen:validate-swan-chase` 通过 `164` 项断言，`qizhen:validate-rain-safety` 通过 `70` 项断言，`typecheck`、`build:single`、`verify:single` 与 `git diff --check` 通过。离线单文件为 `257652626` 字节，SHA-256 为 `6cb5d79ca7fb1e7c4481398aec4632edc1bbd1d5758dd39bcc919cce045e960d`。
- 浏览器验证：使用 `develop-web-game` 标准客户端分别打开码头登船、开阔水域、黑天鹅围栏与直河道追逐检查点。开发碰撞层确认十四个浮标框均贴合橙色实体、河道四个石块框逐石分离，浅水纹、藻斑、涟漪和石块间水面均可通行；围栏图的岸边石块继续由岸线轮廓统一阻挡。最终 `file://` 单文件成功进入 `qizhen_chase`，运行时返回四个新石块框和五个新浮标框，未产生 console/page error 文件。
- 交付边界：本轮只修改启真湖碰撞模型、对应回归验证器与进度记录，并重建本地 `demo/index.html`；没有执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-29 A 范围交付与合作者第四章修复集成

- 提交范围：按用户确认的 A 方案提交当前批准的源码、玩法数据、美术与音频资产、验证器及文案记录；继续排除 `demo/index.html`、`dist/`、Godot 归档和临时浏览器产物。离线单文件因体积超过 GitHub 单文件限制，仅作为本地交付物保留。
- 合作者基线：合入远端 `origin/main` 的 `866ae84 fix(chapter4): restore floor loading and reality cues`，保留暂停 Phaser 后恢复、分阶段楼层贴图原子提交、A3 错位楼梯返回 A2 落点、宿主暂停场景复用及配电拓扑修复。
- 语义消解：第四章继续使用本地统一现实模式视觉层；深色观察为青蓝扫描氛围，浅色操作为暖金边框氛围。两种模式的谜题点始终存在，不匹配模式以低透明度休眠，玩家可任意调查顺序并获得模式纠正；可操作权限仍由控制器验证。删除了远端重复遮罩和重复发光实现，避免同一场景出现两套视觉权威。
- 自动验证：`npm run typecheck`、第四章 story、runtime（`1095` 项）、warmup（`77` 项）、topology（`2769` 项）、effective interactions（`435` 项）、assets、Task 14（`365` 项）全部通过；关键玩法套件 `11/11` 通过，并通过 3.5 章 `48` 种证据完成顺序、深浅模式 `180` 项顺序验证、启真湖雨天安全、分级节奏钓取、黑天鹅追逐、第三章追逐音频、RPG 朝向无关、人物帧与紫金港地图验证。
- 音频与发布：第三章 `77/77` 音频合同和 3.5 章 `11` 个录音资产验证通过；生产构建通过。`build:single` 与 `verify:single` 通过，`demo/index.html` 为 `257651801` 字节，含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：Playwright 驱动真实 Chromium 检查 `390×844` 手机首页、`1440×900` 剧院入口和第四章入口；三处均脱离加载占位，关卡导航和 RPG 画布正确，console error 为 `0`。项目自带 `verify-browser-smoke.mjs` 在本机 Chrome 的同步截图调用达到 `60s` 超时，随后改用项目外 Playwright 会话完成等价验证；临时快照和日志已移出工作区。
- CI 修复：首次推送后的 GitHub Web CI 在关键玩法套件内运行 `audio:pursuit:verify` 时找不到 `ffprobe`。根因是工作流把 FFmpeg 安装放在关键套件之后。现已将 FFmpeg/ffprobe 准备步骤移动到关键套件之前；本地关键套件和完整音频合同已通过，最终远端状态以后续 GitHub Actions 运行结果为准。
- Git 状态：本节记录于本地功能提交 `1db10e3` 与远端 `866ae84` 的合并过程中；此处尚未声明推送或远端 CI 完成，最终状态以合并提交、远端 SHA 和 GitHub Actions 为准。

## 2026-08-29 第三章北向校园地图主角缩小 50%

- 范围：只调整 `BootScene` 使用的北向紫金港校园地图主角。室内、第四章、启真湖步行与皮划艇、剧院至启真湖侧视过场继续使用原共享人物比例。
- 显示契约：共享人物基准保持 `0.65`；新增北向校园专用倍率 `0.5`，实际显示比例为 `0.325`。运行时尺寸由 `62×83` 世界像素降为 `31×42`，姓名标签按新图像顶部重新定位。
- 碰撞与玩法：缩放继续通过共享 `applyRpgPlayerVisualScale` 应用，脚部碰撞保持 `19.5×14.63` 世界像素；出生点、移动速度、地图路径、剧院入口半径和交互范围均未修改。
- 回归门禁：`verify:rpg-player` 新增北向校园专用比例与 `BootScene` 接入检查，防止以后误改全局人物比例或退回全尺寸配置。`npm run verify:rpg-player`、`npm run verify:rpg-character-sprites`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。
- 浏览器验证：`develop-web-game` 标准客户端在 Vite 与最终 `file://` 单文件中完成左右移动；单文件 Blink 状态从 `x=3300` 连续更新至 `3322`、`3349`，剧院入口按 `Space` 后进入 `theater_interior / theater_lobby`。Blink、Gecko、WebKit 均确认 `displayScale=0.325`、`displayWidth=31`、`displayHeight=42`、碰撞 `19.5×14.63`，console/page error 为 `0`；`390×844` WebKit 页面无横向溢出且保持单个 Phaser canvas。
- 单文件：`demo/index.html` 为 `257646004` 字节，SHA-256 为 `a62c2fe3c5ea5296718a1eeedfec1fd9be94b919c31b805d2a8063873ab09040`。
- 交付边界：本轮直接修改现有 `main` 工作区并重建本地单文件，没有执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-29 755 米自行车换道抖动修复

- 根因：3D 骑行渲染器先平滑移动骑手，随后又把 `-laneVelocity * 0.032` 作为横向相机偏移逐帧累加。一次向右换道中，相机会先向左移动，再拉回骑手所在车道；该增量也没有按帧时间缩放，帧率变化会改变回摆幅度。
- 运动修正：删除逐帧累加的相机反向偏移。骑手横移、横向速度、车身倾角、车把转角和相机跟随统一改用按 `deltaSeconds` 计算的指数响应；车身与车把继续保留同向倾斜，换道规则、车道目标、碰撞、距离、踏频和结算权威均未修改。
- 可观察性：3D 画布调试状态新增骑手横坐标、目标车道横坐标、平滑横向速度、车身侧倾和相机横坐标。食堂自行车合同新增 `runtime.chase-renderer.stable-steering`，要求上述运动使用帧率无关响应，并禁止重新引入 `lateralLag` 相机反向增量。
- 自动验证：`npm run verify:canteen-bike-transition` 通过 `41/41` 项，`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。离线单文件为 `257645955` 字节，SHA-256 为 `4b48d636d60f8741183a93f1e988c5106a4bb5209e02c43ff18f2825036e5d13`。
- 浏览器验证：在 Blink 的 Vite 版 Three.js 骑行画布中分别执行右换道和左回位，两次骑手横坐标与相机横坐标的方向反转均为 `0`，车身倾角和车把转角只向本次换道方向变化后归零。随后从最终 `file://` 单文件进入 `c3-canteen-chase`，右换道从 `riderX=0` 连续到 `3.35`、相机从 `0` 连续到 `0.904`，方向反转均为 `0`；运行仍处于 `755m` 故事模式，`3` 次机会、车道 `2`、碰撞 `0`。Gecko 与 WebKit 也各自运行 Three.js 右换道；两者的骑手与相机方向反转均为 `0`，转角单向变化后归零，三引擎 console/page error 均为 `0`。
- 交付边界：本轮重建本地 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-29 远端 main 更新与第四章本地修复合并

- 远端同步：成功 fetch 并将本地 `main` 从 `66da254` 快进到 `760cbbf`，纳入 `c174eaa / ac30d19 / 760cbbf` 三个远端提交，共 `65` 个文件、`9197` 行新增和 `6569` 行删除；本地没有领先远端的提交。
- 本地保护：合并前只把 `8` 个已跟踪修改放入临时 stash，`1456` 个未跟踪文件保持原地不动（Godot `1429`、启真湖浏览器素材 `23`、脚本 `3`、第三章文案 `1`）。快进后恢复本地改动，仅 `ChapterFourPowerPanelGame.tsx` 与 `chapter4-755.css` 发生内容冲突，其余六个文件自动合并。
- 冲突收口：保留远端新增的空间方向键导航、更醒目的四像素线路和两行节点状态布局，同时保留本地的五边形节点位置、由 `adjacentZoneIds` 动态生成的唯一相邻图、明确的“自身和直连区域”规则及无答案标记约束。对应故事验证改为检查实际数据派生连线、绝对定位拓扑和空间导航，不再锁死远端曾使用的常量名与三列 CSS。
- 配电新基线：远端将开局供电从 `mask=6` 改为 `mask=14`；最终离线单文件实际完成“大厅—西走廊—东走廊—面包店后场”，状态为 `14 → 9 → 26 → 23 → 13`，随后自动锁定并进入 `final_chase`。五个按钮、五条模型派生连线和每步灯态一致。
- 模式与楼梯保留：合并后浅色仍只渲染并开放 105 讲台终端，深色只渲染并开放 104 黑板残影；深色遮罩为 `0.54`，荧光点计数为 `1`。暂停 Phaser 后恢复 A2、分阶段 plate 原子提交和 A2 楼梯落点修复均通过合并后的第四章验证。
- 自动验证：`typecheck`、第四章 story、runtime（`1095` 项）、warmup（`77` 项）、topology（`2769` 项）、effective interactions（`435` 项）全部通过；远端 critical 套件包含的 `9` 个验证逐项通过，另通过启真湖工具分支 `114` 项与室内门 `28` 项。`build:single` 与 `verify:single` 通过，离线文件为 `252443274` 字节、`2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：开发服务器在 `390×844` 手机首页、`1440×900` 剧院和第四章检查点均脱离加载占位，画布、运行场景和文档尺寸正确；最终 `file://` 单文件再次完成完整配电序列及浅/深模式互斥，console/page error 为 `0`。远端 `run-test-suite.mjs` 在 Windows 上以 `spawnSync npm.cmd EINVAL` 失败，`verify-browser-smoke.mjs` 也无法发现本机 Chrome；其底层验证和等价 Chromium 场景均已直接执行通过，本轮没有扩大范围修改这两个远端工具。
- Git 边界：合并后 `main` 与 `origin/main` 对齐，八个本地修改保持未暂存，全部未跟踪文件保持原状；本轮临时 stash 在逐文件核对后删除，更早的历史 stash 未动。未提交、未推送、未上传，临时浏览器配置已删除。

## 2026-08-28 第四章提示点收口与五区配电相邻关系校正

- 提示点边界：撤回此前额外叠加的内外两圈提示图形；每个可见目标只保留原来一个提示点。只有合同明确标为 `requiredMode: "dark"` 的原提示点在深色观察下使用 ADD 呼吸荧光，浅色专属目标保持原琥珀点，无模式要求的通用交互不再被误标成荧光线索。
- 模式互斥：有模式要求的目标继续同时按渲染、附近交互和可操作集合过滤。浏览器实测浅色只出现并可操作 `a1_classroom_105_lectern_terminal`，深色只出现并可操作 `a1_classroom_104_blackboard_residual`；深色遮罩透明度为 `0.54`，荧光提示点计数从误加后的多个收口为 `1`。
- 配电相邻关系：五区按钮由无连线的双列清单改为与权威模型一致的五边形线路图，顺序为“大厅—西走廊—面包店后场—教室区—东走廊—大厅”。五条线直接从 `adjacentZoneIds` 生成，不维护第二份隐藏关系；方向键按画面空间位置移动。没有新增答案标记、推荐点击或解法提示。
- 配电规则说明：面板明确写出“按下一区，会切换它自身和连线直接相接的区域”。同步远端新基线后，实际联动为 `14 → 9 → 26 → 23 → 13` 并自动锁定进入最终追逐；每一步只改变自身和画面直连节点。
- 视觉与离线验证：Blink 在 `1280×720` 与 `390×844` 检查五条线均精确落到节点中心、按钮零重叠、面板和文档零溢出；收窄节点后底部连接不再被按钮遮到难以辨认。最终 `file://` 单文件重新验证五节点、五连线、完整新配电序列以及浅/深目标互斥，console/page error 为 `0`。
- 自动验证：同步远端后，`npm run typecheck`、第四章 story、runtime（`1095` 项）、warmup（`77` 项）、topology（`2769` 项）、effective interactions（`435` 项）、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。离线单文件为 `252443274` 字节、`2` 个内联脚本和 `1` 个内联样式。
- 交付边界：临时浏览器配置和截图已删除；未触碰现有未跟踪的 Godot、启真湖素材与第三章文案文件，也未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-28 第四章楼梯返回 A2 与现实模式视觉修复

- 楼梯返回根因：Three.js 错位楼梯接管期间 Phaser 场景处于 paused，宿主原先只把 active 场景视为已运行，恢复检查点时可能把暂停场景重新 start；同时楼层同步只看控制器楼层，未要求目标贴图、背景对象与已应用 projection 同时就绪，因此会先切到 A2 的空白区域。
- A2 到达事务：宿主把 active、paused、sleeping 都视为同一在途场景；Phaser 在 resume 时显式完成阶段预热、背景创建、强制 projection 提交，再进行楼层同步。plate 事务只原子提交资源实际就绪的楼层并准确记录已应用贴图，当前楼层与控制器新目标楼层的贴图缺一不可；开场仍可只预热 A1。A3 楼梯成功后使用 A2 源像素楼梯落点 `x=1036, y=214`，不再落到电梯安全点。
- 模式呈现：深色观察在亮地图上增加 `0.54` 的深蓝压暗层，地图与场景物体被压暗而主角、底部提示和共享 HUD 保持可读。深色提示点改为青蓝色 ADD 叠加的呼吸荧光；204 教室残影也使用同一荧光层级。
- 模式交互：有 `requiredMode` 的提示点在不匹配模式下从渲染集合、附近交互、空间证明和道具投放候选中同时移除；204 实体桌椅只在浅色操作中可选。无模式要求的对话、校史人物与通用场景交互继续在两种模式中可用。
- 可观察性与回归：第四章运行时调试状态增加压暗透明度、遮罩/提示点深度和发光提示点数量；预热验证补上 paused 场景复用、resume 同步、分阶段原子贴图、目标 plate 就绪和 A2 楼梯落点断言，故事验证补上模式互斥、深色荧光与 204 桌椅浅色限定。
- 浏览器验证：Blink 从 `c4-755-room204-1850` 实际完成 A3 Three.js 楼梯并退出，恢复后为 `A2 / c4_a2_corridor / a2_1850_evening`，玩家世界坐标 `2900,214`，物理边界为 `x=1864, width=1672`。浅色显示 `12` 个 204 槽位且不显示残影组；深色槽位为 `0`、残影组可见、遮罩透明度 `0.54`、残影与提示点均为 ADD 发光；切回浅色后全部恢复。最终 `file://` 单文件另验证开场仍正确应用 `a1_2245_opening` 且没有 plate/background 失败，以及 104 深色目标与 105 浅色目标互斥、压暗和发光计数；console/page error 为 `0`。
- 自动验证：`npm run typecheck`、`chapter4:validate-story`、`chapter4:validate-runtime`（`1252` 项）、`chapter4:validate-warmup`（`77` 项）、`chapter4:validate-topology`（`2769` 项）、`chapter4:validate-effective-interactions`（`435` 项）、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。离线单文件为 `252406171` 字节、`2` 个内联脚本和 `1` 个内联样式。额外 Task 14 音频时长验证因当前环境缺少 `ffprobe` 在音频探测处退出；本轮未修改音频合同。
- 交付边界：本轮重建本地 `demo/index.html`，未触碰现有未跟踪的 Godot、启真湖素材与第三章文案文件，也未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 3.5章语音备忘录红黑主题与波形作用域修复

- 视觉统一：3.5章语音备忘录改为黑色细网格底、深灰录音卡片、红色播放按钮、红色录音波形和暗红选中状态；全局手机状态栏保持既有浅色系统样式，应用边界清晰。未播放、播放、已保留、排序、反馈和键盘聚焦状态均使用同一组语义色变量。
- 根因修复：首页“录音”图标与录音列表原来共用 `.voice-wave`，首页图标的绝对定位覆盖了录音卡片波形，导致波形集中显示在标题栏右上方。首页图标改用独立 `.voice-icon-wave`，七段录音各自的波形恢复到对应卡片内。
- 行为边界：没有修改七段恢复录音、试听时长、四段筛选、声音事件标注、排序判定或章节进度；本轮只修改视觉样式与首页图标类名。
- 自动验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；离线单文件为 `252401262` 字节，包含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：使用 `develop-web-game` 标准客户端分别检查 Vite 与最终 `file://` 单文件的 `c3-interlude-voice` 检查点。未播放和播放两种状态下，所有波形均位于各自录音卡片；播放中的第一段显示红色描边、停止按钮和高亮波形，console/page error 为 `0`。临时截图和状态文件在目视检查后删除。
- 交付边界：本轮重建本地 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 图书馆信息台盖章器像素素材替换

- 问题定位：第二章图书馆信息台的盖章器原先由三个 Phaser 矩形拼接，和 `library_interior.png` 的高细节像素美术不一致；旧坐标还让印章压在前台工作人员身前。
- 生成素材：使用内置 `imagegen` 生成透明底俯视像素印章，保留木柄、黄铜连接件与暗红印面；原始输出裁去透明空边后，以最近邻缩到 `64×88`，保存为 `src/assets/rpg/props/library_front_desk_stamp_v01.png`。最终运行时显示为 `28×40` 世界像素。
- 最终提示词：`transparent 2D pixel-art game prop sprite; compact manual library verification rubber stamp; dark walnut wooden handle, brass neck, muted red rubber base; top-down three-quarter view; warm modern-library RPG palette; one isolated object; no text, no logo, no watermark; readable at about 32×44 pixels`。
- 接入方式：`LibraryInteriorScene` 预载并预热新贴图，用生成的 `Image` 替换旧矩形 `Container`。盖章状态、报告递交、扫描线、盖章下压与回弹仍由既有控制器和 Tween 驱动。印章静置坐标调整到柜台桌面空位，避免遮挡人物与状态牌。
- 自动验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；离线单文件为 `252399065` 字节，包含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：使用 `develop-web-game` 标准客户端分别打开 Vite 与最终 `file://` 单文件的 `c2-nonperson-stamp` 检查点。两轮定位修正后，印章完整位于柜台桌面，未遮挡工作人员、状态牌或既有桌面物件；console/page error 为 `0`。临时截图与裁剪图在目视检查后删除。
- 交付边界：本轮重建本地 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。用户关于“浙大钉校园地图”的后半句尚未提供完整修改要求，因此未推断或改动该页面。

## 2026-08-27 第四章分阶段预热失败恢复与受限设备调度

- 初始就绪判定：`ChapterFourTemporalMazeScene` 不再根据“计划预载到哪个阶段”直接把阶段标记为 ready；进入 `create()` 时逐项检查 Phaser texture，任一贴图缺失都会保留阶段与短格式资源明细，并进入可重试状态。
- 推测与必需加载：新增纯策略模块 `ChapterFourWarmupLoadPolicy.ts`。必需阶段在低网速、节省流量和低内存设备上仍完整加载；推测加载逐项等待浏览器空闲片段，受限设备每批最多两项并自动续批。重试退避由最早缺失的前置阶段决定。
- 失败时可继续操作：状态切换缺资源时保留当前已应用的 projection、碰撞与玩家控制，不清空旧画面。底部持续显示失败阶段和数量，键盘 `R` 与点击均可重试；第四章入口 Gate 接收同一失败事件并使用原入口按钮重试。失败 URL 在单文件 data URL 场景下折叠为 `inline:<asset-key>`，避免调试状态复制整段内联资源。
- 生命周期：Phaser 的 idle wait 与 Loader Promise 都注册可结算取消器，scene shutdown/restart 会立即收口在途等待；generation 阻止旧 scene 回调续载到新实例。手机侧浏览器预热也能在组件取消后收口；后续即时请求可把仍在运行的推测任务提升为必需任务。
- 指标修正：浏览器图片缓存复用时，本次尝试的传输与解码字节均为 `0`，measurement 回到 `unknown`；`image.decode()` reject 记为失败并从可复用缓存删除。调试状态新增 required phase、已加载阶段、在途阶段、失败详情与重试时刻。
- 可执行验证：`npm run chapter4:validate-warmup` 先在策略模块缺失时按预期失败，实施后通过 `70` 项静态与 fake-loader 行为断言；`npm run typecheck`、Task 14 的 `365` 项断言和 `git diff --check` 通过。`chapter4:validate-runtime` 仍有 `4` 条并行教室有效交互导致的旧 Quest 固定顺序断言，交由统一任务模型收口，本轮未越界修改。
- 交付边界：本轮未构建或编辑 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 食堂、剧院与启真湖现实模式解序

- 通用规则：保留“深色观察 / 浅色操作”的语义与 `wrong_mode` 反馈；进入场景、交互成功、交互失败和小游戏结算均不再自动改变现实模式，由玩家自行切换。
- 食堂：D 套餐可在浅色模式直接完成实体领取；出口车可先推动；自行车清洁与付款不再依赖先读取车锁编码。深色模式仍可记录窗口、出口和车辆线索，但这些兼容字段不再成为浅色操作的唯一门槛。
- 剧院：正确票码可直接释放临时票，临时票可直接完成验票与道具箱扫描；追光玩法不再强制切换模式。玩家在追光准备或追踪阶段切回深色时，只暂停并等待手动回到浅色，不扣除尝试次数。
- 启真湖：鱼竿、正确钓点和最终纸条目标不再因未观察而隐藏；正确浅色操作不依赖先记录倒影坐标。错误目标与错误模式仍在开启节奏会话前被拒绝，不消耗故事物品，也不创建部分会话。
- 顺序回归：新增 `npm run verify:rpg-reality-mode-order`，覆盖浅色先行、深色先行、错误模式无状态消耗、无自动切换、手机临时票直接释放和启真湖节奏预检，共 `74` 项断言。
- 自动验证：现实模式顺序 `74` 项、剧院追光故事、启真湖四张钓鱼谱面、启真湖雨天安全 `47` 项、食堂自行车转场 `40` 项、JSON 解析、`git diff --check` 与 `npm run typecheck` 全部通过，剩余错误为 `0`。
- 交付边界：本轮未构建或编辑 `demo/index.html`，未修改第四章、3.5章或宿主运行时，也未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 全游戏玩家文本按章节导出

- 导出产物：新增 `docs/game-text-by-chapter.md`，按第一章、第二章、第三章、3.5章过渡、第四章、结局、跨章节与共用系统七组排版；每条文本保留可点击的源码文件与行号，同章重复文本合并但不丢失来源。
- 提取机制：新增 `scripts/export-game-text.mjs`，使用 TypeScript AST 扫描 `src/` 中的 TS、TSX 与 JSON；收录对白、字幕、任务、按钮、帖子、物品、提示、失败反馈和玩家可见状态，动态模板统一显示为 `{{表达式}}`。
- 范围清理：排除开发者面板与 checkpoint、调试工具、测试断言、内部 ID、资源路径、存档字段、运行时诊断，以及 MiniMax 等配音制作字段；增加导出质量门禁，发现调试 HTML、开发模块来源或配音生产提示时直接失败。
- 当前统计：共 `6156` 条去重文本，来自 `128` 个源码文件；第一章 `401`、第二章 `406`、第三章 `1098`、3.5章 `289`、第四章 `1190`、结局 `88`、跨章节与共用系统 `2684`。
- 可重复运行：`npm run text:export` 重新生成；`npm run text:check` 验证 Markdown 与当前源码完全同步。两条命令均已立即执行并通过。
- 交付边界：本轮仅生成 Markdown 与导出工具，不重建 `demo/index.html`，不执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 第四章最终保安追逐逻辑优化

- 根因：最终追逐原先每帧都按玩家当前坐标重新选择最近图节点，保安使用固定 `196px/s`，同一次物理接触立即失败。玩家经过节点分界或转弯时，目标会来回切换；距离过远时追逐失去压力，拐角短暂擦碰时又可能误判。
- 路径追踪：继续使用 A1/A2 已校准的十二节点路线和正式碰撞体，不允许保安直线穿墙。模型根据玩家最近移动计算 `320ms` 受限预判位置，并对新目标保持 `260ms`；保安到达目标点 `34px` 内才允许提前重选，减少分岔口左右反复转向。
- 压力曲线：保安与玩家的图路径距离大于 `420px` 时使用 `224px/s` 追赶，`120–420px` 使用原合同 `196px/s`，小于 `120px` 时降至 `178px/s`，给玩家留下转向与脱离空间。三档速度均由纯模型输出，Phaser 只负责碰撞、动画和实际位移。
- 公平抓捕：追逐开始提供 `700ms` 接触保护，跨主楼梯抵达 A2 后提供 `420ms` 保护；保护结束后仍需持续接触 `180ms` 才判失败。202 终点和 A1 主楼梯入口在同帧接触时优先成立，避免门槛与楼梯边缘的一帧误抓。
- 可观察性：`render_game_to_text()` 增加预判坐标、目标保持时间、压力档位、实时速度、图路径距离、接触累计时间和剩余保护时间，便于以后调整难度时复用同一套证据。
- 自动验证：`npm run typecheck`、`npm run chapter4:validate-runtime`（`1225` 项）、`npm run chapter4:validate-story`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 全部通过。单文件为 `252361681` 字节，包含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：使用 `develop-web-game` 标准客户端从离线单文件进入 `c4-755-chase` 并连续操作。实际状态依次覆盖 `close=178`、`tracking=196`、`catch_up=224`，目标沿 `a1_lower_hall → a1_main_stair` 前进，画面中保安方向与速度一致；console/page error 为 `0`。临时截图和状态文件在目视记录后删除。
- 交付边界：本轮重建了本地 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-27 启真湖雨天环境特效增强

- 问题基线：原雨天码头只有一层蓝色滤色与 `34` 条均匀雨线，实际 `960×540` 画面仅能同时辨认约 `10–12` 条雨线；湖面缺少清晰的落雨反馈，铺装地面也没有连续湿润感。
- 分层雨景：雨天码头改为 `64` 条远景细雨与 `36` 条近景亮雨，两层使用不同长度、速度、透明度和深度；增加 `3` 条低雾带、`4` 组不规则湿面反光，并停用晴朗状态的湖面高光，避免天气效果互相叠加。
- 湖面反馈：按 `1672×941` 源图手工布置 `18` 个湖面落点，全部限定在码头水域内；每个落点包含短促水滴触点与扩散环，连续帧中按错开的周期出现。减少动态效果设置开启时保留静态雨景，不创建循环动画。
- 天气差分：雨天调试状态输出 `rainEffects.active=true`，转为多云后为 `false`；多云状态停用雨线、低雾、落雨环和雨中湿面，只保留既有的四处雨后水坑及其脚点提示逻辑。
- 自动验证：`npm run typecheck`、`npm run qizhen:validate-rain-safety`、`git diff --check`、`npm run build:single` 与 `npm run verify:single` 全部通过；雨天安全验证共 `47` 项断言，离线单文件为 `252358325` 字节、`2` 个内联脚本、`1` 个内联样式。
- 浏览器验证：用 `develop-web-game` 标准客户端通过 `file://` 分别进入 `c3-qizhen-rain-hold` 与 `c3-qizhen-overcast`。Blink 雨天连续三帧可见两层雨线位移与湖面落雨环，多云画面无雨线和落雨环；随后 Gecko 与 WebKit 均确认雨天状态、单个 Phaser canvas 和完整特效计数。`390×844` iOS Safari 场景保持雨天状态，横屏提示正常且文档无溢出。三种引擎全部进入 `qizhen_lake / qizhen_dock`，console/page error 为 `0`。临时截图在目视记录后删除。
- 交付边界：本轮只修改当前交付工作树并重建本地 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-27 浙大钉开发者反馈入口与个人菜单单行修复

- 反馈入口改造：工作台原“意见草稿”调整为“开发者反馈”，页面明确面向 `7:55` 游戏开发团队；加入真实 GitHub 仓库入口与“提交 Issue”入口，Issue 会自动带入反馈分类、首行标题、完整反馈内容和游戏名称。
- 全局提示清理：删除玩家可见的“本 Demo”“真实部门”“不发送账号请求”“不连接真实账号服务”等说明；个人页原账号安全占位项改为“开发者反馈 / GitHub Issues”，首次 CC98 认证和应用状态提示也改用剧情内文案。离线单文件复查上述四类旧文案均为 `0` 处。
- 个人菜单修复：将纯文本菜单从通用的“图标 + 文本”双列布局中分离，`个人资料`、`账号与安全`、`退出浙大钉` 三项固定为单列、单行、超长省略；浙大百事通搜索结果恢复原有图标列表布局。
- 自动验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；离线单文件为 `252355883` 字节，包含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：Blink 在 `319×739` 窄屏完成“主页 → 浙大钉 → 个人菜单 → 工作台 → 开发者反馈 → 保存草稿 → GitHub 仓库 → 提交 Issue”链路。三项菜单的计算样式均为 `white-space: nowrap`，每项 `clientHeight=scrollHeight=52`；两个链接打开的地址正确，Issue 标题与正文预填正确，反馈保存状态可见，console/page error 为 `0`。另用 `develop-web-game` 标准客户端打开最终离线单文件，运行状态正常。
- 交付边界：本轮重建了本地 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-27 主角侧向十二帧左右迈腿循环

- 问题定位：共享主角侧向运行时原来只使用 `8` 张姿势，现有帧间缺少明确的承重腿交换，连续播放时容易读成同一条腿反复前伸。原素材中的第九张侧姿尺寸比统一角色合同大约高 `8%`，没有直接插入，避免角色在步行时忽大忽小。
- 动画修订：侧向周期扩展为 `12` 帧，分成两组六帧半步。`0–5` 使用近侧腿承重、远侧腿摆动，`6–11` 交换为远侧腿承重、近侧腿摆动；手臂同步反向摆动。两组半步的轮廓高度统一为 `104/103/102/101/102/103px`，整周期继续使用 `880ms`，侧向帧率为约 `13.64 FPS`。上下方向仍保留既有八帧和同一整步时长。
- 透明素材：通过内置 ImageGen 生成四张独立过渡姿势并确认 PNG alpha 通道，再由 `scripts/build-rpg-player-frames.py` 与原八张姿势共同生成 `96×128` 的 `player_side_0.png` 至 `player_side_11.png`。源图保存在 `src/assets/rpg/player/source/player_side_transition_01_v3.png`、`23_v3.png`、`45_v3.png`、`67_v3.png`，未采用两张带棋盘底或尺寸失配的候选。
- 运行时统一：Phaser 共享主角和第四章错位楼梯 Three.js 例外场景都改为方向感知帧数；侧向读取十二帧，上下读取八帧。第四章 `render_game_to_text` 增加实际 `texture`、`turning` 与 `walkFps`，便于回归运行时播放序列。
- 自动验证：`verify:rpg-player` 确认 `28` 张运行时帧全部唯一，其中向下 `8`、向上 `8`、侧向 `12`；`verify:rpg-character-sprites` 确认透明轮廓完整、头脚未裁切且十二帧身高合同稳定；`typecheck`、`chapter4:validate-stair-materials` 的 `26` 项检查、`build:single`、`verify:single` 与 `git diff --check` 全部通过。单文件为 `252354725` 字节，包含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验证：先使用 `develop-web-game` 标准客户端从 `c4-755-bakery-1225` 打开离线单文件；随后在 Blink、Gecko、WebKit 中分别按住右键和左键连续采样。三个引擎的两个方向都严格循环 `act1-player-side-0` 至 `act1-player-side-11`，实际帧率为 `13.6363`；Blink 四个关键相位的实画面可辨认两条腿交替落地与蹬离。三引擎 console/page error 均为 `0`，临时截图、状态和验证脚本在目视记录后删除。
- 交付边界：本轮只修改当前交付工作树并重建本地 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-27 单文件交付候选构建

- 基于当前 `delivery-20260826` 源码重建 `demo/index.html`。`npm run build:single` 通过，Vite 处理 `659` 个模块；`npm run verify:single` 确认产物为 `252297406` 字节、`2` 个内联脚本、`1` 个内联样式，可直接作为离线单文件运行。
- 构建前回归通过：`typecheck`；第四章拓扑 `2769` 项与运行时合同 `1201` 项；启真湖雨天安全 `25` 项；启真湖日志内容与确定性；任务提示所有权检查 `188` 个源文件。构建后 `git diff --check` 通过。
- 按 `develop-web-game` 标准客户端通过 `file://` 直接打开新单文件并进入 `c4-755-bakery-1225`。Phaser 场景为 `duan_yongping_temporal_maze`，A1 画面正常；主角运行时深度为 `9900`，`a1-ann-014` 与 `a1-ann-015` 对应的两段北侧空气墙均出现在实际碰撞列表中，浏览器 console/page error 为 `0`。
- 交付范围：远端 `main` fetch 和三视图审计完成后，用户选择完整范围 A。源码提交为 `bbc4afd3618808988a61d4297f4c6652b1485cda`；日期化交付目录为 `7-55-upload-20260827`，其中单文件与实现归档及两份 SHA-256 均已通过本地复核。远端交付信息由 `README.md`、`ASSETS.md` 和 GitHub Release `demo-20260827` 统一记录。

## 2026-08-27 第四章北侧墙沿空气墙与主角固定顶层

- A1 北侧肖像墙左右两段下沿新增源像素空气墙：西段复用 `a1-ann-014` 的 `{x:43,y:134,width:496,height:17}`，东段复用 `a1-ann-015` 的 `{x:1201,y:134,width:408,height:20}`。两条墙后通道的半开可通行区分别终止于 `y=134` 与 `y=130`，新碰撞不侵入墙后通道，侧向入口继续开放。
- 复查 A2、A3 同类北侧房间墙沿：A2 的 `006/007/010/011` 与 A3 的 `009/010` 已有源标注碰撞，本轮增加回归断言，避免以后误删；A2 未被选为空气墙的 `a2-ann-022` 继续保持原状。
- 第四章主角深度改为固定 `9900`，移动、场景恢复、最终追逐和电梯出场都不再按世界 `y` 改变深度。墙体前景、栏杆、家具、电梯和 NPC 均低于主角；调试层、任务 UI 与校友详情面板仍位于主角之上。
- 自动验证：`chapter4:validate-topology` 通过 `2769` 项断言，`chapter4:validate-runtime` 通过 `1201` 项断言，`typecheck` 通过。
- Chromium + Phaser 实际刚体验证：西段 `x=500` 与东段 `x=1300` 向下移动时，玩家脚部刚体均精确停在墙沿顶边 `y=134`；西侧 `x=600` 与东侧 `x=1150` 的侧入口可继续向下通过。A1、A2、A3 三个开发检查点的玩家深度均为 `9900`；全部第四章前景裁片的最高深度为 `4881`，电梯最高深度为 `3981`，主角保持在二者之上。浏览器 console/page error 为 `0`。
- 本轮按要求未运行 `build:single`、未编辑 `demo/index.html`；已打开的旧离线单文件仍显示旧内容。

## 2026-08-27 第四章 A2 五处家具空气墙

- 按浏览器蓝框复用 A2 原图的源像素标注，为 201 创客工坊中央工作台、开放学习区长书柜和 203 计算机教室三排电脑桌增加实体碰撞。
- 新增碰撞与已有前景裁片共用 `a2-ann-020`、`a2-ann-021`、`a2-ann-023`、`a2-ann-024`、`a2-ann-025` 的精确矩形，确保阻挡边缘和可见物体一致；未被点名的 `a2-ann-022` 不改。
- 验证通过：第四章拓扑 `2697` 项断言、运行时合同 `1191` 项断言和 TypeScript 类型检查均通过；验证器新增五组“碰撞矩形必须等于前景裁片矩形”的回归断言，并明确禁止误加 `a2-ann-022`。
- 真实 Chromium + Phaser 键盘移动验证通过：玩家分别停在工作台下缘、长书柜上缘和三排电脑桌上缘；玩家从每排左侧间隙绕行到下一条走廊，203 教室没有被横向空气墙封死；测试过程无控制台或页面错误。
- 按用户本轮指示不重新构建离线单文件，现有 `demo/index.html` 保持不变。

## 2026-08-27 第四章 A2 204 教室座椅重心下移

- 问题定位：204 教室的 12 组桌椅、4 张讨论桌和 12 个早晨放置槽位共用源像素布局。原首排脚点为 `y=609`，视觉上靠近教室上沿，底墙前留白明显更大。
- 布局修订：三排桌椅脚点由 `609 / 686 / 757` 统一下移为 `633 / 710 / 781`，共下移 `24px`。4 张讨论桌同步从 `y=686` 移至 `y=710`；12 个深色残影的世界锚点和放置触发框同步移动。讲台、抽屉、门洞、教室边界与房间外家具保持原位。
- 碰撞与通行：桌、椅和讨论桌的脚部碰撞继续从同一布局与 manifest 生成，未增加画面与碰撞偏移。横向通道采样线同步从 `y=623` 移至 `y=647`；三条纵向通道、入口和完整排列后的横向连接仍保持可通行。
- 自动验证：`chapter4:validate-topology` 通过 `2551` 项断言，其中 Room204 为 `1009` 项；`chapter4:validate-runtime` 通过 `1191` 项断言；`typecheck` 与 `git diff --check` 通过。
- 浏览器验证：按 `develop-web-game` 客户端从 A2 走廊实际行走至 204，角色停在房间源坐标约 `(329.67,652.80)`，桌椅视觉重心下移后上下留白接近平衡，讲台保持原位，角色可进入桌椅间通道；截图已目视确认。为定向视觉检查临时改写的开发检查点已立即还原，最终源码仍从 A3 竺老两问与错位楼梯进入 A2。
- 单文件：`npm run build:single` 与 `npm run verify:single` 通过；生成的 `demo/index.html` 为 `252290377` bytes、`2` 个内联脚本、`1` 个内联样式。Playwright 通过 `file://` 打开该单文件，进入 `room204_restore / A3 / c4_a3_wayfinding`，Phaser 场景为 `duan_yongping_temporal_maze`，无 console/page error 文件。
- 交付边界：本轮只完成当前 `delivery-20260826` 工作树与单文件修订，没有执行 Git 暂存、提交、合并、推送或 GitHub 上传。

## 2026-08-26 DEV 章节与关卡分层

- 用户要求最终基于 DEV 划分关卡和章节。现有“章节 → 玩法段落 → 节点”改为正式的“章节 → 编号关卡 → 直达节点”三级导航。
- 六个章节组共划分 28 个关卡：第一章 2 关、第二章 6 关、第三章 6 关、3.5章 2 关、第四章 8 关、寻人篇 4 关；每个既有开发检查点保留原 ID、seed、备份和恢复行为。
- DEV 顶部同时显示章节数、关卡数和节点数；关卡按钮显示编号、名称和节点数量，支持查看本章全部关卡。
- 自动验证：新增 `npm run verify:developer-levels`，验证 `120` 个现有检查点均且仅归入一个关卡、关卡和章节对应、关卡 ID 唯一、章节关卡数固定，结果通过 `550` 项断言；`npm run typecheck`、`npm run build` 与 `git diff --check` 均通过，普通构建处理 `690` 个模块。
- 浏览器验证：按 `develop-web-game` 标准客户端读取真实游戏状态，并在 Blink `1280×720` 与 `390×844` 完成“第四章 4-4 → 4-6 → 本章全部 → 第三章 3-1 → 3-4 → 天气调控节点”的点按链路；共检查 `30` 项，节点数量分别为 `1 / 2 / 13 / 11 / 5`，节点跳转后激活态正确，恢复入口保留，两个视口均无文档溢出，DEV 面板完整位于视口内，console/page error 为 `0`。两张页面截图已目视确认，临时 QA 资产在结论记录后删除。
- 交付边界：未运行 `build:single`，未重建 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-26 A1 前台柜台空气墙

- 用户在第四章 A1 前台柜台区域指出需要空气墙。
- 复用人工标注 `a1-ann-016`，在柜台前景矩形内新增源像素碰撞 `{x:758,y:633,width:179,height:26}`。碰撞覆盖柜台下方实体立面并终止于 `a1_foreground_016` 的遮挡基线；上方 8px 留给 07:55 阶段的读卡器和签到纸槽，避免可拖放目标与空气墙重叠。
- NPC 继续保持无碰撞，柜台前方的交互位置和大厅通道不变。
- 验证完成：`chapter4:validate-topology` 通过 `2551` 项断言，`chapter4:validate-runtime` 通过 `1191` 项断言，`chapter4:validate-assets`、`typecheck`、`build` 与 `git diff --check` 均通过。
- Blink 实际移动：角色从大厅入口持续向上后停在柜台碰撞下沿，调试状态显示角色 `y=634.625`、脚部碰撞体中心位于柜台下方，未穿越空气墙；随后向下可以正常离开至 `y=813.558...`，没有粘墙或合同错误。浏览器截图和状态文件仅用于检查，结论记录后删除。
- 交付边界：未运行 `build:single`，未重建 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-26 CC98 首次统一身份认证解谜

- 入口与身份：首次进入 CC98 时先显示剧情内统一身份认证页，后续帖子、二手交易与章节入口沿用认证结果，不重复拦截。学号使用既有校园卡身份 `3250100755`，玩家需点击“查看随身校园卡”读取并填入；没有校园卡时控制器拒绝读取。
- 象征密码：三段提示按固定顺序展开，分别为浙江大学英文缩写 `ZJU`、求是书院创办年份 `1897` 和认证公告末尾感叹号 `!`，唯一答案为 `ZJU1897!`。大小写与片段顺序均在提示中明确。
- 失败累计：前三次提交可立即尝试；第 3 次失败后锁定 30 秒，第 4 次失败后锁定 60 秒，之后每次增加 30 秒。锁定以绝对截止时间保存，刷新页面不会清零，锁定期间提交不会增加失败次数，正确凭据也必须等截止时间后再提交。
- 进度权威：`ActOneBootstrapController` 统一处理学号读取、提示展开、凭据核验、失败记录与认证完成。`GameState` 和 `SaveStore` 保存认证事实，存档版本升至 `28`；版本 `27` 及更早且已经取得游戏手柄的旧存档自动迁移为已认证，避免后续章节倒退。
- 任务与开发入口：未认证时共享任务栏只显示“完成 CC98 首次身份认证”，认证后恢复“去 CC98 购买游戏手柄”。新增 `c2-cc98-login` 未认证检查点；既有 `c2-gamepad-market` 与后续检查点固定为已认证。
- 配色修订：根据用户复核，删除线索区白底蓝灰配色；页面统一为明亮湖景蓝背景、半透明炭灰认证与线索面板、橙金校徽和提示强调、标准登录蓝按钮，与参考图主色关系一致。
- 自动验证：`npm run verify:cc98-login` 通过 `18` 项断言，覆盖学号一致性、唯一密码、三次即时机会、`30/60/90s` 累计锁定、锁定零写入、认证任务交接、版本 `27` 迁移、正式保存恢复和两个开发检查点。`npm run verify:task-guidance` 检查 `205` 个源文件通过，`npm run typecheck` 与 `npm run build` 通过，Vite 处理 `690` 个模块。
- 浏览器验证：先按 `develop-web-game` 标准网页游戏客户端在桌面检查点读取 `render_game_to_text` 并目视检查页面；再在 Blink `430×860` 完成“读校园卡 → 展开三段提示 → 连续三次失败 → 显示 30 秒锁定 → 测试解除截止时间 → 输入 `ZJU1897!` → 进入原 CC98 二手交易帖子”的完整链路。最终任务为 `chapter_two_direction_purchase_gamepad`，console/page error 为 `0`。
- 交付边界：按用户此前要求未运行 `build:single`，未重建 `demo/index.html`，未执行 Git fetch、stage、commit、merge、push 或上传。浏览器 QA 截图只用于本轮检查，记录结论后删除。

## 2026-08-26 启真湖雨后水坑与脚点证据反馈

- 天气调控完成后，小码头由持续雨线切换为四处雨后浅水坑；水坑使用 `1672×941` 原图坐标，分别位于西侧步道、器材区空地、南侧通道和入口通道。四个包围框均通过可行走区域检查，不与水域、器材屋、器材架、花坛或世界边界碰撞相交。
- 水坑属于视觉与环境叙事层，不参与物理碰撞和剧情进度。玩家保持步行状态时以角色脚点命中椭圆区域；首次踩入每一个水坑发布玩家字幕“这是下过雨的证明”。离开后再次踩入同一水坑不会重复刷字幕，切换到皮划艇不会触发。
- `render_game_to_text` 新增 `afterRainPuddles` 调试状态，包含是否可见、当前踩中的水坑、已经触发的水坑和四个源像素定义，便于自动回归天气差分与脚点命中。
- `qizhen:validate-rain-safety` 扩展到 `19` 项，新增四水坑数量、世界边界、步行碰撞分离、椭圆脚点和精确反馈文案合同。`qizhen:validate-fishing`、`typecheck`、`build` 与 `git diff --check` 同时通过。
- Blink 真实运行：雨天节点保持雨线且 `visible=false`；多云节点显示四个水坑。角色从 `(330,830)` 走到入口水坑后，脚点命中 `entry_path`，页面字幕显示“这是下过雨的证明”，console/page error 为 `0`。离开、等待字幕结束、再次踩入后没有第二条字幕，`enteredIds` 仍只有 `entry_path`。
- 当前边界：按用户此前要求没有运行 `build:single`，没有重建 `demo/index.html`，没有执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。临时 QA 截图与状态文件在记录结论后删除。

## 2026-08-26 第三章启真湖雨天到多云天气调控流程

- 正式流程：启真湖小码头保持初始小雨和禁航。三件器材收齐后，安全员只完成器材核对并提交天气调控申请；玩家返回手机打开天气应用，执行“启真湖小码头天气调控”后，天气才切换为多云并解除登船门禁。绕过安全员直接操作天气应用会被控制器拒绝。
- 任务引导：`boarding_tutorial` 现在依次给出“向湖边安全员申请天气调控”“在天气应用将启真湖调为多云”“交替划左右桨完成上船”三个单一下一目标。天气页只显示当前调控状态和操作结果，跨页面路线继续由共享任务栏负责。
- 状态与存档：`QizhenLakeState` 新增 `weatherAdjustmentRequested`；`rainSafetyCleared` 只在天气应用操作成功后写入。存档版本升至 `27`，版本 `26` 及更早且已经到达上船阶段的存档会迁移为已完成天气调控，避免旧进度被重新锁住。
- 开发者节点：第三章启真湖段新增“雨天安全禁令”“天气调控”“多云开放登船”三个节点，分别固定为器材齐全但仍下雨、申请已提交且天气应用可操作、调控完成并返回码头。节点总数和第三章分组计数由现有开发通道自动更新。
- 视觉同步：天气应用、手机主页天气卡、天气通知和启真湖码头共用 `selectCampusWeather()`。调控前显示“小雨 / 18°C / 湿度 88% / 正在降水”和码头雨线；调控后显示“多云 / 19°C / 湿度 76% / 降水停止”，主页同步去除雨滴，码头同步去除雨线。
- 自动验证：`npm run typecheck`、`npm run qizhen:validate-rain-safety`和`npm run build`通过；雨天安全验证共 `14` 项断言，覆盖禁航、申请事务、天气应用门禁、调控结果和三个开发检查点。Vite 构建处理 `684` 个模块。
- 浏览器验证：按 `develop-web-game` 回归流程运行网页游戏客户端并目视检查调控前天气页。Blink 实际完成“小雨天气页 → 点击调控 → 多云天气页 → 返回主页天气卡”的点按链路，并分别打开雨天码头和多云码头检查雨线差分；console/page error 为 `0`。Blink、Gecko、WebKit 在 `390×844` 触屏视口均完成调控，文档横纵溢出为 `0`。
- 交付边界：遵循用户要求，未运行 `build:single`，未重建 `demo/index.html`，未执行 Git 暂存、提交或上传。浏览器 QA 截图检查完成后已移入废纸篓。

## 2026-08-26 755 米骑行脚踝外翻修复

- 问题定位：两段腿部 IK 能将脚底接触点放到踏板上，但脚掌此前保持局部单位旋转，因此继续继承小腿末端的俯仰和侧倾；踏板进入高低位时，鞋底和鞋头会向身体外侧翻。
- 姿态修复：新增独立脚踝约束。髋—膝—脚链仍由踏板接触点驱动；IK 完成后，左右鞋的世界朝向改为与自行车车架一致，鞋底保持稳定、鞋头沿自行车前进方向。朝向更新后再以父节点局部坐标补偿脚的位置，因此不会牺牲脚底—踏板接触。
- 状态复位：每次重新应用姿势时显式清零左右脚局部旋转，避免骑行姿势留下的脚踝四元数污染站立、下车或推车姿势。
- 可观测性：Three.js 画布新增左右鞋底倾斜、鞋头方向偏差四项调试数据，并保留左右脚接触误差。`verify:canteen-bike-transition` 新增脚踝约束静态合同检查，该项通过；总结果为 `82 checks / 75 passed / 7 failed`，七项仍是既有 overlay、旧 continuation 与 Host 接线缺口。
- 浏览器验证：在 Three.js 骑行调试页以四个相隔约四分之一圈的曲柄相位检查。四相位中左右脚接触误差、鞋底倾斜和鞋头方向偏差均为 `0.000000`，console/page error 为 `0`；四张全景与四张脚部放大截图均已目视确认，鞋子在高位、低位和前后位保持朝前，无外翻。
- 构建验证：`npm run typecheck` 与 `npm run build` 通过，Vite 处理 `684` 个模块。遵循用户要求，未运行 `build:single`，未重建 `demo/index.html`。

## 2026-08-26 755 米骑行腿部踩踏运动修复

- 问题定位：3D 主骑行原先使用 `animationSeconds * 10.5` 固定推进曲柄，同时在腿根叠加 `±sin(phase) * 0.48` 手动摆动。行驶速度变化时踏频不会变化，腿根旋转与脚踏 IK 还会同时修改同一条髋—膝—脚链，导致实际画面中的腿部运动不符合踩踏关系。
- 3D 运动关系：车轮转角继续由实际行驶距离和 `0.5` 世界单位轮径计算；曲柄改为通过共享 `2.6` 齿比从车轮转角推导，踏频随游戏速度变化并限制在 `110 RPM` 以内。腿部姿态只由曲柄接触点和两段 IK 求解，删除第二层腿根摆动。坐姿上下位移从固定时间驱动的最大 `0.035` 收敛为曲柄双周期驱动的最大 `0.008`。
- 后备渲染：2D Canvas 后备路径改用同一轮径、齿比和行驶距离计算踩踏相位；直行帧只使用六张正式骑行帧，移除额外四帧和 `±1.4°` 左右摇摆。转向倾斜继续仅由真实换道位移决定。
- 自动检查：现有 `verify:canteen-bike-transition` 新增“共享齿比 + 曲柄接触 IK 单一控制”和“距离驱动曲柄”两项检查，均通过。该总验证器仍有 `7` 项既有失败，范围为已缺失的过渡 overlay、旧 continuation 和 Host start/ride/finish 接线，本轮没有修改这些模块。
- 构建验证：`npm run typecheck` 与 `npm run build` 通过，Vite 正常处理 `684` 个模块。未运行 `build:single`，未重建 `demo/index.html`。
- 浏览器验证：按 `develop-web-game` 回归流程运行网页游戏客户端，并对 `c3-canteen-chase` 定向检查。Three.js 主路径连续采样四个相位，踏频约 `45.1–51.4 RPM`，齿比输出 `2.6`，左右脚—踏板及左右手—握把误差均为 `0.000000`，console/page error 为 `0`。强制关闭 WebGL2 后，Canvas 后备路径在 `960×540` 下连续四帧正常，帧序随距离推进且无整个人物左右摆动，console/page error 为 `0`。两条渲染路径截图均已目视检查。
- 验证计数：Three.js 主路径 `1` 次多相位实机回归，Canvas 后备路径 `1` 次多相位实机回归；当前跨两条渲染路径的运动关系结论仍按一次改动批次记录。

## 2026-08-26 第四章 A1 一楼前台值班助理 NPC

- 角色接入：在 A1 大厅前台增加“一楼前台值班助理”，复用已入库的透明像素职员两帧素材 `front_desk_staff_2frame.png`，帧尺寸 `96×128`、统一缩放 `0.72`，源坐标为 `x=819,y=652`。柜台前景 `a1_foreground_016` 继续遮住下半身，角色尺寸、投影、光照与现有食堂/图书馆 NPC 保持一致。
- 交互可达性：交谈热区绑定柜台前沿真实矩形 `{x:758,y:625,width:179,height:34}`，有效站立距离为 `104px`。从 `c4-755-classrooms-1850` 默认检查点无需走入柜台，站在外侧即可按 `Space` 完成交谈，交互不读取人物朝向也不限制现实模式。
- 阶段信息：值班助理会根据 `bakery_hour_hand`、`room204_restore`、`morning_checkin`和 `exterior_closure` 回答当前可执行的内容。教室阶段会分别识别 104/105 未完成、只完成一间和两间全部完成，只保留当前信息，不透露后续解谜链。
- 进度边界：交谈 intent 由 `ChapterFourTemporalMazeController` 验证，结果固定为 accepted read-only。它不写入 fact、道具、检查点或楼层状态，不取代 104/105 的必做门禁，不增加第三个通关条件。
- 自动验证：`npm run typecheck`、`npm run chapter4:validate-runtime`和 `npm run chapter4:validate-story` 通过。运行时验证为 `1154` 个断言，覆盖布局锚点、投影 NPC 列表、近距离接受、过远拒绝和交谈零写入。JSON 解析与 `git diff --check` 通过。
- 浏览器验证：Blink `1280×720` 实机检查中，默认检查点的玩家位置为 `x=836,y=716`，目标矩形与 `104px` 交谈距离均正确输出；原地按 `Space` 成功显示“104 要观察黑板残留，105 要检查讲台本地回放”的底部字幕。`contractFailures=[]`，console/page error 为 `0`。
- 交付边界：遵循用户要求，未运行 `build:single`，`demo/index.html` 与当前 Git 基线无差异。

## 2026-08-26 第四章 A1 教室主线门禁与实机交互

- 进程限制：将 104“黑板擦痕延迟残留”与 105“讲台终端本地回放”改为 `room204_restore` 的必做前置。少完成任意一项时，从 A1 请求前往 A2/A3 会以 `classroom_checks_required` 拒绝，不写入楼层、检查点或剧情状态。
- 玩法分工：104 仅在“深色观察”登记黑板书写残留；105 仅在“浅色操作”检查讲台回放。两项分别写入 `classroom_104_chalk_residual_observed` 与 `classroom_105_terminal_replay_checked`，再将任务栏单一下一目标推进到 A3 参照教室。
- 空间实现：两个交互点都使用 A1 `1672×941` 原图坐标。104 绑定东北教室黑板区，105 绑定东南教室讲台区；目标可达、可重复查看，重复交互不重复写状态。
- 自动校验：`npm run typecheck`、`npm run chapter4:validate-runtime` 和 `npm run chapter4:validate-story` 通过。运行时验证为 `1146` 个断言，覆盖错误模式零写入、单教室仍锁楼层、两教室完成后解锁、重复查看只读和任务栏进阶。
- 浏览器验证：新增 `c4-755-classrooms-1850` 开发检查点，从 A1 大厅实际行走到两间教室。104 在深色模式成功写入事实，最终位置 `x=1396.27,y=276.00`；105 在浅色模式成功写入事实，最终位置 `x=1372.80,y=633.87`。两次 `contractFailures=[]`，教室门洞、课桌间通道与交互距离均可用。
- 已知独立失败：`npm run chapter4:validate-topology` 仍有既有 Task11 分钟端点外界差异（期望 `x=967,y=26`，当前 `x=966,y=25`）。本轮没有修改 Task11 端点几何。
- 交付边界：遵循用户要求，未运行 `build:single`，未重建 `demo/index.html`。

## 2026-08-26 共享 RPG 行走相位连续性修复

- 问题定位：第四章与其他 RPG 场景共用的 `RpgPlayerAnimator` 原先依据 Phaser 场景的绝对运行时间选取行走帧。角色从静止开始移动、持续按键转向或完成转身时，首个可见帧会落入八相位循环中段；中性支撑相位因而被跳过，侧向移动看起来会像单腿迈步。
- 修复：在 `src/scenes/rpg/RpgPlayerTextures.ts` 中增加 `walkCycleStartedAt` 与 `getRpgPlayerWalkFrameAt()`。每一次静止后重新走动、显式设定朝向或转身完成，都会从第 `0` 帧开始连续播放 `0 → 7`；转身落定保留一帧目标朝向的中性姿势，再进入循环。共享帧尺寸、统一缩放、脚部碰撞盒、地图坐标和八张已审核素材均未改动。
- 验证：`npm run typecheck`、`npm run verify:rpg-player`、`npm run verify:rpg-character-sprites`、`npm run chapter4:validate-runtime` 均通过。开发环境的 `c4-755-bakery-1225` 检查点以网页游戏回归客户端完成 `ArrowRight` 连续 `72` 帧与松键 `12` 帧；运行态保持一个 Phaser canvas，玩家最终为 `facing=side`、`cardinalFacing=right`，截图已目视检查，新增 console/page error 为 `0`。
- 已知独立失败：`npm run chapter4:validate-topology` 仍报既有的 Task11 分钟端点外界差异（期望 `x=967,y=26`，实际 `x=966,y=25`）。本轮没有修改地图、旧钟或端点数据，该失败未由本次动画改动产生。
- 交付边界：按用户本轮要求，未生成新的单文件 `demo/index.html`。

## 2026-08-27 第四章 204 研讨教室复原状态持久展示

- 问题定位：204 研讨教室的桌椅、讲台和碰撞体原先只在 `room204_restore` 阶段挂载。安装定位片并进入维修、停电、追逐和最后一分钟等后续阶段后，`syncRoom204Runtime()` 会销毁整套动态家具，因此玩家完成复原后再次经过 A2 时会看到空教室。
- 修复：新增 `selectRoom204RuntimePresentation()`，将 204 运行时划分为 `interactive`、`restored`、`hidden`。后续八个正式阶段只有在 `room204_restored` 已持久化且十二组摆放完整时才保留复原布局；后续阶段会清除搬运选择和残影提示，保留十二张桌子、十二把椅子、讲台及其静态碰撞，临时讨论长桌保持隐藏。
- 自动验证：`npm run typecheck`、`npm run chapter4:validate-runtime`、`npm run chapter4:validate-story`、定向 `git diff --check` 均通过。运行时验证为 `1220` 个断言，新增覆盖八个后续阶段、缺少完成事实和摆放不完整三类状态。
- 浏览器验证：Blink `1280×720` 在 `c4-755-final-minute` 检查点确认 `presentation=restored`、`completePlacements=true`、`visibleDeskCount=12`、`visibleChairCount=12`、`visibleDiscussionTableCount=0`、`podiumVisible=true`。角色正对椅子向上移动 `900ms` 仅从 `y=760` 到 `y=756.125`，确认碰撞生效；中央通道向上移动 `1100ms` 从 `y=810` 到 `y=625.2`，确认通行未被家具封死。`contractFailures=[]`，console/page error 为 `0`，截图已目视检查并删除。
- 单文件验证：`npm run build:single` 与 `npm run verify:single` 通过，`demo/index.html` 为 `252359267 bytes`。本轮没有提交、推送或合并 GitHub。

## 2026-08-26 CC98 电话卡汇总与开怀一笑版面扩充

- 来源边界：浏览 `https://www.cc98.org/boardList` 确认当前公开版面列表包含“开怀一笑”（`/board/135`）及学习、信息、兴趣、交易、情感、生活等分组；进入该内容页时当前受控会话返回 `401`，因此没有读取、导出或复用任何真实主题或回复文本。
- 用户指定标题：将用户提供的“【移动/联通/电信】2026年校园电话卡信息汇总帖　详情请戳”原样作为本地 `p19` 标题，归入新增“手机服务”版面；正文与四条回复均为本地原创，并明确套餐期限、实测地点与注销条件等可比较信息。
- 内容扩充：新增 `p19` 至 `p28` 共 10 条本地帖子、31 条原创回复。新覆盖“手机服务”1 帖、“开怀一笑”3 帖、“二手市场”1 帖，以及校园生活、校园卡、自习室、失物招领、食堂各 1 帖。开怀一笑只采用轻松校园小事的讨论结构，未复写真实帖的标题、正文、用户名、时间戳或楼层。
- 版面目录：目录由 9 个扩展为 12 个，新增“手机服务”“二手市场”“开怀一笑”；“开怀一笑”加入默认关注，进入目录后可显示 `3 帖`，手机服务显示 `1 帖`，两者均支持打开、阅读和返回。
- 浏览器验证：Blink 在桌面下完成 `版面 → 开怀一笑 → 三帖列表 → 全部版面 → 手机服务 → 电话卡汇总帖详情` 的点按链路；`390×844` 下文档横纵溢出均为 `0`。详情页截图经目视检查，电话卡标题、版面名、正文、互动信息与回复均处于电话框内可读区域。网页游戏回归客户端成功输出 CC98 状态与截图；截图只作本次检查，随后移至废纸篓。
- 待完成：若已登录的 Chrome 会话后续能向受控浏览器暴露具体标签页，可按低频、少页方式补做真实“开怀一笑”讨论节奏观察；在此之前继续维持原创内容边界。

## 2026-08-26 CC98 版面导航与本地帖子扩充

- 问题定位：`P02_CC98` 底部五个入口此前使用 `cc98-bottom-static`，该层设置了 `pointer-events: none`，所有图标都只有视觉效果。
- 交互实现：底部导航已替换为真实按钮。热门显示综合帖子，新帖按发布时间排序，关注按已关注版面筛选，版面提供可点按的板块目录和关注切换，我的页面保留本次会话的实际浏览记录。版面内点击帖子仍进入原有线程页，剧情线程和既有控制器没有改动。
- 内容扩充：`cc98.posts.json` 新增 `p11` 至 `p18` 共 8 条本地虚构主题和 27 条回复，覆盖校园生活、食堂、失物招领、交通出行、学习天地、打印服务、图书馆和校园卡。文案只参考公开可证的校园论坛讨论范围与项目内既有版面结构，没有复制真实用户内容。
- 文案检查：新增主题、正文和回复的禁用表达扫描结果为 `forbiddenHits=[]`，JSON 解析通过。
- 浏览器验证：Blink 在 `430×860` 下完成版面目录、交通出行筛选、进帖、返回、我的浏览、新帖与关注页的完整点按流程，console/page error 为 `0`；Firefox 和 WebKit 均完成版面目录到交通出行筛选，console/page error 为 `0`；Blink `390×844` 粗指针下完成关注切换，横纵文档溢出为 `0`。
- 单文件验证：`demo/index.html` 直接以 `file://` 打开后完成版面目录、筛选、进帖、返回和浏览记录流程，`boardCount=9`、`historyCount=1`、横纵文档溢出为 `0`、console/page error 为 `0`。`npm run typecheck`、`npm run build:single`、`npm run verify:single` 和定向 `git diff --check` 均通过。
- 开发检查点说明：带 `devCheckpoint` 参数时开发者通道按设计会以全屏层展开并阻挡下层点按。浏览器回归在加载检查点后先用 `Ctrl+Shift+D` 关闭该层，再测试玩家界面；正式 `file://` 页面中的折叠 `DEV` 触发器不覆盖底部导航。

## 2026-08-24 Task10 质量返修：音频停机事件与 postgame seed 容错

- 范围限制：仅修 Task10 质量审查的两项问题，不扩展其他玩法。修改文件为 `src/scenes/phone/P16_BikeArcade/index.tsx`、新增 `src/scenes/phone/P16_BikeArcade/EndlessArcadeSceneEvents.ts`、`src/modules/DeveloperChannel.ts`、`scripts/verify-endless-arcade.mjs`。
- 音频生命周期：P16 将 `confirm_exit` 从 `running` 进入时显式发 `endless_arcade_runtime_paused`，原因固定为 `player`；Host `error` 进入错误态前发同一停机 cue，原因固定为 `runtime_error`；页面 cleanup 与返回手机主页统一走幂等的 `endless_arcade_closed` 发射器，重复清理不会重复发事件。
- 恢复规则：`keepPlaying()` 没有手工发 resumed，仍只依赖 Host 真正回到 `running` 后由既有 phase 迁移发 `endless_arcade_runtime_resumed`，避免 `externalPause` 下误播恢复。
- postgame seed 解析：`readEndlessArcadeDeveloperSeed()` 现在先取当前 checkpoint 的 `createPostgameDeveloperSeed()` 作为 fallback。`boot/mode/summary` 任一关键字段坏掉、缺字段、字符串冒充数字或旧 JSON 不符合合同，都会回退到当前 checkpoint 的正式 seed。`game_over.summary` 在有限数校验后再走 `normalizeEndlessRunSummary()`；`bikeStartDistance` 需要是 finite number，合法值会取整并夹到安全范围，非法值回退到 checkpoint 约定值。
- validator：`scripts/verify-endless-arcade.mjs` 新增可执行 runtime 检查，覆盖 `{}` fallback、字符串/缺字段 fallback、bike 起跑距离 fallback、合法大数 normalize、confirm-exit stop cue、runtime-error stop cue、cleanup close 幂等。验证器总检查数现为 `108`。
- 验证：`npm run typecheck` 通过；`npm run endless:validate` 通过（`108/108 PASS`）；`npm run chapter4:validate-task14` 通过（`assertions=337`）；`git diff --check` 通过。

## 2026-08-24 755 米骑车角色身份重做与物理代理复验

- 用户于 2026-08-24 回复“任务通过”，已作为三张人物视觉候选的正式外观批准记录。后续 A8、A13 和 A14 已完成；M1 生成后因完整输出的手指脱把和重复脚踏被技术拒绝，manifest 当前状态为 `m1_rejected_full_output_m2_blocked`。
- 正式锚点审计确认两个帧位差异：Start F40 还是宽镜，F41 才是握把与脚踏局部；Finish F9 还是宽镜，F10 才是刹车把与前轮局部。原生局部当前只服务物理接触审核，不作为最终人物质量证据。
- 新增并完成三张正式视觉锚点：A8 `picture_08_mount_grip_pedal_macro_1920x1080.png`（`1920×1080`）、A13 `subject_02_bicycle_canonical_2048x2048.png`（`2048×2048`）、A14 `subject_03_rider_action_canonical_2048x1024.png`（`2048×1024`）。三图均已实际检查为 8-bit sRGB、RGB 无 Alpha，且完成人工目视检查。
- A8 采用已批准的高质量视觉局部首帧，A13 和 A14 约束人物和自行车身份；原生 F41 只校验手—握把、鞋—脚踏、曲柄—链条关系。当前没有与这些高质量 PNG 对应的可编辑高精度网格工程，因此不记录成高精度三维建模已完成。
- 新增 M1 独立提示词 `docs/assets/minimax-h3-canteen-755-theater/prompts/m1-mount-grip-pedal.txt`；模型锁定 `MiniMax-Hailuo-2.3`，输入锁定 A8，帧选取合同仍为 `0–29 @ 24 FPS`。截至本记录尚未调用 `mmx video generate`，M2 继续锁定。
- 原生 F41 局部参考已实际打开并检查：`stage=start`、`segment=O3`、`camera=grip_pedal_macro`、`pose=pedal_press`；单只右手与蓝色袖口、单只右鞋、单个脚踏、曲柄、短链条与局部车架均可见，脸、躯干、其他肢体和调试方块均未出现；手和脚的对应接触误差均为 `0`。该结论的视觉验证次数为 `1`，当前等级为“可用物理参考假说”。
- 通过显式 `mmx 1.0.22` 调用 `MiniMax-Hailuo-2.3` 生成 M1 一次；任务 ID `434107226964380`，文件 ID `434080431296955`，原片位于 `docs/assets/minimax-h3-canteen-755-theater/generation/m1/raw/m1_mount_grip_pedal_raw.mp4`。额度从区间 `0/5`、每周 `0/35` 变为区间 `1/5`、每周 `1/35`；本轮没有发起第二次生成。
- `ffprobe` 实测原片为 `1364×768`、`24 FPS`、`141` 帧、`5.875s`、H.264、yuv420p、无音轨；SHA-256 为 `2b1603bacf4bee1f1b35eaa04a7f60ee2d38eaa6601f198d67d2e1dcddb25bb3`。
- 全部 `141` 帧已抽取并逐段目视检查，另完成一次独立视觉复核。`0–29` 局部审片窗在当前可见约束下通过；零基第 `39` 帧（抽帧 `frame_040.png`）首次明确出现食指和中指脱把，零基第 `120` 帧（抽帧 `frame_121.png`）首次明确出现第二脚踏，后段鞋—脚踏关系继续恶化。完整 M1 判定为 `rejected_full_output`，`integration_allowed=false`。
- 审片产物已写入 `generation/m1/review/`：`0–29` 的 `30` 帧、`1.25s` 预览 MP4，完整 `0–140` 接触表，`6` 张全帧细节表，关键失败帧表与 `m1_review.json`。这些文件只服务审片和追溯，当前禁止运行时派生。
- M2 未生成，本轮也没有裁切原片来替换完整任务判定。用户若后续要求重试，需要先修改锚点构图或将握把和脚踏拆成更小的单部件任务。
- 原生宏镜头改动后的交付验证已完成：`npm run typecheck` 通过；首次 `build:single` 遇到正在变化的无关 `P13_PhoneHome/index.tsx` 中间状态并失败，本轮未修改该文件，其内容完整写入后重跑 `typecheck` 与 `build:single` 均通过。Vite 处理 `650` 个模块，`demo/index.html` 为 `249152262 bytes`，SHA-256 `4960ce0686ba8f19a85813c5e6df0249dab6ccf0bbce853405b8026d8a2d8efe`；`npm run verify:single` 通过。`npm run verify:canteen-bike-transition` 仍为 `79 checks / 72 passed / 7 failed`，失败范围仍为过场 overlay、旧 continuation 清理和 Host 三层接线。
- 本轮临时锚点截图、浏览器宏镜头截图、M1 全帧抽取目录和 `video-frames` 临时关键帧已删除；需要交付的原片与审片证据仍保留在 `docs/assets/minimax-h3-canteen-755-theater/generation/m1/`。
- 用户已否决 2026-08-23 第三轮 v8/v9 人物观感。`hero-front-v9.png`、`hero-close-v8.png`、`start-f033-v8.png`、`finish-f082-v9.png`、`finish-f107-v8.png` 已从正式预览目录清除，旧章节中的人物外观判断随本节废止。
- 身份基准固定为 `docs/assets/minimax-h3-canteen-755-theater/anchors/subject_01_player_identity_2048x2048.png`：偏分层次短黑发、清晰眉眼、蓝色开襟外套、浅色内搭、深灰长裤、灰白运动鞋、无背包。旧 `subject_03_rider_action_2048x1024.png` 不再拥有脸、发型、服装和全身比例的覆盖权。
- 三张角色视觉候选为 `character-development/subject_01_player_3d_turnaround_v01.png`（`1681×935`）、`subject_03_rider_action_hq_v01.png`（`1672×941`）、`subject_03_rider_action_sequence_v02.png`（`1682×935`）。三图均为 8-bit sRGB、无 Alpha、低于 `5760×5760`，已于 2026-08-24 由用户批准；`formalAnchor=false`与 `hailuoUpload=false` 继续保持。
- 四动作候选锁定同一人物的低跨梁上车、稳定骑行、左脚落地和车左侧推车构图。它只承担身份、材质和静态动作方向；连续跨步轨迹、重心、手脚接触和车轮运动继续由原生 Three.js rig 与逐帧检查承担。
- 原生 rig 的定位收敛为物理与 IK 代理。当前为 `58 meshes / 58030 triangles / 44 materials`，仓库内仍没有与高质量转面图对应的可编辑网格、拓扑、骨骼权重、UV 和完整 PBR 材质工程文件，因此不能把新 PNG 记录成高精度三维模型已完成。
- 浏览器关键帧复验已实际运行：start F33 双手握把误差 `0 / 0`；start F40 双手与双脚接触均为 `0`；finish F66 左右手握把误差 `0 / 0.003742`，右脚踏板误差 `0`；finish F82 和 F107 的右手到近侧握把误差均为 `0`。选定帧目视覆盖低跨梁上车、坐稳、左脚落地、下车落地、推车和松手走向剧院。
- 物理结论的验证次数为 `1`，当前等级为“可接受假说”。这些数据未完整证明连续运动中的惯性、抓地、脚步滑移、重心转移和所有中间帧。
- 本轮已调用本地图像锚点生成流程，并完成一次 M1 MiniMax/Hailuo 生成。M1 完整输出已技术拒绝；M2 继续锁定。
- 验证：`npm run typecheck` 通过；`npm run build:single` 通过，Vite 处理 `650` 个模块并重建 `demo/index.html`；`npm run verify:canteen-bike-transition` 仍为 `79 checks / 72 passed / 7 failed`。七项缺口继续是 `CanteenBikeTransitionOverlay.tsx`、旧 continuation 符号清理，以及 `RpgGameHost` 的 start/ride/finish selector、互斥层和 controller endpoint 接线。当前不能声称过场已经正式接入。

## 2026-08-23 755 米骑车人物模板第三轮收紧与可视化演示

> 本节人物外观判断已被 2026-08-24 用户否决记录废止；保留其余历史数据用于追溯。

- 本轮继续只收 `src/scenes/rpg/canteen-chase/ChaseRiderRig.ts` 与 `CanteenBikeTransitionRenderer.ts`，目标是把用户指出的三类问题拆开处理：`1` 正脸与发型离 `subject_01_player_identity_2048x2048.png` 太远；`2` 骑乘臀座、刹车接触和推车姿态让人物显得假；`3` inspection 背景里还混着调试方块，影响人像判断。
- 已落实的人物外观修正：手臂、前臂和手掌半径再次收细；眼白恢复为窄白眼裂，保留深色瞳孔和黑眉；新增鼻线，嘴线缩短；耳朵缩小；发顶体块压扁并改成偏分碎发，刘海锥体减少为 6 束，左右侧发和顶发重新做了不对称起伏。inspection 视图只保留中性地面，不再显示宏拍调试方块。
- 已落实的接触与姿态修正：左右握把 contact 从单纯 `z=0.09` 改成带横向和纵向补偿的真实手握点，因此 `ride / brake` 双手残差从固定 `0.0278187683` 直接降到 `5e-16` 量级；骑行、踏下和刹车姿态统一加入 `SEATED_RIDER_OFFSET_Y=-0.08` 与 `SEATED_RIDER_OFFSET_Z=0.04`，让骨盆真正落到座位上；`push_bike` 根节点与右肩重新布位，推车最终帧目视已回到“人站在车左后侧单手扶把”的状态。
- 量化回测只覆盖当前真正约束的 pose。`ride` 左右手/脚都在 `1e-15` 量级；`brake` 也在 `1e-15` 量级。残余问题还在 `grip` 右手 `0.03928`，以及 `dismount_leg_over` 左手 `0.06032`、右手 `0.30354`。这些数值的验证次数仍是 `1`，当前只能算假说，不能误报成正式通过。
- 新的人像与关键帧预览已保留到正式预览目录：
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/hero-front-v9.png`
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/hero-close-v8.png`
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/start-f033-v8.png`
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/finish-f082-v9.png`
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/finish-f107-v8.png`
- 当前结论：人物观感已经明显好于上一轮，骑乘与刹车的硬伤已经去掉，推车段也能看。但“帅气模板”还没有完全收口，下车跨腿仍偏僵，`grip` 与 `dismount_leg_over` 的手把残差还没收干净，因此本轮仍不允许调用 MiniMax/Hailuo 正式生成，也不能把这批图误报成最终视频。
- 静态验证边界没有变化：`npm run typecheck` 于本轮再次通过；`npm run verify:canteen-bike-transition` 仍是 `79 checks / 72 passed / 7 failed`，失败项继续只在 `CanteenBikeTransitionOverlay.tsx` 缺失和 `RpgGameHost` 的 start/ride/finish selector、互斥 layer、controller endpoint 未接线。正式集成状态没有前进。

## 2026-08-23 755 米骑行人物模板第二轮收紧与锚点复验

- 本轮目标是把 `anchors/subject_01_player_identity_2048x2048.png` 对应的“帅气模板”重新拉回当前 Three.js 骑手，同时保留上一轮已经稳定的车架、挡泥板和骑行 IK。
- 已落实的角色修正集中在 `src/scenes/rpg/canteen-chase/ChaseRiderRig.ts`：皮肤色保持 `0xeab17d`，头颈缩短，头部整体下移，面部五官整体下移，发顶与侧发重新压缩，刘海长度上收，肩点从大圆球改为短连接管 + 小球，开襟外套门襟继续收窄，挡泥板改为真实上半弧曲线。当前自行车外观比上一轮更接近锚点图中的蓝色校园车。
- 为了补足“脸太空、太丑”的问题，新增了一个不依赖 DOM 的 `DataTexture` 面部贴图层，直接叠到头部前侧。它现在至少提供了可读的眼睛、高光、鼻影和嘴部信息，避免检查图继续退化成无五官圆头。
- 检查镜头同步收紧：`CanteenBikeTransitionRenderer.ts` 现在支持 `hero / hero_front / hero_side / hero_back / bicycle` 五类 inspection 角度，默认 hero 角度后退并抬高 look target，避免旧版那种直接裁掉头顶的误判。
- 浏览器新截图已实际生成并人工查看。保留为正式预览的三张图是：
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/hero-front-v4.png`
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/start-f033-model-v2.png`
  - `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/finish-f082-model-v2.png`
- 当前量化结果：直接构建 rig 后测得复杂度 `50 meshes / 30976 triangles / 39 materials`。`ride` 姿态下脚踏接触误差仍在 `6.59e-16` 量级，但右手到右握把残差升到 `0.01768` 世界单位，说明人物外形改动已经反推到接触链，仍需下一轮继续回收。
- 正式合同边界没有变化。`npm run verify:canteen-bike-transition` 仍是 `79 checks / 72 passed / 7 failed`，失败项仍集中在 `CanteenBikeTransitionOverlay.tsx` 缺失和 `RpgGameHost` 的 start/ride/finish selector、互斥 layer、controller endpoint 未接线。当前仍不能声称已经正式集成。
- 本轮 `npm run typecheck` 没有通过，但失败点出在电话端既有文件 `src/scenes/phone/P15_Zjuding/index.tsx`、`ZjudingAppRegistry.ts`、`ZjudingUtilityPanel.tsx` 的 `badge` 类型问题，不在本轮骑行建模改动路径里。这个结论的验证次数是 `1`，当前只能算假说。

## 2026-08-23 755 米骑行 IK 物理修复与关键帧复验

- 物理边界：本批只处理 `src/scenes/rpg/canteen-chase/ChaseRiderRig.ts` 的双骨 IK、肩点和接触启用规则；未进入外观身份建模，也未接 `RpgGameHost` 的 start/ride/finish 过场层。
- 数学修复：删除旧 `setEndEffectorToTarget()` 与 `alignContactPoint()` 末端平移吸附。`solveTwoBoneIK()` 现改为固定骨长解析式求解：目标向量统一放在 `rootPivot.parent` 局部坐标系求解，上骨长度取 `midPivot.position.length()`，下段接触长度取 `midPivot.worldToLocal(endContact.world)`，肘膝弯折平面由 world-space bend hint 投影得到。`endEffector.position` 不再被改写，手掌和鞋底局部端点保持常量。
- 肩点重配：修公式后量得旧肩点到左握把的世界距离约 `1.3677`，超出旧手臂可达长度，主因是肩点过后过高，不是公式本身。现为所有握把姿态增加前移下沉肩点；典型骑行姿态改为 `x=±0.44, y=1.78, z=-0.26`，`grip / leg_over / dismount_leg_over / push_bike` 再按进度单独调整 `riderRoot.position.x` 与右肩。
- 定量验证：用 `npx tsx` 直接导入 rig 后复算接触误差。`ride / pedal_press / brake` 的手握把与脚踏板误差已降到 `1e-15` 量级；`left_foot_down` 保留右脚接触为 `5.24e-16`，左脚故意离踏板，属于设计动作。`leg_over` 右手误差降到 `6.20e-4`。残余弱点仍在 `grip` 右手 `4.69e-2`、`dismount_leg_over` 双手 `1.03e-1 ~ 1.70e-1`、`push_bike` 右手 `2.02e-1`，这些还没有达到正式成片标准。
- 浏览器复验：`npm run typecheck` 通过；`npm run verify:canteen-bike-transition` 仍为既有 `79 checks / 72 passed / 7 failed`，失败项全部集中在 `CanteenBikeTransitionOverlay.tsx` 缺失和 `RpgGameHost` 的 start/ride/finish selector、互斥 layer、controller endpoint 未接线，没有新增合同回退。
- 出图证据：新图已写到 `docs/assets/minimax-h3-canteen-755-theater/previews/option-a-hd-model-preview/start-f033-ik-pass/shot-0.png`、`finish-f082-ik-pass/shot-0.png`，并抓取了 `start-f055-ik-pass`、`finish-f025-ik-pass` 近景对照。目视确认起步跨车和终点下车不再出现上一轮那种明显的手臂断开。另有 `option-a-native-preview/chase-377m-ik-pass.png` 作为实时路线状态参考。
- 当前结论：主骑行物理链已从“错误机制”提升到“可接受假说”，验证次数 `1`。用户后续要求的身份外观对齐 `anchors/subject_01_player_identity_2048x2048.png`、去背包/圆顶发片、提升光影和材质精细度，仍未完成，不能把这批 IK 修复误报成最终可交付视频。

## 2026-08-23 第四章统一扩展与修复收束

- 已按用户确认的组合执行第四章本轮统一扩展与修复：`A1 + A2 + A3 + B1 + B3 + C2`。本批收口覆盖 3.5 未同步记录、3.5→4 H3 入口、第四章 `7:55` 阶段提示/差分/三提示、Task 9 detailCode 反馈、Task 10 字幕归属、Task 11 DEV 节点、Task 13 场景细节和 B3 细节音效。
- 3.5 记录恢复：`P20_TimelineRecovery` 维持“待恢复时间窗 → 四证据 → 三旧时间排除 → 自动时间线 → 四地点判断 → 回放入口”的正式链；目的地不会在未满足条件时提前泄露；录音试听草稿、事件型预览和回放准备态已纳入控制器与存档清理。
- 第四章任务表达：`ChapterFourStagePresentation` 和 `chapter4-755.content.json` 已固化 `13` 个阶段、`6` 个时间态、`28` 个活动任务和 `84` 条三段式提示；共享任务栏读取阶段名、时间状态、楼层、局部进度、当前差分、时间来源、手机可信度和已确认事实。章节完成态保留空 hints。
- 第四章反馈契约：`ChapterFourTemporalMazeController` 的锁定态细分为 `33` 个 detailCode；`RpgGameHost` 只从 `chapter4-755.content.json.intentFeedback.details` 取原因与下一步，不再让粗粒度 `locked` 淹没具体纠错。
- 第四章字幕归属：Host 不再把所有 7:55 交互结果自动转成玩家字幕；剧情对白、关键结果和失败仍由场景/覆盖层独占。阶段副作用签名已收敛到 `phase + timeState`，楼层切换与签到局部进度不会重复播报。
- DEV 与恢复入口：`c4-prologue-task-card` 保持“未确认时刷新仍回任务卡，确认后进入 A1 开场同步”；`c4-755-return-clock` 与 `c4-755-closure` 作为稳定正式节点保留；旧 `c4-755-light-grid` 与 `c4-755-complete` 继续只做别名，不再提供旧错误结果节点。
- 场景细节：面包坊三名学生加入端点看手机/调包小动作；保洁阿姨在修前做短推车失败尝试、修后改为短程推车并落到静置车状态；维修保安按巡逻/清单/看表/确认/追逐的不同动作切换；签到阶段新增三名不带碰撞的早八学生。Chapter 4 细节音效新增 `clock_stutter_started / clock_stable_started / maintenance_cart_wheel_stuck / maintenance_cart_wheel_repaired`，并通过 ambient owner 生命周期控制。
- 新一轮静态验证已实际执行并通过：`npm run typecheck`、`npm run chapter4:validate-assets`、`npm run chapter4:validate-story`、`npm run chapter4:validate-topology`、`npm run chapter4:validate-runtime`、`npm run chapter4:validate-task14`、`npm run verify:rpg-facing-agnostic`、`npm run verify:rpg-character-sprites`、`npm run audio:chapter3-interlude-voice-memos:verify`。
- 正式单文件已重建并验证：`npm run build:single`、`npm run verify:single` 通过；当前 `demo/index.html` 大小 `248256518 bytes`，修改时间 `2026-08-23 19:39:31 CST`，SHA-256 `b00c9d4454e6c20c5793e70099a1e2a7b1f96f9df5c9caebe0c455c6084c28b6`。
- 浏览器验证边界：Chromium 成功通过本地 HTTP 打开 `c4-755-opening` 与 `c4-prologue-task-card`，确认第四章打开态已进入 `duan_yongping_temporal_maze / c4_a1_lobby`，开发者任务卡确认后 `seven-fifty-five.developer-chapter4-task-card-confirmed.v1=1`，刷新后仍恢复到已确认入口链。Firefox 在放宽到 `90s` 超时后也成功打开同一第四章检查点，标题为 `7:55` 且无 pageerror。Firefox/WebKit 在 `15s` 快速超时下均无法完成这个超大单文件首开，因此当前跨内核结论仅能证明“可打开”，不能把首开性能判为合格。
- 保留边界：第四章正式收束 consumer 仍缺用户已确认的“灿若星辰”唯一正式素材路径或等价 proof，因此 `c4-755-closure` 继续维持 `completed=false` 的外景等待态；本轮没有伪造 `c4-755-result` 或最终收束消费者。

## 2026-08-23 食堂上车与剧院下车衔接 A 方案首批实现检查点

- 本批完成 Task 1–3：新增 `npm run verify:canteen-bike-transition` 合同验证器；`ChapterThreeCanteenController` 将付款与真正开骑拆分为两个门；`ChaseThreeRenderer` 已切换到共享 `ChaseRiderRig`，保留原 chase 的 root 名、`1.28` 缩放、`frontAssembly` 位置与现有逐帧更新顺序。
- `payForBike()` 现在只在 `chase_ready` 阶段扣除 `cafeteriaWages` 与现金，并写入 `bikePaid=true`，发出 `canteen_bike_paid`；新增 `startChase()` 只在 `chase_ready + bikePaid + !chaseCompleted` 时把 phase 推进到 `chasing`，重复调用在未完成 chase 期间保持幂等。
- 新共享 rig 位于 `src/scenes/rpg/canteen-chase/ChaseRiderRig.ts`，由现有 `ThreePrimitiveCache` 注入 geometry/material cache，没有创建第二套 primitive cache。骑手与蓝色自行车拆出 `bicycleRoot`、`riderRoot`、`frontAssembly`、`rightBrakeLever`、`crank`、`left/rightPedal`、`chain`、`basket`、`left/rightHand`、`left/rightFoot`，并提供 `applyChaseRiderPose()` 供后续过场渲染与锚点导出复用。审查发现 A8 所需的右手—握把、右鞋—踏板原先只有独立节点，未形成接触约束；现已增加四个不可见表面端点与 `enforce / measure / assert` 接触 API，数学断言覆盖 `6` 种双接触姿态、每种 `5` 个进度采样，共 `30` 个样本，最大误差分别为 `2.00e-15` 与 `1.09e-15` 世界单位，低于 `1e-5` 阈值。
- 验证已立即执行：`npm run typecheck` 通过。`npm run verify:canteen-bike-transition` 从首轮 `failed=14` 降到当前 `failed=9`；当前剩余失败全部集中在后续 Task 4–7：缺少 `CanteenBikeTransitionTimeline.ts`、`CanteenBikeTransitionRenderer.ts`、`CanteenBikeTransitionOverlay.tsx`，以及 `RpgGameHost` 仍保留旧 `755m` continuation 链路、未声明 start/ride/finish 三层 selector、未做互斥 handoff layer 和 controller endpoint 接线。
- 本批验证次数：控制器行为验证 `1` 次，共享 rig 静态变换与更新顺序验证 `1` 次，接触数学约束执行 `1` 次，当前结论仍属于假说；TypeScript 在 Task 3 完成后与最终并发状态下共通过 `2` 次。共享 rig 已在真实 Vite + Blink 会话中检查 `0m / 377m / 755m` 三个状态，人物中心、比例、相机范围稳定，控制台 `0 error / 0 warning`；本次 `web_game_playwright_client` 的 canvas 抓图返回黑帧，Playwright 整页截图画面正常，因此暂将差异判断为抓图链路问题，该判断仍属于一次验证的假说。临时 QA 截图均已移入系统废纸篓。完整 A 方案浏览器链仍为 `0` 次；手掌—袖口、鞋—裤腿的视觉连续性和 A7–A14 正式锚点仍需在 Task 4 与 Task 8 检查。

## 2026-08-23 食堂上车与剧院下车衔接 A 方案设计确认

- 用户选择 A：完整展示上车、起步、755 米胜利后的刹停、下车和移车。正式链路保留完整 0–755 米真实玩法。
- 新设计把 Hailuo 2.3 限制为两个固定 1.25 秒近景插镜：右手握把加右脚踏，以及右手刹车把加前轮减速。玩家全身、蓝色自行车、纸条、NPC、道路和剧院继续由原生运行时渲染。
- 权威状态复用现有事实组合：chase_ready+bikePaid 为上车门，chasing+!chaseCompleted 为真实骑行，chasing+chaseCompleted+bestDistance>=755 为下车门，theater_reached 为剧院外检查点。设计不新增剧情 phase 或存档版本。
- 已明确废止 700 米正式交接、picture_05 的错误 755 米生成首帧、旧跨投影中间分镜和两条已拒绝视频。旧视频继续保持 rejected_by_user 与 integration_allowed=false。
- 正式分镜为 Start gate 91 帧、3.792 秒；Finish gate 133 帧、5.542 秒。新锚点 A7–A14 全部由共享 Three.js 骑手模型截图或直接渲染，场景图 1920×1080，主体图最大 2048×2048，均低于 5760×5760。
- 完整设计、两个可直接粘贴的英文提示词、资产清单和逐文件实施计划已写入 docs/plans/2026-08-23-canteen-bike-transition-option-a-design.md、docs/assets/minimax-h3-canteen-755-theater/ 与 project-development-report.md。
- 当前验证边界：设计与代码路径审阅 1 次，仍属于假说；新骑手模型、A7–A14、Hailuo M1/M2 和浏览器链均为 0 次。未调用 MiniMax、未生成新视频、未修改运行时代码、未执行 Git 写操作。

## 2026-08-22 第四章学生、主人公、保安与保洁阿姨多姿势透明角色更新

- 问题修复：面包坊三名学生由四帧同相动作升级为八帧步行，并分别从第 `0 / 3 / 6` 帧开始播放；现场不再出现三人同一时刻使用同一姿势的情况。
- 后续裁切修正：用户实机发现角色帧间忽大忽小且部分头脚缺失。根因是四张生成源图只在视觉上接近网格，人物轮廓实际跨越等分线；旧构建器先按等分格截断人物，再把每个残缺帧分别放大到目标高度。主人公源图还实际包含 `8` 个朝下、`7` 个朝上和 `9` 个侧向轮廓，旧方向映射把第一个侧向姿势当成第八个朝上姿势。
- 生成路径：调用 `mmx 1.0.15` 的 `image-01`。`2048×2048` 请求发生服务端 `rpc timeout`；`1024×1024` 候选虽然成功返回，但没有遵守 `4×4` 网格、透明背景和像素风约束，已拒绝接入。按用户允许的备用路径生成四张原生 RGBA 源图，并以 `_v2` 文件名保留旧素材。
- 角色动作：学生包含八帧步行、看手机、调背包、推门和站立；主人公包含朝下、朝上和侧向三组八帧步行，朝左由水平镜像；保安包含八帧巡逻、清单、手表、手电和对讲机；保洁阿姨包含推车、拖地、警示牌、照明开关、休息和站立。
- 图集处理：两个构建器改为从整张源图提取完整 Alpha 轮廓，再按行列中心排序；每个方向组或角色只使用一个固定统一缩放比例，并保留至少 `2px` 的头顶和脚底安全留白。朝上第八帧由第五个朝上源姿势水平镜像补齐，侧向组选用九个候选中的前八个。运行帧的透明掩膜直接取自原图 Alpha，避免二次连通区域标签排序产生黑色背景。
- 回归门禁：新增 `npm run verify:rpg-character-sprites`，验证四类角色的源图轮廓数量、头脚留白、源图/运行帧轮廓重合度、宽高比、同动画缩放稳定性和主人公补帧映射；当前四类角色全部通过，同一动画测得的最大/最小缩放比低于 `1.03`。
- 运行时接入：Phaser 主角循环更新为单帧 `110ms` 的八帧动画；第四章 Three.js 错位楼梯同步消费同一组 `24` 帧。学生与保安为 `8 FPS`；保洁推车为 `8 FPS`、拖地为 `6 FPS`。角色碰撞脚框和存档逻辑未改变。
- 浏览器验证：Chromium `1280×720` 在重建单文件的 `c4-755-bakery-1225` 连续检查两帧，三名学生头脚完整、透明背景正确且帧间人物比例稳定；`c4-755-maintenance-2245` 检查了完整显示的主人公、保安、保洁阿姨和清洁车。经过前景墙或前台时保留基于脚点深度的遮挡；离开遮挡区后完整轮廓恢复。两处控制台均为 `0 error / 0 warning`。
- 单文件交付：`npm run build:single` 与 `npm run verify:single` 通过，生成 `demo/index.html`，大小 `247123278 bytes`，SHA-256 `b93366659343e7df98b842397075db587b5aaf84d43215976051c583b1622409`。Playwright CLI 阻止 `file:` 协议自动化，因此直接文件打开保留为人工刷新确认边界。
- 复用文档：`docs/plans/2026-08-22-diverse-transparent-rpg-character-sprites.md` 记录 MiniMax 失败样本判定、四角色最终提示词、整图轮廓提取、固定缩放、透明背景要求和运行时帧率。
- Git 边界：本轮没有执行暂存、提交、合并或上传。

## 2026-08-22 全章节无朝向互动与第四章边界单文件打包

- 正式构建：按用户最新要求运行 `npm run build:single`。该命令先执行 `tsc --noEmit`，随后用 Vite Demo 模式内联资源；共转换 `606` 个模块并成功重建 `demo/index.html`。
- 单文件产物：`246582539 bytes`，修改时间 `2026-08-22 16:28:03 CST`，SHA-256 `259583dcb1d4142d590426c12b0667d8ce313e6389b5d54bbda5cae079d27f9f`。
- 结构验证：`npm run verify:single` 通过，产物包含 `2` 个内联脚本与 `1` 个内联样式，并验证 `campus-map-demo.html`、`chapter4-monument-stair-demo.html` 和 `index.html` 三个入口。
- 合同回归：全章节无朝向互动检查通过 `256` 个活动文件且 `forbiddenMatches=0`；第四章拓扑、运行时与 Task 14 分别通过 `2495 / 1125 / 220` 项断言。
- 浏览器验证：Chromium 通过本地 HTTP 打开新单文件的 `c4-755-room204-1850` 检查点，页面标题为 `7:55`，React 根节点数为 `1`，Phaser canvas 数为 `1`，场景为 `duan_yongping_temporal_maze`，A3 活动物理边界为 `{x:3728,y:0,width:1672,height:941}`，`contractFailures=[]`。控制台为 `0 error / 0 warning`，网络记录只有 `index.html` 一个 `200 OK` 请求。
- 直接文件验证边界：Playwright CLI 明确阻止 `file:` 协议，因此没有取得新的自动化 `file://` 运行证据；单文件结构验证和 HTTP 零外部资源运行均已通过。用户可直接打开新产物进行人工核对。
- 交付边界：本轮只重建正式 Demo 和普通构建目录，没有创建 ZIP，也没有执行 Git 暂存、提交、合并或上传。

## 2026-08-22 全章节互动取消朝向门槛与第四章逐层地图硬边界

- 全局规则：人物朝向只服务移动输入、步行动画、角色绘制以及皮划艇运动、追逐和尾流表现。观察、拾取、对话、门与设备使用、物品拖放、楼梯和电梯等所有剧情互动不读取人物朝向。
- 共享契约：`RpgInteractionContract.ts` 删除 `requiredFacing`、`facingToleranceDegrees`、`wrong_facing` 和面向目标辅助函数；空间核验只保留目标、模式、道具、真实可见边缘距离与拖放命中区域。`RpgGameHost` 的第四章空间证明同步删除 `cardinalFacing`。
- 场景覆盖：第二章图书馆、第三章食堂、剧院和启真湖、第四章教学楼的互动目标与提示全部移除朝向门槛。启真湖的连续船头角仍用于划桨运动和追逐计算，不进入抛竿、拾取、开柜、喂天鹅或其他剧情互动判定。
- 第四章边界：Phaser 物理世界与摄像机在每次楼层切换、恢复输入前同时锁定到当前楼层的 `1672×941` 源像素范围。世界坐标分别为 A1 `x=0..1672`、A2 `x=1864..3536`、A3 `x=3728..5400`、三层均为 `y=0..941`；两段 `192px` 楼层间隙不可进入。
- 回归机制：新增 `scripts/verify-rpg-facing-agnostic.mjs`，扫描活动 `src` 中的旧朝向字段、拒绝结果、辅助函数和面向提示；接入 `package.json` 与 `.github/workflows/web-ci.yml`。该机制创建后已立即执行，扫描 `256` 个活动文件，`forbiddenMatches=0`。
- 静态验证：`npm run chapter4:validate-topology` 通过 `2495` 项断言，`npm run chapter4:validate-runtime` 通过 `1125` 项断言，`npm run chapter4:validate-task14` 通过 `220` 项断言；`npm run verify:rpg-facing-agnostic`、`npm run typecheck` 与普通生产构建 `npm run build` 全部通过。Vite 仅保留仓库既有的大 chunk 提示。
- 边界实机验证：Chromium `1280×720` 对 A1、A2、A3 分别执行左、右、上、下四次持续向外移动，共 `12/12` 次都精确停在当前楼层物理边界；没有进入层间空白，也没有出现 console/page error。
- 无朝向实机验证：图书馆入口记录在人物朝下时可打开；剧院售票机在人物朝左且目标位于右侧时可触发；A3 教室参照目标在人物背向目标时可写入 `a3_reference_observed`。三次互动后人物视觉朝向均保持原值，console/page error 为 `0`。
- 交付边界：按用户当前要求，本轮没有运行单文件打包，没有改写 `demo/index.html`，也没有执行 Git 暂存、提交、合并或上传。

## 2026-08-22 启真湖可抛竿水纹、船位容错与固定判定线

- 问题定位：旧视觉把多枚收缩水纹环叠在同一浮标上，玩家缺少固定的时机参照，连续音符和长按音符的读取负担较高。
- 水纹根因：场景创建了目标 `pulse`，但初始设为不可见后没有在活动目标更新中重新显示；浅色操作下的钥匙、网框、鱼群和纸条抛竿点因此缺少可读轮廓。
- 水纹重构：四个可抛竿目标改为金色主轮廓、白色内环、金色外环和白色中心点，深色观察水纹保持青色区分。最近或当前手持道具可接受的水纹显示一个准确目标名称，其余不显示常驻文字。
- 船位容错：可抛竿水纹的真实可见边界固定为 `180×84`，皮划艇到最近边缘的允许距离放宽到 `220px`，对应目标中心水平约 `310px`、垂直约 `262px`；道具拖放框为 `360×240`。深色观察水纹为 `156×72 + 190px` 距离容错。船头朝向继续不参与钓鱼抛竿判定。
- 视觉重构：`QizhenFishingRhythmVisual` 新增画面中下部的固定节奏轨道、白色高对比「判定线」、右向左移动的 `A / S / D` 彩色音符、节拍刻度和方向箭头。音符进入可命中窗口时判定线变为金色，命中后按结果颜色闪示，反馈文案改为「精准 / 良好·稍早或稍晚 / 命中·稍早或稍晚 / 错过」。
- 长按与降动效：长按音符命中后锁在判定线，右侧水平进度条显示剩余持续时间。`prefers-reduced-motion` 使用离散音符位置和整数拍倒计时。浮标水纹保留为低透明度场景反馈。
- 规则边界：谱面、`96 BPM`、`70 / 130 / 190 ms` 判定窗口、辅助模式 `230 ms`、张力模型、道具结算和存档均未改动；固定轨道与原判定引擎读取同一个单调时钟。权威契约已同步到 `docs/chapter-3-qizhen-fishing-rhythm.md` §7。
- 浏览器验证：Blink `1280×720` 实景中检查了音符接近、精准命中和长按进度三种画面；精确同时钟输入得到 `perfect / tension=50`，长按进度画面为 `judged=8 / tension=50`。Blink `390×844` 粗指针视口中三枚触控键与节奏轨道无重叠，通过共享 `rpg_qizhen_fishing_input` 通道点按「S 提竿」得到 `perfect / judged=1 / tension=50`。Blink、Firefox、WebKit 均复验最终金色三层可抛竿水纹；手机视口中水纹与底部控制区无重叠。真实物品栏拖放在船与目标中心相距 `280px` 时成功启动 `locker_key`，相距 `340px` 时仍被距离门禁拒绝。最终 Blink、WebKit 和手机会话为 `0 error / 0 warning`；Firefox 为 `0 error / 3 warning`，分别来自兼容性探针主动释放 WebGL context 与无用户手势时 Web Audio 自动启动受限，不影响本轮交互。
- 静态与交付边界：`npm run typecheck` 与普通生产构建 `npm run build` 通过，Vite 仅报告仓库既有的大 chunk 提示。按用户要求，本轮没有运行单文件打包，没有改写 `demo/index.html`，也没有执行 Git 提交或上传。

## 2026-08-22 第三、四章字幕与任务提示单一归属

- 归属规则：共享任务栏只显示当前目标与按需展开的提示；RPG 字幕只保留剧情对白、旁白、线索结果、失败、操作纠错和关键阶段结果；道具拖放的接受或拒绝只由物品栏反馈呈现。场景不再为同一次状态变化重复播报任务更新。
- 第四章：`RpgGameHost` 停止把每次 7:55 intent 的接受结果和协议错误自动转成玩家字幕，技术拒绝写入调试输出；保留场景/覆盖层独占展示清单作为运行时契约元数据。教学楼场景删除楼层到达、重复拾取、重复放置和重复成功字幕，并消除道具栏与场景同时报错；任务动作改写进当前任务标题，仍只保留三条既定按需提示。错位楼梯首次进入只播报空间异常，不再附带操作步骤。
- 第三章：食堂新增按餐盘、队伍、调饮、点餐、取餐和出口防守事实切换的细粒度任务；校园、食堂、剧院和启真湖删除地点标题、模式切换、阶段更新、逐步划桨、拾取确认、前往下一目标和抵达确认等任务型字幕。启真湖道具链完成文案只陈述本次结果，下一步继续由任务栏负责；锁定航道只在玩家实际撞到未开放入口时给出一次纠错。
- 配音保护：剧情对白队列未删除，第三章语音合同仍登记 `37` 条台词，`unrecorded=0 / stale=0 / errors=0`。完整音频门禁保持既有 `76/77` 状态，唯一缺项仍为 `music_qizhen_fishing.mp3`；运行时继续复用现有 `96 BPM` 音乐和程序节拍降级，本次未伪造专用音乐产物。
- 静态与契约验证：第三章五个活动场景的主动 `task` 字幕发射扫描为 `0`；JSON 解析、目标文件空白检查和 `npm run typecheck` 通过。`npm run chapter4:validate-story`、`npm run chapter4:validate-runtime`（`1171` assertions）与 `npm run chapter4:validate-task14`（`215` assertions）通过。
- 浏览器抽查：重建后的单文件分别从 `c3-canteen-entry`、`c3-theater-program`、`c3-qizhen-open-water` 和 `c4-755-bakery-1225` 进入。四处均由共享任务栏显示唯一当前目标，关闭 DEV 后没有并行任务字幕；食堂提示按需从 `0/1` 展开到 `1/1`，面包坊为既定 `0/0`。抽查还修正了剧院任务无障碍名称的双句号，启真湖与第四章页面 console error/warning 均为 `0`。
- Demo：`npm run build:single` 与 `npm run verify:single` 通过；`demo/index.html` 为 `246584150 bytes`，SHA-256 为 `20f6da4c881620188afe444894907010306d5be9ab43eea391d15e11b6e8d719`。按用户要求，本轮没有执行三层浏览器碰撞与遮挡校验。

## 2026-08-22 MiniMax H3 食堂上车、755 米骑行与剧院抵达衔接

- 范围纠偏：按当前控制器和运行时规格，链路固定为“东区大食堂外支付并上车 → 真实 0–755 米 Three.js 骑行 → 求是大讲堂外 `campus_theater_junction`”。剧院大厅仍需入口交互后由 `ChapterThreeTheaterController.enterTheater()` 开启。
- 实机母帧：从 `c3-canteen-bike`、`c3-canteen-theater` 和追逐调试页 `0m / 377m / 700m / 755m` 截取 6 张无 HUD 母帧；生成 6 张 `1920×1080` 场景锚点，覆盖上车起点、骑行首帧、沿途核对、755 米终点和剧院外部回接。
- 主体锚点：从仓库当前精灵生成玩家、蓝色自行车、骑行动作、纸条飞行动作、白衣 NPC、绿衣 NPC 共 6 张独立主体图；全部为 8-bit sRGB、无 Alpha，最大画布 `2048×2048`，低于用户确认的 `5760×5760` 上限。多帧图仅代表同一主体的连续动作。
- 分镜：新增两张缺失的中间关键帧和两张三联分镜。Clip 01 为 6 秒“俯视食堂上车 → 后视骑行 0m”；Clip 02 为 7 秒“755m 终点 → 刹停下车 → 北向剧院入口”。两段分别使用蓝色外套和白色弧顶的全画面遮挡完成一次隐藏硬切，禁止交叉溶解。
- 提示词：`docs/plans/2026-08-22-minimax-h3-canteen-755-theater-cutscene.md` 提供两段可直接粘贴的 H3 全参考六段式英文提示词、逐秒镜头、上传标签映射、返工顺序、模型验收和未来媒体 `ended` 握手边界；资产目录包含 README 和机器可读 manifest。
- 交付边界：755 米距离、三车道、障碍、碰撞、三次机会、完成判定和存档继续由 TypeScript 控制器负责。当前 `900ms` 终点等待尚未修改，正式接入 7 秒视频时需要改为媒体结束握手。本轮没有修改运行时代码，没有重建单文件。H3 实际生成与播放验证次数为 `0`。

## 2026-08-21 MiniMax H3 第三章半至第四章锚点与衔接设计（历史生成基线）

> 本节记录视频生成前的 `32.40s` 方案。`2026-08-22` 已按三份实际成片改为 `43.833333s` 六阶段运行时；当前事实见后文“第三章半至第四章 H3 衔接视频拼接与接入”。

- 正式与扩展双轨：按当前 Task 7 记录，正式回放保持 `snap / lake_exit / arcade / entrance`，总长 `32.40s`，使用成片 01–03；保洁员门厅和保安清楼保留为可选扩展成片 04–05，只有显式恢复 `lobby / closing`、资源加载、音频字幕节点和 `51600ms` 任务卡后才可接入。旧 DEV 偏移仍显示后两段，不作为活动时间轴证据。
- 上传锚点：新增 `docs/assets/minimax-h3-chapter3-4/anchors/transition/`，包含 10 张成片首尾锚点与 1 张 A1 回接锚点。全部为 `1672×941`、8-bit sRGB、无 Alpha，低于 H3 `5760×5760` 上限；四张关键首尾图固定了钓线/纸条或 NPC 收束构图，其余七张保持源环境 RGB 像素不变。
- 主体锚点：继续使用 3 张 `1024×1024` 纸条锚点和 7 张 NPC 身份/动作锚点；NPC 最大画布为 `3584×1024`。多帧动作图仍明确表示同一角色的连续动作，禁止生成多名人物或多套道具。
- 提示词：完整五段提示词保留 H3 全参考六段结构。正式版先生成 01–03；扩展版只在重新启用时间轴后生成 04–05。上传表已改用统一的高分辨率衔接锚点，A1 回接图不占用 H3 图片槽。
- 接缝：定义游戏到成片 01 的像素块接入、01→02 与 02→03 的出右入左动作匹配、正式版 03→任务卡→A1 的 ready 握手回接；扩展版另有 03→04、04→05、05→任务卡→A1。主体跨镜接缝禁止交叉溶解，避免纸条或 NPC 双影。
- 真实流程检查：本地 Vite 中从 `c4-prologue` 播放到当前 `32.4s` 任务卡，点击“收下任务，进入第四章”后序幕层解除并进入 A1；浏览器 console error 为 `0`。现有 Host 仍在 `a1_2245_opening + contractReady` 后延迟 `80ms` 释放，计划中的 `240ms` 六步像素揭幕尚未实现。
- 验证：11 张衔接锚点的数量、尺寸、8-bit sRGB、无 Alpha、文档路径全部通过；五段提示词的六段结构计数为 `5×6`，静默字段为 `10` 个 `N/A`；七张未合成环境锚点与源图逐像素 `AE=0`。本轮只修改文档和外部生成锚点，没有修改运行时代码，因此未运行 typecheck 或单文件构建。H3 实际视频尚未生成，模型输出一致性验证次数为 `0`。

## 2026-08-20 第四章教学楼地图提示词与首轮素材候选

- 生成范围：基于第四章剧情和三层时间迷宫玩法规格，完成 A1/A2/A3 母图、22:45/12:25/18:50/07:54/07:55 时间态、202 最后一分钟状态，以及旧钟、配电箱、204 家具与残影、剧情道具、移动隔断/203 门/导视碎片等透明精灵候选。
- 来源边界：本轮没有把当前运行时地图、截图或精灵作为图像输入；A1 从空白提示生成，部分 A2/A3 候选只使用本轮新生成 A1 维持新素材集内部结构。
- 交付位置：`artifacts/chapter4-map-assets-20260820/` 保存 20 张 PNG、资产清单和规则精灵表元数据；完整提示词保存在 `docs/plans/2026-08-20-chapter4-topdown-pixel-map-generation-prompts.md`。
- 验证：逐文件检查像素尺寸和 Alpha；6 张精灵表均具有真实 Alpha，清单记录了 1671px 宽度偏差、时间态仍为无 Alpha 完整场景、楼层结构漂移、精灵锚点未校准等限制。当前素材只作为候选视觉稿，未接入运行时，也未修改碰撞和存档逻辑。
- 范围纠偏：项目已有正式“灿若星辰”素材。本轮生成的星灯状态表和室外收束候选已从交付目录移至 macOS 废纸篓，可恢复；提示词文档已标记该部分不进入生成队列。
- 碰撞与遮挡提示词：逐张识别现有 20 张候选图，新增一个统一入口和三个分册，共提供 20 段可直接复制的识图提示词。母图分册记录固定空气墙、真实门洞、走廊、物品名称、交互锚点与前景基线；时间态分册区分动态实体与纯光照；精灵分册记录 cell、Alpha 边界、pivot、脚部碰撞盒和深度规则。
- 坐标验证：母图目测坐标保留 `approximate=true`；规则精灵表 cell 与 5% Alpha 边界单独标为实测。检查确认 5 张母图、9 张时间态和 6 张精灵表均有独立提示词，20 个文件名全部覆盖。当前只形成标注规格，没有写入运行时碰撞数据。

## 2026-08-18 设置桌面、CC98 学习天地与第四章自习群

- 桌面编辑：手机首页应用顺序进入 `UiState` 与存档版本 24；桌面端长按约 `460ms` 进入编辑，支持拖动、键盘方向键换位、完成退出与默认排布恢复。剧情应用只允许移动；当前存档中仅可选应用“浙大体艺”显示移除按钮，`微信 / 照片 / CC98 / 浙大钉 / 设置` 等入口没有删除语义。
- 设置应用：新增原生像素风设置首页、搜索与 8 个子项，接入网络、声音、显示、桌面、应用恢复、隐私、电池后台记录与系统诊断。第四章“电池与后台活动”要求从 07:55 记录中选出照片、时钟、浙大钉三条异常；控制器校验通过后写入共享证据。
- CC98 内容：保留旧本地编辑数据并按帖子 ID 合并新默认帖；新增打印、自习、食堂、雨具与课程资料等校园帖子，时间筛选栏改为可读的“发现 / 本周 / 本月 / 往年今日 / 活动”。全部新增论坛文案按 `human-writing` 规则检查，避免说明书式旁白。原有“资料索引机 / 期末资料按课程和年份整理好了”在第四章会显示可导入状态，点击后进入同一资料核对线程，完成后原位显示“已导入自习群”。
- 第四章联动：新增“学习天地资料索引帖”及六条回复。玩家从帖子中选取“课程与年份入口 / 旧自习讨论 / 今晚仍要现场核验”后，资料会进入微信“麦斯威夜间自习群”的群文件；保存路线讨论后，任务推进到“根据夜间人员动线重建纸条路线”。CC98 只提供资料入口，现场学生消息继续提供夜间路线证据。
- 浏览器链路：Blink 中完成 `设置后台记录 → CC98 三项导入 → 微信群文件 → 保存路线` 的真实点击流程；任务依次从 CC98 导入切到微信保存，再推进至夜间人员动线重建。另从旧“资料索引机”列表项进入专帖，选择三项有效信息后成功导入，验证旧入口与新增专帖共用同一控制器事实。桌面长按进入编辑，Delete 无法移除设置，ArrowRight 可移动设置，退出设置再回首页后新顺序仍保留。
- 多端验证：`390×844` 检查设置首页、手机桌面和扩充后的 CC98 列表，document 横向溢出均为 `0`，浏览器 console error 为 `0`。旧“资料索引机”入口另在 Blink、Firefox 与 WebKit 中完成跳转核对；三个内核均打开同一学习天地导入面板，`390×844` 下 document 横纵溢出为 `0`、console error 为 `0`。浏览器内构造缺少两个桌面字段的版本 23 存档，`SaveStore` 成功补出默认顺序与空隐藏列表。静态验证通过 `npm run typecheck`、`npm run chapter4:validate-topology` 与定向 `git diff --check`。
- 交付边界：按用户要求，本轮开发阶段没有运行 `build:single`，也没有改写 `demo/index.html`。

## 2026-08-15 校时关卡 2 换装 3D 机芯爆炸图

- 改动：第 2 关「锁定双机芯」的 2D 数字滚轮替换为纯 CSS 3D + SVG 齿轮爆炸图组件 `src/scenes/phone/P19_Clock/ClockMovement3D.tsx`（受控组件，读数与锁定全部由 `ClockCalibrationController` 持有，组件只上报 `onAdjust(unit, ±1)` / `onLock(unit)`）；样式落在 `src/styles/scenes/p19-clock-movement-3d.css`（注册于 `src/styles/scenes.css:21`）；九个文案键在 `src/data/chapter4-clock.content.json` 的 `coarseTime.movement3d`；`src/scenes/phone/P19_Clock/index.tsx` 的 coarse_time 面板接入组件并删除死代码 ClockReel/wrap/pad。玩法合同未动：`adjustCoarseBy → lockCoarseUnit(08/00) → 双锁 → confirmCoarseTime()`。
- 交互面：齿轮/指针分层爆炸视图（爆炸/装配滑杆与按钮、复位视角）、视角拖拽惯性旋转、机芯齿轮上下拖动与滚轮调节、键盘 `ArrowUp/ArrowDown`、± 按钮、锁定按钮、芯片读数与锁定台账。
- QA 修复：初版组件高 `412px` 使「进入漂移核对」主按钮被场景底部常驻反馈条（`.clock-feedback` 绝对定位）遮住中心 hit-test；将组件高度降为 `372px`（`p19-clock-movement-3d.css`），两视口下按钮中心命中均为按钮本身（430px 时间隙 `8px`、390px 下 `7px`），爆炸图各层仍完整可见。
- 浏览器验证（gstack headless Blink，`?devCheckpoint=c4-clock-coarse`）：`430×860` 与 `390×844` 两视口 document 横纵溢出均为 `0`、console/page error 均为 `0`、无失败网络请求；± 点按、齿轮拖动（上增下减）、滚轮、键盘四路调节均生效；小时 `07→08` 锁定后反馈「小时机芯已锁定。」且 ±/拖动/滚轮全部失效（按钮 disabled、spinbutton `tabIndex=-1`）；分钟 `55→00` 同理；双锁后 `2/2 LOCKED`，点击「进入漂移核对」进入第 3 关漂移矩阵；刷新后按 DEV 检查点合同重播回本关开头，正式 localStorage 存档未被开发者会话写入（键数 `0`）。
- 交付验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 均通过；离线 `demo/index.html` 为 `176590136 bytes`，SHA-256 `9f66fb51d832f5483cd25c1e0a11701becc44c0bfd55e3afb8fd23eeae727ec1`。QA 截图均存于临时目录并已删除。

## 2026-08-13 第四章校时内容扩展（四个真实关卡）

- 用户纠偏：所需“四个流程”指四段有独立内容的连续玩法；DEV 只用于跳转测试，不能把同一次简单校准拆成四个入口后视为完成。
- 关卡 1「档案重建」：六条跨场景记录中筛选三条 B2-04 有效证据，再从 `07:55 / 08:00 / 08:32 / 22:45` 选择目标时刻；错线索不会写入档案，证据不足或时刻错误会被控制器拒绝。
- 关卡 2「双机芯锁定」：小时轮与分钟轮需要分别调到 `08 / 00` 并独立锁定；锁定后的机芯停止旋转，两枚锁扣完成后才能进入下一关。
- 关卡 3「三路漂移消除」：校门 `+07`、主电梯 `-04`、B2-04 `+23` 分别需要选择反向修正 `-7 / +4 / -23`；每条选择与失败次数进入正式状态，三路归零后生成 `08:00:00`。
- 关卡 4「三协议放行」：三轮分别使用宽窗常速、窄窗加速、偏置窗反向扫描；失败回到第一轮，完成三种协议后章节才写入 `clock_phase_lock` 和完成态。
- 存档：版本升级为 `21`，保存档案线索、机芯锁定、漂移通道与尝试次数；版本 `20` 依据原 step 推断已完成的关内事实，避免旧档回退。
- DEV：保留 `c4-clock-intro / coarse / precision / release` 四个入口，但标签已改成“校时关卡 1–4”，每个入口种下此前关卡的正式事实并从本关开头开始。
- 浏览器验证：Blink `699×739` 完成一条真实全链，最终为 `archive=3 / locks=2 / drift=3 / hits=3 / step=complete`；四个 DEV 入口逐一核对状态前置分别为 `0-0-0 / 3-0-0 / 3-2-0 / 3-2-3`，放行失误会使命中数回到 `0`。
- 移动端验证：`390×844` 的第三关画面与三路操作均在手机壳内显示，document 与 scene 横纵溢出均为 `0`；浏览器控制台错误为 `0`。
- 交付验证：`npm run typecheck`、`npm run chapter4:validate-topology`、相关路径 `git diff --check`、`npm run build:single`、`npm run verify:single` 均通过；离线 `demo/index.html` 为 `176572880 bytes`，SHA-256 `427c3237114b152db1f9ee900efad52961dda9b61bab02a9b74a53f0030441cc`。重建产物通过 HTTP 打开第三关时状态为 `archive=3 / locks=2 / drift=0 / seconds_trim`，页面溢出与控制台错误均为 `0`。

## 2026-08-13 第四章校时页四段流程与视觉重构

- 新需求：校时玩法需要至少拆成 4 个 DEV 可直达流程；手机页视觉要更像章节终端，层级更清楚，不能只剩一个单调表盘。
- 已实现：`src/scenes/phone/P19_Clock/index.tsx` 现在按正式 `ClockCalibrationController` 的 `target_selection → coarse_time → seconds_trim → phase_lock → complete` 五态驱动界面，不再使用临时本地流程判断。
- 已实现：校时页重构为四段式黑金终端 UI：顶部状态带、四段步骤轨、分阶段操作面板、目标卡片、双数字轮、秒尺微调、相位放行槽、完成页账本。页面在 `430×860` 逻辑手机壳内完整显示。
- 已实现：粗调与精调的主按钮增加可用条件。`确认时分` 只在 `08:00` 时可点，`提交 08:00:00` 只在秒数归零后可点，减少误触和误导。
- 已实现：DEV 直达点固定为 `c4-clock-intro / c4-clock-coarse / c4-clock-precision / c4-clock-release`，可以分别检查四段流程起点。
- 静态验证：`npm run typecheck`、`npm run chapter4:validate-topology`、相关路径 `git diff --check` 通过。
- 浏览器视觉验证：Blink 本地 `http://127.0.0.1:5173/?devCheckpoint=...` 下，四个 checkpoint 都完成画面核对；`intro / coarse / precision / release` 四页均在同一手机壳内稳定显示。`699×739` 桌面缩放与 `390×844` 手机视口的页面、时钟场景横纵溢出均为 `0`，控制台错误为 `0`。重建后的单文件通过 `http://127.0.0.1:4173/?devCheckpoint=c4-clock-release` 再次加载，仍为 `phase_lock` 且无溢出或控制台错误。
- 浏览器交互验证：
  - `01 选择目标`：点击 `08:00` 卡片后进入 `coarse_time`。
  - `02 粗调时分`：`HOUR +1`、`MINUTE +5` 后按钮解锁，确认后进入 `seconds_trim`。
  - `03 秒级微调`：`-5 × 4`、`-1 × 3` 将 `08:00:23` 压到 `08:00:00`，提交后进入 `phase_lock`。
  - `04 相位放行`：在黄区连续命中 `3` 次后进入 `complete`。
- 完成态：全链结束后 `clockCalibration=aligned/complete`、`phaseLockHits=3`、`chapter4.phase=complete`、`clock_phase_lock` 已写入已解谜列表；完成事件仅在第三次命中时发布。
- 浏览器边界：第一次自动化脚本失败点已经确认来自 DEV 面板遮挡点击，验证脚本中已先关闭面板再执行流程；RPG 触屏表冠仅在 `seconds_trim` 阶段显示，完成后无法继续改写时间。
- 单文件验证：`npm run build:single` 与 `npm run verify:single` 通过，`demo/index.html` 产物为 `176562655 bytes`，SHA-256 `2914de500ccdaac1dbbf8df2cd594caa75328a95b8c845352f67ca54ef57d1cb`。

## 2026-08-13 启真湖第六次翻船字幕

- 新需求：启真湖累计翻船次数超过 `5` 次时，显示“你的手机和眼镜共沉启真湖，只有手机打捞上来了，眼镜永远离开了你”。
- 已实现：统一翻船控制器在计数由 `5` 增至 `6` 时发布一次 `qizhen_capsize_loss_subtitle_unlocked`；启真湖场景通过共享 RPG 底部字幕层显示 `6500ms` 的旁白字幕。
- 计数边界：同侧连续划桨或侧倾越限计入 `capsizeCount`；撞岸只停车，黑天鹅追上沿用独立追逐失败计数。剧情重置后计数归零，可在新一轮再次触发。
- 顺序修正：普通翻船提示先发布，控制器阈值字幕随后发布，防止第六次专属字幕被普通提示同步覆盖。
- 静态验证：`npm run typecheck`、相关文件 `git diff --check` 和 `npm run build:single` 通过。
- 浏览器验收：Blink `1280×720` 的真实启真湖 Phaser 场景中，第 `5` 次没有解锁事件，第 `6` 次由四次同侧划桨触发翻船并显示专属旁白，第 `7` 次没有重复；三段结果的专属事件/字幕计数分别为 `0/0`、`1/1`、`1/1`，控制台与页面错误为 `0`。截图确认字幕位于底部安全区，翻船动画与物品栏均正常。
- 单文件验收：重建后的 `demo/index.html` 通过 HTTP 进入 `c3-qizhen-open-water`，场景为 `qizhen_lake`、载具为 `kayak`、Phaser canvas 为 `1`、专属文案已内嵌、错误为 `0`。产物 `176543541 bytes`，SHA-256 `23b2a49ce5f3f2cd88e6f5ca13ece3e36c4fe181a8b04ddc67821b2c191563d9`。

## 2026-07-09

- 当前方向：完善 `7:55` 游戏本体和单文件展示页，不再调整讲稿。
- 优先级：交互稳定性、浏览器兼容、单文件交付可复现、基础 QA 可观测。
- 已做：物品栏拖拽增加全局 `pointermove/pointerup/pointercancel` 监听，释放命中保留 DOM 点选 + 矩形兜底。
- 已做：增加只读 `window.render_game_to_text()`，脚本可读取当前场景、网络、数字、道具和关键旗标。
- 已做：增加 `npm run build:single`，可从源码稳定生成单文件 `demo/index.html`。
- 验证：`npm run typecheck` 通过；`npm run test:run -- --reporter=dot` 通过 23 个测试；`npm run build:single` 已实际生成 `demo/index.html`。
- 浏览器验证：`demo/index.html` 可打开 slide，点击“开始试玩”后进入内嵌游戏；内嵌游戏 `render_game_to_text()` 返回当前初始状态。
- 浏览器验证：开发页通过全局 `pointermove/pointerup` 模拟把钥匙拖到钟楼，结果为 `towerOpened=true`、钥匙消耗、肥料出现。

## 2026-07-09 slide 拆分

- 新需求：路演已结束，`demo/index.html` 不再需要 slide 壳，恢复为纯游戏单文件。
- 已做：删除 slide 嵌入脚本，`npm run build:single` 改为只执行纯游戏 `build:demo`。
- 验证：`npm run build:single` 与 `npm run typecheck` 通过；静态检查确认 `start-game/game-shell/embedded-game-frame` 不存在；浏览器打开 `demo/index.html` 第一屏为游戏闹钟，`render_game_to_text()` 可读。

## 2026-07-10 浙大钉与图书馆页面链

- 新需求：浙大钉进入后先显示新工作台；“学在浙大”进入原页面；“图书馆”依次进入移动图书馆、空间列表、座位选择。
- 已做：导入四张 941×1672 参考图，使用截图视觉层与 React 交互热点组合，保持现有像素手机壳和 07:55 全局状态栏。
- 已做：搜索、菜单、馆舍选择、日期/时段、地图/列表、筛选、座位选择和确认预约均有实际状态响应。
- 已做：`render_game_to_text()` 增加 `zjudingPage/librarySelectedSeat/librarySeatReserved`，开发环境支持 `?scene=zjuding&zjudingPage=...` 直接视觉验收。
- 视觉检查：已渲染并查看 hub、library、library_spaces、library_seat 四页；修正选座页动态座位号与底图文字叠加。
- 测试方式调整：用户将亲自执行功能测试，后续只做视觉复刻检查与页面跳转生成确认。
- 构建验证：`npm run build:single` 通过，四层页面与图片资源已内嵌到 `demo/index.html`（约 27.2 MB）。

## 2026-07-10 图书馆座位识别修正

- 问题：地图热点按 `001–032` 逐行排列，和参考图按桌子两侧纵向编号的规则不一致；点击第三行第六列会错误显示 `022`。
- 根因：第二张桌子原图明确标注左侧 `021–024`、右侧 `017–020`，其余桌子按相同规律延续。
- 修正：座位改为四桌八列坐标矩阵；热点中心对齐椅子图标，高亮范围缩小到椅子本身。
- 视觉检查：点击 `022` 后，高亮落在第二张桌子左侧第二把椅子，与原图编号顺序一致。

## 2026-07-10 截图页面比例修正

- 问题：四张参考图为 `941×1672`，截图页面此前强制填入 `430×930` 画布，造成约 22% 的额外纵向拉伸。
- 修正：参考图页面改用等比 `430×764` 画布；原“学在浙大”页面继续使用 `430×930`。
- 布局：参考图和交互热点同步上移 `16px`，缩短顶部个人信息区并把下方内容提上来。
- 视觉检查：浙大钉主页和选座页已按 `694×739` 浏览器视口渲染检查；文字、图标恢复等比，`022` 热点仍与椅子位置一致。

## 2026-07-10 全局手机尺寸与 CC98

- 尺寸基准：以原手机主页为准，全局固定 `430×930`；已写入项目 `CLAUDE.md`，场景不得再修改外框尺寸或使用非等比图片拉伸。
- 运行时：`PhoneShell` 已恢复单一固定尺寸；CC98 与浙大钉视觉检查的外框均为 `430×930`。
- CC98：手机主页 CC98 图标已接入 `cc98` 场景，使用原生 React/CSS 重建热门话题列表。
- 可编辑内容：默认数据位于 `src/data/cc98.posts.json`；页面右上角可编辑并保存 30 个字段到本机 `localStorage`，菜单可恢复默认数据。
- 视觉参考：原图保存为 `pageexample/cc98_hot_topics_reference.png`；页面包含 5 条默认帖子、15 个按钮和 2 组导航。
- 关卡设计：新增 `docs/level-design-ideas.md`，记录三种设计方向和 10 个浙大特色候选关卡，等待用户案例后继续筛选。

## 2026-07-10 图书馆期末周跨应用关卡

- 关卡链：图书馆预约后离座丢位，校园卡校验临时离座凭证，浙大体艺显示求是潮自行车拥堵，CC98 十大与资料检索提供恢复规则，最后回到原选座页恢复预约。
- 场景复用：图书馆、校园卡、浙大体艺、CC98 四套既有画面全部复用；新增整页视觉背景为 0，只增加状态条、按钮和帖子详情原生 UI。
- 状态解耦：新增 `LibraryFinalsController` 和八段状态；关卡只发领域事件，`AudioDirector` 只订阅事件且不回写游戏状态。
- 音频：通过本机 MiniMax CLI 生成 7 条同一角色旁白、6 段阶段独立配乐和 4 个阶段独立音效；FFmpeg 统一响度，`ffprobe` 实测时长写入 `library-finals.audio.generated.json`。
- 音频差异：预约、丢座、自行车堵车、CC98 十大、CC98 检索、座位恢复均使用不同配乐；旁白按阶段调整语速和音高。
- CC98：主页图标跳转已在浏览器点击确认；帖子详情重建为整页像素 UI，包含楼主、操作记录、热门回复、楼层和分页。
- 论坛素材：导入 `cc98_forum_treasure.png`，在第 3 楼以 `bd` 留言和图片附件展示。
- 配置入口：剧情台词、十大帖子、检索资料和回复楼层集中在 `src/data/library-finals.content.json`，后续改剧情无需修改关卡状态代码。
- 验证：`npm run typecheck` 通过；`npm run test:run -- --reporter=dot` 通过 25 个测试，jsdom 仅输出既有媒体播放能力警告。
- 原创化：CC98 列表、楼主正文、操作记录和全部回复已改成围绕丢座、校园卡、求是潮堵车与资料检索的虚构内容；本地存储升级为 `v2`，旧参考内容不会继续显示。
- 入口调整：手机主页删除校园卡应用；浙大钉“电子校园卡”进入校园卡，常规返回浙大钉首页，临时离座阶段返回图书馆选座页。
- 热点修正：浙大钉主页热点改用截图等比显示后的真实内容区，应用格、快捷入口、搜索栏和底部导航已用可视化边框检查；个人资料热点额外下移收紧。
- 最终构建：`npm run build:single` 已重新生成 `demo/index.html`，文件约 33.4 MB；静态服务加载成功。

## 2026-07-10 CC98 校园痛点与谜题调研

- 调研方式：按用户要求使用 Computer Use 浏览真实 CC98 首页、宿舍搬迁反馈专楼、纯 `ac01` 回复讨论和课程出分讨论专楼。
- 内容边界：仅记录校园问题、论坛交互与 `bd/cy/ac01` 等极短站内用语；不保存真实用户名，不复制真实学生正文，游戏文本全部原创。
- 关键问题：考试周搬迁与抽签公开性、宿舍条件和通勤、课程出分等待、评论内检索缺失、资料包容量与链接、图片回复造成的信息噪声。
- 设计产物：新增 `docs/cc98-campus-pain-puzzle-research.md`，包含 8 个照片玩法、9 种论坛语义、12 张关卡卡片及按画面复用率划分的实现优先级。
- 推荐首链：照片找差异 → 校园卡空调费用 → `ac01` 过滤 → `bd` 顶帖 → 浙大体艺自行车路线 → 图书馆座位恢复。
- 跨月扩展：继续使用 Computer Use 检查 30 日热门、历史上的今天和站内跨月检索，样本覆盖 2026 年 1、2、4、6、7 月及 2025 年 9–12 月，并以更早年份验证周期性。
- 传播规模：当前样本中校园道路突发事件约 11 万浏览、出分专楼约 9.7 万、宿舍搬迁约 7.3 万；跨月搜索结果仅用于重复度判断，不冒充历史十大排名。
- 新增设计：补充十大后续链、热度公式、已消失的十大、校园卡季节钟、退补选循环和体育打卡审核回退六组谜题。

## 2026-07-10 浙大钉与图书馆原生 HTML 重建

- 问题确认：新增四页此前使用整页参考图加透明热点，动态日期、座位号等 HTML 状态会与底图文字重叠，也无法支持后续分元素动画。
- 技术栈复用：沿用项目现有 React 18、TypeScript、组件内状态、领域控制器、集中式 `scenes.css` 和统一 `PhoneShell`，没有引入第二套页面框架。
- 原生重建：`hub`、`library`、`library_spaces`、`library_seat` 已改为独立 DOM；旧 `ScreenshotPage`、`Hotspot`、`.zju-reference-*` 和 `.zju-hotspot` 已删除。
- 媒体边界：四张 941×1672 整页图已移到 `pageexample/*_reference.png`，运行时不再导入；仅从空间列表提取 3 张房间实景和 1 张读者头像作为独立 `<img>` 媒体。
- 交互保留：应用搜索、电子校园卡、图书馆入口、空间模式、馆舍选择、房间预约、日期、时段、地图/列表、筛选、座位与预约确认均继续使用原状态和路由。
- 视觉检查：在逻辑 `430×930` 和默认缩放视口检查四页；工作台与选座页底部空段已收紧，手机外框比例保持 `430:930`。
- 跳转检查：浏览器实际点击 `图书馆 → 座位预约 → 二层南 → 022`；四次定位均唯一，`022` 高亮位于第二张桌子左侧第二席，页面显示“已选座位号：022”。
- 运行时检查：选座页 `<img>` 数量为 0；浏览器控制台无 warning/error；单文件中未出现四张整页图文件名和旧截图渲染类名。
- 审查修正：房间 CTA 增加 `预约+房间名` 的唯一可访问名称；ActionSheet 增加首次聚焦、Tab 焦点约束、`Escape` 关闭和触发按钮焦点恢复，浏览器已实际验证。
- 验证：`npm run typecheck` 通过；`npm run build:single` 通过，生成 `demo/index.html` 约 26.0 MB。按用户要求未运行自动化测试套件。

## 2026-07-10 跨应用谜题核心状态机

- 状态：补齐 14 个新流程阶段、谜题细分状态、路线点、`bd` 回复 ID 和审核参数类型；旧阶段仅保留为带 TODO 的迁移兼容类型。
- 规则：新增有序路线、两级引用和 `7-47-3` 审核纯函数及 3 条单元测试；冻结的 readonly `ROUTE_ORDER` 同时供路线校验和控制器事件使用。
- 控制器：`LibraryFinalsController` 成为新流程的统一写入口；阶段与 puzzle 在一次 store 更新中提交，失败调用不改状态，第三个有效 `bd` 直接发出 `cc98_top_ten_reached`。
- 兼容：旧四个命令保留独立 deprecated lane，继续写入 `pass_validated/bike_jam/top_ten/guide_found` 并发送既有事件；显式新命令继续执行完整 C 流程。
- 交互状态：首次隐藏 18 条进入 `floor_47_found`，后续关闭或重开过滤器保留 citation 和 phase；审核入口把三个参数初始化为 `5/45/1`。
- 边界：预约座位号在写状态和发事件前统一 `trim()`；两条 lane 恢复座位前都要求非空座位号；legacy 资料查找只接受 `library-leave-pass`，失败调用保持状态和事件历史不变。
- 存档：`SaveStore.load()` 逐字段构造 `GameState`，枚举、数字范围、nullable 字段和布尔值均做白名单校验；unknown key 不进入状态，非法值回退当前初始值，读取或 JSON 解析异常返回 `null`。
- 验证：用户指定的 3 个测试文件共 27 条测试通过；`npm run typecheck` 通过；完整 Vitest 套件 13 个文件、50 条测试通过。完整套件仍输出既有 jsdom 媒体 API 和 React `act(...)` 警告。
- 范围：未创建提交，未重写 `demo/index.html`，未生成视觉 QA 截图。

## 2026-07-10 跨应用谜题线索条 Task 3

- 谜题配置：新增 `library-finals.puzzle.json`，精确固定 18 条 `ac01`、47 楼、`47 → 12 → 1`、三点路线、3 次 `bd`、`7-47-3`、`7/47/3` 审核与 `45/560/800ms` 时序。
- 线索层：新增 `QuestClueStrip`，仅在 11 个新流程活动阶段显示；`idle/seat_reserved/seat_recovered`、旧流程阶段和 bare 场景隐藏。
- 槽位规则：`route_screenshot`、`route_screenshot_attached`和 `attached` 归并为一张轨迹截图，再按稳定顺序显示恢复码与临时离座凭证，最多 3 个 `28px` 槽位。
- 拖拽：临时凭证仅在 `route_audit_passed` 可拖；已实现 pointer capture、fixed ghost、window 级 move/up/cancel、`lostpointercapture` 与卸载清理，并发出 `library_pass_drag_started/ended`。
- 壳层：`PhoneShell` 在状态栏后、物品栏前挂载线索层；保持 `430×930`，线索条位于 `top:44px/left:8px`，场景层 `z-index:0`、线索层 `50`、控制中心 `65`。
- 可访问性：槽位具有 `aria-label`，线索区域使用 `aria-live="polite"`，hover/focus 显示标签，focus-visible 轮廓可见；reduced motion 只保留透明度变化。
- 聚焦测试：`QuestClueStrip.test.tsx` 26 条通过，覆盖活动/非活动/bare 显示、三槽归并、release、cancel、lost capture 和 unmount。
- 完整验证：`npm run test:run -- --reporter=dot` 通过 14 个文件、76 条测试；`npm run typecheck` 通过。完整套件仍输出既有 jsdom 媒体 API 与 React `act(...)` 提示。
- 构建与浏览器：单文件构建在 `/tmp` 输出通过并已清理，未改写 `demo/index.html`；Chromium 已检查逻辑 `430×930` 和 `390×844` 缩放视口、hover/focus、拖拽 ghost、外部释放和控制中心层级，临时截图与快照已删除。
- 边界：未修改 controller、core、CC98、Tiyi、Zjuding，未创建提交。

## 2026-07-10 Task 3 规格复审修复

- 事件契约：`library_pass_drag_started` 现在固定携带 `cancelled: false`，release、cancel 和 lost capture 相关断言已同步。
- 配置单源：`puzzleRules` 直接导入 `library-finals.puzzle.json`，通过 `LibraryFinalsPuzzleConfigView` 校验并冻结路线、审核、`ac01FloorCount`、`bdRequired` 和 `recoveryCode`。
- 运行逻辑：`ROUTE_ORDER`、`validateAudit`、CC98 过滤楼层数、`bd` 达标数和恢复码均读取同一配置视图，已删除这些值在控制器中的重复常量。
- 挂载边界：导出 `isQuestCluePhase`，`PhoneShell` 仅在非 bare 且新流程活动阶段挂载 `QuestClueStrip`；组件 effect 同时保留活动阶段防御检查。
- 监听验证：新增非活动 `PhoneShell` 的 window pointer listener 零注册测试。
- 验证：线索条、谜题规则和控制器定向套件 3 个文件、43 条通过；完整 Vitest 14 个文件、78 条通过；`npm run typecheck` 通过。完整套件仍输出既有 jsdom 媒体 API 与 React `act(...)` 提示。
- 边界：未修改 core、CC98、Tiyi、Zjuding，未创建提交。

## 2026-07-11 第一章启动链与宿舍据点确认

- 宿舍方案：用户确认 A，第一章结尾开放为可反复返回据点；后续用于整理“游戏”菜单内容、查看室友留言和返回校园地图。
- RPG 首次进入：只显示人物、地图和临时道具栏，移动与交互暂时锁定，手机入口可用。
- 启动顺序：浙大登录读取浙大钉身份 → 浙大钉部门黄页拨打剧情学号 → CC98 交换操作键 → 浙大体艺开始锻炼并启用行走。
- 第一关：强制取得一个主线道具，完成必要区域跑图后开放“游戏”入口并进入第二章。
- 道具栏：第一关通过后隐藏常驻临时栏，道具、线索和任务记录迁入“游戏”菜单。
- 方向：普通手机场景固定竖屏；后续 RPG 固定横屏。
- 文案与音频：整体口吻缩短并增加轻松嘲讽；第二章图书馆旁白继续英文，使用独立女声。
- 规格与计划：新增 `2026-07-11-act1-bootstrap-dorm-hub-design.md` 和对应实施计划。

## 2026-07-11 CC98 过滤与引用链 Task 4

- 调查专楼：原生生成 63 层虚构回复，18 层纯 `ac01` 来自配置；剧情专楼与普通可编辑帖子、本机存储完全分离。
- 过滤演出：18 层按 `45ms` 阶梯折叠，完成后聚焦第 47 楼引用；关闭和重开过滤不清空引用进度。
- 引用链：完成 `47 → 12 → 1`，错误查看第 46 楼只触发 `220ms` 反馈；主楼显示 `北门 → 桥 → 二层南` 并进入体艺路线。
- 兼容：旧版十大帖子继续保留在旧阶段，新流程打开调查专楼不会调用旧 `openTopTen()`。
- 可编辑边界：普通帖子仍可编辑和保存，两个剧情帖子不会写入 `localStorage`。
- 验证：三个 CC98 聚焦测试文件共 14 项通过；`npm run typecheck` 通过。JSDOM 仍输出既有媒体播放未实现提示。

## 2026-07-11 第一章启动链、横屏 RPG 与音频交付

- 状态链：实现 `浙大登录读取身份 → 部门黄页拨打剧情学号 3250100755 → CC98 交换操作键 → 浙大体艺开始锻炼`，四步在浏览器中实际点击通过。
- RPG：首次进入只显示人物、校园地图、临时道具栏和手机入口；未授权时移动锁定，安装按键后显示触控键，体艺授权后启用键盘和触控移动。
- 地图视觉：Phaser 画布固定 `960×540`，使用分层屋顶、立面、门窗、求是桥、水面、树木和名称标签重建俯视伪 3D 校园场景；修正建筑标签遮挡、北门裁切和人物与触控键重叠。
- 跑图与据点：强制拾取 `游戏卡带`，记录北门、桥、图书馆、游戏终端四个区域；完成后收纳临时道具栏，开放“游戏”菜单、第二章和可反复返回的宿舍据点。
- 第二章跨应用链：浏览器实际检查 CC98 63 楼与 18 条 `ac01` 过滤、体艺路线、`7/47/3` 审核，并用全局指针拖拽将 PASS 从线索栏放到图书馆 `022`，座位成功恢复。
- 手机适配：普通手机页面保持 `430×930` 竖屏逻辑尺寸，在 `390×844` 视口中等比缩放；RPG 仅在竖屏显示横屏提示。
- 音频：MiniMax CLI 实际生成 7 条第一章中文男声和 6 个独立动作音效，总旁白时长 `27.861s`；第二章保留 14 条英文女声、9 段配乐和 20 个音效。`AudioDirector` 仅订阅领域事件，播放失败不回写关卡状态。
- 自动验证：`npm run typecheck` 通过；完整 Vitest 为 22 个文件、103 项通过；JSDOM 仍输出既有 `HTMLMediaElement` 未实现与 React `act(...)` 提示，真实浏览器无 warning/error。
- 单文件：`npm run build:single` 成功生成 `demo/index.html`，`29,877,910 bytes`；静态检查确认无外链脚本、无外链样式，Phaser 与两套旁白均已内嵌。
- 浏览器限制：自动浏览器策略拒绝直接导航到 `file://` 地址；最终视觉使用同源开发预览检查，单文件本体通过构建与静态内联检查。

## 2026-07-11 CC98 第二批热点调研

- 校网恢复后使用 Computer Use 重新读取 `7 日热门`和`30 日热门`；校园道路事件约 11 万、出分专楼约 9.9 万、宿舍搬迁约 7.3 万。
- 论坛功能议题“一键隐藏纯 ac01 回复”进入 7 日热门，约 1.2 万浏览，进一步支持将过滤器作为正式谜题机制。
- 食堂排队检索覆盖 2023–2026，确认饭点、窗口规则、活动菜品和失物位置为反复出现的低单帖、高频问题。
- 校车检索显示 6 月末至暑假切换期问题密集，集中于时刻表版本、停运日期、上车点、下车点和失物追踪。
- 新增 8 个可落地谜题：窗口时钟、六分钱取餐、队尾路线、菜单版本、时刻表版本、上车点漂移、末班车回执、失物循环。
- 边界：未保存真实用户名，未复制真实正文；自行车、考试周、选课和毕业离校仍待站内跨月检索，不将推测写成调查结论。

## 2026-07-11 紫金港地图识别、入口迁移与桌面全视口

- 官方对照：检查浙江大学官方三维地图及紫金港地标资料，当前泛化的斜河、教学区、图书馆和游戏终端无法通过“可识别为浙大”验收。
- 地图重画：继续使用 Phaser 3.87 原生 Graphics、Arcade Physics 和 `960×540` 逻辑画布；运行时没有导入整张地图截图。
- 空间锚点：改为纵向启真湖水系，东岸组合基础馆与管院楼塔楼；新增月牙楼、紫金港体育馆、求是大讲堂、湖心岛、南华园、南大门和求是鹰。
- 玩法保留：重新对齐桥、基础馆、南大门和校园地图终端四个触发区，保留水域碰撞、角色行走、卡带拾取和第一章状态机；底层 `north_gate` ID 为存档兼容保留，显示名改为“南大门”。
- 入口链：手机主页删除独立“游戏”；浙大钉“校园地图”成为校园 RPG 入口；“打开手机”返回浙大钉首页，第二章入口继续进入浙大钉图书馆。
- 桌面适配：RPG 进入后铺满浏览器可用区域；`1280×720` 完整铺满，`1100×800` 渲染为 `1100×618.75`、比例 `1.7778` 并上下留边，无非等比拉伸；`F` 键保留用户主动系统全屏。
- 视觉验收：完整重载后画布稳定非空，校区标签不再被临时道具栏遮挡，浏览器 warning/error 为 0；HMR 后一次 WebGL 截图出现黑块，完整重载后消失，未进入交付构建。
- 跳转验收：浏览器实际点击 `浙大钉 → 校园地图 → 打开手机`；返回后浙大钉首页、校园地图按钮均存在，手机主屏“游戏”按钮数量为 0。
- 验证：`npm run typecheck` 通过；完整 Vitest 22 个文件、104 项通过，仍有既有 JSDOM 媒体 API 与 React `act(...)` 提示；`npm run build:single` 生成 `demo/index.html`，`29,883,447 bytes`。

## 2026-07-11 第二、三章完整开发报告

- 范围纠正：撤回误写的第一关 V2 规格、实施计划引用和进度段落；第一关继续以用户提供的 36 页策划书和现有实现为准。
- 第二章报告：新增 `docs/chapter-2-library-finals-development-report.md`，共 885 行、30 个主章节，完整记录 `022` 丢座、63 楼调查、18 条 `ac01` 过滤、`47 → 12 → 1` 引用、体艺路线、照片证据、三次 `bd`、`7-47-3` 审核和 PASS 拖放。
- 第二章实现事实：主流程已完成；14 条英文女声、9 段配乐和 20 个音效已经生成。`music_cc98_investigation.mp3` 在生成清单中只有 `35ms`，报告将其列为待修问题。
- 第三章报告：新增 `docs/chapter-3-qiushi-bike-755-development-report.md`，共 861 行、32 个主章节，记录 P16 三车道骑行、755 米目标、三次机会、三类障碍、速度曲线、碰撞、胜负、快照和章节化缺口。
- 第三章实现事实：P16 可玩原型已经存在；第二章门槛、持久完成状态、专属音频、后台暂停、障碍组合约束和下一章出口仍待实现。
- 索引：新增 `docs/chapter-development-report-index.md`，统一第一关、第二章和第三章的文档入口与衔接关系。
- 验证：第二章与第三章相关 8 个测试文件共 59 项通过；`npm run typecheck` 通过。
- 范围：本轮只修改开发文档和进度记录，没有修改运行时代码或重新构建单文件。

## 2026-08-21 第四章 Task5 集成修补（面包房顺序合同 + 第四章库存接线）

- 目标：继续推进第四章 `7:55` 主线执行面，先修掉两个直接影响流程的缺口：`12:25` 面包房里“看灯→停带→取时针”的顺序合同，以及第四章六个新道具未进入通用 RPG 物品栏/图标/检查弹窗/拖拽提示体系的问题。
- 控制器与交互合同：`src/modules/ChapterFourTemporalMazeController.ts` 新增 `inspect_bakery_conveyor_lamp` intent；`src/core/types.ts` 增加事实 `bakery_conveyor_lamp_inspected`；`src/scenes/rpg/RpgInteractionContract.ts` 改为先激活传送带灯，记录该事实后才开放时针拾取，时针未亮相前直接取不会再被合同放行。
- 场景与 Host：`src/scenes/rpg/ChapterFourTemporalMazeScene.ts` 把传送带灯映射到新 intent；`src/scenes/rpg/RpgGameHost.tsx` 给 Chapter 4 requestId 去重集合补了生命周期清理，离开教学楼或集合过大时清空，避免长会话中无界累积。
- 通用库存接线：把 `attendanceRecordPaper / oldClockHourHand / clockPositioningPlate / shortPryBar / universalLubricatingOil / finalMinute` 接入 `ItemId` 主集合，并同步补齐：
  - `src/data/itemCatalog.ts` 的 inspect/use 合同；
  - `src/components/InventoryBar.tsx` 与 `src/scenes/rpg/RpgInventoryDock.tsx` 的排序；
  - `src/components/PixelIcon.tsx` 的像素图标与 `ITEM_META`；
  - `src/components/ItemInspectDialog.tsx` 的检查文案；
  - `src/scenes/rpg/RpgItemUseGuidance.ts` 的第四章拖拽提示。
- 当前影响：第四章新道具现在可以在手机与 RPG 两侧统一显示、打开详情、给出场景内使用提示；面包房流程不再让灯和时针同时开放。
- 静态验证：
  - `npm run chapter4:validate-story` 通过；
  - `npm run chapter4:validate-topology` 通过；
  - `npm run typecheck` 通过；
  - 定向 `git diff --check` 通过。
- 未完成：Task6 的场景遗留逻辑还在，尤其是 `ChapterFourTemporalMazeScene.ts` 内旧电梯/旧导视死代码、Chapter 4 精灵显式 trim 消费、以及更完整的动态实体可视边界接线仍待继续收口；三层浏览器碰撞校验按用户要求不做。

## 2026-07-11 第二、三章 V1.0 并行开发收口

- 第二章：重新生成 `music_cc98_investigation.mp3`，实测 `24.000s`；删除旧版 `pass_validated → bike_jam → top_ten → guide_found` 阶段和未引用音频，当前正式资源为 10 条英文女声、7 段配乐、17 个章节音效，并复用 2 个全局 UI 音效。
- 第二章存档：`SaveStore` 现在恢复完整校验后的 `GameState`，覆盖调查阶段、引用、路线、证据、`bd`、审核参数、PASS 和座位恢复；保留独立第三章切片迁移入口。
- 第三章门槛：P13 “游戏”图标只在 `libraryFinalsPhase === "seat_recovered"` 后出现，首次解锁脉冲只播放一次；浏览器实际点击后进入 P16。
- 第三章玩法：补齐受约束障碍波次、近失反馈、`188 / 377 / 566 / 755m` 节点、页面隐藏暂停、1 秒恢复提示、reduced motion 和 Phaser 销毁清理。
- 第三章存档：新增 `BikeArcadeChapterController`，持久化 `unlocked / completed / attemptCount / bestDistance / bestLives`；成功只接受 `755m`，失败只接受机会归零。
- 第三章音频：MiniMax CLI 生成 4 段配乐、10 个动作音效和 3 条英文女声；`AudioDirector` 按事件对轴，离开页面会取消延迟 cue，重玩时最后一次机会和结算旁白可以再次触发。
- 章节出口：成功结算进入 P17 `chapter_transition`，显示距离、剩余机会和尝试次数，并提供返回桌面与重玩入口。
- 浏览器验收：逻辑 `430×930` 与 `390×844` 均无页面溢出；CC98 主按钮实际进入原创帖子列表；P16 Canvas 为 `390×650`，像素采样有 `15,693` 个点与底色不同；P17 页面无尺寸溢出。
- 自动验证：`npm run typecheck` 通过；完整 Vitest 为 32 个文件、149 项通过且无媒体或 `act(...)` 警告；两套音频 `--verify-only` 均通过；`npm run build:single` 生成 `45,931,113 bytes` 的 `demo/index.html`，无外链脚本或样式。
- 项目规则：`CLAUDE.md` 新增长期章节约束，统一入口门槛、共享存档、终态校验、Phaser 生命周期和场景关闭音频清理；新增规则后对应 5 个测试文件、33 项再次通过。

## 2026-07-11 紫金港可行走 Tiled 地图与高精度模型重建

- 运行结构：校园场景改为 `75×50`、`32px` 瓦片的 `2400×1600` Tiled JSON 世界；地面、水体、装饰、道路折线、环境对象、地标对象和水域碰撞均为独立可编辑层，运行时没有整幅校园背景图。
- 高精度资产：以基础图书馆精灵为画风基准，GPT Image 生成 4×4 环境对象图集，包含教学楼、宿舍、科研楼、服务楼、香樟、垂柳、湖心岛、南华园、大草坪、广场、球场、温室、桥、自行车棚和信息亭；旧手工简化 SVG 图集已删除。
- 地标资产：月牙楼、基础图书馆、主图书馆、管理学院、求是大讲堂、紫金港体育馆和南大门保留独立高精度 PNG；原始生成图单独存档，构建脚本重新处理透明通道并清除洋红边缘。
- 地形材质：草地、石材和水面从高精度场景资产抽取为无缝镜像瓦片；镜头缩放固定到 `0.625 / 0.75 / 0.875 / 1 / 1.125` 档位，使 `32px` 瓦片落在整数像素并消除缩放缝。
- 布局修正：删除遗留可见几何建筑；重新分配地标、普通建筑和景观位置，月牙楼前科研楼、体育馆前宿舍与球场、管理学院与基础馆、南大门与南华园均不再重叠；人物出生点移到南大门前方。
- 道路重建：旧横竖瓦片网格清零；道路改为 Tiled 折线对象，机动车道仅保留外围路、东西分区走廊和南门南侧接入线，启真湖使用两岸步道及三座桥接线。道路分段绕开建筑可见边界，渲染分为路肩、路缘、沥青和中心虚线。
- 桥梁修正：桥位移动到启真湖三个收窄处，显示宽度由 `440` 提高到 `560`，水体碰撞同步开出 `7` 格桥口；桥端覆盖两岸，角色可通过桥口，不再悬浮于宽湖面中央。
- 浏览器检查：在 `1280×720` 完整重载检查南门、中央湖区、北区、东北区和大草坪；Canvas 为 `960×540` 等比铺满，拖拽镜头后 `render_game_to_text()` 返回 `manual` 模式和正确世界坐标，浏览器 console/page error 为 0。
- 验证：`npm run typecheck` 通过；地图模型与 Tiled 结构 7 项测试通过；完整套件 167 项中 166 项通过，唯一失败为 CC98 可编辑帖子默认标题与旧测试期望不一致；`npm run build:single` 成功生成约 `48.6 MB` 的 `demo/index.html`。

## 2026-07-11 启真湖桥与河槽一体化修复

- 素材分层：新增 `process-zijingang-bridge.mjs`，从环境图集第 13 帧分离石质桥体，删除素材内自带的蓝紫水纹，并转成与东西向通行轴一致的透明像素模型。

## 2026-07-19 第二章身份保护、移动链与图书馆调查链修正

- 身份保护：新增 `src/core/IdentityAccess.ts`，唯一展示规则固定为 `inventoryRecovered && items.campusCard`；在该条件不成立时，浙大钉名字区、校园卡页、部门黄页、Toast、RPG 名牌、库存文案与卡片说明统一隐藏真实姓名和学号。
- 首次取卡：寝室右侧个人书桌交互现在一次性恢复道具栏、发放校园卡并自动打开放大卡片；首次完整身份只出现在该放大界面，关闭前桌面分栏 phone pane 进入 `inert` 状态，无法绕过首显。
- 旧存档迁移：`SaveStore` 升级到新阶段链。已完成命名、安装手柄、手动移动或后续图书馆阶段的旧存档会自动补齐校园卡与道具栏事实；仍停留在前置阶段的旧存档继续隐藏身份。
- 第一章基础界面：状态栏、任务栏和页面控制区改为固定安全区；CC98 占座调查搜索行改成 `图标 / 输入框 / 搜索键` 三列，结果标题、楼层和正文分层排版，超长文本单行截断。
- 第二章入口与移动：补齐 `朋友追问 → 系统红圈 → 找到道具栏 → 寝室宝箱 → 校园卡首显`。人物命名、课外锻炼、三击三角、水滴取线、右箭头合成、余额改写、手柄购买、手柄安装、首次手动输入和可离开寝室提示已经拆成独立状态。
- 预约前置：首次手动移动后，系统会插入“先预约基础馆二层南区 022”说明；预约成功前寝室出口与校园路线保持关闭，避免地图开放和图书馆台词堆叠。
- 图书馆调查链：馆藏终端改为显式“检索已解锁”；索书号拖拽先打开《旧版临时离座恢复规定》，关闭后才推进任务；任务栏新增三项证明要求；照片页删除独立亮度条并直接依赖控制中心亮度；失物招领机补齐四阶段文本；四证据上传后增加 bd 前系统剧情。
- 状态一致性：图书馆关键道具消耗与 puzzle 写回改成单次 store 更新；右移箭头在余额与 022 小票流程中保留复用；手柄购买只入背包，安装后才停止自动走动并开放方向输入。
- 构建验证：`npm run typecheck` 通过；`git diff --check` 通过；`npm run build:single` 已实际重建 `demo/index.html`。
- 浏览器验证：按 `develop-web-game` 技能实际检查 `render_game_to_text()`、截图与时间推进；逻辑 `430×860`、`390×844`、`960×540` 三种视口下，身份隐藏页无姓名/学号泄露，校园卡首显只出现在放大卡片，CC98 搜索三列与结果分层可见，RPG `960×540` 画布、任务栏与道具栏无重叠。临时 QA 截图已在本轮检查后清理。
- 约束：本项目当前未恢复自动化测试套件，按工作区规则仅执行 `typecheck`、单文件构建与真实浏览器核验。
- 桥面拼接：每座桥使用一个完整左段和一个裁切延长段重叠，跨度固定为 `970 → 1400`，中央接缝收在桥墩处，左右桥台均覆盖陆岸。
- 水域建模：Tiled `Water` 图层继续保留连续水格和纹理；独立 `waterCollisionCells` 只在三座桥下开出 `96px` 通行带，桥下可见水面与角色碰撞不再共用删格逻辑。
- 坐标单源：桥对象写入跨度、段宽、延长段起点和碰撞半宽；道路折线、石质落脚区、碰撞通道与第一章桥触发区均读取或同步到这组坐标。
- 视觉检查：`1280×720` 浏览器画面确认北桥横跨完整河槽、水面连续、两端落在石质桥台，控制台错误为 `0`；临时截图位于 `/tmp`，检查后删除。
- 完整验证：`npm run typecheck` 通过；35 个测试文件、168 项测试全部通过；新增地图测试同时验证桥下仍有 Water tile 且不存在 WaterCollision。
- 单文件：`npm run build:single` 成功生成 `48,752,468 bytes` 的 `demo/index.html`；桥体与延长段均已内联，外链脚本和外链样式数量为 `0`。

## 2026-07-30 启真湖场景继续打磨

- 范围：只继续修改 `/src/scenes/rpg/QizhenLakeScene.ts` 的启真湖场景视觉层和交互 UI，不改手机页、不改状态机、不打包单文件。
- 外部参考：用本机 Kimi CLI 做了一轮只读审美和演出审查，主要吸收了“深色模式避免平铺遮罩、关键交互点需要可读聚焦、装置类 UI 要带结构细节”的建议。
- 已做：为启真湖补了更强的环境层，包含水面 shimmer、glint、ripple、漂浮粒子，以及按 plate 区分的深色聚焦光斑。
- 已做：指示牌阶段把三块牌子的实体感继续拉高，新增编号圆章、水面缺口提示文案，并把深色模式下的可见度进一步抬高，避免只能看到一排发灰方框。
- 已做：喷雾阶段让机器本体和同步 HUD 同时可读，避免 HUD 把核心可交互物完全压住；当前截图里可同时看到喷雾控制器和同步条。
- 实机检查：按 `develop-web-game` 流程重新跑了 `c3-qizhen-reflection / signs / decoy / mist` 四个检查点截图，并逐张人工查看。
- 实机结果：reflection 看到三段拦截圈与岸线环境；signs 能稳定看到三块编号指示牌和顶部缺口提示；decoy 有更明确的挂载位和站位圈；mist 能同时看到喷雾控制器与同步 HUD。
- 交互回归：倒影阶段在开场对白结束后执行一次中央拦截，状态按规则记录 `reflectionMistakes=1`；指示牌阶段从深色观察切到浅色操作并旋转中央牌，状态变为 `signRotations=[0,1,0]`；喷雾阶段实际移动到湖面观察点并交互，状态写入 `mistRhythmRead=true`。三次浏览器运行均没有页面或控制台错误。
- 文案收紧：只调整场景新增的物件名、操作提示和失败反馈，删除“同步、观测、目标、校准”等抽象界面术语，改成可直接对应画面与动作的短句；谜题目标、状态条件和事件名均未改动。
- 原文边界：已将 `chapter3-qizhen-lake.content.json` 与《755_chapter3_detailed_gdd_animation_spec_v1.0》《第三章文本总》逐段对照，文档规定的剧情对白保持原文，本轮没有为追求口语化擅改剧情文本。
- 文案实机：重新检查 `c3-qizhen-signs / decoy / mist` 三个检查点；新提示在 `960×540` 画面内无截断，实际旋转中央指示牌后仍写入 `signRotations=[0,1,0]`，观察水面后仍写入 `mistRhythmRead=true`，浏览器未记录页面或控制台错误。
- 校验：`npm run typecheck` 通过；`git diff --check -- src/scenes/rpg/QizhenLakeScene.ts progress.md` 通过。
- 交付更新：前一轮按当时要求未打包；用户随后明确标注需要重建，现已执行 `npm run build:single`。生成的 `demo/index.html` 为 `99,836,762 bytes`，SHA-256 为 `1ff3bf509c91ae20b503267c332f13ab95f2f8f7b998d2fd61d22f70601fb13d`。
- 离线单文件检查：直接通过 `file://` 打开 `c3-qizhen-signs` 与 `c3-qizhen-mist`，新文案和场景画面均已进入生成文件；实际旋转中央指示牌后得到 `signRotations=[0,1,0]`，观察水面后得到 `mistRhythmRead=true`，没有页面或控制台错误。

## 2026-07-11 桥面接缝、体育场比例与道路净空修复

- 桥面连续化：桥素材改为 `430×132` 单一模型，左右桥头保留原始比例，仅将中央桥面扩展到完整跨度；三座桥共享模型，中央砖缝、栏杆和桥身不再错位。
- 体育尺度：田径场从 `360` 放大到 `560` 显示宽度，并从 `y=650` 下移到 `y=810`；当前可见占地与紫金港体育馆接近，两个对象之间保留明确空地。
- 道路整理：删除西北道路断点中的重复教学楼，将两段道路合并为连续 `west_north_link`；宿舍、科研楼和服务楼移出机动车道 `25px` 净空范围。
- 东区整理：校园终端移动到 `(2250, 1380)`，强制道具与任务触发区同步迁移，避开温室和南侧道路；清理田径场范围内的一栋重复科研楼。
- 约束测试：新增机动车道与带碰撞建筑净空检查，以及田径场最小校园尺度检查；完整套件为 35 个测试文件、`170` 项全部通过。
- 浏览器检查：在 `1280×720` 分别检查桥梁、体育区和西北道路，镜头拖动坐标稳定，页面与控制台错误为 `0`；临时截图检查后删除。
- 单文件：`npm run build:single` 生成 `48,701,140 bytes` 的 `demo/index.html`；外链脚本和样式为 `0`，旧桥延长段引用为 `0`。

## 2026-07-11 建筑尺度模型与水域净空约束

- 尺度分层：所有地标与结构对象写入 `displayWidth`、`placementWidth/Height`、`placementOffset`、`collisionWidth/Height` 和 `scaleClass`；显示、占地检查和物理碰撞不再共用一个粗略尺寸。
- 生成拦截：`generate-zijingang-tilemap.mjs` 在写出 JSON 前检查每个结构与 Water tile 的矩形相交，并以 `4px` 净空检查结构之间重叠；任一失败会中止地图生成。
- 水域修形：主湖东向扩张带限制到 `x≤45`，恢复基础图书馆和东侧水域之间的陆岸，不改动桥下连续水面和碰撞通道。
- 东区布局：删除位于东侧水带上的重复科研楼与服务楼；田径场移到 `(2120,810)`，车棚移到 `(1770,1080)`；温室缩放并移到 `(2240,1250)`，校园终端保留在 `(2250,1380)`。
- 地标尺度：地标显示宽度进入 Tiled 属性，Phaser 按该宽度同比缩放精灵、碰撞和标签；基础图书馆调整为 `340px` 并迁移到 `(1720,770)`，任务触发区同步。
- 遮挡清理：删除覆盖温室的两组东岸旧树群；温室、终端、宿舍和水岸均保持独立可见。
- 双重验证：新增地图测试独立检查尺度字段、水域净空和结构互斥；生成器校验已实际运行通过，完整套件为 35 个文件、`172` 项全部通过。
- 浏览器检查：`1280×720` 检查基础馆与东侧水带、温室与终端区域，结构均位于陆地，控制台错误为 `0`；临时截图检查后删除。
- 单文件：`npm run build:single` 生成 `48,707,049 bytes` 的 `demo/index.html`，外链脚本和样式数量均为 `0`。

## 2026-07-11 基础图书馆 L 形多边形占地

- Tiled 多边形：新增 `StructureFootprints` 图层，基础图书馆使用 `12` 点凹多边形描述塔楼、两翼和内凹区域，坐标随 `displayWidth / baseWidth` 同比缩放。
- 物理分解：新增 `StructureCollisions` 图层，由同一尺度规格生成 `4` 个矩形碰撞块；Phaser 从图层加载碰撞，删除基础馆渲染函数中的硬编码障碍物。
- 几何校验：地图生成器新增点在多边形、线段相交和多边形相交计算；复杂建筑使用真实多边形检查水域与结构冲突，普通结构继续使用矩形快速检查。
- 数据契约：基础馆 Tiled 对象写入 `placementShape=polygon`；新增测试要求 `12` 个顶点和 `4` 个有效碰撞矩形，防止回退为整块矩形占地。
- 浏览器检查：`1280×720` 重新加载基础馆与两侧水域区域，画面稳定，控制台错误为 `0`；临时截图检查后删除。
- 完整验证：`npm run typecheck` 通过；35 个测试文件、`173` 项全部通过；`npm run build:single` 生成 `48,710,468 bytes` 的 `demo/index.html`，外链脚本和样式均为 `0`。

## 2026-07-11 东岸宿舍群尺度修正

- 有效像素校正：东岸宿舍群图集有效宽度约占帧宽 `67%`；`displayWidth` 从 `260` 提高到 `400`，实际可见宽度约从 `175px` 提高到 `269px`。
- 同步尺度：宿舍碰撞从 `150×100` 调整到 `230×154`，位置改为 `(2222,1040)`，与田径场保持垂直间距。
- 空间调整：东侧水带上段半径从 `2` 格收窄到 `1` 格；东侧环路从 `x=2350` 外移到 `x=2380`，形成可容纳宿舍真实占地的陆岸宽度。
- 浏览器检查：`1280×720` 实际画面确认宿舍群完整位于陆地，与水域、田径场和道路均不相交，控制台错误为 `0`；临时截图检查后删除。
- 完整验证：35 个测试文件、`173` 项全部通过；单文件重建为 `48,710,432 bytes`，外链脚本和样式均为 `0`。
# 2026-07-11 内训笔记

- 新增 `7-55-游戏开发内训笔记.md`。
- 内容基于当前技术栈、章节开发报告、核心状态、存档、演出调度、Phaser 运行时和 35 个测试文件整理。
- 笔记覆盖技术栈职责、双运行时架构、三类玩法、7 项开发难点、质量保证和新成员上手顺序。
- 按内训要求补入知识树、知识图谱、学习收获、疑问与建议、问题闭环、延伸学习、思考题、入门/进阶进度和验收报告。
- 即时验证：`npm run typecheck` 通过；35 个测试文件、167 项测试全部通过；`npm run build:single` 通过，生成约 46MB 的 `demo/index.html`；文本规则检查通过。
- 新增 `XLab-内训学习报告-知识图谱与项目实践.md`，融合软件团队知识图谱、XLab Personal Blog 内训材料和《7:55》游戏开发实践。

## 2026-07-11 第二、三章谜题深度与演出解耦收口

- 调查链：折叠 18 条纯 `ac01` 后不再自动跳到 47 楼；玩家需核对 2、8、19、36、53 楼五位虚构角色的关联回复，`investigatedStoryFloors` 经 `SaveStore` 校验并持久化。
- 引用门槛：五条关联回复或过滤开关未满足时，`LibraryFinalsController.followCitation()` 返回 `false`；1 楼与 12 楼旧正文只通过 47 楼引用入口逐级展示。
- 路线推理：来源卡改为打乱顺序，玩家自行排列路线；演出 cue 只显示 `3/3`，路线失败按类别、结构、证据三层提示。
- 十大与口令：六条文字讨论和一张 `bd` 配图混排，只有路线、附件、规则三条来源闭合回复有效；口令改为三段输入、错误段标红和三级提示。
- 剧情帖编辑：剧情帖文案覆盖保存到独立 `seven-fifty-five.cc98-quest-post-overrides.v1`，普通帖子存储和谜题校验配置保持分离。
- 演出架构：新增 `PresentationDirector`、`PresentationLayer` 与运行时快照；动画和 `AudioDirector` 独立消费稳定 `presentation_cue`，均不写入关卡进度。
- 动画：P16 补齐入场、道路、换道、近失、碰撞、里程和结算演出；P17 补齐道路展开、节点、标题、统计和按钮入场，并修复移动端底部越界。
- 音频：更新过滤完成旁白；图书馆音频脚本的 `--verify-only` 现在只做 MP3、时长、响度和旁白哈希校验，运行结果 `generated: []` 且不改写清单。
- 浏览器验收：逻辑 `430×930` 框为 `430×930`；`390×844` 下框为 `354×765.63`，比例均为 `0.4623656`。CC98 路线、十大、口令、P16、P17 无横向页面滚动，控制台 warning/error 为 0。
- 最终验证：`npm run typecheck` 通过；35 个测试文件、168 项全部通过且无 React/media warning；两套音频 `--verify-only` 通过；`npm run build:single` 生成约 `48.7 MB` 的 `demo/index.html`，外链脚本和样式为 0。

## 2026-07-11 紫金港统一客观比例尺与视野密度

- 比例尺契约：新增 `visualWidth` 作为建筑在世界坐标中的可见宽度；图集素材的 `displayWidth` 根据每帧透明像素边界自动换算，删除以完整 `512×512` 帧宽直接衡量建筑的旧口径。
- 模型单源：宿舍、教学楼、服务楼、体育场地、温室、车棚和终端各自只保留一组 `visualWidth / collision / scaleClass` 模型；同一素材的重复实例只允许改变坐标。
- 尺度分层：地标 `320-490`、校园楼组 `230-270`、服务建筑 `155-190`、体育场地 `390-430`、工具建筑 `90-150` 世界像素；当前宿舍统一为 `260`，教学楼 `240`，服务楼 `175`，体育场地 `410`。
- 布局整理：西侧宿舍移到道路净空内；删除错误小尺寸掩盖下与求是大讲堂、道路相交的旧实例，在西区两个道路分块补入同尺度服务楼。
- 生成约束：地图写出前验证尺度区间、可见宽度与占地宽度一致、重复模型尺寸一致、水域净空、结构互斥和可见占地与机动车道净空。
- 镜头：桌面默认缩放从 `0.875` 调为 `1.0`，减少首屏空草地占比；缩小按钮和滚轮仍可回到 `0.875 / 0.75 / 0.625`。
- 浏览器检查：`1280×720` 检查南门、西区、启真湖、东区和东南区；`1100×800` 画布保持 `1100×618.75` 等比显示。缩小和拖拽状态依次为 `1.0 → 0.875 → manual`，控制台错误为 `0`。
- 定向验证：地图生成命令实际执行通过；`ZijingangTilemap.test.ts` 共 `10` 项通过，覆盖统一可见尺度、重复模型、水域、道路、桥梁和结构占地。
- 最终验证：`npm run typecheck` 通过；35 个测试文件、`174` 项全部通过；`npm run build:single` 生成约 `48.7 MB` 的 `demo/index.html`。

## 2026-07-11 签到结算到校园 RPG 的章节衔接

- 章节定位：原 P12 从“第一章结局”调整为“序章结算”；保留现实寝室画面，将“重新开始”改为“进入下一章”。
- 状态门槛：`ActOneBootstrapController.beginAfterCheckin()` 只接受 `checkinDone=true`，失败时发送 `act1_entry_rejected`，成功时进入 `campus_bootstrap` 并发送 `act1_started`。
- 状态延续：删除 P12 对 `createInitialGameState()` 的调用；`0798`、已取得物品、签到状态和持久存档均保留，RPG 从 `identity_required` 冻结角色阶段开始。
- 叙事衔接：结算页显示“序章·完 / 7:55 / 签到成功。你还在床上。”；进入后首个目标为打开手机并在浙大钉完成身份登录。
- 项目约束：`CLAUDE.md` 新增章节完成禁止默认重置全局状态的规则；新游戏重置仅保留给显式新游戏入口。
- 定向验证：控制器与 P12 组件共 `7` 项测试通过，`npm run typecheck` 通过。
- 浏览器验证：`1280×720` 点击结算按钮后切换到横屏 RPG；`390×844` 结算页完整显示，进入后显示横屏提示。两种视口中控制台错误均为 `0`。
- 最终验证：`npm run typecheck` 通过；36 个测试文件、`177` 项全部通过；`npm run build:single` 生成 `48,711,634 bytes` 的 `demo/index.html`，外链脚本和样式均为 `0`，构建中不存在旧“第一章完”重启文案。

## 2026-07-11 南大门正视立面与道路对齐

- 视觉资产：使用 GPT Image 将南大门重绘为正对屏幕的九拱水平立面，求是鹰保持为右侧独立构件；原始参考为 `1907×825`，色键处理后的透明运行资产为 `1660×251`。
- 色键处理：`process-zijingang-landmarks.mjs` 为南门单独使用 `20%` fuzz，移除生成图洋红背景，同时保留门柱、拱券和鹰像边缘细节。
- 地图对齐：南门保持 `480` 世界像素可见宽度、约 `73` 世界像素高度，基线位于 `y=1490`，沿 `y=1550` 南侧道路水平展开；碰撞区同步改为 `450×56`。
- 字幕净空：“南大门”名称移到门体上方，避免与出生点 `(700,1530)` 的人物和南侧道路重叠。
- 约束测试：新增正视比例、零旋转、门体高度和道路间距断言；`ZijingangTilemap` 与 `ZijingangWorldModel` 共 `15` 项定向测试通过。
- 浏览器检查：`1280×720` 实际进入“浙大钉 → 校园地图”，确认门体正视、沿道路水平延伸、求是鹰独立可见、透明边缘无洋红残留，控制台错误为 `0`。
- 最终验证：`npm run typecheck` 通过；36 个测试文件、`178` 项全部通过；`npm run build:single` 生成 `48,332,107 bytes` 的 `demo/index.html`，外链脚本、样式和远程资源均为 `0`。

## 2026-07-12 紫金港分区绿化与移动谜题契约收口

- 绿化分层：环境图集使用独立道路树阵、密林和湖岸垂柳素材；地图现有 11 组道路树阵、9 组成片林地和 6 组湖岸垂柳，覆盖北区、西区、东区、大草坪边缘和启真湖两岸。
- 湖岸净空：六组垂柳缩到 `150-160px` 可见宽度并分段放置，避开三座桥面、纵向湖岸道路和建筑入口；大草坪与南门前继续保留人物行走空间。
- 分布约束：地图测试新增四象限绿化密度断言，每个象限至少 5 组结构化植被，防止后续把树木集中到单一区域后重新出现大片无功能草地。
- 流程契约：清理旧版“登录、电话、免费按键、跑四区”控制器测试，改为验证身份命名、体艺自动行走、三角形与竖线合成、校园卡余额移位、CC98 购买手柄、首次手动移动与宿舍出口的正式流程。
- 浏览器检查：`1280×720` 下以 `1.0` 默认镜头检查南门，以 `0.625` 镜头检查四个地图象限；树阵、林地、垂柳、地标、道路和桥梁保持独立，镜头拖动正常，console/page error 为 `0`。
- 自动验证：`npm run typecheck` 通过；39 个测试文件、187 项全部通过；`npm run build:single` 生成 `demo/index.html`，构建输出为 `47,855.13 kB`。
- 单文件检查：Chromium 直接打开 `file://.../demo/index.html`，首屏正常，手机壳保持 `430×930` 等比缩放，横向溢出为 `0`，外链脚本和外链样式均为 `0`，warning/error 为 `0`。

## 2026-07-12 东区主路、田径场与温室调整

- 道路贯通：删除 `east_north_link_a / east_north_link_b` 两段断路，改为 `east_north_link` 单一折线，从 `(1350,500)` 连续延伸到 `(2380,500)`；体育馆入口保持在 `(2050,500)` 接入主路。全图审计同时删除两条压入水域的重复湖岸机动车道，让启真湖源从北环路下方开始，并在东区中路增加 `160px` 小桥。
- 田径场位移：运动场从 `(2120,810)` 调整到 `(2040,855)`，完成向左 `80px`、向下 `45px` 的移动。
- 东岸腾挪：基础图书馆从 `x=1720` 收拢到 `x=1630`，入口步道和交互区同步；东岸宿舍群移到 `(2260,1095)`，顶视占地高度校正为 `230px`，三组结构保持净空。
- 温室放大：侧视温室 `visualWidth` 从 `90px` 提高到 `120px`，占地和碰撞仍避开东区道路、南侧水域与信息亭。
- 回归约束：新增东区北路连续性、旧分段不存在、体育馆入口接点、田径场位置、温室最小可见尺度和“机动车道过水必须有桥”断言；地图与世界模型定向测试 `21/21` 通过。
- 最终验证：`npm run typecheck` 通过；39 个测试文件、190 项全部通过；开发预览与 `file://` 单文件均在默认 `1.0×` 镜头检查，console/page error 为 `0`。
- 单文件：`npm run build:single` 成功生成 `demo/index.html`，构建输出为 `52,298.28 kB`，外链脚本和外链样式为 `0`。

## 2026-07-12 第二章 V2「022 的占座书包」完整实现

- 双真源：`chapter-2-library-story.md` 管理剧情，`chapter-2-library-development-spec.md` 管理规则与验收；`chapter-2-library-finals-development-report.md` 已按真实代码重写为 V2.0。
- RPG 图书馆：新增 `1500×900` 基础图书馆内部世界、入口记录、信息台、失物登记机、检索终端、打印机、文学书架、二楼南区座位和 `022` 占座书包；Phaser 继续使用 `960×540` 逻辑画布。
- 场景往返：新增 `library_entrance / library_front_desk / library_shelf_755 / library_seat_022` 命名检查点；手机与 RPG 往返后恢复最近位置。
- 道具拖放：新增 RPG 道具栏与 DOM 指针到 Phaser 逻辑坐标换算；索书号、识别报告、右移箭头和 PASS 各自只接受对应目标，右移箭头使用后保留。
- 馆藏检索：浙大钉图书馆新增馆藏页；搜索“三分钟离座法”后同时显示用户提供的五张封面，正确结果为《三分钟离座法及其例外》，四张混淆项只显示局部错误反馈，不推进状态。
- 证据加工：照片 `IMG_0755.JPG` 在亮度不高于 `20%` 时显示标签并生成识别报告；失物登记机盖章生成书包非本人证明；桌面夹缝产出 `022` 小票；体艺补录仅接受 `7 / 47 / 3`。
- CC98：调查帖缩为 `23` 楼，保留 `5` 条可选 `ac01`；四项证据上传完成后，只有 `A / C / E` 三条回复有效，排名按 `04 → 03 → 02 → 01` 推进。
- 恢复申请：排名 `01` 后开放图书馆恢复申请；提交三项材料生成 `seatReleasePass`，PASS 只在 RPG 对 `022` 书包生效，手机页不直接恢复座位。
- 章节出口：书包转移到失物招领后玩家坐上 `022`，逐句完成数据驱动对话，任务更新为 `chapter_three_book_hunt`；第二章完成不自动解锁求是潮骑行。
- 内容维护：CC98 帖子、五本馆藏文字、bd 选项、14 条旁白和 022 对话统一收口到 `library-finals.content.json`，封面组件只保留 cover key 映射。
- 演出架构：领域事件经 `PresentationDirector` 转成稳定 `presentation_cue`；动画与 `AudioDirector` 独立消费，均不写入关卡状态。
- 音频：MiniMax CLI 生成 14 条中文旁白、5 段 24 秒阶段配乐和 16 个独立音效，共 `35` 个 V2 MP3；删除 `33` 个无引用 V1 音频；`--verify-only` 全部通过。
- 存档：升级为 V2 envelope，保存完整图书馆、证据、bd、PASS、RPG 检查点和第三章任务状态；旧中间存档重置到可继续入口，旧完成存档迁移到 `friend_contacted`。
- 验证：`npm run typecheck` 通过；40 个测试文件、`170` 项全部通过；馆藏页新增五封面、四混淆项和唯一正确结果测试。
- 单文件：`npm run build:single` 生成 `65,472,222 bytes` 的 `demo/index.html`；五张馆藏封面与 14 条 V2 旁白均已核对为内嵌数据，外链脚本、外链样式和外部资源标签为 `0`。
- 人工验收：开发服务器保留在 `http://127.0.0.1:5173/`，馆藏直达入口为 `?scene=zjuding&zjudingPage=library_catalog&libraryFinalsPhase=evidence_gathering`；最终视觉与操作手感由人工确认。

## 2026-07-13 第二章 V2 验收与单文件优化

- 手机视觉：馆藏、恢复申请、CC98、体艺和照片新增独立 V2 样式；`430×930` 真实 Chromium 下页面 `scrollWidth` 均不超过容器宽度，馆藏封面固定槽位、长列表纵向滚动，物品栏默认位置下移并继续吸附左侧上下拖动。
- 谜题信息：体艺提交前只展示入馆记录、CC98 公示和旧版规则三类来源，三档失败提示不输出 `7 / 47 / 3`；照片页不再直接说明亮度阈值；验证成功后才显示精确参数。
- CC98 数据：调查帖、23 楼回复、5 条可选 `ac01`、证据槽和 `bd` 选项统一读取 `library-finals.content.json`；第 16 楼显示 `bd` 配图，该回复不参与通关门槛。
- RPG 生命周期：修复 React StrictMode 首次销毁场景残留 bridge 订阅的问题；校园、寝室和图书馆场景统一在 `shutdown` 与 `destroy` 清理订阅，稳定保持单 canvas，文本快照与图书馆 `1500×900` 画面一致。
- RPG 实机链：真实鼠标验证错误落点不消耗道具；索书号、识别报告、右移箭头和 PASS 均只接受对应目标；右移箭头保留，识别报告与 PASS 正确消耗；坐下后逐句完成 18 句对话并进入 `chapter_three_book_hunt`。
- 场景往返：在 `library_shelf_755` 从 RPG 打开手机，再经 `浙大钉 → 校园地图` 返回，人物坐标稳定恢复为 `(610, 330)`，检查点未丢失。
- 资源优化：五张馆藏封面生成 `420px` WebP 运行版，总体积约 `256 KiB`；单文件从 `65,472,222` 降至 `51,755,654 bytes`，减少约 `20.9%`，手机卡片尺寸下文字保持清晰。
- 自动验证：`npm run typecheck` 通过；42 个测试文件、177 项全部通过；真实 Chromium 手机页和 RPG 操作 console/page error 均为 `0`。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 的 SHA-256 为 `5b21de72df935f8c9a226c8f3df5c88078c0100578c8a0bea54c34dc569cee2e`，外链脚本、样式和媒体均为 `0`；`file://` 在 `430×930` 直接打开正常且无横向溢出。

## 2026-07-13 细粒度开发者通道与 CC98 回复扩充

- 开发者通道：新增按第一、二、三章分组的 19 个玩法节点，覆盖签到码、系统红圈、寝室物品栏、移动谜题、图书馆证据、十大、恢复申请、PASS、022 对话、求是潮 377/566 米和结算。
- 状态种子：每个入口同时写入场景、运行模式、任务阶段、道具、图书馆证据和检查点；跳转前保存进入前状态，可在面板一键恢复。
- 直达契约：支持 `?dev=1` 打开面板、`?devCheckpoint=<id>` 直达节点和 `Ctrl+Shift+D` 切换面板；Vite 与单文件共用实现。
- 第三章：`c3-congestion` 与 `c3-sprint` 将 Phaser 模拟距离分别初始化为 `377` 和 `566`，浏览器实测冲刺入口启动后显示 `613 / 755m`，确认并非从零开始。
- CC98：五个普通帖子各有六位虚构用户的主题化回复；六个头像由独立 CSS 像素构造；`bd` 配图仅放在图书馆临时离座帖的相关回复。
- 物品栏：第一章获得首个道具后立即显示；第二章系统要求寻找物品栏期间隐藏；寝室宝箱找回后恢复。
- 视觉检查：`1200×900` 下开发面板与 `430×930` 手机壳独立布局，面板可滚动；CC98 图书馆帖实际显示六个不同头像与一张 `bd` 配图。
- 最终验证：44 个测试文件、181 项测试全部通过；`npm run build:single` 生成 `51,752.17 kB` 的 `demo/index.html`，SHA-256 为 `fbaa8399b23157234637bf2f824befa702d42a01ffe16e79d8e7ef56d4add58a`。

## 2026-07-13 旧存档物品栏入口修复

- 根因：手机背包同时依赖已有道具和 `inventoryRecovered`；部分旧存档已有道具，但迁移后该字段仍为 `false`，因此左侧按钮未渲染。
- 修复：背包显示改为依据真实道具数量；只在朋友追问、系统对峙和寻找寝室宝箱三个明确阶段隐藏。
- 浏览器检查：模拟 `phase=complete / inventoryRecovered=false / reverseGear=true` 的旧存档，左侧背包按钮边界为 `38×63px`，点击后 `aria-expanded=true`，物品栏显示 1 个道具。

## 2026-07-13 存档恢复与控制中心重置

- 自动存档：继续保存完整剧情状态，写入前关闭控制中心、收起物品栏并清除悬空道具选择，防止重载后恢复到临时操作态。
- 双槽恢复：主存档写入前保留上一份有效 JSON；主存档损坏时自动读取备份并修复主槽。
- 开发隔离：开发者 checkpoint 激活期间不再写入正式 `localStorage`，退出或恢复后正式存档保持原进度。
- 控制中心：新增“游戏进度”区，提供“立即保存”和“重置剧情进度”；重置需二次确认，清除章节、道具、谜题与骑行进度，保留玩家编辑的 CC98 帖子。
- 浏览器检查：手动保存后重载保持 `phone_home` 和 `reverseGear`；确认重置后重载回到 `alarm` 且道具为空。
- 小屏检查：`390×844` 下手机框 `354×765.63`，控制中心 `349.06px` 宽，页面 `scrollWidth=390`，确认区无横向溢出。
- 单文件验收：直接打开 `demo/index.html` 的 `file://` 页面，手动保存后重载仍保持 `phone_home` 与 `reverseGear`；重置后再次重载回到 `alarm` 且道具为空。
- 最终验证：45 个测试文件、187 项测试全部通过；`npm run build:single` 成功，生成 `51,755.06 kB` 的 `demo/index.html`，SHA-256 为 `31908d26d1c66dbcafa8e796096a94c2f914ffede77a19016ac962a5a8403568`。
## 2026-07-13 当前版本游戏攻略与流程核对

- 以 `src/` 状态机、控制器门槛、场景按钮和开发者断点为准，新增 `docs/gameplay-debug-walkthrough.md`。
- 攻略覆盖第一章 `0798`、序章旁白捕获、第二章移动前置、RPG 图书馆 022 四证据链、CC98 A/C/E bd、PASS 清退和第三章 755 骑行。
- 单独记录物品栏、控制中心、RPG 道具拖拽、存档重置、`render_game_to_text()` 状态检查和 19 个开发者断点。
- 源码核对发现正式流程缺口：`complete022Dialogue()` 会进入 `friend_contacted`，但没有同步设置 `bikeArcade.unlocked = true`；攻略将第三章标为当前需通过开发者通道进入，避免误判为玩家操作问题。

## 2026-07-13 RPG 手机竖屏适配

- 问题：手机竖屏时 `rpg-rotate-hint` 以全屏层遮住 RPG，页面始终停在“请将设备横过来继续 RPG”。
- 修复：取消竖屏阻塞层；保留 Phaser 画布 16:9 等比区域；任务栏、系统操作、道具区和触摸方向键分区布局；加入 safe-area 和 `touch-action` 约束。
- 尺寸验证：`375×812` 、`390×812` 、`430×812` 下 RPG 画布均保持 `16:9`，三种宽度 `scrollWidth` 均等于视口宽度，竖屏提示层为 `display:none`。
- 触摸验证：竖屏点击“向右”后图中人物坐标由 `1100` 移动到 `1148`；点击“打开手机”返回 `zjuding`，无浏览器报错。
- 单文件验证：重新生成 `demo/index.html`，直接以 `file://` 打开后在 `390×844` 竖屏视口下可加载 RPG，无横向溢出和控制台错误。
- 最终单文件：`npm run build:single` 通过，`demo/index.html` 大小为 `51,757.18 kB`，SHA-256 为 `718255d918a4ccdbd911223149b8a8c1003b442367f20640108780671ee849c3`。

## 2026-07-13 第二、三章英文配音与语境表演配置

- 英文范围：第二章系统同行前奏 `21` 条、图书馆 022 流程 `14` 条、第三章求是潮骑行 `3` 条，共 `38` 条；第一章和序章中文旁白继续使用原中文声线与文件。
- 声线连续性：第二、三章统一使用 MiniMax `speech-2.8-hd / English_Graceful_Lady / English`；角色跨章节保持同一音色。
- 语境表演：每条台词新增独立 `delivery`，按让步、催促、惊讶、行政确认、低声揭示、紧急指令和克制庆祝等语境调整标点停顿、`speed` 与 `pitch`；生成配置哈希包含 `delivery`，修改表演要求会使对应单句自动失效并重生成。
- 生成隔离：`act2_*` 读取第二章英文声线，其余 `act1_* / prologue_*` 继续读取第一章中文声线；图书馆生成器读取内容文件中的声线；求是潮生成器增加 `--voice-only`，不会连带重做配乐和音效。
- 网络恢复：第一、二章 MiniMax 生成器对超时和短暂网络错误执行最多三次退避重试；本轮图书馆生成出现一次网络失败，恢复后完整生成成功。
- 复现命令：新增 `npm run audio:chapters:english`；重复执行时三章均返回 `generated: []`，确认缓存与配置哈希生效。
- 音频验收：`38` 个文件均为可解码 MP3、`32 kHz`、单声道，来源清单统一为 `MiniMax speech-2.8-hd English_Graceful_Lady`；总时长 `270,859 ms`，单条时长范围 `1,162-15,738 ms`。
- 契约测试：新增 `ChapterEnglishVoice.generated.test.ts`，覆盖英文字符、逐句表演说明、声线一致性、第一章中文保留、文本哈希、MiniMax 来源、文件存在性、解码、采样率、声道与缓存命令。
- 项目验证：`npm run typecheck` 通过；`48` 个测试文件、`204` 项测试全部通过；`npm run build:single` 生成 `53,913,107 bytes` 的 `demo/index.html`，SHA-256 为 `2cc58f09704d2908af881a498e96994a01b214a668442ab6c27e6ae964424729`，外部资源为 `0`。

## 2026-07-14 第一章校园卡依赖修复与序章英文男声

- 第一章流程：签到码散落后，主页出现可点击的“浙大钉：查看寝室定位”；玩家依次进入 `浙大钉 → 校园地图 → 寝室`，打开宝箱获得校园卡，再从 `¥0.06` 的黄色中间 `0` 取得第一位签到码。
- 顺序门槛：散码前拒绝寝室 RPG 入口；散码后开放并持久记录 `dormHubUnlocked`。校园卡页面在未持卡时拒绝收集黄色 `0`。
- 第二章继承：校园卡和物品栏从第一章持续保留；系统红圈识别已有校园卡，完成一次连续对话后直接进入“找到移动的办法”。`inventory_required` 仅用于旧存档兼容。
- 存档：升级为 V4；旧存档只要已有校园卡、第一位 `0` 或 `cardZeroTaken`，就自动补齐 `campusCard / inventoryRecovered`，并把旧 `inventory_required` 推进到 `system_return_required`。
- 开发者通道：新增 `c1-dorm-card`；旧 `c2-inventory` 映射到第一章宝箱，旧 `c2-system-return` 映射到第二章系统红圈；第二章检查点统一继承第一章已完成状态。
- 文档约束：`CLAUDE.md` 和 `docs/gameplay-debug-walkthrough.md` 已同步为第一章取卡的唯一正式流程。
- 序章旁白：`prologue_narrator_intro` 改为英文男性叙述声线 `English_expressive_narrator`，按四段分别设置更低音高、停顿与加速离场语气；生成文件时长 `15.105281s`、`32 kHz`、单声道 MP3。
- 验证：`npm run typecheck` 通过；`48` 个测试文件、`213` 项测试全部通过；`npm run build:single` 成功。`demo/index.html` 为 `53,985,019 bytes`，SHA-256 为 `81aee20545ab55b7bdc9087c222ee9d0ff1896569348fa1ffc20c1d2e47980a9`，脚本外链为 `0`，唯一 `link` 为内嵌 `data:` favicon。
- 浏览器核对：内置浏览器拒绝带开发检查点参数的本地 `file://` 跳转，本轮未记录人工视觉通过结论；单文件已留在原路径供实机继续验收。

## 2026-07-14 全游戏英文配音与讽刺语气统一

- 全局规则：所有实际播放的配音统一使用英文；中文 UI 和中文提示字幕继续保留。`CLAUDE.md` 已把语言、角色连续性和两套播放器共同验收写成长期约束。
- 旧场景覆盖：第一章 `playVo` 的 9 句旧配音新增独立英文朗读文本和语境表演说明，MiniMax 重新生成原兼容文件名 `all_shadow_vo_002-010.mp3`，旧场景无需改调用方式。
- 第一章事件音频：7 条 `act1_*` 台词改为英文女系统声线，语气集中在行政式嘲讽、克制烦躁和被迫处理问题的无奈；第二、三章继续使用同一英文女系统声线。
- 男旁白：序章开场改写为更尖锐的英式克制嘲讽，结尾明确表达不愿继续收拾问题；被抓住和讨价还价两句同步改为英文男声，并通过更低音高、停顿和加速强化失态与不耐烦。
- 生成管线：`generate-act-one-audio.mjs --voice-only` 现在同时生成事件语音和旧场景语音；文本、声线、语言、语气说明、速度与音高共同参与缓存哈希。
- 资产结果：本轮重新生成 19 个受影响的 MiniMax 文件；所有文件均为可解码 MP3、`32 kHz`、单声道，生成配置和清单中不再含中文声线。
- 契约测试：`ChapterEnglishVoice.generated.test.ts` 升级为全游戏英文配音测试，覆盖第一章、序章、第二章前奏、图书馆、第三章和旧播放器，同时继续校验中文旧场景字幕。
- 字幕解耦：`AudioDirector` 优先读取可选 `subtitleZh`；第一章事件继续显示原中文字幕，MiniMax 朗读和文本哈希只使用英文 `text`。
- 缓存验证：`npm run audio:chapters:english` 二次执行后三个生成器均返回 `generated: []`，说明英文语音资产与当前文本、声线和表演配置完全对应。
- 最终验证：`npm run typecheck` 通过；48 个测试文件、214 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `53,842,117 bytes`，SHA-256 为 `e90e95c34e6d17ed9220dbf6039b92cb3b8aaf31b1ac4eb5b8c41aefc5d51fda`；外链脚本、样式和媒体均为 `0`。

## 2026-07-14 宿舍据点场景扩充

- 场景定位：标题从通用“宿舍据点”改为“蓝田六舍 · W12”，继续作为第一章校园卡宝箱和第二章移动谜题的共用寝室。
- 空间重构：Phaser 房间从 `620×404` 扩展到 `760×404`，减少桌面端左右黑边，同时保留中央移动通道和底部门口。
- 寝室内容：新增双层床、床梯与床帘、三联书桌、椅子、衣柜、鞋架、公共桌、雨天窗户、墙面题字、台灯、盆栽、风扇、地板拼缝和门口地毯。
- 环境反馈：窗户和墙面题字可点击查看短反馈；风扇持续旋转，台灯光晕缓慢变化。上述演出不写关卡状态。
- 宝箱修复：宝箱移动到公共桌中央，并增加独立透明 Pointer 命中层，继续兼容鼠标、触摸和缩放后的画布坐标。
- 实际交互：关闭开发面板后点击宝箱成功写入 `inventoryRecovered=true` 并获得 `campusCard`；`c2-dorm-exit` 在 `390×844` 触控向下后正常进入 `campus_bootstrap`。
- 移动端检查：`390×844` 页面 `scrollWidth=390`，无横向溢出；寝室、任务栏、道具栏和触控方向键没有重叠，控制台与页面错误均为 `0`。
- 最终验证：`npm run typecheck` 通过；48 个测试文件、214 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `53,847,256 bytes`，SHA-256 为 `6753e3c428e66e6c5fd3ecda0acc4b8a154706663b1c6f5c0c5aae11e39e8ede`。

## 2026-07-15 CC98 灌水回帖与全局中文字幕

- 普通 CC98：五个帖子共 30 条回帖全部改写；保留六个虚构账号和各帖主题，语气调整为前排占楼、接梗、跑题、报数、蹲资料和校园日常吐槽。
- 图书馆调查帖：五条可选 `ac01`、四条填充回复以及错误 B/D `bd` 选项改为与 022 占座语境相关的轻松灌水内容；A/C/E 证据门槛保持不变。
- 旧内容迁移：普通帖标题、正文等玩家编辑内容继续保留；运行时统一用当前版本的作者回帖，旧存档不会继续显示过期回复。
- 字幕语言：序章、第一章、第二章前奏、图书馆和第三章所有实际配音继续使用英文；所有屏幕字幕统一读取中文文本。
- 字幕显示：继续复用 `.toast-layer / .px-toast`，保持底部 `18px`、左右 `12px`、`14px` 字号、`1.45` 行高和音频时长加 `450ms` 的显示规则。
- 兼容播放器：`VoicePlayer` 默认开启中文字幕；此前未显式传入字幕参数的起床旁白、起床闪字和微信散码两句也会显示中文气泡。
- 定向验证：论坛语气、旧回帖迁移、字幕语言、字幕路由、音频文件和显示契约共 6 个测试文件、27 项全部通过；`npm run typecheck` 通过。
- 全量测试：50 个测试文件、219 项全部通过；项目规则新增非小改动必须执行完整测试组、总量保持至少 200 项且不得用重复断言凑数。
- 浏览器检查：`430×930` 缩放视口下，图书馆调查帖的新 `ac01`、填充楼层和 B/D 干扰 `bd` 均正常显示；求是潮英文配音显示中文底部字幕，页面横向溢出为 `0`。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `53,850,803 bytes`，SHA-256 为 `8e2607b0264eefc5fc49e40fed5a4c70ef3f2fe333bf45b6b2bb6b523002d740`，外部资源为 `0`。

## 2026-07-15 馆藏检索、字幕单一归属与旁白声线统一

- 馆藏检索：检索界面与剧情证据门槛分离；简称“三分钟”显示 5 本相似馆藏，“离席”过滤为 1 本，无结果输入显示明确空状态；完整题名和书名号标点可正常推进线索。
- 剧情门槛：未读取 CC98 题名提示时仍可使用馆藏搜索，但选择正确书籍不会提前发放 `755` 线索。
- 字幕归属：`AudioDirector` 增加 `subtitleSurface`；序章旁白和浙大钉系统对话使用场景内中文字幕，不再同时生成全局 Toast。真实页面核对为场景字幕 `1`、全局字幕 `0`。
- 旁白声线：全部旁白继续使用 `English_expressive_narrator`，基础音调统一为 `-4`；只保留语速、停顿和重音的语境变化。受影响的 3 段英文男声已重新生成，第二次执行生成列表为空。
- CC98 顶栏：操作区改为两等分，按钮文字从“编/存”改为完整“编辑/保存”；真实页面中按钮 `clientWidth` 与 `scrollWidth` 均为 `66px`，无裁切。
- 长期规则：`CLAUDE.md` 新增字幕唯一归属、功能检索与剧情门槛分离、旁白固定声线与基础音调约束。
- 最终验证：`npm run typecheck` 通过；50 个测试文件、`226` 项全部通过；`430×930` 目标手机壳下馆藏检索、CC98 顶栏和序章字幕均无横向溢出。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `53,832,350 bytes`，SHA-256 为 `e9a975b0aaee30d7c6381be0d7fb1b459bba47e2efdf88a72b7d6773e4836065`，DOM 外部资源为 `0`。

## 2026-07-15 浙大体艺锻炼按钮命中修复

- 交互归属：绿色“等待开始锻炼 / 锻炼进行中”区域改为只读 `status` 字幕，设置 `pointer-events: none`，不再启动锻炼或返回寝室。
- 素材按钮：按 `852×1846` 原图中蓝色按钮的像素边界，在 `430×930` 逻辑手机内建立 `65×752 / 290×54` 的独立透明热点；可见外观继续使用原始页面素材。
- 状态反馈：人物已命名时显示“参加者已确认，可以开始课外锻炼”；点击蓝色按钮后更新为“锻炼进行中 / 小人正在寝室里来回走动”。
- 单一反馈：首次启动删除场景内重复 Toast，只保留 `act2_exercise_started` 统一事件提供的一条中文字幕、英文配音和音效；再次点击才提示记录已经存在。
- 自动验证：新增“字幕点击无效”“蓝色按钮启动”“运行状态只读”测试；全量 `50` 个测试文件、`228` 项测试通过，`npm run typecheck` 通过。
- 浏览器验证：字幕中心实际命中底层 `IMG.app-bg`；蓝色热点点击后状态正确切换，首次操作 Toast 数量为 `1`。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `53,832,827 bytes`，SHA-256 为 `62796acef2ca2c3c5e873eef6e6a02e1b3689902677c0c90533600e4df494ae8`，DOM 外部资源为 `0`。

## 2026-07-15 手机导航、RPG 提示与第二章线索可读性

- RPG 操作：桌面移动提示统一为 `WASD`，交互键统一为 `Space`；触控交互按钮显示“空格”。图书馆前台的馆藏终端、入馆记录和闸机标签已分开布置。
- 部门黄页：新增校园卡读卡区；拖入校园卡后自动填写姓名和学号，拨号仍由玩家确认。三档提示从“确认身份”逐步收窄到校园卡。
- 微信导师头像：补充卡扣、胶缝和高光动画；连续检查会依次提示卡住、需要润滑和天气水滴，只有拖入天气水滴才释放竖线。
- CC98 内容：删除夸张的配图称呼，保留 `bd` 配图和轻松灌水语气；帖子详情右上关闭按钮和编辑弹层关闭按钮均可实际操作。
- 统一导航：新增 `PhoneNavButton`，根页面使用 `exit`、应用子页使用 `back`、覆盖层使用 `close`；微信、签到、天气、校园卡、体艺、盆栽、照片、CC98、浙大钉和求是潮均接入同一语义。
- 返回链路：签到页不再依赖历史栈，固定返回 `浙大钉 → 学在浙大`；图书馆恢复页返回图书馆首页；CC98 帖子关闭后回到热门列表。
- 遮挡修复：任务线索条改为纯展示，不再获取焦点或接收指针；位置移入状态栏中部，左上 `44×44` 导航区域完整保留。
- 浏览器核对：图书馆恢复页与首页左上按钮可见且可点击；CC98 帖子关闭后详情节点为 `0`、帖子列表保持可见；`390×844` 视口无标题或按钮重叠。全新页面控制台 error 为 `0`。
- 策划候选：微信“遇水显字 / 校园卡压泡校时 / 撤回回音”、意见箱“已阅未办 / 绕行建议征集”、失物招领“错分柜申诉 / 三箭头转运单”仅记录为后续候选，本轮未接入剧情状态。
- 最终验证：`npm run typecheck` 通过；`53` 个测试文件、`245` 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `53,840,250 bytes`，SHA-256 为 `cca0e8a2f61781458de9d98519b360968b8e6341a4dca39bb2b9c739cfcdc0c6`，DOM 外部资源为 `0`。

## 2026-07-15 第二章图书馆叙事节奏与界面精修

- 剧情节奏：入口任务拆为“读取入馆记录 → 前往 022”；记录先揭示 `022 存在未闭合会话`，到达座位后播放信号波纹和 `LINK LOST`，再进入占座书包调查。
- 线索披露：调查帖开启后先要求确认旧版规则；取得索书号并回收旧规则后，才展示三项恢复证明；证明齐全后再提示整理 CC98 公示材料。原有证据链、阶段枚举和存档字段保持兼容。
- RPG 场景：重绘图书馆三区地面、窗户、照明、入口、前台人物、馆藏终端、打印区、书架和阅览桌细节；对话框、反馈条和顶部任务栏降低面积与视觉权重。
- 交互焦点：普通探索只显示距离玩家最近的标记；选择道具时只显示匹配的投放目标。新增纯函数和三项测试覆盖最近目标、匹配投放及无匹配回退。
- 馆藏检索：搜索框和搜索按钮独占第一行，检索字段与馆藏范围移到第二行；高级检索改为题名匹配、索书号分类、馆藏地点；结果标题显示条目数量，原完整题名与普通关键词检索均保留。
- 恢复申请：三份证明增加来源、状态和下一步说明，并增加总体进度条；022 选座页在章节进行中切换为调查状态，提供统一“返回现场”入口。
- 体艺字段：`47` 明确显示为“公示编号 47 号”，避免和 23 层调查帖的楼层总数混淆。
- 文档同步：`docs/chapter-2-library-story.md` 与 `docs/chapter-2-library-development-spec.md` 已记录渐进披露、信号演出、交互标记和检索页结构规则。
- 自动验证：`npm run typecheck` 通过；`53` 个测试文件、`256` 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `53,851,377 bytes`，SHA-256 为 `d182e11251b06ed6e547d66d9ce747fe3669b705b5887f37f3039d8f7bfb9e4d`；仅保留内嵌 `data:` favicon，外链脚本和样式为 `0`。
- 视觉验收：本轮内置浏览器拒绝对本地 `file://` 页面执行页面快照，因此没有记录人工视觉通过结论；交付文件已更新，保留给实机直接核对。

## 2026-07-15 寝室美术、人物比例与 RPG 输入修复

- 寝室地图：使用 GPT Image 生成与参考寝室结构一致的横版 RPG 像素场景；左侧双层床、右侧连续书桌与衣柜、后墙房门和中央通道均保留，运行素材为 `src/assets/rpg/interiors/dorm_hub.png`。
- 校园卡位置：移除公共桌和宝箱；校园卡由 Phaser 单独渲染在右侧个人书桌上，使用 `38×23` 可见尺寸和 `70×52` 透明命中区，拾取后从场景消失并写入第一章共享状态。
- 人物重绘：使用 GPT Image 生成学生角色表，清理为六张透明 `48×64` 方向帧；寝室按上下左右方向和 `130ms` 双帧节奏播放行走动画，左右方向共用镜像帧。
- 比例修正：共享 `RpgPlayerTextures` 将人物显示缩放统一为 `0.625`，实际画面约 `30×40`；碰撞盒同步改为 `24×18` 并下移到脚部，姓名标签同步缩小。寝室、校园和图书馆共用同一配置。
- 输入恢复：开发面板关闭时统一恢复 Phaser 全局输入、当前场景输入和键盘输入，并在下一动画帧复查；面板遮罩期间继续隔离地图点击，关闭面板不会误触下层场景。
- 移动端：`375×667`、`390×844`、`430×930` 和 `1200×900` 下 RPG 画布保持 `16:9`；十件道具固定五列两行，全部可见，最小触控目标 `52px`，无横向溢出。
- 真实交互：浏览器中拾取右侧书桌校园卡后 `campusCard=true`、`inventoryRecovered=true`；关闭开发面板后长按 `Space` 可读取入馆记录；右侧行走帧、校园卡拖放和图书馆馆藏检索均已实际触发。
- 音频容错：MiniMax CLI 对两条新场景音乐连续三次返回网络错误；运行时间线暂时映射到现有有效配乐，缺失音频不会阻断状态推进，后续可独立替换场景音乐文件。
- 自动验证：`npm run typecheck` 通过；`58` 个测试文件、`289` 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `58,564,186 bytes`，SHA-256 为 `aa09473b59c053ca747f0ea57965d6cb1a0f37fe9a85228b2f46cd058ba09d96`，外部资源为 `0`。
- 离线验收：本机 Chrome 以 `file://` 直接打开第一章寝室检查点，加载一个 `960×540` Phaser 画布，在 `430px` 宽视口内等比显示为 `430×241.875`，页面与控制台错误均为 `0`。

## 2026-07-16 图书馆入口开门演出

- 门禁结构：在图书馆入口中央新增两扇独立玻璃门、顶部感应灯和两条闸机挡板；门体继续使用 Phaser 图形绘制，不改动背景素材。
- 交互顺序：首次进入时门禁保持关闭；玩家在闸机前读取入馆记录后，感应灯由红变绿，扫描线下移，玻璃门向两侧滑开，闸机挡板同步收起。
- 实际通行：关闭状态保留透明碰撞墙，人物向上移动会停在 `y=740.5`；记录读取且动画完成后碰撞关闭，人物可继续通过至 `y=652.5`。
- 再次接近：已取得入馆权限后，人物接近入口会自动开门；离开感应范围后门体自动闭合，剧情状态与视觉演出保持独立。
- 入口位置：`library_entrance` 出生点从闸机机身移动到左侧通道 `(715, 842)`；三根闸机和两侧固定玻璃增加碰撞，人物不能穿过设备。
- 调试状态：`render_game_to_text()` 新增 `rpgRuntime.entranceDoor`，输出 `closed / opening / open / closing` 和 `accessGranted`，便于后续检查动画与门禁状态。
- 视觉验收：真实 Chrome 分别检查关门、开门中和完全打开三帧；门板滑入两侧固定玻璃区，入口文字、人物和 HUD 未发生遮挡，控制台错误为 `0`。
- 自动验证：`npm run typecheck` 通过；`58` 个测试文件、`290` 项测试全部通过；入口模型新增未授权关闭、授权近距离开启和离开感应区关闭测试。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `58,568,994 bytes`，SHA-256 为 `6c9ac4a53199de66776b70100116269a5889997e8035b9492e5987669136c067`，外部资源为 `0`。
- 离线验收：`file://` 下入口由 `closed / false` 正确切换为 `open / true`；`960×540` 画布在 `430px` 宽视口中等比显示为 `430×241.875`，控制台错误为 `0`。

## 2026-07-16 图书馆像素碰撞重标

- 坐标单源：新增 `LIBRARY_STATIC_COLLISION_RECTS`，所有静态碰撞直接使用 `library_interior.png` 的 `1500×900` 源像素边界。
- 上部修复：补齐北侧墙体，将八组书架、展示架和阅览区分隔架从统一近似矩形改为独立像素边界。
- 全场细化：前台、馆藏终端、打印机、阅览桌、护栏、门厅玻璃和闸机均改为独立轮廓，原先覆盖整块地毯的粗糙碰撞已删除。
- 调试能力：开发环境可用 `?debugColliders=1` 显示黄色边界；`render_game_to_text()` 输出碰撞矩形，正式单文件不显示调试层。
- 真实操作：人物向上停在 `y=97.5`，不再进入窗框；在两列书架之间向右停在 `x=197.5`、向左停在 `x=173.5`，与书架像素边界及 `7.5px` 脚部半宽一致；离开墙体和通道正常，控制台错误为 `0`。
- 自动验证：`npm run typecheck` 通过；`58` 个测试文件、`296` 项测试全部通过，新增碰撞边界、实体采样、通道采样、地毯空地、门厅通道和出生点覆盖。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `58,571,472 bytes`，SHA-256 为 `4ceb38e424685c419925725571a9c3d5769977bd58f1403033c41e418aa75de3`，DOM 外部资源为 `0`。
- 离线验收：`file://` 直接打开后载入 `960×540` 画布，`1280×900` 视口中等比显示为 `1280×720`；人物向上正确停在目标书架边界 `y=226.5`，控制台错误为 `0`。

## 2026-07-16 物品详情简介与含蓄提示

- 字段统一：共享物品详情的第三项从“用途”改为“简介”，数据契约同步由 `usage` 改为 `intro`；手机物品栏与 RPG 道具栏继续复用同一份详情数据。
- 全量改写：21 件物品均获得独立简介，提示物品关系、可作用对象类别或缺失证据类型，不再直接写出拖放目标、提交位置和终局答案。
- 泄底清理：右移箭头、占座纸条、索书号、旧离座规定、物品识别报告、022 小票和清退 PASS 的标题短描述改为客观外观或来源信息，避免标题先于简介公布操作路线。
- 契约保护：新增“简介标签”“旧用途标签消失”“全部物品简介非空”“禁止精确解法短语”测试，后续新增物品仍需满足同一提示规则。
- 视觉验收：真实 Chrome 在 `390×844` 手机视口与 `1280×900` RPG 视口检查右移箭头详情；两种弹窗均显示“分类 / 来源 / 简介”，内容完整，无横向溢出或内部滚动。
- 自动验证：`npm run typecheck` 通过；`58` 个测试文件、`298` 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `58,572,093 bytes`，SHA-256 为 `8182cb93a0f410f8e87b5f286a9136d395267d33991aa272c6be406caedc71e3`。

## 2026-07-16 022 阅览区像素碰撞修复

- 粗框移除：删除覆盖西侧斜护栏和整条南侧边界的两个近似矩形，避免将可见地砖与真实入口一起设为空气墙。
- 像素重标：依据 `library_interior.png` 的 `1500×900` 源像素，将边界拆为西侧盆栽、六段斜护栏、两根入口立柱、横护栏、两个花箱、中柱和东侧盆栽共 `14` 个碰撞块。
- 入口恢复：保留两根立柱之间 `x=1002–1074` 的通行缺口；人物完整碰撞盒在中心与左右边缘采样均不命中静态碰撞。
- 阻挡验证：人物在 `x=1180` 直接向南撞击横护栏时停在 `y=507.7`；沿外侧移动到 `x=1038.7, y=606.3` 后可向上穿过入口并到达 `y=502.3`。
- 透明区域：斜护栏改为连续重叠的阶梯矩形，护栏内外的三角形地面保持可走；南侧地砖、阅览区地毯和入口金属门槛均未被额外覆盖。
- 测试覆盖：新增斜护栏实体与透明区、入口柱与人物宽度、横护栏与花箱、边缘盆栽四组像素采样测试。
- 自动验证：`npm run typecheck` 通过；`58` 个测试文件、`302` 项测试全部通过；`npm run build:single` 成功。
- 单文件交付：`demo/index.html` 为 `58,572,940 bytes`，SHA-256 为 `2eb21e7d3c154ead07691da66cdee73e842f54328e5915f989659836fb9cfdd1`；`file://` 载入后外部资源与控制台错误均为 `0`。

## 2026-07-16 RPG 人物全局尺寸统一

- 全局尺寸：共享 `RpgPlayerTextures` 将人物显示缩放从 `0.625` 调整为 `1.0`，六张 `48×64` 方向帧以完整尺寸显示；姓名标签偏移同步从 `34px` 调整为 `44px`。
- 碰撞保持：脚部碰撞的世界尺寸继续保持 `15×11.25`，并按完整帧重新计算为 `16.5 / 50.75` 的源像素偏移；人物放大不会缩窄宿舍、校园和图书馆通道。
- 单一配置：宿舍 `DormHubScene`、校园 `BootScene` 与图书馆 `LibraryInteriorScene` 全部通过 `configureRpgPlayerSprite` 应用人物尺寸；缺图回退纹理也统一生成 `48×64` 帧。
- 长期约束：`CLAUDE.md` 固定所有当前及未来可控 RPG 人物必须复用共享配置；新增测试扫描全部可控 RPG Scene，禁止场景自行设置人物缩放、显示尺寸或碰撞体。
- 自动验证：`npm run typecheck` 通过；人物资源定向测试 `10` 项通过；完整测试 `58` 个文件、`305` 项全部通过；`npm run build:single` 成功。
- 视觉验收：在 `1280×720` 真实浏览器画面分别检查 `c2-dorm-exit`、`c2-entrance-record` 和 `c2-library-gate`；人物与寝室家具、图书馆闸机及校园建筑比例正常，姓名标签未遮挡头部，浏览器错误为 `0`。
- 单文件交付：`demo/index.html` 为 `58,573,074 bytes`，SHA-256 为 `23c949953ff82f03c133d2c420cd5da77256cfa7a66e0e1ee87658a6cf65578f`，外链脚本、样式和 HTTP 资源均为 `0`。

## 2026-07-16 流程简化实施：状态单源与存档迁移

- 新增 `FeatureAccess`、`QuestViewModel`、`StoryLine`、纸质文档和道具用途类型；章节与功能权限统一由正式剧情事实派生。
- 新增 `selectFeatureAccess()`、`canEnterScene()`、`sanitizeZjudingPage()`；第一章直接路由无法进入 CC98、照片、天气和后续小游戏。
- 新增 `selectQuestViewModel()`；第一章、第二章移动、第二章图书馆和第三章均输出一个当前目标、数字进度、步骤状态、三档提示和推荐界面。
- 存档升级为 V5，保留 V2–V4 兼容；新增章节提示确认记录，并在加载时清理纸条、索书号、旧规则、右移箭头、三份证明和 PASS 的已失效实例。
- 定向验证：`npm run typecheck` 通过；核心权限、任务、路由、存档和重置共 `5` 个测试文件、`25` 项通过。

## 2026-07-16 流程简化、双屏、道具与语音完整交付

- 章节与权限：第一章继续沿用原有签到流程；第二章入口、离开寝室、照片调查、CC98 楼主上传、`bd`、022 恢复申请和第三章入口均由剧情事实统一派生。旧存档和直接路由会经过权限校正。
- 统一任务：手机、RPG 和桌面双屏共用 `QuestTaskBar`；任务抽屉显示单一当前目标、步骤状态、数字进度、三档渐进提示和相关界面导航，导航不会自动完成谜题。
- 界面精简：CC98、浙大钉和图书馆按阶段展示有效控件；无关入口改为不可聚焦、不可点击且无图标的静态 `xxx`。CC98 楼主上传与 `bd` 分阶段出现。
- 桌面双屏：横屏、精细指针且宽度至少 `1100px` 时，同时挂载手机与 RPG；两区读取同一状态，焦点决定键盘归属，任务栏、提示层和演出层各保留一个实例。移动端保持单屏切换。
- 道具系统：统一 `ITEM_CATALOG`；八类纸质道具支持展开阅读、键盘关闭和已提交材料回看。CC98 四槽及恢复申请三槽支持拖拽与点击选择，错误、重复和越阶段提交均不会消费或推进。
- 生命周期：纸条、索书号、旧规则、右移箭头、恢复证明和清退 PASS 按正式用途消费或转化；校园卡和手柄保留。V5 存档迁移会清理已经失效的旧道具。
- 语音职责：男旁白固定 `English_expressive_narrator / pitch -4`，女系统固定 `English_Graceful_Lady`；英文配音配中文字幕。玩家、022、操作反馈、任务提示和通关吐槽保持纯文字，文字时长按可见字符数限制在 `2400–6500ms`。
- 正式入口：生产单文件默认隐藏内部 `DEV` 检查点；仅开发环境、`?dev=1` 或明确的 `devCheckpoint` 参数可启用。干净存档打开时显示“早八闹钟 / 07:55 / 开始游戏”。
- 天气入口：第二章解锁天气后，手机主页底部天气通知具备按钮、键盘焦点和悬停反馈；点击会进入与主页天气卡相同的完整天气页。第一章未解锁时仍为只读通知。
- 体育场视角：`sports_courts` 从斜视角场地透视校正为 `362×271` 正俯视像素源图，接入环境图集第 `10` 帧；清除洋红残边并同步 `placementHeight`，地图上的跑道、足球场和球场方向与俯视校园一致。
- 自动验证：TypeScript 检查通过；`61` 个测试文件、`318` 项测试全部通过，覆盖功能矩阵、第一章回归、任务栏、双屏、上传、生命周期、纸质道具、语音职责、天气通知入口、体育场资产和正式 DEV 隐藏。
- 音频验证：三组音频生成与校验连续执行两轮；两轮的 `generated` 均为空，未发生意外重生成，现有 MP3 均可由 `ffprobe` 解码。
- 阶段浏览器矩阵：依次检查第一章、第二章开始、离开寝室、检查占座纸条、楼主上传、`bd` 排名、恢复申请、章节出口和第三章共 `9` 个检查点；章节、任务、功能权限、手机与 Phaser 挂载均符合预期，页面错误为 `0`。
- 离线验收：在 `390×844` 全新浏览器上下文直接用 `file://` 打开 `demo/index.html`，得到 `1` 个手机框架、`0` 个 DEV 入口、首屏“开始游戏”，控制台与页面错误为 `0`。在 `1280×900` 双屏检查点实际点击底部天气通知进入天气页，并移动到体育场区域核对正俯视贴图，页面错误为 `0`。
- 单文件交付：`demo/index.html` 为 `52,092,753 bytes`，SHA-256 为 `df07f60b1e31d9b2904c81ce58f80d60d3e91ed187f20954b3a23dc267c73302`；脚本、样式、字体、图片和音频全部内嵌，可离线打开。

## 2026-07-16 锁定入口图标与框体恢复

- 视觉契约：锁定中的应用、服务和导航槽位继续保留原卡片框与原图标，只隐藏名称、说明和角标；静态节点无按钮语义、无焦点、无点击与无效提示，正式剧情开放后沿原权限规则恢复名称和交互。
- 覆盖范围：手机桌面的照片、CC98、游戏；浙大钉身份快捷项、应用宫格、底部导航与搜索图标；移动图书馆读者快捷项、服务宫格与底部导航；CC98 顶部静态菜单图标与底部导航。
- 占位清理：浙大钉底部无用途的蓝色 `assistant-banner` 已从组件和样式中删除；文字型未开放内容仍保留 `xxx`，不再用 `xxx` 替代已知图标。
- 自动验证：手机桌面、浙大钉和 CC98 定向套件共 `3` 个测试文件、`34` 项通过；`npm run typecheck` 通过；完整 Vitest 为 `61` 个测试文件、`321` 项全部通过；`npm run build:single` 成功。
- 离线验收：直接通过 `file://` 检查干净首屏、第一章手机桌面、第二章浙大钉、移动图书馆和 CC98。首屏有 `1` 个“开始游戏”且 `DEV=0`；第一章 `3` 个锁定应用均保留 `2px` 图标框、名称与按钮数量为 `0`；浙大钉宫格 `9` 个、图书馆 `8` 个、CC98 底栏 `5` 个锁定入口均显示图标且无按钮，宫格内 `xxx=0`、蓝色横条数量 `0`，所有页面错误为 `0`。
- 单文件交付：`demo/index.html` 为 `52,094,891 bytes`，SHA-256 为 `178e8d7b2a51202434e83a6080f6e2c7f0c81f920fdcaf383dee73aa209d9bdf`；脚本、样式、字体、图片和音频继续全部内嵌。
- 清理：真实浏览器截图和游戏验证客户端生成的状态文件均只保存在 `/tmp`，验收记录完成后删除，不进入交付包。

## 2026-07-16 白屏恢复、任务入口与手机比例修复

- 白屏取证：最终单文件在全新浏览器上下文可正常显示“早八闹钟 / 07:55 / 开始游戏”；此前消失的 `DEV` 来自生产包的主动隐藏条件。离线评审包现默认显示折叠 `DEV`，可从旧存档或异常页面直达有效检查点；`?dev=0` 保留为展示模式。
- 手机比例：公共逻辑画布由 `430×930` 收紧为 `430×860`，宽高比固定为 `1:2`；`PhoneShell` 与 `InventoryBar` 复用同一尺寸常量，页面继续等比缩放，不允许横纵分离拉伸。
- 任务点击：真实浏览器确认点击事件原本已触发，但手机任务条的 `transform` 建立了错误的 fixed containing block，使抽屉被限制在窄条内部。现已移除该变换参照，补齐 pointer 事件隔离与 `touch-action`，抽屉完整限制在手机框内。
- 任务信息：抽屉新增独立的“当前任务”“当前进度”区块，并继续显示下一步目标、步骤、三档提示和相关界面导航；鼠标、触摸、Enter 与 Space 共用同一按钮。
- 数字反馈：物品栏新增四个有序签到数字槽；已取得数字按 `d1–d4` 原位显示，未知位为 `?`，收起状态同步显示紧凑数字串。
- 自动验证：`npm run typecheck` 通过；`61` 个测试文件、`323` 项测试全部通过；新增生产 DEV、任务指针隔离、任务摘要和数字槽覆盖。
- 浏览器验收：`815×650` 下手机框为 `307×614`，`390×844` 下为 `354×708`，两者宽高比均为 `0.5`。干净流程实际点击“开始游戏 → 关闭 → 再睡5分钟 → 进入手机主界面 → 任务键”，抽屉命中任务按钮且完整位于手机框内；第一章检查点显示 `0798` 四个数字槽，横向溢出为 `0`，页面与控制台错误为 `0`。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `52,097,280 bytes`，SHA-256 为 `6be1cbbe7f93b02bc7e872e4757485077cd74ffb27204d05fce69fd42b2acd7f`。

## 2026-07-16 签到数字同步到任务栏

- 状态单源：`QuestTaskBar` 直接读取 `state.digits.d1–d4`，未新增任务提示布尔值或数字副本；只有第一章散码后显示数字提示，进入后续章节自动隐藏。
- 顶部任务键：当前目标下方增加紧凑“签到码”提示，已取得数字显示原值，未取得位置显示 `?`；任务标题、数字进度和点击区域保持不变。
- 任务抽屉：在“当前任务 / 当前进度”与下一步目标之间新增四个有序数字槽，并显示已获得数量，例如部分进度 `0 ? 9 ? · 2/4`、齐全进度 `0 7 9 8 · 4/4`。
- 自动验证：`npm run typecheck` 通过；`61` 个测试文件、`324` 项测试全部通过。新增测试覆盖部分数字的原位显示、任务键无答案泄露和抽屉计数。
- 浏览器验收：使用共享 Web 游戏操作脚本实际点击最终单文件任务键；顶部第二行显示 `签到码 0 7 9 8`，抽屉四格显示 `0 / 7 / 9 / 8` 与 `4/4`，`render_game_to_text()` 同步返回四个相同数字，页面与控制台错误为 `0`。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `52,099,217 bytes`，SHA-256 为 `e10ef8010edf3ff177a37c8ce4b446b105408ae2ae8db01416440aa958c1f9f3`，外链脚本、样式和 HTTP 媒体均为 `0`。

## 2026-07-16 任务防剧透与锁定图标名称对齐

- 任务防剧透：任务抽屉删除完整步骤清单，只渲染一个“下一步目标”；锁定后续步骤的名称不进入 DOM，数字进度与三档手动提示保留。
- 材料回看：已完成的纸质道具改放入“已取得材料”资料夹，默认收起；用户主动展开后仍可回看已消耗文档。收起态实测高度为 `42px`。
- 锁定入口：锁定中的手机桌面应用、浙大钉身份快捷项与应用宫格、移动图书馆服务、浙大钉与 CC98 底栏均保留原名称；继续使用静态元素，无按钮语义、焦点和点击反馈。
- 对齐验收：浙大钉 `11` 个宫格实测每格高 `96px`，同行 `top` 坐标一致；手机桌面照片、CC98、游戏三个锁定格均为 `84px`；图书馆八个锁定服务和 CC98 五个底栏名称全部可见。
- 任务验收：第二章 `5/16` 检查点只显示“生成并盖章物品识别报告”；后续小票、本人证明、四项公示、`bd`、排名与恢复申请文字命中数为 `0`。
- 自动验证：`npm run typecheck` 通过；定向 `4` 个测试文件、`48` 项通过；完整 Vitest 为 `61` 个测试文件、`325` 项全部通过。
- 真实浏览器：共检查任务抽屉、浙大钉、图书馆、CC98 和手机桌面 `5` 个页面，游戏文本状态与画面一致，页面与控制台错误均为 `0`。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `52,100,969 bytes`，SHA-256 为 `7c60671ed7015a94dfc8e74400d20a53b6340c18b54c6c00b69ca105f1971a31`，外链脚本、样式和 HTTP 媒体均为 `0`。
- Pro 审阅包：`7_55_current_implementation_20260716.zip` 已从最新源码重建；`unzip -t` 通过，内含的 `demo/index.html` 哈希与正式单文件一致，不含 `node_modules`、`dist`、开发工具目录、嵌套 ZIP 或临时截图。ZIP 自身大小与哈希在交付回复中报告，避免压缩包内文档对自身哈希形成循环引用。

## 2026-07-16 地图任务层、图书馆重入与手机返回修复

- 地图任务层：RPG 任务详情通过 portal 直接挂载到 `.rpg-shell`，不再受顶部窄任务条高度约束；在 `694×1000` 细指针视口实测抽屉位于 `(14, 64)`、尺寸 `470×420.4`，完整落在游戏容器内且内容可滚动。
- 输入区分：虚拟方向键只在主指针为 `coarse` 时渲染；桌面细指针实测方向键节点为 `0`，`390×844` 触摸上下文保留 `1` 组、`5` 个移动/空格按钮。
- 图书馆重入：`LibraryFinalsController.enterLibrary()` 支持所有未结束图书馆阶段；重入按当前事实选择安全检查点并保持阶段。真实浏览器从截图对应的 `5/16 · evidence_gathering` 触发门口事件后进入 `library_interior / library_seat_022`，进度仍为 `5/16`。
- 手机返回：单屏地图按钮改为“返回手机主页”；返回结果为 `runtimeMode=phone`、`currentScene=phone_home`，原 `rpgScene=campus_bootstrap`、`rpgCheckpoint=campus_library_gate` 和任务进度保持不变。
- 自动验证：`npm run typecheck` 通过；完整 Vitest 为 `61` 个测试文件、`330` 项全部通过，新增 RPG drawer portal、细/粗指针控制、图书馆后续阶段重入和手机主页返回覆盖。
- 离线与视觉验收：共享 Web 游戏客户端确认 `960×540` 地图非空且运行输入正常；最终 `file://` 单文件在桌面与触摸上下文均无页面或控制台错误。所有临时 QA 脚本、截图和状态文件已删除。
- 单文件交付：`npm run build:single` 成功；`demo/index.html` 为 `52,102,364 bytes`，SHA-256 为 `80de8cd903ee4f2985294b97a7f7df745417df01132cdb0517115d5418332ba8`。

## 2026-07-17 MiniMax 候选素材库（未接入）

- 目录：新增 `artifacts/minimax-candidates/20260717/`，作为独立候选素材区；现有 `src/assets`、`src/data`、React/Phaser 运行时和音频清单没有新增引用。
- 画面：通过 MiniMax Image CLI 生成 `36` 张候选，覆盖寝室、图书馆、校园地图、图书馆外景、体育场、湖岸、手机主页、浙大钉、CC98、图书馆检索、天气、任务抽屉、纸质证据、校园卡、手柄、角色、图标、纹理和论坛附件；严格像素化与俯视提示追加了 `_candidate_b` 变体。
- 音频：通过 MiniMax Music CLI 生成 `7` 条配乐，通过 Speech CLI 生成 `12` 条角色配音（男旁白与女系统分开），并生成 `5` 条经 FFmpeg 截短的音效候选。黑屏配乐与 `022` 信号音各重试三次后超时，失败原因写入候选清单，未用占位文件补齐。
- 文本：通过 MiniMax Text CLI 分批生成对白、任务标题、三档提示、文字吐槽、CC98 帖子/回复/附件/版务、物品简介、纸质道具正文、手机标签和无障碍描述。`36` 份 JSON 通过解析，汇总在 `text/selected-index.json`；`21` 个超时或截断片段移入 `text/partials/` 并标记为不可直接接入。
- 交付边界：本轮没有运行游戏测试，也没有把任何候选接入正式流程；候选库单独打包，便于 Pro 审阅后再选取、重绘和裁切。

## 2026-07-17 候选素材三风格扩展（未接入）

- 用户要求：每个候选概念至少有三种主题一致、风格不同、可供筛选的版本。
- 风格矩阵：新增 `artifacts/minimax-candidates/20260717/style-matrix.json`，图片使用 `classic_pixel / paper_archive / rainy_scanline`，配乐使用 `classic_pixel / paper_ambient / rainy_glitch`，语音使用 `baseline / low_deadpan / clipped_comic`，音效使用 `clean_ui / paper_mechanical / radio_glitch`，文案使用 `plain_case / dry_campus / procedural_minimal`。
- 覆盖结果：26 个图片概念 78 个主版本；8 个配乐概念 24 个版本；12 个语音概念 36 个版本；6 个音效概念 18 个版本；36 个文案概念 108 个版本；共 264 个主版本，`reports/style-coverage.json` 缺失数为 0。
- 音频边界：MiniMax 额度在音效阶段触顶，3 个语音变体和 6 个音效变体使用同源成功音频做速度、动态和滤波派生，写入 `reports/style-audio-derived-manifest.json`，没有生成空文件或伪造成功记录。
- 文案变体：事实字段保持一致，三种版本记录不同的语气、节奏、排版与展示规则；文件位于 `text/styles/`，未改动运行时内容。
- 隔离：所有图片、音频、文本和矩阵均留在候选目录；没有接入 `src/`、`src/assets/`、`demo/index.html` 或运行时配置。
- 验证：仅完成媒体文件存在性、非零大小、SHA-256 覆盖和 ZIP 完整性核对；按用户要求未运行游戏测试套件。
- 评审包：`7_55_minimax_candidates_20260717_3styles.zip`，`126M`，SHA-256 `633241d4f7410893f9dbce078f66249cddca99f65c7a312f6a0f1d2fe7e9fbba`；`unzip -t` 通过。

## 2026-07-16 自动测试体系移除

- 删除范围：按用户要求移除全部 `61` 个项目测试文件，以及 `vitest.setup.ts`、`src/data/qa.smoke.json`、`docs/qa-checklist.md` 和 `.playwright-cli` 测试缓存；游戏源码、素材、剧情文档与历史开发记录保留。
- 配置清理：从 `package.json` 删除 `test`、`test:run` 命令及 Vitest、Testing Library、jsdom 依赖；`vite.config.ts` 恢复使用 Vite 配置入口并删除测试环境；`tsconfig.json` 删除测试初始化文件引用。
- 依赖清理：刷新 `package-lock.json` 并执行 `npm prune --ignore-scripts`，本地移除 `88` 个多余依赖；顶层 Vitest、Testing Library 与 jsdom 查询结果为空。
- 验证边界：本轮未执行任何自动测试命令。只运行 `npm run typecheck` 与 `npm run build:single`，两项均成功。
- 单文件交付：重新生成的 `demo/index.html` 为 `52,102,364 bytes`，SHA-256 为 `80de8cd903ee4f2985294b97a7f7df745417df01132cdb0517115d5418332ba8`；测试代码原本不进入运行包，因此成品哈希保持不变。

## 2026-07-17 用户确认寝室底图正式接入

- 正式底图：用户确认的严格俯视像素寝室图已原尺寸接入 `src/assets/rpg/interiors/dorm_hub.png`，源文件归档为 `source/dorm_hub_user_selected_topdown.png`；世界尺寸为 `941×1672`，固定保留左墙两组上下铺、右墙四张长桌和中央通道。
- 场景模型：新增 `DormHubModel.ts`，以原图像素建立 `23` 组静态碰撞、`14` 个交互目标、校园卡坐标和出生点；长床与长桌的可交互距离按目标矩形边缘计算，不再依赖中心点。顶部墙面另含一条与人物帧高度对应的脚点净空带，避免角色图像越过上边框。
- 镜头与人物：Phaser 继续使用 `960×540` 画布，在竖向世界中跟随人物并保持等比显示；共享人物显示比例调整为 `1.3`，宿舍、校园和图书馆继续统一复用 `configureRpgPlayerSprite`。
- 第一章入口：校园卡以 Phaser 交互物放在右侧第三张个人书桌，人物初始位置同时支持鼠标点击和空格键拾取；实测拾取后 `ownedItems=[campusCard]`、`inventoryRecovered=true`，底图上不保留重复卡片。
- 寝室交互：床铺、窗帘、窗下柜、鞋架、洗衣篮、四张书桌、书页、抽屉、洗手台、床边书架、地面背包和房门均具有近距离提示与独立动画；房门加入门扇收缩、门缝光和闪光演出，动画后再发布出场事件。
- 碰撞实测：人物连续向上穿过中央通道后，在顶部窗柜下方稳定停止于 `y=444.625`，无法进入墙面或越过页面上边框；向右在右下柜体前停止于 `x=735.25`，向左在阳台隔断前停止于 `x=235.75`。三段调试叠层确认床区、四张桌椅、洗手台、阳台、背包、柜体和门口缺口与源像素边界一致。
- 移动端验收：最终离线单文件在 `390×844` 触屏视口中，RPG 画布为 `390×219.375`，保持 `16:9`；五个触控键均为 `48×48`，横向溢出为 `0`，页面与控制台错误为 `0`。
- 检查与交付：恢复项目级 `tsconfig.json` 后 `npm run typecheck` 真正覆盖 `src` 并通过；`npm run build:single` 成功。`demo/index.html` 为 `36,790,254 bytes`，SHA-256 为 `9ebe074d12e738eb7186312942d6a101af74bbba260cd5b7e423db1ea0e3fedf`，外链 `src` 与 `href` 数量均为 `0`；`file://` 实测可加载、拾取校园卡且无页面错误。
- 验证边界：项目自动测试体系此前已按用户要求移除，本轮未恢复测试套件；验收使用真实 Chromium 运行、`render_game_to_text()` 状态、桌面/触屏操作和临时视觉截图完成。

## 2026-07-17 紫金港正俯视校园世界与四分区拼接

- 视角契约：校园世界改为严格 `90°` 正俯视、北向朝上；建筑以屋顶占地、庭院、玻璃顶、圆形端塔和入口边缘表达特征，运行时禁止立面挤出、等距投影和混合朝向。
- 官方骨架：继续使用浙大地图 WMS 全图和 WFS `254` 个要素作为离线生成参考；世界固定为 `2400×1920`，地标中心来自统一官方坐标投影，地标大小按同一世界比例收敛。
- 分区机制：新增 `NW / NE / SW / SE` 四块 `1320×1080` 分区，每相邻区域保留 `240px` 重叠；实际执行切分和羽化拼接后，拼接前后 SHA-256 完全一致，坐标没有漂移。
- 运行时替换：Phaser 校园场景只加载统一的 `zijingang_campus_plate.png`；旧 Tiled 地图、矢量道路、独立建筑、桥和环境图集均已退出运行路径。人物、标签、碰撞、入口、相机和任务状态继续由 Phaser 管理。
- 跑图修复：水域碰撞过滤小面积误判连通块，并为南门和基础图书馆建立显式步行通道；南门中央通道扩为 `48px`。
- 浏览器检查：人物从南门 `y=1840` 向北移动到 `y=1286`，镜头同步跟随；随后到达基础图书馆入口并通过空格进入 `library_interior / library_entrance`，页面和控制台错误为 `0`。
- 生成状态：GPT Image 的编辑与无参考生成接口连续返回网络错误；四分区资产槽位和拼接脚本已完成，服务恢复后可以逐块替换现有确定性俯视分区。

## 2026-07-17 紫金港俯视坐标恢复与防拉伸约束

- 问题定位：尚未完成的横向分区改造把校园世界改成 `6720×720`，但渲染层仍加载 `2400×1920` 俯视底图，导致整张校园图被横向拉伸并破坏人物、入口与碰撞坐标。
- 视角恢复：校园主场景继续采用严格 `90°` 正俯视、北向朝上；世界、底图、人物、建筑碰撞、水域碰撞和图书馆入口统一恢复到 `2400×1920` 坐标系。
- 运行时清理：校园预加载只保留统一俯视底图，横向立面建筑、横向景观和六段横向分区均退出运行路径；底图按源尺寸 `1:1` 渲染，不再调用 `setDisplaySize()`。
- 防回归：`drawZijingangWorld()` 启动时校验底图自然尺寸必须等于世界尺寸，尺寸不一致会直接报告错误，避免后续再次静默拉伸。
- 小地图：左下角 Phaser 小地图和 CSS 边框统一为 `160×128`，与完整校园 `2400:1920` 比例一致，右侧黑色空条已消除。
- 视觉检查：开发预览在南大门和基础图书馆两处确认人物、道路、启真湖、建筑和入口均为同一俯视比例；`1100×800` 下 Canvas 与壳层比例均为 `1.7778`，`390×844` 下 Canvas 为 `390×219.375`，页面横纵溢出均为 `0`。
- 离线检查：最终 `file://` 单文件实际加载 `campus_bootstrap`，运行时世界为 `2400×1920`、人物出生点为 `(1133, 1840)`，无页面或控制台错误。
- 验证：`npm run typecheck` 通过；`npm run build:single` 通过。`demo/index.html` 为 `36,790,547 bytes`，SHA-256 为 `d33c36943b7d3d329094dc810e7c4bdd5b4365a6e86408b72106049427d67f98`；外链脚本与 HTTP 媒体均为 `0`。按用户要求未恢复或运行自动化测试套件。

## 2026-07-17 RPG 任务栏与底部字幕安全区

- 统一坐标：新增 `RpgHudLayout.ts` 作为寝室与图书馆 HUD 的唯一位置来源；顶部画面保留给任务栏，普通反馈从 `y=486` 向上展开，空格交互提示固定在 `y=528` 最底行，二者均使用底边锚点。
- 图书馆对话：对话框中心统一为 `y=434`；开始对话时立即停止并隐藏普通反馈字幕，只保留对话正文和空格继续提示，避免同一画面显示两套字幕。
- 项目约束：`CLAUDE.md` 已写入 RPG 顶部任务栏安全区和底部字幕规则，后续场景不得重新使用局部顶部反馈坐标。
- 浏览器验收：真实 Chromium 分别检查寝室反馈、寝室空格提示、图书馆反馈、图书馆对话和图书馆继续提示；顶部任务栏保持无遮挡，底部各层无交叠，页面与控制台错误为 `0`。
- 离线交付：`file://` 直接打开最终单文件后，任务栏、寝室地图和底部空格提示均正常显示，外部网络请求为 `0`。`npm run typecheck` 与 `npm run build:single` 均通过；`demo/index.html` 为 `36,790,547 bytes`，SHA-256 为 `d33c36943b7d3d329094dc810e7c4bdd5b4365a6e86408b72106049427d67f98`。
- 验证边界：项目自动测试体系此前已按用户要求移除，本轮没有恢复测试套件；视觉核对所用临时截图和浏览器目录已清理。

## 2026-07-17 `20260716` 修复包选择性合并

- 合并边界：以当前项目为主线，只从 `/Users/zhuhangcheng/Downloads/7_55_current_implementation_20260716/` 移植指定修复；现有寝室、校园、图书馆地图和后续剧情实现均保留。
- 浙大钉：头像恢复为可访问按钮，点击后打开“个人资料 / 账号与安全 / 退出浙大钉”菜单；退出项可返回手机主页。浙大钉可用与不可用入口、手机桌面入口统一使用固定图标行和标签行，同行实测坐标一致。
- 物品与章节显示：拖动物品幽灵层恢复以指针为原点，实测中心偏差为 `0px`；签到数字条和物品栏数字槽只在第一章渲染，第二章对应节点数量均为 `0`。
- 微信语音：朋友第一段语音由播放完成事件推进剧情，播放开始 `2s` 后才显示跳过层；点击跳过会结束当前语音并进入下一段演出，切换页面时可取消且不会误推进。
- RPG 重入：每次进入校园地图都会根据手柄持有和购买事实重新同步移动权限；手机触摸上下文首次进入与返回后重入的禁用方向键数量均为 `0`，`movementEnabled=true`。
- 手机与双屏：粗指针或窄屏下除输入框、文本域和可编辑区外统一禁止文字选择；输入框保持 `user-select:text`。桌面双屏进入全屏后，右侧嵌入式 RPG 不再套用独占全屏尺寸，实测前后壳层宽高比均为 `1.7778`。
- 验证：`npm run typecheck` 与 `npm run build:single` 均通过；真实 Chromium 覆盖浙大钉菜单与退出、桌面图标、章节数字、物品拖动、微信语音、手机地图重入、文字选择和 `2560×1080` 双屏全屏，共 `0` 个页面或控制台错误。
- 离线交付：最终 `file://` 单文件可直达浙大钉并正常显示，运行期间 HTTP 外部资源请求为 `0`。`demo/index.html` 为 `36,792,437 bytes`，SHA-256 为 `ece77b31af9c521db376d49a09dbd6bb58d4bc7d2d7bbccfd39bf90f72e7f376`。
- 验证边界：项目自动测试体系此前已按用户要求移除，本轮未恢复测试依赖；浏览器验收使用本机 Playwright 运行环境。

## 2026-07-18 第二章操作动画与校园掩码兼容

- 照片识别：`IMG_0755.JPG` 改为亮度连续驱动的曝光、高光、噪点、扫描线和 OCR 状态；达到阈值后执行像素解码、标签锁定和识别报告展开，答案在可读状态前不进入 DOM。
- CC98：四份材料上传后执行入槽扫描和核验锁定；无效 `bd` 回复执行局部驳回抖动；有效回复驱动 `04 → 03 → 02 → 01` 排名翻页，进入十大第一时补充像素爆发和结果展开。
- 浙大体艺：三个审核字段增加数字拨轮反馈；错误提交执行红色扫描与审核回退；`7 / 47 / 3` 通过后执行绿色扫描、边框确认和“已认证”盖章。
- 浙大钉：恢复材料提交增加逐槽扫描、核验与进度脉冲；三份材料齐全后，022 清退 PASS 使用票据打印动画出现。动画仅消费组件属性和控制器结果，不延迟或反向控制领域状态。
- 动效边界：新增动画均提供 `prefers-reduced-motion` 静态降级；没有增加剧情解释字幕，现有按钮、拖拽槽位、状态机、旁白与音效事件保持原契约。
- 校园运行时：最新 `zijingang-campus-runtime.json` 已使用压缩可行走位图，旧矩形碰撞字段不再存在。`ZijingangWorld` 现解码位图并将连续不可行走格合并为 `568` 个静态碰撞矩形，恢复类型检查并避免地图入口读取空字段。
- 浏览器检查：在 `390×844` 视口确认手机框为 `354×708`，CC98 帖子横向溢出为 `0`；逐个触发材料上传、无效回复、排名翻页、体艺拨轮/驳回/认证和 PASS 打印，计算样式均命中新动画名。校园入口 Canvas 为 `960×540` 且控制台错误为 `0`。
- 构建验证：按用户要求未恢复或运行自动测试套件；`npm run typecheck` 与 `npm run build:single` 均通过。最终 `demo/index.html` 为 `73,208,050 bytes`，SHA-256 为 `aee6cbe742ed77dd78000acc7e9d6a3a56e5eaf0e3d8af917da4293459425963`，外链脚本、样式和 HTTP 媒体为 `0`。

## 2026-07-18 道具/任务动画与仓库旧全景地图接入

- 动画入包：重新从当前 `src/` 构建离线单文件，`InventoryBar` 的道具获得飞入动画和 `QuestClueStrip` 的任务目标/进度变化动画均已进入 `demo/index.html`。真实购买手柄流程中观察到 `inventory-item-flight`、`inventory-receive-lock` 和 `quest-task-update-lock`，页面错误为 `0`。
- 正式地图：将仓库归档中的旧全景拼接图恢复为校园运行底图；文件为 `5016×5016`、`50,942,320 bytes`，SHA-256 为 `63ff841fce9e29fd73775b6f42cf3ef65ae303993a55f3a555c90ec0a5ff98c2`。新增 `npm run map:zijingang` 校验图片尺寸、哈希、世界尺寸、出生点、图书馆入口和运行时字段。
- 坐标同步：校园世界、地标、标签、出生点、图书馆入口、相机缩放与正方形小地图统一切换到 `5016×5016` 坐标系；实际移动从 `(2508,4800)` 到 `(2508,4547)`，继续走到图书馆入口并按空格成功进入 `library_interior / library_entrance`。
- 碰撞边界：仓库旧版运行时的建筑碰撞和水域碰撞数组为空，因此本次保持其自由移动行为；现有 `3840×3072` 掩码与 `5016×5016` 全景图坐标不兼容，没有错误套用到新底图。
- 验证：`npm run map:zijingang`、`npm run typecheck`、`npm run build:single` 均通过；直接用 `file://` 打开成品完成底图显示、移动、图书馆入口和两类动画检查。按用户要求未恢复或运行自动测试套件。
- 离线交付：`demo/index.html` 为 `104,000,109 bytes`，SHA-256 为 `57451851ca81445f64a87504ac129bc10472dce625aaa7ec6a87a1e5a3357ca5`；旧全景 PNG 的完整字节和哈希已在单文件内核对。成品距离 GitHub 单文件 `100 MiB` 限制仅余 `857,491 bytes`（约 `837.39 KiB`）。

## 2026-07-18 新基线地图与章节动画同步

- 仓库规则：远端已建立无旧发布产物的新基线；本地启用 `pull.ff=only` 和 `.githooks/pre-push`。Git 只跟踪正式源码、脚本和文档，`demo/`、`dist/`、`uploads/` 继续留在忽略范围。
- 校园底图：正式运行图为 `5016×5016`、`47,550,839 bytes`，SHA-256 为 `600e3010c7b1ccb4e4c697850e9ee37b6670d84aaec3ba5ce8fc0c1274a718bd`。同坐标可视掩码 SHA-256 为 `7e8afde05e25767d33f1db8e830cd49f2aa310cbde4784ec3cfb249b63c04804`，运行时使用 `4px` 单元的压缩位图并记录 `175,473` 个可行走格。
- 地图工具：新增 `npm run map:zijingang:rebuild` 作为 4×4 源图的确定性重建入口；`npm run map:zijingang` 已实际验证底图尺寸、哈希、出生点、图书馆入口、压缩位图长度和掩码哈希。
- 第一章动画：签到数字飞入对应槽位，四位输入完成后逐格锁定并激活签到键；取得数字后继续复用任务栏数字飞入反馈。签到状态机和章节流程未调整。
- 第二章动画：微信追问增加回复输入、本人消息发送、对方输入和问号落入；浙大钉系统对话逐句重建并扫描进入；馆藏检索标题与五条结果错峰展开。全部反馈只读取现有状态，不写剧情进度。
- 图书馆路由：移动图书馆的“座位预约”和“空间预约”恢复可点击；实测链路为图书馆首页 → 空间列表 → 二层南选座页，`022` 位于第二张桌子左侧第二席。
- 浏览器检查：`390×844` 视口中手机框宽高比为 `0.5`，签到、微信、系统、馆藏和选座页面横向溢出均为 `0`；计算样式分别命中 `checkin-entry-flight`、`wx-followup-*`、`zju-system-line-enter` 和 `zju-catalog-result-in`，控制台错误为 `0`。
- 验证边界：按用户要求未恢复或运行自动测试套件。`npm ci`、`npm run typecheck`、`npm run build` 和 `npm run build:single` 均成功；本地单文件为 `99,761,037 bytes`，SHA-256 为 `414002fc8835f74363e9a86f0e67ad37386cca40e8f5311a8c1e2811f39b8fb6`，按版本管理规范不提交进 Git 历史。

## 2026-07-19 经纬度错误框拦截小玩法

- 签到收尾：输入 `0798` 后先短暂显示签到成功，再弹出标题为“经度与纬度不存在”的 `LOCATION ERROR` 错误框；框内明确显示 `longitude: null`、`latitude: null` 和 `ERR_GEO_0798`，随后进入红闪、过渡黑屏与序章收尾。
- 玩法主体：序章保留 `7s` 黑屏；错误框随后落入画面，玩家通过指针拖动或 `A/D`、左右方向键移动该框，对齐底部出口并拦住旁白圆圈的三次离场路径。
- 胜负逻辑：三次命中后进入 `1400ms` 按住锁定；提前松开清空锁定进度；累计三次未命中进入可重试失败页。控制器只在三次拦截、锁定达标且未失败时推进章节。
- 校园卡调整：撤销开局持有校园卡和第一章物品栏解锁；第一章校园地图继续锁定。第 `1` 位 `0` 改由签到页的“本周缺勤 `0` 次”提供。校园卡在第二章系统对话后从寝室右侧书桌拾取，拾取后进入物品栏。
- 状态观测：新增 `EndingRuntimeSnapshot`，`window.render_game_to_text()` 可读取阶段、拦截数、失误数、错误框/圆圈位置和锁定进度；`window.advanceTime()` 提供确定性时间控制。
- 真实浏览器：验证签到成功到错误框的完整转场，错误展示时 `ownedItems=[]`；验证指针将挡板移至 `72%`，键盘三次命中后按住锁定并进入第二章，以及三次未命中进入重试页。第一章浙大钉中校园地图为静态锁定槽且按钮数为 `0`；第二章寝室按空格拾卡后状态进入 `system_return_required`。`430×860` 桌面基线和 `390×844` 触屏视口均无溢出或页面错误。
- 验证与交付：英文旁白生成幂等检查返回 `generated=[]`；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。直接通过 `file://` 打开生成物，以键盘完成三次错误框拦截与长按锁定，最终回到 `phone_home / friend_message_required`，页面错误为 `0`。`demo/index.html` 为 `99,483,916 bytes`，SHA-256 为 `7d02e42ce21e49efb9eea6cb7806344a7e71e5bc3a73d736c1ceb4db7f66b1c4`。
- 验证边界：项目自动测试体系已按用户要求移除，本轮没有恢复测试依赖；使用共享 Web 游戏 Playwright 客户端、浏览器状态输出和临时截图完成验收。

## 2026-07-19 身份门控、移动预约与图书馆调查链修正

- P0 身份门控：新增 `selectIdentityReadable(state)`，唯一条件为 `actOne.inventoryRecovered && items.campusCard`；校园卡取得前，浙大钉、校园卡页、部门黄页、CC98 订单、读者主页、Toast、无障碍属性和 RPG 名牌均不输出真实姓名或学号。实体卡从寝室右侧个人书桌取得后自动打开详情，首次完整显示身份；关闭详情后才进入移动任务。详情补齐 Tab/Shift+Tab 焦点循环，桌面双屏手机区在首显阶段设为 `inert`。
- 旧存档修复：存档版本升至 `7`。版本 `6` 及更早的存档若已完成人物命名或移动，会补齐校园卡与道具栏事实；仍处于系统寻找道具栏之前的存档会清除误带的校园卡。真实浏览器分别注入早期与已命名旧存档，两类迁移结果均符合门控。
- P1 安全区与 CC98：状态栏固定在 `0–40px`，任务栏固定在 `40–80px`，页面控制区从 `80px` 后开始；搜索行使用“图标 / 输入框 / 搜索键”三列，输入保持单行省略，候选结果分为标题、楼层和正文。`430×860` 实测三层边界首尾相接且无重叠，四条候选记录完整渲染。
- P3–P4 移动链：接通朋友追问、系统红圈、寝室宝箱、校园卡首显、黄页命名、体艺锻炼、主页三次点击取三角、天气水滴、导师竖线、右箭头合成、余额 `0.06 → 6.00`、市场购买、拖手柄安装和首次方向输入。真实浏览器逐项执行后确认：前两次三角点击只给提示；水滴和两项合成素材按规则消耗；右箭头改余额后保留；购买只增加手柄；安装后手柄消失并开放控制。
- P5 预约前置：首次方向输入只写入 `manualControlTested` 并进入系统三句说明，此时 `canLeaveDorm=false`；完成“基础馆 / 二层南 / 022”预约后才进入 `movement_ready`、开放寝室出口并将任务更新为“前往基础图书馆 022”。新增 `c2-reservation-briefing` 与 `c2-seat-reservation` 两个开发检查点。
- P6 调查链：23 楼正确记录是 CC98 唯一推进项，错误候选按来源、时间或附件给出具体原因；五条 `ac01` 回复的作者和内容各有 `5/5` 唯一值。馆藏终端解锁、旧规则自动打开、关闭规则后开放三项证明与照片、快门白闪、共享亮度识别、失物招领 `missing_report / ready / scanning / stamped`、四证上传后的系统说明及 A/C/E 有效 `bd` 均已接入控制器状态。
- 浏览器验收：使用共享 Web 游戏客户端执行 `advanceTime` 并读取 `render_game_to_text()`；随后以真实 Pointer/Keyboard 交互检查 `390×844` 身份隐藏、`430×860` CC98/照片/预约说明、`960×540` 寝室/图书馆。姓名、学号在身份关闭时对可见 DOM、隐藏 DOM、`alt`、`aria-label`、`title`、`value` 的命中均为 `0`；所有检查页面与控制台错误为 `0`。
- 合并前绕过审计：RPG 图书馆交互现严格校验 `action / targetId / itemId`，控制器同时验证关键道具持有；`<=6` 旧存档不会从调查帖直接跳过馆藏终端，也不会从已取得规则直接跳过关闭阅读，并会补回续接道具；拍照前已经处于低亮度时，必须在拍照后再次调整到 `<=20` 才能完成识别。定向浏览器复验覆盖错误道具拒绝、正确道具推进、两类旧存档恢复和拍前/拍后亮度门槛，页面及控制台错误为 `0`。
- 构建与离线：`npm run typecheck`、`git diff --check`、`npm run build:single` 均通过。`demo/index.html` 为 `99,513,010 bytes`，SHA-256 为 `1fca87ae20703207efe1b5d96998c92481c1062a5387494ba1b27eaf2c31f14b`。`file://` 直接打开后，干净首屏、寝室拾卡首显和预约说明检查均通过，运行期间 HTTP 外部请求为 `0`；默认 DEV 入口存在，`?dev=0` 可隐藏。
- 验证边界：项目自动测试体系保持移除状态，本轮未恢复测试依赖；临时截图、状态 JSON 和浏览器 QA 结果完成检查后从 `/tmp` 删除。

## 2026-07-19 图书馆物件化交互与 755 书架机关

- 755 书架：拖入“索书号 755”后，书架本体按像素步进执行抖动与右移 `16px`，同步移动静态碰撞体并露出旧版离座规定；纸张完成局部出现和道具栏转移后才自动打开规定内容。错误道具不会触发机关或消耗索书号。
- 状态与重载：运行时调试状态增加 `idle / shaking / sliding / paper / complete` 五阶段、偏移量和纸张可见性；关闭规定后才写入已读事实。重进图书馆时书架和碰撞体直接保持右移终态，未读规则会自动重新打开，纸张动画不重复播放；规则未读时 CC98 拒绝上传该证据。
- 图书馆自然反馈：移除座位外框、失物招领大框、书架高亮框和通用目标闪框；022 改为状态灯、信号环和书包本体反馈，馆藏终端与登记机改为设备局部扫描，座位小票和 PASS 依靠纸张与书包位移表达，证据飞向右下道具栏位置。
- 展示层收敛：图书馆 RPG 已有物件动画的事件关闭全屏方框式演出，保留原有音效、字幕和底部安全区反馈；拖拽物品影子改为透明无边框，仅保留像素投影。
- 规则固化：`CLAUDE.md` 增加图书馆物件化交互约束，明确局部动画、碰撞同步、转移期交互门控和未读证据重入规则；底部安全区反馈、设备实体标签与开发碰撞层继续保留。
- 浏览器验收：真实 Pointer 拖拽验证错误道具拒绝、书架抖动、滑动、纸张出现、规则自动打开、关闭后任务推进与终态重载；实际碰撞从 `left=513 / right=620` 同步到 `left=529 / right=636`。中断机关并重进后规则自动重开；未读规则上传返回 `false`、读后返回 `true`；书包转移期间座位不可交互，转移完成后才开放。另逐项检查登记机扫描/盖章、证据入栏、座位小票、PASS、馆藏终端和拖拽影子，页面及控制台错误均为 `0`。
- 视口与动态降级：`1280×720` 基线和 `1280×800` 非 `16:9` 视口均保持单一 `960×540` 逻辑画布与 `16:9` 显示；`prefers-reduced-motion` 下机关直接完成 `16px` 位移并正常打开规定。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,519,606 bytes`，SHA-256 为 `b216ad680caa23cfc8d0fa051359893f2a95559beeda99c0d2e477a15b1e4930`，外链脚本、样式和 HTTP 媒体为 `0`。

## 2026-07-19 第二章签到页封闭

- 入口规则：`selectFeatureAccess(state).checkin` 仅在序章为 `true`；首次经纬度失败并进入第二章后，`SceneRouter.goTo("checkin")` 统一拒绝访问。第三章继续保持关闭，未来只有新增明确剧情状态后才重新开放。
- 浙大钉表现：第二章仍保留“学在浙大”页面及底图中的原签到卡片，覆盖卡片的 `zjuding-checkin-hotspot` 不再渲染；页面没有签到按钮、焦点目标或额外拒绝提示，点击卡片区域保持在 `zjuding`。
- 存档兼容：`SaveStore` 继续通过 `canEnterScene` 清理恢复状态；模拟第二章旧存档直接保存 `currentScene="checkin"` 后，加载结果自动回到 `phone_home`，章节阶段保持 `system_required`。
- 浏览器验收：第一章从签到页返回“学在浙大”后仍存在 `1` 个签到热点，点击可重新进入 `checkin`；第二章实际进入“学在浙大”后热点与签到按钮均为 `0`，直接路由返回 `false` 并发布 `feature_access_denied`。`390×844` 视口中手机框为 `354×708`，横向溢出为 `0`，页面与控制台错误为 `0`。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、共享 Web 游戏客户端、定向 Chromium 回归、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,519,672 bytes`，SHA-256 为 `2295bf89679ecc01ff6d9ec1602a8ce360b0e03da1f183620224df4693918c59`。

## 2026-07-19 体艺按钮覆盖与移动线索提示

- 按钮覆盖：体艺课外锻炼状态层保持顶边不动，向下扩展 `12px`，完整覆盖底图自带的蓝色「开始课外锻炼」按钮及底部阴影；绿色状态层在桌面与缩放后的 `390×844` 视口中均无蓝色残影。
- 即时引导：开始锻炼后，按钮持久显示「下一步：回到主页，查看「方向校准」推送」，同时发布同文任务 Toast；不再只说明小人自动走动。
- 分阶段任务：移动任务的箭头阶段拆为「主页方向校准 → 天气水滴 → 导师头像竖线 → 组合图形」四个当前目标；取得三角形后才把目标切换到天气，避免锻炼开始时同时展示后续全部答案。
- 反馈去重：三角形与天气水滴各由一条里程碑 Toast 负责「获得道具 + 下一步」，删除组件内重复的获得提示。
- 完整流程验收：真实点击完成「开始锻炼 → 回主页 → 三次观察推送 → 取得三角形 → 打开天气 → 取得水滴」；任务目标依次为「查看主页的方向校准推送」、「从天气页面取得一滴水」、「用天气水滴处理导师头像」，页面与控制台错误为 `0`。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、共享 Web 游戏客户端、定向 Chromium 回归、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,520,634 bytes`，SHA-256 为 `cf7714c479d5e74dc8811eddab710b1fb1980a686a3942bb519d7be8b0f78d91`。

## 2026-07-19 基础图书馆入口坐标校准

- 问题定位：`c2-library-gate` 虽写入 `campus_library_gate` 检查点，校园场景仍固定使用南侧默认出生点 `(2508,4800)`；旧入口 `(2617,2360)` 与地标中心 `(2617,2572)` 同时落在绿植和道路交叉区域，先前验收只验证了路由切换，没有验证底图建筑对应关系。
- 建筑与入口：依据 `5016×5016` 正式底图可见像素，将带中央圆塔、连翼和玻璃中庭的基础图书馆锚点校准为 `(3000,280)`，南门交互点校准为 `(3000,538)`，门口检查点为 `(3000,610)`；开发检查点现在实际在该坐标生成玩家。
- 道路碰撞：新增 `npm run map:zijingang:walkability`，只从现有正式底图重建碰撞掩码和运行时数据，不改写已批准底图。图书馆南门石板路与东西道路加入源像素对齐的连通段，入口接近点为 `(3000,544)`；`npm run map:zijingang` 现同时校验地标、入口、接近点、交互半径和六点玩家脚部碰撞。
- 资产一致性：正式底图重建前后 SHA-256 均为 `600e3010c7b1ccb4e4c697850e9ee37b6670d84aaec3ba5ce8fc0c1274a718bd`；新掩码 SHA-256 为 `fab95fbed64e50c18aff4595eb6a5ea6325c64aa985f8fabb580fb01e13a7f4e`，可行走格为 `177,526`。
- 浏览器验收：共享 Web 游戏客户端在 `1280×720` 显示基础图书馆完整南立面，玩家位于门前道路；关闭章节引导后按空格进入 `library_interior / library_entrance`，阶段更新为 `library_entered`。`1280×800` 非 `16:9` 视口保持 `1280×720` 的 16:9 Canvas，页面和控制台错误为 `0`。
- 构建与离线：`npm run map:zijingang`、`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`file://` 单文件再次验证门口画面和空格入馆链路；`demo/index.html` 为 `99,520,772 bytes`，SHA-256 为 `abb5b0b778e8f51cd7c9262a602c04c63253ff192fa7f1653ae327f9e254a33c`。
- 验证边界：项目自动测试体系保持移除状态，本轮未恢复测试依赖；所有地图裁剪图、浏览器截图和状态 JSON 均为临时验收文件，检查后清理。

## 2026-07-19 入馆记录时间交互

- 入口装置：基础图书馆闸机增加可点击的像素小屏，玩家靠近后可用鼠标点击或空格打开入馆记录；距离不足时只提示靠近，不推进任务。
- 时间阅读：记录面板分别显示 `07:55 主馆入口` 与 `08:02 二楼南区 022`，并保留 `08:02 − 07:55` 核对式，不显示计算结果。首次点击“记下记录”后才写入 `entranceRecordRead` 与 `arrival_7_minutes`；完成后可再次点击复查。
- 输入与门控：面板打开期间停止角色移动并隐藏场景交互标记；鼠标按钮、Enter、空格均可确认，Esc 可关闭且不会写入线索。任务推进仍由 `LibraryFinalsController.readEntranceRecord()` 校验。
- 提示收敛：进入图书馆时的系统提示改为引导玩家查看闸机小屏，取消交互前直接告知七分钟；任务提示、开发检查点、剧情文档与实现规范同步到点击查看流程。
- 状态观测：`render_game_to_text()` 只在面板打开时输出两条可见时间与减法式，同时记录面板开关和已读状态，便于验证关闭、确认与复查三种路径。
- 浏览器验收：共享 Web 游戏客户端在 `1280×720` 完成“小屏点击 → 面板查看 → 按钮确认 → 再次点击复查”，任务从“读取基础图书馆入馆记录”更新为“前往二层南区寻找 022”，入口门开放，控制台错误为 `0`；Esc 关闭路径保持 `entranceRecordRead=false`。`1280×800` 非 `16:9` 视口保持 `1280×720` Canvas 和 `1.7778` 宽高比，面板未与任务栏或道具栏发生遮挡。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,528,992 bytes`，SHA-256 为 `6867063cefc7273bde8d41b789bc1d92be7c31bf9fb86c843c274502e917304e`。

## 2026-07-19 PR #7 第二章剧情与任务流整合

- 冲突处理：先以远端主线 `08bab7c` 为基线手工解决 PR #7 的 `11` 个文本冲突，再吸收最新主线 `c3e246e` 的基础图书馆入口坐标、道路掩码和入馆记录面板；接入 PR 的独立剧情播放层、第二章对白与 CC98 反馈文案，同时保留主线的三层提示任务栏、身份门控、存档迁移和图书馆物件化动画。
- 控制器门槛：四项证据上传完成后进入独立 `bd_briefing` 阶段，最终 `022` 对话停留在 `seat_recovered`；两处都必须由玩家确认后调用控制器，计时器只推进中间对白。正式存档刷新后会重新打开未确认剧情。
- 剧情顺序：首次入馆事件携带 `firstEntry`，顶层调度器固定按“路线说明 → 入馆对白”排队；实际快进验证从 `3/3` 切换为 `1/14`。每个新序列重置行号，连续事件不会继承前一个序列的索引。
- 任务与音频：任务抽屉继续显示“当前任务 / 当前进度 / 下一步目标”、三层渐进提示和导航；未显示锁定步骤，也未提前输出审核参数。剧情对白当前使用场景自有文本层，已移除无资源语音占位和玩家、`022` 的错误语音角色。调查帖保留 `5` 条可选 `ac01`，阅读只记录楼层，不改变证据进度。
- 浏览器验收：吸收最新主线后再次逐一打开第二章 `34` 个开发检查点，页面错误、控制台错误、状态解析失败和 RPG Canvas 缺失或尺寸异常均为 `0`；实际执行四证上传、错误 `B` 回复驳回、有效 `A/C/E` 排名 `04 → 01`、PASS 清退书包、坐到 `022`、对话确认与第三章解锁。`bd_briefing` 和 `022` 末句各等待 `7.2s`，阶段均保持不变；确认后才推进。
- 入口与持久化：首次入馆剧情保持“路线说明 `3/3` → 入馆对白 `1/14`”顺序；闸机小屏可打开，Esc 关闭保持 `entranceRecordRead=false`，Enter 确认后任务切换为寻找 `022` 且入口门开放。`430×860` 任务抽屉完整显示，`1440×900` 图书馆保持单一画布与手机壳；`bd_briefing`、`seat_recovered` 均通过正式本地存档刷新恢复。共享 Web 游戏客户端最终输出 `entranceRecord.open=true / read=false`，无错误文件；所有临时截图、状态 JSON 和 Playwright 快照已删除。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run map:zijingang` 通过，正式底图 SHA-256 保持 `600e3010c7b1ccb4e4c697850e9ee37b6670d84aaec3ba5ce8fc0c1274a718bd`；`npm run audio:chapters:english` 连续两次均返回 `generated=[]`，`npm run typecheck`、`git diff --check`、JSON 解析与 `npm run build:single` 均通过。`demo/index.html` 为 `99,535,750 bytes`，SHA-256 为 `82e9d732cda177105a6637c72ffab5f563780e899f49e9cdbb43e454ccc1f3aa`。

## 2026-07-19 图书馆并行证据、书包重绘与共享人物动画

- 证据顺序：保留“入馆记录 → 找到 022 → 打开 23 楼调查帖”的调查入口；进入证据阶段后，馆藏旧规、照片识别、022 夹缝小票和体艺补录四条支线可交叉完成，不再互相作为硬前置。
- 上传与终局：CC98 楼主上传区在调查帖打开后即可见，任意已取得材料可单独上传；`bd`、恢复申请和 PASS 仍由四份材料齐全后的控制器状态开放。任务抽屉改为“并行材料收集 0/4”，只显示当前材料类别和进度。
- 022 书包：常态直接使用图书馆底图中的深蓝像素书包，交互坐标回到桌面实物中心；执行 PASS 时由带橙色包边、肩带、拉链和前袋的动态像素复制件接管转移。清退后使用同一底图的连续空桌木纹补片覆盖原书包，纸条与桌面纹理保持完整，重进场景直接恢复空位终态。
- 人物动画：`RpgPlayerAnimator` 统一接管校园、寝室和图书馆三个 Phaser 场景；90度、180度和左右反转分别经过原朝向、`6°` 侧身过渡和新朝向。行走帧间隔统一为 `80ms`，运行观测值为 `12.5 FPS`；三个场景均完成独立方向采样。
- 浏览器验收：实际打开照片、CC98 上传、体艺补录与 022 小票路径，确认旧规未读时仍可分支推进；书包清退验证常态、转移中、清退后和重进四个画面。`430×860` 与 `390×844` 任务抽屉横向溢出均为 `0`，`1280×720` 与 `1280×800` 保持 `16:9` RPG 画布，浏览器控制台错误为 `0`。
- 构建与离线：吸收远端最新第二章剧情整合后，`git diff --check`、`npm run typecheck` 和 `npm run build:single` 均通过；`file://` 单文件直达 022 时只显示一个书包，人物调试状态为 `12.5 FPS`，外部 HTTP 请求为 `0`。`demo/index.html` 为 `99,539,974 bytes`，SHA-256 为 `dcc10dc628f66f42900ffca2f1cd2432ddde90f16661605ced5c95d3e6f754af`。
- 验证边界：项目自动测试体系保持移除状态，本轮未恢复测试依赖；分支组合使用控制器返回值、`render_game_to_text()` 和真实 Chromium 画面联合验证。

## 2026-07-19 三款校园应用网络入口统一

- 入口规则：浙大体艺在移动任务与图书馆到馆证明支线中不再绕过网络检查；每次进入都记录当时的网络，只有移动数据可完成加载，校园网或离线会按原 3 秒流程闪退。
- 校网应用：CC98 新增像素校园网验证页，移动数据或离线进入时显示失败动画、发布拒绝事件并返回手机主页；浙大钉继续停在加载页，同时明确提示切换校园网后重新进入。CC98 与浙大钉都只有校园网入口可以显示业务页面。
- 规则单源：`NetworkController` 统一提供体艺、CC98、浙大钉三项入口判定；`c2-exercise` 与 `c2-tiyi-proof` 开发检查点预置移动数据，其他 CC98、浙大钉检查点继续预置校园网。
- 浏览器验收：共享网页游戏客户端已检查第二章体艺证明和 CC98 的正确网络入口；定向 Chromium 在 `430×860`、`390×844` 覆盖体艺移动阶段错误/正确网络、图书馆体艺错误网络、CC98 错误/正确网络、浙大钉错误网络停留及重新进入。四组场景页面与控制台错误均为 `0`。
- 构建与离线：`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过；`file://` 单文件直达第二章 CC98 时校园网校验与帖子页正常，控制台错误为 `0`。`demo/index.html` 为 `99,542,606 bytes`，SHA-256 为 `fea289d828b739ca2d39425eeca04486e9b50455862d142dd58a4fb6446df6dd`。

## 2026-07-20 移动线索并行、提前取票与统一道具反馈

- 移动线索：浙大体艺开始锻炼后，主页三角形与天气水滴同时开放；玩家可按任意顺序取得，任务栏根据“均未取得 / 仅有水滴 / 仅有三角形 / 两者齐全”显示当前下一步。导师竖线和右箭头合成仍由控制器校验。
- 022 小票：首次到达 022 即开放桌下夹缝；持有右箭头即可推出小票，不依赖书包检查、调查帖或其他证据阶段，取票不会改写当前图书馆阶段，右箭头继续保留。
- 道具反馈：手机与 RPG 共用最近获得道具检测和飞入反馈；第二章及后续的新道具均执行“来源飞入 → 道具栏脉冲 → 新槽落位”，首个手机道具也能在物品栏从空状态出现时完整播放。
- 浏览器验收：真实 Pointer 流程分别验证天气优先、三角形优先、首次到达 022 立即取票，以及手机/RPG 道具飞入动画；小票路径保持 `library_entered`，右箭头仍在道具栏，页面与控制台错误均为 `0`。

## 2026-07-20 物品身份盖章机

- 场景实体：失物招领前台增加可直接辨认的像素盖章机，机身包含 `STAMP 0.22` 铭牌、进纸托盘、扫描区、压章头、侧面手柄、出纸口和姓名/学号/人格三枚核验灯；机器本体承担点击与拖拽命中区域。
- 完整交互：把“物品识别报告”拖入机器后，依次执行进纸、扫描、压章头与手柄同步下压、纸面出现“非本人”红章、机械回弹和出纸；输入报告被消耗，“书包非本人证明”通过 RPG 统一飞入动画进入道具栏。
- 展示时序：`library_bag_nonperson_proof_issued` 剧情延后 `900ms`，状态和证明立即生效，压章与出纸期间不显示剧情遮罩；机器完成出纸后再打开系统对白。重进场景会根据 `missing_report / ready / scanning / stamped` 恢复正确设备状态。
- 浏览器验收：开发版和 `file://` 单文件均完成真实报告拖拽，运行时依次观测 `idle → feeding → scanning → stamping → ejecting → complete`；压章时章头位置为 `25`、手柄角度为 `8°`、红章可见，出纸完成后报告隐藏、证明持有、剧情出现，页面与控制台错误为 `0`。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,550,915 bytes`，SHA-256 为 `54fd362b2aba1112e6956db1694777ecbaa019ca2762cadf6a20b93f435ad60f`。

## 2026-07-20 全局字幕视觉契约统一

- 共享组件：新增 `GameSubtitleFrame`，统一系统、旁白、任务、玩家、成功、错误和广播字幕的身份标签、P0 身份脱敏、显示时长与视觉语义；手机 Toast、起床旁白、浙大钉系统对白、序章拦截对白和图书馆剧情对白均接入同一契约。
- 方框与动画：字幕统一使用深色像素面板、`3px` 边框、`6px` 左侧强调线、直角、`5px` 像素阴影；逐句对白使用 `280ms / steps(5)` 入场，定时字幕使用 `steps(16)` 完整显示周期，角色与状态差异只改变强调色。`prefers-reduced-motion` 下直接显示稳定终态。
- 位置安全区：手机字幕统一锚定底部中间安全行并保持同宽；RPG 新增壳层 `RpgSubtitleLayer`，寝室和图书馆 Phaser 场景只发布 `rpg_subtitle`，字幕固定在物品栏上方。图书馆剧情对白使用横屏底部安全行，序章错误框玩法区域上移至字幕上方。
- 交互修正：浙大钉系统对白打开时，场景交互层高于共享任务栏，继续按钮可直接点击；字幕关闭后恢复原有页面层级。章节演出卡与表单即时反馈继续沿用各自功能样式，不纳入字幕类别。
- 浏览器验收：开发版与最终 `file://` 单文件分别覆盖起床旁白、浙大钉系统/玩家对白、手机 Toast、序章拦截、RPG 现场反馈和图书馆剧情，共六类字幕。`430×860`、`390×844`、`1280×720` 下均命中统一背景、边框、直角、阴影和阶梯动画；RPG 字幕底边为 `588px`、物品栏顶边为 `597px`，序章玩法底边为 `663.65px`、字幕顶边为 `701px`，未发生遮挡，页面与控制台错误均为 `0`。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,580,324 bytes`，SHA-256 为 `4c02e94928de83600531b0eeb6b5cd79c0e1bb684d18a5a6d2475c8f548ebf1a`。

## 2026-07-20 体艺 7 / 47 / 3 来源提示修正

- 来源闭环：体艺到馆证明页直接展示三份已取得材料的原始内容及字段关系。`7` 由入馆记录 `08:02 − 07:55` 计算；`47` 来自 CC98 调查帖 `23` 楼楼主编辑中的旧申请公示编号；`3` 来自《旧版临时离座恢复规定》的三项证明要求。
- 概念消歧：页面明确标注 `23` 是调查帖回复楼层，表单第二项读取的是公示编号 `47`；剧情文档、开发规范、开发报告和调试指引同步改为同一口径。
- 交互提示：三列输入分别显示“计算时间差 / 读取编号 / 计算条目数”；未取得的来源会指向对应调查位置，已取得的来源会显示可核对内容。前三次失败提示按“运算关系 → 具体来源 → 23 与 47 的区别”逐步展开，任务抽屉第三层提示同步说明三种操作。
- 浏览器验收：共享 Web 游戏客户端和定向 Chromium 在 `390×844`、`430×860` 验证三张来源卡、任务提示、三次错误反馈及正确提交；正确结果写入 `7 / 47 / 3` 并取得到馆证明。最终 `file://` 单文件复验通过，页面与控制台错误均为 `0`，页面无横向溢出，来源面板保持纵向滚动。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,583,757 bytes`，SHA-256 为 `ae510f6dcf00d2100e00069cd1d50cdb6c0d9b50f767d555a00ab37fb30038e2`。

## 2026-07-20 CC98 BD 四位热度口令

- 语义说明：四项证据上传完成后，系统先明确说明 `bd = 帮顶`，并解释点击数字回复的 `bd` 会把该数字按顺序写入四位热度口令；任务栏同步显示当前选择进度和三层来源提示。
- 帖子玩法：调查帖在原 `23` 楼后新增 `24–31` 楼八条数字候选回复，数字为 `4 / 3 / 1 / 0 / 5 / 2 / 6 / 7`。口令顺序沿用上方材料栏：旧规证明条数、身份通过项数、022 座位末位、到座耗时，正确结果为 `3 / 0 / 2 / 7`。
- 交互与状态：每条候选回复提供 `bd 选入`，四个槽位支持撤回、清空和提交；第四位选入后自动回到口令面板。`bdSelectedPostIds` 与 `bdPasswordAttemptCount` 由控制器持久化，退出 CC98 并重新进入后仍保留选择。错误提交清空本轮输入并按三层提示解释顺序、操作和干扰信息；正确提交使排名一次从 `04` 更新到 `01`，旧 A/C/E 回复筛选不再出现在界面。
- 浏览器验收：共享网页游戏客户端已运行并检查剧情说明画面；定向 Chromium 在 `430×860`、`390×844` 验证六句说明、八条回复、四项提示、三次错误提交、`30··` 跨场景保留、`3027` 正确提交、第四位后的自动回位及 `top_ten_reached`。开发版与最终 `file://` 单文件页面及控制台错误均为 `0`，横向溢出为 `0`。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；JSON 解析、`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,592,139 bytes`，SHA-256 为 `fb2c3b598ea3159d94d6fde08470f5173ba9e8d00669b9dc36d7c889949da031`。

## 2026-07-20 大地图遮挡、寻路、移动与相机控制器集成

- 集成接线：`BootScene` 接入四个新模块——`CampusBuildingLayer` 在 `drawZijingangWorld` 之后为 8 个 landmark/major 建筑生成同源裁剪遮挡 overlay（depth=南缘 y，小地图相机忽略，静止时逐像素一致）；每栋建筑按 `getCollisionRect` 建 invisible rect 加入现有 obstacles static group（Map 保留引用），`onBuildingChanged` 时 setPosition/setSize + `updateFromGameObject()` 同步碰撞体；`RpgMovementController` 接管每帧速度（键盘+虚拟方向 clamp 后 `setManualInput`，每帧唯一 velocity 写入者，220/320 双速与加减速）；`RpgCameraController` 接管相机（follow deadzone 300×180、offset y 34、默认 zoom 0.375、0.0625 档位、小地图 128×128 @ (16,392)、拖拽 8px 阈值与惯性、小地图视口金框与点击跳转），旧 `setupCamera/setupCameraInput/finishCameraDrag/resumeCameraFollow/changeCameraZoom/manualCamera/cameraDragging` 整段删除。
- 点击寻路：`onWorldTap` → `CampusPathGrid.findPath`，成功则 `setPath` 并画路径指示（金色描边小圆点+终点脉冲圆，沿用 libraryGateMarker 视觉语言，depth=世界 y，小地图忽略，arrived/cancelled 清除），不可达则短暂红色反馈标记；`CLICK_TO_MOVE_ENABLED` 常量可一键关闭。这是本次唯一新增视觉元素。
- 契约保持：`rpg_camera_recenter` → `recenter(true)`、`rpg_camera_zoom` → `zoomBy(delta)`、`rpg_direction_changed`/`rpg_interact` 不变；`subscribeRpgSceneBridge` 双事件清理不变；library gate marker/prompt/进入、名牌、playerMarker（depth 20000 仅小地图可见）、spawn 选择逻辑不变；`publishDebugState` 的 `camera.mode` 改读 `cameraController.manualMode` 并新增 `path` 字段（followingPath/pathLength）；DEV 下 `registry.set("campusBuildingLayer", ...)` 供控制台调试。
- 模块修复（接口形状不变）：`RpgCameraController` 补上缺失的 wheel 缩放监听（attach 只注册了 pointer 事件；按原契约实现指针锚点、离散档位、manual 模式，走 120ms 缓动，destroy 同步移除）；`CampusBuildingLayer.build()` 末尾恢复 `texture.firstFrame = "__BASE"`——Phaser 的 `texture.add` 会把 firstFrame 改成首个自定义帧，场景重建时无底图帧参数创建的底图 image 会渲染成裁剪帧（世界黑屏只剩碎片）。
- 寻路可靠性：采样格从默认 16px 调整为 24px（16px 保守格会把窄于玩家足盒 ~19.5px 的路缘缝隙标为可走，A* 会把玩家引进物理无法穿行的死角被卡死取消）；`handleWorldTap` 改为在足盒空间寻路（起点取 `body.center`、终点按点击点），再换算回精灵锚点空间喂移动控制器，消除路点本身不可达。调整后从图书馆门口点击 950px 外目的地，绕行约 2850px 全程自动到达并清除指示。
- 浏览器验收：定向 Chromium（gstack）经 `?devCheckpoint=c2-library-gate` 进入：大地图渲染与集成前逐字节一致；WASD 行走 220、SHIFT 跑 320、松手减速刹车；点击寻路全程 arrived、中途 7 个路径点指示可见；建筑北侧被 overlay 完全遮挡、南侧贴边压住建筑；拖拽平移+松手惯性漂移、wheel 缩放落档且 manual、小地图点击跳视角、⌖/+/- 按钮（bridge）正常；走近 (3000,538) 出现 gate 提示，空格进入图书馆 interior；DEV 控制台 `applyTransform("crescent_building", { offsetX: 200, scaleY: 1.3 })` 后 overlay 移动变形、碰撞体同步 (2585,2087,481,476)，`resetTransform` 后画面与初始截图逐字节一致；`game.scene.start` 重启与进出图书馆两种生命周期后底图/overlay/小地图完整；`1280×720` 与 `1280×800` 视口均无拉伸遮挡；`file://` 单文件冒烟与 dev 基线逐字节一致；控制台错误为 0。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,583,860 bytes`，SHA-256 为 `4a71afca594801adf5b8d943bc5f7a349e623efdfdbea00a5d79953d0d86782c`。
- 验证边界与遗留：movementEnabled 锁定分支保持原有 setVelocity(0)+静止+toast 逻辑（校园检查点均 seed 解锁状态，该路径代码未变、经类型检查）；applyTransform 后原位 walkability 掩码障碍与原位底图像素仍在（模块既定限制）；小地图始终显示原始底图；QA 截图已全部删除。

## 2026-07-20 序章错误通知、逃脱节奏与签到码显示收敛

- 居中通知：签到成功演出先在原签到页面中央显示紧凑的 `系统通知 · LOCATION ERROR`，正文保留“经度与纬度不存在”和空坐标；通知停留 `1900ms` 后依次进入 `1200ms` 红闪、黑屏与逃脱场景，未改变控制器的签到校验和章节推进权限。
- 逃脱节奏：三轮旁白拦截时限由 `2700 / 2500 / 2300ms` 缩短为 `2200 / 1900 / 1650ms`；三条轨迹改为多段弯折、S 形折返和三波段摆动，并继续限制在可玩区域内。
- 显示收敛：第一章四位签到码只由顶部共享任务栏和任务抽屉显示；`InventoryBar` 删除展开态数字条和收起态紧凑数字串，道具槽只承载真实物品。`AGENTS.md` 与 `CLAUDE.md` 已同步该唯一展示规则。
- 浏览器验收：`430×860` 和缩放后的 `390×844` 视口均显示居中通知，后者通知边界约为 `285.7×94.7`，横向溢出为 `0`；实际时序验证经过签到、通知、红闪、黑屏并进入 `ending`。完整键盘流程连续挡住三轮并完成 `1400ms` 锁定，三轮轨迹采样分别出现 `1 / 3 / 3` 次方向变化；Pointer Events 拖动把错误框中心从 `50%` 更新到 `24%`。打开含道具的物品栏后，顶部任务栏仍显示 `0 7 9 8`，物品栏数字节点为 `0`，控制台错误为 `0`。
- 构建验证：项目自动测试体系保持移除状态，本轮未恢复测试依赖；共享 Web 游戏客户端、定向 Chromium、`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,591,121 bytes`，SHA-256 为 `20d8df0c9b10da00618cba598e0739b1823d34c034f25e7e93a70ec297f36285`。

## 2026-07-20 签到后道具栏隐藏时机修正

- 根因：手机壳原先只在 `friend_message_required / system_required / inventory_required` 三个第二章阶段隐藏道具栏，导致成功签到后的盖章、经纬度通知、红闪和旁白拦截期间仍会显示已有道具。
- 门控修正：道具栏现在以 `flags.checkinDone && !actOne.inventoryRecovered` 为唯一隐藏条件；签到成功写入 `checkinDone` 后立即隐藏，寝室取回校园卡并写入 `inventoryRecovered` 后恢复。项目规则、签到场景说明和调试对照表已同步。
- 浏览器验收：在签到页预置一个真实已拥有道具后，`430×860` 下签到前道具栏节点为 `1`，提交 `0798` 后的 `stamp1` 和 `geoerror` 阶段均为 `0`，取回校园卡状态后恢复为 `1`；`390×844` 复验为 `1 → 0`，横向溢出为 `0`。最终 `file://` 单文件同样验证 `1 → 0`，外部 HTTP 请求与控制台错误均为 `0`。
- 构建验证：共享 Web 游戏客户端、`npm run typecheck`、`git diff --check` 与 `npm run build:single` 均通过。`demo/index.html` 为 `99,591,079 bytes`，SHA-256 为 `ecaa997e56d83719aad76a5621ac185ad4f9763a399e240f342f6649e47d6d2a`。

## 2026-07-20 Web 多端与三内核适配

- 共享适配层：新增 `ClientCompatibility` 与 `useMediaQuery`，统一输出 Blink / Gecko / WebKit、iOS / Android / desktop、fine / coarse / hybrid 输入类型、VisualViewport 尺寸和能力快照；根节点同步写入可视区 CSS 变量，`render_game_to_text()` 可直接读取同一快照。页面缩放到 `2×` 时，原始 VisualViewport 为 `195×422`，归一化应用视口仍为 `390×844`，手机框保持 `354×708`，没有被反向缩小或外层裁切。
- 布局与输入：桌面分栏门控改为 `≥1100px + 横屏 + any-pointer:fine + any-hover:hover`；存在粗指针的混合设备保留 RPG 触控键。控制中心亮度改按 `pointerId` 跟踪，Pointer Capture 缺失或丢失时仍可收口；移动端方向键加入 `96ms` 最短脉冲，快速点按在 Blink / Gecko / WebKit 中分别产生 `13px / 13px / 9px` 实际位移。粗指针竖屏的 `DEV` 入口移到右下安全区，不再遮挡左方向键。
- 内核降级：标准与 WebKit 前缀 Fullscreen、`AudioContext` / `webkitAudioContext`、新旧 MediaQueryList 监听、原生与 CSS/ARIA inert 路径均进入共享契约；调试快照在缺少 `structuredClone` 时使用纯数据 JSON 深拷贝，音频资源索引移除负数 `.at()` 依赖。动态视口、容器查询单位、安全区和 `image-rendering` 均提供基线声明。Vite 构建目标固定为 Chrome / Edge 90+、Firefox 91+、Safari 15+。
- 开发版矩阵：共享网页游戏客户端完成一次真实闹钟点击；定向矩阵在 Chromium `149.0.7827.55`、Firefox `152.0.4`、WebKit `26.5` 中各运行桌面手机、移动手机、桌面控制中心、移动控制中心、桌面 RPG、移动 RPG，共 `18` 个组合。错误、文档溢出、手机比例、RPG 比例、空画布、亮度键盘/指针输入、桌面键盘移动、移动触控移动、触控键数量的失败数均为 `0`。
- 离线矩阵：最终 `file://` 单文件在三内核各复验桌面手机与移动 RPG，共 `6` 个组合，并在所有上下文中主动关闭原生 `structuredClone` 验证 JSON 降级；页面和控制台错误为 `0`，外部 HTTP 请求为 `0`，溢出为 `0`，三个移动端均显示 5 个触控键并完成右移。`demo/index.html` 为 `99,593,953 bytes`，SHA-256 为 `e151934c0168ce752eda567bf2a908cb395f61005c401e25c94fef985cb990bd`。
- 规则沉淀：`AGENTS.md`、`CLAUDE.md` 和 `docs/client-compatibility.md` 固化支持基线、设备布局、能力降级、输入契约和验收矩阵。项目自动测试体系保持移除状态，本轮未添加测试依赖；改动范围不含 `godot/`。

## 2026-07-20 GitHub Web CI

- 触发范围：新增 `.github/workflows/web-ci.yml`，每个 PR、每次推送到 `main` 和手动触发都会运行；同一 PR 或分支的新提交会取消旧运行。
- 检查范围：Node.js 22 下执行锁文件安装、紫金港地图契约、TypeScript 类型检查、常规生产构建、离线单文件构建和单文件内联校验。
- 产物校验：新增 `npm run verify:single`，要求 `demo/` 只生成非空的 `index.html`，包含内联 module runtime 与样式，且不存在外部脚本、样式表或 HTTP 媒体资源。
- 权限与依赖：工作流只授予 `contents: read`，官方 `checkout` 与 `setup-node` 固定到当前 `v4` commit SHA；未恢复自动测试依赖，未增加 Godot 构建。
- 基线验证：在最新 `main` 提交 `c373433` 的干净 worktree 中，`npm ci`、地图契约、`npm run typecheck`、`npm run build` 与 `npm run build:single` 均已通过。
- 实现后验证：按 CI 顺序重新执行 `npm ci`、地图契约、类型检查、常规构建、单文件构建与 `verify:single`，全部通过；`demo/index.html` 为 `99,593,953 bytes`，包含 2 个内联脚本和 1 个内联样式。共享 Web 游戏客户端无页面或控制台错误，真实点击“开始游戏”后进入响铃态并显示“关闭”。临时截图已删除。

## 2026-07-21 Phaser 地图与手机 UI 选择性集成

- Phaser 地图：调整寝室隐形空气墙、图书馆出生点和失物招领机交互坐标；校园、寝室、图书馆继续由现有 Phaser 宿主管理。
- 流程修正：校园卡返回保留浙大钉当前子页，`SceneRouter.back()` 避免把返回目标重新写入历史栈；校园、寝室和图书馆检查点按场景显式归类。
- 体艺证明：页面说明 `7 / 47 / 3` 分别来自入馆时间差、CC98 楼主编辑公示编号和旧版规则证明数量；三项来源可任意顺序收集，但控制器只在全部读取后接受提交。
- 视觉规范：原 `scenes.css` 按页面拆为 17 个样式文件，保持原级联顺序；字体、字幕、方框、动画时长和 easing 使用共享 token，并补充统一规范文档。
- 范围边界：本次选择性集成不包含 `godot/`、Godot bridge、Godot 模型类型或 Godot 构建接线。

## 2026-07-21 第一、二章修订稿文本落地

- 移动流程：按《第一二章文本修改定位与显示条件》清理黄页、寝室人物、体艺、方向推送、天气、微信、校园卡和手柄交易中的重复或泄题提示；缩短保留反馈，并把预约 022 前的强制系统对白替换为修订稿四句。
- 人物命名：删除未命名时场景本地的“他听不到你说话。”，只保留控制器事件播放的完整同义提示，避免同一次点击连续重复。
- 手柄后提示：人物已安装手柄时，点击人物只显示“试着走一步”或“会按方向移动”的当前状态，不再继续发布人物检查事件，因此不会触发“他可能不太知道往哪边走”的旧阶段提示。
- 寝室交互输入：移除房间家具的 Phaser 鼠标点击区、寝室门自动碰撞触发，并在寝室隐藏触控“空格”按钮，避免它与“返回手机主页”重叠。校园卡宝箱和人物提示保留点击；家具与门只由人物靠近目标后按物理空格键触发。图书馆交互和道具拖放保持不变。
- 人物阶段提示：恢复寝室人物点击入口，提示继续由控制器按未命名、已命名但未锻炼、已锻炼但未安装手柄三个关卡状态依次切换；安装手柄后只显示当前控制状态，不再回退到旧方向提示。
- 道具栏后剧情：恢复找回道具栏后的六句系统/玩家对白，沿用已有逐句播放、语音事件和快进层；关闭校园卡详情不再提前推进阶段，玩家必须回到浙大钉首页点击红圈触发。取得道具栏后到剧情结束前，任务栏保持上一关“找到道具栏”；播完后同一任务位才切换为“让地图人物回应你”，没有增加中间任务。
- 聚焦手机修复：移除 `system_return_required` 阶段将“聚焦手机”重定向回校园卡详情、并把手机面板设为 inert 的旧门控；聚焦操作现在会先关闭 RPG 道具详情，再正常切换到手机，使玩家可以进入浙大钉首页点击红圈。
- 签到失败旁白：将 `prologue_narrator_intro` 替换为“噗，哦抱歉……”的新版本；画面仍按原节奏分三段显示，三段拼接与修订原句一致，旁白标签由演出层单独显示。
- 图书馆流程：删除入馆前旧三句和四证据剧情末尾的口令解释；调整闸机、CC98 搜索、馆藏检索、755 书架、照片识别、盖章机、小票、体艺补录与 BD 谜题反馈。删除项同时移除空提示容器或空事件发布，不影响原有状态推进、动画、道具和音效。
- 前台交互：新增 `frontDeskProofRequestSeen` 持久状态，在前台强制剧情完整播放后写入；剧情后、物品识别报告生成前，玩家每次与前台交互依次显示四句修订提示。旧存档通过报告/盖章进度推断已看状态，开发检查点和完成态同步补齐。
- 复核与构建：两组旧句残留扫描均为 `0`，新增关键文本均可定位；`npm.cmd run typecheck`、`git diff --check` 与 `npm.cmd run build:single` 均通过。浏览器环境拒绝访问本地 `file://` 构建，本轮未完成实机交互复验。`demo/index.html` 为 `99,590,391 bytes`，SHA-256 为 `db5b28f5910c9227f69b7248e4cc351ccd7390b2ba29ee75d64149f4d6b1be50`。

## 2026-07-21 GitHub 最新版本同步与 Godot 路线停止

- 同步基线：当前工作区从 GitHub `main` 最新提交 `27ab6d6` 建立 `codex/sync-main-no-godot`，保留远端 Web CI、三内核兼容、Phaser 地图、任务栏和第一、二章文本修改。
- 冲突处理：体艺采用远端简化版本；README、构建脚本、浏览器目标和 RPG 样式采用最新 Phaser/Web 版本；与 Godot 无关的场景说明、注册说明和共享字体 token 调整继续保留。
- 任务栏兼容：保留远端任务栏的简化结构，同时恢复第一章四位签到数字在顶部任务按钮和任务抽屉中的显示；物品栏继续不重复显示数字。手机任务抽屉改用稳定的手机框 DOM 引用，避免首次渲染时 portal 目标为空而被压缩到任务按钮宽度。
- 引擎决策：Godot 迁移路线正式停止。活动工作区移除 `godot/`、Godot bridge、Godot 模型状态、Godot 构建脚本和生成的 `.import` 文件；React、TypeScript 与 Phaser 继续承担全部运行时。
- 恢复边界：同步前的完整普通工作区保存在 Git stash；Godot 目录与生成缓存移到工作区外恢复目录，避免在活动源码中继续保留接线。
- 验证结果：地图契约、`npm run typecheck`、常规生产构建、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。浏览器在逻辑 `430×860` 和移动 `390×844` 视口验证完整任务抽屉、四个签到数字槽和顶部 `0 7 9 8`，横向溢出与页面错误均为 `0`。最终 `demo/index.html` 为 `99,591,358 bytes`，SHA-256 为 `3f603dcd15a5692a056dda4ffbcce593fc509a392155ab0292b7e7e0304d3dee`。

## 2026-07-22 寝室校园卡拾取点改造

- 用户反馈：右侧个人书桌上的宝箱造型与寝室环境不协调，拾取物悬浮感明显；目标改为直接展示平放在桌面的校园卡。
- 视觉实现：移除宝箱箱体、锁、金属带、金色光框和上下漂浮动画；改为蓝白像素校园卡，包含照片区、姓名/卡号线和校色标记，仅保留贴近桌面的 `1–2px` 阴影，并顺着桌面轻微旋转。
- 空间关系：校园卡位置从 `(790, 920)` 微调至 `(792, 928)`，落在第三张个人书桌的纸张旁；透明点击区域保持 `68×52`，剧情门控、拾取距离和获得校园卡事件不变。
- 文案同步：附近交互提示由“打开个人书桌上的宝箱”改为“拿起个人书桌上的校园卡”。
- 浏览器验收：开发版和最终 `file://` 单文件均直达 `c2-inventory`，确认校园卡平放在书桌且无悬浮动画；空格与鼠标点击均可拾取，随后卡片消失、`ownedItems=["campusCard"]`、`inventoryRecovered=true`、阶段进入 `system_return_required`，页面与控制台错误为 `0`。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过；最终 `demo/index.html` 为 `67,890,337 bytes`。临时浏览器截图在检查后删除。

## 2026-07-22 黄页联络忙线门控

- 用户反馈：部门黄页的“联络成功”应在后续找到系统并完成交互后开放；此前提前拨号会被笼统归类为姓名或学号错误。
- 状态修正：`ActOneBootstrapController.identifyCharacter()` 改为区分 `connected / busy / identity_mismatch`；正常联络继续只允许在第二章移动任务及其后续阶段发生，剧情门控仍由控制器负责。
- 前置反馈：在联络尚未开放的阶段点击“呼叫”，显示“您拨打的电话正在通话中，请稍后再拨。”；开放后正确身份仍会写入人物姓名，错误身份继续显示不匹配反馈。
- 离线浏览器验收：`c2-system` 中拨号保持 `system_required / characterNamed=false / directory`，并显示完整忙线文案；`c2-name` 中输入校园卡姓名与学号后进入 `movement_required / characterNamed=true / hub`，显示“黄页联络成功”。两条路径页面错误、控制台错误、外部 HTTP 请求和横向溢出均为 `0`。

## 2026-07-22 校园宽幅地图道路与建筑接缝修正

- 道路对齐：在世界 `x=2644` 的花园接缝前，将左侧图像整体上移 `32px`，使两侧车道线、路缘、人行道和栅栏高度连续。
- 建筑裁切：删除原图 `x=5700..7000` 的 `1300px` 重复半幅塔楼，使花园直接衔接完整圆形建筑；地图宽度由 `13044` 收敛为 `11744`。
- 坐标与遮罩：图书馆入口平移到 `(9200, 950)`，食堂追踪出生点平移到 `x=10500`；按 `4px` 网格重建可行走遮罩与运行时 manifest，出生点、图书馆通路和食堂通路仍在同一连通区域。
- 实机验收：开发版与最终 `file://` 单文件均通过小地图定位检查两处接缝；图书馆门口按住空格后进入 `library_interior / library_entrance`，食堂追踪检查点正常渲染，页面与控制台错误为 `0`。
- 构建验证：`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 全部通过。`demo/index.html` 为 `64,397,731 bytes`，SHA-256 为 `3c256916e1aaf1aba94fb327836e0a23cde743192d2e9b54a4c9b2bab1915a4c`。

## 2026-07-22 第二章过期水滴清理

- 问题复现：构造 `checkinDone=true` 且同时持有第一章 `waterDrop` 和第二章 `weatherWater` 的旧存档，原实现会在天气页同时显示两个水滴道具。
- 即时收口：成功提交 `0798` 时同步清除第一章配方中已过期的 `waterDrop / headphone / wateredHeadphone`，并清空指向它们的道具选中状态。
- 存档兼容：`SaveStore` 读取已完成签到的旧存档时执行同样清理，保留独立的第二章 `weatherWater`；如果旧选中项指向第一章水滴，会自动回到未选中。
- 浏览器验收：共享网页游戏客户端已运行并检查天气页；开发版和最终 `file://` 单文件均验证旧存档迁移及实际收集流程。道具栏仅显示“电子校园卡 / 三角形 / 天气水滴”，无第一章“水滴”；页面错误、控制台错误、外部 HTTP 请求和横向溢出均为 `0`。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。`demo/index.html` 为 `64,397,982 bytes`，SHA-256 为 `6e48c81e651b95dd3aff2aba5daedfbf3f313160a0aa23f116d05ef95a6c5aa6`。

## 2026-07-22 校园 RPG 总览小地图移除

- 用户反馈：校园 RPG 左下角的“紫金港全图”总览条占用主地图视野，需要完全移除。
- 渲染收口：`BootScene` 将 `RpgCameraController` 的 `minimap` 显式设为 `null`，停止创建 Phaser 总览相机和视口标记；同时删除仅供小地图使用的玩家标记。
- UI 清理：`RpgGameHost` 移除“紫金港全图”外框 DOM，`rpg.css` 删除桌面与移动端的小地图样式。人物定位、地图放大/缩小、键盘移动、相机跟随和点击寻路继续保留。
- 浏览器验收：共享网页游戏客户端、`1200×1280` 开发版和最终 `file://` 单文件均直达 `canteen-hunt`；左下角只显示主地图，`.rpg-minimap-frame` 与“紫金港全图”节点数均为 `0`。`A` 键实际左移 `73px`，放大按钮将缩放从 `0.55` 提高到 `0.61`。最终单文件追加 Blink / Gecko / WebKit 三内核定向复验，三者均为单 canvas、可键盘移动且无总览地图；页面错误、控制台错误、外部 HTTP 请求和横向溢出均为 `0`。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。`demo/index.html` 为 `64,397,119 bytes`，SHA-256 为 `1d7053d90cb1b0cbf8bf648148957e583f9037cf420327a631d3a77f33c5314f`。

## 2026-07-22 校园人物透视、建筑通路与图书馆交互修正

- 人物与透视：校园人物基础显示尺寸提高到原先的 `2×`，并按脚底世界坐标从远处 `1.0×` 平滑过渡到近处 `1.5×`；显示尺寸随纵深变化，脚底碰撞盒继续保持固定世界尺寸，避免人物放大后空气墙同步扩大。
- 建筑通路：图书馆入口校准为 `(9120, 780)`，建筑前可行走通道延伸至 `y=760`；人物可以从道路走到门前并按空格进入，同时相邻花坛仍保持阻挡。最终可行走网格为 `147136` 个单元。
- 接缝修复：局部重绘并融合校园宽幅图在世界 `x≈7079` 的天空、树林、湖面、人行道和车道衔接；最终全景保持 `11744×1084`，SHA-256 为 `9bb6c5593697601fa1347655e43dc563bbc2e32768987df2d602aca31f525986`。
- 图书馆交互：座位 `022` 的右箭头目标视觉范围保持 `66×46`，实际拖放判定扩大为 `144×104`；最终单文件实拖到旧范围外、新范围内后成功取得小票，右箭头继续保留。盖章机向场景后方移动 `32px` 至 `y=488`，遮住原先突出的盆栽区域并保留完整机身和交互提示。
- 浏览器验收：Blink 在 `1280×720`、`1440×900` 和 `390×844` 下完成键盘或触控移动；Gecko 与 WebKit 在 `1280×720` 下完成键盘移动。各场景维持 `16:9`，非宽屏窗口正确留黑边，移动端显示 5 个触控键，文档溢出、页面错误和控制台错误均为 `0`。
- 构建验证：`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。最终 `demo/index.html` 为 `64,467,543 bytes`，SHA-256 为 `2d458de460b7ae576af2893f2d4223149f8f391b7f36e63ecae2eb3b2f0bdae4`。

## 2026-07-23 校园大地图恢复 2D RPG 俯视探索

- 地图替换：校园运行时切换为用户提供的单张 `4516×3420` 俯视地图，整图作为唯一运行时底图；道路、水域、建筑拆分层与简化平面图归档在 `source/topdown/`，只用于坐标、碰撞和建筑对应关系校准。
- 出生点与建筑对应：依据简化平面图确认“紫云碧峰”“东区大食堂”和“基础图书馆”；校园出生点设为 `(2550,650)`，位于紫云碧峰建筑区正南侧道路，剧情图书馆入口绑定基础图书馆 `(3706,1696)`，安全接近点为 `(3805,1680)`。
- 移动与碰撞：从道路透明层生成保守的 `4px` 可行走网格，并只把东区大食堂前广场、基础图书馆东/南侧空地纳入人工开放区域；建筑、水域、密集植被和未确认空地保持阻挡。最终 `159432 / 965295` 个网格可行走，出生点、图书馆、食堂和追踪区域处于同一连通区。
- 遮挡与镜头：紫云碧峰、东区大食堂、基础图书馆使用同一底图的精确建筑裁片按南缘深度重绘，人物走到建筑后方会被遮住、走到前方保持可见；镜头继续双轴跟随与离散缩放，人物改为适配俯视比例的轻微纵深缩放，其他 RPG 内景、手机页面和剧情状态未改动。
- 浏览器验收：桌面 `1280×720` 验证紫云碧峰道路出生、四向移动、基础图书馆实体碰撞和空格进入 `library_interior / library_entrance`；移动 `390×844` 保持 `16:9` canvas、触控键和零文档溢出。最终 `file://` 单文件页面与控制台错误均为 `0`。
- 构建验证：`npm run map:zijingang:rebuild`、`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。最终 `demo/index.html` 为 `68,809,884 bytes`，SHA-256 为 `b64e006d2103f92d5f3d00a09d557f0b17bf431b08d6c1d4d7d6ca7d51fdcd0d`。

## 2026-07-23 校园地图比例、碰撞、遮挡与原生清晰度修正

- 相对比例：校园人物世界尺寸缩小为上一版的 `0.5×`，标称默认镜头从 `0.55` 提高到 `1.1`；两项倍率互相补偿，因此初始画面中的人物绝对像素大小不变，而地图建筑相对人物放大一倍。
- 原生清晰度：校园场景保留 `960×540` 逻辑坐标，但单独把 canvas 后备尺寸提高到当前 CSS 显示尺寸与设备像素比，最高 `3×`，并以同倍率补偿相机。桌面 `1280×720 / DPR 1` 实际使用 `1280×720` 后备画布，移动 `390×844 / DPR 3` 使用 `1170×658`；离开校园进入内景时恢复 `960×540`，其他 RPG 场景不受影响。
- 碰撞收口：删除紫云碧峰、东区大食堂、基础图书馆的粗矩形物理体；建筑视觉范围不再参与碰撞。道路仍由 `4px` 掩码负责，食堂与图书馆开放广场只减去实测建筑主体多边形。紫云碧峰西侧与北侧道路、食堂北侧道路均已恢复通行，可行走网格更新为 `162255 / 965295`。
- 遮挡修正：三处建筑改为同源图片的多边形透明裁片；只有人物脚底同时位于建筑南缘以北且处于建筑横向范围内时才被遮挡。人物贴着建筑侧面时，遮挡层自动降到人物下方，不再切掉半个角色。
- 名称可读性：地标名称从建筑外侧远处移到建筑顶部内侧，字号提高到 `18px`，笔画与地图内提示按设备像素比独立高分辨率生成；紫云碧峰和基础图书馆在默认镜头下可直接辨认。
- 离线验收：最终 `file://` 单文件在桌面确认校园后备画布与 CSS 均为 `1280×720`、基础图书馆按空格进入 `library_interior / library_entrance` 后恢复 `960×540`；移动端保持一个 `16:9` canvas、触控键、零文档溢出，页面与控制台错误均为 `0`。
- 构建验证：`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。最终 `demo/index.html` 为 `68,812,214 bytes`，SHA-256 为 `a5b8f9b07ce4eac64ef0b23ce2c54cecb671fbde862b2386c841a63935db4671`。

## 2026-07-23 校园地图速度、跟随死区与特殊建筑收口

- 移动速度：人物校园世界尺寸减半后，步行/奔跑速度同步从 `220/320` 降为 `110/160`，避免小人物在大地图上移动过快；浏览器连续按键实测步行约 `108px/s`。
- 镜头跟随：确认 Phaser 死区使用世界坐标后，改为按当前可见世界宽高实时计算，宽度比例为 `300/960`、高度比例为 `180/540`。默认缩放与放大一档的浏览器实测横向触发比例分别约为半屏的 `31.3%` 和 `31.36%`，人物保持在屏幕内部开始带动镜头。
- 建筑特殊处理：紫云碧峰与东区大食堂关闭同源裁片遮挡，并删除东区大食堂的人工开放广场和建筑实体多边形；两者只服从道路透明层生成的碰撞。基础图书馆的人工广场、建筑实体多边形和遮挡继续保留。重建后可行走网格为 `158952 / 965295`，食堂剧情点和图书馆入口仍可达。
- 手工单源：碰撞开放区与实体多边形以 `scripts/calibrate-topdown-campus-runtime.py` 为准；建筑可视范围、名称锚点、遮挡开关与遮挡多边形以 `src/scenes/rpg/ZijingangCampusLayout.ts` 为准。
- 名称标识：地标文字移除彩色描边，保持 `18px` 高分辨率渲染；文字顶边位于实测屋顶上缘内侧 `12px`，不再悬离建筑，并避开顶部任务栏边线。
- 验证：`npm run map:zijingang:walkability`、`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 已通过；桌面浏览器和最终 `file://` 单文件的画布后备尺寸与 CSS 显示尺寸一致、`image-rendering:auto`、文档溢出为 `0`、页面与控制台错误为 `0`。最终 `demo/index.html` 为 `68,812,630 bytes`，SHA-256 为 `6e83c189a469beecc30aa26b67139e98d676bb8c570fe35e3d754253d2e8c9f7`。

## 2026-07-23 月牙楼北侧道路遮挡

- 建筑对应：建筑身份以简化平面地图为准，再用用户指出的青绿色屋顶、中央拱门与圆柱塔楼图像对应到正式底图；月牙楼运行时中心为 `(3365,1190)`，同源裁片范围为 `390×220`。
- 遮挡范围：新增月牙楼实测轮廓并启用遮挡，不增加人工开放区或特殊碰撞。道路蒙版在建筑北侧只允许 `x=3324..3399, y<=1130`，因此人物只能从上方公路沿受限通道接近，侧面不会进入遮挡判定。
- 文档：`src/assets/rpg/campus/README.md` 新增中文“手动修改方法”，明确建筑身份、碰撞开放区、实体多边形、遮挡轮廓、标签位置、生成命令和浏览器复验步骤。
- 浏览器复验：从基础图书馆检查点缩放并平移视窗后，实际点击寻路到月牙楼北侧道路终点 `(3357,1088)`；人物本体被同源建筑裁片遮住，姓名和“月牙楼”标签仍可识别，画布无溢出、页面与控制台错误为 `0`。

## 2026-07-23 合并远程食堂入口与图书馆出口

- 远程同步：保留本地 `4516×3420` 俯视校园底图、坐标系、通行掩码和月牙楼遮挡，未把远程 `11744×1084` 旧宽幅全景及其坐标重新接回运行时。
- 人物资源：接入远程上、下、侧向各 `4` 帧、共 `12` 张 `96×128` 人物帧；校园仍使用当前俯视地图的 `0.5×` 世界比例和 `1.1` 默认镜头，室内沿用共享显示比例。
- 食堂入口：接入 `canteen_interior` 场景和剧情控制器，校园门口使用当前地图中的东区大食堂坐标 `(3120,620)`，返回点为 `(3120,650)`。
- 图书馆出口：入口外侧新增离开交互，返回 `campus_bootstrap / campus_library_gate`，保留第二章阶段、证据、道具和已读记录。
- 浏览器验收：Blink 桌面实际完成“基础图书馆门口 → 图书馆室内 → 返回基础图书馆门口”以及“东区大食堂门口 → 食堂室内”；食堂内景恢复 `960×540` 后备画布，文档溢出、页面错误和控制台错误均为 `0`。
- 构建验证：`npm run typecheck`、`npm run map:zijingang`、`npm run build`、`npm run verify:single` 与 `git diff --check` 通过；单文件使用工作区 Node 24 和 `8192MB` 堆完成生成，`demo/index.html` 为 `72,531,190 bytes`，SHA-256 为 `868995bfd00c58d200b56ee1d31b07bbaa54e87ec29f67a9a91eab06bff48586`。

## 2026-07-24 独立校园地图 Demo 与 DEV 直达收口

- 合并基线：从远端最新 `main` 的 `4516×3420` 俯视校园地图建立合并分支；旧 `11744×1084` 宽幅接缝提交未带入，避免回退地图坐标、碰撞和建筑遮挡。Three.js Bike Arcade 草稿因违反正式运行时 Phaser-only 约束未进入本次合并，并保留在本地 stash。
- 独立 Demo：新增 `campus-map-demo.html`、`src/demos/campus-map-demo.tsx` 与响应式样式，直接复用正式 `BootScene`、俯视地图、碰撞、镜头、键盘、触控和点击寻路；状态使用内存 `GameStore`，不会读写正式剧情存档。
- 单文件交付：Vite 新增 `campus-demo` 模式，`npm run build:campus-map-demo` 生成 `demo/campus-map-demo.html`；验证器同时允许并检查正式 `index.html` 与独立地图产物，拒绝外部脚本、样式和 HTTP 资源。
- DEV 修复：第二章和第三章检查点现在预置相应的 `seenChapterIntros`，`c2-name`、`c3-congestion` 与 `campus-canteen-entry` 直达不再被旧章节弹窗拦截；`c3-congestion` 保持 `377 / 755m`，默认 DEV 触发器与 `?dev=0` 隐藏契约保持有效。
- 输入兼容：触控方向键在 Pointer Capture 被旧 WebKit 或合成输入拒绝时继续发送移动事件，并由全局 `pointerup / pointercancel` 安全停止。
- 浏览器验收：最终单文件在 Blink、Gecko、WebKit 桌面 `1280×720` 均完成右移，角色从 `(3805,1680)` 移至约 `(3857,1680)`；Blink 与 WebKit `390×844` 均显示 5 个触控键并完成同等移动。所有场景为单 Canvas、文档溢出、页面错误和控制台错误均为 `0`。
- 构建验证：`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run build:campus-map-demo`、`npm run verify:single`、`npm run verify:campus-map-demo` 与 `git diff --check` 通过。`demo/index.html` 为 `72,531,325 bytes`，SHA-256 为 `9807b2a1285eb3f617553d55ce6429423652f544d57155e7463aaf5a54482ae6`；`demo/campus-map-demo.html` 为 `37,550,426 bytes`，SHA-256 为 `92e3d8186c21b130d708d103f3b8d98b4fb5ec88cd8defa5782a60ec90f8bb83`。

## 2026-07-24 独立校园 Demo 接入大食堂剧情

- 遗漏定位：`src/demos/campus-map-demo.tsx` 原先只注册 `BootScene`，收到 `rpg_canteen_entry_requested` 后明确停留大地图并显示占位提示，因此独立单文件无法进入已有的 `CanteenInteriorScene`。
- 场景接入：独立 Demo 注册校园与食堂两个 Phaser 场景，使用内存状态启动食堂寻人阶段；“大食堂剧情”会重置到门前，空格进入后按 `餐盘识别与回收 → 点餐机 → 0755 取餐窗口 → 三次出口封堵 → 返回校园` 推进。
- 共享控制：新增 `bindChapterThreeCanteenEvents()`，正式 `RpgGameHost` 与独立 Demo 共用一套食堂事件到控制器的绑定，避免演示入口再次退化为只弹提示。`src/demos/README.md` 已记录该约束。
- 跨端操作：桌面继续使用 WASD / 方向键、空格与 Tab；触控继续使用方向键和空格，并在食堂阶段提供显式“切到深色 / 切回浅色”按钮。剧情字幕写入独立 Demo 的可见通知区，移动端不再隐藏该区域。
- 状态验证：使用真实 `EventBus + ChapterThreeCanteenController` 执行 35 个领域事件，完整状态链到达 `campus_bootstrap / campus_canteen_gate / chase_ready`，三项餐盘、点餐 D、3 号窗口与 `southeast → steam → west` 封堵顺序全部通过断言。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single`、`npm run build:campus-map-demo`、`npm run verify:campus-map-demo` 与 `git diff --check` 通过。`demo/index.html` 为 `72,531,548 bytes`，SHA-256 为 `123da5ddb208298417d8248f9bc8af3f82fe17aa186432fb97606bc3806bf17b`；`demo/campus-map-demo.html` 为 `41,104,600 bytes`，SHA-256 为 `d1d141a68ea199f51881057c098b0a390862c0ace1b2211e7cb35e01b4bf8f87`。
- 验收边界：当前浏览器控制通道对 `file://` 页面的刷新、DOM 读取和截图均按安全策略拒绝；本轮没有把构建或控制器断言冒充为最终视觉验收。需要在当前单文件手动刷新后完成一次入口、字幕、明暗按钮和返回校园的可见链路确认。

## 2026-07-24 全分支本地集成预览

- 预览基线：本地 `codex/preview-all-integrated-demo` 以远程 PR #20、独立 Demo 食堂接入提交 `abbfab6` 为基础，再 merge `codex/chapter3-canteen-20260722` 的两个独有提交；本分支只用于合并前查看，未推送、未改远程 `main`。
- 冲突处理：保留当前 `4516×3420` 俯视校园底图、通行掩码、碰撞、人物缩放、镜头、跨浏览器适配和 DEV 直达修复；加入第三章食堂后续自行车追逐、体艺馆、启真湖、剧情状态、道具、音频和场景资产。项目规则与旧宽幅地图生成脚本未被旧分支覆盖。
- 地图衔接：东区大食堂继续使用当前坐标；体艺馆入口落在当前东侧体育区可走道路 `(4100,1350)`，启真湖入口落在当前湖区道路 `(2900,1800)`，两个点均通过现有 `4px` 通行位图取样。
- 校验：`npm run typecheck`、`npm run map:zijingang`、`npm run build:single`、`npm run verify:single` 与暂存区 `git diff --check` 通过。最终 `demo/index.html` 为 `96,530,366 bytes`，包含 2 个内联脚本和 1 个内联样式。
- 浏览器边界：已接管当前 `file://.../demo/index.html` 标签页，但浏览器安全策略拒绝刷新本地文件；未切换到其他自动化表面规避限制。用户手动刷新当前标签页后即可查看新产物。

## 2026-07-24 第三章食堂直连与实体交互收口

- 主线入口：`022` 对话完成后直接写入 `canteenHunt.tracking`，运行时转入 `campus_bootstrap / campus_spawn`；第三章任务统一为“追到东区大食堂”。求是潮骑行不再出现在正式入口、任务或 DEV 节点中，旧入口参数保留到食堂检查点的兼容映射。
- 存档兼容：保存版本升至 `11`。旧 `friend_contacted`、`chapter_three_book_hunt`、`bike_arcade`、`chapter_transition` 状态在读取时迁入食堂追踪；已有食堂、剧院和启真湖进度保持原状态。
- 食堂实体：点餐机、取餐窗和三辆餐盘车拆为“实体锚点 + 可走操作站位”。点餐机与取餐窗的玩家站位位于柜台下方；控制器先验证餐盘车封堵选择，场景再让人物从后方连续推车，按验证结果停靠或回退。
- 输入与空间：食堂、寝室、图书馆、剧院、校园和启真湖捕获 Space；寝室触控交互键恢复。图书馆道具拖放追加目标边缘距离校验，剧院海报与取票机使用可走侧站位，舞台出生点离开舞台前沿碰撞区。
- 浏览器验收：开发地址的 `c2-chapter-exit` 显示“追到东区大食堂”并进入 RPG；`c3-canteen-menu` 中角色位于点餐机正下方；`c3-canteen-block` 点击实体餐盘车后角色与餐车共同移动，随后出现第一段拦截反馈。浏览器控制台错误为 `0`。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `96,534,912 bytes`，SHA-256 为 `9c7b737ea75e631356784ceb7c6af4c874cbf69ca753c43ab60e76027d02a2a7`。

## 2026-07-24 食堂餐车连续推进与余额账本

- 余额事实源：新增以分为单位的 `wallet`。右箭头将校园卡从 `¥0.06` 变为 `¥6.00`，购买手柄扣至 `¥0.00`；三只目标餐盘回收完成后零钱增加 `¥2.00`，自行车付款后零钱扣至 `¥0.00`。校园卡页与 CC98 交易页都读取该状态；v11 及更早存档会按既有手柄、餐盘回收费和骑车事实推导余额。
- 餐车动作：三辆餐车使用四帧轮组、车架、托盘和把手绘制，人物先走到把手，再以固定相对位置随车连续前进；滚轮帧、人物步态和滚轮音效从实际滚动时刻开始。错误封堵沿原路线回推，已封住的车不再可二次交互。
- 空间约束：西侧车终点对齐纸条逃逸锚点 `(82,250)`；完成封堵后启用车箱下部碰撞，人物不能穿过已封出口。推车期间禁用明暗切换，并为控制器拒绝结果恢复本地输入锁。
- 状态验证：Vite SSR 以真实 `GameStore + EventBus + Controller` 运行“余额右移 → 购买手柄 → 三餐盘回收 → 点餐 D → 3 号窗口 → southeast / steam / west 封堵 → 自行车付款”，结果为校园卡 `0` 分、零钱 `0` 分、阶段 `chasing`。另验证 v11 旧存档迁移和校园卡页面渲染，已消费页输出 `¥0.00` 与 `我的零钱 ¥2.00`。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single`、`git diff --check` 通过。最终 `demo/index.html` 为 `96,539,357 bytes`，SHA-256 为 `1a30f46c833462c37f289b1fa9dd8fcb700a58f4e041f702deed78a8ba88c42d`。浏览器控制通道拒绝接管 `file://` 产物，因此本轮不记录新的截图验收；需要用户手动刷新当前单文件页面完成画面复核。
- 支付提示：自行车旁的提示直接读取 `wallet.cashCents`，餐盘回收完成后显示“我的零钱：2.00 元”；付款事件写入后同步显示 `0.00 元`，避免将食堂收入误解为未到账或校园卡余额。

## 2026-07-25 食堂油渍纸巾命中修正

- 根因：校园地图会提高 Phaser canvas backing-store 分辨率，但 RPG 道具栏拖放始终按 `960×540` 换算 client 坐标，导致自行车锁的世界坐标偏移，落点经常落在 `100px` 命中圈外。
- 修正：`RpgInventoryDock` 现在传入实际 canvas 宽高；室内仍为 `960×540`，校园则使用当前 backing-store 尺寸。食堂自行车开场字幕仍会播放，但不再阻塞查看、读码和纸巾拖放。
- 浏览器验证：本地 `1280×720 @ DPR 2` 的 `c3-canteen-bike` 检查点中，关闭 DEV 面板后执行“切深色 → 点击自行车读码 → 切浅色 → 从道具栏拖油渍纸巾到自行车锁”。结果为 `bikeCodeRead=true`、`bikeLockCleaned=true`、`greaseTissue` 仍在道具栏、阶段仍为 `chase_ready`，浏览器错误为 `0`；画面出现“反光消失，二维码可读”。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `96,539,177 bytes`，SHA-256 为 `bae9920f1196c5bcdd389c97baf3b272493a50d27365de92ab3cc8fab508b97b`。

## 2026-07-26 东区大食堂 755 米 3D 骑行替换

- 用户输入：保留东区大食堂内部剧情、追逐和餐盘车流程，使用 `/Users/zhuhangcheng/.qoderworkcn/workspace/mrucdokos7lsy4mk/outputs/bike_rush_3d_demo.html` 替换原有扫码后的骑行流程。
- 运行时边界：外部 Demo 依赖 Three.js CDN，正式项目需要离线单文件并保持 React / TypeScript / Phaser 运行时，因此移植玩法、低多边形 3D 视觉与交互契约，不引入外链脚本或第二套引擎。
- 已实现：食堂车锁识别、油渍纸巾清理和 2 元支付继续作为剧情门槛；付款后进入三车道 755 米骑行，支持 A / D、方向键、触控换道、三次机会、六类障碍、188 / 377 / 566 米节点、失败重试、剧情通关和无尽模式。
- 状态契约：`canteenHunt` 新增通关、尝试次数、最佳距离和最佳剩余机会；SaveStore 升至 v13，并兼容 v12 钱包及旧 `theater_reached` 存档。控制器只接受 `755m 且 lives > 0` 的剧情胜利或 `lives === 0` 的失败结算，通关后由玩家确认继续进入剧院。
- 可观测性：`window.render_game_to_text()` 的 `canteenChase` 现在输出模式、运行阶段、距离、目标、机会、车道、碰撞和前方障碍；追逐层接管 `window.advanceTime(ms)` 供确定性玩法验证。
- CI 同款验证：`npm run map:zijingang`、`npm run typecheck`、`npm run build`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 全部通过；Web CI 同步覆盖上述地图契约、类型检查、生产构建和离线单文件检查。
- 单文件浏览器验收：正式 `demo/index.html` 在桌面完成开始追逐、A / D 换道、755m 通关、持久化最佳成绩和“继续追踪纸条”进入 `campus_theater_junction`；失败分支在三次碰撞后停在 `474m` 并提供重试。`390×844` 触控环境保持 `390×219.375` 的 16:9 画面，左右换道按钮为 `42×42`，实际右移由车道 `1` 变为 `2`。两端横向溢出、页面错误、控制台错误和外部请求均为 `0`。
- 最终产物：`demo/index.html` 为 `96,556,169 bytes`，SHA-256 为 `b77678c636ca714a357dd017f516c82e43a3ccfcf926459e4bc891fedb934bef`。

## 2026-07-26 道具反馈、食堂交互顺序与模型精细化

- 道具使用：新增 RPG 道具使用指导选择器。按住道具会直接显示当前可用目标、剧情条件或无需拖动的自动核验方式；每次投放统一返回 `accepted / missed_target / wrong_item / too_far / locked / passive / elsewhere` 中的明确结果。电话道具栏在拖动时显示所有实测投放区域，悬停目标有二次描边，落在目标外会显示可见反馈。
- 食堂流程：点餐、取餐和三次餐车封堵分别新增持久化的暗色观察事实。亮色且未观察时不会提前打开点餐选择面板，也不会增加点餐、取餐或封堵计数；暗色确认线索后切回亮色才允许执行。旧存档按已有阶段推导观察事实，DEV 检查点同步预置相应状态。
- 食堂模型：取餐区增加清晰的 `1号窗口 / 2号窗口 / 3号窗口` 场景标牌；三辆餐盘车重绘为带三层车架、成组餐盘、把手、防撞条和四帧滚轮的实体，推动、退回和封堵碰撞继续使用真实车身位置。
- 骑行与单车模型：755 米追逐补充车手身体、服装、背包、头盔、轮组、辐条、链条、车架、六类障碍、楼宇窗格、树木层次、校园路灯、道路颗粒和运动细节。校园共享单车另行重绘轮组、辐条、挡泥板、链条、车篮和二维码锁，并缩小遮挡车架的反光块。
- 输入适配：桌面细指针追逐只显示键盘提示，触控换道键只在粗指针设备出现。Blink `1440×900` 实测画布为 `1440×810`、比例 `16:9`，按 `D` 后车道由 `1` 变为 `2`，触控键数量为 `0`；WebKit `390×844 @ DPR 3` 显示两个触控键，Pointer Event 右移后车道为 `2`。
- 真实流程：Blink 中实走点餐链为“亮色空格保持 `menuOpen=false` → 暗色观察写入 `menuDarkClueRead=true` → 亮色选择 D 进入 `pickup_search`”；取餐链为“亮色拒绝 → 暗色确认 3 号窗口 → 亮色核验后进入 `exit_blocking`”；餐车链为“亮色封堵计数保持 `0` → 暗色记录 `southeast` → 亮色推车后计数为 `1`”。误拖校园卡显示“本场景没有使用点”，按住油渍纸巾显示共享单车车锁的阶段条件。
- 浏览器矩阵：Blink、Gecko、WebKit 在 `1280×720` 均进入 `canteen_interior / pickup_search`，保持单 Canvas、横纵溢出为 `0`，页面和控制台错误为 `0`。移动 WebKit 追逐保持两个触控目标且无溢出。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `96,592,706 bytes`，SHA-256 为 `0181561cfc00c283d091d603e3830f6d9ea66617cda58166f5dad99a6054eeb7`。

## 2026-07-26 食堂顶部取餐窗口与低像素纸条模型

- 窗口位置：`1 / 2 / 3` 号取餐窗口从南侧旧柜台迁到食堂最上方服务栏的三个连续档口；`3` 号绑定有可见蒸汽的最右档口。窗口实体锚点分别为 `(790,218)`、`(1035,218)`、`(1235,218)`。
- 交互站位：三个站位统一位于 `y=260` 的净空带，人物脚部碰撞不会再压进第一排餐桌。浏览器实走后，人物到达 `(1043,260)` 时命中 `pickup_window_2`，到达 `(792,260)` 时命中 `pickup_window_1`，初始 `(1235,260)` 命中 `pickup_window_3`。
- 可见引导：取餐阶段显示完整的 `1号取餐窗口 / 2号取餐窗口 / 3号取餐窗口` 牌、对应编号圆环和“站这里 · 空格”；号牌、站位、距离判定、点击热区、DEV 出生点、深色纤维与纸条弹出点全部读取 `CANTEEN_PICKUP_WINDOWS`，避免视觉与判定坐标再次分离。
- 纸条模型：原 `36×34` 扁平四边形改为 `64×50` 低像素 `2.5D` 模型，包含底部厚边、三块折面、翘角、投影、蓝色 `0755` 点阵和编码条。纸条从 `3` 号蒸汽档口以窄侧展开、翻转后落到追逐位置，落定保留轻微折面摆动。
- 真实流程：Blink 单文件完成“浅色空格保持 `pickup_search / clue=false` → 深色在 3 号位读取暗号 → 浅色核验 0755 → `exit_blocking / paperBusy=false`”，页面和控制台错误为 `0`。
- 跨端矩阵：Blink `1280×720`、非 `16:9` 的 `1440×900`、移动 `390×844`，以及 Gecko、WebKit `1280×720` 均保持一个 Canvas、三个取餐目标、文档横纵溢出为 `0`、页面和控制台错误为 `0`；移动端保留一个触控控制组。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `96,594,748 bytes`，SHA-256 为 `21f19c9d703fb97bb61d26a9e2c9198b2bbc81d4f44217af05d5d9b8c2994ca6`。

## 2026-07-26 临时观演票引导与 Godot RPG 迁移决策

- 观演票落点：入口票据目标从检票员与读票器之间的模糊圆形范围移到右侧真实读票器，固定落点为 `(907,690)`、站位为 `(907,770)`；后台票据扫描口固定落点为 `(364,170)`、站位为 `(420,218)`。
- 拖动引导：按住临时观演票时才显示蓝色站位圈、连线和精确松手框；人物到位后统一转为绿色并显示“站位正确”。道具栏同时说明当前目标、前置剧情和具体松手位置。
- 判定修复：落点选择优先当前道具的可接收目标，再按精确区域面积排序，解决扫描口与道具箱大范围重叠时先命中道具箱的问题。失败结果区分框外、目标正确但人物过远、道具不匹配和剧情未开放；两次验票成功均保留临时观演票。
- 输入文案：剧院海报、闸机、票据扫描器、灯控台、通风口和启真湖假纸条的拖动提示使用独立“拖动道具”格式，不再附加无效的空格键；实际支持 Space 的查看、进入、对话和追光照射提示继续保留。
- 运行时契约：新增 `TheaterRuntimeContract.ts` 版本 `1.0.0`，现有 Phaser 剧院实际通过该端口读取状态、提交意图、订阅事件和更新检查点。`docs/theater-runtime-contract.md` 记录 Godot 剧院接入边界与七个 DEV 验收节点。
- 引擎决策：项目规则已改为 React/TypeScript 负责手机、共享状态、控制器、存档、任务、道具和表现层；Godot 4 Web 负责校园大地图和全部横屏 RPG 内景。迁移期 Phaser 横屏场景仅作为逐场景回退，宽屏并置一个手机壳和一个活动 RPG 画布。
- 浏览器实测：Blink 桌面完成入口 `0832` 取票、票根自动合成、远距离正确落点拒绝、走入站位后闸机放行、后台精确扫描、框外退票；两次成功均保留观演票。Blink `390×844` 实际拖票成功，文档横纵溢出为 `0`；Gecko、WebKit `1280×720` 均载入 `theater_interior / prop_setup`，契约版本为 `1.0.0`，页面和控制台错误为 `0`。
- 构建验证：`npm run typecheck`、`npm run build:single`、技能网页游戏客户端、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `96,600,714 bytes`，SHA-256 为 `c73aacce18d797e299cda28f0b361d3edad80b3f18658ceb86e85fd5de9e8b3e`。

## 2026-07-27 Godot Web 剧院宿主基础与并置验证

- Godot 工作区：新增固定 Godot `4.7.1` 的 `godot/` 项目、单线程 Web 导出配置、剧院场景脚本、TypeScript 资产同步、构建清单和静态一致性验证。`npm run godot:export:web` 已实际导出 `public/godot/theater/`；`index.wasm` 为 `39,513,091 bytes`，`index.pck` 为 `1,774,296 bytes`。
- 状态边界：React / TypeScript 继续持有剧情、存档、任务、道具和控制器。Godot 通过 `1.0.0` 版本协议接收递增快照、提交意图并输出调试快照；取票码和节目单使用 React DOM 面板，物品栏拖放通过 iframe 映射到固定 `960×540` 坐标。
- 当前覆盖：Godot 预览覆盖 `entry_ticket`、`program_search`、`prop_setup`、`spotlight_ready` 和 `complete`，同时复用剧院底图的前景裁片实现人物遮挡，并为纸巾、观演票、荧光刷和追光遥控器显示精确目标与站位。`spotlight_hunt` 与 `reversal` 会按 `godot_phase_not_migrated` 定向回退 Phaser，默认 `auto` 在整段验收前保持 Phaser；`?rpgEngine=godot` 用于显式预览。
- 实际流程：Blink 中完成取票机 `0832`、票根自动合成、节目顺序 `追光 → 开场 → 谢幕`、临时观演票拖入后台扫描器、错误落点解释、人物移动与实体碰撞、深浅模式同步。入口人物向上移动后脚部碰撞停在闸机实体边缘，页面错误和控制台错误均为 `0`。
- 浏览器矩阵：Blink `1280×800`、Gecko `1280×720`、WebKit `1280×720` 均运行 Godot，画布保持 `16:9`，文档横纵溢出和页面错误为 `0`。WebKit `390×844` 显示 `5` 个 `48×48` 触控键；持续按右键后人物 `x` 从 `1080` 变为 `1171`。
- 离线回退：重新生成的 `demo/index.html` 通过 `file://` 打开并在显式 `rpgEngine=godot` 请求下返回 `phaser / file_protocol`，未挂载 Godot iframe，外部请求、文档溢出、页面错误和控制台错误均为 `0`。
- 构建验证：技能网页游戏客户端、`npm run godot:export:web`、`npm run godot:check`、`npm run build`、`npm run build:single` 和 `npm run verify:single` 通过。`demo/` 仅保留两个离线 HTML，不再复制 Godot Web 目录；最终 `demo/index.html` 为 `96,616,390 bytes`，SHA-256 为 `87a0b9c7d2407b3a4910e799d531ef5be0151edcde19bca21e5eeb20e29514fd`。

## 2026-07-27 深浅模式、精确投放与第三章音频统一

- 交互规则：新增 `RpgInteractionContract.ts` 作为深浅模式、目标框、可达站位、可接收道具、投放顺序和失败类别的共享事实源。深色模式统一承担观察，浅色模式统一承担拖入、清洁、付款、推动、扫描和设备启动；等价目标只需观察一次，食堂取餐提示改为寻找暗号对应窗口，不再要求按窗口顺序逐个检查。
- 精确投放：食堂 `1 / 2 / 3` 号窗口、图书馆书架与 `022` 夹缝、剧院海报/闸机/扫描器/灯控台/通风口、启真湖九个诱饵点均提供可见目标框和人物站位。失败结果区分框外、道具错误、人物过远、模式错误和剧情锁定，失败时保留道具并说明下一步。
- 真实拖动验收：图书馆规则纸在远距离正确目标上被拒绝，人物走入绿色站位后拖入书架成功并转换为离馆规则；WebKit 重复通过。Godot 剧院在深色模式远距离拖遥控器保持道具，人物到位并切回浅色后拖入灯控台成功进入 `spotlight_hunt`。
- Godot 画布：Web 导出改用自适应画布策略，HTTP 预览中 iframe 与内部 canvas 在 `1280×720` 同步填满，固定 `960×540` 逻辑坐标继续用于碰撞和道具映射。`npm run godot:export:web` 与 `npm run godot:check` 实际运行通过，结果为 Godot `4.7.1`、`14` 个同步资产、`11` 个目标、`27` 个碰撞体和匹配的 Web 导出。
- Godot 完成态：实走发现完成检查点仍按舞台出生，座椅与隔断会阻止人物抵达大厅出口；TypeScript 运行时契约现统一按 `admitted + phase` 解析 `spawnZone`，Phaser 与 Godot 读取同一结果。隔离浏览器存档重载后保持 `phase=complete / spawnZone=lobby`，人物位于 `(836,842)`、出口目标激活；按 Space 后进入 `campus_bootstrap / campus_theater_junction` 并开启启真湖定位任务，页面和控制台错误为 `0`。
- 移动端布局：模式切换按钮与道具栏改为独立纵向区间，食堂、剧院和启真湖统一生效。WebKit `390×844` 实测按钮底边 `373.375px`、道具栏顶边 `383.375px`，间隔 `10px`，文档溢出和控制台错误均为 `0`。
- 浏览器矩阵：Blink `1440×900`、Blink `390×844`、Gecko `1280×720`、WebKit `1280×720` 与 WebKit Godot `390×844` 均保持 `16:9` RPG 画面、真实键盘或触控移动、零文档溢出和零页面错误。技能网页游戏客户端在剧院检查点完成渲染与运行时状态读取，临时截图已删除。
- 音频契约：新增第三章 `37` 条英文配音脚本、角色/音色/字幕归属、批量生成器、状态报告和哈希去重校验。男旁白固定 `English_expressive_narrator / pitch -4`，女系统固定 `English_Graceful_Lady`，场景继续显示中文字幕；食堂、剧院和启真湖各有 `3` 首音乐与 `10` 个音效。
- 音频生成：MiniMax 配额恢复后补齐启真湖 `10` 个独立短音效和 `37` 条配音；音效改为逐条生成、静音裁切、定长归一化、原子替换和逐项清单检查点，配音生成器同步增加原子替换、逐项清单检查点及限流重试。再次执行 `npm run audio:chapter3` 的四个生成阶段均返回空数组，确认可重复运行且不会重写有效资产。
- 生成链路审计：合并前审查发现部分检查点可能覆盖运行时 canonical manifest；现将启真湖音效和配音的中断进度迁入 `node_modules/.cache/seven-fifty-five/`，只有完整资产集才能原子更新正式清单。食堂、剧院、启真湖音乐、启真湖音效与配音生成器统一要求配置哈希和文件哈希同时匹配；`--verify-only` 严格只读。缺失 `1` 个启真湖音效的故障注入通过 `1/1`：命令非零退出、缓存记录 `9` 项、正式清单哈希不变、测试资产恢复；完整验证和普通增量运行也各通过 `1/1`，五份正式清单哈希均保持不变。
- CI 门禁：`.github/workflows/web-ci.yml` 新增 `npm run audio:chapter3:verify`，每个 PR 和 `main` 推送都会核对 `76` 项音频、五份正式清单、配置指纹、文件哈希与重复字节，再进入地图、Godot、类型和构建步骤。
- 音频完整性：`npm run audio:chapter3:status` 与 `npm run audio:chapter3:verify` 均报告 `expected=76 / ready=76 / missing=0 / unrecorded=0 / stale=0 / errors=0`；启真湖 `10` 个音效均为 `44.1kHz` 双声道、时长符合各自契约且文件哈希互不重复。
- 音频运行验收：Blink、Gecko 与 WebKit `1280×720` 均实走“Space 推进系统台词 → 切换深色观察”，系统配音、反射段音乐和模式切换音效在用户输入后成功播放，页面、控制台、媒体与请求错误均为 `0`。WebKit `390×844` 同样播放成功，显示 `5` 个触控按钮，模式按钮与道具栏重叠为 `0`，文档溢出为 `0`；WebKit 在首次用户输入前拒绝背景音乐自动播放，输入后按统一音频解锁流程恢复。
- 单文件交付：`npm run typecheck`、`npm run godot:check`、`npm run build`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。Blink 直接打开最新 `file://` 单文件后，内联配音、音乐和音效的 SHA-256 与生成清单对应，三类媒体均成功播放；`390×844` 下画布为 `390×219.375`、模式按钮与道具栏重叠为 `0`、文档溢出为 `0`。`demo/index.html` 为 `99,824,173 bytes`，SHA-256 为 `ee62ae55176a8d00785fa0a7dfda2d1ca262f0b6f124cdf65bd4af28ed5aa65c`；技能网页游戏客户端截图已检查并移入废纸篓。

## 2026-07-28 第三章音频 CI 环境收口

- 远端失败定位：PR #30 首轮 Web CI 在音频契约步骤中止。生成器的 `probeAudio()` 需要 `ffmpeg` 和 `ffprobe`，Ubuntu job 未显式准备这两个工具；缓存复用分支同时隐藏了底层 `ENOENT`，最终只显示“需要重新生成”。
- CI 修正：`.github/workflows/web-ci.yml` 在音频校验前检查 `ffmpeg` / `ffprobe`，缺失时通过 Ubuntu 包管理器安装，随后输出两者版本。食堂、剧院、启真湖音效与第三章配音生成器在 `--verify-only` 下保留底层探测异常，方便后续直接识别缺工具、解码失败或媒体参数越界。
- 诊断验证：用限制 `PATH` 的负向运行得到 `Probe ... failed: spawnSync ffprobe ENOENT`，确认错误已精确透出；恢复正常工具后 `npm run audio:chapter3:verify` 仍为 `76/76`。
- 本地回归：Workflow YAML 解析、`npm run typecheck`、`npm run godot:check`、`npm run map:zijingang`、`npm run build`、`npm run build:single`、`npm run verify:single` 和 `git diff --check` 全部通过；单文件仍为 `99,824,173 bytes`。
## 2026-07-28 Godot 剧院完整接管

- 追光与反转：Godot 剧院补齐 `spotlight_hunt` 和 `reversal`。三轮轨迹、诱饵残影、灯位预置、连续锁定、提前照射、超时、三次失败辅助、纸条破裂和残影逃离均读取 `TheaterSpotlightModel.ts` 同源数据；Godot 只提交实测意图，TypeScript 控制器继续验证并写入状态。
- 恢复链路：第 1、2 轮分别重载后保持 `spotlightRound=1 / 2`；`reversal / round 3` 写入正式存档后重载仍恢复反转，再正常进入 `complete`，发放 `decoyPaper` 与 `wetProgram`。完成态从 `(836,842)` 的剧院出口按 Space 返回 `campus_bootstrap / campus_theater_junction`，启真湖进入 `location_search`。
- 道具反馈：临时观演票拖入后台扫描器后保留票据、解锁道具箱并发放荧光粉刷。实际拖动同时验证框外、错道具、距离不足和深色模式锁定，界面分别显示下一步，失败不移除道具。
- 中文字体：Godot Web 加入 Fusion Pixel Font `2024.05.12` 的简体中文比例字体与 OFL/上游许可证记录，中文追光提示不再显示缺字方框。字体 SHA-256 为 `a6122b69f7ba5d0951a259954fcac8bf8dcb03779bccfeabada457f945b3ae08`。
- WebKit 兼容：追光图元改为回合创建时一次生成，瞄准只移动节点，照射状态只切换透明度；避免 WebKit 对动态索引缓冲的 `bindBuffer / bufferSubData` 错误。分阶段复验从每帧重复错误降至 `0`。
- 三内核验收：Blink、Gecko、WebKit 三次独立完整流程均命中三轮并进入 `complete`，回合锁定值为 `300 / 433.33 / 550ms`，存档重载、观演票拖放、`1440×900` 键盘移动和 `390×844` Pointer Event 触控移动全部通过。Blink `390×844` 另用原生 `touchStart / touchEnd` 在 Godot 画布完成左灯位瞄准与按住照射，`spotlightRound` 从 `0` 进入 `1`，失误为 `0`。两种附加视口保持 `16:9`，文档溢出、页面错误和控制台错误均为 `0`。
- 接管结果：`GODOT_ACCEPTED_SCENES` 已加入 `theater_interior`。HTTP(S) 默认 `auto` 在三内核均挂载一个 Godot iframe；显式 `rpgEngine=phaser` 与 `file://` 单文件继续使用 Phaser。三内核离线单文件均为一个 Phaser canvas、零 Godot iframe和零错误。
- 构建验证：`npm run godot:export:web`、`npm run godot:check`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。`demo/index.html` 为 `99,824,721 bytes`，SHA-256 为 `a49ac5448b7fa18481c7902d8d29f6ba613e01323dfd11732f4ad62a6464e748`；Godot `index.pck` 为 `3,898,448 bytes`。

## 2026-07-29 Godot 剧院 4.7 standalone 场景合入

- 集成范围：从 `C:\Users\·\Desktop\godot剧院4.7` 合入 `theatre_interactive.tscn`、`theatre_plaza.tscn`、`scripts/theatre_*`、`assets/maps/` 和 `assets/player/`，放置在远端 Godot 分支的 `godot/` 子项目内，保留原始 `res://assets/...` 与 `res://scripts/...` 引用。
- 运行边界：未替换 `godot/project.godot` 的 `theater_runtime.tscn` 主入口，也未接管 React/TypeScript `1.0.0` 剧院 runtime 契约；新增场景作为 640 × 360 standalone 原型供 Godot 编辑器直接打开，正式 Web runtime 继续使用现有 `theater_runtime.gd` 与 `public/godot/theater/`。
- 仓库修正：补充 `.gitattributes` 的 `*.godot text eol=lf`，让 Windows 工作树中的 `project.godot` 与现有 Web build manifest 的 LF hash 保持一致。
- 验证结果：新增场景与脚本的 `res://` 引用全部能在 `godot/` 下找到；`node scripts/verify-godot-project.mjs` 通过，输出 `verified Godot project version=4.7.1 assets=14 targets=11 collisions=27 webBuild=matched`；`git diff --cached --check` 通过。未运行 Godot headless import，因为本机 `godot` 命令不在 PATH；未运行 `npm run godot:check`，因为 sparse 工作树未安装 `node_modules/esbuild`，本轮使用不依赖包安装的静态 Godot 校验覆盖现有 manifest。

## 2026-07-30 剧院入口穿模与提示安全区

- 检票实体：Phaser 回退场景为检票员和右侧读票器补齐按完整可视高度计算的导航碰撞区，人物从正面靠近时停在设备外侧；统一调试状态同步输出两块碰撞矩形。
- 提示位置：Phaser 场景交互提示与 Godot 宿主提示统一使用底部内缩 `132px` 的字幕安全基线，检票提示不再贴住画布底边或遮住入口门。
- 轻量验证：`npm run typecheck` 与 `git diff --check` 通过。开发预览从剧院大厅出生点实际执行右移、上移，人物停在 `(921,762)`，当前目标为 `theater_ticket_gate`，控制台与页面错误均为 `0`；截图已人工检查并在记录结论后删除。本轮按用户要求未重新打包 `demo/index.html`。

## 2026-07-30 剧院舞台右侧设备空气墙

- 坐标修正：`stage_right_equipment` 从覆盖整块侧台的 `1260–1512 × 42–258` 收紧为设备本体 `1290–1478 × 90–210`，恢复设备前棕色操作区和右侧台阶的行走范围；Godot 运行数据已通过 `godot:sync` 同步。
- 实际行走：从 `theater_stage` 出生点持续向右，人物可进入原阻挡区域并停留在 `(1333,200)`；继续移动可抵达真实东侧墙体 `(1502,200)`，没有页面或控制台错误。
- 验证：`npm run typecheck`、`git diff --check` 通过；两张临时验证截图均已人工检查并在记录结论后删除。本轮未重新打包 `demo/index.html`。

## 2026-07-30 启真湖假纸条占位提示精修

- 新需求：保留启真湖假纸条阶段的占位提醒，但把当前提示框的体块感压下去，让提示更细、更像场景里的像素引导。
- 已做：`src/scenes/rpg/QizhenLakeScene.ts` 收窄了夹位边角、减弱了大面积蓝色填充、缩小了顶部说明牌，并把站位框改成更贴脚下的地面引导标记。
- 已做：保留原命中范围、原站位坐标、原提示文案和原剧情判定，没有改玩法。
- 验证：`npm run typecheck` 通过；使用 `develop-web-game` 的 Playwright 客户端抓取 `c3-qizhen-decoy` 检查点画布截图，提示仍清楚可读。
- 验证：重新执行 `npm run build:single`，并用 `file:///Users/zhuhangcheng/Documents/黑客松/7-55/demo/index.html?devCheckpoint=c3-qizhen-decoy&dev=0&rpgEngine=phaser` 打开离线单文件复看，确认新版占位提示已进入当前 demo。

## 2026-07-30 食堂骑行纵深演出与剧院直连

- 骑行视角：玩家与前车统一改为背向镜头的纵深模型，保留三车道换道规则；玩家增加背部、服装、背包、手臂、腿部、车架、前后轮和踏频细节，骑行动作使用连续 CSS 帧。
- 横穿行人：`runner` 障碍从道路左右边缘进入，随着接近程度横穿到真实碰撞车道；四肢和身体分别播放跑步动作，视觉位置与结算车道保持一致。
- 路景稳定：路边建筑、树、路灯和道路虚线改用连续世界索引。每次仅替换已经越过镜头的一组物件，消除原先按固定间距整组重排造成的建筑跳动与闪动；追逐视图从整数米刷新提高到约每 `0.42m` 刷新一次。
- 剧院直连：755 米剧情胜利后显示短暂抵达结果，`1650ms` 后依次通过食堂控制器完成追逐、通过剧院控制器进入 `theater_lobby`；玩家也可点“立即进入剧院”，不再返回校园剧院路口二次操作。
- 开发预览：从 `c3-canteen-chase` 实跑至 `755m`，自动进入 `rpgScene=theater_interior / rpgCheckpoint=theater_lobby`，同时得到 `canteenHunt.phase=theater_reached / theaterHunt.active=true / theaterHunt.phase=entry_ticket`；页面与控制台错误为 `0`。
- 离线单文件：同一完整流程在 `file://` 产物再次通过，外部请求为 `0`。`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；`demo/index.html` 为 `99,843,996 bytes`，SHA-256 为 `71fed111d1889fc489e54361d3cdd1bea637ef8c5397095bd3247f7d7923dfdb`。

## 2026-07-30 剧场后启真湖环湖地图与剧情过场

- 地图恢复：恢复旧 `11744 × 1084` 多图拼接校园全景，在剧场东侧 `x=8400` 插入 `1924px` 启真湖片段，生成当前 `13668 × 1084` 环湖运行图。两侧使用各 `260px` 同源环境融合，前景车道贯穿插入段，地图左右边界通过短淡出双向接回。
- 可复现生成：新增 `scripts/build-zijingang-loop-panorama.py`，由旧全景源图和启真湖源图原子生成 `zijingang_campus_loop_panorama.png`；新增环湖坐标与碰撞校准，统一维护食堂、剧场、启真湖、图书馆、出生点、循环边界和过场轨迹。运行图 SHA-256 为 `c2f3c887bb6c1d5f58e09a89883a28bd0050d0ccc8b1c85e10b5236ec3a4136d`。
- 通行与纵深：前景道路 `y≥864` 连续可走，食堂、剧场、启真湖和图书馆入口使用实测通路；人物继续读取共享纵深曲线，远处 `1.0`、近处 `1.5`，当前湖畔停点显示约 `115 × 153px`。静态连通验证覆盖两端循环到达点和四处剧情入口。
- 剧情衔接：食堂追逐完成仍直达首次剧场；剧场完成态在画布获得焦点后按 Space 退出，立即进入校园剧场路口并启动湖畔过场。湿纸沿路面领先、间断水迹淡出、人物自动追到 `(9040,930)`，四段台词和三段视觉节拍读取第三章启真湖内容配置；过场不提前公开启真湖谜题答案。
- 存档与开发入口：新增 `campus_qizhen_transition_stop` 正式检查点。首次过场结束后保存 `locationBriefingSeen=true`，重载停在湖畔且不重复播放；未完成时仍从剧场安全点重播。新增 `c3-qizhen-transition` DEV 检查点，DEV 会话仍不写正式存档。
- 浏览器实测：Blink 完成正式存档过场、重载跳过、剧场完成态真实退出和右端环湖接回，环湖次数为 `1`；Gecko、WebKit `1280×720` 均完成过场，画布为 `1280×720`、文档溢出和错误为 `0`。WebKit `390×844` 显示 `5` 个触控键，右移后人物 `x=9040→9091`，画布为 `390×219.375`，文档溢出和错误为 `0`。
- 离线与 Godot：`file://` 单文件在请求 Godot 时保持一个 Phaser Canvas、零 iframe、零外部请求并正常播放过场。前序 Godot 剧场源码同步后重新导出 Web 产物，`npm run godot:check` 报告 Godot `4.7.1`、`15` 个资产、`11` 个目标、`27` 个碰撞体和匹配的 Web 构建。
- 构建验证：`npm run map:zijingang:rebuild`、`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single`、`npm run godot:export:web`、`npm run godot:check` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `130,734,222 bytes`，SHA-256 为 `2421482c074eb8148dfd3ab80790de643df6535ab14373de1e7d80a208950aee`。

## 2026-07-30 图书馆 022 至第三章食堂自动转场

- 文档对齐：逐句沿用第三章剧情与动画规格中的 `022` 对话，共 `26` 句；补齐记录查询、签到记录逃离、外观模式解锁、纸条破窗、深色脚印、浅色推书车、再次确认路径、校园路线和食堂抵达镜头。首次触发不再显示“是否继续追踪”选择，直接开始演出。
- 演出运行时：新增 `34` 节拍确定性时间轴，普通模式总长约 `45.2s`。每个阶段有独立状态、字幕、安全跳过、键盘焦点闭环、页面隐藏暂停和 `window.advanceTime()` 测试入口；减弱动态模式压缩非对白阶段，总长约 `40.7s`，对白仍保留阅读时间。
- 视觉落地：图书馆、当前校园总图与东区大食堂底图按阶段切换；出口段用实际人物像素图推动书车，路线段用 SVG 描绘纸条移动路径，食堂抵达段依次显示地点牌、蒸汽中的纸条残影和真实校园卡余额 `¥0.00`。有限动画改为进入对应阶段后才启动，避免路线与余额动画提前耗尽。
- 状态衔接：演出自然结束或跳过后统一进入 `chapter_three / canteen_interior / canteen_entrance`，开启 `canteenHunt.phase=tray_search`，任务更新为“在食堂截住纸条”。完成事件改为 `chapter_three_opening_completed`，避免已退出的图书馆场景继续响应旧事件。
- 浏览器验收：技能网页游戏客户端完成 `7` 段连续自动推进，状态依次覆盖对话、记录逃离、模式说明、纸条对话、抵达与食堂接管；桌面完整播放、桌面跳过、`390×844` 键盘焦点/跳过/进入食堂、减弱动态和离线 `file://` 单文件均通过。最终状态一致，外部请求、页面错误和控制台错误均为 `0`。
- 构建验证：`npm run typecheck`、`npm run audio:chapter3:verify`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。`demo/index.html` 为 `130,734,868 bytes`，SHA-256 为 `96160f620d815368a4820c69f7dac1aecbf970fd462ce9162793472efba4a102`。

## 2026-08-01 当前总体单文件预览重打包

- 打包范围：以已合并的校园环湖与启真湖提交为基础，叠加当前本地保留的 Godot 剧场完整接管、图书馆 022 至食堂开场、舞台右侧空气墙及相关 DEV 修改，重新生成总体离线预览。
- 完整性验证：第三章音频 `76/76`、校园环湖 `13668 × 1084`、Godot `4.7.1 / 15` 个资产 / `11` 个目标 / `27` 个碰撞体及 Web 构建哈希一致；`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均通过。
- 最终产物：`demo/index.html` 为 `130,734,868 bytes`，SHA-256 为 `96160f620d815368a4820c69f7dac1aecbf970fd462ce9162793472efba4a102`。
- 预览交接：应用内浏览器自动化不允许控制 `file://` 标签页，未绕过该限制；用户当前打开的 `demo/index.html` 标签页手动刷新后即可加载本次总体版本。

## 2026-08-01 启真湖指示牌箭头转轴对齐

- 根因与修正：三块指示牌共用的箭头容器绕局部 `(0, 0)` 旋转，但可见浅色转轴原本画在 `(-14, 0)`，旋转时会沿半径 `14px` 的圆周偏移；现将转轴固定到真实旋转原点 `(0, 0)`，保留箭杆、箭尖、牌子坐标和解谜判定。
- 交互验收：网页游戏客户端从 `c3-qizhen-signs` 检查点切到浅色操作，连续旋转中央 2 号牌；运行状态依次为 `[0,1,0]`、`[0,2,0]`、`[0,3,0]`、`[0,0,0]`，四个方向的实际画布截图均已逐张检查，转轴保持在外圈圆心，无新增控制台或页面错误。
- 当前预览：应用内 HTTP 预览已打开中央指示牌可操作状态，真实点击后触发旋转反馈，可直接复看。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。`demo/index.html` 为 `130,734,866 bytes`，SHA-256 为 `a1152968768504a95f6464b0be829529a5df1e69585c104b2d931251a5c33863`。

## 2026-08-02 启真湖右侧拼接带重构

- 根因：启真湖插入段右边界位于世界坐标 `x=10324`，旧生成器在 `x=10064–10324` 对整张图使用同一条水平透明度渐变，导致湖区柳树、灰色建筑、路灯和右侧圆形建筑在约 `x=10194` 形成双重曝光；前景道路本身保持连续。
- 图像重构：拼接生成器改为分层多频融合。天空使用宽色彩过渡，中景与前景沿树干、绿篱和围栏轮廓切换，细节羽化宽度保持 `40–52px`；`y≥864` 的道路继续使用原线性融合，避免改变道路几何、世界宽度、入口坐标和碰撞坐标。
- 可验证契约：运行清单记录 `blendMode=layered-multiband-v1`、左右 `260px` 融合范围、细节羽化范围和道路起始线；地图验证同步校验完整插入元数据与碰撞位图 SHA-256。新环湖图 SHA-256 为 `504b0fdc6e846a2e5b4214b327a93c03b720b6ea7e48acbfa7804acbdd56cfb6`。
- DEV 修正：`c3-qizhen-gate` 现在直接进入 `campus_bootstrap / campus_qizhen_gate`，不会沿用剧场场景；该入口仍为会话态，不写正式存档。
- 实际通行：从启真湖入口 `x=9362,y=930` 连续右移，人物通过 `x=10324` 后抵达 `x=10486`，并继续走至 `x=12175`。五个连续画面均已检查，接缝处灰色重影消失，前景人行道、车道、绿篱和围栏保持连续；页面错误与控制台错误均为 `0`。
- 构建验证：`npm run map:zijingang:rebuild`、`npm run map:zijingang`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。应用内 HTTP 总体预览已刷新到本次单文件版本。

## 2026-08-02 第三章剧场至湖畔 MiniMax-H3 CG 任务

- 剧情与分镜：按剧场反转完成后的 `location_search` 状态设计一条 `10s` 横向过场。画面只表现湿纸向水域方向逃离、断续水迹中断和玩家停下调查，不显示启真湖名称、桥梁机关、倒影解法或其他未解答案。
- 角色连续性：林星宇保持黑色短发、蓝灰外套、深色长裤和白色运动鞋；湿纸保持贴地移动、断续水滴与低饱和青蓝残影。字幕、对白和声音仍由 React 表现层拥有。
- 参考帧：从当前 `13668×1084` 环湖全景裁出剧场门口与无标识湖畔两张 `1920×1080` 参考帧，并合成当前侧面人物像素图；两帧均已人工检查。
- CLI：默认 `mmx` 已升级并立即验证为 `1.0.19`，认证仍来自本机 MiniMax 配置。H3 干跑确认请求包含 `2K / 10s / adaptive / first_frame + last_frame`。
- 正式任务：通过 `mmx video generate --model MiniMax-H3` 提交后，服务端返回 `HTTP 400 / code 2013`，当前 TokenPlan 或 Credit 不支持 H3，任务未创建且没有任务 ID。未擅自降级到 Hailuo。
- 规则：仓库允许经用户明确批准的独立 MiniMax 剧情 CG；视频继续作为 React 表现资产，不替换校园全景、碰撞、Godot 场景或 TypeScript 进度权威。

## 2026-08-03 道具最终消费与启真湖关键词贴图

- 生命周期：补齐 `rightArrow`、`greaseTissue`、`temporaryTheaterTicket`、`spotlightRemote`、`fluorescentBrush`、`wetProgram`、三个地点关键词、`decoyPaper` 与 `reflectionCoordinate` 的最终消费点；校园卡继续作为跨章节身份物品保留。旧存档按既有剧情事实清理残留道具和失效选中项，DEV 检查点同步到相同状态。
- 交互反馈：物品移除会同时清除选中态和详情弹窗；剧场扫描、启真湖地点检索等成功反馈明确说明物品已使用并从道具栏移除。
- 地点检索视觉：启真湖校园地图的 `桥边 / 倒影 / 湖` 三个槽位和候选卡片改为显示现有像素贴图，贴图置于方框主体，文字只作为下方标签；根据实机反馈再次把槽位贴图放大到 `62px`、候选贴图放大到 `58px`，让图形占据方框主体。
- 浏览器验收：桌面 DEV 检查点实际加入第三个关键词后，三个放大贴图槽位完整显示，阶段进入 `lake_unlocked`，`lakeKeyword=false`，道具栏只保留校园卡和尚待使用的假纸条；`390×844` 下页面宽度保持 `390px`，贴图在缩放后仍占方框约 `91%–94%`，零文档横向溢出，零控制台与页面错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；当前 `demo/index.html` 为 `130,665,894 bytes`。
- Kimi K3 剪辑：按官方宣传片案例的代理式剪辑方法，让本机 `kimi 0.30.0` / `kimi-code/k3` 检查全景、角色帧与临时音乐，完成镜头选择、运动匹配、节拍对齐、联系表复审和一轮证据驱动返修；输出 `10.000s / 1920×1080 / H.264 / yuv420p / 30fps / 300 帧` 静音母版及带临时 AAC 音轨的审片版。独立完整解码和三个关键节拍抽帧通过，视频暂未接入正式剧情，等待审片确认。

## 2026-08-04 校园主图、食堂动画、骑行重绘与启真湖适配收口

- 校园主图：普通宿舍、图书馆、东区食堂和剧场通行段恢复为 IonicJian 提交的 `4516 × 3420` 俯视校园图，运行图 SHA-256 为 `57e27997d0c24a77dd758869bcc1bab8665b10496a77ec0f802986461ceb116d`；剧场到启真湖继续使用独立 `13668 × 1084` 伪 2.5D 环湖衔接图。两套地图的运行清单、碰撞遮罩和验证命令已分离。
- 食堂稳定性：食堂守出口运行时在场景销毁和玩家实体释放后停止更新，食堂主场景也拒绝处理释放后的最后一帧，消除切换场景时访问空玩家 `setVelocity` 的崩溃。图书馆文学书架前景深度同步修正，人物位于书架南侧时保持前景遮挡关系。
- 推车动画：增加可追溯的 8 帧四方向推车人物源图、洋红键透明处理和确定性构建脚本；运行帧改为 8 帧循环，普通推动与冲刺分别使用 `58ms / 42ms` 帧时长，减少原 4 帧循环的抖动。
- 骑行重绘：按 Kimi K3 的先审查后执行流程，将原大型 SVG 场景替换为低分辨率 Canvas 像素渲染。骑车人物含 3 帧踏频，横穿行人含 4 帧跑步，路障、锥桶、汽车、人群、共享单车、建筑、树、路灯和纸条统一到同一像素网格；保留 `755m`、三车道、三次机会、`188 / 377 / 566m` 节点、碰撞和存档契约。
- 启真湖适配：划船人物在皮划艇内部单独缩放到 `0.72`，整船保持现有水面碰撞和操控坐标；桌面分屏与单屏任务文字居中。`390 × 844` 单屏任务栏扩展到 `362px`，任务文本保留 `230px` 可用宽度，返回、全屏、模式切换和道具栏保持可操作。
- 浏览器实测：Blink `1280 × 720` 实际启动骑行、完成左右变道并进入碰撞结算；食堂守出口持续运行且控制台错误为 `0`；启真湖桌面和 `390 × 844` 均重载检查，移动视口控制台错误与文档横向溢出为 `0`。图书馆检查点实际移动到书架站位，人物前景深度符合修正。
- 自动验证：`npm run map:zijingang`、`npm run godot:check`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。远端 `origin/main` 与本地基线均为 `4863231`，开发期间没有新增远端提交。当前 `demo/index.html` 为 `133,210,912 bytes`，SHA-256 为 `bae3907e2bbc4c1c2fcd178a36c1c0245c9f79b142ee0eb2c69c5bc3143a47db`。

## 2026-08-04 图书馆文学书架显示与遮挡修复

- 根因：用于擦除底图原书架的地板裁片深度为 `410`，高于完整书架的 `330`，运行时地板裁片覆盖书架主体；书架滑动动画又临时把书架提升到 `4300`，会覆盖站在南侧的人物。
- 修复：地板裁片固定放在完整书架下方两个深度单位；书架静止、抖动和滑动全过程统一使用基于实体底边的 `SHELF_FRONT_DEPTH`。人物继续按脚底位置更新深度，南侧人物覆盖书架，碰撞区保持不变。
- 浏览器验收：在 `c2-archived-rule` 检查点确认完整书架、盆栽、书脊和底座全部显示；人物从 `(625,355)` 移动到书架正南侧 `(547.67,251)` 后覆盖书架底沿和索书号标签，并停在碰撞边缘。技能网页游戏客户端与浏览器控制台均为 `0` 错误。
- 构建验证：`npm run typecheck`、`npm run build:single` 与 `npm run verify:single` 通过；最新 `demo/index.html` 为 `133,210,917 bytes`，SHA-256 为 `ceb81c33af06c7ba4fcf5bfb4ed71aafc273d196e0624a98bcf69002e205d5fa`。

## 2026-08-05 图书馆校准页、启真湖双帧与剧场追光演出

- 图书馆调试入口：新增 `library-shelf-debug.html` 与 `npm run dev:library-shelf`。调试页按原始 `1500 × 900` 坐标显示图书馆底图，可手动拖动或填写书架裁剪、场景位置、尺寸、地板补片深度、人物位置与缩放，并可复制校准 JSON 或 TypeScript 常量。
- 遮挡校准：调试页复用运行时 `player depth = Y + 120` 和书架前景深度 `330`，提供书架与人物切换、前后关系实时状态及 A/B 两帧细微轮换预览。Vite 独立入口在 `1440 × 900` 下完成前景和后景两种状态复验，控制台错误为 `0`。
- 启真湖划船：新增两张 `128 × 160` 透明纯俯视像素帧，人物坐在橙色皮划艇内，左右分别使用去叶树枝和三角警示牌作为桨；两帧以桨角、手臂和水花的细微差异轮换。图像差异为 `699` 个像素，运行时移动和静止间隔分别为 `150ms / 420ms`，整体显示缩放降至 `0.52`。
- 启真湖提示：场景只保留最近目标的一处交互说明，并根据人物屏幕位置动态下移固定提示，避免任务文字、船体和世界标签重叠；任务栏继续使用共享居中布局。
- 剧场追光：追光面板增加舞台框架、侧幕、移动扫描光、三轮状态灯、灯位导轨、双层脉冲圈、轨迹点、纸条呼吸帧和锁定进度；命中时播放扩散环与像素火花，失误时播放红青故障条。所有补间在面板销毁时统一停止，未改变三轮判定、存档或控制器契约。
- 单文件验收：通过 HTTP 加载本次生成的 `demo/index.html`，在 `1280 × 720` 逐一复验图书馆、启真湖和剧场，三处控制台错误为 `0`；启真湖和剧场在 `390 × 844` 下画布均为 `390 × 219.375`、保持 `16:9`，文档宽度为 `390px` 且无横向溢出。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `133,236,189 bytes`，SHA-256 为 `2d3171a41e690d739d0a0ffcf761f50527da1cd7f73be5571e9f9a1c5d597268`。

## 2026-08-05 755 米骑行改为直接剧情追逐

- 对照 `/Users/zhuhangcheng/.qoderworkcn/workspace/mrucdokos7lsy4mk/outputs/bike_rush_3d_demo.html` 与当前源码确认：三车道透视道路、骑车人物、六类障碍、三次机会、188 / 377 / 566 / 755 米节点已经在现有 Canvas 渲染器中落地，本轮集中调整进入和结算流程。
- `CanteenChaseOverlay` 进入即运行：移除 3 秒倒计时、起跑标题卡、结果卡、无尽模式入口、模式标签和最佳成绩卡；保留距离、机会、里程节点、键盘与触控换道。
- 追逐固定为一次 755 米剧情任务。失败碰撞效果结束后 0.9 秒自动恢复三次机会并从 0 米重开，不再要求玩家操作结算页；成功后 0.9 秒自动回到剧院入口剧情检查点。
- 运行时与控制器契约同步收窄到 `mode: "story"`，保留 `countdown: null` 字段供 `render_game_to_text()` 稳定读取，删除 React 宿主不再使用的完成、次数和最佳成绩展示参数。
- 验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 均通过；生成的 `demo/index.html` 为 133,229,374 bytes、2 个内联脚本、1 个内联样式，SHA-256 为 `8ecc8471862ea76fe41d7274b70a1ec37b2f1d5ac9332eecb8a488e1e3fb1bbc`。
- 桌面 `1280×720` 验收：页面载入 0.7 秒时追逐已从 0 米推进到 13 米，DOM 中起跑卡、倒计时和无尽模式文本均为 0；A / D 换道有效。保持中间车道触发三次碰撞后，画面从 267 米、2 次机会自动恢复到 128 米、3 次机会，过程中未出现结算卡。
- 755 米完整验收：开局右移到第三车道，抵达 755 米后 `chaseCompleted=true`、`chaseBestDistance=755`、`canteenChase=null`，自动进入 `campus_theater_junction`，任务切换为“在剧院逼停纸条”。
- 移动端 `390×844` 触控验收：追逐画面保持 `390×219.375` 的 16:9 尺寸，文档无横向或纵向溢出，左右按钮均为 `42×42`；点击右移后按钮正确进入最右车道禁用状态。桌面、移动端页面错误均为 0。

## 2026-08-05 755 米骑行校园路人和旁白

- 生成与审校：通过本机 `kimi-code/k3` 为食堂到剧院的 755 米骑行段设计路人分布与四段短旁白；安装并立即验证开源 `human-writing 1.1.0`，旁白检查结果为 `90` 个汉字、覆盖规则的失败与警告均为 `0`。
- 场景路人：人行道新增看手机赶路、两人边走边聊、端豆浆驻足和推共享单车四类校园路人；按世界距离确定性分布在道路两侧，远近缩放随道路透视统一变化，不参与车道碰撞。
- 双帧演出：四类路人各有两张程序化像素帧，依据世界距离轮换；启用减弱动态时固定首帧。路人绘制层位于建筑前、道路障碍后，保持骑车人物和横穿障碍的判定可读性。
- 旁白触发：开局、`188m`、`377m`、`566m` 各触发一次短旁白，分别对应四类路人；旁白只属于本次追逐的表现状态，暂停、重试、胜利和卸载时均会正确清理，不写入正式存档。
- 完整流程：自动规避障碍实跑到 `755m`，依次记录 `start / m188 / m377 / m566` 四段旁白，最终状态为 `won`、三次机会、零碰撞，页面与控制台错误为 `0`。
- 跨内核验收：Blink、Gecko、WebKit 均在 `1280×720` 和 `390×844` 载入追逐、显示 `6` 个可见路人并完成一次右换道；桌面隐藏触控键，移动端显示两个触控键，六种组合均无文档溢出、控制台错误或页面错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `133,234,366 bytes`，SHA-256 为 `bec66060f061cbf1e28974e68d0f31f4bb3bc183f1ee49eefb31043f2832acd2`。

## 2026-08-06 启真湖码头左右桨场景化拾取

- 拾取状态：码头装备从一次串行领取拆为皮划艇、柳树枝左桨和旧三角牌右桨三个独立事实；任意顺序可拾取，只有三件齐全才进入 `boarding_tutorial` 并解锁上船点。宿主对桨类型进行白名单校验，无效的桥接载荷不会写入进度。
- 场景融合：皮划艇继续使用救生圈旁的实景器材架；左桨作为临水花坛边的细枝，右桨作为码头设备区的旧三角牌。两个动态物件按原图投影、像素密度和光照方向绘制，远距离时不显示名称或光圈，只在玩家进入可交互距离后显示低强度反馈。
- 提示流程：任务抽屉和码头状态按未收集的实物逐步提示，交互文案分别为确认皮划艇、拾取柳树枝、拆下旧三角牌；删除“装备已取齐”的提前表述。
- 完整验收：同一 Blink 会话从 `(330,830)` 实际行走至器材架、柳树枝和三角牌，三次拾取后状态依次为 `[true,false,false]`、`[true,true,false]`、`[true,true,true]`；最后实际行走到码头前端上船，进入 `vehicle=kayak / phase=boarding_tutorial`。全链路页面与控制台错误为 `0`。
- 跨内核与移动端：Blink、Gecko、WebKit 在 `1280×720` 均进入 `qizhen_lake / dock_outfitting`，画布 `1280×720`，文档溢出和错误为 `0`；iOS WebKit `390×844` 识别为粗粒度指针，画布保持 `390×219.375` 的 `16:9`，显示触控操作区，无文档溢出和页面错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `133,237,129 bytes`，SHA-256 为 `ddfa8c6e87d317a32ee53dc5441df87b2aae08ab49741a4adb73238b197512fc`。

## 2026-08-06 启真湖码头空气墙、遮挡与三角牌底图切换

- 空气墙：器材架碰撞从覆盖整件立面改为只覆盖落地底座 `kayak_rack_base`；同一会话中人物从入口绕至架后 `(523,726)`，确认原先阻挡的铺装区域可以通行。
- 前后遮挡：新增器材架前景裁片 `kayak_rack_front`，人物脚底位于架后时启用前景覆盖，移动到架前 `(523,874)` 后解除覆盖；碰撞和视觉深度共用同一组源图坐标。
- 三角牌状态：在原始码头图上局部生成无牌版本，除 `92 × 137` 的牌体与投影区域外不改动场景；拾取右桨前使用原图，拾取后切换无牌底图并同步全部前景裁片，删除运行时重复绘制的三角牌。
- 完整验收：Blink `1280 × 720` 从启真湖入口实际进入码头、绕过器材架底座并拾取右桨，状态从 `dockSignRemoved=false` 切换为 `true`，右桨目标同步消失，架后与架前截图均完成检查，控制台和页面错误为 `0`。
- 跨内核与移动端：Gecko `1366 × 768`、WebKit `1280 × 720` 与 iOS WebKit `390 × 844` 均通过真实空格交互进入 `qizhen_lake / dock`；三种场景均无文档溢出、控制台错误或页面错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `136,619,294 bytes`，SHA-256 为 `929edecada25c923c347eaa2ba41152df65d7f9f143fae37fae0046bec0c79c0`。

## 2026-08-06 启真湖直河道抵达终点自动通过

- 通关条件：黑天鹅追逐改为抵达河道左端 `x≤190` 后立即完成，不再要求终点再次按空格；任务配置、场内提示和船体状态栏均明确显示“左端抵达即通过”。
- 难度调整：删除黑天鹅逐步缩短距离和追上船尾强制翻船的判定，追逐表现改为固定安全跟随；左右同侧连续划桨和撞击河岸的既有平衡规则继续生效。
- 河道贯通：追逐阶段的浮排与旧网栏保留画面和前后遮挡，但不再作为实体阻断水路；普通探索阶段仍读取原始碰撞数据。运行调试状态同步输出实际追逐碰撞列表和终点坐标。
- 完整流程：Blink `1280×720` 从 `c3-qizhen-chase` 仅用真实 `A/D` 左右桨输入，从 `(1390,505)` 抵达左端并自动切回小码头；最终 `phase=complete`、`zone=dock`、`transitionReady=true`，全过程未发送空格键，页面与控制台错误为 `0`。
- 跨内核与移动端：Blink `1280×720`、Gecko `1366×768` 与 iOS WebKit `390×844` 均完成八次左右桨输入，人物前进约 `450px`，追逐碰撞列表均只保留世界边界、南北河岸和右侧码头；三种环境均无文档溢出、控制台错误或页面错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `136,619,790 bytes`，SHA-256 为 `feb1293aaf0bf7ab185272ac274eea32ab8647ac022b1356957c825d3e31f756`。

## 2026-08-06 755 米校园骑行画面整体重构

- 视觉层级：删除近景建筑墙、密集路人、分散距离卡与机会卡，重构为中央三车道、两侧人行道、稀疏树列、路灯和低对比校园远景；纸条、六类障碍、骑手与自行车统一使用同一透视和像素颗粒。
- 清晰度与动势：桌面画布恢复原生 `960 × 540` 绘制精度，取消半分辨率二次放大；障碍可视距离扩展到 `240m`，路人间距从 `24m` 调整到 `52m`，骑手缩放与车道中心重新校准，保留踏频、换道倾斜、道路标线运动和碰撞闪烁。
- 状态界面：距离、`188 / 377 / 566m` 节点、进度和三次机会合并为一条顶部进度轨；旁白改为左下短字幕，键盘换道提示固定在底部，移动端保留两个独立触控按钮。`755m`、三车道、三次机会、碰撞和自动进入剧院衔接点的规则未改变。
- 完整流程：Blink `1280 × 720` 实际完成左移、右移、主动碰撞一次、后续动态避障与 `755m` 结算；碰撞后机会从 `3` 降为 `2`，最终 `chaseCompleted=true` 并进入 `campus_theater_junction`，页面与控制台错误为 `0`。
- 跨内核与移动端：Gecko `1366 × 768`、WebKit `1180 × 820` 与 iOS WebKit `390 × 844` 均完成载入和换道；移动端两个触控按钮可点击，四种环境均无文档横向或纵向溢出、控制台错误或页面错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `136,616,888 bytes`，SHA-256 为 `f5bf0e6696634732c44e0e0785f8cef166033289976ea16565ae69731e305d25`。

## 2026-08-06 启真湖黑天鹅动态追逐恢复

- 根因：上一轮降低直河道难度后，黑天鹅被固定在船后 `135px`，船与黑天鹅长期保持相同相对位置，画面缺少逼近变化。
- 追逐表现：黑天鹅按 `3.2s` 周期在约 `210px` 至 `112px` 间往复逼近，并沿船尾横向追踪；逼近强度同步控制扑翼频率、体型变化和三层水面尾迹。减弱动态模式继续关闭高频扑翼。
- 难度边界：黑天鹅不会触发强制翻船或额外失败条件；玩家保持左右交替划桨，到达河道左端后立即通过。左右同侧连续划桨和河岸碰撞仍沿用皮划艇基础规则。
- 完整流程：Blink `1280×720` 使用真实 `A/D` 输入完成全段逃离，最终为 `phase=complete`、`zone=dock`、`transitionReady=true`、`magneticAttachmentBroken=true`；未增加终点交互步骤。
- 跨内核与移动端：Blink、Gecko、WebKit 的远距帧约为 `209px`，逼近帧约为 `114px`，三种内核均无页面错误、控制台错误和文档溢出；iOS WebKit `390×844` 使用左右桨触控完成全段逃离并进入相同完成状态。
- 构建验证：网页游戏客户端、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `136,617,825 bytes`，SHA-256 为 `c73bab3fe1cdac68f9da7eb65b5b11b24d74346265ac79a8d05f41428a7001a9`。

## 2026-08-06 图书馆书架多帧开启与前台两帧角色

- 书架演出：文学书架开启改为 `13` 个离散像素阶段，先以 `0 / -2 / 1 / -1 / 0px` 轻微变化，再按 `2px` 递增缓慢横移到 `16px` 终态；每帧持续约 `120–190ms`，机械夹层随位移逐步显现，碰撞边界和人物遮挡同步使用当前帧坐标。
- 减弱动态：启用 `prefers-reduced-motion` 时直接进入终态帧并保留纸张出现，避免持续动画；旧存档恢复到已完成状态时固定为第 `13/13` 帧。
- 校准入口：`library-shelf-debug.html` 从两帧轮换升级为完整 `13` 帧预览，继续支持手动调整裁片、终态偏移、帧间隔、人物位置和前后深度；实测状态从第 `4/13` 帧、`-1px` 过渡到第 `9/13` 帧、`8px`，无页面错误和文档溢出。
- 前台角色：信息台新增一名 `96×128` 双帧前台工作人员，低头登记与抬头翻页缓慢轮换；柜台前景按源图坐标单独回绘，角色下半身由柜台遮挡，玩家位于柜台前时继续覆盖角色。生成源图保留在 `src/assets/rpg/npcs/library/source/`，运行图为透明 `192×128` 双帧表。
- 完整流程：Blink、Gecko、WebKit 均记录到前台第 `2` 帧，控制台与页面错误为 `0`；iOS WebKit `390×844` 同样完成两帧切换，无文档溢出。书架道具在移动 WebKit 中通过真实触控拖动，状态依次到达第 `8/13` 帧 `6px` 和终态 `16px`，旧规则纸张成功取得且索书号被消费。
- 构建验证：网页游戏客户端、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `136,657,287 bytes`，SHA-256 为 `9c916ef5bc8d292ec3b71b9273c22c395b5fa7e1079d0948604c8424955371e2`。

## 2026-08-07 图书馆前台人工核验与敲章

- 用户反馈：删除左侧独立盖章机，将物品识别报告的核验、盖章和结果交付放到前台 NPC 上。
- 交互契约：`itemRecognitionReport` 的拖拽目标由 `lost_found_machine` 改为 `front_desk`，高亮框缩到工作人员与柜台之间，并保留柜台前的明确站位。
- 场景表现：独立盖章机已移除；前台 NPC 使用既有两帧立绘完成接件、低头核验和敲章动作，柜台上同步播放报告滑入、三项核验灯、手持印章落下、红色“非本人”章和凭证返回动画。
- 提示规则：报告未生成、可递交、核验中和已盖章四种状态均由前台给出对应反馈；核验期间不再显示无效空格键提示。
- 完整验收：在 `c2-nonperson-stamp` 检查点通过真实 Pointer 拖拽将报告交给前台工作人员，运行状态依次为 `checking / stamping / complete`；前台角色在核验和敲章时使用第 2 帧，结束后恢复第 1 帧。报告被消耗，书包非本人证明成功发放。
- 跨内核与移动端：Blink `1280×720`、Gecko `1366×768`、WebKit `1180×820` 与 iOS WebKit `390×844` 均完成同一拖拽和敲章流程，四种环境无文档溢出、控制台错误或页面错误。
- 文案同步：浙大钉恢复材料、道具目录、开发检查点和第二章开发文档已统一使用“前台工作人员人工核验与盖章”，删除现行流程中的登记机目标引用。

## 2026-08-07 启真湖码头人物遮挡校准

- 将码头前景的纵深排序线从整张裁片下沿改到北侧立柱形成遮挡的位置。
- 人物走到码头南端上船位后保持完整显示；人物处于北侧立柱后方时继续保留前后遮挡。
- 浏览器验收：在 `c3-qizhen-boarding` 检查点实际移动到 `(680,635)` 的码头上船目标，`activeOcclusionIds` 与 `softenedOcclusionIds` 均为空，人物完整显示；继续向北移动到 `(680,423)` 后码头前景重新进入两组遮挡状态。
- 构建验证：网页游戏客户端、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `136,657,022 bytes`，SHA-256 为 `40df73bb0d3122c979e317e35a219255d3b993d159425e019a6876951a0769c0`。

## 2026-08-07 剧场、启真湖与环湖反馈增强单文件打包

- 打包范围：将剧场交互 marker、任务更新字幕、反馈排队与 speaker 标签，启真湖装备提示、拖放落点、配置化文案与沉默路径反馈，以及环湖过渡逐句字幕和入口指引一并编入离线单文件。
- 自动验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；单文件包含 `2` 个内联脚本和 `1` 个内联样式。
- 浏览器验收：通过本地 HTTP 从生成后的 `demo/index.html` 分别进入 `c3-theater-program`、`c3-qizhen-dock` 和 `c3-qizhen-transition`。三处均生成 Phaser 画布，运行状态分别落在剧场节目搜索、码头装备收集和剧场后环湖过渡，页面与控制台错误为 `0`。
- 最终产物：`demo/index.html` 为 `136,674,943 bytes`，SHA-256 为 `454783283d1ba3df1b9bfb7dbb455c1f24059bd5411dc3686229d8b86bc956d9`。

## 2026-08-08 终章三名 NPC 立绘与动作图集整合

- 规格落地：按《段永平教学楼时间回溯关卡》实现远处离楼学生、保洁员、清楼保安三套角色形象，覆盖学生行走/看手机/整理背包/推门、保洁推车/拖地/放警示牌/关灯/休息、保安巡查/核表/看表/手电引导/对讲机共 `17` 套动画资源。
- 资产生产：三张生成源图保留在 `src/assets/rpg/npcs/finale/source/`；`scripts/build-finale-npc-atlases.mjs` 统一去除背景、等比缩放、脚底锚定并生成透明运行图集与 SHA-256 manifest，未手工修改生成后的单帧。
- 运行接口：新增 `FinaleNpcTextures.ts`，向 Phaser 兼容层提供统一预加载和动画注册，同时保留 JSON manifest 供 Godot 与后续终章场景读取；清洁车、宽动作使用独立帧宽，避免挤压人物比例。
- 调试入口：新增 `finale-npc-debug.html` 与 `npm run dev:finale-npcs`，可实时查看全部动画、FPS、帧尺寸、透明背景与脚底基线，并可在 `1×–3×` 之间调整像素预览倍率。
- Godot 同步：终章运行图集和 manifest 已加入 `scripts/sync-godot-rpg-assets.mjs` 的哈希同步清单，目标路径为 `godot/assets/rpg/npcs/finale/`。
- 导出验证：使用仓库锁定的 Godot `4.7.1` 完成 Web 重新导出；最终校验为 `assets=33`、`webBuild=matched`，新增图集已进入 Godot 导入与 Web 打包流程。
- 浏览器验收：独立预览页在 Blink `1280×720` 与 `390×844` 均加载 `17` 张动画卡，全部图片可用，动画帧实际发生切换；两种视口文档宽度分别等于 `1280` 与 `390`，无横向溢出、页面错误或控制台错误。临时桌面和移动截图检查后删除。
- 构建验证：`npm run art:finale-npcs`、`npm run godot:export:web`、`npm run typecheck`、`npm run build` 与 `git diff --check` 通过。

## 2026-08-08 终章教学楼环境母图与人物合成检查

- 需求修正：上一轮只覆盖三名真人角色，缺少楼梯、楼层与终局教室等环境资产；本轮按终章规格补齐启真湖至教学楼拱廊、一楼门厅与迈斯威、楼梯间、电梯竖向交通核、二楼开放自习与活动区、N3-214 智慧教室共 `6` 张环境母图。
- 投影边界：拱廊序幕使用规格允许的伪 `2.5D` 低机位侧视；五张室内图统一使用俯视正交像素视角。所有母图固定为 `1672 × 941`，人物、湿纸条、清洁车、签到板、电梯门与轿厢、卷帘、时间残影、晨光和扫描器继续保留为动态运行层。
- 资产契约：新增 `finale_environment_manifest.json` 与 `FinaleEnvironmentTextures.ts`，记录场景职责、投影、时间单元、动态层、源尺寸和 SHA-256；`npm run art:finale-environments` 会检查六图尺寸并重建清单。
- 合成调试：新增 `finale-environment-debug.html` 与 `npm run dev:finale-environments`，可切换六张环境、叠加全部终章 NPC 动作、点击或拖动人物设置源坐标、调整人物倍率并显示源坐标网格。
- Godot 同步：六张母图与环境 manifest 已进入统一哈希同步清单，并使用 Godot `4.7.1` 实际重新导入和导出；最终校验为 `assets=40`、`webBuild=matched`。
- 浏览器验收：Blink、Gecko、WebKit 均逐一切换并加载六张 `1672 × 941` 环境图，角色动画发生帧切换，页面与控制台错误为 `0`；`390 × 844` 移动视口文档宽度等于 `390`，无横向溢出。桌面与移动截图检查后按规则清理。
- 构建验证：`npm run art:finale-environments`、`npm run typecheck`、`npm run build`、`npm run godot:export:web` 与 `git diff --check` 通过。
- 后续边界：本轮完成环境与人物美术资产整合；终章 Godot 场景树、源像素碰撞、前景遮挡、时间轨迹、电梯逻辑和剧情控制器仍待下一阶段实现。

## 2026-08-08 第四章序幕过场「纸条进入段永平教学楼」

- 触发与收尾：`qizhenLake.phase === "complete"` 且 `chapter4.prologueSeen === false` 时，首次停留在启真湖画布即播放约 55 秒序幕过场；收下任务卡后由 `ChapterFourPrologueController.completePrologue()` 在保留完整 `GameState` 的前提下回到手机主页进入第四章，未使用 `createInitialGameState()` 兜底。
- 状态与存档：`GameState` 新增 `chapter4: { prologueSeen }` 并持久化；`SaveStore` 以 `normalizeChapterFour` 兼容旧存档（缺失字段回退为未看，老玩家完成启真湖后补看一次过场）。
- 演出实现：新增 `src/scenes/rpg/Chapter4PrologueOverlay.tsx` 与 `src/scenes/rpg/chapter4-prologue/`（共享时间线 `PrologueTimeline.ts` + 像素 canvas 渲染器 `PrologueRenderer.ts`），沿用食堂追逐的「React 覆盖层 + canvas 渲染器」模式；六段分镜为磁扣裂纹与断线弹回、纸条滑水/撞栏杆/翻转/落石板/二次卷起、拱廊穿行（柱影变暗/灯光带湿反光/台阶折起/横风推进）、学生看手机肘推玻璃门与电子钟 `22:44:57 → 22:45:00`、门厅湿地滑行（带走窄水膜、留下干燥轨迹）与保洁员台词、广播电流声/保安台词/分两批关闭照明。
- 音频契约：新增 `src/data/chapter4-prologue.audio.json` cue 时间线并注册进 `AudioDirector` 与 `PresentationDirector`；引用并行生成的 `src/assets/audio/chapter4/prologue/` 资产（`sfx_ch4_*`、`vo_ch4_prologue_*`、`music_ch4_prologue_night_pursuit`），文件缺失时照常播放画面不阻塞剧情。四句配音台词经 `src/data/chapter4PrologueStory.ts` 注册进故事线目录，`subtitleSurface: "scene"` 保证中文字幕只有过场字幕一个归属表面；`StoryLine` 的 speaker/voiceRole 联合类型按内容清单扩展了玩家、保洁员、保安三类小角色。
- 跳过/重播：过场中可点「跳过过场」或按 `Esc` 直达任务卡（发 `chapter4_prologue_skip` 取消排队音效并停止在播人声）；任务卡提供「重播过场」纯表现层重播；中途切回手机发 `chapter4_prologue_closed` 停音乐与人声，下次进入湖区重新播放。
- 开发检查点：新增 `c4-prologue`（启真湖完成态直达过场）与 `c4-prologue-done`（序幕已看的第四章起点），均复用 `c3-qizhen-complete` 的完整 quest/item/scene 事实种子。
- 文本登记：8.1 全部台词、电子钟读数、迈斯威方向牌与任务卡文案已按既有体例补入《剧情与提示文本总表.md》。
- 浏览器验收：离线单文件经本地 HTTP 以 `?devCheckpoint=c4-prologue` 直达过场；覆盖层与像素画布正常挂载，六段分镜截图抽查到位（门厅湿地干痕、清楼关灯与手电、任务卡完整文案），四条中文字幕按时间线轮换且归属过场字幕表面。实时走完 + `window.advanceTime` 快进两条路径均到达任务卡；「重播过场」重置后「跳过过场」直达任务卡，「收下任务，进入第四章」后 `runtimeMode=phone`、`currentScene=phone_home`、覆盖层卸载，全程控制台零错误。过场期间音频资产尚未生成，运行按契约静默降级、不阻塞剧情。
- 存档兼容：开发检查点会话不写正式存档（既有规则）；正式流程存档包含 `chapter4` 字段。手工删除存档中的 `chapter4` 模拟旧存档后重载，水合恢复 `prologueSeen: false` 且场景正常，无控制台错误。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `139,937,326 bytes`，SHA-256 为 `712ad5335d4a9174036ef5a03c42ffec50d18f207d75aba04141baa8b5eeb176`（含已生成的第四章序幕全部音频资产）。

## 2026-08-08 剧场生成美术正式接入

- 原始需求：将已生成的检票员、舞台管理员残影、纸条状态、剧场道具和追光特效真正接入剧场运行时。
- 资源落盘：四张生成源图已保存在 `src/assets/rpg/theater/source/`，保留原图作为可追溯输入。
- 可复现加工：新增 `npm run art:theater`，从源图确定性裁切、去除绿色背景、最近邻缩放并生成 `47` 个透明运行资源和 SHA-256 manifest。
- 正式运行时：Godot 剧场已接入检票员站立/扫描帧、三张节目单碎片、票根隐藏标记、`0832` 屏幕残影、节目单背面顺序、舞台管理员与道具箱蓝青残影、纸条未来路径，以及飞行、残影、荧光粉、锁定、破裂、替身和逃逸状态。Phaser 单文件兼容场景使用同一套运行资源与阶段显隐规则。
- 道具图标：半张票根 A/B、临时观演票、三张节目单残页、追光灯遥控器、荧光粉刷、假纸条和湿节目单共 `10` 个道具改用生成后的像素图标；其他道具继续使用既有 SVG 映射。
- 追光表现：正式与兼容运行时均绑定灯光束、命中扩散环、像素火花、失误故障条和纸条反转序列；Godot 观察阶段残留空白按钮边框的问题一并修复。
- Godot 导出：`npm run godot:export:web` 使用锁定的 Godot `4.7.1` 实际重新导入并导出，校验结果为 `assets=88`、`targets=11`、`collisions=27`、`webBuild=matched`。
- 浏览器验收：Blink `1280 × 720` 分别进入 Godot 正式场景和 Phaser 兼容场景，核对入场检票、节目单碎片、浅/深模式切换、管理员与道具箱残影、追光观察/锁定/命中/失误，以及纸条锁定、破裂、碎片和逃逸序列；Godot 调试状态确认对应 art 显隐值，命中轮次从 `0` 推进到 `1`，故障理由为 `early`，所有检查页面与控制台错误为 `0`。
- 视口验收：Godot 内嵌画布保持 `16:9`；Blink `1440 × 900` 和移动触控视口 `390 × 844` 均无文档横向或纵向溢出，移动端保留方向键、空格键和完整道具栏。
- 构建验证：`npm run art:theater`、`npm run godot:export:web`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最终 `demo/index.html` 为 `140,237,696 bytes`，SHA-256 为 `86421a4769176d275ac560c4a0cf23b41a672a567bbc53cb36041d15d09c23b7`。

## 2026-08-08 第四章序幕亮色像素场景与连续转场修正

- 问题复核：实机抽查确认旧 `PrologueRenderer` 仍以大面积深色程序绘图作为六段过场背景；已生成的场景母图没有进入运行时，画面亮度和像素风均未达到当前要求。
- 场景接入：新增 `PrologueVisualAssets.ts`，将磁扣断裂、离开湖面、拱廊、教学楼入口、门厅与清楼六组 A/B 双帧场景图接入画布；场景图只承担环境，湿纸条、磁扣、学生、保洁员、保安、手电和熄灯继续作为动态层。
- 像素加工：新增 `npm run art:chapter4-prologue`，把 `1672×941` 源图统一压到 `480×270` 像素网格，提亮暗部、限制为 `72` 色，再以最近邻放大到 `960×540`；生成的 `pixel/` 目录作为运行图，源图继续保留为可追溯输入。
- 转场契约：相邻分镜以 `260ms` 像素块揭示连接；离湖与拱廊使用同方向横向出入，进入门厅使用门缝中心展开，清楼使用交错灯区切换。每个分镜保持纸条的运动方向、落点和画面内出入口一致，不再叠加黑屏淡入。
- 双帧演出：每组 A/B 帧按 `2200ms` 离散轮换，关闭 Canvas 平滑；`prefers-reduced-motion` 固定 A 帧并跳过动态揭示。
- UI 明度：过场底色、跳过按钮和任务卡改为明亮蓝绿/米色像素面板；清楼阶段仅用最高 `16%` 的分区蓝色遮罩表达关灯，避免整屏压黑。
- 浏览器抽查：Blink `1280×720` 实际查看启真湖首镜、拱廊和门厅三个关键节点；画面为硬边低色阶像素效果，湖面和门厅保持可读亮度，字幕与任务栏不遮挡纸条路径，控制台错误和警告为 `0`。Blink `390×844` 保持 `960×540` 横屏场景比例并无文档溢出。
- 最终验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；生成后的 `demo/index.html` 经独立本地 HTTP 打开 `c4-prologue` 检查点，画布存在、错误边界为空、文档宽度与 `1280px` 视口一致，控制台错误与警告为 `0`。单文件为 `141,366,738 bytes`，SHA-256 为 `3d5005ee8cb29ba6bc19aae80236a4cb041ce808e64f47a317482cf75e7f3eb0`。
- 跨内核补验：Firefox `1366×768` 与 WebKit `1180×820` 均加载 `960px` Canvas、错误边界为空且无文档横向溢出，控制台错误为 `0`。Firefox 单文件路径产生浏览器自身的 AudioContext/媒体自动播放限制提示与一次 WebGL 上下文切换提示，过场 Canvas 已回退为 2D 且画面正常；WebKit 源码预览无警告。

## 2026-08-08 第四章序幕 Flash 式图层动画与立绘接入

- 问题定位：上一版虽然接入六组场景图，但 A/B 帧以整幅画面轮换，人物仍由简化色块绘制，已生成的学生、保洁员、保安动作图集和 A/B 对话立绘没有进入序幕。
- 动作图集：`PrologueVisualAssets` 预加载 `FINALE_NPC_ANIMATIONS` 的 `17` 组透明图集；序幕实际调用学生行走/看手机/整理背包/推门，保洁推车/拖地/待机/放警示牌/关灯，保安巡查/看表/手电/对讲机。所有帧按 manifest 的独立帧宽、FPS 和脚底锚点裁切，没有使用统一宽度挤压人物。
- 对话立绘：`npm run art:chapter4-prologue` 现在同时从六张原始立绘去除洋红幕、等比缩放并统一输出到 `portraits/finale/runtime/`。学生推门段使用学生 A/B 反应切入，保洁员和保安说话时分别显示自己的 A/B 立绘，立绘帧以 `680ms` 低频切换。
- Flash 式转场：删除 `260ms` 整图像素块揭示。湖面到湖岸使用纸条落点的扩展涟漪和摄像机推近；湖岸到拱廊用横向经过的石柱遮挡；拱廊到入口以亮门开口推近；入口到门厅使用双扇玻璃门从中心滑开；门厅到清楼使用侧门墙体遮挡。纸条水平运动方向在连续镜头中保持一致。
- 环境双帧：A 帧作为稳定背景，B 帧只以最高 `24%` 的周期环境变化叠加，不再每 `2200ms` 切换整幅画面。减弱动态模式固定 A 帧并保留可读的瞬时切换。
- 浏览器验收：使用网页游戏客户端每 `4s` 快进一次，完整覆盖约 `52s` 时间轴；再对五个转场边界分别抽取连续三帧。学生、保洁员、保安的场内动作和三组立绘均在实际覆盖层中可见，任务卡正常到达，页面与控制台错误为 `0`。本结论完成 `2` 组独立验证：全时间轴等间隔抽帧与转场边界抽帧。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `142,661,023 bytes`，SHA-256 为 `70f725ef18ce38f1fce3c259da42b5cffbf1a747c8751c55ec922796e2f1a95a`。

## 2026-08-08 第四章序幕 DEV 分镜节点

- DEV 章节导航补上「第四章」，并将序幕独立成「序幕演出」玩法段落。
- 新增七个可直达节点：磁扣断裂 `0ms`、离开启真湖 `4200ms`、夜间拱廊 `12400ms`、学生推门 `24400ms`、门厅湿地 `32400ms`、清楼关灯 `44200ms`、新任务卡 `51600ms`。
- 检查点把起播时间保存在会话级开发状态；正式存档仍只保存控制器认可的剧情事实。切换非序幕检查点或恢复进入前存档时会清理该开发起播时间。
- 序幕播放器可从指定时间初始化画面、字幕、人物立绘与任务卡，并预先标记过去的音频 cue，避免从中段进入时集中补播前序音效。
- 浏览器验收：Blink `1280×720` 逐项打开七个直达 URL，`data-initial-elapsed-ms`、会话 offset 与目标时间全部一致，任务卡仅在 `51600ms` 节点直接显示；控制台与页面错误均为 `0`。DEV 面板实际切到「第四章 → 序幕演出」，八个序幕相关入口全部可见，点击「清楼关灯」后覆盖层即时重挂载到 `44200ms`。生成后的 `file://demo/index.html?dev=1&devCheckpoint=c4-prologue-task-card` 也已直开验证，任务卡、DEV 面板与 `51600ms` 起播状态均正常。
- 兼容验收：Blink `390×844` 的第四章 DEV 面板右边界为 `372px`、文档宽度为 `390px`，无横向溢出；Firefox `1280×720` 的拱廊节点正确从 `12400ms` 起播且错误为 `0`。本机缓存的 WebKit 可执行文件与当前系统 WebKit ABI 不兼容，本轮未形成新的 WebKit 运行证据；同一序幕覆盖层在前一轮已通过 WebKit 完整加载检查。
- 构建验证：网页游戏客户端、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过。最新 `demo/index.html` 为 `142,662,809 bytes`，SHA-256 为 `46ee106506e8eb28d54e9d1ac9ba4502f4c906dcb29e48724b81f7563605b65d`。

## 2026-08-08 第四章 A1 气流与错位楼梯可玩切片

- 规格审计：完整核对终章开发稿的六层拓扑、两轮循环、13 个谜题、NPC 调度、交通能力和终局条件；新增 `docs/plans/2026-08-08-chapter4-temporal-maze-gap-audit.md`，明确当前只有谜题一和谜题七形成真实交互闭环。
- 章节状态：`ChapterFourState` 补齐阶段、循环、模式、楼体/楼层/房间、楼内时间、13 个谜题、线索、锚、替身、重置、终局码，以及楼梯回声、旋转角度和对齐结果；`SaveStore` 同步完成安全归一化。
- A1 流程：序幕确认后直接进入 `duan_yongping_temporal_maze / c4_a1_lobby`；深色模式记录断续水迹，浅色模式借迈斯威暖风恢复风路并推进主电梯厅。实机验证出生点为 `(834,690)`，气流观察从 `arrival` 推进到 `airflow_overlay`。
- 楼梯结构：重新生成 A1 西楼梯与独立楼梯间底图，移除梯段轴线尽头的房门；消防门位于侧向平台，上下梯段以开放楼梯井连续表达，服务升降梯机械墙保留为声学线索。
- 错位楼梯玩法：新增纪念碑谷式受控空间对齐切片。B3 先在深色模式记录下方空调低频，浅色使用 `A/←` 与 `D/→` 以 90° 步进旋转中央楼梯段；只有 90° 竖向端点对齐后，空格触发人物通过动画并写入 `c4_b2_activity`、`phase=multicam_video_edit` 与第 7/13 项完成事实。
- DEV：新增 `c4-stair-echo`，保留 `c4-arrival`、`c4-airflow`、`c4-main-elevator` 与 `c4-clock-calibration`，每个节点写入真实章节事实。
- 自动验证：`npm run chapter4:validate-topology`、`npm run art:finale-environments`、`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 通过；拓扑为 `6 floors / 5 connectors / 13 puzzles`。
- 浏览器验收：Blink `1280×720` 真实完成 B3 深色回声→浅色旋转→端点对齐→B2 通过，状态从 `stairRotationQuarterTurns=0` 变为 `1`，最终 `stairAlignmentSolved=true`、检查点为 `c4_b2_activity`；A1 气流交互再次通过，页面与控制台错误为 `0`。Blink `390×844` 的文档尺寸等于视口，RPG 画布保持 `16:9` 且无页面溢出。Gecko、WebKit 与完整 13 谜题流程仍待后续验收。
- 单文件产物：`demo/index.html` 为 `157,370,389 bytes`，SHA-256 为 `5e8a1fee0977b20d61fa273c506514c2a8d5e54ba02ce369fb976ca080aef310`。

## 2026-08-08 第四章楼梯间 3D 空间解谜独立 Demo

- 用户否决上一版二维楼梯旋转切片；本轮停止扩展其他终章剧情，只制作可单独打开的真实 3D 楼梯间解谜。
- 关卡数量按当前拓扑固定为 `2`。A 关升级为入口横移台、中央旋转梯、出口升降台三件联动，共 `36` 种组合；B 关升级为下层旋转梯、中层升降台、上层旋转梯、出口横移台四件联动，共 `144` 种组合。
- 新增 Three.js 正交 3D 场景、真实踏步几何、平台与立柱遮挡、射线点击、机关缓动、人物四肢步行动画、路径通行、关卡切换和 `2/2` 终局界面。
- 操作覆盖点击机关、`Q/E` 或左右方向键调整、`B/Tab` 切换机关、重置、全屏和移动端触屏按钮。主通行按钮已移除；点击场景会选择最近的前向路线点，断路时人物走到当前可达边缘并停下，通路完整时走到点击位置或出口；`Space` 仅保留为键盘等价操作。
- 独立源码入口为 `chapter4-monument-stair-demo.html`；`npm run build:chapter4-stairs3d` 生成不引用外部脚本或样式的 `demo/chapter4-monument-stair-demo.html`，不改写主游戏 `demo/index.html`。
- 网页游戏客户端完成断路点击、A 关三机关、B 关四机关和两关连续通关：断路点击后人物停在 `maxReachablePathIndex=1`，完整流程最终为 `phase=all_complete`，七个机关全部 `aligned=true`，控制台错误为 `0`。
- Playwright 在 `390×844` 逐一触发三类触屏机关并直接点击场景完成 A 关；RPG 面板保持 `16:9`，文档宽高与视口一致、无溢出、页面及控制台错误为 `0`。B 关四个机关标签在窄屏内完整换行显示。
- 生成单文件通过独立静态服务器复验：完整键盘流程到达 `2/2`，点击断路流程停在边缘，控制台错误与警告均为 `0`。最终独立产物为 `3,318,940 bytes`，SHA-256 为 `61292d8857b722b17bee3b577498f23f53ce498e0d935aaad31e676979453cf1`。
- 验证边界：`npm run build:chapter4-stairs3d` 与独立 `typecheck` 通过；仓库主 `npm run build:single` 被工作树中已删除的 `src/assets/rpg/campus/zijingang_campus_plate.png` 阻断，本轮没有恢复、替换或覆盖这项主线资产改动。
- 当前定位为独立原型。尚未接入正式楼层进入判定、`GameState`、存档、任务或 Godot；获得玩法确认后再将每个楼梯间映射为一个独立关卡与完成事实。

## 2026-08-08 第四章序幕纸条高度与风迹增强

- 飞行轨迹：离湖二次卷起、夜间拱廊、教学楼入口、门厅侧门与清楼环廊五段的纸条中心线整体上移，并增加分段升力和上下浮动；纸条阴影单独投到更低的位置并随离地高度变淡，画面可直接读出纸条悬空状态。
- 风迹表现：新增共用像素风迹渲染，包含五条连续风带、深蓝轮廓、青白风芯与方形风粒；灯光反射、湖岸石板和门厅湿地等高亮背景下仍保持可辨识。
- 降级一致性：生成场景母图与程序绘制备用场景均使用同一飞行高度和风迹规则，资源加载失败时不会退回贴地飞行。
- 浏览器逐帧验收：网页游戏客户端在 Blink 中抽查 `10000ms` 离湖、`18000ms` 拱廊、`28500ms` 入口和 `47000ms` 清楼四帧；运行母图正常加载，纸条与地面/人物脚线保持高度差，风迹在四种背景中清楚可见，页面与控制台错误为 `0`。同一轮另行检查程序绘制备用画面，轨迹与风迹均存在。
- 验证边界：`npm run typecheck` 通过；`npm run build:single` 仍被工作树中已删除的 `src/assets/rpg/campus/zijingang_campus_plate.png` 阻断。本轮未恢复、替换或覆盖该校园地图资产，因此尚未更新 `demo/index.html`。

## 2026-08-08 第四章三视角像素楼梯关卡开发规格

- 详细设计：新增 `docs/plans/2026-08-08-chapter4-monument-perspective-two-level-design.md`，把两个独立楼梯关卡固化为三个离散正交视角、屏幕投影端点图和图搜索点击移动；第一关包含三件机关与一次投影跨越，第二关包含四件机关、两次投影跨越和一次方向错误的可读重合。
- 连通契约：端点按关卡白名单、当前视角、内部 `480×270` 屏幕距离、投影切线方向和遮挡结果分类；有效连接使用青色实线，位置接近但方向失败使用橙色虚线，后者不进入可走图。
- 移动契约：点击可达目标时走完整最短路；不可达时走到当前连通分量最接近目标的边缘。通过投影边期间锁定视角和机关，并限制世界坐标交接时的脚底屏幕位移。
- 画风契约：独立 Demo 后续关闭抗锯齿、软阴影、连续雾、平滑 PBR 和圆角玻璃 UI，使用 `480×270 → 960×540` 最近邻渲染、有限色板、硬边阴影和共享 `96×128` 四帧 RPG 人物资源，与第四章亮色门厅及前后像素场景保持一致。
- 实施计划：`project-development-report.md` 已加入文件级九任务计划，覆盖类型/关卡数据拆分、投影图、三相机、导航、像素渲染、共享人物、两关校准、HUD 与跨浏览器验收。
- 验证边界：本轮只写设计和实施计划，没有修改独立 Demo 行为，也没有生成新的 `demo/chapter4-monument-stair-demo.html`。主 `demo/index.html` 的构建仍受工作树中已删除的 `src/assets/rpg/campus/zijingang_campus_plate.png` 影响，本轮未恢复该文件。

## 2026-08-08 第四章三视角楼梯间主 Demo 集成重写与全量验收

- 按 `docs/plans/2026-08-08-chapter4-monument-perspective-two-level-design.md` 整体重写 `src/tools/ChapterFourMonumentStairDemo.ts` 与 `src/tools/chapter-four-monument-stair-demo.css`（`chapter4-monument-stair-demo.html` 仅更新标题与主题色），四个底层模块（types/levels/engine/pixelStyle/playerSprite）未做任何修改。
- 渲染管线：`WebGLRenderer(antialias:false)` + 内部 `480×270` 缓冲 + 画布 CSS `960×540` 最近邻放大（整数倍优先的舞台缩放），WebGL 不可用时显示可读错误卡与返回链接。
- 三视角：每关三台正交相机取自 `LEVEL_CAMERAS`，同一 lookAt 中心与可见范围，禁止指针漂移；切换 `480ms`（减弱动态 1ms）四姿态帧，期间锁定移动/机关/点击/再次切换，仅安全节点可切换（否则按钮禁用但可见），切换完成执行完整投影重算。
- 投影接缝：重算后 valid 显示青色实线四帧出现动画、方向失败显示橙色虚线三帧动画且首次保留 `1200ms`、invalid 不写入导航图；`occlude` 用 `THREE.Raycaster` 对实心遮挡面实现规则 5；接缝画面表现采用屏幕空间 22px 缝合线（端点世界连线在屏幕上缩成点，不可读），沿切线屏幕方向展开，实/虚线均可读。
- 点击移动：射线命中→最近导航节点→BFS；不可达走断口边缘且反馈只显示一次；投影边通行记录 `lockedPerspectiveEdgeId`，锁定相机/机关/重置，45% 进度处切换端点空间并逐帧校验画面跳变 ≤2px；有效接缝屏幕重合区（9px 内）的点击解析为跨越到远端端点，避免命中近端机关实体被误判为选中。
- 机关：点击实体选中（`Box3Helper` 贴合实际包围盒、选择色 `#6EB7D6`），选中后底部显示两枚方向控制；桌面 `Q/E` + 触屏像素按钮；单档 `470ms`；旋转 90° 四离散姿态帧，升降/横移按内部像素整数位移每 60ms 更新；人物站在被操作机关上时按引擎矩阵插值携带，机关停止后先更新世界矩阵再重算。
- 关卡流程：A 关完成→消防门四帧打开→走入门内→16×9 像素块遮罩 `360ms`→B 关；B 关完成→全完成画面（重玩入口）；重置只重置当前关且不回退 A 关完成状态；`12s` 无输入仅脉冲当前选中机关；重复锁定输入忽略并给短促按钮反馈；首次有效接缝、断路、方向错误三段反馈文案均来自关卡数据。
- UI：深蓝黑底、米白 `2px` 边框、黄色章节号、Fusion Pixel 字体；顶部仅关卡名+当前目标，底部仅状态行+选中机关与两个操作键+重置，右侧纵向三视角按钮（方向字形+序号）；触屏命中框 ≥44×44 CSS px 且互不覆盖；修复舞台 `transform` 缩放布局盒导致的移动视口文档溢出（`overflow:hidden` 裁剪），390×844 下 `scrollWidth/Height` 与视口一致。
- 调试接口：`window.render_game_to_text()` 返回十字段 `StairDemoSnapshot` JSON；`window.stairDemoDev` 实现 `setView/setMechanism/clickNode/resetLevel/replayAll`。
- 验证：`node scripts/verify-chapter4-stair-levels.mjs`（135 项）与 `verify-chapter4-stair-engine.mjs`（46 项）全绿；`npm run build:chapter4-stairs3d`（含 `tsc --noEmit`）通过；`git diff --check` 干净。
- 浏览器验收（本地 HTTP + 无头 Chromium，临时脚本与截图均在 `/tmp` 并已删除）：1280×720 真实键盘/鼠标 + dev API 混合走完 A 关六步与 B 关七步共 67 项断言 0 失败，覆盖接缝出现时机、投影跨越锁定、门开四帧、关间遮罩、错误重合橙色虚线与 1200ms 保留、梯端停下与方向文案、升降台携带、重置/重玩/全完成、快照字段齐全且随流程变化，页面与控制台错误为 0；1280×800 与 390×844（触屏 tap 实测、命中框达标、文档零溢出）及 prefers-reduced-motion 各完成 A 关共 34 项断言 0 失败。17 张关键步骤截图逐张目检：像素硬边、人物脚底锚点稳定、色板与亮度档、UI 规范、装饰不遮端点/接缝均符合 §8。
- 产物：`demo/chapter4-monument-stair-demo.html` 为 `3,532.96 kB`，SHA-256 `6c3e142c7d080a8a8c6fc057ec18ba3883c5f3395185c4b17e3920b9b5e9fecf`。主 `npm run build:single` 仍受工作树中已删除的 `src/assets/rpg/campus/zijingang_campus_plate.png` 阻断，本轮未恢复该文件；正式章节接入、`GameState` 写入与 Godot 迁移保留为后续工作。

## 2026-08-09 第四章 A1 主电梯历史同步与 A2 到站闭环

- 范围调整：按用户要求暂停楼梯视错觉正式接入，继续实现主电梯段。
- 状态与存档：新增电梯历史已观察、重放起点、三轨对齐、尝试次数与已进入轿厢五项事实；存档版本升至 `18`，兼容旧版缺失字段。
- 三轨面板：轿厢、门体、六秒进入窗口共用一条历史偏移；错位时保留面板并明确说明开门区间未覆盖进入窗口，`22:43:31` 对齐后才启动重放。
- 门体演出：A1 关闭时直接使用母图中的门；开门时两片门从中缝向两侧收回，门洞、通行碰撞和门体进度共用同一数值。通行阈值为 `82%`，全开后保持 `6s`，门缝内有人时触发防夹并恢复全开。
- 跨层闭环：玩家进入轿厢后锁定移动，完成 A1 关门、`1↑2` 指示、上行和 A2 开门；到站后落在 `c4_a2_corridor`，阶段推进为 `npc_schedule_route`。
- DEV 节点：新增 `c4-elevator-aligned` 与 `c4-a2-arrival`，可直达对齐前验收和 A2 到站验收。
- 真实浏览器验收：Blink `1280×720` 走完错位反馈、正确对齐、A1 开门、6 秒窗口、门缝防夹、进入轿厢、关门、上行和 A2 全开，控制台与页面错误为 `0`。Blink `1100×760` 与触屏 `390×844` 无文档溢出，移动端三轨面板完整落在视口内。
- 验证边界：`npm run typecheck` 和 `npm run chapter4:validate-topology` 通过；在临时副本中仅恢复 HEAD 校园底图后，`npm run build:single` 通过。工作区主构建仍被已删除的 `zijingang_campus_plate.png` 阻断；本轮未修改该删除。Gecko 和 WebKit 的 Playwright 运行文件未安装，本轮没有新的跨内核运行证据。

## 2026-08-09 RPG 全局物体距离与朝向交互

- 共享规则：`RpgInteractionContract` 改为从人物脚点量到真实物体 `width/height` 最近边缘；`stand` 只保留为出生和演出落位信息。新增固定四向、`toward_target` 前向锥和 `wrong_facing` 反馈，道具投放与空格/指针交互使用同一距离和朝向判定。
- 场景接通：食堂、图书馆、剧场 Phaser 回退、启真湖与第四章 A1 已接入共享规则；启真湖划艇使用连续船头向量。第四章当前只对已实现的断续水迹、迈斯威卷帘门和主电梯生效，A2 与最终教室尚未形成可交互运行目标。
- 物件设计：按底图物体边界分别校准取餐窗、扫描口、设备、柜台、书架、背包、海报、自助机、闸机、灯控台、通风口、器材架、柳枝、警示牌、储物柜、登船边和电梯；墙面设备使用固定朝向，可多侧接近物体使用面向物体。
- 视觉清理：删除食堂窗口大牌、编号圈、“站这里”与投放说明；删除图书馆和剧场站位圈、连接线和投放标签；关闭启真湖普通物件发光圈。场景提示改为无底框描边文字，道具选中时只描边真实物件边界。
- Godot 同步：剧场场景数据契约升至 `1.1.0`，React–Godot 消息协议保持 `1.0.0`；重新导出并登记 `public/godot/theater/`。`npm run godot:export:web` 通过，校验结果为 `assets=88 / targets=11 / collisions=27 / webBuild=matched`。
- 浏览器验收：Blink `1280×720` 逐一检查食堂、图书馆、剧场、启真湖和 A1 教学楼，未发现旧窗口牌、站位圈或带底色的场景提示；页面与控制台错误为 `0`。食堂在同一目标完成两次独立判定：人物 `(790,268)` 面向下时拒绝，人物偏离旧站点至 `(851,255)` 且面向上时接受并写入 `pickupTimeErrorSeen=true`。图书馆入馆记录同样完成错朝向拒绝与偏移位置正朝向打开面板。正式剧场预览确认 `engine=godot`、`runtimeContractVersion=1.1.0`、`phaserCanvasCount=0`。
- 验证边界：全局机制获得 `2` 个 Phaser 场景的正反向交互验证、`1` 个 Godot 正式运行时加载验证和 `5` 个场景的画面检查。`npm run typecheck` 通过；工作树直接执行 `npm run build:single` 仍被已删除的校园底图阻断，在仅临时提供 HEAD 底图且随后恢复删除状态的情况下构建通过。所有临时底图、服务、状态文件和截图均已删除。

## 2026-08-09 启真湖前划与组合后划

- 输入契约：皮划艇状态下，`A/←` 和 `D/→` 默认分别前划左右桨；按住 `S/↓` 再按左右桨执行后划。触屏增加独立“按住后划”修饰键，支持一根手指保持修饰、另一根手指点击左右桨。
- 物理与演出：速度改为有符号区间，前划上限 `340`、后划上限 `230`；后划转向方向与前划相反。前进使用船尾水波，后退使用船头水波，每次划桨均有对应方向的短促水波。
- 教学与反馈：上船教学仅统计交替前划，后划会显示用途提示且不会增加 `boardingStrokeCount`。状态栏区分“默认前划”“后划已按住”“后退中”。
- 生命周期：触屏后划由首个指针独占；无关指针抬起不再清除状态。离开皮划艇、场景关闭和重新创建时清理反向输入、负速度、侧倾、划桨节奏与翻船瞬时状态。
- 浏览器验收：Blink、Gecko、WebKit 在 `1280×720` 均通过键盘前划与组合后划；前划速度为 `273–277`、方向为 `forward`、水波来源为 `stern`，后划速度为 `-90–-91`、方向为 `reverse`、水波来源为 `bow`，页面与控制台错误均为 `0`。Blink 触屏 `390×844` 通过两指和额外误触指针验收，后划保持时速度 `-119`，松开后惯性速度 `-112`；四个触控按钮均不小于 `54×65px`，文档无溢出。
- 流程验收：`c3-qizhen-boarding` 实际步行到登船位后，两个后划输入保持计数 `0`，随后四次交替前划将计数推进至 `4` 并进入 `open_water`。反划中通过 DEV 切出并返回后，速度、侧倾、方向和修饰状态均归零。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check`、隔离副本 `npm run build:single` 与 `npm run verify:single` 通过。生成的 `demo/index.html` 已同步回工作区，大小 `157403529 bytes`，SHA-256 为 `ba0422735e1e7f8cb094f75497e258a4322f6af6883f96798159fb00477ed7f2`。工作区校验脚本会因 `demo/` 中已有 `chapter4-monument-stair-demo.html` 与 `godot/` 目录而拒绝运行；相同哈希的隔离产物已通过完整单文件校验。

## 2026-08-09 启真湖黑天鹅实体追逐与河道碰撞校准

- 追逐失败：黑天鹅已从循环跟随演出改为真实距离追击。船鹅中心距离达到 `104px` 时触发碰船、画面震动和翻船演出，并通过控制器将当前流程恢复到 `qizhen_chase / channel_chase`；只清零本轮距离，保留最佳距离与尝试次数。
- 距离速度曲线：起步保护为 `4s`；距离 `≤150px` 时目标速度为 `168px/s`，距离 `≥360px` 时为 `440px/s`，中间使用 smoothstep 平滑插值。远距离速度高于皮划艇 `340px/s` 上限，近距离速度低于正常交替划行速度；单帧追击位移限制为 `50ms`。
- 划桨修正：左右交替划桨现在使船头在基准航向两侧对称小幅摆动，避免首桨产生的单向偏移累积；连续同侧划桨仍会扩大转向与侧倾。
- 船体碰撞：碰撞体从隐藏人物缩放值中解耦，改为根据可见艇体 `83×67px` 和当前航向逐帧计算轴对齐包围盒。翻船、DEV 跳转和场景重建均清理速度、侧倾、划桨方向和节奏运行态。
- 地图碰撞：浮排、西侧网栏、两根系泊柱、右侧码头、三组石块、五个浮标和阶梯式南北岸线全部按 `1672×941` 河道源图像素坐标重新标定，追逐期不再移除浮排与网栏碰撞。追逐出生线调整为 `(1280,680)`，中央可见水道允许完整交替划行，且不穿过任何实体。
- 浏览器验收：最终单文件在 Blink `1280×720` 以 `c3-qizhen-chase` 实测。完全停桨会连续触发追上失败，每次恢复为人物 `(1280,680)`、追逐距离 `0`、阶段保持 `swan_chase`；`34` 次左右交替输入以 `capsizeCount=0`、`chaseAttempts=1`达到 `qizhen_complete`，距离和最佳距离均为 `1000`。两路最终产物均无页面或控制台错误。
- 碰撞可视验收：临时 Vite 副本以 `rpgCollision=1` 检查源图边缘，红色碰撞边界与浮排、系泊柱、右侧码头、石块、浮标和南岸走道重合；运行快照确认水平艇体碰撞尺寸为 `83×67px`。临时副本的字体请求因 node_modules 软链接不在 Vite allow list 而返回 `403`，该请求不存在于最终单文件；最终 HTTP 验收错误为 `0`。
- 构建验证：`npm run typecheck`、`git diff --check` 与隔离副本 `npm run build:single` 通过。构建时仅在临时副本提供 HEAD 校园底图，工作区的底图类型变更保持不动。生成的 `demo/index.html` 已回写工作区，大小 `161078316 bytes`，SHA-256 为 `1dd891f7c6a0b4b99a95a3ea8c898debd7752debd108a88ce0f57776c4a63631`。

## 2026-08-09 教学楼地图优先重做与纯网页运行时

- 美术方向：停止使用原先由谜题分区驱动的教学楼底图，新增 `teaching_building_ground_floor.png`。母图为 `1672×941` 像素，使用与食堂、图书馆一致的大尺度俯视平面结构，包含四间教室、中央门厅、双楼梯、双电梯、前台、闸机与入口。
- 地图优先：`ChapterFourTemporalMazeScene` 当前只保留人物移动、镜头、源像素碰撞、返回与全屏。章节任务条、现实模式、物品栏、电梯面板、站位标记和剧情交互目标均不挂载；待基础地图验收后再设计剧情与玩法。
- 碰撞标定：新场景按母图原始坐标建立 `41` 个碰撞矩形，覆盖外墙、四间教室、桌椅、花槽、前台、设备和闸机。人物从 `(836,700)` 向上移动会在前台边界停于 `y=634.875`，绕行路线可达东侧大厅。
- 运行时决策：所有横屏 RPG 场景统一使用 React + TypeScript + Phaser。`RpgGameHost` 已移除 Godot frame、加载失败回退和 Godot 剧院面板分支；`rpgEngine=godot` 也保持 `engine=phaser / reason=web_runtime_only`。CI 和 `package.json` 不再运行 Godot 同步、导出或哈希校验。
- 文档边界：`AGENTS.md`、客户端兼容契约、剧院运行时契约、RPG 交互契约、校园/室内/字体资产说明均已切换到纯网页路线；旧 Godot 目录只作历史参考。
- 验收计数：教学楼地图在 Blink `1280×720`、`1100×760`、`390×844` 和重建后单文件共完成 `4` 次可见验收；教学楼与剧院共 `2` 个场景在显式请求 Godot 时仍各只挂载 `1` 个 Phaser canvas、`0` 个 Godot frame，页面与控制台错误为 `0`。
- 构建验证：`npm run art:finale-environments`、`npm run typecheck`、`npm run build:single` 与 `git diff --check` 通过；在只包含 `index.html` 的临时验收目录中，`verify-single-file-build.mjs` 通过，结果为 `161055246 bytes / 2 inline scripts / 1 inline style`，SHA-256 `09b9c94815ec8832e4c12eeb604d375f995f48a1a57903a8718773385bca6489`。构建期间仅临时提供 HEAD 校园底图，随后立即移除链接；工作树中用户删除的 `zijingang_campus_plate.png` 仍保持删除状态。本轮本地 HTTP 服务、临时校园底图、状态快照和验收截图已全部清理。

## 2026-08-09 教学楼三层拼接地图与楼层交通

- 地图重做：用户否决单层全景后，将教学楼改为三张独立 `1672×941` 俯视像素楼层图。1F 包含主入口、三部电梯、双楼梯、麦思威面包坊餐厅、104/105 教室与校友头像长廊；2F 包含 201 创客工坊、204 研讨教室、202 阶梯教室、203 计算机教室、开放学习区与纪念画像；3F 包含 301 校史档案展、302 媒体工作室、304 报告厅、303 智慧教室、校友荣誉门厅与头像长廊。
- 拼接运行时：Phaser 将三层母图按 `192px` 间隔放进同一个 `5400×941` 世界。相机使用 `1:1` 源像素局部跟随并限制在当前楼层，玩家不再一次看到整层缩略图。三层共用同一电梯和两侧楼梯的局部坐标。
- 楼层交通：电梯支持 `1/2/3` 数字键、方向键加 `Enter`、桌面点击和移动端触摸；西侧楼梯逐层向下，东侧楼梯逐层向上。楼层通道按人物到真实通道区域的距离判定，并要求人物面向上方通道后才能触发。
- 剧情预留：按源像素登记 `17` 个剧情锚点，覆盖麦思威、各教室门厅、开放学习区、校史展、媒体工作室、报告厅、智慧教室和三层校友图片区。锚点只进入运行时调试与后续控制器设计，当前地图阶段不挂载谜题标记或剧情面板。
- 美术清理：旧单层 `teaching_building_ground_floor.png` 已由三层母图替换；终章环境清单从 `6` 张扩展为 `9` 张并重新生成哈希。
- 浏览器验收：Blink `1280×720` 逐图检查 1F 局部视野、2F 电梯面板和 3F 到站画面；键盘实际完成 `2F → 3F`。Blink 触屏 `390×844` 使用共享交互按钮打开电梯并点击 `3F` 成功，五个触控按钮可见，文档宽度等于 `390px`。Blink `1280×800` 画布为 `1280×720`、比例 `16:9`、文档无溢出。上述运行均无页面或控制台错误。
- 构建验收：`npm run art:finale-environments`、`npm run typecheck` 和 `npm run build:single` 通过；隔离验证结果为 `168597229 bytes / 2 inline scripts / 1 inline style`，SHA-256 `3d8b1129d98cdc2ca0a7f28bd638e7d18de2dac0cd3a129d434905f13aaab85e`。构建后的 HTTP 单文件再次通过 `2F → 3F` 键盘选层，运行世界为 `5400×941`、Phaser canvas 数量为 `1`、错误为 `0`。
- 验证计数：大地图局部视野、楼层电梯、移动触摸、非 `16:9` 信封缩放与最终单文件共形成 `6` 次独立检查。本轮只验证地图与楼层交通；教室、餐厅和校友头像的正式剧情玩法仍待基于已确认地图设计。

## 2026-08-09 启真湖软边界与后划脱困复验

- 碰撞响应：岸线、地图水域边缘和实体障碍只将皮划艇速度归零，不再触发碰撞侧翻；碰撞不会改变船头角度或额外增加侧倾。连续同侧划桨仍保留为唯一的普通侧翻机制，黑天鹅接触仍是追逐失败机制。
- 脱困操作：船头保持原方向，按住 `S/↓` 并交替划左右桨即可沿原航向反向退出；提示明确显示“船头方向保持不变”，运行快照标记为 `stop_preserve_heading_allow_reverse`。
- 单文件实测：在 `c3-qizhen-open-water` 从 `(560,790)` 前划撞到西北岛岸线，最终停于 `(561,447)`，`capsizeCount=0`、`capsizing=false`、碰撞记录角度与当前角度均为 `-1.386rad`。随后从同一路线碰岸后执行四次交替后划，皮划艇退到 `(590,645)`，速度 `-141`、方向 `reverse`、船头水波 `bow`，侧翻次数仍为 `0`。
- 视觉与错误检查：已分别打开碰岸和后划脱困截图；船体停在可见岸边，倒退后重新进入开阔水面。两次运行均未生成控制台或页面错误文件。`npm run typecheck` 与 `git diff --check` 通过；当前 `demo/index.html` 已包含对应提示与调试契约，SHA-256 为 `3d8b1129d98cdc2ca0a7f28bd638e7d18de2dac0cd3a129d434905f13aaab85e`。

## 2026-08-09 单文件重新打包与实机启动

- 重新执行 `npm run build:single`；首次因 `src/assets/rpg/campus/zijingang_campus_plate.png` 短暂缺失而失败，该资产恢复后再次构建成功。恢复文件为 `4516×3420` PNG，Git blob 与当前 `HEAD` 中的 `fc86519dd753315d5cd254e4a9a0053541da0763` 一致。
- 新生成 `/Users/zhuhangcheng/Documents/黑客松/7-55/demo/index.html`：`168597295 bytes`，修改时间 `2026-08-09 17:07:43 +08:00`，SHA-256 `aeed271061604b4638e4fe8451dccca6a9733d599f774860d8c6b651a3d9d1b0`。
- 内嵌检查确认软边界提示、`stop_preserve_heading_allow_reverse`、`rpg_qizhen_reverse_changed` 和黑天鹅追上失败文案均已写入，HTTP 外部资源数为 `0`。
- 通过本地 HTTP 启动新单文件，从 `c3-qizhen-open-water` 进入后启真湖画面完整，`render_game_to_text()` 返回 `collisionResponse=stop_preserve_heading_allow_reverse`，未产生浏览器错误。
- `npm run verify:single` 仍会因 `demo/` 中存在独立的 Chapter 4 调试页和 Godot 输出目录报白名单错误；该报错来自验证器的目录独占假设，定向单文件检查与实际启动均已通过。

## 2026-08-09 第四章序幕高空追赶与尾迹清理

- 高空路径：离湖抬升、夜间拱廊、教学楼入口、门厅与清楼环廊五段均把纸条中心线提升到人物头顶上方；每段写入独立地面投影位置，纸条高度和地面位置可同时辨认。
- 追赶关系：门厅保洁员从观察状态进入推车追赶，横向位置持续落后纸条约 `172px`；程序绘制备用画面使用同样的前后关系。
- 视觉清理：删除门厅纸条后方的整段实心湿痕，公共风迹由五组粗长矩形改为短小断续像素，纸条下方的整条矩形阴影改为分裂式地面投影。
- 兼容保持：场景母图动态层和程序绘制备用场景同步更新；画布无障碍说明也明确为纸条升高并被追入教学楼。
- 浏览器验收：Blink `1280×720` 实际检查拱廊、入口、门厅追赶中段、门厅追赶后段与清楼环廊共 `5` 个关键帧。纸条均位于人物头顶上方，门厅追赶距离可见，未再出现与纸条相连的实心长条，页面和控制台错误为 `0`。
- 构建验证：`npm run typecheck`、`npm run build:single` 与目标文件 `git diff --check` 通过。最终 `demo/index.html` 为 `168597295 bytes`，SHA-256 为 `aeed271061604b4638e4fe8451dccca6a9733d599f774860d8c6b651a3d9d1b0`。构建期间临时恢复 HEAD 校园底图，构建后立即移除；工作树中的删除状态保持不变。临时浏览器截图和状态文件在检查后删除。

## 2026-08-09 教学楼电梯等待与乘梯闭环

- 交互顺序：大厅交互先登记呼叫，楼层按钮只在人物进入轿厢后出现。完整顺序为呼叫灯亮、层显逐层变化、到站闪灯、双门打开、人物步入、轿厢选层、关门、楼层运行、目的层开门、人物走出和门体复位。
- 场内表现：中心电梯门上方增加常驻数字层显；运行时显示上下行箭头，门侧呼叫灯区分等待与到站。两扇门使用门框几何裁切，打开时滑入墙体，不在大厅画面外露灰色门板。
- 控制设计：桌面支持方向键、`Enter` 与数字键；细指针可点击轿厢楼层按钮；粗指针使用共享方向键切换选层、共享交互键确认。等待、开关门和行驶期间锁定人物移动，结束后恢复碰撞与正常朝向判定。
- 调试状态：`render_game_to_text()` 增加 `elevatorRuntimePhase`、`elevatorDoorProgress`、`elevatorTargetFloor`、`elevatorDisplayFloor` 与 `elevatorWaitRemainingMs`，可分别确认等待、开门、选层、行驶和复位。
- 浏览器验收：Blink `1280×720` 分别检查等待层显、开门进度、门全开与轿厢面板、3F 出梯复位；键盘完整跑通 `2F → 3F`。Blink 触屏 `390×844` 使用共享右方向键与交互键完成相同路线，最终 `currentFloor=3`、`elevatorRuntimePhase=idle`、面板关闭，页面与控制台错误为 `0`。
- 验证计数：新增 `4` 个阶段画面检查、`1` 个桌面完整流程和 `1` 个触摸完整流程。`npm run typecheck` 与 `npm run build:single` 通过；最终 `demo/index.html` 为 `168605053 bytes`，SHA-256 为 `fcde48bb9f98e5a2ce670d5dba4a77198ccf92c5055e41426baff5ed9cff3975`。临时验收截图与状态文件已移到废纸篓，可恢复。

## 2026-08-09 第四章三层校园时间迷宫 C 方案

- 用户确认采用“空间变化 + 时间重放”组合。固定结构为一部电梯、相邻连续楼梯和始终可走的主环路；动态门、隔断、NPC 与历史窗口只改变可见支路。
- 范围收束：本轮正式切片只覆盖 A 楼 1F/2F/3F，三层和 `A1/A2/A3` 一一对应；B 楼、A4 与独立视错觉楼梯保留后续接口，不再压入三张展示层。
- 三层差异：1F 负责气流与电梯历史校准；2F 负责人员时刻、可变走廊和导视碎片；3F 负责旧导视重建与历史连廊判断；完成 3F 后返回 2F 进入新的取证窗口。
- 通行修正规格：2F 保留西侧 `220px`、东侧 `128px`、南侧 `128px` 三段固定通道；南侧范围为局部 `y=686..814`，中央休息区需要重新出图并同步碰撞。
- 设计文档：`docs/plans/2026-08-09-chapter4-three-floor-temporal-maze-design.md`。
- 实施计划：已写入 `project-development-report.md`，覆盖布局验证、控制器投影、三张底图、单电梯/相邻楼梯、动态碰撞、三层玩法、DEV、存档、三内核与单文件验收。
- 当前验证计数：设计基于三张底图、现有碰撞、现有状态机和电梯链共 `4` 类代码/资产证据；尚未开始新的运行验证，因此玩法结论保持设计假说。

## 2026-08-10 远端食堂更新合入与三层时间迷宫继续落地

- GitHub 同步：当前 `HEAD` 已快进到 `origin/main` 的 `c667bab`（食堂动画）。该提交新增纸包鸡取餐过场、今日新品宣传板、饮料插入和队伍动画贴图，并修改食堂控制器、场景、存档兼容、DEV 节点与道具指引。
- 冲突处理：保留远端新动画和新阶段，同时保留本地已校准的取餐窗口宽度、站位与朝向判定。`CanteenInteriorModel.ts`、`CanteenInteriorScene.ts` 和 `RpgItemUseGuidance.ts` 的三处冲突已解除，未留下 unmerged 路径。
- 第四章逻辑：导视板现在校验完整三槽顺序“西侧碎片 / 中间留空 / 东侧碎片”，不再过滤空槽。A1 电梯历史、A3 旧导视、导视重建和连廊历史的提示顺序已与控制器一致。
- 几何校准：2F 三条固定通道改为源图上实际可走地面，补入两组画像花盆碰撞。A2 双碎片、返程窗口与 A3 三个证据点的站位全部移到可走地面。
- 构建与浏览器：`npm run typecheck`、`npm run chapter4:validate-topology`、`git diff --check` 和 `npm run build:single` 通过。Blink 完成食堂、A1、A2、A3 节点可见验收，并通过 `390×844` 和 `1024×768` 视口；Firefox 与 WebKit 各完成一次单文件运行。六类运行均为单 Phaser canvas、比例 `16:9`、无文档溢出、无页面或控制台错误。
- 单文件：`demo/index.html` 已重建为 `160115009 bytes`，修改时间 `2026-08-10 00:26:34 +08:00`，SHA-256 为 `3d3fbcf184c4a8479443bba04ead475206177bd7515817210c5ed30171cf5bb1`。

## 2026-08-10 启真湖移动端划桨手势合入当前单文件

- 触屏输入：删除需要双指配合的独立“按住后划”按钮；左桨和右桨分别读取纵向手势，上划执行前进桨，下划执行后退桨，位移不足 `18px` 的轻触默认前进。
- 即时反馈：手指按下、越过前划阈值、越过后划阈值时，桨按钮分别显示待判定、`↑ 前进` 和 `↓ 后退`。左右桨允许两根手指同时操作，单侧拒绝重复触点，取消指针、失焦、离开湖区或下船会清理未完成手势。
- 桌面保持：键盘仍使用 `A/←` 和 `D/→` 前划，按住 `S/↓` 再划任一侧执行后划。规则文档和游戏内教程已同步为同一套语义。
- 移动端实测：在当前带第四章开发内容的工作区重建单文件后，Blink `390×844` 以 `c3-qizhen-chase` 进入启真湖；真实 Pointer Event 序列完成左桨上划、右桨下划和左桨轻触，三个控件完整可见，页面横纵溢出与页面、控制台错误均为 `0`。隔离分支同套代码此前已通过 Blink、Gecko 和 WebKit 双指手势检查。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check` 和 `npm run build:single` 通过。`npm run verify:single` 仅因 `demo/` 同时保留 `chapter4-monument-stair-demo.html` 与历史 `godot/` 目录而拒绝目录独占校验，本次未删除这两个调试产物。最新 `demo/index.html` 为 `160115726 bytes`，SHA-256 为 `4490f48f31f6d66eb833fe28114db46b795d214291e282bd72cd3a0728be50b1`。

## 2026-08-11 启真湖黑天鹅围栏碰撞与船头组合位修正

- 围栏碰撞：删除覆盖 `930..1435 × 155..565` 的整块矩形，按源图中北侧、左侧转角、南侧弧线和东侧立柱拆成 `10` 段窄碰撞。可见围栏继续阻挡，围栏外侧开阔水面恢复通行。
- 组合交互：磁性扣与钓鱼竿的目标框从固定空水面改为跟随皮划艇船头，尺寸从 `150×110` 缩到 `96×64`；选择任一组件时目标框贴着船体显示，完成后立即消失。
- 运行验收：Blink 在 `c3-qizhen-paper` 以交替前划抵达围栏边，碰撞不触发侧翻；随后执行 `S/↓ + 左右桨` 交替后划，最终速度 `-102`、方向 `reverse`、`capsizing=false`，能够退出碰撞区。道具拖放实测得到 `magneticFishingRod=true` 与 `magneticRodCombined=true`。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check` 和 `npm run build:single` 通过。HTTP 单文件再次完成前划碰撞、后划脱困与磁性钓鱼竿组合，页面状态未报告错误。`demo/index.html` 为 `160116716 bytes`，SHA-256 为 `ece5a87c2d0d3d026b628d79bb0b329224ff8ce3954efb6e73fd6591e4ce41f1`。
- 验证计数：本轮形成 `3` 条独立运行证据，分别覆盖碰撞几何、反向脱困和道具组合闭环。

## 2026-08-11 教学楼人员层与三维错位楼梯

- 二层人员：A2 现在包含 `6` 条往返动线，覆盖路过学生、推车保洁员和巡查保安。每条动线使用资源清单中的原始帧率；角色到达端点后原路返回，水平角色同步翻转朝向，不再出现倒着行走或瞬移回起点。
- 自习学生：201 与 204 各加入两名双帧学生，动作以低频循环播放并设置不同起始相位。桌面前沿从二层母图按源像素裁出并在人物前景重绘，人物上半身可见、腿部位于桌沿后方，复用食堂坐席的遮挡结构。
- 明暗表现：浅色操作显示正常人物；深色观察显示相同人员的残影和移动路线。投影清单与内容 JSON 同步登记全部正常角色和残影 ID。
- 错位楼梯：`chapter-four-stair-alignment` 已接入原本独立的 Three.js 两关实现。进入该场景时隐藏并锁定 Phaser 输入，完成两关后仍由第四章 TypeScript 控制器写入进度；独立调试页和主单文件共用同一挂载入口，卸载时释放渲染循环、监听器、几何和调试接口。
- 验证：`npm run typecheck` 与 `npm run chapter4:validate-topology` 通过；HTTP 单文件在 `c4-a2-arrival` 连续三帧检查中显示保洁、保安和四名流动学生的位置持续变化，页面和控制台错误为 `0`。移动到 2F 中部后可见 201/204 自习学生位于桌后。三维楼梯单文件入口返回 `stair_a / playing / south_east` 的运行状态并正常绘制 WebGL 场景。

## 2026-08-11 755 米自行车追逐连续像素素材重制

- 环境层：新增无 UI、无人物、无障碍的 `16:9` 校园三车道道路底图，保留实时车道投影、里程、换道和碰撞逻辑。
- 骑手动画：生成并接入同一骑手的六帧踏频循环，固定底部中心锚点，以约 `9.5 fps` 播放；暂停与减少动态效果模式保持固定帧。
- 动态对象：手机路人、豆浆路人、跑步学生、三人阻挡组均使用两帧循环；锥桶、路障、共享单车和校园服务车改用同透视图集，并继续按实际距离缩放。
- 透明边缘：全部动态素材先以纯洋红底生成，再执行 Alpha 去底、软遮罩和去色溢；骑手图集透明像素 `1303516/1572516`，路人障碍图集透明像素 `1299393/1572528`，未在浏览器画面发现洋红残留或白色抠图边。
- 浏览器验收：Blink 通过 `c3-canteen-chase` 真实检查点运行至 `155m`，完成右换道与回中线；完整页面复验显示生成素材随距离缩放，页面和控制台错误为 `0`。
- 帧与构建验证：相隔 `130ms` 的两张实际追逐帧有 `37382` 个像素变化；`npm run typecheck`、`git diff --check` 与 `npm run build:single` 通过。新 `demo/index.html` 为 `167670734 bytes`，SHA-256 为 `5969a273015ebeab341ce09842aadf02c38918346b9272b72875267216f65ac4`。

## 2026-08-11 755 米追逐透视与背景动势修正

- 标线去重：正式生成背景不再运行第二层 `drawRoadMotion`，道路仅保留背景原生车道线；程序标线只供素材未加载时的备用背景使用。
- 背景动画：在原始道路帧基础上生成 B/C 两张同构微变帧，建筑、道路与透视不变，只调整云缘、树叶与光照。运行时使用 `A → B → C → B` 平滑混合循环，并让低对比度路面纹理沿透视方向向骑手移动。
- 行人透视：左右行人位置从画面中心偏移改为人行道中心线投影，远端聚合到消失点，近端保持在人行道内；两侧立绘分别朝向消失点，不再横向或背离道路延伸方向。
- 实玩验收：先使用 `develop-web-game` 标准脚本跑通距离推进和换道；由于标准脚本只截取底层 Phaser canvas，再对实际 `canvas.canteen-bike-canvas` 表层执行了完整页面检查。Blink `1280×720` 中背景微变帧、行人纵深、右换道均正常，文档溢出为 `0`，页面和控制台错误为 `0`。
- 构建验证：`npm run typecheck`、目标路径 `git diff --check` 和 `npm run build:single` 通过。`demo/index.html` 为 `172798136 bytes`，SHA-256 为 `066009353bb44ce5599f2b05a134f8178dacd7bfe0c0b5a9af4134f6247f8cd8`。

## 2026-08-11 第四章楼梯视角冻结修复与多视角上行

- 冻结根因：视角按钮把节点的 `safe` 恢复属性当成切换条件；人物抵达楼梯端点或机关平台后，另外两个视角因此被禁用。视角切换条件现已集中到同一判定：人物静止即可切换，行走、机关动画、透视跨越和镜头过渡期间继续锁定。
- 多视角上行：关卡定义新增 `ascentViewSequence`。第一关上行使用 `south_west`；第二关下段上行使用 `south_west`，上段上行切换为 `top_oblique`。第二关目标文案同步要求逐层变换视角。
- 自动验证：楼梯引擎 `46` 项检查全部通过；两关布局与视角契约 `139` 项检查全部通过，额外校验相邻上行段不得重复视角；`npm run typecheck` 与目标文件空白检查通过。
- 浏览器闭环：修复前在 `A_STAIR_HIGH` 复现视角 2/3 禁用，修复后同一节点三个视角均可操作。完整两关流程按 `south_west → top_oblique` 完成第二关并进入 `all_complete`，页面和控制台错误为 `0`。
- 集成与响应式：`npm run build:chapter4-stairs3d` 和 `npm run build:single` 通过。构建后的主单文件确认 Three.js 表层可见、Phaser 表层隐藏；在 `699×739` 与 `390×844` 两档视口中，三个视角按钮均为 `48×48`，视角 3 可正常切换，页面无横向溢出且错误为 `0`。
- 验证计数：本轮形成 `5` 类独立证据，覆盖故障复现、纯逻辑契约、两关通关、主单文件集成和双视口响应式。多视角上行规则已经进入设计文档和关卡验证器。

## 2026-08-11 755 米追逐景深、行人朝向与骑手转向帧

- 景深推进：生成道路帧先进入固定 `320×180` 像素栅格，再以 nearest-neighbor 放大到 `960×540`；终点建筑以入口为锚点，按追逐进度从 `1.00×` 连续扩大到 `1.56×`，减少动态效果模式也保留距离推进。
- 行人朝向：手机学生、豆浆学生和推车学生改用新生成的正面三分之四视角双帧；步行动画按 `180ms` 节拍切帧，和向屏幕下方接近的运动方向一致。
- 骑手帧率：直行循环由原 `6` 帧扩展为 `10` 帧，播放间隔从 `105ms` 缩到 `72ms`。新图集另含左转 `4` 帧、右转 `4` 帧，换道视觉过渡时间常数调整为 `180ms`；握把一前一后、前叉偏转、前轮斜向投影和回正均有独立帧，身体只保留辅助侧倾。后视角的左右转向行已按屏幕运动重新映射。
- 资产处理：`front_walker_cycle_4f.png` 与 `rider_turn_cycle_12f.png` 均按统一低分辨率像素簇生成，并以纯洋红底完成 Alpha 去底；运行时关闭图像平滑，避免白边与插值模糊。骑手图集 `12` 帧重新归一化为相同 `340px` 实体高度、`370px` 脚底基线和格内中心，消除直行循环与转向切帧的周期性缩放抽搐。
- 运行验收：Blink `1280×720` 已检查 `33m` 直行、左右换道、`288m` 中段和 `660m` 后段画面；终点建筑随距离显著放大，左转帧可见龙头、前叉和前轮共同偏转，前向行人未再倒着走。自动避障跑至 `663m` 时碰撞数仍为 `0`；文档横纵溢出为 `0`，页面和控制台错误为 `0`。
- 构建验证：`npm run typecheck`、`git diff --check` 与 `npm run build:single` 通过。最新 `demo/index.html` 为 `177019859 bytes`，SHA-256 为 `79a33a9d5d09787b5def7c0391be693eb13dc6e092ae0c1ef8b79b99f378340e`。

## 2026-08-11 第四章错位楼梯像素材质优化

- 素材来源：引入 ambientCG 的 `Plaster001`、`Concrete010`、`Metal012` 三张官方 `1K-JPG Color` 原图，分别对应墙面、楼梯/平台和深色金属结构。仓库内保留原始下载文件，`manifest.json` 记录官方页面、下载地址、字节数和 SHA-256；许可为 `CC0 1.0`。
- 像素化策略：运行时将三张原图各自降采样为 `64×64` 灰度像素砖，再由现有暖墙、灰石和深色结构色进行调制。墙面只保留 `248/252/255` 三档明度，混凝土与金属最多六档；继续使用 `MeshBasicMaterial`、硬边轮廓和最近邻采样，不接入法线、粗糙度、金属度或连续光照。
- 几何贴图：新增按物体真实世界尺寸生成 UV 的箱体几何，楼梯踏步、平台、门框和背景墙使用统一 `2.4` 世界单位平铺尺度，避免长构件被横向拉伸。贴图异步加载后创建新的 `CanvasTexture` 并回填材质，解决仅替换占位纹理图像时浏览器仍显示旧材质的问题。
- 可追溯验证：新增 `chapter4:validate-stair-materials`，共通过 `26` 项检查，覆盖 `CC0`、官方来源、仅三张色彩图、本地离线依赖、文件大小和 SHA-256。运行快照确认 `expected=3`、`loaded=3`、`failed=[]`、三张贴图均为 `64×64`。
- 玩法与视觉验收：楼梯引擎 `46` 项、关卡/视角契约 `139` 项全部通过；独立页完成两关全流程，第二关按 `south_west → top_oblique` 上行并进入 `all_complete`。主单文件在 `1280×720`、`699×739` 和 `390×844` 三档视口确认 Three.js 表层可见、Phaser 表层隐藏、三枚视角按钮可操作、文档无横向溢出，页面与控制台错误为 `0`。
- 构建产物：`npm run build:chapter4-stairs3d` 和 `npm run build:single` 通过。独立演示为 `6066580 bytes`，SHA-256 `6d627c655a39ff121b38ec04aae8c078de37690dda80a2b26532d938c3d0b5fc`；随后同一工作区的追逐画面更新再次重建主单文件，当前产物为 `178172179 bytes`，SHA-256 `df9b4e26a95165aee2434e146f6c390d1c9a4eae0bb3db7b40b1ad07282f635d`，并已确认内嵌 `ambientcg_cc0_pixel` 材质合同。

## 2026-08-11 第四章第二关楼梯接缝与上行输入修复

- 故障复现：原有通关脚本通过 `stairDemoDev.clickNode` 直接指定目标，未覆盖真实方向输入。第二关上层接缝对准后，修复前按 `ArrowUp` 仍停在 `B_UPPER_HIGH`，反而按 `ArrowDown` 才能跨到 `B_HIGH_ISLAND`；主单文件移动端点按“向上”同样停在原节点。
- 输入根因：有效投影接缝的两个端点在屏幕上近乎重合，普通方向选择使用亚像素投影差判断上下，结果会随相机和浮点误差反转。引擎现按关卡已定义的 `connectorA → connectorB` 作为接缝上行方向，`↑` 只向高端跨越，`↓` 只允许从高端返回；普通实体边仍沿用屏幕方向选择。
- 几何根因：`B_HIGH_ISLAND` 的接缝落点位于高层平台内部 `0.804` 世界单位，人物和接缝会被平台及消防门遮挡。高层平台沿 z 轴平移至落点正好位于可见近侧边缘，落点顶面误差与边缘误差均为 `0.000`；接缝端点和跨越期间只临时提升人物渲染层，离开接缝后恢复正常遮挡。
- 触屏接通：`RpgGameHost` 的方向键事件新增订阅入口并传给 Three.js 楼梯关卡；零向量停止事件继续忽略。修复前移动端失败复现已转为按“向上”到达 `B_HIGH_ISLAND`，页面与控制台错误为 `0`。
- 回归合同：楼梯引擎由修复前 `46` 通过、`3` 失败变为 `51/51` 通过；关卡几何由 `140` 通过、`1` 失败变为 `141/141` 通过。真实键盘流程验证下层 `ArrowUp → B_MID_LIFT_LOW`、上层 `ArrowUp → B_HIGH_ISLAND`，并继续到 `phase=all_complete`。
- 成品验收：`npm run typecheck`、`npm run build:chapter4-stairs3d`、`npm run build:single` 均通过。生成后的独立页再次完成两关，主单文件确认 Three.js 可见且 Phaser 隐藏；`699×739` 与 `390×844` 无横向溢出、三个视角按钮均为 `48×48`。Blink、Gecko、WebKit 在 `390×844` 触屏环境中均通过“向上 → B_HIGH_ISLAND”，三者页面与控制台错误均为 `0`。
- 当前产物：`demo/chapter4-monument-stair-demo.html` 为 `6067525 bytes`，SHA-256 `55a608b7f7e6ec498c931ca3f0bd49ed054506f1a1249cb6c94f8386ed3f6ecf`；`demo/index.html` 为 `177019859 bytes`，SHA-256 `79a33a9d5d09787b5def7c0391be693eb13dc6e092ae0c1ef8b79b99f378340e`。

## 2026-08-11 第四章第二关上楼口净空与横移台侧向停靠

- 视觉根因：未接通的出口横移台原本与上层落点共用 x 坐标并沿相机纵深 z 轴待命，上方视角中的脚点净空只有 `8.54px`；人物在有效接缝端点又被强制绘制到最前层，组合后会把横移台读成墙体，并形成穿墙错觉。
- 失败合同：关卡验证器新增“未接通平台与上层落点屏幕净空”和“末档停靠中心”检查。修复前结果为 `141` 项通过、`1` 项失败；净空阈值按完整人物精灵提高到 `30px`，避免只保护脚点却遮住头部。
- 布局修正：出口横移台改为从右侧沿 x 轴滑入，初始中心为 `(8.1138, 8.3637, 5.7)`，每档向左 `1.7`；第 `2` 档精确回到 `(4.7138, 8.3637, 5.7)`，继续接通高层孤台与消防门。未接通状态的上楼口实际净空提升到 `58.78px`。
- 遮挡修正：人物静止在接缝端点时恢复 Three.js 真实深度遮挡；仅在投影接缝跨越动画期间临时提升渲染层，落地后立即恢复。上楼前、跨越中、落地后、横移台中档和末档画面均逐张检查，上楼口保持可见且没有实体穿墙读法。
- 浏览器闭环：生成后的主单文件在 Blink、Gecko、WebKit 中均完成两关；出口横移台通过真实画面点击选中并按两次 `E` 完成侧向停靠，最终状态均为 `phase=all_complete / playerNodeId=B_EXIT / b_exit_slide=2`，页面与控制台错误为 `0`。
- 回归与构建：关卡几何 `143/143`、楼梯引擎 `51/51`、材质合同 `26/26` 与 `npm run typecheck` 全部通过；`npm run build:chapter4-stairs3d` 和 `npm run build:single` 均完成。独立页为 `6067420 bytes`，SHA-256 `0e103093c7f473198a11f34e959e7e91260937d01e52e1032696650a5c8f6b08`；主单文件为 `177020406 bytes`，SHA-256 `395e9cb8bb3d40df70912598a13fe9c7f3c0ad68ac71a9c6adf47dd0120c1957`。

## 2026-08-11 755 米追逐分层景深增强

- 状态：本节的条带透视实现已被后续“755 米追逐生成式里程背景”替代；以下仅保留历史验证记录，不再代表当前运行时。
- 距离推进：背景先在固定 `320×180` 像素栅格中完成微动画混合，再按追逐距离进行分区透视。中央终点楼由 `1.00×` 连续推进到 `1.72×`；两侧近景额外获得最高 `0.18×` 横向推进和 `0.12×` 纵向推进，使侧楼更早靠近并移出视野。
- 连续性：分层推进按 `2px` 竖向条带采样同一张完整背景，保持道路、路缘和建筑之间的接缝连续；所有采样继续关闭图像平滑，避免重新出现写实插值或帧间尺寸抽动。
- 浏览器验收：Blink `1280×720` 自动避障跑至 `38m / 376m / 696m`，三段画面确认终点楼逐段拉近、侧楼放大并向画外推进、道路接缝连续，碰撞数始终为 `0`。Gecko `1024×768` 与 WebKit `390×844` 分别复跑至 `691m` 和 `688m`；三内核文档尺寸均等于视口，无横向溢出或页面、控制台错误。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check` 与 `npm run build:single` 通过。最新 `demo/index.html` 为 `177020516 bytes`，SHA-256 为 `9ab1c47df27891b6cc2c5a5ae92e3a3a1badc11afa007ebe52d56ff6c08937ce`。

## 2026-08-11 启真湖钓鱼曲《水纹 7:55》生成合同

- 单曲方案：新增 `qizhen.fishing / music_qizhen_fishing`，固定 `20.000s / 96 BPM / 4/4 / 8 小节 / D Dorian`。第 4、6、8 小节对应 `10s / 15s / 20s` 可结束落点，旋律短句音符数为 `7 / 5 / 5`。
- 生成处理：钓鱼曲禁用原脚本的淡入淡出，并在标准化前移除开头静音；旧三首启真湖环境曲继续复用，不修改文件和正式生成清单。
- 判定合同：每拍 `0.625s`，后续音乐、视觉环和输入判定共用 `AudioContext.currentTime` 的预定起点；禁止用连续 `setTimeout` 累积判定时间。
- MiniMax 实际调用：`/opt/homebrew/bin/mmx` 已接受生成命令并请求 `music-2.6`，服务端因当前 Token Plan 达到用量上限拒绝生成。脚本原子保护生效，未产生 `music_qizhen_fishing.mp3`、临时音频或部分清单。
- Phaser 兼容：节拍浮标的上半圆从非法 `Graphics.fillSlice` 改为 `beginPath / arc / fillPath`，保留原有外观且通过当前 Phaser 类型合同。
- 当前验证计数：`1` 次 `--verify-only` 正确只报告缺少 `music_qizhen_fishing`；`1` 次真实 MiniMax API 请求明确返回额度阻塞；JSON 配置、生成脚本语法、`npm run typecheck`、目标文件空白检查与 `npm run build:single` 通过。单文件为 `181237993 bytes`，SHA-256 `24f9f0009a999e15438a2e06a71c520355085fb55614af34876a4464efa514f3`。音频时长、节拍、和声落点与浏览器播放仍等待实际文件，当前不得视为生成完成。

## 2026-08-11 755 米追逐生成式里程背景

- 生图序列：以现有校园三车道像素底图为身份锚点，保留 `0 / 47 / 95 / 143 / 190 / 238 / 285 / 331 / 377 / 424 / 470 / 518 / 566 / 600 / 635 / 668 / 700m` 十七张过程图，并新增 `755m` 终点图。十八张画面均为 `1672×941`，不含人物、纸条、障碍和 UI；终点图让教学楼入口占据更大画幅，形成明确抵达感。
- 连续帧构建：新增 `scripts/build-canteen-chase-distance-atlas.py`。脚本对每个相邻生图区间生成 `16` 个预校准相机姿态，共导出 `273` 张不透明 `320×180` 帧，打包为 `5120×3240`、约 `6.1 MB` 的 `campus_avenue_distance_atlas_273f.png`。运行时不再同时嵌入十七张高分辨率过程图。
- 连续运行接入：`ChaseRenderer` 按当前里程直接选择图集帧，平均每 `2–3m` 前进一帧，并以 nearest-neighbor 放大到 `960×540`。对照试验排除了会产生重影、模糊或网点的透明混合、光流补帧和抖动混色；正式路径始终绘制一张完整不透明帧，人物锚点、画面外框和像素栅格保持稳定。
- 浏览器验收：Blink `1280×720` 连续检查 `92–102m`、`328–382m`、`468–476m`、`632–640m` 与 `668 / 690 / 700 / 720 / 750m`，共 `26` 个画面；Gecko `1024×768` 与 WebKit `390×844` 分别复验 `120 / 350 / 620m`。三内核均保持 `3` 次机会、`0` 碰撞和运行状态，页面与控制台错误、文档横纵溢出均为 `0`，画布保持 `16:9`。画面核对确认终点楼连续放大、两侧建筑持续前移，未出现旧式整帧跳变或双影。
- 构建验证：图集脚本实际重建通过，`npm run typecheck` 与 `npm run build:single` 通过。`demo/index.html` 为 `180393544 bytes`，SHA-256 `c8ea0096cac447481d47e67dde1ccc21aeade4dc4d6456ad7d7441686ed9c0e5`。

## 2026-08-11 启真湖场景内节奏钓鱼

- 玩法闭环：生锈钥匙、破损网框、小鲤鱼和纸条本体已接入 `precheck → rhythm → resolve`，只在谱面通过后调用原控制器发奖。普通鱼钩直抛纸条仍立即失败，不启动节奏。
- 判定与视觉：新增四张 96 BPM JSON 谱面、纯 TypeScript 张力模型与 Phaser 浮标水纹视觉。键盘、触摸、视觉和程序节拍器共用 `AudioContext.currentTime`，不可用时回退单调 `performance.now()`。
- 输入与生命周期：钓鱼期间船速和侧倾清零，镜头锁定浮标，划桨、模式切换、道具栏与普通字幕停用；页面隐藏和场景卸载取消本轮。两次失败后开启宽判定辅助，成功后清零该目标计数。
- 浏览器验收：Blink `1280×720` 完整键盘通过钥匙 10 秒谱和纸条 20 秒谱；纸条通过后只发生 `1` 次捕获与 `1` 次追逐入场，没有评级停顿。Blink `390×844` 三键约 `75×75px`，触摸首音判定 `perfect`且船速为 `0`。Firefox 和 WebKit 亦通过首音判定，全部浏览器错误为 `0`。
- 道具安全：钥匙在谱面开始后仍为 `false`，成功才加入道具栏；小鲤鱼谱失败后 `fishFeedPellets=true / smallCarp=false / fishCaught=false`，剧情阶段保持 `tool_chain`。
- 音频阻塞：MiniMax CLI 实际请求再次返回 Token Plan 用量上限，未产生 `music_qizhen_fishing.mp3` 或部分 manifest。当前主线由同时钟程序节拍保证可玩，时间线临时复用旧启真湖 SFX。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check` 与 `npm run build:single` 通过。新生成的 `demo/index.html` 为 `190904822 bytes`，SHA-256 `51ae70ae5ab2530dadc6c7139ac2386b857f8f2cf2149decc3734df5456b2ef8`；通过本地 HTTP 从 `c3-qizhen-open-water` 启动，画布和运行状态正常，无错误文件。

## 2026-08-11 启真湖水纹钓鱼隐藏朝向门槛移除

- 实际体验问题：水纹钓鱼的界面文案要求“船头对准”，但钓鱼玩法未把朝向呈现为可读、可稳定控制的判定条件。
- 交互修正：`fishing_spot` 和 `paper` 水纹目标改为只按皮划艇到真实目标边界的距离判定；码头储物柜、黑天鹅等有明确正面的实体仍保留朝向要求。
- 文案修正：装饵和抛竿指引改为“划到水纹附近”，道具栏通用文案改为“靠近目标 · 拖到目标上”，不再对所有道具目标误报朝向要求。
- 实际操作验证：Blink `1280×720` 从 `c3-qizhen-paper` 组合磁吸钓竿，划到纸条水纹约 `50px` 处后将船头转向目标反方向（朝向点积 `-0.897`）；拖入钓竿仍进入 `fishing.state=running / spotId=paper`，道具在节奏通过前保留，页面与控制台错误为 `0`。
- 验证与产物：`npm run typecheck`、`npm run build:single` 与目标文件 `git diff --check` 通过。`demo/index.html` 为 `180393544 bytes`，SHA-256 `c8ea0096cac447481d47e67dde1ccc21aeade4dc4d6456ad7d7441686ed9c0e5`。

## 2026-08-11 GitHub 提交前差异审阅规则

- 新增项目级约束：任何暂存、提交、拉取、合并、变基或推送前，先更新 GitHub 远端引用，分别展示未提交工作区、本地独有提交和远端独有提交；用户选定精确范围后才允许写入 Git。
- 首次执行：`git fetch --prune origin` 成功；当前分支 `codex/bike-rush-visual-redesign` 相对跟踪分支为 `ahead 2 / behind 0`，相对 GitHub 默认分支 `origin/main` 为 `ahead 0 / behind 3`。
- 工作区盘点：暂存区为 `0`；已跟踪修改 `72` 个文件，约 `7504` 行新增、`1226` 行删除；未跟踪文件 `387` 个。明确识别到 `scripts/.tmp-canteen-continuity-qa.mjs`、`scripts/__pycache__/*.pyc` 和调试 HTML，提交前必须单独排除或确认。
- 本轮只执行远端读取和差异审计，没有执行 `git add`、`git commit`、`git pull`、`git merge`、`git rebase` 或 `git push`。

## 2026-08-11 755 米追逐本地 Three.js 三维运行时

- 运行时替换：新增 `ChaseThreeRenderer`，使用仓库内 `three` 依赖构建真实世界坐标道路。骑手位置按 `distance × 0.22` 在世界 z 轴持续前进，相机跟随骑手，终点食堂固定在 755 米世界坐标之后；当前画面不再依赖整张背景向下滚动模拟前进。
- 本地建模：道路、人行道、路缘、树木、路灯、校园楼、终点食堂、纸条、骑手、自行车、路人和原有六类障碍全部改为本地低多边形像素块模型。骑手的前轮、前叉、龙头组成独立转向总成，左换道和右换道使用对应方向的转角，车身仅保留辅助倾角；轮胎、踏板、腿部和路人步态按时间连续更新，模型尺寸固定。
- 玩法权威：原 `ChaseGeometry`、碰撞、里程、机会数、旁白与 755 米结束条件保持为唯一逻辑来源；Three.js 只负责显示。旧 Canvas 图集渲染器保留为 WebGL2 不可创建时的兼容回退，并在画布 `data-chase-renderer` 标出实际后端。
- 兼容实现：WebGL2 直接在正式画布创建并传入 Three.js，避免额外探针占用上下文。Blink 无头 SwiftShader 无法创建第二个 WebGL2 上下文时安静回退旧 Canvas；Gecko 桌面与 WebKit `390×844` 触摸视口均实际进入 `three` 后端，移动端左右换道按钮正常显示，三者页面和控制台错误为 `0`、横纵文档溢出为 `0`。
- 运行验收：Gecko 正式 DEV 入口从 `18m` 驾驶至 `680m`，机会数保持 `3`、碰撞为 `0`。`333m` 与 `680m` 截图确认路侧建筑依次越过相机，终点食堂由远景持续扩大到占据道路尽头；前景路人、车辆、树木和灯柱呈现一致透视。
- 文档与构建：新增 `docs/canteen-chase-3d-runtime.md`，固化坐标、建模、画风、回退与验收合同。`npm run typecheck`、`npm run build:single`、目标文件空白检查均通过；生成的 `demo/index.html` 为 `180417224 bytes`，SHA-256 为 `3625e5fa16afb40d51c57273defec6d10f90452a33b0db701c48e4b939f006c4`。

## 2026-08-11 755 米追逐紫金港辨识度与转向近景

- 校园身份：3D 路线新增 `紫金港校区` 石牌、`求是路` 蓝色导视、`东区大食堂 →` 方向牌、两处校园自行车停放点和规则绿篱节点；沿街楼体统一为暖砖、米白竖向构件和蓝玻璃组合。
- 终点立面：东区大食堂补齐米白门廊、四根竖柱、双片蓝玻璃入口、四级宽台阶、绿篱、校园路灯和黄色像素门头，终点继续固定在 755 米世界坐标之外并随真实相机距离接近。
- 转向近景：骑手后视镜头降低并缩短跟随距离，车把、双前叉、前轮、青色握把和前灯在画面中可辨；车把转角提高至车身倾角约 `2.9` 倍，并按投影后的车头方向验证左右换道，避免只依赖世界旋转符号判断后视画面。
- 稳定性：所有近景部件继续挂在固定尺寸模型层级中，只改变旋转，不改变缩放或脚底锚点；画布公开 `data-chase-steer` 与 `data-chase-handlebar-steer` 供 DEV 验收。
- 浏览器验收：Firefox 与 iOS WebKit 均进入 `three` 后端，自动避障分别运行至 `680m`，保持 `3` 次机会、`0` 碰撞、`0` 页面与控制台错误；Chromium 无头 SwiftShader 进入 `canvas-fallback` 并完成同程验证。开局石牌、中段建筑层次、后段食堂门头和移动端触控画面已逐张检查。右换道采样为车身 `-0.420rad`、车把 `-0.465rad`，投影后的车头方向 `screenDx > 0`，与右侧目标车道一致。
- 构建产物：`npm run typecheck`、`npm run build:single` 与目标文件空白检查通过；`demo/index.html` 为 `180420381 bytes`，SHA-256 为 `42945a81536b3455b68b10af68ac7141412fb7411d836060e9bdf7f989d059d2`。

## 2026-08-11 755 米追逐终点剧场校正

- 剧情校正：食堂后的 `755m` 追逐终点由误用的东区大食堂立面改为求是大讲堂剧场入口；沿途方向牌同步改为 `求是大讲堂 →`。
- 视觉依据：按 `zijingang_campus_loop_panorama.png` 中剧场正面重建白色椭圆屋顶、弧形蓝玻璃幕墙、七根白色立柱、中央双门、四级宽台阶、花坛、路灯和入口标牌。
- 建模约束：建筑继续使用本地低面数几何、离散色板和硬边像素渲染，不引入远程模型、照片贴图或平面终点广告牌；终点仍固定在 `755m` 世界坐标之后，由相机真实接近。
- 运行验收：Firefox `1280×720` 从正式 `c3-canteen-chase` DEV 入口自动避障跑至 `561m` 与 `705m`，两处画面确认圆形屋顶、弧形幕墙、入口台阶和 `求是大讲堂` 标牌持续接近；机会数保持 `3`、碰撞为 `0`、页面和控制台错误为 `0`。
- 移动端验收：WebKit `390×844` 实际进入 `three` 后端，画布保持 `16:9`、触控换道按钮可见，文档横纵溢出与页面、控制台错误均为 `0`。
- 构建验证：标准网页游戏客户端已运行；`npm run typecheck`、目标文件空白检查和 `npm run build:single` 通过。`demo/index.html` 为 `180420955 bytes`，SHA-256 为 `678b18d9cbece15fe47b4174410e706023f6926193971967ccdf3f479a785afd`。

## 2026-08-12 755 米追逐道路两侧分区

- 路段轮换：沿途环境按草坪树阵、校园楼群、启真湖水岸三类分区循环，取消整段道路重复铺设暖砖楼的表现。
- 湖岸建模：新增两段固定世界坐标水面、硬边水纹、石质驳岸、远岸草带和湖畔玻璃大楼；两段水岸分列道路不同侧，与对侧草坪或楼群形成交替。
- 逻辑边界：环境模型只参与 Three.js 显示，三车道、障碍、碰撞、里程、机会数和终点剧场坐标继续由原控制器与 `ChaseGeometry` 管理。
- 运行验收：Firefox `1280×720` 从正式 DEV 入口自动避障跑至 `236m` 与 `557m`，两段截图分别确认右侧水岸和左侧水岸进入近景，草坪、树阵、玻璃楼与湖面按路段轮换；机会数保持 `3`、碰撞为 `0`、页面与控制台错误及文档溢出均为 `0`。
- 构建验证：标准网页游戏客户端、`npm run typecheck`、目标文件空白检查和 `npm run build:single` 均通过。`demo/index.html` 为 `180422205 bytes`，SHA-256 为 `3883f6267d968407a41f5b8e8bc2eb53ebb36a2b504c6b75048402e98aaaf707`。

## 2026-08-12 全局无损性能优化第一轮

- 部署资源：Vite 正式构建关闭 `public/` 自动复制。该目录只有已退役 Godot Web 导出，仍保留历史源文件，但不再进入活动浏览器产物。普通生产输出由 `188464 KiB / 362 files` 降至 `130236 KiB / 351 files`，减少 `58228 KiB`，约 `30.90%`。
- 字体体积：新增统一 `pixel-font.css`，只加载当前 Chrome 90+、Firefox 91+、Safari 15+ 均支持的 WOFF2 字体源。字形和像素风格不变，移除发行物中重复的约 `1.4 MB` WOFF 副本。
- Three.js 热路径：新增不可变基础几何与材质缓存；追逐静态路景再按共享材质合并。Firefox 正式 3D 路径从 `805` 次绘制调用、`861` 份 GPU 几何降至约 `192` 次调用、`72` 份几何；纸条、骑手、自行车转向、障碍、路人和透明阴影仍保留独立动画。该前后对照为 `1` 组同节点验证，当前按项目规则视为确定性优化数据，不外推到所有硬件的帧率增益。
- 运行时分配：骑手车头屏幕投影改为复用向量，DEV 性能数据改为每 `100ms` 更新，避免每帧创建临时向量和同步 DOM dataset。
- 共享封装：新增 `RpgAssetLoader`，统一玩家、校园底图、启真湖船体、第四章环境和 NPC 的幂等图片/精灵表预加载；场景重启不再重复排队同一纹理。该层不持有剧情、存档或资源卸载权。
- 单文件：`demo/index.html` 从 `180422205` 降至 `176500593 bytes`，减少 `3921612 bytes`，约 `2.17%`；SHA-256 为 `d8d47703250cb18cebd08195aa7c1477618c7fccd03a9068eef7d6f28cc2bc7c`。产物包含 `1` 个内联 module、`1` 个内联 style、`0` 个外部脚本、`0` 个外部样式和 `0` 个 HTTP 资源。
- 验证机制：移出 `demo/` 中与 `public/godot` 字节完全一致的退役副本；单文件验证器正式允许当前 Chapter 4 Three.js 楼梯调试页。`npm run verify:single` 和 `npm run verify:single -- chapter4-monument-stair-demo.html` 已实际通过。
- 浏览器回归：标准网页游戏客户端实际进入 755 米追逐、启真湖大湖、第四章二楼节点；Blink 食堂、Gecko 剧场、WebKit `390×844` 第四章三条补充入口均完成加载，字体状态为 `loaded`，文档横纵溢出为 `0`，页面与控制台错误为 `0`。启真湖和第四章截图已检查，原素材像素、碰撞位置和人物/NPC 显示保持。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single`、目标文件 `git diff --check` 与三内核 HTTP 回归通过。
- 后续边界：大 PNG 仍是单文件主体。第二轮只能采用解码像素哈希一致的 PNG 无损重编码或场景按需拆包；离线单文件要求所有关卡随包携带，因此场景懒加载只能降低启动解析和峰值内存，不能显著降低最终 HTML 体积。

## 2026-08-12 剧场 CC98 两波抢票委托

- 主线接入：抵达剧场后，CC98 出现“学生剧《7:55》临时退票”求助帖。玩家接单后回到剧场取票机，抢到的仍是半张票根 B，海报取得半张票根 A、合成临时观演票、闸机检票及后续节目单流程全部保留。
- 网络分支：第一波使用 `ZJUWLAN` 必定失败，明确显示“本次响应速度过慢”，并进入等待第二波；第二波未开启流量会继续被拦截。玩家可在剧场右上角切换 `流量 5G`。第一波已经使用流量时直接中票，手机系统显示“你的运气很好，但钱包就没那么好了。”
- 权威状态：`TheaterHuntState` 新增 `locked / posted / accepted / first_wave_failed / delivered` 有序阶段和 `cc98TicketClaimedWave`。CC98 页面、任务栏、手机通知、剧场取票机和开发检查点读取同一控制器状态。
- 存档兼容：存档版本升至 `19`；启真湖旧迁移固定在版本 `18` 阈值，并优先保留已记录 `complete / transitionReady / chaseDistance=1000` 的历史完成档，避免旧完成进度再次进入追逐。实测 v17 与 v18 的 `qizhenLake.phase=complete / paperReleased=true` 均保持 `complete`；v17 未完成的 `chase_ready` 仍正确迁移到 `swan_chase`；旧剧场后续档补为 `delivered / wave=2`。
- 开发入口：新增委托发布、接单、第一波过慢、第一波流量中票与回执交付节点，支持 `?devCheckpoint=` 直接检查两条路径。
- 浏览器验证：Blink `1280×720` 完成错误前置拒绝、第一波校园网失败、第二波未开流量拦截、切流量第二波成功、第一波流量直接成功、票根合成、CC98 深链和 v18 迁移；`390×844` CC98 委托面板无横向溢出。页面和控制台错误为 `0`。该完整矩阵当前验证次数为 `1`，跨内核结论仍待补充。
- 成品验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 和目标文件空白检查通过。生成后的单文件通过本地 HTTP 启动剧场检查点，Phaser 画布为 `1280×720`，网络按钮可切换至 `cellular`，页面和控制台错误为 `0`。`demo/index.html` 为 `176535261 bytes`，SHA-256 为 `632ea20628891a3d1ecfcb495030b2d2a1ce9e59004f19321816c6f1c02fcfe5`。

## 2026-08-13 剧场取票与检票链修复

- 真实根因：取票码虽然已经显示，控制器仍依赖隐藏的 `ticketCodeRead`；取票机固定要求朝右；入口到取票机的直线路径被南墙边缘误导；第一波失败对白锁定交互约五秒；面板开启后的首个指针输入可能被丢弃；第二波成功沿用失败事件和失败音效；两张半票的自动合成依赖一次性事件；闸机读票器可操作距离带过窄。
- 取票修复：正确输入 `0832` 时同步补记观察事实；取票机改为面向真实目标的朝向判定并扩大合理距离；大厅出生位上移到连续通道；面板只忽略打开它的同一次指针按下；已取票状态改为只读反馈；第二波使用独立成功事件与成功音效。
- 等待与任务：第一波失败后显示五秒第二波倒计时和网络状态，玩家可立即切换流量；任务栏按实际物品状态分别引导取得票根 A、合成 A+B、拖临时观演票到右侧读票器。
- 恢复与验票：剧场重新打开时检测 A+B 并恢复为临时观演票；闸机读票器距离扩大，仍保留朝向要求。Blink `1280×720` 从校园网第一波失败、切流量第二波成功、自动合票，到真实鼠标拖票过闸机进入 `program_search` 全链通过，事件与页面错误为 `0`。
- 边界验证：鼠标面板首次数字点击提交值为 `0832`；把 `ticketCodeRead` 人为设为 `false` 后正确输入仍能推进并补记观察；仅含 A+B 的开发检查点重新进入剧场后恢复为 `temporaryTheaterTicket=true`。Chromium、Firefox、WebKit `1280×720` 均加载剧场，画布和文档尺寸无溢出，错误为 `0`。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check`、标准网页游戏客户端、`npm run build:single` 与 `npm run verify:single` 通过。`demo/index.html` 为 `176539012 bytes`，SHA-256 为 `f9b61e0f4563af9fbf1556ee3546870516b5de27c7f03d011cfdec61c100eba5`。

## 2026-08-12 第四章微信证据链

- 角色边界：校园保安、保洁员仅作为 RPG 地图 NPC，不加入微信联系人。手机线使用“校园后勤服务”公众号、“麦斯威夜间自习群”、文件传输助手和原有朋友聊天。
- 证据闭环：公众号通知解锁一楼主电梯历史观察；历史提示音需在文件传输助手归档后才可开始三轨同步；二楼学生群路线截图是人员时刻观察的前置；三楼新旧导视照片需归档并请朋友对照后才可调整导视板。
- 任务引导：新增单一当前步的微信任务投影。任务条会切换到手机微信，完成该步后自动恢复 RPG 目标；手机主页微信图标只在有待处理证据时显示数字角标。
- 开发入口：新增 `c4-wechat-notice`、`c4-wechat-elevator-audio`、`c4-wechat-student-route` 和 `c4-wechat-wayfinding` 四个粒度节点，均种入完整楼层、阶段、历史证据与手机页面状态。
- 可见反馈：RPG 中缺公众号通知、录音归档、学生群路线或照片对照时，字幕会明确指向微信中的对应会话；所有手机动作都有成功、已完成或前置未满足结果。
- 浏览器验收：标准网页游戏客户端运行 `c4-wechat-notice`、`c4-wechat-student-route` 和 `c4-wechat-wayfinding` 节点并产出状态快照。Blink `430×860` 完成公众号阅读、录音归档、学生群截图、照片归档和朋友对照整链；Blink、Gecko 和 WebKit `390×844` 分别完成公众号阅读，文档溢出与页面错误均为 `0`。完整链和三内核基线当前各验证 `1` 次，仍属定向验收结果。
- 构建验证：`npm run typecheck`、目标路径 `git diff --check`、`npm run build:single` 和 `npm run verify:single` 通过。最终单文件 `demo/index.html` 为 `176535266 bytes`，SHA-256 为 `3dcd6227dcd8489011b7297c02740befbff9d53d59a1cca944325f1afa646a30`；产物包含 `2` 个内联脚本、`1` 个内联样式，三个离线 HTML 入口均完成验证。

## 2026-08-12 剧场取票链路修复

- 根因收束：修掉了三处直接卡住流程的问题。其一，`0832` 已经在深色观察中可见，但正确输入仍会被隐藏的 `ticketCodeRead` 状态拒绝；现在正确码会同步补记观察事实。其二，取票机、闸机和大厅出生位的几何判定过窄；现在出生位上移、取票机改为 `toward_target` 朝向、闸机读票器可达高度上调，近身判定和画面读法一致。其三，`半票 A + 半票 B` 只靠一次性事件触发合成；现在剧院重新打开时会自动恢复合成，避免 reload 或 DEV 节点把玩家卡在两张半票。
- 可见引导：剧场任务条改成随委托阶段切换。现在会明确提示接 CC98 帮抢委托、第一波失败后切流量、第二波回机输入 `0832`、半票恢复、以及把临时观演票拖到右侧读票器。取票机已完成后会直接提示“票根已经进入道具栏”，不再反复开码面板。
- 面板交互：数字面板去掉了基于固定毫秒的输入吞噬，改成只忽略打开面板的那一次原始按下事件。实际结果是面板打开后的第一次数字点击不会再被吃掉。
- 浏览器验收：Blink `1280×720` 实机完成了同一条剧院链路中的三项验证。`1` 次键盘路径：校园网输入 `0832` 后进入 `first_wave_failed`，切到 `cellular` 后第二次输入进入 `delivered`，并直接得到 `temporaryTheaterTicket=true`。`1` 次鼠标数字面板路径：面板打开后首次点击数字即可完成第一波失败分支，证明首击不再丢失。`1` 次几何路径：第二波成功后，人物可稳定走到闸机前并把最近目标切到 `theater_ticket_gate`，任务同步显示“把临时观演票交给检票闸机”。上述运行页面与控制台错误均为 `0`。当前跨内核验证次数仍为 `1`，结论只覆盖本轮 Blink 回归。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 均已实际通过。当前 `demo/index.html` 为 `176537375 bytes`，SHA-256 为 `f1be0073c6a2604e4a5d8d57a0809f43475da2db063bd510261aa3d7d730ef1e`。

## 2026-08-13 剧场抢票迁回手机 CC98

- 交互归位：接单与两波抢票全部在 CC98 帖子内的“手机票务 H5”完成。玩家先在剧场深色观察确认 `08:32`，随后回手机参加第一波；校园网必定得到网速过慢提示，控制中心切换移动数据后在同一手机页参加第二波。
- 第一波流量分支：若玩家在第一波提交前已经切到移动数据，手机直接记录 `claimedWave=1` 并显示“你的运气很好，但是钱包就没那么好了”。两条成功路径都生成 `0832` 手机取票码。
- 实体票分离：手机抢中后只写订单成功状态，不提前发放票根 B。剧场取票机在浅色操作中输入 `0832` 才打印 `theaterTicketHalfB`；已有票根时保持幂等，不会重复发放。原有半票 A、A+B 合成、闸机拖票与后续节目单继续复用。
- 重复界面清理：删除剧场右上角网络切换按钮、剧场第二波倒计时和剧场内两波成功/失败对白。普通 CC98 仍要求校园网；已接单的票务缓存页允许在移动数据下恢复，以免玩家切网后无法完成第二波。
- 任务与开发节点：任务条、手机通知、CC98 深链、剧场提示和五个票务 DEV 节点全部改成“手机抢票 → 剧场打印”的同一顺序。
- 浏览器验收：标准网页游戏客户端先覆盖 `first_wave_failed` 与 `delivered` 页面；Playwright 实际点击完成校园网第一波失败、控制中心切流量、第二波成功，最终为 `delivered / wave=2 / halfB=false`，手机回执显示 `0832`。独立第一波流量节点为 `wave=1 / halfB=false` 且指定文案可见。剧场控制器输入 `0832` 后为 `halfB=true`，任务切换到合成两张半票根。重建后的单文件经独立 HTTP 服务再次加载 `delivered` 节点，仍为移动数据、票根 B 未提前发放、取票任务正确，页面与控制台错误为 `0`。所有临时截图均已人工检查并移出工作区。
- 构建验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与目标路径空白检查通过。`audio:chapter3:verify` 仍只报告既有的 `music_qizhen_fishing` 缺失，未发现本次剧场音频事件错误。最终 `demo/index.html` 为 `176543367 bytes`，SHA-256 为 `262f8d69d455d15e7cac04786f8319d80f1fb1f99f96011f8e9c07d1c0fcf78c`。

## 2026-08-13 第四章微信群聊说明精简

- 删除“学生消息仅记录观察时间和方向，仍需回二楼核验。”说明栏。群聊页面只保留聊天内容和“保存路线讨论截图”主操作，后续返回二楼的引导继续由共享任务栏负责。
- 标准网页游戏客户端从 `c4-wechat-student-route` 打开微信群聊，确认按钮下方说明栏和占位已消失，聊天记录与主操作完整，页面和控制台无新增错误。`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与目标路径空白检查通过；最终 `demo/index.html` 为 `176543541 bytes`，SHA-256 为 `23b2a49ce5f3f2cd88e6f5ca13ece3e36c4fe181a8b04ddc67821b2c191563d9`。

## 2026-08-13 启真湖节奏钓鱼正式入口与验收

- 可达性修复：新增 `c3-qizhen-rhythm-key`、`c3-qizhen-rhythm-net`、`c3-qizhen-rhythm-fish`、`c3-qizhen-rhythm-paper` 四个 DEV 直达节点。节点分别把皮划艇放在真实钓点判定范围内，并种入该轮所需的观察事实、钓具和剧情阶段；普通启真湖安全出生点与正式存档不受影响。
- 玩法可见性：四次捕获均使用 `precheck → rhythm → resolve` 延迟结算。水纹提示改为“开始节奏钓取”，顶栏显示目标、进度、张力、连击，以及蓝色提竿、绿色左收线、黄色右收线的键位说明；移动端三键沿用同一颜色与按住/松开合同。
- 谱面覆盖：钥匙、网框、小鲤鱼、纸条分别加载 `8 / 14 / 20 / 26` 个节拍，支持收缩圆环、`Perfect / Great / Good / Miss`、张力、连击、长按音符、失败保留道具和两次失败后的辅助判定。
- 实机验收：标准网页游戏客户端从钥匙节点打开节奏界面，状态为 `running / locker_key / 8 notes`，视觉中圆环、浮标、状态栏和按键说明均可见，浏览器错误为 `0`。额外实机按 96 BPM 完成全部八拍后，`rustedLockerKey=true` 且任务推进到“用钥匙打开码头储物柜”；四个直达节点都成功进入相应谱面且音符数量与配置一致。
- 声音降级：专用 `music_qizhen_fishing.mp3` 仍因本机没有可用 MiniMax CLI 产物而缺失；运行时临时复用现有 96 BPM `music_qizhen_mist`，并叠加 Web Audio 节拍器，缺音频不会阻塞玩法。`audio:chapter3:verify` 当前为 `76 / 77`，唯一缺项仍是专用钓鱼配乐。
- 单文件：`npm run typecheck`、目标路径 `git diff --check`、`npm run build:single`、`npm run verify:single` 通过。生成后以独立 HTTP 服务再次从 `c3-qizhen-rhythm-key` 启动，状态为 `running / 8 notes` 且页面错误为 `0`。`demo/index.html` 为 `176572880 bytes`，SHA-256 为 `427c3237114b152db1f9ee900efad52961dda9b61bab02a9b74a53f0030441cc`。

## 2026-08-13 启真湖节奏钓鱼 A/S/D 三键统一

- 输入收束：节奏会话内固定为 `A` 左收线、`S` 提竿、`D` 右收线；方向键和空格不再参与节拍判定。离开节奏会话后，`S` 继续承担皮划艇后划修饰键，湖区普通移动合同不变。
- 触屏一致性：移动端按钮改为从左到右 `A 左收线 / S 提竿 / D 右收线`，三枚按钮约 `75×75 CSS px`；`390×844` 下文档横纵溢出均为 `0`。
- 可见提示：浮标音符字形、顶部窄状态栏、任务提示和 DEV 节点均改成 A/S/D，不再显示独立空格提竿提示。正式开局仍由拖入当前钓具触发，避免 `S + A/D` 后划组合误开节奏玩法。
- 实机验收：标准网页游戏客户端进入钥匙谱并确认状态栏、收缩圆环和 A/S/D 字形可见，状态快照为 `running / 8 notes`，页面错误为 `0`。真实键盘按 A/S/D 完成 10 秒钥匙谱后，`rustedLockerKey=true`、任务推进至“用钥匙打开码头储物柜”、船速保持 `0`；会话内额外按空格后 `judged` 仍为 `0`，证明空格不再判拍。Blink、Gecko、WebKit 均以真实 `S` 命中首个提竿音符，判定计数为 `1`、张力保持 `50`、页面错误为 `0`。
- 构建验证：`npm run typecheck`、目标文件 `git diff --check`、`npm run build:single` 与 `npm run verify:single` 通过。单文件 `demo/index.html` 为 `176572634 bytes`，SHA-256 为 `16664923bc685e05767e9c8f2c07accd35bca2aca517813d907cc4739087ab61`。
- 后续交付范围：用户指定后续 GitHub 上传只整理剧场手机抢票、启真湖和段永平教学楼三部分；提交前仍需按仓库规则先 fetch 并分别展示工作树、相对远端的本地提交和远端新增提交，由用户确认精确文件范围。

## 2026-08-15 启真湖拍照记录相机端到端接线

- controller 事务:`ChapterThreeQizhenLakeController` 新增 `precheckPhotoCapture`(只读,零写入零事件)、`capturePhoto`、`saveJournalDraft`、`discardJournalDraft`。拒绝原因码统一为 `inactive / swan_chase / journal_locked / journal_archived / unknown_spot`,草稿另有 `orphan_photo / draft_mismatch / incomplete_draft`;`locked → capture_ready` 在首次通过的拍摄写事务中推进,预检保持只读。拍摄幂等键取场景会话单调秒数,重复快门同 id 直接返回既有结果,不重复写、不重复发事件。
- 存档 v21→v22:`SAVE_VERSION` 升 `22` 且 `SUPPORTED_ENVELOPE_VERSIONS` 同时保留 21;修复 `normalizeQizhenLake` 完整字面量缺 `journal / dockCollisionCount / swanAlertLevel` 的编译断点。旧档无 journal 字段时补默认值;已完成启真湖的旧档直接迁为兼容归档(`archived` + 空照片只读占位),预检与拍摄一律以 `journal_archived` 拒绝,不回退到拍照任务。已有 journal 的存档逐字段 sanitize,照片记录显式重建,只保留 recipe 合同字段,Base64/canvas 数据在重建时被丢弃。
- host 接线:`RpgGameHost` 订阅场景 `qizhen_photo_session_requested`,先预检、拒绝走既有字幕层反馈;通过后统一在 `rpg-shell` 内挂载 `QizhenJournalCamera` 覆盖层(现状只有这一条挂载路径,桌面分屏与窄屏共用),并回发 `qizhen_photo_session_opened/closed`。会话打开期间闸住 Phaser 输入、键盘、全屏键、任务栏、道具栏、模式开关与划桨按钮;关闭时丢弃未存草稿(已存草稿保留)、恢复 canvas 焦点并 resetKeys 防粘连;`visibilitychange` 隐藏与宿主卸载视同关闭。
- 跨合同最小修补:场景侧主/补拍 `kind` 判定从 `!mainPhoto` 改为与 controller 一致的「主帖未发布」规则,修复主帖草稿存盘后重拍/重开相机会变成空选项补拍的死路;会话请求 payload 增加 `capturedAtSeconds` 单调秒数;调试类型同步该字段;相机样式文件追加覆盖层定位规则。
- 验证:`npm run typecheck` 全树零错误,`npm run qizhen:validate-journal` 通过。esbuild+node 沙箱脚本(临时文件,已删除)实际跑通 49 项断言:v21 未开始/工具链中/追逐中/已完成四类样本迁移落地、主帖与补拍完整事务、幂等重放、草稿闸门、归档档 v22 往返幂等。`build:single` 按计划留待下一波 QA 统一执行。

## 2026-08-15 启真湖相机模块浏览器验收与单文件构建

- 构建:`npm run build:single` + `npm run verify:single` 通过。最终产物 `demo/index.html` 176,625,037 字节,SHA-256 `00f6ab26f9a782295e09ec0d4ddf1c18e30495224aa2b19f6bc80f6d740427f5`(含本次三处修复后的重建;修复前首建 176,625,030 字节 / `5a1576a1…edf6e`)。
- 验收中修复(仅触本批新文件):`RpgGameHost.tsx` 会话打开期间隐藏 `rpg-system-actions`(聚焦手机/全屏)按钮组,此前未随 `photoSessionOpen` 闸住;`qizhen-journal-camera.css` 覆盖层 z-index 44→84,压住桌面分屏壳层任务条(触发器 76/抽屉 77/桌面条 80),原层级下任务条在会话期间可见且可点开抽屉;`QizhenLakeModel.ts` 的 `bucketQizhenSwanDistance` 阈值 260/520→330/430——swan_cove 站位区 (700,420)–(900,560) 到鹅锚点 (1160,400) 的可达距离带约 261–487 源像素,原阈值下 near/far 两档均不可达,`swan_near/swan_far` 标签永不出现。
- 验收工具:playwright-core + chrome-headless-shell(另备 gstack)。自动化零保持时间的按键不会触发 Phaser `JustDown`(同一帧内 keyup 清 `_justDown`),真实保持按键一切正常——属工具假象,非产品缺陷。
- 浏览器矩阵,Blink 1280×720(dev server 与单文件 HTTP 各跑一遍主流程):
  - a. 零 console/page error;画布精确 16:9(1280×720);文档无溢出。
  - b. 站位区外按 C → 底部字幕「这里构不成画面,再往湖心靠一靠。」且不开相机;湖心 (752,464) 按 C → 相机打开,取景底图+皮划艇+水平参考线+速度/侧倾读数+拍摄点名「湖心」+「拍摄」按钮齐全。
  - c. 会话期间船位冻结不动、瞬时速度缓降归零(快照 139 → 0 约 1.5s);A/D/Space 与画布指针点击均零事件。
  - d. 快门 → 冻结画面 + 标签芯片「构图在线」+ 标题/状态三选一;未选齐「存为草稿」disabled;选齐保存 → 「草稿已保存,可前往 CC98 发布。」;journal 状态 locked→capture_ready→main_draft 逐步推进。
  - e. 重拍回取景并回滚未发布照片与草稿(status 回 capture_ready);再拍沿用已存标题/状态选择;Esc 与「收起相机」均可关闭;关闭后划桨立即响应、无按键粘连(resetKeys 生效)。
  - f. 控制中心「立即保存」写入正式存档(v22 含 mainPhoto+pendingDraft);无 dev 参数刷新后直接回到湖区 kayak 状态,journal 不回退,debug `qizhenLake.photoCamera` 正常。
  - g. 码头栈道 on_foot (669,635) 开相机(kind spot),补拍说明三选一存草稿 → `optionalPhotos.dock`;黑天鹅区近带 (888,459) → 芯片「黑天鹅贴脸」+ `--near` 剪影,远带 (739,546) → 「黑天鹅在远处」+ `--far`。
  - h. 桌面 1024×768(非 16:9、非分屏路径):画布 letterbox 1024×576、覆盖层与壳层等齐、任务栏正确隐藏;390×844 触控(coarse):画布 390×219,画布内「相机」按钮点按开/关正常,覆盖层全屏布局无溢出,快门→三选一→存草稿完整,零报错。
  - i. `visibilitychange`(hidden + visibilityState 双覆盖模拟)→ 会话取消、未存草稿与未发布照片回滚、零报错。
- Gecko(Firefox 1539)与 WebKit(2342)1280×720 冒烟:开相机→快门→三选一→存草稿全过,零 pageError;Gecko 仅见 WebGL 探测与 AudioContext 自动播放策略告警(预期,按合同不阻断状态流转)。
- 已知边界(按既定语义记录,不属本模块修复范围):主帖草稿挂起时保存补拍草稿,`pendingDraft` 单槽被补拍草稿顶替(`mainPhoto` 与 `mainTitleId/mainStatusId` 保留,主帖重拍沿用选择);湖心主帖重拍的空说明路径需主帖发布后才出现,本轮未进入。
- 回归命令:修复后 `npm run typecheck` 零错误、`npm run qizhen:validate-journal` 通过(3 标题/3 状态/9 补拍说明/8 标签/4 点名/12 相机文案键,确定性检查通过)。过程截图全部置于 /tmp,检查后已删除;仓库改动仅上述三个源文件与重建产物 `demo/index.html`,无残留。

## 2026-08-17 当前工作区单文件 demo 重建

- 交付：按当前工作区源码执行 `npm run build:single`，重建离线单文件 `demo/index.html`；本次未创建提交、未推送、未合并，保留现有未提交内容。
- 验证：TypeScript 检查与 demo 构建均通过，593 个模块完成转换；`npm run verify:single` 通过，确认产物包含 2 个内联脚本、1 个内联样式，且三份离线入口均在校验白名单内。
- 产物：`demo/index.html` 为 `176,637,393 bytes`，SHA-256 为 `160d3d4602e2550b81b1f1bae85a795afff78053cdf3b9cd0032e7573104273c`，生成时间为 2026-08-17 15:54:06 CST。

## 2026-08-17 第四章 A1 墙后通行与前景遮挡

- 修复：将一楼面包坊与中厅之间的竖向隔断、105 教室西侧墙从静态碰撞集合移出，改为基于同一张源图的前景裁切遮挡。人物可进入原先被提前拦住的地面区域，进入墙后区域时墙体像素覆盖人物；桌椅、柜台、花盆和外部边界维持原碰撞。
- 合同校验：布局验证器新增 A1 前景遮挡检查，要求两块遮挡存在且对应旧整墙碰撞不得回流。
- 验证：`npm run chapter4:validate-topology`、`npm run typecheck`、`npm run build:single` 与 `npm run verify:single` 通过；本地 HTTP 的 A1 场景已启动，调试碰撞层与控制台检查无错误或警告。重建后的 `demo/index.html` 为 `176,638,338 bytes`，SHA-256 为 `3574c8bfce567bc0c4525bb124b9ed770963a3620f1245294105d7e2e383e15b`。

## 2026-08-17 手机主页开花联动与 CC98 顶栏收束

- 主页盆栽读取 `flowerBloomed || flowerEightTaken`。完成开花的正常存档、旧存档和已有后续 DEV 节点都会显示同一朵四色花瓣与黄色花心；花瓣配色与“照片”应用图标一致，盆栽入口行为保持不变。
- CC98 帖子顶栏的退出控件由大号空心图形改为 `8px` 黑色圆点；控件本身仍保留 `44px` 高的点击区、原有无障碍标签和返回热门话题行为。
- 验证：`npm run typecheck` 与目标路径空白检查通过。本地开发页从第二章 DEV 节点确认盆栽为 `is-bloomed`、标签为“湖边盆栽，已开花”；剧场票务帖子确认黑点为 `8×8px`、控件为 `44px`，点击后成功返回热门话题，浏览器错误为 `0`。
- 开发约束：按用户要求，本轮未运行 `build:single`，未重建 `demo/index.html`。临时浏览器 QA 图片已移入废纸篓。

## 2026-08-17 022 照片证据生成底图接入

- 素材：先固定“二楼南区 022 书包、OCR 卡、桌面反光”的像素风生成提示词，再生成原始图并压缩为 `968×726` WebP；产物从约 `1.4 MB` 降至约 `35 KB`，新增路径为 `src/assets/ui/photo-evidence/library_022_reflection.webp`。
- 接入：照片识别页以该 WebP 作为真实照片底图；现有亮度、反光、像素噪点、扫描线、OCR 框和识别成功态继续由 React 状态驱动，因此控制中心亮度仍会影响读图过程。
- 验证：`npm run typecheck` 通过，目标源码空白检查通过。本地开发页从“照片识别报告”DEV 节点实际拍摄后确认底图加载、扫描态和 OCR 覆层均出现。按用户要求，本轮未运行 `build:single`，未重建 `demo/index.html`。

## 2026-08-17 第四章主电梯门前景深度

- 修复：主电梯门从固定高层级改为按门片下沿计算的室内深度（`4159`）；人物站在电梯站位（脚点 `y=204`）时深度为 `4204`，会遮挡门片。人物走到门片后侧时，门片仍可按纵深遮挡人物。
- 动画：历史登梯、普通登梯和到站离厢阶段同步采用门前人物层级，避免开门、上行和落地三个阶段出现遮挡跳变。
- 验证：`npm run typecheck` 通过；本地 Chapter 4 主电梯节点可正常进入、画面无控制台错误。按用户要求，本轮未运行 `build:single`，未重建 `demo/index.html`。

## 2026-08-18 第三章半手机取证与相机相册串联

- 剧情衔接：启真湖黑天鹅追逐完成后回到手机，进入“未同步的七分五十五秒”恢复流程。正式路径依次要求 CC98 离湖记录、七帧动态照片、楼宇服务通知与网络记录、四段录音，再排除三个旧时间并确认段永平教学楼一楼；旧纸条直接飞入教学楼的过场不再拥有独立入口，只作为四项证据通过后的恢复回放。
- 状态与存档：新增第三章半控制器、持久状态、任务投影、功能门槛、存档迁移与七个 DEV 检查点。第四章入口同时校验证据齐备、干扰项排除、时间线顺序和目的地解释，直接调用页面或旧完成标记不能绕过取证。
- 相机与相册：启真湖相机继续把湖心、码头、倒影和黑天鹅照片写入 `qizhenLake.journal`；照片应用新增相簿架，同一状态中的拍摄结果进入“启真湖划船”，恢复工具找回的七张动态照片进入独立“恢复的项目”。两组照片不互相覆盖。
- 生图策略：先在 `docs/chapter-3-5-photo-evidence-prompts.md` 固定 Image 2 提示词，再以启真湖色板和夜间湖岸像素光照为参考生成同机位 `3×2` 帧板。正式接入五张 `512×512` WebP：纸条左、中、右连续帧与两张早期湖面帧；另两张干扰帧由连续帧水平翻转得到。每张约 `61 KB`，无文字、界面、白边或水印。
- 第四章重绘兼容：当前照片只表现湖岸灯柱、水纹、纸条、船头和远处仍亮灯的校园长廊轮廓，不写入楼梯、电梯、教室编号或楼层布局。第四章的走廊、门牌和室内照片延后到最终地图定稿后生成，并以最终运行地图作为唯一构图参考。
- 浏览器验收：Blink `1280×720` 从 `c3-interlude-photos` 进入照片应用，相簿架、七张恢复帧和正确顺序反馈均可用；七张图片全部完成加载，天然尺寸均为 `512×512`。选择 `B2 → 91 → 4C` 后得到“纸条向东离岸”证据。`c3-interlude-reboot` 能从主页恢复通知进入工具并停在 CC98 起点门槛；`c3-interlude-replay` 只在目的地确认后出现播放按钮，点击后进入带 `RECOVERED TIMELINE` 标记的 RPG 回放。`390×844` 复验文档横纵溢出均为 `0`，七张图片仍完整加载，控制台和页面错误为 `0`。
- 合同验证：`npm run typecheck`、`npm run qizhen:validate-journal`、`npm run chapter4:validate-topology`、相关已跟踪文件和新增文本文件的空白检查均通过。按开发阶段约束，本轮未运行 `build:single`，未重建 `demo/index.html`。

## 2026-08-18 第三章半双配乐接入与单文件交付

- 音乐接入：将用户提供的《启真湖的倒影》接入第三章半“打开恢复工具”之后的手机取证阶段，循环音量为 `0.15`；将《夜风把它送进教学楼》接入“播放恢复回放”与第四章序幕，循环音量为 `0.16`。
- 音频冲突修复：恢复回放期间保留底层启真湖场景，但不再发布湖区入场音乐事件，防止旧湖区配乐覆盖《夜风把它送进教学楼》。序幕完成或关闭仍由原有音频清理事件停止音乐。
- 单文件：`npm run typecheck`、`npm run build:single`和 `npm run verify:single` 全部通过。产物 `demo/index.html` 为 `192,116,388 bytes`，包含 `2` 个内联脚本、`1` 个内联样式和已内嵌的两首 MP3，SHA-256 为 `999a68a598cb9a1678f3e9398abffd9f52e5d3e25da3470255fe35c4171171ba`。
- 浏览器验收：Blink `1280×720` 中实际点击“打开恢复工具”后，播放中的音频 SHA-256 与《启真湖的倒影》源文件一致；点击“播放恢复回放”后，播放中的音频 SHA-256 与《夜风把它送进教学楼》源文件一致，旧湖区音乐未再抢占通道，页面与控制台错误为 `0`。触屏 `390×844` 复验回放音乐正常，文档横纵溢出均为 `0`。网页游戏客户端截图完成目检后已删除。

## 2026-08-18 天气页外出打卡前提示

- 条件文案：浙大体艺尚未开始课外锻炼时，天气水滴卡片改为“还没有开始外出打卡”，并提示“你都还没有开始外出打卡，一滴雨都不会落到你身上。”；开始锻炼和已收集状态保持原有反馈。
- 验证：`npm run typecheck` 与目标文件空白检查通过；按当前开发约束未运行单文件构建。

## 2026-08-18 照片应用旧照预览与 022 取证链

- 素材：先在 `docs/library-photo-roll-prompts.md` 固定 Image 2 生成提示词，再生成六张校园旧照的联系表。关键照片同时保留深蓝色书包、铜色 `022` 标牌、侧袋半包纸、`07:55` 时间和未开花盆栽，作为后续物品报告的实际证据。
- 压缩：六张切图先缩至 `160×160` 像素格再以近邻算法放大到 `320×320` WebP，单张约 `10–18 KB`，清理了高频细节并保留线索数字可读性。
- 交互：照片应用的六个占位格改为真实缩略图按钮，点击后在手机画幅内打开大图、文件名和现场说明。`022 旧照` 仅在主照亮度降到 `20%` 以下且 OCR 稳定后允许“用旧照补全物品报告”，确认后调用现有 controller 进度接口，未新建界面私有进度。
- 主页：“记录恢复”改为文档与时钟图标，“录音”改为话筒与波形图标；第一章开花后的湖边盆栽移到桌面右侧。
- 验证：`npm run typecheck` 通过；Blink `1280×720` 实际跑通“拍摄 022 书包 → 控制中心亮度 12% → 打开 022 旧照 → 写入物品报告”；六张图片均完成加载，天然尺寸均为 `320×320`。触屏 `390×844` 再次跑通旧照打开和进度按钮解锁，文档横纵溢出均为 `0`，页面与控制台错误为 `0`。按用户开发期约束，本轮未运行 `build:single`。

## 2026-08-18 启真湖三源交叉检索台

- 线索获取：CC98 的桥边目击、馆藏检索的倒影异常、微信中的湖面水纹各自保留来源和原句。微信线索改为玩家主动保存，聊天结束不再自动写入地图进度。
- 推理交互：校园地图删去上下两组重复线索卡，改为单一“交叉检索台”。每条来源仅出现一次，状态明确区分“未取得、导入、已接入”；第三条导入后只进入待核对状态，玩家点击“核对交点”后才确认启真湖并开放入口。
- 进度权威：`ChapterThreeQizhenLakeController` 新增独立地点确认事务；线索导入和地点解锁拆为两个控制器阶段。任务栏在三条记录齐备后切换为“在校园地图核对地点交点”，避免继续显示泛化找地点提示。
- 视觉：三条来源行通过左侧连线汇入一个中心交点，待核对时显示短脉冲；解锁后沿用原启真湖结果卡。布局保持既有像素界面和 430×860 手机合同，没有增加新的全页素材。
- 验证：`npm run typecheck` 与目标路径空白检查通过。本地 HTTP 从 `c3-qizhen-map` 实际完成“导入微信地点词 → 出现核对交点 → 点击核对 → 显示启真湖入口”；浏览器错误和警告均为 `0`。`390×844` 下文档宽高均无溢出，手机框为 `354×708`。按当前开发约束未运行 `build:single`。

## 2026-08-18 启真湖全朝向交互与公众号可选阅读

- 启真湖交互：全部 30 个湖区交互目标显式声明 `up / down / left / right` 四向均可。键盘空格、场景点击、道具拖放、落点框高亮和传送入口统一只检查距离、现实模式与当前剧情条件；人物朝向继续服务划船运动、转弯和追逐表现，不再阻塞拾桨、登船、开柜、投喂、钓取和道具组合。
- 朝向验收：开发服务器运行时确认码头目标调试数据包含四个有效方向；随后对 30 个目标逐一执行四方向判定，共 120 个组合全部返回可交互。`npm run typecheck`、`npm run qizhen:validate-journal` 与目标路径空白检查通过。
- 公众号结构：微信中的“校园后勤服务”增加公众号主页、主线通知卡、校园日常、往期推文、正文阅读页和三项底部菜单。主线通知继续调用第四章控制器；六篇校园生活文章保持只读，不写任务、存档或地点解锁状态。
- 公众号文案：六篇可选文章覆盖雨伞暂存、晚自习收尾、餐盘回收、共享单车、水鸟观察和失物招领，并按 `human-writing` 完成口语化审校。页面删除开发说明口吻，只显示正常的文章数量、日期和阅读信息。
- 浏览器验收：Blink `1200×638` 和触屏 `390×844` 均实际跑通“微信列表 → 公众号主页 → 往期列表 → 可选正文 → 返回主页”；手机框尺寸稳定，文档无横纵溢出，页面错误与警告均为 `0`。按开发阶段约束未运行 `build:single`，未重建 `demo/index.html`。

## 2026-08-20 MiniMax H3 第三章至第四章纸条锚点修正

- 锚点：停止直接上传 `64×64` 纸条精灵，新增三张 `1024×1024` H3 专用主体锚点，分别来自运行时 `paper_flight_0`、`paper_flight_2` 和 `paper_flight_4`。原始画布以最近邻算法放大到 `768×768`，居中合成到统一的 `#273142` 无纹理背景。
- 素材边界：移除未参与第四章序幕运行时的荧光纸条参考，纸条身份固定为暖米白纸体、棕褐磨损与右上暗红八角星形印记；青蓝风痕继续作为独立场景效果。
- 提示词：更新五段 H3 上传表、主体定义、保留分析与动作描述；关灯段改用低照度纸条锚点，其余段按正面和弯折锚点控制形态。
- 验证：三张派生图均为 `1024×1024`、8-bit sRGB、无透明通道；逐张下采样后的 RGB SHA-256 与相应原始精灵合成结果完全一致。未修改运行时代码，因此未运行 TypeScript 和单文件构建。
- NPC 锚点：新增学生、保洁员、清洁车、保安与灯控动作共七张 H3 专用锚点。身份图使用 `1024×1024`，动作图使用 `1536×1024`、`2048×1024` 或 `3584×1024`，统一采用 `#667386` 无纹理蓝灰背景并保持整数倍最近邻放大。
- NPC 源图清理：`guard_check_watch_2frame.png` 与 `cleaner_toggle_lights_2frame.png` 底部存在断开的头部残片；派生锚点仅排除 `y=116–127` 残片区域，完整人物、脚底阴影、道具和动作帧均保留。
- NPC 提示词：三段人物场景明确声明动作表中的重复人形为同一角色的连续动作阶段，目标画面只渲染一名对应角色和一套道具，纯色参考背景不进入成片。

## 2026-08-20 第四章 7:55 主线实施基线

- Git 基线：当前分支为 `codex/bike-rush-visual-redesign`，HEAD 为 `c667bab 食堂动画`。`git status --short` 显示大量既有已修改和未跟踪文件，工作区很脏；当前任务按已批准的共享工作区计划冻结现状，不创建会与并行编辑脱节的 worktree，也未执行 stage、commit、push、clean、restore 或 reset。
- 本轮并行实施分工：asset lane 负责 `src/assets/rpg/interiors/finale/chapter4-755/**`、`finale_environment_manifest.json` 和资产脚本；state lane 负责 `src/core/**`、`src/modules/ChapterFour*`、第四章内容 JSON 与存档迁移；scene lane 负责 `ChapterFourTemporalMazeScene.ts`、`RpgGameHost.tsx`、第四章组件与样式；integration lane 负责 Quest、DEV、debug、CI、文档和生成的 `demo/index.html`。该分工仅用于本次 7:55 实施切分，不改变仓库长期文件所有权。
- `npm run chapter4:validate-topology`：退出码 `0`，输出 `Chapter 4 topology valid: 6 legacy floors, 5 connectors, 3 runtime floors, 13 puzzles.`。该结果只验证旧版六层、五连接器和 `13 puzzles` 合同，不能证明新的 7:55 剧情、资产、碰撞或追逐流程已实现或验证。
- `npm run typecheck`：退出码 `0`，`tsc --noEmit` 通过。
- `npm run verify:single`：退出码 `0`；现有 `demo/index.html` 为 `192116388 bytes`，含 `2` 个内联脚本、`1` 个内联样式，白名单入口为 `campus-map-demo.html`、`chapter4-monument-stair-demo.html`、`index.html`。该结果只证明 `demo/` 中现存历史产物满足离线封装结构检查，不证明它与当前脏工作区源码同步，也不构成新 7:55 主线的已验证产物。本基线未运行 `npm run build:single`，未重写单文件产物。

## 2026-08-20 第四章 7:55 三层结构母图资产门阻塞

- 全图 `precise-object-edit` 试验输出保留在 `/Users/zhuhangcheng/.codex/generated_images/01a01efd-db9b-7d32-bc34-a49ec2d97dbd/exec-799d9b98-22b3-4054-b908-f8d5d07244df.png`，尺寸为 `1671×941`。门洞中心约为 `x=782`，相对合同 `x=836` 误差约 `-54px`；楼梯约为 `x=933..1043, y=81..219`，未满足 `932,145,138,107`；A1 指定门洞位置错误，且头像、家具等非指定区域被重绘，因此未接入。
- 确定性临时原型已删除，仅保留以下量化结论：仅局部电梯 `72×96 @ (800,63)`、楼梯 `138×107 @ (932,145)` 和门洞裁片的逐像素校验为 `AE=0`。整图原始尺寸与 `960×540` contain 目检均因中央地砖填补边界的明显拼贴缝和 A1 门洞浅色块判定为 FAIL，局部 `AE=0` 不能视为视觉合格。全图变化为 `98,646` 像素，占 `6.2698%`，声明允许区外变化为 `0`；临时原型、差异图和视口评审图已在记录结论后删除。
- 第二次仅针对 `390×252` 中央核裁片的局部 `imagegen` 调用因长时间没有返回结果，由主代理终止；该调用没有形成可验收输出，也未作为资产结果。
- 正式 `src/assets/rpg/interiors/finale/chapter4-755/base/a1.png`、`a2.png`、`a3.png`、同目录 `README.md` 和 `scripts/normalize-chapter4-755-assets.mjs` 均未创建。三个 `artifacts/chapter4-map-assets-20260820/base/` 候选原图保持不变；本轮没有 Godot 修改、Git 状态变更命令或 `build:single`。
- 最小解阻条件：提供三张人工校正母图，或提供支持 mask 与源像素坐标锁定的局部编辑能力；三层必须同时满足主电梯中心 `x=836`、有效门片 `72×96`、楼梯边界 `{x:932,y:145,width:138,height:107}`，A1 还需真实可见且净宽至少 `62px` 的面包坊门洞。正式解阻以创建 `src/assets/rpg/interiors/finale/chapter4-755/base/a1.png|a2.png|a3.png` 并满足量化与视觉合同为准；九张状态图修订能力必须可复用到同结构资产。质量门不得通过降低坐标、边界连续性或视口观感要求来绕过。

## 2026-08-20 第四章 7:55 剧情合同与 v25 存档迁移

- 内容合同：新增 `chapter4-755.content.json`，固定 13 个有序阶段、6 个时间态、首次拨钟的原子时间源切换、A2/A3 教室复原、5 区灯控、保安状态、17 项物品事务、校园卡与纸条两个签到目标和 07:55 完成不变量。活动合同不包含旧 `08:00` 或 `B2-04` 终局。
- 状态与物品：新增新主线时间权威、世界/手机时间、204 教室摆放、灯控、追逐、签到与完成状态，以及签到记录纸条、旧时针、钟面定位片、短撬棍、通用润滑油、最后一分钟六项物品。旧控制器字段保留在显式 Task 5 兼容边界内，v25 水合会清空旧谜题事实。
- 存档迁移：版本由 `24` 升至 `25`。v24 未开始存档进入新开场；进行中存档恢复到 A1 开场检查点并清除第四章不兼容事实；已完成存档迁移到可信 `07:55` 完成态。迁移探针同时确认主存档损坏时使用上一份快照，以及保存时关闭控制中心、物品栏和选中物品。
- 验证：`npm run chapter4:validate-story` 与 `npm run typecheck` 通过；旧 `08:00/B2-04`、错误完成秒数、`campusCard` 被消耗三个临时负例均被 validator 拒绝。拥有路径 `git diff --check` 和新增文件行尾空白检查通过；临时夹具已删除。按任务约束未运行 `build:single`，未修改 `demo/index.html`。

## 2026-08-20 第四章 7:55 合同与水合质量修补

- 母图合同：validator 现要求每个 `phaseContracts[*].floorPlateIds` 为非空、无重复的字符串数组，并要求每个 ID 属于该阶段引用的 `timeState.plateIds`。该子集规则允许共享 `0754_blackout` 时间态的阶段按所在楼层选用母图。`exterior_closure` 已补为 `a1_0755_morning`。
- v25 水合：六项第四章物品统一由规范化后的 `phase`、`factIds` 和 `completed` 收敛。完成态会保留签到纸条并清除已消费组件；`return_to_clock` 会恢复缺失的 `finalMinute`；清洁车修复后会清除短撬棍并保留待用于钟齿轮的润滑油。越过 `opening_handoff` 的阶段会强制 `prologueSeen = true`，全局 `campusCard` 不受该规则修改。
- 负例与探针：空 `floorPlateIds` 和跨时间态母图 ID 两个负例均以退出码 `1` 被拒绝。v25 异常水合探针确认完成态旧时针为 `false`、其余已消费组件清除、签到纸条与校园卡保留、返回旧钟阶段 `finalMinute = true`、进阶阶段序幕标记为 `true`，以及维护阶段撬棍/润滑油状态收敛。
- 最终验证：`npm run chapter4:validate-story`、`npm run typecheck` 与目标文件 `git diff --check` 均通过；新增 validator 无行尾空白，全部临时负例和探针文件已删除。按任务约束未运行 `build:single`，未修改 `demo/index.html`。

## 2026-08-20 第四章 7:55 控制器、投影与单一 Host 写入口

- 状态事务：`ChapterFourTemporalMazeController.resolve755Intent()` 成为新 7:55 路径的唯一剧情写入口。入口交接、现实模式、阶段白名单移动、纸条、旧钟、时针、204 教室 12 项复原、定位盘、撬棍、轮罩、润滑油、灯控、追逐、最后一分钟、双目标签到和室外收束均在控制器中校验当前阶段、位置、模式、事实、物品与重复调用。拒绝结果不写入状态；阶段转换一次性更新时间权威、时间态、世界时间、手机时间、可信位、保安状态、楼层、房间和 RPG checkpoint。
- 正常入口：`complete_prologue_handoff` 在通用序幕闸门前处理，只接受第三章半恢复回放已解锁且第四章仍为 `opening_handoff` 的状态；成功后写入 `prologueSeen`、A1 大厅和开场 `81900 / 28523 / untrusted` 合同。`move_to_location` 与 `record_checkpoint` 仅接受阶段白名单内的 A1/A2/A3 安全位置。
- 物品与水合缺口：Task 5 执行时补齐 Task 4 漏掉的 `cart_wheel_cover_opened` 和 `paper_temporarily_out_of_inventory` 事实。开轮罩会消耗短撬棍；偷分钟前的 `blackout_light_grid` v25 水合保留签到纸条，偷纸事实存在时清除纸条，`final_chase` 继续保持纸条离开物品栏，202 投影回收最后一分钟时恢复纸条。校园卡不受第四章物品收敛影响。
- 投影：`selectChapterFourMazeProjection()` 从新状态输出时间态、活动时间整图、当前底图、可用目标、动态碰撞、遮挡、NPC、保安、门状态和安全 checkpoint。合法 A1/A2/A3 位置找不到同层时间整图时分别回退到稳定结构底图 `a1_base / a2_base / a3_base`；`activePlateIds` 仍保留内容合同列出的时间态整图。Task 3 资产 manifest 必须沿用这三个稳定 ID。
- 交互合同：新增 typed `CHAPTER_FOUR_755_INTERACTION_TARGETS`。已知矩形全部标记 `approximate=true`、`contractPending=true`、`collision=false` 并记录文档来源；204 的 12 个半开槽位逐一记录对应 `acceptedPieceId`。撬棍、清洁车轮罩/油瓶/车轮、读卡器和纸槽没有可辩护坐标，使用 `bounds:null + activation:contract_pending`，并从活动投影排除。旧钟重叠插槽由阶段投影保证一次只开放一个。共享落点命中统一为右/下边界不包含的半开矩形。
- Host 与功能入口：`RpgGameHost` 只订阅 `rpg_chapter4_755_intent_requested` 作为新第四章剧情写请求；非空 `requestId`、会话内重复请求和 intent payload 会在调用控制器前校验，统一发布 resolved/feedback。序幕结束与现实模式切换也走该事件。旧校时页面在 `FeatureAccess` 中保持不可达，Settings、微信和 CC98 的普通入口不受第四章阻塞；`StatusBar` 在新第四章活动时只读 `phoneStatusTimeSeconds` 和可信位。
- 验证：`npm run chapter4:validate-story` 通过，输出 `13 phases, 6 time states, 5 light zones, 17 item operations`；`npm run chapter4:validate-topology` 通过，输出仍为旧拓扑校验器的 `6 legacy floors, 5 connectors, 3 runtime floors, 13 puzzles`；`npm run typecheck` 通过。纯 Node/内存探针跑通正常序幕入口、越序拒绝无写、完整主线、首次拉钟原子切换、两种签到顺序、追逐失败只恢复 checkpoint、v25 轮罩/偷纸双分支水合、A1/A2/A3 底图选择、临时坐标标记和半开边界语义。
- 后续兼容债务：Task 6/7/8/10/13 仍需把 `ChapterFourTemporalMazeScene` 改为提交新 intent、向投影传完整 `GameState`、消费新 plate/target/dynamic-layer 字段，并为六个无坐标目标按可见精灵落位；当前旧 scene、Quest、DEV 和 phone consumer 仍依赖只读/无写的 deprecated 字段或 controller no-op 签名。该兼容层不能作为新主线权威，后续迁移完成后应删除。
- 开发约束：本轮没有运行 `build:single`，没有修改 `demo/index.html`、package、Quest、DEV、phone page 或 ChapterFourTemporalMazeScene，也没有执行 stage、commit、push、merge、rebase、clean、restore 或 reset。

## 2026-08-21 第四章 7:55 结构母图阻塞复核

- 局部生成复核：A1 中央 `390×252` 裁片的唯一新 `imagegen` 输出保留在 `/Users/zhuhangcheng/.codex/generated_images/01a01e9c-f95f-78a1-a337-24004156f07d/exec-72287c73-f48a-4a37-b125-52e9f1c7394c.png`，原始尺寸为 `1560×1008`，即目标裁片的整数四倍。使用最近邻缩回 `390×252` 后再次目检，电梯仍约位于局部 `x=52` 中心而非目标 `x=116`，旧钟和楼梯的位置、宽高也未满足三个目标矩形；墙面、地砖和边缘发生整体重绘，因此未合成到 A1，临时复验图已删除。
- 确定性路径：对仅使用 A1 v01、A2 v02、A3 v01 候选像素的无缝重构再做一次受限可行性审查，仍未形成可同时通过 `1:1`、`960×540`、坐标和接缝门槛的 A1 原型。子任务只留下的 `/tmp/a1.png`、`/tmp/e72.png`、`/tmp/s138.png` 输入副本已逐一删除；没有正式资产或脚本写入。
- 源文件检索：排除 `.git`、`node_modules`、`dist` 和 `demo` 后检查了当前树的 `451` 个 PNG，并检查常见分层格式与 Git 图像路径历史。没有 PSD、Krita、Aseprite、XCF、ORA、TMX 等分层源，也没有隐藏的校正版。旧运行时三层图确有精确 `x=836` 电梯门片和既有楼梯合同，但计划限定 Task 1 只使用新候选，且旧 A1 仍没有可见面包坊门洞，因此没有拿旧底图替换新素材。
- 依赖结论：Task 2 必须复用 Task 1 的同一交通核与门洞修正，Task 3 必须从校正母图重标碰撞/遮挡；Task 6 又明确要求 Task 3 与 Task 5 同时通过。Task 1 当前回到待资产输入状态，Task 2–3 与 Task 6–16 不提前写入。最小解阻输入仍为三张人工校正母图，或一次能锁定 mask、源像素坐标与输出尺寸的编辑结果。
- 结尾素材预检：当前仓库无法唯一定位用户已完成的“灿若星辰”正式资产或 consumer。`closing_a/b` 属于室内序幕，`finale_arrival_arcade` 属于入楼环境，校园总底图也没有结尾灯交互；三者均未冒充正式来源。Task 13 到达该接线点前仍需要唯一文件路径、`assetId` 或 `sequenceId`，且不会生成替代素材。
- 开发约束：本次复核未运行 `build:single`，未修改 `demo/index.html`，未创建 Task 1 正式资产，未开始 Task 6，也未执行 stage、commit、push、merge、rebase、clean、restore 或 reset。

## 2026-08-21 第四章结构母图人工标注台

- 标注入口：在忽略的候选素材包中新增 `artifacts/chapter4-map-assets-20260820/chapter4-structure-annotation.html`，直接加载 A1 v01、A2 v02、A3 v01 三张 `1672×941` 原图。网页只叠加 SVG 标注层，不裁切、拉伸、重编码或写回 PNG；素材包 README 已补充离线使用与导出流程。
- 交互：支持三层切换、矩形与点位、物体名称、旁注、空气墙、前景遮挡、可通行区、保持不变区等分类、合同参考框、缩放、选中编辑、删除、撤销、当前图二次确认清空、浏览器本地草稿、摘要复制以及 JSON 下载/导入。
- 坐标合同：所有显示缩放均反算到源像素；点导出整数 `{x,y}`，矩形统一为半开 `{x,y,width,height}`，拖框低边界向下取整、高边界向上取整。只读合同框固定为电梯门洞 `{x:800,y:63,width:72,height:96}` 与楼梯 `{x:932,y:145,width:138,height:107}`。
- 数据边界：JSON 固定为 `chapter4-map-annotations/v1`，包含三个候选的仓库相对路径、尺寸与 SHA-256，不包含绝对路径或图片像素。导入前校验 schema、坐标空间、三图 ID、文件名、尺寸、SHA、坐标范围、总数上限与每图上限；文本只通过 `textContent` 渲染，页面没有外部字体、CDN、脚本、遥测或上传请求。
- 浏览器验收：本地 HTTP 下实测 A1 拖框、A2 点标、A3 切换、选中编辑入口、撤销、刷新恢复、摘要复制、JSON 下载和重新导入；控制台错误与警告均为 `0`。桌面 `1440×900` 与移动 `390×844` 完成目检，移动文档宽度等于视口宽度 `390px`，原图天然尺寸仍为 `1672×941`。
- 清理与运行：桌面/移动 QA 截图、Playwright 快照、日志和测试 JSON 已在目检后删除，重复的 `4175` 测试服务器已停止。当前人工复核入口由 `127.0.0.1:4174` 提供；本轮未修改游戏运行时、正式资产、`demo/index.html` 或 Git 状态，也未运行 `build:single`。

## 2026-08-21 第四章三层人工几何标注首轮收件

- 用户已通过结构标注台提交 A1/A2/A3 三层共 `78` 个源像素半开矩形：A1 `26`、A2 `30`、A3 `22`。原始结果保存为 `artifacts/chapter4-map-assets-20260820/chapter4-structure-annotations-user-v01.json`，可重新导入标注台；文件同时记录三张候选图的 SHA-256，未改写任何 PNG。
- 分类统计：空气墙 `42`、前景遮挡 `15`、必须可通行 `17`、电梯可见范围 `3`、A1 面包坊门洞 `1`。所有矩形均为整数、正尺寸并位于 `1672×941` 范围内，ID 无重复，图片哈希匹配；本轮内存校验输出 `CALIBRATION_DATA_PASS`。
- 门洞纠偏：A1 `{x:490,y:514,width:41,height:263}` 穿过竖向隔墙，`41px` 表示墙体厚度，沿墙方向的可通行净跨度为 `263px`，满足此前 `62px` 最小净开口；不能把矩形 `width` 误读为玩家通过方向的净宽。
- 遮挡复核：为全部 `15` 个前景遮挡补充对象名称、`baselineY` 与 `full_crop / baseline_only` 建议。遮挡矩形只定义重绘范围，碰撞仍由独立空气墙负责。
- 自动冲突：A2 存在 `4` 处空气墙与必须可通行区的边缘交叠，面积分别为 `18 / 232 / 32 / 24px²`；运行时必须以可通行区优先，裁掉重叠边缘后再生成 Arcade static bodies。A3 `a3-ann-017` 仅 `5px` 厚、`a3-ann-018` 仅 `1px` 宽，正式碰撞前需扩到可见墙帽或立柱范围。
- 激活阻断：三层可见电梯中心为 A1 `772.5`、A2 `791`、A3 `787.5`，与当前项目共享 `x=836` 交通核和 `72×96` 门片合同不一致；候选图也尚未替换 Scene 当前加载的旧 `teaching_building_floor_1/2/3.png`。在明确“修图保持共享交通核”或“改为每层独立电梯锚点”前，标注合同保持 `runtimeActivation: blocked`，不会把新坐标错误套到旧底图。
- 交付边界：未修改正式运行时碰撞、正式底图、`demo/index.html` 或 Git 状态，未运行 `build:single`。

## 2026-08-21 第四章 7:55 三层结构母图正式接入

- 决策解阻：用户确认采用每层独立电梯锚点。A1/A2/A3 的可见门洞中心分别固定为 `772.5 / 791 / 787.5`；A1 第 25、26 区域定义为可通行的墙后区域，并由肖像墙前景裁片按脚点基线遮挡人物。该决定已同步到 `AGENTS.md`、三层迷宫设计文档、地图生成提示词和项目开发报告，取代旧共享 `x=836` 约束。
- 资产晋升：将人工标注对应的三张 `1672×941` 候选母图逐字节复制为 `src/assets/rpg/interiors/finale/chapter4-755/base/a1.png|a2.png|a3.png`。三图 SHA-256 分别为 `0df950f0…85e3`、`b1d09d66…fb04`、`3077b3f6…02e`；`finale_environment_manifest.json` 新增 `a1_base / a2_base / a3_base` 三个 Phaser consumer。九张时间态整图本轮保持未注册。
- 布局合同：`chapter4-three-floor-maze.layout.json` 升为 schema v2，矩形统一为半开 `{x,y,width,height}`。接入 `42` 条空气墙、`17` 条必须通行区、`1` 个面包坊门洞、`17` 个前景遮挡和三层独立电梯的 `visibleBounds / doorCenter / standPosition / arrivalPosition / travelBounds`。A2 四处墙体交叠按通行区优先裁边；A3 两条过薄碰撞分别扩到 `10px` 高和 `8px` 宽，修正原因保存在数据中。
- Phaser 消费：`ChapterFourTemporalMazeScene` 已直接加载三张新母图，移除共享电梯中心常量；电梯门、站位、交互范围、移动落点和到站位置均从当前楼层合同读取。前景 crop 常驻，深度为 `4000 + baselineY`；人物按脚点 `4000 + y` 排深度，遮挡裁片不进入碰撞组。调试状态新增三层电梯、前景遮挡和可通行区数据。
- 接近判定修补：集成检查发现电梯虽然生成了各层 `69 / 80 / 74px` 接近范围，筛选仍固定使用旧 `54px`。现已改为读取 `candidate.zone.proximity`，三层合同站位均能进入电梯交互范围，同时保留其他 RPG 场景旧矩形调试结构的兼容 union。
- 合同验证：已执行 `npm run art:finale-environments`、`npm run chapter4:validate-assets`、`npm run chapter4:validate-topology` 和 `npm run typecheck`，均通过；资产校验器锁定三图尺寸、哈希、manifest consumer、楼层资产 ID 与三层电梯矩形。按用户最新要求，随后停止继续进行三层浏览器碰撞与校验；开发服务器已停止，临时浏览器截图、快照和日志已移入废纸篓。
- 交付边界：未运行 `build:single`，未修改 `demo/index.html`，未执行 stage、commit、push、merge、rebase、clean、restore 或 reset。

## 2026-08-21 第四章 7:55 Task 6 Phaser 场景合同

- 精灵注册：五张活动 sheet 继续按整图加载，在 Scene `create` 阶段由 schema 3 manifest 注册显式 Phaser frame。清单共 `62` 条，其中 `61` 条非空 frame 使用绝对 `sourceTrim`，`setTrim` 的目标偏移相对 `sourceCell`（无 cell 时使用 `sourceRect`），pivot 归一化；唯一 `empty` frame 跳过。缺 sheet、尺寸、重复 ID、空 trim、越界、pivot 越界和已有 frame 几何不一致均进入 `contractFailures`。
- 原子母图组：每次投影变化先形成 A1/A2/A3 三张完整 plate group，并检查 `1672×941` 纹理、全部前景 crop 和 `physicalDeltas`。校验通过后在同一同步段切换三层背景、替换同 plate 前景、重建 plate collider；失败保留上一完整组，且不修改人物、相机和 zoom。午间排队栏杆和 A3 参照教室家具使用 source-pixel collider；204 动态家具、保安和灯控屏障没有实体边界时只报告 pending/failure，不出现在 applied collision ID 中。
- 场景收敛：删除旧 A2 排班/NPC/自习桌 crop、移动隔断、导视碎片、旧历史电梯重放与旧 action/move 事件口。三层仍以拼接世界运行，静态碰撞、人物脚点深度、A1 墙后可通行遮挡、楼梯和普通电梯保留；电梯门、站位和落点读取三层独立中心 `772.5 / 791 / 787.5`，未恢复共享常量。
- 单一写入口：场景只发布 `rpg_chapter4_755_intent_requested` 并只消费对应 resolved；`move_to_location` 未获 controller 接受时不启动楼层转移动画。Task 6 的剧情 actionable allowlist 固定为空，纸条、旧钟、传送带、204、维护、灯阵、追逐和签到只投影/渲染几何，等待 Task 7–13 逐项开放；含 `acceptedItem` 的目标不会产生 `Space` 提示。
- Host 与 debug：正式 `duan_yongping_temporal_maze` 活动时挂载共享 `RpgInventoryDock`。Debug 分开记录 projected/applied plate、collision、occlusion、target ID，另含 5 灯区、safe checkpoint、frame 注册结果和 contract failure；旧 cycle、route、partition、historical 字段删除。碰撞使用无视觉 Zone，collider/occlusion/target 边界可视叠层仅在 `import.meta.env.DEV` 且对应 URL flag 打开时创建。
- 验证：`npm run chapter4:validate-story`、`npm run chapter4:validate-assets`、`npm run chapter4:validate-topology`、`npm run typecheck` 和目标 diff-check 通过。一次 `/tmp` 合同探针确认 `62/61/1` frame 合同、9 张状态 plate、13 个三层组、3 项 physical delta、唯一新写入口、Task 7–13 零 actionable、C4 dock、projected/applied debug 分离和三层电梯中心；探针、备份和 diff 临时文件已删除。按用户要求未执行三层浏览器碰撞专项，也未运行 `build:single` 或改写 `demo/index.html`。
- 两阶段提交复核：新前景先以隐藏状态完整创建，新 plate static group、source-pixel bodies 与 player collider 先完整创建和校验，且新 collider 在提交前保持 inactive；旧前景、旧 group 和旧 collider 全程保留。三层 background 保存 texture/frame 快照后依次 `setTexture`，任一步失败会恢复三层快照并销毁 stage。三层成功后才在同一同步段显示新前景、激活新 collider、停用并隐藏旧组，再逐对象安全清理旧资源；清理异常只写入 `contractFailures`，不会停用或销毁新组。开发态 registry fault injector 与一次性 `/tmp` 探针覆盖前景 staging、碰撞 staging、第二层 `setTexture` 和旧资源 cleanup 四类故障；前三类均保持旧三层背景、前景和碰撞完整，成功及 cleanup 异常路径均只让新 collider 参与碰撞。
- 投影重试与异常物品收口：`projection`、完整 projection signature、target visuals 以及 phase/mode/light debug 快照只在原子 plate apply 返回成功后提交。失败保持上一 applied projection、三层资源、target 容器和 signature，并以 `120 / 240 / 480 / 960 / 1920ms` 上限退避持续重试；候选 signature 改变会立即清零退避。Scene 投放入口使用 `GameState.items` own-property guard，Dock feedback 使用 `GameState.items + ITEM_META` 双 own-property guard，不再将任意字符串断言成 `ItemId`；异常 ID 在 Scene 显示安全失败，Dock 忽略异常回执。专项 AST/状态机探针确认同 signature 首次失败后旧背景、前景、collider、targets、signature 均保持，解除故障后自动成功，同时拒绝 8 类异常值并接受全部 6 个第四章道具 ID。
- Active delivery 排除：未跟踪的 `src/scenes/rpg/ChapterFourStairAlignmentScene.ts` 当前没有 consumer，本轮不纳入活动交付；文件未删除、未还原，也没有继续修改。

## 2026-08-21 第四章 7:55 Task 7 开场纸条与首次拨钟

- 序幕截止：活动时间线固定在 `32400ms` 的教学楼玻璃门任务卡，`advance` 与跳过均收敛到该时刻。活动 phase 只保留 `snap / lake_exit / arcade / entrance`，不再加载保洁员或保安对话立绘，Renderer 的活动 dispatch 不含门厅清楼、追逐或关灯分支；任务确认到纸条现场之间没有第二条路线选择。
- 无黑帧交接：Host 在提交 `complete_prologue_handoff` 后继续保留序幕覆盖层。只有 Phaser Scene 已提交应用 `a1_2245_opening`、三层 plate group、前景、碰撞和投影目标集合，并发出 `contractReady` live-ready 后，Host 才释放覆盖层。入口拒绝与 `5s` 超时均显示失败，按钮以新 `requestId` 重试；超时在同步 emit 前启动，避免同步 ready 覆盖定时器。
- 开场事实与顺序：新增 `opening_paper_at_noticeboard`、`external_time_rejected`，以及 `complete_opening_paper_flight / resolve_external_time_rejection / resolve_hall_clock_inspection` 三个严格无多余字段 intent。Controller 只在对应演出结算后写事实；SaveStore v25 按纸条落定、捕获、外部时间拒绝、旧钟检查建立因果闭包，同时保留 `opening_paper_caught` 和 `hall_clock_inspection` 两个可重播的未结算刷新状态，阶段总数仍为 `13`。
- 纸条与空间合同：Scene 从共享人物 Arcade 脚部 body center 计算距离与面向，纸条从脚点前方 `4m` 飞到约 `6m` 外的公告栏真实锚点。落定关键帧提交 controller 后才投影捕获目标，使用正式 `chapter4_story_items/sign_in_record_paper` frame；成功捕获只授予一次 `attendanceRecordPaper`。Task 7 actionable allowlist 只有纸条和旧钟，开场三阶段在接近判定、电梯入口和移动请求三层拒绝楼梯/电梯路线。
- 时间拒绝与旧钟：捕获接受后锁定移动和剧情输入，显示固定视口 close-up，明确并列外部 `22:45`、手机冻结 `07:55:23` 与“不可信”，完整演出结束才结算外部时间事实。旧钟只在该事实成立后以浅色操作开放；接受检查先进入 `hall_clock_inspection`，依次显示 `2245_missing_hour_hand / gear_stuttering`，演出完成才写 `hall_clock_inspected`。刷新发生在两段演出中间时会从 controller 状态安全重播。
- 首次拨钟：只有 `hall_clock_inspected` 后允许拉钟。Controller 一次事务切换到 `bakery_hour_hand / hall_clock / 1225_bakery / 44700 / trusted=true`，投影同时选择 `a1_1225_bakery`。Scene 只在 accepted 且已提交状态完整时播放 `gear_stuttering → 1225_missing_hour_hand`、四次短闪与齿轮音效；视觉或音频失败不回滚或阻塞已提交剧情。Host 对七个开场演出 intent 不叠加“当前操作已记录”字幕，拒绝反馈继续可见。
- 请求与清理：纸条、旧钟及三个演出结算请求均含 pending、唯一 `requestId` 和超时恢复；重复输入不会重复提交。Scene shutdown/destroy 通过共享 lifecycle helper 解绑 bridge，并清理移动请求、剧情请求、演出 timer 和外部时间 close-up。
- 验证：`chapter4:validate-story`、`chapter4:validate-assets`、`chapter4:validate-topology`、`typecheck` 与 `git diff --check` 均通过。Vite SSR 内存探针确认越序请求零写、纸条 settled gate、捕获一次、外部时间 gate、检查握手、首次拨钟原子时钟/底图、两段 reload resume 和同一 `requestId` 仅执行一次；静态探针确认 `32400ms` 截止、live-ready 后释放、超时重试、脚部几何、Task 7 两目标白名单和 shutdown/destroy 清理。主实现验证未安排 `build:single`，也未执行用户豁免的三层浏览器碰撞专项或 Git 写操作；随后发生的越界构建另记如下，不计入 Task 7 验收。

## 2026-08-21 第四章 7:55 Task 7 越界构建记录

- 事实记录：只读复核子代理违反本任务边界，误执行了一次 `npm run build:single`，并重建 ignored 的 `demo/index.html`。该产物没有来源备份，当前视为陈旧输出；本轮不修改或还原它，等待 Task 15 按正式流程重建。
- 验收边界：这次越界构建不计入 Task 7 或 Task 15 的验证结果。Task 7 只采用 story/assets/topology/typecheck、Vite SSR 状态探针、静态源码探针与 `git diff --check` 结果。
- 复核结果：重新执行剧情 validator 与 Vite SSR 内存探针，主链路最终进入 `bakery_hour_hand / hall_clock / 1225_bakery / 44700 / trusted=true`；两段中途刷新保持未结算并可重播，同一 `requestId` 只执行一次。本轮仍未执行三层浏览器碰撞专项，也未执行 Git 写操作。

## 2026-08-21 第四章 7:55 Task 7 独立复核修补

- 任务投影：`QuestModel` 的活动 7:55 路径改读 `chapter4-755.content.json`，从当前 `phaseContracts.taskKeys` 中按事实与物品选择一个下一目标。开场依次显示纸条、旧钟检查、首次拨钟；首次拨钟后立即显示“前往面包坊检查传送带”，取得旧时针后切换为“回大厅装回旧时针”。任务抽屉每次只返回一个 step；旧 `chapter4-temporal-maze` 内容保留为运行时迁移兼容 fallback。
- 开场位置：`complete_prologue_handoff` 原子收敛到 `A1 / a1_lobby / c4_a1_lobby`，该阶段不再接受移动到 `a1_hall_clock`；SaveStore 同样把 `opening_handoff` 水合到大厅。公告栏目标暂时兼容旧进程中的 `a1_hall_clock` 大厅别名，避免未刷新进程在纸条落定后失去目标。
- 首次检查文本：Scene 字幕和 `hall_clock.first_inspection` 只说明旧钟可以拨动但响应方向、幅度错误，不再提前说明时针缺失或时针轴为空。缺时针 atlas 仍作为环境视觉使用，不参与该段文字揭示。
- 验证：story/assets/topology/typecheck、`git diff --check` 均通过。定向 Vite SSR 探针确认 controller 与 SaveStore 都将开场位置收敛到 A1 大厅、旧 hall alias 仍可投影纸条、五个开场/面包坊任务目标每次只显示一个、旧任务模型 fallback 可用。本次修补未运行 `build`、`build:single`、Git 写或三层浏览器碰撞专项，也未修改或还原此前标记为陈旧的 `demo/index.html`。

## 2026-08-21 第四章 7:55 Task 8 12:25 面包坊旧时针

- 独立实体合同：`a1_bakery_inspection_lamp`、`a1_bakery_conveyor_edge`和 `a1_bakery_hour_hand_pickup` 全部使用 `runtime_entity`；删除面包坊灯/传送带共用的大范围布局锚点。Scene 从活动 Phaser GameObject 的 `getBounds()` 向外取整，生成现有 `runtimeTarget` envelope；三个验收矩形分别为 `[354,313,393,343)`、`[286,332,303,361)` 和 `[288,312,322,351)`。时针视觉只复用 `chapter4_story_items/old_clock_hour_hand`，pivot `(294,345)`、uniform scale `0.10`，没有写入底图或新增图像。
- 控制器与恢复：新增 `bakery_hour_hand_exposed`、`bakery_hour_hand_collected` 与 `complete_bakery_conveyor_stop`，并将 `bakery_conveyor_lamp_inspected` 纳入 SaveStore 有效事实。保存/恢复按 `installed → collected → exposed → lamp` 补齐因果；旧时针只在 collected 成立时恢复为持有。传送带在用灯前仍投影且可尝试，越序只返回“先点亮烤箱旁的检修灯，让传送带停一下。”并保持零写。
- 停带演出：灯被 controller 接受后 Scene 锁输入；`0 / 120 / 360 / 520 / 700ms` 依次执行点灯与停带 cue、减速、停带并暂停近处 NPC、显示时针/glint、提交 completion intent。Controller 写入 exposed 后解锁；无灯、灯已查但未 exposed、已 exposed、已 collected/持有、已 installed 五种刷新状态均有明确恢复分支。
- 一次性道具与任务：拾取在同一事务写 collected 并授予 `oldClockHourHand`；重复拾取零写。Quest 每次只投影一个下一目标：先检查灯/传送带，exposed 后取时针，collected/持有后回大厅安装。旧钟 socket 只显示道具拖放提示；浅色、可见边界、距离与朝向同时通过才消耗道具，并原子进入 `room204_restore / 1850_evening / 67800 / trusted=true / A2+A3 plate group`。Task 9 以后目标仍不在 Scene actionable allowlist 中。
- NPC 与路线：面包师复用 `counter_aunties_2frame.png` frames `6–7`，origin `0.5,1`、scale `0.65`、position `(365,340)`、无碰撞，由 `a1_foreground_018` 柜台前景遮住下半身。三名学生复用 finale student atlas 与玩家脚部 body 合同，路线、速度与端点停顿按布局数据执行；phase/plate 变化及 shutdown/destroy 会清理 collider、tween、timer、entity 和 bridge listener。两条 mapper waypoint 从门洞东侧经 `y=560` 或 `y=748`，共用东端净空中心 `x=477`，最终连到 `(374,386)` 与 `(294,386)` 站位。
- 声音边界：Task 8 只发出 `chapter4_bakery_approach`、`chapter4_bakery_conveyor_stop`、`chapter4_bakery_hour_hand_revealed` 三个 domain cue，元数据包含 source/player world x 与 distance；未声称当前 AudioDirector 支持 pan，未复用其他章节音频充当正式素材。
- 复审收口：三个 runtime target 的 `targetId + entityId + bounds` 现在必须与 `layout.bakeryRuntime.targetEntities[].installationBounds` 精确相等；合法世界内 `1×1` 或平移 `1px` 的伪造边界都返回 `null`，controller 保持零写。`complete_bakery_conveyor_stop` 超时、拒绝、或 accepted 但 committed exposed fact 缺失时，Scene 统一按当前已提交 state 保持灯亮、恢复传送带/人流、隐藏时针和 glint，延迟后自动重试。
- 验证：`npm run chapter4:validate-assets`、`npm run chapter4:validate-story`、`npm run chapter4:validate-topology`、`npm run chapter4:validate-runtime` 与 `npm run typecheck` 全部退出码 `0`。runtime validator 执行 `150` 项断言，新增三目标正常/伪造边界、controller 零写和 committed-runtime 回滚矩阵；topology validator 以 `2px` 采样检查 fixed + queue + 三名 NPC 全路程 swept-foot collider，NPC 边界精确从 Scene 的 origin `0.5,1`、display scale `0.65`、source foot-box offset 与 bottom inset 推导。该结论仅属纯数据 Arcade 数学合同验证，不作为实机浏览器碰撞证据。定向与新文件 diff-check 通过，`/tmp` 无 Task 8 残留。本轮未运行 `build`、`build:single`、Git 写或用户豁免的三层浏览器碰撞专项。

## 2026-08-21 第四章 7:55 Task 9 18:50 教室复原与定位盘

- 纯模型：新增 `ChapterFourRoom204Model.ts`，统一读取 layout 中的 `12` 件桌椅组合、`12` 个 `20×20` 槽位、桌椅偏移、四张组合桌、讲台和投影节拍。任意唯一 piece 可放入任意唯一空 slot，仅接受 `orientation=up`；纯函数区分 unknown piece/slot、non-up、duplicate piece、occupied slot 和 already placed。canonical 对应关系只用于后续阶段存档修复，不参与正常解题。
- 场景与交互：A3 标准教室只在浅色操作观察一次，A2 的 `12` 张残影只在深色观察显示并一次登记。A2 浅色操作下靠近未归位椅子可搬起一组，靠近任意空槽位可放置；深色模式、未搬起家具和未就绪边界都有可见的下一步反馈。家具视觉使用已注册的 `12` 张单人桌、`12` 把椅子、`4` 张组合桌和讲台；碰撞从 manifest 每帧 `collisionBounds` 经 `0.25` 统一缩放和 pivot 转换成实际 static body。残影保持 floor decal，不建立碰撞。
- 运行时边界：A2 残影组、`12` 个槽位和讲台抽屉均为 `runtime_entity`。Scene 按 layout 创建 Phaser Zone，再从 `getBounds()` 向外取整；Controller 仅接受与 layout 中 `targetId + entityId + bounds` 完全一致的 envelope。平移 `1px`、伪造 entity、缺少 runtime bounds 或静态伪坐标均零写拒绝。
- 事实与握手：第 `12` 件合法入槽且两次观察成立时，Controller 写入 `room204_restored`。Scene 立即锁输入，播放短 `07:55` 偏移到稳定投影，再提交 `complete_room204_projection`；Controller 重新校验完整 placements 与两次观察后才写 `room204_projection_completed`。超时、拒绝或接受但缺失已提交事实时，演出回到已完成布局并延迟重试。
- 一次性道具：投影握手完成后才开放讲台抽屉。拾取在同一事务写入 `positioning_plate_collected` 并授予 `clockPositioningPlate`；拖到旧钟可见插槽后消耗一次，写入 `positioning_plate_installed`，并原子切换到 `maintenance_repair / 2245_maintenance / A1 / a1_hall_clock / c4_a1_lobby`。Task 10 及更后目标在 Room204 阶段保持关闭。
- 存档与任务：SaveStore 复用纯模型清除未知、重复和 non-up 数据，按“两次观察 → 完整复原 → 投影完成 → 定位盘收集 → 安装”建立因果闭包。Room204 中途存档保留合法部分进度；后续 phase 缺 placements 时才补 canonical 完整布局。Quest 依次只显示参照、残影、复原、看投影、取定位盘、安装中的当前一项。
- 纯数据几何：topology validator 从 manifest 的家具脚部碰撞、layout 的统一缩放/偏移和 `19.5×14.625` 玩家脚部框推导完成态障碍。`2px` 与 `4px` 采样均保持 x=`132.5 / 230 / 327.5` 三条纵向走道和 y=`623` 横向连接；覆盖 `12×12=144` 种 piece→slot 候选包络。该结论只是纯数据几何合同，不作为浏览器实机碰撞证据。
- 验证：`chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`typecheck` 均退出码 `0`。runtime validator 执行 `406` 项断言；topology validator 执行 `2164` 项断言，其中 Room204 为 `1009` 项。`git diff --check` 与新文件 whitespace 检查通过。按用户要求未运行三层浏览器碰撞专项；按实施边界未运行 `build`、`build:single`、未改写 `demo/index.html`、未执行 Git 写操作。

## 2026-08-21 第四章 7:55 Task 10 22:45 维护链与普通巡逻保安

- 维护链：新增 `cart_wheel_inspected`，并固定“检查车轮 → 取短撬棍 → 消耗撬棍开轮罩 → 取通用润滑油 → 修车轮保留半瓶油 → 修旧钟齿轮消耗油”六步事务。撬棍可提前拾取，Quest 仍优先显示检查车轮；齿轮修好后保持 `maintenance_repair / 2245_maintenance / patrol`，下一目标为“把旧钟拨向 07:55”，Task 11 后续目标仍关闭。
- 坐标与资源：`maintenanceRuntime` 成为短撬棍、清洁车、清洁员、轮罩/车轮、润滑油、旧钟齿轮和保安巡逻的唯一布局来源。Scene 为 6 个目标创建实际 GameObject，将 `getBounds()` 向外取整后与 layout 精确匹配；轮罩明确使用清洁车局部区域加程序化开盖状态。修轮后清洁员使用 layout 声明的 `cleaner_push_cart` 推车 `900ms`，旧 collider/body 立即停用。
- 普通巡逻：新增纯 `ChapterFourGuardModel`，状态为 `patrol / confirming / pursuit / returning`；连续可见 `400ms` 转追击，连续失视 `900ms` 返回巡逻；视野参数为 `220px / 36° / 56px`，近距离仍受墙体 LOS 阻挡；速度为 `84 / 140 / 96px/s`，停留 `1–2s`，最大分片 `50ms`，seed 可复现。Scene 只给保安本体配置静态墙 collider 和人物 overlap，视锥、确认 `!` 和红色追击表现无碰撞。捕获只在 pursuit 与半开脚框相交时发出 `recover_from_maintenance_patrol`。
- 捕获恢复与存档：Controller 仅在 maintenance + patrol 接受普通巡逻恢复，原样保留 items、facts、`chaseAttempt`、深浅模式、灯阵和时间，只写入 A1 大厅安全位置并关闭道具栏/拖放选中。Scene 接受后放置人物于 `(836,716)`，保安从 `west_north` 走向 `stair_north`。SaveStore 修复 gear→wheel→cover→inspect 因果闭包；未开轮罩会清除伪造油瓶，修轮未修钟会恢复半瓶油，修钟后强制油瓶不持有；非法 maintenance room/floor 回收到 `A1 / a1_lobby / c4_a1_lobby`。
- 验证：`chapter4:validate-runtime` 执行 `771` 项断言，覆盖 6 目标全类零写拒绝、grant/consume once、6 态 save、捕获深比较、`399/400ms`、`899/900ms`、LOS 墙阻挡、重见清零、last-visible、return、seed 和脚框接触。topology 执行 `2221` 项断言，5 条保安路径用 `20×16` 脚框和 `2px` 步长对 A1 静态墙做纯数据采样，全部通过。assets 校验 4 个 NPC PNG/manifest/hash/RGBA 合同与 4 个维护帧绑定。story、runtime、topology、assets 与 typecheck 均 fresh 通过；定向 diff-check 通过。本轮未运行 `build`、`build:single`、Git 写或用户豁免的三层浏览器碰撞专项。

## 2026-08-21 第四章 7:55 Task 10 质量复审修补

- Task 11 边界：分针端点在 Task 10 基线只允许 `return_to_clock` 兼容安装；维护阶段不再投影或响应该端点。`trigger_minute_theft` 保留请求类型兼容，但 Controller 固定返回 `locked` 且零写，Scene 不再发出该意图。
- 保安物理权威：纯模型每步显式接收 Arcade guard body 的实际脚框中心并返回 `desiredVelocity`。Scene 仅在创建和捕获恢复时定位保安；普通帧从已解算 body 回灌位置，只设置速度，墙体 collider 的分离结果不会在下一帧被模型坐标覆盖。捕获也读取实际 guard/player body。
- 目标边界溯源：撬棍和润滑油从当前可见 sprite 对应的 manifest source interaction、pivot 与统一缩放派生；轮罩检查、程序化轮罩和车轮从 `cleaning_cart` 的 `144×128` frame-local `{88,91,28,37}` 区域与实际 sprite transform 派生；齿轮从当前可见 clock frame 的 A1 manifest interaction 派生。六项均先生成 Zone，再以实际 `getBounds()` 向外取整与 layout installation 精确比较，不再由 installation 自身生成校验对象。
- 单推车表现：修轮时先销毁独立 `cleaning_cart` 及旧 body/collider，再把清洁员切到已含推车的 `cleaner_push_cart`；Tween 只移动该组合 sprite，并以 active Tween guard 防止每帧重启，结束后场上保持单一推车视觉。
- 复审验证：`chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`typecheck` 与定向 `git diff --check` 全部退出码 `0`。runtime 为 `774` 项，topology 为 `2224` 项；资产门新增 `4` 组 source-derivation 断言，剧情门新增 Task 11 锁定、物理回灌、禁止逐帧 teleport 与单推车清理断言。纯数据与静态合同仍不构成浏览器碰撞证据；本轮按用户豁免未运行该专项，也未运行 `build`、`build:single` 或 Git 写操作。

## 2026-08-21 第四章 7:55 Task 11 偷分钟、停电与五灯配电箱

- 最终拨钟：齿轮修好后仍处于 `maintenance_repair / 2245_maintenance / patrol`，旧 `trigger_minute_theft` 保持锁定。Scene 使用 `gear_running` 可见钟面和程序化分针端点，端点 Zone 从实际 `getBounds()` 向外取整并绑定唯一 layout installation；浅色操作、A1 大厅/旧钟位置、距离、朝向和纸条条件全部通过后，`begin_final_clock_drag` 只建立运行时握手且零写。指针拖动与 `Space / Enter` 使用同一宽松完成动作，没有精度、计时或失败惩罚。
- 偷分钟与停电事务：运行时按 `0 / 240 / 680 / 1040 / 1160ms` 锁定移动、交互、背包和楼层切换，依次完成分针移动、纸条飞向端点、`complete_minute_theft` 提交与反馈。Controller 仅在最终提交点一次写入 `blackout_light_grid / 0754_blackout / 28440 / trusted`、保安离场、纸条暂离物品栏、灯阵 `mask=6` 未锁定以及 A1 大厅安全点；拒绝或超时按已提交状态恢复钟面和纸条并允许重试。
- 五灯纯模型与面板：新增无 React、Store、Phaser 依赖的 `ChapterFourLightGridModel`，固定五区 XOR mask `7 / 19 / 13 / 28 / 26`、初始 `6`、目标 `13` 和全亮 `31`。32 态枚举只存在一组点击向量 `28`，全亮判定失败。A1 配电箱交互绑定精确 installation `{493,528,67,124}` 和可见箱 `{505,540,43,100}`；React 面板提供五灯状态、方向键、`Enter / Space`、未锁定时 `Escape`、pending 防并发和可见错误，最后一次 toggle 先持久化 `mask=13`，状态同步后自动锁定并进入 `final_chase`。
- 视觉与生命周期：五个光区全部标记 `visualOnly / nonColliding / approximate`，区域互不重叠，mask 变化只更新遮暗覆盖层。配电箱使用 `closed / open_powered / open_partial / open_restored` 四帧作装饰，32 种灯态由 React/CSS 绘制。面板会话缓存 target/spatial/runtime envelope，所有 toggle/lock 均通过统一第四章 intent handler 和唯一 requestId；关闭、锁定、phase 变化与 Scene/Host shutdown 会清理会话、timer、pointer 和 overlay。
- 存档与任务：SaveStore 对停电及后续阶段补齐齿轮修复和纸条暂离事实，停电阶段保留合法 `0..31` mask、非法值回退为 `6`；`final_chase` 及以后强制 `mask=13`、`locked=true` 和锁定事实，并修复旧 `a2_lecture_202` 到 `a2_room_202` 的位置迁移。任务抽屉每次只显示一个目标：拨向 `07:55`、让必要路线亮起、前往 `202`；Scene 的 Task 11 allowlist 明确排除 Task 12 目标。
- 验证：最终 fresh `chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`typecheck` 均退出码 `0`；runtime 为 `907` 项断言，topology 为 `2258` 项断言。定向 `git diff --check` 和新文件行尾空白检查通过。资产、拓扑与运行时输出明确标记 `no_browser_evidence`；按用户要求未运行三层浏览器碰撞专项，按实施边界未运行 `build`、`build:single` 或任何 Git 写操作。

## 2026-08-22 第四章 7:55 Task 11 第二路复审修补

- 拨钟会话锁：`finalClockDragActive` 现在属于 Scene 故事输入锁，从 begin accepted 到分针拖拽、`1040ms` 提交和演出回滚期间持续向 Host 发布锁状态。Host 隐藏任务栏、系统按钮、模式开关和道具 Dock，关闭 Phaser 键盘；仅在实际指针拖拽阶段保留 Scene Pointer，进入偷分钟演出后立即取消该例外。Controller 在 `complete_minute_theft` 再验证浅色操作，模式被外部改变时返回 `wrong_mode`、清除握手并保持 GameState 零写，Scene 恢复钟面和纸条后可重新开始。
- 配电锁定重试：目标 mask 的首次自动 `lock_light_grid` 失败后，面板在同一 mask 下显示可聚焦的“重试锁定”按钮。按钮继续调用原 canonical handler；Host 的 pending request ref 和唯一 requestId 仍阻止并发与重复写入，无需破坏已解出的灯态。
- 生命周期：只读审计确认 Phaser Scene shutdown 可能复用同一实例，而 chase guard 字段此前可能保留已销毁对象引用；shutdown 现在显式调用 `destroyChaseRuntime()`，同时清理 guard overlap 并置空字段。没有开放或实现 Task 12 交互。
- 取消与验证：分针拖拽监听 `pointerupoutside`，触控取消通过 Phaser `Pointer.wasCanceled` 回滚；`30s` 隐式安全 timer 只负责恢复并允许重试，不显示倒计时、不改变剧情或道具。阶段变化销毁 Task11 runtime，shutdown 强制发布解锁。修补后 fresh assets、story、topology、runtime、typecheck 全部退出码 `0`；runtime 为 `912` 项断言，topology 为 `2258` 项断言。未运行 build、Git 写或浏览器专项。

## 2026-08-22 第四章 7:55 Task 11 pointercancel 复验修补

- DOM 取消监听：最终拨钟 runtime 在当前 `this.game.canvas` 上以 capture 模式记录原生 `pointerdown.pointerId`；Phaser 端点接收同次按下后把该 ID 绑定到当前拖拽。begin accepted 只为非空活动 ID 安装 final-clock 专用 `pointercancel`，事件仅在 `finalClockDragActive` 且 `event.pointerId` 精确匹配时立即调用统一回滚，未复用 Host 方向键、虚拟摇杆或皮划艇取消路径。
- 清理闭包：正常释放进入演出、取消回滚、安全超时、phase change、Scene shutdown 和 runtime destroy 均调用同一监听移除逻辑；destroy 同时移除 canvas 的 final-clock `pointerdown` 记录器并清空 canvas、pending ID 和 active ID，避免 Phaser Scene 实例复用时遗留 DOM listener。
- 验证：fresh story、runtime、typecheck 均退出码 `0`，runtime 保持 `912` 项断言；story 静态门新增当前 canvas、活动原生 pointerId 精确匹配、即时统一回滚以及 end/rollback/destroy 移除监听断言。定向 diff-check 与行尾空白检查通过；未运行 build、Git 写或浏览器专项。

## 2026-08-22 第四章 7:55 Task 12 最终追逐、202 取回与主楼梯返程

- 纯追逐模型：新增 `ChapterFourFinalChaseModel.ts`，固定 `arming / running / portal_transfer / finish_pending / failure_pending / complete` 六态、连续 `4` 个 committed/applied frame 后启动、`50ms` 最大分片、人物 `208px/s`、保安 `196px/s`。同帧同时进入 202 门槛与发生接触时先结算到达；finish/failure 均通过一次性 pending 请求和 `expectedAttempt` 防止旧回调写入。
- 路线与交通：正式路线固定为 A1 `(590,612)` 起点、`(590,724)` 保安、`(836,540)`、`(836,228)`、`(1001,214)` 主楼梯、A2 `(966,214)`、`(1100,232)`、`(1100,400)`、`(1353,400)` 至 `(1353,356.5)` 门槛。面包坊与 203 保留为不推进的死路；追逐 A1→A2 与取回后 A2→A1 只接受 `main_stair`，电梯在两阶段均锁定。返程保安离场，Task 12 终点保持 `return_to_clock`，最后一分钟安装、签到与外景收束仍由 Task 13 开放。
- 202 门与最后一分钟：门状态矩阵为追逐开放且无 collider、取回阶段关闭并启用 `{x:1298,y:341,width:110,height:29}` 屏障、返程重新开放且无 collider。当前没有正式关门 sprite，只使用程序化状态提示和碰撞。`chapter4_story_items/final_minute_shard` 在 `(1353,320)` 生成，Scene 从可见 sprite `getBounds()` 向外取整后创建 Zone，必须浅色、距离、朝向和精确 `targetId + entityId + bounds` 同时通过；成功仅一次授予 `finalMinute`、恢复签到纸条并记录 `final_minute_recovered`。
- 状态、存档与任务：Controller 对到达、失败和主楼梯穿越校验当前 attempt；失败只增加 attempt 并返回 `A1 / a1_lobby / c4_a1_lobby`，保留灯阵、纸条状态、道具、事实、模式和 `07:54`。SaveStore 将 `a2_lecture_202` 迁移为 `a2_room_202`，追逐刷新回 A1，取回刷新回 A2-202，返程可在已提交的 A2 或 A1 安全侧恢复；运行时 guard/portal/door 字段不持久化。Quest 在追逐、取回和返程各只显示一个当前目标。
- 验证：fresh `chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`typecheck` 全部退出码 `0`。runtime 执行 `1036` 项断言，覆盖六态纯模型、4-frame 启动、delta 分片、finish-first、attempt 防旧写、失败保留、三态门、运行时目标防伪、一次授予、存档矩阵、单目标与 Task 13 关闭；topology 执行 `2466` 项断言，A1/A2 去程与返程均以 `2px` 和 `4px` 纯数据网格校验。这些结果属于资源、静态源码和纯数据合同，不构成浏览器碰撞证据；按用户要求未运行三层浏览器碰撞专项，也未运行 `build`、`build:single`或 Git 写操作。

## 2026-08-22 第四章 7:55 Task 13 部分实施：最后一分钟、双项签到与正式外景阻塞边界

- 安装与时间事务：玩家在 `return_to_clock` 通过 `main_stair` 从 A2 返回 A1 后，可将浅色模式下的 `finalMinute` 拖到可见程序化分针端点。端点以当前 Phaser 实体 `getBounds()` 实算的 `{x:971,y:52,width:16,height:16}` 为权威矩形，经 Zone 精确绑定 layout，`approximate=false`，未使用整个旧钟大框或估算常量。成功仅一次消耗 `finalMinute`，原子进入 `morning_checkin / 0755_morning / 28500 / trusted / guard absent / A1 a1_checkin / c4_a1_lobby`，签到纸条与校园卡保留。
- 双项签到：读卡器与纸槽使用可见程序化 fixture，各自从 `getBounds()` 导出 Zone，分别精确绑定 `{756,608,34,24}` 与 `{835,606,40,26}`；站位为 `(773,662)` / `(855,662)`，均为 `56px + up`。`campusCard` 与 `attendanceRecordPaper` 可任意顺序、各接受一次、重复零写且均不消耗；两项完成后只转到 `exterior_closure / A1 / a1_exterior`，时间仍为可信 `07:55`，未自动写入章节完成。Scene 的 phase change、shutdown 和 destroy 会清理分钟端点、签到 fixture/Zone/文字、反馈与 listener；视觉对象不拥有进度。
- 存档与任务闭包：SaveStore 在返程恢复 `finalMinute + attendanceRecordPaper + campusCard`，在早晨签到只保留 boolean 与 fact 同时合法的单项进度，两项齐全自动规范到楼外等待态；早期阶段的恶意签到/收束事实、boolean 和道具位会被清理。在没有正式 consumer proof 的情况下，旧 `complete`、bare acknowledged 或 closure fact 均降级到 `exterior_closure`，`completed=false / exteriorClosureAcknowledged=false`。Quest 每次只显示一个下一目标：A2 返主楼梯、A1 装回一分钟、双项签到或已完成一项后的唯一剩余项、楼外正式收束；未泄露 Task 14+ 步骤。
- 正式外景阻塞：新增严格 `ChapterFourClosureAssetReference / ChapterFourClosureSessionProof / ChapterFourClosureSessionVerifier` 合同，但 `CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE` 明确为 `null`。全仓只读检索未找到可唯一确认的“灿若星辰”路径、`assetId`、`sequenceId` 和实际 consumer；`zjuding_home.png`、`closing_a/b`、`finale_arrival_arcade` 和校园总图均未被冒用。Scene 已移除每帧 bare acknowledge；当前任何无 proof、伪 proof 或无正式 reference 的收束请求都固定 `locked + zero-write`，也没有生成、复制或注册替代素材。manifest 继续保持 `generatedStarMaterial=false / generatedExteriorClosure=false`。
- 验证与状态：fresh `chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`typecheck` 全部退出码 `0`。runtime 执行 `1141` 项断言，覆盖一次安装、原子时间、两种签到顺序、重复零写、错道具/模式/距离/朝向、runtime envelope 防伪、Save 矩阵、单任务与 bare closure 锁定；topology 执行 `2497` 项纯数据断言，包含两个签到站位、目标分离与 A1 空气墙非重叠。按用户要求未运行三层浏览器碰撞专项，也未运行 `build`、`build:single` 或 Git 写操作。
- 当前结论：`Task 13 = partial / blocked_on_official_asset_reference`，不宣称完成。最小解阻输入是用户提供已有正式“灿若星辰”的唯一仓库路径或已注册 `assetId`，以及对应 `sequenceId` 和实际 consumer 模块/完成回调。这些信息到位前，楼外收束始终停在等待态。

## 2026-08-22 第四章 7:55 Task 14 任务反馈、音频路由、DEV 检查点与空间重验

- 任务反馈：第四章 Quest 固定只显示当前一个目标，进度只输出 `0/1` 或 `1/1`。任务 ID 或 objective 变化时，`QuestClueStrip` 同时收起抽屉并清空本地提示计数。内容合同只保留残影、车轮和灯阵三条指定提示，大厅旧钟的第四条提示和未使用的 `repair_hall_clock` 已移除。
- 音频路由：新增 `chapter4-755.audio.json`，由 `AudioDirector` 与 `PresentationDirector` 共同消费。时间切换、面包坊停带、204 抽屉、清洁车、齿轮修复、停电、灯阵、最终追逐、失败/成功、最后一分钟、刷卡、纸条与签到完成均只映射仓库已有 MP3。Scene 已移除同次齿轮直播，巡逻警告只发 domain event，没有为它绑定语义不符的音频。外景收束 cue 数保持为 `0`。
- DEV 检查点：第四章面板恰好显示 11 个稳定 ID，从 `c4-755-opening` 到 `c4-755-complete`；旧 C4 ID 通过显式 alias 迁移。每个 seed 同时设置 phase、timeState、mode、facts、items、floor、room、checkpoint、runtime 与关闭的 UI。未知 ID 显式拒绝，`?dev=0` 关闭 panel、URL seed 和快捷键；DEV 会话不写入正式存档。`c4-755-complete` 只种入双项签到完成的 `exterior_closure` 等待态，保持 `completed=false / exteriorClosureAcknowledged=false`。
- 空间重验：Host 对每个有 target 的第四章 intent 生成唯一 attestation ID，通过 EventBus 同步请求当前 active Scene 回传真实人物脚点、四向朝向、scene key、target/entity 和精确边界。Host 只接受恰好一个 nonce、scene、projection、target、entity、bounds 都匹配的响应，再用共享距离/朝向函数重算空间结果。零响应、多 producer、错 nonce/scene/target/bounds、非有限坐标和伪造布尔值均零写拒绝；临时 listener 在 `finally` 中解绑。
- 结构化 debug：运行时输出 committed/applied phase、timeState、plate signature、target IDs，实体精确边界和来源，普通保安、最终追逐、灯阵会话、202 门、结构化合同失败、最近失败以及 DEV checkpoint ID/source。其他 scene 仍可读旧的矩形 union。
- 验证：`chapter4:validate-task14` 执行 `197` 项断言并通过，包含 Quest 三提示、音频 schema/文件存在性/零外景 cue、11 DEV seed/alias/URL/`dev=0`/会话存档、debug schema 和 attestation 动态拒绝矩阵。fresh `chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`typecheck` 全部退出码 `0`；topology 为 `2497` 项，runtime 为 `1141` 项。按任务分工未运行 `build`、`build:single`、CI 或三层浏览器碰撞专项，未执行 Git 写操作。
- 剩余边界：`CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE` 仍为 `null`，正式外景 consumer proof 缺失；Task 14 按合同保持等待态。Task 15 负责 build/CI，后续任务负责用户调试与最终交付。

## 2026-08-22 第四章 7:55 Task 15 CI、构建与多浏览器验收矩阵

- CI 与静态交付门：`.github/workflows/web-ci.yml` 已在 `typecheck` 前顺序运行 `chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`chapter4:validate-task14`。最终 fresh 结果为 assets `0`、story `0`、topology `0 / 2497`、runtime `0 / 1171`、Task14 `0 / 215`、typecheck `0`、build `0`、build:single `0`、verify:single `0`、`git diff --check` `0`。资产验证同时实际通过本地完整 provenance 模式和 clean-checkout tracked-contract 模式；缺失单个 provenance 输入的部分模式按预期退出 `1`。
- Blink 桌面与移动端：`11/11` DEV checkpoint 在 `1280×720` 通过，`1280×800` letterbox、任务栏、模式控件和道具栏无越界；`390×844` 保持单 canvas、`16:9`、coarse-pointer 五个触控控件和零 document overflow。真实交互覆盖 Room204 键盘移动、配电箱三次点击并把 mask 从 `6` 锁为 `13`、校园卡与签到纸条两种拖放、追逐连续失败两次后经主楼梯成功、返回手机主页后通过当前任务返回同一现场。已验路径均为 `contractFailures=[]`、`pageerror=0`、`console.error=0`、`requestfailed=0`。
- 状态恢复与迁移：移除 session-only DEV 标记后，真实完成校园卡拖放，正式 localStorage 写入 `11008` bytes；刷新后恢复 `morning_checkin`、校园卡已签到、纸条未签到、同一 RPG scene/checkpoint，且 DEV checkpoint 为空。永久 runtime validator 另覆盖并通过四类存档：v24 第四章前、v24 中途、v24 已完成但无正式外景 proof 时降级到 `exterior_closure` 等待态、主存档损坏且 v24 备份有效时恢复并修复主存档。
- Gecko、WebKit 与单文件：Firefox 和 WebKit 各自完成 `11/11` 个 `1280×720` checkpoint 烟测，追逐态均确认 `finalChase.active=true` 和有限正 `guardBounds`。最终 `demo/index.html` 通过 HTTP 与 `file://` 的 opening、room204、chase、complete smoke；直接文件刷新仍保持 `exterior_closure / completed=false / acknowledged=false`。最终文件为 `236019677` bytes，SHA-256 `7a011c99f78a22c54e7a2b0e9888f93bfef02967cdf8aec28215d1d765479478`，内含 `2` 个 inline script 与 `1` 个 inline style；该 ignored 产物只作为本地验证结果，不默认进入 Git 交付范围。
- 边界与清理：按用户要求未执行三层浏览器碰撞与遮挡专项。Task 15 没有伪造“灿若星辰”正式 consumer proof，完整自然流程只能到 `exterior_closure` 等待态；其余已解锁交互与关键路径已用真实操作或多浏览器 checkpoint 验证。所有本轮 Playwright 截图、临时 QA 目录和浏览器会话均已清理，剩余截图为 `0`。

## 2026-08-22 第三章半至第四章 H3 衔接视频拼接与接入

- 源片复核：逐段读取三份用户提供视频的编码、尺寸、帧率、时长和音轨，并用接触表、镜头切点及首尾接缝检查确认顺序为“磁扣断裂与纸条离湖 → 夜间拱廊与玻璃入口 → 门厅、教学楼外景与熄灯走廊”。三份原文件均保留原位，未覆盖或改写。
- 正式资产：三段按原顺序与原速度拼接为 `chapter35_to_chapter4_h3_transition.mp4`，统一为 fragmented MP4、`960×540 / 24 FPS / H.264 High / yuv420p`，共 `1052` 帧、`43.833333s`、`8282814` bytes，且只有视频流。SHA-256 为 `d5cb9e9a91ef778337f5eeef74fad59643ca1f393607f993d7e5fc8196678aff`；相对压缩前规范化成片的全帧 SSIM 为 `0.988282`。`chapter4-prologue-h3.asset.json` 锁定三源哈希、顺序、切点、fragmented 容器与本地音频权威。
- 音频与单文件载入：新增从现有第四章序幕音乐派生的 `music_ch4_prologue_h3_44s.mp3`，原音乐不变。新文件为 `44.000000s / 353687 bytes / 64306 bit/s / 44.1kHz stereo`，SHA-256 `0b8e5a0eb47f431af5d96f13b9bbff07580419b1641de9e6637fa59d7c4685c6`。常规 Vite 使用 H3 URL；单文件把 Base64 切成 `256 KiB` 片段，在 Worker 解码后经 `MediaSource / SourceBuffer` 顺序追加，解决 WebKit 同时启动大视频与大音乐时的冻结。
- 运行时接入：`Chapter4PrologueRuntimeGate` 提升到 App 根级，成为任务卡确认、controller 提交、`requestId`、20 秒超时、刷新恢复、A1 live-ready 与 `80ms` 释放的唯一 owner。等待期间下层 Phaser 保持挂载，DOM `inert / aria-hidden / pointer-events` 与 Host 输入/键盘 block 同时生效。`RpgGameHost` 删除重复 Overlay 和 handoff owner，并显式拒绝通用事件路径中的 `complete_prologue_handoff`。`Chapter4PrologueOverlay` 保持 H3 主画面、六阶段 Canvas 回退、静音视频与 `43834ms` 任务卡。
- 合同验证：`chapter4:validate-story` 同步验证 App 根级唯一 owner、常驻 runtime、刷新任务卡偏移、requestId 回环、内部 retry、20 秒失败不卸载、Host 禁止重复提交、MSE 初始化、MP4/音乐实际哈希。fresh assets、story、topology `2497`、runtime `1171`、Task14 `215`、typecheck、production build、build:single、verify:single 与定向 diff-check 全部退出码 `0`。
- 浏览器验收：Chromium、Firefox、WebKit 的 HTTP 单文件均以 `data-h3-source=blob / data-h3-video=ready` 实际播放，`currentTime` 连续前进，解码尺寸 `960×540`，media error 为 `null`，console error 为 `0`。Chromium 与 WebKit 完成任务卡确认后的自动 A1 交接，最终为 `opening_handoff / A1 / a1_2245_opening / c4_a1_lobby`，一个 Phaser canvas，输入恢复，`contractFailures=[]`；WebKit 的 retry、live-ready、release 使用同一 requestId，未要求用户点击重试。Vite URL 分支以 `data-h3-source=url` 播放并通过；减少动态效果模式进入 `fallback`、暂停隐藏视频并保留 Canvas，console error 为 `0`。
- 刷新与 DEV 边界：旧 `c4-prologue-task-card` ID 按 Task14 的兼容规则迁移到 canonical `c4-755-opening`，重载会自动完成 A1 安全恢复，不作为可停留的独立任务卡节点。已提交的正式 `opening_handoff` 仍以 `43834ms` 初始化序幕层，并在 A1 ready 后自动释放。该行为与当前 11 个第四章正式 DEV 节点合同一致。
- 单文件与 Git：最终 ignored `demo/index.html` 为 `246712370` bytes，SHA-256 `3c8ecf5963200ba6da727199e1fc71d391ea2de5536542d516e229ffc4a8609a`，含 `2` 个 inline script、`1` 个 inline style，外部 script/stylesheet 标签均为 `0`。Playwright CLI 阻止新的 `file://` 导航，当前通过 HTTP MSE 播放与单文件结构校验。按用户要求未执行三层碰撞/遮挡专项。Task16 只读 fetch 确认当前 checkout 比 `origin/main` 少 `17` 个提交；清理 H3 临时快照后，工作树有 `104` 个 modified tracked files 与 `586` 个 untracked files；未执行 stage、commit、push、merge、rebase 或 reset。

## 2026-08-22 《7:55》MiniMax H3 宣传 PV 锚点、分镜与节奏预演

- 剧情范围：基于当前实机和 DEV 检查点，确定 `35s` 宣传链路为“07:55 闹钟 → 首页数字调查 → 0798 签到 → 图书馆 022 → 755 米骑行 → 剧院聚光灯 → 启真湖皮划艇 → 22:45 A1 → 202 最后一分钟 → 早晨双签到 → 07:55 片名”。正式外景资产仍缺少确认，本版不展示该段。
- 实机锚点：通过浏览器逐一进入当前章节检查点，保留 `10` 张 `1920×1080` Picture 锚点；新增玩家、纸条、自行车、骑行动作、皮划艇、白衣 NPC、绿衣 NPC 共 `7` 张 Subject 锚点。全部上传图为 PNG、8-bit sRGB、无 Alpha，最大 `2048×2048`，低于 `5760×5760`。
- H3 方案：`docs/plans/2026-08-22-minimax-h3-game-promo-pv.md` 提供三段全参考六段式英文提示词、逐秒分镜、逐片上传映射、UI 保真限制、NPC 数量限制、返工顺序、后期字幕、配音稿、音乐音效表和验收清单。三个静音片段为 `11s + 12s + 12s`；H3 实际生成与播放次数仍为 `0`。
- 可视交付：资产包位于 `docs/assets/minimax-h3-promo-pv-20260822/`，包含 Picture/Subject 锚点、原始截图副本、三张片段分镜、总览、片尾卡、CSV 剪辑时间线与 manifest。`seven_fifty_five_promo_pv_animatic_35s.mp4` 使用当前游戏音乐和八个节点音效完成截图硬切预演。
- 验证：manifest 通过 JSON 解析；六个 H3 提示字段各出现 `3` 次；17 张上传锚点均通过尺寸、8-bit sRGB 与三通道检查。预演视频为 `1920×1080 / 24 FPS / H.264 / yuv420p`，音频为 `AAC / 44.1kHz / stereo`，时长 `35.000000s`，文件大小 `4565816` bytes；关键帧接触表经人工检查后已删除。本轮没有修改游戏运行时代码，没有执行 build、Git 写或 H3 在线生成。

## 2026-08-22 MiniMax CLI 与 Hailuo 2.3 实际生成

- CLI 与额度：按用户更正改用 `MiniMax-Hailuo-2.3`，安装并立即验证官方 `mmx-cli 1.0.22`；`mmx auth status` 使用本机 `config.json` 中已保存的 API Key，输出只显示遮罩值。生成前视频额度为 `5/5`，生成后本周期使用 `5/5`、周额度使用 `5/35`。当前 CLI 的 Hailuo 2.3 路径只接受单张首帧，`--duration / --ratio / --reference-image / --last-frame` 属于 H3 或其他模型路径，因此五段均采用服务默认 6 秒 I2V。
- 五段原始输出：食堂上车、剧院抵达、图书馆 022、启真湖皮划艇、202 最后一分钟均通过一条直接阻塞的 `mmx video generate --model MiniMax-Hailuo-2.3 --image ... --download ...` 命令生成。五段统一为 `1364×768 / 24 FPS / 141 帧 / 5.875s / H.264 / yuv420p / 无音轨`，对应 MiniMax file ID 已写入 `docs/assets/minimax-hailuo23-generation-20260822/task-results.json`。启真湖首次提交遇到 `HTTP 502`；额度仍为 `3` 且无文件，确认未扣次数后只重试一次并成功。
- 画面验收：食堂段完成俯视地图、近景上车和后视骑行，但尾段远景路人增多且纸条靠近车轮；剧院段完成抵达与减速，但未完整下车或到达北向俯视尾帧。两段列为审片素材。图书馆保持单玩家、022 桌和 HUD；启真湖保持单艇、单人、北向投影与交替划桨；202 保持单玩家、单时间碎片并以青光结束，三段列为宣传可用。五段首/中/尾接触表已作为正式交付保留。
- 拼接交付：`canteen_755_theater_hailuo23_review_13_75s.mp4` 为 `1920×1080 / 24 FPS / 330 帧 / 13.75s / H.264 + AAC`，中间 2 秒实机画面表示真实可玩 755 米阶段；SHA-256 为 `fcea25d58b7687c3ffbd87e950d3f9bb5b682ea92a31a9d0193fc4576c3c75dc`。`seven_fifty_five_hailuo23_promo_mv_35s.mp4` 为 `1920×1080 / 24 FPS / 840 帧 / 35.00s / H.264 + AAC`，组合五段 Hailuo 画面、实机截图、片尾卡和当前游戏音乐音效；SHA-256 为 `82e6fa143e6fdb49baddb5ab0287b56d50459d593ce091a257e21d5be9cc24a8`。
- 边界：本轮实际调用 MiniMax 并耗用五次视频额度，没有修改游戏运行时代码，没有把视频接入章节控制器，没有运行 build 或 Git 写操作。运行时仍保持“生成上车片段 → 真实 755 米玩法 → 生成抵达片段”，后续接入前需要对两段衔接视频做用户视觉选择，并决定是否在新额度周期重生成两处偏差。

## 2026-08-22 Hailuo 2.3 衔接与宣传 MV 用户拒绝记录

- 验收结论：用户明确反馈两份成片均不可用。`canteen_755_theater_hailuo23_review_13_75s.mp4` 与 `seven_fifty_five_hailuo23_promo_mv_35s.mp4` 已在 `task-results.json` 标记为 `user_acceptance=rejected / integration_allowed=false`；两条衔接原片同步标记为 `rejected_by_user`，三条宣传原片改为待逐条复验。此前“可审片”“宣传可用”结论由本记录废止。
- 失败根因：食堂段在单个 6 秒任务中跨越北向俯视、人物近景和后视 3D，导致人物比例、自行车结构、NPC 数量和纸条位置漂移；剧院段同时要求后视接近、停车、下车和北向俯视交接，导致建筑几何与横向物体变形。当前 Hailuo 2.3 CLI 只有一张首帧，无法锁定精确尾帧或多锚点一致性。
- 重做约束：新增 `docs/plans/2026-08-22-hailuo23-transition-promo-redesign-after-rejection.md` 与 `docs/assets/minimax-hailuo23-generation-20260822/prompts/hailuo23-retry-prompts.md`。每个生成任务只允许一个投影视角和一个动作；食堂俯视、后视骑行与剧院俯视之间由实机定帧、短遮挡和硬切交接。
- 下一步门禁：`mmx quota` 复核视频周期为 `5/5`，恢复时间 `2026-08-23 00:00 CST`，周额度为 `5/35`。恢复后只提交 A1 后视骑行起步 6 秒验证片，抽取 `0 / 36 / 72 / 108 / 140` 帧并制作接触表；用户未明确通过时停止第二条和宣传 MV 的付费生成。

## 2026-08-22 第四章 H3 MiniMax 场景配音修复与接入

- 缺陷定位：逐段检查 `43.833333s` H3 画面、现有四角色语音目录、字幕时间线和单文件载入结果。玩家 `English_Diligent_Man` 与旁白 `English_expressive_narrator` 已与现有片头时间窗匹配，继续复用原文件；保洁员旧句长 `6211ms`，超过门厅可用窗口，保安旧句长 `4805ms` 且时间线没有触发，因此只重做两段 NPC 台词。`lake_exit` 与 `entrance` 保留画面和现场音，不新增旁白，避免同一信息重复说明。
- 场景提示词：新增 `docs/plans/2026-08-22-chapter4-h3-scene-voice-prompts.md`，记录六阶段镜头语义、角色声线、英文合成文本、中文字幕、语速、情绪、响度规范、触发点和最长时长。保洁员继续使用 `Chinese (Mandarin)_Kind-hearted_Antie`，保安继续使用 `English_Trustworthy_Man`；声线 ID 与之前配音一致。
- MiniMax 实际生成：通过本机已认证的 `mmx 1.0.15` 执行 `speech synthesize` 并进行一次短句节奏修订。最终保洁员为 `Careful, I just mopped. That paper went inside.`，字幕“保洁员｜小心，刚拖过。那张纸往里去了。”；成品 `2841ms / 47796 bytes / 32kHz mono MP3`，SHA-256 `3a7d8182c146d98e326e3fef26ff05873b5a95b305bec17c20b27e374439c465`。最终保安为 `The North Teaching Building is closing. Please pack up.`，字幕“保安｜同学，北教要清楼了，请收好东西。”；成品 `2413ms / 41460 bytes / 32kHz mono MP3`，SHA-256 `b49d31593914e24bf459b4f36670afffbe6abf7efd1d96e5da33e53dd4c408b4`。
- 一致性处理：生成器新增场景、触发点、时长预算、情绪和 `short_dialogue_consistent_v2` 校验；两段短对话统一经过轻压缩和双通道响度归一。最终保洁员为 `-17.2 LUFS / -1.9 dBFS true peak`，保安为 `-17.8 LUFS / -1.9 dBFS true peak`；既有玩家和旁白分别为 `-16.4 / -16.7 LUFS`。当前四段自动测量差值处于约 `1.4 LU` 范围，主观音色和表演接受仍需用户试听确认。
- 时间线接入：保洁员在 `29450ms` 进入，`32291ms` 结束，距门厅阶段结束保留 `1126ms`；保安在 `36000ms` 进入，`38413ms` 结束，距广播静电提示保留 `2629ms`。`PrologueTimeline.ts`、运行时音频表、内容清单和生成清单已同步，故事验证器要求两个正式 beat 存在，同时继续禁止备用肖像分支抢占 H3 画面。
- 验证：最终 `generate-chapter4-prologue-voice-audio --verify-only`、`chapter4:validate-story`、`typecheck`、`build:single`、`verify:single` 与定向 `git diff --check` 全部退出码 `0`。Chromium 从正式存档进入单文件，实测在视频 `29.543299s` 和 `36.126699s` 分别出现两条字幕并载入对应内嵌音频，console error/warning 均为 `0`。最终 `demo/index.html` 为 `246590721` bytes，SHA-256 `a1ac086d94ad0de439a903fd3f8b8a72521ff8ae6c9a3401e078b13843c3dd70`。
- 边界与清理：本轮未生成“灿若星辰”，未运行三层浏览器碰撞与遮挡专项，未执行 Git stage、commit、push、merge、rebase 或 reset。浏览器会话和本轮临时帧、响度文件、Playwright 页面快照已关闭并移至 macOS 废纸篓，可恢复。

## 2026-08-23 第三章半七选四录音取证与 MiniMax 正式素材

- 玩法：语音备忘录由四段直接排序改为七段试听、筛选四段、再排列顺序。三段混淆录音来自东区食堂、剧场和图书馆；页面试听前只显示 `CLIP` 编号，试听后展示可核对的环境声记录。选中任意混淆项会整组拒绝，四段正确但错序会单独提示声场不连续，正确顺序仍为 `lake → stone → lobby → broadcast`。
- 状态边界：`ChapterThreeInterludeVoiceClipId`、`GameState`、`SaveStore v25` 和四段正式证据存档保持原合同。三个混淆 ID 只存在于候选模型和 P21 页面运行时。控制器校验完整七候选集合，失败不把混淆项写入存档，也不会通过过滤混淆项得到成功结果。
- 提示词：新增 `docs/plans/2026-08-23-chapter35-voice-memo-prompts.md` 和结构化内容清单。提示词沿用主角 `English_Diligent_Man`、系统女声 `English_Graceful_Lady`、既有保洁员和保安声线。`human-writing` 检查结果为翻案句、同构排比、名词化、黑话、硬停词和模型路标各 `0`。
- MiniMax 与混音：本机已认证 `mmx 1.0.22` 实际生成四段 `speech-2.8-hd` 干声，时长为 `1997 / 4138 / 4310 / 4485ms`。FFmpeg 复用现有环境声、保洁员和保安配音，生成七段 `5200ms / 32kHz / mono / 128kbps MP3`。七段最终哈希均不同，综合响度为 `-21.3` 至 `-19.0 LUFS`，true peak 为 `-4.9` 至 `-2.4 dBFS`。
- 音频运行时：七段最终录音以受控 `voice` 预览播放；连续试听会暂停上一段，重复点击会停止当前段，页面隐藏、退出和卸载都会发出停止事件。UI 播放时长来自生成清单，当前录音不再沿用 `1200ms` 固定图标时长。
- 自动验证：首次专项验证按预期在缺失生成清单处失败。生成后 `audio:chapter3-interlude-voice-memos:verify` 通过，确认 `7` 段录音、`4` 段正确、`3` 段混淆、`4` 段 MiniMax 干声和 `11` 个生成资产；二次 `--verify-only` 显示 `networkUsed=false`。`typecheck`、`build:single`、`verify:single` 均通过，七段最终 MP3 均完成 Base64 全字节内嵌。
- 浏览器：Chromium `1280×720` 验证快速切换得到 `3` 次播放、`2` 次旧音频暂停和唯一活动停止按钮，退出后暂停数增加到 `3`。含剧场混淆项的组合保持在当前任务；正确四段错序被拒绝；正确顺序通过后任务进入“保存闭楼通知和入口截图”。`390×844` 文档尺寸为 `390×844`、横向溢出为 `false`；console error/warning 均为 `0`，网络记录只有重新载入的内嵌 `index.html`。
- 单文件：`demo/index.html` 为 `248256518` bytes，SHA-256 `b00c9d4454e6c20c5793e70099a1e2a7b1f96f9df5c9caebe0c455c6084c28b6`，包含 `2` 个内嵌 script 与 `1` 个内嵌 style。
- 已知全仓门：`chapter4:validate-story` 当前仍报告两项与本轮录音无关的既有错误，分别涉及 Task 7 真实脚框/目标几何来源和 Task 10 `Space` 交互范围。本轮未修改这两条第四章玩法。
- 清理与交付：本轮浏览器会话和本地 HTTP 服务已关闭；五个新建 Playwright 截图/快照移入 `/Users/zhuhangcheng/.Trash/codex-ch35-qa-20260823-1949/`，旧日志保留。未执行 Git stage、commit、push、merge、rebase 或 reset。

## 2026-08-22 第四章 H3 配音版 Demo 单文件打包

- 构建：使用仓库正式入口 `npm run build:single` 重新执行 TypeScript 检查与 Vite demo 构建，`606` 个模块完成转换，脚本和样式均内嵌到 `demo/index.html`，构建退出码为 `0`。
- 单文件验证：`npm run verify:single` 通过；最终文件包含 `2` 个内嵌 script、`1` 个内嵌 style，无需额外部署资源。文件大小为 `246590721` bytes，修改时间为 `2026-08-22 13:32:09 CST`，SHA-256 为 `a1ac086d94ad0de439a903fd3f8b8a72521ff8ae6c9a3401e078b13843c3dd70`。
- 配音封装：对最终 HTML 的实际内容进行 Base64 全字节匹配。保洁员 MP3 `embedded=true / 63728` 个 Base64 字符，保安 MP3 `embedded=true / 55280` 个 Base64 字符；四角色语音生成清单再次通过 `--verify-only`，没有重新生成文件。
- 交付边界：当前可交付入口为 `demo/index.html`。本轮未创建重复 ZIP，避免为一个单文件增加第二份约 `235MiB` 副本；未执行 Git stage、commit、push、merge、rebase 或 reset。

## 2026-08-23 第三章半与第四章统一拓展修复启动

- 用户已批准统一 Task 0–16，并确认可选细节范围为 `A1 + A2 + A3 + B1 + B3 + C2`；其余 `A4/A5/B2/B4/C1/C3/C4` 不进入本轮实现。
- 执行边界：保留第 3.5 章正式字段与 H3 入口合同；录音未完成草稿使用版本化 `sessionStorage`；所有章节交互继续不读取人物朝向；不生成新的“灿若星辰”；不执行 A1/A2/A3 碰撞、空气墙或前景遮挡浏览器专项。
- 工作区边界：当前分支为 `codex/bike-rush-visual-redesign` 且包含大量既有修改和未跟踪依赖。为保留当前真实基线，本轮不创建 worktree，不执行 Git stage、commit、push、merge、rebase 或 reset；按文件所有权协作并保留其他改动。
- 启动验证：实施前 `npm run typecheck` 退出码 `0`。

## 2026-08-23 第三章半与第四章统一拓展修复收口

- 已落地范围：按用户确认组合完成 `A1 + A2 + A3 + B1 + B3 + C2`，并把 `Task 1–14` 的核心实现收口到正式运行时代码。第 3.5 章完成统一内容入口、七选四录音模型、录音草稿恢复、照片/微信/网络泄露压缩、自动时间线与四候选终判、H3 前置预加载延后。第四章完成 `13` 段阶段差分、`6` 个时间态、任务栏三级提示、`204` 进度 `n/12`、`locked.detailCode` 细化、字幕/任务栏/道具反馈分层、DEV 检查点归一，以及批准细节 `B1/B3/C2` 的场景变化与音效切换。
- 明确阻塞边界：`Task 12` 仍保持阻塞。当前只保留“灿若星辰”正式 consumer 的等待位，不生成替代资产，不创建 `c4-755-result`，也不把外景收束误记为已完成。故事与运行时验证继续要求“缺正式 reference 时零写入”。
- 确定性验证：`npm run audio:chapter3-interlude-voice-memos:verify`、`npm run chapter4:validate-topology`、`npm run chapter4:validate-story`、`npm run chapter4:validate-runtime`、`npm run chapter4:validate-task14`、`npm run verify:rpg-facing-agnostic`、`npm run typecheck` 全部通过。过程中顺手修复了两处全仓类型阻塞：`src/scenes/rpg/canteen-chase/ChaseRiderRig.ts` 的接触点对齐辅助函数与双侧误差统计，以及 `src/scenes/rpg/ThreePrimitiveCache.ts` 的缓存键类型过窄。
- 浏览器路径：Chromium 已验证 `c3-interlude-timeline` 未提前泄露最终地点、`c4-prologue-task-card` 的“未确认刷新仍停任务卡 / 确认后刷新恢复 A1”语义、`c4-755-opening` 的 A1 释放、以及多个第四章 DEV 检查点的正文文案与无控制台错误。跨引擎抽样中，Firefox 代表检查点可起页；WebKit 仍在 RPG 资源解码阶段报大量 `*.png due to access control checks`，当前属于唯一未收敛浏览器残项，尚不满足“WebKit 零 pageerror”目标。
- 显式排除：本轮未执行 A1/A2/A3 的三层碰撞、空气墙、可通行区、前景遮挡浏览器专项；未做 Git 提交、合并或上传；未生成新的“灿若星辰”外景素材。
- 单文件产物：重新执行 `npm run build:single` 与构建后 `npm run verify:single`，最新 `demo/index.html` 为 `248416003 bytes`，SHA-256 为 `1c157d667ab51abd849810b6368c3aa394874056a97445a1a8424bd8717fc127`，结构验证结果为 `inlineScripts=2`、`inlineStyles=1`。

## 2026-08-23 第三章半与第四章统一拓展修复最终产物级复验

- 记录优先级：本条以当前源码重新构建并直接验收最终单文件，取代上一条“WebKit 仍有资源解码残项”和旧哈希结论。Vite 快速切换时曾出现被取消的动态导入错误，但正式交付的 HTTP 单文件在 WebKit 中没有复现；该开发态现象不再列为单文件交付阻塞。
- 实施范围：用户批准的 `A1 + A2 + A3 + B1 + B3 + C2` 已进入正式运行时。第 3.5 章的内容分层、七选四录音、试听草稿恢复、自动时间线、四地点终判和提示收敛，以及第四章的阶段差分、三级提示、204 复原进度、细化反馈、字幕分层、DEV/reload 合同、NPC 姿态和细节音效均已接通。全章节交互继续不读取人物朝向。
- 确定性验证：`chapter4:validate-story` 通过 `13` 个阶段、`6` 个时间态和 `17` 个道具操作；`chapter4:validate-runtime` 通过 `1125` 项断言；`chapter4:validate-task14` 通过 `337` 项断言并确认 `28` 个活动任务共 `84` 条提示；`chapter4:validate-topology` 通过 `2495` 项纯数据断言；`audio:chapter3-interlude-voice-memos:verify` 确认 `7` 段录音、`4` 段正式证据、`3` 段混淆项和每段 `32` 个 RMS 波形 bin，二次验证未联网。资产、人物帧、全仓朝向禁用、TypeScript 和单文件结构验证均通过。
- 最终单文件浏览器矩阵：Chromium `1280×720`、Firefox `1366×768`、WebKit `390×844` 均完成真实 HTTP 加载，三者均为 `consoleErrors=0 / pageErrors=0 / requestFailures=0`，文档无横向或纵向溢出，任务抽屉可滚动且只保留一个 Phaser canvas。Chromium 验证未确认任务卡刷新仍停留、确认后进入并恢复 `opening_handoff / A1 / c4_a1_lobby`，且 `contractFailures=[]`、键盘输入恢复；Firefox 验证阶段 6、维修 `0/6` 和三级提示；WebKit 验证阶段 11、签到 `0/2`、三级提示和同一任务卡刷新合同。
- H3 当前产物复验：三内核均从内嵌单文件创建 `blob:` 视频源，`data-h3-video=ready`、`readyState=4`、解码尺寸 `960×540`、媒体错误为 `null`，连续采样均前进约 `2.51s`。Chromium 自然播放到 `43.64/43.92s` 后显示“第四章：时间迷宫”任务卡；Firefox 与 WebKit 在确认实际播放后点击“跳过恢复回放”，同样显示任务卡。三条路径均为零控制台错误、零页面错误、零请求失败。
- 最终产物：重新执行 `npm run typecheck`、`npm run build:single` 与 `npm run verify:single`，`demo/index.html` 为 `248422234 bytes`，修改时间 `2026-08-23 22:51:00 CST`，SHA-256 为 `b9479da111a6a232402f581a1f51643b7edd3f1a1f9d556f669874f3ad79e62e`；结构为 `inlineScripts=2 / inlineStyles=1`。构建后确认没有活动源码文件晚于该产物。
- 保留边界：Task 12 继续等待用户提供唯一、已批准的“灿若星辰”仓库路径或 `assetId`、对应 `sequenceId` 和真实 consumer 完成回调；在此之前保持 `c4-755-closure`，不伪造 `c4-755-result`。本轮按用户要求没有执行 A1/A2/A3 碰撞、空气墙、必须可通行区和前景遮挡浏览器专项。音频的可解码、时长、波形和响度合同已经自动验证，主观音色与表演仍需用户试听决定。
- 清理与交付：最终浏览器会话均已关闭；本轮临时 QA 脚本与截图在记录证据后删除。本轮未执行 Git stage、commit、push、merge、rebase、reset 或上传。

## 2026-08-23 手机应用 UI 系统、浙大钉功能与校园生活相簿

- 全局 UI：新增 `PhoneAppUi.tsx` 与 `phone-app-ui.css`，统一手机应用内部的状态栏避让、64px 页头、64px 底栏、列表行、分段控件、状态反馈和操作面板。操作面板统一实现 Escape 关闭、Tab 焦点循环、显式初始焦点、关闭后返回真实触发控件；针对 Safari 指针点击不设置活动元素的行为，页面会记录指针或键盘触发控件并显式恢复焦点。`docs/phone-ui-system.md` 固定了外壳、应用主题、锁定槽位、反馈和状态写入边界。
- 浙大钉：新增 `ZjudingAppRegistry.ts` 与 `ZjudingUtilityPanel.tsx`。首页、百事通搜索和工作台共用 11 项稳定应用定义与同一 `FeatureAccess` 判定；身份未读取时只保留“首页”按钮，其余四个底栏槽位和十个受限应用均为无按钮、无焦点、无点击的静态槽位。身份恢复后开放智云课堂、网络账户、后勤服务、失物档案、访客预览、慧学外语、意见草稿、全部应用、通讯录、消息和个人页。新页面只读取正式状态；访客与意见仅写两个版本化 `sessionStorage` 草稿键，界面明确显示“未提交”或“本机草稿”。
- 照片内容：新增 `phonePhotoCatalog.ts`，集中管理原有 6 张图书馆相册照片和 6 张校园生活照片。只有稳定条目 `seat_022_clue` 可调用既有物品报告流程；新增校园、学习空间、宿舍和食堂照片全部为 `decorative`，点开、筛选和关闭均不写剧情、物品、任务或存档。图书馆相册由 6 张扩展到 12 张，并可切换“最近 12 张 / 校园与日常”；第三章半照片应用增加独立“校园与日常”相簿。两处预览均复用共享操作面板。
- 素材来源边界：校门、月牙楼、启真湖浮桥和天鹅等场景特征只依据浙江大学官方公开页面核对。网页图片没有进入游戏包，也未被声明为可再分发素材。六张正式 WebP 由新构图提示生成，统一为 `512×512`，无水印、无可读标志、无 `07:55`、纸条、022 或其他剧情线索；来源与约束记录在 `docs/photo-library-source-notes.md`。
- 浏览器验证：先使用 `develop-web-game` 的正式 Playwright 客户端读取 `render_game_to_text`，再运行集成点击链。Chromium、Firefox、WebKit 均完成浙大钉课程页、百事通首焦点、Escape、焦点恢复、访客草稿和校园相簿；三类引擎均为 `consoleErrors=0 / pageErrors=0`。身份未读取检查得到 `1` 个可用应用、`10` 个静态应用槽位、`1` 个可用底栏按钮、`4` 个静态底栏槽位和 `0` 个可聚焦锁定槽位。`1280×900` 与 `390×844` 均无文档横向或纵向溢出；缩放视口的状态栏底边和应用骨架顶边精确重合。六张新增图片在三类引擎中均完成解码，实际尺寸均为 `512×512`。访客草稿与普通照片点击前后的领域状态摘要完全一致。
- 离线单文件：`npm run typecheck`、`npm run build:single` 与 `npm run verify:single` 全部退出码 `0`。直接通过 `file://` 打开构建后的 `demo/index.html`，Chromium 成功进入智云课堂和校园生活相簿，六张图片全部解码，控制台和页面错误均为 `0`。最终文件为 `249126873 bytes`，修改时间 `2026-08-23 23:51:30 CST`，SHA-256 为 `9551e0d750400c736b83ab3bd02e67f8289d1c45fba6f53212bf97ee91b68e48`，结构为 `inlineScripts=2 / inlineStyles=1`。
- 范围与交付：本轮只迁移浙大钉、第三章半照片相簿和图书馆照片层；微信、CC98、设置、天气等应用仍可分批迁入同一套 primitives。未新增 `GameState`、`SaveStore` 或正式业务字段，未执行 Git stage、commit、push、merge、rebase、reset 或上传。

## 2026-08-24 全通关后“7:55 挑战”无尽小游戏中心计划与自审

- 计划结论：保留手机桌面现有 `bike_arcade` 内部 ID、`7:55` 图标、`游戏` 名称和固定槽位，把 P16 升级为统一的 `7:55 挑战` 中心；首版包含节奏钓鱼、灯光追逐和 755 米骑行三种持续提难、失败结算的单局挑战。
- 状态审查：旧 `bikeArcade.unlocked` 属于第三章历史合同，不能作为通关权限；裸 `chapter4.completed` 会被当前 SaveStore 防伪迁移降级，刷新后也不能稳定开放入口。计划新增仅在第四章正式素材引用和 consumer session verifier 均通过后写入的 `chapter4_closure_v1` 持久回执，并将通关权限、三模式成绩和旧骑行状态分离。
- 迁移风险：执行时先固定 Chapter 4 v25 迁移阈值，再把整体 SaveStore 提升到 v26；同时限制 `currentScene === "bike_arcade"` 的旧第三章推断版本，避免 postgame 页面刷新时改写图书馆进度。正式入口改为不可从桌面删除，旧隐藏配置会在归一化时移除该 ID。
- 玩法复用：节奏钓鱼复用启真湖单调时钟、判定窗、hold、combo 和 tension；灯光追逐复用第三章剧院路径、光束覆盖和连续锁定；骑行复用 P16 的 390×650 Phaser scene、可解三车道波次和暂停生命周期。共享规则提取必须先通过原剧情固定用例 parity，再接入无尽规则。
- 运行时边界：新增一个 `EndlessArcadeController` 和一个 `EndlessArcadeGameHost`；一次只挂载一个 Phaser canvas。当前局的 seed、音符、障碍、目标、按键和计时器不写存档；三模式只提交经过校验且每个 run ID 只结算一次的 summary。
- 自审与执行：`project-development-report.md` 已增加完整 Task 0–13，覆盖正式回执、挑战中心、三模式、开发检查点、确定性验证、30 分钟资源长测、Blink/Gecko/WebKit、多视口和离线单文件。正式第四章收束仍依赖既有 Task 12 的真实“灿若星辰”reference、consumer 和 verifier；开发检查点可以先验证玩法，但不生成生产通关事实。
- 本轮边界：仅完成计划、代码证据审查和实施自审；未修改运行时代码、存档版本、`demo/index.html` 或 Git 状态，未执行构建和上传。

## 2026-08-24 全通关后“7:55 挑战”首批 Task 0–2 实施

- Task 0 验证入口：新增 `scripts/verify-endless-arcade.mjs`，并在 `package.json` 登记 `npm run endless:validate`。验证器固定为 84 项合同，覆盖正式回执、存档迁移、入口权限、三模式注册、单局控制器、确定性规则、剧情兼容和交付接线；命名函数提取改用 TypeScript AST，并通过对象返回类型、注释、字符串和模板字符串花括号的自检。
- Task 1 正式回执与迁移：`GameState` 新增 `postgame.mainStoryCompletionReceipt` 与三模式 `endlessArcade.records`；`selectMainStoryCompleted()` 只接受 `chapter4_closure_v1`，`FeatureAccess.endlessChallenge` 成为统一权限。SaveStore 固定第四章迁移阈值 `25`、整体版本提升到 `26`，对裸完成态、无效回执和旧骑行成绩执行受限归一化；经 verifier 接受的第四章正式收束在一次 controller 事务内写入回执、章节完成、手机主页路由与瞬态 UI 清理。
- Task 2 固定入口：保留 `bike_arcade` 内部 ID、`7:55` 图标、`游戏` 名称和原桌面顺序；该入口不可删除，旧隐藏列表会移除其 ID。P13、SceneRouter 和 P16 统一读取 `endlessChallenge`。锁定态为静态无焦点元素；解锁后同一槽位变为按钮。桌面编辑同时禁止锁定图标成为指针或键盘交换的源与目标，F2 可进入键盘编辑态，pointer capture、lost capture、window blur 与卸载均清理拖拽状态。
- 规格与质量复核：Task 0、Task 1、Task 2 的规格审查均通过；Task 0 与 Task 1 最终质量复核通过。Task 2 首轮发现锁定图标换位、键盘无法进入编辑态和跨槽位释放清理三个问题，修正后原审查者返回 `QUALITY APPROVED`。
- Fresh 验证：`npm run typecheck`、`npm run chapter4:validate-story`、`npm run chapter4:validate-runtime`（1125 项）与 `npm run chapter4:validate-task14`（337 项）均退出码 `0`。`npm run endless:validate` 按计划退出码 `1`，84 项通过 56 项、剩余 28 项；当前 Task 0–2 对应的状态、回执、SaveStore、手机入口和剧情兼容分组全部通过，失败只指向 Task 3 以后尚未创建的 registry、controller、三模式规则与 CI 接线。
- 生产边界：正式“灿若星辰” reference/consumer verifier 仍未接入，生产入口继续锁定；本批没有生成替代素材，没有修改 `demo/index.html`，没有运行 `build:single`，也没有执行 Git stage、commit、push、merge、rebase 或 reset。

## 2026-08-24 全通关后“7:55 挑战”Task 3–5 实施

- Task 3 挑战中心与宿主：P16 已重构为统一的“7:55 挑战”中心，包含节奏钓鱼、灯光追逐和 755 米骑行三张入口卡、玩法说明、最佳成绩、加载、暂停、退出确认、结算、错误恢复和返回手机主页。`EndlessChallengeRegistry` 通过显式 `import.meta.glob` 只懒加载选中的 scene；尚未进入 Task 6/8 的场景稳定返回结构化 `runtime_unavailable`，没有预置临时代码。`EndlessArcadeGameHost` 只维护一份 Phaser 实例和一个 canvas，boot timeout 会作废当前启动 session，页面隐藏、失焦和控制中心在 loading 或 running 时都进入显式暂停，结算会停止 scene，迟到的动态导入不能复活已失败局。
- 壳层边界：任务栏和物品栏只在 `loading/running/paused/confirm_exit` 四种活动局相位隐藏；锁定、中心、玩法说明、错误和结算页恢复正常。canvas 交给 Phaser `FIT` 计算并只施加最大边界，浏览器实测画布比例为 `390:650 = 0.6`。
- Task 4 控制器：新增 `EndlessArcadeController`，只写 `state.endlessArcade` 的对应模式记录。启动返回 `runId / mode / seed / attempt / sessionOnly` ticket；seed 使用固定 salt 的 deterministic hash，不调用随机数。一个 controller 只有一个 runtime-only active run；跨模式并发、过期或重复 ticket、非有限或越界 summary 都拒绝。结算更新独立模式的六项最佳字段，取消仅清除 runtime ticket。`SaveStore` 导出统一成绩上限，P16 与宿主以 ticket 串联启动和一次结算。
- Task 5 节奏复用：新增通用 `RhythmFishingEngine`；启真湖 `QizhenFishingRhythmModel` 保留原构造器、四个 chart ID、公开字段和常量，仅改为适配该引擎。新增 `EndlessFishingRules`，同一 `seed + segmentIndex` 必得相同谱面，首尾均为 hook，音符、层级、分数、缓存段和历史长度均受常量约束。`qizhen:validate-fishing` 校验四张谱面的 hash、正常/辅助音符数、全 Perfect、时间原点、70/130/190ms 边界、错误动作、hold 断开顺序、两种张力持续窗、取消和等距命中；全部通过。
- 验证：`EndlessArcadeController` 临时打包运行矩阵通过，覆盖并发拒绝、过期 summary、一次结算、取消和记录隔离。`npm run qizhen:validate-fishing`、`npm run typecheck`、定向 `git diff --check` 均为 0。`npm run endless:validate` 现为 87 项通过 77 项，剩余 10 项只指向未来 Task 7/9/13：灯光规则、无尽骑行规则和 CI 接线。Chromium Vite 实测以正式通关回执进入中心：hub 三模式可见；骑行运行态只存在 1 个 canvas、任务栏/物品栏隐藏、比例 0.6；结算写入 bike 记录；继续本局回到 running；确认退出回 hub 且不改变最佳成绩。390×844 下手机框保持 1:2 且文档无横向溢出。控制台 error 为 0。
- 交付边界：未修改生成的 `demo/index.html`，未运行单文件构建，也未执行 Git stage、commit、push、merge、rebase、reset 或上传。Playwright 自动页面快照目录仅为本轮临时检查内容，后续已清理。

## 2026-08-24 全通关后“7:55 挑战”Task 6–8 实施

- Task 6 节奏钓鱼场景：新增 `EndlessFishingScene`，以 `390×650` 三轨画布呈现明显判定线、张力、层级、连击和可见节拍 fallback；`J/K/L` 与三枚触屏键共享 press/release 合同。场景只消费 controller ticket 的 seed，段落完成后延续张力与连击，失败提交结构化 summary，不写剧情状态。
- Task 7 灯光规则复用：`TheaterSpotlightModel` 导出纯判定器，第三章剧院 controller 改为调用同一实现；新增 seeded 灯光路径、干扰路径、动态预览时长、操作时间、光束半径和锁定时长。专项验证覆盖原三轮成功与错灯位、提前、超时、中断，并检查 seed 复现、路径点上限和历史上限。
- Task 8 竖屏灯光追逐：实现 `preview → action → transition` 状态机、跨轮三格电量、连续锁定、提前照射/路线判断错误/锁定中断/行动超时四类扣电、400ms 可读反馈、动态难度和一次结算。行动阶段清除路线，两张纸使用完全一致的静态外观，目标身份只来自预览路线。
- 触屏与宿主：灯光模式使用横向 `role=slider` 滑轨与独立按住照射键，真实指针坐标经 React → Host → Phaser 归一化传递；滑轨、灯光键、钓鱼和自行车三键均显式 pointer capture，外部松手、取消、丢失捕获和离开统一释放且去重。暂停恢复后的页面相位只听 Host 状态，不再乐观显示 running。
- 视觉修补：真实浏览器发现挑战中心仍收到 legacy `bike_arcade_opened` 的“三条车道”旁白与旧骑行入口音乐；`PresentationDirector` 已停止按 `currentScene === bike_arcade` 自动发该 cue，旧剧情控制器事件和新的 `endless_arcade_*` 事件边界保持分离。
- 审查与验证：Task 8 经规格审查三轮收敛后 PASS，并经代码质量复审关闭触屏持续按下与暂停 UI/Host 状态分叉后 PASS。`npm run typecheck`、`npm run theater:validate-spotlight`、`git diff --check` 均通过；`npm run endless:validate` 为 `82/87`，剩余五项只属于 Task 9 自行车确定性规则和 CI 接线。
- 浏览器证据：Chromium 移动触屏 `390×844` 实测 `canvasCount=1`、canvas 比例 `0.6`、滑轨可见且能把光束移到左侧、行动期按住照射为 true、按钮外松手后为 false、预览期提前照射把电量从 3 扣到 2、进入行动后路线隐藏、退出确认后恢复 running；console/page error 均为 0。最新预览与行动截图已人工检查，旧骑行字幕修复后消失。
- 边界与清理：遵照当前要求未运行 `build:single`，未编辑 `demo/index.html`，未执行 Git stage、commit、push、merge、rebase 或 reset。本轮 Playwright 截图、状态、脚本和日志已移入 `/Users/zhuhangcheng/.Trash/codex-task8-qa-20260824/`，可恢复；开发服务器将在本批结束时关闭。

## 2026-08-24 全通关后“7:55 挑战”Task 9–11 收口

- Task 9 自行车双模式收口：`BikeRushScene` 现严格区分 `story/endless`，宿主在 endless 模式下强制写入 `bikeArcadeRunConfig={ mode: "endless", seed }`，Scene 对 bridge、mode 和 seed 不匹配直接抛错，不再静默回落剧情桥。剧情旧回调改为统一经过 `BikeArcadeStoryBridgeDispatcher`，`scripts/verify-bike-arcade.mjs` 新增有序 payload spy 断言，确认旧 755 米链路事件顺序和一次性 finish 未退化。
- Task 10 postgame 开发通道：新增 `寻人篇 → 7:55 挑战` 八个 session-only 检查点，覆盖通关后手机主页、挑战中心、节奏钓鱼开始/结算、灯光追逐开始/结算、755 米骑行跨圈/结算。`DeveloperChannel` 为这些节点附带 sessionStorage runtime seed；P16 在 `readEndlessArcadeDeveloperSeed()` 基础上可直接进入 hub、自动开跑或直达结算，不写正式存档。`render_game_to_text` 新增 `endlessArcadeRuntime` 调试快照，暴露 access、phase、selectedMode、activeRunId、attempt、snapshot 和 summary。
- 浏览器修补：Vite Playwright 实测先后发现并修正两个真实问题。其一，`postgame-bike-lap2` 没有读取开发起跑距离，导致仍从 0 米开跑；修复为 `EndlessArcadeGameHost` 读取 `getDeveloperBikeStart()` 并写入 registry，复测后状态变为 `progress=823`、`lap=2`。其二，synthetic `game_over` seed 因结果页渲染条件绑定 `runTicket` 而出现空白；拆分 runtime shell 与 host 挂载后，`postgame-fishing-fail` 复测已显示完整结算卡片和三按钮。
- Task 10 音频方向：新增 `src/data/endless-arcade.audio.json`，只复用现有 `bike_arcade` 音乐/音效资源，为 `mode_selected`、`runtime_requested`、`runtime_paused`、`runtime_resumed`、`runtime_finished`、`hub_returned`、`closed` 建立统一 cue。`AudioDirector`/`PresentationDirector` 已接入该时间线；页面隐藏、控制中心暂停、返回 hub 和关闭场景都会停止当前局音频，人声与排队 cue 也同步清空。
- Task 11 自动验证与 CI：`.github/workflows/web-ci.yml` 已在 `typecheck` 前加入 `npm run endless:validate`。`scripts/verify-endless-arcade.mjs` 扩展到 `98` 项，新增 postgame 检查点、runtime 调试快照、audio timeline 和 CI 接线断言；当前 fresh 结果为 `98/98 PASS`。受影响的 `chapter4:validate-task14` 保持 `337` 项通过，未把 postgame 节点误判进第四章 canonical DEV 列表。
- 浏览器证据：Chromium/Blink Vite 本轮完成三条定向路径。`?devCheckpoint=postgame-endless-hub` 显示 challenge hub，`render_game_to_text.endlessArcadeRuntime.phase === "hub"` 且 `selectedMode === null`。`?devCheckpoint=postgame-bike-lap2` 进入 running，`phaserCanvasCount === 1`、`progress === 823`、`lap === 2`、`tier === 2`。`?devCheckpoint=postgame-fishing-fail` 进入 `game_over`，结果页显示 `9240 分 / 6 次收线 / 层级 4 / 连击 19`，并保留“再来一局 / 返回挑战中心 / 返回手机主页”三按钮。
- 当前边界：尚未执行 Task 11 计划中的三模式 `30` 分钟长测，也未做 Firefox/WebKit、多视口和单文件 `?devCheckpoint` 验收；这些仍留给后续 Task 11/12。按当前要求，未运行 `build:single`，未编辑 `demo/index.html`，未执行 Git stage、commit、push、merge、rebase 或 reset。

## 2026-08-24 全通关后“7:55 挑战”Task 11 长测完成与 Task 12 浏览器修补

- Task 11 长测现已实际落地：`scripts/verify-endless-arcade-long-run.mjs` 被 `scripts/verify-endless-arcade.mjs` 调用，fresh `npm run endless:validate` 输出 `152/152 PASS`。三模式都完成等效 `30` 分钟离线跑测，同 seed 全量重放一致、异 seed 指纹不同，资源采样覆盖 start/mid/end/after_exit，controller 的 invalid summary、一次 cancel、一次 settle、三模式独立落库和 score ceiling 全部通过。`npm run bike:validate`、`npm run chapter4:validate-task14` 与 `npm run typecheck` 本轮也均为 `0`。
- Task 12 浏览器修补根因：真实浏览器下 `?devCheckpoint=postgame-fishing-start` 会先进入运行态，再在首局失败结算时落入错误页。根因不是钓鱼规则本身，而是 React 开发态严格模式会先执行一次 effect cleanup；P16 旧代码在 cleanup 中立即 `cancelAttempt(runId)`，把 controller runtime ticket 提前清掉，随后真实 `game_over` 到来时 `settleAttempt()` 返回 `null`，页面被误导向 `error`。
- 实施修复：`src/scenes/phone/P16_BikeArcade/index.tsx` 新增 `lifecycleEpochRef`，把页面关闭事件和 `cancelAttempt()` 放入 microtask，并要求 epoch 未变化才执行。这样 React 开发态的探测式 cleanup 不再吞掉当前局 ticket，真实离开场景时仍会按原合同清理。
- 修复后浏览器证据：Blink 正式客户端重新跑 `postgame-fishing-start`，页面不再出现 `玩法载入失败`，而是约 `5.2s` 后进入正常 `game_over`，`render_game_to_text.endlessArcadeRuntime.phase === "game_over"`，summary 为 `0 分 / 0 次收线 / 层级 1 / 连击 0 / durationMs≈5240`，记录成功落库到 `bestDurationMs`。Blink 下 hub、结算返回 hub、bike 第二圈运行态继续通过；bike 运行态保持 `phaserCanvasCount === 1`、`lap === 2`、`lane === 2`。
- 跨引擎补验：Firefox 与 WebKit 均成功打开 `?devCheckpoint=postgame-endless-hub`，读取到 `phase === "hub"`。两者都能运行 `postgame-bike-lap2`，得到 `phase === "running"`、`canvases === 1`、`lap === 2`、`lane === 2`。两者也都能把 `postgame-fishing-start` 自动推进到正常结算，`phase === "game_over"`，不再落入错误页。
- 清理与边界：本轮只修了 P16 生命周期，不改 `demo/index.html`，不执行 `build:single`，不做 Git stage、commit、push、merge、rebase 或 reset。浏览器截图与状态 JSON 在人工核对后已删除，只保留 `progress.md` 里的文字证据。

## 2026-08-24 全通关后“7:55 挑战”Task 11–12 最终验收

- 最新自动基线取代上方阶段性 `152/152` 记录：fresh `npm run endless:validate` 为 `172/172 PASS`。三模式分别完成等效 `1,800,000ms` 离线确定性模拟；同 seed 重放一致、异 seed 指纹不同。节奏钓鱼结果为 `97,960,166 分 / 146 段 / T13 / 最大连击 3808`，灯光追逐为 `267,311,772 分 / 648 轮 / T13 / 最大连击 648`，自行车为 `9,839,249 分 / 107,353m / T18 / 最大连击 1952`。
- 资源验证边界已明确：`modeledMemory` 仅为 `pure_rules_resource_counts_only` 的确定性驻留单位模型，`browserHeapMeasured=false`；三模式 start/mid/end 采样保持预算内，`after_exit` 的 runtime、objects、entries、history 和 timers 均为 `0`。本条不宣称完成真实浏览器 heap 测量。
- Task 12 生命周期修复完成：React StrictMode probe cleanup 由 lifecycle epoch 拦截；Host 在暂停和销毁前执行中性输入释放；灯光场景清除左右移动、照射、锁定与诱饵覆盖；钓鱼清除 held input 且不产生额外惩罚；三种 scene cleanup 同时覆盖 `SHUTDOWN` 与 `DESTROY`。
- 粗指针合同已统一：触控区仅在 `phase === running` 渲染；节奏钓鱼显示“左收 J / 起钩 K / 右收 L”，灯光追逐显示滑轨与“按住照射”，自行车只显示“左车道 / 右车道”。pointer capture 不可用或抛错时，window `pointerup`、`pointercancel`、`blur`、`pagehide` 与 document `visibilitychange` 仍会释放输入。
- 灯光追逐调试所有权已隔离：场景只挂载 `window.render_endless_spotlight_to_text` 和受控 `advanceTime`，不覆盖主应用 `window.render_game_to_text`；返回挑战中心后专用 hook、时间推进器和 Phaser canvas 均清理。
- 真实浏览器基础矩阵 `45/45 PASS`：Blink、Gecko、WebKit × `1280×720`、`1280×800`、`390×844`，逐一验证锁定桌面、挑战中心、节奏钓鱼运行态、灯光追逐运行态和自行车运行态。所有用例 `documentOverflowX/Y=0`，手机框比例为 `0.5`，运行态 canvas 为唯一 `390×650` 实例，任务栏和物品栏不覆盖画布，浏览器 diagnostics 为 `0`。
- 状态与生命周期工作流 `19/19 PASS`：三引擎均验证三个模式的失焦暂停、继续、控制中心暂停、退出确认、失败、重试和返回中心；三引擎移动端均验证无 pointer capture 能力时的 `pointercancel/pagehide` fallback。Blink 另以自然灯光失败完成一次 controller 结算，移除 session-only 开发检查点后写入正式临时浏览器存档，刷新后仍停留挑战中心且最佳成绩文本保持一致。
- 视觉抽查已覆盖 Blink 桌面挑战中心、`1280×800` 灯光运行态和 `390×844` 自行车触控态。检查完成后，本轮 `/private/tmp/codex-task12-matrix.*` 截图、JSON 和脚本均已删除；共享 Playwright MCP 仍在运行，其项目级 console 文件不计入本轮截图交付物，也未终止该共享进程。
- Fresh 专项验证均为 `0`：`npm run typecheck`、`npm run bike:validate`（`21/21`）、`npm run qizhen:validate-fishing`、`npm run theater:validate-spotlight`、`npm run chapter4:validate-task14`（`337` 项）。`project-development-report.md` 已把无尽节奏钓鱼键位从错误的 `A/S/D` 修正为 `J/K/L`；启真湖原剧情的 `A/S/D` 合同保持不变。
- 交付边界：Task 13 仍暂缓；本轮未运行 `build:single` 或 `verify:single`，未编辑 `demo/index.html`，未执行 Git stage、commit、push、merge、rebase、reset 或上传。

## 2026-08-25 全通关后“7:55 挑战”Task 13 单文件构建与上传前验收

- Fresh 自动验证：`chapter4:validate-assets`、`chapter4:validate-story`、`chapter4:validate-topology`、`chapter4:validate-runtime`、`chapter4:validate-task14`、`endless:validate`（`172/172`）、`bike:validate`（`21/21`）、`qizhen:validate-fishing`、`theater:validate-spotlight`、`verify:rpg-facing-agnostic` 与 `typecheck` 全部退出码 `0`。校园地图校验确认 `4516×3420` 正射底图、`13668×1084` 启真湖侧视走廊和 `24` 张玩家帧有效。
- Chapter 3 音频门首次以 `76/77` 报告 `music_qizhen_fishing.mp3` 缺失。已从已验证交付快照恢复相同二进制，并补回 `chapter3-qizhen.audio.generated.json` 的原哈希记录；复验为 `expected=77 / ready=77`。恢复文件为 `482628 bytes / 20.000s / 44.1kHz stereo`，SHA-256 `9cdbd42eef10c39d3b393b335a8458f29226aa1d74c0388adb026c31124de352`，本轮没有调用 MiniMax 或其他生成服务。
- 构建结果：`npm run build`、`npm run build:single` 与 `npm run verify:single` 全部通过。离线产物 `demo/index.html` 为 `249852086 bytes`，生成时间 `2026-08-25 22:34:14 +0800`，SHA-256 `cf935fd1fbc21e49f2b9903596d77d0f33743e84d89ef881e6b6216bf29aca5d`；结构包含 `2` 个内联脚本、`1` 个内联样式，未引用外部脚本、样式或 HTTP 资源。
- 单文件实际运行：标准网页游戏客户端从 `http://127.0.0.1:4178/index.html?devCheckpoint=postgame-endless-hub` 与直接 `file://.../demo/index.html?devCheckpoint=postgame-endless-hub` 分别进入挑战中心，两条路径截图像素结果一致、状态 JSON 完整且无 error 文件。HTTP 路径继续覆盖节奏钓鱼运行态与失败结算、灯光追逐运行态、骑行第二圈运行态；三个活动局的 `phaserCanvasCount` 均为 `1`，骑行为 `progress=984 / lap=2 / tier=2`。
- 浏览器范围：本次生成物复验使用 Blink；同一源码在前一 Task 11–12 fresh 基线中已通过 Blink/Gecko/WebKit 的 `45/45` 基础矩阵与 `19/19` 生命周期工作流。按用户明确要求，三层碰撞、空气墙、可通行区与前景遮挡浏览器专项继续排除。
- 上传边界：`demo/` 当前被 `.gitignore` 排除，普通暂存不会包含 `demo/index.html`。本轮到此仍未 stage、commit、merge、rebase、push 或 reset；下一步先 fetch，再分别展示工作区、本地领先、远端领先和未跟踪内容，由用户确认精确提交范围及是否强制纳入单文件。

## 2026-08-26 手机主页应用点按与物品栏遮挡修复

- 根因一：第二章及以后主页应用在 `pointerdown` 时立即把指针捕获给外层应用槽，普通点按的完整点击序列可能无法交给内部按钮；长按编辑仍能生效，因此表现为“长按可编辑、点按进不了应用”。修复后普通点按不捕获指针，只有长按达到 `460ms` 或已处于桌面编辑态时才捕获；窗口失焦、取消、丢失捕获和卸载仍清理交互状态。
- 根因二：物品栏在道具合成后保持展开，并跨手机场景保留，左侧应用与后续页面控件会被实际面板遮住。所有成功合成现在统一收起物品栏并清空选中项；`SceneRouter.goTo()` 与 `back()` 在成功切换场景时执行同样的瞬态 UI 清理。
- 真实鼠标回归：逐项完成“合成右移箭头 → 点按应用”，微信、浙大体艺、浙大钉、设置、CC98、控制中心共 `6/6` 通过；长按仍进入编辑态且不打开应用；未先合成时从主页进入浙大钉也会自动收起物品栏。浏览器 console/page error 为 `0`。
- 构建与离线验证：`npm run typecheck`、`npm run build:single`、`npm run verify:single` 全部退出码 `0`。生成的 `demo/index.html` 为 `249852378 bytes`；直接 `file://` 运行重新完成右移箭头合成并点按进入微信，`rightArrow=true`、`inventoryOpen=false`、`selectedItem=null`、`currentScene=wechat`，错误为 `0`。
- 当前边界：用户要求此项先不继续；本轮未执行 Git stage、commit、merge、rebase、push 或上传。

## 2026-08-26 紫金港动态天气与启真湖停航美术基准

- 新增 `docs/art-prompts/zijingang_dynamic_weather_v01.md`，将时间、天气、地表、风、水面和能见度拆为独立状态，并定义固定底图、时间调色、云影、地表响应、水面响应、天气粒子、动态对象、前景遮挡和 HUD 的层级合同。
- 使用正式紫金港底图生成晴朗清晨、无降水阴天、小雨清晨和雨后转晴四张美术定调图；使用正式启真湖码头底图生成雨天停航参考图。五张图均保存在 `src/assets/rpg/**/weather/`，原始正式底图未改动。
- 玩法分流已固定：晴朗与低风无降水阴天允许通过码头检查后下水；小雨禁止下水并切换为岸线湿纸、漂移方向和停航记录调查；雨后转晴需要通过风、水面和能见度检查并等待天气过渡完成后开放下水。
- 安全条件统一为无降水、无阵风、水面非短浪、能见度合格且天气过渡完成。拒绝结果包含结构化原因和下一行动，禁止静默拦截。
- 生成整图只承担风格与颜色参考。正式地图、坐标、碰撞、入口和任务物品仍使用原资源与 TypeScript controller；后续实现应从原图提取固定掩模并组合可调天气图层。
- 本轮仅增加美术参考图、提示词和实现合同；未修改运行时代码、`demo/index.html` 或 Git 状态，未执行构建、暂存、提交或上传。

## 2026-08-26 全游戏任务提示所有权清理

- 浙大体艺绿色状态卡在锻炼开始后只保留“课外锻炼进行中”，移除三角形和天气水滴的持续路线提示。
- `movementQuest()` 将方向控制阶段拆成八个任务栏目标：收集两项素材、补三角形、补天气水滴、处理导师头像、组合右箭头、调整余额、购买手柄、安装并校验手动移动。三角形与水滴继续支持任意取得顺序。
- 全游戏搜索并清理页面、成功 Toast、道具详情和 RPG 成功字幕中的重复跨页面路线，覆盖图书馆恢复材料、CC98 手柄交易与十大、公演接单、时间线恢复、第四章微信、电梯与导视板、寝室出口、剧院第一波和启真湖装备/河道状态。
- 交互失败纠正、当前小游戏操作、锁定原因、持有道具的当前用途和任务栏自身的“显示下一条提示”继续保留。
- 新增 `npm run verify:task-guidance`，扫描 `src/scenes`、`src/components` 和 `src/data`，阻止页面重新出现“下一步：”或“接下来”式全局路线提示；共享 `QuestClueStrip` 为唯一豁免所有者。
- `AGENTS.md` 已写入任务提示所有权规则；剧情与提示文本总表同步更新本轮变更的道具详情和交易成功文案。
- Fresh 验证：`npm run verify:task-guidance` 检查 `202` 个源文件并通过；`npm run typecheck`、`npm run build:single`、`npm run verify:single` 全部退出码 `0`。离线单文件为 `249853441 bytes`，包含 `2` 个内联脚本和 `1` 个内联样式。
- 任务选择器状态矩阵通过 `9/9`：均未取得、水滴先取得、三角形先取得、两者齐全、竖线取得、箭头合成、余额调整、手柄购买和手柄安装分别指向正确任务与场景。最终单文件确认旧浙大体艺提示、旧手柄交易路线和旧盛水耳机路线均不存在，新任务目标已内联。
- 可视验证边界：应用内浏览器安全策略拒绝直接导航到本地 `file://` 单文件，因此本轮没有可视化通过结论，也没有绕过限制；创建失败后的空白临时标签页已经关闭。
- Git 边界：本轮未执行 fetch、stage、commit、merge、rebase、push、reset 或上传。

## 2026-08-26 DEV 导航独立 3.5 章

- 开发者通道新增独立 `3.5章` 页签，将原来分散在第三章的八个“未同步记录”节点和第四章的七个 H3 教学楼衔接节点统一迁入；总节点数保持 `114`，各章计数更新为第一章 `6`、第二章 `35`、第三章 `39`、3.5 章 `15`、第四章 `11`、寻人篇 `8`。
- 3.5 章内部按“未同步记录”和“教学楼过渡”分段；节点标题移除重复的 `3.5·` 与 `3.5→4·` 前缀。第四章现在从 `c4-755-opening / 入楼与纸条` 开始，DEV 章节边界与真实玩法边界一致。
- 所有 checkpoint ID、H3 时间偏移、session-only seed、刷新恢复和第四章 controller 入口保持原合同；专项校验新增 3.5 章完整顺序断言，并要求第四章只包含十一项正式时间迷宫节点。
- Fresh 验证：`npm run chapter4:validate-task14` 为 `338` 项通过，`npm run verify:task-guidance` 检查 `202` 个源文件通过，`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均退出码 `0`。
- Blink 真实运行验证：从 `c3-interlude-reboot` 打开 DEV 后，`3.5章 / 15` 默认进入“未同步记录”，实点“教学楼过渡”后显示 `7` 个 H3 节点；实点“第四章”后显示 `11` 个节点且首项为“入楼与纸条”。两个场景均未生成 console/page error 记录，截图经目视检查后移入废纸篓。
- 离线单文件 `demo/index.html` 为 `249853351 bytes`，SHA-256 `cee1abaa5ae89f793cb135d1a9cb7dfe67f4f44c69fc9542ce6b3cdee09ba16c`；产物包含 `3.5章`、`未同步记录`、`教学楼过渡`，且不再包含旧标题 `3.5→4·完整回放`。
- 当前边界：本轮未执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传；浏览器截图只用于临时 QA，没有加入交付物。

## 2026-08-26 第四章顶部任务状态栏统一

- 根因确认：第四章将时间状态、楼层、当前目标和局部进度同时写入共享任务栏的折叠按钮，并额外挂载 `has-chapter-four-context` 与第二行 `quest-task-local-progress`，使原本全章节统一的单行任务状态栏变成拥挤的第四章专属布局。
- 折叠状态现统一为“章节标签 + 当前任务”，与此前任务接取后的状态栏使用相同 DOM 和 CSS；第四章示例为“第 4 章 · 拉动大厅旧钟，让它第一次转动”。时间、楼层、可信度、阶段差分、局部进度和已确认事实继续保留在展开后的任务详情中。
- 清理 `triggerObjective`、`quest-task-local-progress` 和 `has-chapter-four-context` 专属分支，并在 Task 14 校验器中增加静态合同，阻止第四章再次把时间差分塞回折叠任务栏。
- Fresh 验证：`npm run chapter4:validate-task14` 为 `339` 项通过；`npm run verify:task-guidance` 检查 `202` 个源文件通过；`npm run typecheck`、`npm run build:single`、`npm run verify:single` 与 `git diff --check` 均退出码 `0`。
- Blink 真实运行验证：`1280×720` 下折叠栏为 `44px` 单行且无局部进度节点；展开任务栏后仍显示“现场 22:45 · 手机 07:55:23 未同步”“07:55:23 · 手机未同步，当前读数不可信”和当前目标。接近用户截图的 `842×837` 视口无文档溢出、无 console/page error。
- 离线单文件已用直接 `file://` 路径复验同一状态栏，未出现旧的时间拼接布局。`demo/index.html` 为 `249852899 bytes`，SHA-256 `0d4e520d5a68a520e2102a6dcc6841a53ee6e55873d1af81f1684479a1981fd4`。
- 当前边界：本轮未执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传；临时浏览器截图仅用于目视 QA，不加入交付物。

## 2026-08-26 第四章旧钟配准与 RPG 静默预热

- 旧钟错位根因：`ensureHallClockStateSprite()` 先前用大厅旧钟的交互矩形除以未裁边的 `frame.realWidth / realHeight`，把透明留白算入缩放，同时将贴图放在交互框中心 `(1001,90)`。对 A1 原画、22:45 开场图、22:45 维修图和钟表帧做径向边缘测量后，原画钟轴为 `(996,63)`、表盘半径为 `37px`，贴图表盘半径为 `108px`。
- 视觉合同：`finalClockRuntime.visualRegistration` 现在固定原画钟轴、`37/108 = 0.3425925926` 的统一缩放、`clock_axis` 帧锚点和测量来源；贴图不再读取交互矩形尺寸。分针运行时共用同一钟轴，程序化端点 `getBounds()` 已实测更新为 `{x:967,y:26,width:16,height:16}`。
- 真实 A1 复核：修复前贴图白色表盘明显缩在原画金色外壳内部并向下偏移；修复后贴图外圈、钟轴和楼梯上方原画边缘重合。开启 `clock_gear_repaired` 后，分针端点作为正式运行时 target 出现，bounds 与布局一致，`chapterFour.contractFailures=[]`，浏览器 console/page error 为 `0`。
- 静默加载机制：`RpgRuntimePreload` 继续复用唯一 `RpgGameHost` 动态导入 Promise，并新增 scene-aware 空闲预热。每个 Phaser Scene 显式导出其正式 `preload()` URL 清单；Host 合并共享 `24` 张玩家帧并去重。普通手机流程用 `requestIdleCallback`，Safari 15 用 `180ms setTimeout` 回退；省流量或 `2g` 连接只预热模块并标记 degraded。
- 3.5→4 边界：时间线恢复页在目的地确认前保持 `rpgWarmup.status=idle / moduleReady=false / assetCount=0`；玩家请求恢复回放后，Gate 在 H3 播放期间立即预热教学楼。实测第四章为 `69/69` 张正式资源就绪，未扫描美术源目录，也未提前泄露地点结果。
- 进入体验：预热完成后同步发布已解析的 Host 组件，App 直接挂载它；Suspense 只保留为过快进入和失败兜底。Chromium 与 WebKit 的普通手机流程均为 `25/25` 资源就绪，进入 `campus_bootstrap` 分别约 `338ms / 314ms` 完成 Phaser 挂载，MutationObserver 均确认 `Loading RPG runtime` 从未出现，错误为 `0`。
- 单文件约束修正：首版通配 `import.meta.glob` 会把未使用的 RPG 源图纳入 Rollup，构建以 `Invalid string length` 失败；该实现已删除并由显式场景清单取代。修正后的 `build:single` 与 `verify:single` 通过，离线 HTML 结构保持两个内联脚本、一个内联样式；HTTP 单文件实测 `25/25` 预热完成且错误为 `0`。
- 当前边界：本轮没有执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。所有钟表和预热截图、JSON 仅作为临时 QA，结论记录后删除或移入废纸篓。

## 2026-08-26 第四章支援 NPC、电梯深度与启真湖雨天安全闭环

- 第四章新增两个布局锺定的非碰撞 NPC：A2 电梯口值班安全员和 A3 参照教室教师。两者只在 `room204_restore` 阶段激活，提供一楼 104/105 校验、A3 参照登记和返回 204 复原的当前状态反馈，不创建第二份进度权威。
- 电梯门、指示器和楼层灯改为固定背景深度 `3980/3981/3981`；玩家从 `4000 + worldY` 起排序。A1/A2/A3 的门心、等待点和到达点共 `9` 个锺点均断言玩家位于电梯前方。
- 启真湖小码头新增湖边安全员和可见雨层。安全员经两轮真实截图调整到码头铺装区 `(650,700)`，缩放为 `0.52`，避开水域、花坛和器材架实体。
- 新增持久事实 `qizhenLake.rainSafetyCleared` 和共享天气选择器。小雨且未放行时，`boardKayak()` 在 controller 内拒绝登船并发布可见原因；三件器材齐全后与安全员交谈，天气投影转为阴天并允许登船。旧存档和已进入上船阶段的 DEV 检查点自动补齐放行事实，不会倒退。
- 新增 `npm run qizhen:validate-rain-safety`，已实际运行 `7` 项 controller 断言：雨天拒绝、拒绝反馈、器材不足继续拦截、器材齐全放行、天气切换、放行后登船和载具状态写入均通过。
- Fresh 校验：`npm run typecheck`、`npm run chapter4:validate-runtime`（`1165` 项）、`npm run chapter4:validate-story`、`npm run qizhen:validate-rain-safety`、`npm run qizhen:validate-fishing`、`npm run qizhen:validate-journal` 和 `git diff --check` 均退出码 `0`。
- Blink `1280×720` 真实运行覆盖 `c3-qizhen-dock`、`c3-qizhen-boarding` 和 `c4-755-room204-1850`；安全员、雨层、放行后无雨状态、A3 教师 target 与第四章电梯深度调试状态均已实际呈现，console/page error 为 `0`。
- 当前边界：按用户要求未构建新的单文件，未编辑 `demo/index.html`；未执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。本轮浏览器截图与 JSON 只用于临时 QA，结论记录后删除。

## 2026-08-26 第四章电梯历史校准与双层错视楼梯回归

- 根因确认：第四章现行重写仍保留通用楼层选择框，但把旧电梯回放与错视楼梯字段降为兼容存档，原有 `ChapterFourMonumentStairDemo` 也没有正式的 `RpgGameHost` 入口，因此剧情中看不到电梯试错过程，双层楼梯玩法也无法进入。
- 正式流程改为：完成 104 粉笔残留与 105 终端回放后，在深色观察中读取 A1 电梯开门历史；切换浅色操作，把六秒人物轨迹对齐到八秒开门窗口；A2 暂时锁定，只允许先到 A3；登记 303 参照后，从三楼下行楼梯进入双层错视关；通关后自动落到 A2 走廊并继续 204 残影复原。
- 电梯校准面板使用现场时间轴：蓝色为 `22:43:27–22:43:35` 开门窗口，黄色为六秒人物轨迹，白线为上升沿；正确起点为 `22:43:31`。错误提交保留当前状态并显示下一次调整方向，不消耗剧情物品。
- `RpgGameHost` 现在在楼梯开始时暂停并隐藏 Phaser，在同一 `960×540` 宿主中挂载唯一 Three.js 画布；完成或退出后恢复 Phaser。Three.js 只提交 `complete_misaligned_stair` 领域意图，楼层、事实、检查点和存档仍由 TypeScript controller 写入。
- `AGENTS.md` 已固化这条因果路线：通用楼层选择器不得绕过电梯历史校准、A3 参照登记和双层错视楼梯，也不得再次取代这些正式进度门。
- 双层错视关沿用原有两关：第一关为横移台、中央旋转梯和出口升降台；第二关为下层旋转梯、中层升降台、上层旋转梯和出口横移台。机关、视角、投影接缝与两关素材均复用已存在的正式实现。
- DEV 增加 `c4-755-elevator-history`，可直接验证电梯轨迹校准；`c4-755-room204-1850` 现在从 A3 错视楼梯前开始，便于直接检查两层楼梯与 A2 回落。
- 自动验证已通过：`npm run typecheck`、`chapter4:validate-task14`（`364` 项）、`chapter4:validate-story`、`chapter4:validate-runtime`（`1176` 项）、`chapter4:validate-stair-materials`、`chapter4:validate-assets`、`verify-chapter4-stair-engine`（`51` 项）、`verify-chapter4-stair-levels`（`143` 项）和 `chapter4:validate-topology`（`2505` 项）。
- Blink 真实运行验证：电梯校准成功后楼层面板显示 `2F ×` 与可选 `3F`；A3 楼梯入口可进入 Three.js。Blink、Gecko、WebKit 均实际完成两层楼梯，最终状态一致为 `floor=A2`、`checkpoint=c4_a2_corridor`、`misaligned_stair_solved=true`、`data-rpg-engine=phaser`，console/page error 均为 `0`；Blink 的任务同时推进到“回到二楼，在深色观察中确认 204 残影”。
- 当前边界：按用户要求没有构建新的单文件，也没有编辑 `demo/index.html`；没有执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。浏览器截图只用于临时目视 QA，记录结论后删除。

## 2026-08-26 第四章校史人物荣誉门厅与竺老两问

- A3 校友墙从三位扩展为六位真实人物：苏步青、竺可桢、路甬祥、陈建功、谈家桢、程开甲。三位保留在中央荣誉墙，新增三位布置在北侧展板；竺可桢保持中央叙事位。每位人物都有独立 source-pixel 画框、近距离 `Space` 交互、生平弹窗和浙江大学官方资料入口。
- 新增六张透明背景像素人物像，运行时尺寸统一为 `384px` 高、文件为 `119–138KB`。`chapter4:validate-assets` 现在检查六张图的 RGBA 格式、尺寸、至少 `10%` 全透明背景、透明角点、`200KB` 上限及数据表引用，避免资源漂移和静默预热回退。
- 竺可桢生平页接入“竺老两问”。玩家完成两项选择后，controller 原子写入 `zhu_two_questions_answered` 与回答字段，任务栏切换到错位楼梯；未完成时，无论场景交互还是 Host 入口都拒绝进入楼梯。存档恢复会保持“事实与回答同时存在”，旧存档不会出现半完成状态。
- “灿若星辰灯”只新增 `canruo_star_lamp_primed` 准备信号，仍由现有正式灯光收束内容消费；本轮没有生成替代灯光素材，也没有绕过官方收束引用缺失时的关闭门。
- 修复人物弹窗的指针命中：屏幕固定按钮此前仍按滚动后的世界坐标测试，导致键盘可用但鼠标点击无效。背景、关闭按钮、行动按钮、选项与确认按钮现均显式使用 `scrollFactor=0`，与屏幕坐标一致。
- Blink `1280×720` 真实运行以鼠标完成“查看竺可桢生平 → 进入两问 → 选择第三项与第二项 → 两次确认”。最终状态为 `purpose=serve_public`、`person=clear_minded`、`zhu_two_questions_answered=true`，任务目标为“接通三楼通往二楼的错位楼梯”，console/page error 为 `0`；画面确认中央三幅人物像、相框、灯光、角色遮挡和交互提示位置正常。
- Fresh 校验：`npm run typecheck`、`npm run chapter4:validate-assets`、`chapter4:validate-runtime`（`1191` 项）、`chapter4:validate-story`、`chapter4:validate-task14`（`365` 项）、`npm run build` 与 `git diff --check` 均退出码 `0`。普通 Vite 构建确认六张人物像均保持 `119–138KB`，没有重新生成单文件。
- 当前边界：按用户要求没有运行 `build:single` 或编辑 `demo/index.html`；没有执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。浏览器截图与状态 JSON 只用于临时 QA，结论记录后删除。

## 2026-08-26 3.5 章设备接入记录纵向滚动修复

- 根因：`.interlude-scroll` 虽然声明了 `overflow-y: auto`，但 `interlude-network-page` 没有建立纵向 flex 高度约束，主内容按 `1521px` 完整高度向下增长后被 `430×860` 手机外框裁掉；内部元素不存在可用的滚动视口，因此列表第二、第三条记录和底部返回按钮无法通过滚轮或触屏到达。
- 修复：设备接入记录页改为 `display:flex / flex-direction:column / min-height:0 / overflow:hidden`；页头固定为非伸缩区域，主内容获得 `flex:1 1 auto`、独立纵向滚动、横向裁切、`overscroll-behavior-y:contain`、`touch-action:pan-y` 和 WebKit 惯性滚动。
- Blink `842×837` 桌面实测：内容区 `clientHeight=772`、`scrollHeight=1521`、最大滚动距离 `749px`；真实滚轮将 `scrollTop` 从 `0` 推进到 `720`，第三条启真湖记录、筛选说明和“返回记录恢复”按钮均进入可视区域，console/page error 为 `0`。
- Blink `390×844` 粗指针实测：通过连续触摸上划将 `scrollTop` 推进到 `749`，`touchAction=pan-y`，文档横向和纵向外溢均为 `0`。移动端底部内容完整可见，页头、任务按钮和 DEV 触发器未覆盖结果区。
- Fresh 校验：网页游戏回归客户端已运行并检查状态与截图；`npm run typecheck`、`npm run build` 和 `git diff --check` 均退出码 `0`。
- 当前边界：按用户此前要求没有运行 `build:single`，没有编辑 `demo/index.html`，也没有执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。临时 QA 截图、指标 JSON 与状态文件在记录结论后删除。

## 2026-08-26 第四章保安、保洁阿姨方向帧与自习学生动线修复

- 内置生图功能按统一像素角色合同生成保安和保洁阿姨的新素材。保安拥有下行、上行、右行各 `8` 帧，左行由右行等比镜像；保洁阿姨拥有推车下行、上行、右行各 `8` 帧和原地待机 `8` 帧。每帧固定人物尺度、头脚完整、脚底基线一致，推车动作保持双手与把手连接。
- 生图服务直接透明通道未稳定生效：首次保安稿把棋盘格写入 RGB，深色背景修订也没有可用 alpha。正式流程改用纯色中间底并自动生成 alpha、清理紫色边缘；七张 v3 source grid 与七张方向/待机运行时图均实测为 `srgba 4.0 / opaque=False`，可直接作为透明 PNG 使用。
- `build-finale-npc-atlases.mjs`、`FinaleNpcTextures.ts` 和正式 manifest 已接入新方向表。保安根据实际速度的主轴选择上、下或侧行动画；横向向左时镜像，低速及停顿保持上一朝向，避免两个花坛间原地左右翻头。维修完成后的保洁推车使用上行动画。
- 面包坊三名自习学生改为左上、右上、左下三条互不重叠的水平路线；修正源图原生朝左的镜像判定，往右才镜像，往左使用原图。运行时 debug 记录每名学生的位置、路线、镜像与动画，也记录普通保安的当前动画、方向和镜像。
- Blink 真实运行：`c4-755-maintenance-2245` 连续采样确认保安从 `guard_walk / side` 切换到 `guard_walk_up / up`，无 console/page error；`c4-755-bakery-1225` 三次采样确认三人分散，左右两向 `flipX` 与路线一致，且没有重叠或持续后退。
- Fresh 校验：`npm run typecheck`、`npm run chapter4:validate-assets`、`npm run verify:rpg-character-sprites`、`npm run chapter4:validate-runtime`（`1191` 项）、`npm run chapter4:validate-topology`（`2517` 项）和 `npm run build` 均退出码 `0`。本轮没有运行 `build:single`，没有编辑 `demo/index.html`，没有执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。

## 2026-08-26 三种通关后无尽挑战完整退役

- 按用户最终范围决定，删除通关后“无尽节奏钓鱼”“无尽灯光追逐”“无尽 755 米骑行”及其统一挑战中心；第三章剧情节奏钓鱼、剧院剧情追光和食堂剧情 755 米骑行继续保留。
- 删除 `P16_BikeArcade`、`P17_ChapterTransition`、`EndlessArcadeController`、独立骑行 controller、挑战内容表、挑战音频与样式；同步清理 `GameState`、`SaveStore`、功能门、手机首页入口、DEV checkpoint、CI、校验脚本、文档与剧情提示表中的正式引用。
- 静态扫描覆盖 `package.json`、CI、README、ASSETS、AGENTS、CONTRIBUTING、`src`、`scripts`、`docs` 与剧情文本总表，未检出 `endless`、`postgame`、挑战中心、已删除模块名或三种无尽玩法文案。
- Fresh 专项验证通过：DEV 为 `5` 章、`24` 关、`112` 个 checkpoint；CC98 登录、任务提示、全局无朝向交互、启真湖四张剧情谱面、雨天安全、剧院剧情追光、食堂剧情骑行、第四章素材/剧情/拓扑/运行时/Task 14/楼梯素材均通过。
- Fresh 构建验证：`npm run typecheck`、`npm run build`、`npm run build:single` 与 `npm run verify:single` 均退出码 `0`；新单文件为 `252290377 bytes`，包含两个内联脚本和一个内联样式。
- 真实浏览器验证覆盖 Vite 桌面、`390×844` 移动视口和 `file://` 单文件直开。三个环境均无退役玩法文案；直开结果为 `currentScene=phone_home`、`canvasCount=1`、退役 render hook 为 `undefined`，DEV 摘要为 `5 章 · 24 关 · 112 节点`。
- 临时 Chrome profile、Playwright 输出和浏览器 QA 截图已从工作区移出；正式交付不包含运行时截图或测试缓存。

## 2026-08-27 启真湖云层校准、含蓄提示与 CC98 收尾显示修复

- 启真湖天气应用取消一键完成，新增三层云带校准小游戏：低、中、高三层各在五个位置循环移动，玩家把实体云带移入虚线目标框后才能提交；初始局面理论最少为 `6` 步。
- 新增纯规则 `QizhenWeatherControlModel`。章节 controller 分离“开始一次校准”和“提交完成”，拒绝未开始、未对齐、越界或少于理论最少步数的结果；`weatherControlAttempts`、`weatherControlBestMoves` 与放行事实通过 `SaveStore` 持久化并完成保存后重载验证。
- 天气页的小雨和多云图形改为统一像素剪影：云层使用合并外轮廓、顶部高光和底部阴影，雨线扩展为 `18` 条并使用不同长度、位置和逐帧下落节奏。完成反馈收敛为“湖区状态已更新 / 返回码头确认”，不再提前解释停航解除逻辑。
- 湖边安全员在拦截、待处理和直接登船失败时只说“现在天气不能下水”；任务栏只显示“确认能否下水 / 解决当前下水条件”。船桨初始说明、场景提示、目标名称和首航贴文移除“去掉叶子的树枝”“旧三角牌”等直接答案，玩家靠近物体后才得到实际用途反馈。
- CC98“启真湖划船记录收尾”根因为页面继承四行列表网格，正文被自动放入 `54px` 行。收尾页现使用 `72px + minmax(0,1fr)` 两行网格，正文获得独立可滚动区域、有效最小高度和滚动边界。
- Chromium 真实流程：天气页按六次右移完成 `3/3 · 6 步`，提交后显示最佳 `6` 步，console/page error 为 `0`；CC98 在 `1280×720` 和 `390×844` 均完整显示主帖、湖面图、回复、两项收尾选择和发布按钮，移动逻辑视口 `clientHeight=742 / scrollHeight=750 / maxScroll=8`，发布后正常返回记录恢复页。
- Fresh 验证：`npm run typecheck`、`npm run qizhen:validate-rain-safety`（`25` 项，含保存重载）、`npm run qizhen:validate-journal`、`npm run verify:task-guidance` 与 `git diff --check` 全部通过。
- 当前边界：按用户要求未运行 `build:single`、未编辑 `demo/index.html`，所以已打开的旧离线单文件仍是旧内容；未执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。

## 2026-08-27 第三章半并行取证、现实模式解序与第四章阶段加载基线

- 现行计划已追加到 `project-development-report.md`，明确第一批只执行：第四章四阶段静默加载、第三章半四分支并行任务、全游戏浅色/深色交互解序。第四章有效教室/NPC 交互与保安感知状态机进入下一批实现。
- 基线分支为 `codex/20260826-main-delivery`，基线 `HEAD=07d1472`。工作树包含用户正在进行的人物侧面帧、空气墙、雨天表现、文本导出、Room 204、CC98 和浙大钉改动；本轮不得重置、覆盖或提交这些局部修改。
- 基线 `npm run typecheck` 已实际运行并退出码 `0`。本轮首批不生成新的单文件，不编辑 `demo/index.html`，不执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。

## 2026-08-27 第三章半四分支并行调查

- 任务选择器取消照片、录音、消息、网络的固定先后关系。完成划船记录起点后，任务栏统一显示“恢复剩余证据（n/4）”，并常显照片线索、录音线索、消息线索和网络记录四行；每行独立显示完成状态并可直接打开相应应用。
- 四类完成条件继续由既有 controller 事实判定：照片顺序完成、录音顺序完成、两条消息都保存、网络记录读取。聚合任务只投影状态，不创建第二份进度权威，也不在任务文案中显示记录 ID、地点答案或精确结束时间。
- 正式流程删除“核对自动恢复的时间线”独立任务。四类证据、三条旧时间和不可信时钟核验完成后直接开放地点选择；确认正确目的地时原子写入规范时间线。`assembleTimeline()` 与原 DEV checkpoint 继续保留，供旧存档和开发跳转兼容。
- `SaveStore` 增加双向归一化：摘要 evidence ID 可补回照片、录音、消息与网络细分事实；细分完成事实可补回摘要 ID；已满足前置条件的旧存档统一修复为规范时间线；已经进入第四章的存档强制恢复完整证据、排除项、目的地和完成态，避免章节倒退。
- 新增 `npm run chapter3:validate-interlude`。Fresh 结果为 `1933` 项断言通过，覆盖四分支 `4!` 排列与消息内部两种次序，共 `48` 条完整顺序；同时覆盖前置锁定、错误输入、三类旧存档、已进入第四章的旧存档、答案泄露检查和 `assembleTimeline()` 兼容。
- 相关门禁通过：3.5 录音 `7` 条成品、`4` 条正确项和 `3` 条混淆项全部验证；第三章总音频 `77/77`；任务提示所有权检查 `189` 个源文件。`git diff --check` 对本任务文件通过。
- 共享阻塞：本轮 `npm run typecheck` 当前只被并行 Task 1 的 `ChapterFourWarmupAssets.ts` 中间类型错误阻塞；`chapter4:validate-task14` 当前两项失败也都指向 Task 1 的阶段预热注册表和入口合同。本任务自身的 Task 14 任务栏静态要求已恢复。`npm run text:check` 报玩家文本导出过期，需要主线程在合并本轮新文案后运行 `npm run text:export`。
- 交付边界：本轮不构建单文件、不编辑 `demo/index.html`，不执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传。

## 2026-08-27 第四章四阶段静默加载

- 资源注册表统一为 `entry → transport → maintenance → closure` 四阶段。首次进入只把 A1/A2/A3 三张底图、A1 开场、主角、基础 HUD、前台与电梯交给 Phaser `preload()`；校友墙、学生、面包坊与 204 教室归 transport，保安、保洁、配电、停电与追逐归 maintenance，最后一分钟和早晨状态归 closure。旧 `FINALE_ENVIRONMENTS` 不再进入第四章时间迷宫加载链。
- 运行时每次只静默加载当前阶段的下一阶段，并逐个资源启动 Phaser loader。状态已经需要新阶段但资源尚未齐备时，保持上一张已提交投影；失败 URL 会保留，`1500ms` 后可由同一路径重试。深存档仍会在首次 `preload()` 中累计加载至其当前阶段，避免恢复后缺图。
- `RpgRuntimePreload` 按场景与阶段分别记录状态、资源数、复用数、失败 URL、预计/实测传输字节、预计解码字节、耗时、受限网络与低内存降级原因。空闲预热在受限网络或低内存设备只预取两个资源；必需阶段可随后完整重试。
- `registerChapterFour755ManifestFrames()` 与 NPC 动画注册支持当前已加载子集；只有五张活动 spritesheet 全部存在时才执行完整 `62` 帧和 `1` 个空帧合同，阶段加载期间不会把尚未下载的 sheet 误报为素材损坏。
- 新增 `npm run chapter4:validate-warmup`，确定性检查四阶段顺序、`12` 张 plate、`5` 张 spritesheet、`21` 组 NPC 动画的唯一归属、entry 资源边界、runtime loader、失败重试和指标字段。Fresh 结果：该门禁 `49` 项、`typecheck`、第四章 story、runtime（`1225` 项）、Task 14（`365` 项）和 assets 全部通过，`git diff --check` 通过。
- 本轮没有构建单文件、没有编辑 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或上传。浏览器阶段切换验证由主线程与其他批次的真实流程 QA 统一执行。

## 2026-08-27 第三章现实模式双顺序与触屏切换收口

- 食堂菜单、3 号取餐窗和旧餐盘车链允许“深色观察后浅色操作”与“浅色操作后补深色观察”两种路径；实体操作不再自动补写观察事实，实时防守完成只写通关进度。点餐后未读取的暗色菜单仍可返回点餐机补录。
- 剧院道具箱在浅色扫描打开后，切到深色观察仍会显示并记录道具残影与管理员提示；已打开状态不再提前吞掉观察事件。
- 启真湖以生锈钥匙钓点作为代表链路，钓取后仍可返回深色观察补录真实坐标；钓取本身不会写入 `observedFishingSpotIds`。四类代表路径的两种次序在保存前产生相同领域事实。
- 食堂防守、剧院追光和启真湖器材收集/上船阶段均补齐 React 触屏模式切换入口；切换直接提交 controller 事件，不依赖会被场景小游戏状态拦截的本地按键分支。
- 任务栏、道具说明、食堂与启真湖内容表已清理“先深色、再浅色”的旧提示；文案只说明当前动作需要的模式，并保留物品、距离、阶段与目标约束。
- `npm run verify:rpg-reality-mode-order` 从 `74` 项扩展到 `143` 项并通过，新增菜单、取餐窗、餐盘车、剧院道具箱、启真湖钥匙的双路径保存前事实等价校验，以及观察事实不由实体操作合成、触屏入口和旧文案静态合同。
- Fresh 验证：`npm run typecheck`、`npm run verify:canteen-bike-transition`（`40/40`）、`npm run theater:validate-spotlight`、`npm run qizhen:validate-fishing`、`npm run qizhen:validate-rain-safety`（`47` 项）和 `npm run verify:task-guidance` 均退出码 `0`。
- 当前边界：本轮只验证 controller 写入前的事实等价性；`SaveStore` 往返与旧存档归一化由主线程独立处理。本轮没有构建单文件、没有编辑 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 第四章保安追逐表现状态机

- 新增纯 `ChapterFourGuardPresentationModel`，只读取原 `ChapterFourGuardModel` 的 mode、可见性、进入追逐、脱离追逐、期望移动和朝向结果；它不写入位置、速度、碰撞、抓捕、终点、存档或剧情事实。
- 表现阶段覆盖巡查、发现、转身确认、追逐、短暂失去视野、最后目击点搜索、回到巡查和重新发现。发现、失视与重新发现使用有限时长提示；追逐入口的对讲机动作结束后回到方向行走帧。
- 维修保安朝向增加主轴切换滞后：低于 `8px/s` 的细小速度不改变朝向，近对角线速度保持上一主轴；确认、失视和搜索期间锁定最近一次清晰朝向，避免两个花坛间逐帧左右翻头。
- Scene 的位移仍原样使用 `next.desiredVelocity`，抓捕仍要求原 authority 处于 `pursuit` 且脚框接触；最终追逐继续使用独立原规则。本轮只替换普通维修巡查的动画、镜像、警示符号和视锥外观投影。
- Fresh 专项校验：`npm run chapter4:validate-guard-presentation` 通过 `40` 项断言；`npm run typecheck` 和定向 `git diff --check` 均退出码 `0`。本任务接入后 `chapter4:validate-runtime` 曾完整通过 `1225` 项；并行的现实模式解序改动随后落入共享工作树，最新复跑只剩 `4` 条旧任务顺序断言失败，错误均为电梯历史与 204 观察任务 selector 预期，没有 guard、路径、抓捕或保存断言失败，需主线程在合并解序 validator 后统一复跑。
- Chromium 网页游戏客户端在 `c4-755-maintenance-2245` 连续运行三轮。状态采样显示保安从西南巡查停留稳定进入北侧路线，动画按 `guard_check_list → guard_walk` 切换，侧向镜像保持与运动方向一致；三张画面均已目视检查，未生成 console/page error 文件。临时截图与状态文件在记录结论后删除。

## 2026-08-27 第四章六间教室有效只读交互

- 新增 `ChapterFourInteractionContent` 统一内容表，覆盖 A2 的 201 创客工坊、202 阶梯教室、203 计算机教室，以及 A3 的 301 校史档案展、302 媒体工作室、304 报告厅。六处内容均覆盖六个时间状态和深色/浅色两种模式，每组文本分别承担环境说明、状态反馈、支线信息或主题表达。
- 六个目标全部复用 `chapter4-three-floor-maze.layout.json` 的精确 source-pixel 房间锚点，作为 `collision=false` 的近距离 `Space` 交互；它们只在 `room204_restore` 投影，避开维修追逐、停电、最终追逐和最后一分钟阶段，不新增人物或主线事实。
- Controller 新增统一 `inspect_chapter_four_context` intent，命中后只返回 `acceptReadOnly()`；Scene 把六个目标纳入 actionable set，按当前投影阶段、时间状态和现实模式选择字幕。两种模式均可直接读取本模式信息，没有固定交互顺序。
- 新增 `npm run chapter4:validate-effective-interactions`。Fresh 结果通过 `284` 项断言，覆盖六间教室、六个时间状态、两种模式、精确坐标、楼层投影、距离拒绝、冲突阶段关闭、controller 零写入和无 progression gate；`npm run typecheck` 与定向 `git diff --check` 均通过。
- 最新 `chapter4:validate-runtime` 仍有 `4` 条失败，均为共享工作树中现实模式解序后保留的旧任务栏顺序断言：电梯历史两条、A3 参考教室一条、Room 204 残影一条。失败不涉及本轮六个目标、空间合同、intent 或状态零写入；主线程需统一更新该旧回归预期后再完整复跑。
- 本轮没有构建单文件、没有编辑 `demo/index.html`，没有执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-27 并行取证、阶段预热、现实模式解序与第四章交互整体验收

- 第三章半正式任务改为四类证据并行：照片、录音、消息和网络记录可按任意顺序完成，任务栏显示聚合进度与四行独立状态；四类证据收齐后进入旧时间排除与地点判断，删除正常流程中不会出现的独立“核对自动时间线”任务。旧存档继续通过 `SaveStore` 双向归一化恢复摘要与细分事实。
- 第四章静默加载最终收敛为 `entry → transport → maintenance → closure`。`entry` 只包含 A1 开场、主角、基础 HUD、前台和电梯基础资源；A2/A3、校友墙、学生、面包坊与 204 教室在 transport 前加载；保安、保洁、配电、停电和追逐进入 maintenance；最后一分钟与晨间资源进入 closure。必需阶段失败时保留上一张已提交投影并提供重试，空闲预热在受限网络或低内存环境按小批次降级。
- 全游戏现实模式合同写入 `AGENTS.md` 与共享交互规则：浅色操作和深色观察分别保留物理行为与信息读取语义，任何一方都不能仅因另一方事实尚未写入而关闭入口。食堂、剧院、启真湖和第四章代表链路均支持两种顺序；实体操作不自动伪造观察事实，最终结算仍检查真实完整条件。
- 剧院节目单补齐最后一个顺序锁：深色模式可在收集残页前读取舞台残影顺序，浅色模式也可先收齐残页再回读残影；两条路线都在浅色灯控台提交相同节目顺序并得到相同终态。第四章电梯历史读取与轨道校准可在 104/105 检查前按任意顺序完成，但前往高层的剧情路线仍由教室检查事实独立门控。
- 六间教室交互升级为生产场景与 validator 共用的纯流程。A2 的 201/202/203 和 A3 的 301/302/304 均执行 `light → dark` 与 `dark → light`，控制器结果必须为 `accepted=true / changed=false / inspect_chapter_four_context` 才能输出对应时态字幕；435 项断言同时检查只读性、拒绝路径、锚点内部样本与静态碰撞分离。六套时态文案中当前正式流程只开放 18:50，其余明确作为后续时态回访预留。
- 普通维修保安增加 `patrol_walk / notice / turn_confirm / pursue / short_sight_loss / last_seen_search / return_to_patrol / reacquire` 表现状态，低速抖动和近对角线速度不会逐帧翻转朝向。原 `ChapterFourGuardModel` 继续独占位移、视线、碰撞与抓捕权威；独立审查未发现 Critical 或 Important 问题，`returning / disengaged` 推进稳定，剩余风险为反复短时重新发现的视觉抖动覆盖。
- Fresh 自动验证全部通过：第三章半 `1944` 项、`48` 种完成顺序；现实模式 `180` 项；第四章预热 `70` 项；六教室 `435` 项；保安表现 `40` 项；第四章 runtime `1252` 项、story、Task 14 `365` 项、assets 与 topology `2769` 项；食堂 `40/40`、剧院三轮、启真湖钓鱼/雨天 `47` 项/日志、任务提示所有权、`typecheck`、`text:check` 和 `git diff --check` 均通过。
- `npm run build` 已生成普通 Vite 生产构建并通过，未运行 `build:single`，未编辑 `demo/index.html`。剧情文本重新导出为 `docs/game-text-by-chapter.md`，共 `6217` 条，其中第四章 `1269` 条。
- 证据边界：本轮没有执行真实浏览器中的六教室靠近后 `Space` 闭环，也没有完成 Safari/移动端的内存峰值和阶段切换停顿 profile；纯流程、资源阶段、控制器与构建验证已通过，不能替代这两项真实运行证据。按既有决定，不执行第四章三层碰撞与遮挡浏览器专项校验。
- 交付边界：本轮未执行 Git fetch、stage、commit、merge、rebase、push、reset 或上传，也未生成新的单文件。

## 2026-08-27 `2a540e7` 第三章改动选择性语义合并

- 以 `2a540e7a7325b177c3685ea6ea74a284d5d15745` 为语义来源恢复后续提交覆盖掉的第三章改动；没有整文件 checkout 或 cherry-pick，保留当前版本的无朝向交互契约、第四章、启真湖与资源预热实现。
- 场馆对外名称按审阅意见统一为“剧场”：校园入口、食堂骑行终点建筑与路牌、CC98 委托正文和取票说明不再显示“求是大讲堂”。
- 剧场取票机在手机票务已送达时仍提交 kiosk 请求并打开 `0832` 输入面板；检票员与读票器视觉、互动点和投放框统一下移 `42px`，原碰撞矩形保持不变。后台道具箱恢复到 `(294,165) / 96×95 / proximity 72`，票据扫描器恢复 `proximity 72`。
- 节目单不再在场景中直接显示完整答案；深色观察只提示打开道具栏，三张残页详情分别显示荧光顺序 `1 / 2 / 3`。食堂转场提示同步改为“节目单简介里的荧光编号”。
- 食堂 DEV 的守出口检查点恢复为开始/中段/末段，瞬态运行时分别从 `0 / 30000 / 50000ms` 起跑；中段和末段不再预填出口识别与命中数。点餐检查点重新播放队伍退让交接，自行车检查点说明补全深色读码、擦锁和支付 2 元。
- 按用户明确范围保持六项现状：最近目标判定、食堂入场、食堂点餐机、食堂 NPC 范围、道具重叠决胜、剧院出口。对应当前值仍为入场半径 `360`、点餐机模型 `(790,218)` / 站位 `(790,260)`、坐席 NPC `72×88 / proximity 54`、剧院出口模型 `(836,842) / proximity 90` 与热点 `156×92`；共享最近目标和道具重叠排序未改。
- Fresh 校验：`npm run typecheck`、`npm run verify:rpg-facing-agnostic`、`npm run verify:developer-levels`、`npm run verify:task-guidance`、`npm run verify:canteen-bike-transition`、17 项选择性语义断言、`npm run build:single` 与 `npm run verify:single` 均通过。单文件首次构建触及 Node 默认约 `2.5GB` 堆上限，使用临时 `--max-old-space-size=6144` 重跑后成功，产物为 `252298403 bytes`、两个内联脚本和一个内联样式。
- Chromium `1280×720` 直接打开 `file:///D:/Code/7-55/demo/index.html` 完成 21 项真实运行断言：已送达票务状态可靠近取票机并打开 code panel，检票 target `y=732`；三张节目单详情依次显示 `顺序：1/2/3`；后台道具箱与扫描器坐标/距离生效；守出口中段和末段起点为 `30000/50000ms`，末段首次采样剩余 `9925ms`；console/page error 为 `0`。
- 当前边界：未执行 stage、commit、merge、rebase、push、reset 或上传，也未处理 stash 和既有未跟踪 Godot/启真湖素材。临时 Chromium 进程已结束，临时浏览器资料已移入回收站，QA 脚本已删除。

## 2026-08-27 启真湖返回手机后的地图、DEV 与云层校准断链修复

- 根因是桌面双栏把手机焦点与持久运行模式混用了：点击“聚焦手机”只把 `activeSurface` 切到 `phone`，为保留 Phaser 地图，`runtimeMode` 会继续保持 `rpg`。因此“前往大地图上的启真湖入口”和 DEV 节点虽然已经正确写入 `campus_qizhen_loop / campus_qizhen_gate`，可见焦点仍留在手机；天气 controller 又把 `runtimeMode === "phone"` 误当成天气页可操作条件，导致云层按钮可见但返回 `inactive`。
- App 现在监听 `qizhen_campus_approach_entered`、`qizhen_lake_entered` 与 `qizhen_rpg_resumed`，显式进入或恢复启真湖地图时同步聚焦 RPG；DeveloperChannel 在应用节点或恢复备份后按节点最终 `runtimeMode` 同步目标画面，所以同一地图场景内的 DEV 跳转也不会再被手机焦点遮住。
- 校园地图恢复边界改为 controller 权威：只确认“启真湖”但尚未点击“前往大地图上的启真湖入口”时，仍打开首次入口页；一旦保存点到达 `campus_qizhen_gate`，或已经进入 `qizhen_lake`，之后从手机点击“校园地图”会直接恢复原 `rpgScene / rpgCheckpoint`，不重置湖区阶段、载具、出生点或道具链。
- 云层校准的页面权威改为 `currentScene === "weather"`。装备齐全、阶段为 `boarding_tutorial`、已向安全员提交天气请求且尚未放行仍是正式前置条件；桌面双栏即使保持 `runtimeMode=rpg`，聚焦后的天气页也可开始并提交校准。雨天专项验证改为直接覆盖这个双栏状态。
- Chromium `1280×720` Vite 实测首次解锁但保存点仍为 `campus_qizhen_transition_stop` 时继续显示入口页；点击入口后从“聚焦手机 → 浙大钉 → 校园地图”直接恢复 `campus_qizhen_loop / campus_qizhen_gate`；湖内同一路径恢复 `qizhen_lake / qizhen_open_water`，前后湖区事实逐字段不变。云层校准仍可从 0 次正常开始，六次右移显示 `3/3 · 6 步`，提交后为“多云”、最佳 `6` 步；DEV“启真湖入口”同样切回 RPG，console/page error 为 `0`。
- 生成后的 `demo/index.html` 直接 `file://` 打开再次覆盖真实手机导航；`c3-qizhen-gate` 与 `c3-qizhen-open-water` 都从浙大钉“校园地图”直接恢复原检查点，没有重开地点检索页，Phaser canvas 始终为 `1`，console/page error 为 `0`。此前的地图入口、`runtimeMode=rpg + activeSurface=phone` 天气校准启动和 DEV 跳转也继续通过。
- Fresh 校验通过：`npm run typecheck`、`npm run qizhen:validate-rain-safety`（28 项）、`npm run qizhen:validate-fishing`、`npm run qizhen:validate-journal`、`npm run verify:developer-levels`（509 项）、`npm run verify:task-guidance`、`npm run verify:rpg-facing-agnostic`、`npm run build:single`、`npm run verify:single` 与 `git diff --check`。单文件为 `252299207 bytes`、两个内联脚本和一个内联样式。
- 当前边界：本轮未执行 fetch、stage、commit、merge、rebase、push、reset 或上传；按用户要求未处理 stash，也未碰既有未跟踪 Godot/启真湖素材。临时 Vite、Chromium 与 QA 脚本均已清理。

## 2026-08-27 合作者版本比较、语义合并与 main 交付验证

- 上传前执行 `git fetch origin main --prune`。本地基线为 `07d1472`，本地待交付范围为 `72` 个已修改跟踪文件和 `21` 个未跟踪文件；合作者在远端新增 `3e9eff4 fix(game): restore chapter 3 changes and Qizhen navigation`，共 `19` 个文件、`272` 行新增和 `65` 行删除。
- 双方共有 `12` 个重叠文件。临时索引模拟合并确认 `8` 个文件可以自动合并，`4` 个文件需要语义决策：`progress.md`、启真湖雨天验证器、剧场内容表与剧场场景。实际合并提交为 `557246c`，没有强制推送、整文件覆盖或丢弃合作者提交。
- 冲突处理保留双方进度记录；启真湖雨天验证同时覆盖地图恢复与 `64 + 36` 条雨线、雾层、地面反光和水花；场馆名称统一为“剧场”；节目顺序不在场景直接显示，改由三张节目单详情中的荧光编号给出；深色观察和浅色收集继续允许任意顺序；后台残影仍以 `propGhostRead` 作为是否已读的事实。
- Fresh 自动验证通过：`typecheck`；第三章半 `1944` 项；现实模式 `180` 项；第四章 runtime `1252` 项、story、Task 14 `365` 项、topology `2769` 项、预热 `70` 项、六教室 `435` 项、保安表现 `40` 项；启真湖雨天 `50` 项、钓鱼和日志；开发检查点 `509` 项；无朝向合同、任务提示、食堂骑行 `40/40` 与剧场追光三轮。`git diff --check` 通过。
- 合并后文本重新导出并通过 `text:check`：总计 `6219` 条，第一章 `401`、第二章 `406`、第三章 `1096`、3.5 章 `278`、第四章 `1269`、结局 `87`、跨章节系统 `2682`。
- `NODE_OPTIONS=--max-old-space-size=6144 npm run build:single` 与 `npm run verify:single` 通过。离线产物为 `demo/index.html`，`252403148` 字节、`2` 个内联脚本和 `1` 个内联样式。
- Chromium 离线单文件在 `1280×720` 实际打开剧场节目单、启真湖入口与第四章 18:50 三个 DEV 检查点；前两处 canvas 画面正常，第四章 gameplay client 的 canvas 单独截图只得到 WebGL 黑底，但整页截图确认 A1 大厅、前台 NPC、玩家、任务栏和道具栏均正常。三个状态快照均与画面一致，没有生成 console/page error 文件。
- Chromium `390×844` 验证开发面板可完整滚动；`?dev=0` 显示稳定的 7:55 启动页和固定手机外框。Playwright 当前未安装 Firefox 与 WebKit 可执行文件，因此本轮没有新增 Gecko/WebKit 实机证据；已有静态兼容合同和自动门禁不能替代该项。
- 临时 QA 截图、状态快照与空的 Firefox/WebKit 临时目录在记录结论后删除。推送和远端 CI 结果由本节后续交付记录补充。
- `git push origin HEAD:main` 非强制推送成功；本地 HEAD、`origin/main` 与 `git ls-remote` 三方均确认 `7f1f5e5a9ff0fb7d1cb904d13f96604298ec01c5`。GitHub Web CI [33086839856](https://github.com/zhu607705-coder/7-55/actions/runs/33086839856) 完整通过。
- Release `demo-20260827` 的四个附件已由本次产物覆盖：HTML `252403148` 字节、SHA-256 `1b6d6909cc22507614e37b65629c8eb2cd1f640ab00a4b54ef51171275ba38ec`；实现 ZIP `551053650` 字节、SHA-256 `bb263c0b674e5fe5e126988bae21e6997cdc3139e20c4b93741871d087698bff`。ZIP 来自 `7f1f5e5` 的全部 Git 跟踪内容并通过 `unzip -t`；远端 SHA 文件下载回读一致。标签保留原始日更节点，Release 说明明确附件对应合并后的 `main` 提交。

## 2026-08-28 四项低决策解密重构

- 第三章半网络页改为默认显示四条接入记录，时间、会话与区域筛选可任意组合；四条候选记录均可保存或替换。候选在保存时不判正误，地点确认阶段由新增 `ChapterThreeEvidenceMatrixModel` 统一核对网络记录与最终地点；错误候选会形成矩阵冲突且不写入完成态。旧存档继续把已读网络记录迁移到规范候选 ID。
- 启真湖连续唯一道具链收束为柜门、浮排和天鹅三个独立分支。三条分支可按 `3!` 六种顺序完成，分别取得尼龙绳、破损网框和天鹅磁铁；四件材料只在最终组装时一次消费并进入捕纸阶段。开盒、饲料和小鱼等中间状态由天鹅分支短流程统一完成，不再逐件形成唯一投放步骤。
- 第四章维修链改为三现象故障诊断。玩家根据轮罩先响、旧钟同齿位回弹和干涸油圈，分别判断卡扣、齿轮偏位与缺油；错误组合零写入，正确组合才发放短撬棍与润滑油。随后保留撬开轮罩和一次联动润滑两个实体动作，一次润滑同时恢复车轮与旧钟齿轮。任务栏进度同步收敛为 `0/3 → 3/3`。
- 三楼导视板删除“中间空位”答案提示。界面仅给当前照片、旧残影和二楼入口方向三份材料；初始碎片与空槽位置不再等于正确答案，玩家需要自行判断箭头端、字样端和缺失槽位。
- Fresh 自动验证通过：第三章半 `1957` 项、`48` 种完成顺序；启真湖三分支 `6` 种排列、`114` 项；启真湖四张钓鱼谱面；第四章 story、runtime `1091` 项、topology `2769` 项；`typecheck`、`text:check`、普通 `npm run build` 与 `git diff --check` 均通过。文本导出更新为 `6272` 条。
- Chromium `1280×720` 实测网络页可无筛选直接保存错误候选，并可从区域、设备等任意维度开始组合筛选；错误候选进入证据矩阵等待统一核验。维修诊断实测错误答案显示矛盾且撬棍/润滑油保持未取得，正确答案后任务栏进入 `1/3` 并同时取得两件工具；console error 为 `0`。临时 Playwright 快照、console 日志和截图已删除。
- 当前边界：按本轮要求只修改上述四项及其测试、文本导出和进度记录；未生成新的离线单文件，未编辑 `demo/index.html`。提交前已执行 `git fetch origin main --prune` 与三视图审计：工作树仅含本节 `30` 个范围内文件，本地相对远端新增提交 `0` 个，远端相对本地新增提交 `0` 个，双方基线均为 `c174eaa`；最终远端结果以本次 Git 历史为准。

## 2026-08-28 第四章五区配电拓扑重排

- 配电谜题取消旧版固定列表排列。大厅、西走廊、东走廊、面包坊后场和教室区改为与教学楼空间关系一致的五节点拓扑，面板用五条可见线路表达联动关系；方向键按画面中的最近节点移动焦点。
- 开局供电状态从 `mask=6` 改为 `mask=14`，目标仍为通往大厅、东走廊和教室区的 `mask=13`。唯一解改为大厅、西走廊、东走廊、面包坊后场四个节点，实际状态序列为 `14 → 9 → 26 → 23 → 13`，不再复用旧版三步解。
- 存档版本提升至 `29`。版本 `28` 及更早、尚停留在旧配电开局 `mask=6` 的存档会迁移到新开局 `mask=14`；已锁定的完成态保持 `mask=13`，合法的中途尝试继续保留。
- Chapter 4 story、runtime `1095` 项、topology `2769` 项、阶段预热 `70` 项、开发检查点 `509` 项、`typecheck`、普通 `npm run build`、文本导出/核对和 `git diff --check` 均通过。文本总数保持 `6272` 条。
- Chromium `1280×720` 从 `c4-755-blackout-0754` 实际移动到一楼配电面板并用 `Space` 打开；验证 `mask=14`、五个空间槽位、五条连线、方向键焦点序列和完整四步解。成功后自动锁定 `mask=13`、关闭面板并进入 `final_chase`，console/page error 为 `0`。
- 当前边界：本轮未运行 `build:single`，未编辑 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。临时浏览器截图与状态证据在结论记录后删除。

## 2026-08-28 启真湖雨天落水、寝室吹风机与风向校准闭环

- 新增透明像素吹风机正式素材 `src/assets/rpg/props/items/hair_dryer_generated_v01.png`。素材为 `128×128 RGBA`，保留完整机身、把手、电线和插头；寝室场景以 nearest filtering 显示在林星宇自己的书桌，不把道具烘焙进寝室底图。
- 雨天小码头流程改为两次明确交互：第一次上船由值班老师劝阻并只显示“现在天气不能下水”；玩家再次尝试时触发强行下水、落水、救援和回寝室演出。落水只增加本次启真湖倾覆次数，不消耗剧情物品。
- 回寝室后，吹风机作为独立近距离 `Space` 目标出现。拾取成功立即从桌面消失，写入 controller-owned `hairDryer` 道具事实，并把共享任务切到天气页；未拾取时离开寝室会得到本地纠正提示。
- 天气页复用同一张透明素材，改为六步风向校准：玩家用吹风机分别移动低、中、高三层云带，三层进入目标槽后才能送出最后一阵风。成功后消耗吹风机、停止降雨并恢复小码头上船阶段；页面文案不提前显示“改成多云”的答案。
- 存档版本提升到 `30`。旧版待处理天气存档归一化为 `rain_recovery`，补齐救援、天气请求和吹风机事实，避免旧玩家卡在已经离开湖区但没有道具的状态；完成放行的存档不会重新获得吹风机。
- Fresh 自动验证通过：`npm run qizhen:validate-rain-safety` 共 `67` 项，覆盖首次劝阻、第二次强行下水、救援、寝室拾取、六步校准、道具消耗、存档往返和 v29 迁移；`npm run typecheck` 与普通 `npm run build` 均通过。
- Chromium `1280×720` 实测吹风机在书桌上比例与透明边缘正常；人物到达桌边后用 `Space` 拾取，道具从场景目标和画面同步移除，任务切换到天气页。天气起始页与校准面板均在共享手机视口内完整显示，三轮状态采样均未生成 console/page error。
- 当前边界：本轮未运行 `build:single`，未编辑 `demo/index.html`，未执行 Git 暂存、提交、合并、推送或上传。浏览器临时截图与错误状态文件在记录结论后删除。

## 2026-08-28 启真湖四次节奏钓取分层

- 保留原两阶段钓取事务、按键判断、长按、节拍、失败回滚与四个剧情目标，只重排四次主线钓取的长度和强度。钥匙为 `10s / 8` 次输入的完整教学谱；破损网框为 `7.5s / 4` 次输入的短谱并保留一次长按；小鲤鱼为 `5s / 1` 次提竿判定；最终纸条保留 `20s / 26` 次输入、两次长按和错拍节点。
- 谱面数据新增 `experience` 与 `instruction` 元数据，模型和画面直接读取同一份档位说明。运行时按 `tutorial_full / quick_hold / quick_strike / finale_full` 输出不同本地操作提示；小鲤鱼不再复用长谱。
- 音频时间线修正为钓取开始播放正式 `music_qizhen_fishing` 与低音量湖面环境层。普通钥匙、网框和小鲤鱼完成后恢复湖畔音乐；最终纸条开始时提高节奏音乐强度并加入低频提示，完成后只播放纸条脱离声，直接保留追逐前的紧张状态。
- 补齐实际入口：大湖新增“鱼群聚拢的水纹”浅色目标，持有鱼饲料时可以启动小鲤鱼的一次判定；网框 DEV 检查点改为河道母图、`qizhen_channel` 检查点和 `channel_entry` 安全出生点。专项 validator 同时锁定这两个入口，避免谱面存在但场景不可触发。
- Fresh 自动验证通过：`npm run qizhen:validate-fishing`、`npm run qizhen:validate-tool-branches`（六种分支排列、`114` 项）、`npm run typecheck`、第三章音频合同、`npm run text:check` 和普通 `npm run build`。文本重新导出为 `6305` 条，其中第三章 `1105` 条。
- Chromium `1280×720` 使用正式网页游戏客户端进入四个 DEV 检查点：钥匙、网框、小鲤鱼和纸条均建立 `audio_context` 节奏会话，分别显示 `8 / 4 / 1 / 26` 个判定；三档缩短与最终高难画面均已目视检查，无 console/page error。小鲤鱼零输入失败后，`fishFeedPellets` 保留、`fishCaught=false`、失败次数从 `0` 增到 `1`，证明失败没有消费剧情道具。
- 当前边界：本轮未运行 `build:single`，未编辑 `demo/index.html`，未执行 Git fetch、暂存、提交、合并、推送或上传。临时浏览器截图与状态文件在记录结论后删除。

## 2026-08-28 常规横屏室内门动画、通行与遮挡统一

- 新增共享 `RpgInteriorDoorRuntime`，统一管理关门、开门、开启中、关闭中、通行延迟、静态阻挡、门扇动画和同源前景遮挡。门扇支持单扇平移、双扇平移、单扇转开和双扇转开；场景只提供门洞尺寸、运动类型、阻挡线和同源前景裁片。
- 寝室正中下方出口改为单扇侧滑门；关门时阻挡人物，开门达到可通行进度后解除阻挡，人物穿过门框时由原场景裁片遮挡。图书馆保留原有玻璃门滑动表现，并接入同一前景遮挡和运行时调试合同。
- 食堂东南实体出口与剧场正中下方出口改为双扇侧滑门。食堂删除悬浮“出门”按钮，只保留靠近实体门后 `Space` 离开；原食堂东南整段墙体碰撞拆除门洞覆盖，仅保留东侧实体墙，西侧门框改为可从后方经过的前景遮挡区。
- 四个场景都发布 `interiorDoor` 调试快照，包含门 ID、状态、动画进度、是否通行和人物是否处于遮挡区。第四章电梯、202 教室门和食堂守出口的三处剧情门逻辑保持原实现，未被共享常规门替换。
- 新增 `npm run verify:rpg-interior-doors`，Fresh 通过 `28` 项断言；`npm run typecheck`、普通 `npm run build` 与定向 `git diff --check` 均通过。Vite 仅保留既有大 chunk 警告。
- Chromium `1280×720` 已目视检查寝室、图书馆、食堂和剧场四个关门状态；寝室验证单扇开启、通行延迟和人物过门遮挡，食堂与剧场验证双扇开启与解除阻挡。食堂开门后正常返回校园；目标浏览器运行没有 console/page error。
- 当前边界：本轮没有运行 `build:single`，没有编辑 `demo/index.html`，没有执行 Git fetch、暂存、提交、合并、推送或上传。临时浏览器截图、状态快照与错误文件在记录结论后删除。

## 2026-08-28 GitHub main 交付前单文件与导航复核

- 按用户确认的完整范围 A 执行交付准备，继续使用既有 `selected-phaser-ui-20260721` 工作区，没有创建新的工作区。`git fetch origin main --prune` 后，本地 `HEAD`、`origin/main` 与共同基线均为 `ac30d197670c43780947b3410588be2e7137361a`；本地新增提交和远端待合并提交均为 `0`。
- 上传候选范围为 `41` 个已跟踪修改与 `3` 个未跟踪项，覆盖启真湖雨天救援、吹风机与云层校准、四次节奏钓取分层、第四章配电/时间迷宫修正、常规室内门机制、存档迁移、验证脚本、文本导出和项目记录。Godot、Playwright 临时产物、`output/`、`dist/` 与被忽略的 `demo/index.html` 不进入提交范围。
- Fresh 自动验证通过：`npm run typecheck`、室内门 `28` 项、启真湖钓取、启真湖雨天 `67` 项、第四章 story、第四章 runtime `1095` 项、`git diff --check`、`npm run build:single` 与 `npm run verify:single`。离线产物为 `demo/index.html`，`252440046` 字节、两个内联脚本和一个内联样式。
- 本机 Chrome 以 `file://` 直接打开离线单文件，启动页、DEV 通道与固定手机外框正常渲染。Playwright 使用同一 `demo/index.html` 的本地 HTTP 预览完成“启动页 → 第一章开场 → DEV 第四章 RPG → 聚焦手机 → 天气页 → 云层校准”基础导航；云层校准正确显示透明吹风机和三层控制，console error 与 warning 均为 `0`。
- 本轮生成的 Playwright 快照、console 日志、Chrome 临时用户目录与单文件截图已移入回收站。当前记录仍处于提交前状态；最终 commit、push、GitHub CI 与远端 `main` SHA 以本节后续远端证据为准。

## 2026-08-28 启真湖雨天强行下水翻船动画延长

- 原实现只把步行角色平移到水面后旋转淡出，约 `3.15s` 内结束，没有真正显示皮划艇或划桨动作。现改为分段演出：人物走向码头、皮划艇推出、六次左右交替划桨、速度与倾角逐步变化、侧风把船身压偏、船体侧翻入水、岸边获救、返回寝室。
- 新增纯演出配置 `QizhenRainRescuePresentation.ts`，正常版本为六桨、约 `7.25s`；减少动态效果版本抽取三桨、约 `2.26s`。路线全部位于码头母图水域，演出坐标、速度和倾角不进入正式存档。
- 复用正式皮划艇双帧、坐姿主角、左右桨水花和尾流。强制翻船增加船体 `82°` 侧倾、缩放、淡出、八层扩散水环、镜头轻震与闪光；救援后人物在值班老师旁重新出现。演出开始时清除旧上船提示，调试状态同步 `rainRescueStage`、六次桨序、船速、倾角和翻船状态。
- 控制器结算保持原合同：演出完成后只发送一次 `rpg_qizhen_rain_rescue_completed_requested`，倾覆次数从 `0` 增到 `1`，阶段进入 `rain_recovery`，保存点回到 `dorm_spawn`，并开启寝室吹风机与后续天气处理任务。
- Fresh 验证通过：`npm run typecheck`、启真湖雨天安全 `69` 项、`git diff --check`、文本导出与核对（总计 `6304` 条）、`npm run build:single` 和 `npm run verify:single`。离线单文件为 `252443985` 字节、两个内联脚本和一个内联样式。
- Chromium `1280×720` 使用 `develop-web-game` 标准客户端从 `c3-qizhen-rain-hold` 完整执行劝阻、再次登船、六桨划行、翻船、救援和寝室落点；中段画面确认皮划艇、桨帧与尾流可见，翻船画面确认船体侧倾与水花可见，最终状态确认 `rainRescueCompleted=true`、`capsizeCount=1`、`weatherAdjustmentRequested=true`，console/page error 为 `0`。
- 交付边界：本轮仅在现有工作区修改动画、文本、专项验证和进度记录；已生成本地 `demo/index.html` 做离线门禁，没有执行 Git 暂存、提交、合并、推送或上传。临时浏览器截图与状态文件在目视检查后删除。

## 2026-08-28 启真湖持续风力三轨天气校准

- 天气调整从离散点按改为三条 `0–100` 连续轨道。西南风始终向左施加位移，低、中、高三层分别使用 `Z/C`、`A/D`、`Q/E` 后退与前进；三组键可同时按住，触控端提供同语义的六个按住按钮。
- 三层目标中心分别为 `34 / 52 / 70`，容差为 `±8`。玩家必须实际操作过每一层，并让三层同时进入目标区持续 `1000ms`；任意一层被风推出目标区时稳定进度立即清零。只有 controller 校验通过后才消耗吹风机、停止降雨并恢复上船阶段。
- 天气页增加持续风向条、轨道内风向反馈、虚线目标区、云带连续位置、按键激活态、三层操作事实和同步稳定进度。校准期间收拢天气信息区，保持 `430×860` 手机外框不变；运行时快照向 `render_game_to_text()` 发布三层位置、输入方向、稳定时间、操作次数和对齐数量。
- `npm run qizhen:validate-rain-safety` 通过 `69` 项断言，覆盖持续风、三层独立控制、最少三次有效输入、完整 `1s` 稳定、缺失操作拒绝、吹风机消耗、保存恢复和雨天救援闭环。`npm run typecheck`、文本导出/核对、`git diff --check` 均通过；文本总数更新为 `6309` 条，其中第三章 `1121` 条。
- Chromium、Firefox 与 WebKit 在 `1280×720` 均确认无输入时高层云带持续左移，按 `E` 后能够逆风右移。Chromium `390×844` 触控端确认六个按钮实际命中区约为 `31.28×29.64px`，页面文档宽高无溢出，按住与松开均进入同一输入路径。标准网页游戏客户端与补充六键脚本完成正式成功闭环，console/page error 为 `0`。
- `NODE_OPTIONS=--max-old-space-size=6144 npm run build:single` 与 `npm run verify:single` 通过；离线 `demo/index.html` 为 `252450614` 字节、两个内联脚本和一个内联样式。离线 `file://` 再次完成六键控制与天气更新，最佳校正次数为 `5`，最终 `rainSafetyCleared=true`、`phase=boarding_tutorial`、吹风机已消耗。
- 交付边界：本轮继续使用既有 `selected-phaser-ui-20260721` 工作区，没有创建新工作区，也没有执行 Git fetch、暂存、提交、合并、推送或上传。临时浏览器截图、状态文件和 QA 脚本在记录结论后删除。

## 2026-08-28 CC98《7:55》学生剧海报与演出档案

- 使用内置 `imagegen` 按“空剧场、七点五十五分时钟、深蓝幕布、聚光灯下节目单与票根、红色观众席、竖版像素海报”的提示生成正式原画；缩放为 `512×768` 后保存至 `src/assets/ui/cc98/theater_755_student_play_poster_v01.png`。缩小到约 `99×148px` 的手机显示尺寸时，标题、时钟、聚光灯和票根仍可辨认。
- CC98 帮抢帖楼主正文改为真实剧社退票说明，不再提前公布校园网失败、第二波流量要求与 `0832` 取票答案。原抢票 controller、两波回执、可选大厅记录和存档事实保持不变。
- 帖内新增可展开的演出档案：默认显示正式海报、原创作品标识、剧名、核心句、演出时间、入场时间和地点；展开后补充剧情简介、四项演出信息、制作分工和三条现场须知。档案只承担世界观与现场信息，不写入任何章节进度。
- Fresh 自动验证通过：`git diff --check`、`npm run typecheck`、文本导出/核对、`npm run build:single` 与 `npm run verify:single`。文本总计更新为 `6340` 条；离线 `demo/index.html` 为 `253134358` 字节、两个内联脚本和一个内联样式。
- Chromium 在 Vite `842×837`、移动视口 `390×844` 和单文件本地 HTTP 预览中完成帖子打开、档案展开、向下滚动和帮抢接单。海报内嵌自然尺寸为 `512×768`，四个详情区完整渲染，手机与文档均无横向溢出，展开后票务按钮仍可见且可点击，console/page error 为 `0`。
- 交付边界：本轮继续使用现有工作区，没有执行 Git fetch、暂存、提交、合并、推送或上传。浏览器验证截图仅用于本轮目视检查，结论记录后删除。

## 2026-08-28 启真湖雨天强行下水提示与 MiniMax 救援回放

- 首次向湖边值班老师确认时，反馈改为“现在天气不能下水。你要坚持，可以继续靠近码头试试。”，只提示仍可继续靠近码头，不直接说明强行下水、翻船或天气调整答案。雨天救援完成但尚未调整天气时，再次从湖畔入口申请进入会保持在原场景，并显示“这么不长记性，还想要再成一次落汤鸡不成。”。
- 使用 MiniMax Hailuo 2.3 只提交一次雨天救援视频生成：`task_id=435712012501280`、`file_id=435718259605889`。正式素材为 `qizhen_rain_rescue_hailuo23_v01.mp4`，`1364×768`、`24fps`、`5.875s`、无音轨、`2462885` 字节，SHA-256 为 `9232e480334a8e74eff8f0439151380ea62ca00ab7e44a66d04aaea6d4f66eb3`；同目录 manifest 记录生成提示、任务号、验收结论和运行时边界。
- 新增 React 救援回放层。Phaser 六桨翻船演出完成后，回放层覆盖同一 `960×540` 游戏壳并暂停人物、键盘、道具、任务栏和触控输入；视频结束或玩家跳过后才继续确定性救援结算。视频错误、超过 `9s` 未就绪、页面隐藏恢复失败或“减少动态效果”模式都会回退到同一控制器结算，不写第二套章节状态。
- Fresh 自动验证通过：`npm run typecheck`、启真湖雨天安全 `70` 项、文本重新导出与 `npm run text:check`、`git diff --check`、`NODE_OPTIONS=--max-old-space-size=6144 npm run build:single` 和 `npm run verify:single`。文本总计 `6349` 条；离线单文件为 `256422151` 字节、两个内联脚本、一个内联样式和一个内嵌 MP4 数据源。
- Chromium `1280×720` 在 Vite 完整验证首次克制提示、强行登船、视频播放、回寝室和再次拦截；视频 `readyState=4`、`duration=5.875`，救援后 `rain_recovery / dorm_hub / capsizeCount=1`，console/page error 为 `0`。减少动态效果模式不挂载视频，仍完成同一救援结算。
- 生成后的单文件经本地 HTTP 使用真实方向键和空格键完成“走到值班老师 → 查看提示 → 走到登船点 → 强行登船 → 内嵌视频 → 跳过 → 回寝室”，视频源确认为 `data:video/mp4;base64` 且 `readyState=4`；`file://` 直接打开同一产物也确认 `qizhen_lake / boarding_tutorial`、一个 Phaser canvas 和零 console/page error。
- 交付边界：本轮继续使用既有工作区，没有执行 Git fetch、暂存、提交、合并、推送或上传；生成视频已纳入源码资产范围，临时锚点、逐帧审阅图和浏览器截图在记录结论后删除。

## 2026-08-29 黑天鹅追逐压力阶段与跨浏览器收口

- 雨天翻船后的 MiniMax 救援回放继续使用既有 React 覆盖层接入同一 `960×540` 游戏壳；视频结束、跳过、载入失败和超时仍汇入同一个 controller 结算，不把生成视频作为位置、碰撞、存档或剧情权威。
- 新增纯 `QizhenSwanChasePressureModel`。追逐表现分为放飞警示、持续追踪、冲刺预警、短距冲刺和恢复调整五段，并按起始段、河道中段、左岸近段调整节奏。模型只读取真实间距、流程进度和玩家纵向位置，不写抓捕、终点、尝试次数、存档或章节事实。
- 第一次冲刺预警提前到追逐 `2.7s`，锁定玩家当时所在航线并持续到原 `4s` 接触保护结束；黑天鹅在预警阶段不会提前冲刺。原规则保持：实际中心距 `≤104px` 且保护期结束才失败，同帧先结算左岸终点，近距速度始终低于皮划艇最大速度、远距速度始终高于最大速度。
- 追逐 HUD 独立显示当前阶段、危险等级、真实距离、河道段落和进度，并使用蓝、黄、红三档风险条；冲刺预警锁定航线，冲刺开始产生水环和轻微镜头反馈，进入左岸近段产生单次收尾提示。通用划桨状态栏只保留控制、行进方式和侧倾，避免重复显示距离。
- 新增 `npm run qizhen:validate-swan-chase` 并纳入 critical suite。专项 `86` 项断言覆盖五阶段循环、预警提前、保护期内禁止冲刺、航线锁定、三段速度边界、风险单调性、真实抓捕与同帧终点优先；全套 `10` 个 critical validator、`typecheck`、文本导出与核对均通过，文本总计更新为 `6360` 条。
- Chromium 标准网页游戏客户端实测：静止时 `3.69s / gap=122 / catchReady=false` 显示冲刺预警，继续忽略后在 `4.11s / gap=104` 被追上；保持划行时在左岸近段进入冲刺；`44` 次左右交替划桨完成 `1000` 距离，`capsizeCount=0`、`chaseAttempts=1`，随后回到既有手机收尾。
- Blink、Gecko、WebKit 共 `12` 个运行组合通过：每个引擎覆盖 `1280×720`、`1180×800`、`844×390` 触控横屏和 `390×844` 竖屏；键盘和触控划桨都推进真实追逐距离，所有 canvas 保持 `16:9`，页面无横纵溢出且 console/page error 为 `0`。
- `NODE_OPTIONS=--max-old-space-size=6144 npm run build:single` 与 `npm run verify:single` 通过；离线 `demo/index.html` 为 `256429273` 字节、两个内联脚本和一个内联样式。`file://` 直开后左右划桨将追逐推进至 `689`，压力阶段、真实间距与调试字段均可读，没有 console/page error。
- 交付边界：本轮继续使用既有 `selected-phaser-ui-20260721` 工作区，没有创建新工作区，也没有执行 Git fetch、暂存、提交、合并、推送或上传。临时浏览器截图与状态文件在结论记录后删除。

## 2026-08-29 黑天鹅与保安追逐音乐、配音和动态混音

- 黑天鹅追逐新增独立 `28s` 循环音乐床，开始与重试时恢复播放，失败和抵达左岸时停止；放飞警示、冲刺预警、短距冲刺和左岸近段只更新当前音乐的音量与速率，不重新起播。配音保持三句稀疏旁白：放飞后指向左岸、首次冲刺预警、接近左岸收尾，每句在一次尝试中最多播放一次。
- 保安追逐继续沿用第四章既有夜间追逐音乐 `music_ch4_prologue_night_pursuit`，避免出现第二套风格身份；`catch_up / tracking / close` 三档依据真实路径距离动态调整音量和速率。新增开始追逐、楼层切换和近距离三句保安配音，楼层句与近距句在一次追逐中各播放一次。
- 六条中文语音均由 MiniMax `speech-2.8-hd` 生成：黑天鹅段采用低音高旁白声线，保安段采用沉稳男声；生成清单记录模型、声线、文本哈希、配置哈希、文件 SHA-256、时长、采样率与声道。MiniMax Music 接口本次返回 HTTP `410`，黑天鹅音乐按生成脚本中的确定性 ffmpeg 兜底生成，清单明确保留该来源，不伪称为 MiniMax 音乐输出。
- `AudioDirector` 改为合并同名事件的音频节拍，使第四章原有追逐音乐与新增配音可以同时接入；语音播放期间将音乐临时压低到 `0.075`，结束后恢复对应压力档。离开启真湖、失败、重试、完成和关闭第四章时会取消排队音频并停止相应声道，避免跨场景残留。
- 新增 `npm run audio:pursuit` 与 `npm run audio:pursuit:verify`，专项验证通过 `112` 项断言，覆盖七个 MP3 的存在性、哈希、解码、时长、采样率、声道、MiniMax 声音来源、事件路由、一次性语音、动态混音、失败/完成收尾和第四章既有音乐保留；该验证已加入 critical suite，完整 `11` 个 critical validator 全部通过。
- Chromium `1280×720` 真实浏览器运行态确认：黑天鹅左岸近段同时处于 `music_qizhen_swan_chase` 播放、音乐压低至 `0.075`、`vo_pursuit_qizhen_swan_final` 播放；保安追逐进入 `close` 档后确认 `music_ch4_prologue_night_pursuit` 正在循环、开始配音和近距配音均能播放，近距音乐同样正确压低至 `0.075`。两条追逐均无 console error 或 warning。
- Fresh 自动验证通过：完整 critical suite、`npm run typecheck`、文本导出/核对、`git diff --check`、`NODE_OPTIONS=--max-old-space-size=6144 npm run build:single` 与 `npm run verify:single`。离线 `demo/index.html` 为 `257645257` 字节、两个内联脚本和一个内联样式；本轮没有执行 Git 暂存、提交、合并、推送或上传，浏览器临时截图和状态文件在记录结论后删除。

## 2026-08-29 第四章深浅模式视觉分层与解密锚点

- 第四章 `深色观察` 增加冷蓝压暗、边缘暗角、轻量扫描纹和青色圆环线索锚点；`浅色操作` 增加暖色轻覆层和金色菱形操作锚点。两种模式使用 `240ms` 交叉淡入，模式按钮同步采用各自色温和边框。
- 现有第四章投影目标全部接入同一解密锚点合同。当前模式目标完整显示，另一模式目标保留低亮提示；目标仍由原 room、phase、visibleWhen 和 controller 规则决定，视觉层不写章节状态。
- 氛围层深度为 `9800`，解密锚点为 `9850`，人物为 `9900`，共享 HUD 为 `10000`。人物全程保持在模式氛围和解密点上方，现有门、电梯、碰撞与前景关系没有改变。
- Chromium `1280×720` 对两个第四章 DEV 检查点各完成一次浅色/深色对照，共 `2` 个检查点、`4` 张运行画面。维修检查点确认金色操作点与青色观察点随模式互换 active/dormant，运行调试字段与画面一致，console/page error 为 `0`。
- Fresh 自动验证通过：`npm run chapter4:validate-runtime`（`1095` 项）、`npm run chapter4:validate-effective-interactions`（`435` 项）、`npm run verify:rpg-reality-mode-order`（`180` 项）、`npm run chapter4:validate-story`、`npm run typecheck` 和 `npm run build:single`。单文件构建为 `257649.89 kB`，gzip `189331.88 kB`。
- 当前浏览器上下文停在第三章检查点，没有包含用户所指第四章具体位置的标注。本轮先把所有现有第四章解密目标升级为可辨认锚点；如果需要在一个全新空白区域增加独立谜题，还需要 `A1/A2/A3 + 房间或物件`，或一张第四章标注图。本轮没有执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-29 第四章六处有机插入谜题与 image2 场景装配

- 第四章新增六处与现场陈设绑定的谜题：A1 前台值班牌顺序、A3 301 胶片索引、A3 302 新旧影像对齐、A2 201 定位板三轴校准、A2 203 五区拓扑恢复、A2 开放自习区疏散路线。六处均由原场景空白装置触发，没有替换 104／105、电梯、错位楼梯和 204 家具复原的既有主谜题。
- 使用 image2 生成并裁成真实透明底的六件正式素材，全部保存在 `src/assets/rpg/interiors/finale/chapter4-755/props/`。素材按源像素 `1:1`、nearest filtering 和各层世界坐标装配；深色模式统一施加荧光蓝色调，浅色模式保留原暖色与金色操作点，人物深度继续高于装置和模式氛围层。
- 调查节奏调整为：A1 三项校验可任意顺序完成；A3 两处装置都可先打开查看，302 的实体校准在取得 301 胶片后提交；错位楼梯完成后，A2 三处现场记录可任意顺序处理，三项齐全后任务栏再进入 204 完整复原。浅色操作可以先完成允许的实体谜题，深色观察提供线索，不存在统一的“必须先深后浅”硬顺序。
- 新增第四章 DEV 节点 `c4-755-a2-field-records`，直接落在 18:50 二楼交通核心并携带三楼与错位楼梯前置事实。开放自习区路线板保持原画面位置，交互距离单独校准为 `96px`，使人物可停在书架北侧打开装置，无需扩大书架空气墙或穿过家具。
- Chromium `1280×633` 通过真实键盘路线分别抵达六件装置。A1 验证浅色直接完成；A3 验证错误组合不重置、深色荧光蓝残影与未取得胶片时的可查看提示；A2 三处均完成真实走位、打开、调节与提交，最终事实同时包含 `a2_positioning_plate_calibrated`、`a2_power_topology_recovered`、`a2_evacuation_route_confirmed`，任务栏随后切换为 204 家具复原。
- 同一最终 `file://` 单文件在 Blink、Gecko、WebKit 的 `1280×720` 视口均显示一个 `1280×720` Phaser 画布、第四章任务和零页面溢出。Fresh Blink 与 WebKit 为 `0 exception / 0 error / 0 warning`；Gecko 为 `0 exception / 0 error`，只报告一次 headless WebGL 上下文恢复提示和一次无用户手势时的 AudioContext 自动播放拦截。Gecko 画布抽样 `144/144` 个像素均为非黑，临时截图目视确认场景、人物、HUD 与 A2 入口完整显示。
- 本轮没有创建测试文件或测试依赖。发布检查通过：`npm run typecheck`、`NODE_OPTIONS=--max-old-space-size=6144 npm run build:single`、`npm run verify:single` 和 `git diff --check`。离线 `demo/index.html` 为 `257773435` 字节、两个内联脚本和一个内联样式；`file://` 直开后进入 A2 检查点，Phaser canvas 为 `1`，预热素材 `20/20`，失败资源为 `0`。支持 NPC 的动画刷新改为在动画注册完成后补播，Fresh Chrome 单独载入最终单文件并等待 `15s` 后采集到 `0 exception / 0 error / 0 warning`。
- 交付边界：继续使用既有 `selected-phaser-ui-20260721` 工作区，没有创建新工作区，也没有执行 Git 暂存、提交、合并、推送或上传。浏览器临时截图与 Chrome 临时目录在本轮结论记录后删除。

## 2026-08-29 剧院正中出口按原门重绘与动态复原

- 删除剧院正中出口的灰蓝通用门表现。第二轮测量确认原门左右门轴相距约 `176px`、门页可见高度约 `70px`；先前 `116×118` 门页存在明显的窄高比例偏差。正式素材 `theater_center_exit_closed_v03.png` 直接提取 `theater_interior.png` 两扇开启门的木纹、描边和黄铜把手，按原门页四边形进行透视校正后重组为 `176×70` 的闭门状态。
- 内置 imagegen 生成的闭门场景只用于复核俯视构图、门轴范围和垂直压缩比例。运行时没有采用生成图中的墙面、门柱或灯具，正式门页保持底图原始像素色域、光照方向和纹理密度。
- 共享 `RpgInteriorDoorRuntime` 新增可选门页贴图、门洞/光照透明度、场景级缓动和 `double-fold` 双页透视收拢方式。剧院闭合时显示新门页；开启时两页沿外侧门轴收窄并淡出，随后完整露出底图中原有的两扇开启门，避免二维旋转产生大面积斜板。
- 剧院门继续复用原门框前景裁片和既有阻挡线。闭门时不可通行，达到通行进度后解除阻挡；人物进入门洞时门页位于人物上层，门页让出后恢复原底图通道。其他寝室、食堂和图书馆门没有传入新选项，保持现有表现。
- Vite 与最终 `file://` 单文件均在 `c3-theater-complete` 检查点验证闭合、开启中和通行状态。单文件开启中快照为 `progress=0.575 / passable=true / actorOccluded=false`，画面中门页已收窄、人物位于门洞、原开启门页逐步显露；浏览器 console/page error 为 `0`。
- 本轮没有新增测试文件或测试依赖。`npm run typecheck`、`git diff --check`、`npm run build:single` 与 `npm run verify:single` 通过；离线 `demo/index.html` 为 `257796896` 字节、两个内联脚本和一个内联样式，SHA-256 为 `726835a7bea96ff63a1d31266b8a7656239366eda09db43b7fa51336ed1a851f`。
- 被否决的 `v01` 亮金边门页和 `v02` 窄高门页均已移入 macOS 回收站，可恢复；本轮继续使用既有工作区，没有执行 Git 暂存、提交、合并、推送或上传。

## 2026-08-29 A 范围主分支上传与 CI 契约对齐

- 按用户确认的范围 A，将现有 `selected-phaser-ui-20260721` 工作区内第四章有机插入谜题、启真湖追逐与碰撞修正、剧场出口复原、CC98 世界观素材、音频、文本、控制器、存档迁移和既有验证脚本纳入同一次 `main` 交付；被忽略的 `demo/`、`dist/`、外部 ZIP/备份、Godot 与临时 QA 产物没有进入提交。
- 首次远端提交为 `8a46dd447ebe1e02c2a69571c9b0c707dd5c5be4`。本地 `HEAD`、`origin/main` 与 `git ls-remote origin refs/heads/main` 当时一致，工作树干净；GitHub Web CI `33245818634` 在第四章剧情契约步骤发现 7 项旧校验规则。
- 本地复现确认正式内容已扩展为 `36` 个活动任务与 `108` 条提示，QuestModel 已使用 A1、A3、A2 三组并行调查，Host 增加六处现场谜题与正式收束的唯一呈现权，SaveStore v32 只在完整收束证明、双项签到与锁定灯阵同时成立时恢复 `complete`。运行时实现与批准设计一致，失败来源为旧 validator 仍固定检查 `33 / 99`、旧事实顺序和旧握手集合。
- 只更新既有 `scripts/verify-chapter4-755-story.mjs`：精确锁定 `14` 项 204 阶段任务、`18` 项事实闭包、三组任意顺序调查、六处新增谜题、正式收束握手和 v32 防伪完成条件。没有创建测试文件或测试依赖；`npm run chapter4:validate-story` 已恢复通过，仍检查 `13` 个阶段、`6` 个时间状态、`5` 个配电区域与 `14` 个道具操作。
- 剧情契约修复提交 `d8ec7a455d75d39cbcaa59de6a21eb056301d8b6` 推送后，GitHub Web CI `33246172873` 已通过剧情、资产和拓扑步骤，并在运行时矩阵暴露第二处状态夹具过期及一项真实存档边界问题。运行时夹具现已补齐 A1 值班板、A3 档案链与 A2 三项现场记录的合法前置事实，原 `116` 项级联失败收敛为 `6` 项独立差异。
- SaveStore v32 的降级条件已收紧：只有原存档明确处于 `phase=complete` 时，缺少完整收束证明才降级至 `exterior_closure`；维修、返程或早晨阶段中伪造的 `completed/acknowledged` 字段不再把玩家提前送至外部收束页。合法的 v32 完整闭包仍可恢复 `complete`，外部收束页的伪造完成字段仍会被清除。
- Task 14 校验同步纳入正式的 `c4-755-a2-field-records` 检查点，并更新为 `36` 个活动任务、`108` 条渐进提示与 `14` 个第四章 DEV 节点。该节点仍由 `DeveloperChannel` 生成合法 `A2 / a2_corridor / room204_restore` 状态，不影响正式存档。
- 修正后 `npm run chapter4:validate-runtime` 通过 `1095` 项断言，`npm run chapter4:validate-story`、`npm run chapter4:validate-task14`（`375` 项）、`npm run chapter4:validate-topology`（`2781` 项）与 `npm run typecheck` 同步通过。远端最终提交与 GitHub CI 结果以本节后续交付证据为准。
