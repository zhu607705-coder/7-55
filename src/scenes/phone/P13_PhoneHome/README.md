# P13 Phone Home 手机主界面

- Scene ID: `phone_home`
- Entry: P01 起床后；各应用返回时
- Reads: `flags.codeScattered/gearFallen/gearNineTaken/waterDropTaken/towerOpened/bonsaiHintShown`,
  `ui.autoRotate/selectedItem`, `items.towerKey`
- Writes: `digits.d3=9`、`items.reverseGear/waterDrop/fertilizer`、上述 flags
- Events: `gear_hint`, `collect_digit`, `get_item`, `use_item`
- 机关：
  - 设置齿轮：点击提示“它看起来很想转转”；自动旋转开启 → 转 180° 掉落 → 点背面 9 → d3 + 反转齿轮
  - 塔楼：物品栏选中钥匙后点击 → 插入旋转 90° → 一袋肥料
  - 天气组件：任务开始后点黄色雨滴 → 水滴
  - 湖边盆栽摆件：入口 → `bonsai`（首次提示“它绝对不会开花”）
  - 微信弹窗：1s/2.4s 两条消息，点击直达朋友聊天
- Tests: App.test 冒烟（进入微信 / 控制中心切网 / 浙大钉门禁）
