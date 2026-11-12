# 追光线

原创第三人称 Three.js 屋顶跑酷。首条路线设在一座虚构的沿海城市，玩家从机房屋顶出发，经沿海风廊、塔前屋顶、中继天桥和天线检修台，最后抵达信号塔。路线长 658 米。跑者自动向前，玩家控制转向、起跳和滑铲。场景、人物、绑定、动作和合成音效由本目录代码生成。

## 运行

```sh
npm ci
npm run dev
npm run build
npm run preview
```

正式构建输出在 `dist/`，可由静态 HTTP 服务独立托管。桌面使用 A/D 或方向键转向，空格起跳，S 滑铲，Esc 暂停。触屏可滑动操作，也可点底部按钮。接近低栏时按跳键会撑越，靠近有青色灯条的侧墙按跳键会贴墙跑。四处检查点允许从当前区段重来，最佳用时按路线长度和难度保存在本机。

## 关卡标尺

| 区段 | 内容 |
| --- | --- |
| 机房屋顶 | 短距离练撑越、屋沿起跳和低梁滑铲，随后用机组检验换道 |
| 沿海风廊 | 右墙跨越 13 米断面，接回宽屋顶，再加普通缺口与低梁 |
| 塔前屋顶 | 左墙跨越 13.5 米断面，接两组连续跳跃与滑铲 |
| 中继天桥 | 382 米处的旧终点成为中继检查点，上坡后从中线窄桥起跳，再贴右墙过断面 |
| 天线检修台 | 登上更高屋面，向右换道通过检修桥，再组合滑铲、换道和长缺口 |

标准档速度从 8.8 到 11.8 米/秒，挑战档提速 16%。标准档的离地宽限和跳跃缓冲分别为 100 和 140 毫秒，挑战档为 65 和 100 毫秒。普通缺口最长 6.4 米，墙跑断面长于普通跳跃距离。路线、平台高度、窄桥落脚范围、障碍碰撞和可跑墙位置共用 `src/course.js` 中的坐标。

## 参考

- 用同一个起跳意图结合环境选择跳、撑越或贴墙跑，参考 [EA 的《Mirror’s Edge Catalyst》动作设计](https://www.ea.com/amp/news/movement-in-mirrors-edge-catalyst-the-basics)。
- 短暂的离地宽限和落地前输入缓冲参考 [Maddy Thorson 的《Celeste & Forgiveness》](https://www.maddymakesgames.com/articles/celeste_and_forgiveness/)。路线按单动作练习、检查点、组合考验展开，参考 [《Celeste》GDC 关卡设计分享](https://www.gdcvault.com/play/1024307/Level-Design-Workshop-Designing-Celeste)。
- 斜阳负责角色和建筑投影，天空光保留冷色暗部。近处轨道用实时阴影，远景通过雾和大色面区分深度。参考 [Three.js 阴影](https://threejs.org/manual/pages/shadows.html)和[色彩管理](https://threejs.org/manual/pages/color-management.html)。
