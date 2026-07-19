# 《7:55》第二章完整开发报告

章节名：022 的占座书包  
版本：V2.0  
日期：2026-07-12  
实现状态：主流程、音画事件、存档迁移、单文件构建均已完成  
主要技术：React 18、TypeScript、Zustand、Phaser 3、Pointer Events、CSS Animation、MiniMax CLI、Vite 单文件构建

## 核心一句话

玩家进入基础图书馆，发现二楼南区 `022` 被一个书包占用。玩家需要在 RPG 图书馆、浙大钉图书馆、照片、浙大体艺和 CC98 之间收集并认证四项材料，使剧情帖排名从 `04` 上升到 `01`，生成只对 `022` 书包有效的解除占座 `PASS`，回到 RPG 将书包转移到失物招领，坐上 `022`，获得第三章任务“找到那本借走签到记录的书”。

## 一、开发依据

本章有两个内容真源：

1. `docs/chapter-2-library-story.md`：对白、叙事顺序、任务文案、章节出口。
2. `docs/chapter-2-library-development-spec.md`：状态门槛、页面职责、道具用途、动画要求、验收标准。

实现报告记录当前真实代码。旧版 `63` 楼、`18` 条纯 `ac01`、`47 → 12 → 主楼` 引用链、路线截图、恢复口令和手机选座页拖 PASS 已退出第二章主流程。

## 二、章节入口

### 前置条件

玩家已完成第一章结尾的移动谜题：

```text
部门黄页确认姓名和学号
→ 浙大体艺开始课外锻炼
→ CC98 市场购买手柄
→ 玩家完成一次手动移动
→ actOne.canLeaveDorm = true
```

### 入口动作

玩家在校园 RPG 走到基础图书馆门口，触发：

```text
rpg_library_gate_requested
→ LibraryFinalsController.unlockLibraryRoute()
→ LibraryFinalsController.enterLibrary()
→ runtimeMode = rpg
→ rpgScene = library_interior
→ rpgCheckpoint = library_entrance
```

任务更新：

```text
进入图书馆，找到 022
```

演出：

- 图书馆入口门禁扫描。
- 章节任务面板显示 `022`。
- 播放 `music_library_arrival_v2`。
- 旁白使用 `vo_library_route_unlocked` 与 `vo_library_entered`。

## 三、P20 RPG 图书馆内部

### 逻辑画布

```text
RPG 逻辑尺寸：960 × 540
内部世界尺寸：1500 × 900
摄像机：跟随玩家，固定像素缩放
控制：WASD / 方向键 / 触控方向键 / A 交互
```

### 场景区域

1. 入口门禁与入馆记录。
2. 信息台。
3. 失物招领与物品身份盖章机。
4. 馆藏检索终端。
5. 打印机。
6. 文学书架与 `I247.55` 区域。
7. 二楼南区座位。
8. `022` 书包、纸条、桌面夹缝和座椅。

### 场景反馈

- 可交互物体显示上下浮动标记。
- 普通交互标记显示 `!`。
- 接受道具的目标显示向下箭头。
- 玩家接近目标时底部显示操作提示。
- 错误道具、错误位置、条件不完整分别显示独立反馈。
- 场景返回手机后保存命名检查点，再进入时从入口、前台、书架或 `022` 恢复。

## 四、P21 发现 022 占座书包

### 步骤 1：读取入馆记录

玩家走到门禁小屏幕并按 `A`：

```text
entranceRecordRead = true
clueIds += arrival_7_minutes
事件：library_entrance_record_read
```

得到数值线索：

```text
从寝室到 022：7 分钟
```

动画：门禁记录闪烁绿色，播放 `fx_arrival_record_v2`。

### 步骤 2：检查书包

玩家走到 `022` 并按 `A`：

```text
phase: library_entered → occupied_seat_found
backpackInspected = true
rpgCheckpoint = library_seat_022
事件：library_occupied_seat_found
```

动画：

- 书包与座位框连续震动。
- 座位边框由普通色变为红色。
- 占座纸条显现。
- 播放 `fx_backpack_alert_v2`。
- 配乐切换为 `music_library_evidence_v2`。

