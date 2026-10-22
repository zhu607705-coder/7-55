# 启真湖输入与镜头修复 · 2026-10-18

## 交付范围

基于 PR147 的 6db72961629c0bb737c714f82558415dbf3ca635 发布副本，使用新的云端工作目录。原副本未修改。本次仅修改独立 Godot 启真湖原型的输入、划桨呈现、镜头及 HUD；未接入正式章节、存档或主线剧情。未改地形、美术资产、任务条件、物理常数或路线。

## 实际修改

- 划桨：`set_paused(false)` 现在是幂等操作，不再每帧丢弃待播放的交替划桨，也不再清水花速度历史。真正暂停会清掉旧输入并冻结当前姿态；恢复后继续当前划桨。
- 输入：键盘与触屏统一进入现有四个模型输入。左侧拖方向；右侧按住划桨，释放后停止推进并完成当前收桨。只在触碰时画临时触控标记，无常驻操作按钮排。
- 目标：点按当前可交互目标优先于触控区域；在原有距离范围内自动减速，沿用原模型的低速与 1.25 秒操作条件。新划桨/转向、暂停、失焦、地图与画幅变化会取消旧触控或操作请求。
- 镜头：保持北向上，前瞻随速度变化；交互附近稳定构图。地图返回采用固定 0.24 秒过渡，避免从全图位置慢追；窄横屏限制前瞻位移以保证船体不被 HUD 遮挡。
- HUD：使用实际画幅像素布局，手机不再整体缩成小字。字幕独立于世界缩放；危险提示与近目标标签避开船体；目标优先命中，不被虚拟摇杆抢走。

## 可复核测试

- 修复前：待播放划桨 `pending_before=true` → 重复 `set_paused(false)` 后 `pending_after=false`
- 修复后：相同复现 `pending_before=true` → `pending_after=true`
- 新增输入、划桨、镜头、HUD 回归：70 项通过，0 失败
- 原有独立模型/路线审计：41 项通过，0 失败
- 原有模型测试与 30 Hz 路线测试通过
- 60 Hz 完整普通输入路线仍为 110.692 秒、25,559.99 像素、225 次划桨、2 次擦岸、0 次天鹅命中；与基线一致
- 六种实际画幅：1280×720、720×1280、1920×1080、960×640、390×844、844×390
- 窄横屏最高速度下八个航向均检查船体与顶部/底部 HUD、危险横幅的避让
- 独立代码审查发现的鼠标负 ID、手机整体缩小、窄横屏弹窗越界及高速危险条遮船问题已修复并复查

## 原生画面证据

`7-55_Qizhen_InputCamera_38s_AutomatedReplay.mp4`：Godot 4.6.3 / OpenGL Compatibility / Mesa llvmpipe 的真实引擎画面，1280×720、30 FPS、38 秒、1× 播放，无剪辑。画面带“自动输入回放”标记。

- 使用合成的键盘和触摸事件走实际场景输入处理器，不是人工游玩或真机触屏测试
- 从原始码头出生位置连续运行；未改写位置、朝向、速度、时间或目标进度
- 展示左拖方向、右按划桨、松开、地图打开/返回、暂停/恢复、点按湖面信号及天鹅预警
- 实录累计 70 次物理划桨与 70 次视觉划桨，0 擦岸、0 天鹅命中；完成第一个检查目标并继续行驶
- 地图约在第 6–7.5 秒，暂停约在第 13–14 秒；最后游戏时间约 35.467 秒
- 这是局部输入验收录像，**不是完整路线通关视频**；完整路线由独立模型测试验证

`01–09` 静帧检查了桌面、手机横竖屏、标题、地图、暂停与高速危险提示。文件名含 `fixture` 的图片使用显式设置的目标/速度/危险状态，仅验证画面布局，不构成实际任务或通关证据。`replay-*.png` 则来自连续录制。

软件渲染与固定帧率录制不代表真机 GPU 性能。没有进行触屏硬件、不同手机系统或人工手感验收。

## 复现

Godot 4.6.3，先导入项目，再运行：

```
godot --headless --path . --script res://tests/reproduce_pause_regression.gd
godot --headless --path . --script res://tests/test_input_camera.gd
godot --headless --path . --script res://tests/test_large_world.gd
godot --headless --path . --script res://tests/audit_large_world.gd
godot --headless --path . --script res://tests/test_route_30hz.gd
```

仓库发布版本保留原有测试的 Godot `user://` 输出路径，无需建立项目父目录。新增测试默认写入项目内 `test-output/`；可传 `-- --evidence-dir=/absolute/path` 改为指定输出目录。

原生回放：

```
godot --path . --audio-driver Dummy --fixed-fps 30 --write-movie replay.avi --script res://tests/capture_input_replay.gd
godot --path . --audio-driver Dummy --script res://tests/capture_input_layouts.gd
```

必须有可用显示服务器。此次使用云端 Xorg dummy + llvmpipe；没有操作用户的电脑。

## 后续边界

仍需实际手机与人工手感检查。项目保留原型的中心加圆周水域碰撞、低速交互与朝北系泊规则。本次提交仅更新 Draft PR #147 的工作分支；未合并或部署。
