# 7:55 楼梯追逐：镜头与输入修订（2026-10-18）

## 来源与范围

- 已发布基线：PR143 / B3，commit `19b7104910ffe842be4a4e162f0c59c8aac4c6cf`
- 本轮工作基线：2026-10-16 的 B4 full-body review 源包。保留它的全身步态、脚底接触、手机同手锚点和静态权重缓存
- 只修改独立楼梯预览的镜头和输入适配器。未接入主线；未改变正式进度或存档
- 未修改 model / physics / manifest、原 28 张 PNG、B4 gait / step-pose / guard-feedback 模块
- 移速 3.25 m/s、起跳速度 7.6 m/s、重力 20 m/s²、60 Hz 固定步长均保持原值

## 本轮变化

1. 原版已经按地面高度跟随，本轮保留该约束，并添加跳跃高度不影响镜头的回归
2. 前瞻采样前方路线位置，并对平台转角作三角平滑。左右换向在 0.5 秒内转换前瞻，跟随速度上限 6 m/s，避免瞬间甩镜
3. 横屏保持原画幅预算。窄竖屏至少保留 7.8 m 横向范围，容纳角色、下个落脚点和前方 4.5 m 警示距离
4. 竖屏按宽度选择内部渲染档位，390×844 不再降到 130×281，仍使用最近邻采样
5. 输入适配器加入 7 tick 的短跳跃缓冲，约 117 ms。只在落地后的合法输入边沿触发一次；过期或长按不会自动连跳
6. 快速松开移动触点不再额外制造一次跳跃。上滑、第二指和 Space 继续跳跃
7. 取消触摸、失焦、暂停、重试和实际画幅变化清除旧输入；恢复后仍按住的方向/Space 必须先松开，再重新按下

没有新增黑框、控制条、叠加提示或美术风格。保留逐级楼梯、十二段有限路线、重复 04、保安黄光与手机蓝光。

## 验证

正式证据位于交付包 `verification/`。完整仓库 runner 共 9 套、8,845 项检查，0 失败；独立源包不包含真实 State autoload，因此独立 runner 为 8 套。

- 真实 State、正式/备份/临时存档字节不变
- 四种画幅：1280×720、1024×768、844×390、390×844
- 每种画幅完整重放 3,485 tick，十二段/十二门均完成；角色头脚、下一个落脚点和前方 4.5 m 均位于归一化 4%–96% 安全区域
- 正向全程最大镜头位移 0.0562 m/tick；连续换向最大 0.1001 m/tick（6 m/s 上限，浮点舍入）
- 同一进度改变跳跃高度时，镜头目标完全不变
- 通过普通输入适配器的完整通关仍可由原始输入 proof 校验
- 新增 69 项覆盖短缓冲、过期、连续输入、松手、触屏、取消、失焦、旋转、换向、画幅及完整输入适配器通关

视频是实际 Godot 4.6.3 Compatibility / Mesa llvmpipe 渲染，60 Hz 离线 MovieWriter，每条约 32 秒。使用普通键盘和多点触摸事件：持续移动、松手六 tick、换触屏、第二指跳跃。不是人工试玩或实时 60 FPS 性能证明。

## 重现

独立包：在 Godot 4.6.3 打开 `preview/project.godot`，正常导入后运行。

Linux 命令：

    godot --headless --editor --import --quit --path preview
    node preview/tools/test_endless_stair.mjs

仓库：从上述 B3 commit 开始，叠加交付包的 `repository_overlay/`，按仓库原同步/导入流程准备素材，再运行：

    node godot_native/tools/test_endless_stair.mjs

原生录制脚本：`tests/capture_endless_stair_camera_input.gd`。横屏项目默认 1280×720。竖屏录制先复制独立预览，将副本 `project.godot` 的 viewport/window 默认宽高都设为 390×844，再加 `--resolution 390x844` 和用户参数 `--portrait`。MovieWriter 在启动时锁定项目 viewport，单独改 window resolution 不够。设置 `--fixed-fps 60 --write-movie output.avi`。录制 JSON 会记录原生帧数、输入事件和松手后的实际位移。
