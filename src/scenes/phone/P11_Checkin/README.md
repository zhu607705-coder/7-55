# P11 校务签到（学在浙大）

- Scene ID: `checkin`
- Access: 仅序章开放；首次经纬度错误进入第二章后，由 `selectFeatureAccess` 和 `SceneRouter` 拒绝再次进入。
- Entry: 浙大钉内页右上绿色卡片
- Reads: `networkMode`, `flags.codeScattered`, `flags.cardZeroTaken`
- Writes: `digits.d1 = "0"`, `flags.cardZeroTaken`, `flags.checkinDone`
- Events: `checkin_absence_zero_taken`, `checkin_rejected`, `checkin_success`, `checkin_stamped`, `checkin_geo_error_presented`
- 规则（`src/modules/CheckinController.ts`）：
  - 流量提交 → “请连接校园网”
  - 错码 → 红抖 “签到码错误”
  - 签到码散落后，`本周缺勤 0 次` 中的 `0` 提供第一位数字
  - 0798 + 校园网 → “签”“到”逐字跳出 → 居中显示 `经度与纬度不存在` 系统通知 `1900ms` → 全屏红闪 → 黑屏 → 路由 `ending`
  - 成功签到写入 `flags.checkinDone` 后立即隐藏手机道具栏；直到寝室取回校园卡并写入 `actOne.inventoryRecovered` 才恢复
  - 同一错误框在 `ending` 中成为可移动拦截板
- 视觉：无示例图，自行设计（4 格码输入 + 像素数字键盘，浅灰蓝配色）
