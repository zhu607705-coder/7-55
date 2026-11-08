# 校园来信：四个第一人称三维样段

Godot 4.7.1 独立可游玩预览：图书馆座位使用、柳湖观察、纸桥试载与雕塑投影与来信投递。第一人称负责实际玩法，可切换第三人称场景总览；返回后恢复原位置。各物件有独立模型、材质与操作范围。默认画面不显示物品文字、悬停说明或底部解说，保留场景切换、总览、重来与移动摇杆。

| 样段 | 物件操作 | 完成与恢复 |
| --- | --- | --- |
| 空着的座位 | 点击终端预约、拖校园卡到感应区、点击自己的座椅落座 | 坐下切换到桌前眼高，移动时起身；离开后在终端释放。其他人的预约不受影响 |
| 柳湖交接 | 拖动两只手轮调节方向和俯仰，走到能看清点位的位置观察 | 校准后记录三个不同点位，重复记录不增加进度 |
| 纸桥来信 | 拖动两个支点、点击纸边折起、分别拖动三枚砝码 | 平纸跨度过大可试载失败，点击托盘收回砝码后重试 |
| 母校之光 | 拖灯座校准真实投影，走到侧面的观察位置，拿信并投入实体信箱 | 校准、避开光路、拾取与近距离投递分别校验；总览不代替实际操作 |

## 运行

在仓库根目录执行：

```sh
npm ci --ignore-scripts
node godot_native/tools/sync_source.mjs
GODOT_BIN=/path/to/Godot-4.7.1 node godot_native/tools/build_campus_letter.mjs
node godot_native/tools/serve_web.mjs --directory=godot_native/exports/campus-letter-web --port=8795
```

浏览器地址为 `http://127.0.0.1:8795`。构建脚本检查引擎版本，复制最小资源引用集，运行专项原生检查，再导出独立 Web 项目。生成项目位于 `exports/campus-letter-project`，不更改主工程入口或生产导出预设。横屏逻辑画面为 1280×720，保持 16:9；手机竖屏显示转横屏提示。

桌面和触摸都可以拖空白处转头、点击地面或使用摇杆行走，操作可见物件。键盘只保留辅助移动路径。多指操作不会抢夺已经按住的物件；失焦、旋转屏幕、取消与离开场景会释放输入。

## 模型与材质

可编辑源为 `authoring/campus_objects.blend`，由 `tools/build_detail_assets.py` 生成并单独导出各对象 GLB。家具曲面、木板倒角、灯具关节、玻璃透镜、旋钮、接缝和书页均为独立几何。现有玻璃雨棚与柳树继续复用；雕塑手部从既有角色表面提取后细化。此批样段不再渲染人物、坐姿人物或总览人物，第一人称通过独立碰撞体移动。

真实参考及用法记录见 `REFERENCES.md`。木材、混凝土、金属和织物贴图来自 ambientCG，许可 CC0-1.0，文件及下载包 SHA-256 见 `assets3d/pbr/sources.json`。PBR 材质在 Godot 中按名称共享，避免每个模型重复加载同一组图像；Blender 保留完整材质节点。构建清单 `sample-manifest.json` 记录本次实际使用资源的 SHA-256。

## 重放浏览器验收

安装 Playwright 的环境可以运行：

```sh
PLAYWRIGHT_MODULE=/absolute/path/to/playwright node godot_native/tools/verify_campus_letter_browser.mjs
PLAYWRIGHT_MODULE=/absolute/path/to/playwright node godot_native/tools/verify_campus_letter_browser.mjs --touch
```

脚本只读取运行状态与物件投影坐标，使用普通鼠标或 Chrome 模拟触摸完成四个流程，不注入完成状态。默认连接本地 8795 端口，可通过 `CAMPUS_LETTER_URL` 指定地址。

## 状态边界

`experience_model.gd` 独占样段规则与完成判定。相机、动画、材质不写进度。当前完成状态仅保留于本次预览会话，不调用主线 State、任务、物品或存档。纸桥形变和柳湖校准是玩法模型；正式校园接入仍由对应章节控制器接收结果。

## 验证记录

当前专项原生检查为 46 项，全部通过。桌面鼠标和 Chrome 模拟触摸均完成四个样段，控制台错误为空。专项原生结果位于 `exports/campus-letter-web/tests.log`；桌面鼠标与 Chrome 触摸模拟流程、截图和 JSON 记录位于 `exports/verification/campus-letter/`。检查四个样段的拒绝操作、恢复、完成、第一人称坐姿、总览返回与多指取消。手机触摸模拟不等同于实体设备验收。

本目录为独立本地预览，本轮未改变线上生产入口。

2026-11-07 最新现场反馈：移除当前黑衣人物及其在四样段的复用。母校之光由可见的实体信箱承接来信投递；不设置不可见人物接收区。
