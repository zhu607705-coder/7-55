# 2F 团队工作室：两台屏幕，两个版本

**后续修订：** 原按钮排、编号端口按钮与默认热键说明已按用户准则撤掉。当前交互见[场景实物与操纵杆](OBJECT_INTERACTION_20261029.md)；本页保留前一版机制及历史验证，不作为当前操作说明。

2026-10-29 · 隔离的原生 Godot 可玩小样

在二楼团队工作室走近既有 `team_desk_6`，按 Space 或点击桌面进入。源端改动沿实际接线传播，接收屏收到后才刷新；旧片段回放可以恰巧与当前画面相同，却不会跟随下一次修改。玩家改变连接后，用两次不同改稿检验同步是否稳定。

当前完成只保留在本次评审会话中。没有正式任务奖励、存档、跨房间进度或生产剧情接入，刷新会重置。太阳能小车仍是设计与抽象数值模型，机器人往返仍是视觉流程设计。全楼 25 间清单不代表已经有 25 个可玩关卡。

## 操作与呈现

- 点击两个编号接头接线，鼠标拖线是等价操作；键盘 1–7 选择接头，Space 改稿，X 断开输入端，Z 撤回。
- 分配盒的一条输入对应两条输出，每个物理输出只连接一根线。交换两台接收屏的位置时，接头、接线及屏幕身份一起移动。
- 屏幕图案用形状和 A/B/C 字母区分，不以颜色为唯一编码。传播动画按实际路径与跳数运行，不提前刷新目标。
- 提示由 H 或按钮逐层请求；第一层指出异常，第二层建议比较，第三层指回制作/试用记录。提示与记录位于顶部，接线区始终可见，可明确收起。
- 退出、失去焦点或改线中止未完成的试验。改线使当前验证失效，撤回也须重新验证；已经在本地取得的结果不倒扣。
- 返回房间恢复原脚底位置和输入，原来的两台显示器也显示当前接收图案。楼层轮廓、门洞、碰撞和通行均未改变。

## 视觉依据

沿用原生字体服务与 `monitor_front.png` 透明对象，不新增照片式 UI。显示器裁片等比显示；960×540 操作面随窗口等比缩放。正文/按钮为 23 逻辑字号，辅助状态为 20；按钮高 44，接头为 54×44。在 844×390 横屏下分别约为 16.6px、14.4px 和 31.8px。当前没有改变项目艺术规范或全局视觉系统。

本轮 Impeccable 复核发现并修复了移动字号、线索覆盖接线、H3 仍显示“下一层”三项问题。最终复核为 ship，仅限这些修复和提供的截图，不等于 Argon 对全部谜题的评审。

## 复现

在仓库根目录设置 `GODOT_BIN` 指向项目固定的 Godot 4.7.1。

```sh
node godot_native/samples/future_learning_center/run.mjs --signal-test --headless
FLC_SIGNAL_CHECK=1 FLC_CAPTURE_DIR=/tmp/flc-signal-desktop node godot_native/samples/future_learning_center/run.mjs --resolution 1280x720
FLC_SIGNAL_CHECK=1 FLC_TOUCH=1 FLC_CAPTURE_DIR=/tmp/flc-signal-mobile node godot_native/samples/future_learning_center/run.mjs --resolution 844x390
node godot_native/samples/future_learning_center/run.mjs --test --headless
```

按现有 standalone 导出流程运行 `build_web.mjs <output-directory>`，设置匹配的 `GODOT_WEB_TEMPLATE`。通过 HTTP 服务打开 `<output-directory>/?area=team`：只将玩家放在合法工作台接近点，不自动进入或完成谜题。默认机电操作台入口和 `?area=stairs` 继续有效。

本机当前试玩：[双屏工作室](http://127.0.0.1:8139/signal_sync_20261029/?area=team)。这是本地服务地址，不是部署网址。

## 本轮证据与边界

基线为 `codex/flc-transcript-level-design-20261029` 的 `4c5fa5f147ce3cdd492895a97f9cca69fd415efd` 加未提交工作树；实际文件校验值见 [测试输入收据](SIGNAL_SYNC_VERIFICATION_20261029.json)。没有将基线 SHA 当成包含新代码的已测试提交。

| 验证 | 结果 | 范围 |
| --- | --- | --- |
| 双屏模型 | 15 项，0 失败 | 缓存反例、不同改稿、连接版本、撤回、取消 |
| 桌面普通输入 | 19 项，0 失败 | 接近、点击/键盘/拖线、交换屏幕、撤回和退出 |
| 模拟 844×390 触控 | 18 项，0 失败 | 同一原生按钮和两端点选，含返回原位置 |
| 三层空间回归 | 1740 项，0 失败 | 既有楼层空间与相关规则 |
| Native preflight | 5 项通过，536 项未运行 | 部分预检，不是完整发布验收 |
| 独立 Web 导出 | import / startup / export 均通过 | Godot 4.7.1，autoload 列表为空，不访问正式存档 |

截图与输入记录保存在仓库 `.impeccable/review/flc_signal_20261029/`。浏览器实测记录以验证收据为准。尚未验证实体手机、全部浏览器家族、正式章节与生产发布；没有新增配音。

[完整25间设计](../design/ROOM_PUZZLES_20261029.md) · [提示与难度](../design/GUIDANCE_AND_DIFFICULTY_20261029.md) · [待发送 Argon 审阅包](../design/ARGON_REVIEW_PACKET_20261029.md)
