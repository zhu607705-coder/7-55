# 手机界面、校园服务与连续定位（2026-10-25）

原本地候选基于 `0c01f5c45a7efbc42b7759af9df86a0fea4932ec`，包含微信内容、体艺界面，以及用户后续追加的跑道、校园服务和设置要求。本文保留当时的实现与验收历史；用户后续明确整体合并，当前交付范围已统一至 [集成记录](INTEGRATION_20261025.md)，不再使用中间的文件批次作为独立待上传版本。

## 实际变化

- 微信采用用户提供的手机截图布局：白色会话列表、浅灰置顶区、头像、姓名、摘要、独立时间列和底部四栏。顶部搜索可输入过滤，通讯录、朋友圈、公众号、文章和返回路径实际可用。朋友消息按当前章节与阶段选择；第一章提醒收入手动展开的历史。气泡由独立对象和容器计算高度、换行与内边距。
- 体艺桌面、启动页和主页复用同一个有边距的跑步图形。主页是原生标题、统计卡、菜单和滚动内容；保留原始金色 7 的裁片、领取动作与 4 的底图。四个菜单可进入详情并返回，缺失的运动记录不虚构。
- 虚拟定位改为连续操控 GPS 点。鼠标/手指拖动，方向键移动，空格减速；可见干扰区要求慢行。离开跑道或冲过干扰区会丢失本段并退回最近记录点，点击目标不能推进。跑道使用两段平行直道和两端半圆，绘制、检查点和移动范围来自同一条曲线。松手、触摸取消、失焦和暂停清除输入。
- 浙大钉的全部 11 个应用入口、搜索和底部导航从开局均可打开。地图在尚未解锁出寝室流程时显示当前位置与路线状态；浏览服务不会自动开放世界。图书馆入口可打开，原 `xxx` 占位改为可读状态；未满足的预约与现场调查在详情中说明，原控制器继续核验操作。
- 智云课堂展示原创微积分课堂片段与板书，后续章节显示回放。数字签到进入原四位码页面；雷达显示检测动画，人在寝室时明确返回不在教室范围内。它不调用真实定位，也不授予原签到完成事实。数字页返回原来的课堂来源；学在浙大提供课程、点名记录和课堂直录播入口，已完成或已结束状态不持续显示正在点名。
- 网络缴费加入可选账务谜题：查看本月待缴账单及已缴回执，选择匹配原因并核对重复计费。控制器要求两份凭据都已查看；错误原因不能消除欠费，重复提交不产生额外收益。独立可选原生存档字段保存核对结果并验证来源条件，旧存档无需新增字段。不扣原校园卡余额，不改变网络模式或主线证据。
- 设置使用原创 Wi-Fi、扬声器、亮度、桌面、应用、锁、电池和信息图标，配白色分组列表。条目整体可点击，子页有返回，保留搜索和滚动位置；遵循减少动态效果设置。大字号由容器计算行高。

## 参考与文案

