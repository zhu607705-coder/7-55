# 7:55 第一章完整剧情 + 视觉统一 实施计划

## 先行告知（无示例图、需自行设计的界面）

- **P11 校务签到输入页（学在浙大）**：浙大钉内界面绿色按键跳转的目标页没有示例图。
  将自行设计：像素风 4 位签到码输入框 + 数字键盘，风格延续浙大钉内界面的浅灰蓝配色。
- 其余此前缺图的界面均已由你补充（盆栽 2 张、校园卡余额、浙大钉加载/内页、现实画面）或
  确认无需内页（设置=主屏齿轮图标交互、天气=主屏组件交互、朋友头像=聊天列表内交互）。

## 目标

1. 视觉统一：引入开源像素中文字体（缝合像素 Fusion Pixel，OFL 协议），建立统一设计
   Token（纸色底、墨色描边、硬阴影、像素锯齿圆角），清理 styles.css 中大量重复/死代码。
2. 新增全局 UI：可收起的左侧物品栏（参照 pageexample/物品栏.png）、全局状态栏、
   控制中心下拉层、像素 Toast/字幕层、亮度滤镜、全屏震动特效。
3. 补完剧情：四条线索 → 集齐 0798 → 学在浙大签到 → 红闪黑屏 → 现实小房间。

## 剧情状态机（最终确认版）

```
P00 闹钟(振动+音效) → 关闭 → P01 07:55(再睡5分钟→旁白→起床蠢货) → P13 主屏
→ 1s后微信弹窗(朋友:老师点名/签到码) → P14 微信列表 → 朋友聊天
→ 朋友发"签到码 0798" → 小影猛击屏幕(全屏震动) → 四位数字飞散 → 任务:找回四位签到码
（物品栏自此出现）

线索1  浙大钉(需校园网,流量则卡加载) → 底部导航"我的" → 校园卡余额 ¥0.06
       → 点黄色的第二个0 → d1=0，吐槽"余额暂时不足以购买尊严"
线索2  浙大体艺：校园网下加载3s闪退，≥3次提示"校园网已经尽力了，你也是"/"我知道你没钱买流量"
       → 控制中心切流量 → 进入成功 → 打卡次数47(黄) → 点击 → d2=7
线索3  主屏设置齿轮：点击提示"它看起来很想转转" → 控制中心开"自动旋转"
       → 齿轮转180°掉落、背面朝外刻着9 → 点击 → d3=9 + 道具[反转齿轮]
线索4  a.控制中心播放音乐→耳机图标抖动→点击掉落→道具[耳机]
       b.主屏天气组件收集[水滴]
       c.微信列表·朋友头像(斜线)：自动旋转开启时斜线一端掉落挂在框上→点剩余端3次→整条掉落
         →"检测到未经授权的友情支援"→道具[斜线]
       d.物品栏内把[斜线]拖到[反转齿轮]上 → 合成[钥匙]
       e.选中[钥匙]点主屏塔楼 → 插入旋转90° → 获得[肥料]
       f.主屏盆栽摆件(点击提示"它绝对不会开花") → 盆栽页
         浇水(需耳机+水滴)/照光(需控制中心亮度拉高)/施肥(需肥料) 三项平行，各让植株长高一点
         → 全部完成开花 → 点花吐出数字8 → d4=8

P11 浙大钉绿色按键 → 校务签到页：流量提示"请连接校园网"；输错报错；
    输入0798 → "签""到"逐字跳出 → 全屏红闪 → 黑屏"经度或纬度不存在"
P12 黑屏 → 现实世界(小房间图) → 第一章·完
```

## 任务分解

### Task 1 字体与设计 Token
- `npm i fusion-pixel-12px-proportional-zh_hans`（或从 GitHub release curl woff2）；
  失败则回退系统字体栈并告知。
- 新建 `src/styles/`：`base.css`(token/字体/重置)、`components.css`(pixel-btn/panel/toast/
  modal/物品栏)、`scenes.css`(各场景)。删除旧 styles.css 中 `.zju-*`、`.home-*` 等死代码。

