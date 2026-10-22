# 7:55 全场景 UI 适配清单（只读审计）

基线：`2d077fe`，2026-10-21。文件路径均相对 `godot_native/`。本清单不是视觉批准、通关证明或新一轮测试结果；未修改 runtime。

## 决策边界

- 最新用户已明确批准 5 项：**HUD 2 左侧任务柱、interaction 1 居中物件牌、dialogue 2 右侧人物对话、journal 3 单页手记、theater 1 下方双区控制**；不再等待导出文件。
- 精确字号/字体/颜色/间距等按本轮用户提供参数执行，旧 playground 审批标记已被此最新指令取代。其余手机/背包/暂停大面板并非因此自动批准；不更改作者文案。
- layoutMode 未单独提供。按已确认名称解释为左列/居中物件牌/右侧对白，不用 compact 模式反向覆盖这些构图；这是原生适配映射，不宣称逐像素复制浏览器。
- 本清单的覆盖盘点仍有效；新 5 项适配正在进行，未经最终 GPU/交互验证不能称全场景完成。theater 1 不套用于无关票务终端；缺失梁祝源仍需定位。
- **梁祝**（不是良渚）：对 `scripts/`、解码后 `data/**/*.json`、保留 Web `src/` 搜索 `梁祝/灯影/扇影/liangzhu/fan_shadow` 均无命中。当前 `c3_spotlight.gd` 是已有剧场追光玩法，不能冒称梁祝灯影/扇影。需定位新源/分支才能纳入真实适配。
- 场景不等于 `.tscn` 数量：主要世界/手机/活动由脚本动态构建。`data/worlds.json.worlds` 有下列 8 个正式世界 ID；预览/研究场景不是新增可玩章节。

## 所有表面的共同适配契约

保持 State/controller、剧情文字、物件 ID、保存、earned gate 不变。保留已有键盘/鼠标/触摸、拖放坐标与点击目标；物件图片不得换成虚构线索。风格参数只进展示层。每个组件检查普通、hover/focus、pressed、disabled/locked、loading、error、success；适用时检查暂停/重试/返回/退出、失焦释放触摸、恢复原输入 owner。不得把只测 normal 的截图算作全状态覆盖。

尺寸验收：手机逻辑 430×860；世界源坐标/碰撞不改。建议总套件包含 1440×900、1280×720、430×860、390×844、667×375，窄屏中选实际风险点增测；429/431 宽用于滚动取整。逐项检查中文换行、图标不缺字、底部操作可见、滚动触底、抽屉遮挡、物件拖放转换、软键盘与安全区。上述建议不是声称已有全部覆盖。

## 世界与常驻层（8/8 IDs）

| 实际场景 | 组件/入口（scripts/） | 尺寸/遮挡重点 | 已有证据入口；尚需补齐 |
|---|---|---|---|
| dorm_hub 宿舍 | world.gd::refresh_world；objects/dorm_scene_adapter.gd；main._layout | 宿舍缩放映射、柜门/拾取与 HUD/背包碰撞 | capture_dorm_manual / dorm_cabinet_sequence；新样式两方向实际交互图 |
| campus_bootstrap 校园 | world.gd；ui/campus_wayfinding.gd | 世界导航≠手机地图；人物脚底、地标/任务遮挡 | capture_campus_wayfinding；UI redesign campus-map；多地图目的地与 toast 同屏 |
| library_interior 图书馆 | ui/library_world_layers.gd；presentation/library_story_host/view.gd | 座位、盖章、馆员对白、驱离/背包状态 | UI redesign library-dialogue；library_stamp_* tests；预约/驱离/归还边界态 |
| canteen_interior 食堂 | objects/canteen_object_scene.gd；ui/chapter3_world_layers.gd | 叠盘、机器命中区、用餐/防守 HUD | capture_c3_canteen_devices / canteen_foot_occlusion；防守暂停/结果/设备错误态 |
| theater_interior 剧场 | ui/chapter3_world_layers.gd；presentation/theater_stage_view.gd；c3_scene_host | 幕布、票口、线索实物、对白与设备重叠 | capture_theater_clues；UI redesign theater-device-error；舞台全部阶段/追光结果 |
| campus_qizhen_loop 湖区外环 | world.gd；ui/chapter3_world_layers.gd | 世界路径与手机导航返回，交通/角色遮挡 | campus wayfinding/source tests；独立新风格实际截图缺口 |
| qizhen_lake 启真湖 | world.gd；ui/chapter3_world_layers.gd；kayak_status_view | 船/双桨、湖面遮挡、提示/手机/物品柄 | qizhen_swan_* captures；kayak_status_layout；四次钓鱼/雨救援各终态 |
| duan_yongping_temporal_maze 教学楼 | ui/chapter4_world_layers/phase_layers.gd；main._open_chapter4_* | A1/A2/A3、1672×941 世界边界、房门底部/手柄/梯口、守卫 | room201/room301/endless_stair captures；compact_device_navigation；每楼层/204摆放/追逐切换 |

