# 7:55 Web 客户端适配契约

## 支持基线

- 构建目标固定为 Chrome / Edge 90+、Firefox 91+、Safari / iOS Safari 15+。
- 运行时覆盖 Blink、Gecko、WebKit。浏览器识别只用于调试输出；功能分支必须使用能力检测。
- 单文件 `demo/index.html` 与 Vite 开发版使用同一套适配层，离线打开不得依赖外部脚本、字体或网络请求。

## 设备布局

| 设备与输入 | 手机界面 | RPG 界面 | 控制规则 |
| --- | --- | --- | --- |
| 桌面细指针，横屏宽度 `< 1100px` | `430 × 860` 逻辑框等比缩放并居中 | `960 × 540` 逻辑画布等比缩放并留黑边 | 键盘、鼠标；不渲染虚拟方向键 |
| 桌面细指针，横屏宽度 `≥ 1100px` 且支持 hover | 手机与 RPG 可进入共享桌面分栏 | RPG 保持 `16:9` | `any-pointer: fine` 与 `any-hover: hover` 同时满足才开放分栏 |
| Android / iOS 竖屏粗指针 | 手机框按可视视口与安全区等比缩放 | 画布置于顶部，任务、物品和触控区位于其下 | 虚拟方向键与空格键可见；快速点按方向键至少输出 `96ms` 方向脉冲 |
| Android / iOS 横屏粗指针 | 保持手机逻辑比例 | RPG 尽量填满可视区并保持 `16:9` | 触控区保留，安全区不得遮挡操作键 |
| 平板或二合一设备 | 按实际视口等比缩放 | 同时存在粗、细指针时保留触控键；满足桌面分栏条件时可分栏 | 使用 `any-pointer` 判断可用输入，不能只读取主指针 |
| 页面缩放、地址栏伸缩、软键盘出现 | 读取 `VisualViewport` 后更新尺寸变量 | 同步更新 RPG 壳层 | 页面缩放不得被手机框反向抵消 |

手机场景始终由 `PhoneShell` 持有 `430 × 860` 逻辑尺寸。RPG 始终由 `RpgGameHost` 持有 `960 × 540` 逻辑画布。任何设备适配都只能调整外层缩放、分区和安全区，不能改变这两个逻辑坐标系。

## 共享适配入口

- `src/core/ClientCompatibility.ts` 负责浏览器引擎、平台、输入类型、可视视口和能力快照。
- `src/components/useMediaQuery.ts` 负责 React 媒体查询订阅，并兼容旧 WebKit 的 `MediaQueryList.addListener`。
- `src/main.tsx` 在 React 首次渲染前安装适配层，并向根节点写入：
  - `data-browser-engine`
  - `data-client-platform`
  - `data-input-profile`
  - `--app-viewport-width`
  - `--app-viewport-height`
  - `--app-vw`
  - `--app-vh`
- `render_game_to_text()` 输出同一份能力快照，浏览器验收脚本据此核对实际分支。

新组件不得自行复制 UA 检测、`matchMedia` 订阅或视口变量维护逻辑。

## 能力降级表

| 能力 | 首选路径 | 降级路径 |
| --- | --- | --- |
| 动态视口 | `VisualViewport` + 共享 CSS 变量 | `window.innerWidth/innerHeight` 与 `100vh` |
| 屏幕旋转 | `orientationchange` + `VisualViewport.resize` | `window.resize` |
| 媒体查询监听 | `MediaQueryList.addEventListener("change")` | `addListener` / `removeListener` |
| 容器查询单位 | `cqw` / `cqh` | 共享视口变量与百分比尺寸 |
| 全屏 | 标准 Fullscreen API | `webkitRequestFullscreen`；iOS 无元素全屏时使用 CSS 可视区布局 |
| Web Audio | `AudioContext` | `webkitAudioContext`；两者均缺失时静音继续剧情 |
| `inert` | 原生 `inert` | `aria-hidden`、焦点移除、`.is-inert-fallback` 禁止指针输入 |
| 可序列化快照克隆 | `structuredClone` | JSON 深拷贝；只用于纯数据调试快照 |
| Pointer Capture | `setPointerCapture` / `releasePointerCapture` | `window` 级 `pointerup`、`pointercancel`、`blur`、`pagehide` 收口 |
| 安全区 | `env(safe-area-inset-*, 0px)` | `0px` |

