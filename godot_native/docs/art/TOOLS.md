# 像素素材工具链

用户后续要求像素边长约为粗版的20%。新批次按原生细像素重绘，不先降到旧24×32角色/240×135舞台再放大。`fineCharacter`精确检查120×160原生帧，`fineStage`检查1200×675，使用`--scale=1`；粗版的`character --scale=4`与下方开场流程仅保留作历史复现。细图优先保留结构与细节，以统一的等比定位和最近色映射整理，不对已清楚的细格网使用大pixel-size弹性重采样。

两套MIT工具均已从固定官方提交审查、使用锁定依赖构建并安装到本机隔离目录。工具本体不进入Godot/PCK，不改系统PATH或shell配置；构建用Rust缓存留在`/tmp`，可运行CLI、许可和安装记录保存在`~/.local/share/755-art-tools/`。提交与本机二进制SHA见`../../tools/art_tools.lock.json`，其他平台需重新构建并记录各自SHA。

| 工具 | 持久入口 | 实测用途 |
| --- | --- | --- |
| Pixel Snapper | `~/.local/share/755-art-tools/pixel-snapper/bin/spritefusion-pixel-snapper` | 混杂像素格、色板清理；输出新图，不覆盖原图 |
| Sprite Normals | `~/.local/share/755-art-tools/sprite-normals/bin/spritefusion-sprite-normals` | 对已定稿的sprite生成法线；不做像素化 |

Pixel Snapper先做k-means再映射指定色板，因此必须显式传`32`，不能保留默认16色后再要求32色。`--pixel-size`是检测/重采样参数，不是输出尺寸承诺；本次1254×1254斜俯视开场的4/6/8试验分别得到369×360、251×243、176×178，不能直接放回有源坐标合同的地图。

```sh
GAME755_ART_TOOLS_DIR="$HOME/.local/share/755-art-tools"
GAME755_PALETTE="$(node -p "require('./godot_native/docs/art/art_direction_v1.json').palette.colors.join(',')")"
"$GAME755_ART_TOOLS_DIR/pixel-snapper/bin/spritefusion-pixel-snapper" input.png output.png 32 --pixel-size 8 --palette "$GAME755_PALETTE"
"$GAME755_ART_TOOLS_DIR/sprite-normals/bin/spritefusion-sprite-normals" final_sprite.png -o final_sprite_n.png --normal-format opengl
FFMPEG_BIN=ffmpeg node godot_native/tools/audit_pixel_art.mjs final_sprite.png --profile=character --scale=4 --strict --output=godot_native/exports/verification/art-batch/report.json
```

审计器只读检查PNG尺寸、声明的整数放大格、固定色板和透明度。`--profile`支持规范中已有类型；`--verbose`打印完整像素统计。默认将非合规旧图登记为诊断，`--strict`才以失败退出。格网和色数通过后仍需人工审视轮廓、统一尺度、透视，以及实机碰撞、遮挡、文字和触点。禁止将技术通过写成整个游戏美术验收。

开场首批流程：原始网页生图保留→固定32色、pixel-size8清理→从原生176×178结果以整数坐标`0,0,160,160`裁切→nearest整数4倍→640×640无损WebP→解码后的25,600个4×4格逐格检查。它不含游戏碰撞坐标；这个裁切步骤不能照搬到地图。最终WebP仅7004字节。近景概念和第一次斜俯视生成失败均留有来源记录，没有将失败或概念图写成正式结果。

法线试验使用自制32×32杯子，检查了尺寸、逐字节透明度、法线向量与DirectX/OpenGL绿通道关系以及输入防覆盖。**尚未将法线接入游戏材质**；原图的高光也可能被估计成凹凸，不能生成后直接批量给所有物体打光。

初始验证记录在`exports/verification/pixel_snapper_20261021/`、`exports/verification/art_direction_20261021/`及本机工具各自的安装记录中。每批都保留原始图和新输出，按原有地图/角色/道具合同分别决定是否采用。
