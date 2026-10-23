# Godot 分支与版本整合

审计基准：2026-10-22 15:12 UTC，远端默认分支 `main`，提交 `32dfc73c113de980ca42b1c48a893d068e122127`。本次沿用 [PR #161](https://github.com/zhu607705-coder/7-55/pull/161) 作为单一审阅入口，不新建逐功能远端分支，不删除旧分支。

## 远端分支不是十份未合入功能

下表的“独有提交”是 `git rev-list main..HEAD`，不是把旧树与新树双点比较后误认出的逆向删除。

| 远端分支 | 审计 head | main 外独有提交 | 处理 |
|---|---|---:|---|
| `main` | `32dfc73` | 0 | 正式 Godot 目标 |
| `godot-version` | `8a0ede3` | 0 | #105 已外部合入 main |
| `codex/godot-complete-20261019` | `2d8e325` | 0 | #155 已合入 godot-version，再进入 main |
| `codex/campus-ui-system-20261021` | `3ee0eb5` | 0 | #156 已合入上述链，锁定 UI 保留 |
| `codex/dorm-modular-assets-20261021` | `60e996d` | 0 | #157 已合入，候选资产/场景保留 |
| `codex/kenney-visual-slice-20261022` | `aaa7dd7` | 0 | #158 已合入，独立示例保留 |
| `codex/motion-reference-polish-20261022` | `c88fcc7` | 0 | #159 已合入，B3 原角色动效保留 |
| `codex/mobile-touch-controls-20261022` | `77633d5` | 0 | #160 已外部合入 main |
| `codex/mobile-bottom-hint-20261022` | `5182cc7` | 1 | 保留底部提示改动，作为本次入口 |
| `codex/native-picker-drive-caption-20261022` | `98ed5e6` | 1 | 原提交以第二父提交吸收到本候选 |

`3ee0eb5`、`2d8e325`、`8a0ede3` 的 tree 均为 `61ce51900ead177043a6d666116c2b699a2778a6`。两个未合入提交的 7 个与 2 个文件互不重叠；其原始无冲突并集 tree 是 `7531f174c3ac94ee98b61d369e03e8c0ce2197c6`。**加上本次版本链改动后，不再是这个旧并集 tree。**

## 功能保留，而非旧目录覆盖新运行时

- Dorm 14、Kenney 6、Motion 7 个功能文件与各最终来源 head 同 blob。来源清单中的 415 个原始/适配 SHA、10 个原始快照匹配，34 项 PR 清单内 2749 个去重 required 路径均存在。这是静态来源核验，不是 2749 项运行测试。
- main 相比上述相同 Godot tree 仅有 #160 的 12 个修改、5 个新增、0 删除；运行代码修改仅 `main.gd`、`world.gd` 的已请求移动触控适配。没有把旧 React 整棵目录覆盖 Godot。
- 正式宿舍仍使用原锁定 plate、坐标适配器、背包与移动门禁。Dorm modular 和 Kenney 原本是独立场景/F6 候选，没有正式剧情入口；代码保留不代表自动选为正式宿舍。
- B3 保持独立预览路由及原角色帧、真实弹道与落地缓冲，不强塞正式剧情。原分支未提供独立 jump atlas，不能报成合并遗漏或新生成素材。
- 原锁定 UI 文档的 THEATER-1 仍是预留配置，所提梁祝扇影源不在现有仓库；宿舍 candidate 的 `sink_unverified` 等来源限制仍有效。本次不虚构缺失源、不扩到新的美术设计。
- 保留 `src/` 作为行为与源数据参考，继续源/原生差分验证；禁止恢复旧混合 iframe 运行时或建立第二套剧情状态权威。

## 实际版本链统一到 4.7.1

```text
官方 Godot 4.7.1 editor + 校验
  ├─ Native / cross-PR / mobile / 8 个独立 proof-example 工作流
  └─ 同版 web_nothreads_release.zip + 校验
       → 真实 HTML / WASM / PCK 导出
       → 精确音频兼容补丁 / 分包 / manifest / 来源与字节校验
       → 真实 Chromium 输入、持久化刷新与 HTTP 传输验收
```

- Native、cross-PR、mobile 原本已 4.7.1；另 8 个根目录可执行 proof/example 工作流原为 4.6.3，生产 Web 原为 4.7.2。所有实际运行 pin、同版模板路径、PCK/header/manifest 断言一起更新，非只改显示字符串。
- 8 个独立工作流是 `blender-stair-sample`、`qizhen-blender-nearshore`、`qizhen-large-world-example`、`qizhen-playable-example`、`ui-redesign-proof`、`dorm-modular-proof`、`kenney-visual-proof`、`motion-reference-proof`。修改配置不等于这些独立 proof 已全部重跑。
- Linux ZIP SHA-256：`c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba`；templates TPZ SHA-256：`86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`。Web 安装继续使用官方 SHA-512 双校验。
- 音频补丁继续拒绝未知引擎/输入、非单一匹配或输出摘要错误；不放宽为任意 4.x，也不把 4.7.2 模板混入 4.7.1。
- `project.godot` 的 `4.6` compatibility feature 不是可执行引擎 pin，保持不动。历史报告、旧导出及归档示例不全局改号。未选择或修改 Blender 版本。
- 初始下载上限仍为 **100,000,000 字节**，延后包上限仍为 **24,000,000 字节**。旧 4.7.2 载荷 `101,337,784` 的失败不能靠抬高预算或漏统计掩盖。

## 单一候选的验收与发布边界

1. 先在现有 #161 构造含两个原提交的候选并完成相关预检，再一次更新分支。最终 head、main base、PR merge-ref 及对应 tree 以该次不可变收据为准。
2. 对最终代码运行完整 Native（包括后续 GPU/PCK/replay）、cross-PR、18 张真实移动触控截图、27 张手机图标截图、保留 Web source/release，以及真正的 4.7.1 Godot Web export/browser。保留源码 fixture 构造与真实输入/渲染的区别。
3. `deploy-pages.yml` 的 PR 路径只有 build/accept 和证据上传。build 为 contents:read；PR 不配置 Pages、不上传 Pages 整包、不调用 deploy。原发布 job 才有 Pages/id-token 权限，PR 并发组独立。
4. 合入 main 会触发既有 Pages 发布链；不能把“PR 构建成功”说成“已经部署”。合并不能跳过保护或尚未完成的验收，不能用手动部署代替 PR 验证。
5. 当前验收不是物理手机测试，也不等于人工完整四章通关；Chromium 自动验收不代替 Gecko/WebKit 或可听音频人工检查。需要 earned fixtures 的深度场景若未执行，须明确记录为未测。

### 旧收据原样保留，不当作最终新 SHA 的绿灯

| 旧来源 | 已有事实 |
|---|---|
| #161 `5182cc7` | 真图 18 张/188 检查；Native 456/457，唯一 picker 基线失败，后续阶段 skipped |
| #162 `98ed5e6` | 4.7.1 Native 457/457 及后续 GPU/PCK/replay 全通过；Web 两次在 FFmpeg 安装期取消，不能称全 CI 绿 |
| 原始两提交并集 `7531f17` | 本地 focused 4031 检查/0 失败，不是完整 CI 或新 Web 渲染 |
| 旧本地 Web 诊断 | 35/38；单文件构建被 SIGKILL，两个依赖产物检查未能通过；一次受控重试仍被杀，原因未证实 |

最终运行链接、精确 SHA、真实图片和未达门槛统一记录在 #161；不通过改写历史报告制造新验收结果。

## 同一入口追加的用户授权修正

- **同类小图标恢复原 Web**：WiFi 独立两弧加点、7 个 launcher SVG、原浙大钉 PNG 和 CC98 字标。只恢复原图形/配色；不变网格、字号、按钮及语义。68 个 PixelMap 与 11 个物件 PNG 的源一致保护保留。详见 `PHONE_ICON_SOURCE_RESTORATION.md`。
- **电量与早期充电**：取消应用打开/切换的固定耗电，不删除网络耗电和低电模式。0%/1% 旧档都可从 C1 主页/盆栽经已有现实桌面上的实体充电座恢复；不是 C2 才有的地点。母图来自实际网页生成，原字节和来源说明保留；Godot 标准导入限 256px，实际物体按 144px 布局。2200ms 单次、owner 绑定、可取消充电只恢复电量/退出低电，不改手动亮度、植物条件或背包。关闭/失焦/换档/模态取消活动会话，重载桌面不重播起床，C2 不能误回 C1 桌面。
- **浙大体艺两阶段**：第一次切移动数据仍可取 7；第二章外出运动阶段同招无效，必须在游戏内公众号“浙大体育与艺术”→“联系我们”→模拟获取→明确安装，再真实运动、取得天气雨滴。旧客户端蓝底/下半屏空白仅是游戏内失败呈现，不请求真实权限、不让游戏进程崩溃、不嵌真实二维码/下载链接。C1 盆栽雨滴未改。
- **存档 36**：新增 `actOne.tiyiUpdateStage` 与有限的 `ui.homeDeskReturnScene`。仅已验证的 v35 导入走缺字段迁移；v36 缺字段/非法阶段拒绝。已有真实运动/雨滴事实可保留访问，单有 C1 的 7 或网络模式不授予二阶段更新。
- **最小性能修改**：`chapter3_world_layers.gd` 每 tick 只保留实际读取的 `theaterHunt.admitted` 小快照，替代两处完整深拷贝。所有首次/重进/回退/载入边沿保持不变，画质、像素尺寸和规则不变。

### 本地预检（不是最终远端 SHA 验收）

| 范围 | 可核事实 |
|---|---|
| 图标 | Source 对照 213；9 个相关阶段，Native 609 检查、4 时间线、30 布局。27 组合仅 fixture validate，**尚未生成真实 PNG** |
| 早期充电 | 实际 Native GUI/时钟专项 120；剧场边界 152；Source 模型 1129；未当作 WASM/物理手机证明 |
| Tiyi/迁移 | 新专项 61；Source 1033；保存集成 1829；域校验 1014；Source SaveStore 差分 572 |
| Controller 连续录制 | C1→C4，923 检查/0 失败；包含显式空间设置，**非人工或 Web 全流程通关** |
| 性能 | 7 个回归阶段、54,267 检查/0 失败；同官方4.7.1、冻结705源文件、仅该运行时文件不同的三轮交错 A/B |
| 新功能实际 Web 导出 | `sourceInputSha256=b715c1f3da36369de65285e40c995e33e843353f86b3abcadcfccd85c177ddb9`；首载 **98,403,868 B**，小于原100,000,000 B；无预算提高 |

性能数据是 **headless CPU 毫秒**，不是 FPS 或真机结果：

| 场景 | layer.sync P50 基线→修复 | world._process P50 基线→修复 |
|---|---|---|
| 宿舍 | 0.051→0.007ms | 0.110→0.041ms |
| 剧场 | 0.052→0.008ms | 0.134→0.055ms |
| 启真湖码头 | 0.053→0.008ms | 0.113→0.043ms |

每轮先预热，再同场景测量；手机切页结果无一致改善，不作加速结论。原始重复测量和源码摘要另存审计收据；这个微小 CPU 优化不能外推整游戏帧率或内存泄漏结论。

新增普通 Web 输入场景使用真实文件选择器、鼠标/触摸、持久化刷新与可见控件，不提供 State 写入桥。0%/1% v35 是从 controller-earned 盆栽边界**明确构造**的兼容输入，不是假称历史用户档；其 SHA、完整输入、唯一允许变化及拒绝负例独立记录。构造通过不算交互通过。最终 CI 分别验证真实充电/取消/手动光照、C1 首次网络谜题、C2 二次失败及公众号安装→运动→雨滴，并保留实际 PNG。
