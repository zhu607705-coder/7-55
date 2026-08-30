# P06 浙大体艺

- Scene ID: `tiyi`
- Entry: 主屏浙大体艺图标
- Reads: `networkMode`, `flags.tiyiCrashCount/tiyiCountTaken`, `actOne.characterNamed/exerciseStarted`
- Writes: `flags.tiyiCrashCount`（+1/次）、`flags.tiyiCountTaken`、`digits.d2 = "7"`
- Events: `tiyi_crashed`, `collect_digit`
- 规则：
  - 所有章节与支线统一校验进入时的网络状态。
  - 校园网或离线：加载页停 3 秒 → 闪退回主屏；闪退 ≥3 次追加
    “校园网已经尽力了，你也是”“我知道你没钱买流量”
  - 流量：1.4 秒加载后进入主页，黄色 47 可点 → d2=7
  - 第一章移动链：按钮进入虚拟定位跑步，按顺序完成十个一分钟定位点；面板把每次点按演出为 `300m`，最终形成 `10:00 / 3.00km / 03'20\"` 的七点五圈记录。只有第十个点完成后才调用 `ActOneBootstrapController.startExercise()` 写入正式进度。
  - 虚拟定位中途退出不会写入半完成状态；触屏直接点按，键盘使用 `Tab + Enter/Space`，`Esc` 可退出本次定位。
- Assets: `src/assets/ui/tiyi_loading.png`, `tiyi_main.jpg`
