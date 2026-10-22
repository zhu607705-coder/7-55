# 原生录制证据（提交前已交付的历史录制）

最终交付录像：7-55_Qizhen_LargeWorld_InputReplay_1x.mp4

- Godot 4.6.3 原生场景，OpenGL Compatibility / llvmpipe
- 1280 × 720，30 FPS，正常 1× 播放速度
- 全程连续，无剪辑；自动输入控制器经普通输入接口操控
- 录制过程未改写位置、朝向、速度、游戏计时或目标状态
- 最新游戏时间 108.642 秒；全片另含约 4 秒完成画面
- 25,553.66 游戏像素 / 220 次交替划桨 / 0 擦岸 / 0 命中 / 2 次天鹅预警冲刺
- 五个玩家可读阶段由九个导航目标组成；检查、捞取、系泊均需低速按住交互
- 该视频是自动输入验收回放，不是人工游玩或实地船行视频

01-overview-runtime.png 等定点地形画面由独立检查脚本设置观察位置。它们只作为地图呈现证据，不能证明连续路线。连续通关以完整录像及 NATIVE_CAPTURE_RESULT.json 为准。

独立审计的 60 Hz 运行完成时间为 110.692 秒。两次运行的输入采样频率不同，路径细节和接触次数略有不同。

视频已单独交付，本仓库不包含视频、逐帧图像、输入日志或录制缓存。若需重新录制，可使用 Godot Movie Maker：

`godot --path . --fixed-fps 30 --write-movie /absolute/output/route.avi --script res://tests/capture_full_route.gd`

请使用可写的绝对输出路径与支持图形渲染的环境。辅助 JSON/PNG 输出在 Godot `user://` 数据目录。录制脚本输出自动输入回放标记；定点截图脚本不是通关证据。
