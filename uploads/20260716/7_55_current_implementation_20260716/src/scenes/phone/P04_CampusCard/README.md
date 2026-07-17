# P04 校园卡余额

- Scene ID: `campus_card`
- Entry: 浙大钉首页 → 电子校园卡
- Exit: 常规返回浙大钉首页；图书馆临时离座阶段返回原选座页
- Reads: `flags.cardZeroTaken`
- Writes: `digits.d1 = "0"`、`flags.cardZeroTaken`
- Events: `collect_digit`, `card_zero_taken`
- 规则：余额显示 ¥0.06，第二个 0（小数点后的 0）为黄色可点 → d1=0，
  吐槽“余额暂时不足以购买尊严”
- 视觉：按 pageexample/校园卡余额.png 用 DOM 重制（深蓝像素卡片）
