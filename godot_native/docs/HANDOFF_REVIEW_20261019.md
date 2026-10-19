# 2026-10-19 整合树衔接复查

检查对象：`integration/godot-complete-20261019` 的未提交整合树，Git HEAD 为 `0592269fb2d72944eef8c5aadf72a612cf99ea0f`。本地实际引擎为 Godot `4.7.2.stable.official.ed1daf0bf`。本轮复查关注正式流程、纯呈现、独立预览之间的状态和控制权交接。

## 已确认的湖区规则

用户于 2026-10-19 明确选择保留当前网页端及 PR #51 的独立材料支线，同时保留旧存档投喂兼容。此项选择已经确定，`AGENTS.md` 原有有序道具链条已同步，不再作为待决规则冲突。

- 钓竿、尼龙绳、破损网框、天鹅磁铁分别保留在物品栏。钥匙开柜取得绳、钓取网框、黑天鹅支线取得磁铁之间不强制排序。
- 四件齐备后，控制器原子消耗四件材料并产生磁性钓竿。合成演出只显示已经接受的结果。
- 新流程不要求先合成抄网、捞饲料罐、开罐、钓小鲤鱼再投喂。旧 `swan_exchange` 存档仍接受小鲤鱼投喂；该动作只消耗鱼、取得独立磁铁并保留钓竿。

证据并非仅有文件路径：