共同世界层：`main._layout/_show_world_mobile/_show_inventory/_show_world_journal`、`ui/world_overlay_layout.gd`、`world_inventory_item.gd`、`interaction_chrome.gd`、`inventory_gesture.gd`。HUD 2/interact 1 的已确认参数只映射这些展示入口；不能重写碰撞。已有 `test_world_overlay_layout/integration`、`test_inventory_viewport_transform`、`test_shell_layout`，不等于每个世界都已用新风格验收。

## 手机全路由及子页

主入口 `ui/phone_pages.gd::build`；`main._refresh/_layout` 拥有外壳；`ui/phone_chrome.gd` 拥有状态、任务、数字条、物品柄。不要由每页修改外框。

| 全部 route / 分支 | owner / 方法 | 风险与现有覆盖 |
|---|---|---|
| alarm / desktop | phone_pages._alarm/_wake；native_opening_presentation | 闹钟数字、唤醒/系统通知输入；opening/modal tests、capture_wake_actual；新版完整开场补拍 |
| ending | native_ending_resume.build | 继续/重开/加载错误，长标题；不能只拍主菜单 |
| phone_home | phone_pages._home / home_app_button / phone_home_art | CC98 不换行、42px gear、编辑拖动、通知最长态；symbols 实拍、app_identity/phone_app tests |
| wechat / system_chat | _wechat/_conversation | 长群聊、选择、真实对白、下一句焦点、返回；phone_navigation；需不同剧情会话实拍 |
| control_center | _controls | 滑杆/音乐/重置确认、暂停图标；symbols 实拍与 phone_utilities/effects；确认态补拍 |
| checkin | native_checkin_page / checkin_success_view | 格子、输入、成功页按钮；checkin tests；失败/完成两方向 |
| campus_card / bonsai | _campus_card/_bonsai；bonsai_growth_view | 卡片余额/编号与生长动画，不改图内文字；phone_pages/机制测试；动画终态补拍 |
| cc98 | _cc98；cc98_login_page / cc98_investigation_page / cc98_gamepad_exchange | 登录、hot/new/profile、board/post/search、draft/edit、调查、交换；调查可滚动 copy 取整已修；earned_catalog_title 5 宽覆盖；帖文/交换/错误态尚需一致实拍 |
| zjuding | _zjuding；campus_wayfinding / c3_lake_app_context | 主页、learn、campus_map、smart_classroom/network_account/logistics/lost_found/visitor_preview/language_cards/feedback_draft/all_apps/contacts/messages/profile；组合图标已拆层；symbols 含真实湖图；所有子页未全拍 |
| tiyi | _tiyi；native_tiyi_presence / native_tiyi_identity | 课程/运动入口与 running/resume；不能以虚拟跑测试覆盖所有前置页 |
| weather | _weather；native_weather_icon | 实际吹风机装置、雨天/完成、温度；symbols weather-complete；正在调整/失败另测 |
| directory | _directory | 长联系人名单、滚动、搜索输入；phone_pages 基础尺寸；软键盘/最长值补验 |
| library_app / library_recovery / library_record / library_rule / library_catalog / library_archive / library_022_dialogue / c3_lake_catalog | _library；native_library_pages.build/home/spaces/seats/catalog/recovery；local_page=home/spaces/seat/location | 固定顶部54/底部60与滚动、座位/检索/证据解锁；phone_library_login/library_catalog_repeat/earned_catalog_title；symbols 只涵盖主页，座位/恢复长文补拍 |
| photos | _photos；photo_evidence_surface / photo_brightness_session | 列表、选图、亮度解谜、线索动作；recovery_photo_layout、phone_pages gallery branches；普通照片/湖后自动路由分别验 |
| settings | _settings | root/search/详情、保存/导入等；UI redesign settings；长搜索结果与键盘/错误 |
| c3_journal / c3_journal_camera | c3_journal_pages.build | 记录与相机工具、earned 条目、取景按钮；qizhen_journal/save、journal_portability；相机覆盖缺口 |
| c35_recovery / c35_journal / c35_photos / c35_voice / c35_official / c35_messages / c35_network / c3_ticket_post | chapter3_phone_pages.build → recovery/journal/photos/voice/official/messages/network/ticket | 容器布局与 header、录音波形、照片序列、长文及按键最小高度；UI redesign 仅 recovery/network/voice；其余5路及完成/失败/播放/暂停需新实拍 |

