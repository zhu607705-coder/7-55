# P06 浙大体艺

- Scene ID: `tiyi`
- Entry: 主屏浙大体艺图标
- Reads: `networkMode`, `flags.tiyiCrashCount/tiyiCountTaken`
- Writes: `flags.tiyiCrashCount`（+1/次）、`flags.tiyiCountTaken`、`digits.d2 = "7"`
- Events: `tiyi_crashed`, `collect_digit`
- 规则：
  - 校园网：加载页停 3 秒 → 闪退回主屏；闪退 ≥3 次追加
    “校园网已经尽力了，你也是”“我知道你没钱买流量”
  - 流量：1.4 秒加载后进入主页，黄色 47 可点 → d2=7
- Assets: `src/assets/ui/tiyi_loading.png`, `tiyi_main.jpg`
