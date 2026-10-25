# 2026-10-25 统一集成记录

用户明确要求整体合并，统一当前版本。基线为 `main` 的 `abd8b0028e8443795518243da7930ee760bc92e9`，同时纳入 PR #174 的原始提交 `a1794948558f651c55fa12b2347fa26a418ed3a7`。采用保留提交祖先的合并方式，让该 PR 与本地功能进入同一条主线；不把只读 fetch 记成已经合并。

## 内容

- 手机候选：微信阶段消息与内容、白色界面、体艺图标、连续定位及直跑道、开场可浏览校园服务、课堂与签到入口、校园网账单支线、系统设置、20 组 Gemini 双语例句及搜索。原验收历史见 `TIYI_VISUAL_20261025.md`、`WECHAT_SOCIAL_20261025.md`。
- 301 展室：33 个独立对象、中央展柜内索引抽屉、清空入口、源脚框碰撞与遮挡，删除顶部操作段落。文案与素材来源见 `ROOM301_EXHIBIT_20261025.md`。
- 北教修复：A3 墙脚与地图外围补齐同源碰撞；保留全部必须通行区。杨卫画像、金框和热点一起移至楼梯右侧北墙，以当前时态同源地砖恢复旧位置。电梯门旁三层按钮各为独立对象，按压/指示反馈连接原操作，关闭的门有实际门槛。
- 亮度修复：删除设置页取证提示，手机玻璃层覆盖应用、控制中心和手机文档。整个 0–100 范围有可见调光；拖动时只预览，松手仍经控制器提交。设置与控制中心共用低电量上限，照片原有取证条件继续由控制器核验。
- PR #174：7 类网页生成素材及 53 个独立节点调试预览、启动器、检查与来源记录均纳入。该 PR 的 104/105 净地板尚未验收，仍保留其显式调试门控；正式默认渲染不据此宣称整层物件重建完成。

## 验证

局部变更复用已有检查，云端按精确集成提交执行所需发布门禁；不在本地重复整套游戏回归。

- 亮度：现有 chrome 72、工具 50、实际 Main 照片生命周期 260 项通过。覆盖按下未松手时画面已变化、拖动不销毁控件、设置页不产生照片证据、原照片调光条件及三种尺寸。
- A3 墙体：有效旧实现负控为 131 项中 18 项失败；修后实际主场景 135 项通过。既有拓扑验证 5687 项通过，全部 8 个必须通行区和 9 条既有路线保留。
- 电梯按钮：现有 world 44 项通过，含三层可见面板命中、原空地不再命中、门槛实体/门前可站、深浅模式及退出清理。
- 肖像：TypeScript、既有素材检查、20 位人物来源数据逐字段对应与现有 phase world 552 项通过。实际 Godot 4.7.1 Compatibility 图形渲染已查看新挂墙位置及旧框补底；这不是全流程人工验收。
- 例句扩充：现有手机导航 241 项通过，实际浏览器检查 430×860 和 390×844 的搜索、清空、译文与长列表末尾；阅读不改剧情。此前已记录的专项结果按其原始来源摘要保留。

最终集成导出、浏览器复走、CI、主线合并及部署各自记录结果。正式发布以主线提交、Pages 工作流和线上 `build-manifest.json` 为准。

## 提交范围

包含当前已跟踪修改与新增源码、数据、美术和项目记录，并纳入 PR #174 的 30 个文件。排除本地 `node_modules` 链接、忽略的导出/缓存、外部 QA 截图及下载草稿。

<!-- submission-files -->