| 证据 | 实际含义 |
|---|---|
| [已合并 PR #51](https://github.com/zhu607705-coder/7-55/pull/51)，head `81b6a8adb67253d68a838c30cd7f8a48f003c20d` | 明确要求任意材料顺序、四件最终合成、旧投喂入口；2026-09-07 北京时间已合入 Web 主线。该 head 为当前 `origin/main` 的祖先。 |
| `progress.md` 的“2026-09-07 启真湖四件材料最终组装” | 记录用户对独立支线的澄清，区分新 `tool_chain` 入口与旧 `swan_exchange` 兼容入口。 |
| `src/modules/ChapterThreeQizhenLakeController.ts` 的 `combineItems`、`feedSwan`、`completeSwanBranch` | 当前 Web 的真实实现。四件合成和独立天鹅支线在 `ac30d197`（2026-08-28）引入，并在 `350be86e`（2026-09-07）修正物品保留和重载。 |
| `godot_native/scripts/chapters/c3_lake.gd` 的对应方法 | 初始原生移植提交 `ef0024a5`（2026-10-02）已经采用当前 Web 规则，并非本次合并删除了旧链条。 |
| [PR #115](https://github.com/zhu607705-coder/7-55/pull/115) | 明确保留四件原配方，新增原生物体和纯呈现，不赋予动画奖励或存档权威。 |
| [PR #149](https://github.com/zhu607705-coder/7-55/pull/149)、[PR #152](https://github.com/zhu607705-coder/7-55/pull/152) | 前者接入天鹅/救援呈现，后者修复正式 Continue；均未宣称用独立湖区样例替换正式玩法。 |

本机执行未修改的 Web 控制器回归：`verify-qizhen-tool-branches.mjs` 六种顺序、204 项通过；`verify-qizhen-swan-material.mjs` 通过。这说明当前 Web 行为，不能单独证明原生所有路径或旧存档的最终可完成性。

## 正式与独立衔接

| 交接 | 已核对的权威与清理 | 证据和限制 |
|---|---|---|
| 正式钓纸条 → 天鹅入场 → 正式河道 | 钓鱼结果先原子保存抓纸/放天鹅和河道阶段；入场只持有一次性、绑定精确状态及追逐次数的呈现 lease。演出阻止河道输入和计时，不能提交逃脱结果。 | `c3_lake.gd`、`c3_swan_entrance_session.gd`、`test_c3_swan_entrance_shell.gd`；此前本机 140 项通过，含跳过、失焦、取消、状态替换、重载与重复 terminal。 |
| 天鹅呈现完成/取消 → 河道操作 | Rig 为呈现子节点，结束后随 owner 释放；纸条与 HUD 保留在 Rig 之上。正式 WorldSession、河道位置、碰撞和完成 proof 不被预览模型替换。 | 正式测试检查真实捕获位置/朝向、前景顺序、完成及取消销毁、原逃脱结算与物品消耗。 |
| 原生天鹅独立预览 → 划桨/重播/退出 | 一份 Rig 只采样现有模型；重播复用该子节点，退出释放。自包含打包清单已补齐 Rig 场景、脚本与图层依赖。 | 最新 native preview 与重新生成的独立包各 1447 项通过，含真实 draw、取消手势与迟到释放；正式 PCK 历史 adapter probe 15 项通过，最终重新导出的包由打包验收再跑。 |
| 入口 → 内嵌楼梯/树木预览 → 入口 | 内嵌楼梯通过 `exited` 交还 host；独立运行才允许退出应用。host 关闭预览时先禁用处理，再延迟释放节点和工具条。 | `entry.gd`、楼梯 view 与 `test_entry_previews.gd`；现有测试覆盖真实菜单点击、两种返回、存档和 InputMap 保持，最终入口改动由当前验证批次确认。 |
| 入口 → 独立湖区/Blender 工程 | 单独 OS 进程，不共享正式完成凭据；目录说明明确关闭独立窗口后回原入口。 | 能运行独立项目不等同于接入正式章节；不能把该项目的成功信号写入正式状态。 |

## 本轮修复

此前两个天鹅入口仍调用已经删除的 `kayak_art.draw()`。它们已改用 `scenes/objects/kayak_rig.tscn`，并增加前景 pass 保持纸条、遮幅和 HUD 的绘制顺序。对应 PR 原始文件仍有字节快照及原 SHA，当前适配文件另有 SHA；没有覆盖原始来源校验值。

追加静态复查确认独立天鹅预览未处理 `InputEventScreenTouch.canceled`：已记录的桨手势遇到取消释放时会被当成普通释放，发出一次意外划桨。现在取消会清除该指针并直接返回，后续迟到释放不能恢复动作。现有预览测试新增两条断言；最终原生与重新生成的独立包均执行 1447 项、0 失败。

## 旧投喂兼容与续接修复

旧投喂代码真实存在：`c3_lake.gd` 的 `swan_exchange` 分支检查拥有小鲤鱼，消耗鱼、授予 `swanMagnet`，保留钓竿并回到 `tool_chain`；空间目标在该阶段接受 `smallCarp`。

修复前，`export_lake_branch_source_fixtures.mjs` 从 TS 控制器生成 legacy net/tin/fish/feeding 路径，`test_qizhen_branches.gd` 通过原生实际目标、真实钓鱼重放和磁盘保存/重载逐步比较。旧测试停在投喂奖励，没有继续验证最终组装，因此漏掉了续接死路。

本机纯 Node 真实 Web 控制器 + SaveStore 已复现进一步缺口：

1. 旧 `swan_exchange` 存档已有 `netCombined=true`、`lockerOpened=true`，绳和网框已在旧链中消耗，小鲤鱼仍在物品栏。
2. `feedSwan("smallCarp")` 接受。保存、重载后只剩钓竿和磁铁；绳和网框仍不存在。
3. 四件组装返回 `wrong_item`；重新钓钥匙、网框均返回 `already_complete`。原生对应条件同样阻止重新获取。

初始失败记录：`/tmp/codex-755-lake-legacy-feed-continuation.json`。此缺口已在共享源控制器、存档迁移和原生层修复：

- 新增 `legacyNetMaterialsConsumed`，只记录旧抄网已消耗绳和框。浏览器迁移读取归一化前的明确 `netCombined`、`lockerOpened`，保留显式 `false`；不能把阶段推导的事实在第二次读档时洗成收据。实际使用旧抄网也可以签发该收据。
- 原生旧文件的普通 Continue 和原生导入均在原结构校验后、填默认值之前补同样收据。仅这个新字段允许旧文件缺省；字段存在时仍必须是布尔值。
- 最后组装把已经使用的两件材料计入旧消耗，只消耗当前拥有的钓竿和磁铁并关闭收据。不补发绳、框，不再次消费旧材料，不让投喂直接授予最终钓竿。
- `QizhenFinalAssembly.ts` 让 Web 控制器和真实物品栏按钮使用相同的材料条件。任务/物品栏说明旧材料已经使用；原生 `can_assemble` 与实际页面动作同样可达。
- 回归扩展为旧浏览器 v18/v26/v35 → 投喂 → 保存重载 → 最终组装 → 重载/重复提交，以及旧原生文件 Continue/导入、无收据的阶段值、伪收据、缺钓竿/磁铁和严格布尔字段。保留新鲜六种支线顺序及四件实际消耗。

新 Web 专项还通过真实 `RpgInventoryDock` 渲染检查组装按钮存在，并检查只发布仍拥有的钓竿/磁铁消费事件。该专项已注册到现有 critical/release 套件。最终原生差分已实际运行：湖区源行为 739 项、60 次原生磁盘存档、0 失败；完整 SaveStore 差分 569 案例、0 失败。两者均使用当前生成 fixture 与最终控制器代码。

## 当前验证状态与剩余包验收

最终 source/SHA 静态复测为 2414 项、0 失败，`git diff --check` 通过。原 PR 的原始字节快照与原 SHA、当前适配 SHA 均由同一检查器核对；四个负向探针会拒绝快照损坏、适配文件损坏、删除 optional 资源 guard 或删除侧面镜像 fallback。不存在以新 SHA 覆盖原始 SHA 的宽免。

Web quick 4/4、critical 25/25 全部通过，包含新旧存档专项；初始状态、719 资产、SaveStore IR、存档域和源控制器差分 fixture 已同步，生成数据检查通过。根任务暂停原生进程进行 computer use 时只做 Node/静态工作，解除暂停后才执行以下最终定向批次。所有原生运行使用 `tools/native_test_sandbox.mjs`，没有修改真实玩家存档或 `HOME`。

| 最终检查 | 实际结果 |
|---|---|
| 原生启动与完整脚本图 | 启动通过；725 scripts、0 failures |
| `test_qizhen_swan_entrance.gd` | 1447 checks、0 failures，包含新增取消/迟到释放 |
| 重新生成的独立 swan 包 | 新目录打包、资源导入、包内同一测试 1447 checks、0 failures |
| `verify_lake_branch_source.mjs` | 6 种支线顺序、51 个组装条件、6 个天鹅条件、5 个旧保存续接；739 checks、60 native disk saves、0 failures；同时通过真实保存保护的负向探针 |
| `verify_save_migration.mjs` | 569 个原 SaveStore 差分案例、0 failures |
| `test_save_integration.gd` | 1805 checks、233 real-file browser imports、117 developer checkpoints、0 failures |
| `test_world_inventory_combinations.gd` | 64 checks、0 failures |
| `test_lake_assembly_paddles.gd`、`test_lake_assembly_shell.gd` | 95 / 44 checks、0 failures |
| 救援动画与控制权专项 | `test_rain_rescue.gd` 50、`test_rain_rescue_ownership.gd` 25 checks、0 failures；由最终原生批次执行 |

上述最终定向批次记录于 `/tmp/codex-755-native-post-integration-report.json`；最新独立包记录于 `/tmp/codex-755-swan-final-package-report.json`，目录为 `/tmp/codex-755-swan-final-package`。完整原生总报告与最终入口人工检查由根任务整合，不在本报告重复计总数。

此前跨 PR 32 个通过阶段与定向复测的来源、首次失败和复测记录仍保留于 `/tmp/codex-755-crosspr-report.json`。该记录明确区分旧完整批次、后续定向批次和最新源 SHA，不把它们改写成第二次完整跨 PR 运行。正式天鹅 shell 此前 140 项通过，后续触控修改只影响独立预览；其对应生产文件未再改变。

剩余的是最终交付包验收：重新导出最终正式 PCK，并从空目录通过外部 `tools/verify_pr_integration_pck.gd` 复测导入资源和真实 Rig。该项由打包收口执行；历史 15 项通过不能代替最终包。没有悬挂的湖区规则冲突，也未声称全章人工通关、真实音频或手机硬件验收。

## 最终交付 PCK 验收补记

上述待验项已于 2026-10-19 完成：从冻结运行源码重新导出 `exports/7-55-integrated-native-20261019.pck`，714795696 字节，SHA256 为 `b73a9a493553753fef9eca2bc425a7da8b27d1b6a584c506ba6dc8e43b96ece1`。导出前后运行源码摘要一致；没有复用历史包。

相同字节的 PCK 放入无源码目录，通过外部 `tools/verify_pr_integration_pck.gd` 实际运行，最终 **15 项、0 失败**，覆盖正式入口、原生救援纹理重映射与 JSON、生产适配脚本、State autoload 和真实 Kayak Rig 依赖。交付包保留正式存档目录；仅验收目录的旁置 `override.cfg` 使用临时隔离存档。证据归档于 `verification/integration_20261019/pck.json`，`cross_pr.json` 仅追加此次最终包结果并更新汇总状态，原始失败与复测记录不改写。
