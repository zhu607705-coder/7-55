# P12 序章结算

- Scene ID: `ending`
- Entry: P11 签到成功红闪后
- Required state: `checkinDone === true`
- Sequence: `7s` 黑屏 → 经纬度错误框部署 → 三次拦截 → `1400ms` 按住锁定 → 对话 → 白色连闪 → 手机主页
- Controls: pointer drag, `A/D`, left/right arrows; final lock accepts pointer hold, `Space`, and `Enter`
- Failure: three misses open a retry state; retry restarts the error-window game without replaying the seven-second blackout
- Runtime inspection: `window.render_game_to_text().endingGame`
- Controller gate: `completeNarratorIntervention()` validates three interceptions and the full hold before chapter progression
