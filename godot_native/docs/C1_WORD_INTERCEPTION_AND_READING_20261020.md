# 2026-10-20 第一章文字发现与通知阅读设计／验收

本轮回应两个实际反馈：旧错误框拦截过短，玩家缺少发现操作与理解规则的过程；剧情文字和通知会互相覆盖，黑色半透明阅读面也不合适。实现与本记录均位于隔离候选 `/tmp/codex-755-c1-ui`，不代表此前 canonical 发布包已包含这些修改。

## 三阶段文字发现

`src/data/prologue-interception.content.json` 是 Web 与原生共同使用的作者数据；原生同步副本的 SHA-256 同为 `64ff1f31b664749a43d5590bf9464717634c33bdb342386852c9244a91fea778`。共六个目标文字卡，映射三个完成阶段：

| 阶段 | 目标文字 | 判定关系 |
| --- | --- | --- |
| 发现移动与留下文字 | `等` | 一个真实目标接触；背景词不是目标。 |
| 留下两个坐标名称 | `经度`、`纬度` | 两条独立坐标支线，先后不限；不是必须先经度后纬度。 |
| 接回原句 | `旁白`、`还没`、`说完` | 按原句先后完成，不能提前接后面的片段。 |

每段先展示可读线索，玩家可回看完整线索。错误框本身仍是可拖动的挡板；指针／触屏拖标题栏，或用 `A/D`、左右方向键持续移动。目标文字与实际窗口采用旋转矩形的扫掠接触判定；末帧位置接近、等待或红色接触标记本身都不授予进度。红圈不再是三次下落路线里的移动对象，最后长按锁定圆圈仍保留。

错词、次序错误或目标漏出时，现场暂停并显示本次原因。回看、暂停和失败阅读期间不消耗运动、生成或处罚时钟。选择 Web 的 `继续这一段`／原生的 `继续当前阶段` 会保留已完成阶段与当前已经收集的文字，移除不安全的旧词体，仅重新发出缺失目标；没有三次失误清零限制，也不会自动通关。提示逐步从原因进入窗口／线索关系，后续可提供当前缺失文字的落点辅助。这些是已给线索的阅读与操作帮助，不提供未来章节路线。

根线程实际 GUI 还发现：原生按钮每帧先隐藏再显示，导致跨帧按住后松开丢失点击。旧测试把按下／松开塞在同帧，未捕获此问题。修复移除逐帧先隐藏动作；新测试改为按下后跨三个真实 `process_frame` 并执行布局，再释放，同时验证 `R` 恢复读取。这项修复与负控单独记录，不能用旧的 `35` 项输入检查替代。

原有签到成功、经纬度错误框、红闪、七秒黑屏、最终 `1400ms` 长按、四句对白、白屏收尾和手机主页交接保留。六次实际文字捕获各自参与局部语义判定；三个阶段完成后仍映射现有 `interceptedCount: 3` 证明。`ActOneBootstrapController`、原生章节控制器、共享状态类型与存档结构未改为新的推进权威。锁定提前释放、取消或失焦仍清除未完成按住进度。

这里“保留四句对白”指各端本轮修改前各自已有的四句，并非 Web／原生逐字一致。原生沿用 `zh_text_revisions` 的现有中文显示适配：[2026-10-18 台账](CHINESE_TEXT_REVISION_20261018.md) 将 `table-prologue_narrator_caught`、`table-prologue_narrator_bargain` 标为“采纳”，`table-player-threat` 标为“适配采纳”。两句玩家文字各处于约 `1100ms` 的固定无声窗口，已有适配压缩为“帮我补签到！”／“不帮就一起死机！”，保留补签与死机威胁，避免移动后续 bargain 既有配音 cue。原英语音轨与 offset 保留；映射见[现有中文修订数据](../data/zh_text_revisions.json)。本轮保留两端各自原四句，不撤回已采纳适配，也不把这项已记录差异视为新 bug 或漏合并；最终实际 GUI 对白验收仍以根线程后续记录为准。

