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

## PR #175 的 CI 修复候选

本轮补齐 13 个运行时、生成数据及既有验收驱动文件。修复以当前控制器、源坐标和存档语义为边界；以下是本地定向结果，不代表该候选已通过远端 CI、合并或部署。

- 连续定位已不再提供旧 `Fix` 按钮或 `target` 属性。四章驱动改为实际按下、沿轨迹移动、松手，浏览器驱动分别发送普通鼠标拖拽和触屏拖拽；保留十段轨迹、600 秒及 3000 米的原验证契约，不直接填写完成进度或绕过控制器。完整控制器流程为 1170 项、0 失败，完成四章并重新生成 controller-earned fixtures。
- 同步 `save_normalizer.json` 的当前源输入；生成数据继续从既有源派生。轻量 world fixture 未创建 `chapter4_layers` 时跳过电梯对象接入，正式章节仍按原层对象完成惰性创建与绑定。
- 图书馆尚未解锁的入口保留图标、名称和槽位，改为无焦点、无按钮子节点的静态对象；点击不弹额外说明、不发出意图、不改剧情。控制器解锁后在原槽位恢复普通按钮。手机状态栏移除重复手绘字层，由原生 `Label` 统一排字和绘制，避免时间/网络文字叠印。
- 紧凑窗口中的地图保留 `960×540` 逻辑视口，等比缩放并留边；手机仍使用 `430×860`。既有点地、摇杆和等待场景验收读取当前变换后的可见区域，不再假设竖屏地图会改变源投影。

复用的定向结果如下，报告存在范围重叠，不累计为全游戏人工验收：

| 路径 | 结果 | 证据范围 |
| --- | --- | --- |
| 四章控制器流程 | 1170 / 0 | `controller-earned-updated-run/controller-campaign-report.json`；真实连续轨迹输入及控制器回执 |
| Web 手机恢复，桌面 | 919 / 0 | `phone-recovery-continuous-run/web-acceptance.json`；十段鼠标拖拽 |
| Web 手机恢复，390×844 触屏 | 920 / 0 | `phone-recovery-continuous-run-touch390/web-acceptance.json`；十段普通触屏拖拽 |
| 地图场景视口 | 282 / 0 | `landscape-scene-contracts.json`；六个既有场景和五种窗口，地图保持 `960×540` |
| 地图实际输入 | 312 / 0 | `landscape-direct-input.json` 的 `PORTRAIT_EXPLORATION`；点地、摇杆、取消及后续移动 |
| 食堂等待 | 140 / 0 | `landscape-canteen-final.json`；最终独立报告替代早期同场景失败尝试 |
| 图书馆锁定槽 | 139 / 0 | `library-locked-slot.json`；静态锁定、点击不发意图及同槽解锁 |

上表报告位于外部验证目录 `755-tools/verification/room301-20261025/`。`landscape-direct-input.json` 同时保留早期食堂失败输出；仅其独立的实际输入结果为 312 / 0，食堂以最终报告为准。Web orientation helper 的 20 项通过由协作代理最终报告提供，本节不将其当作新导出的浏览器验收。

桌面及触屏连续拖拽复用了端口 5251 的既有 Web 导出，其 source-input 为 `0c648d292dcd6befc92012b3c01c34d57bb4ca8d892d2cb5f22adf2675679a02`；这证明新驱动可操作该连续跑步契约，不证明当前 13 文件候选已经重新导出。论坛全帖的 Gemini 场景生成与后续审阅仍在进行，尚未完成回填或验收。

## 2026-10-26 CI 分段集成与新导出复核

本文文件名与 2026-10-25 的历史记录保留。最新候选继续纳入 PR #174 从 `a179494` 推进至 `33cc4991b7d0ada3d65baaca146c62359f5fbf56` 的全部 20 个 CI、工具、测试与记录文件，按精确 tree/blob 校对并保留原提交祖先。下面只记录本轮已取得的证据，不代填后续远端检查、最终合并或部署结果。

