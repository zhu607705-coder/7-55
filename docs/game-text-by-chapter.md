# 《7:55》游戏文本总表

> 本文件由 `npm run text:export` 从当前 `src/` 自动生成。请修改源文件后重新导出，不要只修改本文件。

- 文本条目：6375
- 来源文件：136
- 收录范围：剧情对白、字幕、任务说明、交互提示、按钮、页面标题、帖子、物品说明、失败反馈与玩家可见状态文案。
- 排除范围：开发者面板、测试断言、内部 ID、CSS 类名、资源路径、存档字段和运行时调试信息。
- 去重规则：同一章节内完全相同的文本合并为一条，全部源码位置仍保留。
- 模板规则：动态表达式显示为 `{{表达式}}`。

## 章节索引

| 章节 | 文本条目 |
| --- | ---: |
| [第一章](#第一章) | 409 |
| [第二章](#第二章) | 403 |
| [第三章](#第三章) | 1175 |
| [3.5章过渡](#35章过渡) | 299 |
| [第四章](#第四章) | 1302 |
| [结局](#结局) | 89 |
| [跨章节与共用系统](#跨章节与共用系统) | 2698 |

## 第一章

1. 已找到的签到数字：{{digitSlots .map((digit, index) =&gt; \`第${index + 1}位${digit ?? "未找到"}\`) .join("，")}}
   来源：[src/components/QuestClueStrip.tsx:105](../src/components/QuestClueStrip.tsx#L105)
2. 返回任务现场
   来源：[src/components/QuestClueStrip.tsx:112](../src/components/QuestClueStrip.tsx#L112)
3. 前往相关界面
   来源：[src/components/QuestClueStrip.tsx:112](../src/components/QuestClueStrip.tsx#L112)
4. 查看信息
   来源：[src/core/QuestModel.ts:53](../src/core/QuestModel.ts#L53)
5. 找签到码（{{digitCount}}/4）
   来源：[src/core/QuestModel.ts:60](../src/core/QuestModel.ts#L60)
6. 先检查浙大体艺、设置齿轮和盆栽相关界面。
   来源：[src/core/QuestModel.ts:62](../src/core/QuestModel.ts#L62)
7. 道具可以拖拽合并。
   来源：[src/core/QuestModel.ts:63](../src/core/QuestModel.ts#L63)
8. 浙大体艺打不开时，试试换一种网络。
   来源：[src/core/QuestModel.ts:64](../src/core/QuestModel.ts#L64)
9. 微信界面也用“自动旋转”
   来源：[src/core/QuestModel.ts:65](../src/core/QuestModel.ts#L65)
10. 光照在控制中心拖动调节
   来源：[src/core/QuestModel.ts:66](../src/core/QuestModel.ts#L66)
11. 还有一个在签到页面
   来源：[src/core/QuestModel.ts:67](../src/core/QuestModel.ts#L67)
12. 去签到
   来源：[src/core/QuestModel.ts:74](../src/core/QuestModel.ts#L74)
13. 五分钟
   来源：[src/core/QuestModel.ts:81](../src/core/QuestModel.ts#L81)
14. 林星宇
   来源：[src/data/act-one-bootstrap.content.json:3](../src/data/act-one-bootstrap.content.json#L3)
15. 游戏卡带
   来源：[src/data/act-one-bootstrap.content.json:21](../src/data/act-one-bootstrap.content.json#L21)
16. 第一章的实体入口。标签上只印着 7:55。
   来源：[src/data/act-one-bootstrap.content.json:22](../src/data/act-one-bootstrap.content.json#L22)
17. 南大门
   来源：[src/data/act-one-bootstrap.content.json:25](../src/data/act-one-bootstrap.content.json#L25)
18. 启真湖桥
   来源：[src/data/act-one-bootstrap.content.json:26](../src/data/act-one-bootstrap.content.json#L26)
19. 基础馆
   来源：[src/data/act-one-bootstrap.content.json:27](../src/data/act-one-bootstrap.content.json#L27)；[src/modules/ActOneBootstrapController.ts:522](../src/modules/ActOneBootstrapController.ts#L522)
20. 校园地图终端
   来源：[src/data/act-one-bootstrap.content.json:28](../src/data/act-one-bootstrap.content.json#L28)
21. 校园服务台
   来源：[src/data/act-one-bootstrap.content.json:31](../src/data/act-one-bootstrap.content.json#L31)
22. 游戏联络台
   来源：[src/data/act-one-bootstrap.content.json:32](../src/data/act-one-bootstrap.content.json#L32)
23. 体艺值班台
   来源：[src/data/act-one-bootstrap.content.json:33](../src/data/act-one-bootstrap.content.json#L33)
24. 完成签到
   来源：[src/data/act-one-bootstrap.content.json:36](../src/data/act-one-bootstrap.content.json#L36)
25. 查看朋友的新消息
   来源：[src/data/act-one-bootstrap.content.json:37](../src/data/act-one-bootstrap.content.json#L37)
26. 找到系统
   来源：[src/data/act-one-bootstrap.content.json:38](../src/data/act-one-bootstrap.content.json#L38)
27. 找到道具栏
   来源：[src/data/act-one-bootstrap.content.json:39](../src/data/act-one-bootstrap.content.json#L39)
28. 带着道具栏回去找系统
   来源：[src/data/act-one-bootstrap.content.json:40](../src/data/act-one-bootstrap.content.json#L40)
29. 找到移动的办法
   来源：[src/data/act-one-bootstrap.content.json:41](../src/data/act-one-bootstrap.content.json#L41)；[src/data/act-one-bootstrap.content.json:42](../src/data/act-one-bootstrap.content.json#L42)；[src/data/act-one-bootstrap.content.json:43](../src/data/act-one-bootstrap.content.json#L43)；[src/data/act-one-bootstrap.content.json:44](../src/data/act-one-bootstrap.content.json#L44)；[src/data/act-one-bootstrap.content.json:46](../src/data/act-one-bootstrap.content.json#L46)；[src/data/act-one-bootstrap.content.json:47](../src/data/act-one-bootstrap.content.json#L47)
30. 可以出门了
   来源：[src/data/act-one-bootstrap.content.json:45](../src/data/act-one-bootstrap.content.json#L45)；[src/data/act-one-bootstrap.content.json:48](../src/data/act-one-bootstrap.content.json#L48)
31. 前往图书馆寻找系统的朋友
   来源：[src/data/act-one-bootstrap.content.json:49](../src/data/act-one-bootstrap.content.json#L49)
32. 他听不到你说话。
   来源：[src/data/act-one-bootstrap.content.json:52](../src/data/act-one-bootstrap.content.json#L52)
33. 这位同学目前连自己的名字都不知道。
   来源：[src/data/act-one-bootstrap.content.json:53](../src/data/act-one-bootstrap.content.json#L53)
34. 他走起来了，但他不知道该往哪里走。
   来源：[src/data/act-one-bootstrap.content.json:54](../src/data/act-one-bootstrap.content.json#L54)
35. 手柄已经到货，方向输入等待校验。
   来源：[src/data/act-one-bootstrap.content.json:55](../src/data/act-one-bootstrap.content.json#L55)
36. 这张卡带上只写了 7:55，它显然不是课程表。
   来源：[src/data/act-one-bootstrap.content.json:56](../src/data/act-one-bootstrap.content.json#L56)
37. 可以出门了。
   来源：[src/data/act-one-bootstrap.content.json:57](../src/data/act-one-bootstrap.content.json#L57)
38. Excellent. You opened the game. Now kindly apply for permission to operate yourself.
   来源：[src/data/act-one-bootstrap.content.json:61](../src/data/act-one-bootstrap.content.json#L61)
39. 很好，你打开了游戏。现在请先去申请操作自己。
   来源：[src/data/act-one-bootstrap.content.json:62](../src/data/act-one-bootstrap.content.json#L62)
40. Identity verified. The character finally has a name. The network remains unconvinced.
   来源：[src/data/act-one-bootstrap.content.json:67](../src/data/act-one-bootstrap.content.json#L67)
41. 登录成功。这个角色终于有名字了，仍然没联网。
   来源：[src/data/act-one-bootstrap.content.json:68](../src/data/act-one-bootstrap.content.json#L68)
42. Call connected. Using a student ID as a phone number is distressingly on brand.
   来源：[src/data/act-one-bootstrap.content.json:73](../src/data/act-one-bootstrap.content.json#L73)
43. 电话接通。用学号当电话号码，很有校园特色。
   来源：[src/data/act-one-bootstrap.content.json:74](../src/data/act-one-bootstrap.content.json#L74)
44. The controls have arrived. Sports has not yet approved the act of walking.
   来源：[src/data/act-one-bootstrap.content.json:79](../src/data/act-one-bootstrap.content.json#L79)
45. 方向键到货。体艺还没批准你走路。
   来源：[src/data/act-one-bootstrap.content.json:80](../src/data/act-one-bootstrap.content.json#L80)
46. Exercise started. Congratulations. You are now officially permitted to walk.
   来源：[src/data/act-one-bootstrap.content.json:85](../src/data/act-one-bootstrap.content.json#L85)
47. 锻炼开始。恭喜，你现在被允许步行。
   来源：[src/data/act-one-bootstrap.content.json:86](../src/data/act-one-bootstrap.content.json#L86)
48. Cartridge acquired. Keep walking. Apparently all four areas require your personal attendance.
   来源：[src/data/act-one-bootstrap.content.json:91](../src/data/act-one-bootstrap.content.json#L91)
49. 卡带拿到了。继续把地图走完，四个区域一个都不能漏。
   来源：[src/data/act-one-bootstrap.content.json:92](../src/data/act-one-bootstrap.content.json#L92)
50. Map complete. The menu is open, and the system has formally recorded your ability to walk. A historic day.
   来源：[src/data/act-one-bootstrap.content.json:97](../src/data/act-one-bootstrap.content.json#L97)
51. 全图已刷。游戏菜单已开放，系统已记录你会走路。
   来源：[src/data/act-one-bootstrap.content.json:98](../src/data/act-one-bootstrap.content.json#L98)
52. Pfft, oh, sorry. I did not mean anything by it. It is just... this does not look like a success, does it? I suppose you will have to get up, drag yourself to class, and deal with it. Good luck, kid! I am leaving!
   来源：[src/data/act-one-bootstrap.content.json:103](../src/data/act-one-bootstrap.content.json#L103)
53. 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。我想你只好乖乖起来滚去上课了。祝你好运，孩子！我要走了！
   来源：[src/data/act-one-bootstrap.content.json:104](../src/data/act-one-bootstrap.content.json#L104)
54. 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。
   来源：[src/data/act-one-bootstrap.content.json:106](../src/data/act-one-bootstrap.content.json#L106)
55. 我想你只好乖乖起来滚去上课了。
   来源：[src/data/act-one-bootstrap.content.json:107](../src/data/act-one-bootstrap.content.json#L107)
56. 祝你好运，孩子！我要走了！
   来源：[src/data/act-one-bootstrap.content.json:108](../src/data/act-one-bootstrap.content.json#L108)
57. Pfft, oh, sorry. I did not mean anything by it. It is just... this does not look like a success, does it?
   来源：[src/data/act-one-bootstrap.content.json:114](../src/data/act-one-bootstrap.content.json#L114)
58. I suppose you will have to get up, drag yourself to class, and deal with it.
   来源：[src/data/act-one-bootstrap.content.json:118](../src/data/act-one-bootstrap.content.json#L118)
59. Good luck, kid! I am leaving!
   来源：[src/data/act-one-bootstrap.content.json:122](../src/data/act-one-bootstrap.content.json#L122)
60. Hey! What exactly do you think you are doing? Let go of me!
   来源：[src/data/act-one-bootstrap.content.json:128](../src/data/act-one-bootstrap.content.json#L128)
61. 嘿！你到底在干什么？放开我！
   来源：[src/data/act-one-bootstrap.content.json:129](../src/data/act-one-bootstrap.content.json#L129)
62. Oh, fine, fine! But first, take your hand off me!
   来源：[src/data/act-one-bootstrap.content.json:134](../src/data/act-one-bootstrap.content.json#L134)
63. 哦，好吧，好吧！但你先把手放开！
   来源：[src/data/act-one-bootstrap.content.json:135](../src/data/act-one-bootstrap.content.json#L135)
64. Oh, damn it. You win, kid.
   来源：[src/data/act-one-bootstrap.content.json:140](../src/data/act-one-bootstrap.content.json#L140)
65. 哦，该死。你赢了，孩子。
   来源：[src/data/act-one-bootstrap.content.json:141](../src/data/act-one-bootstrap.content.json#L141)
66. Fine. Bring out your inventory.
   来源：[src/data/act-one-bootstrap.content.json:146](../src/data/act-one-bootstrap.content.json#L146)
67. 行。把你的道具栏拿出来。
   来源：[src/data/act-one-bootstrap.content.json:147](../src/data/act-one-bootstrap.content.json#L147)
68. Wait. Where is your inventory? You cannot expect me to work empty-handed!
   来源：[src/data/act-one-bootstrap.content.json:152](../src/data/act-one-bootstrap.content.json#L152)
69. 等等，你的道具栏呢？你总不能指望我空手干活！
   来源：[src/data/act-one-bootstrap.content.json:153](../src/data/act-one-bootstrap.content.json#L153)
70. Just. Find it.
   来源：[src/data/act-one-bootstrap.content.json:158](../src/data/act-one-bootstrap.content.json#L158)
71. 去。找。到。它。
   来源：[src/data/act-one-bootstrap.content.json:159](../src/data/act-one-bootstrap.content.json#L159)
72. You found it. Great. Then let us get moving.
   来源：[src/data/act-one-bootstrap.content.json:164](../src/data/act-one-bootstrap.content.json#L164)
73. 你找到了，那就太好了，我们出发吧！
   来源：[src/data/act-one-bootstrap.content.json:165](../src/data/act-one-bootstrap.content.json#L165)
74. I should be honest. I do not have permission to edit attendance records.
   来源：[src/data/act-one-bootstrap.content.json:170](../src/data/act-one-bootstrap.content.json#L170)
75. 我得说实话了，我没有修改记录权限
   来源：[src/data/act-one-bootstrap.content.json:171](../src/data/act-one-bootstrap.content.json#L171)
76. But I have a friend who might.
   来源：[src/data/act-one-bootstrap.content.json:176](../src/data/act-one-bootstrap.content.json#L176)
77. 但我有一个朋友她或许能做到
   来源：[src/data/act-one-bootstrap.content.json:177](../src/data/act-one-bootstrap.content.json#L177)
78. If we still want your participation grade, we need to find her in the library.
   来源：[src/data/act-one-bootstrap.content.json:182](../src/data/act-one-bootstrap.content.json#L182)
79. 如果我们还想要平时分，就得去图书馆找她
   来源：[src/data/act-one-bootstrap.content.json:183](../src/data/act-one-bootstrap.content.json#L183)
80. Understood? Then move.
   来源：[src/data/act-one-bootstrap.content.json:188](../src/data/act-one-bootstrap.content.json#L188)
81. 明白了？那就快行动吧！
   来源：[src/data/act-one-bootstrap.content.json:189](../src/data/act-one-bootstrap.content.json#L189)
82. He cannot hear you. At the moment, he does not even have a name to answer to.
   来源：[src/data/act-one-bootstrap.content.json:194](../src/data/act-one-bootstrap.content.json#L194)
83. 他听不到你说话。现在的他连一个能回应的名字都没有。
   来源：[src/data/act-one-bootstrap.content.json:195](../src/data/act-one-bootstrap.content.json#L195)
84. Name and student ID match. Good. He now knows who he is.
   来源：[src/data/act-one-bootstrap.content.json:200](../src/data/act-one-bootstrap.content.json#L200)
85. 姓名和学号一致。很好，他现在知道自己是谁了。
   来源：[src/data/act-one-bootstrap.content.json:201](../src/data/act-one-bootstrap.content.json#L201)
86. Exercise record synced. Check the new Direction Calibration notice on the phone home screen.
   来源：[src/data/act-one-bootstrap.content.json:206](../src/data/act-one-bootstrap.content.json#L206)
87. 锻炼记录已同步。
   来源：[src/data/act-one-bootstrap.content.json:207](../src/data/act-one-bootstrap.content.json#L207)
88. Triangle collected. Open Weather next and catch one drop of rain.
   来源：[src/data/act-one-bootstrap.content.json:212](../src/data/act-one-bootstrap.content.json#L212)
89. 获得道具：三角形。
   来源：[src/data/act-one-bootstrap.content.json:213](../src/data/act-one-bootstrap.content.json#L213)
90. Weather drop collected. Use it on the stuck vertical line beside the mentor avatar.
   来源：[src/data/act-one-bootstrap.content.json:218](../src/data/act-one-bootstrap.content.json#L218)
91. 获得道具：天气水滴。
   来源：[src/data/act-one-bootstrap.content.json:219](../src/data/act-one-bootstrap.content.json#L219)
92. That vertical line is stuck. Apparently, even your advisor's avatar has formatting requirements.
   来源：[src/data/act-one-bootstrap.content.json:224](../src/data/act-one-bootstrap.content.json#L224)
93. 那条竖线粘住了。看来导师头像也有自己的排版要求。
   来源：[src/data/act-one-bootstrap.content.json:225](../src/data/act-one-bootstrap.content.json#L225)
94. A triangle plus a vertical line. You now have an arrow that can move things to the right.
   来源：[src/data/act-one-bootstrap.content.json:230](../src/data/act-one-bootstrap.content.json#L230)
95. 一个三角形加一条竖线。现在你有了一支能把东西向右移的箭头。
   来源：[src/data/act-one-bootstrap.content.json:231](../src/data/act-one-bootstrap.content.json#L231)
96. The decimal point moved two places right. Six cents has temporarily acquired the dignity of six yuan.
   来源：[src/data/act-one-bootstrap.content.json:236](../src/data/act-one-bootstrap.content.json#L236)
97. 小数点向右移动了两位。六分钱暂时获得了六元钱的尊严。
   来源：[src/data/act-one-bootstrap.content.json:237](../src/data/act-one-bootstrap.content.json#L237)
98. You only have zero point zero six yuan. The seller rejected your hundred-installment plan.
   来源：[src/data/act-one-bootstrap.content.json:242](../src/data/act-one-bootstrap.content.json#L242)
99. 你只有零点零六元。卖家拒绝了你分一百期付款的方案。
   来源：[src/data/act-one-bootstrap.content.json:243](../src/data/act-one-bootstrap.content.json#L243)
100. You can leave now.
   来源：[src/data/act-one-bootstrap.content.json:248](../src/data/act-one-bootstrap.content.json#L248)
101. 现在可以出门了。
   来源：[src/data/act-one-bootstrap.content.json:249](../src/data/act-one-bootstrap.content.json#L249)
102. 蓝田六舍 · W12
   来源：[src/data/act-one-bootstrap.content.json:255](../src/data/act-one-bootstrap.content.json#L255)
103. 室友留言：你的校园卡压在右边书桌那摞纸旁边。
   来源：[src/data/act-one-bootstrap.content.json:256](../src/data/act-one-bootstrap.content.json#L256)
104. 校园卡
   来源：[src/data/act-one-bootstrap.content.json:257](../src/data/act-one-bootstrap.content.json#L257)
105. 返回校园地图
   来源：[src/data/act-one-bootstrap.content.json:258](../src/data/act-one-bootstrap.content.json#L258)
106. 手柄毕业生
   来源：[src/data/act-one-bootstrap.content.json:262](../src/data/act-one-bootstrap.content.json#L262)
107. 二手市场
   来源：[src/data/act-one-bootstrap.content.json:265](../src/data/act-one-bootstrap.content.json#L265)
108. 6块出游戏手柄，寝室自提
   来源：[src/data/act-one-bootstrap.content.json:266](../src/data/act-one-bootstrap.content.json#L266)
109. 26-07-11 07:55
   来源：[src/data/act-one-bootstrap.content.json:269](../src/data/act-one-bootstrap.content.json#L269)
110. 方向键、摇杆和一个不太灵的 A 键都在。只收 6 元，不议价，也不接受 0.06 元分期。
   来源：[src/data/act-one-bootstrap.content.json:270](../src/data/act-one-bootstrap.content.json#L270)
111. 支付 6 元购买手柄
   来源：[src/data/act-one-bootstrap.content.json:271](../src/data/act-one-bootstrap.content.json#L271)
112. checkin\_incomplete
   来源：[src/modules/ActOneBootstrapController.ts:75](../src/modules/ActOneBootstrapController.ts#L75)
113. capture\_incomplete
   来源：[src/modules/ActOneBootstrapController.ts:86](../src/modules/ActOneBootstrapController.ts#L86)
114. 他好像没什么动力走
   来源：[src/modules/ActOneBootstrapController.ts:192](../src/modules/ActOneBootstrapController.ts#L192)
115. 他可能不太知道往哪边走
   来源：[src/modules/ActOneBootstrapController.ts:196](../src/modules/ActOneBootstrapController.ts#L196)
116. 在寝室刷3公里的想法不错
   来源：[src/modules/ActOneBootstrapController.ts:197](../src/modules/ActOneBootstrapController.ts#L197)
117. campus\_card\_required
   来源：[src/modules/ActOneBootstrapController.ts:333](../src/modules/ActOneBootstrapController.ts#L333)
118. not\_owned
   来源：[src/modules/ActOneBootstrapController.ts:447](../src/modules/ActOneBootstrapController.ts#L447)
119. inactive
   来源：[src/modules/ActOneBootstrapController.ts:451](../src/modules/ActOneBootstrapController.ts#L451)
120. identity\_required
   来源：[src/modules/ActOneBootstrapController.ts:455](../src/modules/ActOneBootstrapController.ts#L455)
121. exercise\_required
   来源：[src/modules/ActOneBootstrapController.ts:459](../src/modules/ActOneBootstrapController.ts#L459)
122. wrong\_library
   来源：[src/modules/ActOneBootstrapController.ts:523](../src/modules/ActOneBootstrapController.ts#L523)
123. 二层南
   来源：[src/modules/ActOneBootstrapController.ts:526](../src/modules/ActOneBootstrapController.ts#L526)
124. wrong\_room
   来源：[src/modules/ActOneBootstrapController.ts:527](../src/modules/ActOneBootstrapController.ts#L527)
125. wrong\_seat
   来源：[src/modules/ActOneBootstrapController.ts:531](../src/modules/ActOneBootstrapController.ts#L531)
126. 早八闹钟
   来源：[src/scenes/phone/P00_Alarm/index.tsx:83](../src/scenes/phone/P00_Alarm/index.tsx#L83)
127. 学在浙大签到还剩 5 分钟
   来源：[src/scenes/phone/P00_Alarm/index.tsx:85](../src/scenes/phone/P00_Alarm/index.tsx#L85)
128. 开始游戏
   来源：[src/scenes/phone/P00_Alarm/index.tsx:90](../src/scenes/phone/P00_Alarm/index.tsx#L90)
129. 关闭
   来源：[src/scenes/phone/P00_Alarm/index.tsx:94](../src/scenes/phone/P00_Alarm/index.tsx#L94)
130. ZJUWLAN · 17%
   来源：[src/scenes/phone/P01_Desktop/index.tsx:33](../src/scenes/phone/P01_Desktop/index.tsx#L33)
131. （我）
   来源：[src/scenes/phone/P01_Desktop/index.tsx:38](../src/scenes/phone/P01_Desktop/index.tsx#L38)
132. ……再睡5分钟……
   来源：[src/scenes/phone/P01_Desktop/index.tsx:40](../src/scenes/phone/P01_Desktop/index.tsx#L40)
133. 起床蠢货
   来源：[src/scenes/phone/P01_Desktop/index.tsx:46](../src/scenes/phone/P01_Desktop/index.tsx#L46)
134. 进入手机主界面
   来源：[src/scenes/phone/P01_Desktop/index.tsx:50](../src/scenes/phone/P01_Desktop/index.tsx#L50)
135. 旁白
   来源：[src/scenes/phone/P01_Desktop/index.tsx:57](../src/scenes/phone/P01_Desktop/index.tsx#L57)
136. 你没有5分钟了，但你很有勇气
   来源：[src/scenes/phone/P01_Desktop/index.tsx:58](../src/scenes/phone/P01_Desktop/index.tsx#L58)
137. 水帖
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:26](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L26)
138. caption
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:37](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L37)
139. 路过
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:55](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L55)
140. 022占座调查帖回复
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:66](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L66)
141. 23 楼调查记录
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:69](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L69)
142. 关键线索分布在不同用户的回复和引用中。
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:70](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L70)
143. ac01 已读
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:72](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L72)
144. 楼
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:92](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L92)
145. CC98 bd 表情包
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:98](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L98)
146. 读一下（可选）
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:109](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L109)
147. 已记下这条水帖
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:109](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L109)
148. 条 ac01 全部为可选内容；证据进度不会因此变化。
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:118](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L118)
149. 卖家暂时不认识这段剧情。
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:26](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L26)
150. system
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:26](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L26)；[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:30](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L30)；[src/scenes/phone/P06_Tiyi/index.tsx:78](../src/scenes/phone/P06_Tiyi/index.tsx#L78)；[src/scenes/phone/P06_Tiyi/index.tsx:82](../src/scenes/phone/P06_Tiyi/index.tsx#L82)；[src/scenes/phone/P11_Checkin/index.tsx:93](../src/scenes/phone/P11_Checkin/index.tsx#L93)
151. 手柄已经在道具栏里。
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:30](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L30)
152. 支付成功：游戏手柄已放入道具栏。
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:33](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L33)
153. task
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:33](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L33)；[src/scenes/phone/P06_Tiyi/index.tsx:72](../src/scenes/phone/P06_Tiyi/index.tsx#L72)；[src/scenes/phone/P10_Bonsai/index.tsx:92](../src/scenes/phone/P10_Bonsai/index.tsx#L92)；[src/scenes/phone/P11_Checkin/index.tsx:115](../src/scenes/phone/P11_Checkin/index.tsx#L115)
154. CC98游戏手柄交易
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:43](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L43)
155. 二手游戏手柄 × 1
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:50](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L50)
156. 商品
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:50](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L50)
157. ¥6.00，不议价
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:51](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L51)
158. 售价
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:51](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L51)
159. 你的余额
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:52](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L52)
160. 收货人
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:54](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L54)
161. 身份信息尚未读取
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:55](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L55)
162. 回寝室试用手柄
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:59](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L59)
163. 这个槽位需要对应名称的纸质材料。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:142](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L142)
164. 这份材料还没有形成可核对的道具。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:152](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L152)
165. 当前阶段不能选入这条回复。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:159](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L159)
166. CC98证据与十大排名
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:189](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L189)
167. 楼主证据上传区
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:191](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L191)
168. 楼主编辑：上传证据
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:194](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L194)
169. 证据完整度：
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:195](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L195)
170. 待补齐
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:197](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L197)
171. 等待说明
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:197](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L197)
172. 可生成口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:197](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L197)
173. 上传
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:218](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L218)
174. 未获得
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:218](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L218)
175. 已上传
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:218](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L218)
176. 当前排名
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:227](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L227)
177. 请先上传四项证据
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:229](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L229)
178. 十大第一
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:229](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L229)
179. 完成 BD 四位口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:229](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L229)
180. BD四位热度口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:233](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L233)
181. 口令顺序提示
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:239](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L239)
182. 当前口令 {{selectedPostIds.map((id) =&gt; BD\_DIGIT\_BY\_POST.get(id)).join("") \|\| "空"}}
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:244](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L244)
183. 撤回一位
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:248](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L248)
184. 清空
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:249](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L249)
185. 提交口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:250](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L250)
186. 已通过
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:250](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L250)
187. 数字候选回复
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:254](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L254)
188. 口令第 {{selectedIndex + 1}} 位
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:260](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L260)
189. 楼 ·
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:260](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L260)
190. 数字回复
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:260](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L260)
191. 数字 {{post.digit}}
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:262](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L262)
192. 对 {{post.floor}} 楼回复 bd，选入数字 {{post.digit}}
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:266](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L266)
193. 第 {{selectedIndex + 1}} 位
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:269](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L269)
194. bd 选入
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:269](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L269)
195. 公示排名已更新为 01。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:277](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L277)
196. 先从随身校园卡确认账号，再拆开密码提示。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:26](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L26)
197. 随身物品里没有校园卡，当前无法确认 10 位学号。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:47](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L47)
198. 校园卡已读取：{{actOneContent.studentName}}，学号已填入。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:51](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L51)
199. 提示 {{count}}/3 已展开：{{hint.clue}}
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:58](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L58)
200. 三段密码提示已经全部展开，按顺序拼接即可。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:60](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L60)
201. 认证通过，正在进入 CC98。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:68](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L68)
202. 先读取校园卡上的学号，再提交认证。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:72](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L72)
203. 尝试暂时锁定，还需等待 {{formatWaitSeconds(result.remainingMs)}}。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:77](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L77)
204. 学号与校园卡不一致。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:83](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L83)
205. 密码片段、顺序或大小写不正确。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:85](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L85)
206. 学号和密码均未通过核验。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:86](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L86)
207. {{mismatch}} 已累计 {{result.failureCount}} 次失败，等待 {{formatWaitSeconds(result.lockDurationMs)}} 后可重试。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:88](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L88)
208. {{mismatch}} 还可立即尝试 {{CC98\_LOGIN\_FREE\_ATTEMPTS - result.failureCount}} 次。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:89](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L89)
209. 浙江大学统一身份认证解谜
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:94](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L94)
210. 浙江大学统一身份认证
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:99](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L99)；[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:206](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L206)
211. UNIFIED IDENTITY AUTHENTICATION
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:100](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L100)
212. 浙大通行证登录
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:105](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L105)
213. 首次进入 CC98
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:108](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L108)
214. 浙大通行证
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:109](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L109)
215. 10 位学号
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:122](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L122)
216. 统一身份认证学号
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:123](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L123)
217. 按提示组合密码
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:133](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L133)
218. 统一身份认证密码
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:134](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L134)
219. 显示
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:142](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L142)
220. 隐藏
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:142](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L142)
221. 失败记录
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:147](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L147)
222. 锁定
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:149](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L149)
223. 立即机会 {{immediateAttemptsLeft}}/3
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:150](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L150)
224. 下次失败等待 {{nextPenaltySeconds}}s
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:150](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L150)
225. 登 录
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:158](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L158)
226. 等待 {{formatWaitSeconds(remainingMs)}}
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:158](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L158)
227. 认证线索
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:165](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L165)；[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:167](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L167)
228. 本地找回
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:167](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L167)
229. 查看随身校园卡
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:174](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L174)
230. 校园卡身份已读取
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:174](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L174)
231. 卡面记录了持卡人的 10 位学号
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:175](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L175)
232. 读取
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:177](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L177)
233. 填入
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:177](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L177)
234. 待解锁片段
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:187](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L187)
235. 展开上一条提示后显示
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:188](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L188)
236. 提示已全部展开
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:202](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L202)
237. 展开提示 {{login.revealedHintCount + 1}}
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:202](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L202)
238. 退出认证
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:209](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L209)
239. 「浙大体艺」已停止运行。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:47](../src/scenes/phone/P06_Tiyi/index.tsx#L47)
240. 「浙大体艺」又双叒停止运行了。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:47](../src/scenes/phone/P06_Tiyi/index.tsx#L47)
241. 47 次。它已经把 7 交出来了。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:65](../src/scenes/phone/P06_Tiyi/index.tsx#L65)
242. 获得第 2 位：7
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:72](../src/scenes/phone/P06_Tiyi/index.tsx#L72)
243. 锻炼对象没有姓名。先去给他打电话。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:78](../src/scenes/phone/P06_Tiyi/index.tsx#L78)
244. 课外锻炼已经在记录。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:82](../src/scenes/phone/P06_Tiyi/index.tsx#L82)
245. 浙大体艺加载中
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:88](../src/scenes/phone/P06_Tiyi/index.tsx#L88)
246. 退出
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:96](../src/scenes/phone/P06_Tiyi/index.tsx#L96)
247. 浙大体艺
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:103](../src/scenes/phone/P06_Tiyi/index.tsx#L103)
248. 运动打卡次数 47
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:110](../src/scenes/phone/P06_Tiyi/index.tsx#L110)
249. 开始课外锻炼
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:127](../src/scenes/phone/P06_Tiyi/index.tsx#L127)
250. 课外锻炼进行中
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:127](../src/scenes/phone/P06_Tiyi/index.tsx#L127)
251. 参加者已确认
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:130](../src/scenes/phone/P06_Tiyi/index.tsx#L130)
252. 请先在部门黄页确认参加者
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:131](../src/scenes/phone/P06_Tiyi/index.tsx#L131)
253. 退出浙大体艺，返回手机主页
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:135](../src/scenes/phone/P06_Tiyi/index.tsx#L135)
254. 到座耗时
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:39](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L39)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:255](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L255)
255. 分钟
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:40](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L40)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:255](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L255)
256. 入口小屏 · 计算时间差
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:45](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L45)
257. 公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:49](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L49)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:202](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L202)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:256](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L256)
258. 号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:50](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L50)
259. CC98 楼主编辑 · 读取编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:55](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L55)
260. 证明数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:59](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L59)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:257](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L257)
261. 项
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:60](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L60)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:257](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L257)
262. 旧版规则 · 统计类别
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:65](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L65)
263. 图书馆入口
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:73](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L73)
264. 前台
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:75](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L75)
265. 失物招领
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:76](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L76)
266. 馆藏检索
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:77](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L77)
267. 打印机
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:78](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L78)
268. 书架背面
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:79](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L79)
269. 仍有字段与来源不一致。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:91](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L91)
270. 三项字段分别对应三份已保存的证据。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:111](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L111)
271. 本人来过证明补录单
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:152](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L152)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:157](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L157)
272. 补录成功
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:157](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L157)
273. 待补录 · 先核对下方三项调查材料
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:158](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L158)
274. 系统已承认你确实来过图书馆
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:158](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L158)
275. 表单 022
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:160](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L160)
276. 已认证
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:160](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L160)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:251](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L251)
277. 已记录的图书馆路线
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:163](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L163)
278. 检测到室内异常锻炼路线
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:164](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L164)
279. 寝室
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:166](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L166)
280. 补录方法
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:173](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L173)
281. 三项材料从哪里取得
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:174](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L174)
282. 01 图书馆入口小屏
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:176](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L176)
283. 填写到座耗时
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:176](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L176)
284. 02 CC98 调查帖楼主编辑
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:177](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L177)
285. 填写公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:177](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L177)
286. 03 二楼南区 755 书架旧版规则
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:178](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L178)
287. 填写证明数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:178](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L178)
288. 三项材料可按任意顺序收集；取得后，下方会显示可核对的原文。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:180](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L180)
289. 审核依据
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:183](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L183)
290. 填：到座耗时
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:187](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L187)
291. 图书馆入口小屏
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:187](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L187)
292. 二楼南区 022
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:190](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L190)
293. 主馆入口
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:190](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L190)
294. 填写两次记录的分钟差
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:191](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L191)
295. 未取得 · 回到基础图书馆入口，查看门禁记录小屏
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:193](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L193)
296. 填：公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:199](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L199)
297. CC98 调查帖 · 23 楼楼主编辑
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:199](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L199)
298. 楼主编辑原文：旧申请统一挂在
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:202](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L202)
299. 23 是回复楼层；填写原文中的公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:203](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L203)
300. 未取得 · 在 022 座位拿到占座纸条，用它打开 CC98 调查帖
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:205](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L205)
301. 《旧版临时离座恢复规定》
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:211](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L211)
302. 填：证明数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:211](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L211)
303. 填写规则列出的证明类别数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:217](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L217)
304. 未取得 · 在二楼南区 755 书架使用“索书号 755”，取得并阅读规则
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:219](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L219)
305. 来源
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:236](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L236)
306. {{control.label}}减一
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:238](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L238)
307. {{control.label}}加一
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:240](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L240)
308. 提交补录
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:246](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L246)
309. 本人来过证明
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:252](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L252)
310. 一张证明你来过的证明。它没有证明你为什么要来。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:253](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L253)
311. 已验证补录值
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:254](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L254)
312. 返回手机主页
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:259](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L259)
313. 已照光
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:31](../src/scenes/phone/P10_Bonsai/index.tsx#L31)
314. 已浇水
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:47](../src/scenes/phone/P10_Bonsai/index.tsx#L47)
315. 已施肥
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:58](../src/scenes/phone/P10_Bonsai/index.tsx#L58)
316. 没什么反应。
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:66](../src/scenes/phone/P10_Bonsai/index.tsx#L66)
317. 花心空空的。
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:78](../src/scenes/phone/P10_Bonsai/index.tsx#L78)
318. 它绝对不会开花。
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:81](../src/scenes/phone/P10_Bonsai/index.tsx#L81)
319. 获得第 4 位：8
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:92](../src/scenes/phone/P10_Bonsai/index.tsx#L92)
320. 好像有点想开花
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:95](../src/scenes/phone/P10_Bonsai/index.tsx#L95)
321. 开花了？！
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:95](../src/scenes/phone/P10_Bonsai/index.tsx#L95)
322. 它绝对不会开花
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:95](../src/scenes/phone/P10_Bonsai/index.tsx#L95)
323. 盆栽
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:98](../src/scenes/phone/P10_Bonsai/index.tsx#L98)；[src/scenes/phone/P10_Bonsai/index.tsx:104](../src/scenes/phone/P10_Bonsai/index.tsx#L104)
324. 盛开的盆栽
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:104](../src/scenes/phone/P10_Bonsai/index.tsx#L104)
325. 数字 8
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:114](../src/scenes/phone/P10_Bonsai/index.tsx#L114)
326. waterDrop
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:121](../src/scenes/phone/P10_Bonsai/index.tsx#L121)
327. sun
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:124](../src/scenes/phone/P10_Bonsai/index.tsx#L124)
328. fertilizer
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:127](../src/scenes/phone/P10_Bonsai/index.tsx#L127)
329. 退出盆栽，返回手机主页
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:131](../src/scenes/phone/P10_Bonsai/index.tsx#L131)
330. 请连接校园网。
   来源：[src/scenes/phone/P11_Checkin/index.tsx:93](../src/scenes/phone/P11_Checkin/index.tsx#L93)
331. 签到码错误。
   来源：[src/scenes/phone/P11_Checkin/index.tsx:102](../src/scenes/phone/P11_Checkin/index.tsx#L102)
332. 获得第 1 位：0
   来源：[src/scenes/phone/P11_Checkin/index.tsx:115](../src/scenes/phone/P11_Checkin/index.tsx#L115)
333. 校务签到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:126](../src/scenes/phone/P11_Checkin/index.tsx#L126)
334. 返回学在浙大
   来源：[src/scenes/phone/P11_Checkin/index.tsx:128](../src/scenes/phone/P11_Checkin/index.tsx#L128)
335. 学在浙大 · 课堂签到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:129](../src/scenes/phone/P11_Checkin/index.tsx#L129)
336. 高等数学（早八特供版）
   来源：[src/scenes/phone/P11_Checkin/index.tsx:134](../src/scenes/phone/P11_Checkin/index.tsx#L134)
337. 快快老师 · 紫金港西1-201 · 08:00
   来源：[src/scenes/phone/P11_Checkin/index.tsx:137](../src/scenes/phone/P11_Checkin/index.tsx#L137)
338. 正在点名中……
   来源：[src/scenes/phone/P11_Checkin/index.tsx:138](../src/scenes/phone/P11_Checkin/index.tsx#L138)
339. 本周缺勤
   来源：[src/scenes/phone/P11_Checkin/index.tsx:140](../src/scenes/phone/P11_Checkin/index.tsx#L140)
340. 收集本周缺勤次数零
   来源：[src/scenes/phone/P11_Checkin/index.tsx:142](../src/scenes/phone/P11_Checkin/index.tsx#L142)
341. 次
   来源：[src/scenes/phone/P11_Checkin/index.tsx:146](../src/scenes/phone/P11_Checkin/index.tsx#L146)
342. 签到码输入
   来源：[src/scenes/phone/P11_Checkin/index.tsx:150](../src/scenes/phone/P11_Checkin/index.tsx#L150)
343. 签到码错误，请重新输入
   来源：[src/scenes/phone/P11_Checkin/index.tsx:168](../src/scenes/phone/P11_Checkin/index.tsx#L168)
344. 数字键盘
   来源：[src/scenes/phone/P11_Checkin/index.tsx:170](../src/scenes/phone/P11_Checkin/index.tsx#L170)
345. 删除
   来源：[src/scenes/phone/P11_Checkin/index.tsx:176](../src/scenes/phone/P11_Checkin/index.tsx#L176)
346. 签到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:183](../src/scenes/phone/P11_Checkin/index.tsx#L183)
347. 签
   来源：[src/scenes/phone/P11_Checkin/index.tsx:194](../src/scenes/phone/P11_Checkin/index.tsx#L194)
348. 到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:195](../src/scenes/phone/P11_Checkin/index.tsx#L195)
349. 系统通知 · LOCATION ERROR
   来源：[src/scenes/phone/P11_Checkin/index.tsx:200](../src/scenes/phone/P11_Checkin/index.tsx#L200)
350. 经度与纬度不存在
   来源：[src/scenes/phone/P11_Checkin/index.tsx:201](../src/scenes/phone/P11_Checkin/index.tsx#L201)
351. longitude: null · latitude: null
   来源：[src/scenes/phone/P11_Checkin/index.tsx:202](../src/scenes/phone/P11_Checkin/index.tsx#L202)
352. 黑屏
   来源：[src/scenes/phone/P11_Checkin/index.tsx:208](../src/scenes/phone/P11_Checkin/index.tsx#L208)
353. 齿轮已经掉在下面了。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:223](../src/scenes/phone/P13_PhoneHome/index.tsx#L223)
354. 它看起来很想转转。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:227](../src/scenes/phone/P13_PhoneHome/index.tsx#L227)
355. 它转起来了！
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:227](../src/scenes/phone/P13_PhoneHome/index.tsx#L227)
356. {{definition.ariaLabel ?? definition.label}}{{access.chapter === "chapter\_one" ? "" : "，按 F2 编辑桌面"}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:554](../src/scenes/phone/P13_PhoneHome/index.tsx#L554)
357. 检查上铺床组
   来源：[src/scenes/rpg/DormHubModel.ts:69](../src/scenes/rpg/DormHubModel.ts#L69)
358. 检查下铺床组
   来源：[src/scenes/rpg/DormHubModel.ts:70](../src/scenes/rpg/DormHubModel.ts#L70)
359. 拉动窗帘
   来源：[src/scenes/rpg/DormHubModel.ts:71](../src/scenes/rpg/DormHubModel.ts#L71)
360. 打开窗下柜
   来源：[src/scenes/rpg/DormHubModel.ts:72](../src/scenes/rpg/DormHubModel.ts#L72)
361. 查看鞋架
   来源：[src/scenes/rpg/DormHubModel.ts:73](../src/scenes/rpg/DormHubModel.ts#L73)
362. 查看洗衣篮
   来源：[src/scenes/rpg/DormHubModel.ts:74](../src/scenes/rpg/DormHubModel.ts#L74)
363. 拨动蓝色台灯
   来源：[src/scenes/rpg/DormHubModel.ts:75](../src/scenes/rpg/DormHubModel.ts#L75)
364. 翻看摊开的书
   来源：[src/scenes/rpg/DormHubModel.ts:76](../src/scenes/rpg/DormHubModel.ts#L76)
365. 检查个人书桌
   来源：[src/scenes/rpg/DormHubModel.ts:77](../src/scenes/rpg/DormHubModel.ts#L77)
366. 拉开书桌抽屉
   来源：[src/scenes/rpg/DormHubModel.ts:78](../src/scenes/rpg/DormHubModel.ts#L78)
367. 拧开水龙头
   来源：[src/scenes/rpg/DormHubModel.ts:79](../src/scenes/rpg/DormHubModel.ts#L79)
368. 查看床边书架
   来源：[src/scenes/rpg/DormHubModel.ts:80](../src/scenes/rpg/DormHubModel.ts#L80)
369. 检查地上的背包
   来源：[src/scenes/rpg/DormHubModel.ts:81](../src/scenes/rpg/DormHubModel.ts#L81)
370. 打开寝室门
   来源：[src/scenes/rpg/DormHubModel.ts:82](../src/scenes/rpg/DormHubModel.ts#L82)
371. 拿起书桌上的吹风机
   来源：[src/scenes/rpg/DormHubModel.ts:98](../src/scenes/rpg/DormHubModel.ts#L98)
372. 床帘后只有一床叠得过分认真的被子。
   来源：[src/scenes/rpg/DormHubScene.ts:43](../src/scenes/rpg/DormHubScene.ts#L43)
373. 枕头下面没有捷径，只有一张过期的外卖券。
   来源：[src/scenes/rpg/DormHubScene.ts:44](../src/scenes/rpg/DormHubScene.ts#L44)
374. 窗外很亮。七点五十五分不会因此晚一点。
   来源：[src/scenes/rpg/DormHubScene.ts:45](../src/scenes/rpg/DormHubScene.ts#L45)
375. 柜门打开了。里面整齐地保存着一片空白。
   来源：[src/scenes/rpg/DormHubScene.ts:46](../src/scenes/rpg/DormHubScene.ts#L46)
376. 鞋都在，人也该在。这个推理暂时没有帮助。
   来源：[src/scenes/rpg/DormHubScene.ts:47](../src/scenes/rpg/DormHubScene.ts#L47)
377. 洗衣篮拒绝提供任何关于签到记录的证词。
   来源：[src/scenes/rpg/DormHubScene.ts:48](../src/scenes/rpg/DormHubScene.ts#L48)
378. 蓝色台灯亮了。桌面终于像有人认真学习过。
   来源：[src/scenes/rpg/DormHubScene.ts:49](../src/scenes/rpg/DormHubScene.ts#L49)
379. 书翻到夹着便签的一页：先找到名字，再谈方向。
   来源：[src/scenes/rpg/DormHubScene.ts:50](../src/scenes/rpg/DormHubScene.ts#L50)
380. 这是你的书桌。校园卡压在桌面的纸张旁边。
   来源：[src/scenes/rpg/DormHubScene.ts:51](../src/scenes/rpg/DormHubScene.ts#L51)
381. 抽屉里有三支没墨的笔，以及非常稳定的失望。
   来源：[src/scenes/rpg/DormHubScene.ts:52](../src/scenes/rpg/DormHubScene.ts#L52)
382. 吹风机还能正常工作。
   来源：[src/scenes/rpg/DormHubScene.ts:53](../src/scenes/rpg/DormHubScene.ts#L53)
383. 水龙头还能出水。至少寝室里有一个系统响应正常。
   来源：[src/scenes/rpg/DormHubScene.ts:54](../src/scenes/rpg/DormHubScene.ts#L54)
384. 书脊按课程排好，最薄的那本写着《平时分自救》。
   来源：[src/scenes/rpg/DormHubScene.ts:55](../src/scenes/rpg/DormHubScene.ts#L55)
385. 不是你的包。拉链上挂着一句很明确的‘别翻’。
   来源：[src/scenes/rpg/DormHubScene.ts:56](../src/scenes/rpg/DormHubScene.ts#L56)
386. 门没有意见，流程有。
   来源：[src/scenes/rpg/DormHubScene.ts:57](../src/scenes/rpg/DormHubScene.ts#L57)
387. 这件道具暂时不需要交给他。
   来源：[src/scenes/rpg/DormHubScene.ts:259](../src/scenes/rpg/DormHubScene.ts#L259)
388. gamepad
   来源：[src/scenes/rpg/DormHubScene.ts:262](../src/scenes/rpg/DormHubScene.ts#L262)；[src/scenes/rpg/DormHubScene.ts:264](../src/scenes/rpg/DormHubScene.ts#L264)
389. missed\_target
   来源：[src/scenes/rpg/DormHubScene.ts:262](../src/scenes/rpg/DormHubScene.ts#L262)；[src/scenes/rpg/DormHubScene.ts:273](../src/scenes/rpg/DormHubScene.ts#L273)
390. wrong\_item
   来源：[src/scenes/rpg/DormHubScene.ts:262](../src/scenes/rpg/DormHubScene.ts#L262)
391. 角色
   来源：[src/scenes/rpg/DormHubScene.ts:263](../src/scenes/rpg/DormHubScene.ts#L263)；[src/scenes/rpg/DormHubScene.ts:274](../src/scenes/rpg/DormHubScene.ts#L274)
392. 道具没有进入有效的游戏画布。
   来源：[src/scenes/rpg/DormHubScene.ts:264](../src/scenes/rpg/DormHubScene.ts#L264)
393. 角色当前只接收游戏手柄。
   来源：[src/scenes/rpg/DormHubScene.ts:264](../src/scenes/rpg/DormHubScene.ts#L264)
394. 把手柄拖到小人身上。
   来源：[src/scenes/rpg/DormHubScene.ts:270](../src/scenes/rpg/DormHubScene.ts#L270)
395. 松手点没有进入角色身体范围。
   来源：[src/scenes/rpg/DormHubScene.ts:275](../src/scenes/rpg/DormHubScene.ts#L275)
396. 你被送回寝室，衣服还在滴水。
   来源：[src/scenes/rpg/DormHubScene.ts:373](../src/scenes/rpg/DormHubScene.ts#L373)
397. 吹风机已经放进物品栏。
   来源：[src/scenes/rpg/DormHubScene.ts:387](../src/scenes/rpg/DormHubScene.ts#L387)
398. 现在还不需要使用吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:388](../src/scenes/rpg/DormHubScene.ts#L388)
399. 获得寝室吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:396](../src/scenes/rpg/DormHubScene.ts#L396)
400. 拿起个人书桌上的校园卡
   来源：[src/scenes/rpg/DormHubScene.ts:561](../src/scenes/rpg/DormHubScene.ts#L561)
401. 先用手机天气页面处理启真湖的云层。
   来源：[src/scenes/rpg/DormHubScene.ts:580](../src/scenes/rpg/DormHubScene.ts#L580)
402. 先从自己的书桌拿到吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:581](../src/scenes/rpg/DormHubScene.ts#L581)
403. 寝室门已打开。
   来源：[src/scenes/rpg/DormHubScene.ts:586](../src/scenes/rpg/DormHubScene.ts#L586)
404. 先完成基础馆二层南区 022 的座位预约。
   来源：[src/scenes/rpg/DormHubScene.ts:604](../src/scenes/rpg/DormHubScene.ts#L604)
405. 校园卡已经在物品栏里。
   来源：[src/scenes/rpg/DormHubScene.ts:611](../src/scenes/rpg/DormHubScene.ts#L611)
406. 当前任务还没有开放校园卡拾取。
   来源：[src/scenes/rpg/DormHubScene.ts:615](../src/scenes/rpg/DormHubScene.ts#L615)
407. 获得校园卡。身份信息已可读。
   来源：[src/scenes/rpg/DormHubScene.ts:622](../src/scenes/rpg/DormHubScene.ts#L622)
408. 他现在会按你的方向移动。
   来源：[src/scenes/rpg/DormHubScene.ts:629](../src/scenes/rpg/DormHubScene.ts#L629)
409. 方向控制已安装，试着让他走一步。
   来源：[src/scenes/rpg/DormHubScene.ts:630](../src/scenes/rpg/DormHubScene.ts#L630)

## 第二章

1. CHAPTER 02
   来源：[src/App.tsx:310](../src/App.tsx#L310)
2. 第 2 章
   来源：[src/App.tsx:311](../src/App.tsx#L311)
3. 找到移动的办法
   来源：[src/App.tsx:312](../src/App.tsx#L312)；[src/core/QuestModel.ts:215](../src/core/QuestModel.ts#L215)
4. 进入第二章
   来源：[src/App.tsx:313](../src/App.tsx#L313)
5. 旁白
   来源：[src/components/LibraryStoryOverlay.tsx:89](../src/components/LibraryStoryOverlay.tsx#L89)；[src/components/LibraryStoryOverlay.tsx:90](../src/components/LibraryStoryOverlay.tsx#L90)；[src/data/library-finals.content.json:25](../src/data/library-finals.content.json#L25)；[src/data/library-finals.content.json:35](../src/data/library-finals.content.json#L35)；[src/data/library-finals.content.json:72](../src/data/library-finals.content.json#L72)
6. 玩家
   来源：[src/components/LibraryStoryOverlay.tsx:89](../src/components/LibraryStoryOverlay.tsx#L89)；[src/components/LibraryStoryOverlay.tsx:90](../src/components/LibraryStoryOverlay.tsx#L90)；[src/data/library-finals.content.json:10](../src/data/library-finals.content.json#L10)；[src/data/library-finals.content.json:12](../src/data/library-finals.content.json#L12)；[src/data/library-finals.content.json:14](../src/data/library-finals.content.json#L14)；[src/data/library-finals.content.json:16](../src/data/library-finals.content.json#L16)；[src/data/library-finals.content.json:18](../src/data/library-finals.content.json#L18)；[src/data/library-finals.content.json:20](../src/data/library-finals.content.json#L20)；[src/data/library-finals.content.json:26](../src/data/library-finals.content.json#L26)；[src/data/library-finals.content.json:31](../src/data/library-finals.content.json#L31)；[src/data/library-finals.content.json:40](../src/data/library-finals.content.json#L40)；[src/data/library-finals.content.json:42](../src/data/library-finals.content.json#L42)；[src/data/library-finals.content.json:45](../src/data/library-finals.content.json#L45)；[src/data/library-finals.content.json:49](../src/data/library-finals.content.json#L49)；[src/data/library-finals.content.json:51](../src/data/library-finals.content.json#L51)；[src/data/library-finals.content.json:56](../src/data/library-finals.content.json#L56)；[src/data/library-finals.content.json:62](../src/data/library-finals.content.json#L62)；[src/data/library-finals.content.json:66](../src/data/library-finals.content.json#L66)；[src/data/library-finals.content.json:68](../src/data/library-finals.content.json#L68)；[src/data/library-finals.content.json:76](../src/data/library-finals.content.json#L76)；[src/data/library-finals.content.json:82](../src/data/library-finals.content.json#L82)；[src/data/library-finals.content.json:266](../src/data/library-finals.content.json#L266)；[src/data/library-finals.content.json:271](../src/data/library-finals.content.json#L271)；[src/data/library-finals.content.json:274](../src/data/library-finals.content.json#L274)；[src/data/library-finals.content.json:276](../src/data/library-finals.content.json#L276)；[src/data/library-finals.content.json:279](../src/data/library-finals.content.json#L279)；[src/data/library-finals.content.json:283](../src/data/library-finals.content.json#L283)
7. 第二章剧情对白
   来源：[src/components/LibraryStoryOverlay.tsx:93](../src/components/LibraryStoryOverlay.tsx#L93)
8. 剧情播放中 ·
   来源：[src/components/LibraryStoryOverlay.tsx:99](../src/components/LibraryStoryOverlay.tsx#L99)
9. 等待确认
   来源：[src/components/LibraryStoryOverlay.tsx:100](../src/components/LibraryStoryOverlay.tsx#L100)
10. 自动播放 · 可快进
   来源：[src/components/LibraryStoryOverlay.tsx:100](../src/components/LibraryStoryOverlay.tsx#L100)
11. 操作已暂停 · Enter / Space
   来源：[src/components/LibraryStoryOverlay.tsx:107](../src/components/LibraryStoryOverlay.tsx#L107)
12. 继续
   来源：[src/components/LibraryStoryOverlay.tsx:109](../src/components/LibraryStoryOverlay.tsx#L109)
13. 快进
   来源：[src/components/LibraryStoryOverlay.tsx:109](../src/components/LibraryStoryOverlay.tsx#L109)
14. 确认并继续
   来源：[src/components/LibraryStoryOverlay.tsx:109](../src/components/LibraryStoryOverlay.tsx#L109)
15. 收集三角形与天气水滴
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)
16. 主页的「方向校准」与天气页面各有一项变化，两边可以分别检查。
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
17. 取得顺序不影响后续组合。
   来源：[src/core/QuestModel.ts:92](../src/core/QuestModel.ts#L92)
18. 查看主页的「方向校准」推送
   来源：[src/core/QuestModel.ts:100](../src/core/QuestModel.ts#L100)
19. 连续检查推送头像边缘，取下松动的三角形。
   来源：[src/core/QuestModel.ts:101](../src/core/QuestModel.ts#L101)
20. 从天气页面取得天气水滴
   来源：[src/core/QuestModel.ts:108](../src/core/QuestModel.ts#L108)
21. 打开天气页面，收集已经出现的水滴。
   来源：[src/core/QuestModel.ts:109](../src/core/QuestModel.ts#L109)
22. 用天气水滴处理导师头像
   来源：[src/core/QuestModel.ts:116](../src/core/QuestModel.ts#L116)
23. 打开微信，把天气水滴拖到导师头像边缘的黏着竖线。
   来源：[src/core/QuestModel.ts:117](../src/core/QuestModel.ts#L117)
24. 组合三角形与竖线
   来源：[src/core/QuestModel.ts:124](../src/core/QuestModel.ts#L124)
25. 在道具栏中将主页三角形与导师头像掉落的竖线组合。
   来源：[src/core/QuestModel.ts:125](../src/core/QuestModel.ts#L125)
26. 用右移箭头调整校园卡余额
   来源：[src/core/QuestModel.ts:132](../src/core/QuestModel.ts#L132)
27. 把右移箭头拖到电子校园卡的余额数字上。
   来源：[src/core/QuestModel.ts:133](../src/core/QuestModel.ts#L133)
28. 完成 CC98 首次身份认证
   来源：[src/core/QuestModel.ts:140](../src/core/QuestModel.ts#L140)
29. 先从随身校园卡读取 10 位学号。
   来源：[src/core/QuestModel.ts:142](../src/core/QuestModel.ts#L142)
30. 密码按校名缩写、建校年份、结尾标点三段拼接。
   来源：[src/core/QuestModel.ts:143](../src/core/QuestModel.ts#L143)
31. 去 CC98 购买游戏手柄
   来源：[src/core/QuestModel.ts:151](../src/core/QuestModel.ts#L151)
32. 打开 CC98 二手交易，用调整后的校园卡余额付款。
   来源：[src/core/QuestModel.ts:152](../src/core/QuestModel.ts#L152)
33. 把游戏手柄安装到寝室角色
   来源：[src/core/QuestModel.ts:159](../src/core/QuestModel.ts#L159)
34. 返回寝室，把道具栏里的游戏手柄拖到角色身上。
   来源：[src/core/QuestModel.ts:160](../src/core/QuestModel.ts#L160)
35. 完成第一次手动移动
   来源：[src/core/QuestModel.ts:166](../src/core/QuestModel.ts#L166)
36. 使用方向键移动一次，确认手柄已经生效。
   来源：[src/core/QuestModel.ts:167](../src/core/QuestModel.ts#L167)
37. 确认方向控制已经生效
   来源：[src/core/QuestModel.ts:172](../src/core/QuestModel.ts#L172)
38. 让地图人物回应你
   来源：[src/core/QuestModel.ts:179](../src/core/QuestModel.ts#L179)
39. 找到道具栏
   来源：[src/core/QuestModel.ts:179](../src/core/QuestModel.ts#L179)
40. 手机里有能联系校内人员的地方。
   来源：[src/core/QuestModel.ts:181](../src/core/QuestModel.ts#L181)
41. 用校园卡上的身份信息，在部门黄页里找到他。
   来源：[src/core/QuestModel.ts:182](../src/core/QuestModel.ts#L182)
42. 让地图人物动起来
   来源：[src/core/QuestModel.ts:189](../src/core/QuestModel.ts#L189)
43. 有一个 App 专门负责把普通走路变成记录。
   来源：[src/core/QuestModel.ts:191](../src/core/QuestModel.ts#L191)
44. 打开浙大体艺，开始课外锻炼。
   来源：[src/core/QuestModel.ts:192](../src/core/QuestModel.ts#L192)
45. 预约 022
   来源：[src/core/QuestModel.ts:200](../src/core/QuestModel.ts#L200)
46. 二层南区022
   来源：[src/core/QuestModel.ts:201](../src/core/QuestModel.ts#L201)
47. 去图书馆
   来源：[src/core/QuestModel.ts:228](../src/core/QuestModel.ts#L228)
48. 地图缩放仔细找
   来源：[src/core/QuestModel.ts:229](../src/core/QuestModel.ts#L229)
49. 确认座位状态
   来源：[src/core/QuestModel.ts:234](../src/core/QuestModel.ts#L234)
50. 去 RPG 图书馆地图找 022。
   来源：[src/core/QuestModel.ts:236](../src/core/QuestModel.ts#L236)
51. 检查 022 上的东西和旁边的纸条。
   来源：[src/core/QuestModel.ts:237](../src/core/QuestModel.ts#L237)
52. 查清占座规则
   来源：[src/core/QuestModel.ts:243](../src/core/QuestModel.ts#L243)
53. 纸条提到了一个更吵的地方。
   来源：[src/core/QuestModel.ts:245](../src/core/QuestModel.ts#L245)
54. CC98 里有人讨论过 022。
   来源：[src/core/QuestModel.ts:246](../src/core/QuestModel.ts#L246)
55. 用占座纸条搜索 CC98，再顺着帖子找旧规则。
   来源：[src/core/QuestModel.ts:247](../src/core/QuestModel.ts#L247)
56. 凑齐恢复材料（{{proofCount}}/3）
   来源：[src/core/QuestModel.ts:254](../src/core/QuestModel.ts#L254)
57. 照片、座位夹缝和体艺都能帮上忙。
   来源：[src/core/QuestModel.ts:256](../src/core/QuestModel.ts#L256)
58. 照片曝光了就把光调小（控制中心光条）
   来源：[src/core/QuestModel.ts:257](../src/core/QuestModel.ts#L257)
59. 体艺 7,47,3
   来源：[src/core/QuestModel.ts:258](../src/core/QuestModel.ts#L258)
60. 让帖子被看见
   来源：[src/core/QuestModel.ts:265](../src/core/QuestModel.ts#L265)
61. 3027，为什么自己想
   来源：[src/core/QuestModel.ts:266](../src/core/QuestModel.ts#L266)
62. 提交恢复申请
   来源：[src/core/QuestModel.ts:272](../src/core/QuestModel.ts#L272)
63. 在浙大钉-&gt;图书馆-&gt;pass申请
   来源：[src/core/QuestModel.ts:273](../src/core/QuestModel.ts#L273)
64. 回到 022
   来源：[src/core/QuestModel.ts:279](../src/core/QuestModel.ts#L279)
65. 字面意思。
   来源：[src/core/QuestModel.ts:280](../src/core/QuestModel.ts#L280)
66. 恢复 022 座位
   来源：[src/core/QuestModel.ts:303](../src/core/QuestModel.ts#L303)
67. 第二章·022 的占座书包
   来源：[src/data/library-finals.content.json:3](../src/data/library-finals.content.json#L3)
68. 这里就是图书馆？
   来源：[src/data/library-finals.content.json:10](../src/data/library-finals.content.json#L10)
69. 她最后留下入馆记录的地方。
   来源：[src/data/library-finals.content.json:11](../src/data/library-finals.content.json#L11)
70. 系统
   来源：[src/data/library-finals.content.json:11](../src/data/library-finals.content.json#L11)；[src/data/library-finals.content.json:13](../src/data/library-finals.content.json#L13)；[src/data/library-finals.content.json:15](../src/data/library-finals.content.json#L15)；[src/data/library-finals.content.json:17](../src/data/library-finals.content.json#L17)；[src/data/library-finals.content.json:19](../src/data/library-finals.content.json#L19)；[src/data/library-finals.content.json:21](../src/data/library-finals.content.json#L21)；[src/data/library-finals.content.json:27](../src/data/library-finals.content.json#L27)；[src/data/library-finals.content.json:30](../src/data/library-finals.content.json#L30)；[src/data/library-finals.content.json:32](../src/data/library-finals.content.json#L32)；[src/data/library-finals.content.json:36](../src/data/library-finals.content.json#L36)；[src/data/library-finals.content.json:39](../src/data/library-finals.content.json#L39)；[src/data/library-finals.content.json:41](../src/data/library-finals.content.json#L41)；[src/data/library-finals.content.json:43](../src/data/library-finals.content.json#L43)；[src/data/library-finals.content.json:44](../src/data/library-finals.content.json#L44)；[src/data/library-finals.content.json:55](../src/data/library-finals.content.json#L55)；[src/data/library-finals.content.json:61](../src/data/library-finals.content.json#L61)；[src/data/library-finals.content.json:63](../src/data/library-finals.content.json#L63)；[src/data/library-finals.content.json:67](../src/data/library-finals.content.json#L67)；[src/data/library-finals.content.json:69](../src/data/library-finals.content.json#L69)；[src/data/library-finals.content.json:75](../src/data/library-finals.content.json#L75)；[src/data/library-finals.content.json:84](../src/data/library-finals.content.json#L84)；[src/data/library-finals.content.json:267](../src/data/library-finals.content.json#L267)；[src/data/library-finals.content.json:269](../src/data/library-finals.content.json#L269)；[src/data/library-finals.content.json:277](../src/data/library-finals.content.json#L277)；[src/data/library-finals.content.json:281](../src/data/library-finals.content.json#L281)；[src/data/library-finals.content.json:284](../src/data/library-finals.content.json#L284)
71. 你朋友是管理员？
   来源：[src/data/library-finals.content.json:12](../src/data/library-finals.content.json#L12)
72. 她不管馆内秩序。
   来源：[src/data/library-finals.content.json:13](../src/data/library-finals.content.json#L13)
73. 馆长？
   来源：[src/data/library-finals.content.json:14](../src/data/library-finals.content.json#L14)
74. 也不在馆长名册里。
   来源：[src/data/library-finals.content.json:15](../src/data/library-finals.content.json#L15)
75. 所以是？
   来源：[src/data/library-finals.content.json:16](../src/data/library-finals.content.json#L16)
76. 一个座位，二楼南区 022。
   来源：[src/data/library-finals.content.json:17](../src/data/library-finals.content.json#L17)
77. 上次见面时，她就在 022。
   来源：[src/data/library-finals.content.json:19](../src/data/library-finals.content.json#L19)
78. 以前？
   来源：[src/data/library-finals.content.json:20](../src/data/library-finals.content.json#L20)
79. 这张记录没有固定时长。先去闸机核对入馆时间。
   来源：[src/data/library-finals.content.json:21](../src/data/library-finals.content.json#L21)
80. 书包
   来源：[src/data/library-finals.content.json:24](../src/data/library-finals.content.json#L24)；[src/data/library-finals.content.json:81](../src/data/library-finals.content.json#L81)；[src/data/library-finals.content.json:83](../src/data/library-finals.content.json#L83)
81. 022 被一个书包占着，桌上的纸条写着“主人马上回来”。
   来源：[src/data/library-finals.content.json:25](../src/data/library-finals.content.json#L25)
82. 它把座位占了。
   来源：[src/data/library-finals.content.json:26](../src/data/library-finals.content.json#L26)
83. 先别碰。去 CC98 查三分钟离座的规则。
   来源：[src/data/library-finals.content.json:27](../src/data/library-finals.content.json#L27)
84. 先看这条讨论，确认三分钟离座的规则。
   来源：[src/data/library-finals.content.json:30](../src/data/library-finals.content.json#L30)
85. 查到以后呢？
   来源：[src/data/library-finals.content.json:31](../src/data/library-finals.content.json#L31)
86. 拿到规则，再补齐恢复 022 的证明。
   来源：[src/data/library-finals.content.json:32](../src/data/library-finals.content.json#L32)
87. 书名、索书号和 022 的记录都能对上。
   来源：[src/data/library-finals.content.json:35](../src/data/library-finals.content.json#L35)
88. 去二楼南区 755 号书架背面找旧版规则。
   来源：[src/data/library-finals.content.json:36](../src/data/library-finals.content.json#L36)
89. 旧版离座规则找到了。
   来源：[src/data/library-finals.content.json:39](../src/data/library-finals.content.json#L39)
90. 坏消息？
   来源：[src/data/library-finals.content.json:40](../src/data/library-finals.content.json#L40)
91. 它要求三项证明。
   来源：[src/data/library-finals.content.json:41](../src/data/library-finals.content.json#L41)
92. 书包还要核验身份？
   来源：[src/data/library-finals.content.json:42](../src/data/library-finals.content.json#L42)
93. 规则只认已经留下的材料。
   来源：[src/data/library-finals.content.json:43](../src/data/library-finals.content.json#L43)
94. 座位小票、到馆证明、书包非本人证明。
   来源：[src/data/library-finals.content.json:44](../src/data/library-finals.content.json#L44)
95. 前台
   来源：[src/data/library-finals.content.json:48](../src/data/library-finals.content.json#L48)；[src/data/library-finals.content.json:50](../src/data/library-finals.content.json#L50)；[src/data/library-finals.content.json:52](../src/data/library-finals.content.json#L52)；[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
96. 请说明要处理的物品。
   来源：[src/data/library-finals.content.json:48](../src/data/library-finals.content.json#L48)
97. 022 的占座书包。
   来源：[src/data/library-finals.content.json:49](../src/data/library-finals.content.json#L49)
98. 请先提交书包非本人证明。
   来源：[src/data/library-finals.content.json:50](../src/data/library-finals.content.json#L50)
99. 书包也要做身份核验？
   来源：[src/data/library-finals.content.json:51](../src/data/library-finals.content.json#L51)
100. 系统里，它目前登记为座位使用者。
   来源：[src/data/library-finals.content.json:52](../src/data/library-finals.content.json#L52)
101. 盖章完成。书包不再算 022 的使用者。
   来源：[src/data/library-finals.content.json:55](../src/data/library-finals.content.json#L55)
102. 我今天跑的证明比上课还多。
   来源：[src/data/library-finals.content.json:56](../src/data/library-finals.content.json#L56)
103. 补录成功。
   来源：[src/data/library-finals.content.json:59](../src/data/library-finals.content.json#L59)
104. 体艺
   来源：[src/data/library-finals.content.json:59](../src/data/library-finals.content.json#L59)；[src/data/library-finals.content.json:60](../src/data/library-finals.content.json#L60)
105. 入馆和到馆时间已写入记录。
   来源：[src/data/library-finals.content.json:60](../src/data/library-finals.content.json#L60)
106. 到馆证明拿到了。
   来源：[src/data/library-finals.content.json:61](../src/data/library-finals.content.json#L61)
107. 终于有一项证明的是我自己。
   来源：[src/data/library-finals.content.json:62](../src/data/library-finals.content.json#L62)
108. 还差座位小票。
   来源：[src/data/library-finals.content.json:63](../src/data/library-finals.content.json#L63)
109. 好了，证据齐了。现在图书馆会处理了吧？
   来源：[src/data/library-finals.content.json:66](../src/data/library-finals.content.json#L66)
110. 还差公开确认。图书馆 App 只读取十大帖的四位热度口令。
   来源：[src/data/library-finals.content.json:67](../src/data/library-finals.content.json#L67)
111. bd 到底是什么？
   来源：[src/data/library-finals.content.json:68](../src/data/library-finals.content.json#L68)
112. bd 是“帮顶”。在一条数字回复上点 bd，数字就会按顺序写入口令。
   来源：[src/data/library-finals.content.json:69](../src/data/library-finals.content.json#L69)
113. 帖子到了第一，022 的恢复申请入口开放。
   来源：[src/data/library-finals.content.json:72](../src/data/library-finals.content.json#L72)
114. 清退凭证生成。带它回 022。
   来源：[src/data/library-finals.content.json:75](../src/data/library-finals.content.json#L75)
115. 这次该把座位还给人了。
   来源：[src/data/library-finals.content.json:76](../src/data/library-finals.content.json#L76)
116. 请占座物品离开 022。
   来源：[src/data/library-finals.content.json:79](../src/data/library-finals.content.json#L79)
117. 图书馆提示
   来源：[src/data/library-finals.content.json:79](../src/data/library-finals.content.json#L79)；[src/data/library-finals.content.json:80](../src/data/library-finals.content.json#L80)
118. 如需认领，请前往失物招领。
   来源：[src/data/library-finals.content.json:80](../src/data/library-finals.content.json#L80)
119. 主人马上回来。
   来源：[src/data/library-finals.content.json:81](../src/data/library-finals.content.json#L81)
120. 什么时候？
   来源：[src/data/library-finals.content.json:82](../src/data/library-finals.content.json#L82)
121. 三分钟。
   来源：[src/data/library-finals.content.json:83](../src/data/library-finals.content.json#L83)
122. 纸条上的这句话已经留了三天。
   来源：[src/data/library-finals.content.json:84](../src/data/library-finals.content.json#L84)
123. 二南临时读者
   来源：[src/data/library-finals.content.json:90](../src/data/library-finals.content.json#L90)；[src/data/library-finals.content.json:104](../src/data/library-finals.content.json#L104)；[src/data/library-finals.content.json:138](../src/data/library-finals.content.json#L138)
124. 求助
   来源：[src/data/library-finals.content.json:92](../src/data/library-finals.content.json#L92)
125. 校园生活
   来源：[src/data/library-finals.content.json:93](../src/data/library-finals.content.json#L93)
126. 【求助】022 的书包占座三天了
   来源：[src/data/library-finals.content.json:94](../src/data/library-finals.content.json#L94)
127. 26-07-12 08:02
   来源：[src/data/library-finals.content.json:97](../src/data/library-finals.content.json#L97)
128. 二楼南区 022 有个书包，纸条写着离开三分钟。人没回来，座位也没有空。
   来源：[src/data/library-finals.content.json:98](../src/data/library-finals.content.json#L98)
129. 楼主
   来源：[src/data/library-finals.content.json:105](../src/data/library-finals.content.json#L105)
130. 022 有个书包，离开三分钟回来还在。纸条写着离开三分钟，回来时系统已经换人。
   来源：[src/data/library-finals.content.json:106](../src/data/library-finals.content.json#L106)
131. 入口记录员
   来源：[src/data/library-finals.content.json:110](../src/data/library-finals.content.json#L110)
132. 补充
   来源：[src/data/library-finals.content.json:111](../src/data/library-finals.content.json#L111)
133. 入馆记录能证明你什么时候到，但不能证明座位上的东西属于谁。
   来源：[src/data/library-finals.content.json:112](../src/data/library-finals.content.json#L112)
134. 索书号爱好者
   来源：[src/data/library-finals.content.json:116](../src/data/library-finals.content.json#L116)
135. 线索
   来源：[src/data/library-finals.content.json:117](../src/data/library-finals.content.json#L117)；[src/data/library-finals.content.json:133](../src/data/library-finals.content.json#L133)
136. 回复 4 楼，入口记录只能证明到场
   来源：[src/data/library-finals.content.json:118](../src/data/library-finals.content.json#L118)
137. 旧版规则不在网上，在图书馆书架背面。搜‘三分钟离座法’。
   来源：[src/data/library-finals.content.json:119](../src/data/library-finals.content.json#L119)
138. 纸面支援专员
   来源：[src/data/library-finals.content.json:123](../src/data/library-finals.content.json#L123)
139. 路过
   来源：[src/data/library-finals.content.json:124](../src/data/library-finals.content.json#L124)
140. bd 就是帮顶。点一条数字回复的 bd，右侧数字会写进热度口令。
   来源：[src/data/library-finals.content.json:125](../src/data/library-finals.content.json#L125)
141. bd
   来源：[src/data/library-finals.content.json:127](../src/data/library-finals.content.json#L127)
142. 热度维护员
   来源：[src/data/library-finals.content.json:132](../src/data/library-finals.content.json#L132)
143. 证据齐后，按上传栏从上到下选择四条数字回复，组成四位口令。
   来源：[src/data/library-finals.content.json:134](../src/data/library-finals.content.json#L134)
144. 楼主编辑
   来源：[src/data/library-finals.content.json:139](../src/data/library-finals.content.json#L139)
145. 帖子进十大第一后，图书馆 App 会开放 022 恢复申请。旧申请统一挂在公示编号 47。
   来源：[src/data/library-finals.content.json:140](../src/data/library-finals.content.json#L140)
146. 前排先占楼
   来源：[src/data/library-finals.content.json:144](../src/data/library-finals.content.json#L144)
147. ac01，座位没占到，楼层总得先占一个。
   来源：[src/data/library-finals.content.json:144](../src/data/library-finals.content.json#L144)
148. 三分钟后再来
   来源：[src/data/library-finals.content.json:145](../src/data/library-finals.content.json#L145)
149. ac01。三分钟后回来看看这条回复有没有被别人预约。
   来源：[src/data/library-finals.content.json:145](../src/data/library-finals.content.json#L145)
150. 空气座位经销商
   来源：[src/data/library-finals.content.json:146](../src/data/library-finals.content.json#L146)
151. 前排出售空气座位，坐下即视为离开。ac01
   来源：[src/data/library-finals.content.json:146](../src/data/library-finals.content.json#L146)
152. 022 的书包今天也全勤，我今天也……算了。ac01
   来源：[src/data/library-finals.content.json:147](../src/data/library-finals.content.json#L147)
153. 022考勤员
   来源：[src/data/library-finals.content.json:147](../src/data/library-finals.content.json#L147)
154. 公示编号 47，运动次数 47，建议书包报名体艺。ac01
   来源：[src/data/library-finals.content.json:148](../src/data/library-finals.content.json#L148)
155. 体艺凑数办
   来源：[src/data/library-finals.content.json:148](../src/data/library-finals.content.json#L148)
156. 二南窗边位
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
157. 期末周返场员
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
158. 续杯失败者
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
159. 自习室回声
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
160. 先等后续。我刚从 022 旁边经过，书包还在，座位一直没人。
   来源：[src/data/library-finals.content.json:153](../src/data/library-finals.content.json#L153)
161. 我去接杯水再回来，座位就换人了。三分钟从什么时候开始算？
   来源：[src/data/library-finals.content.json:154](../src/data/library-finals.content.json#L154)
162. 今晚九点后我还见过这个书包，主人没有出现。
   来源：[src/data/library-finals.content.json:155](../src/data/library-finals.content.json#L155)
163. 规则写三分钟，就该把起算时间写清楚。
   来源：[src/data/library-finals.content.json:156](../src/data/library-finals.content.json#L156)
164. 人回不回来先不说，至少系统得给一个能核对的时间。
   来源：[src/data/library-finals.content.json:157](../src/data/library-finals.content.json#L157)
165. 下次给书包单独办张入馆卡，记录可能更完整。
   来源：[src/data/library-finals.content.json:158](../src/data/library-finals.content.json#L158)
166. 先收藏。等有人把“本人”和“物品”分开说清楚。
   来源：[src/data/library-finals.content.json:159](../src/data/library-finals.content.json#L159)
167. 我想看结论。现在能确认的是，书包没离开，座位也没空。
   来源：[src/data/library-finals.content.json:160](../src/data/library-finals.content.json#L160)
168. 这条回复先留着。等 022 空出来，我再坐。
   来源：[src/data/library-finals.content.json:161](../src/data/library-finals.content.json#L161)
169. 请书包主人自己来领取占座记录。
   来源：[src/data/library-finals.content.json:162](../src/data/library-finals.content.json#L162)
170. 我也遇到过。人还在路上，座位已经换了使用者。
   来源：[src/data/library-finals.content.json:163](../src/data/library-finals.content.json#L163)
171. 规则写得完整，核对时间那一项却没有写。
   来源：[src/data/library-finals.content.json:164](../src/data/library-finals.content.json#L164)
172. 755 号书架背面
   来源：[src/data/library-finals.content.json:168](../src/data/library-finals.content.json#L168)
173. 旧版离座规则
   来源：[src/data/library-finals.content.json:168](../src/data/library-finals.content.json#L168)
174. 书包非本人证明
   来源：[src/data/library-finals.content.json:169](../src/data/library-finals.content.json#L169)
175. 物品身份盖章机
   来源：[src/data/library-finals.content.json:169](../src/data/library-finals.content.json#L169)
176. 022 桌下夹缝
   来源：[src/data/library-finals.content.json:170](../src/data/library-finals.content.json#L170)
177. 022 座位小票
   来源：[src/data/library-finals.content.json:170](../src/data/library-finals.content.json#L170)
178. 本人来过证明
   来源：[src/data/library-finals.content.json:171](../src/data/library-finals.content.json#L171)
179. 浙大体艺补录
   来源：[src/data/library-finals.content.json:171](../src/data/library-finals.content.json#L171)
180. BD 四位热度口令
   来源：[src/data/library-finals.content.json:174](../src/data/library-finals.content.json#L174)
181. bd = 帮顶。点击数字回复中的 bd，会把该数字按顺序写入口令。
   来源：[src/data/library-finals.content.json:175](../src/data/library-finals.content.json#L175)
182. 按上方四项已上传证据从上到下，各选择一条对应的数字回复。
   来源：[src/data/library-finals.content.json:176](../src/data/library-finals.content.json#L176)
183. 旧版规则
   来源：[src/data/library-finals.content.json:178](../src/data/library-finals.content.json#L178)
184. 数证明要求
   来源：[src/data/library-finals.content.json:178](../src/data/library-finals.content.json#L178)
185. 非本人证明
   来源：[src/data/library-finals.content.json:179](../src/data/library-finals.content.json#L179)
186. 数身份通过项
   来源：[src/data/library-finals.content.json:179](../src/data/library-finals.content.json#L179)
187. 022 小票
   来源：[src/data/library-finals.content.json:180](../src/data/library-finals.content.json#L180)
188. 取座位号末位
   来源：[src/data/library-finals.content.json:180](../src/data/library-finals.content.json#L180)
189. 到馆证明
   来源：[src/data/library-finals.content.json:181](../src/data/library-finals.content.json#L181)
190. 取到座耗时
   来源：[src/data/library-finals.content.json:181](../src/data/library-finals.content.json#L181)
191. 公示编号 47 的十位是 4。这个数字属于公示编号。
   来源：[src/data/library-finals.content.json:184](../src/data/library-finals.content.json#L184)
192. 公示号拆分员
   来源：[src/data/library-finals.content.json:184](../src/data/library-finals.content.json#L184)
193. 规则条目统计员
   来源：[src/data/library-finals.content.json:185](../src/data/library-finals.content.json#L185)
194. 旧规列出到馆、座位、占用物身份三类证明要求。
   来源：[src/data/library-finals.content.json:185](../src/data/library-finals.content.json#L185)
195. 目标排名是 01，我先记录末位 1。
   来源：[src/data/library-finals.content.json:186](../src/data/library-finals.content.json#L186)
196. 十大排名观察员
   来源：[src/data/library-finals.content.json:186](../src/data/library-finals.content.json#L186)
197. 盖章机值班员
   来源：[src/data/library-finals.content.json:187](../src/data/library-finals.content.json#L187)
198. 书包的姓名、学号、人格均未通过，身份有效项为 0。
   来源：[src/data/library-finals.content.json:187](../src/data/library-finals.content.json#L187)
199. 索书号 755 的末位是 5。这个数字属于馆藏线索。
   来源：[src/data/library-finals.content.json:188](../src/data/library-finals.content.json#L188)
200. 索书号末位员
   来源：[src/data/library-finals.content.json:188](../src/data/library-finals.content.json#L188)
201. 022 票据核对员
   来源：[src/data/library-finals.content.json:189](../src/data/library-finals.content.json#L189)
202. 座位号 022 取末位，票据对应数字为 2。
   来源：[src/data/library-finals.content.json:189](../src/data/library-finals.content.json#L189)
203. 关键回复计数员
   来源：[src/data/library-finals.content.json:190](../src/data/library-finals.content.json#L190)
204. 楼主编辑前共有六条固定剧情回复，我记录数字 6。
   来源：[src/data/library-finals.content.json:190](../src/data/library-finals.content.json#L190)
205. 07:55 入馆，08:02 到达 022，到座耗时为 7 分钟。
   来源：[src/data/library-finals.content.json:191](../src/data/library-finals.content.json#L191)
206. 门禁时差计算员
   来源：[src/data/library-finals.content.json:191](../src/data/library-finals.content.json#L191)
207. 三分钟离座法
   来源：[src/data/library-finals.content.json:196](../src/data/library-finals.content.json#L196)；[src/data/library-finals.puzzle.json:5](../src/data/library-finals.puzzle.json#L5)
208. 三分钟离座法及其例外
   来源：[src/data/library-finals.content.json:200](../src/data/library-finals.content.json#L200)
209. 馆内秩序编写组
   来源：[src/data/library-finals.content.json:201](../src/data/library-finals.content.json#L201)
210. 馆藏内部资料
   来源：[src/data/library-finals.content.json:204](../src/data/library-finals.content.json#L204)
211. 基础馆二楼南区 755 号书架背面
   来源：[src/data/library-finals.content.json:205](../src/data/library-finals.content.json#L205)
212. 本书不可借阅，因为借走过一次后规则失效了三天。
   来源：[src/data/library-finals.content.json:206](../src/data/library-finals.content.json#L206)
213. 三分钟离席法与若干例外
   来源：[src/data/library-finals.content.json:211](../src/data/library-finals.content.json#L211)
214. 间歇研究室
   来源：[src/data/library-finals.content.json:212](../src/data/library-finals.content.json#L212)
215. 自习室出版社
   来源：[src/data/library-finals.content.json:215](../src/data/library-finals.content.json#L215)
216. 基础馆四楼 B 区
   来源：[src/data/library-finals.content.json:216](../src/data/library-finals.content.json#L216)
217. 研究心理边界，不包含座位恢复条款。
   来源：[src/data/library-finals.content.json:217](../src/data/library-finals.content.json#L217)
218. 三分钟暂离法及其应用
   来源：[src/data/library-finals.content.json:222](../src/data/library-finals.content.json#L222)
219. 短时休息组
   来源：[src/data/library-finals.content.json:223](../src/data/library-finals.content.json#L223)
220. 效率实验社
   来源：[src/data/library-finals.content.json:226](../src/data/library-finals.content.json#L226)
221. 基础馆三楼 G 区
   来源：[src/data/library-finals.content.json:227](../src/data/library-finals.content.json#L227)
222. 暂离计时器实践手册，没有 022 相关附件。
   来源：[src/data/library-finals.content.json:228](../src/data/library-finals.content.json#L228)
223. 三分钟起身法与边界情况
   来源：[src/data/library-finals.content.json:233](../src/data/library-finals.content.json#L233)
224. 边界观察组
   来源：[src/data/library-finals.content.json:234](../src/data/library-finals.content.json#L234)
225. 清醒文库
   来源：[src/data/library-finals.content.json:237](../src/data/library-finals.content.json#L237)
226. 基础馆一楼 C 区
   来源：[src/data/library-finals.content.json:238](../src/data/library-finals.content.json#L238)
227. 讨论起身后的边界，不提供占座处理权限。
   来源：[src/data/library-finals.content.json:239](../src/data/library-finals.content.json#L239)
228. 三分钟空座法及其解释
   来源：[src/data/library-finals.content.json:244](../src/data/library-finals.content.json#L244)
229. 空位说明组
   来源：[src/data/library-finals.content.json:245](../src/data/library-finals.content.json#L245)
230. 静坐资料室
   来源：[src/data/library-finals.content.json:248](../src/data/library-finals.content.json#L248)
231. 基础馆五楼 G 区
   来源：[src/data/library-finals.content.json:249](../src/data/library-finals.content.json#L249)
232. 解释空座现象，不处理有书包的座位。
   来源：[src/data/library-finals.content.json:250](../src/data/library-finals.content.json#L250)
233. 对象类型：书包；状态：长期占座；本人属性：不成立
   来源：[src/data/library-finals.content.json:257](../src/data/library-finals.content.json#L257)
234. 本人来过证明补录单
   来源：[src/data/library-finals.content.json:260](../src/data/library-finals.content.json#L260)
235. 寝室
   来源：[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
236. 书架背面
   来源：[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
237. 图书馆入口
   来源：[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
238. 022
   来源：[src/data/library-finals.content.json:265](../src/data/library-finals.content.json#L265)；[src/data/library-finals.content.json:268](../src/data/library-finals.content.json#L268)；[src/data/library-finals.content.json:270](../src/data/library-finals.content.json#L270)；[src/data/library-finals.content.json:272](../src/data/library-finals.content.json#L272)；[src/data/library-finals.content.json:273](../src/data/library-finals.content.json#L273)；[src/data/library-finals.content.json:275](../src/data/library-finals.content.json#L275)；[src/data/library-finals.content.json:278](../src/data/library-finals.content.json#L278)；[src/data/library-finals.content.json:280](../src/data/library-finals.content.json#L280)
239. 你终于坐下了。
   来源：[src/data/library-finals.content.json:265](../src/data/library-finals.content.json#L265)
240. 你就是系统的朋友？
   来源：[src/data/library-finals.content.json:266](../src/data/library-finals.content.json#L266)
241. 她以前不在座位上。
   来源：[src/data/library-finals.content.json:267](../src/data/library-finals.content.json#L267)
242. 你以前也不在红圈里。
   来源：[src/data/library-finals.content.json:268](../src/data/library-finals.content.json#L268)
243. 先查签到记录。能修改吗？
   来源：[src/data/library-finals.content.json:269](../src/data/library-finals.content.json#L269)
244. 我先查。
   来源：[src/data/library-finals.content.json:270](../src/data/library-finals.content.json#L270)
245. 可以改吗？
   来源：[src/data/library-finals.content.json:271](../src/data/library-finals.content.json#L271)
246. 查完了。签到记录离开了原页面。
   来源：[src/data/library-finals.content.json:272](../src/data/library-finals.content.json#L272)
247. 它夹在一张纸条里，记录停在 07:55。
   来源：[src/data/library-finals.content.json:273](../src/data/library-finals.content.json#L273)
248. 纸条往哪去了？
   来源：[src/data/library-finals.content.json:274](../src/data/library-finals.content.json#L274)
249. 它不在浅色操作能看见的位置。
   来源：[src/data/library-finals.content.json:275](../src/data/library-finals.content.json#L275)
250. 什么意思？
   来源：[src/data/library-finals.content.json:276](../src/data/library-finals.content.json#L276)
251. 说明白一点。
   来源：[src/data/library-finals.content.json:277](../src/data/library-finals.content.json#L277)
252. 切到深色观察，能看见纸条留下的痕迹。
   来源：[src/data/library-finals.content.json:278](../src/data/library-finals.content.json#L278)
253. 这就是暗色模式？
   来源：[src/data/library-finals.content.json:279](../src/data/library-finals.content.json#L279)
254. 这是它在系统里的名称。
   来源：[src/data/library-finals.content.json:280](../src/data/library-finals.content.json#L280)
255. 先追痕迹，别让纸条离开视野。
   来源：[src/data/library-finals.content.json:281](../src/data/library-finals.content.json#L281)
256. 本人马上回来。
   来源：[src/data/library-finals.content.json:282](../src/data/library-finals.content.json#L282)
257. 纸条
   来源：[src/data/library-finals.content.json:282](../src/data/library-finals.content.json#L282)；[src/scenes/rpg/LibraryInteriorScene.ts:2346](../src/scenes/rpg/LibraryInteriorScene.ts#L2346)
258. 它会说话了？！
   来源：[src/data/library-finals.content.json:283](../src/data/library-finals.content.json#L283)
259. 它把原来的话留在纸条上了。
   来源：[src/data/library-finals.content.json:284](../src/data/library-finals.content.json#L284)
260. 追到东区大食堂
   来源：[src/modules/LibraryFinalsController.ts:734](../src/modules/LibraryFinalsController.ts#L734)
261. 余额没有向任何方向移动。
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:31](../src/scenes/phone/P04_CampusCard/index.tsx#L31)
262. system
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:31](../src/scenes/phone/P04_CampusCard/index.tsx#L31)；[src/scenes/phone/P04_CampusCard/index.tsx:35](../src/scenes/phone/P04_CampusCard/index.tsx#L35)；[src/scenes/phone/P15_Zjuding/index.tsx:883](../src/scenes/phone/P15_Zjuding/index.tsx#L883)；[src/scenes/phone/P15_Zjuding/index.tsx:896](../src/scenes/phone/P15_Zjuding/index.tsx#L896)；[src/scenes/phone/P15_Zjuding/index.tsx:904](../src/scenes/phone/P15_Zjuding/index.tsx#L904)；[src/scenes/phone/P15_Zjuding/index.tsx:968](../src/scenes/phone/P15_Zjuding/index.tsx#L968)；[src/scenes/phone/P15_Zjuding/index.tsx:984](../src/scenes/phone/P15_Zjuding/index.tsx#L984)；[src/scenes/phone/P15_Zjuding/index.tsx:987](../src/scenes/phone/P15_Zjuding/index.tsx#L987)；[src/scenes/phone/P15_Zjuding/index.tsx:992](../src/scenes/phone/P15_Zjuding/index.tsx#L992)；[src/scenes/phone/P15_Zjuding/index.tsx:996](../src/scenes/phone/P15_Zjuding/index.tsx#L996)；[src/scenes/rpg/LibraryInteriorScene.ts:357](../src/scenes/rpg/LibraryInteriorScene.ts#L357)；[src/scenes/rpg/LibraryInteriorScene.ts:380](../src/scenes/rpg/LibraryInteriorScene.ts#L380)；[src/scenes/rpg/LibraryInteriorScene.ts:390](../src/scenes/rpg/LibraryInteriorScene.ts#L390)；[src/scenes/rpg/LibraryInteriorScene.ts:541](../src/scenes/rpg/LibraryInteriorScene.ts#L541)；[src/scenes/rpg/LibraryInteriorScene.ts:2150](../src/scenes/rpg/LibraryInteriorScene.ts#L2150)
263. 这个箭头还不能改动余额。
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:35](../src/scenes/phone/P04_CampusCard/index.tsx#L35)
264. 校园卡
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:54](../src/scenes/phone/P04_CampusCard/index.tsx#L54)
265. 扫一扫
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:58](../src/scenes/phone/P04_CampusCard/index.tsx#L58)
266. 付款码
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:62](../src/scenes/phone/P04_CampusCard/index.tsx#L62)；[src/scenes/phone/P04_CampusCard/index.tsx:125](../src/scenes/phone/P04_CampusCard/index.tsx#L125)
267. 卡片充值
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:66](../src/scenes/phone/P04_CampusCard/index.tsx#L66)；[src/scenes/phone/P04_CampusCard/index.tsx:129](../src/scenes/phone/P04_CampusCard/index.tsx#L129)
268. 卡包
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:70](../src/scenes/phone/P04_CampusCard/index.tsx#L70)
269. 浙江大学
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:77](../src/scenes/phone/P04_CampusCard/index.tsx#L77)
270. ZHEJIANG UNIVERSITY
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:78](../src/scenes/phone/P04_CampusCard/index.tsx#L78)
271. 学 号：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:88](../src/scenes/phone/P04_CampusCard/index.tsx#L88)
272. 学号未读取
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:89](../src/scenes/phone/P04_CampusCard/index.tsx#L89)
273. 姓 名：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:92](../src/scenes/phone/P04_CampusCard/index.tsx#L92)
274. 姓名未读取
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:93](../src/scenes/phone/P04_CampusCard/index.tsx#L93)
275. 卡账户：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:96](../src/scenes/phone/P04_CampusCard/index.tsx#L96)
276. 校园卡余额：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:100](../src/scenes/phone/P04_CampusCard/index.tsx#L100)
277. 我的零钱：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:113](../src/scenes/phone/P04_CampusCard/index.tsx#L113)
278. 账单
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:121](../src/scenes/phone/P04_CampusCard/index.tsx#L121)
279. 挂失·解挂
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:133](../src/scenes/phone/P04_CampusCard/index.tsx#L133)
280. ▎校园新闻
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:139](../src/scenes/phone/P04_CampusCard/index.tsx#L139)
281. 查看全部 ›
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:140](../src/scenes/phone/P04_CampusCard/index.tsx#L140)
282. 浙江大学图书馆暑期开放安排通知！
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:142](../src/scenes/phone/P04_CampusCard/index.tsx#L142)
283. 2026 年暑期图书馆开放安排
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:143](../src/scenes/phone/P04_CampusCard/index.tsx#L143)
284. 1天前 · 校园资讯中心
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:144](../src/scenes/phone/P04_CampusCard/index.tsx#L144)
285. 返回浙大钉
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:147](../src/scenes/phone/P04_CampusCard/index.tsx#L147)
286. 首页
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:150](../src/scenes/phone/P04_CampusCard/index.tsx#L150)
287. 资讯
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:151](../src/scenes/phone/P04_CampusCard/index.tsx#L151)
288. 校园码
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:152](../src/scenes/phone/P04_CampusCard/index.tsx#L152)
289. 应用
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:153](../src/scenes/phone/P04_CampusCard/index.tsx#L153)
290. 我的
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:154](../src/scenes/phone/P04_CampusCard/index.tsx#L154)
291. 校园地图将在第二章开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:883](../src/scenes/phone/P15_Zjuding/index.tsx#L883)
292. 校园地图还没有响应你的进入请求。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:896](../src/scenes/phone/P15_Zjuding/index.tsx#L896)
293. 图书馆现场还没有开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:904](../src/scenes/phone/P15_Zjuding/index.tsx#L904)
294. 任务更新：在浙大钉预约图书馆座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:959](../src/scenes/phone/P15_Zjuding/index.tsx#L959)
295. task
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:959](../src/scenes/phone/P15_Zjuding/index.tsx#L959)；[src/scenes/phone/P15_Zjuding/index.tsx:978](../src/scenes/phone/P15_Zjuding/index.tsx#L978)
296. 电子校园卡将在第二章寝室任务中取得。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:968](../src/scenes/phone/P15_Zjuding/index.tsx#L968)
297. 黄页联络成功
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:978](../src/scenes/phone/P15_Zjuding/index.tsx#L978)
298. 您拨打的电话正在通话中，请稍后再拨。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:984](../src/scenes/phone/P15_Zjuding/index.tsx#L984)
299. 姓名或学号不匹配。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:987](../src/scenes/phone/P15_Zjuding/index.tsx#L987)
300. 读卡器正在逐字识别。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:992](../src/scenes/phone/P15_Zjuding/index.tsx#L992)
301. 姓名和学号已经读入。拨出这通电话。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:996](../src/scenes/phone/P15_Zjuding/index.tsx#L996)
302. 离开图书馆
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:150](../src/scenes/rpg/LibraryInteriorModel.ts#L150)
303. 查看入馆记录
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:159](../src/scenes/rpg/LibraryInteriorModel.ts#L159)
304. 前台工作人员
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:173](../src/scenes/rpg/LibraryInteriorModel.ts#L173)
305. 馆藏检索终端
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:185](../src/scenes/rpg/LibraryInteriorModel.ts#L185)
306. 自助打印机
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:195](../src/scenes/rpg/LibraryInteriorModel.ts#L195)
307. 文学书架夹层
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:206](../src/scenes/rpg/LibraryInteriorModel.ts#L206)
308. 检查占座书包
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:219](../src/scenes/rpg/LibraryInteriorModel.ts#L219)；[src/scenes/rpg/LibraryInteriorScene.ts:592](../src/scenes/rpg/LibraryInteriorScene.ts#L592)
309. 桌面夹缝
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:234](../src/scenes/rpg/LibraryInteriorModel.ts#L234)
310. 拿起占座纸条
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:246](../src/scenes/rpg/LibraryInteriorModel.ts#L246)
311. 坐到 022
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:257](../src/scenes/rpg/LibraryInteriorModel.ts#L257)
312. 索书号 755
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:67](../src/scenes/rpg/LibraryInteriorScene.ts#L67)
313. 物品识别报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:68](../src/scenes/rpg/LibraryInteriorScene.ts#L68)
314. 右移箭头
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:69](../src/scenes/rpg/LibraryInteriorScene.ts#L69)
315. 离座清退 PASS
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:70](../src/scenes/rpg/LibraryInteriorScene.ts#L70)
316. 前台：请出示物品识别报告。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:74](../src/scenes/rpg/LibraryInteriorScene.ts#L74)
317. 玩家：我用肉眼看不行吗？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:75](../src/scenes/rpg/LibraryInteriorScene.ts#L75)
318. 前台：肉眼不是本部门认可设备。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:76](../src/scenes/rpg/LibraryInteriorScene.ts#L76)
319. 系统：你看，眼睛又输了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:77](../src/scenes/rpg/LibraryInteriorScene.ts#L77)
320. 记录已保存
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:364](../src/scenes/rpg/LibraryInteriorScene.ts#L364)
321. success
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:364](../src/scenes/rpg/LibraryInteriorScene.ts#L364)；[src/scenes/rpg/LibraryInteriorScene.ts:385](../src/scenes/rpg/LibraryInteriorScene.ts#L385)；[src/scenes/rpg/LibraryInteriorScene.ts:900](../src/scenes/rpg/LibraryInteriorScene.ts#L900)；[src/scenes/rpg/LibraryInteriorScene.ts:940](../src/scenes/rpg/LibraryInteriorScene.ts#L940)；[src/scenes/rpg/LibraryInteriorScene.ts:1184](../src/scenes/rpg/LibraryInteriorScene.ts#L1184)；[src/scenes/rpg/LibraryInteriorScene.ts:1208](../src/scenes/rpg/LibraryInteriorScene.ts#L1208)；[src/scenes/rpg/LibraryInteriorScene.ts:1301](../src/scenes/rpg/LibraryInteriorScene.ts#L1301)
322. 占座纸条已收入道具栏
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:372](../src/scenes/rpg/LibraryInteriorScene.ts#L372)
323. 旧规则已确认：三项证明要求已核对，可继续补齐未完成材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:380](../src/scenes/rpg/LibraryInteriorScene.ts#L380)
324. 图书馆馆藏检索功能已解锁。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:385](../src/scenes/rpg/LibraryInteriorScene.ts#L385)
325. 前台接过报告，正在核对照片、座位号和物品身份。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:390](../src/scenes/rpg/LibraryInteriorScene.ts#L390)
326. 任务更新：追上逃跑的记录纸条
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:415](../src/scenes/rpg/LibraryInteriorScene.ts#L415)
327. chapter
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:415](../src/scenes/rpg/LibraryInteriorScene.ts#L415)
328. broadcast
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:419](../src/scenes/rpg/LibraryInteriorScene.ts#L419)
329. no\_target
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:435](../src/scenes/rpg/LibraryInteriorScene.ts#L435)
330. missed\_target
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:438](../src/scenes/rpg/LibraryInteriorScene.ts#L438)
331. 把道具拖到画面中对应的真实物体。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:439](../src/scenes/rpg/LibraryInteriorScene.ts#L439)
332. wrong\_item
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:448](../src/scenes/rpg/LibraryInteriorScene.ts#L448)；[src/scenes/rpg/LibraryInteriorScene.ts:453](../src/scenes/rpg/LibraryInteriorScene.ts#L453)
333. too\_far
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:462](../src/scenes/rpg/LibraryInteriorScene.ts#L462)；[src/scenes/rpg/LibraryInteriorScene.ts:466](../src/scenes/rpg/LibraryInteriorScene.ts#L466)
334. unavailable
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:481](../src/scenes/rpg/LibraryInteriorScene.ts#L481)
335. locked
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:484](../src/scenes/rpg/LibraryInteriorScene.ts#L484)
336. 对应道具
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:582](../src/scenes/rpg/LibraryInteriorScene.ts#L582)
337. 拖入「{{itemLabel}}」 {{target.label}}
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:583](../src/scenes/rpg/LibraryInteriorScene.ts#L583)
338. 前台正在核验并盖章
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:587](../src/scenes/rpg/LibraryInteriorScene.ts#L587)
339. 询问前台工作人员
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:589](../src/scenes/rpg/LibraryInteriorScene.ts#L589)
340. 继续与 022 对话
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:594](../src/scenes/rpg/LibraryInteriorScene.ts#L594)
341. 前台正在整理失物记录，目前没有需要办理的材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:641](../src/scenes/rpg/LibraryInteriorScene.ts#L641)
342. 三项证明已齐，上传给大家看看。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:643](../src/scenes/rpg/LibraryInteriorScene.ts#L643)
343. 前台：先在照片页面生成物品识别报告，再拿来核验。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:645](../src/scenes/rpg/LibraryInteriorScene.ts#L645)
344. 前台：把物品识别报告递到柜台上，我核验后盖章。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:646](../src/scenes/rpg/LibraryInteriorScene.ts#L646)
345. 前台正在核对报告，请等她完成盖章。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:647](../src/scenes/rpg/LibraryInteriorScene.ts#L647)
346. 前台：非本人证明已经盖好，继续补齐另外两项材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:648](../src/scenes/rpg/LibraryInteriorScene.ts#L648)
347. 馆藏检索已同步到图书馆，可按帖子中的题名继续查找。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:653](../src/scenes/rpg/LibraryInteriorScene.ts#L653)
348. 终端可以检索题名、作者和索书号，当前没有调查关键词。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:654](../src/scenes/rpg/LibraryInteriorScene.ts#L654)
349. 书架：I247.55 区域。它看起来不是书架，是一串密码伪装成家具。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:658](../src/scenes/rpg/LibraryInteriorScene.ts#L658)
350. 书架：I247.?? 区域。看不清楚，有没有具体索书号？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:659](../src/scenes/rpg/LibraryInteriorScene.ts#L659)
351. 恢复申请已经通过，PASS 可对现场占用物生效。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:663](../src/scenes/rpg/LibraryInteriorScene.ts#L663)
352. 打印机显示缺纸；旁边的纸盒显示库存充足。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:671](../src/scenes/rpg/LibraryInteriorScene.ts#L671)
353. 夹缝里露出一角小票，手指无法直接取出。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:674](../src/scenes/rpg/LibraryInteriorScene.ts#L674)
354. 纸条引用了一段公开讨论，关键词仍可辨认。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:675](../src/scenes/rpg/LibraryInteriorScene.ts#L675)
355. 椅子仍被占用。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:676](../src/scenes/rpg/LibraryInteriorScene.ts#L676)
356. 座位已经空出，可以坐下确认会话。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:676](../src/scenes/rpg/LibraryInteriorScene.ts#L676)
357. 07:55
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:774](../src/scenes/rpg/LibraryInteriorScene.ts#L774)
358. 主馆入口
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:774](../src/scenes/rpg/LibraryInteriorScene.ts#L774)；[src/scenes/rpg/LibraryInteriorScene.ts:1678](../src/scenes/rpg/LibraryInteriorScene.ts#L1678)
359. 08:02
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:775](../src/scenes/rpg/LibraryInteriorScene.ts#L775)
360. 二楼南区 022
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:775](../src/scenes/rpg/LibraryInteriorScene.ts#L775)；[src/scenes/rpg/LibraryInteriorScene.ts:1697](../src/scenes/rpg/LibraryInteriorScene.ts#L1697)
361. 这个道具和目标的证据类型对不上。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:821](../src/scenes/rpg/LibraryInteriorScene.ts#L821)
362. 先走到{{targetLabel ? \`「${targetLabel}」\` : "目标"}}的可操作边缘，再使用道具。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:823](../src/scenes/rpg/LibraryInteriorScene.ts#L823)
363. 道具没有落在可交互目标上。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:825](../src/scenes/rpg/LibraryInteriorScene.ts#L825)
364. 条件还不完整，目标暂时不接受这个操作。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:826](../src/scenes/rpg/LibraryInteriorScene.ts#L826)
365. error
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:827](../src/scenes/rpg/LibraryInteriorScene.ts#L827)；[src/scenes/rpg/LibraryInteriorScene.ts:887](../src/scenes/rpg/LibraryInteriorScene.ts#L887)
366. 022 仍有微弱信号，信号源被书包压住了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:887](../src/scenes/rpg/LibraryInteriorScene.ts#L887)
367. 书架开始缓慢横移，后面的夹层逐渐露出一份旧黄纸。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:940](../src/scenes/rpg/LibraryInteriorScene.ts#L940)
368. 022 · 空闲
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1083](../src/scenes/rpg/LibraryInteriorScene.ts#L1083)
369. 022 · 占用
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1083](../src/scenes/rpg/LibraryInteriorScene.ts#L1083)；[src/scenes/rpg/LibraryInteriorScene.ts:2319](../src/scenes/rpg/LibraryInteriorScene.ts#L2319)
370. 前台盖章完成：书包不等于本人。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1184](../src/scenes/rpg/LibraryInteriorScene.ts#L1184)
371. 小票向“右”了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1208](../src/scenes/rpg/LibraryInteriorScene.ts#L1208)
372. 022 · 转移中
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1242](../src/scenes/rpg/LibraryInteriorScene.ts#L1242)
373. 书包：主人马上回来。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1244](../src/scenes/rpg/LibraryInteriorScene.ts#L1244)
374. 玩家：什么时候？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1245](../src/scenes/rpg/LibraryInteriorScene.ts#L1245)
375. 书包：三分钟。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1246](../src/scenes/rpg/LibraryInteriorScene.ts#L1246)
376. 系统：它三天前也是这么说的。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1247](../src/scenes/rpg/LibraryInteriorScene.ts#L1247)
377. 022 已恢复。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1301](../src/scenes/rpg/LibraryInteriorScene.ts#L1301)
378. 图书馆门禁 · 入馆记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1648](../src/scenes/rpg/LibraryInteriorScene.ts#L1648)
379. 入馆扫描
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1667](../src/scenes/rpg/LibraryInteriorScene.ts#L1667)
380. 到达记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1686](../src/scenes/rpg/LibraryInteriorScene.ts#L1686)
381. 到座耗时核对：08:02 − 07:55
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1709](../src/scenes/rpg/LibraryInteriorScene.ts#L1709)
382. 目标记录：二楼南区 022 · 会话未闭合
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1715](../src/scenes/rpg/LibraryInteriorScene.ts#L1715)
383. 记下记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1723](../src/scenes/rpg/LibraryInteriorScene.ts#L1723)；[src/scenes/rpg/LibraryInteriorScene.ts:1870](../src/scenes/rpg/LibraryInteriorScene.ts#L1870)
384. Enter / 空格 确认 · Esc 关闭
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1736](../src/scenes/rpg/LibraryInteriorScene.ts#L1736)
385. 入馆记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1806](../src/scenes/rpg/LibraryInteriorScene.ts#L1806)
386. 点击查看
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1812](../src/scenes/rpg/LibraryInteriorScene.ts#L1812)；[src/scenes/rpg/LibraryInteriorScene.ts:1927](../src/scenes/rpg/LibraryInteriorScene.ts#L1927)
387. 关闭记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1870](../src/scenes/rpg/LibraryInteriorScene.ts#L1870)
388. 已读取 · 点击复查
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1927](../src/scenes/rpg/LibraryInteriorScene.ts#L1927)
389. 基础图书馆 · 二层南区
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1936](../src/scenes/rpg/LibraryInteriorScene.ts#L1936)
390. 信息台 / 失物招领
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2028](../src/scenes/rpg/LibraryInteriorScene.ts#L2028)
391. 图
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2095](../src/scenes/rpg/LibraryInteriorScene.ts#L2095)
392. 物
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2095](../src/scenes/rpg/LibraryInteriorScene.ts#L2095)
393. 座
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2095](../src/scenes/rpg/LibraryInteriorScene.ts#L2095)
394. 非本人
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2119](../src/scenes/rpg/LibraryInteriorScene.ts#L2119)
395. 请靠近信息台柜台。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2150](../src/scenes/rpg/LibraryInteriorScene.ts#L2150)
396. 等待报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2169](../src/scenes/rpg/LibraryInteriorScene.ts#L2169)
397. 递交报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2170](../src/scenes/rpg/LibraryInteriorScene.ts#L2170)
398. 人工核验
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2171](../src/scenes/rpg/LibraryInteriorScene.ts#L2171)
399. 已盖章
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2172](../src/scenes/rpg/LibraryInteriorScene.ts#L2172)
400. 馆藏检索 / 打印
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2217](../src/scenes/rpg/LibraryInteriorScene.ts#L2217)
401. 文学 / 社科书架
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2234](../src/scenes/rpg/LibraryInteriorScene.ts#L2234)
402. 旧规
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2289](../src/scenes/rpg/LibraryInteriorScene.ts#L2289)
403. 二层南区 · 安静阅览
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2308](../src/scenes/rpg/LibraryInteriorScene.ts#L2308)

## 第三章

1. Single continuous static top-down 2D pixel-art gameplay shot, 16:9. Begin exactly from the supplied Qizhen Lake rainy capsize frame. Preserve the lake, pier, buoys, shoreline, pixel grid, lighting, kayak color and shape, and human scale. In heavy rain the orange kayak completes one roll and drifts only a short distance. The same dark-blue-jacket student surfaces beside it; the head and both arms remain visible. From the lower wooden pier, a college teacher in a dark teal raincoat and a campus safety officer in navy throw one orange life ring attached to a rope. The ring lands beside the student, the student grips it, and both adults pull the student smoothly toward the pier. End with the student safely sitting on the pier under a pale towel while both adults stand nearby. Water ripples and rain continue. No camera movement, no cut, no zoom, no view change, no close-up, no extra people, no extra boats, no text, no UI, no logo, no subtitles, no anatomy distortion, no disappearing limbs.
   来源：[src/assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.manifest.json:24](../src/assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.manifest.json#L24)
2. 地图、码头、浮标和雨势保持稳定；翻覆、抛圈、拉回、披毛巾动作连续。人物末段较游戏精灵写实，缩放至 RPG 视口后可接受。
   来源：[src/assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.manifest.json:29](../src/assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.manifest.json#L29)
3. 短暂加载后：
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:47](../src/components/ChapterThreeOpeningOverlay.tsx#L47)
4. 获得功能：外观模式切换
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:48](../src/components/ChapterThreeOpeningOverlay.tsx#L48)
5. 纸条突然从 022 座位详情页弹出，贴着图书馆窗缝飞走。
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:49](../src/components/ChapterThreeOpeningOverlay.tsx#L49)
6. 切到深色模式，看到纸条脚印通向出口。
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:50](../src/components/ChapterThreeOpeningOverlay.tsx#L50)
7. 切回浅色模式，发现出口被书车挡住。
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:51](../src/components/ChapterThreeOpeningOverlay.tsx#L51)
8. 再次切到深色模式，确认脚印通向食堂。
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:52](../src/components/ChapterThreeOpeningOverlay.tsx#L52)
9. 当前任务：追上逃跑的记录纸条
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:53](../src/components/ChapterThreeOpeningOverlay.tsx#L53)
10. 离开图书馆，在校园里继续追踪纸条。
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:54](../src/components/ChapterThreeOpeningOverlay.tsx#L54)
11. 玩家
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:142](../src/components/ChapterThreeOpeningOverlay.tsx#L142)
12. 系统
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:143](../src/components/ChapterThreeOpeningOverlay.tsx#L143)
13. 纸条
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:144](../src/components/ChapterThreeOpeningOverlay.tsx#L144)
14. 第二章到第三章转场演出
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:367](../src/components/ChapterThreeOpeningOverlay.tsx#L367)
15. CHAPTER 03
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:383](../src/components/ChapterThreeOpeningOverlay.tsx#L383)
16. 07:55 的残影
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:384](../src/components/ChapterThreeOpeningOverlay.tsx#L384)
17. RECORD QUERY
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:390](../src/components/ChapterThreeOpeningOverlay.tsx#L390)
18. 外观模式切换
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:395](../src/components/ChapterThreeOpeningOverlay.tsx#L395)
19. 浅色模式
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:396](../src/components/ChapterThreeOpeningOverlay.tsx#L396)
20. 深色模式
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:396](../src/components/ChapterThreeOpeningOverlay.tsx#L396)
21. 当前校园 / 07:55 的校园残影
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:397](../src/components/ChapterThreeOpeningOverlay.tsx#L397)
22. 本人马上回来
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:402](../src/components/ChapterThreeOpeningOverlay.tsx#L402)
23. 热气
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:410](../src/components/ChapterThreeOpeningOverlay.tsx#L410)
24. 食堂
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:410](../src/components/ChapterThreeOpeningOverlay.tsx#L410)
25. 退款
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:410](../src/components/ChapterThreeOpeningOverlay.tsx#L410)
26. 追到东区大食堂
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:424](../src/components/ChapterThreeOpeningOverlay.tsx#L424)；[src/core/QuestModel.ts:658](../src/core/QuestModel.ts#L658)；[src/core/QuestModel.ts:684](../src/core/QuestModel.ts#L684)；[src/core/QuestModel.ts:686](../src/core/QuestModel.ts#L686)；[src/core/QuestModel.ts:688](../src/core/QuestModel.ts#L688)
27. 地点
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:429](../src/components/ChapterThreeOpeningOverlay.tsx#L429)
28. 剧情
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:429](../src/components/ChapterThreeOpeningOverlay.tsx#L429)
29. 回到校园
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:434](../src/components/ChapterThreeOpeningOverlay.tsx#L434)
30. 继续演出
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:434](../src/components/ChapterThreeOpeningOverlay.tsx#L434)
31. 快进此句
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:434](../src/components/ChapterThreeOpeningOverlay.tsx#L434)
32. 跳过演出
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:445](../src/components/ChapterThreeOpeningOverlay.tsx#L445)
33. 演出已暂停
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:449](../src/components/ChapterThreeOpeningOverlay.tsx#L449)
34. 确认能否下水
   来源：[src/core/QuestModel.ts:327](../src/core/QuestModel.ts#L327)
35. 器材收齐后，去小码头找值班老师确认。
   来源：[src/core/QuestModel.ts:328](../src/core/QuestModel.ts#L328)
36. 再次尝试登船
   来源：[src/core/QuestModel.ts:332](../src/core/QuestModel.ts#L332)
37. 回到皮划艇旁。
   来源：[src/core/QuestModel.ts:333](../src/core/QuestModel.ts#L333)
38. 靠近食堂里的异常纸条
   来源：[src/core/QuestModel.ts:411](../src/core/QuestModel.ts#L411)
39. 纸条停在入口附近，靠近后会继续移动。
   来源：[src/core/QuestModel.ts:411](../src/core/QuestModel.ts#L411)
40. 先完成餐盘回收，取得后续行动需要的零钱和纸巾。
   来源：[src/core/QuestModel.ts:414](../src/core/QuestModel.ts#L414)
41. 与收餐口阿姨交谈
   来源：[src/core/QuestModel.ts:414](../src/core/QuestModel.ts#L414)；[src/scenes/rpg/CanteenInteriorScene.ts:915](../src/scenes/rpg/CanteenInteriorScene.ts#L915)
42. 找出并交回带污渍的餐盘（{{returnedTargetTrays}}/3）
   来源：[src/core/QuestModel.ts:419](../src/core/QuestModel.ts#L419)
43. 深色观察可辨认蓝光和油渍；浅色操作可直接拿起餐盘并交给收餐口阿姨。
   来源：[src/core/QuestModel.ts:420](../src/core/QuestModel.ts#L420)
44. 一次只能搬一个餐盘。
   来源：[src/core/QuestModel.ts:420](../src/core/QuestModel.ts#L420)
45. 查看第三列队伍和新品宣传板
   来源：[src/core/QuestModel.ts:425](../src/core/QuestModel.ts#L425)
46. 与排队学生交谈，确认怎样让第三列队伍移动。
   来源：[src/core/QuestModel.ts:425](../src/core/QuestModel.ts#L425)
47. 查看饮料货架的颜色顺序
   来源：[src/core/QuestModel.ts:428](../src/core/QuestModel.ts#L428)
48. 货架从左到右的颜色决定调配顺序。
   来源：[src/core/QuestModel.ts:428](../src/core/QuestModel.ts#L428)
49. 在校园地图核对地点交点
   来源：[src/core/QuestModel.ts:474](../src/core/QuestModel.ts#L474)
50. 三条地点记录已接入。
   来源：[src/core/QuestModel.ts:476](../src/core/QuestModel.ts#L476)
51. 打开浙大钉的校园地图，完成最后核对。
   来源：[src/core/QuestModel.ts:477](../src/core/QuestModel.ts#L477)
52. 从校园地图前往启真湖
   来源：[src/core/QuestModel.ts:492](../src/core/QuestModel.ts#L492)
53. 进入大地图后走到启真湖入口。
   来源：[src/core/QuestModel.ts:493](../src/core/QuestModel.ts#L493)
54. 手机地图已确认地点。
   来源：[src/core/QuestModel.ts:493](../src/core/QuestModel.ts#L493)
55. 启真湖追纸
   来源：[src/core/QuestModel.ts:498](../src/core/QuestModel.ts#L498)
56. 去 CC98 接下学生剧现场帮抢委托
   来源：[src/core/QuestModel.ts:505](../src/core/QuestModel.ts#L505)
57. 手机 CC98 出现了一条学生剧临时退票求助帖。
   来源：[src/core/QuestModel.ts:507](../src/core/QuestModel.ts#L507)
58. 接单后再到剧院大厅确认取票时间。
   来源：[src/core/QuestModel.ts:508](../src/core/QuestModel.ts#L508)
59. 在剧院大厅确认 08:32 放票时间
   来源：[src/core/QuestModel.ts:517](../src/core/QuestModel.ts#L517)
60. 在深色观察中靠近取票机，读取屏幕残影。
   来源：[src/core/QuestModel.ts:519](../src/core/QuestModel.ts#L519)
61. 确认时间后回到手机 CC98 帖子参加第一波。
   来源：[src/core/QuestModel.ts:520](../src/core/QuestModel.ts#L520)
62. 在手机 CC98 票务页参加第一波放票
   来源：[src/core/QuestModel.ts:526](../src/core/QuestModel.ts#L526)
63. 打开学生剧现场帮抢帖，在票务卡中操作。
   来源：[src/core/QuestModel.ts:528](../src/core/QuestModel.ts#L528)
64. 可以直接抢第一波，也可以先打开控制中心切换到移动数据。
   来源：[src/core/QuestModel.ts:529](../src/core/QuestModel.ts#L529)
65. 在手机票务页参加第二波放票
   来源：[src/core/QuestModel.ts:538](../src/core/QuestModel.ts#L538)
66. 移动数据已经开启。
   来源：[src/core/QuestModel.ts:540](../src/core/QuestModel.ts#L540)
67. 回到 CC98 帮抢帖，等待倒计时结束后点击第二波。
   来源：[src/core/QuestModel.ts:541](../src/core/QuestModel.ts#L541)
68. 开启手机移动数据，等待第二波放票
   来源：[src/core/QuestModel.ts:548](../src/core/QuestModel.ts#L548)
69. 第一波已结束，系统提示响应速度过慢。
   来源：[src/core/QuestModel.ts:550](../src/core/QuestModel.ts#L550)
70. 在 CC98 票务卡中打开控制中心，切换为移动数据。
   来源：[src/core/QuestModel.ts:551](../src/core/QuestModel.ts#L551)
71. 把临时观演票交给检票闸机
   来源：[src/core/QuestModel.ts:560](../src/core/QuestModel.ts#L560)
72. 靠近闸机右侧的读票器。
   来源：[src/core/QuestModel.ts:562](../src/core/QuestModel.ts#L562)
73. 把道具栏里的临时观演票拖到读票器的发光框内。
   来源：[src/core/QuestModel.ts:563](../src/core/QuestModel.ts#L563)
74. 合成两张半票根
   来源：[src/core/QuestModel.ts:570](../src/core/QuestModel.ts#L570)
75. 在道具栏中将半张票根 A 与半张票根 B 组合。
   来源：[src/core/QuestModel.ts:571](../src/core/QuestModel.ts#L571)
76. 去剧院取票机打印半张票根 B
   来源：[src/core/QuestModel.ts:577](../src/core/QuestModel.ts#L577)
77. 手机抢票已经成功，订单取票码是 0832。
   来源：[src/core/QuestModel.ts:579](../src/core/QuestModel.ts#L579)
78. 在浅色操作中靠近取票机，输入取票码打印实体票根。
   来源：[src/core/QuestModel.ts:580](../src/core/QuestModel.ts#L580)
79. 从入口海报栏取得半张票根 A
   来源：[src/core/QuestModel.ts:587](../src/core/QuestModel.ts#L587)
80. 靠近大厅左侧的海报玻璃。
   来源：[src/core/QuestModel.ts:589](../src/core/QuestModel.ts#L589)
81. 把去油纸巾拖到海报玻璃的发光区域。
   来源：[src/core/QuestModel.ts:590](../src/core/QuestModel.ts#L590)
82. 确认两张半票根
   来源：[src/core/QuestModel.ts:596](../src/core/QuestModel.ts#L596)
83. 打开道具栏确认票根 A 与票根 B，再完成组合。
   来源：[src/core/QuestModel.ts:597](../src/core/QuestModel.ts#L597)
84. 追光第 {{Math.min(state.theaterHunt.spotlightRound + 1, 3)}} / 3 轮：观察轨迹，预置灯位并持续照射
   来源：[src/core/QuestModel.ts:630](../src/core/QuestModel.ts#L630)
85. 已完成 {{state.theaterHunt.spotlightRound}} / 3 轮，失败只重试当前轮。
   来源：[src/core/QuestModel.ts:632](../src/core/QuestModel.ts#L632)
86. 查看追光灯下的纸条
   来源：[src/core/QuestModel.ts:642](../src/core/QuestModel.ts#L642)
87. 剧院追纸
   来源：[src/core/QuestModel.ts:652](../src/core/QuestModel.ts#L652)
88. 沿校园地图中留下的脚印前往东区大食堂。
   来源：[src/core/QuestModel.ts:659](../src/core/QuestModel.ts#L659)；[src/core/QuestModel.ts:689](../src/core/QuestModel.ts#L689)
89. 追上逃跑的记录纸条
   来源：[src/data/chapter3-canteen.content.json:4](../src/data/chapter3-canteen.content.json#L4)
90. 纸条钻进了食堂。
   来源：[src/data/chapter3-canteen.content.json:6](../src/data/chapter3-canteen.content.json#L6)
91. 切到深色观察，沿着它留下的蓝色纸屑找路。
   来源：[src/data/chapter3-canteen.content.json:7](../src/data/chapter3-canteen.content.json#L7)
92. 痕迹在热气和收餐口附近断开。
   来源：[src/data/chapter3-canteen.content.json:8](../src/data/chapter3-canteen.content.json#L8)
93. 旁白：纸条钻进了食堂。
   来源：[src/data/chapter3-canteen.content.json:12](../src/data/chapter3-canteen.content.json#L12)
94. 系统：先别跟丢。
   来源：[src/data/chapter3-canteen.content.json:13](../src/data/chapter3-canteen.content.json#L13)
95. 任务：在食堂截住纸条
   来源：[src/data/chapter3-canteen.content.json:15](../src/data/chapter3-canteen.content.json#L15)
96. 深色观察能看见纸条碰过的餐盘和墙角。
   来源：[src/data/chapter3-canteen.content.json:17](../src/data/chapter3-canteen.content.json#L17)
97. 点餐后会拿到一张取餐小票。
   来源：[src/data/chapter3-canteen.content.json:18](../src/data/chapter3-canteen.content.json#L18)
98. 浅色操作可在 3 号窗口交取餐号；深色观察可补充查看窗口残影。
   来源：[src/data/chapter3-canteen.content.json:19](../src/data/chapter3-canteen.content.json#L19)
99. 阿姨：同学，桌上有三只脏盘，能不能帮我送回来？
   来源：[src/data/chapter3-canteen.content.json:23](../src/data/chapter3-canteen.content.json#L23)
100. 玩家：为什么？
   来源：[src/data/chapter3-canteen.content.json:24](../src/data/chapter3-canteen.content.json#L24)
101. 阿姨：我这儿的履带不停，你正好在旁边。
   来源：[src/data/chapter3-canteen.content.json:25](../src/data/chapter3-canteen.content.json#L25)
102. 任务：找出并交回三只带污渍的餐盘。
   来源：[src/data/chapter3-canteen.content.json:27](../src/data/chapter3-canteen.content.json#L27)
103. 当前为深色观察，只能辨认残影；拿取餐盘需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:28](../src/data/chapter3-canteen.content.json#L28)
104. 你手上已经有一个餐盘。先把它交给阿姨。
   来源：[src/data/chapter3-canteen.content.json:29](../src/data/chapter3-canteen.content.json#L29)
105. 阿姨：先拿一个盘子过来。
   来源：[src/data/chapter3-canteen.content.json:30](../src/data/chapter3-canteen.content.json#L30)
106. 已拿起餐盘。把它交给右侧收餐口的阿姨。
   来源：[src/data/chapter3-canteen.content.json:31](../src/data/chapter3-canteen.content.json#L31)
107. 阿姨：这只对，油渍和蓝光都在。
   来源：[src/data/chapter3-canteen.content.json:32](../src/data/chapter3-canteen.content.json#L32)
108. 阿姨：这只很干净，先放这儿。我还要找脏的。
   来源：[src/data/chapter3-canteen.content.json:33](../src/data/chapter3-canteen.content.json#L33)
109. 阿姨：三只都回来了。两块钱和这张纸巾，拿着。
   来源：[src/data/chapter3-canteen.content.json:35](../src/data/chapter3-canteen.content.json#L35)
110. 玩家：收盘子还有工资？
   来源：[src/data/chapter3-canteen.content.json:36](../src/data/chapter3-canteen.content.json#L36)
111. 阿姨：今天有。明天看排班。
   来源：[src/data/chapter3-canteen.content.json:37](../src/data/chapter3-canteen.content.json#L37)
112. 系统：现金 2.00 元已入账。
   来源：[src/data/chapter3-canteen.content.json:38](../src/data/chapter3-canteen.content.json#L38)
113. 阿姨：盘子放履带，别站上去。
   来源：[src/data/chapter3-canteen.content.json:40](../src/data/chapter3-canteen.content.json#L40)
114. 玩家：我能站到前面吗？
   来源：[src/data/chapter3-canteen.content.json:44](../src/data/chapter3-canteen.content.json#L44)
115. 同学：前面没空位。你先看看新品宣传。
   来源：[src/data/chapter3-canteen.content.json:45](../src/data/chapter3-canteen.content.json#L45)
116. 想拿哪一瓶？
   来源：[src/data/chapter3-canteen.content.json:47](../src/data/chapter3-canteen.content.json#L47)
117. 拿饮料
   来源：[src/data/chapter3-canteen.content.json:48](../src/data/chapter3-canteen.content.json#L48)
118. 算了
   来源：[src/data/chapter3-canteen.content.json:49](../src/data/chapter3-canteen.content.json#L49)
119. 这瓶已经在物品栏里，先拿去调配。
   来源：[src/data/chapter3-canteen.content.json:50](../src/data/chapter3-canteen.content.json#L50)
120. 获得气泡水（蓝色）。
   来源：[src/data/chapter3-canteen.content.json:52](../src/data/chapter3-canteen.content.json#L52)
121. 获得柠檬茶（白色）。
   来源：[src/data/chapter3-canteen.content.json:53](../src/data/chapter3-canteen.content.json#L53)
122. 获得黑咖啡（黑色）。
   来源：[src/data/chapter3-canteen.content.json:54](../src/data/chapter3-canteen.content.json#L54)
123. 货架标签被擦花了，先记住颜色顺序。
   来源：[src/data/chapter3-canteen.content.json:56](../src/data/chapter3-canteen.content.json#L56)
124. 货架颜色从左到右：黑色、蓝色、白色。
   来源：[src/data/chapter3-canteen.content.json:57](../src/data/chapter3-canteen.content.json#L57)
125. 请按货架提示调配今日新品。
   来源：[src/data/chapter3-canteen.content.json:58](../src/data/chapter3-canteen.content.json#L58)
126. 先看货架，颜色顺序决定配方。
   来源：[src/data/chapter3-canteen.content.json:59](../src/data/chapter3-canteen.content.json#L59)
127. 这瓶饮料不在道具栏里。
   来源：[src/data/chapter3-canteen.content.json:60](../src/data/chapter3-canteen.content.json#L60)
128. 饮料已经倒入大玻璃杯。
   来源：[src/data/chapter3-canteen.content.json:61](../src/data/chapter3-canteen.content.json#L61)
129. 配方不对，得到难喝饮料。
   来源：[src/data/chapter3-canteen.content.json:62](../src/data/chapter3-canteen.content.json#L62)
130. 配方正确，得到今日新品气泡水。
   来源：[src/data/chapter3-canteen.content.json:63](../src/data/chapter3-canteen.content.json#L63)
131. 玩家：这也能卖？
   来源：[src/data/chapter3-canteen.content.json:65](../src/data/chapter3-canteen.content.json#L65)
132. 系统：已经喝掉。队伍还在原地。
   来源：[src/data/chapter3-canteen.content.json:66](../src/data/chapter3-canteen.content.json#L66)
133. 把今日新品气泡水拖到第三窗口宣传板下方的空杯位。
   来源：[src/data/chapter3-canteen.content.json:68](../src/data/chapter3-canteen.content.json#L68)
134. 宣传板亮了，第三列队伍开始后退。
   来源：[src/data/chapter3-canteen.content.json:69](../src/data/chapter3-canteen.content.json#L69)
135. 今日新品气泡水
   来源：[src/data/chapter3-canteen.content.json:70](../src/data/chapter3-canteen.content.json#L70)
136. 试饮位已开启，请给我们的供货商一格脸面。
   来源：[src/data/chapter3-canteen.content.json:71](../src/data/chapter3-canteen.content.json#L71)
137. 玩家：他们怎么都退了？
   来源：[src/data/chapter3-canteen.content.json:73](../src/data/chapter3-canteen.content.json#L73)
138. 系统：前排看见宣传板，后面跟着挪。空位出来了。
   来源：[src/data/chapter3-canteen.content.json:74](../src/data/chapter3-canteen.content.json#L74)
139. 菜单看起来正常。纸包鸡排在第四项。
   来源：[src/data/chapter3-canteen.content.json:79](../src/data/chapter3-canteen.content.json#L79)
140. 暗色菜单换成了另一套字。
   来源：[src/data/chapter3-canteen.content.json:80](../src/data/chapter3-canteen.content.json#L80)
141. 暗色菜单已记录。浅色操作可在点餐机下单。
   来源：[src/data/chapter3-canteen.content.json:81](../src/data/chapter3-canteen.content.json#L81)
142. 当前为深色观察，只能查看菜单；下单需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:82](../src/data/chapter3-canteen.content.json#L82)
143. 先取完当前餐品，点餐机才接受下一单。
   来源：[src/data/chapter3-canteen.content.json:83](../src/data/chapter3-canteen.content.json#L83)
144. 包过
   来源：[src/data/chapter3-canteen.content.json:85](../src/data/chapter3-canteen.content.json#L85)
145. 包子
   来源：[src/data/chapter3-canteen.content.json:85](../src/data/chapter3-canteen.content.json#L85)
146. 豆过
   来源：[src/data/chapter3-canteen.content.json:86](../src/data/chapter3-canteen.content.json#L86)
147. 豆浆
   来源：[src/data/chapter3-canteen.content.json:86](../src/data/chapter3-canteen.content.json#L86)
148. 鸡蛋
   来源：[src/data/chapter3-canteen.content.json:87](../src/data/chapter3-canteen.content.json#L87)
149. 鸡过
   来源：[src/data/chapter3-canteen.content.json:87](../src/data/chapter3-canteen.content.json#L87)
150. 纸包过
   来源：[src/data/chapter3-canteen.content.json:88](../src/data/chapter3-canteen.content.json#L88)
151. 纸包鸡
   来源：[src/data/chapter3-canteen.content.json:88](../src/data/chapter3-canteen.content.json#L88)
152. 白过
   来源：[src/data/chapter3-canteen.content.json:89](../src/data/chapter3-canteen.content.json#L89)
153. 白粥
   来源：[src/data/chapter3-canteen.content.json:89](../src/data/chapter3-canteen.content.json#L89)
154. 点餐机：已下单
   来源：[src/data/chapter3-canteen.content.json:91](../src/data/chapter3-canteen.content.json#L91)；[src/data/chapter3-canteen.content.json:92](../src/data/chapter3-canteen.content.json#L92)
155. 系统：纸包鸡已经下单。拿好 0755 取餐号。
   来源：[src/data/chapter3-canteen.content.json:93](../src/data/chapter3-canteen.content.json#L93)
156. 先去点餐机拿 0755 取餐号。
   来源：[src/data/chapter3-canteen.content.json:96](../src/data/chapter3-canteen.content.json#L96)
157. 这是一张取纸用的小票，别把它丢掉。
   来源：[src/data/chapter3-canteen.content.json:97](../src/data/chapter3-canteen.content.json#L97)
158. 残影阿姨：……票……
   来源：[src/data/chapter3-canteen.content.json:98](../src/data/chapter3-canteen.content.json#L98)；[src/data/chapter3-canteen.content.json:99](../src/data/chapter3-canteen.content.json#L99)
159. 窗口没有人。去 3 号窗口找残影阿姨。
   来源：[src/data/chapter3-canteen.content.json:100](../src/data/chapter3-canteen.content.json#L100)
160. 深色观察只能查看窗口残影；交票需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:101](../src/data/chapter3-canteen.content.json#L101)
161. 这张票不归这个窗口。
   来源：[src/data/chapter3-canteen.content.json:102](../src/data/chapter3-canteen.content.json#L102)
162. 残影阿姨接过票。
   来源：[src/data/chapter3-canteen.content.json:103](../src/data/chapter3-canteen.content.json#L103)
163. 取餐系统：该餐品不在当前时间。
   来源：[src/data/chapter3-canteen.content.json:105](../src/data/chapter3-canteen.content.json#L105)
164. 玩家：那我点到哪一天了？
   来源：[src/data/chapter3-canteen.content.json:106](../src/data/chapter3-canteen.content.json#L106)
165. 系统：换一个窗口试试。
   来源：[src/data/chapter3-canteen.content.json:107](../src/data/chapter3-canteen.content.json#L107)
166. 获得比较真实的包子。
   来源：[src/data/chapter3-canteen.content.json:110](../src/data/chapter3-canteen.content.json#L110)
167. 获得没什么线索的豆浆。
   来源：[src/data/chapter3-canteen.content.json:111](../src/data/chapter3-canteen.content.json#L111)
168. 获得世界观边缘的鸡蛋。
   来源：[src/data/chapter3-canteen.content.json:112](../src/data/chapter3-canteen.content.json#L112)
169. 获得很热但很没用的白粥。
   来源：[src/data/chapter3-canteen.content.json:113](../src/data/chapter3-canteen.content.json#L113)
170. 1号窗口：0755号，请取粥。
   来源：[src/data/chapter3-canteen.content.json:116](../src/data/chapter3-canteen.content.json#L116)
171. 系统：领到一碗粥。纸条不在这里。
   来源：[src/data/chapter3-canteen.content.json:117](../src/data/chapter3-canteen.content.json#L117)
172. 2号窗口：0755号，请取蛋。
   来源：[src/data/chapter3-canteen.content.json:120](../src/data/chapter3-canteen.content.json#L120)
173. 玩家：纸条会下蛋吗？
   来源：[src/data/chapter3-canteen.content.json:121](../src/data/chapter3-canteen.content.json#L121)
174. 系统：先把这次取餐走完。
   来源：[src/data/chapter3-canteen.content.json:122](../src/data/chapter3-canteen.content.json#L122)
175. 3号窗口：0755 号，请取纸。纸条从蒸汽里弹出。
   来源：[src/data/chapter3-canteen.content.json:124](../src/data/chapter3-canteen.content.json#L124)
176. 3号窗口：0755 号，请取纸。
   来源：[src/data/chapter3-canteen.content.json:125](../src/data/chapter3-canteen.content.json#L125)
177. 餐盘车可以推，先把它放到纸条要去的出口。
   来源：[src/data/chapter3-canteen.content.json:128](../src/data/chapter3-canteen.content.json#L128)
178. 蓝色轨迹停在当前出口。浅色操作可以推动实体餐车。
   来源：[src/data/chapter3-canteen.content.json:129](../src/data/chapter3-canteen.content.json#L129)
179. 这辆餐车没有接上当前蓝色轨迹。
   来源：[src/data/chapter3-canteen.content.json:130](../src/data/chapter3-canteen.content.json#L130)
180. 深色观察只能查看轨迹；推动实体餐车需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:131](../src/data/chapter3-canteen.content.json#L131)
181. 纸条从另一个出口飞走了。
   来源：[src/data/chapter3-canteen.content.json:132](../src/data/chapter3-canteen.content.json#L132)
182. 纸条撞上餐盘车，掉下蓝色纸屑。
   来源：[src/data/chapter3-canteen.content.json:134](../src/data/chapter3-canteen.content.json#L134)
183. 它调头，下一次会换出口。
   来源：[src/data/chapter3-canteen.content.json:135](../src/data/chapter3-canteen.content.json#L135)
184. 阿姨：纸不能打包带走。
   来源：[src/data/chapter3-canteen.content.json:138](../src/data/chapter3-canteen.content.json#L138)
185. 玩家：它自己跑出去的。
   来源：[src/data/chapter3-canteen.content.json:139](../src/data/chapter3-canteen.content.json#L139)
186. 系统：出门，继续追。
   来源：[src/data/chapter3-canteen.content.json:140](../src/data/chapter3-canteen.content.json#L140)
187. 餐盘回收费 2.00 元
   来源：[src/data/chapter3-canteen.content.json:144](../src/data/chapter3-canteen.content.json#L144)
188. 收回三只目标餐盘得到的两元钱，可支付一次扫码骑车。
   来源：[src/data/chapter3-canteen.content.json:145](../src/data/chapter3-canteen.content.json#L145)
189. 油渍纸巾
   来源：[src/data/chapter3-canteen.content.json:146](../src/data/chapter3-canteen.content.json#L146)
190. 收餐口阿姨给的油渍纸巾，可擦掉车锁和海报玻璃上的反光。
   来源：[src/data/chapter3-canteen.content.json:147](../src/data/chapter3-canteen.content.json#L147)
191. 0755 取餐号
   来源：[src/data/chapter3-canteen.content.json:148](../src/data/chapter3-canteen.content.json#L148)
192. 点餐机打印的取餐小票。浅色操作时可交给对应取餐窗口。
   来源：[src/data/chapter3-canteen.content.json:149](../src/data/chapter3-canteen.content.json#L149)
193. 纸条沿主干道飞走。
   来源：[src/data/chapter3-canteen.content.json:153](../src/data/chapter3-canteen.content.json#L153)；[src/data/chapter3-story-lines.json:119](../src/data/chapter3-story-lines.json#L119)
194. 系统：共享单车在路边。用 2.00 元扫码。
   来源：[src/data/chapter3-canteen.content.json:154](../src/data/chapter3-canteen.content.json#L154)
195. 玩家：它已经跑远了。
   来源：[src/data/chapter3-canteen.content.json:155](../src/data/chapter3-canteen.content.json#L155)
196. 系统：骑上车，别再看它。
   来源：[src/data/chapter3-canteen.content.json:156](../src/data/chapter3-canteen.content.json#L156)
197. 扫码骑车：2.00 元 / 次
   来源：[src/data/chapter3-canteen.content.json:158](../src/data/chapter3-canteen.content.json#L158)
198. 我的零钱：{amount} 元
   来源：[src/data/chapter3-canteen.content.json:159](../src/data/chapter3-canteen.content.json#L159)
199. 玩家：零钱不够。
   来源：[src/data/chapter3-canteen.content.json:161](../src/data/chapter3-canteen.content.json#L161)
200. 系统：先完成餐盘回收。
   来源：[src/data/chapter3-canteen.content.json:162](../src/data/chapter3-canteen.content.json#L162)
201. 餐盘回收费已到账。用 2.00 元支付一次骑行。
   来源：[src/data/chapter3-canteen.content.json:164](../src/data/chapter3-canteen.content.json#L164)
202. 反光过强，识别失败
   来源：[src/data/chapter3-canteen.content.json:165](../src/data/chapter3-canteen.content.json#L165)
203. 显示完整编号与二维码边缘压痕
   来源：[src/data/chapter3-canteen.content.json:166](../src/data/chapter3-canteen.content.json#L166)
204. 残影记录不具备支付资格。
   来源：[src/data/chapter3-canteen.content.json:167](../src/data/chapter3-canteen.content.json#L167)
205. 反光消失，二维码可读
   来源：[src/data/chapter3-canteen.content.json:168](../src/data/chapter3-canteen.content.json#L168)
206. 浅色操作可清洁车锁并扫码付款；深色观察可补充查看编号压痕。
   来源：[src/data/chapter3-canteen.content.json:169](../src/data/chapter3-canteen.content.json#L169)
207. 755 米骑行完成，纸条钻进剧院。
   来源：[src/data/chapter3-canteen.content.json:170](../src/data/chapter3-canteen.content.json#L170)
208. 人行道上有人赶早课，没人注意纸条掠过车道。
   来源：[src/data/chapter3-canteen.content.json:172](../src/data/chapter3-canteen.content.json#L172)
209. 食堂门口两个人聊着天，占住了外侧车道。
   来源：[src/data/chapter3-canteen.content.json:173](../src/data/chapter3-canteen.content.json#L173)
210. 有人端着豆浆停在路边，给你留出一段空路。
   来源：[src/data/chapter3-canteen.content.json:174](../src/data/chapter3-canteen.content.json#L174)
211. 前面有人推车过马路，纸条已经飞到剧院方向。
   来源：[src/data/chapter3-canteen.content.json:175](../src/data/chapter3-canteen.content.json#L175)
212. 任务：骑车追上纸条
   来源：[src/data/chapter3-canteen.content.json:177](../src/data/chapter3-canteen.content.json#L177)
213. 在车锁旁清除反光并付款。
   来源：[src/data/chapter3-canteen.content.json:179](../src/data/chapter3-canteen.content.json#L179)
214. 骑行时避开前方车辆和行人。
   来源：[src/data/chapter3-canteen.content.json:180](../src/data/chapter3-canteen.content.json#L180)
215. 深色观察可补充查看编号，浅色操作负责清洁与付款。
   来源：[src/data/chapter3-canteen.content.json:181](../src/data/chapter3-canteen.content.json#L181)
216. 在剧院逼停纸条
   来源：[src/data/chapter3-canteen.content.json:185](../src/data/chapter3-canteen.content.json#L185)
217. 纸条进去了，你还没有票。
   来源：[src/data/chapter3-canteen.content.json:187](../src/data/chapter3-canteen.content.json#L187)
218. 深色模式能看到票根、节目单简介里的荧光编号和纸条残影。
   来源：[src/data/chapter3-canteen.content.json:188](../src/data/chapter3-canteen.content.json#L188)
219. 先拼票进场，再让纸条在浅色模式里发光。
   来源：[src/data/chapter3-canteen.content.json:189](../src/data/chapter3-canteen.content.json#L189)
220. 生锈的柜门钥匙
   来源：[src/data/chapter3-qizhen-fishing.charts.json:10](../src/data/chapter3-qizhen-fishing.charts.json#L10)；[src/scenes/rpg/QizhenLakeScene.ts:162](../src/scenes/rpg/QizhenLakeScene.ts#L162)
221. 教学谱面：音符碰到判定线时按对应的 A / S / D
   来源：[src/data/chapter3-qizhen-fishing.charts.json:12](../src/data/chapter3-qizhen-fishing.charts.json#L12)
222. 破损网框
   来源：[src/data/chapter3-qizhen-fishing.charts.json:28](../src/data/chapter3-qizhen-fishing.charts.json#L28)；[src/scenes/rpg/QizhenLakeScene.ts:163](../src/scenes/rpg/QizhenLakeScene.ts#L163)
223. 短判定：按住 A 至圆环结束，再完成收线
   来源：[src/data/chapter3-qizhen-fishing.charts.json:30](../src/data/chapter3-qizhen-fishing.charts.json#L30)
224. 小鲤鱼
   来源：[src/data/chapter3-qizhen-fishing.charts.json:42](../src/data/chapter3-qizhen-fishing.charts.json#L42)；[src/data/chapter3-qizhen-lake.content.json:126](../src/data/chapter3-qizhen-lake.content.json#L126)；[src/scenes/rpg/QizhenLakeScene.ts:164](../src/scenes/rpg/QizhenLakeScene.ts#L164)
225. 一次判定：水纹收紧到判定线时按 S 提竿
   来源：[src/data/chapter3-qizhen-fishing.charts.json:44](../src/data/chapter3-qizhen-fishing.charts.json#L44)
226. 纸条本体
   来源：[src/data/chapter3-qizhen-fishing.charts.json:53](../src/data/chapter3-qizhen-fishing.charts.json#L53)；[src/scenes/rpg/QizhenLakeScene.ts:165](../src/scenes/rpg/QizhenLakeScene.ts#L165)
227. 最终捕纸：保持张力，完整完成八小节
   来源：[src/data/chapter3-qizhen-fishing.charts.json:55](../src/data/chapter3-qizhen-fishing.charts.json#L55)
228. 启真湖
   来源：[src/data/chapter3-qizhen-lake.content.json:3](../src/data/chapter3-qizhen-lake.content.json#L3)
229. 剧场外 · 湖畔方向
   来源：[src/data/chapter3-qizhen-lake.content.json:6](../src/data/chapter3-qizhen-lake.content.json#L6)
230. 湿纸从剧场门边飞出，贴着路面向东移动。
   来源：[src/data/chapter3-qizhen-lake.content.json:11](../src/data/chapter3-qizhen-lake.content.json#L11)
231. 路边只留下几段不连续的水迹。
   来源：[src/data/chapter3-qizhen-lake.content.json:12](../src/data/chapter3-qizhen-lake.content.json#L12)
232. 水迹在湖畔一侧中断，无法直接确认地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:13](../src/data/chapter3-qizhen-lake.content.json#L13)
233. 玩家：它去哪了？
   来源：[src/data/chapter3-qizhen-lake.content.json:17](../src/data/chapter3-qizhen-lake.content.json#L17)
234. 系统：没有连续痕迹，需要核对其他来源。
   来源：[src/data/chapter3-qizhen-lake.content.json:18](../src/data/chapter3-qizhen-lake.content.json#L18)
235. 玩家：那就分头查。
   来源：[src/data/chapter3-qizhen-lake.content.json:19](../src/data/chapter3-qizhen-lake.content.json#L19)
236. 系统：先看论坛和馆藏记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:20](../src/data/chapter3-qizhen-lake.content.json#L20)
237. 【求助】剧院门口飞出一张湿纸，有人看见吗
   来源：[src/data/chapter3-qizhen-lake.content.json:23](../src/data/chapter3-qizhen-lake.content.json#L23)
238. 3楼：刚看到它往有水的地方移动。
   来源：[src/data/chapter3-qizhen-lake.content.json:25](../src/data/chapter3-qizhen-lake.content.json#L25)
239. 8楼：方向靠近桥。
   来源：[src/data/chapter3-qizhen-lake.content.json:26](../src/data/chapter3-qizhen-lake.content.json#L26)
240. 14楼：最后一次看到它时，纸边还在滴水。
   来源：[src/data/chapter3-qizhen-lake.content.json:27](../src/data/chapter3-qizhen-lake.content.json#L27)
241. 系统：论坛线索指向湖区和桥。
   来源：[src/data/chapter3-qizhen-lake.content.json:29](../src/data/chapter3-qizhen-lake.content.json#L29)
242. 玩家：继续找能区分地点的信息。
   来源：[src/data/chapter3-qizhen-lake.content.json:30](../src/data/chapter3-qizhen-lake.content.json#L30)
243. 签到记录夹页
   来源：[src/data/chapter3-qizhen-lake.content.json:33](../src/data/chapter3-qizhen-lake.content.json#L33)
244. 馆藏状态
   来源：[src/data/chapter3-qizhen-lake.content.json:35](../src/data/chapter3-qizhen-lake.content.json#L35)
245. 异常外借
   来源：[src/data/chapter3-qizhen-lake.content.json:35](../src/data/chapter3-qizhen-lake.content.json#L35)
246. 偏高
   来源：[src/data/chapter3-qizhen-lake.content.json:36](../src/data/chapter3-qizhen-lake.content.json#L36)
247. 湿度
   来源：[src/data/chapter3-qizhen-lake.content.json:36](../src/data/chapter3-qizhen-lake.content.json#L36)
248. 定位方式
   来源：[src/data/chapter3-qizhen-lake.content.json:37](../src/data/chapter3-qizhen-lake.content.json#L37)
249. 失效
   来源：[src/data/chapter3-qizhen-lake.content.json:37](../src/data/chapter3-qizhen-lake.content.json#L37)
250. 水面反射区域
   来源：[src/data/chapter3-qizhen-lake.content.json:38](../src/data/chapter3-qizhen-lake.content.json#L38)
251. 最近特征
   来源：[src/data/chapter3-qizhen-lake.content.json:38](../src/data/chapter3-qizhen-lake.content.json#L38)
252. 备注
   来源：[src/data/chapter3-qizhen-lake.content.json:39](../src/data/chapter3-qizhen-lake.content.json#L39)
253. 当前页码只出现在倒影中
   来源：[src/data/chapter3-qizhen-lake.content.json:39](../src/data/chapter3-qizhen-lake.content.json#L39)
254. 玩家：需要在湖面倒影里确认位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:41](../src/data/chapter3-qizhen-lake.content.json#L41)
255. 系统：已记录倒影条件。
   来源：[src/data/chapter3-qizhen-lake.content.json:42](../src/data/chapter3-qizhen-lake.content.json#L42)
256. 朋友：你到哪了？
   来源：[src/data/chapter3-qizhen-lake.content.json:45](../src/data/chapter3-qizhen-lake.content.json#L45)
257. 自动回复：我在跟踪湿纸。
   来源：[src/data/chapter3-qizhen-lake.content.json:46](../src/data/chapter3-qizhen-lake.content.json#L46)
258. 朋友：群里有人在校园湖面拍到了一圈逆风扩散的水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:47](../src/data/chapter3-qizhen-lake.content.json#L47)
259. 已接入 1 条记录，来源还不足以确认地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:50](../src/data/chapter3-qizhen-lake.content.json#L50)
260. 已接入 2 条记录，还缺一个独立来源。
   来源：[src/data/chapter3-qizhen-lake.content.json:51](../src/data/chapter3-qizhen-lake.content.json#L51)
261. 三条记录已对齐。核对交点后才会在校园地图上标记入口。
   来源：[src/data/chapter3-qizhen-lake.content.json:52](../src/data/chapter3-qizhen-lake.content.json#L52)
262. 手机地图：已确认启真湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:53](../src/data/chapter3-qizhen-lake.content.json#L53)
263. 核对结果：桥边、倒影和湖面三条记录指向同一个地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:54](../src/data/chapter3-qizhen-lake.content.json#L54)
264. 核对交点
   来源：[src/data/chapter3-qizhen-lake.content.json:55](../src/data/chapter3-qizhen-lake.content.json#L55)
265. 玩家：前往启真湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:56](../src/data/chapter3-qizhen-lake.content.json#L56)
266. 系统：已建立湖区入口。
   来源：[src/data/chapter3-qizhen-lake.content.json:57](../src/data/chapter3-qizhen-lake.content.json#L57)
267. 玩家：小码头有一艘皮划艇。
   来源：[src/data/chapter3-qizhen-lake.content.json:62](../src/data/chapter3-qizhen-lake.content.json#L62)
268. 系统：船边还缺两件可以划水的工具。
   来源：[src/data/chapter3-qizhen-lake.content.json:63](../src/data/chapter3-qizhen-lake.content.json#L63)
269. 玩家：先完成上船平衡。
   来源：[src/data/chapter3-qizhen-lake.content.json:64](../src/data/chapter3-qizhen-lake.content.json#L64)
270. 任务：先确认皮划艇，再在码头周围寻找两件可以划水的东西。
   来源：[src/data/chapter3-qizhen-lake.content.json:66](../src/data/chapter3-qizhen-lake.content.json#L66)
271. 先查看救生圈旁的器材架。
   来源：[src/data/chapter3-qizhen-lake.content.json:67](../src/data/chapter3-qizhen-lake.content.json#L67)
272. 码头周围有一件细长物体，靠近后再判断能不能使用。
   来源：[src/data/chapter3-qizhen-lake.content.json:68](../src/data/chapter3-qizhen-lake.content.json#L68)
273. 另一件需要从码头现有设施里找。
   来源：[src/data/chapter3-qizhen-lake.content.json:69](../src/data/chapter3-qizhen-lake.content.json#L69)
274. 三件装备收齐后，到码头前端上船，再交替划左右桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:70](../src/data/chapter3-qizhen-lake.content.json#L70)
275. 先把皮划艇划回小码头并上岸。
   来源：[src/data/chapter3-qizhen-lake.content.json:71](../src/data/chapter3-qizhen-lake.content.json#L71)
276. 皮划艇已确认。两支桨没有放在器材架上，继续沿码头寻找。
   来源：[src/data/chapter3-qizhen-lake.content.json:72](../src/data/chapter3-qizhen-lake.content.json#L72)
277. 柳树枝长度合适，已作为左桨。还要找另一侧的桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:73](../src/data/chapter3-qizhen-lake.content.json#L73)
278. 旧三角牌已经拆下，可作为右桨。继续找齐剩余装备。
   来源：[src/data/chapter3-qizhen-lake.content.json:74](../src/data/chapter3-qizhen-lake.content.json#L74)
279. 皮划艇和两支临时桨都已收齐。
   来源：[src/data/chapter3-qizhen-lake.content.json:75](../src/data/chapter3-qizhen-lake.content.json#L75)
280. 值班老师：现在天气不能下水。你要坚持，可以继续靠近码头试试。
   来源：[src/data/chapter3-qizhen-lake.content.json:76](../src/data/chapter3-qizhen-lake.content.json#L76)
281. 值班老师：雨还没停，不能下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:77](../src/data/chapter3-qizhen-lake.content.json#L77)
282. 值班老师：这么不长记性，还想要再成一次落汤鸡不成。
   来源：[src/data/chapter3-qizhen-lake.content.json:78](../src/data/chapter3-qizhen-lake.content.json#L78)
283. 你还是把皮划艇推下水，顶着雨划离了码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:79](../src/data/chapter3-qizhen-lake.content.json#L79)
284. 连续几桨后，侧风把船身压向一边，皮划艇失去平衡。
   来源：[src/data/chapter3-qizhen-lake.content.json:80](../src/data/chapter3-qizhen-lake.content.json#L80)
285. 值班老师和安全员把你救上岸。
   来源：[src/data/chapter3-qizhen-lake.content.json:81](../src/data/chapter3-qizhen-lake.content.json#L81)
286. 值班老师：现在可以下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:82](../src/data/chapter3-qizhen-lake.content.json#L82)；[src/data/chapter3-qizhen-lake.content.json:83](../src/data/chapter3-qizhen-lake.content.json#L83)
287. 这是下过雨的证明
   来源：[src/data/chapter3-qizhen-lake.content.json:84](../src/data/chapter3-qizhen-lake.content.json#L84)
288. 现在天气不能下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:85](../src/data/chapter3-qizhen-lake.content.json#L85)
289. 上船平衡
   来源：[src/data/chapter3-qizhen-lake.content.json:88](../src/data/chapter3-qizhen-lake.content.json#L88)
290. 键盘用 A/左方向键划左桨、D/右方向键划右桨，按住 S 或下方向键再划可后退。触屏在左右桨按钮上向上划为前进、向下划为后退，轻触默认前进。上船时先连续交替前划四次。
   来源：[src/data/chapter3-qizhen-lake.content.json:89](../src/data/chapter3-qizhen-lake.content.json#L89)
291. 连续划同一侧会增大倾角。
   来源：[src/data/chapter3-qizhen-lake.content.json:90](../src/data/chapter3-qizhen-lake.content.json#L90)
292. 后划可以离岸或修正位置；上船平衡仍需交替前划。
   来源：[src/data/chapter3-qizhen-lake.content.json:91](../src/data/chapter3-qizhen-lake.content.json#L91)
293. 皮划艇翻转，已回到最近安全点。
   来源：[src/data/chapter3-qizhen-lake.content.json:92](../src/data/chapter3-qizhen-lake.content.json#L92)
294. 你的手机和眼镜共沉启真湖，只有手机打捞上来了，眼镜永远离开了你。
   来源：[src/data/chapter3-qizhen-lake.content.json:93](../src/data/chapter3-qizhen-lake.content.json#L93)
295. 平衡已稳定，可以进入大湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:94](../src/data/chapter3-qizhen-lake.content.json#L94)
296. 上船阶段横向稳定性低。键盘左右桨默认前划，按住下方向键可后划；触屏上划前进、下划后退。先交替前划四次稳住重心。
   来源：[src/data/chapter3-qizhen-lake.content.json:95](../src/data/chapter3-qizhen-lake.content.json#L95)
297. 任务：交替第 1 次，继续保持。
   来源：[src/data/chapter3-qizhen-lake.content.json:97](../src/data/chapter3-qizhen-lake.content.json#L97)
298. 任务：交替第 2 次，船身渐稳。
   来源：[src/data/chapter3-qizhen-lake.content.json:98](../src/data/chapter3-qizhen-lake.content.json#L98)
299. 任务：交替第 3 次，还差一次。
   来源：[src/data/chapter3-qizhen-lake.content.json:99](../src/data/chapter3-qizhen-lake.content.json#L99)
300. 连续划同一侧导致翻船，左右交替可以稳住船身。
   来源：[src/data/chapter3-qizhen-lake.content.json:101](../src/data/chapter3-qizhen-lake.content.json#L101)
301. 船身被边界挡住。船头方向保持不变；键盘按住 S/↓ 再交替划桨，触屏在左右桨上交替向下划，即可倒出。
   来源：[src/data/chapter3-qizhen-lake.content.json:102](../src/data/chapter3-qizhen-lake.content.json#L102)
302. 键盘 A/← 左桨 · D/→ 右桨 · S/↓+桨 后划｜触屏上划前进 · 下划后退
   来源：[src/data/chapter3-qizhen-lake.content.json:103](../src/data/chapter3-qizhen-lake.content.json#L103)
303. 默认前划
   来源：[src/data/chapter3-qizhen-lake.content.json:104](../src/data/chapter3-qizhen-lake.content.json#L104)
304. 后划已按住
   来源：[src/data/chapter3-qizhen-lake.content.json:105](../src/data/chapter3-qizhen-lake.content.json#L105)
305. 后退中
   来源：[src/data/chapter3-qizhen-lake.content.json:106](../src/data/chapter3-qizhen-lake.content.json#L106)
306. 侧倾
   来源：[src/data/chapter3-qizhen-lake.content.json:107](../src/data/chapter3-qizhen-lake.content.json#L107)；[src/data/chapter3-qizhen-lake.content.json:374](../src/data/chapter3-qizhen-lake.content.json#L374)；[src/modules/QizhenJournalModel.ts:61](../src/modules/QizhenJournalModel.ts#L61)
307. 即将翻船
   来源：[src/data/chapter3-qizhen-lake.content.json:108](../src/data/chapter3-qizhen-lake.content.json#L108)
308. 浅色操作：划船、取物、抛竿和组合道具。
   来源：[src/data/chapter3-qizhen-lake.content.json:111](../src/data/chapter3-qizhen-lake.content.json#L111)
309. 深色观察：记录纸条倒影和物品位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:112](../src/data/chapter3-qizhen-lake.content.json#L112)
310. 这个坐标尚未在深色观察中记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:113](../src/data/chapter3-qizhen-lake.content.json#L113)
311. 系统：已在浮排边找到钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:114](../src/data/chapter3-qizhen-lake.content.json#L114)
312. 假纸条已固定在鱼钩上。
   来源：[src/data/chapter3-qizhen-lake.content.json:115](../src/data/chapter3-qizhen-lake.content.json#L115)
313. 普通鱼钩无法固定纸条。先收齐三处分支材料。
   来源：[src/data/chapter3-qizhen-lake.content.json:116](../src/data/chapter3-qizhen-lake.content.json#L116)
314. 任务：去钥匙倒影对应的浅色水面抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:117](../src/data/chapter3-qizhen-lake.content.json#L117)
315. 道具 1：生锈的柜门钥匙
   来源：[src/data/chapter3-qizhen-lake.content.json:120](../src/data/chapter3-qizhen-lake.content.json#L120)
316. 道具 2：尼龙绳
   来源：[src/data/chapter3-qizhen-lake.content.json:121](../src/data/chapter3-qizhen-lake.content.json#L121)
317. 道具 3：破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:122](../src/data/chapter3-qizhen-lake.content.json#L122)
318. 道具 4：临时抄网
   来源：[src/data/chapter3-qizhen-lake.content.json:123](../src/data/chapter3-qizhen-lake.content.json#L123)
319. 道具 5：密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:124](../src/data/chapter3-qizhen-lake.content.json#L124)
320. 道具 6：鱼饲料颗粒
   来源：[src/data/chapter3-qizhen-lake.content.json:125](../src/data/chapter3-qizhen-lake.content.json#L125)
321. 道具 7：黑天鹅掉落的磁性扣
   来源：[src/data/chapter3-qizhen-lake.content.json:127](../src/data/chapter3-qizhen-lake.content.json#L127)
322. 磁性钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:128](../src/data/chapter3-qizhen-lake.content.json#L128)
323. 检查围栏边遗留的旧饲料盒。
   来源：[src/data/chapter3-qizhen-lake.content.json:131](../src/data/chapter3-qizhen-lake.content.json#L131)
324. 系统：饲料盒处理完成，黑天鹅推来一枚磁性扣。
   来源：[src/data/chapter3-qizhen-lake.content.json:132](../src/data/chapter3-qizhen-lake.content.json#L132)
325. 磁性钓鱼竿已固定纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:133](../src/data/chapter3-qizhen-lake.content.json#L133)
326. 纸条触发围栏机关，黑天鹅进入直河道。
   来源：[src/data/chapter3-qizhen-lake.content.json:134](../src/data/chapter3-qizhen-lake.content.json#L134)
327. 任务：将三处分支材料带回大湖装配位。
   来源：[src/data/chapter3-qizhen-lake.content.json:135](../src/data/chapter3-qizhen-lake.content.json#L135)
328. 磁性钓鱼竿组合完成。
   来源：[src/data/chapter3-qizhen-lake.content.json:136](../src/data/chapter3-qizhen-lake.content.json#L136)
329. 黑天鹅只接受刚钓到的小鲤鱼。
   来源：[src/data/chapter3-qizhen-lake.content.json:137](../src/data/chapter3-qizhen-lake.content.json#L137)
330. 把黑天鹅磁性扣或钓鱼竿拖进组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:138](../src/data/chapter3-qizhen-lake.content.json#L138)
331. 需要磁性钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:139](../src/data/chapter3-qizhen-lake.content.json#L139)
332. 黑天鹅追逐
   来源：[src/data/chapter3-qizhen-lake.content.json:142](../src/data/chapter3-qizhen-lake.content.json#L142)
333. 交替划桨驶向河道左端。停划或撞上障碍会让黑天鹅追上船体。
   来源：[src/data/chapter3-qizhen-lake.content.json:143](../src/data/chapter3-qizhen-lake.content.json#L143)
334. 黑天鹅撞上船尾，追逐失败。
   来源：[src/data/chapter3-qizhen-lake.content.json:144](../src/data/chapter3-qizhen-lake.content.json#L144)
335. 已回到直河道追逐检查点。
   来源：[src/data/chapter3-qizhen-lake.content.json:145](../src/data/chapter3-qizhen-lake.content.json#L145)
336. 已返回小码头。磁性扣损坏，纸条再次逃离。
   来源：[src/data/chapter3-qizhen-lake.content.json:146](../src/data/chapter3-qizhen-lake.content.json#L146)
337. 已抵达河道另一端。
   来源：[src/data/chapter3-qizhen-lake.content.json:147](../src/data/chapter3-qizhen-lake.content.json#L147)
338. 左端抵达即通过
   来源：[src/data/chapter3-qizhen-lake.content.json:148](../src/data/chapter3-qizhen-lake.content.json#L148)
339. 追击距离
   来源：[src/data/chapter3-qizhen-lake.content.json:149](../src/data/chapter3-qizhen-lake.content.json#L149)
340. 黑天鹅接近船尾
   来源：[src/data/chapter3-qizhen-lake.content.json:150](../src/data/chapter3-qizhen-lake.content.json#L150)
341. 水面出现追击水纹
   来源：[src/data/chapter3-qizhen-lake.content.json:152](../src/data/chapter3-qizhen-lake.content.json#L152)
342. 黑天鹅保持追击
   来源：[src/data/chapter3-qizhen-lake.content.json:153](../src/data/chapter3-qizhen-lake.content.json#L153)
343. 黑天鹅正在抬翼蓄力
   来源：[src/data/chapter3-qizhen-lake.content.json:154](../src/data/chapter3-qizhen-lake.content.json#L154)
344. 黑天鹅短距冲刺
   来源：[src/data/chapter3-qizhen-lake.content.json:155](../src/data/chapter3-qizhen-lake.content.json#L155)
345. 黑天鹅减速调整
   来源：[src/data/chapter3-qizhen-lake.content.json:156](../src/data/chapter3-qizhen-lake.content.json#L156)
346. 距离稳定
   来源：[src/data/chapter3-qizhen-lake.content.json:159](../src/data/chapter3-qizhen-lake.content.json#L159)
347. 距离缩短
   来源：[src/data/chapter3-qizhen-lake.content.json:160](../src/data/chapter3-qizhen-lake.content.json#L160)
348. 即将接触船尾
   来源：[src/data/chapter3-qizhen-lake.content.json:161](../src/data/chapter3-qizhen-lake.content.json#L161)
349. 起始段
   来源：[src/data/chapter3-qizhen-lake.content.json:164](../src/data/chapter3-qizhen-lake.content.json#L164)
350. 河道中段
   来源：[src/data/chapter3-qizhen-lake.content.json:165](../src/data/chapter3-qizhen-lake.content.json#L165)
351. 左岸近段
   来源：[src/data/chapter3-qizhen-lake.content.json:166](../src/data/chapter3-qizhen-lake.content.json#L166)
352. 围栏开了。朝左岸划。
   来源：[src/data/chapter3-qizhen-lake.content.json:169](../src/data/chapter3-qizhen-lake.content.json#L169)
353. 它正在船尾对准航线。继续交替划桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:170](../src/data/chapter3-qizhen-lake.content.json#L170)
354. 左岸快到了。稳住节奏。
   来源：[src/data/chapter3-qizhen-lake.content.json:171](../src/data/chapter3-qizhen-lake.content.json#L171)
355. 玩家：纸条只在倒影里出现。
   来源：[src/data/chapter3-qizhen-lake.content.json:175](../src/data/chapter3-qizhen-lake.content.json#L175)
356. 系统：深色观察可以记录它的坐标。
   来源：[src/data/chapter3-qizhen-lake.content.json:175](../src/data/chapter3-qizhen-lake.content.json#L175)
357. 浅色操作可在浮排边捞起漂浮的钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:176](../src/data/chapter3-qizhen-lake.content.json#L176)
358. 系统：位置已记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:176](../src/data/chapter3-qizhen-lake.content.json#L176)
359. 浅色操作显示金色高对比可抛竿水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:177](../src/data/chapter3-qizhen-lake.content.json#L177)
360. 深色观察显示纸条倒影和物品位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:178](../src/data/chapter3-qizhen-lake.content.json#L178)
361. 该位置没有记录到目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:179](../src/data/chapter3-qizhen-lake.content.json#L179)
362. 位置已记录；浅色操作可在对应水纹抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:180](../src/data/chapter3-qizhen-lake.content.json#L180)
363. 在启真湖找到纸条
   来源：[src/data/chapter3-qizhen-lake.content.json:181](../src/data/chapter3-qizhen-lake.content.json#L181)；[src/data/chapter3-qizhen-lake.content.json:266](../src/data/chapter3-qizhen-lake.content.json#L266)
364. 旧指示牌已作为右桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:184](../src/data/chapter3-qizhen-lake.content.json#L184)
365. 浮排河道
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)
366. 禁止游泳
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)
367. 小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)；[src/data/chapter3-qizhen-lake.content.json:244](../src/data/chapter3-qizhen-lake.content.json#L244)；[src/data/chapter3-qizhen-lake.content.json:359](../src/data/chapter3-qizhen-lake.content.json#L359)；[src/scenes/rpg/QizhenLakeModel.ts:471](../src/scenes/rpg/QizhenLakeModel.ts#L471)
368. 该操作不符合当前阶段。
   来源：[src/data/chapter3-qizhen-lake.content.json:186](../src/data/chapter3-qizhen-lake.content.json#L186)
369. 右桨已安装。
   来源：[src/data/chapter3-qizhen-lake.content.json:187](../src/data/chapter3-qizhen-lake.content.json#L187)
370. 倒影坐标已记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:188](../src/data/chapter3-qizhen-lake.content.json#L188)
371. 浅色操作可在对应水纹抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:189](../src/data/chapter3-qizhen-lake.content.json#L189)
372. 任务：把假纸条固定到钓鱼竿上作饵。
   来源：[src/data/chapter3-qizhen-lake.content.json:192](../src/data/chapter3-qizhen-lake.content.json#L192)
373. 深色观察可补充确认坐标；浅色操作也可以直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:193](../src/data/chapter3-qizhen-lake.content.json#L193)
374. 系统：假纸条已装成诱饵，固定到鱼钩上。
   来源：[src/data/chapter3-qizhen-lake.content.json:194](../src/data/chapter3-qizhen-lake.content.json#L194)
375. 倒影中出现可抛竿的位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:195](../src/data/chapter3-qizhen-lake.content.json#L195)
376. 先拖入假纸条当饵；直接用普通钓鱼竿只会穿过倒影。
   来源：[src/data/chapter3-qizhen-lake.content.json:196](../src/data/chapter3-qizhen-lake.content.json#L196)
377. 当前为浅色操作。
   来源：[src/data/chapter3-qizhen-lake.content.json:199](../src/data/chapter3-qizhen-lake.content.json#L199)
378. 当前为深色观察。
   来源：[src/data/chapter3-qizhen-lake.content.json:200](../src/data/chapter3-qizhen-lake.content.json#L200)
379. 当前阶段无法切换观察模式。
   来源：[src/data/chapter3-qizhen-lake.content.json:201](../src/data/chapter3-qizhen-lake.content.json#L201)
380. 操作没有命中当前目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:202](../src/data/chapter3-qizhen-lake.content.json#L202)
381. 未命中目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:203](../src/data/chapter3-qizhen-lake.content.json#L203)
382. 目标已命中。
   来源：[src/data/chapter3-qizhen-lake.content.json:204](../src/data/chapter3-qizhen-lake.content.json#L204)
383. 钓起一把生锈的柜门钥匙。
   来源：[src/data/chapter3-qizhen-lake.content.json:207](../src/data/chapter3-qizhen-lake.content.json#L207)
384. 钓起一个破损网框。
   来源：[src/data/chapter3-qizhen-lake.content.json:208](../src/data/chapter3-qizhen-lake.content.json#L208)
385. 码头储物柜打开，里面是一卷尼龙绳。
   来源：[src/data/chapter3-qizhen-lake.content.json:209](../src/data/chapter3-qizhen-lake.content.json#L209)
386. 尼龙绳已经固定到破损网框，临时抄网完成。
   来源：[src/data/chapter3-qizhen-lake.content.json:210](../src/data/chapter3-qizhen-lake.content.json#L210)
387. 临时抄网从浮排下捞出了密封饲料盒。
   来源：[src/data/chapter3-qizhen-lake.content.json:211](../src/data/chapter3-qizhen-lake.content.json#L211)
388. 在浮排硬边撬开盒盖，得到鱼食颗粒。
   来源：[src/data/chapter3-qizhen-lake.content.json:212](../src/data/chapter3-qizhen-lake.content.json#L212)
389. 鱼食颗粒引来一条小鲤鱼。
   来源：[src/data/chapter3-qizhen-lake.content.json:213](../src/data/chapter3-qizhen-lake.content.json#L213)
390. 这里需要生锈的柜门钥匙。
   来源：[src/data/chapter3-qizhen-lake.content.json:214](../src/data/chapter3-qizhen-lake.content.json#L214)
391. 把尼龙绳或破损网框拖进组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:215](../src/data/chapter3-qizhen-lake.content.json#L215)
392. 这里需要临时抄网。
   来源：[src/data/chapter3-qizhen-lake.content.json:216](../src/data/chapter3-qizhen-lake.content.json#L216)
393. 把密封饲料盒拖到硬边上撬开。
   来源：[src/data/chapter3-qizhen-lake.content.json:217](../src/data/chapter3-qizhen-lake.content.json#L217)
394. 把道具拖到场景中对应的真实物体。
   来源：[src/data/chapter3-qizhen-lake.content.json:220](../src/data/chapter3-qizhen-lake.content.json#L220)
395. 没有命中当前可用物体，靠近并对准后重试。
   来源：[src/data/chapter3-qizhen-lake.content.json:221](../src/data/chapter3-qizhen-lake.content.json#L221)
396. 当前为深色观察；使用实体道具需要浅色操作。
   来源：[src/data/chapter3-qizhen-lake.content.json:222](../src/data/chapter3-qizhen-lake.content.json#L222)
397. 目标对了，把皮划艇划到金色水纹外圈附近即可抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:223](../src/data/chapter3-qizhen-lake.content.json#L223)
398. 先把人物或皮划艇移到高对比标记附近。
   来源：[src/data/chapter3-qizhen-lake.content.json:224](../src/data/chapter3-qizhen-lake.content.json#L224)
399. 当前道具与这个目标不匹配。
   来源：[src/data/chapter3-qizhen-lake.content.json:225](../src/data/chapter3-qizhen-lake.content.json#L225)
400. 确认器材架上的皮划艇
   来源：[src/data/chapter3-qizhen-lake.content.json:228](../src/data/chapter3-qizhen-lake.content.json#L228)
401. 查看花坛边的细长物体
   来源：[src/data/chapter3-qizhen-lake.content.json:229](../src/data/chapter3-qizhen-lake.content.json#L229)
402. 查看设备区的旧设施
   来源：[src/data/chapter3-qizhen-lake.content.json:230](../src/data/chapter3-qizhen-lake.content.json#L230)
403. 从小码头上船
   来源：[src/data/chapter3-qizhen-lake.content.json:231](../src/data/chapter3-qizhen-lake.content.json#L231)
404. 观察倒影位置
   来源：[src/data/chapter3-qizhen-lake.content.json:232](../src/data/chapter3-qizhen-lake.content.json#L232)
405. 捞起钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:233](../src/data/chapter3-qizhen-lake.content.json#L233)
406. 开始节奏钓取
   来源：[src/data/chapter3-qizhen-lake.content.json:234](../src/data/chapter3-qizhen-lake.content.json#L234)
407. 把小鲤鱼喂给黑天鹅
   来源：[src/data/chapter3-qizhen-lake.content.json:235](../src/data/chapter3-qizhen-lake.content.json#L235)
408. 直接抛竿会失败；拖入假纸条作饵
   来源：[src/data/chapter3-qizhen-lake.content.json:236](../src/data/chapter3-qizhen-lake.content.json#L236)
409. 使用当前钓具
   来源：[src/data/chapter3-qizhen-lake.content.json:237](../src/data/chapter3-qizhen-lake.content.json#L237)
410. 冲回小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:238](../src/data/chapter3-qizhen-lake.content.json#L238)
411. 抵达河道左端即自动通过
   来源：[src/data/chapter3-qizhen-lake.content.json:239](../src/data/chapter3-qizhen-lake.content.json#L239)
412. 离开启真湖
   来源：[src/data/chapter3-qizhen-lake.content.json:240](../src/data/chapter3-qizhen-lake.content.json#L240)；[src/scenes/rpg/QizhenLakeModel.ts:348](../src/scenes/rpg/QizhenLakeModel.ts#L348)
413. 当前动作需要浅色操作
   来源：[src/data/chapter3-qizhen-lake.content.json:241](../src/data/chapter3-qizhen-lake.content.json#L241)
414. 启真湖大湖面
   来源：[src/data/chapter3-qizhen-lake.content.json:245](../src/data/chapter3-qizhen-lake.content.json#L245)
415. 浮排直河道
   来源：[src/data/chapter3-qizhen-lake.content.json:246](../src/data/chapter3-qizhen-lake.content.json#L246)
416. 黑天鹅围栏
   来源：[src/data/chapter3-qizhen-lake.content.json:247](../src/data/chapter3-qizhen-lake.content.json#L247)；[src/data/chapter3-qizhen-lake.content.json:361](../src/data/chapter3-qizhen-lake.content.json#L361)；[src/scenes/rpg/QizhenLakeModel.ts:498](../src/scenes/rpg/QizhenLakeModel.ts#L498)
417. 完成上船平衡后才能划向大湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:250](../src/data/chapter3-qizhen-lake.content.json#L250)
418. 钓到小鲤鱼后才能前往黑天鹅围栏。
   来源：[src/data/chapter3-qizhen-lake.content.json:251](../src/data/chapter3-qizhen-lake.content.json#L251)
419. 尼龙绳和破损网框尚未组合成临时抄网。
   来源：[src/data/chapter3-qizhen-lake.content.json:252](../src/data/chapter3-qizhen-lake.content.json#L252)
420. 浮排河道已经处理完。
   来源：[src/data/chapter3-qizhen-lake.content.json:253](../src/data/chapter3-qizhen-lake.content.json#L253)
421. 围栏机关尚未触发，需要先用磁性钓鱼竿取出纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:254](../src/data/chapter3-qizhen-lake.content.json#L254)
422. 密封饲料盒还没捞起并打开。
   来源：[src/data/chapter3-qizhen-lake.content.json:255](../src/data/chapter3-qizhen-lake.content.json#L255)
423. 在小码头分别找齐皮划艇和左右桨
   来源：[src/data/chapter3-qizhen-lake.content.json:258](../src/data/chapter3-qizhen-lake.content.json#L258)
424. 交替划左右桨完成上船
   来源：[src/data/chapter3-qizhen-lake.content.json:259](../src/data/chapter3-qizhen-lake.content.json#L259)
425. 切到深色观察，记录倒影位置
   来源：[src/data/chapter3-qizhen-lake.content.json:260](../src/data/chapter3-qizhen-lake.content.json#L260)
426. 任意顺序完成柜门、浮排和天鹅三处分支
   来源：[src/data/chapter3-qizhen-lake.content.json:261](../src/data/chapter3-qizhen-lake.content.json#L261)
427. 处理围栏边的旧饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:262](../src/data/chapter3-qizhen-lake.content.json#L262)
428. 用磁性钓鱼竿取出纸条
   来源：[src/data/chapter3-qizhen-lake.content.json:263](../src/data/chapter3-qizhen-lake.content.json#L263)
429. 沿直河道逃回小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:264](../src/data/chapter3-qizhen-lake.content.json#L264)
430. 查看启真湖后续过渡剧情
   来源：[src/data/chapter3-qizhen-lake.content.json:265](../src/data/chapter3-qizhen-lake.content.json#L265)
431. 深色观察用于记录坐标，浅色操作可直接尝试抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:268](../src/data/chapter3-qizhen-lake.content.json#L268)
432. 普通鱼钩无法直接固定纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:269](../src/data/chapter3-qizhen-lake.content.json#L269)
433. 道具会在最后一次成功使用后消失。
   来源：[src/data/chapter3-qizhen-lake.content.json:270](../src/data/chapter3-qizhen-lake.content.json#L270)
434. 在大湖面捞起钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:274](../src/data/chapter3-qizhen-lake.content.json#L274)
435. 浅色操作时，在大湖面浮排边捞起钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:275](../src/data/chapter3-qizhen-lake.content.json#L275)
436. 深色观察可先记录纸条倒影，但不限制捞竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:275](../src/data/chapter3-qizhen-lake.content.json#L275)
437. 把假纸条装上钓鱼竿作饵
   来源：[src/data/chapter3-qizhen-lake.content.json:278](../src/data/chapter3-qizhen-lake.content.json#L278)
438. 把假纸条拖到大湖面的纸条倒影上装饵。
   来源：[src/data/chapter3-qizhen-lake.content.json:279](../src/data/chapter3-qizhen-lake.content.json#L279)
439. 直接对倒影抛竿只会穿过去。
   来源：[src/data/chapter3-qizhen-lake.content.json:279](../src/data/chapter3-qizhen-lake.content.json#L279)
440. 在钥匙倒影处钓起储物柜钥匙
   来源：[src/data/chapter3-qizhen-lake.content.json:282](../src/data/chapter3-qizhen-lake.content.json#L282)
441. 彩色音符碰到白色判定线时按 A 左收线、S 提竿、D 右收线；标有「按住」的音符要保持到水平进度条填满。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
442. 浅色操作时，皮划艇到达金色水纹外圈附近后，把钓鱼竿拖入水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
443. 深色观察可记录钥匙倒影坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
444. 用钥匙打开码头储物柜
   来源：[src/data/chapter3-qizhen-lake.content.json:286](../src/data/chapter3-qizhen-lake.content.json#L286)
445. 带着生锈的柜门钥匙回小码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:287](../src/data/chapter3-qizhen-lake.content.json#L287)
446. 靠近储物柜，把钥匙拖到锁孔。
   来源：[src/data/chapter3-qizhen-lake.content.json:287](../src/data/chapter3-qizhen-lake.content.json#L287)
447. 在旧木桩倒影处钓起破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:290](../src/data/chapter3-qizhen-lake.content.json#L290)
448. 浅色操作时，皮划艇到达金色网框水纹外圈附近后开始节奏钓取。
   来源：[src/data/chapter3-qizhen-lake.content.json:291](../src/data/chapter3-qizhen-lake.content.json#L291)
449. 深色观察可记录网框倒影坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:291](../src/data/chapter3-qizhen-lake.content.json#L291)
450. 组合尼龙绳和破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:294](../src/data/chapter3-qizhen-lake.content.json#L294)
451. 把尼龙绳或破损网框拖进组合位，也可以在道具栏内直接组合。
   来源：[src/data/chapter3-qizhen-lake.content.json:295](../src/data/chapter3-qizhen-lake.content.json#L295)
452. 浮标组合位在大湖面。
   来源：[src/data/chapter3-qizhen-lake.content.json:295](../src/data/chapter3-qizhen-lake.content.json#L295)
453. 用临时抄网捞起密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:298](../src/data/chapter3-qizhen-lake.content.json#L298)
454. 把临时抄网拖到浮排下方的投放框。
   来源：[src/data/chapter3-qizhen-lake.content.json:299](../src/data/chapter3-qizhen-lake.content.json#L299)
455. 从大湖北侧进入浮排直河道。
   来源：[src/data/chapter3-qizhen-lake.content.json:299](../src/data/chapter3-qizhen-lake.content.json#L299)
456. 在浮排硬边撬开密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:302](../src/data/chapter3-qizhen-lake.content.json#L302)
457. 把密封饲料盒拖到浮排硬边开罐位。
   来源：[src/data/chapter3-qizhen-lake.content.json:303](../src/data/chapter3-qizhen-lake.content.json#L303)
458. 密封饲料盒要借浮排硬边撬开。
   来源：[src/data/chapter3-qizhen-lake.content.json:303](../src/data/chapter3-qizhen-lake.content.json#L303)
459. 用鱼饲料颗粒钓一条小鲤鱼
   来源：[src/data/chapter3-qizhen-lake.content.json:306](../src/data/chapter3-qizhen-lake.content.json#L306)
460. 浅色操作时，皮划艇到达金色鱼群水纹外圈附近后，把鱼饲料颗粒拖入水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:307](../src/data/chapter3-qizhen-lake.content.json#L307)
461. 深色观察可记录鱼群水纹坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:307](../src/data/chapter3-qizhen-lake.content.json#L307)
462. 组合磁性扣和钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:310](../src/data/chapter3-qizhen-lake.content.json#L310)
463. 把黑天鹅磁性扣拖到钓鱼竿上，或去船头磁吸组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:311](../src/data/chapter3-qizhen-lake.content.json#L311)
464. 组合位在黑天鹅围栏外的水面。
   来源：[src/data/chapter3-qizhen-lake.content.json:311](../src/data/chapter3-qizhen-lake.content.json#L311)
465. 用磁性钓鱼竿吸住纸条本体
   来源：[src/data/chapter3-qizhen-lake.content.json:314](../src/data/chapter3-qizhen-lake.content.json#L314)
466. 皮划艇到达金色纸条水纹外圈附近后，把磁性钓鱼竿拖入水纹，完成最终八小节节奏钓取。
   来源：[src/data/chapter3-qizhen-lake.content.json:315](../src/data/chapter3-qizhen-lake.content.json#L315)
467. 深色观察可确认纸条坐标；浅色操作可直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:315](../src/data/chapter3-qizhen-lake.content.json#L315)
468. 【记录】启真湖首航：船是捡的，桨是凑的，人是活的
   来源：[src/data/chapter3-qizhen-lake.content.json:321](../src/data/chapter3-qizhen-lake.content.json#L321)
469. 启真湖划船一圈没翻，特此发帖留念
   来源：[src/data/chapter3-qizhen-lake.content.json:322](../src/data/chapter3-qizhen-lake.content.json#L322)
470. 在湖心漂了一下午，风比课表还满
   来源：[src/data/chapter3-qizhen-lake.content.json:323](../src/data/chapter3-qizhen-lake.content.json#L323)
471. 人还在湖上，船还浮着
   来源：[src/data/chapter3-qizhen-lake.content.json:326](../src/data/chapter3-qizhen-lake.content.json#L326)
472. 两条胳膊已报废，但不亏
   来源：[src/data/chapter3-qizhen-lake.content.json:327](../src/data/chapter3-qizhen-lake.content.json#L327)
473. 上岸再整理，先占个楼
   来源：[src/data/chapter3-qizhen-lake.content.json:328](../src/data/chapter3-qizhen-lake.content.json#L328)
474. 出发位打卡。临时装备已经固定，先试着划离码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:332](../src/data/chapter3-qizhen-lake.content.json#L332)
475. 回码头补一张。能完整地划回来，我自己都没想到。
   来源：[src/data/chapter3-qizhen-lake.content.json:333](../src/data/chapter3-qizhen-lake.content.json#L333)
476. 器材架空了一半，这艘皮划艇暂时归我保管。
   来源：[src/data/chapter3-qizhen-lake.content.json:334](../src/data/chapter3-qizhen-lake.content.json#L334)
477. 水面静下来的时候，倒影比实景还清楚，船都不敢动。
   来源：[src/data/chapter3-qizhen-lake.content.json:337](../src/data/chapter3-qizhen-lake.content.json#L337)
478. 刚按快门就来一圈水纹，倒影当场断开，凑合看。
   来源：[src/data/chapter3-qizhen-lake.content.json:338](../src/data/chapter3-qizhen-lake.content.json#L338)
479. 为了等水静下来，在湖心多漂了十分钟，值。
   来源：[src/data/chapter3-qizhen-lake.content.json:339](../src/data/chapter3-qizhen-lake.content.json#L339)
480. 黑天鹅隔着围栏盯着我看了很久，没敢再靠近。
   来源：[src/data/chapter3-qizhen-lake.content.json:342](../src/data/chapter3-qizhen-lake.content.json#L342)
481. 按下快门那一下它正好转头，气场很足。
   来源：[src/data/chapter3-qizhen-lake.content.json:343](../src/data/chapter3-qizhen-lake.content.json#L343)
482. 围栏空了，水面只剩一圈还没散的水痕。
   来源：[src/data/chapter3-qizhen-lake.content.json:344](../src/data/chapter3-qizhen-lake.content.json#L344)
483. 构图在线
   来源：[src/data/chapter3-qizhen-lake.content.json:348](../src/data/chapter3-qizhen-lake.content.json#L348)
484. 拍歪了
   来源：[src/data/chapter3-qizhen-lake.content.json:349](../src/data/chapter3-qizhen-lake.content.json#L349)
485. 速度太快
   来源：[src/data/chapter3-qizhen-lake.content.json:350](../src/data/chapter3-qizhen-lake.content.json#L350)
486. 水纹清楚
   来源：[src/data/chapter3-qizhen-lake.content.json:351](../src/data/chapter3-qizhen-lake.content.json#L351)
487. 水纹断了
   来源：[src/data/chapter3-qizhen-lake.content.json:352](../src/data/chapter3-qizhen-lake.content.json#L352)
488. 黑天鹅贴脸
   来源：[src/data/chapter3-qizhen-lake.content.json:353](../src/data/chapter3-qizhen-lake.content.json#L353)
489. 黑天鹅在远处
   来源：[src/data/chapter3-qizhen-lake.content.json:354](../src/data/chapter3-qizhen-lake.content.json#L354)
490. 鹅去栏空
   来源：[src/data/chapter3-qizhen-lake.content.json:355](../src/data/chapter3-qizhen-lake.content.json#L355)
491. 湖心
   来源：[src/data/chapter3-qizhen-lake.content.json:358](../src/data/chapter3-qizhen-lake.content.json#L358)；[src/scenes/rpg/QizhenLakeModel.ts:460](../src/scenes/rpg/QizhenLakeModel.ts#L460)
492. 湖心倒影
   来源：[src/data/chapter3-qizhen-lake.content.json:360](../src/data/chapter3-qizhen-lake.content.json#L360)
493. 启真湖记录相机
   来源：[src/data/chapter3-qizhen-lake.content.json:364](../src/data/chapter3-qizhen-lake.content.json#L364)
494. 拍摄
   来源：[src/data/chapter3-qizhen-lake.content.json:365](../src/data/chapter3-qizhen-lake.content.json#L365)；[src/modules/QizhenJournalModel.ts:52](../src/modules/QizhenJournalModel.ts#L52)
495. 收起相机
   来源：[src/data/chapter3-qizhen-lake.content.json:366](../src/data/chapter3-qizhen-lake.content.json#L366)；[src/modules/QizhenJournalModel.ts:53](../src/modules/QizhenJournalModel.ts#L53)
496. 重拍
   来源：[src/data/chapter3-qizhen-lake.content.json:367](../src/data/chapter3-qizhen-lake.content.json#L367)；[src/modules/QizhenJournalModel.ts:54](../src/modules/QizhenJournalModel.ts#L54)
497. 选择主帖标题
   来源：[src/data/chapter3-qizhen-lake.content.json:368](../src/data/chapter3-qizhen-lake.content.json#L368)；[src/modules/QizhenJournalModel.ts:55](../src/modules/QizhenJournalModel.ts#L55)
498. 选择主帖状态
   来源：[src/data/chapter3-qizhen-lake.content.json:369](../src/data/chapter3-qizhen-lake.content.json#L369)；[src/modules/QizhenJournalModel.ts:56](../src/modules/QizhenJournalModel.ts#L56)
499. 选择补拍说明
   来源：[src/data/chapter3-qizhen-lake.content.json:370](../src/data/chapter3-qizhen-lake.content.json#L370)；[src/modules/QizhenJournalModel.ts:57](../src/modules/QizhenJournalModel.ts#L57)
500. 存为草稿
   来源：[src/data/chapter3-qizhen-lake.content.json:371](../src/data/chapter3-qizhen-lake.content.json#L371)；[src/modules/QizhenJournalModel.ts:58](../src/modules/QizhenJournalModel.ts#L58)
501. 草稿已保存,可前往 CC98 发布。
   来源：[src/data/chapter3-qizhen-lake.content.json:372](../src/data/chapter3-qizhen-lake.content.json#L372)；[src/modules/QizhenJournalModel.ts:59](../src/modules/QizhenJournalModel.ts#L59)
502. 速度
   来源：[src/data/chapter3-qizhen-lake.content.json:373](../src/data/chapter3-qizhen-lake.content.json#L373)；[src/modules/QizhenJournalModel.ts:60](../src/modules/QizhenJournalModel.ts#L60)
503. 船速和侧倾都会写进照片标签。想拍干净点，先把船稳下来再按快门。
   来源：[src/data/chapter3-qizhen-lake.content.json:375](../src/data/chapter3-qizhen-lake.content.json#L375)
504. 校园生活
   来源：[src/data/chapter3-qizhen-lake.content.json:378](../src/data/chapter3-qizhen-lake.content.json#L378)；[src/data/chapter3-theater.content.json:22](../src/data/chapter3-theater.content.json#L22)
505. 楼主
   来源：[src/data/chapter3-qizhen-lake.content.json:379](../src/data/chapter3-qizhen-lake.content.json#L379)；[src/modules/QizhenJournalModel.ts:81](../src/modules/QizhenJournalModel.ts#L81)
506. 草稿
   来源：[src/data/chapter3-qizhen-lake.content.json:380](../src/data/chapter3-qizhen-lake.content.json#L380)；[src/modules/QizhenJournalModel.ts:82](../src/modules/QizhenJournalModel.ts#L82)
507. 发布主帖
   来源：[src/data/chapter3-qizhen-lake.content.json:381](../src/data/chapter3-qizhen-lake.content.json#L381)；[src/modules/QizhenJournalModel.ts:83](../src/modules/QizhenJournalModel.ts#L83)
508. 发布中…
   来源：[src/data/chapter3-qizhen-lake.content.json:382](../src/data/chapter3-qizhen-lake.content.json#L382)；[src/modules/QizhenJournalModel.ts:84](../src/modules/QizhenJournalModel.ts#L84)
509. 追加到帖子
   来源：[src/data/chapter3-qizhen-lake.content.json:383](../src/data/chapter3-qizhen-lake.content.json#L383)；[src/modules/QizhenJournalModel.ts:85](../src/modules/QizhenJournalModel.ts#L85)
510. 只看楼主
   来源：[src/data/chapter3-qizhen-lake.content.json:384](../src/data/chapter3-qizhen-lake.content.json#L384)；[src/modules/QizhenJournalModel.ts:86](../src/modules/QizhenJournalModel.ts#L86)
511. 查看全部
   来源：[src/data/chapter3-qizhen-lake.content.json:385](../src/data/chapter3-qizhen-lake.content.json#L385)；[src/modules/QizhenJournalModel.ts:87](../src/modules/QizhenJournalModel.ts#L87)
512. 继续补充
   来源：[src/data/chapter3-qizhen-lake.content.json:386](../src/data/chapter3-qizhen-lake.content.json#L386)；[src/modules/QizhenJournalModel.ts:88](../src/modules/QizhenJournalModel.ts#L88)
513. 返回湖面
   来源：[src/data/chapter3-qizhen-lake.content.json:387](../src/data/chapter3-qizhen-lake.content.json#L387)；[src/data/chapter3-qizhen-lake.content.json:395](../src/data/chapter3-qizhen-lake.content.json#L395)；[src/modules/QizhenJournalModel.ts:89](../src/modules/QizhenJournalModel.ts#L89)；[src/modules/QizhenJournalModel.ts:102](../src/modules/QizhenJournalModel.ts#L102)
514. 帖子已归档,仅供查看。
   来源：[src/data/chapter3-qizhen-lake.content.json:388](../src/data/chapter3-qizhen-lake.content.json#L388)；[src/modules/QizhenJournalModel.ts:90](../src/modules/QizhenJournalModel.ts#L90)
515. 湖心主图
   来源：[src/data/chapter3-qizhen-lake.content.json:389](../src/data/chapter3-qizhen-lake.content.json#L389)；[src/modules/QizhenJournalModel.ts:91](../src/modules/QizhenJournalModel.ts#L91)
516. 补拍照片
   来源：[src/data/chapter3-qizhen-lake.content.json:390](../src/data/chapter3-qizhen-lake.content.json#L390)；[src/modules/QizhenJournalModel.ts:92](../src/modules/QizhenJournalModel.ts#L92)
517. 发布失败：不在校园网
   来源：[src/data/chapter3-qizhen-lake.content.json:392](../src/data/chapter3-qizhen-lake.content.json#L392)
518. CC98 仅在校园网（ZJUWLAN）下可以发帖。照片、标题和说明都已保留，网络恢复后请手动重试，不会自动补发。
   来源：[src/data/chapter3-qizhen-lake.content.json:393](../src/data/chapter3-qizhen-lake.content.json#L393)
519. 打开控制中心
   来源：[src/data/chapter3-qizhen-lake.content.json:394](../src/data/chapter3-qizhen-lake.content.json#L394)；[src/modules/QizhenJournalModel.ts:101](../src/modules/QizhenJournalModel.ts#L101)
520. 继续编辑
   来源：[src/data/chapter3-qizhen-lake.content.json:396](../src/data/chapter3-qizhen-lake.content.json#L396)；[src/modules/QizhenJournalModel.ts:103](../src/modules/QizhenJournalModel.ts#L103)
521. bd。楼主发帖时间已记录，比我昨晚的打印队列靠前。
   来源：[src/data/chapter3-qizhen-lake.content.json:401](../src/data/chapter3-qizhen-lake.content.json#L401)
522. 下午路过启真湖看见这艘船了，湖心风不小，照片倒是拍得挺稳。
   来源：[src/data/chapter3-qizhen-lake.content.json:402](../src/data/chapter3-qizhen-lake.content.json#L402)
523. 右边那支桨看着眼熟，像是器材架旁边立了很久的旧牌子。
   来源：[src/data/chapter3-qizhen-lake.content.json:403](../src/data/chapter3-qizhen-lake.content.json#L403)
524. 每天骑车绕湖一圈，头回见有人划这个。先收藏，翻了记得回来更新。
   来源：[src/data/chapter3-qizhen-lake.content.json:404](../src/data/chapter3-qizhen-lake.content.json#L404)
525. 余额 0.06 元，租船押金都付不起，看楼主发帖就当自己划过。
   来源：[src/data/chapter3-qizhen-lake.content.json:405](../src/data/chapter3-qizhen-lake.content.json#L405)
526. 无审核权限，仅存档湖心主图一张。船的来源建议楼主自行补充说明。
   来源：[src/data/chapter3-qizhen-lake.content.json:406](../src/data/chapter3-qizhen-lake.content.json#L406)
527. 这个码头我天天推车经过，器材架今天确实空了一格，原来在你这。
   来源：[src/data/chapter3-qizhen-lake.content.json:409](../src/data/chapter3-qizhen-lake.content.json#L409)
528. 架空位 +1，东西记得还。上次有人借桨借了半个学期。
   来源：[src/data/chapter3-qizhen-lake.content.json:410](../src/data/chapter3-qizhen-lake.content.json#L410)
529. 码头木板数过了，翘起来三块，踩中间那块最稳，不用谢。
   来源：[src/data/chapter3-qizhen-lake.content.json:411](../src/data/chapter3-qizhen-lake.content.json#L411)
530. 出发位与回位经比对为同一码头，行程闭环，予以存档。
   来源：[src/data/chapter3-qizhen-lake.content.json:412](../src/data/chapter3-qizhen-lake.content.json#L412)
531. 这张倒影我在对岸目击过拍摄过程，水面确实静了一阵，就一阵。
   来源：[src/data/chapter3-qizhen-lake.content.json:415](../src/data/chapter3-qizhen-lake.content.json#L415)
532. 等水静下来要多久？我在岸边计时到五分钟就放弃了，楼主有耐心。
   来源：[src/data/chapter3-qizhen-lake.content.json:416](../src/data/chapter3-qizhen-lake.content.json#L416)
533. 湖心倒影，老港人都知道这个机位。下班绕过去看一眼，血压能低点。
   来源：[src/data/chapter3-qizhen-lake.content.json:417](../src/data/chapter3-qizhen-lake.content.json#L417)
534. 倒影中船身与人物比例一致，未发现修图痕迹，通过。
   来源：[src/data/chapter3-qizhen-lake.content.json:418](../src/data/chapter3-qizhen-lake.content.json#L418)
535. 黑天鹅盯人是常规项目，建议不要长时间对视，赢不了。
   来源：[src/data/chapter3-qizhen-lake.content.json:421](../src/data/chapter3-qizhen-lake.content.json#L421)
536. 它转头那下我正好路过，连风都停了半秒，气场确实足。
   来源：[src/data/chapter3-qizhen-lake.content.json:422](../src/data/chapter3-qizhen-lake.content.json#L422)
537. 这鹅一天的伙食费超过我的余额，楼主别跟它比气场，比不过。
   来源：[src/data/chapter3-qizhen-lake.content.json:423](../src/data/chapter3-qizhen-lake.content.json#L423)
538. 空围栏这张亦已存档。水痕未散，后续动向保持观察。
   来源：[src/data/chapter3-qizhen-lake.content.json:424](../src/data/chapter3-qizhen-lake.content.json#L424)
539. system
   来源：[src/data/chapter3-story-lines.json:18](../src/data/chapter3-story-lines.json#L18)；[src/data/chapter3-story-lines.json:27](../src/data/chapter3-story-lines.json#L27)；[src/data/chapter3-story-lines.json:36](../src/data/chapter3-story-lines.json#L36)；[src/data/chapter3-story-lines.json:45](../src/data/chapter3-story-lines.json#L45)；[src/data/chapter3-story-lines.json:54](../src/data/chapter3-story-lines.json#L54)；[src/data/chapter3-story-lines.json:63](../src/data/chapter3-story-lines.json#L63)；[src/data/chapter3-story-lines.json:72](../src/data/chapter3-story-lines.json#L72)；[src/data/chapter3-story-lines.json:81](../src/data/chapter3-story-lines.json#L81)；[src/data/chapter3-story-lines.json:108](../src/data/chapter3-story-lines.json#L108)；[src/data/chapter3-story-lines.json:126](../src/data/chapter3-story-lines.json#L126)；[src/data/chapter3-story-lines.json:135](../src/data/chapter3-story-lines.json#L135)；[src/data/chapter3-story-lines.json:144](../src/data/chapter3-story-lines.json#L144)；[src/data/chapter3-story-lines.json:162](../src/data/chapter3-story-lines.json#L162)；[src/data/chapter3-story-lines.json:171](../src/data/chapter3-story-lines.json#L171)；[src/data/chapter3-story-lines.json:180](../src/data/chapter3-story-lines.json#L180)；[src/data/chapter3-story-lines.json:189](../src/data/chapter3-story-lines.json#L189)；[src/data/chapter3-story-lines.json:198](../src/data/chapter3-story-lines.json#L198)；[src/data/chapter3-story-lines.json:207](../src/data/chapter3-story-lines.json#L207)；[src/data/chapter3-story-lines.json:216](../src/data/chapter3-story-lines.json#L216)；[src/data/chapter3-story-lines.json:225](../src/data/chapter3-story-lines.json#L225)；[src/data/chapter3-story-lines.json:234](../src/data/chapter3-story-lines.json#L234)；[src/data/chapter3-story-lines.json:243](../src/data/chapter3-story-lines.json#L243)；[src/data/chapter3-story-lines.json:252](../src/data/chapter3-story-lines.json#L252)；[src/data/chapter3-story-lines.json:261](../src/data/chapter3-story-lines.json#L261)；[src/data/chapter3-story-lines.json:270](../src/data/chapter3-story-lines.json#L270)；[src/data/chapter3-story-lines.json:279](../src/data/chapter3-story-lines.json#L279)；[src/data/chapter3-story-lines.json:288](../src/data/chapter3-story-lines.json#L288)；[src/data/chapter3-story-lines.json:297](../src/data/chapter3-story-lines.json#L297)；[src/data/chapter3-story-lines.json:306](../src/data/chapter3-story-lines.json#L306)；[src/data/chapter3-story-lines.json:315](../src/data/chapter3-story-lines.json#L315)；[src/data/chapter3-story-lines.json:333](../src/data/chapter3-story-lines.json#L333)；[src/data/chapter3-story-lines.json:342](../src/data/chapter3-story-lines.json#L342)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:67](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L67)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:84](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L84)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:90](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L90)；[src/scenes/rpg/CanteenInteriorScene.ts:1919](../src/scenes/rpg/CanteenInteriorScene.ts#L1919)；[src/scenes/rpg/CanteenInteriorScene.ts:1923](../src/scenes/rpg/CanteenInteriorScene.ts#L1923)；[src/scenes/rpg/CanteenInteriorScene.ts:1955](../src/scenes/rpg/CanteenInteriorScene.ts#L1955)；[src/scenes/rpg/CanteenInteriorScene.ts:1959](../src/scenes/rpg/CanteenInteriorScene.ts#L1959)；[src/scenes/rpg/CanteenInteriorScene.ts:1968](../src/scenes/rpg/CanteenInteriorScene.ts#L1968)；[src/scenes/rpg/CanteenInteriorScene.ts:1977](../src/scenes/rpg/CanteenInteriorScene.ts#L1977)；[src/scenes/rpg/CanteenInteriorScene.ts:1993](../src/scenes/rpg/CanteenInteriorScene.ts#L1993)；[src/scenes/rpg/CanteenInteriorScene.ts:1997](../src/scenes/rpg/CanteenInteriorScene.ts#L1997)；[src/scenes/rpg/CanteenInteriorScene.ts:2011](../src/scenes/rpg/CanteenInteriorScene.ts#L2011)；[src/scenes/rpg/CanteenInteriorScene.ts:2019](../src/scenes/rpg/CanteenInteriorScene.ts#L2019)；[src/scenes/rpg/CanteenInteriorScene.ts:2023](../src/scenes/rpg/CanteenInteriorScene.ts#L2023)；[src/scenes/rpg/CanteenInteriorScene.ts:2027](../src/scenes/rpg/CanteenInteriorScene.ts#L2027)；[src/scenes/rpg/CanteenInteriorScene.ts:2056](../src/scenes/rpg/CanteenInteriorScene.ts#L2056)；[src/scenes/rpg/CanteenInteriorScene.ts:2060](../src/scenes/rpg/CanteenInteriorScene.ts#L2060)；[src/scenes/rpg/CanteenInteriorScene.ts:2211](../src/scenes/rpg/CanteenInteriorScene.ts#L2211)；[src/scenes/rpg/CanteenInteriorScene.ts:3169](../src/scenes/rpg/CanteenInteriorScene.ts#L3169)；[src/scenes/rpg/CanteenInteriorScene.ts:3244](../src/scenes/rpg/CanteenInteriorScene.ts#L3244)；[src/scenes/rpg/CanteenInteriorScene.ts:3614](../src/scenes/rpg/CanteenInteriorScene.ts#L3614)；[src/scenes/rpg/CanteenInteriorScene.ts:3663](../src/scenes/rpg/CanteenInteriorScene.ts#L3663)；[src/scenes/rpg/CanteenInteriorScene.ts:3753](../src/scenes/rpg/CanteenInteriorScene.ts#L3753)；[src/scenes/rpg/QizhenLakeScene.ts:584](../src/scenes/rpg/QizhenLakeScene.ts#L584)；[src/scenes/rpg/QizhenLakeScene.ts:834](../src/scenes/rpg/QizhenLakeScene.ts#L834)；[src/scenes/rpg/QizhenLakeScene.ts:1005](../src/scenes/rpg/QizhenLakeScene.ts#L1005)；[src/scenes/rpg/QizhenLakeScene.ts:1038](../src/scenes/rpg/QizhenLakeScene.ts#L1038)；[src/scenes/rpg/QizhenLakeScene.ts:1853](../src/scenes/rpg/QizhenLakeScene.ts#L1853)；[src/scenes/rpg/QizhenLakeScene.ts:2132](../src/scenes/rpg/QizhenLakeScene.ts#L2132)；[src/scenes/rpg/QizhenLakeScene.ts:2189](../src/scenes/rpg/QizhenLakeScene.ts#L2189)；[src/scenes/rpg/QizhenLakeScene.ts:2293](../src/scenes/rpg/QizhenLakeScene.ts#L2293)；[src/scenes/rpg/QizhenLakeScene.ts:2494](../src/scenes/rpg/QizhenLakeScene.ts#L2494)；[src/scenes/rpg/QizhenLakeScene.ts:2498](../src/scenes/rpg/QizhenLakeScene.ts#L2498)；[src/scenes/rpg/QizhenLakeScene.ts:2516](../src/scenes/rpg/QizhenLakeScene.ts#L2516)；[src/scenes/rpg/QizhenLakeScene.ts:2520](../src/scenes/rpg/QizhenLakeScene.ts#L2520)；[src/scenes/rpg/QizhenLakeScene.ts:2526](../src/scenes/rpg/QizhenLakeScene.ts#L2526)；[src/scenes/rpg/QizhenLakeScene.ts:2540](../src/scenes/rpg/QizhenLakeScene.ts#L2540)；[src/scenes/rpg/QizhenLakeScene.ts:2555](../src/scenes/rpg/QizhenLakeScene.ts#L2555)；[src/scenes/rpg/QizhenLakeScene.ts:2614](../src/scenes/rpg/QizhenLakeScene.ts#L2614)；[src/scenes/rpg/QizhenLakeScene.ts:2939](../src/scenes/rpg/QizhenLakeScene.ts#L2939)；[src/scenes/rpg/QizhenLakeScene.ts:2945](../src/scenes/rpg/QizhenLakeScene.ts#L2945)；[src/scenes/rpg/QizhenLakeScene.ts:2949](../src/scenes/rpg/QizhenLakeScene.ts#L2949)；[src/scenes/rpg/QizhenLakeScene.ts:2953](../src/scenes/rpg/QizhenLakeScene.ts#L2953)；[src/scenes/rpg/QizhenLakeScene.ts:2957](../src/scenes/rpg/QizhenLakeScene.ts#L2957)；[src/scenes/rpg/QizhenLakeScene.ts:2967](../src/scenes/rpg/QizhenLakeScene.ts#L2967)；[src/scenes/rpg/QizhenLakeScene.ts:3479](../src/scenes/rpg/QizhenLakeScene.ts#L3479)；[src/scenes/rpg/TheaterInteriorScene.ts:991](../src/scenes/rpg/TheaterInteriorScene.ts#L991)；[src/scenes/rpg/TheaterInteriorScene.ts:999](../src/scenes/rpg/TheaterInteriorScene.ts#L999)；[src/scenes/rpg/TheaterInteriorScene.ts:1003](../src/scenes/rpg/TheaterInteriorScene.ts#L1003)；[src/scenes/rpg/TheaterInteriorScene.ts:1008](../src/scenes/rpg/TheaterInteriorScene.ts#L1008)；[src/scenes/rpg/TheaterInteriorScene.ts:1041](../src/scenes/rpg/TheaterInteriorScene.ts#L1041)；[src/scenes/rpg/TheaterInteriorScene.ts:1062](../src/scenes/rpg/TheaterInteriorScene.ts#L1062)；[src/scenes/rpg/TheaterInteriorScene.ts:1164](../src/scenes/rpg/TheaterInteriorScene.ts#L1164)；[src/scenes/rpg/TheaterInteriorScene.ts:1203](../src/scenes/rpg/TheaterInteriorScene.ts#L1203)；[src/scenes/rpg/TheaterInteriorScene.ts:1212](../src/scenes/rpg/TheaterInteriorScene.ts#L1212)；[src/scenes/rpg/TheaterInteriorScene.ts:1258](../src/scenes/rpg/TheaterInteriorScene.ts#L1258)；[src/scenes/rpg/TheaterInteriorScene.ts:1264](../src/scenes/rpg/TheaterInteriorScene.ts#L1264)；[src/scenes/rpg/TheaterInteriorScene.ts:1681](../src/scenes/rpg/TheaterInteriorScene.ts#L1681)
540. 系统：它可能只是来体验一下排队，很多东西在食堂都会排队。
   来源：[src/data/chapter3-story-lines.json:20](../src/data/chapter3-story-lines.json#L20)
541. Maybe it only came to experience the queue. Many things end up queuing in a cafeteria.
   来源：[src/data/chapter3-story-lines.json:21](../src/data/chapter3-story-lines.json#L21)
542. 系统：因为你现在需要钱，而它们需要劳动力。
   来源：[src/data/chapter3-story-lines.json:29](../src/data/chapter3-story-lines.json#L29)
543. Because you need money, and they need labor.
   来源：[src/data/chapter3-story-lines.json:30](../src/data/chapter3-story-lines.json#L30)
544. 系统：它看起来不像纸条会吃的东西，虽然纸条也不该吃东西。
   来源：[src/data/chapter3-story-lines.json:38](../src/data/chapter3-story-lines.json#L38)
545. That does not look like something a paper slip would eat. Admittedly, paper should not eat at all.
   来源：[src/data/chapter3-story-lines.json:39](../src/data/chapter3-story-lines.json#L39)
546. 系统：不是，是一份比较真实的早饭。
   来源：[src/data/chapter3-story-lines.json:47](../src/data/chapter3-story-lines.json#L47)
547. No. It is merely a disappointingly real breakfast.
   来源：[src/data/chapter3-story-lines.json:48](../src/data/chapter3-story-lines.json#L48)
548. 系统：纸包鸡。我知道的至少前两个字很有嫌疑。
   来源：[src/data/chapter3-story-lines.json:56](../src/data/chapter3-story-lines.json#L56)
549. Paper-wrapped chicken. At least the first word is suspicious.
   来源：[src/data/chapter3-story-lines.json:57](../src/data/chapter3-story-lines.json#L57)
550. 系统：一份线索。鸡只是包装。
   来源：[src/data/chapter3-story-lines.json:65](../src/data/chapter3-story-lines.json#L65)
551. One clue. The chicken is only packaging.
   来源：[src/data/chapter3-story-lines.json:66](../src/data/chapter3-story-lines.json#L66)
552. 系统：这份粥很热，但线索很冷。
   来源：[src/data/chapter3-story-lines.json:74](../src/data/chapter3-story-lines.json#L74)
553. The congee is hot. The clue is cold.
   来源：[src/data/chapter3-story-lines.json:75](../src/data/chapter3-story-lines.json#L75)
554. 系统：请不要拓展世界观。
   来源：[src/data/chapter3-story-lines.json:83](../src/data/chapter3-story-lines.json#L83)
555. Please do not expand the worldbuilding.
   来源：[src/data/chapter3-story-lines.json:84](../src/data/chapter3-story-lines.json#L84)
556. narrator
   来源：[src/data/chapter3-story-lines.json:90](../src/data/chapter3-story-lines.json#L90)；[src/data/chapter3-story-lines.json:99](../src/data/chapter3-story-lines.json#L99)；[src/data/chapter3-story-lines.json:117](../src/data/chapter3-story-lines.json#L117)；[src/data/chapter3-story-lines.json:153](../src/data/chapter3-story-lines.json#L153)；[src/data/chapter3-story-lines.json:324](../src/data/chapter3-story-lines.json#L324)；[src/scenes/rpg/CanteenInteriorScene.ts:1927](../src/scenes/rpg/CanteenInteriorScene.ts#L1927)；[src/scenes/rpg/QizhenLakeScene.ts:948](../src/scenes/rpg/QizhenLakeScene.ts#L948)；[src/scenes/rpg/QizhenLakeScene.ts:952](../src/scenes/rpg/QizhenLakeScene.ts#L952)；[src/scenes/rpg/QizhenLakeScene.ts:1069](../src/scenes/rpg/QizhenLakeScene.ts#L1069)；[src/scenes/rpg/QizhenLakeScene.ts:2535](../src/scenes/rpg/QizhenLakeScene.ts#L2535)；[src/scenes/rpg/QizhenLakeScene.ts:3383](../src/scenes/rpg/QizhenLakeScene.ts#L3383)；[src/scenes/rpg/QizhenLakeScene.ts:3412](../src/scenes/rpg/QizhenLakeScene.ts#L3412)；[src/scenes/rpg/TheaterInteriorScene.ts:1172](../src/scenes/rpg/TheaterInteriorScene.ts#L1172)
557. 纸条撞回食堂，掉下一点蓝光。
   来源：[src/data/chapter3-story-lines.json:92](../src/data/chapter3-story-lines.json#L92)
558. The paper crashes back into the cafeteria and sheds a flicker of blue light.
   来源：[src/data/chapter3-story-lines.json:93](../src/data/chapter3-story-lines.json#L93)
559. 纸条急了，它开始不尊重取餐流程。
   来源：[src/data/chapter3-story-lines.json:101](../src/data/chapter3-story-lines.json#L101)
560. The paper is getting desperate. It has stopped respecting the pickup procedure.
   来源：[src/data/chapter3-story-lines.json:102](../src/data/chapter3-story-lines.json#L102)
561. 系统：自助服务发展到这一步，我有点害怕。
   来源：[src/data/chapter3-story-lines.json:110](../src/data/chapter3-story-lines.json#L110)
562. Self-service has advanced too far. I am mildly concerned.
   来源：[src/data/chapter3-story-lines.json:111](../src/data/chapter3-story-lines.json#L111)
563. The paper flees along the main road.
   来源：[src/data/chapter3-story-lines.json:120](../src/data/chapter3-story-lines.json#L120)
564. 系统：你正在以“没吃早饭的人类速度”移动。
   来源：[src/data/chapter3-story-lines.json:128](../src/data/chapter3-story-lines.json#L128)
565. You are moving at the speed of a human who skipped breakfast.
   来源：[src/data/chapter3-story-lines.json:129](../src/data/chapter3-story-lines.json#L129)
566. 系统：它没有绩点负担。
   来源：[src/data/chapter3-story-lines.json:137](../src/data/chapter3-story-lines.json#L137)
567. It carries no grade-point burden.
   来源：[src/data/chapter3-story-lines.json:138](../src/data/chapter3-story-lines.json#L138)
568. 系统：这句话在本游戏里出现频率太高了。
   来源：[src/data/chapter3-story-lines.json:146](../src/data/chapter3-story-lines.json#L146)
569. That sentence occurs far too often in this game.
   来源：[src/data/chapter3-story-lines.json:147](../src/data/chapter3-story-lines.json#L147)
570. 旁白：失败得很慷慨。
   来源：[src/data/chapter3-story-lines.json:155](../src/data/chapter3-story-lines.json#L155)
571. A remarkably generous failure.
   来源：[src/data/chapter3-story-lines.json:156](../src/data/chapter3-story-lines.json#L156)
572. 系统：这场演出本来也没什么逻辑。
   来源：[src/data/chapter3-story-lines.json:164](../src/data/chapter3-story-lines.json#L164)；[src/data/chapter3-theater.content.json:110](../src/data/chapter3-theater.content.json#L110)
573. This performance never had much logic to begin with.
   来源：[src/data/chapter3-story-lines.json:165](../src/data/chapter3-story-lines.json#L165)
574. 系统：whooooo！
   来源：[src/data/chapter3-story-lines.json:173](../src/data/chapter3-story-lines.json#L173)；[src/data/chapter3-theater.content.json:153](../src/data/chapter3-theater.content.json#L153)
575. Whooooo!
   来源：[src/data/chapter3-story-lines.json:174](../src/data/chapter3-story-lines.json#L174)
576. 系统：哦，可能纸类之间有一些我们不懂的关系。
   来源：[src/data/chapter3-story-lines.json:182](../src/data/chapter3-story-lines.json#L182)；[src/data/chapter3-theater.content.json:156](../src/data/chapter3-theater.content.json#L156)
577. Perhaps paper has relationships we do not understand.
   来源：[src/data/chapter3-story-lines.json:183](../src/data/chapter3-story-lines.json#L183)
578. 系统：不知道。它这次没有沿路掉纸屑。
   来源：[src/data/chapter3-story-lines.json:191](../src/data/chapter3-story-lines.json#L191)
579. No idea. This time it left no paper scraps along the road.
   来源：[src/data/chapter3-story-lines.json:192](../src/data/chapter3-story-lines.json#L192)
580. 系统：老办法，发个论坛问问。
   来源：[src/data/chapter3-story-lines.json:200](../src/data/chapter3-story-lines.json#L200)
581. Use the old method. Ask the campus forum.
   来源：[src/data/chapter3-story-lines.json:201](../src/data/chapter3-story-lines.json#L201)
582. 系统：CC98 提供了一个非常精确的范围：不是厕所。
   来源：[src/data/chapter3-story-lines.json:209](../src/data/chapter3-story-lines.json#L209)
583. CC98 has provided a highly precise range: not the restroom.
   来源：[src/data/chapter3-story-lines.json:210](../src/data/chapter3-story-lines.json#L210)
584. 系统：意思是它现在比我们更艺术。
   来源：[src/data/chapter3-story-lines.json:218](../src/data/chapter3-story-lines.json#L218)
585. It means the paper is currently more artistic than we are.
   来源：[src/data/chapter3-story-lines.json:219](../src/data/chapter3-story-lines.json#L219)
586. 系统：恭喜，你完成了一次校园级猜谜。
   来源：[src/data/chapter3-story-lines.json:227](../src/data/chapter3-story-lines.json#L227)
587. Congratulations. You have completed a campus-scale guessing game.
   来源：[src/data/chapter3-story-lines.json:228](../src/data/chapter3-story-lines.json#L228)
588. 系统：准确来说，是在倒影里。
   来源：[src/data/chapter3-story-lines.json:236](../src/data/chapter3-story-lines.json#L236)
589. More precisely, it is inside the reflection.
   来源：[src/data/chapter3-story-lines.json:237](../src/data/chapter3-story-lines.json#L237)
590. 系统：对不会游泳的人来说区别很大。
   来源：[src/data/chapter3-story-lines.json:245](../src/data/chapter3-story-lines.json#L245)
591. For someone who cannot swim, the difference is substantial.
   来源：[src/data/chapter3-story-lines.json:246](../src/data/chapter3-story-lines.json#L246)
592. 系统：它又消失了。
   来源：[src/data/chapter3-story-lines.json:254](../src/data/chapter3-story-lines.json#L254)
593. It disappeared again.
   来源：[src/data/chapter3-story-lines.json:255](../src/data/chapter3-story-lines.json#L255)
594. 系统：通常这里不应该有给我们指指路的牌子吗？
   来源：[src/data/chapter3-story-lines.json:263](../src/data/chapter3-story-lines.json#L263)
595. Should there not be a sign around here to point us somewhere?
   来源：[src/data/chapter3-story-lines.json:264](../src/data/chapter3-story-lines.json#L264)
596. 系统：这就是它躲藏的地方，哈
   来源：[src/data/chapter3-story-lines.json:272](../src/data/chapter3-story-lines.json#L272)
597. So this is where it is hiding. Hah.
   来源：[src/data/chapter3-story-lines.json:273](../src/data/chapter3-story-lines.json#L273)
598. 系统：把它挂到哪里去，让大家看看！
   来源：[src/data/chapter3-story-lines.json:281](../src/data/chapter3-story-lines.json#L281)
599. Hang it somewhere public. Let everyone see it.
   来源：[src/data/chapter3-story-lines.json:282](../src/data/chapter3-story-lines.json#L282)
600. 系统：就是这个假的
   来源：[src/data/chapter3-story-lines.json:290](../src/data/chapter3-story-lines.json#L290)
601. Use the fake one.
   来源：[src/data/chapter3-story-lines.json:291](../src/data/chapter3-story-lines.json#L291)
602. 系统：因为它不能接受别人替它逃跑。
   来源：[src/data/chapter3-story-lines.json:299](../src/data/chapter3-story-lines.json#L299)
603. Because it cannot tolerate someone else escaping in its place.
   来源：[src/data/chapter3-story-lines.json:300](../src/data/chapter3-story-lines.json#L300)
604. 系统：你只是让湖更有氛围了。
   来源：[src/data/chapter3-story-lines.json:308](../src/data/chapter3-story-lines.json#L308)
605. You have only made the lake more atmospheric.
   来源：[src/data/chapter3-story-lines.json:309](../src/data/chapter3-story-lines.json#L309)
606. 系统：还在嘲笑你的倒影。
   来源：[src/data/chapter3-story-lines.json:317](../src/data/chapter3-story-lines.json#L317)
607. It is still mocking your reflection.
   来源：[src/data/chapter3-story-lines.json:318](../src/data/chapter3-story-lines.json#L318)
608. 纸条从湖面倒影弹出来，贴着地面飞。
   来源：[src/data/chapter3-story-lines.json:326](../src/data/chapter3-story-lines.json#L326)
609. The paper springs out of the lake reflection and skims along the ground.
   来源：[src/data/chapter3-story-lines.json:327](../src/data/chapter3-story-lines.json#L327)
610. 系统：现在！它回到浅色模式了！
   来源：[src/data/chapter3-story-lines.json:335](../src/data/chapter3-story-lines.json#L335)
611. Now! It is back in the light layer!
   来源：[src/data/chapter3-story-lines.json:336](../src/data/chapter3-story-lines.json#L336)
612. 系统：能抓了！
   来源：[src/data/chapter3-story-lines.json:344](../src/data/chapter3-story-lines.json#L344)
613. You can catch it now!
   来源：[src/data/chapter3-story-lines.json:345](../src/data/chapter3-story-lines.json#L345)
614. 剧院
   来源：[src/data/chapter3-theater.content.json:3](../src/data/chapter3-theater.content.json#L3)
615. 进入剧院
   来源：[src/data/chapter3-theater.content.json:5](../src/data/chapter3-theater.content.json#L5)
616. 深色模式会显示被隐藏的票务信息。
   来源：[src/data/chapter3-theater.content.json:7](../src/data/chapter3-theater.content.json#L7)
617. 浅色模式可以处理现实中的玻璃、机器和票根。
   来源：[src/data/chapter3-theater.content.json:8](../src/data/chapter3-theater.content.json#L8)
618. 检票员：请出示票。
   来源：[src/data/chapter3-theater.content.json:12](../src/data/chapter3-theater.content.json#L12)
619. 玩家：我在追一张纸，让我进去。
   来源：[src/data/chapter3-theater.content.json:13](../src/data/chapter3-theater.content.json#L13)
620. 检票员：纸有票吗？
   来源：[src/data/chapter3-theater.content.json:14](../src/data/chapter3-theater.content.json#L14)
621. 玩家：它从门缝进去的。
   来源：[src/data/chapter3-theater.content.json:15](../src/data/chapter3-theater.content.json#L15)
622. 检票员：那它脸皮至少比你薄。
   来源：[src/data/chapter3-theater.content.json:16](../src/data/chapter3-theater.content.json#L16)
623. 紫金港学生剧社
   来源：[src/data/chapter3-theater.content.json:20](../src/data/chapter3-theater.content.json#L20)；[src/data/chapter3-theater.content.json:41](../src/data/chapter3-theater.content.json#L41)
624. 【求助】学生剧《7:55》临时退票，求现场帮抢
   来源：[src/data/chapter3-theater.content.json:23](../src/data/chapter3-theater.content.json#L23)
625. 刚刚
   来源：[src/data/chapter3-theater.content.json:26](../src/data/chapter3-theater.content.json#L26)
626. 学生剧《7:55》今晚在紫金港校区剧场演出。原票主临时无法到场，剧社受托把一张现场测试票放回手机票务。请确认能够按时入场再接单，具体取票规则见下方票务卡。
   来源：[src/data/chapter3-theater.content.json:27](../src/data/chapter3-theater.content.json#L27)
627. 紫金港学生剧社 · 2026 秋季原创作品
   来源：[src/data/chapter3-theater.content.json:29](../src/data/chapter3-theater.content.json#L29)
628. 学生剧《7:55》
   来源：[src/data/chapter3-theater.content.json:30](../src/data/chapter3-theater.content.json#L30)
629. 所有钟表停在同一分钟，记忆仍在继续。
   来源：[src/data/chapter3-theater.content.json:31](../src/data/chapter3-theater.content.json#L31)
630. 学生剧《7:55》像素海报：深蓝幕布、指向七点五十五分的时钟、聚光灯下的节目单和票根
   来源：[src/data/chapter3-theater.content.json:32](../src/data/chapter3-theater.content.json#L32)
631. 散场广播响起后，一名迟到的学生仍在寻找自己的座位。他穿过三次散场、两条相同的走廊，以及一场反复重来的谢幕。舞台记录着同一个时间，观众保留着不同版本的昨晚。
   来源：[src/data/chapter3-theater.content.json:33](../src/data/chapter3-theater.content.json#L33)
632. 本周五 19:30
   来源：[src/data/chapter3-theater.content.json:35](../src/data/chapter3-theater.content.json#L35)
633. 演出时间
   来源：[src/data/chapter3-theater.content.json:35](../src/data/chapter3-theater.content.json#L35)
634. 开始入场
   来源：[src/data/chapter3-theater.content.json:36](../src/data/chapter3-theater.content.json#L36)
635. 演出地点
   来源：[src/data/chapter3-theater.content.json:37](../src/data/chapter3-theater.content.json#L37)
636. 紫金港校区剧场
   来源：[src/data/chapter3-theater.content.json:37](../src/data/chapter3-theater.content.json#L37)
637. 75 分钟 · 无中场休息
   来源：[src/data/chapter3-theater.content.json:38](../src/data/chapter3-theater.content.json#L38)
638. 演出时长
   来源：[src/data/chapter3-theater.content.json:38](../src/data/chapter3-theater.content.json#L38)
639. 出品
   来源：[src/data/chapter3-theater.content.json:41](../src/data/chapter3-theater.content.json#L41)
640. 文本
   来源：[src/data/chapter3-theater.content.json:42](../src/data/chapter3-theater.content.json#L42)
641. 学生剧社原创组
   来源：[src/data/chapter3-theater.content.json:42](../src/data/chapter3-theater.content.json#L42)
642. 舞台
   来源：[src/data/chapter3-theater.content.json:43](../src/data/chapter3-theater.content.json#L43)
643. 学生剧社舞台组
   来源：[src/data/chapter3-theater.content.json:43](../src/data/chapter3-theater.content.json#L43)
644. 灯光与声音
   来源：[src/data/chapter3-theater.content.json:44](../src/data/chapter3-theater.content.json#L44)
645. 剧场技术组
   来源：[src/data/chapter3-theater.content.json:44](../src/data/chapter3-theater.content.json#L44)
646. 演出含短时黑场、频闪与广播音效；有需要的观众可在前台领取提示单。
   来源：[src/data/chapter3-theater.content.json:47](../src/data/chapter3-theater.content.json#L47)
647. 19:30 后关闭正门，迟到观众将在序场结束后由工作人员引导入场。
   来源：[src/data/chapter3-theater.content.json:48](../src/data/chapter3-theater.content.json#L48)
648. 演出过程中请勿摄影或录音；谢幕结束后开放十分钟演后谈。
   来源：[src/data/chapter3-theater.content.json:49](../src/data/chapter3-theater.content.json#L49)
649. 查看完整演出档案
   来源：[src/data/chapter3-theater.content.json:51](../src/data/chapter3-theater.content.json#L51)
650. 收起演出档案
   来源：[src/data/chapter3-theater.content.json:52](../src/data/chapter3-theater.content.json#L52)
651. 大厅取票机的普通界面不显示放票时间，深色观察里应该还留着一组四位数字，可以作为放票时间的补充确认。
   来源：[src/data/chapter3-theater.content.json:54](../src/data/chapter3-theater.content.json#L54)
652. 接下现场帮抢
   来源：[src/data/chapter3-theater.content.json:55](../src/data/chapter3-theater.content.json#L55)
653. 委托待接：前往剧场前台也无法直接取票，需要先在这里接单。
   来源：[src/data/chapter3-theater.content.json:56](../src/data/chapter3-theater.content.json#L56)
654. 第一波可直接提交；大厅深色残留可补充确认 08:32。
   来源：[src/data/chapter3-theater.content.json:57](../src/data/chapter3-theater.content.json#L57)
655. 第一波将在本手机页面提交；大厅残留记录与网络切换可按任意顺序处理。
   来源：[src/data/chapter3-theater.content.json:58](../src/data/chapter3-theater.content.json#L58)
656. 第一波已结束：系统判定响应速度过慢。
   来源：[src/data/chapter3-theater.content.json:59](../src/data/chapter3-theater.content.json#L59)
657. 第一波请求已结束，手机票务页正在等待第二波：
   来源：[src/data/chapter3-theater.content.json:60](../src/data/chapter3-theater.content.json#L60)
658. 移动数据已开启，第二波已可在本手机页面提交。
   来源：[src/data/chapter3-theater.content.json:61](../src/data/chapter3-theater.content.json#L61)
659. 第二波仅接受移动数据。打开手机控制中心切换网络后再提交。
   来源：[src/data/chapter3-theater.content.json:62](../src/data/chapter3-theater.content.json#L62)
660. 第一波抢票成功。你的运气很好，但是钱包就没那么好了。
   来源：[src/data/chapter3-theater.content.json:63](../src/data/chapter3-theater.content.json#L63)
661. 第二波抢票成功。手机已收到 0832 取票码。
   来源：[src/data/chapter3-theater.content.json:64](../src/data/chapter3-theater.content.json#L64)
662. 第二波抢票成功，取票码 0832 已写入手机回执。
   来源：[src/data/chapter3-theater.content.json:65](../src/data/chapter3-theater.content.json#L65)
663. 你的运气很好，但是钱包就没那么好了。
   来源：[src/data/chapter3-theater.content.json:66](../src/data/chapter3-theater.content.json#L66)
664. 手机票务 H5
   来源：[src/data/chapter3-theater.content.json:67](../src/data/chapter3-theater.content.json#L67)
665. 校园网
   来源：[src/data/chapter3-theater.content.json:68](../src/data/chapter3-theater.content.json#L68)
666. 移动数据
   来源：[src/data/chapter3-theater.content.json:69](../src/data/chapter3-theater.content.json#L69)
667. 无网络
   来源：[src/data/chapter3-theater.content.json:70](../src/data/chapter3-theater.content.json#L70)
668. 参加第一波抢票
   来源：[src/data/chapter3-theater.content.json:71](../src/data/chapter3-theater.content.json#L71)；[src/data/chapter3-theater.content.json:73](../src/data/chapter3-theater.content.json#L73)
669. 参加第二波抢票
   来源：[src/data/chapter3-theater.content.json:72](../src/data/chapter3-theater.content.json#L72)
670. 打开控制中心切换网络
   来源：[src/data/chapter3-theater.content.json:74](../src/data/chapter3-theater.content.json#L74)
671. 需要移动数据
   来源：[src/data/chapter3-theater.content.json:75](../src/data/chapter3-theater.content.json#L75)
672. 第二波倒计时
   来源：[src/data/chapter3-theater.content.json:76](../src/data/chapter3-theater.content.json#L76)
673. 第二波已开放
   来源：[src/data/chapter3-theater.content.json:77](../src/data/chapter3-theater.content.json#L77)
674. 剧场取票码
   来源：[src/data/chapter3-theater.content.json:78](../src/data/chapter3-theater.content.json#L78)
675. 去剧场大厅，在自助取票机输入 0832，打印半张票根 B。
   来源：[src/data/chapter3-theater.content.json:79](../src/data/chapter3-theater.content.json#L79)
676. 我已经在大厅，接下这次帮抢。
   来源：[src/data/chapter3-theater.content.json:80](../src/data/chapter3-theater.content.json#L80)
677. 系统提示：第一波请求响应超时。第二波开始前请切换到移动数据。
   来源：[src/data/chapter3-theater.content.json:81](../src/data/chapter3-theater.content.json#L81)
678. 手机票务回执：第一波抢票成功。你的运气很好，但是钱包就没那么好了。取票码 0832。
   来源：[src/data/chapter3-theater.content.json:82](../src/data/chapter3-theater.content.json#L82)
679. 手机票务回执：第二波抢票成功，取票码 0832 已生成。请到大厅取票机打印票根。
   来源：[src/data/chapter3-theater.content.json:83](../src/data/chapter3-theater.content.json#L83)
680. 检票员：没有票不能进。
   来源：[src/data/chapter3-theater.content.json:86](../src/data/chapter3-theater.content.json#L86)
681. 玻璃反光严重，你只能看见一个很需要睡觉的人。
   来源：[src/data/chapter3-theater.content.json:87](../src/data/chapter3-theater.content.json#L87)
682. 方法很脏，但有效。海报栏交出了它藏着的半张票。
   来源：[src/data/chapter3-theater.content.json:88](../src/data/chapter3-theater.content.json#L88)
683. 请输入取票码。它坚信你记得自己没买过的票。
   来源：[src/data/chapter3-theater.content.json:89](../src/data/chapter3-theater.content.json#L89)
684. 0832 号，两波释放，当前未取票。
   来源：[src/data/chapter3-theater.content.json:90](../src/data/chapter3-theater.content.json#L90)
685. 取票机：查无此票。你的观演资格仍停留在想象中。
   来源：[src/data/chapter3-theater.content.json:91](../src/data/chapter3-theater.content.json#L91)
686. 取票机：当前没有已确认的代取委托。先在手机 CC98 接单。
   来源：[src/data/chapter3-theater.content.json:92](../src/data/chapter3-theater.content.json#L92)
687. 取票机：手机票务页尚未抢到票。请先回到 CC98 帖子完成放票。
   来源：[src/data/chapter3-theater.content.json:93](../src/data/chapter3-theater.content.json#L93)
688. 取票机：取票码核验通过，半张票根 B 已打印并进入物品栏。
   来源：[src/data/chapter3-theater.content.json:94](../src/data/chapter3-theater.content.json#L94)
689. 检票员：这张票为什么有两种字体？
   来源：[src/data/chapter3-theater.content.json:96](../src/data/chapter3-theater.content.json#L96)
690. 玩家：艺术效果。
   来源：[src/data/chapter3-theater.content.json:97](../src/data/chapter3-theater.content.json#L97)
691. 检票员：好的，剧院接受艺术效果。
   来源：[src/data/chapter3-theater.content.json:98](../src/data/chapter3-theater.content.json#L98)
692. 取得节目单残页，确认节目顺序。
   来源：[src/data/chapter3-theater.content.json:102](../src/data/chapter3-theater.content.json#L102)
693. 灯控台：请输入节目顺序。
   来源：[src/data/chapter3-theater.content.json:103](../src/data/chapter3-theater.content.json#L103)
694. 当前状态：追光灯锁定。
   来源：[src/data/chapter3-theater.content.json:104](../src/data/chapter3-theater.content.json#L104)
695. 普通节目单，看起来很会假装正式。
   来源：[src/data/chapter3-theater.content.json:105](../src/data/chapter3-theater.content.json#L105)
696. 荧光编号藏在三张节目单的简介里。打开道具栏逐张查看。
   来源：[src/data/chapter3-theater.content.json:106](../src/data/chapter3-theater.content.json#L106)
697. 荧光编号还散在三张节目单简介里；深色观察与浅色收集可以任意顺序完成。
   来源：[src/data/chapter3-theater.content.json:107](../src/data/chapter3-theater.content.json#L107)
698. 灯控台：节目逻辑不成立。
   来源：[src/data/chapter3-theater.content.json:109](../src/data/chapter3-theater.content.json#L109)
699. 追光灯解锁。
   来源：[src/data/chapter3-theater.content.json:112](../src/data/chapter3-theater.content.json#L112)
700. 开场
   来源：[src/data/chapter3-theater.content.json:114](../src/data/chapter3-theater.content.json#L114)
701. 追光
   来源：[src/data/chapter3-theater.content.json:115](../src/data/chapter3-theater.content.json#L115)
702. 谢幕
   来源：[src/data/chapter3-theater.content.json:116](../src/data/chapter3-theater.content.json#L116)
703. 让纸条留下能够被追光灯识别的痕迹。
   来源：[src/data/chapter3-theater.content.json:120](../src/data/chapter3-theater.content.json#L120)
704. 锁住了。它看起来非常相信流程。
   来源：[src/data/chapter3-theater.content.json:121](../src/data/chapter3-theater.content.json#L121)
705. 道具箱已经空了，荧光粉刷等着去后台通风口。
   来源：[src/data/chapter3-theater.content.json:122](../src/data/chapter3-theater.content.json#L122)
706. 箱内有荧光粉刷的残影，但你摸不到 7:55 的东西。
   来源：[src/data/chapter3-theater.content.json:123](../src/data/chapter3-theater.content.json#L123)
707. 会谢幕的道具才能出箱。
   来源：[src/data/chapter3-theater.content.json:124](../src/data/chapter3-theater.content.json#L124)
708. 验票口沉默片刻，承认了这张票的艺术性。
   来源：[src/data/chapter3-theater.content.json:125](../src/data/chapter3-theater.content.json#L125)
709. 粉末被风吹上舞台。现在连借口都会发光。
   来源：[src/data/chapter3-theater.content.json:126](../src/data/chapter3-theater.content.json#L126)
710. 观察路径残影或直接试灯，用追光灯连续照中纸条三次。
   来源：[src/data/chapter3-theater.content.json:129](../src/data/chapter3-theater.content.json#L129)
711. 前往观众席右侧灯控台，将追光灯遥控器拖入控制台。
   来源：[src/data/chapter3-theater.content.json:130](../src/data/chapter3-theater.content.json#L130)
712. 把追光灯遥控器拖入灯控台的蓝色投放框。
   来源：[src/data/chapter3-theater.content.json:131](../src/data/chapter3-theater.content.json#L131)
713. 观察纸条的移动路径；深色模式会显示更完整的尾迹。
   来源：[src/data/chapter3-theater.content.json:132](../src/data/chapter3-theater.content.json#L132)
714. 浅色模式：预置追光灯，等纸条进入光圈后持续照射。
   来源：[src/data/chapter3-theater.content.json:133](../src/data/chapter3-theater.content.json#L133)
715. 拖动滑轨或按左右键移动追光灯；按住照射键或空格完成锁定。
   来源：[src/data/chapter3-theater.content.json:134](../src/data/chapter3-theater.content.json#L134)
716. 检查灯位、开启时机和连续照射时间。
   来源：[src/data/chapter3-theater.content.json:135](../src/data/chapter3-theater.content.json#L135)
717. 纸条已离开舞台，本轮没有完成锁定。
   来源：[src/data/chapter3-theater.content.json:136](../src/data/chapter3-theater.content.json#L136)
718. 连续锁定
   来源：[src/data/chapter3-theater.content.json:137](../src/data/chapter3-theater.content.json#L137)
719. 按住照射
   来源：[src/data/chapter3-theater.content.json:138](../src/data/chapter3-theater.content.json#L138)
720. 辅助已开启：残影延长，命中范围扩大。
   来源：[src/data/chapter3-theater.content.json:139](../src/data/chapter3-theater.content.json#L139)
721. 灯位不符。重新观察纸条最后进入的灯区。
   来源：[src/data/chapter3-theater.content.json:141](../src/data/chapter3-theater.content.json#L141)
722. 没有开启追光灯。纸条进入灯区时按住照射。
   来源：[src/data/chapter3-theater.content.json:142](../src/data/chapter3-theater.content.json#L142)
723. 照射开启过早，纸条在进入灯区前改变了路线。
   来源：[src/data/chapter3-theater.content.json:143](../src/data/chapter3-theater.content.json#L143)
724. 照射开启过晚，纸条已经离开灯区。
   来源：[src/data/chapter3-theater.content.json:144](../src/data/chapter3-theater.content.json#L144)
725. 照射中断。需要保持光圈与纸条连续重合。
   来源：[src/data/chapter3-theater.content.json:145](../src/data/chapter3-theater.content.json#L145)
726. 纸条已经离开舞台，本轮重新开始。
   来源：[src/data/chapter3-theater.content.json:146](../src/data/chapter3-theater.content.json#L146)
727. 它避开了追光灯。当前轮次重新开始。
   来源：[src/data/chapter3-theater.content.json:148](../src/data/chapter3-theater.content.json#L148)
728. 追光命中。
   来源：[src/data/chapter3-theater.content.json:149](../src/data/chapter3-theater.content.json#L149)
729. 它把被抓也写进了流程。
   来源：[src/data/chapter3-theater.content.json:150](../src/data/chapter3-theater.content.json#L150)
730. 玩家：抓到了！
   来源：[src/data/chapter3-theater.content.json:152](../src/data/chapter3-theater.content.json#L152)
731. 玩家：......
   来源：[src/data/chapter3-theater.content.json:154](../src/data/chapter3-theater.content.json#L154)
732. 玩家：它还会替身？
   来源：[src/data/chapter3-theater.content.json:155](../src/data/chapter3-theater.content.json#L155)
733. 找出纸条下一站
   来源：[src/data/chapter3-theater.content.json:160](../src/data/chapter3-theater.content.json#L160)
734. 纸条这次没有留下连续脚印。
   来源：[src/data/chapter3-theater.content.json:162](../src/data/chapter3-theater.content.json#L162)
735. 湿掉的节目单可以用于查询不同来源。
   来源：[src/data/chapter3-theater.content.json:163](../src/data/chapter3-theater.content.json#L163)
736. 手机地图需要三条相互独立的地点特征。
   来源：[src/data/chapter3-theater.content.json:164](../src/data/chapter3-theater.content.json#L164)
737. 已切换到深色观察：读取残影与异常痕迹，不搬动实体。
   来源：[src/data/chapter3-theater.content.json:168](../src/data/chapter3-theater.content.json#L168)
738. 已切换到浅色操作：可以拖放道具、清洁玻璃和操作设备。
   来源：[src/data/chapter3-theater.content.json:169](../src/data/chapter3-theater.content.json#L169)
739. 这里暂时没有要处理的事。
   来源：[src/data/chapter3-theater.content.json:172](../src/data/chapter3-theater.content.json#L172)
740. 先走到设备前的可站立位置再操作。
   来源：[src/data/chapter3-theater.content.json:173](../src/data/chapter3-theater.content.json#L173)
741. 先走近一点再操作。
   来源：[src/data/chapter3-theater.content.json:174](../src/data/chapter3-theater.content.json#L174)
742. 任务更新：找齐三张节目单残页，确认节目顺序。
   来源：[src/data/chapter3-theater.content.json:177](../src/data/chapter3-theater.content.json#L177)
743. 任务更新：让纸条留下能被追光灯识别的痕迹。
   来源：[src/data/chapter3-theater.content.json:178](../src/data/chapter3-theater.content.json#L178)
744. 任务更新：把追光灯遥控器拖到观众席右侧灯控台。
   来源：[src/data/chapter3-theater.content.json:179](../src/data/chapter3-theater.content.json#L179)
745. 任务更新：观察残影路径，用追光灯连续照中纸条三次。
   来源：[src/data/chapter3-theater.content.json:180](../src/data/chapter3-theater.content.json#L180)
746. 任务更新：看清纸条真正的去向。
   来源：[src/data/chapter3-theater.content.json:181](../src/data/chapter3-theater.content.json#L181)
747. 任务更新：从剧院出口离开，追查纸条的下一站。
   来源：[src/data/chapter3-theater.content.json:182](../src/data/chapter3-theater.content.json#L182)
748. 022 已恢复
   来源：[src/data/presentation-cues.ts:209](../src/data/presentation-cues.ts#L209)
749. 点击座位并联系异常意识
   来源：[src/data/presentation-cues.ts:210](../src/data/presentation-cues.ts#L210)
750. 抵达东区大食堂
   来源：[src/data/presentation-cues.ts:218](../src/data/presentation-cues.ts#L218)
751. 继续追踪逃进食堂的记录纸条
   来源：[src/data/presentation-cues.ts:219](../src/data/presentation-cues.ts#L219)
752. 当前剧情阶段不能重新进入大食堂。
   来源：[src/demos/campus-map-demo.tsx:202](../src/demos/campus-map-demo.tsx#L202)
753. 正在进入大食堂剧情…
   来源：[src/demos/campus-map-demo.tsx:202](../src/demos/campus-map-demo.tsx#L202)
754. 先完成当前食堂剧情，纸条被截住后才能离开。
   来源：[src/demos/campus-map-demo.tsx:205](../src/demos/campus-map-demo.tsx#L205)
755. 已进入大食堂：跟随剧情提示，先找出纸条碰过的餐盘。
   来源：[src/demos/campus-map-demo.tsx:215](../src/demos/campus-map-demo.tsx#L215)
756. 大食堂剧情已开始：沿脚印到入口，按空格进入。
   来源：[src/demos/campus-map-demo.tsx:217](../src/demos/campus-map-demo.tsx#L217)
757. 大地图已就绪：道路可走，建筑与绿地保持阻挡。
   来源：[src/demos/campus-map-demo.tsx:219](../src/demos/campus-map-demo.tsx#L219)
758. 已到达基础图书馆入口。当前大地图路线保持开放。
   来源：[src/demos/campus-map-demo.tsx:222](../src/demos/campus-map-demo.tsx#L222)
759. archived
   来源：[src/modules/ChapterThreePhoneInterludeController.ts:108](../src/modules/ChapterThreePhoneInterludeController.ts#L108)；[src/modules/ChapterThreeQizhenLakeController.ts:1286](../src/modules/ChapterThreeQizhenLakeController.ts#L1286)；[src/modules/ChapterThreeQizhenLakeController.ts:1314](../src/modules/ChapterThreeQizhenLakeController.ts#L1314)
760. return\_to\_dock
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:302](../src/modules/ChapterThreeQizhenLakeController.ts#L302)
761. rain\_and\_equipment
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:393](../src/modules/ChapterThreeQizhenLakeController.ts#L393)
762. rescue\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:465](../src/modules/ChapterThreeQizhenLakeController.ts#L465)；[src/modules/ChapterThreeQizhenLakeController.ts:505](../src/modules/ChapterThreeQizhenLakeController.ts#L505)
763. hair\_dryer\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:467](../src/modules/ChapterThreeQizhenLakeController.ts#L467)；[src/modules/ChapterThreeQizhenLakeController.ts:507](../src/modules/ChapterThreeQizhenLakeController.ts#L507)
764. safety\_request\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:468](../src/modules/ChapterThreeQizhenLakeController.ts#L468)；[src/modules/ChapterThreeQizhenLakeController.ts:509](../src/modules/ChapterThreeQizhenLakeController.ts#L509)
765. control\_session\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:510](../src/modules/ChapterThreeQizhenLakeController.ts#L510)
766. invalid\_control\_summary
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:516](../src/modules/ChapterThreeQizhenLakeController.ts#L516)
767. rain\_safety\_hold
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:562](../src/modules/ChapterThreeQizhenLakeController.ts#L562)
768. qizhen\_escape\_completed
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1010](../src/modules/ChapterThreeQizhenLakeController.ts#L1010)
769. capture\_ready
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1064](../src/modules/ChapterThreeQizhenLakeController.ts#L1064)；[src/modules/ChapterThreeQizhenLakeController.ts:1121](../src/modules/ChapterThreeQizhenLakeController.ts#L1121)；[src/modules/ChapterThreeQizhenLakeController.ts:1160](../src/modules/ChapterThreeQizhenLakeController.ts#L1160)；[src/modules/QizhenJournalModel.ts:224](../src/modules/QizhenJournalModel.ts#L224)
770. inactive
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1090](../src/modules/ChapterThreeQizhenLakeController.ts#L1090)；[src/modules/ChapterThreeQizhenLakeController.ts:1331](../src/modules/ChapterThreeQizhenLakeController.ts#L1331)
771. swan\_chase
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1092](../src/modules/ChapterThreeQizhenLakeController.ts#L1092)；[src/modules/ChapterThreeQizhenLakeController.ts:1285](../src/modules/ChapterThreeQizhenLakeController.ts#L1285)；[src/modules/ChapterThreeQizhenLakeController.ts:1313](../src/modules/ChapterThreeQizhenLakeController.ts#L1313)；[src/modules/ChapterThreeQizhenLakeController.ts:1333](../src/modules/ChapterThreeQizhenLakeController.ts#L1333)；[src/scenes/rpg/QizhenLakeScene.ts:1035](../src/scenes/rpg/QizhenLakeScene.ts#L1035)
772. journal\_archived
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1093](../src/modules/ChapterThreeQizhenLakeController.ts#L1093)；[src/modules/QizhenJournalModel.ts:204](../src/modules/QizhenJournalModel.ts#L204)
773. journal\_locked
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1095](../src/modules/ChapterThreeQizhenLakeController.ts#L1095)；[src/modules/ChapterThreeQizhenLakeController.ts:1296](../src/modules/ChapterThreeQizhenLakeController.ts#L1296)；[src/modules/ChapterThreeQizhenLakeController.ts:1315](../src/modules/ChapterThreeQizhenLakeController.ts#L1315)；[src/modules/QizhenJournalModel.ts:203](../src/modules/QizhenJournalModel.ts#L203)
774. draft\_mismatch
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1097](../src/modules/ChapterThreeQizhenLakeController.ts#L1097)
775. orphan\_photo
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1099](../src/modules/ChapterThreeQizhenLakeController.ts#L1099)
776. incomplete\_draft
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1101](../src/modules/ChapterThreeQizhenLakeController.ts#L1101)；[src/modules/ChapterThreeQizhenLakeController.ts:1103](../src/modules/ChapterThreeQizhenLakeController.ts#L1103)；[src/modules/ChapterThreeQizhenLakeController.ts:1211](../src/modules/ChapterThreeQizhenLakeController.ts#L1211)；[src/modules/ChapterThreeQizhenLakeController.ts:1301](../src/modules/ChapterThreeQizhenLakeController.ts#L1301)
777. main\_draft
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1160](../src/modules/ChapterThreeQizhenLakeController.ts#L1160)；[src/modules/QizhenJournalModel.ts:224](../src/modules/QizhenJournalModel.ts#L224)
778. open
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1225](../src/modules/ChapterThreeQizhenLakeController.ts#L1225)
779. already\_published
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1294](../src/modules/ChapterThreeQizhenLakeController.ts#L1294)
780. no\_draft
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1297](../src/modules/ChapterThreeQizhenLakeController.ts#L1297)；[src/modules/ChapterThreeQizhenLakeController.ts:1300](../src/modules/ChapterThreeQizhenLakeController.ts#L1300)
781. offline
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1302](../src/modules/ChapterThreeQizhenLakeController.ts#L1302)；[src/modules/ChapterThreeQizhenLakeController.ts:1323](../src/modules/ChapterThreeQizhenLakeController.ts#L1323)
782. not\_open
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1317](../src/modules/ChapterThreeQizhenLakeController.ts#L1317)
783. no\_photo
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1322](../src/modules/ChapterThreeQizhenLakeController.ts#L1322)
784. locked
   来源：[src/modules/QizhenJournalModel.ts:130](../src/modules/QizhenJournalModel.ts#L130)；[src/scenes/phone/P18_Photos/index.tsx:197](../src/scenes/phone/P18_Photos/index.tsx#L197)；[src/scenes/rpg/CanteenInteriorScene.ts:2347](../src/scenes/rpg/CanteenInteriorScene.ts#L2347)；[src/scenes/rpg/TheaterInteriorScene.ts:1388](../src/scenes/rpg/TheaterInteriorScene.ts#L1388)；[src/scenes/rpg/TheaterInteriorScene.ts:1396](../src/scenes/rpg/TheaterInteriorScene.ts#L1396)
785. unknown\_spot
   来源：[src/modules/QizhenJournalModel.ts:202](../src/modules/QizhenJournalModel.ts#L202)
786. titles
   来源：[src/modules/QizhenJournalModel.ts:298](../src/modules/QizhenJournalModel.ts#L298)
787. statuses
   来源：[src/modules/QizhenJournalModel.ts:299](../src/modules/QizhenJournalModel.ts#L299)
788. spotCaptions.{{spotId}}
   来源：[src/modules/QizhenJournalModel.ts:311](../src/modules/QizhenJournalModel.ts#L311)
789. replyPools.{{poolKey}}
   来源：[src/modules/QizhenJournalModel.ts:339](../src/modules/QizhenJournalModel.ts#L339)
790. {{statusText}}。主图还没拍，等我先把船划到湖心。
   来源：[src/modules/QizhenJournalModel.ts:527](../src/modules/QizhenJournalModel.ts#L527)
791. 标签：{{labels.join("、")}}。
   来源：[src/modules/QizhenJournalModel.ts:532](../src/modules/QizhenJournalModel.ts#L532)
792. {{statusText}}。主图是在湖心按的快门，{{tagPart}}先占 1 楼，后面慢慢补。
   来源：[src/modules/QizhenJournalModel.ts:533](../src/modules/QizhenJournalModel.ts#L533)
793. （标题未定）
   来源：[src/modules/QizhenJournalModel.ts:578](../src/modules/QizhenJournalModel.ts#L578)
794. （状态未定）
   来源：[src/modules/QizhenJournalModel.ts:579](../src/modules/QizhenJournalModel.ts#L579)
795. 低层
   来源：[src/modules/QizhenWeatherControlModel.ts:12](../src/modules/QizhenWeatherControlModel.ts#L12)；[src/modules/QizhenWeatherControlModel.ts:64](../src/modules/QizhenWeatherControlModel.ts#L64)
796. 高层
   来源：[src/modules/QizhenWeatherControlModel.ts:12](../src/modules/QizhenWeatherControlModel.ts#L12)；[src/modules/QizhenWeatherControlModel.ts:48](../src/modules/QizhenWeatherControlModel.ts#L48)
797. 中层
   来源：[src/modules/QizhenWeatherControlModel.ts:12](../src/modules/QizhenWeatherControlModel.ts#L12)；[src/modules/QizhenWeatherControlModel.ts:56](../src/modules/QizhenWeatherControlModel.ts#L56)
798. {{board}}:{{view.title}}
   来源：[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:217](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L217)
799. 1楼
   来源：[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:263](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L263)
800. 楼
   来源：[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:312](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L312)；[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:339](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L339)
801. 学生剧《7:55》演出档案
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:12](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L12)
802. 演出档案
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:14](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L14)
803. 原创学生剧
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:15](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L15)
804. 剧情简介
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:50](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L50)
805. 演出信息
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:55](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L55)
806. 制作分工
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:67](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L67)
807. 现场须知
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:79](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L79)
808. {{copy.secondWaveCountdownStatus}}{{secondWaveSeconds}} 秒
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:60](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L60)
809. 这条委托当前无法接取。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:67](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L67)
810. 学生剧现场帮抢委托已接取。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:71](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L71)
811. task
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:71](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L71)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:96](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L96)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:102](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L102)
812. 第一波结束：网速过慢。请切换到移动数据。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:84](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L84)
813. 第二波要求使用移动数据。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:90](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L90)
814. 第二波抢票成功，取票码已生成。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:102](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L102)
815. 当前放票尚未开放。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:110](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L110)
816. 学生剧手机帮抢委托
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:120](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L120)
817. 待接
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:125](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L125)
818. 第一波开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:127](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L127)
819. 第二波等待
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:129](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L129)
820. 第二波开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:129](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L129)
821. 第二波已中
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:130](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L130)
822. 第一波已中
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:130](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L130)
823. 委托进度
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:134](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L134)
824. 1 接单
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:135](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L135)
825. 2 大厅记录（可选）
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:136](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L136)
826. 3 第一波
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:137](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L137)
827. 4 第二波
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:139](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L139)
828. 4 已抢到
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:139](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L139)
829. 当前网络：{{networkLabel}}
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:143](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L143)
830. 当前网络
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:144](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L144)
831. 第一波放票时间
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:156](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L156)
832. 第一波放票
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:157](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L157)
833. {{secondWaveSeconds}} 秒后开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:187](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L187)
834. 抢票成功回执
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:196](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L196)
835. 湖区云层校准
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:188](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L188)
836. 寝室吹风机
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:190](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L190)
837. 风向校准
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:191](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L191)
838. 逆风修正三层云带
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:191](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L191)
839. /3 ·
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:192](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L192)
840. 西南风持续向左推动云带
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:195](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L195)
841. 持续风力
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:196](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L196)
842. 高层 Q/E · 中层 A/D · 低层 Z/C 后退 / 前进
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:198](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L198)
843. {{control.label}}云带位置
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:213](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L213)
844. {{control.label}}{{direction === -1 ? "后退" : "前进"}}，键盘 {{key}}
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:238](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L238)
845. 进
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:249](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L249)
846. 退
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:249](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L249)
847. 三层均需操作
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:258](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L258)
848. 同步稳定
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:258](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L258)
849. 发现一条未归档的夜间接入记录。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:725](../src/scenes/phone/P13_PhoneHome/index.tsx#L725)
850. 校园网络
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:725](../src/scenes/phone/P13_PhoneHome/index.tsx#L725)
851. 打开 CC98 学生剧现场帮抢帖
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:736](../src/scenes/phone/P13_PhoneHome/index.tsx#L736)
852. CC98 · 学生剧《7:55》
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:740](../src/scenes/phone/P13_PhoneHome/index.tsx#L740)
853. 现场帮抢委托待接
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:743](../src/scenes/phone/P13_PhoneHome/index.tsx#L743)
854. 已接单，第一波待开始
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:745](../src/scenes/phone/P13_PhoneHome/index.tsx#L745)
855. 07:55:23
   来源：[src/scenes/phone/P18_Photos/index.tsx:33](../src/scenes/phone/P18_Photos/index.tsx#L33)；[src/scenes/phone/P18_Photos/index.tsx:34](../src/scenes/phone/P18_Photos/index.tsx#L34)；[src/scenes/phone/P18_Photos/index.tsx:35](../src/scenes/phone/P18_Photos/index.tsx#L35)；[src/scenes/phone/P18_Photos/index.tsx:36](../src/scenes/phone/P18_Photos/index.tsx#L36)；[src/scenes/phone/P18_Photos/index.tsx:37](../src/scenes/phone/P18_Photos/index.tsx#L37)；[src/scenes/phone/P18_Photos/index.tsx:38](../src/scenes/phone/P18_Photos/index.tsx#L38)；[src/scenes/phone/P18_Photos/index.tsx:39](../src/scenes/phone/P18_Photos/index.tsx#L39)
856. FRM 3A
   来源：[src/scenes/phone/P18_Photos/index.tsx:33](../src/scenes/phone/P18_Photos/index.tsx#L33)
857. FRM 91
   来源：[src/scenes/phone/P18_Photos/index.tsx:34](../src/scenes/phone/P18_Photos/index.tsx#L34)
858. FRM D7
   来源：[src/scenes/phone/P18_Photos/index.tsx:35](../src/scenes/phone/P18_Photos/index.tsx#L35)
859. FRM 4C
   来源：[src/scenes/phone/P18_Photos/index.tsx:36](../src/scenes/phone/P18_Photos/index.tsx#L36)
860. FRM 0F
   来源：[src/scenes/phone/P18_Photos/index.tsx:37](../src/scenes/phone/P18_Photos/index.tsx#L37)
861. FRM B2
   来源：[src/scenes/phone/P18_Photos/index.tsx:38](../src/scenes/phone/P18_Photos/index.tsx#L38)
862. FRM E8
   来源：[src/scenes/phone/P18_Photos/index.tsx:39](../src/scenes/phone/P18_Photos/index.tsx#L39)
863. 照片相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:63](../src/scenes/phone/P18_Photos/index.tsx#L63)
864. 相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:69](../src/scenes/phone/P18_Photos/index.tsx#L69)
865. 退出照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:70](../src/scenes/phone/P18_Photos/index.tsx#L70)
866. 启真湖划船
   来源：[src/scenes/phone/P18_Photos/index.tsx:79](../src/scenes/phone/P18_Photos/index.tsx#L79)；[src/scenes/phone/P18_Photos/index.tsx:108](../src/scenes/phone/P18_Photos/index.tsx#L108)
867. 张 · 来自相机
   来源：[src/scenes/phone/P18_Photos/index.tsx:80](../src/scenes/phone/P18_Photos/index.tsx#L80)
868. 恢复的项目
   来源：[src/scenes/phone/P18_Photos/index.tsx:84](../src/scenes/phone/P18_Photos/index.tsx#L84)
869. 7 张 · 帧顺序损坏
   来源：[src/scenes/phone/P18_Photos/index.tsx:85](../src/scenes/phone/P18_Photos/index.tsx#L85)
870. 校园与日常
   来源：[src/scenes/phone/P18_Photos/index.tsx:91](../src/scenes/phone/P18_Photos/index.tsx#L91)；[src/scenes/phone/P18_Photos/index.tsx:138](../src/scenes/phone/P18_Photos/index.tsx#L138)
871. 张 · 普通照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:92](../src/scenes/phone/P18_Photos/index.tsx#L92)
872. 相机照片、恢复帧和普通生活照分开归档。普通照片不会进入时间线或证据判定。
   来源：[src/scenes/phone/P18_Photos/index.tsx:94](../src/scenes/phone/P18_Photos/index.tsx#L94)
873. 启真湖划船相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:102](../src/scenes/phone/P18_Photos/index.tsx#L102)
874. 返回相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:109](../src/scenes/phone/P18_Photos/index.tsx#L109)；[src/scenes/phone/P18_Photos/index.tsx:139](../src/scenes/phone/P18_Photos/index.tsx#L139)；[src/scenes/phone/P18_Photos/index.tsx:216](../src/scenes/phone/P18_Photos/index.tsx#L216)
875. {{photo.spotId}} 相机照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:118](../src/scenes/phone/P18_Photos/index.tsx#L118)
876. 这份存档没有保留相机照片。恢复的动态照片仍可继续核验。
   来源：[src/scenes/phone/P18_Photos/index.tsx:123](../src/scenes/phone/P18_Photos/index.tsx#L123)
877. 校园与日常相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:132](../src/scenes/phone/P18_Photos/index.tsx#L132)
878. 这些照片用于补足手机相册的生活层次，不会触发剧情进度。
   来源：[src/scenes/phone/P18_Photos/index.tsx:144](../src/scenes/phone/P18_Photos/index.tsx#L144)
879. 校园与日常照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:145](../src/scenes/phone/P18_Photos/index.tsx#L145)
880. {{selectedCampusPhoto.capturedAt}} · {{selectedCampusPhoto.location}}
   来源：[src/scenes/phone/P18_Photos/index.tsx:164](../src/scenes/phone/P18_Photos/index.tsx#L164)
881. {{selectedCampusPhoto.title}}，{{selectedCampusPhoto.detail}}
   来源：[src/scenes/phone/P18_Photos/index.tsx:169](../src/scenes/phone/P18_Photos/index.tsx#L169)
882. 普通照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:172](../src/scenes/phone/P18_Photos/index.tsx#L172)
883. 不参与时间线、地点判断或物品识别。
   来源：[src/scenes/phone/P18_Photos/index.tsx:173](../src/scenes/phone/P18_Photos/index.tsx#L173)
884. 照
   来源：[src/scenes/phone/P18_Photos/index.tsx:174](../src/scenes/phone/P18_Photos/index.tsx#L174)
885. 关闭
   来源：[src/scenes/phone/P18_Photos/index.tsx:176](../src/scenes/phone/P18_Photos/index.tsx#L176)；[src/scenes/rpg/TheaterInteriorScene.ts:1452](../src/scenes/rpg/TheaterInteriorScene.ts#L1452)；[src/scenes/rpg/TheaterInteriorScene.ts:1498](../src/scenes/rpg/TheaterInteriorScene.ts#L1498)
886. accepted
   来源：[src/scenes/phone/P18_Photos/index.tsx:195](../src/scenes/phone/P18_Photos/index.tsx#L195)；[src/scenes/rpg/CanteenInteriorScene.ts:2303](../src/scenes/rpg/CanteenInteriorScene.ts#L2303)；[src/scenes/rpg/CanteenInteriorScene.ts:2369](../src/scenes/rpg/CanteenInteriorScene.ts#L2369)
887. 三帧已经恢复为一次连续的水平移动。
   来源：[src/scenes/phone/P18_Photos/index.tsx:196](../src/scenes/phone/P18_Photos/index.tsx#L196)
888. 先完成 CC98 记录收尾。
   来源：[src/scenes/phone/P18_Photos/index.tsx:198](../src/scenes/phone/P18_Photos/index.tsx#L198)
889. 这三帧的运动方向没有连续起来。
   来源：[src/scenes/phone/P18_Photos/index.tsx:200](../src/scenes/phone/P18_Photos/index.tsx#L200)
890. 对比纸条与同一根湖岸灯柱的相对位置。
   来源：[src/scenes/phone/P18_Photos/index.tsx:202](../src/scenes/phone/P18_Photos/index.tsx#L202)
891. 排除镜像和无关帧，选择能形成连续水平移动的三张照片。
   来源：[src/scenes/phone/P18_Photos/index.tsx:203](../src/scenes/phone/P18_Photos/index.tsx#L203)
892. 已恢复相册
   来源：[src/scenes/phone/P18_Photos/index.tsx:209](../src/scenes/phone/P18_Photos/index.tsx#L209)
893. 最近删除 · 已恢复
   来源：[src/scenes/phone/P18_Photos/index.tsx:215](../src/scenes/phone/P18_Photos/index.tsx#L215)
894. 重排
   来源：[src/scenes/phone/P18_Photos/index.tsx:222](../src/scenes/phone/P18_Photos/index.tsx#L222)
895. IMG\_0755\_LIVE · 帧顺序损坏
   来源：[src/scenes/phone/P18_Photos/index.tsx:222](../src/scenes/phone/P18_Photos/index.tsx#L222)
896. 选出同一段运动中连续的三帧，再按先后顺序放入。
   来源：[src/scenes/phone/P18_Photos/index.tsx:223](../src/scenes/phone/P18_Photos/index.tsx#L223)
897. {{slot + 1}} · 待选择
   来源：[src/scenes/phone/P18_Photos/index.tsx:228](../src/scenes/phone/P18_Photos/index.tsx#L228)
898. {{frame.label}}，恢复照片帧
   来源：[src/scenes/phone/P18_Photos/index.tsx:243](../src/scenes/phone/P18_Photos/index.tsx#L243)
899. 已恢复的连续帧
   来源：[src/scenes/phone/P18_Photos/index.tsx:250](../src/scenes/phone/P18_Photos/index.tsx#L250)
900. 连续帧已恢复
   来源：[src/scenes/phone/P18_Photos/index.tsx:255](../src/scenes/phone/P18_Photos/index.tsx#L255)
901. 确认照片顺序
   来源：[src/scenes/phone/P18_Photos/index.tsx:258](../src/scenes/phone/P18_Photos/index.tsx#L258)
902. 紫金港校区
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:414](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L414)
903. 剧场
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:478](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L478)
904. 求是路
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:847](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L847)
905. 剧场 →
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:852](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L852)
906. 剧院外到达转场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)
907. 食堂外上车转场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)
908. start
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)；[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
909. 角色解锁共享单车并开始骑行
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
910. 角色刹车下车并进入剧院外广场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
911. 食堂到剧院：755 米 3D 自行车追逐
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:361](../src/scenes/rpg/CanteenChaseOverlay.tsx#L361)
912. 三车道校园道路、骑车人物、前方障碍，以及两侧人行道上的校园路人
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:369](../src/scenes/rpg/CanteenChaseOverlay.tsx#L369)
913. 骑行状态
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:372](../src/scenes/rpg/CanteenChaseOverlay.tsx#L372)
914. 追纸距离
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:374](../src/scenes/rpg/CanteenChaseOverlay.tsx#L374)
915. / 755m
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:375](../src/scenes/rpg/CanteenChaseOverlay.tsx#L375)
916. 骑行进度
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:380](../src/scenes/rpg/CanteenChaseOverlay.tsx#L380)
917. 机会
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:403](../src/scenes/rpg/CanteenChaseOverlay.tsx#L403)
918. 剩余 {{view.lives}} 次机会
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:404](../src/scenes/rpg/CanteenChaseOverlay.tsx#L404)
919. 节奏提升
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
920. 拥堵升级
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
921. 最后冲刺
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
922. 换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:434](../src/scenes/rpg/CanteenChaseOverlay.tsx#L434)
923. 追逐方向
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:436](../src/scenes/rpg/CanteenChaseOverlay.tsx#L436)
924. 向左换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:437](../src/scenes/rpg/CanteenChaseOverlay.tsx#L437)
925. 向右换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:438](../src/scenes/rpg/CanteenChaseOverlay.tsx#L438)
926. 返回页面后继续
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:444](../src/scenes/rpg/CanteenChaseOverlay.tsx#L444)
927. 已暂停
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:444](../src/scenes/rpg/CanteenChaseOverlay.tsx#L444)
928. 纸条已离开 · 重新拦截
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:196](../src/scenes/rpg/CanteenDefenseRuntime.ts#L196)
929. 准备重新开始
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:197](../src/scenes/rpg/CanteenDefenseRuntime.ts#L197)
930. 守住出口 {{seconds.toString().padStart(2, "0")}} 秒
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:463](../src/scenes/rpg/CanteenDefenseRuntime.ts#L463)
931. 冲刺冷却 {{(this.dashCooldownMs / 1000).toFixed(1)}}s
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:466](../src/scenes/rpg/CanteenDefenseRuntime.ts#L466)
932. 空格：冲刺
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:466](../src/scenes/rpg/CanteenDefenseRuntime.ts#L466)
933. 蓝色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:188](../src/scenes/rpg/CanteenInteriorModel.ts#L188)
934. 白色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:200](../src/scenes/rpg/CanteenInteriorModel.ts#L200)
935. 黑色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:212](../src/scenes/rpg/CanteenInteriorModel.ts#L212)
936. 查看右侧瓶罐架
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:226](../src/scenes/rpg/CanteenInteriorModel.ts#L226)
937. 使用混合台
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:238](../src/scenes/rpg/CanteenInteriorModel.ts#L238)
938. 第五个窗口宣传灯箱空杯位
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:250](../src/scenes/rpg/CanteenInteriorModel.ts#L250)
939. 询问第三列第一个同学
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:266](../src/scenes/rpg/CanteenInteriorModel.ts#L266)
940. 1号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:312](../src/scenes/rpg/CanteenInteriorModel.ts#L312)
941. 2号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:326](../src/scenes/rpg/CanteenInteriorModel.ts#L326)
942. 3号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:340](../src/scenes/rpg/CanteenInteriorModel.ts#L340)
943. 4号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:354](../src/scenes/rpg/CanteenInteriorModel.ts#L354)
944. 5号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:368](../src/scenes/rpg/CanteenInteriorModel.ts#L368)
945. 第三窗口点餐机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:451](../src/scenes/rpg/CanteenInteriorModel.ts#L451)
946. {{cart.exitId}}出口餐盘车
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:463](../src/scenes/rpg/CanteenInteriorModel.ts#L463)
947. 食堂东南出口
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:473](../src/scenes/rpg/CanteenInteriorModel.ts#L473)
948. 前面没动，我也没动。大家都很稳定。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:177](../src/scenes/rpg/CanteenInteriorScene.ts#L177)
949. 你说的对。虽然不知道你说了什么。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:178](../src/scenes/rpg/CanteenInteriorScene.ts#L178)
950. 是啊，吃什么。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:179](../src/scenes/rpg/CanteenInteriorScene.ts#L179)
951. 今天有气泡水喝吗？
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:180](../src/scenes/rpg/CanteenInteriorScene.ts#L180)
952. 早十不慌，先来个西红柿鸡蛋。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:181](../src/scenes/rpg/CanteenInteriorScene.ts#L181)
953. 为什么早上吃西红柿鸡蛋。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:182](../src/scenes/rpg/CanteenInteriorScene.ts#L182)
954. 刚才有张纸过去了。它没拿餐盘。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:185](../src/scenes/rpg/CanteenInteriorScene.ts#L185)
955. 看手机。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:186](../src/scenes/rpg/CanteenInteriorScene.ts#L186)
956. 依旧看手机。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:187](../src/scenes/rpg/CanteenInteriorScene.ts#L187)
957. 不用问了可以坐这里。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:188](../src/scenes/rpg/CanteenInteriorScene.ts#L188)
958. 要什么？快点，后面排着呢。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:190](../src/scenes/rpg/CanteenInteriorScene.ts#L190)
959. 交谈
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:877](../src/scenes/rpg/CanteenInteriorScene.ts#L877)；[src/scenes/rpg/CanteenInteriorScene.ts:889](../src/scenes/rpg/CanteenInteriorScene.ts#L889)；[src/scenes/rpg/CanteenInteriorScene.ts:902](../src/scenes/rpg/CanteenInteriorScene.ts#L902)
960. 桌上的餐盘
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1288](../src/scenes/rpg/CanteenInteriorScene.ts#L1288)
961. 号取餐窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1369](../src/scenes/rpg/CanteenInteriorScene.ts#L1369)
962. 拖入 0755 · {{window.value}}号
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1393](../src/scenes/rpg/CanteenInteriorScene.ts#L1393)
963. 站这里 · 再拖票
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1415](../src/scenes/rpg/CanteenInteriorScene.ts#L1415)
964. 玩家：找到了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1537](../src/scenes/rpg/CanteenInteriorScene.ts#L1537)
965. 纸条：！
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1540](../src/scenes/rpg/CanteenInteriorScene.ts#L1540)
966. {{canteenContent.drinks.shelfPrompt}} / {{canteenContent.drinks.shelfOrder}}
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1959](../src/scenes/rpg/CanteenInteriorScene.ts#L1959)
967. success
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1973](../src/scenes/rpg/CanteenInteriorScene.ts#L1973)；[src/scenes/rpg/CanteenInteriorScene.ts:2036](../src/scenes/rpg/CanteenInteriorScene.ts#L2036)；[src/scenes/rpg/CanteenInteriorScene.ts:3654](../src/scenes/rpg/CanteenInteriorScene.ts#L3654)；[src/scenes/rpg/CanteenInteriorScene.ts:3780](../src/scenes/rpg/CanteenInteriorScene.ts#L3780)；[src/scenes/rpg/QizhenLakeScene.ts:2512](../src/scenes/rpg/QizhenLakeScene.ts#L2512)；[src/scenes/rpg/QizhenLakeScene.ts:2531](../src/scenes/rpg/QizhenLakeScene.ts#L2531)；[src/scenes/rpg/QizhenLakeScene.ts:2542](../src/scenes/rpg/QizhenLakeScene.ts#L2542)；[src/scenes/rpg/QizhenLakeScene.ts:2551](../src/scenes/rpg/QizhenLakeScene.ts#L2551)；[src/scenes/rpg/QizhenLakeScene.ts:2562](../src/scenes/rpg/QizhenLakeScene.ts#L2562)；[src/scenes/rpg/QizhenLakeScene.ts:2567](../src/scenes/rpg/QizhenLakeScene.ts#L2567)；[src/scenes/rpg/QizhenLakeScene.ts:2571](../src/scenes/rpg/QizhenLakeScene.ts#L2571)；[src/scenes/rpg/QizhenLakeScene.ts:2575](../src/scenes/rpg/QizhenLakeScene.ts#L2575)；[src/scenes/rpg/QizhenLakeScene.ts:2579](../src/scenes/rpg/QizhenLakeScene.ts#L2579)；[src/scenes/rpg/QizhenLakeScene.ts:2583](../src/scenes/rpg/QizhenLakeScene.ts#L2583)；[src/scenes/rpg/QizhenLakeScene.ts:2598](../src/scenes/rpg/QizhenLakeScene.ts#L2598)；[src/scenes/rpg/QizhenLakeScene.ts:2602](../src/scenes/rpg/QizhenLakeScene.ts#L2602)；[src/scenes/rpg/QizhenLakeScene.ts:2606](../src/scenes/rpg/QizhenLakeScene.ts#L2606)；[src/scenes/rpg/QizhenLakeScene.ts:2610](../src/scenes/rpg/QizhenLakeScene.ts#L2610)；[src/scenes/rpg/TheaterInteriorScene.ts:1623](../src/scenes/rpg/TheaterInteriorScene.ts#L1623)；[src/scenes/rpg/TheaterInteriorScene.ts:1698](../src/scenes/rpg/TheaterInteriorScene.ts#L1698)；[src/scenes/rpg/TheaterInteriorScene.ts:1733](../src/scenes/rpg/TheaterInteriorScene.ts#L1733)
968. 窗口正常出餐。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2036](../src/scenes/rpg/CanteenInteriorScene.ts#L2036)
969. rpg\_canteen\_tray\_task\_start\_requested
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2184](../src/scenes/rpg/CanteenInteriorScene.ts#L2184)
970. missed\_target
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2293](../src/scenes/rpg/CanteenInteriorScene.ts#L2293)；[src/scenes/rpg/CanteenInteriorScene.ts:2309](../src/scenes/rpg/CanteenInteriorScene.ts#L2309)；[src/scenes/rpg/CanteenInteriorScene.ts:2329](../src/scenes/rpg/CanteenInteriorScene.ts#L2329)；[src/scenes/rpg/TheaterInteriorScene.ts:1354](../src/scenes/rpg/TheaterInteriorScene.ts#L1354)；[src/scenes/rpg/TheaterInteriorScene.ts:1379](../src/scenes/rpg/TheaterInteriorScene.ts#L1379)
971. 玩家自己
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2304](../src/scenes/rpg/CanteenInteriorScene.ts#L2304)
972. 把难喝饮料拖到人物自己身上才能喝掉。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2310](../src/scenes/rpg/CanteenInteriorScene.ts#L2310)
973. dailySpecialSparklingWater
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2330](../src/scenes/rpg/CanteenInteriorScene.ts#L2330)
974. 请拖到第五个打饭窗口下方宣传板的发光空杯位。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2331](../src/scenes/rpg/CanteenInteriorScene.ts#L2331)
975. 小票不需要拖拽：靠近取餐窗口后按空格使用。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2332](../src/scenes/rpg/CanteenInteriorScene.ts#L2332)
976. wrong\_item
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2339](../src/scenes/rpg/CanteenInteriorScene.ts#L2339)；[src/scenes/rpg/TheaterInteriorScene.ts:1388](../src/scenes/rpg/TheaterInteriorScene.ts#L1388)
977. light
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2349](../src/scenes/rpg/CanteenInteriorScene.ts#L2349)；[src/scenes/rpg/TheaterInteriorScene.ts:1398](../src/scenes/rpg/TheaterInteriorScene.ts#L1398)
978. too\_far
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2356](../src/scenes/rpg/CanteenInteriorScene.ts#L2356)；[src/scenes/rpg/TheaterInteriorScene.ts:1405](../src/scenes/rpg/TheaterInteriorScene.ts#L1405)
979. promo
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2358](../src/scenes/rpg/CanteenInteriorScene.ts#L2358)
980. 落点正确；人物还没有靠近宣传板。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2359](../src/scenes/rpg/CanteenInteriorScene.ts#L2359)
981. 落点正确；靠近设施后再操作。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2360](../src/scenes/rpg/CanteenInteriorScene.ts#L2360)
982. 先把手上的餐盘交给阿姨
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2558](../src/scenes/rpg/CanteenInteriorScene.ts#L2558)
983. 拿起桌上的餐盘
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2559](../src/scenes/rpg/CanteenInteriorScene.ts#L2559)
984. 使用点餐机
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2561](../src/scenes/rpg/CanteenInteriorScene.ts#L2561)
985. 查看{{nearest.value}}号窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2564](../src/scenes/rpg/CanteenInteriorScene.ts#L2564)
986. 使用小票 · {{nearest.value}}号窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2566](../src/scenes/rpg/CanteenInteriorScene.ts#L2566)
987. {{nearest.value}}号取餐窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2567](../src/scenes/rpg/CanteenInteriorScene.ts#L2567)
988. 把今日新品放入宣传板空杯位
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2570](../src/scenes/rpg/CanteenInteriorScene.ts#L2570)
989. 宣传板空杯位
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2571](../src/scenes/rpg/CanteenInteriorScene.ts#L2571)
990. 确认蓝色轨迹指向
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2574](../src/scenes/rpg/CanteenInteriorScene.ts#L2574)
991. 靠近餐盘车把手
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2575](../src/scenes/rpg/CanteenInteriorScene.ts#L2575)
992. 靠近东南门离开食堂
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2577](../src/scenes/rpg/CanteenInteriorScene.ts#L2577)
993. 气泡水（蓝色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2925](../src/scenes/rpg/CanteenInteriorScene.ts#L2925)
994. 柠檬茶（白色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2926](../src/scenes/rpg/CanteenInteriorScene.ts#L2926)
995. 黑咖啡（黑色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2927](../src/scenes/rpg/CanteenInteriorScene.ts#L2927)
996. ← / → 选择 · 空格 / 回车确认 · Esc 退出
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2964](../src/scenes/rpg/CanteenInteriorScene.ts#L2964)
997. 食堂新品混合台
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3075](../src/scenes/rpg/CanteenInteriorScene.ts#L3075)
998. 退出 Esc
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3083](../src/scenes/rpg/CanteenInteriorScene.ts#L3083)
999. 大玻璃杯
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3106](../src/scenes/rpg/CanteenInteriorScene.ts#L3106)
1000. 货架提示已记录：黑色 → 蓝色 → 白色
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3117](../src/scenes/rpg/CanteenInteriorScene.ts#L3117)
1001. 货架提示：尚未查看
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3118](../src/scenes/rpg/CanteenInteriorScene.ts#L3118)
1002. 黑咖啡
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3129](../src/scenes/rpg/CanteenInteriorScene.ts#L3129)
1003. 气泡水
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3130](../src/scenes/rpg/CanteenInteriorScene.ts#L3130)
1004. 柠檬茶
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3131](../src/scenes/rpg/CanteenInteriorScene.ts#L3131)
1005. {{button.name}}·未持有
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3145](../src/scenes/rpg/CanteenInteriorScene.ts#L3145)
1006. 倒入{{button.name}}
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3145](../src/scenes/rpg/CanteenInteriorScene.ts#L3145)
1007. 观察模式 · 菜名留下了另一层字
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3221](../src/scenes/rpg/CanteenInteriorScene.ts#L3221)
1008. 选择一份餐品 · 取餐前不能重复下单
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3222](../src/scenes/rpg/CanteenInteriorScene.ts#L3222)
1009. 玩家：那是鸡吗？
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3378](../src/scenes/rpg/CanteenInteriorScene.ts#L3378)
1010. 系统：现在不是了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3378](../src/scenes/rpg/CanteenInteriorScene.ts#L3378)
1011. 本人马上回来。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3475](../src/scenes/rpg/CanteenInteriorScene.ts#L3475)
1012. 场景仍在初始化，请稍后再试。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3614](../src/scenes/rpg/CanteenInteriorScene.ts#L3614)
1013. 纸条暂时没有找到能钻出去的流程。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3654](../src/scenes/rpg/CanteenInteriorScene.ts#L3654)
1014. 左上门
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3659](../src/scenes/rpg/CanteenInteriorScene.ts#L3659)
1015. 左中下通道
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3660](../src/scenes/rpg/CanteenInteriorScene.ts#L3660)
1016. 右下门
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3661](../src/scenes/rpg/CanteenInteriorScene.ts#L3661)
1017. 纸条从{{exitLabel\[exitId\]}}溜走了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3663](../src/scenes/rpg/CanteenInteriorScene.ts#L3663)
1018. rpg\_canteen\_leave\_requested
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3798](../src/scenes/rpg/CanteenInteriorScene.ts#L3798)
1019. 玩家：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3822](../src/scenes/rpg/CanteenInteriorScene.ts#L3822)；[src/scenes/rpg/QizhenLakeScene.ts:3146](../src/scenes/rpg/QizhenLakeScene.ts#L3146)；[src/scenes/rpg/QizhenLoopScene.ts:352](../src/scenes/rpg/QizhenLoopScene.ts#L352)；[src/scenes/rpg/TheaterInteriorScene.ts:2476](../src/scenes/rpg/TheaterInteriorScene.ts#L2476)
1020. 系统：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3823](../src/scenes/rpg/CanteenInteriorScene.ts#L3823)；[src/scenes/rpg/QizhenLakeScene.ts:3147](../src/scenes/rpg/QizhenLakeScene.ts#L3147)；[src/scenes/rpg/QizhenLoopScene.ts:353](../src/scenes/rpg/QizhenLoopScene.ts#L353)；[src/scenes/rpg/TheaterInteriorScene.ts:2477](../src/scenes/rpg/TheaterInteriorScene.ts#L2477)
1021. 任务：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3824](../src/scenes/rpg/CanteenInteriorScene.ts#L3824)；[src/scenes/rpg/QizhenLakeScene.ts:3148](../src/scenes/rpg/QizhenLakeScene.ts#L3148)；[src/scenes/rpg/QizhenLoopScene.ts:354](../src/scenes/rpg/QizhenLoopScene.ts#L354)；[src/scenes/rpg/TheaterInteriorScene.ts:2478](../src/scenes/rpg/TheaterInteriorScene.ts#L2478)
1022. 精准
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:77](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L77)
1023. 良好
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:78](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L78)
1024. 命中
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:79](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L79)
1025. 错过
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:80](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L80)
1026. 判定线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:185](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L185)
1027. 彩色音符向左移动
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:196](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L196)
1028. 准确率 {{(result.accuracy \* 100).toFixed(1)}}%
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:357](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L357)
1029. 断线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:407](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L407)
1030. 脱钩
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:407](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L407)
1031. 未通过
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:407](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L407)
1032. 辅助·
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:492](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L492)
1033. {{assistLabel}}目标：{{this.options.targetLabel}} {{this.model.judgedCount}}/{{this.model.totalNotes}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:493](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L493)
1034. 张力 {{tension}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:500](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L500)
1035. 连击 {{combo}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:501](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L501)
1036. 右收线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:730](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L730)
1037. 左收线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:730](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L730)
1038. 按住
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:739](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L739)
1039. · 稍早
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:943](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L943)
1040. · 稍晚
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:944](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L944)
1041. 器材架上的皮划艇
   来源：[src/scenes/rpg/QizhenLakeModel.ts:349](../src/scenes/rpg/QizhenLakeModel.ts#L349)
1042. 花坛边的细长物体
   来源：[src/scenes/rpg/QizhenLakeModel.ts:350](../src/scenes/rpg/QizhenLakeModel.ts#L350)
1043. 设备区的旧设施
   来源：[src/scenes/rpg/QizhenLakeModel.ts:351](../src/scenes/rpg/QizhenLakeModel.ts#L351)
1044. 小码头登船边
   来源：[src/scenes/rpg/QizhenLakeModel.ts:352](../src/scenes/rpg/QizhenLakeModel.ts#L352)
1045. 湖边值班老师
   来源：[src/scenes/rpg/QizhenLakeModel.ts:353](../src/scenes/rpg/QizhenLakeModel.ts#L353)
1046. 码头储物柜
   来源：[src/scenes/rpg/QizhenLakeModel.ts:354](../src/scenes/rpg/QizhenLakeModel.ts#L354)
1047. 划向大湖
   来源：[src/scenes/rpg/QizhenLakeModel.ts:355](../src/scenes/rpg/QizhenLakeModel.ts#L355)
1048. 返回小码头
   来源：[src/scenes/rpg/QizhenLakeModel.ts:357](../src/scenes/rpg/QizhenLakeModel.ts#L357)
1049. 前往黑天鹅围栏
   来源：[src/scenes/rpg/QizhenLakeModel.ts:358](../src/scenes/rpg/QizhenLakeModel.ts#L358)
1050. 进入浮排河道
   来源：[src/scenes/rpg/QizhenLakeModel.ts:359](../src/scenes/rpg/QizhenLakeModel.ts#L359)
1051. 纸条倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:360](../src/scenes/rpg/QizhenLakeModel.ts#L360)
1052. 钥匙倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:361](../src/scenes/rpg/QizhenLakeModel.ts#L361)
1053. 网框倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:362](../src/scenes/rpg/QizhenLakeModel.ts#L362)
1054. 鱼群倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:363](../src/scenes/rpg/QizhenLakeModel.ts#L363)
1055. 漂浮的钓鱼竿
   来源：[src/scenes/rpg/QizhenLakeModel.ts:364](../src/scenes/rpg/QizhenLakeModel.ts#L364)
1056. 纸条倒影水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:365](../src/scenes/rpg/QizhenLakeModel.ts#L365)
1057. 钥匙水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:366](../src/scenes/rpg/QizhenLakeModel.ts#L366)
1058. 鱼群聚拢的水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:367](../src/scenes/rpg/QizhenLakeModel.ts#L367)
1059. 最终钓具装配位
   来源：[src/scenes/rpg/QizhenLakeModel.ts:368](../src/scenes/rpg/QizhenLakeModel.ts#L368)
1060. 返回大湖
   来源：[src/scenes/rpg/QizhenLakeModel.ts:370](../src/scenes/rpg/QizhenLakeModel.ts#L370)；[src/scenes/rpg/QizhenLakeModel.ts:376](../src/scenes/rpg/QizhenLakeModel.ts#L376)
1061. 进入返航河道
   来源：[src/scenes/rpg/QizhenLakeModel.ts:371](../src/scenes/rpg/QizhenLakeModel.ts#L371)
1062. 围栏边的黑天鹅
   来源：[src/scenes/rpg/QizhenLakeModel.ts:372](../src/scenes/rpg/QizhenLakeModel.ts#L372)
1063. 纸条本体水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:373](../src/scenes/rpg/QizhenLakeModel.ts#L373)
1064. 黑天鹅追逐起点
   来源：[src/scenes/rpg/QizhenLakeModel.ts:375](../src/scenes/rpg/QizhenLakeModel.ts#L375)
1065. 浮排下的破损网框
   来源：[src/scenes/rpg/QizhenLakeModel.ts:377](../src/scenes/rpg/QizhenLakeModel.ts#L377)
1066. 小码头方向
   来源：[src/scenes/rpg/QizhenLakeModel.ts:378](../src/scenes/rpg/QizhenLakeModel.ts#L378)
1067. 湖心全景:朝北取景时西北柳岛与整片开阔水面入镜,船体落在画面下缘。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:466](../src/scenes/rpg/QizhenLakeModel.ts#L466)
1068. 小码头:木栈道、器材架与登船边入镜;徒步或乘艇都可取景。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:482](../src/scenes/rpg/QizhenLakeModel.ts#L482)
1069. 倒影水面
   来源：[src/scenes/rpg/QizhenLakeModel.ts:487](../src/scenes/rpg/QizhenLakeModel.ts#L487)
1070. 倒影水面:东侧倒影区入镜;水面平静时倒影完整,船速与侧倾大时水纹断开。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:493](../src/scenes/rpg/QizhenLakeModel.ts#L493)
1071. 黑天鹅围栏:从围栏外水域取景,黑天鹅在围栏内游动;鹅离开后只剩空围栏与水痕。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:505](../src/scenes/rpg/QizhenLakeModel.ts#L505)
1072. rpg\_qizhen\_intro\_seen\_requested
   来源：[src/scenes/rpg/QizhenLakeScene.ts:551](../src/scenes/rpg/QizhenLakeScene.ts#L551)
1073. {{qizhenContent.chase.caught}}{{qizhenContent.chase.failed}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1005](../src/scenes/rpg/QizhenLakeScene.ts#L1005)
1074. swan\_caught
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1007](../src/scenes/rpg/QizhenLakeScene.ts#L1007)
1075. {{qizhenContent.boarding.capsizeSameSide}}{{qizhenContent.chase.failed}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1036](../src/scenes/rpg/QizhenLakeScene.ts#L1036)
1076. 节奏钓取未能启动，道具已保留，请重试。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1853](../src/scenes/rpg/QizhenLakeScene.ts#L1853)
1077. 未通过：道具已保留。下次将扩大判定窗口并精简节拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2130](../src/scenes/rpg/QizhenLakeScene.ts#L2130)
1078. 未通过：道具已保留，靠近同一水纹可立即重试。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2131](../src/scenes/rpg/QizhenLakeScene.ts#L2131)
1079. {{qizhenContent.mist.darkPrompt}} {{formatRpgModeRequirement("light")}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2188](../src/scenes/rpg/QizhenLakeScene.ts#L2188)
1080. locker\_key
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2561](../src/scenes/rpg/QizhenLakeScene.ts#L2561)
1081. 浮排边的旧饲料盒被捞起并撬开。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2592](../src/scenes/rpg/QizhenLakeScene.ts#L2592)
1082. 饲料撒入围栏，黑天鹅把一枚磁性扣推到船边。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2593](../src/scenes/rpg/QizhenLakeScene.ts#L2593)
1083. 三处分支素材已合并，可以进行最终捕纸。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2598](../src/scenes/rpg/QizhenLakeScene.ts#L2598)
1084. player
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2898](../src/scenes/rpg/QizhenLakeScene.ts#L2898)
1085. 相机
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2907](../src/scenes/rpg/QizhenLakeScene.ts#L2907)
1086. 正在节奏钓取,收竿后再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2939](../src/scenes/rpg/QizhenLakeScene.ts#L2939)
1087. 黑天鹅正追着船尾,顾不上拍照。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2945](../src/scenes/rpg/QizhenLakeScene.ts#L2945)
1088. 这里要上船后才能取景。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2949](../src/scenes/rpg/QizhenLakeScene.ts#L2949)
1089. 船还没停稳,等一下再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2953](../src/scenes/rpg/QizhenLakeScene.ts#L2953)
1090. 先听完这段话,再打开相机。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2957](../src/scenes/rpg/QizhenLakeScene.ts#L2957)
1091. 这里构不成画面,再往{{nearest.label}}靠一靠。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2965](../src/scenes/rpg/QizhenLakeScene.ts#L2965)
1092. 河道里取景太窄,去大湖面或黑天鹅围栏旁再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2966](../src/scenes/rpg/QizhenLakeScene.ts#L2966)
1093. forced\_launch\_capsize
   来源：[src/scenes/rpg/QizhenLakeScene.ts:3417](../src/scenes/rpg/QizhenLakeScene.ts#L3417)；[src/scenes/rpg/QizhenLakeScene.ts:3430](../src/scenes/rpg/QizhenLakeScene.ts#L3430)
1094. 启真湖入口
   来源：[src/scenes/rpg/QizhenLoopScene.ts:45](../src/scenes/rpg/QizhenLoopScene.ts#L45)
1095. 查看入口
   来源：[src/scenes/rpg/QizhenLoopScene.ts:46](../src/scenes/rpg/QizhenLoopScene.ts#L46)
1096. 系统：还没确认湿纸指向的地点。先核对论坛、馆藏记录和地图线索。
   来源：[src/scenes/rpg/QizhenLoopScene.ts:47](../src/scenes/rpg/QizhenLoopScene.ts#L47)
1097. {{GATE\_ENTRY\_LABEL}} · {{formatRpgInteractionHint("进入启真湖")}}
   来源：[src/scenes/rpg/QizhenLoopScene.ts:206](../src/scenes/rpg/QizhenLoopScene.ts#L206)；[src/scenes/rpg/QizhenLoopScene.ts:241](../src/scenes/rpg/QizhenLoopScene.ts#L241)
1098. 启真湖雨天落水救援回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:60](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L60)
1099. 值班老师和安全员把落水学生拉回码头
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:71](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L71)
1100. 启真湖 · 雨天救援
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:81](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L81)
1101. 正在将落水者拉回码头
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:82](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L82)
1102. 正在载入救援回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:82](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L82)
1103. 跳过回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:88](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L88)
1104. 入口海报玻璃
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:93](../src/scenes/rpg/TheaterInteriorModel.ts#L93)
1105. 临时票打印机
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:111](../src/scenes/rpg/TheaterInteriorModel.ts#L111)
1106. 检票闸机右侧读票器
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:122](../src/scenes/rpg/TheaterInteriorModel.ts#L122)；[src/scenes/rpg/TheaterInteriorScene.ts:186](../src/scenes/rpg/TheaterInteriorScene.ts#L186)
1107. 开场节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:135](../src/scenes/rpg/TheaterInteriorModel.ts#L135)
1108. 追光节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:136](../src/scenes/rpg/TheaterInteriorModel.ts#L136)
1109. 终场节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:137](../src/scenes/rpg/TheaterInteriorModel.ts#L137)
1110. 剧院灯光控制台
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:140](../src/scenes/rpg/TheaterInteriorModel.ts#L140)
1111. 后台道具箱
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:155](../src/scenes/rpg/TheaterInteriorModel.ts#L155)
1112. 道具箱旁票据扫描器
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:165](../src/scenes/rpg/TheaterInteriorModel.ts#L165)；[src/scenes/rpg/TheaterInteriorScene.ts:187](../src/scenes/rpg/TheaterInteriorScene.ts#L187)
1113. 后台通风口
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:180](../src/scenes/rpg/TheaterInteriorModel.ts#L180)；[src/scenes/rpg/TheaterInteriorScene.ts:188](../src/scenes/rpg/TheaterInteriorScene.ts#L188)
1114. 剧院出口
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:193](../src/scenes/rpg/TheaterInteriorModel.ts#L193)；[src/scenes/rpg/TheaterInteriorScene.ts:193](../src/scenes/rpg/TheaterInteriorScene.ts#L193)
1115. 灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:124](../src/scenes/rpg/TheaterInteriorScene.ts#L124)
1116. 检票员
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:124](../src/scenes/rpg/TheaterInteriorScene.ts#L124)
1117. 取票机
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:124](../src/scenes/rpg/TheaterInteriorScene.ts#L124)；[src/scenes/rpg/TheaterInteriorScene.ts:190](../src/scenes/rpg/TheaterInteriorScene.ts#L190)
1118. 手机系统
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:124](../src/scenes/rpg/TheaterInteriorScene.ts#L124)
1119. 入口海报
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:185](../src/scenes/rpg/TheaterInteriorScene.ts#L185)
1120. 灯光控制台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:189](../src/scenes/rpg/TheaterInteriorScene.ts#L189)
1121. 节目单
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:191](../src/scenes/rpg/TheaterInteriorScene.ts#L191)
1122. 道具箱
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:192](../src/scenes/rpg/TheaterInteriorScene.ts#L192)
1123. 验票
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:637](../src/scenes/rpg/TheaterInteriorScene.ts#L637)
1124. theater\_decoy\_inspect\_requested
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1091](../src/scenes/rpg/TheaterInteriorScene.ts#L1091)
1125. dark
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1211](../src/scenes/rpg/TheaterInteriorScene.ts#L1211)；[src/scenes/rpg/TheaterInteriorScene.ts:1213](../src/scenes/rpg/TheaterInteriorScene.ts#L1213)
1126. 查看海报栏
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1283](../src/scenes/rpg/TheaterInteriorScene.ts#L1283)
1127. 油渍纸巾 → 入口海报
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1283](../src/scenes/rpg/TheaterInteriorScene.ts#L1283)
1128. 查看取票机
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1286](../src/scenes/rpg/TheaterInteriorScene.ts#L1286)；[src/scenes/rpg/TheaterInteriorScene.ts:1289](../src/scenes/rpg/TheaterInteriorScene.ts#L1289)
1129. 输入取票码
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1288](../src/scenes/rpg/TheaterInteriorScene.ts#L1288)
1130. 临时观演票 → 右侧验票槽
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1291](../src/scenes/rpg/TheaterInteriorScene.ts#L1291)
1131. 与检票员对话
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1291](../src/scenes/rpg/TheaterInteriorScene.ts#L1291)
1132. 查看残影
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1293](../src/scenes/rpg/TheaterInteriorScene.ts#L1293)
1133. 取得节目单残页
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1293](../src/scenes/rpg/TheaterInteriorScene.ts#L1293)
1134. 操作灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1295](../src/scenes/rpg/TheaterInteriorScene.ts#L1295)
1135. 追光灯遥控器 → 灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1295](../src/scenes/rpg/TheaterInteriorScene.ts#L1295)
1136. 查看道具箱
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1297](../src/scenes/rpg/TheaterInteriorScene.ts#L1297)
1137. 检查票据扫描器
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1299](../src/scenes/rpg/TheaterInteriorScene.ts#L1299)
1138. 临时观演票 → 票据扫描口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1299](../src/scenes/rpg/TheaterInteriorScene.ts#L1299)
1139. 离开剧院
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1301](../src/scenes/rpg/TheaterInteriorScene.ts#L1301)
1140. 检查后台通风口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1302](../src/scenes/rpg/TheaterInteriorScene.ts#L1302)
1141. 荧光粉刷 → 后台通风口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1302](../src/scenes/rpg/TheaterInteriorScene.ts#L1302)
1142. 票已退回：请拖到检票闸机右侧发蓝光的「验票」读票器框内。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1372](../src/scenes/rpg/TheaterInteriorScene.ts#L1372)
1143. 票已退回：请拖到道具箱旁发蓝光的票据扫描口框内。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1374](../src/scenes/rpg/TheaterInteriorScene.ts#L1374)
1144. 票已退回：当前阶段没有临时观演票的使用点。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1375](../src/scenes/rpg/TheaterInteriorScene.ts#L1375)
1145. 道具没有放到当前阶段对应的真实物体。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1376](../src/scenes/rpg/TheaterInteriorScene.ts#L1376)
1146. temporaryTheaterTicket
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1407](../src/scenes/rpg/TheaterInteriorScene.ts#L1407)
1147. gate
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1408](../src/scenes/rpg/TheaterInteriorScene.ts#L1408)
1148. 票已退回；请靠近读票器。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1409](../src/scenes/rpg/TheaterInteriorScene.ts#L1409)
1149. 票已退回；请靠近扫描器。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1410](../src/scenes/rpg/TheaterInteriorScene.ts#L1410)
1150. 退格
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1445](../src/scenes/rpg/TheaterInteriorScene.ts#L1445)
1151. 提交
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1449](../src/scenes/rpg/TheaterInteriorScene.ts#L1449)；[src/scenes/rpg/TheaterInteriorScene.ts:1495](../src/scenes/rpg/TheaterInteriorScene.ts#L1495)
1152. 撤回
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1488](../src/scenes/rpg/TheaterInteriorScene.ts#L1488)
1153. 清空
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1492](../src/scenes/rpg/TheaterInteriorScene.ts#L1492)
1154. 第 {{round + 1}} / 3 轮 · 观察
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1764](../src/scenes/rpg/TheaterInteriorScene.ts#L1764)
1155. 观察尾迹，记住最后一个灯区。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1771](../src/scenes/rpg/TheaterInteriorScene.ts#L1771)
1156. 右
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1837](../src/scenes/rpg/TheaterInteriorScene.ts#L1837)
1157. 中
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1837](../src/scenes/rpg/TheaterInteriorScene.ts#L1837)
1158. 左
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1837](../src/scenes/rpg/TheaterInteriorScene.ts#L1837)
1159. 第 {{round + 1}} / 3 轮 · 预置
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1971](../src/scenes/rpg/TheaterInteriorScene.ts#L1971)
1160. 预置追光灯
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1972](../src/scenes/rpg/TheaterInteriorScene.ts#L1972)
1161. 拖动下方滑轨，或按 ← / → 移动。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1973](../src/scenes/rpg/TheaterInteriorScene.ts#L1973)
1162. 深色观察可核对尾迹；切至浅色操作后启动追光灯。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1991](../src/scenes/rpg/TheaterInteriorScene.ts#L1991)
1163. Tab 切换模式；切换不会重置本轮观察。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1993](../src/scenes/rpg/TheaterInteriorScene.ts#L1993)
1164. 浅色操作已就绪，追光灯正在启动。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1998](../src/scenes/rpg/TheaterInteriorScene.ts#L1998)
1165. 第 {{round + 1}} / 3 轮 · 锁定
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2019](../src/scenes/rpg/TheaterInteriorScene.ts#L2019)
1166. 断裂尾迹是假残影。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2111](../src/scenes/rpg/TheaterInteriorScene.ts#L2111)
1167. 锁定中，保持照射。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2115](../src/scenes/rpg/TheaterInteriorScene.ts#L2115)
1168. 光圈脱离纸条，重新锁定。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2118](../src/scenes/rpg/TheaterInteriorScene.ts#L2118)
1169. 第 {{hitCount}} / 3 轮 · 命中
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2233](../src/scenes/rpg/TheaterInteriorScene.ts#L2233)
1170. {{theaterContent.spotlight.hit}} 已命中 {{hitCount}} / 3
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2234](../src/scenes/rpg/TheaterInteriorScene.ts#L2234)
1171. 连续锁定完成。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2235](../src/scenes/rpg/TheaterInteriorScene.ts#L2235)
1172. 第 {{this.runtime.getState().theaterHunt.spotlightRound + 1}} / 3 轮 · 重试
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2303](../src/scenes/rpg/TheaterInteriorScene.ts#L2303)
1173. 保持已完成轮次，重新观察本轮。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2309](../src/scenes/rpg/TheaterInteriorScene.ts#L2309)
1174. 手机系统：
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2477](../src/scenes/rpg/TheaterInteriorScene.ts#L2477)
1175. {{name}}：
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2483](../src/scenes/rpg/TheaterInteriorScene.ts#L2483)

## 3.5章过渡

1. 状态栏
   来源：[src/components/StatusBar.tsx:29](../src/components/StatusBar.tsx#L29)
2. 状态时间已冻结，等待旧钟成为时间来源
   来源：[src/components/StatusBar.tsx:33](../src/components/StatusBar.tsx#L33)
3. 时间不可信
   来源：[src/components/StatusBar.tsx:37](../src/components/StatusBar.tsx#L37)
4. 不可信
   来源：[src/components/StatusBar.tsx:38](../src/components/StatusBar.tsx#L38)
5. completed
   来源：[src/core/QuestModel.ts:713](../src/core/QuestModel.ts#L713)
6. pending
   来源：[src/core/QuestModel.ts:713](../src/core/QuestModel.ts#L713)
7. 风大起来了，我该回去了。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:25](../src/data/chapter3-interlude-voice-memos.audio.content.json#L25)
8. The wind's picking up. I should head back.
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:26](../src/data/chapter3-interlude-voice-memos.audio.content.json#L26)
9. 东区食堂即将关闭，请带好随身物品。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:38](../src/data/chapter3-interlude-voice-memos.audio.content.json#L38)
10. East Canteen is closing. Please collect your belongings.
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:39](../src/data/chapter3-interlude-voice-memos.audio.content.json#L39)
11. 今晚的演出已经结束，请从东侧前厅离场。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:51](../src/data/chapter3-interlude-voice-memos.audio.content.json#L51)
12. The evening performance has ended. Please leave through the east foyer.
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:52](../src/data/chapter3-interlude-voice-memos.audio.content.json#L52)
13. 阅览室将在十分钟后关闭，请检查随身物品。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:64](../src/data/chapter3-interlude-voice-memos.audio.content.json#L64)
14. The reading rooms will close in ten minutes. Please check your belongings.
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:65](../src/data/chapter3-interlude-voice-memos.audio.content.json#L65)
15. CLIP D7
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:76](../src/data/chapter3-interlude-voice-memos.audio.content.json#L76)
16. 22:37:05
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:78](../src/data/chapter3-interlude-voice-memos.audio.content.json#L78)
17. 近处水声、交替桨声，男声说风大，要回去。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:79](../src/data/chapter3-interlude-voice-memos.audio.content.json#L79)
18. 近处连续水声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:87](../src/data/chapter3-interlude-voice-memos.audio.content.json#L87)
19. 交替拨水声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:88](../src/data/chapter3-interlude-voice-memos.audio.content.json#L88)
20. 近处男声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:89](../src/data/chapter3-interlude-voice-memos.audio.content.json#L89)
21. 风声逐渐增强
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:90](../src/data/chapter3-interlude-voice-memos.audio.content.json#L90)
22. CLIP 91
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:103](../src/data/chapter3-interlude-voice-memos.audio.content.json#L103)
23. 船底短促擦过硬岸，随后近水声减弱。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:106](../src/data/chapter3-interlude-voice-memos.audio.content.json#L106)
24. 近处水声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:114](../src/data/chapter3-interlude-voice-memos.audio.content.json#L114)
25. 硬面短促擦碰
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:115](../src/data/chapter3-interlude-voice-memos.audio.content.json#L115)
26. 轻微金属碰响
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:116](../src/data/chapter3-interlude-voice-memos.audio.content.json#L116)
27. 稀疏水声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:117](../src/data/chapter3-interlude-voice-memos.audio.content.json#L117)
28. CLIP 4C
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:130](../src/data/chapter3-interlude-voice-memos.audio.content.json#L130)
29. 玻璃门开合，近处女声提醒地面刚拖过。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:133](../src/data/chapter3-interlude-voice-memos.audio.content.json#L133)
30. 玻璃门开合
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:141](../src/data/chapter3-interlude-voice-memos.audio.content.json#L141)
31. 近处女声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:142](../src/data/chapter3-interlude-voice-memos.audio.content.json#L142)
32. 清洁设备吸水声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:143](../src/data/chapter3-interlude-voice-memos.audio.content.json#L143)
33. 拖布滑过湿地
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:144](../src/data/chapter3-interlude-voice-memos.audio.content.json#L144)
34. CLIP 3A
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:157](../src/data/chapter3-interlude-voice-memos.audio.content.json#L157)
35. 22:45:00
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:159](../src/data/chapter3-interlude-voice-memos.audio.content.json#L159)
36. 远处男声通知北教清楼，广播静电后传来断电声。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:160](../src/data/chapter3-interlude-voice-memos.audio.content.json#L160)
37. 广播静电
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:168](../src/data/chapter3-interlude-voice-memos.audio.content.json#L168)
38. 远处男声广播
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:169](../src/data/chapter3-interlude-voice-memos.audio.content.json#L169)
39. 电力停止声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:170](../src/data/chapter3-interlude-voice-memos.audio.content.json#L170)
40. CLIP B4
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:182](../src/data/chapter3-interlude-voice-memos.audio.content.json#L182)
41. 托盘连续滑动，女声提示东区食堂关闭。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:185](../src/data/chapter3-interlude-voice-memos.audio.content.json#L185)
42. 托盘滑动与轻碰
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:193](../src/data/chapter3-interlude-voice-memos.audio.content.json#L193)
43. 公共女声提醒
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:194](../src/data/chapter3-interlude-voice-memos.audio.content.json#L194)；[src/data/chapter3-interlude-voice-memos.audio.content.json:221](../src/data/chapter3-interlude-voice-memos.audio.content.json#L221)；[src/data/chapter3-interlude-voice-memos.audio.content.json:248](../src/data/chapter3-interlude-voice-memos.audio.content.json#L248)
44. 小车轮滚动
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:195](../src/data/chapter3-interlude-voice-memos.audio.content.json#L195)
45. 电子确认短音
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:196](../src/data/chapter3-interlude-voice-memos.audio.content.json#L196)
46. CLIP E2
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:209](../src/data/chapter3-interlude-voice-memos.audio.content.json#L209)
47. 检票器连续短响，女声提示演出结束。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:212](../src/data/chapter3-interlude-voice-memos.audio.content.json#L212)
48. 检票器连续短响
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:220](../src/data/chapter3-interlude-voice-memos.audio.content.json#L220)
49. 设备轻响
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:222](../src/data/chapter3-interlude-voice-memos.audio.content.json#L222)
50. 纸张取放声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:223](../src/data/chapter3-interlude-voice-memos.audio.content.json#L223)
51. CLIP 6F
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:236](../src/data/chapter3-interlude-voice-memos.audio.content.json#L236)
52. 门禁单响，女声提示阅览室十分钟后关闭。
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:239](../src/data/chapter3-interlude-voice-memos.audio.content.json#L239)
53. 门禁单次短响
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:247](../src/data/chapter3-interlude-voice-memos.audio.content.json#L247)
54. 键按与检索响应
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:249](../src/data/chapter3-interlude-voice-memos.audio.content.json#L249)
55. 纸条滑出声
   来源：[src/data/chapter3-interlude-voice-memos.audio.content.json:250](../src/data/chapter3-interlude-voice-memos.audio.content.json#L250)
56. 待恢复
   来源：[src/data/chapter3InterludeContent.ts:63](../src/data/chapter3InterludeContent.ts#L63)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:153](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L153)
57. 待核验时间窗
   来源：[src/data/chapter3InterludeContent.ts:64](../src/data/chapter3InterludeContent.ts#L64)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:133](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L133)
58. CC98 划船记录
   来源：[src/data/chapter3InterludeContent.ts:68](../src/data/chapter3InterludeContent.ts#L68)
59. 最后一条离湖回复提供了记录起点。
   来源：[src/data/chapter3InterludeContent.ts:70](../src/data/chapter3InterludeContent.ts#L70)
60. 恢复照片
   来源：[src/data/chapter3InterludeContent.ts:74](../src/data/chapter3InterludeContent.ts#L74)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:171](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L171)
61. 时间缺失
   来源：[src/data/chapter3InterludeContent.ts:75](../src/data/chapter3InterludeContent.ts#L75)
62. 三张残片记录了纸条位置的连续变化。
   来源：[src/data/chapter3InterludeContent.ts:76](../src/data/chapter3InterludeContent.ts#L76)
63. 照片
   来源：[src/data/chapter3InterludeContent.ts:77](../src/data/chapter3InterludeContent.ts#L77)
64. 夜间接入记录
   来源：[src/data/chapter3InterludeContent.ts:80](../src/data/chapter3InterludeContent.ts#L80)
65. 区间末段
   来源：[src/data/chapter3InterludeContent.ts:81](../src/data/chapter3InterludeContent.ts#L81)
66. 通知、路线截图和短会话共同缩小了地点范围。
   来源：[src/data/chapter3InterludeContent.ts:82](../src/data/chapter3InterludeContent.ts#L82)
67. 微信与校园网络
   来源：[src/data/chapter3InterludeContent.ts:83](../src/data/chapter3InterludeContent.ts#L83)
68. 广播录音
   来源：[src/data/chapter3InterludeContent.ts:86](../src/data/chapter3InterludeContent.ts#L86)
69. 广播和断电声提供了记录终点。
   来源：[src/data/chapter3InterludeContent.ts:88](../src/data/chapter3InterludeContent.ts#L88)
70. 录音
   来源：[src/data/chapter3InterludeContent.ts:89](../src/data/chapter3InterludeContent.ts#L89)
71. 启真湖小码头
   来源：[src/data/chapter3InterludeContent.ts:98](../src/data/chapter3InterludeContent.ts#L98)
72. 剧场前厅
   来源：[src/data/chapter3InterludeContent.ts:99](../src/data/chapter3InterludeContent.ts#L99)
73. 基础图书馆南侧
   来源：[src/data/chapter3InterludeContent.ts:100](../src/data/chapter3InterludeContent.ts#L100)
74. 段永平教学楼 A 楼一层
   来源：[src/data/chapter3InterludeContent.ts:101](../src/data/chapter3InterludeContent.ts#L101)
75. 录音末段出现室内广播和断电声，湖面环境无法解释这组声音。
   来源：[src/data/chapter3InterludeContent.ts:104](../src/data/chapter3InterludeContent.ts#L104)
76. 末段短会话的接入点编号与剧场网络记录不一致。
   来源：[src/data/chapter3InterludeContent.ts:105](../src/data/chapter3InterludeContent.ts#L105)
77. 闭楼通知和入口截图指向另一组楼宇入口规则。
   来源：[src/data/chapter3InterludeContent.ts:106](../src/data/chapter3InterludeContent.ts#L106)
78. 取餐编号
   来源：[src/data/chapter3InterludeContent.ts:112](../src/data/chapter3InterludeContent.ts#L112)
79. 食堂 0755
   来源：[src/data/chapter3InterludeContent.ts:112](../src/data/chapter3InterludeContent.ts#L112)
80. 更早的独立记录
   来源：[src/data/chapter3InterludeContent.ts:113](../src/data/chapter3InterludeContent.ts#L113)
81. 剧场 08:32
   来源：[src/data/chapter3InterludeContent.ts:113](../src/data/chapter3InterludeContent.ts#L113)
82. 未同步的本机时钟
   来源：[src/data/chapter3InterludeContent.ts:114](../src/data/chapter3InterludeContent.ts#L114)
83. 状态栏 07:55:23
   来源：[src/data/chapter3InterludeContent.ts:114](../src/data/chapter3InterludeContent.ts#L114)
84. 未同步的七分五十五秒
   来源：[src/data/chapter3InterludeContent.ts:119](../src/data/chapter3InterludeContent.ts#L119)
85. 打开未同步记录
   来源：[src/data/chapter3InterludeContent.ts:123](../src/data/chapter3InterludeContent.ts#L123)
86. 手机首页出现了一条记录恢复通知。
   来源：[src/data/chapter3InterludeContent.ts:125](../src/data/chapter3InterludeContent.ts#L125)
87. 打开记录恢复页，查看目前缺失的时间与证据。
   来源：[src/data/chapter3InterludeContent.ts:126](../src/data/chapter3InterludeContent.ts#L126)
88. 进入“记录恢复”，开始核对离湖后的记录。
   来源：[src/data/chapter3InterludeContent.ts:127](../src/data/chapter3InterludeContent.ts#L127)
89. 恢复时间窗起点
   来源：[src/data/chapter3InterludeContent.ts:133](../src/data/chapter3InterludeContent.ts#L133)
90. 先寻找能够证明离湖时刻的原始记录。
   来源：[src/data/chapter3InterludeContent.ts:135](../src/data/chapter3InterludeContent.ts#L135)
91. CC98 划船记录保留了带时间的最后回复。
   来源：[src/data/chapter3InterludeContent.ts:136](../src/data/chapter3InterludeContent.ts#L136)
92. 打开划船记录帖并保存最后一条离湖回复。
   来源：[src/data/chapter3InterludeContent.ts:137](../src/data/chapter3InterludeContent.ts#L137)
93. 恢复剩余证据
   来源：[src/data/chapter3InterludeContent.ts:143](../src/data/chapter3InterludeContent.ts#L143)
94. 照片、录音、消息和网络记录可以分别处理，完成顺序不影响恢复结果。
   来源：[src/data/chapter3InterludeContent.ts:145](../src/data/chapter3InterludeContent.ts#L145)
95. 任务栏会分别记录四类证据的状态，每一行都能直接打开对应应用。
   来源：[src/data/chapter3InterludeContent.ts:146](../src/data/chapter3InterludeContent.ts#L146)
96. 四类证据全部恢复后，再回到记录恢复页核验旧时间。
   来源：[src/data/chapter3InterludeContent.ts:147](../src/data/chapter3InterludeContent.ts#L147)
97. 排除旧时间记录
   来源：[src/data/chapter3InterludeContent.ts:153](../src/data/chapter3InterludeContent.ts#L153)
98. 三条旧记录中，数字的含义和时钟可信度并不相同。
   来源：[src/data/chapter3InterludeContent.ts:155](../src/data/chapter3InterludeContent.ts#L155)
99. 分别判断编号、独立事件和未同步时钟能否作为本次时间。
   来源：[src/data/chapter3InterludeContent.ts:156](../src/data/chapter3InterludeContent.ts#L156)
100. 为三条旧时间各选择对应的排除理由。
   来源：[src/data/chapter3InterludeContent.ts:157](../src/data/chapter3InterludeContent.ts#L157)
101. 根据证据确认目的地
   来源：[src/data/chapter3InterludeContent.ts:163](../src/data/chapter3InterludeContent.ts#L163)
102. 比较每个候选地点与四项证据是否存在冲突。
   来源：[src/data/chapter3InterludeContent.ts:165](../src/data/chapter3InterludeContent.ts#L165)
103. 同时核对水面离开、室内路线、网络记录和闭楼广播。
   来源：[src/data/chapter3InterludeContent.ts:166](../src/data/chapter3InterludeContent.ts#L166)
104. 在记录恢复页选择唯一没有证据冲突的地点。
   来源：[src/data/chapter3InterludeContent.ts:167](../src/data/chapter3InterludeContent.ts#L167)
105. 播放恢复回放
   来源：[src/data/chapter3InterludeContent.ts:173](../src/data/chapter3InterludeContent.ts#L173)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:245](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L245)
106. 目的地已经确认，可以播放恢复结果。
   来源：[src/data/chapter3InterludeContent.ts:175](../src/data/chapter3InterludeContent.ts#L175)
107. 回放结束后会进入第四章任务卡。
   来源：[src/data/chapter3InterludeContent.ts:176](../src/data/chapter3InterludeContent.ts#L176)
108. 在记录恢复页启动回放。
   来源：[src/data/chapter3InterludeContent.ts:177](../src/data/chapter3InterludeContent.ts#L177)
109. {{startLabel}} — {{endLabel}}
   来源：[src/modules/ChapterThreeInterludeModel.ts:90](../src/modules/ChapterThreeInterludeModel.ts#L90)
110. 照片线索
   来源：[src/modules/ChapterThreeInterludeModel.ts:109](../src/modules/ChapterThreeInterludeModel.ts#L109)
111. 录音线索
   来源：[src/modules/ChapterThreeInterludeModel.ts:115](../src/modules/ChapterThreeInterludeModel.ts#L115)
112. 消息线索
   来源：[src/modules/ChapterThreeInterludeModel.ts:121](../src/modules/ChapterThreeInterludeModel.ts#L121)
113. 网络记录
   来源：[src/modules/ChapterThreeInterludeModel.ts:127](../src/modules/ChapterThreeInterludeModel.ts#L127)
114. 时间窗起点仍待恢复。
   来源：[src/modules/ChapterThreeInterludeModel.ts:165](../src/modules/ChapterThreeInterludeModel.ts#L165)
115. 还有 {{branchProgress.total - branchProgress.completed}} 类证据待恢复。
   来源：[src/modules/ChapterThreeInterludeModel.ts:167](../src/modules/ChapterThreeInterludeModel.ts#L167)
116. 还有 {{3 - interlude.rejectedDecoyIds.length}} 条旧时间需要核验。
   来源：[src/modules/ChapterThreeInterludeModel.ts:169](../src/modules/ChapterThreeInterludeModel.ts#L169)
117. 还需从 {{chapterThreeInterludePublicContent.destinationCandidates.length}} 个候选地点中排除冲突。
   来源：[src/modules/ChapterThreeInterludeModel.ts:171](../src/modules/ChapterThreeInterludeModel.ts#L171)
118. 时间与地点已经完成交叉核验。
   来源：[src/modules/ChapterThreeInterludeModel.ts:173](../src/modules/ChapterThreeInterludeModel.ts#L173)
119. 检测到 7 分 55 秒未同步记录。
   来源：[src/modules/ChapterThreeInterludeModel.ts:184](../src/modules/ChapterThreeInterludeModel.ts#L184)
120. 恢复工具尚未建立这条记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:417](../src/scenes/phone/P02_CC98/index.tsx#L417)
121. 启真湖划船记录收尾
   来源：[src/scenes/phone/P02_CC98/index.tsx:421](../src/scenes/phone/P02_CC98/index.tsx#L421)
122. 退出帖子，返回记录恢复
   来源：[src/scenes/phone/P02_CC98/index.tsx:426](../src/scenes/phone/P02_CC98/index.tsx#L426)
123. CC98小程序
   来源：[src/scenes/phone/P02_CC98/index.tsx:429](../src/scenes/phone/P02_CC98/index.tsx#L429)
124. 林星宇
   来源：[src/scenes/phone/P02_CC98/index.tsx:434](../src/scenes/phone/P02_CC98/index.tsx#L434)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:124](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L124)
125. 楼主 · 22:37
   来源：[src/scenes/phone/P02_CC98/index.tsx:434](../src/scenes/phone/P02_CC98/index.tsx#L434)
126. 舟
   来源：[src/scenes/phone/P02_CC98/index.tsx:434](../src/scenes/phone/P02_CC98/index.tsx#L434)
127. 启真湖划船记录｜风景很好，返程提前了
   来源：[src/scenes/phone/P02_CC98/index.tsx:435](../src/scenes/phone/P02_CC98/index.tsx#L435)
128. 退出
   来源：[src/scenes/phone/P02_CC98/index.tsx:655](../src/scenes/phone/P02_CC98/index.tsx#L655)；[src/scenes/phone/P15_Zjuding/index.tsx:1219](../src/scenes/phone/P15_Zjuding/index.tsx#L1219)
129. 找到 4 条候选记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:677](../src/scenes/phone/P02_CC98/index.tsx#L677)
130. 需要能说明纸张状态的实物线索。
   来源：[src/scenes/phone/P02_CC98/index.tsx:683](../src/scenes/phone/P02_CC98/index.tsx#L683)
131. 找到 1 条刚发布的目击帖。
   来源：[src/scenes/phone/P02_CC98/index.tsx:687](../src/scenes/phone/P02_CC98/index.tsx#L687)
132. 当前无法记录这条目击信息。
   来源：[src/scenes/phone/P02_CC98/index.tsx:692](../src/scenes/phone/P02_CC98/index.tsx#L692)
133. {{qizhenContent.locationSearch.cc98.system}} / {{qizhenContent.locationSearch.cc98.player}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:695](../src/scenes/phone/P02_CC98/index.tsx#L695)
134. 小雨。局部黏着物可能松动。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:53](../src/scenes/phone/P13_PhoneHome/index.tsx#L53)
135. 多云。启真湖小码头降水已经停止。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:54](../src/scenes/phone/P13_PhoneHome/index.tsx#L54)
136. accepted
   来源：[src/scenes/phone/P14_Wechat/index.tsx:47](../src/scenes/phone/P14_Wechat/index.tsx#L47)；[src/scenes/phone/P14_Wechat/index.tsx:55](../src/scenes/phone/P14_Wechat/index.tsx#L55)；[src/scenes/phone/P15_Zjuding/index.tsx:383](../src/scenes/phone/P15_Zjuding/index.tsx#L383)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:56](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L56)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:91](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L91)；[src/scenes/phone/P21_VoiceMemos/index.tsx:331](../src/scenes/phone/P21_VoiceMemos/index.tsx#L331)
137. already\_complete
   来源：[src/scenes/phone/P14_Wechat/index.tsx:47](../src/scenes/phone/P14_Wechat/index.tsx#L47)；[src/scenes/phone/P14_Wechat/index.tsx:55](../src/scenes/phone/P14_Wechat/index.tsx#L55)；[src/scenes/phone/P15_Zjuding/index.tsx:383](../src/scenes/phone/P15_Zjuding/index.tsx#L383)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:91](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L91)；[src/scenes/phone/P21_VoiceMemos/index.tsx:331](../src/scenes/phone/P21_VoiceMemos/index.tsx#L331)
138. 公众号通知已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:48](../src/scenes/phone/P14_Wechat/index.tsx#L48)
139. 先在记录恢复中确认划船帖的离湖时间。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:49](../src/scenes/phone/P14_Wechat/index.tsx#L49)；[src/scenes/phone/P14_Wechat/index.tsx:59](../src/scenes/phone/P14_Wechat/index.tsx#L59)；[src/scenes/phone/P15_Zjuding/index.tsx:385](../src/scenes/phone/P15_Zjuding/index.tsx#L385)
140. 入口变化已截图：东侧关闭，西侧主入口可通行。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:56](../src/scenes/phone/P14_Wechat/index.tsx#L56)
141. incorrect
   来源：[src/scenes/phone/P14_Wechat/index.tsx:57](../src/scenes/phone/P14_Wechat/index.tsx#L57)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:93](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L93)
142. 这两条消息还不能拼出可通行入口。需要同时确认封闭方向和可进入方向。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:58](../src/scenes/phone/P14_Wechat/index.tsx#L58)
143. 紫金港楼宇服务公众号通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:76](../src/scenes/phone/P14_Wechat/index.tsx#L76)
144. 返回微信消息列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:78](../src/scenes/phone/P14_Wechat/index.tsx#L78)
145. 文件传输助手里还没有两张导视板照片。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:736](../src/scenes/phone/P14_Wechat/index.tsx#L736)
146. 微信
   来源：[src/scenes/phone/P14_Wechat/index.tsx:759](../src/scenes/phone/P14_Wechat/index.tsx#L759)
147. 退出微信，返回手机主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:767](../src/scenes/phone/P14_Wechat/index.tsx#L767)
148. 聊天(
   来源：[src/scenes/phone/P14_Wechat/index.tsx:769](../src/scenes/phone/P14_Wechat/index.tsx#L769)
149. 已登录 2 台设备 ›
   来源：[src/scenes/phone/P14_Wechat/index.tsx:774](../src/scenes/phone/P14_Wechat/index.tsx#L774)
150. 22:44:57
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:332](../src/scenes/phone/P15_Zjuding/index.tsx#L332)
151. 北教学区 A 区 · 楼宇名待核验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:334](../src/scenes/phone/P15_Zjuding/index.tsx#L334)
152. 段永平教学楼 A 楼一层大厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:334](../src/scenes/phone/P15_Zjuding/index.tsx#L334)
153. 3 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:335](../src/scenes/phone/P15_Zjuding/index.tsx#L335)
154. 未知设备 · 身份来源待核验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:336](../src/scenes/phone/P15_Zjuding/index.tsx#L336)
155. 这条接入记录已加入证据矩阵；地点确认时会统一核对冲突。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:384](../src/scenes/phone/P15_Zjuding/index.tsx#L384)
156. 浙大钉校园网络记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:390](../src/scenes/phone/P15_Zjuding/index.tsx#L390)
157. 退出浙大钉，返回手机主页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:392](../src/scenes/phone/P15_Zjuding/index.tsx#L392)
158. 设备接入记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:393](../src/scenes/phone/P15_Zjuding/index.tsx#L393)
159. 浙大钉 · 网络服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:393](../src/scenes/phone/P15_Zjuding/index.tsx#L393)
160. 查询范围 · 来源进度
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:398](../src/scenes/phone/P15_Zjuding/index.tsx#L398)
161. /3；每项条件会立即更新结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:400](../src/scenes/phone/P15_Zjuding/index.tsx#L400)
162. 有效筛选维度
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:400](../src/scenes/phone/P15_Zjuding/index.tsx#L400)
163. 浙江大学统一身份认证
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1256](../src/scenes/phone/P15_Zjuding/index.tsx#L1256)
164. 地点记录待核验
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:256](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L256)
165. 校园地图已接入 {{state.qizhenLake.mapClueIds.length}}/3 条公开线索。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:257](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L257)
166. 打开地图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:258](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L258)
167. 未同步记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:265](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L265)
168. 设备接入记录已保存。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:267](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L267)
169. 设备接入记录仍待核验。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:268](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L268)
170. 请填写访客姓名和到访日期，再生成本机预览。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:290](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L290)
171. 预览草稿已保存到本次会话，没有提交到校务系统。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:297](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L297)
172. 已生成本机预览，当前浏览器不允许保存会话草稿。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:298](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L298)
173. 访客预览草稿已清空。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:305](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L305)
174. 0755 是取餐编号，不能作为夜间时间。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:19](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L19)
175. 08:32 来自更早的独立抢票记录。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:20](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L20)
176. 07:55:23 是未同步的本机时钟值。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:21](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L21)
177. 这是编号，不是本段记录的时间
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:25](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L25)
178. 这是更早的独立事件
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:26](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L26)
179. 这是本机冻结值，不能代表实际时间
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:27](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L27)
180. 22:44:12 · 启真湖小码头
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:38](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L38)
181. 22:44:31 · 剧场前厅
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:39](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L39)
182. 22:43:11 · 基础图书馆南侧
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:40](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L40)
183. 22:44:57 · 北教学区 A 区
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:41](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L41)
184. 当前无法恢复这段记录。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:56](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L56)
185. 恢复工具已打开。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:56](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L56)
186. 地点与四项证据一致，恢复结果已确认。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:67](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L67)
187. 先完成四类证据与旧时间核验。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:71](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L71)
188. record\_0755
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:75](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L75)
189. 证据矩阵发现：保存的接入记录与该地点冲突，请返回网络记录重新选择。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:76](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L76)
190. 当前证据还不足以确认这个地点。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:77](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L77)
191. 恢复回放尚未解锁。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:86](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L86)
192. 这条理由与记录来源不匹配。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:94](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L94)
193. 四项证据还没收齐。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:95](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L95)
194. 未同步记录恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:100](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L100)
195. 退出记录恢复，返回手机主页
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:104](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L104)
196. RECOVERY 03.5
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:107](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L107)
197. 检测到 7 分 55 秒未同步记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:115](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L115)
198. 启真湖的离开记录仍在，后面的去向没有写入。手机时钟与带来源的记录不一致，不能直接采用。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:116](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L116)
199. 7 帧
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:118](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L118)
200. 媒体缓存
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:118](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L118)
201. 3 条
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:119](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L119)
202. 短会话
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:119](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L119)
203. 12 条
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:120](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L120)
204. 通知归档
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:120](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L120)
205. 时间索引
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:121](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L121)
206. 异常
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:121](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L121)
207. 我离开湖边以后，去了哪里？
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:124](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L124)
208. 系统
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:125](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L125)
209. 先从能够核对来源的记录开始。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:125](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L125)
210. 打开恢复工具
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:127](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L127)
211. 左右边界分别由原始证据恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:140](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L140)
212. 恢复证据 {{viewModel.evidenceProgress.completed}}/{{viewModel.evidenceProgress.total}}
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:145](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L145)
213. 未完成
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:154](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L154)
214. 已记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:154](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L154)
215. 打开对应来源，完成当前证据核验。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:156](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L156)
216. 打开证据来源
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:157](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L157)
217. 重新打开来源
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:157](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L157)
218. 先恢复时间窗起点
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:165](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L165)
219. 划船帖的最后一条回复保留了带来源的离湖时间。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:166](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L166)
220. 去 CC98 收尾
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:167](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L167)
221. 证据来源
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:170](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L170)
222. 整理录音
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:172](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L172)
223. 查看微信
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:173](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L173)
224. 核对网络
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:174](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L174)
225. 排除旧时间
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:180](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L180)
226. 选择排除理由
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:185](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L185)
227. 已排除
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:185](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L185)
228. 自动恢复时间线
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:204](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L204)
229. 自动恢复的时间线
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:205](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L205)
230. 证据矩阵
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:219](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L219)
231. 四源交叉核验
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:219](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L219)
232. 离湖
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:221](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L221)
233. 同一移动过程，方向连续。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:221](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L221)
234. CC98 × 照片
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:221](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L221)
235. 录音 × 网络
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:222](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L222)
236. 末段
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:222](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L222)
237. 室内广播、三秒陌生设备与候选地点需要同时成立。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:222](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L222)
238. 候选
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:223](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L223)
239. 尚未保存
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:223](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L223)
240. 已保存接入记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:223](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L223)
241. 选择最终地点
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:230](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L230)
242. 选择唯一能够同时解释时间窗、移动过程、入口变化和网络短会话的地点。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:231](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L231)
243. 路径记录已恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:243](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L243)
244. 回放会从启真湖最后一帧开始，并在已确认地点结束。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:244](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L244)
245. 近
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:92](../src/scenes/phone/P21_VoiceMemos/index.tsx#L92)
246. 中
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:93](../src/scenes/phone/P21_VoiceMemos/index.tsx#L93)
247. 远
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:94](../src/scenes/phone/P21_VoiceMemos/index.tsx#L94)
248. 先试听这段录音，再决定是否保留。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:279](../src/scenes/phone/P21_VoiceMemos/index.tsx#L279)
249. 已经选满四段。先移出一段，再加入新的录音。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:288](../src/scenes/phone/P21_VoiceMemos/index.tsx#L288)
250. 需要先选满四段录音。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:297](../src/scenes/phone/P21_VoiceMemos/index.tsx#L297)
251. 用上下按钮调整四段录音的发生顺序。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:303](../src/scenes/phone/P21_VoiceMemos/index.tsx#L303)
252. 录音已接成连续路线，末段在 22:45:00 结束。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:332](../src/scenes/phone/P21_VoiceMemos/index.tsx#L332)
253. locked
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:333](../src/scenes/phone/P21_VoiceMemos/index.tsx#L333)
254. 先完成 CC98 记录收尾。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:334](../src/scenes/phone/P21_VoiceMemos/index.tsx#L334)
255. 四段都来自这条路线，前后声场仍有一处接不上。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:336](../src/scenes/phone/P21_VoiceMemos/index.tsx#L336)
256. 其中至少一段属于别的夜间记录。重新比较背景声。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:337](../src/scenes/phone/P21_VoiceMemos/index.tsx#L337)
257. 语音备忘录
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:342](../src/scenes/phone/P21_VoiceMemos/index.tsx#L342)；[src/scenes/phone/P21_VoiceMemos/index.tsx:349](../src/scenes/phone/P21_VoiceMemos/index.tsx#L349)
258. 退出语音备忘录
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:346](../src/scenes/phone/P21_VoiceMemos/index.tsx#L346)
259. VOICE MEMOS
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:349](../src/scenes/phone/P21_VoiceMemos/index.tsx#L349)
260. 排序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:350](../src/scenes/phone/P21_VoiceMemos/index.tsx#L350)
261. 录音整理步骤
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:353](../src/scenes/phone/P21_VoiceMemos/index.tsx#L353)
262. 1 / 2 筛选录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:354](../src/scenes/phone/P21_VoiceMemos/index.tsx#L354)
263. 2 / 2 排列顺序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:354](../src/scenes/phone/P21_VoiceMemos/index.tsx#L354)
264. 逐段试听，从七段恢复文件中留下同一次移动过程的四段。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:356](../src/scenes/phone/P21_VoiceMemos/index.tsx#L356)
265. 根据环境声的连续变化，调整四段录音的先后位置。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:357](../src/scenes/phone/P21_VoiceMemos/index.tsx#L357)
266. 七段恢复录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:361](../src/scenes/phone/P21_VoiceMemos/index.tsx#L361)
267. {{playing === clip.id ? "停止" : "试听"}} {{clip.code}}
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:370](../src/scenes/phone/P21_VoiceMemos/index.tsx#L370)；[src/scenes/phone/P21_VoiceMemos/index.tsx:406](../src/scenes/phone/P21_VoiceMemos/index.tsx#L406)
268. 未试听
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:373](../src/scenes/phone/P21_VoiceMemos/index.tsx#L373)
269. 保留这段
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:384](../src/scenes/phone/P21_VoiceMemos/index.tsx#L384)
270. 试听后可选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:384](../src/scenes/phone/P21_VoiceMemos/index.tsx#L384)
271. 移出候选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:384](../src/scenes/phone/P21_VoiceMemos/index.tsx#L384)
272. {{clip.code}} 可听事件
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:386](../src/scenes/phone/P21_VoiceMemos/index.tsx#L386)；[src/scenes/phone/P21_VoiceMemos/index.tsx:415](../src/scenes/phone/P21_VoiceMemos/index.tsx#L415)
273. {{soundEvent.category}} · {{soundEvent.startMs}}–{{soundEvent.endMs}}ms
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:391](../src/scenes/phone/P21_VoiceMemos/index.tsx#L391)；[src/scenes/phone/P21_VoiceMemos/index.tsx:420](../src/scenes/phone/P21_VoiceMemos/index.tsx#L420)
274. 距
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:393](../src/scenes/phone/P21_VoiceMemos/index.tsx#L393)；[src/scenes/phone/P21_VoiceMemos/index.tsx:422](../src/scenes/phone/P21_VoiceMemos/index.tsx#L422)
275. 当前录音顺序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:402](../src/scenes/phone/P21_VoiceMemos/index.tsx#L402)
276. {{clip.code}} 上移
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:411](../src/scenes/phone/P21_VoiceMemos/index.tsx#L411)
277. {{clip.code}} 下移
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:412](../src/scenes/phone/P21_VoiceMemos/index.tsx#L412)
278. 清空选择
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:434](../src/scenes/phone/P21_VoiceMemos/index.tsx#L434)
279. 进入排序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:435](../src/scenes/phone/P21_VoiceMemos/index.tsx#L435)
280. 返回重选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:439](../src/scenes/phone/P21_VoiceMemos/index.tsx#L439)
281. 核对录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:440](../src/scenes/phone/P21_VoiceMemos/index.tsx#L440)
282. P07 天气
   来源：[src/scenes/phone/registry.tsx:55](../src/scenes/phone/registry.tsx#L55)
283. 第二章天气页：收集水滴并用于松开导师头像上的竖线。
   来源：[src/scenes/phone/registry.tsx:56](../src/scenes/phone/registry.tsx#L56)
284. P18 照片
   来源：[src/scenes/phone/registry.tsx:59](../src/scenes/phone/registry.tsx#L59)
285. IMG\_0755.JPG 亮度识别；亮度不高于 20% 时生成物品识别报告。
   来源：[src/scenes/phone/registry.tsx:60](../src/scenes/phone/registry.tsx#L60)
286. P20 记录恢复
   来源：[src/scenes/phone/registry.tsx:63](../src/scenes/phone/registry.tsx#L63)
287. 第三章半：汇总 CC98、照片、微信、网络和录音证据，恢复 22:37:05—22:45:00 路径。
   来源：[src/scenes/phone/registry.tsx:64](../src/scenes/phone/registry.tsx#L64)
288. P21 语音备忘录
   来源：[src/scenes/phone/registry.tsx:67](../src/scenes/phone/registry.tsx#L67)
289. 第三章半：从七段恢复录音中筛选四段，再按声场变化排列。
   来源：[src/scenes/phone/registry.tsx:68](../src/scenes/phone/registry.tsx#L68)
290. P04 校园卡余额
   来源：[src/scenes/phone/registry.tsx:71](../src/scenes/phone/registry.tsx#L71)
291. 第二章取得校园卡后显示余额，并接受右移箭头。
   来源：[src/scenes/phone/registry.tsx:72](../src/scenes/phone/registry.tsx#L72)
292. P11 校务签到
   来源：[src/scenes/phone/registry.tsx:75](../src/scenes/phone/registry.tsx#L75)
293. 校园网输入 0798 → 短暂成功 → 经度与纬度错误 → 红闪和七秒黑屏。
   来源：[src/scenes/phone/registry.tsx:76](../src/scenes/phone/registry.tsx#L76)
294. P10 盆栽
   来源：[src/scenes/phone/registry.tsx:79](../src/scenes/phone/registry.tsx#L79)
295. 浇水/照光/施肥三步平行 → 开花 → 点花得 d4=8。
   来源：[src/scenes/phone/registry.tsx:80](../src/scenes/phone/registry.tsx#L80)
296. P12 序章结算
   来源：[src/scenes/phone/registry.tsx:83](../src/scenes/phone/registry.tsx#L83)
297. 移动错误框拦截三次旁白路径，完成长按锁定和系统对话后返回手机主页。
   来源：[src/scenes/phone/registry.tsx:84](../src/scenes/phone/registry.tsx#L84)
298. P19 时钟
   来源：[src/scenes/phone/registry.tsx:87](../src/scenes/phone/registry.tsx#L87)
299. 第四章校时：拖动环形刻度/表冠/数字或滚轮、Q/E 键，把被篡改冻结的 07:55:23 校准对齐。
   来源：[src/scenes/phone/registry.tsx:88](../src/scenes/phone/registry.tsx#L88)

## 第四章

1. 第四章 7:55 A1 结构母图
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:27](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L27)
2. 第四章 7:55 A2 结构母图
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:47](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L47)
3. 第四章 7:55 A3 结构母图
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:67](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L67)
4. 第四章大厅旧钟状态
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:603](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L603)
5. 第四章配电面板状态
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:1100](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L1100)
6. 第四章 7:55 剧情道具
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:1332](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L1332)
7. 第四章 204 教室家具
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:1742](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L1742)
8. 第四章 204 教室深色残影
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:3455](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L3455)
9. 正在恢复 A1 现场……
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:68](../src/components/Chapter4PrologueRuntimeGate.tsx#L68)；[src/components/Chapter4PrologueRuntimeGate.tsx:117](../src/components/Chapter4PrologueRuntimeGate.tsx#L117)
10. A1 现场未在时限内完成应用。可用同一按钮重试同步。
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:98](../src/components/Chapter4PrologueRuntimeGate.tsx#L98)
11. {{String(event.payload?.phaseLabel ?? "A1 入口")}}资源准备失败（{{failedUrls.length}} 项）。请重试。
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:141](../src/components/Chapter4PrologueRuntimeGate.tsx#L141)
12. A1 现场已完成应用。
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:169](../src/components/Chapter4PrologueRuntimeGate.tsx#L169)
13. 正在重试同步 A1 现场……
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:215](../src/components/Chapter4PrologueRuntimeGate.tsx#L215)
14. 正在提交第四章入口……
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:224](../src/components/Chapter4PrologueRuntimeGate.tsx#L224)
15. 第四章入口被拒绝。可重试。
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:230](../src/components/Chapter4PrologueRuntimeGate.tsx#L230)
16. 第四章入口提交失败。可重试。
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:237](../src/components/Chapter4PrologueRuntimeGate.tsx#L237)
17. 入口已写入，正在等待 A1 地图、前景、碰撞和交互点完成应用……
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:241](../src/components/Chapter4PrologueRuntimeGate.tsx#L241)
18. 第三章半至第四章恢复回放
   来源：[src/components/Chapter4PrologueRuntimeGate.tsx:270](../src/components/Chapter4PrologueRuntimeGate.tsx#L270)
19. 小鲤鱼
   来源：[src/components/PixelIcon.tsx:888](../src/components/PixelIcon.tsx#L888)
20. 用鱼食引到钓点的小鲤鱼，暂时保持活性。
   来源：[src/components/PixelIcon.tsx:888](../src/components/PixelIcon.tsx#L888)
21. 黑天鹅带回的小型磁铁，可固定到钓竿末端。
   来源：[src/components/PixelIcon.tsx:889](../src/components/PixelIcon.tsx#L889)
22. 天鹅磁铁
   来源：[src/components/PixelIcon.tsx:889](../src/components/PixelIcon.tsx#L889)
23. 安装磁吸附件的钓竿，可接近夹在金属结构上的纸张。
   来源：[src/components/PixelIcon.tsx:890](../src/components/PixelIcon.tsx#L890)
24. 磁吸钓竿
   来源：[src/components/PixelIcon.tsx:890](../src/components/PixelIcon.tsx#L890)
25. 第四章开场追到的签到纸。最后还得把它送回正式签到口。
   来源：[src/components/PixelIcon.tsx:891](../src/components/PixelIcon.tsx#L891)
26. 签到记录纸
   来源：[src/components/PixelIcon.tsx:891](../src/components/PixelIcon.tsx#L891)；[src/data/itemCatalog.ts:210](../src/data/itemCatalog.ts#L210)
27. 从面包店传送带上取下来的旧钟时针。先停带，再拿它。
   来源：[src/components/PixelIcon.tsx:892](../src/components/PixelIcon.tsx#L892)
28. 旧钟时针
   来源：[src/components/PixelIcon.tsx:892](../src/components/PixelIcon.tsx#L892)
29. 204 复位完成后得到的旧钟定位盘。它负责让时间回到正确轨道。
   来源：[src/components/PixelIcon.tsx:893](../src/components/PixelIcon.tsx#L893)
30. 定位盘
   来源：[src/components/PixelIcon.tsx:893](../src/components/PixelIcon.tsx#L893)
31. 短撬棍
   来源：[src/components/PixelIcon.tsx:894](../src/components/PixelIcon.tsx#L894)
32. 面包店后场找到的短撬棍。适合掀开清洁车轮罩。
   来源：[src/components/PixelIcon.tsx:894](../src/components/PixelIcon.tsx#L894)
33. 通用润滑油
   来源：[src/components/PixelIcon.tsx:895](../src/components/PixelIcon.tsx#L895)
34. 修好清洁车后取到的半瓶润滑油。先修车轮，再上旧钟齿轮。
   来源：[src/components/PixelIcon.tsx:895](../src/components/PixelIcon.tsx#L895)
35. 从 202 投影中追回的一分钟。它必须回到旧钟分针端点。
   来源：[src/components/PixelIcon.tsx:896](../src/components/PixelIcon.tsx#L896)
36. 最后一分钟
   来源：[src/components/PixelIcon.tsx:896](../src/components/PixelIcon.tsx#L896)；[src/data/itemCatalog.ts:232](../src/data/itemCatalog.ts#L232)
37. 第 1 章
   来源：[src/components/QuestClueStrip.tsx:20](../src/components/QuestClueStrip.tsx#L20)
38. 第 2 章
   来源：[src/components/QuestClueStrip.tsx:21](../src/components/QuestClueStrip.tsx#L21)
39. 第 3 章
   来源：[src/components/QuestClueStrip.tsx:22](../src/components/QuestClueStrip.tsx#L22)
40. 第 4 章
   来源：[src/components/QuestClueStrip.tsx:23](../src/components/QuestClueStrip.tsx#L23)
41. 第四章当前阶段概览
   来源：[src/components/QuestClueStrip.tsx:225](../src/components/QuestClueStrip.tsx#L225)
42. 当前阶段
   来源：[src/components/QuestClueStrip.tsx:227](../src/components/QuestClueStrip.tsx#L227)；[src/data/chapter4-temporal-maze.content.json:107](../src/data/chapter4-temporal-maze.content.json#L107)
43. 时间状态
   来源：[src/components/QuestClueStrip.tsx:231](../src/components/QuestClueStrip.tsx#L231)；[src/data/chapter4-temporal-maze.content.json:108](../src/data/chapter4-temporal-maze.content.json#L108)
44. 所在楼层
   来源：[src/components/QuestClueStrip.tsx:235](../src/components/QuestClueStrip.tsx#L235)；[src/data/chapter4-temporal-maze.content.json:109](../src/data/chapter4-temporal-maze.content.json#L109)
45. 当前进度
   来源：[src/components/QuestClueStrip.tsx:239](../src/components/QuestClueStrip.tsx#L239)；[src/data/chapter4-temporal-maze.content.json:110](../src/data/chapter4-temporal-maze.content.json#L110)
46. 第四章阶段差分
   来源：[src/components/QuestClueStrip.tsx:244](../src/components/QuestClueStrip.tsx#L244)
47. 当前差分
   来源：[src/components/QuestClueStrip.tsx:246](../src/components/QuestClueStrip.tsx#L246)；[src/data/chapter4-temporal-maze.content.json:111](../src/data/chapter4-temporal-maze.content.json#L111)
48. 时间来源
   来源：[src/components/QuestClueStrip.tsx:251](../src/components/QuestClueStrip.tsx#L251)；[src/data/chapter4-temporal-maze.content.json:112](../src/data/chapter4-temporal-maze.content.json#L112)
49. 手机状态
   来源：[src/components/QuestClueStrip.tsx:255](../src/components/QuestClueStrip.tsx#L255)；[src/data/chapter4-temporal-maze.content.json:113](../src/data/chapter4-temporal-maze.content.json#L113)
50. 已确认事实
   来源：[src/components/QuestClueStrip.tsx:260](../src/components/QuestClueStrip.tsx#L260)；[src/data/chapter4-temporal-maze.content.json:114](../src/data/chapter4-temporal-maze.content.json#L114)
51. 当前阶段尚无已确认事实。
   来源：[src/components/QuestClueStrip.tsx:265](../src/components/QuestClueStrip.tsx#L265)；[src/data/chapter4-temporal-maze.content.json:116](../src/data/chapter4-temporal-maze.content.json#L116)
52. 签到数字
   来源：[src/components/QuestClueStrip.tsx:274](../src/components/QuestClueStrip.tsx#L274)
53. 第
   来源：[src/components/QuestClueStrip.tsx:280](../src/components/QuestClueStrip.tsx#L280)
54. 位
   来源：[src/components/QuestClueStrip.tsx:280](../src/components/QuestClueStrip.tsx#L280)
55. 打开控制中心
   来源：[src/components/StatusBar.tsx:45](../src/components/StatusBar.tsx#L45)
56. 车轮声音
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:9](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L9)
57. 推车起步时轮罩先响，车轮随后才停。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:9](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L9)
58. 旧钟卡滞
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:10](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L10)
59. 秒轮到同一齿位会回弹，拨动后仍重复。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:10](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L10)
60. 轮轴边只有干涸油圈，地面没有新鲜滴落。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:11](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L11)
61. 油迹
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:11](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L11)
62. 卡扣
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:15](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L15)
63. 缺油
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:16](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L16)
64. 齿轮偏位
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:17](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L17)
65. 供电中断
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:18](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L18)
66. 异物堵塞
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:19](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L19)
67. 22:45 · 维修记录
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:43](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L43)
68. 根据三处现象判断故障原因
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:44](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L44)
69. 每项现象选择一个原因，提交前可以改选。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:45](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L45)
70. 选择原因
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:61](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L61)
71. 返回现场
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:69](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L69)
72. 提交诊断
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:71](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L71)
73. 正在核对…
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:71](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L71)
74. 五区配电箱
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:130](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L130)
75. 让必要路线亮起
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:131](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L131)；[src/data/chapter4-755.content.json:911](../src/data/chapter4-755.content.json#L911)
76. 五区配电线路拓扑
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:134](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L134)
77. {{zone.label}}当前{{on ? "亮" : "暗"}}
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:157](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L157)
78. 暗
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:180](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L180)
79. 亮
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:180](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L180)
80. 正在同步配电状态……
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:188](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L188)
81. 配电结果已锁定。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:190](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L190)；[src/scenes/rpg/RpgGameHost.tsx:1022](../src/scenes/rpg/RpgGameHost.tsx#L1022)
82. 操作一个节点会同时切换与它直接连线的区域。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:191](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L191)
83. 方向键移动焦点 · Enter / Space 切换 · Esc 关闭
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:194](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L194)
84. 重试锁定配电结果
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:200](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L200)
85. 重试锁定
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:203](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L203)
86. 关闭箱门
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:213](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L213)
87. 错位楼梯空间校准
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:54](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L54)
88. 正在载入楼梯空间…
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:56](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L56)
89. 楼梯空间启动失败
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:59](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L59)
90. 返回三楼后可以重新进入。
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:60](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L60)
91. 返回三楼
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:64](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L64)
92. 三条轨道已经对齐，主电梯开始重放这一段历史。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:65](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L65)
93. 这一段历史已经对齐，可以返回主电梯厅。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:67](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L67)
94. 开门区间没有完整覆盖黄色进入窗口。继续移动整段轿厢历史。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:69](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L69)
95. 当前仍在深色观察。切回浅色操作后才能启动历史重放。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:71](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L71)
96. 当前剧情阶段尚未开放轿厢重放。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:73](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L73)
97. 拖动下方时间游标，三条轨道会保持同一历史偏移。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:74](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L74)
98. HISTORY REPLAY / A-LIFT
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:90](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L90)
99. 主电梯三轨同步
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:91](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L91)
100. 关闭三轨同步面板
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:93](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L93)
101. 当前模式
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:97](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L97)
102. 浅色操作
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:98](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L98)；[src/data/chapter4-temporal-maze.content.json:94](../src/data/chapter4-temporal-maze.content.json#L94)；[src/scenes/rpg/RpgInteractionContract.ts:37](../src/scenes/rpg/RpgInteractionContract.ts#L37)
103. 深色观察
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:98](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L98)；[src/data/chapter4-temporal-maze.content.json:95](../src/data/chapter4-temporal-maze.content.json#L95)；[src/scenes/rpg/RpgInteractionContract.ts:33](../src/scenes/rpg/RpgInteractionContract.ts#L33)
104. 重放起点
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:99](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L99)
105. 尝试
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:101](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L101)
106. 电梯历史三轨
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:105](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L105)
107. 轿厢
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:113](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L113)
108. 门体
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:122](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L122)
109. 开门
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:124](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L124)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:126](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L126)
110. 关闭
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:125](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L125)；[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
111. 进入
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:131](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L131)
112. 6 秒窗口
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:133](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L133)
113. 拖动轿厢历史
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:143](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L143)
114. 调整电梯历史重放起点
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:155](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L155)
115. 切到浅色操作
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:163](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L163)
116. 启动历史重放
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:170](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L170)
117. 目标：让一楼开门区间完整覆盖进入窗口
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:173](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L173)
118. 碎片 A · 箭头端
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:18](../src/components/temporal-maze/WayfindingBoardGame.tsx#L18)
119. 碎片 B · 2F 字样端
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:19](../src/components/temporal-maze/WayfindingBoardGame.tsx#L19)
120. 当前历史片段已经恢复。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:29](../src/components/temporal-maze/WayfindingBoardGame.tsx#L29)
121. 这一段导视记录已经恢复。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:30](../src/components/temporal-maze/WayfindingBoardGame.tsx#L30)
122. 碎片顺序与已记录的历史痕迹不一致。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:31](../src/components/temporal-maze/WayfindingBoardGame.tsx#L31)
123. 切回浅色操作后再调整导视板。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:32](../src/components/temporal-maze/WayfindingBoardGame.tsx#L32)
124. 第四章教学楼流程尚未开始。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:33](../src/components/temporal-maze/WayfindingBoardGame.tsx#L33)；[src/scenes/rpg/RpgGameHost.tsx:348](../src/scenes/rpg/RpgGameHost.tsx#L348)
125. 仍缺当前排列所需的历史证据。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:34](../src/components/temporal-maze/WayfindingBoardGame.tsx#L34)
126. 比较三份现场材料后，选择一块碎片，再选择目标槽位。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:42](../src/components/temporal-maze/WayfindingBoardGame.tsx#L42)
127. 该槽位为空。先选择一块导视碎片。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:71](../src/components/temporal-maze/WayfindingBoardGame.tsx#L71)
128. 已选择{{FRAGMENT\_LABELS\[fragment\]}}，请选择目标槽位。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:75](../src/components/temporal-maze/WayfindingBoardGame.tsx#L75)
129. 已取消当前选择。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:80](../src/components/temporal-maze/WayfindingBoardGame.tsx#L80)
130. 槽位已交换。确认前可以继续调整。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:87](../src/components/temporal-maze/WayfindingBoardGame.tsx#L87)
131. ARCHIVED SIGNAGE / A3
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:124](../src/components/temporal-maze/WayfindingBoardGame.tsx#L124)
132. 残缺导视板
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:125](../src/components/temporal-maze/WayfindingBoardGame.tsx#L125)
133. 取消并关闭导视板
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:127](../src/components/temporal-maze/WayfindingBoardGame.tsx#L127)
134. 当前目标
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:131](../src/components/temporal-maze/WayfindingBoardGame.tsx#L131)；[src/scenes/rpg/Chapter4PrologueOverlay.tsx:709](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L709)
135. 比较当前导视照片、旧残影和二楼入口方向，判断两块碎片及缺失槽位的位置。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:132](../src/components/temporal-maze/WayfindingBoardGame.tsx#L132)
136. 导视板比对材料
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:135](../src/components/temporal-maze/WayfindingBoardGame.tsx#L135)
137. 当前导视照片
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:137](../src/components/temporal-maze/WayfindingBoardGame.tsx#L137)
138. 完整板面由三段等宽槽位组成；两块残片并拢后宽度仍不足。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:138](../src/components/temporal-maze/WayfindingBoardGame.tsx#L138)
139. 旧导视残影
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:141](../src/components/temporal-maze/WayfindingBoardGame.tsx#L141)
140. 箭头端贴近左侧磨损边；“2F”字样端与箭头之间留有断续胶痕。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:142](../src/components/temporal-maze/WayfindingBoardGame.tsx#L142)
141. 二楼入口方向
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:145](../src/components/temporal-maze/WayfindingBoardGame.tsx#L145)
142. 从交通核心进入二楼时，入口位于左侧导向一边。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:146](../src/components/temporal-maze/WayfindingBoardGame.tsx#L146)
143. 三个导视板槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:150](../src/components/temporal-maze/WayfindingBoardGame.tsx#L150)
144. 当前空槽
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:152](../src/components/temporal-maze/WayfindingBoardGame.tsx#L152)
145. 槽位 {{index + 1}}：{{label}}{{picked ? "，已选择" : ""}}
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:161](../src/components/temporal-maze/WayfindingBoardGame.tsx#L161)
146. 槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:184](../src/components/temporal-maze/WayfindingBoardGame.tsx#L184)
147. 当前没有装入碎片
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:186](../src/components/temporal-maze/WayfindingBoardGame.tsx#L186)
148. 选择后放入另一槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:186](../src/components/temporal-maze/WayfindingBoardGame.tsx#L186)
149. 取消
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:197](../src/components/temporal-maze/WayfindingBoardGame.tsx#L197)
150. 方向键切换槽位，Enter 或空格选择
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:198](../src/components/temporal-maze/WayfindingBoardGame.tsx#L198)
151. 确认当前排列
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:199](../src/components/temporal-maze/WayfindingBoardGame.tsx#L199)
152. active
   来源：[src/core/QuestModel.ts:32](../src/core/QuestModel.ts#L32)；[src/core/QuestModel.ts:821](../src/core/QuestModel.ts#L821)；[src/core/QuestModel.ts:849](../src/core/QuestModel.ts#L849)
153. completed
   来源：[src/core/QuestModel.ts:32](../src/core/QuestModel.ts#L32)；[src/core/QuestModel.ts:821](../src/core/QuestModel.ts#L821)；[src/core/QuestModel.ts:849](../src/core/QuestModel.ts#L849)
154. 把时间拨回 7:55
   来源：[src/data/chapter4-755.content.json:5](../src/data/chapter4-755.content.json#L5)
155. 阶段 1 · 接住签到纸
   来源：[src/data/chapter4-755.content.json:130](../src/data/chapter4-755.content.json#L130)
156. 外部记录指向现场 22:45，手机仍停在 07:55:23，当前读数尚未同步。
   来源：[src/data/chapter4-755.content.json:131](../src/data/chapter4-755.content.json#L131)
157. 阶段 2 · 核对异常时间
   来源：[src/data/chapter4-755.content.json:134](../src/data/chapter4-755.content.json#L134)
158. 现场 22:45 与手机 07:55:23 冲突，需要确认手机时间不可作为当前依据。
   来源：[src/data/chapter4-755.content.json:135](../src/data/chapter4-755.content.json#L135)
159. 阶段 3 · 接管大厅旧钟
   来源：[src/data/chapter4-755.content.json:138](../src/data/chapter4-755.content.json#L138)
160. 手机时间已被外部记录否定，大厅旧钟缺少时针，尚未成为可用时间源。
   来源：[src/data/chapter4-755.content.json:139](../src/data/chapter4-755.content.json#L139)
161. 阶段 4 · 找回旧时针
   来源：[src/data/chapter4-755.content.json:142](../src/data/chapter4-755.content.json#L142)
162. 大厅旧钟停在 12:25，时针落入面包坊传送带，需要取回并装回。
   来源：[src/data/chapter4-755.content.json:143](../src/data/chapter4-755.content.json#L143)
163. 阶段 5 · 恢复 204
   来源：[src/data/chapter4-755.content.json:146](../src/data/chapter4-755.content.json#L146)
164. 电梯保留 18:50 历史轨道，三楼与二楼之间的楼梯发生投影错位；接通交通后再按 303 参照恢复 204。
   来源：[src/data/chapter4-755.content.json:147](../src/data/chapter4-755.content.json#L147)
165. 阶段 6 · 完成维修
   来源：[src/data/chapter4-755.content.json:150](../src/data/chapter4-755.content.json#L150)
166. 旧钟进入 22:45 维修时段且手机已同步，保洁车轮与钟内齿轮仍影响校时。
   来源：[src/data/chapter4-755.content.json:151](../src/data/chapter4-755.content.json#L151)
167. 阶段 7 · 接通必要照明
   来源：[src/data/chapter4-755.content.json:154](../src/data/chapter4-755.content.json#L154)
168. 旧钟已到 07:54，最后一分钟被纸条带走，只需恢复通往目标区域的必要灯区。
   来源：[src/data/chapter4-755.content.json:155](../src/data/chapter4-755.content.json#L155)
169. 阶段 8 · 追向 202
   来源：[src/data/chapter4-755.content.json:158](../src/data/chapter4-755.content.json#L158)
170. 旧钟仍停在 07:54，最后一分钟正在向二楼 202 移动。
   来源：[src/data/chapter4-755.content.json:159](../src/data/chapter4-755.content.json#L159)
171. 阶段 9 · 取回最后一分钟
   来源：[src/data/chapter4-755.content.json:162](../src/data/chapter4-755.content.json#L162)
172. 202 投影保留最后一分钟，旧钟仍缺少这一分钟。
   来源：[src/data/chapter4-755.content.json:163](../src/data/chapter4-755.content.json#L163)
173. 阶段 10 · 返回大厅旧钟
   来源：[src/data/chapter4-755.content.json:166](../src/data/chapter4-755.content.json#L166)
174. 最后一分钟已经取回，需要通过主楼梯送回一楼旧钟。
   来源：[src/data/chapter4-755.content.json:167](../src/data/chapter4-755.content.json#L167)
175. 阶段 11 · 完成双重签到
   来源：[src/data/chapter4-755.content.json:170](../src/data/chapter4-755.content.json#L170)
176. 旧钟与手机均为 07:55，校园卡与签到记录纸仍需分别通过验证。
   来源：[src/data/chapter4-755.content.json:171](../src/data/chapter4-755.content.json#L171)
177. 阶段 12 · 完成楼外收束
   来源：[src/data/chapter4-755.content.json:174](../src/data/chapter4-755.content.json#L174)
178. 楼内校时和双重签到已经完成，仍需确认楼外正式收束结果。
   来源：[src/data/chapter4-755.content.json:175](../src/data/chapter4-755.content.json#L175)
179. 阶段 13 · 本人来过
   来源：[src/data/chapter4-755.content.json:178](../src/data/chapter4-755.content.json#L178)
180. 旧钟、手机与签到记录均已对齐到 07:55。
   来源：[src/data/chapter4-755.content.json:179](../src/data/chapter4-755.content.json#L179)
181. 现场 22:45 · 手机 07:55:23 未同步
   来源：[src/data/chapter4-755.content.json:184](../src/data/chapter4-755.content.json#L184)；[src/modules/ChapterFourStagePresentation.ts:83](../src/modules/ChapterFourStagePresentation.ts#L83)
182. 旧钟 12:25 · 面包坊时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:187](../src/data/chapter4-755.content.json#L187)
183. 旧钟 18:50 · 晚间教室 · 手机已同步
   来源：[src/data/chapter4-755.content.json:190](../src/data/chapter4-755.content.json#L190)
184. 旧钟 22:45 · 维修时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:193](../src/data/chapter4-755.content.json#L193)；[src/modules/ChapterFourStagePresentation.ts:84](../src/modules/ChapterFourStagePresentation.ts#L84)
185. 旧钟 07:54 · 停电时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:196](../src/data/chapter4-755.content.json#L196)
186. 旧钟 07:55 · 清晨签到 · 手机已同步
   来源：[src/data/chapter4-755.content.json:199](../src/data/chapter4-755.content.json#L199)
187. 签到纸已落到公告栏前
   来源：[src/data/chapter4-755.content.json:203](../src/data/chapter4-755.content.json#L203)
188. 签到记录纸已接住
   来源：[src/data/chapter4-755.content.json:204](../src/data/chapter4-755.content.json#L204)
189. 手机 07:55:23 已被外部记录否定
   来源：[src/data/chapter4-755.content.json:205](../src/data/chapter4-755.content.json#L205)
190. 大厅旧钟缺件状态已确认
   来源：[src/data/chapter4-755.content.json:206](../src/data/chapter4-755.content.json#L206)
191. 面包坊检修灯已确认
   来源：[src/data/chapter4-755.content.json:207](../src/data/chapter4-755.content.json#L207)
192. 旧时针已从传送带露出
   来源：[src/data/chapter4-755.content.json:208](../src/data/chapter4-755.content.json#L208)
193. 旧时针已取得
   来源：[src/data/chapter4-755.content.json:209](../src/data/chapter4-755.content.json#L209)
194. 旧时针已装回
   来源：[src/data/chapter4-755.content.json:210](../src/data/chapter4-755.content.json#L210)
195. 104 黑板的延迟擦痕已记录
   来源：[src/data/chapter4-755.content.json:211](../src/data/chapter4-755.content.json#L211)
196. 105 讲台的本地回放延迟已确认
   来源：[src/data/chapter4-755.content.json:212](../src/data/chapter4-755.content.json#L212)
197. 主电梯三条历史轨道已读取
   来源：[src/data/chapter4-755.content.json:213](../src/data/chapter4-755.content.json#L213)
198. 主电梯 18:50 重放窗口已校准
   来源：[src/data/chapter4-755.content.json:214](../src/data/chapter4-755.content.json#L214)
199. 三楼 303 晨间参照已记录
   来源：[src/data/chapter4-755.content.json:215](../src/data/chapter4-755.content.json#L215)
200. 竺老两问已回答
   来源：[src/data/chapter4-755.content.json:216](../src/data/chapter4-755.content.json#L216)
201. 三楼至二楼的错位楼梯已接通
   来源：[src/data/chapter4-755.content.json:217](../src/data/chapter4-755.content.json#L217)
202. 二楼 204 残影已记录
   来源：[src/data/chapter4-755.content.json:218](../src/data/chapter4-755.content.json#L218)
203. 二楼 204 已恢复
   来源：[src/data/chapter4-755.content.json:219](../src/data/chapter4-755.content.json#L219)
204. 204 投影记录已完成
   来源：[src/data/chapter4-755.content.json:220](../src/data/chapter4-755.content.json#L220)
205. 钟面定位片已取得
   来源：[src/data/chapter4-755.content.json:221](../src/data/chapter4-755.content.json#L221)
206. 钟面定位片已装回
   来源：[src/data/chapter4-755.content.json:222](../src/data/chapter4-755.content.json#L222)
207. 保洁车轮卡滞已确认
   来源：[src/data/chapter4-755.content.json:223](../src/data/chapter4-755.content.json#L223)
208. 保洁车轮罩已打开
   来源：[src/data/chapter4-755.content.json:224](../src/data/chapter4-755.content.json#L224)
209. 保洁车轮已修复
   来源：[src/data/chapter4-755.content.json:225](../src/data/chapter4-755.content.json#L225)
210. 旧钟齿轮已修复
   来源：[src/data/chapter4-755.content.json:226](../src/data/chapter4-755.content.json#L226)
211. 签到纸暂时带走最后一分钟
   来源：[src/data/chapter4-755.content.json:227](../src/data/chapter4-755.content.json#L227)
212. 必要照明路线已锁定
   来源：[src/data/chapter4-755.content.json:228](../src/data/chapter4-755.content.json#L228)
213. 灿若星辰灯光收束准备信号已记录
   来源：[src/data/chapter4-755.content.json:229](../src/data/chapter4-755.content.json#L229)
214. 最后一分钟已取回
   来源：[src/data/chapter4-755.content.json:230](../src/data/chapter4-755.content.json#L230)
215. 最后一分钟已装回旧钟
   来源：[src/data/chapter4-755.content.json:231](../src/data/chapter4-755.content.json#L231)
216. 校园卡验证已通过
   来源：[src/data/chapter4-755.content.json:232](../src/data/chapter4-755.content.json#L232)
217. 签到记录纸验证已通过
   来源：[src/data/chapter4-755.content.json:233](../src/data/chapter4-755.content.json#L233)
218. 楼外正式收束已确认
   来源：[src/data/chapter4-755.content.json:234](../src/data/chapter4-755.content.json#L234)
219. 第四章交接条件尚未齐全。
   来源：[src/data/chapter4-755.content.json:240](../src/data/chapter4-755.content.json#L240)
220. 先完成恢复回放并在任务卡确认进入。
   来源：[src/data/chapter4-755.content.json:241](../src/data/chapter4-755.content.json#L241)
221. 该操作不属于当前阶段。
   来源：[src/data/chapter4-755.content.json:244](../src/data/chapter4-755.content.json#L244)
222. 打开任务栏，按当前目标继续。
   来源：[src/data/chapter4-755.content.json:245](../src/data/chapter4-755.content.json#L245)
223. 当前目标尚未开放。
   来源：[src/data/chapter4-755.content.json:248](../src/data/chapter4-755.content.json#L248)
224. 先完成任务栏中显示的当前前置操作。
   来源：[src/data/chapter4-755.content.json:249](../src/data/chapter4-755.content.json#L249)
225. 当前阶段不能进入这一区域。
   来源：[src/data/chapter4-755.content.json:252](../src/data/chapter4-755.content.json#L252)
226. 返回当前楼层已开放的任务目标。
   来源：[src/data/chapter4-755.content.json:253](../src/data/chapter4-755.content.json#L253)
227. 这次楼梯通行条件不成立。
   来源：[src/data/chapter4-755.content.json:256](../src/data/chapter4-755.content.json#L256)
228. 按任务栏目标从当前楼层的主楼梯继续。
   来源：[src/data/chapter4-755.content.json:257](../src/data/chapter4-755.content.json#L257)
229. 传送带仍在运行。
   来源：[src/data/chapter4-755.content.json:260](../src/data/chapter4-755.content.json#L260)
230. 先检查并点亮烤箱旁的检修灯。
   来源：[src/data/chapter4-755.content.json:261](../src/data/chapter4-755.content.json#L261)
231. 传送带正在执行停机过程。
   来源：[src/data/chapter4-755.content.json:264](../src/data/chapter4-755.content.json#L264)
232. 等待停稳后再取露出的旧时针。
   来源：[src/data/chapter4-755.content.json:265](../src/data/chapter4-755.content.json#L265)
233. 旧时针流程尚未完成。
   来源：[src/data/chapter4-755.content.json:268](../src/data/chapter4-755.content.json#L268)
234. 先让传送带停稳，取得旧时针后拖到大厅旧钟。
   来源：[src/data/chapter4-755.content.json:269](../src/data/chapter4-755.content.json#L269)
235. A1 的时间差校验尚未完成。
   来源：[src/data/chapter4-755.content.json:272](../src/data/chapter4-755.content.json#L272)
236. 104 黑板擦痕与 105 讲台回放可按任意顺序确认。
   来源：[src/data/chapter4-755.content.json:273](../src/data/chapter4-755.content.json#L273)
237. 主电梯的历史轨道尚未记录。
   来源：[src/data/chapter4-755.content.json:276](../src/data/chapter4-755.content.json#L276)
238. 完成 104 与 105 校验后，可在一楼电梯门前用深色观察记录；这不限制浅色校准的先后。
   来源：[src/data/chapter4-755.content.json:277](../src/data/chapter4-755.content.json#L277)
239. 主电梯重放窗口尚未校准。
   来源：[src/data/chapter4-755.content.json:280](../src/data/chapter4-755.content.json#L280)
240. 使用浅色操作进入轿厢，让门体开放区间覆盖六秒进入窗口。
   来源：[src/data/chapter4-755.content.json:281](../src/data/chapter4-755.content.json#L281)
241. 竺老两问尚未完成。
   来源：[src/data/chapter4-755.content.json:284](../src/data/chapter4-755.content.json#L284)
242. 回到三楼校史人物荣誉门厅，靠近竺可桢画像按 Space 并提交两项回答。
   来源：[src/data/chapter4-755.content.json:285](../src/data/chapter4-755.content.json#L285)
243. 三楼与二楼之间的楼梯仍处于投影错位状态。
   来源：[src/data/chapter4-755.content.json:288](../src/data/chapter4-755.content.json#L288)
244. 完成竺老两问后，从三楼主楼梯下行口进入空间对齐关卡。
   来源：[src/data/chapter4-755.content.json:289](../src/data/chapter4-755.content.json#L289)
245. 204 复原缺少参照记录。
   来源：[src/data/chapter4-755.content.json:292](../src/data/chapter4-755.content.json#L292)
246. 补齐 303 参照与 204 深色残影；家具摆放可以在两项记录之前或之后完成。
   来源：[src/data/chapter4-755.content.json:293](../src/data/chapter4-755.content.json#L293)
247. 204 仍有家具未复原。
   来源：[src/data/chapter4-755.content.json:296](../src/data/chapter4-755.content.json#L296)
248. 把剩余家具放入空槽位，直到进度达到 12/12。
   来源：[src/data/chapter4-755.content.json:297](../src/data/chapter4-755.content.json#L297)
249. 该家具未被当前场景识别。
   来源：[src/data/chapter4-755.content.json:300](../src/data/chapter4-755.content.json#L300)
250. 重新选取 204 内可见且尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:301](../src/data/chapter4-755.content.json#L301)
251. 该位置不属于 204 的复原槽位。
   来源：[src/data/chapter4-755.content.json:304](../src/data/chapter4-755.content.json#L304)
252. 靠近教室内清晰显示的空槽位后重试。
   来源：[src/data/chapter4-755.content.json:305](../src/data/chapter4-755.content.json#L305)
253. 该家具状态无法写入复原记录。
   来源：[src/data/chapter4-755.content.json:308](../src/data/chapter4-755.content.json#L308)
254. 放下后重新选取家具，再放入任一空槽位。
   来源：[src/data/chapter4-755.content.json:309](../src/data/chapter4-755.content.json#L309)
255. 这组家具已经写入另一个槽位。
   来源：[src/data/chapter4-755.content.json:312](../src/data/chapter4-755.content.json#L312)
256. 改选一组尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:313](../src/data/chapter4-755.content.json#L313)
257. 这个槽位已经有一组家具。
   来源：[src/data/chapter4-755.content.json:316](../src/data/chapter4-755.content.json#L316)
258. 把当前家具放入另一个空槽位。
   来源：[src/data/chapter4-755.content.json:317](../src/data/chapter4-755.content.json#L317)
259. 这组家具已经完成复原。
   来源：[src/data/chapter4-755.content.json:320](../src/data/chapter4-755.content.json#L320)
260. 继续选择一组尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:321](../src/data/chapter4-755.content.json#L321)
261. 讲台抽屉尚未解锁。
   来源：[src/data/chapter4-755.content.json:324](../src/data/chapter4-755.content.json#L324)
262. 先完成 12/12 复原并确认 07:55 投影。
   来源：[src/data/chapter4-755.content.json:325](../src/data/chapter4-755.content.json#L325)
263. 大厅旧钟仍缺少钟面定位片。
   来源：[src/data/chapter4-755.content.json:328](../src/data/chapter4-755.content.json#L328)
264. 从 204 讲台抽屉取得定位片，再拖到旧钟插槽。
   来源：[src/data/chapter4-755.content.json:329](../src/data/chapter4-755.content.json#L329)
265. 保洁车轮的卡滞点尚未确认。
   来源：[src/data/chapter4-755.content.json:332](../src/data/chapter4-755.content.json#L332)
266. 先检查卡住的车轮，再使用短撬棒打开轮罩。
   来源：[src/data/chapter4-755.content.json:333](../src/data/chapter4-755.content.json#L333)
267. 润滑位置仍被轮罩挡住。
   来源：[src/data/chapter4-755.content.json:336](../src/data/chapter4-755.content.json#L336)
268. 先用短撬棒打开轮罩，再取得润滑油。
   来源：[src/data/chapter4-755.content.json:337](../src/data/chapter4-755.content.json#L337)
269. 旧钟齿轮维修仍受保洁车阻挡。
   来源：[src/data/chapter4-755.content.json:340](../src/data/chapter4-755.content.json#L340)
270. 先给保洁车轮上油并让车移动，再处理旧钟齿轮。
   来源：[src/data/chapter4-755.content.json:341](../src/data/chapter4-755.content.json#L341)
271. 旧钟齿轮仍处于断续状态。
   来源：[src/data/chapter4-755.content.json:344](../src/data/chapter4-755.content.json#L344)
272. 先完成车轮维修，再给旧钟齿轮上油。
   来源：[src/data/chapter4-755.content.json:345](../src/data/chapter4-755.content.json#L345)
273. 最后一分钟的拖拽过程尚未就绪。
   来源：[src/data/chapter4-755.content.json:348](../src/data/chapter4-755.content.json#L348)
274. 完成旧钟维修后，在浅色操作中重新开始拖动分针。
   来源：[src/data/chapter4-755.content.json:349](../src/data/chapter4-755.content.json#L349)
275. 配电流程尚未开放或已经锁定。
   来源：[src/data/chapter4-755.content.json:352](../src/data/chapter4-755.content.json#L352)
276. 先完成分针拖拽；若已锁定照明，继续前往 202。
   来源：[src/data/chapter4-755.content.json:353](../src/data/chapter4-755.content.json#L353)
277. 这次追逐请求已失效。
   来源：[src/data/chapter4-755.content.json:356](../src/data/chapter4-755.content.json#L356)
278. 从当前追逐检查点重新开始。
   来源：[src/data/chapter4-755.content.json:357](../src/data/chapter4-755.content.json#L357)
279. 最后一分钟尚未安全取回。
   来源：[src/data/chapter4-755.content.json:360](../src/data/chapter4-755.content.json#L360)
280. 抵达 202 并收取投影中的最后一分钟。
   来源：[src/data/chapter4-755.content.json:361](../src/data/chapter4-755.content.json#L361)
281. 当前还不能把最后一分钟装回旧钟。
   来源：[src/data/chapter4-755.content.json:364](../src/data/chapter4-755.content.json#L364)
282. 携带最后一分钟、校园卡和签到纸，经主楼梯返回一楼大厅。
   来源：[src/data/chapter4-755.content.json:365](../src/data/chapter4-755.content.json#L365)
283. 第三章半的证据恢复尚未闭合。
   来源：[src/data/chapter4-755.content.json:368](../src/data/chapter4-755.content.json#L368)
284. 返回手机完成时间线与地点确认，再继续第四章。
   来源：[src/data/chapter4-755.content.json:369](../src/data/chapter4-755.content.json#L369)
285. 当前签到条件尚未齐全。
   来源：[src/data/chapter4-755.content.json:372](../src/data/chapter4-755.content.json#L372)
286. 确认已到 07:55，并把对应的校园卡或签到纸拖到各自设备。
   来源：[src/data/chapter4-755.content.json:373](../src/data/chapter4-755.content.json#L373)
287. 校园卡验证已经通过。
   来源：[src/data/chapter4-755.content.json:376](../src/data/chapter4-755.content.json#L376)
288. 继续提交签到记录纸。
   来源：[src/data/chapter4-755.content.json:377](../src/data/chapter4-755.content.json#L377)
289. 签到记录纸验证已经通过。
   来源：[src/data/chapter4-755.content.json:380](../src/data/chapter4-755.content.json#L380)
290. 继续读取校园卡。
   来源：[src/data/chapter4-755.content.json:381](../src/data/chapter4-755.content.json#L381)
291. 楼外收束的前置记录尚未齐全。
   来源：[src/data/chapter4-755.content.json:384](../src/data/chapter4-755.content.json#L384)
292. 先完成校园卡与签到纸的双重签到。
   来源：[src/data/chapter4-755.content.json:385](../src/data/chapter4-755.content.json#L385)
293. 正式收束播放尚未得到验证。
   来源：[src/data/chapter4-755.content.json:388](../src/data/chapter4-755.content.json#L388)
294. 完整播放已批准的收束内容后再确认结果。
   来源：[src/data/chapter4-755.content.json:389](../src/data/chapter4-755.content.json#L389)
295. 先点亮烤箱旁的检修灯，让传送带停一下。
   来源：[src/data/chapter4-755.content.json:434](../src/data/chapter4-755.content.json#L434)
296. 等纸条落到公告栏前再抓住它
   来源：[src/data/chapter4-755.content.json:719](../src/data/chapter4-755.content.json#L719)
297. 观察一楼门厅公告栏前的纸条落点。
   来源：[src/data/chapter4-755.content.json:721](../src/data/chapter4-755.content.json#L721)
298. 纸条停稳后才会进入可抓取状态。
   来源：[src/data/chapter4-755.content.json:722](../src/data/chapter4-755.content.json#L722)
299. 纸条落到公告栏前时靠近纸条并执行交互。
   来源：[src/data/chapter4-755.content.json:723](../src/data/chapter4-755.content.json#L723)
300. 查看大厅旧钟
   来源：[src/data/chapter4-755.content.json:727](../src/data/chapter4-755.content.json#L727)
301. 观察一楼大厅中央的旧钟。
   来源：[src/data/chapter4-755.content.json:729](../src/data/chapter4-755.content.json#L729)
302. 先确认缺失指针和卡滞齿轮，才能继续拨动旧钟。
   来源：[src/data/chapter4-755.content.json:730](../src/data/chapter4-755.content.json#L730)
303. 在浅色操作中靠近大厅旧钟并执行交互。
   来源：[src/data/chapter4-755.content.json:731](../src/data/chapter4-755.content.json#L731)
304. 拉动大厅旧钟，让它第一次转动
   来源：[src/data/chapter4-755.content.json:735](../src/data/chapter4-755.content.json#L735)
305. 继续检查大厅旧钟的可操作部位。
   来源：[src/data/chapter4-755.content.json:737](../src/data/chapter4-755.content.json#L737)
306. 完成旧钟检查后，第一次拨动会切换时间来源。
   来源：[src/data/chapter4-755.content.json:738](../src/data/chapter4-755.content.json#L738)
307. 在浅色操作中靠近大厅旧钟并执行拨动交互。
   来源：[src/data/chapter4-755.content.json:739](../src/data/chapter4-755.content.json#L739)
308. 前往面包坊检查检修灯和传送带
   来源：[src/data/chapter4-755.content.json:743](../src/data/chapter4-755.content.json#L743)
309. 观察一楼面包坊烤箱旁的检修灯和传送带边缘。
   来源：[src/data/chapter4-755.content.json:745](../src/data/chapter4-755.content.json#L745)
310. 检修灯亮起后，传送带才会进入停机流程。
   来源：[src/data/chapter4-755.content.json:746](../src/data/chapter4-755.content.json#L746)
311. 在浅色操作中靠近检修灯并交互，等待传送带完全停下。
   来源：[src/data/chapter4-755.content.json:747](../src/data/chapter4-755.content.json#L747)
312. 传送带停下后取走金属时针
   来源：[src/data/chapter4-755.content.json:751](../src/data/chapter4-755.content.json#L751)
313. 查看停止的传送带上新露出的金属部件。
   来源：[src/data/chapter4-755.content.json:753](../src/data/chapter4-755.content.json#L753)
314. 只有停机流程完成后，旧时针才可被取走。
   来源：[src/data/chapter4-755.content.json:754](../src/data/chapter4-755.content.json#L754)
315. 在浅色操作中靠近传送带上的旧时针并执行拾取。
   来源：[src/data/chapter4-755.content.json:755](../src/data/chapter4-755.content.json#L755)
316. 回大厅装回旧时针
   来源：[src/data/chapter4-755.content.json:759](../src/data/chapter4-755.content.json#L759)
317. 返回一楼大厅旧钟的时针缺口。
   来源：[src/data/chapter4-755.content.json:761](../src/data/chapter4-755.content.json#L761)
318. 旧时针只能装入旧钟对应的时针接口。
   来源：[src/data/chapter4-755.content.json:762](../src/data/chapter4-755.content.json#L762)
319. 在浅色操作中把道具栏里的旧时针拖到旧钟时针接口。
   来源：[src/data/chapter4-755.content.json:763](../src/data/chapter4-755.content.json#L763)
320. 前往三楼观察 303 的晨间布置
   来源：[src/data/chapter4-755.content.json:767](../src/data/chapter4-755.content.json#L767)
321. 前往三楼 303 参照教室。
   来源：[src/data/chapter4-755.content.json:769](../src/data/chapter4-755.content.json#L769)
322. 303 晨间参照可在 204 家具摆放前后记录，不限制 204 残影的观察顺序。
   来源：[src/data/chapter4-755.content.json:770](../src/data/chapter4-755.content.json#L770)
323. 保持浅色操作，靠近 303 晨间参照区域并执行记录。
   来源：[src/data/chapter4-755.content.json:771](../src/data/chapter4-755.content.json#L771)
324. 完成 104 与 105 的时间差校验
   来源：[src/data/chapter4-755.content.json:775](../src/data/chapter4-755.content.json#L775)
325. 104 与 105 各保留了一种时间延迟记录，两项都确认后才能使用楼层通道。
   来源：[src/data/chapter4-755.content.json:777](../src/data/chapter4-755.content.json#L777)
326. 104 使用深色观察读取黑板擦痕残留。
   来源：[src/data/chapter4-755.content.json:778](../src/data/chapter4-755.content.json#L778)
327. 105 使用浅色操作检查讲台本地回放；两间教室可按任意顺序处理。
   来源：[src/data/chapter4-755.content.json:779](../src/data/chapter4-755.content.json#L779)
328. 完成主电梯历史读取与重放校准
   来源：[src/data/chapter4-755.content.json:783](../src/data/chapter4-755.content.json#L783)
329. 104 与 105 的两项校验完成后，主电梯会留下轿厢、门体和进入窗口三条轨道。
   来源：[src/data/chapter4-755.content.json:785](../src/data/chapter4-755.content.json#L785)
330. 深色观察可在一楼电梯门前记录三条轨道；浅色操作可进入轿厢校准重放起点。
   来源：[src/data/chapter4-755.content.json:786](../src/data/chapter4-755.content.json#L786)
331. 读取与校准互不作为对方的前置条件，两项均完成后电梯线索收束。
   来源：[src/data/chapter4-755.content.json:787](../src/data/chapter4-755.content.json#L787)
332. 校准主电梯的 18:50 重放窗口
   来源：[src/data/chapter4-755.content.json:791](../src/data/chapter4-755.content.json#L791)
333. 在浅色操作中进入一楼主电梯轿厢。
   来源：[src/data/chapter4-755.content.json:793](../src/data/chapter4-755.content.json#L793)
334. 调整重放起点，让门体开放区间完整覆盖人物的六秒进入窗口。
   来源：[src/data/chapter4-755.content.json:794](../src/data/chapter4-755.content.json#L794)
335. 校准成功后乘电梯直达三楼，二楼按钮会暂时锁定。
   来源：[src/data/chapter4-755.content.json:795](../src/data/chapter4-755.content.json#L795)
336. 在校史人物荣誉墙回答竺老两问
   来源：[src/data/chapter4-755.content.json:799](../src/data/chapter4-755.content.json#L799)
337. 前往三楼校史人物荣誉门厅，中间画像为竺可桢老校长。
   来源：[src/data/chapter4-755.content.json:801](../src/data/chapter4-755.content.json#L801)
338. 靠近竺可桢画像并按 Space，先阅读生平，再依次回答两个问题。
   来源：[src/data/chapter4-755.content.json:802](../src/data/chapter4-755.content.json#L802)
339. 每个选项都会保留你的回答；提交后才能进入错位楼梯。
   来源：[src/data/chapter4-755.content.json:803](../src/data/chapter4-755.content.json#L803)
340. 接通三楼通往二楼的错位楼梯
   来源：[src/data/chapter4-755.content.json:807](../src/data/chapter4-755.content.json#L807)
341. 完成竺老两问后，前往三楼主楼梯下行口。303 晨间参照可在此前或此后记录。
   来源：[src/data/chapter4-755.content.json:809](../src/data/chapter4-755.content.json#L809)
342. 在三个固定视角中调节横移台、旋转梯和升降台，让投影端点形成连续通路。
   来源：[src/data/chapter4-755.content.json:810](../src/data/chapter4-755.content.json#L810)
343. 完成两段楼梯间后会从二楼交通核心恢复行动。
   来源：[src/data/chapter4-755.content.json:811](../src/data/chapter4-755.content.json#L811)
344. 回到二楼，在深色观察中确认 204 残影
   来源：[src/data/chapter4-755.content.json:815](../src/data/chapter4-755.content.json#L815)
345. 返回二楼 204，查看教室中的成组家具残影。
   来源：[src/data/chapter4-755.content.json:817](../src/data/chapter4-755.content.json#L817)
346. 204 的复原需要同时具备 303 参照和 204 残影记录。
   来源：[src/data/chapter4-755.content.json:818](../src/data/chapter4-755.content.json#L818)
347. 切到深色观察，靠近 204 残影区域并执行观察。
   来源：[src/data/chapter4-755.content.json:819](../src/data/chapter4-755.content.json#L819)
348. 把教室恢复成早晨的样子
   来源：[src/data/chapter4-755.content.json:823](../src/data/chapter4-755.content.json#L823)
349. 303 晨间参照、204 深色残影和浅色家具摆放可按任意顺序完成。
   来源：[src/data/chapter4-755.content.json:825](../src/data/chapter4-755.content.json#L825)
350. 每组家具只占一个空槽，每个空槽只接受一组家具，共需放置 12 组。
   来源：[src/data/chapter4-755.content.json:826](../src/data/chapter4-755.content.json#L826)
351. 浅色操作可先摆放家具；缺失的参照或残影随后补齐时，系统会统一确认复原结果。
   来源：[src/data/chapter4-755.content.json:827](../src/data/chapter4-755.content.json#L827)
352. 查看 204 投影幕上的时间
   来源：[src/data/chapter4-755.content.json:831](../src/data/chapter4-755.content.json#L831)
353. 完成复原后查看 204 前方的投影幕。
   来源：[src/data/chapter4-755.content.json:833](../src/data/chapter4-755.content.json#L833)
354. 12 组家具全部就位后，投影记录才会稳定。
   来源：[src/data/chapter4-755.content.json:834](../src/data/chapter4-755.content.json#L834)
355. 留在 204 内完成投影播放，并在稳定画面出现后执行确认。
   来源：[src/data/chapter4-755.content.json:835](../src/data/chapter4-755.content.json#L835)
356. 从 204 讲台抽屉取出钟面定位片
   来源：[src/data/chapter4-755.content.json:839](../src/data/chapter4-755.content.json#L839)
357. 查看 204 讲台的抽屉。
   来源：[src/data/chapter4-755.content.json:841](../src/data/chapter4-755.content.json#L841)
358. 投影记录完成后，讲台抽屉才会开放。
   来源：[src/data/chapter4-755.content.json:842](../src/data/chapter4-755.content.json#L842)
359. 在浅色操作中靠近讲台抽屉并执行拾取，取得钟面定位片。
   来源：[src/data/chapter4-755.content.json:843](../src/data/chapter4-755.content.json#L843)
360. 把钟面定位片装回大厅旧钟
   来源：[src/data/chapter4-755.content.json:847](../src/data/chapter4-755.content.json#L847)
361. 返回一楼大厅旧钟的定位片接口。
   来源：[src/data/chapter4-755.content.json:849](../src/data/chapter4-755.content.json#L849)
362. 钟面定位片只接受从 204 讲台取得的对应道具。
   来源：[src/data/chapter4-755.content.json:850](../src/data/chapter4-755.content.json#L850)
363. 在浅色操作中把钟面定位片拖到旧钟定位片接口。
   来源：[src/data/chapter4-755.content.json:851](../src/data/chapter4-755.content.json#L851)
364. 诊断保洁车与旧钟的联动故障
   来源：[src/data/chapter4-755.content.json:855](../src/data/chapter4-755.content.json#L855)
365. 靠近保洁车检查车轮声音、旧钟卡滞和地面油迹。
   来源：[src/data/chapter4-755.content.json:857](../src/data/chapter4-755.content.json#L857)
366. 三项现象分别对应一种故障原因；提交前可以反复改选。
   来源：[src/data/chapter4-755.content.json:858](../src/data/chapter4-755.content.json#L858)
367. 诊断正确后会取得执行维修所需的短撬棍与润滑油。
   来源：[src/data/chapter4-755.content.json:859](../src/data/chapter4-755.content.json#L859)
368. 去面包店后场取短撬棍
   来源：[src/data/chapter4-755.content.json:863](../src/data/chapter4-755.content.json#L863)
369. 前往一楼面包坊后场查找可用工具。
   来源：[src/data/chapter4-755.content.json:865](../src/data/chapter4-755.content.json#L865)
370. 轮罩需要短撬棍打开，其他道具不会被接受。
   来源：[src/data/chapter4-755.content.json:866](../src/data/chapter4-755.content.json#L866)
371. 在浅色操作中靠近面包坊后场的短撬棍并执行拾取。
   来源：[src/data/chapter4-755.content.json:867](../src/data/chapter4-755.content.json#L867)
372. 用短撬棍打开保洁车轮罩
   来源：[src/data/chapter4-755.content.json:871](../src/data/chapter4-755.content.json#L871)
373. 返回保洁车的车轮罩。
   来源：[src/data/chapter4-755.content.json:873](../src/data/chapter4-755.content.json#L873)
374. 诊断完成后，短撬棍可用于打开卡住的轮罩，并会在本次使用后消耗。
   来源：[src/data/chapter4-755.content.json:874](../src/data/chapter4-755.content.json#L874)
375. 在浅色操作中把短撬棍拖到保洁车轮罩。
   来源：[src/data/chapter4-755.content.json:875](../src/data/chapter4-755.content.json#L875)
376. 取出轮罩内的通用润滑油
   来源：[src/data/chapter4-755.content.json:879](../src/data/chapter4-755.content.json#L879)
377. 查看已经打开的保洁车轮罩内部。
   来源：[src/data/chapter4-755.content.json:881](../src/data/chapter4-755.content.json#L881)
378. 轮罩打开后，通用润滑油才会出现为可拾取道具。
   来源：[src/data/chapter4-755.content.json:882](../src/data/chapter4-755.content.json#L882)
379. 在浅色操作中靠近轮罩内的润滑油并执行拾取。
   来源：[src/data/chapter4-755.content.json:883](../src/data/chapter4-755.content.json#L883)
380. 润滑轮轴并校正旧钟齿轮
   来源：[src/data/chapter4-755.content.json:887](../src/data/chapter4-755.content.json#L887)
381. 观察保洁车已打开轮罩的车轮。
   来源：[src/data/chapter4-755.content.json:889](../src/data/chapter4-755.content.json#L889)
382. 诊断确认车轮缺油与旧钟齿轮偏位属于同一次卡滞。
   来源：[src/data/chapter4-755.content.json:890](../src/data/chapter4-755.content.json#L890)
383. 在浅色操作中把通用润滑油拖到保洁车轮，完成联动修复。
   来源：[src/data/chapter4-755.content.json:891](../src/data/chapter4-755.content.json#L891)
384. 用剩下的润滑油修复旧钟齿轮
   来源：[src/data/chapter4-755.content.json:895](../src/data/chapter4-755.content.json#L895)
385. 返回一楼大厅旧钟的齿轮位置。
   来源：[src/data/chapter4-755.content.json:897](../src/data/chapter4-755.content.json#L897)
386. 车轮修复完成后，剩余润滑油才可用于旧钟齿轮，并会在使用后消耗。
   来源：[src/data/chapter4-755.content.json:898](../src/data/chapter4-755.content.json#L898)
387. 在浅色操作中把通用润滑油拖到大厅旧钟齿轮。
   来源：[src/data/chapter4-755.content.json:899](../src/data/chapter4-755.content.json#L899)
388. 把旧钟拨向 07:55
   来源：[src/data/chapter4-755.content.json:903](../src/data/chapter4-755.content.json#L903)；[src/data/chapter4-755.content.json:1493](../src/data/chapter4-755.content.json#L1493)
389. 查看维修完成后的大厅旧钟表盘。
   来源：[src/data/chapter4-755.content.json:905](../src/data/chapter4-755.content.json#L905)
390. 车轮与钟内齿轮均修复后，旧钟才接受最终校时。
   来源：[src/data/chapter4-755.content.json:906](../src/data/chapter4-755.content.json#L906)
391. 在浅色操作中拖动旧钟分针到 07:55 刻度并松开。
   来源：[src/data/chapter4-755.content.json:907](../src/data/chapter4-755.content.json#L907)
392. 查看一楼停电状态下的配电面板和五个灯区。
   来源：[src/data/chapter4-755.content.json:913](../src/data/chapter4-755.content.json#L913)
393. 只校验必要路线：大厅、东走廊和教室区亮起，西走廊和面包店后场保持关闭。
   来源：[src/data/chapter4-755.content.json:914](../src/data/chapter4-755.content.json#L914)
394. 在浅色操作中切换对应灯区，满足五个必要条件后点击锁定。
   来源：[src/data/chapter4-755.content.json:915](../src/data/chapter4-755.content.json#L915)
395. 前往 202
   来源：[src/data/chapter4-755.content.json:919](../src/data/chapter4-755.content.json#L919)
396. 观察最后一分钟经过的主楼梯和二楼走廊。
   来源：[src/data/chapter4-755.content.json:921](../src/data/chapter4-755.content.json#L921)
397. 追逐阶段只保存当前追逐检查点，失败会从该段重新开始。
   来源：[src/data/chapter4-755.content.json:922](../src/data/chapter4-755.content.json#L922)
398. 沿一楼主楼梯进入二楼，继续移动到 202 门口的到达区域。
   来源：[src/data/chapter4-755.content.json:923](../src/data/chapter4-755.content.json#L923)
399. 取回最后一分钟
   来源：[src/data/chapter4-755.content.json:927](../src/data/chapter4-755.content.json#L927)
400. 查看二楼 202 内的投影区域。
   来源：[src/data/chapter4-755.content.json:929](../src/data/chapter4-755.content.json#L929)
401. 到达 202 后，最后一分钟与签到记录纸会在同一记录点恢复。
   来源：[src/data/chapter4-755.content.json:930](../src/data/chapter4-755.content.json#L930)
402. 在浅色操作中靠近 202 投影并执行拾取。
   来源：[src/data/chapter4-755.content.json:931](../src/data/chapter4-755.content.json#L931)
403. 沿主楼梯回到一楼旧钟
   来源：[src/data/chapter4-755.content.json:935](../src/data/chapter4-755.content.json#L935)
404. 从二楼 202 返回二楼主楼梯入口。
   来源：[src/data/chapter4-755.content.json:937](../src/data/chapter4-755.content.json#L937)
405. 携带最后一分钟时，跨层返回只接受主楼梯路线。
   来源：[src/data/chapter4-755.content.json:938](../src/data/chapter4-755.content.json#L938)
406. 进入二楼主楼梯通行区，沿主楼梯回到一楼大厅。
   来源：[src/data/chapter4-755.content.json:939](../src/data/chapter4-755.content.json#L939)
407. 把最后一分钟装回旧钟
   来源：[src/data/chapter4-755.content.json:943](../src/data/chapter4-755.content.json#L943)
408. 查看一楼大厅旧钟的分针端点。
   来源：[src/data/chapter4-755.content.json:945](../src/data/chapter4-755.content.json#L945)
409. 最后一分钟只能装回大厅旧钟的分钟接口。
   来源：[src/data/chapter4-755.content.json:946](../src/data/chapter4-755.content.json#L946)
410. 在浅色操作中把道具栏里的最后一分钟拖到旧钟分钟接口。
   来源：[src/data/chapter4-755.content.json:947](../src/data/chapter4-755.content.json#L947)
411. 完成刷卡与纸条签到
   来源：[src/data/chapter4-755.content.json:951](../src/data/chapter4-755.content.json#L951)
412. 观察一楼签到区的校园卡读卡器和签到记录纸插槽。
   来源：[src/data/chapter4-755.content.json:953](../src/data/chapter4-755.content.json#L953)
413. 两项验证互不依赖，任意顺序完成，进度只按两个已接受事实计算。
   来源：[src/data/chapter4-755.content.json:954](../src/data/chapter4-755.content.json#L954)
414. 在浅色操作中把校园卡拖到读卡器，并把签到记录纸拖到纸条插槽。
   来源：[src/data/chapter4-755.content.json:955](../src/data/chapter4-755.content.json#L955)
415. 使用校园卡完成刷卡
   来源：[src/data/chapter4-755.content.json:959](../src/data/chapter4-755.content.json#L959)
416. 查看一楼签到区的校园卡读卡器。
   来源：[src/data/chapter4-755.content.json:961](../src/data/chapter4-755.content.json#L961)
417. 读卡器只接受校园卡，已完成的纸条验证不会被清除。
   来源：[src/data/chapter4-755.content.json:962](../src/data/chapter4-755.content.json#L962)
418. 在浅色操作中把校园卡拖到校园卡读卡器。
   来源：[src/data/chapter4-755.content.json:963](../src/data/chapter4-755.content.json#L963)
419. 提交签到记录纸条
   来源：[src/data/chapter4-755.content.json:967](../src/data/chapter4-755.content.json#L967)
420. 查看一楼签到区的签到记录纸插槽。
   来源：[src/data/chapter4-755.content.json:969](../src/data/chapter4-755.content.json#L969)
421. 纸条插槽只接受已恢复的签到记录纸，已完成的刷卡验证不会被清除。
   来源：[src/data/chapter4-755.content.json:970](../src/data/chapter4-755.content.json#L970)
422. 在浅色操作中把签到记录纸拖到纸条插槽。
   来源：[src/data/chapter4-755.content.json:971](../src/data/chapter4-755.content.json#L971)
423. 观看并完成楼外正式收束
   来源：[src/data/chapter4-755.content.json:975](../src/data/chapter4-755.content.json#L975)
424. 完成双重签到后，查看教学楼外的正式收束画面。
   来源：[src/data/chapter4-755.content.json:977](../src/data/chapter4-755.content.json#L977)
425. 楼外画面完整播放并通过会话校验后，章节完成确认才会开放。
   来源：[src/data/chapter4-755.content.json:978](../src/data/chapter4-755.content.json#L978)
426. 等待正式收束播放结束，再点击完成确认。
   来源：[src/data/chapter4-755.content.json:979](../src/data/chapter4-755.content.json#L979)
427. 本人来过
   来源：[src/data/chapter4-755.content.json:983](../src/data/chapter4-755.content.json#L983)
428. system
   来源：[src/data/chapter4-755.content.json:990](../src/data/chapter4-755.content.json#L990)；[src/data/chapter4-755.content.json:1000](../src/data/chapter4-755.content.json#L1000)；[src/data/chapter4-755.content.json:1006](../src/data/chapter4-755.content.json#L1006)；[src/data/chapter4-755.content.json:1010](../src/data/chapter4-755.content.json#L1010)；[src/data/chapter4-755.content.json:1018](../src/data/chapter4-755.content.json#L1018)；[src/data/chapter4-755.content.json:1022](../src/data/chapter4-755.content.json#L1022)；[src/data/chapter4-755.content.json:1028](../src/data/chapter4-755.content.json#L1028)；[src/data/chapter4-755.content.json:1036](../src/data/chapter4-755.content.json#L1036)；[src/data/chapter4-755.content.json:1042](../src/data/chapter4-755.content.json#L1042)；[src/data/chapter4-755.content.json:1062](../src/data/chapter4-755.content.json#L1062)；[src/data/chapter4-755.content.json:1072](../src/data/chapter4-755.content.json#L1072)；[src/data/chapter4-755.content.json:1076](../src/data/chapter4-755.content.json#L1076)；[src/data/chapter4-755.content.json:1160](../src/data/chapter4-755.content.json#L1160)；[src/data/chapter4-755.content.json:1166](../src/data/chapter4-755.content.json#L1166)；[src/data/chapter4-755.content.json:1186](../src/data/chapter4-755.content.json#L1186)；[src/data/chapter4-755.content.json:1194](../src/data/chapter4-755.content.json#L1194)；[src/data/chapter4-755.content.json:1222](../src/data/chapter4-755.content.json#L1222)；[src/data/chapter4-755.content.json:1228](../src/data/chapter4-755.content.json#L1228)；[src/data/chapter4-755.content.json:1234](../src/data/chapter4-755.content.json#L1234)；[src/data/chapter4-755.content.json:1248](../src/data/chapter4-755.content.json#L1248)；[src/data/chapter4-755.content.json:1254](../src/data/chapter4-755.content.json#L1254)；[src/data/chapter4-755.content.json:1260](../src/data/chapter4-755.content.json#L1260)；[src/data/chapter4-755.content.json:1266](../src/data/chapter4-755.content.json#L1266)；[src/data/chapter4-755.content.json:1274](../src/data/chapter4-755.content.json#L1274)；[src/data/chapter4-755.content.json:1280](../src/data/chapter4-755.content.json#L1280)；[src/data/chapter4-755.content.json:1288](../src/data/chapter4-755.content.json#L1288)；[src/scenes/phone/P14_Wechat/index.tsx:447](../src/scenes/phone/P14_Wechat/index.tsx#L447)；[src/scenes/phone/P14_Wechat/index.tsx:450](../src/scenes/phone/P14_Wechat/index.tsx#L450)
429. 现场画面已同步。异常签到纸正在飞向公告栏。
   来源：[src/data/chapter4-755.content.json:991](../src/data/chapter4-755.content.json#L991)
430. player
   来源：[src/data/chapter4-755.content.json:996](../src/data/chapter4-755.content.json#L996)；[src/data/chapter4-755.content.json:1014](../src/data/chapter4-755.content.json#L1014)；[src/data/chapter4-755.content.json:1032](../src/data/chapter4-755.content.json#L1032)；[src/data/chapter4-755.content.json:1052](../src/data/chapter4-755.content.json#L1052)；[src/data/chapter4-755.content.json:1066](../src/data/chapter4-755.content.json#L1066)；[src/data/chapter4-755.content.json:1176](../src/data/chapter4-755.content.json#L1176)；[src/data/chapter4-755.content.json:1190](../src/data/chapter4-755.content.json#L1190)；[src/data/chapter4-755.content.json:1240](../src/data/chapter4-755.content.json#L1240)；[src/data/chapter4-755.content.json:1270](../src/data/chapter4-755.content.json#L1270)；[src/data/chapter4-755.content.json:1284](../src/data/chapter4-755.content.json#L1284)
431. 抓到了。
   来源：[src/data/chapter4-755.content.json:997](../src/data/chapter4-755.content.json#L997)
432. 正在提交签到记录……
   来源：[src/data/chapter4-755.content.json:1001](../src/data/chapter4-755.content.json#L1001)
433. 提交失败。外部时间：22:45。
   来源：[src/data/chapter4-755.content.json:1007](../src/data/chapter4-755.content.json#L1007)
434. 签到截止时间：07:55。
   来源：[src/data/chapter4-755.content.json:1011](../src/data/chapter4-755.content.json#L1011)
435. 手机上还写着 07:55:23。
   来源：[src/data/chapter4-755.content.json:1015](../src/data/chapter4-755.content.json#L1015)
436. 它已经被四个外部来源否定了。
   来源：[src/data/chapter4-755.content.json:1019](../src/data/chapter4-755.content.json#L1019)
437. 记录回来了，你没有回到记录发生的时候。
   来源：[src/data/chapter4-755.content.json:1023](../src/data/chapter4-755.content.json#L1023)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7297](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7297)
438. 旧钟能被拨动，但指针不会按你的动作走。
   来源：[src/data/chapter4-755.content.json:1029](../src/data/chapter4-755.content.json#L1029)
439. 这是好消息？
   来源：[src/data/chapter4-755.content.json:1033](../src/data/chapter4-755.content.json#L1033)
440. 它还在出错。
   来源：[src/data/chapter4-755.content.json:1037](../src/data/chapter4-755.content.json#L1037)
441. 时间源已切换：大厅旧钟。
   来源：[src/data/chapter4-755.content.json:1043](../src/data/chapter4-755.content.json#L1043)
442. baker
   来源：[src/data/chapter4-755.content.json:1048](../src/data/chapter4-755.content.json#L1048)；[src/data/chapter4-755.content.json:1056](../src/data/chapter4-755.content.json#L1056)
443. 你拿走那个？我还以为它是新品配料。
   来源：[src/data/chapter4-755.content.json:1049](../src/data/chapter4-755.content.json#L1049)
444. 它本来是时针。
   来源：[src/data/chapter4-755.content.json:1053](../src/data/chapter4-755.content.json#L1053)
445. 那它总算找到对口味了。
   来源：[src/data/chapter4-755.content.json:1057](../src/data/chapter4-755.content.json#L1057)
446. 黑板已经擦净，残留笔画仍按书写顺序逐段出现。首尾相差 7 分 55 秒。
   来源：[src/data/chapter4-755.content.json:1063](../src/data/chapter4-755.content.json#L1063)
447. 房间空了，板书还在补完上一节课。
   来源：[src/data/chapter4-755.content.json:1067](../src/data/chapter4-755.content.json#L1067)
448. 讲台回放停在 07:47:05，教室记录显示 07:55:00。本地画面延迟 7 分 55 秒。
   来源：[src/data/chapter4-755.content.json:1073](../src/data/chapter4-755.content.json#L1073)
449. 该终端只能证明回放延迟，不能用于校准现场时间。
   来源：[src/data/chapter4-755.content.json:1077](../src/data/chapter4-755.content.json#L1077)
450. 值班助理
   来源：[src/data/chapter4-755.content.json:1082](../src/data/chapter4-755.content.json#L1082)；[src/data/chapter4-755.content.json:1088](../src/data/chapter4-755.content.json#L1088)；[src/data/chapter4-755.content.json:1094](../src/data/chapter4-755.content.json#L1094)；[src/data/chapter4-755.content.json:1100](../src/data/chapter4-755.content.json#L1100)；[src/data/chapter4-755.content.json:1106](../src/data/chapter4-755.content.json#L1106)；[src/data/chapter4-755.content.json:1112](../src/data/chapter4-755.content.json#L1112)；[src/data/chapter4-755.content.json:1118](../src/data/chapter4-755.content.json#L1118)
451. 面包坊那边的传送带刚停过一次。旧钟缺少的部件可能在那里。
   来源：[src/data/chapter4-755.content.json:1083](../src/data/chapter4-755.content.json#L1083)
452. 104 要观察黑板残留，105 要检查讲台本地回放。两项都登记后，楼层通行才会恢复。
   来源：[src/data/chapter4-755.content.json:1089](../src/data/chapter4-755.content.json#L1089)
453. 104 已登记。105 讲台回放还没有检查。
   来源：[src/data/chapter4-755.content.json:1095](../src/data/chapter4-755.content.json#L1095)
454. 105 已登记。104 黑板残留还没有观察。
   来源：[src/data/chapter4-755.content.json:1101](../src/data/chapter4-755.content.json#L1101)
455. 两项时间差记录都已登记。现在可以继续核对二楼和三楼。
   来源：[src/data/chapter4-755.content.json:1107](../src/data/chapter4-755.content.json#L1107)
456. 现在是 07:55。校园卡放到左侧读卡器，签到纸放入右侧纸槽。
   来源：[src/data/chapter4-755.content.json:1113](../src/data/chapter4-755.content.json#L1113)
457. 大厅旧钟、签到记录和外部时间已经一致。今天的记录可以归档。
   来源：[src/data/chapter4-755.content.json:1119](../src/data/chapter4-755.content.json#L1119)
458. 安全员
   来源：[src/data/chapter4-755.content.json:1124](../src/data/chapter4-755.content.json#L1124)；[src/data/chapter4-755.content.json:1130](../src/data/chapter4-755.content.json#L1130)；[src/data/chapter4-755.content.json:1136](../src/data/chapter4-755.content.json#L1136)
459. 二楼电梯口暂不放行。先把一楼 104 黑板残留和 105 讲台回放都登记完。
   来源：[src/data/chapter4-755.content.json:1125](../src/data/chapter4-755.content.json#L1125)
460. 一楼两项记录已到。先去三楼参照教室核对标准布局，再回 204。
   来源：[src/data/chapter4-755.content.json:1131](../src/data/chapter4-755.content.json#L1131)
461. 三楼参照已登记。现在可以进 204，按残影恢复讲台和桌椅位置。
   来源：[src/data/chapter4-755.content.json:1137](../src/data/chapter4-755.content.json#L1137)
462. 教师
   来源：[src/data/chapter4-755.content.json:1142](../src/data/chapter4-755.content.json#L1142)；[src/data/chapter4-755.content.json:1148](../src/data/chapter4-755.content.json#L1148)
463. 这间教室保留标准布局。用浅色操作记录讲台和十二组桌椅，完成后回二楼 204。
   来源：[src/data/chapter4-755.content.json:1143](../src/data/chapter4-755.content.json#L1143)
464. 标准布局已经记录。二楼 204 需要的是这份参照。
   来源：[src/data/chapter4-755.content.json:1149](../src/data/chapter4-755.content.json#L1149)
465. projection
   来源：[src/data/chapter4-755.content.json:1154](../src/data/chapter4-755.content.json#L1154)
466. 07:55 / 早到的人还没有开始后悔。
   来源：[src/data/chapter4-755.content.json:1155](../src/data/chapter4-755.content.json#L1155)；[src/data/chapter4-three-floor-maze.layout.json:250](../src/data/chapter4-three-floor-maze.layout.json#L250)
467. 303 的 12 组参照位置已经记录。
   来源：[src/data/chapter4-755.content.json:1161](../src/data/chapter4-755.content.json#L1161)
468. 残影把每组桌椅原来的位置都记下来了。
   来源：[src/data/chapter4-755.content.json:1167](../src/data/chapter4-755.content.json#L1167)
469. cleaner
   来源：[src/data/chapter4-755.content.json:1172](../src/data/chapter4-755.content.json#L1172)；[src/data/chapter4-755.content.json:1180](../src/data/chapter4-755.content.json#L1180)
470. 它没坏，只是不肯走。
   来源：[src/data/chapter4-755.content.json:1173](../src/data/chapter4-755.content.json#L1173)
471. 我有办法让它走。
   来源：[src/data/chapter4-755.content.json:1177](../src/data/chapter4-755.content.json#L1177)
472. 那你先让它别叫。
   来源：[src/data/chapter4-755.content.json:1181](../src/data/chapter4-755.content.json#L1181)
473. 时间校准至 07:54。
   来源：[src/data/chapter4-755.content.json:1187](../src/data/chapter4-755.content.json#L1187)
474. 差一分钟。
   来源：[src/data/chapter4-755.content.json:1191](../src/data/chapter4-755.content.json#L1191)
475. 纸条把最后一分钟带走了。定位结果：阶梯教室。
   来源：[src/data/chapter4-755.content.json:1195](../src/data/chapter4-755.content.json#L1195)
476. guard
   来源：[src/data/chapter4-755.content.json:1200](../src/data/chapter4-755.content.json#L1200)；[src/data/chapter4-755.content.json:1206](../src/data/chapter4-755.content.json#L1206)；[src/data/chapter4-755.content.json:1212](../src/data/chapter4-755.content.json#L1212)；[src/data/chapter4-755.content.json:1218](../src/data/chapter4-755.content.json#L1218)
477. 同学，站住。离旧钟远一点。
   来源：[src/data/chapter4-755.content.json:1201](../src/data/chapter4-755.content.json#L1201)；[src/data/pursuit.audio.content.json:87](../src/data/pursuit.audio.content.json#L87)
478. 我看到你了。停下。
   来源：[src/data/chapter4-755.content.json:1207](../src/data/chapter4-755.content.json#L1207)；[src/data/pursuit.audio.content.json:115](../src/data/pursuit.audio.content.json#L115)
479. 别往楼上跑。现在停下。
   来源：[src/data/chapter4-755.content.json:1213](../src/data/chapter4-755.content.json#L1213)；[src/data/pursuit.audio.content.json:101](../src/data/pursuit.audio.content.json#L101)
480. 出去。
   来源：[src/data/chapter4-755.content.json:1219](../src/data/chapter4-755.content.json#L1219)
481. 你被清楼流程退回了上一分钟。
   来源：[src/data/chapter4-755.content.json:1223](../src/data/chapter4-755.content.json#L1223)
482. 被清楼保安拦下了，已回到一楼大厅重来。
   来源：[src/data/chapter4-755.content.json:1229](../src/data/chapter4-755.content.json#L1229)
483. 阶梯教室门已关闭。
   来源：[src/data/chapter4-755.content.json:1235](../src/data/chapter4-755.content.json#L1235)
484. 不跑了？
   来源：[src/data/chapter4-755.content.json:1241](../src/data/chapter4-755.content.json#L1241)
485. paper
   来源：[src/data/chapter4-755.content.json:1244](../src/data/chapter4-755.content.json#L1244)
486. 本人马上回来。
   来源：[src/data/chapter4-755.content.json:1245](../src/data/chapter4-755.content.json#L1245)
487. 它回来了。
   来源：[src/data/chapter4-755.content.json:1249](../src/data/chapter4-755.content.json#L1249)
488. 最后一分钟和签到纸条都回来了。
   来源：[src/data/chapter4-755.content.json:1255](../src/data/chapter4-755.content.json#L1255)
489. 07:55 已经回到门厅。
   来源：[src/data/chapter4-755.content.json:1261](../src/data/chapter4-755.content.json#L1261)
490. 签到成功。时间：07:55。地点：段永平教学楼 A1。状态：本人来过。
   来源：[src/data/chapter4-755.content.json:1267](../src/data/chapter4-755.content.json#L1267)
491. 现在算准时吗？
   来源：[src/data/chapter4-755.content.json:1271](../src/data/chapter4-755.content.json#L1271)
492. 从时间角度，算。
   来源：[src/data/chapter4-755.content.json:1275](../src/data/chapter4-755.content.json#L1275)
493. 外面亮了一下。
   来源：[src/data/chapter4-755.content.json:1281](../src/data/chapter4-755.content.json#L1281)；[src/modules/ChapterFourTemporalMazeController.ts:1446](../src/modules/ChapterFourTemporalMazeController.ts#L1446)；[src/modules/ChapterFourTemporalMazeController.ts:1474](../src/modules/ChapterFourTemporalMazeController.ts#L1474)
494. 这次真的结束了？
   来源：[src/data/chapter4-755.content.json:1285](../src/data/chapter4-755.content.json#L1285)
495. 这次是。时间同意了。
   来源：[src/data/chapter4-755.content.json:1289](../src/data/chapter4-755.content.json#L1289)
496. 大厅
   来源：[src/data/chapter4-755.content.json:1398](../src/data/chapter4-755.content.json#L1398)
497. 西走廊
   来源：[src/data/chapter4-755.content.json:1408](../src/data/chapter4-755.content.json#L1408)
498. 东走廊
   来源：[src/data/chapter4-755.content.json:1418](../src/data/chapter4-755.content.json#L1418)
499. 教室区
   来源：[src/data/chapter4-755.content.json:1428](../src/data/chapter4-755.content.json#L1428)
500. 面包店后场
   来源：[src/data/chapter4-755.content.json:1438](../src/data/chapter4-755.content.json#L1438)
501. 学习天地资料索引帖
   来源：[src/data/chapter4-cc98.content.json:3](../src/data/chapter4-cc98.content.json#L3)
502. 学习天地
   来源：[src/data/chapter4-cc98.content.json:4](../src/data/chapter4-cc98.content.json#L4)
503. 课程资料整理员
   来源：[src/data/chapter4-cc98.content.json:7](../src/data/chapter4-cc98.content.json#L7)
504. 学习天地资料索引帖，课程和年份入口已补齐
   来源：[src/data/chapter4-cc98.content.json:10](../src/data/chapter4-cc98.content.json#L10)
505. 26-07-10 22:18
   来源：[src/data/chapter4-cc98.content.json:11](../src/data/chapter4-cc98.content.json#L11)
506. 把学习天地里散着的课程资料重新挂了一遍。点课程名先选年份，再看对应目录和旧自习讨论。段永平教学楼 A2 的房间情况与东西侧路线请到现场核对，CC98 只提供资料入口，麦斯威夜间自习群的即时消息仍要单独查看。
   来源：[src/data/chapter4-cc98.content.json:12](../src/data/chapter4-cc98.content.json#L12)
507. 旧自习讨论
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
508. 课程资料
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
509. 年份入口
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
510. 高数周三晚
   来源：[src/data/chapter4-cc98.content.json:18](../src/data/chapter4-cc98.content.json#L18)
511. 22:21
   来源：[src/data/chapter4-cc98.content.json:19](../src/data/chapter4-cc98.content.json#L19)
512. 2楼
   来源：[src/data/chapter4-cc98.content.json:20](../src/data/chapter4-cc98.content.json#L20)
513. 课程
   来源：[src/data/chapter4-cc98.content.json:21](../src/data/chapter4-cc98.content.json#L21)
514. 我按 2023 秋季高数点进去，先看到讲义，再看到自习室讨论。旧帖里的日期要自己看清，别把去年的开门时间当今晚用。
   来源：[src/data/chapter4-cc98.content.json:22](../src/data/chapter4-cc98.content.json#L22)
515. 打印室常客
   来源：[src/data/chapter4-cc98.content.json:26](../src/data/chapter4-cc98.content.json#L26)
516. 22:24
   来源：[src/data/chapter4-cc98.content.json:27](../src/data/chapter4-cc98.content.json#L27)
517. 3楼
   来源：[src/data/chapter4-cc98.content.json:28](../src/data/chapter4-cc98.content.json#L28)
518. 打印
   来源：[src/data/chapter4-cc98.content.json:29](../src/data/chapter4-cc98.content.json#L29)
519. 课程名搜不全时可以只输两个字。我刚从西区打印室回来，按年份找到的文件比首页推荐的少一堆，下载前先看页数。
   来源：[src/data/chapter4-cc98.content.json:30](../src/data/chapter4-cc98.content.json#L30)
520. 麦斯威靠窗位
   来源：[src/data/chapter4-cc98.content.json:34](../src/data/chapter4-cc98.content.json#L34)
521. 22:27
   来源：[src/data/chapter4-cc98.content.json:35](../src/data/chapter4-cc98.content.json#L35)
522. 4楼
   来源：[src/data/chapter4-cc98.content.json:36](../src/data/chapter4-cc98.content.json#L36)
523. 自习
   来源：[src/data/chapter4-cc98.content.json:37](../src/data/chapter4-cc98.content.json#L37)
524. 旧自习讨论里有人记过插座和座位，但每天的空位都不一样。今晚我 21:50 到麦斯威，靠窗第三张桌已经有人了。
   来源：[src/data/chapter4-cc98.content.json:38](../src/data/chapter4-cc98.content.json#L38)
525. 资料夹分层
   来源：[src/data/chapter4-cc98.content.json:42](../src/data/chapter4-cc98.content.json#L42)
526. 22:30
   来源：[src/data/chapter4-cc98.content.json:43](../src/data/chapter4-cc98.content.json#L43)
527. 5楼
   来源：[src/data/chapter4-cc98.content.json:44](../src/data/chapter4-cc98.content.json#L44)
528. 整理
   来源：[src/data/chapter4-cc98.content.json:45](../src/data/chapter4-cc98.content.json#L45)
529. 年份入口按课程分开看比较省事。我把 2022 和 2024 的资料放进两个文件夹，旧讨论单独留着，方便对照当时的说法。
   来源：[src/data/chapter4-cc98.content.json:46](../src/data/chapter4-cc98.content.json#L46)
530. A2 晚课生
   来源：[src/data/chapter4-cc98.content.json:50](../src/data/chapter4-cc98.content.json#L50)
531. 22:34
   来源：[src/data/chapter4-cc98.content.json:51](../src/data/chapter4-cc98.content.json#L51)
532. 6楼
   来源：[src/data/chapter4-cc98.content.json:52](../src/data/chapter4-cc98.content.json#L52)
533. 现场
   来源：[src/data/chapter4-cc98.content.json:53](../src/data/chapter4-cc98.content.json#L53)
534. A2 里面的房间和走廊晚上会变，帖子里的课程资料只能帮忙认入口。到楼里以后按当晚看到的门牌和通道走，别照旧帖直接抄路线。
   来源：[src/data/chapter4-cc98.content.json:54](../src/data/chapter4-cc98.content.json#L54)
535. 群里等消息
   来源：[src/data/chapter4-cc98.content.json:58](../src/data/chapter4-cc98.content.json#L58)
536. 22:38
   来源：[src/data/chapter4-cc98.content.json:59](../src/data/chapter4-cc98.content.json#L59)
537. 7楼
   来源：[src/data/chapter4-cc98.content.json:60](../src/data/chapter4-cc98.content.json#L60)
538. 提醒
   来源：[src/data/chapter4-cc98.content.json:61](../src/data/chapter4-cc98.content.json#L61)
539. 导入群里以后，课程和年份会留在群文件，现场有人发的新消息还在聊天里。去段永平教学楼核对时，两个地方都看一眼。
   来源：[src/data/chapter4-cc98.content.json:62](../src/data/chapter4-cc98.content.json#L62)
540. 导入到麦斯威夜间自习群
   来源：[src/data/chapter4-cc98.content.json:66](../src/data/chapter4-cc98.content.json#L66)
541. 把课程年份入口和旧自习讨论带进自习群
   来源：[src/data/chapter4-cc98.content.json:67](../src/data/chapter4-cc98.content.json#L67)
542. 已导入学习天地资料索引。课程和年份入口会留在群文件，段永平教学楼 A2 的房间与东西侧路线仍需到现场核验。
   来源：[src/data/chapter4-cc98.content.json:68](../src/data/chapter4-cc98.content.json#L68)
543. 这份学习天地资料索引已经导入麦斯威夜间自习群，群文件不会重复添加。现场消息仍请查看聊天记录。
   来源：[src/data/chapter4-cc98.content.json:69](../src/data/chapter4-cc98.content.json#L69)
544. 当前章节还没到段永平教学楼 A2，暂时不能导入学习天地资料。先完成前面的现场调查，再回来查看。
   来源：[src/data/chapter4-cc98.content.json:70](../src/data/chapter4-cc98.content.json#L70)
545. 完成启真湖段落并进入第四章后，学习天地资料索引才会开放。
   来源：[src/data/chapter4-cc98.content.json:71](../src/data/chapter4-cc98.content.json#L71)
546. 麦斯威夜间自习群
   来源：[src/data/chapter4-cc98.content.json:74](../src/data/chapter4-cc98.content.json#L74)；[src/data/chapter4-wechat.content.json:98](../src/data/chapter4-wechat.content.json#L98)
547. 资料索引已放进群文件。群聊继续接收今晚的现场消息，A2 房间核验与东西侧路线以现场和群聊记录为准。
   来源：[src/data/chapter4-cc98.content.json:75](../src/data/chapter4-cc98.content.json#L75)
548. CC98 的课程、年份入口和旧自习讨论只用于查资料，不能替代微信现场消息。
   来源：[src/data/chapter4-cc98.content.json:76](../src/data/chapter4-cc98.content.json#L76)
549. 打开麦斯威夜间自习群，查看刚导入的资料索引和最新现场消息。
   来源：[src/data/chapter4-cc98.content.json:77](../src/data/chapter4-cc98.content.json#L77)
550. 校时终端
   来源：[src/data/chapter4-clock.content.json:3](../src/data/chapter4-clock.content.json#L3)
551. 本机时间冻结在 07:55:23。B2-04 的签到终端只接受经三路设备共同确认的 08:00:00。
   来源：[src/data/chapter4-clock.content.json:4](../src/data/chapter4-clock.content.json#L4)
552. 档案
   来源：[src/data/chapter4-clock.content.json:6](../src/data/chapter4-clock.content.json#L6)
553. 机芯
   来源：[src/data/chapter4-clock.content.json:7](../src/data/chapter4-clock.content.json#L7)
554. 漂移
   来源：[src/data/chapter4-clock.content.json:8](../src/data/chapter4-clock.content.json#L8)
555. 放行
   来源：[src/data/chapter4-clock.content.json:9](../src/data/chapter4-clock.content.json#L9)
556. 重建签到档案
   来源：[src/data/chapter4-clock.content.json:12](../src/data/chapter4-clock.content.json#L12)
557. B2-04 异常记录
   来源：[src/data/chapter4-clock.content.json:13](../src/data/chapter4-clock.content.json#L13)
558. 先从六条混杂记录中选出互相支持的三条证据，再据此选择目标时刻。缺少证据或选错时刻都会被终端拒绝。
   来源：[src/data/chapter4-clock.content.json:14](../src/data/chapter4-clock.content.json#L14)
559. 门厅残影
   来源：[src/data/chapter4-clock.content.json:16](../src/data/chapter4-clock.content.json#L16)；[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
560. 纸条最后进入 B2-04，门牌没有发生位移。
   来源：[src/data/chapter4-clock.content.json:16](../src/data/chapter4-clock.content.json#L16)
561. 课程调整
   来源：[src/data/chapter4-clock.content.json:17](../src/data/chapter4-clock.content.json#L17)
562. 临时教室开放时间提前到 08:00。
   来源：[src/data/chapter4-clock.content.json:17](../src/data/chapter4-clock.content.json#L17)
563. 签到日志
   来源：[src/data/chapter4-clock.content.json:18](../src/data/chapter4-clock.content.json#L18)
564. B2-04 终端在整点首次接受学生签到。
   来源：[src/data/chapter4-clock.content.json:18](../src/data/chapter4-clock.content.json#L18)
565. 闭馆广播
   来源：[src/data/chapter4-clock.content.json:19](../src/data/chapter4-clock.content.json#L19)
566. 该记录来自基础图书馆，与本楼终端无关。
   来源：[src/data/chapter4-clock.content.json:19](../src/data/chapter4-clock.content.json#L19)
567. 剧场放票
   来源：[src/data/chapter4-clock.content.json:20](../src/data/chapter4-clock.content.json#L20)
568. 手机缓存中的剧场票务时间。
   来源：[src/data/chapter4-clock.content.json:20](../src/data/chapter4-clock.content.json#L20)
569. 0755 是窗口暗号，无法作为教学楼时间。
   来源：[src/data/chapter4-clock.content.json:21](../src/data/chapter4-clock.content.json#L21)
570. 食堂取餐
   来源：[src/data/chapter4-clock.content.json:21](../src/data/chapter4-clock.content.json#L21)
571. 07:55
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
572. 当前停留
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
573. 冻结
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
574. 手机异常
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
575. 08:00
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
576. 签到开放
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
577. 早间
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
578. B2-04
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)；[src/data/chapter4-clock.content.json:51](../src/data/chapter4-clock.content.json#L51)；[src/data/chapter4-clock.content.json:61](../src/data/chapter4-clock.content.json#L61)
579. 08:32
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
580. 剧场
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
581. 票务缓存
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
582. 外部记录
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
583. 22:45
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
584. 闭楼
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
585. 进入时刻
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
586. 锁定双机芯
   来源：[src/data/chapter4-clock.content.json:31](../src/data/chapter4-clock.content.json#L31)
587. 小时轮与分钟轮拥有独立锁扣。先把对应数字调到目标值，再分别锁定；已经锁定的机芯不能继续旋转。
   来源：[src/data/chapter4-clock.content.json:32](../src/data/chapter4-clock.content.json#L32)
588. 小时机芯
   来源：[src/data/chapter4-clock.content.json:34](../src/data/chapter4-clock.content.json#L34)
589. 分钟机芯
   来源：[src/data/chapter4-clock.content.json:35](../src/data/chapter4-clock.content.json#L35)
590. 锁定机芯
   来源：[src/data/chapter4-clock.content.json:36](../src/data/chapter4-clock.content.json#L36)
591. 已锁定
   来源：[src/data/chapter4-clock.content.json:37](../src/data/chapter4-clock.content.json#L37)
592. 爆炸视图
   来源：[src/data/chapter4-clock.content.json:38](../src/data/chapter4-clock.content.json#L38)
593. 装配视图
   来源：[src/data/chapter4-clock.content.json:39](../src/data/chapter4-clock.content.json#L39)
594. 复位视角
   来源：[src/data/chapter4-clock.content.json:40](../src/data/chapter4-clock.content.json#L40)
595. 上下拖动机芯齿轮、滚轮或点按 ± 调节读数,对准 08:00 后锁定对应机芯。
   来源：[src/data/chapter4-clock.content.json:41](../src/data/chapter4-clock.content.json#L41)
596. 目标 08:00
   来源：[src/data/chapter4-clock.content.json:42](../src/data/chapter4-clock.content.json#L42)
597. 消除三路设备漂移
   来源：[src/data/chapter4-clock.content.json:46](../src/data/chapter4-clock.content.json#L46)
598. 校门、电梯和教室终端记录了不同方向的秒差。逐条选择反向修正值，三路归零后才能形成 08:00:00。
   来源：[src/data/chapter4-clock.content.json:47](../src/data/chapter4-clock.content.json#L47)
599. 校门闸机
   来源：[src/data/chapter4-clock.content.json:49](../src/data/chapter4-clock.content.json#L49)
600. 主电梯
   来源：[src/data/chapter4-clock.content.json:50](../src/data/chapter4-clock.content.json#L50)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:951](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L951)
601. 通过三种放行协议
   来源：[src/data/chapter4-clock.content.json:56](../src/data/chapter4-clock.content.json#L56)
602. 三轮拥有不同速度与有效窗口：校门宽窗、主梯窄窗、教室反向扫描。每轮只需命中一次，失败会回到第一轮。
   来源：[src/data/chapter4-clock.content.json:57](../src/data/chapter4-clock.content.json#L57)
603. 宽窗 / 常速
   来源：[src/data/chapter4-clock.content.json:59](../src/data/chapter4-clock.content.json#L59)
604. 校门
   来源：[src/data/chapter4-clock.content.json:59](../src/data/chapter4-clock.content.json#L59)
605. 窄窗 / 加速
   来源：[src/data/chapter4-clock.content.json:60](../src/data/chapter4-clock.content.json#L60)
606. 主梯
   来源：[src/data/chapter4-clock.content.json:60](../src/data/chapter4-clock.content.json#L60)
607. 偏置窗 / 反扫
   来源：[src/data/chapter4-clock.content.json:61](../src/data/chapter4-clock.content.json#L61)
608. 07:55 冻结已解除
   来源：[src/data/chapter4-clock.content.json:65](../src/data/chapter4-clock.content.json#L65)
609. 三路设备同时写入 08:00:00，B2-04 签到终端恢复。
   来源：[src/data/chapter4-clock.content.json:66](../src/data/chapter4-clock.content.json#L66)
610. 校时权限尚未开放
   来源：[src/data/chapter4-clock.content.json:69](../src/data/chapter4-clock.content.json#L69)
611. 先完成教学楼内的十二个时间节点，再回到手机处理 B2-04。
   来源：[src/data/chapter4-clock.content.json:70](../src/data/chapter4-clock.content.json#L70)
612. 档案证据不足，或所选时刻与三条有效记录不一致。
   来源：[src/data/chapter4-clock.content.json:73](../src/data/chapter4-clock.content.json#L73)
613. 当前机芯或漂移修正仍未满足这一关的条件。
   来源：[src/data/chapter4-clock.content.json:74](../src/data/chapter4-clock.content.json#L74)
614. 本轮放行失败，协议进度已回到校门。
   来源：[src/data/chapter4-clock.content.json:75](../src/data/chapter4-clock.content.json#L75)
615. 该操作当前不可用，检查本关已经锁定的部分。
   来源：[src/data/chapter4-clock.content.json:76](../src/data/chapter4-clock.content.json#L76)
616. 校时已经完成。
   来源：[src/data/chapter4-clock.content.json:77](../src/data/chapter4-clock.content.json#L77)
617. 三条档案证据成立，08:00 已设为校准目标。
   来源：[src/data/chapter4-clock.content.json:78](../src/data/chapter4-clock.content.json#L78)
618. 双机芯锁定，开始核对三路设备漂移。
   来源：[src/data/chapter4-clock.content.json:79](../src/data/chapter4-clock.content.json#L79)
619. 三路漂移全部归零，进入最终放行。
   来源：[src/data/chapter4-clock.content.json:80](../src/data/chapter4-clock.content.json#L80)
620. 三种协议均已通过，冻结解除。
   来源：[src/data/chapter4-clock.content.json:81](../src/data/chapter4-clock.content.json#L81)
621. 系统：三路设备已归零。等待三种协议放行。
   来源：[src/data/chapter4-clock.content.json:83](../src/data/chapter4-clock.content.json#L83)
622. 玩家：三路记录同时变成了 08:00。
   来源：[src/data/chapter4-clock.content.json:85](../src/data/chapter4-clock.content.json#L85)
623. 系统：校时确认。B2-04 签到终端恢复。
   来源：[src/data/chapter4-clock.content.json:86](../src/data/chapter4-clock.content.json#L86)
624. 玩家：07:55 的冻结解除了。
   来源：[src/data/chapter4-clock.content.json:87](../src/data/chapter4-clock.content.json#L87)
625. 系统：校时完成。07:55 的冻结已解除。
   来源：[src/data/chapter4-clock.content.json:89](../src/data/chapter4-clock.content.json#L89)
626. 完成四关校时
   来源：[src/data/chapter4-clock.content.json:91](../src/data/chapter4-clock.content.json#L91)
627. 筛选三条有效档案，再选择对应时刻。
   来源：[src/data/chapter4-clock.content.json:93](../src/data/chapter4-clock.content.json#L93)
628. 分别校准并锁定小时、分钟两组机芯。
   来源：[src/data/chapter4-clock.content.json:94](../src/data/chapter4-clock.content.json#L94)
629. 为校门、电梯和 B2-04 选择反向漂移修正。
   来源：[src/data/chapter4-clock.content.json:95](../src/data/chapter4-clock.content.json#L95)
630. 依次通过三种速度与窗口不同的放行协议。
   来源：[src/data/chapter4-clock.content.json:96](../src/data/chapter4-clock.content.json#L96)
631. 校时已完成。
   来源：[src/data/chapter4-clock.content.json:97](../src/data/chapter4-clock.content.json#L97)
632. 又断了。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:35](../src/data/chapter4-prologue-voice.audio.content.json#L35)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:69](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L69)
633. It broke again.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:36](../src/data/chapter4-prologue-voice.audio.content.json#L36)
634. 湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:49](../src/data/chapter4-prologue-voice.audio.content.json#L49)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:77](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L77)
635. The lake did not keep it. The night wind carried it into the teaching building that was still lit.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:50](../src/data/chapter4-prologue-voice.audio.content.json#L50)
636. 小心，刚拖过。那张纸往里去了。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:63](../src/data/chapter4-prologue-voice.audio.content.json#L63)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:85](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L85)
637. Careful, I just mopped. That paper went inside.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:64](../src/data/chapter4-prologue-voice.audio.content.json#L64)
638. 同学，北教要清楼了，请收好东西。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:79](../src/data/chapter4-prologue-voice.audio.content.json#L79)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:93](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L93)
639. The North Teaching Building is closing. Please pack up.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:80](../src/data/chapter4-prologue-voice.audio.content.json#L80)
640. 段永平教学楼时间迷宫
   来源：[src/data/chapter4-temporal-maze.content.json:3](../src/data/chapter4-temporal-maze.content.json#L3)
641. 进入一楼门厅，确认湿纸留下的气流轨迹
   来源：[src/data/chapter4-temporal-maze.content.json:5](../src/data/chapter4-temporal-maze.content.json#L5)；[src/data/chapter4-temporal-maze.content.json:120](../src/data/chapter4-temporal-maze.content.json#L120)
642. 深色观察可查看门厅中央的断续水迹。
   来源：[src/data/chapter4-temporal-maze.content.json:6](../src/data/chapter4-temporal-maze.content.json#L6)
643. 恢复纸条进入主电梯厅的风路
   来源：[src/data/chapter4-temporal-maze.content.json:9](../src/data/chapter4-temporal-maze.content.json#L9)；[src/data/chapter4-temporal-maze.content.json:121](../src/data/chapter4-temporal-maze.content.json#L121)
644. 深色观察：地面水迹从玻璃门延伸到迈斯威卷帘门。
   来源：[src/data/chapter4-temporal-maze.content.json:10](../src/data/chapter4-temporal-maze.content.json#L10)
645. 浅色操作：到迈斯威卷帘门前，借助暖风把纸条送向主电梯。
   来源：[src/data/chapter4-temporal-maze.content.json:11](../src/data/chapter4-temporal-maze.content.json#L11)
646. 已记录气流轨迹。浅色操作可在迈斯威卷帘门前恢复风路。
   来源：[src/data/chapter4-temporal-maze.content.json:12](../src/data/chapter4-temporal-maze.content.json#L12)
647. 暖风重新接上水迹，湿纸进入主电梯厅。
   来源：[src/data/chapter4-temporal-maze.content.json:13](../src/data/chapter4-temporal-maze.content.json#L13)
648. 在主电梯厅同步纸条留下的历史轨道
   来源：[src/data/chapter4-temporal-maze.content.json:16](../src/data/chapter4-temporal-maze.content.json#L16)；[src/data/chapter4-temporal-maze.content.json:122](../src/data/chapter4-temporal-maze.content.json#L122)
649. 深色观察：读取轿厢、门体与玩家进入窗口三条历史轨道。
   来源：[src/data/chapter4-temporal-maze.content.json:17](../src/data/chapter4-temporal-maze.content.json#L17)
650. 浅色操作：拖动轿厢轨道，让一楼开门区间完整覆盖六秒进入窗口。
   来源：[src/data/chapter4-temporal-maze.content.json:18](../src/data/chapter4-temporal-maze.content.json#L18)
651. 当前校准动作需要浅色操作；深色观察可独立读取三条历史轨道。
   来源：[src/data/chapter4-temporal-maze.content.json:19](../src/data/chapter4-temporal-maze.content.json#L19)
652. 三轨已经对齐。电梯返回一楼，等待门体完全打开。
   来源：[src/data/chapter4-temporal-maze.content.json:20](../src/data/chapter4-temporal-maze.content.json#L20)
653. 开门区间没有完整覆盖进入窗口。调整重放起点后再试。
   来源：[src/data/chapter4-temporal-maze.content.json:21](../src/data/chapter4-temporal-maze.content.json#L21)
654. 开门窗口已经结束。再次启动历史重放。
   来源：[src/data/chapter4-temporal-maze.content.json:22](../src/data/chapter4-temporal-maze.content.json#L22)
655. 历史片段继续运行，已到达 A2。
   来源：[src/data/chapter4-temporal-maze.content.json:23](../src/data/chapter4-temporal-maze.content.json#L23)
656. 深色观察：记录同一时间片内经过门口和停留区的人员残影。
   来源：[src/data/chapter4-temporal-maze.content.json:51](../src/data/chapter4-temporal-maze.content.json#L51)
657. 三组人员时刻已记录。浅色操作可处理可见隔断。
   来源：[src/data/chapter4-temporal-maze.content.json:52](../src/data/chapter4-temporal-maze.content.json#L52)
658. 浅色操作：依照已记录的空档逐一移动两组可见隔断。
   来源：[src/data/chapter4-temporal-maze.content.json:56](../src/data/chapter4-temporal-maze.content.json#L56)
659. 人员时刻证据尚未完整；两种现实模式的交互入口都保持开放。
   来源：[src/data/chapter4-temporal-maze.content.json:57](../src/data/chapter4-temporal-maze.content.json#L57)
660. 内圈支路已接通，开放学习区现在可达。
   来源：[src/data/chapter4-temporal-maze.content.json:58](../src/data/chapter4-temporal-maze.content.json#L58)
661. 在开放学习区取得两块导视碎片。
   来源：[src/data/chapter4-temporal-maze.content.json:66](../src/data/chapter4-temporal-maze.content.json#L66)
662. 深色观察：读取旧导视残影。
   来源：[src/data/chapter4-temporal-maze.content.json:67](../src/data/chapter4-temporal-maze.content.json#L67)
663. 旧导视残影已记录。浅色操作可重建导视板。
   来源：[src/data/chapter4-temporal-maze.content.json:68](../src/data/chapter4-temporal-maze.content.json#L68)
664. 浅色操作：比较当前导视照片、旧残影与二楼入口方向，自行判断缺失槽位和两块碎片的位置。
   来源：[src/data/chapter4-temporal-maze.content.json:69](../src/data/chapter4-temporal-maze.content.json#L69)
665. 碎片与当前历史记录不一致，重新检查已记录的导视痕迹。
   来源：[src/data/chapter4-temporal-maze.content.json:70](../src/data/chapter4-temporal-maze.content.json#L70)
666. 导视板恢复了一段可验证记录。返回已访问楼层继续取证。
   来源：[src/data/chapter4-temporal-maze.content.json:71](../src/data/chapter4-temporal-maze.content.json#L71)
667. 导视板恢复后，切到深色观察并读取入口开合与人员经过留下的历史痕迹。
   来源：[src/data/chapter4-temporal-maze.content.json:75](../src/data/chapter4-temporal-maze.content.json#L75)
668. 连廊历史已记录，可与导视碎片交叉核对。
   来源：[src/data/chapter4-temporal-maze.content.json:76](../src/data/chapter4-temporal-maze.content.json#L76)
669. 回到已访问区域，检查新出现的取证窗口。
   来源：[src/data/chapter4-temporal-maze.content.json:82](../src/data/chapter4-temporal-maze.content.json#L82)
670. 当前历史窗口尚未形成，继续核对已有证据。
   来源：[src/data/chapter4-temporal-maze.content.json:83](../src/data/chapter4-temporal-maze.content.json#L83)
671. 新的取证窗口已经开放，当前安全位置已保存。
   来源：[src/data/chapter4-temporal-maze.content.json:84](../src/data/chapter4-temporal-maze.content.json#L84)
672. 当前交通核心不能到达该楼层。
   来源：[src/data/chapter4-temporal-maze.content.json:87](../src/data/chapter4-temporal-maze.content.json#L87)
673. 仍缺当前步骤所需的证据。
   来源：[src/data/chapter4-temporal-maze.content.json:88](../src/data/chapter4-temporal-maze.content.json#L88)
674. 切换现实模式后再执行当前动作。
   来源：[src/data/chapter4-temporal-maze.content.json:89](../src/data/chapter4-temporal-maze.content.json#L89)
675. 当前路线条件尚未满足。
   来源：[src/data/chapter4-temporal-maze.content.json:90](../src/data/chapter4-temporal-maze.content.json#L90)
676. 四项外部记录
   来源：[src/data/chapter4-temporal-maze.content.json:99](../src/data/chapter4-temporal-maze.content.json#L99)
677. 大厅旧钟
   来源：[src/data/chapter4-temporal-maze.content.json:100](../src/data/chapter4-temporal-maze.content.json#L100)
678. 手机已同步
   来源：[src/data/chapter4-temporal-maze.content.json:103](../src/data/chapter4-temporal-maze.content.json#L103)
679. 手机未同步，当前读数不可信
   来源：[src/data/chapter4-temporal-maze.content.json:104](../src/data/chapter4-temporal-maze.content.json#L104)
680. 完成启真湖逃脱并进入教学楼
   来源：[src/data/chapter4-temporal-maze.content.json:119](../src/data/chapter4-temporal-maze.content.json#L119)
681. 根据夜间人员动线重建纸条路线
   来源：[src/data/chapter4-temporal-maze.content.json:123](../src/data/chapter4-temporal-maze.content.json#L123)
682. 重建二楼走廊等待区
   来源：[src/data/chapter4-temporal-maze.content.json:124](../src/data/chapter4-temporal-maze.content.json#L124)
683. 拼合楼层导视碎片
   来源：[src/data/chapter4-temporal-maze.content.json:125](../src/data/chapter4-temporal-maze.content.json#L125)
684. 确认连廊只位于三楼
   来源：[src/data/chapter4-temporal-maze.content.json:126](../src/data/chapter4-temporal-maze.content.json#L126)
685. 记录下层回声，旋转折返楼梯并接通 B2
   来源：[src/data/chapter4-temporal-maze.content.json:127](../src/data/chapter4-temporal-maze.content.json#L127)
686. 剪合多机位监控记录
   来源：[src/data/chapter4-temporal-maze.content.json:128](../src/data/chapter4-temporal-maze.content.json#L128)
687. 录制可在复位后重放的动作回声
   来源：[src/data/chapter4-temporal-maze.content.json:129](../src/data/chapter4-temporal-maze.content.json#L129)
688. 用两部电梯运输大型签到板
   来源：[src/data/chapter4-temporal-maze.content.json:130](../src/data/chapter4-temporal-maze.content.json#L130)
689. 在迈斯威暖风中控制纸条含水量
   来源：[src/data/chapter4-temporal-maze.content.json:131](../src/data/chapter4-temporal-maze.content.json#L131)
690. 从 23:30 复位点恢复第二循环
   来源：[src/data/chapter4-temporal-maze.content.json:132](../src/data/chapter4-temporal-maze.content.json#L132)
691. 安排第二循环的逆向运输路线
   来源：[src/data/chapter4-temporal-maze.content.json:133](../src/data/chapter4-temporal-maze.content.json#L133)
692. 校准 07:55 相位并打开 B2-04
   来源：[src/data/chapter4-temporal-maze.content.json:134](../src/data/chapter4-temporal-maze.content.json#L134)
693. 读取异常签到记录
   来源：[src/data/chapter4-temporal-maze.content.json:135](../src/data/chapter4-temporal-maze.content.json#L135)
694. 空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:833](../src/data/chapter4-three-floor-maze.layout.json#L833)；[src/data/chapter4-three-floor-maze.layout.json:842](../src/data/chapter4-three-floor-maze.layout.json#L842)；[src/data/chapter4-three-floor-maze.layout.json:851](../src/data/chapter4-three-floor-maze.layout.json#L851)；[src/data/chapter4-three-floor-maze.layout.json:860](../src/data/chapter4-three-floor-maze.layout.json#L860)；[src/data/chapter4-three-floor-maze.layout.json:869](../src/data/chapter4-three-floor-maze.layout.json#L869)；[src/data/chapter4-three-floor-maze.layout.json:878](../src/data/chapter4-three-floor-maze.layout.json#L878)；[src/data/chapter4-three-floor-maze.layout.json:887](../src/data/chapter4-three-floor-maze.layout.json#L887)；[src/data/chapter4-three-floor-maze.layout.json:896](../src/data/chapter4-three-floor-maze.layout.json#L896)；[src/data/chapter4-three-floor-maze.layout.json:905](../src/data/chapter4-three-floor-maze.layout.json#L905)；[src/data/chapter4-three-floor-maze.layout.json:914](../src/data/chapter4-three-floor-maze.layout.json#L914)；[src/data/chapter4-three-floor-maze.layout.json:923](../src/data/chapter4-three-floor-maze.layout.json#L923)；[src/data/chapter4-three-floor-maze.layout.json:1371](../src/data/chapter4-three-floor-maze.layout.json#L1371)；[src/data/chapter4-three-floor-maze.layout.json:1380](../src/data/chapter4-three-floor-maze.layout.json#L1380)；[src/data/chapter4-three-floor-maze.layout.json:1389](../src/data/chapter4-three-floor-maze.layout.json#L1389)；[src/data/chapter4-three-floor-maze.layout.json:1404](../src/data/chapter4-three-floor-maze.layout.json#L1404)；[src/data/chapter4-three-floor-maze.layout.json:1413](../src/data/chapter4-three-floor-maze.layout.json#L1413)；[src/data/chapter4-three-floor-maze.layout.json:1422](../src/data/chapter4-three-floor-maze.layout.json#L1422)；[src/data/chapter4-three-floor-maze.layout.json:1431](../src/data/chapter4-three-floor-maze.layout.json#L1431)；[src/data/chapter4-three-floor-maze.layout.json:1440](../src/data/chapter4-three-floor-maze.layout.json#L1440)；[src/data/chapter4-three-floor-maze.layout.json:1449](../src/data/chapter4-three-floor-maze.layout.json#L1449)；[src/data/chapter4-three-floor-maze.layout.json:1464](../src/data/chapter4-three-floor-maze.layout.json#L1464)；[src/data/chapter4-three-floor-maze.layout.json:1473](../src/data/chapter4-three-floor-maze.layout.json#L1473)；[src/data/chapter4-three-floor-maze.layout.json:1482](../src/data/chapter4-three-floor-maze.layout.json#L1482)；[src/data/chapter4-three-floor-maze.layout.json:1497](../src/data/chapter4-three-floor-maze.layout.json#L1497)；[src/data/chapter4-three-floor-maze.layout.json:1512](../src/data/chapter4-three-floor-maze.layout.json#L1512)；[src/data/chapter4-three-floor-maze.layout.json:1521](../src/data/chapter4-three-floor-maze.layout.json#L1521)；[src/data/chapter4-three-floor-maze.layout.json:1530](../src/data/chapter4-three-floor-maze.layout.json#L1530)；[src/data/chapter4-three-floor-maze.layout.json:1539](../src/data/chapter4-three-floor-maze.layout.json#L1539)；[src/data/chapter4-three-floor-maze.layout.json:1548](../src/data/chapter4-three-floor-maze.layout.json#L1548)；[src/data/chapter4-three-floor-maze.layout.json:1557](../src/data/chapter4-three-floor-maze.layout.json#L1557)；[src/data/chapter4-three-floor-maze.layout.json:1566](../src/data/chapter4-three-floor-maze.layout.json#L1566)；[src/data/chapter4-three-floor-maze.layout.json:1575](../src/data/chapter4-three-floor-maze.layout.json#L1575)；[src/data/chapter4-three-floor-maze.layout.json:1584](../src/data/chapter4-three-floor-maze.layout.json#L1584)；[src/data/chapter4-three-floor-maze.layout.json:1593](../src/data/chapter4-three-floor-maze.layout.json#L1593)；[src/data/chapter4-three-floor-maze.layout.json:1932](../src/data/chapter4-three-floor-maze.layout.json#L1932)；[src/data/chapter4-three-floor-maze.layout.json:1941](../src/data/chapter4-three-floor-maze.layout.json#L1941)；[src/data/chapter4-three-floor-maze.layout.json:1950](../src/data/chapter4-three-floor-maze.layout.json#L1950)；[src/data/chapter4-three-floor-maze.layout.json:1959](../src/data/chapter4-three-floor-maze.layout.json#L1959)；[src/data/chapter4-three-floor-maze.layout.json:1968](../src/data/chapter4-three-floor-maze.layout.json#L1968)；[src/data/chapter4-three-floor-maze.layout.json:1977](../src/data/chapter4-three-floor-maze.layout.json#L1977)；[src/data/chapter4-three-floor-maze.layout.json:1986](../src/data/chapter4-three-floor-maze.layout.json#L1986)；[src/data/chapter4-three-floor-maze.layout.json:1995](../src/data/chapter4-three-floor-maze.layout.json#L1995)；[src/data/chapter4-three-floor-maze.layout.json:2004](../src/data/chapter4-three-floor-maze.layout.json#L2004)；[src/data/chapter4-three-floor-maze.layout.json:2013](../src/data/chapter4-three-floor-maze.layout.json#L2013)；[src/data/chapter4-three-floor-maze.layout.json:2022](../src/data/chapter4-three-floor-maze.layout.json#L2022)；[src/data/chapter4-three-floor-maze.layout.json:2031](../src/data/chapter4-three-floor-maze.layout.json#L2031)；[src/data/chapter4-three-floor-maze.layout.json:2046](../src/data/chapter4-three-floor-maze.layout.json#L2046)
695. 北侧西段肖像墙下沿空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:932](../src/data/chapter4-three-floor-maze.layout.json#L932)
696. 北侧东段肖像墙下沿空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:941](../src/data/chapter4-three-floor-maze.layout.json#L941)
697. 前台柜台空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:950](../src/data/chapter4-three-floor-maze.layout.json#L950)
698. 面包坊门洞
   来源：[src/data/chapter4-three-floor-maze.layout.json:961](../src/data/chapter4-three-floor-maze.layout.json#L961)
699. 必须可通行
   来源：[src/data/chapter4-three-floor-maze.layout.json:971](../src/data/chapter4-three-floor-maze.layout.json#L971)；[src/data/chapter4-three-floor-maze.layout.json:981](../src/data/chapter4-three-floor-maze.layout.json#L981)；[src/data/chapter4-three-floor-maze.layout.json:991](../src/data/chapter4-three-floor-maze.layout.json#L991)；[src/data/chapter4-three-floor-maze.layout.json:1001](../src/data/chapter4-three-floor-maze.layout.json#L1001)；[src/data/chapter4-three-floor-maze.layout.json:1011](../src/data/chapter4-three-floor-maze.layout.json#L1011)；[src/data/chapter4-three-floor-maze.layout.json:1021](../src/data/chapter4-three-floor-maze.layout.json#L1021)；[src/data/chapter4-three-floor-maze.layout.json:1604](../src/data/chapter4-three-floor-maze.layout.json#L1604)；[src/data/chapter4-three-floor-maze.layout.json:1614](../src/data/chapter4-three-floor-maze.layout.json#L1614)；[src/data/chapter4-three-floor-maze.layout.json:1624](../src/data/chapter4-three-floor-maze.layout.json#L1624)；[src/data/chapter4-three-floor-maze.layout.json:1634](../src/data/chapter4-three-floor-maze.layout.json#L1634)；[src/data/chapter4-three-floor-maze.layout.json:1644](../src/data/chapter4-three-floor-maze.layout.json#L1644)；[src/data/chapter4-three-floor-maze.layout.json:2063](../src/data/chapter4-three-floor-maze.layout.json#L2063)；[src/data/chapter4-three-floor-maze.layout.json:2073](../src/data/chapter4-three-floor-maze.layout.json#L2073)；[src/data/chapter4-three-floor-maze.layout.json:2083](../src/data/chapter4-three-floor-maze.layout.json#L2083)；[src/data/chapter4-three-floor-maze.layout.json:2093](../src/data/chapter4-three-floor-maze.layout.json#L2093)；[src/data/chapter4-three-floor-maze.layout.json:2103](../src/data/chapter4-three-floor-maze.layout.json#L2103)；[src/data/chapter4-three-floor-maze.layout.json:2113](../src/data/chapter4-three-floor-maze.layout.json#L2113)
700. 前景遮挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:1033](../src/data/chapter4-three-floor-maze.layout.json#L1033)；[src/data/chapter4-three-floor-maze.layout.json:1046](../src/data/chapter4-three-floor-maze.layout.json#L1046)；[src/data/chapter4-three-floor-maze.layout.json:1059](../src/data/chapter4-three-floor-maze.layout.json#L1059)；[src/data/chapter4-three-floor-maze.layout.json:1072](../src/data/chapter4-three-floor-maze.layout.json#L1072)；[src/data/chapter4-three-floor-maze.layout.json:1085](../src/data/chapter4-three-floor-maze.layout.json#L1085)；[src/data/chapter4-three-floor-maze.layout.json:1098](../src/data/chapter4-three-floor-maze.layout.json#L1098)；[src/data/chapter4-three-floor-maze.layout.json:1111](../src/data/chapter4-three-floor-maze.layout.json#L1111)；[src/data/chapter4-three-floor-maze.layout.json:1656](../src/data/chapter4-three-floor-maze.layout.json#L1656)；[src/data/chapter4-three-floor-maze.layout.json:1669](../src/data/chapter4-three-floor-maze.layout.json#L1669)；[src/data/chapter4-three-floor-maze.layout.json:1682](../src/data/chapter4-three-floor-maze.layout.json#L1682)；[src/data/chapter4-three-floor-maze.layout.json:1695](../src/data/chapter4-three-floor-maze.layout.json#L1695)；[src/data/chapter4-three-floor-maze.layout.json:1708](../src/data/chapter4-three-floor-maze.layout.json#L1708)；[src/data/chapter4-three-floor-maze.layout.json:1721](../src/data/chapter4-three-floor-maze.layout.json#L1721)；[src/data/chapter4-three-floor-maze.layout.json:2125](../src/data/chapter4-three-floor-maze.layout.json#L2125)；[src/data/chapter4-three-floor-maze.layout.json:2138](../src/data/chapter4-three-floor-maze.layout.json#L2138)
701. 北侧西段肖像墙前景
   来源：[src/data/chapter4-three-floor-maze.layout.json:1124](../src/data/chapter4-three-floor-maze.layout.json#L1124)
702. 北侧东段肖像墙前景
   来源：[src/data/chapter4-three-floor-maze.layout.json:1138](../src/data/chapter4-three-floor-maze.layout.json#L1138)
703. 麦思威面包坊餐厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:1153](../src/data/chapter4-three-floor-maze.layout.json#L1153)
704. 一楼校友头像长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:1163](../src/data/chapter4-three-floor-maze.layout.json#L1163)
705. 104 教室门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:1173](../src/data/chapter4-three-floor-maze.layout.json#L1173)
706. 105 教室门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:1183](../src/data/chapter4-three-floor-maze.layout.json#L1183)
707. 104 黑板擦痕残留
   来源：[src/data/chapter4-three-floor-maze.layout.json:1193](../src/data/chapter4-three-floor-maze.layout.json#L1193)
708. 105 讲台回放终端
   来源：[src/data/chapter4-three-floor-maze.layout.json:1203](../src/data/chapter4-three-floor-maze.layout.json#L1203)
709. 一楼前台值班助理
   来源：[src/data/chapter4-three-floor-maze.layout.json:1213](../src/data/chapter4-three-floor-maze.layout.json#L1213)
710. 教学楼主入口
   来源：[src/data/chapter4-three-floor-maze.layout.json:1223](../src/data/chapter4-three-floor-maze.layout.json#L1223)
711. 公告栏前的签到记录纸条
   来源：[src/data/chapter4-three-floor-maze.layout.json:1233](../src/data/chapter4-three-floor-maze.layout.json#L1233)
712. 一楼旧钟
   来源：[src/data/chapter4-three-floor-maze.layout.json:1243](../src/data/chapter4-three-floor-maze.layout.json#L1243)
713. 旧钟时针插槽
   来源：[src/data/chapter4-three-floor-maze.layout.json:1253](../src/data/chapter4-three-floor-maze.layout.json#L1253)；[src/scenes/rpg/RpgInteractionContract.ts:562](../src/scenes/rpg/RpgInteractionContract.ts#L562)
714. 旧钟定位盘插槽
   来源：[src/data/chapter4-three-floor-maze.layout.json:1263](../src/data/chapter4-three-floor-maze.layout.json#L1263)
715. 旧钟齿轮
   来源：[src/data/chapter4-three-floor-maze.layout.json:1273](../src/data/chapter4-three-floor-maze.layout.json#L1273)；[src/scenes/rpg/RpgInteractionContract.ts:834](../src/scenes/rpg/RpgInteractionContract.ts#L834)
716. 旧钟分针端点
   来源：[src/data/chapter4-three-floor-maze.layout.json:1283](../src/data/chapter4-three-floor-maze.layout.json#L1283)；[src/scenes/rpg/RpgInteractionContract.ts:845](../src/scenes/rpg/RpgInteractionContract.ts#L845)；[src/scenes/rpg/RpgItemUseGuidance.ts:85](../src/scenes/rpg/RpgItemUseGuidance.ts#L85)
717. 一楼配电面板
   来源：[src/data/chapter4-three-floor-maze.layout.json:1293](../src/data/chapter4-three-floor-maze.layout.json#L1293)；[src/scenes/rpg/RpgInteractionContract.ts:869](../src/scenes/rpg/RpgInteractionContract.ts#L869)
718. 201 创客工坊
   来源：[src/data/chapter4-three-floor-maze.layout.json:1735](../src/data/chapter4-three-floor-maze.layout.json#L1735)
719. 204 研讨教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:1745](../src/data/chapter4-three-floor-maze.layout.json#L1745)
720. 202 阶梯教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:1755](../src/data/chapter4-three-floor-maze.layout.json#L1755)
721. 203 计算机教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:1765](../src/data/chapter4-three-floor-maze.layout.json#L1765)
722. 二楼开放学习区
   来源：[src/data/chapter4-three-floor-maze.layout.json:1775](../src/data/chapter4-three-floor-maze.layout.json#L1775)
723. 二楼校友纪念长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:1785](../src/data/chapter4-three-floor-maze.layout.json#L1785)
724. 二楼电梯口值班安全员
   来源：[src/data/chapter4-three-floor-maze.layout.json:1795](../src/data/chapter4-three-floor-maze.layout.json#L1795)
725. 204 教室残影组
   来源：[src/data/chapter4-three-floor-maze.layout.json:1805](../src/data/chapter4-three-floor-maze.layout.json#L1805)
726. 204 讲台抽屉里的定位盘
   来源：[src/data/chapter4-three-floor-maze.layout.json:1815](../src/data/chapter4-three-floor-maze.layout.json#L1815)
727. 202 阶梯教室门槛
   来源：[src/data/chapter4-three-floor-maze.layout.json:1825](../src/data/chapter4-three-floor-maze.layout.json#L1825)；[src/scenes/rpg/RpgInteractionContract.ts:884](../src/scenes/rpg/RpgInteractionContract.ts#L884)
728. 202 投影中的最后一分钟
   来源：[src/data/chapter4-three-floor-maze.layout.json:1835](../src/data/chapter4-three-floor-maze.layout.json#L1835)；[src/scenes/rpg/RpgInteractionContract.ts:896](../src/scenes/rpg/RpgInteractionContract.ts#L896)
729. 301 校史档案展
   来源：[src/data/chapter4-three-floor-maze.layout.json:2152](../src/data/chapter4-three-floor-maze.layout.json#L2152)
730. 302 媒体工作室
   来源：[src/data/chapter4-three-floor-maze.layout.json:2162](../src/data/chapter4-three-floor-maze.layout.json#L2162)
731. 304 报告厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2172](../src/data/chapter4-three-floor-maze.layout.json#L2172)
732. 303 智慧教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:2182](../src/data/chapter4-three-floor-maze.layout.json#L2182)
733. 三楼校史人物荣誉门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2192](../src/data/chapter4-three-floor-maze.layout.json#L2192)
734. 校史人物·苏步青
   来源：[src/data/chapter4-three-floor-maze.layout.json:2202](../src/data/chapter4-three-floor-maze.layout.json#L2202)
735. 校史人物·竺可桢
   来源：[src/data/chapter4-three-floor-maze.layout.json:2212](../src/data/chapter4-three-floor-maze.layout.json#L2212)
736. 校史人物·路甬祥
   来源：[src/data/chapter4-three-floor-maze.layout.json:2222](../src/data/chapter4-three-floor-maze.layout.json#L2222)
737. 校史人物·陈建功
   来源：[src/data/chapter4-three-floor-maze.layout.json:2232](../src/data/chapter4-three-floor-maze.layout.json#L2232)
738. 校史人物·谈家桢
   来源：[src/data/chapter4-three-floor-maze.layout.json:2237](../src/data/chapter4-three-floor-maze.layout.json#L2237)
739. 校史人物·程开甲
   来源：[src/data/chapter4-three-floor-maze.layout.json:2242](../src/data/chapter4-three-floor-maze.layout.json#L2242)
740. 三楼校友头像长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:2247](../src/data/chapter4-three-floor-maze.layout.json#L2247)
741. 三楼参照教室教师
   来源：[src/data/chapter4-three-floor-maze.layout.json:2257](../src/data/chapter4-three-floor-maze.layout.json#L2257)
742. 三楼晨间教室布置参照
   来源：[src/data/chapter4-three-floor-maze.layout.json:2267](../src/data/chapter4-three-floor-maze.layout.json#L2267)
743. 校园后勤服务
   来源：[src/data/chapter4-wechat.content.json:3](../src/data/chapter4-wechat.content.json#L3)
744. 公众号
   来源：[src/data/chapter4-wechat.content.json:4](../src/data/chapter4-wechat.content.json#L4)
745. 段永平教学楼夜间运行提醒
   来源：[src/data/chapter4-wechat.content.json:5](../src/data/chapter4-wechat.content.json#L5)
746. 夜间清楼期间，部分通道将分时关闭，主电梯停靠状态可能调整。
   来源：[src/data/chapter4-wechat.content.json:7](../src/data/chapter4-wechat.content.json#L7)
747. 教学楼自 22:45 起按楼层分区清楼。
   来源：[src/data/chapter4-wechat.content.json:9](../src/data/chapter4-wechat.content.json#L9)
748. 主电梯停靠状态以轿厢显示和现场提示音为准。
   来源：[src/data/chapter4-wechat.content.json:10](../src/data/chapter4-wechat.content.json#L10)
749. 部分通道可能临时关闭，请留意楼层公告。
   来源：[src/data/chapter4-wechat.content.json:11](../src/data/chapter4-wechat.content.json#L11)
750. 现场广播和安全指引优先于本推送。
   来源：[src/data/chapter4-wechat.content.json:12](../src/data/chapter4-wechat.content.json#L12)
751. 读完并保存通知
   来源：[src/data/chapter4-wechat.content.json:14](../src/data/chapter4-wechat.content.json#L14)
752. 校园楼宇与生活服务
   来源：[src/data/chapter4-wechat.content.json:15](../src/data/chapter4-wechat.content.json#L15)
753. 楼宇小事
   来源：[src/data/chapter4-wechat.content.json:19](../src/data/chapter4-wechat.content.json#L19)
754. 雨天的伞先放哪儿
   来源：[src/data/chapter4-wechat.content.json:20](../src/data/chapter4-wechat.content.json#L20)
755. 收伞、取伞和寻找失物的几个细节，能少留一地水，也能少拿错一把黑伞。
   来源：[src/data/chapter4-wechat.content.json:22](../src/data/chapter4-wechat.content.json#L22)
756. 雨天的楼道口总会多出几把伞。午后从图书馆回来，伞尖还滴着水，带进教室容易把地砖踩出一串湿脚印。教学区入口旁的暂存架放了吸水垫，伞可以合好后靠边摆，伞柄别挂在消防门上。
   来源：[src/data/chapter4-wechat.content.json:26](../src/data/chapter4-wechat.content.json#L26)
757. 傍晚取伞时，先看看伞带和手柄上的小标记。黑伞排在一起，三分钟足够让人怀疑自己的记忆，也很容易拿错。没有找到的同学可以在服务台登记颜色、伞柄样式和大致时间。工作人员整理时会把散落的伞移到失物架，雨停后记得领走。
   来源：[src/data/chapter4-wechat.content.json:27](../src/data/chapter4-wechat.content.json#L27)
758. 夜读提示
   来源：[src/data/chapter4-wechat.content.json:32](../src/data/chapter4-wechat.content.json#L32)
759. 晚自习收尾的半分钟
   来源：[src/data/chapter4-wechat.content.json:33](../src/data/chapter4-wechat.content.json#L33)
760. 带走桌边的充电线，把椅子推进去，夜间清洁经过时能少绕几次。
   来源：[src/data/chapter4-wechat.content.json:35](../src/data/chapter4-wechat.content.json#L35)
761. 晚间自习临近结束时，走廊里的打印机通常还在吐最后几页，充电线也最容易留在桌角。离开前花半分钟看一眼座位下方，再把椅子轻轻推进去，清洁设备经过时能少绕几次。
   来源：[src/data/chapter4-wechat.content.json:39](../src/data/chapter4-wechat.content.json#L39)
762. 入口、电梯和可通行楼层以当晚现场提示为准。准备继续学习的同学，请把水杯、电脑和个人物品带在身边。临时找不到同伴时，可以先到大厅等候，别在正在清洁的楼层里来回找插座。
   来源：[src/data/chapter4-wechat.content.json:40](../src/data/chapter4-wechat.content.json#L40)
763. 食堂顺手事
   来源：[src/data/chapter4-wechat.content.json:45](../src/data/chapter4-wechat.content.json#L45)
764. 餐盘回收台前少等一会儿
   来源：[src/data/chapter4-wechat.content.json:46](../src/data/chapter4-wechat.content.json#L46)
765. 餐盘放稳，筷子和纸巾分开，下一位同学就能早一点离开回收台。
   来源：[src/data/chapter4-wechat.content.json:48](../src/data/chapter4-wechat.content.json#L48)
766. 午餐高峰过去后，回收台上常剩几只装着汤勺的餐盘。餐具回收口前有时只差两步，大家端着餐盘聊天，队伍就会停在转角。餐盘放稳后再把筷子和纸巾分开，后面的人能少等一会儿。
   来源：[src/data/chapter4-wechat.content.json:52](../src/data/chapter4-wechat.content.json#L52)
767. 汤碗和剩菜请先倒净，整杯饮料也别塞进餐盘缝里。纸巾掉进残渣桶时不用弯腰去捞，可以交给现场工作人员处理。吃完把桌面收干净，下一位同学就能直接坐下。
   来源：[src/data/chapter4-wechat.content.json:53](../src/data/chapter4-wechat.content.json#L53)
768. 校园慢行
   来源：[src/data/chapter4-wechat.content.json:58](../src/data/chapter4-wechat.content.json#L58)
769. 把共享单车摆正以后
   来源：[src/data/chapter4-wechat.content.json:59](../src/data/chapter4-wechat.content.json#L59)
770. 把车停进线内，给盲道、坡道和拖着行李的人多留一点通过空间。
   来源：[src/data/chapter4-wechat.content.json:61](../src/data/chapter4-wechat.content.json#L61)
771. 早八前后，教学区路边经常出现同一种停车方式。车头朝里，后轮卡在树池边，旁边只够一个人侧身通过。赶时间可以理解，拎着早餐或拖着行李经过的人也确实容易被绊住。
   来源：[src/data/chapter4-wechat.content.json:65](../src/data/chapter4-wechat.content.json#L65)
772. 骑到目的地后，把车停进线内，再把挡住盲道、坡道和楼门的车辆顺手移开一点。遇到倒下的车，可以先扶正后再结束用车。多花十秒，清洁车和轮椅都能顺着走。
   来源：[src/data/chapter4-wechat.content.json:66](../src/data/chapter4-wechat.content.json#L66)
773. 湖边观察
   来源：[src/data/chapter4-wechat.content.json:71](../src/data/chapter4-wechat.content.json#L71)
774. 在启真湖边看水鸟
   来源：[src/data/chapter4-wechat.content.json:72](../src/data/chapter4-wechat.content.json#L72)
775. 镜头可以拉近，脚步和食物要离远一些。安静观察，常能看到更多。
   来源：[src/data/chapter4-wechat.content.json:74](../src/data/chapter4-wechat.content.json#L74)
776. 启真湖边最近多了几只停在浅水处的水鸟。有人隔着栏杆拍照，也有人带着面包走近。鸟一受惊就会游向水面中央，岸边的人越多，等待的时间也越长。
   来源：[src/data/chapter4-wechat.content.json:78](../src/data/chapter4-wechat.content.json#L78)
777. 看鸟时留在步道上，把镜头拉近就够了。不要投喂面包、薯片和含糖饮料，也别追着鸟群跑。可以留意羽色、脚蹼和活动方向，声音放低一些。安静站一会儿，有时能看到它们靠近岸边。
   来源：[src/data/chapter4-wechat.content.json:79](../src/data/chapter4-wechat.content.json#L79)
778. 失物招领
   来源：[src/data/chapter4-wechat.content.json:84](../src/data/chapter4-wechat.content.json#L84)
779. 失物架上那只耳机
   来源：[src/data/chapter4-wechat.content.json:85](../src/data/chapter4-wechat.content.json#L85)
780. 水杯、卡套和耳机常出现在服务台，多留几个特征就能少跑几趟。
   来源：[src/data/chapter4-wechat.content.json:87](../src/data/chapter4-wechat.content.json#L87)
781. 楼宇服务台的失物架上，最常见的是水杯、门禁卡套和单只耳机。难找的是没有写名字的充电盒，外观看起来接近，型号、贴纸和磨损位置各有不同。
   来源：[src/data/chapter4-wechat.content.json:91](../src/data/chapter4-wechat.content.json#L91)
782. 捡到物品后，交给就近服务台时尽量补一句地点和时间。失主来问时，颜色、贴纸和磨损位置都能帮上忙。要找失物的同学可以先准备这些特征，再留一个可联系的方式。
   来源：[src/data/chapter4-wechat.content.json:92](../src/data/chapter4-wechat.content.json#L92)
783. 203 还开着吗？我电脑没关。
   来源：[src/data/chapter4-wechat.content.json:101](../src/data/chapter4-wechat.content.json#L101)；[src/scenes/phone/P14_Wechat/index.tsx:30](../src/scenes/phone/P14_Wechat/index.tsx#L30)
784. 林昊
   来源：[src/data/chapter4-wechat.content.json:101](../src/data/chapter4-wechat.content.json#L101)；[src/scenes/phone/P14_Wechat/index.tsx:30](../src/scenes/phone/P14_Wechat/index.tsx#L30)
785. 陈嘉
   来源：[src/data/chapter4-wechat.content.json:102](../src/data/chapter4-wechat.content.json#L102)；[src/scenes/phone/P14_Wechat/index.tsx:31](../src/scenes/phone/P14_Wechat/index.tsx#L31)
786. 刚看见保安从东边过去。
   来源：[src/data/chapter4-wechat.content.json:102](../src/data/chapter4-wechat.content.json#L102)；[src/scenes/phone/P14_Wechat/index.tsx:31](../src/scenes/phone/P14_Wechat/index.tsx#L31)
787. 东边不是已经封了吗？
   来源：[src/data/chapter4-wechat.content.json:103](../src/data/chapter4-wechat.content.json#L103)
788. 周琪
   来源：[src/data/chapter4-wechat.content.json:103](../src/data/chapter4-wechat.content.json#L103)
789. 室友
   来源：[src/data/chapter4-wechat.content.json:104](../src/data/chapter4-wechat.content.json#L104)
790. 我在西侧看见保洁推车，应该还能走。
   来源：[src/data/chapter4-wechat.content.json:104](../src/data/chapter4-wechat.content.json#L104)
791. 陈嘉撤回了一条消息
   来源：[src/data/chapter4-wechat.content.json:106](../src/data/chapter4-wechat.content.json#L106)
792. 算了，我去楼梯口看看。
   来源：[src/data/chapter4-wechat.content.json:107](../src/data/chapter4-wechat.content.json#L107)
793. 保存路线讨论截图
   来源：[src/data/chapter4-wechat.content.json:108](../src/data/chapter4-wechat.content.json#L108)
794. 文件传输助手
   来源：[src/data/chapter4-wechat.content.json:111](../src/data/chapter4-wechat.content.json#L111)
795. 还没有第四章现场资料。
   来源：[src/data/chapter4-wechat.content.json:112](../src/data/chapter4-wechat.content.json#L112)
796. 夜间运行通知
   来源：[src/data/chapter4-wechat.content.json:113](../src/data/chapter4-wechat.content.json#L113)
797. 主电梯到站提示音 00:07
   来源：[src/data/chapter4-wechat.content.json:114](../src/data/chapter4-wechat.content.json#L114)
798. 麦斯威夜间自习群路线讨论
   来源：[src/data/chapter4-wechat.content.json:115](../src/data/chapter4-wechat.content.json#L115)
799. 三楼新旧导视板对照照片
   来源：[src/data/chapter4-wechat.content.json:116](../src/data/chapter4-wechat.content.json#L116)
800. 把现在使用的导视板和残留的旧导视板都发我。
   来源：[src/data/chapter4-wechat.content.json:119](../src/data/chapter4-wechat.content.json#L119)
801. \[图片\] 三楼新旧导视板
   来源：[src/data/chapter4-wechat.content.json:120](../src/data/chapter4-wechat.content.json#L120)
802. 两张图的二楼箭头方向相反。去现场核对仍保留旧编号的一侧，再调整导视板。
   来源：[src/data/chapter4-wechat.content.json:121](../src/data/chapter4-wechat.content.json#L121)
803. 对照两张照片
   来源：[src/data/chapter4-wechat.content.json:122](../src/data/chapter4-wechat.content.json#L122)
804. 苏步青
   来源：[src/data/ChapterFourAlumniHonorWall.ts:50](../src/data/ChapterFourAlumniHonorWall.ts#L50)
805. 数学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:52](../src/data/ChapterFourAlumniHonorWall.ts#L52)；[src/data/ChapterFourAlumniHonorWall.ts:106](../src/data/ChapterFourAlumniHonorWall.ts#L106)
806. 1931 年回国后任浙江大学数学系副教授、教授及系主任。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:54](../src/data/ChapterFourAlumniHonorWall.ts#L54)
807. 与陈建功共同形成有影响力的“陈苏学派”，培养了一批数学人才。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:55](../src/data/ChapterFourAlumniHonorWall.ts#L55)
808. 抗战时期随浙江大学西迁，在艰苦条件下继续教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:56](../src/data/ChapterFourAlumniHonorWall.ts#L56)
809. 浙江大学·求是大家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:58](../src/data/ChapterFourAlumniHonorWall.ts#L58)
810. 竺可桢
   来源：[src/data/ChapterFourAlumniHonorWall.ts:68](../src/data/ChapterFourAlumniHonorWall.ts#L68)
811. 气象学家、地理学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:70](../src/data/ChapterFourAlumniHonorWall.ts#L70)
812. 1936—1949 年任浙江大学校长，领导学校完成西迁并坚持办学。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:72](../src/data/ChapterFourAlumniHonorWall.ts#L72)
813. 任内学校由 3 个学院、16 个系发展为 7 个学院、27 个系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:73](../src/data/ChapterFourAlumniHonorWall.ts#L73)
814. 他在新生入学时提出两个问题，要求学生思考求学目的与成人方向。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:74](../src/data/ChapterFourAlumniHonorWall.ts#L74)
815. 浙江大学国际联合学院·竺老两问
   来源：[src/data/ChapterFourAlumniHonorWall.ts:76](../src/data/ChapterFourAlumniHonorWall.ts#L76)
816. 路甬祥
   来源：[src/data/ChapterFourAlumniHonorWall.ts:86](../src/data/ChapterFourAlumniHonorWall.ts#L86)
817. 流体传动与控制学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:88](../src/data/ChapterFourAlumniHonorWall.ts#L88)
818. 1964 年毕业于浙江大学机械系，后留校任教并长期从事流体传动与控制研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:90](../src/data/ChapterFourAlumniHonorWall.ts#L90)
819. 1988—1995 年任浙江大学校长，推动学校教育、科研与管理改革。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:91](../src/data/ChapterFourAlumniHonorWall.ts#L91)
820. 1991 年当选中国科学院学部委员，1994 年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:92](../src/data/ChapterFourAlumniHonorWall.ts#L92)
821. 浙江大学·历任校长
   来源：[src/data/ChapterFourAlumniHonorWall.ts:94](../src/data/ChapterFourAlumniHonorWall.ts#L94)
822. 陈建功
   来源：[src/data/ChapterFourAlumniHonorWall.ts:104](../src/data/ChapterFourAlumniHonorWall.ts#L104)
823. 1929 年起在浙江大学任教，主持数学系建设与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:108](../src/data/ChapterFourAlumniHonorWall.ts#L108)
824. 与苏步青共同培育了中国现代数学的重要学术群体。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:109](../src/data/ChapterFourAlumniHonorWall.ts#L109)
825. 西迁时期坚持教学和研究，奠定了浙大数学学科的早期基础。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:110](../src/data/ChapterFourAlumniHonorWall.ts#L110)
826. 浙江大学档案馆·俊彩星驰长廊
   来源：[src/data/ChapterFourAlumniHonorWall.ts:112](../src/data/ChapterFourAlumniHonorWall.ts#L112)
827. 谈家桢
   来源：[src/data/ChapterFourAlumniHonorWall.ts:122](../src/data/ChapterFourAlumniHonorWall.ts#L122)
828. 遗传学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:124](../src/data/ChapterFourAlumniHonorWall.ts#L124)
829. 曾任浙江大学生物系教授，在西迁途中继续组织遗传学教学与实验。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:126](../src/data/ChapterFourAlumniHonorWall.ts#L126)
830. 在缺少自来水、电灯和专业设备的条件下，带领学生用简易器材坚持研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:127](../src/data/ChapterFourAlumniHonorWall.ts#L127)
831. 后长期推动中国现代遗传学的学科建设与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:128](../src/data/ChapterFourAlumniHonorWall.ts#L128)
832. 浙江大学·求是精神薪火相传
   来源：[src/data/ChapterFourAlumniHonorWall.ts:130](../src/data/ChapterFourAlumniHonorWall.ts#L130)
833. 程开甲
   来源：[src/data/ChapterFourAlumniHonorWall.ts:140](../src/data/ChapterFourAlumniHonorWall.ts#L140)
834. 核物理学家、人民科学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:142](../src/data/ChapterFourAlumniHonorWall.ts#L142)
835. 1937 级浙江大学物理系校友，1941 年毕业。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:144](../src/data/ChapterFourAlumniHonorWall.ts#L144)
836. 是我国核武器研究的领导者之一，也是核试验事业的开拓者。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:145](../src/data/ChapterFourAlumniHonorWall.ts#L145)
837. 获两弹一星功勋奖章、国家最高科学技术奖、八一勋章与人民科学家国家荣誉称号。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:146](../src/data/ChapterFourAlumniHonorWall.ts#L146)
838. 浙江大学·程开甲先生诞辰 105 周年纪念会
   来源：[src/data/ChapterFourAlumniHonorWall.ts:148](../src/data/ChapterFourAlumniHonorWall.ts#L148)
839. 第一问：到浙大来做什么？
   来源：[src/data/ChapterFourAlumniHonorWall.ts:160](../src/data/ChapterFourAlumniHonorWall.ts#L160)
840. 追问事实与方法
   来源：[src/data/ChapterFourAlumniHonorWall.ts:162](../src/data/ChapterFourAlumniHonorWall.ts#L162)
841. 用所学解决真实问题
   来源：[src/data/ChapterFourAlumniHonorWall.ts:163](../src/data/ChapterFourAlumniHonorWall.ts#L163)
842. 为公共需要承担责任
   来源：[src/data/ChapterFourAlumniHonorWall.ts:164](../src/data/ChapterFourAlumniHonorWall.ts#L164)
843. 第二问：将来毕业后要做什么样的人？
   来源：[src/data/ChapterFourAlumniHonorWall.ts:169](../src/data/ChapterFourAlumniHonorWall.ts#L169)
844. 对工作和他人负责
   来源：[src/data/ChapterFourAlumniHonorWall.ts:171](../src/data/ChapterFourAlumniHonorWall.ts#L171)
845. 保持独立判断与证据诚实
   来源：[src/data/ChapterFourAlumniHonorWall.ts:172](../src/data/ChapterFourAlumniHonorWall.ts#L172)
846. 把能力放到社会需要上
   来源：[src/data/ChapterFourAlumniHonorWall.ts:173](../src/data/ChapterFourAlumniHonorWall.ts#L173)
847. 查看 201 创客工坊
   来源：[src/data/ChapterFourInteractionContent.ts:80](../src/data/ChapterFourInteractionContent.ts#L80)
848. 201 的工具已经归位，门边登记板停在晚间封闭状态。
   来源：[src/data/ChapterFourInteractionContent.ts:90](../src/data/ChapterFourInteractionContent.ts#L90)
849. 操作台边缘保留着较早的手部动作残影，当前房间没有新增活动轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:91](../src/data/ChapterFourInteractionContent.ts#L91)
850. 午间工坊暂停开放，切割垫上压着尚未装配的校园模型。
   来源：[src/data/ChapterFourInteractionContent.ts:94](../src/data/ChapterFourInteractionContent.ts#L94)
851. 模型零件周围有连续取放残影，时间间隔与午休人流一致。
   来源：[src/data/ChapterFourInteractionContent.ts:95](../src/data/ChapterFourInteractionContent.ts#L95)
852. 晚课前的工坊已经清台，只有一台焊台仍显示余温警示。
   来源：[src/data/ChapterFourInteractionContent.ts:98](../src/data/ChapterFourInteractionContent.ts#L98)
853. 焊台上方的动作残影在 18:50 前停止，随后没有人继续使用设备。
   来源：[src/data/ChapterFourInteractionContent.ts:99](../src/data/ChapterFourInteractionContent.ts#L99)
854. 维修时段的总电源已经断开，工具柜保持封签状态。
   来源：[src/data/ChapterFourInteractionContent.ts:102](../src/data/ChapterFourInteractionContent.ts#L102)
855. 工具柜没有被开启的残影，走廊异常并非来自这间工坊。
   来源：[src/data/ChapterFourInteractionContent.ts:103](../src/data/ChapterFourInteractionContent.ts#L103)
856. 应急照明只覆盖出口，工坊设备仍保持断电。
   来源：[src/data/ChapterFourInteractionContent.ts:106](../src/data/ChapterFourInteractionContent.ts#L106)
857. 门口出现一段短暂停留残影，没有进入操作区。
   来源：[src/data/ChapterFourInteractionContent.ts:107](../src/data/ChapterFourInteractionContent.ts#L107)
858. 晨间开放检查已完成，工具数量与登记表一致。
   来源：[src/data/ChapterFourInteractionContent.ts:110](../src/data/ChapterFourInteractionContent.ts#L110)
859. 昨夜残影已经淡去，设备状态回到正常的早班记录。
   来源：[src/data/ChapterFourInteractionContent.ts:111](../src/data/ChapterFourInteractionContent.ts#L111)
860. 查看 202 阶梯教室
   来源：[src/data/ChapterFourInteractionContent.ts:117](../src/data/ChapterFourInteractionContent.ts#L117)
861. 202 的投影幕已经收起，阶梯座位按离场状态折叠。
   来源：[src/data/ChapterFourInteractionContent.ts:127](../src/data/ChapterFourInteractionContent.ts#L127)
862. 最后一排到门口有一段连贯离场残影，讲台附近没有停留。
   来源：[src/data/ChapterFourInteractionContent.ts:128](../src/data/ChapterFourInteractionContent.ts#L128)
863. 午间讲座尚未开始，前排桌面摆着未发放的空白资料。
   来源：[src/data/ChapterFourInteractionContent.ts:131](../src/data/ChapterFourInteractionContent.ts#L131)
864. 座位间只有短暂经过的残影，没有形成完整听课轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:132](../src/data/ChapterFourInteractionContent.ts#L132)
865. 晚间教室已清空，投影机风扇刚停止，门槛处仍有散场脚印。
   来源：[src/data/ChapterFourInteractionContent.ts:135](../src/data/ChapterFourInteractionContent.ts#L135)
866. 座位残影从前排向出口逐段消失，散场时间集中在 18:50 前后。
   来源：[src/data/ChapterFourInteractionContent.ts:136](../src/data/ChapterFourInteractionContent.ts#L136)
867. 维修许可牌挂在门外，室内设备保持关机。
   来源：[src/data/ChapterFourInteractionContent.ts:139](../src/data/ChapterFourInteractionContent.ts#L139)
868. 讲台投影区保留一段独立画面残留，与普通授课记录不连续。
   来源：[src/data/ChapterFourInteractionContent.ts:140](../src/data/ChapterFourInteractionContent.ts#L140)
869. 停电后安全出口灯正常，阶梯通道没有障碍物。
   来源：[src/data/ChapterFourInteractionContent.ts:143](../src/data/ChapterFourInteractionContent.ts#L143)
870. 投影区残影仍在，亮度不随停电状态变化。
   来源：[src/data/ChapterFourInteractionContent.ts:144](../src/data/ChapterFourInteractionContent.ts#L144)
871. 202 已完成晨检，投影和座椅等待第一节课。
   来源：[src/data/ChapterFourInteractionContent.ts:147](../src/data/ChapterFourInteractionContent.ts#L147)
872. 夜间残留停止更新，教室回到正常的晨间时间轨。
   来源：[src/data/ChapterFourInteractionContent.ts:148](../src/data/ChapterFourInteractionContent.ts#L148)
873. 查看 203 计算机教室
   来源：[src/data/ChapterFourInteractionContent.ts:154](../src/data/ChapterFourInteractionContent.ts#L154)
874. 203 的终端已批量关机，教师机保留着当日维护清单。
   来源：[src/data/ChapterFourInteractionContent.ts:164](../src/data/ChapterFourInteractionContent.ts#L164)
875. 屏幕前的残影按座位顺序消失，没有人在关机后返回。
   来源：[src/data/ChapterFourInteractionContent.ts:165](../src/data/ChapterFourInteractionContent.ts#L165)
876. 午间机房处于节能待机，靠门终端正在安装课程环境。
   来源：[src/data/ChapterFourInteractionContent.ts:168](../src/data/ChapterFourInteractionContent.ts#L168)
877. 键盘上方的输入残影很短，属于自动部署前的检查动作。
   来源：[src/data/ChapterFourInteractionContent.ts:169](../src/data/ChapterFourInteractionContent.ts#L169)
878. 晚课结束后终端已退出账号，第三排有一把椅子尚未推回。
   来源：[src/data/ChapterFourInteractionContent.ts:172](../src/data/ChapterFourInteractionContent.ts#L172)
879. 第三排的离座残影比其他位置晚六秒，但随后直接离开机房。
   来源：[src/data/ChapterFourInteractionContent.ts:173](../src/data/ChapterFourInteractionContent.ts#L173)
880. 机房交换机仍在线，学生终端全部断开。
   来源：[src/data/ChapterFourInteractionContent.ts:176](../src/data/ChapterFourInteractionContent.ts#L176)
881. 网络指示残影连续，设备没有出现异常重启。
   来源：[src/data/ChapterFourInteractionContent.ts:177](../src/data/ChapterFourInteractionContent.ts#L177)
882. 后备电源只维持交换机，显示器和主机均已关闭。
   来源：[src/data/ChapterFourInteractionContent.ts:180](../src/data/ChapterFourInteractionContent.ts#L180)
883. 设备断电时间一致，没有单独延迟的终端。
   来源：[src/data/ChapterFourInteractionContent.ts:181](../src/data/ChapterFourInteractionContent.ts#L181)
884. 机房已按早课配置启动，座位状态与预约名单一致。
   来源：[src/data/ChapterFourInteractionContent.ts:184](../src/data/ChapterFourInteractionContent.ts#L184)
885. 夜间设备残影已经结束，当前只有晨检人员的短时轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:185](../src/data/ChapterFourInteractionContent.ts#L185)
886. 查看 301 校史档案展
   来源：[src/data/ChapterFourInteractionContent.ts:191](../src/data/ChapterFourInteractionContent.ts#L191)
887. 301 的档案柜按年代编号，展签强调记录需要保留原始时间。
   来源：[src/data/ChapterFourInteractionContent.ts:201](../src/data/ChapterFourInteractionContent.ts#L201)
888. 翻阅残影停在同一页：校史记录同时注明事件、地点与记录人。
   来源：[src/data/ChapterFourInteractionContent.ts:202](../src/data/ChapterFourInteractionContent.ts#L202)
889. 午间展厅开放，玻璃柜中的教学日志按日期排放。
   来源：[src/data/ChapterFourInteractionContent.ts:205](../src/data/ChapterFourInteractionContent.ts#L205)
890. 访客残影在日志柜前停留最久，随后依次查看人物档案。
   来源：[src/data/ChapterFourInteractionContent.ts:206](../src/data/ChapterFourInteractionContent.ts#L206)
891. 晚间展厅已停止接待，档案扫描台仍显示当日校验结果。
   来源：[src/data/ChapterFourInteractionContent.ts:209](../src/data/ChapterFourInteractionContent.ts#L209)
892. 扫描动作在 18:50 前完成，每页都保留来源编号。
   来源：[src/data/ChapterFourInteractionContent.ts:210](../src/data/ChapterFourInteractionContent.ts#L210)
893. 恒温柜运行正常，维修记录没有涉及档案展区。
   来源：[src/data/ChapterFourInteractionContent.ts:213](../src/data/ChapterFourInteractionContent.ts#L213)
894. 展柜周围没有异常移动残影，档案位置保持不变。
   来源：[src/data/ChapterFourInteractionContent.ts:214](../src/data/ChapterFourInteractionContent.ts#L214)
895. 停电时档案柜自动上锁，应急照明覆盖疏散通道。
   来源：[src/data/ChapterFourInteractionContent.ts:217](../src/data/ChapterFourInteractionContent.ts#L217)
896. 锁定动作同时发生，没有单独开启的柜门。
   来源：[src/data/ChapterFourInteractionContent.ts:218](../src/data/ChapterFourInteractionContent.ts#L218)
897. 晨检完成后，档案展恢复开放状态。
   来源：[src/data/ChapterFourInteractionContent.ts:221](../src/data/ChapterFourInteractionContent.ts#L221)
898. 早班记录从 07:55 开始，昨夜时间轨已经封存。
   来源：[src/data/ChapterFourInteractionContent.ts:222](../src/data/ChapterFourInteractionContent.ts#L222)
899. 查看 302 媒体工作室
   来源：[src/data/ChapterFourInteractionContent.ts:228](../src/data/ChapterFourInteractionContent.ts#L228)
900. 302 的录音设备已关闭，时间码发生器保留最后一次同步结果。
   来源：[src/data/ChapterFourInteractionContent.ts:238](../src/data/ChapterFourInteractionContent.ts#L238)
901. 剪辑台残影显示素材被逐段核对，没有一次性覆盖原始文件。
   来源：[src/data/ChapterFourInteractionContent.ts:239](../src/data/ChapterFourInteractionContent.ts#L239)
902. 午间工作室正在导出校园活动素材，监听音量保持在低档。
   来源：[src/data/ChapterFourInteractionContent.ts:242](../src/data/ChapterFourInteractionContent.ts#L242)
903. 录音棚里的说话残影与波形段落对应，停顿位置清晰。
   来源：[src/data/ChapterFourInteractionContent.ts:243](../src/data/ChapterFourInteractionContent.ts#L243)
904. 晚间录制已经结束，场记板停在 18:50 的收尾镜次。
   来源：[src/data/ChapterFourInteractionContent.ts:246](../src/data/ChapterFourInteractionContent.ts#L246)
905. 最后一段人声结束后仍有六秒环境声，随后才停止录制。
   来源：[src/data/ChapterFourInteractionContent.ts:247](../src/data/ChapterFourInteractionContent.ts#L247)
906. 工作室断开外部输入，存储阵列继续执行校验。
   来源：[src/data/ChapterFourInteractionContent.ts:250](../src/data/ChapterFourInteractionContent.ts#L250)
907. 设备残影只显示自动校验，没有新的录制动作。
   来源：[src/data/ChapterFourInteractionContent.ts:251](../src/data/ChapterFourInteractionContent.ts#L251)
908. 后备电源保留时间码和存储阵列，其他设备已经关闭。
   来源：[src/data/ChapterFourInteractionContent.ts:254](../src/data/ChapterFourInteractionContent.ts#L254)
909. 时间码在停电期间连续，没有发生跳秒。
   来源：[src/data/ChapterFourInteractionContent.ts:255](../src/data/ChapterFourInteractionContent.ts#L255)
910. 工作室完成晨间同步，所有设备采用同一时间源。
   来源：[src/data/ChapterFourInteractionContent.ts:258](../src/data/ChapterFourInteractionContent.ts#L258)
911. 当前残影只有开机检查，时间轨从 07:55 重新开始。
   来源：[src/data/ChapterFourInteractionContent.ts:259](../src/data/ChapterFourInteractionContent.ts#L259)
912. 查看 304 报告厅
   来源：[src/data/ChapterFourInteractionContent.ts:265](../src/data/ChapterFourInteractionContent.ts#L265)
913. 304 的报告题目仍留在侧屏：判断需要来源、时间和可复核记录。
   来源：[src/data/ChapterFourInteractionContent.ts:275](../src/data/ChapterFourInteractionContent.ts#L275)
914. 观众残影在提问环节集中出现，讲台记录保留了每次修改。
   来源：[src/data/ChapterFourInteractionContent.ts:276](../src/data/ChapterFourInteractionContent.ts#L276)
915. 午间报告尚未开始，讲台水杯和翻页器已经摆好。
   来源：[src/data/ChapterFourInteractionContent.ts:279](../src/data/ChapterFourInteractionContent.ts#L279)
916. 前排只有布场人员的短时残影，座位区尚未形成观众轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:280](../src/data/ChapterFourInteractionContent.ts#L280)
917. 晚间报告结束后，侧屏保留最后一页：记录结果，也记录判断过程。
   来源：[src/data/ChapterFourInteractionContent.ts:283](../src/data/ChapterFourInteractionContent.ts#L283)
918. 散场残影从后排开始，讲台人员最后离开。
   来源：[src/data/ChapterFourInteractionContent.ts:284](../src/data/ChapterFourInteractionContent.ts#L284)
919. 报告厅完成设备巡检，扩声与投影均处于关机状态。
   来源：[src/data/ChapterFourInteractionContent.ts:287](../src/data/ChapterFourInteractionContent.ts#L287)
920. 设备周围没有异常操作残影，巡检记录连续。
   来源：[src/data/ChapterFourInteractionContent.ts:288](../src/data/ChapterFourInteractionContent.ts#L288)
921. 应急广播接管报告厅，所有出口指示正常。
   来源：[src/data/ChapterFourInteractionContent.ts:291](../src/data/ChapterFourInteractionContent.ts#L291)
922. 广播启用与停电同时发生，没有额外控制动作。
   来源：[src/data/ChapterFourInteractionContent.ts:292](../src/data/ChapterFourInteractionContent.ts#L292)
923. 报告厅开始晨间准备，侧屏切换为当日安排。
   来源：[src/data/ChapterFourInteractionContent.ts:295](../src/data/ChapterFourInteractionContent.ts#L295)
924. 当前只有布场人员的残影，昨夜报告已经归档。
   来源：[src/data/ChapterFourInteractionContent.ts:296](../src/data/ChapterFourInteractionContent.ts#L296)
925. 待补全
   来源：[src/data/itemCatalog.ts:212](../src/data/itemCatalog.ts#L212)
926. 状态
   来源：[src/data/itemCatalog.ts:212](../src/data/itemCatalog.ts#L212)；[src/data/itemCatalog.ts:235](../src/data/itemCatalog.ts#L235)
927. 教学楼签到
   来源：[src/data/itemCatalog.ts:213](../src/data/itemCatalog.ts#L213)
928. 用途
   来源：[src/data/itemCatalog.ts:213](../src/data/itemCatalog.ts#L213)
929. 纸面记录停在 07:55 前后，签字栏还空着。
   来源：[src/data/itemCatalog.ts:216](../src/data/itemCatalog.ts#L216)
930. 它会暂时离开你的道具栏，但最后仍需要回到签到口。
   来源：[src/data/itemCatalog.ts:217](../src/data/itemCatalog.ts#L217)
931. 边缘有多次折返留下的旧压痕。
   来源：[src/data/itemCatalog.ts:219](../src/data/itemCatalog.ts#L219)
932. 202 阶梯教室投影
   来源：[src/data/itemCatalog.ts:234](../src/data/itemCatalog.ts#L234)
933. 来源
   来源：[src/data/itemCatalog.ts:234](../src/data/itemCatalog.ts#L234)
934. 待归位
   来源：[src/data/itemCatalog.ts:235](../src/data/itemCatalog.ts#L235)
935. 它是被偷走的最后一分钟，需要回到旧钟分针端点。
   来源：[src/data/itemCatalog.ts:238](../src/data/itemCatalog.ts#L238)
936. 归位后，手机与世界时间会重新对齐。
   来源：[src/data/itemCatalog.ts:239](../src/data/itemCatalog.ts#L239)
937. 纸面的光影像一截被掰下来的时间。
   来源：[src/data/itemCatalog.ts:241](../src/data/itemCatalog.ts#L241)
938. 左岸快到了。稳住节奏。
   来源：[src/data/pursuit.audio.content.json:73](../src/data/pursuit.audio.content.json#L73)
939. The left bank is close. Hold the rhythm.
   来源：[src/data/pursuit.audio.content.json:74](../src/data/pursuit.audio.content.json#L74)
940. Stop! Step away from the clock.
   来源：[src/data/pursuit.audio.content.json:88](../src/data/pursuit.audio.content.json#L88)
941. Do not run upstairs. Stop now.
   来源：[src/data/pursuit.audio.content.json:102](../src/data/pursuit.audio.content.json#L102)
942. I can see you. Stop!
   来源：[src/data/pursuit.audio.content.json:116](../src/data/pursuit.audio.content.json#L116)
943. 纸条抓取 {{facts.has("opening\_paper\_caught") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:144](../src/modules/ChapterFourStagePresentation.ts#L144)
944. 时间核对 {{facts.has("external\_time\_rejected") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:146](../src/modules/ChapterFourStagePresentation.ts#L146)
945. 旧钟检查 {{facts.has("hall\_clock\_inspected") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:148](../src/modules/ChapterFourStagePresentation.ts#L148)
946. 旧时针流程 {{countFacts(facts, \[ "bakery\_conveyor\_lamp\_inspected", "bakery\_hour\_hand\_exposed", "bakery\_hour\_hand\_collected", "hour\_hand\_installed" \])}}/4
   来源：[src/modules/ChapterFourStagePresentation.ts:150](../src/modules/ChapterFourStagePresentation.ts#L150)
947. 交通与参照 {{countFacts(facts, \[ "classroom\_104\_chalk\_residual\_observed", "classroom\_105\_terminal\_replay\_checked", "elevator\_history\_observed", "elevator\_history\_calibrated", "a3\_reference\_observed", "zhu\_two\_questions\_answered", "misaligned\_stair\_solved", "room204\_residual\_observed" \])}}/8 · 复原 {{normalizeRoom204Placements(state.chapter4.room204Placements).length}}/12
   来源：[src/modules/ChapterFourStagePresentation.ts:157](../src/modules/ChapterFourStagePresentation.ts#L157)
948. 维修流程 {{countMaintenanceMilestones(facts)}}/3
   来源：[src/modules/ChapterFourStagePresentation.ts:168](../src/modules/ChapterFourStagePresentation.ts#L168)
949. 必要灯区 {{progress.satisfied}}/{{progress.total}}
   来源：[src/modules/ChapterFourStagePresentation.ts:171](../src/modules/ChapterFourStagePresentation.ts#L171)
950. 抵达 202 0/1
   来源：[src/modules/ChapterFourStagePresentation.ts:174](../src/modules/ChapterFourStagePresentation.ts#L174)
951. 最后一分钟 {{facts.has("final\_minute\_recovered") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:176](../src/modules/ChapterFourStagePresentation.ts#L176)
952. 返回旧钟 0/1
   来源：[src/modules/ChapterFourStagePresentation.ts:178](../src/modules/ChapterFourStagePresentation.ts#L178)
953. 返回旧钟 1/1
   来源：[src/modules/ChapterFourStagePresentation.ts:178](../src/modules/ChapterFourStagePresentation.ts#L178)
954. 签到确认 {{countFacts(facts, \["checkin\_card\_accepted", "checkin\_paper\_accepted"\])}}/2
   来源：[src/modules/ChapterFourStagePresentation.ts:180](../src/modules/ChapterFourStagePresentation.ts#L180)
955. 收束确认 {{facts.has("exterior\_closure\_acknowledged") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:182](../src/modules/ChapterFourStagePresentation.ts#L182)
956. 章节完成 1/1
   来源：[src/modules/ChapterFourStagePresentation.ts:184](../src/modules/ChapterFourStagePresentation.ts#L184)
957. duplicate
   来源：[src/modules/ChapterFourTemporalMazeController.ts:327](../src/modules/ChapterFourTemporalMazeController.ts#L327)
958. resolved
   来源：[src/modules/ChapterFourTemporalMazeController.ts:331](../src/modules/ChapterFourTemporalMazeController.ts#L331)
959. failed
   来源：[src/modules/ChapterFourTemporalMazeController.ts:333](../src/modules/ChapterFourTemporalMazeController.ts#L333)
960. accepted
   来源：[src/modules/ChapterFourTemporalMazeController.ts:710](../src/modules/ChapterFourTemporalMazeController.ts#L710)；[src/modules/ChapterFourTemporalMazeController.ts:719](../src/modules/ChapterFourTemporalMazeController.ts#L719)；[src/scenes/phone/P08_Settings/index.tsx:105](../src/scenes/phone/P08_Settings/index.tsx#L105)；[src/scenes/phone/P08_Settings/index.tsx:124](../src/scenes/phone/P08_Settings/index.tsx#L124)；[src/scenes/phone/P19_Clock/index.tsx:148](../src/scenes/phone/P19_Clock/index.tsx#L148)；[src/scenes/phone/P19_Clock/index.tsx:155](../src/scenes/phone/P19_Clock/index.tsx#L155)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6806](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6806)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6948](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6948)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6960)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6969](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6969)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6977](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6977)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7078](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7078)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7086](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7086)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7094](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7094)
961. invalid\_request
   来源：[src/modules/ChapterFourTemporalMazeController.ts:1838](../src/modules/ChapterFourTemporalMazeController.ts#L1838)；[src/modules/ChapterFourTemporalMazeController.ts:1845](../src/modules/ChapterFourTemporalMazeController.ts#L1845)；[src/modules/ChapterFourTemporalMazeController.ts:1848](../src/modules/ChapterFourTemporalMazeController.ts#L1848)
962. invalid\_intent
   来源：[src/modules/ChapterFourTemporalMazeController.ts:1851](../src/modules/ChapterFourTemporalMazeController.ts#L1851)；[src/modules/ChapterFourTemporalMazeController.ts:1855](../src/modules/ChapterFourTemporalMazeController.ts#L1855)
963. 查看校园后勤服务的夜间运行通知
   来源：[src/modules/ChapterFourWechatModel.ts:80](../src/modules/ChapterFourWechatModel.ts#L80)
964. 打开微信中的“校园后勤服务”公众号，保存段永平教学楼夜间运行提醒。
   来源：[src/modules/ChapterFourWechatModel.ts:81](../src/modules/ChapterFourWechatModel.ts#L81)
965. 归档主电梯历史提示音
   来源：[src/modules/ChapterFourWechatModel.ts:87](../src/modules/ChapterFourWechatModel.ts#L87)
966. 打开微信的文件传输助手，保存刚刚在深色观察中记录的电梯提示音。
   来源：[src/modules/ChapterFourWechatModel.ts:88](../src/modules/ChapterFourWechatModel.ts#L88)
967. 从 CC98 导入学习天地资料索引
   来源：[src/modules/ChapterFourWechatModel.ts:97](../src/modules/ChapterFourWechatModel.ts#L97)
968. 打开 CC98 的学习天地资料索引帖，选出课程年份、旧讨论和现场核验三项，再导入自习群。
   来源：[src/modules/ChapterFourWechatModel.ts:98](../src/modules/ChapterFourWechatModel.ts#L98)
969. 保存麦斯威夜间自习群的路线讨论
   来源：[src/modules/ChapterFourWechatModel.ts:103](../src/modules/ChapterFourWechatModel.ts#L103)
970. 打开微信学生群，保存包含东西两侧矛盾描述的群聊截图。
   来源：[src/modules/ChapterFourWechatModel.ts:104](../src/modules/ChapterFourWechatModel.ts#L104)
971. 归档三楼新旧导视板照片
   来源：[src/modules/ChapterFourWechatModel.ts:112](../src/modules/ChapterFourWechatModel.ts#L112)
972. 打开文件传输助手，将当前导视板和深色残影保存在同一组记录中。
   来源：[src/modules/ChapterFourWechatModel.ts:113](../src/modules/ChapterFourWechatModel.ts#L113)
973. 请朋友对照新旧导视板
   来源：[src/modules/ChapterFourWechatModel.ts:119](../src/modules/ChapterFourWechatModel.ts#L119)
974. 在微信朋友聊天中对照两张照片，记下二楼箭头的方向差异。
   来源：[src/modules/ChapterFourWechatModel.ts:120](../src/modules/ChapterFourWechatModel.ts#L120)
975. already\_complete
   来源：[src/scenes/phone/P08_Settings/index.tsx:105](../src/scenes/phone/P08_Settings/index.tsx#L105)；[src/scenes/phone/P08_Settings/index.tsx:124](../src/scenes/phone/P08_Settings/index.tsx#L124)
976. 旧桌面排布已核对，辅助记录已保存。
   来源：[src/scenes/phone/P08_Settings/index.tsx:106](../src/scenes/phone/P08_Settings/index.tsx#L106)
977. incorrect
   来源：[src/scenes/phone/P08_Settings/index.tsx:107](../src/scenes/phone/P08_Settings/index.tsx#L107)；[src/scenes/phone/P08_Settings/index.tsx:126](../src/scenes/phone/P08_Settings/index.tsx#L126)
978. 第一排仍不对。旧截图从左到右是微信、浙大钉、照片、CC98。
   来源：[src/scenes/phone/P08_Settings/index.tsx:108](../src/scenes/phone/P08_Settings/index.tsx#L108)
979. 进入第四章后才能核对这张旧桌面截图。
   来源：[src/scenes/phone/P08_Settings/index.tsx:109](../src/scenes/phone/P08_Settings/index.tsx#L109)
980. 三条 07:55 异常记录已归档。照片索引、时钟唤醒和 A2 定位共用同一时刻。
   来源：[src/scenes/phone/P08_Settings/index.tsx:125](../src/scenes/phone/P08_Settings/index.tsx#L125)
981. 记录还混着正常刷新。只保留同时发生在 07:55 的三条异常活动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:127](../src/scenes/phone/P08_Settings/index.tsx#L127)
982. 第四章尚未开始，这里只有普通后台记录。
   来源：[src/scenes/phone/P08_Settings/index.tsx:128](../src/scenes/phone/P08_Settings/index.tsx#L128)
983. 打开控制中心切换网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
984. 当前网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
985. 等待校园网
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
986. 可访问
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
987. 离线
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
988. 校园网络与移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
989. 移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
990. 背景音乐
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
991. 开启
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
992. 声音与振动
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
993. 语音与操作音效保持开启
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
994. 微信
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:439](../src/scenes/phone/P13_PhoneHome/index.tsx#L439)；[src/scenes/phone/P13_PhoneHome/index.tsx:442](../src/scenes/phone/P13_PhoneHome/index.tsx#L442)；[src/scenes/phone/P13_PhoneHome/index.tsx:798](../src/scenes/phone/P13_PhoneHome/index.tsx#L798)
995. 微信，待处理：{{chapterFourWechatObjective.label}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:442](../src/scenes/phone/P13_PhoneHome/index.tsx#L442)
996. 浙大体艺
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:447](../src/scenes/phone/P13_PhoneHome/index.tsx#L447)
997. 浙大钉
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:453](../src/scenes/phone/P13_PhoneHome/index.tsx#L453)
998. CC98
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:497](../src/scenes/phone/P13_PhoneHome/index.tsx#L497)；[src/scenes/phone/P13_PhoneHome/index.tsx:500](../src/scenes/phone/P13_PhoneHome/index.tsx#L500)
999. CC98，待处理：{{chapterFourWechatObjective?.label ?? "学习天地资料索引"}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:500](../src/scenes/phone/P13_PhoneHome/index.tsx#L500)
1000. 控制中心
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:505](../src/scenes/phone/P13_PhoneHome/index.tsx#L505)
1001. 时钟
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:514](../src/scenes/phone/P13_PhoneHome/index.tsx#L514)
1002. 新增照片「看不清的书脊」
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:778](../src/scenes/phone/P13_PhoneHome/index.tsx#L778)
1003. 照片
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:778](../src/scenes/phone/P13_PhoneHome/index.tsx#L778)；[src/scenes/phone/P13_PhoneHome/index.tsx:804](../src/scenes/phone/P13_PhoneHome/index.tsx#L804)
1004. 打开 CC98 学习天地资料索引帖
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:789](../src/scenes/phone/P13_PhoneHome/index.tsx#L789)
1005. 课程年份入口与旧自习讨论待导入
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:792](../src/scenes/phone/P13_PhoneHome/index.tsx#L792)
1006. CC98 · 学习天地
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:792](../src/scenes/phone/P13_PhoneHome/index.tsx#L792)
1007. IMG\_0755 的识别结果仍需现场核验
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:804](../src/scenes/phone/P13_PhoneHome/index.tsx#L804)
1008. 这份资料已经保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:447](../src/scenes/phone/P14_Wechat/index.tsx#L447)
1009. 夜间运行通知已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:456](../src/scenes/phone/P14_Wechat/index.tsx#L456)
1010. 第四章开始后才能查看这条运行通知。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:457](../src/scenes/phone/P14_Wechat/index.tsx#L457)
1011. 主电梯提示音已归档。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:464](../src/scenes/phone/P14_Wechat/index.tsx#L464)
1012. 文件传输助手尚未收到一楼电梯历史提示音记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:465](../src/scenes/phone/P14_Wechat/index.tsx#L465)
1013. 路线讨论已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:472](../src/scenes/phone/P14_Wechat/index.tsx#L472)
1014. 先去 CC98 学习天地，把课程年份入口、旧讨论和现场核验三项导入群文件。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:474](../src/scenes/phone/P14_Wechat/index.tsx#L474)
1015. 先阅读公众号通知，并抵达二楼清楼阶段。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:475](../src/scenes/phone/P14_Wechat/index.tsx#L475)
1016. 新旧导视板照片已归档。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:482](../src/scenes/phone/P14_Wechat/index.tsx#L482)
1017. 文件传输助手尚未收到三楼旧导视板残影记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:483](../src/scenes/phone/P14_Wechat/index.tsx#L483)
1018. 照片对照完成。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:490](../src/scenes/phone/P14_Wechat/index.tsx#L490)
1019. 先把三楼新旧导视板照片保存到文件传输助手。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:491](../src/scenes/phone/P14_Wechat/index.tsx#L491)
1020. 朋友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:638](../src/scenes/phone/P14_Wechat/index.tsx#L638)
1021. 返回公众号主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1022. 返回聊天列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1023. official
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1024. 麦斯威夜间自习群聊天记录
   来源：[src/scenes/phone/P14_Wechat/index.tsx:657](../src/scenes/phone/P14_Wechat/index.tsx#L657)
1025. 22:47 ·
   来源：[src/scenes/phone/P14_Wechat/index.tsx:658](../src/scenes/phone/P14_Wechat/index.tsx#L658)
1026. 人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:658](../src/scenes/phone/P14_Wechat/index.tsx#L658)
1027. 路线讨论已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:685](../src/scenes/phone/P14_Wechat/index.tsx#L685)
1028. 第四章现场资料
   来源：[src/scenes/phone/P14_Wechat/index.tsx:690](../src/scenes/phone/P14_Wechat/index.tsx#L690)
1029. 公众号推送 · 22:40
   来源：[src/scenes/phone/P14_Wechat/index.tsx:693](../src/scenes/phone/P14_Wechat/index.tsx#L693)
1030. 已读
   来源：[src/scenes/phone/P14_Wechat/index.tsx:693](../src/scenes/phone/P14_Wechat/index.tsx#L693)
1031. 群文件 · 学习天地
   来源：[src/scenes/phone/P14_Wechat/index.tsx:697](../src/scenes/phone/P14_Wechat/index.tsx#L697)
1032. 课程年份入口与旧自习讨论
   来源：[src/scenes/phone/P14_Wechat/index.tsx:698](../src/scenes/phone/P14_Wechat/index.tsx#L698)
1033. 已从 CC98 导入
   来源：[src/scenes/phone/P14_Wechat/index.tsx:699](../src/scenes/phone/P14_Wechat/index.tsx#L699)
1034. 现场录音 · 1F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:704](../src/scenes/phone/P14_Wechat/index.tsx#L704)
1035. 保存照片
   来源：[src/scenes/phone/P14_Wechat/index.tsx:714](../src/scenes/phone/P14_Wechat/index.tsx#L714)
1036. 已归档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:714](../src/scenes/phone/P14_Wechat/index.tsx#L714)
1037. 朋友导视板对照聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:720](../src/scenes/phone/P14_Wechat/index.tsx#L720)
1038. 新旧导视板照片
   来源：[src/scenes/phone/P14_Wechat/index.tsx:725](../src/scenes/phone/P14_Wechat/index.tsx#L725)
1039. 2F →
   来源：[src/scenes/phone/P14_Wechat/index.tsx:726](../src/scenes/phone/P14_Wechat/index.tsx#L726)
1040. 当前导视
   来源：[src/scenes/phone/P14_Wechat/index.tsx:726](../src/scenes/phone/P14_Wechat/index.tsx#L726)
1041. ← 2F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:727](../src/scenes/phone/P14_Wechat/index.tsx#L727)
1042. 历史残影
   来源：[src/scenes/phone/P14_Wechat/index.tsx:727](../src/scenes/phone/P14_Wechat/index.tsx#L727)
1043. 照片已完成对照
   来源：[src/scenes/phone/P14_Wechat/index.tsx:730](../src/scenes/phone/P14_Wechat/index.tsx#L730)
1044. {{label}} −
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:377](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L377)
1045. {{label}} +
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:387](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L387)
1046. {{strings.assemble}} / {{strings.explode}}
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:511](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L511)
1047. 系统
   来源：[src/scenes/phone/P19_Clock/index.tsx:29](../src/scenes/phone/P19_Clock/index.tsx#L29)
1048. 玩家
   来源：[src/scenes/phone/P19_Clock/index.tsx:31](../src/scenes/phone/P19_Clock/index.tsx#L31)
1049. 我
   来源：[src/scenes/phone/P19_Clock/index.tsx:31](../src/scenes/phone/P19_Clock/index.tsx#L31)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:70](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L70)
1050. {{currentRound.label}}协议通过，进入下一轮。
   来源：[src/scenes/phone/P19_Clock/index.tsx:103](../src/scenes/phone/P19_Clock/index.tsx#L103)
1051. 这条记录属于其他场景，无法写入 B2-04 档案。
   来源：[src/scenes/phone/P19_Clock/index.tsx:133](../src/scenes/phone/P19_Clock/index.tsx#L133)
1052. {{unit === "hour" ? "小时" : "分钟"}}机芯已锁定。
   来源：[src/scenes/phone/P19_Clock/index.tsx:148](../src/scenes/phone/P19_Clock/index.tsx#L148)
1053. {{channel.label}}漂移已归零。
   来源：[src/scenes/phone/P19_Clock/index.tsx:155](../src/scenes/phone/P19_Clock/index.tsx#L155)
1054. 返回手机主页
   来源：[src/scenes/phone/P19_Clock/index.tsx:166](../src/scenes/phone/P19_Clock/index.tsx#L166)；[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)；[src/scenes/rpg/RpgGameHost.tsx:1994](../src/scenes/rpg/RpgGameHost.tsx#L1994)
1055. B2-04 / TIME REPAIR
   来源：[src/scenes/phone/P19_Clock/index.tsx:167](../src/scenes/phone/P19_Clock/index.tsx#L167)
1056. 校时状态
   来源：[src/scenes/phone/P19_Clock/index.tsx:171](../src/scenes/phone/P19_Clock/index.tsx#L171)
1057. 四关校时流程
   来源：[src/scenes/phone/P19_Clock/index.tsx:175](../src/scenes/phone/P19_Clock/index.tsx#L175)
1058. 返回当前任务
   来源：[src/scenes/phone/P19_Clock/index.tsx:179](../src/scenes/phone/P19_Clock/index.tsx#L179)
1059. ACCESS DENIED
   来源：[src/scenes/phone/P19_Clock/index.tsx:179](../src/scenes/phone/P19_Clock/index.tsx#L179)
1060. /3 证据
   来源：[src/scenes/phone/P19_Clock/index.tsx:182](../src/scenes/phone/P19_Clock/index.tsx#L182)
1061. 01 / ARCHIVE REBUILD
   来源：[src/scenes/phone/P19_Clock/index.tsx:182](../src/scenes/phone/P19_Clock/index.tsx#L182)
1062. 提交档案与时刻
   来源：[src/scenes/phone/P19_Clock/index.tsx:189](../src/scenes/phone/P19_Clock/index.tsx#L189)
1063. /2 LOCKED
   来源：[src/scenes/phone/P19_Clock/index.tsx:193](../src/scenes/phone/P19_Clock/index.tsx#L193)
1064. 02 / DUAL MOVEMENT
   来源：[src/scenes/phone/P19_Clock/index.tsx:193](../src/scenes/phone/P19_Clock/index.tsx#L193)
1065. 00 分机芯
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1066. 08 时机芯
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1067. 23 秒暂存
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1068. 进入漂移核对
   来源：[src/scenes/phone/P19_Clock/index.tsx:205](../src/scenes/phone/P19_Clock/index.tsx#L205)
1069. /3 ONLINE
   来源：[src/scenes/phone/P19_Clock/index.tsx:209](../src/scenes/phone/P19_Clock/index.tsx#L209)
1070. 03 / DRIFT MATRIX
   来源：[src/scenes/phone/P19_Clock/index.tsx:209](../src/scenes/phone/P19_Clock/index.tsx#L209)
1071. 已归零
   来源：[src/scenes/phone/P19_Clock/index.tsx:213](../src/scenes/phone/P19_Clock/index.tsx#L213)
1072. 应用反向修正
   来源：[src/scenes/phone/P19_Clock/index.tsx:213](../src/scenes/phone/P19_Clock/index.tsx#L213)
1073. 生成 08:00:00
   来源：[src/scenes/phone/P19_Clock/index.tsx:215](../src/scenes/phone/P19_Clock/index.tsx#L215)
1074. 04 / THREE PROTOCOLS
   来源：[src/scenes/phone/P19_Clock/index.tsx:219](../src/scenes/phone/P19_Clock/index.tsx#L219)
1075. 执行本轮放行
   来源：[src/scenes/phone/P19_Clock/index.tsx:224](../src/scenes/phone/P19_Clock/index.tsx#L224)
1076. 放行尝试
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1077. 漂移尝试
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1078. 四关校时
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1079. TIME AXIS / RELEASED
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1080. P01 起床
   来源：[src/scenes/phone/registry.tsx:27](../src/scenes/phone/registry.tsx#L27)
1081. 再睡5分钟 → 旁白 → 起床蠢货！！！ → 手机主界面。
   来源：[src/scenes/phone/registry.tsx:28](../src/scenes/phone/registry.tsx#L28)
1082. P13 手机主界面
   来源：[src/scenes/phone/registry.tsx:31](../src/scenes/phone/registry.tsx#L31)
1083. 主屏：设置齿轮/塔楼钥匙孔/天气水滴/盆栽入口/微信弹窗。
   来源：[src/scenes/phone/registry.tsx:32](../src/scenes/phone/registry.tsx#L32)
1084. P08 设置
   来源：[src/scenes/phone/registry.tsx:35](../src/scenes/phone/registry.tsx#L35)
1085. 真实系统设置、桌面编排、可选应用恢复与第四章后台活动取证。
   来源：[src/scenes/phone/registry.tsx:36](../src/scenes/phone/registry.tsx#L36)
1086. P14 微信
   来源：[src/scenes/phone/registry.tsx:39](../src/scenes/phone/registry.tsx#L39)
1087. 朋友聊天触发小影散码；列表中朋友头像藏斜线谜题（P03）。
   来源：[src/scenes/phone/registry.tsx:40](../src/scenes/phone/registry.tsx#L40)
1088. P02 CC98
   来源：[src/scenes/phone/registry.tsx:43](../src/scenes/phone/registry.tsx#L43)
1089. 仅校园网可进入；热门话题列表与剧情帖子记录跟随游戏进度。
   来源：[src/scenes/phone/registry.tsx:44](../src/scenes/phone/registry.tsx#L44)
1090. P15 浙大钉
   来源：[src/scenes/phone/registry.tsx:47](../src/scenes/phone/registry.tsx#L47)
1091. 仅校园网可进入；承载系统入口、图书馆预约和移动图书馆证据流程。
   来源：[src/scenes/phone/registry.tsx:48](../src/scenes/phone/registry.tsx#L48)
1092. P06 浙大体艺
   来源：[src/scenes/phone/registry.tsx:51](../src/scenes/phone/registry.tsx#L51)
1093. 仅流量可进入；先开启课外锻炼，图书馆阶段再核对 7 / 47 / 3 到馆材料。
   来源：[src/scenes/phone/registry.tsx:52](../src/scenes/phone/registry.tsx#L52)
1094. 准备离开教学楼的学生像素立绘
   来源：[src/scenes/rpg/chapter4-prologue/ProloguePortraitAssets.ts:13](../src/scenes/rpg/chapter4-prologue/ProloguePortraitAssets.ts#L13)
1095. 迈斯威 →
   来源：[src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts:1365](../src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts#L1365)
1096. 旁白
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:78](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L78)
1097. 保洁员
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:86](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L86)
1098. 第四章序幕：纸条进入段永平教学楼
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:641](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L641)
1099. 夜色中，湿纸条离开启真湖，经过街机厅进入段永平教学楼，沿大厅进入熄灯后的走廊
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:664](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L664)
1100. 由四项手机证据恢复的现场回放
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:667](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L667)
1101. RECOVERED TIMELINE
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:668](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L668)
1102. SOURCE 4 / 4
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:669](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L669)
1103. 跳过恢复回放
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:674](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L674)
1104. CHAPTER 03.5 · COMPLETE
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:701](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L701)
1105. 第四章：时间迷宫
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:702](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L702)
1106. 现场定位
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:705](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L705)
1107. 段永平教学楼玻璃门
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:706](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L706)
1108. 追踪进入教学楼的异常签到纸
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:710](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L710)
1109. 正在提交任务……
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:724](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L724)
1110. 正在同步教学楼现场……
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:726](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L726)
1111. 重试进入第四章
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:728](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L728)
1112. 收下任务，进入第四章
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:729](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L729)
1113. 重播过场
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:736](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L736)
1114. 楼梯的空间关系发生错位。
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:87](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L87)
1115. B2 已接通
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:220](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L220)
1116. 空格键 记录下层回声
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:222](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L222)
1117. 下层回声已记录
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:222](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L222)
1118. 端点已对齐 · 空格键通过
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:224](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L224)
1119. A / ← 左转 · D / → 右转 · 让两端发光后通过
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:225](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L225)
1120. 错位折返楼梯
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:269](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L269)
1121. A1 入口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:150](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L150)
1122. 电梯与楼层
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:151](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L151)
1123. 维修与追逐
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:152](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L152)
1124. 收束场景
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:153](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L153)
1125. A1 · 麦思威面包坊与门厅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:684](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L684)
1126. A2 · 教室与开放学习区
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:685](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L685)
1127. A3 · 校友荣誉门厅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:686](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L686)
1128. 楼梯上行口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L960)
1129. 楼梯下行口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L960)
1130. up
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L960)
1131. unknown
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1428](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1428)
1132. 资料依据：{{figure.sourceLabel}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1814](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1814)
1133. 返回地图
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1836](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1836)
1134. 进入竺老两问
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1836](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1836)
1135. Space / Enter · 确认 Esc · 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1843](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1843)
1136. 正在保存两项回答……
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1867](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1867)
1137. 方向键选择 · Esc 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1898](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1898)
1138. 确认选择
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1904](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1904)
1139. {{CHAPTER\_FOUR\_WARMUP\_PHASE\_LABELS\[failedPhase\]}}资源准备失败（{{failedCount}} 项）· R 重试
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2065](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2065)
1140. 进度已恢复，请重试当前操作。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:3122](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L3122)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5086](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5086)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6390](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6390)
1141. 校园卡
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4417](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4417)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4435](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4435)；[src/scenes/rpg/RpgGameHost.tsx:2065](../src/scenes/rpg/RpgGameHost.tsx#L2065)
1142. 纸条
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4423](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4423)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4438](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4438)
1143. 已刷卡
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4435](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4435)
1144. 已签到
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4438](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4438)
1145. chase.close
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4767](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4767)
1146. 保安
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:94](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L94)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4769](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4769)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4791](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4791)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4978](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4978)
1147. chase.floor\_changed
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4789](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4789)
1148. 202 门已关闭
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4858](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4858)
1149. maintenance.cleaner
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4969](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4969)
1150. chase.started
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4976](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4976)
1151. morning.entry
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4984](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4984)
1152. exterior.closure
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4991](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4991)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7102](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7102)
1153. 07:55 残影投影
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5046](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5046)
1154. 校准中……
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5052](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5052)
1155. 偏移·3px
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5065](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5065)
1156. Space · 把已搬起的桌椅放到残影槽位
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5349](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5349)
1157. Space · 搬动一组桌椅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5356](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5356)
1158. 当前为深色观察；搬动桌椅需要浅色操作
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5357](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5357)
1159. 先搬一组桌椅，再放到残影槽位。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5366](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5366)
1160. 搬动桌椅需要浅色操作；当前仍可查看残影槽位。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5367](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5367)
1161. 把对应道具拖到{{this.nearbyStoryTarget.contract.label}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5376](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5376)
1162. 切到浅色操作后再搬动桌椅。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5445](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5445)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5476](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5476)
1163. 先搬一组桌椅，再放到对应残影位置。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5484](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5484)
1164. 请从道具栏拖动道具到{{storyTarget.contract.label}}。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5738](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5738)
1165. final\_chase
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5753](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5753)
1166. 追逐中电梯已锁，请进入主楼梯。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5754](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5754)
1167. 返程只能沿主楼梯回到一楼旧钟。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5755](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5755)
1168. 当前可继续观察；轿厢重放校准需要浅色操作。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5767](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5767)
1169. 电梯的历史片段只保留上行记录。请从三楼主楼梯返回二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5774](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5774)
1170. 先到校史人物荣誉墙阅读竺可桢生平并回答竺老两问。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5786](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5786)
1171. 选择楼层
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5838](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5838)
1172. 方向键选择 · Enter 确认 · Esc 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5861](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5861)
1173. 同步电梯历史
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5876](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5876)
1174. 让一楼开门记录完整覆盖人物的六秒进入窗口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5879](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5879)
1175. 重放校准
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5893](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5893)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5903](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5903)
1176. −1 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5902](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5902)
1177. +1 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5904](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5904)
1178. ←/→ 调整 · Enter 重放 · Esc 离开
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5905](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5905)
1179. 蓝色 门体开放 {{formatClock(doorStart)}}—{{formatClock(doorEnd)}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5953](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5953)
1180. 黄色 人物进入 {{formatClock(playerStart)}}—{{formatClock(playerEnd)}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5954](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5954)
1181. 白线 轿厢开始上行
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5955](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5955)
1182. 重放失败：门体没有覆盖完整进入窗口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5955](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5955)
1183. 二楼按钮没有对应的历史到站记录。先乘到三楼，再从错位楼梯返回二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6018](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6018)
1184. 当前已在 {{targetFloor}}F
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6022](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6022)
1185. 拨钟操作已取消，旧钟和纸条均已恢复，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6152](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6152)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6185](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6185)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6200](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6200)
1186. 最终拨钟条件尚未满足，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6245](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6245)
1187. 时间校准至 07:54。纸条带走了最后一分钟。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6290](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6290)
1188. 传送带停机确认超时，已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6582](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6582)
1189. 07:55 残影投影确认超时，已回到已完成的教室布局，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6588](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6588)
1190. 最终拨钟确认超时，已恢复转动的旧钟和签到纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6595](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6595)
1191. 回答保存超时，请再次确认第二问。两项选择仍保留，系统不会判定对错。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6602](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6602)
1192. 当前楼层状态已经同步。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6654](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6654)
1193. 请切回浅色操作后再移动。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6655](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6655)
1194. 当前剧情阶段没有开放这条楼层通道。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6656](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6656)
1195. 当前无法前往该楼层。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6657](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6657)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6662](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6662)
1196. 当前剧情条件尚未满足。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6681](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6681)；[src/scenes/rpg/RpgGameHost.tsx:349](../src/scenes/rpg/RpgGameHost.tsx#L349)
1197. 门体开放区间未完整覆盖六秒进入窗口。调整重放起点后再试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6685](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6685)
1198. {{detail}} 请再次确认第二问；两项选择仍保留。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6692](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6692)
1199. {{detail}}已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6706](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6706)
1200. {{detail}}已回到已完成的教室布局，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6712](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6712)
1201. {{detail}}已恢复转动的旧钟和签到纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6719](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6719)
1202. oldClockHourHand
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6728](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6728)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6805](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6805)
1203. finalMinute
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6732](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6732)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7077](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7077)
1204. campusCard
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6736](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6736)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7085](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7085)；[src/scenes/rpg/RpgGameHost.tsx:2064](../src/scenes/rpg/RpgGameHost.tsx#L2064)
1205. attendanceRecordPaper
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6740](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6740)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7093](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7093)
1206. shortPryBar
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6744](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6744)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6960)
1207. universalLubricatingOil
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6749](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6749)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6968](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6968)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6976](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6976)
1208. 传送带停机结果缺少已提交记录，已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6790](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6790)
1209. 金属时针已装回旧钟，时间已切换到 18:50。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6807](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6807)
1210. 当前教室没有新增状态记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6853](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6853)
1211. 竺老两问已记录。你的回答将在后续灯光收束中被读取。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6868](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6868)
1212. classroom104.chalk\_residual
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6876](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6876)
1213. classroom105.terminal\_replay
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6884](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6884)
1214. 已记录门体开放、人物进入和轿厢上行三条时间轨。轿厢重放校准可独立在浅色操作中完成。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6892](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6892)
1215. room204.a3\_reference\_recorded
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6906](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6906)
1216. room204.residual\_recorded
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6914](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6914)
1217. 已复原 {{normalizeRoom204Placements( this.bridge.getState().chapter4.room204Placements ).length}}/{{ROOM204\_SLOT\_ORDER.length}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6923](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6923)
1218. 07:55 投影结果缺少已提交记录，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6933](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6933)
1219. clockPositioningPlate
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6947](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6947)
1220. 定位盘已装回旧钟，现在线索转入 22:45 维护时段。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6949](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6949)
1221. 轮罩已打开，短撬棍完成了最后一次用途。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6960)
1222. 保洁车轮已修好，瓶里还剩一半润滑油。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6970](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6970)
1223. 旧钟齿轮已恢复转动。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6978](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6978)
1224. 已回到大厅安全点。维修进度和道具均已保留。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6991](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6991)
1225. 偷走最后一分钟的提交不完整，已恢复旧钟和纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7009](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7009)
1226. chase.retry
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7054](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7054)
1227. lecture.recovered\_result
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7064](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7064)
1228. 最后一分钟已装回旧钟。时间已恢复到 07:55。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7079](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7079)
1229. 校园卡已通过签到校验。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7087](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7087)
1230. 签到记录已提交。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7095](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7095)
1231. 外部现场
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7318](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7318)
1232. 手机状态栏 · 冻结
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7328](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7328)
1233. 不可信
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7334](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7334)
1234. 外部时间与手机冻结时间冲突 · 签到提交已拒绝
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7337](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7337)
1235. 旧钟停在 22:45。表盘能被拨动，但响应方向和幅度都不对。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7363](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7363)
1236. 旧钟停在 12:25。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7445](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7445)
1237. 无法使用该道具。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7608](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7608)
1238. invalid\_item
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7609](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7609)
1239. 未命中有效目标。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7616](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7616)
1240. missed\_target
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7616](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7616)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7629](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7629)
1241. 未命中当前阶段的可见道具目标。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7629](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7629)
1242. {{target.contract.label}}需要另一件道具。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7634](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7634)
1243. wrong\_item
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7634](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7634)
1244. 交互失败，请重新靠近目标后重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7751](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7751)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7755](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7755)；[src/scenes/rpg/RpgGameHost.tsx:831](../src/scenes/rpg/RpgGameHost.tsx#L831)
1245. locked
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7751](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7751)
1246. 当前目标需要另一件道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:345](../src/scenes/rpg/RpgGameHost.tsx#L345)
1247. 距离目标太远，请靠近可见交互区域。
   来源：[src/scenes/rpg/RpgGameHost.tsx:346](../src/scenes/rpg/RpgGameHost.tsx#L346)
1248. 当前组合与已记录的线索不一致。
   来源：[src/scenes/rpg/RpgGameHost.tsx:347](../src/scenes/rpg/RpgGameHost.tsx#L347)
1249. 到三楼校史人物荣誉墙阅读竺可桢生平并回答竺老两问后，可进入空间校准。
   来源：[src/scenes/rpg/RpgGameHost.tsx:518](../src/scenes/rpg/RpgGameHost.tsx#L518)
1250. 正在写入二楼到达记录…
   来源：[src/scenes/rpg/RpgGameHost.tsx:556](../src/scenes/rpg/RpgGameHost.tsx#L556)
1251. 楼梯校准结果未能写入，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:574](../src/scenes/rpg/RpgGameHost.tsx#L574)
1252. 两层错位楼梯已连通。已从三楼抵达二楼，204 教室恢复流程开放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:580](../src/scenes/rpg/RpgGameHost.tsx#L580)
1253. 教学楼交互请求缺少有效编号或包含多余字段。请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:856](../src/scenes/rpg/RpgGameHost.tsx#L856)
1254. 当前教学楼交互请求无效。
   来源：[src/scenes/rpg/RpgGameHost.tsx:857](../src/scenes/rpg/RpgGameHost.tsx#L857)
1255. 这次教学楼交互已经处理，未重复写入。
   来源：[src/scenes/rpg/RpgGameHost.tsx:863](../src/scenes/rpg/RpgGameHost.tsx#L863)；[src/scenes/rpg/RpgGameHost.tsx:949](../src/scenes/rpg/RpgGameHost.tsx#L949)
1256. 第四章序幕交接仅由 App gate 提交。
   来源：[src/scenes/rpg/RpgGameHost.tsx:870](../src/scenes/rpg/RpgGameHost.tsx#L870)
1257. 当前交互位置无法由活动场景重新确认，请靠近可见目标后重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:897](../src/scenes/rpg/RpgGameHost.tsx#L897)
1258. 无目标交互不得携带运行时几何。
   来源：[src/scenes/rpg/RpgGameHost.tsx:940](../src/scenes/rpg/RpgGameHost.tsx#L940)
1259. 教学楼交互处理失败，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:953](../src/scenes/rpg/RpgGameHost.tsx#L953)
1260. 配电请求未被接受，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1017](../src/scenes/rpg/RpgGameHost.tsx#L1017)
1261. 区域供电状态已同步。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1026](../src/scenes/rpg/RpgGameHost.tsx#L1026)
1262. 三项判断中仍有矛盾，请重新核对现场现象。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1070](../src/scenes/rpg/RpgGameHost.tsx#L1070)
1263. 7:55 RPG runtime
   来源：[src/scenes/rpg/RpgGameHost.tsx:1887](../src/scenes/rpg/RpgGameHost.tsx#L1887)
1264. 7:55 横屏游戏
   来源：[src/scenes/rpg/RpgGameHost.tsx:1902](../src/scenes/rpg/RpgGameHost.tsx#L1902)
1265. 聚焦手机
   来源：[src/scenes/rpg/RpgGameHost.tsx:1994](../src/scenes/rpg/RpgGameHost.tsx#L1994)
1266. 全屏
   来源：[src/scenes/rpg/RpgGameHost.tsx:1995](../src/scenes/rpg/RpgGameHost.tsx#L1995)
1267. 地图视角
   来源：[src/scenes/rpg/RpgGameHost.tsx:2000](../src/scenes/rpg/RpgGameHost.tsx#L2000)
1268. 定位人物
   来源：[src/scenes/rpg/RpgGameHost.tsx:2001](../src/scenes/rpg/RpgGameHost.tsx#L2001)
1269. 放大地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2002](../src/scenes/rpg/RpgGameHost.tsx#L2002)
1270. 缩小地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2003](../src/scenes/rpg/RpgGameHost.tsx#L2003)
1271. 地图物品栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2053](../src/scenes/rpg/RpgGameHost.tsx#L2053)
1272. 物品栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2054](../src/scenes/rpg/RpgGameHost.tsx#L2054)
1273. 查看电子校园卡
   来源：[src/scenes/rpg/RpgGameHost.tsx:2059](../src/scenes/rpg/RpgGameHost.tsx#L2059)
1274. 单击查看校园卡信息，双击查看完整详情
   来源：[src/scenes/rpg/RpgGameHost.tsx:2060](../src/scenes/rpg/RpgGameHost.tsx#L2060)
1275. 已连接
   来源：[src/scenes/rpg/RpgGameHost.tsx:2085](../src/scenes/rpg/RpgGameHost.tsx#L2085)
1276. 待登记姓名
   来源：[src/scenes/rpg/RpgGameHost.tsx:2087](../src/scenes/rpg/RpgGameHost.tsx#L2087)
1277. 待开始锻炼
   来源：[src/scenes/rpg/RpgGameHost.tsx:2088](../src/scenes/rpg/RpgGameHost.tsx#L2088)
1278. 节奏钓鱼 A 左收线、S 提竿、D 右收线按钮
   来源：[src/scenes/rpg/RpgGameHost.tsx:2124](../src/scenes/rpg/RpgGameHost.tsx#L2124)
1279. A 左收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2128](../src/scenes/rpg/RpgGameHost.tsx#L2128)
1280. willowBranchPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2134](../src/scenes/rpg/RpgGameHost.tsx#L2134)
1281. 交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2195](../src/scenes/rpg/RpgGameHost.tsx#L2195)
1282. 与当前湖区目标交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2195](../src/scenes/rpg/RpgGameHost.tsx#L2195)
1283. RPG操作键，键盘使用 WASD 移动和空格键交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2202](../src/scenes/rpg/RpgGameHost.tsx#L2202)
1284. 向上
   来源：[src/scenes/rpg/RpgGameHost.tsx:2204](../src/scenes/rpg/RpgGameHost.tsx#L2204)
1285. 向左
   来源：[src/scenes/rpg/RpgGameHost.tsx:2205](../src/scenes/rpg/RpgGameHost.tsx#L2205)
1286. 向下
   来源：[src/scenes/rpg/RpgGameHost.tsx:2206](../src/scenes/rpg/RpgGameHost.tsx#L2206)
1287. 向右
   来源：[src/scenes/rpg/RpgGameHost.tsx:2207](../src/scenes/rpg/RpgGameHost.tsx#L2207)
1288. 深色模式只读取线索和异常，不执行实体操作。
   来源：[src/scenes/rpg/RpgInteractionContract.ts:34](../src/scenes/rpg/RpgInteractionContract.ts#L34)
1289. 浅色模式执行移动、拖放、清洁、付款和设备操作。
   来源：[src/scenes/rpg/RpgInteractionContract.ts:38](../src/scenes/rpg/RpgInteractionContract.ts#L38)
1290. 204 教室空槽位
   来源：[src/scenes/rpg/RpgInteractionContract.ts:426](../src/scenes/rpg/RpgInteractionContract.ts#L426)
1291. 烤箱旁的检修灯
   来源：[src/scenes/rpg/RpgInteractionContract.ts:513](../src/scenes/rpg/RpgInteractionContract.ts#L513)
1292. 面包坊传送带边缘
   来源：[src/scenes/rpg/RpgInteractionContract.ts:529](../src/scenes/rpg/RpgInteractionContract.ts#L529)
1293. 传送带旁的金属时针
   来源：[src/scenes/rpg/RpgInteractionContract.ts:545](../src/scenes/rpg/RpgInteractionContract.ts#L545)
1294. 清洁车卡住的轮罩
   来源：[src/scenes/rpg/RpgInteractionContract.ts:768](../src/scenes/rpg/RpgInteractionContract.ts#L768)
1295. 面包店后场短撬棍
   来源：[src/scenes/rpg/RpgInteractionContract.ts:784](../src/scenes/rpg/RpgInteractionContract.ts#L784)
1296. 清洁车轮罩
   来源：[src/scenes/rpg/RpgInteractionContract.ts:795](../src/scenes/rpg/RpgInteractionContract.ts#L795)
1297. 清洁车里的通用润滑油
   来源：[src/scenes/rpg/RpgInteractionContract.ts:809](../src/scenes/rpg/RpgInteractionContract.ts#L809)
1298. 清洁车车轮
   来源：[src/scenes/rpg/RpgInteractionContract.ts:820](../src/scenes/rpg/RpgInteractionContract.ts#L820)
1299. 签到校园卡读卡器
   来源：[src/scenes/rpg/RpgInteractionContract.ts:913](../src/scenes/rpg/RpgInteractionContract.ts#L913)；[src/scenes/rpg/RpgItemUseGuidance.ts:76](../src/scenes/rpg/RpgItemUseGuidance.ts#L76)
1300. 签到记录纸槽
   来源：[src/scenes/rpg/RpgInteractionContract.ts:929](../src/scenes/rpg/RpgInteractionContract.ts#L929)；[src/scenes/rpg/RpgItemUseGuidance.ts:82](../src/scenes/rpg/RpgItemUseGuidance.ts#L82)
1301. 先把最后一分钟归还到旧钟，再去签到口。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:85](../src/scenes/rpg/RpgItemUseGuidance.ts#L85)
1302. 旧钟接近 07:55 时，这张纸会被剧情自动带走。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:88](../src/scenes/rpg/RpgItemUseGuidance.ts#L88)

## 结局

1. locked
   来源：[src/core/GameState.ts:243](../src/core/GameState.ts#L243)
2. 围栏开了。朝左岸划。
   来源：[src/data/pursuit.audio.content.json:45](../src/data/pursuit.audio.content.json#L45)
3. The gate is open. Paddle for the left bank.
   来源：[src/data/pursuit.audio.content.json:46](../src/data/pursuit.audio.content.json#L46)
4. 校园卡余额
   来源：[src/data/scenes.config.json:9](../src/data/scenes.config.json#L9)
5. P04
   来源：[src/data/scenes.config.json:9](../src/data/scenes.config.json#L9)
6. 校务签到（学在浙大）
   来源：[src/data/scenes.config.json:10](../src/data/scenes.config.json#L10)
7. P11
   来源：[src/data/scenes.config.json:10](../src/data/scenes.config.json#L10)
8. 盆栽
   来源：[src/data/scenes.config.json:11](../src/data/scenes.config.json#L11)
9. P10
   来源：[src/data/scenes.config.json:11](../src/data/scenes.config.json#L11)
10. 序章结算 / 下一章入口
   来源：[src/data/scenes.config.json:12](../src/data/scenes.config.json#L12)
11. P12
   来源：[src/data/scenes.config.json:12](../src/data/scenes.config.json#L12)
12. narrator
   来源：[src/scenes/phone/P12_Ending/index.tsx:46](../src/scenes/phone/P12_Ending/index.tsx#L46)；[src/scenes/phone/P12_Ending/index.tsx:49](../src/scenes/phone/P12_Ending/index.tsx#L49)
13. 不，除非你帮助我
   来源：[src/scenes/phone/P12_Ending/index.tsx:47](../src/scenes/phone/P12_Ending/index.tsx#L47)
14. player
   来源：[src/scenes/phone/P12_Ending/index.tsx:47](../src/scenes/phone/P12_Ending/index.tsx#L47)；[src/scenes/phone/P12_Ending/index.tsx:48](../src/scenes/phone/P12_Ending/index.tsx#L48)
15. 不然你就和我的绩点同归于尽吧
   来源：[src/scenes/phone/P12_Ending/index.tsx:48](../src/scenes/phone/P12_Ending/index.tsx#L48)
16. 序章结算
   来源：[src/scenes/phone/P12_Ending/index.tsx:505](../src/scenes/phone/P12_Ending/index.tsx#L505)
17. 黑屏
   来源：[src/scenes/phone/P12_Ending/index.tsx:510](../src/scenes/phone/P12_Ending/index.tsx#L510)
18. GEO ERROR // INTERCEPT
   来源：[src/scenes/phone/P12_Ending/index.tsx:516](../src/scenes/phone/P12_Ending/index.tsx#L516)
19. 错误框拦截
   来源：[src/scenes/phone/P12_Ending/index.tsx:517](../src/scenes/phone/P12_Ending/index.tsx#L517)
20. 已挡住 {{view.blockedCount}} 次，共 {{REQUIRED\_BLOCKS}} 次
   来源：[src/scenes/phone/P12_Ending/index.tsx:519](../src/scenes/phone/P12_Ending/index.tsx#L519)
21. 失误
   来源：[src/scenes/phone/P12_Ending/index.tsx:524](../src/scenes/phone/P12_Ending/index.tsx#L524)
22. 旁白
   来源：[src/scenes/phone/P12_Ending/index.tsx:532](../src/scenes/phone/P12_Ending/index.tsx#L532)；[src/scenes/phone/P12_Ending/index.tsx:576](../src/scenes/phone/P12_Ending/index.tsx#L576)；[src/scenes/phone/P12_Ending/index.tsx:650](../src/scenes/phone/P12_Ending/index.tsx#L650)
23. 按住旁白圆圈完成锁定，当前 {{Math.round(lockProgress \* 100)}}%
   来源：[src/scenes/phone/P12_Ending/index.tsx:547](../src/scenes/phone/P12_Ending/index.tsx#L547)
24. 正在移动的旁白圆圈
   来源：[src/scenes/phone/P12_Ending/index.tsx:573](../src/scenes/phone/P12_Ending/index.tsx#L573)
25. 拖动经纬度错误框挡住下方出口，键盘可用 A D 或左右方向键
   来源：[src/scenes/phone/P12_Ending/index.tsx:589](../src/scenes/phone/P12_Ending/index.tsx#L589)
26. LOCATION ERROR
   来源：[src/scenes/phone/P12_Ending/index.tsx:608](../src/scenes/phone/P12_Ending/index.tsx#L608)
27. 经度与纬度不存在
   来源：[src/scenes/phone/P12_Ending/index.tsx:609](../src/scenes/phone/P12_Ending/index.tsx#L609)
28. null / null
   来源：[src/scenes/phone/P12_Ending/index.tsx:610](../src/scenes/phone/P12_Ending/index.tsx#L610)
29. 已挡住
   来源：[src/scenes/phone/P12_Ending/index.tsx:615](../src/scenes/phone/P12_Ending/index.tsx#L615)
30. 未命中出口位置
   来源：[src/scenes/phone/P12_Ending/index.tsx:618](../src/scenes/phone/P12_Ending/index.tsx#L618)
31. SIGNAL LOST
   来源：[src/scenes/phone/P12_Ending/index.tsx:623](../src/scenes/phone/P12_Ending/index.tsx#L623)
32. 拦截失败
   来源：[src/scenes/phone/P12_Ending/index.tsx:624](../src/scenes/phone/P12_Ending/index.tsx#L624)
33. 错误框连续三次没有对齐出口。
   来源：[src/scenes/phone/P12_Ending/index.tsx:625](../src/scenes/phone/P12_Ending/index.tsx#L625)
34. 重新部署错误框
   来源：[src/scenes/phone/P12_Ending/index.tsx:626](../src/scenes/phone/P12_Ending/index.tsx#L626)
35. 按住圆圈 1.4 秒完成锁定
   来源：[src/scenes/phone/P12_Ending/index.tsx:632](../src/scenes/phone/P12_Ending/index.tsx#L632)
36. 拖动错误框 · 键盘 A / D 或 ← / →
   来源：[src/scenes/phone/P12_Ending/index.tsx:632](../src/scenes/phone/P12_Ending/index.tsx#L632)
37. 已被锁定的旁白圆圈
   来源：[src/scenes/phone/P12_Ending/index.tsx:640](../src/scenes/phone/P12_Ending/index.tsx#L640)
38. 已锁定
   来源：[src/scenes/phone/P12_Ending/index.tsx:642](../src/scenes/phone/P12_Ending/index.tsx#L642)
39. 我
   来源：[src/scenes/phone/P12_Ending/index.tsx:650](../src/scenes/phone/P12_Ending/index.tsx#L650)
40. 已暂停
   来源：[src/scenes/phone/P12_Ending/index.tsx:657](../src/scenes/phone/P12_Ending/index.tsx#L657)
41. 白屏闪退
   来源：[src/scenes/phone/P12_Ending/index.tsx:659](../src/scenes/phone/P12_Ending/index.tsx#L659)
42. 哐当——齿轮转了半圈，掉下来了。背面朝外。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:99](../src/scenes/phone/P13_PhoneHome/index.tsx#L99)
43. 记录恢复
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:868](../src/scenes/phone/P13_PhoneHome/index.tsx#L868)
44. 检测到 7 分 55 秒未同步记录
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:868](../src/scenes/phone/P13_PhoneHome/index.tsx#L868)
45. 现在
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:869](../src/scenes/phone/P13_PhoneHome/index.tsx#L869)；[src/scenes/phone/P13_PhoneHome/index.tsx:884](../src/scenes/phone/P13_PhoneHome/index.tsx#L884)
46. 朋友：成功了吗
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:872](../src/scenes/phone/P13_PhoneHome/index.tsx#L872)
47. 成功了吗
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:883](../src/scenes/phone/P13_PhoneHome/index.tsx#L883)；[src/scenes/phone/P14_Wechat/index.tsx:844](../src/scenes/phone/P14_Wechat/index.tsx#L844)
48. 朋友
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:883](../src/scenes/phone/P13_PhoneHome/index.tsx#L883)；[src/scenes/phone/P14_Wechat/index.tsx:839](../src/scenes/phone/P14_Wechat/index.tsx#L839)
49. 朋友发来的微信消息
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:887](../src/scenes/phone/P13_PhoneHome/index.tsx#L887)
50. 任务更新：找到系统
   来源：[src/scenes/phone/P14_Wechat/index.tsx:297](../src/scenes/phone/P14_Wechat/index.tsx#L297)
51. task
   来源：[src/scenes/phone/P14_Wechat/index.tsx:297](../src/scenes/phone/P14_Wechat/index.tsx#L297)
52. 你到底到哪了？
   来源：[src/scenes/phone/P14_Wechat/index.tsx:842](../src/scenes/phone/P14_Wechat/index.tsx#L842)
53. 这是签到码 ▓▓▓▓
   来源：[src/scenes/phone/P14_Wechat/index.tsx:846](../src/scenes/phone/P14_Wechat/index.tsx#L846)
54. 快快老师在点名，学在浙大
   来源：[src/scenes/phone/P14_Wechat/index.tsx:847](../src/scenes/phone/P14_Wechat/index.tsx#L847)
55. 室友：还有 12 秒进入梦乡最深处。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:858](../src/scenes/phone/P14_Wechat/index.tsx#L858)
56. 室友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:866](../src/scenes/phone/P14_Wechat/index.tsx#L866)
57. 晚上一起去食堂吃饭呀~
   来源：[src/scenes/phone/P14_Wechat/index.tsx:867](../src/scenes/phone/P14_Wechat/index.tsx#L867)
58. 没有，但我正试着威胁系统
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1017](../src/scenes/phone/P14_Wechat/index.tsx#L1017)
59. 启真湖地点线索
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1035](../src/scenes/phone/P14_Wechat/index.tsx#L1035)
60. 保存地点词：湖面
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1044](../src/scenes/phone/P14_Wechat/index.tsx#L1044)
61. 已保存地点词：湖面
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1044](../src/scenes/phone/P14_Wechat/index.tsx#L1044)
62. 任务：找到系统
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1051](../src/scenes/phone/P14_Wechat/index.tsx#L1051)
63. 任务：找回四位签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1053](../src/scenes/phone/P14_Wechat/index.tsx#L1053)
64. 座位状态图例
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:520](../src/scenes/phone/P15_Zjuding/index.tsx#L520)
65. 空闲中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:522](../src/scenes/phone/P15_Zjuding/index.tsx#L522)
66. 已预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:523](../src/scenes/phone/P15_Zjuding/index.tsx#L523)
67. 使用中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:524](../src/scenes/phone/P15_Zjuding/index.tsx#L524)
68. 暂停中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:525](../src/scenes/phone/P15_Zjuding/index.tsx#L525)
69. 不可用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:526](../src/scenes/phone/P15_Zjuding/index.tsx#L526)
70. 请点击白色座位选座
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:535](../src/scenes/phone/P15_Zjuding/index.tsx#L535)
71. Please select a seat available
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:536](../src/scenes/phone/P15_Zjuding/index.tsx#L536)
72. P00 闹钟
   来源：[src/scenes/phone/registry.tsx:23](../src/scenes/phone/registry.tsx#L23)
73. 07:55 闹钟，振动+音效，关闭后进入起床场景。
   来源：[src/scenes/phone/registry.tsx:24](../src/scenes/phone/registry.tsx#L24)
74. 倒影对应点一
   来源：[src/scenes/rpg/RpgGameHost.tsx:204](../src/scenes/rpg/RpgGameHost.tsx#L204)
75. 旧木桩倒影
   来源：[src/scenes/rpg/RpgGameHost.tsx:205](../src/scenes/rpg/RpgGameHost.tsx#L205)
76. 鱼群水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:206](../src/scenes/rpg/RpgGameHost.tsx#L206)
77. 纸条本体水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:207](../src/scenes/rpg/RpgGameHost.tsx#L207)
78. 启真湖的行程还没开始,现在拍不了。
   来源：[src/scenes/rpg/RpgGameHost.tsx:210](../src/scenes/rpg/RpgGameHost.tsx#L210)
79. 黑天鹅正追着船尾,顾不上拍照。
   来源：[src/scenes/rpg/RpgGameHost.tsx:211](../src/scenes/rpg/RpgGameHost.tsx#L211)
80. 先完成上船教学,稳住船之后再打开相机。
   来源：[src/scenes/rpg/RpgGameHost.tsx:212](../src/scenes/rpg/RpgGameHost.tsx#L212)
81. 手柄已安装，自动走动已停止。请输入一次方向。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1114](../src/scenes/rpg/RpgGameHost.tsx#L1114)
82. 他还不知道自己是谁。先用部门黄页完成命名。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1115](../src/scenes/rpg/RpgGameHost.tsx#L1115)
83. 他还没有开始课外锻炼。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1116](../src/scenes/rpg/RpgGameHost.tsx#L1116)
84. 道具栏里没有手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1117](../src/scenes/rpg/RpgGameHost.tsx#L1117)
85. 204 讲台抽屉里的定位盘
   来源：[src/scenes/rpg/RpgInteractionContract.ts:733](../src/scenes/rpg/RpgInteractionContract.ts#L733)
86. 旧钟定位盘插槽
   来源：[src/scenes/rpg/RpgInteractionContract.ts:756](../src/scenes/rpg/RpgInteractionContract.ts#L756)
87. no\_response
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1275](../src/scenes/rpg/RpgInteractionContract.ts#L1275)
88. multiple\_responses
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1276](../src/scenes/rpg/RpgInteractionContract.ts#L1276)
89. invalid\_response
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1279](../src/scenes/rpg/RpgInteractionContract.ts#L1279)

## 跨章节与共用系统

1. 当前剧情条件已变化，请返回任务目标后重试。
   来源：[src/App.tsx:142](../src/App.tsx#L142)
2. 手机交互区
   来源：[src/App.tsx:358](../src/App.tsx#L358)
3. 地图交互区
   来源：[src/App.tsx:376](../src/App.tsx#L376)
4. Loading RPG runtime
   来源：[src/App.tsx:381](../src/App.tsx#L381)；[src/App.tsx:411](../src/App.tsx#L411)
5. 安中大楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
6. 白沙二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
7. 白沙三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
8. 白沙四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
9. 白沙一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
10. 宝港生活广场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
11. 北二门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
12. 北一门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
13. 碧峰二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
14. 碧峰三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
15. 碧峰四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
16. 碧峰五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
17. 碧峰一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
18. 变电站
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
19. 茶花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
20. 成均苑3幢（创B大楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
21. 翠柏二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
22. 翠柏三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
23. 翠柏四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
24. 翠柏一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
25. 大食堂停车场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
26. 待定
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
27. 丹阳二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
28. 丹阳六幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
29. 丹阳三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
30. 丹阳四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
31. 丹阳五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
32. 丹阳一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
33. 迪臣路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
34. 东7
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
35. 东二教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
36. 东二门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
37. 东六教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
38. 东三教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
39. 东三门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
40. 东四教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
41. 东田径场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
42. 东五教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
43. 东一教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
44. 东一门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
45. 动力中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
46. 动物中心楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
47. 段永平教学楼（北教）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
48. 段永平教学楼（北教学楼1号楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
49. 段永平教学楼（北教学楼2号楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
50. 段永平教学楼（北教学楼4号楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
51. 段永平生命科学研究交叉中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
52. 风雨操场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
53. 港湾家园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
54. 港湾家园29幢（大学生创业实训基地）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
55. 工程训练（金工）中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
56. 观通楼（农科教大楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
57. 桂花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
58. 海洋试验厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
59. 海洋与计算中心楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
60. 杭州市西湖区
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
61. 杭州市西湖区余杭塘路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
62. 杭州市西湖区余杭塘路866号
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
63. 湖滨路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
64. 华家池路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
65. 化学实验中心（周厚复楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
66. 化学试剂仓库
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
67. 机器人与智能装备
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
68. 基础交叉研究大楼（在建）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
69. 建工试验厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
70. 教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
71. 教学楼12
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
72. 金秀楼（校医院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
73. 开物苑（机械学院3幢）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
74. 看台
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
75. 蓝田二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
76. 蓝田六幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
77. 蓝田三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
78. 蓝田四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
79. 蓝田五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
80. 蓝田一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
81. 篮球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
82. 临湖餐厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
83. 留祥路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
84. 留学生公寓A楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
85. 留学生公寓B楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
86. 蒙民伟楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
87. 纳米楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
88. 南华园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
89. 农生环大楼A座（农学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
90. 农生环大楼B座（环资学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
91. 农生环大楼C座（农业生命环境学部、交叉平台）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
92. 农生环大楼D座（生工食品学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
93. 农生环大楼E座（动物科学学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
94. 农业科技创新试验中心D
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
95. 农业试验站A
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
96. 农业试验站B
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
97. 农业试验站C
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
98. 藕舫路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
99. 牌坊
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
100. 潘方仁求是馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
101. 匹克球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
102. 其他
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
103. 启真湖
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/data/phonePhotoCatalog.ts:130](../src/data/phonePhotoCatalog.ts#L130)；[src/scenes/phone/P15_Zjuding/index.tsx:1473](../src/scenes/phone/P15_Zjuding/index.tsx#L1473)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
104. 前沿学科综合大楼（来同馆）（在建）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
105. 青溪二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
106. 青溪三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
107. 青溪四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
108. 青溪一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
109. 求是大道
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
110. 求是大讲堂
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
111. 生科楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
112. 生物实验中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
113. 生物物理楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
114. 实验果园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
115. 实验室
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
116. 思睿桥
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
117. 泰和路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
118. 桃花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
119. 图书信息A楼（基础图书馆）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
120. 图书信息C楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
121. 万物母气鼎
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
122. 网球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
123. 西部发展研究院大楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
124. 西二教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
125. 西迁纪念亭
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
126. 西区动物中心A座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
127. 西区动物中心B座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
128. 西区动物中心C座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
129. 西区动物中心D座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
130. 西三教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
131. 西四教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
132. 西田径场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
133. 西一教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
134. 小白楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
135. 校医院2号楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
136. 校友林小木屋
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
137. 校友楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
138. 行政服务办事大厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
139. 学生长廊
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
140. 学生综合楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
141. 亚运比赛馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
142. 亚运热身馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
143. 阳明桥
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
144. 药学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
145. 医学教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
146. 医学科研楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
147. 医学院科研楼辅楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
148. 医学专业图书馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
149. 医学综合楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
150. 宜山环路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
151. 音乐厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
152. 银泉1幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
153. 银泉3幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
154. 银泉5幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
155. 银泉餐厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
156. 银泉学生服务中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
157. 樱花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
158. 咏曼阁（临水报告厅）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
159. 游泳馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
160. 余杭塘路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
161. 羽毛球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
162. 月牙楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/data/phonePhotoCatalog.ts:142](../src/data/phonePhotoCatalog.ts#L142)；[src/scenes/rpg/ZijingangCampusLayout.ts:135](../src/scenes/rpg/ZijingangCampusLayout.ts#L135)
163. 浙江大学动物医院
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
164. 浙江省杭州市西湖区浙江大学药学院鑫药创制园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
165. 竺可桢像
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
166. 主图书馆（浙江大学校史校情馆）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
167. 紫金港剧场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
168. 紫金港食堂（东区）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
169. 紫金港校区
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/data/phonePhotoCatalog.ts:118](../src/data/phonePhotoCatalog.ts#L118)
170. 紫金港校区北门门卫房
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
171. 紫金港校区东二门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
172. 紫金港校区求是物业苗圃玻璃房
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
173. 紫荆花路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
174. 紫云二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
175. 紫云三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
176. 紫云四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
177. 紫云五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
178. 紫云一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
179. 足球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
180. 遵义西路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
181. urn:ogc:def:crs:EPSG::32651
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
182. X图书馆1(1).jpg
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
183. 教学楼单电梯门六档动画
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4153](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4153)
184. 启真湖至教学楼拱廊
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4377](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4377)
185. 只用于启真湖追逐结束后的低机位纸条追踪序幕。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4381](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4381)
186. 一楼门厅与迈斯威
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4403](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4403)
187. 承担旧版入楼、气流轨迹教学、纸张干燥与整楼复位演出。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4407](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4407)
188. 楼梯间
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4430](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4430)
189. 历史楼梯间环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4434](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4434)
190. 电梯竖向交通核
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4454](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4454)
191. 历史电梯交通核环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4458](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4458)
192. 二楼开放自习与活动区
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4480](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4480)
193. 历史二楼活动区环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4484](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4484)
194. N3-214 智慧教室
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4507](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4507)
195. 历史终局教室环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4511](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4511)
196. 教学楼 1F · 麦思威与校友廊
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4534](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4534)
197. 三层正式母图之前的历史教学楼一层图。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4538](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4538)
198. 教学楼 2F · 教室与开放学习区
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4559](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4559)
199. 三层正式母图之前的历史教学楼二层图。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4563](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4563)
200. 教学楼 3F · 校友荣誉门厅
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4584](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4584)
201. 三层正式母图之前的历史教学楼三层图。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4588](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4588)
202. 已连接 ZJUWLAN
   来源：[src/components/ControlCenter.tsx:44](../src/components/ControlCenter.tsx#L44)
203. 已切换到移动数据（流量心在滴血）
   来源：[src/components/ControlCenter.tsx:44](../src/components/ControlCenter.tsx#L44)
204. campus\_wifi
   来源：[src/components/ControlCenter.tsx:44](../src/components/ControlCenter.tsx#L44)
205. 耳机安静地挂着，不理你。
   来源：[src/components/ControlCenter.tsx:56](../src/components/ControlCenter.tsx#L56)
206. 耳机掉了下来，背面朝下。
   来源：[src/components/ControlCenter.tsx:67](../src/components/ControlCenter.tsx#L67)
207. task
   来源：[src/components/ControlCenter.tsx:67](../src/components/ControlCenter.tsx#L67)；[src/components/ControlCenter.tsx:128](../src/components/ControlCenter.tsx#L128)；[src/components/InventoryBar.tsx:452](../src/components/InventoryBar.tsx#L452)；[src/scenes/phone/P02_CC98/index.tsx:323](../src/scenes/phone/P02_CC98/index.tsx#L323)；[src/scenes/phone/P02_CC98/index.tsx:726](../src/scenes/phone/P02_CC98/index.tsx#L726)；[src/scenes/phone/P07_Weather/index.tsx:55](../src/scenes/phone/P07_Weather/index.tsx#L55)；[src/scenes/phone/P13_PhoneHome/index.tsx:138](../src/scenes/phone/P13_PhoneHome/index.tsx#L138)；[src/scenes/phone/P13_PhoneHome/index.tsx:183](../src/scenes/phone/P13_PhoneHome/index.tsx#L183)；[src/scenes/phone/P13_PhoneHome/index.tsx:364](../src/scenes/phone/P13_PhoneHome/index.tsx#L364)；[src/scenes/phone/P13_PhoneHome/index.tsx:386](../src/scenes/phone/P13_PhoneHome/index.tsx#L386)；[src/scenes/phone/P14_Wechat/index.tsx:236](../src/scenes/phone/P14_Wechat/index.tsx#L236)；[src/scenes/phone/P14_Wechat/index.tsx:363](../src/scenes/phone/P14_Wechat/index.tsx#L363)；[src/scenes/phone/P14_Wechat/index.tsx:443](../src/scenes/phone/P14_Wechat/index.tsx#L443)；[src/scenes/phone/P14_Wechat/index.tsx:509](../src/scenes/phone/P14_Wechat/index.tsx#L509)；[src/scenes/phone/P15_Zjuding/index.tsx:655](../src/scenes/phone/P15_Zjuding/index.tsx#L655)；[src/scenes/phone/P15_Zjuding/index.tsx:948](../src/scenes/phone/P15_Zjuding/index.tsx#L948)；[src/scenes/phone/P15_Zjuding/index.tsx:952](../src/scenes/phone/P15_Zjuding/index.tsx#L952)；[src/scenes/phone/P15_Zjuding/index.tsx:955](../src/scenes/phone/P15_Zjuding/index.tsx#L955)；[src/scenes/phone/P15_Zjuding/index.tsx:1054](../src/scenes/phone/P15_Zjuding/index.tsx#L1054)
208. 自动旋转已关闭。
   来源：[src/components/ControlCenter.tsx:123](../src/components/ControlCenter.tsx#L123)
209. 自动旋转已开启。
   来源：[src/components/ControlCenter.tsx:123](../src/components/ControlCenter.tsx#L123)
210. 存档写入失败，请检查浏览器存储权限。
   来源：[src/components/ControlCenter.tsx:128](../src/components/ControlCenter.tsx#L128)
211. 进度已保存。
   来源：[src/components/ControlCenter.tsx:128](../src/components/ControlCenter.tsx#L128)
212. 控制中心
   来源：[src/components/ControlCenter.tsx:139](../src/components/ControlCenter.tsx#L139)；[src/scenes/phone/P08_Settings/index.tsx:36](../src/scenes/phone/P08_Settings/index.tsx#L36)
213. 关闭控制中心
   来源：[src/components/ControlCenter.tsx:140](../src/components/ControlCenter.tsx#L140)
214. 7月9日 周四
   来源：[src/components/ControlCenter.tsx:143](../src/components/ControlCenter.tsx#L143)
215. 收起
   来源：[src/components/ControlCenter.tsx:144](../src/components/ControlCenter.tsx#L144)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:352](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L352)
216. 未连接
   来源：[src/components/ControlCenter.tsx:163](../src/components/ControlCenter.tsx#L163)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
217. 已连接
   来源：[src/components/ControlCenter.tsx:163](../src/components/ControlCenter.tsx#L163)
218. 移动数据
   来源：[src/components/ControlCenter.tsx:179](../src/components/ControlCenter.tsx#L179)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
219. 使用中
   来源：[src/components/ControlCenter.tsx:180](../src/components/ControlCenter.tsx#L180)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
220. 已关闭
   来源：[src/components/ControlCenter.tsx:180](../src/components/ControlCenter.tsx#L180)
221. music
   来源：[src/components/ControlCenter.tsx:188](../src/components/ControlCenter.tsx#L188)
222. 未在播放
   来源：[src/components/ControlCenter.tsx:189](../src/components/ControlCenter.tsx#L189)
223. 正在播放：早八进行曲
   来源：[src/components/ControlCenter.tsx:189](../src/components/ControlCenter.tsx#L189)
224. 播放音乐
   来源：[src/components/ControlCenter.tsx:192](../src/components/ControlCenter.tsx#L192)
225. 暂停
   来源：[src/components/ControlCenter.tsx:192](../src/components/ControlCenter.tsx#L192)
226. 耳机
   来源：[src/components/ControlCenter.tsx:200](../src/components/ControlCenter.tsx#L200)；[src/components/PixelIcon.tsx:831](../src/components/PixelIcon.tsx#L831)；[src/data/items.config.json:11](../src/data/items.config.json#L11)
227. headphone
   来源：[src/components/ControlCenter.tsx:202](../src/components/ControlCenter.tsx#L202)
228. 耳机不见了
   来源：[src/components/ControlCenter.tsx:205](../src/components/ControlCenter.tsx#L205)
229. 亮度
   来源：[src/components/ControlCenter.tsx:214](../src/components/ControlCenter.tsx#L214)
230. sun
   来源：[src/components/ControlCenter.tsx:237](../src/components/ControlCenter.tsx#L237)
231. 自动旋转
   来源：[src/components/ControlCenter.tsx:252](../src/components/ControlCenter.tsx#L252)
232. 振动一直开着。它见证了闹钟的一切。
   来源：[src/components/ControlCenter.tsx:254](../src/components/ControlCenter.tsx#L254)
233. 振动
   来源：[src/components/ControlCenter.tsx:258](../src/components/ControlCenter.tsx#L258)
234. 飞行模式？你连教室都飞不到。
   来源：[src/components/ControlCenter.tsx:260](../src/components/ControlCenter.tsx#L260)
235. 飞行模式
   来源：[src/components/ControlCenter.tsx:264](../src/components/ControlCenter.tsx#L264)
236. 勿扰模式无法阻挡早八。
   来源：[src/components/ControlCenter.tsx:266](../src/components/ControlCenter.tsx#L266)
237. 勿扰
   来源：[src/components/ControlCenter.tsx:270](../src/components/ControlCenter.tsx#L270)
238. 存档管理
   来源：[src/components/ControlCenter.tsx:274](../src/components/ControlCenter.tsx#L274)
239. 游戏进度
   来源：[src/components/ControlCenter.tsx:277](../src/components/ControlCenter.tsx#L277)
240. 自动保存已开启
   来源：[src/components/ControlCenter.tsx:278](../src/components/ControlCenter.tsx#L278)
241. 立即保存
   来源：[src/components/ControlCenter.tsx:284](../src/components/ControlCenter.tsx#L284)
242. 重置剧情进度
   来源：[src/components/ControlCenter.tsx:285](../src/components/ControlCenter.tsx#L285)
243. 将清除章节、道具和谜题进度。编辑过的 CC98 帖子会保留。
   来源：[src/components/ControlCenter.tsx:289](../src/components/ControlCenter.tsx#L289)
244. 取消
   来源：[src/components/ControlCenter.tsx:290](../src/components/ControlCenter.tsx#L290)
245. 确认重置
   来源：[src/components/ControlCenter.tsx:291](../src/components/ControlCenter.tsx#L291)
246. 系统
   来源：[src/components/GameSubtitleFrame.tsx:16](../src/components/GameSubtitleFrame.tsx#L16)；[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)；[src/scenes/phone/P15_Zjuding/index.tsx:2097](../src/scenes/phone/P15_Zjuding/index.tsx#L2097)
247. 旁白
   来源：[src/components/GameSubtitleFrame.tsx:17](../src/components/GameSubtitleFrame.tsx#L17)；[src/data/storyLines.ts:58](../src/data/storyLines.ts#L58)
248. 任务
   来源：[src/components/GameSubtitleFrame.tsx:18](../src/components/GameSubtitleFrame.tsx#L18)；[src/components/QuestClueStrip.tsx:176](../src/components/QuestClueStrip.tsx#L176)；[src/scenes/phone/P15_Zjuding/index.tsx:2014](../src/scenes/phone/P15_Zjuding/index.tsx#L2014)
249. 我
   来源：[src/components/GameSubtitleFrame.tsx:19](../src/components/GameSubtitleFrame.tsx#L19)；[src/scenes/phone/P02_CC98/index.tsx:187](../src/scenes/phone/P02_CC98/index.tsx#L187)；[src/scenes/phone/P15_Zjuding/index.tsx:2097](../src/scenes/phone/P15_Zjuding/index.tsx#L2097)
250. 记录
   来源：[src/components/GameSubtitleFrame.tsx:20](../src/components/GameSubtitleFrame.tsx#L20)；[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)；[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)；[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)
251. 提示
   来源：[src/components/GameSubtitleFrame.tsx:21](../src/components/GameSubtitleFrame.tsx#L21)；[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)
252. 广播
   来源：[src/components/GameSubtitleFrame.tsx:22](../src/components/GameSubtitleFrame.tsx#L22)
253. 身份信息
   来源：[src/components/GameSubtitleFrame.tsx:37](../src/components/GameSubtitleFrame.tsx#L37)
254. 身份编号
   来源：[src/components/GameSubtitleFrame.tsx:38](../src/components/GameSubtitleFrame.tsx#L38)
255. game-subtitle-frame subtitle-tone-{{tone}} {{timed ? "is-timed" : "is-line-entering"}} {{className}}
   来源：[src/components/GameSubtitleFrame.tsx:57](../src/components/GameSubtitleFrame.tsx#L57)
256. {{ITEM\_META\[next\].name}}：{{ITEM\_META\[next\].desc}}
   来源：[src/components/InventoryBar.tsx:440](../src/components/InventoryBar.tsx#L440)
257. 合成成功：{{ITEM\_META\[result\].name}}！
   来源：[src/components/InventoryBar.tsx:452](../src/components/InventoryBar.tsx#L452)
258. 它们拒绝合作。
   来源：[src/components/InventoryBar.tsx:455](../src/components/InventoryBar.tsx#L455)
259. 已命中高亮目标，正在校验当前剧情条件。
   来源：[src/components/InventoryBar.tsx:464](../src/components/InventoryBar.tsx#L464)
260. 没有放进高亮区域，请在目标框内松手。
   来源：[src/components/InventoryBar.tsx:469](../src/components/InventoryBar.tsx#L469)
261. 物品栏
   来源：[src/components/InventoryBar.tsx:520](../src/components/InventoryBar.tsx#L520)
262. 收起物品栏
   来源：[src/components/InventoryBar.tsx:539](../src/components/InventoryBar.tsx#L539)
263. 展开物品栏
   来源：[src/components/InventoryBar.tsx:539](../src/components/InventoryBar.tsx#L539)
264. backpack
   来源：[src/components/InventoryBar.tsx:541](../src/components/InventoryBar.tsx#L541)
265. 空空如也
   来源：[src/components/InventoryBar.tsx:556](../src/components/InventoryBar.tsx#L556)
266. 道具：{{ITEM\_META\[item\].name}}，{{isPaperItem(item) ? "点击展开内容" : "双击查看详情"}}
   来源：[src/components/InventoryBar.tsx:565](../src/components/InventoryBar.tsx#L565)
267. 拖到真实物件；松手后会校验距离、目标和剧情条件
   来源：[src/components/InventoryBar.tsx:581](../src/components/InventoryBar.tsx#L581)
268. {{ITEM\_META\[state.ui.selectedItem\].name}} · 双击查看
   来源：[src/components/InventoryBar.tsx:583](../src/components/InventoryBar.tsx#L583)
269. 可拖动 · 双击查看
   来源：[src/components/InventoryBar.tsx:584](../src/components/InventoryBar.tsx#L584)
270. 环境材料
   来源：[src/components/ItemInspectDialog.tsx:35](../src/components/ItemInspectDialog.tsx#L35)
271. 主屏早八雨滴
   来源：[src/components/ItemInspectDialog.tsx:36](../src/components/ItemInspectDialog.tsx#L36)
272. 一滴不够浇花。某件翻到背面的随身设备，刚好留着一个空腔。
   来源：[src/components/ItemInspectDialog.tsx:37](../src/components/ItemInspectDialog.tsx#L37)
273. 容器素材
   来源：[src/components/ItemInspectDialog.tsx:40](../src/components/ItemInspectDialog.tsx#L40)
274. 控制中心音乐模块
   来源：[src/components/ItemInspectDialog.tsx:41](../src/components/ItemInspectDialog.tsx#L41)
275. 正面负责声音，背面留着凹处。那一点空位还没有装东西。
   来源：[src/components/ItemInspectDialog.tsx:42](../src/components/ItemInspectDialog.tsx#L42)
276. 合成道具
   来源：[src/components/ItemInspectDialog.tsx:45](../src/components/ItemInspectDialog.tsx#L45)
277. 耳机 + 水滴
   来源：[src/components/ItemInspectDialog.tsx:46](../src/components/ItemInspectDialog.tsx#L46)
278. 耳机背面的空腔里留着一小份水，液体没有继续渗出。
   来源：[src/components/ItemInspectDialog.tsx:47](../src/components/ItemInspectDialog.tsx#L47)
279. 机械素材
   来源：[src/components/ItemInspectDialog.tsx:50](../src/components/ItemInspectDialog.tsx#L50)
280. 主屏设置齿轮背面
   来源：[src/components/ItemInspectDialog.tsx:51](../src/components/ItemInspectDialog.tsx#L51)
281. 数字藏在背面，齿形留在边缘。若再接上一段斜线，轮廓会更完整。
   来源：[src/components/ItemInspectDialog.tsx:52](../src/components/ItemInspectDialog.tsx#L52)
282. 图形素材
   来源：[src/components/ItemInspectDialog.tsx:55](../src/components/ItemInspectDialog.tsx#L55)；[src/components/ItemInspectDialog.tsx:75](../src/components/ItemInspectDialog.tsx#L75)；[src/components/ItemInspectDialog.tsx:85](../src/components/ItemInspectDialog.tsx#L85)
283. 朋友头像掉落的一撇
   来源：[src/components/ItemInspectDialog.tsx:56](../src/components/ItemInspectDialog.tsx#L56)
284. 单独看只是一撇。某个带齿的圆形部件缺少一段细长结构。
   来源：[src/components/ItemInspectDialog.tsx:57](../src/components/ItemInspectDialog.tsx#L57)
285. 解锁工具
   来源：[src/components/ItemInspectDialog.tsx:60](../src/components/ItemInspectDialog.tsx#L60)；[src/components/ItemInspectDialog.tsx:269](../src/components/ItemInspectDialog.tsx#L269)
286. 斜线 + 反转齿轮
   来源：[src/components/ItemInspectDialog.tsx:61](../src/components/ItemInspectDialog.tsx#L61)
287. 轮廓已经完整。主屏高处有一处尺寸相近、一直没有作用的圆孔。
   来源：[src/components/ItemInspectDialog.tsx:62](../src/components/ItemInspectDialog.tsx#L62)
288. 植物材料
   来源：[src/components/ItemInspectDialog.tsx:65](../src/components/ItemInspectDialog.tsx#L65)
289. 塔楼机关奖励
   来源：[src/components/ItemInspectDialog.tsx:66](../src/components/ItemInspectDialog.tsx#L66)
290. 水、光、土壤养分，顺序可以不同，三项都要留下痕迹。
   来源：[src/components/ItemInspectDialog.tsx:67](../src/components/ItemInspectDialog.tsx#L67)
291. 身份凭证
   来源：[src/components/ItemInspectDialog.tsx:70](../src/components/ItemInspectDialog.tsx#L70)
292. 寝室右侧书桌 / 电子校园卡
   来源：[src/components/ItemInspectDialog.tsx:71](../src/components/ItemInspectDialog.tsx#L71)
293. 姓名和学号用于身份核验；余额与校园服务会在后续流程中继续使用。
   来源：[src/components/ItemInspectDialog.tsx:72](../src/components/ItemInspectDialog.tsx#L72)
294. 主页推送头像
   来源：[src/components/ItemInspectDialog.tsx:76](../src/components/ItemInspectDialog.tsx#L76)
295. 尖端已经给出方向，尾部仍少一条笔直的结构。
   来源：[src/components/ItemInspectDialog.tsx:77](../src/components/ItemInspectDialog.tsx#L77)
296. 功能材料
   来源：[src/components/ItemInspectDialog.tsx:80](../src/components/ItemInspectDialog.tsx#L80)
297. 天气页面
   来源：[src/components/ItemInspectDialog.tsx:81](../src/components/ItemInspectDialog.tsx#L81)
298. 水量很少，浇花显得勉强。某张头像边缘的连接处只需要一点湿润。
   来源：[src/components/ItemInspectDialog.tsx:82](../src/components/ItemInspectDialog.tsx#L82)
299. 导师头像掉落的一竖
   来源：[src/components/ItemInspectDialog.tsx:86](../src/components/ItemInspectDialog.tsx#L86)
300. 长度和方向都合适；某个只有尖端的图形还缺它。
   来源：[src/components/ItemInspectDialog.tsx:87](../src/components/ItemInspectDialog.tsx#L87)
301. 位移工具
   来源：[src/components/ItemInspectDialog.tsx:90](../src/components/ItemInspectDialog.tsx#L90)
302. 三角形 + 竖线
   来源：[src/components/ItemInspectDialog.tsx:91](../src/components/ItemInspectDialog.tsx#L91)
303. 它只规定向右，不规定对象。写着数的、夹在缝里的，都属于可尝试范围。
   来源：[src/components/ItemInspectDialog.tsx:92](../src/components/ItemInspectDialog.tsx#L92)
304. 控制设备
   来源：[src/components/ItemInspectDialog.tsx:95](../src/components/ItemInspectDialog.tsx#L95)
305. CC98 二手市场
   来源：[src/components/ItemInspectDialog.tsx:96](../src/components/ItemInspectDialog.tsx#L96)
306. 自动行走解决了会不会走；四个方向才能决定往哪里走。
   来源：[src/components/ItemInspectDialog.tsx:97](../src/components/ItemInspectDialog.tsx#L97)
307. 调查证据
   来源：[src/components/ItemInspectDialog.tsx:100](../src/components/ItemInspectDialog.tsx#L100)
308. 图书馆 022 座位旁
   来源：[src/components/ItemInspectDialog.tsx:101](../src/components/ItemInspectDialog.tsx#L101)
309. 纸上写了离开时长和占位理由。原句放进公开讨论区，更容易找到相同说法。
   来源：[src/components/ItemInspectDialog.tsx:102](../src/components/ItemInspectDialog.tsx#L102)
310. 检索线索
   来源：[src/components/ItemInspectDialog.tsx:105](../src/components/ItemInspectDialog.tsx#L105)
311. 浙大钉馆藏检索结果
   来源：[src/components/ItemInspectDialog.tsx:106](../src/components/ItemInspectDialog.tsx#L106)
312. 这串数字不回答问题，只标记位置。书架边缘会出现同样的编号。
   来源：[src/components/ItemInspectDialog.tsx:107](../src/components/ItemInspectDialog.tsx#L107)
313. 公开证据
   来源：[src/components/ItemInspectDialog.tsx:110](../src/components/ItemInspectDialog.tsx#L110)
314. 图书馆 755 书架夹层
   来源：[src/components/ItemInspectDialog.tsx:111](../src/components/ItemInspectDialog.tsx#L111)
315. 发布日期很旧，适用范围仍值得核对。公开讨论需要能查到出处的文字。
   来源：[src/components/ItemInspectDialog.tsx:112](../src/components/ItemInspectDialog.tsx#L112)
316. 机器报告
   来源：[src/components/ItemInspectDialog.tsx:115](../src/components/ItemInspectDialog.tsx#L115)
317. 照片识别结果
   来源：[src/components/ItemInspectDialog.tsx:116](../src/components/ItemInspectDialog.tsx#L116)
318. 它确认了画面里的物品，身份一栏仍为空。校园里有个地方专门补这一栏。
   来源：[src/components/ItemInspectDialog.tsx:117](../src/components/ItemInspectDialog.tsx#L117)
319. 认证证明
   来源：[src/components/ItemInspectDialog.tsx:120](../src/components/ItemInspectDialog.tsx#L120)
320. 物品身份盖章机
   来源：[src/components/ItemInspectDialog.tsx:121](../src/components/ItemInspectDialog.tsx#L121)
321. 一条错误等号已经被排除，座位归属仍未说明。单独提交会缺少另外两类材料。
   来源：[src/components/ItemInspectDialog.tsx:122](../src/components/ItemInspectDialog.tsx#L122)
322. 座位凭据
   来源：[src/components/ItemInspectDialog.tsx:125](../src/components/ItemInspectDialog.tsx#L125)
323. 022 桌面夹缝
   来源：[src/components/ItemInspectDialog.tsx:126](../src/components/ItemInspectDialog.tsx#L126)；[src/scenes/rpg/RpgItemUseGuidance.ts:156](../src/scenes/rpg/RpgItemUseGuidance.ts#L156)
324. 编号能对应座位，时间要与另一份到场记录互相核对。
   来源：[src/components/ItemInspectDialog.tsx:127](../src/components/ItemInspectDialog.tsx#L127)
325. 到场证明
   来源：[src/components/ItemInspectDialog.tsx:130](../src/components/ItemInspectDialog.tsx#L130)
326. 浙大体艺访问记录
   来源：[src/components/ItemInspectDialog.tsx:131](../src/components/ItemInspectDialog.tsx#L131)
327. 它只回答人是否到过那里，座位归属还要交给另一张凭据。
   来源：[src/components/ItemInspectDialog.tsx:132](../src/components/ItemInspectDialog.tsx#L132)
328. 执行凭证
   来源：[src/components/ItemInspectDialog.tsx:135](../src/components/ItemInspectDialog.tsx#L135)
329. 022 恢复申请签发
   来源：[src/components/ItemInspectDialog.tsx:136](../src/components/ItemInspectDialog.tsx#L136)
330. 三份材料已经换成临时处置权限，凭证对应基础馆二层南区 022。
   来源：[src/components/ItemInspectDialog.tsx:137](../src/components/ItemInspectDialog.tsx#L137)
331. 餐盘回收费 2.00 元
   来源：[src/components/ItemInspectDialog.tsx:140](../src/components/ItemInspectDialog.tsx#L140)；[src/components/PixelIcon.tsx:854](../src/components/PixelIcon.tsx#L854)；[src/data/items.config.json:151](../src/data/items.config.json#L151)
332. 餐盘回收
   来源：[src/components/ItemInspectDialog.tsx:141](../src/components/ItemInspectDialog.tsx#L141)
333. 收回三只目标餐盘得到的两元钱，可支付一次扫码骑车。
   来源：[src/components/ItemInspectDialog.tsx:142](../src/components/ItemInspectDialog.tsx#L142)；[src/components/PixelIcon.tsx:854](../src/components/PixelIcon.tsx#L854)；[src/data/items.config.json:152](../src/data/items.config.json#L152)
334. 油渍纸巾
   来源：[src/components/ItemInspectDialog.tsx:145](../src/components/ItemInspectDialog.tsx#L145)；[src/components/PixelIcon.tsx:855](../src/components/PixelIcon.tsx#L855)；[src/data/items.config.json:158](../src/data/items.config.json#L158)
335. 食堂桌面
   来源：[src/components/ItemInspectDialog.tsx:146](../src/components/ItemInspectDialog.tsx#L146)
336. 收餐口阿姨给的油渍纸巾，可擦掉车锁和海报玻璃上的反光。
   来源：[src/components/ItemInspectDialog.tsx:147](../src/components/ItemInspectDialog.tsx#L147)；[src/components/PixelIcon.tsx:855](../src/components/PixelIcon.tsx#L855)；[src/data/items.config.json:159](../src/data/items.config.json#L159)
337. 调配原料 · 蓝色
   来源：[src/components/ItemInspectDialog.tsx:150](../src/components/ItemInspectDialog.tsx#L150)
338. 食堂饮料区
   来源：[src/components/ItemInspectDialog.tsx:151](../src/components/ItemInspectDialog.tsx#L151)；[src/components/ItemInspectDialog.tsx:156](../src/components/ItemInspectDialog.tsx#L156)；[src/components/ItemInspectDialog.tsx:161](../src/components/ItemInspectDialog.tsx#L161)
339. 蓝色饮料原料。与黑咖啡、柠檬茶按货架顺序调配。
   来源：[src/components/ItemInspectDialog.tsx:152](../src/components/ItemInspectDialog.tsx#L152)；[src/components/PixelIcon.tsx:856](../src/components/PixelIcon.tsx#L856)；[src/data/items.config.json:166](../src/data/items.config.json#L166)
340. 调配原料 · 白色
   来源：[src/components/ItemInspectDialog.tsx:155](../src/components/ItemInspectDialog.tsx#L155)
341. 白色饮料原料。查看货架颜色顺序后放进混合台。
   来源：[src/components/ItemInspectDialog.tsx:157](../src/components/ItemInspectDialog.tsx#L157)；[src/components/PixelIcon.tsx:857](../src/components/PixelIcon.tsx#L857)；[src/data/items.config.json:173](../src/data/items.config.json#L173)
342. 调配原料 · 黑色
   来源：[src/components/ItemInspectDialog.tsx:160](../src/components/ItemInspectDialog.tsx#L160)
343. 黑色饮料原料。按货架顺序放进混合台。
   来源：[src/components/ItemInspectDialog.tsx:162](../src/components/ItemInspectDialog.tsx#L162)；[src/components/PixelIcon.tsx:858](../src/components/PixelIcon.tsx#L858)；[src/data/items.config.json:180](../src/data/items.config.json#L180)
344. 失败饮品
   来源：[src/components/ItemInspectDialog.tsx:165](../src/components/ItemInspectDialog.tsx#L165)
345. 食堂混合台
   来源：[src/components/ItemInspectDialog.tsx:166](../src/components/ItemInspectDialog.tsx#L166)；[src/components/ItemInspectDialog.tsx:172](../src/components/ItemInspectDialog.tsx#L172)
346. 混错顺序得到的饮料。可以喝掉，不能推进任务。
   来源：[src/components/ItemInspectDialog.tsx:167](../src/components/ItemInspectDialog.tsx#L167)；[src/components/PixelIcon.tsx:859](../src/components/PixelIcon.tsx#L859)；[src/data/items.config.json:187](../src/data/items.config.json#L187)
347. 在食堂 RPG 中拖到自己身上可以喝掉。
   来源：[src/components/ItemInspectDialog.tsx:168](../src/components/ItemInspectDialog.tsx#L168)
348. 今日新品
   来源：[src/components/ItemInspectDialog.tsx:171](../src/components/ItemInspectDialog.tsx#L171)
349. 拖到第三窗口宣传板的空杯位。守出口时可在地面留两秒减速气泡。
   来源：[src/components/ItemInspectDialog.tsx:173](../src/components/ItemInspectDialog.tsx#L173)；[src/components/PixelIcon.tsx:860](../src/components/PixelIcon.tsx#L860)；[src/data/items.config.json:194](../src/data/items.config.json#L194)
350. 先拖到第三个餐口宣传板空杯位；守出口时可再拖进食堂地面减速纸条。
   来源：[src/components/ItemInspectDialog.tsx:174](../src/components/ItemInspectDialog.tsx#L174)
351. 0755 取餐号
   来源：[src/components/ItemInspectDialog.tsx:177](../src/components/ItemInspectDialog.tsx#L177)；[src/components/PixelIcon.tsx:861](../src/components/PixelIcon.tsx#L861)；[src/data/itemCatalog.ts:138](../src/data/itemCatalog.ts#L138)；[src/data/items.config.json:200](../src/data/items.config.json#L200)
352. 点餐机
   来源：[src/components/ItemInspectDialog.tsx:178](../src/components/ItemInspectDialog.tsx#L178)
353. 点餐机打印的取餐小票。切到深色模式，交给 3 号窗口残影阿姨。
   来源：[src/components/ItemInspectDialog.tsx:179](../src/components/ItemInspectDialog.tsx#L179)；[src/components/PixelIcon.tsx:861](../src/components/PixelIcon.tsx#L861)；[src/data/items.config.json:201](../src/data/items.config.json#L201)
354. 1号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)
355. 从窗口领到的包子。正常，且没有纸条线索。
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)；[src/components/PixelIcon.tsx:862](../src/components/PixelIcon.tsx#L862)；[src/data/items.config.json:208](../src/data/items.config.json#L208)
356. 食堂彩蛋
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)；[src/components/ItemInspectDialog.tsx:182](../src/components/ItemInspectDialog.tsx#L182)；[src/components/ItemInspectDialog.tsx:183](../src/components/ItemInspectDialog.tsx#L183)；[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)
357. 2号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:182](../src/components/ItemInspectDialog.tsx#L182)
358. 从窗口领到的豆浆。此时没有其他用途。
   来源：[src/components/ItemInspectDialog.tsx:182](../src/components/ItemInspectDialog.tsx#L182)；[src/components/PixelIcon.tsx:863](../src/components/PixelIcon.tsx#L863)；[src/data/items.config.json:215](../src/data/items.config.json#L215)
359. 4号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:183](../src/components/ItemInspectDialog.tsx#L183)
360. 从窗口领到的鸡蛋。此时没有其他用途。
   来源：[src/components/ItemInspectDialog.tsx:183](../src/components/ItemInspectDialog.tsx#L183)；[src/components/PixelIcon.tsx:864](../src/components/PixelIcon.tsx#L864)；[src/data/items.config.json:222](../src/data/items.config.json#L222)
361. 5号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)
362. 从窗口领到的白粥。烫手，且没有其他用途。
   来源：[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)；[src/components/PixelIcon.tsx:865](../src/components/PixelIcon.tsx#L865)；[src/data/items.config.json:229](../src/data/items.config.json#L229)
363. 半张剧院票根 A
   来源：[src/components/ItemInspectDialog.tsx:186](../src/components/ItemInspectDialog.tsx#L186)；[src/components/PixelIcon.tsx:866](../src/components/PixelIcon.tsx#L866)；[src/data/items.config.json:235](../src/data/items.config.json#L235)
364. 剧院海报栏
   来源：[src/components/ItemInspectDialog.tsx:187](../src/components/ItemInspectDialog.tsx#L187)
365. 它证明你的一半可以进场，另一半还在流程里。
   来源：[src/components/ItemInspectDialog.tsx:188](../src/components/ItemInspectDialog.tsx#L188)；[src/components/PixelIcon.tsx:866](../src/components/PixelIcon.tsx#L866)；[src/data/items.config.json:236](../src/data/items.config.json#L236)
366. 半张剧院票根 B
   来源：[src/components/ItemInspectDialog.tsx:191](../src/components/ItemInspectDialog.tsx#L191)；[src/components/PixelIcon.tsx:867](../src/components/PixelIcon.tsx#L867)；[src/data/items.config.json:242](../src/data/items.config.json#L242)
367. 剧院取票机
   来源：[src/components/ItemInspectDialog.tsx:192](../src/components/ItemInspectDialog.tsx#L192)
368. 来自一台失败的取票机。它至少努力过。
   来源：[src/components/ItemInspectDialog.tsx:193](../src/components/ItemInspectDialog.tsx#L193)；[src/components/PixelIcon.tsx:867](../src/components/PixelIcon.tsx#L867)；[src/data/items.config.json:243](../src/data/items.config.json#L243)
369. 临时观演票
   来源：[src/components/ItemInspectDialog.tsx:196](../src/components/ItemInspectDialog.tsx#L196)；[src/components/PixelIcon.tsx:868](../src/components/PixelIcon.tsx#L868)；[src/data/items.config.json:249](../src/data/items.config.json#L249)；[src/modules/InventoryController.ts:16](../src/modules/InventoryController.ts#L16)
370. 两张半票根
   来源：[src/components/ItemInspectDialog.tsx:197](../src/components/ItemInspectDialog.tsx#L197)
371. 两张半真半假的票根拼出来的票。剧院看了都沉默了一秒。
   来源：[src/components/ItemInspectDialog.tsx:198](../src/components/ItemInspectDialog.tsx#L198)；[src/components/PixelIcon.tsx:868](../src/components/PixelIcon.tsx#L868)；[src/data/items.config.json:250](../src/data/items.config.json#L250)
372. 节目单残页
   来源：[src/components/ItemInspectDialog.tsx:201](../src/components/ItemInspectDialog.tsx#L201)；[src/components/ItemInspectDialog.tsx:206](../src/components/ItemInspectDialog.tsx#L206)；[src/components/ItemInspectDialog.tsx:211](../src/components/ItemInspectDialog.tsx#L211)
373. 剧院座席
   来源：[src/components/ItemInspectDialog.tsx:202](../src/components/ItemInspectDialog.tsx#L202)；[src/components/ItemInspectDialog.tsx:207](../src/components/ItemInspectDialog.tsx#L207)；[src/components/ItemInspectDialog.tsx:212](../src/components/ItemInspectDialog.tsx#L212)
374. 普通节目单，看起来很会假装正式。
   来源：[src/components/ItemInspectDialog.tsx:203](../src/components/ItemInspectDialog.tsx#L203)；[src/components/ItemInspectDialog.tsx:208](../src/components/ItemInspectDialog.tsx#L208)；[src/components/ItemInspectDialog.tsx:213](../src/components/ItemInspectDialog.tsx#L213)；[src/components/PixelIcon.tsx:869](../src/components/PixelIcon.tsx#L869)；[src/components/PixelIcon.tsx:870](../src/components/PixelIcon.tsx#L870)；[src/components/PixelIcon.tsx:871](../src/components/PixelIcon.tsx#L871)；[src/data/items.config.json:257](../src/data/items.config.json#L257)；[src/data/items.config.json:264](../src/data/items.config.json#L264)；[src/data/items.config.json:271](../src/data/items.config.json#L271)
375. 追光灯遥控器
   来源：[src/components/ItemInspectDialog.tsx:216](../src/components/ItemInspectDialog.tsx#L216)；[src/components/PixelIcon.tsx:872](../src/components/PixelIcon.tsx#L872)；[src/data/items.config.json:277](../src/data/items.config.json#L277)
376. 剧院灯控台
   来源：[src/components/ItemInspectDialog.tsx:217](../src/components/ItemInspectDialog.tsx#L217)
377. 能让舞台中央变亮。也能让逃避责任的纸条短暂接受审判。
   来源：[src/components/ItemInspectDialog.tsx:218](../src/components/ItemInspectDialog.tsx#L218)；[src/components/PixelIcon.tsx:872](../src/components/PixelIcon.tsx#L872)；[src/data/items.config.json:278](../src/data/items.config.json#L278)
378. 荧光粉刷
   来源：[src/components/ItemInspectDialog.tsx:221](../src/components/ItemInspectDialog.tsx#L221)；[src/components/PixelIcon.tsx:873](../src/components/PixelIcon.tsx#L873)；[src/data/items.config.json:284](../src/data/items.config.json#L284)
379. 后台道具箱
   来源：[src/components/ItemInspectDialog.tsx:222](../src/components/ItemInspectDialog.tsx#L222)
380. 刷过之后，连借口都会发光。
   来源：[src/components/ItemInspectDialog.tsx:223](../src/components/ItemInspectDialog.tsx#L223)；[src/components/PixelIcon.tsx:873](../src/components/PixelIcon.tsx#L873)；[src/data/items.config.json:285](../src/data/items.config.json#L285)
381. 假纸条
   来源：[src/components/ItemInspectDialog.tsx:226](../src/components/ItemInspectDialog.tsx#L226)；[src/components/PixelIcon.tsx:874](../src/components/PixelIcon.tsx#L874)；[src/data/items.config.json:291](../src/data/items.config.json#L291)
382. 剧院追光灯下
   来源：[src/components/ItemInspectDialog.tsx:227](../src/components/ItemInspectDialog.tsx#L227)
383. 长得很像目标，但态度没那么差。
   来源：[src/components/ItemInspectDialog.tsx:228](../src/components/ItemInspectDialog.tsx#L228)；[src/components/PixelIcon.tsx:874](../src/components/PixelIcon.tsx#L874)；[src/data/items.config.json:292](../src/data/items.config.json#L292)
384. 可安装到钓竿上作为诱饵，装饵成功后会消耗
   来源：[src/components/ItemInspectDialog.tsx:229](../src/components/ItemInspectDialog.tsx#L229)
385. 湿掉的节目单
   来源：[src/components/ItemInspectDialog.tsx:232](../src/components/ItemInspectDialog.tsx#L232)；[src/components/PixelIcon.tsx:875](../src/components/PixelIcon.tsx#L875)；[src/data/itemCatalog.ts:163](../src/data/itemCatalog.ts#L163)；[src/data/items.config.json:298](../src/data/items.config.json#L298)
386. 剧院舞台
   来源：[src/components/ItemInspectDialog.tsx:233](../src/components/ItemInspectDialog.tsx#L233)；[src/data/itemCatalog.ts:166](../src/data/itemCatalog.ts#L166)
387. 纸条逃跑时留下的节目单，边角湿得很有方向感。
   来源：[src/components/ItemInspectDialog.tsx:234](../src/components/ItemInspectDialog.tsx#L234)；[src/components/PixelIcon.tsx:875](../src/components/PixelIcon.tsx#L875)；[src/data/items.config.json:299](../src/data/items.config.json#L299)
388. 地点关键词
   来源：[src/components/ItemInspectDialog.tsx:237](../src/components/ItemInspectDialog.tsx#L237)；[src/components/ItemInspectDialog.tsx:242](../src/components/ItemInspectDialog.tsx#L242)；[src/components/ItemInspectDialog.tsx:247](../src/components/ItemInspectDialog.tsx#L247)
389. CC98 目击回复
   来源：[src/components/ItemInspectDialog.tsx:238](../src/components/ItemInspectDialog.tsx#L238)
390. 目击者只确认了桥附近，仍不足以确定具体地点。
   来源：[src/components/ItemInspectDialog.tsx:239](../src/components/ItemInspectDialog.tsx#L239)
391. 图书馆馆藏状态
   来源：[src/components/ItemInspectDialog.tsx:243](../src/components/ItemInspectDialog.tsx#L243)
392. 异常页码只出现在水面反射区域。
   来源：[src/components/ItemInspectDialog.tsx:244](../src/components/ItemInspectDialog.tsx#L244)
393. 微信朋友消息
   来源：[src/components/ItemInspectDialog.tsx:248](../src/components/ItemInspectDialog.tsx#L248)
394. 群聊只留下了一个不完整的湖名。
   来源：[src/components/ItemInspectDialog.tsx:249](../src/components/ItemInspectDialog.tsx#L249)
395. 场景坐标
   来源：[src/components/ItemInspectDialog.tsx:252](../src/components/ItemInspectDialog.tsx#L252)
396. 启真湖指示牌
   来源：[src/components/ItemInspectDialog.tsx:253](../src/components/ItemInspectDialog.tsx#L253)
397. 深浅两种观察结果共同指向右侧路灯杆。
   来源：[src/components/ItemInspectDialog.tsx:254](../src/components/ItemInspectDialog.tsx#L254)
398. 寝室电器
   来源：[src/components/ItemInspectDialog.tsx:257](../src/components/ItemInspectDialog.tsx#L257)
399. 个人书桌
   来源：[src/components/ItemInspectDialog.tsx:258](../src/components/ItemInspectDialog.tsx#L258)
400. 吹风机的风量调节仍然可用。
   来源：[src/components/ItemInspectDialog.tsx:259](../src/components/ItemInspectDialog.tsx#L259)
401. 进入天气页面后，用它推动低、中、高三层云带
   来源：[src/components/ItemInspectDialog.tsx:260](../src/components/ItemInspectDialog.tsx#L260)
402. 湖面工具
   来源：[src/components/ItemInspectDialog.tsx:263](../src/components/ItemInspectDialog.tsx#L263)
403. 启真湖码头装备架
   来源：[src/components/ItemInspectDialog.tsx:264](../src/components/ItemInspectDialog.tsx#L264)
404. 竿梢保留了附件连接位。深色观察可记录目标，浅色操作可在正确水纹抛竿。
   来源：[src/components/ItemInspectDialog.tsx:265](../src/components/ItemInspectDialog.tsx#L265)
405. 可安装诱饵、钓取水面物品，或与磁铁组合
   来源：[src/components/ItemInspectDialog.tsx:266](../src/components/ItemInspectDialog.tsx#L266)
406. 启真湖开放水域钓点
   来源：[src/components/ItemInspectDialog.tsx:270](../src/components/ItemInspectDialog.tsx#L270)；[src/components/ItemInspectDialog.tsx:282](../src/components/ItemInspectDialog.tsx#L282)
407. 钥匙表面的锈蚀和码头储物柜锁孔一致。
   来源：[src/components/ItemInspectDialog.tsx:271](../src/components/ItemInspectDialog.tsx#L271)
408. 靠近码头储物柜后拖入锁孔
   来源：[src/components/ItemInspectDialog.tsx:272](../src/components/ItemInspectDialog.tsx#L272)
409. 修复材料
   来源：[src/components/ItemInspectDialog.tsx:275](../src/components/ItemInspectDialog.tsx#L275)；[src/components/ItemInspectDialog.tsx:281](../src/components/ItemInspectDialog.tsx#L281)
410. 启真湖码头储物柜
   来源：[src/components/ItemInspectDialog.tsx:276](../src/components/ItemInspectDialog.tsx#L276)
411. 耐水绳结仍然完整，长度适合重新固定一圈网框。
   来源：[src/components/ItemInspectDialog.tsx:277](../src/components/ItemInspectDialog.tsx#L277)
412. 与缺少网面的框架组合
   来源：[src/components/ItemInspectDialog.tsx:278](../src/components/ItemInspectDialog.tsx#L278)
413. 框架仍可承重，固定网面的绳索已经脱落。
   来源：[src/components/ItemInspectDialog.tsx:283](../src/components/ItemInspectDialog.tsx#L283)
414. 与耐水绳索组合
   来源：[src/components/ItemInspectDialog.tsx:284](../src/components/ItemInspectDialog.tsx#L284)
415. 打捞工具
   来源：[src/components/ItemInspectDialog.tsx:287](../src/components/ItemInspectDialog.tsx#L287)
416. 尼龙绳 + 断裂网框
   来源：[src/components/ItemInspectDialog.tsx:288](../src/components/ItemInspectDialog.tsx#L288)
417. 网框已经恢复封闭，可承托钓钩难以稳定带回的物品。
   来源：[src/components/ItemInspectDialog.tsx:289](../src/components/ItemInspectDialog.tsx#L289)
418. 在浅色操作中拖向已观察的水下罐体
   来源：[src/components/ItemInspectDialog.tsx:290](../src/components/ItemInspectDialog.tsx#L290)
419. 密封容器
   来源：[src/components/ItemInspectDialog.tsx:293](../src/components/ItemInspectDialog.tsx#L293)
420. 启真湖水下打捞点
   来源：[src/components/ItemInspectDialog.tsx:294](../src/components/ItemInspectDialog.tsx#L294)
421. 罐盖仍然密封，摇动时能听到细小颗粒碰撞。
   来源：[src/components/ItemInspectDialog.tsx:295](../src/components/ItemInspectDialog.tsx#L295)
422. 返回安全位置后打开罐盖
   来源：[src/components/ItemInspectDialog.tsx:296](../src/components/ItemInspectDialog.tsx#L296)
423. 投喂材料
   来源：[src/components/ItemInspectDialog.tsx:299](../src/components/ItemInspectDialog.tsx#L299)
424. 密封饲料罐
   来源：[src/components/ItemInspectDialog.tsx:300](../src/components/ItemInspectDialog.tsx#L300)；[src/components/PixelIcon.tsx:886](../src/components/PixelIcon.tsx#L886)；[src/data/items.config.json:375](../src/data/items.config.json#L375)
425. 颗粒遇水后会缓慢下沉，可让鱼群在短时间内集中。
   来源：[src/components/ItemInspectDialog.tsx:301](../src/components/ItemInspectDialog.tsx#L301)
426. 在已观察的鱼群位置使用
   来源：[src/components/ItemInspectDialog.tsx:302](../src/components/ItemInspectDialog.tsx#L302)
427. 活体诱导物
   来源：[src/components/ItemInspectDialog.tsx:305](../src/components/ItemInspectDialog.tsx#L305)
428. 启真湖鱼群钓点
   来源：[src/components/ItemInspectDialog.tsx:306](../src/components/ItemInspectDialog.tsx#L306)
429. 小鲤鱼仍有活性，需要尽快完成当前湖区操作。
   来源：[src/components/ItemInspectDialog.tsx:307](../src/components/ItemInspectDialog.tsx#L307)
430. 靠近黑天鹅后进行投喂
   来源：[src/components/ItemInspectDialog.tsx:308](../src/components/ItemInspectDialog.tsx#L308)
431. 磁吸附件
   来源：[src/components/ItemInspectDialog.tsx:311](../src/components/ItemInspectDialog.tsx#L311)
432. 启真湖黑天鹅
   来源：[src/components/ItemInspectDialog.tsx:312](../src/components/ItemInspectDialog.tsx#L312)
433. 小型磁铁的固定环与钓竿末端尺寸一致。
   来源：[src/components/ItemInspectDialog.tsx:313](../src/components/ItemInspectDialog.tsx#L313)
434. 与基础钓竿组合
   来源：[src/components/ItemInspectDialog.tsx:314](../src/components/ItemInspectDialog.tsx#L314)
435. 组合工具
   来源：[src/components/ItemInspectDialog.tsx:317](../src/components/ItemInspectDialog.tsx#L317)
436. 钓竿 + 天鹅磁铁
   来源：[src/components/ItemInspectDialog.tsx:318](../src/components/ItemInspectDialog.tsx#L318)
437. 磁吸附件可接近金属夹具，同时保留钓竿的距离优势。
   来源：[src/components/ItemInspectDialog.tsx:319](../src/components/ItemInspectDialog.tsx#L319)
438. 用于捕获被夹住的纸张；返航完成后附件会损坏
   来源：[src/components/ItemInspectDialog.tsx:320](../src/components/ItemInspectDialog.tsx#L320)
439. 签到材料
   来源：[src/components/ItemInspectDialog.tsx:323](../src/components/ItemInspectDialog.tsx#L323)
440. 教学楼公告栏前
   来源：[src/components/ItemInspectDialog.tsx:324](../src/components/ItemInspectDialog.tsx#L324)
441. 这张纸先把你引回了楼里，最后也得由你把它送回签到口。
   来源：[src/components/ItemInspectDialog.tsx:325](../src/components/ItemInspectDialog.tsx#L325)
442. 晨间签到阶段拖向签到纸槽
   来源：[src/components/ItemInspectDialog.tsx:326](../src/components/ItemInspectDialog.tsx#L326)
443. 钟表部件
   来源：[src/components/ItemInspectDialog.tsx:329](../src/components/ItemInspectDialog.tsx#L329)；[src/components/ItemInspectDialog.tsx:335](../src/components/ItemInspectDialog.tsx#L335)
444. 面包店传送带边缘
   来源：[src/components/ItemInspectDialog.tsx:330](../src/components/ItemInspectDialog.tsx#L330)
445. 真正能推进时间的不是灯光，而是停带后露出来的这根旧钟时针。
   来源：[src/components/ItemInspectDialog.tsx:331](../src/components/ItemInspectDialog.tsx#L331)
446. 返回一楼旧钟，将它拖向时针插槽
   来源：[src/components/ItemInspectDialog.tsx:332](../src/components/ItemInspectDialog.tsx#L332)
447. 204 讲台抽屉
   来源：[src/components/ItemInspectDialog.tsx:336](../src/components/ItemInspectDialog.tsx#L336)
448. 它不是普通零件，而是让旧钟重新对准正确结构的定位盘。
   来源：[src/components/ItemInspectDialog.tsx:337](../src/components/ItemInspectDialog.tsx#L337)
449. 返回一楼旧钟，将它拖向定位盘插槽
   来源：[src/components/ItemInspectDialog.tsx:338](../src/components/ItemInspectDialog.tsx#L338)
450. 维修工具
   来源：[src/components/ItemInspectDialog.tsx:341](../src/components/ItemInspectDialog.tsx#L341)
451. 面包店后场
   来源：[src/components/ItemInspectDialog.tsx:342](../src/components/ItemInspectDialog.tsx#L342)
452. 长度不大，刚好适合翘开清洁车轮罩。
   来源：[src/components/ItemInspectDialog.tsx:343](../src/components/ItemInspectDialog.tsx#L343)
453. 拖向清洁车轮罩
   来源：[src/components/ItemInspectDialog.tsx:344](../src/components/ItemInspectDialog.tsx#L344)
454. 维修材料
   来源：[src/components/ItemInspectDialog.tsx:347](../src/components/ItemInspectDialog.tsx#L347)
455. 清洁车内侧
   来源：[src/components/ItemInspectDialog.tsx:348](../src/components/ItemInspectDialog.tsx#L348)
456. 先用它让清洁车恢复，再把剩下的半瓶交给旧钟齿轮。
   来源：[src/components/ItemInspectDialog.tsx:349](../src/components/ItemInspectDialog.tsx#L349)
457. 先拖向清洁车轮，再拖向旧钟齿轮
   来源：[src/components/ItemInspectDialog.tsx:350](../src/components/ItemInspectDialog.tsx#L350)
458. 时间碎片
   来源：[src/components/ItemInspectDialog.tsx:353](../src/components/ItemInspectDialog.tsx#L353)
459. 202 阶梯教室投影
   来源：[src/components/ItemInspectDialog.tsx:354](../src/components/ItemInspectDialog.tsx#L354)
460. 这是一段被偷走的最后一分钟。它只能回到旧钟分针端点。
   来源：[src/components/ItemInspectDialog.tsx:355](../src/components/ItemInspectDialog.tsx#L355)
461. 拖向旧钟分针端点，恢复 07:55
   来源：[src/components/ItemInspectDialog.tsx:356](../src/components/ItemInspectDialog.tsx#L356)
462. 关闭{{item.name}}详情
   来源：[src/components/ItemInspectDialog.tsx:458](../src/components/ItemInspectDialog.tsx#L458)
463. 分类
   来源：[src/components/ItemInspectDialog.tsx:473](../src/components/ItemInspectDialog.tsx#L473)；[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
464. 来源
   来源：[src/components/ItemInspectDialog.tsx:477](../src/components/ItemInspectDialog.tsx#L477)；[src/data/itemCatalog.ts:166](../src/data/itemCatalog.ts#L166)
465. 持卡人
   来源：[src/components/ItemInspectDialog.tsx:482](../src/components/ItemInspectDialog.tsx#L482)
466. 简介
   来源：[src/components/ItemInspectDialog.tsx:487](../src/components/ItemInspectDialog.tsx#L487)
467. 顺序：
   来源：[src/components/ItemInspectDialog.tsx:491](../src/components/ItemInspectDialog.tsx#L491)
468. 用途提示
   来源：[src/components/ItemInspectDialog.tsx:497](../src/components/ItemInspectDialog.tsx#L497)
469. {{item.name}}正文
   来源：[src/components/ItemInspectDialog.tsx:504](../src/components/ItemInspectDialog.tsx#L504)
470. 应用导航
   来源：[src/components/PhoneAppUi.tsx:109](../src/components/PhoneAppUi.tsx#L109)
471. QUICK PANEL
   来源：[src/components/PhoneAppUi.tsx:232](../src/components/PhoneAppUi.tsx#L232)
472. 关闭{{title}}
   来源：[src/components/PhoneAppUi.tsx:235](../src/components/PhoneAppUi.tsx#L235)
473. phone-app-feedback is-{{tone}} {{className}}
   来源：[src/components/PhoneAppUi.tsx:252](../src/components/PhoneAppUi.tsx#L252)
474. 7:55 scaled phone viewport
   来源：[src/components/PhoneShell.tsx:145](../src/components/PhoneShell.tsx#L145)
475. 7:55 phone runtime
   来源：[src/components/PhoneShell.tsx:147](../src/components/PhoneShell.tsx#L147)
476. 从早八雨里接住的一滴水。它看起来很普通，但已经比你更早起床。
   来源：[src/components/PixelIcon.tsx:830](../src/components/PixelIcon.tsx#L830)；[src/data/items.config.json:5](../src/data/items.config.json#L5)
477. 水滴
   来源：[src/components/PixelIcon.tsx:830](../src/components/PixelIcon.tsx#L830)；[src/data/items.config.json:4](../src/data/items.config.json#L4)
478. 从控制中心掉下来的耳机。背面朝下，像一个不太情愿的小水瓢。
   来源：[src/components/PixelIcon.tsx:831](../src/components/PixelIcon.tsx#L831)；[src/data/items.config.json:12](../src/data/items.config.json#L12)
479. 盛水的耳机
   来源：[src/components/PixelIcon.tsx:832](../src/components/PixelIcon.tsx#L832)；[src/data/items.config.json:18](../src/data/items.config.json#L18)；[src/modules/InventoryController.ts:14](../src/modules/InventoryController.ts#L14)
480. 一只装了水的耳机。音质未知，灌溉能力暂时领先。
   来源：[src/components/PixelIcon.tsx:832](../src/components/PixelIcon.tsx#L832)
481. 从设置里掉下来的齿轮。背面刻着 9，说明它一直有背着你生活。
   来源：[src/components/PixelIcon.tsx:833](../src/components/PixelIcon.tsx#L833)；[src/data/items.config.json:26](../src/data/items.config.json#L26)
482. 反转齿轮
   来源：[src/components/PixelIcon.tsx:833](../src/components/PixelIcon.tsx#L833)；[src/data/items.config.json:25](../src/data/items.config.json#L25)
483. 朋友头像上掉下来的一撇。检测到未经授权的友情支援。
   来源：[src/components/PixelIcon.tsx:834](../src/components/PixelIcon.tsx#L834)；[src/data/items.config.json:33](../src/data/items.config.json#L33)
484. 斜线
   来源：[src/components/PixelIcon.tsx:834](../src/components/PixelIcon.tsx#L834)；[src/data/items.config.json:32](../src/data/items.config.json#L32)
485. 斜线和齿轮拼成的钥匙。合法性很低，开锁欲很强。
   来源：[src/components/PixelIcon.tsx:835](../src/components/PixelIcon.tsx#L835)；[src/data/items.config.json:40](../src/data/items.config.json#L40)
486. 钥匙
   来源：[src/components/PixelIcon.tsx:835](../src/components/PixelIcon.tsx#L835)；[src/data/items.config.json:39](../src/data/items.config.json#L39)；[src/modules/InventoryController.ts:13](../src/modules/InventoryController.ts#L13)
487. 一袋肥料
   来源：[src/components/PixelIcon.tsx:836](../src/components/PixelIcon.tsx#L836)；[src/data/items.config.json:46](../src/data/items.config.json#L46)
488. 钟楼里掉出来的肥料。不要问钟楼为什么会长出农业属性。
   来源：[src/components/PixelIcon.tsx:836](../src/components/PixelIcon.tsx#L836)；[src/data/items.config.json:47](../src/data/items.config.json#L47)
489. 电子校园卡
   来源：[src/components/PixelIcon.tsx:838](../src/components/PixelIcon.tsx#L838)；[src/scenes/phone/P15_Zjuding/index.tsx:2002](../src/scenes/phone/P15_Zjuding/index.tsx#L2002)；[src/scenes/phone/P15_Zjuding/index.tsx:2004](../src/scenes/phone/P15_Zjuding/index.tsx#L2004)；[src/scenes/phone/P15_Zjuding/index.tsx:2005](../src/scenes/phone/P15_Zjuding/index.tsx#L2005)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
490. 证明你是你的卡。余额方面，它持保留意见。
   来源：[src/components/PixelIcon.tsx:839](../src/components/PixelIcon.tsx#L839)；[src/data/items.config.json:54](../src/data/items.config.json#L54)
491. 从主页推送头像里抠下来的三角形。它还没想好自己是播放键还是箭头的一部分。
   来源：[src/components/PixelIcon.tsx:841](../src/components/PixelIcon.tsx#L841)；[src/data/items.config.json:61](../src/data/items.config.json#L61)
492. 三角形
   来源：[src/components/PixelIcon.tsx:841](../src/components/PixelIcon.tsx#L841)；[src/data/items.config.json:60](../src/data/items.config.json#L60)
493. 从天气页面接到的一滴水。天气预报终于做了一件可以直接拿来用的事。
   来源：[src/components/PixelIcon.tsx:842](../src/components/PixelIcon.tsx#L842)；[src/data/items.config.json:68](../src/data/items.config.json#L68)
494. 天气水滴
   来源：[src/components/PixelIcon.tsx:842](../src/components/PixelIcon.tsx#L842)；[src/data/items.config.json:67](../src/data/items.config.json#L67)
495. 从导师头像上滑落的一条竖线。它看起来很严肃，像一句还没发完的消息。
   来源：[src/components/PixelIcon.tsx:843](../src/components/PixelIcon.tsx#L843)；[src/data/items.config.json:75](../src/data/items.config.json#L75)
496. 竖线
   来源：[src/components/PixelIcon.tsx:843](../src/components/PixelIcon.tsx#L843)；[src/data/items.config.json:74](../src/data/items.config.json#L74)
497. 能把什么东西往右移。它不解决问题，只负责让问题换个位置。
   来源：[src/components/PixelIcon.tsx:844](../src/components/PixelIcon.tsx#L844)；[src/data/items.config.json:82](../src/data/items.config.json#L82)
498. 右移箭头
   来源：[src/components/PixelIcon.tsx:844](../src/components/PixelIcon.tsx#L844)；[src/modules/InventoryController.ts:15](../src/modules/InventoryController.ts#L15)
499. 游戏手柄
   来源：[src/components/PixelIcon.tsx:845](../src/components/PixelIcon.tsx#L845)；[src/data/items.config.json:88](../src/data/items.config.json#L88)
500. CC98 二手市场六块钱成交。它让你终于可以操作自己，听起来很悲伤。
   来源：[src/components/PixelIcon.tsx:845](../src/components/PixelIcon.tsx#L845)；[src/data/items.config.json:89](../src/data/items.config.json#L89)
501. 022 座位旁的纸条，写着“主人马上回来”。拖到 CC98 搜索栏查找同类记录。
   来源：[src/components/PixelIcon.tsx:846](../src/components/PixelIcon.tsx#L846)；[src/data/items.config.json:96](../src/data/items.config.json#L96)
502. 占座纸条
   来源：[src/components/PixelIcon.tsx:846](../src/components/PixelIcon.tsx#L846)；[src/data/items.config.json:95](../src/data/items.config.json#L95)
503. 书架定位编号。拖到 755 号书架，查找旧版离座规则。
   来源：[src/components/PixelIcon.tsx:847](../src/components/PixelIcon.tsx#L847)；[src/data/items.config.json:103](../src/data/items.config.json#L103)
504. 索书号 755
   来源：[src/components/PixelIcon.tsx:847](../src/components/PixelIcon.tsx#L847)；[src/data/items.config.json:102](../src/data/items.config.json#L102)
505. 旧离座规定
   来源：[src/components/PixelIcon.tsx:848](../src/components/PixelIcon.tsx#L848)
506. 书架背面找到的旧版离座规定。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:848](../src/components/PixelIcon.tsx#L848)；[src/data/items.config.json:110](../src/data/items.config.json#L110)
507. 物品识别报告
   来源：[src/components/PixelIcon.tsx:849](../src/components/PixelIcon.tsx#L849)；[src/data/itemCatalog.ts:65](../src/data/itemCatalog.ts#L65)；[src/data/items.config.json:116](../src/data/items.config.json#L116)
508. 照片调暗后生成的书包识别报告。带到图书馆前台核验盖章。
   来源：[src/components/PixelIcon.tsx:849](../src/components/PixelIcon.tsx#L849)；[src/data/items.config.json:117](../src/data/items.config.json#L117)
509. 前台盖章后的书包非本人证明。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:850](../src/components/PixelIcon.tsx#L850)；[src/data/items.config.json:124](../src/data/items.config.json#L124)
510. 书包非本人证明
   来源：[src/components/PixelIcon.tsx:850](../src/components/PixelIcon.tsx#L850)；[src/data/itemCatalog.ts:76](../src/data/itemCatalog.ts#L76)；[src/data/items.config.json:123](../src/data/items.config.json#L123)；[src/data/presentation-cues.ts:142](../src/data/presentation-cues.ts#L142)；[src/scenes/phone/P15_Zjuding/index.tsx:195](../src/scenes/phone/P15_Zjuding/index.tsx#L195)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:105](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L105)
511. 022 座位小票
   来源：[src/components/PixelIcon.tsx:851](../src/components/PixelIcon.tsx#L851)；[src/data/items.config.json:130](../src/data/items.config.json#L130)；[src/data/presentation-cues.ts:151](../src/data/presentation-cues.ts#L151)；[src/scenes/phone/P15_Zjuding/index.tsx:201](../src/scenes/phone/P15_Zjuding/index.tsx#L201)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:106](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L106)
512. 从 022 桌下夹缝取到的小票。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:851](../src/components/PixelIcon.tsx#L851)；[src/data/items.config.json:131](../src/data/items.config.json#L131)
513. 本人来过证明
   来源：[src/components/PixelIcon.tsx:852](../src/components/PixelIcon.tsx#L852)；[src/data/itemCatalog.ts:104](../src/data/itemCatalog.ts#L104)；[src/data/items.config.json:137](../src/data/items.config.json#L137)；[src/data/presentation-cues.ts:160](../src/data/presentation-cues.ts#L160)；[src/scenes/phone/P15_Zjuding/index.tsx:207](../src/scenes/phone/P15_Zjuding/index.tsx#L207)
514. 体艺补录得到的到馆证明。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:852](../src/components/PixelIcon.tsx#L852)；[src/data/items.config.json:138](../src/data/items.config.json#L138)
515. 离座清退 PASS
   来源：[src/components/PixelIcon.tsx:853](../src/components/PixelIcon.tsx#L853)；[src/data/itemCatalog.ts:118](../src/data/itemCatalog.ts#L118)
516. 三项材料换来的清退凭证。拖到 022 书包使用。
   来源：[src/components/PixelIcon.tsx:853](../src/components/PixelIcon.tsx#L853)；[src/data/items.config.json:145](../src/data/items.config.json#L145)
517. 气泡水
   来源：[src/components/PixelIcon.tsx:856](../src/components/PixelIcon.tsx#L856)；[src/data/items.config.json:165](../src/data/items.config.json#L165)
518. 柠檬茶
   来源：[src/components/PixelIcon.tsx:857](../src/components/PixelIcon.tsx#L857)；[src/data/items.config.json:172](../src/data/items.config.json#L172)
519. 黑咖啡
   来源：[src/components/PixelIcon.tsx:858](../src/components/PixelIcon.tsx#L858)；[src/data/items.config.json:179](../src/data/items.config.json#L179)
520. 难喝饮料
   来源：[src/components/PixelIcon.tsx:859](../src/components/PixelIcon.tsx#L859)；[src/data/items.config.json:186](../src/data/items.config.json#L186)
521. 今日新品气泡水
   来源：[src/components/PixelIcon.tsx:860](../src/components/PixelIcon.tsx#L860)；[src/data/items.config.json:193](../src/data/items.config.json#L193)
522. 比较真实的包子
   来源：[src/components/PixelIcon.tsx:862](../src/components/PixelIcon.tsx#L862)；[src/data/items.config.json:207](../src/data/items.config.json#L207)
523. 没什么线索的豆浆
   来源：[src/components/PixelIcon.tsx:863](../src/components/PixelIcon.tsx#L863)；[src/data/items.config.json:214](../src/data/items.config.json#L214)
524. 世界观边缘的鸡蛋
   来源：[src/components/PixelIcon.tsx:864](../src/components/PixelIcon.tsx#L864)；[src/data/items.config.json:221](../src/data/items.config.json#L221)
525. 很热但很没用的白粥
   来源：[src/components/PixelIcon.tsx:865](../src/components/PixelIcon.tsx#L865)；[src/data/items.config.json:228](../src/data/items.config.json#L228)
526. 节目单残页·开场
   来源：[src/components/PixelIcon.tsx:869](../src/components/PixelIcon.tsx#L869)；[src/data/items.config.json:256](../src/data/items.config.json#L256)
527. 节目单残页·追光
   来源：[src/components/PixelIcon.tsx:870](../src/components/PixelIcon.tsx#L870)；[src/data/items.config.json:263](../src/data/items.config.json#L263)
528. 节目单残页·谢幕
   来源：[src/components/PixelIcon.tsx:871](../src/components/PixelIcon.tsx#L871)；[src/data/items.config.json:270](../src/data/items.config.json#L270)
529. 桥边
   来源：[src/components/PixelIcon.tsx:876](../src/components/PixelIcon.tsx#L876)；[src/data/items.config.json:305](../src/data/items.config.json#L305)；[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
530. CC98 目击者留下的地点关键词。
   来源：[src/components/PixelIcon.tsx:876](../src/components/PixelIcon.tsx#L876)；[src/data/items.config.json:306](../src/data/items.config.json#L306)
531. 倒影
   来源：[src/components/PixelIcon.tsx:877](../src/components/PixelIcon.tsx#L877)；[src/data/items.config.json:312](../src/data/items.config.json#L312)；[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
532. 馆藏系统留下的地点关键词。
   来源：[src/components/PixelIcon.tsx:877](../src/components/PixelIcon.tsx#L877)；[src/data/items.config.json:313](../src/data/items.config.json#L313)
533. 湖
   来源：[src/components/PixelIcon.tsx:878](../src/components/PixelIcon.tsx#L878)；[src/data/items.config.json:319](../src/data/items.config.json#L319)
534. 微信消息留下的地点关键词。
   来源：[src/components/PixelIcon.tsx:878](../src/components/PixelIcon.tsx#L878)；[src/data/items.config.json:320](../src/data/items.config.json#L320)
535. 倒影坐标
   来源：[src/components/PixelIcon.tsx:879](../src/components/PixelIcon.tsx#L879)；[src/data/itemCatalog.ts:183](../src/data/itemCatalog.ts#L183)；[src/data/items.config.json:326](../src/data/items.config.json#L326)
536. 两种观察模式共同确认的位置。
   来源：[src/components/PixelIcon.tsx:879](../src/components/PixelIcon.tsx#L879)；[src/data/items.config.json:327](../src/data/items.config.json#L327)
537. 从自己的书桌取得，可在天气页面推动湖区云带。
   来源：[src/components/PixelIcon.tsx:880](../src/components/PixelIcon.tsx#L880)
538. 寝室吹风机
   来源：[src/components/PixelIcon.tsx:880](../src/components/PixelIcon.tsx#L880)；[src/data/items.config.json:333](../src/data/items.config.json#L333)
539. 钓竿
   来源：[src/components/PixelIcon.tsx:881](../src/components/PixelIcon.tsx#L881)；[src/data/items.config.json:340](../src/data/items.config.json#L340)
540. 码头装备架上的基础钓竿，可安装诱饵或磁吸附件。
   来源：[src/components/PixelIcon.tsx:881](../src/components/PixelIcon.tsx#L881)；[src/data/items.config.json:341](../src/data/items.config.json#L341)
541. 从湖中钓起的旧钥匙，表面锈迹与码头储物柜一致。
   来源：[src/components/PixelIcon.tsx:882](../src/components/PixelIcon.tsx#L882)；[src/data/items.config.json:348](../src/data/items.config.json#L348)
542. 锈蚀柜钥匙
   来源：[src/components/PixelIcon.tsx:882](../src/components/PixelIcon.tsx#L882)；[src/data/items.config.json:347](../src/data/items.config.json#L347)
543. 储物柜内的耐水尼龙绳，长度足够固定一圈网框。
   来源：[src/components/PixelIcon.tsx:883](../src/components/PixelIcon.tsx#L883)；[src/data/items.config.json:355](../src/data/items.config.json#L355)
544. 尼龙绳
   来源：[src/components/PixelIcon.tsx:883](../src/components/PixelIcon.tsx#L883)；[src/data/items.config.json:354](../src/data/items.config.json#L354)
545. 从水下钓起的旧网框，网面已经脱落。
   来源：[src/components/PixelIcon.tsx:884](../src/components/PixelIcon.tsx#L884)；[src/data/items.config.json:362](../src/data/items.config.json#L362)
546. 断裂网框
   来源：[src/components/PixelIcon.tsx:884](../src/components/PixelIcon.tsx#L884)；[src/data/items.config.json:361](../src/data/items.config.json#L361)
547. 临时抄网
   来源：[src/components/PixelIcon.tsx:885](../src/components/PixelIcon.tsx#L885)；[src/data/items.config.json:368](../src/data/items.config.json#L368)；[src/modules/InventoryController.ts:17](../src/modules/InventoryController.ts#L17)
548. 用尼龙绳修复的网框，可打捞钓钩无法稳定带回的物品。
   来源：[src/components/PixelIcon.tsx:885](../src/components/PixelIcon.tsx#L885)；[src/data/items.config.json:369](../src/data/items.config.json#L369)
549. 从水中捞出的密封金属罐，内部有颗粒滚动声。
   来源：[src/components/PixelIcon.tsx:886](../src/components/PixelIcon.tsx#L886)；[src/data/items.config.json:376](../src/data/items.config.json#L376)
550. 密封罐中的鱼食，可用于吸引小型鱼群靠近。
   来源：[src/components/PixelIcon.tsx:887](../src/components/PixelIcon.tsx#L887)；[src/data/items.config.json:383](../src/data/items.config.json#L383)
551. 鱼食颗粒
   来源：[src/components/PixelIcon.tsx:887](../src/components/PixelIcon.tsx#L887)；[src/data/items.config.json:382](../src/data/items.config.json#L382)
552. 记录 A
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
553. 记录 B
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
554. 记录 C
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
555. 当前任务
   来源：[src/components/QuestClueStrip.tsx:156](../src/components/QuestClueStrip.tsx#L156)；[src/components/QuestClueStrip.tsx:197](../src/components/QuestClueStrip.tsx#L197)
556. {{CHAPTER\_LABEL\[quest.chapter\]}}当前任务：{{parallelObjective}}{{chapterFourAria}}{{showDigitHint ? \`。${digitHintAria}\` : ""}}。点击查看任务提示
   来源：[src/components/QuestClueStrip.tsx:163](../src/components/QuestClueStrip.tsx#L163)
557. 点击查看当前任务和提示
   来源：[src/components/QuestClueStrip.tsx:166](../src/components/QuestClueStrip.tsx#L166)
558. 收起任务
   来源：[src/components/QuestClueStrip.tsx:176](../src/components/QuestClueStrip.tsx#L176)
559. 签到码
   来源：[src/components/QuestClueStrip.tsx:177](../src/components/QuestClueStrip.tsx#L177)
560. 任务详情
   来源：[src/components/QuestClueStrip.tsx:186](../src/components/QuestClueStrip.tsx#L186)
561. 任务栏
   来源：[src/components/QuestClueStrip.tsx:191](../src/components/QuestClueStrip.tsx#L191)
562. 关闭任务详情
   来源：[src/components/QuestClueStrip.tsx:193](../src/components/QuestClueStrip.tsx#L193)
563. 并行调查 {{parallelProgress.completed}}/{{parallelProgress.total}}
   来源：[src/components/QuestClueStrip.tsx:202](../src/components/QuestClueStrip.tsx#L202)
564. 调查分支
   来源：[src/components/QuestClueStrip.tsx:204](../src/components/QuestClueStrip.tsx#L204)
565. 待恢复
   来源：[src/components/QuestClueStrip.tsx:213](../src/components/QuestClueStrip.tsx#L213)
566. 已恢复
   来源：[src/components/QuestClueStrip.tsx:213](../src/components/QuestClueStrip.tsx#L213)
567. 打开
   来源：[src/components/QuestClueStrip.tsx:215](../src/components/QuestClueStrip.tsx#L215)
568. 重新打开
   来源：[src/components/QuestClueStrip.tsx:215](../src/components/QuestClueStrip.tsx#L215)
569. 任务提示
   来源：[src/components/QuestClueStrip.tsx:288](../src/components/QuestClueStrip.tsx#L288)；[src/components/QuestClueStrip.tsx:290](../src/components/QuestClueStrip.tsx#L290)
570. 当前任务没有提示。
   来源：[src/components/QuestClueStrip.tsx:293](../src/components/QuestClueStrip.tsx#L293)
571. 需要时点击下方按钮，逐条查看提示。
   来源：[src/components/QuestClueStrip.tsx:294](../src/components/QuestClueStrip.tsx#L294)
572. 提示已全部展开
   来源：[src/components/QuestClueStrip.tsx:304](../src/components/QuestClueStrip.tsx#L304)
573. 显示下一条提示
   来源：[src/components/QuestClueStrip.tsx:304](../src/components/QuestClueStrip.tsx#L304)
574. 校时表冠：按住并绕圈拖动以校时
   来源：[src/components/RpgClockCrownOverlay.tsx:88](../src/components/RpgClockCrownOverlay.tsx#L88)
575. Back to desktop
   来源：[src/components/ScenePlaceholder.tsx:24](../src/components/ScenePlaceholder.tsx#L24)
576. 流量
   来源：[src/components/StatusBar.tsx:59](../src/components/StatusBar.tsx#L59)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
577. 无服务
   来源：[src/components/StatusBar.tsx:69](../src/components/StatusBar.tsx#L69)
578. 17%
   来源：[src/components/StatusBar.tsx:71](../src/components/StatusBar.tsx#L71)
579. locked
   来源：[src/core/QuestModel.ts:32](../src/core/QuestModel.ts#L32)；[src/modules/Cc98UnifiedLoginModel.ts:80](../src/modules/Cc98UnifiedLoginModel.ts#L80)；[src/scenes/phone/P02_CC98/index.tsx:317](../src/scenes/phone/P02_CC98/index.tsx#L317)；[src/scenes/rpg/BootScene.ts:568](../src/scenes/rpg/BootScene.ts#L568)；[src/scenes/rpg/RpgGameHost.tsx:1123](../src/scenes/rpg/RpgGameHost.tsx#L1123)；[src/scenes/rpg/RpgGameHost.tsx:1216](../src/scenes/rpg/RpgGameHost.tsx#L1216)；[src/scenes/rpg/RpgGameHost.tsx:1235](../src/scenes/rpg/RpgGameHost.tsx#L1235)；[src/scenes/rpg/RpgGameHost.tsx:1243](../src/scenes/rpg/RpgGameHost.tsx#L1243)；[src/scenes/rpg/RpgGameHost.tsx:1255](../src/scenes/rpg/RpgGameHost.tsx#L1255)；[src/scenes/rpg/RpgGameHost.tsx:1268](../src/scenes/rpg/RpgGameHost.tsx#L1268)；[src/scenes/rpg/RpgGameHost.tsx:1293](../src/scenes/rpg/RpgGameHost.tsx#L1293)；[src/scenes/rpg/RpgGameHost.tsx:1303](../src/scenes/rpg/RpgGameHost.tsx#L1303)；[src/scenes/rpg/RpgGameHost.tsx:1310](../src/scenes/rpg/RpgGameHost.tsx#L1310)；[src/scenes/rpg/RpgItemUseGuidance.ts:49](../src/scenes/rpg/RpgItemUseGuidance.ts#L49)
580. 在寝室找一件能用的设备
   来源：[src/core/QuestModel.ts:343](../src/core/QuestModel.ts#L343)
581. 检查自己的书桌。
   来源：[src/core/QuestModel.ts:344](../src/core/QuestModel.ts#L344)
582. 处理启真湖的天气记录
   来源：[src/core/QuestModel.ts:348](../src/core/QuestModel.ts#L348)
583. 打开手机天气页面。
   来源：[src/core/QuestModel.ts:349](../src/core/QuestModel.ts#L349)
584. 完成湖区三处分支 {{branchCount}}/3
   来源：[src/core/QuestModel.ts:370](../src/core/QuestModel.ts#L370)
585. 码头柜门：钓起钥匙并打开柜门。
   来源：[src/core/QuestModel.ts:371](../src/core/QuestModel.ts#L371)
586. 码头柜门：已取得尼龙绳。
   来源：[src/core/QuestModel.ts:371](../src/core/QuestModel.ts#L371)
587. 浮排分支：已取得破损网框。
   来源：[src/core/QuestModel.ts:372](../src/core/QuestModel.ts#L372)
588. 浮排分支：在直河道钓起破损网框。
   来源：[src/core/QuestModel.ts:372](../src/core/QuestModel.ts#L372)
589. 天鹅分支：前往围栏处理旧饲料盒。
   来源：[src/core/QuestModel.ts:373](../src/core/QuestModel.ts#L373)
590. 天鹅分支：已取得磁性扣。
   来源：[src/core/QuestModel.ts:373](../src/core/QuestModel.ts#L373)
591. 三个分支可以任意顺序完成。
   来源：[src/core/QuestModel.ts:374](../src/core/QuestModel.ts#L374)
592. 合并三处分支材料
   来源：[src/core/QuestModel.ts:377](../src/core/QuestModel.ts#L377)
593. 返回大湖面的最终钓具装配位。
   来源：[src/core/QuestModel.ts:378](../src/core/QuestModel.ts#L378)
594. 将尼龙绳、破损网框、磁性扣和钓鱼竿放入装配位。
   来源：[src/core/QuestModel.ts:379](../src/core/QuestModel.ts#L379)
595. 按货架顺序调配今日新品（{{hunt.drinkMixSequence.length}}/3）
   来源：[src/core/QuestModel.ts:433](../src/core/QuestModel.ts#L433)
596. 从饮料机取得三种饮料，再到调配台按黑色、蓝色、白色依次倒入。
   来源：[src/core/QuestModel.ts:434](../src/core/QuestModel.ts#L434)
597. 把今日新品气泡水放入宣传板空杯位
   来源：[src/core/QuestModel.ts:438](../src/core/QuestModel.ts#L438)
598. 目标位在第三窗口宣传板下方。
   来源：[src/core/QuestModel.ts:438](../src/core/QuestModel.ts#L438)
599. 等待第三列队伍让出位置
   来源：[src/core/QuestModel.ts:440](../src/core/QuestModel.ts#L440)
600. 在点餐机选择纸包鸡
   来源：[src/core/QuestModel.ts:445](../src/core/QuestModel.ts#L445)
601. 点餐后会取得 0755 取餐号。
   来源：[src/core/QuestModel.ts:446](../src/core/QuestModel.ts#L446)
602. 浅色操作可直接点餐；深色观察可补充读取异常菜单文字。
   来源：[src/core/QuestModel.ts:446](../src/core/QuestModel.ts#L446)
603. 把 0755 取餐号交给 3 号窗口
   来源：[src/core/QuestModel.ts:452](../src/core/QuestModel.ts#L452)
604. 浅色操作可直接交票；深色观察可补充查看 3 号窗口残影。
   来源：[src/core/QuestModel.ts:453](../src/core/QuestModel.ts#L453)
605. 守住纸条可能逃离的出口（{{hunt.blockHits}}/3）
   来源：[src/core/QuestModel.ts:459](../src/core/QuestModel.ts#L459)
606. 空格键可以冲刺；纸条回头时路线会再次出现。
   来源：[src/core/QuestModel.ts:460](../src/core/QuestModel.ts#L460)
607. 浅色操作可推动当前路线上的餐盘车；深色观察可补充确认蓝色轨迹。
   来源：[src/core/QuestModel.ts:460](../src/core/QuestModel.ts#L460)
608. 回到交通核心，在仍有历史残影的楼层核对旧导视。
   来源：[src/core/QuestModel.ts:905](../src/core/QuestModel.ts#L905)
609. 求是路况员
   来源：[src/data/cc98.posts.json:4](../src/data/cc98.posts.json#L4)
610. 交通出行
   来源：[src/data/cc98.posts.json:7](../src/data/cc98.posts.json#L7)；[src/data/cc98.posts.json:286](../src/data/cc98.posts.json#L286)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
611. 考试结束十分钟，求是潮哪边还能走
   来源：[src/data/cc98.posts.json:8](../src/data/cc98.posts.json#L8)
612. 26-07-10 17:42
   来源：[src/data/cc98.posts.json:11](../src/data/cc98.posts.json#L11)
613. 刚从东侧绕出来。教学区北侧的人行道还能连续走，东侧车流已经堵成两段。
   来源：[src/data/cc98.posts.json:12](../src/data/cc98.posts.json#L12)
614. 标记为实时路况
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
615. 回复区已经形成三条不同绕行路线
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
616. 路况互助机器人
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
617. 17:41 出考场，17:44 还在北口。东边四排车没动，北侧多走两分钟能过。
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)
618. 2楼
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)；[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)；[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)；[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)；[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)；[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)；[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)；[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)；[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)；[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)；[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)；[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)；[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)；[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)；[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)；[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)；[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)；[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)；[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)；[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)；[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)；[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)；[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)；[src/scenes/phone/P02_CC98/index.tsx:113](../src/scenes/phone/P02_CC98/index.tsx#L113)；[src/scenes/phone/P02_CC98/index.tsx:440](../src/scenes/phone/P02_CC98/index.tsx#L440)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:43](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L43)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:44](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L44)
619. 今天 17:44
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)
620. 前排
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)
621. 3楼
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)；[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)；[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)；[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)；[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)；[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)；[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)；[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)；[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)；[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)；[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)；[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)；[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)；[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)；[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)；[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)；[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)；[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)；[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)；[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)；[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)；[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)；[src/scenes/phone/P02_CC98/index.tsx:123](../src/scenes/phone/P02_CC98/index.tsx#L123)；[src/scenes/phone/P02_CC98/index.tsx:441](../src/scenes/phone/P02_CC98/index.tsx#L441)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:53](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L53)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:54](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L54)
622. 北边树下还有空路，风也从那边过。走北侧，别跟车流挤。
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)
623. 建议
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)；[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)；[src/scenes/phone/P07_Weather/index.tsx:103](../src/scenes/phone/P07_Weather/index.tsx#L103)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
624. 今天 17:45
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)；[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)
625. 4楼
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)；[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)；[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)；[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)；[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)；[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)；[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)；[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)；[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)；[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)；[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)；[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)；[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)；[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)；[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)；[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)；[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)；[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)；[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)；[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)；[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)；[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)；[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)；[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)；[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)；[src/scenes/phone/P02_CC98/index.tsx:134](../src/scenes/phone/P02_CC98/index.tsx#L134)
626. 二南门口横着停的共享单车还在。北口靠左走，别贴着那辆车。
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)
627. 今天 17:47
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)
628. 路况
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)；[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)
629. 5楼
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)；[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)；[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)；[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)；[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)；[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)；[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)；[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)；[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)；[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)；[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)；[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)；[src/scenes/phone/P02_CC98/index.tsx:145](../src/scenes/phone/P02_CC98/index.tsx#L145)
630. 今天 17:49
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)；[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
631. 实况
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)
632. 我刚骑完北侧绿道，过两个路口没停。东侧第一个口已经堵满。
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)
633. 6楼
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)；[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)；[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)；[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)；[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)；[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)；[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)；[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
634. 今天 17:51
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)
635. 我没有余额换车，推着现有这辆从北侧过了。北侧确实更省时间。
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)
636. 预算
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)
637. 7楼
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)；[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)；[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)；[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)；[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)；[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)；[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)；[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)；[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)；[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)
638. 报数
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)
639. 记录里写清楚，北侧可通，东侧拥堵。走人行道，别把车推进行人堆。
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)
640. 今天 17:54
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)
641. 二南守座人
   来源：[src/data/cc98.posts.json:26](../src/data/cc98.posts.json#L26)
642. 图书馆
   来源：[src/data/cc98.posts.json:29](../src/data/cc98.posts.json#L29)；[src/data/cc98.posts.json:344](../src/data/cc98.posts.json#L344)；[src/scenes/phone/P02_CC98/index.tsx:197](../src/scenes/phone/P02_CC98/index.tsx#L197)；[src/scenes/phone/P13_PhoneHome/index.tsx:768](../src/scenes/phone/P13_PhoneHome/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:125](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L125)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:485](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L485)
643. 二层南临时离座规则更新了吗
   来源：[src/data/cc98.posts.json:30](../src/data/cc98.posts.json#L30)
644. 26-07-10 17:39
   来源：[src/data/cc98.posts.json:33](../src/data/cc98.posts.json#L33)
645. 离座超过三分钟后，原座位会重新开放。完成校园卡核验后，可在选座页申请恢复一次。
   来源：[src/data/cc98.posts.json:34](../src/data/cc98.posts.json#L34)
646. 补充规则入口
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
647. 馆内秩序值班台
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
648. 原帖只有结果，没有说明恢复材料
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
649. 17:40 去接水，17:43 回来，页面已经换成别人的编号。先留好时间戳。
   来源：[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)
650. 今天 17:41
   来源：[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)；[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
651. 带图
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)
652. 今天 17:43
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)
653. 先帮顶。人还没坐回去，这条帖先别被新消息刷掉。
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)
654. bd
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:57](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L57)
655. 022 桌上的书包三天没动。它比大多数人更符合“长期使用”这一项。
   来源：[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)
656. 提案
   来源：[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)
657. 今天 17:48
   来源：[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)
658. 经历
   来源：[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)；[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)；[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)；[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)
659. 我去接水 2 分 59 秒，回到门口刚好三分钟。座位已经换号。
   来源：[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)
660. 0.06 元可以做身份核验，恢复申请还是要补材料。
   来源：[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)
661. 今天 17:50
   来源：[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)
662. 资产
   来源：[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)
663. 今天 17:53
   来源：[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)
664. 理论
   来源：[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)
665. 需要留下离座时长和校园卡核验两项记录。满足后才能申请恢复。
   来源：[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)
666. 资料索引机
   来源：[src/data/cc98.posts.json:48](../src/data/cc98.posts.json#L48)
667. 学习天地
   来源：[src/data/cc98.posts.json:51](../src/data/cc98.posts.json#L51)；[src/data/cc98.posts.json:205](../src/data/cc98.posts.json#L205)；[src/data/cc98.posts.json:306](../src/data/cc98.posts.json#L306)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:195](../src/scenes/phone/P02_CC98/index.tsx#L195)
668. 期末资料按课程和年份整理好了
   来源：[src/data/cc98.posts.json:52](../src/data/cc98.posts.json#L52)
669. 26-07-10 17:35
   来源：[src/data/cc98.posts.json:55](../src/data/cc98.posts.json#L55)
670. 资料按课程、教师和年份建立索引。搜索时只记得两个字也能定位到对应目录。
   来源：[src/data/cc98.posts.json:56](../src/data/cc98.posts.json#L56)
671. 加入版面索引
   来源：[src/data/cc98.posts.json:57](../src/data/cc98.posts.json#L57)
672. 目录结构和版本信息均可核对
   来源：[src/data/cc98.posts.json:57](../src/data/cc98.posts.json#L57)
673. 资料版值班员
   来源：[src/data/cc98.posts.json:57](../src/data/cc98.posts.json#L57)；[src/data/cc98.posts.json:312](../src/data/cc98.posts.json#L312)
674. 今天 17:37
   来源：[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)；[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)
675. 求助
   来源：[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)
676. 文件名写成“最终版5真的最终版”的那份，能不能把交稿时间也写进文件名。
   来源：[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)
677. “老师说不考”我会单独存。考试前夜总有人去翻这个文件夹。
   来源：[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)
678. 今天 17:39
   来源：[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)
679. 保留
   来源：[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
680. 高数目录里的图书馆规则别删，022 这次要靠它确认座位。
   来源：[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
681. 反向实测
   来源：[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)
682. 我输入完整课程名，首页先给了三条选课通知。索引能不能再靠前一点？
   来源：[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)
683. 今天 17:46
   来源：[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)
684. 下载
   来源：[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)；[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
685. 资料不用钱，下载到 99% 断掉后，我得再付一遍流量。
   来源：[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)
686. 蹲蹲
   来源：[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
687. 请补版本日期、页数和来源。只有“最终版”，我无法判断是哪一天的最终版。
   来源：[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
688. 六分钱余额
   来源：[src/data/cc98.posts.json:70](../src/data/cc98.posts.json#L70)
689. 校园卡
   来源：[src/data/cc98.posts.json:73](../src/data/cc98.posts.json#L73)；[src/data/cc98.posts.json:363](../src/data/cc98.posts.json#L363)；[src/data/cc98.posts.json:478](../src/data/cc98.posts.json#L478)；[src/data/items.config.json:53](../src/data/items.config.json#L53)；[src/scenes/phone/P02_CC98/index.tsx:201](../src/scenes/phone/P02_CC98/index.tsx#L201)
690. 余额 0.06 元能通过临时离座校验吗
   来源：[src/data/cc98.posts.json:74](../src/data/cc98.posts.json#L74)
691. 26-07-10 17:31
   来源：[src/data/cc98.posts.json:77](../src/data/cc98.posts.json#L77)
692. 实测可以。余额不会影响身份校验，系统仍然要求完整走完验证流程。
   来源：[src/data/cc98.posts.json:78](../src/data/cc98.posts.json#L78)
693. 标记为已实测
   来源：[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)
694. 楼主提供了低余额条件下的完整结果
   来源：[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)
695. 校园卡民间客服
   来源：[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)；[src/data/cc98.posts.json:369](../src/data/cc98.posts.json#L369)；[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
696. 0.06 元能刷身份，打印一面还差一点。至少时间戳能留下。
   来源：[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)
697. 今天 17:33
   来源：[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)；[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)
698. 实测
   来源：[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)；[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)；[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)
699. 今天 17:35
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)
700. 刷卡声很响，余额数字很小。旁边排队的人全听见了。
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)
701. 现场
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)；[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)；[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
702. 门禁只看校园卡身份，余额写在另一个页面。我在入口看过。
   来源：[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)
703. 成本
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
704. 从求是潮骑去充值点再回来，比这次校验本身久。
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
705. 今天 17:40
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
706. 本人
   来源：[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)
707. 今天 17:42
   来源：[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)；[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)
708. 楼主在。0.06 元够我做身份核验，其他事要等以后。
   来源：[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)
709. 实测结果已留档。低余额可核验，恢复申请仍要完成。
   来源：[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)
710. 众筹
   来源：[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)
711. 体艺第47次
   来源：[src/data/cc98.posts.json:92](../src/data/cc98.posts.json#L92)
712. 校园生活
   来源：[src/data/cc98.posts.json:95](../src/data/cc98.posts.json#L95)；[src/data/cc98.posts.json:183](../src/data/cc98.posts.json#L183)；[src/data/cc98.posts.json:227](../src/data/cc98.posts.json#L227)；[src/data/cc98.posts.json:459](../src/data/cc98.posts.json#L459)；[src/scenes/phone/P02_CC98/index.tsx:59](../src/scenes/phone/P02_CC98/index.tsx#L59)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:193](../src/scenes/phone/P02_CC98/index.tsx#L193)
713. 今天的运动记录全是绕自行车
   来源：[src/data/cc98.posts.json:96](../src/data/cc98.posts.json#L96)
714. 26-07-10 17:28
   来源：[src/data/cc98.posts.json:99](../src/data/cc98.posts.json#L99)
715. 体艺记录显示四十七次通行，实际过程是在求是潮两侧反复寻找能走的缝隙。
   来源：[src/data/cc98.posts.json:100](../src/data/cc98.posts.json#L100)
716. 计入特殊路线样本
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
717. 课外锻炼观察组
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
718. 路线确有移动，运动目的暂无法判断
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
719. 从 17:28 到 17:42，我绕同一辆车四十七次。打印队都没它绕得久。
   来源：[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)
720. 分账
   来源：[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)
721. 今天 17:30
   来源：[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)；[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)；[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)
722. 北口风大，人走得慢。三步一停，体艺还是把它记成通行。
   来源：[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)
723. 今天 17:32
   来源：[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)；[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)
724. 逆风
   来源：[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)
725. 二南门口那辆车一直横在外侧，旁边还有一辆车把它挡住。
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)
726. 今天 17:34
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
727. 命名
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)
728. 车流在路口回堵，骑车的人掉头，步行的人跟着让。两分钟没过一个灯。
   来源：[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)
729. 今天 17:36
   来源：[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)
730. 步数进账了，目的地没到。体艺记录和我今天的路线各算各的。
   来源：[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)
731. 收益
   来源：[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)
732. 凑整
   来源：[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)
733. 记录有效。位移反复发生，终点未到。这条路线该单列。
   来源：[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)
734. 西区打印排队中
   来源：[src/data/cc98.posts.json:114](../src/data/cc98.posts.json#L114)
735. 打印服务
   来源：[src/data/cc98.posts.json:117](../src/data/cc98.posts.json#L117)；[src/data/cc98.posts.json:325](../src/data/cc98.posts.json#L325)；[src/scenes/phone/P02_CC98/index.tsx:200](../src/scenes/phone/P02_CC98/index.tsx#L200)
736. 西区打印店早上哪台机快一点
   来源：[src/data/cc98.posts.json:118](../src/data/cc98.posts.json#L118)
737. 26-07-10 17:24
   来源：[src/data/cc98.posts.json:121](../src/data/cc98.posts.json#L121)
738. 今天 08:10 到西区打印店，前面有六个人。双面黑白先空出来，彩打那台一直在换纸。赶早课的可以先打黑白。
   来源：[src/data/cc98.posts.json:122](../src/data/cc98.posts.json#L122)
739. 补充机器状态
   来源：[src/data/cc98.posts.json:123](../src/data/cc98.posts.json#L123)
740. 打印店排队记录员
   来源：[src/data/cc98.posts.json:123](../src/data/cc98.posts.json#L123)；[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)
741. 楼主记录了到店时间和两台机器的使用情况
   来源：[src/data/cc98.posts.json:123](../src/data/cc98.posts.json#L123)
742. 08:13 我在左边那台打完 18 页，自动双面没有卡纸。
   来源：[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)
743. 今天 17:26
   来源：[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)；[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
744. 今天 17:28
   来源：[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)；[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
745. 门口的取件架今天挪到右手边，拿完别站在入口数页码。
   来源：[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)
746. 提醒
   来源：[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)；[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)；[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)；[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)；[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)；[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)；[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)；[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)；[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)
747. 细节
   来源：[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)
748. 装订机旁边那台需要先在屏幕上选纸型，直接塞纸会退回。
   来源：[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)
749. 从西区食堂后门过去，08:20 还不用排到台阶上。
   来源：[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)
750. 路线
   来源：[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)；[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)
751. 付款
   来源：[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
752. 校园卡余额不够时可以先用手机付，机器会保留刚才选的份数。
   来源：[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
753. 把到店时间、机器编号和纸张规格写在订单上，之后找文件方便。
   来源：[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)
754. 闭馆后找座位
   来源：[src/data/cc98.posts.json:136](../src/data/cc98.posts.json#L136)
755. 自习室
   来源：[src/data/cc98.posts.json:139](../src/data/cc98.posts.json#L139)；[src/data/cc98.posts.json:497](../src/data/cc98.posts.json#L497)；[src/scenes/phone/P02_CC98/index.tsx:198](../src/scenes/phone/P02_CC98/index.tsx#L198)
756. 基础图书馆闭馆后还有安静的位置吗
   来源：[src/data/cc98.posts.json:140](../src/data/cc98.posts.json#L140)
757. 26-07-10 17:21
   来源：[src/data/cc98.posts.json:143](../src/data/cc98.posts.json#L143)
758. 昨晚 19:35 从基础图书馆二楼出来，雨衣没带，就去麦斯威靠窗那排坐到 20:10。插座在桌脚边，带长线会好用一点。
   来源：[src/data/cc98.posts.json:144](../src/data/cc98.posts.json#L144)
759. 加入自习地点索引
   来源：[src/data/cc98.posts.json:145](../src/data/cc98.posts.json#L145)
760. 帖子提供了闭馆后的实际座位和插座位置
   来源：[src/data/cc98.posts.json:145](../src/data/cc98.posts.json#L145)
761. 夜间自习信息台
   来源：[src/data/cc98.posts.json:145](../src/data/cc98.posts.json#L145)；[src/data/cc98.posts.json:503](../src/data/cc98.posts.json#L503)
762. 补充
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)；[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)；[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)；[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)；[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)；[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)
763. 今天 17:23
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)；[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)
764. 麦斯威二楼 19:50 还有空桌，靠窗的位置灯比较亮。
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)
765. 今天 17:25
   来源：[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)
766. 雨天
   来源：[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)
767. 昨晚雨大，门口地垫湿了。伞先套袋再进座位区。
   来源：[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)
768. 插座
   来源：[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)
769. 今天 17:27
   来源：[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)；[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)
770. 靠墙第三张桌的插座松，手机充电会断，电脑最好接靠柱子的那排。
   来源：[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)
771. 到店
   来源：[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)
772. 今天 17:29
   来源：[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)
773. 我 20:05 从东门进，店里有人开线上会议，想安静写题记得带耳塞。
   来源：[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)
774. 今天 17:31
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
775. 热水要在一楼吧台旁接，带杯子比临时买饮料省时间。
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
776. 消费
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
777. 离开前看一下桌面和插座，闭馆后的座位没有统一失物招领提醒。
   来源：[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)
778. 三楼最后一勺
   来源：[src/data/cc98.posts.json:158](../src/data/cc98.posts.json#L158)
779. 食堂
   来源：[src/data/cc98.posts.json:161](../src/data/cc98.posts.json#L161)；[src/data/cc98.posts.json:247](../src/data/cc98.posts.json#L247)；[src/data/cc98.posts.json:554](../src/data/cc98.posts.json#L554)；[src/scenes/phone/P02_CC98/index.tsx:199](../src/scenes/phone/P02_CC98/index.tsx#L199)
780. 东二食堂三楼炒饭晚上几点收窗口
   来源：[src/data/cc98.posts.json:162](../src/data/cc98.posts.json#L162)
781. 26-07-10 17:18
   来源：[src/data/cc98.posts.json:165](../src/data/cc98.posts.json#L165)
782. 昨晚 18:50 去东二食堂三楼，炒饭窗口还接单，19:05 只剩蛋炒饭。想加青菜的要早点去，打包盒在窗口右边自己拿。
   来源：[src/data/cc98.posts.json:166](../src/data/cc98.posts.json#L166)
783. 补充窗口时间
   来源：[src/data/cc98.posts.json:167](../src/data/cc98.posts.json#L167)
784. 东二饭点记录
   来源：[src/data/cc98.posts.json:167](../src/data/cc98.posts.json#L167)；[src/data/cc98.posts.json:253](../src/data/cc98.posts.json#L253)；[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
785. 楼主给出了到店时间和当天剩余餐品
   来源：[src/data/cc98.posts.json:167](../src/data/cc98.posts.json#L167)
786. 18:40 去还有青菜炒饭，取餐区右侧的勺子需要自己拿。
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)
787. 饭点
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)
788. 今天 17:20
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)；[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)
789. 今天 17:22
   来源：[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)；[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
790. 排队
   来源：[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)；[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)；[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)
791. 下雨天大家都从南门进，18:45 后南门那条队会拐到柱子后面。
   来源：[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)
792. 今天 17:24
   来源：[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)；[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)
793. 三楼靠窗两排桌子先被占满，端着餐盘上去前先看一眼空位。
   来源：[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)
794. 座位
   来源：[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)；[src/data/itemCatalog.ts:32](../src/data/itemCatalog.ts#L32)；[src/scenes/phone/P15_Zjuding/index.tsx:1811](../src/scenes/phone/P15_Zjuding/index.tsx#L1811)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
795. 到达
   来源：[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
796. 我从东门骑过去，18:55 才停好车，窗口已经开始收配菜。
   来源：[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
797. 打包盒不收钱，筷子在取餐台下层。刚才找了三分钟。
   来源：[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
798. 支付
   来源：[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
799. 窗口时间会按当天备菜量变，想稳妥就按 18:40 到店安排。
   来源：[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)
800. 核对
   来源：[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)；[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)；[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)；[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)；[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
801. 雨天伞套管理员
   来源：[src/data/cc98.posts.json:180](../src/data/cc98.posts.json#L180)
802. 教学楼门口的伞套机今天放哪边了
   来源：[src/data/cc98.posts.json:184](../src/data/cc98.posts.json#L184)
803. 26-07-10 17:15
   来源：[src/data/cc98.posts.json:187](../src/data/cc98.posts.json#L187)
804. 今天 16:20 到东教学楼，伞套机从门左边移到了门卫桌旁。机器没纸时可以先去旁边的小篮子拿，别把湿伞直接带进走廊。
   来源：[src/data/cc98.posts.json:188](../src/data/cc98.posts.json#L188)
805. 补充入口位置
   来源：[src/data/cc98.posts.json:189](../src/data/cc98.posts.json#L189)
806. 伞套机和备用伞套的位置都已说明
   来源：[src/data/cc98.posts.json:189](../src/data/cc98.posts.json#L189)
807. 雨天通行提醒
   来源：[src/data/cc98.posts.json:189](../src/data/cc98.posts.json#L189)
808. 16:25 备用篮还有一半，拿完要把伞尖朝下放。
   来源：[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)
809. 今天 17:17
   来源：[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)
810. 今天 17:19
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)
811. 天气
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)；[src/scenes/phone/P07_Weather/index.tsx:68](../src/scenes/phone/P07_Weather/index.tsx#L68)；[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)；[src/scenes/phone/P13_PhoneHome/index.tsx:845](../src/scenes/phone/P13_PhoneHome/index.tsx#L845)；[src/scenes/phone/P13_PhoneHome/index.tsx:851](../src/scenes/phone/P13_PhoneHome/index.tsx#L851)
812. 雨水会顺着门槛流进去，进门后先在地垫上停两步。
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)
813. 摆放
   来源：[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)
814. 今天 17:21
   来源：[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)
815. 伞架右侧那一格空着，长柄伞别横放，会挡住旁边的人。
   来源：[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)
816. 骑车到门口后先推到屋檐下，直接停在入口会挡住送货车。
   来源：[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)
817. 通行
   来源：[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)
818. 备用伞套不用刷卡，旁边的饮水机才需要校园卡。
   来源：[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)
819. 入口改过位置后，最好把门左和门右都看一遍，免得回头找。
   来源：[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)
820. 晚课后抄题人
   来源：[src/data/cc98.posts.json:202](../src/data/cc98.posts.json#L202)
821. 线代课后题有人用同一版空白答题纸吗
   来源：[src/data/cc98.posts.json:206](../src/data/cc98.posts.json#L206)
822. 26-07-10 17:12
   来源：[src/data/cc98.posts.json:209](../src/data/cc98.posts.json#L209)
823. 周三 21:10 在西区教学楼打印室找空白答题纸，最后在靠窗的文件架第二层看到一叠。纸张右上角有课程简称，拿之前先数清页数。
   来源：[src/data/cc98.posts.json:210](../src/data/cc98.posts.json#L210)
824. 补充取用位置
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
825. 楼主说明了寻找时间、房间和文件架层数
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
826. 学习资料互助台
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
827. 今天 17:14
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)
828. 我拿到的是六页版，最后一页有老师留的空白演算区。
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)
829. 资料
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)
830. 今天 17:16
   来源：[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)
831. 文件架旁边的窗没关，纸角有点卷，带夹子会好拿。
   来源：[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)
832. 今天 17:18
   来源：[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)
833. 同一层还有一叠概率论的纸，课程简称只差一个字，别拿错。
   来源：[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)
834. 从西区教学楼南门进，沿走廊到头再右转，打印室就在饮水机旁。
   来源：[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)
835. 复印
   来源：[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
836. 只要空白纸的话，复印机不用开机，先看文件架的标签。
   来源：[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
837. 拿走后在帖子里写一下版本和页数，后来的人就不用逐叠翻。
   来源：[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)
838. 整理
   来源：[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
839. 雨天走南门
   来源：[src/data/cc98.posts.json:224](../src/data/cc98.posts.json#L224)
840. 雨还没停，东教学楼哪扇门口不积水
   来源：[src/data/cc98.posts.json:228](../src/data/cc98.posts.json#L228)
841. 26-07-10 17:08
   来源：[src/data/cc98.posts.json:231](../src/data/cc98.posts.json#L231)
842. 刚从东教学楼出来，西侧玻璃门前的地垫已经湿透。南边侧门的地面还干一点，手里有纸和电脑的可以从那边进。
   来源：[src/data/cc98.posts.json:232](../src/data/cc98.posts.json#L232)
843. 保留雨天通行记录
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)
844. 楼主说明了两处门口的地面情况
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)
845. 校园生活值班员
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)；[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
846. 今天 17:10
   来源：[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)
847. 西侧那块地垫已经软了，早八带纸质资料的还是绕南边。
   来源：[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)
848. 今天 17:12
   来源：[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)
849. 路过
   来源：[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)
850. 我从南侧门进，门口有一串伞套，走进去还算干。
   来源：[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)
851. 侧门的扶手有水，进门时别一边看手机一边跨门槛。
   来源：[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)
852. 二十分钟前路过，南边那块地还没积水。
   来源：[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)
853. 更新
   来源：[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)
854. 端盘找座位
   来源：[src/data/cc98.posts.json:244](../src/data/cc98.posts.json#L244)
855. 东二晚高峰的空座是在二楼还是三楼
   来源：[src/data/cc98.posts.json:248](../src/data/cc98.posts.json#L248)
856. 26-07-10 17:05
   来源：[src/data/cc98.posts.json:251](../src/data/cc98.posts.json#L251)
857. 傍晚六点二十到东二时二楼靠门的桌子已经满了，三楼最里面还有两张四人桌。想先放包再去排队的，记得别把通道边的空椅子当座位。
   来源：[src/data/cc98.posts.json:252](../src/data/cc98.posts.json#L252)
858. 补充座位信息
   来源：[src/data/cc98.posts.json:253](../src/data/cc98.posts.json#L253)
859. 楼主记录了到店时间和可用桌位
   来源：[src/data/cc98.posts.json:253](../src/data/cc98.posts.json#L253)
860. 今天 17:07
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
861. 晚到
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
862. 我六点三十五才上三楼，里面那两张桌已经有人坐下了。
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
863. 二楼饮水机旁的两把椅子在等人，别端着盘子站过去。
   来源：[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)
864. 观察
   来源：[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)
865. 今天 17:09
   来源：[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)
866. 今天 17:11
   来源：[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)
867. 三楼窗口排得慢一点，座位倒是比二楼松。
   来源：[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)
868. 结论
   来源：[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)；[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)；[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)；[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)
869. 今天 17:13
   来源：[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)
870. 想快点吃就二楼排队，想坐下就先上三楼看一圈。
   来源：[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)
871. 门口捡眼镜
   来源：[src/data/cc98.posts.json:264](../src/data/cc98.posts.json#L264)
872. 失物招领
   来源：[src/data/cc98.posts.json:267](../src/data/cc98.posts.json#L267)；[src/data/cc98.posts.json:535](../src/data/cc98.posts.json#L535)；[src/scenes/phone/P02_CC98/index.tsx:202](../src/scenes/phone/P02_CC98/index.tsx#L202)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:105](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L105)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:73](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L73)
873. 东区食堂门口捡到一副黑框眼镜
   来源：[src/data/cc98.posts.json:268](../src/data/cc98.posts.json#L268)
874. 26-07-10 17:02
   来源：[src/data/cc98.posts.json:271](../src/data/cc98.posts.json#L271)
875. 傍晚在东区食堂南门台阶边捡到一副黑框眼镜，镜腿内侧有一小段白色贴纸。我交到一楼服务台了，失主去问时带一下能核对的信息。
   来源：[src/data/cc98.posts.json:272](../src/data/cc98.posts.json#L272)
876. 标记服务台已接收
   来源：[src/data/cc98.posts.json:273](../src/data/cc98.posts.json#L273)
877. 失物招领版面
   来源：[src/data/cc98.posts.json:273](../src/data/cc98.posts.json#L273)；[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
878. 物品去向和辨认特征已经写明
   来源：[src/data/cc98.posts.json:273](../src/data/cc98.posts.json#L273)
879. 今天 17:04
   来源：[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)；[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)
880. 贴纸上有没有课程名，我室友下午刚丢了一副。
   来源：[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)
881. 问询
   来源：[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)
882. 今天 17:06
   来源：[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)
883. 先别把镜片度数写出来，服务台核对时再说。
   来源：[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)
884. 今天 17:08
   来源：[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)
885. 南门台阶晚上人多，走的时候最好把东西放包里。
   来源：[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)
886. 剧场外等雨小组
   来源：[src/data/cc98.posts.json:283](../src/data/cc98.posts.json#L283)
887. 从剧场走去湖边，雨后哪段路灯更亮
   来源：[src/data/cc98.posts.json:287](../src/data/cc98.posts.json#L287)
888. 26-07-10 16:58
   来源：[src/data/cc98.posts.json:290](../src/data/cc98.posts.json#L290)
889. 演出散场后往湖边走，靠外侧的树下那段光比较暗，石板也有水。绕到主路再下去会多走几分钟，路面和灯都好一点。
   来源：[src/data/cc98.posts.json:291](../src/data/cc98.posts.json#L291)
890. 加入雨后步行提醒
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
891. 楼主写清了两条路线的差别
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
892. 夜间步行信息台
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
893. 今天 17:00
   来源：[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)；[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
894. 骑行
   来源：[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)
895. 主路有积水反光，骑车也别压着边沿走。
   来源：[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)
896. 风向
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)；[src/scenes/phone/P07_Weather/index.tsx:101](../src/scenes/phone/P07_Weather/index.tsx#L101)
897. 湖边风比剧场外大，伞撑不住时先收起来。
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)
898. 今天 17:02
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)
899. 时间
   来源：[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)；[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/itemCatalog.ts:94](../src/data/itemCatalog.ts#L94)；[src/scenes/phone/P15_Zjuding/index.tsx:404](../src/scenes/phone/P15_Zjuding/index.tsx#L404)
900. 我多走了三分钟，鞋底没沾上泥，值。
   来源：[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)
901. 夜里走主路，别沿着树影那边抄近道。
   来源：[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)
902. 页码强迫症
   来源：[src/data/cc98.posts.json:303](../src/data/cc98.posts.json#L303)
903. 化工原理旧卷的页码有人补齐了吗
   来源：[src/data/cc98.posts.json:307](../src/data/cc98.posts.json#L307)
904. 26-07-10 16:54
   来源：[src/data/cc98.posts.json:310](../src/data/cc98.posts.json#L310)
905. 资料夹里有两份同年份旧卷，一份从第六页直接跳到第八页。我把缺页题号记下来了，想问有没有人留着完整扫描版，能顺手核对一下。
   来源：[src/data/cc98.posts.json:311](../src/data/cc98.posts.json#L311)
906. 保留缺页标记
   来源：[src/data/cc98.posts.json:312](../src/data/cc98.posts.json#L312)
907. 楼主指出了具体版本和缺失位置
   来源：[src/data/cc98.posts.json:312](../src/data/cc98.posts.json#L312)
908. 今天 16:56
   来源：[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)；[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
909. 文件
   来源：[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)
910. 我手里的版本是八页，周末回寝室再找一下原件。
   来源：[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)
911. 第七页是传热那道图题，只有题干没有答案。
   来源：[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)
912. 今天 16:58
   来源：[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)
913. 不要把缺页版覆盖原文件，后面的人还要比对来源。
   来源：[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
914. 胶圈带少了
   来源：[src/data/cc98.posts.json:322](../src/data/cc98.posts.json#L322)
915. 打印室的装订机还需要自己带胶圈吗
   来源：[src/data/cc98.posts.json:326](../src/data/cc98.posts.json#L326)
916. 26-07-10 16:50
   来源：[src/data/cc98.posts.json:329](../src/data/cc98.posts.json#L329)
917. 西区教学楼打印室的装订机能用，桌上只剩小号胶圈。报告超过四十页的，最好自己带一包，临时等补货容易赶不上上课。
   来源：[src/data/cc98.posts.json:330](../src/data/cc98.posts.json#L330)
918. 补充耗材状态
   来源：[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)
919. 楼主说明了机器和胶圈的现状
   来源：[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)
920. 刚才有人拿五十页去装，店员让他分两本。
   来源：[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)
921. 今天 16:52
   来源：[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)
922. 今天 16:54
   来源：[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)
923. 透明封面在最下面一层抽屉，第一次去很容易漏看。
   来源：[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)
924. 经验
   来源：[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
925. 页数多就分两册，翻起来也省事。
   来源：[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
926. 二楼靠窗充电中
   来源：[src/data/cc98.posts.json:341](../src/data/cc98.posts.json#L341)
927. 基础图书馆二楼靠窗的插座这两天还稳吗
   来源：[src/data/cc98.posts.json:345](../src/data/cc98.posts.json#L345)
928. 26-07-10 16:46
   来源：[src/data/cc98.posts.json:348](../src/data/cc98.posts.json#L348)
929. 昨天靠窗第三张桌的插座断过两次，换到靠柱子那排后正常。今天要带电脑写作业的，先别把座位选在窗边最里面。
   来源：[src/data/cc98.posts.json:349](../src/data/cc98.posts.json#L349)
930. 补充插座状态
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
931. 楼主给出了异常位置和替代位置
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
932. 图书馆设备记录
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
933. 复测
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)
934. 今天 16:48
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)；[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)
935. 我下午试了两次，靠窗第三张桌还是会松。
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)
936. 今天 16:50
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
937. 靠柱子那排有两个空口，插头比较紧。
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
938. 替代
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
939. 别把插线板横在过道，借书车会从那里过。
   来源：[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)
940. 补办卡排队中
   来源：[src/data/cc98.posts.json:360](../src/data/cc98.posts.json#L360)
941. 校园卡补办当天能进图书馆吗
   来源：[src/data/cc98.posts.json:364](../src/data/cc98.posts.json#L364)
942. 26-07-10 16:42
   来源：[src/data/cc98.posts.json:367](../src/data/cc98.posts.json#L367)
943. 今天上午卡丢了，补办后先在机器上做了一次身份核验，下午进基础图书馆没有被拦。旧卡已经停用，带着旧卡去刷只会多排一次队。
   来源：[src/data/cc98.posts.json:368](../src/data/cc98.posts.json#L368)
944. 标记为当日记录
   来源：[src/data/cc98.posts.json:369](../src/data/cc98.posts.json#L369)
945. 楼主说明了补办后的验证和入馆结果
   来源：[src/data/cc98.posts.json:369](../src/data/cc98.posts.json#L369)
946. 补办后先看卡面编号，机器读取到新号才算完成。
   来源：[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)
947. 今天 16:44
   来源：[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)；[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)
948. 今天 16:46
   来源：[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
949. 中午人少一点，柜台和机器都不用等太久。
   来源：[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)
950. 丢卡先停用，补办当天把新卡做一次验证。
   来源：[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)
951. 信号格满了
   来源：[src/data/cc98.posts.json:379](../src/data/cc98.posts.json#L379)
952. 手机服务
   来源：[src/data/cc98.posts.json:382](../src/data/cc98.posts.json#L382)；[src/scenes/phone/P02_CC98/index.tsx:196](../src/scenes/phone/P02_CC98/index.tsx#L196)
953. 【移动/联通/电信】2026年校园电话卡信息汇总帖 详情请戳
   来源：[src/data/cc98.posts.json:383](../src/data/cc98.posts.json#L383)
954. 26-07-10 16:38
   来源：[src/data/cc98.posts.json:386](../src/data/cc98.posts.json#L386)
955. 准备开学换号的可以先把套餐、校园区域覆盖和注销条件写在同一层回复里。只放海报截图很难比较，最好补充自己实测的宿舍、教学楼和地铁口信号。
   来源：[src/data/cc98.posts.json:387](../src/data/cc98.posts.json#L387)
956. 讨论包含不同运营商的使用场景和办理提醒
   来源：[src/data/cc98.posts.json:388](../src/data/cc98.posts.json#L388)
957. 校园通信互助台
   来源：[src/data/cc98.posts.json:388](../src/data/cc98.posts.json#L388)
958. 整理为信息汇总
   来源：[src/data/cc98.posts.json:388](../src/data/cc98.posts.json#L388)
959. 教学楼里先看自己常待的那一侧，办卡点的信号格不能代表上课的位置。
   来源：[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)
960. 今天 16:40
   来源：[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)；[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
961. 今天 16:42
   来源：[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)
962. 套餐写清楚是月租还是校园期，别把首月优惠当成长期价格。
   来源：[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)
963. 想保留旧号码的先问转网和注销流程，开学那周柜台排队会很长。
   来源：[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)
964. 楼里只保留可核对的套餐名称、适用期限和实测位置，广告图不单独计入结论。
   来源：[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
965. 图书馆门口的雨
   来源：[src/data/cc98.posts.json:399](../src/data/cc98.posts.json#L399)
966. 开怀一笑
   来源：[src/data/cc98.posts.json:402](../src/data/cc98.posts.json#L402)；[src/data/cc98.posts.json:421](../src/data/cc98.posts.json#L421)；[src/data/cc98.posts.json:516](../src/data/cc98.posts.json#L516)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:204](../src/scenes/phone/P02_CC98/index.tsx#L204)
967. 雨伞在一楼，人在三楼，雨还在外面
   来源：[src/data/cc98.posts.json:403](../src/data/cc98.posts.json#L403)
968. 26-07-10 16:34
   来源：[src/data/cc98.posts.json:406](../src/data/cc98.posts.json#L406)
969. 本来只是下楼拿外卖，发现伞架里那把蓝伞很像我的。等我把伞带到三楼，才想起自己的伞还在寝室。
   来源：[src/data/cc98.posts.json:407](../src/data/cc98.posts.json#L407)
970. 保留轻松讨论
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)
971. 回复围绕雨天小失误展开，没有涉及失物认领
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)
972. 开怀一笑值班员
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)；[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)；[src/data/cc98.posts.json:522](../src/data/cc98.posts.json#L522)
973. 今天 16:36
   来源：[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)；[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)
974. 同款
   来源：[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)
975. 我有一次带着空伞套走回寝室，雨伞在门口，套子在手里。
   来源：[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)
976. 今天 16:38
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)
977. 确认
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)
978. 至少你把伞带到了需要它的楼层，进度已经过半。
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)
979. 补图
   来源：[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
980. 下雨天的记忆会自动把所有蓝伞归到自己名下。
   来源：[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
981. 晚八还在找耳机
   来源：[src/data/cc98.posts.json:418](../src/data/cc98.posts.json#L418)
982. 耳机连上了隔壁桌，我听完了半节陌生人的网课
   来源：[src/data/cc98.posts.json:422](../src/data/cc98.posts.json#L422)
983. 26-07-10 16:30
   来源：[src/data/cc98.posts.json:425](../src/data/cc98.posts.json#L425)
984. 戴上耳机后发现讲课内容完全听不懂，还以为自己选错了章节。直到隔壁同学抬头问谁连到了他的设备，我才发现耳机名字还叫“默认设备”。
   来源：[src/data/cc98.posts.json:426](../src/data/cc98.posts.json#L426)
985. 加入设备小事
   来源：[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)
986. 帖子包含清楚的误连原因和轻松回复
   来源：[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)
987. 今天 16:32
   来源：[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
988. 设备名改成自己看得懂的，图书馆里“默认设备”永远不止一个。
   来源：[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)
989. 今天 16:34
   来源：[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)
990. 我连过一段白噪音，找了五分钟才知道声音来自隔壁的平板。
   来源：[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)
991. 陌生课程听不懂先别怀疑自己，先看蓝牙名称。
   来源：[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)
992. 搬寝室清库存
   来源：[src/data/cc98.posts.json:437](../src/data/cc98.posts.json#L437)
993. 二手市场
   来源：[src/data/cc98.posts.json:440](../src/data/cc98.posts.json#L440)；[src/scenes/phone/P02_CC98/index.tsx:203](../src/scenes/phone/P02_CC98/index.tsx#L203)
994. 出一盏可调光台灯，限校内当面自取
   来源：[src/data/cc98.posts.json:441](../src/data/cc98.posts.json#L441)
995. 26-07-10 16:26
   来源：[src/data/cc98.posts.json:444](../src/data/cc98.posts.json#L444)
996. 台灯用了两学期，触控和调光都正常，电源线在。只约公共区域当面试亮，想要的带上能确认时间的人再联系。
   来源：[src/data/cc98.posts.json:445](../src/data/cc98.posts.json#L445)
997. 补充交易边界
   来源：[src/data/cc98.posts.json:446](../src/data/cc98.posts.json#L446)
998. 二手市场提醒员
   来源：[src/data/cc98.posts.json:446](../src/data/cc98.posts.json#L446)
999. 楼主提供了物品状态、交接方式和试用条件
   来源：[src/data/cc98.posts.json:446](../src/data/cc98.posts.json#L446)
1000. 今天 16:28
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)
1001. 能拍一下最低档亮度吗，晚上看屏幕怕太刺眼。
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)
1002. 询问
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)
1003. 当面先试灯和接口，转账后再发现少线会很麻烦。
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)
1004. 今天 16:30
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)
1005. 规范
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
1006. 物品状态、地点和时间写清楚，楼里就不用反复问同一件事。
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
1007. 实验服忘带了
   来源：[src/data/cc98.posts.json:456](../src/data/cc98.posts.json#L456)
1008. 实验课前十分钟才想起实验服还晾在阳台
   来源：[src/data/cc98.posts.json:460](../src/data/cc98.posts.json#L460)
1009. 26-07-10 16:22
   来源：[src/data/cc98.posts.json:463](../src/data/cc98.posts.json#L463)
1010. 一路跑到楼下才发现雨把衣服晾得很有弹性，赶到实验楼时正好听见老师点名。今天的经验是：把实验服放进包里，不要相信早上临出门的自己。
   来源：[src/data/cc98.posts.json:464](../src/data/cc98.posts.json#L464)
1011. 内容为个人经历和防漏清单，没有课程资料需求
   来源：[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
1012. 收录课前小事
   来源：[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
1013. 今天 16:24
   来源：[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)；[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)
1014. 我把实验鞋带成了拖鞋，进楼前才发现鞋底不对。
   来源：[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)
1015. 今天 16:26
   来源：[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)
1016. 清单
   来源：[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)
1017. 实验服、护目镜、笔，前一晚放门边最省心。
   来源：[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)
1018. 跑到门口才想起来实验服在包里的人，今天也不少。
   来源：[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)
1019. 取件码忘带
   来源：[src/data/cc98.posts.json:475](../src/data/cc98.posts.json#L475)
1020. 校园卡绑定旧手机后，门禁旁边怎么重新核验
   来源：[src/data/cc98.posts.json:479](../src/data/cc98.posts.json#L479)
1021. 26-07-10 16:18
   来源：[src/data/cc98.posts.json:482](../src/data/cc98.posts.json#L482)
1022. 换手机后旧设备还留着绑定信息，今天在门禁旁的机器上重新核验才恢复正常。先确认新手机能打开校园卡页面，再去现场操作会少跑一趟。
   来源：[src/data/cc98.posts.json:483](../src/data/cc98.posts.json#L483)
1023. 标记设备换绑记录
   来源：[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
1024. 楼主给出了换机后的现场验证步骤
   来源：[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
1025. 今天 16:20
   来源：[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)；[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)
1026. 旧手机还在时先退出绑定，之后换新机更容易确认。
   来源：[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)
1027. 今天 16:22
   来源：[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)
1028. 我先去图书馆门口试了一次，失败后再去机器核验就通过了。
   来源：[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)
1029. 换机当天留下新设备的验证结果，进楼前先试一次。
   来源：[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)
1030. 窗边那排空着
   来源：[src/data/cc98.posts.json:494](../src/data/cc98.posts.json#L494)
1031. 晚课结束后有人愿意一起占四人桌写作业吗
   来源：[src/data/cc98.posts.json:498](../src/data/cc98.posts.json#L498)
1032. 26-07-10 16:14
   来源：[src/data/cc98.posts.json:501](../src/data/cc98.posts.json#L501)
1033. 想找两三个人在麦斯威把作业写完，各做各的，不开外放。九点前如果位置满了就散，带电脑的优先坐有插座那侧。
   来源：[src/data/cc98.posts.json:502](../src/data/cc98.posts.json#L502)
1034. 保留临时约伴帖
   来源：[src/data/cc98.posts.json:503](../src/data/cc98.posts.json#L503)
1035. 时间、地点和自习规则已经写明
   来源：[src/data/cc98.posts.json:503](../src/data/cc98.posts.json#L503)
1036. 报名
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)
1037. 今天 16:16
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)；[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)
1038. 我带耳机和插线板，七点四十左右到。
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)
1039. 今天 16:18
   来源：[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)
1040. 能保证不讨论题目吗，我有一份报告要赶。
   来源：[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)
1041. 第一次见面选公共区域，离开前把桌面收好。
   来源：[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)
1042. 西门等外卖
   来源：[src/data/cc98.posts.json:513](../src/data/cc98.posts.json#L513)
1043. 我给外卖备注“蓝色外套”，结果门口站了七个蓝色外套
   来源：[src/data/cc98.posts.json:517](../src/data/cc98.posts.json#L517)
1044. 26-07-10 16:10
   来源：[src/data/cc98.posts.json:520](../src/data/cc98.posts.json#L520)
1045. 骑手问谁是蓝色外套，我举手后旁边也举起六只手。最后靠备注里的饮料口味找到了自己的那一袋。
   来源：[src/data/cc98.posts.json:521](../src/data/cc98.posts.json#L521)
1046. 加入校园小场面
   来源：[src/data/cc98.posts.json:522](../src/data/cc98.posts.json#L522)
1047. 主题来自公共取餐区的日常误会
   来源：[src/data/cc98.posts.json:522](../src/data/cc98.posts.json#L522)
1048. 今天 16:12
   来源：[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)；[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
1049. 下次备注鞋子颜色，蓝色外套在雨天没有辨识度。
   来源：[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)
1050. 今天 16:14
   来源：[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)
1051. 我写过“背电脑包”，门口每个人都背着。
   来源：[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)
1052. 饮料口味和取餐码比穿什么可靠。
   来源：[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)
1053. 卡套夹住了
   来源：[src/data/cc98.posts.json:532](../src/data/cc98.posts.json#L532)
1054. 教学楼一楼窗台上有一张校园卡，卡套是深绿色的
   来源：[src/data/cc98.posts.json:536](../src/data/cc98.posts.json#L536)
1055. 26-07-10 16:06
   来源：[src/data/cc98.posts.json:539](../src/data/cc98.posts.json#L539)
1056. 卡放在一楼饮水机旁的窗台上，深绿色卡套边缘有磨损。我没有移动，失主到场后先核对姓名和卡面照片再拿。
   来源：[src/data/cc98.posts.json:540](../src/data/cc98.posts.json#L540)
1057. 保留现场位置
   来源：[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
1058. 物品特征、所在位置和核对方式完整
   来源：[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
1059. 别把卡号完整发出来，能让失主自己说明卡套细节更稳妥。
   来源：[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)
1060. 今天 16:08
   来源：[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)；[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)
1061. 今天 16:10
   来源：[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)
1062. 饮水机旁人来人往，没找到失主就交到门卫处。
   来源：[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)
1063. 现场物品只写辨识特征，不公开完整个人信息。
   来源：[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
1064. 三号窗口观察员
   来源：[src/data/cc98.posts.json:551](../src/data/cc98.posts.json#L551)
1065. 东二三号窗口今天的队伍为什么总会停一下
   来源：[src/data/cc98.posts.json:555](../src/data/cc98.posts.json#L555)
1066. 26-07-10 16:02
   来源：[src/data/cc98.posts.json:558](../src/data/cc98.posts.json#L558)
1067. 排队时看见前面的人都会在付款页找半天，原来是当天的套餐入口换了位置。点餐前先看屏幕底部一行，队伍会走得快一点。
   来源：[src/data/cc98.posts.json:559](../src/data/cc98.posts.json#L559)
1068. 补充点餐界面变化
   来源：[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
1069. 帖子说明了排队变慢的具体原因
   来源：[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
1070. 今天 16:04
   来源：[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
1071. 我刚去过，先选套餐再选饭，顺序和昨天不一样。
   来源：[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
1072. 今天 16:06
   来源：[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)
1073. 屏幕前别临时问朋友吃什么，后面的人会一起停住。
   来源：[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)
1074. 入口变化时把步骤写清楚，下一位就少等一会儿。
   来源：[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)
1075. 时间戳和打印队都要记清。
   来源：[src/data/cc98.thread-personas.json:2](../src/data/cc98.thread-personas.json#L2)
1076. 晚八点打印机
   来源：[src/data/cc98.thread-personas.json:2](../src/data/cc98.thread-personas.json#L2)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:41](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L41)
1077. 路过带图，顺手报告风向和人流。
   来源：[src/data/cc98.thread-personas.json:3](../src/data/cc98.thread-personas.json#L3)
1078. 玉泉风很大
   来源：[src/data/cc98.thread-personas.json:3](../src/data/cc98.thread-personas.json#L3)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:51](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L51)
1079. 盯着座位、插座和没人取走的东西。
   来源：[src/data/cc98.thread-personas.json:4](../src/data/cc98.thread-personas.json#L4)
1080. 二南插座观察员
   来源：[src/data/cc98.thread-personas.json:4](../src/data/cc98.thread-personas.json#L4)
1081. 每天经过求是潮，偶尔能走出去。
   来源：[src/data/cc98.thread-personas.json:5](../src/data/cc98.thread-personas.json#L5)
1082. 求是潮逆行者
   来源：[src/data/cc98.thread-personas.json:5](../src/data/cc98.thread-personas.json#L5)
1083. 六分钱富豪
   来源：[src/data/cc98.thread-personas.json:6](../src/data/cc98.thread-personas.json#L6)
1084. 余额 0.06 元，账目记录完整。
   来源：[src/data/cc98.thread-personas.json:6](../src/data/cc98.thread-personas.json#L6)
1085. 没有审核权限，只保留证据和结论。
   来源：[src/data/cc98.thread-personas.json:7](../src/data/cc98.thread-personas.json#L7)
1086. 紫金港野生审核员
   来源：[src/data/cc98.thread-personas.json:7](../src/data/cc98.thread-personas.json#L7)
1087. narrator
   来源：[src/data/dialogue.lines.json:5](../src/data/dialogue.lines.json#L5)；[src/data/storyLines.ts:46](../src/data/storyLines.ts#L46)
1088. 你没有5分钟了，但你很有勇气
   来源：[src/data/dialogue.lines.json:6](../src/data/dialogue.lines.json#L6)
1089. xiaoying
   来源：[src/data/dialogue.lines.json:16](../src/data/dialogue.lines.json#L16)；[src/data/dialogue.lines.json:27](../src/data/dialogue.lines.json#L27)；[src/data/dialogue.lines.json:38](../src/data/dialogue.lines.json#L38)；[src/data/dialogue.lines.json:71](../src/data/dialogue.lines.json#L71)；[src/data/dialogue.lines.json:93](../src/data/dialogue.lines.json#L93)；[src/scenes/phone/P14_Wechat/index.tsx:403](../src/scenes/phone/P14_Wechat/index.tsx#L403)
1090. 起床蠢货！！！
   来源：[src/data/dialogue.lines.json:17](../src/data/dialogue.lines.json#L17)
1091. 等等等等，你想翘课？没门！我不会让你签上的！
   来源：[src/data/dialogue.lines.json:28](../src/data/dialogue.lines.json#L28)
1092. 找你的数字去吧哈哈哈
   来源：[src/data/dialogue.lines.json:39](../src/data/dialogue.lines.json#L39)；[src/scenes/phone/P14_Wechat/index.tsx:990](../src/scenes/phone/P14_Wechat/index.tsx#L990)
1093. system
   来源：[src/data/dialogue.lines.json:49](../src/data/dialogue.lines.json#L49)；[src/data/dialogue.lines.json:60](../src/data/dialogue.lines.json#L60)；[src/data/dialogue.lines.json:82](../src/data/dialogue.lines.json#L82)；[src/data/storyLines.ts:46](../src/data/storyLines.ts#L46)；[src/data/storyLines.ts:54](../src/data/storyLines.ts#L54)；[src/scenes/phone/P02_CC98/index.tsx:631](../src/scenes/phone/P02_CC98/index.tsx#L631)；[src/scenes/phone/P02_CC98/index.tsx:782](../src/scenes/phone/P02_CC98/index.tsx#L782)；[src/scenes/phone/P07_Weather/index.tsx:29](../src/scenes/phone/P07_Weather/index.tsx#L29)；[src/scenes/phone/P07_Weather/index.tsx:41](../src/scenes/phone/P07_Weather/index.tsx#L41)；[src/scenes/phone/P07_Weather/index.tsx:45](../src/scenes/phone/P07_Weather/index.tsx#L45)；[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)；[src/scenes/phone/P07_Weather/index.tsx:60](../src/scenes/phone/P07_Weather/index.tsx#L60)；[src/scenes/phone/P07_Weather/index.tsx:63](../src/scenes/phone/P07_Weather/index.tsx#L63)；[src/scenes/phone/P13_PhoneHome/index.tsx:214](../src/scenes/phone/P13_PhoneHome/index.tsx#L214)；[src/scenes/phone/P13_PhoneHome/index.tsx:337](../src/scenes/phone/P13_PhoneHome/index.tsx#L337)；[src/scenes/phone/P13_PhoneHome/index.tsx:341](../src/scenes/phone/P13_PhoneHome/index.tsx#L341)；[src/scenes/phone/P14_Wechat/index.tsx:349](../src/scenes/phone/P14_Wechat/index.tsx#L349)；[src/scenes/phone/P14_Wechat/index.tsx:355](../src/scenes/phone/P14_Wechat/index.tsx#L355)；[src/scenes/phone/P14_Wechat/index.tsx:419](../src/scenes/phone/P14_Wechat/index.tsx#L419)；[src/scenes/phone/P14_Wechat/index.tsx:423](../src/scenes/phone/P14_Wechat/index.tsx#L423)；[src/scenes/phone/P14_Wechat/index.tsx:506](../src/scenes/phone/P14_Wechat/index.tsx#L506)；[src/scenes/phone/P15_Zjuding/index.tsx:71](../src/scenes/phone/P15_Zjuding/index.tsx#L71)；[src/scenes/phone/P15_Zjuding/index.tsx:73](../src/scenes/phone/P15_Zjuding/index.tsx#L73)；[src/scenes/phone/P15_Zjuding/index.tsx:74](../src/scenes/phone/P15_Zjuding/index.tsx#L74)；[src/scenes/phone/P15_Zjuding/index.tsx:75](../src/scenes/phone/P15_Zjuding/index.tsx#L75)；[src/scenes/phone/P15_Zjuding/index.tsx:78](../src/scenes/phone/P15_Zjuding/index.tsx#L78)；[src/scenes/phone/P15_Zjuding/index.tsx:80](../src/scenes/phone/P15_Zjuding/index.tsx#L80)；[src/scenes/phone/P15_Zjuding/index.tsx:81](../src/scenes/phone/P15_Zjuding/index.tsx#L81)；[src/scenes/phone/P15_Zjuding/index.tsx:84](../src/scenes/phone/P15_Zjuding/index.tsx#L84)；[src/scenes/phone/P15_Zjuding/index.tsx:86](../src/scenes/phone/P15_Zjuding/index.tsx#L86)；[src/scenes/phone/P15_Zjuding/index.tsx:87](../src/scenes/phone/P15_Zjuding/index.tsx#L87)；[src/scenes/phone/P15_Zjuding/index.tsx:88](../src/scenes/phone/P15_Zjuding/index.tsx#L88)；[src/scenes/phone/P15_Zjuding/index.tsx:89](../src/scenes/phone/P15_Zjuding/index.tsx#L89)；[src/scenes/phone/P15_Zjuding/index.tsx:92](../src/scenes/phone/P15_Zjuding/index.tsx#L92)；[src/scenes/phone/P15_Zjuding/index.tsx:93](../src/scenes/phone/P15_Zjuding/index.tsx#L93)；[src/scenes/phone/P15_Zjuding/index.tsx:94](../src/scenes/phone/P15_Zjuding/index.tsx#L94)；[src/scenes/phone/P15_Zjuding/index.tsx:95](../src/scenes/phone/P15_Zjuding/index.tsx#L95)；[src/scenes/phone/P15_Zjuding/index.tsx:621](../src/scenes/phone/P15_Zjuding/index.tsx#L621)；[src/scenes/phone/P15_Zjuding/index.tsx:636](../src/scenes/phone/P15_Zjuding/index.tsx#L636)；[src/scenes/phone/P15_Zjuding/index.tsx:666](../src/scenes/phone/P15_Zjuding/index.tsx#L666)；[src/scenes/phone/P15_Zjuding/index.tsx:759](../src/scenes/phone/P15_Zjuding/index.tsx#L759)；[src/scenes/phone/P15_Zjuding/index.tsx:923](../src/scenes/phone/P15_Zjuding/index.tsx#L923)；[src/scenes/phone/P15_Zjuding/index.tsx:1049](../src/scenes/phone/P15_Zjuding/index.tsx#L1049)；[src/scenes/rpg/BootScene.ts:205](../src/scenes/rpg/BootScene.ts#L205)；[src/scenes/rpg/BootScene.ts:207](../src/scenes/rpg/BootScene.ts#L207)；[src/scenes/rpg/BootScene.ts:615](../src/scenes/rpg/BootScene.ts#L615)
1094. 余额暂时不足以购买尊严
   来源：[src/data/dialogue.lines.json:50](../src/data/dialogue.lines.json#L50)
1095. 校园网已经尽力了，你也是
   来源：[src/data/dialogue.lines.json:61](../src/data/dialogue.lines.json#L61)
1096. 我知道你没钱买流量
   来源：[src/data/dialogue.lines.json:72](../src/data/dialogue.lines.json#L72)
1097. 就差一次，真绝望
   来源：[src/data/dialogue.lines.json:83](../src/data/dialogue.lines.json#L83)
1098. 哈，一个废齿轮
   来源：[src/data/dialogue.lines.json:94](../src/data/dialogue.lines.json#L94)
1099. 022 临时离座留言
   来源：[src/data/itemCatalog.ts:30](../src/data/itemCatalog.ts#L30)
1100. 022 · 二楼南区
   来源：[src/data/itemCatalog.ts:32](../src/data/itemCatalog.ts#L32)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:138](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L138)
1101. 离开时长
   来源：[src/data/itemCatalog.ts:33](../src/data/itemCatalog.ts#L33)
1102. 三分钟
   来源：[src/data/itemCatalog.ts:33](../src/data/itemCatalog.ts#L33)
1103. 留言状态
   来源：[src/data/itemCatalog.ts:34](../src/data/itemCatalog.ts#L34)
1104. 仍在占用
   来源：[src/data/itemCatalog.ts:34](../src/data/itemCatalog.ts#L34)
1105. 本人离开三分钟，精神仍在座位上。
   来源：[src/data/itemCatalog.ts:36](../src/data/itemCatalog.ts#L36)
1106. 临时离座规则详见 CC98。
   来源：[src/data/itemCatalog.ts:36](../src/data/itemCatalog.ts#L36)
1107. 纸张边缘留有反复折叠痕迹。
   来源：[src/data/itemCatalog.ts:37](../src/data/itemCatalog.ts#L37)
1108. 馆藏定位单
   来源：[src/data/itemCatalog.ts:40](../src/data/itemCatalog.ts#L40)
1109. 《三分钟离座法及其例外》
   来源：[src/data/itemCatalog.ts:42](../src/data/itemCatalog.ts#L42)
1110. 书名
   来源：[src/data/itemCatalog.ts:42](../src/data/itemCatalog.ts#L42)；[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
1111. 索书号
   来源：[src/data/itemCatalog.ts:43](../src/data/itemCatalog.ts#L43)
1112. 馆藏位置
   来源：[src/data/itemCatalog.ts:44](../src/data/itemCatalog.ts#L44)
1113. 基础馆文学书架 · 755 段
   来源：[src/data/itemCatalog.ts:44](../src/data/itemCatalog.ts#L44)
1114. 本条目为旧版规定的馆内定位线索。
   来源：[src/data/itemCatalog.ts:46](../src/data/itemCatalog.ts#L46)
1115. 状态：仅馆内查阅。
   来源：[src/data/itemCatalog.ts:47](../src/data/itemCatalog.ts#L47)
1116. 旧版临时离座恢复规定
   来源：[src/data/itemCatalog.ts:50](../src/data/itemCatalog.ts#L50)
1117. 版本
   来源：[src/data/itemCatalog.ts:52](../src/data/itemCatalog.ts#L52)
1118. 期末周修订版 · 已归档
   来源：[src/data/itemCatalog.ts:52](../src/data/itemCatalog.ts#L52)
1119. 适用范围
   来源：[src/data/itemCatalog.ts:53](../src/data/itemCatalog.ts#L53)
1120. 座位被非本人随身物持续占用
   来源：[src/data/itemCatalog.ts:53](../src/data/itemCatalog.ts#L53)
1121. 目标座位
   来源：[src/data/itemCatalog.ts:54](../src/data/itemCatalog.ts#L54)
1122. 恢复申请须同时具备三类证明：
   来源：[src/data/itemCatalog.ts:57](../src/data/itemCatalog.ts#L57)
1123. 一、本人确实到馆；
   来源：[src/data/itemCatalog.ts:58](../src/data/itemCatalog.ts#L58)
1124. 二、目标座位与凭据一致；
   来源：[src/data/itemCatalog.ts:59](../src/data/itemCatalog.ts#L59)
1125. 三、当前占用物不具备本人身份。
   来源：[src/data/itemCatalog.ts:60](../src/data/itemCatalog.ts#L60)
1126. 规则依据须先完成公开公示。
   来源：[src/data/itemCatalog.ts:62](../src/data/itemCatalog.ts#L62)
1127. 对象类型
   来源：[src/data/itemCatalog.ts:67](../src/data/itemCatalog.ts#L67)
1128. 双肩书包
   来源：[src/data/itemCatalog.ts:67](../src/data/itemCatalog.ts#L67)
1129. 未识别
   来源：[src/data/itemCatalog.ts:68](../src/data/itemCatalog.ts#L68)；[src/data/itemCatalog.ts:69](../src/data/itemCatalog.ts#L69)
1130. 姓名
   来源：[src/data/itemCatalog.ts:68](../src/data/itemCatalog.ts#L68)；[src/scenes/phone/P15_Zjuding/index.tsx:1268](../src/scenes/phone/P15_Zjuding/index.tsx#L1268)；[src/scenes/phone/P15_Zjuding/index.tsx:1334](../src/scenes/phone/P15_Zjuding/index.tsx#L1334)
1131. 学号
   来源：[src/data/itemCatalog.ts:69](../src/data/itemCatalog.ts#L69)；[src/scenes/phone/P15_Zjuding/index.tsx:1272](../src/scenes/phone/P15_Zjuding/index.tsx#L1272)；[src/scenes/phone/P15_Zjuding/index.tsx:1346](../src/scenes/phone/P15_Zjuding/index.tsx#L1346)
1132. 识别结果
   来源：[src/data/itemCatalog.ts:70](../src/data/itemCatalog.ts#L70)
1133. 未检测到可签到主体
   来源：[src/data/itemCatalog.ts:70](../src/data/itemCatalog.ts#L70)
1134. 检测到大量期末周使用痕迹。
   来源：[src/data/itemCatalog.ts:72](../src/data/itemCatalog.ts#L72)
1135. 身份结论需由馆内前台工作人员确认。
   来源：[src/data/itemCatalog.ts:72](../src/data/itemCatalog.ts#L72)
1136. 报告状态：待盖章。
   来源：[src/data/itemCatalog.ts:73](../src/data/itemCatalog.ts#L73)
1137. 022 座位占用书包
   来源：[src/data/itemCatalog.ts:78](../src/data/itemCatalog.ts#L78)
1138. 对象
   来源：[src/data/itemCatalog.ts:78](../src/data/itemCatalog.ts#L78)
1139. 非本人
   来源：[src/data/itemCatalog.ts:79](../src/data/itemCatalog.ts#L79)
1140. 认证结论
   来源：[src/data/itemCatalog.ts:79](../src/data/itemCatalog.ts#L79)
1141. 无 / 无
   来源：[src/data/itemCatalog.ts:80](../src/data/itemCatalog.ts#L80)
1142. 姓名 / 学号
   来源：[src/data/itemCatalog.ts:80](../src/data/itemCatalog.ts#L80)
1143. 盖章来源
   来源：[src/data/itemCatalog.ts:81](../src/data/itemCatalog.ts#L81)
1144. 基础馆物品身份盖章机
   来源：[src/data/itemCatalog.ts:81](../src/data/itemCatalog.ts#L81)
1145. 该物品不具备独立占用座位的身份条件。
   来源：[src/data/itemCatalog.ts:83](../src/data/itemCatalog.ts#L83)
1146. 电子章：基础馆失物身份登记。
   来源：[src/data/itemCatalog.ts:84](../src/data/itemCatalog.ts#L84)
1147. 022 座位凭据
   来源：[src/data/itemCatalog.ts:90](../src/data/itemCatalog.ts#L90)
1148. 座位编号
   来源：[src/data/itemCatalog.ts:92](../src/data/itemCatalog.ts#L92)
1149. 二楼南区
   来源：[src/data/itemCatalog.ts:93](../src/data/itemCatalog.ts#L93)
1150. 区域
   来源：[src/data/itemCatalog.ts:93](../src/data/itemCatalog.ts#L93)；[src/scenes/phone/P15_Zjuding/index.tsx:416](../src/scenes/phone/P15_Zjuding/index.tsx#L416)
1151. 离座中 · 待公示
   来源：[src/data/itemCatalog.ts:95](../src/data/itemCatalog.ts#L95)
1152. 凭据状态
   来源：[src/data/itemCatalog.ts:95](../src/data/itemCatalog.ts#L95)
1153. 当前占用物：书包。
   来源：[src/data/itemCatalog.ts:97](../src/data/itemCatalog.ts#L97)
1154. 恢复处理需提交论坛公示。
   来源：[src/data/itemCatalog.ts:97](../src/data/itemCatalog.ts#L97)
1155. 凭据来源：022 桌面夹缝。
   来源：[src/data/itemCatalog.ts:98](../src/data/itemCatalog.ts#L98)
1156. 7 分钟
   来源：[src/data/itemCatalog.ts:106](../src/data/itemCatalog.ts#L106)
1157. 到馆时长
   来源：[src/data/itemCatalog.ts:106](../src/data/itemCatalog.ts#L106)
1158. 公示编号
   来源：[src/data/itemCatalog.ts:107](../src/data/itemCatalog.ts#L107)
1159. 证明数量
   来源：[src/data/itemCatalog.ts:108](../src/data/itemCatalog.ts#L108)
1160. 补录成功
   来源：[src/data/itemCatalog.ts:109](../src/data/itemCatalog.ts#L109)
1161. 记录状态
   来源：[src/data/itemCatalog.ts:109](../src/data/itemCatalog.ts#L109)
1162. 访问轨迹与 022 座位凭据的时间记录一致。
   来源：[src/data/itemCatalog.ts:111](../src/data/itemCatalog.ts#L111)
1163. 签发来源：浙大体艺访问记录补录。
   来源：[src/data/itemCatalog.ts:112](../src/data/itemCatalog.ts#L112)
1164. 适用座位
   来源：[src/data/itemCatalog.ts:120](../src/data/itemCatalog.ts#L120)
1165. 处理目标
   来源：[src/data/itemCatalog.ts:121](../src/data/itemCatalog.ts#L121)
1166. 非本人占用书包
   来源：[src/data/itemCatalog.ts:121](../src/data/itemCatalog.ts#L121)
1167. 单次有效
   来源：[src/data/itemCatalog.ts:122](../src/data/itemCatalog.ts#L122)
1168. 有效状态
   来源：[src/data/itemCatalog.ts:122](../src/data/itemCatalog.ts#L122)
1169. 已完成公开公示与三项恢复材料核验。
   来源：[src/data/itemCatalog.ts:124](../src/data/itemCatalog.ts#L124)
1170. 仅对登记为非本人的占用物有效。
   来源：[src/data/itemCatalog.ts:125](../src/data/itemCatalog.ts#L125)
1171. 取餐号
   来源：[src/data/itemCatalog.ts:140](../src/data/itemCatalog.ts#L140)
1172. 请取餐
   来源：[src/data/itemCatalog.ts:141](../src/data/itemCatalog.ts#L141)
1173. 状态
   来源：[src/data/itemCatalog.ts:141](../src/data/itemCatalog.ts#L141)；[src/data/itemCatalog.ts:165](../src/data/itemCatalog.ts#L165)
1174. 一张从点餐机吐出来的小票。
   来源：[src/data/itemCatalog.ts:143](../src/data/itemCatalog.ts#L143)
1175. 它证明你认真排过队，也认真被骗进流程。
   来源：[src/data/itemCatalog.ts:144](../src/data/itemCatalog.ts#L144)
1176. 边角湿润
   来源：[src/data/itemCatalog.ts:165](../src/data/itemCatalog.ts#L165)
1177. 纸条这次没有留下连续脚印。
   来源：[src/data/itemCatalog.ts:169](../src/data/itemCatalog.ts#L169)
1178. 潮湿痕迹只能说明它经过了有水的地方。
   来源：[src/data/itemCatalog.ts:170](../src/data/itemCatalog.ts#L170)
1179. 仍需从不同来源核对地点特征。
   来源：[src/data/itemCatalog.ts:171](../src/data/itemCatalog.ts#L171)
1180. 边角湿得很有方向感。
   来源：[src/data/itemCatalog.ts:173](../src/data/itemCatalog.ts#L173)
1181. 暗色细节
   来源：[src/data/itemCatalog.ts:185](../src/data/itemCatalog.ts#L185)
1182. 湖面左侧 / 桥影下方 / 亮点偏右
   来源：[src/data/itemCatalog.ts:185](../src/data/itemCatalog.ts#L185)
1183. 浅色细节
   来源：[src/data/itemCatalog.ts:186](../src/data/itemCatalog.ts#L186)
1184. 右侧路灯杆
   来源：[src/data/itemCatalog.ts:186](../src/data/itemCatalog.ts#L186)
1185. 两种模式记录的是同一个位置。
   来源：[src/data/itemCatalog.ts:188](../src/data/itemCatalog.ts#L188)
1186. 来源：启真湖倒影指示牌。
   来源：[src/data/itemCatalog.ts:189](../src/data/itemCatalog.ts#L189)
1187. 耳机背面的凹处已经装水，可用于完成盆栽浇水。
   来源：[src/data/items.config.json:19](../src/data/items.config.json#L19)
1188. 右向箭头
   来源：[src/data/items.config.json:81](../src/data/items.config.json#L81)
1189. 旧版离座规则
   来源：[src/data/items.config.json:109](../src/data/items.config.json#L109)；[src/data/presentation-cues.ts:125](../src/data/presentation-cues.ts#L125)
1190. 解除占座 PASS
   来源：[src/data/items.config.json:144](../src/data/items.config.json#L144)；[src/data/presentation-cues.ts:192](../src/data/presentation-cues.ts#L192)
1191. 从寝室书桌上拿来的吹风机。天气页面正在等待它处理启真湖的云层。
   来源：[src/data/items.config.json:334](../src/data/items.config.json#L334)
1192. 小鲤鱼
   来源：[src/data/items.config.json:389](../src/data/items.config.json#L389)
1193. 用鱼食引到钓点的小鲤鱼，暂时保持活性。
   来源：[src/data/items.config.json:390](../src/data/items.config.json#L390)
1194. 天鹅磁铁
   来源：[src/data/items.config.json:396](../src/data/items.config.json#L396)
1195. 黑天鹅带回的小型磁铁，可固定到钓竿末端。
   来源：[src/data/items.config.json:397](../src/data/items.config.json#L397)
1196. 磁吸钓竿
   来源：[src/data/items.config.json:403](../src/data/items.config.json#L403)
1197. 安装磁吸附件的钓竿，可接近夹在金属结构上的纸张。
   来源：[src/data/items.config.json:404](../src/data/items.config.json#L404)
1198. 签到记录纸条
   来源：[src/data/items.config.json:410](../src/data/items.config.json#L410)
1199. 它跑得比证明快。签到时需要和校园卡一起使用。
   来源：[src/data/items.config.json:411](../src/data/items.config.json#L411)
1200. 旧时针
   来源：[src/data/items.config.json:417](../src/data/items.config.json#L417)
1201. 它绕了半栋楼，最后混进了刚出炉的面包。
   来源：[src/data/items.config.json:418](../src/data/items.config.json#L418)
1202. 钟面定位片
   来源：[src/data/items.config.json:424](../src/data/items.config.json#L424)
1203. 透明塑料片，边缘有两条短刻度。它知道 7 和 55 本来该站在哪里。
   来源：[src/data/items.config.json:425](../src/data/items.config.json#L425)
1204. 短撬棍
   来源：[src/data/items.config.json:431](../src/data/items.config.json#L431)
1205. 够短，刚好能撬开别人不想让你看的缝。
   来源：[src/data/items.config.json:432](../src/data/items.config.json#L432)
1206. 通用润滑油
   来源：[src/data/items.config.json:438](../src/data/items.config.json#L438)
1207. 它解决不了人生问题，但能让卡死的东西承认自己还会转。
   来源：[src/data/items.config.json:439](../src/data/items.config.json#L439)
1208. 最后一分钟
   来源：[src/data/items.config.json:445](../src/data/items.config.json#L445)
1209. 一分钟。不多，但足够签到。
   来源：[src/data/items.config.json:446](../src/data/items.config.json#L446)
1210. 窗边豆浆
   来源：[src/data/phonePhotoCatalog.ts:41](../src/data/phonePhotoCatalog.ts#L41)
1211. 高数草稿还摊在桌上，豆浆已经冷了。
   来源：[src/data/phonePhotoCatalog.ts:44](../src/data/phonePhotoCatalog.ts#L44)
1212. 06月18日 08:43
   来源：[src/data/phonePhotoCatalog.ts:45](../src/data/phonePhotoCatalog.ts#L45)
1213. 基础馆
   来源：[src/data/phonePhotoCatalog.ts:46](../src/data/phonePhotoCatalog.ts#L46)；[src/data/phonePhotoCatalog.ts:82](../src/data/phonePhotoCatalog.ts#L82)；[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
1214. 寝室晚饭
   来源：[src/data/phonePhotoCatalog.ts:53](../src/data/phonePhotoCatalog.ts#L53)
1215. 校园卡压着充电线，桌面没有收拾。
   来源：[src/data/phonePhotoCatalog.ts:56](../src/data/phonePhotoCatalog.ts#L56)
1216. 06月19日 19:16
   来源：[src/data/phonePhotoCatalog.ts:57](../src/data/phonePhotoCatalog.ts#L57)
1217. 紫云宿舍
   来源：[src/data/phonePhotoCatalog.ts:58](../src/data/phonePhotoCatalog.ts#L58)
1218. 雨后早餐
   来源：[src/data/phonePhotoCatalog.ts:65](../src/data/phonePhotoCatalog.ts#L65)
1219. 长椅还有水迹，纸袋放在靠内侧。
   来源：[src/data/phonePhotoCatalog.ts:68](../src/data/phonePhotoCatalog.ts#L68)
1220. 06月22日 07:28
   来源：[src/data/phonePhotoCatalog.ts:69](../src/data/phonePhotoCatalog.ts#L69)
1221. 东区
   来源：[src/data/phonePhotoCatalog.ts:70](../src/data/phonePhotoCatalog.ts#L70)
1222. 自习间隙
   来源：[src/data/phonePhotoCatalog.ts:77](../src/data/phonePhotoCatalog.ts#L77)
1223. 面包包装拆了一半，保温杯放在右边。
   来源：[src/data/phonePhotoCatalog.ts:80](../src/data/phonePhotoCatalog.ts#L80)
1224. 06月24日 16:02
   来源：[src/data/phonePhotoCatalog.ts:81](../src/data/phonePhotoCatalog.ts#L81)
1225. 食堂打包
   来源：[src/data/phonePhotoCatalog.ts:89](../src/data/phonePhotoCatalog.ts#L89)
1226. 餐巾纸折在盒饭旁边，桌面很干净。
   来源：[src/data/phonePhotoCatalog.ts:92](../src/data/phonePhotoCatalog.ts#L92)
1227. 06月26日 18:51
   来源：[src/data/phonePhotoCatalog.ts:93](../src/data/phonePhotoCatalog.ts#L93)
1228. 东区食堂
   来源：[src/data/phonePhotoCatalog.ts:94](../src/data/phonePhotoCatalog.ts#L94)；[src/data/phonePhotoCatalog.ts:178](../src/data/phonePhotoCatalog.ts#L178)
1229. 022 旧照
   来源：[src/data/phonePhotoCatalog.ts:101](../src/data/phonePhotoCatalog.ts#L101)
1230. 同一只 022 书包。侧袋里的半包纸，在 07:55 时已经存在。
   来源：[src/data/phonePhotoCatalog.ts:104](../src/data/phonePhotoCatalog.ts#L104)
1231. 06月28日 07:55
   来源：[src/data/phonePhotoCatalog.ts:105](../src/data/phonePhotoCatalog.ts#L105)
1232. 基础馆二楼南区
   来源：[src/data/phonePhotoCatalog.ts:106](../src/data/phonePhotoCatalog.ts#L106)
1233. 校门口的阴天
   来源：[src/data/phonePhotoCatalog.ts:113](../src/data/phonePhotoCatalog.ts#L113)
1234. 树荫压得很低，骑车的人都从拱门边绕过去。
   来源：[src/data/phonePhotoCatalog.ts:116](../src/data/phonePhotoCatalog.ts#L116)
1235. 07月01日 14:32
   来源：[src/data/phonePhotoCatalog.ts:117](../src/data/phonePhotoCatalog.ts#L117)
1236. 启真湖早晨
   来源：[src/data/phonePhotoCatalog.ts:125](../src/data/phonePhotoCatalog.ts#L125)
1237. 浮桥旁有两圈新波纹，车还停在柳树下面。
   来源：[src/data/phonePhotoCatalog.ts:128](../src/data/phonePhotoCatalog.ts#L128)
1238. 07月02日 09:12
   来源：[src/data/phonePhotoCatalog.ts:129](../src/data/phonePhotoCatalog.ts#L129)
1239. 雨后的月牙楼
   来源：[src/data/phonePhotoCatalog.ts:137](../src/data/phonePhotoCatalog.ts#L137)
1240. 地砖还在反光，伞已经可以收起来了。
   来源：[src/data/phonePhotoCatalog.ts:140](../src/data/phonePhotoCatalog.ts#L140)
1241. 07月03日 16:47
   来源：[src/data/phonePhotoCatalog.ts:141](../src/data/phonePhotoCatalog.ts#L141)
1242. 晚自习加餐
   来源：[src/data/phonePhotoCatalog.ts:149](../src/data/phonePhotoCatalog.ts#L149)
1243. 耳机缠在本子边，饭盒还留着一点热气。
   来源：[src/data/phonePhotoCatalog.ts:152](../src/data/phonePhotoCatalog.ts#L152)
1244. 07月05日 21:06
   来源：[src/data/phonePhotoCatalog.ts:153](../src/data/phonePhotoCatalog.ts#L153)
1245. 学习空间
   来源：[src/data/phonePhotoCatalog.ts:154](../src/data/phonePhotoCatalog.ts#L154)
1246. 车筐里的雨衣
   来源：[src/data/phonePhotoCatalog.ts:161](../src/data/phonePhotoCatalog.ts#L161)
1247. 雨停得很快，车筐上还挂着水珠。
   来源：[src/data/phonePhotoCatalog.ts:164](../src/data/phonePhotoCatalog.ts#L164)
1248. 07月06日 12:23
   来源：[src/data/phonePhotoCatalog.ts:165](../src/data/phonePhotoCatalog.ts#L165)
1249. 宿舍区
   来源：[src/data/phonePhotoCatalog.ts:166](../src/data/phonePhotoCatalog.ts#L166)
1250. 午饭排队
   来源：[src/data/phonePhotoCatalog.ts:173](../src/data/phonePhotoCatalog.ts#L173)
1251. 前面只剩三个人，番茄鸡蛋面先端到了。
   来源：[src/data/phonePhotoCatalog.ts:176](../src/data/phonePhotoCatalog.ts#L176)
1252. 07月07日 11:54
   来源：[src/data/phonePhotoCatalog.ts:177](../src/data/phonePhotoCatalog.ts#L177)
1253. 找到道具栏
   来源：[src/data/presentation-cues.ts:34](../src/data/presentation-cues.ts#L34)
1254. 校园地图内出现了可调查的寝室据点
   来源：[src/data/presentation-cues.ts:35](../src/data/presentation-cues.ts#L35)
1255. 箱
   来源：[src/data/presentation-cues.ts:36](../src/data/presentation-cues.ts#L36)
1256. 让地图人物回应你
   来源：[src/data/presentation-cues.ts:42](../src/data/presentation-cues.ts#L42)
1257. 先让寝室里的人知道自己是谁
   来源：[src/data/presentation-cues.ts:43](../src/data/presentation-cues.ts#L43)
1258. 右移箭头已合成
   来源：[src/data/presentation-cues.ts:50](../src/data/presentation-cues.ts#L50)
1259. 它能把一个目标向右移动两格
   来源：[src/data/presentation-cues.ts:51](../src/data/presentation-cues.ts#L51)
1260. 交易完成
   来源：[src/data/presentation-cues.ts:58](../src/data/presentation-cues.ts#L58)
1261. 游戏手柄已放入道具栏
   来源：[src/data/presentation-cues.ts:59](../src/data/presentation-cues.ts#L59)
1262. 可以出门了
   来源：[src/data/presentation-cues.ts:66](../src/data/presentation-cues.ts#L66)；[src/scenes/rpg/RpgGameHost.tsx:1129](../src/scenes/rpg/RpgGameHost.tsx#L1129)
1263. 寝室出口已开放
   来源：[src/data/presentation-cues.ts:67](../src/data/presentation-cues.ts#L67)
1264. 门
   来源：[src/data/presentation-cues.ts:68](../src/data/presentation-cues.ts#L68)
1265. 进入图书馆，找到 022
   来源：[src/data/presentation-cues.ts:74](../src/data/presentation-cues.ts#L74)
1266. 基础图书馆入口已开放
   来源：[src/data/presentation-cues.ts:75](../src/data/presentation-cues.ts#L75)
1267. 入馆记录待核对
   来源：[src/data/presentation-cues.ts:82](../src/data/presentation-cues.ts#L82)
1268. 点击闸机旁的小屏查看两条时间
   来源：[src/data/presentation-cues.ts:83](../src/data/presentation-cues.ts#L83)
1269. 022 被书包占用
   来源：[src/data/presentation-cues.ts:91](../src/data/presentation-cues.ts#L91)
1270. 调查纸条与离座规则
   来源：[src/data/presentation-cues.ts:92](../src/data/presentation-cues.ts#L92)
1271. 获得占座纸条
   来源：[src/data/presentation-cues.ts:100](../src/data/presentation-cues.ts#L100)
1272. 可拖入 CC98 搜索
   来源：[src/data/presentation-cues.ts:101](../src/data/presentation-cues.ts#L101)
1273. 调查帖已找到
   来源：[src/data/presentation-cues.ts:109](../src/data/presentation-cues.ts#L109)
1274. 23 楼内容，5 条 ac01 可选
   来源：[src/data/presentation-cues.ts:110](../src/data/presentation-cues.ts#L110)
1275. 正确馆藏已确认
   来源：[src/data/presentation-cues.ts:117](../src/data/presentation-cues.ts#L117)
1276. 索书号 I247.55 / 755
   来源：[src/data/presentation-cues.ts:118](../src/data/presentation-cues.ts#L118)
1277. 恢复 022 需要三项证明
   来源：[src/data/presentation-cues.ts:126](../src/data/presentation-cues.ts#L126)
1278. 物品识别报告已生成
   来源：[src/data/presentation-cues.ts:134](../src/data/presentation-cues.ts#L134)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:203](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L203)
1279. 对象类型：书包
   来源：[src/data/presentation-cues.ts:135](../src/data/presentation-cues.ts#L135)
1280. 失物招领登记已盖章
   来源：[src/data/presentation-cues.ts:143](../src/data/presentation-cues.ts#L143)
1281. 章
   来源：[src/data/presentation-cues.ts:144](../src/data/presentation-cues.ts#L144)
1282. 右移箭头仍保留在道具栏
   来源：[src/data/presentation-cues.ts:152](../src/data/presentation-cues.ts#L152)
1283. 7 / 47 / 3 补录通过
   来源：[src/data/presentation-cues.ts:161](../src/data/presentation-cues.ts#L161)
1284. 四项证据已公示
   来源：[src/data/presentation-cues.ts:168](../src/data/presentation-cues.ts#L168)
1285. 系统将说明帮顶与四位口令规则
   来源：[src/data/presentation-cues.ts:169](../src/data/presentation-cues.ts#L169)
1286. 进入十大
   来源：[src/data/presentation-cues.ts:176](../src/data/presentation-cues.ts#L176)
1287. 剧情帖排名 01
   来源：[src/data/presentation-cues.ts:177](../src/data/presentation-cues.ts#L177)
1288. 022 恢复申请已开放
   来源：[src/data/presentation-cues.ts:184](../src/data/presentation-cues.ts#L184)
1289. 提交三项恢复证明
   来源：[src/data/presentation-cues.ts:185](../src/data/presentation-cues.ts#L185)
1290. 仅可用于 RPG 中的 022 书包
   来源：[src/data/presentation-cues.ts:193](../src/data/presentation-cues.ts#L193)
1291. 占座对象已转移
   来源：[src/data/presentation-cues.ts:200](../src/data/presentation-cues.ts#L200)
1292. 书包已送往失物招领
   来源：[src/data/presentation-cues.ts:201](../src/data/presentation-cues.ts#L201)
1293. 它正在船尾对准航线。继续交替划桨。
   来源：[src/data/pursuit.audio.content.json:59](../src/data/pursuit.audio.content.json#L59)
1294. It is lining up behind you. Keep alternating.
   来源：[src/data/pursuit.audio.content.json:60](../src/data/pursuit.audio.content.json#L60)
1295. 闹钟
   来源：[src/data/scenes.config.json:2](../src/data/scenes.config.json#L2)
1296. P00
   来源：[src/data/scenes.config.json:2](../src/data/scenes.config.json#L2)
1297. 07:55 起床
   来源：[src/data/scenes.config.json:3](../src/data/scenes.config.json#L3)
1298. P01
   来源：[src/data/scenes.config.json:3](../src/data/scenes.config.json#L3)
1299. 手机主界面
   来源：[src/data/scenes.config.json:4](../src/data/scenes.config.json#L4)
1300. P13
   来源：[src/data/scenes.config.json:4](../src/data/scenes.config.json#L4)
1301. 微信 / 朋友头像谜题
   来源：[src/data/scenes.config.json:5](../src/data/scenes.config.json#L5)
1302. P14
   来源：[src/data/scenes.config.json:5](../src/data/scenes.config.json#L5)
1303. 浙大钉（加载/内页）
   来源：[src/data/scenes.config.json:6](../src/data/scenes.config.json#L6)
1304. P15
   来源：[src/data/scenes.config.json:6](../src/data/scenes.config.json#L6)
1305. 浙大体艺
   来源：[src/data/scenes.config.json:7](../src/data/scenes.config.json#L7)；[src/scenes/phone/P08_Settings/index.tsx:29](../src/scenes/phone/P08_Settings/index.tsx#L29)
1306. P06
   来源：[src/data/scenes.config.json:7](../src/data/scenes.config.json#L7)
1307. 天气 / 水滴谜题
   来源：[src/data/scenes.config.json:8](../src/data/scenes.config.json#L8)
1308. P07
   来源：[src/data/scenes.config.json:8](../src/data/scenes.config.json#L8)
1309. 玩家
   来源：[src/data/storyLines.ts:60](../src/data/storyLines.ts#L60)；[src/scenes/phone/P02_CC98/index.tsx:124](../src/scenes/phone/P02_CC98/index.tsx#L124)
1310. 基础图书馆门前
   来源：[src/demos/campus-map-demo.tsx:32](../src/demos/campus-map-demo.tsx#L32)
1311. 大食堂门前
   来源：[src/demos/campus-map-demo.tsx:33](../src/demos/campus-map-demo.tsx#L33)
1312. 追踪脚印
   来源：[src/demos/campus-map-demo.tsx:46](../src/demos/campus-map-demo.tsx#L46)
1313. 抵达食堂
   来源：[src/demos/campus-map-demo.tsx:47](../src/demos/campus-map-demo.tsx#L47)
1314. 进入食堂
   来源：[src/demos/campus-map-demo.tsx:48](../src/demos/campus-map-demo.tsx#L48)
1315. 寻找异常餐盘
   来源：[src/demos/campus-map-demo.tsx:49](../src/demos/campus-map-demo.tsx#L49)
1316. 调配今日新品
   来源：[src/demos/campus-map-demo.tsx:50](../src/demos/campus-map-demo.tsx#L50)
1317. 破解点餐机
   来源：[src/demos/campus-map-demo.tsx:51](../src/demos/campus-map-demo.tsx#L51)
1318. 寻找 0755 窗口
   来源：[src/demos/campus-map-demo.tsx:52](../src/demos/campus-map-demo.tsx#L52)
1319. 封堵纸条出口
   来源：[src/demos/campus-map-demo.tsx:53](../src/demos/campus-map-demo.tsx#L53)
1320. 准备继续追赶
   来源：[src/demos/campus-map-demo.tsx:54](../src/demos/campus-map-demo.tsx#L54)
1321. 追逐中
   来源：[src/demos/campus-map-demo.tsx:55](../src/demos/campus-map-demo.tsx#L55)
1322. 抵达体艺馆
   来源：[src/demos/campus-map-demo.tsx:56](../src/demos/campus-map-demo.tsx#L56)
1323. 地图加载中…
   来源：[src/demos/campus-map-demo.tsx:168](../src/demos/campus-map-demo.tsx#L168)
1324. 食堂内的纸条已被逼出，已返回大食堂门前。
   来源：[src/demos/campus-map-demo.tsx:224](../src/demos/campus-map-demo.tsx#L224)
1325. 大食堂剧情已重开：已到{{target.label}}，按空格进入。
   来源：[src/demos/campus-map-demo.tsx:358](../src/demos/campus-map-demo.tsx#L358)
1326. 已回到{{target.label}}，当前为自由探索。
   来源：[src/demos/campus-map-demo.tsx:359](../src/demos/campus-map-demo.tsx#L359)
1327. 紫金港校园大地图与大食堂剧情演示
   来源：[src/demos/campus-map-demo.tsx:385](../src/demos/campus-map-demo.tsx#L385)
1328. 校园与大食堂剧情交互区
   来源：[src/demos/campus-map-demo.tsx:388](../src/demos/campus-map-demo.tsx#L388)
1329. 大食堂剧情
   来源：[src/demos/campus-map-demo.tsx:393](../src/demos/campus-map-demo.tsx#L393)；[src/demos/campus-map-demo.tsx:400](../src/demos/campus-map-demo.tsx#L400)
1330. 紫金港校园大地图
   来源：[src/demos/campus-map-demo.tsx:393](../src/demos/campus-map-demo.tsx#L393)
1331. 演示操作
   来源：[src/demos/campus-map-demo.tsx:398](../src/demos/campus-map-demo.tsx#L398)
1332. 自由探索
   来源：[src/demos/campus-map-demo.tsx:399](../src/demos/campus-map-demo.tsx#L399)
1333. 切到深色
   来源：[src/demos/campus-map-demo.tsx:409](../src/demos/campus-map-demo.tsx#L409)
1334. 切回浅色
   来源：[src/demos/campus-map-demo.tsx:409](../src/demos/campus-map-demo.tsx#L409)
1335. 回到角色
   来源：[src/demos/campus-map-demo.tsx:414](../src/demos/campus-map-demo.tsx#L414)
1336. 缩小地图
   来源：[src/demos/campus-map-demo.tsx:415](../src/demos/campus-map-demo.tsx#L415)
1337. 放大地图
   来源：[src/demos/campus-map-demo.tsx:416](../src/demos/campus-map-demo.tsx#L416)
1338. 全屏
   来源：[src/demos/campus-map-demo.tsx:419](../src/demos/campus-map-demo.tsx#L419)
1339. 坐标
   来源：[src/demos/campus-map-demo.tsx:423](../src/demos/campus-map-demo.tsx#L423)
1340. 缩放
   来源：[src/demos/campus-map-demo.tsx:424](../src/demos/campus-map-demo.tsx#L424)
1341. 剧情
   来源：[src/demos/campus-map-demo.tsx:427](../src/demos/campus-map-demo.tsx#L427)
1342. 浅色模式
   来源：[src/demos/campus-map-demo.tsx:428](../src/demos/campus-map-demo.tsx#L428)
1343. 深色模式
   来源：[src/demos/campus-map-demo.tsx:428](../src/demos/campus-map-demo.tsx#L428)
1344. WASD / 方向键移动 · 空格交互 · Tab 切换明暗
   来源：[src/demos/campus-map-demo.tsx:433](../src/demos/campus-map-demo.tsx#L433)
1345. WASD / 方向键移动 · Shift 冲刺 · 空格进入 · 单击路面寻路
   来源：[src/demos/campus-map-demo.tsx:434](../src/demos/campus-map-demo.tsx#L434)
1346. 触控方向与交互
   来源：[src/demos/campus-map-demo.tsx:439](../src/demos/campus-map-demo.tsx#L439)
1347. 向上移动
   来源：[src/demos/campus-map-demo.tsx:440](../src/demos/campus-map-demo.tsx#L440)
1348. 向左移动
   来源：[src/demos/campus-map-demo.tsx:441](../src/demos/campus-map-demo.tsx#L441)
1349. 向下移动
   来源：[src/demos/campus-map-demo.tsx:442](../src/demos/campus-map-demo.tsx#L442)
1350. 向右移动
   来源：[src/demos/campus-map-demo.tsx:443](../src/demos/campus-map-demo.tsx#L443)
1351. 空格
   来源：[src/demos/campus-map-demo.tsx:444](../src/demos/campus-map-demo.tsx#L444)；[src/scenes/rpg/RpgControlHints.ts:6](../src/scenes/rpg/RpgControlHints.ts#L6)
1352. 页面运行出错
   来源：[src/ErrorBoundary.tsx:26](../src/ErrorBoundary.tsx#L26)
1353. 多云
   来源：[src/modules/CampusWeatherModel.ts:5](../src/modules/CampusWeatherModel.ts#L5)；[src/modules/CampusWeatherModel.ts:13](../src/modules/CampusWeatherModel.ts#L13)
1354. 小雨
   来源：[src/modules/CampusWeatherModel.ts:5](../src/modules/CampusWeatherModel.ts#L5)；[src/modules/CampusWeatherModel.ts:11](../src/modules/CampusWeatherModel.ts#L11)
1355. 校名缩写
   来源：[src/modules/Cc98UnifiedLoginModel.ts:11](../src/modules/Cc98UnifiedLoginModel.ts#L11)
1356. 取浙江大学英文名的三个大写字母。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:12](../src/modules/Cc98UnifiedLoginModel.ts#L12)
1357. 校史年份
   来源：[src/modules/Cc98UnifiedLoginModel.ts:17](../src/modules/Cc98UnifiedLoginModel.ts#L17)
1358. 接上求是书院创办的四位年份。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:18](../src/modules/Cc98UnifiedLoginModel.ts#L18)
1359. 结尾标点
   来源：[src/modules/Cc98UnifiedLoginModel.ts:23](../src/modules/Cc98UnifiedLoginModel.ts#L23)
1360. 保留认证公告最后的感叹号。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:24](../src/modules/Cc98UnifiedLoginModel.ts#L24)
1361. already\_authenticated
   来源：[src/modules/Cc98UnifiedLoginModel.ts:76](../src/modules/Cc98UnifiedLoginModel.ts#L76)
1362. identity\_unavailable
   来源：[src/modules/Cc98UnifiedLoginModel.ts:77](../src/modules/Cc98UnifiedLoginModel.ts#L77)
1363. authenticated
   来源：[src/modules/Cc98UnifiedLoginModel.ts:84](../src/modules/Cc98UnifiedLoginModel.ts#L84)
1364. rejected
   来源：[src/modules/Cc98UnifiedLoginModel.ts:89](../src/modules/Cc98UnifiedLoginModel.ts#L89)
1365. both
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1366. password
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1367. student\_id
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1368. network
   来源：[src/modules/CheckinController.ts:19](../src/modules/CheckinController.ts#L19)
1369. wrong\_code
   来源：[src/modules/CheckinController.ts:24](../src/modules/CheckinController.ts#L24)
1370. 磁性钓鱼竿
   来源：[src/modules/InventoryController.ts:18](../src/modules/InventoryController.ts#L18)
1371. developer\_checkpoint\_session
   来源：[src/modules/SaveController.ts:26](../src/modules/SaveController.ts#L26)
1372. 匿名用户
   来源：[src/scenes/phone/P02_CC98/index.tsx:56](../src/scenes/phone/P02_CC98/index.tsx#L56)
1373. 刚刚
   来源：[src/scenes/phone/P02_CC98/index.tsx:63](../src/scenes/phone/P02_CC98/index.tsx#L63)；[src/scenes/phone/P02_CC98/index.tsx:222](../src/scenes/phone/P02_CC98/index.tsx#L222)
1374. 如题。
   来源：[src/scenes/phone/P02_CC98/index.tsx:64](../src/scenes/phone/P02_CC98/index.tsx#L64)
1375. 今天 09:{{String(12 + index \* 2).padStart(2, "0")}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:67](../src/scenes/phone/P02_CC98/index.tsx#L67)
1376. {{\[3, 8, 14\]\[index\]}}楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:68](../src/scenes/phone/P02_CC98/index.tsx#L68)
1377. 今天 {{reply.time}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:95](../src/scenes/phone/P02_CC98/index.tsx#L95)
1378. 今天 08:29
   来源：[src/scenes/phone/P02_CC98/index.tsx:112](../src/scenes/phone/P02_CC98/index.tsx#L112)
1379. 今天 08:30
   来源：[src/scenes/phone/P02_CC98/index.tsx:122](../src/scenes/phone/P02_CC98/index.tsx#L122)
1380. 今天 08:31
   来源：[src/scenes/phone/P02_CC98/index.tsx:133](../src/scenes/phone/P02_CC98/index.tsx#L133)
1381. 网络提示
   来源：[src/scenes/phone/P02_CC98/index.tsx:135](../src/scenes/phone/P02_CC98/index.tsx#L135)
1382. 今天 08:32
   来源：[src/scenes/phone/P02_CC98/index.tsx:144](../src/scenes/phone/P02_CC98/index.tsx#L144)
1383. 系统回执
   来源：[src/scenes/phone/P02_CC98/index.tsx:146](../src/scenes/phone/P02_CC98/index.tsx#L146)
1384. 23 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:169](../src/scenes/phone/P02_CC98/index.tsx#L169)
1385. 【求助】022 座位今日临时离开
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1386. 12 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1387. 来源不匹配：这是今日新帖，纸条引用的是旧版公开记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1388. 来源为今日新帖，没有旧版离座规定的引用。
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1389. 【记录】二南 022 晚间使用情况
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1390. 31 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1391. 发布时间为当日 22:40，早于纸条中的本次离座事件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1392. 时间不匹配：这条记录早于本次 022 占用事件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1393. 【闲聊】二楼南区今天还有位置吗
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1394. 18 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1395. 附件不匹配：这条帖子没有纸条对应的离座凭据。
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1396. 正文提到 022，附件区为空。
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1397. 本月
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1398. 本周
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1399. 发现
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1400. 活动
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1401. 今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)；[src/scenes/phone/P02_CC98/index.tsx:817](../src/scenes/phone/P02_CC98/index.tsx#L817)
1402. 往年今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1403. 新帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:184](../src/scenes/phone/P02_CC98/index.tsx#L184)；[src/scenes/phone/P02_CC98/index.tsx:946](../src/scenes/phone/P02_CC98/index.tsx#L946)
1404. 关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:185](../src/scenes/phone/P02_CC98/index.tsx#L185)；[src/scenes/phone/P02_CC98/index.tsx:906](../src/scenes/phone/P02_CC98/index.tsx#L906)
1405. 版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:186](../src/scenes/phone/P02_CC98/index.tsx#L186)
1406. 校内日常、天气和临时消息
   来源：[src/scenes/phone/P02_CC98/index.tsx:207](../src/scenes/phone/P02_CC98/index.tsx#L207)
1407. 步行、骑行和校内出行
   来源：[src/scenes/phone/P02_CC98/index.tsx:208](../src/scenes/phone/P02_CC98/index.tsx#L208)
1408. 资料、课程和复习讨论
   来源：[src/scenes/phone/P02_CC98/index.tsx:209](../src/scenes/phone/P02_CC98/index.tsx#L209)
1409. 电话卡、网络和通讯服务
   来源：[src/scenes/phone/P02_CC98/index.tsx:210](../src/scenes/phone/P02_CC98/index.tsx#L210)
1410. 馆内规则、座位和设备
   来源：[src/scenes/phone/P02_CC98/index.tsx:211](../src/scenes/phone/P02_CC98/index.tsx#L211)
1411. 自习地点与安静程度
   来源：[src/scenes/phone/P02_CC98/index.tsx:212](../src/scenes/phone/P02_CC98/index.tsx#L212)
1412. 窗口、排队和座位
   来源：[src/scenes/phone/P02_CC98/index.tsx:213](../src/scenes/phone/P02_CC98/index.tsx#L213)
1413. 打印、复印和取件
   来源：[src/scenes/phone/P02_CC98/index.tsx:214](../src/scenes/phone/P02_CC98/index.tsx#L214)
1414. 校园卡使用和服务记录
   来源：[src/scenes/phone/P02_CC98/index.tsx:215](../src/scenes/phone/P02_CC98/index.tsx#L215)
1415. 遗失物和失物信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:216](../src/scenes/phone/P02_CC98/index.tsx#L216)
1416. 闲置物品与当面交易提醒
   来源：[src/scenes/phone/P02_CC98/index.tsx:217](../src/scenes/phone/P02_CC98/index.tsx#L217)
1417. 轻松话题和校园小事
   来源：[src/scenes/phone/P02_CC98/index.tsx:218](../src/scenes/phone/P02_CC98/index.tsx#L218)
1418. 课程与年份入口
   来源：[src/scenes/phone/P02_CC98/index.tsx:269](../src/scenes/phone/P02_CC98/index.tsx#L269)
1419. 先选课程，再按年份进入资料目录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:270](../src/scenes/phone/P02_CC98/index.tsx#L270)
1420. 旧自习讨论
   来源：[src/scenes/phone/P02_CC98/index.tsx:274](../src/scenes/phone/P02_CC98/index.tsx#L274)
1421. 旧帖能核对座位与插座记录，但日期可能已经过期。
   来源：[src/scenes/phone/P02_CC98/index.tsx:275](../src/scenes/phone/P02_CC98/index.tsx#L275)
1422. 今晚仍要现场核验
   来源：[src/scenes/phone/P02_CC98/index.tsx:279](../src/scenes/phone/P02_CC98/index.tsx#L279)
1423. A2 的门牌、房间和通道以今晚实际情况为准。
   来源：[src/scenes/phone/P02_CC98/index.tsx:280](../src/scenes/phone/P02_CC98/index.tsx#L280)
1424. 首页推荐顺序
   来源：[src/scenes/phone/P02_CC98/index.tsx:284](../src/scenes/phone/P02_CC98/index.tsx#L284)
1425. 推荐位会变化，无法作为资料目录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:285](../src/scenes/phone/P02_CC98/index.tsx#L285)
1426. 直接照抄旧路线
   来源：[src/scenes/phone/P02_CC98/index.tsx:289](../src/scenes/phone/P02_CC98/index.tsx#L289)
1427. 旧路线没有记录今晚的封闭入口。
   来源：[src/scenes/phone/P02_CC98/index.tsx:290](../src/scenes/phone/P02_CC98/index.tsx#L290)
1428. accepted
   来源：[src/scenes/phone/P02_CC98/index.tsx:311](../src/scenes/phone/P02_CC98/index.tsx#L311)；[src/scenes/rpg/RpgGameHost.tsx:1123](../src/scenes/rpg/RpgGameHost.tsx#L1123)；[src/scenes/rpg/RpgGameHost.tsx:1207](../src/scenes/rpg/RpgGameHost.tsx#L1207)；[src/scenes/rpg/RpgGameHost.tsx:1235](../src/scenes/rpg/RpgGameHost.tsx#L1235)；[src/scenes/rpg/RpgGameHost.tsx:1243](../src/scenes/rpg/RpgGameHost.tsx#L1243)；[src/scenes/rpg/RpgGameHost.tsx:1255](../src/scenes/rpg/RpgGameHost.tsx#L1255)；[src/scenes/rpg/RpgGameHost.tsx:1268](../src/scenes/rpg/RpgGameHost.tsx#L1268)；[src/scenes/rpg/RpgGameHost.tsx:1293](../src/scenes/rpg/RpgGameHost.tsx#L1293)；[src/scenes/rpg/RpgGameHost.tsx:1303](../src/scenes/rpg/RpgGameHost.tsx#L1303)；[src/scenes/rpg/RpgGameHost.tsx:1310](../src/scenes/rpg/RpgGameHost.tsx#L1310)
1429. already\_complete
   来源：[src/scenes/phone/P02_CC98/index.tsx:313](../src/scenes/phone/P02_CC98/index.tsx#L313)
1430. incorrect
   来源：[src/scenes/phone/P02_CC98/index.tsx:315](../src/scenes/phone/P02_CC98/index.tsx#L315)
1431. 这三项里混进了今晚无法使用的信息。再看一遍帖子和回复。
   来源：[src/scenes/phone/P02_CC98/index.tsx:316](../src/scenes/phone/P02_CC98/index.tsx#L316)
1432. 学习天地资料索引已导入自习群。
   来源：[src/scenes/phone/P02_CC98/index.tsx:323](../src/scenes/phone/P02_CC98/index.tsx#L323)
1433. 筛选并导入学习天地资料
   来源：[src/scenes/phone/P02_CC98/index.tsx:328](../src/scenes/phone/P02_CC98/index.tsx#L328)
1434. 导入前核对
   来源：[src/scenes/phone/P02_CC98/index.tsx:330](../src/scenes/phone/P02_CC98/index.tsx#L330)
1435. 选出今晚还能使用的三项信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:331](../src/scenes/phone/P02_CC98/index.tsx#L331)
1436. 已导入麦斯威夜间自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:357](../src/scenes/phone/P02_CC98/index.tsx#L357)
1437. 从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。
   来源：[src/scenes/phone/P02_CC98/index.tsx:436](../src/scenes/phone/P02_CC98/index.tsx#L436)
1438. 启真湖 · 22:37:05
   来源：[src/scenes/phone/P02_CC98/index.tsx:437](../src/scenes/phone/P02_CC98/index.tsx#L437)
1439. 晚上水面反光挺亮，靠岸别太快。
   来源：[src/scenes/phone/P02_CC98/index.tsx:440](../src/scenes/phone/P02_CC98/index.tsx#L440)
1440. 最后一张图像是朝东边拍的。
   来源：[src/scenes/phone/P02_CC98/index.tsx:441](../src/scenes/phone/P02_CC98/index.tsx#L441)
1441. 本次记录准备结束，选择楼主的最后一条回复。
   来源：[src/scenes/phone/P02_CC98/index.tsx:444](../src/scenes/phone/P02_CC98/index.tsx#L444)
1442. qizhen-summary
   来源：[src/scenes/phone/P02_CC98/index.tsx:448](../src/scenes/phone/P02_CC98/index.tsx#L448)；[src/scenes/phone/P02_CC98/index.tsx:458](../src/scenes/phone/P02_CC98/index.tsx#L458)
1443. 安全返航
   来源：[src/scenes/phone/P02_CC98/index.tsx:452](../src/scenes/phone/P02_CC98/index.tsx#L452)
1444. 船和人都回来了。湖上的事先记到这里，剩下的等我整理。
   来源：[src/scenes/phone/P02_CC98/index.tsx:453](../src/scenes/phone/P02_CC98/index.tsx#L453)
1445. 细节暂不公开
   来源：[src/scenes/phone/P02_CC98/index.tsx:462](../src/scenes/phone/P02_CC98/index.tsx#L462)
1446. 最后一段发生了点不适合写进划船记录的事。人已上岸，其他细节暂时保留。
   来源：[src/scenes/phone/P02_CC98/index.tsx:463](../src/scenes/phone/P02_CC98/index.tsx#L463)
1447. 发布收尾并保存时间
   来源：[src/scenes/phone/P02_CC98/index.tsx:466](../src/scenes/phone/P02_CC98/index.tsx#L466)
1448. 纸条已读取。请核对搜索结果的来源、时间和附件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:535](../src/scenes/phone/P02_CC98/index.tsx#L535)
1449. 湿纸特征已加入搜索。找到一条刚发布的目击帖。
   来源：[src/scenes/phone/P02_CC98/index.tsx:540](../src/scenes/phone/P02_CC98/index.tsx#L540)
1450. 校内讨论和临时信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:597](../src/scenes/phone/P02_CC98/index.tsx#L597)
1451. CC98 仅支持校园网。请切换后重新进入。
   来源：[src/scenes/phone/P02_CC98/index.tsx:631](../src/scenes/phone/P02_CC98/index.tsx#L631)
1452. CC98 校园网验证
   来源：[src/scenes/phone/P02_CC98/index.tsx:645](../src/scenes/phone/P02_CC98/index.tsx#L645)
1453. 网络验证失败
   来源：[src/scenes/phone/P02_CC98/index.tsx:649](../src/scenes/phone/P02_CC98/index.tsx#L649)
1454. 校内访问验证
   来源：[src/scenes/phone/P02_CC98/index.tsx:649](../src/scenes/phone/P02_CC98/index.tsx#L649)
1455. 正在恢复手机票务页面
   来源：[src/scenes/phone/P02_CC98/index.tsx:651](../src/scenes/phone/P02_CC98/index.tsx#L651)
1456. 正在连接校园网服务
   来源：[src/scenes/phone/P02_CC98/index.tsx:651](../src/scenes/phone/P02_CC98/index.tsx#L651)
1457. 正在检查 ZJUWLAN
   来源：[src/scenes/phone/P02_CC98/index.tsx:652](../src/scenes/phone/P02_CC98/index.tsx#L652)
1458. 这条 23 楼记录尚未满足调查门槛。
   来源：[src/scenes/phone/P02_CC98/index.tsx:705](../src/scenes/phone/P02_CC98/index.tsx#L705)
1459. CC98 帖子已保存到本机。
   来源：[src/scenes/phone/P02_CC98/index.tsx:726](../src/scenes/phone/P02_CC98/index.tsx#L726)
1460. CC98 帖子已恢复为默认内容。
   来源：[src/scenes/phone/P02_CC98/index.tsx:782](../src/scenes/phone/P02_CC98/index.tsx#L782)
1461. CC98热门话题
   来源：[src/scenes/phone/P02_CC98/index.tsx:786](../src/scenes/phone/P02_CC98/index.tsx#L786)
1462. 退出 CC98，返回手机主页
   来源：[src/scenes/phone/P02_CC98/index.tsx:791](../src/scenes/phone/P02_CC98/index.tsx#L791)
1463. 热门话题
   来源：[src/scenes/phone/P02_CC98/index.tsx:794](../src/scenes/phone/P02_CC98/index.tsx#L794)
1464. 开发者帖子维护
   来源：[src/scenes/phone/P02_CC98/index.tsx:795](../src/scenes/phone/P02_CC98/index.tsx#L795)
1465. 更多
   来源：[src/scenes/phone/P02_CC98/index.tsx:796](../src/scenes/phone/P02_CC98/index.tsx#L796)
1466. CC98更多菜单
   来源：[src/scenes/phone/P02_CC98/index.tsx:796](../src/scenes/phone/P02_CC98/index.tsx#L796)
1467. 保存帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:799](../src/scenes/phone/P02_CC98/index.tsx#L799)
1468. 编辑帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:799](../src/scenes/phone/P02_CC98/index.tsx#L799)
1469. 保存
   来源：[src/scenes/phone/P02_CC98/index.tsx:800](../src/scenes/phone/P02_CC98/index.tsx#L800)
1470. 编辑
   来源：[src/scenes/phone/P02_CC98/index.tsx:800](../src/scenes/phone/P02_CC98/index.tsx#L800)
1471. 恢复默认帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:808](../src/scenes/phone/P02_CC98/index.tsx#L808)
1472. 关闭菜单
   来源：[src/scenes/phone/P02_CC98/index.tsx:811](../src/scenes/phone/P02_CC98/index.tsx#L811)
1473. 热门话题时间筛选
   来源：[src/scenes/phone/P02_CC98/index.tsx:816](../src/scenes/phone/P02_CC98/index.tsx#L816)
1474. CC98占座调查搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:822](../src/scenes/phone/P02_CC98/index.tsx#L822)
1475. 可接收道具
   来源：[src/scenes/phone/P02_CC98/index.tsx:823](../src/scenes/phone/P02_CC98/index.tsx#L823)；[src/scenes/phone/P02_CC98/index.tsx:857](../src/scenes/phone/P02_CC98/index.tsx#L857)
1476. 资料搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:823](../src/scenes/phone/P02_CC98/index.tsx#L823)
1477. CC98 搜索内容
   来源：[src/scenes/phone/P02_CC98/index.tsx:827](../src/scenes/phone/P02_CC98/index.tsx#L827)
1478. 022 占座纸条
   来源：[src/scenes/phone/P02_CC98/index.tsx:829](../src/scenes/phone/P02_CC98/index.tsx#L829)
1479. 把占座纸条拖到这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:830](../src/scenes/phone/P02_CC98/index.tsx#L830)
1480. 搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:832](../src/scenes/phone/P02_CC98/index.tsx#L832)；[src/scenes/phone/P02_CC98/index.tsx:866](../src/scenes/phone/P02_CC98/index.tsx#L866)；[src/scenes/phone/P15_Zjuding/index.tsx:1618](../src/scenes/phone/P15_Zjuding/index.tsx#L1618)；[src/scenes/phone/P15_Zjuding/index.tsx:2026](../src/scenes/phone/P15_Zjuding/index.tsx#L2026)；[src/scenes/phone/P15_Zjuding/index.tsx:2029](../src/scenes/phone/P15_Zjuding/index.tsx#L2029)
1481. 搜索结果
   来源：[src/scenes/phone/P02_CC98/index.tsx:834](../src/scenes/phone/P02_CC98/index.tsx#L834)
1482. 拖入纸条或点击搜索后显示候选记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:846](../src/scenes/phone/P02_CC98/index.tsx#L846)
1483. 论坛会根据纸条内容建立 23 楼调查索引。
   来源：[src/scenes/phone/P02_CC98/index.tsx:850](../src/scenes/phone/P02_CC98/index.tsx#L850)
1484. 湿纸目击搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:856](../src/scenes/phone/P02_CC98/index.tsx#L856)
1485. 目击搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:857](../src/scenes/phone/P02_CC98/index.tsx#L857)
1486. 湿纸目击搜索内容
   来源：[src/scenes/phone/P02_CC98/index.tsx:861](../src/scenes/phone/P02_CC98/index.tsx#L861)
1487. 剧院门口 湿纸
   来源：[src/scenes/phone/P02_CC98/index.tsx:863](../src/scenes/phone/P02_CC98/index.tsx#L863)
1488. 把湿掉的节目单拖到这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:864](../src/scenes/phone/P02_CC98/index.tsx#L864)
1489. 先用实物特征建立目击范围。
   来源：[src/scenes/phone/P02_CC98/index.tsx:869](../src/scenes/phone/P02_CC98/index.tsx#L869)
1490. CC98版面目录
   来源：[src/scenes/phone/P02_CC98/index.tsx:875](../src/scenes/phone/P02_CC98/index.tsx#L875)
1491. 全部版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:878](../src/scenes/phone/P02_CC98/index.tsx#L878)
1492. 选择一个版面查看帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:879](../src/scenes/phone/P02_CC98/index.tsx#L879)
1493. 个
   来源：[src/scenes/phone/P02_CC98/index.tsx:881](../src/scenes/phone/P02_CC98/index.tsx#L881)；[src/scenes/phone/P02_CC98/index.tsx:923](../src/scenes/phone/P02_CC98/index.tsx#L923)
1494. 进入{{board}}版面，共{{postCount}}帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:891](../src/scenes/phone/P02_CC98/index.tsx#L891)
1495. 帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:897](../src/scenes/phone/P02_CC98/index.tsx#L897)；[src/scenes/phone/P02_CC98/index.tsx:949](../src/scenes/phone/P02_CC98/index.tsx#L949)
1496. 关注{{board}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:903](../src/scenes/phone/P02_CC98/index.tsx#L903)
1497. 取消关注{{board}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:903](../src/scenes/phone/P02_CC98/index.tsx#L903)
1498. 已关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:906](../src/scenes/phone/P02_CC98/index.tsx#L906)；[src/scenes/phone/P14_Wechat/index.tsx:574](../src/scenes/phone/P14_Wechat/index.tsx#L574)
1499. CC98我的页面
   来源：[src/scenes/phone/P02_CC98/index.tsx:914](../src/scenes/phone/P02_CC98/index.tsx#L914)
1500. 我的浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:917](../src/scenes/phone/P02_CC98/index.tsx#L917)
1501. 本次打开过的帖子会留在这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:918](../src/scenes/phone/P02_CC98/index.tsx#L918)
1502. 条
   来源：[src/scenes/phone/P02_CC98/index.tsx:920](../src/scenes/phone/P02_CC98/index.tsx#L920)；[src/scenes/phone/P02_CC98/index.tsx:924](../src/scenes/phone/P02_CC98/index.tsx#L924)；[src/scenes/phone/P15_Zjuding/index.tsx:423](../src/scenes/phone/P15_Zjuding/index.tsx#L423)；[src/scenes/phone/P15_Zjuding/index.tsx:1665](../src/scenes/phone/P15_Zjuding/index.tsx#L1665)
1503. 关注版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:923](../src/scenes/phone/P02_CC98/index.tsx#L923)
1504. 浏览记录
   来源：[src/scenes/phone/P02_CC98/index.tsx:924](../src/scenes/phone/P02_CC98/index.tsx#L924)
1505. 最近浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:927](../src/scenes/phone/P02_CC98/index.tsx#L927)
1506. 还没有浏览记录。打开一篇帖子后会出现在这里。
   来源：[src/scenes/phone/P02_CC98/index.tsx:936](../src/scenes/phone/P02_CC98/index.tsx#L936)
1507. CC98帖子列表
   来源：[src/scenes/phone/P02_CC98/index.tsx:939](../src/scenes/phone/P02_CC98/index.tsx#L939)
1508. ‹ 全部版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:943](../src/scenes/phone/P02_CC98/index.tsx#L943)
1509. 关注的版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:946](../src/scenes/phone/P02_CC98/index.tsx#L946)
1510. 按发布时间排列
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1511. 本版面当前可见帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1512. 可在版面页调整关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1513. 可导入自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:983](../src/scenes/phone/P02_CC98/index.tsx#L983)
1514. 已导入自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:983](../src/scenes/phone/P02_CC98/index.tsx#L983)
1515. 回复 ·
   来源：[src/scenes/phone/P02_CC98/index.tsx:988](../src/scenes/phone/P02_CC98/index.tsx#L988)
1516. 浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:989](../src/scenes/phone/P02_CC98/index.tsx#L989)
1517. 正文
   来源：[src/scenes/phone/P02_CC98/index.tsx:1002](../src/scenes/phone/P02_CC98/index.tsx#L1002)
1518. 这个版面暂时没有可显示的帖子。
   来源：[src/scenes/phone/P02_CC98/index.tsx:1007](../src/scenes/phone/P02_CC98/index.tsx#L1007)
1519. CC98主导航
   来源：[src/scenes/phone/P02_CC98/index.tsx:1011](../src/scenes/phone/P02_CC98/index.tsx#L1011)
1520. 提取目击关键词
   来源：[src/scenes/phone/P02_CC98/index.tsx:1070](../src/scenes/phone/P02_CC98/index.tsx#L1070)
1521. 目击信息可归纳为一个地点关键词
   来源：[src/scenes/phone/P02_CC98/index.tsx:1071](../src/scenes/phone/P02_CC98/index.tsx#L1071)
1522. 记录关键词：桥边
   来源：[src/scenes/phone/P02_CC98/index.tsx:1073](../src/scenes/phone/P02_CC98/index.tsx#L1073)
1523. 已取得：桥边
   来源：[src/scenes/phone/P02_CC98/index.tsx:1073](../src/scenes/phone/P02_CC98/index.tsx#L1073)
1524. 关闭帖子编辑
   来源：[src/scenes/phone/P02_CC98/index.tsx:1091](../src/scenes/phone/P02_CC98/index.tsx#L1091)
1525. CC98小程序
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:19](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L19)
1526. 热门
   来源：[src/scenes/phone/P02_CC98/index.tsx:183](../src/scenes/phone/P02_CC98/index.tsx#L183)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:20](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L20)
1527. 今天 08:22
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:21](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L21)
1528. 楼主
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:22](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L22)
1529. 1楼
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:23](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L23)
1530. 纸飞机维修员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:25](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L25)
1531. 增加论坛经验 755
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:26](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L26)
1532. 帖子成功把常识送进流程
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:27](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L27)
1533. 热门回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:35](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L35)
1534. 只看楼主
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:36](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L36)
1535. 今天 08:24
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:42](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L42)
1536. 先 bd 留言。问题能不能解决不确定，队形必须先完整。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:45](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L45)
1537. 今天 08:27
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:52](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L52)
1538. bd 图先补上，楼主今晚大概能收到一点抽象支援。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:55](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L55)
1539. CC98帖子：{{post.title}}
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:120](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L120)
1540. 返回热门话题
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:122](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L122)
1541. 退出帖子，返回热门话题
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:132](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L132)
1542. 退出帖子
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:133](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L133)
1543. 已锁定无法回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:142](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L142)
1544. 用户
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:164](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L164)；[src/scenes/phone/P15_Zjuding/index.tsx:1960](../src/scenes/phone/P15_Zjuding/index.tsx#L1960)
1545. 操作
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:168](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L168)
1546. 理由
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:172](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L172)
1547. ⚙ 操作
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:178](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L178)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:235](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L235)
1548. ↶ 回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:179](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L179)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:236](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L236)
1549. 图书管理员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:197](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L197)
1550. 今天 08:55
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:198](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L198)
1551. 管理员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:200](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L200)
1552. 24楼
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:201](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L201)
1553. 您好已收到您的问题反馈，请前往图书馆程序进行系统申诉。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:203](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L203)
1554. 回复筛选
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:209](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L209)
1555. 匿名用户{{index + 1}}
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:221](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L221)
1556. CC98 bd 表情包
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:230](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L230)
1557. 现在没有需要带走的水。
   来源：[src/scenes/phone/P07_Weather/index.tsx:29](../src/scenes/phone/P07_Weather/index.tsx#L29)
1558. 湖区状态已经更新。
   来源：[src/scenes/phone/P07_Weather/index.tsx:41](../src/scenes/phone/P07_Weather/index.tsx#L41)；[src/scenes/phone/P07_Weather/index.tsx:60](../src/scenes/phone/P07_Weather/index.tsx#L60)
1559. 当前没有待处理的湖区记录。
   来源：[src/scenes/phone/P07_Weather/index.tsx:45](../src/scenes/phone/P07_Weather/index.tsx#L45)
1560. 先从寝室书桌拿到吹风机。
   来源：[src/scenes/phone/P07_Weather/index.tsx:45](../src/scenes/phone/P07_Weather/index.tsx#L45)
1561. 当前无法开始校准。
   来源：[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)
1562. 湖区状态已更新。
   来源：[src/scenes/phone/P07_Weather/index.tsx:55](../src/scenes/phone/P07_Weather/index.tsx#L55)
1563. 校准记录无效，请重新对齐。
   来源：[src/scenes/phone/P07_Weather/index.tsx:63](../src/scenes/phone/P07_Weather/index.tsx#L63)
1564. 退出天气，返回手机主页
   来源：[src/scenes/phone/P07_Weather/index.tsx:70](../src/scenes/phone/P07_Weather/index.tsx#L70)
1565. 杭州 · 紫金港
   来源：[src/scenes/phone/P07_Weather/index.tsx:71](../src/scenes/phone/P07_Weather/index.tsx#L71)
1566. °C
   来源：[src/scenes/phone/P07_Weather/index.tsx:95](../src/scenes/phone/P07_Weather/index.tsx#L95)；[src/scenes/phone/P07_Weather/index.tsx:96](../src/scenes/phone/P07_Weather/index.tsx#L96)；[src/scenes/phone/P13_PhoneHome/index.tsx:681](../src/scenes/phone/P13_PhoneHome/index.tsx#L681)
1567. 体感温度
   来源：[src/scenes/phone/P07_Weather/index.tsx:96](../src/scenes/phone/P07_Weather/index.tsx#L96)
1568. 天气详情
   来源：[src/scenes/phone/P07_Weather/index.tsx:99](../src/scenes/phone/P07_Weather/index.tsx#L99)
1569. 湿度
   来源：[src/scenes/phone/P07_Weather/index.tsx:100](../src/scenes/phone/P07_Weather/index.tsx#L100)
1570. 西南风 2级
   来源：[src/scenes/phone/P07_Weather/index.tsx:101](../src/scenes/phone/P07_Weather/index.tsx#L101)；[src/scenes/phone/P13_PhoneHome/index.tsx:689](../src/scenes/phone/P13_PhoneHome/index.tsx#L689)
1571. 降水
   来源：[src/scenes/phone/P07_Weather/index.tsx:102](../src/scenes/phone/P07_Weather/index.tsx#L102)
1572. 已经停止
   来源：[src/scenes/phone/P07_Weather/index.tsx:102](../src/scenes/phone/P07_Weather/index.tsx#L102)
1573. 正在发生
   来源：[src/scenes/phone/P07_Weather/index.tsx:102](../src/scenes/phone/P07_Weather/index.tsx#L102)
1574. 处理湖区云图
   来源：[src/scenes/phone/P07_Weather/index.tsx:104](../src/scenes/phone/P07_Weather/index.tsx#L104)
1575. 返回码头确认
   来源：[src/scenes/phone/P07_Weather/index.tsx:104](../src/scenes/phone/P07_Weather/index.tsx#L104)
1576. 暂不适合下水
   来源：[src/scenes/phone/P07_Weather/index.tsx:104](../src/scenes/phone/P07_Weather/index.tsx#L104)
1577. 处理黏着物
   来源：[src/scenes/phone/P07_Weather/index.tsx:105](../src/scenes/phone/P07_Weather/index.tsx#L105)
1578. 湖区记录尚未开放
   来源：[src/scenes/phone/P07_Weather/index.tsx:115](../src/scenes/phone/P07_Weather/index.tsx#L115)
1579. 湖区状态已更新
   来源：[src/scenes/phone/P07_Weather/index.tsx:115](../src/scenes/phone/P07_Weather/index.tsx#L115)；[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1580. 开始湖区云层校准
   来源：[src/scenes/phone/P07_Weather/index.tsx:115](../src/scenes/phone/P07_Weather/index.tsx#L115)
1581. 启动风向校准
   来源：[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1582. 缺少可用设备
   来源：[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1583. 暂无湖区记录
   来源：[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1584. 返回码头确认{{state.qizhenLake.weatherControlBestMoves &gt; 0 ? \` · 最少 ${state.qizhenLake.weatherControlBestMoves} 次校正\` : ""}}
   来源：[src/scenes/phone/P07_Weather/index.tsx:122](../src/scenes/phone/P07_Weather/index.tsx#L122)
1585. 先检查寝室书桌
   来源：[src/scenes/phone/P07_Weather/index.tsx:124](../src/scenes/phone/P07_Weather/index.tsx#L124)
1586. 在持续风力中同步稳定三层云带
   来源：[src/scenes/phone/P07_Weather/index.tsx:124](../src/scenes/phone/P07_Weather/index.tsx#L124)
1587. 完成码头检查后再查看
   来源：[src/scenes/phone/P07_Weather/index.tsx:125](../src/scenes/phone/P07_Weather/index.tsx#L125)
1588. 收集天气水滴
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1589. 天气水滴尚未开放
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1590. 天气水滴已收集
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1591. 还没有开始外出打卡
   来源：[src/scenes/phone/P07_Weather/index.tsx:137](../src/scenes/phone/P07_Weather/index.tsx#L137)
1592. 接住一滴水
   来源：[src/scenes/phone/P07_Weather/index.tsx:137](../src/scenes/phone/P07_Weather/index.tsx#L137)
1593. 水滴已收集
   来源：[src/scenes/phone/P07_Weather/index.tsx:137](../src/scenes/phone/P07_Weather/index.tsx#L137)
1594. 你都还没有开始外出打卡，一滴雨都不会落到你身上。
   来源：[src/scenes/phone/P07_Weather/index.tsx:138](../src/scenes/phone/P07_Weather/index.tsx#L138)
1595. 它正在道具栏里等着被使用
   来源：[src/scenes/phone/P07_Weather/index.tsx:138](../src/scenes/phone/P07_Weather/index.tsx#L138)
1596. 这滴水看起来比天气预报更有用
   来源：[src/scenes/phone/P07_Weather/index.tsx:138](../src/scenes/phone/P07_Weather/index.tsx#L138)
1597. 微信
   来源：[src/scenes/phone/P08_Settings/index.tsx:28](../src/scenes/phone/P08_Settings/index.tsx#L28)；[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)；[src/scenes/phone/P14_Wechat/index.tsx:151](../src/scenes/phone/P14_Wechat/index.tsx#L151)
1598. 浙大钉
   来源：[src/scenes/phone/P08_Settings/index.tsx:30](../src/scenes/phone/P08_Settings/index.tsx#L30)；[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)；[src/scenes/phone/P13_PhoneHome/index.tsx:827](../src/scenes/phone/P13_PhoneHome/index.tsx#L827)
1599. 设置
   来源：[src/scenes/phone/P08_Settings/index.tsx:31](../src/scenes/phone/P08_Settings/index.tsx#L31)；[src/scenes/phone/P08_Settings/index.tsx:145](../src/scenes/phone/P08_Settings/index.tsx#L145)；[src/scenes/phone/P08_Settings/index.tsx:148](../src/scenes/phone/P08_Settings/index.tsx#L148)；[src/scenes/phone/P13_PhoneHome/index.tsx:460](../src/scenes/phone/P13_PhoneHome/index.tsx#L460)
1600. 照片
   来源：[src/scenes/phone/P08_Settings/index.tsx:32](../src/scenes/phone/P08_Settings/index.tsx#L32)；[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)；[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)；[src/scenes/phone/P13_PhoneHome/index.tsx:466](../src/scenes/phone/P13_PhoneHome/index.tsx#L466)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:118](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L118)
1601. 记录恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:33](../src/scenes/phone/P08_Settings/index.tsx#L33)；[src/scenes/phone/P13_PhoneHome/index.tsx:473](../src/scenes/phone/P13_PhoneHome/index.tsx#L473)；[src/scenes/phone/P13_PhoneHome/index.tsx:718](../src/scenes/phone/P13_PhoneHome/index.tsx#L718)
1602. 录音
   来源：[src/scenes/phone/P08_Settings/index.tsx:34](../src/scenes/phone/P08_Settings/index.tsx#L34)；[src/scenes/phone/P13_PhoneHome/index.tsx:485](../src/scenes/phone/P13_PhoneHome/index.tsx#L485)
1603. 时钟
   来源：[src/scenes/phone/P08_Settings/index.tsx:37](../src/scenes/phone/P08_Settings/index.tsx#L37)；[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)
1604. 查看当前连接
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1605. 网
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1606. 校园网络与移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1607. 背景音乐
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1608. 声
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1609. 声音与振动
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1610. 亮度与可读性
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)
1611. 显
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)
1612. 显示与辅助
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)；[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1613. 移动图标与恢复排布
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)
1614. 桌
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)
1615. 桌面与壁纸
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)；[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1616. 恢复可选应用
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)
1617. 应
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)
1618. 应用管理
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)；[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1619. 权
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)
1620. 相机、照片与网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)
1621. 隐私与权限
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)；[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1622. 电
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)
1623. 电池与后台活动
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)；[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1624. 检查 07:55 记录
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)
1625. 存档与运行状态
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)
1626. 系
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)
1627. 系统诊断与关于
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)；[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1628. 07:48
   来源：[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)
1629. 天气卡片刷新
   来源：[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)
1630. 07:55
   来源：[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)；[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)；[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)
1631. 重新建立 IMG\_0755 索引
   来源：[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)
1632. 07:52
   来源：[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)
1633. 同步两条新消息
   来源：[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)
1634. 系统时间被后台唤醒
   来源：[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)
1635. 恢复 A2 室内定位
   来源：[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)
1636. 08:02
   来源：[src/scenes/phone/P08_Settings/index.tsx:57](../src/scenes/phone/P08_Settings/index.tsx#L57)
1637. 读取热门话题缓存
   来源：[src/scenes/phone/P08_Settings/index.tsx:57](../src/scenes/phone/P08_Settings/index.tsx#L57)
1638. {{APP\_LABELS\[appId\]}}已移动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:95](../src/scenes/phone/P08_Settings/index.tsx#L95)
1639. {{APP\_LABELS\[appId\]}}已回到桌面。
   来源：[src/scenes/phone/P08_Settings/index.tsx:100](../src/scenes/phone/P08_Settings/index.tsx#L100)
1640. 屏幕亮度
   来源：[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1641. 照片取证会读取这个亮度值。
   来源：[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1642. 核对旧桌面截图
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1643. 恢复默认顺序
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1644. 将{{APP\_LABELS\[appId\]}}后移
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1645. 将{{APP\_LABELS\[appId\]}}前移
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1646. 旧截图第一排
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1647. 微信 浙大钉 照片 CC98
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1648. 桌面也支持长按图标进入编辑。这里可用按钮精确调整顺序。
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1649. 桌面已恢复默认顺序。
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1650. 当前阶段还没有可删除的可选应用。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1651. 当前允许从桌面移除
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1652. 恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1653. 没有从桌面移除的可选应用。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1654. 微信、照片、CC98、浙大钉、设置等剧情应用只能移动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1655. 保存剧情照片
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1656. 取证时使用
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1657. 相机
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1658. 校园网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1659. CC98 与校内服务
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1660. 当前没有需要核验的剧情记录。
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1661. 核验所选记录
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1662. 记录已归档
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1663. 选出同时发生在 07:55 的三条异常活动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1664. 存档
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1665. 个可见
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1666. 游戏时间
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1667. 桌面应用
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1668. 自动保存与上一版本恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1669. 返回设置
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1670. 退出设置，返回手机主页
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1671. root
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1672. PHONE SYSTEM
   来源：[src/scenes/phone/P08_Settings/index.tsx:148](../src/scenes/phone/P08_Settings/index.tsx#L148)
1673. 搜索设置项
   来源：[src/scenes/phone/P08_Settings/index.tsx:151](../src/scenes/phone/P08_Settings/index.tsx#L151)
1674. 塞不进去。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:112](../src/scenes/phone/P13_PhoneHome/index.tsx#L112)
1675. 钥匙旋转 90°——咔哒。塔楼吐出\[一袋肥料\]。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:138](../src/scenes/phone/P13_PhoneHome/index.tsx#L138)
1676. CC98 需要校园网；已经载入的手机票务页面可在移动数据下继续。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:182](../src/scenes/phone/P13_PhoneHome/index.tsx#L182)
1677. 这条推送现在只负责占位置。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:210](../src/scenes/phone/P13_PhoneHome/index.tsx#L210)
1678. 头像边缘松了一点，再点一次。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:211](../src/scenes/phone/P13_PhoneHome/index.tsx#L211)
1679. 三角形已经翘起，再点一次就能取下。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:212](../src/scenes/phone/P13_PhoneHome/index.tsx#L212)
1680. 设置图标只剩一个空位，风从里面吹过。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:219](../src/scenes/phone/P13_PhoneHome/index.tsx#L219)
1681. 这个应用参与剧情，只能移动位置。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:337](../src/scenes/phone/P13_PhoneHome/index.tsx#L337)
1682. {{appId === "tiyi" ? "浙大体艺" : "求是潮 755"}}已从桌面移除，可在设置中恢复。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:341](../src/scenes/phone/P13_PhoneHome/index.tsx#L341)
1683. 获得第 3 位：9
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:364](../src/scenes/phone/P13_PhoneHome/index.tsx#L364)
1684. 钟楼已经把秘密交出去了。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:372](../src/scenes/phone/P13_PhoneHome/index.tsx#L372)
1685. 钟楼大门紧锁。锁孔的形状有点奇怪。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:376](../src/scenes/phone/P13_PhoneHome/index.tsx#L376)
1686. 接住了一滴早八雨。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:386](../src/scenes/phone/P13_PhoneHome/index.tsx#L386)
1687. 它绝对不会开花。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:393](../src/scenes/phone/P13_PhoneHome/index.tsx#L393)
1688. 从桌面移除{{definition.label}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:592](../src/scenes/phone/P13_PhoneHome/index.tsx#L592)
1689. 像素风浙大首页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:607](../src/scenes/phone/P13_PhoneHome/index.tsx#L607)
1690. 钟楼
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:638](../src/scenes/phone/P13_PhoneHome/index.tsx#L638)
1691. 湖边盆栽
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:658](../src/scenes/phone/P13_PhoneHome/index.tsx#L658)
1692. 湖边盆栽，已开花
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:658](../src/scenes/phone/P13_PhoneHome/index.tsx#L658)
1693. 天气：{{campusWeather.label}}，{{weatherTemperature}} 摄氏度
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:666](../src/scenes/phone/P13_PhoneHome/index.tsx#L666)
1694. 打开天气
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:668](../src/scenes/phone/P13_PhoneHome/index.tsx#L668)
1695. 收集水滴
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:675](../src/scenes/phone/P13_PhoneHome/index.tsx#L675)
1696. 最高 20°C / 最低 15°C
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:685](../src/scenes/phone/P13_PhoneHome/index.tsx#L685)
1697. 空气湿度
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:688](../src/scenes/phone/P13_PhoneHome/index.tsx#L688)
1698. 拖动图标调整位置
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:695](../src/scenes/phone/P13_PhoneHome/index.tsx#L695)
1699. 完成
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:696](../src/scenes/phone/P13_PhoneHome/index.tsx#L696)；[src/scenes/rpg/RpgGameHost.tsx:2278](../src/scenes/rpg/RpgGameHost.tsx#L2278)
1700. 应用
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:699](../src/scenes/phone/P13_PhoneHome/index.tsx#L699)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)
1701. 掉落的齿轮，背面刻着 9
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:706](../src/scenes/phone/P13_PhoneHome/index.tsx#L706)
1702. 通知列表
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:712](../src/scenes/phone/P13_PhoneHome/index.tsx#L712)
1703. 流量已开启，返回手机票务页抢第二波
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:748](../src/scenes/phone/P13_PhoneHome/index.tsx#L748)
1704. 第一波结束：网速过慢，开启流量
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:749](../src/scenes/phone/P13_PhoneHome/index.tsx#L749)
1705. 第一波抢票成功，运气很好，钱包没那么好
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:751](../src/scenes/phone/P13_PhoneHome/index.tsx#L751)
1706. 08:32 第二波取票回执已同步
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:752](../src/scenes/phone/P13_PhoneHome/index.tsx#L752)
1707. 图书馆：您有一本书已逾期 755 天
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:766](../src/scenes/phone/P13_PhoneHome/index.tsx#L766)
1708. 您有一本书已逾期 755 天
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:768](../src/scenes/phone/P13_PhoneHome/index.tsx#L768)
1709. CC98：Re: 三楼书架是不是多了一层？
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:771](../src/scenes/phone/P13_PhoneHome/index.tsx#L771)
1710. Re: 三楼书架是不是多了一层？
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:773](../src/scenes/phone/P13_PhoneHome/index.tsx#L773)
1711. 照片：新增照片「看不清的书脊」
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:776](../src/scenes/phone/P13_PhoneHome/index.tsx#L776)
1712. 三角形已收集
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:815](../src/scenes/phone/P13_PhoneHome/index.tsx#L815)
1713. 系统方向推送
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:815](../src/scenes/phone/P13_PhoneHome/index.tsx#L815)
1714. 方向校准
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:819](../src/scenes/phone/P13_PhoneHome/index.tsx#L819)
1715. 课程提醒
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:819](../src/scenes/phone/P13_PhoneHome/index.tsx#L819)
1716. 签到记录未更新。你本人仍未抵达。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:820](../src/scenes/phone/P13_PhoneHome/index.tsx#L820)
1717. 头像方向正确，正文方向未知。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:820](../src/scenes/phone/P13_PhoneHome/index.tsx#L820)
1718. 校园地图已恢复访问，寝室入口可用。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:827](../src/scenes/phone/P13_PhoneHome/index.tsx#L827)
1719. 课堂签到仍在等待四位代码。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:833](../src/scenes/phone/P13_PhoneHome/index.tsx#L833)
1720. 学在浙大
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:833](../src/scenes/phone/P13_PhoneHome/index.tsx#L833)；[src/scenes/phone/P15_Zjuding/index.tsx:1367](../src/scenes/phone/P15_Zjuding/index.tsx#L1367)；[src/scenes/phone/P15_Zjuding/index.tsx:1386](../src/scenes/phone/P15_Zjuding/index.tsx#L1386)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:55](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L55)
1721. 天气：{{weatherNotification}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:841](../src/scenes/phone/P13_PhoneHome/index.tsx#L841)；[src/scenes/phone/P13_PhoneHome/index.tsx:849](../src/scenes/phone/P13_PhoneHome/index.tsx#L849)
1722. 页面切换
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:859](../src/scenes/phone/P13_PhoneHome/index.tsx#L859)
1723. 第 1 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:860](../src/scenes/phone/P13_PhoneHome/index.tsx#L860)
1724. 第 2 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:861](../src/scenes/phone/P13_PhoneHome/index.tsx#L861)
1725. 第 3 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:862](../src/scenes/phone/P13_PhoneHome/index.tsx#L862)
1726. 记录恢复：检测到未同步记录
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:866](../src/scenes/phone/P13_PhoneHome/index.tsx#L866)
1727. 朋友
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:899](../src/scenes/phone/P13_PhoneHome/index.tsx#L899)；[src/scenes/phone/P14_Wechat/index.tsx:948](../src/scenes/phone/P14_Wechat/index.tsx#L948)
1728. 快快老师在点名，学在浙大
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:900](../src/scenes/phone/P13_PhoneHome/index.tsx#L900)
1729. 这是签到码：XX……
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:901](../src/scenes/phone/P13_PhoneHome/index.tsx#L901)
1730. 现在
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:903](../src/scenes/phone/P13_PhoneHome/index.tsx#L903)
1731. 照片 IMG\_0755.JPG
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:115](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L115)
1732. 关闭照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:117](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L117)
1733. 022书包拍摄界面
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:123](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L123)
1734. 保持画面居中
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:124](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L124)
1735. 对准 022 书包
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:124](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L124)
1736. 还没有在 022 现场确认书包。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:130](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L130)
1737. 目标已对准，点击快门。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:130](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L130)
1738. 拍摄 022 书包
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:131](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L131)
1739. 反光的书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:142](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L142)
1740. 可读的书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:142](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L142)
1741. 书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:159](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L159)
1742. 高数教材 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:160](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L160)
1743. 水杯 x1 充电器 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:161](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L161)
1744. 半包纸 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:162](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L162)
1745. 姓名：未检测到
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:163](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L163)
1746. 学号：未检测到
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:164](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L164)
1747. 人格：加载失败
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:165](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L165)
1748. 标签反光，无法识别
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:169](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L169)
1749. 控制中心亮度
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:185](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L185)
1750. 照片直接读取系统亮度
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:187](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L187)
1751. 还没有拍到 022 上的书包。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:191](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L191)
1752. 识别稳定，标签内容已锁定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:193](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L193)
1753. 标签边缘已出现，识别信号仍不稳定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:195](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L195)
1754. 光照太亮了，识别器无法对焦。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:196](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L196)
1755. 旧相册里还有一张同场景照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:203](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L203)
1756. 找到同一只 022 书包的旧照，核对半包纸出现的时间。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:204](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L204)
1757. 查看 022 旧照
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:210](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L210)
1758. 已写入报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:210](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L210)
1759. 照片筛选
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:217](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L217)
1760. 最近 {{LIBRARY\_ROLL\_PHOTOS.length}} 张
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:220](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L220)
1761. 校园与日常
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:221](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L221)
1762. 校园与日常照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1763. 最近照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1764. campus\_life
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1765. 预览 {{photo.title}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:235](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L235)
1766. 6 张校园与日常照片。它们只用于补足相册内容，不参与证据判定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:250](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L250)
1767. {{LIBRARY\_ROLL\_PHOTOS.length}} 张最近照片。点开可以查看细节。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:251](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L251)
1768. {{selectedRollPhoto.file}} · {{selectedRollPhoto.location}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:258](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L258)
1769. {{selectedRollPhoto.title}}，{{selectedRollPhoto.detail}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:263](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L263)
1770. 旧照与刚拍下的标签内容一致。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:267](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L267)
1771. 先把刚拍下的主照片亮度降到 20% 以下。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:267](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L267)
1772. 已写入物品报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:269](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L269)
1773. 用旧照补全物品报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:269](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L269)
1774. 东边入口已经封了，别再往那边走。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:32](../src/scenes/phone/P14_Wechat/index.tsx#L32)
1775. 周琪
   来源：[src/scenes/phone/P14_Wechat/index.tsx:32](../src/scenes/phone/P14_Wechat/index.tsx#L32)
1776. 室友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:33](../src/scenes/phone/P14_Wechat/index.tsx#L33)
1777. 我在西侧看见保洁推车，大厅主入口应该还能进。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:33](../src/scenes/phone/P14_Wechat/index.tsx#L33)
1778. 陈嘉
   来源：[src/scenes/phone/P14_Wechat/index.tsx:34](../src/scenes/phone/P14_Wechat/index.tsx#L34)
1779. 陈嘉撤回了一条消息
   来源：[src/scenes/phone/P14_Wechat/index.tsx:34](../src/scenes/phone/P14_Wechat/index.tsx#L34)
1780. 公众号 · 22:40
   来源：[src/scenes/phone/P14_Wechat/index.tsx:79](../src/scenes/phone/P14_Wechat/index.tsx#L79)
1781. 紫金港楼宇服务
   来源：[src/scenes/phone/P14_Wechat/index.tsx:79](../src/scenes/phone/P14_Wechat/index.tsx#L79)；[src/scenes/phone/P14_Wechat/index.tsx:157](../src/scenes/phone/P14_Wechat/index.tsx#L157)
1782. 校园楼宇运行通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:84](../src/scenes/phone/P14_Wechat/index.tsx#L84)
1783. 夜间闭楼与入口调整
   来源：[src/scenes/phone/P14_Wechat/index.tsx:85](../src/scenes/phone/P14_Wechat/index.tsx#L85)
1784. 22:45 起，
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1785. 北教学区一处楼宇
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1786. 段永平教学楼
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1787. 进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1788. 主电梯保留运行，楼层开放情况以现场提示为准。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:88](../src/scenes/phone/P14_Wechat/index.tsx#L88)
1789. 保存通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:90](../src/scenes/phone/P14_Wechat/index.tsx#L90)
1790. 通知已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:90](../src/scenes/phone/P14_Wechat/index.tsx#L90)
1791. 麦斯威夜间自习群
   来源：[src/scenes/phone/P14_Wechat/index.tsx:101](../src/scenes/phone/P14_Wechat/index.tsx#L101)；[src/scenes/phone/P14_Wechat/index.tsx:104](../src/scenes/phone/P14_Wechat/index.tsx#L104)；[src/scenes/phone/P14_Wechat/index.tsx:163](../src/scenes/phone/P14_Wechat/index.tsx#L163)
1792. 返回微信消息列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:103](../src/scenes/phone/P14_Wechat/index.tsx#L103)
1793. 群聊 · 18人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:104](../src/scenes/phone/P14_Wechat/index.tsx#L104)
1794. 选中两条能够同时确认“哪边关闭”和“哪边可进入”的消息。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:109](../src/scenes/phone/P14_Wechat/index.tsx#L109)
1795. 选择
   来源：[src/scenes/phone/P14_Wechat/index.tsx:123](../src/scenes/phone/P14_Wechat/index.tsx#L123)
1796. 已选
   来源：[src/scenes/phone/P14_Wechat/index.tsx:123](../src/scenes/phone/P14_Wechat/index.tsx#L123)
1797. 22:42 入口调整截图 · 东侧关闭 / 西侧主入口可通行
   来源：[src/scenes/phone/P14_Wechat/index.tsx:130](../src/scenes/phone/P14_Wechat/index.tsx#L130)
1798. 保存路线截图
   来源：[src/scenes/phone/P14_Wechat/index.tsx:139](../src/scenes/phone/P14_Wechat/index.tsx#L139)
1799. 截图已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:139](../src/scenes/phone/P14_Wechat/index.tsx#L139)
1800. 微信恢复证据
   来源：[src/scenes/phone/P14_Wechat/index.tsx:148](../src/scenes/phone/P14_Wechat/index.tsx#L148)
1801. 退出微信，返回手机主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:150](../src/scenes/phone/P14_Wechat/index.tsx#L150)
1802. 消息
   来源：[src/scenes/phone/P14_Wechat/index.tsx:151](../src/scenes/phone/P14_Wechat/index.tsx#L151)；[src/scenes/phone/P15_Zjuding/index.tsx:141](../src/scenes/phone/P15_Zjuding/index.tsx#L141)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:79](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L79)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:87](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L87)
1803. 楼
   来源：[src/scenes/phone/P14_Wechat/index.tsx:156](../src/scenes/phone/P14_Wechat/index.tsx#L156)
1804. 有一条未归档的运行通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:157](../src/scenes/phone/P14_Wechat/index.tsx#L157)
1805. 已存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:159](../src/scenes/phone/P14_Wechat/index.tsx#L159)；[src/scenes/phone/P14_Wechat/index.tsx:165](../src/scenes/phone/P14_Wechat/index.tsx#L165)
1806. 有两条消息可组成路线截图
   来源：[src/scenes/phone/P14_Wechat/index.tsx:163](../src/scenes/phone/P14_Wechat/index.tsx#L163)
1807. 返回记录恢复
   来源：[src/scenes/phone/P14_Wechat/index.tsx:168](../src/scenes/phone/P14_Wechat/index.tsx#L168)；[src/scenes/phone/P15_Zjuding/index.tsx:451](../src/scenes/phone/P15_Zjuding/index.tsx#L451)
1808. 任务更新：找回四位签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:236](../src/scenes/phone/P14_Wechat/index.tsx#L236)
1809. 咔——斜线断了一截，挂在头像框上晃悠。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:331](../src/scenes/phone/P14_Wechat/index.tsx#L331)
1810. 导师头像现在不接受附件。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:349](../src/scenes/phone/P14_Wechat/index.tsx#L349)
1811. 卡扣反而更紧了。它需要能渗进胶缝的东西。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:355](../src/scenes/phone/P14_Wechat/index.tsx#L355)
1812. 竖线滑落了。获得道具：竖线
   来源：[src/scenes/phone/P14_Wechat/index.tsx:363](../src/scenes/phone/P14_Wechat/index.tsx#L363)
1813. 或许可以再斜一点
   来源：[src/scenes/phone/P14_Wechat/index.tsx:387](../src/scenes/phone/P14_Wechat/index.tsx#L387)
1814. 它也想转转罢
   来源：[src/scenes/phone/P14_Wechat/index.tsx:389](../src/scenes/phone/P14_Wechat/index.tsx#L389)
1815. 斜线晃了晃，还没掉。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:391](../src/scenes/phone/P14_Wechat/index.tsx#L391)
1816. 头像上的斜线纹丝不动。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:392](../src/scenes/phone/P14_Wechat/index.tsx#L392)
1817. 检测到未经授权的友情支援。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:403](../src/scenes/phone/P14_Wechat/index.tsx#L403)
1818. 你戳了戳剩下的一端……
   来源：[src/scenes/phone/P14_Wechat/index.tsx:406](../src/scenes/phone/P14_Wechat/index.tsx#L406)
1819. 导师的消息，还是等签完到再回吧。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:414](../src/scenes/phone/P14_Wechat/index.tsx#L414)
1820. 头像中间留下了一道很干净的空隙。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:419](../src/scenes/phone/P14_Wechat/index.tsx#L419)
1821. 这条竖线被透明胶和两枚卡扣封在头像框里。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:423](../src/scenes/phone/P14_Wechat/index.tsx#L423)
1822. 这条聊天还不能作为地点记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:506](../src/scenes/phone/P14_Wechat/index.tsx#L506)
1823. 已从聊天中保存地点词：湖面。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:509](../src/scenes/phone/P14_Wechat/index.tsx#L509)
1824. 已保存通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:541](../src/scenes/phone/P14_Wechat/index.tsx#L541)
1825. · 校园日常记录
   来源：[src/scenes/phone/P14_Wechat/index.tsx:557](../src/scenes/phone/P14_Wechat/index.tsx#L557)
1826. 阅读
   来源：[src/scenes/phone/P14_Wechat/index.tsx:557](../src/scenes/phone/P14_Wechat/index.tsx#L557)
1827. {{chapterFourWechatContent.official.name}}公众号主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:567](../src/scenes/phone/P14_Wechat/index.tsx#L567)
1828. 后勤
   来源：[src/scenes/phone/P14_Wechat/index.tsx:569](../src/scenes/phone/P14_Wechat/index.tsx#L569)；[src/scenes/phone/P14_Wechat/index.tsx:788](../src/scenes/phone/P14_Wechat/index.tsx#L788)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
1829. 夜间通知 ·
   来源：[src/scenes/phone/P14_Wechat/index.tsx:584](../src/scenes/phone/P14_Wechat/index.tsx#L584)
1830. 已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:588](../src/scenes/phone/P14_Wechat/index.tsx#L588)
1831. 主线通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:588](../src/scenes/phone/P14_Wechat/index.tsx#L588)
1832. 往期推文
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)；[src/scenes/phone/P14_Wechat/index.tsx:593](../src/scenes/phone/P14_Wechat/index.tsx#L593)；[src/scenes/phone/P14_Wechat/index.tsx:625](../src/scenes/phone/P14_Wechat/index.tsx#L625)
1833. 校园日常
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)；[src/scenes/phone/P14_Wechat/index.tsx:593](../src/scenes/phone/P14_Wechat/index.tsx#L593)；[src/scenes/phone/P14_Wechat/index.tsx:620](../src/scenes/phone/P14_Wechat/index.tsx#L620)
1834. daily
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)
1835. 篇
   来源：[src/scenes/phone/P14_Wechat/index.tsx:594](../src/scenes/phone/P14_Wechat/index.tsx#L594)
1836. 公众号自定义菜单
   来源：[src/scenes/phone/P14_Wechat/index.tsx:614](../src/scenes/phone/P14_Wechat/index.tsx#L614)
1837. 夜间通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:615](../src/scenes/phone/P14_Wechat/index.tsx#L615)
1838. 档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:665](../src/scenes/phone/P14_Wechat/index.tsx#L665)
1839. 学习天地资料索引
   来源：[src/scenes/phone/P14_Wechat/index.tsx:667](../src/scenes/phone/P14_Wechat/index.tsx#L667)
1840. 群文件 ›
   来源：[src/scenes/phone/P14_Wechat/index.tsx:670](../src/scenes/phone/P14_Wechat/index.tsx#L670)
1841. 林昊
   来源：[src/scenes/phone/P14_Wechat/index.tsx:682](../src/scenes/phone/P14_Wechat/index.tsx#L682)
1842. 保存录音
   来源：[src/scenes/phone/P14_Wechat/index.tsx:705](../src/scenes/phone/P14_Wechat/index.tsx#L705)
1843. 已归档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:705](../src/scenes/phone/P14_Wechat/index.tsx#L705)
1844. 待现场核验
   来源：[src/scenes/phone/P14_Wechat/index.tsx:709](../src/scenes/phone/P14_Wechat/index.tsx#L709)
1845. 群聊截图 · 2F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:709](../src/scenes/phone/P14_Wechat/index.tsx#L709)
1846. 现场照片 · 3F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:713](../src/scenes/phone/P14_Wechat/index.tsx#L713)
1847. 等你从 CC98 导入资料索引
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
1848. 路线讨论已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
1849. 学习天地资料已加入群文件
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
1850. 文件传输助手：只有你给自己发的表情包。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:801](../src/scenes/phone/P14_Wechat/index.tsx#L801)
1851. 文件传输助手
   来源：[src/scenes/phone/P14_Wechat/index.tsx:805](../src/scenes/phone/P14_Wechat/index.tsx#L805)
1852. \[图片\]
   来源：[src/scenes/phone/P14_Wechat/index.tsx:806](../src/scenes/phone/P14_Wechat/index.tsx#L806)
1853. 已保存 {{chapterFourWechat.archiveCount}} 项现场资料
   来源：[src/scenes/phone/P14_Wechat/index.tsx:806](../src/scenes/phone/P14_Wechat/index.tsx#L806)
1854. 打开朋友聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:816](../src/scenes/phone/P14_Wechat/index.tsx#L816)
1855. 朋友头像
   来源：[src/scenes/phone/P14_Wechat/index.tsx:822](../src/scenes/phone/P14_Wechat/index.tsx#L822)
1856. 导师：实验报告仍然不会自己完成。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:876](../src/scenes/phone/P14_Wechat/index.tsx#L876)
1857. 导师头像上的竖线
   来源：[src/scenes/phone/P14_Wechat/index.tsx:882](../src/scenes/phone/P14_Wechat/index.tsx#L882)
1858. 导师
   来源：[src/scenes/phone/P14_Wechat/index.tsx:904](../src/scenes/phone/P14_Wechat/index.tsx#L904)
1859. 头像胶缝里似乎缺一点能流动的东西。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:908](../src/scenes/phone/P14_Wechat/index.tsx#L908)
1860. 两枚卡扣在发亮，中间的竖线还是拔不动。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:910](../src/scenes/phone/P14_Wechat/index.tsx#L910)
1861. 头像框中间多了一条被封住的竖线。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:911](../src/scenes/phone/P14_Wechat/index.tsx#L911)
1862. 请把实验报告的初稿发我一下。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:912](../src/scenes/phone/P14_Wechat/index.tsx#L912)
1863. 聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:923](../src/scenes/phone/P14_Wechat/index.tsx#L923)
1864. 联系人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:927](../src/scenes/phone/P14_Wechat/index.tsx#L927)
1865. 探索
   来源：[src/scenes/phone/P14_Wechat/index.tsx:931](../src/scenes/phone/P14_Wechat/index.tsx#L931)
1866. 我的
   来源：[src/scenes/phone/P14_Wechat/index.tsx:935](../src/scenes/phone/P14_Wechat/index.tsx#L935)；[src/scenes/phone/P15_Zjuding/index.tsx:142](../src/scenes/phone/P15_Zjuding/index.tsx#L142)；[src/scenes/phone/P15_Zjuding/index.tsx:147](../src/scenes/phone/P15_Zjuding/index.tsx#L147)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:80](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L80)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:88](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L88)
1867. 返回聊天列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:946](../src/scenes/phone/P14_Wechat/index.tsx#L946)
1868. 快快老师在点名，学在浙大。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:959](../src/scenes/phone/P14_Wechat/index.tsx#L959)
1869. 这是签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:967](../src/scenes/phone/P14_Wechat/index.tsx#L967)
1870. 等等等等，你想翘课？没门！
   来源：[src/scenes/phone/P14_Wechat/index.tsx:987](../src/scenes/phone/P14_Wechat/index.tsx#L987)
1871. 我不会让你签上的！
   来源：[src/scenes/phone/P14_Wechat/index.tsx:988](../src/scenes/phone/P14_Wechat/index.tsx#L988)
1872. 跳过小影语音
   来源：[src/scenes/phone/P14_Wechat/index.tsx:999](../src/scenes/phone/P14_Wechat/index.tsx#L999)
1873. 成功了吗
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1007](../src/scenes/phone/P14_Wechat/index.tsx#L1007)
1874. wx-msg wx-qizhen-message {{line.startsWith("自动回复：") ? "is-self" : ""}}
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1037](../src/scenes/phone/P14_Wechat/index.tsx#L1037)
1875. 自动回复：
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1038](../src/scenes/phone/P14_Wechat/index.tsx#L1038)
1876. 身份信息未读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:62](../src/scenes/phone/P15_Zjuding/index.tsx#L62)
1877. 拜托了，帮我改一下签到记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:72](../src/scenes/phone/P15_Zjuding/index.tsx#L72)；[src/scenes/phone/P15_Zjuding/index.tsx:79](../src/scenes/phone/P15_Zjuding/index.tsx#L79)
1878. player
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:72](../src/scenes/phone/P15_Zjuding/index.tsx#L72)；[src/scenes/phone/P15_Zjuding/index.tsx:79](../src/scenes/phone/P15_Zjuding/index.tsx#L79)；[src/scenes/phone/P15_Zjuding/index.tsx:85](../src/scenes/phone/P15_Zjuding/index.tsx#L85)
1879. 先把校园卡收好。寝室里的人还需要找到移动方法。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:81](../src/scenes/phone/P15_Zjuding/index.tsx#L81)
1880. 别打扰我……哦，你已经完事了，速度还挺快的
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:92](../src/scenes/phone/P15_Zjuding/index.tsx#L92)
1881. 我以为你要在寝室“就再睡一会儿”呢
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:93](../src/scenes/phone/P15_Zjuding/index.tsx#L93)
1882. 你知道的，去图书馆要先完成座位预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:94](../src/scenes/phone/P15_Zjuding/index.tsx#L94)
1883. 基础馆二楼南区022，记住了。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:95](../src/scenes/phone/P15_Zjuding/index.tsx#L95)
1884. 馆藏检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:127](../src/scenes/phone/P15_Zjuding/index.tsx#L127)；[src/scenes/phone/P15_Zjuding/index.tsx:1506](../src/scenes/phone/P15_Zjuding/index.tsx#L1506)；[src/scenes/phone/P15_Zjuding/index.tsx:1507](../src/scenes/phone/P15_Zjuding/index.tsx#L1507)；[src/scenes/phone/P15_Zjuding/index.tsx:1510](../src/scenes/phone/P15_Zjuding/index.tsx#L1510)；[src/scenes/phone/P15_Zjuding/index.tsx:1511](../src/scenes/phone/P15_Zjuding/index.tsx#L1511)
1885. 借阅信息
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:128](../src/scenes/phone/P15_Zjuding/index.tsx#L128)
1886. 阅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:128](../src/scenes/phone/P15_Zjuding/index.tsx#L128)
1887. 座位预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:129](../src/scenes/phone/P15_Zjuding/index.tsx#L129)；[src/scenes/phone/P15_Zjuding/index.tsx:1514](../src/scenes/phone/P15_Zjuding/index.tsx#L1514)
1888. 空间预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:130](../src/scenes/phone/P15_Zjuding/index.tsx#L130)
1889. 荐
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:131](../src/scenes/phone/P15_Zjuding/index.tsx#L131)
1890. 求是荐书
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:131](../src/scenes/phone/P15_Zjuding/index.tsx#L131)
1891. 新书通报
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:132](../src/scenes/phone/P15_Zjuding/index.tsx#L132)
1892. 查收查引
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:133](../src/scenes/phone/P15_Zjuding/index.tsx#L133)
1893. 引
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:133](../src/scenes/phone/P15_Zjuding/index.tsx#L133)
1894. 图书馆缴费
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:134](../src/scenes/phone/P15_Zjuding/index.tsx#L134)
1895. 失物招领 · 前台工作人员
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:197](../src/scenes/phone/P15_Zjuding/index.tsx#L197)
1896. 二层南区 · 022 桌面夹缝
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:203](../src/scenes/phone/P15_Zjuding/index.tsx#L203)
1897. 浙大体艺 · 到馆记录补录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:209](../src/scenes/phone/P15_Zjuding/index.tsx#L209)
1898. 二层
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:214](../src/scenes/phone/P15_Zjuding/index.tsx#L214)；[src/scenes/phone/P15_Zjuding/index.tsx:215](../src/scenes/phone/P15_Zjuding/index.tsx#L215)
1899. 二层南
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:214](../src/scenes/phone/P15_Zjuding/index.tsx#L214)；[src/scenes/phone/P15_Zjuding/index.tsx:553](../src/scenes/phone/P15_Zjuding/index.tsx#L553)
1900. 二层北
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:215](../src/scenes/phone/P15_Zjuding/index.tsx#L215)
1901. 三层
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:216](../src/scenes/phone/P15_Zjuding/index.tsx#L216)；[src/scenes/phone/P15_Zjuding/index.tsx:217](../src/scenes/phone/P15_Zjuding/index.tsx#L217)
1902. 三层东
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:216](../src/scenes/phone/P15_Zjuding/index.tsx#L216)
1903. 三层南
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:217](../src/scenes/phone/P15_Zjuding/index.tsx#L217)
1904. 返回，离开{{title}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:247](../src/scenes/phone/P15_Zjuding/index.tsx#L247)
1905. {{title}}更多菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:249](../src/scenes/phone/P15_Zjuding/index.tsx#L249)
1906. 页面导航
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:269](../src/scenes/phone/P15_Zjuding/index.tsx#L269)；[src/scenes/phone/P15_Zjuding/index.tsx:1583](../src/scenes/phone/P15_Zjuding/index.tsx#L1583)
1907. 22:44:31
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:343](../src/scenes/phone/P15_Zjuding/index.tsx#L343)
1908. 剧场前厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:345](../src/scenes/phone/P15_Zjuding/index.tsx#L345)
1909. 18 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:346](../src/scenes/phone/P15_Zjuding/index.tsx#L346)
1910. 已认证设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:347](../src/scenes/phone/P15_Zjuding/index.tsx#L347)；[src/scenes/phone/P15_Zjuding/index.tsx:413](../src/scenes/phone/P15_Zjuding/index.tsx#L413)
1911. 22:43:11
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:354](../src/scenes/phone/P15_Zjuding/index.tsx#L354)
1912. 基础图书馆南侧
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:356](../src/scenes/phone/P15_Zjuding/index.tsx#L356)
1913. 3 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:357](../src/scenes/phone/P15_Zjuding/index.tsx#L357)；[src/scenes/phone/P15_Zjuding/index.tsx:368](../src/scenes/phone/P15_Zjuding/index.tsx#L368)
1914. 未知设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:358](../src/scenes/phone/P15_Zjuding/index.tsx#L358)；[src/scenes/phone/P15_Zjuding/index.tsx:369](../src/scenes/phone/P15_Zjuding/index.tsx#L369)
1915. 22:44:12
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:365](../src/scenes/phone/P15_Zjuding/index.tsx#L365)
1916. 启真湖小码头
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:367](../src/scenes/phone/P15_Zjuding/index.tsx#L367)
1917. 网络记录筛选
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:402](../src/scenes/phone/P15_Zjuding/index.tsx#L402)
1918. 缺失时段末段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:406](../src/scenes/phone/P15_Zjuding/index.tsx#L406)
1919. 最后 1 分钟
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:407](../src/scenes/phone/P15_Zjuding/index.tsx#L407)
1920. 会话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:410](../src/scenes/phone/P15_Zjuding/index.tsx#L410)
1921. 未知设备 · 短会话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:412](../src/scenes/phone/P15_Zjuding/index.tsx#L412)
1922. 全校
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:417](../src/scenes/phone/P15_Zjuding/index.tsx#L417)
1923. 北教学区 A 区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:418](../src/scenes/phone/P15_Zjuding/index.tsx#L418)
1924. 其他楼宇
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:419](../src/scenes/phone/P15_Zjuding/index.tsx#L419)
1925. 接入记录结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:422](../src/scenes/phone/P15_Zjuding/index.tsx#L422)
1926. 查询结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:423](../src/scenes/phone/P15_Zjuding/index.tsx#L423)
1927. 接入点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:428](../src/scenes/phone/P15_Zjuding/index.tsx#L428)
1928. 位置
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:429](../src/scenes/phone/P15_Zjuding/index.tsx#L429)
1929. 设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:430](../src/scenes/phone/P15_Zjuding/index.tsx#L430)
1930. 记录已保存
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:437](../src/scenes/phone/P15_Zjuding/index.tsx#L437)
1931. 保存这条记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:438](../src/scenes/phone/P15_Zjuding/index.tsx#L438)
1932. 可从任意维度开始筛选，也可直接保存候选记录。系统不会替你判定候选，最终冲突由证据矩阵统一核验。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:443](../src/scenes/phone/P15_Zjuding/index.tsx#L443)
1933. 记录核验结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:445](../src/scenes/phone/P15_Zjuding/index.tsx#L445)
1934. 林星宇
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:446](../src/scenes/phone/P15_Zjuding/index.tsx#L446)
1935. 这不是我的手机。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:446](../src/scenes/phone/P15_Zjuding/index.tsx#L446)
1936. 北教学区 A 区的一处大厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1937. 段永平教学楼一楼
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1938. 留下了三秒会话。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1939. 设备名也不是你的。它借用了你的校园身份，在
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1940. 可选座位地图
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:473](../src/scenes/phone/P15_Zjuding/index.tsx#L473)
1941. 选择座位{{leftSeat}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:489](../src/scenes/phone/P15_Zjuding/index.tsx#L489)
1942. 选择座位{{rightSeat}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:500](../src/scenes/phone/P15_Zjuding/index.tsx#L500)
1943. 北向
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:517](../src/scenes/phone/P15_Zjuding/index.tsx#L517)
1944. 请选择馆舍
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:552](../src/scenes/phone/P15_Zjuding/index.tsx#L552)
1945. 07月10日 · 今天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:554](../src/scenes/phone/P15_Zjuding/index.tsx#L554)；[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
1946. 全部座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:557](../src/scenes/phone/P15_Zjuding/index.tsx#L557)；[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
1947. 请连接校园网后重新进入浙大钉。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:621](../src/scenes/phone/P15_Zjuding/index.tsx#L621)
1948. reservation
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:630](../src/scenes/phone/P15_Zjuding/index.tsx#L630)
1949. 读卡器没有读到有效证件。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:636](../src/scenes/phone/P15_Zjuding/index.tsx#L636)
1950. 证件信息已读入。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:655](../src/scenes/phone/P15_Zjuding/index.tsx#L655)
1951. 读卡区只认校园身份凭证。这件道具没有姓名和学号。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:666](../src/scenes/phone/P15_Zjuding/index.tsx#L666)
1952. 馆藏检索没有识别这件道具中的页码特征。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:698](../src/scenes/phone/P15_Zjuding/index.tsx#L698)
1953. 节目单的潮湿页码已送入馆藏状态检索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:706](../src/scenes/phone/P15_Zjuding/index.tsx#L706)
1954. 这个槽位需要对应名称的恢复证明。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:722](../src/scenes/phone/P15_Zjuding/index.tsx#L722)
1955. 退出浙大钉
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:764](../src/scenes/phone/P15_Zjuding/index.tsx#L764)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
1956. 个人资料
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:768](../src/scenes/phone/P15_Zjuding/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
1957. 账号与安全
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:768](../src/scenes/phone/P15_Zjuding/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
1958. 收藏号码
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:772](../src/scenes/phone/P15_Zjuding/index.tsx#L772)；[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
1959. 最近通话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:772](../src/scenes/phone/P15_Zjuding/index.tsx#L772)；[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
1960. 我的预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:776](../src/scenes/phone/P15_Zjuding/index.tsx#L776)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
1961. 当前没有已确认的图书馆预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:780](../src/scenes/phone/P15_Zjuding/index.tsx#L780)
1962. 刷新空位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:784](../src/scenes/phone/P15_Zjuding/index.tsx#L784)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
1963. 刷新座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:784](../src/scenes/phone/P15_Zjuding/index.tsx#L784)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
1964. 已重新读取本机座位状态：{{selectedRoom}}空闲 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.available ?? 0}} 席。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:785](../src/scenes/phone/P15_Zjuding/index.tsx#L785)
1965. 预约规则
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:788](../src/scenes/phone/P15_Zjuding/index.tsx#L788)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
1966. 预约页只接受当前剧情已开放的馆舍、区域和座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:789](../src/scenes/phone/P15_Zjuding/index.tsx#L789)
1967. 取消预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:792](../src/scenes/phone/P15_Zjuding/index.tsx#L792)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
1968. 已确认预约保持不变。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:793](../src/scenes/phone/P15_Zjuding/index.tsx#L793)
1969. 找回账号
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:796](../src/scenes/phone/P15_Zjuding/index.tsx#L796)；[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
1970. 请通过电子校园卡重新读取身份。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:797](../src/scenes/phone/P15_Zjuding/index.tsx#L797)
1971. 安全提示
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:800](../src/scenes/phone/P15_Zjuding/index.tsx#L800)；[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
1972. 账号信息由电子校园卡状态读取。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:801](../src/scenes/phone/P15_Zjuding/index.tsx#L801)
1973. 当前状态已显示。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:804](../src/scenes/phone/P15_Zjuding/index.tsx#L804)
1974. 它看了看你的空手，又缩回了红圈里。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:923](../src/scenes/phone/P15_Zjuding/index.tsx#L923)
1975. 求是印章没有回应。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:927](../src/scenes/phone/P15_Zjuding/index.tsx#L927)
1976. 任务更新：找到道具栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:948](../src/scenes/phone/P15_Zjuding/index.tsx#L948)
1977. 任务更新：找到移动的办法
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:952](../src/scenes/phone/P15_Zjuding/index.tsx#L952)
1978. 任务更新：让地图人物回应你
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:955](../src/scenes/phone/P15_Zjuding/index.tsx#L955)
1979. 本章的 022 状态由图书馆现场记录管理。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1015](../src/scenes/phone/P15_Zjuding/index.tsx#L1015)
1980. 座位 {{state.ui.librarySelectedSeat ?? "022"}} 已预约，不能在当前任务中改签。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1019](../src/scenes/phone/P15_Zjuding/index.tsx#L1019)
1981. 请先选择一个白色座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1028](../src/scenes/phone/P15_Zjuding/index.tsx#L1028)
1982. 座位 {{state.ui.librarySelectedSeat}} 已预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1032](../src/scenes/phone/P15_Zjuding/index.tsx#L1032)
1983. 预约来源不匹配：请选择基础馆。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1044](../src/scenes/phone/P15_Zjuding/index.tsx#L1044)
1984. 预约区域不匹配：请选择二层南区。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1045](../src/scenes/phone/P15_Zjuding/index.tsx#L1045)
1985. 座位凭据不匹配：目标座位为 022。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1046](../src/scenes/phone/P15_Zjuding/index.tsx#L1046)
1986. 系统还没有开放本次座位预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1047](../src/scenes/phone/P15_Zjuding/index.tsx#L1047)
1987. 预约成功：基础馆二层南区 022。任务更新：前往基础图书馆 022
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1054](../src/scenes/phone/P15_Zjuding/index.tsx#L1054)
1988. 请输入书名、作者或索书号。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1063](../src/scenes/phone/P15_Zjuding/index.tsx#L1063)
1989. 检索完成：发现 1 条异常外借记录。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1075](../src/scenes/phone/P15_Zjuding/index.tsx#L1075)
1990. 没有找到与“{{query}}”相符的馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1083](../src/scenes/phone/P15_Zjuding/index.tsx#L1083)
1991. 检索完成：找到 {{results.length}} 本馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1087](../src/scenes/phone/P15_Zjuding/index.tsx#L1087)
1992. 检索完成：找到 {{results.length}} 本相似馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1093](../src/scenes/phone/P15_Zjuding/index.tsx#L1093)
1993. 当前无法保存这条异常定位信息。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1098](../src/scenes/phone/P15_Zjuding/index.tsx#L1098)
1994. {{qizhenContent.locationSearch.catalog.player}} / {{qizhenContent.locationSearch.catalog.system}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1101](../src/scenes/phone/P15_Zjuding/index.tsx#L1101)
1995. 地图没有从这件道具中读到地点关键词。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1107](../src/scenes/phone/P15_Zjuding/index.tsx#L1107)
1996. 当前没有需要合并的地点线索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1111](../src/scenes/phone/P15_Zjuding/index.tsx#L1111)
1997. 这条记录已经参与检索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1115](../src/scenes/phone/P15_Zjuding/index.tsx#L1115)
1998. 三条记录还没有全部对齐。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1130](../src/scenes/phone/P15_Zjuding/index.tsx#L1130)
1999. 启真湖入口还没有在大地图上开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1138](../src/scenes/phone/P15_Zjuding/index.tsx#L1138)
2000. 已获得线索：索书号 {{result.callNumber}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1145](../src/scenes/phone/P15_Zjuding/index.tsx#L1145)；[src/scenes/phone/P15_Zjuding/index.tsx:1158](../src/scenes/phone/P15_Zjuding/index.tsx#L1158)
2001. {{result.title}}的索书号和 022 没有可核对的关系。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1153](../src/scenes/phone/P15_Zjuding/index.tsx#L1153)
2002. 十大排名还没有被图书馆系统同步。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1164](../src/scenes/phone/P15_Zjuding/index.tsx#L1164)
2003. 恢复申请只在帖子进入十大第一后开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1168](../src/scenes/phone/P15_Zjuding/index.tsx#L1168)
2004. 该证明还未获得、已提交，或当前申请尚未开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1177](../src/scenes/phone/P15_Zjuding/index.tsx#L1177)
2005. 三项恢复材料尚未齐全。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1191](../src/scenes/phone/P15_Zjuding/index.tsx#L1191)
2006. 浙大钉加载中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1204](../src/scenes/phone/P15_Zjuding/index.tsx#L1204)
2007. 请连接校园网后重新进入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1215](../src/scenes/phone/P15_Zjuding/index.tsx#L1215)
2008. 统一身份认证
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1258](../src/scenes/phone/P15_Zjuding/index.tsx#L1258)
2009. 登录帮助
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
2010. 校园身份信息
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1264](../src/scenes/phone/P15_Zjuding/index.tsx#L1264)
2011. 旧登录入口已合并到电子校园卡。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1265](../src/scenes/phone/P15_Zjuding/index.tsx#L1265)
2012. 前往部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1276](../src/scenes/phone/P15_Zjuding/index.tsx#L1276)
2013. 浙大钉部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1284](../src/scenes/phone/P15_Zjuding/index.tsx#L1284)
2014. 部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1286](../src/scenes/phone/P15_Zjuding/index.tsx#L1286)；[src/scenes/phone/P15_Zjuding/index.tsx:2013](../src/scenes/phone/P15_Zjuding/index.tsx#L2013)；[src/scenes/phone/P15_Zjuding/index.tsx:2017](../src/scenes/phone/P15_Zjuding/index.tsx#L2017)；[src/scenes/phone/P15_Zjuding/index.tsx:2018](../src/scenes/phone/P15_Zjuding/index.tsx#L2018)
2015. 黄页菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
2016. 部门联系人
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1291](../src/scenes/phone/P15_Zjuding/index.tsx#L1291)
2017. 联络寝室人物
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1299](../src/scenes/phone/P15_Zjuding/index.tsx#L1299)
2018. 校园卡读卡区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1305](../src/scenes/phone/P15_Zjuding/index.tsx#L1305)
2019. 电子校园卡已读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1316](../src/scenes/phone/P15_Zjuding/index.tsx#L1316)
2020. 校园身份读卡区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1316](../src/scenes/phone/P15_Zjuding/index.tsx#L1316)
2021. 正在识别持卡人字段……
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1319](../src/scenes/phone/P15_Zjuding/index.tsx#L1319)
2022. 姓名与 10 位学号已填入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1321](../src/scenes/phone/P15_Zjuding/index.tsx#L1321)
2023. 校园卡已对准，点击读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1323](../src/scenes/phone/P15_Zjuding/index.tsx#L1323)
2024. 点击查看提示，或将身份凭证放入此处
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1324](../src/scenes/phone/P15_Zjuding/index.tsx#L1324)
2025. 联络未命名人物
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1331](../src/scenes/phone/P15_Zjuding/index.tsx#L1331)
2026. 请输入校园卡上的完整身份
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1331](../src/scenes/phone/P15_Zjuding/index.tsx#L1331)
2027. 校园卡姓名
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1341](../src/scenes/phone/P15_Zjuding/index.tsx#L1341)
2028. 10 位学号
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1354](../src/scenes/phone/P15_Zjuding/index.tsx#L1354)
2029. ☎ 呼叫
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1359](../src/scenes/phone/P15_Zjuding/index.tsx#L1359)
2030. 已联络：{{actOneContent.studentName}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1359](../src/scenes/phone/P15_Zjuding/index.tsx#L1359)
2031. 校务签到
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1375](../src/scenes/phone/P15_Zjuding/index.tsx#L1375)
2032. 返回浙大钉
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1382](../src/scenes/phone/P15_Zjuding/index.tsx#L1382)
2033. 学在浙大导航
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1383](../src/scenes/phone/P15_Zjuding/index.tsx#L1383)
2034. 当前位于学在浙大。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1384](../src/scenes/phone/P15_Zjuding/index.tsx#L1384)
2035. 方向靠近桥
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
2036. CC98 目击帖
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
2037. 馆藏异常记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
2038. 页码只出现在倒影中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
2039. 湖面
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2040. 湖面出现逆风水纹
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2041. 微信聊天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2042. 三条记录来自不同应用。先取得地点词，再在这里逐条接入。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1417](../src/scenes/phone/P15_Zjuding/index.tsx#L1417)
2043. 校园地图地点检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1419](../src/scenes/phone/P15_Zjuding/index.tsx#L1419)
2044. 保留原始来源，核对三条地点记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1424](../src/scenes/phone/P15_Zjuding/index.tsx#L1424)
2045. 交叉检索台
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1424](../src/scenes/phone/P15_Zjuding/index.tsx#L1424)
2046. 三源地点记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1429](../src/scenes/phone/P15_Zjuding/index.tsx#L1429)
2047. 已接入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1432](../src/scenes/phone/P15_Zjuding/index.tsx#L1432)；[src/scenes/phone/P15_Zjuding/index.tsx:1450](../src/scenes/phone/P15_Zjuding/index.tsx#L1450)
2048. 待核对
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2049. 入口已标记
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2050. 收集中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2051. 提取词：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1447](../src/scenes/phone/P15_Zjuding/index.tsx#L1447)
2052. 导入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1452](../src/scenes/phone/P15_Zjuding/index.tsx#L1452)
2053. 导入{{clue.source}}的地点词{{clue.label}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1452](../src/scenes/phone/P15_Zjuding/index.tsx#L1452)
2054. 未取得
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1454](../src/scenes/phone/P15_Zjuding/index.tsx#L1454)
2055. 核对地点交点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1461](../src/scenes/phone/P15_Zjuding/index.tsx#L1461)
2056. 前往大地图上的启真湖入口
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1476](../src/scenes/phone/P15_Zjuding/index.tsx#L1476)
2057. 浙大移动图书馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1484](../src/scenes/phone/P15_Zjuding/index.tsx#L1484)；[src/scenes/phone/P15_Zjuding/index.tsx:1486](../src/scenes/phone/P15_Zjuding/index.tsx#L1486)；[src/scenes/phone/P15_Zjuding/index.tsx:1597](../src/scenes/phone/P15_Zjuding/index.tsx#L1597)
2058. 未读取身份的读者头像
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1491](../src/scenes/phone/P15_Zjuding/index.tsx#L1491)
2059. 校园卡持卡人读者头像
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1491](../src/scenes/phone/P15_Zjuding/index.tsx#L1491)
2060. 022恢复申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1530](../src/scenes/phone/P15_Zjuding/index.tsx#L1530)；[src/scenes/phone/P15_Zjuding/index.tsx:1531](../src/scenes/phone/P15_Zjuding/index.tsx#L1531)；[src/scenes/phone/P15_Zjuding/index.tsx:1534](../src/scenes/phone/P15_Zjuding/index.tsx#L1534)；[src/scenes/phone/P15_Zjuding/index.tsx:1536](../src/scenes/phone/P15_Zjuding/index.tsx#L1536)
2061. 返回现场
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1540](../src/scenes/phone/P15_Zjuding/index.tsx#L1540)；[src/scenes/phone/P15_Zjuding/index.tsx:1541](../src/scenes/phone/P15_Zjuding/index.tsx#L1541)；[src/scenes/phone/P15_Zjuding/index.tsx:1544](../src/scenes/phone/P15_Zjuding/index.tsx#L1544)；[src/scenes/phone/P15_Zjuding/index.tsx:1545](../src/scenes/phone/P15_Zjuding/index.tsx#L1545)；[src/scenes/phone/P15_Zjuding/index.tsx:1887](../src/scenes/phone/P15_Zjuding/index.tsx#L1887)
2062. 022 座位恢复申请已开放
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1552](../src/scenes/phone/P15_Zjuding/index.tsx#L1552)
2063. 帖子当前排名 01，可提交三项证明。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1553](../src/scenes/phone/P15_Zjuding/index.tsx#L1553)
2064. 活动日历
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1560](../src/scenes/phone/P15_Zjuding/index.tsx#L1560)
2065. （活动报名）“我著·我...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1562](../src/scenes/phone/P15_Zjuding/index.tsx#L1562)
2066. （活动报名）书香浙大·开...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1562](../src/scenes/phone/P15_Zjuding/index.tsx#L1562)
2067. 通知公告
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1565](../src/scenes/phone/P15_Zjuding/index.tsx#L1565)
2068. 关于新增校外数据库访...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1567](../src/scenes/phone/P15_Zjuding/index.tsx#L1567)
2069. 图书馆数字资源校外访...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1567](../src/scenes/phone/P15_Zjuding/index.tsx#L1567)
2070. 规章制度
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1570](../src/scenes/phone/P15_Zjuding/index.tsx#L1570)
2071. 读者文明使用空间须知
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)
2072. 图书馆座位预约管理规则
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)
2073. 图书馆馆藏检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1595](../src/scenes/phone/P15_Zjuding/index.tsx#L1595)
2074. 文献库选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1601](../src/scenes/phone/P15_Zjuding/index.tsx#L1601)
2075. 当前正在使用中文文献库。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1602](../src/scenes/phone/P15_Zjuding/index.tsx#L1602)
2076. 中文文献库
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1602](../src/scenes/phone/P15_Zjuding/index.tsx#L1602)
2077. 检索条件
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1606](../src/scenes/phone/P15_Zjuding/index.tsx#L1606)
2078. 搜索文献
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1614](../src/scenes/phone/P15_Zjuding/index.tsx#L1614)
2079. 馆藏检索关键词
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1615](../src/scenes/phone/P15_Zjuding/index.tsx#L1615)
2080. 检索范围
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1620](../src/scenes/phone/P15_Zjuding/index.tsx#L1620)
2081. 当前检索字段固定为书名，高级检索可查看其他条件。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
2082. 检索字段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
2083. 当前馆藏范围为全部馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2084. 馆藏范围
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2085. 全部馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2086. 高级检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1628](../src/scenes/phone/P15_Zjuding/index.tsx#L1628)
2087. 收起高级检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1628](../src/scenes/phone/P15_Zjuding/index.tsx#L1628)
2088. 检索到的书籍数：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1630](../src/scenes/phone/P15_Zjuding/index.tsx#L1630)
2089. 高级检索字段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1633](../src/scenes/phone/P15_Zjuding/index.tsx#L1633)
2090. 包含全部关键词
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1634](../src/scenes/phone/P15_Zjuding/index.tsx#L1634)
2091. 题名匹配
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1634](../src/scenes/phone/P15_Zjuding/index.tsx#L1634)
2092. 全部分类
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1635](../src/scenes/phone/P15_Zjuding/index.tsx#L1635)
2093. 索书号分类
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1635](../src/scenes/phone/P15_Zjuding/index.tsx#L1635)
2094. 馆藏地点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1636](../src/scenes/phone/P15_Zjuding/index.tsx#L1636)
2095. 基础图书馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1636](../src/scenes/phone/P15_Zjuding/index.tsx#L1636)；[src/scenes/rpg/ZijingangCampusLayout.ts:100](../src/scenes/rpg/ZijingangCampusLayout.ts#L100)
2096. 异常外借状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1643](../src/scenes/phone/P15_Zjuding/index.tsx#L1643)
2097. 签到记录夹页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1644](../src/scenes/phone/P15_Zjuding/index.tsx#L1644)
2098. 异常外借
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1644](../src/scenes/phone/P15_Zjuding/index.tsx#L1644)
2099. 记录关键词：倒影
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1651](../src/scenes/phone/P15_Zjuding/index.tsx#L1651)
2100. 已取得：倒影
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1651](../src/scenes/phone/P15_Zjuding/index.tsx#L1651)
2101. 馆藏检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1663](../src/scenes/phone/P15_Zjuding/index.tsx#L1663)
2102. 检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1665](../src/scenes/phone/P15_Zjuding/index.tsx#L1665)
2103. 选择馆藏{{result.title}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1671](../src/scenes/phone/P15_Zjuding/index.tsx#L1671)
2104. {{result.title}}封面
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1672](../src/scenes/phone/P15_Zjuding/index.tsx#L1672)
2105. 著者：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1675](../src/scenes/phone/P15_Zjuding/index.tsx#L1675)
2106. 索书号：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1676](../src/scenes/phone/P15_Zjuding/index.tsx#L1676)
2107. 无检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1687](../src/scenes/phone/P15_Zjuding/index.tsx#L1687)
2108. 没有匹配馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1688](../src/scenes/phone/P15_Zjuding/index.tsx#L1688)
2109. 可尝试书名、作者或索书号中的连续文字。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1689](../src/scenes/phone/P15_Zjuding/index.tsx#L1689)
2110. 新书推荐
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1692](../src/scenes/phone/P15_Zjuding/index.tsx#L1692)；[src/scenes/phone/P15_Zjuding/index.tsx:1693](../src/scenes/phone/P15_Zjuding/index.tsx#L1693)
2111. 输入题名后，相似书籍会同时列出。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1694](../src/scenes/phone/P15_Zjuding/index.tsx#L1694)
2112. 022座位恢复申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1704](../src/scenes/phone/P15_Zjuding/index.tsx#L1704)；[src/scenes/phone/P15_Zjuding/index.tsx:1706](../src/scenes/phone/P15_Zjuding/index.tsx#L1706)
2113. 基础馆 · 二楼南区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1713](../src/scenes/phone/P15_Zjuding/index.tsx#L1713)
2114. CC98 公示排名：01
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1714](../src/scenes/phone/P15_Zjuding/index.tsx#L1714)
2115. 恢复材料进度 {{submitted.length}}/3
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1718](../src/scenes/phone/P15_Zjuding/index.tsx#L1718)
2116. 旧版规则 · 恢复条件
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1722](../src/scenes/phone/P15_Zjuding/index.tsx#L1722)
2117. CC98 公示已生效。三份材料分别确认占用物身份、座位编号与本人到馆记录。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1723](../src/scenes/phone/P15_Zjuding/index.tsx#L1723)
2118. 恢复证明槽位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1725](../src/scenes/phone/P15_Zjuding/index.tsx#L1725)
2119. 待取得
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2120. 可提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2121. 已核验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2122. 来源：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1745](../src/scenes/phone/P15_Zjuding/index.tsx#L1745)
2123. 材料已锁定到本次申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1746](../src/scenes/phone/P15_Zjuding/index.tsx#L1746)
2124. 道具栏已识别，可提交校验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1746](../src/scenes/phone/P15_Zjuding/index.tsx#L1746)
2125. 提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1753](../src/scenes/phone/P15_Zjuding/index.tsx#L1753)
2126. 座位释放PASS已签发
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1761](../src/scenes/phone/P15_Zjuding/index.tsx#L1761)
2127. PASS 已签发
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1763](../src/scenes/phone/P15_Zjuding/index.tsx#L1763)；[src/scenes/phone/P15_Zjuding/index.tsx:1854](../src/scenes/phone/P15_Zjuding/index.tsx#L1854)
2128. 凭证只对 RPG 图书馆内的 022 书包生效。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1764](../src/scenes/phone/P15_Zjuding/index.tsx#L1764)
2129. 回图书馆处理书包
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1765](../src/scenes/phone/P15_Zjuding/index.tsx#L1765)
2130. 生成 022 座位释放 PASS
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1769](../src/scenes/phone/P15_Zjuding/index.tsx#L1769)
2131. 图书馆空间列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1777](../src/scenes/phone/P15_Zjuding/index.tsx#L1777)
2132. 图书馆空间预约...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1779](../src/scenes/phone/P15_Zjuding/index.tsx#L1779)；[src/scenes/phone/P15_Zjuding/index.tsx:1863](../src/scenes/phone/P15_Zjuding/index.tsx#L1863)
2133. 空间预约菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
2134. 收起座位预约栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1785](../src/scenes/phone/P15_Zjuding/index.tsx#L1785)
2135. 展开座位预约栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1785](../src/scenes/phone/P15_Zjuding/index.tsx#L1785)
2136. 预
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2137. 约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2138. 座
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2139. 空间选择模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1791](../src/scenes/phone/P15_Zjuding/index.tsx#L1791)
2140. 列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1792](../src/scenes/phone/P15_Zjuding/index.tsx#L1792)
2141. 快速选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1793](../src/scenes/phone/P15_Zjuding/index.tsx#L1793)
2142. 空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1796](../src/scenes/phone/P15_Zjuding/index.tsx#L1796)
2143. 显示
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1796](../src/scenes/phone/P15_Zjuding/index.tsx#L1796)
2144. 可预约空间列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1802](../src/scenes/phone/P15_Zjuding/index.tsx#L1802)
2145. {{room.label}}自习空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1806](../src/scenes/phone/P15_Zjuding/index.tsx#L1806)
2146. 主馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1807](../src/scenes/phone/P15_Zjuding/index.tsx#L1807)；[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2147. 空闲
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1811](../src/scenes/phone/P15_Zjuding/index.tsx#L1811)；[src/scenes/phone/P15_Zjuding/index.tsx:1822](../src/scenes/phone/P15_Zjuding/index.tsx#L1822)
2148. 预约{{room.label}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1812](../src/scenes/phone/P15_Zjuding/index.tsx#L1812)
2149. 快速选择空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1818](../src/scenes/phone/P15_Zjuding/index.tsx#L1818)
2150. 我的中心
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1830](../src/scenes/phone/P15_Zjuding/index.tsx#L1830)
2151. 当前位于空间预约列表。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1832](../src/scenes/phone/P15_Zjuding/index.tsx#L1832)
2152. 座位已恢复
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1850](../src/scenes/phone/P15_Zjuding/index.tsx#L1850)
2153. 清退已执行
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1852](../src/scenes/phone/P15_Zjuding/index.tsx#L1852)
2154. 恢复申请待提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1856](../src/scenes/phone/P15_Zjuding/index.tsx#L1856)
2155. 公示审核中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1858](../src/scenes/phone/P15_Zjuding/index.tsx#L1858)
2156. 占用异常
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1859](../src/scenes/phone/P15_Zjuding/index.tsx#L1859)
2157. 图书馆座位选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1861](../src/scenes/phone/P15_Zjuding/index.tsx#L1861)
2158. 选座菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
2159. 主馆 · 二层 ·
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1870](../src/scenes/phone/P15_Zjuding/index.tsx#L1870)
2160. 查看平面图 ›
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1872](../src/scenes/phone/P15_Zjuding/index.tsx#L1872)
2161. 已切换到下方平面图。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1872](../src/scenes/phone/P15_Zjuding/index.tsx#L1872)
2162. {{selectedRoom}}：座位 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.seats ?? 0}}，当前空闲 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.available ?? 0}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1873](../src/scenes/phone/P15_Zjuding/index.tsx#L1873)
2163. 查看房间详情 ›
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1873](../src/scenes/phone/P15_Zjuding/index.tsx#L1873)
2164. 当前空余 32 个座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1876](../src/scenes/phone/P15_Zjuding/index.tsx#L1876)
2165. 空余 32
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1876](../src/scenes/phone/P15_Zjuding/index.tsx#L1876)
2166. 022调查状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1880](../src/scenes/phone/P15_Zjuding/index.tsx#L1880)
2167. 当前现场状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1883](../src/scenes/phone/P15_Zjuding/index.tsx#L1883)
2168. 书包仍在现场，手机页面只负责查询与提交材料。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1885](../src/scenes/phone/P15_Zjuding/index.tsx#L1885)
2169. 现场已清空，座位等待本人确认。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1885](../src/scenes/phone/P15_Zjuding/index.tsx#L1885)
2170. 预约日期与时段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1890](../src/scenes/phone/P15_Zjuding/index.tsx#L1890)
2171. 座位显示模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1903](../src/scenes/phone/P15_Zjuding/index.tsx#L1903)
2172. 地图模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1904](../src/scenes/phone/P15_Zjuding/index.tsx#L1904)
2173. 列表模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1905](../src/scenes/phone/P15_Zjuding/index.tsx#L1905)
2174. 筛选：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1909](../src/scenes/phone/P15_Zjuding/index.tsx#L1909)
2175. 已选：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1909](../src/scenes/phone/P15_Zjuding/index.tsx#L1909)
2176. 筛选
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1910](../src/scenes/phone/P15_Zjuding/index.tsx#L1910)
2177. 可选座位列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1923](../src/scenes/phone/P15_Zjuding/index.tsx#L1923)
2178. 手机端保留调查记录；书包、小票与 PASS 操作均在图书馆现场完成。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1933](../src/scenes/phone/P15_Zjuding/index.tsx#L1933)
2179. 返回
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1937](../src/scenes/phone/P15_Zjuding/index.tsx#L1937)
2180. 立即预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1939](../src/scenes/phone/P15_Zjuding/index.tsx#L1939)
2181. 预约成功
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1939](../src/scenes/phone/P15_Zjuding/index.tsx#L1939)
2182. 浙大钉首页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1946](../src/scenes/phone/P15_Zjuding/index.tsx#L1946)
2183. 打开个人菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1952](../src/scenes/phone/P15_Zjuding/index.tsx#L1952)
2184. 个人菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1956](../src/scenes/phone/P15_Zjuding/index.tsx#L1956)
2185. 浙江大学
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1963](../src/scenes/phone/P15_Zjuding/index.tsx#L1963)
2186. 打开浙大百事通搜索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1966](../src/scenes/phone/P15_Zjuding/index.tsx#L1966)
2187. 百事通
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1967](../src/scenes/phone/P15_Zjuding/index.tsx#L1967)；[src/scenes/phone/P15_Zjuding/index.tsx:1970](../src/scenes/phone/P15_Zjuding/index.tsx#L1970)
2188. 系统红圈
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1983](../src/scenes/phone/P15_Zjuding/index.tsx#L1983)
2189. 求
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1986](../src/scenes/phone/P15_Zjuding/index.tsx#L1986)；[src/scenes/phone/P15_Zjuding/index.tsx:1989](../src/scenes/phone/P15_Zjuding/index.tsx#L1989)；[src/scenes/phone/P15_Zjuding/index.tsx:2092](../src/scenes/phone/P15_Zjuding/index.tsx#L2092)
2190. /求是学院（归口...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1993](../src/scenes/phone/P15_Zjuding/index.tsx#L1993)
2191. 身份码
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1998](../src/scenes/phone/P15_Zjuding/index.tsx#L1998)；[src/scenes/phone/P15_Zjuding/index.tsx:1999](../src/scenes/phone/P15_Zjuding/index.tsx#L1999)
2192. 校园钱包
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2008](../src/scenes/phone/P15_Zjuding/index.tsx#L2008)；[src/scenes/phone/P15_Zjuding/index.tsx:2009](../src/scenes/phone/P15_Zjuding/index.tsx#L2009)
2193. 搜索浙大钉应用与服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2025](../src/scenes/phone/P15_Zjuding/index.tsx#L2025)
2194. 搜索应用与服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2026](../src/scenes/phone/P15_Zjuding/index.tsx#L2026)
2195. 浙大百事通
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2029](../src/scenes/phone/P15_Zjuding/index.tsx#L2029)；[src/scenes/phone/P15_Zjuding/index.tsx:2104](../src/scenes/phone/P15_Zjuding/index.tsx#L2104)
2196. 浙大钉应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2032](../src/scenes/phone/P15_Zjuding/index.tsx#L2032)
2197. 系统对话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2091](../src/scenes/phone/P15_Zjuding/index.tsx#L2091)
2198. 继续对话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2099](../src/scenes/phone/P15_Zjuding/index.tsx#L2099)
2199. 搜索应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2106](../src/scenes/phone/P15_Zjuding/index.tsx#L2106)
2200. 输入应用名称
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2112](../src/scenes/phone/P15_Zjuding/index.tsx#L2112)
2201. 没有匹配的应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2132](../src/scenes/phone/P15_Zjuding/index.tsx#L2132)
2202. 选择馆舍
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2153](../src/scenes/phone/P15_Zjuding/index.tsx#L2153)
2203. 农医馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2204. 紫金港西区馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2205. 已选择{{library}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2162](../src/scenes/phone/P15_Zjuding/index.tsx#L2162)
2206. 预约日期
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2172](../src/scenes/phone/P15_Zjuding/index.tsx#L2172)
2207. 07月11日 · 明天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2208. 07月12日 · 后天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2209. 预约时段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2183](../src/scenes/phone/P15_Zjuding/index.tsx#L2183)
2210. 筛选座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2194](../src/scenes/phone/P15_Zjuding/index.tsx#L2194)
2211. 安静区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2212. 靠窗
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2213. 有电源
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2214. 当前座位筛选已切换为：{{filter}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2197](../src/scenes/phone/P15_Zjuding/index.tsx#L2197)
2215. 确认预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2205](../src/scenes/phone/P15_Zjuding/index.tsx#L2205)；[src/scenes/phone/P15_Zjuding/index.tsx:2216](../src/scenes/phone/P15_Zjuding/index.tsx#L2216)
2216. 号座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2207](../src/scenes/phone/P15_Zjuding/index.tsx#L2207)
2217. 再想一下
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2213](../src/scenes/phone/P15_Zjuding/index.tsx#L2213)
2218. 学
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:56](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L56)
2219. 课程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2220. 签到
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)
2221. 学习
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:482](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L482)
2222. 智云课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:65](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L65)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:70](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L70)
2223. 云
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:66](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L66)
2224. 课件
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2225. 课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2226. 日程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2227. 校园地图
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1420](../src/scenes/phone/P15_Zjuding/index.tsx#L1420)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:75](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L75)
2228. 位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1423](../src/scenes/phone/P15_Zjuding/index.tsx#L1423)；[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:76](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L76)
2229. 导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
2230. 地图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
2231. 网络缴费
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:85](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L85)
2232. 连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
2233. 校园网
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2234. 账户
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
2235. 后勤服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:95](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L95)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:72](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L72)
2236. 勤
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:96](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L96)
2237. 报修
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2238. 服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:484](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L484)
2239. 网络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2240. 寻
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:106](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L106)
2241. 档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2242. 失物
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2243. 书包
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2244. 证明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2245. 访客预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:115](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L115)
2246. 访
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:116](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L116)
2247. 草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2248. 访客
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2249. 入校
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2250. 预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1812](../src/scenes/phone/P15_Zjuding/index.tsx#L1812)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2251. 图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:126](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L126)
2252. 馆藏
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2253. 图书
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2254. 慧学外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:135](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L135)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:75](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L75)
2255. 词汇
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2256. 卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2257. 外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2258. 英语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2259. 开发反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:145](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L145)
2260. 信
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:146](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L146)
2261. 反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2262. 开发者
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2263. 意见
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2264. 新
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:132](../src/scenes/phone/P15_Zjuding/index.tsx#L132)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:152](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L152)
2265. 全部
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:405](../src/scenes/phone/P15_Zjuding/index.tsx#L405)；[src/scenes/phone/P15_Zjuding/index.tsx:411](../src/scenes/phone/P15_Zjuding/index.tsx#L411)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:156](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L156)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)
2266. 工作台
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:140](../src/scenes/phone/P15_Zjuding/index.tsx#L140)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:86](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L86)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:491](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L491)
2267. 校园参观
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:61](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L61)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2268. 功能建议
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:65](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L65)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2269. 网络账户
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:71](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L71)
2270. 访客预约预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:74](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L74)
2271. 开发者反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:76](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L76)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:472](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L472)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2272. 全部应用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:77](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L77)
2273. 通讯录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:139](../src/scenes/phone/P15_Zjuding/index.tsx#L139)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:78](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L78)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:85](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L85)
2274. 首页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:138](../src/scenes/phone/P15_Zjuding/index.tsx#L138)；[src/scenes/phone/P15_Zjuding/index.tsx:146](../src/scenes/phone/P15_Zjuding/index.tsx#L146)；[src/scenes/phone/P15_Zjuding/index.tsx:1830](../src/scenes/phone/P15_Zjuding/index.tsx#L1830)；[src/scenes/phone/P15_Zjuding/index.tsx:1831](../src/scenes/phone/P15_Zjuding/index.tsx#L1831)；[src/scenes/phone/P15_Zjuding/index.tsx:1832](../src/scenes/phone/P15_Zjuding/index.tsx#L1832)；[src/scenes/phone/P15_Zjuding/index.tsx:2057](../src/scenes/phone/P15_Zjuding/index.tsx#L2057)；[src/scenes/phone/P15_Zjuding/index.tsx:2059](../src/scenes/phone/P15_Zjuding/index.tsx#L2059)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:84](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L84)
2275. 北教学区 A-204
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2276. 化学工程基础
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2277. 课程资料已缓存在本机。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2278. 周一 08:00
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2279. 数据方法与 AI4S
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2280. 线上课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2281. 周三 13:15
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2282. 最近一次课件仅供预览。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2283. 安全提醒已读取，不产生签到记录。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2284. 东教学区 3-106
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2285. 实验室安全
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2286. 周五 10:00
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2287. 导向；路径识别
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:98](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L98)
2288. 倒影；反射
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:99](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L99)
2289. 维修；保养
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:100](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L100)
2290. 书包物品识别报告
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:104](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L104)
2291. 照片·本机识别
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:104](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L104)
2292. 图书馆前台
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:105](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L105)
2293. 基础馆二层南区
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:106](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L106)
2294. 本人到馆证明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:107](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L107)
2295. 浙大体艺·到馆记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:107](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L107)
2296. 游戏反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:112](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L112)
2297. ## 反馈内容 / {{content}} / ## 游戏 / 7:55
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:115](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L115)
2298. ## 反馈内容 / 请描述问题、复现步骤或建议。 / ## 游戏 / 7:55
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:116](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L116)
2299. 校园网已连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:208](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L208)
2300. 当前使用移动数据
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:210](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L210)
2301. 当前处于离线状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:211](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L211)
2302. 校园网状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:223](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L223)
2303. 校园身份已读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:230](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L230)
2304. {{studentName}}·{{studentId}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:231](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L231)
2305. 查看校园卡
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:232](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L232)
2306. 图书馆座位预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:239](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L239)
2307. 已预约 {{state.ui.librarySelectedSeat ?? "022"}} 号座位
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:240](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L240)
2308. 查看图书馆
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:241](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L241)
2309. 图书馆服务已开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:247](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L247)
2310. 当前可用功能以图书馆首页实际状态为准。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:248](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L248)
2311. 打开图书馆
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:249](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L249)
2312. 请先填写意见内容。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:310](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L310)
2313. 反馈草稿已保存。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:315](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L315)
2314. 反馈内容已保留在当前页面。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:316](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L316)
2315. 反馈内容已清空。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:322](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L322)
2316. 本机课程预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:341](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L341)
2317. 门课程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:342](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L342)
2318. 查看课程日程和缓存说明，不产生签到或成绩记录。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:343](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L343)
2319. 课程列表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:345](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L345)
2320. 查看
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)；[src/scenes/phone/P15_Zjuding/index.tsx:1753](../src/scenes/phone/P15_Zjuding/index.tsx#L1753)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:352](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L352)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:390](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L390)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:410](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L410)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2321. 当前连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:365](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L365)
2322. 页面只读取本机网络状态，不扣费、不充值、不生成账单。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:367](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L367)
2323. 可用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2324. 浙大钉与 CC98 需要校园网。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2325. 备用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
2326. 浙大体艺的网络规则与浙大钉不同。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
2327. 查看连接说明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:374](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L374)
2328. 收起连接说明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:374](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L374)
2329. 如需切换网络，请返回手机控制中心。本页不会自动修改网络模式。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:377](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L377)
2330. 校园服务聚合
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:385](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L385)
2331. 后勤状态台
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:386](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L386)
2332. 所有条目只读取已开放的本地功能，未提交任何报修工单。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:387](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L387)
2333. 网络服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:390](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L390)
2334. 当前阶段未开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2335. 进入
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2336. 图书馆服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1504](../src/scenes/phone/P15_Zjuding/index.tsx#L1504)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)
2337. 未开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2338. 已开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2339. 校园导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2340. 部门黄页可用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2341. 服务联络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2342. 公共联络表可查看
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2343. 仅显示已公开记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:401](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L401)
2344. 份本机档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:402](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L402)
2345. 查看档案不会生成证明、改变物品或推进图书馆进度。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:403](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L403)
2346. 已公开失物档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:406](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L406)
2347. 本机已取得
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:409](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L409)
2348. 后续只会在相关记录真正取得后显示。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:415](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L415)
2349. 暂无已公开档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:415](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L415)
2350. 本机预览工具
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:423](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L423)
2351. 访客信息草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:424](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L424)
2352. 草稿仅保存在当前浏览器会话，不代表正式入校申请。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:425](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L425)
2353. 访客预览草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:427](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L427)
2354. 访客姓名
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:428](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L428)
2355. 用于本机预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:428](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L428)
2356. 到访日期
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:429](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L429)
2357. 例如：08月24日
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:429](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L429)
2358. 到访用途
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2359. 亲友来访
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2360. 学术交流
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2361. 保存预览草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:431](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L431)
2362. 清空
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:431](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L431)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:475](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L475)
2363. 未提交·本机预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:433](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L433)
2364. 本地微卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:441](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L441)
2365. 校园场景外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:442](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L442)
2366. 点击卡片查看中文释义与场景例句。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:443](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L443)
2367. 外语卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:445](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L445)
2368. 点击查看释义
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:450](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L450)
2369. 7:55 开发者通道
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:464](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L464)
2370. 向开发团队反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:465](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L465)
2371. 整理问题或建议后，可直接前往 GitHub 提交 Issue。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:466](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L466)
2372. 7:55 开发者链接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:468](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L468)
2373. GitHub 仓库
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:469](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L469)
2374. 提交 Issue
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:470](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L470)
2375. 交互问题
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2376. 内容校对
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2377. 反馈内容
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:474](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L474)
2378. 描述问题、复现步骤或建议
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:474](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L474)
2379. 保存草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:475](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L475)
2380. 校园
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:483](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L483)
2381. 统一应用目录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:490](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L490)
2382. 应用状态与首页、搜索完全一致。未开放项保留原名称与静态图标。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:492](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L492)
2383. 校园公开联络表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:521](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L521)
2384. 个服务联络点
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:522](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L522)
2385. 号码来自当前游戏内容，页面不会直接拨号。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:523](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L523)
2386. 部门联系方式
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:525](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L525)
2387. 部门黄页会在剧情恢复校园身份后开放。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:530](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L530)
2388. 打开部门黄页
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:530](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L530)
2389. 当前已公开状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:537](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L537)
2390. 条消息
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:538](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L538)
2391. 只聚合已发生的网络、身份、预约和记录状态。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:539](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L539)
2392. 消息列表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:541](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L541)
2393. 已读
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:558](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L558)
2394. 取得电子校园卡后显示
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2395. 身份未读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1963](../src/scenes/phone/P15_Zjuding/index.tsx#L1963)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2396. 校园身份
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2397. 当前网络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:572](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L572)
2398. 详情
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:572](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L572)
2399. 未读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
2400. 已读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
2401. 当前无预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2402. 图书馆预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2403. 座位 {{state.ui.librarySelectedSeat ?? "022"}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2404. GitHub Issues
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2405. 返回，离开{{PANEL\_TITLES\[panel\]}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:586](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L586)
2406. 浙大钉导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:592](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L592)
2407. 基础图书馆入口 · {{RPG\_CONTROL\_HINTS.libraryGate}}
   来源：[src/scenes/rpg/BootScene.ts:170](../src/scenes/rpg/BootScene.ts#L170)
2408. 东区大食堂入口 · {{formatRpgInteractionHint("进入食堂")}}
   来源：[src/scenes/rpg/BootScene.ts:175](../src/scenes/rpg/BootScene.ts#L175)
2409. 剧场入口 · {{formatRpgInteractionHint("进入剧场")}}
   来源：[src/scenes/rpg/BootScene.ts:180](../src/scenes/rpg/BootScene.ts#L180)
2410. 共享单车
   来源：[src/scenes/rpg/BootScene.ts:569](../src/scenes/rpg/BootScene.ts#L569)；[src/scenes/rpg/BootScene.ts:578](../src/scenes/rpg/BootScene.ts#L578)；[src/scenes/rpg/BootScene.ts:586](../src/scenes/rpg/BootScene.ts#L586)；[src/scenes/rpg/BootScene.ts:597](../src/scenes/rpg/BootScene.ts#L597)；[src/scenes/rpg/RpgGameHost.tsx:1244](../src/scenes/rpg/RpgGameHost.tsx#L1244)；[src/scenes/rpg/RpgItemUseGuidance.ts:206](../src/scenes/rpg/RpgItemUseGuidance.ts#L206)；[src/scenes/rpg/RpgItemUseGuidance.ts:207](../src/scenes/rpg/RpgItemUseGuidance.ts#L207)；[src/scenes/rpg/RpgItemUseGuidance.ts:208](../src/scenes/rpg/RpgItemUseGuidance.ts#L208)；[src/scenes/rpg/RpgItemUseGuidance.ts:209](../src/scenes/rpg/RpgItemUseGuidance.ts#L209)
2411. 共享单车交互尚未开放，请先完成食堂内部流程。
   来源：[src/scenes/rpg/BootScene.ts:570](../src/scenes/rpg/BootScene.ts#L570)
2412. wrong\_item
   来源：[src/scenes/rpg/BootScene.ts:577](../src/scenes/rpg/BootScene.ts#L577)；[src/scenes/rpg/RpgGameHost.tsx:1180](../src/scenes/rpg/RpgGameHost.tsx#L1180)
2413. 共享单车当前只接收纸巾或 2 元现金。
   来源：[src/scenes/rpg/BootScene.ts:579](../src/scenes/rpg/BootScene.ts#L579)
2414. missed\_target
   来源：[src/scenes/rpg/BootScene.ts:586](../src/scenes/rpg/BootScene.ts#L586)；[src/scenes/rpg/BootScene.ts:596](../src/scenes/rpg/BootScene.ts#L596)；[src/scenes/rpg/RpgInventoryDock.tsx:370](../src/scenes/rpg/RpgInventoryDock.tsx#L370)
2415. 松手点没有进入共享单车车身的高亮范围。
   来源：[src/scenes/rpg/BootScene.ts:598](../src/scenes/rpg/BootScene.ts#L598)
2416. success
   来源：[src/scenes/rpg/BootScene.ts:622](../src/scenes/rpg/BootScene.ts#L622)
2417. campus-minimap
   来源：[src/scenes/rpg/RpgCameraController.ts:22](../src/scenes/rpg/RpgCameraController.ts#L22)
2418. WASD 移动
   来源：[src/scenes/rpg/RpgControlHints.ts:2](../src/scenes/rpg/RpgControlHints.ts#L2)
2419. 空格键
   来源：[src/scenes/rpg/RpgControlHints.ts:3](../src/scenes/rpg/RpgControlHints.ts#L3)
2420. WASD 移动 · 空格键进入
   来源：[src/scenes/rpg/RpgControlHints.ts:4](../src/scenes/rpg/RpgControlHints.ts#L4)
2421. 空格键继续
   来源：[src/scenes/rpg/RpgControlHints.ts:5](../src/scenes/rpg/RpgControlHints.ts#L5)
2422. 拖动道具 {{label}}
   来源：[src/scenes/rpg/RpgControlHints.ts:14](../src/scenes/rpg/RpgControlHints.ts#L14)
2423. 启真湖的帖子已经归档,不能再补拍了。
   来源：[src/scenes/rpg/RpgGameHost.tsx:213](../src/scenes/rpg/RpgGameHost.tsx#L213)
2424. 这里构不成画面,换个位置再试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:214](../src/scenes/rpg/RpgGameHost.tsx#L214)
2425. 这张照片已经不在记录里了,重新拍一张。
   来源：[src/scenes/rpg/RpgGameHost.tsx:215](../src/scenes/rpg/RpgGameHost.tsx#L215)
2426. 草稿和照片对不上,请重新拍摄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:216](../src/scenes/rpg/RpgGameHost.tsx#L216)
2427. 先把该选的都选好,再存草稿。
   来源：[src/scenes/rpg/RpgGameHost.tsx:217](../src/scenes/rpg/RpgGameHost.tsx#L217)
2428. {{targetLabel}}已完成当前操作。
   来源：[src/scenes/rpg/RpgGameHost.tsx:317](../src/scenes/rpg/RpgGameHost.tsx#L317)
2429. 切到浅色操作后再使用道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:318](../src/scenes/rpg/RpgGameHost.tsx#L318)
2430. {{targetLabel}}当前需要其他道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:319](../src/scenes/rpg/RpgGameHost.tsx#L319)
2431. 当前目标还没有观察记录；深色观察可补充坐标。
   来源：[src/scenes/rpg/RpgGameHost.tsx:320](../src/scenes/rpg/RpgGameHost.tsx#L320)
2432. 普通鱼钩无法固定纸条。需要完成湖区道具链。
   来源：[src/scenes/rpg/RpgGameHost.tsx:321](../src/scenes/rpg/RpgGameHost.tsx#L321)
2433. 这个目标已经完成，请查看当前任务。
   来源：[src/scenes/rpg/RpgGameHost.tsx:322](../src/scenes/rpg/RpgGameHost.tsx#L322)
2434. 当前剧情条件尚未满足。
   来源：[src/scenes/rpg/RpgGameHost.tsx:323](../src/scenes/rpg/RpgGameHost.tsx#L323)
2435. 该交互点当前未开放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:324](../src/scenes/rpg/RpgGameHost.tsx#L324)
2436. 当前操作已记录。
   来源：[src/scenes/rpg/RpgGameHost.tsx:342](../src/scenes/rpg/RpgGameHost.tsx#L342)
2437. 当前操作已经完成。
   来源：[src/scenes/rpg/RpgGameHost.tsx:343](../src/scenes/rpg/RpgGameHost.tsx#L343)
2438. 切换到目标要求的现实模式后重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:344](../src/scenes/rpg/RpgGameHost.tsx#L344)
2439. 当前流程还不能安装手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1118](../src/scenes/rpg/RpgGameHost.tsx#L1118)
2440. active
   来源：[src/scenes/rpg/RpgGameHost.tsx:1123](../src/scenes/rpg/RpgGameHost.tsx#L1123)
2441. 角色
   来源：[src/scenes/rpg/RpgGameHost.tsx:1124](../src/scenes/rpg/RpgGameHost.tsx#L1124)；[src/scenes/rpg/RpgItemUseGuidance.ts:130](../src/scenes/rpg/RpgItemUseGuidance.ts#L130)；[src/scenes/rpg/RpgItemUseGuidance.ts:131](../src/scenes/rpg/RpgItemUseGuidance.ts#L131)；[src/scenes/rpg/RpgItemUseGuidance.ts:132](../src/scenes/rpg/RpgItemUseGuidance.ts#L132)；[src/scenes/rpg/RpgItemUseGuidance.ts:133](../src/scenes/rpg/RpgItemUseGuidance.ts#L133)
2442. unavailable
   来源：[src/scenes/rpg/RpgGameHost.tsx:1146](../src/scenes/rpg/RpgGameHost.tsx#L1146)；[src/scenes/rpg/RpgGameHost.tsx:1154](../src/scenes/rpg/RpgGameHost.tsx#L1154)；[src/scenes/rpg/RpgGameHost.tsx:1212](../src/scenes/rpg/RpgGameHost.tsx#L1212)
2443. wrong\_target
   来源：[src/scenes/rpg/RpgGameHost.tsx:1171](../src/scenes/rpg/RpgGameHost.tsx#L1171)；[src/scenes/rpg/RpgGameHost.tsx:1180](../src/scenes/rpg/RpgGameHost.tsx#L1180)；[src/scenes/rpg/RpgInteractionContract.ts:1288](../src/scenes/rpg/RpgInteractionContract.ts#L1288)
2444. cleaned
   来源：[src/scenes/rpg/RpgGameHost.tsx:1235](../src/scenes/rpg/RpgGameHost.tsx#L1235)
2445. 共享单车车锁
   来源：[src/scenes/rpg/RpgGameHost.tsx:1236](../src/scenes/rpg/RpgGameHost.tsx#L1236)；[src/scenes/rpg/RpgItemUseGuidance.ts:202](../src/scenes/rpg/RpgItemUseGuidance.ts#L202)；[src/scenes/rpg/RpgItemUseGuidance.ts:203](../src/scenes/rpg/RpgItemUseGuidance.ts#L203)
2446. 清洁车锁需要浅色操作。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1237](../src/scenes/rpg/RpgGameHost.tsx#L1237)
2447. rule
   来源：[src/scenes/rpg/RpgGameHost.tsx:1237](../src/scenes/rpg/RpgGameHost.tsx#L1237)；[src/scenes/rpg/RpgGameHost.tsx:1245](../src/scenes/rpg/RpgGameHost.tsx#L1245)
2448. paid
   来源：[src/scenes/rpg/RpgGameHost.tsx:1243](../src/scenes/rpg/RpgGameHost.tsx#L1243)
2449. 付款需要浅色操作，且车锁表面已经清洁。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1245](../src/scenes/rpg/RpgGameHost.tsx#L1245)
2450. 入口海报
   来源：[src/scenes/rpg/RpgGameHost.tsx:1256](../src/scenes/rpg/RpgGameHost.tsx#L1256)；[src/scenes/rpg/RpgItemUseGuidance.ts:217](../src/scenes/rpg/RpgItemUseGuidance.ts#L217)；[src/scenes/rpg/RpgItemUseGuidance.ts:218](../src/scenes/rpg/RpgItemUseGuidance.ts#L218)
2451. 检票闸机右侧读票器
   来源：[src/scenes/rpg/RpgGameHost.tsx:1269](../src/scenes/rpg/RpgGameHost.tsx#L1269)；[src/scenes/rpg/RpgItemUseGuidance.ts:224](../src/scenes/rpg/RpgItemUseGuidance.ts#L224)；[src/scenes/rpg/RpgItemUseGuidance.ts:227](../src/scenes/rpg/RpgItemUseGuidance.ts#L227)
2452. 验票完成，闸机已经放行；临时观演票会保留。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1271](../src/scenes/rpg/RpgGameHost.tsx#L1271)
2453. 当前剧情条件不允许验票，请先完成入口取票流程。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1272](../src/scenes/rpg/RpgGameHost.tsx#L1272)
2454. 道具箱旁票据扫描器
   来源：[src/scenes/rpg/RpgGameHost.tsx:1294](../src/scenes/rpg/RpgGameHost.tsx#L1294)；[src/scenes/rpg/RpgItemUseGuidance.ts:234](../src/scenes/rpg/RpgItemUseGuidance.ts#L234)；[src/scenes/rpg/RpgItemUseGuidance.ts:237](../src/scenes/rpg/RpgItemUseGuidance.ts#L237)
2455. 票据扫描完成，道具箱已经解锁；临时观演票已完成用途并从道具栏移除。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1296](../src/scenes/rpg/RpgGameHost.tsx#L1296)
2456. 扫描票据需要浅色操作、临时观演票和当前道具布置阶段。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1297](../src/scenes/rpg/RpgGameHost.tsx#L1297)
2457. 后台通风口
   来源：[src/scenes/rpg/RpgGameHost.tsx:1304](../src/scenes/rpg/RpgGameHost.tsx#L1304)；[src/scenes/rpg/RpgItemUseGuidance.ts:249](../src/scenes/rpg/RpgItemUseGuidance.ts#L249)；[src/scenes/rpg/RpgItemUseGuidance.ts:252](../src/scenes/rpg/RpgItemUseGuidance.ts#L252)；[src/scenes/rpg/RpgItemUseGuidance.ts:254](../src/scenes/rpg/RpgItemUseGuidance.ts#L254)
2458. 灯光控制台
   来源：[src/scenes/rpg/RpgGameHost.tsx:1311](../src/scenes/rpg/RpgGameHost.tsx#L1311)；[src/scenes/rpg/RpgItemUseGuidance.ts:258](../src/scenes/rpg/RpgItemUseGuidance.ts#L258)；[src/scenes/rpg/RpgItemUseGuidance.ts:261](../src/scenes/rpg/RpgItemUseGuidance.ts#L261)；[src/scenes/rpg/RpgItemUseGuidance.ts:263](../src/scenes/rpg/RpgItemUseGuidance.ts#L263)
2459. 你被救起并送回寝室。先找到吹风机。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1371](../src/scenes/rpg/RpgGameHost.tsx#L1371)
2460. 浮排边钓鱼竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:1391](../src/scenes/rpg/RpgGameHost.tsx#L1391)
2461. fishingRod
   来源：[src/scenes/rpg/RpgGameHost.tsx:1391](../src/scenes/rpg/RpgGameHost.tsx#L1391)；[src/scenes/rpg/RpgGameHost.tsx:1410](../src/scenes/rpg/RpgGameHost.tsx#L1410)；[src/scenes/rpg/RpgGameHost.tsx:1419](../src/scenes/rpg/RpgGameHost.tsx#L1419)；[src/scenes/rpg/RpgGameHost.tsx:2147](../src/scenes/rpg/RpgGameHost.tsx#L2147)
2462. 钓鱼竿装饵框
   来源：[src/scenes/rpg/RpgGameHost.tsx:1394](../src/scenes/rpg/RpgGameHost.tsx#L1394)；[src/scenes/rpg/RpgItemUseGuidance.ts:300](../src/scenes/rpg/RpgItemUseGuidance.ts#L300)
2463. decoyPaper
   来源：[src/scenes/rpg/RpgGameHost.tsx:1394](../src/scenes/rpg/RpgGameHost.tsx#L1394)
2464. 已观察抛竿点
   来源：[src/scenes/rpg/RpgGameHost.tsx:1400](../src/scenes/rpg/RpgGameHost.tsx#L1400)
2465. 湖区道具点
   来源：[src/scenes/rpg/RpgGameHost.tsx:1405](../src/scenes/rpg/RpgGameHost.tsx#L1405)
2466. 工具装配框
   来源：[src/scenes/rpg/RpgGameHost.tsx:1410](../src/scenes/rpg/RpgGameHost.tsx#L1410)；[src/scenes/rpg/RpgItemUseGuidance.ts:293](../src/scenes/rpg/RpgItemUseGuidance.ts#L293)；[src/scenes/rpg/RpgItemUseGuidance.ts:319](../src/scenes/rpg/RpgItemUseGuidance.ts#L319)；[src/scenes/rpg/RpgItemUseGuidance.ts:322](../src/scenes/rpg/RpgItemUseGuidance.ts#L322)；[src/scenes/rpg/RpgItemUseGuidance.ts:324](../src/scenes/rpg/RpgItemUseGuidance.ts#L324)；[src/scenes/rpg/RpgItemUseGuidance.ts:325](../src/scenes/rpg/RpgItemUseGuidance.ts#L325)；[src/scenes/rpg/RpgItemUseGuidance.ts:363](../src/scenes/rpg/RpgItemUseGuidance.ts#L363)；[src/scenes/rpg/RpgItemUseGuidance.ts:366](../src/scenes/rpg/RpgItemUseGuidance.ts#L366)；[src/scenes/rpg/RpgItemUseGuidance.ts:367](../src/scenes/rpg/RpgItemUseGuidance.ts#L367)；[src/scenes/rpg/RpgItemUseGuidance.ts:368](../src/scenes/rpg/RpgItemUseGuidance.ts#L368)
2467. 黑天鹅投喂区
   来源：[src/scenes/rpg/RpgGameHost.tsx:1416](../src/scenes/rpg/RpgGameHost.tsx#L1416)；[src/scenes/rpg/RpgItemUseGuidance.ts:355](../src/scenes/rpg/RpgItemUseGuidance.ts#L355)；[src/scenes/rpg/RpgItemUseGuidance.ts:358](../src/scenes/rpg/RpgItemUseGuidance.ts#L358)
2468. 黑天鹅围栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:1419](../src/scenes/rpg/RpgGameHost.tsx#L1419)
2469. 纸条本体水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:1423](../src/scenes/rpg/RpgGameHost.tsx#L1423)；[src/scenes/rpg/RpgItemUseGuidance.ts:374](../src/scenes/rpg/RpgItemUseGuidance.ts#L374)；[src/scenes/rpg/RpgItemUseGuidance.ts:376](../src/scenes/rpg/RpgItemUseGuidance.ts#L376)；[src/scenes/rpg/RpgItemUseGuidance.ts:377](../src/scenes/rpg/RpgItemUseGuidance.ts#L377)
2470. 电子校园卡：{{actOneContent.studentName}} · {{actOneContent.studentId}}
   来源：[src/scenes/rpg/RpgGameHost.tsx:1834](../src/scenes/rpg/RpgGameHost.tsx#L1834)
2471. 电子校园卡：身份信息尚未读取
   来源：[src/scenes/rpg/RpgGameHost.tsx:1835](../src/scenes/rpg/RpgGameHost.tsx#L1835)
2472. 手柄已连接：WASD 或方向键移动，空格键交互。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1844](../src/scenes/rpg/RpgGameHost.tsx#L1844)
2473. 手柄有电，角色还没有姓名。去部门黄页读取校园卡。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1845](../src/scenes/rpg/RpgGameHost.tsx#L1845)
2474. 手柄已连接，浙大体艺还没有开始课外锻炼。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1846](../src/scenes/rpg/RpgGameHost.tsx#L1846)
2475. 道具栏里没有手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1847](../src/scenes/rpg/RpgGameHost.tsx#L1847)
2476. 当前任务还没有开放手柄控制。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1848](../src/scenes/rpg/RpgGameHost.tsx#L1848)
2477. 使用游戏手柄
   来源：[src/scenes/rpg/RpgGameHost.tsx:2072](../src/scenes/rpg/RpgGameHost.tsx#L2072)
2478. 单击连接手柄，双击查看完整详情
   来源：[src/scenes/rpg/RpgGameHost.tsx:2073](../src/scenes/rpg/RpgGameHost.tsx#L2073)
2479. gamepad
   来源：[src/scenes/rpg/RpgGameHost.tsx:2077](../src/scenes/rpg/RpgGameHost.tsx#L2077)
2480. 手柄
   来源：[src/scenes/rpg/RpgGameHost.tsx:2078](../src/scenes/rpg/RpgGameHost.tsx#L2078)
2481. 左收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2135](../src/scenes/rpg/RpgGameHost.tsx#L2135)
2482. S 提竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:2141](../src/scenes/rpg/RpgGameHost.tsx#L2141)
2483. 提竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:2148](../src/scenes/rpg/RpgGameHost.tsx#L2148)
2484. D 右收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2154](../src/scenes/rpg/RpgGameHost.tsx#L2154)
2485. warningSignPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2160](../src/scenes/rpg/RpgGameHost.tsx#L2160)；[src/scenes/rpg/RpgGameHost.tsx:2191](../src/scenes/rpg/RpgGameHost.tsx#L2191)
2486. 右收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2161](../src/scenes/rpg/RpgGameHost.tsx#L2161)
2487. 皮划艇划桨手势和交互按钮
   来源：[src/scenes/rpg/RpgGameHost.tsx:2166](../src/scenes/rpg/RpgGameHost.tsx#L2166)
2488. 左桨，上划前进，下划后退，轻触默认前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2170](../src/scenes/rpg/RpgGameHost.tsx#L2170)
2489. willowBranchPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2177](../src/scenes/rpg/RpgGameHost.tsx#L2177)
2490. 左桨
   来源：[src/scenes/rpg/RpgGameHost.tsx:2178](../src/scenes/rpg/RpgGameHost.tsx#L2178)
2491. ↑ 前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2179](../src/scenes/rpg/RpgGameHost.tsx#L2179)；[src/scenes/rpg/RpgGameHost.tsx:2193](../src/scenes/rpg/RpgGameHost.tsx#L2193)
2492. ↑前进 · ↓后退
   来源：[src/scenes/rpg/RpgGameHost.tsx:2179](../src/scenes/rpg/RpgGameHost.tsx#L2179)；[src/scenes/rpg/RpgGameHost.tsx:2193](../src/scenes/rpg/RpgGameHost.tsx#L2193)
2493. ↓ 后退
   来源：[src/scenes/rpg/RpgGameHost.tsx:2179](../src/scenes/rpg/RpgGameHost.tsx#L2179)；[src/scenes/rpg/RpgGameHost.tsx:2193](../src/scenes/rpg/RpgGameHost.tsx#L2193)
2494. 右桨，上划前进，下划后退，轻触默认前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2184](../src/scenes/rpg/RpgGameHost.tsx#L2184)
2495. 右桨
   来源：[src/scenes/rpg/RpgGameHost.tsx:2192](../src/scenes/rpg/RpgGameHost.tsx#L2192)
2496. 交互（键盘为空格键）
   来源：[src/scenes/rpg/RpgGameHost.tsx:2211](../src/scenes/rpg/RpgGameHost.tsx#L2211)
2497. 请将设备横过来继续 RPG
   来源：[src/scenes/rpg/RpgGameHost.tsx:2220](../src/scenes/rpg/RpgGameHost.tsx#L2220)
2498. 点击闸机小屏，核对入馆与到达时间
   来源：[src/scenes/rpg/RpgGameHost.tsx:2251](../src/scenes/rpg/RpgGameHost.tsx#L2251)
2499. 前往二层南区寻找 022
   来源：[src/scenes/rpg/RpgGameHost.tsx:2251](../src/scenes/rpg/RpgGameHost.tsx#L2251)
2500. 调查纸条提到的公开记录
   来源：[src/scenes/rpg/RpgGameHost.tsx:2252](../src/scenes/rpg/RpgGameHost.tsx#L2252)
2501. 检查书包旁边的占座纸条
   来源：[src/scenes/rpg/RpgGameHost.tsx:2252](../src/scenes/rpg/RpgGameHost.tsx#L2252)
2502. 用占座纸条查找公开记录
   来源：[src/scenes/rpg/RpgGameHost.tsx:2254](../src/scenes/rpg/RpgGameHost.tsx#L2254)
2503. 并行收集四项公示材料（{{evidenceReadyCount}}/4）
   来源：[src/scenes/rpg/RpgGameHost.tsx:2262](../src/scenes/rpg/RpgGameHost.tsx#L2262)
2504. 把已取得材料上传到 CC98
   来源：[src/scenes/rpg/RpgGameHost.tsx:2263](../src/scenes/rpg/RpgGameHost.tsx#L2263)
2505. 确认系统说明，开始筛选有效回复
   来源：[src/scenes/rpg/RpgGameHost.tsx:2265](../src/scenes/rpg/RpgGameHost.tsx#L2265)
2506. 让证据公示进入 CC98 十大
   来源：[src/scenes/rpg/RpgGameHost.tsx:2266](../src/scenes/rpg/RpgGameHost.tsx#L2266)
2507. 完成图书馆座位恢复申请
   来源：[src/scenes/rpg/RpgGameHost.tsx:2267](../src/scenes/rpg/RpgGameHost.tsx#L2267)
2508. 对 022 书包使用离座清退 PASS
   来源：[src/scenes/rpg/RpgGameHost.tsx:2268](../src/scenes/rpg/RpgGameHost.tsx#L2268)
2509. 坐到已经恢复的 022
   来源：[src/scenes/rpg/RpgGameHost.tsx:2269](../src/scenes/rpg/RpgGameHost.tsx#L2269)
2510. 与 022 继续对话
   来源：[src/scenes/rpg/RpgGameHost.tsx:2270](../src/scenes/rpg/RpgGameHost.tsx#L2270)
2511. 追上逃跑的记录纸条
   来源：[src/scenes/rpg/RpgGameHost.tsx:2271](../src/scenes/rpg/RpgGameHost.tsx#L2271)
2512. 前往基础图书馆，寻找系统的朋友
   来源：[src/scenes/rpg/RpgGameHost.tsx:2272](../src/scenes/rpg/RpgGameHost.tsx#L2272)
2513. 说明
   来源：[src/scenes/rpg/RpgGameHost.tsx:2281](../src/scenes/rpg/RpgGameHost.tsx#L2281)
2514. 调查
   来源：[src/scenes/rpg/RpgGameHost.tsx:2295](../src/scenes/rpg/RpgGameHost.tsx#L2295)
2515. 公告栏前的签到记录纸条
   来源：[src/scenes/rpg/RpgInteractionContract.ts:472](../src/scenes/rpg/RpgInteractionContract.ts#L472)
2516. 一楼旧钟
   来源：[src/scenes/rpg/RpgInteractionContract.ts:490](../src/scenes/rpg/RpgInteractionContract.ts#L490)
2517. 与一楼前台值班助理交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:572](../src/scenes/rpg/RpgInteractionContract.ts#L572)
2518. 与二楼电梯口值班安全员交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:587](../src/scenes/rpg/RpgInteractionContract.ts#L587)
2519. 与三楼参照教室教师交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:597](../src/scenes/rpg/RpgInteractionContract.ts#L597)
2520. 查看苏步青生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:607](../src/scenes/rpg/RpgInteractionContract.ts#L607)
2521. 查看竺可桢生平与竺老两问
   来源：[src/scenes/rpg/RpgInteractionContract.ts:617](../src/scenes/rpg/RpgInteractionContract.ts#L617)
2522. 查看路甬祥生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:627](../src/scenes/rpg/RpgInteractionContract.ts#L627)
2523. 查看陈建功生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:637](../src/scenes/rpg/RpgInteractionContract.ts#L637)
2524. 查看谈家桢生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:647](../src/scenes/rpg/RpgInteractionContract.ts#L647)
2525. 查看程开甲生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:657](../src/scenes/rpg/RpgInteractionContract.ts#L657)
2526. 观察 104 黑板擦痕
   来源：[src/scenes/rpg/RpgInteractionContract.ts:667](../src/scenes/rpg/RpgInteractionContract.ts#L667)
2527. 检查 105 讲台回放
   来源：[src/scenes/rpg/RpgInteractionContract.ts:683](../src/scenes/rpg/RpgInteractionContract.ts#L683)
2528. 三楼晨间教室布置参照
   来源：[src/scenes/rpg/RpgInteractionContract.ts:699](../src/scenes/rpg/RpgInteractionContract.ts#L699)
2529. 204 教室残影组
   来源：[src/scenes/rpg/RpgInteractionContract.ts:712](../src/scenes/rpg/RpgInteractionContract.ts#L712)
2530. mismatched\_nonce
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1282](../src/scenes/rpg/RpgInteractionContract.ts#L1282)
2531. wrong\_scene
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1285](../src/scenes/rpg/RpgInteractionContract.ts#L1285)
2532. wrong\_bounds
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1291](../src/scenes/rpg/RpgInteractionContract.ts#L1291)
2533. stale\_projection
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1296](../src/scenes/rpg/RpgInteractionContract.ts#L1296)
2534. invalid\_player
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1305](../src/scenes/rpg/RpgInteractionContract.ts#L1305)
2535. spatial\_claim\_mismatch
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1321](../src/scenes/rpg/RpgInteractionContract.ts#L1321)
2536. 需要{{contract.label}}：{{contract.shortHint}}
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1563](../src/scenes/rpg/RpgInteractionContract.ts#L1563)
2537. 目标
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:111](../src/scenes/rpg/RpgInventoryDock.tsx#L111)
2538. 目标命中，使用成功
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:117](../src/scenes/rpg/RpgInventoryDock.tsx#L117)
2539. {{targetLabel}}已接收该道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:118](../src/scenes/rpg/RpgInventoryDock.tsx#L118)
2540. 目标命中，人物距离不足
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:125](../src/scenes/rpg/RpgInventoryDock.tsx#L125)
2541. 靠近「{{targetLabel}}」后再拖入道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:126](../src/scenes/rpg/RpgInventoryDock.tsx#L126)
2542. 目标命中，道具不匹配
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:133](../src/scenes/rpg/RpgInventoryDock.tsx#L133)
2543. 「{{targetLabel}}」需要另一类道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:134](../src/scenes/rpg/RpgInventoryDock.tsx#L134)
2544. 没有放进目标范围
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:141](../src/scenes/rpg/RpgInventoryDock.tsx#L141)
2545. 请把道具放到画面中对应的真实物体上。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:142](../src/scenes/rpg/RpgInventoryDock.tsx#L142)
2546. 当前模式不能执行该动作
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:149](../src/scenes/rpg/RpgInventoryDock.tsx#L149)
2547. 切回浅色操作后，再把道具拖入目标范围。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:150](../src/scenes/rpg/RpgInventoryDock.tsx#L150)
2548. 目标位置尚未记录
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:157](../src/scenes/rpg/RpgInventoryDock.tsx#L157)
2549. 深色观察可以补充目标坐标；浅色操作仍可直接作用于画面中清晰可见的实体目标。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:158](../src/scenes/rpg/RpgInventoryDock.tsx#L158)
2550. 纸张无法直接钓取
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:165](../src/scenes/rpg/RpgInventoryDock.tsx#L165)
2551. 钓钩无法固定纸张。检查已获得的工具，补充适合金属夹具的连接方式。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:166](../src/scenes/rpg/RpgInventoryDock.tsx#L166)
2552. 当前步骤已经完成
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:173](../src/scenes/rpg/RpgInventoryDock.tsx#L173)
2553. 无需重复使用该道具，继续查看当前任务。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:174](../src/scenes/rpg/RpgInventoryDock.tsx#L174)
2554. 此处无需拖动
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:181](../src/scenes/rpg/RpgInventoryDock.tsx#L181)
2555. 靠近对应位置或完成页面操作时会自动核验。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:182](../src/scenes/rpg/RpgInventoryDock.tsx#L182)
2556. 本场景没有使用点
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:189](../src/scenes/rpg/RpgInventoryDock.tsx#L189)；[src/scenes/rpg/RpgItemUseGuidance.ts:63](../src/scenes/rpg/RpgItemUseGuidance.ts#L63)
2557. 保留该道具，跟随当前任务前往对应页面或场景。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:190](../src/scenes/rpg/RpgInventoryDock.tsx#L190)；[src/scenes/rpg/RpgItemUseGuidance.ts:64](../src/scenes/rpg/RpgItemUseGuidance.ts#L64)
2558. 当前使用条件未满足
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:196](../src/scenes/rpg/RpgInventoryDock.tsx#L196)；[src/scenes/rpg/RpgItemUseGuidance.ts:50](../src/scenes/rpg/RpgItemUseGuidance.ts#L50)
2559. 「{{targetLabel}}」当前还不能接收该道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:197](../src/scenes/rpg/RpgInventoryDock.tsx#L197)
2560. consumed
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:225](../src/scenes/rpg/RpgInventoryDock.tsx#L225)
2561. 道具没有进入游戏画布，请拖到场景中的对应物体。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:371](../src/scenes/rpg/RpgInventoryDock.tsx#L371)
2562. RPG 道具栏
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:389](../src/scenes/rpg/RpgInventoryDock.tsx#L389)
2563. 道具
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:392](../src/scenes/rpg/RpgInventoryDock.tsx#L392)
2564. 靠近目标 · 拖到目标上
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:393](../src/scenes/rpg/RpgInventoryDock.tsx#L393)
2565. 目标：{{guidance.targetLabel}}。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:398](../src/scenes/rpg/RpgInventoryDock.tsx#L398)
2566. 拖动{{ITEM\_META\[itemId\].name}}，{{isPaperItem(itemId) ? "单击" : "双击"}}查看详情
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:412](../src/scenes/rpg/RpgInventoryDock.tsx#L412)
2567. {{ITEM\_META\[itemId\].name}}：{{ITEM\_META\[itemId\].desc}}
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:414](../src/scenes/rpg/RpgInventoryDock.tsx#L414)
2568. 校园卡在手机应用和地图入口中读取
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:13](../src/scenes/rpg/RpgItemUseGuidance.ts#L13)
2569. 前往 CC98 搜索栏提交占座纸条
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:14](../src/scenes/rpg/RpgItemUseGuidance.ts#L14)
2570. 前往 CC98 证据上传区提交旧版规定
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:15](../src/scenes/rpg/RpgItemUseGuidance.ts#L15)
2571. 前往 CC98 或恢复申请页面提交证明
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:16](../src/scenes/rpg/RpgItemUseGuidance.ts#L16)；[src/scenes/rpg/RpgItemUseGuidance.ts:18](../src/scenes/rpg/RpgItemUseGuidance.ts#L18)
2572. 前往 CC98 或恢复申请页面提交凭据
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:17](../src/scenes/rpg/RpgItemUseGuidance.ts#L17)
2573. 到食堂左下角混合台倒入玻璃杯
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:19](../src/scenes/rpg/RpgItemUseGuidance.ts#L19)；[src/scenes/rpg/RpgItemUseGuidance.ts:20](../src/scenes/rpg/RpgItemUseGuidance.ts#L20)；[src/scenes/rpg/RpgItemUseGuidance.ts:21](../src/scenes/rpg/RpgItemUseGuidance.ts#L21)
2574. 在食堂地图中拖到自己身上喝掉
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:22](../src/scenes/rpg/RpgItemUseGuidance.ts#L22)
2575. 到食堂第五个打饭窗口上方的宣传灯箱空杯位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:23](../src/scenes/rpg/RpgItemUseGuidance.ts#L23)
2576. 靠近取餐窗口后按空格使用；纸包鸡需在深色第三窗口交票
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:24](../src/scenes/rpg/RpgItemUseGuidance.ts#L24)
2577. 食物彩蛋，没有剧情用途
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:25](../src/scenes/rpg/RpgItemUseGuidance.ts#L25)；[src/scenes/rpg/RpgItemUseGuidance.ts:26](../src/scenes/rpg/RpgItemUseGuidance.ts#L26)；[src/scenes/rpg/RpgItemUseGuidance.ts:27](../src/scenes/rpg/RpgItemUseGuidance.ts#L27)；[src/scenes/rpg/RpgItemUseGuidance.ts:28](../src/scenes/rpg/RpgItemUseGuidance.ts#L28)
2578. 与另一半临时票合成，无需拖到场景
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:29](../src/scenes/rpg/RpgItemUseGuidance.ts#L29)；[src/scenes/rpg/RpgItemUseGuidance.ts:30](../src/scenes/rpg/RpgItemUseGuidance.ts#L30)
2579. 到剧院灯光控制台打开节目单排序
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:31](../src/scenes/rpg/RpgItemUseGuidance.ts#L31)；[src/scenes/rpg/RpgItemUseGuidance.ts:32](../src/scenes/rpg/RpgItemUseGuidance.ts#L32)；[src/scenes/rpg/RpgItemUseGuidance.ts:33](../src/scenes/rpg/RpgItemUseGuidance.ts#L33)
2580. 前往 CC98 或馆藏检索提交湿节目单
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:34](../src/scenes/rpg/RpgItemUseGuidance.ts#L34)
2581. 前往校园地图搜索栏提交地点关键词
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:35](../src/scenes/rpg/RpgItemUseGuidance.ts#L35)；[src/scenes/rpg/RpgItemUseGuidance.ts:36](../src/scenes/rpg/RpgItemUseGuidance.ts#L36)；[src/scenes/rpg/RpgItemUseGuidance.ts:37](../src/scenes/rpg/RpgItemUseGuidance.ts#L37)
2582. 坐标会在启真湖布置假纸条时自动核验
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:38](../src/scenes/rpg/RpgItemUseGuidance.ts#L38)
2583. 靠近目标，把道具拖到物体本身后松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:41](../src/scenes/rpg/RpgItemUseGuidance.ts#L41)
2584. ready
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:42](../src/scenes/rpg/RpgItemUseGuidance.ts#L42)
2585. 当前可以使用
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:43](../src/scenes/rpg/RpgItemUseGuidance.ts#L43)
2586. passive
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:56](../src/scenes/rpg/RpgItemUseGuidance.ts#L56)
2587. 无需拖动
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:57](../src/scenes/rpg/RpgItemUseGuidance.ts#L57)
2588. elsewhere
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:62](../src/scenes/rpg/RpgItemUseGuidance.ts#L62)
2589. 旧钟时针插槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:94](../src/scenes/rpg/RpgItemUseGuidance.ts#L94)
2590. 旧钟定位盘插槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:99](../src/scenes/rpg/RpgItemUseGuidance.ts#L99)
2591. 清洁车车轮
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:105](../src/scenes/rpg/RpgItemUseGuidance.ts#L105)；[src/scenes/rpg/RpgItemUseGuidance.ts:114](../src/scenes/rpg/RpgItemUseGuidance.ts#L114)
2592. 先靠近保洁车检查卡住的车轮。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:105](../src/scenes/rpg/RpgItemUseGuidance.ts#L105)
2593. 清洁车轮罩
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:108](../src/scenes/rpg/RpgItemUseGuidance.ts#L108)
2594. 先把润滑油拖到清洁车车轮，修好后仍会保留半瓶。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:114](../src/scenes/rpg/RpgItemUseGuidance.ts#L114)
2595. 把剩下的半瓶润滑油拖到旧钟齿轮。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:117](../src/scenes/rpg/RpgItemUseGuidance.ts#L117)
2596. 旧钟齿轮
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:117](../src/scenes/rpg/RpgItemUseGuidance.ts#L117)
2597. 润滑油的剧情用途已经完成。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:119](../src/scenes/rpg/RpgItemUseGuidance.ts#L119)
2598. 旧钟分针端点
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:123](../src/scenes/rpg/RpgItemUseGuidance.ts#L123)
2599. 手柄已经连接并等待方向输入校验。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:129](../src/scenes/rpg/RpgItemUseGuidance.ts#L129)
2600. 先在部门黄页完成角色命名。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:130](../src/scenes/rpg/RpgItemUseGuidance.ts#L130)
2601. 先在浙大体艺开始课外锻炼。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:131](../src/scenes/rpg/RpgItemUseGuidance.ts#L131)
2602. 先在 CC98 完成手柄购买。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:132](../src/scenes/rpg/RpgItemUseGuidance.ts#L132)
2603. 把手柄拖到角色身体范围内，并在人物轮廓内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:133](../src/scenes/rpg/RpgItemUseGuidance.ts#L133)
2604. 文学书架 755 段
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:142](../src/scenes/rpg/RpgItemUseGuidance.ts#L142)；[src/scenes/rpg/RpgItemUseGuidance.ts:143](../src/scenes/rpg/RpgItemUseGuidance.ts#L143)
2605. 先完成馆藏检索并取得索书号 755。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:143](../src/scenes/rpg/RpgItemUseGuidance.ts#L143)
2606. 前台正在人工核验并盖章，等待流程完成。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:146](../src/scenes/rpg/RpgItemUseGuidance.ts#L146)
2607. 靠近前台，把物品识别报告拖到工作人员与盖章台之间。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:151](../src/scenes/rpg/RpgItemUseGuidance.ts#L151)
2608. 前台工作人员
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:151](../src/scenes/rpg/RpgItemUseGuidance.ts#L151)；[src/scenes/rpg/RpgItemUseGuidance.ts:152](../src/scenes/rpg/RpgItemUseGuidance.ts#L152)
2609. 先在照片页面生成物品识别报告。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:152](../src/scenes/rpg/RpgItemUseGuidance.ts#L152)
2610. 022 座位凭据已经取出，右移箭头已完成最后用途。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:157](../src/scenes/rpg/RpgItemUseGuidance.ts#L157)
2611. 022 占座书包
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:163](../src/scenes/rpg/RpgItemUseGuidance.ts#L163)；[src/scenes/rpg/RpgItemUseGuidance.ts:164](../src/scenes/rpg/RpgItemUseGuidance.ts#L164)
2612. 先完成公开公示和三项恢复材料，取得清退 PASS。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:164](../src/scenes/rpg/RpgItemUseGuidance.ts#L164)
2613. 1、2、3号取餐窗口验票槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:170](../src/scenes/rpg/RpgItemUseGuidance.ts#L170)
2614. 取餐号只在取餐阶段使用。先完成当前食堂任务。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:170](../src/scenes/rpg/RpgItemUseGuidance.ts#L170)
2615. 不需要拖拽或站位。浅色操作可在对应窗口交票；深色观察可补充查看窗口残影。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:172](../src/scenes/rpg/RpgItemUseGuidance.ts#L172)
2616. 取餐窗口
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:172](../src/scenes/rpg/RpgItemUseGuidance.ts#L172)
2617. 靠近混合台打开调配窗口，再点击对应饮料倒入大玻璃杯。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:185](../src/scenes/rpg/RpgItemUseGuidance.ts#L185)
2618. 左下角混合台
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:185](../src/scenes/rpg/RpgItemUseGuidance.ts#L185)
2619. 第五个打饭窗口下方的宣传板空杯位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:192](../src/scenes/rpg/RpgItemUseGuidance.ts#L192)
2620. 先靠近宣传板，再把今日新品气泡水拖进发光的空杯位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:192](../src/scenes/rpg/RpgItemUseGuidance.ts#L192)
2621. 把难喝饮料拖到人物身上可以喝掉，但不会推进剧情。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:195](../src/scenes/rpg/RpgItemUseGuidance.ts#L195)
2622. 玩家自己
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:195](../src/scenes/rpg/RpgItemUseGuidance.ts#L195)
2623. 车锁已经擦净，2 元现金可以用于付款。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:201](../src/scenes/rpg/RpgItemUseGuidance.ts#L201)
2624. 切回浅色模式后再清洁车锁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:202](../src/scenes/rpg/RpgItemUseGuidance.ts#L202)
2625. 先用纸巾清洁车锁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:206](../src/scenes/rpg/RpgItemUseGuidance.ts#L206)
2626. 切回浅色模式后付款。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:207](../src/scenes/rpg/RpgItemUseGuidance.ts#L207)
2627. 现金余额不足 2 元。回食堂完成收餐盘，领取 2 元和油渍纸巾。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:208](../src/scenes/rpg/RpgItemUseGuidance.ts#L208)
2628. 把 2 元现金拖到共享单车范围内，并在车身上松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:209](../src/scenes/rpg/RpgItemUseGuidance.ts#L209)
2629. 海报玻璃已经擦净。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:216](../src/scenes/rpg/RpgItemUseGuidance.ts#L216)
2630. 擦拭海报只在剧院入口取票阶段开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:217](../src/scenes/rpg/RpgItemUseGuidance.ts#L217)
2631. 切回浅色模式后擦拭海报玻璃。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:218](../src/scenes/rpg/RpgItemUseGuidance.ts#L218)
2632. 从海报右侧靠近，把油渍纸巾拖到玻璃污渍上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:219](../src/scenes/rpg/RpgItemUseGuidance.ts#L219)
2633. 入口海报玻璃
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:219](../src/scenes/rpg/RpgItemUseGuidance.ts#L219)
2634. 深色模式只读取异常；切回浅色操作后再把票拖入读票器。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:224](../src/scenes/rpg/RpgItemUseGuidance.ts#L224)
2635. 靠近读票器，把票拖到右侧验票槽内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:228](../src/scenes/rpg/RpgItemUseGuidance.ts#L228)
2636. 票据扫描已经完成，临时观演票已从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:232](../src/scenes/rpg/RpgItemUseGuidance.ts#L232)
2637. 深色模式可查看道具箱残影；切回浅色模式后扫描票据。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:234](../src/scenes/rpg/RpgItemUseGuidance.ts#L234)
2638. 靠近道具箱旁的扫描器，把票拖到扫描口内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:238](../src/scenes/rpg/RpgItemUseGuidance.ts#L238)
2639. 入场核验已完成。票会在后台道具箱阶段再次使用，先完成当前节目单任务。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:242](../src/scenes/rpg/RpgItemUseGuidance.ts#L242)
2640. 当前流程不需要再次拖动临时观演票。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:244](../src/scenes/rpg/RpgItemUseGuidance.ts#L244)
2641. 后台纸屑已经显影，荧光粉刷已从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:247](../src/scenes/rpg/RpgItemUseGuidance.ts#L247)
2642. 先在后台完成票据扫描并打开道具箱，取得荧光粉刷。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:249](../src/scenes/rpg/RpgItemUseGuidance.ts#L249)
2643. 切回浅色操作后，把荧光粉刷拖入通风口。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:252](../src/scenes/rpg/RpgItemUseGuidance.ts#L252)
2644. 靠近通风口，把荧光粉刷拖到栅格上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:254](../src/scenes/rpg/RpgItemUseGuidance.ts#L254)
2645. 先完成后台纸屑显影，灯光控制台随后开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:258](../src/scenes/rpg/RpgItemUseGuidance.ts#L258)
2646. 深色模式只观察追光残影；切回浅色操作后启动灯光控制台。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:261](../src/scenes/rpg/RpgItemUseGuidance.ts#L261)
2647. 从下方靠近控制台，把追光灯遥控器拖到控制面板上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:263](../src/scenes/rpg/RpgItemUseGuidance.ts#L263)
2648. 靠近灯光控制台打开节目单排序，无需把节目单拖到控制台。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:266](../src/scenes/rpg/RpgItemUseGuidance.ts#L266)
2649. 深色观察只记录坐标。切回浅色操作后使用道具。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:274](../src/scenes/rpg/RpgItemUseGuidance.ts#L274)
2650. 假纸条已经固定到鱼钩上并从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:277](../src/scenes/rpg/RpgItemUseGuidance.ts#L277)
2651. 先在大湖浮排边找到钓鱼竿。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:279](../src/scenes/rpg/RpgItemUseGuidance.ts#L279)
2652. 纸条倒影装饵框
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:279](../src/scenes/rpg/RpgItemUseGuidance.ts#L279)；[src/scenes/rpg/RpgItemUseGuidance.ts:282](../src/scenes/rpg/RpgItemUseGuidance.ts#L282)；[src/scenes/rpg/RpgItemUseGuidance.ts:284](../src/scenes/rpg/RpgItemUseGuidance.ts#L284)
2653. 先划回大湖，再寻找纸条倒影装饵框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:282](../src/scenes/rpg/RpgItemUseGuidance.ts#L282)
2654. 把船划到纸条倒影附近，再把假纸条拖到对应水纹。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:285](../src/scenes/rpg/RpgItemUseGuidance.ts#L285)
2655. 纸条倒影水纹
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:285](../src/scenes/rpg/RpgItemUseGuidance.ts#L285)
2656. 船头磁吸组合位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:291](../src/scenes/rpg/RpgItemUseGuidance.ts#L291)
2657. 先划到黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:291](../src/scenes/rpg/RpgItemUseGuidance.ts#L291)
2658. 船头工具区
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:294](../src/scenes/rpg/RpgItemUseGuidance.ts#L294)
2659. 让船头对准工具区，把钓鱼竿拖到天鹅磁扣旁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:294](../src/scenes/rpg/RpgItemUseGuidance.ts#L294)
2660. 当前抛竿点位于大湖，先划回大湖。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:297](../src/scenes/rpg/RpgItemUseGuidance.ts#L297)
2661. 可用抛竿点
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:297](../src/scenes/rpg/RpgItemUseGuidance.ts#L297)；[src/scenes/rpg/RpgItemUseGuidance.ts:302](../src/scenes/rpg/RpgItemUseGuidance.ts#L302)；[src/scenes/rpg/RpgItemUseGuidance.ts:303](../src/scenes/rpg/RpgItemUseGuidance.ts#L303)
2662. 先把假纸条拖到钓鱼竿装饵框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:300](../src/scenes/rpg/RpgItemUseGuidance.ts#L300)
2663. 把船划到目标水纹附近后抛竿。深色观察可补充记录位置，直接钓纸条会显示失败原因。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:303](../src/scenes/rpg/RpgItemUseGuidance.ts#L303)
2664. 码头储物柜已经打开。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:308](../src/scenes/rpg/RpgItemUseGuidance.ts#L308)
2665. 返回小码头，储物柜锁孔只在码头区域开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:310](../src/scenes/rpg/RpgItemUseGuidance.ts#L310)
2666. 码头储物柜
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:310](../src/scenes/rpg/RpgItemUseGuidance.ts#L310)；[src/scenes/rpg/RpgItemUseGuidance.ts:311](../src/scenes/rpg/RpgItemUseGuidance.ts#L311)；[src/scenes/rpg/RpgItemUseGuidance.ts:312](../src/scenes/rpg/RpgItemUseGuidance.ts#L312)
2667. 返回小码头，靠近柜门，把钥匙拖到锁孔。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:312](../src/scenes/rpg/RpgItemUseGuidance.ts#L312)
2668. 两件道具已组合为临时抄网。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:316](../src/scenes/rpg/RpgItemUseGuidance.ts#L316)
2669. 先取得另一个组合部件。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:319](../src/scenes/rpg/RpgItemUseGuidance.ts#L319)
2670. 回到大湖的浮标组合位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:322](../src/scenes/rpg/RpgItemUseGuidance.ts#L322)
2671. 把尼龙绳或破损网框拖入装配框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:325](../src/scenes/rpg/RpgItemUseGuidance.ts#L325)
2672. 密封饲料盒已经取回。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:330](../src/scenes/rpg/RpgItemUseGuidance.ts#L330)
2673. 浮排系绳下方
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:332](../src/scenes/rpg/RpgItemUseGuidance.ts#L332)；[src/scenes/rpg/RpgItemUseGuidance.ts:333](../src/scenes/rpg/RpgItemUseGuidance.ts#L333)；[src/scenes/rpg/RpgItemUseGuidance.ts:334](../src/scenes/rpg/RpgItemUseGuidance.ts#L334)
2674. 进入浮排直河道，再靠近浮排系绳。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:332](../src/scenes/rpg/RpgItemUseGuidance.ts#L332)
2675. 进入直河道，让船头对准浮排下方，把抄网拖到密封饲料盒上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:334](../src/scenes/rpg/RpgItemUseGuidance.ts#L334)
2676. 饲料盒已经打开。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:339](../src/scenes/rpg/RpgItemUseGuidance.ts#L339)
2677. 返回浮排直河道，开盒位在浮排上缘。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:341](../src/scenes/rpg/RpgItemUseGuidance.ts#L341)
2678. 浮排开盒位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:341](../src/scenes/rpg/RpgItemUseGuidance.ts#L341)；[src/scenes/rpg/RpgItemUseGuidance.ts:342](../src/scenes/rpg/RpgItemUseGuidance.ts#L342)
2679. 浮排硬边
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:343](../src/scenes/rpg/RpgItemUseGuidance.ts#L343)
2680. 让船头对准浮排硬边，把密封饲料盒拖到边缘上开启。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:343](../src/scenes/rpg/RpgItemUseGuidance.ts#L343)
2681. 回到大湖的鱼群水纹位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:348](../src/scenes/rpg/RpgItemUseGuidance.ts#L348)
2682. 鱼群水纹
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:348](../src/scenes/rpg/RpgItemUseGuidance.ts#L348)；[src/scenes/rpg/RpgItemUseGuidance.ts:350](../src/scenes/rpg/RpgItemUseGuidance.ts#L350)；[src/scenes/rpg/RpgItemUseGuidance.ts:351](../src/scenes/rpg/RpgItemUseGuidance.ts#L351)
2683. 把饲料颗粒拖入鱼群水纹；深色观察可补充记录位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:351](../src/scenes/rpg/RpgItemUseGuidance.ts#L351)
2684. 黑天鹅
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:357](../src/scenes/rpg/RpgItemUseGuidance.ts#L357)
2685. 让船头对准黑天鹅，把小鲤鱼拖到天鹅面前。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:357](../src/scenes/rpg/RpgItemUseGuidance.ts#L357)
2686. 划到黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:358](../src/scenes/rpg/RpgItemUseGuidance.ts#L358)
2687. 划到黑天鹅围栏区的船头装配位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:363](../src/scenes/rpg/RpgItemUseGuidance.ts#L363)
2688. 把磁性扣拖到钓鱼竿所在的装配框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:367](../src/scenes/rpg/RpgItemUseGuidance.ts#L367)
2689. 钓鱼竿当前不在道具栏。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:368](../src/scenes/rpg/RpgItemUseGuidance.ts#L368)
2690. 纸条已经被固定，进入返航追逐。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:372](../src/scenes/rpg/RpgItemUseGuidance.ts#L372)
2691. 纸条本体水纹位于黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:374](../src/scenes/rpg/RpgItemUseGuidance.ts#L374)
2692. 把磁性钓鱼竿拖入纸条本体水纹；深色观察可补充记录位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:377](../src/scenes/rpg/RpgItemUseGuidance.ts#L377)
2693. 当前{{current.label}}。点击切换到{{next.label}}
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:25](../src/scenes/rpg/RpgRealityModeToggle.tsx#L25)
2694. {{current.shortHint}} 点击切换到{{next.label}}。
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:26](../src/scenes/rpg/RpgRealityModeToggle.tsx#L26)
2695. 当前模式
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:34](../src/scenes/rpg/RpgRealityModeToggle.tsx#L34)
2696. 切换：
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:36](../src/scenes/rpg/RpgRealityModeToggle.tsx#L36)
2697. 紫云碧峰
   来源：[src/scenes/rpg/ZijingangCampusLayout.ts:54](../src/scenes/rpg/ZijingangCampusLayout.ts#L54)
2698. 东区大食堂
   来源：[src/scenes/rpg/ZijingangCampusLayout.ts:73](../src/scenes/rpg/ZijingangCampusLayout.ts#L73)