### 步骤 3：取得纸条

玩家按 `A` 拿起纸条：

```text
phase: occupied_seat_found → evidence_gathering
occupancyNoteCollected = true
items.occupancyNote = true
事件：library_occupancy_note_collected
```

动画：纸条上浮并淡出，播放 `fx_note_pickup_v2`。

任务更新：

```text
调查 022 的占座规则
```

## 五、P22 CC98 调查帖

### 入口

占座纸条取得后，CC98 显示剧情调查帖：

```text
标题：【求助】022 的书包已经三天没眨眼了
版面：校园生活
楼层：23
公示编号：47
```

帖子、作者名和回复全部为原创虚构内容，数据位于：

```text
src/data/library-finals.content.json
```

### 楼层结构

主线回复分布在 `1 / 4 / 12 / 18 / 23` 楼：

```text
1 楼：022 书包与三分钟离座现象
4 楼：入口记录只能证明到达时间
12 楼：搜索“三分钟离座法”
18 楼：证据齐全后进行 bd
23 楼：帖子进入排名 01 后开放恢复申请
```

可选 `ac01` 共 5 条：

```text
3 / 6 / 9 / 15 / 21 楼
```

这些回复提供论坛氛围，不参与过关判定。控制器最多记录 5 条，读完或跳过均可继续。

### 状态

```text
investigationOpened = true
optionalAc01Floors = [] 至最多 5 项
clueIds += public_notice_floor_47
事件：cc98_occupation_post_opened
```

音画：

- 配乐切换为 `music_cc98_publicity_v2`。
- 打开调查帖触发扫描反馈。
- 点击可选 `ac01` 只播放轻量提示音。
- 旁白提示帖子有 23 楼和 5 条可选 `ac01`。

## 六、P23 图书馆馆藏检索

### 页面入口

路径：

```text
浙大钉
→ 图书馆
→ 馆藏检索
```

页面保留参考图的主要结构：

1. 原生顶部栏。
2. 中文文献库 / 外文文献库切换。
3. 书名、关键词、范围和搜索按钮。
4. 高级检索入口。
5. 检索结果计数。
6. 可滚动的封面与书目信息列表。

### 搜索规则

唯一接受的题名：

```text
三分钟离座法
```

空格会被忽略。错误题名不显示剧情结果。

### 五本检索结果

搜索后同时显示五张用户提供的封面：

| 顺序 | 稳定 ID | 题名 | 结果 |
| ---: | --- | --- | --- |
| 1 | `three-minute-leave-method` | 三分钟离座法及其例外 | 正确 |
| 2 | `three-minute-seat-thinking` | 三分钟离席法与若干例外 | 混淆项 |
| 3 | `three-minute-pause` | 三分钟暂离法及其应用 | 混淆项 |
| 4 | `three-minute-stand-up` | 三分钟起身法与边界情况 | 混淆项 |
| 5 | `three-minute-empty-seat` | 三分钟空座法及其解释 | 混淆项 |

封面文件：

```text
src/assets/phone/library-search/three_minute_leave_method.png
src/assets/phone/library-search/three_minute_leave_art.png
src/assets/phone/library-search/three_minute_pause_application.png
src/assets/phone/library-search/three_minute_rise_boundaries.png
src/assets/phone/library-search/three_minute_empty_seat.png
```

### 误选处理

点击任一混淆项：

```text
事件：library_catalog_distractor_selected
播放：fx_catalog_wrong_v2
显示：该索书号与 022 没有可核对的关系
状态：不变
```

误选不会关闭结果列表，不会取得道具，不会推进 phase。

### 正确结果

点击《三分钟离座法及其例外》：

```text
callNumberCollected = true
items.callNumber755 = true
clueIds += call_number_755
索书号：I247.55 / 755
位置：基础馆二楼南区 755 号书架背面
事件：library_catalog_match_found
```

音效：`fx_catalog_correct_v2`。  
旁白：`vo_library_catalog_match_found`。

## 七、P24 书架背面旧版规则

