# 二楼太阳能竞赛与机器人往返

**后续修订：** 本文的早期按键／按钮近景已被用户否定。当前工作区采用[场景物件与实体操纵杆](OBJECT_INTERACTION_20261029.md)；本文保留机制和前一轮证据，不能作为当前操作方式的说明。

本轮将用户批准的两套机制接进既有原生房间评审场景。基线 `4c5fa5f147ce3cdd492895a97f9cca69fd415efd`，工作分支 `codex/flc-transcript-level-design-20261029`，未提交工作区。引擎与 Web 模板均为 Godot 4.7.1。

## 实际入口与操作

- 方程式车队：现有 `formula_workbench_0`。靠近按 Space，或点击桌面自动走到可站立侧边。1 改板角，2 换板尺寸，3 换传动，4 换日照条件，Space 同时发车。鼠标和触屏可点对应按钮。两车完整跑 30 秒，累计距离超过基准才完成；格数是教学模型的单位，不能预测真实车辆。
- ASABE：现有 `robotics_workbench_30`。相同的靠近/点击入口。点选或方向键选择模块，R 旋转，C 在直轨/转弯/单向模块之间更换；返程口可选左/上/下，N 分步或 Space 连续。实际装货→载货→卸货→空车返程；送达本身不算完成。可换双向共用段，也可搭上方或下方回路。
- Z 撤回配置，H 主动打开并逐层请求提示。查看记录只显示已发生的实跑：小车记录入影、复光、终点差距；机器人叠加真实路径与停点。提示和记录不替玩家安装或判定成功。

桌面出现独立透明小车/机器人，与近景使用同一生成母版；房间轮廓、楼层连接、门窗、脚框、原生镜头及原有工作台位置没有改动。退出返回原位。所有物件、声音及记录的完成权限仍由规则模型控制。

## 状态与边界

`solar_race_model.gd` 使用 0.05 秒固定步长、同一光照序列和同一配置版本。中途换件或失焦会中止该场；只有完整场次写本会话最佳。两车初始相同会打平，不预设一个假的起步反超。数字模型枚举有多个胜出组合。

`robot_delivery_model.gd` 检查每个相邻模块的实际接缝与进入方向；车在不通的入口前停住，不瞬移回起点。四向图集尺寸、等比缩放和车头前端由 `motion_prop_metrics.gd` 与绘制共用；受阻时整个可见车头保持在接缝外至少 2 个逻辑像素。装卸与行驶是可暂停阶段，货物独立移动；轮子跟随位移，车头通过四张固定视角贴图换向。修改轨道使旧试验失效，重新把可复用货物放回安全起点；完成后原配置仍可再试。失焦暂停机器人，回到页面后需主动继续。

两个模型完全不读写正式章节、背包、任务或持久存档。关闭页面会丢失会话配置和纪录。机器人“改变卸货站位置”仍是设计中的进阶变式；当前已实现改变返程出口和整条回路。触控是桌面模拟触摸事件验收，尚未验证物理手机。

## 复现

```sh
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/future_learning_center/run.mjs --motion-test --headless
FLC_CAPTURE_DIR=/absolute/captures FLC_MOTION_CHECK=1 GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/future_learning_center/run.mjs --resolution 1280x720
FLC_CAPTURE_DIR=/absolute/mobile FLC_MOTION_CHECK=1 FLC_TOUCH=1 GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/future_learning_center/run.mjs --resolution 844x390
GODOT_BIN=/path/to/Godot-4.7.1 GODOT_WEB_TEMPLATE=/path/to/4.7.1.stable/web_nothreads_release.zip node godot_native/samples/future_learning_center/build_web.mjs /absolute/web-review
```

独立 Web 入口接受 `?area=solar`、`?area=robotics`、`?area=team`，只把评审玩家放到相应操作台的合法侧边，不自动通关。进入后按 Space 或点击桌面。

## 素材与验证

`assets/puzzles/provenance.json` 保存生成工具、完整提示、原文件及哈希；`frames.json` 保存四向实测裁切区域。两张 RGBA 母版均 1254 × 1254；原始字节保留，使用最近邻过滤、统一等比缩放，不旋转整张 2.5D 图片。它们是生成的像素风素材，未声称严格量化为 32 色。

自动化输入在真实原生窗口按正常实时速度完成 30 秒竞赛和往返。模型、输入、空间回归、Web 构建及浏览器行为分别记录在 `MOTION_PUZZLES_VERIFICATION_20261029.json`。它们不代表全部 25 间房间、最终建筑美术、真实新玩家难度、正式发布或实机验收。

`.impeccable/review/flc_motion_20261029/robot_delivery_actual.mp4` 为 24 秒、960 × 540、30 FPS 的原生渲染演示：先展示返程受阻，再搭上方回路，完成卸货与空车归位。它按同一模型的固定 30 Hz 步长采集 720 帧；另有正常实时输入验收，不把定步长录制当作性能或真人试玩证明。独立 Impeccable 复核对车头停位及对比度两项修复给出 `ship`，并完成与既有原生界面的文档比对。

全楼提示与难度仍见 `../design/GUIDANCE_AND_DIFFICULTY_20261029.md`。Argon 审阅包已经准备，入口尚未确认；本轮本地审查不冒称 Argon 意见。
