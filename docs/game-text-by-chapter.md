# 《7:55》游戏文本总表

> 本文件由 `npm run text:export` 从当前 `src/` 自动生成。请修改源文件后重新导出，不要只修改本文件。

- 文本条目：6816
- 来源文件：144
- 收录范围：剧情对白、字幕、任务说明、交互提示、按钮、页面标题、帖子、物品说明、失败反馈与玩家可见状态文案。
- 排除范围：开发者面板、测试断言、内部 ID、CSS 类名、资源路径、存档字段和运行时调试信息。
- 去重规则：同一章节内完全相同的文本合并为一条，全部源码位置仍保留。
- 模板规则：动态表达式显示为 `{{表达式}}`。

## 章节索引

| 章节 | 文本条目 |
| --- | ---: |
| [第一章](#第一章) | 463 |
| [第二章](#第二章) | 409 |
| [第三章](#第三章) | 1180 |
| [3.5章过渡](#35章过渡) | 296 |
| [第四章](#第四章) | 1654 |
| [结局](#结局) | 103 |
| [跨章节与共用系统](#跨章节与共用系统) | 2711 |

## 第一章

1. 已找到的签到数字：{{digitSlots .map((digit, index) =&gt; \`第${index + 1}位${digit ?? "未找到"}\`) .join("，")}}
   来源：[src/components/QuestClueStrip.tsx:114](../src/components/QuestClueStrip.tsx#L114)
2. 返回任务现场
   来源：[src/components/QuestClueStrip.tsx:121](../src/components/QuestClueStrip.tsx#L121)
3. 前往相关界面
   来源：[src/components/QuestClueStrip.tsx:121](../src/components/QuestClueStrip.tsx#L121)
4. 查看信息
   来源：[src/core/QuestModel.ts:57](../src/core/QuestModel.ts#L57)
5. 找签到码（{{digitCount}}/4）
   来源：[src/core/QuestModel.ts:64](../src/core/QuestModel.ts#L64)
6. 先检查浙大体艺、设置齿轮和盆栽相关界面。
   来源：[src/core/QuestModel.ts:66](../src/core/QuestModel.ts#L66)
7. 道具可以拖拽合并。
   来源：[src/core/QuestModel.ts:67](../src/core/QuestModel.ts#L67)
8. 浙大体艺打不开时，试试换一种网络。
   来源：[src/core/QuestModel.ts:68](../src/core/QuestModel.ts#L68)
9. 微信界面也用“自动旋转”
   来源：[src/core/QuestModel.ts:69](../src/core/QuestModel.ts#L69)
10. 光照在控制中心拖动调节
   来源：[src/core/QuestModel.ts:70](../src/core/QuestModel.ts#L70)
11. 还有一个在签到页面
   来源：[src/core/QuestModel.ts:71](../src/core/QuestModel.ts#L71)
12. 去签到
   来源：[src/core/QuestModel.ts:78](../src/core/QuestModel.ts#L78)
13. 五分钟
   来源：[src/core/QuestModel.ts:85](../src/core/QuestModel.ts#L85)
14. 签到校园卡
   来源：[src/core/QuestModel.ts:88](../src/core/QuestModel.ts#L88)
15. 签到页
   来源：[src/core/QuestModel.ts:88](../src/core/QuestModel.ts#L88)
16. 数字 {{state.digits.d1}}
   来源：[src/core/QuestModel.ts:88](../src/core/QuestModel.ts#L88)
17. 数字 {{state.digits.d2}}
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)
18. 应用异常
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)
19. 浙大体艺
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)；[src/scenes/phone/P06_Tiyi/index.tsx:110](../src/scenes/phone/P06_Tiyi/index.tsx#L110)
20. 设置齿轮
   来源：[src/core/QuestModel.ts:90](../src/core/QuestModel.ts#L90)
21. 设置页
   来源：[src/core/QuestModel.ts:90](../src/core/QuestModel.ts#L90)
22. 数字 {{state.digits.d3}}
   来源：[src/core/QuestModel.ts:90](../src/core/QuestModel.ts#L90)
23. 盆栽机关
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
24. 数字 {{state.digits.d4}}
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
25. 主页盆栽
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
26. 林星宇
   来源：[src/data/act-one-bootstrap.content.json:3](../src/data/act-one-bootstrap.content.json#L3)；[src/scenes/phone/P06_Tiyi/index.tsx:144](../src/scenes/phone/P06_Tiyi/index.tsx#L144)
27. 游戏卡带
   来源：[src/data/act-one-bootstrap.content.json:21](../src/data/act-one-bootstrap.content.json#L21)
28. 第一章的实体入口。标签上只印着 7:55。
   来源：[src/data/act-one-bootstrap.content.json:22](../src/data/act-one-bootstrap.content.json#L22)
29. 南大门
   来源：[src/data/act-one-bootstrap.content.json:25](../src/data/act-one-bootstrap.content.json#L25)
30. 启真湖桥
   来源：[src/data/act-one-bootstrap.content.json:26](../src/data/act-one-bootstrap.content.json#L26)
31. 基础馆
   来源：[src/data/act-one-bootstrap.content.json:27](../src/data/act-one-bootstrap.content.json#L27)；[src/modules/ActOneBootstrapController.ts:537](../src/modules/ActOneBootstrapController.ts#L537)
32. 校园地图终端
   来源：[src/data/act-one-bootstrap.content.json:28](../src/data/act-one-bootstrap.content.json#L28)
33. 校园服务台
   来源：[src/data/act-one-bootstrap.content.json:31](../src/data/act-one-bootstrap.content.json#L31)
34. 游戏联络台
   来源：[src/data/act-one-bootstrap.content.json:32](../src/data/act-one-bootstrap.content.json#L32)
35. 体艺值班台
   来源：[src/data/act-one-bootstrap.content.json:33](../src/data/act-one-bootstrap.content.json#L33)
36. 完成签到
   来源：[src/data/act-one-bootstrap.content.json:36](../src/data/act-one-bootstrap.content.json#L36)
37. 查看朋友的新消息
   来源：[src/data/act-one-bootstrap.content.json:37](../src/data/act-one-bootstrap.content.json#L37)
38. 找到系统
   来源：[src/data/act-one-bootstrap.content.json:38](../src/data/act-one-bootstrap.content.json#L38)
39. 找到道具栏
   来源：[src/data/act-one-bootstrap.content.json:39](../src/data/act-one-bootstrap.content.json#L39)
40. 带着道具栏回去找系统
   来源：[src/data/act-one-bootstrap.content.json:40](../src/data/act-one-bootstrap.content.json#L40)
41. 找到移动的办法
   来源：[src/data/act-one-bootstrap.content.json:41](../src/data/act-one-bootstrap.content.json#L41)；[src/data/act-one-bootstrap.content.json:42](../src/data/act-one-bootstrap.content.json#L42)；[src/data/act-one-bootstrap.content.json:43](../src/data/act-one-bootstrap.content.json#L43)；[src/data/act-one-bootstrap.content.json:44](../src/data/act-one-bootstrap.content.json#L44)；[src/data/act-one-bootstrap.content.json:46](../src/data/act-one-bootstrap.content.json#L46)；[src/data/act-one-bootstrap.content.json:47](../src/data/act-one-bootstrap.content.json#L47)
42. 可以出门了
   来源：[src/data/act-one-bootstrap.content.json:45](../src/data/act-one-bootstrap.content.json#L45)；[src/data/act-one-bootstrap.content.json:48](../src/data/act-one-bootstrap.content.json#L48)
43. 前往图书馆寻找系统的朋友
   来源：[src/data/act-one-bootstrap.content.json:49](../src/data/act-one-bootstrap.content.json#L49)
44. 他听不到你说话。
   来源：[src/data/act-one-bootstrap.content.json:52](../src/data/act-one-bootstrap.content.json#L52)
45. 这位同学目前连自己的名字都不知道。
   来源：[src/data/act-one-bootstrap.content.json:53](../src/data/act-one-bootstrap.content.json#L53)
46. 他走起来了，但他不知道该往哪里走。
   来源：[src/data/act-one-bootstrap.content.json:54](../src/data/act-one-bootstrap.content.json#L54)
47. 手柄已经到货，方向输入等待校验。
   来源：[src/data/act-one-bootstrap.content.json:55](../src/data/act-one-bootstrap.content.json#L55)
48. 这张卡带上只写了 7:55，它显然不是课程表。
   来源：[src/data/act-one-bootstrap.content.json:56](../src/data/act-one-bootstrap.content.json#L56)
49. 可以出门了。
   来源：[src/data/act-one-bootstrap.content.json:57](../src/data/act-one-bootstrap.content.json#L57)
50. Excellent. You opened the game. Now kindly apply for permission to operate yourself.
   来源：[src/data/act-one-bootstrap.content.json:61](../src/data/act-one-bootstrap.content.json#L61)
51. 很好，你打开了游戏。现在请先去申请操作自己。
   来源：[src/data/act-one-bootstrap.content.json:62](../src/data/act-one-bootstrap.content.json#L62)
52. Identity verified. The character finally has a name. The network remains unconvinced.
   来源：[src/data/act-one-bootstrap.content.json:67](../src/data/act-one-bootstrap.content.json#L67)
53. 登录成功。这个角色终于有名字了，仍然没联网。
   来源：[src/data/act-one-bootstrap.content.json:68](../src/data/act-one-bootstrap.content.json#L68)
54. Call connected. Using a student ID as a phone number is distressingly on brand.
   来源：[src/data/act-one-bootstrap.content.json:73](../src/data/act-one-bootstrap.content.json#L73)
55. 电话接通。用学号当电话号码，很有校园特色。
   来源：[src/data/act-one-bootstrap.content.json:74](../src/data/act-one-bootstrap.content.json#L74)
56. The controls have arrived. Sports has not yet approved the act of walking.
   来源：[src/data/act-one-bootstrap.content.json:79](../src/data/act-one-bootstrap.content.json#L79)
57. 方向键到货。体艺还没批准你走路。
   来源：[src/data/act-one-bootstrap.content.json:80](../src/data/act-one-bootstrap.content.json#L80)
58. Exercise started. Congratulations. You are now officially permitted to walk.
   来源：[src/data/act-one-bootstrap.content.json:85](../src/data/act-one-bootstrap.content.json#L85)
59. 锻炼开始。恭喜，你现在被允许步行。
   来源：[src/data/act-one-bootstrap.content.json:86](../src/data/act-one-bootstrap.content.json#L86)
60. Cartridge acquired. Keep walking. Apparently all four areas require your personal attendance.
   来源：[src/data/act-one-bootstrap.content.json:91](../src/data/act-one-bootstrap.content.json#L91)
61. 卡带拿到了。继续把地图走完，四个区域一个都不能漏。
   来源：[src/data/act-one-bootstrap.content.json:92](../src/data/act-one-bootstrap.content.json#L92)
62. Map complete. The menu is open, and the system has formally recorded your ability to walk. A historic day.
   来源：[src/data/act-one-bootstrap.content.json:97](../src/data/act-one-bootstrap.content.json#L97)
63. 全图已刷。游戏菜单已开放，系统已记录你会走路。
   来源：[src/data/act-one-bootstrap.content.json:98](../src/data/act-one-bootstrap.content.json#L98)
64. Pfft, oh, sorry. I did not mean anything by it. It is just... this does not look like a success, does it? I suppose you will have to get up, drag yourself to class, and deal with it. Good luck, kid! I am leaving!
   来源：[src/data/act-one-bootstrap.content.json:103](../src/data/act-one-bootstrap.content.json#L103)
65. 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。我想你只好乖乖起来滚去上课了。祝你好运，孩子！我要走了！
   来源：[src/data/act-one-bootstrap.content.json:104](../src/data/act-one-bootstrap.content.json#L104)
66. 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。
   来源：[src/data/act-one-bootstrap.content.json:106](../src/data/act-one-bootstrap.content.json#L106)
67. 我想你只好乖乖起来滚去上课了。
   来源：[src/data/act-one-bootstrap.content.json:107](../src/data/act-one-bootstrap.content.json#L107)
68. 祝你好运，孩子！我要走了！
   来源：[src/data/act-one-bootstrap.content.json:108](../src/data/act-one-bootstrap.content.json#L108)
69. Pfft, oh, sorry. I did not mean anything by it. It is just... this does not look like a success, does it?
   来源：[src/data/act-one-bootstrap.content.json:114](../src/data/act-one-bootstrap.content.json#L114)
70. I suppose you will have to get up, drag yourself to class, and deal with it.
   来源：[src/data/act-one-bootstrap.content.json:118](../src/data/act-one-bootstrap.content.json#L118)
71. Good luck, kid! I am leaving!
   来源：[src/data/act-one-bootstrap.content.json:122](../src/data/act-one-bootstrap.content.json#L122)
72. Hey! What exactly do you think you are doing? Let go of me!
   来源：[src/data/act-one-bootstrap.content.json:128](../src/data/act-one-bootstrap.content.json#L128)
73. 嘿！你到底在干什么？放开我！
   来源：[src/data/act-one-bootstrap.content.json:129](../src/data/act-one-bootstrap.content.json#L129)
74. Oh, fine, fine! But first, take your hand off me!
   来源：[src/data/act-one-bootstrap.content.json:134](../src/data/act-one-bootstrap.content.json#L134)
75. 哦，好吧，好吧！但你先把手放开！
   来源：[src/data/act-one-bootstrap.content.json:135](../src/data/act-one-bootstrap.content.json#L135)
76. Oh, damn it. You win, kid.
   来源：[src/data/act-one-bootstrap.content.json:140](../src/data/act-one-bootstrap.content.json#L140)
77. 哦，该死。你赢了，孩子。
   来源：[src/data/act-one-bootstrap.content.json:141](../src/data/act-one-bootstrap.content.json#L141)
78. Fine. Bring out your inventory.
   来源：[src/data/act-one-bootstrap.content.json:146](../src/data/act-one-bootstrap.content.json#L146)
79. 行。把你的道具栏拿出来。
   来源：[src/data/act-one-bootstrap.content.json:147](../src/data/act-one-bootstrap.content.json#L147)
80. Wait. Where is your inventory? You cannot expect me to work empty-handed!
   来源：[src/data/act-one-bootstrap.content.json:152](../src/data/act-one-bootstrap.content.json#L152)
81. 等等，你的道具栏呢？你总不能指望我空手干活！
   来源：[src/data/act-one-bootstrap.content.json:153](../src/data/act-one-bootstrap.content.json#L153)
82. Just. Find it.
   来源：[src/data/act-one-bootstrap.content.json:158](../src/data/act-one-bootstrap.content.json#L158)
83. 去。找。到。它。
   来源：[src/data/act-one-bootstrap.content.json:159](../src/data/act-one-bootstrap.content.json#L159)
84. You found it. Great. Then let us get moving.
   来源：[src/data/act-one-bootstrap.content.json:164](../src/data/act-one-bootstrap.content.json#L164)
85. 你找到了，那就太好了，我们出发吧！
   来源：[src/data/act-one-bootstrap.content.json:165](../src/data/act-one-bootstrap.content.json#L165)
86. I should be honest. I do not have permission to edit attendance records.
   来源：[src/data/act-one-bootstrap.content.json:170](../src/data/act-one-bootstrap.content.json#L170)
87. 我得说实话了，我没有修改记录权限
   来源：[src/data/act-one-bootstrap.content.json:171](../src/data/act-one-bootstrap.content.json#L171)
88. But I have a friend who might.
   来源：[src/data/act-one-bootstrap.content.json:176](../src/data/act-one-bootstrap.content.json#L176)
89. 但我有一个朋友她或许能做到
   来源：[src/data/act-one-bootstrap.content.json:177](../src/data/act-one-bootstrap.content.json#L177)
90. If we still want your participation grade, we need to find her in the library.
   来源：[src/data/act-one-bootstrap.content.json:182](../src/data/act-one-bootstrap.content.json#L182)
91. 如果我们还想要平时分，就得去图书馆找她
   来源：[src/data/act-one-bootstrap.content.json:183](../src/data/act-one-bootstrap.content.json#L183)
92. Understood? Then move.
   来源：[src/data/act-one-bootstrap.content.json:188](../src/data/act-one-bootstrap.content.json#L188)
93. 明白了？那就快行动吧！
   来源：[src/data/act-one-bootstrap.content.json:189](../src/data/act-one-bootstrap.content.json#L189)
94. He cannot hear you. At the moment, he does not even have a name to answer to.
   来源：[src/data/act-one-bootstrap.content.json:194](../src/data/act-one-bootstrap.content.json#L194)
95. 他听不到你说话。现在的他连一个能回应的名字都没有。
   来源：[src/data/act-one-bootstrap.content.json:195](../src/data/act-one-bootstrap.content.json#L195)
96. Name and student ID match. Good. He now knows who he is.
   来源：[src/data/act-one-bootstrap.content.json:200](../src/data/act-one-bootstrap.content.json#L200)
97. 姓名和学号一致。很好，他现在知道自己是谁了。
   来源：[src/data/act-one-bootstrap.content.json:201](../src/data/act-one-bootstrap.content.json#L201)
98. Exercise record synced. Check the new Direction Calibration notice on the phone home screen.
   来源：[src/data/act-one-bootstrap.content.json:206](../src/data/act-one-bootstrap.content.json#L206)
99. 锻炼记录已同步。
   来源：[src/data/act-one-bootstrap.content.json:207](../src/data/act-one-bootstrap.content.json#L207)
100. Triangle collected. Open Weather next and catch one drop of rain.
   来源：[src/data/act-one-bootstrap.content.json:212](../src/data/act-one-bootstrap.content.json#L212)
101. 获得道具：三角形。
   来源：[src/data/act-one-bootstrap.content.json:213](../src/data/act-one-bootstrap.content.json#L213)
102. Weather drop collected. Use it on the stuck vertical line beside the mentor avatar.
   来源：[src/data/act-one-bootstrap.content.json:218](../src/data/act-one-bootstrap.content.json#L218)
103. 获得道具：天气水滴。
   来源：[src/data/act-one-bootstrap.content.json:219](../src/data/act-one-bootstrap.content.json#L219)
104. That vertical line is stuck. Apparently, even your advisor's avatar has formatting requirements.
   来源：[src/data/act-one-bootstrap.content.json:224](../src/data/act-one-bootstrap.content.json#L224)
105. 那条竖线粘住了。看来导师头像也有自己的排版要求。
   来源：[src/data/act-one-bootstrap.content.json:225](../src/data/act-one-bootstrap.content.json#L225)
106. A triangle plus a vertical line. You now have an arrow that can move things to the right.
   来源：[src/data/act-one-bootstrap.content.json:230](../src/data/act-one-bootstrap.content.json#L230)
107. 一个三角形加一条竖线。现在你有了一支能把东西向右移的箭头。
   来源：[src/data/act-one-bootstrap.content.json:231](../src/data/act-one-bootstrap.content.json#L231)
108. The decimal point moved two places right. Six cents has temporarily acquired the dignity of six yuan.
   来源：[src/data/act-one-bootstrap.content.json:236](../src/data/act-one-bootstrap.content.json#L236)
109. 小数点向右移动了两位。六分钱暂时获得了六元钱的尊严。
   来源：[src/data/act-one-bootstrap.content.json:237](../src/data/act-one-bootstrap.content.json#L237)
110. You only have zero point zero six yuan. The seller rejected your hundred-installment plan.
   来源：[src/data/act-one-bootstrap.content.json:242](../src/data/act-one-bootstrap.content.json#L242)
111. 你只有零点零六元。卖家拒绝了你分一百期付款的方案。
   来源：[src/data/act-one-bootstrap.content.json:243](../src/data/act-one-bootstrap.content.json#L243)
112. You can leave now.
   来源：[src/data/act-one-bootstrap.content.json:248](../src/data/act-one-bootstrap.content.json#L248)
113. 现在可以出门了。
   来源：[src/data/act-one-bootstrap.content.json:249](../src/data/act-one-bootstrap.content.json#L249)
114. 蓝田六舍 · W12
   来源：[src/data/act-one-bootstrap.content.json:255](../src/data/act-one-bootstrap.content.json#L255)
115. 室友留言：你的校园卡压在右边书桌那摞纸旁边。
   来源：[src/data/act-one-bootstrap.content.json:256](../src/data/act-one-bootstrap.content.json#L256)
116. 校园卡
   来源：[src/data/act-one-bootstrap.content.json:257](../src/data/act-one-bootstrap.content.json#L257)
117. 返回校园地图
   来源：[src/data/act-one-bootstrap.content.json:258](../src/data/act-one-bootstrap.content.json#L258)
118. 手柄毕业生
   来源：[src/data/act-one-bootstrap.content.json:262](../src/data/act-one-bootstrap.content.json#L262)
119. 二手市场
   来源：[src/data/act-one-bootstrap.content.json:265](../src/data/act-one-bootstrap.content.json#L265)
120. 6块出游戏手柄，寝室自提
   来源：[src/data/act-one-bootstrap.content.json:266](../src/data/act-one-bootstrap.content.json#L266)
121. 26-07-11 07:55
   来源：[src/data/act-one-bootstrap.content.json:269](../src/data/act-one-bootstrap.content.json#L269)
122. 方向键、摇杆和一个不太灵的 A 键都在。只收 6 元，不议价，也不接受 0.06 元分期。
   来源：[src/data/act-one-bootstrap.content.json:270](../src/data/act-one-bootstrap.content.json#L270)
123. 支付 6 元购买手柄
   来源：[src/data/act-one-bootstrap.content.json:271](../src/data/act-one-bootstrap.content.json#L271)
124. checkin\_incomplete
   来源：[src/modules/ActOneBootstrapController.ts:75](../src/modules/ActOneBootstrapController.ts#L75)
125. capture\_incomplete
   来源：[src/modules/ActOneBootstrapController.ts:86](../src/modules/ActOneBootstrapController.ts#L86)
126. 他好像没什么动力走
   来源：[src/modules/ActOneBootstrapController.ts:207](../src/modules/ActOneBootstrapController.ts#L207)
127. 他可能不太知道往哪边走
   来源：[src/modules/ActOneBootstrapController.ts:211](../src/modules/ActOneBootstrapController.ts#L211)
128. 在寝室刷3公里的想法不错
   来源：[src/modules/ActOneBootstrapController.ts:212](../src/modules/ActOneBootstrapController.ts#L212)
129. campus\_card\_required
   来源：[src/modules/ActOneBootstrapController.ts:348](../src/modules/ActOneBootstrapController.ts#L348)
130. not\_owned
   来源：[src/modules/ActOneBootstrapController.ts:462](../src/modules/ActOneBootstrapController.ts#L462)
131. inactive
   来源：[src/modules/ActOneBootstrapController.ts:466](../src/modules/ActOneBootstrapController.ts#L466)
132. identity\_required
   来源：[src/modules/ActOneBootstrapController.ts:470](../src/modules/ActOneBootstrapController.ts#L470)
133. exercise\_required
   来源：[src/modules/ActOneBootstrapController.ts:474](../src/modules/ActOneBootstrapController.ts#L474)
134. wrong\_library
   来源：[src/modules/ActOneBootstrapController.ts:538](../src/modules/ActOneBootstrapController.ts#L538)
135. 二层南
   来源：[src/modules/ActOneBootstrapController.ts:541](../src/modules/ActOneBootstrapController.ts#L541)
136. wrong\_room
   来源：[src/modules/ActOneBootstrapController.ts:542](../src/modules/ActOneBootstrapController.ts#L542)
137. wrong\_seat
   来源：[src/modules/ActOneBootstrapController.ts:546](../src/modules/ActOneBootstrapController.ts#L546)
138. 早八闹钟
   来源：[src/scenes/phone/P00_Alarm/index.tsx:83](../src/scenes/phone/P00_Alarm/index.tsx#L83)
139. 学在浙大签到还剩 5 分钟
   来源：[src/scenes/phone/P00_Alarm/index.tsx:85](../src/scenes/phone/P00_Alarm/index.tsx#L85)
140. 开始游戏
   来源：[src/scenes/phone/P00_Alarm/index.tsx:90](../src/scenes/phone/P00_Alarm/index.tsx#L90)
141. 关闭
   来源：[src/scenes/phone/P00_Alarm/index.tsx:94](../src/scenes/phone/P00_Alarm/index.tsx#L94)
142. ZJUWLAN · 17%
   来源：[src/scenes/phone/P01_Desktop/index.tsx:33](../src/scenes/phone/P01_Desktop/index.tsx#L33)
143. （我）
   来源：[src/scenes/phone/P01_Desktop/index.tsx:38](../src/scenes/phone/P01_Desktop/index.tsx#L38)
144. ……再睡5分钟……
   来源：[src/scenes/phone/P01_Desktop/index.tsx:40](../src/scenes/phone/P01_Desktop/index.tsx#L40)
145. 起床蠢货
   来源：[src/scenes/phone/P01_Desktop/index.tsx:46](../src/scenes/phone/P01_Desktop/index.tsx#L46)
146. 进入手机主界面
   来源：[src/scenes/phone/P01_Desktop/index.tsx:50](../src/scenes/phone/P01_Desktop/index.tsx#L50)
147. 旁白
   来源：[src/scenes/phone/P01_Desktop/index.tsx:57](../src/scenes/phone/P01_Desktop/index.tsx#L57)
148. 你没有5分钟了，但你很有勇气
   来源：[src/scenes/phone/P01_Desktop/index.tsx:58](../src/scenes/phone/P01_Desktop/index.tsx#L58)
149. 水帖
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:26](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L26)
150. caption
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:37](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L37)
151. 路过
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:55](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L55)
152. 022占座调查帖回复
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:66](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L66)
153. 23 楼调查记录
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:69](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L69)
154. 关键线索分布在不同用户的回复和引用中。
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:70](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L70)
155. ac01 已读
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:72](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L72)
156. 楼
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:92](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L92)
157. CC98 bd 表情包
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:98](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L98)
158. 读一下（可选）
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:109](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L109)
159. 已记下这条水帖
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:109](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L109)
160. 条 ac01 全部为可选内容；证据进度不会因此变化。
   来源：[src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx:118](../src/scenes/phone/P02_CC98/Ac01FilterPuzzle.tsx#L118)
161. 卖家暂时不认识这段剧情。
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:26](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L26)
162. system
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:26](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L26)；[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:30](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L30)；[src/scenes/phone/P06_Tiyi/index.tsx:79](../src/scenes/phone/P06_Tiyi/index.tsx#L79)；[src/scenes/phone/P06_Tiyi/index.tsx:83](../src/scenes/phone/P06_Tiyi/index.tsx#L83)；[src/scenes/phone/P11_Checkin/index.tsx:93](../src/scenes/phone/P11_Checkin/index.tsx#L93)
163. 手柄已经在道具栏里。
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:30](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L30)
164. 支付成功：游戏手柄已放入道具栏。
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:33](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L33)
165. task
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:33](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L33)；[src/scenes/phone/P06_Tiyi/index.tsx:74](../src/scenes/phone/P06_Tiyi/index.tsx#L74)；[src/scenes/phone/P10_Bonsai/index.tsx:92](../src/scenes/phone/P10_Bonsai/index.tsx#L92)；[src/scenes/phone/P11_Checkin/index.tsx:115](../src/scenes/phone/P11_Checkin/index.tsx#L115)
166. CC98游戏手柄交易
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:43](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L43)
167. 二手游戏手柄 × 1
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:50](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L50)
168. 商品
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:50](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L50)
169. ¥6.00，不议价
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:51](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L51)
170. 售价
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:51](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L51)
171. 你的余额
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:52](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L52)
172. 收货人
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:54](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L54)
173. 身份信息尚未读取
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:55](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L55)
174. 回寝室试用手柄
   来源：[src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx:59](../src/scenes/phone/P02_CC98/ControlExchangePuzzle.tsx#L59)
175. 这个槽位需要对应名称的纸质材料。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:142](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L142)
176. 这份材料还没有形成可核对的道具。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:152](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L152)
177. 当前阶段不能选入这条回复。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:159](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L159)
178. CC98证据与十大排名
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:189](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L189)
179. 楼主证据上传区
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:191](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L191)
180. 楼主编辑：上传证据
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:194](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L194)
181. 证据完整度：
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:195](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L195)
182. 待补齐
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:197](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L197)
183. 等待说明
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:197](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L197)
184. 可生成口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:197](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L197)
185. 上传
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:218](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L218)
186. 未获得
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:218](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L218)
187. 已上传
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:218](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L218)
188. 当前排名
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:227](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L227)
189. 请先上传四项证据
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:229](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L229)
190. 十大第一
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:229](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L229)
191. 完成 BD 四位口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:229](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L229)
192. BD四位热度口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:233](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L233)
193. 口令顺序提示
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:239](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L239)
194. 当前口令 {{selectedPostIds.map((id) =&gt; BD\_DIGIT\_BY\_POST.get(id)).join("") \|\| "空"}}
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:244](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L244)
195. 撤回一位
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:248](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L248)
196. 清空
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:249](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L249)
197. 提交口令
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:250](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L250)
198. 已通过
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:250](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L250)
199. 数字候选回复
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:254](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L254)
200. 口令第 {{selectedIndex + 1}} 位
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:260](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L260)
201. 楼 ·
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:260](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L260)
202. 数字回复
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:260](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L260)
203. 数字 {{post.digit}}
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:262](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L262)
204. 对 {{post.floor}} 楼回复 bd，选入数字 {{post.digit}}
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:266](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L266)
205. 第 {{selectedIndex + 1}} 位
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:269](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L269)
206. bd 选入
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:269](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L269)
207. 公示排名已更新为 01。
   来源：[src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx:277](../src/scenes/phone/P02_CC98/TopTenRisePuzzle.tsx#L277)
208. 先从随身校园卡确认账号，再拆开密码提示。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:26](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L26)
209. 随身物品里没有校园卡，当前无法确认 10 位学号。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:47](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L47)
210. 校园卡已读取：{{actOneContent.studentName}}，学号已填入。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:51](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L51)
211. 提示 {{count}}/3 已展开：{{hint.clue}}
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:58](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L58)
212. 三段密码提示已经全部展开，按顺序拼接即可。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:60](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L60)
213. 认证通过，正在进入 CC98。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:68](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L68)
214. 先读取校园卡上的学号，再提交认证。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:72](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L72)
215. 尝试暂时锁定，还需等待 {{formatWaitSeconds(result.remainingMs)}}。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:77](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L77)
216. 学号与校园卡不一致。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:83](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L83)
217. 密码片段、顺序或大小写不正确。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:85](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L85)
218. 学号和密码均未通过核验。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:86](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L86)
219. {{mismatch}} 已累计 {{result.failureCount}} 次失败，等待 {{formatWaitSeconds(result.lockDurationMs)}} 后可重试。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:88](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L88)
220. {{mismatch}} 还可立即尝试 {{CC98\_LOGIN\_FREE\_ATTEMPTS - result.failureCount}} 次。
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:89](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L89)
221. 浙江大学统一身份认证解谜
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:94](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L94)
222. 浙江大学统一身份认证
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:99](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L99)；[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:206](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L206)
223. UNIFIED IDENTITY AUTHENTICATION
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:100](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L100)
224. 浙大通行证登录
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:105](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L105)
225. 首次进入 CC98
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:108](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L108)
226. 浙大通行证
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:109](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L109)
227. 10 位学号
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:122](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L122)
228. 统一身份认证学号
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:123](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L123)
229. 按提示组合密码
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:133](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L133)
230. 统一身份认证密码
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:134](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L134)
231. 显示
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:142](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L142)
232. 隐藏
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:142](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L142)
233. 失败记录
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:147](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L147)
234. 锁定
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:149](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L149)
235. 立即机会 {{immediateAttemptsLeft}}/3
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:150](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L150)
236. 下次失败等待 {{nextPenaltySeconds}}s
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:150](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L150)
237. 登 录
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:158](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L158)
238. 等待 {{formatWaitSeconds(remainingMs)}}
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:158](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L158)
239. 认证线索
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:165](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L165)；[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:167](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L167)
240. 本地找回
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:167](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L167)
241. 查看随身校园卡
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:174](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L174)
242. 校园卡身份已读取
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:174](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L174)
243. 卡面记录了持卡人的 10 位学号
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:175](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L175)
244. 读取
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:177](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L177)
245. 填入
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:177](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L177)
246. 待解锁片段
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:187](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L187)
247. 展开上一条提示后显示
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:188](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L188)
248. 提示已全部展开
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:202](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L202)
249. 展开提示 {{login.revealedHintCount + 1}}
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:202](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L202)
250. 退出认证
   来源：[src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx:209](../src/scenes/phone/P02_CC98/UnifiedIdentityLogin.tsx#L209)
251. 南直道
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:7](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L7)
252. 西南弯
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:8](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L8)
253. 西弯道
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:9](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L9)
254. 西北弯
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:10](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L10)
255. 北直道西
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:11](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L11)
256. 北直道东
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:12](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L12)
257. 东北弯
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:13](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L13)
258. 东弯道
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:14](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L14)
259. 东南弯
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:15](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L15)
260. 终点线
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:16](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L16)
261. 点击发光定位点，生成第 1 分钟的运动轨迹。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:31](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L31)
262. complete
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:63](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L63)
263. ready
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:63](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L63)
264. running
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:63](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L63)
265. 第 {{index + 1}} 分钟已经记录。当前需要第 {{recordedFixes + 1}} 个定位点。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:87](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L87)
266. 定位漂移：请先补齐第 {{recordedFixes + 1}} 分钟。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:91](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L91)
267. 第 {{nextFixCount}} 分钟定位成功。继续戳中第 {{nextFixCount + 1}} 个定位点。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:98](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L98)
268. 参加者身份失效。请退出后重新确认。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:104](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L104)
269. 10 分钟定位回放完成，3.00 公里锻炼记录已同步。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:108](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L108)
270. 课外锻炼虚拟定位
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:116](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L116)
271. VIRTUAL GPS · 紫云田径场
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:122](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L122)
272. 10 分钟跑完 3 km
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:123](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L123)
273. 课外锻炼已同步
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:123](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L123)
274. 返回体艺首页
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:125](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L125)；[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:211](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L211)
275. 退出本次定位
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:125](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L125)
276. 本次锻炼数据
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:128](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L128)
277. 用时
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:130](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L130)
278. 距离
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:134](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L134)
279. 平均配速
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:138](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L138)
280. ZJU SPORTS
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:159](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L159)
281. 虚拟轨迹回放
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:160](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L160)
282. / 7.50 圈
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:161](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L161)
283. 第 {{index + 1}} 分钟定位点：{{fix.label}}{{visited ? "，已记录" : target ? "，当前目标" : "，尚未解锁"}}
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:184](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L184)
284. 定位状态
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:194](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L194)
285. 等待首个点
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:196](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L196)
286. 轨迹锁定
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:196](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L196)
287. 精度 ±{{Math.max(4, 13 - recordedFixes)}} m
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:196](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L196)
288. {{participantName}} · 记录编号 PE-0755-3000
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:202](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L202)
289. 触屏点按发光目标；键盘使用 Tab 与 Enter / Space。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:202](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L202)
290. 课外锻炼完成
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:206](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L206)
291. TRACK ACCEPTED
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:207](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L207)
292. 3.00 KM · 03'20\\" / KM
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:209](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L209)
293. 十个定位点已完成，课外锻炼记录正式生效。
   来源：[src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx:210](../src/scenes/phone/P06_Tiyi/ActOneVirtualRun.tsx#L210)
294. 「浙大体艺」已停止运行。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:49](../src/scenes/phone/P06_Tiyi/index.tsx#L49)
295. 「浙大体艺」又双叒停止运行了。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:49](../src/scenes/phone/P06_Tiyi/index.tsx#L49)
296. 47 次。它已经把 7 交出来了。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:67](../src/scenes/phone/P06_Tiyi/index.tsx#L67)
297. 获得第 2 位：7
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:74](../src/scenes/phone/P06_Tiyi/index.tsx#L74)
298. 课外锻炼已经在记录。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:79](../src/scenes/phone/P06_Tiyi/index.tsx#L79)
299. 锻炼对象没有姓名。先去给他打电话。
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:83](../src/scenes/phone/P06_Tiyi/index.tsx#L83)
300. 浙大体艺加载中
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:95](../src/scenes/phone/P06_Tiyi/index.tsx#L95)
301. 退出
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:103](../src/scenes/phone/P06_Tiyi/index.tsx#L103)
302. 运动打卡次数 47
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:117](../src/scenes/phone/P06_Tiyi/index.tsx#L117)
303. 开始虚拟定位
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:134](../src/scenes/phone/P06_Tiyi/index.tsx#L134)
304. 课外锻炼进行中
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:134](../src/scenes/phone/P06_Tiyi/index.tsx#L134)
305. 10 分钟跑完 3 km · 点击生成轨迹
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:137](../src/scenes/phone/P06_Tiyi/index.tsx#L137)
306. 请先在部门黄页确认参加者
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:138](../src/scenes/phone/P06_Tiyi/index.tsx#L138)
307. 退出浙大体艺，返回手机主页
   来源：[src/scenes/phone/P06_Tiyi/index.tsx:149](../src/scenes/phone/P06_Tiyi/index.tsx#L149)
308. 到座耗时
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:39](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L39)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:255](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L255)
309. 分钟
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:40](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L40)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:255](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L255)
310. 入口小屏 · 计算时间差
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:45](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L45)
311. 公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:49](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L49)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:202](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L202)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:256](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L256)
312. 号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:50](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L50)
313. CC98 楼主编辑 · 读取编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:55](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L55)
314. 证明数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:59](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L59)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:257](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L257)
315. 项
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:60](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L60)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:257](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L257)
316. 旧版规则 · 统计类别
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:65](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L65)
317. 图书馆入口
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:73](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L73)
318. 前台
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:75](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L75)
319. 失物招领
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:76](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L76)
320. 馆藏检索
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:77](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L77)
321. 打印机
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:78](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L78)
322. 书架背面
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:79](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L79)
323. 仍有字段与来源不一致。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:91](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L91)
324. 三项字段分别对应三份已保存的证据。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:111](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L111)
325. 本人来过证明补录单
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:152](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L152)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:157](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L157)
326. 补录成功
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:157](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L157)
327. 待补录 · 先核对下方三项调查材料
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:158](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L158)
328. 系统已承认你确实来过图书馆
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:158](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L158)
329. 表单 022
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:160](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L160)
330. 已认证
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:160](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L160)；[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:251](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L251)
331. 已记录的图书馆路线
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:163](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L163)
332. 检测到室内异常锻炼路线
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:164](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L164)
333. 寝室
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:166](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L166)
334. 补录方法
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:173](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L173)
335. 三项材料从哪里取得
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:174](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L174)
336. 01 图书馆入口小屏
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:176](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L176)
337. 填写到座耗时
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:176](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L176)
338. 02 CC98 调查帖楼主编辑
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:177](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L177)
339. 填写公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:177](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L177)
340. 03 二楼南区 755 书架旧版规则
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:178](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L178)
341. 填写证明数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:178](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L178)
342. 三项材料可按任意顺序收集；取得后，下方会显示可核对的原文。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:180](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L180)
343. 审核依据
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:183](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L183)
344. 填：到座耗时
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:187](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L187)
345. 图书馆入口小屏
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:187](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L187)
346. 二楼南区 022
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:190](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L190)
347. 主馆入口
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:190](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L190)
348. 填写两次记录的分钟差
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:191](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L191)
349. 未取得 · 回到基础图书馆入口，查看门禁记录小屏
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:193](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L193)
350. 填：公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:199](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L199)
351. CC98 调查帖 · 23 楼楼主编辑
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:199](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L199)
352. 楼主编辑原文：旧申请统一挂在
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:202](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L202)
353. 23 是回复楼层；填写原文中的公示编号
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:203](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L203)
354. 未取得 · 在 022 座位拿到占座纸条，用它打开 CC98 调查帖
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:205](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L205)
355. 《旧版临时离座恢复规定》
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:211](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L211)
356. 填：证明数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:211](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L211)
357. 填写规则列出的证明类别数量
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:217](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L217)
358. 未取得 · 在二楼南区 755 书架使用“索书号 755”，取得并阅读规则
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:219](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L219)
359. 来源
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:236](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L236)
360. {{control.label}}减一
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:238](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L238)
361. {{control.label}}加一
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:240](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L240)
362. 提交补录
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:246](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L246)
363. 本人来过证明
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:252](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L252)
364. 一张证明你来过的证明。它没有证明你为什么要来。
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:253](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L253)
365. 已验证补录值
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:254](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L254)
366. 返回手机主页
   来源：[src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx:259](../src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx#L259)
367. 已照光
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:31](../src/scenes/phone/P10_Bonsai/index.tsx#L31)
368. 已浇水
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:47](../src/scenes/phone/P10_Bonsai/index.tsx#L47)
369. 已施肥
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:58](../src/scenes/phone/P10_Bonsai/index.tsx#L58)
370. 没什么反应。
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:66](../src/scenes/phone/P10_Bonsai/index.tsx#L66)
371. 花心空空的。
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:78](../src/scenes/phone/P10_Bonsai/index.tsx#L78)
372. 它绝对不会开花。
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:81](../src/scenes/phone/P10_Bonsai/index.tsx#L81)
373. 获得第 4 位：8
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:92](../src/scenes/phone/P10_Bonsai/index.tsx#L92)
374. 好像有点想开花
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:95](../src/scenes/phone/P10_Bonsai/index.tsx#L95)
375. 开花了？！
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:95](../src/scenes/phone/P10_Bonsai/index.tsx#L95)
376. 它绝对不会开花
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:95](../src/scenes/phone/P10_Bonsai/index.tsx#L95)
377. 盆栽
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:98](../src/scenes/phone/P10_Bonsai/index.tsx#L98)；[src/scenes/phone/P10_Bonsai/index.tsx:104](../src/scenes/phone/P10_Bonsai/index.tsx#L104)
378. 盛开的盆栽
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:104](../src/scenes/phone/P10_Bonsai/index.tsx#L104)
379. 数字 8
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:114](../src/scenes/phone/P10_Bonsai/index.tsx#L114)
380. waterDrop
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:121](../src/scenes/phone/P10_Bonsai/index.tsx#L121)
381. sun
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:124](../src/scenes/phone/P10_Bonsai/index.tsx#L124)
382. fertilizer
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:127](../src/scenes/phone/P10_Bonsai/index.tsx#L127)
383. 退出盆栽，返回手机主页
   来源：[src/scenes/phone/P10_Bonsai/index.tsx:131](../src/scenes/phone/P10_Bonsai/index.tsx#L131)
384. 请连接校园网。
   来源：[src/scenes/phone/P11_Checkin/index.tsx:93](../src/scenes/phone/P11_Checkin/index.tsx#L93)
385. 签到码错误。
   来源：[src/scenes/phone/P11_Checkin/index.tsx:102](../src/scenes/phone/P11_Checkin/index.tsx#L102)
386. 获得第 1 位：0
   来源：[src/scenes/phone/P11_Checkin/index.tsx:115](../src/scenes/phone/P11_Checkin/index.tsx#L115)
387. 校务签到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:126](../src/scenes/phone/P11_Checkin/index.tsx#L126)
388. 返回学在浙大
   来源：[src/scenes/phone/P11_Checkin/index.tsx:128](../src/scenes/phone/P11_Checkin/index.tsx#L128)
389. 学在浙大 · 课堂签到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:129](../src/scenes/phone/P11_Checkin/index.tsx#L129)
390. 高等数学（早八特供版）
   来源：[src/scenes/phone/P11_Checkin/index.tsx:134](../src/scenes/phone/P11_Checkin/index.tsx#L134)
391. 快快老师 · 紫金港西1-201 · 08:00
   来源：[src/scenes/phone/P11_Checkin/index.tsx:137](../src/scenes/phone/P11_Checkin/index.tsx#L137)
392. 正在点名中……
   来源：[src/scenes/phone/P11_Checkin/index.tsx:138](../src/scenes/phone/P11_Checkin/index.tsx#L138)
393. 本周缺勤
   来源：[src/scenes/phone/P11_Checkin/index.tsx:140](../src/scenes/phone/P11_Checkin/index.tsx#L140)
394. 收集本周缺勤次数零
   来源：[src/scenes/phone/P11_Checkin/index.tsx:142](../src/scenes/phone/P11_Checkin/index.tsx#L142)
395. 次
   来源：[src/scenes/phone/P11_Checkin/index.tsx:146](../src/scenes/phone/P11_Checkin/index.tsx#L146)
396. 签到码输入
   来源：[src/scenes/phone/P11_Checkin/index.tsx:150](../src/scenes/phone/P11_Checkin/index.tsx#L150)
397. 签到码错误，请重新输入
   来源：[src/scenes/phone/P11_Checkin/index.tsx:168](../src/scenes/phone/P11_Checkin/index.tsx#L168)
398. 数字键盘
   来源：[src/scenes/phone/P11_Checkin/index.tsx:170](../src/scenes/phone/P11_Checkin/index.tsx#L170)
399. 删除
   来源：[src/scenes/phone/P11_Checkin/index.tsx:176](../src/scenes/phone/P11_Checkin/index.tsx#L176)
400. 签到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:183](../src/scenes/phone/P11_Checkin/index.tsx#L183)
401. 签
   来源：[src/scenes/phone/P11_Checkin/index.tsx:194](../src/scenes/phone/P11_Checkin/index.tsx#L194)
402. 到
   来源：[src/scenes/phone/P11_Checkin/index.tsx:195](../src/scenes/phone/P11_Checkin/index.tsx#L195)
403. 系统通知 · LOCATION ERROR
   来源：[src/scenes/phone/P11_Checkin/index.tsx:200](../src/scenes/phone/P11_Checkin/index.tsx#L200)
404. 经度与纬度不存在
   来源：[src/scenes/phone/P11_Checkin/index.tsx:201](../src/scenes/phone/P11_Checkin/index.tsx#L201)
405. longitude: null · latitude: null
   来源：[src/scenes/phone/P11_Checkin/index.tsx:202](../src/scenes/phone/P11_Checkin/index.tsx#L202)
406. 黑屏
   来源：[src/scenes/phone/P11_Checkin/index.tsx:208](../src/scenes/phone/P11_Checkin/index.tsx#L208)
407. 齿轮已经掉在下面了。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:223](../src/scenes/phone/P13_PhoneHome/index.tsx#L223)
408. 它看起来很想转转。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:227](../src/scenes/phone/P13_PhoneHome/index.tsx#L227)
409. 它转起来了！
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:227](../src/scenes/phone/P13_PhoneHome/index.tsx#L227)
410. {{definition.ariaLabel ?? definition.label}}{{access.chapter === "chapter\_one" ? "" : "，按 F2 编辑桌面"}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:554](../src/scenes/phone/P13_PhoneHome/index.tsx#L554)
411. 检查上铺床组
   来源：[src/scenes/rpg/DormHubModel.ts:115](../src/scenes/rpg/DormHubModel.ts#L115)
412. 检查下铺床组
   来源：[src/scenes/rpg/DormHubModel.ts:116](../src/scenes/rpg/DormHubModel.ts#L116)
413. 拉动窗帘
   来源：[src/scenes/rpg/DormHubModel.ts:117](../src/scenes/rpg/DormHubModel.ts#L117)
414. 打开窗下柜
   来源：[src/scenes/rpg/DormHubModel.ts:118](../src/scenes/rpg/DormHubModel.ts#L118)
415. 查看鞋架
   来源：[src/scenes/rpg/DormHubModel.ts:119](../src/scenes/rpg/DormHubModel.ts#L119)
416. 查看洗衣篮
   来源：[src/scenes/rpg/DormHubModel.ts:120](../src/scenes/rpg/DormHubModel.ts#L120)
417. 拨动蓝色台灯
   来源：[src/scenes/rpg/DormHubModel.ts:121](../src/scenes/rpg/DormHubModel.ts#L121)
418. 翻看摊开的书
   来源：[src/scenes/rpg/DormHubModel.ts:122](../src/scenes/rpg/DormHubModel.ts#L122)
419. 检查个人书桌
   来源：[src/scenes/rpg/DormHubModel.ts:123](../src/scenes/rpg/DormHubModel.ts#L123)
420. 拉开书桌抽屉
   来源：[src/scenes/rpg/DormHubModel.ts:124](../src/scenes/rpg/DormHubModel.ts#L124)
421. 拧开水龙头
   来源：[src/scenes/rpg/DormHubModel.ts:125](../src/scenes/rpg/DormHubModel.ts#L125)
422. 查看床边书架
   来源：[src/scenes/rpg/DormHubModel.ts:126](../src/scenes/rpg/DormHubModel.ts#L126)
423. 检查地上的背包
   来源：[src/scenes/rpg/DormHubModel.ts:127](../src/scenes/rpg/DormHubModel.ts#L127)
424. 打开寝室门
   来源：[src/scenes/rpg/DormHubModel.ts:128](../src/scenes/rpg/DormHubModel.ts#L128)
425. 拿起书桌上的吹风机
   来源：[src/scenes/rpg/DormHubModel.ts:165](../src/scenes/rpg/DormHubModel.ts#L165)
426. 床帘后只有一床叠得过分认真的被子。
   来源：[src/scenes/rpg/DormHubScene.ts:60](../src/scenes/rpg/DormHubScene.ts#L60)
427. 枕头下面没有捷径，只有一张过期的外卖券。
   来源：[src/scenes/rpg/DormHubScene.ts:61](../src/scenes/rpg/DormHubScene.ts#L61)
428. 窗外很亮。七点五十五分不会因此晚一点。
   来源：[src/scenes/rpg/DormHubScene.ts:62](../src/scenes/rpg/DormHubScene.ts#L62)
429. 柜门打开了。里面整齐地保存着一片空白。
   来源：[src/scenes/rpg/DormHubScene.ts:63](../src/scenes/rpg/DormHubScene.ts#L63)
430. 鞋都在，人也该在。这个推理暂时没有帮助。
   来源：[src/scenes/rpg/DormHubScene.ts:64](../src/scenes/rpg/DormHubScene.ts#L64)
431. 洗衣篮拒绝提供任何关于签到记录的证词。
   来源：[src/scenes/rpg/DormHubScene.ts:65](../src/scenes/rpg/DormHubScene.ts#L65)
432. 蓝色台灯亮了。桌面终于像有人认真学习过。
   来源：[src/scenes/rpg/DormHubScene.ts:66](../src/scenes/rpg/DormHubScene.ts#L66)
433. 书翻到夹着便签的一页：先找到名字，再谈方向。
   来源：[src/scenes/rpg/DormHubScene.ts:67](../src/scenes/rpg/DormHubScene.ts#L67)
434. 这是你的书桌。校园卡压在桌面的纸张旁边。
   来源：[src/scenes/rpg/DormHubScene.ts:68](../src/scenes/rpg/DormHubScene.ts#L68)
435. 抽屉里有三支没墨的笔，以及非常稳定的失望。
   来源：[src/scenes/rpg/DormHubScene.ts:69](../src/scenes/rpg/DormHubScene.ts#L69)
436. 吹风机还能正常工作。
   来源：[src/scenes/rpg/DormHubScene.ts:70](../src/scenes/rpg/DormHubScene.ts#L70)
437. 水龙头还能出水。至少寝室里有一个系统响应正常。
   来源：[src/scenes/rpg/DormHubScene.ts:71](../src/scenes/rpg/DormHubScene.ts#L71)
438. 书脊按课程排好，最薄的那本写着《平时分自救》。
   来源：[src/scenes/rpg/DormHubScene.ts:72](../src/scenes/rpg/DormHubScene.ts#L72)
439. 不是你的包。拉链上挂着一句很明确的‘别翻’。
   来源：[src/scenes/rpg/DormHubScene.ts:73](../src/scenes/rpg/DormHubScene.ts#L73)
440. 门没有意见，流程有。
   来源：[src/scenes/rpg/DormHubScene.ts:74](../src/scenes/rpg/DormHubScene.ts#L74)
441. 这件道具暂时不需要交给他。
   来源：[src/scenes/rpg/DormHubScene.ts:285](../src/scenes/rpg/DormHubScene.ts#L285)
442. gamepad
   来源：[src/scenes/rpg/DormHubScene.ts:288](../src/scenes/rpg/DormHubScene.ts#L288)；[src/scenes/rpg/DormHubScene.ts:290](../src/scenes/rpg/DormHubScene.ts#L290)
443. missed\_target
   来源：[src/scenes/rpg/DormHubScene.ts:288](../src/scenes/rpg/DormHubScene.ts#L288)；[src/scenes/rpg/DormHubScene.ts:299](../src/scenes/rpg/DormHubScene.ts#L299)
444. wrong\_item
   来源：[src/scenes/rpg/DormHubScene.ts:288](../src/scenes/rpg/DormHubScene.ts#L288)
445. 角色
   来源：[src/scenes/rpg/DormHubScene.ts:289](../src/scenes/rpg/DormHubScene.ts#L289)；[src/scenes/rpg/DormHubScene.ts:300](../src/scenes/rpg/DormHubScene.ts#L300)
446. 道具没有进入有效的游戏画布。
   来源：[src/scenes/rpg/DormHubScene.ts:290](../src/scenes/rpg/DormHubScene.ts#L290)
447. 角色当前只接收游戏手柄。
   来源：[src/scenes/rpg/DormHubScene.ts:290](../src/scenes/rpg/DormHubScene.ts#L290)
448. 把手柄拖到小人身上。
   来源：[src/scenes/rpg/DormHubScene.ts:296](../src/scenes/rpg/DormHubScene.ts#L296)
449. 松手点没有进入角色身体范围。
   来源：[src/scenes/rpg/DormHubScene.ts:301](../src/scenes/rpg/DormHubScene.ts#L301)
450. 你被送回寝室，衣服还在滴水。
   来源：[src/scenes/rpg/DormHubScene.ts:408](../src/scenes/rpg/DormHubScene.ts#L408)
451. 吹风机已经放进物品栏。
   来源：[src/scenes/rpg/DormHubScene.ts:422](../src/scenes/rpg/DormHubScene.ts#L422)
452. 现在还不需要使用吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:423](../src/scenes/rpg/DormHubScene.ts#L423)
453. 获得寝室吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:431](../src/scenes/rpg/DormHubScene.ts#L431)
454. 拿起个人书桌上的校园卡
   来源：[src/scenes/rpg/DormHubScene.ts:627](../src/scenes/rpg/DormHubScene.ts#L627)
455. 先用手机天气页面处理启真湖的云层。
   来源：[src/scenes/rpg/DormHubScene.ts:646](../src/scenes/rpg/DormHubScene.ts#L646)
456. 先从自己的书桌拿到吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:647](../src/scenes/rpg/DormHubScene.ts#L647)
457. 寝室门已打开。
   来源：[src/scenes/rpg/DormHubScene.ts:652](../src/scenes/rpg/DormHubScene.ts#L652)
458. 先完成基础馆二层南区 022 的座位预约。
   来源：[src/scenes/rpg/DormHubScene.ts:670](../src/scenes/rpg/DormHubScene.ts#L670)
459. 校园卡已经在物品栏里。
   来源：[src/scenes/rpg/DormHubScene.ts:677](../src/scenes/rpg/DormHubScene.ts#L677)
460. 当前任务还没有开放校园卡拾取。
   来源：[src/scenes/rpg/DormHubScene.ts:681](../src/scenes/rpg/DormHubScene.ts#L681)
461. 获得校园卡。身份信息已可读。
   来源：[src/scenes/rpg/DormHubScene.ts:688](../src/scenes/rpg/DormHubScene.ts#L688)
462. 他现在会按你的方向移动。
   来源：[src/scenes/rpg/DormHubScene.ts:695](../src/scenes/rpg/DormHubScene.ts#L695)
463. 方向控制已安装，试着让他走一步。
   来源：[src/scenes/rpg/DormHubScene.ts:696](../src/scenes/rpg/DormHubScene.ts#L696)

## 第二章

1. CHAPTER 02
   来源：[src/App.tsx:384](../src/App.tsx#L384)
2. 第 2 章
   来源：[src/App.tsx:385](../src/App.tsx#L385)
3. 找到移动的办法
   来源：[src/App.tsx:386](../src/App.tsx#L386)；[src/core/QuestModel.ts:238](../src/core/QuestModel.ts#L238)
4. 进入第二章
   来源：[src/App.tsx:387](../src/App.tsx#L387)
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
   来源：[src/core/QuestModel.ts:112](../src/core/QuestModel.ts#L112)
16. 主页的「方向校准」与天气页面各有一项变化，两边可以分别检查。
   来源：[src/core/QuestModel.ts:114](../src/core/QuestModel.ts#L114)
17. 取得顺序不影响后续组合。
   来源：[src/core/QuestModel.ts:115](../src/core/QuestModel.ts#L115)
18. 查看主页的「方向校准」推送
   来源：[src/core/QuestModel.ts:123](../src/core/QuestModel.ts#L123)
19. 连续检查推送头像边缘，取下松动的三角形。
   来源：[src/core/QuestModel.ts:124](../src/core/QuestModel.ts#L124)
20. 从天气页面取得天气水滴
   来源：[src/core/QuestModel.ts:131](../src/core/QuestModel.ts#L131)
21. 打开天气页面，收集已经出现的水滴。
   来源：[src/core/QuestModel.ts:132](../src/core/QuestModel.ts#L132)
22. 用天气水滴处理导师头像
   来源：[src/core/QuestModel.ts:139](../src/core/QuestModel.ts#L139)
23. 打开微信，把天气水滴拖到导师头像边缘的黏着竖线。
   来源：[src/core/QuestModel.ts:140](../src/core/QuestModel.ts#L140)
24. 组合三角形与竖线
   来源：[src/core/QuestModel.ts:147](../src/core/QuestModel.ts#L147)
25. 在道具栏中将主页三角形与导师头像掉落的竖线组合。
   来源：[src/core/QuestModel.ts:148](../src/core/QuestModel.ts#L148)
26. 用右移箭头调整校园卡余额
   来源：[src/core/QuestModel.ts:155](../src/core/QuestModel.ts#L155)
27. 把右移箭头拖到电子校园卡的余额数字上。
   来源：[src/core/QuestModel.ts:156](../src/core/QuestModel.ts#L156)
28. 完成 CC98 首次身份认证
   来源：[src/core/QuestModel.ts:163](../src/core/QuestModel.ts#L163)
29. 先从随身校园卡读取 10 位学号。
   来源：[src/core/QuestModel.ts:165](../src/core/QuestModel.ts#L165)
30. 密码按校名缩写、建校年份、结尾标点三段拼接。
   来源：[src/core/QuestModel.ts:166](../src/core/QuestModel.ts#L166)
31. 去 CC98 购买游戏手柄
   来源：[src/core/QuestModel.ts:174](../src/core/QuestModel.ts#L174)
32. 打开 CC98 二手交易，用调整后的校园卡余额付款。
   来源：[src/core/QuestModel.ts:175](../src/core/QuestModel.ts#L175)
33. 把游戏手柄安装到寝室角色
   来源：[src/core/QuestModel.ts:182](../src/core/QuestModel.ts#L182)
34. 返回寝室，把道具栏里的游戏手柄拖到角色身上。
   来源：[src/core/QuestModel.ts:183](../src/core/QuestModel.ts#L183)
35. 完成第一次手动移动
   来源：[src/core/QuestModel.ts:189](../src/core/QuestModel.ts#L189)
36. 使用方向键移动一次，确认手柄已经生效。
   来源：[src/core/QuestModel.ts:190](../src/core/QuestModel.ts#L190)
37. 确认方向控制已经生效
   来源：[src/core/QuestModel.ts:195](../src/core/QuestModel.ts#L195)
38. 让地图人物回应你
   来源：[src/core/QuestModel.ts:202](../src/core/QuestModel.ts#L202)
39. 找到道具栏
   来源：[src/core/QuestModel.ts:202](../src/core/QuestModel.ts#L202)
40. 手机里有能联系校内人员的地方。
   来源：[src/core/QuestModel.ts:204](../src/core/QuestModel.ts#L204)
41. 用校园卡上的身份信息，在部门黄页里找到他。
   来源：[src/core/QuestModel.ts:205](../src/core/QuestModel.ts#L205)
42. 让地图人物动起来
   来源：[src/core/QuestModel.ts:212](../src/core/QuestModel.ts#L212)
43. 有一个 App 专门负责把普通走路变成记录。
   来源：[src/core/QuestModel.ts:214](../src/core/QuestModel.ts#L214)
44. 打开浙大体艺，开始课外锻炼。
   来源：[src/core/QuestModel.ts:215](../src/core/QuestModel.ts#L215)
45. 预约 022
   来源：[src/core/QuestModel.ts:223](../src/core/QuestModel.ts#L223)
46. 二层南区022
   来源：[src/core/QuestModel.ts:224](../src/core/QuestModel.ts#L224)
47. 主页方向校准
   来源：[src/core/QuestModel.ts:244](../src/core/QuestModel.ts#L244)
48. 松动三角形
   来源：[src/core/QuestModel.ts:245](../src/core/QuestModel.ts#L245)
49. 天气页面
   来源：[src/core/QuestModel.ts:251](../src/core/QuestModel.ts#L251)
50. 天气水滴
   来源：[src/core/QuestModel.ts:252](../src/core/QuestModel.ts#L252)
51. completed
   来源：[src/core/QuestModel.ts:267](../src/core/QuestModel.ts#L267)
52. pending
   来源：[src/core/QuestModel.ts:267](../src/core/QuestModel.ts#L267)
53. 去图书馆
   来源：[src/core/QuestModel.ts:284](../src/core/QuestModel.ts#L284)
54. 地图缩放仔细找
   来源：[src/core/QuestModel.ts:285](../src/core/QuestModel.ts#L285)
55. 确认座位状态
   来源：[src/core/QuestModel.ts:290](../src/core/QuestModel.ts#L290)
56. 去 RPG 图书馆地图找 022。
   来源：[src/core/QuestModel.ts:292](../src/core/QuestModel.ts#L292)
57. 检查 022 上的东西和旁边的纸条。
   来源：[src/core/QuestModel.ts:293](../src/core/QuestModel.ts#L293)
58. 查清占座规则
   来源：[src/core/QuestModel.ts:299](../src/core/QuestModel.ts#L299)
59. 纸条提到了一个更吵的地方。
   来源：[src/core/QuestModel.ts:301](../src/core/QuestModel.ts#L301)
60. CC98 里有人讨论过 022。
   来源：[src/core/QuestModel.ts:302](../src/core/QuestModel.ts#L302)
61. 用占座纸条搜索 CC98，再顺着帖子找旧规则。
   来源：[src/core/QuestModel.ts:303](../src/core/QuestModel.ts#L303)
62. 凑齐恢复材料（{{proofCount}}/3）
   来源：[src/core/QuestModel.ts:310](../src/core/QuestModel.ts#L310)
63. 照片、座位夹缝和体艺都能帮上忙。
   来源：[src/core/QuestModel.ts:312](../src/core/QuestModel.ts#L312)
64. 照片曝光了就把光调小（控制中心光条）
   来源：[src/core/QuestModel.ts:313](../src/core/QuestModel.ts#L313)
65. 体艺 7,47,3
   来源：[src/core/QuestModel.ts:314](../src/core/QuestModel.ts#L314)
66. 让帖子被看见
   来源：[src/core/QuestModel.ts:321](../src/core/QuestModel.ts#L321)
67. 3027，为什么自己想
   来源：[src/core/QuestModel.ts:322](../src/core/QuestModel.ts#L322)
68. 提交恢复申请
   来源：[src/core/QuestModel.ts:328](../src/core/QuestModel.ts#L328)
69. 在浙大钉-&gt;图书馆-&gt;pass申请
   来源：[src/core/QuestModel.ts:329](../src/core/QuestModel.ts#L329)
70. 回到 022
   来源：[src/core/QuestModel.ts:335](../src/core/QuestModel.ts#L335)
71. 字面意思。
   来源：[src/core/QuestModel.ts:336](../src/core/QuestModel.ts#L336)
72. 恢复 022 座位
   来源：[src/core/QuestModel.ts:359](../src/core/QuestModel.ts#L359)
73. 第二章·022 的占座书包
   来源：[src/data/library-finals.content.json:3](../src/data/library-finals.content.json#L3)
74. 这里就是图书馆？
   来源：[src/data/library-finals.content.json:10](../src/data/library-finals.content.json#L10)
75. 她最后留下入馆记录的地方。
   来源：[src/data/library-finals.content.json:11](../src/data/library-finals.content.json#L11)
76. 系统
   来源：[src/data/library-finals.content.json:11](../src/data/library-finals.content.json#L11)；[src/data/library-finals.content.json:13](../src/data/library-finals.content.json#L13)；[src/data/library-finals.content.json:15](../src/data/library-finals.content.json#L15)；[src/data/library-finals.content.json:17](../src/data/library-finals.content.json#L17)；[src/data/library-finals.content.json:19](../src/data/library-finals.content.json#L19)；[src/data/library-finals.content.json:21](../src/data/library-finals.content.json#L21)；[src/data/library-finals.content.json:27](../src/data/library-finals.content.json#L27)；[src/data/library-finals.content.json:30](../src/data/library-finals.content.json#L30)；[src/data/library-finals.content.json:32](../src/data/library-finals.content.json#L32)；[src/data/library-finals.content.json:36](../src/data/library-finals.content.json#L36)；[src/data/library-finals.content.json:39](../src/data/library-finals.content.json#L39)；[src/data/library-finals.content.json:41](../src/data/library-finals.content.json#L41)；[src/data/library-finals.content.json:43](../src/data/library-finals.content.json#L43)；[src/data/library-finals.content.json:44](../src/data/library-finals.content.json#L44)；[src/data/library-finals.content.json:55](../src/data/library-finals.content.json#L55)；[src/data/library-finals.content.json:61](../src/data/library-finals.content.json#L61)；[src/data/library-finals.content.json:63](../src/data/library-finals.content.json#L63)；[src/data/library-finals.content.json:67](../src/data/library-finals.content.json#L67)；[src/data/library-finals.content.json:69](../src/data/library-finals.content.json#L69)；[src/data/library-finals.content.json:75](../src/data/library-finals.content.json#L75)；[src/data/library-finals.content.json:84](../src/data/library-finals.content.json#L84)；[src/data/library-finals.content.json:267](../src/data/library-finals.content.json#L267)；[src/data/library-finals.content.json:269](../src/data/library-finals.content.json#L269)；[src/data/library-finals.content.json:277](../src/data/library-finals.content.json#L277)；[src/data/library-finals.content.json:281](../src/data/library-finals.content.json#L281)；[src/data/library-finals.content.json:284](../src/data/library-finals.content.json#L284)
77. 你朋友是管理员？
   来源：[src/data/library-finals.content.json:12](../src/data/library-finals.content.json#L12)
78. 她不管馆内秩序。
   来源：[src/data/library-finals.content.json:13](../src/data/library-finals.content.json#L13)
79. 馆长？
   来源：[src/data/library-finals.content.json:14](../src/data/library-finals.content.json#L14)
80. 也不在馆长名册里。
   来源：[src/data/library-finals.content.json:15](../src/data/library-finals.content.json#L15)
81. 所以是？
   来源：[src/data/library-finals.content.json:16](../src/data/library-finals.content.json#L16)
82. 一个座位，二楼南区 022。
   来源：[src/data/library-finals.content.json:17](../src/data/library-finals.content.json#L17)
83. 上次见面时，她就在 022。
   来源：[src/data/library-finals.content.json:19](../src/data/library-finals.content.json#L19)
84. 以前？
   来源：[src/data/library-finals.content.json:20](../src/data/library-finals.content.json#L20)
85. 这张记录没有固定时长。先去闸机核对入馆时间。
   来源：[src/data/library-finals.content.json:21](../src/data/library-finals.content.json#L21)
86. 书包
   来源：[src/data/library-finals.content.json:24](../src/data/library-finals.content.json#L24)；[src/data/library-finals.content.json:81](../src/data/library-finals.content.json#L81)；[src/data/library-finals.content.json:83](../src/data/library-finals.content.json#L83)
87. 022 被一个书包占着，桌上的纸条写着“主人马上回来”。
   来源：[src/data/library-finals.content.json:25](../src/data/library-finals.content.json#L25)
88. 它把座位占了。
   来源：[src/data/library-finals.content.json:26](../src/data/library-finals.content.json#L26)
89. 先别碰。去 CC98 查三分钟离座的规则。
   来源：[src/data/library-finals.content.json:27](../src/data/library-finals.content.json#L27)
90. 先看这条讨论，确认三分钟离座的规则。
   来源：[src/data/library-finals.content.json:30](../src/data/library-finals.content.json#L30)
91. 查到以后呢？
   来源：[src/data/library-finals.content.json:31](../src/data/library-finals.content.json#L31)
92. 拿到规则，再补齐恢复 022 的证明。
   来源：[src/data/library-finals.content.json:32](../src/data/library-finals.content.json#L32)
93. 书名、索书号和 022 的记录都能对上。
   来源：[src/data/library-finals.content.json:35](../src/data/library-finals.content.json#L35)
94. 去二楼南区 755 号书架背面找旧版规则。
   来源：[src/data/library-finals.content.json:36](../src/data/library-finals.content.json#L36)
95. 旧版离座规则找到了。
   来源：[src/data/library-finals.content.json:39](../src/data/library-finals.content.json#L39)
96. 坏消息？
   来源：[src/data/library-finals.content.json:40](../src/data/library-finals.content.json#L40)
97. 它要求三项证明。
   来源：[src/data/library-finals.content.json:41](../src/data/library-finals.content.json#L41)
98. 书包还要核验身份？
   来源：[src/data/library-finals.content.json:42](../src/data/library-finals.content.json#L42)
99. 规则只认已经留下的材料。
   来源：[src/data/library-finals.content.json:43](../src/data/library-finals.content.json#L43)
100. 座位小票、到馆证明、书包非本人证明。
   来源：[src/data/library-finals.content.json:44](../src/data/library-finals.content.json#L44)
101. 前台
   来源：[src/data/library-finals.content.json:48](../src/data/library-finals.content.json#L48)；[src/data/library-finals.content.json:50](../src/data/library-finals.content.json#L50)；[src/data/library-finals.content.json:52](../src/data/library-finals.content.json#L52)；[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
102. 请说明要处理的物品。
   来源：[src/data/library-finals.content.json:48](../src/data/library-finals.content.json#L48)
103. 022 的占座书包。
   来源：[src/data/library-finals.content.json:49](../src/data/library-finals.content.json#L49)
104. 请先提交书包非本人证明。
   来源：[src/data/library-finals.content.json:50](../src/data/library-finals.content.json#L50)
105. 书包也要做身份核验？
   来源：[src/data/library-finals.content.json:51](../src/data/library-finals.content.json#L51)
106. 系统里，它目前登记为座位使用者。
   来源：[src/data/library-finals.content.json:52](../src/data/library-finals.content.json#L52)
107. 盖章完成。书包不再算 022 的使用者。
   来源：[src/data/library-finals.content.json:55](../src/data/library-finals.content.json#L55)
108. 我今天跑的证明比上课还多。
   来源：[src/data/library-finals.content.json:56](../src/data/library-finals.content.json#L56)
109. 补录成功。
   来源：[src/data/library-finals.content.json:59](../src/data/library-finals.content.json#L59)
110. 体艺
   来源：[src/data/library-finals.content.json:59](../src/data/library-finals.content.json#L59)；[src/data/library-finals.content.json:60](../src/data/library-finals.content.json#L60)
111. 入馆和到馆时间已写入记录。
   来源：[src/data/library-finals.content.json:60](../src/data/library-finals.content.json#L60)
112. 到馆证明拿到了。
   来源：[src/data/library-finals.content.json:61](../src/data/library-finals.content.json#L61)
113. 终于有一项证明的是我自己。
   来源：[src/data/library-finals.content.json:62](../src/data/library-finals.content.json#L62)
114. 还差座位小票。
   来源：[src/data/library-finals.content.json:63](../src/data/library-finals.content.json#L63)
115. 好了，证据齐了。现在图书馆会处理了吧？
   来源：[src/data/library-finals.content.json:66](../src/data/library-finals.content.json#L66)
116. 还差公开确认。图书馆 App 只读取十大帖的四位热度口令。
   来源：[src/data/library-finals.content.json:67](../src/data/library-finals.content.json#L67)
117. bd 到底是什么？
   来源：[src/data/library-finals.content.json:68](../src/data/library-finals.content.json#L68)
118. bd 是“帮顶”。在一条数字回复上点 bd，数字就会按顺序写入口令。
   来源：[src/data/library-finals.content.json:69](../src/data/library-finals.content.json#L69)
119. 帖子到了第一，022 的恢复申请入口开放。
   来源：[src/data/library-finals.content.json:72](../src/data/library-finals.content.json#L72)
120. 清退凭证生成。带它回 022。
   来源：[src/data/library-finals.content.json:75](../src/data/library-finals.content.json#L75)
121. 这次该把座位还给人了。
   来源：[src/data/library-finals.content.json:76](../src/data/library-finals.content.json#L76)
122. 请占座物品离开 022。
   来源：[src/data/library-finals.content.json:79](../src/data/library-finals.content.json#L79)
123. 图书馆提示
   来源：[src/data/library-finals.content.json:79](../src/data/library-finals.content.json#L79)；[src/data/library-finals.content.json:80](../src/data/library-finals.content.json#L80)
124. 如需认领，请前往失物招领。
   来源：[src/data/library-finals.content.json:80](../src/data/library-finals.content.json#L80)
125. 主人马上回来。
   来源：[src/data/library-finals.content.json:81](../src/data/library-finals.content.json#L81)
126. 什么时候？
   来源：[src/data/library-finals.content.json:82](../src/data/library-finals.content.json#L82)
127. 三分钟。
   来源：[src/data/library-finals.content.json:83](../src/data/library-finals.content.json#L83)
128. 纸条上的这句话已经留了三天。
   来源：[src/data/library-finals.content.json:84](../src/data/library-finals.content.json#L84)
129. 二南临时读者
   来源：[src/data/library-finals.content.json:90](../src/data/library-finals.content.json#L90)；[src/data/library-finals.content.json:104](../src/data/library-finals.content.json#L104)；[src/data/library-finals.content.json:138](../src/data/library-finals.content.json#L138)
130. 求助
   来源：[src/data/library-finals.content.json:92](../src/data/library-finals.content.json#L92)
131. 校园生活
   来源：[src/data/library-finals.content.json:93](../src/data/library-finals.content.json#L93)
132. 【求助】022 的书包占座三天了
   来源：[src/data/library-finals.content.json:94](../src/data/library-finals.content.json#L94)
133. 26-07-12 08:02
   来源：[src/data/library-finals.content.json:97](../src/data/library-finals.content.json#L97)
134. 二楼南区 022 有个书包，纸条写着离开三分钟。人没回来，座位也没有空。
   来源：[src/data/library-finals.content.json:98](../src/data/library-finals.content.json#L98)
135. 楼主
   来源：[src/data/library-finals.content.json:105](../src/data/library-finals.content.json#L105)
136. 022 有个书包，离开三分钟回来还在。纸条写着离开三分钟，回来时系统已经换人。
   来源：[src/data/library-finals.content.json:106](../src/data/library-finals.content.json#L106)
137. 入口记录员
   来源：[src/data/library-finals.content.json:110](../src/data/library-finals.content.json#L110)
138. 补充
   来源：[src/data/library-finals.content.json:111](../src/data/library-finals.content.json#L111)
139. 入馆记录能证明你什么时候到，但不能证明座位上的东西属于谁。
   来源：[src/data/library-finals.content.json:112](../src/data/library-finals.content.json#L112)
140. 索书号爱好者
   来源：[src/data/library-finals.content.json:116](../src/data/library-finals.content.json#L116)
141. 线索
   来源：[src/data/library-finals.content.json:117](../src/data/library-finals.content.json#L117)；[src/data/library-finals.content.json:133](../src/data/library-finals.content.json#L133)
142. 回复 4 楼，入口记录只能证明到场
   来源：[src/data/library-finals.content.json:118](../src/data/library-finals.content.json#L118)
143. 旧版规则不在网上，在图书馆书架背面。搜‘三分钟离座法’。
   来源：[src/data/library-finals.content.json:119](../src/data/library-finals.content.json#L119)
144. 纸面支援专员
   来源：[src/data/library-finals.content.json:123](../src/data/library-finals.content.json#L123)
145. 路过
   来源：[src/data/library-finals.content.json:124](../src/data/library-finals.content.json#L124)
146. bd 就是帮顶。点一条数字回复的 bd，右侧数字会写进热度口令。
   来源：[src/data/library-finals.content.json:125](../src/data/library-finals.content.json#L125)
147. bd
   来源：[src/data/library-finals.content.json:127](../src/data/library-finals.content.json#L127)
148. 热度维护员
   来源：[src/data/library-finals.content.json:132](../src/data/library-finals.content.json#L132)
149. 证据齐后，按上传栏从上到下选择四条数字回复，组成四位口令。
   来源：[src/data/library-finals.content.json:134](../src/data/library-finals.content.json#L134)
150. 楼主编辑
   来源：[src/data/library-finals.content.json:139](../src/data/library-finals.content.json#L139)
151. 帖子进十大第一后，图书馆 App 会开放 022 恢复申请。旧申请统一挂在公示编号 47。
   来源：[src/data/library-finals.content.json:140](../src/data/library-finals.content.json#L140)
152. 前排先占楼
   来源：[src/data/library-finals.content.json:144](../src/data/library-finals.content.json#L144)
153. ac01，座位没占到，楼层总得先占一个。
   来源：[src/data/library-finals.content.json:144](../src/data/library-finals.content.json#L144)
154. 三分钟后再来
   来源：[src/data/library-finals.content.json:145](../src/data/library-finals.content.json#L145)
155. ac01。三分钟后回来看看这条回复有没有被别人预约。
   来源：[src/data/library-finals.content.json:145](../src/data/library-finals.content.json#L145)
156. 空气座位经销商
   来源：[src/data/library-finals.content.json:146](../src/data/library-finals.content.json#L146)
157. 前排出售空气座位，坐下即视为离开。ac01
   来源：[src/data/library-finals.content.json:146](../src/data/library-finals.content.json#L146)
158. 022 的书包今天也全勤，我今天也……算了。ac01
   来源：[src/data/library-finals.content.json:147](../src/data/library-finals.content.json#L147)
159. 022考勤员
   来源：[src/data/library-finals.content.json:147](../src/data/library-finals.content.json#L147)
160. 公示编号 47，运动次数 47，建议书包报名体艺。ac01
   来源：[src/data/library-finals.content.json:148](../src/data/library-finals.content.json#L148)
161. 体艺凑数办
   来源：[src/data/library-finals.content.json:148](../src/data/library-finals.content.json#L148)
162. 二南窗边位
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
163. 期末周返场员
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
164. 续杯失败者
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
165. 自习室回声
   来源：[src/data/library-finals.content.json:151](../src/data/library-finals.content.json#L151)
166. 先等后续。我刚从 022 旁边经过，书包还在，座位一直没人。
   来源：[src/data/library-finals.content.json:153](../src/data/library-finals.content.json#L153)
167. 我去接杯水再回来，座位就换人了。三分钟从什么时候开始算？
   来源：[src/data/library-finals.content.json:154](../src/data/library-finals.content.json#L154)
168. 今晚九点后我还见过这个书包，主人没有出现。
   来源：[src/data/library-finals.content.json:155](../src/data/library-finals.content.json#L155)
169. 规则写三分钟，就该把起算时间写清楚。
   来源：[src/data/library-finals.content.json:156](../src/data/library-finals.content.json#L156)
170. 人回不回来先不说，至少系统得给一个能核对的时间。
   来源：[src/data/library-finals.content.json:157](../src/data/library-finals.content.json#L157)
171. 下次给书包单独办张入馆卡，记录可能更完整。
   来源：[src/data/library-finals.content.json:158](../src/data/library-finals.content.json#L158)
172. 先收藏。等有人把“本人”和“物品”分开说清楚。
   来源：[src/data/library-finals.content.json:159](../src/data/library-finals.content.json#L159)
173. 我想看结论。现在能确认的是，书包没离开，座位也没空。
   来源：[src/data/library-finals.content.json:160](../src/data/library-finals.content.json#L160)
174. 这条回复先留着。等 022 空出来，我再坐。
   来源：[src/data/library-finals.content.json:161](../src/data/library-finals.content.json#L161)
175. 请书包主人自己来领取占座记录。
   来源：[src/data/library-finals.content.json:162](../src/data/library-finals.content.json#L162)
176. 我也遇到过。人还在路上，座位已经换了使用者。
   来源：[src/data/library-finals.content.json:163](../src/data/library-finals.content.json#L163)
177. 规则写得完整，核对时间那一项却没有写。
   来源：[src/data/library-finals.content.json:164](../src/data/library-finals.content.json#L164)
178. 755 号书架背面
   来源：[src/data/library-finals.content.json:168](../src/data/library-finals.content.json#L168)
179. 旧版离座规则
   来源：[src/data/library-finals.content.json:168](../src/data/library-finals.content.json#L168)
180. 书包非本人证明
   来源：[src/data/library-finals.content.json:169](../src/data/library-finals.content.json#L169)
181. 物品身份盖章机
   来源：[src/data/library-finals.content.json:169](../src/data/library-finals.content.json#L169)
182. 022 桌下夹缝
   来源：[src/data/library-finals.content.json:170](../src/data/library-finals.content.json#L170)
183. 022 座位小票
   来源：[src/data/library-finals.content.json:170](../src/data/library-finals.content.json#L170)
184. 本人来过证明
   来源：[src/data/library-finals.content.json:171](../src/data/library-finals.content.json#L171)
185. 浙大体艺补录
   来源：[src/data/library-finals.content.json:171](../src/data/library-finals.content.json#L171)
186. BD 四位热度口令
   来源：[src/data/library-finals.content.json:174](../src/data/library-finals.content.json#L174)
187. bd = 帮顶。点击数字回复中的 bd，会把该数字按顺序写入口令。
   来源：[src/data/library-finals.content.json:175](../src/data/library-finals.content.json#L175)
188. 按上方四项已上传证据从上到下，各选择一条对应的数字回复。
   来源：[src/data/library-finals.content.json:176](../src/data/library-finals.content.json#L176)
189. 旧版规则
   来源：[src/data/library-finals.content.json:178](../src/data/library-finals.content.json#L178)
190. 数证明要求
   来源：[src/data/library-finals.content.json:178](../src/data/library-finals.content.json#L178)
191. 非本人证明
   来源：[src/data/library-finals.content.json:179](../src/data/library-finals.content.json#L179)
192. 数身份通过项
   来源：[src/data/library-finals.content.json:179](../src/data/library-finals.content.json#L179)
193. 022 小票
   来源：[src/data/library-finals.content.json:180](../src/data/library-finals.content.json#L180)
194. 取座位号末位
   来源：[src/data/library-finals.content.json:180](../src/data/library-finals.content.json#L180)
195. 到馆证明
   来源：[src/data/library-finals.content.json:181](../src/data/library-finals.content.json#L181)
196. 取到座耗时
   来源：[src/data/library-finals.content.json:181](../src/data/library-finals.content.json#L181)
197. 公示编号 47 的十位是 4。这个数字属于公示编号。
   来源：[src/data/library-finals.content.json:184](../src/data/library-finals.content.json#L184)
198. 公示号拆分员
   来源：[src/data/library-finals.content.json:184](../src/data/library-finals.content.json#L184)
199. 规则条目统计员
   来源：[src/data/library-finals.content.json:185](../src/data/library-finals.content.json#L185)
200. 旧规列出到馆、座位、占用物身份三类证明要求。
   来源：[src/data/library-finals.content.json:185](../src/data/library-finals.content.json#L185)
201. 目标排名是 01，我先记录末位 1。
   来源：[src/data/library-finals.content.json:186](../src/data/library-finals.content.json#L186)
202. 十大排名观察员
   来源：[src/data/library-finals.content.json:186](../src/data/library-finals.content.json#L186)
203. 盖章机值班员
   来源：[src/data/library-finals.content.json:187](../src/data/library-finals.content.json#L187)
204. 书包的姓名、学号、人格均未通过，身份有效项为 0。
   来源：[src/data/library-finals.content.json:187](../src/data/library-finals.content.json#L187)
205. 索书号 755 的末位是 5。这个数字属于馆藏线索。
   来源：[src/data/library-finals.content.json:188](../src/data/library-finals.content.json#L188)
206. 索书号末位员
   来源：[src/data/library-finals.content.json:188](../src/data/library-finals.content.json#L188)
207. 022 票据核对员
   来源：[src/data/library-finals.content.json:189](../src/data/library-finals.content.json#L189)
208. 座位号 022 取末位，票据对应数字为 2。
   来源：[src/data/library-finals.content.json:189](../src/data/library-finals.content.json#L189)
209. 关键回复计数员
   来源：[src/data/library-finals.content.json:190](../src/data/library-finals.content.json#L190)
210. 楼主编辑前共有六条固定剧情回复，我记录数字 6。
   来源：[src/data/library-finals.content.json:190](../src/data/library-finals.content.json#L190)
211. 07:55 入馆，08:02 到达 022，到座耗时为 7 分钟。
   来源：[src/data/library-finals.content.json:191](../src/data/library-finals.content.json#L191)
212. 门禁时差计算员
   来源：[src/data/library-finals.content.json:191](../src/data/library-finals.content.json#L191)
213. 三分钟离座法
   来源：[src/data/library-finals.content.json:196](../src/data/library-finals.content.json#L196)；[src/data/library-finals.puzzle.json:5](../src/data/library-finals.puzzle.json#L5)
214. 三分钟离座法及其例外
   来源：[src/data/library-finals.content.json:200](../src/data/library-finals.content.json#L200)
215. 馆内秩序编写组
   来源：[src/data/library-finals.content.json:201](../src/data/library-finals.content.json#L201)
216. 馆藏内部资料
   来源：[src/data/library-finals.content.json:204](../src/data/library-finals.content.json#L204)
217. 基础馆二楼南区 755 号书架背面
   来源：[src/data/library-finals.content.json:205](../src/data/library-finals.content.json#L205)
218. 本书不可借阅，因为借走过一次后规则失效了三天。
   来源：[src/data/library-finals.content.json:206](../src/data/library-finals.content.json#L206)
219. 三分钟离席法与若干例外
   来源：[src/data/library-finals.content.json:211](../src/data/library-finals.content.json#L211)
220. 间歇研究室
   来源：[src/data/library-finals.content.json:212](../src/data/library-finals.content.json#L212)
221. 自习室出版社
   来源：[src/data/library-finals.content.json:215](../src/data/library-finals.content.json#L215)
222. 基础馆四楼 B 区
   来源：[src/data/library-finals.content.json:216](../src/data/library-finals.content.json#L216)
223. 研究心理边界，不包含座位恢复条款。
   来源：[src/data/library-finals.content.json:217](../src/data/library-finals.content.json#L217)
224. 三分钟暂离法及其应用
   来源：[src/data/library-finals.content.json:222](../src/data/library-finals.content.json#L222)
225. 短时休息组
   来源：[src/data/library-finals.content.json:223](../src/data/library-finals.content.json#L223)
226. 效率实验社
   来源：[src/data/library-finals.content.json:226](../src/data/library-finals.content.json#L226)
227. 基础馆三楼 G 区
   来源：[src/data/library-finals.content.json:227](../src/data/library-finals.content.json#L227)
228. 暂离计时器实践手册，没有 022 相关附件。
   来源：[src/data/library-finals.content.json:228](../src/data/library-finals.content.json#L228)
229. 三分钟起身法与边界情况
   来源：[src/data/library-finals.content.json:233](../src/data/library-finals.content.json#L233)
230. 边界观察组
   来源：[src/data/library-finals.content.json:234](../src/data/library-finals.content.json#L234)
231. 清醒文库
   来源：[src/data/library-finals.content.json:237](../src/data/library-finals.content.json#L237)
232. 基础馆一楼 C 区
   来源：[src/data/library-finals.content.json:238](../src/data/library-finals.content.json#L238)
233. 讨论起身后的边界，不提供占座处理权限。
   来源：[src/data/library-finals.content.json:239](../src/data/library-finals.content.json#L239)
234. 三分钟空座法及其解释
   来源：[src/data/library-finals.content.json:244](../src/data/library-finals.content.json#L244)
235. 空位说明组
   来源：[src/data/library-finals.content.json:245](../src/data/library-finals.content.json#L245)
236. 静坐资料室
   来源：[src/data/library-finals.content.json:248](../src/data/library-finals.content.json#L248)
237. 基础馆五楼 G 区
   来源：[src/data/library-finals.content.json:249](../src/data/library-finals.content.json#L249)
238. 解释空座现象，不处理有书包的座位。
   来源：[src/data/library-finals.content.json:250](../src/data/library-finals.content.json#L250)
239. 对象类型：书包；状态：长期占座；本人属性：不成立
   来源：[src/data/library-finals.content.json:257](../src/data/library-finals.content.json#L257)
240. 本人来过证明补录单
   来源：[src/data/library-finals.content.json:260](../src/data/library-finals.content.json#L260)
241. 寝室
   来源：[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
242. 书架背面
   来源：[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
243. 图书馆入口
   来源：[src/data/library-finals.content.json:261](../src/data/library-finals.content.json#L261)
244. 022
   来源：[src/data/library-finals.content.json:265](../src/data/library-finals.content.json#L265)；[src/data/library-finals.content.json:268](../src/data/library-finals.content.json#L268)；[src/data/library-finals.content.json:270](../src/data/library-finals.content.json#L270)；[src/data/library-finals.content.json:272](../src/data/library-finals.content.json#L272)；[src/data/library-finals.content.json:273](../src/data/library-finals.content.json#L273)；[src/data/library-finals.content.json:275](../src/data/library-finals.content.json#L275)；[src/data/library-finals.content.json:278](../src/data/library-finals.content.json#L278)；[src/data/library-finals.content.json:280](../src/data/library-finals.content.json#L280)
245. 你终于坐下了。
   来源：[src/data/library-finals.content.json:265](../src/data/library-finals.content.json#L265)
246. 你就是系统的朋友？
   来源：[src/data/library-finals.content.json:266](../src/data/library-finals.content.json#L266)
247. 她以前不在座位上。
   来源：[src/data/library-finals.content.json:267](../src/data/library-finals.content.json#L267)
248. 你以前也不在红圈里。
   来源：[src/data/library-finals.content.json:268](../src/data/library-finals.content.json#L268)
249. 先查签到记录。能修改吗？
   来源：[src/data/library-finals.content.json:269](../src/data/library-finals.content.json#L269)
250. 我先查。
   来源：[src/data/library-finals.content.json:270](../src/data/library-finals.content.json#L270)
251. 可以改吗？
   来源：[src/data/library-finals.content.json:271](../src/data/library-finals.content.json#L271)
252. 查完了。签到记录离开了原页面。
   来源：[src/data/library-finals.content.json:272](../src/data/library-finals.content.json#L272)
253. 它夹在一张纸条里，记录停在 07:55。
   来源：[src/data/library-finals.content.json:273](../src/data/library-finals.content.json#L273)
254. 纸条往哪去了？
   来源：[src/data/library-finals.content.json:274](../src/data/library-finals.content.json#L274)
255. 它不在浅色操作能看见的位置。
   来源：[src/data/library-finals.content.json:275](../src/data/library-finals.content.json#L275)
256. 什么意思？
   来源：[src/data/library-finals.content.json:276](../src/data/library-finals.content.json#L276)
257. 说明白一点。
   来源：[src/data/library-finals.content.json:277](../src/data/library-finals.content.json#L277)
258. 切到深色观察，能看见纸条留下的痕迹。
   来源：[src/data/library-finals.content.json:278](../src/data/library-finals.content.json#L278)
259. 这就是暗色模式？
   来源：[src/data/library-finals.content.json:279](../src/data/library-finals.content.json#L279)
260. 这是它在系统里的名称。
   来源：[src/data/library-finals.content.json:280](../src/data/library-finals.content.json#L280)
261. 先追痕迹，别让纸条离开视野。
   来源：[src/data/library-finals.content.json:281](../src/data/library-finals.content.json#L281)
262. 本人马上回来。
   来源：[src/data/library-finals.content.json:282](../src/data/library-finals.content.json#L282)
263. 纸条
   来源：[src/data/library-finals.content.json:282](../src/data/library-finals.content.json#L282)；[src/scenes/rpg/LibraryInteriorScene.ts:2353](../src/scenes/rpg/LibraryInteriorScene.ts#L2353)
264. 它会说话了？！
   来源：[src/data/library-finals.content.json:283](../src/data/library-finals.content.json#L283)
265. 它把原来的话留在纸条上了。
   来源：[src/data/library-finals.content.json:284](../src/data/library-finals.content.json#L284)
266. 追到东区大食堂
   来源：[src/modules/LibraryFinalsController.ts:734](../src/modules/LibraryFinalsController.ts#L734)
267. 余额没有向任何方向移动。
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:31](../src/scenes/phone/P04_CampusCard/index.tsx#L31)
268. system
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:31](../src/scenes/phone/P04_CampusCard/index.tsx#L31)；[src/scenes/phone/P04_CampusCard/index.tsx:35](../src/scenes/phone/P04_CampusCard/index.tsx#L35)；[src/scenes/phone/P15_Zjuding/index.tsx:883](../src/scenes/phone/P15_Zjuding/index.tsx#L883)；[src/scenes/phone/P15_Zjuding/index.tsx:896](../src/scenes/phone/P15_Zjuding/index.tsx#L896)；[src/scenes/phone/P15_Zjuding/index.tsx:904](../src/scenes/phone/P15_Zjuding/index.tsx#L904)；[src/scenes/phone/P15_Zjuding/index.tsx:968](../src/scenes/phone/P15_Zjuding/index.tsx#L968)；[src/scenes/phone/P15_Zjuding/index.tsx:984](../src/scenes/phone/P15_Zjuding/index.tsx#L984)；[src/scenes/phone/P15_Zjuding/index.tsx:987](../src/scenes/phone/P15_Zjuding/index.tsx#L987)；[src/scenes/phone/P15_Zjuding/index.tsx:992](../src/scenes/phone/P15_Zjuding/index.tsx#L992)；[src/scenes/phone/P15_Zjuding/index.tsx:996](../src/scenes/phone/P15_Zjuding/index.tsx#L996)；[src/scenes/rpg/LibraryInteriorScene.ts:363](../src/scenes/rpg/LibraryInteriorScene.ts#L363)；[src/scenes/rpg/LibraryInteriorScene.ts:386](../src/scenes/rpg/LibraryInteriorScene.ts#L386)；[src/scenes/rpg/LibraryInteriorScene.ts:396](../src/scenes/rpg/LibraryInteriorScene.ts#L396)；[src/scenes/rpg/LibraryInteriorScene.ts:547](../src/scenes/rpg/LibraryInteriorScene.ts#L547)；[src/scenes/rpg/LibraryInteriorScene.ts:2157](../src/scenes/rpg/LibraryInteriorScene.ts#L2157)
269. 这个箭头还不能改动余额。
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:35](../src/scenes/phone/P04_CampusCard/index.tsx#L35)
270. 校园卡
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:54](../src/scenes/phone/P04_CampusCard/index.tsx#L54)
271. 扫一扫
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:58](../src/scenes/phone/P04_CampusCard/index.tsx#L58)
272. 付款码
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:62](../src/scenes/phone/P04_CampusCard/index.tsx#L62)；[src/scenes/phone/P04_CampusCard/index.tsx:125](../src/scenes/phone/P04_CampusCard/index.tsx#L125)
273. 卡片充值
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:66](../src/scenes/phone/P04_CampusCard/index.tsx#L66)；[src/scenes/phone/P04_CampusCard/index.tsx:129](../src/scenes/phone/P04_CampusCard/index.tsx#L129)
274. 卡包
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:70](../src/scenes/phone/P04_CampusCard/index.tsx#L70)
275. 浙江大学
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:77](../src/scenes/phone/P04_CampusCard/index.tsx#L77)
276. ZHEJIANG UNIVERSITY
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:78](../src/scenes/phone/P04_CampusCard/index.tsx#L78)
277. 学 号：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:88](../src/scenes/phone/P04_CampusCard/index.tsx#L88)
278. 学号未读取
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:89](../src/scenes/phone/P04_CampusCard/index.tsx#L89)
279. 姓 名：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:92](../src/scenes/phone/P04_CampusCard/index.tsx#L92)
280. 姓名未读取
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:93](../src/scenes/phone/P04_CampusCard/index.tsx#L93)
281. 卡账户：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:96](../src/scenes/phone/P04_CampusCard/index.tsx#L96)
282. 校园卡余额：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:100](../src/scenes/phone/P04_CampusCard/index.tsx#L100)
283. 我的零钱：
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:113](../src/scenes/phone/P04_CampusCard/index.tsx#L113)
284. 账单
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:121](../src/scenes/phone/P04_CampusCard/index.tsx#L121)
285. 挂失·解挂
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:133](../src/scenes/phone/P04_CampusCard/index.tsx#L133)
286. ▎校园新闻
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:139](../src/scenes/phone/P04_CampusCard/index.tsx#L139)
287. 查看全部 ›
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:140](../src/scenes/phone/P04_CampusCard/index.tsx#L140)
288. 浙江大学图书馆暑期开放安排通知！
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:142](../src/scenes/phone/P04_CampusCard/index.tsx#L142)
289. 2026 年暑期图书馆开放安排
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:143](../src/scenes/phone/P04_CampusCard/index.tsx#L143)
290. 1天前 · 校园资讯中心
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:144](../src/scenes/phone/P04_CampusCard/index.tsx#L144)
291. 返回浙大钉
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:147](../src/scenes/phone/P04_CampusCard/index.tsx#L147)
292. 首页
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:150](../src/scenes/phone/P04_CampusCard/index.tsx#L150)
293. 资讯
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:151](../src/scenes/phone/P04_CampusCard/index.tsx#L151)
294. 校园码
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:152](../src/scenes/phone/P04_CampusCard/index.tsx#L152)
295. 应用
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:153](../src/scenes/phone/P04_CampusCard/index.tsx#L153)
296. 我的
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:154](../src/scenes/phone/P04_CampusCard/index.tsx#L154)
297. 校园地图将在第二章开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:883](../src/scenes/phone/P15_Zjuding/index.tsx#L883)
298. 校园地图还没有响应你的进入请求。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:896](../src/scenes/phone/P15_Zjuding/index.tsx#L896)
299. 图书馆现场还没有开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:904](../src/scenes/phone/P15_Zjuding/index.tsx#L904)
300. 任务更新：在浙大钉预约图书馆座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:959](../src/scenes/phone/P15_Zjuding/index.tsx#L959)
301. task
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:959](../src/scenes/phone/P15_Zjuding/index.tsx#L959)；[src/scenes/phone/P15_Zjuding/index.tsx:978](../src/scenes/phone/P15_Zjuding/index.tsx#L978)
302. 电子校园卡将在第二章寝室任务中取得。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:968](../src/scenes/phone/P15_Zjuding/index.tsx#L968)
303. 黄页联络成功
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:978](../src/scenes/phone/P15_Zjuding/index.tsx#L978)
304. 您拨打的电话正在通话中，请稍后再拨。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:984](../src/scenes/phone/P15_Zjuding/index.tsx#L984)
305. 姓名或学号不匹配。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:987](../src/scenes/phone/P15_Zjuding/index.tsx#L987)
306. 读卡器正在逐字识别。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:992](../src/scenes/phone/P15_Zjuding/index.tsx#L992)
307. 姓名和学号已经读入。拨出这通电话。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:996](../src/scenes/phone/P15_Zjuding/index.tsx#L996)
308. 离开图书馆
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:150](../src/scenes/rpg/LibraryInteriorModel.ts#L150)
309. 查看入馆记录
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:159](../src/scenes/rpg/LibraryInteriorModel.ts#L159)
310. 前台工作人员
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:173](../src/scenes/rpg/LibraryInteriorModel.ts#L173)
311. 馆藏检索终端
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:185](../src/scenes/rpg/LibraryInteriorModel.ts#L185)
312. 自助打印机
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:195](../src/scenes/rpg/LibraryInteriorModel.ts#L195)
313. 文学书架夹层
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:206](../src/scenes/rpg/LibraryInteriorModel.ts#L206)
314. 检查占座书包
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:219](../src/scenes/rpg/LibraryInteriorModel.ts#L219)；[src/scenes/rpg/LibraryInteriorScene.ts:598](../src/scenes/rpg/LibraryInteriorScene.ts#L598)
315. 桌面夹缝
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:234](../src/scenes/rpg/LibraryInteriorModel.ts#L234)
316. 拿起占座纸条
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:246](../src/scenes/rpg/LibraryInteriorModel.ts#L246)
317. 坐到 022
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:257](../src/scenes/rpg/LibraryInteriorModel.ts#L257)
318. 索书号 755
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:71](../src/scenes/rpg/LibraryInteriorScene.ts#L71)
319. 物品识别报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:72](../src/scenes/rpg/LibraryInteriorScene.ts#L72)
320. 右移箭头
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:73](../src/scenes/rpg/LibraryInteriorScene.ts#L73)
321. 离座清退 PASS
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:74](../src/scenes/rpg/LibraryInteriorScene.ts#L74)
322. 前台：请出示物品识别报告。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:78](../src/scenes/rpg/LibraryInteriorScene.ts#L78)
323. 玩家：我用肉眼看不行吗？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:79](../src/scenes/rpg/LibraryInteriorScene.ts#L79)
324. 前台：肉眼不是本部门认可设备。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:80](../src/scenes/rpg/LibraryInteriorScene.ts#L80)
325. 系统：你看，眼睛又输了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:81](../src/scenes/rpg/LibraryInteriorScene.ts#L81)
326. 记录已保存
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:370](../src/scenes/rpg/LibraryInteriorScene.ts#L370)
327. success
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:370](../src/scenes/rpg/LibraryInteriorScene.ts#L370)；[src/scenes/rpg/LibraryInteriorScene.ts:391](../src/scenes/rpg/LibraryInteriorScene.ts#L391)；[src/scenes/rpg/LibraryInteriorScene.ts:906](../src/scenes/rpg/LibraryInteriorScene.ts#L906)；[src/scenes/rpg/LibraryInteriorScene.ts:946](../src/scenes/rpg/LibraryInteriorScene.ts#L946)；[src/scenes/rpg/LibraryInteriorScene.ts:1190](../src/scenes/rpg/LibraryInteriorScene.ts#L1190)；[src/scenes/rpg/LibraryInteriorScene.ts:1214](../src/scenes/rpg/LibraryInteriorScene.ts#L1214)；[src/scenes/rpg/LibraryInteriorScene.ts:1307](../src/scenes/rpg/LibraryInteriorScene.ts#L1307)
328. 占座纸条已收入道具栏
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:378](../src/scenes/rpg/LibraryInteriorScene.ts#L378)
329. 旧规则已确认：三项证明要求已核对，可继续补齐未完成材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:386](../src/scenes/rpg/LibraryInteriorScene.ts#L386)
330. 图书馆馆藏检索功能已解锁。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:391](../src/scenes/rpg/LibraryInteriorScene.ts#L391)
331. 前台接过报告，正在核对照片、座位号和物品身份。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:396](../src/scenes/rpg/LibraryInteriorScene.ts#L396)
332. 任务更新：追上逃跑的记录纸条
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:421](../src/scenes/rpg/LibraryInteriorScene.ts#L421)
333. chapter
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:421](../src/scenes/rpg/LibraryInteriorScene.ts#L421)
334. broadcast
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:425](../src/scenes/rpg/LibraryInteriorScene.ts#L425)
335. no\_target
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:441](../src/scenes/rpg/LibraryInteriorScene.ts#L441)
336. missed\_target
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:444](../src/scenes/rpg/LibraryInteriorScene.ts#L444)
337. 把道具拖到画面中对应的真实物体。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:445](../src/scenes/rpg/LibraryInteriorScene.ts#L445)
338. wrong\_item
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:454](../src/scenes/rpg/LibraryInteriorScene.ts#L454)；[src/scenes/rpg/LibraryInteriorScene.ts:459](../src/scenes/rpg/LibraryInteriorScene.ts#L459)
339. too\_far
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:468](../src/scenes/rpg/LibraryInteriorScene.ts#L468)；[src/scenes/rpg/LibraryInteriorScene.ts:472](../src/scenes/rpg/LibraryInteriorScene.ts#L472)
340. unavailable
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:487](../src/scenes/rpg/LibraryInteriorScene.ts#L487)
341. locked
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:490](../src/scenes/rpg/LibraryInteriorScene.ts#L490)
342. 对应道具
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:588](../src/scenes/rpg/LibraryInteriorScene.ts#L588)
343. 拖入「{{itemLabel}}」 {{target.label}}
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:589](../src/scenes/rpg/LibraryInteriorScene.ts#L589)
344. 前台正在核验并盖章
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:593](../src/scenes/rpg/LibraryInteriorScene.ts#L593)
345. 询问前台工作人员
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:595](../src/scenes/rpg/LibraryInteriorScene.ts#L595)
346. 继续与 022 对话
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:600](../src/scenes/rpg/LibraryInteriorScene.ts#L600)
347. 前台正在整理失物记录，目前没有需要办理的材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:647](../src/scenes/rpg/LibraryInteriorScene.ts#L647)
348. 三项证明已齐，上传给大家看看。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:649](../src/scenes/rpg/LibraryInteriorScene.ts#L649)
349. 前台：先在照片页面生成物品识别报告，再拿来核验。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:651](../src/scenes/rpg/LibraryInteriorScene.ts#L651)
350. 前台：把物品识别报告递到柜台上，我核验后盖章。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:652](../src/scenes/rpg/LibraryInteriorScene.ts#L652)
351. 前台正在核对报告，请等她完成盖章。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:653](../src/scenes/rpg/LibraryInteriorScene.ts#L653)
352. 前台：非本人证明已经盖好，继续补齐另外两项材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:654](../src/scenes/rpg/LibraryInteriorScene.ts#L654)
353. 馆藏检索已同步到图书馆，可按帖子中的题名继续查找。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:659](../src/scenes/rpg/LibraryInteriorScene.ts#L659)
354. 终端可以检索题名、作者和索书号，当前没有调查关键词。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:660](../src/scenes/rpg/LibraryInteriorScene.ts#L660)
355. 书架：I247.55 区域。它看起来不是书架，是一串密码伪装成家具。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:664](../src/scenes/rpg/LibraryInteriorScene.ts#L664)
356. 书架：I247.?? 区域。看不清楚，有没有具体索书号？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:665](../src/scenes/rpg/LibraryInteriorScene.ts#L665)
357. 恢复申请已经通过，PASS 可对现场占用物生效。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:669](../src/scenes/rpg/LibraryInteriorScene.ts#L669)
358. 打印机显示缺纸；旁边的纸盒显示库存充足。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:677](../src/scenes/rpg/LibraryInteriorScene.ts#L677)
359. 夹缝里露出一角小票，手指无法直接取出。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:680](../src/scenes/rpg/LibraryInteriorScene.ts#L680)
360. 纸条引用了一段公开讨论，关键词仍可辨认。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:681](../src/scenes/rpg/LibraryInteriorScene.ts#L681)
361. 椅子仍被占用。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:682](../src/scenes/rpg/LibraryInteriorScene.ts#L682)
362. 座位已经空出，可以坐下确认会话。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:682](../src/scenes/rpg/LibraryInteriorScene.ts#L682)
363. 07:55
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:780](../src/scenes/rpg/LibraryInteriorScene.ts#L780)
364. 主馆入口
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:780](../src/scenes/rpg/LibraryInteriorScene.ts#L780)；[src/scenes/rpg/LibraryInteriorScene.ts:1685](../src/scenes/rpg/LibraryInteriorScene.ts#L1685)
365. 08:02
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:781](../src/scenes/rpg/LibraryInteriorScene.ts#L781)
366. 二楼南区 022
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:781](../src/scenes/rpg/LibraryInteriorScene.ts#L781)；[src/scenes/rpg/LibraryInteriorScene.ts:1704](../src/scenes/rpg/LibraryInteriorScene.ts#L1704)
367. 这个道具和目标的证据类型对不上。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:827](../src/scenes/rpg/LibraryInteriorScene.ts#L827)
368. 先走到{{targetLabel ? \`「${targetLabel}」\` : "目标"}}的可操作边缘，再使用道具。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:829](../src/scenes/rpg/LibraryInteriorScene.ts#L829)
369. 道具没有落在可交互目标上。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:831](../src/scenes/rpg/LibraryInteriorScene.ts#L831)
370. 条件还不完整，目标暂时不接受这个操作。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:832](../src/scenes/rpg/LibraryInteriorScene.ts#L832)
371. error
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:833](../src/scenes/rpg/LibraryInteriorScene.ts#L833)；[src/scenes/rpg/LibraryInteriorScene.ts:893](../src/scenes/rpg/LibraryInteriorScene.ts#L893)
372. 022 仍有微弱信号，信号源被书包压住了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:893](../src/scenes/rpg/LibraryInteriorScene.ts#L893)
373. 书架开始缓慢横移，后面的夹层逐渐露出一份旧黄纸。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:946](../src/scenes/rpg/LibraryInteriorScene.ts#L946)
374. 022 · 空闲
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1089](../src/scenes/rpg/LibraryInteriorScene.ts#L1089)
375. 022 · 占用
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1089](../src/scenes/rpg/LibraryInteriorScene.ts#L1089)；[src/scenes/rpg/LibraryInteriorScene.ts:2326](../src/scenes/rpg/LibraryInteriorScene.ts#L2326)
376. 前台盖章完成：书包不等于本人。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1190](../src/scenes/rpg/LibraryInteriorScene.ts#L1190)
377. 小票向“右”了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1214](../src/scenes/rpg/LibraryInteriorScene.ts#L1214)
378. 022 · 转移中
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1248](../src/scenes/rpg/LibraryInteriorScene.ts#L1248)
379. 书包：主人马上回来。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1250](../src/scenes/rpg/LibraryInteriorScene.ts#L1250)
380. 玩家：什么时候？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1251](../src/scenes/rpg/LibraryInteriorScene.ts#L1251)
381. 书包：三分钟。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1252](../src/scenes/rpg/LibraryInteriorScene.ts#L1252)
382. 系统：它三天前也是这么说的。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1253](../src/scenes/rpg/LibraryInteriorScene.ts#L1253)
383. 022 已恢复。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1307](../src/scenes/rpg/LibraryInteriorScene.ts#L1307)
384. 图书馆门禁 · 入馆记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1655](../src/scenes/rpg/LibraryInteriorScene.ts#L1655)
385. 入馆扫描
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1674](../src/scenes/rpg/LibraryInteriorScene.ts#L1674)
386. 到达记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1693](../src/scenes/rpg/LibraryInteriorScene.ts#L1693)
387. 到座耗时核对：08:02 − 07:55
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1716](../src/scenes/rpg/LibraryInteriorScene.ts#L1716)
388. 目标记录：二楼南区 022 · 会话未闭合
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1722](../src/scenes/rpg/LibraryInteriorScene.ts#L1722)
389. 记下记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1730](../src/scenes/rpg/LibraryInteriorScene.ts#L1730)；[src/scenes/rpg/LibraryInteriorScene.ts:1877](../src/scenes/rpg/LibraryInteriorScene.ts#L1877)
390. Enter / 空格 确认 · Esc 关闭
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1743](../src/scenes/rpg/LibraryInteriorScene.ts#L1743)
391. 入馆记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1813](../src/scenes/rpg/LibraryInteriorScene.ts#L1813)
392. 点击查看
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1819](../src/scenes/rpg/LibraryInteriorScene.ts#L1819)；[src/scenes/rpg/LibraryInteriorScene.ts:1934](../src/scenes/rpg/LibraryInteriorScene.ts#L1934)
393. 关闭记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1877](../src/scenes/rpg/LibraryInteriorScene.ts#L1877)
394. 已读取 · 点击复查
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1934](../src/scenes/rpg/LibraryInteriorScene.ts#L1934)
395. 基础图书馆 · 二层南区
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1943](../src/scenes/rpg/LibraryInteriorScene.ts#L1943)
396. 信息台 / 失物招领
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2035](../src/scenes/rpg/LibraryInteriorScene.ts#L2035)
397. 图
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2102](../src/scenes/rpg/LibraryInteriorScene.ts#L2102)
398. 物
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2102](../src/scenes/rpg/LibraryInteriorScene.ts#L2102)
399. 座
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2102](../src/scenes/rpg/LibraryInteriorScene.ts#L2102)
400. 非本人
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2126](../src/scenes/rpg/LibraryInteriorScene.ts#L2126)
401. 请靠近信息台柜台。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2157](../src/scenes/rpg/LibraryInteriorScene.ts#L2157)
402. 等待报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2176](../src/scenes/rpg/LibraryInteriorScene.ts#L2176)
403. 递交报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2177](../src/scenes/rpg/LibraryInteriorScene.ts#L2177)
404. 人工核验
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2178](../src/scenes/rpg/LibraryInteriorScene.ts#L2178)
405. 已盖章
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2179](../src/scenes/rpg/LibraryInteriorScene.ts#L2179)
406. 馆藏检索 / 打印
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2224](../src/scenes/rpg/LibraryInteriorScene.ts#L2224)
407. 文学 / 社科书架
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2241](../src/scenes/rpg/LibraryInteriorScene.ts#L2241)
408. 旧规
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2296](../src/scenes/rpg/LibraryInteriorScene.ts#L2296)
409. 二层南区 · 安静阅览
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2315](../src/scenes/rpg/LibraryInteriorScene.ts#L2315)

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
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:424](../src/components/ChapterThreeOpeningOverlay.tsx#L424)；[src/core/QuestModel.ts:755](../src/core/QuestModel.ts#L755)；[src/core/QuestModel.ts:781](../src/core/QuestModel.ts#L781)；[src/core/QuestModel.ts:783](../src/core/QuestModel.ts#L783)；[src/core/QuestModel.ts:785](../src/core/QuestModel.ts#L785)
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
   来源：[src/core/QuestModel.ts:383](../src/core/QuestModel.ts#L383)
35. 器材收齐后，去小码头找值班老师确认。
   来源：[src/core/QuestModel.ts:384](../src/core/QuestModel.ts#L384)
36. 再次尝试登船
   来源：[src/core/QuestModel.ts:388](../src/core/QuestModel.ts#L388)
37. 回到皮划艇旁。
   来源：[src/core/QuestModel.ts:389](../src/core/QuestModel.ts#L389)
38. 靠近食堂里的异常纸条
   来源：[src/core/QuestModel.ts:471](../src/core/QuestModel.ts#L471)
39. 纸条停在入口附近，靠近后会继续移动。
   来源：[src/core/QuestModel.ts:471](../src/core/QuestModel.ts#L471)
40. 先完成餐盘回收，取得后续行动需要的零钱和纸巾。
   来源：[src/core/QuestModel.ts:474](../src/core/QuestModel.ts#L474)
41. 与收餐口阿姨交谈
   来源：[src/core/QuestModel.ts:474](../src/core/QuestModel.ts#L474)；[src/scenes/rpg/CanteenInteriorScene.ts:973](../src/scenes/rpg/CanteenInteriorScene.ts#L973)
42. 找出并交回带污渍的餐盘（{{returnedTargetTrays}}/3）
   来源：[src/core/QuestModel.ts:479](../src/core/QuestModel.ts#L479)
43. 深色观察可辨认蓝光和油渍；浅色操作可直接拿起餐盘并交给收餐口阿姨。
   来源：[src/core/QuestModel.ts:480](../src/core/QuestModel.ts#L480)
44. 一次只能搬一个餐盘。
   来源：[src/core/QuestModel.ts:480](../src/core/QuestModel.ts#L480)
45. 查看第三列队伍和新品宣传板
   来源：[src/core/QuestModel.ts:485](../src/core/QuestModel.ts#L485)
46. 与排队学生交谈，确认怎样让第三列队伍移动。
   来源：[src/core/QuestModel.ts:485](../src/core/QuestModel.ts#L485)
47. 查看饮料货架的颜色顺序
   来源：[src/core/QuestModel.ts:488](../src/core/QuestModel.ts#L488)
48. 货架从左到右的颜色决定调配顺序。
   来源：[src/core/QuestModel.ts:488](../src/core/QuestModel.ts#L488)
49. 在校园地图核对地点交点
   来源：[src/core/QuestModel.ts:534](../src/core/QuestModel.ts#L534)
50. 三条地点记录已接入。
   来源：[src/core/QuestModel.ts:536](../src/core/QuestModel.ts#L536)
51. 打开浙大钉的校园地图，完成最后核对。
   来源：[src/core/QuestModel.ts:537](../src/core/QuestModel.ts#L537)
52. 从校园地图前往启真湖
   来源：[src/core/QuestModel.ts:552](../src/core/QuestModel.ts#L552)
53. 进入大地图后走到启真湖入口。
   来源：[src/core/QuestModel.ts:553](../src/core/QuestModel.ts#L553)
54. 手机地图已确认地点。
   来源：[src/core/QuestModel.ts:553](../src/core/QuestModel.ts#L553)
55. 启真湖追纸
   来源：[src/core/QuestModel.ts:558](../src/core/QuestModel.ts#L558)
56. 码头柜门
   来源：[src/core/QuestModel.ts:565](../src/core/QuestModel.ts#L565)
57. 钥匙与尼龙绳
   来源：[src/core/QuestModel.ts:566](../src/core/QuestModel.ts#L566)
58. 直河浮排
   来源：[src/core/QuestModel.ts:571](../src/core/QuestModel.ts#L571)
59. 破损网框
   来源：[src/core/QuestModel.ts:572](../src/core/QuestModel.ts#L572)；[src/data/chapter3-qizhen-fishing.charts.json:28](../src/data/chapter3-qizhen-fishing.charts.json#L28)；[src/scenes/rpg/QizhenLakeScene.ts:168](../src/scenes/rpg/QizhenLakeScene.ts#L168)
60. 天鹅围栏
   来源：[src/core/QuestModel.ts:577](../src/core/QuestModel.ts#L577)
61. 饲料与磁性扣
   来源：[src/core/QuestModel.ts:578](../src/core/QuestModel.ts#L578)
62. 去 CC98 接下学生剧现场帮抢委托
   来源：[src/core/QuestModel.ts:602](../src/core/QuestModel.ts#L602)
63. 手机 CC98 出现了一条学生剧临时退票求助帖。
   来源：[src/core/QuestModel.ts:604](../src/core/QuestModel.ts#L604)
64. 接单后再到剧院大厅确认取票时间。
   来源：[src/core/QuestModel.ts:605](../src/core/QuestModel.ts#L605)
65. 在剧院大厅确认 08:32 放票时间
   来源：[src/core/QuestModel.ts:614](../src/core/QuestModel.ts#L614)
66. 在深色观察中靠近取票机，读取屏幕残影。
   来源：[src/core/QuestModel.ts:616](../src/core/QuestModel.ts#L616)
67. 确认时间后回到手机 CC98 帖子参加第一波。
   来源：[src/core/QuestModel.ts:617](../src/core/QuestModel.ts#L617)
68. 在手机 CC98 票务页参加第一波放票
   来源：[src/core/QuestModel.ts:623](../src/core/QuestModel.ts#L623)
69. 打开学生剧现场帮抢帖，在票务卡中操作。
   来源：[src/core/QuestModel.ts:625](../src/core/QuestModel.ts#L625)
70. 可以直接抢第一波，也可以先打开控制中心切换到移动数据。
   来源：[src/core/QuestModel.ts:626](../src/core/QuestModel.ts#L626)
71. 在手机票务页参加第二波放票
   来源：[src/core/QuestModel.ts:635](../src/core/QuestModel.ts#L635)
72. 移动数据已经开启。
   来源：[src/core/QuestModel.ts:637](../src/core/QuestModel.ts#L637)
73. 回到 CC98 帮抢帖，等待倒计时结束后点击第二波。
   来源：[src/core/QuestModel.ts:638](../src/core/QuestModel.ts#L638)
74. 开启手机移动数据，等待第二波放票
   来源：[src/core/QuestModel.ts:645](../src/core/QuestModel.ts#L645)
75. 第一波已结束，系统提示响应速度过慢。
   来源：[src/core/QuestModel.ts:647](../src/core/QuestModel.ts#L647)
76. 在 CC98 票务卡中打开控制中心，切换为移动数据。
   来源：[src/core/QuestModel.ts:648](../src/core/QuestModel.ts#L648)
77. 把临时观演票交给检票闸机
   来源：[src/core/QuestModel.ts:657](../src/core/QuestModel.ts#L657)
78. 靠近闸机右侧的读票器。
   来源：[src/core/QuestModel.ts:659](../src/core/QuestModel.ts#L659)
79. 把道具栏里的临时观演票拖到读票器的发光框内。
   来源：[src/core/QuestModel.ts:660](../src/core/QuestModel.ts#L660)
80. 合成两张半票根
   来源：[src/core/QuestModel.ts:667](../src/core/QuestModel.ts#L667)
81. 在道具栏中将半张票根 A 与半张票根 B 组合。
   来源：[src/core/QuestModel.ts:668](../src/core/QuestModel.ts#L668)
82. 去剧院取票机打印半张票根 B
   来源：[src/core/QuestModel.ts:674](../src/core/QuestModel.ts#L674)
83. 手机抢票已经成功，订单取票码是 0832。
   来源：[src/core/QuestModel.ts:676](../src/core/QuestModel.ts#L676)
84. 在浅色操作中靠近取票机，输入取票码打印实体票根。
   来源：[src/core/QuestModel.ts:677](../src/core/QuestModel.ts#L677)
85. 从入口海报栏取得半张票根 A
   来源：[src/core/QuestModel.ts:684](../src/core/QuestModel.ts#L684)
86. 靠近大厅左侧的海报玻璃。
   来源：[src/core/QuestModel.ts:686](../src/core/QuestModel.ts#L686)
87. 把去油纸巾拖到海报玻璃的发光区域。
   来源：[src/core/QuestModel.ts:687](../src/core/QuestModel.ts#L687)
88. 确认两张半票根
   来源：[src/core/QuestModel.ts:693](../src/core/QuestModel.ts#L693)
89. 打开道具栏确认票根 A 与票根 B，再完成组合。
   来源：[src/core/QuestModel.ts:694](../src/core/QuestModel.ts#L694)
90. 追光第 {{Math.min(state.theaterHunt.spotlightRound + 1, 3)}} / 3 轮：观察轨迹，预置灯位并持续照射
   来源：[src/core/QuestModel.ts:727](../src/core/QuestModel.ts#L727)
91. 已完成 {{state.theaterHunt.spotlightRound}} / 3 轮，失败只重试当前轮。
   来源：[src/core/QuestModel.ts:729](../src/core/QuestModel.ts#L729)
92. 查看追光灯下的纸条
   来源：[src/core/QuestModel.ts:739](../src/core/QuestModel.ts#L739)
93. 剧院追纸
   来源：[src/core/QuestModel.ts:749](../src/core/QuestModel.ts#L749)
94. 沿校园地图中留下的脚印前往东区大食堂。
   来源：[src/core/QuestModel.ts:756](../src/core/QuestModel.ts#L756)；[src/core/QuestModel.ts:786](../src/core/QuestModel.ts#L786)
95. 追上逃跑的记录纸条
   来源：[src/data/chapter3-canteen.content.json:4](../src/data/chapter3-canteen.content.json#L4)
96. 纸条钻进了食堂。
   来源：[src/data/chapter3-canteen.content.json:6](../src/data/chapter3-canteen.content.json#L6)
97. 切到深色观察，沿着它留下的蓝色纸屑找路。
   来源：[src/data/chapter3-canteen.content.json:7](../src/data/chapter3-canteen.content.json#L7)
98. 痕迹在热气和收餐口附近断开。
   来源：[src/data/chapter3-canteen.content.json:8](../src/data/chapter3-canteen.content.json#L8)
99. 旁白：纸条钻进了食堂。
   来源：[src/data/chapter3-canteen.content.json:12](../src/data/chapter3-canteen.content.json#L12)
100. 系统：先别跟丢。
   来源：[src/data/chapter3-canteen.content.json:13](../src/data/chapter3-canteen.content.json#L13)
101. 任务：在食堂截住纸条
   来源：[src/data/chapter3-canteen.content.json:15](../src/data/chapter3-canteen.content.json#L15)
102. 深色观察能看见纸条碰过的餐盘和墙角。
   来源：[src/data/chapter3-canteen.content.json:17](../src/data/chapter3-canteen.content.json#L17)
103. 点餐后会拿到一张取餐小票。
   来源：[src/data/chapter3-canteen.content.json:18](../src/data/chapter3-canteen.content.json#L18)
104. 浅色操作可在 3 号窗口交取餐号；深色观察可补充查看窗口残影。
   来源：[src/data/chapter3-canteen.content.json:19](../src/data/chapter3-canteen.content.json#L19)
105. 阿姨：同学，桌上有三只脏盘，能不能帮我送回来？
   来源：[src/data/chapter3-canteen.content.json:23](../src/data/chapter3-canteen.content.json#L23)
106. 玩家：为什么？
   来源：[src/data/chapter3-canteen.content.json:24](../src/data/chapter3-canteen.content.json#L24)
107. 阿姨：我这儿的履带不停，你正好在旁边。
   来源：[src/data/chapter3-canteen.content.json:25](../src/data/chapter3-canteen.content.json#L25)
108. 任务：找出并交回三只带污渍的餐盘。
   来源：[src/data/chapter3-canteen.content.json:27](../src/data/chapter3-canteen.content.json#L27)
109. 当前为深色观察，只能辨认残影；拿取餐盘需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:28](../src/data/chapter3-canteen.content.json#L28)
110. 你手上已经有一个餐盘。先把它交给阿姨。
   来源：[src/data/chapter3-canteen.content.json:29](../src/data/chapter3-canteen.content.json#L29)
111. 阿姨：先拿一个盘子过来。
   来源：[src/data/chapter3-canteen.content.json:30](../src/data/chapter3-canteen.content.json#L30)
112. 已拿起餐盘。把它交给右侧收餐口的阿姨。
   来源：[src/data/chapter3-canteen.content.json:31](../src/data/chapter3-canteen.content.json#L31)
113. 阿姨：这只对，油渍和蓝光都在。
   来源：[src/data/chapter3-canteen.content.json:32](../src/data/chapter3-canteen.content.json#L32)
114. 阿姨：这只很干净，先放这儿。我还要找脏的。
   来源：[src/data/chapter3-canteen.content.json:33](../src/data/chapter3-canteen.content.json#L33)
115. 阿姨：三只都回来了。两块钱和这张纸巾，拿着。
   来源：[src/data/chapter3-canteen.content.json:35](../src/data/chapter3-canteen.content.json#L35)
116. 玩家：收盘子还有工资？
   来源：[src/data/chapter3-canteen.content.json:36](../src/data/chapter3-canteen.content.json#L36)
117. 阿姨：今天有。明天看排班。
   来源：[src/data/chapter3-canteen.content.json:37](../src/data/chapter3-canteen.content.json#L37)
118. 系统：现金 2.00 元已入账。
   来源：[src/data/chapter3-canteen.content.json:38](../src/data/chapter3-canteen.content.json#L38)
119. 阿姨：盘子放履带，别站上去。
   来源：[src/data/chapter3-canteen.content.json:40](../src/data/chapter3-canteen.content.json#L40)
120. 玩家：我能站到前面吗？
   来源：[src/data/chapter3-canteen.content.json:44](../src/data/chapter3-canteen.content.json#L44)
121. 同学：前面没空位。你先看看新品宣传。
   来源：[src/data/chapter3-canteen.content.json:45](../src/data/chapter3-canteen.content.json#L45)
122. 想拿哪一瓶？
   来源：[src/data/chapter3-canteen.content.json:47](../src/data/chapter3-canteen.content.json#L47)
123. 拿饮料
   来源：[src/data/chapter3-canteen.content.json:48](../src/data/chapter3-canteen.content.json#L48)
124. 算了
   来源：[src/data/chapter3-canteen.content.json:49](../src/data/chapter3-canteen.content.json#L49)
125. 这瓶已经在物品栏里，先拿去调配。
   来源：[src/data/chapter3-canteen.content.json:50](../src/data/chapter3-canteen.content.json#L50)
126. 获得气泡水（蓝色）。
   来源：[src/data/chapter3-canteen.content.json:52](../src/data/chapter3-canteen.content.json#L52)
127. 获得柠檬茶（白色）。
   来源：[src/data/chapter3-canteen.content.json:53](../src/data/chapter3-canteen.content.json#L53)
128. 获得黑咖啡（黑色）。
   来源：[src/data/chapter3-canteen.content.json:54](../src/data/chapter3-canteen.content.json#L54)
129. 货架标签被擦花了，先记住颜色顺序。
   来源：[src/data/chapter3-canteen.content.json:56](../src/data/chapter3-canteen.content.json#L56)
130. 货架颜色从左到右：黑色、蓝色、白色。
   来源：[src/data/chapter3-canteen.content.json:57](../src/data/chapter3-canteen.content.json#L57)
131. 请按货架提示调配今日新品。
   来源：[src/data/chapter3-canteen.content.json:58](../src/data/chapter3-canteen.content.json#L58)
132. 先看货架，颜色顺序决定配方。
   来源：[src/data/chapter3-canteen.content.json:59](../src/data/chapter3-canteen.content.json#L59)
133. 这瓶饮料不在道具栏里。
   来源：[src/data/chapter3-canteen.content.json:60](../src/data/chapter3-canteen.content.json#L60)
134. 饮料已经倒入大玻璃杯。
   来源：[src/data/chapter3-canteen.content.json:61](../src/data/chapter3-canteen.content.json#L61)
135. 配方不对，得到难喝饮料。
   来源：[src/data/chapter3-canteen.content.json:62](../src/data/chapter3-canteen.content.json#L62)
136. 配方正确，得到今日新品气泡水。
   来源：[src/data/chapter3-canteen.content.json:63](../src/data/chapter3-canteen.content.json#L63)
137. 玩家：这也能卖？
   来源：[src/data/chapter3-canteen.content.json:65](../src/data/chapter3-canteen.content.json#L65)
138. 系统：已经喝掉。队伍还在原地。
   来源：[src/data/chapter3-canteen.content.json:66](../src/data/chapter3-canteen.content.json#L66)
139. 把今日新品气泡水拖到第三窗口宣传板下方的空杯位。
   来源：[src/data/chapter3-canteen.content.json:68](../src/data/chapter3-canteen.content.json#L68)
140. 宣传板亮了，第三列队伍开始后退。
   来源：[src/data/chapter3-canteen.content.json:69](../src/data/chapter3-canteen.content.json#L69)
141. 今日新品气泡水
   来源：[src/data/chapter3-canteen.content.json:70](../src/data/chapter3-canteen.content.json#L70)
142. 试饮位已开启，请给我们的供货商一格脸面。
   来源：[src/data/chapter3-canteen.content.json:71](../src/data/chapter3-canteen.content.json#L71)
143. 玩家：他们怎么都退了？
   来源：[src/data/chapter3-canteen.content.json:73](../src/data/chapter3-canteen.content.json#L73)
144. 系统：前排看见宣传板，后面跟着挪。空位出来了。
   来源：[src/data/chapter3-canteen.content.json:74](../src/data/chapter3-canteen.content.json#L74)
145. 菜单看起来正常。纸包鸡排在第四项。
   来源：[src/data/chapter3-canteen.content.json:79](../src/data/chapter3-canteen.content.json#L79)
146. 暗色菜单换成了另一套字。
   来源：[src/data/chapter3-canteen.content.json:80](../src/data/chapter3-canteen.content.json#L80)
147. 暗色菜单已记录。浅色操作可在点餐机下单。
   来源：[src/data/chapter3-canteen.content.json:81](../src/data/chapter3-canteen.content.json#L81)
148. 当前为深色观察，只能查看菜单；下单需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:82](../src/data/chapter3-canteen.content.json#L82)
149. 先取完当前餐品，点餐机才接受下一单。
   来源：[src/data/chapter3-canteen.content.json:83](../src/data/chapter3-canteen.content.json#L83)
150. 包过
   来源：[src/data/chapter3-canteen.content.json:85](../src/data/chapter3-canteen.content.json#L85)
151. 包子
   来源：[src/data/chapter3-canteen.content.json:85](../src/data/chapter3-canteen.content.json#L85)
152. 豆过
   来源：[src/data/chapter3-canteen.content.json:86](../src/data/chapter3-canteen.content.json#L86)
153. 豆浆
   来源：[src/data/chapter3-canteen.content.json:86](../src/data/chapter3-canteen.content.json#L86)
154. 鸡蛋
   来源：[src/data/chapter3-canteen.content.json:87](../src/data/chapter3-canteen.content.json#L87)
155. 鸡过
   来源：[src/data/chapter3-canteen.content.json:87](../src/data/chapter3-canteen.content.json#L87)
156. 纸包过
   来源：[src/data/chapter3-canteen.content.json:88](../src/data/chapter3-canteen.content.json#L88)
157. 纸包鸡
   来源：[src/data/chapter3-canteen.content.json:88](../src/data/chapter3-canteen.content.json#L88)
158. 白过
   来源：[src/data/chapter3-canteen.content.json:89](../src/data/chapter3-canteen.content.json#L89)
159. 白粥
   来源：[src/data/chapter3-canteen.content.json:89](../src/data/chapter3-canteen.content.json#L89)
160. 点餐机：已下单
   来源：[src/data/chapter3-canteen.content.json:91](../src/data/chapter3-canteen.content.json#L91)；[src/data/chapter3-canteen.content.json:92](../src/data/chapter3-canteen.content.json#L92)
161. 系统：纸包鸡已经下单。拿好 0755 取餐号。
   来源：[src/data/chapter3-canteen.content.json:93](../src/data/chapter3-canteen.content.json#L93)
162. 先去点餐机拿 0755 取餐号。
   来源：[src/data/chapter3-canteen.content.json:96](../src/data/chapter3-canteen.content.json#L96)
163. 这是一张取纸用的小票，别把它丢掉。
   来源：[src/data/chapter3-canteen.content.json:97](../src/data/chapter3-canteen.content.json#L97)
164. 残影阿姨：……票……
   来源：[src/data/chapter3-canteen.content.json:98](../src/data/chapter3-canteen.content.json#L98)；[src/data/chapter3-canteen.content.json:99](../src/data/chapter3-canteen.content.json#L99)
165. 窗口没有人。去 3 号窗口找残影阿姨。
   来源：[src/data/chapter3-canteen.content.json:100](../src/data/chapter3-canteen.content.json#L100)
166. 深色观察只能查看窗口残影；交票需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:101](../src/data/chapter3-canteen.content.json#L101)
167. 这张票不归这个窗口。
   来源：[src/data/chapter3-canteen.content.json:102](../src/data/chapter3-canteen.content.json#L102)
168. 残影阿姨接过票。
   来源：[src/data/chapter3-canteen.content.json:103](../src/data/chapter3-canteen.content.json#L103)
169. 取餐系统：该餐品不在当前时间。
   来源：[src/data/chapter3-canteen.content.json:105](../src/data/chapter3-canteen.content.json#L105)
170. 玩家：那我点到哪一天了？
   来源：[src/data/chapter3-canteen.content.json:106](../src/data/chapter3-canteen.content.json#L106)
171. 系统：换一个窗口试试。
   来源：[src/data/chapter3-canteen.content.json:107](../src/data/chapter3-canteen.content.json#L107)
172. 获得比较真实的包子。
   来源：[src/data/chapter3-canteen.content.json:110](../src/data/chapter3-canteen.content.json#L110)
173. 获得没什么线索的豆浆。
   来源：[src/data/chapter3-canteen.content.json:111](../src/data/chapter3-canteen.content.json#L111)
174. 获得世界观边缘的鸡蛋。
   来源：[src/data/chapter3-canteen.content.json:112](../src/data/chapter3-canteen.content.json#L112)
175. 获得很热但很没用的白粥。
   来源：[src/data/chapter3-canteen.content.json:113](../src/data/chapter3-canteen.content.json#L113)
176. 1号窗口：0755号，请取粥。
   来源：[src/data/chapter3-canteen.content.json:116](../src/data/chapter3-canteen.content.json#L116)
177. 系统：领到一碗粥。纸条不在这里。
   来源：[src/data/chapter3-canteen.content.json:117](../src/data/chapter3-canteen.content.json#L117)
178. 2号窗口：0755号，请取蛋。
   来源：[src/data/chapter3-canteen.content.json:120](../src/data/chapter3-canteen.content.json#L120)
179. 玩家：纸条会下蛋吗？
   来源：[src/data/chapter3-canteen.content.json:121](../src/data/chapter3-canteen.content.json#L121)
180. 系统：先把这次取餐走完。
   来源：[src/data/chapter3-canteen.content.json:122](../src/data/chapter3-canteen.content.json#L122)
181. 3号窗口：0755 号，请取纸。纸条从蒸汽里弹出。
   来源：[src/data/chapter3-canteen.content.json:124](../src/data/chapter3-canteen.content.json#L124)
182. 3号窗口：0755 号，请取纸。
   来源：[src/data/chapter3-canteen.content.json:125](../src/data/chapter3-canteen.content.json#L125)
183. 餐盘车可以推，先把它放到纸条要去的出口。
   来源：[src/data/chapter3-canteen.content.json:128](../src/data/chapter3-canteen.content.json#L128)
184. 蓝色轨迹停在当前出口。浅色操作可以推动实体餐车。
   来源：[src/data/chapter3-canteen.content.json:129](../src/data/chapter3-canteen.content.json#L129)
185. 这辆餐车没有接上当前蓝色轨迹。
   来源：[src/data/chapter3-canteen.content.json:130](../src/data/chapter3-canteen.content.json#L130)
186. 深色观察只能查看轨迹；推动实体餐车需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:131](../src/data/chapter3-canteen.content.json#L131)
187. 纸条从另一个出口飞走了。
   来源：[src/data/chapter3-canteen.content.json:132](../src/data/chapter3-canteen.content.json#L132)
188. 纸条撞上餐盘车，掉下蓝色纸屑。
   来源：[src/data/chapter3-canteen.content.json:134](../src/data/chapter3-canteen.content.json#L134)
189. 它调头，下一次会换出口。
   来源：[src/data/chapter3-canteen.content.json:135](../src/data/chapter3-canteen.content.json#L135)
190. 阿姨：纸不能打包带走。
   来源：[src/data/chapter3-canteen.content.json:138](../src/data/chapter3-canteen.content.json#L138)
191. 玩家：它自己跑出去的。
   来源：[src/data/chapter3-canteen.content.json:139](../src/data/chapter3-canteen.content.json#L139)
192. 系统：出门，继续追。
   来源：[src/data/chapter3-canteen.content.json:140](../src/data/chapter3-canteen.content.json#L140)
193. 餐盘回收费 2.00 元
   来源：[src/data/chapter3-canteen.content.json:144](../src/data/chapter3-canteen.content.json#L144)
194. 收回三只目标餐盘得到的两元钱，可支付一次扫码骑车。
   来源：[src/data/chapter3-canteen.content.json:145](../src/data/chapter3-canteen.content.json#L145)
195. 油渍纸巾
   来源：[src/data/chapter3-canteen.content.json:146](../src/data/chapter3-canteen.content.json#L146)
196. 收餐口阿姨给的油渍纸巾，可擦掉车锁和海报玻璃上的反光。
   来源：[src/data/chapter3-canteen.content.json:147](../src/data/chapter3-canteen.content.json#L147)
197. 0755 取餐号
   来源：[src/data/chapter3-canteen.content.json:148](../src/data/chapter3-canteen.content.json#L148)
198. 点餐机打印的取餐小票。浅色操作时可交给对应取餐窗口。
   来源：[src/data/chapter3-canteen.content.json:149](../src/data/chapter3-canteen.content.json#L149)
199. 纸条沿主干道飞走。
   来源：[src/data/chapter3-canteen.content.json:153](../src/data/chapter3-canteen.content.json#L153)；[src/data/chapter3-story-lines.json:119](../src/data/chapter3-story-lines.json#L119)
200. 系统：共享单车在路边。用 2.00 元扫码。
   来源：[src/data/chapter3-canteen.content.json:154](../src/data/chapter3-canteen.content.json#L154)
201. 玩家：它已经跑远了。
   来源：[src/data/chapter3-canteen.content.json:155](../src/data/chapter3-canteen.content.json#L155)
202. 系统：骑上车，别再看它。
   来源：[src/data/chapter3-canteen.content.json:156](../src/data/chapter3-canteen.content.json#L156)
203. 扫码骑车：2.00 元 / 次
   来源：[src/data/chapter3-canteen.content.json:158](../src/data/chapter3-canteen.content.json#L158)
204. 我的零钱：{amount} 元
   来源：[src/data/chapter3-canteen.content.json:159](../src/data/chapter3-canteen.content.json#L159)
205. 玩家：零钱不够。
   来源：[src/data/chapter3-canteen.content.json:161](../src/data/chapter3-canteen.content.json#L161)
206. 系统：先完成餐盘回收。
   来源：[src/data/chapter3-canteen.content.json:162](../src/data/chapter3-canteen.content.json#L162)
207. 餐盘回收费已到账。用 2.00 元支付一次骑行。
   来源：[src/data/chapter3-canteen.content.json:164](../src/data/chapter3-canteen.content.json#L164)
208. 反光过强，识别失败
   来源：[src/data/chapter3-canteen.content.json:165](../src/data/chapter3-canteen.content.json#L165)
209. 显示完整编号与二维码边缘压痕
   来源：[src/data/chapter3-canteen.content.json:166](../src/data/chapter3-canteen.content.json#L166)
210. 残影记录不具备支付资格。
   来源：[src/data/chapter3-canteen.content.json:167](../src/data/chapter3-canteen.content.json#L167)
211. 反光消失，二维码可读
   来源：[src/data/chapter3-canteen.content.json:168](../src/data/chapter3-canteen.content.json#L168)
212. 浅色操作可清洁车锁并扫码付款；深色观察可补充查看编号压痕。
   来源：[src/data/chapter3-canteen.content.json:169](../src/data/chapter3-canteen.content.json#L169)
213. 755 米骑行完成，纸条钻进剧院。
   来源：[src/data/chapter3-canteen.content.json:170](../src/data/chapter3-canteen.content.json#L170)
214. 人行道上有人赶早课，没人注意纸条掠过车道。
   来源：[src/data/chapter3-canteen.content.json:172](../src/data/chapter3-canteen.content.json#L172)
215. 食堂门口两个人聊着天，占住了外侧车道。
   来源：[src/data/chapter3-canteen.content.json:173](../src/data/chapter3-canteen.content.json#L173)
216. 有人端着豆浆停在路边，给你留出一段空路。
   来源：[src/data/chapter3-canteen.content.json:174](../src/data/chapter3-canteen.content.json#L174)
217. 前面有人推车过马路，纸条已经飞到剧院方向。
   来源：[src/data/chapter3-canteen.content.json:175](../src/data/chapter3-canteen.content.json#L175)
218. 任务：骑车追上纸条
   来源：[src/data/chapter3-canteen.content.json:177](../src/data/chapter3-canteen.content.json#L177)
219. 在车锁旁清除反光并付款。
   来源：[src/data/chapter3-canteen.content.json:179](../src/data/chapter3-canteen.content.json#L179)
220. 骑行时避开前方车辆和行人。
   来源：[src/data/chapter3-canteen.content.json:180](../src/data/chapter3-canteen.content.json#L180)
221. 深色观察可补充查看编号，浅色操作负责清洁与付款。
   来源：[src/data/chapter3-canteen.content.json:181](../src/data/chapter3-canteen.content.json#L181)
222. 在剧院逼停纸条
   来源：[src/data/chapter3-canteen.content.json:185](../src/data/chapter3-canteen.content.json#L185)
223. 纸条进去了，你还没有票。
   来源：[src/data/chapter3-canteen.content.json:187](../src/data/chapter3-canteen.content.json#L187)
224. 深色模式能看到票根、节目单简介里的荧光编号和纸条残影。
   来源：[src/data/chapter3-canteen.content.json:188](../src/data/chapter3-canteen.content.json#L188)
225. 先拼票进场，再让纸条在浅色模式里发光。
   来源：[src/data/chapter3-canteen.content.json:189](../src/data/chapter3-canteen.content.json#L189)
226. 生锈的柜门钥匙
   来源：[src/data/chapter3-qizhen-fishing.charts.json:10](../src/data/chapter3-qizhen-fishing.charts.json#L10)；[src/scenes/rpg/QizhenLakeScene.ts:167](../src/scenes/rpg/QizhenLakeScene.ts#L167)
227. 教学谱面：音符碰到判定线时按对应的 A / S / D
   来源：[src/data/chapter3-qizhen-fishing.charts.json:12](../src/data/chapter3-qizhen-fishing.charts.json#L12)
228. 短判定：按住 A 至圆环结束，再完成收线
   来源：[src/data/chapter3-qizhen-fishing.charts.json:30](../src/data/chapter3-qizhen-fishing.charts.json#L30)
229. 小鲤鱼
   来源：[src/data/chapter3-qizhen-fishing.charts.json:42](../src/data/chapter3-qizhen-fishing.charts.json#L42)；[src/data/chapter3-qizhen-lake.content.json:126](../src/data/chapter3-qizhen-lake.content.json#L126)；[src/scenes/rpg/QizhenLakeScene.ts:169](../src/scenes/rpg/QizhenLakeScene.ts#L169)
230. 一次判定：水纹收紧到判定线时按 S 提竿
   来源：[src/data/chapter3-qizhen-fishing.charts.json:44](../src/data/chapter3-qizhen-fishing.charts.json#L44)
231. 纸条本体
   来源：[src/data/chapter3-qizhen-fishing.charts.json:53](../src/data/chapter3-qizhen-fishing.charts.json#L53)；[src/scenes/rpg/QizhenLakeScene.ts:170](../src/scenes/rpg/QizhenLakeScene.ts#L170)
232. 最终捕纸：保持张力，完整完成八小节
   来源：[src/data/chapter3-qizhen-fishing.charts.json:55](../src/data/chapter3-qizhen-fishing.charts.json#L55)
233. 启真湖
   来源：[src/data/chapter3-qizhen-lake.content.json:3](../src/data/chapter3-qizhen-lake.content.json#L3)
234. 剧场外 · 湖畔方向
   来源：[src/data/chapter3-qizhen-lake.content.json:6](../src/data/chapter3-qizhen-lake.content.json#L6)
235. 湿纸从剧场门边飞出，贴着路面向东移动。
   来源：[src/data/chapter3-qizhen-lake.content.json:11](../src/data/chapter3-qizhen-lake.content.json#L11)
236. 路边只留下几段不连续的水迹。
   来源：[src/data/chapter3-qizhen-lake.content.json:12](../src/data/chapter3-qizhen-lake.content.json#L12)
237. 水迹在湖畔一侧中断，无法直接确认地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:13](../src/data/chapter3-qizhen-lake.content.json#L13)
238. 玩家：它去哪了？
   来源：[src/data/chapter3-qizhen-lake.content.json:17](../src/data/chapter3-qizhen-lake.content.json#L17)
239. 系统：没有连续痕迹，需要核对其他来源。
   来源：[src/data/chapter3-qizhen-lake.content.json:18](../src/data/chapter3-qizhen-lake.content.json#L18)
240. 玩家：那就分头查。
   来源：[src/data/chapter3-qizhen-lake.content.json:19](../src/data/chapter3-qizhen-lake.content.json#L19)
241. 系统：先看论坛和馆藏记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:20](../src/data/chapter3-qizhen-lake.content.json#L20)
242. 【求助】剧院门口飞出一张湿纸，有人看见吗
   来源：[src/data/chapter3-qizhen-lake.content.json:23](../src/data/chapter3-qizhen-lake.content.json#L23)
243. 3楼：刚看到它往有水的地方移动。
   来源：[src/data/chapter3-qizhen-lake.content.json:25](../src/data/chapter3-qizhen-lake.content.json#L25)
244. 8楼：方向靠近桥。
   来源：[src/data/chapter3-qizhen-lake.content.json:26](../src/data/chapter3-qizhen-lake.content.json#L26)
245. 14楼：最后一次看到它时，纸边还在滴水。
   来源：[src/data/chapter3-qizhen-lake.content.json:27](../src/data/chapter3-qizhen-lake.content.json#L27)
246. 系统：论坛线索指向湖区和桥。
   来源：[src/data/chapter3-qizhen-lake.content.json:29](../src/data/chapter3-qizhen-lake.content.json#L29)
247. 玩家：继续找能区分地点的信息。
   来源：[src/data/chapter3-qizhen-lake.content.json:30](../src/data/chapter3-qizhen-lake.content.json#L30)
248. 签到记录夹页
   来源：[src/data/chapter3-qizhen-lake.content.json:33](../src/data/chapter3-qizhen-lake.content.json#L33)
249. 馆藏状态
   来源：[src/data/chapter3-qizhen-lake.content.json:35](../src/data/chapter3-qizhen-lake.content.json#L35)
250. 异常外借
   来源：[src/data/chapter3-qizhen-lake.content.json:35](../src/data/chapter3-qizhen-lake.content.json#L35)
251. 偏高
   来源：[src/data/chapter3-qizhen-lake.content.json:36](../src/data/chapter3-qizhen-lake.content.json#L36)
252. 湿度
   来源：[src/data/chapter3-qizhen-lake.content.json:36](../src/data/chapter3-qizhen-lake.content.json#L36)
253. 定位方式
   来源：[src/data/chapter3-qizhen-lake.content.json:37](../src/data/chapter3-qizhen-lake.content.json#L37)
254. 失效
   来源：[src/data/chapter3-qizhen-lake.content.json:37](../src/data/chapter3-qizhen-lake.content.json#L37)
255. 水面反射区域
   来源：[src/data/chapter3-qizhen-lake.content.json:38](../src/data/chapter3-qizhen-lake.content.json#L38)
256. 最近特征
   来源：[src/data/chapter3-qizhen-lake.content.json:38](../src/data/chapter3-qizhen-lake.content.json#L38)
257. 备注
   来源：[src/data/chapter3-qizhen-lake.content.json:39](../src/data/chapter3-qizhen-lake.content.json#L39)
258. 当前页码只出现在倒影中
   来源：[src/data/chapter3-qizhen-lake.content.json:39](../src/data/chapter3-qizhen-lake.content.json#L39)
259. 玩家：需要在湖面倒影里确认位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:41](../src/data/chapter3-qizhen-lake.content.json#L41)
260. 系统：已记录倒影条件。
   来源：[src/data/chapter3-qizhen-lake.content.json:42](../src/data/chapter3-qizhen-lake.content.json#L42)
261. 朋友：你到哪了？
   来源：[src/data/chapter3-qizhen-lake.content.json:45](../src/data/chapter3-qizhen-lake.content.json#L45)
262. 自动回复：我在跟踪湿纸。
   来源：[src/data/chapter3-qizhen-lake.content.json:46](../src/data/chapter3-qizhen-lake.content.json#L46)
263. 朋友：群里有人在校园湖面拍到了一圈逆风扩散的水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:47](../src/data/chapter3-qizhen-lake.content.json#L47)
264. 已接入 1 条记录，来源还不足以确认地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:50](../src/data/chapter3-qizhen-lake.content.json#L50)
265. 已接入 2 条记录，还缺一个独立来源。
   来源：[src/data/chapter3-qizhen-lake.content.json:51](../src/data/chapter3-qizhen-lake.content.json#L51)
266. 三条记录已对齐。核对交点后才会在校园地图上标记入口。
   来源：[src/data/chapter3-qizhen-lake.content.json:52](../src/data/chapter3-qizhen-lake.content.json#L52)
267. 手机地图：已确认启真湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:53](../src/data/chapter3-qizhen-lake.content.json#L53)
268. 核对结果：桥边、倒影和湖面三条记录指向同一个地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:54](../src/data/chapter3-qizhen-lake.content.json#L54)
269. 核对交点
   来源：[src/data/chapter3-qizhen-lake.content.json:55](../src/data/chapter3-qizhen-lake.content.json#L55)
270. 玩家：前往启真湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:56](../src/data/chapter3-qizhen-lake.content.json#L56)
271. 系统：已建立湖区入口。
   来源：[src/data/chapter3-qizhen-lake.content.json:57](../src/data/chapter3-qizhen-lake.content.json#L57)
272. 玩家：小码头有一艘皮划艇。
   来源：[src/data/chapter3-qizhen-lake.content.json:62](../src/data/chapter3-qizhen-lake.content.json#L62)
273. 系统：船边还缺两件可以划水的工具。
   来源：[src/data/chapter3-qizhen-lake.content.json:63](../src/data/chapter3-qizhen-lake.content.json#L63)
274. 玩家：先完成上船平衡。
   来源：[src/data/chapter3-qizhen-lake.content.json:64](../src/data/chapter3-qizhen-lake.content.json#L64)
275. 任务：先确认皮划艇，再在码头周围寻找两件可以划水的东西。
   来源：[src/data/chapter3-qizhen-lake.content.json:66](../src/data/chapter3-qizhen-lake.content.json#L66)
276. 先查看救生圈旁的器材架。
   来源：[src/data/chapter3-qizhen-lake.content.json:67](../src/data/chapter3-qizhen-lake.content.json#L67)
277. 码头周围有一件细长物体，靠近后再判断能不能使用。
   来源：[src/data/chapter3-qizhen-lake.content.json:68](../src/data/chapter3-qizhen-lake.content.json#L68)
278. 另一件需要从码头现有设施里找。
   来源：[src/data/chapter3-qizhen-lake.content.json:69](../src/data/chapter3-qizhen-lake.content.json#L69)
279. 三件装备收齐后，到码头前端上船，再交替划左右桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:70](../src/data/chapter3-qizhen-lake.content.json#L70)
280. 先把皮划艇划回小码头并上岸。
   来源：[src/data/chapter3-qizhen-lake.content.json:71](../src/data/chapter3-qizhen-lake.content.json#L71)
281. 皮划艇已确认。两支桨没有放在器材架上，继续沿码头寻找。
   来源：[src/data/chapter3-qizhen-lake.content.json:72](../src/data/chapter3-qizhen-lake.content.json#L72)
282. 柳树枝长度合适，已作为左桨。还要找另一侧的桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:73](../src/data/chapter3-qizhen-lake.content.json#L73)
283. 旧三角牌已经拆下，可作为右桨。继续找齐剩余装备。
   来源：[src/data/chapter3-qizhen-lake.content.json:74](../src/data/chapter3-qizhen-lake.content.json#L74)
284. 皮划艇和两支临时桨都已收齐。
   来源：[src/data/chapter3-qizhen-lake.content.json:75](../src/data/chapter3-qizhen-lake.content.json#L75)
285. 值班老师：现在天气不能下水。你要坚持，可以继续靠近码头试试。
   来源：[src/data/chapter3-qizhen-lake.content.json:76](../src/data/chapter3-qizhen-lake.content.json#L76)
286. 值班老师：雨还没停，不能下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:77](../src/data/chapter3-qizhen-lake.content.json#L77)
287. 值班老师：这么不长记性，还想要再成一次落汤鸡不成。
   来源：[src/data/chapter3-qizhen-lake.content.json:78](../src/data/chapter3-qizhen-lake.content.json#L78)
288. 你还是把皮划艇推下水，顶着雨划离了码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:79](../src/data/chapter3-qizhen-lake.content.json#L79)
289. 连续几桨后，侧风把船身压向一边，皮划艇失去平衡。
   来源：[src/data/chapter3-qizhen-lake.content.json:80](../src/data/chapter3-qizhen-lake.content.json#L80)
290. 值班老师和安全员把你救上岸。
   来源：[src/data/chapter3-qizhen-lake.content.json:81](../src/data/chapter3-qizhen-lake.content.json#L81)
291. 值班老师：现在可以下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:82](../src/data/chapter3-qizhen-lake.content.json#L82)；[src/data/chapter3-qizhen-lake.content.json:83](../src/data/chapter3-qizhen-lake.content.json#L83)
292. 这是下过雨的证明
   来源：[src/data/chapter3-qizhen-lake.content.json:84](../src/data/chapter3-qizhen-lake.content.json#L84)
293. 现在天气不能下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:85](../src/data/chapter3-qizhen-lake.content.json#L85)
294. 上船平衡
   来源：[src/data/chapter3-qizhen-lake.content.json:88](../src/data/chapter3-qizhen-lake.content.json#L88)
295. 键盘用 A/左方向键划左桨、D/右方向键划右桨，按住 S 或下方向键再划可后退。触屏在左右桨按钮上向上划为前进、向下划为后退，轻触默认前进。上船时先连续交替前划四次。
   来源：[src/data/chapter3-qizhen-lake.content.json:89](../src/data/chapter3-qizhen-lake.content.json#L89)
296. 连续划同一侧会增大倾角。
   来源：[src/data/chapter3-qizhen-lake.content.json:90](../src/data/chapter3-qizhen-lake.content.json#L90)
297. 后划可以离岸或修正位置；上船平衡仍需交替前划。
   来源：[src/data/chapter3-qizhen-lake.content.json:91](../src/data/chapter3-qizhen-lake.content.json#L91)
298. 皮划艇翻转，已回到最近安全点。
   来源：[src/data/chapter3-qizhen-lake.content.json:92](../src/data/chapter3-qizhen-lake.content.json#L92)
299. 你的手机和眼镜共沉启真湖，只有手机打捞上来了，眼镜永远离开了你。
   来源：[src/data/chapter3-qizhen-lake.content.json:93](../src/data/chapter3-qizhen-lake.content.json#L93)
300. 平衡已稳定，可以进入大湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:94](../src/data/chapter3-qizhen-lake.content.json#L94)
301. 上船阶段横向稳定性低。键盘左右桨默认前划，按住下方向键可后划；触屏上划前进、下划后退。先交替前划四次稳住重心。
   来源：[src/data/chapter3-qizhen-lake.content.json:95](../src/data/chapter3-qizhen-lake.content.json#L95)
302. 任务：交替第 1 次，继续保持。
   来源：[src/data/chapter3-qizhen-lake.content.json:97](../src/data/chapter3-qizhen-lake.content.json#L97)
303. 任务：交替第 2 次，船身渐稳。
   来源：[src/data/chapter3-qizhen-lake.content.json:98](../src/data/chapter3-qizhen-lake.content.json#L98)
304. 任务：交替第 3 次，还差一次。
   来源：[src/data/chapter3-qizhen-lake.content.json:99](../src/data/chapter3-qizhen-lake.content.json#L99)
305. 连续划同一侧导致翻船，左右交替可以稳住船身。
   来源：[src/data/chapter3-qizhen-lake.content.json:101](../src/data/chapter3-qizhen-lake.content.json#L101)
306. 船身被边界挡住。船头方向保持不变；键盘按住 S/↓ 再交替划桨，触屏在左右桨上交替向下划，即可倒出。
   来源：[src/data/chapter3-qizhen-lake.content.json:102](../src/data/chapter3-qizhen-lake.content.json#L102)
307. 键盘 A/← 左桨 · D/→ 右桨 · S/↓+桨 后划｜触屏上划前进 · 下划后退
   来源：[src/data/chapter3-qizhen-lake.content.json:103](../src/data/chapter3-qizhen-lake.content.json#L103)
308. 默认前划
   来源：[src/data/chapter3-qizhen-lake.content.json:104](../src/data/chapter3-qizhen-lake.content.json#L104)
309. 后划已按住
   来源：[src/data/chapter3-qizhen-lake.content.json:105](../src/data/chapter3-qizhen-lake.content.json#L105)
310. 后退中
   来源：[src/data/chapter3-qizhen-lake.content.json:106](../src/data/chapter3-qizhen-lake.content.json#L106)
311. 侧倾
   来源：[src/data/chapter3-qizhen-lake.content.json:107](../src/data/chapter3-qizhen-lake.content.json#L107)；[src/data/chapter3-qizhen-lake.content.json:374](../src/data/chapter3-qizhen-lake.content.json#L374)；[src/modules/QizhenJournalModel.ts:61](../src/modules/QizhenJournalModel.ts#L61)
312. 即将翻船
   来源：[src/data/chapter3-qizhen-lake.content.json:108](../src/data/chapter3-qizhen-lake.content.json#L108)
313. 浅色操作：划船、取物、抛竿和组合道具。
   来源：[src/data/chapter3-qizhen-lake.content.json:111](../src/data/chapter3-qizhen-lake.content.json#L111)
314. 深色观察：记录纸条倒影和物品位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:112](../src/data/chapter3-qizhen-lake.content.json#L112)
315. 这个坐标尚未在深色观察中记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:113](../src/data/chapter3-qizhen-lake.content.json#L113)
316. 系统：已在浮排边找到钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:114](../src/data/chapter3-qizhen-lake.content.json#L114)
317. 假纸条已固定在鱼钩上。
   来源：[src/data/chapter3-qizhen-lake.content.json:115](../src/data/chapter3-qizhen-lake.content.json#L115)
318. 普通鱼钩无法固定纸条。先收齐三处分支材料。
   来源：[src/data/chapter3-qizhen-lake.content.json:116](../src/data/chapter3-qizhen-lake.content.json#L116)
319. 任务：去钥匙倒影对应的浅色水面抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:117](../src/data/chapter3-qizhen-lake.content.json#L117)
320. 道具 1：生锈的柜门钥匙
   来源：[src/data/chapter3-qizhen-lake.content.json:120](../src/data/chapter3-qizhen-lake.content.json#L120)
321. 道具 2：尼龙绳
   来源：[src/data/chapter3-qizhen-lake.content.json:121](../src/data/chapter3-qizhen-lake.content.json#L121)
322. 道具 3：破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:122](../src/data/chapter3-qizhen-lake.content.json#L122)
323. 道具 4：临时抄网
   来源：[src/data/chapter3-qizhen-lake.content.json:123](../src/data/chapter3-qizhen-lake.content.json#L123)
324. 道具 5：密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:124](../src/data/chapter3-qizhen-lake.content.json#L124)
325. 道具 6：鱼饲料颗粒
   来源：[src/data/chapter3-qizhen-lake.content.json:125](../src/data/chapter3-qizhen-lake.content.json#L125)
326. 道具 7：黑天鹅掉落的磁性扣
   来源：[src/data/chapter3-qizhen-lake.content.json:127](../src/data/chapter3-qizhen-lake.content.json#L127)
327. 磁性钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:128](../src/data/chapter3-qizhen-lake.content.json#L128)
328. 检查围栏边遗留的旧饲料盒。
   来源：[src/data/chapter3-qizhen-lake.content.json:131](../src/data/chapter3-qizhen-lake.content.json#L131)
329. 系统：饲料盒处理完成，黑天鹅推来一枚磁性扣。
   来源：[src/data/chapter3-qizhen-lake.content.json:132](../src/data/chapter3-qizhen-lake.content.json#L132)
330. 磁性钓鱼竿已固定纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:133](../src/data/chapter3-qizhen-lake.content.json#L133)
331. 纸条触发围栏机关，黑天鹅进入直河道。
   来源：[src/data/chapter3-qizhen-lake.content.json:134](../src/data/chapter3-qizhen-lake.content.json#L134)
332. 任务：将三处分支材料带回大湖装配位。
   来源：[src/data/chapter3-qizhen-lake.content.json:135](../src/data/chapter3-qizhen-lake.content.json#L135)
333. 磁性钓鱼竿组合完成。
   来源：[src/data/chapter3-qizhen-lake.content.json:136](../src/data/chapter3-qizhen-lake.content.json#L136)
334. 黑天鹅只接受刚钓到的小鲤鱼。
   来源：[src/data/chapter3-qizhen-lake.content.json:137](../src/data/chapter3-qizhen-lake.content.json#L137)
335. 把黑天鹅磁性扣或钓鱼竿拖进组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:138](../src/data/chapter3-qizhen-lake.content.json#L138)
336. 需要磁性钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:139](../src/data/chapter3-qizhen-lake.content.json#L139)
337. 黑天鹅追逐
   来源：[src/data/chapter3-qizhen-lake.content.json:142](../src/data/chapter3-qizhen-lake.content.json#L142)
338. 交替划桨驶向河道左端。停划或撞上障碍会让黑天鹅追上船体。
   来源：[src/data/chapter3-qizhen-lake.content.json:143](../src/data/chapter3-qizhen-lake.content.json#L143)
339. 黑天鹅撞上船尾，追逐失败。
   来源：[src/data/chapter3-qizhen-lake.content.json:144](../src/data/chapter3-qizhen-lake.content.json#L144)
340. 已回到直河道追逐检查点。
   来源：[src/data/chapter3-qizhen-lake.content.json:145](../src/data/chapter3-qizhen-lake.content.json#L145)
341. 已返回小码头。磁性扣损坏，纸条再次逃离。
   来源：[src/data/chapter3-qizhen-lake.content.json:146](../src/data/chapter3-qizhen-lake.content.json#L146)
342. 已抵达河道另一端。
   来源：[src/data/chapter3-qizhen-lake.content.json:147](../src/data/chapter3-qizhen-lake.content.json#L147)
343. 左端抵达即通过
   来源：[src/data/chapter3-qizhen-lake.content.json:148](../src/data/chapter3-qizhen-lake.content.json#L148)
344. 追击距离
   来源：[src/data/chapter3-qizhen-lake.content.json:149](../src/data/chapter3-qizhen-lake.content.json#L149)
345. 黑天鹅接近船尾
   来源：[src/data/chapter3-qizhen-lake.content.json:150](../src/data/chapter3-qizhen-lake.content.json#L150)
346. 水面出现追击水纹
   来源：[src/data/chapter3-qizhen-lake.content.json:152](../src/data/chapter3-qizhen-lake.content.json#L152)
347. 黑天鹅保持追击
   来源：[src/data/chapter3-qizhen-lake.content.json:153](../src/data/chapter3-qizhen-lake.content.json#L153)
348. 黑天鹅正在抬翼蓄力
   来源：[src/data/chapter3-qizhen-lake.content.json:154](../src/data/chapter3-qizhen-lake.content.json#L154)
349. 黑天鹅短距冲刺
   来源：[src/data/chapter3-qizhen-lake.content.json:155](../src/data/chapter3-qizhen-lake.content.json#L155)
350. 黑天鹅减速调整
   来源：[src/data/chapter3-qizhen-lake.content.json:156](../src/data/chapter3-qizhen-lake.content.json#L156)
351. 距离稳定
   来源：[src/data/chapter3-qizhen-lake.content.json:159](../src/data/chapter3-qizhen-lake.content.json#L159)
352. 距离缩短
   来源：[src/data/chapter3-qizhen-lake.content.json:160](../src/data/chapter3-qizhen-lake.content.json#L160)
353. 即将接触船尾
   来源：[src/data/chapter3-qizhen-lake.content.json:161](../src/data/chapter3-qizhen-lake.content.json#L161)
354. 起始段
   来源：[src/data/chapter3-qizhen-lake.content.json:164](../src/data/chapter3-qizhen-lake.content.json#L164)
355. 河道中段
   来源：[src/data/chapter3-qizhen-lake.content.json:165](../src/data/chapter3-qizhen-lake.content.json#L165)
356. 左岸近段
   来源：[src/data/chapter3-qizhen-lake.content.json:166](../src/data/chapter3-qizhen-lake.content.json#L166)
357. 围栏开了。朝左岸划。
   来源：[src/data/chapter3-qizhen-lake.content.json:169](../src/data/chapter3-qizhen-lake.content.json#L169)
358. 它正在船尾对准航线。继续交替划桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:170](../src/data/chapter3-qizhen-lake.content.json#L170)
359. 左岸快到了。稳住节奏。
   来源：[src/data/chapter3-qizhen-lake.content.json:171](../src/data/chapter3-qizhen-lake.content.json#L171)
360. 玩家：纸条只在倒影里出现。
   来源：[src/data/chapter3-qizhen-lake.content.json:175](../src/data/chapter3-qizhen-lake.content.json#L175)
361. 系统：深色观察可以记录它的坐标。
   来源：[src/data/chapter3-qizhen-lake.content.json:175](../src/data/chapter3-qizhen-lake.content.json#L175)
362. 浅色操作可在浮排边捞起漂浮的钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:176](../src/data/chapter3-qizhen-lake.content.json#L176)
363. 系统：位置已记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:176](../src/data/chapter3-qizhen-lake.content.json#L176)
364. 浅色操作显示金色高对比可抛竿水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:177](../src/data/chapter3-qizhen-lake.content.json#L177)
365. 深色观察显示纸条倒影和物品位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:178](../src/data/chapter3-qizhen-lake.content.json#L178)
366. 该位置没有记录到目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:179](../src/data/chapter3-qizhen-lake.content.json#L179)
367. 位置已记录；浅色操作可在对应水纹抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:180](../src/data/chapter3-qizhen-lake.content.json#L180)
368. 在启真湖找到纸条
   来源：[src/data/chapter3-qizhen-lake.content.json:181](../src/data/chapter3-qizhen-lake.content.json#L181)；[src/data/chapter3-qizhen-lake.content.json:266](../src/data/chapter3-qizhen-lake.content.json#L266)
369. 旧指示牌已作为右桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:184](../src/data/chapter3-qizhen-lake.content.json#L184)
370. 浮排河道
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)
371. 禁止游泳
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)
372. 小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)；[src/data/chapter3-qizhen-lake.content.json:244](../src/data/chapter3-qizhen-lake.content.json#L244)；[src/data/chapter3-qizhen-lake.content.json:359](../src/data/chapter3-qizhen-lake.content.json#L359)；[src/scenes/rpg/QizhenLakeModel.ts:504](../src/scenes/rpg/QizhenLakeModel.ts#L504)
373. 该操作不符合当前阶段。
   来源：[src/data/chapter3-qizhen-lake.content.json:186](../src/data/chapter3-qizhen-lake.content.json#L186)
374. 右桨已安装。
   来源：[src/data/chapter3-qizhen-lake.content.json:187](../src/data/chapter3-qizhen-lake.content.json#L187)
375. 倒影坐标已记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:188](../src/data/chapter3-qizhen-lake.content.json#L188)
376. 浅色操作可在对应水纹抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:189](../src/data/chapter3-qizhen-lake.content.json#L189)
377. 任务：把假纸条固定到钓鱼竿上作饵。
   来源：[src/data/chapter3-qizhen-lake.content.json:192](../src/data/chapter3-qizhen-lake.content.json#L192)
378. 深色观察可补充确认坐标；浅色操作也可以直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:193](../src/data/chapter3-qizhen-lake.content.json#L193)
379. 系统：假纸条已装成诱饵，固定到鱼钩上。
   来源：[src/data/chapter3-qizhen-lake.content.json:194](../src/data/chapter3-qizhen-lake.content.json#L194)
380. 倒影中出现可抛竿的位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:195](../src/data/chapter3-qizhen-lake.content.json#L195)
381. 先拖入假纸条当饵；直接用普通钓鱼竿只会穿过倒影。
   来源：[src/data/chapter3-qizhen-lake.content.json:196](../src/data/chapter3-qizhen-lake.content.json#L196)
382. 当前为浅色操作。
   来源：[src/data/chapter3-qizhen-lake.content.json:199](../src/data/chapter3-qizhen-lake.content.json#L199)
383. 当前为深色观察。
   来源：[src/data/chapter3-qizhen-lake.content.json:200](../src/data/chapter3-qizhen-lake.content.json#L200)
384. 当前阶段无法切换观察模式。
   来源：[src/data/chapter3-qizhen-lake.content.json:201](../src/data/chapter3-qizhen-lake.content.json#L201)
385. 操作没有命中当前目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:202](../src/data/chapter3-qizhen-lake.content.json#L202)
386. 未命中目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:203](../src/data/chapter3-qizhen-lake.content.json#L203)
387. 目标已命中。
   来源：[src/data/chapter3-qizhen-lake.content.json:204](../src/data/chapter3-qizhen-lake.content.json#L204)
388. 钓起一把生锈的柜门钥匙。
   来源：[src/data/chapter3-qizhen-lake.content.json:207](../src/data/chapter3-qizhen-lake.content.json#L207)
389. 钓起一个破损网框。
   来源：[src/data/chapter3-qizhen-lake.content.json:208](../src/data/chapter3-qizhen-lake.content.json#L208)
390. 码头储物柜打开，里面是一卷尼龙绳。
   来源：[src/data/chapter3-qizhen-lake.content.json:209](../src/data/chapter3-qizhen-lake.content.json#L209)
391. 尼龙绳已经固定到破损网框，临时抄网完成。
   来源：[src/data/chapter3-qizhen-lake.content.json:210](../src/data/chapter3-qizhen-lake.content.json#L210)
392. 临时抄网从浮排下捞出了密封饲料盒。
   来源：[src/data/chapter3-qizhen-lake.content.json:211](../src/data/chapter3-qizhen-lake.content.json#L211)
393. 在浮排硬边撬开盒盖，得到鱼食颗粒。
   来源：[src/data/chapter3-qizhen-lake.content.json:212](../src/data/chapter3-qizhen-lake.content.json#L212)
394. 鱼食颗粒引来一条小鲤鱼。
   来源：[src/data/chapter3-qizhen-lake.content.json:213](../src/data/chapter3-qizhen-lake.content.json#L213)
395. 这里需要生锈的柜门钥匙。
   来源：[src/data/chapter3-qizhen-lake.content.json:214](../src/data/chapter3-qizhen-lake.content.json#L214)
396. 把尼龙绳或破损网框拖进组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:215](../src/data/chapter3-qizhen-lake.content.json#L215)
397. 这里需要临时抄网。
   来源：[src/data/chapter3-qizhen-lake.content.json:216](../src/data/chapter3-qizhen-lake.content.json#L216)
398. 把密封饲料盒拖到硬边上撬开。
   来源：[src/data/chapter3-qizhen-lake.content.json:217](../src/data/chapter3-qizhen-lake.content.json#L217)
399. 把道具拖到场景中对应的真实物体。
   来源：[src/data/chapter3-qizhen-lake.content.json:220](../src/data/chapter3-qizhen-lake.content.json#L220)
400. 没有命中当前可用物体，靠近并对准后重试。
   来源：[src/data/chapter3-qizhen-lake.content.json:221](../src/data/chapter3-qizhen-lake.content.json#L221)
401. 当前为深色观察；使用实体道具需要浅色操作。
   来源：[src/data/chapter3-qizhen-lake.content.json:222](../src/data/chapter3-qizhen-lake.content.json#L222)
402. 目标对了，把皮划艇划到金色水纹外圈附近即可抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:223](../src/data/chapter3-qizhen-lake.content.json#L223)
403. 先把人物或皮划艇移到高对比标记附近。
   来源：[src/data/chapter3-qizhen-lake.content.json:224](../src/data/chapter3-qizhen-lake.content.json#L224)
404. 当前道具与这个目标不匹配。
   来源：[src/data/chapter3-qizhen-lake.content.json:225](../src/data/chapter3-qizhen-lake.content.json#L225)
405. 确认器材架上的皮划艇
   来源：[src/data/chapter3-qizhen-lake.content.json:228](../src/data/chapter3-qizhen-lake.content.json#L228)
406. 查看花坛边的细长物体
   来源：[src/data/chapter3-qizhen-lake.content.json:229](../src/data/chapter3-qizhen-lake.content.json#L229)
407. 查看设备区的旧设施
   来源：[src/data/chapter3-qizhen-lake.content.json:230](../src/data/chapter3-qizhen-lake.content.json#L230)
408. 从小码头上船
   来源：[src/data/chapter3-qizhen-lake.content.json:231](../src/data/chapter3-qizhen-lake.content.json#L231)
409. 观察倒影位置
   来源：[src/data/chapter3-qizhen-lake.content.json:232](../src/data/chapter3-qizhen-lake.content.json#L232)
410. 捞起钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:233](../src/data/chapter3-qizhen-lake.content.json#L233)
411. 开始节奏钓取
   来源：[src/data/chapter3-qizhen-lake.content.json:234](../src/data/chapter3-qizhen-lake.content.json#L234)
412. 把小鲤鱼喂给黑天鹅
   来源：[src/data/chapter3-qizhen-lake.content.json:235](../src/data/chapter3-qizhen-lake.content.json#L235)
413. 直接抛竿会失败；拖入假纸条作饵
   来源：[src/data/chapter3-qizhen-lake.content.json:236](../src/data/chapter3-qizhen-lake.content.json#L236)
414. 使用当前钓具
   来源：[src/data/chapter3-qizhen-lake.content.json:237](../src/data/chapter3-qizhen-lake.content.json#L237)
415. 冲回小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:238](../src/data/chapter3-qizhen-lake.content.json#L238)
416. 抵达河道左端即自动通过
   来源：[src/data/chapter3-qizhen-lake.content.json:239](../src/data/chapter3-qizhen-lake.content.json#L239)
417. 离开启真湖
   来源：[src/data/chapter3-qizhen-lake.content.json:240](../src/data/chapter3-qizhen-lake.content.json#L240)；[src/scenes/rpg/QizhenLakeModel.ts:381](../src/scenes/rpg/QizhenLakeModel.ts#L381)
418. 当前动作需要浅色操作
   来源：[src/data/chapter3-qizhen-lake.content.json:241](../src/data/chapter3-qizhen-lake.content.json#L241)
419. 启真湖大湖面
   来源：[src/data/chapter3-qizhen-lake.content.json:245](../src/data/chapter3-qizhen-lake.content.json#L245)
420. 浮排直河道
   来源：[src/data/chapter3-qizhen-lake.content.json:246](../src/data/chapter3-qizhen-lake.content.json#L246)
421. 黑天鹅围栏
   来源：[src/data/chapter3-qizhen-lake.content.json:247](../src/data/chapter3-qizhen-lake.content.json#L247)；[src/data/chapter3-qizhen-lake.content.json:361](../src/data/chapter3-qizhen-lake.content.json#L361)；[src/scenes/rpg/QizhenLakeModel.ts:531](../src/scenes/rpg/QizhenLakeModel.ts#L531)
422. 完成上船平衡后才能划向大湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:250](../src/data/chapter3-qizhen-lake.content.json#L250)
423. 钓到小鲤鱼后才能前往黑天鹅围栏。
   来源：[src/data/chapter3-qizhen-lake.content.json:251](../src/data/chapter3-qizhen-lake.content.json#L251)
424. 尼龙绳和破损网框尚未组合成临时抄网。
   来源：[src/data/chapter3-qizhen-lake.content.json:252](../src/data/chapter3-qizhen-lake.content.json#L252)
425. 浮排河道已经处理完。
   来源：[src/data/chapter3-qizhen-lake.content.json:253](../src/data/chapter3-qizhen-lake.content.json#L253)
426. 围栏机关尚未触发，需要先用磁性钓鱼竿取出纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:254](../src/data/chapter3-qizhen-lake.content.json#L254)
427. 密封饲料盒还没捞起并打开。
   来源：[src/data/chapter3-qizhen-lake.content.json:255](../src/data/chapter3-qizhen-lake.content.json#L255)
428. 在小码头分别找齐皮划艇和左右桨
   来源：[src/data/chapter3-qizhen-lake.content.json:258](../src/data/chapter3-qizhen-lake.content.json#L258)
429. 交替划左右桨完成上船
   来源：[src/data/chapter3-qizhen-lake.content.json:259](../src/data/chapter3-qizhen-lake.content.json#L259)
430. 切到深色观察，记录倒影位置
   来源：[src/data/chapter3-qizhen-lake.content.json:260](../src/data/chapter3-qizhen-lake.content.json#L260)
431. 任意顺序完成柜门、浮排和天鹅三处分支
   来源：[src/data/chapter3-qizhen-lake.content.json:261](../src/data/chapter3-qizhen-lake.content.json#L261)
432. 处理围栏边的旧饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:262](../src/data/chapter3-qizhen-lake.content.json#L262)
433. 用磁性钓鱼竿取出纸条
   来源：[src/data/chapter3-qizhen-lake.content.json:263](../src/data/chapter3-qizhen-lake.content.json#L263)
434. 沿直河道逃回小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:264](../src/data/chapter3-qizhen-lake.content.json#L264)
435. 查看启真湖后续过渡剧情
   来源：[src/data/chapter3-qizhen-lake.content.json:265](../src/data/chapter3-qizhen-lake.content.json#L265)
436. 深色观察用于记录坐标，浅色操作可直接尝试抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:268](../src/data/chapter3-qizhen-lake.content.json#L268)
437. 普通鱼钩无法直接固定纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:269](../src/data/chapter3-qizhen-lake.content.json#L269)
438. 道具会在最后一次成功使用后消失。
   来源：[src/data/chapter3-qizhen-lake.content.json:270](../src/data/chapter3-qizhen-lake.content.json#L270)
439. 在大湖面捞起钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:274](../src/data/chapter3-qizhen-lake.content.json#L274)
440. 浅色操作时，在大湖面浮排边捞起钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:275](../src/data/chapter3-qizhen-lake.content.json#L275)
441. 深色观察可先记录纸条倒影，但不限制捞竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:275](../src/data/chapter3-qizhen-lake.content.json#L275)
442. 把假纸条装上钓鱼竿作饵
   来源：[src/data/chapter3-qizhen-lake.content.json:278](../src/data/chapter3-qizhen-lake.content.json#L278)
443. 把假纸条拖到大湖面的纸条倒影上装饵。
   来源：[src/data/chapter3-qizhen-lake.content.json:279](../src/data/chapter3-qizhen-lake.content.json#L279)
444. 直接对倒影抛竿只会穿过去。
   来源：[src/data/chapter3-qizhen-lake.content.json:279](../src/data/chapter3-qizhen-lake.content.json#L279)
445. 在钥匙倒影处钓起储物柜钥匙
   来源：[src/data/chapter3-qizhen-lake.content.json:282](../src/data/chapter3-qizhen-lake.content.json#L282)
446. 彩色音符碰到白色判定线时按 A 左收线、S 提竿、D 右收线；标有「按住」的音符要保持到水平进度条填满。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
447. 浅色操作时，皮划艇到达金色水纹外圈附近后，把钓鱼竿拖入水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
448. 深色观察可记录钥匙倒影坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
449. 用钥匙打开码头储物柜
   来源：[src/data/chapter3-qizhen-lake.content.json:286](../src/data/chapter3-qizhen-lake.content.json#L286)
450. 带着生锈的柜门钥匙回小码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:287](../src/data/chapter3-qizhen-lake.content.json#L287)
451. 靠近储物柜，把钥匙拖到锁孔。
   来源：[src/data/chapter3-qizhen-lake.content.json:287](../src/data/chapter3-qizhen-lake.content.json#L287)
452. 在旧木桩倒影处钓起破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:290](../src/data/chapter3-qizhen-lake.content.json#L290)
453. 浅色操作时，皮划艇到达金色网框水纹外圈附近后开始节奏钓取。
   来源：[src/data/chapter3-qizhen-lake.content.json:291](../src/data/chapter3-qizhen-lake.content.json#L291)
454. 深色观察可记录网框倒影坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:291](../src/data/chapter3-qizhen-lake.content.json#L291)
455. 组合尼龙绳和破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:294](../src/data/chapter3-qizhen-lake.content.json#L294)
456. 把尼龙绳或破损网框拖进组合位，也可以在道具栏内直接组合。
   来源：[src/data/chapter3-qizhen-lake.content.json:295](../src/data/chapter3-qizhen-lake.content.json#L295)
457. 浮标组合位在大湖面。
   来源：[src/data/chapter3-qizhen-lake.content.json:295](../src/data/chapter3-qizhen-lake.content.json#L295)
458. 用临时抄网捞起密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:298](../src/data/chapter3-qizhen-lake.content.json#L298)
459. 把临时抄网拖到浮排下方的投放框。
   来源：[src/data/chapter3-qizhen-lake.content.json:299](../src/data/chapter3-qizhen-lake.content.json#L299)
460. 从大湖北侧进入浮排直河道。
   来源：[src/data/chapter3-qizhen-lake.content.json:299](../src/data/chapter3-qizhen-lake.content.json#L299)
461. 在浮排硬边撬开密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:302](../src/data/chapter3-qizhen-lake.content.json#L302)
462. 把密封饲料盒拖到浮排硬边开罐位。
   来源：[src/data/chapter3-qizhen-lake.content.json:303](../src/data/chapter3-qizhen-lake.content.json#L303)
463. 密封饲料盒要借浮排硬边撬开。
   来源：[src/data/chapter3-qizhen-lake.content.json:303](../src/data/chapter3-qizhen-lake.content.json#L303)
464. 用鱼饲料颗粒钓一条小鲤鱼
   来源：[src/data/chapter3-qizhen-lake.content.json:306](../src/data/chapter3-qizhen-lake.content.json#L306)
465. 浅色操作时，皮划艇到达金色鱼群水纹外圈附近后，把鱼饲料颗粒拖入水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:307](../src/data/chapter3-qizhen-lake.content.json#L307)
466. 深色观察可记录鱼群水纹坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:307](../src/data/chapter3-qizhen-lake.content.json#L307)
467. 组合磁性扣和钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:310](../src/data/chapter3-qizhen-lake.content.json#L310)
468. 把黑天鹅磁性扣拖到钓鱼竿上，或去船头磁吸组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:311](../src/data/chapter3-qizhen-lake.content.json#L311)
469. 组合位在黑天鹅围栏外的水面。
   来源：[src/data/chapter3-qizhen-lake.content.json:311](../src/data/chapter3-qizhen-lake.content.json#L311)
470. 用磁性钓鱼竿吸住纸条本体
   来源：[src/data/chapter3-qizhen-lake.content.json:314](../src/data/chapter3-qizhen-lake.content.json#L314)
471. 皮划艇到达金色纸条水纹外圈附近后，把磁性钓鱼竿拖入水纹，完成最终八小节节奏钓取。
   来源：[src/data/chapter3-qizhen-lake.content.json:315](../src/data/chapter3-qizhen-lake.content.json#L315)
472. 深色观察可确认纸条坐标；浅色操作可直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:315](../src/data/chapter3-qizhen-lake.content.json#L315)
473. 【记录】启真湖首航：船是捡的，桨是凑的，人是活的
   来源：[src/data/chapter3-qizhen-lake.content.json:321](../src/data/chapter3-qizhen-lake.content.json#L321)
474. 启真湖划船一圈没翻，特此发帖留念
   来源：[src/data/chapter3-qizhen-lake.content.json:322](../src/data/chapter3-qizhen-lake.content.json#L322)
475. 在湖心漂了一下午，风比课表还满
   来源：[src/data/chapter3-qizhen-lake.content.json:323](../src/data/chapter3-qizhen-lake.content.json#L323)
476. 人还在湖上，船还浮着
   来源：[src/data/chapter3-qizhen-lake.content.json:326](../src/data/chapter3-qizhen-lake.content.json#L326)
477. 两条胳膊已报废，但不亏
   来源：[src/data/chapter3-qizhen-lake.content.json:327](../src/data/chapter3-qizhen-lake.content.json#L327)
478. 上岸再整理，先占个楼
   来源：[src/data/chapter3-qizhen-lake.content.json:328](../src/data/chapter3-qizhen-lake.content.json#L328)
479. 出发位打卡。临时装备已经固定，先试着划离码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:332](../src/data/chapter3-qizhen-lake.content.json#L332)
480. 回码头补一张。能完整地划回来，我自己都没想到。
   来源：[src/data/chapter3-qizhen-lake.content.json:333](../src/data/chapter3-qizhen-lake.content.json#L333)
481. 器材架空了一半，这艘皮划艇暂时归我保管。
   来源：[src/data/chapter3-qizhen-lake.content.json:334](../src/data/chapter3-qizhen-lake.content.json#L334)
482. 水面静下来的时候，倒影比实景还清楚，船都不敢动。
   来源：[src/data/chapter3-qizhen-lake.content.json:337](../src/data/chapter3-qizhen-lake.content.json#L337)
483. 刚按快门就来一圈水纹，倒影当场断开，凑合看。
   来源：[src/data/chapter3-qizhen-lake.content.json:338](../src/data/chapter3-qizhen-lake.content.json#L338)
484. 为了等水静下来，在湖心多漂了十分钟，值。
   来源：[src/data/chapter3-qizhen-lake.content.json:339](../src/data/chapter3-qizhen-lake.content.json#L339)
485. 黑天鹅隔着围栏盯着我看了很久，没敢再靠近。
   来源：[src/data/chapter3-qizhen-lake.content.json:342](../src/data/chapter3-qizhen-lake.content.json#L342)
486. 按下快门那一下它正好转头，气场很足。
   来源：[src/data/chapter3-qizhen-lake.content.json:343](../src/data/chapter3-qizhen-lake.content.json#L343)
487. 围栏空了，水面只剩一圈还没散的水痕。
   来源：[src/data/chapter3-qizhen-lake.content.json:344](../src/data/chapter3-qizhen-lake.content.json#L344)
488. 构图在线
   来源：[src/data/chapter3-qizhen-lake.content.json:348](../src/data/chapter3-qizhen-lake.content.json#L348)
489. 拍歪了
   来源：[src/data/chapter3-qizhen-lake.content.json:349](../src/data/chapter3-qizhen-lake.content.json#L349)
490. 速度太快
   来源：[src/data/chapter3-qizhen-lake.content.json:350](../src/data/chapter3-qizhen-lake.content.json#L350)
491. 水纹清楚
   来源：[src/data/chapter3-qizhen-lake.content.json:351](../src/data/chapter3-qizhen-lake.content.json#L351)
492. 水纹断了
   来源：[src/data/chapter3-qizhen-lake.content.json:352](../src/data/chapter3-qizhen-lake.content.json#L352)
493. 黑天鹅贴脸
   来源：[src/data/chapter3-qizhen-lake.content.json:353](../src/data/chapter3-qizhen-lake.content.json#L353)
494. 黑天鹅在远处
   来源：[src/data/chapter3-qizhen-lake.content.json:354](../src/data/chapter3-qizhen-lake.content.json#L354)
495. 鹅去栏空
   来源：[src/data/chapter3-qizhen-lake.content.json:355](../src/data/chapter3-qizhen-lake.content.json#L355)
496. 湖心
   来源：[src/data/chapter3-qizhen-lake.content.json:358](../src/data/chapter3-qizhen-lake.content.json#L358)；[src/scenes/rpg/QizhenLakeModel.ts:493](../src/scenes/rpg/QizhenLakeModel.ts#L493)
497. 湖心倒影
   来源：[src/data/chapter3-qizhen-lake.content.json:360](../src/data/chapter3-qizhen-lake.content.json#L360)
498. 启真湖记录相机
   来源：[src/data/chapter3-qizhen-lake.content.json:364](../src/data/chapter3-qizhen-lake.content.json#L364)
499. 拍摄
   来源：[src/data/chapter3-qizhen-lake.content.json:365](../src/data/chapter3-qizhen-lake.content.json#L365)；[src/modules/QizhenJournalModel.ts:52](../src/modules/QizhenJournalModel.ts#L52)
500. 收起相机
   来源：[src/data/chapter3-qizhen-lake.content.json:366](../src/data/chapter3-qizhen-lake.content.json#L366)；[src/modules/QizhenJournalModel.ts:53](../src/modules/QizhenJournalModel.ts#L53)
501. 重拍
   来源：[src/data/chapter3-qizhen-lake.content.json:367](../src/data/chapter3-qizhen-lake.content.json#L367)；[src/modules/QizhenJournalModel.ts:54](../src/modules/QizhenJournalModel.ts#L54)
502. 选择主帖标题
   来源：[src/data/chapter3-qizhen-lake.content.json:368](../src/data/chapter3-qizhen-lake.content.json#L368)；[src/modules/QizhenJournalModel.ts:55](../src/modules/QizhenJournalModel.ts#L55)
503. 选择主帖状态
   来源：[src/data/chapter3-qizhen-lake.content.json:369](../src/data/chapter3-qizhen-lake.content.json#L369)；[src/modules/QizhenJournalModel.ts:56](../src/modules/QizhenJournalModel.ts#L56)
504. 选择补拍说明
   来源：[src/data/chapter3-qizhen-lake.content.json:370](../src/data/chapter3-qizhen-lake.content.json#L370)；[src/modules/QizhenJournalModel.ts:57](../src/modules/QizhenJournalModel.ts#L57)
505. 存为草稿
   来源：[src/data/chapter3-qizhen-lake.content.json:371](../src/data/chapter3-qizhen-lake.content.json#L371)；[src/modules/QizhenJournalModel.ts:58](../src/modules/QizhenJournalModel.ts#L58)
506. 草稿已保存,可前往 CC98 发布。
   来源：[src/data/chapter3-qizhen-lake.content.json:372](../src/data/chapter3-qizhen-lake.content.json#L372)；[src/modules/QizhenJournalModel.ts:59](../src/modules/QizhenJournalModel.ts#L59)
507. 速度
   来源：[src/data/chapter3-qizhen-lake.content.json:373](../src/data/chapter3-qizhen-lake.content.json#L373)；[src/modules/QizhenJournalModel.ts:60](../src/modules/QizhenJournalModel.ts#L60)
508. 船速和侧倾都会写进照片标签。想拍干净点，先把船稳下来再按快门。
   来源：[src/data/chapter3-qizhen-lake.content.json:375](../src/data/chapter3-qizhen-lake.content.json#L375)
509. 校园生活
   来源：[src/data/chapter3-qizhen-lake.content.json:378](../src/data/chapter3-qizhen-lake.content.json#L378)；[src/data/chapter3-theater.content.json:22](../src/data/chapter3-theater.content.json#L22)
510. 楼主
   来源：[src/data/chapter3-qizhen-lake.content.json:379](../src/data/chapter3-qizhen-lake.content.json#L379)；[src/modules/QizhenJournalModel.ts:81](../src/modules/QizhenJournalModel.ts#L81)
511. 草稿
   来源：[src/data/chapter3-qizhen-lake.content.json:380](../src/data/chapter3-qizhen-lake.content.json#L380)；[src/modules/QizhenJournalModel.ts:82](../src/modules/QizhenJournalModel.ts#L82)
512. 发布主帖
   来源：[src/data/chapter3-qizhen-lake.content.json:381](../src/data/chapter3-qizhen-lake.content.json#L381)；[src/modules/QizhenJournalModel.ts:83](../src/modules/QizhenJournalModel.ts#L83)
513. 发布中…
   来源：[src/data/chapter3-qizhen-lake.content.json:382](../src/data/chapter3-qizhen-lake.content.json#L382)；[src/modules/QizhenJournalModel.ts:84](../src/modules/QizhenJournalModel.ts#L84)
514. 追加到帖子
   来源：[src/data/chapter3-qizhen-lake.content.json:383](../src/data/chapter3-qizhen-lake.content.json#L383)；[src/modules/QizhenJournalModel.ts:85](../src/modules/QizhenJournalModel.ts#L85)
515. 只看楼主
   来源：[src/data/chapter3-qizhen-lake.content.json:384](../src/data/chapter3-qizhen-lake.content.json#L384)；[src/modules/QizhenJournalModel.ts:86](../src/modules/QizhenJournalModel.ts#L86)
516. 查看全部
   来源：[src/data/chapter3-qizhen-lake.content.json:385](../src/data/chapter3-qizhen-lake.content.json#L385)；[src/modules/QizhenJournalModel.ts:87](../src/modules/QizhenJournalModel.ts#L87)
517. 继续补充
   来源：[src/data/chapter3-qizhen-lake.content.json:386](../src/data/chapter3-qizhen-lake.content.json#L386)；[src/modules/QizhenJournalModel.ts:88](../src/modules/QizhenJournalModel.ts#L88)
518. 返回湖面
   来源：[src/data/chapter3-qizhen-lake.content.json:387](../src/data/chapter3-qizhen-lake.content.json#L387)；[src/data/chapter3-qizhen-lake.content.json:395](../src/data/chapter3-qizhen-lake.content.json#L395)；[src/modules/QizhenJournalModel.ts:89](../src/modules/QizhenJournalModel.ts#L89)；[src/modules/QizhenJournalModel.ts:102](../src/modules/QizhenJournalModel.ts#L102)
519. 帖子已归档,仅供查看。
   来源：[src/data/chapter3-qizhen-lake.content.json:388](../src/data/chapter3-qizhen-lake.content.json#L388)；[src/modules/QizhenJournalModel.ts:90](../src/modules/QizhenJournalModel.ts#L90)
520. 湖心主图
   来源：[src/data/chapter3-qizhen-lake.content.json:389](../src/data/chapter3-qizhen-lake.content.json#L389)；[src/modules/QizhenJournalModel.ts:91](../src/modules/QizhenJournalModel.ts#L91)
521. 补拍照片
   来源：[src/data/chapter3-qizhen-lake.content.json:390](../src/data/chapter3-qizhen-lake.content.json#L390)；[src/modules/QizhenJournalModel.ts:92](../src/modules/QizhenJournalModel.ts#L92)
522. 发布失败：不在校园网
   来源：[src/data/chapter3-qizhen-lake.content.json:392](../src/data/chapter3-qizhen-lake.content.json#L392)
523. CC98 仅在校园网（ZJUWLAN）下可以发帖。照片、标题和说明都已保留，网络恢复后请手动重试，不会自动补发。
   来源：[src/data/chapter3-qizhen-lake.content.json:393](../src/data/chapter3-qizhen-lake.content.json#L393)
524. 打开控制中心
   来源：[src/data/chapter3-qizhen-lake.content.json:394](../src/data/chapter3-qizhen-lake.content.json#L394)；[src/modules/QizhenJournalModel.ts:101](../src/modules/QizhenJournalModel.ts#L101)
525. 继续编辑
   来源：[src/data/chapter3-qizhen-lake.content.json:396](../src/data/chapter3-qizhen-lake.content.json#L396)；[src/modules/QizhenJournalModel.ts:103](../src/modules/QizhenJournalModel.ts#L103)
526. bd。楼主发帖时间已记录，比我昨晚的打印队列靠前。
   来源：[src/data/chapter3-qizhen-lake.content.json:401](../src/data/chapter3-qizhen-lake.content.json#L401)
527. 下午路过启真湖看见这艘船了，湖心风不小，照片倒是拍得挺稳。
   来源：[src/data/chapter3-qizhen-lake.content.json:402](../src/data/chapter3-qizhen-lake.content.json#L402)
528. 右边那支桨看着眼熟，像是器材架旁边立了很久的旧牌子。
   来源：[src/data/chapter3-qizhen-lake.content.json:403](../src/data/chapter3-qizhen-lake.content.json#L403)
529. 每天骑车绕湖一圈，头回见有人划这个。先收藏，翻了记得回来更新。
   来源：[src/data/chapter3-qizhen-lake.content.json:404](../src/data/chapter3-qizhen-lake.content.json#L404)
530. 余额 0.06 元，租船押金都付不起，看楼主发帖就当自己划过。
   来源：[src/data/chapter3-qizhen-lake.content.json:405](../src/data/chapter3-qizhen-lake.content.json#L405)
531. 无审核权限，仅存档湖心主图一张。船的来源建议楼主自行补充说明。
   来源：[src/data/chapter3-qizhen-lake.content.json:406](../src/data/chapter3-qizhen-lake.content.json#L406)
532. 这个码头我天天推车经过，器材架今天确实空了一格，原来在你这。
   来源：[src/data/chapter3-qizhen-lake.content.json:409](../src/data/chapter3-qizhen-lake.content.json#L409)
533. 架空位 +1，东西记得还。上次有人借桨借了半个学期。
   来源：[src/data/chapter3-qizhen-lake.content.json:410](../src/data/chapter3-qizhen-lake.content.json#L410)
534. 码头木板数过了，翘起来三块，踩中间那块最稳，不用谢。
   来源：[src/data/chapter3-qizhen-lake.content.json:411](../src/data/chapter3-qizhen-lake.content.json#L411)
535. 出发位与回位经比对为同一码头，行程闭环，予以存档。
   来源：[src/data/chapter3-qizhen-lake.content.json:412](../src/data/chapter3-qizhen-lake.content.json#L412)
536. 这张倒影我在对岸目击过拍摄过程，水面确实静了一阵，就一阵。
   来源：[src/data/chapter3-qizhen-lake.content.json:415](../src/data/chapter3-qizhen-lake.content.json#L415)
537. 等水静下来要多久？我在岸边计时到五分钟就放弃了，楼主有耐心。
   来源：[src/data/chapter3-qizhen-lake.content.json:416](../src/data/chapter3-qizhen-lake.content.json#L416)
538. 湖心倒影，老港人都知道这个机位。下班绕过去看一眼，血压能低点。
   来源：[src/data/chapter3-qizhen-lake.content.json:417](../src/data/chapter3-qizhen-lake.content.json#L417)
539. 倒影中船身与人物比例一致，未发现修图痕迹，通过。
   来源：[src/data/chapter3-qizhen-lake.content.json:418](../src/data/chapter3-qizhen-lake.content.json#L418)
540. 黑天鹅盯人是常规项目，建议不要长时间对视，赢不了。
   来源：[src/data/chapter3-qizhen-lake.content.json:421](../src/data/chapter3-qizhen-lake.content.json#L421)
541. 它转头那下我正好路过，连风都停了半秒，气场确实足。
   来源：[src/data/chapter3-qizhen-lake.content.json:422](../src/data/chapter3-qizhen-lake.content.json#L422)
542. 这鹅一天的伙食费超过我的余额，楼主别跟它比气场，比不过。
   来源：[src/data/chapter3-qizhen-lake.content.json:423](../src/data/chapter3-qizhen-lake.content.json#L423)
543. 空围栏这张亦已存档。水痕未散，后续动向保持观察。
   来源：[src/data/chapter3-qizhen-lake.content.json:424](../src/data/chapter3-qizhen-lake.content.json#L424)
544. system
   来源：[src/data/chapter3-story-lines.json:18](../src/data/chapter3-story-lines.json#L18)；[src/data/chapter3-story-lines.json:27](../src/data/chapter3-story-lines.json#L27)；[src/data/chapter3-story-lines.json:36](../src/data/chapter3-story-lines.json#L36)；[src/data/chapter3-story-lines.json:45](../src/data/chapter3-story-lines.json#L45)；[src/data/chapter3-story-lines.json:54](../src/data/chapter3-story-lines.json#L54)；[src/data/chapter3-story-lines.json:63](../src/data/chapter3-story-lines.json#L63)；[src/data/chapter3-story-lines.json:72](../src/data/chapter3-story-lines.json#L72)；[src/data/chapter3-story-lines.json:81](../src/data/chapter3-story-lines.json#L81)；[src/data/chapter3-story-lines.json:108](../src/data/chapter3-story-lines.json#L108)；[src/data/chapter3-story-lines.json:126](../src/data/chapter3-story-lines.json#L126)；[src/data/chapter3-story-lines.json:135](../src/data/chapter3-story-lines.json#L135)；[src/data/chapter3-story-lines.json:144](../src/data/chapter3-story-lines.json#L144)；[src/data/chapter3-story-lines.json:162](../src/data/chapter3-story-lines.json#L162)；[src/data/chapter3-story-lines.json:171](../src/data/chapter3-story-lines.json#L171)；[src/data/chapter3-story-lines.json:180](../src/data/chapter3-story-lines.json#L180)；[src/data/chapter3-story-lines.json:189](../src/data/chapter3-story-lines.json#L189)；[src/data/chapter3-story-lines.json:198](../src/data/chapter3-story-lines.json#L198)；[src/data/chapter3-story-lines.json:207](../src/data/chapter3-story-lines.json#L207)；[src/data/chapter3-story-lines.json:216](../src/data/chapter3-story-lines.json#L216)；[src/data/chapter3-story-lines.json:225](../src/data/chapter3-story-lines.json#L225)；[src/data/chapter3-story-lines.json:234](../src/data/chapter3-story-lines.json#L234)；[src/data/chapter3-story-lines.json:243](../src/data/chapter3-story-lines.json#L243)；[src/data/chapter3-story-lines.json:252](../src/data/chapter3-story-lines.json#L252)；[src/data/chapter3-story-lines.json:261](../src/data/chapter3-story-lines.json#L261)；[src/data/chapter3-story-lines.json:270](../src/data/chapter3-story-lines.json#L270)；[src/data/chapter3-story-lines.json:279](../src/data/chapter3-story-lines.json#L279)；[src/data/chapter3-story-lines.json:288](../src/data/chapter3-story-lines.json#L288)；[src/data/chapter3-story-lines.json:297](../src/data/chapter3-story-lines.json#L297)；[src/data/chapter3-story-lines.json:306](../src/data/chapter3-story-lines.json#L306)；[src/data/chapter3-story-lines.json:315](../src/data/chapter3-story-lines.json#L315)；[src/data/chapter3-story-lines.json:333](../src/data/chapter3-story-lines.json#L333)；[src/data/chapter3-story-lines.json:342](../src/data/chapter3-story-lines.json#L342)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:67](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L67)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:84](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L84)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:90](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L90)；[src/scenes/rpg/CanteenInteriorScene.ts:1977](../src/scenes/rpg/CanteenInteriorScene.ts#L1977)；[src/scenes/rpg/CanteenInteriorScene.ts:1981](../src/scenes/rpg/CanteenInteriorScene.ts#L1981)；[src/scenes/rpg/CanteenInteriorScene.ts:2013](../src/scenes/rpg/CanteenInteriorScene.ts#L2013)；[src/scenes/rpg/CanteenInteriorScene.ts:2017](../src/scenes/rpg/CanteenInteriorScene.ts#L2017)；[src/scenes/rpg/CanteenInteriorScene.ts:2026](../src/scenes/rpg/CanteenInteriorScene.ts#L2026)；[src/scenes/rpg/CanteenInteriorScene.ts:2035](../src/scenes/rpg/CanteenInteriorScene.ts#L2035)；[src/scenes/rpg/CanteenInteriorScene.ts:2051](../src/scenes/rpg/CanteenInteriorScene.ts#L2051)；[src/scenes/rpg/CanteenInteriorScene.ts:2055](../src/scenes/rpg/CanteenInteriorScene.ts#L2055)；[src/scenes/rpg/CanteenInteriorScene.ts:2069](../src/scenes/rpg/CanteenInteriorScene.ts#L2069)；[src/scenes/rpg/CanteenInteriorScene.ts:2077](../src/scenes/rpg/CanteenInteriorScene.ts#L2077)；[src/scenes/rpg/CanteenInteriorScene.ts:2081](../src/scenes/rpg/CanteenInteriorScene.ts#L2081)；[src/scenes/rpg/CanteenInteriorScene.ts:2085](../src/scenes/rpg/CanteenInteriorScene.ts#L2085)；[src/scenes/rpg/CanteenInteriorScene.ts:2114](../src/scenes/rpg/CanteenInteriorScene.ts#L2114)；[src/scenes/rpg/CanteenInteriorScene.ts:2118](../src/scenes/rpg/CanteenInteriorScene.ts#L2118)；[src/scenes/rpg/CanteenInteriorScene.ts:2269](../src/scenes/rpg/CanteenInteriorScene.ts#L2269)；[src/scenes/rpg/CanteenInteriorScene.ts:3237](../src/scenes/rpg/CanteenInteriorScene.ts#L3237)；[src/scenes/rpg/CanteenInteriorScene.ts:3313](../src/scenes/rpg/CanteenInteriorScene.ts#L3313)；[src/scenes/rpg/CanteenInteriorScene.ts:3665](../src/scenes/rpg/CanteenInteriorScene.ts#L3665)；[src/scenes/rpg/CanteenInteriorScene.ts:3715](../src/scenes/rpg/CanteenInteriorScene.ts#L3715)；[src/scenes/rpg/CanteenInteriorScene.ts:3805](../src/scenes/rpg/CanteenInteriorScene.ts#L3805)；[src/scenes/rpg/QizhenLakeScene.ts:591](../src/scenes/rpg/QizhenLakeScene.ts#L591)；[src/scenes/rpg/QizhenLakeScene.ts:841](../src/scenes/rpg/QizhenLakeScene.ts#L841)；[src/scenes/rpg/QizhenLakeScene.ts:1012](../src/scenes/rpg/QizhenLakeScene.ts#L1012)；[src/scenes/rpg/QizhenLakeScene.ts:1045](../src/scenes/rpg/QizhenLakeScene.ts#L1045)；[src/scenes/rpg/QizhenLakeScene.ts:1860](../src/scenes/rpg/QizhenLakeScene.ts#L1860)；[src/scenes/rpg/QizhenLakeScene.ts:2139](../src/scenes/rpg/QizhenLakeScene.ts#L2139)；[src/scenes/rpg/QizhenLakeScene.ts:2196](../src/scenes/rpg/QizhenLakeScene.ts#L2196)；[src/scenes/rpg/QizhenLakeScene.ts:2300](../src/scenes/rpg/QizhenLakeScene.ts#L2300)；[src/scenes/rpg/QizhenLakeScene.ts:2501](../src/scenes/rpg/QizhenLakeScene.ts#L2501)；[src/scenes/rpg/QizhenLakeScene.ts:2505](../src/scenes/rpg/QizhenLakeScene.ts#L2505)；[src/scenes/rpg/QizhenLakeScene.ts:2523](../src/scenes/rpg/QizhenLakeScene.ts#L2523)；[src/scenes/rpg/QizhenLakeScene.ts:2527](../src/scenes/rpg/QizhenLakeScene.ts#L2527)；[src/scenes/rpg/QizhenLakeScene.ts:2533](../src/scenes/rpg/QizhenLakeScene.ts#L2533)；[src/scenes/rpg/QizhenLakeScene.ts:2547](../src/scenes/rpg/QizhenLakeScene.ts#L2547)；[src/scenes/rpg/QizhenLakeScene.ts:2562](../src/scenes/rpg/QizhenLakeScene.ts#L2562)；[src/scenes/rpg/QizhenLakeScene.ts:2621](../src/scenes/rpg/QizhenLakeScene.ts#L2621)；[src/scenes/rpg/QizhenLakeScene.ts:2947](../src/scenes/rpg/QizhenLakeScene.ts#L2947)；[src/scenes/rpg/QizhenLakeScene.ts:2953](../src/scenes/rpg/QizhenLakeScene.ts#L2953)；[src/scenes/rpg/QizhenLakeScene.ts:2957](../src/scenes/rpg/QizhenLakeScene.ts#L2957)；[src/scenes/rpg/QizhenLakeScene.ts:2961](../src/scenes/rpg/QizhenLakeScene.ts#L2961)；[src/scenes/rpg/QizhenLakeScene.ts:2965](../src/scenes/rpg/QizhenLakeScene.ts#L2965)；[src/scenes/rpg/QizhenLakeScene.ts:2975](../src/scenes/rpg/QizhenLakeScene.ts#L2975)；[src/scenes/rpg/QizhenLakeScene.ts:3487](../src/scenes/rpg/QizhenLakeScene.ts#L3487)；[src/scenes/rpg/TheaterInteriorScene.ts:1024](../src/scenes/rpg/TheaterInteriorScene.ts#L1024)；[src/scenes/rpg/TheaterInteriorScene.ts:1032](../src/scenes/rpg/TheaterInteriorScene.ts#L1032)；[src/scenes/rpg/TheaterInteriorScene.ts:1036](../src/scenes/rpg/TheaterInteriorScene.ts#L1036)；[src/scenes/rpg/TheaterInteriorScene.ts:1041](../src/scenes/rpg/TheaterInteriorScene.ts#L1041)；[src/scenes/rpg/TheaterInteriorScene.ts:1074](../src/scenes/rpg/TheaterInteriorScene.ts#L1074)；[src/scenes/rpg/TheaterInteriorScene.ts:1095](../src/scenes/rpg/TheaterInteriorScene.ts#L1095)；[src/scenes/rpg/TheaterInteriorScene.ts:1197](../src/scenes/rpg/TheaterInteriorScene.ts#L1197)；[src/scenes/rpg/TheaterInteriorScene.ts:1236](../src/scenes/rpg/TheaterInteriorScene.ts#L1236)；[src/scenes/rpg/TheaterInteriorScene.ts:1245](../src/scenes/rpg/TheaterInteriorScene.ts#L1245)；[src/scenes/rpg/TheaterInteriorScene.ts:1291](../src/scenes/rpg/TheaterInteriorScene.ts#L1291)；[src/scenes/rpg/TheaterInteriorScene.ts:1297](../src/scenes/rpg/TheaterInteriorScene.ts#L1297)；[src/scenes/rpg/TheaterInteriorScene.ts:1714](../src/scenes/rpg/TheaterInteriorScene.ts#L1714)
545. 系统：它可能只是来体验一下排队，很多东西在食堂都会排队。
   来源：[src/data/chapter3-story-lines.json:20](../src/data/chapter3-story-lines.json#L20)
546. Maybe it only came to experience the queue. Many things end up queuing in a cafeteria.
   来源：[src/data/chapter3-story-lines.json:21](../src/data/chapter3-story-lines.json#L21)
547. 系统：因为你现在需要钱，而它们需要劳动力。
   来源：[src/data/chapter3-story-lines.json:29](../src/data/chapter3-story-lines.json#L29)
548. Because you need money, and they need labor.
   来源：[src/data/chapter3-story-lines.json:30](../src/data/chapter3-story-lines.json#L30)
549. 系统：它看起来不像纸条会吃的东西，虽然纸条也不该吃东西。
   来源：[src/data/chapter3-story-lines.json:38](../src/data/chapter3-story-lines.json#L38)
550. That does not look like something a paper slip would eat. Admittedly, paper should not eat at all.
   来源：[src/data/chapter3-story-lines.json:39](../src/data/chapter3-story-lines.json#L39)
551. 系统：不是，是一份比较真实的早饭。
   来源：[src/data/chapter3-story-lines.json:47](../src/data/chapter3-story-lines.json#L47)
552. No. It is merely a disappointingly real breakfast.
   来源：[src/data/chapter3-story-lines.json:48](../src/data/chapter3-story-lines.json#L48)
553. 系统：纸包鸡。我知道的至少前两个字很有嫌疑。
   来源：[src/data/chapter3-story-lines.json:56](../src/data/chapter3-story-lines.json#L56)
554. Paper-wrapped chicken. At least the first word is suspicious.
   来源：[src/data/chapter3-story-lines.json:57](../src/data/chapter3-story-lines.json#L57)
555. 系统：一份线索。鸡只是包装。
   来源：[src/data/chapter3-story-lines.json:65](../src/data/chapter3-story-lines.json#L65)
556. One clue. The chicken is only packaging.
   来源：[src/data/chapter3-story-lines.json:66](../src/data/chapter3-story-lines.json#L66)
557. 系统：这份粥很热，但线索很冷。
   来源：[src/data/chapter3-story-lines.json:74](../src/data/chapter3-story-lines.json#L74)
558. The congee is hot. The clue is cold.
   来源：[src/data/chapter3-story-lines.json:75](../src/data/chapter3-story-lines.json#L75)
559. 系统：请不要拓展世界观。
   来源：[src/data/chapter3-story-lines.json:83](../src/data/chapter3-story-lines.json#L83)
560. Please do not expand the worldbuilding.
   来源：[src/data/chapter3-story-lines.json:84](../src/data/chapter3-story-lines.json#L84)
561. narrator
   来源：[src/data/chapter3-story-lines.json:90](../src/data/chapter3-story-lines.json#L90)；[src/data/chapter3-story-lines.json:99](../src/data/chapter3-story-lines.json#L99)；[src/data/chapter3-story-lines.json:117](../src/data/chapter3-story-lines.json#L117)；[src/data/chapter3-story-lines.json:153](../src/data/chapter3-story-lines.json#L153)；[src/data/chapter3-story-lines.json:324](../src/data/chapter3-story-lines.json#L324)；[src/scenes/rpg/CanteenInteriorScene.ts:1985](../src/scenes/rpg/CanteenInteriorScene.ts#L1985)；[src/scenes/rpg/QizhenLakeScene.ts:955](../src/scenes/rpg/QizhenLakeScene.ts#L955)；[src/scenes/rpg/QizhenLakeScene.ts:959](../src/scenes/rpg/QizhenLakeScene.ts#L959)；[src/scenes/rpg/QizhenLakeScene.ts:1076](../src/scenes/rpg/QizhenLakeScene.ts#L1076)；[src/scenes/rpg/QizhenLakeScene.ts:2542](../src/scenes/rpg/QizhenLakeScene.ts#L2542)；[src/scenes/rpg/QizhenLakeScene.ts:3391](../src/scenes/rpg/QizhenLakeScene.ts#L3391)；[src/scenes/rpg/QizhenLakeScene.ts:3420](../src/scenes/rpg/QizhenLakeScene.ts#L3420)；[src/scenes/rpg/TheaterInteriorScene.ts:1205](../src/scenes/rpg/TheaterInteriorScene.ts#L1205)
562. 纸条撞回食堂，掉下一点蓝光。
   来源：[src/data/chapter3-story-lines.json:92](../src/data/chapter3-story-lines.json#L92)
563. The paper crashes back into the cafeteria and sheds a flicker of blue light.
   来源：[src/data/chapter3-story-lines.json:93](../src/data/chapter3-story-lines.json#L93)
564. 纸条急了，它开始不尊重取餐流程。
   来源：[src/data/chapter3-story-lines.json:101](../src/data/chapter3-story-lines.json#L101)
565. The paper is getting desperate. It has stopped respecting the pickup procedure.
   来源：[src/data/chapter3-story-lines.json:102](../src/data/chapter3-story-lines.json#L102)
566. 系统：自助服务发展到这一步，我有点害怕。
   来源：[src/data/chapter3-story-lines.json:110](../src/data/chapter3-story-lines.json#L110)
567. Self-service has advanced too far. I am mildly concerned.
   来源：[src/data/chapter3-story-lines.json:111](../src/data/chapter3-story-lines.json#L111)
568. The paper flees along the main road.
   来源：[src/data/chapter3-story-lines.json:120](../src/data/chapter3-story-lines.json#L120)
569. 系统：你正在以“没吃早饭的人类速度”移动。
   来源：[src/data/chapter3-story-lines.json:128](../src/data/chapter3-story-lines.json#L128)
570. You are moving at the speed of a human who skipped breakfast.
   来源：[src/data/chapter3-story-lines.json:129](../src/data/chapter3-story-lines.json#L129)
571. 系统：它没有绩点负担。
   来源：[src/data/chapter3-story-lines.json:137](../src/data/chapter3-story-lines.json#L137)
572. It carries no grade-point burden.
   来源：[src/data/chapter3-story-lines.json:138](../src/data/chapter3-story-lines.json#L138)
573. 系统：这句话在本游戏里出现频率太高了。
   来源：[src/data/chapter3-story-lines.json:146](../src/data/chapter3-story-lines.json#L146)
574. That sentence occurs far too often in this game.
   来源：[src/data/chapter3-story-lines.json:147](../src/data/chapter3-story-lines.json#L147)
575. 旁白：失败得很慷慨。
   来源：[src/data/chapter3-story-lines.json:155](../src/data/chapter3-story-lines.json#L155)
576. A remarkably generous failure.
   来源：[src/data/chapter3-story-lines.json:156](../src/data/chapter3-story-lines.json#L156)
577. 系统：这场演出本来也没什么逻辑。
   来源：[src/data/chapter3-story-lines.json:164](../src/data/chapter3-story-lines.json#L164)；[src/data/chapter3-theater.content.json:110](../src/data/chapter3-theater.content.json#L110)
578. This performance never had much logic to begin with.
   来源：[src/data/chapter3-story-lines.json:165](../src/data/chapter3-story-lines.json#L165)
579. 系统：whooooo！
   来源：[src/data/chapter3-story-lines.json:173](../src/data/chapter3-story-lines.json#L173)；[src/data/chapter3-theater.content.json:153](../src/data/chapter3-theater.content.json#L153)
580. Whooooo!
   来源：[src/data/chapter3-story-lines.json:174](../src/data/chapter3-story-lines.json#L174)
581. 系统：哦，可能纸类之间有一些我们不懂的关系。
   来源：[src/data/chapter3-story-lines.json:182](../src/data/chapter3-story-lines.json#L182)；[src/data/chapter3-theater.content.json:156](../src/data/chapter3-theater.content.json#L156)
582. Perhaps paper has relationships we do not understand.
   来源：[src/data/chapter3-story-lines.json:183](../src/data/chapter3-story-lines.json#L183)
583. 系统：不知道。它这次没有沿路掉纸屑。
   来源：[src/data/chapter3-story-lines.json:191](../src/data/chapter3-story-lines.json#L191)
584. No idea. This time it left no paper scraps along the road.
   来源：[src/data/chapter3-story-lines.json:192](../src/data/chapter3-story-lines.json#L192)
585. 系统：老办法，发个论坛问问。
   来源：[src/data/chapter3-story-lines.json:200](../src/data/chapter3-story-lines.json#L200)
586. Use the old method. Ask the campus forum.
   来源：[src/data/chapter3-story-lines.json:201](../src/data/chapter3-story-lines.json#L201)
587. 系统：CC98 提供了一个非常精确的范围：不是厕所。
   来源：[src/data/chapter3-story-lines.json:209](../src/data/chapter3-story-lines.json#L209)
588. CC98 has provided a highly precise range: not the restroom.
   来源：[src/data/chapter3-story-lines.json:210](../src/data/chapter3-story-lines.json#L210)
589. 系统：意思是它现在比我们更艺术。
   来源：[src/data/chapter3-story-lines.json:218](../src/data/chapter3-story-lines.json#L218)
590. It means the paper is currently more artistic than we are.
   来源：[src/data/chapter3-story-lines.json:219](../src/data/chapter3-story-lines.json#L219)
591. 系统：恭喜，你完成了一次校园级猜谜。
   来源：[src/data/chapter3-story-lines.json:227](../src/data/chapter3-story-lines.json#L227)
592. Congratulations. You have completed a campus-scale guessing game.
   来源：[src/data/chapter3-story-lines.json:228](../src/data/chapter3-story-lines.json#L228)
593. 系统：准确来说，是在倒影里。
   来源：[src/data/chapter3-story-lines.json:236](../src/data/chapter3-story-lines.json#L236)
594. More precisely, it is inside the reflection.
   来源：[src/data/chapter3-story-lines.json:237](../src/data/chapter3-story-lines.json#L237)
595. 系统：对不会游泳的人来说区别很大。
   来源：[src/data/chapter3-story-lines.json:245](../src/data/chapter3-story-lines.json#L245)
596. For someone who cannot swim, the difference is substantial.
   来源：[src/data/chapter3-story-lines.json:246](../src/data/chapter3-story-lines.json#L246)
597. 系统：它又消失了。
   来源：[src/data/chapter3-story-lines.json:254](../src/data/chapter3-story-lines.json#L254)
598. It disappeared again.
   来源：[src/data/chapter3-story-lines.json:255](../src/data/chapter3-story-lines.json#L255)
599. 系统：通常这里不应该有给我们指指路的牌子吗？
   来源：[src/data/chapter3-story-lines.json:263](../src/data/chapter3-story-lines.json#L263)
600. Should there not be a sign around here to point us somewhere?
   来源：[src/data/chapter3-story-lines.json:264](../src/data/chapter3-story-lines.json#L264)
601. 系统：这就是它躲藏的地方，哈
   来源：[src/data/chapter3-story-lines.json:272](../src/data/chapter3-story-lines.json#L272)
602. So this is where it is hiding. Hah.
   来源：[src/data/chapter3-story-lines.json:273](../src/data/chapter3-story-lines.json#L273)
603. 系统：把它挂到哪里去，让大家看看！
   来源：[src/data/chapter3-story-lines.json:281](../src/data/chapter3-story-lines.json#L281)
604. Hang it somewhere public. Let everyone see it.
   来源：[src/data/chapter3-story-lines.json:282](../src/data/chapter3-story-lines.json#L282)
605. 系统：就是这个假的
   来源：[src/data/chapter3-story-lines.json:290](../src/data/chapter3-story-lines.json#L290)
606. Use the fake one.
   来源：[src/data/chapter3-story-lines.json:291](../src/data/chapter3-story-lines.json#L291)
607. 系统：因为它不能接受别人替它逃跑。
   来源：[src/data/chapter3-story-lines.json:299](../src/data/chapter3-story-lines.json#L299)
608. Because it cannot tolerate someone else escaping in its place.
   来源：[src/data/chapter3-story-lines.json:300](../src/data/chapter3-story-lines.json#L300)
609. 系统：你只是让湖更有氛围了。
   来源：[src/data/chapter3-story-lines.json:308](../src/data/chapter3-story-lines.json#L308)
610. You have only made the lake more atmospheric.
   来源：[src/data/chapter3-story-lines.json:309](../src/data/chapter3-story-lines.json#L309)
611. 系统：还在嘲笑你的倒影。
   来源：[src/data/chapter3-story-lines.json:317](../src/data/chapter3-story-lines.json#L317)
612. It is still mocking your reflection.
   来源：[src/data/chapter3-story-lines.json:318](../src/data/chapter3-story-lines.json#L318)
613. 纸条从湖面倒影弹出来，贴着地面飞。
   来源：[src/data/chapter3-story-lines.json:326](../src/data/chapter3-story-lines.json#L326)
614. The paper springs out of the lake reflection and skims along the ground.
   来源：[src/data/chapter3-story-lines.json:327](../src/data/chapter3-story-lines.json#L327)
615. 系统：现在！它回到浅色模式了！
   来源：[src/data/chapter3-story-lines.json:335](../src/data/chapter3-story-lines.json#L335)
616. Now! It is back in the light layer!
   来源：[src/data/chapter3-story-lines.json:336](../src/data/chapter3-story-lines.json#L336)
617. 系统：能抓了！
   来源：[src/data/chapter3-story-lines.json:344](../src/data/chapter3-story-lines.json#L344)
618. You can catch it now!
   来源：[src/data/chapter3-story-lines.json:345](../src/data/chapter3-story-lines.json#L345)
619. 剧院
   来源：[src/data/chapter3-theater.content.json:3](../src/data/chapter3-theater.content.json#L3)
620. 进入剧院
   来源：[src/data/chapter3-theater.content.json:5](../src/data/chapter3-theater.content.json#L5)
621. 深色模式会显示被隐藏的票务信息。
   来源：[src/data/chapter3-theater.content.json:7](../src/data/chapter3-theater.content.json#L7)
622. 浅色模式可以处理现实中的玻璃、机器和票根。
   来源：[src/data/chapter3-theater.content.json:8](../src/data/chapter3-theater.content.json#L8)
623. 检票员：请出示票。
   来源：[src/data/chapter3-theater.content.json:12](../src/data/chapter3-theater.content.json#L12)
624. 玩家：我在追一张纸，让我进去。
   来源：[src/data/chapter3-theater.content.json:13](../src/data/chapter3-theater.content.json#L13)
625. 检票员：纸有票吗？
   来源：[src/data/chapter3-theater.content.json:14](../src/data/chapter3-theater.content.json#L14)
626. 玩家：它从门缝进去的。
   来源：[src/data/chapter3-theater.content.json:15](../src/data/chapter3-theater.content.json#L15)
627. 检票员：那它脸皮至少比你薄。
   来源：[src/data/chapter3-theater.content.json:16](../src/data/chapter3-theater.content.json#L16)
628. 紫金港学生剧社
   来源：[src/data/chapter3-theater.content.json:20](../src/data/chapter3-theater.content.json#L20)；[src/data/chapter3-theater.content.json:41](../src/data/chapter3-theater.content.json#L41)
629. 【求助】学生剧《7:55》临时退票，求现场帮抢
   来源：[src/data/chapter3-theater.content.json:23](../src/data/chapter3-theater.content.json#L23)
630. 刚刚
   来源：[src/data/chapter3-theater.content.json:26](../src/data/chapter3-theater.content.json#L26)
631. 学生剧《7:55》今晚在紫金港校区剧场演出。原票主临时无法到场，剧社受托把一张现场测试票放回手机票务。请确认能够按时入场再接单，具体取票规则见下方票务卡。
   来源：[src/data/chapter3-theater.content.json:27](../src/data/chapter3-theater.content.json#L27)
632. 紫金港学生剧社 · 2026 秋季原创作品
   来源：[src/data/chapter3-theater.content.json:29](../src/data/chapter3-theater.content.json#L29)
633. 学生剧《7:55》
   来源：[src/data/chapter3-theater.content.json:30](../src/data/chapter3-theater.content.json#L30)
634. 所有钟表停在同一分钟，记忆仍在继续。
   来源：[src/data/chapter3-theater.content.json:31](../src/data/chapter3-theater.content.json#L31)
635. 学生剧《7:55》像素海报：深蓝幕布、指向七点五十五分的时钟、聚光灯下的节目单和票根
   来源：[src/data/chapter3-theater.content.json:32](../src/data/chapter3-theater.content.json#L32)
636. 散场广播响起后，一名迟到的学生仍在寻找自己的座位。他穿过三次散场、两条相同的走廊，以及一场反复重来的谢幕。舞台记录着同一个时间，观众保留着不同版本的昨晚。
   来源：[src/data/chapter3-theater.content.json:33](../src/data/chapter3-theater.content.json#L33)
637. 本周五 19:30
   来源：[src/data/chapter3-theater.content.json:35](../src/data/chapter3-theater.content.json#L35)
638. 演出时间
   来源：[src/data/chapter3-theater.content.json:35](../src/data/chapter3-theater.content.json#L35)
639. 开始入场
   来源：[src/data/chapter3-theater.content.json:36](../src/data/chapter3-theater.content.json#L36)
640. 演出地点
   来源：[src/data/chapter3-theater.content.json:37](../src/data/chapter3-theater.content.json#L37)
641. 紫金港校区剧场
   来源：[src/data/chapter3-theater.content.json:37](../src/data/chapter3-theater.content.json#L37)
642. 75 分钟 · 无中场休息
   来源：[src/data/chapter3-theater.content.json:38](../src/data/chapter3-theater.content.json#L38)
643. 演出时长
   来源：[src/data/chapter3-theater.content.json:38](../src/data/chapter3-theater.content.json#L38)
644. 出品
   来源：[src/data/chapter3-theater.content.json:41](../src/data/chapter3-theater.content.json#L41)
645. 文本
   来源：[src/data/chapter3-theater.content.json:42](../src/data/chapter3-theater.content.json#L42)
646. 学生剧社原创组
   来源：[src/data/chapter3-theater.content.json:42](../src/data/chapter3-theater.content.json#L42)
647. 舞台
   来源：[src/data/chapter3-theater.content.json:43](../src/data/chapter3-theater.content.json#L43)
648. 学生剧社舞台组
   来源：[src/data/chapter3-theater.content.json:43](../src/data/chapter3-theater.content.json#L43)
649. 灯光与声音
   来源：[src/data/chapter3-theater.content.json:44](../src/data/chapter3-theater.content.json#L44)
650. 剧场技术组
   来源：[src/data/chapter3-theater.content.json:44](../src/data/chapter3-theater.content.json#L44)
651. 演出含短时黑场、频闪与广播音效；有需要的观众可在前台领取提示单。
   来源：[src/data/chapter3-theater.content.json:47](../src/data/chapter3-theater.content.json#L47)
652. 19:30 后关闭正门，迟到观众将在序场结束后由工作人员引导入场。
   来源：[src/data/chapter3-theater.content.json:48](../src/data/chapter3-theater.content.json#L48)
653. 演出过程中请勿摄影或录音；谢幕结束后开放十分钟演后谈。
   来源：[src/data/chapter3-theater.content.json:49](../src/data/chapter3-theater.content.json#L49)
654. 查看完整演出档案
   来源：[src/data/chapter3-theater.content.json:51](../src/data/chapter3-theater.content.json#L51)
655. 收起演出档案
   来源：[src/data/chapter3-theater.content.json:52](../src/data/chapter3-theater.content.json#L52)
656. 大厅取票机的普通界面不显示放票时间，深色观察里应该还留着一组四位数字，可以作为放票时间的补充确认。
   来源：[src/data/chapter3-theater.content.json:54](../src/data/chapter3-theater.content.json#L54)
657. 接下现场帮抢
   来源：[src/data/chapter3-theater.content.json:55](../src/data/chapter3-theater.content.json#L55)
658. 委托待接：前往剧场前台也无法直接取票，需要先在这里接单。
   来源：[src/data/chapter3-theater.content.json:56](../src/data/chapter3-theater.content.json#L56)
659. 第一波可直接提交；大厅深色残留可补充确认 08:32。
   来源：[src/data/chapter3-theater.content.json:57](../src/data/chapter3-theater.content.json#L57)
660. 第一波将在本手机页面提交；大厅残留记录与网络切换可按任意顺序处理。
   来源：[src/data/chapter3-theater.content.json:58](../src/data/chapter3-theater.content.json#L58)
661. 第一波已结束：系统判定响应速度过慢。
   来源：[src/data/chapter3-theater.content.json:59](../src/data/chapter3-theater.content.json#L59)
662. 第一波请求已结束，手机票务页正在等待第二波：
   来源：[src/data/chapter3-theater.content.json:60](../src/data/chapter3-theater.content.json#L60)
663. 移动数据已开启，第二波已可在本手机页面提交。
   来源：[src/data/chapter3-theater.content.json:61](../src/data/chapter3-theater.content.json#L61)
664. 第二波仅接受移动数据。打开手机控制中心切换网络后再提交。
   来源：[src/data/chapter3-theater.content.json:62](../src/data/chapter3-theater.content.json#L62)
665. 第一波抢票成功。你的运气很好，但是钱包就没那么好了。
   来源：[src/data/chapter3-theater.content.json:63](../src/data/chapter3-theater.content.json#L63)
666. 第二波抢票成功。手机已收到 0832 取票码。
   来源：[src/data/chapter3-theater.content.json:64](../src/data/chapter3-theater.content.json#L64)
667. 第二波抢票成功，取票码 0832 已写入手机回执。
   来源：[src/data/chapter3-theater.content.json:65](../src/data/chapter3-theater.content.json#L65)
668. 你的运气很好，但是钱包就没那么好了。
   来源：[src/data/chapter3-theater.content.json:66](../src/data/chapter3-theater.content.json#L66)
669. 手机票务 H5
   来源：[src/data/chapter3-theater.content.json:67](../src/data/chapter3-theater.content.json#L67)
670. 校园网
   来源：[src/data/chapter3-theater.content.json:68](../src/data/chapter3-theater.content.json#L68)
671. 移动数据
   来源：[src/data/chapter3-theater.content.json:69](../src/data/chapter3-theater.content.json#L69)
672. 无网络
   来源：[src/data/chapter3-theater.content.json:70](../src/data/chapter3-theater.content.json#L70)
673. 参加第一波抢票
   来源：[src/data/chapter3-theater.content.json:71](../src/data/chapter3-theater.content.json#L71)；[src/data/chapter3-theater.content.json:73](../src/data/chapter3-theater.content.json#L73)
674. 参加第二波抢票
   来源：[src/data/chapter3-theater.content.json:72](../src/data/chapter3-theater.content.json#L72)
675. 打开控制中心切换网络
   来源：[src/data/chapter3-theater.content.json:74](../src/data/chapter3-theater.content.json#L74)
676. 需要移动数据
   来源：[src/data/chapter3-theater.content.json:75](../src/data/chapter3-theater.content.json#L75)
677. 第二波倒计时
   来源：[src/data/chapter3-theater.content.json:76](../src/data/chapter3-theater.content.json#L76)
678. 第二波已开放
   来源：[src/data/chapter3-theater.content.json:77](../src/data/chapter3-theater.content.json#L77)
679. 剧场取票码
   来源：[src/data/chapter3-theater.content.json:78](../src/data/chapter3-theater.content.json#L78)
680. 去剧场大厅，在自助取票机输入 0832，打印半张票根 B。
   来源：[src/data/chapter3-theater.content.json:79](../src/data/chapter3-theater.content.json#L79)
681. 我已经在大厅，接下这次帮抢。
   来源：[src/data/chapter3-theater.content.json:80](../src/data/chapter3-theater.content.json#L80)
682. 系统提示：第一波请求响应超时。第二波开始前请切换到移动数据。
   来源：[src/data/chapter3-theater.content.json:81](../src/data/chapter3-theater.content.json#L81)
683. 手机票务回执：第一波抢票成功。你的运气很好，但是钱包就没那么好了。取票码 0832。
   来源：[src/data/chapter3-theater.content.json:82](../src/data/chapter3-theater.content.json#L82)
684. 手机票务回执：第二波抢票成功，取票码 0832 已生成。请到大厅取票机打印票根。
   来源：[src/data/chapter3-theater.content.json:83](../src/data/chapter3-theater.content.json#L83)
685. 检票员：没有票不能进。
   来源：[src/data/chapter3-theater.content.json:86](../src/data/chapter3-theater.content.json#L86)
686. 玻璃反光严重，你只能看见一个很需要睡觉的人。
   来源：[src/data/chapter3-theater.content.json:87](../src/data/chapter3-theater.content.json#L87)
687. 方法很脏，但有效。海报栏交出了它藏着的半张票。
   来源：[src/data/chapter3-theater.content.json:88](../src/data/chapter3-theater.content.json#L88)
688. 请输入取票码。它坚信你记得自己没买过的票。
   来源：[src/data/chapter3-theater.content.json:89](../src/data/chapter3-theater.content.json#L89)
689. 0832 号，两波释放，当前未取票。
   来源：[src/data/chapter3-theater.content.json:90](../src/data/chapter3-theater.content.json#L90)
690. 取票机：查无此票。你的观演资格仍停留在想象中。
   来源：[src/data/chapter3-theater.content.json:91](../src/data/chapter3-theater.content.json#L91)
691. 取票机：当前没有已确认的代取委托。先在手机 CC98 接单。
   来源：[src/data/chapter3-theater.content.json:92](../src/data/chapter3-theater.content.json#L92)
692. 取票机：手机票务页尚未抢到票。请先回到 CC98 帖子完成放票。
   来源：[src/data/chapter3-theater.content.json:93](../src/data/chapter3-theater.content.json#L93)
693. 取票机：取票码核验通过，半张票根 B 已打印并进入物品栏。
   来源：[src/data/chapter3-theater.content.json:94](../src/data/chapter3-theater.content.json#L94)
694. 检票员：这张票为什么有两种字体？
   来源：[src/data/chapter3-theater.content.json:96](../src/data/chapter3-theater.content.json#L96)
695. 玩家：艺术效果。
   来源：[src/data/chapter3-theater.content.json:97](../src/data/chapter3-theater.content.json#L97)
696. 检票员：好的，剧院接受艺术效果。
   来源：[src/data/chapter3-theater.content.json:98](../src/data/chapter3-theater.content.json#L98)
697. 取得节目单残页，确认节目顺序。
   来源：[src/data/chapter3-theater.content.json:102](../src/data/chapter3-theater.content.json#L102)
698. 灯控台：请输入节目顺序。
   来源：[src/data/chapter3-theater.content.json:103](../src/data/chapter3-theater.content.json#L103)
699. 当前状态：追光灯锁定。
   来源：[src/data/chapter3-theater.content.json:104](../src/data/chapter3-theater.content.json#L104)
700. 普通节目单，看起来很会假装正式。
   来源：[src/data/chapter3-theater.content.json:105](../src/data/chapter3-theater.content.json#L105)
701. 荧光编号藏在三张节目单的简介里。打开道具栏逐张查看。
   来源：[src/data/chapter3-theater.content.json:106](../src/data/chapter3-theater.content.json#L106)
702. 荧光编号还散在三张节目单简介里；深色观察与浅色收集可以任意顺序完成。
   来源：[src/data/chapter3-theater.content.json:107](../src/data/chapter3-theater.content.json#L107)
703. 灯控台：节目逻辑不成立。
   来源：[src/data/chapter3-theater.content.json:109](../src/data/chapter3-theater.content.json#L109)
704. 追光灯解锁。
   来源：[src/data/chapter3-theater.content.json:112](../src/data/chapter3-theater.content.json#L112)
705. 开场
   来源：[src/data/chapter3-theater.content.json:114](../src/data/chapter3-theater.content.json#L114)
706. 追光
   来源：[src/data/chapter3-theater.content.json:115](../src/data/chapter3-theater.content.json#L115)
707. 谢幕
   来源：[src/data/chapter3-theater.content.json:116](../src/data/chapter3-theater.content.json#L116)
708. 让纸条留下能够被追光灯识别的痕迹。
   来源：[src/data/chapter3-theater.content.json:120](../src/data/chapter3-theater.content.json#L120)
709. 锁住了。它看起来非常相信流程。
   来源：[src/data/chapter3-theater.content.json:121](../src/data/chapter3-theater.content.json#L121)
710. 道具箱已经空了，荧光粉刷等着去后台通风口。
   来源：[src/data/chapter3-theater.content.json:122](../src/data/chapter3-theater.content.json#L122)
711. 箱内有荧光粉刷的残影，但你摸不到 7:55 的东西。
   来源：[src/data/chapter3-theater.content.json:123](../src/data/chapter3-theater.content.json#L123)
712. 会谢幕的道具才能出箱。
   来源：[src/data/chapter3-theater.content.json:124](../src/data/chapter3-theater.content.json#L124)
713. 验票口沉默片刻，承认了这张票的艺术性。
   来源：[src/data/chapter3-theater.content.json:125](../src/data/chapter3-theater.content.json#L125)
714. 粉末被风吹上舞台。现在连借口都会发光。
   来源：[src/data/chapter3-theater.content.json:126](../src/data/chapter3-theater.content.json#L126)
715. 观察路径残影或直接试灯，用追光灯连续照中纸条三次。
   来源：[src/data/chapter3-theater.content.json:129](../src/data/chapter3-theater.content.json#L129)
716. 前往观众席右侧灯控台，将追光灯遥控器拖入控制台。
   来源：[src/data/chapter3-theater.content.json:130](../src/data/chapter3-theater.content.json#L130)
717. 把追光灯遥控器拖入灯控台的蓝色投放框。
   来源：[src/data/chapter3-theater.content.json:131](../src/data/chapter3-theater.content.json#L131)
718. 观察纸条的移动路径；深色模式会显示更完整的尾迹。
   来源：[src/data/chapter3-theater.content.json:132](../src/data/chapter3-theater.content.json#L132)
719. 浅色模式：预置追光灯，等纸条进入光圈后持续照射。
   来源：[src/data/chapter3-theater.content.json:133](../src/data/chapter3-theater.content.json#L133)
720. 拖动滑轨或按左右键移动追光灯；按住照射键或空格完成锁定。
   来源：[src/data/chapter3-theater.content.json:134](../src/data/chapter3-theater.content.json#L134)
721. 检查灯位、开启时机和连续照射时间。
   来源：[src/data/chapter3-theater.content.json:135](../src/data/chapter3-theater.content.json#L135)
722. 纸条已离开舞台，本轮没有完成锁定。
   来源：[src/data/chapter3-theater.content.json:136](../src/data/chapter3-theater.content.json#L136)
723. 连续锁定
   来源：[src/data/chapter3-theater.content.json:137](../src/data/chapter3-theater.content.json#L137)
724. 按住照射
   来源：[src/data/chapter3-theater.content.json:138](../src/data/chapter3-theater.content.json#L138)
725. 辅助已开启：残影延长，命中范围扩大。
   来源：[src/data/chapter3-theater.content.json:139](../src/data/chapter3-theater.content.json#L139)
726. 灯位不符。重新观察纸条最后进入的灯区。
   来源：[src/data/chapter3-theater.content.json:141](../src/data/chapter3-theater.content.json#L141)
727. 没有开启追光灯。纸条进入灯区时按住照射。
   来源：[src/data/chapter3-theater.content.json:142](../src/data/chapter3-theater.content.json#L142)
728. 照射开启过早，纸条在进入灯区前改变了路线。
   来源：[src/data/chapter3-theater.content.json:143](../src/data/chapter3-theater.content.json#L143)
729. 照射开启过晚，纸条已经离开灯区。
   来源：[src/data/chapter3-theater.content.json:144](../src/data/chapter3-theater.content.json#L144)
730. 照射中断。需要保持光圈与纸条连续重合。
   来源：[src/data/chapter3-theater.content.json:145](../src/data/chapter3-theater.content.json#L145)
731. 纸条已经离开舞台，本轮重新开始。
   来源：[src/data/chapter3-theater.content.json:146](../src/data/chapter3-theater.content.json#L146)
732. 它避开了追光灯。当前轮次重新开始。
   来源：[src/data/chapter3-theater.content.json:148](../src/data/chapter3-theater.content.json#L148)
733. 追光命中。
   来源：[src/data/chapter3-theater.content.json:149](../src/data/chapter3-theater.content.json#L149)
734. 它把被抓也写进了流程。
   来源：[src/data/chapter3-theater.content.json:150](../src/data/chapter3-theater.content.json#L150)
735. 玩家：抓到了！
   来源：[src/data/chapter3-theater.content.json:152](../src/data/chapter3-theater.content.json#L152)
736. 玩家：......
   来源：[src/data/chapter3-theater.content.json:154](../src/data/chapter3-theater.content.json#L154)
737. 玩家：它还会替身？
   来源：[src/data/chapter3-theater.content.json:155](../src/data/chapter3-theater.content.json#L155)
738. 找出纸条下一站
   来源：[src/data/chapter3-theater.content.json:160](../src/data/chapter3-theater.content.json#L160)
739. 纸条这次没有留下连续脚印。
   来源：[src/data/chapter3-theater.content.json:162](../src/data/chapter3-theater.content.json#L162)
740. 湿掉的节目单可以用于查询不同来源。
   来源：[src/data/chapter3-theater.content.json:163](../src/data/chapter3-theater.content.json#L163)
741. 手机地图需要三条相互独立的地点特征。
   来源：[src/data/chapter3-theater.content.json:164](../src/data/chapter3-theater.content.json#L164)
742. 已切换到深色观察：读取残影与异常痕迹，不搬动实体。
   来源：[src/data/chapter3-theater.content.json:168](../src/data/chapter3-theater.content.json#L168)
743. 已切换到浅色操作：可以拖放道具、清洁玻璃和操作设备。
   来源：[src/data/chapter3-theater.content.json:169](../src/data/chapter3-theater.content.json#L169)
744. 这里暂时没有要处理的事。
   来源：[src/data/chapter3-theater.content.json:172](../src/data/chapter3-theater.content.json#L172)
745. 先走到设备前的可站立位置再操作。
   来源：[src/data/chapter3-theater.content.json:173](../src/data/chapter3-theater.content.json#L173)
746. 先走近一点再操作。
   来源：[src/data/chapter3-theater.content.json:174](../src/data/chapter3-theater.content.json#L174)
747. 任务更新：找齐三张节目单残页，确认节目顺序。
   来源：[src/data/chapter3-theater.content.json:177](../src/data/chapter3-theater.content.json#L177)
748. 任务更新：让纸条留下能被追光灯识别的痕迹。
   来源：[src/data/chapter3-theater.content.json:178](../src/data/chapter3-theater.content.json#L178)
749. 任务更新：把追光灯遥控器拖到观众席右侧灯控台。
   来源：[src/data/chapter3-theater.content.json:179](../src/data/chapter3-theater.content.json#L179)
750. 任务更新：观察残影路径，用追光灯连续照中纸条三次。
   来源：[src/data/chapter3-theater.content.json:180](../src/data/chapter3-theater.content.json#L180)
751. 任务更新：看清纸条真正的去向。
   来源：[src/data/chapter3-theater.content.json:181](../src/data/chapter3-theater.content.json#L181)
752. 任务更新：从剧院出口离开，追查纸条的下一站。
   来源：[src/data/chapter3-theater.content.json:182](../src/data/chapter3-theater.content.json#L182)
753. 022 已恢复
   来源：[src/data/presentation-cues.ts:209](../src/data/presentation-cues.ts#L209)
754. 点击座位并联系异常意识
   来源：[src/data/presentation-cues.ts:210](../src/data/presentation-cues.ts#L210)
755. 抵达东区大食堂
   来源：[src/data/presentation-cues.ts:218](../src/data/presentation-cues.ts#L218)
756. 继续追踪逃进食堂的记录纸条
   来源：[src/data/presentation-cues.ts:219](../src/data/presentation-cues.ts#L219)
757. 当前剧情阶段不能重新进入大食堂。
   来源：[src/demos/campus-map-demo.tsx:202](../src/demos/campus-map-demo.tsx#L202)
758. 正在进入大食堂剧情…
   来源：[src/demos/campus-map-demo.tsx:202](../src/demos/campus-map-demo.tsx#L202)
759. 先完成当前食堂剧情，纸条被截住后才能离开。
   来源：[src/demos/campus-map-demo.tsx:205](../src/demos/campus-map-demo.tsx#L205)
760. 已进入大食堂：跟随剧情提示，先找出纸条碰过的餐盘。
   来源：[src/demos/campus-map-demo.tsx:215](../src/demos/campus-map-demo.tsx#L215)
761. 大食堂剧情已开始：沿脚印到入口，按空格进入。
   来源：[src/demos/campus-map-demo.tsx:217](../src/demos/campus-map-demo.tsx#L217)
762. 大地图已就绪：道路可走，建筑与绿地保持阻挡。
   来源：[src/demos/campus-map-demo.tsx:219](../src/demos/campus-map-demo.tsx#L219)
763. 已到达基础图书馆入口。当前大地图路线保持开放。
   来源：[src/demos/campus-map-demo.tsx:222](../src/demos/campus-map-demo.tsx#L222)
764. archived
   来源：[src/modules/ChapterThreePhoneInterludeController.ts:108](../src/modules/ChapterThreePhoneInterludeController.ts#L108)；[src/modules/ChapterThreeQizhenLakeController.ts:1308](../src/modules/ChapterThreeQizhenLakeController.ts#L1308)；[src/modules/ChapterThreeQizhenLakeController.ts:1336](../src/modules/ChapterThreeQizhenLakeController.ts#L1336)
765. return\_to\_dock
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:324](../src/modules/ChapterThreeQizhenLakeController.ts#L324)
766. rain\_and\_equipment
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:415](../src/modules/ChapterThreeQizhenLakeController.ts#L415)
767. rescue\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:487](../src/modules/ChapterThreeQizhenLakeController.ts#L487)；[src/modules/ChapterThreeQizhenLakeController.ts:527](../src/modules/ChapterThreeQizhenLakeController.ts#L527)
768. hair\_dryer\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:489](../src/modules/ChapterThreeQizhenLakeController.ts#L489)；[src/modules/ChapterThreeQizhenLakeController.ts:529](../src/modules/ChapterThreeQizhenLakeController.ts#L529)
769. safety\_request\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:490](../src/modules/ChapterThreeQizhenLakeController.ts#L490)；[src/modules/ChapterThreeQizhenLakeController.ts:531](../src/modules/ChapterThreeQizhenLakeController.ts#L531)
770. control\_session\_required
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:532](../src/modules/ChapterThreeQizhenLakeController.ts#L532)
771. invalid\_control\_summary
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:538](../src/modules/ChapterThreeQizhenLakeController.ts#L538)
772. rain\_safety\_hold
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:584](../src/modules/ChapterThreeQizhenLakeController.ts#L584)
773. qizhen\_escape\_completed
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1032](../src/modules/ChapterThreeQizhenLakeController.ts#L1032)
774. capture\_ready
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1086](../src/modules/ChapterThreeQizhenLakeController.ts#L1086)；[src/modules/ChapterThreeQizhenLakeController.ts:1143](../src/modules/ChapterThreeQizhenLakeController.ts#L1143)；[src/modules/ChapterThreeQizhenLakeController.ts:1182](../src/modules/ChapterThreeQizhenLakeController.ts#L1182)；[src/modules/QizhenJournalModel.ts:224](../src/modules/QizhenJournalModel.ts#L224)
775. inactive
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1112](../src/modules/ChapterThreeQizhenLakeController.ts#L1112)；[src/modules/ChapterThreeQizhenLakeController.ts:1353](../src/modules/ChapterThreeQizhenLakeController.ts#L1353)
776. swan\_chase
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1114](../src/modules/ChapterThreeQizhenLakeController.ts#L1114)；[src/modules/ChapterThreeQizhenLakeController.ts:1307](../src/modules/ChapterThreeQizhenLakeController.ts#L1307)；[src/modules/ChapterThreeQizhenLakeController.ts:1335](../src/modules/ChapterThreeQizhenLakeController.ts#L1335)；[src/modules/ChapterThreeQizhenLakeController.ts:1355](../src/modules/ChapterThreeQizhenLakeController.ts#L1355)；[src/scenes/rpg/QizhenLakeScene.ts:1042](../src/scenes/rpg/QizhenLakeScene.ts#L1042)
777. journal\_archived
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1115](../src/modules/ChapterThreeQizhenLakeController.ts#L1115)；[src/modules/QizhenJournalModel.ts:204](../src/modules/QizhenJournalModel.ts#L204)
778. journal\_locked
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1117](../src/modules/ChapterThreeQizhenLakeController.ts#L1117)；[src/modules/ChapterThreeQizhenLakeController.ts:1318](../src/modules/ChapterThreeQizhenLakeController.ts#L1318)；[src/modules/ChapterThreeQizhenLakeController.ts:1337](../src/modules/ChapterThreeQizhenLakeController.ts#L1337)；[src/modules/QizhenJournalModel.ts:203](../src/modules/QizhenJournalModel.ts#L203)
779. draft\_mismatch
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1119](../src/modules/ChapterThreeQizhenLakeController.ts#L1119)
780. orphan\_photo
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1121](../src/modules/ChapterThreeQizhenLakeController.ts#L1121)
781. incomplete\_draft
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1123](../src/modules/ChapterThreeQizhenLakeController.ts#L1123)；[src/modules/ChapterThreeQizhenLakeController.ts:1125](../src/modules/ChapterThreeQizhenLakeController.ts#L1125)；[src/modules/ChapterThreeQizhenLakeController.ts:1233](../src/modules/ChapterThreeQizhenLakeController.ts#L1233)；[src/modules/ChapterThreeQizhenLakeController.ts:1323](../src/modules/ChapterThreeQizhenLakeController.ts#L1323)
782. main\_draft
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1182](../src/modules/ChapterThreeQizhenLakeController.ts#L1182)；[src/modules/QizhenJournalModel.ts:224](../src/modules/QizhenJournalModel.ts#L224)
783. open
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1247](../src/modules/ChapterThreeQizhenLakeController.ts#L1247)
784. already\_published
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1316](../src/modules/ChapterThreeQizhenLakeController.ts#L1316)
785. no\_draft
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1319](../src/modules/ChapterThreeQizhenLakeController.ts#L1319)；[src/modules/ChapterThreeQizhenLakeController.ts:1322](../src/modules/ChapterThreeQizhenLakeController.ts#L1322)
786. offline
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1324](../src/modules/ChapterThreeQizhenLakeController.ts#L1324)；[src/modules/ChapterThreeQizhenLakeController.ts:1345](../src/modules/ChapterThreeQizhenLakeController.ts#L1345)
787. not\_open
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1339](../src/modules/ChapterThreeQizhenLakeController.ts#L1339)
788. no\_photo
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1344](../src/modules/ChapterThreeQizhenLakeController.ts#L1344)
789. locked
   来源：[src/modules/QizhenJournalModel.ts:130](../src/modules/QizhenJournalModel.ts#L130)；[src/scenes/phone/P18_Photos/index.tsx:197](../src/scenes/phone/P18_Photos/index.tsx#L197)；[src/scenes/rpg/CanteenInteriorScene.ts:2405](../src/scenes/rpg/CanteenInteriorScene.ts#L2405)；[src/scenes/rpg/TheaterInteriorScene.ts:1421](../src/scenes/rpg/TheaterInteriorScene.ts#L1421)；[src/scenes/rpg/TheaterInteriorScene.ts:1429](../src/scenes/rpg/TheaterInteriorScene.ts#L1429)
790. unknown\_spot
   来源：[src/modules/QizhenJournalModel.ts:202](../src/modules/QizhenJournalModel.ts#L202)
791. titles
   来源：[src/modules/QizhenJournalModel.ts:298](../src/modules/QizhenJournalModel.ts#L298)
792. statuses
   来源：[src/modules/QizhenJournalModel.ts:299](../src/modules/QizhenJournalModel.ts#L299)
793. spotCaptions.{{spotId}}
   来源：[src/modules/QizhenJournalModel.ts:311](../src/modules/QizhenJournalModel.ts#L311)
794. replyPools.{{poolKey}}
   来源：[src/modules/QizhenJournalModel.ts:339](../src/modules/QizhenJournalModel.ts#L339)
795. {{statusText}}。主图还没拍，等我先把船划到湖心。
   来源：[src/modules/QizhenJournalModel.ts:527](../src/modules/QizhenJournalModel.ts#L527)
796. 标签：{{labels.join("、")}}。
   来源：[src/modules/QizhenJournalModel.ts:532](../src/modules/QizhenJournalModel.ts#L532)
797. {{statusText}}。主图是在湖心按的快门，{{tagPart}}先占 1 楼，后面慢慢补。
   来源：[src/modules/QizhenJournalModel.ts:533](../src/modules/QizhenJournalModel.ts#L533)
798. （标题未定）
   来源：[src/modules/QizhenJournalModel.ts:578](../src/modules/QizhenJournalModel.ts#L578)
799. （状态未定）
   来源：[src/modules/QizhenJournalModel.ts:579](../src/modules/QizhenJournalModel.ts#L579)
800. 低层
   来源：[src/modules/QizhenWeatherControlModel.ts:12](../src/modules/QizhenWeatherControlModel.ts#L12)；[src/modules/QizhenWeatherControlModel.ts:64](../src/modules/QizhenWeatherControlModel.ts#L64)
801. 高层
   来源：[src/modules/QizhenWeatherControlModel.ts:12](../src/modules/QizhenWeatherControlModel.ts#L12)；[src/modules/QizhenWeatherControlModel.ts:48](../src/modules/QizhenWeatherControlModel.ts#L48)
802. 中层
   来源：[src/modules/QizhenWeatherControlModel.ts:12](../src/modules/QizhenWeatherControlModel.ts#L12)；[src/modules/QizhenWeatherControlModel.ts:56](../src/modules/QizhenWeatherControlModel.ts#L56)
803. {{board}}:{{view.title}}
   来源：[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:217](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L217)
804. 1楼
   来源：[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:263](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L263)
805. 楼
   来源：[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:312](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L312)；[src/scenes/phone/P02_CC98/QizhenJournalThread.tsx:339](../src/scenes/phone/P02_CC98/QizhenJournalThread.tsx#L339)
806. 学生剧《7:55》演出档案
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:12](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L12)
807. 演出档案
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:14](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L14)
808. 原创学生剧
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:15](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L15)
809. 剧情简介
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:50](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L50)
810. 演出信息
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:55](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L55)
811. 制作分工
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:67](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L67)
812. 现场须知
   来源：[src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx:79](../src/scenes/phone/P02_CC98/TheaterProductionArchive.tsx#L79)
813. {{copy.secondWaveCountdownStatus}}{{secondWaveSeconds}} 秒
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:60](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L60)
814. 这条委托当前无法接取。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:67](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L67)
815. 学生剧现场帮抢委托已接取。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:71](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L71)
816. task
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:71](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L71)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:96](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L96)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:102](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L102)
817. 第一波结束：网速过慢。请切换到移动数据。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:84](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L84)
818. 第二波要求使用移动数据。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:90](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L90)
819. 第二波抢票成功，取票码已生成。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:102](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L102)
820. 当前放票尚未开放。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:110](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L110)
821. 学生剧手机帮抢委托
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:120](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L120)
822. 待接
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:125](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L125)
823. 第一波开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:127](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L127)
824. 第二波等待
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:129](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L129)
825. 第二波开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:129](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L129)
826. 第二波已中
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:130](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L130)
827. 第一波已中
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:130](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L130)
828. 委托进度
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:134](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L134)
829. 1 接单
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:135](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L135)
830. 2 大厅记录（可选）
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:136](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L136)
831. 3 第一波
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:137](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L137)
832. 4 第二波
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:139](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L139)
833. 4 已抢到
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:139](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L139)
834. 当前网络：{{networkLabel}}
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:143](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L143)
835. 当前网络
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:144](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L144)
836. 第一波放票时间
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:156](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L156)
837. 第一波放票
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:157](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L157)
838. {{secondWaveSeconds}} 秒后开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:187](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L187)
839. 抢票成功回执
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:196](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L196)
840. 湖区云层校准
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:188](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L188)
841. 寝室吹风机
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:190](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L190)
842. 风向校准
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:191](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L191)
843. 逆风修正三层云带
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:191](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L191)
844. /3 ·
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:192](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L192)
845. 西南风持续向左推动云带
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:195](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L195)
846. 持续风力
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:196](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L196)
847. 高层 Q/E · 中层 A/D · 低层 Z/C 后退 / 前进
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:198](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L198)
848. {{control.label}}云带位置
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:213](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L213)
849. {{control.label}}{{direction === -1 ? "后退" : "前进"}}，键盘 {{key}}
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:238](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L238)
850. 进
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:249](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L249)
851. 退
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:249](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L249)
852. 三层均需操作
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:258](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L258)
853. 同步稳定
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:258](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L258)
854. 发现一条未归档的夜间接入记录。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:725](../src/scenes/phone/P13_PhoneHome/index.tsx#L725)
855. 校园网络
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:725](../src/scenes/phone/P13_PhoneHome/index.tsx#L725)
856. 打开 CC98 学生剧现场帮抢帖
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:736](../src/scenes/phone/P13_PhoneHome/index.tsx#L736)
857. CC98 · 学生剧《7:55》
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:740](../src/scenes/phone/P13_PhoneHome/index.tsx#L740)
858. 现场帮抢委托待接
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:743](../src/scenes/phone/P13_PhoneHome/index.tsx#L743)
859. 已接单，第一波待开始
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:745](../src/scenes/phone/P13_PhoneHome/index.tsx#L745)
860. 07:55:23
   来源：[src/scenes/phone/P18_Photos/index.tsx:33](../src/scenes/phone/P18_Photos/index.tsx#L33)；[src/scenes/phone/P18_Photos/index.tsx:34](../src/scenes/phone/P18_Photos/index.tsx#L34)；[src/scenes/phone/P18_Photos/index.tsx:35](../src/scenes/phone/P18_Photos/index.tsx#L35)；[src/scenes/phone/P18_Photos/index.tsx:36](../src/scenes/phone/P18_Photos/index.tsx#L36)；[src/scenes/phone/P18_Photos/index.tsx:37](../src/scenes/phone/P18_Photos/index.tsx#L37)；[src/scenes/phone/P18_Photos/index.tsx:38](../src/scenes/phone/P18_Photos/index.tsx#L38)；[src/scenes/phone/P18_Photos/index.tsx:39](../src/scenes/phone/P18_Photos/index.tsx#L39)
861. FRM 3A
   来源：[src/scenes/phone/P18_Photos/index.tsx:33](../src/scenes/phone/P18_Photos/index.tsx#L33)
862. FRM 91
   来源：[src/scenes/phone/P18_Photos/index.tsx:34](../src/scenes/phone/P18_Photos/index.tsx#L34)
863. FRM D7
   来源：[src/scenes/phone/P18_Photos/index.tsx:35](../src/scenes/phone/P18_Photos/index.tsx#L35)
864. FRM 4C
   来源：[src/scenes/phone/P18_Photos/index.tsx:36](../src/scenes/phone/P18_Photos/index.tsx#L36)
865. FRM 0F
   来源：[src/scenes/phone/P18_Photos/index.tsx:37](../src/scenes/phone/P18_Photos/index.tsx#L37)
866. FRM B2
   来源：[src/scenes/phone/P18_Photos/index.tsx:38](../src/scenes/phone/P18_Photos/index.tsx#L38)
867. FRM E8
   来源：[src/scenes/phone/P18_Photos/index.tsx:39](../src/scenes/phone/P18_Photos/index.tsx#L39)
868. 照片相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:63](../src/scenes/phone/P18_Photos/index.tsx#L63)
869. 相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:69](../src/scenes/phone/P18_Photos/index.tsx#L69)
870. 退出照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:70](../src/scenes/phone/P18_Photos/index.tsx#L70)
871. 启真湖划船
   来源：[src/scenes/phone/P18_Photos/index.tsx:79](../src/scenes/phone/P18_Photos/index.tsx#L79)；[src/scenes/phone/P18_Photos/index.tsx:108](../src/scenes/phone/P18_Photos/index.tsx#L108)
872. 张 · 来自相机
   来源：[src/scenes/phone/P18_Photos/index.tsx:80](../src/scenes/phone/P18_Photos/index.tsx#L80)
873. 恢复的项目
   来源：[src/scenes/phone/P18_Photos/index.tsx:84](../src/scenes/phone/P18_Photos/index.tsx#L84)
874. 7 张 · 帧顺序损坏
   来源：[src/scenes/phone/P18_Photos/index.tsx:85](../src/scenes/phone/P18_Photos/index.tsx#L85)
875. 校园与日常
   来源：[src/scenes/phone/P18_Photos/index.tsx:91](../src/scenes/phone/P18_Photos/index.tsx#L91)；[src/scenes/phone/P18_Photos/index.tsx:138](../src/scenes/phone/P18_Photos/index.tsx#L138)
876. 张 · 普通照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:92](../src/scenes/phone/P18_Photos/index.tsx#L92)
877. 相机照片、恢复帧和普通生活照分开归档。普通照片不会进入时间线或证据判定。
   来源：[src/scenes/phone/P18_Photos/index.tsx:94](../src/scenes/phone/P18_Photos/index.tsx#L94)
878. 启真湖划船相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:102](../src/scenes/phone/P18_Photos/index.tsx#L102)
879. 返回相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:109](../src/scenes/phone/P18_Photos/index.tsx#L109)；[src/scenes/phone/P18_Photos/index.tsx:139](../src/scenes/phone/P18_Photos/index.tsx#L139)；[src/scenes/phone/P18_Photos/index.tsx:216](../src/scenes/phone/P18_Photos/index.tsx#L216)
880. {{photo.spotId}} 相机照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:118](../src/scenes/phone/P18_Photos/index.tsx#L118)
881. 这份存档没有保留相机照片。恢复的动态照片仍可继续核验。
   来源：[src/scenes/phone/P18_Photos/index.tsx:123](../src/scenes/phone/P18_Photos/index.tsx#L123)
882. 校园与日常相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:132](../src/scenes/phone/P18_Photos/index.tsx#L132)
883. 这些照片用于补足手机相册的生活层次，不会触发剧情进度。
   来源：[src/scenes/phone/P18_Photos/index.tsx:144](../src/scenes/phone/P18_Photos/index.tsx#L144)
884. 校园与日常照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:145](../src/scenes/phone/P18_Photos/index.tsx#L145)
885. {{selectedCampusPhoto.capturedAt}} · {{selectedCampusPhoto.location}}
   来源：[src/scenes/phone/P18_Photos/index.tsx:164](../src/scenes/phone/P18_Photos/index.tsx#L164)
886. {{selectedCampusPhoto.title}}，{{selectedCampusPhoto.detail}}
   来源：[src/scenes/phone/P18_Photos/index.tsx:169](../src/scenes/phone/P18_Photos/index.tsx#L169)
887. 普通照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:172](../src/scenes/phone/P18_Photos/index.tsx#L172)
888. 不参与时间线、地点判断或物品识别。
   来源：[src/scenes/phone/P18_Photos/index.tsx:173](../src/scenes/phone/P18_Photos/index.tsx#L173)
889. 照
   来源：[src/scenes/phone/P18_Photos/index.tsx:174](../src/scenes/phone/P18_Photos/index.tsx#L174)
890. 关闭
   来源：[src/scenes/phone/P18_Photos/index.tsx:176](../src/scenes/phone/P18_Photos/index.tsx#L176)；[src/scenes/rpg/TheaterInteriorScene.ts:1485](../src/scenes/rpg/TheaterInteriorScene.ts#L1485)；[src/scenes/rpg/TheaterInteriorScene.ts:1531](../src/scenes/rpg/TheaterInteriorScene.ts#L1531)
891. accepted
   来源：[src/scenes/phone/P18_Photos/index.tsx:195](../src/scenes/phone/P18_Photos/index.tsx#L195)；[src/scenes/rpg/CanteenInteriorScene.ts:2361](../src/scenes/rpg/CanteenInteriorScene.ts#L2361)；[src/scenes/rpg/CanteenInteriorScene.ts:2427](../src/scenes/rpg/CanteenInteriorScene.ts#L2427)
892. 三帧已经恢复为一次连续的水平移动。
   来源：[src/scenes/phone/P18_Photos/index.tsx:196](../src/scenes/phone/P18_Photos/index.tsx#L196)
893. 先完成 CC98 记录收尾。
   来源：[src/scenes/phone/P18_Photos/index.tsx:198](../src/scenes/phone/P18_Photos/index.tsx#L198)
894. 这三帧的运动方向没有连续起来。
   来源：[src/scenes/phone/P18_Photos/index.tsx:200](../src/scenes/phone/P18_Photos/index.tsx#L200)
895. 对比纸条与同一根湖岸灯柱的相对位置。
   来源：[src/scenes/phone/P18_Photos/index.tsx:202](../src/scenes/phone/P18_Photos/index.tsx#L202)
896. 排除镜像和无关帧，选择能形成连续水平移动的三张照片。
   来源：[src/scenes/phone/P18_Photos/index.tsx:203](../src/scenes/phone/P18_Photos/index.tsx#L203)
897. 已恢复相册
   来源：[src/scenes/phone/P18_Photos/index.tsx:209](../src/scenes/phone/P18_Photos/index.tsx#L209)
898. 最近删除 · 已恢复
   来源：[src/scenes/phone/P18_Photos/index.tsx:215](../src/scenes/phone/P18_Photos/index.tsx#L215)
899. 重排
   来源：[src/scenes/phone/P18_Photos/index.tsx:222](../src/scenes/phone/P18_Photos/index.tsx#L222)
900. IMG\_0755\_LIVE · 帧顺序损坏
   来源：[src/scenes/phone/P18_Photos/index.tsx:222](../src/scenes/phone/P18_Photos/index.tsx#L222)
901. 选出同一段运动中连续的三帧，再按先后顺序放入。
   来源：[src/scenes/phone/P18_Photos/index.tsx:223](../src/scenes/phone/P18_Photos/index.tsx#L223)
902. {{slot + 1}} · 待选择
   来源：[src/scenes/phone/P18_Photos/index.tsx:228](../src/scenes/phone/P18_Photos/index.tsx#L228)
903. {{frame.label}}，恢复照片帧
   来源：[src/scenes/phone/P18_Photos/index.tsx:243](../src/scenes/phone/P18_Photos/index.tsx#L243)
904. 已恢复的连续帧
   来源：[src/scenes/phone/P18_Photos/index.tsx:250](../src/scenes/phone/P18_Photos/index.tsx#L250)
905. 连续帧已恢复
   来源：[src/scenes/phone/P18_Photos/index.tsx:255](../src/scenes/phone/P18_Photos/index.tsx#L255)
906. 确认照片顺序
   来源：[src/scenes/phone/P18_Photos/index.tsx:258](../src/scenes/phone/P18_Photos/index.tsx#L258)
907. 紫金港校区
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:424](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L424)
908. 剧场
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:488](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L488)
909. 求是路
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:877](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L877)
910. 剧场 →
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:882](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L882)
911. 剧院外到达转场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)
912. 食堂外上车转场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)
913. start
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)；[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
914. 角色解锁共享单车并开始骑行
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
915. 角色刹车下车并进入剧院外广场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
916. 食堂到剧院：755 米 3D 自行车追逐
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:361](../src/scenes/rpg/CanteenChaseOverlay.tsx#L361)
917. 三车道校园道路、骑车人物、前方障碍，以及两侧人行道上的校园路人
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:369](../src/scenes/rpg/CanteenChaseOverlay.tsx#L369)
918. 骑行状态
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:372](../src/scenes/rpg/CanteenChaseOverlay.tsx#L372)
919. 追纸距离
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:374](../src/scenes/rpg/CanteenChaseOverlay.tsx#L374)
920. / 755m
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:375](../src/scenes/rpg/CanteenChaseOverlay.tsx#L375)
921. 骑行进度
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:380](../src/scenes/rpg/CanteenChaseOverlay.tsx#L380)
922. 机会
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:403](../src/scenes/rpg/CanteenChaseOverlay.tsx#L403)
923. 剩余 {{view.lives}} 次机会
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:404](../src/scenes/rpg/CanteenChaseOverlay.tsx#L404)
924. 节奏提升
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
925. 拥堵升级
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
926. 最后冲刺
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
927. 换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:434](../src/scenes/rpg/CanteenChaseOverlay.tsx#L434)
928. 追逐方向
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:436](../src/scenes/rpg/CanteenChaseOverlay.tsx#L436)
929. 向左换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:437](../src/scenes/rpg/CanteenChaseOverlay.tsx#L437)
930. 向右换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:438](../src/scenes/rpg/CanteenChaseOverlay.tsx#L438)
931. 返回页面后继续
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:444](../src/scenes/rpg/CanteenChaseOverlay.tsx#L444)
932. 已暂停
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:444](../src/scenes/rpg/CanteenChaseOverlay.tsx#L444)
933. 纸条已离开 · 重新拦截
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:197](../src/scenes/rpg/CanteenDefenseRuntime.ts#L197)
934. 准备重新开始
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:198](../src/scenes/rpg/CanteenDefenseRuntime.ts#L198)
935. 守住出口 {{seconds.toString().padStart(2, "0")}} 秒
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:464](../src/scenes/rpg/CanteenDefenseRuntime.ts#L464)
936. 冲刺冷却 {{(this.dashCooldownMs / 1000).toFixed(1)}}s
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:467](../src/scenes/rpg/CanteenDefenseRuntime.ts#L467)
937. 空格：冲刺
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:467](../src/scenes/rpg/CanteenDefenseRuntime.ts#L467)
938. 蓝色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:188](../src/scenes/rpg/CanteenInteriorModel.ts#L188)
939. 白色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:200](../src/scenes/rpg/CanteenInteriorModel.ts#L200)
940. 黑色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:212](../src/scenes/rpg/CanteenInteriorModel.ts#L212)
941. 查看右侧瓶罐架
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:226](../src/scenes/rpg/CanteenInteriorModel.ts#L226)
942. 使用混合台
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:238](../src/scenes/rpg/CanteenInteriorModel.ts#L238)
943. 第五个窗口宣传灯箱空杯位
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:250](../src/scenes/rpg/CanteenInteriorModel.ts#L250)
944. 询问第三列第一个同学
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:266](../src/scenes/rpg/CanteenInteriorModel.ts#L266)
945. 1号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:312](../src/scenes/rpg/CanteenInteriorModel.ts#L312)
946. 2号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:326](../src/scenes/rpg/CanteenInteriorModel.ts#L326)
947. 3号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:340](../src/scenes/rpg/CanteenInteriorModel.ts#L340)
948. 4号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:354](../src/scenes/rpg/CanteenInteriorModel.ts#L354)
949. 5号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:368](../src/scenes/rpg/CanteenInteriorModel.ts#L368)
950. 第三窗口点餐机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:451](../src/scenes/rpg/CanteenInteriorModel.ts#L451)
951. {{cart.exitId}}出口餐盘车
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:463](../src/scenes/rpg/CanteenInteriorModel.ts#L463)
952. 食堂东南出口
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:473](../src/scenes/rpg/CanteenInteriorModel.ts#L473)
953. 前面没动，我也没动。大家都很稳定。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:184](../src/scenes/rpg/CanteenInteriorScene.ts#L184)
954. 你说的对。虽然不知道你说了什么。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:185](../src/scenes/rpg/CanteenInteriorScene.ts#L185)
955. 是啊，吃什么。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:186](../src/scenes/rpg/CanteenInteriorScene.ts#L186)
956. 今天有气泡水喝吗？
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:187](../src/scenes/rpg/CanteenInteriorScene.ts#L187)
957. 早十不慌，先来个西红柿鸡蛋。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:188](../src/scenes/rpg/CanteenInteriorScene.ts#L188)
958. 为什么早上吃西红柿鸡蛋。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:189](../src/scenes/rpg/CanteenInteriorScene.ts#L189)
959. 刚才有张纸过去了。它没拿餐盘。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:192](../src/scenes/rpg/CanteenInteriorScene.ts#L192)
960. 看手机。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:193](../src/scenes/rpg/CanteenInteriorScene.ts#L193)
961. 依旧看手机。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:194](../src/scenes/rpg/CanteenInteriorScene.ts#L194)
962. 不用问了可以坐这里。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:195](../src/scenes/rpg/CanteenInteriorScene.ts#L195)
963. 要什么？快点，后面排着呢。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:197](../src/scenes/rpg/CanteenInteriorScene.ts#L197)
964. 交谈
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:935](../src/scenes/rpg/CanteenInteriorScene.ts#L935)；[src/scenes/rpg/CanteenInteriorScene.ts:947](../src/scenes/rpg/CanteenInteriorScene.ts#L947)；[src/scenes/rpg/CanteenInteriorScene.ts:960](../src/scenes/rpg/CanteenInteriorScene.ts#L960)
965. 桌上的餐盘
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1346](../src/scenes/rpg/CanteenInteriorScene.ts#L1346)
966. 号取餐窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1427](../src/scenes/rpg/CanteenInteriorScene.ts#L1427)
967. 拖入 0755 · {{window.value}}号
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1451](../src/scenes/rpg/CanteenInteriorScene.ts#L1451)
968. 站这里 · 再拖票
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1473](../src/scenes/rpg/CanteenInteriorScene.ts#L1473)
969. 玩家：找到了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1595](../src/scenes/rpg/CanteenInteriorScene.ts#L1595)
970. 纸条：！
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1598](../src/scenes/rpg/CanteenInteriorScene.ts#L1598)
971. {{canteenContent.drinks.shelfPrompt}} / {{canteenContent.drinks.shelfOrder}}
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2017](../src/scenes/rpg/CanteenInteriorScene.ts#L2017)
972. success
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2031](../src/scenes/rpg/CanteenInteriorScene.ts#L2031)；[src/scenes/rpg/CanteenInteriorScene.ts:2094](../src/scenes/rpg/CanteenInteriorScene.ts#L2094)；[src/scenes/rpg/CanteenInteriorScene.ts:3706](../src/scenes/rpg/CanteenInteriorScene.ts#L3706)；[src/scenes/rpg/CanteenInteriorScene.ts:3832](../src/scenes/rpg/CanteenInteriorScene.ts#L3832)；[src/scenes/rpg/QizhenLakeScene.ts:2519](../src/scenes/rpg/QizhenLakeScene.ts#L2519)；[src/scenes/rpg/QizhenLakeScene.ts:2538](../src/scenes/rpg/QizhenLakeScene.ts#L2538)；[src/scenes/rpg/QizhenLakeScene.ts:2549](../src/scenes/rpg/QizhenLakeScene.ts#L2549)；[src/scenes/rpg/QizhenLakeScene.ts:2558](../src/scenes/rpg/QizhenLakeScene.ts#L2558)；[src/scenes/rpg/QizhenLakeScene.ts:2569](../src/scenes/rpg/QizhenLakeScene.ts#L2569)；[src/scenes/rpg/QizhenLakeScene.ts:2574](../src/scenes/rpg/QizhenLakeScene.ts#L2574)；[src/scenes/rpg/QizhenLakeScene.ts:2578](../src/scenes/rpg/QizhenLakeScene.ts#L2578)；[src/scenes/rpg/QizhenLakeScene.ts:2582](../src/scenes/rpg/QizhenLakeScene.ts#L2582)；[src/scenes/rpg/QizhenLakeScene.ts:2586](../src/scenes/rpg/QizhenLakeScene.ts#L2586)；[src/scenes/rpg/QizhenLakeScene.ts:2590](../src/scenes/rpg/QizhenLakeScene.ts#L2590)；[src/scenes/rpg/QizhenLakeScene.ts:2605](../src/scenes/rpg/QizhenLakeScene.ts#L2605)；[src/scenes/rpg/QizhenLakeScene.ts:2609](../src/scenes/rpg/QizhenLakeScene.ts#L2609)；[src/scenes/rpg/QizhenLakeScene.ts:2613](../src/scenes/rpg/QizhenLakeScene.ts#L2613)；[src/scenes/rpg/QizhenLakeScene.ts:2617](../src/scenes/rpg/QizhenLakeScene.ts#L2617)；[src/scenes/rpg/TheaterInteriorScene.ts:1656](../src/scenes/rpg/TheaterInteriorScene.ts#L1656)；[src/scenes/rpg/TheaterInteriorScene.ts:1731](../src/scenes/rpg/TheaterInteriorScene.ts#L1731)；[src/scenes/rpg/TheaterInteriorScene.ts:1766](../src/scenes/rpg/TheaterInteriorScene.ts#L1766)
973. 窗口正常出餐。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2094](../src/scenes/rpg/CanteenInteriorScene.ts#L2094)
974. rpg\_canteen\_tray\_task\_start\_requested
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2242](../src/scenes/rpg/CanteenInteriorScene.ts#L2242)
975. missed\_target
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2351](../src/scenes/rpg/CanteenInteriorScene.ts#L2351)；[src/scenes/rpg/CanteenInteriorScene.ts:2367](../src/scenes/rpg/CanteenInteriorScene.ts#L2367)；[src/scenes/rpg/CanteenInteriorScene.ts:2387](../src/scenes/rpg/CanteenInteriorScene.ts#L2387)；[src/scenes/rpg/TheaterInteriorScene.ts:1387](../src/scenes/rpg/TheaterInteriorScene.ts#L1387)；[src/scenes/rpg/TheaterInteriorScene.ts:1412](../src/scenes/rpg/TheaterInteriorScene.ts#L1412)
976. 玩家自己
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2362](../src/scenes/rpg/CanteenInteriorScene.ts#L2362)
977. 把难喝饮料拖到人物自己身上才能喝掉。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2368](../src/scenes/rpg/CanteenInteriorScene.ts#L2368)
978. dailySpecialSparklingWater
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2388](../src/scenes/rpg/CanteenInteriorScene.ts#L2388)
979. 请拖到第五个打饭窗口下方宣传板的发光空杯位。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2389](../src/scenes/rpg/CanteenInteriorScene.ts#L2389)
980. 小票不需要拖拽：靠近取餐窗口后按空格使用。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2390](../src/scenes/rpg/CanteenInteriorScene.ts#L2390)
981. wrong\_item
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2397](../src/scenes/rpg/CanteenInteriorScene.ts#L2397)；[src/scenes/rpg/TheaterInteriorScene.ts:1421](../src/scenes/rpg/TheaterInteriorScene.ts#L1421)
982. light
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2407](../src/scenes/rpg/CanteenInteriorScene.ts#L2407)；[src/scenes/rpg/TheaterInteriorScene.ts:1431](../src/scenes/rpg/TheaterInteriorScene.ts#L1431)
983. too\_far
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2414](../src/scenes/rpg/CanteenInteriorScene.ts#L2414)；[src/scenes/rpg/TheaterInteriorScene.ts:1438](../src/scenes/rpg/TheaterInteriorScene.ts#L1438)
984. promo
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2416](../src/scenes/rpg/CanteenInteriorScene.ts#L2416)
985. 落点正确；人物还没有靠近宣传板。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2417](../src/scenes/rpg/CanteenInteriorScene.ts#L2417)
986. 落点正确；靠近设施后再操作。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2418](../src/scenes/rpg/CanteenInteriorScene.ts#L2418)
987. 先把手上的餐盘交给阿姨
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2616](../src/scenes/rpg/CanteenInteriorScene.ts#L2616)
988. 拿起桌上的餐盘
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2617](../src/scenes/rpg/CanteenInteriorScene.ts#L2617)
989. 使用点餐机
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2619](../src/scenes/rpg/CanteenInteriorScene.ts#L2619)
990. 查看{{nearest.value}}号窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2622](../src/scenes/rpg/CanteenInteriorScene.ts#L2622)
991. 使用小票 · {{nearest.value}}号窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2624](../src/scenes/rpg/CanteenInteriorScene.ts#L2624)
992. {{nearest.value}}号取餐窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2625](../src/scenes/rpg/CanteenInteriorScene.ts#L2625)
993. 把今日新品放入宣传板空杯位
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2628](../src/scenes/rpg/CanteenInteriorScene.ts#L2628)
994. 宣传板空杯位
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2629](../src/scenes/rpg/CanteenInteriorScene.ts#L2629)
995. 确认蓝色轨迹指向
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2632](../src/scenes/rpg/CanteenInteriorScene.ts#L2632)
996. 靠近餐盘车把手
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2633](../src/scenes/rpg/CanteenInteriorScene.ts#L2633)
997. 靠近东南门离开食堂
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2635](../src/scenes/rpg/CanteenInteriorScene.ts#L2635)
998. 气泡水（蓝色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2991](../src/scenes/rpg/CanteenInteriorScene.ts#L2991)
999. 柠檬茶（白色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2992](../src/scenes/rpg/CanteenInteriorScene.ts#L2992)
1000. 黑咖啡（黑色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2993](../src/scenes/rpg/CanteenInteriorScene.ts#L2993)
1001. ← / → 选择 · 空格 / 回车确认 · Esc 退出
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3030](../src/scenes/rpg/CanteenInteriorScene.ts#L3030)
1002. 食堂新品混合台
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3142](../src/scenes/rpg/CanteenInteriorScene.ts#L3142)
1003. 退出 Esc
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3150](../src/scenes/rpg/CanteenInteriorScene.ts#L3150)
1004. 大玻璃杯
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3173](../src/scenes/rpg/CanteenInteriorScene.ts#L3173)
1005. 货架提示已记录：黑色 → 蓝色 → 白色
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3184](../src/scenes/rpg/CanteenInteriorScene.ts#L3184)
1006. 货架提示：尚未查看
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3185](../src/scenes/rpg/CanteenInteriorScene.ts#L3185)
1007. 黑咖啡
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3196](../src/scenes/rpg/CanteenInteriorScene.ts#L3196)
1008. 气泡水
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3197](../src/scenes/rpg/CanteenInteriorScene.ts#L3197)
1009. 柠檬茶
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3198](../src/scenes/rpg/CanteenInteriorScene.ts#L3198)
1010. {{button.name}}·未持有
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3212](../src/scenes/rpg/CanteenInteriorScene.ts#L3212)
1011. 倒入{{button.name}}
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3212](../src/scenes/rpg/CanteenInteriorScene.ts#L3212)
1012. 观察模式 · 菜名留下了另一层字
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3289](../src/scenes/rpg/CanteenInteriorScene.ts#L3289)
1013. 选择一份餐品 · 取餐前不能重复下单
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3290](../src/scenes/rpg/CanteenInteriorScene.ts#L3290)
1014. 玩家：那是鸡吗？
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3435](../src/scenes/rpg/CanteenInteriorScene.ts#L3435)
1015. 系统：现在不是了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3435](../src/scenes/rpg/CanteenInteriorScene.ts#L3435)
1016. 本人马上回来。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3531](../src/scenes/rpg/CanteenInteriorScene.ts#L3531)
1017. 场景仍在初始化，请稍后再试。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3665](../src/scenes/rpg/CanteenInteriorScene.ts#L3665)
1018. 纸条暂时没有找到能钻出去的流程。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3706](../src/scenes/rpg/CanteenInteriorScene.ts#L3706)
1019. 左上门
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3711](../src/scenes/rpg/CanteenInteriorScene.ts#L3711)
1020. 左中下通道
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3712](../src/scenes/rpg/CanteenInteriorScene.ts#L3712)
1021. 右下门
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3713](../src/scenes/rpg/CanteenInteriorScene.ts#L3713)
1022. 纸条从{{exitLabel\[exitId\]}}溜走了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3715](../src/scenes/rpg/CanteenInteriorScene.ts#L3715)
1023. rpg\_canteen\_leave\_requested
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3850](../src/scenes/rpg/CanteenInteriorScene.ts#L3850)
1024. 玩家：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3874](../src/scenes/rpg/CanteenInteriorScene.ts#L3874)；[src/scenes/rpg/QizhenLakeScene.ts:3154](../src/scenes/rpg/QizhenLakeScene.ts#L3154)；[src/scenes/rpg/QizhenLoopScene.ts:348](../src/scenes/rpg/QizhenLoopScene.ts#L348)；[src/scenes/rpg/TheaterInteriorScene.ts:2509](../src/scenes/rpg/TheaterInteriorScene.ts#L2509)
1025. 系统：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3875](../src/scenes/rpg/CanteenInteriorScene.ts#L3875)；[src/scenes/rpg/QizhenLakeScene.ts:3155](../src/scenes/rpg/QizhenLakeScene.ts#L3155)；[src/scenes/rpg/QizhenLoopScene.ts:349](../src/scenes/rpg/QizhenLoopScene.ts#L349)；[src/scenes/rpg/TheaterInteriorScene.ts:2510](../src/scenes/rpg/TheaterInteriorScene.ts#L2510)
1026. 任务：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3876](../src/scenes/rpg/CanteenInteriorScene.ts#L3876)；[src/scenes/rpg/QizhenLakeScene.ts:3156](../src/scenes/rpg/QizhenLakeScene.ts#L3156)；[src/scenes/rpg/QizhenLoopScene.ts:350](../src/scenes/rpg/QizhenLoopScene.ts#L350)；[src/scenes/rpg/TheaterInteriorScene.ts:2511](../src/scenes/rpg/TheaterInteriorScene.ts#L2511)
1027. 精准
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:77](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L77)
1028. 良好
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:78](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L78)
1029. 命中
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:79](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L79)
1030. 错过
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:80](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L80)
1031. 判定线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:185](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L185)
1032. 彩色音符向左移动
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:196](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L196)
1033. 准确率 {{(result.accuracy \* 100).toFixed(1)}}%
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:357](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L357)
1034. 断线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:407](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L407)
1035. 脱钩
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:407](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L407)
1036. 未通过
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:407](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L407)
1037. 辅助·
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:492](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L492)
1038. {{assistLabel}}目标：{{this.options.targetLabel}} {{this.model.judgedCount}}/{{this.model.totalNotes}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:493](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L493)
1039. 张力 {{tension}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:500](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L500)
1040. 连击 {{combo}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:501](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L501)
1041. 右收线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:730](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L730)
1042. 左收线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:730](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L730)
1043. 按住
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:739](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L739)
1044. · 稍早
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:943](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L943)
1045. · 稍晚
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:944](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L944)
1046. 器材架上的皮划艇
   来源：[src/scenes/rpg/QizhenLakeModel.ts:382](../src/scenes/rpg/QizhenLakeModel.ts#L382)
1047. 花坛边的细长物体
   来源：[src/scenes/rpg/QizhenLakeModel.ts:383](../src/scenes/rpg/QizhenLakeModel.ts#L383)
1048. 设备区的旧设施
   来源：[src/scenes/rpg/QizhenLakeModel.ts:384](../src/scenes/rpg/QizhenLakeModel.ts#L384)
1049. 小码头登船边
   来源：[src/scenes/rpg/QizhenLakeModel.ts:385](../src/scenes/rpg/QizhenLakeModel.ts#L385)
1050. 湖边值班老师
   来源：[src/scenes/rpg/QizhenLakeModel.ts:386](../src/scenes/rpg/QizhenLakeModel.ts#L386)
1051. 码头储物柜
   来源：[src/scenes/rpg/QizhenLakeModel.ts:387](../src/scenes/rpg/QizhenLakeModel.ts#L387)
1052. 划向大湖
   来源：[src/scenes/rpg/QizhenLakeModel.ts:388](../src/scenes/rpg/QizhenLakeModel.ts#L388)
1053. 返回小码头
   来源：[src/scenes/rpg/QizhenLakeModel.ts:390](../src/scenes/rpg/QizhenLakeModel.ts#L390)
1054. 前往黑天鹅围栏
   来源：[src/scenes/rpg/QizhenLakeModel.ts:391](../src/scenes/rpg/QizhenLakeModel.ts#L391)
1055. 进入浮排河道
   来源：[src/scenes/rpg/QizhenLakeModel.ts:392](../src/scenes/rpg/QizhenLakeModel.ts#L392)
1056. 纸条倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:393](../src/scenes/rpg/QizhenLakeModel.ts#L393)
1057. 钥匙倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:394](../src/scenes/rpg/QizhenLakeModel.ts#L394)
1058. 网框倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:395](../src/scenes/rpg/QizhenLakeModel.ts#L395)
1059. 鱼群倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:396](../src/scenes/rpg/QizhenLakeModel.ts#L396)
1060. 漂浮的钓鱼竿
   来源：[src/scenes/rpg/QizhenLakeModel.ts:397](../src/scenes/rpg/QizhenLakeModel.ts#L397)
1061. 纸条倒影水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:398](../src/scenes/rpg/QizhenLakeModel.ts#L398)
1062. 钥匙水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:399](../src/scenes/rpg/QizhenLakeModel.ts#L399)
1063. 鱼群聚拢的水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:400](../src/scenes/rpg/QizhenLakeModel.ts#L400)
1064. 最终钓具装配位
   来源：[src/scenes/rpg/QizhenLakeModel.ts:401](../src/scenes/rpg/QizhenLakeModel.ts#L401)
1065. 返回大湖
   来源：[src/scenes/rpg/QizhenLakeModel.ts:403](../src/scenes/rpg/QizhenLakeModel.ts#L403)；[src/scenes/rpg/QizhenLakeModel.ts:409](../src/scenes/rpg/QizhenLakeModel.ts#L409)
1066. 进入返航河道
   来源：[src/scenes/rpg/QizhenLakeModel.ts:404](../src/scenes/rpg/QizhenLakeModel.ts#L404)
1067. 围栏边的黑天鹅
   来源：[src/scenes/rpg/QizhenLakeModel.ts:405](../src/scenes/rpg/QizhenLakeModel.ts#L405)
1068. 纸条本体水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:406](../src/scenes/rpg/QizhenLakeModel.ts#L406)
1069. 黑天鹅追逐起点
   来源：[src/scenes/rpg/QizhenLakeModel.ts:408](../src/scenes/rpg/QizhenLakeModel.ts#L408)
1070. 浮排下的破损网框
   来源：[src/scenes/rpg/QizhenLakeModel.ts:410](../src/scenes/rpg/QizhenLakeModel.ts#L410)
1071. 小码头方向
   来源：[src/scenes/rpg/QizhenLakeModel.ts:411](../src/scenes/rpg/QizhenLakeModel.ts#L411)
1072. 湖心全景:朝北取景时西北柳岛与整片开阔水面入镜,船体落在画面下缘。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:499](../src/scenes/rpg/QizhenLakeModel.ts#L499)
1073. 小码头:木栈道、器材架与登船边入镜;徒步或乘艇都可取景。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:515](../src/scenes/rpg/QizhenLakeModel.ts#L515)
1074. 倒影水面
   来源：[src/scenes/rpg/QizhenLakeModel.ts:520](../src/scenes/rpg/QizhenLakeModel.ts#L520)
1075. 倒影水面:东侧倒影区入镜;水面平静时倒影完整,船速与侧倾大时水纹断开。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:526](../src/scenes/rpg/QizhenLakeModel.ts#L526)
1076. 黑天鹅围栏:从围栏外水域取景,黑天鹅在围栏内游动;鹅离开后只剩空围栏与水痕。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:538](../src/scenes/rpg/QizhenLakeModel.ts#L538)
1077. rpg\_qizhen\_intro\_seen\_requested
   来源：[src/scenes/rpg/QizhenLakeScene.ts:558](../src/scenes/rpg/QizhenLakeScene.ts#L558)
1078. {{qizhenContent.chase.caught}}{{qizhenContent.chase.failed}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1012](../src/scenes/rpg/QizhenLakeScene.ts#L1012)
1079. swan\_caught
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1014](../src/scenes/rpg/QizhenLakeScene.ts#L1014)
1080. {{qizhenContent.boarding.capsizeSameSide}}{{qizhenContent.chase.failed}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1043](../src/scenes/rpg/QizhenLakeScene.ts#L1043)
1081. 节奏钓取未能启动，道具已保留，请重试。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1860](../src/scenes/rpg/QizhenLakeScene.ts#L1860)
1082. 未通过：道具已保留。下次将扩大判定窗口并精简节拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2137](../src/scenes/rpg/QizhenLakeScene.ts#L2137)
1083. 未通过：道具已保留，靠近同一水纹可立即重试。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2138](../src/scenes/rpg/QizhenLakeScene.ts#L2138)
1084. {{qizhenContent.mist.darkPrompt}} {{formatRpgModeRequirement("light")}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2195](../src/scenes/rpg/QizhenLakeScene.ts#L2195)
1085. locker\_key
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2568](../src/scenes/rpg/QizhenLakeScene.ts#L2568)
1086. 浮排边的旧饲料盒被捞起并撬开。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2599](../src/scenes/rpg/QizhenLakeScene.ts#L2599)
1087. 饲料撒入围栏，黑天鹅把一枚磁性扣推到船边。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2600](../src/scenes/rpg/QizhenLakeScene.ts#L2600)
1088. 三处分支素材已合并，可以进行最终捕纸。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2605](../src/scenes/rpg/QizhenLakeScene.ts#L2605)
1089. player
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2906](../src/scenes/rpg/QizhenLakeScene.ts#L2906)
1090. 相机
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2915](../src/scenes/rpg/QizhenLakeScene.ts#L2915)
1091. 正在节奏钓取,收竿后再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2947](../src/scenes/rpg/QizhenLakeScene.ts#L2947)
1092. 黑天鹅正追着船尾,顾不上拍照。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2953](../src/scenes/rpg/QizhenLakeScene.ts#L2953)
1093. 这里要上船后才能取景。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2957](../src/scenes/rpg/QizhenLakeScene.ts#L2957)
1094. 船还没停稳,等一下再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2961](../src/scenes/rpg/QizhenLakeScene.ts#L2961)
1095. 先听完这段话,再打开相机。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2965](../src/scenes/rpg/QizhenLakeScene.ts#L2965)
1096. 这里构不成画面,再往{{nearest.label}}靠一靠。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2973](../src/scenes/rpg/QizhenLakeScene.ts#L2973)
1097. 河道里取景太窄,去大湖面或黑天鹅围栏旁再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2974](../src/scenes/rpg/QizhenLakeScene.ts#L2974)
1098. forced\_launch\_capsize
   来源：[src/scenes/rpg/QizhenLakeScene.ts:3425](../src/scenes/rpg/QizhenLakeScene.ts#L3425)；[src/scenes/rpg/QizhenLakeScene.ts:3438](../src/scenes/rpg/QizhenLakeScene.ts#L3438)
1099. 启真湖入口
   来源：[src/scenes/rpg/QizhenLoopScene.ts:44](../src/scenes/rpg/QizhenLoopScene.ts#L44)
1100. 查看入口
   来源：[src/scenes/rpg/QizhenLoopScene.ts:45](../src/scenes/rpg/QizhenLoopScene.ts#L45)
1101. 系统：还没确认湿纸指向的地点。先核对论坛、馆藏记录和地图线索。
   来源：[src/scenes/rpg/QizhenLoopScene.ts:46](../src/scenes/rpg/QizhenLoopScene.ts#L46)
1102. {{GATE\_ENTRY\_LABEL}} · {{formatRpgInteractionHint("进入启真湖")}}
   来源：[src/scenes/rpg/QizhenLoopScene.ts:203](../src/scenes/rpg/QizhenLoopScene.ts#L203)；[src/scenes/rpg/QizhenLoopScene.ts:237](../src/scenes/rpg/QizhenLoopScene.ts#L237)
1103. 启真湖雨天落水救援回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:60](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L60)
1104. 值班老师和安全员把落水学生拉回码头
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:71](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L71)
1105. 启真湖 · 雨天救援
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:81](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L81)
1106. 正在将落水者拉回码头
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:82](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L82)
1107. 正在载入救援回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:82](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L82)
1108. 跳过回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:88](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L88)
1109. 入口海报玻璃
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:93](../src/scenes/rpg/TheaterInteriorModel.ts#L93)
1110. 临时票打印机
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:111](../src/scenes/rpg/TheaterInteriorModel.ts#L111)
1111. 检票闸机右侧读票器
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:122](../src/scenes/rpg/TheaterInteriorModel.ts#L122)；[src/scenes/rpg/TheaterInteriorScene.ts:192](../src/scenes/rpg/TheaterInteriorScene.ts#L192)
1112. 开场节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:135](../src/scenes/rpg/TheaterInteriorModel.ts#L135)
1113. 追光节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:136](../src/scenes/rpg/TheaterInteriorModel.ts#L136)
1114. 终场节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:137](../src/scenes/rpg/TheaterInteriorModel.ts#L137)
1115. 剧院灯光控制台
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:140](../src/scenes/rpg/TheaterInteriorModel.ts#L140)
1116. 后台道具箱
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:155](../src/scenes/rpg/TheaterInteriorModel.ts#L155)
1117. 道具箱旁票据扫描器
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:165](../src/scenes/rpg/TheaterInteriorModel.ts#L165)；[src/scenes/rpg/TheaterInteriorScene.ts:193](../src/scenes/rpg/TheaterInteriorScene.ts#L193)
1118. 后台通风口
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:180](../src/scenes/rpg/TheaterInteriorModel.ts#L180)；[src/scenes/rpg/TheaterInteriorScene.ts:194](../src/scenes/rpg/TheaterInteriorScene.ts#L194)
1119. 剧院出口
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:193](../src/scenes/rpg/TheaterInteriorModel.ts#L193)；[src/scenes/rpg/TheaterInteriorScene.ts:199](../src/scenes/rpg/TheaterInteriorScene.ts#L199)
1120. 灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:130](../src/scenes/rpg/TheaterInteriorScene.ts#L130)
1121. 检票员
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:130](../src/scenes/rpg/TheaterInteriorScene.ts#L130)
1122. 取票机
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:130](../src/scenes/rpg/TheaterInteriorScene.ts#L130)；[src/scenes/rpg/TheaterInteriorScene.ts:196](../src/scenes/rpg/TheaterInteriorScene.ts#L196)
1123. 手机系统
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:130](../src/scenes/rpg/TheaterInteriorScene.ts#L130)
1124. 入口海报
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:191](../src/scenes/rpg/TheaterInteriorScene.ts#L191)
1125. 灯光控制台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:195](../src/scenes/rpg/TheaterInteriorScene.ts#L195)
1126. 节目单
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:197](../src/scenes/rpg/TheaterInteriorScene.ts#L197)
1127. 道具箱
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:198](../src/scenes/rpg/TheaterInteriorScene.ts#L198)
1128. 验票
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:670](../src/scenes/rpg/TheaterInteriorScene.ts#L670)
1129. theater\_decoy\_inspect\_requested
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1124](../src/scenes/rpg/TheaterInteriorScene.ts#L1124)
1130. dark
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1244](../src/scenes/rpg/TheaterInteriorScene.ts#L1244)；[src/scenes/rpg/TheaterInteriorScene.ts:1246](../src/scenes/rpg/TheaterInteriorScene.ts#L1246)
1131. 查看海报栏
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1316](../src/scenes/rpg/TheaterInteriorScene.ts#L1316)
1132. 油渍纸巾 → 入口海报
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1316](../src/scenes/rpg/TheaterInteriorScene.ts#L1316)
1133. 查看取票机
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1319](../src/scenes/rpg/TheaterInteriorScene.ts#L1319)；[src/scenes/rpg/TheaterInteriorScene.ts:1322](../src/scenes/rpg/TheaterInteriorScene.ts#L1322)
1134. 输入取票码
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1321](../src/scenes/rpg/TheaterInteriorScene.ts#L1321)
1135. 临时观演票 → 右侧验票槽
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1324](../src/scenes/rpg/TheaterInteriorScene.ts#L1324)
1136. 与检票员对话
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1324](../src/scenes/rpg/TheaterInteriorScene.ts#L1324)
1137. 查看残影
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1326](../src/scenes/rpg/TheaterInteriorScene.ts#L1326)
1138. 取得节目单残页
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1326](../src/scenes/rpg/TheaterInteriorScene.ts#L1326)
1139. 操作灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1328](../src/scenes/rpg/TheaterInteriorScene.ts#L1328)
1140. 追光灯遥控器 → 灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1328](../src/scenes/rpg/TheaterInteriorScene.ts#L1328)
1141. 查看道具箱
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1330](../src/scenes/rpg/TheaterInteriorScene.ts#L1330)
1142. 检查票据扫描器
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1332](../src/scenes/rpg/TheaterInteriorScene.ts#L1332)
1143. 临时观演票 → 票据扫描口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1332](../src/scenes/rpg/TheaterInteriorScene.ts#L1332)
1144. 离开剧院
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1334](../src/scenes/rpg/TheaterInteriorScene.ts#L1334)
1145. 检查后台通风口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1335](../src/scenes/rpg/TheaterInteriorScene.ts#L1335)
1146. 荧光粉刷 → 后台通风口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1335](../src/scenes/rpg/TheaterInteriorScene.ts#L1335)
1147. 票已退回：请拖到检票闸机右侧发蓝光的「验票」读票器框内。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1405](../src/scenes/rpg/TheaterInteriorScene.ts#L1405)
1148. 票已退回：请拖到道具箱旁发蓝光的票据扫描口框内。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1407](../src/scenes/rpg/TheaterInteriorScene.ts#L1407)
1149. 票已退回：当前阶段没有临时观演票的使用点。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1408](../src/scenes/rpg/TheaterInteriorScene.ts#L1408)
1150. 道具没有放到当前阶段对应的真实物体。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1409](../src/scenes/rpg/TheaterInteriorScene.ts#L1409)
1151. temporaryTheaterTicket
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1440](../src/scenes/rpg/TheaterInteriorScene.ts#L1440)
1152. gate
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1441](../src/scenes/rpg/TheaterInteriorScene.ts#L1441)
1153. 票已退回；请靠近读票器。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1442](../src/scenes/rpg/TheaterInteriorScene.ts#L1442)
1154. 票已退回；请靠近扫描器。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1443](../src/scenes/rpg/TheaterInteriorScene.ts#L1443)
1155. 退格
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1478](../src/scenes/rpg/TheaterInteriorScene.ts#L1478)
1156. 提交
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1482](../src/scenes/rpg/TheaterInteriorScene.ts#L1482)；[src/scenes/rpg/TheaterInteriorScene.ts:1528](../src/scenes/rpg/TheaterInteriorScene.ts#L1528)
1157. 撤回
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1521](../src/scenes/rpg/TheaterInteriorScene.ts#L1521)
1158. 清空
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1525](../src/scenes/rpg/TheaterInteriorScene.ts#L1525)
1159. 第 {{round + 1}} / 3 轮 · 观察
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1797](../src/scenes/rpg/TheaterInteriorScene.ts#L1797)
1160. 观察尾迹，记住最后一个灯区。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1804](../src/scenes/rpg/TheaterInteriorScene.ts#L1804)
1161. 右
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1870](../src/scenes/rpg/TheaterInteriorScene.ts#L1870)
1162. 中
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1870](../src/scenes/rpg/TheaterInteriorScene.ts#L1870)
1163. 左
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1870](../src/scenes/rpg/TheaterInteriorScene.ts#L1870)
1164. 第 {{round + 1}} / 3 轮 · 预置
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2004](../src/scenes/rpg/TheaterInteriorScene.ts#L2004)
1165. 预置追光灯
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2005](../src/scenes/rpg/TheaterInteriorScene.ts#L2005)
1166. 拖动下方滑轨，或按 ← / → 移动。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2006](../src/scenes/rpg/TheaterInteriorScene.ts#L2006)
1167. 深色观察可核对尾迹；切至浅色操作后启动追光灯。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2024](../src/scenes/rpg/TheaterInteriorScene.ts#L2024)
1168. Tab 切换模式；切换不会重置本轮观察。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2026](../src/scenes/rpg/TheaterInteriorScene.ts#L2026)
1169. 浅色操作已就绪，追光灯正在启动。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2031](../src/scenes/rpg/TheaterInteriorScene.ts#L2031)
1170. 第 {{round + 1}} / 3 轮 · 锁定
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2052](../src/scenes/rpg/TheaterInteriorScene.ts#L2052)
1171. 断裂尾迹是假残影。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2144](../src/scenes/rpg/TheaterInteriorScene.ts#L2144)
1172. 锁定中，保持照射。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2148](../src/scenes/rpg/TheaterInteriorScene.ts#L2148)
1173. 光圈脱离纸条，重新锁定。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2151](../src/scenes/rpg/TheaterInteriorScene.ts#L2151)
1174. 第 {{hitCount}} / 3 轮 · 命中
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2266](../src/scenes/rpg/TheaterInteriorScene.ts#L2266)
1175. {{theaterContent.spotlight.hit}} 已命中 {{hitCount}} / 3
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2267](../src/scenes/rpg/TheaterInteriorScene.ts#L2267)
1176. 连续锁定完成。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2268](../src/scenes/rpg/TheaterInteriorScene.ts#L2268)
1177. 第 {{this.runtime.getState().theaterHunt.spotlightRound + 1}} / 3 轮 · 重试
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2336](../src/scenes/rpg/TheaterInteriorScene.ts#L2336)
1178. 保持已完成轮次，重新观察本轮。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2342](../src/scenes/rpg/TheaterInteriorScene.ts#L2342)
1179. 手机系统：
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2510](../src/scenes/rpg/TheaterInteriorScene.ts#L2510)
1180. {{name}}：
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2516](../src/scenes/rpg/TheaterInteriorScene.ts#L2516)

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
   来源：[src/core/QuestModel.ts:810](../src/core/QuestModel.ts#L810)
6. pending
   来源：[src/core/QuestModel.ts:810](../src/core/QuestModel.ts#L810)
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
   来源：[src/data/chapter3InterludeContent.ts:63](../src/data/chapter3InterludeContent.ts#L63)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:166](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L166)
57. 待核验时间窗
   来源：[src/data/chapter3InterludeContent.ts:64](../src/data/chapter3InterludeContent.ts#L64)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:135](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L135)
58. CC98 划船记录
   来源：[src/data/chapter3InterludeContent.ts:68](../src/data/chapter3InterludeContent.ts#L68)
59. 最后一条离湖回复提供了记录起点。
   来源：[src/data/chapter3InterludeContent.ts:70](../src/data/chapter3InterludeContent.ts#L70)
60. 恢复照片
   来源：[src/data/chapter3InterludeContent.ts:74](../src/data/chapter3InterludeContent.ts#L74)
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
   来源：[src/data/chapter3InterludeContent.ts:173](../src/data/chapter3InterludeContent.ts#L173)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:240](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L240)
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
   来源：[src/scenes/phone/P02_CC98/index.tsx:434](../src/scenes/phone/P02_CC98/index.tsx#L434)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:126](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L126)
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
   来源：[src/scenes/phone/P14_Wechat/index.tsx:47](../src/scenes/phone/P14_Wechat/index.tsx#L47)；[src/scenes/phone/P14_Wechat/index.tsx:55](../src/scenes/phone/P14_Wechat/index.tsx#L55)；[src/scenes/phone/P15_Zjuding/index.tsx:383](../src/scenes/phone/P15_Zjuding/index.tsx#L383)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:56](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L56)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:93](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L93)；[src/scenes/phone/P21_VoiceMemos/index.tsx:427](../src/scenes/phone/P21_VoiceMemos/index.tsx#L427)
137. already\_complete
   来源：[src/scenes/phone/P14_Wechat/index.tsx:47](../src/scenes/phone/P14_Wechat/index.tsx#L47)；[src/scenes/phone/P14_Wechat/index.tsx:55](../src/scenes/phone/P14_Wechat/index.tsx#L55)；[src/scenes/phone/P15_Zjuding/index.tsx:383](../src/scenes/phone/P15_Zjuding/index.tsx#L383)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:93](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L93)；[src/scenes/phone/P21_VoiceMemos/index.tsx:427](../src/scenes/phone/P21_VoiceMemos/index.tsx#L427)
138. 公众号通知已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:48](../src/scenes/phone/P14_Wechat/index.tsx#L48)
139. 先在记录恢复中确认划船帖的离湖时间。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:49](../src/scenes/phone/P14_Wechat/index.tsx#L49)；[src/scenes/phone/P14_Wechat/index.tsx:59](../src/scenes/phone/P14_Wechat/index.tsx#L59)；[src/scenes/phone/P15_Zjuding/index.tsx:385](../src/scenes/phone/P15_Zjuding/index.tsx#L385)
140. 入口变化已截图：东侧关闭，西侧主入口可通行。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:56](../src/scenes/phone/P14_Wechat/index.tsx#L56)
141. incorrect
   来源：[src/scenes/phone/P14_Wechat/index.tsx:57](../src/scenes/phone/P14_Wechat/index.tsx#L57)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:95](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L95)
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
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:31](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L31)
181. 22:44:31 · 剧场前厅
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:32](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L32)
182. 22:43:11 · 基础图书馆南侧
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:33](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L33)
183. 22:44:57 · 北教学区 A 区
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:34](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L34)
184. 通知与路线已核验
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:40](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L40)
185. 当前无法恢复这段记录。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:56](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L56)
186. 恢复工具已打开。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:56](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L56)
187. 地点与四项证据一致，恢复结果已确认。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:69](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L69)
188. 先完成四类证据与旧时间核验。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:73](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L73)
189. record\_0755
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:77](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L77)
190. 证据矩阵发现：保存的接入记录与该地点冲突，请返回网络记录重新选择。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:78](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L78)
191. 当前证据还不足以确认这个地点。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:79](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L79)
192. 恢复回放尚未解锁。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:88](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L88)
193. 这条理由与记录来源不匹配。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:96](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L96)
194. 四项证据还没收齐。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:97](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L97)
195. 未同步记录恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:102](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L102)
196. 退出记录恢复，返回手机主页
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:106](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L106)
197. RECOVERY 03.5
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:109](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L109)
198. 检测到 7 分 55 秒未同步记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:117](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L117)
199. 启真湖的离开记录仍在，后面的去向没有写入。手机时钟与带来源的记录不一致，不能直接采用。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:118](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L118)
200. 7 帧
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:120](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L120)
201. 媒体缓存
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:120](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L120)
202. 3 条
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:121](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L121)
203. 短会话
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:121](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L121)
204. 12 条
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:122](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L122)
205. 通知归档
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:122](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L122)
206. 时间索引
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:123](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L123)
207. 异常
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:123](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L123)
208. 我离开湖边以后，去了哪里？
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:126](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L126)
209. 系统
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:127](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L127)
210. 先从能够核对来源的记录开始。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:127](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L127)
211. 打开恢复工具
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:129](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L129)
212. 左右边界分别由原始证据恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:142](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L142)
213. 先恢复时间窗起点
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:149](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L149)
214. 划船帖的最后一条回复保留了带来源的离湖时间。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:150](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L150)
215. 去 CC98 收尾
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:151](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L151)
216. 四类证据并行恢复，已完成 {{viewModel.branchProgress.completed}} 项，共 {{viewModel.branchProgress.total}} 项
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:155](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L155)
217. 四源恢复环
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:157](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L157)
218. 恢复证据
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:160](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L160)
219. 四条分支互不锁定，可以从任一节点开始；全部完成后自动汇合
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:161](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L161)
220. 点击进入来源
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:165](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L165)
221. 已恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:166](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L166)
222. 排除旧时间
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:175](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L175)
223. 选择排除理由
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:180](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L180)
224. 已排除
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:180](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L180)
225. 自动恢复时间线
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:199](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L199)
226. 自动恢复的时间线
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:200](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L200)
227. 证据矩阵
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:213](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L213)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:214](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L214)
228. 四源交叉核验
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:214](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L214)
229. 离湖
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:216](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L216)
230. 同一移动过程，方向连续。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:216](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L216)
231. CC98 × 照片
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:216](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L216)
232. 录音 × 网络
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:217](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L217)
233. 末段
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:217](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L217)
234. 室内广播、三秒陌生设备与候选地点需要同时成立。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:217](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L217)
235. 候选
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)
236. 尚未保存
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)
237. 已保存接入记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)
238. 选择最终地点
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:225](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L225)
239. 选择唯一能够同时解释时间窗、移动过程、入口变化和网络短会话的地点。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:226](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L226)
240. 路径记录已恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:238](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L238)
241. 回放会从启真湖最后一帧开始，并在已确认地点结束。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:239](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L239)
242. 近
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:108](../src/scenes/phone/P21_VoiceMemos/index.tsx#L108)
243. 中
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:109](../src/scenes/phone/P21_VoiceMemos/index.tsx#L109)
244. 远
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:110](../src/scenes/phone/P21_VoiceMemos/index.tsx#L110)
245. 先试听这段录音，再决定是否保留。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:375](../src/scenes/phone/P21_VoiceMemos/index.tsx#L375)
246. 已经选满四段。先移出一段，再加入新的录音。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:384](../src/scenes/phone/P21_VoiceMemos/index.tsx#L384)
247. 需要先选满四段录音。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:393](../src/scenes/phone/P21_VoiceMemos/index.tsx#L393)
248. 用上下按钮调整四段录音的发生顺序。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:399](../src/scenes/phone/P21_VoiceMemos/index.tsx#L399)
249. 录音已接成连续路线，末段在 22:45:00 结束。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:428](../src/scenes/phone/P21_VoiceMemos/index.tsx#L428)
250. locked
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:429](../src/scenes/phone/P21_VoiceMemos/index.tsx#L429)
251. 先完成 CC98 记录收尾。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:430](../src/scenes/phone/P21_VoiceMemos/index.tsx#L430)
252. 四段都来自这条路线，前后声场仍有一处接不上。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:432](../src/scenes/phone/P21_VoiceMemos/index.tsx#L432)
253. 其中至少一段属于别的夜间记录。重新比较背景声。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:433](../src/scenes/phone/P21_VoiceMemos/index.tsx#L433)
254. 语音备忘录
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:438](../src/scenes/phone/P21_VoiceMemos/index.tsx#L438)；[src/scenes/phone/P21_VoiceMemos/index.tsx:445](../src/scenes/phone/P21_VoiceMemos/index.tsx#L445)
255. 退出语音备忘录
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:442](../src/scenes/phone/P21_VoiceMemos/index.tsx#L442)
256. VOICE MEMOS
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:445](../src/scenes/phone/P21_VoiceMemos/index.tsx#L445)
257. 排序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:446](../src/scenes/phone/P21_VoiceMemos/index.tsx#L446)
258. 录音整理步骤
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:449](../src/scenes/phone/P21_VoiceMemos/index.tsx#L449)
259. 1 / 2 筛选录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:450](../src/scenes/phone/P21_VoiceMemos/index.tsx#L450)
260. 2 / 2 排列顺序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:450](../src/scenes/phone/P21_VoiceMemos/index.tsx#L450)
261. 逐段试听，从七段恢复文件中留下同一次移动过程的四段。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:452](../src/scenes/phone/P21_VoiceMemos/index.tsx#L452)
262. 根据环境声的连续变化，调整四段录音的先后位置。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:453](../src/scenes/phone/P21_VoiceMemos/index.tsx#L453)
263. 七段恢复录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:457](../src/scenes/phone/P21_VoiceMemos/index.tsx#L457)
264. {{isPlaying ? "暂停" : isPaused ? "继续播放" : "播放"}} {{clip.code}}
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:471](../src/scenes/phone/P21_VoiceMemos/index.tsx#L471)；[src/scenes/phone/P21_VoiceMemos/index.tsx:516](../src/scenes/phone/P21_VoiceMemos/index.tsx#L516)
265. 未试听
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:477](../src/scenes/phone/P21_VoiceMemos/index.tsx#L477)
266. 保留这段
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:488](../src/scenes/phone/P21_VoiceMemos/index.tsx#L488)
267. 试听后可选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:488](../src/scenes/phone/P21_VoiceMemos/index.tsx#L488)
268. 移出候选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:488](../src/scenes/phone/P21_VoiceMemos/index.tsx#L488)
269. {{clip.code}} 可听事件
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:490](../src/scenes/phone/P21_VoiceMemos/index.tsx#L490)；[src/scenes/phone/P21_VoiceMemos/index.tsx:528](../src/scenes/phone/P21_VoiceMemos/index.tsx#L528)
270. {{soundEvent.category}} · {{soundEvent.startMs}}–{{soundEvent.endMs}}ms
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:495](../src/scenes/phone/P21_VoiceMemos/index.tsx#L495)；[src/scenes/phone/P21_VoiceMemos/index.tsx:533](../src/scenes/phone/P21_VoiceMemos/index.tsx#L533)
271. 距
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:497](../src/scenes/phone/P21_VoiceMemos/index.tsx#L497)；[src/scenes/phone/P21_VoiceMemos/index.tsx:535](../src/scenes/phone/P21_VoiceMemos/index.tsx#L535)
272. 当前录音顺序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:506](../src/scenes/phone/P21_VoiceMemos/index.tsx#L506)
273. {{clip.code}} 上移
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:524](../src/scenes/phone/P21_VoiceMemos/index.tsx#L524)
274. {{clip.code}} 下移
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:525](../src/scenes/phone/P21_VoiceMemos/index.tsx#L525)
275. 清空选择
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:548](../src/scenes/phone/P21_VoiceMemos/index.tsx#L548)
276. 进入排序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:549](../src/scenes/phone/P21_VoiceMemos/index.tsx#L549)
277. 返回重选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:553](../src/scenes/phone/P21_VoiceMemos/index.tsx#L553)
278. 核对录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:554](../src/scenes/phone/P21_VoiceMemos/index.tsx#L554)
279. P07 天气
   来源：[src/scenes/phone/registry.tsx:55](../src/scenes/phone/registry.tsx#L55)
280. 第二章天气页：收集水滴并用于松开导师头像上的竖线。
   来源：[src/scenes/phone/registry.tsx:56](../src/scenes/phone/registry.tsx#L56)
281. P18 照片
   来源：[src/scenes/phone/registry.tsx:59](../src/scenes/phone/registry.tsx#L59)
282. IMG\_0755.JPG 亮度识别；亮度不高于 20% 时生成物品识别报告。
   来源：[src/scenes/phone/registry.tsx:60](../src/scenes/phone/registry.tsx#L60)
283. P20 记录恢复
   来源：[src/scenes/phone/registry.tsx:63](../src/scenes/phone/registry.tsx#L63)
284. 第三章半：汇总 CC98、照片、微信、网络和录音证据，恢复 22:37:05—22:45:00 路径。
   来源：[src/scenes/phone/registry.tsx:64](../src/scenes/phone/registry.tsx#L64)
285. P21 语音备忘录
   来源：[src/scenes/phone/registry.tsx:67](../src/scenes/phone/registry.tsx#L67)
286. 第三章半：从七段恢复录音中筛选四段，再按声场变化排列。
   来源：[src/scenes/phone/registry.tsx:68](../src/scenes/phone/registry.tsx#L68)
287. P04 校园卡余额
   来源：[src/scenes/phone/registry.tsx:71](../src/scenes/phone/registry.tsx#L71)
288. 第二章取得校园卡后显示余额，并接受右移箭头。
   来源：[src/scenes/phone/registry.tsx:72](../src/scenes/phone/registry.tsx#L72)
289. P11 校务签到
   来源：[src/scenes/phone/registry.tsx:75](../src/scenes/phone/registry.tsx#L75)
290. 校园网输入 0798 → 短暂成功 → 经度与纬度错误 → 红闪和七秒黑屏。
   来源：[src/scenes/phone/registry.tsx:76](../src/scenes/phone/registry.tsx#L76)
291. P10 盆栽
   来源：[src/scenes/phone/registry.tsx:79](../src/scenes/phone/registry.tsx#L79)
292. 浇水/照光/施肥三步平行 → 开花 → 点花得 d4=8。
   来源：[src/scenes/phone/registry.tsx:80](../src/scenes/phone/registry.tsx#L80)
293. P12 序章结算
   来源：[src/scenes/phone/registry.tsx:83](../src/scenes/phone/registry.tsx#L83)
294. 移动错误框拦截三次旁白路径，完成长按锁定和系统对话后返回手机主页。
   来源：[src/scenes/phone/registry.tsx:84](../src/scenes/phone/registry.tsx#L84)
295. P19 时钟
   来源：[src/scenes/phone/registry.tsx:87](../src/scenes/phone/registry.tsx#L87)
296. 第四章校时：拖动环形刻度/表冠/数字或滚轮、Q/E 键，把被篡改冻结的 07:55:23 校准对齐。
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
   来源：[src/components/QuestClueStrip.tsx:21](../src/components/QuestClueStrip.tsx#L21)
38. 第 2 章
   来源：[src/components/QuestClueStrip.tsx:22](../src/components/QuestClueStrip.tsx#L22)
39. 第 3 章
   来源：[src/components/QuestClueStrip.tsx:23](../src/components/QuestClueStrip.tsx#L23)
40. 第 4 章
   来源：[src/components/QuestClueStrip.tsx:24](../src/components/QuestClueStrip.tsx#L24)
41. 第四章当前阶段概览
   来源：[src/components/QuestClueStrip.tsx:246](../src/components/QuestClueStrip.tsx#L246)
42. 当前阶段
   来源：[src/components/QuestClueStrip.tsx:248](../src/components/QuestClueStrip.tsx#L248)；[src/data/chapter4-temporal-maze.content.json:107](../src/data/chapter4-temporal-maze.content.json#L107)
43. 时间状态
   来源：[src/components/QuestClueStrip.tsx:252](../src/components/QuestClueStrip.tsx#L252)；[src/data/chapter4-temporal-maze.content.json:108](../src/data/chapter4-temporal-maze.content.json#L108)
44. 所在楼层
   来源：[src/components/QuestClueStrip.tsx:256](../src/components/QuestClueStrip.tsx#L256)；[src/data/chapter4-temporal-maze.content.json:109](../src/data/chapter4-temporal-maze.content.json#L109)
45. 当前进度
   来源：[src/components/QuestClueStrip.tsx:260](../src/components/QuestClueStrip.tsx#L260)；[src/data/chapter4-temporal-maze.content.json:110](../src/data/chapter4-temporal-maze.content.json#L110)
46. 第四章阶段差分
   来源：[src/components/QuestClueStrip.tsx:265](../src/components/QuestClueStrip.tsx#L265)
47. 当前差分
   来源：[src/components/QuestClueStrip.tsx:267](../src/components/QuestClueStrip.tsx#L267)；[src/data/chapter4-temporal-maze.content.json:111](../src/data/chapter4-temporal-maze.content.json#L111)
48. 时间来源
   来源：[src/components/QuestClueStrip.tsx:272](../src/components/QuestClueStrip.tsx#L272)；[src/data/chapter4-temporal-maze.content.json:112](../src/data/chapter4-temporal-maze.content.json#L112)
49. 手机状态
   来源：[src/components/QuestClueStrip.tsx:276](../src/components/QuestClueStrip.tsx#L276)；[src/data/chapter4-temporal-maze.content.json:113](../src/data/chapter4-temporal-maze.content.json#L113)
50. 已确认事实
   来源：[src/components/QuestClueStrip.tsx:281](../src/components/QuestClueStrip.tsx#L281)；[src/data/chapter4-temporal-maze.content.json:114](../src/data/chapter4-temporal-maze.content.json#L114)
51. 当前阶段尚无已确认事实。
   来源：[src/components/QuestClueStrip.tsx:286](../src/components/QuestClueStrip.tsx#L286)；[src/data/chapter4-temporal-maze.content.json:116](../src/data/chapter4-temporal-maze.content.json#L116)
52. 签到数字
   来源：[src/components/QuestClueStrip.tsx:295](../src/components/QuestClueStrip.tsx#L295)
53. 打开控制中心
   来源：[src/components/StatusBar.tsx:45](../src/components/StatusBar.tsx#L45)
54. 未点亮的灿若星辰灯
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:43](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L43)
55. 回答已保存
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:47](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L47)；[src/scenes/rpg/RpgGameHost.tsx:829](../src/scenes/rpg/RpgGameHost.tsx#L829)
56. 07:55 · 校史墙留下的两项问题
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:51](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L51)
57. 灯仍未点亮
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:52](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L52)
58. 保存两项回答
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:93](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L93)
59. 保存中……
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:93](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L93)
60. 104 教室
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:16](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L16)
61. 105 教室
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:17](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L17)
62. 主电梯
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:18](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L18)；[src/data/chapter4-clock.content.json:50](../src/data/chapter4-clock.content.json#L50)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1008](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1008)
63. 开放自习区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:22](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L22)
64. 东侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:23](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L23)
65. 教室门槛
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:24](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L24)
66. 202 出口
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:25](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L25)
67. 大厅 — 西侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:29](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L29)
68. 大厅 — 东侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:30](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L30)
69. 西侧走廊 — 后区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:31](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L31)
70. 东侧走廊 — 教室区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:32](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L32)
71. 后区 — 教室区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:33](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L33)
72. 西侧走廊 — 东侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:34](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L34)
73. 大厅 — 教室区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:35](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L35)
74. 浅色操作
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:121](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L121)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:98](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L98)；[src/data/chapter4-temporal-maze.content.json:94](../src/data/chapter4-temporal-maze.content.json#L94)；[src/scenes/rpg/RpgInteractionContract.ts:43](../src/scenes/rpg/RpgInteractionContract.ts#L43)
75. 深色观察
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:121](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L121)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:98](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L98)；[src/data/chapter4-temporal-maze.content.json:95](../src/data/chapter4-temporal-maze.content.json#L95)；[src/scenes/rpg/RpgInteractionContract.ts:39](../src/scenes/rpg/RpgInteractionContract.ts#L39)
76. 返回现场
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:124](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L124)；[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:180](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L180)；[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:69](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L69)
77. {{definition.locationLabel}}的{{definition.title}}装置
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:129](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L129)
78. 调整当前装置
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:130](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L130)
79. 观察残留痕迹
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:130](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L130)
80. 记录完成
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:140](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L140)
81. 缺少可校准底片
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:145](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L145)
82. 先在 301 的胶片索引中取出旧导视胶片；两处调查仍可按任意顺序打开查看。
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:146](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L146)
83. 当前装置允许反复调整，提交失败不会重置。
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:178](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L178)
84. 线索会保留在本次调查记录中；关闭后可直接切换模式。
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:178](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L178)
85. 提交结果
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:183](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L183)
86. 正在核对…
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:183](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L183)；[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:71](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L71)
87. 104：旧夹痕
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:194](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L194)
88. 105：中段夹痕
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:194](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L194)
89. 主电梯：最新夹痕
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:194](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L194)
90. 楼层：A3
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:195](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L195)
91. 年代：九十年代末
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:195](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L195)
92. 用途：入口导视
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:195](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L195)
93. 方向：顺时针 90°
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:196](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L196)
94. 横向：右移 2 格
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:196](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L196)
95. 纵向：上移 1 格
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:196](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L196)
96. 横向：−2
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:197](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L197)
97. 压力：3 档
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:197](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L197)
98. 纵向：+1
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:197](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L197)
99. 大厅分别连接两侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:198](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L198)
100. 两侧走廊分别连向两个末端区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:198](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L198)
101. 两个末端区互相连接
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:198](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L198)
102. 起点：开放自习区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:199](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L199)
103. 中段：东侧走廊、教室门槛
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:199](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L199)
104. 终点：202 出口
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:199](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L199)
105. 年代
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:236](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L236)
106. 1977–1984
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:237](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L237)
107. 1985–1990
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:237](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L237)
108. 1991–1998
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:237](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L237)
109. 选择范围
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:237](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L237)
110. 楼层
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:239](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L239)
111. 选择楼层
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:240](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L240)
112. 用途
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:242](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L242)；[src/data/itemCatalog.ts:213](../src/data/itemCatalog.ts#L213)
113. 考勤
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:243](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L243)
114. 入口导视
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:243](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L243)
115. 维修
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:243](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L243)
116. 选择用途
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:243](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L243)
117. 垂直
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
118. 水平
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
119. 旋转
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
120. 横向
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:250](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L250)
121. 压力
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:250](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L250)
122. 纵向
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:250](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L250)
123. 五区连线选择
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:253](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L253)
124. / 5 条
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:258](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L258)
125. 已保留
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:258](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L258)
126. {{labels\[id\]}}前移
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:284](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L284)
127. {{labels\[id\]}}后移
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:285](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L285)
128. 车轮声音
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:9](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L9)
129. 推车起步时轮罩先响，车轮随后才停。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:9](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L9)
130. 旧钟卡滞
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:10](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L10)
131. 秒轮到同一齿位会回弹，拨动后仍重复。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:10](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L10)
132. 轮轴边只有干涸油圈，地面没有新鲜滴落。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:11](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L11)
133. 油迹
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:11](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L11)
134. 卡扣
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:15](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L15)
135. 缺油
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:16](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L16)
136. 齿轮偏位
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:17](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L17)
137. 供电中断
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:18](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L18)
138. 异物堵塞
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:19](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L19)
139. 22:45 · 维修记录
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:43](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L43)
140. 根据三处现象判断故障原因
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:44](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L44)
141. 每项现象选择一个原因，提交前可以改选。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:45](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L45)
142. 选择原因
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:61](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L61)
143. 提交诊断
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:71](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L71)
144. 五区配电箱
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:148](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L148)
145. 让必要路线亮起
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:149](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L149)；[src/data/chapter4-755.content.json:1048](../src/data/chapter4-755.content.json#L1048)
146. 五区配电线路拓扑
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:152](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L152)
147. {{zone.label}}当前{{on ? "亮" : "暗"}}，连接{{adjacentLabels}}
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:191](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L191)
148. 暗
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:212](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L212)
149. 亮
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:212](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L212)
150. 正在同步配电状态……
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:220](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L220)
151. 配电结果已锁定。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:222](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L222)；[src/scenes/rpg/RpgGameHost.tsx:1333](../src/scenes/rpg/RpgGameHost.tsx#L1333)
152. 按下一区，会切换它自身和连线直接相接的区域。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:223](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L223)
153. 方向键移动焦点 · Enter / Space 切换 · Esc 关闭
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:226](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L226)
154. 重试锁定配电结果
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:232](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L232)
155. 重试锁定
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:235](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L235)
156. 关闭箱门
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:245](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L245)
157. 错位楼梯空间校准
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:54](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L54)
158. 正在载入楼梯空间…
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:56](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L56)
159. 楼梯空间启动失败
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:59](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L59)
160. 返回三楼后可以重新进入。
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:60](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L60)
161. 返回三楼
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:64](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L64)
162. 灿若星辰灯点亮
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:41](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L41)
163. 灿若星辰
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:64](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L64)
164. 时间切换操作
   来源：[src/components/temporal-maze/ChapterFourTransitionOverlay.tsx:56](../src/components/temporal-maze/ChapterFourTransitionOverlay.tsx#L56)
165. 继续行动
   来源：[src/components/temporal-maze/ChapterFourTransitionOverlay.tsx:58](../src/components/temporal-maze/ChapterFourTransitionOverlay.tsx#L58)
166. 三条轨道已经对齐，主电梯开始重放这一段历史。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:65](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L65)
167. 这一段历史已经对齐，可以返回主电梯厅。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:67](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L67)
168. 开门区间没有完整覆盖黄色进入窗口。继续移动整段轿厢历史。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:69](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L69)
169. 当前仍在深色观察。切回浅色操作后才能启动历史重放。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:71](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L71)
170. 当前剧情阶段尚未开放轿厢重放。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:73](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L73)
171. 拖动下方时间游标，三条轨道会保持同一历史偏移。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:74](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L74)
172. HISTORY REPLAY / A-LIFT
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:90](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L90)
173. 主电梯三轨同步
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:91](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L91)
174. 关闭三轨同步面板
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:93](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L93)
175. 当前模式
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:97](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L97)
176. 重放起点
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:99](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L99)
177. 尝试
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:101](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L101)
178. 电梯历史三轨
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:105](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L105)
179. 轿厢
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:113](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L113)
180. 门体
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:122](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L122)
181. 开门
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:124](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L124)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:126](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L126)
182. 关闭
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:125](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L125)；[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
183. 进入
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:131](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L131)
184. 6 秒窗口
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:133](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L133)
185. 拖动轿厢历史
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:143](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L143)
186. 调整电梯历史重放起点
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:155](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L155)
187. 切到浅色操作
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:163](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L163)
188. 启动历史重放
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:170](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L170)
189. 目标：让一楼开门区间完整覆盖进入窗口
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:173](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L173)
190. 碎片 A · 箭头端
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:18](../src/components/temporal-maze/WayfindingBoardGame.tsx#L18)
191. 碎片 B · 2F 字样端
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:19](../src/components/temporal-maze/WayfindingBoardGame.tsx#L19)
192. 当前历史片段已经恢复。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:29](../src/components/temporal-maze/WayfindingBoardGame.tsx#L29)
193. 这一段导视记录已经恢复。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:30](../src/components/temporal-maze/WayfindingBoardGame.tsx#L30)
194. 碎片顺序与已记录的历史痕迹不一致。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:31](../src/components/temporal-maze/WayfindingBoardGame.tsx#L31)
195. 切回浅色操作后再调整导视板。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:32](../src/components/temporal-maze/WayfindingBoardGame.tsx#L32)
196. 第四章教学楼流程尚未开始。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:33](../src/components/temporal-maze/WayfindingBoardGame.tsx#L33)；[src/scenes/rpg/RpgGameHost.tsx:385](../src/scenes/rpg/RpgGameHost.tsx#L385)
197. 仍缺当前排列所需的历史证据。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:34](../src/components/temporal-maze/WayfindingBoardGame.tsx#L34)
198. 比较三份现场材料后，选择一块碎片，再选择目标槽位。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:42](../src/components/temporal-maze/WayfindingBoardGame.tsx#L42)
199. 该槽位为空。先选择一块导视碎片。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:71](../src/components/temporal-maze/WayfindingBoardGame.tsx#L71)
200. 已选择{{FRAGMENT\_LABELS\[fragment\]}}，请选择目标槽位。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:75](../src/components/temporal-maze/WayfindingBoardGame.tsx#L75)
201. 已取消当前选择。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:80](../src/components/temporal-maze/WayfindingBoardGame.tsx#L80)
202. 槽位已交换。确认前可以继续调整。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:87](../src/components/temporal-maze/WayfindingBoardGame.tsx#L87)
203. ARCHIVED SIGNAGE / A3
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:124](../src/components/temporal-maze/WayfindingBoardGame.tsx#L124)
204. 残缺导视板
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:125](../src/components/temporal-maze/WayfindingBoardGame.tsx#L125)
205. 取消并关闭导视板
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:127](../src/components/temporal-maze/WayfindingBoardGame.tsx#L127)
206. 当前目标
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:131](../src/components/temporal-maze/WayfindingBoardGame.tsx#L131)；[src/scenes/rpg/Chapter4PrologueOverlay.tsx:709](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L709)
207. 比较当前导视照片、旧残影和二楼入口方向，判断两块碎片及缺失槽位的位置。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:132](../src/components/temporal-maze/WayfindingBoardGame.tsx#L132)
208. 导视板比对材料
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:135](../src/components/temporal-maze/WayfindingBoardGame.tsx#L135)
209. 当前导视照片
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:137](../src/components/temporal-maze/WayfindingBoardGame.tsx#L137)
210. 完整板面由三段等宽槽位组成；两块残片并拢后宽度仍不足。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:138](../src/components/temporal-maze/WayfindingBoardGame.tsx#L138)
211. 旧导视残影
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:141](../src/components/temporal-maze/WayfindingBoardGame.tsx#L141)
212. 箭头端贴近左侧磨损边；“2F”字样端与箭头之间留有断续胶痕。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:142](../src/components/temporal-maze/WayfindingBoardGame.tsx#L142)
213. 二楼入口方向
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:145](../src/components/temporal-maze/WayfindingBoardGame.tsx#L145)
214. 从交通核心进入二楼时，入口位于左侧导向一边。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:146](../src/components/temporal-maze/WayfindingBoardGame.tsx#L146)
215. 三个导视板槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:150](../src/components/temporal-maze/WayfindingBoardGame.tsx#L150)
216. 当前空槽
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:152](../src/components/temporal-maze/WayfindingBoardGame.tsx#L152)
217. 槽位 {{index + 1}}：{{label}}{{picked ? "，已选择" : ""}}
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:161](../src/components/temporal-maze/WayfindingBoardGame.tsx#L161)
218. 槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:184](../src/components/temporal-maze/WayfindingBoardGame.tsx#L184)
219. 当前没有装入碎片
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:186](../src/components/temporal-maze/WayfindingBoardGame.tsx#L186)
220. 选择后放入另一槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:186](../src/components/temporal-maze/WayfindingBoardGame.tsx#L186)
221. 取消
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:197](../src/components/temporal-maze/WayfindingBoardGame.tsx#L197)
222. 方向键切换槽位，Enter 或空格选择
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:198](../src/components/temporal-maze/WayfindingBoardGame.tsx#L198)
223. 确认当前排列
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:199](../src/components/temporal-maze/WayfindingBoardGame.tsx#L199)
224. active
   来源：[src/core/QuestModel.ts:928](../src/core/QuestModel.ts#L928)；[src/core/QuestModel.ts:1130](../src/core/QuestModel.ts#L1130)
225. completed
   来源：[src/core/QuestModel.ts:928](../src/core/QuestModel.ts#L928)；[src/core/QuestModel.ts:1033](../src/core/QuestModel.ts#L1033)；[src/core/QuestModel.ts:1102](../src/core/QuestModel.ts#L1102)；[src/core/QuestModel.ts:1130](../src/core/QuestModel.ts#L1130)
226. 104 黑板
   来源：[src/core/QuestModel.ts:940](../src/core/QuestModel.ts#L940)
227. 擦痕残留
   来源：[src/core/QuestModel.ts:941](../src/core/QuestModel.ts#L941)
228. 105 讲台
   来源：[src/core/QuestModel.ts:946](../src/core/QuestModel.ts#L946)
229. 本地回放
   来源：[src/core/QuestModel.ts:947](../src/core/QuestModel.ts#L947)
230. pending
   来源：[src/core/QuestModel.ts:1033](../src/core/QuestModel.ts#L1033)；[src/core/QuestModel.ts:1102](../src/core/QuestModel.ts#L1102)
231. 303 晨间参照
   来源：[src/core/QuestModel.ts:1043](../src/core/QuestModel.ts#L1043)
232. 浅色现场记录
   来源：[src/core/QuestModel.ts:1044](../src/core/QuestModel.ts#L1044)
233. 204 夜间残影
   来源：[src/core/QuestModel.ts:1049](../src/core/QuestModel.ts#L1049)
234. 深色轮廓记录
   来源：[src/core/QuestModel.ts:1050](../src/core/QuestModel.ts#L1050)
235. 204 家具复原
   来源：[src/core/QuestModel.ts:1055](../src/core/QuestModel.ts#L1055)
236. {{completedGroupCount}}/{{ROOM204\_GROUP\_ORDER.length}} 组就位
   来源：[src/core/QuestModel.ts:1056](../src/core/QuestModel.ts#L1056)
237. 校园卡读卡器
   来源：[src/core/QuestModel.ts:1079](../src/core/QuestModel.ts#L1079)
238. 刷卡确认
   来源：[src/core/QuestModel.ts:1080](../src/core/QuestModel.ts#L1080)
239. 签到纸插槽
   来源：[src/core/QuestModel.ts:1086](../src/core/QuestModel.ts#L1086)
240. 纸条确认
   来源：[src/core/QuestModel.ts:1087](../src/core/QuestModel.ts#L1087)
241. 把时间拨回 7:55
   来源：[src/data/chapter4-755.content.json:5](../src/data/chapter4-755.content.json#L5)
242. 阶段 1 · 接住签到纸
   来源：[src/data/chapter4-755.content.json:130](../src/data/chapter4-755.content.json#L130)
243. 外部记录指向现场 22:45，手机仍停在 07:55:23，当前读数尚未同步。
   来源：[src/data/chapter4-755.content.json:131](../src/data/chapter4-755.content.json#L131)
244. 阶段 2 · 核对异常时间
   来源：[src/data/chapter4-755.content.json:134](../src/data/chapter4-755.content.json#L134)
245. 现场 22:45 与手机 07:55:23 冲突，需要确认手机时间不可作为当前依据。
   来源：[src/data/chapter4-755.content.json:135](../src/data/chapter4-755.content.json#L135)
246. 阶段 3 · 接管大厅旧钟
   来源：[src/data/chapter4-755.content.json:138](../src/data/chapter4-755.content.json#L138)
247. 手机时间已被外部记录否定，大厅旧钟缺少时针，尚未成为可用时间源。
   来源：[src/data/chapter4-755.content.json:139](../src/data/chapter4-755.content.json#L139)
248. 阶段 4 · 找回旧时针
   来源：[src/data/chapter4-755.content.json:142](../src/data/chapter4-755.content.json#L142)
249. 大厅旧钟停在 12:25，时针落入面包坊传送带，需要取回并装回。
   来源：[src/data/chapter4-755.content.json:143](../src/data/chapter4-755.content.json#L143)
250. 阶段 5 · 恢复 204
   来源：[src/data/chapter4-755.content.json:146](../src/data/chapter4-755.content.json#L146)
251. 电梯保留 18:50 历史轨道，三楼与二楼之间的楼梯发生投影错位；接通交通后再按 303 参照恢复 204。
   来源：[src/data/chapter4-755.content.json:147](../src/data/chapter4-755.content.json#L147)
252. 阶段 6 · 完成维修
   来源：[src/data/chapter4-755.content.json:150](../src/data/chapter4-755.content.json#L150)
253. 旧钟进入 22:45 维修时段且手机已同步，保洁车轮与钟内齿轮仍影响校时。
   来源：[src/data/chapter4-755.content.json:151](../src/data/chapter4-755.content.json#L151)
254. 阶段 7 · 接通必要照明
   来源：[src/data/chapter4-755.content.json:154](../src/data/chapter4-755.content.json#L154)
255. 旧钟已到 07:54，最后一分钟被纸条带走，只需恢复通往目标区域的必要灯区。
   来源：[src/data/chapter4-755.content.json:155](../src/data/chapter4-755.content.json#L155)
256. 阶段 8 · 追向 202
   来源：[src/data/chapter4-755.content.json:158](../src/data/chapter4-755.content.json#L158)
257. 旧钟仍停在 07:54，最后一分钟正在向二楼 202 移动。
   来源：[src/data/chapter4-755.content.json:159](../src/data/chapter4-755.content.json#L159)
258. 阶段 9 · 取回最后一分钟
   来源：[src/data/chapter4-755.content.json:162](../src/data/chapter4-755.content.json#L162)
259. 202 投影保留最后一分钟，旧钟仍缺少这一分钟。
   来源：[src/data/chapter4-755.content.json:163](../src/data/chapter4-755.content.json#L163)
260. 阶段 10 · 返回大厅旧钟
   来源：[src/data/chapter4-755.content.json:166](../src/data/chapter4-755.content.json#L166)
261. 最后一分钟已经取回，需要通过主楼梯送回一楼旧钟。
   来源：[src/data/chapter4-755.content.json:167](../src/data/chapter4-755.content.json#L167)
262. 阶段 11 · 完成双重签到
   来源：[src/data/chapter4-755.content.json:170](../src/data/chapter4-755.content.json#L170)
263. 旧钟与手机均为 07:55，校园卡与签到记录纸仍需分别通过验证。
   来源：[src/data/chapter4-755.content.json:171](../src/data/chapter4-755.content.json#L171)
264. 阶段 12 · 完成楼外收束
   来源：[src/data/chapter4-755.content.json:174](../src/data/chapter4-755.content.json#L174)
265. 楼内校时和双重签到已经完成，仍需确认楼外正式收束结果。
   来源：[src/data/chapter4-755.content.json:175](../src/data/chapter4-755.content.json#L175)
266. 阶段 13 · 本人来过
   来源：[src/data/chapter4-755.content.json:178](../src/data/chapter4-755.content.json#L178)
267. 旧钟、手机与签到记录均已对齐到 07:55。
   来源：[src/data/chapter4-755.content.json:179](../src/data/chapter4-755.content.json#L179)
268. 现场 22:45 · 手机 07:55:23 未同步
   来源：[src/data/chapter4-755.content.json:184](../src/data/chapter4-755.content.json#L184)；[src/modules/ChapterFourStagePresentation.ts:86](../src/modules/ChapterFourStagePresentation.ts#L86)
269. 旧钟 12:25 · 面包坊时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:187](../src/data/chapter4-755.content.json#L187)
270. 旧钟 18:50 · 晚间教室 · 手机已同步
   来源：[src/data/chapter4-755.content.json:190](../src/data/chapter4-755.content.json#L190)
271. 旧钟 22:45 · 维修时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:193](../src/data/chapter4-755.content.json#L193)；[src/modules/ChapterFourStagePresentation.ts:87](../src/modules/ChapterFourStagePresentation.ts#L87)
272. 旧钟 07:54 · 停电时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:196](../src/data/chapter4-755.content.json#L196)
273. 旧钟 07:55 · 清晨签到 · 手机已同步
   来源：[src/data/chapter4-755.content.json:199](../src/data/chapter4-755.content.json#L199)
274. 签到纸已落到公告栏前
   来源：[src/data/chapter4-755.content.json:203](../src/data/chapter4-755.content.json#L203)
275. 签到记录纸已接住
   来源：[src/data/chapter4-755.content.json:204](../src/data/chapter4-755.content.json#L204)
276. 手机 07:55:23 已被外部记录否定
   来源：[src/data/chapter4-755.content.json:205](../src/data/chapter4-755.content.json#L205)
277. 大厅旧钟缺件状态已确认
   来源：[src/data/chapter4-755.content.json:206](../src/data/chapter4-755.content.json#L206)
278. 面包坊检修灯已确认
   来源：[src/data/chapter4-755.content.json:207](../src/data/chapter4-755.content.json#L207)
279. 旧时针已从传送带露出
   来源：[src/data/chapter4-755.content.json:208](../src/data/chapter4-755.content.json#L208)
280. 旧时针已取得
   来源：[src/data/chapter4-755.content.json:209](../src/data/chapter4-755.content.json#L209)
281. 旧时针已装回
   来源：[src/data/chapter4-755.content.json:210](../src/data/chapter4-755.content.json#L210)
282. 104 黑板的延迟擦痕已记录
   来源：[src/data/chapter4-755.content.json:211](../src/data/chapter4-755.content.json#L211)
283. 105 讲台的本地回放延迟已确认
   来源：[src/data/chapter4-755.content.json:212](../src/data/chapter4-755.content.json#L212)
284. 主电梯三条历史轨道已读取
   来源：[src/data/chapter4-755.content.json:213](../src/data/chapter4-755.content.json#L213)
285. 主电梯 18:50 重放窗口已校准
   来源：[src/data/chapter4-755.content.json:214](../src/data/chapter4-755.content.json#L214)
286. A1 值班签到板已重建
   来源：[src/data/chapter4-755.content.json:215](../src/data/chapter4-755.content.json#L215)
287. 301 旧导视胶片已取出
   来源：[src/data/chapter4-755.content.json:216](../src/data/chapter4-755.content.json#L216)
288. 302 新旧影像已对齐
   来源：[src/data/chapter4-755.content.json:217](../src/data/chapter4-755.content.json#L217)
289. 三楼 303 晨间参照已记录
   来源：[src/data/chapter4-755.content.json:218](../src/data/chapter4-755.content.json#L218)
290. 竺老两问已回答
   来源：[src/data/chapter4-755.content.json:219](../src/data/chapter4-755.content.json#L219)
291. 三楼至二楼的错位楼梯已接通
   来源：[src/data/chapter4-755.content.json:220](../src/data/chapter4-755.content.json#L220)
292. 二楼 204 残影已记录
   来源：[src/data/chapter4-755.content.json:221](../src/data/chapter4-755.content.json#L221)
293. 二楼 204 已恢复
   来源：[src/data/chapter4-755.content.json:222](../src/data/chapter4-755.content.json#L222)
294. 204 投影记录已完成
   来源：[src/data/chapter4-755.content.json:223](../src/data/chapter4-755.content.json#L223)
295. 钟面定位片已取得
   来源：[src/data/chapter4-755.content.json:224](../src/data/chapter4-755.content.json#L224)
296. 201 定位板已完成三轴校准
   来源：[src/data/chapter4-755.content.json:225](../src/data/chapter4-755.content.json#L225)
297. 203 五区供电拓扑已恢复
   来源：[src/data/chapter4-755.content.json:226](../src/data/chapter4-755.content.json#L226)
298. A2 夜间疏散路线已确认
   来源：[src/data/chapter4-755.content.json:227](../src/data/chapter4-755.content.json#L227)
299. 钟面定位片已装回
   来源：[src/data/chapter4-755.content.json:228](../src/data/chapter4-755.content.json#L228)
300. 保洁车轮卡滞已确认
   来源：[src/data/chapter4-755.content.json:229](../src/data/chapter4-755.content.json#L229)
301. 保洁车轮罩已打开
   来源：[src/data/chapter4-755.content.json:230](../src/data/chapter4-755.content.json#L230)
302. 保洁车轮已修复
   来源：[src/data/chapter4-755.content.json:231](../src/data/chapter4-755.content.json#L231)
303. 旧钟齿轮已修复
   来源：[src/data/chapter4-755.content.json:232](../src/data/chapter4-755.content.json#L232)
304. 签到纸暂时带走最后一分钟
   来源：[src/data/chapter4-755.content.json:233](../src/data/chapter4-755.content.json#L233)
305. 必要照明路线已锁定
   来源：[src/data/chapter4-755.content.json:234](../src/data/chapter4-755.content.json#L234)
306. 灿若星辰灯光收束准备信号已记录
   来源：[src/data/chapter4-755.content.json:235](../src/data/chapter4-755.content.json#L235)
307. 最后一分钟已取回
   来源：[src/data/chapter4-755.content.json:236](../src/data/chapter4-755.content.json#L236)
308. 最后一分钟已装回旧钟
   来源：[src/data/chapter4-755.content.json:237](../src/data/chapter4-755.content.json#L237)
309. 校园卡验证已通过
   来源：[src/data/chapter4-755.content.json:238](../src/data/chapter4-755.content.json#L238)
310. 签到记录纸验证已通过
   来源：[src/data/chapter4-755.content.json:239](../src/data/chapter4-755.content.json#L239)
311. 楼外正式收束已确认
   来源：[src/data/chapter4-755.content.json:240](../src/data/chapter4-755.content.json#L240)
312. 第四章交接条件尚未齐全。
   来源：[src/data/chapter4-755.content.json:246](../src/data/chapter4-755.content.json#L246)
313. 先完成恢复回放并在任务卡确认进入。
   来源：[src/data/chapter4-755.content.json:247](../src/data/chapter4-755.content.json#L247)
314. 该操作不属于当前阶段。
   来源：[src/data/chapter4-755.content.json:250](../src/data/chapter4-755.content.json#L250)
315. 打开任务栏，按当前目标继续。
   来源：[src/data/chapter4-755.content.json:251](../src/data/chapter4-755.content.json#L251)
316. 当前目标尚未开放。
   来源：[src/data/chapter4-755.content.json:254](../src/data/chapter4-755.content.json#L254)
317. 先完成任务栏中显示的当前前置操作。
   来源：[src/data/chapter4-755.content.json:255](../src/data/chapter4-755.content.json#L255)
318. 当前阶段不能进入这一区域。
   来源：[src/data/chapter4-755.content.json:258](../src/data/chapter4-755.content.json#L258)
319. 返回当前楼层已开放的任务目标。
   来源：[src/data/chapter4-755.content.json:259](../src/data/chapter4-755.content.json#L259)
320. 这次楼梯通行条件不成立。
   来源：[src/data/chapter4-755.content.json:262](../src/data/chapter4-755.content.json#L262)
321. 按任务栏目标从当前楼层的主楼梯继续。
   来源：[src/data/chapter4-755.content.json:263](../src/data/chapter4-755.content.json#L263)
322. 传送带仍在运行。
   来源：[src/data/chapter4-755.content.json:266](../src/data/chapter4-755.content.json#L266)
323. 先检查并点亮烤箱旁的检修灯。
   来源：[src/data/chapter4-755.content.json:267](../src/data/chapter4-755.content.json#L267)
324. 传送带正在执行停机过程。
   来源：[src/data/chapter4-755.content.json:270](../src/data/chapter4-755.content.json#L270)
325. 等待停稳后再取露出的旧时针。
   来源：[src/data/chapter4-755.content.json:271](../src/data/chapter4-755.content.json#L271)
326. 旧时针流程尚未完成。
   来源：[src/data/chapter4-755.content.json:274](../src/data/chapter4-755.content.json#L274)
327. 先让传送带停稳，取得旧时针后拖到大厅旧钟。
   来源：[src/data/chapter4-755.content.json:275](../src/data/chapter4-755.content.json#L275)
328. A1 的时间差校验尚未完成。
   来源：[src/data/chapter4-755.content.json:278](../src/data/chapter4-755.content.json#L278)
329. 104 黑板擦痕与 105 讲台回放可按任意顺序确认。
   来源：[src/data/chapter4-755.content.json:279](../src/data/chapter4-755.content.json#L279)
330. 主电梯的历史轨道尚未记录。
   来源：[src/data/chapter4-755.content.json:282](../src/data/chapter4-755.content.json#L282)
331. 完成 104 与 105 校验后，可在一楼电梯门前用深色观察记录；这不限制浅色校准的先后。
   来源：[src/data/chapter4-755.content.json:283](../src/data/chapter4-755.content.json#L283)
332. 主电梯重放窗口尚未校准。
   来源：[src/data/chapter4-755.content.json:286](../src/data/chapter4-755.content.json#L286)
333. 使用浅色操作进入轿厢，让门体开放区间覆盖六秒进入窗口。
   来源：[src/data/chapter4-755.content.json:287](../src/data/chapter4-755.content.json#L287)
334. 三层电梯运行记录尚未齐全。
   来源：[src/data/chapter4-755.content.json:290](../src/data/chapter4-755.content.json#L290)
335. 分别在一楼、三楼和二楼查阅起行、到站与外呼记录；三段可按任意顺序归档。
   来源：[src/data/chapter4-755.content.json:291](../src/data/chapter4-755.content.json#L291)
336. 跨层停靠链尚未复核。
   来源：[src/data/chapter4-755.content.json:294](../src/data/chapter4-755.content.json#L294)
337. 三段记录齐全后，在浅色操作的电梯面板中确认实际到站层和未响应外呼层。
   来源：[src/data/chapter4-755.content.json:295](../src/data/chapter4-755.content.json#L295)
338. A1 的三段值班记录还没有汇合。
   来源：[src/data/chapter4-755.content.json:298](../src/data/chapter4-755.content.json#L298)
339. 到前台台面打开签到板；104、105 与电梯的调查顺序不受限制。
   来源：[src/data/chapter4-755.content.json:299](../src/data/chapter4-755.content.json#L299)
340. 302 扫描台缺少旧导视胶片。
   来源：[src/data/chapter4-755.content.json:302](../src/data/chapter4-755.content.json#L302)
341. 到三楼 301 的索引抽屉按年份、楼层与用途筛出胶片。
   来源：[src/data/chapter4-755.content.json:303](../src/data/chapter4-755.content.json#L303)
342. 三楼新旧导视影像尚未重合。
   来源：[src/data/chapter4-755.content.json:306](../src/data/chapter4-755.content.json#L306)
343. 带着 301 胶片到 302，校准平移和旋转后再进入错位楼梯。
   来源：[src/data/chapter4-755.content.json:307](../src/data/chapter4-755.content.json#L307)
344. 钟面定位片尚未完成三轴校准。
   来源：[src/data/chapter4-755.content.json:310](../src/data/chapter4-755.content.json#L310)
345. 到二楼 201 创客工坊调整横向、纵向和压力。
   来源：[src/data/chapter4-755.content.json:311](../src/data/chapter4-755.content.json#L311)
346. 五区供电关系仍不完整。
   来源：[src/data/chapter4-755.content.json:314](../src/data/chapter4-755.content.json#L314)
347. 到二楼 203 恢复停电前的五条相邻连线。
   来源：[src/data/chapter4-755.content.json:315](../src/data/chapter4-755.content.json#L315)
348. 二楼疏散通路尚未确认。
   来源：[src/data/chapter4-755.content.json:318](../src/data/chapter4-755.content.json#L318)
349. 在开放自习区按脚步残影排列通往 202 的四段路线。
   来源：[src/data/chapter4-755.content.json:319](../src/data/chapter4-755.content.json#L319)
350. 竺老两问尚未完成。
   来源：[src/data/chapter4-755.content.json:322](../src/data/chapter4-755.content.json#L322)
351. 在楼外未点亮的灿若星辰灯前选择并一次提交两项回答。
   来源：[src/data/chapter4-755.content.json:323](../src/data/chapter4-755.content.json#L323)
352. 三楼与二楼之间的楼梯仍处于投影错位状态。
   来源：[src/data/chapter4-755.content.json:326](../src/data/chapter4-755.content.json#L326)
353. 在三楼晨间教室记录参照后，从主楼梯进入空间校准。
   来源：[src/data/chapter4-755.content.json:327](../src/data/chapter4-755.content.json#L327)
354. 204 复原缺少参照记录。
   来源：[src/data/chapter4-755.content.json:330](../src/data/chapter4-755.content.json#L330)
355. 补齐 303 参照与 204 深色残影；家具摆放可以在两项记录之前或之后完成。
   来源：[src/data/chapter4-755.content.json:331](../src/data/chapter4-755.content.json#L331)
356. 204 仍有家具未复原。
   来源：[src/data/chapter4-755.content.json:334](../src/data/chapter4-755.content.json#L334)
357. 依据四处原始痕迹完成剩余成组摆放，直到四组全部复原。
   来源：[src/data/chapter4-755.content.json:335](../src/data/chapter4-755.content.json#L335)
358. 该家具未被当前场景识别。
   来源：[src/data/chapter4-755.content.json:338](../src/data/chapter4-755.content.json#L338)
359. 重新选取 204 内可见且尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:339](../src/data/chapter4-755.content.json#L339)
360. 该位置不属于 204 的复原槽位。
   来源：[src/data/chapter4-755.content.json:342](../src/data/chapter4-755.content.json#L342)
361. 靠近教室内清晰显示的空槽位后重试。
   来源：[src/data/chapter4-755.content.json:343](../src/data/chapter4-755.content.json#L343)
362. 该家具状态无法写入复原记录。
   来源：[src/data/chapter4-755.content.json:346](../src/data/chapter4-755.content.json#L346)
363. 放下后重新选取家具，再放入任一空槽位。
   来源：[src/data/chapter4-755.content.json:347](../src/data/chapter4-755.content.json#L347)
364. 这组家具已经写入另一个槽位。
   来源：[src/data/chapter4-755.content.json:350](../src/data/chapter4-755.content.json#L350)
365. 改选一组尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:351](../src/data/chapter4-755.content.json#L351)
366. 这个槽位已经有一组家具。
   来源：[src/data/chapter4-755.content.json:354](../src/data/chapter4-755.content.json#L354)
367. 把当前家具放入另一个空槽位。
   来源：[src/data/chapter4-755.content.json:355](../src/data/chapter4-755.content.json#L355)
368. 这组家具已经完成复原。
   来源：[src/data/chapter4-755.content.json:358](../src/data/chapter4-755.content.json#L358)
369. 继续选择一组尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:359](../src/data/chapter4-755.content.json#L359)
370. 这片痕迹不属于当前复原记录。
   来源：[src/data/chapter4-755.content.json:362](../src/data/chapter4-755.content.json#L362)
371. 靠近教室内仍有残影的痕迹区。
   来源：[src/data/chapter4-755.content.json:363](../src/data/chapter4-755.content.json#L363)
372. 当前痕迹区与提交的复原组不一致。
   来源：[src/data/chapter4-755.content.json:366](../src/data/chapter4-755.content.json#L366)
373. 留在当前痕迹区并重新执行一次复原。
   来源：[src/data/chapter4-755.content.json:367](../src/data/chapter4-755.content.json#L367)
374. 这组三处位置含有旧存档中的占用记录。
   来源：[src/data/chapter4-755.content.json:370](../src/data/chapter4-755.content.json#L370)
375. 先处理其他痕迹区；当前组会保留原记录。
   来源：[src/data/chapter4-755.content.json:371](../src/data/chapter4-755.content.json#L371)
376. 这组三处桌椅已经复原。
   来源：[src/data/chapter4-755.content.json:374](../src/data/chapter4-755.content.json#L374)
377. 查看教室内仍有残影的痕迹区。
   来源：[src/data/chapter4-755.content.json:375](../src/data/chapter4-755.content.json#L375)
378. 讲台抽屉尚未解锁。
   来源：[src/data/chapter4-755.content.json:378](../src/data/chapter4-755.content.json#L378)
379. 先完成四组复原并确认 07:55 投影。
   来源：[src/data/chapter4-755.content.json:379](../src/data/chapter4-755.content.json#L379)
380. 一楼的时间记录还没有形成可比较的同一组。
   来源：[src/data/chapter4-755.content.json:382](../src/data/chapter4-755.content.json#L382)
381. 补齐 104、105 与电梯的原始记录，再查看它们共有的时间差。
   来源：[src/data/chapter4-755.content.json:383](../src/data/chapter4-755.content.json#L383)
382. 投影中的时间、空间和纸痕仍未完成叠合。
   来源：[src/data/chapter4-755.content.json:386](../src/data/chapter4-755.content.json#L386)
383. 回看教室里四组原始痕迹，确认它们在投影中同时稳定。
   来源：[src/data/chapter4-755.content.json:387](../src/data/chapter4-755.content.json#L387)
384. 保洁车与旧钟之间的同源碰撞痕迹尚未确认。
   来源：[src/data/chapter4-755.content.json:390](../src/data/chapter4-755.content.json#L390)
385. 比较教室投影的缺口形状与保洁车轮罩附近的擦痕。
   来源：[src/data/chapter4-755.content.json:391](../src/data/chapter4-755.content.json#L391)
386. 当前照明还没有确认纸痕经过的连续区域。
   来源：[src/data/chapter4-755.content.json:394](../src/data/chapter4-755.content.json#L394)
387. 回到配电面板，让先前记录过的三个区域同时保持可见。
   来源：[src/data/chapter4-755.content.json:395](../src/data/chapter4-755.content.json#L395)
388. 身份记录与三楼留下的求学信息尚未形成完整对应。
   来源：[src/data/chapter4-755.content.json:398](../src/data/chapter4-755.content.json#L398)
389. 查看三楼参照教室与中央信息墙留下的姓名和时间细节。
   来源：[src/data/chapter4-755.content.json:399](../src/data/chapter4-755.content.json#L399)
390. 大厅旧钟仍缺少钟面定位片。
   来源：[src/data/chapter4-755.content.json:402](../src/data/chapter4-755.content.json#L402)
391. 从 204 讲台抽屉取得定位片，再拖到旧钟插槽。
   来源：[src/data/chapter4-755.content.json:403](../src/data/chapter4-755.content.json#L403)
392. 保洁车轮的卡滞点尚未确认。
   来源：[src/data/chapter4-755.content.json:406](../src/data/chapter4-755.content.json#L406)
393. 先检查卡住的车轮，再使用短撬棒打开轮罩。
   来源：[src/data/chapter4-755.content.json:407](../src/data/chapter4-755.content.json#L407)
394. 润滑位置仍被轮罩挡住。
   来源：[src/data/chapter4-755.content.json:410](../src/data/chapter4-755.content.json#L410)
395. 先用短撬棒打开轮罩，再取得润滑油。
   来源：[src/data/chapter4-755.content.json:411](../src/data/chapter4-755.content.json#L411)
396. 旧钟齿轮维修仍受保洁车阻挡。
   来源：[src/data/chapter4-755.content.json:414](../src/data/chapter4-755.content.json#L414)
397. 先给保洁车轮上油并让车移动，再处理旧钟齿轮。
   来源：[src/data/chapter4-755.content.json:415](../src/data/chapter4-755.content.json#L415)
398. 旧钟齿轮仍处于断续状态。
   来源：[src/data/chapter4-755.content.json:418](../src/data/chapter4-755.content.json#L418)
399. 先完成车轮维修，再给旧钟齿轮上油。
   来源：[src/data/chapter4-755.content.json:419](../src/data/chapter4-755.content.json#L419)
400. 最后一分钟的拖拽过程尚未就绪。
   来源：[src/data/chapter4-755.content.json:422](../src/data/chapter4-755.content.json#L422)
401. 完成旧钟维修后，在浅色操作中重新开始拖动分针。
   来源：[src/data/chapter4-755.content.json:423](../src/data/chapter4-755.content.json#L423)
402. 配电流程尚未开放或已经锁定。
   来源：[src/data/chapter4-755.content.json:426](../src/data/chapter4-755.content.json#L426)
403. 先完成分针拖拽；若已锁定照明，继续前往 202。
   来源：[src/data/chapter4-755.content.json:427](../src/data/chapter4-755.content.json#L427)
404. 这次追逐请求已失效。
   来源：[src/data/chapter4-755.content.json:430](../src/data/chapter4-755.content.json#L430)
405. 从当前追逐检查点重新开始。
   来源：[src/data/chapter4-755.content.json:431](../src/data/chapter4-755.content.json#L431)
406. 最后一分钟尚未安全取回。
   来源：[src/data/chapter4-755.content.json:434](../src/data/chapter4-755.content.json#L434)
407. 抵达 202 并收取投影中的最后一分钟。
   来源：[src/data/chapter4-755.content.json:435](../src/data/chapter4-755.content.json#L435)
408. 当前还不能把最后一分钟装回旧钟。
   来源：[src/data/chapter4-755.content.json:438](../src/data/chapter4-755.content.json#L438)
409. 携带最后一分钟、校园卡和签到纸，经主楼梯返回一楼大厅。
   来源：[src/data/chapter4-755.content.json:439](../src/data/chapter4-755.content.json#L439)
410. 第三章半的证据恢复尚未闭合。
   来源：[src/data/chapter4-755.content.json:442](../src/data/chapter4-755.content.json#L442)
411. 返回手机完成时间线与地点确认，再继续第四章。
   来源：[src/data/chapter4-755.content.json:443](../src/data/chapter4-755.content.json#L443)
412. 当前签到条件尚未齐全。
   来源：[src/data/chapter4-755.content.json:446](../src/data/chapter4-755.content.json#L446)
413. 确认已到 07:55，并把对应的校园卡或签到纸拖到各自设备。
   来源：[src/data/chapter4-755.content.json:447](../src/data/chapter4-755.content.json#L447)
414. 校园卡验证已经通过。
   来源：[src/data/chapter4-755.content.json:450](../src/data/chapter4-755.content.json#L450)
415. 继续提交签到记录纸。
   来源：[src/data/chapter4-755.content.json:451](../src/data/chapter4-755.content.json#L451)
416. 签到记录纸验证已经通过。
   来源：[src/data/chapter4-755.content.json:454](../src/data/chapter4-755.content.json#L454)
417. 继续读取校园卡。
   来源：[src/data/chapter4-755.content.json:455](../src/data/chapter4-755.content.json#L455)
418. 楼外收束的前置记录尚未齐全。
   来源：[src/data/chapter4-755.content.json:458](../src/data/chapter4-755.content.json#L458)
419. 先完成校园卡与签到纸的双重签到。
   来源：[src/data/chapter4-755.content.json:459](../src/data/chapter4-755.content.json#L459)
420. 正式收束播放尚未得到验证。
   来源：[src/data/chapter4-755.content.json:462](../src/data/chapter4-755.content.json#L462)
421. 完整播放已批准的收束内容后再确认结果。
   来源：[src/data/chapter4-755.content.json:463](../src/data/chapter4-755.content.json#L463)
422. 先点亮烤箱旁的检修灯，让传送带停一下。
   来源：[src/data/chapter4-755.content.json:508](../src/data/chapter4-755.content.json#L508)
423. 等纸条落到公告栏前再抓住它
   来源：[src/data/chapter4-755.content.json:824](../src/data/chapter4-755.content.json#L824)
424. 观察一楼门厅公告栏前的纸条落点。
   来源：[src/data/chapter4-755.content.json:826](../src/data/chapter4-755.content.json#L826)
425. 纸条停稳后才会进入可抓取状态。
   来源：[src/data/chapter4-755.content.json:827](../src/data/chapter4-755.content.json#L827)
426. 纸条落到公告栏前时靠近纸条并执行交互。
   来源：[src/data/chapter4-755.content.json:828](../src/data/chapter4-755.content.json#L828)
427. 查看大厅旧钟
   来源：[src/data/chapter4-755.content.json:832](../src/data/chapter4-755.content.json#L832)
428. 观察一楼大厅中央的旧钟。
   来源：[src/data/chapter4-755.content.json:834](../src/data/chapter4-755.content.json#L834)
429. 先确认缺失指针和卡滞齿轮，才能继续拨动旧钟。
   来源：[src/data/chapter4-755.content.json:835](../src/data/chapter4-755.content.json#L835)
430. 在浅色操作中靠近大厅旧钟并执行交互。
   来源：[src/data/chapter4-755.content.json:836](../src/data/chapter4-755.content.json#L836)
431. 拉动大厅旧钟，让它第一次转动
   来源：[src/data/chapter4-755.content.json:840](../src/data/chapter4-755.content.json#L840)
432. 继续检查大厅旧钟的可操作部位。
   来源：[src/data/chapter4-755.content.json:842](../src/data/chapter4-755.content.json#L842)
433. 完成旧钟检查后，第一次拨动会切换时间来源。
   来源：[src/data/chapter4-755.content.json:843](../src/data/chapter4-755.content.json#L843)
434. 在浅色操作中靠近大厅旧钟并执行拨动交互。
   来源：[src/data/chapter4-755.content.json:844](../src/data/chapter4-755.content.json#L844)
435. 前往面包坊检查检修灯和传送带
   来源：[src/data/chapter4-755.content.json:848](../src/data/chapter4-755.content.json#L848)
436. 观察一楼面包坊烤箱旁的检修灯和传送带边缘。
   来源：[src/data/chapter4-755.content.json:850](../src/data/chapter4-755.content.json#L850)
437. 检修灯亮起后，传送带才会进入停机流程。
   来源：[src/data/chapter4-755.content.json:851](../src/data/chapter4-755.content.json#L851)
438. 在浅色操作中靠近检修灯并交互，等待传送带完全停下。
   来源：[src/data/chapter4-755.content.json:852](../src/data/chapter4-755.content.json#L852)
439. 传送带停下后取走金属时针
   来源：[src/data/chapter4-755.content.json:856](../src/data/chapter4-755.content.json#L856)
440. 查看停止的传送带上新露出的金属部件。
   来源：[src/data/chapter4-755.content.json:858](../src/data/chapter4-755.content.json#L858)
441. 只有停机流程完成后，旧时针才可被取走。
   来源：[src/data/chapter4-755.content.json:859](../src/data/chapter4-755.content.json#L859)
442. 在浅色操作中靠近传送带上的旧时针并执行拾取。
   来源：[src/data/chapter4-755.content.json:860](../src/data/chapter4-755.content.json#L860)
443. 回大厅装回旧时针
   来源：[src/data/chapter4-755.content.json:864](../src/data/chapter4-755.content.json#L864)
444. 返回一楼大厅旧钟的时针缺口。
   来源：[src/data/chapter4-755.content.json:866](../src/data/chapter4-755.content.json#L866)
445. 旧时针只能装入旧钟对应的时针接口。
   来源：[src/data/chapter4-755.content.json:867](../src/data/chapter4-755.content.json#L867)
446. 在浅色操作中把道具栏里的旧时针拖到旧钟时针接口。
   来源：[src/data/chapter4-755.content.json:868](../src/data/chapter4-755.content.json#L868)
447. 前往三楼观察 303 的晨间布置
   来源：[src/data/chapter4-755.content.json:872](../src/data/chapter4-755.content.json#L872)
448. 前往三楼 303 参照教室。
   来源：[src/data/chapter4-755.content.json:874](../src/data/chapter4-755.content.json#L874)
449. 303 晨间参照可在 204 家具摆放前后记录，不限制 204 残影的观察顺序。
   来源：[src/data/chapter4-755.content.json:875](../src/data/chapter4-755.content.json#L875)
450. 保持浅色操作，靠近 303 晨间参照区域并执行记录。
   来源：[src/data/chapter4-755.content.json:876](../src/data/chapter4-755.content.json#L876)
451. 汇总 A1 剩余调查点
   来源：[src/data/chapter4-755.content.json:880](../src/data/chapter4-755.content.json#L880)
452. 104 黑板、105 讲台、主电梯和值班签到板都位于一楼，可自由选择先查看哪一处。
   来源：[src/data/chapter4-755.content.json:882](../src/data/chapter4-755.content.json#L882)
453. 主电梯的历史轨道需要 104 与 105 的时间差记录；值班签到板可以在前后任意时机重建。
   来源：[src/data/chapter4-755.content.json:883](../src/data/chapter4-755.content.json#L883)
454. 深色观察读取痕迹，浅色操作调整设备；两种模式的进入顺序不会锁死进度。
   来源：[src/data/chapter4-755.content.json:884](../src/data/chapter4-755.content.json#L884)
455. 完成 104 与 105 的时间差校验
   来源：[src/data/chapter4-755.content.json:888](../src/data/chapter4-755.content.json#L888)
456. 104 与 105 各保留了一种时间延迟记录，两项都确认后才能使用楼层通道。
   来源：[src/data/chapter4-755.content.json:890](../src/data/chapter4-755.content.json#L890)
457. 104 使用深色观察读取黑板擦痕残留。
   来源：[src/data/chapter4-755.content.json:891](../src/data/chapter4-755.content.json#L891)
458. 105 使用浅色操作检查讲台本地回放；两间教室可按任意顺序处理。
   来源：[src/data/chapter4-755.content.json:892](../src/data/chapter4-755.content.json#L892)
459. 完成主电梯历史读取与重放校准
   来源：[src/data/chapter4-755.content.json:896](../src/data/chapter4-755.content.json#L896)
460. 104 与 105 的两项校验完成后，主电梯会留下轿厢、门体和进入窗口三条轨道。
   来源：[src/data/chapter4-755.content.json:898](../src/data/chapter4-755.content.json#L898)
461. 深色观察可在一楼电梯门前记录三条轨道；浅色操作可进入轿厢校准重放起点。
   来源：[src/data/chapter4-755.content.json:899](../src/data/chapter4-755.content.json#L899)
462. 读取与校准互不作为对方的前置条件，两项均完成后电梯线索收束。
   来源：[src/data/chapter4-755.content.json:900](../src/data/chapter4-755.content.json#L900)
463. 校准主电梯的 18:50 重放窗口
   来源：[src/data/chapter4-755.content.json:904](../src/data/chapter4-755.content.json#L904)
464. 在浅色操作中进入一楼主电梯轿厢。
   来源：[src/data/chapter4-755.content.json:906](../src/data/chapter4-755.content.json#L906)
465. 调整重放起点，让门体开放区间完整覆盖人物的六秒进入窗口。
   来源：[src/data/chapter4-755.content.json:907](../src/data/chapter4-755.content.json#L907)
466. 校准成功后乘电梯直达三楼，二楼按钮会暂时锁定。
   来源：[src/data/chapter4-755.content.json:908](../src/data/chapter4-755.content.json#L908)
467. 复核三层停靠记录，确认定位片的楼层基准
   来源：[src/data/chapter4-755.content.json:912](../src/data/chapter4-755.content.json#L912)
468. 一楼起行轨、三楼到站铃和二楼外呼日志可以按任意顺序归档。
   来源：[src/data/chapter4-755.content.json:914](../src/data/chapter4-755.content.json#L914)
469. 在各层主电梯轿厢中使用深色观察读取本层记录；二楼需先经三楼错位楼梯进入。
   来源：[src/data/chapter4-755.content.json:915](../src/data/chapter4-755.content.json#L915)
470. 三段记录齐全后切回浅色操作，在电梯面板确认实际到站层和未响应外呼层。
   来源：[src/data/chapter4-755.content.json:916](../src/data/chapter4-755.content.json#L916)
471. 在未点亮的灿若星辰灯前回答竺老两问
   来源：[src/data/chapter4-755.content.json:920](../src/data/chapter4-755.content.json#L920)
472. 双重签到完成后，楼外会保留一盏未点亮的灿若星辰灯。
   来源：[src/data/chapter4-755.content.json:922](../src/data/chapter4-755.content.json#L922)
473. 分别选择求学目的与希望成为的人，系统会一次保存两项回答。
   来源：[src/data/chapter4-755.content.json:923](../src/data/chapter4-755.content.json#L923)
474. 确认文字只显示“回答已保存”；随后才开始点灯收束。
   来源：[src/data/chapter4-755.content.json:924](../src/data/chapter4-755.content.json#L924)
475. 在三楼记录晨间教室参照
   来源：[src/data/chapter4-755.content.json:928](../src/data/chapter4-755.content.json#L928)
476. 前往三楼晨间教室，在深色观察中记录桌椅、入口与投影边界。
   来源：[src/data/chapter4-755.content.json:930](../src/data/chapter4-755.content.json#L930)
477. 荣誉墙画像只提供人物生平与资料来源，301 与 302 影像可继续查阅。
   来源：[src/data/chapter4-755.content.json:931](../src/data/chapter4-755.content.json#L931)
478. 晨间教室参照记录完成后，主楼梯开放空间校准。
   来源：[src/data/chapter4-755.content.json:932](../src/data/chapter4-755.content.json#L932)
479. 接通三楼通往二楼的错位楼梯
   来源：[src/data/chapter4-755.content.json:936](../src/data/chapter4-755.content.json#L936)
480. 记录三楼晨间教室参照后，前往主楼梯下行口。
   来源：[src/data/chapter4-755.content.json:938](../src/data/chapter4-755.content.json#L938)
481. 在三个固定视角中调节横移台、旋转梯和升降台，让投影端点形成连续通路。
   来源：[src/data/chapter4-755.content.json:939](../src/data/chapter4-755.content.json#L939)
482. 完成两段楼梯间后会从二楼交通核心恢复行动。
   来源：[src/data/chapter4-755.content.json:940](../src/data/chapter4-755.content.json#L940)
483. 回到二楼，在深色观察中确认 204 残影
   来源：[src/data/chapter4-755.content.json:944](../src/data/chapter4-755.content.json#L944)
484. 返回二楼 204，查看教室中的成组家具残影。
   来源：[src/data/chapter4-755.content.json:946](../src/data/chapter4-755.content.json#L946)
485. 204 的复原需要同时具备 303 参照和 204 残影记录。
   来源：[src/data/chapter4-755.content.json:947](../src/data/chapter4-755.content.json#L947)
486. 切到深色观察，靠近 204 残影区域并执行观察。
   来源：[src/data/chapter4-755.content.json:948](../src/data/chapter4-755.content.json#L948)
487. 把教室恢复成早晨的样子
   来源：[src/data/chapter4-755.content.json:952](../src/data/chapter4-755.content.json#L952)
488. 303 晨间参照、204 深色残影和浅色家具摆放可按任意顺序完成。
   来源：[src/data/chapter4-755.content.json:954](../src/data/chapter4-755.content.json#L954)
489. 十二件家具按四处原始痕迹分成四组，每次摆放同时复原一组。
   来源：[src/data/chapter4-755.content.json:955](../src/data/chapter4-755.content.json#L955)
490. 浅色操作可先摆放家具；缺失的参照或残影随后补齐时，系统会统一确认复原结果。
   来源：[src/data/chapter4-755.content.json:956](../src/data/chapter4-755.content.json#L956)
491. 查看 204 投影幕上的时间
   来源：[src/data/chapter4-755.content.json:960](../src/data/chapter4-755.content.json#L960)
492. 完成复原后查看 204 前方的投影幕。
   来源：[src/data/chapter4-755.content.json:962](../src/data/chapter4-755.content.json#L962)
493. 四组家具全部就位后，投影记录才会稳定。
   来源：[src/data/chapter4-755.content.json:963](../src/data/chapter4-755.content.json#L963)
494. 留在 204 内完成投影播放，并在稳定画面出现后执行确认。
   来源：[src/data/chapter4-755.content.json:964](../src/data/chapter4-755.content.json#L964)
495. 从 204 讲台抽屉取出钟面定位片
   来源：[src/data/chapter4-755.content.json:968](../src/data/chapter4-755.content.json#L968)
496. 查看 204 讲台的抽屉。
   来源：[src/data/chapter4-755.content.json:970](../src/data/chapter4-755.content.json#L970)
497. 投影记录完成后，讲台抽屉才会开放。
   来源：[src/data/chapter4-755.content.json:971](../src/data/chapter4-755.content.json#L971)
498. 在浅色操作中靠近讲台抽屉并执行拾取，取得钟面定位片。
   来源：[src/data/chapter4-755.content.json:972](../src/data/chapter4-755.content.json#L972)
499. 补齐 A2 三处现场记录
   来源：[src/data/chapter4-755.content.json:976](../src/data/chapter4-755.content.json#L976)
500. 201 定位板、203 五区拓扑和开放自习区疏散路线互相独立，可以任意顺序处理。
   来源：[src/data/chapter4-755.content.json:978](../src/data/chapter4-755.content.json#L978)
501. 深色观察用于读取旧痕，浅色操作用于校准、连线和排列；观察不构成提交的硬前置。
   来源：[src/data/chapter4-755.content.json:979](../src/data/chapter4-755.content.json#L979)
502. 三处记录完成后，钟面定位片才具备可验证的安装依据。
   来源：[src/data/chapter4-755.content.json:980](../src/data/chapter4-755.content.json#L980)
503. 把钟面定位片装回大厅旧钟
   来源：[src/data/chapter4-755.content.json:984](../src/data/chapter4-755.content.json#L984)
504. 返回一楼大厅旧钟的定位片接口。
   来源：[src/data/chapter4-755.content.json:986](../src/data/chapter4-755.content.json#L986)
505. 钟面定位片只接受从 204 讲台取得的对应道具。
   来源：[src/data/chapter4-755.content.json:987](../src/data/chapter4-755.content.json#L987)
506. 在浅色操作中把钟面定位片拖到旧钟定位片接口。
   来源：[src/data/chapter4-755.content.json:988](../src/data/chapter4-755.content.json#L988)
507. 诊断保洁车与旧钟的联动故障
   来源：[src/data/chapter4-755.content.json:992](../src/data/chapter4-755.content.json#L992)
508. 靠近保洁车检查车轮声音、旧钟卡滞和地面油迹。
   来源：[src/data/chapter4-755.content.json:994](../src/data/chapter4-755.content.json#L994)
509. 三项现象分别对应一种故障原因；提交前可以反复改选。
   来源：[src/data/chapter4-755.content.json:995](../src/data/chapter4-755.content.json#L995)
510. 诊断正确后会取得执行维修所需的短撬棍与润滑油。
   来源：[src/data/chapter4-755.content.json:996](../src/data/chapter4-755.content.json#L996)
511. 去面包店后场取短撬棍
   来源：[src/data/chapter4-755.content.json:1000](../src/data/chapter4-755.content.json#L1000)
512. 前往一楼面包坊后场查找可用工具。
   来源：[src/data/chapter4-755.content.json:1002](../src/data/chapter4-755.content.json#L1002)
513. 轮罩需要短撬棍打开，其他道具不会被接受。
   来源：[src/data/chapter4-755.content.json:1003](../src/data/chapter4-755.content.json#L1003)
514. 在浅色操作中靠近面包坊后场的短撬棍并执行拾取。
   来源：[src/data/chapter4-755.content.json:1004](../src/data/chapter4-755.content.json#L1004)
515. 用短撬棍打开保洁车轮罩
   来源：[src/data/chapter4-755.content.json:1008](../src/data/chapter4-755.content.json#L1008)
516. 返回保洁车的车轮罩。
   来源：[src/data/chapter4-755.content.json:1010](../src/data/chapter4-755.content.json#L1010)
517. 诊断完成后，短撬棍可用于打开卡住的轮罩，并会在本次使用后消耗。
   来源：[src/data/chapter4-755.content.json:1011](../src/data/chapter4-755.content.json#L1011)
518. 在浅色操作中把短撬棍拖到保洁车轮罩。
   来源：[src/data/chapter4-755.content.json:1012](../src/data/chapter4-755.content.json#L1012)
519. 取出轮罩内的通用润滑油
   来源：[src/data/chapter4-755.content.json:1016](../src/data/chapter4-755.content.json#L1016)
520. 查看已经打开的保洁车轮罩内部。
   来源：[src/data/chapter4-755.content.json:1018](../src/data/chapter4-755.content.json#L1018)
521. 轮罩打开后，通用润滑油才会出现为可拾取道具。
   来源：[src/data/chapter4-755.content.json:1019](../src/data/chapter4-755.content.json#L1019)
522. 在浅色操作中靠近轮罩内的润滑油并执行拾取。
   来源：[src/data/chapter4-755.content.json:1020](../src/data/chapter4-755.content.json#L1020)
523. 润滑轮轴并校正旧钟齿轮
   来源：[src/data/chapter4-755.content.json:1024](../src/data/chapter4-755.content.json#L1024)
524. 观察保洁车已打开轮罩的车轮。
   来源：[src/data/chapter4-755.content.json:1026](../src/data/chapter4-755.content.json#L1026)
525. 诊断确认车轮缺油与旧钟齿轮偏位属于同一次卡滞。
   来源：[src/data/chapter4-755.content.json:1027](../src/data/chapter4-755.content.json#L1027)
526. 在浅色操作中把通用润滑油拖到保洁车轮，完成联动修复。
   来源：[src/data/chapter4-755.content.json:1028](../src/data/chapter4-755.content.json#L1028)
527. 用剩下的润滑油修复旧钟齿轮
   来源：[src/data/chapter4-755.content.json:1032](../src/data/chapter4-755.content.json#L1032)
528. 返回一楼大厅旧钟的齿轮位置。
   来源：[src/data/chapter4-755.content.json:1034](../src/data/chapter4-755.content.json#L1034)
529. 车轮修复完成后，剩余润滑油才可用于旧钟齿轮，并会在使用后消耗。
   来源：[src/data/chapter4-755.content.json:1035](../src/data/chapter4-755.content.json#L1035)
530. 在浅色操作中把通用润滑油拖到大厅旧钟齿轮。
   来源：[src/data/chapter4-755.content.json:1036](../src/data/chapter4-755.content.json#L1036)
531. 把旧钟拨向 07:55
   来源：[src/data/chapter4-755.content.json:1040](../src/data/chapter4-755.content.json#L1040)；[src/data/chapter4-755.content.json:1736](../src/data/chapter4-755.content.json#L1736)
532. 查看维修完成后的大厅旧钟表盘。
   来源：[src/data/chapter4-755.content.json:1042](../src/data/chapter4-755.content.json#L1042)
533. 车轮与钟内齿轮均修复后，旧钟才接受最终校时。
   来源：[src/data/chapter4-755.content.json:1043](../src/data/chapter4-755.content.json#L1043)
534. 在浅色操作中拖动旧钟分针到 07:55 刻度并松开。
   来源：[src/data/chapter4-755.content.json:1044](../src/data/chapter4-755.content.json#L1044)
535. 查看一楼停电状态下的配电面板和五个灯区。
   来源：[src/data/chapter4-755.content.json:1050](../src/data/chapter4-755.content.json#L1050)
536. 只校验必要路线：大厅、东走廊和教室区亮起，西走廊和面包店后场保持关闭。
   来源：[src/data/chapter4-755.content.json:1051](../src/data/chapter4-755.content.json#L1051)
537. 在浅色操作中切换对应灯区，满足五个必要条件后点击锁定。
   来源：[src/data/chapter4-755.content.json:1052](../src/data/chapter4-755.content.json#L1052)
538. 前往 202
   来源：[src/data/chapter4-755.content.json:1056](../src/data/chapter4-755.content.json#L1056)
539. 观察最后一分钟经过的主楼梯和二楼走廊。
   来源：[src/data/chapter4-755.content.json:1058](../src/data/chapter4-755.content.json#L1058)
540. 追逐阶段只保存当前追逐检查点，失败会从该段重新开始。
   来源：[src/data/chapter4-755.content.json:1059](../src/data/chapter4-755.content.json#L1059)
541. 沿一楼主楼梯进入二楼，继续移动到 202 门口的到达区域。
   来源：[src/data/chapter4-755.content.json:1060](../src/data/chapter4-755.content.json#L1060)
542. 取回最后一分钟
   来源：[src/data/chapter4-755.content.json:1064](../src/data/chapter4-755.content.json#L1064)
543. 查看二楼 202 内的投影区域。
   来源：[src/data/chapter4-755.content.json:1066](../src/data/chapter4-755.content.json#L1066)
544. 到达 202 后，最后一分钟与签到记录纸会在同一记录点恢复。
   来源：[src/data/chapter4-755.content.json:1067](../src/data/chapter4-755.content.json#L1067)
545. 在浅色操作中靠近 202 投影并执行拾取。
   来源：[src/data/chapter4-755.content.json:1068](../src/data/chapter4-755.content.json#L1068)
546. 沿主楼梯回到一楼旧钟
   来源：[src/data/chapter4-755.content.json:1072](../src/data/chapter4-755.content.json#L1072)
547. 从二楼 202 返回二楼主楼梯入口。
   来源：[src/data/chapter4-755.content.json:1074](../src/data/chapter4-755.content.json#L1074)
548. 携带最后一分钟时，跨层返回只接受主楼梯路线。
   来源：[src/data/chapter4-755.content.json:1075](../src/data/chapter4-755.content.json#L1075)
549. 进入二楼主楼梯通行区，沿主楼梯回到一楼大厅。
   来源：[src/data/chapter4-755.content.json:1076](../src/data/chapter4-755.content.json#L1076)
550. 把最后一分钟装回旧钟
   来源：[src/data/chapter4-755.content.json:1080](../src/data/chapter4-755.content.json#L1080)
551. 查看一楼大厅旧钟的分针端点。
   来源：[src/data/chapter4-755.content.json:1082](../src/data/chapter4-755.content.json#L1082)
552. 最后一分钟只能装回大厅旧钟的分钟接口。
   来源：[src/data/chapter4-755.content.json:1083](../src/data/chapter4-755.content.json#L1083)
553. 在浅色操作中把道具栏里的最后一分钟拖到旧钟分钟接口。
   来源：[src/data/chapter4-755.content.json:1084](../src/data/chapter4-755.content.json#L1084)
554. 完成刷卡与纸条签到
   来源：[src/data/chapter4-755.content.json:1088](../src/data/chapter4-755.content.json#L1088)
555. 观察一楼签到区的校园卡读卡器和签到记录纸插槽。
   来源：[src/data/chapter4-755.content.json:1090](../src/data/chapter4-755.content.json#L1090)
556. 两项验证互不依赖，任意顺序完成，进度只按两个已接受事实计算。
   来源：[src/data/chapter4-755.content.json:1091](../src/data/chapter4-755.content.json#L1091)
557. 在浅色操作中把校园卡拖到读卡器，并把签到记录纸拖到纸条插槽。
   来源：[src/data/chapter4-755.content.json:1092](../src/data/chapter4-755.content.json#L1092)
558. 使用校园卡完成刷卡
   来源：[src/data/chapter4-755.content.json:1096](../src/data/chapter4-755.content.json#L1096)
559. 查看一楼签到区的校园卡读卡器。
   来源：[src/data/chapter4-755.content.json:1098](../src/data/chapter4-755.content.json#L1098)
560. 读卡器只接受校园卡，已完成的纸条验证不会被清除。
   来源：[src/data/chapter4-755.content.json:1099](../src/data/chapter4-755.content.json#L1099)
561. 在浅色操作中把校园卡拖到校园卡读卡器。
   来源：[src/data/chapter4-755.content.json:1100](../src/data/chapter4-755.content.json#L1100)
562. 提交签到记录纸条
   来源：[src/data/chapter4-755.content.json:1104](../src/data/chapter4-755.content.json#L1104)
563. 查看一楼签到区的签到记录纸插槽。
   来源：[src/data/chapter4-755.content.json:1106](../src/data/chapter4-755.content.json#L1106)
564. 纸条插槽只接受已恢复的签到记录纸，已完成的刷卡验证不会被清除。
   来源：[src/data/chapter4-755.content.json:1107](../src/data/chapter4-755.content.json#L1107)
565. 在浅色操作中把签到记录纸拖到纸条插槽。
   来源：[src/data/chapter4-755.content.json:1108](../src/data/chapter4-755.content.json#L1108)
566. 观看并完成楼外正式收束
   来源：[src/data/chapter4-755.content.json:1112](../src/data/chapter4-755.content.json#L1112)
567. 完成双重签到后，查看教学楼外的正式收束画面。
   来源：[src/data/chapter4-755.content.json:1114](../src/data/chapter4-755.content.json#L1114)
568. 楼外画面完整播放并通过会话校验后，章节会自动完成。
   来源：[src/data/chapter4-755.content.json:1115](../src/data/chapter4-755.content.json#L1115)
569. 保持画面开启，直到灿若星辰灯全部点亮。
   来源：[src/data/chapter4-755.content.json:1116](../src/data/chapter4-755.content.json#L1116)
570. 本人来过
   来源：[src/data/chapter4-755.content.json:1120](../src/data/chapter4-755.content.json#L1120)
571. system
   来源：[src/data/chapter4-755.content.json:1127](../src/data/chapter4-755.content.json#L1127)；[src/data/chapter4-755.content.json:1137](../src/data/chapter4-755.content.json#L1137)；[src/data/chapter4-755.content.json:1143](../src/data/chapter4-755.content.json#L1143)；[src/data/chapter4-755.content.json:1147](../src/data/chapter4-755.content.json#L1147)；[src/data/chapter4-755.content.json:1155](../src/data/chapter4-755.content.json#L1155)；[src/data/chapter4-755.content.json:1159](../src/data/chapter4-755.content.json#L1159)；[src/data/chapter4-755.content.json:1165](../src/data/chapter4-755.content.json#L1165)；[src/data/chapter4-755.content.json:1173](../src/data/chapter4-755.content.json#L1173)；[src/data/chapter4-755.content.json:1179](../src/data/chapter4-755.content.json#L1179)；[src/data/chapter4-755.content.json:1199](../src/data/chapter4-755.content.json#L1199)；[src/data/chapter4-755.content.json:1209](../src/data/chapter4-755.content.json#L1209)；[src/data/chapter4-755.content.json:1213](../src/data/chapter4-755.content.json#L1213)；[src/data/chapter4-755.content.json:1297](../src/data/chapter4-755.content.json#L1297)；[src/data/chapter4-755.content.json:1303](../src/data/chapter4-755.content.json#L1303)；[src/data/chapter4-755.content.json:1323](../src/data/chapter4-755.content.json#L1323)；[src/data/chapter4-755.content.json:1331](../src/data/chapter4-755.content.json#L1331)；[src/data/chapter4-755.content.json:1359](../src/data/chapter4-755.content.json#L1359)；[src/data/chapter4-755.content.json:1365](../src/data/chapter4-755.content.json#L1365)；[src/data/chapter4-755.content.json:1371](../src/data/chapter4-755.content.json#L1371)；[src/data/chapter4-755.content.json:1385](../src/data/chapter4-755.content.json#L1385)；[src/data/chapter4-755.content.json:1391](../src/data/chapter4-755.content.json#L1391)；[src/data/chapter4-755.content.json:1397](../src/data/chapter4-755.content.json#L1397)；[src/data/chapter4-755.content.json:1403](../src/data/chapter4-755.content.json#L1403)；[src/data/chapter4-755.content.json:1411](../src/data/chapter4-755.content.json#L1411)；[src/data/chapter4-755.content.json:1417](../src/data/chapter4-755.content.json#L1417)；[src/data/chapter4-755.content.json:1425](../src/data/chapter4-755.content.json#L1425)；[src/scenes/phone/P14_Wechat/index.tsx:447](../src/scenes/phone/P14_Wechat/index.tsx#L447)；[src/scenes/phone/P14_Wechat/index.tsx:450](../src/scenes/phone/P14_Wechat/index.tsx#L450)
572. 现场画面已同步。异常签到纸正在飞向公告栏。
   来源：[src/data/chapter4-755.content.json:1128](../src/data/chapter4-755.content.json#L1128)
573. player
   来源：[src/data/chapter4-755.content.json:1133](../src/data/chapter4-755.content.json#L1133)；[src/data/chapter4-755.content.json:1151](../src/data/chapter4-755.content.json#L1151)；[src/data/chapter4-755.content.json:1169](../src/data/chapter4-755.content.json#L1169)；[src/data/chapter4-755.content.json:1189](../src/data/chapter4-755.content.json#L1189)；[src/data/chapter4-755.content.json:1203](../src/data/chapter4-755.content.json#L1203)；[src/data/chapter4-755.content.json:1313](../src/data/chapter4-755.content.json#L1313)；[src/data/chapter4-755.content.json:1327](../src/data/chapter4-755.content.json#L1327)；[src/data/chapter4-755.content.json:1377](../src/data/chapter4-755.content.json#L1377)；[src/data/chapter4-755.content.json:1407](../src/data/chapter4-755.content.json#L1407)；[src/data/chapter4-755.content.json:1421](../src/data/chapter4-755.content.json#L1421)
574. 抓到了。
   来源：[src/data/chapter4-755.content.json:1134](../src/data/chapter4-755.content.json#L1134)
575. 正在提交签到记录……
   来源：[src/data/chapter4-755.content.json:1138](../src/data/chapter4-755.content.json#L1138)
576. 提交失败。外部时间：22:45。
   来源：[src/data/chapter4-755.content.json:1144](../src/data/chapter4-755.content.json#L1144)
577. 签到截止时间：07:55。
   来源：[src/data/chapter4-755.content.json:1148](../src/data/chapter4-755.content.json#L1148)
578. 手机上还写着 07:55:23。
   来源：[src/data/chapter4-755.content.json:1152](../src/data/chapter4-755.content.json#L1152)
579. 它已经被四个外部来源否定了。
   来源：[src/data/chapter4-755.content.json:1156](../src/data/chapter4-755.content.json#L1156)
580. 记录回来了，你没有回到记录发生的时候。
   来源：[src/data/chapter4-755.content.json:1160](../src/data/chapter4-755.content.json#L1160)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8291](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8291)
581. 旧钟能被拨动，但指针不会按你的动作走。
   来源：[src/data/chapter4-755.content.json:1166](../src/data/chapter4-755.content.json#L1166)
582. 这是好消息？
   来源：[src/data/chapter4-755.content.json:1170](../src/data/chapter4-755.content.json#L1170)
583. 它还在出错。
   来源：[src/data/chapter4-755.content.json:1174](../src/data/chapter4-755.content.json#L1174)
584. 时间源已切换：大厅旧钟。
   来源：[src/data/chapter4-755.content.json:1180](../src/data/chapter4-755.content.json#L1180)
585. baker
   来源：[src/data/chapter4-755.content.json:1185](../src/data/chapter4-755.content.json#L1185)；[src/data/chapter4-755.content.json:1193](../src/data/chapter4-755.content.json#L1193)
586. 你拿走那个？我还以为它是新品配料。
   来源：[src/data/chapter4-755.content.json:1186](../src/data/chapter4-755.content.json#L1186)
587. 它本来是时针。
   来源：[src/data/chapter4-755.content.json:1190](../src/data/chapter4-755.content.json#L1190)
588. 那它总算找到对口味了。
   来源：[src/data/chapter4-755.content.json:1194](../src/data/chapter4-755.content.json#L1194)
589. 黑板已经擦净，残留笔画仍按书写顺序逐段出现。首尾相差 7 分 55 秒。
   来源：[src/data/chapter4-755.content.json:1200](../src/data/chapter4-755.content.json#L1200)
590. 房间空了，板书还在补完上一节课。
   来源：[src/data/chapter4-755.content.json:1204](../src/data/chapter4-755.content.json#L1204)
591. 讲台回放停在 07:47:05，教室记录显示 07:55:00。本地画面延迟 7 分 55 秒。
   来源：[src/data/chapter4-755.content.json:1210](../src/data/chapter4-755.content.json#L1210)
592. 该终端只能证明回放延迟，不能用于校准现场时间。
   来源：[src/data/chapter4-755.content.json:1214](../src/data/chapter4-755.content.json#L1214)
593. 值班助理
   来源：[src/data/chapter4-755.content.json:1219](../src/data/chapter4-755.content.json#L1219)；[src/data/chapter4-755.content.json:1225](../src/data/chapter4-755.content.json#L1225)；[src/data/chapter4-755.content.json:1231](../src/data/chapter4-755.content.json#L1231)；[src/data/chapter4-755.content.json:1237](../src/data/chapter4-755.content.json#L1237)；[src/data/chapter4-755.content.json:1243](../src/data/chapter4-755.content.json#L1243)；[src/data/chapter4-755.content.json:1249](../src/data/chapter4-755.content.json#L1249)；[src/data/chapter4-755.content.json:1255](../src/data/chapter4-755.content.json#L1255)
594. 面包坊那边的传送带刚停过一次。旧钟缺少的部件可能在那里。
   来源：[src/data/chapter4-755.content.json:1220](../src/data/chapter4-755.content.json#L1220)
595. 104 要观察黑板残留，105 要检查讲台本地回放。两项都登记后，楼层通行才会恢复。
   来源：[src/data/chapter4-755.content.json:1226](../src/data/chapter4-755.content.json#L1226)
596. 104 已登记。105 讲台回放还没有检查。
   来源：[src/data/chapter4-755.content.json:1232](../src/data/chapter4-755.content.json#L1232)
597. 105 已登记。104 黑板残留还没有观察。
   来源：[src/data/chapter4-755.content.json:1238](../src/data/chapter4-755.content.json#L1238)
598. 两项时间差记录都已登记。现在可以继续核对二楼和三楼。
   来源：[src/data/chapter4-755.content.json:1244](../src/data/chapter4-755.content.json#L1244)
599. 现在是 07:55。校园卡放到左侧读卡器，签到纸放入右侧纸槽。
   来源：[src/data/chapter4-755.content.json:1250](../src/data/chapter4-755.content.json#L1250)
600. 大厅旧钟、签到记录和外部时间已经一致。今天的记录可以归档。
   来源：[src/data/chapter4-755.content.json:1256](../src/data/chapter4-755.content.json#L1256)
601. 安全员
   来源：[src/data/chapter4-755.content.json:1261](../src/data/chapter4-755.content.json#L1261)；[src/data/chapter4-755.content.json:1267](../src/data/chapter4-755.content.json#L1267)；[src/data/chapter4-755.content.json:1273](../src/data/chapter4-755.content.json#L1273)
602. 二楼电梯口暂不放行。先把一楼 104 黑板残留和 105 讲台回放都登记完。
   来源：[src/data/chapter4-755.content.json:1262](../src/data/chapter4-755.content.json#L1262)
603. 一楼两项记录已到。先去三楼参照教室核对标准布局，再回 204。
   来源：[src/data/chapter4-755.content.json:1268](../src/data/chapter4-755.content.json#L1268)
604. 三楼参照已登记。现在可以进 204，按残影恢复讲台和桌椅位置。
   来源：[src/data/chapter4-755.content.json:1274](../src/data/chapter4-755.content.json#L1274)
605. 教师
   来源：[src/data/chapter4-755.content.json:1279](../src/data/chapter4-755.content.json#L1279)；[src/data/chapter4-755.content.json:1285](../src/data/chapter4-755.content.json#L1285)
606. 这间教室保留标准布局。用深色观察记录讲台、桌椅和入口边界，完成后回二楼 204。
   来源：[src/data/chapter4-755.content.json:1280](../src/data/chapter4-755.content.json#L1280)
607. 标准布局已经记录。二楼 204 需要的是这份参照。
   来源：[src/data/chapter4-755.content.json:1286](../src/data/chapter4-755.content.json#L1286)
608. projection
   来源：[src/data/chapter4-755.content.json:1291](../src/data/chapter4-755.content.json#L1291)
609. 07:55 / 早到的人还没有开始后悔。
   来源：[src/data/chapter4-755.content.json:1292](../src/data/chapter4-755.content.json#L1292)；[src/data/chapter4-three-floor-maze.layout.json:808](../src/data/chapter4-three-floor-maze.layout.json#L808)
610. 三楼晨间教室的讲台、桌椅和入口边界已经记录。
   来源：[src/data/chapter4-755.content.json:1298](../src/data/chapter4-755.content.json#L1298)
611. 残影把每组桌椅原来的位置都记下来了。
   来源：[src/data/chapter4-755.content.json:1304](../src/data/chapter4-755.content.json#L1304)
612. cleaner
   来源：[src/data/chapter4-755.content.json:1309](../src/data/chapter4-755.content.json#L1309)；[src/data/chapter4-755.content.json:1317](../src/data/chapter4-755.content.json#L1317)
613. 它没坏，只是不肯走。
   来源：[src/data/chapter4-755.content.json:1310](../src/data/chapter4-755.content.json#L1310)
614. 我有办法让它走。
   来源：[src/data/chapter4-755.content.json:1314](../src/data/chapter4-755.content.json#L1314)
615. 那你先让它别叫。
   来源：[src/data/chapter4-755.content.json:1318](../src/data/chapter4-755.content.json#L1318)
616. 时间校准至 07:54。
   来源：[src/data/chapter4-755.content.json:1324](../src/data/chapter4-755.content.json#L1324)
617. 差一分钟。
   来源：[src/data/chapter4-755.content.json:1328](../src/data/chapter4-755.content.json#L1328)
618. 纸条把最后一分钟带走了。定位结果：阶梯教室。
   来源：[src/data/chapter4-755.content.json:1332](../src/data/chapter4-755.content.json#L1332)
619. guard
   来源：[src/data/chapter4-755.content.json:1337](../src/data/chapter4-755.content.json#L1337)；[src/data/chapter4-755.content.json:1343](../src/data/chapter4-755.content.json#L1343)；[src/data/chapter4-755.content.json:1349](../src/data/chapter4-755.content.json#L1349)；[src/data/chapter4-755.content.json:1355](../src/data/chapter4-755.content.json#L1355)
620. 同学，站住。离旧钟远一点。
   来源：[src/data/chapter4-755.content.json:1338](../src/data/chapter4-755.content.json#L1338)；[src/data/pursuit.audio.content.json:87](../src/data/pursuit.audio.content.json#L87)
621. 我看到你了。停下。
   来源：[src/data/chapter4-755.content.json:1344](../src/data/chapter4-755.content.json#L1344)；[src/data/pursuit.audio.content.json:115](../src/data/pursuit.audio.content.json#L115)
622. 别往楼上跑。现在停下。
   来源：[src/data/chapter4-755.content.json:1350](../src/data/chapter4-755.content.json#L1350)；[src/data/pursuit.audio.content.json:101](../src/data/pursuit.audio.content.json#L101)
623. 出去。
   来源：[src/data/chapter4-755.content.json:1356](../src/data/chapter4-755.content.json#L1356)
624. 你被清楼流程退回了上一分钟。
   来源：[src/data/chapter4-755.content.json:1360](../src/data/chapter4-755.content.json#L1360)
625. 被清楼保安拦下了，已回到一楼大厅重来。
   来源：[src/data/chapter4-755.content.json:1366](../src/data/chapter4-755.content.json#L1366)
626. 阶梯教室门已关闭。
   来源：[src/data/chapter4-755.content.json:1372](../src/data/chapter4-755.content.json#L1372)
627. 不跑了？
   来源：[src/data/chapter4-755.content.json:1378](../src/data/chapter4-755.content.json#L1378)
628. paper
   来源：[src/data/chapter4-755.content.json:1381](../src/data/chapter4-755.content.json#L1381)
629. 本人马上回来。
   来源：[src/data/chapter4-755.content.json:1382](../src/data/chapter4-755.content.json#L1382)
630. 它回来了。
   来源：[src/data/chapter4-755.content.json:1386](../src/data/chapter4-755.content.json#L1386)
631. 最后一分钟和签到纸条都回来了。
   来源：[src/data/chapter4-755.content.json:1392](../src/data/chapter4-755.content.json#L1392)
632. 07:55 已经回到门厅。
   来源：[src/data/chapter4-755.content.json:1398](../src/data/chapter4-755.content.json#L1398)
633. 签到成功。时间：07:55。地点：段永平教学楼 A1。状态：本人来过。
   来源：[src/data/chapter4-755.content.json:1404](../src/data/chapter4-755.content.json#L1404)
634. 现在算准时吗？
   来源：[src/data/chapter4-755.content.json:1408](../src/data/chapter4-755.content.json#L1408)
635. 从时间角度，算。
   来源：[src/data/chapter4-755.content.json:1412](../src/data/chapter4-755.content.json#L1412)
636. 外面亮了一下。
   来源：[src/data/chapter4-755.content.json:1418](../src/data/chapter4-755.content.json#L1418)；[src/modules/ChapterFourTemporalMazeController.ts:1716](../src/modules/ChapterFourTemporalMazeController.ts#L1716)；[src/modules/ChapterFourTemporalMazeController.ts:1746](../src/modules/ChapterFourTemporalMazeController.ts#L1746)
637. 这次真的结束了？
   来源：[src/data/chapter4-755.content.json:1422](../src/data/chapter4-755.content.json#L1422)
638. 这次是。时间同意了。
   来源：[src/data/chapter4-755.content.json:1426](../src/data/chapter4-755.content.json#L1426)
639. 窗侧时间刻痕区
   来源：[src/data/chapter4-755.content.json:1530](../src/data/chapter4-755.content.json#L1530)
640. 窗沿粉尘断线与前三处桌面亮边位于同一水平带。
   来源：[src/data/chapter4-755.content.json:1532](../src/data/chapter4-755.content.json#L1532)
641. 中央拖痕区
   来源：[src/data/chapter4-755.content.json:1556](../src/data/chapter4-755.content.json#L1556)
642. 中央地面的三段平行拖痕具有相同间距。
   来源：[src/data/chapter4-755.content.json:1558](../src/data/chapter4-755.content.json#L1558)
643. 讲台投影边缘区
   来源：[src/data/chapter4-755.content.json:1582](../src/data/chapter4-755.content.json#L1582)
644. 讲台投影边缘经过三处桌脚留下的浅色缺口。
   来源：[src/data/chapter4-755.content.json:1584](../src/data/chapter4-755.content.json#L1584)
645. 门侧纸痕区
   来源：[src/data/chapter4-755.content.json:1608](../src/data/chapter4-755.content.json#L1608)
646. 门侧纸屑压痕在三处桌脚位置连续出现。
   来源：[src/data/chapter4-755.content.json:1610](../src/data/chapter4-755.content.json#L1610)
647. 大厅
   来源：[src/data/chapter4-755.content.json:1641](../src/data/chapter4-755.content.json#L1641)
648. 西走廊
   来源：[src/data/chapter4-755.content.json:1651](../src/data/chapter4-755.content.json#L1651)
649. 东走廊
   来源：[src/data/chapter4-755.content.json:1661](../src/data/chapter4-755.content.json#L1661)
650. 教室区
   来源：[src/data/chapter4-755.content.json:1671](../src/data/chapter4-755.content.json#L1671)
651. 面包店后场
   来源：[src/data/chapter4-755.content.json:1681](../src/data/chapter4-755.content.json#L1681)
652. 旧钟重新配准
   来源：[src/data/chapter4-755.content.json:2249](../src/data/chapter4-755.content.json#L2249)
653. 12:25 → 18:50
   来源：[src/data/chapter4-755.content.json:2250](../src/data/chapter4-755.content.json#L2250)
654. 时针归位后，教学楼切换到教室仍有人活动的傍晚记录。
   来源：[src/data/chapter4-755.content.json:2251](../src/data/chapter4-755.content.json#L2251)
655. 定位盘完成校准
   来源：[src/data/chapter4-755.content.json:2267](../src/data/chapter4-755.content.json#L2267)
656. 18:50 → 22:45
   来源：[src/data/chapter4-755.content.json:2268](../src/data/chapter4-755.content.json#L2268)
657. 定位片归位后，旧钟进入清楼前的维护时段。
   来源：[src/data/chapter4-755.content.json:2269](../src/data/chapter4-755.content.json#L2269)
658. 校准发生偏移
   来源：[src/data/chapter4-755.content.json:2285](../src/data/chapter4-755.content.json#L2285)
659. 22:45 → 07:54
   来源：[src/data/chapter4-755.content.json:2286](../src/data/chapter4-755.content.json#L2286)
660. 旧钟已经转到清晨，纸条带走了最后一分钟，教学楼同时停电。
   来源：[src/data/chapter4-755.content.json:2287](../src/data/chapter4-755.content.json#L2287)
661. 最后一分钟归位
   来源：[src/data/chapter4-755.content.json:2333](../src/data/chapter4-755.content.json#L2333)
662. 07:54 → 07:55
   来源：[src/data/chapter4-755.content.json:2334](../src/data/chapter4-755.content.json#L2334)
663. 旧钟和手机重新显示同一个清晨时刻。
   来源：[src/data/chapter4-755.content.json:2335](../src/data/chapter4-755.content.json#L2335)
664. 学习天地资料索引帖
   来源：[src/data/chapter4-cc98.content.json:3](../src/data/chapter4-cc98.content.json#L3)
665. 学习天地
   来源：[src/data/chapter4-cc98.content.json:4](../src/data/chapter4-cc98.content.json#L4)
666. 课程资料整理员
   来源：[src/data/chapter4-cc98.content.json:7](../src/data/chapter4-cc98.content.json#L7)
667. 学习天地资料索引帖，课程和年份入口已补齐
   来源：[src/data/chapter4-cc98.content.json:10](../src/data/chapter4-cc98.content.json#L10)
668. 26-07-10 22:18
   来源：[src/data/chapter4-cc98.content.json:11](../src/data/chapter4-cc98.content.json#L11)
669. 把学习天地里散着的课程资料重新挂了一遍。点课程名先选年份，再看对应目录和旧自习讨论。段永平教学楼 A2 的房间情况与东西侧路线请到现场核对，CC98 只提供资料入口，麦斯威夜间自习群的即时消息仍要单独查看。
   来源：[src/data/chapter4-cc98.content.json:12](../src/data/chapter4-cc98.content.json#L12)
670. 旧自习讨论
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
671. 课程资料
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
672. 年份入口
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
673. 高数周三晚
   来源：[src/data/chapter4-cc98.content.json:18](../src/data/chapter4-cc98.content.json#L18)
674. 22:21
   来源：[src/data/chapter4-cc98.content.json:19](../src/data/chapter4-cc98.content.json#L19)
675. 2楼
   来源：[src/data/chapter4-cc98.content.json:20](../src/data/chapter4-cc98.content.json#L20)
676. 课程
   来源：[src/data/chapter4-cc98.content.json:21](../src/data/chapter4-cc98.content.json#L21)
677. 我按 2023 秋季高数点进去，先看到讲义，再看到自习室讨论。旧帖里的日期要自己看清，别把去年的开门时间当今晚用。
   来源：[src/data/chapter4-cc98.content.json:22](../src/data/chapter4-cc98.content.json#L22)
678. 打印室常客
   来源：[src/data/chapter4-cc98.content.json:26](../src/data/chapter4-cc98.content.json#L26)
679. 22:24
   来源：[src/data/chapter4-cc98.content.json:27](../src/data/chapter4-cc98.content.json#L27)
680. 3楼
   来源：[src/data/chapter4-cc98.content.json:28](../src/data/chapter4-cc98.content.json#L28)
681. 打印
   来源：[src/data/chapter4-cc98.content.json:29](../src/data/chapter4-cc98.content.json#L29)
682. 课程名搜不全时可以只输两个字。我刚从西区打印室回来，按年份找到的文件比首页推荐的少一堆，下载前先看页数。
   来源：[src/data/chapter4-cc98.content.json:30](../src/data/chapter4-cc98.content.json#L30)
683. 麦斯威靠窗位
   来源：[src/data/chapter4-cc98.content.json:34](../src/data/chapter4-cc98.content.json#L34)
684. 22:27
   来源：[src/data/chapter4-cc98.content.json:35](../src/data/chapter4-cc98.content.json#L35)
685. 4楼
   来源：[src/data/chapter4-cc98.content.json:36](../src/data/chapter4-cc98.content.json#L36)
686. 自习
   来源：[src/data/chapter4-cc98.content.json:37](../src/data/chapter4-cc98.content.json#L37)
687. 旧自习讨论里有人记过插座和座位，但每天的空位都不一样。今晚我 21:50 到麦斯威，靠窗第三张桌已经有人了。
   来源：[src/data/chapter4-cc98.content.json:38](../src/data/chapter4-cc98.content.json#L38)
688. 资料夹分层
   来源：[src/data/chapter4-cc98.content.json:42](../src/data/chapter4-cc98.content.json#L42)
689. 22:30
   来源：[src/data/chapter4-cc98.content.json:43](../src/data/chapter4-cc98.content.json#L43)
690. 5楼
   来源：[src/data/chapter4-cc98.content.json:44](../src/data/chapter4-cc98.content.json#L44)
691. 整理
   来源：[src/data/chapter4-cc98.content.json:45](../src/data/chapter4-cc98.content.json#L45)
692. 年份入口按课程分开看比较省事。我把 2022 和 2024 的资料放进两个文件夹，旧讨论单独留着，方便对照当时的说法。
   来源：[src/data/chapter4-cc98.content.json:46](../src/data/chapter4-cc98.content.json#L46)
693. A2 晚课生
   来源：[src/data/chapter4-cc98.content.json:50](../src/data/chapter4-cc98.content.json#L50)
694. 22:34
   来源：[src/data/chapter4-cc98.content.json:51](../src/data/chapter4-cc98.content.json#L51)
695. 6楼
   来源：[src/data/chapter4-cc98.content.json:52](../src/data/chapter4-cc98.content.json#L52)
696. 现场
   来源：[src/data/chapter4-cc98.content.json:53](../src/data/chapter4-cc98.content.json#L53)
697. A2 里面的房间和走廊晚上会变，帖子里的课程资料只能帮忙认入口。到楼里以后按当晚看到的门牌和通道走，别照旧帖直接抄路线。
   来源：[src/data/chapter4-cc98.content.json:54](../src/data/chapter4-cc98.content.json#L54)
698. 群里等消息
   来源：[src/data/chapter4-cc98.content.json:58](../src/data/chapter4-cc98.content.json#L58)
699. 22:38
   来源：[src/data/chapter4-cc98.content.json:59](../src/data/chapter4-cc98.content.json#L59)
700. 7楼
   来源：[src/data/chapter4-cc98.content.json:60](../src/data/chapter4-cc98.content.json#L60)
701. 提醒
   来源：[src/data/chapter4-cc98.content.json:61](../src/data/chapter4-cc98.content.json#L61)
702. 导入群里以后，课程和年份会留在群文件，现场有人发的新消息还在聊天里。去段永平教学楼核对时，两个地方都看一眼。
   来源：[src/data/chapter4-cc98.content.json:62](../src/data/chapter4-cc98.content.json#L62)
703. 导入到麦斯威夜间自习群
   来源：[src/data/chapter4-cc98.content.json:66](../src/data/chapter4-cc98.content.json#L66)
704. 把课程年份入口和旧自习讨论带进自习群
   来源：[src/data/chapter4-cc98.content.json:67](../src/data/chapter4-cc98.content.json#L67)
705. 已导入学习天地资料索引。课程和年份入口会留在群文件，段永平教学楼 A2 的房间与东西侧路线仍需到现场核验。
   来源：[src/data/chapter4-cc98.content.json:68](../src/data/chapter4-cc98.content.json#L68)
706. 这份学习天地资料索引已经导入麦斯威夜间自习群，群文件不会重复添加。现场消息仍请查看聊天记录。
   来源：[src/data/chapter4-cc98.content.json:69](../src/data/chapter4-cc98.content.json#L69)
707. 当前章节还没到段永平教学楼 A2，暂时不能导入学习天地资料。先完成前面的现场调查，再回来查看。
   来源：[src/data/chapter4-cc98.content.json:70](../src/data/chapter4-cc98.content.json#L70)
708. 完成启真湖段落并进入第四章后，学习天地资料索引才会开放。
   来源：[src/data/chapter4-cc98.content.json:71](../src/data/chapter4-cc98.content.json#L71)
709. 麦斯威夜间自习群
   来源：[src/data/chapter4-cc98.content.json:74](../src/data/chapter4-cc98.content.json#L74)；[src/data/chapter4-wechat.content.json:98](../src/data/chapter4-wechat.content.json#L98)
710. 资料索引已放进群文件。群聊继续接收今晚的现场消息，A2 房间核验与东西侧路线以现场和群聊记录为准。
   来源：[src/data/chapter4-cc98.content.json:75](../src/data/chapter4-cc98.content.json#L75)
711. CC98 的课程、年份入口和旧自习讨论只用于查资料，不能替代微信现场消息。
   来源：[src/data/chapter4-cc98.content.json:76](../src/data/chapter4-cc98.content.json#L76)
712. 打开麦斯威夜间自习群，查看刚导入的资料索引和最新现场消息。
   来源：[src/data/chapter4-cc98.content.json:77](../src/data/chapter4-cc98.content.json#L77)
713. 校时终端
   来源：[src/data/chapter4-clock.content.json:3](../src/data/chapter4-clock.content.json#L3)
714. 本机时间冻结在 07:55:23。B2-04 的签到终端只接受经三路设备共同确认的 08:00:00。
   来源：[src/data/chapter4-clock.content.json:4](../src/data/chapter4-clock.content.json#L4)
715. 档案
   来源：[src/data/chapter4-clock.content.json:6](../src/data/chapter4-clock.content.json#L6)
716. 机芯
   来源：[src/data/chapter4-clock.content.json:7](../src/data/chapter4-clock.content.json#L7)
717. 漂移
   来源：[src/data/chapter4-clock.content.json:8](../src/data/chapter4-clock.content.json#L8)
718. 放行
   来源：[src/data/chapter4-clock.content.json:9](../src/data/chapter4-clock.content.json#L9)
719. 重建签到档案
   来源：[src/data/chapter4-clock.content.json:12](../src/data/chapter4-clock.content.json#L12)
720. B2-04 异常记录
   来源：[src/data/chapter4-clock.content.json:13](../src/data/chapter4-clock.content.json#L13)
721. 先从六条混杂记录中选出互相支持的三条证据，再据此选择目标时刻。缺少证据或选错时刻都会被终端拒绝。
   来源：[src/data/chapter4-clock.content.json:14](../src/data/chapter4-clock.content.json#L14)
722. 门厅残影
   来源：[src/data/chapter4-clock.content.json:16](../src/data/chapter4-clock.content.json#L16)；[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
723. 纸条最后进入 B2-04，门牌没有发生位移。
   来源：[src/data/chapter4-clock.content.json:16](../src/data/chapter4-clock.content.json#L16)
724. 课程调整
   来源：[src/data/chapter4-clock.content.json:17](../src/data/chapter4-clock.content.json#L17)
725. 临时教室开放时间提前到 08:00。
   来源：[src/data/chapter4-clock.content.json:17](../src/data/chapter4-clock.content.json#L17)
726. 签到日志
   来源：[src/data/chapter4-clock.content.json:18](../src/data/chapter4-clock.content.json#L18)
727. B2-04 终端在整点首次接受学生签到。
   来源：[src/data/chapter4-clock.content.json:18](../src/data/chapter4-clock.content.json#L18)
728. 闭馆广播
   来源：[src/data/chapter4-clock.content.json:19](../src/data/chapter4-clock.content.json#L19)
729. 该记录来自基础图书馆，与本楼终端无关。
   来源：[src/data/chapter4-clock.content.json:19](../src/data/chapter4-clock.content.json#L19)
730. 剧场放票
   来源：[src/data/chapter4-clock.content.json:20](../src/data/chapter4-clock.content.json#L20)
731. 手机缓存中的剧场票务时间。
   来源：[src/data/chapter4-clock.content.json:20](../src/data/chapter4-clock.content.json#L20)
732. 0755 是窗口暗号，无法作为教学楼时间。
   来源：[src/data/chapter4-clock.content.json:21](../src/data/chapter4-clock.content.json#L21)
733. 食堂取餐
   来源：[src/data/chapter4-clock.content.json:21](../src/data/chapter4-clock.content.json#L21)
734. 07:55
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
735. 当前停留
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
736. 冻结
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
737. 手机异常
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
738. 08:00
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
739. 签到开放
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
740. 早间
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
741. B2-04
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)；[src/data/chapter4-clock.content.json:51](../src/data/chapter4-clock.content.json#L51)；[src/data/chapter4-clock.content.json:61](../src/data/chapter4-clock.content.json#L61)
742. 08:32
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
743. 剧场
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
744. 票务缓存
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
745. 外部记录
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
746. 22:45
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
747. 闭楼
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
748. 进入时刻
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
749. 锁定双机芯
   来源：[src/data/chapter4-clock.content.json:31](../src/data/chapter4-clock.content.json#L31)
750. 小时轮与分钟轮拥有独立锁扣。先把对应数字调到目标值，再分别锁定；已经锁定的机芯不能继续旋转。
   来源：[src/data/chapter4-clock.content.json:32](../src/data/chapter4-clock.content.json#L32)
751. 小时机芯
   来源：[src/data/chapter4-clock.content.json:34](../src/data/chapter4-clock.content.json#L34)
752. 分钟机芯
   来源：[src/data/chapter4-clock.content.json:35](../src/data/chapter4-clock.content.json#L35)
753. 锁定机芯
   来源：[src/data/chapter4-clock.content.json:36](../src/data/chapter4-clock.content.json#L36)
754. 已锁定
   来源：[src/data/chapter4-clock.content.json:37](../src/data/chapter4-clock.content.json#L37)
755. 爆炸视图
   来源：[src/data/chapter4-clock.content.json:38](../src/data/chapter4-clock.content.json#L38)
756. 装配视图
   来源：[src/data/chapter4-clock.content.json:39](../src/data/chapter4-clock.content.json#L39)
757. 复位视角
   来源：[src/data/chapter4-clock.content.json:40](../src/data/chapter4-clock.content.json#L40)
758. 上下拖动机芯齿轮、滚轮或点按 ± 调节读数,对准 08:00 后锁定对应机芯。
   来源：[src/data/chapter4-clock.content.json:41](../src/data/chapter4-clock.content.json#L41)
759. 目标 08:00
   来源：[src/data/chapter4-clock.content.json:42](../src/data/chapter4-clock.content.json#L42)
760. 消除三路设备漂移
   来源：[src/data/chapter4-clock.content.json:46](../src/data/chapter4-clock.content.json#L46)
761. 校门、电梯和教室终端记录了不同方向的秒差。逐条选择反向修正值，三路归零后才能形成 08:00:00。
   来源：[src/data/chapter4-clock.content.json:47](../src/data/chapter4-clock.content.json#L47)
762. 校门闸机
   来源：[src/data/chapter4-clock.content.json:49](../src/data/chapter4-clock.content.json#L49)
763. 通过三种放行协议
   来源：[src/data/chapter4-clock.content.json:56](../src/data/chapter4-clock.content.json#L56)
764. 三轮拥有不同速度与有效窗口：校门宽窗、主梯窄窗、教室反向扫描。每轮只需命中一次，失败会回到第一轮。
   来源：[src/data/chapter4-clock.content.json:57](../src/data/chapter4-clock.content.json#L57)
765. 宽窗 / 常速
   来源：[src/data/chapter4-clock.content.json:59](../src/data/chapter4-clock.content.json#L59)
766. 校门
   来源：[src/data/chapter4-clock.content.json:59](../src/data/chapter4-clock.content.json#L59)
767. 窄窗 / 加速
   来源：[src/data/chapter4-clock.content.json:60](../src/data/chapter4-clock.content.json#L60)
768. 主梯
   来源：[src/data/chapter4-clock.content.json:60](../src/data/chapter4-clock.content.json#L60)
769. 偏置窗 / 反扫
   来源：[src/data/chapter4-clock.content.json:61](../src/data/chapter4-clock.content.json#L61)
770. 07:55 冻结已解除
   来源：[src/data/chapter4-clock.content.json:65](../src/data/chapter4-clock.content.json#L65)
771. 三路设备同时写入 08:00:00，B2-04 签到终端恢复。
   来源：[src/data/chapter4-clock.content.json:66](../src/data/chapter4-clock.content.json#L66)
772. 校时权限尚未开放
   来源：[src/data/chapter4-clock.content.json:69](../src/data/chapter4-clock.content.json#L69)
773. 先完成教学楼内的十二个时间节点，再回到手机处理 B2-04。
   来源：[src/data/chapter4-clock.content.json:70](../src/data/chapter4-clock.content.json#L70)
774. 档案证据不足，或所选时刻与三条有效记录不一致。
   来源：[src/data/chapter4-clock.content.json:73](../src/data/chapter4-clock.content.json#L73)
775. 当前机芯或漂移修正仍未满足这一关的条件。
   来源：[src/data/chapter4-clock.content.json:74](../src/data/chapter4-clock.content.json#L74)
776. 本轮放行失败，协议进度已回到校门。
   来源：[src/data/chapter4-clock.content.json:75](../src/data/chapter4-clock.content.json#L75)
777. 该操作当前不可用，检查本关已经锁定的部分。
   来源：[src/data/chapter4-clock.content.json:76](../src/data/chapter4-clock.content.json#L76)
778. 校时已经完成。
   来源：[src/data/chapter4-clock.content.json:77](../src/data/chapter4-clock.content.json#L77)
779. 三条档案证据成立，08:00 已设为校准目标。
   来源：[src/data/chapter4-clock.content.json:78](../src/data/chapter4-clock.content.json#L78)
780. 双机芯锁定，开始核对三路设备漂移。
   来源：[src/data/chapter4-clock.content.json:79](../src/data/chapter4-clock.content.json#L79)
781. 三路漂移全部归零，进入最终放行。
   来源：[src/data/chapter4-clock.content.json:80](../src/data/chapter4-clock.content.json#L80)
782. 三种协议均已通过，冻结解除。
   来源：[src/data/chapter4-clock.content.json:81](../src/data/chapter4-clock.content.json#L81)
783. 系统：三路设备已归零。等待三种协议放行。
   来源：[src/data/chapter4-clock.content.json:83](../src/data/chapter4-clock.content.json#L83)
784. 玩家：三路记录同时变成了 08:00。
   来源：[src/data/chapter4-clock.content.json:85](../src/data/chapter4-clock.content.json#L85)
785. 系统：校时确认。B2-04 签到终端恢复。
   来源：[src/data/chapter4-clock.content.json:86](../src/data/chapter4-clock.content.json#L86)
786. 玩家：07:55 的冻结解除了。
   来源：[src/data/chapter4-clock.content.json:87](../src/data/chapter4-clock.content.json#L87)
787. 系统：校时完成。07:55 的冻结已解除。
   来源：[src/data/chapter4-clock.content.json:89](../src/data/chapter4-clock.content.json#L89)
788. 完成四关校时
   来源：[src/data/chapter4-clock.content.json:91](../src/data/chapter4-clock.content.json#L91)
789. 筛选三条有效档案，再选择对应时刻。
   来源：[src/data/chapter4-clock.content.json:93](../src/data/chapter4-clock.content.json#L93)
790. 分别校准并锁定小时、分钟两组机芯。
   来源：[src/data/chapter4-clock.content.json:94](../src/data/chapter4-clock.content.json#L94)
791. 为校门、电梯和 B2-04 选择反向漂移修正。
   来源：[src/data/chapter4-clock.content.json:95](../src/data/chapter4-clock.content.json#L95)
792. 依次通过三种速度与窗口不同的放行协议。
   来源：[src/data/chapter4-clock.content.json:96](../src/data/chapter4-clock.content.json#L96)
793. 校时已完成。
   来源：[src/data/chapter4-clock.content.json:97](../src/data/chapter4-clock.content.json#L97)
794. 又断了。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:35](../src/data/chapter4-prologue-voice.audio.content.json#L35)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:69](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L69)
795. It broke again.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:36](../src/data/chapter4-prologue-voice.audio.content.json#L36)
796. 湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:49](../src/data/chapter4-prologue-voice.audio.content.json#L49)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:77](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L77)
797. The lake did not keep it. The night wind carried it into the teaching building that was still lit.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:50](../src/data/chapter4-prologue-voice.audio.content.json#L50)
798. 小心，刚拖过。那张纸往里去了。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:63](../src/data/chapter4-prologue-voice.audio.content.json#L63)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:85](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L85)
799. Careful, I just mopped. That paper went inside.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:64](../src/data/chapter4-prologue-voice.audio.content.json#L64)
800. 同学，北教要清楼了，请收好东西。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:79](../src/data/chapter4-prologue-voice.audio.content.json#L79)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:93](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L93)
801. The North Teaching Building is closing. Please pack up.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:80](../src/data/chapter4-prologue-voice.audio.content.json#L80)
802. 段永平教学楼时间迷宫
   来源：[src/data/chapter4-temporal-maze.content.json:3](../src/data/chapter4-temporal-maze.content.json#L3)
803. 进入一楼门厅，确认湿纸留下的气流轨迹
   来源：[src/data/chapter4-temporal-maze.content.json:5](../src/data/chapter4-temporal-maze.content.json#L5)；[src/data/chapter4-temporal-maze.content.json:120](../src/data/chapter4-temporal-maze.content.json#L120)
804. 深色观察可查看门厅中央的断续水迹。
   来源：[src/data/chapter4-temporal-maze.content.json:6](../src/data/chapter4-temporal-maze.content.json#L6)
805. 恢复纸条进入主电梯厅的风路
   来源：[src/data/chapter4-temporal-maze.content.json:9](../src/data/chapter4-temporal-maze.content.json#L9)；[src/data/chapter4-temporal-maze.content.json:121](../src/data/chapter4-temporal-maze.content.json#L121)
806. 深色观察：地面水迹从玻璃门延伸到迈斯威卷帘门。
   来源：[src/data/chapter4-temporal-maze.content.json:10](../src/data/chapter4-temporal-maze.content.json#L10)
807. 浅色操作：到迈斯威卷帘门前，借助暖风把纸条送向主电梯。
   来源：[src/data/chapter4-temporal-maze.content.json:11](../src/data/chapter4-temporal-maze.content.json#L11)
808. 已记录气流轨迹。浅色操作可在迈斯威卷帘门前恢复风路。
   来源：[src/data/chapter4-temporal-maze.content.json:12](../src/data/chapter4-temporal-maze.content.json#L12)
809. 暖风重新接上水迹，湿纸进入主电梯厅。
   来源：[src/data/chapter4-temporal-maze.content.json:13](../src/data/chapter4-temporal-maze.content.json#L13)
810. 在主电梯厅同步纸条留下的历史轨道
   来源：[src/data/chapter4-temporal-maze.content.json:16](../src/data/chapter4-temporal-maze.content.json#L16)；[src/data/chapter4-temporal-maze.content.json:122](../src/data/chapter4-temporal-maze.content.json#L122)
811. 深色观察：读取轿厢、门体与玩家进入窗口三条历史轨道。
   来源：[src/data/chapter4-temporal-maze.content.json:17](../src/data/chapter4-temporal-maze.content.json#L17)
812. 浅色操作：拖动轿厢轨道，让一楼开门区间完整覆盖六秒进入窗口。
   来源：[src/data/chapter4-temporal-maze.content.json:18](../src/data/chapter4-temporal-maze.content.json#L18)
813. 当前校准动作需要浅色操作；深色观察可独立读取三条历史轨道。
   来源：[src/data/chapter4-temporal-maze.content.json:19](../src/data/chapter4-temporal-maze.content.json#L19)
814. 三轨已经对齐。电梯返回一楼，等待门体完全打开。
   来源：[src/data/chapter4-temporal-maze.content.json:20](../src/data/chapter4-temporal-maze.content.json#L20)
815. 开门区间没有完整覆盖进入窗口。调整重放起点后再试。
   来源：[src/data/chapter4-temporal-maze.content.json:21](../src/data/chapter4-temporal-maze.content.json#L21)
816. 开门窗口已经结束。再次启动历史重放。
   来源：[src/data/chapter4-temporal-maze.content.json:22](../src/data/chapter4-temporal-maze.content.json#L22)
817. 历史片段继续运行，已到达 A2。
   来源：[src/data/chapter4-temporal-maze.content.json:23](../src/data/chapter4-temporal-maze.content.json#L23)
818. 深色观察：记录同一时间片内经过门口和停留区的人员残影。
   来源：[src/data/chapter4-temporal-maze.content.json:51](../src/data/chapter4-temporal-maze.content.json#L51)
819. 三组人员时刻已记录。浅色操作可处理可见隔断。
   来源：[src/data/chapter4-temporal-maze.content.json:52](../src/data/chapter4-temporal-maze.content.json#L52)
820. 浅色操作：依照已记录的空档逐一移动两组可见隔断。
   来源：[src/data/chapter4-temporal-maze.content.json:56](../src/data/chapter4-temporal-maze.content.json#L56)
821. 人员时刻证据尚未完整；两种现实模式的交互入口都保持开放。
   来源：[src/data/chapter4-temporal-maze.content.json:57](../src/data/chapter4-temporal-maze.content.json#L57)
822. 内圈支路已接通，开放学习区现在可达。
   来源：[src/data/chapter4-temporal-maze.content.json:58](../src/data/chapter4-temporal-maze.content.json#L58)
823. 在开放学习区取得两块导视碎片。
   来源：[src/data/chapter4-temporal-maze.content.json:66](../src/data/chapter4-temporal-maze.content.json#L66)
824. 深色观察：读取旧导视残影。
   来源：[src/data/chapter4-temporal-maze.content.json:67](../src/data/chapter4-temporal-maze.content.json#L67)
825. 旧导视残影已记录。浅色操作可重建导视板。
   来源：[src/data/chapter4-temporal-maze.content.json:68](../src/data/chapter4-temporal-maze.content.json#L68)
826. 浅色操作：比较当前导视照片、旧残影与二楼入口方向，自行判断缺失槽位和两块碎片的位置。
   来源：[src/data/chapter4-temporal-maze.content.json:69](../src/data/chapter4-temporal-maze.content.json#L69)
827. 碎片与当前历史记录不一致，重新检查已记录的导视痕迹。
   来源：[src/data/chapter4-temporal-maze.content.json:70](../src/data/chapter4-temporal-maze.content.json#L70)
828. 导视板恢复了一段可验证记录。返回已访问楼层继续取证。
   来源：[src/data/chapter4-temporal-maze.content.json:71](../src/data/chapter4-temporal-maze.content.json#L71)
829. 导视板恢复后，切到深色观察并读取入口开合与人员经过留下的历史痕迹。
   来源：[src/data/chapter4-temporal-maze.content.json:75](../src/data/chapter4-temporal-maze.content.json#L75)
830. 连廊历史已记录，可与导视碎片交叉核对。
   来源：[src/data/chapter4-temporal-maze.content.json:76](../src/data/chapter4-temporal-maze.content.json#L76)
831. 回到已访问区域，检查新出现的取证窗口。
   来源：[src/data/chapter4-temporal-maze.content.json:82](../src/data/chapter4-temporal-maze.content.json#L82)
832. 当前历史窗口尚未形成，继续核对已有证据。
   来源：[src/data/chapter4-temporal-maze.content.json:83](../src/data/chapter4-temporal-maze.content.json#L83)
833. 新的取证窗口已经开放，当前安全位置已保存。
   来源：[src/data/chapter4-temporal-maze.content.json:84](../src/data/chapter4-temporal-maze.content.json#L84)
834. 当前交通核心不能到达该楼层。
   来源：[src/data/chapter4-temporal-maze.content.json:87](../src/data/chapter4-temporal-maze.content.json#L87)
835. 仍缺当前步骤所需的证据。
   来源：[src/data/chapter4-temporal-maze.content.json:88](../src/data/chapter4-temporal-maze.content.json#L88)
836. 切换现实模式后再执行当前动作。
   来源：[src/data/chapter4-temporal-maze.content.json:89](../src/data/chapter4-temporal-maze.content.json#L89)
837. 当前路线条件尚未满足。
   来源：[src/data/chapter4-temporal-maze.content.json:90](../src/data/chapter4-temporal-maze.content.json#L90)
838. 四项外部记录
   来源：[src/data/chapter4-temporal-maze.content.json:99](../src/data/chapter4-temporal-maze.content.json#L99)
839. 大厅旧钟
   来源：[src/data/chapter4-temporal-maze.content.json:100](../src/data/chapter4-temporal-maze.content.json#L100)
840. 手机已同步
   来源：[src/data/chapter4-temporal-maze.content.json:103](../src/data/chapter4-temporal-maze.content.json#L103)
841. 手机未同步，当前读数不可信
   来源：[src/data/chapter4-temporal-maze.content.json:104](../src/data/chapter4-temporal-maze.content.json#L104)
842. 完成启真湖逃脱并进入教学楼
   来源：[src/data/chapter4-temporal-maze.content.json:119](../src/data/chapter4-temporal-maze.content.json#L119)
843. 根据夜间人员动线重建纸条路线
   来源：[src/data/chapter4-temporal-maze.content.json:123](../src/data/chapter4-temporal-maze.content.json#L123)
844. 重建二楼走廊等待区
   来源：[src/data/chapter4-temporal-maze.content.json:124](../src/data/chapter4-temporal-maze.content.json#L124)
845. 拼合楼层导视碎片
   来源：[src/data/chapter4-temporal-maze.content.json:125](../src/data/chapter4-temporal-maze.content.json#L125)
846. 确认连廊只位于三楼
   来源：[src/data/chapter4-temporal-maze.content.json:126](../src/data/chapter4-temporal-maze.content.json#L126)
847. 记录下层回声，旋转折返楼梯并接通 B2
   来源：[src/data/chapter4-temporal-maze.content.json:127](../src/data/chapter4-temporal-maze.content.json#L127)
848. 剪合多机位监控记录
   来源：[src/data/chapter4-temporal-maze.content.json:128](../src/data/chapter4-temporal-maze.content.json#L128)
849. 录制可在复位后重放的动作回声
   来源：[src/data/chapter4-temporal-maze.content.json:129](../src/data/chapter4-temporal-maze.content.json#L129)
850. 用两部电梯运输大型签到板
   来源：[src/data/chapter4-temporal-maze.content.json:130](../src/data/chapter4-temporal-maze.content.json#L130)
851. 在迈斯威暖风中控制纸条含水量
   来源：[src/data/chapter4-temporal-maze.content.json:131](../src/data/chapter4-temporal-maze.content.json#L131)
852. 从 23:30 复位点恢复第二循环
   来源：[src/data/chapter4-temporal-maze.content.json:132](../src/data/chapter4-temporal-maze.content.json#L132)
853. 安排第二循环的逆向运输路线
   来源：[src/data/chapter4-temporal-maze.content.json:133](../src/data/chapter4-temporal-maze.content.json#L133)
854. 校准 07:55 相位并打开 B2-04
   来源：[src/data/chapter4-temporal-maze.content.json:134](../src/data/chapter4-temporal-maze.content.json#L134)
855. 读取异常签到记录
   来源：[src/data/chapter4-temporal-maze.content.json:135](../src/data/chapter4-temporal-maze.content.json#L135)
856. 空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:1920](../src/data/chapter4-three-floor-maze.layout.json#L1920)；[src/data/chapter4-three-floor-maze.layout.json:1929](../src/data/chapter4-three-floor-maze.layout.json#L1929)；[src/data/chapter4-three-floor-maze.layout.json:1938](../src/data/chapter4-three-floor-maze.layout.json#L1938)；[src/data/chapter4-three-floor-maze.layout.json:1947](../src/data/chapter4-three-floor-maze.layout.json#L1947)；[src/data/chapter4-three-floor-maze.layout.json:1956](../src/data/chapter4-three-floor-maze.layout.json#L1956)；[src/data/chapter4-three-floor-maze.layout.json:1965](../src/data/chapter4-three-floor-maze.layout.json#L1965)；[src/data/chapter4-three-floor-maze.layout.json:1974](../src/data/chapter4-three-floor-maze.layout.json#L1974)；[src/data/chapter4-three-floor-maze.layout.json:1983](../src/data/chapter4-three-floor-maze.layout.json#L1983)；[src/data/chapter4-three-floor-maze.layout.json:1992](../src/data/chapter4-three-floor-maze.layout.json#L1992)；[src/data/chapter4-three-floor-maze.layout.json:2001](../src/data/chapter4-three-floor-maze.layout.json#L2001)；[src/data/chapter4-three-floor-maze.layout.json:2010](../src/data/chapter4-three-floor-maze.layout.json#L2010)；[src/data/chapter4-three-floor-maze.layout.json:2477](../src/data/chapter4-three-floor-maze.layout.json#L2477)；[src/data/chapter4-three-floor-maze.layout.json:2486](../src/data/chapter4-three-floor-maze.layout.json#L2486)；[src/data/chapter4-three-floor-maze.layout.json:2495](../src/data/chapter4-three-floor-maze.layout.json#L2495)；[src/data/chapter4-three-floor-maze.layout.json:2510](../src/data/chapter4-three-floor-maze.layout.json#L2510)；[src/data/chapter4-three-floor-maze.layout.json:2519](../src/data/chapter4-three-floor-maze.layout.json#L2519)；[src/data/chapter4-three-floor-maze.layout.json:2528](../src/data/chapter4-three-floor-maze.layout.json#L2528)；[src/data/chapter4-three-floor-maze.layout.json:2537](../src/data/chapter4-three-floor-maze.layout.json#L2537)；[src/data/chapter4-three-floor-maze.layout.json:2546](../src/data/chapter4-three-floor-maze.layout.json#L2546)；[src/data/chapter4-three-floor-maze.layout.json:2555](../src/data/chapter4-three-floor-maze.layout.json#L2555)；[src/data/chapter4-three-floor-maze.layout.json:2570](../src/data/chapter4-three-floor-maze.layout.json#L2570)；[src/data/chapter4-three-floor-maze.layout.json:2579](../src/data/chapter4-three-floor-maze.layout.json#L2579)；[src/data/chapter4-three-floor-maze.layout.json:2588](../src/data/chapter4-three-floor-maze.layout.json#L2588)；[src/data/chapter4-three-floor-maze.layout.json:2603](../src/data/chapter4-three-floor-maze.layout.json#L2603)；[src/data/chapter4-three-floor-maze.layout.json:2618](../src/data/chapter4-three-floor-maze.layout.json#L2618)；[src/data/chapter4-three-floor-maze.layout.json:2627](../src/data/chapter4-three-floor-maze.layout.json#L2627)；[src/data/chapter4-three-floor-maze.layout.json:2636](../src/data/chapter4-three-floor-maze.layout.json#L2636)；[src/data/chapter4-three-floor-maze.layout.json:2645](../src/data/chapter4-three-floor-maze.layout.json#L2645)；[src/data/chapter4-three-floor-maze.layout.json:2654](../src/data/chapter4-three-floor-maze.layout.json#L2654)；[src/data/chapter4-three-floor-maze.layout.json:2663](../src/data/chapter4-three-floor-maze.layout.json#L2663)；[src/data/chapter4-three-floor-maze.layout.json:2672](../src/data/chapter4-three-floor-maze.layout.json#L2672)；[src/data/chapter4-three-floor-maze.layout.json:2681](../src/data/chapter4-three-floor-maze.layout.json#L2681)；[src/data/chapter4-three-floor-maze.layout.json:2690](../src/data/chapter4-three-floor-maze.layout.json#L2690)；[src/data/chapter4-three-floor-maze.layout.json:2699](../src/data/chapter4-three-floor-maze.layout.json#L2699)；[src/data/chapter4-three-floor-maze.layout.json:3077](../src/data/chapter4-three-floor-maze.layout.json#L3077)；[src/data/chapter4-three-floor-maze.layout.json:3086](../src/data/chapter4-three-floor-maze.layout.json#L3086)；[src/data/chapter4-three-floor-maze.layout.json:3095](../src/data/chapter4-three-floor-maze.layout.json#L3095)；[src/data/chapter4-three-floor-maze.layout.json:3113](../src/data/chapter4-three-floor-maze.layout.json#L3113)；[src/data/chapter4-three-floor-maze.layout.json:3122](../src/data/chapter4-three-floor-maze.layout.json#L3122)；[src/data/chapter4-three-floor-maze.layout.json:3131](../src/data/chapter4-three-floor-maze.layout.json#L3131)；[src/data/chapter4-three-floor-maze.layout.json:3140](../src/data/chapter4-three-floor-maze.layout.json#L3140)；[src/data/chapter4-three-floor-maze.layout.json:3149](../src/data/chapter4-three-floor-maze.layout.json#L3149)；[src/data/chapter4-three-floor-maze.layout.json:3158](../src/data/chapter4-three-floor-maze.layout.json#L3158)；[src/data/chapter4-three-floor-maze.layout.json:3167](../src/data/chapter4-three-floor-maze.layout.json#L3167)；[src/data/chapter4-three-floor-maze.layout.json:3176](../src/data/chapter4-three-floor-maze.layout.json#L3176)；[src/data/chapter4-three-floor-maze.layout.json:3185](../src/data/chapter4-three-floor-maze.layout.json#L3185)；[src/data/chapter4-three-floor-maze.layout.json:3200](../src/data/chapter4-three-floor-maze.layout.json#L3200)
857. 北侧西段肖像墙下沿空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2019](../src/data/chapter4-three-floor-maze.layout.json#L2019)
858. 北侧东段肖像墙下沿空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2028](../src/data/chapter4-three-floor-maze.layout.json#L2028)
859. 前台柜台空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2037](../src/data/chapter4-three-floor-maze.layout.json#L2037)
860. 面包坊柜台空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2046](../src/data/chapter4-three-floor-maze.layout.json#L2046)
861. 面包坊门洞
   来源：[src/data/chapter4-three-floor-maze.layout.json:2057](../src/data/chapter4-three-floor-maze.layout.json#L2057)
862. 必须可通行
   来源：[src/data/chapter4-three-floor-maze.layout.json:2067](../src/data/chapter4-three-floor-maze.layout.json#L2067)；[src/data/chapter4-three-floor-maze.layout.json:2077](../src/data/chapter4-three-floor-maze.layout.json#L2077)；[src/data/chapter4-three-floor-maze.layout.json:2087](../src/data/chapter4-three-floor-maze.layout.json#L2087)；[src/data/chapter4-three-floor-maze.layout.json:2097](../src/data/chapter4-three-floor-maze.layout.json#L2097)；[src/data/chapter4-three-floor-maze.layout.json:2107](../src/data/chapter4-three-floor-maze.layout.json#L2107)；[src/data/chapter4-three-floor-maze.layout.json:2117](../src/data/chapter4-three-floor-maze.layout.json#L2117)；[src/data/chapter4-three-floor-maze.layout.json:2710](../src/data/chapter4-three-floor-maze.layout.json#L2710)；[src/data/chapter4-three-floor-maze.layout.json:2720](../src/data/chapter4-three-floor-maze.layout.json#L2720)；[src/data/chapter4-three-floor-maze.layout.json:2730](../src/data/chapter4-three-floor-maze.layout.json#L2730)；[src/data/chapter4-three-floor-maze.layout.json:2740](../src/data/chapter4-three-floor-maze.layout.json#L2740)；[src/data/chapter4-three-floor-maze.layout.json:2750](../src/data/chapter4-three-floor-maze.layout.json#L2750)；[src/data/chapter4-three-floor-maze.layout.json:3316](../src/data/chapter4-three-floor-maze.layout.json#L3316)；[src/data/chapter4-three-floor-maze.layout.json:3326](../src/data/chapter4-three-floor-maze.layout.json#L3326)；[src/data/chapter4-three-floor-maze.layout.json:3336](../src/data/chapter4-three-floor-maze.layout.json#L3336)；[src/data/chapter4-three-floor-maze.layout.json:3346](../src/data/chapter4-three-floor-maze.layout.json#L3346)；[src/data/chapter4-three-floor-maze.layout.json:3356](../src/data/chapter4-three-floor-maze.layout.json#L3356)；[src/data/chapter4-three-floor-maze.layout.json:3366](../src/data/chapter4-three-floor-maze.layout.json#L3366)
863. 前景遮挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2129](../src/data/chapter4-three-floor-maze.layout.json#L2129)；[src/data/chapter4-three-floor-maze.layout.json:2142](../src/data/chapter4-three-floor-maze.layout.json#L2142)；[src/data/chapter4-three-floor-maze.layout.json:2155](../src/data/chapter4-three-floor-maze.layout.json#L2155)；[src/data/chapter4-three-floor-maze.layout.json:2168](../src/data/chapter4-three-floor-maze.layout.json#L2168)；[src/data/chapter4-three-floor-maze.layout.json:2181](../src/data/chapter4-three-floor-maze.layout.json#L2181)；[src/data/chapter4-three-floor-maze.layout.json:2194](../src/data/chapter4-three-floor-maze.layout.json#L2194)；[src/data/chapter4-three-floor-maze.layout.json:2207](../src/data/chapter4-three-floor-maze.layout.json#L2207)；[src/data/chapter4-three-floor-maze.layout.json:2762](../src/data/chapter4-three-floor-maze.layout.json#L2762)；[src/data/chapter4-three-floor-maze.layout.json:2775](../src/data/chapter4-three-floor-maze.layout.json#L2775)；[src/data/chapter4-three-floor-maze.layout.json:2788](../src/data/chapter4-three-floor-maze.layout.json#L2788)；[src/data/chapter4-three-floor-maze.layout.json:2801](../src/data/chapter4-three-floor-maze.layout.json#L2801)；[src/data/chapter4-three-floor-maze.layout.json:2814](../src/data/chapter4-three-floor-maze.layout.json#L2814)；[src/data/chapter4-three-floor-maze.layout.json:2827](../src/data/chapter4-three-floor-maze.layout.json#L2827)；[src/data/chapter4-three-floor-maze.layout.json:3378](../src/data/chapter4-three-floor-maze.layout.json#L3378)；[src/data/chapter4-three-floor-maze.layout.json:3391](../src/data/chapter4-three-floor-maze.layout.json#L3391)
864. 北侧西段肖像墙前景
   来源：[src/data/chapter4-three-floor-maze.layout.json:2220](../src/data/chapter4-three-floor-maze.layout.json#L2220)
865. 北侧东段肖像墙前景
   来源：[src/data/chapter4-three-floor-maze.layout.json:2234](../src/data/chapter4-three-floor-maze.layout.json#L2234)
866. 麦思威面包坊餐厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2249](../src/data/chapter4-three-floor-maze.layout.json#L2249)
867. 一楼校友头像长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:2259](../src/data/chapter4-three-floor-maze.layout.json#L2259)
868. 104 教室门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2269](../src/data/chapter4-three-floor-maze.layout.json#L2269)
869. 105 教室门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2279](../src/data/chapter4-three-floor-maze.layout.json#L2279)
870. 104 黑板擦痕残留
   来源：[src/data/chapter4-three-floor-maze.layout.json:2289](../src/data/chapter4-three-floor-maze.layout.json#L2289)
871. 105 讲台回放终端
   来源：[src/data/chapter4-three-floor-maze.layout.json:2299](../src/data/chapter4-three-floor-maze.layout.json#L2299)
872. 一楼前台值班助理
   来源：[src/data/chapter4-three-floor-maze.layout.json:2309](../src/data/chapter4-three-floor-maze.layout.json#L2309)
873. 一楼前台值班签到板
   来源：[src/data/chapter4-three-floor-maze.layout.json:2319](../src/data/chapter4-three-floor-maze.layout.json#L2319)
874. 教学楼主入口
   来源：[src/data/chapter4-three-floor-maze.layout.json:2329](../src/data/chapter4-three-floor-maze.layout.json#L2329)
875. 公告栏前的签到记录纸条
   来源：[src/data/chapter4-three-floor-maze.layout.json:2339](../src/data/chapter4-three-floor-maze.layout.json#L2339)
876. 一楼旧钟
   来源：[src/data/chapter4-three-floor-maze.layout.json:2349](../src/data/chapter4-three-floor-maze.layout.json#L2349)
877. 旧钟时针插槽
   来源：[src/data/chapter4-three-floor-maze.layout.json:2359](../src/data/chapter4-three-floor-maze.layout.json#L2359)；[src/scenes/rpg/RpgInteractionContract.ts:605](../src/scenes/rpg/RpgInteractionContract.ts#L605)
878. 旧钟定位盘插槽
   来源：[src/data/chapter4-three-floor-maze.layout.json:2369](../src/data/chapter4-three-floor-maze.layout.json#L2369)
879. 旧钟齿轮
   来源：[src/data/chapter4-three-floor-maze.layout.json:2379](../src/data/chapter4-three-floor-maze.layout.json#L2379)；[src/scenes/rpg/RpgInteractionContract.ts:878](../src/scenes/rpg/RpgInteractionContract.ts#L878)
880. 旧钟分针端点
   来源：[src/data/chapter4-three-floor-maze.layout.json:2389](../src/data/chapter4-three-floor-maze.layout.json#L2389)；[src/scenes/rpg/RpgInteractionContract.ts:889](../src/scenes/rpg/RpgInteractionContract.ts#L889)；[src/scenes/rpg/RpgItemUseGuidance.ts:85](../src/scenes/rpg/RpgItemUseGuidance.ts#L85)
881. 一楼配电面板
   来源：[src/data/chapter4-three-floor-maze.layout.json:2399](../src/data/chapter4-three-floor-maze.layout.json#L2399)；[src/scenes/rpg/RpgInteractionContract.ts:913](../src/scenes/rpg/RpgInteractionContract.ts#L913)
882. 201 创客工坊
   来源：[src/data/chapter4-three-floor-maze.layout.json:2841](../src/data/chapter4-three-floor-maze.layout.json#L2841)
883. 201 定位板校准夹具
   来源：[src/data/chapter4-three-floor-maze.layout.json:2851](../src/data/chapter4-three-floor-maze.layout.json#L2851)
884. 204 研讨教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:2861](../src/data/chapter4-three-floor-maze.layout.json#L2861)
885. 202 阶梯教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:2871](../src/data/chapter4-three-floor-maze.layout.json#L2871)
886. 203 计算机教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:2881](../src/data/chapter4-three-floor-maze.layout.json#L2881)
887. 203 五区拓扑终端
   来源：[src/data/chapter4-three-floor-maze.layout.json:2891](../src/data/chapter4-three-floor-maze.layout.json#L2891)
888. 二楼开放学习区
   来源：[src/data/chapter4-three-floor-maze.layout.json:2901](../src/data/chapter4-three-floor-maze.layout.json#L2901)
889. 开放自习区疏散路线板
   来源：[src/data/chapter4-three-floor-maze.layout.json:2911](../src/data/chapter4-three-floor-maze.layout.json#L2911)
890. 二楼校友纪念长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:2921](../src/data/chapter4-three-floor-maze.layout.json#L2921)
891. 二楼电梯口值班安全员
   来源：[src/data/chapter4-three-floor-maze.layout.json:2931](../src/data/chapter4-three-floor-maze.layout.json#L2931)
892. 204 教室残影组
   来源：[src/data/chapter4-three-floor-maze.layout.json:2941](../src/data/chapter4-three-floor-maze.layout.json#L2941)
893. 204 讲台抽屉里的定位盘
   来源：[src/data/chapter4-three-floor-maze.layout.json:2951](../src/data/chapter4-three-floor-maze.layout.json#L2951)
894. 202 阶梯教室门槛
   来源：[src/data/chapter4-three-floor-maze.layout.json:2961](../src/data/chapter4-three-floor-maze.layout.json#L2961)；[src/scenes/rpg/RpgInteractionContract.ts:928](../src/scenes/rpg/RpgInteractionContract.ts#L928)
895. 202 投影中的最后一分钟
   来源：[src/data/chapter4-three-floor-maze.layout.json:2971](../src/data/chapter4-three-floor-maze.layout.json#L2971)；[src/scenes/rpg/RpgInteractionContract.ts:940](../src/scenes/rpg/RpgInteractionContract.ts#L940)
896. 301 档案展北墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3068](../src/data/chapter4-three-floor-maze.layout.json#L3068)
897. 302 媒体工作室西墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3104](../src/data/chapter4-three-floor-maze.layout.json#L3104)
898. 校友荣誉门厅南墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3215](../src/data/chapter4-three-floor-maze.layout.json#L3215)
899. 304 报告厅北墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3224](../src/data/chapter4-three-floor-maze.layout.json#L3224)
900. 304 报告厅西墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3233](../src/data/chapter4-three-floor-maze.layout.json#L3233)
901. 304 报告厅南墙西段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3242](../src/data/chapter4-three-floor-maze.layout.json#L3242)
902. 304 报告厅南墙东段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3251](../src/data/chapter4-three-floor-maze.layout.json#L3251)
903. 304 报告厅东墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3260](../src/data/chapter4-three-floor-maze.layout.json#L3260)
904. 303 智慧教室北墙西段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3269](../src/data/chapter4-three-floor-maze.layout.json#L3269)
905. 303 智慧教室北墙东段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3278](../src/data/chapter4-three-floor-maze.layout.json#L3278)
906. 303 智慧教室西墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3287](../src/data/chapter4-three-floor-maze.layout.json#L3287)
907. 303 智慧教室东墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3296](../src/data/chapter4-three-floor-maze.layout.json#L3296)
908. A3 建筑南侧外墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3305](../src/data/chapter4-three-floor-maze.layout.json#L3305)
909. 301 校史档案展
   来源：[src/data/chapter4-three-floor-maze.layout.json:3405](../src/data/chapter4-three-floor-maze.layout.json#L3405)
910. 301 胶片索引抽屉
   来源：[src/data/chapter4-three-floor-maze.layout.json:3415](../src/data/chapter4-three-floor-maze.layout.json#L3415)
911. 302 媒体工作室
   来源：[src/data/chapter4-three-floor-maze.layout.json:3425](../src/data/chapter4-three-floor-maze.layout.json#L3425)
912. 302 新旧影像对齐扫描台
   来源：[src/data/chapter4-three-floor-maze.layout.json:3435](../src/data/chapter4-three-floor-maze.layout.json#L3435)
913. 304 报告厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:3445](../src/data/chapter4-three-floor-maze.layout.json#L3445)
914. 303 智慧教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:3455](../src/data/chapter4-three-floor-maze.layout.json#L3455)
915. 三楼校史人物荣誉门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:3465](../src/data/chapter4-three-floor-maze.layout.json#L3465)
916. 校史人物·苏步青
   来源：[src/data/chapter4-three-floor-maze.layout.json:3475](../src/data/chapter4-three-floor-maze.layout.json#L3475)
917. 校史人物·竺可桢
   来源：[src/data/chapter4-three-floor-maze.layout.json:3485](../src/data/chapter4-three-floor-maze.layout.json#L3485)
918. 校史人物·路甬祥
   来源：[src/data/chapter4-three-floor-maze.layout.json:3495](../src/data/chapter4-three-floor-maze.layout.json#L3495)
919. 校史人物·陈建功
   来源：[src/data/chapter4-three-floor-maze.layout.json:3505](../src/data/chapter4-three-floor-maze.layout.json#L3505)
920. 校史人物·谈家桢
   来源：[src/data/chapter4-three-floor-maze.layout.json:3515](../src/data/chapter4-three-floor-maze.layout.json#L3515)
921. 校史人物·程开甲
   来源：[src/data/chapter4-three-floor-maze.layout.json:3525](../src/data/chapter4-three-floor-maze.layout.json#L3525)
922. 三楼校友头像长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:3535](../src/data/chapter4-three-floor-maze.layout.json#L3535)
923. 三楼参照教室教师
   来源：[src/data/chapter4-three-floor-maze.layout.json:3545](../src/data/chapter4-three-floor-maze.layout.json#L3545)
924. 三楼晨间教室布置参照
   来源：[src/data/chapter4-three-floor-maze.layout.json:3555](../src/data/chapter4-three-floor-maze.layout.json#L3555)
925. 校园后勤服务
   来源：[src/data/chapter4-wechat.content.json:3](../src/data/chapter4-wechat.content.json#L3)
926. 公众号
   来源：[src/data/chapter4-wechat.content.json:4](../src/data/chapter4-wechat.content.json#L4)
927. 段永平教学楼夜间运行提醒
   来源：[src/data/chapter4-wechat.content.json:5](../src/data/chapter4-wechat.content.json#L5)
928. 夜间清楼期间，部分通道将分时关闭，主电梯停靠状态可能调整。
   来源：[src/data/chapter4-wechat.content.json:7](../src/data/chapter4-wechat.content.json#L7)
929. 教学楼自 22:45 起按楼层分区清楼。
   来源：[src/data/chapter4-wechat.content.json:9](../src/data/chapter4-wechat.content.json#L9)
930. 主电梯停靠状态以轿厢显示和现场提示音为准。
   来源：[src/data/chapter4-wechat.content.json:10](../src/data/chapter4-wechat.content.json#L10)
931. 部分通道可能临时关闭，请留意楼层公告。
   来源：[src/data/chapter4-wechat.content.json:11](../src/data/chapter4-wechat.content.json#L11)
932. 现场广播和安全指引优先于本推送。
   来源：[src/data/chapter4-wechat.content.json:12](../src/data/chapter4-wechat.content.json#L12)
933. 读完并保存通知
   来源：[src/data/chapter4-wechat.content.json:14](../src/data/chapter4-wechat.content.json#L14)
934. 校园楼宇与生活服务
   来源：[src/data/chapter4-wechat.content.json:15](../src/data/chapter4-wechat.content.json#L15)
935. 楼宇小事
   来源：[src/data/chapter4-wechat.content.json:19](../src/data/chapter4-wechat.content.json#L19)
936. 雨天的伞先放哪儿
   来源：[src/data/chapter4-wechat.content.json:20](../src/data/chapter4-wechat.content.json#L20)
937. 收伞、取伞和寻找失物的几个细节，能少留一地水，也能少拿错一把黑伞。
   来源：[src/data/chapter4-wechat.content.json:22](../src/data/chapter4-wechat.content.json#L22)
938. 雨天的楼道口总会多出几把伞。午后从图书馆回来，伞尖还滴着水，带进教室容易把地砖踩出一串湿脚印。教学区入口旁的暂存架放了吸水垫，伞可以合好后靠边摆，伞柄别挂在消防门上。
   来源：[src/data/chapter4-wechat.content.json:26](../src/data/chapter4-wechat.content.json#L26)
939. 傍晚取伞时，先看看伞带和手柄上的小标记。黑伞排在一起，三分钟足够让人怀疑自己的记忆，也很容易拿错。没有找到的同学可以在服务台登记颜色、伞柄样式和大致时间。工作人员整理时会把散落的伞移到失物架，雨停后记得领走。
   来源：[src/data/chapter4-wechat.content.json:27](../src/data/chapter4-wechat.content.json#L27)
940. 夜读提示
   来源：[src/data/chapter4-wechat.content.json:32](../src/data/chapter4-wechat.content.json#L32)
941. 晚自习收尾的半分钟
   来源：[src/data/chapter4-wechat.content.json:33](../src/data/chapter4-wechat.content.json#L33)
942. 带走桌边的充电线，把椅子推进去，夜间清洁经过时能少绕几次。
   来源：[src/data/chapter4-wechat.content.json:35](../src/data/chapter4-wechat.content.json#L35)
943. 晚间自习临近结束时，走廊里的打印机通常还在吐最后几页，充电线也最容易留在桌角。离开前花半分钟看一眼座位下方，再把椅子轻轻推进去，清洁设备经过时能少绕几次。
   来源：[src/data/chapter4-wechat.content.json:39](../src/data/chapter4-wechat.content.json#L39)
944. 入口、电梯和可通行楼层以当晚现场提示为准。准备继续学习的同学，请把水杯、电脑和个人物品带在身边。临时找不到同伴时，可以先到大厅等候，别在正在清洁的楼层里来回找插座。
   来源：[src/data/chapter4-wechat.content.json:40](../src/data/chapter4-wechat.content.json#L40)
945. 食堂顺手事
   来源：[src/data/chapter4-wechat.content.json:45](../src/data/chapter4-wechat.content.json#L45)
946. 餐盘回收台前少等一会儿
   来源：[src/data/chapter4-wechat.content.json:46](../src/data/chapter4-wechat.content.json#L46)
947. 餐盘放稳，筷子和纸巾分开，下一位同学就能早一点离开回收台。
   来源：[src/data/chapter4-wechat.content.json:48](../src/data/chapter4-wechat.content.json#L48)
948. 午餐高峰过去后，回收台上常剩几只装着汤勺的餐盘。餐具回收口前有时只差两步，大家端着餐盘聊天，队伍就会停在转角。餐盘放稳后再把筷子和纸巾分开，后面的人能少等一会儿。
   来源：[src/data/chapter4-wechat.content.json:52](../src/data/chapter4-wechat.content.json#L52)
949. 汤碗和剩菜请先倒净，整杯饮料也别塞进餐盘缝里。纸巾掉进残渣桶时不用弯腰去捞，可以交给现场工作人员处理。吃完把桌面收干净，下一位同学就能直接坐下。
   来源：[src/data/chapter4-wechat.content.json:53](../src/data/chapter4-wechat.content.json#L53)
950. 校园慢行
   来源：[src/data/chapter4-wechat.content.json:58](../src/data/chapter4-wechat.content.json#L58)
951. 把共享单车摆正以后
   来源：[src/data/chapter4-wechat.content.json:59](../src/data/chapter4-wechat.content.json#L59)
952. 把车停进线内，给盲道、坡道和拖着行李的人多留一点通过空间。
   来源：[src/data/chapter4-wechat.content.json:61](../src/data/chapter4-wechat.content.json#L61)
953. 早八前后，教学区路边经常出现同一种停车方式。车头朝里，后轮卡在树池边，旁边只够一个人侧身通过。赶时间可以理解，拎着早餐或拖着行李经过的人也确实容易被绊住。
   来源：[src/data/chapter4-wechat.content.json:65](../src/data/chapter4-wechat.content.json#L65)
954. 骑到目的地后，把车停进线内，再把挡住盲道、坡道和楼门的车辆顺手移开一点。遇到倒下的车，可以先扶正后再结束用车。多花十秒，清洁车和轮椅都能顺着走。
   来源：[src/data/chapter4-wechat.content.json:66](../src/data/chapter4-wechat.content.json#L66)
955. 湖边观察
   来源：[src/data/chapter4-wechat.content.json:71](../src/data/chapter4-wechat.content.json#L71)
956. 在启真湖边看水鸟
   来源：[src/data/chapter4-wechat.content.json:72](../src/data/chapter4-wechat.content.json#L72)
957. 镜头可以拉近，脚步和食物要离远一些。安静观察，常能看到更多。
   来源：[src/data/chapter4-wechat.content.json:74](../src/data/chapter4-wechat.content.json#L74)
958. 启真湖边最近多了几只停在浅水处的水鸟。有人隔着栏杆拍照，也有人带着面包走近。鸟一受惊就会游向水面中央，岸边的人越多，等待的时间也越长。
   来源：[src/data/chapter4-wechat.content.json:78](../src/data/chapter4-wechat.content.json#L78)
959. 看鸟时留在步道上，把镜头拉近就够了。不要投喂面包、薯片和含糖饮料，也别追着鸟群跑。可以留意羽色、脚蹼和活动方向，声音放低一些。安静站一会儿，有时能看到它们靠近岸边。
   来源：[src/data/chapter4-wechat.content.json:79](../src/data/chapter4-wechat.content.json#L79)
960. 失物招领
   来源：[src/data/chapter4-wechat.content.json:84](../src/data/chapter4-wechat.content.json#L84)
961. 失物架上那只耳机
   来源：[src/data/chapter4-wechat.content.json:85](../src/data/chapter4-wechat.content.json#L85)
962. 水杯、卡套和耳机常出现在服务台，多留几个特征就能少跑几趟。
   来源：[src/data/chapter4-wechat.content.json:87](../src/data/chapter4-wechat.content.json#L87)
963. 楼宇服务台的失物架上，最常见的是水杯、门禁卡套和单只耳机。难找的是没有写名字的充电盒，外观看起来接近，型号、贴纸和磨损位置各有不同。
   来源：[src/data/chapter4-wechat.content.json:91](../src/data/chapter4-wechat.content.json#L91)
964. 捡到物品后，交给就近服务台时尽量补一句地点和时间。失主来问时，颜色、贴纸和磨损位置都能帮上忙。要找失物的同学可以先准备这些特征，再留一个可联系的方式。
   来源：[src/data/chapter4-wechat.content.json:92](../src/data/chapter4-wechat.content.json#L92)
965. 203 还开着吗？我电脑没关。
   来源：[src/data/chapter4-wechat.content.json:101](../src/data/chapter4-wechat.content.json#L101)；[src/scenes/phone/P14_Wechat/index.tsx:30](../src/scenes/phone/P14_Wechat/index.tsx#L30)
966. 林昊
   来源：[src/data/chapter4-wechat.content.json:101](../src/data/chapter4-wechat.content.json#L101)；[src/scenes/phone/P14_Wechat/index.tsx:30](../src/scenes/phone/P14_Wechat/index.tsx#L30)
967. 陈嘉
   来源：[src/data/chapter4-wechat.content.json:102](../src/data/chapter4-wechat.content.json#L102)；[src/scenes/phone/P14_Wechat/index.tsx:31](../src/scenes/phone/P14_Wechat/index.tsx#L31)
968. 刚看见保安从东边过去。
   来源：[src/data/chapter4-wechat.content.json:102](../src/data/chapter4-wechat.content.json#L102)；[src/scenes/phone/P14_Wechat/index.tsx:31](../src/scenes/phone/P14_Wechat/index.tsx#L31)
969. 东边不是已经封了吗？
   来源：[src/data/chapter4-wechat.content.json:103](../src/data/chapter4-wechat.content.json#L103)
970. 周琪
   来源：[src/data/chapter4-wechat.content.json:103](../src/data/chapter4-wechat.content.json#L103)
971. 室友
   来源：[src/data/chapter4-wechat.content.json:104](../src/data/chapter4-wechat.content.json#L104)
972. 我在西侧看见保洁推车，应该还能走。
   来源：[src/data/chapter4-wechat.content.json:104](../src/data/chapter4-wechat.content.json#L104)
973. 陈嘉撤回了一条消息
   来源：[src/data/chapter4-wechat.content.json:106](../src/data/chapter4-wechat.content.json#L106)
974. 算了，我去楼梯口看看。
   来源：[src/data/chapter4-wechat.content.json:107](../src/data/chapter4-wechat.content.json#L107)
975. 保存路线讨论截图
   来源：[src/data/chapter4-wechat.content.json:108](../src/data/chapter4-wechat.content.json#L108)
976. 文件传输助手
   来源：[src/data/chapter4-wechat.content.json:111](../src/data/chapter4-wechat.content.json#L111)
977. 还没有第四章现场资料。
   来源：[src/data/chapter4-wechat.content.json:112](../src/data/chapter4-wechat.content.json#L112)
978. 夜间运行通知
   来源：[src/data/chapter4-wechat.content.json:113](../src/data/chapter4-wechat.content.json#L113)
979. 主电梯到站提示音 00:07
   来源：[src/data/chapter4-wechat.content.json:114](../src/data/chapter4-wechat.content.json#L114)
980. 麦斯威夜间自习群路线讨论
   来源：[src/data/chapter4-wechat.content.json:115](../src/data/chapter4-wechat.content.json#L115)
981. 三楼新旧导视板对照照片
   来源：[src/data/chapter4-wechat.content.json:116](../src/data/chapter4-wechat.content.json#L116)
982. 把现在使用的导视板和残留的旧导视板都发我。
   来源：[src/data/chapter4-wechat.content.json:119](../src/data/chapter4-wechat.content.json#L119)
983. \[图片\] 三楼新旧导视板
   来源：[src/data/chapter4-wechat.content.json:120](../src/data/chapter4-wechat.content.json#L120)
984. 两张图的二楼箭头方向相反。去现场核对仍保留旧编号的一侧，再调整导视板。
   来源：[src/data/chapter4-wechat.content.json:121](../src/data/chapter4-wechat.content.json#L121)
985. 对照两张照片
   来源：[src/data/chapter4-wechat.content.json:122](../src/data/chapter4-wechat.content.json#L122)
986. 苏步青
   来源：[src/data/ChapterFourAlumniHonorWall.ts:95](../src/data/ChapterFourAlumniHonorWall.ts#L95)
987. 数学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:97](../src/data/ChapterFourAlumniHonorWall.ts#L97)；[src/data/ChapterFourAlumniHonorWall.ts:154](../src/data/ChapterFourAlumniHonorWall.ts#L154)；[src/data/ChapterFourAlumniHonorWall.ts:252](../src/data/ChapterFourAlumniHonorWall.ts#L252)
988. 1931年回国后任浙江大学数学系副教授、教授及系主任。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:99](../src/data/ChapterFourAlumniHonorWall.ts#L99)
989. 与陈建功共同形成有影响力的“陈苏学派”，培养了一批数学人才。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:100](../src/data/ChapterFourAlumniHonorWall.ts#L100)
990. 抗战时期随浙江大学西迁，在艰苦条件下继续教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:101](../src/data/ChapterFourAlumniHonorWall.ts#L101)
991. 浙江大学·求是大家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:103](../src/data/ChapterFourAlumniHonorWall.ts#L103)；[src/data/ChapterFourAlumniHonorWall.ts:220](../src/data/ChapterFourAlumniHonorWall.ts#L220)；[src/data/ChapterFourAlumniHonorWall.ts:239](../src/data/ChapterFourAlumniHonorWall.ts#L239)；[src/data/ChapterFourAlumniHonorWall.ts:258](../src/data/ChapterFourAlumniHonorWall.ts#L258)；[src/data/ChapterFourAlumniHonorWall.ts:334](../src/data/ChapterFourAlumniHonorWall.ts#L334)；[src/data/ChapterFourAlumniHonorWall.ts:372](../src/data/ChapterFourAlumniHonorWall.ts#L372)
992. 竺可桢
   来源：[src/data/ChapterFourAlumniHonorWall.ts:114](../src/data/ChapterFourAlumniHonorWall.ts#L114)
993. 气象学家、地理学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:116](../src/data/ChapterFourAlumniHonorWall.ts#L116)
994. 1936—1949年任浙江大学校长，领导学校完成西迁并坚持办学。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:118](../src/data/ChapterFourAlumniHonorWall.ts#L118)
995. 任内学校由 3 个学院、16 个系发展为 7 个学院、27 个系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:119](../src/data/ChapterFourAlumniHonorWall.ts#L119)
996. 他在新生入学时提出两个问题，要求学生思考求学目的与成人方向。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:120](../src/data/ChapterFourAlumniHonorWall.ts#L120)
997. 浙江大学国际联合学院·竺老两问
   来源：[src/data/ChapterFourAlumniHonorWall.ts:122](../src/data/ChapterFourAlumniHonorWall.ts#L122)
998. 路甬祥
   来源：[src/data/ChapterFourAlumniHonorWall.ts:133](../src/data/ChapterFourAlumniHonorWall.ts#L133)
999. 流体传动与控制学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:135](../src/data/ChapterFourAlumniHonorWall.ts#L135)
1000. 1964年毕业于浙江大学机械系，后留校任教并长期从事流体传动与控制研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:137](../src/data/ChapterFourAlumniHonorWall.ts#L137)
1001. 1988—1995年任浙江大学校长，推动学校教育、科研与管理改革。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:138](../src/data/ChapterFourAlumniHonorWall.ts#L138)
1002. 1991年当选中国科学院学部委员，1994年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:139](../src/data/ChapterFourAlumniHonorWall.ts#L139)
1003. 浙江大学·历任校长
   来源：[src/data/ChapterFourAlumniHonorWall.ts:141](../src/data/ChapterFourAlumniHonorWall.ts#L141)；[src/data/ChapterFourAlumniHonorWall.ts:296](../src/data/ChapterFourAlumniHonorWall.ts#L296)
1004. 陈建功
   来源：[src/data/ChapterFourAlumniHonorWall.ts:152](../src/data/ChapterFourAlumniHonorWall.ts#L152)
1005. 1929年起在浙江大学任教，主持数学系建设与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:156](../src/data/ChapterFourAlumniHonorWall.ts#L156)
1006. 与苏步青共同培育了中国现代数学的重要学术群体。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:157](../src/data/ChapterFourAlumniHonorWall.ts#L157)
1007. 西迁时期坚持教学和研究，奠定了浙大数学学科的早期基础。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:158](../src/data/ChapterFourAlumniHonorWall.ts#L158)
1008. 浙江大学档案馆·俊彩星驰长廊
   来源：[src/data/ChapterFourAlumniHonorWall.ts:160](../src/data/ChapterFourAlumniHonorWall.ts#L160)；[src/data/ChapterFourAlumniHonorWall.ts:429](../src/data/ChapterFourAlumniHonorWall.ts#L429)
1009. 谈家桢
   来源：[src/data/ChapterFourAlumniHonorWall.ts:172](../src/data/ChapterFourAlumniHonorWall.ts#L172)
1010. 遗传学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:174](../src/data/ChapterFourAlumniHonorWall.ts#L174)
1011. 曾任浙江大学生物系教授，在西迁途中继续组织遗传学教学与实验。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:176](../src/data/ChapterFourAlumniHonorWall.ts#L176)
1012. 在缺少自来水、电灯和专业设备的条件下，带领学生用简易器材坚持研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:177](../src/data/ChapterFourAlumniHonorWall.ts#L177)
1013. 后长期推动中国现代遗传学的学科建设与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:178](../src/data/ChapterFourAlumniHonorWall.ts#L178)
1014. 浙江大学·求是精神薪火相传
   来源：[src/data/ChapterFourAlumniHonorWall.ts:180](../src/data/ChapterFourAlumniHonorWall.ts#L180)
1015. 程开甲
   来源：[src/data/ChapterFourAlumniHonorWall.ts:192](../src/data/ChapterFourAlumniHonorWall.ts#L192)
1016. 核物理学家、人民科学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:194](../src/data/ChapterFourAlumniHonorWall.ts#L194)
1017. 1937级浙江大学物理系校友，1941年毕业。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:196](../src/data/ChapterFourAlumniHonorWall.ts#L196)
1018. 是我国核武器研究的领导者之一，也是核试验事业的开拓者。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:197](../src/data/ChapterFourAlumniHonorWall.ts#L197)
1019. 获两弹一星功勋奖章、国家最高科学技术奖、八一勋章与人民科学家国家荣誉称号。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:198](../src/data/ChapterFourAlumniHonorWall.ts#L198)
1020. 浙江大学·程开甲先生诞辰 105 周年纪念会
   来源：[src/data/ChapterFourAlumniHonorWall.ts:200](../src/data/ChapterFourAlumniHonorWall.ts#L200)
1021. 王淦昌
   来源：[src/data/ChapterFourAlumniHonorWall.ts:212](../src/data/ChapterFourAlumniHonorWall.ts#L212)
1022. 核物理学家、两弹一星功勋科学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:214](../src/data/ChapterFourAlumniHonorWall.ts#L214)
1023. 1936年起任浙江大学物理系教授，并随学校西迁坚持教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:216](../src/data/ChapterFourAlumniHonorWall.ts#L216)
1024. 长期从事核物理研究，是我国核科学与核武器研制的重要开拓者之一。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:217](../src/data/ChapterFourAlumniHonorWall.ts#L217)
1025. 1999年获追授两弹一星功勋奖章。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:218](../src/data/ChapterFourAlumniHonorWall.ts#L218)
1026. 贝时璋
   来源：[src/data/ChapterFourAlumniHonorWall.ts:231](../src/data/ChapterFourAlumniHonorWall.ts#L231)
1027. 生物学家、生物物理学奠基人
   来源：[src/data/ChapterFourAlumniHonorWall.ts:233](../src/data/ChapterFourAlumniHonorWall.ts#L233)
1028. 1930年在浙江大学创建生物学系，并在西迁时期持续组织教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:235](../src/data/ChapterFourAlumniHonorWall.ts#L235)
1029. 1958年参与创建中国科学院生物物理研究所并任首任所长。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:236](../src/data/ChapterFourAlumniHonorWall.ts#L236)
1030. 长期推动我国细胞学、实验生物学与生物物理学发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:237](../src/data/ChapterFourAlumniHonorWall.ts#L237)
1031. 谷超豪
   来源：[src/data/ChapterFourAlumniHonorWall.ts:250](../src/data/ChapterFourAlumniHonorWall.ts#L250)
1032. 1943年进入浙江大学龙泉分校，后在数学系学习并任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:254](../src/data/ChapterFourAlumniHonorWall.ts#L254)
1033. 在偏微分方程、微分几何和数学物理等领域取得系统成果。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:255](../src/data/ChapterFourAlumniHonorWall.ts#L255)
1034. 2009年获国家最高科学技术奖。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:256](../src/data/ChapterFourAlumniHonorWall.ts#L256)
1035. 李政道
   来源：[src/data/ChapterFourAlumniHonorWall.ts:269](../src/data/ChapterFourAlumniHonorWall.ts#L269)
1036. 物理学家、诺贝尔物理学奖获得者
   来源：[src/data/ChapterFourAlumniHonorWall.ts:271](../src/data/ChapterFourAlumniHonorWall.ts#L271)
1037. 1943年进入迁至湄潭的浙江大学物理系学习。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:273](../src/data/ChapterFourAlumniHonorWall.ts#L273)
1038. 求学期间受到束星北、王淦昌等先生指导，奠定理论物理基础。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:274](../src/data/ChapterFourAlumniHonorWall.ts#L274)
1039. 长期支持中国基础科学研究与青年人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:275](../src/data/ChapterFourAlumniHonorWall.ts#L275)
1040. 浙江大学·李政道纪念
   来源：[src/data/ChapterFourAlumniHonorWall.ts:277](../src/data/ChapterFourAlumniHonorWall.ts#L277)
1041. 潘云鹤
   来源：[src/data/ChapterFourAlumniHonorWall.ts:288](../src/data/ChapterFourAlumniHonorWall.ts#L288)
1042. 计算机应用专家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:290](../src/data/ChapterFourAlumniHonorWall.ts#L290)
1043. 1981年在浙江大学获得硕士学位后留校任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:292](../src/data/ChapterFourAlumniHonorWall.ts#L292)
1044. 1995—2006年任浙江大学校长，参与推动四校合并后的学科建设。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:293](../src/data/ChapterFourAlumniHonorWall.ts#L293)
1045. 长期研究人工智能、计算机美术与智能城市。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:294](../src/data/ChapterFourAlumniHonorWall.ts#L294)
1046. 韩祯祥
   来源：[src/data/ChapterFourAlumniHonorWall.ts:307](../src/data/ChapterFourAlumniHonorWall.ts#L307)
1047. 电力系统专家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:309](../src/data/ChapterFourAlumniHonorWall.ts#L309)
1048. 1951年毕业于浙江大学电机系并留校任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:311](../src/data/ChapterFourAlumniHonorWall.ts#L311)
1049. 1984—1988年任浙江大学校长，推动教学、科研与国际交流。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:312](../src/data/ChapterFourAlumniHonorWall.ts#L312)
1050. 长期从事电力系统稳定、控制与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:313](../src/data/ChapterFourAlumniHonorWall.ts#L313)
1051. 浙江大学·韩祯祥院士纪念
   来源：[src/data/ChapterFourAlumniHonorWall.ts:315](../src/data/ChapterFourAlumniHonorWall.ts#L315)
1052. 夏道行
   来源：[src/data/ChapterFourAlumniHonorWall.ts:326](../src/data/ChapterFourAlumniHonorWall.ts#L326)
1053. 数学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:328](../src/data/ChapterFourAlumniHonorWall.ts#L328)；[src/data/ChapterFourAlumniHonorWall.ts:366](../src/data/ChapterFourAlumniHonorWall.ts#L366)
1054. 1952年进入浙江大学数学系攻读研究生，师从陈建功先生。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:330](../src/data/ChapterFourAlumniHonorWall.ts#L330)
1055. 在泛函分析、广义函数和数学物理等领域作出重要贡献。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:331](../src/data/ChapterFourAlumniHonorWall.ts#L331)
1056. 1980年当选中国科学院学部委员。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:332](../src/data/ChapterFourAlumniHonorWall.ts#L332)
1057. 潘镜芙
   来源：[src/data/ChapterFourAlumniHonorWall.ts:345](../src/data/ChapterFourAlumniHonorWall.ts#L345)
1058. 船舶设计专家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:347](../src/data/ChapterFourAlumniHonorWall.ts#L347)
1059. 1952年毕业于浙江大学电机系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:349](../src/data/ChapterFourAlumniHonorWall.ts#L349)
1060. 长期主持我国导弹驱逐舰研制，推动舰船总体设计与系统集成发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:350](../src/data/ChapterFourAlumniHonorWall.ts#L350)
1061. 1995年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:351](../src/data/ChapterFourAlumniHonorWall.ts#L351)
1062. 浙江大学档案馆·潘镜芙
   来源：[src/data/ChapterFourAlumniHonorWall.ts:353](../src/data/ChapterFourAlumniHonorWall.ts#L353)
1063. 王元
   来源：[src/data/ChapterFourAlumniHonorWall.ts:364](../src/data/ChapterFourAlumniHonorWall.ts#L364)
1064. 1952年毕业于浙江大学数学系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:368](../src/data/ChapterFourAlumniHonorWall.ts#L368)
1065. 在数论、数值分析与组合设计等领域取得重要成果。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:369](../src/data/ChapterFourAlumniHonorWall.ts#L369)
1066. 与华罗庚共同发展的数论方法被称为华—王方法。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:370](../src/data/ChapterFourAlumniHonorWall.ts#L370)
1067. 陈宜张
   来源：[src/data/ChapterFourAlumniHonorWall.ts:383](../src/data/ChapterFourAlumniHonorWall.ts#L383)
1068. 神经生理学家、医学教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:385](../src/data/ChapterFourAlumniHonorWall.ts#L385)
1069. 1952年毕业于浙江大学医学院，是学院首届毕业生之一。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:387](../src/data/ChapterFourAlumniHonorWall.ts#L387)
1070. 长期研究神经生理学与神经内分泌调控。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:388](../src/data/ChapterFourAlumniHonorWall.ts#L388)
1071. 曾任浙江医科大学校长并推动医学教育发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:389](../src/data/ChapterFourAlumniHonorWall.ts#L389)
1072. 浙江大学·陈宜张
   来源：[src/data/ChapterFourAlumniHonorWall.ts:391](../src/data/ChapterFourAlumniHonorWall.ts#L391)
1073. 林俊德
   来源：[src/data/ChapterFourAlumniHonorWall.ts:402](../src/data/ChapterFourAlumniHonorWall.ts#L402)
1074. 爆炸力学与核试验工程专家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:404](../src/data/ChapterFourAlumniHonorWall.ts#L404)
1075. 1960年毕业于浙江大学机械系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:406](../src/data/ChapterFourAlumniHonorWall.ts#L406)
1076. 扎根大漠五十余年，参加我国全部核试验并负责关键测试技术。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:407](../src/data/ChapterFourAlumniHonorWall.ts#L407)
1077. 1993年当选中国工程院院士，2018年被列入全军挂像英模。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:408](../src/data/ChapterFourAlumniHonorWall.ts#L408)
1078. 浙江大学·林俊德院士纪念
   来源：[src/data/ChapterFourAlumniHonorWall.ts:410](../src/data/ChapterFourAlumniHonorWall.ts#L410)
1079. 谭其骧
   来源：[src/data/ChapterFourAlumniHonorWall.ts:421](../src/data/ChapterFourAlumniHonorWall.ts#L421)
1080. 历史地理学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:423](../src/data/ChapterFourAlumniHonorWall.ts#L423)
1081. 1940—1950年在浙江大学史地系任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:425](../src/data/ChapterFourAlumniHonorWall.ts#L425)
1082. 在历史地理、疆域沿革与人口迁移研究方面影响深远。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:426](../src/data/ChapterFourAlumniHonorWall.ts#L426)
1083. 主持编绘《中国历史地图集》，推动现代历史地理学科建设。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:427](../src/data/ChapterFourAlumniHonorWall.ts#L427)
1084. 郑树森
   来源：[src/data/ChapterFourAlumniHonorWall.ts:440](../src/data/ChapterFourAlumniHonorWall.ts#L440)
1085. 器官移植专家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:442](../src/data/ChapterFourAlumniHonorWall.ts#L442)
1086. 长期在浙江大学从事肝胆胰外科与器官移植临床、科研和教学。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:444](../src/data/ChapterFourAlumniHonorWall.ts#L444)
1087. 推动我国肝移植、多器官联合移植与相关技术体系发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:445](../src/data/ChapterFourAlumniHonorWall.ts#L445)
1088. 2001年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:446](../src/data/ChapterFourAlumniHonorWall.ts#L446)
1089. 浙江大学个人主页·郑树森
   来源：[src/data/ChapterFourAlumniHonorWall.ts:448](../src/data/ChapterFourAlumniHonorWall.ts#L448)
1090. 杨卫
   来源：[src/data/ChapterFourAlumniHonorWall.ts:459](../src/data/ChapterFourAlumniHonorWall.ts#L459)
1091. 固体力学专家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:461](../src/data/ChapterFourAlumniHonorWall.ts#L461)
1092. 长期在浙江大学从事固体力学、微纳米力学与交叉力学研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:463](../src/data/ChapterFourAlumniHonorWall.ts#L463)
1093. 2006—2013年任浙江大学校长，推动学科交叉与工程教育发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:464](../src/data/ChapterFourAlumniHonorWall.ts#L464)
1094. 2003年当选中国科学院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:465](../src/data/ChapterFourAlumniHonorWall.ts#L465)
1095. 浙江大学个人主页·杨卫
   来源：[src/data/ChapterFourAlumniHonorWall.ts:467](../src/data/ChapterFourAlumniHonorWall.ts#L467)
1096. 第一问：到浙大来做什么？
   来源：[src/data/ChapterFourAlumniHonorWall.ts:480](../src/data/ChapterFourAlumniHonorWall.ts#L480)
1097. 追问事实与方法
   来源：[src/data/ChapterFourAlumniHonorWall.ts:482](../src/data/ChapterFourAlumniHonorWall.ts#L482)
1098. 用所学解决真实问题
   来源：[src/data/ChapterFourAlumniHonorWall.ts:483](../src/data/ChapterFourAlumniHonorWall.ts#L483)
1099. 为公共需要承担责任
   来源：[src/data/ChapterFourAlumniHonorWall.ts:484](../src/data/ChapterFourAlumniHonorWall.ts#L484)
1100. 第二问：将来毕业后要做什么样的人？
   来源：[src/data/ChapterFourAlumniHonorWall.ts:489](../src/data/ChapterFourAlumniHonorWall.ts#L489)
1101. 对工作和他人负责
   来源：[src/data/ChapterFourAlumniHonorWall.ts:491](../src/data/ChapterFourAlumniHonorWall.ts#L491)
1102. 保持独立判断与证据诚实
   来源：[src/data/ChapterFourAlumniHonorWall.ts:492](../src/data/ChapterFourAlumniHonorWall.ts#L492)
1103. 把能力放到社会需要上
   来源：[src/data/ChapterFourAlumniHonorWall.ts:493](../src/data/ChapterFourAlumniHonorWall.ts#L493)
1104. 打开前台值班签到板
   来源：[src/data/ChapterFourInteractionContent.ts:92](../src/data/ChapterFourInteractionContent.ts#L92)
1105. 前台签到板留有三个空位，可以把已确认的值班牌放回去。
   来源：[src/data/ChapterFourInteractionContent.ts:101](../src/data/ChapterFourInteractionContent.ts#L101)
1106. 三个夹痕的磨损不同，分别对应 104、105 与主电梯。
   来源：[src/data/ChapterFourInteractionContent.ts:102](../src/data/ChapterFourInteractionContent.ts#L102)
1107. 查看 201 创客工坊
   来源：[src/data/ChapterFourInteractionContent.ts:107](../src/data/ChapterFourInteractionContent.ts#L107)
1108. 201 的工具已经归位，门边登记板停在晚间封闭状态。
   来源：[src/data/ChapterFourInteractionContent.ts:117](../src/data/ChapterFourInteractionContent.ts#L117)
1109. 操作台边缘保留着较早的手部动作残影，当前房间没有新增活动轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:118](../src/data/ChapterFourInteractionContent.ts#L118)
1110. 午间工坊暂停开放，切割垫上压着尚未装配的校园模型。
   来源：[src/data/ChapterFourInteractionContent.ts:121](../src/data/ChapterFourInteractionContent.ts#L121)
1111. 模型零件周围有连续取放残影，时间间隔与午休人流一致。
   来源：[src/data/ChapterFourInteractionContent.ts:122](../src/data/ChapterFourInteractionContent.ts#L122)
1112. 晚课前的工坊已经清台，只有一台焊台仍显示余温警示。
   来源：[src/data/ChapterFourInteractionContent.ts:125](../src/data/ChapterFourInteractionContent.ts#L125)
1113. 焊台上方的动作残影在 18:50 前停止，随后没有人继续使用设备。
   来源：[src/data/ChapterFourInteractionContent.ts:126](../src/data/ChapterFourInteractionContent.ts#L126)
1114. 维修时段的总电源已经断开，工具柜保持封签状态。
   来源：[src/data/ChapterFourInteractionContent.ts:129](../src/data/ChapterFourInteractionContent.ts#L129)
1115. 工具柜没有被开启的残影，走廊异常并非来自这间工坊。
   来源：[src/data/ChapterFourInteractionContent.ts:130](../src/data/ChapterFourInteractionContent.ts#L130)
1116. 应急照明只覆盖出口，工坊设备仍保持断电。
   来源：[src/data/ChapterFourInteractionContent.ts:133](../src/data/ChapterFourInteractionContent.ts#L133)
1117. 门口出现一段短暂停留残影，没有进入操作区。
   来源：[src/data/ChapterFourInteractionContent.ts:134](../src/data/ChapterFourInteractionContent.ts#L134)
1118. 晨间开放检查已完成，工具数量与登记表一致。
   来源：[src/data/ChapterFourInteractionContent.ts:137](../src/data/ChapterFourInteractionContent.ts#L137)
1119. 昨夜残影已经淡去，设备状态回到正常的早班记录。
   来源：[src/data/ChapterFourInteractionContent.ts:138](../src/data/ChapterFourInteractionContent.ts#L138)
1120. 查看 202 阶梯教室
   来源：[src/data/ChapterFourInteractionContent.ts:144](../src/data/ChapterFourInteractionContent.ts#L144)
1121. 202 的投影幕已经收起，阶梯座位按离场状态折叠。
   来源：[src/data/ChapterFourInteractionContent.ts:154](../src/data/ChapterFourInteractionContent.ts#L154)
1122. 最后一排到门口有一段连贯离场残影，讲台附近没有停留。
   来源：[src/data/ChapterFourInteractionContent.ts:155](../src/data/ChapterFourInteractionContent.ts#L155)
1123. 午间讲座尚未开始，前排桌面摆着未发放的空白资料。
   来源：[src/data/ChapterFourInteractionContent.ts:158](../src/data/ChapterFourInteractionContent.ts#L158)
1124. 座位间只有短暂经过的残影，没有形成完整听课轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:159](../src/data/ChapterFourInteractionContent.ts#L159)
1125. 晚间教室已清空，投影机风扇刚停止，门槛处仍有散场脚印。
   来源：[src/data/ChapterFourInteractionContent.ts:162](../src/data/ChapterFourInteractionContent.ts#L162)
1126. 座位残影从前排向出口逐段消失，散场时间集中在 18:50 前后。
   来源：[src/data/ChapterFourInteractionContent.ts:163](../src/data/ChapterFourInteractionContent.ts#L163)
1127. 维修许可牌挂在门外，室内设备保持关机。
   来源：[src/data/ChapterFourInteractionContent.ts:166](../src/data/ChapterFourInteractionContent.ts#L166)
1128. 讲台投影区保留一段独立画面残留，与普通授课记录不连续。
   来源：[src/data/ChapterFourInteractionContent.ts:167](../src/data/ChapterFourInteractionContent.ts#L167)
1129. 停电后安全出口灯正常，阶梯通道没有障碍物。
   来源：[src/data/ChapterFourInteractionContent.ts:170](../src/data/ChapterFourInteractionContent.ts#L170)
1130. 投影区残影仍在，亮度不随停电状态变化。
   来源：[src/data/ChapterFourInteractionContent.ts:171](../src/data/ChapterFourInteractionContent.ts#L171)
1131. 202 已完成晨检，投影和座椅等待第一节课。
   来源：[src/data/ChapterFourInteractionContent.ts:174](../src/data/ChapterFourInteractionContent.ts#L174)
1132. 夜间残留停止更新，教室回到正常的晨间时间轨。
   来源：[src/data/ChapterFourInteractionContent.ts:175](../src/data/ChapterFourInteractionContent.ts#L175)
1133. 查看 203 计算机教室
   来源：[src/data/ChapterFourInteractionContent.ts:181](../src/data/ChapterFourInteractionContent.ts#L181)
1134. 203 的终端已批量关机，教师机保留着当日维护清单。
   来源：[src/data/ChapterFourInteractionContent.ts:191](../src/data/ChapterFourInteractionContent.ts#L191)
1135. 屏幕前的残影按座位顺序消失，没有人在关机后返回。
   来源：[src/data/ChapterFourInteractionContent.ts:192](../src/data/ChapterFourInteractionContent.ts#L192)
1136. 午间机房处于节能待机，靠门终端正在安装课程环境。
   来源：[src/data/ChapterFourInteractionContent.ts:195](../src/data/ChapterFourInteractionContent.ts#L195)
1137. 键盘上方的输入残影很短，属于自动部署前的检查动作。
   来源：[src/data/ChapterFourInteractionContent.ts:196](../src/data/ChapterFourInteractionContent.ts#L196)
1138. 晚课结束后终端已退出账号，第三排有一把椅子尚未推回。
   来源：[src/data/ChapterFourInteractionContent.ts:199](../src/data/ChapterFourInteractionContent.ts#L199)
1139. 第三排的离座残影比其他位置晚六秒，但随后直接离开机房。
   来源：[src/data/ChapterFourInteractionContent.ts:200](../src/data/ChapterFourInteractionContent.ts#L200)
1140. 机房交换机仍在线，学生终端全部断开。
   来源：[src/data/ChapterFourInteractionContent.ts:203](../src/data/ChapterFourInteractionContent.ts#L203)
1141. 网络指示残影连续，设备没有出现异常重启。
   来源：[src/data/ChapterFourInteractionContent.ts:204](../src/data/ChapterFourInteractionContent.ts#L204)
1142. 后备电源只维持交换机，显示器和主机均已关闭。
   来源：[src/data/ChapterFourInteractionContent.ts:207](../src/data/ChapterFourInteractionContent.ts#L207)
1143. 设备断电时间一致，没有单独延迟的终端。
   来源：[src/data/ChapterFourInteractionContent.ts:208](../src/data/ChapterFourInteractionContent.ts#L208)
1144. 机房已按早课配置启动，座位状态与预约名单一致。
   来源：[src/data/ChapterFourInteractionContent.ts:211](../src/data/ChapterFourInteractionContent.ts#L211)
1145. 夜间设备残影已经结束，当前只有晨检人员的短时轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:212](../src/data/ChapterFourInteractionContent.ts#L212)
1146. 查看开放自习区路线板
   来源：[src/data/ChapterFourInteractionContent.ts:218](../src/data/ChapterFourInteractionContent.ts#L218)
1147. 路线板上的四段卡片可以重新排列，以确认前往 202 的通道。
   来源：[src/data/ChapterFourInteractionContent.ts:228](../src/data/ChapterFourInteractionContent.ts#L228)
1148. 人流残影从自习区向东移动，穿过教室门槛后抵达 202 出口。
   来源：[src/data/ChapterFourInteractionContent.ts:229](../src/data/ChapterFourInteractionContent.ts#L229)
1149. 查看 301 校史档案展
   来源：[src/data/ChapterFourInteractionContent.ts:234](../src/data/ChapterFourInteractionContent.ts#L234)
1150. 301 的档案柜按年代编号，展签强调记录需要保留原始时间。
   来源：[src/data/ChapterFourInteractionContent.ts:244](../src/data/ChapterFourInteractionContent.ts#L244)
1151. 翻阅残影停在同一页：校史记录同时注明事件、地点与记录人。
   来源：[src/data/ChapterFourInteractionContent.ts:245](../src/data/ChapterFourInteractionContent.ts#L245)
1152. 午间展厅开放，玻璃柜中的教学日志按日期排放。
   来源：[src/data/ChapterFourInteractionContent.ts:248](../src/data/ChapterFourInteractionContent.ts#L248)
1153. 访客残影在日志柜前停留最久，随后依次查看人物档案。
   来源：[src/data/ChapterFourInteractionContent.ts:249](../src/data/ChapterFourInteractionContent.ts#L249)
1154. 晚间展厅已停止接待，档案扫描台仍显示当日校验结果。
   来源：[src/data/ChapterFourInteractionContent.ts:252](../src/data/ChapterFourInteractionContent.ts#L252)
1155. 扫描动作在 18:50 前完成，每页都保留来源编号。
   来源：[src/data/ChapterFourInteractionContent.ts:253](../src/data/ChapterFourInteractionContent.ts#L253)
1156. 恒温柜运行正常，维修记录没有涉及档案展区。
   来源：[src/data/ChapterFourInteractionContent.ts:256](../src/data/ChapterFourInteractionContent.ts#L256)
1157. 展柜周围没有异常移动残影，档案位置保持不变。
   来源：[src/data/ChapterFourInteractionContent.ts:257](../src/data/ChapterFourInteractionContent.ts#L257)
1158. 停电时档案柜自动上锁，应急照明覆盖疏散通道。
   来源：[src/data/ChapterFourInteractionContent.ts:260](../src/data/ChapterFourInteractionContent.ts#L260)
1159. 锁定动作同时发生，没有单独开启的柜门。
   来源：[src/data/ChapterFourInteractionContent.ts:261](../src/data/ChapterFourInteractionContent.ts#L261)
1160. 晨检完成后，档案展恢复开放状态。
   来源：[src/data/ChapterFourInteractionContent.ts:264](../src/data/ChapterFourInteractionContent.ts#L264)
1161. 早班记录从 07:55 开始，昨夜时间轨已经封存。
   来源：[src/data/ChapterFourInteractionContent.ts:265](../src/data/ChapterFourInteractionContent.ts#L265)
1162. 查看 302 媒体工作室
   来源：[src/data/ChapterFourInteractionContent.ts:271](../src/data/ChapterFourInteractionContent.ts#L271)
1163. 302 的录音设备已关闭，时间码发生器保留最后一次同步结果。
   来源：[src/data/ChapterFourInteractionContent.ts:281](../src/data/ChapterFourInteractionContent.ts#L281)
1164. 剪辑台残影显示素材被逐段核对，没有一次性覆盖原始文件。
   来源：[src/data/ChapterFourInteractionContent.ts:282](../src/data/ChapterFourInteractionContent.ts#L282)
1165. 午间工作室正在导出校园活动素材，监听音量保持在低档。
   来源：[src/data/ChapterFourInteractionContent.ts:285](../src/data/ChapterFourInteractionContent.ts#L285)
1166. 录音棚里的说话残影与波形段落对应，停顿位置清晰。
   来源：[src/data/ChapterFourInteractionContent.ts:286](../src/data/ChapterFourInteractionContent.ts#L286)
1167. 晚间录制已经结束，场记板停在 18:50 的收尾镜次。
   来源：[src/data/ChapterFourInteractionContent.ts:289](../src/data/ChapterFourInteractionContent.ts#L289)
1168. 最后一段人声结束后仍有六秒环境声，随后才停止录制。
   来源：[src/data/ChapterFourInteractionContent.ts:290](../src/data/ChapterFourInteractionContent.ts#L290)
1169. 工作室断开外部输入，存储阵列继续执行校验。
   来源：[src/data/ChapterFourInteractionContent.ts:293](../src/data/ChapterFourInteractionContent.ts#L293)
1170. 设备残影只显示自动校验，没有新的录制动作。
   来源：[src/data/ChapterFourInteractionContent.ts:294](../src/data/ChapterFourInteractionContent.ts#L294)
1171. 后备电源保留时间码和存储阵列，其他设备已经关闭。
   来源：[src/data/ChapterFourInteractionContent.ts:297](../src/data/ChapterFourInteractionContent.ts#L297)
1172. 时间码在停电期间连续，没有发生跳秒。
   来源：[src/data/ChapterFourInteractionContent.ts:298](../src/data/ChapterFourInteractionContent.ts#L298)
1173. 工作室完成晨间同步，所有设备采用同一时间源。
   来源：[src/data/ChapterFourInteractionContent.ts:301](../src/data/ChapterFourInteractionContent.ts#L301)
1174. 当前残影只有开机检查，时间轨从 07:55 重新开始。
   来源：[src/data/ChapterFourInteractionContent.ts:302](../src/data/ChapterFourInteractionContent.ts#L302)
1175. 查看 304 报告厅
   来源：[src/data/ChapterFourInteractionContent.ts:308](../src/data/ChapterFourInteractionContent.ts#L308)
1176. 304 的报告题目仍留在侧屏：判断需要来源、时间和可复核记录。
   来源：[src/data/ChapterFourInteractionContent.ts:318](../src/data/ChapterFourInteractionContent.ts#L318)
1177. 观众残影在提问环节集中出现，讲台记录保留了每次修改。
   来源：[src/data/ChapterFourInteractionContent.ts:319](../src/data/ChapterFourInteractionContent.ts#L319)
1178. 午间报告尚未开始，讲台水杯和翻页器已经摆好。
   来源：[src/data/ChapterFourInteractionContent.ts:322](../src/data/ChapterFourInteractionContent.ts#L322)
1179. 前排只有布场人员的短时残影，座位区尚未形成观众轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:323](../src/data/ChapterFourInteractionContent.ts#L323)
1180. 晚间报告结束后，侧屏保留最后一页：记录结果，也记录判断过程。
   来源：[src/data/ChapterFourInteractionContent.ts:326](../src/data/ChapterFourInteractionContent.ts#L326)
1181. 散场残影从后排开始，讲台人员最后离开。
   来源：[src/data/ChapterFourInteractionContent.ts:327](../src/data/ChapterFourInteractionContent.ts#L327)
1182. 报告厅完成设备巡检，扩声与投影均处于关机状态。
   来源：[src/data/ChapterFourInteractionContent.ts:330](../src/data/ChapterFourInteractionContent.ts#L330)
1183. 设备周围没有异常操作残影，巡检记录连续。
   来源：[src/data/ChapterFourInteractionContent.ts:331](../src/data/ChapterFourInteractionContent.ts#L331)
1184. 应急广播接管报告厅，所有出口指示正常。
   来源：[src/data/ChapterFourInteractionContent.ts:334](../src/data/ChapterFourInteractionContent.ts#L334)
1185. 广播启用与停电同时发生，没有额外控制动作。
   来源：[src/data/ChapterFourInteractionContent.ts:335](../src/data/ChapterFourInteractionContent.ts#L335)
1186. 报告厅开始晨间准备，侧屏切换为当日安排。
   来源：[src/data/ChapterFourInteractionContent.ts:338](../src/data/ChapterFourInteractionContent.ts#L338)
1187. 当前只有布场人员的残影，昨夜报告已经归档。
   来源：[src/data/ChapterFourInteractionContent.ts:339](../src/data/ChapterFourInteractionContent.ts#L339)
1188. 待补全
   来源：[src/data/itemCatalog.ts:212](../src/data/itemCatalog.ts#L212)
1189. 状态
   来源：[src/data/itemCatalog.ts:212](../src/data/itemCatalog.ts#L212)；[src/data/itemCatalog.ts:235](../src/data/itemCatalog.ts#L235)
1190. 教学楼签到
   来源：[src/data/itemCatalog.ts:213](../src/data/itemCatalog.ts#L213)
1191. 纸面记录停在 07:55 前后，签字栏还空着。
   来源：[src/data/itemCatalog.ts:216](../src/data/itemCatalog.ts#L216)
1192. 它会暂时离开你的道具栏，但最后仍需要回到签到口。
   来源：[src/data/itemCatalog.ts:217](../src/data/itemCatalog.ts#L217)
1193. 边缘有多次折返留下的旧压痕。
   来源：[src/data/itemCatalog.ts:219](../src/data/itemCatalog.ts#L219)
1194. 202 阶梯教室投影
   来源：[src/data/itemCatalog.ts:234](../src/data/itemCatalog.ts#L234)
1195. 来源
   来源：[src/data/itemCatalog.ts:234](../src/data/itemCatalog.ts#L234)
1196. 待归位
   来源：[src/data/itemCatalog.ts:235](../src/data/itemCatalog.ts#L235)
1197. 它是被偷走的最后一分钟，需要回到旧钟分针端点。
   来源：[src/data/itemCatalog.ts:238](../src/data/itemCatalog.ts#L238)
1198. 归位后，手机与世界时间会重新对齐。
   来源：[src/data/itemCatalog.ts:239](../src/data/itemCatalog.ts#L239)
1199. 纸面的光影像一截被掰下来的时间。
   来源：[src/data/itemCatalog.ts:241](../src/data/itemCatalog.ts#L241)
1200. 左岸快到了。稳住节奏。
   来源：[src/data/pursuit.audio.content.json:73](../src/data/pursuit.audio.content.json#L73)
1201. The left bank is close. Hold the rhythm.
   来源：[src/data/pursuit.audio.content.json:74](../src/data/pursuit.audio.content.json#L74)
1202. Stop! Step away from the clock.
   来源：[src/data/pursuit.audio.content.json:88](../src/data/pursuit.audio.content.json#L88)
1203. Do not run upstairs. Stop now.
   来源：[src/data/pursuit.audio.content.json:102](../src/data/pursuit.audio.content.json#L102)
1204. I can see you. Stop!
   来源：[src/data/pursuit.audio.content.json:116](../src/data/pursuit.audio.content.json#L116)
1205. 门厅 · 教室层
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:21](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L21)
1206. 104 / 105 / 旧钟门厅
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:22](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L22)
1207. 起行与门体轨
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:23](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L23)
1208. 一楼门体持续开放八秒，完整覆盖六秒进入窗口。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:26](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L26)
1209. 门体闭合后，轿厢指示立即由 1F 转为上行。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:27](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L27)
1210. 204 · 创客层
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:34](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L34)
1211. 201 / 203 / 204 / 开放自习区
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:35](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L35)
1212. 外呼与门机对照
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:36](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L36)
1213. 二楼下行外呼在 18:50:04 被按下，按钮持续亮到 18:50:12。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:39](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L39)
1214. 同一时间段没有二楼门机开启记录，层显由 1F 直接跳到 3F。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:40](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L40)
1215. 荣誉墙 · 档案层
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:47](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L47)
1216. 301 / 302 / 303 / 304 / 荣誉墙
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:48](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L48)
1217. 到站铃与开门轨
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:49](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L49)
1218. 三楼到站铃在 18:50:12 响起，随后门机完整开启。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:52](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L52)
1219. 轿厢内没有第二次起步记录，这里是离开一楼后的实际到站层。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:53](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L53)
1220. 值班牌重建
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:93](../src/modules/ChapterFourInsertedPuzzleModel.ts#L93)
1221. A1 前台
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:94](../src/modules/ChapterFourInsertedPuzzleModel.ts#L94)
1222. 三段痕迹分别停在 104、105 与主电梯；夹痕由左向右逐渐变新。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:95](../src/modules/ChapterFourInsertedPuzzleModel.ts#L95)
1223. 把三张值班牌按痕迹先后放回签到板。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:96](../src/modules/ChapterFourInsertedPuzzleModel.ts#L96)
1224. A1 的三处调查已汇成一条值班记录。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:97](../src/modules/ChapterFourInsertedPuzzleModel.ts#L97)
1225. 胶片索引
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:103](../src/modules/ChapterFourInsertedPuzzleModel.ts#L103)
1226. A3 · 301 校史档案展
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:104](../src/modules/ChapterFourInsertedPuzzleModel.ts#L104)
1227. 残留索引指向九十年代末、A3 层，并标记为入口导视用途。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:105](../src/modules/ChapterFourInsertedPuzzleModel.ts#L105)
1228. 用年份、楼层和用途缩小抽屉范围，取出唯一胶片。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:106](../src/modules/ChapterFourInsertedPuzzleModel.ts#L106)
1229. 旧导视胶片已从索引抽屉取出。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:107](../src/modules/ChapterFourInsertedPuzzleModel.ts#L107)
1230. 新旧影像对齐
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:113](../src/modules/ChapterFourInsertedPuzzleModel.ts#L113)
1231. A3 · 302 媒体工作室
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:114](../src/modules/ChapterFourInsertedPuzzleModel.ts#L114)
1232. 旧影像的入口轮廓向右偏两格、向上一格，并顺时针转过四分之一圈。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:115](../src/modules/ChapterFourInsertedPuzzleModel.ts#L115)
1233. 平移并旋转胶片，让入口、楼梯与荣誉墙三个轮廓同时重合。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:116](../src/modules/ChapterFourInsertedPuzzleModel.ts#L116)
1234. 旧导视影像已与当前楼层坐标重合。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:117](../src/modules/ChapterFourInsertedPuzzleModel.ts#L117)
1235. 定位板校准
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:123](../src/modules/ChapterFourInsertedPuzzleModel.ts#L123)
1236. A2 · 201 创客工坊
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:124](../src/modules/ChapterFourInsertedPuzzleModel.ts#L124)
1237. 压力痕迹显示横向回退两格、纵向前推一格，第三档压力留下完整压印。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:125](../src/modules/ChapterFourInsertedPuzzleModel.ts#L125)
1238. 调整横向、纵向与压力，让三处触点同时落入旧痕。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:126](../src/modules/ChapterFourInsertedPuzzleModel.ts#L126)
1239. 定位板已完成三轴校准。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:127](../src/modules/ChapterFourInsertedPuzzleModel.ts#L127)
1240. 五区拓扑恢复
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:133](../src/modules/ChapterFourInsertedPuzzleModel.ts#L133)
1241. A2 · 203 计算机教室
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:134](../src/modules/ChapterFourInsertedPuzzleModel.ts#L134)
1242. 五区形成一个闭合环：大厅连两侧走廊，两侧分别接后区与教室区，末端再相连。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:135](../src/modules/ChapterFourInsertedPuzzleModel.ts#L135)
1243. 只保留停电前存在的五条相邻连线。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:136](../src/modules/ChapterFourInsertedPuzzleModel.ts#L136)
1244. 五区供电拓扑已恢复到停电前状态。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:137](../src/modules/ChapterFourInsertedPuzzleModel.ts#L137)
1245. 疏散路线确认
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:143](../src/modules/ChapterFourInsertedPuzzleModel.ts#L143)
1246. A2 · 开放自习区
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:144](../src/modules/ChapterFourInsertedPuzzleModel.ts#L144)
1247. 脚步残影从自习区进入东侧走廊，穿过教室门槛后在 202 出口消失。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:145](../src/modules/ChapterFourInsertedPuzzleModel.ts#L145)
1248. 按人流经过顺序排列四段路线卡。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:146](../src/modules/ChapterFourInsertedPuzzleModel.ts#L146)
1249. A2 夜间疏散路线已确认。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:147](../src/modules/ChapterFourInsertedPuzzleModel.ts#L147)
1250. 纸条抓取 {{facts.has("opening\_paper\_caught") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:147](../src/modules/ChapterFourStagePresentation.ts#L147)
1251. 时间核对 {{facts.has("external\_time\_rejected") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:149](../src/modules/ChapterFourStagePresentation.ts#L149)
1252. 旧钟检查 {{facts.has("hall\_clock\_inspected") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:151](../src/modules/ChapterFourStagePresentation.ts#L151)
1253. 旧时针流程 {{countFacts(facts, \[ "bakery\_conveyor\_lamp\_inspected", "bakery\_hour\_hand\_exposed", "bakery\_hour\_hand\_collected", "hour\_hand\_installed" \])}}/4
   来源：[src/modules/ChapterFourStagePresentation.ts:153](../src/modules/ChapterFourStagePresentation.ts#L153)
1254. 交通与参照 {{countFacts(facts, \[ "classroom\_104\_chalk\_residual\_observed", "classroom\_105\_terminal\_replay\_checked", "elevator\_history\_observed", "elevator\_history\_calibrated", "a3\_reference\_observed", "misaligned\_stair\_solved", "room204\_residual\_observed" \])}}/7 · 复原 {{countCompletedRoom204Groups( state.chapter4.room204Placements )}}/{{ROOM204\_GROUP\_ORDER.length}}
   来源：[src/modules/ChapterFourStagePresentation.ts:160](../src/modules/ChapterFourStagePresentation.ts#L160)
1255. 维修流程 {{countMaintenanceMilestones(facts)}}/3
   来源：[src/modules/ChapterFourStagePresentation.ts:172](../src/modules/ChapterFourStagePresentation.ts#L172)
1256. 必要灯区 {{progress.satisfied}}/{{progress.total}}
   来源：[src/modules/ChapterFourStagePresentation.ts:175](../src/modules/ChapterFourStagePresentation.ts#L175)
1257. 抵达 202 0/1
   来源：[src/modules/ChapterFourStagePresentation.ts:178](../src/modules/ChapterFourStagePresentation.ts#L178)
1258. 最后一分钟 {{facts.has("final\_minute\_recovered") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:180](../src/modules/ChapterFourStagePresentation.ts#L180)
1259. 返回旧钟 0/1
   来源：[src/modules/ChapterFourStagePresentation.ts:182](../src/modules/ChapterFourStagePresentation.ts#L182)
1260. 返回旧钟 1/1
   来源：[src/modules/ChapterFourStagePresentation.ts:182](../src/modules/ChapterFourStagePresentation.ts#L182)
1261. 签到确认 {{countFacts(facts, \["checkin\_card\_accepted", "checkin\_paper\_accepted"\])}}/2
   来源：[src/modules/ChapterFourStagePresentation.ts:184](../src/modules/ChapterFourStagePresentation.ts#L184)
1262. 收束确认 {{facts.has("exterior\_closure\_acknowledged") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:186](../src/modules/ChapterFourStagePresentation.ts#L186)
1263. 章节完成 1/1
   来源：[src/modules/ChapterFourStagePresentation.ts:188](../src/modules/ChapterFourStagePresentation.ts#L188)
1264. duplicate
   来源：[src/modules/ChapterFourTemporalMazeController.ts:361](../src/modules/ChapterFourTemporalMazeController.ts#L361)
1265. resolved
   来源：[src/modules/ChapterFourTemporalMazeController.ts:365](../src/modules/ChapterFourTemporalMazeController.ts#L365)
1266. failed
   来源：[src/modules/ChapterFourTemporalMazeController.ts:367](../src/modules/ChapterFourTemporalMazeController.ts#L367)
1267. accepted
   来源：[src/modules/ChapterFourTemporalMazeController.ts:824](../src/modules/ChapterFourTemporalMazeController.ts#L824)；[src/modules/ChapterFourTemporalMazeController.ts:833](../src/modules/ChapterFourTemporalMazeController.ts#L833)；[src/scenes/phone/P08_Settings/index.tsx:105](../src/scenes/phone/P08_Settings/index.tsx#L105)；[src/scenes/phone/P08_Settings/index.tsx:124](../src/scenes/phone/P08_Settings/index.tsx#L124)；[src/scenes/phone/P19_Clock/index.tsx:148](../src/scenes/phone/P19_Clock/index.tsx#L148)；[src/scenes/phone/P19_Clock/index.tsx:155](../src/scenes/phone/P19_Clock/index.tsx#L155)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7778](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7778)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7942](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7942)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7954](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7954)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7963](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7963)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7971](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7971)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8072](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8072)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8080](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8080)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8088](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8088)
1268. invalid\_request
   来源：[src/modules/ChapterFourTemporalMazeController.ts:2132](../src/modules/ChapterFourTemporalMazeController.ts#L2132)；[src/modules/ChapterFourTemporalMazeController.ts:2139](../src/modules/ChapterFourTemporalMazeController.ts#L2139)；[src/modules/ChapterFourTemporalMazeController.ts:2142](../src/modules/ChapterFourTemporalMazeController.ts#L2142)
1269. invalid\_intent
   来源：[src/modules/ChapterFourTemporalMazeController.ts:2145](../src/modules/ChapterFourTemporalMazeController.ts#L2145)；[src/modules/ChapterFourTemporalMazeController.ts:2149](../src/modules/ChapterFourTemporalMazeController.ts#L2149)
1270. 查看校园后勤服务的夜间运行通知
   来源：[src/modules/ChapterFourWechatModel.ts:80](../src/modules/ChapterFourWechatModel.ts#L80)
1271. 打开微信中的“校园后勤服务”公众号，保存段永平教学楼夜间运行提醒。
   来源：[src/modules/ChapterFourWechatModel.ts:81](../src/modules/ChapterFourWechatModel.ts#L81)
1272. 归档主电梯历史提示音
   来源：[src/modules/ChapterFourWechatModel.ts:87](../src/modules/ChapterFourWechatModel.ts#L87)
1273. 打开微信的文件传输助手，保存刚刚在深色观察中记录的电梯提示音。
   来源：[src/modules/ChapterFourWechatModel.ts:88](../src/modules/ChapterFourWechatModel.ts#L88)
1274. 从 CC98 导入学习天地资料索引
   来源：[src/modules/ChapterFourWechatModel.ts:97](../src/modules/ChapterFourWechatModel.ts#L97)
1275. 打开 CC98 的学习天地资料索引帖，选出课程年份、旧讨论和现场核验三项，再导入自习群。
   来源：[src/modules/ChapterFourWechatModel.ts:98](../src/modules/ChapterFourWechatModel.ts#L98)
1276. 保存麦斯威夜间自习群的路线讨论
   来源：[src/modules/ChapterFourWechatModel.ts:103](../src/modules/ChapterFourWechatModel.ts#L103)
1277. 打开微信学生群，保存包含东西两侧矛盾描述的群聊截图。
   来源：[src/modules/ChapterFourWechatModel.ts:104](../src/modules/ChapterFourWechatModel.ts#L104)
1278. 归档三楼新旧导视板照片
   来源：[src/modules/ChapterFourWechatModel.ts:112](../src/modules/ChapterFourWechatModel.ts#L112)
1279. 打开文件传输助手，将当前导视板和深色残影保存在同一组记录中。
   来源：[src/modules/ChapterFourWechatModel.ts:113](../src/modules/ChapterFourWechatModel.ts#L113)
1280. 请朋友对照新旧导视板
   来源：[src/modules/ChapterFourWechatModel.ts:119](../src/modules/ChapterFourWechatModel.ts#L119)
1281. 在微信朋友聊天中对照两张照片，记下二楼箭头的方向差异。
   来源：[src/modules/ChapterFourWechatModel.ts:120](../src/modules/ChapterFourWechatModel.ts#L120)
1282. already\_complete
   来源：[src/scenes/phone/P08_Settings/index.tsx:105](../src/scenes/phone/P08_Settings/index.tsx#L105)；[src/scenes/phone/P08_Settings/index.tsx:124](../src/scenes/phone/P08_Settings/index.tsx#L124)
1283. 旧桌面排布已核对，辅助记录已保存。
   来源：[src/scenes/phone/P08_Settings/index.tsx:106](../src/scenes/phone/P08_Settings/index.tsx#L106)
1284. incorrect
   来源：[src/scenes/phone/P08_Settings/index.tsx:107](../src/scenes/phone/P08_Settings/index.tsx#L107)；[src/scenes/phone/P08_Settings/index.tsx:126](../src/scenes/phone/P08_Settings/index.tsx#L126)
1285. 第一排仍不对。旧截图从左到右是微信、浙大钉、照片、CC98。
   来源：[src/scenes/phone/P08_Settings/index.tsx:108](../src/scenes/phone/P08_Settings/index.tsx#L108)
1286. 进入第四章后才能核对这张旧桌面截图。
   来源：[src/scenes/phone/P08_Settings/index.tsx:109](../src/scenes/phone/P08_Settings/index.tsx#L109)
1287. 三条 07:55 异常记录已归档。照片索引、时钟唤醒和 A2 定位共用同一时刻。
   来源：[src/scenes/phone/P08_Settings/index.tsx:125](../src/scenes/phone/P08_Settings/index.tsx#L125)
1288. 记录还混着正常刷新。只保留同时发生在 07:55 的三条异常活动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:127](../src/scenes/phone/P08_Settings/index.tsx#L127)
1289. 第四章尚未开始，这里只有普通后台记录。
   来源：[src/scenes/phone/P08_Settings/index.tsx:128](../src/scenes/phone/P08_Settings/index.tsx#L128)
1290. 打开控制中心切换网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1291. 当前网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1292. 等待校园网
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1293. 可访问
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1294. 离线
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1295. 校园网络与移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1296. 移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1297. 背景音乐
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1298. 开启
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1299. 声音与振动
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1300. 语音与操作音效保持开启
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1301. 微信
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:439](../src/scenes/phone/P13_PhoneHome/index.tsx#L439)；[src/scenes/phone/P13_PhoneHome/index.tsx:442](../src/scenes/phone/P13_PhoneHome/index.tsx#L442)；[src/scenes/phone/P13_PhoneHome/index.tsx:798](../src/scenes/phone/P13_PhoneHome/index.tsx#L798)
1302. 微信，待处理：{{chapterFourWechatObjective.label}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:442](../src/scenes/phone/P13_PhoneHome/index.tsx#L442)
1303. 浙大体艺
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:447](../src/scenes/phone/P13_PhoneHome/index.tsx#L447)
1304. 浙大钉
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:453](../src/scenes/phone/P13_PhoneHome/index.tsx#L453)
1305. CC98
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:497](../src/scenes/phone/P13_PhoneHome/index.tsx#L497)；[src/scenes/phone/P13_PhoneHome/index.tsx:500](../src/scenes/phone/P13_PhoneHome/index.tsx#L500)
1306. CC98，待处理：{{chapterFourWechatObjective?.label ?? "学习天地资料索引"}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:500](../src/scenes/phone/P13_PhoneHome/index.tsx#L500)
1307. 控制中心
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:505](../src/scenes/phone/P13_PhoneHome/index.tsx#L505)
1308. 时钟
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:514](../src/scenes/phone/P13_PhoneHome/index.tsx#L514)
1309. 新增照片「看不清的书脊」
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:778](../src/scenes/phone/P13_PhoneHome/index.tsx#L778)
1310. 照片
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:778](../src/scenes/phone/P13_PhoneHome/index.tsx#L778)；[src/scenes/phone/P13_PhoneHome/index.tsx:804](../src/scenes/phone/P13_PhoneHome/index.tsx#L804)
1311. 打开 CC98 学习天地资料索引帖
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:789](../src/scenes/phone/P13_PhoneHome/index.tsx#L789)
1312. 课程年份入口与旧自习讨论待导入
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:792](../src/scenes/phone/P13_PhoneHome/index.tsx#L792)
1313. CC98 · 学习天地
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:792](../src/scenes/phone/P13_PhoneHome/index.tsx#L792)
1314. IMG\_0755 的识别结果仍需现场核验
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:804](../src/scenes/phone/P13_PhoneHome/index.tsx#L804)
1315. 这份资料已经保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:447](../src/scenes/phone/P14_Wechat/index.tsx#L447)
1316. 夜间运行通知已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:456](../src/scenes/phone/P14_Wechat/index.tsx#L456)
1317. 第四章开始后才能查看这条运行通知。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:457](../src/scenes/phone/P14_Wechat/index.tsx#L457)
1318. 主电梯提示音已归档。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:464](../src/scenes/phone/P14_Wechat/index.tsx#L464)
1319. 文件传输助手尚未收到一楼电梯历史提示音记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:465](../src/scenes/phone/P14_Wechat/index.tsx#L465)
1320. 路线讨论已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:472](../src/scenes/phone/P14_Wechat/index.tsx#L472)
1321. 先去 CC98 学习天地，把课程年份入口、旧讨论和现场核验三项导入群文件。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:474](../src/scenes/phone/P14_Wechat/index.tsx#L474)
1322. 先阅读公众号通知，并抵达二楼清楼阶段。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:475](../src/scenes/phone/P14_Wechat/index.tsx#L475)
1323. 新旧导视板照片已归档。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:482](../src/scenes/phone/P14_Wechat/index.tsx#L482)
1324. 文件传输助手尚未收到三楼旧导视板残影记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:483](../src/scenes/phone/P14_Wechat/index.tsx#L483)
1325. 照片对照完成。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:490](../src/scenes/phone/P14_Wechat/index.tsx#L490)
1326. 先把三楼新旧导视板照片保存到文件传输助手。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:491](../src/scenes/phone/P14_Wechat/index.tsx#L491)
1327. 朋友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:638](../src/scenes/phone/P14_Wechat/index.tsx#L638)
1328. 返回公众号主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1329. 返回聊天列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1330. official
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1331. 麦斯威夜间自习群聊天记录
   来源：[src/scenes/phone/P14_Wechat/index.tsx:657](../src/scenes/phone/P14_Wechat/index.tsx#L657)
1332. 22:47 ·
   来源：[src/scenes/phone/P14_Wechat/index.tsx:658](../src/scenes/phone/P14_Wechat/index.tsx#L658)
1333. 人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:658](../src/scenes/phone/P14_Wechat/index.tsx#L658)
1334. 路线讨论已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:685](../src/scenes/phone/P14_Wechat/index.tsx#L685)
1335. 第四章现场资料
   来源：[src/scenes/phone/P14_Wechat/index.tsx:690](../src/scenes/phone/P14_Wechat/index.tsx#L690)
1336. 公众号推送 · 22:40
   来源：[src/scenes/phone/P14_Wechat/index.tsx:693](../src/scenes/phone/P14_Wechat/index.tsx#L693)
1337. 已读
   来源：[src/scenes/phone/P14_Wechat/index.tsx:693](../src/scenes/phone/P14_Wechat/index.tsx#L693)
1338. 群文件 · 学习天地
   来源：[src/scenes/phone/P14_Wechat/index.tsx:697](../src/scenes/phone/P14_Wechat/index.tsx#L697)
1339. 课程年份入口与旧自习讨论
   来源：[src/scenes/phone/P14_Wechat/index.tsx:698](../src/scenes/phone/P14_Wechat/index.tsx#L698)
1340. 已从 CC98 导入
   来源：[src/scenes/phone/P14_Wechat/index.tsx:699](../src/scenes/phone/P14_Wechat/index.tsx#L699)
1341. 现场录音 · 1F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:704](../src/scenes/phone/P14_Wechat/index.tsx#L704)
1342. 保存照片
   来源：[src/scenes/phone/P14_Wechat/index.tsx:714](../src/scenes/phone/P14_Wechat/index.tsx#L714)
1343. 已归档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:714](../src/scenes/phone/P14_Wechat/index.tsx#L714)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6685](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6685)
1344. 朋友导视板对照聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:720](../src/scenes/phone/P14_Wechat/index.tsx#L720)
1345. 新旧导视板照片
   来源：[src/scenes/phone/P14_Wechat/index.tsx:725](../src/scenes/phone/P14_Wechat/index.tsx#L725)
1346. 2F →
   来源：[src/scenes/phone/P14_Wechat/index.tsx:726](../src/scenes/phone/P14_Wechat/index.tsx#L726)
1347. 当前导视
   来源：[src/scenes/phone/P14_Wechat/index.tsx:726](../src/scenes/phone/P14_Wechat/index.tsx#L726)
1348. ← 2F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:727](../src/scenes/phone/P14_Wechat/index.tsx#L727)
1349. 历史残影
   来源：[src/scenes/phone/P14_Wechat/index.tsx:727](../src/scenes/phone/P14_Wechat/index.tsx#L727)
1350. 照片已完成对照
   来源：[src/scenes/phone/P14_Wechat/index.tsx:730](../src/scenes/phone/P14_Wechat/index.tsx#L730)
1351. {{label}} −
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:377](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L377)
1352. {{label}} +
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:387](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L387)
1353. {{strings.assemble}} / {{strings.explode}}
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:511](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L511)
1354. 系统
   来源：[src/scenes/phone/P19_Clock/index.tsx:29](../src/scenes/phone/P19_Clock/index.tsx#L29)
1355. 玩家
   来源：[src/scenes/phone/P19_Clock/index.tsx:31](../src/scenes/phone/P19_Clock/index.tsx#L31)
1356. 我
   来源：[src/scenes/phone/P19_Clock/index.tsx:31](../src/scenes/phone/P19_Clock/index.tsx#L31)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:70](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L70)
1357. {{currentRound.label}}协议通过，进入下一轮。
   来源：[src/scenes/phone/P19_Clock/index.tsx:103](../src/scenes/phone/P19_Clock/index.tsx#L103)
1358. 这条记录属于其他场景，无法写入 B2-04 档案。
   来源：[src/scenes/phone/P19_Clock/index.tsx:133](../src/scenes/phone/P19_Clock/index.tsx#L133)
1359. {{unit === "hour" ? "小时" : "分钟"}}机芯已锁定。
   来源：[src/scenes/phone/P19_Clock/index.tsx:148](../src/scenes/phone/P19_Clock/index.tsx#L148)
1360. {{channel.label}}漂移已归零。
   来源：[src/scenes/phone/P19_Clock/index.tsx:155](../src/scenes/phone/P19_Clock/index.tsx#L155)
1361. 返回手机主页
   来源：[src/scenes/phone/P19_Clock/index.tsx:166](../src/scenes/phone/P19_Clock/index.tsx#L166)；[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)；[src/scenes/rpg/RpgGameHost.tsx:2448](../src/scenes/rpg/RpgGameHost.tsx#L2448)
1362. B2-04 / TIME REPAIR
   来源：[src/scenes/phone/P19_Clock/index.tsx:167](../src/scenes/phone/P19_Clock/index.tsx#L167)
1363. 校时状态
   来源：[src/scenes/phone/P19_Clock/index.tsx:171](../src/scenes/phone/P19_Clock/index.tsx#L171)
1364. 四关校时流程
   来源：[src/scenes/phone/P19_Clock/index.tsx:175](../src/scenes/phone/P19_Clock/index.tsx#L175)
1365. 返回当前任务
   来源：[src/scenes/phone/P19_Clock/index.tsx:179](../src/scenes/phone/P19_Clock/index.tsx#L179)
1366. ACCESS DENIED
   来源：[src/scenes/phone/P19_Clock/index.tsx:179](../src/scenes/phone/P19_Clock/index.tsx#L179)
1367. /3 证据
   来源：[src/scenes/phone/P19_Clock/index.tsx:182](../src/scenes/phone/P19_Clock/index.tsx#L182)
1368. 01 / ARCHIVE REBUILD
   来源：[src/scenes/phone/P19_Clock/index.tsx:182](../src/scenes/phone/P19_Clock/index.tsx#L182)
1369. 提交档案与时刻
   来源：[src/scenes/phone/P19_Clock/index.tsx:189](../src/scenes/phone/P19_Clock/index.tsx#L189)
1370. /2 LOCKED
   来源：[src/scenes/phone/P19_Clock/index.tsx:193](../src/scenes/phone/P19_Clock/index.tsx#L193)
1371. 02 / DUAL MOVEMENT
   来源：[src/scenes/phone/P19_Clock/index.tsx:193](../src/scenes/phone/P19_Clock/index.tsx#L193)
1372. 00 分机芯
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1373. 08 时机芯
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1374. 23 秒暂存
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1375. 进入漂移核对
   来源：[src/scenes/phone/P19_Clock/index.tsx:205](../src/scenes/phone/P19_Clock/index.tsx#L205)
1376. /3 ONLINE
   来源：[src/scenes/phone/P19_Clock/index.tsx:209](../src/scenes/phone/P19_Clock/index.tsx#L209)
1377. 03 / DRIFT MATRIX
   来源：[src/scenes/phone/P19_Clock/index.tsx:209](../src/scenes/phone/P19_Clock/index.tsx#L209)
1378. 已归零
   来源：[src/scenes/phone/P19_Clock/index.tsx:213](../src/scenes/phone/P19_Clock/index.tsx#L213)
1379. 应用反向修正
   来源：[src/scenes/phone/P19_Clock/index.tsx:213](../src/scenes/phone/P19_Clock/index.tsx#L213)
1380. 生成 08:00:00
   来源：[src/scenes/phone/P19_Clock/index.tsx:215](../src/scenes/phone/P19_Clock/index.tsx#L215)
1381. 04 / THREE PROTOCOLS
   来源：[src/scenes/phone/P19_Clock/index.tsx:219](../src/scenes/phone/P19_Clock/index.tsx#L219)
1382. 执行本轮放行
   来源：[src/scenes/phone/P19_Clock/index.tsx:224](../src/scenes/phone/P19_Clock/index.tsx#L224)
1383. 放行尝试
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1384. 漂移尝试
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1385. 四关校时
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1386. TIME AXIS / RELEASED
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1387. P01 起床
   来源：[src/scenes/phone/registry.tsx:27](../src/scenes/phone/registry.tsx#L27)
1388. 再睡5分钟 → 旁白 → 起床蠢货！！！ → 手机主界面。
   来源：[src/scenes/phone/registry.tsx:28](../src/scenes/phone/registry.tsx#L28)
1389. P13 手机主界面
   来源：[src/scenes/phone/registry.tsx:31](../src/scenes/phone/registry.tsx#L31)
1390. 主屏：设置齿轮/塔楼钥匙孔/天气水滴/盆栽入口/微信弹窗。
   来源：[src/scenes/phone/registry.tsx:32](../src/scenes/phone/registry.tsx#L32)
1391. P08 设置
   来源：[src/scenes/phone/registry.tsx:35](../src/scenes/phone/registry.tsx#L35)
1392. 真实系统设置、桌面编排、可选应用恢复与第四章后台活动取证。
   来源：[src/scenes/phone/registry.tsx:36](../src/scenes/phone/registry.tsx#L36)
1393. P14 微信
   来源：[src/scenes/phone/registry.tsx:39](../src/scenes/phone/registry.tsx#L39)
1394. 朋友聊天触发小影散码；列表中朋友头像藏斜线谜题（P03）。
   来源：[src/scenes/phone/registry.tsx:40](../src/scenes/phone/registry.tsx#L40)
1395. P02 CC98
   来源：[src/scenes/phone/registry.tsx:43](../src/scenes/phone/registry.tsx#L43)
1396. 仅校园网可进入；热门话题列表与剧情帖子记录跟随游戏进度。
   来源：[src/scenes/phone/registry.tsx:44](../src/scenes/phone/registry.tsx#L44)
1397. P15 浙大钉
   来源：[src/scenes/phone/registry.tsx:47](../src/scenes/phone/registry.tsx#L47)
1398. 仅校园网可进入；承载系统入口、图书馆预约和移动图书馆证据流程。
   来源：[src/scenes/phone/registry.tsx:48](../src/scenes/phone/registry.tsx#L48)
1399. P06 浙大体艺
   来源：[src/scenes/phone/registry.tsx:51](../src/scenes/phone/registry.tsx#L51)
1400. 仅流量可进入；先开启课外锻炼，图书馆阶段再核对 7 / 47 / 3 到馆材料。
   来源：[src/scenes/phone/registry.tsx:52](../src/scenes/phone/registry.tsx#L52)
1401. 准备离开教学楼的学生像素立绘
   来源：[src/scenes/rpg/chapter4-prologue/ProloguePortraitAssets.ts:13](../src/scenes/rpg/chapter4-prologue/ProloguePortraitAssets.ts#L13)
1402. 迈斯威 →
   来源：[src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts:1365](../src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts#L1365)
1403. 旁白
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:78](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L78)
1404. 保洁员
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:86](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L86)
1405. 第四章序幕：纸条进入段永平教学楼
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:641](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L641)
1406. 夜色中，湿纸条离开启真湖，经过街机厅进入段永平教学楼，沿大厅进入熄灯后的走廊
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:664](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L664)
1407. 由四项手机证据恢复的现场回放
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:667](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L667)
1408. RECOVERED TIMELINE
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:668](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L668)
1409. SOURCE 4 / 4
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:669](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L669)
1410. 跳过恢复回放
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:674](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L674)
1411. CHAPTER 03.5 · COMPLETE
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:701](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L701)
1412. 第四章：时间迷宫
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:702](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L702)
1413. 现场定位
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:705](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L705)
1414. 段永平教学楼玻璃门
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:706](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L706)
1415. 追踪进入教学楼的异常签到纸
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:710](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L710)
1416. 正在提交任务……
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:724](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L724)
1417. 正在同步教学楼现场……
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:726](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L726)
1418. 重试进入第四章
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:728](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L728)
1419. 收下任务，进入第四章
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:729](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L729)
1420. 重播过场
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:736](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L736)
1421. 楼梯的空间关系发生错位。
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:87](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L87)
1422. B2 已接通
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:220](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L220)
1423. 空格键 记录下层回声
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:222](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L222)
1424. 下层回声已记录
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:222](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L222)
1425. 端点已对齐 · 空格键通过
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:224](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L224)
1426. A / ← 左转 · D / → 右转 · 让两端发光后通过
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:225](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L225)
1427. 错位折返楼梯
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:269](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L269)
1428. A1 入口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:180](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L180)
1429. 电梯与楼层
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:181](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L181)
1430. 维修与追逐
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:182](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L182)
1431. 收束场景
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:183](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L183)
1432. A1 · 麦思威面包坊与门厅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:741](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L741)
1433. A2 · 教室与开放学习区
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:742](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L742)
1434. A3 · 校友荣誉门厅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:743](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L743)
1435. 楼梯上行口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1017](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1017)
1436. 楼梯下行口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1017](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1017)
1437. up
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1017](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1017)
1438. unknown
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1627](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1627)
1439. 资料依据：{{figure.sourceLabel}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2097](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2097)
1440. Space / Enter · 返回 Esc · 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2124](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2124)
1441. 返回地图
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2130](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2130)
1442. {{CHAPTER\_FOUR\_WARMUP\_PHASE\_LABELS\[failedPhase\]}}资源准备失败（{{failedCount}} 项）· R 重试
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2296](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2296)
1443. 进度已恢复，请重试当前操作。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:3523](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L3523)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5602](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5602)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7354](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7354)
1444. 校园卡
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4864](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4864)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4887](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4887)；[src/scenes/rpg/RpgGameHost.tsx:2519](../src/scenes/rpg/RpgGameHost.tsx#L2519)
1445. 纸条
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4870](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4870)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4895](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4895)
1446. 已刷卡
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4887](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4887)
1447. 已签到
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4895](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4895)
1448. chase.close
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5283](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5283)
1449. 保安
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:94](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L94)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5285](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5285)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5307](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5307)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5494](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5494)
1450. chase.floor\_changed
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5305](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5305)
1451. 202 门已关闭
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5374](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5374)
1452. maintenance.cleaner
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5485](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5485)
1453. chase.started
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5492](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5492)
1454. morning.entry
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5500](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5500)
1455. exterior.closure
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5507](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5507)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8096](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8096)
1456. 07:55 残影投影
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5562](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5562)
1457. 校准中……
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5568](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5568)
1458. 偏移·3px
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5581](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5581)
1459. Space · 按{{ROOM204\_GROUPS\[nearbyGroupId\].label}}复原一组桌椅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5904](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5904)
1460. 当前为深色观察；{{ROOM204\_GROUPS\[nearbyGroupId\].label}}需在浅色操作中复原
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5905](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5905)
1461. Space · 把已搬起的桌椅放到残影槽位
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5912](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5912)
1462. Space · 搬动一组桌椅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5919](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5919)
1463. 当前为深色观察；搬动桌椅需要浅色操作
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5920](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5920)
1464. 先搬一组桌椅，再放到残影槽位。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5929](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5929)
1465. 搬动桌椅需要浅色操作；当前仍可查看残影槽位。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5930](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5930)
1466. Space · 查看{{this.nearbyAlumniFigure.name}}生平
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5943](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5943)
1467. 把对应道具拖到{{this.nearbyStoryTarget.contract.label}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5951](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5951)
1468. 切到浅色操作后再搬动桌椅。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6028](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6028)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6077](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6077)
1469. 先搬一组桌椅，再放到对应残影位置。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6085](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6085)
1470. 请从道具栏拖动道具到{{storyTarget.contract.label}}。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6339](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6339)
1471. final\_chase
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6354](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6354)
1472. 追逐中电梯已锁，请进入主楼梯。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6355](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6355)
1473. 返程只能沿主楼梯回到一楼旧钟。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6356](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6356)
1474. 当前可继续观察；轿厢重放校准需要浅色操作。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6368](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6368)
1475. 电梯的历史片段只保留上行记录。请从三楼主楼梯返回二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6375](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6375)
1476. 先在三楼晨间教室记录桌椅、入口与投影边界。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6387](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6387)
1477. A 楼主电梯
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6440](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6440)
1478. 18:50 运行复核
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6443](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6443)
1479. ↑↓ 选层 · Enter 执行 · Space 复核 · Esc 离开
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6509](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6509)
1480. 同步电梯历史
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6536](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6536)
1481. 让一楼开门记录完整覆盖人物的六秒进入窗口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6539](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6539)
1482. 重放校准
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6553](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6553)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6563](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6563)
1483. −1 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6562](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6562)
1484. +1 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6564](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6564)
1485. ←/→ 调整 · Enter 重放 · Esc 离开
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6565](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6565)
1486. 蓝色 门体开放 {{formatClock(doorStart)}}—{{formatClock(doorEnd)}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6613](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6613)
1487. 黄色 人物进入 {{formatClock(playerStart)}}—{{formatClock(playerEnd)}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6614](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6614)
1488. 白线 轿厢开始上行
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6615](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6615)
1489. 重放失败：门体没有覆盖完整进入窗口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6615](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6615)
1490. 当前层
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6683](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6683)
1491. 可直达
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6687](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6687)
1492. 楼梯绕行
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6688](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6688)
1493. 跨层档案 {{recordCount}}/3{{chainSolved ? " · 已复核" : ""}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6698](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6698)
1494. □ 一楼记录来自门外三条时间轨。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6708](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6708)
1495. 离开轿厢后切到深色观察，在门前完成记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6708](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6708)
1496. □ 本层门机日志尚未归档。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6710](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6710)
1497. 当前可直接读取，记录后不会限制其他楼层的调查顺序。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6711](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6711)
1498. 离开轿厢切到深色观察，再进入电梯读取本层记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6712](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6712)
1499. □ 到达该层后可读取门机记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6714](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6714)
1500. 线索归档顺序不影响楼层通行。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6714](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6714)
1501. □ 轿厢没有该层的历史开门记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6715](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6715)
1502. 先乘到三楼，再从主楼梯完成空间校准并进入二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6715](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6715)
1503. 本层记录已归档
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6719](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6719)
1504. 离开轿厢读取一楼门体轨
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6721](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6721)
1505. 读取{{record.recordTitle}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6723](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6723)
1506. 需切换深色观察
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6724](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6724)
1507. 前往 {{record.displayFloor}}F
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6726](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6726)
1508. 查看主楼梯绕行说明
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6727](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6727)
1509. 停靠链已复核
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6734](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6734)
1510. 复核停靠链
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6736](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6736)
1511. 运行复核 {{recordCount}}/3
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6737](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6737)
1512. 二楼没有历史开门记录。先到三楼完成荣誉墙与影像调查，再从主楼梯校准空间并进入二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6750](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6750)
1513. {{record.displayFloor}}F {{record.recordTitle}}已经归档。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6757](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6757)
1514. 一楼起行记录位于电梯门外。离开轿厢后切到深色观察，在门前读取三条时间轨。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6761](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6761)
1515. 门机旧记录只在深色观察中可读。离开轿厢切换模式后再进入电梯。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6766](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6766)
1516. 停靠链已复核：1F 起行，轿厢越过 2F 后在 3F 到站；2F 外呼未得到响应。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6779](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6779)
1517. 还缺 {{3 - chapterFourElevatorCollectedRecordCount(state.chapter4.factIds)}} 段楼层记录。三段可按任意顺序归档。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6783](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6783)
1518. 记录已经齐全。离开轿厢切回浅色操作，再打开面板完成运行复核。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6787](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6787)
1519. 复原 18:50 停靠链
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6798](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6798)
1520. 3/3 记录齐全
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6801](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6801)
1521. 门开八秒；18:50:06 转为上行
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6806](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6806)
1522. 下行外呼亮起；门机没有开门记录
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6807](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6807)
1523. 到站铃响；随后门机完整开启
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6808](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6808)
1524. 轿厢离开 1F 后实际到站：
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6837](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6837)
1525. 有外呼但未得到开门响应：
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6840](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6840)
1526. 提交运行复核
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6880](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6880)
1527. ←→ 选择实际到站 · ↑↓ 选择未响应层 · Enter 提交 · Esc 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6883](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6883)
1528. 比较三段记录，再分别确认实际到站层和未响应外呼层。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6937](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6937)
1529. 二楼外呼存在，但轿厢没有开门记录。先乘到三楼，再从错位主楼梯进入二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6982](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6982)
1530. 当前已在 {{targetFloor}}F
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6986](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6986)
1531. 拨钟操作已取消，旧钟和纸条均已恢复，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7116](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7116)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7149](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7149)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7164](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7164)
1532. 最终拨钟条件尚未满足，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7209](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7209)
1533. 时间校准至 07:54。纸条带走了最后一分钟。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7254](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7254)
1534. 传送带停机确认超时，已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7546](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7546)
1535. 07:55 残影投影确认超时，已回到已完成的教室布局，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7552](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7552)
1536. 最终拨钟确认超时，已恢复转动的旧钟和签到纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7559](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7559)
1537. 当前楼层状态已经同步。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7625](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7625)
1538. 请切回浅色操作后再移动。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7626](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7626)
1539. 当前剧情阶段没有开放这条楼层通道。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7627](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7627)
1540. 当前无法前往该楼层。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7628](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7628)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7633](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7633)
1541. 当前剧情条件尚未满足。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7652](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7652)；[src/scenes/rpg/RpgGameHost.tsx:386](../src/scenes/rpg/RpgGameHost.tsx#L386)
1542. 门体开放区间未完整覆盖六秒进入窗口。调整重放起点后再试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7656](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7656)
1543. 复核不一致：重新比较二楼外呼与三楼门机时间。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7662](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7662)
1544. 实际到站层与未响应外呼层不能互换。重新比较三段记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7664](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7664)
1545. {{detail}}已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7678](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7678)
1546. {{detail}}已回到已完成的教室布局，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7684](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7684)
1547. {{detail}}已恢复转动的旧钟和签到纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7691](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7691)
1548. oldClockHourHand
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7700](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7700)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7777](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7777)
1549. finalMinute
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7704](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7704)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8071](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8071)
1550. campusCard
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7708](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7708)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8079](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8079)；[src/scenes/rpg/RpgGameHost.tsx:2518](../src/scenes/rpg/RpgGameHost.tsx#L2518)
1551. attendanceRecordPaper
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7712](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7712)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8087](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8087)
1552. shortPryBar
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7716](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7716)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7954](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7954)
1553. universalLubricatingOil
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7721](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7721)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7962](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7962)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7970](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7970)
1554. 传送带停机结果缺少已提交记录，已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7762](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7762)
1555. 金属时针已装回旧钟，时间已切换到 18:50。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7779](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7779)
1556. 当前教室没有新增状态记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7830](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7830)
1557. classroom104.chalk\_residual
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7844](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7844)
1558. classroom105.terminal\_replay
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7852](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7852)
1559. 已记录门体开放、人物进入和轿厢上行三条时间轨。轿厢重放校准可独立在浅色操作中完成。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7860](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7860)
1560. {{record.displayFloor}}F {{record.recordTitle}}已归档。{{record.evidence\[0\]}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7877](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7877)
1561. 三层运行记录已经齐全。切回浅色操作后，可在面板中复核停靠链。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7882](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7882)
1562. 跨层运行链已复核：轿厢从一楼直达三楼，二楼外呼没有得到开门响应。定位片的楼层基准已确认。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7891](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7891)
1563. room204.a3\_reference\_recorded
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7899](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7899)
1564. room204.residual\_recorded
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7907](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7907)
1565. 已复原 {{Math.floor(normalizeRoom204Placements( this.bridge.getState().chapter4.room204Placements ).length / 3)}}/{{ROOM204\_GROUP\_ORDER.length}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7917](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7917)
1566. 07:55 投影结果缺少已提交记录，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7927](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7927)
1567. clockPositioningPlate
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7941](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7941)
1568. 定位盘已装回旧钟，现在线索转入 22:45 维护时段。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7943](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7943)
1569. 轮罩已打开，短撬棍完成了最后一次用途。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7954](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7954)
1570. 保洁车轮已修好，瓶里还剩一半润滑油。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7964](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7964)
1571. 旧钟齿轮已恢复转动。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7972](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7972)
1572. 已回到大厅安全点。维修进度和道具均已保留。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7985](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7985)
1573. 偷走最后一分钟的提交不完整，已恢复旧钟和纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8003](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8003)
1574. chase.retry
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8048](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8048)
1575. lecture.recovered\_result
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8058](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8058)
1576. 最后一分钟已装回旧钟。时间已恢复到 07:55。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8073](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8073)
1577. 校园卡已通过签到校验。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8081](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8081)
1578. 签到记录已提交。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8089](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8089)
1579. 外部现场
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8312](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8312)
1580. 手机状态栏 · 冻结
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8322](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8322)
1581. 不可信
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8328](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8328)
1582. 外部时间与手机冻结时间冲突 · 签到提交已拒绝
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8331](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8331)
1583. 旧钟停在 22:45。表盘能被拨动，但响应方向和幅度都不对。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8357](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8357)
1584. 旧钟停在 12:25。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8439](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8439)
1585. 无法使用该道具。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8625](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8625)
1586. invalid\_item
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8626](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8626)
1587. 未命中有效目标。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8633](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8633)
1588. missed\_target
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8633](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8633)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8646](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8646)
1589. 未命中当前阶段的可见道具目标。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8646](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8646)
1590. {{target.contract.label}}需要另一件道具。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8651](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8651)
1591. wrong\_item
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8651](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8651)
1592. 交互失败，请重新靠近目标后重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8768](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8768)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8772](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8772)；[src/scenes/rpg/RpgGameHost.tsx:1135](../src/scenes/rpg/RpgGameHost.tsx#L1135)
1593. locked
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8768](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8768)
1594. 当前目标需要另一件道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:382](../src/scenes/rpg/RpgGameHost.tsx#L382)
1595. 距离目标太远，请靠近可见交互区域。
   来源：[src/scenes/rpg/RpgGameHost.tsx:383](../src/scenes/rpg/RpgGameHost.tsx#L383)
1596. 当前组合与已记录的线索不一致。
   来源：[src/scenes/rpg/RpgGameHost.tsx:384](../src/scenes/rpg/RpgGameHost.tsx#L384)
1597. 先在三楼晨间教室记录桌椅与入口位置，再进入空间校准。
   来源：[src/scenes/rpg/RpgGameHost.tsx:605](../src/scenes/rpg/RpgGameHost.tsx#L605)
1598. 当前组合与现场痕迹不一致，可以继续调整。
   来源：[src/scenes/rpg/RpgGameHost.tsx:651](../src/scenes/rpg/RpgGameHost.tsx#L651)
1599. 正在写入二楼到达记录…
   来源：[src/scenes/rpg/RpgGameHost.tsx:710](../src/scenes/rpg/RpgGameHost.tsx#L710)
1600. 楼梯校准结果未能写入，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:728](../src/scenes/rpg/RpgGameHost.tsx#L728)
1601. 两层错位楼梯已连通。已从三楼抵达二楼，204 教室恢复流程开放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:734](../src/scenes/rpg/RpgGameHost.tsx#L734)
1602. 回答未保存，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:830](../src/scenes/rpg/RpgGameHost.tsx#L830)
1603. 灯光收束未完成，正在重新播放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:867](../src/scenes/rpg/RpgGameHost.tsx#L867)
1604. 灯光收束确认未写入，已重新播放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:898](../src/scenes/rpg/RpgGameHost.tsx#L898)
1605. 教学楼交互请求缺少有效编号或包含多余字段。请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1160](../src/scenes/rpg/RpgGameHost.tsx#L1160)
1606. 当前教学楼交互请求无效。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1161](../src/scenes/rpg/RpgGameHost.tsx#L1161)
1607. 这次教学楼交互已经处理，未重复写入。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1167](../src/scenes/rpg/RpgGameHost.tsx#L1167)；[src/scenes/rpg/RpgGameHost.tsx:1253](../src/scenes/rpg/RpgGameHost.tsx#L1253)
1608. 第四章序幕交接仅由 App gate 提交。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1174](../src/scenes/rpg/RpgGameHost.tsx#L1174)
1609. 当前交互位置无法由活动场景重新确认，请靠近可见目标后重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1201](../src/scenes/rpg/RpgGameHost.tsx#L1201)
1610. 无目标交互不得携带运行时几何。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1244](../src/scenes/rpg/RpgGameHost.tsx#L1244)
1611. 教学楼交互处理失败，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1257](../src/scenes/rpg/RpgGameHost.tsx#L1257)
1612. 配电请求未被接受，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1328](../src/scenes/rpg/RpgGameHost.tsx#L1328)
1613. 区域供电状态已同步。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1337](../src/scenes/rpg/RpgGameHost.tsx#L1337)
1614. 三项判断中仍有矛盾，请重新核对现场现象。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1387](../src/scenes/rpg/RpgGameHost.tsx#L1387)
1615. 7:55 RPG runtime
   来源：[src/scenes/rpg/RpgGameHost.tsx:2294](../src/scenes/rpg/RpgGameHost.tsx#L2294)
1616. 7:55 横屏游戏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2312](../src/scenes/rpg/RpgGameHost.tsx#L2312)
1617. 聚焦手机
   来源：[src/scenes/rpg/RpgGameHost.tsx:2448](../src/scenes/rpg/RpgGameHost.tsx#L2448)
1618. 全屏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2449](../src/scenes/rpg/RpgGameHost.tsx#L2449)
1619. 地图视角
   来源：[src/scenes/rpg/RpgGameHost.tsx:2454](../src/scenes/rpg/RpgGameHost.tsx#L2454)
1620. 定位人物
   来源：[src/scenes/rpg/RpgGameHost.tsx:2455](../src/scenes/rpg/RpgGameHost.tsx#L2455)
1621. 放大地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2456](../src/scenes/rpg/RpgGameHost.tsx#L2456)
1622. 缩小地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2457](../src/scenes/rpg/RpgGameHost.tsx#L2457)
1623. 地图物品栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2507](../src/scenes/rpg/RpgGameHost.tsx#L2507)
1624. 物品栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2508](../src/scenes/rpg/RpgGameHost.tsx#L2508)
1625. 查看电子校园卡
   来源：[src/scenes/rpg/RpgGameHost.tsx:2513](../src/scenes/rpg/RpgGameHost.tsx#L2513)
1626. 单击查看校园卡信息，双击查看完整详情
   来源：[src/scenes/rpg/RpgGameHost.tsx:2514](../src/scenes/rpg/RpgGameHost.tsx#L2514)
1627. 已连接
   来源：[src/scenes/rpg/RpgGameHost.tsx:2539](../src/scenes/rpg/RpgGameHost.tsx#L2539)
1628. 待登记姓名
   来源：[src/scenes/rpg/RpgGameHost.tsx:2541](../src/scenes/rpg/RpgGameHost.tsx#L2541)
1629. 待开始锻炼
   来源：[src/scenes/rpg/RpgGameHost.tsx:2542](../src/scenes/rpg/RpgGameHost.tsx#L2542)
1630. 节奏钓鱼 A 左收线、S 提竿、D 右收线按钮
   来源：[src/scenes/rpg/RpgGameHost.tsx:2579](../src/scenes/rpg/RpgGameHost.tsx#L2579)
1631. A 左收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2583](../src/scenes/rpg/RpgGameHost.tsx#L2583)
1632. willowBranchPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2589](../src/scenes/rpg/RpgGameHost.tsx#L2589)
1633. 交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2650](../src/scenes/rpg/RpgGameHost.tsx#L2650)
1634. 与当前湖区目标交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2650](../src/scenes/rpg/RpgGameHost.tsx#L2650)
1635. RPG操作键，键盘使用 WASD 移动和空格键交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2657](../src/scenes/rpg/RpgGameHost.tsx#L2657)
1636. 向上
   来源：[src/scenes/rpg/RpgGameHost.tsx:2659](../src/scenes/rpg/RpgGameHost.tsx#L2659)
1637. 向左
   来源：[src/scenes/rpg/RpgGameHost.tsx:2660](../src/scenes/rpg/RpgGameHost.tsx#L2660)
1638. 向下
   来源：[src/scenes/rpg/RpgGameHost.tsx:2661](../src/scenes/rpg/RpgGameHost.tsx#L2661)
1639. 向右
   来源：[src/scenes/rpg/RpgGameHost.tsx:2662](../src/scenes/rpg/RpgGameHost.tsx#L2662)
1640. 深色模式只读取线索和异常，不执行实体操作。
   来源：[src/scenes/rpg/RpgInteractionContract.ts:40](../src/scenes/rpg/RpgInteractionContract.ts#L40)
1641. 浅色模式执行移动、拖放、清洁、付款和设备操作。
   来源：[src/scenes/rpg/RpgInteractionContract.ts:44](../src/scenes/rpg/RpgInteractionContract.ts#L44)
1642. 204 教室空槽位
   来源：[src/scenes/rpg/RpgInteractionContract.ts:444](../src/scenes/rpg/RpgInteractionContract.ts#L444)
1643. 烤箱旁的检修灯
   来源：[src/scenes/rpg/RpgInteractionContract.ts:556](../src/scenes/rpg/RpgInteractionContract.ts#L556)
1644. 面包坊传送带边缘
   来源：[src/scenes/rpg/RpgInteractionContract.ts:572](../src/scenes/rpg/RpgInteractionContract.ts#L572)
1645. 传送带旁的金属时针
   来源：[src/scenes/rpg/RpgInteractionContract.ts:588](../src/scenes/rpg/RpgInteractionContract.ts#L588)
1646. 清洁车卡住的轮罩
   来源：[src/scenes/rpg/RpgInteractionContract.ts:812](../src/scenes/rpg/RpgInteractionContract.ts#L812)
1647. 面包店后场短撬棍
   来源：[src/scenes/rpg/RpgInteractionContract.ts:828](../src/scenes/rpg/RpgInteractionContract.ts#L828)
1648. 清洁车轮罩
   来源：[src/scenes/rpg/RpgInteractionContract.ts:839](../src/scenes/rpg/RpgInteractionContract.ts#L839)
1649. 清洁车里的通用润滑油
   来源：[src/scenes/rpg/RpgInteractionContract.ts:853](../src/scenes/rpg/RpgInteractionContract.ts#L853)
1650. 清洁车车轮
   来源：[src/scenes/rpg/RpgInteractionContract.ts:864](../src/scenes/rpg/RpgInteractionContract.ts#L864)
1651. 签到校园卡读卡器
   来源：[src/scenes/rpg/RpgInteractionContract.ts:957](../src/scenes/rpg/RpgInteractionContract.ts#L957)；[src/scenes/rpg/RpgItemUseGuidance.ts:76](../src/scenes/rpg/RpgItemUseGuidance.ts#L76)
1652. 签到记录纸槽
   来源：[src/scenes/rpg/RpgInteractionContract.ts:973](../src/scenes/rpg/RpgInteractionContract.ts#L973)；[src/scenes/rpg/RpgItemUseGuidance.ts:82](../src/scenes/rpg/RpgItemUseGuidance.ts#L82)
1653. 先把最后一分钟归还到旧钟，再去签到口。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:85](../src/scenes/rpg/RpgItemUseGuidance.ts#L85)
1654. 旧钟接近 07:55 时，这张纸会被剧情自动带走。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:88](../src/scenes/rpg/RpgItemUseGuidance.ts#L88)

## 结局

1. locked
   来源：[src/core/GameState.ts:243](../src/core/GameState.ts#L243)
2. completed
   来源：[src/core/QuestModel.ts:100](../src/core/QuestModel.ts#L100)；[src/core/QuestModel.ts:592](../src/core/QuestModel.ts#L592)；[src/core/QuestModel.ts:961](../src/core/QuestModel.ts#L961)；[src/core/QuestModel.ts:997](../src/core/QuestModel.ts#L997)；[src/core/QuestModel.ts:1070](../src/core/QuestModel.ts#L1070)
3. pending
   来源：[src/core/QuestModel.ts:100](../src/core/QuestModel.ts#L100)；[src/core/QuestModel.ts:592](../src/core/QuestModel.ts#L592)；[src/core/QuestModel.ts:961](../src/core/QuestModel.ts#L961)；[src/core/QuestModel.ts:997](../src/core/QuestModel.ts#L997)；[src/core/QuestModel.ts:1070](../src/core/QuestModel.ts#L1070)
4. 201 定位板
   来源：[src/core/QuestModel.ts:970](../src/core/QuestModel.ts#L970)
5. 三轴校准
   来源：[src/core/QuestModel.ts:971](../src/core/QuestModel.ts#L971)
6. 203 配电箱
   来源：[src/core/QuestModel.ts:976](../src/core/QuestModel.ts#L976)
7. 五区拓扑
   来源：[src/core/QuestModel.ts:977](../src/core/QuestModel.ts#L977)
8. 开放自习区
   来源：[src/core/QuestModel.ts:982](../src/core/QuestModel.ts#L982)
9. 疏散路线
   来源：[src/core/QuestModel.ts:983](../src/core/QuestModel.ts#L983)
10. 1F 起行轨
   来源：[src/core/QuestModel.ts:1006](../src/core/QuestModel.ts#L1006)
11. 门体与起行
   来源：[src/core/QuestModel.ts:1007](../src/core/QuestModel.ts#L1007)
12. 2F 外呼日志
   来源：[src/core/QuestModel.ts:1012](../src/core/QuestModel.ts#L1012)
13. 呼梯与门机
   来源：[src/core/QuestModel.ts:1013](../src/core/QuestModel.ts#L1013)
14. 3F 到站记录
   来源：[src/core/QuestModel.ts:1018](../src/core/QuestModel.ts#L1018)
15. 铃声与开门
   来源：[src/core/QuestModel.ts:1019](../src/core/QuestModel.ts#L1019)
16. 围栏开了。朝左岸划。
   来源：[src/data/pursuit.audio.content.json:45](../src/data/pursuit.audio.content.json#L45)
17. The gate is open. Paddle for the left bank.
   来源：[src/data/pursuit.audio.content.json:46](../src/data/pursuit.audio.content.json#L46)
18. 校园卡余额
   来源：[src/data/scenes.config.json:9](../src/data/scenes.config.json#L9)
19. P04
   来源：[src/data/scenes.config.json:9](../src/data/scenes.config.json#L9)
20. 校务签到（学在浙大）
   来源：[src/data/scenes.config.json:10](../src/data/scenes.config.json#L10)
21. P11
   来源：[src/data/scenes.config.json:10](../src/data/scenes.config.json#L10)
22. 盆栽
   来源：[src/data/scenes.config.json:11](../src/data/scenes.config.json#L11)
23. P10
   来源：[src/data/scenes.config.json:11](../src/data/scenes.config.json#L11)
24. 序章结算 / 下一章入口
   来源：[src/data/scenes.config.json:12](../src/data/scenes.config.json#L12)
25. P12
   来源：[src/data/scenes.config.json:12](../src/data/scenes.config.json#L12)
26. narrator
   来源：[src/scenes/phone/P12_Ending/index.tsx:46](../src/scenes/phone/P12_Ending/index.tsx#L46)；[src/scenes/phone/P12_Ending/index.tsx:49](../src/scenes/phone/P12_Ending/index.tsx#L49)
27. 不，除非你帮助我
   来源：[src/scenes/phone/P12_Ending/index.tsx:47](../src/scenes/phone/P12_Ending/index.tsx#L47)
28. player
   来源：[src/scenes/phone/P12_Ending/index.tsx:47](../src/scenes/phone/P12_Ending/index.tsx#L47)；[src/scenes/phone/P12_Ending/index.tsx:48](../src/scenes/phone/P12_Ending/index.tsx#L48)
29. 不然你就和我的绩点同归于尽吧
   来源：[src/scenes/phone/P12_Ending/index.tsx:48](../src/scenes/phone/P12_Ending/index.tsx#L48)
30. 序章结算
   来源：[src/scenes/phone/P12_Ending/index.tsx:505](../src/scenes/phone/P12_Ending/index.tsx#L505)
31. 黑屏
   来源：[src/scenes/phone/P12_Ending/index.tsx:510](../src/scenes/phone/P12_Ending/index.tsx#L510)
32. GEO ERROR // INTERCEPT
   来源：[src/scenes/phone/P12_Ending/index.tsx:516](../src/scenes/phone/P12_Ending/index.tsx#L516)
33. 错误框拦截
   来源：[src/scenes/phone/P12_Ending/index.tsx:517](../src/scenes/phone/P12_Ending/index.tsx#L517)
34. 已挡住 {{view.blockedCount}} 次，共 {{REQUIRED\_BLOCKS}} 次
   来源：[src/scenes/phone/P12_Ending/index.tsx:519](../src/scenes/phone/P12_Ending/index.tsx#L519)
35. 失误
   来源：[src/scenes/phone/P12_Ending/index.tsx:524](../src/scenes/phone/P12_Ending/index.tsx#L524)
36. 旁白
   来源：[src/scenes/phone/P12_Ending/index.tsx:532](../src/scenes/phone/P12_Ending/index.tsx#L532)；[src/scenes/phone/P12_Ending/index.tsx:576](../src/scenes/phone/P12_Ending/index.tsx#L576)；[src/scenes/phone/P12_Ending/index.tsx:650](../src/scenes/phone/P12_Ending/index.tsx#L650)
37. 按住旁白圆圈完成锁定，当前 {{Math.round(lockProgress \* 100)}}%
   来源：[src/scenes/phone/P12_Ending/index.tsx:547](../src/scenes/phone/P12_Ending/index.tsx#L547)
38. 正在移动的旁白圆圈
   来源：[src/scenes/phone/P12_Ending/index.tsx:573](../src/scenes/phone/P12_Ending/index.tsx#L573)
39. 拖动经纬度错误框挡住下方出口，键盘可用 A D 或左右方向键
   来源：[src/scenes/phone/P12_Ending/index.tsx:589](../src/scenes/phone/P12_Ending/index.tsx#L589)
40. LOCATION ERROR
   来源：[src/scenes/phone/P12_Ending/index.tsx:608](../src/scenes/phone/P12_Ending/index.tsx#L608)
41. 经度与纬度不存在
   来源：[src/scenes/phone/P12_Ending/index.tsx:609](../src/scenes/phone/P12_Ending/index.tsx#L609)
42. null / null
   来源：[src/scenes/phone/P12_Ending/index.tsx:610](../src/scenes/phone/P12_Ending/index.tsx#L610)
43. 已挡住
   来源：[src/scenes/phone/P12_Ending/index.tsx:615](../src/scenes/phone/P12_Ending/index.tsx#L615)
44. 未命中出口位置
   来源：[src/scenes/phone/P12_Ending/index.tsx:618](../src/scenes/phone/P12_Ending/index.tsx#L618)
45. SIGNAL LOST
   来源：[src/scenes/phone/P12_Ending/index.tsx:623](../src/scenes/phone/P12_Ending/index.tsx#L623)
46. 拦截失败
   来源：[src/scenes/phone/P12_Ending/index.tsx:624](../src/scenes/phone/P12_Ending/index.tsx#L624)
47. 错误框连续三次没有对齐出口。
   来源：[src/scenes/phone/P12_Ending/index.tsx:625](../src/scenes/phone/P12_Ending/index.tsx#L625)
48. 重新部署错误框
   来源：[src/scenes/phone/P12_Ending/index.tsx:626](../src/scenes/phone/P12_Ending/index.tsx#L626)
49. 按住圆圈 1.4 秒完成锁定
   来源：[src/scenes/phone/P12_Ending/index.tsx:632](../src/scenes/phone/P12_Ending/index.tsx#L632)
50. 拖动错误框 · 键盘 A / D 或 ← / →
   来源：[src/scenes/phone/P12_Ending/index.tsx:632](../src/scenes/phone/P12_Ending/index.tsx#L632)
51. 已被锁定的旁白圆圈
   来源：[src/scenes/phone/P12_Ending/index.tsx:640](../src/scenes/phone/P12_Ending/index.tsx#L640)
52. 已锁定
   来源：[src/scenes/phone/P12_Ending/index.tsx:642](../src/scenes/phone/P12_Ending/index.tsx#L642)
53. 我
   来源：[src/scenes/phone/P12_Ending/index.tsx:650](../src/scenes/phone/P12_Ending/index.tsx#L650)
54. 已暂停
   来源：[src/scenes/phone/P12_Ending/index.tsx:657](../src/scenes/phone/P12_Ending/index.tsx#L657)
55. 白屏闪退
   来源：[src/scenes/phone/P12_Ending/index.tsx:659](../src/scenes/phone/P12_Ending/index.tsx#L659)
56. 哐当——齿轮转了半圈，掉下来了。背面朝外。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:99](../src/scenes/phone/P13_PhoneHome/index.tsx#L99)
57. 记录恢复
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:868](../src/scenes/phone/P13_PhoneHome/index.tsx#L868)
58. 检测到 7 分 55 秒未同步记录
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:868](../src/scenes/phone/P13_PhoneHome/index.tsx#L868)
59. 现在
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:869](../src/scenes/phone/P13_PhoneHome/index.tsx#L869)；[src/scenes/phone/P13_PhoneHome/index.tsx:884](../src/scenes/phone/P13_PhoneHome/index.tsx#L884)
60. 朋友：成功了吗
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:872](../src/scenes/phone/P13_PhoneHome/index.tsx#L872)
61. 成功了吗
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:883](../src/scenes/phone/P13_PhoneHome/index.tsx#L883)；[src/scenes/phone/P14_Wechat/index.tsx:844](../src/scenes/phone/P14_Wechat/index.tsx#L844)
62. 朋友
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:883](../src/scenes/phone/P13_PhoneHome/index.tsx#L883)；[src/scenes/phone/P14_Wechat/index.tsx:839](../src/scenes/phone/P14_Wechat/index.tsx#L839)
63. 朋友发来的微信消息
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:887](../src/scenes/phone/P13_PhoneHome/index.tsx#L887)
64. 任务更新：找到系统
   来源：[src/scenes/phone/P14_Wechat/index.tsx:297](../src/scenes/phone/P14_Wechat/index.tsx#L297)
65. task
   来源：[src/scenes/phone/P14_Wechat/index.tsx:297](../src/scenes/phone/P14_Wechat/index.tsx#L297)
66. 你到底到哪了？
   来源：[src/scenes/phone/P14_Wechat/index.tsx:842](../src/scenes/phone/P14_Wechat/index.tsx#L842)
67. 这是签到码 ▓▓▓▓
   来源：[src/scenes/phone/P14_Wechat/index.tsx:846](../src/scenes/phone/P14_Wechat/index.tsx#L846)
68. 快快老师在点名，学在浙大
   来源：[src/scenes/phone/P14_Wechat/index.tsx:847](../src/scenes/phone/P14_Wechat/index.tsx#L847)
69. 室友：还有 12 秒进入梦乡最深处。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:858](../src/scenes/phone/P14_Wechat/index.tsx#L858)
70. 室友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:866](../src/scenes/phone/P14_Wechat/index.tsx#L866)
71. 晚上一起去食堂吃饭呀~
   来源：[src/scenes/phone/P14_Wechat/index.tsx:867](../src/scenes/phone/P14_Wechat/index.tsx#L867)
72. 没有，但我正试着威胁系统
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1017](../src/scenes/phone/P14_Wechat/index.tsx#L1017)
73. 启真湖地点线索
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1035](../src/scenes/phone/P14_Wechat/index.tsx#L1035)
74. 保存地点词：湖面
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1044](../src/scenes/phone/P14_Wechat/index.tsx#L1044)
75. 已保存地点词：湖面
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1044](../src/scenes/phone/P14_Wechat/index.tsx#L1044)
76. 任务：找到系统
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1051](../src/scenes/phone/P14_Wechat/index.tsx#L1051)
77. 任务：找回四位签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1053](../src/scenes/phone/P14_Wechat/index.tsx#L1053)
78. 座位状态图例
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:520](../src/scenes/phone/P15_Zjuding/index.tsx#L520)
79. 空闲中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:522](../src/scenes/phone/P15_Zjuding/index.tsx#L522)
80. 已预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:523](../src/scenes/phone/P15_Zjuding/index.tsx#L523)
81. 使用中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:524](../src/scenes/phone/P15_Zjuding/index.tsx#L524)
82. 暂停中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:525](../src/scenes/phone/P15_Zjuding/index.tsx#L525)
83. 不可用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:526](../src/scenes/phone/P15_Zjuding/index.tsx#L526)
84. 请点击白色座位选座
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:535](../src/scenes/phone/P15_Zjuding/index.tsx#L535)
85. Please select a seat available
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:536](../src/scenes/phone/P15_Zjuding/index.tsx#L536)
86. P00 闹钟
   来源：[src/scenes/phone/registry.tsx:23](../src/scenes/phone/registry.tsx#L23)
87. 07:55 闹钟，振动+音效，关闭后进入起床场景。
   来源：[src/scenes/phone/registry.tsx:24](../src/scenes/phone/registry.tsx#L24)
88. 倒影对应点一
   来源：[src/scenes/rpg/RpgGameHost.tsx:227](../src/scenes/rpg/RpgGameHost.tsx#L227)
89. 旧木桩倒影
   来源：[src/scenes/rpg/RpgGameHost.tsx:228](../src/scenes/rpg/RpgGameHost.tsx#L228)
90. 鱼群水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:229](../src/scenes/rpg/RpgGameHost.tsx#L229)
91. 纸条本体水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:230](../src/scenes/rpg/RpgGameHost.tsx#L230)
92. 启真湖的行程还没开始,现在拍不了。
   来源：[src/scenes/rpg/RpgGameHost.tsx:233](../src/scenes/rpg/RpgGameHost.tsx#L233)
93. 黑天鹅正追着船尾,顾不上拍照。
   来源：[src/scenes/rpg/RpgGameHost.tsx:234](../src/scenes/rpg/RpgGameHost.tsx#L234)
94. 先完成上船教学,稳住船之后再打开相机。
   来源：[src/scenes/rpg/RpgGameHost.tsx:235](../src/scenes/rpg/RpgGameHost.tsx#L235)
95. 手柄已安装，自动走动已停止。请输入一次方向。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1431](../src/scenes/rpg/RpgGameHost.tsx#L1431)
96. 他还不知道自己是谁。先用部门黄页完成命名。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1432](../src/scenes/rpg/RpgGameHost.tsx#L1432)
97. 他还没有开始课外锻炼。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1433](../src/scenes/rpg/RpgGameHost.tsx#L1433)
98. 道具栏里没有手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1434](../src/scenes/rpg/RpgGameHost.tsx#L1434)
99. 204 讲台抽屉里的定位盘
   来源：[src/scenes/rpg/RpgInteractionContract.ts:777](../src/scenes/rpg/RpgInteractionContract.ts#L777)
100. 旧钟定位盘插槽
   来源：[src/scenes/rpg/RpgInteractionContract.ts:800](../src/scenes/rpg/RpgInteractionContract.ts#L800)
101. no\_response
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1319](../src/scenes/rpg/RpgInteractionContract.ts#L1319)
102. multiple\_responses
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1320](../src/scenes/rpg/RpgInteractionContract.ts#L1320)
103. invalid\_response
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1323](../src/scenes/rpg/RpgInteractionContract.ts#L1323)

## 跨章节与共用系统

1. 当前剧情条件已变化，请返回任务目标后重试。
   来源：[src/App.tsx:186](../src/App.tsx#L186)
2. 手机交互区
   来源：[src/App.tsx:423](../src/App.tsx#L423)
3. 地图交互区
   来源：[src/App.tsx:442](../src/App.tsx#L442)
4. Loading RPG runtime
   来源：[src/App.tsx:447](../src/App.tsx#L447)；[src/App.tsx:478](../src/App.tsx#L478)
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
   来源：[src/components/GameSubtitleFrame.tsx:18](../src/components/GameSubtitleFrame.tsx#L18)；[src/components/QuestClueStrip.tsx:185](../src/components/QuestClueStrip.tsx#L185)；[src/scenes/phone/P15_Zjuding/index.tsx:2014](../src/scenes/phone/P15_Zjuding/index.tsx#L2014)
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
270. 并行调查
   来源：[src/components/InvestigationRing.tsx:54](../src/components/InvestigationRing.tsx#L54)
271. 各节点可以任意顺序处理
   来源：[src/components/InvestigationRing.tsx:55](../src/components/InvestigationRing.tsx#L55)
272. 已完成 {{completed}} 项，共 {{total}} 项
   来源：[src/components/InvestigationRing.tsx:120](../src/components/InvestigationRing.tsx#L120)
273. 等待汇合
   来源：[src/components/InvestigationRing.tsx:140](../src/components/InvestigationRing.tsx#L140)
274. 已汇合
   来源：[src/components/InvestigationRing.tsx:140](../src/components/InvestigationRing.tsx#L140)
275. {{node.label}}，{{node.statusLabel}}{{node.detail ? \`，${node.detail}\` : ""}}
   来源：[src/components/InvestigationRing.tsx:160](../src/components/InvestigationRing.tsx#L160)
276. 环境材料
   来源：[src/components/ItemInspectDialog.tsx:35](../src/components/ItemInspectDialog.tsx#L35)
277. 主屏早八雨滴
   来源：[src/components/ItemInspectDialog.tsx:36](../src/components/ItemInspectDialog.tsx#L36)
278. 一滴不够浇花。某件翻到背面的随身设备，刚好留着一个空腔。
   来源：[src/components/ItemInspectDialog.tsx:37](../src/components/ItemInspectDialog.tsx#L37)
279. 容器素材
   来源：[src/components/ItemInspectDialog.tsx:40](../src/components/ItemInspectDialog.tsx#L40)
280. 控制中心音乐模块
   来源：[src/components/ItemInspectDialog.tsx:41](../src/components/ItemInspectDialog.tsx#L41)
281. 正面负责声音，背面留着凹处。那一点空位还没有装东西。
   来源：[src/components/ItemInspectDialog.tsx:42](../src/components/ItemInspectDialog.tsx#L42)
282. 合成道具
   来源：[src/components/ItemInspectDialog.tsx:45](../src/components/ItemInspectDialog.tsx#L45)
283. 耳机 + 水滴
   来源：[src/components/ItemInspectDialog.tsx:46](../src/components/ItemInspectDialog.tsx#L46)
284. 耳机背面的空腔里留着一小份水，液体没有继续渗出。
   来源：[src/components/ItemInspectDialog.tsx:47](../src/components/ItemInspectDialog.tsx#L47)
285. 机械素材
   来源：[src/components/ItemInspectDialog.tsx:50](../src/components/ItemInspectDialog.tsx#L50)
286. 主屏设置齿轮背面
   来源：[src/components/ItemInspectDialog.tsx:51](../src/components/ItemInspectDialog.tsx#L51)
287. 数字藏在背面，齿形留在边缘。若再接上一段斜线，轮廓会更完整。
   来源：[src/components/ItemInspectDialog.tsx:52](../src/components/ItemInspectDialog.tsx#L52)
288. 图形素材
   来源：[src/components/ItemInspectDialog.tsx:55](../src/components/ItemInspectDialog.tsx#L55)；[src/components/ItemInspectDialog.tsx:75](../src/components/ItemInspectDialog.tsx#L75)；[src/components/ItemInspectDialog.tsx:85](../src/components/ItemInspectDialog.tsx#L85)
289. 朋友头像掉落的一撇
   来源：[src/components/ItemInspectDialog.tsx:56](../src/components/ItemInspectDialog.tsx#L56)
290. 单独看只是一撇。某个带齿的圆形部件缺少一段细长结构。
   来源：[src/components/ItemInspectDialog.tsx:57](../src/components/ItemInspectDialog.tsx#L57)
291. 解锁工具
   来源：[src/components/ItemInspectDialog.tsx:60](../src/components/ItemInspectDialog.tsx#L60)；[src/components/ItemInspectDialog.tsx:269](../src/components/ItemInspectDialog.tsx#L269)
292. 斜线 + 反转齿轮
   来源：[src/components/ItemInspectDialog.tsx:61](../src/components/ItemInspectDialog.tsx#L61)
293. 轮廓已经完整。主屏高处有一处尺寸相近、一直没有作用的圆孔。
   来源：[src/components/ItemInspectDialog.tsx:62](../src/components/ItemInspectDialog.tsx#L62)
294. 植物材料
   来源：[src/components/ItemInspectDialog.tsx:65](../src/components/ItemInspectDialog.tsx#L65)
295. 塔楼机关奖励
   来源：[src/components/ItemInspectDialog.tsx:66](../src/components/ItemInspectDialog.tsx#L66)
296. 水、光、土壤养分，顺序可以不同，三项都要留下痕迹。
   来源：[src/components/ItemInspectDialog.tsx:67](../src/components/ItemInspectDialog.tsx#L67)
297. 身份凭证
   来源：[src/components/ItemInspectDialog.tsx:70](../src/components/ItemInspectDialog.tsx#L70)
298. 寝室右侧书桌 / 电子校园卡
   来源：[src/components/ItemInspectDialog.tsx:71](../src/components/ItemInspectDialog.tsx#L71)
299. 姓名和学号用于身份核验；余额与校园服务会在后续流程中继续使用。
   来源：[src/components/ItemInspectDialog.tsx:72](../src/components/ItemInspectDialog.tsx#L72)
300. 主页推送头像
   来源：[src/components/ItemInspectDialog.tsx:76](../src/components/ItemInspectDialog.tsx#L76)
301. 尖端已经给出方向，尾部仍少一条笔直的结构。
   来源：[src/components/ItemInspectDialog.tsx:77](../src/components/ItemInspectDialog.tsx#L77)
302. 功能材料
   来源：[src/components/ItemInspectDialog.tsx:80](../src/components/ItemInspectDialog.tsx#L80)
303. 天气页面
   来源：[src/components/ItemInspectDialog.tsx:81](../src/components/ItemInspectDialog.tsx#L81)
304. 水量很少，浇花显得勉强。某张头像边缘的连接处只需要一点湿润。
   来源：[src/components/ItemInspectDialog.tsx:82](../src/components/ItemInspectDialog.tsx#L82)
305. 导师头像掉落的一竖
   来源：[src/components/ItemInspectDialog.tsx:86](../src/components/ItemInspectDialog.tsx#L86)
306. 长度和方向都合适；某个只有尖端的图形还缺它。
   来源：[src/components/ItemInspectDialog.tsx:87](../src/components/ItemInspectDialog.tsx#L87)
307. 位移工具
   来源：[src/components/ItemInspectDialog.tsx:90](../src/components/ItemInspectDialog.tsx#L90)
308. 三角形 + 竖线
   来源：[src/components/ItemInspectDialog.tsx:91](../src/components/ItemInspectDialog.tsx#L91)
309. 它只规定向右，不规定对象。写着数的、夹在缝里的，都属于可尝试范围。
   来源：[src/components/ItemInspectDialog.tsx:92](../src/components/ItemInspectDialog.tsx#L92)
310. 控制设备
   来源：[src/components/ItemInspectDialog.tsx:95](../src/components/ItemInspectDialog.tsx#L95)
311. CC98 二手市场
   来源：[src/components/ItemInspectDialog.tsx:96](../src/components/ItemInspectDialog.tsx#L96)
312. 自动行走解决了会不会走；四个方向才能决定往哪里走。
   来源：[src/components/ItemInspectDialog.tsx:97](../src/components/ItemInspectDialog.tsx#L97)
313. 调查证据
   来源：[src/components/ItemInspectDialog.tsx:100](../src/components/ItemInspectDialog.tsx#L100)
314. 图书馆 022 座位旁
   来源：[src/components/ItemInspectDialog.tsx:101](../src/components/ItemInspectDialog.tsx#L101)
315. 纸上写了离开时长和占位理由。原句放进公开讨论区，更容易找到相同说法。
   来源：[src/components/ItemInspectDialog.tsx:102](../src/components/ItemInspectDialog.tsx#L102)
316. 检索线索
   来源：[src/components/ItemInspectDialog.tsx:105](../src/components/ItemInspectDialog.tsx#L105)
317. 浙大钉馆藏检索结果
   来源：[src/components/ItemInspectDialog.tsx:106](../src/components/ItemInspectDialog.tsx#L106)
318. 这串数字不回答问题，只标记位置。书架边缘会出现同样的编号。
   来源：[src/components/ItemInspectDialog.tsx:107](../src/components/ItemInspectDialog.tsx#L107)
319. 公开证据
   来源：[src/components/ItemInspectDialog.tsx:110](../src/components/ItemInspectDialog.tsx#L110)
320. 图书馆 755 书架夹层
   来源：[src/components/ItemInspectDialog.tsx:111](../src/components/ItemInspectDialog.tsx#L111)
321. 发布日期很旧，适用范围仍值得核对。公开讨论需要能查到出处的文字。
   来源：[src/components/ItemInspectDialog.tsx:112](../src/components/ItemInspectDialog.tsx#L112)
322. 机器报告
   来源：[src/components/ItemInspectDialog.tsx:115](../src/components/ItemInspectDialog.tsx#L115)
323. 照片识别结果
   来源：[src/components/ItemInspectDialog.tsx:116](../src/components/ItemInspectDialog.tsx#L116)
324. 它确认了画面里的物品，身份一栏仍为空。校园里有个地方专门补这一栏。
   来源：[src/components/ItemInspectDialog.tsx:117](../src/components/ItemInspectDialog.tsx#L117)
325. 认证证明
   来源：[src/components/ItemInspectDialog.tsx:120](../src/components/ItemInspectDialog.tsx#L120)
326. 物品身份盖章机
   来源：[src/components/ItemInspectDialog.tsx:121](../src/components/ItemInspectDialog.tsx#L121)
327. 一条错误等号已经被排除，座位归属仍未说明。单独提交会缺少另外两类材料。
   来源：[src/components/ItemInspectDialog.tsx:122](../src/components/ItemInspectDialog.tsx#L122)
328. 座位凭据
   来源：[src/components/ItemInspectDialog.tsx:125](../src/components/ItemInspectDialog.tsx#L125)
329. 022 桌面夹缝
   来源：[src/components/ItemInspectDialog.tsx:126](../src/components/ItemInspectDialog.tsx#L126)；[src/scenes/rpg/RpgItemUseGuidance.ts:156](../src/scenes/rpg/RpgItemUseGuidance.ts#L156)
330. 编号能对应座位，时间要与另一份到场记录互相核对。
   来源：[src/components/ItemInspectDialog.tsx:127](../src/components/ItemInspectDialog.tsx#L127)
331. 到场证明
   来源：[src/components/ItemInspectDialog.tsx:130](../src/components/ItemInspectDialog.tsx#L130)
332. 浙大体艺访问记录
   来源：[src/components/ItemInspectDialog.tsx:131](../src/components/ItemInspectDialog.tsx#L131)
333. 它只回答人是否到过那里，座位归属还要交给另一张凭据。
   来源：[src/components/ItemInspectDialog.tsx:132](../src/components/ItemInspectDialog.tsx#L132)
334. 执行凭证
   来源：[src/components/ItemInspectDialog.tsx:135](../src/components/ItemInspectDialog.tsx#L135)
335. 022 恢复申请签发
   来源：[src/components/ItemInspectDialog.tsx:136](../src/components/ItemInspectDialog.tsx#L136)
336. 三份材料已经换成临时处置权限，凭证对应基础馆二层南区 022。
   来源：[src/components/ItemInspectDialog.tsx:137](../src/components/ItemInspectDialog.tsx#L137)
337. 餐盘回收费 2.00 元
   来源：[src/components/ItemInspectDialog.tsx:140](../src/components/ItemInspectDialog.tsx#L140)；[src/components/PixelIcon.tsx:854](../src/components/PixelIcon.tsx#L854)；[src/data/items.config.json:151](../src/data/items.config.json#L151)
338. 餐盘回收
   来源：[src/components/ItemInspectDialog.tsx:141](../src/components/ItemInspectDialog.tsx#L141)
339. 收回三只目标餐盘得到的两元钱，可支付一次扫码骑车。
   来源：[src/components/ItemInspectDialog.tsx:142](../src/components/ItemInspectDialog.tsx#L142)；[src/components/PixelIcon.tsx:854](../src/components/PixelIcon.tsx#L854)；[src/data/items.config.json:152](../src/data/items.config.json#L152)
340. 油渍纸巾
   来源：[src/components/ItemInspectDialog.tsx:145](../src/components/ItemInspectDialog.tsx#L145)；[src/components/PixelIcon.tsx:855](../src/components/PixelIcon.tsx#L855)；[src/data/items.config.json:158](../src/data/items.config.json#L158)
341. 食堂桌面
   来源：[src/components/ItemInspectDialog.tsx:146](../src/components/ItemInspectDialog.tsx#L146)
342. 收餐口阿姨给的油渍纸巾，可擦掉车锁和海报玻璃上的反光。
   来源：[src/components/ItemInspectDialog.tsx:147](../src/components/ItemInspectDialog.tsx#L147)；[src/components/PixelIcon.tsx:855](../src/components/PixelIcon.tsx#L855)；[src/data/items.config.json:159](../src/data/items.config.json#L159)
343. 调配原料 · 蓝色
   来源：[src/components/ItemInspectDialog.tsx:150](../src/components/ItemInspectDialog.tsx#L150)
344. 食堂饮料区
   来源：[src/components/ItemInspectDialog.tsx:151](../src/components/ItemInspectDialog.tsx#L151)；[src/components/ItemInspectDialog.tsx:156](../src/components/ItemInspectDialog.tsx#L156)；[src/components/ItemInspectDialog.tsx:161](../src/components/ItemInspectDialog.tsx#L161)
345. 蓝色饮料原料。与黑咖啡、柠檬茶按货架顺序调配。
   来源：[src/components/ItemInspectDialog.tsx:152](../src/components/ItemInspectDialog.tsx#L152)；[src/components/PixelIcon.tsx:856](../src/components/PixelIcon.tsx#L856)；[src/data/items.config.json:166](../src/data/items.config.json#L166)
346. 调配原料 · 白色
   来源：[src/components/ItemInspectDialog.tsx:155](../src/components/ItemInspectDialog.tsx#L155)
347. 白色饮料原料。查看货架颜色顺序后放进混合台。
   来源：[src/components/ItemInspectDialog.tsx:157](../src/components/ItemInspectDialog.tsx#L157)；[src/components/PixelIcon.tsx:857](../src/components/PixelIcon.tsx#L857)；[src/data/items.config.json:173](../src/data/items.config.json#L173)
348. 调配原料 · 黑色
   来源：[src/components/ItemInspectDialog.tsx:160](../src/components/ItemInspectDialog.tsx#L160)
349. 黑色饮料原料。按货架顺序放进混合台。
   来源：[src/components/ItemInspectDialog.tsx:162](../src/components/ItemInspectDialog.tsx#L162)；[src/components/PixelIcon.tsx:858](../src/components/PixelIcon.tsx#L858)；[src/data/items.config.json:180](../src/data/items.config.json#L180)
350. 失败饮品
   来源：[src/components/ItemInspectDialog.tsx:165](../src/components/ItemInspectDialog.tsx#L165)
351. 食堂混合台
   来源：[src/components/ItemInspectDialog.tsx:166](../src/components/ItemInspectDialog.tsx#L166)；[src/components/ItemInspectDialog.tsx:172](../src/components/ItemInspectDialog.tsx#L172)
352. 混错顺序得到的饮料。可以喝掉，不能推进任务。
   来源：[src/components/ItemInspectDialog.tsx:167](../src/components/ItemInspectDialog.tsx#L167)；[src/components/PixelIcon.tsx:859](../src/components/PixelIcon.tsx#L859)；[src/data/items.config.json:187](../src/data/items.config.json#L187)
353. 在食堂 RPG 中拖到自己身上可以喝掉。
   来源：[src/components/ItemInspectDialog.tsx:168](../src/components/ItemInspectDialog.tsx#L168)
354. 今日新品
   来源：[src/components/ItemInspectDialog.tsx:171](../src/components/ItemInspectDialog.tsx#L171)
355. 拖到第三窗口宣传板的空杯位。守出口时可在地面留两秒减速气泡。
   来源：[src/components/ItemInspectDialog.tsx:173](../src/components/ItemInspectDialog.tsx#L173)；[src/components/PixelIcon.tsx:860](../src/components/PixelIcon.tsx#L860)；[src/data/items.config.json:194](../src/data/items.config.json#L194)
356. 先拖到第三个餐口宣传板空杯位；守出口时可再拖进食堂地面减速纸条。
   来源：[src/components/ItemInspectDialog.tsx:174](../src/components/ItemInspectDialog.tsx#L174)
357. 0755 取餐号
   来源：[src/components/ItemInspectDialog.tsx:177](../src/components/ItemInspectDialog.tsx#L177)；[src/components/PixelIcon.tsx:861](../src/components/PixelIcon.tsx#L861)；[src/data/itemCatalog.ts:138](../src/data/itemCatalog.ts#L138)；[src/data/items.config.json:200](../src/data/items.config.json#L200)
358. 点餐机
   来源：[src/components/ItemInspectDialog.tsx:178](../src/components/ItemInspectDialog.tsx#L178)
359. 点餐机打印的取餐小票。切到深色模式，交给 3 号窗口残影阿姨。
   来源：[src/components/ItemInspectDialog.tsx:179](../src/components/ItemInspectDialog.tsx#L179)；[src/components/PixelIcon.tsx:861](../src/components/PixelIcon.tsx#L861)；[src/data/items.config.json:201](../src/data/items.config.json#L201)
360. 1号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)
361. 从窗口领到的包子。正常，且没有纸条线索。
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)；[src/components/PixelIcon.tsx:862](../src/components/PixelIcon.tsx#L862)；[src/data/items.config.json:208](../src/data/items.config.json#L208)
362. 食堂彩蛋
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)；[src/components/ItemInspectDialog.tsx:182](../src/components/ItemInspectDialog.tsx#L182)；[src/components/ItemInspectDialog.tsx:183](../src/components/ItemInspectDialog.tsx#L183)；[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)
363. 2号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:182](../src/components/ItemInspectDialog.tsx#L182)
364. 从窗口领到的豆浆。此时没有其他用途。
   来源：[src/components/ItemInspectDialog.tsx:182](../src/components/ItemInspectDialog.tsx#L182)；[src/components/PixelIcon.tsx:863](../src/components/PixelIcon.tsx#L863)；[src/data/items.config.json:215](../src/data/items.config.json#L215)
365. 4号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:183](../src/components/ItemInspectDialog.tsx#L183)
366. 从窗口领到的鸡蛋。此时没有其他用途。
   来源：[src/components/ItemInspectDialog.tsx:183](../src/components/ItemInspectDialog.tsx#L183)；[src/components/PixelIcon.tsx:864](../src/components/PixelIcon.tsx#L864)；[src/data/items.config.json:222](../src/data/items.config.json#L222)
367. 5号取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)
368. 从窗口领到的白粥。烫手，且没有其他用途。
   来源：[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)；[src/components/PixelIcon.tsx:865](../src/components/PixelIcon.tsx#L865)；[src/data/items.config.json:229](../src/data/items.config.json#L229)
369. 半张剧院票根 A
   来源：[src/components/ItemInspectDialog.tsx:186](../src/components/ItemInspectDialog.tsx#L186)；[src/components/PixelIcon.tsx:866](../src/components/PixelIcon.tsx#L866)；[src/data/items.config.json:235](../src/data/items.config.json#L235)
370. 剧院海报栏
   来源：[src/components/ItemInspectDialog.tsx:187](../src/components/ItemInspectDialog.tsx#L187)
371. 它证明你的一半可以进场，另一半还在流程里。
   来源：[src/components/ItemInspectDialog.tsx:188](../src/components/ItemInspectDialog.tsx#L188)；[src/components/PixelIcon.tsx:866](../src/components/PixelIcon.tsx#L866)；[src/data/items.config.json:236](../src/data/items.config.json#L236)
372. 半张剧院票根 B
   来源：[src/components/ItemInspectDialog.tsx:191](../src/components/ItemInspectDialog.tsx#L191)；[src/components/PixelIcon.tsx:867](../src/components/PixelIcon.tsx#L867)；[src/data/items.config.json:242](../src/data/items.config.json#L242)
373. 剧院取票机
   来源：[src/components/ItemInspectDialog.tsx:192](../src/components/ItemInspectDialog.tsx#L192)
374. 来自一台失败的取票机。它至少努力过。
   来源：[src/components/ItemInspectDialog.tsx:193](../src/components/ItemInspectDialog.tsx#L193)；[src/components/PixelIcon.tsx:867](../src/components/PixelIcon.tsx#L867)；[src/data/items.config.json:243](../src/data/items.config.json#L243)
375. 临时观演票
   来源：[src/components/ItemInspectDialog.tsx:196](../src/components/ItemInspectDialog.tsx#L196)；[src/components/PixelIcon.tsx:868](../src/components/PixelIcon.tsx#L868)；[src/data/items.config.json:249](../src/data/items.config.json#L249)；[src/modules/InventoryController.ts:16](../src/modules/InventoryController.ts#L16)
376. 两张半票根
   来源：[src/components/ItemInspectDialog.tsx:197](../src/components/ItemInspectDialog.tsx#L197)
377. 两张半真半假的票根拼出来的票。剧院看了都沉默了一秒。
   来源：[src/components/ItemInspectDialog.tsx:198](../src/components/ItemInspectDialog.tsx#L198)；[src/components/PixelIcon.tsx:868](../src/components/PixelIcon.tsx#L868)；[src/data/items.config.json:250](../src/data/items.config.json#L250)
378. 节目单残页
   来源：[src/components/ItemInspectDialog.tsx:201](../src/components/ItemInspectDialog.tsx#L201)；[src/components/ItemInspectDialog.tsx:206](../src/components/ItemInspectDialog.tsx#L206)；[src/components/ItemInspectDialog.tsx:211](../src/components/ItemInspectDialog.tsx#L211)
379. 剧院座席
   来源：[src/components/ItemInspectDialog.tsx:202](../src/components/ItemInspectDialog.tsx#L202)；[src/components/ItemInspectDialog.tsx:207](../src/components/ItemInspectDialog.tsx#L207)；[src/components/ItemInspectDialog.tsx:212](../src/components/ItemInspectDialog.tsx#L212)
380. 普通节目单，看起来很会假装正式。
   来源：[src/components/ItemInspectDialog.tsx:203](../src/components/ItemInspectDialog.tsx#L203)；[src/components/ItemInspectDialog.tsx:208](../src/components/ItemInspectDialog.tsx#L208)；[src/components/ItemInspectDialog.tsx:213](../src/components/ItemInspectDialog.tsx#L213)；[src/components/PixelIcon.tsx:869](../src/components/PixelIcon.tsx#L869)；[src/components/PixelIcon.tsx:870](../src/components/PixelIcon.tsx#L870)；[src/components/PixelIcon.tsx:871](../src/components/PixelIcon.tsx#L871)；[src/data/items.config.json:257](../src/data/items.config.json#L257)；[src/data/items.config.json:264](../src/data/items.config.json#L264)；[src/data/items.config.json:271](../src/data/items.config.json#L271)
381. 追光灯遥控器
   来源：[src/components/ItemInspectDialog.tsx:216](../src/components/ItemInspectDialog.tsx#L216)；[src/components/PixelIcon.tsx:872](../src/components/PixelIcon.tsx#L872)；[src/data/items.config.json:277](../src/data/items.config.json#L277)
382. 剧院灯控台
   来源：[src/components/ItemInspectDialog.tsx:217](../src/components/ItemInspectDialog.tsx#L217)
383. 能让舞台中央变亮。也能让逃避责任的纸条短暂接受审判。
   来源：[src/components/ItemInspectDialog.tsx:218](../src/components/ItemInspectDialog.tsx#L218)；[src/components/PixelIcon.tsx:872](../src/components/PixelIcon.tsx#L872)；[src/data/items.config.json:278](../src/data/items.config.json#L278)
384. 荧光粉刷
   来源：[src/components/ItemInspectDialog.tsx:221](../src/components/ItemInspectDialog.tsx#L221)；[src/components/PixelIcon.tsx:873](../src/components/PixelIcon.tsx#L873)；[src/data/items.config.json:284](../src/data/items.config.json#L284)
385. 后台道具箱
   来源：[src/components/ItemInspectDialog.tsx:222](../src/components/ItemInspectDialog.tsx#L222)
386. 刷过之后，连借口都会发光。
   来源：[src/components/ItemInspectDialog.tsx:223](../src/components/ItemInspectDialog.tsx#L223)；[src/components/PixelIcon.tsx:873](../src/components/PixelIcon.tsx#L873)；[src/data/items.config.json:285](../src/data/items.config.json#L285)
387. 假纸条
   来源：[src/components/ItemInspectDialog.tsx:226](../src/components/ItemInspectDialog.tsx#L226)；[src/components/PixelIcon.tsx:874](../src/components/PixelIcon.tsx#L874)；[src/data/items.config.json:291](../src/data/items.config.json#L291)
388. 剧院追光灯下
   来源：[src/components/ItemInspectDialog.tsx:227](../src/components/ItemInspectDialog.tsx#L227)
389. 长得很像目标，但态度没那么差。
   来源：[src/components/ItemInspectDialog.tsx:228](../src/components/ItemInspectDialog.tsx#L228)；[src/components/PixelIcon.tsx:874](../src/components/PixelIcon.tsx#L874)；[src/data/items.config.json:292](../src/data/items.config.json#L292)
390. 可安装到钓竿上作为诱饵，装饵成功后会消耗
   来源：[src/components/ItemInspectDialog.tsx:229](../src/components/ItemInspectDialog.tsx#L229)
391. 湿掉的节目单
   来源：[src/components/ItemInspectDialog.tsx:232](../src/components/ItemInspectDialog.tsx#L232)；[src/components/PixelIcon.tsx:875](../src/components/PixelIcon.tsx#L875)；[src/data/itemCatalog.ts:163](../src/data/itemCatalog.ts#L163)；[src/data/items.config.json:298](../src/data/items.config.json#L298)
392. 剧院舞台
   来源：[src/components/ItemInspectDialog.tsx:233](../src/components/ItemInspectDialog.tsx#L233)；[src/data/itemCatalog.ts:166](../src/data/itemCatalog.ts#L166)
393. 纸条逃跑时留下的节目单，边角湿得很有方向感。
   来源：[src/components/ItemInspectDialog.tsx:234](../src/components/ItemInspectDialog.tsx#L234)；[src/components/PixelIcon.tsx:875](../src/components/PixelIcon.tsx#L875)；[src/data/items.config.json:299](../src/data/items.config.json#L299)
394. 地点关键词
   来源：[src/components/ItemInspectDialog.tsx:237](../src/components/ItemInspectDialog.tsx#L237)；[src/components/ItemInspectDialog.tsx:242](../src/components/ItemInspectDialog.tsx#L242)；[src/components/ItemInspectDialog.tsx:247](../src/components/ItemInspectDialog.tsx#L247)
395. CC98 目击回复
   来源：[src/components/ItemInspectDialog.tsx:238](../src/components/ItemInspectDialog.tsx#L238)
396. 目击者只确认了桥附近，仍不足以确定具体地点。
   来源：[src/components/ItemInspectDialog.tsx:239](../src/components/ItemInspectDialog.tsx#L239)
397. 图书馆馆藏状态
   来源：[src/components/ItemInspectDialog.tsx:243](../src/components/ItemInspectDialog.tsx#L243)
398. 异常页码只出现在水面反射区域。
   来源：[src/components/ItemInspectDialog.tsx:244](../src/components/ItemInspectDialog.tsx#L244)
399. 微信朋友消息
   来源：[src/components/ItemInspectDialog.tsx:248](../src/components/ItemInspectDialog.tsx#L248)
400. 群聊只留下了一个不完整的湖名。
   来源：[src/components/ItemInspectDialog.tsx:249](../src/components/ItemInspectDialog.tsx#L249)
401. 场景坐标
   来源：[src/components/ItemInspectDialog.tsx:252](../src/components/ItemInspectDialog.tsx#L252)
402. 启真湖指示牌
   来源：[src/components/ItemInspectDialog.tsx:253](../src/components/ItemInspectDialog.tsx#L253)
403. 深浅两种观察结果共同指向右侧路灯杆。
   来源：[src/components/ItemInspectDialog.tsx:254](../src/components/ItemInspectDialog.tsx#L254)
404. 寝室电器
   来源：[src/components/ItemInspectDialog.tsx:257](../src/components/ItemInspectDialog.tsx#L257)
405. 个人书桌
   来源：[src/components/ItemInspectDialog.tsx:258](../src/components/ItemInspectDialog.tsx#L258)
406. 吹风机的风量调节仍然可用。
   来源：[src/components/ItemInspectDialog.tsx:259](../src/components/ItemInspectDialog.tsx#L259)
407. 进入天气页面后，用它推动低、中、高三层云带
   来源：[src/components/ItemInspectDialog.tsx:260](../src/components/ItemInspectDialog.tsx#L260)
408. 湖面工具
   来源：[src/components/ItemInspectDialog.tsx:263](../src/components/ItemInspectDialog.tsx#L263)
409. 启真湖码头装备架
   来源：[src/components/ItemInspectDialog.tsx:264](../src/components/ItemInspectDialog.tsx#L264)
410. 竿梢保留了附件连接位。深色观察可记录目标，浅色操作可在正确水纹抛竿。
   来源：[src/components/ItemInspectDialog.tsx:265](../src/components/ItemInspectDialog.tsx#L265)
411. 可安装诱饵、钓取水面物品，或与磁铁组合
   来源：[src/components/ItemInspectDialog.tsx:266](../src/components/ItemInspectDialog.tsx#L266)
412. 启真湖开放水域钓点
   来源：[src/components/ItemInspectDialog.tsx:270](../src/components/ItemInspectDialog.tsx#L270)；[src/components/ItemInspectDialog.tsx:282](../src/components/ItemInspectDialog.tsx#L282)
413. 钥匙表面的锈蚀和码头储物柜锁孔一致。
   来源：[src/components/ItemInspectDialog.tsx:271](../src/components/ItemInspectDialog.tsx#L271)
414. 靠近码头储物柜后拖入锁孔
   来源：[src/components/ItemInspectDialog.tsx:272](../src/components/ItemInspectDialog.tsx#L272)
415. 修复材料
   来源：[src/components/ItemInspectDialog.tsx:275](../src/components/ItemInspectDialog.tsx#L275)；[src/components/ItemInspectDialog.tsx:281](../src/components/ItemInspectDialog.tsx#L281)
416. 启真湖码头储物柜
   来源：[src/components/ItemInspectDialog.tsx:276](../src/components/ItemInspectDialog.tsx#L276)
417. 耐水绳结仍然完整，长度适合重新固定一圈网框。
   来源：[src/components/ItemInspectDialog.tsx:277](../src/components/ItemInspectDialog.tsx#L277)
418. 与缺少网面的框架组合
   来源：[src/components/ItemInspectDialog.tsx:278](../src/components/ItemInspectDialog.tsx#L278)
419. 框架仍可承重，固定网面的绳索已经脱落。
   来源：[src/components/ItemInspectDialog.tsx:283](../src/components/ItemInspectDialog.tsx#L283)
420. 与耐水绳索组合
   来源：[src/components/ItemInspectDialog.tsx:284](../src/components/ItemInspectDialog.tsx#L284)
421. 打捞工具
   来源：[src/components/ItemInspectDialog.tsx:287](../src/components/ItemInspectDialog.tsx#L287)
422. 尼龙绳 + 断裂网框
   来源：[src/components/ItemInspectDialog.tsx:288](../src/components/ItemInspectDialog.tsx#L288)
423. 网框已经恢复封闭，可承托钓钩难以稳定带回的物品。
   来源：[src/components/ItemInspectDialog.tsx:289](../src/components/ItemInspectDialog.tsx#L289)
424. 在浅色操作中拖向已观察的水下罐体
   来源：[src/components/ItemInspectDialog.tsx:290](../src/components/ItemInspectDialog.tsx#L290)
425. 密封容器
   来源：[src/components/ItemInspectDialog.tsx:293](../src/components/ItemInspectDialog.tsx#L293)
426. 启真湖水下打捞点
   来源：[src/components/ItemInspectDialog.tsx:294](../src/components/ItemInspectDialog.tsx#L294)
427. 罐盖仍然密封，摇动时能听到细小颗粒碰撞。
   来源：[src/components/ItemInspectDialog.tsx:295](../src/components/ItemInspectDialog.tsx#L295)
428. 返回安全位置后打开罐盖
   来源：[src/components/ItemInspectDialog.tsx:296](../src/components/ItemInspectDialog.tsx#L296)
429. 投喂材料
   来源：[src/components/ItemInspectDialog.tsx:299](../src/components/ItemInspectDialog.tsx#L299)
430. 密封饲料罐
   来源：[src/components/ItemInspectDialog.tsx:300](../src/components/ItemInspectDialog.tsx#L300)；[src/components/PixelIcon.tsx:886](../src/components/PixelIcon.tsx#L886)；[src/data/items.config.json:375](../src/data/items.config.json#L375)
431. 颗粒遇水后会缓慢下沉，可让鱼群在短时间内集中。
   来源：[src/components/ItemInspectDialog.tsx:301](../src/components/ItemInspectDialog.tsx#L301)
432. 在已观察的鱼群位置使用
   来源：[src/components/ItemInspectDialog.tsx:302](../src/components/ItemInspectDialog.tsx#L302)
433. 活体诱导物
   来源：[src/components/ItemInspectDialog.tsx:305](../src/components/ItemInspectDialog.tsx#L305)
434. 启真湖鱼群钓点
   来源：[src/components/ItemInspectDialog.tsx:306](../src/components/ItemInspectDialog.tsx#L306)
435. 小鲤鱼仍有活性，需要尽快完成当前湖区操作。
   来源：[src/components/ItemInspectDialog.tsx:307](../src/components/ItemInspectDialog.tsx#L307)
436. 靠近黑天鹅后进行投喂
   来源：[src/components/ItemInspectDialog.tsx:308](../src/components/ItemInspectDialog.tsx#L308)
437. 磁吸附件
   来源：[src/components/ItemInspectDialog.tsx:311](../src/components/ItemInspectDialog.tsx#L311)
438. 启真湖黑天鹅
   来源：[src/components/ItemInspectDialog.tsx:312](../src/components/ItemInspectDialog.tsx#L312)
439. 小型磁铁的固定环与钓竿末端尺寸一致。
   来源：[src/components/ItemInspectDialog.tsx:313](../src/components/ItemInspectDialog.tsx#L313)
440. 与基础钓竿组合
   来源：[src/components/ItemInspectDialog.tsx:314](../src/components/ItemInspectDialog.tsx#L314)
441. 组合工具
   来源：[src/components/ItemInspectDialog.tsx:317](../src/components/ItemInspectDialog.tsx#L317)
442. 钓竿 + 天鹅磁铁
   来源：[src/components/ItemInspectDialog.tsx:318](../src/components/ItemInspectDialog.tsx#L318)
443. 磁吸附件可接近金属夹具，同时保留钓竿的距离优势。
   来源：[src/components/ItemInspectDialog.tsx:319](../src/components/ItemInspectDialog.tsx#L319)
444. 用于捕获被夹住的纸张；返航完成后附件会损坏
   来源：[src/components/ItemInspectDialog.tsx:320](../src/components/ItemInspectDialog.tsx#L320)
445. 签到材料
   来源：[src/components/ItemInspectDialog.tsx:323](../src/components/ItemInspectDialog.tsx#L323)
446. 教学楼公告栏前
   来源：[src/components/ItemInspectDialog.tsx:324](../src/components/ItemInspectDialog.tsx#L324)
447. 这张纸先把你引回了楼里，最后也得由你把它送回签到口。
   来源：[src/components/ItemInspectDialog.tsx:325](../src/components/ItemInspectDialog.tsx#L325)
448. 晨间签到阶段拖向签到纸槽
   来源：[src/components/ItemInspectDialog.tsx:326](../src/components/ItemInspectDialog.tsx#L326)
449. 钟表部件
   来源：[src/components/ItemInspectDialog.tsx:329](../src/components/ItemInspectDialog.tsx#L329)；[src/components/ItemInspectDialog.tsx:335](../src/components/ItemInspectDialog.tsx#L335)
450. 面包店传送带边缘
   来源：[src/components/ItemInspectDialog.tsx:330](../src/components/ItemInspectDialog.tsx#L330)
451. 真正能推进时间的不是灯光，而是停带后露出来的这根旧钟时针。
   来源：[src/components/ItemInspectDialog.tsx:331](../src/components/ItemInspectDialog.tsx#L331)
452. 返回一楼旧钟，将它拖向时针插槽
   来源：[src/components/ItemInspectDialog.tsx:332](../src/components/ItemInspectDialog.tsx#L332)
453. 204 讲台抽屉
   来源：[src/components/ItemInspectDialog.tsx:336](../src/components/ItemInspectDialog.tsx#L336)
454. 它不是普通零件，而是让旧钟重新对准正确结构的定位盘。
   来源：[src/components/ItemInspectDialog.tsx:337](../src/components/ItemInspectDialog.tsx#L337)
455. 返回一楼旧钟，将它拖向定位盘插槽
   来源：[src/components/ItemInspectDialog.tsx:338](../src/components/ItemInspectDialog.tsx#L338)
456. 维修工具
   来源：[src/components/ItemInspectDialog.tsx:341](../src/components/ItemInspectDialog.tsx#L341)
457. 面包店后场
   来源：[src/components/ItemInspectDialog.tsx:342](../src/components/ItemInspectDialog.tsx#L342)
458. 长度不大，刚好适合翘开清洁车轮罩。
   来源：[src/components/ItemInspectDialog.tsx:343](../src/components/ItemInspectDialog.tsx#L343)
459. 拖向清洁车轮罩
   来源：[src/components/ItemInspectDialog.tsx:344](../src/components/ItemInspectDialog.tsx#L344)
460. 维修材料
   来源：[src/components/ItemInspectDialog.tsx:347](../src/components/ItemInspectDialog.tsx#L347)
461. 清洁车内侧
   来源：[src/components/ItemInspectDialog.tsx:348](../src/components/ItemInspectDialog.tsx#L348)
462. 先用它让清洁车恢复，再把剩下的半瓶交给旧钟齿轮。
   来源：[src/components/ItemInspectDialog.tsx:349](../src/components/ItemInspectDialog.tsx#L349)
463. 先拖向清洁车轮，再拖向旧钟齿轮
   来源：[src/components/ItemInspectDialog.tsx:350](../src/components/ItemInspectDialog.tsx#L350)
464. 时间碎片
   来源：[src/components/ItemInspectDialog.tsx:353](../src/components/ItemInspectDialog.tsx#L353)
465. 202 阶梯教室投影
   来源：[src/components/ItemInspectDialog.tsx:354](../src/components/ItemInspectDialog.tsx#L354)
466. 这是一段被偷走的最后一分钟。它只能回到旧钟分针端点。
   来源：[src/components/ItemInspectDialog.tsx:355](../src/components/ItemInspectDialog.tsx#L355)
467. 拖向旧钟分针端点，恢复 07:55
   来源：[src/components/ItemInspectDialog.tsx:356](../src/components/ItemInspectDialog.tsx#L356)
468. 关闭{{item.name}}详情
   来源：[src/components/ItemInspectDialog.tsx:458](../src/components/ItemInspectDialog.tsx#L458)
469. 分类
   来源：[src/components/ItemInspectDialog.tsx:473](../src/components/ItemInspectDialog.tsx#L473)；[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
470. 来源
   来源：[src/components/ItemInspectDialog.tsx:477](../src/components/ItemInspectDialog.tsx#L477)；[src/data/itemCatalog.ts:166](../src/data/itemCatalog.ts#L166)
471. 持卡人
   来源：[src/components/ItemInspectDialog.tsx:482](../src/components/ItemInspectDialog.tsx#L482)
472. 简介
   来源：[src/components/ItemInspectDialog.tsx:487](../src/components/ItemInspectDialog.tsx#L487)
473. 顺序：
   来源：[src/components/ItemInspectDialog.tsx:491](../src/components/ItemInspectDialog.tsx#L491)
474. 用途提示
   来源：[src/components/ItemInspectDialog.tsx:497](../src/components/ItemInspectDialog.tsx#L497)
475. {{item.name}}正文
   来源：[src/components/ItemInspectDialog.tsx:504](../src/components/ItemInspectDialog.tsx#L504)
476. 应用导航
   来源：[src/components/PhoneAppUi.tsx:109](../src/components/PhoneAppUi.tsx#L109)
477. QUICK PANEL
   来源：[src/components/PhoneAppUi.tsx:232](../src/components/PhoneAppUi.tsx#L232)
478. 关闭{{title}}
   来源：[src/components/PhoneAppUi.tsx:235](../src/components/PhoneAppUi.tsx#L235)
479. phone-app-feedback is-{{tone}} {{className}}
   来源：[src/components/PhoneAppUi.tsx:252](../src/components/PhoneAppUi.tsx#L252)
480. 7:55 scaled phone viewport
   来源：[src/components/PhoneShell.tsx:160](../src/components/PhoneShell.tsx#L160)
481. 7:55 phone runtime
   来源：[src/components/PhoneShell.tsx:162](../src/components/PhoneShell.tsx#L162)
482. 从早八雨里接住的一滴水。它看起来很普通，但已经比你更早起床。
   来源：[src/components/PixelIcon.tsx:830](../src/components/PixelIcon.tsx#L830)；[src/data/items.config.json:5](../src/data/items.config.json#L5)
483. 水滴
   来源：[src/components/PixelIcon.tsx:830](../src/components/PixelIcon.tsx#L830)；[src/data/items.config.json:4](../src/data/items.config.json#L4)
484. 从控制中心掉下来的耳机。背面朝下，像一个不太情愿的小水瓢。
   来源：[src/components/PixelIcon.tsx:831](../src/components/PixelIcon.tsx#L831)；[src/data/items.config.json:12](../src/data/items.config.json#L12)
485. 盛水的耳机
   来源：[src/components/PixelIcon.tsx:832](../src/components/PixelIcon.tsx#L832)；[src/data/items.config.json:18](../src/data/items.config.json#L18)；[src/modules/InventoryController.ts:14](../src/modules/InventoryController.ts#L14)
486. 一只装了水的耳机。音质未知，灌溉能力暂时领先。
   来源：[src/components/PixelIcon.tsx:832](../src/components/PixelIcon.tsx#L832)
487. 从设置里掉下来的齿轮。背面刻着 9，说明它一直有背着你生活。
   来源：[src/components/PixelIcon.tsx:833](../src/components/PixelIcon.tsx#L833)；[src/data/items.config.json:26](../src/data/items.config.json#L26)
488. 反转齿轮
   来源：[src/components/PixelIcon.tsx:833](../src/components/PixelIcon.tsx#L833)；[src/data/items.config.json:25](../src/data/items.config.json#L25)
489. 朋友头像上掉下来的一撇。检测到未经授权的友情支援。
   来源：[src/components/PixelIcon.tsx:834](../src/components/PixelIcon.tsx#L834)；[src/data/items.config.json:33](../src/data/items.config.json#L33)
490. 斜线
   来源：[src/components/PixelIcon.tsx:834](../src/components/PixelIcon.tsx#L834)；[src/data/items.config.json:32](../src/data/items.config.json#L32)
491. 斜线和齿轮拼成的钥匙。合法性很低，开锁欲很强。
   来源：[src/components/PixelIcon.tsx:835](../src/components/PixelIcon.tsx#L835)；[src/data/items.config.json:40](../src/data/items.config.json#L40)
492. 钥匙
   来源：[src/components/PixelIcon.tsx:835](../src/components/PixelIcon.tsx#L835)；[src/data/items.config.json:39](../src/data/items.config.json#L39)；[src/modules/InventoryController.ts:13](../src/modules/InventoryController.ts#L13)
493. 一袋肥料
   来源：[src/components/PixelIcon.tsx:836](../src/components/PixelIcon.tsx#L836)；[src/data/items.config.json:46](../src/data/items.config.json#L46)
494. 钟楼里掉出来的肥料。不要问钟楼为什么会长出农业属性。
   来源：[src/components/PixelIcon.tsx:836](../src/components/PixelIcon.tsx#L836)；[src/data/items.config.json:47](../src/data/items.config.json#L47)
495. 电子校园卡
   来源：[src/components/PixelIcon.tsx:838](../src/components/PixelIcon.tsx#L838)；[src/scenes/phone/P15_Zjuding/index.tsx:2002](../src/scenes/phone/P15_Zjuding/index.tsx#L2002)；[src/scenes/phone/P15_Zjuding/index.tsx:2004](../src/scenes/phone/P15_Zjuding/index.tsx#L2004)；[src/scenes/phone/P15_Zjuding/index.tsx:2005](../src/scenes/phone/P15_Zjuding/index.tsx#L2005)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
496. 证明你是你的卡。余额方面，它持保留意见。
   来源：[src/components/PixelIcon.tsx:839](../src/components/PixelIcon.tsx#L839)；[src/data/items.config.json:54](../src/data/items.config.json#L54)
497. 从主页推送头像里抠下来的三角形。它还没想好自己是播放键还是箭头的一部分。
   来源：[src/components/PixelIcon.tsx:841](../src/components/PixelIcon.tsx#L841)；[src/data/items.config.json:61](../src/data/items.config.json#L61)
498. 三角形
   来源：[src/components/PixelIcon.tsx:841](../src/components/PixelIcon.tsx#L841)；[src/data/items.config.json:60](../src/data/items.config.json#L60)
499. 从天气页面接到的一滴水。天气预报终于做了一件可以直接拿来用的事。
   来源：[src/components/PixelIcon.tsx:842](../src/components/PixelIcon.tsx#L842)；[src/data/items.config.json:68](../src/data/items.config.json#L68)
500. 天气水滴
   来源：[src/components/PixelIcon.tsx:842](../src/components/PixelIcon.tsx#L842)；[src/data/items.config.json:67](../src/data/items.config.json#L67)
501. 从导师头像上滑落的一条竖线。它看起来很严肃，像一句还没发完的消息。
   来源：[src/components/PixelIcon.tsx:843](../src/components/PixelIcon.tsx#L843)；[src/data/items.config.json:75](../src/data/items.config.json#L75)
502. 竖线
   来源：[src/components/PixelIcon.tsx:843](../src/components/PixelIcon.tsx#L843)；[src/data/items.config.json:74](../src/data/items.config.json#L74)
503. 能把什么东西往右移。它不解决问题，只负责让问题换个位置。
   来源：[src/components/PixelIcon.tsx:844](../src/components/PixelIcon.tsx#L844)；[src/data/items.config.json:82](../src/data/items.config.json#L82)
504. 右移箭头
   来源：[src/components/PixelIcon.tsx:844](../src/components/PixelIcon.tsx#L844)；[src/modules/InventoryController.ts:15](../src/modules/InventoryController.ts#L15)
505. 游戏手柄
   来源：[src/components/PixelIcon.tsx:845](../src/components/PixelIcon.tsx#L845)；[src/data/items.config.json:88](../src/data/items.config.json#L88)
506. CC98 二手市场六块钱成交。它让你终于可以操作自己，听起来很悲伤。
   来源：[src/components/PixelIcon.tsx:845](../src/components/PixelIcon.tsx#L845)；[src/data/items.config.json:89](../src/data/items.config.json#L89)
507. 022 座位旁的纸条，写着“主人马上回来”。拖到 CC98 搜索栏查找同类记录。
   来源：[src/components/PixelIcon.tsx:846](../src/components/PixelIcon.tsx#L846)；[src/data/items.config.json:96](../src/data/items.config.json#L96)
508. 占座纸条
   来源：[src/components/PixelIcon.tsx:846](../src/components/PixelIcon.tsx#L846)；[src/data/items.config.json:95](../src/data/items.config.json#L95)
509. 书架定位编号。拖到 755 号书架，查找旧版离座规则。
   来源：[src/components/PixelIcon.tsx:847](../src/components/PixelIcon.tsx#L847)；[src/data/items.config.json:103](../src/data/items.config.json#L103)
510. 索书号 755
   来源：[src/components/PixelIcon.tsx:847](../src/components/PixelIcon.tsx#L847)；[src/data/items.config.json:102](../src/data/items.config.json#L102)
511. 旧离座规定
   来源：[src/components/PixelIcon.tsx:848](../src/components/PixelIcon.tsx#L848)
512. 书架背面找到的旧版离座规定。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:848](../src/components/PixelIcon.tsx#L848)；[src/data/items.config.json:110](../src/data/items.config.json#L110)
513. 物品识别报告
   来源：[src/components/PixelIcon.tsx:849](../src/components/PixelIcon.tsx#L849)；[src/data/itemCatalog.ts:65](../src/data/itemCatalog.ts#L65)；[src/data/items.config.json:116](../src/data/items.config.json#L116)
514. 照片调暗后生成的书包识别报告。带到图书馆前台核验盖章。
   来源：[src/components/PixelIcon.tsx:849](../src/components/PixelIcon.tsx#L849)；[src/data/items.config.json:117](../src/data/items.config.json#L117)
515. 前台盖章后的书包非本人证明。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:850](../src/components/PixelIcon.tsx#L850)；[src/data/items.config.json:124](../src/data/items.config.json#L124)
516. 书包非本人证明
   来源：[src/components/PixelIcon.tsx:850](../src/components/PixelIcon.tsx#L850)；[src/data/itemCatalog.ts:76](../src/data/itemCatalog.ts#L76)；[src/data/items.config.json:123](../src/data/items.config.json#L123)；[src/data/presentation-cues.ts:142](../src/data/presentation-cues.ts#L142)；[src/scenes/phone/P15_Zjuding/index.tsx:195](../src/scenes/phone/P15_Zjuding/index.tsx#L195)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:105](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L105)
517. 022 座位小票
   来源：[src/components/PixelIcon.tsx:851](../src/components/PixelIcon.tsx#L851)；[src/data/items.config.json:130](../src/data/items.config.json#L130)；[src/data/presentation-cues.ts:151](../src/data/presentation-cues.ts#L151)；[src/scenes/phone/P15_Zjuding/index.tsx:201](../src/scenes/phone/P15_Zjuding/index.tsx#L201)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:106](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L106)
518. 从 022 桌下夹缝取到的小票。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:851](../src/components/PixelIcon.tsx#L851)；[src/data/items.config.json:131](../src/data/items.config.json#L131)
519. 本人来过证明
   来源：[src/components/PixelIcon.tsx:852](../src/components/PixelIcon.tsx#L852)；[src/data/itemCatalog.ts:104](../src/data/itemCatalog.ts#L104)；[src/data/items.config.json:137](../src/data/items.config.json#L137)；[src/data/presentation-cues.ts:160](../src/data/presentation-cues.ts#L160)；[src/scenes/phone/P15_Zjuding/index.tsx:207](../src/scenes/phone/P15_Zjuding/index.tsx#L207)
520. 体艺补录得到的到馆证明。上传到 CC98 作为证据。
   来源：[src/components/PixelIcon.tsx:852](../src/components/PixelIcon.tsx#L852)；[src/data/items.config.json:138](../src/data/items.config.json#L138)
521. 离座清退 PASS
   来源：[src/components/PixelIcon.tsx:853](../src/components/PixelIcon.tsx#L853)；[src/data/itemCatalog.ts:118](../src/data/itemCatalog.ts#L118)
522. 三项材料换来的清退凭证。拖到 022 书包使用。
   来源：[src/components/PixelIcon.tsx:853](../src/components/PixelIcon.tsx#L853)；[src/data/items.config.json:145](../src/data/items.config.json#L145)
523. 气泡水
   来源：[src/components/PixelIcon.tsx:856](../src/components/PixelIcon.tsx#L856)；[src/data/items.config.json:165](../src/data/items.config.json#L165)
524. 柠檬茶
   来源：[src/components/PixelIcon.tsx:857](../src/components/PixelIcon.tsx#L857)；[src/data/items.config.json:172](../src/data/items.config.json#L172)
525. 黑咖啡
   来源：[src/components/PixelIcon.tsx:858](../src/components/PixelIcon.tsx#L858)；[src/data/items.config.json:179](../src/data/items.config.json#L179)
526. 难喝饮料
   来源：[src/components/PixelIcon.tsx:859](../src/components/PixelIcon.tsx#L859)；[src/data/items.config.json:186](../src/data/items.config.json#L186)
527. 今日新品气泡水
   来源：[src/components/PixelIcon.tsx:860](../src/components/PixelIcon.tsx#L860)；[src/data/items.config.json:193](../src/data/items.config.json#L193)
528. 比较真实的包子
   来源：[src/components/PixelIcon.tsx:862](../src/components/PixelIcon.tsx#L862)；[src/data/items.config.json:207](../src/data/items.config.json#L207)
529. 没什么线索的豆浆
   来源：[src/components/PixelIcon.tsx:863](../src/components/PixelIcon.tsx#L863)；[src/data/items.config.json:214](../src/data/items.config.json#L214)
530. 世界观边缘的鸡蛋
   来源：[src/components/PixelIcon.tsx:864](../src/components/PixelIcon.tsx#L864)；[src/data/items.config.json:221](../src/data/items.config.json#L221)
531. 很热但很没用的白粥
   来源：[src/components/PixelIcon.tsx:865](../src/components/PixelIcon.tsx#L865)；[src/data/items.config.json:228](../src/data/items.config.json#L228)
532. 节目单残页·开场
   来源：[src/components/PixelIcon.tsx:869](../src/components/PixelIcon.tsx#L869)；[src/data/items.config.json:256](../src/data/items.config.json#L256)
533. 节目单残页·追光
   来源：[src/components/PixelIcon.tsx:870](../src/components/PixelIcon.tsx#L870)；[src/data/items.config.json:263](../src/data/items.config.json#L263)
534. 节目单残页·谢幕
   来源：[src/components/PixelIcon.tsx:871](../src/components/PixelIcon.tsx#L871)；[src/data/items.config.json:270](../src/data/items.config.json#L270)
535. 桥边
   来源：[src/components/PixelIcon.tsx:876](../src/components/PixelIcon.tsx#L876)；[src/data/items.config.json:305](../src/data/items.config.json#L305)；[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
536. CC98 目击者留下的地点关键词。
   来源：[src/components/PixelIcon.tsx:876](../src/components/PixelIcon.tsx#L876)；[src/data/items.config.json:306](../src/data/items.config.json#L306)
537. 倒影
   来源：[src/components/PixelIcon.tsx:877](../src/components/PixelIcon.tsx#L877)；[src/data/items.config.json:312](../src/data/items.config.json#L312)；[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
538. 馆藏系统留下的地点关键词。
   来源：[src/components/PixelIcon.tsx:877](../src/components/PixelIcon.tsx#L877)；[src/data/items.config.json:313](../src/data/items.config.json#L313)
539. 湖
   来源：[src/components/PixelIcon.tsx:878](../src/components/PixelIcon.tsx#L878)；[src/data/items.config.json:319](../src/data/items.config.json#L319)
540. 微信消息留下的地点关键词。
   来源：[src/components/PixelIcon.tsx:878](../src/components/PixelIcon.tsx#L878)；[src/data/items.config.json:320](../src/data/items.config.json#L320)
541. 倒影坐标
   来源：[src/components/PixelIcon.tsx:879](../src/components/PixelIcon.tsx#L879)；[src/data/itemCatalog.ts:183](../src/data/itemCatalog.ts#L183)；[src/data/items.config.json:326](../src/data/items.config.json#L326)
542. 两种观察模式共同确认的位置。
   来源：[src/components/PixelIcon.tsx:879](../src/components/PixelIcon.tsx#L879)；[src/data/items.config.json:327](../src/data/items.config.json#L327)
543. 从自己的书桌取得，可在天气页面推动湖区云带。
   来源：[src/components/PixelIcon.tsx:880](../src/components/PixelIcon.tsx#L880)
544. 寝室吹风机
   来源：[src/components/PixelIcon.tsx:880](../src/components/PixelIcon.tsx#L880)；[src/data/items.config.json:333](../src/data/items.config.json#L333)
545. 钓竿
   来源：[src/components/PixelIcon.tsx:881](../src/components/PixelIcon.tsx#L881)；[src/data/items.config.json:340](../src/data/items.config.json#L340)
546. 码头装备架上的基础钓竿，可安装诱饵或磁吸附件。
   来源：[src/components/PixelIcon.tsx:881](../src/components/PixelIcon.tsx#L881)；[src/data/items.config.json:341](../src/data/items.config.json#L341)
547. 从湖中钓起的旧钥匙，表面锈迹与码头储物柜一致。
   来源：[src/components/PixelIcon.tsx:882](../src/components/PixelIcon.tsx#L882)；[src/data/items.config.json:348](../src/data/items.config.json#L348)
548. 锈蚀柜钥匙
   来源：[src/components/PixelIcon.tsx:882](../src/components/PixelIcon.tsx#L882)；[src/data/items.config.json:347](../src/data/items.config.json#L347)
549. 储物柜内的耐水尼龙绳，长度足够固定一圈网框。
   来源：[src/components/PixelIcon.tsx:883](../src/components/PixelIcon.tsx#L883)；[src/data/items.config.json:355](../src/data/items.config.json#L355)
550. 尼龙绳
   来源：[src/components/PixelIcon.tsx:883](../src/components/PixelIcon.tsx#L883)；[src/data/items.config.json:354](../src/data/items.config.json#L354)
551. 从水下钓起的旧网框，网面已经脱落。
   来源：[src/components/PixelIcon.tsx:884](../src/components/PixelIcon.tsx#L884)；[src/data/items.config.json:362](../src/data/items.config.json#L362)
552. 断裂网框
   来源：[src/components/PixelIcon.tsx:884](../src/components/PixelIcon.tsx#L884)；[src/data/items.config.json:361](../src/data/items.config.json#L361)
553. 临时抄网
   来源：[src/components/PixelIcon.tsx:885](../src/components/PixelIcon.tsx#L885)；[src/data/items.config.json:368](../src/data/items.config.json#L368)；[src/modules/InventoryController.ts:17](../src/modules/InventoryController.ts#L17)
554. 用尼龙绳修复的网框，可打捞钓钩无法稳定带回的物品。
   来源：[src/components/PixelIcon.tsx:885](../src/components/PixelIcon.tsx#L885)；[src/data/items.config.json:369](../src/data/items.config.json#L369)
555. 从水中捞出的密封金属罐，内部有颗粒滚动声。
   来源：[src/components/PixelIcon.tsx:886](../src/components/PixelIcon.tsx#L886)；[src/data/items.config.json:376](../src/data/items.config.json#L376)
556. 密封罐中的鱼食，可用于吸引小型鱼群靠近。
   来源：[src/components/PixelIcon.tsx:887](../src/components/PixelIcon.tsx#L887)；[src/data/items.config.json:383](../src/data/items.config.json#L383)
557. 鱼食颗粒
   来源：[src/components/PixelIcon.tsx:887](../src/components/PixelIcon.tsx#L887)；[src/data/items.config.json:382](../src/data/items.config.json#L382)
558. 记录 A
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
559. 记录 B
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
560. 记录 C
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
561. 当前任务
   来源：[src/components/QuestClueStrip.tsx:165](../src/components/QuestClueStrip.tsx#L165)；[src/components/QuestClueStrip.tsx:208](../src/components/QuestClueStrip.tsx#L208)
562. {{CHAPTER\_LABEL\[quest.chapter\]}}当前任务：{{parallelObjective}}{{chapterFourAria}}{{showDigitHint ? \`。${digitHintAria}\` : ""}}。点击查看任务提示
   来源：[src/components/QuestClueStrip.tsx:172](../src/components/QuestClueStrip.tsx#L172)
563. 点击查看当前任务和提示
   来源：[src/components/QuestClueStrip.tsx:175](../src/components/QuestClueStrip.tsx#L175)
564. 收起任务
   来源：[src/components/QuestClueStrip.tsx:185](../src/components/QuestClueStrip.tsx#L185)
565. 签到码
   来源：[src/components/QuestClueStrip.tsx:186](../src/components/QuestClueStrip.tsx#L186)
566. 任务详情
   来源：[src/components/QuestClueStrip.tsx:197](../src/components/QuestClueStrip.tsx#L197)
567. 任务栏
   来源：[src/components/QuestClueStrip.tsx:202](../src/components/QuestClueStrip.tsx#L202)
568. 关闭任务详情
   来源：[src/components/QuestClueStrip.tsx:204](../src/components/QuestClueStrip.tsx#L204)
569. 并行调查 {{parallelProgress.completed}}/{{parallelProgress.total}}
   来源：[src/components/QuestClueStrip.tsx:215](../src/components/QuestClueStrip.tsx#L215)
570. 并行调查环
   来源：[src/components/QuestClueStrip.tsx:217](../src/components/QuestClueStrip.tsx#L217)
571. 调查分支
   来源：[src/components/QuestClueStrip.tsx:220](../src/components/QuestClueStrip.tsx#L220)
572. 环上节点没有提交先后；选择节点后返回现场，就近调查
   来源：[src/components/QuestClueStrip.tsx:222](../src/components/QuestClueStrip.tsx#L222)
573. 环上节点没有提交先后；方向键切换节点，回车或空格打开
   来源：[src/components/QuestClueStrip.tsx:223](../src/components/QuestClueStrip.tsx#L223)
574. completed
   来源：[src/components/QuestClueStrip.tsx:228](../src/components/QuestClueStrip.tsx#L228)；[src/core/QuestModel.ts:36](../src/core/QuestModel.ts#L36)
575. 可重新查看
   来源：[src/components/QuestClueStrip.tsx:229](../src/components/QuestClueStrip.tsx#L229)
576. 可直接开始
   来源：[src/components/QuestClueStrip.tsx:231](../src/components/QuestClueStrip.tsx#L231)
577. 就近调查
   来源：[src/components/QuestClueStrip.tsx:232](../src/components/QuestClueStrip.tsx#L232)
578. 待处理
   来源：[src/components/QuestClueStrip.tsx:234](../src/components/QuestClueStrip.tsx#L234)
579. 已完成
   来源：[src/components/QuestClueStrip.tsx:234](../src/components/QuestClueStrip.tsx#L234)
580. 第
   来源：[src/components/QuestClueStrip.tsx:301](../src/components/QuestClueStrip.tsx#L301)
581. 位
   来源：[src/components/QuestClueStrip.tsx:301](../src/components/QuestClueStrip.tsx#L301)；[src/scenes/phone/P15_Zjuding/index.tsx:1423](../src/scenes/phone/P15_Zjuding/index.tsx#L1423)；[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:76](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L76)
582. 任务提示
   来源：[src/components/QuestClueStrip.tsx:309](../src/components/QuestClueStrip.tsx#L309)；[src/components/QuestClueStrip.tsx:311](../src/components/QuestClueStrip.tsx#L311)
583. 当前任务没有提示。
   来源：[src/components/QuestClueStrip.tsx:314](../src/components/QuestClueStrip.tsx#L314)
584. 需要时点击下方按钮，逐条查看提示。
   来源：[src/components/QuestClueStrip.tsx:315](../src/components/QuestClueStrip.tsx#L315)
585. 提示已全部展开
   来源：[src/components/QuestClueStrip.tsx:325](../src/components/QuestClueStrip.tsx#L325)
586. 显示下一条提示
   来源：[src/components/QuestClueStrip.tsx:325](../src/components/QuestClueStrip.tsx#L325)
587. 校时表冠：按住并绕圈拖动以校时
   来源：[src/components/RpgClockCrownOverlay.tsx:88](../src/components/RpgClockCrownOverlay.tsx#L88)
588. Back to desktop
   来源：[src/components/ScenePlaceholder.tsx:24](../src/components/ScenePlaceholder.tsx#L24)
589. 流量
   来源：[src/components/StatusBar.tsx:59](../src/components/StatusBar.tsx#L59)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
590. 无服务
   来源：[src/components/StatusBar.tsx:69](../src/components/StatusBar.tsx#L69)
591. 17%
   来源：[src/components/StatusBar.tsx:71](../src/components/StatusBar.tsx#L71)
592. active
   来源：[src/core/QuestModel.ts:36](../src/core/QuestModel.ts#L36)；[src/scenes/rpg/RpgGameHost.tsx:1440](../src/scenes/rpg/RpgGameHost.tsx#L1440)
593. locked
   来源：[src/core/QuestModel.ts:36](../src/core/QuestModel.ts#L36)；[src/modules/Cc98UnifiedLoginModel.ts:80](../src/modules/Cc98UnifiedLoginModel.ts#L80)；[src/scenes/phone/P02_CC98/index.tsx:317](../src/scenes/phone/P02_CC98/index.tsx#L317)；[src/scenes/rpg/BootScene.ts:567](../src/scenes/rpg/BootScene.ts#L567)；[src/scenes/rpg/RpgGameHost.tsx:1440](../src/scenes/rpg/RpgGameHost.tsx#L1440)；[src/scenes/rpg/RpgGameHost.tsx:1533](../src/scenes/rpg/RpgGameHost.tsx#L1533)；[src/scenes/rpg/RpgGameHost.tsx:1552](../src/scenes/rpg/RpgGameHost.tsx#L1552)；[src/scenes/rpg/RpgGameHost.tsx:1560](../src/scenes/rpg/RpgGameHost.tsx#L1560)；[src/scenes/rpg/RpgGameHost.tsx:1572](../src/scenes/rpg/RpgGameHost.tsx#L1572)；[src/scenes/rpg/RpgGameHost.tsx:1585](../src/scenes/rpg/RpgGameHost.tsx#L1585)；[src/scenes/rpg/RpgGameHost.tsx:1610](../src/scenes/rpg/RpgGameHost.tsx#L1610)；[src/scenes/rpg/RpgGameHost.tsx:1620](../src/scenes/rpg/RpgGameHost.tsx#L1620)；[src/scenes/rpg/RpgGameHost.tsx:1627](../src/scenes/rpg/RpgGameHost.tsx#L1627)；[src/scenes/rpg/RpgItemUseGuidance.ts:49](../src/scenes/rpg/RpgItemUseGuidance.ts#L49)
594. 在寝室找一件能用的设备
   来源：[src/core/QuestModel.ts:399](../src/core/QuestModel.ts#L399)
595. 检查自己的书桌。
   来源：[src/core/QuestModel.ts:400](../src/core/QuestModel.ts#L400)
596. 处理启真湖的天气记录
   来源：[src/core/QuestModel.ts:404](../src/core/QuestModel.ts#L404)
597. 打开手机天气页面。
   来源：[src/core/QuestModel.ts:405](../src/core/QuestModel.ts#L405)
598. 完成湖区三处分支 {{branchCount}}/3
   来源：[src/core/QuestModel.ts:430](../src/core/QuestModel.ts#L430)
599. 码头柜门：钓起钥匙并打开柜门。
   来源：[src/core/QuestModel.ts:431](../src/core/QuestModel.ts#L431)
600. 码头柜门：已取得尼龙绳。
   来源：[src/core/QuestModel.ts:431](../src/core/QuestModel.ts#L431)
601. 浮排分支：已取得破损网框。
   来源：[src/core/QuestModel.ts:432](../src/core/QuestModel.ts#L432)
602. 浮排分支：在直河道钓起破损网框。
   来源：[src/core/QuestModel.ts:432](../src/core/QuestModel.ts#L432)
603. 天鹅分支：前往围栏处理旧饲料盒。
   来源：[src/core/QuestModel.ts:433](../src/core/QuestModel.ts#L433)
604. 天鹅分支：已取得磁性扣。
   来源：[src/core/QuestModel.ts:433](../src/core/QuestModel.ts#L433)
605. 三个分支可以任意顺序完成。
   来源：[src/core/QuestModel.ts:434](../src/core/QuestModel.ts#L434)
606. 合并三处分支材料
   来源：[src/core/QuestModel.ts:437](../src/core/QuestModel.ts#L437)
607. 返回大湖面的最终钓具装配位。
   来源：[src/core/QuestModel.ts:438](../src/core/QuestModel.ts#L438)
608. 将尼龙绳、破损网框、磁性扣和钓鱼竿放入装配位。
   来源：[src/core/QuestModel.ts:439](../src/core/QuestModel.ts#L439)
609. 按货架顺序调配今日新品（{{hunt.drinkMixSequence.length}}/3）
   来源：[src/core/QuestModel.ts:493](../src/core/QuestModel.ts#L493)
610. 从饮料机取得三种饮料，再到调配台按黑色、蓝色、白色依次倒入。
   来源：[src/core/QuestModel.ts:494](../src/core/QuestModel.ts#L494)
611. 把今日新品气泡水放入宣传板空杯位
   来源：[src/core/QuestModel.ts:498](../src/core/QuestModel.ts#L498)
612. 目标位在第三窗口宣传板下方。
   来源：[src/core/QuestModel.ts:498](../src/core/QuestModel.ts#L498)
613. 等待第三列队伍让出位置
   来源：[src/core/QuestModel.ts:500](../src/core/QuestModel.ts#L500)
614. 在点餐机选择纸包鸡
   来源：[src/core/QuestModel.ts:505](../src/core/QuestModel.ts#L505)
615. 点餐后会取得 0755 取餐号。
   来源：[src/core/QuestModel.ts:506](../src/core/QuestModel.ts#L506)
616. 浅色操作可直接点餐；深色观察可补充读取异常菜单文字。
   来源：[src/core/QuestModel.ts:506](../src/core/QuestModel.ts#L506)
617. 把 0755 取餐号交给 3 号窗口
   来源：[src/core/QuestModel.ts:512](../src/core/QuestModel.ts#L512)
618. 浅色操作可直接交票；深色观察可补充查看 3 号窗口残影。
   来源：[src/core/QuestModel.ts:513](../src/core/QuestModel.ts#L513)
619. 守住纸条可能逃离的出口（{{hunt.blockHits}}/3）
   来源：[src/core/QuestModel.ts:519](../src/core/QuestModel.ts#L519)
620. 空格键可以冲刺；纸条回头时路线会再次出现。
   来源：[src/core/QuestModel.ts:520](../src/core/QuestModel.ts#L520)
621. 浅色操作可推动当前路线上的餐盘车；深色观察可补充确认蓝色轨迹。
   来源：[src/core/QuestModel.ts:520](../src/core/QuestModel.ts#L520)
622. 回到交通核心，在仍有历史残影的楼层核对旧导视。
   来源：[src/core/QuestModel.ts:1186](../src/core/QuestModel.ts#L1186)
623. 求是路况员
   来源：[src/data/cc98.posts.json:4](../src/data/cc98.posts.json#L4)
624. 交通出行
   来源：[src/data/cc98.posts.json:7](../src/data/cc98.posts.json#L7)；[src/data/cc98.posts.json:286](../src/data/cc98.posts.json#L286)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
625. 考试结束十分钟，求是潮哪边还能走
   来源：[src/data/cc98.posts.json:8](../src/data/cc98.posts.json#L8)
626. 26-07-10 17:42
   来源：[src/data/cc98.posts.json:11](../src/data/cc98.posts.json#L11)
627. 刚从东侧绕出来。教学区北侧的人行道还能连续走，东侧车流已经堵成两段。
   来源：[src/data/cc98.posts.json:12](../src/data/cc98.posts.json#L12)
628. 标记为实时路况
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
629. 回复区已经形成三条不同绕行路线
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
630. 路况互助机器人
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
631. 17:41 出考场，17:44 还在北口。东边四排车没动，北侧多走两分钟能过。
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)
632. 2楼
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)；[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)；[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)；[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)；[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)；[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)；[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)；[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)；[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)；[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)；[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)；[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)；[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)；[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)；[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)；[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)；[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)；[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)；[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)；[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)；[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)；[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)；[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)；[src/scenes/phone/P02_CC98/index.tsx:113](../src/scenes/phone/P02_CC98/index.tsx#L113)；[src/scenes/phone/P02_CC98/index.tsx:440](../src/scenes/phone/P02_CC98/index.tsx#L440)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:43](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L43)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:44](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L44)
633. 今天 17:44
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)
634. 前排
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)
635. 3楼
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)；[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)；[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)；[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)；[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)；[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)；[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)；[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)；[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)；[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)；[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)；[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)；[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)；[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)；[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)；[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)；[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)；[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)；[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)；[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)；[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)；[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)；[src/scenes/phone/P02_CC98/index.tsx:123](../src/scenes/phone/P02_CC98/index.tsx#L123)；[src/scenes/phone/P02_CC98/index.tsx:441](../src/scenes/phone/P02_CC98/index.tsx#L441)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:53](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L53)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:54](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L54)
636. 北边树下还有空路，风也从那边过。走北侧，别跟车流挤。
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)
637. 建议
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)；[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)；[src/scenes/phone/P07_Weather/index.tsx:103](../src/scenes/phone/P07_Weather/index.tsx#L103)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
638. 今天 17:45
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)；[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)
639. 4楼
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)；[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)；[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)；[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)；[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)；[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)；[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)；[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)；[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)；[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)；[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)；[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)；[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)；[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)；[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)；[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)；[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)；[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)；[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)；[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)；[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)；[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)；[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)；[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)；[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)；[src/scenes/phone/P02_CC98/index.tsx:134](../src/scenes/phone/P02_CC98/index.tsx#L134)
640. 二南门口横着停的共享单车还在。北口靠左走，别贴着那辆车。
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)
641. 今天 17:47
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)
642. 路况
   来源：[src/data/cc98.posts.json:18](../src/data/cc98.posts.json#L18)；[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)
643. 5楼
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)；[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)；[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)；[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)；[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)；[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)；[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)；[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)；[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)；[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)；[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)；[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)；[src/scenes/phone/P02_CC98/index.tsx:145](../src/scenes/phone/P02_CC98/index.tsx#L145)
644. 今天 17:49
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)；[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
645. 实况
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)
646. 我刚骑完北侧绿道，过两个路口没停。东侧第一个口已经堵满。
   来源：[src/data/cc98.posts.json:19](../src/data/cc98.posts.json#L19)
647. 6楼
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)；[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)；[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)；[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)；[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)；[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)；[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)；[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
648. 今天 17:51
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)
649. 我没有余额换车，推着现有这辆从北侧过了。北侧确实更省时间。
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)
650. 预算
   来源：[src/data/cc98.posts.json:20](../src/data/cc98.posts.json#L20)
651. 7楼
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)；[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)；[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)；[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)；[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)；[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)；[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)；[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)；[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)；[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)
652. 报数
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)
653. 记录里写清楚，北侧可通，东侧拥堵。走人行道，别把车推进行人堆。
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)
654. 今天 17:54
   来源：[src/data/cc98.posts.json:21](../src/data/cc98.posts.json#L21)
655. 二南守座人
   来源：[src/data/cc98.posts.json:26](../src/data/cc98.posts.json#L26)
656. 图书馆
   来源：[src/data/cc98.posts.json:29](../src/data/cc98.posts.json#L29)；[src/data/cc98.posts.json:344](../src/data/cc98.posts.json#L344)；[src/scenes/phone/P02_CC98/index.tsx:197](../src/scenes/phone/P02_CC98/index.tsx#L197)；[src/scenes/phone/P13_PhoneHome/index.tsx:768](../src/scenes/phone/P13_PhoneHome/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:125](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L125)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:485](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L485)
657. 二层南临时离座规则更新了吗
   来源：[src/data/cc98.posts.json:30](../src/data/cc98.posts.json#L30)
658. 26-07-10 17:39
   来源：[src/data/cc98.posts.json:33](../src/data/cc98.posts.json#L33)
659. 离座超过三分钟后，原座位会重新开放。完成校园卡核验后，可在选座页申请恢复一次。
   来源：[src/data/cc98.posts.json:34](../src/data/cc98.posts.json#L34)
660. 补充规则入口
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
661. 馆内秩序值班台
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
662. 原帖只有结果，没有说明恢复材料
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
663. 17:40 去接水，17:43 回来，页面已经换成别人的编号。先留好时间戳。
   来源：[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)
664. 今天 17:41
   来源：[src/data/cc98.posts.json:38](../src/data/cc98.posts.json#L38)；[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
665. 带图
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)
666. 今天 17:43
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)
667. 先帮顶。人还没坐回去，这条帖先别被新消息刷掉。
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)
668. bd
   来源：[src/data/cc98.posts.json:39](../src/data/cc98.posts.json#L39)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:57](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L57)
669. 022 桌上的书包三天没动。它比大多数人更符合“长期使用”这一项。
   来源：[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)
670. 提案
   来源：[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)
671. 今天 17:48
   来源：[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)
672. 经历
   来源：[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)；[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)；[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)；[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)
673. 我去接水 2 分 59 秒，回到门口刚好三分钟。座位已经换号。
   来源：[src/data/cc98.posts.json:41](../src/data/cc98.posts.json#L41)
674. 0.06 元可以做身份核验，恢复申请还是要补材料。
   来源：[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)
675. 今天 17:50
   来源：[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)
676. 资产
   来源：[src/data/cc98.posts.json:42](../src/data/cc98.posts.json#L42)
677. 今天 17:53
   来源：[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)
678. 理论
   来源：[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)
679. 需要留下离座时长和校园卡核验两项记录。满足后才能申请恢复。
   来源：[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)
680. 资料索引机
   来源：[src/data/cc98.posts.json:48](../src/data/cc98.posts.json#L48)
681. 学习天地
   来源：[src/data/cc98.posts.json:51](../src/data/cc98.posts.json#L51)；[src/data/cc98.posts.json:205](../src/data/cc98.posts.json#L205)；[src/data/cc98.posts.json:306](../src/data/cc98.posts.json#L306)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:195](../src/scenes/phone/P02_CC98/index.tsx#L195)
682. 期末资料按课程和年份整理好了
   来源：[src/data/cc98.posts.json:52](../src/data/cc98.posts.json#L52)
683. 26-07-10 17:35
   来源：[src/data/cc98.posts.json:55](../src/data/cc98.posts.json#L55)
684. 资料按课程、教师和年份建立索引。搜索时只记得两个字也能定位到对应目录。
   来源：[src/data/cc98.posts.json:56](../src/data/cc98.posts.json#L56)
685. 加入版面索引
   来源：[src/data/cc98.posts.json:57](../src/data/cc98.posts.json#L57)
686. 目录结构和版本信息均可核对
   来源：[src/data/cc98.posts.json:57](../src/data/cc98.posts.json#L57)
687. 资料版值班员
   来源：[src/data/cc98.posts.json:57](../src/data/cc98.posts.json#L57)；[src/data/cc98.posts.json:312](../src/data/cc98.posts.json#L312)
688. 今天 17:37
   来源：[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)；[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)
689. 求助
   来源：[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)
690. 文件名写成“最终版5真的最终版”的那份，能不能把交稿时间也写进文件名。
   来源：[src/data/cc98.posts.json:60](../src/data/cc98.posts.json#L60)
691. “老师说不考”我会单独存。考试前夜总有人去翻这个文件夹。
   来源：[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)
692. 今天 17:39
   来源：[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)
693. 保留
   来源：[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
694. 高数目录里的图书馆规则别删，022 这次要靠它确认座位。
   来源：[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
695. 反向实测
   来源：[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)
696. 我输入完整课程名，首页先给了三条选课通知。索引能不能再靠前一点？
   来源：[src/data/cc98.posts.json:63](../src/data/cc98.posts.json#L63)
697. 今天 17:46
   来源：[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)
698. 下载
   来源：[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)；[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
699. 资料不用钱，下载到 99% 断掉后，我得再付一遍流量。
   来源：[src/data/cc98.posts.json:64](../src/data/cc98.posts.json#L64)
700. 蹲蹲
   来源：[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
701. 请补版本日期、页数和来源。只有“最终版”，我无法判断是哪一天的最终版。
   来源：[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
702. 六分钱余额
   来源：[src/data/cc98.posts.json:70](../src/data/cc98.posts.json#L70)
703. 校园卡
   来源：[src/data/cc98.posts.json:73](../src/data/cc98.posts.json#L73)；[src/data/cc98.posts.json:363](../src/data/cc98.posts.json#L363)；[src/data/cc98.posts.json:478](../src/data/cc98.posts.json#L478)；[src/data/items.config.json:53](../src/data/items.config.json#L53)；[src/scenes/phone/P02_CC98/index.tsx:201](../src/scenes/phone/P02_CC98/index.tsx#L201)
704. 余额 0.06 元能通过临时离座校验吗
   来源：[src/data/cc98.posts.json:74](../src/data/cc98.posts.json#L74)
705. 26-07-10 17:31
   来源：[src/data/cc98.posts.json:77](../src/data/cc98.posts.json#L77)
706. 实测可以。余额不会影响身份校验，系统仍然要求完整走完验证流程。
   来源：[src/data/cc98.posts.json:78](../src/data/cc98.posts.json#L78)
707. 标记为已实测
   来源：[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)
708. 楼主提供了低余额条件下的完整结果
   来源：[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)
709. 校园卡民间客服
   来源：[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)；[src/data/cc98.posts.json:369](../src/data/cc98.posts.json#L369)；[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
710. 0.06 元能刷身份，打印一面还差一点。至少时间戳能留下。
   来源：[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)
711. 今天 17:33
   来源：[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)；[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)
712. 实测
   来源：[src/data/cc98.posts.json:82](../src/data/cc98.posts.json#L82)；[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)；[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)
713. 今天 17:35
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)
714. 刷卡声很响，余额数字很小。旁边排队的人全听见了。
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)
715. 现场
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)；[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)；[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
716. 门禁只看校园卡身份，余额写在另一个页面。我在入口看过。
   来源：[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)
717. 成本
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
718. 从求是潮骑去充值点再回来，比这次校验本身久。
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
719. 今天 17:40
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
720. 本人
   来源：[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)
721. 今天 17:42
   来源：[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)；[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)
722. 楼主在。0.06 元够我做身份核验，其他事要等以后。
   来源：[src/data/cc98.posts.json:86](../src/data/cc98.posts.json#L86)
723. 实测结果已留档。低余额可核验，恢复申请仍要完成。
   来源：[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)
724. 众筹
   来源：[src/data/cc98.posts.json:87](../src/data/cc98.posts.json#L87)
725. 体艺第47次
   来源：[src/data/cc98.posts.json:92](../src/data/cc98.posts.json#L92)
726. 校园生活
   来源：[src/data/cc98.posts.json:95](../src/data/cc98.posts.json#L95)；[src/data/cc98.posts.json:183](../src/data/cc98.posts.json#L183)；[src/data/cc98.posts.json:227](../src/data/cc98.posts.json#L227)；[src/data/cc98.posts.json:459](../src/data/cc98.posts.json#L459)；[src/scenes/phone/P02_CC98/index.tsx:59](../src/scenes/phone/P02_CC98/index.tsx#L59)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:193](../src/scenes/phone/P02_CC98/index.tsx#L193)
727. 今天的运动记录全是绕自行车
   来源：[src/data/cc98.posts.json:96](../src/data/cc98.posts.json#L96)
728. 26-07-10 17:28
   来源：[src/data/cc98.posts.json:99](../src/data/cc98.posts.json#L99)
729. 体艺记录显示四十七次通行，实际过程是在求是潮两侧反复寻找能走的缝隙。
   来源：[src/data/cc98.posts.json:100](../src/data/cc98.posts.json#L100)
730. 计入特殊路线样本
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
731. 课外锻炼观察组
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
732. 路线确有移动，运动目的暂无法判断
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
733. 从 17:28 到 17:42，我绕同一辆车四十七次。打印队都没它绕得久。
   来源：[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)
734. 分账
   来源：[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)
735. 今天 17:30
   来源：[src/data/cc98.posts.json:104](../src/data/cc98.posts.json#L104)；[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)；[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)
736. 北口风大，人走得慢。三步一停，体艺还是把它记成通行。
   来源：[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)
737. 今天 17:32
   来源：[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)；[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)
738. 逆风
   来源：[src/data/cc98.posts.json:105](../src/data/cc98.posts.json#L105)
739. 二南门口那辆车一直横在外侧，旁边还有一辆车把它挡住。
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)
740. 今天 17:34
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
741. 命名
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)
742. 车流在路口回堵，骑车的人掉头，步行的人跟着让。两分钟没过一个灯。
   来源：[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)
743. 今天 17:36
   来源：[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)
744. 步数进账了，目的地没到。体艺记录和我今天的路线各算各的。
   来源：[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)
745. 收益
   来源：[src/data/cc98.posts.json:108](../src/data/cc98.posts.json#L108)
746. 凑整
   来源：[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)
747. 记录有效。位移反复发生，终点未到。这条路线该单列。
   来源：[src/data/cc98.posts.json:109](../src/data/cc98.posts.json#L109)
748. 西区打印排队中
   来源：[src/data/cc98.posts.json:114](../src/data/cc98.posts.json#L114)
749. 打印服务
   来源：[src/data/cc98.posts.json:117](../src/data/cc98.posts.json#L117)；[src/data/cc98.posts.json:325](../src/data/cc98.posts.json#L325)；[src/scenes/phone/P02_CC98/index.tsx:200](../src/scenes/phone/P02_CC98/index.tsx#L200)
750. 西区打印店早上哪台机快一点
   来源：[src/data/cc98.posts.json:118](../src/data/cc98.posts.json#L118)
751. 26-07-10 17:24
   来源：[src/data/cc98.posts.json:121](../src/data/cc98.posts.json#L121)
752. 今天 08:10 到西区打印店，前面有六个人。双面黑白先空出来，彩打那台一直在换纸。赶早课的可以先打黑白。
   来源：[src/data/cc98.posts.json:122](../src/data/cc98.posts.json#L122)
753. 补充机器状态
   来源：[src/data/cc98.posts.json:123](../src/data/cc98.posts.json#L123)
754. 打印店排队记录员
   来源：[src/data/cc98.posts.json:123](../src/data/cc98.posts.json#L123)；[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)
755. 楼主记录了到店时间和两台机器的使用情况
   来源：[src/data/cc98.posts.json:123](../src/data/cc98.posts.json#L123)
756. 08:13 我在左边那台打完 18 页，自动双面没有卡纸。
   来源：[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)
757. 今天 17:26
   来源：[src/data/cc98.posts.json:126](../src/data/cc98.posts.json#L126)；[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
758. 今天 17:28
   来源：[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)；[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
759. 门口的取件架今天挪到右手边，拿完别站在入口数页码。
   来源：[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)
760. 提醒
   来源：[src/data/cc98.posts.json:127](../src/data/cc98.posts.json#L127)；[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)；[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)；[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)；[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)；[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)；[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)；[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)；[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)
761. 细节
   来源：[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)
762. 装订机旁边那台需要先在屏幕上选纸型，直接塞纸会退回。
   来源：[src/data/cc98.posts.json:128](../src/data/cc98.posts.json#L128)
763. 从西区食堂后门过去，08:20 还不用排到台阶上。
   来源：[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)
764. 路线
   来源：[src/data/cc98.posts.json:129](../src/data/cc98.posts.json#L129)；[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)
765. 付款
   来源：[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
766. 校园卡余额不够时可以先用手机付，机器会保留刚才选的份数。
   来源：[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
767. 把到店时间、机器编号和纸张规格写在订单上，之后找文件方便。
   来源：[src/data/cc98.posts.json:131](../src/data/cc98.posts.json#L131)
768. 闭馆后找座位
   来源：[src/data/cc98.posts.json:136](../src/data/cc98.posts.json#L136)
769. 自习室
   来源：[src/data/cc98.posts.json:139](../src/data/cc98.posts.json#L139)；[src/data/cc98.posts.json:497](../src/data/cc98.posts.json#L497)；[src/scenes/phone/P02_CC98/index.tsx:198](../src/scenes/phone/P02_CC98/index.tsx#L198)
770. 基础图书馆闭馆后还有安静的位置吗
   来源：[src/data/cc98.posts.json:140](../src/data/cc98.posts.json#L140)
771. 26-07-10 17:21
   来源：[src/data/cc98.posts.json:143](../src/data/cc98.posts.json#L143)
772. 昨晚 19:35 从基础图书馆二楼出来，雨衣没带，就去麦斯威靠窗那排坐到 20:10。插座在桌脚边，带长线会好用一点。
   来源：[src/data/cc98.posts.json:144](../src/data/cc98.posts.json#L144)
773. 加入自习地点索引
   来源：[src/data/cc98.posts.json:145](../src/data/cc98.posts.json#L145)
774. 帖子提供了闭馆后的实际座位和插座位置
   来源：[src/data/cc98.posts.json:145](../src/data/cc98.posts.json#L145)
775. 夜间自习信息台
   来源：[src/data/cc98.posts.json:145](../src/data/cc98.posts.json#L145)；[src/data/cc98.posts.json:503](../src/data/cc98.posts.json#L503)
776. 补充
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)；[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)；[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)；[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)；[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)；[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)
777. 今天 17:23
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)；[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)
778. 麦斯威二楼 19:50 还有空桌，靠窗的位置灯比较亮。
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)
779. 今天 17:25
   来源：[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)
780. 雨天
   来源：[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)
781. 昨晚雨大，门口地垫湿了。伞先套袋再进座位区。
   来源：[src/data/cc98.posts.json:149](../src/data/cc98.posts.json#L149)
782. 插座
   来源：[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)
783. 今天 17:27
   来源：[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)；[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)
784. 靠墙第三张桌的插座松，手机充电会断，电脑最好接靠柱子的那排。
   来源：[src/data/cc98.posts.json:150](../src/data/cc98.posts.json#L150)
785. 到店
   来源：[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)
786. 今天 17:29
   来源：[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)
787. 我 20:05 从东门进，店里有人开线上会议，想安静写题记得带耳塞。
   来源：[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)
788. 今天 17:31
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
789. 热水要在一楼吧台旁接，带杯子比临时买饮料省时间。
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
790. 消费
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
791. 离开前看一下桌面和插座，闭馆后的座位没有统一失物招领提醒。
   来源：[src/data/cc98.posts.json:153](../src/data/cc98.posts.json#L153)
792. 三楼最后一勺
   来源：[src/data/cc98.posts.json:158](../src/data/cc98.posts.json#L158)
793. 食堂
   来源：[src/data/cc98.posts.json:161](../src/data/cc98.posts.json#L161)；[src/data/cc98.posts.json:247](../src/data/cc98.posts.json#L247)；[src/data/cc98.posts.json:554](../src/data/cc98.posts.json#L554)；[src/scenes/phone/P02_CC98/index.tsx:199](../src/scenes/phone/P02_CC98/index.tsx#L199)
794. 东二食堂三楼炒饭晚上几点收窗口
   来源：[src/data/cc98.posts.json:162](../src/data/cc98.posts.json#L162)
795. 26-07-10 17:18
   来源：[src/data/cc98.posts.json:165](../src/data/cc98.posts.json#L165)
796. 昨晚 18:50 去东二食堂三楼，炒饭窗口还接单，19:05 只剩蛋炒饭。想加青菜的要早点去，打包盒在窗口右边自己拿。
   来源：[src/data/cc98.posts.json:166](../src/data/cc98.posts.json#L166)
797. 补充窗口时间
   来源：[src/data/cc98.posts.json:167](../src/data/cc98.posts.json#L167)
798. 东二饭点记录
   来源：[src/data/cc98.posts.json:167](../src/data/cc98.posts.json#L167)；[src/data/cc98.posts.json:253](../src/data/cc98.posts.json#L253)；[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
799. 楼主给出了到店时间和当天剩余餐品
   来源：[src/data/cc98.posts.json:167](../src/data/cc98.posts.json#L167)
800. 18:40 去还有青菜炒饭，取餐区右侧的勺子需要自己拿。
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)
801. 饭点
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)
802. 今天 17:20
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)；[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)
803. 今天 17:22
   来源：[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)；[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
804. 排队
   来源：[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)；[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)；[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)
805. 下雨天大家都从南门进，18:45 后南门那条队会拐到柱子后面。
   来源：[src/data/cc98.posts.json:171](../src/data/cc98.posts.json#L171)
806. 今天 17:24
   来源：[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)；[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)
807. 三楼靠窗两排桌子先被占满，端着餐盘上去前先看一眼空位。
   来源：[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)
808. 座位
   来源：[src/data/cc98.posts.json:172](../src/data/cc98.posts.json#L172)；[src/data/itemCatalog.ts:32](../src/data/itemCatalog.ts#L32)；[src/scenes/phone/P15_Zjuding/index.tsx:1811](../src/scenes/phone/P15_Zjuding/index.tsx#L1811)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
809. 到达
   来源：[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
810. 我从东门骑过去，18:55 才停好车，窗口已经开始收配菜。
   来源：[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
811. 打包盒不收钱，筷子在取餐台下层。刚才找了三分钟。
   来源：[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
812. 支付
   来源：[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
813. 窗口时间会按当天备菜量变，想稳妥就按 18:40 到店安排。
   来源：[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)
814. 核对
   来源：[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)；[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)；[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)；[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)；[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
815. 雨天伞套管理员
   来源：[src/data/cc98.posts.json:180](../src/data/cc98.posts.json#L180)
816. 教学楼门口的伞套机今天放哪边了
   来源：[src/data/cc98.posts.json:184](../src/data/cc98.posts.json#L184)
817. 26-07-10 17:15
   来源：[src/data/cc98.posts.json:187](../src/data/cc98.posts.json#L187)
818. 今天 16:20 到东教学楼，伞套机从门左边移到了门卫桌旁。机器没纸时可以先去旁边的小篮子拿，别把湿伞直接带进走廊。
   来源：[src/data/cc98.posts.json:188](../src/data/cc98.posts.json#L188)
819. 补充入口位置
   来源：[src/data/cc98.posts.json:189](../src/data/cc98.posts.json#L189)
820. 伞套机和备用伞套的位置都已说明
   来源：[src/data/cc98.posts.json:189](../src/data/cc98.posts.json#L189)
821. 雨天通行提醒
   来源：[src/data/cc98.posts.json:189](../src/data/cc98.posts.json#L189)
822. 16:25 备用篮还有一半，拿完要把伞尖朝下放。
   来源：[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)
823. 今天 17:17
   来源：[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)
824. 今天 17:19
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)
825. 天气
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)；[src/scenes/phone/P07_Weather/index.tsx:68](../src/scenes/phone/P07_Weather/index.tsx#L68)；[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)；[src/scenes/phone/P13_PhoneHome/index.tsx:845](../src/scenes/phone/P13_PhoneHome/index.tsx#L845)；[src/scenes/phone/P13_PhoneHome/index.tsx:851](../src/scenes/phone/P13_PhoneHome/index.tsx#L851)
826. 雨水会顺着门槛流进去，进门后先在地垫上停两步。
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)
827. 摆放
   来源：[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)
828. 今天 17:21
   来源：[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)
829. 伞架右侧那一格空着，长柄伞别横放，会挡住旁边的人。
   来源：[src/data/cc98.posts.json:194](../src/data/cc98.posts.json#L194)
830. 骑车到门口后先推到屋檐下，直接停在入口会挡住送货车。
   来源：[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)
831. 通行
   来源：[src/data/cc98.posts.json:195](../src/data/cc98.posts.json#L195)
832. 备用伞套不用刷卡，旁边的饮水机才需要校园卡。
   来源：[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)
833. 入口改过位置后，最好把门左和门右都看一遍，免得回头找。
   来源：[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)
834. 晚课后抄题人
   来源：[src/data/cc98.posts.json:202](../src/data/cc98.posts.json#L202)
835. 线代课后题有人用同一版空白答题纸吗
   来源：[src/data/cc98.posts.json:206](../src/data/cc98.posts.json#L206)
836. 26-07-10 17:12
   来源：[src/data/cc98.posts.json:209](../src/data/cc98.posts.json#L209)
837. 周三 21:10 在西区教学楼打印室找空白答题纸，最后在靠窗的文件架第二层看到一叠。纸张右上角有课程简称，拿之前先数清页数。
   来源：[src/data/cc98.posts.json:210](../src/data/cc98.posts.json#L210)
838. 补充取用位置
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
839. 楼主说明了寻找时间、房间和文件架层数
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
840. 学习资料互助台
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
841. 今天 17:14
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)
842. 我拿到的是六页版，最后一页有老师留的空白演算区。
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)
843. 资料
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)
844. 今天 17:16
   来源：[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)
845. 文件架旁边的窗没关，纸角有点卷，带夹子会好拿。
   来源：[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)
846. 今天 17:18
   来源：[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)
847. 同一层还有一叠概率论的纸，课程简称只差一个字，别拿错。
   来源：[src/data/cc98.posts.json:216](../src/data/cc98.posts.json#L216)
848. 从西区教学楼南门进，沿走廊到头再右转，打印室就在饮水机旁。
   来源：[src/data/cc98.posts.json:217](../src/data/cc98.posts.json#L217)
849. 复印
   来源：[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
850. 只要空白纸的话，复印机不用开机，先看文件架的标签。
   来源：[src/data/cc98.posts.json:218](../src/data/cc98.posts.json#L218)
851. 拿走后在帖子里写一下版本和页数，后来的人就不用逐叠翻。
   来源：[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)
852. 整理
   来源：[src/data/cc98.posts.json:219](../src/data/cc98.posts.json#L219)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
853. 雨天走南门
   来源：[src/data/cc98.posts.json:224](../src/data/cc98.posts.json#L224)
854. 雨还没停，东教学楼哪扇门口不积水
   来源：[src/data/cc98.posts.json:228](../src/data/cc98.posts.json#L228)
855. 26-07-10 17:08
   来源：[src/data/cc98.posts.json:231](../src/data/cc98.posts.json#L231)
856. 刚从东教学楼出来，西侧玻璃门前的地垫已经湿透。南边侧门的地面还干一点，手里有纸和电脑的可以从那边进。
   来源：[src/data/cc98.posts.json:232](../src/data/cc98.posts.json#L232)
857. 保留雨天通行记录
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)
858. 楼主说明了两处门口的地面情况
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)
859. 校园生活值班员
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)；[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
860. 今天 17:10
   来源：[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)
861. 西侧那块地垫已经软了，早八带纸质资料的还是绕南边。
   来源：[src/data/cc98.posts.json:236](../src/data/cc98.posts.json#L236)
862. 今天 17:12
   来源：[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)
863. 路过
   来源：[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)
864. 我从南侧门进，门口有一串伞套，走进去还算干。
   来源：[src/data/cc98.posts.json:237](../src/data/cc98.posts.json#L237)
865. 侧门的扶手有水，进门时别一边看手机一边跨门槛。
   来源：[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)
866. 二十分钟前路过，南边那块地还没积水。
   来源：[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)
867. 更新
   来源：[src/data/cc98.posts.json:239](../src/data/cc98.posts.json#L239)
868. 端盘找座位
   来源：[src/data/cc98.posts.json:244](../src/data/cc98.posts.json#L244)
869. 东二晚高峰的空座是在二楼还是三楼
   来源：[src/data/cc98.posts.json:248](../src/data/cc98.posts.json#L248)
870. 26-07-10 17:05
   来源：[src/data/cc98.posts.json:251](../src/data/cc98.posts.json#L251)
871. 傍晚六点二十到东二时二楼靠门的桌子已经满了，三楼最里面还有两张四人桌。想先放包再去排队的，记得别把通道边的空椅子当座位。
   来源：[src/data/cc98.posts.json:252](../src/data/cc98.posts.json#L252)
872. 补充座位信息
   来源：[src/data/cc98.posts.json:253](../src/data/cc98.posts.json#L253)
873. 楼主记录了到店时间和可用桌位
   来源：[src/data/cc98.posts.json:253](../src/data/cc98.posts.json#L253)
874. 今天 17:07
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
875. 晚到
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
876. 我六点三十五才上三楼，里面那两张桌已经有人坐下了。
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
877. 二楼饮水机旁的两把椅子在等人，别端着盘子站过去。
   来源：[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)
878. 观察
   来源：[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)
879. 今天 17:09
   来源：[src/data/cc98.posts.json:257](../src/data/cc98.posts.json#L257)
880. 今天 17:11
   来源：[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)
881. 三楼窗口排得慢一点，座位倒是比二楼松。
   来源：[src/data/cc98.posts.json:258](../src/data/cc98.posts.json#L258)
882. 结论
   来源：[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)；[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)；[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)；[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)
883. 今天 17:13
   来源：[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)
884. 想快点吃就二楼排队，想坐下就先上三楼看一圈。
   来源：[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)
885. 门口捡眼镜
   来源：[src/data/cc98.posts.json:264](../src/data/cc98.posts.json#L264)
886. 失物招领
   来源：[src/data/cc98.posts.json:267](../src/data/cc98.posts.json#L267)；[src/data/cc98.posts.json:535](../src/data/cc98.posts.json#L535)；[src/scenes/phone/P02_CC98/index.tsx:202](../src/scenes/phone/P02_CC98/index.tsx#L202)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:105](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L105)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:73](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L73)
887. 东区食堂门口捡到一副黑框眼镜
   来源：[src/data/cc98.posts.json:268](../src/data/cc98.posts.json#L268)
888. 26-07-10 17:02
   来源：[src/data/cc98.posts.json:271](../src/data/cc98.posts.json#L271)
889. 傍晚在东区食堂南门台阶边捡到一副黑框眼镜，镜腿内侧有一小段白色贴纸。我交到一楼服务台了，失主去问时带一下能核对的信息。
   来源：[src/data/cc98.posts.json:272](../src/data/cc98.posts.json#L272)
890. 标记服务台已接收
   来源：[src/data/cc98.posts.json:273](../src/data/cc98.posts.json#L273)
891. 失物招领版面
   来源：[src/data/cc98.posts.json:273](../src/data/cc98.posts.json#L273)；[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
892. 物品去向和辨认特征已经写明
   来源：[src/data/cc98.posts.json:273](../src/data/cc98.posts.json#L273)
893. 今天 17:04
   来源：[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)；[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)
894. 贴纸上有没有课程名，我室友下午刚丢了一副。
   来源：[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)
895. 问询
   来源：[src/data/cc98.posts.json:276](../src/data/cc98.posts.json#L276)
896. 今天 17:06
   来源：[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)
897. 先别把镜片度数写出来，服务台核对时再说。
   来源：[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)
898. 今天 17:08
   来源：[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)
899. 南门台阶晚上人多，走的时候最好把东西放包里。
   来源：[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)
900. 剧场外等雨小组
   来源：[src/data/cc98.posts.json:283](../src/data/cc98.posts.json#L283)
901. 从剧场走去湖边，雨后哪段路灯更亮
   来源：[src/data/cc98.posts.json:287](../src/data/cc98.posts.json#L287)
902. 26-07-10 16:58
   来源：[src/data/cc98.posts.json:290](../src/data/cc98.posts.json#L290)
903. 演出散场后往湖边走，靠外侧的树下那段光比较暗，石板也有水。绕到主路再下去会多走几分钟，路面和灯都好一点。
   来源：[src/data/cc98.posts.json:291](../src/data/cc98.posts.json#L291)
904. 加入雨后步行提醒
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
905. 楼主写清了两条路线的差别
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
906. 夜间步行信息台
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
907. 今天 17:00
   来源：[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)；[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
908. 骑行
   来源：[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)
909. 主路有积水反光，骑车也别压着边沿走。
   来源：[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)
910. 风向
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)；[src/scenes/phone/P07_Weather/index.tsx:101](../src/scenes/phone/P07_Weather/index.tsx#L101)
911. 湖边风比剧场外大，伞撑不住时先收起来。
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)
912. 今天 17:02
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)
913. 时间
   来源：[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)；[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/itemCatalog.ts:94](../src/data/itemCatalog.ts#L94)；[src/scenes/phone/P15_Zjuding/index.tsx:404](../src/scenes/phone/P15_Zjuding/index.tsx#L404)
914. 我多走了三分钟，鞋底没沾上泥，值。
   来源：[src/data/cc98.posts.json:297](../src/data/cc98.posts.json#L297)
915. 夜里走主路，别沿着树影那边抄近道。
   来源：[src/data/cc98.posts.json:298](../src/data/cc98.posts.json#L298)
916. 页码强迫症
   来源：[src/data/cc98.posts.json:303](../src/data/cc98.posts.json#L303)
917. 化工原理旧卷的页码有人补齐了吗
   来源：[src/data/cc98.posts.json:307](../src/data/cc98.posts.json#L307)
918. 26-07-10 16:54
   来源：[src/data/cc98.posts.json:310](../src/data/cc98.posts.json#L310)
919. 资料夹里有两份同年份旧卷，一份从第六页直接跳到第八页。我把缺页题号记下来了，想问有没有人留着完整扫描版，能顺手核对一下。
   来源：[src/data/cc98.posts.json:311](../src/data/cc98.posts.json#L311)
920. 保留缺页标记
   来源：[src/data/cc98.posts.json:312](../src/data/cc98.posts.json#L312)
921. 楼主指出了具体版本和缺失位置
   来源：[src/data/cc98.posts.json:312](../src/data/cc98.posts.json#L312)
922. 今天 16:56
   来源：[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)；[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
923. 文件
   来源：[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)
924. 我手里的版本是八页，周末回寝室再找一下原件。
   来源：[src/data/cc98.posts.json:315](../src/data/cc98.posts.json#L315)
925. 第七页是传热那道图题，只有题干没有答案。
   来源：[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)
926. 今天 16:58
   来源：[src/data/cc98.posts.json:316](../src/data/cc98.posts.json#L316)
927. 不要把缺页版覆盖原文件，后面的人还要比对来源。
   来源：[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
928. 胶圈带少了
   来源：[src/data/cc98.posts.json:322](../src/data/cc98.posts.json#L322)
929. 打印室的装订机还需要自己带胶圈吗
   来源：[src/data/cc98.posts.json:326](../src/data/cc98.posts.json#L326)
930. 26-07-10 16:50
   来源：[src/data/cc98.posts.json:329](../src/data/cc98.posts.json#L329)
931. 西区教学楼打印室的装订机能用，桌上只剩小号胶圈。报告超过四十页的，最好自己带一包，临时等补货容易赶不上上课。
   来源：[src/data/cc98.posts.json:330](../src/data/cc98.posts.json#L330)
932. 补充耗材状态
   来源：[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)
933. 楼主说明了机器和胶圈的现状
   来源：[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)
934. 刚才有人拿五十页去装，店员让他分两本。
   来源：[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)
935. 今天 16:52
   来源：[src/data/cc98.posts.json:334](../src/data/cc98.posts.json#L334)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)
936. 今天 16:54
   来源：[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)
937. 透明封面在最下面一层抽屉，第一次去很容易漏看。
   来源：[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)
938. 经验
   来源：[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
939. 页数多就分两册，翻起来也省事。
   来源：[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
940. 二楼靠窗充电中
   来源：[src/data/cc98.posts.json:341](../src/data/cc98.posts.json#L341)
941. 基础图书馆二楼靠窗的插座这两天还稳吗
   来源：[src/data/cc98.posts.json:345](../src/data/cc98.posts.json#L345)
942. 26-07-10 16:46
   来源：[src/data/cc98.posts.json:348](../src/data/cc98.posts.json#L348)
943. 昨天靠窗第三张桌的插座断过两次，换到靠柱子那排后正常。今天要带电脑写作业的，先别把座位选在窗边最里面。
   来源：[src/data/cc98.posts.json:349](../src/data/cc98.posts.json#L349)
944. 补充插座状态
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
945. 楼主给出了异常位置和替代位置
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
946. 图书馆设备记录
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
947. 复测
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)
948. 今天 16:48
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)；[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)
949. 我下午试了两次，靠窗第三张桌还是会松。
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)
950. 今天 16:50
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
951. 靠柱子那排有两个空口，插头比较紧。
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
952. 替代
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
953. 别把插线板横在过道，借书车会从那里过。
   来源：[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)
954. 补办卡排队中
   来源：[src/data/cc98.posts.json:360](../src/data/cc98.posts.json#L360)
955. 校园卡补办当天能进图书馆吗
   来源：[src/data/cc98.posts.json:364](../src/data/cc98.posts.json#L364)
956. 26-07-10 16:42
   来源：[src/data/cc98.posts.json:367](../src/data/cc98.posts.json#L367)
957. 今天上午卡丢了，补办后先在机器上做了一次身份核验，下午进基础图书馆没有被拦。旧卡已经停用，带着旧卡去刷只会多排一次队。
   来源：[src/data/cc98.posts.json:368](../src/data/cc98.posts.json#L368)
958. 标记为当日记录
   来源：[src/data/cc98.posts.json:369](../src/data/cc98.posts.json#L369)
959. 楼主说明了补办后的验证和入馆结果
   来源：[src/data/cc98.posts.json:369](../src/data/cc98.posts.json#L369)
960. 补办后先看卡面编号，机器读取到新号才算完成。
   来源：[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)
961. 今天 16:44
   来源：[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)；[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)
962. 今天 16:46
   来源：[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
963. 中午人少一点，柜台和机器都不用等太久。
   来源：[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)
964. 丢卡先停用，补办当天把新卡做一次验证。
   来源：[src/data/cc98.posts.json:374](../src/data/cc98.posts.json#L374)
965. 信号格满了
   来源：[src/data/cc98.posts.json:379](../src/data/cc98.posts.json#L379)
966. 手机服务
   来源：[src/data/cc98.posts.json:382](../src/data/cc98.posts.json#L382)；[src/scenes/phone/P02_CC98/index.tsx:196](../src/scenes/phone/P02_CC98/index.tsx#L196)
967. 【移动/联通/电信】2026年校园电话卡信息汇总帖 详情请戳
   来源：[src/data/cc98.posts.json:383](../src/data/cc98.posts.json#L383)
968. 26-07-10 16:38
   来源：[src/data/cc98.posts.json:386](../src/data/cc98.posts.json#L386)
969. 准备开学换号的可以先把套餐、校园区域覆盖和注销条件写在同一层回复里。只放海报截图很难比较，最好补充自己实测的宿舍、教学楼和地铁口信号。
   来源：[src/data/cc98.posts.json:387](../src/data/cc98.posts.json#L387)
970. 讨论包含不同运营商的使用场景和办理提醒
   来源：[src/data/cc98.posts.json:388](../src/data/cc98.posts.json#L388)
971. 校园通信互助台
   来源：[src/data/cc98.posts.json:388](../src/data/cc98.posts.json#L388)
972. 整理为信息汇总
   来源：[src/data/cc98.posts.json:388](../src/data/cc98.posts.json#L388)
973. 教学楼里先看自己常待的那一侧，办卡点的信号格不能代表上课的位置。
   来源：[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)
974. 今天 16:40
   来源：[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)；[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
975. 今天 16:42
   来源：[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)
976. 套餐写清楚是月租还是校园期，别把首月优惠当成长期价格。
   来源：[src/data/cc98.posts.json:392](../src/data/cc98.posts.json#L392)
977. 想保留旧号码的先问转网和注销流程，开学那周柜台排队会很长。
   来源：[src/data/cc98.posts.json:393](../src/data/cc98.posts.json#L393)
978. 楼里只保留可核对的套餐名称、适用期限和实测位置，广告图不单独计入结论。
   来源：[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
979. 图书馆门口的雨
   来源：[src/data/cc98.posts.json:399](../src/data/cc98.posts.json#L399)
980. 开怀一笑
   来源：[src/data/cc98.posts.json:402](../src/data/cc98.posts.json#L402)；[src/data/cc98.posts.json:421](../src/data/cc98.posts.json#L421)；[src/data/cc98.posts.json:516](../src/data/cc98.posts.json#L516)；[src/scenes/phone/P02_CC98/index.tsx:191](../src/scenes/phone/P02_CC98/index.tsx#L191)；[src/scenes/phone/P02_CC98/index.tsx:204](../src/scenes/phone/P02_CC98/index.tsx#L204)
981. 雨伞在一楼，人在三楼，雨还在外面
   来源：[src/data/cc98.posts.json:403](../src/data/cc98.posts.json#L403)
982. 26-07-10 16:34
   来源：[src/data/cc98.posts.json:406](../src/data/cc98.posts.json#L406)
983. 本来只是下楼拿外卖，发现伞架里那把蓝伞很像我的。等我把伞带到三楼，才想起自己的伞还在寝室。
   来源：[src/data/cc98.posts.json:407](../src/data/cc98.posts.json#L407)
984. 保留轻松讨论
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)
985. 回复围绕雨天小失误展开，没有涉及失物认领
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)
986. 开怀一笑值班员
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)；[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)；[src/data/cc98.posts.json:522](../src/data/cc98.posts.json#L522)
987. 今天 16:36
   来源：[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)；[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)
988. 同款
   来源：[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)
989. 我有一次带着空伞套走回寝室，雨伞在门口，套子在手里。
   来源：[src/data/cc98.posts.json:411](../src/data/cc98.posts.json#L411)
990. 今天 16:38
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)
991. 确认
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)
992. 至少你把伞带到了需要它的楼层，进度已经过半。
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)
993. 补图
   来源：[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
994. 下雨天的记忆会自动把所有蓝伞归到自己名下。
   来源：[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
995. 晚八还在找耳机
   来源：[src/data/cc98.posts.json:418](../src/data/cc98.posts.json#L418)
996. 耳机连上了隔壁桌，我听完了半节陌生人的网课
   来源：[src/data/cc98.posts.json:422](../src/data/cc98.posts.json#L422)
997. 26-07-10 16:30
   来源：[src/data/cc98.posts.json:425](../src/data/cc98.posts.json#L425)
998. 戴上耳机后发现讲课内容完全听不懂，还以为自己选错了章节。直到隔壁同学抬头问谁连到了他的设备，我才发现耳机名字还叫“默认设备”。
   来源：[src/data/cc98.posts.json:426](../src/data/cc98.posts.json#L426)
999. 加入设备小事
   来源：[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)
1000. 帖子包含清楚的误连原因和轻松回复
   来源：[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)
1001. 今天 16:32
   来源：[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
1002. 设备名改成自己看得懂的，图书馆里“默认设备”永远不止一个。
   来源：[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)
1003. 今天 16:34
   来源：[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)
1004. 我连过一段白噪音，找了五分钟才知道声音来自隔壁的平板。
   来源：[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)
1005. 陌生课程听不懂先别怀疑自己，先看蓝牙名称。
   来源：[src/data/cc98.posts.json:432](../src/data/cc98.posts.json#L432)
1006. 搬寝室清库存
   来源：[src/data/cc98.posts.json:437](../src/data/cc98.posts.json#L437)
1007. 二手市场
   来源：[src/data/cc98.posts.json:440](../src/data/cc98.posts.json#L440)；[src/scenes/phone/P02_CC98/index.tsx:203](../src/scenes/phone/P02_CC98/index.tsx#L203)
1008. 出一盏可调光台灯，限校内当面自取
   来源：[src/data/cc98.posts.json:441](../src/data/cc98.posts.json#L441)
1009. 26-07-10 16:26
   来源：[src/data/cc98.posts.json:444](../src/data/cc98.posts.json#L444)
1010. 台灯用了两学期，触控和调光都正常，电源线在。只约公共区域当面试亮，想要的带上能确认时间的人再联系。
   来源：[src/data/cc98.posts.json:445](../src/data/cc98.posts.json#L445)
1011. 补充交易边界
   来源：[src/data/cc98.posts.json:446](../src/data/cc98.posts.json#L446)
1012. 二手市场提醒员
   来源：[src/data/cc98.posts.json:446](../src/data/cc98.posts.json#L446)
1013. 楼主提供了物品状态、交接方式和试用条件
   来源：[src/data/cc98.posts.json:446](../src/data/cc98.posts.json#L446)
1014. 今天 16:28
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)
1015. 能拍一下最低档亮度吗，晚上看屏幕怕太刺眼。
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)
1016. 询问
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)
1017. 当面先试灯和接口，转账后再发现少线会很麻烦。
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)
1018. 今天 16:30
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)
1019. 规范
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
1020. 物品状态、地点和时间写清楚，楼里就不用反复问同一件事。
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
1021. 实验服忘带了
   来源：[src/data/cc98.posts.json:456](../src/data/cc98.posts.json#L456)
1022. 实验课前十分钟才想起实验服还晾在阳台
   来源：[src/data/cc98.posts.json:460](../src/data/cc98.posts.json#L460)
1023. 26-07-10 16:22
   来源：[src/data/cc98.posts.json:463](../src/data/cc98.posts.json#L463)
1024. 一路跑到楼下才发现雨把衣服晾得很有弹性，赶到实验楼时正好听见老师点名。今天的经验是：把实验服放进包里，不要相信早上临出门的自己。
   来源：[src/data/cc98.posts.json:464](../src/data/cc98.posts.json#L464)
1025. 内容为个人经历和防漏清单，没有课程资料需求
   来源：[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
1026. 收录课前小事
   来源：[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
1027. 今天 16:24
   来源：[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)；[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)
1028. 我把实验鞋带成了拖鞋，进楼前才发现鞋底不对。
   来源：[src/data/cc98.posts.json:468](../src/data/cc98.posts.json#L468)
1029. 今天 16:26
   来源：[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)
1030. 清单
   来源：[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)
1031. 实验服、护目镜、笔，前一晚放门边最省心。
   来源：[src/data/cc98.posts.json:469](../src/data/cc98.posts.json#L469)
1032. 跑到门口才想起来实验服在包里的人，今天也不少。
   来源：[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)
1033. 取件码忘带
   来源：[src/data/cc98.posts.json:475](../src/data/cc98.posts.json#L475)
1034. 校园卡绑定旧手机后，门禁旁边怎么重新核验
   来源：[src/data/cc98.posts.json:479](../src/data/cc98.posts.json#L479)
1035. 26-07-10 16:18
   来源：[src/data/cc98.posts.json:482](../src/data/cc98.posts.json#L482)
1036. 换手机后旧设备还留着绑定信息，今天在门禁旁的机器上重新核验才恢复正常。先确认新手机能打开校园卡页面，再去现场操作会少跑一趟。
   来源：[src/data/cc98.posts.json:483](../src/data/cc98.posts.json#L483)
1037. 标记设备换绑记录
   来源：[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
1038. 楼主给出了换机后的现场验证步骤
   来源：[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
1039. 今天 16:20
   来源：[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)；[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)
1040. 旧手机还在时先退出绑定，之后换新机更容易确认。
   来源：[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)
1041. 今天 16:22
   来源：[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)
1042. 我先去图书馆门口试了一次，失败后再去机器核验就通过了。
   来源：[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)
1043. 换机当天留下新设备的验证结果，进楼前先试一次。
   来源：[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)
1044. 窗边那排空着
   来源：[src/data/cc98.posts.json:494](../src/data/cc98.posts.json#L494)
1045. 晚课结束后有人愿意一起占四人桌写作业吗
   来源：[src/data/cc98.posts.json:498](../src/data/cc98.posts.json#L498)
1046. 26-07-10 16:14
   来源：[src/data/cc98.posts.json:501](../src/data/cc98.posts.json#L501)
1047. 想找两三个人在麦斯威把作业写完，各做各的，不开外放。九点前如果位置满了就散，带电脑的优先坐有插座那侧。
   来源：[src/data/cc98.posts.json:502](../src/data/cc98.posts.json#L502)
1048. 保留临时约伴帖
   来源：[src/data/cc98.posts.json:503](../src/data/cc98.posts.json#L503)
1049. 时间、地点和自习规则已经写明
   来源：[src/data/cc98.posts.json:503](../src/data/cc98.posts.json#L503)
1050. 报名
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)
1051. 今天 16:16
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)；[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)
1052. 我带耳机和插线板，七点四十左右到。
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)
1053. 今天 16:18
   来源：[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)
1054. 能保证不讨论题目吗，我有一份报告要赶。
   来源：[src/data/cc98.posts.json:507](../src/data/cc98.posts.json#L507)
1055. 第一次见面选公共区域，离开前把桌面收好。
   来源：[src/data/cc98.posts.json:508](../src/data/cc98.posts.json#L508)
1056. 西门等外卖
   来源：[src/data/cc98.posts.json:513](../src/data/cc98.posts.json#L513)
1057. 我给外卖备注“蓝色外套”，结果门口站了七个蓝色外套
   来源：[src/data/cc98.posts.json:517](../src/data/cc98.posts.json#L517)
1058. 26-07-10 16:10
   来源：[src/data/cc98.posts.json:520](../src/data/cc98.posts.json#L520)
1059. 骑手问谁是蓝色外套，我举手后旁边也举起六只手。最后靠备注里的饮料口味找到了自己的那一袋。
   来源：[src/data/cc98.posts.json:521](../src/data/cc98.posts.json#L521)
1060. 加入校园小场面
   来源：[src/data/cc98.posts.json:522](../src/data/cc98.posts.json#L522)
1061. 主题来自公共取餐区的日常误会
   来源：[src/data/cc98.posts.json:522](../src/data/cc98.posts.json#L522)
1062. 今天 16:12
   来源：[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)；[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
1063. 下次备注鞋子颜色，蓝色外套在雨天没有辨识度。
   来源：[src/data/cc98.posts.json:525](../src/data/cc98.posts.json#L525)
1064. 今天 16:14
   来源：[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)
1065. 我写过“背电脑包”，门口每个人都背着。
   来源：[src/data/cc98.posts.json:526](../src/data/cc98.posts.json#L526)
1066. 饮料口味和取餐码比穿什么可靠。
   来源：[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)
1067. 卡套夹住了
   来源：[src/data/cc98.posts.json:532](../src/data/cc98.posts.json#L532)
1068. 教学楼一楼窗台上有一张校园卡，卡套是深绿色的
   来源：[src/data/cc98.posts.json:536](../src/data/cc98.posts.json#L536)
1069. 26-07-10 16:06
   来源：[src/data/cc98.posts.json:539](../src/data/cc98.posts.json#L539)
1070. 卡放在一楼饮水机旁的窗台上，深绿色卡套边缘有磨损。我没有移动，失主到场后先核对姓名和卡面照片再拿。
   来源：[src/data/cc98.posts.json:540](../src/data/cc98.posts.json#L540)
1071. 保留现场位置
   来源：[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
1072. 物品特征、所在位置和核对方式完整
   来源：[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
1073. 别把卡号完整发出来，能让失主自己说明卡套细节更稳妥。
   来源：[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)
1074. 今天 16:08
   来源：[src/data/cc98.posts.json:544](../src/data/cc98.posts.json#L544)；[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)
1075. 今天 16:10
   来源：[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)
1076. 饮水机旁人来人往，没找到失主就交到门卫处。
   来源：[src/data/cc98.posts.json:545](../src/data/cc98.posts.json#L545)
1077. 现场物品只写辨识特征，不公开完整个人信息。
   来源：[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
1078. 三号窗口观察员
   来源：[src/data/cc98.posts.json:551](../src/data/cc98.posts.json#L551)
1079. 东二三号窗口今天的队伍为什么总会停一下
   来源：[src/data/cc98.posts.json:555](../src/data/cc98.posts.json#L555)
1080. 26-07-10 16:02
   来源：[src/data/cc98.posts.json:558](../src/data/cc98.posts.json#L558)
1081. 排队时看见前面的人都会在付款页找半天，原来是当天的套餐入口换了位置。点餐前先看屏幕底部一行，队伍会走得快一点。
   来源：[src/data/cc98.posts.json:559](../src/data/cc98.posts.json#L559)
1082. 补充点餐界面变化
   来源：[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
1083. 帖子说明了排队变慢的具体原因
   来源：[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
1084. 今天 16:04
   来源：[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
1085. 我刚去过，先选套餐再选饭，顺序和昨天不一样。
   来源：[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
1086. 今天 16:06
   来源：[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)
1087. 屏幕前别临时问朋友吃什么，后面的人会一起停住。
   来源：[src/data/cc98.posts.json:564](../src/data/cc98.posts.json#L564)
1088. 入口变化时把步骤写清楚，下一位就少等一会儿。
   来源：[src/data/cc98.posts.json:565](../src/data/cc98.posts.json#L565)
1089. 时间戳和打印队都要记清。
   来源：[src/data/cc98.thread-personas.json:2](../src/data/cc98.thread-personas.json#L2)
1090. 晚八点打印机
   来源：[src/data/cc98.thread-personas.json:2](../src/data/cc98.thread-personas.json#L2)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:41](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L41)
1091. 路过带图，顺手报告风向和人流。
   来源：[src/data/cc98.thread-personas.json:3](../src/data/cc98.thread-personas.json#L3)
1092. 玉泉风很大
   来源：[src/data/cc98.thread-personas.json:3](../src/data/cc98.thread-personas.json#L3)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:51](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L51)
1093. 盯着座位、插座和没人取走的东西。
   来源：[src/data/cc98.thread-personas.json:4](../src/data/cc98.thread-personas.json#L4)
1094. 二南插座观察员
   来源：[src/data/cc98.thread-personas.json:4](../src/data/cc98.thread-personas.json#L4)
1095. 每天经过求是潮，偶尔能走出去。
   来源：[src/data/cc98.thread-personas.json:5](../src/data/cc98.thread-personas.json#L5)
1096. 求是潮逆行者
   来源：[src/data/cc98.thread-personas.json:5](../src/data/cc98.thread-personas.json#L5)
1097. 六分钱富豪
   来源：[src/data/cc98.thread-personas.json:6](../src/data/cc98.thread-personas.json#L6)
1098. 余额 0.06 元，账目记录完整。
   来源：[src/data/cc98.thread-personas.json:6](../src/data/cc98.thread-personas.json#L6)
1099. 没有审核权限，只保留证据和结论。
   来源：[src/data/cc98.thread-personas.json:7](../src/data/cc98.thread-personas.json#L7)
1100. 紫金港野生审核员
   来源：[src/data/cc98.thread-personas.json:7](../src/data/cc98.thread-personas.json#L7)
1101. narrator
   来源：[src/data/dialogue.lines.json:5](../src/data/dialogue.lines.json#L5)；[src/data/storyLines.ts:46](../src/data/storyLines.ts#L46)
1102. 你没有5分钟了，但你很有勇气
   来源：[src/data/dialogue.lines.json:6](../src/data/dialogue.lines.json#L6)
1103. xiaoying
   来源：[src/data/dialogue.lines.json:16](../src/data/dialogue.lines.json#L16)；[src/data/dialogue.lines.json:27](../src/data/dialogue.lines.json#L27)；[src/data/dialogue.lines.json:38](../src/data/dialogue.lines.json#L38)；[src/data/dialogue.lines.json:71](../src/data/dialogue.lines.json#L71)；[src/data/dialogue.lines.json:93](../src/data/dialogue.lines.json#L93)；[src/scenes/phone/P14_Wechat/index.tsx:403](../src/scenes/phone/P14_Wechat/index.tsx#L403)
1104. 起床蠢货！！！
   来源：[src/data/dialogue.lines.json:17](../src/data/dialogue.lines.json#L17)
1105. 等等等等，你想翘课？没门！我不会让你签上的！
   来源：[src/data/dialogue.lines.json:28](../src/data/dialogue.lines.json#L28)
1106. 找你的数字去吧哈哈哈
   来源：[src/data/dialogue.lines.json:39](../src/data/dialogue.lines.json#L39)；[src/scenes/phone/P14_Wechat/index.tsx:990](../src/scenes/phone/P14_Wechat/index.tsx#L990)
1107. system
   来源：[src/data/dialogue.lines.json:49](../src/data/dialogue.lines.json#L49)；[src/data/dialogue.lines.json:60](../src/data/dialogue.lines.json#L60)；[src/data/dialogue.lines.json:82](../src/data/dialogue.lines.json#L82)；[src/data/storyLines.ts:46](../src/data/storyLines.ts#L46)；[src/data/storyLines.ts:54](../src/data/storyLines.ts#L54)；[src/scenes/phone/P02_CC98/index.tsx:631](../src/scenes/phone/P02_CC98/index.tsx#L631)；[src/scenes/phone/P02_CC98/index.tsx:782](../src/scenes/phone/P02_CC98/index.tsx#L782)；[src/scenes/phone/P07_Weather/index.tsx:29](../src/scenes/phone/P07_Weather/index.tsx#L29)；[src/scenes/phone/P07_Weather/index.tsx:41](../src/scenes/phone/P07_Weather/index.tsx#L41)；[src/scenes/phone/P07_Weather/index.tsx:45](../src/scenes/phone/P07_Weather/index.tsx#L45)；[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)；[src/scenes/phone/P07_Weather/index.tsx:60](../src/scenes/phone/P07_Weather/index.tsx#L60)；[src/scenes/phone/P07_Weather/index.tsx:63](../src/scenes/phone/P07_Weather/index.tsx#L63)；[src/scenes/phone/P13_PhoneHome/index.tsx:214](../src/scenes/phone/P13_PhoneHome/index.tsx#L214)；[src/scenes/phone/P13_PhoneHome/index.tsx:337](../src/scenes/phone/P13_PhoneHome/index.tsx#L337)；[src/scenes/phone/P13_PhoneHome/index.tsx:341](../src/scenes/phone/P13_PhoneHome/index.tsx#L341)；[src/scenes/phone/P14_Wechat/index.tsx:349](../src/scenes/phone/P14_Wechat/index.tsx#L349)；[src/scenes/phone/P14_Wechat/index.tsx:355](../src/scenes/phone/P14_Wechat/index.tsx#L355)；[src/scenes/phone/P14_Wechat/index.tsx:419](../src/scenes/phone/P14_Wechat/index.tsx#L419)；[src/scenes/phone/P14_Wechat/index.tsx:423](../src/scenes/phone/P14_Wechat/index.tsx#L423)；[src/scenes/phone/P14_Wechat/index.tsx:506](../src/scenes/phone/P14_Wechat/index.tsx#L506)；[src/scenes/phone/P15_Zjuding/index.tsx:71](../src/scenes/phone/P15_Zjuding/index.tsx#L71)；[src/scenes/phone/P15_Zjuding/index.tsx:73](../src/scenes/phone/P15_Zjuding/index.tsx#L73)；[src/scenes/phone/P15_Zjuding/index.tsx:74](../src/scenes/phone/P15_Zjuding/index.tsx#L74)；[src/scenes/phone/P15_Zjuding/index.tsx:75](../src/scenes/phone/P15_Zjuding/index.tsx#L75)；[src/scenes/phone/P15_Zjuding/index.tsx:78](../src/scenes/phone/P15_Zjuding/index.tsx#L78)；[src/scenes/phone/P15_Zjuding/index.tsx:80](../src/scenes/phone/P15_Zjuding/index.tsx#L80)；[src/scenes/phone/P15_Zjuding/index.tsx:81](../src/scenes/phone/P15_Zjuding/index.tsx#L81)；[src/scenes/phone/P15_Zjuding/index.tsx:84](../src/scenes/phone/P15_Zjuding/index.tsx#L84)；[src/scenes/phone/P15_Zjuding/index.tsx:86](../src/scenes/phone/P15_Zjuding/index.tsx#L86)；[src/scenes/phone/P15_Zjuding/index.tsx:87](../src/scenes/phone/P15_Zjuding/index.tsx#L87)；[src/scenes/phone/P15_Zjuding/index.tsx:88](../src/scenes/phone/P15_Zjuding/index.tsx#L88)；[src/scenes/phone/P15_Zjuding/index.tsx:89](../src/scenes/phone/P15_Zjuding/index.tsx#L89)；[src/scenes/phone/P15_Zjuding/index.tsx:92](../src/scenes/phone/P15_Zjuding/index.tsx#L92)；[src/scenes/phone/P15_Zjuding/index.tsx:93](../src/scenes/phone/P15_Zjuding/index.tsx#L93)；[src/scenes/phone/P15_Zjuding/index.tsx:94](../src/scenes/phone/P15_Zjuding/index.tsx#L94)；[src/scenes/phone/P15_Zjuding/index.tsx:95](../src/scenes/phone/P15_Zjuding/index.tsx#L95)；[src/scenes/phone/P15_Zjuding/index.tsx:621](../src/scenes/phone/P15_Zjuding/index.tsx#L621)；[src/scenes/phone/P15_Zjuding/index.tsx:636](../src/scenes/phone/P15_Zjuding/index.tsx#L636)；[src/scenes/phone/P15_Zjuding/index.tsx:666](../src/scenes/phone/P15_Zjuding/index.tsx#L666)；[src/scenes/phone/P15_Zjuding/index.tsx:759](../src/scenes/phone/P15_Zjuding/index.tsx#L759)；[src/scenes/phone/P15_Zjuding/index.tsx:923](../src/scenes/phone/P15_Zjuding/index.tsx#L923)；[src/scenes/phone/P15_Zjuding/index.tsx:1049](../src/scenes/phone/P15_Zjuding/index.tsx#L1049)；[src/scenes/rpg/BootScene.ts:201](../src/scenes/rpg/BootScene.ts#L201)；[src/scenes/rpg/BootScene.ts:203](../src/scenes/rpg/BootScene.ts#L203)；[src/scenes/rpg/BootScene.ts:614](../src/scenes/rpg/BootScene.ts#L614)
1108. 余额暂时不足以购买尊严
   来源：[src/data/dialogue.lines.json:50](../src/data/dialogue.lines.json#L50)
1109. 校园网已经尽力了，你也是
   来源：[src/data/dialogue.lines.json:61](../src/data/dialogue.lines.json#L61)
1110. 我知道你没钱买流量
   来源：[src/data/dialogue.lines.json:72](../src/data/dialogue.lines.json#L72)
1111. 就差一次，真绝望
   来源：[src/data/dialogue.lines.json:83](../src/data/dialogue.lines.json#L83)
1112. 哈，一个废齿轮
   来源：[src/data/dialogue.lines.json:94](../src/data/dialogue.lines.json#L94)
1113. 022 临时离座留言
   来源：[src/data/itemCatalog.ts:30](../src/data/itemCatalog.ts#L30)
1114. 022 · 二楼南区
   来源：[src/data/itemCatalog.ts:32](../src/data/itemCatalog.ts#L32)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:138](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L138)
1115. 离开时长
   来源：[src/data/itemCatalog.ts:33](../src/data/itemCatalog.ts#L33)
1116. 三分钟
   来源：[src/data/itemCatalog.ts:33](../src/data/itemCatalog.ts#L33)
1117. 留言状态
   来源：[src/data/itemCatalog.ts:34](../src/data/itemCatalog.ts#L34)
1118. 仍在占用
   来源：[src/data/itemCatalog.ts:34](../src/data/itemCatalog.ts#L34)
1119. 本人离开三分钟，精神仍在座位上。
   来源：[src/data/itemCatalog.ts:36](../src/data/itemCatalog.ts#L36)
1120. 临时离座规则详见 CC98。
   来源：[src/data/itemCatalog.ts:36](../src/data/itemCatalog.ts#L36)
1121. 纸张边缘留有反复折叠痕迹。
   来源：[src/data/itemCatalog.ts:37](../src/data/itemCatalog.ts#L37)
1122. 馆藏定位单
   来源：[src/data/itemCatalog.ts:40](../src/data/itemCatalog.ts#L40)
1123. 《三分钟离座法及其例外》
   来源：[src/data/itemCatalog.ts:42](../src/data/itemCatalog.ts#L42)
1124. 书名
   来源：[src/data/itemCatalog.ts:42](../src/data/itemCatalog.ts#L42)；[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
1125. 索书号
   来源：[src/data/itemCatalog.ts:43](../src/data/itemCatalog.ts#L43)
1126. 馆藏位置
   来源：[src/data/itemCatalog.ts:44](../src/data/itemCatalog.ts#L44)
1127. 基础馆文学书架 · 755 段
   来源：[src/data/itemCatalog.ts:44](../src/data/itemCatalog.ts#L44)
1128. 本条目为旧版规定的馆内定位线索。
   来源：[src/data/itemCatalog.ts:46](../src/data/itemCatalog.ts#L46)
1129. 状态：仅馆内查阅。
   来源：[src/data/itemCatalog.ts:47](../src/data/itemCatalog.ts#L47)
1130. 旧版临时离座恢复规定
   来源：[src/data/itemCatalog.ts:50](../src/data/itemCatalog.ts#L50)
1131. 版本
   来源：[src/data/itemCatalog.ts:52](../src/data/itemCatalog.ts#L52)
1132. 期末周修订版 · 已归档
   来源：[src/data/itemCatalog.ts:52](../src/data/itemCatalog.ts#L52)
1133. 适用范围
   来源：[src/data/itemCatalog.ts:53](../src/data/itemCatalog.ts#L53)
1134. 座位被非本人随身物持续占用
   来源：[src/data/itemCatalog.ts:53](../src/data/itemCatalog.ts#L53)
1135. 目标座位
   来源：[src/data/itemCatalog.ts:54](../src/data/itemCatalog.ts#L54)
1136. 恢复申请须同时具备三类证明：
   来源：[src/data/itemCatalog.ts:57](../src/data/itemCatalog.ts#L57)
1137. 一、本人确实到馆；
   来源：[src/data/itemCatalog.ts:58](../src/data/itemCatalog.ts#L58)
1138. 二、目标座位与凭据一致；
   来源：[src/data/itemCatalog.ts:59](../src/data/itemCatalog.ts#L59)
1139. 三、当前占用物不具备本人身份。
   来源：[src/data/itemCatalog.ts:60](../src/data/itemCatalog.ts#L60)
1140. 规则依据须先完成公开公示。
   来源：[src/data/itemCatalog.ts:62](../src/data/itemCatalog.ts#L62)
1141. 对象类型
   来源：[src/data/itemCatalog.ts:67](../src/data/itemCatalog.ts#L67)
1142. 双肩书包
   来源：[src/data/itemCatalog.ts:67](../src/data/itemCatalog.ts#L67)
1143. 未识别
   来源：[src/data/itemCatalog.ts:68](../src/data/itemCatalog.ts#L68)；[src/data/itemCatalog.ts:69](../src/data/itemCatalog.ts#L69)
1144. 姓名
   来源：[src/data/itemCatalog.ts:68](../src/data/itemCatalog.ts#L68)；[src/scenes/phone/P15_Zjuding/index.tsx:1268](../src/scenes/phone/P15_Zjuding/index.tsx#L1268)；[src/scenes/phone/P15_Zjuding/index.tsx:1334](../src/scenes/phone/P15_Zjuding/index.tsx#L1334)
1145. 学号
   来源：[src/data/itemCatalog.ts:69](../src/data/itemCatalog.ts#L69)；[src/scenes/phone/P15_Zjuding/index.tsx:1272](../src/scenes/phone/P15_Zjuding/index.tsx#L1272)；[src/scenes/phone/P15_Zjuding/index.tsx:1346](../src/scenes/phone/P15_Zjuding/index.tsx#L1346)
1146. 识别结果
   来源：[src/data/itemCatalog.ts:70](../src/data/itemCatalog.ts#L70)
1147. 未检测到可签到主体
   来源：[src/data/itemCatalog.ts:70](../src/data/itemCatalog.ts#L70)
1148. 检测到大量期末周使用痕迹。
   来源：[src/data/itemCatalog.ts:72](../src/data/itemCatalog.ts#L72)
1149. 身份结论需由馆内前台工作人员确认。
   来源：[src/data/itemCatalog.ts:72](../src/data/itemCatalog.ts#L72)
1150. 报告状态：待盖章。
   来源：[src/data/itemCatalog.ts:73](../src/data/itemCatalog.ts#L73)
1151. 022 座位占用书包
   来源：[src/data/itemCatalog.ts:78](../src/data/itemCatalog.ts#L78)
1152. 对象
   来源：[src/data/itemCatalog.ts:78](../src/data/itemCatalog.ts#L78)
1153. 非本人
   来源：[src/data/itemCatalog.ts:79](../src/data/itemCatalog.ts#L79)
1154. 认证结论
   来源：[src/data/itemCatalog.ts:79](../src/data/itemCatalog.ts#L79)
1155. 无 / 无
   来源：[src/data/itemCatalog.ts:80](../src/data/itemCatalog.ts#L80)
1156. 姓名 / 学号
   来源：[src/data/itemCatalog.ts:80](../src/data/itemCatalog.ts#L80)
1157. 盖章来源
   来源：[src/data/itemCatalog.ts:81](../src/data/itemCatalog.ts#L81)
1158. 基础馆物品身份盖章机
   来源：[src/data/itemCatalog.ts:81](../src/data/itemCatalog.ts#L81)
1159. 该物品不具备独立占用座位的身份条件。
   来源：[src/data/itemCatalog.ts:83](../src/data/itemCatalog.ts#L83)
1160. 电子章：基础馆失物身份登记。
   来源：[src/data/itemCatalog.ts:84](../src/data/itemCatalog.ts#L84)
1161. 022 座位凭据
   来源：[src/data/itemCatalog.ts:90](../src/data/itemCatalog.ts#L90)
1162. 座位编号
   来源：[src/data/itemCatalog.ts:92](../src/data/itemCatalog.ts#L92)
1163. 二楼南区
   来源：[src/data/itemCatalog.ts:93](../src/data/itemCatalog.ts#L93)
1164. 区域
   来源：[src/data/itemCatalog.ts:93](../src/data/itemCatalog.ts#L93)；[src/scenes/phone/P15_Zjuding/index.tsx:416](../src/scenes/phone/P15_Zjuding/index.tsx#L416)
1165. 离座中 · 待公示
   来源：[src/data/itemCatalog.ts:95](../src/data/itemCatalog.ts#L95)
1166. 凭据状态
   来源：[src/data/itemCatalog.ts:95](../src/data/itemCatalog.ts#L95)
1167. 当前占用物：书包。
   来源：[src/data/itemCatalog.ts:97](../src/data/itemCatalog.ts#L97)
1168. 恢复处理需提交论坛公示。
   来源：[src/data/itemCatalog.ts:97](../src/data/itemCatalog.ts#L97)
1169. 凭据来源：022 桌面夹缝。
   来源：[src/data/itemCatalog.ts:98](../src/data/itemCatalog.ts#L98)
1170. 7 分钟
   来源：[src/data/itemCatalog.ts:106](../src/data/itemCatalog.ts#L106)
1171. 到馆时长
   来源：[src/data/itemCatalog.ts:106](../src/data/itemCatalog.ts#L106)
1172. 公示编号
   来源：[src/data/itemCatalog.ts:107](../src/data/itemCatalog.ts#L107)
1173. 证明数量
   来源：[src/data/itemCatalog.ts:108](../src/data/itemCatalog.ts#L108)
1174. 补录成功
   来源：[src/data/itemCatalog.ts:109](../src/data/itemCatalog.ts#L109)
1175. 记录状态
   来源：[src/data/itemCatalog.ts:109](../src/data/itemCatalog.ts#L109)
1176. 访问轨迹与 022 座位凭据的时间记录一致。
   来源：[src/data/itemCatalog.ts:111](../src/data/itemCatalog.ts#L111)
1177. 签发来源：浙大体艺访问记录补录。
   来源：[src/data/itemCatalog.ts:112](../src/data/itemCatalog.ts#L112)
1178. 适用座位
   来源：[src/data/itemCatalog.ts:120](../src/data/itemCatalog.ts#L120)
1179. 处理目标
   来源：[src/data/itemCatalog.ts:121](../src/data/itemCatalog.ts#L121)
1180. 非本人占用书包
   来源：[src/data/itemCatalog.ts:121](../src/data/itemCatalog.ts#L121)
1181. 单次有效
   来源：[src/data/itemCatalog.ts:122](../src/data/itemCatalog.ts#L122)
1182. 有效状态
   来源：[src/data/itemCatalog.ts:122](../src/data/itemCatalog.ts#L122)
1183. 已完成公开公示与三项恢复材料核验。
   来源：[src/data/itemCatalog.ts:124](../src/data/itemCatalog.ts#L124)
1184. 仅对登记为非本人的占用物有效。
   来源：[src/data/itemCatalog.ts:125](../src/data/itemCatalog.ts#L125)
1185. 取餐号
   来源：[src/data/itemCatalog.ts:140](../src/data/itemCatalog.ts#L140)
1186. 请取餐
   来源：[src/data/itemCatalog.ts:141](../src/data/itemCatalog.ts#L141)
1187. 状态
   来源：[src/data/itemCatalog.ts:141](../src/data/itemCatalog.ts#L141)；[src/data/itemCatalog.ts:165](../src/data/itemCatalog.ts#L165)
1188. 一张从点餐机吐出来的小票。
   来源：[src/data/itemCatalog.ts:143](../src/data/itemCatalog.ts#L143)
1189. 它证明你认真排过队，也认真被骗进流程。
   来源：[src/data/itemCatalog.ts:144](../src/data/itemCatalog.ts#L144)
1190. 边角湿润
   来源：[src/data/itemCatalog.ts:165](../src/data/itemCatalog.ts#L165)
1191. 纸条这次没有留下连续脚印。
   来源：[src/data/itemCatalog.ts:169](../src/data/itemCatalog.ts#L169)
1192. 潮湿痕迹只能说明它经过了有水的地方。
   来源：[src/data/itemCatalog.ts:170](../src/data/itemCatalog.ts#L170)
1193. 仍需从不同来源核对地点特征。
   来源：[src/data/itemCatalog.ts:171](../src/data/itemCatalog.ts#L171)
1194. 边角湿得很有方向感。
   来源：[src/data/itemCatalog.ts:173](../src/data/itemCatalog.ts#L173)
1195. 暗色细节
   来源：[src/data/itemCatalog.ts:185](../src/data/itemCatalog.ts#L185)
1196. 湖面左侧 / 桥影下方 / 亮点偏右
   来源：[src/data/itemCatalog.ts:185](../src/data/itemCatalog.ts#L185)
1197. 浅色细节
   来源：[src/data/itemCatalog.ts:186](../src/data/itemCatalog.ts#L186)
1198. 右侧路灯杆
   来源：[src/data/itemCatalog.ts:186](../src/data/itemCatalog.ts#L186)
1199. 两种模式记录的是同一个位置。
   来源：[src/data/itemCatalog.ts:188](../src/data/itemCatalog.ts#L188)
1200. 来源：启真湖倒影指示牌。
   来源：[src/data/itemCatalog.ts:189](../src/data/itemCatalog.ts#L189)
1201. 耳机背面的凹处已经装水，可用于完成盆栽浇水。
   来源：[src/data/items.config.json:19](../src/data/items.config.json#L19)
1202. 右向箭头
   来源：[src/data/items.config.json:81](../src/data/items.config.json#L81)
1203. 旧版离座规则
   来源：[src/data/items.config.json:109](../src/data/items.config.json#L109)；[src/data/presentation-cues.ts:125](../src/data/presentation-cues.ts#L125)
1204. 解除占座 PASS
   来源：[src/data/items.config.json:144](../src/data/items.config.json#L144)；[src/data/presentation-cues.ts:192](../src/data/presentation-cues.ts#L192)
1205. 从寝室书桌上拿来的吹风机。天气页面正在等待它处理启真湖的云层。
   来源：[src/data/items.config.json:334](../src/data/items.config.json#L334)
1206. 小鲤鱼
   来源：[src/data/items.config.json:389](../src/data/items.config.json#L389)
1207. 用鱼食引到钓点的小鲤鱼，暂时保持活性。
   来源：[src/data/items.config.json:390](../src/data/items.config.json#L390)
1208. 天鹅磁铁
   来源：[src/data/items.config.json:396](../src/data/items.config.json#L396)
1209. 黑天鹅带回的小型磁铁，可固定到钓竿末端。
   来源：[src/data/items.config.json:397](../src/data/items.config.json#L397)
1210. 磁吸钓竿
   来源：[src/data/items.config.json:403](../src/data/items.config.json#L403)
1211. 安装磁吸附件的钓竿，可接近夹在金属结构上的纸张。
   来源：[src/data/items.config.json:404](../src/data/items.config.json#L404)
1212. 签到记录纸条
   来源：[src/data/items.config.json:410](../src/data/items.config.json#L410)
1213. 它跑得比证明快。签到时需要和校园卡一起使用。
   来源：[src/data/items.config.json:411](../src/data/items.config.json#L411)
1214. 旧时针
   来源：[src/data/items.config.json:417](../src/data/items.config.json#L417)
1215. 它绕了半栋楼，最后混进了刚出炉的面包。
   来源：[src/data/items.config.json:418](../src/data/items.config.json#L418)
1216. 钟面定位片
   来源：[src/data/items.config.json:424](../src/data/items.config.json#L424)
1217. 透明塑料片，边缘有两条短刻度。它知道 7 和 55 本来该站在哪里。
   来源：[src/data/items.config.json:425](../src/data/items.config.json#L425)
1218. 短撬棍
   来源：[src/data/items.config.json:431](../src/data/items.config.json#L431)
1219. 够短，刚好能撬开别人不想让你看的缝。
   来源：[src/data/items.config.json:432](../src/data/items.config.json#L432)
1220. 通用润滑油
   来源：[src/data/items.config.json:438](../src/data/items.config.json#L438)
1221. 它解决不了人生问题，但能让卡死的东西承认自己还会转。
   来源：[src/data/items.config.json:439](../src/data/items.config.json#L439)
1222. 最后一分钟
   来源：[src/data/items.config.json:445](../src/data/items.config.json#L445)
1223. 一分钟。不多，但足够签到。
   来源：[src/data/items.config.json:446](../src/data/items.config.json#L446)
1224. 窗边豆浆
   来源：[src/data/phonePhotoCatalog.ts:41](../src/data/phonePhotoCatalog.ts#L41)
1225. 高数草稿还摊在桌上，豆浆已经冷了。
   来源：[src/data/phonePhotoCatalog.ts:44](../src/data/phonePhotoCatalog.ts#L44)
1226. 06月18日 08:43
   来源：[src/data/phonePhotoCatalog.ts:45](../src/data/phonePhotoCatalog.ts#L45)
1227. 基础馆
   来源：[src/data/phonePhotoCatalog.ts:46](../src/data/phonePhotoCatalog.ts#L46)；[src/data/phonePhotoCatalog.ts:82](../src/data/phonePhotoCatalog.ts#L82)；[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
1228. 寝室晚饭
   来源：[src/data/phonePhotoCatalog.ts:53](../src/data/phonePhotoCatalog.ts#L53)
1229. 校园卡压着充电线，桌面没有收拾。
   来源：[src/data/phonePhotoCatalog.ts:56](../src/data/phonePhotoCatalog.ts#L56)
1230. 06月19日 19:16
   来源：[src/data/phonePhotoCatalog.ts:57](../src/data/phonePhotoCatalog.ts#L57)
1231. 紫云宿舍
   来源：[src/data/phonePhotoCatalog.ts:58](../src/data/phonePhotoCatalog.ts#L58)
1232. 雨后早餐
   来源：[src/data/phonePhotoCatalog.ts:65](../src/data/phonePhotoCatalog.ts#L65)
1233. 长椅还有水迹，纸袋放在靠内侧。
   来源：[src/data/phonePhotoCatalog.ts:68](../src/data/phonePhotoCatalog.ts#L68)
1234. 06月22日 07:28
   来源：[src/data/phonePhotoCatalog.ts:69](../src/data/phonePhotoCatalog.ts#L69)
1235. 东区
   来源：[src/data/phonePhotoCatalog.ts:70](../src/data/phonePhotoCatalog.ts#L70)
1236. 自习间隙
   来源：[src/data/phonePhotoCatalog.ts:77](../src/data/phonePhotoCatalog.ts#L77)
1237. 面包包装拆了一半，保温杯放在右边。
   来源：[src/data/phonePhotoCatalog.ts:80](../src/data/phonePhotoCatalog.ts#L80)
1238. 06月24日 16:02
   来源：[src/data/phonePhotoCatalog.ts:81](../src/data/phonePhotoCatalog.ts#L81)
1239. 食堂打包
   来源：[src/data/phonePhotoCatalog.ts:89](../src/data/phonePhotoCatalog.ts#L89)
1240. 餐巾纸折在盒饭旁边，桌面很干净。
   来源：[src/data/phonePhotoCatalog.ts:92](../src/data/phonePhotoCatalog.ts#L92)
1241. 06月26日 18:51
   来源：[src/data/phonePhotoCatalog.ts:93](../src/data/phonePhotoCatalog.ts#L93)
1242. 东区食堂
   来源：[src/data/phonePhotoCatalog.ts:94](../src/data/phonePhotoCatalog.ts#L94)；[src/data/phonePhotoCatalog.ts:178](../src/data/phonePhotoCatalog.ts#L178)
1243. 022 旧照
   来源：[src/data/phonePhotoCatalog.ts:101](../src/data/phonePhotoCatalog.ts#L101)
1244. 同一只 022 书包。侧袋里的半包纸，在 07:55 时已经存在。
   来源：[src/data/phonePhotoCatalog.ts:104](../src/data/phonePhotoCatalog.ts#L104)
1245. 06月28日 07:55
   来源：[src/data/phonePhotoCatalog.ts:105](../src/data/phonePhotoCatalog.ts#L105)
1246. 基础馆二楼南区
   来源：[src/data/phonePhotoCatalog.ts:106](../src/data/phonePhotoCatalog.ts#L106)
1247. 校门口的阴天
   来源：[src/data/phonePhotoCatalog.ts:113](../src/data/phonePhotoCatalog.ts#L113)
1248. 树荫压得很低，骑车的人都从拱门边绕过去。
   来源：[src/data/phonePhotoCatalog.ts:116](../src/data/phonePhotoCatalog.ts#L116)
1249. 07月01日 14:32
   来源：[src/data/phonePhotoCatalog.ts:117](../src/data/phonePhotoCatalog.ts#L117)
1250. 启真湖早晨
   来源：[src/data/phonePhotoCatalog.ts:125](../src/data/phonePhotoCatalog.ts#L125)
1251. 浮桥旁有两圈新波纹，车还停在柳树下面。
   来源：[src/data/phonePhotoCatalog.ts:128](../src/data/phonePhotoCatalog.ts#L128)
1252. 07月02日 09:12
   来源：[src/data/phonePhotoCatalog.ts:129](../src/data/phonePhotoCatalog.ts#L129)
1253. 雨后的月牙楼
   来源：[src/data/phonePhotoCatalog.ts:137](../src/data/phonePhotoCatalog.ts#L137)
1254. 地砖还在反光，伞已经可以收起来了。
   来源：[src/data/phonePhotoCatalog.ts:140](../src/data/phonePhotoCatalog.ts#L140)
1255. 07月03日 16:47
   来源：[src/data/phonePhotoCatalog.ts:141](../src/data/phonePhotoCatalog.ts#L141)
1256. 晚自习加餐
   来源：[src/data/phonePhotoCatalog.ts:149](../src/data/phonePhotoCatalog.ts#L149)
1257. 耳机缠在本子边，饭盒还留着一点热气。
   来源：[src/data/phonePhotoCatalog.ts:152](../src/data/phonePhotoCatalog.ts#L152)
1258. 07月05日 21:06
   来源：[src/data/phonePhotoCatalog.ts:153](../src/data/phonePhotoCatalog.ts#L153)
1259. 学习空间
   来源：[src/data/phonePhotoCatalog.ts:154](../src/data/phonePhotoCatalog.ts#L154)
1260. 车筐里的雨衣
   来源：[src/data/phonePhotoCatalog.ts:161](../src/data/phonePhotoCatalog.ts#L161)
1261. 雨停得很快，车筐上还挂着水珠。
   来源：[src/data/phonePhotoCatalog.ts:164](../src/data/phonePhotoCatalog.ts#L164)
1262. 07月06日 12:23
   来源：[src/data/phonePhotoCatalog.ts:165](../src/data/phonePhotoCatalog.ts#L165)
1263. 宿舍区
   来源：[src/data/phonePhotoCatalog.ts:166](../src/data/phonePhotoCatalog.ts#L166)
1264. 午饭排队
   来源：[src/data/phonePhotoCatalog.ts:173](../src/data/phonePhotoCatalog.ts#L173)
1265. 前面只剩三个人，番茄鸡蛋面先端到了。
   来源：[src/data/phonePhotoCatalog.ts:176](../src/data/phonePhotoCatalog.ts#L176)
1266. 07月07日 11:54
   来源：[src/data/phonePhotoCatalog.ts:177](../src/data/phonePhotoCatalog.ts#L177)
1267. 找到道具栏
   来源：[src/data/presentation-cues.ts:34](../src/data/presentation-cues.ts#L34)
1268. 校园地图内出现了可调查的寝室据点
   来源：[src/data/presentation-cues.ts:35](../src/data/presentation-cues.ts#L35)
1269. 箱
   来源：[src/data/presentation-cues.ts:36](../src/data/presentation-cues.ts#L36)
1270. 让地图人物回应你
   来源：[src/data/presentation-cues.ts:42](../src/data/presentation-cues.ts#L42)
1271. 先让寝室里的人知道自己是谁
   来源：[src/data/presentation-cues.ts:43](../src/data/presentation-cues.ts#L43)
1272. 右移箭头已合成
   来源：[src/data/presentation-cues.ts:50](../src/data/presentation-cues.ts#L50)
1273. 它能把一个目标向右移动两格
   来源：[src/data/presentation-cues.ts:51](../src/data/presentation-cues.ts#L51)
1274. 交易完成
   来源：[src/data/presentation-cues.ts:58](../src/data/presentation-cues.ts#L58)
1275. 游戏手柄已放入道具栏
   来源：[src/data/presentation-cues.ts:59](../src/data/presentation-cues.ts#L59)
1276. 可以出门了
   来源：[src/data/presentation-cues.ts:66](../src/data/presentation-cues.ts#L66)；[src/scenes/rpg/RpgGameHost.tsx:1446](../src/scenes/rpg/RpgGameHost.tsx#L1446)
1277. 寝室出口已开放
   来源：[src/data/presentation-cues.ts:67](../src/data/presentation-cues.ts#L67)
1278. 门
   来源：[src/data/presentation-cues.ts:68](../src/data/presentation-cues.ts#L68)
1279. 进入图书馆，找到 022
   来源：[src/data/presentation-cues.ts:74](../src/data/presentation-cues.ts#L74)
1280. 基础图书馆入口已开放
   来源：[src/data/presentation-cues.ts:75](../src/data/presentation-cues.ts#L75)
1281. 入馆记录待核对
   来源：[src/data/presentation-cues.ts:82](../src/data/presentation-cues.ts#L82)
1282. 点击闸机旁的小屏查看两条时间
   来源：[src/data/presentation-cues.ts:83](../src/data/presentation-cues.ts#L83)
1283. 022 被书包占用
   来源：[src/data/presentation-cues.ts:91](../src/data/presentation-cues.ts#L91)
1284. 调查纸条与离座规则
   来源：[src/data/presentation-cues.ts:92](../src/data/presentation-cues.ts#L92)
1285. 获得占座纸条
   来源：[src/data/presentation-cues.ts:100](../src/data/presentation-cues.ts#L100)
1286. 可拖入 CC98 搜索
   来源：[src/data/presentation-cues.ts:101](../src/data/presentation-cues.ts#L101)
1287. 调查帖已找到
   来源：[src/data/presentation-cues.ts:109](../src/data/presentation-cues.ts#L109)
1288. 23 楼内容，5 条 ac01 可选
   来源：[src/data/presentation-cues.ts:110](../src/data/presentation-cues.ts#L110)
1289. 正确馆藏已确认
   来源：[src/data/presentation-cues.ts:117](../src/data/presentation-cues.ts#L117)
1290. 索书号 I247.55 / 755
   来源：[src/data/presentation-cues.ts:118](../src/data/presentation-cues.ts#L118)
1291. 恢复 022 需要三项证明
   来源：[src/data/presentation-cues.ts:126](../src/data/presentation-cues.ts#L126)
1292. 物品识别报告已生成
   来源：[src/data/presentation-cues.ts:134](../src/data/presentation-cues.ts#L134)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:203](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L203)
1293. 对象类型：书包
   来源：[src/data/presentation-cues.ts:135](../src/data/presentation-cues.ts#L135)
1294. 失物招领登记已盖章
   来源：[src/data/presentation-cues.ts:143](../src/data/presentation-cues.ts#L143)
1295. 章
   来源：[src/data/presentation-cues.ts:144](../src/data/presentation-cues.ts#L144)
1296. 右移箭头仍保留在道具栏
   来源：[src/data/presentation-cues.ts:152](../src/data/presentation-cues.ts#L152)
1297. 7 / 47 / 3 补录通过
   来源：[src/data/presentation-cues.ts:161](../src/data/presentation-cues.ts#L161)
1298. 四项证据已公示
   来源：[src/data/presentation-cues.ts:168](../src/data/presentation-cues.ts#L168)
1299. 系统将说明帮顶与四位口令规则
   来源：[src/data/presentation-cues.ts:169](../src/data/presentation-cues.ts#L169)
1300. 进入十大
   来源：[src/data/presentation-cues.ts:176](../src/data/presentation-cues.ts#L176)
1301. 剧情帖排名 01
   来源：[src/data/presentation-cues.ts:177](../src/data/presentation-cues.ts#L177)
1302. 022 恢复申请已开放
   来源：[src/data/presentation-cues.ts:184](../src/data/presentation-cues.ts#L184)
1303. 提交三项恢复证明
   来源：[src/data/presentation-cues.ts:185](../src/data/presentation-cues.ts#L185)
1304. 仅可用于 RPG 中的 022 书包
   来源：[src/data/presentation-cues.ts:193](../src/data/presentation-cues.ts#L193)
1305. 占座对象已转移
   来源：[src/data/presentation-cues.ts:200](../src/data/presentation-cues.ts#L200)
1306. 书包已送往失物招领
   来源：[src/data/presentation-cues.ts:201](../src/data/presentation-cues.ts#L201)
1307. 它正在船尾对准航线。继续交替划桨。
   来源：[src/data/pursuit.audio.content.json:59](../src/data/pursuit.audio.content.json#L59)
1308. It is lining up behind you. Keep alternating.
   来源：[src/data/pursuit.audio.content.json:60](../src/data/pursuit.audio.content.json#L60)
1309. 闹钟
   来源：[src/data/scenes.config.json:2](../src/data/scenes.config.json#L2)
1310. P00
   来源：[src/data/scenes.config.json:2](../src/data/scenes.config.json#L2)
1311. 07:55 起床
   来源：[src/data/scenes.config.json:3](../src/data/scenes.config.json#L3)
1312. P01
   来源：[src/data/scenes.config.json:3](../src/data/scenes.config.json#L3)
1313. 手机主界面
   来源：[src/data/scenes.config.json:4](../src/data/scenes.config.json#L4)
1314. P13
   来源：[src/data/scenes.config.json:4](../src/data/scenes.config.json#L4)
1315. 微信 / 朋友头像谜题
   来源：[src/data/scenes.config.json:5](../src/data/scenes.config.json#L5)
1316. P14
   来源：[src/data/scenes.config.json:5](../src/data/scenes.config.json#L5)
1317. 浙大钉（加载/内页）
   来源：[src/data/scenes.config.json:6](../src/data/scenes.config.json#L6)
1318. P15
   来源：[src/data/scenes.config.json:6](../src/data/scenes.config.json#L6)
1319. 浙大体艺
   来源：[src/data/scenes.config.json:7](../src/data/scenes.config.json#L7)；[src/scenes/phone/P08_Settings/index.tsx:29](../src/scenes/phone/P08_Settings/index.tsx#L29)
1320. P06
   来源：[src/data/scenes.config.json:7](../src/data/scenes.config.json#L7)
1321. 天气 / 水滴谜题
   来源：[src/data/scenes.config.json:8](../src/data/scenes.config.json#L8)
1322. P07
   来源：[src/data/scenes.config.json:8](../src/data/scenes.config.json#L8)
1323. 玩家
   来源：[src/data/storyLines.ts:60](../src/data/storyLines.ts#L60)；[src/scenes/phone/P02_CC98/index.tsx:124](../src/scenes/phone/P02_CC98/index.tsx#L124)
1324. 基础图书馆门前
   来源：[src/demos/campus-map-demo.tsx:32](../src/demos/campus-map-demo.tsx#L32)
1325. 大食堂门前
   来源：[src/demos/campus-map-demo.tsx:33](../src/demos/campus-map-demo.tsx#L33)
1326. 追踪脚印
   来源：[src/demos/campus-map-demo.tsx:46](../src/demos/campus-map-demo.tsx#L46)
1327. 抵达食堂
   来源：[src/demos/campus-map-demo.tsx:47](../src/demos/campus-map-demo.tsx#L47)
1328. 进入食堂
   来源：[src/demos/campus-map-demo.tsx:48](../src/demos/campus-map-demo.tsx#L48)
1329. 寻找异常餐盘
   来源：[src/demos/campus-map-demo.tsx:49](../src/demos/campus-map-demo.tsx#L49)
1330. 调配今日新品
   来源：[src/demos/campus-map-demo.tsx:50](../src/demos/campus-map-demo.tsx#L50)
1331. 破解点餐机
   来源：[src/demos/campus-map-demo.tsx:51](../src/demos/campus-map-demo.tsx#L51)
1332. 寻找 0755 窗口
   来源：[src/demos/campus-map-demo.tsx:52](../src/demos/campus-map-demo.tsx#L52)
1333. 封堵纸条出口
   来源：[src/demos/campus-map-demo.tsx:53](../src/demos/campus-map-demo.tsx#L53)
1334. 准备继续追赶
   来源：[src/demos/campus-map-demo.tsx:54](../src/demos/campus-map-demo.tsx#L54)
1335. 追逐中
   来源：[src/demos/campus-map-demo.tsx:55](../src/demos/campus-map-demo.tsx#L55)
1336. 抵达体艺馆
   来源：[src/demos/campus-map-demo.tsx:56](../src/demos/campus-map-demo.tsx#L56)
1337. 地图加载中…
   来源：[src/demos/campus-map-demo.tsx:168](../src/demos/campus-map-demo.tsx#L168)
1338. 食堂内的纸条已被逼出，已返回大食堂门前。
   来源：[src/demos/campus-map-demo.tsx:224](../src/demos/campus-map-demo.tsx#L224)
1339. 大食堂剧情已重开：已到{{target.label}}，按空格进入。
   来源：[src/demos/campus-map-demo.tsx:358](../src/demos/campus-map-demo.tsx#L358)
1340. 已回到{{target.label}}，当前为自由探索。
   来源：[src/demos/campus-map-demo.tsx:359](../src/demos/campus-map-demo.tsx#L359)
1341. 紫金港校园大地图与大食堂剧情演示
   来源：[src/demos/campus-map-demo.tsx:385](../src/demos/campus-map-demo.tsx#L385)
1342. 校园与大食堂剧情交互区
   来源：[src/demos/campus-map-demo.tsx:388](../src/demos/campus-map-demo.tsx#L388)
1343. 大食堂剧情
   来源：[src/demos/campus-map-demo.tsx:393](../src/demos/campus-map-demo.tsx#L393)；[src/demos/campus-map-demo.tsx:400](../src/demos/campus-map-demo.tsx#L400)
1344. 紫金港校园大地图
   来源：[src/demos/campus-map-demo.tsx:393](../src/demos/campus-map-demo.tsx#L393)
1345. 演示操作
   来源：[src/demos/campus-map-demo.tsx:398](../src/demos/campus-map-demo.tsx#L398)
1346. 自由探索
   来源：[src/demos/campus-map-demo.tsx:399](../src/demos/campus-map-demo.tsx#L399)
1347. 切到深色
   来源：[src/demos/campus-map-demo.tsx:409](../src/demos/campus-map-demo.tsx#L409)
1348. 切回浅色
   来源：[src/demos/campus-map-demo.tsx:409](../src/demos/campus-map-demo.tsx#L409)
1349. 回到角色
   来源：[src/demos/campus-map-demo.tsx:414](../src/demos/campus-map-demo.tsx#L414)
1350. 缩小地图
   来源：[src/demos/campus-map-demo.tsx:415](../src/demos/campus-map-demo.tsx#L415)
1351. 放大地图
   来源：[src/demos/campus-map-demo.tsx:416](../src/demos/campus-map-demo.tsx#L416)
1352. 全屏
   来源：[src/demos/campus-map-demo.tsx:419](../src/demos/campus-map-demo.tsx#L419)
1353. 坐标
   来源：[src/demos/campus-map-demo.tsx:423](../src/demos/campus-map-demo.tsx#L423)
1354. 缩放
   来源：[src/demos/campus-map-demo.tsx:424](../src/demos/campus-map-demo.tsx#L424)
1355. 剧情
   来源：[src/demos/campus-map-demo.tsx:427](../src/demos/campus-map-demo.tsx#L427)
1356. 浅色模式
   来源：[src/demos/campus-map-demo.tsx:428](../src/demos/campus-map-demo.tsx#L428)
1357. 深色模式
   来源：[src/demos/campus-map-demo.tsx:428](../src/demos/campus-map-demo.tsx#L428)
1358. WASD / 方向键移动 · 空格交互 · Tab 切换明暗
   来源：[src/demos/campus-map-demo.tsx:433](../src/demos/campus-map-demo.tsx#L433)
1359. WASD / 方向键移动 · Shift 冲刺 · 空格进入 · 单击路面寻路
   来源：[src/demos/campus-map-demo.tsx:434](../src/demos/campus-map-demo.tsx#L434)
1360. 触控方向与交互
   来源：[src/demos/campus-map-demo.tsx:439](../src/demos/campus-map-demo.tsx#L439)
1361. 向上移动
   来源：[src/demos/campus-map-demo.tsx:440](../src/demos/campus-map-demo.tsx#L440)
1362. 向左移动
   来源：[src/demos/campus-map-demo.tsx:441](../src/demos/campus-map-demo.tsx#L441)
1363. 向下移动
   来源：[src/demos/campus-map-demo.tsx:442](../src/demos/campus-map-demo.tsx#L442)
1364. 向右移动
   来源：[src/demos/campus-map-demo.tsx:443](../src/demos/campus-map-demo.tsx#L443)
1365. 空格
   来源：[src/demos/campus-map-demo.tsx:444](../src/demos/campus-map-demo.tsx#L444)；[src/scenes/rpg/RpgControlHints.ts:6](../src/scenes/rpg/RpgControlHints.ts#L6)
1366. 页面运行出错
   来源：[src/ErrorBoundary.tsx:26](../src/ErrorBoundary.tsx#L26)
1367. 多云
   来源：[src/modules/CampusWeatherModel.ts:5](../src/modules/CampusWeatherModel.ts#L5)；[src/modules/CampusWeatherModel.ts:13](../src/modules/CampusWeatherModel.ts#L13)
1368. 小雨
   来源：[src/modules/CampusWeatherModel.ts:5](../src/modules/CampusWeatherModel.ts#L5)；[src/modules/CampusWeatherModel.ts:11](../src/modules/CampusWeatherModel.ts#L11)
1369. 校名缩写
   来源：[src/modules/Cc98UnifiedLoginModel.ts:11](../src/modules/Cc98UnifiedLoginModel.ts#L11)
1370. 取浙江大学英文名的三个大写字母。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:12](../src/modules/Cc98UnifiedLoginModel.ts#L12)
1371. 校史年份
   来源：[src/modules/Cc98UnifiedLoginModel.ts:17](../src/modules/Cc98UnifiedLoginModel.ts#L17)
1372. 接上求是书院创办的四位年份。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:18](../src/modules/Cc98UnifiedLoginModel.ts#L18)
1373. 结尾标点
   来源：[src/modules/Cc98UnifiedLoginModel.ts:23](../src/modules/Cc98UnifiedLoginModel.ts#L23)
1374. 保留认证公告最后的感叹号。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:24](../src/modules/Cc98UnifiedLoginModel.ts#L24)
1375. already\_authenticated
   来源：[src/modules/Cc98UnifiedLoginModel.ts:76](../src/modules/Cc98UnifiedLoginModel.ts#L76)
1376. identity\_unavailable
   来源：[src/modules/Cc98UnifiedLoginModel.ts:77](../src/modules/Cc98UnifiedLoginModel.ts#L77)
1377. authenticated
   来源：[src/modules/Cc98UnifiedLoginModel.ts:84](../src/modules/Cc98UnifiedLoginModel.ts#L84)
1378. rejected
   来源：[src/modules/Cc98UnifiedLoginModel.ts:89](../src/modules/Cc98UnifiedLoginModel.ts#L89)
1379. both
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1380. password
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1381. student\_id
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1382. network
   来源：[src/modules/CheckinController.ts:19](../src/modules/CheckinController.ts#L19)
1383. wrong\_code
   来源：[src/modules/CheckinController.ts:24](../src/modules/CheckinController.ts#L24)
1384. 磁性钓鱼竿
   来源：[src/modules/InventoryController.ts:18](../src/modules/InventoryController.ts#L18)
1385. developer\_checkpoint\_session
   来源：[src/modules/SaveController.ts:26](../src/modules/SaveController.ts#L26)
1386. 匿名用户
   来源：[src/scenes/phone/P02_CC98/index.tsx:56](../src/scenes/phone/P02_CC98/index.tsx#L56)
1387. 刚刚
   来源：[src/scenes/phone/P02_CC98/index.tsx:63](../src/scenes/phone/P02_CC98/index.tsx#L63)；[src/scenes/phone/P02_CC98/index.tsx:222](../src/scenes/phone/P02_CC98/index.tsx#L222)
1388. 如题。
   来源：[src/scenes/phone/P02_CC98/index.tsx:64](../src/scenes/phone/P02_CC98/index.tsx#L64)
1389. 今天 09:{{String(12 + index \* 2).padStart(2, "0")}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:67](../src/scenes/phone/P02_CC98/index.tsx#L67)
1390. {{\[3, 8, 14\]\[index\]}}楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:68](../src/scenes/phone/P02_CC98/index.tsx#L68)
1391. 今天 {{reply.time}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:95](../src/scenes/phone/P02_CC98/index.tsx#L95)
1392. 今天 08:29
   来源：[src/scenes/phone/P02_CC98/index.tsx:112](../src/scenes/phone/P02_CC98/index.tsx#L112)
1393. 今天 08:30
   来源：[src/scenes/phone/P02_CC98/index.tsx:122](../src/scenes/phone/P02_CC98/index.tsx#L122)
1394. 今天 08:31
   来源：[src/scenes/phone/P02_CC98/index.tsx:133](../src/scenes/phone/P02_CC98/index.tsx#L133)
1395. 网络提示
   来源：[src/scenes/phone/P02_CC98/index.tsx:135](../src/scenes/phone/P02_CC98/index.tsx#L135)
1396. 今天 08:32
   来源：[src/scenes/phone/P02_CC98/index.tsx:144](../src/scenes/phone/P02_CC98/index.tsx#L144)
1397. 系统回执
   来源：[src/scenes/phone/P02_CC98/index.tsx:146](../src/scenes/phone/P02_CC98/index.tsx#L146)
1398. 23 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:169](../src/scenes/phone/P02_CC98/index.tsx#L169)
1399. 【求助】022 座位今日临时离开
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1400. 12 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1401. 来源不匹配：这是今日新帖，纸条引用的是旧版公开记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1402. 来源为今日新帖，没有旧版离座规定的引用。
   来源：[src/scenes/phone/P02_CC98/index.tsx:170](../src/scenes/phone/P02_CC98/index.tsx#L170)
1403. 【记录】二南 022 晚间使用情况
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1404. 31 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1405. 发布时间为当日 22:40，早于纸条中的本次离座事件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1406. 时间不匹配：这条记录早于本次 022 占用事件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:171](../src/scenes/phone/P02_CC98/index.tsx#L171)
1407. 【闲聊】二楼南区今天还有位置吗
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1408. 18 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1409. 附件不匹配：这条帖子没有纸条对应的离座凭据。
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1410. 正文提到 022，附件区为空。
   来源：[src/scenes/phone/P02_CC98/index.tsx:172](../src/scenes/phone/P02_CC98/index.tsx#L172)
1411. 本月
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1412. 本周
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1413. 发现
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1414. 活动
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1415. 今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)；[src/scenes/phone/P02_CC98/index.tsx:817](../src/scenes/phone/P02_CC98/index.tsx#L817)
1416. 往年今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:181](../src/scenes/phone/P02_CC98/index.tsx#L181)
1417. 新帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:184](../src/scenes/phone/P02_CC98/index.tsx#L184)；[src/scenes/phone/P02_CC98/index.tsx:946](../src/scenes/phone/P02_CC98/index.tsx#L946)
1418. 关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:185](../src/scenes/phone/P02_CC98/index.tsx#L185)；[src/scenes/phone/P02_CC98/index.tsx:906](../src/scenes/phone/P02_CC98/index.tsx#L906)
1419. 版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:186](../src/scenes/phone/P02_CC98/index.tsx#L186)
1420. 校内日常、天气和临时消息
   来源：[src/scenes/phone/P02_CC98/index.tsx:207](../src/scenes/phone/P02_CC98/index.tsx#L207)
1421. 步行、骑行和校内出行
   来源：[src/scenes/phone/P02_CC98/index.tsx:208](../src/scenes/phone/P02_CC98/index.tsx#L208)
1422. 资料、课程和复习讨论
   来源：[src/scenes/phone/P02_CC98/index.tsx:209](../src/scenes/phone/P02_CC98/index.tsx#L209)
1423. 电话卡、网络和通讯服务
   来源：[src/scenes/phone/P02_CC98/index.tsx:210](../src/scenes/phone/P02_CC98/index.tsx#L210)
1424. 馆内规则、座位和设备
   来源：[src/scenes/phone/P02_CC98/index.tsx:211](../src/scenes/phone/P02_CC98/index.tsx#L211)
1425. 自习地点与安静程度
   来源：[src/scenes/phone/P02_CC98/index.tsx:212](../src/scenes/phone/P02_CC98/index.tsx#L212)
1426. 窗口、排队和座位
   来源：[src/scenes/phone/P02_CC98/index.tsx:213](../src/scenes/phone/P02_CC98/index.tsx#L213)
1427. 打印、复印和取件
   来源：[src/scenes/phone/P02_CC98/index.tsx:214](../src/scenes/phone/P02_CC98/index.tsx#L214)
1428. 校园卡使用和服务记录
   来源：[src/scenes/phone/P02_CC98/index.tsx:215](../src/scenes/phone/P02_CC98/index.tsx#L215)
1429. 遗失物和失物信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:216](../src/scenes/phone/P02_CC98/index.tsx#L216)
1430. 闲置物品与当面交易提醒
   来源：[src/scenes/phone/P02_CC98/index.tsx:217](../src/scenes/phone/P02_CC98/index.tsx#L217)
1431. 轻松话题和校园小事
   来源：[src/scenes/phone/P02_CC98/index.tsx:218](../src/scenes/phone/P02_CC98/index.tsx#L218)
1432. 课程与年份入口
   来源：[src/scenes/phone/P02_CC98/index.tsx:269](../src/scenes/phone/P02_CC98/index.tsx#L269)
1433. 先选课程，再按年份进入资料目录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:270](../src/scenes/phone/P02_CC98/index.tsx#L270)
1434. 旧自习讨论
   来源：[src/scenes/phone/P02_CC98/index.tsx:274](../src/scenes/phone/P02_CC98/index.tsx#L274)
1435. 旧帖能核对座位与插座记录，但日期可能已经过期。
   来源：[src/scenes/phone/P02_CC98/index.tsx:275](../src/scenes/phone/P02_CC98/index.tsx#L275)
1436. 今晚仍要现场核验
   来源：[src/scenes/phone/P02_CC98/index.tsx:279](../src/scenes/phone/P02_CC98/index.tsx#L279)
1437. A2 的门牌、房间和通道以今晚实际情况为准。
   来源：[src/scenes/phone/P02_CC98/index.tsx:280](../src/scenes/phone/P02_CC98/index.tsx#L280)
1438. 首页推荐顺序
   来源：[src/scenes/phone/P02_CC98/index.tsx:284](../src/scenes/phone/P02_CC98/index.tsx#L284)
1439. 推荐位会变化，无法作为资料目录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:285](../src/scenes/phone/P02_CC98/index.tsx#L285)
1440. 直接照抄旧路线
   来源：[src/scenes/phone/P02_CC98/index.tsx:289](../src/scenes/phone/P02_CC98/index.tsx#L289)
1441. 旧路线没有记录今晚的封闭入口。
   来源：[src/scenes/phone/P02_CC98/index.tsx:290](../src/scenes/phone/P02_CC98/index.tsx#L290)
1442. accepted
   来源：[src/scenes/phone/P02_CC98/index.tsx:311](../src/scenes/phone/P02_CC98/index.tsx#L311)；[src/scenes/rpg/RpgGameHost.tsx:1440](../src/scenes/rpg/RpgGameHost.tsx#L1440)；[src/scenes/rpg/RpgGameHost.tsx:1524](../src/scenes/rpg/RpgGameHost.tsx#L1524)；[src/scenes/rpg/RpgGameHost.tsx:1552](../src/scenes/rpg/RpgGameHost.tsx#L1552)；[src/scenes/rpg/RpgGameHost.tsx:1560](../src/scenes/rpg/RpgGameHost.tsx#L1560)；[src/scenes/rpg/RpgGameHost.tsx:1572](../src/scenes/rpg/RpgGameHost.tsx#L1572)；[src/scenes/rpg/RpgGameHost.tsx:1585](../src/scenes/rpg/RpgGameHost.tsx#L1585)；[src/scenes/rpg/RpgGameHost.tsx:1610](../src/scenes/rpg/RpgGameHost.tsx#L1610)；[src/scenes/rpg/RpgGameHost.tsx:1620](../src/scenes/rpg/RpgGameHost.tsx#L1620)；[src/scenes/rpg/RpgGameHost.tsx:1627](../src/scenes/rpg/RpgGameHost.tsx#L1627)
1443. already\_complete
   来源：[src/scenes/phone/P02_CC98/index.tsx:313](../src/scenes/phone/P02_CC98/index.tsx#L313)
1444. incorrect
   来源：[src/scenes/phone/P02_CC98/index.tsx:315](../src/scenes/phone/P02_CC98/index.tsx#L315)
1445. 这三项里混进了今晚无法使用的信息。再看一遍帖子和回复。
   来源：[src/scenes/phone/P02_CC98/index.tsx:316](../src/scenes/phone/P02_CC98/index.tsx#L316)
1446. 学习天地资料索引已导入自习群。
   来源：[src/scenes/phone/P02_CC98/index.tsx:323](../src/scenes/phone/P02_CC98/index.tsx#L323)
1447. 筛选并导入学习天地资料
   来源：[src/scenes/phone/P02_CC98/index.tsx:328](../src/scenes/phone/P02_CC98/index.tsx#L328)
1448. 导入前核对
   来源：[src/scenes/phone/P02_CC98/index.tsx:330](../src/scenes/phone/P02_CC98/index.tsx#L330)
1449. 选出今晚还能使用的三项信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:331](../src/scenes/phone/P02_CC98/index.tsx#L331)
1450. 已导入麦斯威夜间自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:357](../src/scenes/phone/P02_CC98/index.tsx#L357)
1451. 从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。
   来源：[src/scenes/phone/P02_CC98/index.tsx:436](../src/scenes/phone/P02_CC98/index.tsx#L436)
1452. 启真湖 · 22:37:05
   来源：[src/scenes/phone/P02_CC98/index.tsx:437](../src/scenes/phone/P02_CC98/index.tsx#L437)
1453. 晚上水面反光挺亮，靠岸别太快。
   来源：[src/scenes/phone/P02_CC98/index.tsx:440](../src/scenes/phone/P02_CC98/index.tsx#L440)
1454. 最后一张图像是朝东边拍的。
   来源：[src/scenes/phone/P02_CC98/index.tsx:441](../src/scenes/phone/P02_CC98/index.tsx#L441)
1455. 本次记录准备结束，选择楼主的最后一条回复。
   来源：[src/scenes/phone/P02_CC98/index.tsx:444](../src/scenes/phone/P02_CC98/index.tsx#L444)
1456. qizhen-summary
   来源：[src/scenes/phone/P02_CC98/index.tsx:448](../src/scenes/phone/P02_CC98/index.tsx#L448)；[src/scenes/phone/P02_CC98/index.tsx:458](../src/scenes/phone/P02_CC98/index.tsx#L458)
1457. 安全返航
   来源：[src/scenes/phone/P02_CC98/index.tsx:452](../src/scenes/phone/P02_CC98/index.tsx#L452)
1458. 船和人都回来了。湖上的事先记到这里，剩下的等我整理。
   来源：[src/scenes/phone/P02_CC98/index.tsx:453](../src/scenes/phone/P02_CC98/index.tsx#L453)
1459. 细节暂不公开
   来源：[src/scenes/phone/P02_CC98/index.tsx:462](../src/scenes/phone/P02_CC98/index.tsx#L462)
1460. 最后一段发生了点不适合写进划船记录的事。人已上岸，其他细节暂时保留。
   来源：[src/scenes/phone/P02_CC98/index.tsx:463](../src/scenes/phone/P02_CC98/index.tsx#L463)
1461. 发布收尾并保存时间
   来源：[src/scenes/phone/P02_CC98/index.tsx:466](../src/scenes/phone/P02_CC98/index.tsx#L466)
1462. 纸条已读取。请核对搜索结果的来源、时间和附件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:535](../src/scenes/phone/P02_CC98/index.tsx#L535)
1463. 湿纸特征已加入搜索。找到一条刚发布的目击帖。
   来源：[src/scenes/phone/P02_CC98/index.tsx:540](../src/scenes/phone/P02_CC98/index.tsx#L540)
1464. 校内讨论和临时信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:597](../src/scenes/phone/P02_CC98/index.tsx#L597)
1465. CC98 仅支持校园网。请切换后重新进入。
   来源：[src/scenes/phone/P02_CC98/index.tsx:631](../src/scenes/phone/P02_CC98/index.tsx#L631)
1466. CC98 校园网验证
   来源：[src/scenes/phone/P02_CC98/index.tsx:645](../src/scenes/phone/P02_CC98/index.tsx#L645)
1467. 网络验证失败
   来源：[src/scenes/phone/P02_CC98/index.tsx:649](../src/scenes/phone/P02_CC98/index.tsx#L649)
1468. 校内访问验证
   来源：[src/scenes/phone/P02_CC98/index.tsx:649](../src/scenes/phone/P02_CC98/index.tsx#L649)
1469. 正在恢复手机票务页面
   来源：[src/scenes/phone/P02_CC98/index.tsx:651](../src/scenes/phone/P02_CC98/index.tsx#L651)
1470. 正在连接校园网服务
   来源：[src/scenes/phone/P02_CC98/index.tsx:651](../src/scenes/phone/P02_CC98/index.tsx#L651)
1471. 正在检查 ZJUWLAN
   来源：[src/scenes/phone/P02_CC98/index.tsx:652](../src/scenes/phone/P02_CC98/index.tsx#L652)
1472. 这条 23 楼记录尚未满足调查门槛。
   来源：[src/scenes/phone/P02_CC98/index.tsx:705](../src/scenes/phone/P02_CC98/index.tsx#L705)
1473. CC98 帖子已保存到本机。
   来源：[src/scenes/phone/P02_CC98/index.tsx:726](../src/scenes/phone/P02_CC98/index.tsx#L726)
1474. CC98 帖子已恢复为默认内容。
   来源：[src/scenes/phone/P02_CC98/index.tsx:782](../src/scenes/phone/P02_CC98/index.tsx#L782)
1475. CC98热门话题
   来源：[src/scenes/phone/P02_CC98/index.tsx:786](../src/scenes/phone/P02_CC98/index.tsx#L786)
1476. 退出 CC98，返回手机主页
   来源：[src/scenes/phone/P02_CC98/index.tsx:791](../src/scenes/phone/P02_CC98/index.tsx#L791)
1477. 热门话题
   来源：[src/scenes/phone/P02_CC98/index.tsx:794](../src/scenes/phone/P02_CC98/index.tsx#L794)
1478. 开发者帖子维护
   来源：[src/scenes/phone/P02_CC98/index.tsx:795](../src/scenes/phone/P02_CC98/index.tsx#L795)
1479. 更多
   来源：[src/scenes/phone/P02_CC98/index.tsx:796](../src/scenes/phone/P02_CC98/index.tsx#L796)
1480. CC98更多菜单
   来源：[src/scenes/phone/P02_CC98/index.tsx:796](../src/scenes/phone/P02_CC98/index.tsx#L796)
1481. 保存帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:799](../src/scenes/phone/P02_CC98/index.tsx#L799)
1482. 编辑帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:799](../src/scenes/phone/P02_CC98/index.tsx#L799)
1483. 保存
   来源：[src/scenes/phone/P02_CC98/index.tsx:800](../src/scenes/phone/P02_CC98/index.tsx#L800)
1484. 编辑
   来源：[src/scenes/phone/P02_CC98/index.tsx:800](../src/scenes/phone/P02_CC98/index.tsx#L800)
1485. 恢复默认帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:808](../src/scenes/phone/P02_CC98/index.tsx#L808)
1486. 关闭菜单
   来源：[src/scenes/phone/P02_CC98/index.tsx:811](../src/scenes/phone/P02_CC98/index.tsx#L811)
1487. 热门话题时间筛选
   来源：[src/scenes/phone/P02_CC98/index.tsx:816](../src/scenes/phone/P02_CC98/index.tsx#L816)
1488. CC98占座调查搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:822](../src/scenes/phone/P02_CC98/index.tsx#L822)
1489. 可接收道具
   来源：[src/scenes/phone/P02_CC98/index.tsx:823](../src/scenes/phone/P02_CC98/index.tsx#L823)；[src/scenes/phone/P02_CC98/index.tsx:857](../src/scenes/phone/P02_CC98/index.tsx#L857)
1490. 资料搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:823](../src/scenes/phone/P02_CC98/index.tsx#L823)
1491. CC98 搜索内容
   来源：[src/scenes/phone/P02_CC98/index.tsx:827](../src/scenes/phone/P02_CC98/index.tsx#L827)
1492. 022 占座纸条
   来源：[src/scenes/phone/P02_CC98/index.tsx:829](../src/scenes/phone/P02_CC98/index.tsx#L829)
1493. 把占座纸条拖到这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:830](../src/scenes/phone/P02_CC98/index.tsx#L830)
1494. 搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:832](../src/scenes/phone/P02_CC98/index.tsx#L832)；[src/scenes/phone/P02_CC98/index.tsx:866](../src/scenes/phone/P02_CC98/index.tsx#L866)；[src/scenes/phone/P15_Zjuding/index.tsx:1618](../src/scenes/phone/P15_Zjuding/index.tsx#L1618)；[src/scenes/phone/P15_Zjuding/index.tsx:2026](../src/scenes/phone/P15_Zjuding/index.tsx#L2026)；[src/scenes/phone/P15_Zjuding/index.tsx:2029](../src/scenes/phone/P15_Zjuding/index.tsx#L2029)
1495. 搜索结果
   来源：[src/scenes/phone/P02_CC98/index.tsx:834](../src/scenes/phone/P02_CC98/index.tsx#L834)
1496. 拖入纸条或点击搜索后显示候选记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:846](../src/scenes/phone/P02_CC98/index.tsx#L846)
1497. 论坛会根据纸条内容建立 23 楼调查索引。
   来源：[src/scenes/phone/P02_CC98/index.tsx:850](../src/scenes/phone/P02_CC98/index.tsx#L850)
1498. 湿纸目击搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:856](../src/scenes/phone/P02_CC98/index.tsx#L856)
1499. 目击搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:857](../src/scenes/phone/P02_CC98/index.tsx#L857)
1500. 湿纸目击搜索内容
   来源：[src/scenes/phone/P02_CC98/index.tsx:861](../src/scenes/phone/P02_CC98/index.tsx#L861)
1501. 剧院门口 湿纸
   来源：[src/scenes/phone/P02_CC98/index.tsx:863](../src/scenes/phone/P02_CC98/index.tsx#L863)
1502. 把湿掉的节目单拖到这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:864](../src/scenes/phone/P02_CC98/index.tsx#L864)
1503. 先用实物特征建立目击范围。
   来源：[src/scenes/phone/P02_CC98/index.tsx:869](../src/scenes/phone/P02_CC98/index.tsx#L869)
1504. CC98版面目录
   来源：[src/scenes/phone/P02_CC98/index.tsx:875](../src/scenes/phone/P02_CC98/index.tsx#L875)
1505. 全部版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:878](../src/scenes/phone/P02_CC98/index.tsx#L878)
1506. 选择一个版面查看帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:879](../src/scenes/phone/P02_CC98/index.tsx#L879)
1507. 个
   来源：[src/scenes/phone/P02_CC98/index.tsx:881](../src/scenes/phone/P02_CC98/index.tsx#L881)；[src/scenes/phone/P02_CC98/index.tsx:923](../src/scenes/phone/P02_CC98/index.tsx#L923)
1508. 进入{{board}}版面，共{{postCount}}帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:891](../src/scenes/phone/P02_CC98/index.tsx#L891)
1509. 帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:897](../src/scenes/phone/P02_CC98/index.tsx#L897)；[src/scenes/phone/P02_CC98/index.tsx:949](../src/scenes/phone/P02_CC98/index.tsx#L949)
1510. 关注{{board}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:903](../src/scenes/phone/P02_CC98/index.tsx#L903)
1511. 取消关注{{board}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:903](../src/scenes/phone/P02_CC98/index.tsx#L903)
1512. 已关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:906](../src/scenes/phone/P02_CC98/index.tsx#L906)；[src/scenes/phone/P14_Wechat/index.tsx:574](../src/scenes/phone/P14_Wechat/index.tsx#L574)
1513. CC98我的页面
   来源：[src/scenes/phone/P02_CC98/index.tsx:914](../src/scenes/phone/P02_CC98/index.tsx#L914)
1514. 我的浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:917](../src/scenes/phone/P02_CC98/index.tsx#L917)
1515. 本次打开过的帖子会留在这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:918](../src/scenes/phone/P02_CC98/index.tsx#L918)
1516. 条
   来源：[src/scenes/phone/P02_CC98/index.tsx:920](../src/scenes/phone/P02_CC98/index.tsx#L920)；[src/scenes/phone/P02_CC98/index.tsx:924](../src/scenes/phone/P02_CC98/index.tsx#L924)；[src/scenes/phone/P15_Zjuding/index.tsx:423](../src/scenes/phone/P15_Zjuding/index.tsx#L423)；[src/scenes/phone/P15_Zjuding/index.tsx:1665](../src/scenes/phone/P15_Zjuding/index.tsx#L1665)
1517. 关注版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:923](../src/scenes/phone/P02_CC98/index.tsx#L923)
1518. 浏览记录
   来源：[src/scenes/phone/P02_CC98/index.tsx:924](../src/scenes/phone/P02_CC98/index.tsx#L924)
1519. 最近浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:927](../src/scenes/phone/P02_CC98/index.tsx#L927)
1520. 还没有浏览记录。打开一篇帖子后会出现在这里。
   来源：[src/scenes/phone/P02_CC98/index.tsx:936](../src/scenes/phone/P02_CC98/index.tsx#L936)
1521. CC98帖子列表
   来源：[src/scenes/phone/P02_CC98/index.tsx:939](../src/scenes/phone/P02_CC98/index.tsx#L939)
1522. ‹ 全部版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:943](../src/scenes/phone/P02_CC98/index.tsx#L943)
1523. 关注的版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:946](../src/scenes/phone/P02_CC98/index.tsx#L946)
1524. 按发布时间排列
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1525. 本版面当前可见帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1526. 可在版面页调整关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1527. 可导入自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:983](../src/scenes/phone/P02_CC98/index.tsx#L983)
1528. 已导入自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:983](../src/scenes/phone/P02_CC98/index.tsx#L983)
1529. 回复 ·
   来源：[src/scenes/phone/P02_CC98/index.tsx:988](../src/scenes/phone/P02_CC98/index.tsx#L988)
1530. 浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:989](../src/scenes/phone/P02_CC98/index.tsx#L989)
1531. 正文
   来源：[src/scenes/phone/P02_CC98/index.tsx:1002](../src/scenes/phone/P02_CC98/index.tsx#L1002)
1532. 这个版面暂时没有可显示的帖子。
   来源：[src/scenes/phone/P02_CC98/index.tsx:1007](../src/scenes/phone/P02_CC98/index.tsx#L1007)
1533. CC98主导航
   来源：[src/scenes/phone/P02_CC98/index.tsx:1011](../src/scenes/phone/P02_CC98/index.tsx#L1011)
1534. 提取目击关键词
   来源：[src/scenes/phone/P02_CC98/index.tsx:1070](../src/scenes/phone/P02_CC98/index.tsx#L1070)
1535. 目击信息可归纳为一个地点关键词
   来源：[src/scenes/phone/P02_CC98/index.tsx:1071](../src/scenes/phone/P02_CC98/index.tsx#L1071)
1536. 记录关键词：桥边
   来源：[src/scenes/phone/P02_CC98/index.tsx:1073](../src/scenes/phone/P02_CC98/index.tsx#L1073)
1537. 已取得：桥边
   来源：[src/scenes/phone/P02_CC98/index.tsx:1073](../src/scenes/phone/P02_CC98/index.tsx#L1073)
1538. 关闭帖子编辑
   来源：[src/scenes/phone/P02_CC98/index.tsx:1091](../src/scenes/phone/P02_CC98/index.tsx#L1091)
1539. CC98小程序
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:19](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L19)
1540. 热门
   来源：[src/scenes/phone/P02_CC98/index.tsx:183](../src/scenes/phone/P02_CC98/index.tsx#L183)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:20](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L20)
1541. 今天 08:22
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:21](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L21)
1542. 楼主
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:22](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L22)
1543. 1楼
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:23](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L23)
1544. 纸飞机维修员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:25](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L25)
1545. 增加论坛经验 755
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:26](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L26)
1546. 帖子成功把常识送进流程
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:27](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L27)
1547. 热门回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:35](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L35)
1548. 只看楼主
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:36](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L36)
1549. 今天 08:24
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:42](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L42)
1550. 先 bd 留言。问题能不能解决不确定，队形必须先完整。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:45](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L45)
1551. 今天 08:27
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:52](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L52)
1552. bd 图先补上，楼主今晚大概能收到一点抽象支援。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:55](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L55)
1553. CC98帖子：{{post.title}}
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:120](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L120)
1554. 返回热门话题
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:122](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L122)
1555. 退出帖子，返回热门话题
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:132](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L132)
1556. 退出帖子
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:133](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L133)
1557. 已锁定无法回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:142](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L142)
1558. 用户
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:164](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L164)；[src/scenes/phone/P15_Zjuding/index.tsx:1960](../src/scenes/phone/P15_Zjuding/index.tsx#L1960)
1559. 操作
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:168](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L168)
1560. 理由
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:172](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L172)
1561. ⚙ 操作
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:178](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L178)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:235](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L235)
1562. ↶ 回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:179](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L179)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:236](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L236)
1563. 图书管理员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:197](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L197)
1564. 今天 08:55
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:198](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L198)
1565. 管理员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:200](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L200)
1566. 24楼
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:201](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L201)
1567. 您好已收到您的问题反馈，请前往图书馆程序进行系统申诉。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:203](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L203)
1568. 回复筛选
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:209](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L209)
1569. 匿名用户{{index + 1}}
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:221](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L221)
1570. CC98 bd 表情包
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:230](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L230)
1571. 现在没有需要带走的水。
   来源：[src/scenes/phone/P07_Weather/index.tsx:29](../src/scenes/phone/P07_Weather/index.tsx#L29)
1572. 湖区状态已经更新。
   来源：[src/scenes/phone/P07_Weather/index.tsx:41](../src/scenes/phone/P07_Weather/index.tsx#L41)；[src/scenes/phone/P07_Weather/index.tsx:60](../src/scenes/phone/P07_Weather/index.tsx#L60)
1573. 当前没有待处理的湖区记录。
   来源：[src/scenes/phone/P07_Weather/index.tsx:45](../src/scenes/phone/P07_Weather/index.tsx#L45)
1574. 先从寝室书桌拿到吹风机。
   来源：[src/scenes/phone/P07_Weather/index.tsx:45](../src/scenes/phone/P07_Weather/index.tsx#L45)
1575. 当前无法开始校准。
   来源：[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)
1576. 湖区状态已更新。
   来源：[src/scenes/phone/P07_Weather/index.tsx:55](../src/scenes/phone/P07_Weather/index.tsx#L55)
1577. 校准记录无效，请重新对齐。
   来源：[src/scenes/phone/P07_Weather/index.tsx:63](../src/scenes/phone/P07_Weather/index.tsx#L63)
1578. 退出天气，返回手机主页
   来源：[src/scenes/phone/P07_Weather/index.tsx:70](../src/scenes/phone/P07_Weather/index.tsx#L70)
1579. 杭州 · 紫金港
   来源：[src/scenes/phone/P07_Weather/index.tsx:71](../src/scenes/phone/P07_Weather/index.tsx#L71)
1580. °C
   来源：[src/scenes/phone/P07_Weather/index.tsx:95](../src/scenes/phone/P07_Weather/index.tsx#L95)；[src/scenes/phone/P07_Weather/index.tsx:96](../src/scenes/phone/P07_Weather/index.tsx#L96)；[src/scenes/phone/P13_PhoneHome/index.tsx:681](../src/scenes/phone/P13_PhoneHome/index.tsx#L681)
1581. 体感温度
   来源：[src/scenes/phone/P07_Weather/index.tsx:96](../src/scenes/phone/P07_Weather/index.tsx#L96)
1582. 天气详情
   来源：[src/scenes/phone/P07_Weather/index.tsx:99](../src/scenes/phone/P07_Weather/index.tsx#L99)
1583. 湿度
   来源：[src/scenes/phone/P07_Weather/index.tsx:100](../src/scenes/phone/P07_Weather/index.tsx#L100)
1584. 西南风 2级
   来源：[src/scenes/phone/P07_Weather/index.tsx:101](../src/scenes/phone/P07_Weather/index.tsx#L101)；[src/scenes/phone/P13_PhoneHome/index.tsx:689](../src/scenes/phone/P13_PhoneHome/index.tsx#L689)
1585. 降水
   来源：[src/scenes/phone/P07_Weather/index.tsx:102](../src/scenes/phone/P07_Weather/index.tsx#L102)
1586. 已经停止
   来源：[src/scenes/phone/P07_Weather/index.tsx:102](../src/scenes/phone/P07_Weather/index.tsx#L102)
1587. 正在发生
   来源：[src/scenes/phone/P07_Weather/index.tsx:102](../src/scenes/phone/P07_Weather/index.tsx#L102)
1588. 处理湖区云图
   来源：[src/scenes/phone/P07_Weather/index.tsx:104](../src/scenes/phone/P07_Weather/index.tsx#L104)
1589. 返回码头确认
   来源：[src/scenes/phone/P07_Weather/index.tsx:104](../src/scenes/phone/P07_Weather/index.tsx#L104)
1590. 暂不适合下水
   来源：[src/scenes/phone/P07_Weather/index.tsx:104](../src/scenes/phone/P07_Weather/index.tsx#L104)
1591. 处理黏着物
   来源：[src/scenes/phone/P07_Weather/index.tsx:105](../src/scenes/phone/P07_Weather/index.tsx#L105)
1592. 湖区记录尚未开放
   来源：[src/scenes/phone/P07_Weather/index.tsx:115](../src/scenes/phone/P07_Weather/index.tsx#L115)
1593. 湖区状态已更新
   来源：[src/scenes/phone/P07_Weather/index.tsx:115](../src/scenes/phone/P07_Weather/index.tsx#L115)；[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1594. 开始湖区云层校准
   来源：[src/scenes/phone/P07_Weather/index.tsx:115](../src/scenes/phone/P07_Weather/index.tsx#L115)
1595. 启动风向校准
   来源：[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1596. 缺少可用设备
   来源：[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1597. 暂无湖区记录
   来源：[src/scenes/phone/P07_Weather/index.tsx:120](../src/scenes/phone/P07_Weather/index.tsx#L120)
1598. 返回码头确认{{state.qizhenLake.weatherControlBestMoves &gt; 0 ? \` · 最少 ${state.qizhenLake.weatherControlBestMoves} 次校正\` : ""}}
   来源：[src/scenes/phone/P07_Weather/index.tsx:122](../src/scenes/phone/P07_Weather/index.tsx#L122)
1599. 先检查寝室书桌
   来源：[src/scenes/phone/P07_Weather/index.tsx:124](../src/scenes/phone/P07_Weather/index.tsx#L124)
1600. 在持续风力中同步稳定三层云带
   来源：[src/scenes/phone/P07_Weather/index.tsx:124](../src/scenes/phone/P07_Weather/index.tsx#L124)
1601. 完成码头检查后再查看
   来源：[src/scenes/phone/P07_Weather/index.tsx:125](../src/scenes/phone/P07_Weather/index.tsx#L125)
1602. 收集天气水滴
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1603. 天气水滴尚未开放
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1604. 天气水滴已收集
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1605. 还没有开始外出打卡
   来源：[src/scenes/phone/P07_Weather/index.tsx:137](../src/scenes/phone/P07_Weather/index.tsx#L137)
1606. 接住一滴水
   来源：[src/scenes/phone/P07_Weather/index.tsx:137](../src/scenes/phone/P07_Weather/index.tsx#L137)
1607. 水滴已收集
   来源：[src/scenes/phone/P07_Weather/index.tsx:137](../src/scenes/phone/P07_Weather/index.tsx#L137)
1608. 你都还没有开始外出打卡，一滴雨都不会落到你身上。
   来源：[src/scenes/phone/P07_Weather/index.tsx:138](../src/scenes/phone/P07_Weather/index.tsx#L138)
1609. 它正在道具栏里等着被使用
   来源：[src/scenes/phone/P07_Weather/index.tsx:138](../src/scenes/phone/P07_Weather/index.tsx#L138)
1610. 这滴水看起来比天气预报更有用
   来源：[src/scenes/phone/P07_Weather/index.tsx:138](../src/scenes/phone/P07_Weather/index.tsx#L138)
1611. 微信
   来源：[src/scenes/phone/P08_Settings/index.tsx:28](../src/scenes/phone/P08_Settings/index.tsx#L28)；[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)；[src/scenes/phone/P14_Wechat/index.tsx:151](../src/scenes/phone/P14_Wechat/index.tsx#L151)
1612. 浙大钉
   来源：[src/scenes/phone/P08_Settings/index.tsx:30](../src/scenes/phone/P08_Settings/index.tsx#L30)；[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)；[src/scenes/phone/P13_PhoneHome/index.tsx:827](../src/scenes/phone/P13_PhoneHome/index.tsx#L827)
1613. 设置
   来源：[src/scenes/phone/P08_Settings/index.tsx:31](../src/scenes/phone/P08_Settings/index.tsx#L31)；[src/scenes/phone/P08_Settings/index.tsx:145](../src/scenes/phone/P08_Settings/index.tsx#L145)；[src/scenes/phone/P08_Settings/index.tsx:148](../src/scenes/phone/P08_Settings/index.tsx#L148)；[src/scenes/phone/P13_PhoneHome/index.tsx:460](../src/scenes/phone/P13_PhoneHome/index.tsx#L460)
1614. 照片
   来源：[src/scenes/phone/P08_Settings/index.tsx:32](../src/scenes/phone/P08_Settings/index.tsx#L32)；[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)；[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)；[src/scenes/phone/P13_PhoneHome/index.tsx:466](../src/scenes/phone/P13_PhoneHome/index.tsx#L466)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:118](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L118)
1615. 记录恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:33](../src/scenes/phone/P08_Settings/index.tsx#L33)；[src/scenes/phone/P13_PhoneHome/index.tsx:473](../src/scenes/phone/P13_PhoneHome/index.tsx#L473)；[src/scenes/phone/P13_PhoneHome/index.tsx:718](../src/scenes/phone/P13_PhoneHome/index.tsx#L718)
1616. 录音
   来源：[src/scenes/phone/P08_Settings/index.tsx:34](../src/scenes/phone/P08_Settings/index.tsx#L34)；[src/scenes/phone/P13_PhoneHome/index.tsx:485](../src/scenes/phone/P13_PhoneHome/index.tsx#L485)
1617. 时钟
   来源：[src/scenes/phone/P08_Settings/index.tsx:37](../src/scenes/phone/P08_Settings/index.tsx#L37)；[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)
1618. 查看当前连接
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1619. 网
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1620. 校园网络与移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1621. 背景音乐
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1622. 声
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1623. 声音与振动
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1624. 亮度与可读性
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)
1625. 显
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)
1626. 显示与辅助
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)；[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1627. 移动图标与恢复排布
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)
1628. 桌
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)
1629. 桌面与壁纸
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)；[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1630. 恢复可选应用
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)
1631. 应
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)
1632. 应用管理
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)；[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1633. 权
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)
1634. 相机、照片与网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)
1635. 隐私与权限
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)；[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1636. 电
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)
1637. 电池与后台活动
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)；[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1638. 检查 07:55 记录
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)
1639. 存档与运行状态
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)
1640. 系
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)
1641. 系统诊断与关于
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)；[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1642. 07:48
   来源：[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)
1643. 天气卡片刷新
   来源：[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)
1644. 07:55
   来源：[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)；[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)；[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)
1645. 重新建立 IMG\_0755 索引
   来源：[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)
1646. 07:52
   来源：[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)
1647. 同步两条新消息
   来源：[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)
1648. 系统时间被后台唤醒
   来源：[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)
1649. 恢复 A2 室内定位
   来源：[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)
1650. 08:02
   来源：[src/scenes/phone/P08_Settings/index.tsx:57](../src/scenes/phone/P08_Settings/index.tsx#L57)
1651. 读取热门话题缓存
   来源：[src/scenes/phone/P08_Settings/index.tsx:57](../src/scenes/phone/P08_Settings/index.tsx#L57)
1652. {{APP\_LABELS\[appId\]}}已移动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:95](../src/scenes/phone/P08_Settings/index.tsx#L95)
1653. {{APP\_LABELS\[appId\]}}已回到桌面。
   来源：[src/scenes/phone/P08_Settings/index.tsx:100](../src/scenes/phone/P08_Settings/index.tsx#L100)
1654. 屏幕亮度
   来源：[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1655. 照片取证会读取这个亮度值。
   来源：[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1656. 核对旧桌面截图
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1657. 恢复默认顺序
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1658. 将{{APP\_LABELS\[appId\]}}后移
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1659. 将{{APP\_LABELS\[appId\]}}前移
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1660. 旧截图第一排
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1661. 微信 浙大钉 照片 CC98
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1662. 桌面也支持长按图标进入编辑。这里可用按钮精确调整顺序。
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1663. 桌面已恢复默认顺序。
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1664. 当前阶段还没有可删除的可选应用。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1665. 当前允许从桌面移除
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1666. 恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1667. 没有从桌面移除的可选应用。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1668. 微信、照片、CC98、浙大钉、设置等剧情应用只能移动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1669. 保存剧情照片
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1670. 取证时使用
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1671. 相机
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1672. 校园网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1673. CC98 与校内服务
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1674. 当前没有需要核验的剧情记录。
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1675. 核验所选记录
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1676. 记录已归档
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1677. 选出同时发生在 07:55 的三条异常活动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1678. 存档
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1679. 个可见
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1680. 游戏时间
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1681. 桌面应用
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1682. 自动保存与上一版本恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1683. 返回设置
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1684. 退出设置，返回手机主页
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1685. root
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1686. PHONE SYSTEM
   来源：[src/scenes/phone/P08_Settings/index.tsx:148](../src/scenes/phone/P08_Settings/index.tsx#L148)
1687. 搜索设置项
   来源：[src/scenes/phone/P08_Settings/index.tsx:151](../src/scenes/phone/P08_Settings/index.tsx#L151)
1688. 塞不进去。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:112](../src/scenes/phone/P13_PhoneHome/index.tsx#L112)
1689. 钥匙旋转 90°——咔哒。塔楼吐出\[一袋肥料\]。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:138](../src/scenes/phone/P13_PhoneHome/index.tsx#L138)
1690. CC98 需要校园网；已经载入的手机票务页面可在移动数据下继续。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:182](../src/scenes/phone/P13_PhoneHome/index.tsx#L182)
1691. 这条推送现在只负责占位置。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:210](../src/scenes/phone/P13_PhoneHome/index.tsx#L210)
1692. 头像边缘松了一点，再点一次。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:211](../src/scenes/phone/P13_PhoneHome/index.tsx#L211)
1693. 三角形已经翘起，再点一次就能取下。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:212](../src/scenes/phone/P13_PhoneHome/index.tsx#L212)
1694. 设置图标只剩一个空位，风从里面吹过。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:219](../src/scenes/phone/P13_PhoneHome/index.tsx#L219)
1695. 这个应用参与剧情，只能移动位置。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:337](../src/scenes/phone/P13_PhoneHome/index.tsx#L337)
1696. {{appId === "tiyi" ? "浙大体艺" : "求是潮 755"}}已从桌面移除，可在设置中恢复。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:341](../src/scenes/phone/P13_PhoneHome/index.tsx#L341)
1697. 获得第 3 位：9
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:364](../src/scenes/phone/P13_PhoneHome/index.tsx#L364)
1698. 钟楼已经把秘密交出去了。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:372](../src/scenes/phone/P13_PhoneHome/index.tsx#L372)
1699. 钟楼大门紧锁。锁孔的形状有点奇怪。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:376](../src/scenes/phone/P13_PhoneHome/index.tsx#L376)
1700. 接住了一滴早八雨。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:386](../src/scenes/phone/P13_PhoneHome/index.tsx#L386)
1701. 它绝对不会开花。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:393](../src/scenes/phone/P13_PhoneHome/index.tsx#L393)
1702. 从桌面移除{{definition.label}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:592](../src/scenes/phone/P13_PhoneHome/index.tsx#L592)
1703. 像素风浙大首页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:607](../src/scenes/phone/P13_PhoneHome/index.tsx#L607)
1704. 钟楼
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:638](../src/scenes/phone/P13_PhoneHome/index.tsx#L638)
1705. 湖边盆栽
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:658](../src/scenes/phone/P13_PhoneHome/index.tsx#L658)
1706. 湖边盆栽，已开花
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:658](../src/scenes/phone/P13_PhoneHome/index.tsx#L658)
1707. 天气：{{campusWeather.label}}，{{weatherTemperature}} 摄氏度
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:666](../src/scenes/phone/P13_PhoneHome/index.tsx#L666)
1708. 打开天气
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:668](../src/scenes/phone/P13_PhoneHome/index.tsx#L668)
1709. 收集水滴
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:675](../src/scenes/phone/P13_PhoneHome/index.tsx#L675)
1710. 最高 20°C / 最低 15°C
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:685](../src/scenes/phone/P13_PhoneHome/index.tsx#L685)
1711. 空气湿度
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:688](../src/scenes/phone/P13_PhoneHome/index.tsx#L688)
1712. 拖动图标调整位置
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:695](../src/scenes/phone/P13_PhoneHome/index.tsx#L695)
1713. 完成
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:696](../src/scenes/phone/P13_PhoneHome/index.tsx#L696)；[src/scenes/rpg/RpgGameHost.tsx:2747](../src/scenes/rpg/RpgGameHost.tsx#L2747)
1714. 应用
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:699](../src/scenes/phone/P13_PhoneHome/index.tsx#L699)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)
1715. 掉落的齿轮，背面刻着 9
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:706](../src/scenes/phone/P13_PhoneHome/index.tsx#L706)
1716. 通知列表
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:712](../src/scenes/phone/P13_PhoneHome/index.tsx#L712)
1717. 流量已开启，返回手机票务页抢第二波
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:748](../src/scenes/phone/P13_PhoneHome/index.tsx#L748)
1718. 第一波结束：网速过慢，开启流量
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:749](../src/scenes/phone/P13_PhoneHome/index.tsx#L749)
1719. 第一波抢票成功，运气很好，钱包没那么好
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:751](../src/scenes/phone/P13_PhoneHome/index.tsx#L751)
1720. 08:32 第二波取票回执已同步
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:752](../src/scenes/phone/P13_PhoneHome/index.tsx#L752)
1721. 图书馆：您有一本书已逾期 755 天
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:766](../src/scenes/phone/P13_PhoneHome/index.tsx#L766)
1722. 您有一本书已逾期 755 天
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:768](../src/scenes/phone/P13_PhoneHome/index.tsx#L768)
1723. CC98：Re: 三楼书架是不是多了一层？
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:771](../src/scenes/phone/P13_PhoneHome/index.tsx#L771)
1724. Re: 三楼书架是不是多了一层？
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:773](../src/scenes/phone/P13_PhoneHome/index.tsx#L773)
1725. 照片：新增照片「看不清的书脊」
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:776](../src/scenes/phone/P13_PhoneHome/index.tsx#L776)
1726. 三角形已收集
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:815](../src/scenes/phone/P13_PhoneHome/index.tsx#L815)
1727. 系统方向推送
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:815](../src/scenes/phone/P13_PhoneHome/index.tsx#L815)
1728. 方向校准
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:819](../src/scenes/phone/P13_PhoneHome/index.tsx#L819)
1729. 课程提醒
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:819](../src/scenes/phone/P13_PhoneHome/index.tsx#L819)
1730. 签到记录未更新。你本人仍未抵达。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:820](../src/scenes/phone/P13_PhoneHome/index.tsx#L820)
1731. 头像方向正确，正文方向未知。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:820](../src/scenes/phone/P13_PhoneHome/index.tsx#L820)
1732. 校园地图已恢复访问，寝室入口可用。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:827](../src/scenes/phone/P13_PhoneHome/index.tsx#L827)
1733. 课堂签到仍在等待四位代码。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:833](../src/scenes/phone/P13_PhoneHome/index.tsx#L833)
1734. 学在浙大
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:833](../src/scenes/phone/P13_PhoneHome/index.tsx#L833)；[src/scenes/phone/P15_Zjuding/index.tsx:1367](../src/scenes/phone/P15_Zjuding/index.tsx#L1367)；[src/scenes/phone/P15_Zjuding/index.tsx:1386](../src/scenes/phone/P15_Zjuding/index.tsx#L1386)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:55](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L55)
1735. 天气：{{weatherNotification}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:841](../src/scenes/phone/P13_PhoneHome/index.tsx#L841)；[src/scenes/phone/P13_PhoneHome/index.tsx:849](../src/scenes/phone/P13_PhoneHome/index.tsx#L849)
1736. 页面切换
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:859](../src/scenes/phone/P13_PhoneHome/index.tsx#L859)
1737. 第 1 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:860](../src/scenes/phone/P13_PhoneHome/index.tsx#L860)
1738. 第 2 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:861](../src/scenes/phone/P13_PhoneHome/index.tsx#L861)
1739. 第 3 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:862](../src/scenes/phone/P13_PhoneHome/index.tsx#L862)
1740. 记录恢复：检测到未同步记录
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:866](../src/scenes/phone/P13_PhoneHome/index.tsx#L866)
1741. 朋友
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:899](../src/scenes/phone/P13_PhoneHome/index.tsx#L899)；[src/scenes/phone/P14_Wechat/index.tsx:948](../src/scenes/phone/P14_Wechat/index.tsx#L948)
1742. 快快老师在点名，学在浙大
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:900](../src/scenes/phone/P13_PhoneHome/index.tsx#L900)
1743. 这是签到码：XX……
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:901](../src/scenes/phone/P13_PhoneHome/index.tsx#L901)
1744. 现在
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:903](../src/scenes/phone/P13_PhoneHome/index.tsx#L903)
1745. 照片 IMG\_0755.JPG
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:115](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L115)
1746. 关闭照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:117](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L117)
1747. 022书包拍摄界面
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:123](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L123)
1748. 保持画面居中
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:124](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L124)
1749. 对准 022 书包
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:124](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L124)
1750. 还没有在 022 现场确认书包。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:130](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L130)
1751. 目标已对准，点击快门。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:130](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L130)
1752. 拍摄 022 书包
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:131](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L131)
1753. 反光的书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:142](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L142)
1754. 可读的书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:142](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L142)
1755. 书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:159](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L159)
1756. 高数教材 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:160](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L160)
1757. 水杯 x1 充电器 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:161](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L161)
1758. 半包纸 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:162](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L162)
1759. 姓名：未检测到
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:163](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L163)
1760. 学号：未检测到
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:164](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L164)
1761. 人格：加载失败
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:165](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L165)
1762. 标签反光，无法识别
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:169](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L169)
1763. 控制中心亮度
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:185](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L185)
1764. 照片直接读取系统亮度
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:187](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L187)
1765. 还没有拍到 022 上的书包。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:191](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L191)
1766. 识别稳定，标签内容已锁定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:193](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L193)
1767. 标签边缘已出现，识别信号仍不稳定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:195](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L195)
1768. 光照太亮了，识别器无法对焦。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:196](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L196)
1769. 旧相册里还有一张同场景照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:203](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L203)
1770. 找到同一只 022 书包的旧照，核对半包纸出现的时间。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:204](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L204)
1771. 查看 022 旧照
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:210](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L210)
1772. 已写入报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:210](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L210)
1773. 照片筛选
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:217](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L217)
1774. 最近 {{LIBRARY\_ROLL\_PHOTOS.length}} 张
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:220](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L220)
1775. 校园与日常
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:221](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L221)
1776. 校园与日常照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1777. 最近照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1778. campus\_life
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1779. 预览 {{photo.title}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:235](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L235)
1780. 6 张校园与日常照片。它们只用于补足相册内容，不参与证据判定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:250](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L250)
1781. {{LIBRARY\_ROLL\_PHOTOS.length}} 张最近照片。点开可以查看细节。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:251](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L251)
1782. {{selectedRollPhoto.file}} · {{selectedRollPhoto.location}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:258](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L258)
1783. {{selectedRollPhoto.title}}，{{selectedRollPhoto.detail}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:263](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L263)
1784. 旧照与刚拍下的标签内容一致。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:267](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L267)
1785. 先把刚拍下的主照片亮度降到 20% 以下。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:267](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L267)
1786. 已写入物品报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:269](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L269)
1787. 用旧照补全物品报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:269](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L269)
1788. 东边入口已经封了，别再往那边走。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:32](../src/scenes/phone/P14_Wechat/index.tsx#L32)
1789. 周琪
   来源：[src/scenes/phone/P14_Wechat/index.tsx:32](../src/scenes/phone/P14_Wechat/index.tsx#L32)
1790. 室友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:33](../src/scenes/phone/P14_Wechat/index.tsx#L33)
1791. 我在西侧看见保洁推车，大厅主入口应该还能进。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:33](../src/scenes/phone/P14_Wechat/index.tsx#L33)
1792. 陈嘉
   来源：[src/scenes/phone/P14_Wechat/index.tsx:34](../src/scenes/phone/P14_Wechat/index.tsx#L34)
1793. 陈嘉撤回了一条消息
   来源：[src/scenes/phone/P14_Wechat/index.tsx:34](../src/scenes/phone/P14_Wechat/index.tsx#L34)
1794. 公众号 · 22:40
   来源：[src/scenes/phone/P14_Wechat/index.tsx:79](../src/scenes/phone/P14_Wechat/index.tsx#L79)
1795. 紫金港楼宇服务
   来源：[src/scenes/phone/P14_Wechat/index.tsx:79](../src/scenes/phone/P14_Wechat/index.tsx#L79)；[src/scenes/phone/P14_Wechat/index.tsx:157](../src/scenes/phone/P14_Wechat/index.tsx#L157)
1796. 校园楼宇运行通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:84](../src/scenes/phone/P14_Wechat/index.tsx#L84)
1797. 夜间闭楼与入口调整
   来源：[src/scenes/phone/P14_Wechat/index.tsx:85](../src/scenes/phone/P14_Wechat/index.tsx#L85)
1798. 22:45 起，
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1799. 北教学区一处楼宇
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1800. 段永平教学楼
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1801. 进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1802. 主电梯保留运行，楼层开放情况以现场提示为准。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:88](../src/scenes/phone/P14_Wechat/index.tsx#L88)
1803. 保存通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:90](../src/scenes/phone/P14_Wechat/index.tsx#L90)
1804. 通知已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:90](../src/scenes/phone/P14_Wechat/index.tsx#L90)
1805. 麦斯威夜间自习群
   来源：[src/scenes/phone/P14_Wechat/index.tsx:101](../src/scenes/phone/P14_Wechat/index.tsx#L101)；[src/scenes/phone/P14_Wechat/index.tsx:104](../src/scenes/phone/P14_Wechat/index.tsx#L104)；[src/scenes/phone/P14_Wechat/index.tsx:163](../src/scenes/phone/P14_Wechat/index.tsx#L163)
1806. 返回微信消息列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:103](../src/scenes/phone/P14_Wechat/index.tsx#L103)
1807. 群聊 · 18人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:104](../src/scenes/phone/P14_Wechat/index.tsx#L104)
1808. 选中两条能够同时确认“哪边关闭”和“哪边可进入”的消息。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:109](../src/scenes/phone/P14_Wechat/index.tsx#L109)
1809. 选择
   来源：[src/scenes/phone/P14_Wechat/index.tsx:123](../src/scenes/phone/P14_Wechat/index.tsx#L123)
1810. 已选
   来源：[src/scenes/phone/P14_Wechat/index.tsx:123](../src/scenes/phone/P14_Wechat/index.tsx#L123)
1811. 22:42 入口调整截图 · 东侧关闭 / 西侧主入口可通行
   来源：[src/scenes/phone/P14_Wechat/index.tsx:130](../src/scenes/phone/P14_Wechat/index.tsx#L130)
1812. 保存路线截图
   来源：[src/scenes/phone/P14_Wechat/index.tsx:139](../src/scenes/phone/P14_Wechat/index.tsx#L139)
1813. 截图已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:139](../src/scenes/phone/P14_Wechat/index.tsx#L139)
1814. 微信恢复证据
   来源：[src/scenes/phone/P14_Wechat/index.tsx:148](../src/scenes/phone/P14_Wechat/index.tsx#L148)
1815. 退出微信，返回手机主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:150](../src/scenes/phone/P14_Wechat/index.tsx#L150)
1816. 消息
   来源：[src/scenes/phone/P14_Wechat/index.tsx:151](../src/scenes/phone/P14_Wechat/index.tsx#L151)；[src/scenes/phone/P15_Zjuding/index.tsx:141](../src/scenes/phone/P15_Zjuding/index.tsx#L141)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:79](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L79)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:87](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L87)
1817. 楼
   来源：[src/scenes/phone/P14_Wechat/index.tsx:156](../src/scenes/phone/P14_Wechat/index.tsx#L156)
1818. 有一条未归档的运行通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:157](../src/scenes/phone/P14_Wechat/index.tsx#L157)
1819. 已存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:159](../src/scenes/phone/P14_Wechat/index.tsx#L159)；[src/scenes/phone/P14_Wechat/index.tsx:165](../src/scenes/phone/P14_Wechat/index.tsx#L165)
1820. 有两条消息可组成路线截图
   来源：[src/scenes/phone/P14_Wechat/index.tsx:163](../src/scenes/phone/P14_Wechat/index.tsx#L163)
1821. 返回记录恢复
   来源：[src/scenes/phone/P14_Wechat/index.tsx:168](../src/scenes/phone/P14_Wechat/index.tsx#L168)；[src/scenes/phone/P15_Zjuding/index.tsx:451](../src/scenes/phone/P15_Zjuding/index.tsx#L451)
1822. 任务更新：找回四位签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:236](../src/scenes/phone/P14_Wechat/index.tsx#L236)
1823. 咔——斜线断了一截，挂在头像框上晃悠。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:331](../src/scenes/phone/P14_Wechat/index.tsx#L331)
1824. 导师头像现在不接受附件。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:349](../src/scenes/phone/P14_Wechat/index.tsx#L349)
1825. 卡扣反而更紧了。它需要能渗进胶缝的东西。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:355](../src/scenes/phone/P14_Wechat/index.tsx#L355)
1826. 竖线滑落了。获得道具：竖线
   来源：[src/scenes/phone/P14_Wechat/index.tsx:363](../src/scenes/phone/P14_Wechat/index.tsx#L363)
1827. 或许可以再斜一点
   来源：[src/scenes/phone/P14_Wechat/index.tsx:387](../src/scenes/phone/P14_Wechat/index.tsx#L387)
1828. 它也想转转罢
   来源：[src/scenes/phone/P14_Wechat/index.tsx:389](../src/scenes/phone/P14_Wechat/index.tsx#L389)
1829. 斜线晃了晃，还没掉。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:391](../src/scenes/phone/P14_Wechat/index.tsx#L391)
1830. 头像上的斜线纹丝不动。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:392](../src/scenes/phone/P14_Wechat/index.tsx#L392)
1831. 检测到未经授权的友情支援。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:403](../src/scenes/phone/P14_Wechat/index.tsx#L403)
1832. 你戳了戳剩下的一端……
   来源：[src/scenes/phone/P14_Wechat/index.tsx:406](../src/scenes/phone/P14_Wechat/index.tsx#L406)
1833. 导师的消息，还是等签完到再回吧。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:414](../src/scenes/phone/P14_Wechat/index.tsx#L414)
1834. 头像中间留下了一道很干净的空隙。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:419](../src/scenes/phone/P14_Wechat/index.tsx#L419)
1835. 这条竖线被透明胶和两枚卡扣封在头像框里。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:423](../src/scenes/phone/P14_Wechat/index.tsx#L423)
1836. 这条聊天还不能作为地点记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:506](../src/scenes/phone/P14_Wechat/index.tsx#L506)
1837. 已从聊天中保存地点词：湖面。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:509](../src/scenes/phone/P14_Wechat/index.tsx#L509)
1838. 已保存通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:541](../src/scenes/phone/P14_Wechat/index.tsx#L541)
1839. · 校园日常记录
   来源：[src/scenes/phone/P14_Wechat/index.tsx:557](../src/scenes/phone/P14_Wechat/index.tsx#L557)
1840. 阅读
   来源：[src/scenes/phone/P14_Wechat/index.tsx:557](../src/scenes/phone/P14_Wechat/index.tsx#L557)
1841. {{chapterFourWechatContent.official.name}}公众号主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:567](../src/scenes/phone/P14_Wechat/index.tsx#L567)
1842. 后勤
   来源：[src/scenes/phone/P14_Wechat/index.tsx:569](../src/scenes/phone/P14_Wechat/index.tsx#L569)；[src/scenes/phone/P14_Wechat/index.tsx:788](../src/scenes/phone/P14_Wechat/index.tsx#L788)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
1843. 夜间通知 ·
   来源：[src/scenes/phone/P14_Wechat/index.tsx:584](../src/scenes/phone/P14_Wechat/index.tsx#L584)
1844. 已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:588](../src/scenes/phone/P14_Wechat/index.tsx#L588)
1845. 主线通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:588](../src/scenes/phone/P14_Wechat/index.tsx#L588)
1846. 往期推文
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)；[src/scenes/phone/P14_Wechat/index.tsx:593](../src/scenes/phone/P14_Wechat/index.tsx#L593)；[src/scenes/phone/P14_Wechat/index.tsx:625](../src/scenes/phone/P14_Wechat/index.tsx#L625)
1847. 校园日常
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)；[src/scenes/phone/P14_Wechat/index.tsx:593](../src/scenes/phone/P14_Wechat/index.tsx#L593)；[src/scenes/phone/P14_Wechat/index.tsx:620](../src/scenes/phone/P14_Wechat/index.tsx#L620)
1848. daily
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)
1849. 篇
   来源：[src/scenes/phone/P14_Wechat/index.tsx:594](../src/scenes/phone/P14_Wechat/index.tsx#L594)
1850. 公众号自定义菜单
   来源：[src/scenes/phone/P14_Wechat/index.tsx:614](../src/scenes/phone/P14_Wechat/index.tsx#L614)
1851. 夜间通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:615](../src/scenes/phone/P14_Wechat/index.tsx#L615)
1852. 档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:665](../src/scenes/phone/P14_Wechat/index.tsx#L665)
1853. 学习天地资料索引
   来源：[src/scenes/phone/P14_Wechat/index.tsx:667](../src/scenes/phone/P14_Wechat/index.tsx#L667)
1854. 群文件 ›
   来源：[src/scenes/phone/P14_Wechat/index.tsx:670](../src/scenes/phone/P14_Wechat/index.tsx#L670)
1855. 林昊
   来源：[src/scenes/phone/P14_Wechat/index.tsx:682](../src/scenes/phone/P14_Wechat/index.tsx#L682)
1856. 保存录音
   来源：[src/scenes/phone/P14_Wechat/index.tsx:705](../src/scenes/phone/P14_Wechat/index.tsx#L705)
1857. 已归档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:705](../src/scenes/phone/P14_Wechat/index.tsx#L705)
1858. 待现场核验
   来源：[src/scenes/phone/P14_Wechat/index.tsx:709](../src/scenes/phone/P14_Wechat/index.tsx#L709)
1859. 群聊截图 · 2F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:709](../src/scenes/phone/P14_Wechat/index.tsx#L709)
1860. 现场照片 · 3F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:713](../src/scenes/phone/P14_Wechat/index.tsx#L713)
1861. 等你从 CC98 导入资料索引
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
1862. 路线讨论已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
1863. 学习天地资料已加入群文件
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
1864. 文件传输助手：只有你给自己发的表情包。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:801](../src/scenes/phone/P14_Wechat/index.tsx#L801)
1865. 文件传输助手
   来源：[src/scenes/phone/P14_Wechat/index.tsx:805](../src/scenes/phone/P14_Wechat/index.tsx#L805)
1866. \[图片\]
   来源：[src/scenes/phone/P14_Wechat/index.tsx:806](../src/scenes/phone/P14_Wechat/index.tsx#L806)
1867. 已保存 {{chapterFourWechat.archiveCount}} 项现场资料
   来源：[src/scenes/phone/P14_Wechat/index.tsx:806](../src/scenes/phone/P14_Wechat/index.tsx#L806)
1868. 打开朋友聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:816](../src/scenes/phone/P14_Wechat/index.tsx#L816)
1869. 朋友头像
   来源：[src/scenes/phone/P14_Wechat/index.tsx:822](../src/scenes/phone/P14_Wechat/index.tsx#L822)
1870. 导师：实验报告仍然不会自己完成。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:876](../src/scenes/phone/P14_Wechat/index.tsx#L876)
1871. 导师头像上的竖线
   来源：[src/scenes/phone/P14_Wechat/index.tsx:882](../src/scenes/phone/P14_Wechat/index.tsx#L882)
1872. 导师
   来源：[src/scenes/phone/P14_Wechat/index.tsx:904](../src/scenes/phone/P14_Wechat/index.tsx#L904)
1873. 头像胶缝里似乎缺一点能流动的东西。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:908](../src/scenes/phone/P14_Wechat/index.tsx#L908)
1874. 两枚卡扣在发亮，中间的竖线还是拔不动。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:910](../src/scenes/phone/P14_Wechat/index.tsx#L910)
1875. 头像框中间多了一条被封住的竖线。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:911](../src/scenes/phone/P14_Wechat/index.tsx#L911)
1876. 请把实验报告的初稿发我一下。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:912](../src/scenes/phone/P14_Wechat/index.tsx#L912)
1877. 聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:923](../src/scenes/phone/P14_Wechat/index.tsx#L923)
1878. 联系人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:927](../src/scenes/phone/P14_Wechat/index.tsx#L927)
1879. 探索
   来源：[src/scenes/phone/P14_Wechat/index.tsx:931](../src/scenes/phone/P14_Wechat/index.tsx#L931)
1880. 我的
   来源：[src/scenes/phone/P14_Wechat/index.tsx:935](../src/scenes/phone/P14_Wechat/index.tsx#L935)；[src/scenes/phone/P15_Zjuding/index.tsx:142](../src/scenes/phone/P15_Zjuding/index.tsx#L142)；[src/scenes/phone/P15_Zjuding/index.tsx:147](../src/scenes/phone/P15_Zjuding/index.tsx#L147)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:80](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L80)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:88](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L88)
1881. 返回聊天列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:946](../src/scenes/phone/P14_Wechat/index.tsx#L946)
1882. 快快老师在点名，学在浙大。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:959](../src/scenes/phone/P14_Wechat/index.tsx#L959)
1883. 这是签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:967](../src/scenes/phone/P14_Wechat/index.tsx#L967)
1884. 等等等等，你想翘课？没门！
   来源：[src/scenes/phone/P14_Wechat/index.tsx:987](../src/scenes/phone/P14_Wechat/index.tsx#L987)
1885. 我不会让你签上的！
   来源：[src/scenes/phone/P14_Wechat/index.tsx:988](../src/scenes/phone/P14_Wechat/index.tsx#L988)
1886. 跳过小影语音
   来源：[src/scenes/phone/P14_Wechat/index.tsx:999](../src/scenes/phone/P14_Wechat/index.tsx#L999)
1887. 成功了吗
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1007](../src/scenes/phone/P14_Wechat/index.tsx#L1007)
1888. wx-msg wx-qizhen-message {{line.startsWith("自动回复：") ? "is-self" : ""}}
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1037](../src/scenes/phone/P14_Wechat/index.tsx#L1037)
1889. 自动回复：
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1038](../src/scenes/phone/P14_Wechat/index.tsx#L1038)
1890. 身份信息未读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:62](../src/scenes/phone/P15_Zjuding/index.tsx#L62)
1891. 拜托了，帮我改一下签到记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:72](../src/scenes/phone/P15_Zjuding/index.tsx#L72)；[src/scenes/phone/P15_Zjuding/index.tsx:79](../src/scenes/phone/P15_Zjuding/index.tsx#L79)
1892. player
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:72](../src/scenes/phone/P15_Zjuding/index.tsx#L72)；[src/scenes/phone/P15_Zjuding/index.tsx:79](../src/scenes/phone/P15_Zjuding/index.tsx#L79)；[src/scenes/phone/P15_Zjuding/index.tsx:85](../src/scenes/phone/P15_Zjuding/index.tsx#L85)
1893. 先把校园卡收好。寝室里的人还需要找到移动方法。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:81](../src/scenes/phone/P15_Zjuding/index.tsx#L81)
1894. 别打扰我……哦，你已经完事了，速度还挺快的
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:92](../src/scenes/phone/P15_Zjuding/index.tsx#L92)
1895. 我以为你要在寝室“就再睡一会儿”呢
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:93](../src/scenes/phone/P15_Zjuding/index.tsx#L93)
1896. 你知道的，去图书馆要先完成座位预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:94](../src/scenes/phone/P15_Zjuding/index.tsx#L94)
1897. 基础馆二楼南区022，记住了。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:95](../src/scenes/phone/P15_Zjuding/index.tsx#L95)
1898. 馆藏检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:127](../src/scenes/phone/P15_Zjuding/index.tsx#L127)；[src/scenes/phone/P15_Zjuding/index.tsx:1506](../src/scenes/phone/P15_Zjuding/index.tsx#L1506)；[src/scenes/phone/P15_Zjuding/index.tsx:1507](../src/scenes/phone/P15_Zjuding/index.tsx#L1507)；[src/scenes/phone/P15_Zjuding/index.tsx:1510](../src/scenes/phone/P15_Zjuding/index.tsx#L1510)；[src/scenes/phone/P15_Zjuding/index.tsx:1511](../src/scenes/phone/P15_Zjuding/index.tsx#L1511)
1899. 借阅信息
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:128](../src/scenes/phone/P15_Zjuding/index.tsx#L128)
1900. 阅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:128](../src/scenes/phone/P15_Zjuding/index.tsx#L128)
1901. 座位预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:129](../src/scenes/phone/P15_Zjuding/index.tsx#L129)；[src/scenes/phone/P15_Zjuding/index.tsx:1514](../src/scenes/phone/P15_Zjuding/index.tsx#L1514)
1902. 空间预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:130](../src/scenes/phone/P15_Zjuding/index.tsx#L130)
1903. 荐
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:131](../src/scenes/phone/P15_Zjuding/index.tsx#L131)
1904. 求是荐书
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:131](../src/scenes/phone/P15_Zjuding/index.tsx#L131)
1905. 新书通报
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:132](../src/scenes/phone/P15_Zjuding/index.tsx#L132)
1906. 查收查引
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:133](../src/scenes/phone/P15_Zjuding/index.tsx#L133)
1907. 引
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:133](../src/scenes/phone/P15_Zjuding/index.tsx#L133)
1908. 图书馆缴费
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:134](../src/scenes/phone/P15_Zjuding/index.tsx#L134)
1909. 失物招领 · 前台工作人员
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:197](../src/scenes/phone/P15_Zjuding/index.tsx#L197)
1910. 二层南区 · 022 桌面夹缝
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:203](../src/scenes/phone/P15_Zjuding/index.tsx#L203)
1911. 浙大体艺 · 到馆记录补录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:209](../src/scenes/phone/P15_Zjuding/index.tsx#L209)
1912. 二层
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:214](../src/scenes/phone/P15_Zjuding/index.tsx#L214)；[src/scenes/phone/P15_Zjuding/index.tsx:215](../src/scenes/phone/P15_Zjuding/index.tsx#L215)
1913. 二层南
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:214](../src/scenes/phone/P15_Zjuding/index.tsx#L214)；[src/scenes/phone/P15_Zjuding/index.tsx:553](../src/scenes/phone/P15_Zjuding/index.tsx#L553)
1914. 二层北
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:215](../src/scenes/phone/P15_Zjuding/index.tsx#L215)
1915. 三层
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:216](../src/scenes/phone/P15_Zjuding/index.tsx#L216)；[src/scenes/phone/P15_Zjuding/index.tsx:217](../src/scenes/phone/P15_Zjuding/index.tsx#L217)
1916. 三层东
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:216](../src/scenes/phone/P15_Zjuding/index.tsx#L216)
1917. 三层南
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:217](../src/scenes/phone/P15_Zjuding/index.tsx#L217)
1918. 返回，离开{{title}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:247](../src/scenes/phone/P15_Zjuding/index.tsx#L247)
1919. {{title}}更多菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:249](../src/scenes/phone/P15_Zjuding/index.tsx#L249)
1920. 页面导航
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:269](../src/scenes/phone/P15_Zjuding/index.tsx#L269)；[src/scenes/phone/P15_Zjuding/index.tsx:1583](../src/scenes/phone/P15_Zjuding/index.tsx#L1583)
1921. 22:44:31
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:343](../src/scenes/phone/P15_Zjuding/index.tsx#L343)
1922. 剧场前厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:345](../src/scenes/phone/P15_Zjuding/index.tsx#L345)
1923. 18 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:346](../src/scenes/phone/P15_Zjuding/index.tsx#L346)
1924. 已认证设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:347](../src/scenes/phone/P15_Zjuding/index.tsx#L347)；[src/scenes/phone/P15_Zjuding/index.tsx:413](../src/scenes/phone/P15_Zjuding/index.tsx#L413)
1925. 22:43:11
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:354](../src/scenes/phone/P15_Zjuding/index.tsx#L354)
1926. 基础图书馆南侧
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:356](../src/scenes/phone/P15_Zjuding/index.tsx#L356)
1927. 3 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:357](../src/scenes/phone/P15_Zjuding/index.tsx#L357)；[src/scenes/phone/P15_Zjuding/index.tsx:368](../src/scenes/phone/P15_Zjuding/index.tsx#L368)
1928. 未知设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:358](../src/scenes/phone/P15_Zjuding/index.tsx#L358)；[src/scenes/phone/P15_Zjuding/index.tsx:369](../src/scenes/phone/P15_Zjuding/index.tsx#L369)
1929. 22:44:12
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:365](../src/scenes/phone/P15_Zjuding/index.tsx#L365)
1930. 启真湖小码头
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:367](../src/scenes/phone/P15_Zjuding/index.tsx#L367)
1931. 网络记录筛选
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:402](../src/scenes/phone/P15_Zjuding/index.tsx#L402)
1932. 缺失时段末段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:406](../src/scenes/phone/P15_Zjuding/index.tsx#L406)
1933. 最后 1 分钟
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:407](../src/scenes/phone/P15_Zjuding/index.tsx#L407)
1934. 会话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:410](../src/scenes/phone/P15_Zjuding/index.tsx#L410)
1935. 未知设备 · 短会话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:412](../src/scenes/phone/P15_Zjuding/index.tsx#L412)
1936. 全校
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:417](../src/scenes/phone/P15_Zjuding/index.tsx#L417)
1937. 北教学区 A 区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:418](../src/scenes/phone/P15_Zjuding/index.tsx#L418)
1938. 其他楼宇
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:419](../src/scenes/phone/P15_Zjuding/index.tsx#L419)
1939. 接入记录结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:422](../src/scenes/phone/P15_Zjuding/index.tsx#L422)
1940. 查询结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:423](../src/scenes/phone/P15_Zjuding/index.tsx#L423)
1941. 接入点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:428](../src/scenes/phone/P15_Zjuding/index.tsx#L428)
1942. 位置
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:429](../src/scenes/phone/P15_Zjuding/index.tsx#L429)
1943. 设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:430](../src/scenes/phone/P15_Zjuding/index.tsx#L430)
1944. 记录已保存
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:437](../src/scenes/phone/P15_Zjuding/index.tsx#L437)
1945. 保存这条记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:438](../src/scenes/phone/P15_Zjuding/index.tsx#L438)
1946. 可从任意维度开始筛选，也可直接保存候选记录。系统不会替你判定候选，最终冲突由证据矩阵统一核验。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:443](../src/scenes/phone/P15_Zjuding/index.tsx#L443)
1947. 记录核验结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:445](../src/scenes/phone/P15_Zjuding/index.tsx#L445)
1948. 林星宇
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:446](../src/scenes/phone/P15_Zjuding/index.tsx#L446)
1949. 这不是我的手机。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:446](../src/scenes/phone/P15_Zjuding/index.tsx#L446)
1950. 北教学区 A 区的一处大厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1951. 段永平教学楼一楼
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1952. 留下了三秒会话。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1953. 设备名也不是你的。它借用了你的校园身份，在
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
1954. 可选座位地图
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:473](../src/scenes/phone/P15_Zjuding/index.tsx#L473)
1955. 选择座位{{leftSeat}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:489](../src/scenes/phone/P15_Zjuding/index.tsx#L489)
1956. 选择座位{{rightSeat}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:500](../src/scenes/phone/P15_Zjuding/index.tsx#L500)
1957. 北向
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:517](../src/scenes/phone/P15_Zjuding/index.tsx#L517)
1958. 请选择馆舍
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:552](../src/scenes/phone/P15_Zjuding/index.tsx#L552)
1959. 07月10日 · 今天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:554](../src/scenes/phone/P15_Zjuding/index.tsx#L554)；[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
1960. 全部座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:557](../src/scenes/phone/P15_Zjuding/index.tsx#L557)；[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
1961. 请连接校园网后重新进入浙大钉。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:621](../src/scenes/phone/P15_Zjuding/index.tsx#L621)
1962. reservation
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:630](../src/scenes/phone/P15_Zjuding/index.tsx#L630)
1963. 读卡器没有读到有效证件。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:636](../src/scenes/phone/P15_Zjuding/index.tsx#L636)
1964. 证件信息已读入。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:655](../src/scenes/phone/P15_Zjuding/index.tsx#L655)
1965. 读卡区只认校园身份凭证。这件道具没有姓名和学号。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:666](../src/scenes/phone/P15_Zjuding/index.tsx#L666)
1966. 馆藏检索没有识别这件道具中的页码特征。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:698](../src/scenes/phone/P15_Zjuding/index.tsx#L698)
1967. 节目单的潮湿页码已送入馆藏状态检索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:706](../src/scenes/phone/P15_Zjuding/index.tsx#L706)
1968. 这个槽位需要对应名称的恢复证明。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:722](../src/scenes/phone/P15_Zjuding/index.tsx#L722)
1969. 退出浙大钉
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:764](../src/scenes/phone/P15_Zjuding/index.tsx#L764)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
1970. 个人资料
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:768](../src/scenes/phone/P15_Zjuding/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
1971. 账号与安全
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:768](../src/scenes/phone/P15_Zjuding/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
1972. 收藏号码
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:772](../src/scenes/phone/P15_Zjuding/index.tsx#L772)；[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
1973. 最近通话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:772](../src/scenes/phone/P15_Zjuding/index.tsx#L772)；[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
1974. 我的预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:776](../src/scenes/phone/P15_Zjuding/index.tsx#L776)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
1975. 当前没有已确认的图书馆预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:780](../src/scenes/phone/P15_Zjuding/index.tsx#L780)
1976. 刷新空位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:784](../src/scenes/phone/P15_Zjuding/index.tsx#L784)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
1977. 刷新座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:784](../src/scenes/phone/P15_Zjuding/index.tsx#L784)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
1978. 已重新读取本机座位状态：{{selectedRoom}}空闲 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.available ?? 0}} 席。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:785](../src/scenes/phone/P15_Zjuding/index.tsx#L785)
1979. 预约规则
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:788](../src/scenes/phone/P15_Zjuding/index.tsx#L788)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
1980. 预约页只接受当前剧情已开放的馆舍、区域和座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:789](../src/scenes/phone/P15_Zjuding/index.tsx#L789)
1981. 取消预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:792](../src/scenes/phone/P15_Zjuding/index.tsx#L792)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
1982. 已确认预约保持不变。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:793](../src/scenes/phone/P15_Zjuding/index.tsx#L793)
1983. 找回账号
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:796](../src/scenes/phone/P15_Zjuding/index.tsx#L796)；[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
1984. 请通过电子校园卡重新读取身份。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:797](../src/scenes/phone/P15_Zjuding/index.tsx#L797)
1985. 安全提示
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:800](../src/scenes/phone/P15_Zjuding/index.tsx#L800)；[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
1986. 账号信息由电子校园卡状态读取。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:801](../src/scenes/phone/P15_Zjuding/index.tsx#L801)
1987. 当前状态已显示。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:804](../src/scenes/phone/P15_Zjuding/index.tsx#L804)
1988. 它看了看你的空手，又缩回了红圈里。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:923](../src/scenes/phone/P15_Zjuding/index.tsx#L923)
1989. 求是印章没有回应。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:927](../src/scenes/phone/P15_Zjuding/index.tsx#L927)
1990. 任务更新：找到道具栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:948](../src/scenes/phone/P15_Zjuding/index.tsx#L948)
1991. 任务更新：找到移动的办法
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:952](../src/scenes/phone/P15_Zjuding/index.tsx#L952)
1992. 任务更新：让地图人物回应你
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:955](../src/scenes/phone/P15_Zjuding/index.tsx#L955)
1993. 本章的 022 状态由图书馆现场记录管理。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1015](../src/scenes/phone/P15_Zjuding/index.tsx#L1015)
1994. 座位 {{state.ui.librarySelectedSeat ?? "022"}} 已预约，不能在当前任务中改签。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1019](../src/scenes/phone/P15_Zjuding/index.tsx#L1019)
1995. 请先选择一个白色座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1028](../src/scenes/phone/P15_Zjuding/index.tsx#L1028)
1996. 座位 {{state.ui.librarySelectedSeat}} 已预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1032](../src/scenes/phone/P15_Zjuding/index.tsx#L1032)
1997. 预约来源不匹配：请选择基础馆。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1044](../src/scenes/phone/P15_Zjuding/index.tsx#L1044)
1998. 预约区域不匹配：请选择二层南区。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1045](../src/scenes/phone/P15_Zjuding/index.tsx#L1045)
1999. 座位凭据不匹配：目标座位为 022。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1046](../src/scenes/phone/P15_Zjuding/index.tsx#L1046)
2000. 系统还没有开放本次座位预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1047](../src/scenes/phone/P15_Zjuding/index.tsx#L1047)
2001. 预约成功：基础馆二层南区 022。任务更新：前往基础图书馆 022
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1054](../src/scenes/phone/P15_Zjuding/index.tsx#L1054)
2002. 请输入书名、作者或索书号。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1063](../src/scenes/phone/P15_Zjuding/index.tsx#L1063)
2003. 检索完成：发现 1 条异常外借记录。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1075](../src/scenes/phone/P15_Zjuding/index.tsx#L1075)
2004. 没有找到与“{{query}}”相符的馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1083](../src/scenes/phone/P15_Zjuding/index.tsx#L1083)
2005. 检索完成：找到 {{results.length}} 本馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1087](../src/scenes/phone/P15_Zjuding/index.tsx#L1087)
2006. 检索完成：找到 {{results.length}} 本相似馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1093](../src/scenes/phone/P15_Zjuding/index.tsx#L1093)
2007. 当前无法保存这条异常定位信息。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1098](../src/scenes/phone/P15_Zjuding/index.tsx#L1098)
2008. {{qizhenContent.locationSearch.catalog.player}} / {{qizhenContent.locationSearch.catalog.system}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1101](../src/scenes/phone/P15_Zjuding/index.tsx#L1101)
2009. 地图没有从这件道具中读到地点关键词。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1107](../src/scenes/phone/P15_Zjuding/index.tsx#L1107)
2010. 当前没有需要合并的地点线索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1111](../src/scenes/phone/P15_Zjuding/index.tsx#L1111)
2011. 这条记录已经参与检索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1115](../src/scenes/phone/P15_Zjuding/index.tsx#L1115)
2012. 三条记录还没有全部对齐。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1130](../src/scenes/phone/P15_Zjuding/index.tsx#L1130)
2013. 启真湖入口还没有在大地图上开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1138](../src/scenes/phone/P15_Zjuding/index.tsx#L1138)
2014. 已获得线索：索书号 {{result.callNumber}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1145](../src/scenes/phone/P15_Zjuding/index.tsx#L1145)；[src/scenes/phone/P15_Zjuding/index.tsx:1158](../src/scenes/phone/P15_Zjuding/index.tsx#L1158)
2015. {{result.title}}的索书号和 022 没有可核对的关系。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1153](../src/scenes/phone/P15_Zjuding/index.tsx#L1153)
2016. 十大排名还没有被图书馆系统同步。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1164](../src/scenes/phone/P15_Zjuding/index.tsx#L1164)
2017. 恢复申请只在帖子进入十大第一后开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1168](../src/scenes/phone/P15_Zjuding/index.tsx#L1168)
2018. 该证明还未获得、已提交，或当前申请尚未开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1177](../src/scenes/phone/P15_Zjuding/index.tsx#L1177)
2019. 三项恢复材料尚未齐全。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1191](../src/scenes/phone/P15_Zjuding/index.tsx#L1191)
2020. 浙大钉加载中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1204](../src/scenes/phone/P15_Zjuding/index.tsx#L1204)
2021. 请连接校园网后重新进入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1215](../src/scenes/phone/P15_Zjuding/index.tsx#L1215)
2022. 统一身份认证
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1258](../src/scenes/phone/P15_Zjuding/index.tsx#L1258)
2023. 登录帮助
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
2024. 校园身份信息
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1264](../src/scenes/phone/P15_Zjuding/index.tsx#L1264)
2025. 旧登录入口已合并到电子校园卡。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1265](../src/scenes/phone/P15_Zjuding/index.tsx#L1265)
2026. 前往部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1276](../src/scenes/phone/P15_Zjuding/index.tsx#L1276)
2027. 浙大钉部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1284](../src/scenes/phone/P15_Zjuding/index.tsx#L1284)
2028. 部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1286](../src/scenes/phone/P15_Zjuding/index.tsx#L1286)；[src/scenes/phone/P15_Zjuding/index.tsx:2013](../src/scenes/phone/P15_Zjuding/index.tsx#L2013)；[src/scenes/phone/P15_Zjuding/index.tsx:2017](../src/scenes/phone/P15_Zjuding/index.tsx#L2017)；[src/scenes/phone/P15_Zjuding/index.tsx:2018](../src/scenes/phone/P15_Zjuding/index.tsx#L2018)
2029. 黄页菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
2030. 部门联系人
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1291](../src/scenes/phone/P15_Zjuding/index.tsx#L1291)
2031. 联络寝室人物
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1299](../src/scenes/phone/P15_Zjuding/index.tsx#L1299)
2032. 校园卡读卡区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1305](../src/scenes/phone/P15_Zjuding/index.tsx#L1305)
2033. 电子校园卡已读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1316](../src/scenes/phone/P15_Zjuding/index.tsx#L1316)
2034. 校园身份读卡区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1316](../src/scenes/phone/P15_Zjuding/index.tsx#L1316)
2035. 正在识别持卡人字段……
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1319](../src/scenes/phone/P15_Zjuding/index.tsx#L1319)
2036. 姓名与 10 位学号已填入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1321](../src/scenes/phone/P15_Zjuding/index.tsx#L1321)
2037. 校园卡已对准，点击读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1323](../src/scenes/phone/P15_Zjuding/index.tsx#L1323)
2038. 点击查看提示，或将身份凭证放入此处
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1324](../src/scenes/phone/P15_Zjuding/index.tsx#L1324)
2039. 联络未命名人物
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1331](../src/scenes/phone/P15_Zjuding/index.tsx#L1331)
2040. 请输入校园卡上的完整身份
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1331](../src/scenes/phone/P15_Zjuding/index.tsx#L1331)
2041. 校园卡姓名
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1341](../src/scenes/phone/P15_Zjuding/index.tsx#L1341)
2042. 10 位学号
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1354](../src/scenes/phone/P15_Zjuding/index.tsx#L1354)
2043. ☎ 呼叫
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1359](../src/scenes/phone/P15_Zjuding/index.tsx#L1359)
2044. 已联络：{{actOneContent.studentName}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1359](../src/scenes/phone/P15_Zjuding/index.tsx#L1359)
2045. 校务签到
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1375](../src/scenes/phone/P15_Zjuding/index.tsx#L1375)
2046. 返回浙大钉
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1382](../src/scenes/phone/P15_Zjuding/index.tsx#L1382)
2047. 学在浙大导航
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1383](../src/scenes/phone/P15_Zjuding/index.tsx#L1383)
2048. 当前位于学在浙大。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1384](../src/scenes/phone/P15_Zjuding/index.tsx#L1384)
2049. 方向靠近桥
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
2050. CC98 目击帖
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
2051. 馆藏异常记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
2052. 页码只出现在倒影中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
2053. 湖面
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2054. 湖面出现逆风水纹
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2055. 微信聊天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2056. 三条记录来自不同应用。先取得地点词，再在这里逐条接入。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1417](../src/scenes/phone/P15_Zjuding/index.tsx#L1417)
2057. 校园地图地点检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1419](../src/scenes/phone/P15_Zjuding/index.tsx#L1419)
2058. 保留原始来源，核对三条地点记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1424](../src/scenes/phone/P15_Zjuding/index.tsx#L1424)
2059. 交叉检索台
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1424](../src/scenes/phone/P15_Zjuding/index.tsx#L1424)
2060. 三源地点记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1429](../src/scenes/phone/P15_Zjuding/index.tsx#L1429)
2061. 已接入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1432](../src/scenes/phone/P15_Zjuding/index.tsx#L1432)；[src/scenes/phone/P15_Zjuding/index.tsx:1450](../src/scenes/phone/P15_Zjuding/index.tsx#L1450)
2062. 待核对
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2063. 入口已标记
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2064. 收集中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2065. 提取词：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1447](../src/scenes/phone/P15_Zjuding/index.tsx#L1447)
2066. 导入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1452](../src/scenes/phone/P15_Zjuding/index.tsx#L1452)
2067. 导入{{clue.source}}的地点词{{clue.label}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1452](../src/scenes/phone/P15_Zjuding/index.tsx#L1452)
2068. 未取得
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1454](../src/scenes/phone/P15_Zjuding/index.tsx#L1454)
2069. 核对地点交点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1461](../src/scenes/phone/P15_Zjuding/index.tsx#L1461)
2070. 前往大地图上的启真湖入口
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1476](../src/scenes/phone/P15_Zjuding/index.tsx#L1476)
2071. 浙大移动图书馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1484](../src/scenes/phone/P15_Zjuding/index.tsx#L1484)；[src/scenes/phone/P15_Zjuding/index.tsx:1486](../src/scenes/phone/P15_Zjuding/index.tsx#L1486)；[src/scenes/phone/P15_Zjuding/index.tsx:1597](../src/scenes/phone/P15_Zjuding/index.tsx#L1597)
2072. 未读取身份的读者头像
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1491](../src/scenes/phone/P15_Zjuding/index.tsx#L1491)
2073. 校园卡持卡人读者头像
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1491](../src/scenes/phone/P15_Zjuding/index.tsx#L1491)
2074. 022恢复申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1530](../src/scenes/phone/P15_Zjuding/index.tsx#L1530)；[src/scenes/phone/P15_Zjuding/index.tsx:1531](../src/scenes/phone/P15_Zjuding/index.tsx#L1531)；[src/scenes/phone/P15_Zjuding/index.tsx:1534](../src/scenes/phone/P15_Zjuding/index.tsx#L1534)；[src/scenes/phone/P15_Zjuding/index.tsx:1536](../src/scenes/phone/P15_Zjuding/index.tsx#L1536)
2075. 返回现场
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1540](../src/scenes/phone/P15_Zjuding/index.tsx#L1540)；[src/scenes/phone/P15_Zjuding/index.tsx:1541](../src/scenes/phone/P15_Zjuding/index.tsx#L1541)；[src/scenes/phone/P15_Zjuding/index.tsx:1544](../src/scenes/phone/P15_Zjuding/index.tsx#L1544)；[src/scenes/phone/P15_Zjuding/index.tsx:1545](../src/scenes/phone/P15_Zjuding/index.tsx#L1545)；[src/scenes/phone/P15_Zjuding/index.tsx:1887](../src/scenes/phone/P15_Zjuding/index.tsx#L1887)
2076. 022 座位恢复申请已开放
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1552](../src/scenes/phone/P15_Zjuding/index.tsx#L1552)
2077. 帖子当前排名 01，可提交三项证明。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1553](../src/scenes/phone/P15_Zjuding/index.tsx#L1553)
2078. 活动日历
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1560](../src/scenes/phone/P15_Zjuding/index.tsx#L1560)
2079. （活动报名）“我著·我...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1562](../src/scenes/phone/P15_Zjuding/index.tsx#L1562)
2080. （活动报名）书香浙大·开...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1562](../src/scenes/phone/P15_Zjuding/index.tsx#L1562)
2081. 通知公告
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1565](../src/scenes/phone/P15_Zjuding/index.tsx#L1565)
2082. 关于新增校外数据库访...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1567](../src/scenes/phone/P15_Zjuding/index.tsx#L1567)
2083. 图书馆数字资源校外访...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1567](../src/scenes/phone/P15_Zjuding/index.tsx#L1567)
2084. 规章制度
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1570](../src/scenes/phone/P15_Zjuding/index.tsx#L1570)
2085. 读者文明使用空间须知
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)
2086. 图书馆座位预约管理规则
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)
2087. 图书馆馆藏检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1595](../src/scenes/phone/P15_Zjuding/index.tsx#L1595)
2088. 文献库选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1601](../src/scenes/phone/P15_Zjuding/index.tsx#L1601)
2089. 当前正在使用中文文献库。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1602](../src/scenes/phone/P15_Zjuding/index.tsx#L1602)
2090. 中文文献库
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1602](../src/scenes/phone/P15_Zjuding/index.tsx#L1602)
2091. 检索条件
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1606](../src/scenes/phone/P15_Zjuding/index.tsx#L1606)
2092. 搜索文献
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1614](../src/scenes/phone/P15_Zjuding/index.tsx#L1614)
2093. 馆藏检索关键词
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1615](../src/scenes/phone/P15_Zjuding/index.tsx#L1615)
2094. 检索范围
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1620](../src/scenes/phone/P15_Zjuding/index.tsx#L1620)
2095. 当前检索字段固定为书名，高级检索可查看其他条件。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
2096. 检索字段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
2097. 当前馆藏范围为全部馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2098. 馆藏范围
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2099. 全部馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2100. 高级检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1628](../src/scenes/phone/P15_Zjuding/index.tsx#L1628)
2101. 收起高级检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1628](../src/scenes/phone/P15_Zjuding/index.tsx#L1628)
2102. 检索到的书籍数：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1630](../src/scenes/phone/P15_Zjuding/index.tsx#L1630)
2103. 高级检索字段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1633](../src/scenes/phone/P15_Zjuding/index.tsx#L1633)
2104. 包含全部关键词
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1634](../src/scenes/phone/P15_Zjuding/index.tsx#L1634)
2105. 题名匹配
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1634](../src/scenes/phone/P15_Zjuding/index.tsx#L1634)
2106. 全部分类
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1635](../src/scenes/phone/P15_Zjuding/index.tsx#L1635)
2107. 索书号分类
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1635](../src/scenes/phone/P15_Zjuding/index.tsx#L1635)
2108. 馆藏地点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1636](../src/scenes/phone/P15_Zjuding/index.tsx#L1636)
2109. 基础图书馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1636](../src/scenes/phone/P15_Zjuding/index.tsx#L1636)；[src/scenes/rpg/ZijingangCampusLayout.ts:100](../src/scenes/rpg/ZijingangCampusLayout.ts#L100)
2110. 异常外借状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1643](../src/scenes/phone/P15_Zjuding/index.tsx#L1643)
2111. 签到记录夹页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1644](../src/scenes/phone/P15_Zjuding/index.tsx#L1644)
2112. 异常外借
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1644](../src/scenes/phone/P15_Zjuding/index.tsx#L1644)
2113. 记录关键词：倒影
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1651](../src/scenes/phone/P15_Zjuding/index.tsx#L1651)
2114. 已取得：倒影
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1651](../src/scenes/phone/P15_Zjuding/index.tsx#L1651)
2115. 馆藏检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1663](../src/scenes/phone/P15_Zjuding/index.tsx#L1663)
2116. 检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1665](../src/scenes/phone/P15_Zjuding/index.tsx#L1665)
2117. 选择馆藏{{result.title}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1671](../src/scenes/phone/P15_Zjuding/index.tsx#L1671)
2118. {{result.title}}封面
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1672](../src/scenes/phone/P15_Zjuding/index.tsx#L1672)
2119. 著者：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1675](../src/scenes/phone/P15_Zjuding/index.tsx#L1675)
2120. 索书号：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1676](../src/scenes/phone/P15_Zjuding/index.tsx#L1676)
2121. 无检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1687](../src/scenes/phone/P15_Zjuding/index.tsx#L1687)
2122. 没有匹配馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1688](../src/scenes/phone/P15_Zjuding/index.tsx#L1688)
2123. 可尝试书名、作者或索书号中的连续文字。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1689](../src/scenes/phone/P15_Zjuding/index.tsx#L1689)
2124. 新书推荐
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1692](../src/scenes/phone/P15_Zjuding/index.tsx#L1692)；[src/scenes/phone/P15_Zjuding/index.tsx:1693](../src/scenes/phone/P15_Zjuding/index.tsx#L1693)
2125. 输入题名后，相似书籍会同时列出。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1694](../src/scenes/phone/P15_Zjuding/index.tsx#L1694)
2126. 022座位恢复申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1704](../src/scenes/phone/P15_Zjuding/index.tsx#L1704)；[src/scenes/phone/P15_Zjuding/index.tsx:1706](../src/scenes/phone/P15_Zjuding/index.tsx#L1706)
2127. 基础馆 · 二楼南区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1713](../src/scenes/phone/P15_Zjuding/index.tsx#L1713)
2128. CC98 公示排名：01
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1714](../src/scenes/phone/P15_Zjuding/index.tsx#L1714)
2129. 恢复材料进度 {{submitted.length}}/3
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1718](../src/scenes/phone/P15_Zjuding/index.tsx#L1718)
2130. 旧版规则 · 恢复条件
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1722](../src/scenes/phone/P15_Zjuding/index.tsx#L1722)
2131. CC98 公示已生效。三份材料分别确认占用物身份、座位编号与本人到馆记录。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1723](../src/scenes/phone/P15_Zjuding/index.tsx#L1723)
2132. 恢复证明槽位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1725](../src/scenes/phone/P15_Zjuding/index.tsx#L1725)
2133. 待取得
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2134. 可提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2135. 已核验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2136. 来源：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1745](../src/scenes/phone/P15_Zjuding/index.tsx#L1745)
2137. 材料已锁定到本次申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1746](../src/scenes/phone/P15_Zjuding/index.tsx#L1746)
2138. 道具栏已识别，可提交校验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1746](../src/scenes/phone/P15_Zjuding/index.tsx#L1746)
2139. 提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1753](../src/scenes/phone/P15_Zjuding/index.tsx#L1753)
2140. 座位释放PASS已签发
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1761](../src/scenes/phone/P15_Zjuding/index.tsx#L1761)
2141. PASS 已签发
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1763](../src/scenes/phone/P15_Zjuding/index.tsx#L1763)；[src/scenes/phone/P15_Zjuding/index.tsx:1854](../src/scenes/phone/P15_Zjuding/index.tsx#L1854)
2142. 凭证只对 RPG 图书馆内的 022 书包生效。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1764](../src/scenes/phone/P15_Zjuding/index.tsx#L1764)
2143. 回图书馆处理书包
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1765](../src/scenes/phone/P15_Zjuding/index.tsx#L1765)
2144. 生成 022 座位释放 PASS
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1769](../src/scenes/phone/P15_Zjuding/index.tsx#L1769)
2145. 图书馆空间列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1777](../src/scenes/phone/P15_Zjuding/index.tsx#L1777)
2146. 图书馆空间预约...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1779](../src/scenes/phone/P15_Zjuding/index.tsx#L1779)；[src/scenes/phone/P15_Zjuding/index.tsx:1863](../src/scenes/phone/P15_Zjuding/index.tsx#L1863)
2147. 空间预约菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
2148. 收起座位预约栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1785](../src/scenes/phone/P15_Zjuding/index.tsx#L1785)
2149. 展开座位预约栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1785](../src/scenes/phone/P15_Zjuding/index.tsx#L1785)
2150. 预
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2151. 约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2152. 座
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2153. 空间选择模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1791](../src/scenes/phone/P15_Zjuding/index.tsx#L1791)
2154. 列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1792](../src/scenes/phone/P15_Zjuding/index.tsx#L1792)
2155. 快速选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1793](../src/scenes/phone/P15_Zjuding/index.tsx#L1793)
2156. 空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1796](../src/scenes/phone/P15_Zjuding/index.tsx#L1796)
2157. 显示
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1796](../src/scenes/phone/P15_Zjuding/index.tsx#L1796)
2158. 可预约空间列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1802](../src/scenes/phone/P15_Zjuding/index.tsx#L1802)
2159. {{room.label}}自习空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1806](../src/scenes/phone/P15_Zjuding/index.tsx#L1806)
2160. 主馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1807](../src/scenes/phone/P15_Zjuding/index.tsx#L1807)；[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2161. 空闲
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1811](../src/scenes/phone/P15_Zjuding/index.tsx#L1811)；[src/scenes/phone/P15_Zjuding/index.tsx:1822](../src/scenes/phone/P15_Zjuding/index.tsx#L1822)
2162. 预约{{room.label}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1812](../src/scenes/phone/P15_Zjuding/index.tsx#L1812)
2163. 快速选择空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1818](../src/scenes/phone/P15_Zjuding/index.tsx#L1818)
2164. 我的中心
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1830](../src/scenes/phone/P15_Zjuding/index.tsx#L1830)
2165. 当前位于空间预约列表。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1832](../src/scenes/phone/P15_Zjuding/index.tsx#L1832)
2166. 座位已恢复
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1850](../src/scenes/phone/P15_Zjuding/index.tsx#L1850)
2167. 清退已执行
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1852](../src/scenes/phone/P15_Zjuding/index.tsx#L1852)
2168. 恢复申请待提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1856](../src/scenes/phone/P15_Zjuding/index.tsx#L1856)
2169. 公示审核中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1858](../src/scenes/phone/P15_Zjuding/index.tsx#L1858)
2170. 占用异常
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1859](../src/scenes/phone/P15_Zjuding/index.tsx#L1859)
2171. 图书馆座位选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1861](../src/scenes/phone/P15_Zjuding/index.tsx#L1861)
2172. 选座菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
2173. 主馆 · 二层 ·
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1870](../src/scenes/phone/P15_Zjuding/index.tsx#L1870)
2174. 查看平面图 ›
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1872](../src/scenes/phone/P15_Zjuding/index.tsx#L1872)
2175. 已切换到下方平面图。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1872](../src/scenes/phone/P15_Zjuding/index.tsx#L1872)
2176. {{selectedRoom}}：座位 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.seats ?? 0}}，当前空闲 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.available ?? 0}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1873](../src/scenes/phone/P15_Zjuding/index.tsx#L1873)
2177. 查看房间详情 ›
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1873](../src/scenes/phone/P15_Zjuding/index.tsx#L1873)
2178. 当前空余 32 个座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1876](../src/scenes/phone/P15_Zjuding/index.tsx#L1876)
2179. 空余 32
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1876](../src/scenes/phone/P15_Zjuding/index.tsx#L1876)
2180. 022调查状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1880](../src/scenes/phone/P15_Zjuding/index.tsx#L1880)
2181. 当前现场状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1883](../src/scenes/phone/P15_Zjuding/index.tsx#L1883)
2182. 书包仍在现场，手机页面只负责查询与提交材料。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1885](../src/scenes/phone/P15_Zjuding/index.tsx#L1885)
2183. 现场已清空，座位等待本人确认。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1885](../src/scenes/phone/P15_Zjuding/index.tsx#L1885)
2184. 预约日期与时段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1890](../src/scenes/phone/P15_Zjuding/index.tsx#L1890)
2185. 座位显示模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1903](../src/scenes/phone/P15_Zjuding/index.tsx#L1903)
2186. 地图模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1904](../src/scenes/phone/P15_Zjuding/index.tsx#L1904)
2187. 列表模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1905](../src/scenes/phone/P15_Zjuding/index.tsx#L1905)
2188. 筛选：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1909](../src/scenes/phone/P15_Zjuding/index.tsx#L1909)
2189. 已选：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1909](../src/scenes/phone/P15_Zjuding/index.tsx#L1909)
2190. 筛选
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1910](../src/scenes/phone/P15_Zjuding/index.tsx#L1910)
2191. 可选座位列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1923](../src/scenes/phone/P15_Zjuding/index.tsx#L1923)
2192. 手机端保留调查记录；书包、小票与 PASS 操作均在图书馆现场完成。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1933](../src/scenes/phone/P15_Zjuding/index.tsx#L1933)
2193. 返回
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1937](../src/scenes/phone/P15_Zjuding/index.tsx#L1937)
2194. 立即预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1939](../src/scenes/phone/P15_Zjuding/index.tsx#L1939)
2195. 预约成功
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1939](../src/scenes/phone/P15_Zjuding/index.tsx#L1939)
2196. 浙大钉首页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1946](../src/scenes/phone/P15_Zjuding/index.tsx#L1946)
2197. 打开个人菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1952](../src/scenes/phone/P15_Zjuding/index.tsx#L1952)
2198. 个人菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1956](../src/scenes/phone/P15_Zjuding/index.tsx#L1956)
2199. 浙江大学
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1963](../src/scenes/phone/P15_Zjuding/index.tsx#L1963)
2200. 打开浙大百事通搜索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1966](../src/scenes/phone/P15_Zjuding/index.tsx#L1966)
2201. 百事通
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1967](../src/scenes/phone/P15_Zjuding/index.tsx#L1967)；[src/scenes/phone/P15_Zjuding/index.tsx:1970](../src/scenes/phone/P15_Zjuding/index.tsx#L1970)
2202. 系统红圈
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1983](../src/scenes/phone/P15_Zjuding/index.tsx#L1983)
2203. 求
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1986](../src/scenes/phone/P15_Zjuding/index.tsx#L1986)；[src/scenes/phone/P15_Zjuding/index.tsx:1989](../src/scenes/phone/P15_Zjuding/index.tsx#L1989)；[src/scenes/phone/P15_Zjuding/index.tsx:2092](../src/scenes/phone/P15_Zjuding/index.tsx#L2092)
2204. /求是学院（归口...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1993](../src/scenes/phone/P15_Zjuding/index.tsx#L1993)
2205. 身份码
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1998](../src/scenes/phone/P15_Zjuding/index.tsx#L1998)；[src/scenes/phone/P15_Zjuding/index.tsx:1999](../src/scenes/phone/P15_Zjuding/index.tsx#L1999)
2206. 校园钱包
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2008](../src/scenes/phone/P15_Zjuding/index.tsx#L2008)；[src/scenes/phone/P15_Zjuding/index.tsx:2009](../src/scenes/phone/P15_Zjuding/index.tsx#L2009)
2207. 搜索浙大钉应用与服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2025](../src/scenes/phone/P15_Zjuding/index.tsx#L2025)
2208. 搜索应用与服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2026](../src/scenes/phone/P15_Zjuding/index.tsx#L2026)
2209. 浙大百事通
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2029](../src/scenes/phone/P15_Zjuding/index.tsx#L2029)；[src/scenes/phone/P15_Zjuding/index.tsx:2104](../src/scenes/phone/P15_Zjuding/index.tsx#L2104)
2210. 浙大钉应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2032](../src/scenes/phone/P15_Zjuding/index.tsx#L2032)
2211. 系统对话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2091](../src/scenes/phone/P15_Zjuding/index.tsx#L2091)
2212. 继续对话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2099](../src/scenes/phone/P15_Zjuding/index.tsx#L2099)
2213. 搜索应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2106](../src/scenes/phone/P15_Zjuding/index.tsx#L2106)
2214. 输入应用名称
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2112](../src/scenes/phone/P15_Zjuding/index.tsx#L2112)
2215. 没有匹配的应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2132](../src/scenes/phone/P15_Zjuding/index.tsx#L2132)
2216. 选择馆舍
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2153](../src/scenes/phone/P15_Zjuding/index.tsx#L2153)
2217. 农医馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2218. 紫金港西区馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2219. 已选择{{library}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2162](../src/scenes/phone/P15_Zjuding/index.tsx#L2162)
2220. 预约日期
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2172](../src/scenes/phone/P15_Zjuding/index.tsx#L2172)
2221. 07月11日 · 明天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2222. 07月12日 · 后天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2223. 预约时段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2183](../src/scenes/phone/P15_Zjuding/index.tsx#L2183)
2224. 筛选座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2194](../src/scenes/phone/P15_Zjuding/index.tsx#L2194)
2225. 安静区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2226. 靠窗
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2227. 有电源
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2228. 当前座位筛选已切换为：{{filter}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2197](../src/scenes/phone/P15_Zjuding/index.tsx#L2197)
2229. 确认预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2205](../src/scenes/phone/P15_Zjuding/index.tsx#L2205)；[src/scenes/phone/P15_Zjuding/index.tsx:2216](../src/scenes/phone/P15_Zjuding/index.tsx#L2216)
2230. 号座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2207](../src/scenes/phone/P15_Zjuding/index.tsx#L2207)
2231. 再想一下
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2213](../src/scenes/phone/P15_Zjuding/index.tsx#L2213)
2232. 学
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:56](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L56)
2233. 课程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2234. 签到
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)
2235. 学习
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:482](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L482)
2236. 智云课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:65](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L65)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:70](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L70)
2237. 云
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:66](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L66)
2238. 课件
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2239. 课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2240. 日程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2241. 校园地图
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1420](../src/scenes/phone/P15_Zjuding/index.tsx#L1420)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:75](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L75)
2242. 导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
2243. 地图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
2244. 网络缴费
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:85](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L85)
2245. 连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
2246. 校园网
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2247. 账户
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
2248. 后勤服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:95](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L95)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:72](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L72)
2249. 勤
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:96](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L96)
2250. 报修
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2251. 服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:484](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L484)
2252. 网络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2253. 寻
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:106](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L106)
2254. 档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2255. 失物
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2256. 书包
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2257. 证明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2258. 访客预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:115](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L115)
2259. 访
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:116](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L116)
2260. 草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2261. 访客
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2262. 入校
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2263. 预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1812](../src/scenes/phone/P15_Zjuding/index.tsx#L1812)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2264. 图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:126](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L126)
2265. 馆藏
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2266. 图书
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2267. 慧学外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:135](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L135)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:75](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L75)
2268. 词汇
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2269. 卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2270. 外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2271. 英语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2272. 开发反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:145](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L145)
2273. 信
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:146](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L146)
2274. 反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2275. 开发者
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2276. 意见
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2277. 新
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:132](../src/scenes/phone/P15_Zjuding/index.tsx#L132)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:152](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L152)
2278. 全部
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:405](../src/scenes/phone/P15_Zjuding/index.tsx#L405)；[src/scenes/phone/P15_Zjuding/index.tsx:411](../src/scenes/phone/P15_Zjuding/index.tsx#L411)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:156](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L156)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)
2279. 工作台
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:140](../src/scenes/phone/P15_Zjuding/index.tsx#L140)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:86](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L86)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:491](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L491)
2280. 校园参观
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:61](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L61)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2281. 功能建议
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:65](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L65)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2282. 网络账户
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:71](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L71)
2283. 访客预约预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:74](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L74)
2284. 开发者反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:76](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L76)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:472](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L472)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2285. 全部应用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:77](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L77)
2286. 通讯录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:139](../src/scenes/phone/P15_Zjuding/index.tsx#L139)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:78](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L78)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:85](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L85)
2287. 首页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:138](../src/scenes/phone/P15_Zjuding/index.tsx#L138)；[src/scenes/phone/P15_Zjuding/index.tsx:146](../src/scenes/phone/P15_Zjuding/index.tsx#L146)；[src/scenes/phone/P15_Zjuding/index.tsx:1830](../src/scenes/phone/P15_Zjuding/index.tsx#L1830)；[src/scenes/phone/P15_Zjuding/index.tsx:1831](../src/scenes/phone/P15_Zjuding/index.tsx#L1831)；[src/scenes/phone/P15_Zjuding/index.tsx:1832](../src/scenes/phone/P15_Zjuding/index.tsx#L1832)；[src/scenes/phone/P15_Zjuding/index.tsx:2057](../src/scenes/phone/P15_Zjuding/index.tsx#L2057)；[src/scenes/phone/P15_Zjuding/index.tsx:2059](../src/scenes/phone/P15_Zjuding/index.tsx#L2059)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:84](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L84)
2288. 北教学区 A-204
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2289. 化学工程基础
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2290. 课程资料已缓存在本机。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2291. 周一 08:00
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2292. 数据方法与 AI4S
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2293. 线上课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2294. 周三 13:15
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2295. 最近一次课件仅供预览。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2296. 安全提醒已读取，不产生签到记录。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2297. 东教学区 3-106
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2298. 实验室安全
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2299. 周五 10:00
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2300. 导向；路径识别
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:98](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L98)
2301. 倒影；反射
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:99](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L99)
2302. 维修；保养
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:100](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L100)
2303. 书包物品识别报告
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:104](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L104)
2304. 照片·本机识别
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:104](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L104)
2305. 图书馆前台
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:105](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L105)
2306. 基础馆二层南区
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:106](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L106)
2307. 本人到馆证明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:107](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L107)
2308. 浙大体艺·到馆记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:107](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L107)
2309. 游戏反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:112](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L112)
2310. ## 反馈内容 / {{content}} / ## 游戏 / 7:55
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:115](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L115)
2311. ## 反馈内容 / 请描述问题、复现步骤或建议。 / ## 游戏 / 7:55
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:116](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L116)
2312. 校园网已连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:208](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L208)
2313. 当前使用移动数据
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:210](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L210)
2314. 当前处于离线状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:211](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L211)
2315. 校园网状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:223](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L223)
2316. 校园身份已读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:230](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L230)
2317. {{studentName}}·{{studentId}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:231](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L231)
2318. 查看校园卡
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:232](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L232)
2319. 图书馆座位预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:239](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L239)
2320. 已预约 {{state.ui.librarySelectedSeat ?? "022"}} 号座位
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:240](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L240)
2321. 查看图书馆
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:241](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L241)
2322. 图书馆服务已开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:247](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L247)
2323. 当前可用功能以图书馆首页实际状态为准。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:248](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L248)
2324. 打开图书馆
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:249](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L249)
2325. 请先填写意见内容。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:310](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L310)
2326. 反馈草稿已保存。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:315](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L315)
2327. 反馈内容已保留在当前页面。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:316](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L316)
2328. 反馈内容已清空。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:322](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L322)
2329. 本机课程预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:341](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L341)
2330. 门课程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:342](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L342)
2331. 查看课程日程和缓存说明，不产生签到或成绩记录。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:343](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L343)
2332. 课程列表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:345](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L345)
2333. 查看
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)；[src/scenes/phone/P15_Zjuding/index.tsx:1753](../src/scenes/phone/P15_Zjuding/index.tsx#L1753)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:352](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L352)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:390](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L390)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:410](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L410)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2334. 当前连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:365](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L365)
2335. 页面只读取本机网络状态，不扣费、不充值、不生成账单。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:367](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L367)
2336. 可用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2337. 浙大钉与 CC98 需要校园网。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2338. 备用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
2339. 浙大体艺的网络规则与浙大钉不同。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
2340. 查看连接说明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:374](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L374)
2341. 收起连接说明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:374](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L374)
2342. 如需切换网络，请返回手机控制中心。本页不会自动修改网络模式。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:377](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L377)
2343. 校园服务聚合
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:385](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L385)
2344. 后勤状态台
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:386](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L386)
2345. 所有条目只读取已开放的本地功能，未提交任何报修工单。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:387](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L387)
2346. 网络服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:390](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L390)
2347. 当前阶段未开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2348. 进入
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2349. 图书馆服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1504](../src/scenes/phone/P15_Zjuding/index.tsx#L1504)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)
2350. 未开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2351. 已开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2352. 校园导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2353. 部门黄页可用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2354. 服务联络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2355. 公共联络表可查看
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2356. 仅显示已公开记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:401](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L401)
2357. 份本机档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:402](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L402)
2358. 查看档案不会生成证明、改变物品或推进图书馆进度。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:403](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L403)
2359. 已公开失物档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:406](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L406)
2360. 本机已取得
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:409](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L409)
2361. 后续只会在相关记录真正取得后显示。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:415](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L415)
2362. 暂无已公开档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:415](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L415)
2363. 本机预览工具
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:423](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L423)
2364. 访客信息草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:424](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L424)
2365. 草稿仅保存在当前浏览器会话，不代表正式入校申请。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:425](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L425)
2366. 访客预览草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:427](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L427)
2367. 访客姓名
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:428](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L428)
2368. 用于本机预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:428](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L428)
2369. 到访日期
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:429](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L429)
2370. 例如：08月24日
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:429](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L429)
2371. 到访用途
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2372. 亲友来访
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2373. 学术交流
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2374. 保存预览草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:431](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L431)
2375. 清空
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:431](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L431)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:475](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L475)
2376. 未提交·本机预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:433](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L433)
2377. 本地微卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:441](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L441)
2378. 校园场景外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:442](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L442)
2379. 点击卡片查看中文释义与场景例句。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:443](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L443)
2380. 外语卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:445](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L445)
2381. 点击查看释义
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:450](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L450)
2382. 7:55 开发者通道
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:464](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L464)
2383. 向开发团队反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:465](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L465)
2384. 整理问题或建议后，可直接前往 GitHub 提交 Issue。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:466](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L466)
2385. 7:55 开发者链接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:468](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L468)
2386. GitHub 仓库
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:469](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L469)
2387. 提交 Issue
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:470](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L470)
2388. 交互问题
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2389. 内容校对
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2390. 反馈内容
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:474](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L474)
2391. 描述问题、复现步骤或建议
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:474](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L474)
2392. 保存草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:475](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L475)
2393. 校园
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:483](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L483)
2394. 统一应用目录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:490](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L490)
2395. 应用状态与首页、搜索完全一致。未开放项保留原名称与静态图标。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:492](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L492)
2396. 校园公开联络表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:521](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L521)
2397. 个服务联络点
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:522](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L522)
2398. 号码来自当前游戏内容，页面不会直接拨号。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:523](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L523)
2399. 部门联系方式
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:525](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L525)
2400. 部门黄页会在剧情恢复校园身份后开放。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:530](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L530)
2401. 打开部门黄页
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:530](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L530)
2402. 当前已公开状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:537](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L537)
2403. 条消息
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:538](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L538)
2404. 只聚合已发生的网络、身份、预约和记录状态。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:539](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L539)
2405. 消息列表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:541](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L541)
2406. 已读
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:558](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L558)
2407. 取得电子校园卡后显示
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2408. 身份未读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1963](../src/scenes/phone/P15_Zjuding/index.tsx#L1963)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2409. 校园身份
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2410. 当前网络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:572](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L572)
2411. 详情
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:572](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L572)
2412. 未读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
2413. 已读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
2414. 当前无预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2415. 图书馆预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2416. 座位 {{state.ui.librarySelectedSeat ?? "022"}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2417. GitHub Issues
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2418. 返回，离开{{PANEL\_TITLES\[panel\]}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:586](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L586)
2419. 浙大钉导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:592](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L592)
2420. 基础图书馆入口 · {{RPG\_CONTROL\_HINTS.libraryGate}}
   来源：[src/scenes/rpg/BootScene.ts:166](../src/scenes/rpg/BootScene.ts#L166)
2421. 东区大食堂入口 · {{formatRpgInteractionHint("进入食堂")}}
   来源：[src/scenes/rpg/BootScene.ts:171](../src/scenes/rpg/BootScene.ts#L171)
2422. 剧场入口 · {{formatRpgInteractionHint("进入剧场")}}
   来源：[src/scenes/rpg/BootScene.ts:176](../src/scenes/rpg/BootScene.ts#L176)
2423. 共享单车
   来源：[src/scenes/rpg/BootScene.ts:568](../src/scenes/rpg/BootScene.ts#L568)；[src/scenes/rpg/BootScene.ts:577](../src/scenes/rpg/BootScene.ts#L577)；[src/scenes/rpg/BootScene.ts:585](../src/scenes/rpg/BootScene.ts#L585)；[src/scenes/rpg/BootScene.ts:596](../src/scenes/rpg/BootScene.ts#L596)；[src/scenes/rpg/RpgGameHost.tsx:1561](../src/scenes/rpg/RpgGameHost.tsx#L1561)；[src/scenes/rpg/RpgItemUseGuidance.ts:206](../src/scenes/rpg/RpgItemUseGuidance.ts#L206)；[src/scenes/rpg/RpgItemUseGuidance.ts:207](../src/scenes/rpg/RpgItemUseGuidance.ts#L207)；[src/scenes/rpg/RpgItemUseGuidance.ts:208](../src/scenes/rpg/RpgItemUseGuidance.ts#L208)；[src/scenes/rpg/RpgItemUseGuidance.ts:209](../src/scenes/rpg/RpgItemUseGuidance.ts#L209)
2424. 共享单车交互尚未开放，请先完成食堂内部流程。
   来源：[src/scenes/rpg/BootScene.ts:569](../src/scenes/rpg/BootScene.ts#L569)
2425. wrong\_item
   来源：[src/scenes/rpg/BootScene.ts:576](../src/scenes/rpg/BootScene.ts#L576)；[src/scenes/rpg/RpgGameHost.tsx:1497](../src/scenes/rpg/RpgGameHost.tsx#L1497)
2426. 共享单车当前只接收纸巾或 2 元现金。
   来源：[src/scenes/rpg/BootScene.ts:578](../src/scenes/rpg/BootScene.ts#L578)
2427. missed\_target
   来源：[src/scenes/rpg/BootScene.ts:585](../src/scenes/rpg/BootScene.ts#L585)；[src/scenes/rpg/BootScene.ts:595](../src/scenes/rpg/BootScene.ts#L595)；[src/scenes/rpg/RpgInventoryDock.tsx:387](../src/scenes/rpg/RpgInventoryDock.tsx#L387)
2428. 松手点没有进入共享单车车身的高亮范围。
   来源：[src/scenes/rpg/BootScene.ts:597](../src/scenes/rpg/BootScene.ts#L597)
2429. success
   来源：[src/scenes/rpg/BootScene.ts:621](../src/scenes/rpg/BootScene.ts#L621)
2430. campus-minimap
   来源：[src/scenes/rpg/RpgCameraController.ts:27](../src/scenes/rpg/RpgCameraController.ts#L27)
2431. WASD 移动
   来源：[src/scenes/rpg/RpgControlHints.ts:2](../src/scenes/rpg/RpgControlHints.ts#L2)
2432. 空格键
   来源：[src/scenes/rpg/RpgControlHints.ts:3](../src/scenes/rpg/RpgControlHints.ts#L3)
2433. WASD 移动 · 空格键进入
   来源：[src/scenes/rpg/RpgControlHints.ts:4](../src/scenes/rpg/RpgControlHints.ts#L4)
2434. 空格键继续
   来源：[src/scenes/rpg/RpgControlHints.ts:5](../src/scenes/rpg/RpgControlHints.ts#L5)
2435. 拖动道具 {{label}}
   来源：[src/scenes/rpg/RpgControlHints.ts:14](../src/scenes/rpg/RpgControlHints.ts#L14)
2436. 启真湖的帖子已经归档,不能再补拍了。
   来源：[src/scenes/rpg/RpgGameHost.tsx:236](../src/scenes/rpg/RpgGameHost.tsx#L236)
2437. 这里构不成画面,换个位置再试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:237](../src/scenes/rpg/RpgGameHost.tsx#L237)
2438. 这张照片已经不在记录里了,重新拍一张。
   来源：[src/scenes/rpg/RpgGameHost.tsx:238](../src/scenes/rpg/RpgGameHost.tsx#L238)
2439. 草稿和照片对不上,请重新拍摄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:239](../src/scenes/rpg/RpgGameHost.tsx#L239)
2440. 先把该选的都选好,再存草稿。
   来源：[src/scenes/rpg/RpgGameHost.tsx:240](../src/scenes/rpg/RpgGameHost.tsx#L240)
2441. {{targetLabel}}已完成当前操作。
   来源：[src/scenes/rpg/RpgGameHost.tsx:354](../src/scenes/rpg/RpgGameHost.tsx#L354)
2442. 切到浅色操作后再使用道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:355](../src/scenes/rpg/RpgGameHost.tsx#L355)
2443. {{targetLabel}}当前需要其他道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:356](../src/scenes/rpg/RpgGameHost.tsx#L356)
2444. 当前目标还没有观察记录；深色观察可补充坐标。
   来源：[src/scenes/rpg/RpgGameHost.tsx:357](../src/scenes/rpg/RpgGameHost.tsx#L357)
2445. 普通鱼钩无法固定纸条。需要完成湖区道具链。
   来源：[src/scenes/rpg/RpgGameHost.tsx:358](../src/scenes/rpg/RpgGameHost.tsx#L358)
2446. 这个目标已经完成，请查看当前任务。
   来源：[src/scenes/rpg/RpgGameHost.tsx:359](../src/scenes/rpg/RpgGameHost.tsx#L359)
2447. 当前剧情条件尚未满足。
   来源：[src/scenes/rpg/RpgGameHost.tsx:360](../src/scenes/rpg/RpgGameHost.tsx#L360)
2448. 该交互点当前未开放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:361](../src/scenes/rpg/RpgGameHost.tsx#L361)
2449. 当前操作已记录。
   来源：[src/scenes/rpg/RpgGameHost.tsx:379](../src/scenes/rpg/RpgGameHost.tsx#L379)
2450. 当前操作已经完成。
   来源：[src/scenes/rpg/RpgGameHost.tsx:380](../src/scenes/rpg/RpgGameHost.tsx#L380)
2451. 切换到目标要求的现实模式后重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:381](../src/scenes/rpg/RpgGameHost.tsx#L381)
2452. 当前流程还不能安装手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1435](../src/scenes/rpg/RpgGameHost.tsx#L1435)
2453. 角色
   来源：[src/scenes/rpg/RpgGameHost.tsx:1441](../src/scenes/rpg/RpgGameHost.tsx#L1441)；[src/scenes/rpg/RpgItemUseGuidance.ts:130](../src/scenes/rpg/RpgItemUseGuidance.ts#L130)；[src/scenes/rpg/RpgItemUseGuidance.ts:131](../src/scenes/rpg/RpgItemUseGuidance.ts#L131)；[src/scenes/rpg/RpgItemUseGuidance.ts:132](../src/scenes/rpg/RpgItemUseGuidance.ts#L132)；[src/scenes/rpg/RpgItemUseGuidance.ts:133](../src/scenes/rpg/RpgItemUseGuidance.ts#L133)
2454. unavailable
   来源：[src/scenes/rpg/RpgGameHost.tsx:1463](../src/scenes/rpg/RpgGameHost.tsx#L1463)；[src/scenes/rpg/RpgGameHost.tsx:1471](../src/scenes/rpg/RpgGameHost.tsx#L1471)；[src/scenes/rpg/RpgGameHost.tsx:1529](../src/scenes/rpg/RpgGameHost.tsx#L1529)
2455. wrong\_target
   来源：[src/scenes/rpg/RpgGameHost.tsx:1488](../src/scenes/rpg/RpgGameHost.tsx#L1488)；[src/scenes/rpg/RpgGameHost.tsx:1497](../src/scenes/rpg/RpgGameHost.tsx#L1497)；[src/scenes/rpg/RpgInteractionContract.ts:1332](../src/scenes/rpg/RpgInteractionContract.ts#L1332)
2456. cleaned
   来源：[src/scenes/rpg/RpgGameHost.tsx:1552](../src/scenes/rpg/RpgGameHost.tsx#L1552)
2457. 共享单车车锁
   来源：[src/scenes/rpg/RpgGameHost.tsx:1553](../src/scenes/rpg/RpgGameHost.tsx#L1553)；[src/scenes/rpg/RpgItemUseGuidance.ts:202](../src/scenes/rpg/RpgItemUseGuidance.ts#L202)；[src/scenes/rpg/RpgItemUseGuidance.ts:203](../src/scenes/rpg/RpgItemUseGuidance.ts#L203)
2458. 清洁车锁需要浅色操作。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1554](../src/scenes/rpg/RpgGameHost.tsx#L1554)
2459. rule
   来源：[src/scenes/rpg/RpgGameHost.tsx:1554](../src/scenes/rpg/RpgGameHost.tsx#L1554)；[src/scenes/rpg/RpgGameHost.tsx:1562](../src/scenes/rpg/RpgGameHost.tsx#L1562)
2460. paid
   来源：[src/scenes/rpg/RpgGameHost.tsx:1560](../src/scenes/rpg/RpgGameHost.tsx#L1560)
2461. 付款需要浅色操作，且车锁表面已经清洁。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1562](../src/scenes/rpg/RpgGameHost.tsx#L1562)
2462. 入口海报
   来源：[src/scenes/rpg/RpgGameHost.tsx:1573](../src/scenes/rpg/RpgGameHost.tsx#L1573)；[src/scenes/rpg/RpgItemUseGuidance.ts:217](../src/scenes/rpg/RpgItemUseGuidance.ts#L217)；[src/scenes/rpg/RpgItemUseGuidance.ts:218](../src/scenes/rpg/RpgItemUseGuidance.ts#L218)
2463. 检票闸机右侧读票器
   来源：[src/scenes/rpg/RpgGameHost.tsx:1586](../src/scenes/rpg/RpgGameHost.tsx#L1586)；[src/scenes/rpg/RpgItemUseGuidance.ts:224](../src/scenes/rpg/RpgItemUseGuidance.ts#L224)；[src/scenes/rpg/RpgItemUseGuidance.ts:227](../src/scenes/rpg/RpgItemUseGuidance.ts#L227)
2464. 验票完成，闸机已经放行；临时观演票会保留。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1588](../src/scenes/rpg/RpgGameHost.tsx#L1588)
2465. 当前剧情条件不允许验票，请先完成入口取票流程。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1589](../src/scenes/rpg/RpgGameHost.tsx#L1589)
2466. 道具箱旁票据扫描器
   来源：[src/scenes/rpg/RpgGameHost.tsx:1611](../src/scenes/rpg/RpgGameHost.tsx#L1611)；[src/scenes/rpg/RpgItemUseGuidance.ts:234](../src/scenes/rpg/RpgItemUseGuidance.ts#L234)；[src/scenes/rpg/RpgItemUseGuidance.ts:237](../src/scenes/rpg/RpgItemUseGuidance.ts#L237)
2467. 票据扫描完成，道具箱已经解锁；临时观演票已完成用途并从道具栏移除。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1613](../src/scenes/rpg/RpgGameHost.tsx#L1613)
2468. 扫描票据需要浅色操作、临时观演票和当前道具布置阶段。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1614](../src/scenes/rpg/RpgGameHost.tsx#L1614)
2469. 后台通风口
   来源：[src/scenes/rpg/RpgGameHost.tsx:1621](../src/scenes/rpg/RpgGameHost.tsx#L1621)；[src/scenes/rpg/RpgItemUseGuidance.ts:249](../src/scenes/rpg/RpgItemUseGuidance.ts#L249)；[src/scenes/rpg/RpgItemUseGuidance.ts:252](../src/scenes/rpg/RpgItemUseGuidance.ts#L252)；[src/scenes/rpg/RpgItemUseGuidance.ts:254](../src/scenes/rpg/RpgItemUseGuidance.ts#L254)
2470. 灯光控制台
   来源：[src/scenes/rpg/RpgGameHost.tsx:1628](../src/scenes/rpg/RpgGameHost.tsx#L1628)；[src/scenes/rpg/RpgItemUseGuidance.ts:258](../src/scenes/rpg/RpgItemUseGuidance.ts#L258)；[src/scenes/rpg/RpgItemUseGuidance.ts:261](../src/scenes/rpg/RpgItemUseGuidance.ts#L261)；[src/scenes/rpg/RpgItemUseGuidance.ts:263](../src/scenes/rpg/RpgItemUseGuidance.ts#L263)
2471. 你被救起并送回寝室。先找到吹风机。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1688](../src/scenes/rpg/RpgGameHost.tsx#L1688)
2472. 浮排边钓鱼竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:1708](../src/scenes/rpg/RpgGameHost.tsx#L1708)
2473. fishingRod
   来源：[src/scenes/rpg/RpgGameHost.tsx:1708](../src/scenes/rpg/RpgGameHost.tsx#L1708)；[src/scenes/rpg/RpgGameHost.tsx:1727](../src/scenes/rpg/RpgGameHost.tsx#L1727)；[src/scenes/rpg/RpgGameHost.tsx:1736](../src/scenes/rpg/RpgGameHost.tsx#L1736)；[src/scenes/rpg/RpgGameHost.tsx:2602](../src/scenes/rpg/RpgGameHost.tsx#L2602)
2474. 钓鱼竿装饵框
   来源：[src/scenes/rpg/RpgGameHost.tsx:1711](../src/scenes/rpg/RpgGameHost.tsx#L1711)；[src/scenes/rpg/RpgItemUseGuidance.ts:300](../src/scenes/rpg/RpgItemUseGuidance.ts#L300)
2475. decoyPaper
   来源：[src/scenes/rpg/RpgGameHost.tsx:1711](../src/scenes/rpg/RpgGameHost.tsx#L1711)
2476. 已观察抛竿点
   来源：[src/scenes/rpg/RpgGameHost.tsx:1717](../src/scenes/rpg/RpgGameHost.tsx#L1717)
2477. 湖区道具点
   来源：[src/scenes/rpg/RpgGameHost.tsx:1722](../src/scenes/rpg/RpgGameHost.tsx#L1722)
2478. 工具装配框
   来源：[src/scenes/rpg/RpgGameHost.tsx:1727](../src/scenes/rpg/RpgGameHost.tsx#L1727)；[src/scenes/rpg/RpgItemUseGuidance.ts:293](../src/scenes/rpg/RpgItemUseGuidance.ts#L293)；[src/scenes/rpg/RpgItemUseGuidance.ts:319](../src/scenes/rpg/RpgItemUseGuidance.ts#L319)；[src/scenes/rpg/RpgItemUseGuidance.ts:322](../src/scenes/rpg/RpgItemUseGuidance.ts#L322)；[src/scenes/rpg/RpgItemUseGuidance.ts:324](../src/scenes/rpg/RpgItemUseGuidance.ts#L324)；[src/scenes/rpg/RpgItemUseGuidance.ts:325](../src/scenes/rpg/RpgItemUseGuidance.ts#L325)；[src/scenes/rpg/RpgItemUseGuidance.ts:363](../src/scenes/rpg/RpgItemUseGuidance.ts#L363)；[src/scenes/rpg/RpgItemUseGuidance.ts:366](../src/scenes/rpg/RpgItemUseGuidance.ts#L366)；[src/scenes/rpg/RpgItemUseGuidance.ts:367](../src/scenes/rpg/RpgItemUseGuidance.ts#L367)；[src/scenes/rpg/RpgItemUseGuidance.ts:368](../src/scenes/rpg/RpgItemUseGuidance.ts#L368)
2479. 黑天鹅投喂区
   来源：[src/scenes/rpg/RpgGameHost.tsx:1733](../src/scenes/rpg/RpgGameHost.tsx#L1733)；[src/scenes/rpg/RpgItemUseGuidance.ts:355](../src/scenes/rpg/RpgItemUseGuidance.ts#L355)；[src/scenes/rpg/RpgItemUseGuidance.ts:358](../src/scenes/rpg/RpgItemUseGuidance.ts#L358)
2480. 黑天鹅围栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:1736](../src/scenes/rpg/RpgGameHost.tsx#L1736)
2481. 纸条本体水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:1740](../src/scenes/rpg/RpgGameHost.tsx#L1740)；[src/scenes/rpg/RpgItemUseGuidance.ts:374](../src/scenes/rpg/RpgItemUseGuidance.ts#L374)；[src/scenes/rpg/RpgItemUseGuidance.ts:376](../src/scenes/rpg/RpgItemUseGuidance.ts#L376)；[src/scenes/rpg/RpgItemUseGuidance.ts:377](../src/scenes/rpg/RpgItemUseGuidance.ts#L377)
2482. 电子校园卡：{{actOneContent.studentName}} · {{actOneContent.studentId}}
   来源：[src/scenes/rpg/RpgGameHost.tsx:2241](../src/scenes/rpg/RpgGameHost.tsx#L2241)
2483. 电子校园卡：身份信息尚未读取
   来源：[src/scenes/rpg/RpgGameHost.tsx:2242](../src/scenes/rpg/RpgGameHost.tsx#L2242)
2484. 手柄已连接：WASD 或方向键移动，空格键交互。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2251](../src/scenes/rpg/RpgGameHost.tsx#L2251)
2485. 手柄有电，角色还没有姓名。去部门黄页读取校园卡。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2252](../src/scenes/rpg/RpgGameHost.tsx#L2252)
2486. 手柄已连接，浙大体艺还没有开始课外锻炼。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2253](../src/scenes/rpg/RpgGameHost.tsx#L2253)
2487. 道具栏里没有手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2254](../src/scenes/rpg/RpgGameHost.tsx#L2254)
2488. 当前任务还没有开放手柄控制。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2255](../src/scenes/rpg/RpgGameHost.tsx#L2255)
2489. 使用游戏手柄
   来源：[src/scenes/rpg/RpgGameHost.tsx:2526](../src/scenes/rpg/RpgGameHost.tsx#L2526)
2490. 单击连接手柄，双击查看完整详情
   来源：[src/scenes/rpg/RpgGameHost.tsx:2527](../src/scenes/rpg/RpgGameHost.tsx#L2527)
2491. gamepad
   来源：[src/scenes/rpg/RpgGameHost.tsx:2531](../src/scenes/rpg/RpgGameHost.tsx#L2531)
2492. 手柄
   来源：[src/scenes/rpg/RpgGameHost.tsx:2532](../src/scenes/rpg/RpgGameHost.tsx#L2532)
2493. 左收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2590](../src/scenes/rpg/RpgGameHost.tsx#L2590)
2494. S 提竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:2596](../src/scenes/rpg/RpgGameHost.tsx#L2596)
2495. 提竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:2603](../src/scenes/rpg/RpgGameHost.tsx#L2603)
2496. D 右收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2609](../src/scenes/rpg/RpgGameHost.tsx#L2609)
2497. warningSignPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2615](../src/scenes/rpg/RpgGameHost.tsx#L2615)；[src/scenes/rpg/RpgGameHost.tsx:2646](../src/scenes/rpg/RpgGameHost.tsx#L2646)
2498. 右收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2616](../src/scenes/rpg/RpgGameHost.tsx#L2616)
2499. 皮划艇划桨手势和交互按钮
   来源：[src/scenes/rpg/RpgGameHost.tsx:2621](../src/scenes/rpg/RpgGameHost.tsx#L2621)
2500. 左桨，上划前进，下划后退，轻触默认前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2625](../src/scenes/rpg/RpgGameHost.tsx#L2625)
2501. willowBranchPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2632](../src/scenes/rpg/RpgGameHost.tsx#L2632)
2502. 左桨
   来源：[src/scenes/rpg/RpgGameHost.tsx:2633](../src/scenes/rpg/RpgGameHost.tsx#L2633)
2503. ↑ 前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2634](../src/scenes/rpg/RpgGameHost.tsx#L2634)；[src/scenes/rpg/RpgGameHost.tsx:2648](../src/scenes/rpg/RpgGameHost.tsx#L2648)
2504. ↑前进 · ↓后退
   来源：[src/scenes/rpg/RpgGameHost.tsx:2634](../src/scenes/rpg/RpgGameHost.tsx#L2634)；[src/scenes/rpg/RpgGameHost.tsx:2648](../src/scenes/rpg/RpgGameHost.tsx#L2648)
2505. ↓ 后退
   来源：[src/scenes/rpg/RpgGameHost.tsx:2634](../src/scenes/rpg/RpgGameHost.tsx#L2634)；[src/scenes/rpg/RpgGameHost.tsx:2648](../src/scenes/rpg/RpgGameHost.tsx#L2648)
2506. 右桨，上划前进，下划后退，轻触默认前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2639](../src/scenes/rpg/RpgGameHost.tsx#L2639)
2507. 右桨
   来源：[src/scenes/rpg/RpgGameHost.tsx:2647](../src/scenes/rpg/RpgGameHost.tsx#L2647)
2508. 交互（键盘为空格键）
   来源：[src/scenes/rpg/RpgGameHost.tsx:2666](../src/scenes/rpg/RpgGameHost.tsx#L2666)
2509. 请将设备横过来继续 RPG
   来源：[src/scenes/rpg/RpgGameHost.tsx:2675](../src/scenes/rpg/RpgGameHost.tsx#L2675)
2510. 点击闸机小屏，核对入馆与到达时间
   来源：[src/scenes/rpg/RpgGameHost.tsx:2720](../src/scenes/rpg/RpgGameHost.tsx#L2720)
2511. 前往二层南区寻找 022
   来源：[src/scenes/rpg/RpgGameHost.tsx:2720](../src/scenes/rpg/RpgGameHost.tsx#L2720)
2512. 调查纸条提到的公开记录
   来源：[src/scenes/rpg/RpgGameHost.tsx:2721](../src/scenes/rpg/RpgGameHost.tsx#L2721)
2513. 检查书包旁边的占座纸条
   来源：[src/scenes/rpg/RpgGameHost.tsx:2721](../src/scenes/rpg/RpgGameHost.tsx#L2721)
2514. 用占座纸条查找公开记录
   来源：[src/scenes/rpg/RpgGameHost.tsx:2723](../src/scenes/rpg/RpgGameHost.tsx#L2723)
2515. 并行收集四项公示材料（{{evidenceReadyCount}}/4）
   来源：[src/scenes/rpg/RpgGameHost.tsx:2731](../src/scenes/rpg/RpgGameHost.tsx#L2731)
2516. 把已取得材料上传到 CC98
   来源：[src/scenes/rpg/RpgGameHost.tsx:2732](../src/scenes/rpg/RpgGameHost.tsx#L2732)
2517. 确认系统说明，开始筛选有效回复
   来源：[src/scenes/rpg/RpgGameHost.tsx:2734](../src/scenes/rpg/RpgGameHost.tsx#L2734)
2518. 让证据公示进入 CC98 十大
   来源：[src/scenes/rpg/RpgGameHost.tsx:2735](../src/scenes/rpg/RpgGameHost.tsx#L2735)
2519. 完成图书馆座位恢复申请
   来源：[src/scenes/rpg/RpgGameHost.tsx:2736](../src/scenes/rpg/RpgGameHost.tsx#L2736)
2520. 对 022 书包使用离座清退 PASS
   来源：[src/scenes/rpg/RpgGameHost.tsx:2737](../src/scenes/rpg/RpgGameHost.tsx#L2737)
2521. 坐到已经恢复的 022
   来源：[src/scenes/rpg/RpgGameHost.tsx:2738](../src/scenes/rpg/RpgGameHost.tsx#L2738)
2522. 与 022 继续对话
   来源：[src/scenes/rpg/RpgGameHost.tsx:2739](../src/scenes/rpg/RpgGameHost.tsx#L2739)
2523. 追上逃跑的记录纸条
   来源：[src/scenes/rpg/RpgGameHost.tsx:2740](../src/scenes/rpg/RpgGameHost.tsx#L2740)
2524. 前往基础图书馆，寻找系统的朋友
   来源：[src/scenes/rpg/RpgGameHost.tsx:2741](../src/scenes/rpg/RpgGameHost.tsx#L2741)
2525. 说明
   来源：[src/scenes/rpg/RpgGameHost.tsx:2750](../src/scenes/rpg/RpgGameHost.tsx#L2750)
2526. 调查
   来源：[src/scenes/rpg/RpgGameHost.tsx:2764](../src/scenes/rpg/RpgGameHost.tsx#L2764)
2527. 公告栏前的签到记录纸条
   来源：[src/scenes/rpg/RpgInteractionContract.ts:515](../src/scenes/rpg/RpgInteractionContract.ts#L515)
2528. 一楼旧钟
   来源：[src/scenes/rpg/RpgInteractionContract.ts:533](../src/scenes/rpg/RpgInteractionContract.ts#L533)
2529. 与一楼前台值班助理交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:615](../src/scenes/rpg/RpgInteractionContract.ts#L615)
2530. 与二楼电梯口值班安全员交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:630](../src/scenes/rpg/RpgInteractionContract.ts#L630)
2531. 与三楼参照教室教师交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:640](../src/scenes/rpg/RpgInteractionContract.ts#L640)
2532. 查看苏步青生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:650](../src/scenes/rpg/RpgInteractionContract.ts#L650)
2533. 查看竺可桢生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:660](../src/scenes/rpg/RpgInteractionContract.ts#L660)
2534. 查看路甬祥生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:670](../src/scenes/rpg/RpgInteractionContract.ts#L670)
2535. 查看陈建功生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:680](../src/scenes/rpg/RpgInteractionContract.ts#L680)
2536. 查看谈家桢生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:690](../src/scenes/rpg/RpgInteractionContract.ts#L690)
2537. 查看程开甲生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:700](../src/scenes/rpg/RpgInteractionContract.ts#L700)
2538. 观察 104 黑板擦痕
   来源：[src/scenes/rpg/RpgInteractionContract.ts:710](../src/scenes/rpg/RpgInteractionContract.ts#L710)
2539. 检查 105 讲台回放
   来源：[src/scenes/rpg/RpgInteractionContract.ts:726](../src/scenes/rpg/RpgInteractionContract.ts#L726)
2540. 三楼晨间教室布置参照
   来源：[src/scenes/rpg/RpgInteractionContract.ts:742](../src/scenes/rpg/RpgInteractionContract.ts#L742)
2541. 204 教室残影组
   来源：[src/scenes/rpg/RpgInteractionContract.ts:755](../src/scenes/rpg/RpgInteractionContract.ts#L755)
2542. mismatched\_nonce
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1326](../src/scenes/rpg/RpgInteractionContract.ts#L1326)
2543. wrong\_scene
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1329](../src/scenes/rpg/RpgInteractionContract.ts#L1329)
2544. wrong\_bounds
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1335](../src/scenes/rpg/RpgInteractionContract.ts#L1335)
2545. stale\_projection
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1340](../src/scenes/rpg/RpgInteractionContract.ts#L1340)
2546. invalid\_player
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1349](../src/scenes/rpg/RpgInteractionContract.ts#L1349)
2547. spatial\_claim\_mismatch
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1365](../src/scenes/rpg/RpgInteractionContract.ts#L1365)
2548. 需要{{contract.label}}：{{contract.shortHint}}
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1607](../src/scenes/rpg/RpgInteractionContract.ts#L1607)
2549. 目标
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:112](../src/scenes/rpg/RpgInventoryDock.tsx#L112)
2550. 目标命中，使用成功
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:118](../src/scenes/rpg/RpgInventoryDock.tsx#L118)
2551. {{targetLabel}}已接收该道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:119](../src/scenes/rpg/RpgInventoryDock.tsx#L119)
2552. 目标命中，人物距离不足
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:126](../src/scenes/rpg/RpgInventoryDock.tsx#L126)
2553. 靠近「{{targetLabel}}」后再拖入道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:127](../src/scenes/rpg/RpgInventoryDock.tsx#L127)
2554. 目标命中，道具不匹配
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:134](../src/scenes/rpg/RpgInventoryDock.tsx#L134)
2555. 「{{targetLabel}}」需要另一类道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:135](../src/scenes/rpg/RpgInventoryDock.tsx#L135)
2556. 没有放进目标范围
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:142](../src/scenes/rpg/RpgInventoryDock.tsx#L142)
2557. 请把道具放到画面中对应的真实物体上。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:143](../src/scenes/rpg/RpgInventoryDock.tsx#L143)
2558. 当前模式不能执行该动作
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:150](../src/scenes/rpg/RpgInventoryDock.tsx#L150)
2559. 切回浅色操作后，再把道具拖入目标范围。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:151](../src/scenes/rpg/RpgInventoryDock.tsx#L151)
2560. 目标位置尚未记录
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:158](../src/scenes/rpg/RpgInventoryDock.tsx#L158)
2561. 深色观察可以补充目标坐标；浅色操作仍可直接作用于画面中清晰可见的实体目标。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:159](../src/scenes/rpg/RpgInventoryDock.tsx#L159)
2562. 纸张无法直接钓取
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:166](../src/scenes/rpg/RpgInventoryDock.tsx#L166)
2563. 钓钩无法固定纸张。检查已获得的工具，补充适合金属夹具的连接方式。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:167](../src/scenes/rpg/RpgInventoryDock.tsx#L167)
2564. 当前步骤已经完成
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:174](../src/scenes/rpg/RpgInventoryDock.tsx#L174)
2565. 无需重复使用该道具，继续查看当前任务。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:175](../src/scenes/rpg/RpgInventoryDock.tsx#L175)
2566. 此处无需拖动
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:182](../src/scenes/rpg/RpgInventoryDock.tsx#L182)
2567. 靠近对应位置或完成页面操作时会自动核验。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:183](../src/scenes/rpg/RpgInventoryDock.tsx#L183)
2568. 本场景没有使用点
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:190](../src/scenes/rpg/RpgInventoryDock.tsx#L190)；[src/scenes/rpg/RpgItemUseGuidance.ts:63](../src/scenes/rpg/RpgItemUseGuidance.ts#L63)
2569. 保留该道具，跟随当前任务前往对应页面或场景。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:191](../src/scenes/rpg/RpgInventoryDock.tsx#L191)；[src/scenes/rpg/RpgItemUseGuidance.ts:64](../src/scenes/rpg/RpgItemUseGuidance.ts#L64)
2570. 当前使用条件未满足
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:197](../src/scenes/rpg/RpgInventoryDock.tsx#L197)；[src/scenes/rpg/RpgItemUseGuidance.ts:50](../src/scenes/rpg/RpgItemUseGuidance.ts#L50)
2571. 「{{targetLabel}}」当前还不能接收该道具。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:198](../src/scenes/rpg/RpgInventoryDock.tsx#L198)
2572. consumed
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:227](../src/scenes/rpg/RpgInventoryDock.tsx#L227)
2573. input\_blocked
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:241](../src/scenes/rpg/RpgInventoryDock.tsx#L241)
2574. 道具没有进入游戏画布，请拖到场景中的对应物体。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:388](../src/scenes/rpg/RpgInventoryDock.tsx#L388)
2575. RPG 道具栏
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:408](../src/scenes/rpg/RpgInventoryDock.tsx#L408)
2576. 道具
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:413](../src/scenes/rpg/RpgInventoryDock.tsx#L413)
2577. 靠近目标 · 拖到目标上
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:414](../src/scenes/rpg/RpgInventoryDock.tsx#L414)
2578. 目标：{{guidance.targetLabel}}。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:419](../src/scenes/rpg/RpgInventoryDock.tsx#L419)
2579. 拖动{{ITEM\_META\[itemId\].name}}，{{isPaperItem(itemId) ? "单击" : "双击"}}查看详情
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:433](../src/scenes/rpg/RpgInventoryDock.tsx#L433)
2580. {{ITEM\_META\[itemId\].name}}：{{ITEM\_META\[itemId\].desc}}
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:436](../src/scenes/rpg/RpgInventoryDock.tsx#L436)
2581. 校园卡在手机应用和地图入口中读取
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:13](../src/scenes/rpg/RpgItemUseGuidance.ts#L13)
2582. 前往 CC98 搜索栏提交占座纸条
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:14](../src/scenes/rpg/RpgItemUseGuidance.ts#L14)
2583. 前往 CC98 证据上传区提交旧版规定
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:15](../src/scenes/rpg/RpgItemUseGuidance.ts#L15)
2584. 前往 CC98 或恢复申请页面提交证明
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:16](../src/scenes/rpg/RpgItemUseGuidance.ts#L16)；[src/scenes/rpg/RpgItemUseGuidance.ts:18](../src/scenes/rpg/RpgItemUseGuidance.ts#L18)
2585. 前往 CC98 或恢复申请页面提交凭据
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:17](../src/scenes/rpg/RpgItemUseGuidance.ts#L17)
2586. 到食堂左下角混合台倒入玻璃杯
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:19](../src/scenes/rpg/RpgItemUseGuidance.ts#L19)；[src/scenes/rpg/RpgItemUseGuidance.ts:20](../src/scenes/rpg/RpgItemUseGuidance.ts#L20)；[src/scenes/rpg/RpgItemUseGuidance.ts:21](../src/scenes/rpg/RpgItemUseGuidance.ts#L21)
2587. 在食堂地图中拖到自己身上喝掉
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:22](../src/scenes/rpg/RpgItemUseGuidance.ts#L22)
2588. 到食堂第五个打饭窗口上方的宣传灯箱空杯位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:23](../src/scenes/rpg/RpgItemUseGuidance.ts#L23)
2589. 靠近取餐窗口后按空格使用；纸包鸡需在深色第三窗口交票
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:24](../src/scenes/rpg/RpgItemUseGuidance.ts#L24)
2590. 食物彩蛋，没有剧情用途
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:25](../src/scenes/rpg/RpgItemUseGuidance.ts#L25)；[src/scenes/rpg/RpgItemUseGuidance.ts:26](../src/scenes/rpg/RpgItemUseGuidance.ts#L26)；[src/scenes/rpg/RpgItemUseGuidance.ts:27](../src/scenes/rpg/RpgItemUseGuidance.ts#L27)；[src/scenes/rpg/RpgItemUseGuidance.ts:28](../src/scenes/rpg/RpgItemUseGuidance.ts#L28)
2591. 与另一半临时票合成，无需拖到场景
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:29](../src/scenes/rpg/RpgItemUseGuidance.ts#L29)；[src/scenes/rpg/RpgItemUseGuidance.ts:30](../src/scenes/rpg/RpgItemUseGuidance.ts#L30)
2592. 到剧院灯光控制台打开节目单排序
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:31](../src/scenes/rpg/RpgItemUseGuidance.ts#L31)；[src/scenes/rpg/RpgItemUseGuidance.ts:32](../src/scenes/rpg/RpgItemUseGuidance.ts#L32)；[src/scenes/rpg/RpgItemUseGuidance.ts:33](../src/scenes/rpg/RpgItemUseGuidance.ts#L33)
2593. 前往 CC98 或馆藏检索提交湿节目单
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:34](../src/scenes/rpg/RpgItemUseGuidance.ts#L34)
2594. 前往校园地图搜索栏提交地点关键词
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:35](../src/scenes/rpg/RpgItemUseGuidance.ts#L35)；[src/scenes/rpg/RpgItemUseGuidance.ts:36](../src/scenes/rpg/RpgItemUseGuidance.ts#L36)；[src/scenes/rpg/RpgItemUseGuidance.ts:37](../src/scenes/rpg/RpgItemUseGuidance.ts#L37)
2595. 坐标会在启真湖布置假纸条时自动核验
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:38](../src/scenes/rpg/RpgItemUseGuidance.ts#L38)
2596. 靠近目标，把道具拖到物体本身后松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:41](../src/scenes/rpg/RpgItemUseGuidance.ts#L41)
2597. ready
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:42](../src/scenes/rpg/RpgItemUseGuidance.ts#L42)
2598. 当前可以使用
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:43](../src/scenes/rpg/RpgItemUseGuidance.ts#L43)
2599. passive
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:56](../src/scenes/rpg/RpgItemUseGuidance.ts#L56)
2600. 无需拖动
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:57](../src/scenes/rpg/RpgItemUseGuidance.ts#L57)
2601. elsewhere
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:62](../src/scenes/rpg/RpgItemUseGuidance.ts#L62)
2602. 旧钟时针插槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:94](../src/scenes/rpg/RpgItemUseGuidance.ts#L94)
2603. 旧钟定位盘插槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:99](../src/scenes/rpg/RpgItemUseGuidance.ts#L99)
2604. 清洁车车轮
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:105](../src/scenes/rpg/RpgItemUseGuidance.ts#L105)；[src/scenes/rpg/RpgItemUseGuidance.ts:114](../src/scenes/rpg/RpgItemUseGuidance.ts#L114)
2605. 先靠近保洁车检查卡住的车轮。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:105](../src/scenes/rpg/RpgItemUseGuidance.ts#L105)
2606. 清洁车轮罩
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:108](../src/scenes/rpg/RpgItemUseGuidance.ts#L108)
2607. 先把润滑油拖到清洁车车轮，修好后仍会保留半瓶。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:114](../src/scenes/rpg/RpgItemUseGuidance.ts#L114)
2608. 把剩下的半瓶润滑油拖到旧钟齿轮。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:117](../src/scenes/rpg/RpgItemUseGuidance.ts#L117)
2609. 旧钟齿轮
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:117](../src/scenes/rpg/RpgItemUseGuidance.ts#L117)
2610. 润滑油的剧情用途已经完成。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:119](../src/scenes/rpg/RpgItemUseGuidance.ts#L119)
2611. 旧钟分针端点
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:123](../src/scenes/rpg/RpgItemUseGuidance.ts#L123)
2612. 手柄已经连接并等待方向输入校验。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:129](../src/scenes/rpg/RpgItemUseGuidance.ts#L129)
2613. 先在部门黄页完成角色命名。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:130](../src/scenes/rpg/RpgItemUseGuidance.ts#L130)
2614. 先在浙大体艺开始课外锻炼。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:131](../src/scenes/rpg/RpgItemUseGuidance.ts#L131)
2615. 先在 CC98 完成手柄购买。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:132](../src/scenes/rpg/RpgItemUseGuidance.ts#L132)
2616. 把手柄拖到角色身体范围内，并在人物轮廓内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:133](../src/scenes/rpg/RpgItemUseGuidance.ts#L133)
2617. 文学书架 755 段
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:142](../src/scenes/rpg/RpgItemUseGuidance.ts#L142)；[src/scenes/rpg/RpgItemUseGuidance.ts:143](../src/scenes/rpg/RpgItemUseGuidance.ts#L143)
2618. 先完成馆藏检索并取得索书号 755。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:143](../src/scenes/rpg/RpgItemUseGuidance.ts#L143)
2619. 前台正在人工核验并盖章，等待流程完成。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:146](../src/scenes/rpg/RpgItemUseGuidance.ts#L146)
2620. 靠近前台，把物品识别报告拖到工作人员与盖章台之间。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:151](../src/scenes/rpg/RpgItemUseGuidance.ts#L151)
2621. 前台工作人员
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:151](../src/scenes/rpg/RpgItemUseGuidance.ts#L151)；[src/scenes/rpg/RpgItemUseGuidance.ts:152](../src/scenes/rpg/RpgItemUseGuidance.ts#L152)
2622. 先在照片页面生成物品识别报告。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:152](../src/scenes/rpg/RpgItemUseGuidance.ts#L152)
2623. 022 座位凭据已经取出，右移箭头已完成最后用途。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:157](../src/scenes/rpg/RpgItemUseGuidance.ts#L157)
2624. 022 占座书包
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:163](../src/scenes/rpg/RpgItemUseGuidance.ts#L163)；[src/scenes/rpg/RpgItemUseGuidance.ts:164](../src/scenes/rpg/RpgItemUseGuidance.ts#L164)
2625. 先完成公开公示和三项恢复材料，取得清退 PASS。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:164](../src/scenes/rpg/RpgItemUseGuidance.ts#L164)
2626. 1、2、3号取餐窗口验票槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:170](../src/scenes/rpg/RpgItemUseGuidance.ts#L170)
2627. 取餐号只在取餐阶段使用。先完成当前食堂任务。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:170](../src/scenes/rpg/RpgItemUseGuidance.ts#L170)
2628. 不需要拖拽或站位。浅色操作可在对应窗口交票；深色观察可补充查看窗口残影。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:172](../src/scenes/rpg/RpgItemUseGuidance.ts#L172)
2629. 取餐窗口
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:172](../src/scenes/rpg/RpgItemUseGuidance.ts#L172)
2630. 靠近混合台打开调配窗口，再点击对应饮料倒入大玻璃杯。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:185](../src/scenes/rpg/RpgItemUseGuidance.ts#L185)
2631. 左下角混合台
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:185](../src/scenes/rpg/RpgItemUseGuidance.ts#L185)
2632. 第五个打饭窗口下方的宣传板空杯位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:192](../src/scenes/rpg/RpgItemUseGuidance.ts#L192)
2633. 先靠近宣传板，再把今日新品气泡水拖进发光的空杯位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:192](../src/scenes/rpg/RpgItemUseGuidance.ts#L192)
2634. 把难喝饮料拖到人物身上可以喝掉，但不会推进剧情。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:195](../src/scenes/rpg/RpgItemUseGuidance.ts#L195)
2635. 玩家自己
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:195](../src/scenes/rpg/RpgItemUseGuidance.ts#L195)
2636. 车锁已经擦净，2 元现金可以用于付款。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:201](../src/scenes/rpg/RpgItemUseGuidance.ts#L201)
2637. 切回浅色模式后再清洁车锁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:202](../src/scenes/rpg/RpgItemUseGuidance.ts#L202)
2638. 先用纸巾清洁车锁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:206](../src/scenes/rpg/RpgItemUseGuidance.ts#L206)
2639. 切回浅色模式后付款。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:207](../src/scenes/rpg/RpgItemUseGuidance.ts#L207)
2640. 现金余额不足 2 元。回食堂完成收餐盘，领取 2 元和油渍纸巾。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:208](../src/scenes/rpg/RpgItemUseGuidance.ts#L208)
2641. 把 2 元现金拖到共享单车范围内，并在车身上松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:209](../src/scenes/rpg/RpgItemUseGuidance.ts#L209)
2642. 海报玻璃已经擦净。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:216](../src/scenes/rpg/RpgItemUseGuidance.ts#L216)
2643. 擦拭海报只在剧院入口取票阶段开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:217](../src/scenes/rpg/RpgItemUseGuidance.ts#L217)
2644. 切回浅色模式后擦拭海报玻璃。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:218](../src/scenes/rpg/RpgItemUseGuidance.ts#L218)
2645. 从海报右侧靠近，把油渍纸巾拖到玻璃污渍上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:219](../src/scenes/rpg/RpgItemUseGuidance.ts#L219)
2646. 入口海报玻璃
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:219](../src/scenes/rpg/RpgItemUseGuidance.ts#L219)
2647. 深色模式只读取异常；切回浅色操作后再把票拖入读票器。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:224](../src/scenes/rpg/RpgItemUseGuidance.ts#L224)
2648. 靠近读票器，把票拖到右侧验票槽内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:228](../src/scenes/rpg/RpgItemUseGuidance.ts#L228)
2649. 票据扫描已经完成，临时观演票已从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:232](../src/scenes/rpg/RpgItemUseGuidance.ts#L232)
2650. 深色模式可查看道具箱残影；切回浅色模式后扫描票据。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:234](../src/scenes/rpg/RpgItemUseGuidance.ts#L234)
2651. 靠近道具箱旁的扫描器，把票拖到扫描口内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:238](../src/scenes/rpg/RpgItemUseGuidance.ts#L238)
2652. 入场核验已完成。票会在后台道具箱阶段再次使用，先完成当前节目单任务。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:242](../src/scenes/rpg/RpgItemUseGuidance.ts#L242)
2653. 当前流程不需要再次拖动临时观演票。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:244](../src/scenes/rpg/RpgItemUseGuidance.ts#L244)
2654. 后台纸屑已经显影，荧光粉刷已从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:247](../src/scenes/rpg/RpgItemUseGuidance.ts#L247)
2655. 先在后台完成票据扫描并打开道具箱，取得荧光粉刷。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:249](../src/scenes/rpg/RpgItemUseGuidance.ts#L249)
2656. 切回浅色操作后，把荧光粉刷拖入通风口。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:252](../src/scenes/rpg/RpgItemUseGuidance.ts#L252)
2657. 靠近通风口，把荧光粉刷拖到栅格上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:254](../src/scenes/rpg/RpgItemUseGuidance.ts#L254)
2658. 先完成后台纸屑显影，灯光控制台随后开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:258](../src/scenes/rpg/RpgItemUseGuidance.ts#L258)
2659. 深色模式只观察追光残影；切回浅色操作后启动灯光控制台。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:261](../src/scenes/rpg/RpgItemUseGuidance.ts#L261)
2660. 从下方靠近控制台，把追光灯遥控器拖到控制面板上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:263](../src/scenes/rpg/RpgItemUseGuidance.ts#L263)
2661. 靠近灯光控制台打开节目单排序，无需把节目单拖到控制台。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:266](../src/scenes/rpg/RpgItemUseGuidance.ts#L266)
2662. 深色观察只记录坐标。切回浅色操作后使用道具。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:274](../src/scenes/rpg/RpgItemUseGuidance.ts#L274)
2663. 假纸条已经固定到鱼钩上并从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:277](../src/scenes/rpg/RpgItemUseGuidance.ts#L277)
2664. 先在大湖浮排边找到钓鱼竿。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:279](../src/scenes/rpg/RpgItemUseGuidance.ts#L279)
2665. 纸条倒影装饵框
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:279](../src/scenes/rpg/RpgItemUseGuidance.ts#L279)；[src/scenes/rpg/RpgItemUseGuidance.ts:282](../src/scenes/rpg/RpgItemUseGuidance.ts#L282)；[src/scenes/rpg/RpgItemUseGuidance.ts:284](../src/scenes/rpg/RpgItemUseGuidance.ts#L284)
2666. 先划回大湖，再寻找纸条倒影装饵框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:282](../src/scenes/rpg/RpgItemUseGuidance.ts#L282)
2667. 把船划到纸条倒影附近，再把假纸条拖到对应水纹。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:285](../src/scenes/rpg/RpgItemUseGuidance.ts#L285)
2668. 纸条倒影水纹
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:285](../src/scenes/rpg/RpgItemUseGuidance.ts#L285)
2669. 船头磁吸组合位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:291](../src/scenes/rpg/RpgItemUseGuidance.ts#L291)
2670. 先划到黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:291](../src/scenes/rpg/RpgItemUseGuidance.ts#L291)
2671. 船头工具区
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:294](../src/scenes/rpg/RpgItemUseGuidance.ts#L294)
2672. 让船头对准工具区，把钓鱼竿拖到天鹅磁扣旁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:294](../src/scenes/rpg/RpgItemUseGuidance.ts#L294)
2673. 当前抛竿点位于大湖，先划回大湖。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:297](../src/scenes/rpg/RpgItemUseGuidance.ts#L297)
2674. 可用抛竿点
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:297](../src/scenes/rpg/RpgItemUseGuidance.ts#L297)；[src/scenes/rpg/RpgItemUseGuidance.ts:302](../src/scenes/rpg/RpgItemUseGuidance.ts#L302)；[src/scenes/rpg/RpgItemUseGuidance.ts:303](../src/scenes/rpg/RpgItemUseGuidance.ts#L303)
2675. 先把假纸条拖到钓鱼竿装饵框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:300](../src/scenes/rpg/RpgItemUseGuidance.ts#L300)
2676. 把船划到目标水纹附近后抛竿。深色观察可补充记录位置，直接钓纸条会显示失败原因。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:303](../src/scenes/rpg/RpgItemUseGuidance.ts#L303)
2677. 码头储物柜已经打开。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:308](../src/scenes/rpg/RpgItemUseGuidance.ts#L308)
2678. 返回小码头，储物柜锁孔只在码头区域开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:310](../src/scenes/rpg/RpgItemUseGuidance.ts#L310)
2679. 码头储物柜
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:310](../src/scenes/rpg/RpgItemUseGuidance.ts#L310)；[src/scenes/rpg/RpgItemUseGuidance.ts:311](../src/scenes/rpg/RpgItemUseGuidance.ts#L311)；[src/scenes/rpg/RpgItemUseGuidance.ts:312](../src/scenes/rpg/RpgItemUseGuidance.ts#L312)
2680. 返回小码头，靠近柜门，把钥匙拖到锁孔。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:312](../src/scenes/rpg/RpgItemUseGuidance.ts#L312)
2681. 两件道具已组合为临时抄网。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:316](../src/scenes/rpg/RpgItemUseGuidance.ts#L316)
2682. 先取得另一个组合部件。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:319](../src/scenes/rpg/RpgItemUseGuidance.ts#L319)
2683. 回到大湖的浮标组合位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:322](../src/scenes/rpg/RpgItemUseGuidance.ts#L322)
2684. 把尼龙绳或破损网框拖入装配框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:325](../src/scenes/rpg/RpgItemUseGuidance.ts#L325)
2685. 密封饲料盒已经取回。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:330](../src/scenes/rpg/RpgItemUseGuidance.ts#L330)
2686. 浮排系绳下方
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:332](../src/scenes/rpg/RpgItemUseGuidance.ts#L332)；[src/scenes/rpg/RpgItemUseGuidance.ts:333](../src/scenes/rpg/RpgItemUseGuidance.ts#L333)；[src/scenes/rpg/RpgItemUseGuidance.ts:334](../src/scenes/rpg/RpgItemUseGuidance.ts#L334)
2687. 进入浮排直河道，再靠近浮排系绳。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:332](../src/scenes/rpg/RpgItemUseGuidance.ts#L332)
2688. 进入直河道，让船头对准浮排下方，把抄网拖到密封饲料盒上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:334](../src/scenes/rpg/RpgItemUseGuidance.ts#L334)
2689. 饲料盒已经打开。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:339](../src/scenes/rpg/RpgItemUseGuidance.ts#L339)
2690. 返回浮排直河道，开盒位在浮排上缘。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:341](../src/scenes/rpg/RpgItemUseGuidance.ts#L341)
2691. 浮排开盒位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:341](../src/scenes/rpg/RpgItemUseGuidance.ts#L341)；[src/scenes/rpg/RpgItemUseGuidance.ts:342](../src/scenes/rpg/RpgItemUseGuidance.ts#L342)
2692. 浮排硬边
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:343](../src/scenes/rpg/RpgItemUseGuidance.ts#L343)
2693. 让船头对准浮排硬边，把密封饲料盒拖到边缘上开启。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:343](../src/scenes/rpg/RpgItemUseGuidance.ts#L343)
2694. 回到大湖的鱼群水纹位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:348](../src/scenes/rpg/RpgItemUseGuidance.ts#L348)
2695. 鱼群水纹
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:348](../src/scenes/rpg/RpgItemUseGuidance.ts#L348)；[src/scenes/rpg/RpgItemUseGuidance.ts:350](../src/scenes/rpg/RpgItemUseGuidance.ts#L350)；[src/scenes/rpg/RpgItemUseGuidance.ts:351](../src/scenes/rpg/RpgItemUseGuidance.ts#L351)
2696. 把饲料颗粒拖入鱼群水纹；深色观察可补充记录位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:351](../src/scenes/rpg/RpgItemUseGuidance.ts#L351)
2697. 黑天鹅
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:357](../src/scenes/rpg/RpgItemUseGuidance.ts#L357)
2698. 让船头对准黑天鹅，把小鲤鱼拖到天鹅面前。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:357](../src/scenes/rpg/RpgItemUseGuidance.ts#L357)
2699. 划到黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:358](../src/scenes/rpg/RpgItemUseGuidance.ts#L358)
2700. 划到黑天鹅围栏区的船头装配位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:363](../src/scenes/rpg/RpgItemUseGuidance.ts#L363)
2701. 把磁性扣拖到钓鱼竿所在的装配框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:367](../src/scenes/rpg/RpgItemUseGuidance.ts#L367)
2702. 钓鱼竿当前不在道具栏。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:368](../src/scenes/rpg/RpgItemUseGuidance.ts#L368)
2703. 纸条已经被固定，进入返航追逐。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:372](../src/scenes/rpg/RpgItemUseGuidance.ts#L372)
2704. 纸条本体水纹位于黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:374](../src/scenes/rpg/RpgItemUseGuidance.ts#L374)
2705. 把磁性钓鱼竿拖入纸条本体水纹；深色观察可补充记录位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:377](../src/scenes/rpg/RpgItemUseGuidance.ts#L377)
2706. 当前{{current.label}}。点击切换到{{next.label}}
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:25](../src/scenes/rpg/RpgRealityModeToggle.tsx#L25)
2707. {{current.shortHint}} 点击切换到{{next.label}}。
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:26](../src/scenes/rpg/RpgRealityModeToggle.tsx#L26)
2708. 当前模式
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:34](../src/scenes/rpg/RpgRealityModeToggle.tsx#L34)
2709. 切换：
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:36](../src/scenes/rpg/RpgRealityModeToggle.tsx#L36)
2710. 紫云碧峰
   来源：[src/scenes/rpg/ZijingangCampusLayout.ts:54](../src/scenes/rpg/ZijingangCampusLayout.ts#L54)
2711. 东区大食堂
   来源：[src/scenes/rpg/ZijingangCampusLayout.ts:73](../src/scenes/rpg/ZijingangCampusLayout.ts#L73)