玩家返回 RPG，拖动“索书号 755”到文学书架：

```text
目标：library_shelf_755
接受道具：callNumber755
动作：useCallNumberOnShelf()
```

成功状态：

```text
archivedRuleCollected = true
items.archivedLeaveRule = true
rpgCheckpoint = library_shelf_755
```

动画：

1. 书架横移 `72px`。
2. 背面纸张掉落。
3. 目标位置出现扩散闪光。
4. 播放 `fx_shelf_slide_v2`。

旧版规则说明恢复 `022` 需要三项证明：

```text
本人来过
座位确实为 022
当前占用物不具备人格
```

## 八、P25 照片亮度谜题

### 页面

手机照片新增：

```text
IMG_0755.JPG
对象：022 上的书包
初始问题：标签反光，无法识别
```

### 交互

玩家调节照片识别亮度。阈值为：

```text
brightness <= 20
```

达到阈值：

```text
photoDimmed = true
事件：photo_bag_label_revealed
播放：fx_photo_glare_clear_v2
```

标签显示：

```text
高数教材 x1
水杯 x1
充电器 x1
半包纸 x1
姓名：未检测到
学号：未检测到
人格：加载失败
```

点击“生成识别报告”：

```text
itemReportGenerated = true
items.itemRecognitionReport = true
事件：photo_bag_report_generated
播放：fx_report_print_v2
```

## 九、P26 失物身份登记

玩家返回 RPG，将“物品识别报告”拖到物品身份盖章机：

```text
目标：lost_found_machine
接受道具：itemRecognitionReport
动作：stampNonPersonProof()
```

结果：

```text
items.itemRecognitionReport = false
items.bagNonPersonProof = true
nonPersonProofStamped = true
rpgCheckpoint = library_front_desk
事件：library_bag_nonperson_proof_issued
```

动画：

- 报告沿进纸托盘送入机器，扫描线往返核验。
- 姓名、学号、人格三个核验灯依次更新。
- 压章头与侧面手柄同步下压，纸面出现红色“非本人”章。
- 报告从出纸口退出，再飞入 RPG 道具栏。
- 剧情对白延后到出纸完成后显示，不能遮挡压章和出纸过程。
- 播放 `fx_nonperson_stamp_v2`。

## 十、P27 022 座位小票

玩家将第一章保留的“右移箭头”拖到 `022` 桌面夹缝：

```text
目标：seat_022_gap
接受道具：rightArrow
动作：useRightArrowOnReceipt()
```

结果：

```text
seatReceiptCollected = true
items.seat022Receipt = true
items.rightArrow = true
```

右移箭头不消耗，可继续用于后续章节。

动画：

- 小票从夹缝向右滑出。
- 小票轻微旋转后收入道具栏。
- 播放 `fx_receipt_slide_v2`。

## 十一、P28 浙大体艺本人来过证明

### 页面职责

第一章的浙大体艺仍负责“开始课外锻炼”。第二章后期同一页面显示“本人来过证明补录单”。两个阶段读取不同状态，互不覆盖。

### 三项字段

| 字段 | 正确值 | 来源 |
| --- | ---: | --- |
| 到座耗时 | `7` | 入馆记录 |
| 公示编号 | `47` | CC98 调查帖第 23 楼楼主编辑 |
| 证明数量 | `3` | 旧版离座规则 |

错误提交：

```text
auditAttemptCount += 1
事件：tiyi_presence_audit_rejected
```

提示分三档逐步增加，不会在首次失败直接公布答案。

正确提交：

```text
presenceProofCollected = true
items.libraryPresenceProof = true
事件：tiyi_presence_proof_issued
```

音效：`fx_nonperson_stamp_v2` 以不同播放速度复用。  
旁白：`vo_tiyi_presence_proof_issued`。

## 十二、P29 CC98 证据公示与 BD 四位口令

### 四项上传材料

1. `archived_leave_rule`：旧版离座规则。
2. `bag_non_person_proof`：书包非本人证明。
3. `seat_022_receipt`：022 座位小票。
4. `library_presence_proof`：本人来过证明。