- `docs/game-text-by-chapter.md`
- `godot_native/assets/native/north_objects_20261025/blackboard_105_web_master.png`
- `godot_native/assets/native/north_objects_20261025/bookcase_105_web_master.png`
- `godot_native/assets/native/north_objects_20261025/chair_student_web_master_v2.png`
- `godot_native/assets/native/north_objects_20261025/chair_v2_foot_qa.json`
- `godot_native/assets/native/north_objects_20261025/desk_student_web_master.png`
- `godot_native/assets/native/north_objects_20261025/lectern_105_web_master.png`
- `godot_native/assets/native/north_objects_20261025/notice_105_web_master.png`
- `godot_native/assets/native/north_objects_20261025/plant_105_web_master.png`
- `godot_native/assets/native/north_objects_20261025/room301_archive_case_v1.png`
- `godot_native/assets/native/north_objects_20261025/room301_index_drawer_v1.png`
- `godot_native/assets/native/north_objects_20261025/web_batch2_provenance.json`
- `godot_native/assets/native/north_objects_20261025/web_props_provenance.json`
- `godot_native/data/native/campus-services-copy.json`
- `godot_native/data/native/chapter4-native-source.json`
- `godot_native/data/native/language-examples.json`
- `godot_native/data/native/north-baseline-objects.json`
- `godot_native/data/native/north-generated-objects.json`
- `godot_native/data/native/room301-exhibit.json`
- `godot_native/data/native/tiyi-interface-copy.json`
- `godot_native/data/native/virtual-run-copy.json`
- `godot_native/data/native/wechat-social-content.json`
- `godot_native/data/worlds.json`
- `godot_native/docs/INTEGRATION_20261025.md`
- `godot_native/docs/NORTH_OBJECT_PREVIEW_20261025.md`
- `godot_native/docs/NORTH_OBJECT_PREVIEW_ACCEPTANCE_20261025.json`
- `godot_native/docs/ROOM301_EXHIBIT_20261025.md`
- `godot_native/docs/TIYI_VISUAL_20261025.md`
- `godot_native/docs/WECHAT_SOCIAL_20261025.md`
- `godot_native/samples/north_independent_props/README.md`
- `godot_native/samples/north_independent_props/capture.mjs`
- `godot_native/samples/north_independent_props/play.gd`
- `godot_native/samples/north_independent_props/run.mjs`
- `godot_native/scripts/chapters/campus_network_account.gd`
- `godot_native/scripts/chapters/chapter4.gd`
- `godot_native/scripts/chapters/phone_utilities.gd`
- `godot_native/scripts/games/virtual_run.gd`
- `godot_native/scripts/games/virtual_run_motion.gd`
- `godot_native/scripts/games/virtual_run_track.gd`
- `godot_native/scripts/main.gd`
- `godot_native/scripts/objects/chapter4_elevator_button.gd`
- `godot_native/scripts/objects/north_prop_scene.gd`
- `godot_native/scripts/objects/room301_archive_art.gd`
- `godot_native/scripts/objects/room301_archive_motion.gd`
- `godot_native/scripts/objects/room301_archive_panel.gd`
- `godot_native/scripts/objects/room301_archive_view.gd`
- `godot_native/scripts/objects/room301_exhibit_adapter.gd`
- `godot_native/scripts/objects/room301_exhibit_layout.gd`
- `godot_native/scripts/objects/room301_exhibit_prop.gd`
- `godot_native/scripts/presentation/north_generated_objects.gd`
- `godot_native/scripts/state.gd`
- `godot_native/scripts/ui/c3_lake_app_context.gd`
- `godot_native/scripts/ui/chapter4_phase_layers.gd`
- `godot_native/scripts/ui/chapter4_world_layers.gd`
- `godot_native/scripts/ui/native_checkin_page.gd`
- `godot_native/scripts/ui/native_learn_page.gd`
- `godot_native/scripts/ui/native_library_pages.gd`
- `godot_native/scripts/ui/native_tiyi_identity.gd`
- `godot_native/scripts/ui/native_tiyi_presence.gd`
- `godot_native/scripts/ui/phone_campus_services.gd`
- `godot_native/scripts/ui/phone_chrome.gd`
- `godot_native/scripts/ui/phone_entry_visual.gd`
- `godot_native/scripts/ui/phone_pages.gd`
- `godot_native/scripts/ui/phone_settings_chrome.gd`
- `godot_native/scripts/ui/phone_system_icon.gd`
- `godot_native/scripts/ui/tiyi_seven_art.gd`
- `godot_native/scripts/ui/wechat_chrome.gd`
- `godot_native/scripts/ui/wechat_message_bubble.gd`
- `godot_native/scripts/ui/wechat_social_pages.gd`
- `godot_native/scripts/world.gd`
- `godot_native/shaders/north_prop_alpha_cutoff.gdshader`
- `godot_native/tests/capture_north_independent_props.gd`
- `godot_native/tests/capture_north_palette_alpha.gd`
- `godot_native/tests/capture_north_wall_reveal.gd`
- `godot_native/tests/capture_virtual_run.gd`
- `godot_native/tests/test_chapter4_phase_world.gd`
- `godot_native/tests/test_chapter4_world.gd`
- `godot_native/tests/test_early_games.gd`
- `godot_native/tests/test_native_learn_page.gd`
- `godot_native/tests/test_north_generated_objects.gd`
- `godot_native/tests/test_north_independent_props.gd`
- `godot_native/tests/test_north_preview_gate.gd`
- `godot_native/tests/test_north_prop_fail_closed.gd`
- `godot_native/tests/test_phone_anchor02_tiyi.gd`
- `godot_native/tests/test_phone_app_identity.gd`
- `godot_native/tests/test_phone_chrome.gd`
- `godot_native/tests/test_phone_navigation.gd`
- `godot_native/tests/test_phone_utilities.gd`
- `godot_native/tests/test_photo_brightness_consumer.gd`
- `godot_native/tests/test_room301_archive_main.gd`
- `godot_native/tests/test_tiyi_visual_layout.gd`
- `godot_native/tests/test_virtual_run_authority.gd`
- `godot_native/tests/test_virtual_run_controls.gd`
- `godot_native/tests/test_virtual_run_main_lifecycle.gd`
- `godot_native/tests/test_wechat_reference_ui.gd`
- `godot_native/tests/test_wechat_social_pages.gd`
- `progress.md`
- `scripts/verify-chapter4-temporal-maze.mjs`
- `src/data/ChapterFourAlumniHonorWall.ts`
- `src/data/chapter4-three-floor-maze.layout.json`
- `src/scenes/rpg/ChapterFourTemporalMazeScene.ts`