## 输入契约

- 鼠标、触摸和手写笔统一走 Pointer Events；所有主流程仍需保留键盘等价操作。
- RPG 桌面移动使用 `WASD`，交互使用 `Space`。触控端使用四方向键与标为 `空格` 的交互键。
- 方向键长按持续移动，释放后停止。短于一个渲染帧的触控点按通过 `96ms` 最小脉冲保证可见位移。
- 亮度滑杆按 `pointerId` 追踪活动指针，Pointer Capture 不可用时仍可完成点按、拖动与释放。
- 混合输入设备只要存在粗指针就保留触控键；桌面分栏还需同时满足细指针、hover、横屏和宽度门槛。

## 浏览器验收矩阵

每次改动共享壳层、RPG、输入、音频、全屏或视口逻辑后，至少复验下列组合：

| 内核 | 桌面 | 移动 UA | 关键检查 |
| --- | --- | --- | --- |
| Blink | `1280 × 720`、`1280 × 800` | Android `390 × 844` | 手机比例、控制中心滑杆、RPG 键盘/触控移动 |
| Gecko | `1280 × 720`、`1280 × 800` | Android `390 × 844` | 同上，并允许画布高度出现亚像素舍入 |
| WebKit | `1280 × 720`、`1280 × 800` | iOS `390 × 844` | 同上，并验证无元素全屏时的 CSS 降级 |

通过条件：

- 文档横向和纵向溢出均为 `0`。
- 手机框比例严格为 `0.5`；RPG 画布比例保持 `16:9`，逻辑尺寸为 `960 × 540`。
- 细指针 RPG 不出现触控键；粗指针 RPG 出现 5 个触控按钮。
- 控制中心可用鼠标、触摸和方向键调整亮度。
- RPG 桌面 `D` 键与移动端右方向键均能改变玩家世界坐标。
- 页面错误和控制台错误为 `0`，画布包含非空像素采样。
- 共享网页游戏客户端完成一次实际点击，并检查 `render_game_to_text()`。
- `npm run typecheck`、`npm run build:single` 与最终 `file://` 冒烟均通过。

## 已知内核差异

- iOS WebKit 通常不提供任意元素 Fullscreen API。全屏按钮可以保持可见，但运行时会退回 CSS 可视区布局。
- Gecko 在 `390px` 宽度下可能把 `16:9` 画布高度计算为约 `219.383px`；这是亚像素舍入，画布仍保持允许误差内的 `16:9`。
- WebKit 对 `5016 × 5016` 校园底图的 Canvas2D 线性缩小结果会比 Blink、Gecko 更柔和；坐标、碰撞和非空像素保持一致。保持源图 `1:1` 与 `LINEAR` 纹理契约，避免为单一内核更换世界坐标或资源尺寸。
- Web Audio 可能因自动播放策略处于 suspended 状态。首次用户操作后恢复；音频失败不得阻塞剧情状态。
- `image-rendering` 同时声明 WebKit、Gecko 与标准路径。像素画面的空间尺寸不能依赖某一内核的锐化结果。

## 变更检查清单

1. 先确认改动是否触及共享壳层、视口、输入、全屏、音频或 Phaser 画布。
2. 优先扩展 `ClientCompatibility` 或 `useMediaQuery`，避免在场景内建立第二套判断。
3. 为新 CSS 能力提供基线浏览器可执行的前置声明，再使用 `@supports` 增强。
4. 运行三内核桌面/移动矩阵并记录交互结果。
5. 检查截图中的遮挡、触控目标、安全区、留黑和比例。
6. 删除临时截图与脚本，再更新 `progress.md`。
