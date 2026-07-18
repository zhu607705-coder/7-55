# P14 WeChat 微信（含原 P03 头像谜题）

- Scene ID: `wechat`
- Entry: 主屏微信图标 / 顶部通知
- Reads: `flags.codeScattered/slashHalfDropped/slashTapCount/slashTaken`, `ui.autoRotate`
- Writes: `flags.codeScattered`（小影散码后）、斜线谜题 flags、`items.slashLine`
- Events: `xiaoying_attack`, `code_scattered`, `slash_taken`
- 演出：首次打开朋友聊天 → 小影出现 → 全屏强震 → 四个数字块飞出屏幕 → 任务横幅
- 谜题：列表中朋友头像为斜线；自动旋转开启 → 一端掉落挂框 → 点剩余端 3 次 → 获得[斜线]
  （台词：“检测到未经授权的友情支援”）
- Tests: App.test 冒烟覆盖散码流程
