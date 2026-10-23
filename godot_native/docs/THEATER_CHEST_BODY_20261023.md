# 剧场箱体俯视修正（第二版）

后续箱内机关、真实立体堆放与交互见 [THEATER_CHEST_MECHANISM_20261023.md](THEATER_CHEST_MECHANISM_20261023.md)。下文记录空箱体阶段的素材与投影修正。

用户指出第一版下方盒体仍像平板，视线不够垂直。此版保留原箱子的深色木材、黄铜包角与原交互流程，重建近看画面的下方空心盒体。镜头垂直向下，完整可见下沉箱底与四面内壁；外部正面和面向观众的挂锁不再露出。盒盖仅略过直立位置，正上方投影成为远端的窄带，盒体成为画面主体。

原控制器、扫码取物、奖励、地图碰撞与剧情均沿用上一版已验证的行为。本次只更新对象素材、图层分区与盖子开启投影。原 `prop_chest_overhead_open.png` 保留为历史参考，不再是运行中的近看素材。

现用素材：`assets/native/theater_chest_20261023/prop_chest_overhead_body_v2.png`，1448×1086 RGBA。通过内置 `image_gen` 编辑上一版透明素材，未调用三维生成服务。运行对象：`scripts/objects/theater_chest_object.gd`；显示与热区共用该对象的底面矩形。

最终图像编辑提示词：

> Use case: precise-object-edit. Edit this existing wooden chest game sprite to correct the view and the missing-looking lower box body. Preserve its dark reddish fine-pixel wood, aged brass corners and original identity. CRITICAL: current picture reads as two flat wooden lids and still shows a front facade; fix both. CAMERA IS EXACTLY VERTICAL, straight DOWN 90 degrees over the center of the lower BOX BODY, an orthographic plan view with parallel straight edges. The lower body is a genuinely HOLLOW DEEP wooden CONTAINER, NOT a second lid, not two equal hinged boards, not a flat tray. Clearly show a thick rectangular top rim on ALL FOUR SIDES, the inward-facing inner wall bands, dark occlusion shadows deep under the rim, corner seams descending toward a distinct recessed rectangular wooden FLOOR. The empty floor remains large and completely visible, at least two thirds of the opening; keep the near inner wall visible as a narrow shaded inset strip. Remove the visible outside front facade and face-on hanging padlock, because those are occluded from a true vertical top view; only a small brass latch TOP edge is visible on the near rim. MOST IMPORTANT COMPOSITION CHANGE: the lid is opened ONLY slightly past upright, about 105 degrees from shut, toward the far/top side. Looking straight down, this upright lid is strongly foreshortened and occupies ONLY A SHORT NARROW HORIZONTAL BAND ABOVE THE HINGES, about 15% of the total object height. The lower hollow BOX BODY occupies the remaining 80% of the object height. Do not lay the lid flat on the ground, do not show the lid as a second full rectangular panel. Box cavity has substantial length front-to-back in plan view, a wide 4:3 rectangle with the entire wood floor seen from above. In the composition the big central shape is the unmistakably hollow BOX BODY with its recessed floor, surrounded by thick walls, and a short thin foreshortened lid beyond its far edge. No perspective trapezoid, no exterior side faces, no 45-degree view, no isometric angle. Fine pixel-art detail, restrained material highlights, real transparent exterior. No contents, no text, no puzzles, no new objects.

原生验收使用 `tests/test_theater_chest_focus.gd` 的隔离存档与真实 Main，覆盖鼠标、模拟触控、原扫码交易、打开/返回、镜头与热区。浏览器导出和实体手机不在本次验证范围。
