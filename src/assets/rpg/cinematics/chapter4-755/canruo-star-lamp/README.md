# 灿若星辰灯正式分层素材

本目录中的五张 `1024 × 1536` 透明 PNG 是第四章正式消费者使用的全部灯光素材：

- `lamp_dark.png`：未点亮灯体
- `lamp_outline.png`：球形金属轮廓
- `lamp_leds.png`：灯珠层
- `lamp_core.png`：中央灯芯
- `lamp_glow.png`：光晕层

五张图必须保持同一画布、原始像素和透明通道。运行时由
`ChapterFourStarLampClosure.tsx` 等比叠加，不得单独裁切、拉伸或重新生成。

此前混合压缩包内的 Three.js、Godot、Next.js 构建、原型、依赖目录与其他旧版本
不属于正式素材，也不得成为当前浏览器运行时的资源来源。本目录及其消费者是活动版本的
唯一来源。

正式资源标识：

- `assetId`: `canruo_star_lamp_layered_v1`
- `sequenceId`: `chapter4_755_canruo_star_lamp_6200ms_v1`
- `consumer`: `src/components/temporal-maze/ChapterFourStarLampClosure.tsx`

原始五图 SHA-256：

- `lamp_core.png`: `24f629cdd3aac6d6ae37cf1ea59ddcc51e425e2b5c97d4fcab5f6ce63fd22c2c`
- `lamp_dark.png`: `d44f7e4d3a6b261b19345c0340289af99a69a6a5d51852d9c5eea918c72b75bd`
- `lamp_glow.png`: `e40985f91f179f583f0b87c01628b1ed72f72b4f05424d2377af5019e3550d6c`
- `lamp_leds.png`: `88eec957a051cf0553154718f32147a2daea34d9e23e16431a8a7dac2d52bbce`
- `lamp_outline.png`: `a04d8d0463c74a0096780a7f7e3a4cf0c45140115abd0e9141a2ba1ad78899e9`
