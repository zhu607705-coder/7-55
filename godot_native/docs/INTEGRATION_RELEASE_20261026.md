# 2026-10-26 统一交付记录

本记录保存 PR [#175](https://github.com/zhu607705-coder/7-55/pull/175) 最终发布前的源码检查点；随后到达的完整 CI、合并和部署结果以该 PR 的精确提交与工作流为准。当前已提交基准为 `3064f8c8839dad1c9d591ec3c04b8d5271941224`；PR #174 的 `33cc499` 已纳入检查点 `158c6df`，最新 `bd0dfab34128c18436224aa539817e4fe9be9cf2` 正在本地合并，另有后续修复待提交。以下局部结果不能替代最终精确提交的发布验收。

## 本轮范围

- 手机：微信会话按当前章节展示、白色会话与社交页面、体艺图标和原生页面、连续虚拟定位及含直道的操场、浙大钉开场可浏览的 11 个应用、课程/点名/课堂层级、可选校园网账务支线、系统图标与设置、慧学外语例句和搜索。保留原主线证据、物品与控制器契约；图书馆应用内未解锁槽位仍为无按钮、无焦点和无事件的静态对象。
- 北教：301 展室 33 个独立对象与展柜索引抽屉、移除顶部操作提示；A3 墙脚和外围同源碰撞、原通道保留、杨卫画像挂墙和旧位置同源覆底、三层独立电梯按钮与关闭门槛。运行时和寻路使用同一脚框与源坐标。
- 亮度：删除直接提示取证条件的文字；手机玻璃层实际影响应用、控制中心和文档。拖动预览与控制器提交分开，保留原取证条件和低电量限制。
- PR #174 美术部分：7 类网页生成母版、53 个独立节点预览及来源记录。104/105 净地板仍未完成视觉验收，预览仅在显式 developer 门控下启用，正式构建不能据此宣称整层重建完成。
- CC98：本轮已回填 **323 个可见文案叶**（`52×2 + 165 + 54`，即普通帖标题/正文、普通回复与动态故事帖文案）。采用实际 Computer Use 中 Gemini 3.8 Flash / 低的场景描述生成，再按 Humanizer-zh 审阅；13 文件按旧/新 SHA-256 校对后回填，323 目标叶、元数据和 6 组源/native 镜像检查通过；5 个既有论坛/交易阶段 990 项检查通过，完整发布验收仍 pending。保留 `p02[1]`，以及故事证据值、关键词、作者、时间、帖 ID、附件和搜索匹配契约。来源与保护清单见 [文案来源记录](CC98_GEMINI_COPY_20261026.json)，模型代码未执行。

新公众号研究资料库是独立 Downloads 作者资料，本轮不扩大运行时 PR 范围。历史 20261025 来源文档和美术目录保留原日期；实际发布完成日期与新交付入口另行核实。

## PR #174 分段 CI 与集成

纳入 `a179494..33cc499` 的全部 20 个 CI、工具、测试和记录文件，外部 staging 清单逐文件验证 Git blob。默认仍执行完整 runner，使用两个连续 worker（jobs=2）；source/media/import 和 fixture producer 独占，消费者保留前置闭包和失败阻断。已知局部 profiles 可精简诊断，shared/unknown 变更保守回退 full；partial 结果不会标为完整通过。精确源码、生成物、工具和环境身份约束 resume，同字节去重仅限明确审核哈希，未删除回归文件。

Web 只生产一份 sealed export/fixture，再由普通/streaming baseline、地图/手机 profiles 和图书馆 profiles 并行验收；部署必须同时等待 `build`、`browser_baseline`、`browser_profiles`、`library_profiles` 成功，GPU/PCK 门禁保留。网页驱动同时保留 CDP 确认解除网络阻断后再清除故障身份，以及连续鼠标/触屏 `phoneRecovery.pointer` 两段修复。

集成中实际发现 `--plan/--list` 管道输出在 65,536 字节截断。修复等待 `stdout.write` 回调后退出，未放宽原 JSON 完整性断言；north-targeted 与 full 计划均可完整解析且保持 `not-run`，不会启动引擎。远端最终 jobs=2 完整耗时与加速幅度尚未核实。

## 横屏运行时与浏览器输入

地图始终使用 `960×540`、16:9 和统一等比缩放，手机应用保持 `430×860`。不拉伸地图，不改变源坐标、碰撞或进度权威。

- 主场景以实际绘制变换识别旋转/缩放，取消旧物品与场景手势；固定逻辑尺寸不再漏掉窗口旋转。物体特写在实际呈现区域变化时关闭并重算相机。
- 桨触点随实际比例保持至少 44px；真实桨优先命中，船体与乘员不因扩展触点而误触划桨。小世界相机保持 HUD 安全偏移，出口不会被反馈区遮住。
- 浏览器驱动真正改变设备宽高、screenWidth/Height、DPR 和 screenOrientation，验证 canvas 与 visual viewport 尺寸及 scale=1。先横屏再交互，通过普通双指缩放使远处目标入镜，保留原距离门槛、物理接近的中间帧和单次动作；不注入角色/相机进度。
- 保留 PC 方向键/Space、普通触摸、取消及 stale release、碰撞、返回竖屏手机和地图旋转往返。测试只修旧竖屏 fixture 和浮点变换精度假设，未删除上述功能断言。

## 已取得证据

以下为可追溯的局部结果，存在覆盖重叠，不能累计为全游戏或人工通关数量。外部报告根为 `755-tools/verification/room301-20261025/`，不随交付打包。

| 检查 | 已取得结果 | 报告与限制 |
| --- | --- | --- |
| CI runner 三项专项 | 58 / 0，0 skipped | `ci174-integration-targeted-flush-fixed.log`；保留首次截断失败日志 |
| 地图/输入/特写/相机 9 个既有阶段 | 2259 / 0 | `landscape-ci-orientation-final.json`；completed=true，fullSuitePassed=false |
| 房间 204 既有对象与第二桌 | 1316 / 0；870 / 0 | `native-final-root-three.json`；fixture 纳入独立电梯门槛，原计数失败保留 |
| 中文实际可见阶段 | 123 / 0 | `zh-visible-phase-final.json`；从真实会话入口启动原攻击时钟，替代同组早期失败 |
| 浏览器驱动既有回归 | 82 / 0 | `mobile-world-landscape-driver-node-final.log`；含旋转 helper 合同与负控 |
| 3064 新导出桌面/390 触屏定向 | 596 项 / 2 cases | `precise-3064f8c-browser/result/web-acceptance.json`；亮度、状态栏、地图及手机往返 |
| 原壳旋转负控 | 实际失败 | `precise-3064f8c-browser/rotation-fullmetrics-result/web-acceptance.json`；返回竖屏后 canvas 为 844×1827、scale≈0.462085 |
| CSS 壳候选正控 | 507 项 / 1 case | `precise-3064f8c-browser/shell-css-candidate/web-acceptance.json`；同一导出只替换 canvas CSS，恢复 390×844、scale=1 |
| 横屏真实地图触摸，DPR1 / DPR3 | 各 921 / 0，0 页面错误 | `mobile-world-landscape-pinch-touch390/`、`mobile-world-landscape-pinch-retina390/` 下 `web-acceptance.json`；3064 导出配 CSS 代理，不是最新全部源码的新导出 |

上述 3064 导出的 source-input SHA-256 为 `9f33417eb8d59c3aab8a0b7fc664573c83990b7d12a6202b5319bcf0b9edd5be`。更早 5251 旧导出的 919/920 连续拖拽结果与本表分开归档。全体 3064 native 尝试中的历史失败日志仍保留；本表是受影响项的后续定向结果，不把旧完整运行改写成全绿。

## 文案回填后的局部复核

- 新 runner 的 changed profile 选择 5 个既有论坛/交易阶段，并执行准备输入、存档隔离、导入、启动及全脚本解析闭包：10 stages pass、0 failed/blocked，522 not-run，明确为 partial。5 个论坛阶段合计 990 checks / 0 failures。
- `validate:quick` 5/5；中文显示覆盖 171 叶与有声文本合同通过。首次执行因新媒体回执缺失被阻断，按新工具用现有 ffmpeg/ffprobe 完整转换两段视频后通过，原失败日志保留。
- `test_cc98_gamepad_exchange.gd` 的完整正文断言改为比较当前批准源正文，交易金额/权限/视觉边界的原断言保留；不复制旧文案作为另一个文本权威。

## 20261026 最新 CI 分片接入

重新 fetch 发现 PR #174 又推进至 `bd0dfab`，本轮继续保留该提交祖先。其 27 文件增量把完整原生检查分为封存准备和 6 个双 worker shard，并严格汇总；新增 reader 自动进入依赖计划，未知输入保守执行全量。Web 13 个 consumer 覆盖 17 份报告，完整 sealed 产物和精确 source/receipt 身份不变；缺片、重复、旧 attempt、失败和取消均拒绝当作全绿。原生/GPU gate 与 Web gate 各自必须成功。

- 4 处合并冲突逐项解决；保留本地 plan stdout flush、真实连续跑步 pointer、地图实际旋转和确认解除网络拦截的顺序。
- c2 phone shard 使用连续轨迹，coverage 与对应测试同步；不恢复旧 Fix1–10 点击循环。实际慢项 phone job/step 使用 18/12 分钟，其他 world job 保留 12 分钟；Web 声明超时总上限为 230 runner-min，不是实测耗时或账单。
- 10 个直接相关 Node 合同共 277 项最终通过。初次 bundle 55 项因 macOS `/var` 软链接触发既有 fail-closed guard；只为该专项指定仓库外物理 TMPDIR 后 86/0，其余 9 文件 191/0。原失败保留，未放松路径 guard。
- 新源文案使三个派生输入陈旧：重建 normalizer、library story 与 chapter3 narrative fixture；三个原 `--check` 均通过。Normalizer 仅变化 4 个湖区论坛字符串与源哈希，未改存档规则。
- 远端 `bd0dfab` 的独立基线：Native、retained Web 和 cross-PR 成功；Godot Web 的 retina c2 phone 失败，汇总正确拒绝发布。该结果不替代本轮集成提交的验收。

## C2 独立分片的真实内容就绪

失败 artifact 证明内容仍被必需加载遮罩覆盖：17,836,924 / 105,841,080 bytes，15 包 requested，readyFamilies 为空，实际 scene_id 为空。唯一一次手机按钮输入被遮罩正确拦截。驱动改为使用原 bootTimeout 等遮罩解除、第二章状态及实际寝室场景恢复后再唯一点击；原 20 秒手机可见断言保留，不重试点按、不写状态、不绕开内容门禁。3 个相关 Node 文件 100/0（与前述277有重叠，不累计）；新集成导出中的 retina C2 实际复核仍 pending。

## f7de542 的完整 CI 与后续修正

- Web CI、cross-PR、全部真实 Web consumer 通过；source-contract VM fixture 未提供新增 bootTimeout，汇总正确拒绝发布。补齐真实 option 输入和转发断言后，诊断212项、传输39项通过。
- 原生余三个用例失败。较长图书馆回复暴露离树 Label 字体缓存量高误差（101px 对实际113px），补主题通知后282/0、447/0，两尺寸GPU图确认正文和按钮不重叠。
- 湖区检查的去前缀旧拼接期望改读当前源完整三条，继续精确比较数量与顺序，109/0。旋转夹具冻结了正常相机跟随，取消原断言后恢复一次更新，原源目标/碰撞/精确脚点断言保留，12路线102/0。
- 实际 CUA 观察到手机玻璃覆盖全局 F10 菜单中央；全局弹窗改到玻璃上方，手机应用、文档和手机内控制中心仍受亮度影响。既有surface/chrome442/0、72/0。
- f7干净导出Retina C2实际887/0，含唯一返回手机、更新安装、save/reload、10段触屏拖动与水滴；人工普通导入301、返回手机、论坛和真实亮度滑杆通过。上述历史精确提交证据不代替后续集成门禁。

## 发布状态与边界

| 环节 | 状态 |
| --- | --- |
| 最终提交与完整 source-input 指纹 | pending |
| 最终精确提交的 native / retained Web / Godot Web CI | pending |
| 最终集成导出与浏览器验收 | pending |
| PR #175 合并、远端 main 路径核验 | pending |
| Pages 部署、线上 build-manifest 身份与实际输入复核 | pending |
| CC98 323 叶回填和保护检查 | 完成；5 个既有受影响测试 990/0，最终 CI pending |

本地结果不证明实体手机、其他浏览器内核或四章人工通关。最终交付以实际提交、工作流、远端 main 和线上 manifest 为准；源码合并与网站上线分别记录。较早范围、来源和失败历史见 [20261025 集成记录](INTEGRATION_20261025.md)，CI 分段合同见 [Native validation stages](NATIVE_VALIDATION_STAGES.md)。
