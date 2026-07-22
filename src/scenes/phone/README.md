# Phone Scenes（序章与章节手机界面）

场景注册见 `registry.tsx`。编号文件夹保留场景实现或已退役流程说明；实际可进入页面以 `REAL_SCENES` 为准。

| 文件夹 | SceneId | 说明 |
| --- | --- | --- |
| P00_Alarm | `alarm` | 闹钟：振动+音效，关闭进入 P01 |
| P01_Desktop | `desktop` | 再睡5分钟 → 旁白 → 起床蠢货！！！ |
| P02_CC98 | `cc98` | 校园网门禁 + 热门话题、市场与图书馆调查帖 |
| P04_CampusCard | `campus_card` | 第二章校园卡余额与右移箭头交互 |
| P06_Tiyi | `tiyi` | 校园网闪退线 / 流量 47 → d2 |
| P07_Weather | `weather` | 第二章天气页与水滴收集 |
| P10_Bonsai | `bonsai` | 盆栽三步开花 → d4 |
| P11_Checkin | `checkin` | 学在浙大签到 0798 → 红闪黑屏 |
| P12_Ending | `ending` | 错误框拦截小游戏 → 保留进度返回手机主页 |
| P13_PhoneHome | `phone_home` | 主屏：齿轮 d3 / 塔楼钥匙 / 水滴 / 盆栽入口 |
| P14_Wechat | `wechat` | 小影散码 + 朋友头像斜线谜题（原 P03） |
| P15_Zjuding | `zjuding` | 浙大钉：加载门禁 + 签到/我的导航 |
| P16_BikeArcade | `bike_arcade` | 竖屏三车道骑行小游戏 |
| P17_ChapterTransition | `chapter_transition` | 章节完成记录与后续入口 |
| P18_Photos | `photos` | 图书馆书包拍照与亮度证据处理 |

## 已并入其他位置的旧场景

- P03 头像谜题 → 并入 P14 微信聊天列表
- P05 控制中心 → 全局覆盖层 `src/components/ControlCenter.tsx`
- P08 设置 → 主屏设置齿轮图标交互（P13）
- P09 合成 → 物品栏拖拽合成 `src/components/InventoryBar.tsx`
- P10 Treehole 旧案 → 现行互动由 P10 盆栽与主屏完成

场景之间不要互相 import 内部文件；剧情逻辑统一走 `src/modules/GameKit.ts`。