- 原生 runner 新增只列计划、前置检查、北教定向与保守 changed profiles，默认完整检查仍保留；默认两个连续 worker，source/media/import 和 fixture producer 独占，消费者闭包与失败阻断保留。六次 catalog 与两次 oracle 的工作流重复调用移除后，仍由完整 runner 执行；同字节 GD 只在固定审核哈希一致时显式记录 `deduplicated`，未删除回归文件。`CHROME_BIN` 与 `USER` 的窄豁免采用 `33cc499` 最终版，环境值仍参与身份校验。
- Web 普通与 streaming 验收移至 `browser_baseline`，与地图/手机及图书馆 profiles 并行消费同一 sealed export/fixture；只保留一次生产导出。发布条件同时等待 build、baseline 和两类 profiles 成功，GPU/PCK 门禁保留。`verify_web_export.mjs` 同时保留 streaming 在 CDP 确认解除阻断后才清除故障身份的修复，以及 `3064f8c` 的 `phoneRecovery.pointer` 连续鼠标/触屏驱动，避免整文件替换丢失其中一段。
- 集成时现有 plan/list 测试实际发现 stdout 在 65,536 字节处截断：`console.log` 后立即 `process.exit(0)` 使管道尚未写完就退出。仅修 runner，等待 `stdout.write` 回调后再退出，测试断言未放宽。三个 CI 工具专项合计 **58 通过、0 失败、0 跳过**；`north-targeted` 的 91,131 字节计划与 full 的 325,543 字节计划均能完整解析且全部为 `not-run`，不存在的 `GODOT_BIN` 未被启动。日志为 `ci174-integration-targeted-flush-fixed.log`，原始失败日志继续保留。

基于干净提交 `3064f8c8839dad1c9d591ec3c04b8d5271941224` 的新导出进行精简浏览器复走，来源输入 SHA-256 为 `9f33417eb8d59c3aab8a0b7fc664573c83990b7d12a6202b5319bcf0b9edd5be`。这与前节复用 5251 旧导出的 919/920 项报告分开记录：

| 路径 | 结果 | 证据与边界 |
| --- | --- | --- |
| 新导出桌面与 390×844 触屏 | 596 项通过 / 2 cases | `precise-3064f8c-browser/result/web-acceptance.json`；状态栏、亮度、原生地图输入及手机往返的定向浏览器复核 |
| 横屏返回竖屏的原壳层负控 | 实际失败 | `precise-3064f8c-browser/rotation-fullmetrics-result/web-acceptance.json`；返回后 canvas/布局视口变为 `844×1827`，visual viewport scale 为 `0.462085…`，页面整体缩小；原生地图仍是 `960×540`，不是碰撞或源坐标变化 |
| canvas CSS 候选正控 | 507 项通过 / 1 case | `precise-3064f8c-browser/shell-css-candidate/web-acceptance.json`；同一新导出只替换壳层 canvas 尺寸规则，往返后 canvas 与视口均为 `390×844`、scale 为 `1`，`orientationRoundTrip` 为 true |

CSS 候选将 canvas 固定于视口并以 CSS 保持全宽全高，避免 Godot 上一横屏 inline 像素宽度再次撑大移动页面；Godot 继续拥有像素缓冲和输入变换。相应规则纳入 `godot_native/web/index.html` 候选，最终集成产物及远端 CI 仍需另行确认。证据汇总为 `precise-3064f8c-browser/focused-review.json`，原负控和早期键盘焦点驱动失败不抹除。上述结果不代表实体手机、其他浏览器内核或四章人工通关；本轮不声明论坛 Gemini 文案已回填。

以上路径均相对于外部 `755-tools/verification/room301-20261025/`。精确 PR #174 的 20 文件与 Git blob 校对清单保留在 `ci174-stage/CI174_STAGE_MANIFEST.json`。

## 提交范围

Current integration scope: 179 paths. Excludes node_modules, generated exports/cache, external QA and the standalone research library. Latest release checkpoint: [20261026](INTEGRATION_RELEASE_20261026.md).