每项材料必须已存在于道具栏，重复上传无效。

第四项上传完成：

```text
phase: evidence_gathering → bd_briefing
事件：cc98_evidence_set_completed
```

剧情先明确：`bd` 表示“帮顶”；对数字回复点击 `bd` 会把该数字写入四位热度口令。

玩家确认说明后：

```text
phase: bd_briefing → top_ten_rising
事件：cc98_pre_bd_briefing_completed
```

### 八条数字回复

四项上传材料从上到下给出口令顺序：

```text
旧版规则要求数量 → 3
身份通过项数量 → 0
022 座位号末位 → 2
到座耗时 → 7
```

候选回复位于 `24–31` 楼，显示 `4 / 3 / 1 / 0 / 5 / 2 / 6 / 7` 八个数字及各自来源。玩家通过回复上的 `bd 选入` 按钮依次填充四个口令槽。

共享状态新增：

```text
bdSelectedPostIds
bdPasswordAttemptCount
```

控制器校验完整选择序列。错误提交清空选择并按尝试次数返回渐进提示；正确序列 `3027`：

```text
phase: top_ten_rising → top_ten_reached
rank: 04 → 01
事件：cc98_top_ten_reached
```

演出：

- 每次选入数字执行回复锁定与口令槽落位动画。
- 错误提交执行口令框抖动，低动态偏好直接显示稳定状态。
- 排名 `01` 触发高优先级演出。
- 播放 `fx_evidence_upload_v2` 与 `fx_pass_stamp_v2`。
- 配乐使用 `music_cc98_publicity_v2`。

## 十三、P30 图书馆 022 恢复申请

帖子达到排名 `01` 后，浙大钉图书馆开放：

```text
022 座位恢复申请
```

需要再次提交三项恢复材料：

1. 书包非本人证明。
2. 022 座位小票。
3. 本人来过证明。

三项齐全后点击生成：

```text
phase: recovery_application → pass_ready
evictionPassGenerated = true
items.seatReleasePass = true
事件：library_seat_release_pass_issued
```

页面只签发 PASS，不直接改变 `022` 状态。

音画：

- 配乐切换为 `music_library_enforcement_v2`。
- 盖章音效使用 `fx_pass_stamp_v2`。
- 旁白说明 PASS 仅对 `022` 书包有效。

## 十四、P31 回 RPG 解除占座

### 拖放 PASS

玩家返回 RPG，将 PASS 拖到占座书包：

```text
目标：seat_022_backpack
接受道具：seatReleasePass
动作：applyPassToBackpack()
```

结果：

```text
phase: pass_ready → backpack_removed
items.seatReleasePass = false
backpackEvicted = true
事件：library_seat_release_pass_applied
事件：library_backpack_evicted
```

动画：

1. PASS 从玩家位置旋转飞向书包。
2. 书包连续震动。
3. 四轮短对话依次出现。
4. 书包移动到失物招领方向并淡出。
5. `022` 边框变为绿色。
6. 播放 `fx_backpack_transfer_v2`。

### 坐下

玩家接近空出的椅子并按 `A`：

```text
phase: backpack_removed → seat_recovered
playerSeated = true
librarySelectedSeat = 022
librarySeatReserved = true
事件：library_seat_recovered
```

动画：玩家自动走到座位中心，配乐切换为 `music_library_022_reveal_v2`，播放 `fx_022_signal_v2`。

## 十五、P32 022 对话与第三章出口

玩家按 `A` 逐句推进对话。完整对白位于：

```text
src/data/library-finals.content.json
library.dialogue022
```

结论：

```text
签到记录不在系统里
→ 签到记录被借走
→ 借走记录的是一本书
```

对话结束：

```text
phase: seat_recovered → friend_contacted
nextQuestId = chapter_three_book_hunt
clueIds += borrowed_attendance_record
事件：library_friend_contacted
事件：chapter_three_book_hunt_unlocked
```

第三章任务：

```text
找到那本借走签到记录的书
```

## 十六、状态机