通过用户提供的登录链接实际查看了学在浙大的“我的课程 → 课程 → 点名记录”结构，以及独立的课堂直录播入口。仅借鉴层级和界面语义；代码、文案和报告不包含账号、成绩、个人课程记录或登录凭证。公开入口：[学在浙大](https://course.zju.edu.cn/)。

设置图形参考 Apple HIG 的一致笔画、可识别语义与图标尺寸原则，采用自行绘制的矢量图形：[Icons](https://developer.apple.com/design/human-interface-guidelines/icons)、[Settings](https://developer.apple.com/design/human-interface-guidelines/settings)。

新界面说明通过 Computer Use 在 Gemini 3.8 Flash / 低的会话中只提供场景与事实约束，不给示例句。按 [Humanizer-zh](https://github.com/op7418/Humanizer-zh/blob/main/SKILL.md) 精简措辞；删除模型擅自添加的寝室楼号、开放时段、真实蓝牙检测及校园规章。正文集中在 native JSON。原故事对白、配音、物品 ID、数字证据和剧情结果 payload 保留。

## 验证与边界

- 复用此前已通过且未受影响的微信/体艺、Main 运动生命周期与保留 Web `validate:release` 38/38 结果。本轮没有再次运行整个游戏套件。
- 最新集中原生检查 5/5：手机导航、设置与账单真实保存/读取、课程页、连续跑道输入、原控制器验收。包括错误账务原因、缺少凭据、伪造结算存档、钱包不变和章节不变。
- 实际 GPU 查看 430×860 跑道、设置、1.35 倍字体、课堂、图书馆、欠费页与寝室地图。雷达触发后将结果滚入视野；数字页回退保留来源。实际触屏暴露账单卡片拦截滑动，已让内容、卡片与按钮向滚动容器传递手势，设置列表同时修正。
- 完整相关流程通过：桌面 1280×720（934 项内部断言）、390×844/DPR3 模拟触屏（935 项内部断言），均覆盖 7 组操作路径，且无页面/运行/未取消网络错误。多数内部断言属于同一导出包的资源完整性检查，不是新增数百个玩法测试。对应 source-input 为 `bdfd1b328cabf90cd463ff730cd91b5e39295fe37d119f47d79bdce6c663dac1`。
- 最后只补雷达结果的布局等待：两帧容器布局完成后滚入视野，完成反馈再次定位。最终 Godot 4.7.1 Web source-input 为 `f265d3ef4dcfb7a01fc008e56ff7b18afd031c5277c7a5e895ec71887e6ea7fa`；导出通过资源/媒体校验，触屏相关流程再次 935 项通过，新增实际几何条件要求结果完整位于固定底栏上方。Computer Use 在 390×844 与 430×860 检查实际反馈和普通返回；未因此重跑整个原生或保留 Web 套件。
- 导出是未提交工作区构建，不代表精确提交的云端发布。检查只覆盖本轮路径，不代表实体手机或全四章人工通关。
- 失败记录保留：首次检查把第一章剧情齿轮误当设置入口，改用正式第二章进度后通过；实际触屏发现账单卡片拦截滑动并据此修复；一次原生手势试探使用了固定引擎 ScrollContainer 不处理的 ScreenTouch 事件，删除该无效试探，改用浏览器真实触摸事件验证。切换本地服务时的一次重复检查出现连接拒绝，在服务固定后重新通过；未忽略这些网络错误。
- JSON 与日志位于外部 `tiyi-style-20261025` 验证目录（`campus-services-native.json`、`services-desktop-accepted`、`services-touch-visible`、`final-cua-navigation.json`）。临时 QA 截图按仓库要求检查后清理；用户预览单独保存在 `/Users/zhu/Downloads/755-phone-preview-20261025/learning-courses.png`。
- 提交前只读 fetch 后，HEAD 与 origin/main 同为 `0c01f5c45a7efbc42b7759af9df86a0fea4932ec`。工作区为 25 个已跟踪修改与 16 个新文件；本地独有提交 0，远端 main 独有提交 0。原有 node_modules 链接不包含在清单内。

## 当前完整待提交清单

以下原 **41 个文件**记录手机候选；用户追加的翻译例句新增第 42 项。301 展室另见 ROOM301_EXHIBIT_20261025.md，本列表不作为新的提交授权。原有 `node_modules` 依赖链接、生成导出、外部测试记录及临时截图均排除。

1. `godot_native/scripts/chapters/phone_utilities.gd`
2. `godot_native/scripts/games/virtual_run.gd`
3. `godot_native/scripts/games/virtual_run_track.gd`
4. `godot_native/scripts/state.gd`
5. `godot_native/scripts/ui/c3_lake_app_context.gd`
6. `godot_native/scripts/ui/native_checkin_page.gd`
7. `godot_native/scripts/ui/native_learn_page.gd`
8. `godot_native/scripts/ui/native_library_pages.gd`
9. `godot_native/scripts/ui/native_tiyi_identity.gd`
10. `godot_native/scripts/ui/native_tiyi_presence.gd`
11. `godot_native/scripts/ui/phone_entry_visual.gd`
12. `godot_native/scripts/ui/phone_pages.gd`
13. `godot_native/scripts/ui/tiyi_seven_art.gd`
14. `godot_native/tests/capture_virtual_run.gd`
15. `godot_native/tests/test_early_games.gd`
16. `godot_native/tests/test_native_learn_page.gd`
17. `godot_native/tests/test_phone_anchor02_tiyi.gd`
18. `godot_native/tests/test_phone_app_identity.gd`
19. `godot_native/tests/test_phone_navigation.gd`
20. `godot_native/tests/test_phone_utilities.gd`
21. `godot_native/tests/test_virtual_run_authority.gd`
22. `godot_native/tests/test_virtual_run_controls.gd`
23. `godot_native/tests/test_virtual_run_main_lifecycle.gd`
24. `godot_native/tests/test_wechat_reference_ui.gd`
25. `progress.md`
26. `godot_native/data/native/campus-services-copy.json`
27. `godot_native/data/native/tiyi-interface-copy.json`
28. `godot_native/data/native/virtual-run-copy.json`
29. `godot_native/data/native/wechat-social-content.json`
30. `godot_native/docs/TIYI_VISUAL_20261025.md`
31. `godot_native/docs/WECHAT_SOCIAL_20261025.md`
32. `godot_native/scripts/chapters/campus_network_account.gd`
33. `godot_native/scripts/games/virtual_run_motion.gd`
34. `godot_native/scripts/ui/phone_campus_services.gd`
35. `godot_native/scripts/ui/phone_settings_chrome.gd`
36. `godot_native/scripts/ui/phone_system_icon.gd`
37. `godot_native/scripts/ui/wechat_chrome.gd`
38. `godot_native/scripts/ui/wechat_message_bubble.gd`
39. `godot_native/scripts/ui/wechat_social_pages.gd`
40. `godot_native/tests/test_tiyi_visual_layout.gd`
41. `godot_native/tests/test_wechat_social_pages.gd`

42. `godot_native/data/native/language-examples.json`

慧学外语新增双语例句及自然线索，文案与只读交互的来源和验证见 [301 展室与外语例句](ROOM301_EXHIBIT_20261025.md#慧学外语与后续文案流程)。
