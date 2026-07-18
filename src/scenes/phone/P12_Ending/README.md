# P12 序章结算

- Scene ID: `ending`
- Entry: P11 签到成功红闪黑屏后
- 演出：黑屏（“手机屏幕暗了下去。”）→ 淡入现实世界寝室图 →
  字幕“签到成功。你还在床上。” → “序章·完” + 进入下一章
- Assets: `src/assets/ui/dorm_room.png`（pageexample/现实画面.png）
- 继续条件：`checkinDone === true`
- 继续结果：保留完整 `GameState`，切换到 `campus_bootstrap` 横屏 RPG；玩家从冻结角色开始第一章启动链
