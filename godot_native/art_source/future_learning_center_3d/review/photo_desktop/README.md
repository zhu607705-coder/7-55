# 照片桌面五件 · GPX 鼠标与键盘右区修正版

本版保留原显示器及底座、围板与独立折臂，仅根据用户 2026-11-03 的意见修正鼠标和键盘。候选未替换主场景。

鼠标按官方 GPX 125×63.5×40 mm 外包络与实际官图重做圆背、薄底座、两瓣按键、滚轮和左侧两键。曲线和细节按图片比例估计，保留原照片珊瑚色后壳，不声称厂家精确 CAD，不猜接口或品牌。键盘最右区与主键区保持约 6 mm 独立间隔，保留照片键帽颜色，难辨字符不复制。

| 独立资产 | 源宽×深×高 mm | LOD0/1/2 源三角数 |
|---|---:|---:|
| photo_monitor_stand | 614.0 × 180.0 × 482.5 | 1140 / 660 / 220 |
| photo_keyboard | 370.0 × 145.0 × 39.3 | 32712 / 9828 / 3828 |
| photo_mouse | 63.5 × 125.1 × 40.4 | 20726 / 7898 / 2946 |
| photo_desk_divider | 1619.5 × 669.5 × 420.0 | 1128 / 648 / 264 |
| photo_monitor_arm | 287.5 × 97.0 × 536.5 | 3008 / 1632 / 616 |

除 GPX 官方外包络外，照片没有标尺，尺寸均为暂定值。独立机械臂不能用中央显示器自带底座替代；遮挡的桌夹和屏后连接仍为明确推测，不提供承重或安装规格。围板保留后板和右返板两片，不扩成假想隔间。

所有屏幕均为中性无文字材质；原照片、个人信息和品牌图片未进入资产。独立 .blend、三档 source GLB、标准和 Draco GLB 均可复用。源坐标为米、Blender Z 向上；runtime glTF 为 Y 向上并归零脚点。

## 重建与验证

在完整工程的 future_learning_center_3d 根目录运行：

```
blender -b --factory-startup -t 2 --python scripts/refine_photo_input_devices.py -- --skip-render
node pipeline/build_photo_desktop.mjs
node pipeline/test_photo_desktop.mjs
node pipeline/test_photo_input_revision.mjs
node pipeline/test_photo_supports.mjs
blender -b --factory-startup -t 2 --python scripts/refine_photo_input_devices.py -- --render-only
blender -b --factory-startup -t 2 --python scripts/build_photo_supports.py -- --render-only --assembly-only
```

不要使用旧 build_photo_desktop.py 重建入口覆盖本次鼠标/键盘；该文件只作为公共基础函数保留。本次258项桌面解码检查、27项修正版几何检查、185项围板/折臂检查及530项原回归通过。源模型与Draco码流均真实读取，不是只检查JSON。

本机由已交付五件模型包 v1 恢复，恢复commit为3f7ca5e。原 monitor/divider/arm 共30个模型文件与此恢复快照逐字节一致；键盘/鼠标是用户授权的变化，不再声称它们与旧版一致。详情见 ../photo_living/README.md。

所有预览为 Blender 4.3.2 Cycles CPU 图，非网页或 GPU 验收；本轮不声称主建筑场景、碰撞和网页互动已经接入。

## 本次最终结果

全批 19 件，其中桌面 5 件、生活区 14 件。共 3683 项非浏览器检查通过：桌面 258、鼠标/键盘专项 27、围板/折臂 185、生活区 2683、原回归 530。生活区 42 个 Draco LOD 直接解码确认真实 20-bit 位置量化；最大压缩包络误差 0.001490 mm。

模型包不含 .git、node_modules 或用户原照片。打开 .blend 或读取 GLB 无需 Git。重新构建需 npm ci --prefix pipeline；字节保留回归检查依赖完整工程内的恢复基线，不能在不含 Git 历史的独立 ZIP 中执行该部分。两个模型包可合并解压，路径不冲突。