入口/loading/notice 是独立状态：`phone_entry_visual.gd`、`native_phone_notice.gd`、`native_notice_queue.gd`。已有 phone_entry_lifecycle / phone_loading_notice_layout，不能用静态 ready 页替代验收。

## 活动 / 特殊设备 / 模态

所有活动从 `main._open_game/_open_game_now` 建立输入 owner、逻辑viewport、finished/cancelled/progress信号。下面合并同一脚本的正式 kinds；纯 model 文件不是独立画面。

| 表面 | owner / 入口 | 必验碰撞/状态；现有测试/截图 |
|---|---|---|
| 序章拦截 / 身份盖章 | games/prologue_interception / identity_stamp | 倒计时、汉字/章面、touch/keyboard、失败重试；opening/prologue 与 stamp tests；新版终态缺口 |
| 体艺虚拟跑 | games/virtual_run / virtual_run_track | 跑道/定位、暂停返回和10次验证；virtual_run_controls/authority/main_lifecycle；capture_virtual_run |
| 食堂防守 | games/canteen_defense / canteen_defense_view | 世界物件与HUD同帧、暂停/丢焦/结果；defense_mobile/resume/owners/world_return |
| 755米追车 | ui/minigame_host(mode=chase) / chase_field_view；media chase film | start→ride→finish不可重复奖励；移动安全区/短横屏；mobile_bike_chase、native_chase_integration、replay_handoff_layout |
| 钓鱼 / 划艇 | minigame_host(mode=rhythm/kayak) / lake_fishing_view / kayak_status_view | casting/count_in/fighting/failed/completed；长按释放、双桨、固定重试区；lake_fishing_*、kayak_* tests |
| 钓竿装配 | presentation/lake_rod_assembly / ui/lake_rod_assembly_view | 实物拖放点与遮挡，取消不写进度；assembly/paddles tests；新样式装配中/完成截图 |
| 追光 / 天气小游戏 | games/c3_spotlight / c3_weather | 追光多个轮次及 resolve、天气成功/失败；weather_readability等；不是缺失的梁祝场景 |
| 教学楼活动 | games/chapter4_activity kinds elevator_alignment/chase_stairwell/star_lamp_closure/prologue/dialogue | 移动端长选项/四角操作/过场；chapter4_lamp_*、chase_stair_view等；灯问题/确认/播放三者分开 |
| 错位楼梯 / 追逐空间 | games/chapter4_stairs / chapter4_chase_space_activity / chapter4_chase_space；presentation/*stair*/*chase* | 真实投影/行走、镜头、守卫、失败重试和handoff；endless_stair_camera_input capture；stair_inputs/guard/navigation/post_stair_return |
| 食堂设备 | main._open_c3_device → c3_canteen_device_panel / c3_mixer_panel/surface | 机器控件和物件拖放；c3_canteen_devices_controls、capture_c3_canteen_devices |
| 剧场设备 | main._open_c3_device → c3_theater_device_panel | theater1按确切参数映射到实际相关玩法，不套票务终端；键盘、密码错误、播放控制；c3_devices_controls、UI redesign error实拍 |
| 教学楼设备 | main._open_chapter4_floor_selection/_power/_clock/_device → chapter4_*_panel | 锁定/缺片/插片/对齐、弹窗返回；chapter4_device_panels/main、compact_device_navigation；现有locked图不含所有设备 |
| 全局物品/物件检视/文件 | main._show_inventory/_inspect_item/_open_phone_document → phone_document_modal | 真实物件图、长文、背包选中与返回焦点；inventory/document shell tests；UI redesign inventory/item-document |
| 日志 / 线索对照 | main._show_journal/_show_observation_comparison → native_journal_view / observation_comparison_view | journal3已确认单页手记；earned cards、双槽选择/交换/重选、长内容滚动；journal_composition/observation suites；UI redesign两图 |
| 表单 / 暂停设置 / 文件选择 / developer | main._show_form/_show_settings/_show_file_dialog/_show_developer | OptionButton展开边界、系统文件对话框、保存错误、禁用/焦点；native_long_form_layout、native_modal_world_input；UI redesign pause不是所有表单 |
| 剧情与反馈层 | main._open_narrative/_show_story_caption/_open_world_effect；presentation/c3_narrative_host、library_story_host；native_notice_queue | 不能被toast/背包盖住字幕；一次性关闭、音频/视频清理；library-dialogue/short-dialog已有图，c3反转/票口/章末需补 |

