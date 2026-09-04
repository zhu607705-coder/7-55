# 灿若星辰灯正式分层素材

这五张 `1024 × 1536` 透明 PNG 来自用户在 2026-08-29 提供的正式素材包：

- `lamp_dark.png`：未点亮灯体
- `lamp_outline.png`：球形金属轮廓
- `lamp_leds.png`：灯珠层
- `lamp_core.png`：中央灯芯
- `lamp_glow.png`：光晕层

运行时由 `ChapterFourStarLampClosure.tsx` 挂载
`ChapterFourStarLampThreeRenderer.ts`。五张正式 PNG 是主路径始终可见的灯体，保持原版
灯柱、球形骨架、灯珠、灯芯和光晕，不再由程序化 Three.js 几何替换。Three.js 只负责
远、中、近三层 `THREE.Points` 星空和 `PerspectiveCamera`：相机在未点亮状态下从灯体
底部机位向上移动到正面机位；灯体自身旋转值全程为 `0`。原图投影与同一相机进度同步，
让底座近景到完整灯体的位移可见。随后仍按原素材依次显示灯珠、灯芯和低曝光光晕。

WebGL 不可用或上下文丢失时，继续使用相同的五张正式素材并切换到 CSS 星空背景；兼容
序列保持“暗场观察 → 点亮 → 完成”的顺序，资源不做非等比缩放或二次生成。主路径与
兼容路径都在完整时序结束后才发出一次会话完成回调。

正式资源标识：

- `assetId`: `canruo_star_lamp_layered_v1`
- `sequenceId`: `chapter4_755_canruo_star_lamp_5800ms_camera_rise_layered_v4`
- `consumer`: `src/components/temporal-maze/ChapterFourStarLampClosure.tsx`
- `renderer`: `src/components/temporal-maze/ChapterFourStarLampThreeRenderer.ts`
- `duration`: `5800ms`
- `cameraRise`: `120–2200ms`，摄像机从底部机位抬升到正面机位，灯体旋转 `0`
- `lightStart`: `2350ms`
- `fullyLit`: `4050ms`
- `maximumLightLevels`: 灯珠 `0.70`、灯芯 `0.62`、光晕 `0.26`

## 资源与生命周期

- React 容器使用 `ResizeObserver` 与窗口 resize 事件保持等比透视，不拉伸灯体分层素材。
- `prefers-reduced-motion: reduce` 下停用抬升和星点漂移，但仍先展示暗灯，再分阶段点亮。
- 页面隐藏期间不累计播放时间，恢复后从原阶段继续，避免后台跳过演出后直接签发完成凭证。
- 卸载或切换为兼容路径时取消 RAF、移除监听器并释放 renderer、geometry、material 与 texture。

专项校验：

```bash
npm run chapter4:validate-star-lamp
```

校验器会抽样完整暗场抬升区间，确认灯珠、灯芯与光晕在 `2350ms` 前保持为零；同时检查
摄像机高度持续增加、原图投影从底座近景到完整灯体、灯体旋转恒为零、最终曝光上限、
五张原图始终是正式灯体、三层星点、资源释放与一次性完成凭证。

原始五图 SHA-256：

- `lamp_core.png`: `24f629cdd3aac6d6ae37cf1ea59ddcc51e425e2b5c97d4fcab5f6ce63fd22c2c`
- `lamp_dark.png`: `d44f7e4d3a6b261b19345c0340289af99a69a6a5d51852d9c5eea918c72b75bd`
- `lamp_glow.png`: `e40985f91f179f583f0b87c01628b1ed72f72b4f05424d2377af5019e3550d6c`
- `lamp_leds.png`: `88eec957a051cf0553154718f32147a2daea34d9e23e16431a8a7dac2d52bbce`
- `lamp_outline.png`: `a04d8d0463c74a0096780a7f7e3a4cf0c45140115abd0e9141a2ba1ad78899e9`