[独立只读衔接审查](../verification/integration_20261020/c1_handoff_readonly_review.json) 核对了既有中文采纳、完成门槛、重复回调／旧证明拒绝及原有存档续接，未发现新产品阻断；其中列出的两处旧文档措辞已在审查后修正，原报告不回写。

词体、已收集集合与阶段内提示属于活动会话，不是新存档字段；“失败继续当前阶段”不等于承诺保存每一个漂浮词的中途状态。完成后的普通保存与真实重载仍走原有 `SaveStore`／原生存档消费者。第二章独立的系统红圈对话没有被这次第一章替换。

## 通知与剧情各自的阅读时钟

普通通知使用单条当前消息和等待队列，后来的通知不会直接覆盖正在阅读的内容；重复当前或等待内容合并，不重新开始阅读计时。小游戏、章节介绍、模态阅读或可见剧情字幕占用阅读面时，普通通知等待或暂停；恢复后继续未读时长。

有口播时钟的剧情字幕保持即时显示，不能放入普通通知 FIFO，否则文字会落后语音。Web 使用纯呈现角色，原生通过同步的 `last_subtitle.presentationRole` 区分来源；原生 `subtitle_timed` 四参数信号不变。来源 `dialogue`／`taunt` 使用剧情阅读面，任务与普通结果仍是通知。原有 `subtitleSurface: scene` 消费者继续负责其字幕，不再重复一份全局文字。

手机剧情采用说话者与正文分开的下方阅读带；原生底边锚在手机逻辑 `y=820`，上方 `100` 像素内的状态栏、标题和任务区域继续保留。C3／图书馆现有面板改为不透明暖纸与深色文字，图书馆不再额外绘制全窗半透明黑幕。没有改其安全矩形、影片退出通道、长文滚动、输入或控制器回调时序。

设置弹窗仍有预留通知行；Room302 自有反馈、食堂取餐字幕、虚拟跑结果、世界单字幕 owner 继续优先。追逐到达影片拥有的成功文字从普通队列精确移除，防止影片结束后再次播放。新增文字发现线索没有生成新的有声剧情；现有音频资产、来源键与精确时长继续使用。

## Gemini 使用边界

