# 7:55 · 手机走进微缩校园 — 隔离概念试镜

**Godot 4.7.1 / GL Compatibility。未接入正式游戏，仍为占位美术原型。**

### 2026-10-28 兼容修复与真实渲染检查

先正常 merge `main 80ad46aa`（含 PR186 空间规则），再同步新 `main 533ed6b`（含 PR187 未来学习中心3F）进入原工作分支，不重写历史。后一次无文本冲突；两处样例互不改写，新增楼层132项、手机1329+36项和项目归属检查均复核通过。
共享扫描器保留 main 的项目 ID 注册；正式地图、空间规则、入口与剧情代码相对 main 均未修改。
新的 `test_input.gd` 通过普通触屏/鼠标事件操作可见控件。它补测取消触摸不会误重播、暂停恢复、重复跳过和减弱动态；不会用 `pressed.emit()` 代替输入。
检查发现的原型局部问题已修正：取消抬手不再激活按钮；HUD 使用内容所需高度，标题不再横跨桌面画面；视角由42°微调至44°，保留同一运镜路径和世界坐标。

`.github/workflows/phone-campus-preview.yml` 在 GitHub 托管 Xvfb/GL 上运行同一检查，并保存三种窗口的实际图像和390×844连续播放视频。
视频由正常触屏点击重播开始，不按时间点拼图；静帧另用于检查六个节拍。工作流输出源 SHA、renderer、输入日志及视频元数据。
[GL run 40613832313](https://github.com/zhu607705-coder/7-55/actions/runs/40613832313) 已在 `50e7067` 实际完成：18张节拍图、6张输入状态图和11.67秒竖屏视频，48项图形输入检查通过。已查看全部24张图及整段视频的47个抽帧：小人动作可见，主体未被HUD遮挡。后一次main同步没有改变样例运行代码、资产或GL工作流；新head的CI仍单独跟踪，不能用旧head绿勾代替。当前状态见 [PR176](https://github.com/zhu607705-coder/7-55/pull/176)。
软件 GL、模拟触控和手机尺寸不等于物理手机验收，也不表示占位模型成为最终美术。
`ACCEPTANCE_20261026.json` 保留的是旧 head 的历史记录，不作为本次画面的证明。

这是用户要求的「2D 软件界面 + 玩具尺度 3D 小人」技术原型，不是校园地图替换，也不是新的剧情入口。
没有使用 Three.js，没有修改正式入口、控制器、存档、碰撞、校园地图或生产导出配置。

## 打开

从仓库根目录执行（将 `GODOT_BIN` 换成自己的 Godot 4.7.1）：

```sh
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/phone_to_campus/run.mjs
```

启动器验证引擎版本，按原文件 SHA-256 复制现有 **晨札像素 Regular** 字体及 OFL 说明，导入独立项目，再运行预览。
字体只是复用，不是新生成的角色资产。XDG 缓存与项目用户目录隔离，不读取正式存档。
首次准备后，也可打开 `preview/project.godot` 按 F6/F5；无需完整游戏 source sync、媒体转换或 npm 安装。
单独分发的准备后源码包已含字体和许可证，可以直接用 Godot 打开。

| 操作 | 输入 |
| --- | --- |
| 从头重播 | 重播按钮 / R |
| 暂停、继续 | 暂停按钮 / Space（按钮聚焦时仍有效） |
| 到达稳定尾帧 | 跳过按钮 / Esc |
| 无运镜、无弹跳的静态尾帧 | 减弱动态 |
| 激活聚焦控件 | Enter；Tab 切换焦点 |

失去应用焦点会暂停；回来后需要明确继续。关闭减弱动态仍保留尾帧，不突然自动播放。
预览不自动循环，不发声。所有控件在独立 CanvasLayer 中，不经过 3D 景深或模糊。

## 连续镜头

```text
430×860 手机界面上的薄平面小人
            ↓ 同一组真实 MeshInstance3D，脚点不换位
       撑起 → 蓄力 → 跳出 → 落地压缩/回弹
            ↓ 同一个 Camera3D，连续三次贝塞尔路径
       沿桌面微缩小路走向校园意象 → 稳定尾帧
```

| 秒数 | 节拍 |
| --- | --- |
| 0–1.3 | 屏幕图标，薄深度、无光照材质 |
| 1.3–2.5 | 逐渐立起并恢复体积 |
| 2.5–3.0 | 蓄力压缩 |
| 3.0–4.0 | 抛物式跳跃、转向校园 |
| 4.0–4.6 | 脚点落地、压缩、衰减回弹 |
| 4.6–8.8 | 关节摆动步行，镜头低位跟进 |
| 8.8–10.2 | 镜头稳定停留 |

`timeline.gd` 是按绝对秒数采样的纯函数；`transition.gd` 只用一个与节点绑定的 Tween 驱动它。
重播/跳过/取消会杀掉旧 Tween；代号检查拦截过期回调。`ended(reason)` 只报告预览结果，**不代表剧情完成**。
未来接入时必须由现有 controller 先决定是否允许进入校园，再选择是否播放这个非权威表现；播放、跳过、减弱动态均不能创建解锁事实。

## 材质与边界

- 真实 3D 原语组成的占位小人、背包、树、校门和楼体；没有把平面图拼成假截图。
- 小人与建筑**不是已批准的最终美术，也不声称准确还原真实校园**。屏幕中有明确占位说明。
- 暖色低角度主光、冷色补光、粗糙玩具材质及渐变接触阴影；真实最终观感需要图形会话检查。
- 为兼容现有 Compatibility/Web/mobile 路径，**不启用景深、运动模糊、SSAO、SDFGI 或 compositor**。不把不支持的特效当作必需项。
- 3D 体积变形仅存在于这个明确的玩具转场实验，不修改正式游戏像素角色比例或镜头规则。
- `phone_to_campus/.gdignore` 将整个预览隔离于父 Godot 项目的资源扫描；Web production 原本也排除 `samples/*`。
- 不添加全局输入映射、autoload、State、SaveStore、路由、音频、外部依赖或联网行为。

## 验证与取图

```sh
# 独立导入 + 有失败退出码的行为测试
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/phone_to_campus/run.mjs --test

# 必须在有真实图形 renderer 的授权执行环境运行；不得加 --headless 冒充画面验收
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/samples/phone_to_campus/run.mjs --capture /tmp/phone-campus-captures

# 已准备并导入后，在受支持图形会话中检查真实鼠标/触屏和输出尺寸
/path/to/Godot-4.7.1 --path godot_native/samples/phone_to_campus/preview \
  --script res://test_input.gd -- --require-rendering --output=/tmp/phone-campus-input
```

测试覆盖时间轴边界、平面→立体、跳跃/回弹、帧率无关采样、暂停/恢复/失焦、聚焦按钮下的 Space、连点重播、重复跳过、取消、减弱动态切换和销毁清理。
真实 Window 尺寸为 `1280×720`、`390×844`、`844×390`；**不在测试中改 content_scale_size 伪造响应式行为**。控件最小高 44 逻辑像素。
这些是布局/行为检查，不是像素观感、GPU 性能或物理手机验收。

捕获工具记录真实引擎、display、adapter、renderer 和 18 张六节拍/三尺寸画面。它在 headless/dummy 上非零退出，不输出伪截图。
**历史限制（2026-10-26）**：当时 dot 云执行器创建显示失败，没有真实截图；相关旧收据原样保留。2026-10-28 未重试被拒绝的本地路线，而在已授权的 GitHub 托管 Xvfb/Mesa 上完成上述真实GL采集。小人/校园仍为原语模型，材质偏亮、主阴影较硬；这次确认动作与输入能显示和工作，不代表最终美术认可。

跨 PR 验证器会自动发现嵌套 `project.godot`，按各自 `res://` 根逐一检查；即使父目录含 `.gdignore` 也不漏掉独立源码。手机样例在现有 cross-PR runtime 中另行导入并跑专项，原正式 suites 保留。命名空间负例确认：父项目存在同名文件不能掩盖子项目缺资源。

旧检查见 `ACCEPTANCE_20261026.json`，10月28日本地兼容检查见 `COMPATIBILITY_20261028.json`，已检查的GL证据见 `VISUAL_REVIEW_50e7067.json`。每份收据只说明其注明的源码/环境，不代表最新head的全部门禁、正式版本或物理手机验收。

## 参考

仅咨询，没有复制上游脚本或美术：Godot 官方 [Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html)、[StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)；用户指定的 [gamedev skills router](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/38a4c2500eeb5ff9ac084336b8f66108069d2f8d/router/SKILL.md) 及 Godot animation、camera systems、headless testing 三项。
代码遵循仓库 Apache-2.0；字体保持原 OFL。