| Phase | 进入条件 | 主要动作 | 下一 Phase |
| --- | --- | --- | --- |
| `idle` | 第一章移动谜题未完成或第二章未开始 | 到达图书馆门口 | `library_route_unlocked` |
| `library_route_unlocked` | `actOne.canLeaveDorm` | 进入图书馆 | `library_entered` |
| `library_entered` | 图书馆场景启动 | 读入馆记录、检查书包 | `occupied_seat_found` |
| `occupied_seat_found` | 已检查书包 | 拿占座纸条 | `evidence_gathering` |
| `evidence_gathering` | 已取得纸条 | 收集并上传四项证据 | `bd_briefing` |
| `bd_briefing` | 四项证据已上传 | 确认 BD 与口令说明 | `top_ten_rising` |
| `top_ten_rising` | 四项证据已上传 | 完成 BD 四位口令 | `top_ten_reached` |
| `top_ten_reached` | 排名 01 | 打开恢复申请 | `recovery_application` |
| `recovery_application` | 申请已开放 | 提交三项材料、生成 PASS | `pass_ready` |
| `pass_ready` | PASS 已签发 | 在 RPG 对书包使用 PASS | `backpack_removed` |
| `backpack_removed` | 书包已转移 | 坐上 022 | `seat_recovered` |
| `seat_recovered` | 玩家已坐下 | 完成 022 对话 | `friend_contacted` |
| `friend_contacted` | 对话完成 | 显示第三章任务 | 章节终态 |

控制器对错误顺序返回 `false`，不写状态，不发成功事件。

## 十七、道具生命周期

| 道具 | 来源 | 使用目标 | 使用后 |
| --- | --- | --- | --- |
| `occupancyNote` | 022 纸条 | CC98 调查入口 | 保留 |
| `callNumber755` | 正确馆藏 | RPG 书架 | 保留 |
| `archivedLeaveRule` | 书架背面 | CC98 证据 | 保留 |
| `itemRecognitionReport` | 照片 | 失物登记机 | 消耗 |
| `bagNonPersonProof` | 失物登记机 | CC98 / 恢复申请 | 保留 |
| `rightArrow` | 第一章 | 022 桌面夹缝 | 保留 |
| `seat022Receipt` | 桌面夹缝 | CC98 / 恢复申请 | 保留 |
| `libraryPresenceProof` | 浙大体艺 | CC98 / 恢复申请 | 保留 |
| `seatReleasePass` | 图书馆恢复申请 | 022 占座书包 | 消耗 |

## 十八、音频与演出架构

### 解耦链路

```text
领域操作
→ EventBus 领域事件
→ PresentationDirector
→ presentation_cue
→ PresentationLayer / AudioDirector 各自消费
```

约束：

- `LibraryFinalsController` 不调用音频 API。
- `AudioDirector` 不修改游戏状态。
- 动画和音频之间没有直接调用。
- 删除某段动画不会阻止音频事件产生。
- 删除某段音频不会阻止状态推进。
- 自动播放受限或文件加载失败时，游戏逻辑继续执行。

### V2 资产

MiniMax CLI 已生成并验证：

```text
旁白：14 条
阶段配乐：5 段，每段 24 秒
动作音效：16 个
合计：35 个独立 MP3
```

配乐阶段：

1. `music_library_arrival_v2`
2. `music_library_evidence_v2`
3. `music_cc98_publicity_v2`
4. `music_library_enforcement_v2`
5. `music_library_022_reveal_v2`

旧版第二章 33 个无引用音频已删除，防止继续进入单文件。

## 十九、存档与迁移

存档包版本：

```text
version = 2
```

保存内容包括：

- 当前 phase。
- RPG 场景与命名检查点。
- 图书馆已访问区域。
- 四项证据进度。
- `7 / 47 / 3` 补录值与失败次数。
- CC98 上传、bd 次数和排名。
- 恢复申请材料。
- PASS、书包转移、座位与第三章任务状态。
- 右移箭头持有状态。

迁移规则：

