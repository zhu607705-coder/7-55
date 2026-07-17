# Phone Scenes（序章与章节手机界面）

场景注册见 `registry.tsx`，每个场景一个编号文件夹（`index.tsx` + `README.md`）。

| 文件夹 | SceneId | 说明 |
| --- | --- | --- |
| P00_Alarm | `alarm` | 闹钟：振动+音效，关闭进入 P01 |
| P01_Desktop | `desktop` | 再睡5分钟 → 旁白 → 起床蠢货！！！ |
| P04_CampusCard | `campus_card` | 校园卡余额 ¥0.06，黄色 0 → d1 |
| P06_Tiyi | `tiyi` | 校园网闪退线 / 流量 47 → d2 |
| P10_Bonsai | `bonsai` | 盆栽三步开花 → d4 |
| P11_Checkin | `checkin` | 学在浙大签到 0798 → 红闪黑屏 |
| P12_Ending | `ending` | 序章结算 → 保留进度进入校园 RPG |
| P13_PhoneHome | `phone_home` | 主屏：齿轮 d3 / 塔楼钥匙 / 水滴 / 盆栽入口 |
| P14_Wechat | `wechat` | 小影散码 + 朋友头像斜线谜题（原 P03） |
| P15_Zjuding | `zjuding` | 浙大钉：加载门禁 + 签到/我的导航 |

## 已并入其他位置的旧场景

- P02 CC98 → 剧情改为微信（P14），CC98 仅剩主屏彩蛋图标
- P03 头像谜题 → 并入 P14 微信聊天列表
- P05 控制中心 → 全局覆盖层 `src/components/ControlCenter.tsx`
- P07 天气 → 主屏天气组件交互（P13）
- P08 设置 → 主屏设置齿轮图标交互（P13）
- P09 合成 → 物品栏拖拽合成 `src/components/InventoryBar.tsx`

场景之间不要互相 import 内部文件；剧情逻辑统一走 `src/modules/GameKit.ts`。
