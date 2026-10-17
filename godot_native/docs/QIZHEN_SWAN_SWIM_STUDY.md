# 黑天鹅游泳动作审看 v2

状态：视觉待确认。2026-10-17 收到“当前黑天鹅游泳的动画其实还是有待商榷的”后制作。
这是原启真湖背景上的单独近景，不是新的剧情地图，也未替换原 7.2 秒出场。

打开 `scenes/qizhen_swan_swim_study.tscn` 按 F6。12 秒循环，R 重播，空格/P 暂停。
平游 → 转弯 → 加速 → 收力。循环结束短淡出再从起点重播，不宣称是闭合游动轨迹。

## 检查到的旧呈现问题

- 原出场的 0–3 秒使用一张姿态平移。原“平游”图翼缘较高，易读成惊动姿态
- 3 秒后才切抬颈；展翅不在最初平游段，但整帧旋转不能替代真正方向姿态
- 每 0.08 秒固定出水纹，即使停住也继续出；尾波不由实际速度/位移决定
- 腹部无表面水线遮挡，身体有贴在水面上的感觉

这些是代码及原图中可核查的情况，不代表已确定用户所指就是其中某一项。

## 此近景的调整

- 使用新透明折翅泳姿图。选四张稳定方向图，实际重画方向，不旋转整个侧面贴图
- 普通游泳保持弯颈和稳定身体。仅有不超过 0.35 源像素的小起伏
- 普通划水不展翅。加速用单独低头姿态；原出场扑翅仍在旧独立时间线中
- 腹底裁到稳定水线；表面水纹覆盖接水边缘，水线不随脖子上下跳
- 每移动 10 源像素产生一组尾迹。强度取真实位移/时间；停止后不产生新尾迹，旧尾迹淡出
- 摄像机跟随原天鹅湾内的一条连续确定性采样路径。不是人工操控、不是新的追逐 AI

## 素材来源与选择

`assets/native/chapter3/black_swan_swim_atlas_v2.png`：原生 imagegen 生成，RGBA 1086×1448，约 69.7% 像素透明。
以原出场黑天鹅图为身份参考。要求 3 列×4 行，同体积、低折翅、稳定水线、四个俯视方向、简化羽毛像素。

实际生成结果仍有不同列的脖子和轮廓差异，不能把 12 张随意串成平游。
本次只使用各行第一张作为四个方向，第四行第二张作一次性加速低头。
普通平游不循环明显的低头/抬头帧；没有使用缩放拉伸制造划水。

生成提示要点：
“Same black swan identity, red beak and body volume; tightly folded low wings,
calm curved neck, stable horizontal waterline, no visible legs, no waves or shadow
baked into sprites; 3 columns by 4 rows; west, west-southwest, southwest,
south-southwest genuine redraws; subtle normal paddle poses; crisp pixel clusters;
transparent background; no wing flap or chicken-like head bobbing.”

局限：仅四个方向的审看资产，不是完整八方向成品。方向切换仍可看出关键帧跳变；
羽毛颗粒、与船的比例及最终泳姿还待用户反馈，未宣称视觉通过。

## 验证

- `test_qizhen_swan_swim.gd`：2766 项断言，0 失败
- 包含停住不出尾迹、60 像素位移出 6 组尾迹、真实速度、微小起伏、转向/位置连续性
- 原出场测试 1440 项和运动测试 1615 项仍通过；旧模型与旧过场源文件未改
- 原生截图 75、168、262 帧检查折翅平游、转弯、加速水线
- 视频：Godot 4.6.3 Movie Maker，1280×720，30 fps，360 帧/12 秒，确定性路径
- 云端 llvmpipe 记录：录制 9 秒，CPU render 0.65 ms/frame，GPU render 3.45 ms/frame，编码 13.36 ms/frame
- 上述是离线录制指标，不是实体手机帧率；未做实体手机或正式章节回归
