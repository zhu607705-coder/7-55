# P04 校园卡余额

- Scene ID: `campus_card`
- Entry: 浙大钉首页 → 电子校园卡
- Ownership: 第二章系统要求恢复道具栏后，从寝室右侧个人书桌取得
- Exit: 常规返回浙大钉首页；图书馆临时离座阶段返回原选座页
- Reads: `actOne.balanceShifted`
- Writes: 第二章由 `rightArrow` 触发 `0.06 → 6.00`
- 规则：第一章不开放校园卡；首位 `0` 已迁至学在浙大签到页
- 视觉：按 pageexample/校园卡余额.png 用 DOM 重制（深蓝像素卡片）