- 旧版中间流程重置到 V2 可进入状态，避免旧字段造成软锁。
- 旧版已完成第二章映射到 `friend_contacted`。
- 第一章已经完成余额右移时恢复 `rightArrow`。
- 第二章完成不再自动解锁求是潮骑行章节。

## 二十、可编辑内容入口

后续调整剧情时优先修改：

```text
src/data/library-finals.content.json
```

可编辑内容：

- CC98 帖子标题、作者、正文、主线楼层和可选 `ac01`。
- 五本馆藏的题名、作者、索书号、年份、出版社、位置和说明。
- 八条 BD 数字候选回复、四项顺序提示和四位口令内容。
- 14 条旁白字幕。
- 022 完整对话。

规则数字集中在：

```text
src/data/library-finals.puzzle.json
```

封面映射只保留在页面组件中，文本不重复硬编码。

## 二十一、关键文件

```text
src/modules/LibraryFinalsController.ts
src/modules/library-finals/puzzleRules.ts
src/core/types.ts
src/core/GameState.ts
src/core/SaveStore.ts
src/scenes/rpg/LibraryInteriorScene.ts
src/scenes/rpg/LibraryInteriorModel.ts
src/scenes/rpg/RpgInventoryDock.tsx
src/scenes/phone/P02_CC98/
src/scenes/phone/P06_Tiyi/
src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx
src/scenes/phone/P15_Zjuding/index.tsx
src/data/library-finals.content.json
src/data/library-finals.audio.json
src/data/library-finals.audio.generated.json
scripts/generate-library-finals-audio.mjs
```

## 二十二、验证结果

### 类型和逻辑

```text
npm run typecheck
结果：通过

npm run test:run
结果：40 个测试文件、170 项全部通过
```

覆盖内容包括：

- 16 步控制器完整流程。
- 错误顺序无状态写入。
- 五本书同时显示，四个混淆项无进度。
- 5 条可选 `ac01` 不构成门槛。
- 四项证据必须齐全。
- 仅按四项证据顺序选择的 `3 / 0 / 2 / 7` 有效。
- 排名 `04 → 01`。
- 补录仅接受 `7 / 47 / 3`。
- PASS 只在 RPG 对书包生效。
- 右移箭头使用后保留。
- 第二章不会自动解锁骑行章节。
- V2 存档与旧版迁移。
- RPG 拖放坐标从 DOM 视口正确换算到 `960 × 540` 画布。
- 35 个音频文件可解码，五段配乐时长与响度合格。

### 音频验证

```text
npm run audio:library-finals -- --verify-only
结果：35 个资产全部通过
```

### 单文件

```text
npm run build:single
输出：demo/index.html
大小：65,472,222 bytes
外链脚本：0
外链样式：0
外部资源标签：0
```

五张馆藏封面、14 条 V2 旁白均已核对为内嵌数据。

## 二十三、人工视觉验收入口

开发服务器：

```text
http://127.0.0.1:5173/
```

馆藏检索直达入口：

```text
http://127.0.0.1:5173/?scene=zjuding&zjudingPage=library_catalog&libraryFinalsPhase=evidence_gathering
```

人工检查项目：

1. 搜索框输入“三分钟离座法”后显示五本书。
2. 五张封面与用户提供素材一致。
3. 混淆项点击后保留页面并显示错误反馈。
4. 正确书点击后显示 `I247.55 / 755`。
5. 竖屏手机保持 `430 × 930` 逻辑比例，无非等比拉伸。
6. 列表滚动时顶部栏与搜索区不遮挡结果。
7. RPG 保持 `16:9`，道具拖动在缩放后仍落到正确目标。
8. 旁白、配乐和音效按阶段有明显区分。
9. 返回手机再进入 RPG 后从最近检查点恢复。
10. 022 对话完成后任务更新为“找到那本借走签到记录的书”。

## 二十四、当前边界

- 本轮完成代码、状态、音频、单文件和静态内联验证。
- 自动化浏览器视觉导航未列为交付门槛，最终视觉与操作手感由人工在开发服务器和单文件中确认。
- 第三章骑行仍保留独立显式解锁，不由第二章完成状态自动触发。
