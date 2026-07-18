# P10 盆栽（原 Treehole 重制）

- Scene ID: `bonsai`
- Entry: 主屏湖边盆栽摆件（点击提示“它绝对不会开花”）
- Reads: `items.headphone/waterDrop/fertilizer`, `ui.brightness`, 盆栽 flags
- Writes: `flags.plantWatered/plantLit/plantFertilized/flowerBloomed/flowerEightTaken`,
  `digits.d4=8`
- 三步平行（每步植株放大一档）：
  - 浇水：需要 耳机 + 水滴（“用耳机键浇水”，消耗水滴）
  - 照光：需要控制中心亮度 ≥ 80
  - 施肥：需要 一袋肥料（消耗）
- 全部完成 → 换花开图 → 点花吐出数字 8 → d4
- Assets: `src/assets/ui/bonsai_bud.png`, `bonsai_bloom.png`
- Tests: `src/modules/PlantController.test.ts`