根线程通过 [Gemini 网页会话](https://gemini.google.com/app/862f03f73afba38f) 提供上下文和实际界面，模型选择器确认为 **3.5 Flash-Lite**。Argon 选项因额度灰显，不能将本次协助写成使用了 Argon 或 Gemini 4。

求助范围限于文字与前端 UI 候选，包括线索发现、提示层级和阅读面。只采纳部分建议，并由项目实现者核对、纠错；没有把模型输出当成后端、状态、存档或碰撞实现的依据，也没有据此新增有声剧情。实际实现与下列可执行证据负责验收。

## 已有定向证据

小型报告以原字节归档于 `godot_native/verification/integration_20261020/`；[证据索引](../verification/integration_20261020/c1_reading_manifest.json) 记录来源、字节数、SHA-256 和待完成项。没有把原始截图、媒体或大日志纳入此目录。

| 检查 | 实际结果与范围 | 报告 |
| --- | --- | --- |
| Web 文字模型 | `52/0`；连续输入、碰撞与语义关系、无序坐标、同阶段保留；旧算法负控有效。 | [模型](../verification/integration_20261020/c1_web_model.json) |
| Web 真实应用无头浏览器 | `27/0`；键盘／指针／触屏、缩放、回看／继续、隐藏暂停，以及外置合法存档进入后通过真实控制器完成、写盘与重载。不是人工浏览器试玩。 | [浏览器](../verification/integration_20261020/c1_web_browser.json)／[来源摘要](../verification/integration_20261020/c1_web_summary.json) |
| Web 共享通知 | `30/30`；真实隐藏标签页暂停、React 卸载／重挂载、手机／RPG keyed surface 更替、后续 FIFO、`390` 缩放手机边界。旧 Toast 的 `31` 项检查中出现 `21` 个有效契约失败，无浏览器／基础设施异常。 | [通知浏览器](../verification/integration_20261020/notice_web_browser.json)／[harness 摘要](../verification/integration_20261020/notice_web_harness_summary.json)／[旧实现负控](../verification/integration_20261020/notice_web_legacy_negative.json) |
| 原生 C1 初轮 | 修复按钮前的九阶段快照：模型 `28`、同帧根输入 `35`、早期游戏 `16`、原音频 `32`、C1/C2 控制器 `87`、音效 `86`、恢复控制 `144`，另有自动化四章衔接与 `736` 脚本解析。保留为历史证据，不冒称其捕获最终跨帧按钮问题。 | [修复前摘要](../verification/integration_20261020/c1_native_summary.json) |
| 原生 C1 按钮修复后 | 六个定向阶段均通过，含强化根输入 `37/0`、模型、原音频、早期游戏、四章自动化衔接与 `736` 脚本解析。旧生产跨帧负控为 `20` 检查／`7` 个失败；修后 `37/0`，没有将失败当基础设施异常略过。 | [修后六阶段](../verification/integration_20261020/c1_native_after_button_fix.json)／[跨帧负控](../verification/integration_20261020/c1_native_held_button_before.json)／[修后输入](../verification/integration_20261020/c1_native_held_button_final.json) |
| 原生真实 Main 嵌套输入 | 合法流程取得待继续存档的种子检查 `43/0`；通过正式故事按钮和继续按钮进入 Main，在 `1440×900`、`390×844`、`667×375` 各 `27/0`，共 `81/0`。验证实际偏移／缩放后的全局坐标鼠标与触摸拖动、跨帧按钮、回看／`R`、焦点交接及无额外推进。 | [摘要](../verification/integration_20261020/c1_native_main_nested_input_after_expiry_summary.json)／[桌面](../verification/integration_20261020/c1_native_main_nested_input_after_expiry_1440x900.json)／[手机](../verification/integration_20261020/c1_native_main_nested_input_after_expiry_390x844.json)／[短窗](../verification/integration_20261020/c1_native_main_nested_input_after_expiry_667x375.json) |
| 原生 C1 负控 | 六个故意破坏版本均被对应断言捕获；不是生产代码六次失败。 | [负控](../verification/integration_20261020/c1_native_negative_controls.json) |
| 原生通知／字幕 | 十八个独立阶段的有效定向覆盖通过；末次通知专项 `32/0`，含实际返回、剩余阅读时间、即时语音与队列任务、弹窗行、`430×860`／`390×844`／`667×375` 下方阅读带。最后小修分别补测受影响阶段，不冒称一轮连续十八项。 | [通知摘要](../verification/integration_20261020/notice_native_summary.json)／[最终阅读带](../verification/integration_20261020/notice_native_layout_final.json) |
| 原生通知负控 | 同版脚本对旧来源得 `21` 检查／`15` 个预期失败；另证实追逐影片文字留队会重复，再由精确移除修复。 | [旧来源负控](../verification/integration_20261020/notice_native_old_source_negative.json)／[影片负控](../verification/integration_20261020/notice_native_chase_negative.json) |
| 原生世界通知最终修复 | 四项最终来源定向共 `152/0`：新归属专项 `19`、原通知 `32`、world overlay `89`、world lifecycle `12`。真实 `State.feedback` 三条通知依次读完；场景占用不偷露、单扣时钟、手机／世界互换、同文字外部 owner、直接清空与独立 World fallback 均通过。旧生产同脚本 `19` 检查／`13` 失败含同一卡死的后续断言，不是十三个独立问题。 | [最终摘要](../verification/integration_20261020/notice_native_world_expiry_summary.json)／[原始定向](../verification/integration_20261020/notice_native_world_expiry_focused.json)／[有效负控索引](../verification/integration_20261020/notice_native_world_expiry_valid_negative.json) |

上述原生定向报告实际使用本机 `Godot 4.7.2.stable.official.ed1daf0bf`；不据此宣称其它引擎版本已通过。断言数量是诊断输出，不是分支覆盖率、完整玩家旅程数量或可玩性评分。原生自动化四章连续脚本也不是人工从第一章玩到第四章的证明。

计时需要单独解释：Web 模型的 `59.1s` 是确定性模型模拟时间，不含原七秒黑屏和 `1.5s` 部署；浏览器报告 `64.2s` 仅为驱动主循环计数，额外故意失败的时间推进不在计数中。原生零失败输入报告为模型约 `57.89s`、本地整段场景时钟约 `80.06s`，其中最短一次已观察目标可交互时间约 `3.275s`。这些都不是人类解题用时、成人难度 benchmark、整段真实浏览器用时或固定强制通关时限。详见 [原生计时原始结果](../verification/integration_20261020/c1_native_zero_failure_timing.json)。

## 实际 GUI 的部分验收

根线程通过 Godot 项目管理器重启修后独立 DEBUG 工程，实际验证回看开关、失败继续当前阶段、`R` 阅读恢复，以及按 `A` 约 `260ms` 让窗口向左移动。已通过第一段 `等`，在第二段留下 `经度` 后出现与“方向”有关的错误提示；继续时 `经度` 保留，只补 `纬度`，随后进入第三段并留下 `旁白`。该次记录为累计 `4/6` 个目标、第三段回看暂停；这是最终通知修订前的历史实证。详见 [CUA 部分验收记录](../verification/integration_20261020/c1_gui_review.json)。

最终通知修订后，根线程正常 `Cmd+Q` 退出，再在 Godot 项目管理器选择文字试玩工程，仅执行一次 Run 后关闭项目管理器，加载最终 Main `a6513d7e…`／world `1a08dfd0…` 来源。通过普通主线入口与 Ending Resume Continue 继续，签到结果仍保留；活动局部文字从 `0` 词重新开始，第一目标自然漏过后，以 `R` 打开第一段完整线索。**当前停在第一段回看供用户继续**，没有据此声称完成最后两词、最终长按或对白／白屏收尾。

CUA 拖动尝试没有观察到窗口移动，因此**不声称人工鼠标拖动已通过**。追加的[原生鼠标 Viewport 专项](../verification/integration_20261020/c1_native_viewport_mouse_drag.json) 为 `6/6`：仅提交真实引擎 `MouseButton`／`MouseMotion` 事件，按下跨三帧、六帧拖动、松开跨三帧，验证移动、倾角、释放后停止及二次抓取；没有直接写模型／位置。它与根键盘、触摸拖动和缩放几何一样属于自动化输入证据，不能替代人工鼠标实证。最后两个片段、最终长按、四句对白和白屏收尾尚未在这次实际 GUI 中完整走完。

通知到期与单归属修复后，真实 Main 专项重新执行，并进一步覆盖了宿主嵌套的坐标转换，而不是把活动直接挂在根窗口：先走合法种子流程取得存档，再在隔离 receipt profile 中以实际按钮进入故事、继续 C1，通过根 Viewport 的全局坐标事件测试三种尺寸。各尺寸 `27/0`，来源摘要前后相同，保留 `probeSha256`，不归档存档本体或外置诊断脚本。它运行的是带生产 feature 的源码／编辑器实例，不能称为不可变正式发布包或实际操作系统鼠标验收；也不替代上述尚未完成的人工收尾。

## 完整原生轮次与最终增量

本次本机原生验收已按“完整原轮＋明确修复后的定向增量”完成。[最终原生摘要](../verification/integration_20261020/combined_native_acceptance.json) 保留完整原轮 `419` 阶段的真实结果：`416 PASS / 3 FAIL`、退出码 `1`，当时解析 `736` 脚本。没有把失败改写成一次全绿。

两项音频失败来自测试用固定墙钟等候，实际 AudioServer 已播放约 `4.008s`，尚未达到原 `4.16s` 的百分之八十门槛；生产拒绝授予“听过”证明是正确行为。修正测试读取实际播放时钟，并以提前停止／暂停三项有效负控保留门槛。[诊断](../verification/integration_20261020/combined_native_clock_diagnostic.json)、[负控](../verification/integration_20261020/combined_native_clock_negative.json) 与[测试修正记录](../verification/integration_20261020/combined_native_test_remediation.json) 分别保留。

第三项 world 生命周期检查既含旧“立即覆盖字幕”的预期，也促成了真实生产问题的发现：world 到期先清空文字后，Main 仅按文字相等同步，留下约 `6.94e-17s` 的余量使 FIFO 停在首条。最终以字幕赋值 revision 的明确到期回执解决，并移除 Main 所持 world 的 `State.feedback` 直连，让普通状态反馈只走 Main 队列；独立 world 保留原 fallback。同文字外部 owner 和直接清空不算读完，世界时钟仍只扣一次，原可读时长、场景暂停、modal 预留行与手机／世界交接保持。有效旧生产失败与最终修后结果均保留，未将此生产修复伪装成只改测试。

完整原轮结束后，原生输入只改变六个路径：

- `scripts/main.gd`、`scripts/world.gd`：上述通知到期与单归属修复。
- `tests/test_chapter3_media.gd`、`tests/test_chapter3_phone_ui.gd`：实际播放时钟检查。
- `tests/test_world_presentation_lifecycle.gd`：真实场景占用、完整 FIFO 以及 world 时钟检查。
- 新增 `tests/test_world_notice_ownership.gd`：真实 `State.feedback`、外部 owner、正常 surface 路由和独立 world fallback。

最终[原生增量](../verification/integration_20261020/combined_native_delta.json) `19/19 PASS`，包括自动化四章、C1 自动保存／Continue、C4 后段 Continue、受影响呈现与 `737` 脚本解析；另加上述四个 world 定向阶段，扣除重复的 world lifecycle 后，共 `22` 个不同最终定向阶段通过。最终 Main 又独立通过三尺寸 `81/0` 与合法种子 `43/0`。这不是重新跑了一遍完整 `419`／新枚举 `420` 阶段，也不是人工全程通关。

完整原轮期间 `3592` 个原生输入的起止摘要相同，runtime `2660` 文件摘要同为 `bd461c886975f187814948f713bdff153e7b116cedb17a5886ac73b7eb81bb18`；六文件增量后的 `3593` 输入起止同为 `24ca124f6846ff932475c273988577f89ff69bb74611e3b960c42cf1d281b19b`，runtime `2660` 文件起止同为 `bc7c077fc5f5f2c03b6765fa27240fe34ebdee82f02e395a4250fe175e792056`。逐文件差异与原失败指纹见最终摘要；较大的完整输出与全来源快照保留在 ignored `exports/verification/c1_20261020/`，没有纳入本次小型证据目录。

## 发布与人工验收边界

| 项目 | 本记录状态 |
| --- | --- |
| 本次本机原生验收 | **已完成上述范围**：完整原轮 `419 = 416 PASS / 3 FAIL` 保留；最终 `19/19` 加补充定向、扣重共 `22` 不同阶段通过，解析 `737`。未宣称完整新候选一次全绿。 |
| 合并候选 Web release | **PASS `38/38`**，耗时 `83139ms`，含四项正式生产浏览器 smoke。`demo/index.html` 为 `241886625` 字节，SHA-256 `2fd8f9cad637481a8bce55c4c0398394af8ca271a863f622c1eecb1d7942f331`；这不是人工全程通关。见 [完整 Web 机器报告](../verification/integration_20261020/combined_web_release.json) 与 [正式 smoke](../verification/integration_20261020/combined_web_release_smoke.json)。 |
| 实际 GUI／拖动与阅读面 | **部分通过，整体 pending**：此前已实证回看、继续、`R`、键盘移动及四个目标；最终来源再次重启后当前停第一段完整线索。人工鼠标拖动未观察到移动，最后完整收尾未走完。 |
| PCK／ZIP 与正式发布 | 由最终冻结提交另行生成；准确来源与验收以 `exports/` 对应的 `*.validation.json` receipt 为准，本文不代填新包 hash。正式发布与远端 CI、人工残余验收仍须各自确认，不能沿用旧包的 PASS。 |
| 物理手机、Linux Godot 4.6.3、听感 | 未由本轮这些无头定向报告证明。 |

本轮没有把文档归档当作提交、推送或发布操作。本机验收已按上述范围完成；后续产物 receipt 独立关联最终提交，无需为将新包 hash 写回本文而循环改动提交。保留人工与平台边界及计时限制。