```text
.github/workflows/deploy-pages.yml
.github/workflows/godot-native-ci.yml
ASSETS.md
README.md
docs/TESTING.md
docs/game-text-by-chapter.md
godot_native/.gitignore
godot_native/README.md
godot_native/assets/native/north_objects_20261025/blackboard_105_web_master.png
godot_native/assets/native/north_objects_20261025/bookcase_105_web_master.png
godot_native/assets/native/north_objects_20261025/chair_student_web_master_v2.png
godot_native/assets/native/north_objects_20261025/chair_v2_foot_qa.json
godot_native/assets/native/north_objects_20261025/desk_student_web_master.png
godot_native/assets/native/north_objects_20261025/lectern_105_web_master.png
godot_native/assets/native/north_objects_20261025/notice_105_web_master.png
godot_native/assets/native/north_objects_20261025/plant_105_web_master.png
godot_native/assets/native/north_objects_20261025/room301_archive_case_v1.png
godot_native/assets/native/north_objects_20261025/room301_index_drawer_v1.png
godot_native/assets/native/north_objects_20261025/web_batch2_provenance.json
godot_native/assets/native/north_objects_20261025/web_props_provenance.json
godot_native/data/native/campus-services-copy.json
godot_native/data/native/chapter4-native-source.json
godot_native/data/native/language-examples.json
godot_native/data/native/north-baseline-objects.json
godot_native/data/native/north-generated-objects.json
godot_native/data/native/room301-exhibit.json
godot_native/data/native/save_normalizer.json
godot_native/data/native/tiyi-interface-copy.json
godot_native/data/native/virtual-run-copy.json
godot_native/data/native/wechat-social-content.json
godot_native/data/worlds.json
godot_native/data/zh_text_revisions.json
godot_native/docs/CC98_GEMINI_COPY_20261026.json
godot_native/docs/INTEGRATION_20261025.md
godot_native/docs/INTEGRATION_RELEASE_20261026.md
godot_native/docs/NATIVE_VALIDATION_STAGES.md
godot_native/docs/NORTH_OBJECT_PREVIEW_20261025.md
godot_native/docs/NORTH_OBJECT_PREVIEW_ACCEPTANCE_20261025.json
godot_native/docs/ROOM301_EXHIBIT_20261025.md
godot_native/docs/TIYI_VISUAL_20261025.md
godot_native/docs/WECHAT_SOCIAL_20261025.md
godot_native/samples/north_independent_props/README.md
godot_native/samples/north_independent_props/capture.mjs
godot_native/samples/north_independent_props/play.gd
godot_native/samples/north_independent_props/run.mjs
godot_native/scripts/chapters/campus_network_account.gd
godot_native/scripts/chapters/chapter4.gd
godot_native/scripts/chapters/phone_utilities.gd
godot_native/scripts/data/cc98_store.gd
godot_native/scripts/games/virtual_run.gd
godot_native/scripts/games/virtual_run_motion.gd
godot_native/scripts/games/virtual_run_track.gd
godot_native/scripts/main.gd
godot_native/scripts/objects/chapter4_elevator_button.gd
godot_native/scripts/objects/kayak_world_adapter.gd
godot_native/scripts/objects/north_prop_scene.gd
godot_native/scripts/objects/room301_archive_art.gd
godot_native/scripts/objects/room301_archive_motion.gd
godot_native/scripts/objects/room301_archive_panel.gd
godot_native/scripts/objects/room301_archive_view.gd
godot_native/scripts/objects/room301_exhibit_adapter.gd
godot_native/scripts/objects/room301_exhibit_layout.gd
godot_native/scripts/objects/room301_exhibit_prop.gd
godot_native/scripts/presentation/north_generated_objects.gd
godot_native/scripts/presentation/world_object_focus.gd
godot_native/scripts/state.gd
godot_native/scripts/ui/c3_lake_app_context.gd
godot_native/scripts/ui/cc98_investigation_page.gd
godot_native/scripts/ui/chapter4_phase_layers.gd
godot_native/scripts/ui/chapter4_world_layers.gd
godot_native/scripts/ui/native_checkin_page.gd
godot_native/scripts/ui/native_learn_page.gd
godot_native/scripts/ui/native_library_pages.gd
godot_native/scripts/ui/native_tiyi_identity.gd
godot_native/scripts/ui/native_tiyi_presence.gd
godot_native/scripts/ui/phone_campus_services.gd
godot_native/scripts/ui/phone_chrome.gd
godot_native/scripts/ui/phone_entry_visual.gd
godot_native/scripts/ui/phone_pages.gd
godot_native/scripts/ui/phone_settings_chrome.gd
godot_native/scripts/ui/phone_system_icon.gd
godot_native/scripts/ui/tiyi_seven_art.gd
godot_native/scripts/ui/wechat_chrome.gd
godot_native/scripts/ui/wechat_message_bubble.gd
godot_native/scripts/ui/wechat_social_pages.gd
godot_native/scripts/ui/world_overlay_layout.gd
godot_native/scripts/world.gd
godot_native/shaders/north_prop_alpha_cutoff.gdshader
godot_native/tests/capture_north_independent_props.gd
godot_native/tests/capture_north_palette_alpha.gd
godot_native/tests/capture_north_wall_reveal.gd
godot_native/tests/capture_virtual_run.gd
godot_native/tests/fixtures/chapter3_narrative_source.json
godot_native/tests/fixtures/library_story_source.json
godot_native/tests/fixtures/native_validation_baseline_33cc499.json
godot_native/tests/test_canteen_queue_floor_tap.gd
godot_native/tests/test_canteen_waiting_portrait.gd
godot_native/tests/test_cc98_gamepad_exchange.gd
godot_native/tests/test_chapter4_phase_world.gd
godot_native/tests/test_chapter4_world.gd
godot_native/tests/test_compact_world_tasks.gd
godot_native/tests/test_early_games.gd
godot_native/tests/test_full_campaign.gd
godot_native/tests/test_lake_paddle_pointer.gd
godot_native/tests/test_mobile_direct_touch.gd
godot_native/tests/test_mobile_floor_room204_drag.gd
godot_native/tests/test_mobile_floor_route.gd
godot_native/tests/test_mobile_floor_route_orientations.gd
godot_native/tests/test_native_learn_page.gd
godot_native/tests/test_native_surface_modes.gd
godot_native/tests/test_native_validation_bundle.mjs
godot_native/tests/test_native_validation_registration.mjs
godot_native/tests/test_native_validation_runner.mjs
godot_native/tests/test_native_validation_shards.mjs
godot_native/tests/test_native_validation_workflow.mjs
godot_native/tests/test_north_generated_objects.gd
godot_native/tests/test_north_independent_props.gd
godot_native/tests/test_north_preview_gate.gd
godot_native/tests/test_north_prop_fail_closed.gd
godot_native/tests/test_phone_anchor02_tiyi.gd
godot_native/tests/test_phone_app_identity.gd
godot_native/tests/test_phone_chrome.gd
godot_native/tests/test_phone_clue_discoverability.gd
godot_native/tests/test_phone_library_login.gd
godot_native/tests/test_phone_navigation.gd
godot_native/tests/test_phone_utilities.gd
godot_native/tests/test_photo_brightness_consumer.gd
godot_native/tests/test_portrait_exploration.gd
godot_native/tests/test_portrait_scene_contracts.gd
godot_native/tests/test_room204_native_object.gd
godot_native/tests/test_room204_second_table.gd
godot_native/tests/test_room301_archive_main.gd
godot_native/tests/test_tiyi_visual_layout.gd
godot_native/tests/test_virtual_run_authority.gd
godot_native/tests/test_virtual_run_controls.gd
godot_native/tests/test_virtual_run_main_lifecycle.gd
godot_native/tests/test_web_acceptance_workflow.mjs
godot_native/tests/test_web_controller_fixtures.mjs
godot_native/tests/test_web_input_completion.mjs
godot_native/tests/test_web_phone_shards.mjs
godot_native/tests/test_web_save_diagnostics.mjs
godot_native/tests/test_web_streaming_fault_lifecycle.mjs
godot_native/tests/test_wechat_reference_ui.gd
godot_native/tests/test_wechat_social_pages.gd
godot_native/tests/test_zh_text_display.gd
godot_native/tests/verify_native_prepared_inputs.mjs
godot_native/tools/convert_media.sh
godot_native/tools/native_validation_aggregate.mjs
godot_native/tools/native_validation_bundle.mjs
godot_native/tools/native_validation_identity.mjs
godot_native/tools/native_validation_lock.mjs
godot_native/tools/native_validation_plan.mjs
godot_native/tools/native_validation_registration.mjs
godot_native/tools/native_validation_scheduler.mjs
godot_native/tools/native_validation_shards.mjs
godot_native/tools/native_validation_timings.json
godot_native/tools/prepare_web_controller_fixtures.mjs
godot_native/tools/sync_source.mjs
godot_native/tools/validate_native.mjs
godot_native/tools/verify_web_export.mjs
godot_native/tools/web_phone_recovery.mjs
godot_native/tools/web_phone_shards.mjs
godot_native/web/index.html
package.json
progress.md
scripts/ensure-ci-media-tools.mjs
scripts/test-ci-media-tools.mjs
scripts/verify-chapter4-temporal-maze.mjs
src/data/ChapterFourAlumniHonorWall.ts
src/data/act-one-bootstrap.content.json
src/data/cc98.post-default-history.json
src/data/cc98.posts.json
src/data/chapter3-qizhen-lake.content.json
src/data/chapter3-theater.content.json
src/data/chapter4-cc98.content.json
src/data/chapter4-three-floor-maze.layout.json
src/data/library-finals.content.json
src/scenes/phone/P02_CC98/index.tsx
src/scenes/rpg/ChapterFourTemporalMazeScene.ts
```
