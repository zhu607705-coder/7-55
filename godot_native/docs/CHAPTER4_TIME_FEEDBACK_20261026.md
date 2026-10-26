# Chapter 4：三处已获准事实的短动画

这是接入正式 `Main` 的原生 Godot 表现微调，不是新小游戏，也不是 PR176 的独立玩具转场。正式入口、Chapter4 控制器、State、存档格式、地图与碰撞均未修改。

## 已接入的三段

| 已发生的控制器事件 | 新增反馈 | 时长 |
| --- | --- | --- |
| 首次获得 `a1_time_route_compared` | 两条记录短移对齐：本地回放 **07:47:05** / 教室记录 **07:55:00**，标明相差 **7分55秒**；窄手机改为上下排列；竖屏世界的横向视口则放在略过按钮左侧 | 1.1秒 |
| 原900ms投影证明通过，首次获得 `room204_projection_completed` | 复用204源残影与当前已完成桌椅的实际槽位，短暂贴合、淡去 | 1.2秒 |
| `c4_install_minute` 获准并进入 `morning_checkin` | 在原钟面轴心把分针从54分扣到55分，再出现手机07:55同步符号 | 1.1秒 |

- 比较的是两条记录，不把数字改成相同。开场手机的07:55:23仍是未更新读数；电梯六秒仍是独立的通行证明。
- 204反馈只在已完成布局且原投影证明接受后出现，不提前揭示摆法；没有把3F参照房画成204历史实景。
- 安装瞬间由原控制器提交可信07:55。动画不暂写旧时间，不推迟或重复提交事实。
- 校园卡和签到纸仍各自交付，二者都获准后才到原楼外收尾；原5800ms/减弱动态3600ms及两问未改。

## 输入与生命周期

只有“略过动画”按钮可接收输入；鼠标、触屏点击，或Tab定位后Enter/空格可略过。没有全屏输入罩，也不截取玩家普通移动/交互按键。按钮不抢焦点；键盘略过后恢复原可见焦点，真实下一次Space仍可进入世界输入。

动画由 `State.action_completed` 的前后事实差异触发，没有 `State.act`、写存档或完成证明回调。已经获得的事实、重复观察、普通刷新和读档不会自动重播。换场、楼层/阶段/房间/页面变化、状态字典替换、新游戏/弹窗、控制中心、退出均取消；失焦暂停；减弱动态直接保持静态结果。

Host位于Main，但绘画以当前可见surface为裁剪边界。世界坐标显式经过既有SubViewport→显示容器映射；手机比较不会强制打开世界。钟面与家具保持原源图、统一比例、坐标和碰撞。

## 运行与录制

依赖仓库现有资产；不是另一个可独立分发的完整游戏。准备源文件后，用官方Godot **4.7.1**：

```sh
node godot_native/tools/sync_source.mjs
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/tools/run_chapter4_time_feedback.mjs --test
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/tools/run_chapter4_time_feedback.mjs
```

QA场景加载真实Main与原控制器。底部1/2/3重播三个**明确标记的源检查点**，可选择减弱动态。它不是连续通关证明。运行器复用仓库 `createNativeTestSandbox`：Linux隔离XDG；macOS使用独立工程配置和用户目录；未支持的平台拒绝启动，而不是误用正式存档。

有正常图形显示的受支持环境可录制真实引擎画面：

```sh
# 三种窗口 × 三段 × 三个时间点，真实viewport PNG与capture.json
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/tools/run_chapter4_time_feedback.mjs --capture /tmp/c4-frames
# Godot自带Movie Maker；自动播放三个源检查点
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/tools/run_chapter4_time_feedback.mjs --movie /tmp/c4-feedback.avi
```

无真实renderer时录制非零拒绝；不要把空帧/不完整影片当作视觉证明。QA控件在底部换行，不盖住正式略过按钮。生产导出不能开启该检查点场景。

## 验证边界

- 新专项：实际Main树、三种真实Window尺寸1280×720/390×844/844×390、窄手机字宽、SubViewport映射、鼠标/键盘/触摸略过、后续Space、重复/取消/重载/新游戏/同帧转场等。
- 保留900ms投影、钟面交互、卡/纸独立接受、收尾存档与实际Main设备输入回归。专项数字和最终文件/日志哈希见同目录验收收据。
- **新版完整外观验收仍待重录。** 本机显示Unix socket/沙箱限制未绕过、未重试，也未使用用户电脑。后来在仓库既有受支持 GitHub-hosted Mesa/llvmpipe 路线上录到真实引擎影片（[run40266176335](https://github.com/zhu607705-coder/7-55/actions/runs/40266176335)，游戏head40b2134）：桌面核对与分针同步可见；竖屏差值与原通知相交，204 QA机位站在了东侧走廊。本次仅修反馈紧凑排布与QA检查点机位，并补真实HUD包络和12槽位可见性测试；原通知、正式镜头与地图不改。旧视频不代表本修订已验收，Headless通过也不等于物理手机验收。
- 最新main与PR175兼容试验、远端精确head的CI状态在本PR说明单独记录；未合并、部署或请求自动代码审查。

实现参考了仓库指定的 [Godot动画技能](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/38a4c2500eeb5ff9ac084336b8f66108069d2f8d/skills/godot/godot-animation/SKILL.md)；保留4.7.1与GL Compatibility，不增加引擎或第三方依赖。