### Task 2 状态模型扩展（先改测试再实现）
- `types.ts`：ItemId = waterDrop|headphone|reverseGear|slashLine|towerKey|fertilizer；
  SceneId = alarm|desktop|phone_home|wechat|tiyi|zjuding|campus_card|checkin|bonsai|ending；
  flags 增：codeScattered、cardZeroTaken、tiyiCrashCount(数值)、gearFallen、headphoneFallen、
  slashHalfDropped、slashTapCount、slashTaken、towerOpened、plantWatered、plantLit、
  plantFertilized、flowerBloomed、checkinDone；ui 状态：autoRotate、musicPlaying、
  brightness(0-100)、controlCenterOpen。
- 更新 GameState/GameState.test、scenes.config.json、items.config.json、各场景 README。

### Task 3 全局壳层组件
- `StatusBar.tsx`：07:55 / 网络名(ZJUWLAN|流量|无网络) / 电量17%，点击右侧打开控制中心。
- `ToastLayer.tsx`：订阅 eventBus 的 `toast` 事件，像素气泡队列（系统吐槽/小影台词共用）。
- `InventoryBar.tsx`：左侧可收起竖排槽位（参照物品栏.png），pointer 拖拽合成
  （斜线+反转齿轮→钥匙，`CombineController` + 单测），点击选中→场景目标使用；
  底部显示签到码进度 `0?9?`；任务开始(codeScattered)后才出现。
- `ControlCenter.tsx`：参照 control_center.html 布局重制为统一像素风——
  WLAN/移动数据卡片（互斥切网）、音乐大卡(播放→耳机抖动→掉落收集)、亮度竖滑条
  (≥80 记 brightnessHigh，全局亮度滤镜)、自动旋转/振动等开关格。
- `PhoneShell.tsx` 集成以上 + 全屏震动 class + 亮度滤镜层。

### Task 4 场景迁移与重制（storyScenes.tsx 拆分至各编号文件夹 index.tsx）
- P00 闹钟、P01 起床：沿用现有逻辑，样式统一化。
- P13 主屏重制：应用格（CC98/微信/校园卡→浙大钉我的页/浙大体艺/设置齿轮/照片/控制中心/浙大钉）、
  天气组件（可收集水滴）、塔楼钥匙孔、湖边盆栽摆件入口、微信顶部通知（含第二条"这是签到码：XX"）、
  齿轮掉落动画。
- P14 微信重制为 DOM（弃用整图热区，因斜线头像需动画）：列表=文件传输助手/朋友(斜线头像)/
  室友/导师，朋友聊天页含小影袭击（震动+数字飞散+任务横幅），斜线两段式掉落谜题。

### Task 5 应用内页
- P06 浙大体艺：加载页(复用 浙大体艺加载.png) → 校园网 3s 闪退回主屏(计数+吐槽)；
  流量 → 主页(复用 浙大体艺.jpg) + 黄色"47"高亮热区 → d2=7。
- 浙大钉(新 P15 文件夹)：加载页(浙大钉加载.png)，流量永久卡加载+提示；校园网 →
  内页(浙大钉内界面.png 为底) + 自绘底部导航[学在浙大|我的] + 绿色卡片热区→签到页；
  "我的"→校园卡页。
- P04 校园卡余额：DOM 重制（蓝色像素卡片、¥0.06 第二个0为黄色可点）→ d1=0。
- P11 校务签到：自行设计（见先行告知）——4 格码输入+数字键盘；流量→"请连接校园网"；
  错码→红抖；0798→逐字"签到"→红闪→黑屏文案→ending。`CheckinController` + 单测。
- P10 盆栽：底图 盆栽花未开.png，底部三action(水滴/阳光/肥料)按条件解锁，每步植株放大一档；
  三项完成换 花开.png，点花吐出"8" → d4=8。`PlantController` + 单测。
- P12 结尾：黑屏打字机"经度或纬度不存在" → 现实画面.png + "第一章·完"。

### Task 6 资产与收尾
- pageexample 图片以 ASCII 名复制到 `src/assets/ui/`（tiyi_loading/tiyi_main/zjuding_loading/
  zjuding_home/bonsai_bud/bonsai_bloom/dorm_room 等）；如系统有 imagemagick 则压缩。
- 更新 registry、scenes.config.json、dialogue.lines.json、qa-checklist.md（新 14 步流程）、
  被合并场景文件夹 README 标注"已并入 XX"。
- App.test 扩展：主线冒烟（闹钟→主屏→微信→散码→物品栏出现）；模块单测覆盖合成/盆栽/签到。
- 验收：`npm run typecheck` + `npm test -- --run` + `npm run build` 全绿。
