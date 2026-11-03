# 新照片内容技术验证

本报告是静态资产技术检查，不是用户视觉认可，也不是浏览器/GPU性能验收。

- 新增独立源：20 件；每件 3 个独立源 LOD，共 60 个真实解码 runtime LOD。
- LOD0 去重总三角：200230。不把同一DP800的两次摆放重复计为新源。
- 部分复杂仪器高于 build_asset 请求面数；误差约束阻止进一步简化。以下列实际解码数，不宣称达到Web预算。
- plain/Draco 最大包围误差：2.68220901489e-07 m。
- 独立检查：5834 项，0 失败。20 个 .blend 均单独只读打开，检查后hash保持。
- DP800是系列候选：官方机身W239×H157×D418mm，包含前部突出物总深429.5mm；另外五台仅照片比例估计。
- 六个仪器的实际mesh布局互异；没有把七台都换皮为同一壳体。
- 开PC箱确有独立板托、四角框架和内部线束，+X侧无整块封板。四旋翼确有四个不同位置的电机和两条起落架。
- 恢复基线 fe75c9aa98abed4a69770e92c1f7a9be82db3a64：570 个旧source/runtime文件逐字节保留，含48个旧blend。它是本轮包恢复snapshot，不是原82abe Git对象。

| 源ID | LOD0 | LOD1 | LOD2 |
|---|---:|---:|---:|
| photo_instrument_c1_wide_scope_candidate | 12312 | 5432 | 1904 |
| photo_instrument_dp800_series_candidate | 21620 | 9450 | 3162 |
| photo_instrument_l1_dark_signal_candidate | 26526 | 11496 | 1940 |
| photo_instrument_l2_light_test_unknown | 32276 | 13432 | 2156 |
| photo_instrument_r1_dark_rf_candidate | 23306 | 10470 | 2204 |
| photo_instrument_r2_light_test_unknown | 28230 | 11978 | 2222 |
| lab_closed_thin_device | 908 | 508 | 212 |
| lab_desktop_small_items | 4212 | 2184 | 828 |
| lab_hard_transport_case | 2632 | 1512 | 528 |
| lab_open_pc_chassis | 4976 | 2624 | 1008 |
| lab_stepped_monitor | 2156 | 1160 | 452 |
| lab_unknown_white_case | 1564 | 800 | 300 |
| lab_window_unknown_enclosure | 1432 | 764 | 296 |
| photo_black_pouch | 564 | 324 | 132 |
| photo_blue_rc_charger_unknown | 4700 | 2700 | 616 |
| photo_loose_test_leads | 5776 | 2880 | 1328 |
| photo_quadrotor_unknown | 8796 | 4532 | 1852 |
| photo_solder_station_set | 3128 | 1684 | 728 |
| photo_wire_spool | 14176 | 7108 | 144 |
| photo_yellow_black_handheld_shell | 940 | 540 | 220 |

## 未测范围

- 未做浏览器加载、真实设备帧时、GPU内存、网络时延或并发实例性能测试。
- 未验证电气功能、机械承重、物理仿真或被照片遮挡的结构。
- 候选品牌/型号、估计比例与外观保真度仍需用户认可。
- 组合报告独立于源技术报告，详见 composition_validation.json。

validation.json SHA256: 04c4941ad075a9104007606901bbe881a326de6455526fa0e3df82e04654d7eb

## 两组组合检查

- 图3实验室19实例；电子台44实例，共63次摆放，不能计为63个新源。
- sourcePath/sourceSha256逐项匹配，实际native顶点按实例变换；坐标为Blender Z-up、米。每个scale和materialOverrides记录在报告中。
- 落脚检查无异常（容差下穿3mm、上浮15mm；少量线缆厚度在此范围）。使用声明支撑平面及XY范围，不是机械承重验算。
- >4mm三轴包围盒重叠后再用真实三角面BVH。两面均需跨过对方面平面0.01mm，剔除共面支撑接触。
- 仅剩8对明确列出的架框/洞板固定安装嵌接；未声明相交0。不能表述为所有模型零相交。
- 图3的5对穿插、白壳穿地和箱悬空已纠正；电子台上下洞板、线轴/散线及架/挂盒穿插已纠正后复测。
- 筛查不检测完全包容于另一封闭体内的情况，也不替代用户视觉认可。

composition_validation.json SHA256: 039f641499d948c7918ca8141d3976328d4a446044fd405f5c6a6f944e56882f

复现：先运行 node pipeline/build_photo_evidence.mjs；再运行 node pipeline/test_photo_evidence.mjs；最后运行 node pipeline/test_photo_evidence.mjs --compositions-only。运行前需确认所有source已freeze，依赖按pipeline/package-lock.json恢复。
