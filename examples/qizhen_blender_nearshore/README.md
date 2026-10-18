# 7:55 · 启真湖 Blender 近岸可玩样段

本包是教学浮码头附近的一段美术与操作样段。默认流程为：划离平台 → 近岸低速取回防水袋 → 朝北接近护舷并系泊。原大地图的九阶段路线仍可从标题或地图按 F 进入。没有新增剧情，也没有把短路线当作全湖完成。

## 打开与操作

1. 用 Godot 4.6.x 导入 `preview/project.godot`，运行主场景
2. Enter / 点按开始近岸样段；标题或地图按 F 进入原全湖场景
3. W / 空格划桨，A / D 转向，S 刹停，E 低速取物/系泊
4. 触屏左侧拖方向，右侧按住划桨；靠近目标后直接点按
5. M 查看全湖地形，P / Esc 暂停，R 重试

这不是独立动画：控制、航速、转向、刹停、碰岸、取物和系泊由 Godot 实际游戏逻辑驱动。当前没有真正登岸或步行功能，不演示虚假的上岸动作。

## 文件

- `preview/`：独立 Godot 工程；运行无需安装 Blender
- `source/qizhen_north_bank.blend`：可编辑岸景、浮台、艇壳和生成材质
- `source/build_lake_sample.py`：确定性 Blender 重建脚本；输出两份 GLB
- `source/build_shore_distance.py`：从游戏湖岸生成局部浅水风格距离图
- `verification/`：碰撞、投影、输入、遮挡和运行性能证据
- `preview/docs/REFERENCE_AND_SCOPE.md`：原湖形参考及不确定性

## 重建

在本包目录运行：

    python3 source/build_shore_distance.py
    blender -b --threads 4 --python source/build_lake_sample.py
    godot --headless --path preview --editor --import --quit

需要 Blender 4.3.x、Godot 4.6.x；距离图脚本使用 Python、NumPy 和 Pillow。没有使用 Blender 第三方插件或外购模型/纹理。源 `.blend` 保留分件，GLB 导出按材质合批降低运行绘制开销。贴图已内嵌进 GLB；编辑源中的贴图也已打包。

## 真实资料与艺术化边界

湖形、南岛及主要方位沿用上一大地图依据公开校园图描出的轮廓。蓝色模块式教学浮码头有浙江大学报道依据，但本样段的具体形状、尺寸、连接位置、石驳岸细节、步道、植物和图书馆立面均为游戏艺术化设计。浅水色差只是视觉样式，不是实测水深，也不提供实地通航建议。

- 校园航拍：[浙江大学，2018-04-10](https://www.zju.edu.cn/2018/0410/c32747a1513553/page.psp)
- 校园图：[浙江大学人力资源处，2024-05-17](https://hr.zju.edu.cn/cn/2024/0517/c29598a2918345/page.htm)
- 蓝色教学浮码头：[浙江大学，2023-03-24](https://www.zju.edu.cn/2023/0324/c75118a2732446/pagem.htm)

## 本次范围

本次细化的是北岸近岸样段，未把整张 9000×16000 地图全部做成精细场景。样段模型增加了显式可选的艇壳/平台接触检测；原全湖模型未启用这些回调时，原固定步长和所有推进、转向、阻尼参数不变。详见 `preview/docs/BLENDER_SAMPLE_TECHNICAL.md`。

## 录屏与验证解释

24 秒视频由 Godot 原生渲染器输出，以普通键盘/触屏输入运行 1× 玩法。它不是手动游玩证明，也不是 Blender 离线动画。回放逐帧验证最大位移、转角和进度跳变，截图对应实际游戏帧。软件光栅器性能单独记录，不能据此推断手机实机帧率。