## 现有覆盖与下一轮验收差额

1. `capture_ui_redesign.gd`：1440×900、390×844主要表面；`capture_interactions`额外667×375。DEV checkpoint/字段造景，不是完整剧情通关。名称 campus-map 实际为校园世界，不是地图 App。
2. `capture_phone_symbols.gd`：两尺寸×6场景=12，包含真实湖区地图 App、天气吹风机完成状态。没有手机全部子页/所有hover-focus/error。
3. 既有 GPU 批次 `/tmp/755-candidate-347b6ff/ui-proof` 66图是旧候选参考，**不是新确认5项选择的验收**。前期修正CC98、组合图标、gear边界和湖图标题遮挡不应在新适配中回退。
4. `test_phone_pages` 是直接子节点横向几何及部分授权分支；不检查全部嵌套滚动文字可读性。`test_shell_layout`已有1440/1280/390/430；`test_world_overlay_layout`还有370×700与824×314逻辑extent；不要把这些逻辑extent称作设备真实GPU截图。
5. 优先补：8世界各1个HUD最拥挤状态；phone每个owner至少最长文/最低可用高度；所有小游戏 start/running/pause/fail/success；设备 locked/error/success；真实软键盘、触摸拖放、安全区、浏览器宿主 resize。普通无状态静态页可合批，不重复扩玩法。
6. 发布前绑定确切选择记录、最终commit、测试日志、capture manifest。重新跑受影响输入/生命周期/保存回归，而不是只跑样张；测试阈值不可为新字体/边框放宽。

## 可复核穷举入口

- 世界：`data/worlds.json` 的 `worlds` keys（上表8个）。
- 手机：`scripts/ui/phone_pages.gd::build` + `chapter3_phone_pages.gd::build` + 各builder本地子页；不能只搜索State.native.page。
- 活动：`scripts/chapters/*.gd` 中发出的 config.script/type/kind，最终经 `main._open_game_now`；上表不将*_model当画面。
- 模态：`main._modal_base/_layout_modal`的调用者；世界效果/剧情host另列，避免遗漏非modal UI。
- 检索不存在源是当前树证据，不能推断用户的新梁祝实现永不存在；需父代理定位最新分支/交付文件。
