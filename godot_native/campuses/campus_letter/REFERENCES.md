# 实物参考与材质来源

检索与核对日期：2026-11-07。产品照片只用于比例、制造结构和表面观感的参考，不作为游戏贴图或品牌复刻。

| 参考 | 来源 | 落到本次模型的具体部分 |
| --- | --- | --- |
| 木材表面与榫接尺度 | [Nikari 材料说明](https://nikari.fi/about-us/our-material/) | 保留连续木纹、沿构件方向设置纹理；分开木材与包覆织物的粗糙度 |
| 曲面木座椅与钢架连接 | [HAY Result Chair](https://www.hay.com/hay/furniture/seating/chair/result-chair) | 座板和靠背连续曲面、独立连接件、可见螺栓、脚垫与坐垫包边 |
| 关节台灯 | [Anglepoise Type 75](https://www.anglepoise.com/product/type-75-desk-lamp-slate-grey/)、[技术规格](https://support.anglepoise.com/hc/en-gb/articles/360014173717-Anglepoise-Type-75-Desk-Lamp) | 铰接双臂、枢轴销、双层旋转曲面灯罩、灯泡与电缆；模型为本项目独立设计 |
| 室外投射灯 | [ERCO Beamer](https://www.erco.com/en/products/outdoor/projectors/beamer-7940/) | 筒身、光学透镜、安装支架、独立枢轴和调整旋钮的构造关系 |
| 母校之光材质与构成 | [北化离退休工作处出版资料](https://ltx.buct.edu.cn/_upload/article/files/14/7e/f6d058b9476dad2e4391299ca5dd/837853b7-fba1-4c44-be07-e5181c51bd22.pdf) | 不锈钢反光质感、托举手部与上部结构；本次模型仍为互动装置设计，不作测绘复刻依据 |

## 实际使用的外部材质

均来自 ambientCG，适用 [CC0 1.0 许可](https://docs.ambientcg.com/license/)。源下载包和采用文件记录在 `assets3d/pbr/sources.json`。

- [Wood051](https://ambientcg.com/view?id=Wood051)：桌面、椅板、书架与长椅木材，颜色、法线和粗糙度。
- [Concrete034](https://ambientcg.com/view?id=Concrete034)：地面石质铺装与墙面细微结构，按表面用途调整法线幅度。
- [Metal032](https://ambientcg.com/view?id=Metal032)：钢制砝码、灯具和雕塑，保留各金属本色，使用低幅法线和粗糙度变化。
- [Fabric041](https://ambientcg.com/view?id=Fabric041)：椅垫与布面书封，保留低饱和布色，使用织物法线与粗糙度。

图像以 1K 级共享纹理进入运行时，曲面和倒角增加的是实际轮廓面数；碰撞仍采用独立简化体。运行画面从相同的 Godot Web 构建取得。
