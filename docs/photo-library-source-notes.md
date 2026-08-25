# 手机照片素材来源与重绘边界

## 运行时规则

- 游戏只加载 `src/assets/ui/photo-evidence/` 下的本地素材，不请求外部图片。
- 网络页面只用于核对校园建筑、湖岸设施和日常场景事实。
- 网页原图的再分发授权没有得到确认，因此不复制网页原图，也不把网页原图打进单文件。
- 新增六张照片采用新的机位、构图、人物分布、光线和像素化处理，由生成模型输出后压缩为 `512×512` WebP。
- 六张新增照片的 `storyRole` 均为 `decorative`，不会写入 `GameState`、`SaveStore` 或证据控制器。

## 公开事实参考

| 参考 | 用途 | 运行时处理 |
|---|---|---|
| https://www.zjucce.zju.edu.cn/zh-cn/xiaoyuanfengguang.html | 核对紫金港校园整体环境 | 只作事实参考 |
| https://www.zjucce.zju.edu.cn/zh-cn/zijinggangxiaoqu.html | 核对紫金港校区建筑氛围 | 只作事实参考 |
| https://www.zju.edu.cn/2020/0117/c45261a1957298/pagem.htm | 核对月牙楼、启真湖、草地、桥和天鹅的空间组合 | 只作事实参考 |
| https://www.zju.edu.cn/2023/0324/c75118a2732446/pagem.htm | 核对启真湖蓝色模块浮桥与湖岸活动设施 | 只作事实参考 |
| https://www.zju.edu.cn/2018/0917/c32770a1513823/pagem.htm | 核对月牙楼曲面建筑特征 | 只作事实参考 |
| https://www.zju.edu.cn/2016/0617/c33420a1519384/pagem.htm | 核对启真湖与校门作为常见校园照片背景 | 只作事实参考 |

## 新增资产

| 文件 | 内容 | 生成约束摘要 |
|---|---|---|
| `campus_zijingang_gate_cloudy.webp` | 林荫、红砖浅石三拱校门、自行车 | 新机位；无校名、标志和可读文字 |
| `campus_qizhen_dock_morning.webp` | 柳树、湖面波纹、蓝色模块浮桥、远处建筑与天鹅 | 无纸条、皮划艇、鱼竿或剧情物件 |
| `campus_crescent_after_rain.webp` | 雨后步道、曲面教学楼、自行车 | 无指示牌文字或剧情线索 |
| `life_study_room_late_snack.webp` | 学习空间、本子、保温杯、饭盒与耳机 | 无化学器材、危险操作和可读笔记 |
| `life_bike_basket_raincoat.webp` | 宿舍步道、车筐、雨衣与水瓶 | 无二维码、车辆编号和人物身份 |
| `life_canteen_queue.webp` | 食堂餐盘与普通排队场景 | 无人脸、菜单文字和品牌标志 |

六张图统一使用手工 `32-bit` 像素相机照片风格，禁止水印、签名、UI、`07:55`、`022`、纸条和其他能够被误读为剧情证据的内容。
