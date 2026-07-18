# P11 校务签到（学在浙大）

- Scene ID: `checkin`
- Entry: 浙大钉内页右上绿色卡片
- Reads: `networkMode`
- Writes: `flags.checkinDone`
- Events: `checkin_rejected`, `checkin_success`, `checkin_stamped`
- 规则（`src/modules/CheckinController.ts`）：
  - 流量提交 → “请连接校园网”
  - 错码 → 红抖 “签到码错误”
  - 0798 + 校园网 → “签”“到”逐字跳出 → 全屏红闪 → 黑屏打字机
    “经度或纬度不存在” → 路由 `ending`
- 视觉：无示例图，自行设计（4 格码输入 + 像素数字键盘，浅灰蓝配色）
- Tests: `src/modules/CheckinController.test.ts`
