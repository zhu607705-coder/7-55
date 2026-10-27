# 北教 A3 空底与独立物件审阅

这是单独的美术审阅工程，默认打开 A3 的 `1672 × 941` 空建筑底图。它没有接入正式游戏，不读取或写入游戏存档、碰撞或剧情状态。本工程只保留本轮 A3 审阅所需素材。

使用 Godot **4.7.1** 打开此目录中的 `project.godot` 并运行，或在仓库根目录执行：

```sh
'/Users/zhu/Library/Application Support/755-tools/engines/4.7.1/Godot.app/Contents/MacOS/Godot' --path godot_native/samples/north_clean_rebuild_preview
```

窗口可在「空白底图」「独立物件」「原始整图」之间切换。独立物件模式下点按六幅人物画像会从墙面展开人物介绍，「收起」、Esc 或点背景会将画像收回墙面。介绍中可点「上一位」「下一位」或按左右方向键切换，选择「减少动画」可直接显示结果。也可点顶部「人物」，或让地图获得焦点后用左右方向键选择、Space/Enter 展开。

画像的点击区域随缩放保持可点按大小；文字可以滚动，资料来源沿用原有官方链接。其余物件点击后仍可隐藏，「恢复物件」重置；透明区域不会拦截点击。「＋」「－」或滚轮缩放，放大后可拖动画面，「全图」回到初始视图。

交互由 `portrait_interaction.gd` 管理，使用 Godot Tween 展开、淡入和收回。`portrait_interaction_data.json` 是构建脚本从既有 `chapter4-native-source.json:alumni` 生成的六人资料副本，人物图像与原有介绍保持一致；本预览只读资料，不写入正式游戏的提问、任务或存档状态。

`assets/backgrounds/a3_original.png` 是仓库原图的参考副本，`a3_empty_v3.png` 是移除原图中大部分家具与装饰后重绘的建筑底图。`a3_review_layout.json` 记录 246 个审阅用独立摆放实例；`asset_manifest.json` 记录贴图路径、透明内容范围、来源与 SHA-256。报告厅保留 44 个座位，303 教室保留 24 张桌子和 24 把椅子；六位校友肖像使用项目既有素材，相框是独立层。摆放参照 `north-floor-source-objects.json`、`room301-exhibit.json` 和 `ChapterFourAlumniHonorWall.ts`，部分细节按原图手工补位。

按用户对画像落地、摄影室过空和电脑比例的反馈，画像与相框改用墙面居中锚点，实际绘制范围约束在墙脚以上。摄影室按原图补回右侧摄影机、上/下 AV 机柜、竖屏和桌边设备柜，主显示器约 65 像素宽，左右副屏约 48/49 像素宽；支架落在控制桌的台面范围内。新素材、参考来源和完整提示词见 `generation_studio_scale_sources.json`。荣誉室外走廊中的独立金色画框已按用户要求从摆放清单中移除。

重绘物件来自图像生成，原图局部仅用于参照，没有将原图裁片作为新物件。不同批次的生成文件名见 `generation*_sources.json`；部分候选因与原图不符被排除。素材和版式是近似样稿，不是原画的逐像素复原。

界面字体为项目既有的 755 Morning Note Regular 0.1.1，字体及上游许可随工程放在 `assets/`。

目前仍有明确缺口：301 展室中央的历史画面暂为空框，纸张细节是视觉占位。电梯门是成对的视觉候选，尚未做正式开合动画。底图关键位置仅做了局部对齐检查，墙面有约一像素偏差；整层物件覆盖、遮挡、各时态、真实碰撞和完整剧情互动仍需在正式场景中验证。当前审阅清单没有未映射的来源对象组，但这不等于每个原画细节都已逐像素还原。

工作最初基于 `origin/main` 的 `0713f509`。用户确认后，本分支已快进到重新获取的远端 `6288b515`，包含纸张回卷和掠射光教室示例共 23 个新增提交。A3 原图、北教物件清单和 301 展室清单未变，本地审阅文件在同步前后逐文件 SHA-256 一致。

加上 `-- --objects` 可直接进入整层合成效果。需要导出没有工具栏的原尺寸整层图时，设置 `NORTH_CLEAN_CAPTURE` 为图片绝对路径，并使用 `-- --objects --capture-floor`；导出通过同一 Godot 绘制路径在精确 `1672 × 941` 的视口中完成。

审阅工程的无界面检查：

```sh
'/Users/zhu/Library/Application Support/755-tools/engines/4.7.1/Godot.app/Contents/MacOS/Godot' --headless --path godot_native/samples/north_clean_rebuild_preview --script res://test_preview.gd
```

Godot 4.7.1 下本轮为 524 项、0 失败。另核对 46 个已使用物件贴图的透明通道、边界和 SHA-256。该检查覆盖素材读取、实例标识、主要桌椅数量、画像挂墙范围、电脑与桌面比例、透明区域命中和审阅窗口缩放；不等于正式游戏或移动端操作验收。

画像交互专项为 `--script res://test_portrait_interaction.gd`：26 项、0 失败，覆盖触屏阅读、切换、三个窗口尺寸、动画中途关闭与重选、减少动画和模式切换。`demo_portrait_interaction.gd` 使用实际 GUI 鼠标、触屏、键盘事件演示，并用 Godot Movie Writer 录制；桌面和 390 × 844 窗口各检查 8 项。捕获驱动会请求窗口焦点，并将原生鼠标位置与注入事件统一，避免桌面指针覆盖测试坐标。

录制示例（AVI 为临时中间文件）：

```sh
'/Users/zhu/Library/Application Support/755-tools/engines/4.7.1/Godot.app/Contents/MacOS/Godot' --path godot_native/samples/north_clean_rebuild_preview --resolution 1280x760 --fixed-fps 30 --write-movie /tmp/a3_portrait_interaction.avi --script res://demo_portrait_interaction.gd
```
