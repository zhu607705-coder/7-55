# 启真湖 Blender 近岸样段

在 Godot 4.6.x 中导入本目录的 project.godot，直接运行。

默认入口为 `scenes/blender_lake_sample.tscn`：划离蓝色教学浮码头，近岸减速取回防水袋，再贴近护舷并系泊。标题或地图按 F 可进入未替换的原全湖九阶段场景 `scenes/qizhen_large_world.tscn`。命令行 `--full-route` 同样直接进入原全湖场景。

W/空格划桨，A/D转向，S刹停，E操作，M地图，P/Esc暂停，R重试。触屏左侧拖方向、右侧按住划桨，目标附近点按操作。查看地图、暂停、失焦和屏幕旋转会释放旧输入。

当前为可玩美术样段，不是完整全湖美术重制。没有真正登岸动作。具体码头结构与岸边设施是游戏改编；实地位置/尺寸/水深/通航条件未核实。

完整源码包的上级 README 说明 `.blend`、GLB 重建方法和测试证据。仅导入本 Godot 目录运行，不需要 Blender。

技术说明：`docs/BLENDER_SAMPLE_TECHNICAL.md`
资产说明：`docs/ASSET_PROVENANCE.json`
地理参考：`docs/REFERENCE_AND_SCOPE.md`
