# 《7:55》游戏文本总表

> 本文件由 `npm run text:export` 从当前 `src/` 自动生成。请修改源文件后重新导出，不要只修改本文件。

- 文本条目：7140
- 来源文件：147
- 收录范围：剧情对白、字幕、任务说明、交互提示、按钮、页面标题、帖子、物品说明、失败反馈与玩家可见状态文案。
- 排除范围：开发者面板、测试断言、内部 ID、CSS 类名、资源路径、存档字段和运行时调试信息。
- 去重规则：同一章节内完全相同的文本合并为一条，全部源码位置仍保留。
- 模板规则：动态表达式显示为 `{{表达式}}`。

## 章节索引

| 章节 | 文本条目 |
| --- | ---: |
| [第一章](#第一章) | 463 |
| [第二章](#第二章) | 409 |
| [第三章](#第三章) | 1194 |
| [3.5章过渡](#35章过渡) | 298 |
| [第四章](#第四章) | 1770 |
| [结局](#结局) | 103 |
| [跨章节与共用系统](#跨章节与共用系统) | 2903 |

## 第一章

1. 已找到的签到数字：{{digitSlots .map((digit, index) =&gt; \`第${index + 1}位${digit ?? "未找到"}\`) .join("，")}}
   来源：[src/components/QuestClueStrip.tsx:114](../src/components/QuestClueStrip.tsx#L114)
2. 返回任务现场
   来源：[src/components/QuestClueStrip.tsx:121](../src/components/QuestClueStrip.tsx#L121)
3. 前往相关界面
   来源：[src/components/QuestClueStrip.tsx:121](../src/components/QuestClueStrip.tsx#L121)
4. 查看信息
   来源：[src/core/QuestModel.ts:58](../src/core/QuestModel.ts#L58)
5. 找签到码（{{digitCount}}/4）
   来源：[src/core/QuestModel.ts:65](../src/core/QuestModel.ts#L65)
6. 先检查浙大体艺、设置齿轮和盆栽相关界面。
   来源：[src/core/QuestModel.ts:67](../src/core/QuestModel.ts#L67)
7. 道具可以拖拽合并。
   来源：[src/core/QuestModel.ts:68](../src/core/QuestModel.ts#L68)
8. 浙大体艺打不开时，试试换一种网络。
   来源：[src/core/QuestModel.ts:69](../src/core/QuestModel.ts#L69)
9. 微信界面也用“自动旋转”
   来源：[src/core/QuestModel.ts:70](../src/core/QuestModel.ts#L70)
10. 光照在控制中心拖动调节
   来源：[src/core/QuestModel.ts:71](../src/core/QuestModel.ts#L71)
11. 还有一个在签到页面
   来源：[src/core/QuestModel.ts:72](../src/core/QuestModel.ts#L72)
12. 去签到
   来源：[src/core/QuestModel.ts:79](../src/core/QuestModel.ts#L79)
13. 五分钟
   来源：[src/core/QuestModel.ts:86](../src/core/QuestModel.ts#L86)
14. 签到校园卡
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)
15. 签到页
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)
16. 数字 {{state.digits.d1}}
   来源：[src/core/QuestModel.ts:89](../src/core/QuestModel.ts#L89)
17. 数字 {{state.digits.d2}}
   来源：[src/core/QuestModel.ts:90](../src/core/QuestModel.ts#L90)
18. 应用异常
   来源：[src/core/QuestModel.ts:90](../src/core/QuestModel.ts#L90)
19. 浙大体艺
   来源：[src/core/QuestModel.ts:90](../src/core/QuestModel.ts#L90)；[src/scenes/phone/P06_Tiyi/index.tsx:110](../src/scenes/phone/P06_Tiyi/index.tsx#L110)
20. 设置齿轮
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
21. 设置页
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
22. 数字 {{state.digits.d3}}
   来源：[src/core/QuestModel.ts:91](../src/core/QuestModel.ts#L91)
23. 盆栽机关
   来源：[src/core/QuestModel.ts:92](../src/core/QuestModel.ts#L92)
24. 数字 {{state.digits.d4}}
   来源：[src/core/QuestModel.ts:92](../src/core/QuestModel.ts#L92)
25. 主页盆栽
   来源：[src/core/QuestModel.ts:92](../src/core/QuestModel.ts#L92)
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
142. ZJUWLAN ·
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
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:229](../src/scenes/phone/P13_PhoneHome/index.tsx#L229)
408. 它看起来很想转转。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:233](../src/scenes/phone/P13_PhoneHome/index.tsx#L233)
409. 它转起来了！
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:233](../src/scenes/phone/P13_PhoneHome/index.tsx#L233)
410. {{definition.ariaLabel ?? definition.label}}{{access.chapter === "chapter\_one" ? "" : "，按 F2 编辑桌面"}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:560](../src/scenes/phone/P13_PhoneHome/index.tsx#L560)
411. 检查上铺床组
   来源：[src/scenes/rpg/DormHubModel.ts:142](../src/scenes/rpg/DormHubModel.ts#L142)
412. 检查下铺床组
   来源：[src/scenes/rpg/DormHubModel.ts:143](../src/scenes/rpg/DormHubModel.ts#L143)
413. 拉动窗帘
   来源：[src/scenes/rpg/DormHubModel.ts:144](../src/scenes/rpg/DormHubModel.ts#L144)
414. 打开窗下柜
   来源：[src/scenes/rpg/DormHubModel.ts:145](../src/scenes/rpg/DormHubModel.ts#L145)
415. 查看鞋架
   来源：[src/scenes/rpg/DormHubModel.ts:146](../src/scenes/rpg/DormHubModel.ts#L146)
416. 查看洗衣篮
   来源：[src/scenes/rpg/DormHubModel.ts:147](../src/scenes/rpg/DormHubModel.ts#L147)
417. 拨动蓝色台灯
   来源：[src/scenes/rpg/DormHubModel.ts:148](../src/scenes/rpg/DormHubModel.ts#L148)
418. 翻看摊开的书
   来源：[src/scenes/rpg/DormHubModel.ts:149](../src/scenes/rpg/DormHubModel.ts#L149)
419. 检查个人书桌
   来源：[src/scenes/rpg/DormHubModel.ts:150](../src/scenes/rpg/DormHubModel.ts#L150)
420. 拉开书桌抽屉
   来源：[src/scenes/rpg/DormHubModel.ts:151](../src/scenes/rpg/DormHubModel.ts#L151)
421. 拧开水龙头
   来源：[src/scenes/rpg/DormHubModel.ts:152](../src/scenes/rpg/DormHubModel.ts#L152)
422. 查看床边书架
   来源：[src/scenes/rpg/DormHubModel.ts:153](../src/scenes/rpg/DormHubModel.ts#L153)
423. 检查地上的背包
   来源：[src/scenes/rpg/DormHubModel.ts:154](../src/scenes/rpg/DormHubModel.ts#L154)
424. 打开寝室门
   来源：[src/scenes/rpg/DormHubModel.ts:155](../src/scenes/rpg/DormHubModel.ts#L155)
425. 拿起书桌上的吹风机
   来源：[src/scenes/rpg/DormHubModel.ts:192](../src/scenes/rpg/DormHubModel.ts#L192)
426. 床帘后只有一床叠得过分认真的被子。
   来源：[src/scenes/rpg/DormHubScene.ts:67](../src/scenes/rpg/DormHubScene.ts#L67)
427. 枕头下面没有捷径，只有一张过期的外卖券。
   来源：[src/scenes/rpg/DormHubScene.ts:68](../src/scenes/rpg/DormHubScene.ts#L68)
428. 窗外很亮。七点五十五分不会因此晚一点。
   来源：[src/scenes/rpg/DormHubScene.ts:69](../src/scenes/rpg/DormHubScene.ts#L69)
429. 柜门打开了。里面整齐地保存着一片空白。
   来源：[src/scenes/rpg/DormHubScene.ts:70](../src/scenes/rpg/DormHubScene.ts#L70)
430. 鞋都在，人也该在。这个推理暂时没有帮助。
   来源：[src/scenes/rpg/DormHubScene.ts:71](../src/scenes/rpg/DormHubScene.ts#L71)
431. 洗衣篮拒绝提供任何关于签到记录的证词。
   来源：[src/scenes/rpg/DormHubScene.ts:72](../src/scenes/rpg/DormHubScene.ts#L72)
432. 蓝色台灯亮了。桌面终于像有人认真学习过。
   来源：[src/scenes/rpg/DormHubScene.ts:73](../src/scenes/rpg/DormHubScene.ts#L73)
433. 书翻到夹着便签的一页：先找到名字，再谈方向。
   来源：[src/scenes/rpg/DormHubScene.ts:74](../src/scenes/rpg/DormHubScene.ts#L74)
434. 这是你的书桌。校园卡压在桌面的纸张旁边。
   来源：[src/scenes/rpg/DormHubScene.ts:75](../src/scenes/rpg/DormHubScene.ts#L75)
435. 抽屉里有三支没墨的笔，以及非常稳定的失望。
   来源：[src/scenes/rpg/DormHubScene.ts:76](../src/scenes/rpg/DormHubScene.ts#L76)
436. 吹风机还能正常工作。
   来源：[src/scenes/rpg/DormHubScene.ts:77](../src/scenes/rpg/DormHubScene.ts#L77)
437. 水龙头还能出水。至少寝室里有一个系统响应正常。
   来源：[src/scenes/rpg/DormHubScene.ts:78](../src/scenes/rpg/DormHubScene.ts#L78)
438. 书脊按课程排好，最薄的那本写着《平时分自救》。
   来源：[src/scenes/rpg/DormHubScene.ts:79](../src/scenes/rpg/DormHubScene.ts#L79)
439. 不是你的包。拉链上挂着一句很明确的‘别翻’。
   来源：[src/scenes/rpg/DormHubScene.ts:80](../src/scenes/rpg/DormHubScene.ts#L80)
440. 门没有意见，流程有。
   来源：[src/scenes/rpg/DormHubScene.ts:81](../src/scenes/rpg/DormHubScene.ts#L81)
441. 这件道具暂时不需要交给他。
   来源：[src/scenes/rpg/DormHubScene.ts:313](../src/scenes/rpg/DormHubScene.ts#L313)
442. gamepad
   来源：[src/scenes/rpg/DormHubScene.ts:316](../src/scenes/rpg/DormHubScene.ts#L316)；[src/scenes/rpg/DormHubScene.ts:318](../src/scenes/rpg/DormHubScene.ts#L318)
443. missed\_target
   来源：[src/scenes/rpg/DormHubScene.ts:316](../src/scenes/rpg/DormHubScene.ts#L316)；[src/scenes/rpg/DormHubScene.ts:327](../src/scenes/rpg/DormHubScene.ts#L327)
444. wrong\_item
   来源：[src/scenes/rpg/DormHubScene.ts:316](../src/scenes/rpg/DormHubScene.ts#L316)
445. 角色
   来源：[src/scenes/rpg/DormHubScene.ts:317](../src/scenes/rpg/DormHubScene.ts#L317)；[src/scenes/rpg/DormHubScene.ts:328](../src/scenes/rpg/DormHubScene.ts#L328)
446. 道具没有进入有效的游戏画布。
   来源：[src/scenes/rpg/DormHubScene.ts:318](../src/scenes/rpg/DormHubScene.ts#L318)
447. 角色当前只接收游戏手柄。
   来源：[src/scenes/rpg/DormHubScene.ts:318](../src/scenes/rpg/DormHubScene.ts#L318)
448. 把手柄拖到小人身上。
   来源：[src/scenes/rpg/DormHubScene.ts:324](../src/scenes/rpg/DormHubScene.ts#L324)
449. 松手点没有进入角色身体范围。
   来源：[src/scenes/rpg/DormHubScene.ts:329](../src/scenes/rpg/DormHubScene.ts#L329)
450. 你被送回寝室，衣服还在滴水。
   来源：[src/scenes/rpg/DormHubScene.ts:430](../src/scenes/rpg/DormHubScene.ts#L430)
451. 吹风机已经放进物品栏。
   来源：[src/scenes/rpg/DormHubScene.ts:456](../src/scenes/rpg/DormHubScene.ts#L456)
452. 现在还不需要使用吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:457](../src/scenes/rpg/DormHubScene.ts#L457)
453. 获得寝室吹风机。双击道具可放大查看。
   来源：[src/scenes/rpg/DormHubScene.ts:476](../src/scenes/rpg/DormHubScene.ts#L476)
454. 拿起个人书桌上的校园卡
   来源：[src/scenes/rpg/DormHubScene.ts:685](../src/scenes/rpg/DormHubScene.ts#L685)
455. 先用手机天气页面处理启真湖的云层。
   来源：[src/scenes/rpg/DormHubScene.ts:704](../src/scenes/rpg/DormHubScene.ts#L704)
456. 先从自己的书桌拿到吹风机。
   来源：[src/scenes/rpg/DormHubScene.ts:705](../src/scenes/rpg/DormHubScene.ts#L705)
457. 寝室门已打开。
   来源：[src/scenes/rpg/DormHubScene.ts:710](../src/scenes/rpg/DormHubScene.ts#L710)
458. 先完成基础馆二层南区 022 的座位预约。
   来源：[src/scenes/rpg/DormHubScene.ts:728](../src/scenes/rpg/DormHubScene.ts#L728)
459. 校园卡已经在物品栏里。
   来源：[src/scenes/rpg/DormHubScene.ts:735](../src/scenes/rpg/DormHubScene.ts#L735)
460. 当前任务还没有开放校园卡拾取。
   来源：[src/scenes/rpg/DormHubScene.ts:739](../src/scenes/rpg/DormHubScene.ts#L739)
461. 获得校园卡。身份信息已可读。
   来源：[src/scenes/rpg/DormHubScene.ts:746](../src/scenes/rpg/DormHubScene.ts#L746)
462. 他现在会按你的方向移动。
   来源：[src/scenes/rpg/DormHubScene.ts:753](../src/scenes/rpg/DormHubScene.ts#L753)
463. 方向控制已安装，试着让他走一步。
   来源：[src/scenes/rpg/DormHubScene.ts:754](../src/scenes/rpg/DormHubScene.ts#L754)

## 第二章

1. CHAPTER 02
   来源：[src/App.tsx:391](../src/App.tsx#L391)
2. 第 2 章
   来源：[src/App.tsx:392](../src/App.tsx#L392)
3. 找到移动的办法
   来源：[src/App.tsx:393](../src/App.tsx#L393)；[src/core/QuestModel.ts:239](../src/core/QuestModel.ts#L239)
4. 进入第二章
   来源：[src/App.tsx:394](../src/App.tsx#L394)
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
   来源：[src/core/QuestModel.ts:113](../src/core/QuestModel.ts#L113)
16. 主页的「方向校准」与天气页面各有一项变化，两边可以分别检查。
   来源：[src/core/QuestModel.ts:115](../src/core/QuestModel.ts#L115)
17. 取得顺序不影响后续组合。
   来源：[src/core/QuestModel.ts:116](../src/core/QuestModel.ts#L116)
18. 查看主页的「方向校准」推送
   来源：[src/core/QuestModel.ts:124](../src/core/QuestModel.ts#L124)
19. 连续检查推送头像边缘，取下松动的三角形。
   来源：[src/core/QuestModel.ts:125](../src/core/QuestModel.ts#L125)
20. 从天气页面取得天气水滴
   来源：[src/core/QuestModel.ts:132](../src/core/QuestModel.ts#L132)
21. 打开天气页面，收集已经出现的水滴。
   来源：[src/core/QuestModel.ts:133](../src/core/QuestModel.ts#L133)
22. 用天气水滴处理导师头像
   来源：[src/core/QuestModel.ts:140](../src/core/QuestModel.ts#L140)
23. 打开微信，把天气水滴拖到导师头像边缘的黏着竖线。
   来源：[src/core/QuestModel.ts:141](../src/core/QuestModel.ts#L141)
24. 组合三角形与竖线
   来源：[src/core/QuestModel.ts:148](../src/core/QuestModel.ts#L148)
25. 在道具栏中将主页三角形与导师头像掉落的竖线组合。
   来源：[src/core/QuestModel.ts:149](../src/core/QuestModel.ts#L149)
26. 用右移箭头调整校园卡余额
   来源：[src/core/QuestModel.ts:156](../src/core/QuestModel.ts#L156)
27. 把右移箭头拖到电子校园卡的余额数字上。
   来源：[src/core/QuestModel.ts:157](../src/core/QuestModel.ts#L157)
28. 完成 CC98 首次身份认证
   来源：[src/core/QuestModel.ts:164](../src/core/QuestModel.ts#L164)
29. 先从随身校园卡读取 10 位学号。
   来源：[src/core/QuestModel.ts:166](../src/core/QuestModel.ts#L166)
30. 密码按校名缩写、建校年份、结尾标点三段拼接。
   来源：[src/core/QuestModel.ts:167](../src/core/QuestModel.ts#L167)
31. 去 CC98 购买游戏手柄
   来源：[src/core/QuestModel.ts:175](../src/core/QuestModel.ts#L175)
32. 打开 CC98 二手交易，用调整后的校园卡余额付款。
   来源：[src/core/QuestModel.ts:176](../src/core/QuestModel.ts#L176)
33. 把游戏手柄安装到寝室角色
   来源：[src/core/QuestModel.ts:183](../src/core/QuestModel.ts#L183)
34. 返回寝室，把道具栏里的游戏手柄拖到角色身上。
   来源：[src/core/QuestModel.ts:184](../src/core/QuestModel.ts#L184)
35. 完成第一次手动移动
   来源：[src/core/QuestModel.ts:190](../src/core/QuestModel.ts#L190)
36. 使用方向键移动一次，确认手柄已经生效。
   来源：[src/core/QuestModel.ts:191](../src/core/QuestModel.ts#L191)
37. 确认方向控制已经生效
   来源：[src/core/QuestModel.ts:196](../src/core/QuestModel.ts#L196)
38. 让地图人物回应你
   来源：[src/core/QuestModel.ts:203](../src/core/QuestModel.ts#L203)
39. 找到道具栏
   来源：[src/core/QuestModel.ts:203](../src/core/QuestModel.ts#L203)
40. 手机里有能联系校内人员的地方。
   来源：[src/core/QuestModel.ts:205](../src/core/QuestModel.ts#L205)
41. 用校园卡上的身份信息，在部门黄页里找到他。
   来源：[src/core/QuestModel.ts:206](../src/core/QuestModel.ts#L206)
42. 让地图人物动起来
   来源：[src/core/QuestModel.ts:213](../src/core/QuestModel.ts#L213)
43. 有一个 App 专门负责把普通走路变成记录。
   来源：[src/core/QuestModel.ts:215](../src/core/QuestModel.ts#L215)
44. 打开浙大体艺，开始课外锻炼。
   来源：[src/core/QuestModel.ts:216](../src/core/QuestModel.ts#L216)
45. 预约 022
   来源：[src/core/QuestModel.ts:224](../src/core/QuestModel.ts#L224)
46. 二层南区022
   来源：[src/core/QuestModel.ts:225](../src/core/QuestModel.ts#L225)
47. 主页方向校准
   来源：[src/core/QuestModel.ts:245](../src/core/QuestModel.ts#L245)
48. 松动三角形
   来源：[src/core/QuestModel.ts:246](../src/core/QuestModel.ts#L246)
49. 天气页面
   来源：[src/core/QuestModel.ts:252](../src/core/QuestModel.ts#L252)
50. 天气水滴
   来源：[src/core/QuestModel.ts:253](../src/core/QuestModel.ts#L253)
51. completed
   来源：[src/core/QuestModel.ts:268](../src/core/QuestModel.ts#L268)
52. pending
   来源：[src/core/QuestModel.ts:268](../src/core/QuestModel.ts#L268)
53. 去图书馆
   来源：[src/core/QuestModel.ts:285](../src/core/QuestModel.ts#L285)
54. 地图缩放仔细找
   来源：[src/core/QuestModel.ts:286](../src/core/QuestModel.ts#L286)
55. 确认座位状态
   来源：[src/core/QuestModel.ts:291](../src/core/QuestModel.ts#L291)
56. 去 RPG 图书馆地图找 022。
   来源：[src/core/QuestModel.ts:293](../src/core/QuestModel.ts#L293)
57. 检查 022 上的东西和旁边的纸条。
   来源：[src/core/QuestModel.ts:294](../src/core/QuestModel.ts#L294)
58. 查清占座规则
   来源：[src/core/QuestModel.ts:300](../src/core/QuestModel.ts#L300)
59. 纸条提到了一个更吵的地方。
   来源：[src/core/QuestModel.ts:302](../src/core/QuestModel.ts#L302)
60. CC98 里有人讨论过 022。
   来源：[src/core/QuestModel.ts:303](../src/core/QuestModel.ts#L303)
61. 用占座纸条搜索 CC98，再顺着帖子找旧规则。
   来源：[src/core/QuestModel.ts:304](../src/core/QuestModel.ts#L304)
62. 凑齐恢复材料（{{proofCount}}/3）
   来源：[src/core/QuestModel.ts:311](../src/core/QuestModel.ts#L311)
63. 照片、座位夹缝和体艺都能帮上忙。
   来源：[src/core/QuestModel.ts:313](../src/core/QuestModel.ts#L313)
64. 照片曝光了就把光调小（控制中心光条）
   来源：[src/core/QuestModel.ts:314](../src/core/QuestModel.ts#L314)
65. 体艺 7,47,3
   来源：[src/core/QuestModel.ts:315](../src/core/QuestModel.ts#L315)
66. 让帖子被看见
   来源：[src/core/QuestModel.ts:322](../src/core/QuestModel.ts#L322)
67. 3027，为什么自己想
   来源：[src/core/QuestModel.ts:323](../src/core/QuestModel.ts#L323)
68. 提交恢复申请
   来源：[src/core/QuestModel.ts:329](../src/core/QuestModel.ts#L329)
69. 在浙大钉-&gt;图书馆-&gt;pass申请
   来源：[src/core/QuestModel.ts:330](../src/core/QuestModel.ts#L330)
70. 回到 022
   来源：[src/core/QuestModel.ts:336](../src/core/QuestModel.ts#L336)
71. 字面意思。
   来源：[src/core/QuestModel.ts:337](../src/core/QuestModel.ts#L337)
72. 恢复 022 座位
   来源：[src/core/QuestModel.ts:360](../src/core/QuestModel.ts#L360)
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
   来源：[src/data/library-finals.content.json:282](../src/data/library-finals.content.json#L282)；[src/scenes/rpg/LibraryInteriorScene.ts:2303](../src/scenes/rpg/LibraryInteriorScene.ts#L2303)
264. 它会说话了？！
   来源：[src/data/library-finals.content.json:283](../src/data/library-finals.content.json#L283)
265. 它把原来的话留在纸条上了。
   来源：[src/data/library-finals.content.json:284](../src/data/library-finals.content.json#L284)
266. 追到东区大食堂
   来源：[src/modules/LibraryFinalsController.ts:734](../src/modules/LibraryFinalsController.ts#L734)
267. 余额没有向任何方向移动。
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:31](../src/scenes/phone/P04_CampusCard/index.tsx#L31)
268. system
   来源：[src/scenes/phone/P04_CampusCard/index.tsx:31](../src/scenes/phone/P04_CampusCard/index.tsx#L31)；[src/scenes/phone/P04_CampusCard/index.tsx:35](../src/scenes/phone/P04_CampusCard/index.tsx#L35)；[src/scenes/phone/P15_Zjuding/index.tsx:883](../src/scenes/phone/P15_Zjuding/index.tsx#L883)；[src/scenes/phone/P15_Zjuding/index.tsx:896](../src/scenes/phone/P15_Zjuding/index.tsx#L896)；[src/scenes/phone/P15_Zjuding/index.tsx:904](../src/scenes/phone/P15_Zjuding/index.tsx#L904)；[src/scenes/phone/P15_Zjuding/index.tsx:968](../src/scenes/phone/P15_Zjuding/index.tsx#L968)；[src/scenes/phone/P15_Zjuding/index.tsx:984](../src/scenes/phone/P15_Zjuding/index.tsx#L984)；[src/scenes/phone/P15_Zjuding/index.tsx:987](../src/scenes/phone/P15_Zjuding/index.tsx#L987)；[src/scenes/phone/P15_Zjuding/index.tsx:992](../src/scenes/phone/P15_Zjuding/index.tsx#L992)；[src/scenes/phone/P15_Zjuding/index.tsx:996](../src/scenes/phone/P15_Zjuding/index.tsx#L996)；[src/scenes/rpg/LibraryInteriorScene.ts:353](../src/scenes/rpg/LibraryInteriorScene.ts#L353)；[src/scenes/rpg/LibraryInteriorScene.ts:376](../src/scenes/rpg/LibraryInteriorScene.ts#L376)；[src/scenes/rpg/LibraryInteriorScene.ts:386](../src/scenes/rpg/LibraryInteriorScene.ts#L386)；[src/scenes/rpg/LibraryInteriorScene.ts:537](../src/scenes/rpg/LibraryInteriorScene.ts#L537)；[src/scenes/rpg/LibraryInteriorScene.ts:2109](../src/scenes/rpg/LibraryInteriorScene.ts#L2109)
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
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:219](../src/scenes/rpg/LibraryInteriorModel.ts#L219)；[src/scenes/rpg/LibraryInteriorScene.ts:588](../src/scenes/rpg/LibraryInteriorScene.ts#L588)
315. 桌面夹缝
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:234](../src/scenes/rpg/LibraryInteriorModel.ts#L234)
316. 拿起占座纸条
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:246](../src/scenes/rpg/LibraryInteriorModel.ts#L246)
317. 坐到 022
   来源：[src/scenes/rpg/LibraryInteriorModel.ts:257](../src/scenes/rpg/LibraryInteriorModel.ts#L257)
318. 索书号 755
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:72](../src/scenes/rpg/LibraryInteriorScene.ts#L72)
319. 物品识别报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:73](../src/scenes/rpg/LibraryInteriorScene.ts#L73)
320. 右移箭头
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:74](../src/scenes/rpg/LibraryInteriorScene.ts#L74)
321. 离座清退 PASS
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:75](../src/scenes/rpg/LibraryInteriorScene.ts#L75)
322. 前台：请出示物品识别报告。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:79](../src/scenes/rpg/LibraryInteriorScene.ts#L79)
323. 玩家：我用肉眼看不行吗？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:80](../src/scenes/rpg/LibraryInteriorScene.ts#L80)
324. 前台：肉眼不是本部门认可设备。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:81](../src/scenes/rpg/LibraryInteriorScene.ts#L81)
325. 系统：你看，眼睛又输了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:82](../src/scenes/rpg/LibraryInteriorScene.ts#L82)
326. 记录已保存
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:360](../src/scenes/rpg/LibraryInteriorScene.ts#L360)
327. success
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:360](../src/scenes/rpg/LibraryInteriorScene.ts#L360)；[src/scenes/rpg/LibraryInteriorScene.ts:381](../src/scenes/rpg/LibraryInteriorScene.ts#L381)；[src/scenes/rpg/LibraryInteriorScene.ts:882](../src/scenes/rpg/LibraryInteriorScene.ts#L882)；[src/scenes/rpg/LibraryInteriorScene.ts:922](../src/scenes/rpg/LibraryInteriorScene.ts#L922)；[src/scenes/rpg/LibraryInteriorScene.ts:1166](../src/scenes/rpg/LibraryInteriorScene.ts#L1166)；[src/scenes/rpg/LibraryInteriorScene.ts:1190](../src/scenes/rpg/LibraryInteriorScene.ts#L1190)；[src/scenes/rpg/LibraryInteriorScene.ts:1283](../src/scenes/rpg/LibraryInteriorScene.ts#L1283)
328. 占座纸条已收入道具栏
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:368](../src/scenes/rpg/LibraryInteriorScene.ts#L368)
329. 旧规则已确认：三项证明要求已核对，可继续补齐未完成材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:376](../src/scenes/rpg/LibraryInteriorScene.ts#L376)
330. 图书馆馆藏检索功能已解锁。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:381](../src/scenes/rpg/LibraryInteriorScene.ts#L381)
331. 前台接过报告，正在核对照片、座位号和物品身份。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:386](../src/scenes/rpg/LibraryInteriorScene.ts#L386)
332. 任务更新：追上逃跑的记录纸条
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:411](../src/scenes/rpg/LibraryInteriorScene.ts#L411)
333. chapter
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:411](../src/scenes/rpg/LibraryInteriorScene.ts#L411)
334. broadcast
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:415](../src/scenes/rpg/LibraryInteriorScene.ts#L415)
335. no\_target
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:431](../src/scenes/rpg/LibraryInteriorScene.ts#L431)
336. missed\_target
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:434](../src/scenes/rpg/LibraryInteriorScene.ts#L434)
337. 把道具拖到画面中对应的真实物体。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:435](../src/scenes/rpg/LibraryInteriorScene.ts#L435)
338. wrong\_item
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:444](../src/scenes/rpg/LibraryInteriorScene.ts#L444)；[src/scenes/rpg/LibraryInteriorScene.ts:449](../src/scenes/rpg/LibraryInteriorScene.ts#L449)
339. too\_far
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:458](../src/scenes/rpg/LibraryInteriorScene.ts#L458)；[src/scenes/rpg/LibraryInteriorScene.ts:462](../src/scenes/rpg/LibraryInteriorScene.ts#L462)
340. unavailable
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:477](../src/scenes/rpg/LibraryInteriorScene.ts#L477)
341. locked
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:480](../src/scenes/rpg/LibraryInteriorScene.ts#L480)
342. 对应道具
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:578](../src/scenes/rpg/LibraryInteriorScene.ts#L578)
343. 拖入「{{itemLabel}}」 {{target.label}}
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:579](../src/scenes/rpg/LibraryInteriorScene.ts#L579)
344. 前台正在核验并盖章
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:583](../src/scenes/rpg/LibraryInteriorScene.ts#L583)
345. 询问前台工作人员
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:585](../src/scenes/rpg/LibraryInteriorScene.ts#L585)
346. 继续与 022 对话
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:590](../src/scenes/rpg/LibraryInteriorScene.ts#L590)
347. 前台正在整理失物记录，目前没有需要办理的材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:622](../src/scenes/rpg/LibraryInteriorScene.ts#L622)
348. 三项证明已齐，上传给大家看看。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:624](../src/scenes/rpg/LibraryInteriorScene.ts#L624)
349. 前台：先在照片页面生成物品识别报告，再拿来核验。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:626](../src/scenes/rpg/LibraryInteriorScene.ts#L626)
350. 前台：把物品识别报告递到柜台上，我核验后盖章。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:627](../src/scenes/rpg/LibraryInteriorScene.ts#L627)
351. 前台正在核对报告，请等她完成盖章。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:628](../src/scenes/rpg/LibraryInteriorScene.ts#L628)
352. 前台：非本人证明已经盖好，继续补齐另外两项材料。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:629](../src/scenes/rpg/LibraryInteriorScene.ts#L629)
353. 馆藏检索已同步到图书馆，可按帖子中的题名继续查找。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:634](../src/scenes/rpg/LibraryInteriorScene.ts#L634)
354. 终端可以检索题名、作者和索书号，当前没有调查关键词。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:635](../src/scenes/rpg/LibraryInteriorScene.ts#L635)
355. 书架：I247.55 区域。它看起来不是书架，是一串密码伪装成家具。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:639](../src/scenes/rpg/LibraryInteriorScene.ts#L639)
356. 书架：I247.?? 区域。看不清楚，有没有具体索书号？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:640](../src/scenes/rpg/LibraryInteriorScene.ts#L640)
357. 恢复申请已经通过，PASS 可对现场占用物生效。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:644](../src/scenes/rpg/LibraryInteriorScene.ts#L644)
358. 打印机显示缺纸；旁边的纸盒显示库存充足。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:652](../src/scenes/rpg/LibraryInteriorScene.ts#L652)
359. 夹缝里露出一角小票，手指无法直接取出。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:655](../src/scenes/rpg/LibraryInteriorScene.ts#L655)
360. 纸条引用了一段公开讨论，关键词仍可辨认。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:656](../src/scenes/rpg/LibraryInteriorScene.ts#L656)
361. 椅子仍被占用。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:657](../src/scenes/rpg/LibraryInteriorScene.ts#L657)
362. 座位已经空出，可以坐下确认会话。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:657](../src/scenes/rpg/LibraryInteriorScene.ts#L657)
363. 07:55
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:756](../src/scenes/rpg/LibraryInteriorScene.ts#L756)
364. 主馆入口
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:756](../src/scenes/rpg/LibraryInteriorScene.ts#L756)；[src/scenes/rpg/LibraryInteriorScene.ts:1642](../src/scenes/rpg/LibraryInteriorScene.ts#L1642)
365. 08:02
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:757](../src/scenes/rpg/LibraryInteriorScene.ts#L757)
366. 二楼南区 022
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:757](../src/scenes/rpg/LibraryInteriorScene.ts#L757)；[src/scenes/rpg/LibraryInteriorScene.ts:1661](../src/scenes/rpg/LibraryInteriorScene.ts#L1661)
367. 这个道具和目标的证据类型对不上。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:803](../src/scenes/rpg/LibraryInteriorScene.ts#L803)
368. 先走到{{targetLabel ? \`「${targetLabel}」\` : "目标"}}的可操作边缘，再使用道具。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:805](../src/scenes/rpg/LibraryInteriorScene.ts#L805)
369. 道具没有落在可交互目标上。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:807](../src/scenes/rpg/LibraryInteriorScene.ts#L807)
370. 条件还不完整，目标暂时不接受这个操作。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:808](../src/scenes/rpg/LibraryInteriorScene.ts#L808)
371. error
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:809](../src/scenes/rpg/LibraryInteriorScene.ts#L809)；[src/scenes/rpg/LibraryInteriorScene.ts:869](../src/scenes/rpg/LibraryInteriorScene.ts#L869)
372. 022 仍有微弱信号，信号源被书包压住了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:869](../src/scenes/rpg/LibraryInteriorScene.ts#L869)
373. 书架开始缓慢横移，后面的夹层逐渐露出一份旧黄纸。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:922](../src/scenes/rpg/LibraryInteriorScene.ts#L922)
374. 022 · 空闲
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1065](../src/scenes/rpg/LibraryInteriorScene.ts#L1065)
375. 022 · 占用
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1065](../src/scenes/rpg/LibraryInteriorScene.ts#L1065)；[src/scenes/rpg/LibraryInteriorScene.ts:2276](../src/scenes/rpg/LibraryInteriorScene.ts#L2276)
376. 前台盖章完成：书包不等于本人。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1166](../src/scenes/rpg/LibraryInteriorScene.ts#L1166)
377. 小票向“右”了。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1190](../src/scenes/rpg/LibraryInteriorScene.ts#L1190)
378. 022 · 转移中
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1224](../src/scenes/rpg/LibraryInteriorScene.ts#L1224)
379. 书包：主人马上回来。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1226](../src/scenes/rpg/LibraryInteriorScene.ts#L1226)
380. 玩家：什么时候？
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1227](../src/scenes/rpg/LibraryInteriorScene.ts#L1227)
381. 书包：三分钟。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1228](../src/scenes/rpg/LibraryInteriorScene.ts#L1228)
382. 系统：它三天前也是这么说的。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1229](../src/scenes/rpg/LibraryInteriorScene.ts#L1229)
383. 022 已恢复。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1283](../src/scenes/rpg/LibraryInteriorScene.ts#L1283)
384. 图书馆门禁 · 入馆记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1612](../src/scenes/rpg/LibraryInteriorScene.ts#L1612)
385. 入馆扫描
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1631](../src/scenes/rpg/LibraryInteriorScene.ts#L1631)
386. 到达记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1650](../src/scenes/rpg/LibraryInteriorScene.ts#L1650)
387. 到座耗时核对：08:02 − 07:55
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1673](../src/scenes/rpg/LibraryInteriorScene.ts#L1673)
388. 目标记录：二楼南区 022 · 会话未闭合
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1679](../src/scenes/rpg/LibraryInteriorScene.ts#L1679)
389. 记下记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1687](../src/scenes/rpg/LibraryInteriorScene.ts#L1687)；[src/scenes/rpg/LibraryInteriorScene.ts:1832](../src/scenes/rpg/LibraryInteriorScene.ts#L1832)
390. Enter / 空格 确认 · Esc 关闭
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1700](../src/scenes/rpg/LibraryInteriorScene.ts#L1700)
391. 入馆记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1770](../src/scenes/rpg/LibraryInteriorScene.ts#L1770)
392. 点击查看
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1776](../src/scenes/rpg/LibraryInteriorScene.ts#L1776)；[src/scenes/rpg/LibraryInteriorScene.ts:1889](../src/scenes/rpg/LibraryInteriorScene.ts#L1889)
393. 关闭记录
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1832](../src/scenes/rpg/LibraryInteriorScene.ts#L1832)
394. 已读取 · 点击复查
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1889](../src/scenes/rpg/LibraryInteriorScene.ts#L1889)
395. 基础图书馆 · 二层南区
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1898](../src/scenes/rpg/LibraryInteriorScene.ts#L1898)
396. 信息台 / 失物招领
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:1990](../src/scenes/rpg/LibraryInteriorScene.ts#L1990)
397. 图
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2055](../src/scenes/rpg/LibraryInteriorScene.ts#L2055)
398. 物
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2055](../src/scenes/rpg/LibraryInteriorScene.ts#L2055)
399. 座
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2055](../src/scenes/rpg/LibraryInteriorScene.ts#L2055)
400. 非本人
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2079](../src/scenes/rpg/LibraryInteriorScene.ts#L2079)
401. 请靠近信息台柜台。
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2109](../src/scenes/rpg/LibraryInteriorScene.ts#L2109)
402. 等待报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2126](../src/scenes/rpg/LibraryInteriorScene.ts#L2126)
403. 递交报告
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2127](../src/scenes/rpg/LibraryInteriorScene.ts#L2127)
404. 人工核验
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2128](../src/scenes/rpg/LibraryInteriorScene.ts#L2128)
405. 已盖章
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2129](../src/scenes/rpg/LibraryInteriorScene.ts#L2129)
406. 馆藏检索 / 打印
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2174](../src/scenes/rpg/LibraryInteriorScene.ts#L2174)
407. 文学 / 社科书架
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2191](../src/scenes/rpg/LibraryInteriorScene.ts#L2191)
408. 旧规
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2246](../src/scenes/rpg/LibraryInteriorScene.ts#L2246)
409. 二层南区 · 安静阅览
   来源：[src/scenes/rpg/LibraryInteriorScene.ts:2265](../src/scenes/rpg/LibraryInteriorScene.ts#L2265)

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
   来源：[src/components/ChapterThreeOpeningOverlay.tsx:424](../src/components/ChapterThreeOpeningOverlay.tsx#L424)；[src/core/QuestModel.ts:745](../src/core/QuestModel.ts#L745)；[src/core/QuestModel.ts:771](../src/core/QuestModel.ts#L771)；[src/core/QuestModel.ts:773](../src/core/QuestModel.ts#L773)；[src/core/QuestModel.ts:775](../src/core/QuestModel.ts#L775)
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
   来源：[src/core/QuestModel.ts:384](../src/core/QuestModel.ts#L384)
35. 器材收齐后，去小码头找值班老师确认。
   来源：[src/core/QuestModel.ts:385](../src/core/QuestModel.ts#L385)
36. 再次尝试登船
   来源：[src/core/QuestModel.ts:389](../src/core/QuestModel.ts#L389)
37. 回到皮划艇旁。
   来源：[src/core/QuestModel.ts:390](../src/core/QuestModel.ts#L390)
38. 靠近食堂里的异常纸条
   来源：[src/core/QuestModel.ts:472](../src/core/QuestModel.ts#L472)
39. 纸条停在入口附近，靠近后会继续移动。
   来源：[src/core/QuestModel.ts:472](../src/core/QuestModel.ts#L472)
40. 她在找几只没送回来的餐盘，应该看见了刚才的动静。
   来源：[src/core/QuestModel.ts:475](../src/core/QuestModel.ts#L475)
41. 与收餐口阿姨交谈
   来源：[src/core/QuestModel.ts:475](../src/core/QuestModel.ts#L475)；[src/scenes/rpg/CanteenInteriorScene.ts:1004](../src/scenes/rpg/CanteenInteriorScene.ts#L1004)
42. 找出并交回带污渍的餐盘（{{returnedTargetTrays}}/3）
   来源：[src/core/QuestModel.ts:480](../src/core/QuestModel.ts#L480)
43. 深色观察可辨认蓝光和油渍；浅色操作可直接拿起餐盘并交给收餐口阿姨。
   来源：[src/core/QuestModel.ts:481](../src/core/QuestModel.ts#L481)
44. 一次只能搬一个餐盘。
   来源：[src/core/QuestModel.ts:481](../src/core/QuestModel.ts#L481)
45. 查看第三列队伍和新品宣传板
   来源：[src/core/QuestModel.ts:486](../src/core/QuestModel.ts#L486)
46. 与排队学生交谈，确认怎样让第三列队伍移动。
   来源：[src/core/QuestModel.ts:486](../src/core/QuestModel.ts#L486)
47. 查看饮料货架的颜色顺序
   来源：[src/core/QuestModel.ts:489](../src/core/QuestModel.ts#L489)
48. 货架从左到右的颜色决定调配顺序。
   来源：[src/core/QuestModel.ts:489](../src/core/QuestModel.ts#L489)
49. 在校园地图核对地点交点
   来源：[src/core/QuestModel.ts:535](../src/core/QuestModel.ts#L535)
50. 三条地点记录已接入。
   来源：[src/core/QuestModel.ts:537](../src/core/QuestModel.ts#L537)
51. 打开浙大钉的校园地图，完成最后核对。
   来源：[src/core/QuestModel.ts:538](../src/core/QuestModel.ts#L538)
52. 从校园地图前往启真湖
   来源：[src/core/QuestModel.ts:553](../src/core/QuestModel.ts#L553)
53. 进入大地图后走到启真湖入口。
   来源：[src/core/QuestModel.ts:554](../src/core/QuestModel.ts#L554)
54. 手机地图已确认地点。
   来源：[src/core/QuestModel.ts:554](../src/core/QuestModel.ts#L554)
55. 启真湖追纸
   来源：[src/core/QuestModel.ts:559](../src/core/QuestModel.ts#L559)
56. 码头柜门
   来源：[src/core/QuestModel.ts:566](../src/core/QuestModel.ts#L566)
57. 尼龙绳已取出
   来源：[src/core/QuestModel.ts:567](../src/core/QuestModel.ts#L567)
58. 一扇上锁的柜门
   来源：[src/core/QuestModel.ts:567](../src/core/QuestModel.ts#L567)
59. 直河浮排
   来源：[src/core/QuestModel.ts:572](../src/core/QuestModel.ts#L572)
60. 木桩下的框状物
   来源：[src/core/QuestModel.ts:573](../src/core/QuestModel.ts#L573)
61. 网框已捞起
   来源：[src/core/QuestModel.ts:573](../src/core/QuestModel.ts#L573)
62. 天鹅围栏
   来源：[src/core/QuestModel.ts:578](../src/core/QuestModel.ts#L578)
63. 磁性扣已收好
   来源：[src/core/QuestModel.ts:579](../src/core/QuestModel.ts#L579)
64. 围栏边的旧饲料盒
   来源：[src/core/QuestModel.ts:579](../src/core/QuestModel.ts#L579)
65. 找到进入观众席的办法
   来源：[src/core/QuestModel.ts:603](../src/core/QuestModel.ts#L603)
66. 检票员只接受本场有效票，先看看大厅里的票务信息。
   来源：[src/core/QuestModel.ts:605](../src/core/QuestModel.ts#L605)
67. 有人临时无法到场，可能留下过退票留言。
   来源：[src/core/QuestModel.ts:606](../src/core/QuestModel.ts#L606)
68. 校园论坛的近期帖子里，或许能找到那位同学。
   来源：[src/core/QuestModel.ts:607](../src/core/QuestModel.ts#L607)
69. 确认这场演出的放票信息
   来源：[src/core/QuestModel.ts:615](../src/core/QuestModel.ts#L615)
70. 在深色观察中靠近取票机，读取屏幕残影。
   来源：[src/core/QuestModel.ts:617](../src/core/QuestModel.ts#L617)
71. 确认时间后回到手机 CC98 帖子参加第一波。
   来源：[src/core/QuestModel.ts:618](../src/core/QuestModel.ts#L618)
72. 在手机 CC98 票务页参加第一波放票
   来源：[src/core/QuestModel.ts:624](../src/core/QuestModel.ts#L624)
73. 打开学生剧现场帮抢帖，在票务卡中操作。
   来源：[src/core/QuestModel.ts:626](../src/core/QuestModel.ts#L626)
74. 大厅记录可用于确认第一波的放票时间。
   来源：[src/core/QuestModel.ts:627](../src/core/QuestModel.ts#L627)
75. 在手机票务页参加第二波放票
   来源：[src/core/QuestModel.ts:635](../src/core/QuestModel.ts#L635)
76. 第一波未抢到，当前网速过慢。
   来源：[src/core/QuestModel.ts:637](../src/core/QuestModel.ts#L637)
77. 回到 CC98 帮抢帖，等待倒计时结束后再次提交。
   来源：[src/core/QuestModel.ts:638](../src/core/QuestModel.ts#L638)
78. 把临时观演票交给检票闸机
   来源：[src/core/QuestModel.ts:647](../src/core/QuestModel.ts#L647)
79. 靠近闸机右侧的读票器。
   来源：[src/core/QuestModel.ts:649](../src/core/QuestModel.ts#L649)
80. 把临时观演票交给读票器。
   来源：[src/core/QuestModel.ts:650](../src/core/QuestModel.ts#L650)
81. 核对两张票根能否拼合
   来源：[src/core/QuestModel.ts:657](../src/core/QuestModel.ts#L657)
82. 比较两半的场次、票号和断口，匹配的票根可以拼接。
   来源：[src/core/QuestModel.ts:658](../src/core/QuestModel.ts#L658)
83. 去剧院取票机打印半张票根 B
   来源：[src/core/QuestModel.ts:664](../src/core/QuestModel.ts#L664)
84. 手机抢票已经成功，订单取票码是 0832。
   来源：[src/core/QuestModel.ts:666](../src/core/QuestModel.ts#L666)
85. 在浅色操作中靠近取票机，输入取票码打印实体票根。
   来源：[src/core/QuestModel.ts:667](../src/core/QuestModel.ts#L667)
86. 找找缺失的另一半票根
   来源：[src/core/QuestModel.ts:674](../src/core/QuestModel.ts#L674)
87. 靠近大厅左侧的海报玻璃。
   来源：[src/core/QuestModel.ts:676](../src/core/QuestModel.ts#L676)
88. 玻璃上的反光挡住了夹层，手边的纸巾能擦一擦。
   来源：[src/core/QuestModel.ts:677](../src/core/QuestModel.ts#L677)
89. 确认两张半票根
   来源：[src/core/QuestModel.ts:683](../src/core/QuestModel.ts#L683)
90. 打开道具栏确认票根 A 与票根 B，再完成组合。
   来源：[src/core/QuestModel.ts:684](../src/core/QuestModel.ts#L684)
91. 追光第 {{Math.min(state.theaterHunt.spotlightRound + 1, 3)}} / 3 轮：观察轨迹，预置灯位并持续照射
   来源：[src/core/QuestModel.ts:717](../src/core/QuestModel.ts#L717)
92. 已完成 {{state.theaterHunt.spotlightRound}} / 3 轮，失败只重试当前轮。
   来源：[src/core/QuestModel.ts:719](../src/core/QuestModel.ts#L719)
93. 查看追光灯下的纸条
   来源：[src/core/QuestModel.ts:729](../src/core/QuestModel.ts#L729)
94. 剧院追纸
   来源：[src/core/QuestModel.ts:739](../src/core/QuestModel.ts#L739)
95. 沿校园地图中留下的脚印前往东区大食堂。
   来源：[src/core/QuestModel.ts:746](../src/core/QuestModel.ts#L746)；[src/core/QuestModel.ts:776](../src/core/QuestModel.ts#L776)
96. 追上逃跑的记录纸条
   来源：[src/data/chapter3-canteen.content.json:4](../src/data/chapter3-canteen.content.json#L4)
97. 纸条钻进了食堂。
   来源：[src/data/chapter3-canteen.content.json:6](../src/data/chapter3-canteen.content.json#L6)
98. 切到深色观察，沿着它留下的蓝色纸屑找路。
   来源：[src/data/chapter3-canteen.content.json:7](../src/data/chapter3-canteen.content.json#L7)
99. 痕迹在热气和收餐口附近断开。
   来源：[src/data/chapter3-canteen.content.json:8](../src/data/chapter3-canteen.content.json#L8)
100. 旁白：纸条钻进了食堂。
   来源：[src/data/chapter3-canteen.content.json:12](../src/data/chapter3-canteen.content.json#L12)
101. 系统：先别跟丢。
   来源：[src/data/chapter3-canteen.content.json:13](../src/data/chapter3-canteen.content.json#L13)
102. 任务：在食堂截住纸条
   来源：[src/data/chapter3-canteen.content.json:15](../src/data/chapter3-canteen.content.json#L15)
103. 深色观察能看见纸条碰过的餐盘和墙角。
   来源：[src/data/chapter3-canteen.content.json:17](../src/data/chapter3-canteen.content.json#L17)
104. 点餐后会拿到一张取餐小票。
   来源：[src/data/chapter3-canteen.content.json:18](../src/data/chapter3-canteen.content.json#L18)
105. 窗口残影里还能听见叫号，先和手里的小票对一对。
   来源：[src/data/chapter3-canteen.content.json:19](../src/data/chapter3-canteen.content.json#L19)
106. 阿姨：同学，桌上有三只脏盘，能不能帮我送回来？
   来源：[src/data/chapter3-canteen.content.json:23](../src/data/chapter3-canteen.content.json#L23)
107. 玩家：我只是来找东西的。
   来源：[src/data/chapter3-canteen.content.json:24](../src/data/chapter3-canteen.content.json#L24)
108. 阿姨：那正好，找盘子也算找。送回来给你两块。
   来源：[src/data/chapter3-canteen.content.json:25](../src/data/chapter3-canteen.content.json#L25)
109. 任务：找出并交回三只带污渍的餐盘。
   来源：[src/data/chapter3-canteen.content.json:27](../src/data/chapter3-canteen.content.json#L27)
110. 当前为深色观察，只能辨认残影；拿取餐盘需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:28](../src/data/chapter3-canteen.content.json#L28)
111. 你手上已经有一个餐盘。先把它交给阿姨。
   来源：[src/data/chapter3-canteen.content.json:29](../src/data/chapter3-canteen.content.json#L29)
112. 阿姨：先拿一个盘子过来。
   来源：[src/data/chapter3-canteen.content.json:30](../src/data/chapter3-canteen.content.json#L30)
113. 已拿起餐盘。把它交给右侧收餐口的阿姨。
   来源：[src/data/chapter3-canteen.content.json:31](../src/data/chapter3-canteen.content.json#L31)
114. 阿姨：这只对，油渍和蓝光都在。
   来源：[src/data/chapter3-canteen.content.json:32](../src/data/chapter3-canteen.content.json#L32)
115. 阿姨：这只很干净，先放这儿。我还要找脏的。
   来源：[src/data/chapter3-canteen.content.json:33](../src/data/chapter3-canteen.content.json#L33)
116. 阿姨：三只都回来了。两块钱和这张纸巾，拿着。
   来源：[src/data/chapter3-canteen.content.json:35](../src/data/chapter3-canteen.content.json#L35)
117. 玩家：收盘子还有工资？
   来源：[src/data/chapter3-canteen.content.json:36](../src/data/chapter3-canteen.content.json#L36)
118. 阿姨：今天有。明天看排班。
   来源：[src/data/chapter3-canteen.content.json:37](../src/data/chapter3-canteen.content.json#L37)
119. 系统：现金 2.00 元已入账。
   来源：[src/data/chapter3-canteen.content.json:38](../src/data/chapter3-canteen.content.json#L38)
120. 阿姨：盘子放履带，别站上去。
   来源：[src/data/chapter3-canteen.content.json:40](../src/data/chapter3-canteen.content.json#L40)
121. 玩家：我能站到前面吗？
   来源：[src/data/chapter3-canteen.content.json:44](../src/data/chapter3-canteen.content.json#L44)
122. 同学：等着吧。前面说要先看新品，饭还没吃，广告已经看两轮了。
   来源：[src/data/chapter3-canteen.content.json:45](../src/data/chapter3-canteen.content.json#L45)
123. 想拿哪一瓶？
   来源：[src/data/chapter3-canteen.content.json:47](../src/data/chapter3-canteen.content.json#L47)
124. 拿饮料
   来源：[src/data/chapter3-canteen.content.json:48](../src/data/chapter3-canteen.content.json#L48)
125. 算了
   来源：[src/data/chapter3-canteen.content.json:49](../src/data/chapter3-canteen.content.json#L49)
126. 这瓶已经在物品栏里，先拿去调配。
   来源：[src/data/chapter3-canteen.content.json:50](../src/data/chapter3-canteen.content.json#L50)
127. 获得气泡水（蓝色）。
   来源：[src/data/chapter3-canteen.content.json:52](../src/data/chapter3-canteen.content.json#L52)
128. 获得柠檬茶（白色）。
   来源：[src/data/chapter3-canteen.content.json:53](../src/data/chapter3-canteen.content.json#L53)
129. 获得黑咖啡（黑色）。
   来源：[src/data/chapter3-canteen.content.json:54](../src/data/chapter3-canteen.content.json#L54)
130. 口味标签擦花了，颜色顺序还认得清。
   来源：[src/data/chapter3-canteen.content.json:56](../src/data/chapter3-canteen.content.json#L56)
131. 货架颜色从左到右：黑色、蓝色、白色。
   来源：[src/data/chapter3-canteen.content.json:57](../src/data/chapter3-canteen.content.json#L57)
132. 请按货架提示调配今日新品。
   来源：[src/data/chapter3-canteen.content.json:58](../src/data/chapter3-canteen.content.json#L58)
133. 调配单只写了“按货架排列”。先去看一眼。
   来源：[src/data/chapter3-canteen.content.json:59](../src/data/chapter3-canteen.content.json#L59)
134. 这瓶饮料不在道具栏里。
   来源：[src/data/chapter3-canteen.content.json:60](../src/data/chapter3-canteen.content.json#L60)
135. 饮料已经倒入大玻璃杯。
   来源：[src/data/chapter3-canteen.content.json:61](../src/data/chapter3-canteen.content.json#L61)
136. 配方不对，得到难喝饮料。
   来源：[src/data/chapter3-canteen.content.json:62](../src/data/chapter3-canteen.content.json#L62)
137. 配方正确，得到今日新品气泡水。
   来源：[src/data/chapter3-canteen.content.json:63](../src/data/chapter3-canteen.content.json#L63)
138. 玩家：这也能卖？
   来源：[src/data/chapter3-canteen.content.json:65](../src/data/chapter3-canteen.content.json#L65)
139. 系统：你已完成试饮。无退款项目。
   来源：[src/data/chapter3-canteen.content.json:66](../src/data/chapter3-canteen.content.json#L66)
140. 把今日新品气泡水拖到第三窗口宣传板下方的空杯位。
   来源：[src/data/chapter3-canteen.content.json:68](../src/data/chapter3-canteen.content.json#L68)
141. 宣传板亮了，第三列队伍开始后退。
   来源：[src/data/chapter3-canteen.content.json:69](../src/data/chapter3-canteen.content.json#L69)
142. 今日新品气泡水
   来源：[src/data/chapter3-canteen.content.json:70](../src/data/chapter3-canteen.content.json#L70)
143. 今日新品，欢迎试饮。意见可提，配方不改。
   来源：[src/data/chapter3-canteen.content.json:71](../src/data/chapter3-canteen.content.json#L71)
144. 玩家：他们怎么都退了？
   来源：[src/data/chapter3-canteen.content.json:73](../src/data/chapter3-canteen.content.json#L73)
145. 系统：新品一摆出来就退了。至少试饮意见很一致。
   来源：[src/data/chapter3-canteen.content.json:74](../src/data/chapter3-canteen.content.json#L74)
146. 菜单上都是常见菜名。刚才看见的字，似乎有几个不一样。
   来源：[src/data/chapter3-canteen.content.json:79](../src/data/chapter3-canteen.content.json#L79)
147. 暗色菜单换成了另一套字。
   来源：[src/data/chapter3-canteen.content.json:80](../src/data/chapter3-canteen.content.json#L80)
148. 暗色菜单已记录。浅色操作可在点餐机下单。
   来源：[src/data/chapter3-canteen.content.json:81](../src/data/chapter3-canteen.content.json#L81)
149. 当前为深色观察，只能查看菜单；下单需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:82](../src/data/chapter3-canteen.content.json#L82)
150. 先取完当前餐品，点餐机才接受下一单。
   来源：[src/data/chapter3-canteen.content.json:83](../src/data/chapter3-canteen.content.json#L83)
151. 包过
   来源：[src/data/chapter3-canteen.content.json:85](../src/data/chapter3-canteen.content.json#L85)
152. 包子
   来源：[src/data/chapter3-canteen.content.json:85](../src/data/chapter3-canteen.content.json#L85)
153. 豆过
   来源：[src/data/chapter3-canteen.content.json:86](../src/data/chapter3-canteen.content.json#L86)
154. 豆浆
   来源：[src/data/chapter3-canteen.content.json:86](../src/data/chapter3-canteen.content.json#L86)
155. 鸡蛋
   来源：[src/data/chapter3-canteen.content.json:87](../src/data/chapter3-canteen.content.json#L87)
156. 鸡过
   来源：[src/data/chapter3-canteen.content.json:87](../src/data/chapter3-canteen.content.json#L87)
157. 纸包过
   来源：[src/data/chapter3-canteen.content.json:88](../src/data/chapter3-canteen.content.json#L88)
158. 纸包鸡
   来源：[src/data/chapter3-canteen.content.json:88](../src/data/chapter3-canteen.content.json#L88)
159. 白过
   来源：[src/data/chapter3-canteen.content.json:89](../src/data/chapter3-canteen.content.json#L89)
160. 白粥
   来源：[src/data/chapter3-canteen.content.json:89](../src/data/chapter3-canteen.content.json#L89)
161. 点餐机：已下单
   来源：[src/data/chapter3-canteen.content.json:91](../src/data/chapter3-canteen.content.json#L91)；[src/data/chapter3-canteen.content.json:92](../src/data/chapter3-canteen.content.json#L92)
162. 系统：纸包鸡已经下单。拿好 0755 取餐号。
   来源：[src/data/chapter3-canteen.content.json:93](../src/data/chapter3-canteen.content.json#L93)
163. 窗口要看取餐小票。点餐机还开着。
   来源：[src/data/chapter3-canteen.content.json:96](../src/data/chapter3-canteen.content.json#L96)
164. 小票退回来了，号码还清楚。留着再核对。
   来源：[src/data/chapter3-canteen.content.json:97](../src/data/chapter3-canteen.content.json#L97)
165. 残影阿姨：……票……
   来源：[src/data/chapter3-canteen.content.json:98](../src/data/chapter3-canteen.content.json#L98)；[src/data/chapter3-canteen.content.json:99](../src/data/chapter3-canteen.content.json#L99)
166. 这个窗口没动静，别处还有叫号声。
   来源：[src/data/chapter3-canteen.content.json:100](../src/data/chapter3-canteen.content.json#L100)
167. 深色观察只能查看窗口残影；交票需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:101](../src/data/chapter3-canteen.content.json#L101)
168. 这张票不归这个窗口。
   来源：[src/data/chapter3-canteen.content.json:102](../src/data/chapter3-canteen.content.json#L102)
169. 残影阿姨接过票。
   来源：[src/data/chapter3-canteen.content.json:103](../src/data/chapter3-canteen.content.json#L103)
170. 取餐系统：该餐品不在当前时间。
   来源：[src/data/chapter3-canteen.content.json:105](../src/data/chapter3-canteen.content.json#L105)
171. 玩家：那我点到哪一天了？
   来源：[src/data/chapter3-canteen.content.json:106](../src/data/chapter3-canteen.content.json#L106)
172. 系统：换一个窗口试试。
   来源：[src/data/chapter3-canteen.content.json:107](../src/data/chapter3-canteen.content.json#L107)
173. 领到窗口包子。
   来源：[src/data/chapter3-canteen.content.json:110](../src/data/chapter3-canteen.content.json#L110)
174. 领到窗口豆浆。
   来源：[src/data/chapter3-canteen.content.json:111](../src/data/chapter3-canteen.content.json#L111)
175. 领到水煮蛋。
   来源：[src/data/chapter3-canteen.content.json:112](../src/data/chapter3-canteen.content.json#L112)
176. 领到烫手的白粥。
   来源：[src/data/chapter3-canteen.content.json:113](../src/data/chapter3-canteen.content.json#L113)
177. 1号窗口：0755号，请取粥。
   来源：[src/data/chapter3-canteen.content.json:116](../src/data/chapter3-canteen.content.json#L116)
178. 系统：领到一碗粥。纸条不在这里。
   来源：[src/data/chapter3-canteen.content.json:117](../src/data/chapter3-canteen.content.json#L117)
179. 2号窗口：0755号，请取蛋。
   来源：[src/data/chapter3-canteen.content.json:120](../src/data/chapter3-canteen.content.json#L120)
180. 玩家：怎么又领错了？
   来源：[src/data/chapter3-canteen.content.json:121](../src/data/chapter3-canteen.content.json#L121)
181. 系统：号码没错。这个窗口发的就是蛋。
   来源：[src/data/chapter3-canteen.content.json:122](../src/data/chapter3-canteen.content.json#L122)
182. 3号窗口：0755 号，请取纸。纸条从蒸汽里弹出。
   来源：[src/data/chapter3-canteen.content.json:124](../src/data/chapter3-canteen.content.json#L124)
183. 3号窗口：0755 号，请取纸。
   来源：[src/data/chapter3-canteen.content.json:125](../src/data/chapter3-canteen.content.json#L125)
184. 餐盘车可以推，先把它放到纸条要去的出口。
   来源：[src/data/chapter3-canteen.content.json:128](../src/data/chapter3-canteen.content.json#L128)
185. 蓝色轨迹停在当前出口。浅色操作可以推动实体餐车。
   来源：[src/data/chapter3-canteen.content.json:129](../src/data/chapter3-canteen.content.json#L129)
186. 这辆餐车没有接上当前蓝色轨迹。
   来源：[src/data/chapter3-canteen.content.json:130](../src/data/chapter3-canteen.content.json#L130)
187. 深色观察只能查看轨迹；推动实体餐车需要浅色操作。
   来源：[src/data/chapter3-canteen.content.json:131](../src/data/chapter3-canteen.content.json#L131)
188. 纸条从另一个出口飞走了。
   来源：[src/data/chapter3-canteen.content.json:132](../src/data/chapter3-canteen.content.json#L132)
189. 纸条撞上餐盘车，掉下蓝色纸屑。
   来源：[src/data/chapter3-canteen.content.json:134](../src/data/chapter3-canteen.content.json#L134)
190. 它调头，下一次会换出口。
   来源：[src/data/chapter3-canteen.content.json:135](../src/data/chapter3-canteen.content.json#L135)
191. 阿姨：纸不能打包带走。
   来源：[src/data/chapter3-canteen.content.json:138](../src/data/chapter3-canteen.content.json#L138)
192. 玩家：它自己跑出去的。
   来源：[src/data/chapter3-canteen.content.json:139](../src/data/chapter3-canteen.content.json#L139)
193. 系统：出门，继续追。
   来源：[src/data/chapter3-canteen.content.json:140](../src/data/chapter3-canteen.content.json#L140)
194. 餐盘回收费 2.00 元
   来源：[src/data/chapter3-canteen.content.json:144](../src/data/chapter3-canteen.content.json#L144)
195. 三只脏盘换来的 2.00 元，够骑一次车。今天现结。
   来源：[src/data/chapter3-canteen.content.json:145](../src/data/chapter3-canteen.content.json#L145)
196. 油渍纸巾
   来源：[src/data/chapter3-canteen.content.json:146](../src/data/chapter3-canteen.content.json#L146)
197. 阿姨给的纸巾还留着干净的一角，能擦车锁和海报玻璃。
   来源：[src/data/chapter3-canteen.content.json:147](../src/data/chapter3-canteen.content.json#L147)
198. 0755 取餐号
   来源：[src/data/chapter3-canteen.content.json:148](../src/data/chapter3-canteen.content.json#L148)
199. 点餐机打印的取餐小票。浅色操作时可交给对应取餐窗口。
   来源：[src/data/chapter3-canteen.content.json:149](../src/data/chapter3-canteen.content.json#L149)
200. 纸条沿主干道飞走。
   来源：[src/data/chapter3-canteen.content.json:153](../src/data/chapter3-canteen.content.json#L153)；[src/data/chapter3-story-lines.json:119](../src/data/chapter3-story-lines.json#L119)
201. 系统：共享单车在路边。用 2.00 元扫码。
   来源：[src/data/chapter3-canteen.content.json:154](../src/data/chapter3-canteen.content.json#L154)
202. 玩家：它已经跑远了。
   来源：[src/data/chapter3-canteen.content.json:155](../src/data/chapter3-canteen.content.json#L155)
203. 系统：两块钱刚到账，车费也是两块。收支平衡。
   来源：[src/data/chapter3-canteen.content.json:156](../src/data/chapter3-canteen.content.json#L156)
204. 扫码骑车：2.00 元 / 次
   来源：[src/data/chapter3-canteen.content.json:158](../src/data/chapter3-canteen.content.json#L158)
205. 我的零钱：{amount} 元
   来源：[src/data/chapter3-canteen.content.json:159](../src/data/chapter3-canteen.content.json#L159)
206. 玩家：零钱不够。
   来源：[src/data/chapter3-canteen.content.json:161](../src/data/chapter3-canteen.content.json#L161)
207. 系统：先完成餐盘回收。
   来源：[src/data/chapter3-canteen.content.json:162](../src/data/chapter3-canteen.content.json#L162)
208. 餐盘回收费已到账。用 2.00 元支付一次骑行。
   来源：[src/data/chapter3-canteen.content.json:164](../src/data/chapter3-canteen.content.json#L164)
209. 反光过强，识别失败
   来源：[src/data/chapter3-canteen.content.json:165](../src/data/chapter3-canteen.content.json#L165)
210. 显示完整编号与二维码边缘压痕
   来源：[src/data/chapter3-canteen.content.json:166](../src/data/chapter3-canteen.content.json#L166)
211. 残影记录不具备支付资格。
   来源：[src/data/chapter3-canteen.content.json:167](../src/data/chapter3-canteen.content.json#L167)
212. 反光消失，二维码可读
   来源：[src/data/chapter3-canteen.content.json:168](../src/data/chapter3-canteen.content.json#L168)
213. 浅色操作可清洁车锁并扫码付款；深色观察可补充查看编号压痕。
   来源：[src/data/chapter3-canteen.content.json:169](../src/data/chapter3-canteen.content.json#L169)
214. 755 米骑行完成，纸条钻进剧院。
   来源：[src/data/chapter3-canteen.content.json:170](../src/data/chapter3-canteen.content.json#L170)
215. 人行道上有人赶早课，没人注意纸条掠过车道。
   来源：[src/data/chapter3-canteen.content.json:172](../src/data/chapter3-canteen.content.json#L172)
216. 食堂门口两个人聊着天，占住了外侧车道。
   来源：[src/data/chapter3-canteen.content.json:173](../src/data/chapter3-canteen.content.json#L173)
217. 有人端着豆浆停在路边，给你留出一段空路。
   来源：[src/data/chapter3-canteen.content.json:174](../src/data/chapter3-canteen.content.json#L174)
218. 前面有人推车过马路，纸条已经飞到剧院方向。
   来源：[src/data/chapter3-canteen.content.json:175](../src/data/chapter3-canteen.content.json#L175)
219. 任务：骑车追上纸条
   来源：[src/data/chapter3-canteen.content.json:177](../src/data/chapter3-canteen.content.json#L177)
220. 在车锁旁清除反光并付款。
   来源：[src/data/chapter3-canteen.content.json:179](../src/data/chapter3-canteen.content.json#L179)
221. 骑行时避开前方车辆和行人。
   来源：[src/data/chapter3-canteen.content.json:180](../src/data/chapter3-canteen.content.json#L180)
222. 深色观察可补充查看编号，浅色操作负责清洁与付款。
   来源：[src/data/chapter3-canteen.content.json:181](../src/data/chapter3-canteen.content.json#L181)
223. 在剧院逼停纸条
   来源：[src/data/chapter3-canteen.content.json:185](../src/data/chapter3-canteen.content.json#L185)
224. 纸条进去了，你还没有票。
   来源：[src/data/chapter3-canteen.content.json:187](../src/data/chapter3-canteen.content.json#L187)
225. 深色模式能看到票根、节目单简介里的荧光编号和纸条残影。
   来源：[src/data/chapter3-canteen.content.json:188](../src/data/chapter3-canteen.content.json#L188)
226. 门口还在检票，先找人问问本场的票。
   来源：[src/data/chapter3-canteen.content.json:189](../src/data/chapter3-canteen.content.json#L189)
227. 生锈的柜门钥匙
   来源：[src/data/chapter3-qizhen-fishing.charts.json:10](../src/data/chapter3-qizhen-fishing.charts.json#L10)；[src/scenes/rpg/QizhenLakeScene.ts:169](../src/scenes/rpg/QizhenLakeScene.ts#L169)
228. 教学谱面：音符落到白色判定线时按对应的 A / S / D
   来源：[src/data/chapter3-qizhen-fishing.charts.json:12](../src/data/chapter3-qizhen-fishing.charts.json#L12)
229. 破损网框
   来源：[src/data/chapter3-qizhen-fishing.charts.json:28](../src/data/chapter3-qizhen-fishing.charts.json#L28)；[src/scenes/rpg/QizhenLakeScene.ts:170](../src/scenes/rpg/QizhenLakeScene.ts#L170)
230. 短判定：长条头端到线时按住 A，尾端过线后松开
   来源：[src/data/chapter3-qizhen-fishing.charts.json:30](../src/data/chapter3-qizhen-fishing.charts.json#L30)
231. 小鲤鱼
   来源：[src/data/chapter3-qizhen-fishing.charts.json:42](../src/data/chapter3-qizhen-fishing.charts.json#L42)；[src/data/chapter3-qizhen-lake.content.json:126](../src/data/chapter3-qizhen-lake.content.json#L126)；[src/scenes/rpg/QizhenLakeScene.ts:171](../src/scenes/rpg/QizhenLakeScene.ts#L171)
232. 一次判定：S 音符落到白色判定线时按 S 提竿
   来源：[src/data/chapter3-qizhen-fishing.charts.json:44](../src/data/chapter3-qizhen-fishing.charts.json#L44)
233. 纸条本体
   来源：[src/data/chapter3-qizhen-fishing.charts.json:53](../src/data/chapter3-qizhen-fishing.charts.json#L53)；[src/scenes/rpg/QizhenLakeScene.ts:172](../src/scenes/rpg/QizhenLakeScene.ts#L172)
234. 最终捕纸：保持张力，完整完成八小节
   来源：[src/data/chapter3-qizhen-fishing.charts.json:55](../src/data/chapter3-qizhen-fishing.charts.json#L55)
235. 启真湖
   来源：[src/data/chapter3-qizhen-lake.content.json:3](../src/data/chapter3-qizhen-lake.content.json#L3)
236. 剧场外 · 湖畔方向
   来源：[src/data/chapter3-qizhen-lake.content.json:6](../src/data/chapter3-qizhen-lake.content.json#L6)
237. 湿纸从剧场门边飞出，贴着路面向东移动。
   来源：[src/data/chapter3-qizhen-lake.content.json:11](../src/data/chapter3-qizhen-lake.content.json#L11)
238. 路边只留下几段不连续的水迹。
   来源：[src/data/chapter3-qizhen-lake.content.json:12](../src/data/chapter3-qizhen-lake.content.json#L12)
239. 水迹在湖畔一侧中断，无法直接确认地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:13](../src/data/chapter3-qizhen-lake.content.json#L13)
240. 玩家：它去哪了？
   来源：[src/data/chapter3-qizhen-lake.content.json:17](../src/data/chapter3-qizhen-lake.content.json#L17)
241. 系统：水迹断了，附近没人看清。
   来源：[src/data/chapter3-qizhen-lake.content.json:18](../src/data/chapter3-qizhen-lake.content.json#L18)
242. 玩家：追了一路，还得发帖寻物。
   来源：[src/data/chapter3-qizhen-lake.content.json:19](../src/data/chapter3-qizhen-lake.content.json#L19)
243. 系统：论坛有人路过，馆藏里也留着借阅记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:20](../src/data/chapter3-qizhen-lake.content.json#L20)
244. 【求助】剧院门口飞出一张湿纸，有人看见吗
   来源：[src/data/chapter3-qizhen-lake.content.json:23](../src/data/chapter3-qizhen-lake.content.json#L23)
245. 3楼：刚看到它往有水的地方移动。
   来源：[src/data/chapter3-qizhen-lake.content.json:25](../src/data/chapter3-qizhen-lake.content.json#L25)
246. 8楼：方向靠近桥。
   来源：[src/data/chapter3-qizhen-lake.content.json:26](../src/data/chapter3-qizhen-lake.content.json#L26)
247. 14楼：最后一次看到它时，纸边还在滴水。
   来源：[src/data/chapter3-qizhen-lake.content.json:27](../src/data/chapter3-qizhen-lake.content.json#L27)
248. 系统：论坛线索指向湖区和桥。
   来源：[src/data/chapter3-qizhen-lake.content.json:29](../src/data/chapter3-qizhen-lake.content.json#L29)
249. 玩家：继续找能区分地点的信息。
   来源：[src/data/chapter3-qizhen-lake.content.json:30](../src/data/chapter3-qizhen-lake.content.json#L30)
250. 签到记录夹页
   来源：[src/data/chapter3-qizhen-lake.content.json:33](../src/data/chapter3-qizhen-lake.content.json#L33)
251. 馆藏状态
   来源：[src/data/chapter3-qizhen-lake.content.json:35](../src/data/chapter3-qizhen-lake.content.json#L35)
252. 异常外借
   来源：[src/data/chapter3-qizhen-lake.content.json:35](../src/data/chapter3-qizhen-lake.content.json#L35)
253. 偏高
   来源：[src/data/chapter3-qizhen-lake.content.json:36](../src/data/chapter3-qizhen-lake.content.json#L36)
254. 湿度
   来源：[src/data/chapter3-qizhen-lake.content.json:36](../src/data/chapter3-qizhen-lake.content.json#L36)
255. 定位方式
   来源：[src/data/chapter3-qizhen-lake.content.json:37](../src/data/chapter3-qizhen-lake.content.json#L37)
256. 失效
   来源：[src/data/chapter3-qizhen-lake.content.json:37](../src/data/chapter3-qizhen-lake.content.json#L37)
257. 水面反射区域
   来源：[src/data/chapter3-qizhen-lake.content.json:38](../src/data/chapter3-qizhen-lake.content.json#L38)
258. 最近特征
   来源：[src/data/chapter3-qizhen-lake.content.json:38](../src/data/chapter3-qizhen-lake.content.json#L38)
259. 备注
   来源：[src/data/chapter3-qizhen-lake.content.json:39](../src/data/chapter3-qizhen-lake.content.json#L39)
260. 当前页码只出现在倒影中
   来源：[src/data/chapter3-qizhen-lake.content.json:39](../src/data/chapter3-qizhen-lake.content.json#L39)
261. 玩家：需要在湖面倒影里确认位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:41](../src/data/chapter3-qizhen-lake.content.json#L41)
262. 系统：已记录倒影条件。
   来源：[src/data/chapter3-qizhen-lake.content.json:42](../src/data/chapter3-qizhen-lake.content.json#L42)
263. 朋友：你到哪了？
   来源：[src/data/chapter3-qizhen-lake.content.json:45](../src/data/chapter3-qizhen-lake.content.json#L45)
264. 自动回复：我在跟踪湿纸。
   来源：[src/data/chapter3-qizhen-lake.content.json:46](../src/data/chapter3-qizhen-lake.content.json#L46)
265. 朋友：群里有人在校园湖面拍到了一圈逆风扩散的水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:47](../src/data/chapter3-qizhen-lake.content.json#L47)
266. 已接入 1 条记录，来源还不足以确认地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:50](../src/data/chapter3-qizhen-lake.content.json#L50)
267. 已接入 2 条记录，还缺一个独立来源。
   来源：[src/data/chapter3-qizhen-lake.content.json:51](../src/data/chapter3-qizhen-lake.content.json#L51)
268. 三条记录已对齐。核对交点后才会在校园地图上标记入口。
   来源：[src/data/chapter3-qizhen-lake.content.json:52](../src/data/chapter3-qizhen-lake.content.json#L52)
269. 手机地图：已确认启真湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:53](../src/data/chapter3-qizhen-lake.content.json#L53)
270. 核对结果：桥边、倒影和湖面三条记录指向同一个地点。
   来源：[src/data/chapter3-qizhen-lake.content.json:54](../src/data/chapter3-qizhen-lake.content.json#L54)
271. 核对交点
   来源：[src/data/chapter3-qizhen-lake.content.json:55](../src/data/chapter3-qizhen-lake.content.json#L55)
272. 玩家：前往启真湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:56](../src/data/chapter3-qizhen-lake.content.json#L56)
273. 系统：已建立湖区入口。
   来源：[src/data/chapter3-qizhen-lake.content.json:57](../src/data/chapter3-qizhen-lake.content.json#L57)
274. 玩家：小码头有一艘皮划艇。
   来源：[src/data/chapter3-qizhen-lake.content.json:62](../src/data/chapter3-qizhen-lake.content.json#L62)
275. 系统：船边还缺两件可以划水的工具。
   来源：[src/data/chapter3-qizhen-lake.content.json:63](../src/data/chapter3-qizhen-lake.content.json#L63)
276. 玩家：先完成上船平衡。
   来源：[src/data/chapter3-qizhen-lake.content.json:64](../src/data/chapter3-qizhen-lake.content.json#L64)
277. 任务：先确认皮划艇，再在码头周围寻找两件可以划水的东西。
   来源：[src/data/chapter3-qizhen-lake.content.json:66](../src/data/chapter3-qizhen-lake.content.json#L66)
278. 先查看救生圈旁的器材架。
   来源：[src/data/chapter3-qizhen-lake.content.json:67](../src/data/chapter3-qizhen-lake.content.json#L67)
279. 码头周围有一件细长物体，靠近后再判断能不能使用。
   来源：[src/data/chapter3-qizhen-lake.content.json:68](../src/data/chapter3-qizhen-lake.content.json#L68)
280. 另一件需要从码头现有设施里找。
   来源：[src/data/chapter3-qizhen-lake.content.json:69](../src/data/chapter3-qizhen-lake.content.json#L69)
281. 三件装备收齐后，到码头前端上船，再交替划左右桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:70](../src/data/chapter3-qizhen-lake.content.json#L70)
282. 先把皮划艇划回小码头并上岸。
   来源：[src/data/chapter3-qizhen-lake.content.json:71](../src/data/chapter3-qizhen-lake.content.json#L71)
283. 皮划艇已确认。两支桨没有放在器材架上，继续沿码头寻找。
   来源：[src/data/chapter3-qizhen-lake.content.json:72](../src/data/chapter3-qizhen-lake.content.json#L72)
284. 柳树枝长度合适，已作为左桨。还要找另一侧的桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:73](../src/data/chapter3-qizhen-lake.content.json#L73)
285. 旧三角牌已经拆下，可作为右桨。继续找齐剩余装备。
   来源：[src/data/chapter3-qizhen-lake.content.json:74](../src/data/chapter3-qizhen-lake.content.json#L74)
286. 皮划艇和两支临时桨都已收齐。
   来源：[src/data/chapter3-qizhen-lake.content.json:75](../src/data/chapter3-qizhen-lake.content.json#L75)
287. 值班老师：现在天气不能下水。你要坚持，可以继续靠近码头试试。
   来源：[src/data/chapter3-qizhen-lake.content.json:76](../src/data/chapter3-qizhen-lake.content.json#L76)
288. 值班老师：雨还没停，不能下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:77](../src/data/chapter3-qizhen-lake.content.json#L77)
289. 值班老师：衣服还没干，又来？雨没停，先别下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:78](../src/data/chapter3-qizhen-lake.content.json#L78)
290. 你还是把皮划艇推下水，顶着雨划离了码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:79](../src/data/chapter3-qizhen-lake.content.json#L79)
291. 连续几桨后，侧风把船身压向一边，皮划艇失去平衡。
   来源：[src/data/chapter3-qizhen-lake.content.json:80](../src/data/chapter3-qizhen-lake.content.json#L80)
292. 值班老师和安全员把你救上岸。
   来源：[src/data/chapter3-qizhen-lake.content.json:81](../src/data/chapter3-qizhen-lake.content.json#L81)
293. 值班老师：现在可以下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:82](../src/data/chapter3-qizhen-lake.content.json#L82)；[src/data/chapter3-qizhen-lake.content.json:83](../src/data/chapter3-qizhen-lake.content.json#L83)
294. 这是下过雨的证明
   来源：[src/data/chapter3-qizhen-lake.content.json:84](../src/data/chapter3-qizhen-lake.content.json#L84)
295. 现在天气不能下水。
   来源：[src/data/chapter3-qizhen-lake.content.json:85](../src/data/chapter3-qizhen-lake.content.json#L85)
296. 上船平衡
   来源：[src/data/chapter3-qizhen-lake.content.json:88](../src/data/chapter3-qizhen-lake.content.json#L88)
297. 键盘用 A/左方向键划左桨、D/右方向键划右桨，按住 S 或下方向键再划可后退。触屏在左右桨按钮上向上划为前进、向下划为后退，轻触默认前进。上船时先连续交替前划四次。
   来源：[src/data/chapter3-qizhen-lake.content.json:89](../src/data/chapter3-qizhen-lake.content.json#L89)
298. 连续划同一侧会增大倾角。
   来源：[src/data/chapter3-qizhen-lake.content.json:90](../src/data/chapter3-qizhen-lake.content.json#L90)
299. 后划可以离岸或修正位置；上船平衡仍需交替前划。
   来源：[src/data/chapter3-qizhen-lake.content.json:91](../src/data/chapter3-qizhen-lake.content.json#L91)
300. 皮划艇翻转，已回到最近安全点。
   来源：[src/data/chapter3-qizhen-lake.content.json:92](../src/data/chapter3-qizhen-lake.content.json#L92)
301. 手机和眼镜一起掉进湖里。手机捞回来了，眼镜没找到。
   来源：[src/data/chapter3-qizhen-lake.content.json:93](../src/data/chapter3-qizhen-lake.content.json#L93)
302. 平衡已稳定，可以进入大湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:94](../src/data/chapter3-qizhen-lake.content.json#L94)
303. 上船阶段横向稳定性低。键盘左右桨默认前划，按住下方向键可后划；触屏上划前进、下划后退。先交替前划四次稳住重心。
   来源：[src/data/chapter3-qizhen-lake.content.json:95](../src/data/chapter3-qizhen-lake.content.json#L95)
304. 任务：交替第 1 次，继续保持。
   来源：[src/data/chapter3-qizhen-lake.content.json:97](../src/data/chapter3-qizhen-lake.content.json#L97)
305. 任务：交替第 2 次，船身渐稳。
   来源：[src/data/chapter3-qizhen-lake.content.json:98](../src/data/chapter3-qizhen-lake.content.json#L98)
306. 任务：交替第 3 次，还差一次。
   来源：[src/data/chapter3-qizhen-lake.content.json:99](../src/data/chapter3-qizhen-lake.content.json#L99)
307. 连续划同一侧导致翻船，左右交替可以稳住船身。
   来源：[src/data/chapter3-qizhen-lake.content.json:101](../src/data/chapter3-qizhen-lake.content.json#L101)
308. 船身被边界挡住。船头方向保持不变；键盘按住 S/↓ 再交替划桨，触屏在左右桨上交替向下划，即可倒出。
   来源：[src/data/chapter3-qizhen-lake.content.json:102](../src/data/chapter3-qizhen-lake.content.json#L102)
309. 键盘 A/← 左桨 · D/→ 右桨 · S/↓+桨 后划｜触屏上划前进 · 下划后退
   来源：[src/data/chapter3-qizhen-lake.content.json:103](../src/data/chapter3-qizhen-lake.content.json#L103)
310. 默认前划
   来源：[src/data/chapter3-qizhen-lake.content.json:104](../src/data/chapter3-qizhen-lake.content.json#L104)
311. 后划已按住
   来源：[src/data/chapter3-qizhen-lake.content.json:105](../src/data/chapter3-qizhen-lake.content.json#L105)
312. 后退中
   来源：[src/data/chapter3-qizhen-lake.content.json:106](../src/data/chapter3-qizhen-lake.content.json#L106)
313. 侧倾
   来源：[src/data/chapter3-qizhen-lake.content.json:107](../src/data/chapter3-qizhen-lake.content.json#L107)；[src/data/chapter3-qizhen-lake.content.json:374](../src/data/chapter3-qizhen-lake.content.json#L374)；[src/modules/QizhenJournalModel.ts:61](../src/modules/QizhenJournalModel.ts#L61)
314. 即将翻船
   来源：[src/data/chapter3-qizhen-lake.content.json:108](../src/data/chapter3-qizhen-lake.content.json#L108)
315. 浅色操作：划船、取物、抛竿和组合道具。
   来源：[src/data/chapter3-qizhen-lake.content.json:111](../src/data/chapter3-qizhen-lake.content.json#L111)
316. 深色观察：记录纸条倒影和物品位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:112](../src/data/chapter3-qizhen-lake.content.json#L112)
317. 这个坐标尚未在深色观察中记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:113](../src/data/chapter3-qizhen-lake.content.json#L113)
318. 系统：已在浮排边找到钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:114](../src/data/chapter3-qizhen-lake.content.json#L114)
319. 假纸条已固定在鱼钩上。
   来源：[src/data/chapter3-qizhen-lake.content.json:115](../src/data/chapter3-qizhen-lake.content.json#L115)
320. 没钩住。普通鱼钩挂不牢这张纸，得看看纸上能固定的部位。
   来源：[src/data/chapter3-qizhen-lake.content.json:116](../src/data/chapter3-qizhen-lake.content.json#L116)
321. 任务：去钥匙倒影对应的浅色水面抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:117](../src/data/chapter3-qizhen-lake.content.json#L117)
322. 锈蚀柜钥匙
   来源：[src/data/chapter3-qizhen-lake.content.json:120](../src/data/chapter3-qizhen-lake.content.json#L120)
323. 尼龙绳
   来源：[src/data/chapter3-qizhen-lake.content.json:121](../src/data/chapter3-qizhen-lake.content.json#L121)
324. 断裂网框
   来源：[src/data/chapter3-qizhen-lake.content.json:122](../src/data/chapter3-qizhen-lake.content.json#L122)
325. 临时抄网
   来源：[src/data/chapter3-qizhen-lake.content.json:123](../src/data/chapter3-qizhen-lake.content.json#L123)
326. 密封饲料罐
   来源：[src/data/chapter3-qizhen-lake.content.json:124](../src/data/chapter3-qizhen-lake.content.json#L124)
327. 鱼食颗粒
   来源：[src/data/chapter3-qizhen-lake.content.json:125](../src/data/chapter3-qizhen-lake.content.json#L125)
328. 天鹅磁铁
   来源：[src/data/chapter3-qizhen-lake.content.json:127](../src/data/chapter3-qizhen-lake.content.json#L127)
329. 磁性钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:128](../src/data/chapter3-qizhen-lake.content.json#L128)
330. 检查围栏边遗留的旧饲料盒。
   来源：[src/data/chapter3-qizhen-lake.content.json:131](../src/data/chapter3-qizhen-lake.content.json#L131)
331. 系统：饲料盒处理完成，黑天鹅推来一枚磁性扣。
   来源：[src/data/chapter3-qizhen-lake.content.json:132](../src/data/chapter3-qizhen-lake.content.json#L132)
332. 磁性钓鱼竿已固定纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:133](../src/data/chapter3-qizhen-lake.content.json#L133)
333. 纸条触发围栏机关，黑天鹅进入直河道。
   来源：[src/data/chapter3-qizhen-lake.content.json:134](../src/data/chapter3-qizhen-lake.content.json#L134)
334. 磁性扣的固定环与竿端相配，可以试着装上。
   来源：[src/data/chapter3-qizhen-lake.content.json:135](../src/data/chapter3-qizhen-lake.content.json#L135)
335. 磁性钓鱼竿组合完成。
   来源：[src/data/chapter3-qizhen-lake.content.json:136](../src/data/chapter3-qizhen-lake.content.json#L136)
336. 黑天鹅只接受刚钓到的小鲤鱼。
   来源：[src/data/chapter3-qizhen-lake.content.json:137](../src/data/chapter3-qizhen-lake.content.json#L137)
337. 把黑天鹅磁性扣或钓鱼竿拖进组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:138](../src/data/chapter3-qizhen-lake.content.json#L138)
338. 需要磁性钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:139](../src/data/chapter3-qizhen-lake.content.json#L139)
339. 黑天鹅追逐
   来源：[src/data/chapter3-qizhen-lake.content.json:142](../src/data/chapter3-qizhen-lake.content.json#L142)
340. 交替划桨驶向河道左端。停划或撞上障碍会让黑天鹅追上船体。
   来源：[src/data/chapter3-qizhen-lake.content.json:143](../src/data/chapter3-qizhen-lake.content.json#L143)
341. 黑天鹅撞上船尾，追逐失败。
   来源：[src/data/chapter3-qizhen-lake.content.json:144](../src/data/chapter3-qizhen-lake.content.json#L144)
342. 已回到直河道追逐检查点。
   来源：[src/data/chapter3-qizhen-lake.content.json:145](../src/data/chapter3-qizhen-lake.content.json#L145)
343. 已返回小码头。磁性扣损坏，纸条再次逃离。
   来源：[src/data/chapter3-qizhen-lake.content.json:146](../src/data/chapter3-qizhen-lake.content.json#L146)
344. 已抵达河道另一端。
   来源：[src/data/chapter3-qizhen-lake.content.json:147](../src/data/chapter3-qizhen-lake.content.json#L147)
345. 左端抵达即通过
   来源：[src/data/chapter3-qizhen-lake.content.json:148](../src/data/chapter3-qizhen-lake.content.json#L148)
346. 追击距离
   来源：[src/data/chapter3-qizhen-lake.content.json:149](../src/data/chapter3-qizhen-lake.content.json#L149)
347. 黑天鹅接近船尾
   来源：[src/data/chapter3-qizhen-lake.content.json:150](../src/data/chapter3-qizhen-lake.content.json#L150)
348. 水面出现追击水纹
   来源：[src/data/chapter3-qizhen-lake.content.json:152](../src/data/chapter3-qizhen-lake.content.json#L152)
349. 黑天鹅保持追击
   来源：[src/data/chapter3-qizhen-lake.content.json:153](../src/data/chapter3-qizhen-lake.content.json#L153)
350. 黑天鹅正在抬翼蓄力
   来源：[src/data/chapter3-qizhen-lake.content.json:154](../src/data/chapter3-qizhen-lake.content.json#L154)
351. 黑天鹅短距冲刺
   来源：[src/data/chapter3-qizhen-lake.content.json:155](../src/data/chapter3-qizhen-lake.content.json#L155)
352. 黑天鹅减速调整
   来源：[src/data/chapter3-qizhen-lake.content.json:156](../src/data/chapter3-qizhen-lake.content.json#L156)
353. 距离稳定
   来源：[src/data/chapter3-qizhen-lake.content.json:159](../src/data/chapter3-qizhen-lake.content.json#L159)
354. 距离缩短
   来源：[src/data/chapter3-qizhen-lake.content.json:160](../src/data/chapter3-qizhen-lake.content.json#L160)
355. 即将接触船尾
   来源：[src/data/chapter3-qizhen-lake.content.json:161](../src/data/chapter3-qizhen-lake.content.json#L161)
356. 起始段
   来源：[src/data/chapter3-qizhen-lake.content.json:164](../src/data/chapter3-qizhen-lake.content.json#L164)
357. 河道中段
   来源：[src/data/chapter3-qizhen-lake.content.json:165](../src/data/chapter3-qizhen-lake.content.json#L165)
358. 左岸近段
   来源：[src/data/chapter3-qizhen-lake.content.json:166](../src/data/chapter3-qizhen-lake.content.json#L166)
359. 围栏开了。朝左岸划。
   来源：[src/data/chapter3-qizhen-lake.content.json:169](../src/data/chapter3-qizhen-lake.content.json#L169)
360. 它正在船尾对准航线。继续交替划桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:170](../src/data/chapter3-qizhen-lake.content.json#L170)
361. 左岸快到了。稳住节奏。
   来源：[src/data/chapter3-qizhen-lake.content.json:171](../src/data/chapter3-qizhen-lake.content.json#L171)
362. 玩家：纸条只在倒影里出现。
   来源：[src/data/chapter3-qizhen-lake.content.json:175](../src/data/chapter3-qizhen-lake.content.json#L175)
363. 系统：深色观察可以记录它的坐标。
   来源：[src/data/chapter3-qizhen-lake.content.json:175](../src/data/chapter3-qizhen-lake.content.json#L175)
364. 浅色操作可在浮排边捞起漂浮的钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:176](../src/data/chapter3-qizhen-lake.content.json#L176)
365. 系统：位置已记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:176](../src/data/chapter3-qizhen-lake.content.json#L176)
366. 水纹围成一圈，可以朝那里抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:177](../src/data/chapter3-qizhen-lake.content.json#L177)
367. 深色观察显示纸条倒影和物品位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:178](../src/data/chapter3-qizhen-lake.content.json#L178)
368. 该位置没有记录到目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:179](../src/data/chapter3-qizhen-lake.content.json#L179)
369. 位置已记录；浅色操作可在对应水纹抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:180](../src/data/chapter3-qizhen-lake.content.json#L180)
370. 在启真湖找到纸条
   来源：[src/data/chapter3-qizhen-lake.content.json:181](../src/data/chapter3-qizhen-lake.content.json#L181)；[src/data/chapter3-qizhen-lake.content.json:266](../src/data/chapter3-qizhen-lake.content.json#L266)
371. 旧指示牌已作为右桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:184](../src/data/chapter3-qizhen-lake.content.json#L184)
372. 浮排河道
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)
373. 禁止游泳
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)
374. 小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:185](../src/data/chapter3-qizhen-lake.content.json#L185)；[src/data/chapter3-qizhen-lake.content.json:244](../src/data/chapter3-qizhen-lake.content.json#L244)；[src/data/chapter3-qizhen-lake.content.json:359](../src/data/chapter3-qizhen-lake.content.json#L359)；[src/scenes/rpg/QizhenLakeModel.ts:506](../src/scenes/rpg/QizhenLakeModel.ts#L506)
375. 该操作不符合当前阶段。
   来源：[src/data/chapter3-qizhen-lake.content.json:186](../src/data/chapter3-qizhen-lake.content.json#L186)
376. 右桨已安装。
   来源：[src/data/chapter3-qizhen-lake.content.json:187](../src/data/chapter3-qizhen-lake.content.json#L187)
377. 倒影坐标已记录。
   来源：[src/data/chapter3-qizhen-lake.content.json:188](../src/data/chapter3-qizhen-lake.content.json#L188)
378. 浅色操作可在对应水纹抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:189](../src/data/chapter3-qizhen-lake.content.json#L189)
379. 任务：把假纸条固定到钓鱼竿上作饵。
   来源：[src/data/chapter3-qizhen-lake.content.json:192](../src/data/chapter3-qizhen-lake.content.json#L192)
380. 深色观察可补充确认坐标；浅色操作也可以直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:193](../src/data/chapter3-qizhen-lake.content.json#L193)
381. 系统：假纸条已装成诱饵，固定到鱼钩上。
   来源：[src/data/chapter3-qizhen-lake.content.json:194](../src/data/chapter3-qizhen-lake.content.json#L194)
382. 倒影中出现可抛竿的位置。
   来源：[src/data/chapter3-qizhen-lake.content.json:195](../src/data/chapter3-qizhen-lake.content.json#L195)
383. 先拖入假纸条当饵；直接用普通钓鱼竿只会穿过倒影。
   来源：[src/data/chapter3-qizhen-lake.content.json:196](../src/data/chapter3-qizhen-lake.content.json#L196)
384. 当前为浅色操作。
   来源：[src/data/chapter3-qizhen-lake.content.json:199](../src/data/chapter3-qizhen-lake.content.json#L199)
385. 当前为深色观察。
   来源：[src/data/chapter3-qizhen-lake.content.json:200](../src/data/chapter3-qizhen-lake.content.json#L200)
386. 当前阶段无法切换观察模式。
   来源：[src/data/chapter3-qizhen-lake.content.json:201](../src/data/chapter3-qizhen-lake.content.json#L201)
387. 操作没有命中当前目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:202](../src/data/chapter3-qizhen-lake.content.json#L202)
388. 未命中目标。
   来源：[src/data/chapter3-qizhen-lake.content.json:203](../src/data/chapter3-qizhen-lake.content.json#L203)
389. 目标已命中。
   来源：[src/data/chapter3-qizhen-lake.content.json:204](../src/data/chapter3-qizhen-lake.content.json#L204)
390. 钓起一把生锈的柜门钥匙。
   来源：[src/data/chapter3-qizhen-lake.content.json:207](../src/data/chapter3-qizhen-lake.content.json#L207)
391. 钓起一个破损网框。
   来源：[src/data/chapter3-qizhen-lake.content.json:208](../src/data/chapter3-qizhen-lake.content.json#L208)
392. 码头储物柜打开，里面是一卷尼龙绳。
   来源：[src/data/chapter3-qizhen-lake.content.json:209](../src/data/chapter3-qizhen-lake.content.json#L209)
393. 尼龙绳已经固定到破损网框，临时抄网完成。
   来源：[src/data/chapter3-qizhen-lake.content.json:210](../src/data/chapter3-qizhen-lake.content.json#L210)
394. 临时抄网从浮排下捞出了密封饲料盒。
   来源：[src/data/chapter3-qizhen-lake.content.json:211](../src/data/chapter3-qizhen-lake.content.json#L211)
395. 在浮排硬边撬开盒盖，得到鱼食颗粒。
   来源：[src/data/chapter3-qizhen-lake.content.json:212](../src/data/chapter3-qizhen-lake.content.json#L212)
396. 鱼食颗粒引来一条小鲤鱼。
   来源：[src/data/chapter3-qizhen-lake.content.json:213](../src/data/chapter3-qizhen-lake.content.json#L213)
397. 这里需要生锈的柜门钥匙。
   来源：[src/data/chapter3-qizhen-lake.content.json:214](../src/data/chapter3-qizhen-lake.content.json#L214)
398. 把尼龙绳或破损网框拖进组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:215](../src/data/chapter3-qizhen-lake.content.json#L215)
399. 这里需要临时抄网。
   来源：[src/data/chapter3-qizhen-lake.content.json:216](../src/data/chapter3-qizhen-lake.content.json#L216)
400. 把密封饲料盒拖到硬边上撬开。
   来源：[src/data/chapter3-qizhen-lake.content.json:217](../src/data/chapter3-qizhen-lake.content.json#L217)
401. 把道具拖到场景中对应的真实物体。
   来源：[src/data/chapter3-qizhen-lake.content.json:220](../src/data/chapter3-qizhen-lake.content.json#L220)
402. 没有命中当前可用物体，靠近并对准后重试。
   来源：[src/data/chapter3-qizhen-lake.content.json:221](../src/data/chapter3-qizhen-lake.content.json#L221)
403. 当前为深色观察；使用实体道具需要浅色操作。
   来源：[src/data/chapter3-qizhen-lake.content.json:222](../src/data/chapter3-qizhen-lake.content.json#L222)
404. 目标对了，把皮划艇划到金色水纹外圈附近即可抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:223](../src/data/chapter3-qizhen-lake.content.json#L223)
405. 还够不着，靠近这个物体再试。
   来源：[src/data/chapter3-qizhen-lake.content.json:224](../src/data/chapter3-qizhen-lake.content.json#L224)
406. 当前道具与这个目标不匹配。
   来源：[src/data/chapter3-qizhen-lake.content.json:225](../src/data/chapter3-qizhen-lake.content.json#L225)
407. 确认器材架上的皮划艇
   来源：[src/data/chapter3-qizhen-lake.content.json:228](../src/data/chapter3-qizhen-lake.content.json#L228)
408. 查看花坛边的细长物体
   来源：[src/data/chapter3-qizhen-lake.content.json:229](../src/data/chapter3-qizhen-lake.content.json#L229)
409. 查看设备区的旧设施
   来源：[src/data/chapter3-qizhen-lake.content.json:230](../src/data/chapter3-qizhen-lake.content.json#L230)
410. 从小码头上船
   来源：[src/data/chapter3-qizhen-lake.content.json:231](../src/data/chapter3-qizhen-lake.content.json#L231)
411. 观察倒影位置
   来源：[src/data/chapter3-qizhen-lake.content.json:232](../src/data/chapter3-qizhen-lake.content.json#L232)
412. 捞起钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:233](../src/data/chapter3-qizhen-lake.content.json#L233)
413. 开始节奏钓取
   来源：[src/data/chapter3-qizhen-lake.content.json:234](../src/data/chapter3-qizhen-lake.content.json#L234)
414. 把小鲤鱼喂给黑天鹅
   来源：[src/data/chapter3-qizhen-lake.content.json:235](../src/data/chapter3-qizhen-lake.content.json#L235)
415. 直接抛竿会失败；拖入假纸条作饵
   来源：[src/data/chapter3-qizhen-lake.content.json:236](../src/data/chapter3-qizhen-lake.content.json#L236)
416. 使用当前钓具
   来源：[src/data/chapter3-qizhen-lake.content.json:237](../src/data/chapter3-qizhen-lake.content.json#L237)
417. 冲回小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:238](../src/data/chapter3-qizhen-lake.content.json#L238)
418. 抵达河道左端即自动通过
   来源：[src/data/chapter3-qizhen-lake.content.json:239](../src/data/chapter3-qizhen-lake.content.json#L239)
419. 离开启真湖
   来源：[src/data/chapter3-qizhen-lake.content.json:240](../src/data/chapter3-qizhen-lake.content.json#L240)；[src/scenes/rpg/QizhenLakeModel.ts:383](../src/scenes/rpg/QizhenLakeModel.ts#L383)
420. 当前动作需要浅色操作
   来源：[src/data/chapter3-qizhen-lake.content.json:241](../src/data/chapter3-qizhen-lake.content.json#L241)
421. 启真湖大湖面
   来源：[src/data/chapter3-qizhen-lake.content.json:245](../src/data/chapter3-qizhen-lake.content.json#L245)
422. 浮排直河道
   来源：[src/data/chapter3-qizhen-lake.content.json:246](../src/data/chapter3-qizhen-lake.content.json#L246)
423. 黑天鹅围栏
   来源：[src/data/chapter3-qizhen-lake.content.json:247](../src/data/chapter3-qizhen-lake.content.json#L247)；[src/data/chapter3-qizhen-lake.content.json:361](../src/data/chapter3-qizhen-lake.content.json#L361)；[src/scenes/rpg/QizhenLakeModel.ts:533](../src/scenes/rpg/QizhenLakeModel.ts#L533)
424. 完成上船平衡后才能划向大湖。
   来源：[src/data/chapter3-qizhen-lake.content.json:250](../src/data/chapter3-qizhen-lake.content.json#L250)
425. 钓到小鲤鱼后才能前往黑天鹅围栏。
   来源：[src/data/chapter3-qizhen-lake.content.json:251](../src/data/chapter3-qizhen-lake.content.json#L251)
426. 尼龙绳和破损网框尚未组合成临时抄网。
   来源：[src/data/chapter3-qizhen-lake.content.json:252](../src/data/chapter3-qizhen-lake.content.json#L252)
427. 浮排河道已经处理完。
   来源：[src/data/chapter3-qizhen-lake.content.json:253](../src/data/chapter3-qizhen-lake.content.json#L253)
428. 围栏机关尚未触发，需要先用磁性钓鱼竿取出纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:254](../src/data/chapter3-qizhen-lake.content.json#L254)
429. 密封饲料盒还没捞起并打开。
   来源：[src/data/chapter3-qizhen-lake.content.json:255](../src/data/chapter3-qizhen-lake.content.json#L255)
430. 在小码头分别找齐皮划艇和左右桨
   来源：[src/data/chapter3-qizhen-lake.content.json:258](../src/data/chapter3-qizhen-lake.content.json#L258)
431. 交替划左右桨完成上船
   来源：[src/data/chapter3-qizhen-lake.content.json:259](../src/data/chapter3-qizhen-lake.content.json#L259)
432. 切到深色观察，记录倒影位置
   来源：[src/data/chapter3-qizhen-lake.content.json:260](../src/data/chapter3-qizhen-lake.content.json#L260)
433. 找能把纸条带回来的工具
   来源：[src/data/chapter3-qizhen-lake.content.json:261](../src/data/chapter3-qizhen-lake.content.json#L261)
434. 处理围栏边的旧饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:262](../src/data/chapter3-qizhen-lake.content.json#L262)
435. 用磁性钓鱼竿取出纸条
   来源：[src/data/chapter3-qizhen-lake.content.json:263](../src/data/chapter3-qizhen-lake.content.json#L263)
436. 沿直河道逃回小码头
   来源：[src/data/chapter3-qizhen-lake.content.json:264](../src/data/chapter3-qizhen-lake.content.json#L264)
437. 上岸，看看手机里的新消息
   来源：[src/data/chapter3-qizhen-lake.content.json:265](../src/data/chapter3-qizhen-lake.content.json#L265)
438. 深色观察用于记录坐标，浅色操作可直接尝试抛竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:268](../src/data/chapter3-qizhen-lake.content.json#L268)
439. 普通鱼钩无法直接固定纸条。
   来源：[src/data/chapter3-qizhen-lake.content.json:269](../src/data/chapter3-qizhen-lake.content.json#L269)
440. 捞上来的东西可以展开查看，留意能连接、承托或吸附的部位。
   来源：[src/data/chapter3-qizhen-lake.content.json:270](../src/data/chapter3-qizhen-lake.content.json#L270)
441. 在大湖面捞起钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:274](../src/data/chapter3-qizhen-lake.content.json#L274)
442. 浅色操作时，在大湖面浮排边捞起钓鱼竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:275](../src/data/chapter3-qizhen-lake.content.json#L275)
443. 深色观察可先记录纸条倒影，但不限制捞竿。
   来源：[src/data/chapter3-qizhen-lake.content.json:275](../src/data/chapter3-qizhen-lake.content.json#L275)
444. 把假纸条装上钓鱼竿作饵
   来源：[src/data/chapter3-qizhen-lake.content.json:278](../src/data/chapter3-qizhen-lake.content.json#L278)
445. 把假纸条拖到大湖面的纸条倒影上装饵。
   来源：[src/data/chapter3-qizhen-lake.content.json:279](../src/data/chapter3-qizhen-lake.content.json#L279)
446. 直接对倒影抛竿只会穿过去。
   来源：[src/data/chapter3-qizhen-lake.content.json:279](../src/data/chapter3-qizhen-lake.content.json#L279)
447. 钓起水下的小金属物
   来源：[src/data/chapter3-qizhen-lake.content.json:282](../src/data/chapter3-qizhen-lake.content.json#L282)
448. 浅色操作时，皮划艇到达金色水纹外圈附近后，把钓鱼竿拖入水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
449. 深色观察可记录钥匙倒影坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
450. 音符沿 A、S、D 三列向下移动；短块到白线时点按，长条头端到线时按住，尾端过线后松开。
   来源：[src/data/chapter3-qizhen-lake.content.json:283](../src/data/chapter3-qizhen-lake.content.json#L283)
451. 用钥匙打开码头储物柜
   来源：[src/data/chapter3-qizhen-lake.content.json:286](../src/data/chapter3-qizhen-lake.content.json#L286)
452. 带着生锈的柜门钥匙回小码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:287](../src/data/chapter3-qizhen-lake.content.json#L287)
453. 靠近储物柜，把钥匙拖到锁孔。
   来源：[src/data/chapter3-qizhen-lake.content.json:287](../src/data/chapter3-qizhen-lake.content.json#L287)
454. 查看旧木桩下的框状物
   来源：[src/data/chapter3-qizhen-lake.content.json:290](../src/data/chapter3-qizhen-lake.content.json#L290)
455. 浅色操作时，皮划艇到达金色网框水纹外圈附近后开始节奏钓取。
   来源：[src/data/chapter3-qizhen-lake.content.json:291](../src/data/chapter3-qizhen-lake.content.json#L291)
456. 深色观察可记录网框倒影坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:291](../src/data/chapter3-qizhen-lake.content.json#L291)
457. 组合尼龙绳和破损网框
   来源：[src/data/chapter3-qizhen-lake.content.json:294](../src/data/chapter3-qizhen-lake.content.json#L294)
458. 把尼龙绳或破损网框拖进组合位，也可以在道具栏内直接组合。
   来源：[src/data/chapter3-qizhen-lake.content.json:295](../src/data/chapter3-qizhen-lake.content.json#L295)
459. 浮标组合位在大湖面。
   来源：[src/data/chapter3-qizhen-lake.content.json:295](../src/data/chapter3-qizhen-lake.content.json#L295)
460. 用临时抄网捞起密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:298](../src/data/chapter3-qizhen-lake.content.json#L298)
461. 抄网可以伸到浮排下方，托住那个罐子。
   来源：[src/data/chapter3-qizhen-lake.content.json:299](../src/data/chapter3-qizhen-lake.content.json#L299)
462. 从大湖北侧进入浮排直河道。
   来源：[src/data/chapter3-qizhen-lake.content.json:299](../src/data/chapter3-qizhen-lake.content.json#L299)
463. 在浮排硬边撬开密封饲料盒
   来源：[src/data/chapter3-qizhen-lake.content.json:302](../src/data/chapter3-qizhen-lake.content.json#L302)
464. 把密封饲料盒拖到浮排硬边开罐位。
   来源：[src/data/chapter3-qizhen-lake.content.json:303](../src/data/chapter3-qizhen-lake.content.json#L303)
465. 密封饲料盒要借浮排硬边撬开。
   来源：[src/data/chapter3-qizhen-lake.content.json:303](../src/data/chapter3-qizhen-lake.content.json#L303)
466. 用鱼饲料颗粒钓一条小鲤鱼
   来源：[src/data/chapter3-qizhen-lake.content.json:306](../src/data/chapter3-qizhen-lake.content.json#L306)
467. 浅色操作时，皮划艇到达金色鱼群水纹外圈附近后，把鱼饲料颗粒拖入水纹。
   来源：[src/data/chapter3-qizhen-lake.content.json:307](../src/data/chapter3-qizhen-lake.content.json#L307)
468. 深色观察可记录鱼群水纹坐标，也可在浅色操作直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:307](../src/data/chapter3-qizhen-lake.content.json#L307)
469. 组合磁性扣和钓鱼竿
   来源：[src/data/chapter3-qizhen-lake.content.json:310](../src/data/chapter3-qizhen-lake.content.json#L310)
470. 把黑天鹅磁性扣拖到钓鱼竿上，或去船头磁吸组合位。
   来源：[src/data/chapter3-qizhen-lake.content.json:311](../src/data/chapter3-qizhen-lake.content.json#L311)
471. 组合位在黑天鹅围栏外的水面。
   来源：[src/data/chapter3-qizhen-lake.content.json:311](../src/data/chapter3-qizhen-lake.content.json#L311)
472. 用磁性钓鱼竿吸住纸条本体
   来源：[src/data/chapter3-qizhen-lake.content.json:314](../src/data/chapter3-qizhen-lake.content.json#L314)
473. 皮划艇到达金色纸条水纹外圈附近后，把磁性钓鱼竿拖入水纹，完成最终八小节节奏钓取。
   来源：[src/data/chapter3-qizhen-lake.content.json:315](../src/data/chapter3-qizhen-lake.content.json#L315)
474. 深色观察可确认纸条坐标；浅色操作可直接尝试。
   来源：[src/data/chapter3-qizhen-lake.content.json:315](../src/data/chapter3-qizhen-lake.content.json#L315)
475. 【记录】启真湖首航：船是捡的，桨是凑的，人是活的
   来源：[src/data/chapter3-qizhen-lake.content.json:321](../src/data/chapter3-qizhen-lake.content.json#L321)
476. 启真湖划船一圈没翻，特此发帖留念
   来源：[src/data/chapter3-qizhen-lake.content.json:322](../src/data/chapter3-qizhen-lake.content.json#L322)
477. 在湖心漂了一下午，课表上没有这一项
   来源：[src/data/chapter3-qizhen-lake.content.json:323](../src/data/chapter3-qizhen-lake.content.json#L323)
478. 人还在湖上，船还浮着
   来源：[src/data/chapter3-qizhen-lake.content.json:326](../src/data/chapter3-qizhen-lake.content.json#L326)
479. 两条胳膊已报废，但不亏
   来源：[src/data/chapter3-qizhen-lake.content.json:327](../src/data/chapter3-qizhen-lake.content.json#L327)
480. 上岸再整理，先占个楼
   来源：[src/data/chapter3-qizhen-lake.content.json:328](../src/data/chapter3-qizhen-lake.content.json#L328)
481. 出发位打卡。临时装备已经固定，先试着划离码头。
   来源：[src/data/chapter3-qizhen-lake.content.json:332](../src/data/chapter3-qizhen-lake.content.json#L332)
482. 回码头补一张。能完整地划回来，我自己都没想到。
   来源：[src/data/chapter3-qizhen-lake.content.json:333](../src/data/chapter3-qizhen-lake.content.json#L333)
483. 器材架空了一半，这艘皮划艇暂时归我保管。
   来源：[src/data/chapter3-qizhen-lake.content.json:334](../src/data/chapter3-qizhen-lake.content.json#L334)
484. 水静下来才拍清倒影，没敢再划桨。
   来源：[src/data/chapter3-qizhen-lake.content.json:337](../src/data/chapter3-qizhen-lake.content.json#L337)
485. 刚按快门就来一圈水纹，倒影当场断开，凑合看。
   来源：[src/data/chapter3-qizhen-lake.content.json:338](../src/data/chapter3-qizhen-lake.content.json#L338)
486. 为了等水静下来，在湖心多漂了十分钟，值。
   来源：[src/data/chapter3-qizhen-lake.content.json:339](../src/data/chapter3-qizhen-lake.content.json#L339)
487. 黑天鹅隔着围栏盯着我看了很久，没敢再靠近。
   来源：[src/data/chapter3-qizhen-lake.content.json:342](../src/data/chapter3-qizhen-lake.content.json#L342)
488. 按下快门那一下它正好转头，气场很足。
   来源：[src/data/chapter3-qizhen-lake.content.json:343](../src/data/chapter3-qizhen-lake.content.json#L343)
489. 围栏空了，水面只剩一圈还没散的水痕。
   来源：[src/data/chapter3-qizhen-lake.content.json:344](../src/data/chapter3-qizhen-lake.content.json#L344)
490. 构图在线
   来源：[src/data/chapter3-qizhen-lake.content.json:348](../src/data/chapter3-qizhen-lake.content.json#L348)
491. 拍歪了
   来源：[src/data/chapter3-qizhen-lake.content.json:349](../src/data/chapter3-qizhen-lake.content.json#L349)
492. 速度太快
   来源：[src/data/chapter3-qizhen-lake.content.json:350](../src/data/chapter3-qizhen-lake.content.json#L350)
493. 水纹清楚
   来源：[src/data/chapter3-qizhen-lake.content.json:351](../src/data/chapter3-qizhen-lake.content.json#L351)
494. 水纹断了
   来源：[src/data/chapter3-qizhen-lake.content.json:352](../src/data/chapter3-qizhen-lake.content.json#L352)
495. 黑天鹅贴脸
   来源：[src/data/chapter3-qizhen-lake.content.json:353](../src/data/chapter3-qizhen-lake.content.json#L353)
496. 黑天鹅在远处
   来源：[src/data/chapter3-qizhen-lake.content.json:354](../src/data/chapter3-qizhen-lake.content.json#L354)
497. 鹅去栏空
   来源：[src/data/chapter3-qizhen-lake.content.json:355](../src/data/chapter3-qizhen-lake.content.json#L355)
498. 湖心
   来源：[src/data/chapter3-qizhen-lake.content.json:358](../src/data/chapter3-qizhen-lake.content.json#L358)；[src/scenes/rpg/QizhenLakeModel.ts:495](../src/scenes/rpg/QizhenLakeModel.ts#L495)
499. 湖心倒影
   来源：[src/data/chapter3-qizhen-lake.content.json:360](../src/data/chapter3-qizhen-lake.content.json#L360)
500. 启真湖记录相机
   来源：[src/data/chapter3-qizhen-lake.content.json:364](../src/data/chapter3-qizhen-lake.content.json#L364)
501. 拍摄
   来源：[src/data/chapter3-qizhen-lake.content.json:365](../src/data/chapter3-qizhen-lake.content.json#L365)；[src/modules/QizhenJournalModel.ts:52](../src/modules/QizhenJournalModel.ts#L52)
502. 收起相机
   来源：[src/data/chapter3-qizhen-lake.content.json:366](../src/data/chapter3-qizhen-lake.content.json#L366)；[src/modules/QizhenJournalModel.ts:53](../src/modules/QizhenJournalModel.ts#L53)
503. 重拍
   来源：[src/data/chapter3-qizhen-lake.content.json:367](../src/data/chapter3-qizhen-lake.content.json#L367)；[src/modules/QizhenJournalModel.ts:54](../src/modules/QizhenJournalModel.ts#L54)
504. 选择主帖标题
   来源：[src/data/chapter3-qizhen-lake.content.json:368](../src/data/chapter3-qizhen-lake.content.json#L368)；[src/modules/QizhenJournalModel.ts:55](../src/modules/QizhenJournalModel.ts#L55)
505. 选择主帖状态
   来源：[src/data/chapter3-qizhen-lake.content.json:369](../src/data/chapter3-qizhen-lake.content.json#L369)；[src/modules/QizhenJournalModel.ts:56](../src/modules/QizhenJournalModel.ts#L56)
506. 选择补拍说明
   来源：[src/data/chapter3-qizhen-lake.content.json:370](../src/data/chapter3-qizhen-lake.content.json#L370)；[src/modules/QizhenJournalModel.ts:57](../src/modules/QizhenJournalModel.ts#L57)
507. 存为草稿
   来源：[src/data/chapter3-qizhen-lake.content.json:371](../src/data/chapter3-qizhen-lake.content.json#L371)；[src/modules/QizhenJournalModel.ts:58](../src/modules/QizhenJournalModel.ts#L58)
508. 草稿已保存,可前往 CC98 发布。
   来源：[src/data/chapter3-qizhen-lake.content.json:372](../src/data/chapter3-qizhen-lake.content.json#L372)；[src/modules/QizhenJournalModel.ts:59](../src/modules/QizhenJournalModel.ts#L59)
509. 速度
   来源：[src/data/chapter3-qizhen-lake.content.json:373](../src/data/chapter3-qizhen-lake.content.json#L373)；[src/modules/QizhenJournalModel.ts:60](../src/modules/QizhenJournalModel.ts#L60)
510. 船速和侧倾都会写进照片标签。想拍干净点，先把船稳下来再按快门。
   来源：[src/data/chapter3-qizhen-lake.content.json:375](../src/data/chapter3-qizhen-lake.content.json#L375)
511. 校园生活
   来源：[src/data/chapter3-qizhen-lake.content.json:378](../src/data/chapter3-qizhen-lake.content.json#L378)；[src/data/chapter3-theater.content.json:20](../src/data/chapter3-theater.content.json#L20)
512. 楼主
   来源：[src/data/chapter3-qizhen-lake.content.json:379](../src/data/chapter3-qizhen-lake.content.json#L379)；[src/modules/QizhenJournalModel.ts:81](../src/modules/QizhenJournalModel.ts#L81)
513. 草稿
   来源：[src/data/chapter3-qizhen-lake.content.json:380](../src/data/chapter3-qizhen-lake.content.json#L380)；[src/modules/QizhenJournalModel.ts:82](../src/modules/QizhenJournalModel.ts#L82)
514. 发布主帖
   来源：[src/data/chapter3-qizhen-lake.content.json:381](../src/data/chapter3-qizhen-lake.content.json#L381)；[src/modules/QizhenJournalModel.ts:83](../src/modules/QizhenJournalModel.ts#L83)
515. 发布中…
   来源：[src/data/chapter3-qizhen-lake.content.json:382](../src/data/chapter3-qizhen-lake.content.json#L382)；[src/modules/QizhenJournalModel.ts:84](../src/modules/QizhenJournalModel.ts#L84)
516. 追加到帖子
   来源：[src/data/chapter3-qizhen-lake.content.json:383](../src/data/chapter3-qizhen-lake.content.json#L383)；[src/modules/QizhenJournalModel.ts:85](../src/modules/QizhenJournalModel.ts#L85)
517. 只看楼主
   来源：[src/data/chapter3-qizhen-lake.content.json:384](../src/data/chapter3-qizhen-lake.content.json#L384)；[src/modules/QizhenJournalModel.ts:86](../src/modules/QizhenJournalModel.ts#L86)
518. 查看全部
   来源：[src/data/chapter3-qizhen-lake.content.json:385](../src/data/chapter3-qizhen-lake.content.json#L385)；[src/modules/QizhenJournalModel.ts:87](../src/modules/QizhenJournalModel.ts#L87)
519. 继续补充
   来源：[src/data/chapter3-qizhen-lake.content.json:386](../src/data/chapter3-qizhen-lake.content.json#L386)；[src/modules/QizhenJournalModel.ts:88](../src/modules/QizhenJournalModel.ts#L88)
520. 返回湖面
   来源：[src/data/chapter3-qizhen-lake.content.json:387](../src/data/chapter3-qizhen-lake.content.json#L387)；[src/data/chapter3-qizhen-lake.content.json:395](../src/data/chapter3-qizhen-lake.content.json#L395)；[src/modules/QizhenJournalModel.ts:89](../src/modules/QizhenJournalModel.ts#L89)；[src/modules/QizhenJournalModel.ts:102](../src/modules/QizhenJournalModel.ts#L102)
521. 帖子已归档,仅供查看。
   来源：[src/data/chapter3-qizhen-lake.content.json:388](../src/data/chapter3-qizhen-lake.content.json#L388)；[src/modules/QizhenJournalModel.ts:90](../src/modules/QizhenJournalModel.ts#L90)
522. 湖心主图
   来源：[src/data/chapter3-qizhen-lake.content.json:389](../src/data/chapter3-qizhen-lake.content.json#L389)；[src/modules/QizhenJournalModel.ts:91](../src/modules/QizhenJournalModel.ts#L91)
523. 补拍照片
   来源：[src/data/chapter3-qizhen-lake.content.json:390](../src/data/chapter3-qizhen-lake.content.json#L390)；[src/modules/QizhenJournalModel.ts:92](../src/modules/QizhenJournalModel.ts#L92)
524. 发布失败：不在校园网
   来源：[src/data/chapter3-qizhen-lake.content.json:392](../src/data/chapter3-qizhen-lake.content.json#L392)
525. CC98 仅在校园网（ZJUWLAN）下可以发帖。照片、标题和说明都已保留，网络恢复后请手动重试，不会自动补发。
   来源：[src/data/chapter3-qizhen-lake.content.json:393](../src/data/chapter3-qizhen-lake.content.json#L393)
526. 打开控制中心
   来源：[src/data/chapter3-qizhen-lake.content.json:394](../src/data/chapter3-qizhen-lake.content.json#L394)；[src/modules/QizhenJournalModel.ts:101](../src/modules/QizhenJournalModel.ts#L101)
527. 继续编辑
   来源：[src/data/chapter3-qizhen-lake.content.json:396](../src/data/chapter3-qizhen-lake.content.json#L396)；[src/modules/QizhenJournalModel.ts:103](../src/modules/QizhenJournalModel.ts#L103)
528. bd。楼主发帖时间已记录，比我昨晚的打印队列靠前。
   来源：[src/data/chapter3-qizhen-lake.content.json:401](../src/data/chapter3-qizhen-lake.content.json#L401)
529. 下午路过启真湖看见这艘船了，湖心风不小，照片倒是拍得挺稳。
   来源：[src/data/chapter3-qizhen-lake.content.json:402](../src/data/chapter3-qizhen-lake.content.json#L402)
530. 右边那支桨看着眼熟，像是器材架旁边立了很久的旧牌子。
   来源：[src/data/chapter3-qizhen-lake.content.json:403](../src/data/chapter3-qizhen-lake.content.json#L403)
531. 每天骑车绕湖一圈，头回见有人划这个。先收藏，翻了记得回来更新。
   来源：[src/data/chapter3-qizhen-lake.content.json:404](../src/data/chapter3-qizhen-lake.content.json#L404)
532. 余额 0.06 元，租船押金都付不起，看楼主发帖就当自己划过。
   来源：[src/data/chapter3-qizhen-lake.content.json:405](../src/data/chapter3-qizhen-lake.content.json#L405)
533. 无审核权限，仅存档湖心主图一张。船的来源建议楼主自行补充说明。
   来源：[src/data/chapter3-qizhen-lake.content.json:406](../src/data/chapter3-qizhen-lake.content.json#L406)
534. 这个码头我天天推车经过，器材架今天确实空了一格，原来在你这。
   来源：[src/data/chapter3-qizhen-lake.content.json:409](../src/data/chapter3-qizhen-lake.content.json#L409)
535. 架空位 +1，东西记得还。上次有人借桨借了半个学期。
   来源：[src/data/chapter3-qizhen-lake.content.json:410](../src/data/chapter3-qizhen-lake.content.json#L410)
536. 码头木板数过了，翘起来三块，踩中间那块最稳，不用谢。
   来源：[src/data/chapter3-qizhen-lake.content.json:411](../src/data/chapter3-qizhen-lake.content.json#L411)
537. 出发位与回位经比对为同一码头，行程闭环，予以存档。
   来源：[src/data/chapter3-qizhen-lake.content.json:412](../src/data/chapter3-qizhen-lake.content.json#L412)
538. 这张倒影我在对岸目击过拍摄过程，水面确实静了一阵，就一阵。
   来源：[src/data/chapter3-qizhen-lake.content.json:415](../src/data/chapter3-qizhen-lake.content.json#L415)
539. 等水静下来要多久？我在岸边计时到五分钟就放弃了，楼主有耐心。
   来源：[src/data/chapter3-qizhen-lake.content.json:416](../src/data/chapter3-qizhen-lake.content.json#L416)
540. 湖心倒影，老港人都知道这个机位。下班绕过去看一眼，血压能低点。
   来源：[src/data/chapter3-qizhen-lake.content.json:417](../src/data/chapter3-qizhen-lake.content.json#L417)
541. 倒影中船身与人物比例一致，未发现修图痕迹，通过。
   来源：[src/data/chapter3-qizhen-lake.content.json:418](../src/data/chapter3-qizhen-lake.content.json#L418)
542. 黑天鹅盯人是常规项目，建议不要长时间对视，赢不了。
   来源：[src/data/chapter3-qizhen-lake.content.json:421](../src/data/chapter3-qizhen-lake.content.json#L421)
543. 它转头那下我正好路过。楼主退得挺快，照片居然没糊。
   来源：[src/data/chapter3-qizhen-lake.content.json:422](../src/data/chapter3-qizhen-lake.content.json#L422)
544. 这鹅一天的伙食费超过我的余额，楼主别跟它比气场，比不过。
   来源：[src/data/chapter3-qizhen-lake.content.json:423](../src/data/chapter3-qizhen-lake.content.json#L423)
545. 空围栏这张亦已存档。水痕未散，后续动向保持观察。
   来源：[src/data/chapter3-qizhen-lake.content.json:424](../src/data/chapter3-qizhen-lake.content.json#L424)
546. system
   来源：[src/data/chapter3-story-lines.json:18](../src/data/chapter3-story-lines.json#L18)；[src/data/chapter3-story-lines.json:27](../src/data/chapter3-story-lines.json#L27)；[src/data/chapter3-story-lines.json:36](../src/data/chapter3-story-lines.json#L36)；[src/data/chapter3-story-lines.json:45](../src/data/chapter3-story-lines.json#L45)；[src/data/chapter3-story-lines.json:54](../src/data/chapter3-story-lines.json#L54)；[src/data/chapter3-story-lines.json:63](../src/data/chapter3-story-lines.json#L63)；[src/data/chapter3-story-lines.json:72](../src/data/chapter3-story-lines.json#L72)；[src/data/chapter3-story-lines.json:81](../src/data/chapter3-story-lines.json#L81)；[src/data/chapter3-story-lines.json:108](../src/data/chapter3-story-lines.json#L108)；[src/data/chapter3-story-lines.json:126](../src/data/chapter3-story-lines.json#L126)；[src/data/chapter3-story-lines.json:135](../src/data/chapter3-story-lines.json#L135)；[src/data/chapter3-story-lines.json:144](../src/data/chapter3-story-lines.json#L144)；[src/data/chapter3-story-lines.json:162](../src/data/chapter3-story-lines.json#L162)；[src/data/chapter3-story-lines.json:171](../src/data/chapter3-story-lines.json#L171)；[src/data/chapter3-story-lines.json:180](../src/data/chapter3-story-lines.json#L180)；[src/data/chapter3-story-lines.json:189](../src/data/chapter3-story-lines.json#L189)；[src/data/chapter3-story-lines.json:198](../src/data/chapter3-story-lines.json#L198)；[src/data/chapter3-story-lines.json:207](../src/data/chapter3-story-lines.json#L207)；[src/data/chapter3-story-lines.json:216](../src/data/chapter3-story-lines.json#L216)；[src/data/chapter3-story-lines.json:225](../src/data/chapter3-story-lines.json#L225)；[src/data/chapter3-story-lines.json:234](../src/data/chapter3-story-lines.json#L234)；[src/data/chapter3-story-lines.json:243](../src/data/chapter3-story-lines.json#L243)；[src/data/chapter3-story-lines.json:252](../src/data/chapter3-story-lines.json#L252)；[src/data/chapter3-story-lines.json:261](../src/data/chapter3-story-lines.json#L261)；[src/data/chapter3-story-lines.json:270](../src/data/chapter3-story-lines.json#L270)；[src/data/chapter3-story-lines.json:279](../src/data/chapter3-story-lines.json#L279)；[src/data/chapter3-story-lines.json:288](../src/data/chapter3-story-lines.json#L288)；[src/data/chapter3-story-lines.json:297](../src/data/chapter3-story-lines.json#L297)；[src/data/chapter3-story-lines.json:306](../src/data/chapter3-story-lines.json#L306)；[src/data/chapter3-story-lines.json:315](../src/data/chapter3-story-lines.json#L315)；[src/data/chapter3-story-lines.json:333](../src/data/chapter3-story-lines.json#L333)；[src/data/chapter3-story-lines.json:342](../src/data/chapter3-story-lines.json#L342)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:67](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L67)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:79](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L79)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:85](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L85)；[src/scenes/rpg/CanteenInteriorScene.ts:2008](../src/scenes/rpg/CanteenInteriorScene.ts#L2008)；[src/scenes/rpg/CanteenInteriorScene.ts:2012](../src/scenes/rpg/CanteenInteriorScene.ts#L2012)；[src/scenes/rpg/CanteenInteriorScene.ts:2044](../src/scenes/rpg/CanteenInteriorScene.ts#L2044)；[src/scenes/rpg/CanteenInteriorScene.ts:2048](../src/scenes/rpg/CanteenInteriorScene.ts#L2048)；[src/scenes/rpg/CanteenInteriorScene.ts:2057](../src/scenes/rpg/CanteenInteriorScene.ts#L2057)；[src/scenes/rpg/CanteenInteriorScene.ts:2066](../src/scenes/rpg/CanteenInteriorScene.ts#L2066)；[src/scenes/rpg/CanteenInteriorScene.ts:2082](../src/scenes/rpg/CanteenInteriorScene.ts#L2082)；[src/scenes/rpg/CanteenInteriorScene.ts:2086](../src/scenes/rpg/CanteenInteriorScene.ts#L2086)；[src/scenes/rpg/CanteenInteriorScene.ts:2100](../src/scenes/rpg/CanteenInteriorScene.ts#L2100)；[src/scenes/rpg/CanteenInteriorScene.ts:2108](../src/scenes/rpg/CanteenInteriorScene.ts#L2108)；[src/scenes/rpg/CanteenInteriorScene.ts:2112](../src/scenes/rpg/CanteenInteriorScene.ts#L2112)；[src/scenes/rpg/CanteenInteriorScene.ts:2116](../src/scenes/rpg/CanteenInteriorScene.ts#L2116)；[src/scenes/rpg/CanteenInteriorScene.ts:2145](../src/scenes/rpg/CanteenInteriorScene.ts#L2145)；[src/scenes/rpg/CanteenInteriorScene.ts:2149](../src/scenes/rpg/CanteenInteriorScene.ts#L2149)；[src/scenes/rpg/CanteenInteriorScene.ts:2326](../src/scenes/rpg/CanteenInteriorScene.ts#L2326)；[src/scenes/rpg/CanteenInteriorScene.ts:3290](../src/scenes/rpg/CanteenInteriorScene.ts#L3290)；[src/scenes/rpg/CanteenInteriorScene.ts:3366](../src/scenes/rpg/CanteenInteriorScene.ts#L3366)；[src/scenes/rpg/CanteenInteriorScene.ts:3718](../src/scenes/rpg/CanteenInteriorScene.ts#L3718)；[src/scenes/rpg/CanteenInteriorScene.ts:3768](../src/scenes/rpg/CanteenInteriorScene.ts#L3768)；[src/scenes/rpg/CanteenInteriorScene.ts:3858](../src/scenes/rpg/CanteenInteriorScene.ts#L3858)；[src/scenes/rpg/QizhenLakeScene.ts:587](../src/scenes/rpg/QizhenLakeScene.ts#L587)；[src/scenes/rpg/QizhenLakeScene.ts:837](../src/scenes/rpg/QizhenLakeScene.ts#L837)；[src/scenes/rpg/QizhenLakeScene.ts:1008](../src/scenes/rpg/QizhenLakeScene.ts#L1008)；[src/scenes/rpg/QizhenLakeScene.ts:1041](../src/scenes/rpg/QizhenLakeScene.ts#L1041)；[src/scenes/rpg/QizhenLakeScene.ts:1829](../src/scenes/rpg/QizhenLakeScene.ts#L1829)；[src/scenes/rpg/QizhenLakeScene.ts:2108](../src/scenes/rpg/QizhenLakeScene.ts#L2108)；[src/scenes/rpg/QizhenLakeScene.ts:2164](../src/scenes/rpg/QizhenLakeScene.ts#L2164)；[src/scenes/rpg/QizhenLakeScene.ts:2268](../src/scenes/rpg/QizhenLakeScene.ts#L2268)；[src/scenes/rpg/QizhenLakeScene.ts:2469](../src/scenes/rpg/QizhenLakeScene.ts#L2469)；[src/scenes/rpg/QizhenLakeScene.ts:2473](../src/scenes/rpg/QizhenLakeScene.ts#L2473)；[src/scenes/rpg/QizhenLakeScene.ts:2491](../src/scenes/rpg/QizhenLakeScene.ts#L2491)；[src/scenes/rpg/QizhenLakeScene.ts:2495](../src/scenes/rpg/QizhenLakeScene.ts#L2495)；[src/scenes/rpg/QizhenLakeScene.ts:2501](../src/scenes/rpg/QizhenLakeScene.ts#L2501)；[src/scenes/rpg/QizhenLakeScene.ts:2515](../src/scenes/rpg/QizhenLakeScene.ts#L2515)；[src/scenes/rpg/QizhenLakeScene.ts:2530](../src/scenes/rpg/QizhenLakeScene.ts#L2530)；[src/scenes/rpg/QizhenLakeScene.ts:2589](../src/scenes/rpg/QizhenLakeScene.ts#L2589)；[src/scenes/rpg/QizhenLakeScene.ts:2897](../src/scenes/rpg/QizhenLakeScene.ts#L2897)；[src/scenes/rpg/QizhenLakeScene.ts:2903](../src/scenes/rpg/QizhenLakeScene.ts#L2903)；[src/scenes/rpg/QizhenLakeScene.ts:2907](../src/scenes/rpg/QizhenLakeScene.ts#L2907)；[src/scenes/rpg/QizhenLakeScene.ts:2911](../src/scenes/rpg/QizhenLakeScene.ts#L2911)；[src/scenes/rpg/QizhenLakeScene.ts:2915](../src/scenes/rpg/QizhenLakeScene.ts#L2915)；[src/scenes/rpg/QizhenLakeScene.ts:2925](../src/scenes/rpg/QizhenLakeScene.ts#L2925)；[src/scenes/rpg/QizhenLakeScene.ts:3439](../src/scenes/rpg/QizhenLakeScene.ts#L3439)；[src/scenes/rpg/TheaterInteriorScene.ts:705](../src/scenes/rpg/TheaterInteriorScene.ts#L705)；[src/scenes/rpg/TheaterInteriorScene.ts:709](../src/scenes/rpg/TheaterInteriorScene.ts#L709)；[src/scenes/rpg/TheaterInteriorScene.ts:722](../src/scenes/rpg/TheaterInteriorScene.ts#L722)；[src/scenes/rpg/TheaterInteriorScene.ts:1097](../src/scenes/rpg/TheaterInteriorScene.ts#L1097)；[src/scenes/rpg/TheaterInteriorScene.ts:1105](../src/scenes/rpg/TheaterInteriorScene.ts#L1105)；[src/scenes/rpg/TheaterInteriorScene.ts:1109](../src/scenes/rpg/TheaterInteriorScene.ts#L1109)；[src/scenes/rpg/TheaterInteriorScene.ts:1116](../src/scenes/rpg/TheaterInteriorScene.ts#L1116)；[src/scenes/rpg/TheaterInteriorScene.ts:1150](../src/scenes/rpg/TheaterInteriorScene.ts#L1150)；[src/scenes/rpg/TheaterInteriorScene.ts:1171](../src/scenes/rpg/TheaterInteriorScene.ts#L1171)；[src/scenes/rpg/TheaterInteriorScene.ts:1278](../src/scenes/rpg/TheaterInteriorScene.ts#L1278)；[src/scenes/rpg/TheaterInteriorScene.ts:1319](../src/scenes/rpg/TheaterInteriorScene.ts#L1319)；[src/scenes/rpg/TheaterInteriorScene.ts:1328](../src/scenes/rpg/TheaterInteriorScene.ts#L1328)；[src/scenes/rpg/TheaterInteriorScene.ts:1374](../src/scenes/rpg/TheaterInteriorScene.ts#L1374)；[src/scenes/rpg/TheaterInteriorScene.ts:1380](../src/scenes/rpg/TheaterInteriorScene.ts#L1380)；[src/scenes/rpg/TheaterInteriorScene.ts:1800](../src/scenes/rpg/TheaterInteriorScene.ts#L1800)
547. 系统：它可能只是来体验一下排队，很多东西在食堂都会排队。
   来源：[src/data/chapter3-story-lines.json:20](../src/data/chapter3-story-lines.json#L20)
548. Maybe it only came to experience the queue. Many things end up queuing in a cafeteria.
   来源：[src/data/chapter3-story-lines.json:21](../src/data/chapter3-story-lines.json#L21)
549. 系统：因为你现在需要钱，而它们需要劳动力。
   来源：[src/data/chapter3-story-lines.json:29](../src/data/chapter3-story-lines.json#L29)
550. Because you need money, and they need labor.
   来源：[src/data/chapter3-story-lines.json:30](../src/data/chapter3-story-lines.json#L30)
551. 系统：它看起来不像纸条会吃的东西，虽然纸条也不该吃东西。
   来源：[src/data/chapter3-story-lines.json:38](../src/data/chapter3-story-lines.json#L38)
552. That does not look like something a paper slip would eat. Admittedly, paper should not eat at all.
   来源：[src/data/chapter3-story-lines.json:39](../src/data/chapter3-story-lines.json#L39)
553. 系统：不是，是一份比较真实的早饭。
   来源：[src/data/chapter3-story-lines.json:47](../src/data/chapter3-story-lines.json#L47)
554. No. It is merely a disappointingly real breakfast.
   来源：[src/data/chapter3-story-lines.json:48](../src/data/chapter3-story-lines.json#L48)
555. 系统：纸包鸡。我知道的至少前两个字很有嫌疑。
   来源：[src/data/chapter3-story-lines.json:56](../src/data/chapter3-story-lines.json#L56)
556. Paper-wrapped chicken. At least the first word is suspicious.
   来源：[src/data/chapter3-story-lines.json:57](../src/data/chapter3-story-lines.json#L57)
557. 系统：一份线索。鸡只是包装。
   来源：[src/data/chapter3-story-lines.json:65](../src/data/chapter3-story-lines.json#L65)
558. One clue. The chicken is only packaging.
   来源：[src/data/chapter3-story-lines.json:66](../src/data/chapter3-story-lines.json#L66)
559. 系统：这份粥很热，但线索很冷。
   来源：[src/data/chapter3-story-lines.json:74](../src/data/chapter3-story-lines.json#L74)
560. The congee is hot. The clue is cold.
   来源：[src/data/chapter3-story-lines.json:75](../src/data/chapter3-story-lines.json#L75)
561. 系统：请不要拓展世界观。
   来源：[src/data/chapter3-story-lines.json:83](../src/data/chapter3-story-lines.json#L83)
562. Please do not expand the worldbuilding.
   来源：[src/data/chapter3-story-lines.json:84](../src/data/chapter3-story-lines.json#L84)
563. narrator
   来源：[src/data/chapter3-story-lines.json:90](../src/data/chapter3-story-lines.json#L90)；[src/data/chapter3-story-lines.json:99](../src/data/chapter3-story-lines.json#L99)；[src/data/chapter3-story-lines.json:117](../src/data/chapter3-story-lines.json#L117)；[src/data/chapter3-story-lines.json:153](../src/data/chapter3-story-lines.json#L153)；[src/data/chapter3-story-lines.json:324](../src/data/chapter3-story-lines.json#L324)；[src/scenes/rpg/CanteenInteriorScene.ts:2016](../src/scenes/rpg/CanteenInteriorScene.ts#L2016)；[src/scenes/rpg/QizhenLakeScene.ts:951](../src/scenes/rpg/QizhenLakeScene.ts#L951)；[src/scenes/rpg/QizhenLakeScene.ts:955](../src/scenes/rpg/QizhenLakeScene.ts#L955)；[src/scenes/rpg/QizhenLakeScene.ts:1072](../src/scenes/rpg/QizhenLakeScene.ts#L1072)；[src/scenes/rpg/QizhenLakeScene.ts:2510](../src/scenes/rpg/QizhenLakeScene.ts#L2510)；[src/scenes/rpg/QizhenLakeScene.ts:3343](../src/scenes/rpg/QizhenLakeScene.ts#L3343)；[src/scenes/rpg/QizhenLakeScene.ts:3372](../src/scenes/rpg/QizhenLakeScene.ts#L3372)；[src/scenes/rpg/TheaterInteriorScene.ts:1288](../src/scenes/rpg/TheaterInteriorScene.ts#L1288)
564. 纸条撞回食堂，掉下一点蓝光。
   来源：[src/data/chapter3-story-lines.json:92](../src/data/chapter3-story-lines.json#L92)
565. The paper crashes back into the cafeteria and sheds a flicker of blue light.
   来源：[src/data/chapter3-story-lines.json:93](../src/data/chapter3-story-lines.json#L93)
566. 纸条急了，它开始不尊重取餐流程。
   来源：[src/data/chapter3-story-lines.json:101](../src/data/chapter3-story-lines.json#L101)
567. The paper is getting desperate. It has stopped respecting the pickup procedure.
   来源：[src/data/chapter3-story-lines.json:102](../src/data/chapter3-story-lines.json#L102)
568. 系统：自助服务发展到这一步，我有点害怕。
   来源：[src/data/chapter3-story-lines.json:110](../src/data/chapter3-story-lines.json#L110)
569. Self-service has advanced too far. I am mildly concerned.
   来源：[src/data/chapter3-story-lines.json:111](../src/data/chapter3-story-lines.json#L111)
570. The paper flees along the main road.
   来源：[src/data/chapter3-story-lines.json:120](../src/data/chapter3-story-lines.json#L120)
571. 系统：你正在以“没吃早饭的人类速度”移动。
   来源：[src/data/chapter3-story-lines.json:128](../src/data/chapter3-story-lines.json#L128)
572. You are moving at the speed of a human who skipped breakfast.
   来源：[src/data/chapter3-story-lines.json:129](../src/data/chapter3-story-lines.json#L129)
573. 系统：它没有绩点负担。
   来源：[src/data/chapter3-story-lines.json:137](../src/data/chapter3-story-lines.json#L137)
574. It carries no grade-point burden.
   来源：[src/data/chapter3-story-lines.json:138](../src/data/chapter3-story-lines.json#L138)
575. 系统：这句话在本游戏里出现频率太高了。
   来源：[src/data/chapter3-story-lines.json:146](../src/data/chapter3-story-lines.json#L146)
576. That sentence occurs far too often in this game.
   来源：[src/data/chapter3-story-lines.json:147](../src/data/chapter3-story-lines.json#L147)
577. 旁白：失败得很慷慨。
   来源：[src/data/chapter3-story-lines.json:155](../src/data/chapter3-story-lines.json#L155)
578. A remarkably generous failure.
   来源：[src/data/chapter3-story-lines.json:156](../src/data/chapter3-story-lines.json#L156)
579. 系统：台上的顺序改过，印刷版未必跟得上。
   来源：[src/data/chapter3-story-lines.json:164](../src/data/chapter3-story-lines.json#L164)；[src/data/chapter3-theater.content.json:111](../src/data/chapter3-theater.content.json#L111)
580. They changed the running order. The printed program may be out of date.
   来源：[src/data/chapter3-story-lines.json:165](../src/data/chapter3-story-lines.json#L165)
581. 系统：先翻过来看。
   来源：[src/data/chapter3-story-lines.json:173](../src/data/chapter3-story-lines.json#L173)；[src/data/chapter3-theater.content.json:154](../src/data/chapter3-theater.content.json#L154)
582. Turn it over first.
   来源：[src/data/chapter3-story-lines.json:174](../src/data/chapter3-story-lines.json#L174)
583. 系统：替身有编号。原件去向不在节目单里。
   来源：[src/data/chapter3-story-lines.json:182](../src/data/chapter3-story-lines.json#L182)；[src/data/chapter3-theater.content.json:157](../src/data/chapter3-theater.content.json#L157)
584. The substitute has a serial number. The program says nothing about where the original went.
   来源：[src/data/chapter3-story-lines.json:183](../src/data/chapter3-story-lines.json#L183)
585. 系统：不知道。它这次没有沿路掉纸屑。
   来源：[src/data/chapter3-story-lines.json:191](../src/data/chapter3-story-lines.json#L191)
586. No idea. This time it left no paper scraps along the road.
   来源：[src/data/chapter3-story-lines.json:192](../src/data/chapter3-story-lines.json#L192)
587. 系统：老办法，发个论坛问问。
   来源：[src/data/chapter3-story-lines.json:200](../src/data/chapter3-story-lines.json#L200)
588. Use the old method. Ask the campus forum.
   来源：[src/data/chapter3-story-lines.json:201](../src/data/chapter3-story-lines.json#L201)
589. 系统：CC98 提供了一个非常精确的范围：不是厕所。
   来源：[src/data/chapter3-story-lines.json:209](../src/data/chapter3-story-lines.json#L209)
590. CC98 has provided a highly precise range: not the restroom.
   来源：[src/data/chapter3-story-lines.json:210](../src/data/chapter3-story-lines.json#L210)
591. 系统：意思是它现在比我们更艺术。
   来源：[src/data/chapter3-story-lines.json:218](../src/data/chapter3-story-lines.json#L218)
592. It means the paper is currently more artistic than we are.
   来源：[src/data/chapter3-story-lines.json:219](../src/data/chapter3-story-lines.json#L219)
593. 系统：恭喜，你完成了一次校园级猜谜。
   来源：[src/data/chapter3-story-lines.json:227](../src/data/chapter3-story-lines.json#L227)
594. Congratulations. You have completed a campus-scale guessing game.
   来源：[src/data/chapter3-story-lines.json:228](../src/data/chapter3-story-lines.json#L228)
595. 系统：准确来说，是在倒影里。
   来源：[src/data/chapter3-story-lines.json:236](../src/data/chapter3-story-lines.json#L236)
596. More precisely, it is inside the reflection.
   来源：[src/data/chapter3-story-lines.json:237](../src/data/chapter3-story-lines.json#L237)
597. 系统：对不会游泳的人来说区别很大。
   来源：[src/data/chapter3-story-lines.json:245](../src/data/chapter3-story-lines.json#L245)
598. For someone who cannot swim, the difference is substantial.
   来源：[src/data/chapter3-story-lines.json:246](../src/data/chapter3-story-lines.json#L246)
599. 系统：它又消失了。
   来源：[src/data/chapter3-story-lines.json:254](../src/data/chapter3-story-lines.json#L254)
600. It disappeared again.
   来源：[src/data/chapter3-story-lines.json:255](../src/data/chapter3-story-lines.json#L255)
601. 系统：通常这里不应该有给我们指指路的牌子吗？
   来源：[src/data/chapter3-story-lines.json:263](../src/data/chapter3-story-lines.json#L263)
602. Should there not be a sign around here to point us somewhere?
   来源：[src/data/chapter3-story-lines.json:264](../src/data/chapter3-story-lines.json#L264)
603. 系统：这就是它躲藏的地方，哈
   来源：[src/data/chapter3-story-lines.json:272](../src/data/chapter3-story-lines.json#L272)
604. So this is where it is hiding. Hah.
   来源：[src/data/chapter3-story-lines.json:273](../src/data/chapter3-story-lines.json#L273)
605. 系统：把它挂到哪里去，让大家看看！
   来源：[src/data/chapter3-story-lines.json:281](../src/data/chapter3-story-lines.json#L281)
606. Hang it somewhere public. Let everyone see it.
   来源：[src/data/chapter3-story-lines.json:282](../src/data/chapter3-story-lines.json#L282)
607. 系统：就是这个假的
   来源：[src/data/chapter3-story-lines.json:290](../src/data/chapter3-story-lines.json#L290)
608. Use the fake one.
   来源：[src/data/chapter3-story-lines.json:291](../src/data/chapter3-story-lines.json#L291)
609. 系统：因为它不能接受别人替它逃跑。
   来源：[src/data/chapter3-story-lines.json:299](../src/data/chapter3-story-lines.json#L299)
610. Because it cannot tolerate someone else escaping in its place.
   来源：[src/data/chapter3-story-lines.json:300](../src/data/chapter3-story-lines.json#L300)
611. 系统：你只是让湖更有氛围了。
   来源：[src/data/chapter3-story-lines.json:308](../src/data/chapter3-story-lines.json#L308)
612. You have only made the lake more atmospheric.
   来源：[src/data/chapter3-story-lines.json:309](../src/data/chapter3-story-lines.json#L309)
613. 系统：还在嘲笑你的倒影。
   来源：[src/data/chapter3-story-lines.json:317](../src/data/chapter3-story-lines.json#L317)
614. It is still mocking your reflection.
   来源：[src/data/chapter3-story-lines.json:318](../src/data/chapter3-story-lines.json#L318)
615. 纸条从湖面倒影弹出来，贴着地面飞。
   来源：[src/data/chapter3-story-lines.json:326](../src/data/chapter3-story-lines.json#L326)
616. The paper springs out of the lake reflection and skims along the ground.
   来源：[src/data/chapter3-story-lines.json:327](../src/data/chapter3-story-lines.json#L327)
617. 系统：现在！它回到浅色模式了！
   来源：[src/data/chapter3-story-lines.json:335](../src/data/chapter3-story-lines.json#L335)
618. Now! It is back in the light layer!
   来源：[src/data/chapter3-story-lines.json:336](../src/data/chapter3-story-lines.json#L336)
619. 系统：能抓了！
   来源：[src/data/chapter3-story-lines.json:344](../src/data/chapter3-story-lines.json#L344)
620. You can catch it now!
   来源：[src/data/chapter3-story-lines.json:345](../src/data/chapter3-story-lines.json#L345)
621. 剧院
   来源：[src/data/chapter3-theater.content.json:3](../src/data/chapter3-theater.content.json#L3)
622. 进入剧院
   来源：[src/data/chapter3-theater.content.json:5](../src/data/chapter3-theater.content.json#L5)
623. 深色模式会显示被隐藏的票务信息。
   来源：[src/data/chapter3-theater.content.json:7](../src/data/chapter3-theater.content.json#L7)
624. 浅色模式可以处理现实中的玻璃、机器和票根。
   来源：[src/data/chapter3-theater.content.json:8](../src/data/chapter3-theater.content.json#L8)
625. 检票员：请出示票。
   来源：[src/data/chapter3-theater.content.json:12](../src/data/chapter3-theater.content.json#L12)
626. 玩家：刚才那张纸进去了，我想进去看看。
   来源：[src/data/chapter3-theater.content.json:13](../src/data/chapter3-theater.content.json#L13)
627. 检票员：纸进去我管不着，人进去要验票。今晚好像有同学临时来不了。
   来源：[src/data/chapter3-theater.content.json:14](../src/data/chapter3-theater.content.json#L14)
628. 紫金港学生剧社
   来源：[src/data/chapter3-theater.content.json:18](../src/data/chapter3-theater.content.json#L18)；[src/data/chapter3-theater.content.json:39](../src/data/chapter3-theater.content.json#L39)
629. 【求助】学生剧《7:55》临时退票，求现场帮抢
   来源：[src/data/chapter3-theater.content.json:21](../src/data/chapter3-theater.content.json#L21)
630. 刚刚
   来源：[src/data/chapter3-theater.content.json:24](../src/data/chapter3-theater.content.json#L24)
631. 学生剧《7:55》今晚在紫金港校区剧场演出。原票主临时无法到场，剧社受托把一张现场测试票放回手机票务。请确认能够按时入场再接单，具体取票规则见下方票务卡。
   来源：[src/data/chapter3-theater.content.json:25](../src/data/chapter3-theater.content.json#L25)
632. 紫金港学生剧社 · 2026 秋季原创作品
   来源：[src/data/chapter3-theater.content.json:27](../src/data/chapter3-theater.content.json#L27)
633. 学生剧《7:55》
   来源：[src/data/chapter3-theater.content.json:28](../src/data/chapter3-theater.content.json#L28)
634. 所有钟表停在同一分钟，记忆仍在继续。
   来源：[src/data/chapter3-theater.content.json:29](../src/data/chapter3-theater.content.json#L29)
635. 学生剧《7:55》像素海报：深蓝幕布、指向七点五十五分的时钟、聚光灯下的节目单和票根
   来源：[src/data/chapter3-theater.content.json:30](../src/data/chapter3-theater.content.json#L30)
636. 散场广播响起后，一名迟到的学生仍在寻找自己的座位。他穿过三次散场、两条相同的走廊，以及一场反复重来的谢幕。舞台记录着同一个时间，观众保留着不同版本的昨晚。
   来源：[src/data/chapter3-theater.content.json:31](../src/data/chapter3-theater.content.json#L31)
637. 本周五 19:30
   来源：[src/data/chapter3-theater.content.json:33](../src/data/chapter3-theater.content.json#L33)
638. 演出时间
   来源：[src/data/chapter3-theater.content.json:33](../src/data/chapter3-theater.content.json#L33)
639. 开始入场
   来源：[src/data/chapter3-theater.content.json:34](../src/data/chapter3-theater.content.json#L34)
640. 演出地点
   来源：[src/data/chapter3-theater.content.json:35](../src/data/chapter3-theater.content.json#L35)
641. 紫金港校区剧场
   来源：[src/data/chapter3-theater.content.json:35](../src/data/chapter3-theater.content.json#L35)
642. 75 分钟 · 无中场休息
   来源：[src/data/chapter3-theater.content.json:36](../src/data/chapter3-theater.content.json#L36)
643. 演出时长
   来源：[src/data/chapter3-theater.content.json:36](../src/data/chapter3-theater.content.json#L36)
644. 出品
   来源：[src/data/chapter3-theater.content.json:39](../src/data/chapter3-theater.content.json#L39)
645. 文本
   来源：[src/data/chapter3-theater.content.json:40](../src/data/chapter3-theater.content.json#L40)
646. 学生剧社原创组
   来源：[src/data/chapter3-theater.content.json:40](../src/data/chapter3-theater.content.json#L40)
647. 舞台
   来源：[src/data/chapter3-theater.content.json:41](../src/data/chapter3-theater.content.json#L41)
648. 学生剧社舞台组
   来源：[src/data/chapter3-theater.content.json:41](../src/data/chapter3-theater.content.json#L41)
649. 灯光与声音
   来源：[src/data/chapter3-theater.content.json:42](../src/data/chapter3-theater.content.json#L42)
650. 剧场技术组
   来源：[src/data/chapter3-theater.content.json:42](../src/data/chapter3-theater.content.json#L42)
651. 演出含短时黑场、频闪与广播音效；有需要的观众可在前台领取提示单。
   来源：[src/data/chapter3-theater.content.json:45](../src/data/chapter3-theater.content.json#L45)
652. 19:30 后关闭正门，迟到观众将在序场结束后由工作人员引导入场。
   来源：[src/data/chapter3-theater.content.json:46](../src/data/chapter3-theater.content.json#L46)
653. 演出过程中请勿摄影或录音；谢幕结束后开放十分钟演后谈。
   来源：[src/data/chapter3-theater.content.json:47](../src/data/chapter3-theater.content.json#L47)
654. 查看完整演出档案
   来源：[src/data/chapter3-theater.content.json:49](../src/data/chapter3-theater.content.json#L49)
655. 收起演出档案
   来源：[src/data/chapter3-theater.content.json:50](../src/data/chapter3-theater.content.json#L50)
656. 我刚在大厅看过取票机，普通界面只有取票码输入框。屏幕底下还残留着一行没擦净的数字。
   来源：[src/data/chapter3-theater.content.json:52](../src/data/chapter3-theater.content.json#L52)
657. 接下现场帮抢
   来源：[src/data/chapter3-theater.content.json:53](../src/data/chapter3-theater.content.json#L53)
658. 还没人接单。已经在剧场的同学优先，别抢到了又来不了。
   来源：[src/data/chapter3-theater.content.json:54](../src/data/chapter3-theater.content.json#L54)
659. 票务页可以提交了；大厅旧屏幕上还留着放票记录。
   来源：[src/data/chapter3-theater.content.json:55](../src/data/chapter3-theater.content.json#L55)
660. 接单成功，等本页放票。人已经在大厅，票还得在手机上抢。
   来源：[src/data/chapter3-theater.content.json:56](../src/data/chapter3-theater.content.json#L56)
661. 未抢到：当前网速过慢。
   来源：[src/data/chapter3-theater.content.json:57](../src/data/chapter3-theater.content.json#L57)；[src/data/chapter3-theater.content.json:60](../src/data/chapter3-theater.content.json#L60)
662. 未抢到，当前网速过慢。下一波开放倒计时：
   来源：[src/data/chapter3-theater.content.json:58](../src/data/chapter3-theater.content.json#L58)
663. 第二波已开放，可以再次抢票。
   来源：[src/data/chapter3-theater.content.json:59](../src/data/chapter3-theater.content.json#L59)
664. 第一波抢票成功。你的运气很好，但是钱包就没那么好了。
   来源：[src/data/chapter3-theater.content.json:61](../src/data/chapter3-theater.content.json#L61)
665. 第二波抢票成功。手机已收到 0832 取票码。
   来源：[src/data/chapter3-theater.content.json:62](../src/data/chapter3-theater.content.json#L62)
666. 第二波抢票成功，取票码 0832 已写入手机回执。
   来源：[src/data/chapter3-theater.content.json:63](../src/data/chapter3-theater.content.json#L63)
667. 你的运气很好，但是钱包就没那么好了。
   来源：[src/data/chapter3-theater.content.json:64](../src/data/chapter3-theater.content.json#L64)
668. 手机票务 H5
   来源：[src/data/chapter3-theater.content.json:65](../src/data/chapter3-theater.content.json#L65)
669. 校园网
   来源：[src/data/chapter3-theater.content.json:66](../src/data/chapter3-theater.content.json#L66)
670. 移动数据
   来源：[src/data/chapter3-theater.content.json:67](../src/data/chapter3-theater.content.json#L67)
671. 无网络
   来源：[src/data/chapter3-theater.content.json:68](../src/data/chapter3-theater.content.json#L68)
672. 参加第一波抢票
   来源：[src/data/chapter3-theater.content.json:69](../src/data/chapter3-theater.content.json#L69)；[src/data/chapter3-theater.content.json:71](../src/data/chapter3-theater.content.json#L71)
673. 参加第二波抢票
   来源：[src/data/chapter3-theater.content.json:70](../src/data/chapter3-theater.content.json#L70)
674. 第二波倒计时
   来源：[src/data/chapter3-theater.content.json:72](../src/data/chapter3-theater.content.json#L72)
675. 第二波已开放
   来源：[src/data/chapter3-theater.content.json:73](../src/data/chapter3-theater.content.json#L73)
676. 剧场取票码
   来源：[src/data/chapter3-theater.content.json:74](../src/data/chapter3-theater.content.json#L74)
677. 去剧场大厅，在自助取票机输入 0832，打印半张票根 B。
   来源：[src/data/chapter3-theater.content.json:75](../src/data/chapter3-theater.content.json#L75)
678. 我已经在大厅，接下这次帮抢。
   来源：[src/data/chapter3-theater.content.json:76](../src/data/chapter3-theater.content.json#L76)
679. 手机票务回执：第一波未抢到，当前网速过慢。
   来源：[src/data/chapter3-theater.content.json:77](../src/data/chapter3-theater.content.json#L77)
680. 手机票务回执：第一波抢票成功。你的运气很好，但是钱包就没那么好了。取票码 0832。
   来源：[src/data/chapter3-theater.content.json:78](../src/data/chapter3-theater.content.json#L78)
681. 手机票务回执：第二波抢票成功，取票码 0832 已生成。请到大厅取票机打印票根。
   来源：[src/data/chapter3-theater.content.json:79](../src/data/chapter3-theater.content.json#L79)
682. 检票员：没有票不能进。
   来源：[src/data/chapter3-theater.content.json:82](../src/data/chapter3-theater.content.json#L82)
683. 检票员：今晚有人临时来不了，说在校园论坛留了消息。我这边只负责验票。
   来源：[src/data/chapter3-theater.content.json:83](../src/data/chapter3-theater.content.json#L83)
684. 玻璃反光严重，你只能看见一个很需要睡觉的人。
   来源：[src/data/chapter3-theater.content.json:84](../src/data/chapter3-theater.content.json#L84)
685. 擦去油膜，玻璃下露出半张旧票根。场次和票号还在，验票区域缺了一半。
   来源：[src/data/chapter3-theater.content.json:85](../src/data/chapter3-theater.content.json#L85)
686. 自助取票 · 输入回执上的四位取票码
   来源：[src/data/chapter3-theater.content.json:86](../src/data/chapter3-theater.content.json#L86)
687. 0832 号，两波释放，当前未取票。
   来源：[src/data/chapter3-theater.content.json:87](../src/data/chapter3-theater.content.json#L87)
688. 取票机：查无此票。请核对回执，本机不接受到场证明。
   来源：[src/data/chapter3-theater.content.json:88](../src/data/chapter3-theater.content.json#L88)
689. 取票机：本场常规票已售完。屏幕边贴着一张留言：临时退票事宜，见校园论坛今日留言。
   来源：[src/data/chapter3-theater.content.json:89](../src/data/chapter3-theater.content.json#L89)
690. 取票机：尚未查询到取票回执。只有确认成功的订单才能在这里打印。
   来源：[src/data/chapter3-theater.content.json:90](../src/data/chapter3-theater.content.json#L90)
691. 取票机：回执已核验。补打的票根缺了左半边，场次和票号仍能辨认。
   来源：[src/data/chapter3-theater.content.json:91](../src/data/chapter3-theater.content.json#L91)
692. 玩家：同一场，票号也一样。
   来源：[src/data/chapter3-theater.content.json:93](../src/data/chapter3-theater.content.json#L93)
693. 玩家：接上了。买票还得自己装。
   来源：[src/data/chapter3-theater.content.json:94](../src/data/chapter3-theater.content.json#L94)
694. 检票员：你自己拼的？
   来源：[src/data/chapter3-theater.content.json:97](../src/data/chapter3-theater.content.json#L97)
695. 玩家：两半都在，码也没缺。
   来源：[src/data/chapter3-theater.content.json:98](../src/data/chapter3-theater.content.json#L98)
696. 检票员：能扫。进去吧，票根先别扔。
   来源：[src/data/chapter3-theater.content.json:99](../src/data/chapter3-theater.content.json#L99)
697. 取得节目单残页，确认节目顺序。
   来源：[src/data/chapter3-theater.content.json:103](../src/data/chapter3-theater.content.json#L103)
698. 灯控台：请输入节目顺序。
   来源：[src/data/chapter3-theater.content.json:104](../src/data/chapter3-theater.content.json#L104)
699. 当前状态：追光灯锁定。
   来源：[src/data/chapter3-theater.content.json:105](../src/data/chapter3-theater.content.json#L105)
700. 印好的节目单，简介里有几笔颜色偏淡。排练怎么改，印好的纸也没来得及换。
   来源：[src/data/chapter3-theater.content.json:106](../src/data/chapter3-theater.content.json#L106)
701. 深色观察下，节目单简介里的淡字清楚了一些。可以展开看看。
   来源：[src/data/chapter3-theater.content.json:107](../src/data/chapter3-theater.content.json#L107)
702. 还有残页没看清。收好的节目单也能展开查看。
   来源：[src/data/chapter3-theater.content.json:108](../src/data/chapter3-theater.content.json#L108)
703. 灯控台：顺序不符，请核对节目单。
   来源：[src/data/chapter3-theater.content.json:110](../src/data/chapter3-theater.content.json#L110)
704. 追光灯解锁。
   来源：[src/data/chapter3-theater.content.json:113](../src/data/chapter3-theater.content.json#L113)
705. 开场
   来源：[src/data/chapter3-theater.content.json:115](../src/data/chapter3-theater.content.json#L115)
706. 追光
   来源：[src/data/chapter3-theater.content.json:116](../src/data/chapter3-theater.content.json#L116)
707. 谢幕
   来源：[src/data/chapter3-theater.content.json:117](../src/data/chapter3-theater.content.json#L117)
708. 让纸条留下能够被追光灯识别的痕迹。
   来源：[src/data/chapter3-theater.content.json:121](../src/data/chapter3-theater.content.json#L121)
709. 箱子锁着，旁边装了读票器。取道具也要验票。
   来源：[src/data/chapter3-theater.content.json:122](../src/data/chapter3-theater.content.json#L122)
710. 箱子空了，荧光粉刷已经收好。后台还有风声。
   来源：[src/data/chapter3-theater.content.json:123](../src/data/chapter3-theater.content.json#L123)
711. 箱内有荧光粉刷的残影，但你摸不到 7:55 的东西。
   来源：[src/data/chapter3-theater.content.json:124](../src/data/chapter3-theater.content.json#L124)
712. 会谢幕的道具才能出箱。
   来源：[src/data/chapter3-theater.content.json:125](../src/data/chapter3-theater.content.json#L125)
713. 票码通过，箱锁松开。看演出和取道具，用的居然是同一张票。
   来源：[src/data/chapter3-theater.content.json:126](../src/data/chapter3-theater.content.json#L126)
714. 荧光粉吹上舞台，粘在了移动的纸面上。
   来源：[src/data/chapter3-theater.content.json:127](../src/data/chapter3-theater.content.json#L127)
715. 观察路径残影或直接试灯，用追光灯连续照中纸条三次。
   来源：[src/data/chapter3-theater.content.json:130](../src/data/chapter3-theater.content.json#L130)
716. 前往观众席右侧灯控台，将追光灯遥控器拖入控制台。
   来源：[src/data/chapter3-theater.content.json:131](../src/data/chapter3-theater.content.json#L131)
717. 把追光灯遥控器接到灯控台。
   来源：[src/data/chapter3-theater.content.json:132](../src/data/chapter3-theater.content.json#L132)
718. 观察纸条的移动路径；深色模式会显示更完整的尾迹。
   来源：[src/data/chapter3-theater.content.json:133](../src/data/chapter3-theater.content.json#L133)
719. 浅色模式：预置追光灯，等纸条进入光圈后持续照射。
   来源：[src/data/chapter3-theater.content.json:134](../src/data/chapter3-theater.content.json#L134)
720. 拖动滑轨或按左右键移动追光灯；按住照射键或空格完成锁定。
   来源：[src/data/chapter3-theater.content.json:135](../src/data/chapter3-theater.content.json#L135)
721. 检查灯位、开启时机和连续照射时间。
   来源：[src/data/chapter3-theater.content.json:136](../src/data/chapter3-theater.content.json#L136)
722. 纸条已离开舞台，本轮没有完成锁定。
   来源：[src/data/chapter3-theater.content.json:137](../src/data/chapter3-theater.content.json#L137)
723. 连续锁定
   来源：[src/data/chapter3-theater.content.json:138](../src/data/chapter3-theater.content.json#L138)
724. 按住照射
   来源：[src/data/chapter3-theater.content.json:139](../src/data/chapter3-theater.content.json#L139)
725. 辅助已开启：残影延长，命中范围扩大。
   来源：[src/data/chapter3-theater.content.json:140](../src/data/chapter3-theater.content.json#L140)
726. 灯位不符。重新观察纸条最后进入的灯区。
   来源：[src/data/chapter3-theater.content.json:142](../src/data/chapter3-theater.content.json#L142)
727. 没有开启追光灯。纸条进入灯区时按住照射。
   来源：[src/data/chapter3-theater.content.json:143](../src/data/chapter3-theater.content.json#L143)
728. 照射开启过早，纸条在进入灯区前改变了路线。
   来源：[src/data/chapter3-theater.content.json:144](../src/data/chapter3-theater.content.json#L144)
729. 照射开启过晚，纸条已经离开灯区。
   来源：[src/data/chapter3-theater.content.json:145](../src/data/chapter3-theater.content.json#L145)
730. 照射中断。需要保持光圈与纸条连续重合。
   来源：[src/data/chapter3-theater.content.json:146](../src/data/chapter3-theater.content.json#L146)
731. 纸条已经离开舞台，本轮重新开始。
   来源：[src/data/chapter3-theater.content.json:147](../src/data/chapter3-theater.content.json#L147)
732. 它避开了追光灯。当前轮次重新开始。
   来源：[src/data/chapter3-theater.content.json:149](../src/data/chapter3-theater.content.json#L149)
733. 追光命中。
   来源：[src/data/chapter3-theater.content.json:150](../src/data/chapter3-theater.content.json#L150)
734. 灯下的纸没动，背面露出了道具编号。
   来源：[src/data/chapter3-theater.content.json:151](../src/data/chapter3-theater.content.json#L151)
735. 玩家：抓到了！
   来源：[src/data/chapter3-theater.content.json:153](../src/data/chapter3-theater.content.json#L153)
736. 玩家：道具编号？
   来源：[src/data/chapter3-theater.content.json:155](../src/data/chapter3-theater.content.json#L155)
737. 玩家：我抢票进来，抓了个替身？
   来源：[src/data/chapter3-theater.content.json:156](../src/data/chapter3-theater.content.json#L156)
738. 找出纸条下一站
   来源：[src/data/chapter3-theater.content.json:161](../src/data/chapter3-theater.content.json#L161)
739. 纸条这次没有留下连续脚印。
   来源：[src/data/chapter3-theater.content.json:163](../src/data/chapter3-theater.content.json#L163)
740. 湿掉的节目单可以用于查询不同来源。
   来源：[src/data/chapter3-theater.content.json:164](../src/data/chapter3-theater.content.json#L164)
741. 手机地图需要三条相互独立的地点特征。
   来源：[src/data/chapter3-theater.content.json:165](../src/data/chapter3-theater.content.json#L165)
742. 已切换到深色观察：读取残影与异常痕迹，不搬动实体。
   来源：[src/data/chapter3-theater.content.json:169](../src/data/chapter3-theater.content.json#L169)
743. 已切换到浅色操作：可以拖放道具、清洁玻璃和操作设备。
   来源：[src/data/chapter3-theater.content.json:170](../src/data/chapter3-theater.content.json#L170)
744. 这里暂时没有要处理的事。
   来源：[src/data/chapter3-theater.content.json:173](../src/data/chapter3-theater.content.json#L173)
745. 先走到设备前的可站立位置再操作。
   来源：[src/data/chapter3-theater.content.json:174](../src/data/chapter3-theater.content.json#L174)
746. 先走近一点再操作。
   来源：[src/data/chapter3-theater.content.json:175](../src/data/chapter3-theater.content.json#L175)
747. 任务更新：找齐三张节目单残页，确认节目顺序。
   来源：[src/data/chapter3-theater.content.json:178](../src/data/chapter3-theater.content.json#L178)
748. 任务更新：让纸条留下能被追光灯识别的痕迹。
   来源：[src/data/chapter3-theater.content.json:179](../src/data/chapter3-theater.content.json#L179)
749. 任务更新：把追光灯遥控器拖到观众席右侧灯控台。
   来源：[src/data/chapter3-theater.content.json:180](../src/data/chapter3-theater.content.json#L180)
750. 任务更新：观察残影路径，用追光灯连续照中纸条三次。
   来源：[src/data/chapter3-theater.content.json:181](../src/data/chapter3-theater.content.json#L181)
751. 任务更新：看清纸条真正的去向。
   来源：[src/data/chapter3-theater.content.json:182](../src/data/chapter3-theater.content.json#L182)
752. 任务更新：从剧院出口离开，追查纸条的下一站。
   来源：[src/data/chapter3-theater.content.json:183](../src/data/chapter3-theater.content.json#L183)
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
   来源：[src/modules/ChapterThreeQizhenLakeController.ts:1114](../src/modules/ChapterThreeQizhenLakeController.ts#L1114)；[src/modules/ChapterThreeQizhenLakeController.ts:1307](../src/modules/ChapterThreeQizhenLakeController.ts#L1307)；[src/modules/ChapterThreeQizhenLakeController.ts:1335](../src/modules/ChapterThreeQizhenLakeController.ts#L1335)；[src/modules/ChapterThreeQizhenLakeController.ts:1355](../src/modules/ChapterThreeQizhenLakeController.ts#L1355)；[src/scenes/rpg/QizhenLakeScene.ts:1038](../src/scenes/rpg/QizhenLakeScene.ts#L1038)
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
   来源：[src/modules/QizhenJournalModel.ts:130](../src/modules/QizhenJournalModel.ts#L130)；[src/scenes/phone/P18_Photos/index.tsx:197](../src/scenes/phone/P18_Photos/index.tsx#L197)；[src/scenes/rpg/CanteenInteriorScene.ts:2462](../src/scenes/rpg/CanteenInteriorScene.ts#L2462)；[src/scenes/rpg/TheaterInteriorScene.ts:1507](../src/scenes/rpg/TheaterInteriorScene.ts#L1507)；[src/scenes/rpg/TheaterInteriorScene.ts:1515](../src/scenes/rpg/TheaterInteriorScene.ts#L1515)
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
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:71](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L71)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:91](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L91)；[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:97](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L97)
817. 第二波抢票成功，取票码已生成。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:97](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L97)
818. 当前放票尚未开放。
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:105](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L105)
819. 学生剧手机帮抢委托
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:114](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L114)
820. 待接
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:119](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L119)
821. 第一波开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:121](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L121)
822. 第二波等待
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:123](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L123)
823. 第二波开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:123](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L123)
824. 第二波已中
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:124](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L124)
825. 第一波已中
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:124](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L124)
826. 委托进度
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:128](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L128)
827. 1 接单
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:129](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L129)
828. 2 大厅记录（可选）
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:130](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L130)
829. 3 第一波
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:131](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L131)
830. 4 第二波
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:133](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L133)
831. 4 已抢到
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:133](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L133)
832. 当前网络：{{networkLabel}}
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:137](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L137)
833. 当前网络
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:138](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L138)
834. 第一波放票时间
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:150](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L150)
835. 第一波放票
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:151](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L151)
836. {{secondWaveSeconds}} 秒后开放
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:176](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L176)
837. 抢票成功回执
   来源：[src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx:182](../src/scenes/phone/P02_CC98/TheaterTicketCommission.tsx#L182)
838. 湖区云层校准
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:188](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L188)
839. 寝室吹风机
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:190](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L190)
840. 风向校准
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:191](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L191)
841. 逆风修正三层云带
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:191](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L191)
842. /3 ·
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:192](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L192)
843. 西南风持续向左推动云带
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:195](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L195)
844. 持续风力
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:196](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L196)
845. 高层 Q/E · 中层 A/D · 低层 Z/C 后退 / 前进
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:198](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L198)
846. {{control.label}}云带位置
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:213](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L213)
847. {{control.label}}{{direction === -1 ? "后退" : "前进"}}，键盘 {{key}}
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:238](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L238)
848. 进
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:249](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L249)
849. 退
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:249](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L249)
850. 三层均需操作
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:258](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L258)
851. 同步稳定
   来源：[src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx:258](../src/scenes/phone/P07_Weather/QizhenWeatherCalibration.tsx#L258)
852. 发现一条未归档的夜间接入记录。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:734](../src/scenes/phone/P13_PhoneHome/index.tsx#L734)
853. 校园网络
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:734](../src/scenes/phone/P13_PhoneHome/index.tsx#L734)
854. 打开 CC98 学生剧现场帮抢帖
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:745](../src/scenes/phone/P13_PhoneHome/index.tsx#L745)
855. CC98 · 学生剧《7:55》
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:749](../src/scenes/phone/P13_PhoneHome/index.tsx#L749)
856. 现场帮抢委托待接
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:752](../src/scenes/phone/P13_PhoneHome/index.tsx#L752)
857. 已接单，第一波待开始
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:754](../src/scenes/phone/P13_PhoneHome/index.tsx#L754)
858. 07:55:23
   来源：[src/scenes/phone/P18_Photos/index.tsx:33](../src/scenes/phone/P18_Photos/index.tsx#L33)；[src/scenes/phone/P18_Photos/index.tsx:34](../src/scenes/phone/P18_Photos/index.tsx#L34)；[src/scenes/phone/P18_Photos/index.tsx:35](../src/scenes/phone/P18_Photos/index.tsx#L35)；[src/scenes/phone/P18_Photos/index.tsx:36](../src/scenes/phone/P18_Photos/index.tsx#L36)；[src/scenes/phone/P18_Photos/index.tsx:37](../src/scenes/phone/P18_Photos/index.tsx#L37)；[src/scenes/phone/P18_Photos/index.tsx:38](../src/scenes/phone/P18_Photos/index.tsx#L38)；[src/scenes/phone/P18_Photos/index.tsx:39](../src/scenes/phone/P18_Photos/index.tsx#L39)
859. FRM 3A
   来源：[src/scenes/phone/P18_Photos/index.tsx:33](../src/scenes/phone/P18_Photos/index.tsx#L33)
860. FRM 91
   来源：[src/scenes/phone/P18_Photos/index.tsx:34](../src/scenes/phone/P18_Photos/index.tsx#L34)
861. FRM D7
   来源：[src/scenes/phone/P18_Photos/index.tsx:35](../src/scenes/phone/P18_Photos/index.tsx#L35)
862. FRM 4C
   来源：[src/scenes/phone/P18_Photos/index.tsx:36](../src/scenes/phone/P18_Photos/index.tsx#L36)
863. FRM 0F
   来源：[src/scenes/phone/P18_Photos/index.tsx:37](../src/scenes/phone/P18_Photos/index.tsx#L37)
864. FRM B2
   来源：[src/scenes/phone/P18_Photos/index.tsx:38](../src/scenes/phone/P18_Photos/index.tsx#L38)
865. FRM E8
   来源：[src/scenes/phone/P18_Photos/index.tsx:39](../src/scenes/phone/P18_Photos/index.tsx#L39)
866. 照片相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:63](../src/scenes/phone/P18_Photos/index.tsx#L63)
867. 相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:69](../src/scenes/phone/P18_Photos/index.tsx#L69)
868. 退出照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:70](../src/scenes/phone/P18_Photos/index.tsx#L70)
869. 启真湖划船
   来源：[src/scenes/phone/P18_Photos/index.tsx:79](../src/scenes/phone/P18_Photos/index.tsx#L79)；[src/scenes/phone/P18_Photos/index.tsx:108](../src/scenes/phone/P18_Photos/index.tsx#L108)
870. 张 · 来自相机
   来源：[src/scenes/phone/P18_Photos/index.tsx:80](../src/scenes/phone/P18_Photos/index.tsx#L80)
871. 恢复的项目
   来源：[src/scenes/phone/P18_Photos/index.tsx:84](../src/scenes/phone/P18_Photos/index.tsx#L84)
872. 7 张 · 帧顺序损坏
   来源：[src/scenes/phone/P18_Photos/index.tsx:85](../src/scenes/phone/P18_Photos/index.tsx#L85)
873. 校园与日常
   来源：[src/scenes/phone/P18_Photos/index.tsx:91](../src/scenes/phone/P18_Photos/index.tsx#L91)；[src/scenes/phone/P18_Photos/index.tsx:138](../src/scenes/phone/P18_Photos/index.tsx#L138)
874. 张 · 普通照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:92](../src/scenes/phone/P18_Photos/index.tsx#L92)
875. 相机照片、恢复帧和普通生活照分开归档。普通照片不会进入时间线或证据判定。
   来源：[src/scenes/phone/P18_Photos/index.tsx:94](../src/scenes/phone/P18_Photos/index.tsx#L94)
876. 启真湖划船相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:102](../src/scenes/phone/P18_Photos/index.tsx#L102)
877. 返回相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:109](../src/scenes/phone/P18_Photos/index.tsx#L109)；[src/scenes/phone/P18_Photos/index.tsx:139](../src/scenes/phone/P18_Photos/index.tsx#L139)；[src/scenes/phone/P18_Photos/index.tsx:216](../src/scenes/phone/P18_Photos/index.tsx#L216)
878. {{photo.spotId}} 相机照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:118](../src/scenes/phone/P18_Photos/index.tsx#L118)
879. 这份存档没有保留相机照片。恢复的动态照片仍可继续核验。
   来源：[src/scenes/phone/P18_Photos/index.tsx:123](../src/scenes/phone/P18_Photos/index.tsx#L123)
880. 校园与日常相簿
   来源：[src/scenes/phone/P18_Photos/index.tsx:132](../src/scenes/phone/P18_Photos/index.tsx#L132)
881. 这些照片用于补足手机相册的生活层次，不会触发剧情进度。
   来源：[src/scenes/phone/P18_Photos/index.tsx:144](../src/scenes/phone/P18_Photos/index.tsx#L144)
882. 校园与日常照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:145](../src/scenes/phone/P18_Photos/index.tsx#L145)
883. {{selectedCampusPhoto.capturedAt}} · {{selectedCampusPhoto.location}}
   来源：[src/scenes/phone/P18_Photos/index.tsx:164](../src/scenes/phone/P18_Photos/index.tsx#L164)
884. {{selectedCampusPhoto.title}}，{{selectedCampusPhoto.detail}}
   来源：[src/scenes/phone/P18_Photos/index.tsx:169](../src/scenes/phone/P18_Photos/index.tsx#L169)
885. 普通照片
   来源：[src/scenes/phone/P18_Photos/index.tsx:172](../src/scenes/phone/P18_Photos/index.tsx#L172)
886. 不参与时间线、地点判断或物品识别。
   来源：[src/scenes/phone/P18_Photos/index.tsx:173](../src/scenes/phone/P18_Photos/index.tsx#L173)
887. 照
   来源：[src/scenes/phone/P18_Photos/index.tsx:174](../src/scenes/phone/P18_Photos/index.tsx#L174)
888. 关闭
   来源：[src/scenes/phone/P18_Photos/index.tsx:176](../src/scenes/phone/P18_Photos/index.tsx#L176)；[src/scenes/rpg/TheaterInteriorScene.ts:1571](../src/scenes/rpg/TheaterInteriorScene.ts#L1571)；[src/scenes/rpg/TheaterInteriorScene.ts:1617](../src/scenes/rpg/TheaterInteriorScene.ts#L1617)
889. accepted
   来源：[src/scenes/phone/P18_Photos/index.tsx:195](../src/scenes/phone/P18_Photos/index.tsx#L195)；[src/scenes/rpg/CanteenInteriorScene.ts:2418](../src/scenes/rpg/CanteenInteriorScene.ts#L2418)；[src/scenes/rpg/CanteenInteriorScene.ts:2484](../src/scenes/rpg/CanteenInteriorScene.ts#L2484)
890. 三帧已经恢复为一次连续的水平移动。
   来源：[src/scenes/phone/P18_Photos/index.tsx:196](../src/scenes/phone/P18_Photos/index.tsx#L196)
891. 先完成 CC98 记录收尾。
   来源：[src/scenes/phone/P18_Photos/index.tsx:198](../src/scenes/phone/P18_Photos/index.tsx#L198)
892. 这三帧的运动方向没有连续起来。
   来源：[src/scenes/phone/P18_Photos/index.tsx:200](../src/scenes/phone/P18_Photos/index.tsx#L200)
893. 对比纸条与同一根湖岸灯柱的相对位置。
   来源：[src/scenes/phone/P18_Photos/index.tsx:202](../src/scenes/phone/P18_Photos/index.tsx#L202)
894. 排除镜像和无关帧，选择能形成连续水平移动的三张照片。
   来源：[src/scenes/phone/P18_Photos/index.tsx:203](../src/scenes/phone/P18_Photos/index.tsx#L203)
895. 已恢复相册
   来源：[src/scenes/phone/P18_Photos/index.tsx:209](../src/scenes/phone/P18_Photos/index.tsx#L209)
896. 最近删除 · 已恢复
   来源：[src/scenes/phone/P18_Photos/index.tsx:215](../src/scenes/phone/P18_Photos/index.tsx#L215)
897. 重排
   来源：[src/scenes/phone/P18_Photos/index.tsx:222](../src/scenes/phone/P18_Photos/index.tsx#L222)
898. IMG\_0755\_LIVE · 帧顺序损坏
   来源：[src/scenes/phone/P18_Photos/index.tsx:222](../src/scenes/phone/P18_Photos/index.tsx#L222)
899. 选出同一段运动中连续的三帧，再按先后顺序放入。
   来源：[src/scenes/phone/P18_Photos/index.tsx:223](../src/scenes/phone/P18_Photos/index.tsx#L223)
900. {{slot + 1}} · 待选择
   来源：[src/scenes/phone/P18_Photos/index.tsx:228](../src/scenes/phone/P18_Photos/index.tsx#L228)
901. {{frame.label}}，恢复照片帧
   来源：[src/scenes/phone/P18_Photos/index.tsx:243](../src/scenes/phone/P18_Photos/index.tsx#L243)
902. 已恢复的连续帧
   来源：[src/scenes/phone/P18_Photos/index.tsx:250](../src/scenes/phone/P18_Photos/index.tsx#L250)
903. 连续帧已恢复
   来源：[src/scenes/phone/P18_Photos/index.tsx:255](../src/scenes/phone/P18_Photos/index.tsx#L255)
904. 确认照片顺序
   来源：[src/scenes/phone/P18_Photos/index.tsx:258](../src/scenes/phone/P18_Photos/index.tsx#L258)
905. 紫金港校区
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:424](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L424)
906. 剧场
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:488](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L488)
907. 求是路
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:877](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L877)
908. 剧场 →
   来源：[src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts:882](../src/scenes/rpg/canteen-chase/ChaseThreeRenderer.ts#L882)
909. 剧院外到达转场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)
910. 食堂外上车转场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)
911. start
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:93](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L93)；[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
912. 角色解锁共享单车并开始骑行
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
913. 角色刹车下车并进入剧院外广场
   来源：[src/scenes/rpg/CanteenBikeTransitionOverlay.tsx:100](../src/scenes/rpg/CanteenBikeTransitionOverlay.tsx#L100)
914. 食堂到剧院：755 米 3D 自行车追逐
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:361](../src/scenes/rpg/CanteenChaseOverlay.tsx#L361)
915. 三车道校园道路、骑车人物、前方障碍，以及两侧人行道上的校园路人
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:369](../src/scenes/rpg/CanteenChaseOverlay.tsx#L369)
916. 骑行状态
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:372](../src/scenes/rpg/CanteenChaseOverlay.tsx#L372)
917. 追纸距离
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:374](../src/scenes/rpg/CanteenChaseOverlay.tsx#L374)
918. / 755m
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:375](../src/scenes/rpg/CanteenChaseOverlay.tsx#L375)
919. 骑行进度
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:380](../src/scenes/rpg/CanteenChaseOverlay.tsx#L380)
920. 机会
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:403](../src/scenes/rpg/CanteenChaseOverlay.tsx#L403)
921. 剩余 {{view.lives}} 次机会
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:404](../src/scenes/rpg/CanteenChaseOverlay.tsx#L404)
922. 节奏提升
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
923. 拥堵升级
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
924. 最后冲刺
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:418](../src/scenes/rpg/CanteenChaseOverlay.tsx#L418)
925. 换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:434](../src/scenes/rpg/CanteenChaseOverlay.tsx#L434)
926. 追逐方向
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:436](../src/scenes/rpg/CanteenChaseOverlay.tsx#L436)
927. 向左换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:437](../src/scenes/rpg/CanteenChaseOverlay.tsx#L437)
928. 向右换道
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:438](../src/scenes/rpg/CanteenChaseOverlay.tsx#L438)
929. 返回页面后继续
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:444](../src/scenes/rpg/CanteenChaseOverlay.tsx#L444)
930. 已暂停
   来源：[src/scenes/rpg/CanteenChaseOverlay.tsx:444](../src/scenes/rpg/CanteenChaseOverlay.tsx#L444)
931. 纸条已离开 · 重新拦截
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:197](../src/scenes/rpg/CanteenDefenseRuntime.ts#L197)
932. 准备重新开始
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:198](../src/scenes/rpg/CanteenDefenseRuntime.ts#L198)
933. 守住出口 {{seconds.toString().padStart(2, "0")}} 秒
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:464](../src/scenes/rpg/CanteenDefenseRuntime.ts#L464)
934. 冲刺冷却 {{(this.dashCooldownMs / 1000).toFixed(1)}}s
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:467](../src/scenes/rpg/CanteenDefenseRuntime.ts#L467)
935. 空格：冲刺
   来源：[src/scenes/rpg/CanteenDefenseRuntime.ts:467](../src/scenes/rpg/CanteenDefenseRuntime.ts#L467)
936. 蓝色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:201](../src/scenes/rpg/CanteenInteriorModel.ts#L201)
937. 白色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:213](../src/scenes/rpg/CanteenInteriorModel.ts#L213)
938. 黑色饮料机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:225](../src/scenes/rpg/CanteenInteriorModel.ts#L225)
939. 查看右侧瓶罐架
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:239](../src/scenes/rpg/CanteenInteriorModel.ts#L239)
940. 使用混合台
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:251](../src/scenes/rpg/CanteenInteriorModel.ts#L251)
941. 第五个窗口宣传灯箱空杯位
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:263](../src/scenes/rpg/CanteenInteriorModel.ts#L263)
942. 询问第三列第一个同学
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:279](../src/scenes/rpg/CanteenInteriorModel.ts#L279)
943. 1号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:325](../src/scenes/rpg/CanteenInteriorModel.ts#L325)
944. 2号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:339](../src/scenes/rpg/CanteenInteriorModel.ts#L339)
945. 3号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:353](../src/scenes/rpg/CanteenInteriorModel.ts#L353)
946. 4号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:367](../src/scenes/rpg/CanteenInteriorModel.ts#L367)
947. 5号取餐窗口验票槽
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:381](../src/scenes/rpg/CanteenInteriorModel.ts#L381)
948. 第三窗口点餐机
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:464](../src/scenes/rpg/CanteenInteriorModel.ts#L464)
949. {{cart.exitId}}出口餐盘车
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:476](../src/scenes/rpg/CanteenInteriorModel.ts#L476)
950. 食堂东南出口
   来源：[src/scenes/rpg/CanteenInteriorModel.ts:486](../src/scenes/rpg/CanteenInteriorModel.ts#L486)
951. 前面没动，我也没动。大家都很稳定。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:189](../src/scenes/rpg/CanteenInteriorScene.ts#L189)
952. 你说的对。虽然不知道你说了什么。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:190](../src/scenes/rpg/CanteenInteriorScene.ts#L190)
953. 是啊，吃什么。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:191](../src/scenes/rpg/CanteenInteriorScene.ts#L191)
954. 今天有气泡水喝吗？
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:192](../src/scenes/rpg/CanteenInteriorScene.ts#L192)
955. 早十不慌，先来个西红柿鸡蛋。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:193](../src/scenes/rpg/CanteenInteriorScene.ts#L193)
956. 为什么早上吃西红柿鸡蛋。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:194](../src/scenes/rpg/CanteenInteriorScene.ts#L194)
957. 刚才有张纸过去了。它没拿餐盘。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:197](../src/scenes/rpg/CanteenInteriorScene.ts#L197)
958. 看手机。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:198](../src/scenes/rpg/CanteenInteriorScene.ts#L198)
959. 依旧看手机。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:199](../src/scenes/rpg/CanteenInteriorScene.ts#L199)
960. 不用问了可以坐这里。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:200](../src/scenes/rpg/CanteenInteriorScene.ts#L200)
961. 要什么？快点，后面排着呢。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:202](../src/scenes/rpg/CanteenInteriorScene.ts#L202)
962. 交谈
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:966](../src/scenes/rpg/CanteenInteriorScene.ts#L966)；[src/scenes/rpg/CanteenInteriorScene.ts:978](../src/scenes/rpg/CanteenInteriorScene.ts#L978)；[src/scenes/rpg/CanteenInteriorScene.ts:991](../src/scenes/rpg/CanteenInteriorScene.ts#L991)
963. 桌上的餐盘
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1377](../src/scenes/rpg/CanteenInteriorScene.ts#L1377)
964. 号取餐窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1458](../src/scenes/rpg/CanteenInteriorScene.ts#L1458)
965. 拖入 0755 · {{window.value}}号
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1482](../src/scenes/rpg/CanteenInteriorScene.ts#L1482)
966. 站这里 · 再拖票
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1504](../src/scenes/rpg/CanteenInteriorScene.ts#L1504)
967. 玩家：找到了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1626](../src/scenes/rpg/CanteenInteriorScene.ts#L1626)
968. 纸条：！
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:1629](../src/scenes/rpg/CanteenInteriorScene.ts#L1629)
969. {{canteenContent.drinks.shelfPrompt}} / {{canteenContent.drinks.shelfOrder}}
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2048](../src/scenes/rpg/CanteenInteriorScene.ts#L2048)
970. success
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2062](../src/scenes/rpg/CanteenInteriorScene.ts#L2062)；[src/scenes/rpg/CanteenInteriorScene.ts:2125](../src/scenes/rpg/CanteenInteriorScene.ts#L2125)；[src/scenes/rpg/CanteenInteriorScene.ts:3759](../src/scenes/rpg/CanteenInteriorScene.ts#L3759)；[src/scenes/rpg/CanteenInteriorScene.ts:3885](../src/scenes/rpg/CanteenInteriorScene.ts#L3885)；[src/scenes/rpg/QizhenLakeScene.ts:2487](../src/scenes/rpg/QizhenLakeScene.ts#L2487)；[src/scenes/rpg/QizhenLakeScene.ts:2506](../src/scenes/rpg/QizhenLakeScene.ts#L2506)；[src/scenes/rpg/QizhenLakeScene.ts:2517](../src/scenes/rpg/QizhenLakeScene.ts#L2517)；[src/scenes/rpg/QizhenLakeScene.ts:2526](../src/scenes/rpg/QizhenLakeScene.ts#L2526)；[src/scenes/rpg/QizhenLakeScene.ts:2537](../src/scenes/rpg/QizhenLakeScene.ts#L2537)；[src/scenes/rpg/QizhenLakeScene.ts:2542](../src/scenes/rpg/QizhenLakeScene.ts#L2542)；[src/scenes/rpg/QizhenLakeScene.ts:2546](../src/scenes/rpg/QizhenLakeScene.ts#L2546)；[src/scenes/rpg/QizhenLakeScene.ts:2550](../src/scenes/rpg/QizhenLakeScene.ts#L2550)；[src/scenes/rpg/QizhenLakeScene.ts:2554](../src/scenes/rpg/QizhenLakeScene.ts#L2554)；[src/scenes/rpg/QizhenLakeScene.ts:2558](../src/scenes/rpg/QizhenLakeScene.ts#L2558)；[src/scenes/rpg/QizhenLakeScene.ts:2573](../src/scenes/rpg/QizhenLakeScene.ts#L2573)；[src/scenes/rpg/QizhenLakeScene.ts:2577](../src/scenes/rpg/QizhenLakeScene.ts#L2577)；[src/scenes/rpg/QizhenLakeScene.ts:2581](../src/scenes/rpg/QizhenLakeScene.ts#L2581)；[src/scenes/rpg/QizhenLakeScene.ts:2585](../src/scenes/rpg/QizhenLakeScene.ts#L2585)；[src/scenes/rpg/TheaterInteriorScene.ts:1742](../src/scenes/rpg/TheaterInteriorScene.ts#L1742)；[src/scenes/rpg/TheaterInteriorScene.ts:1817](../src/scenes/rpg/TheaterInteriorScene.ts#L1817)；[src/scenes/rpg/TheaterInteriorScene.ts:1852](../src/scenes/rpg/TheaterInteriorScene.ts#L1852)
971. 窗口正常出餐。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2125](../src/scenes/rpg/CanteenInteriorScene.ts#L2125)
972. rpg\_canteen\_tray\_task\_start\_requested
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2299](../src/scenes/rpg/CanteenInteriorScene.ts#L2299)
973. missed\_target
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2408](../src/scenes/rpg/CanteenInteriorScene.ts#L2408)；[src/scenes/rpg/CanteenInteriorScene.ts:2424](../src/scenes/rpg/CanteenInteriorScene.ts#L2424)；[src/scenes/rpg/CanteenInteriorScene.ts:2444](../src/scenes/rpg/CanteenInteriorScene.ts#L2444)；[src/scenes/rpg/TheaterInteriorScene.ts:1473](../src/scenes/rpg/TheaterInteriorScene.ts#L1473)；[src/scenes/rpg/TheaterInteriorScene.ts:1498](../src/scenes/rpg/TheaterInteriorScene.ts#L1498)
974. 玩家自己
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2419](../src/scenes/rpg/CanteenInteriorScene.ts#L2419)
975. 把难喝饮料拖到人物自己身上才能喝掉。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2425](../src/scenes/rpg/CanteenInteriorScene.ts#L2425)
976. dailySpecialSparklingWater
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2445](../src/scenes/rpg/CanteenInteriorScene.ts#L2445)
977. 请拖到第五个打饭窗口下方宣传板的发光空杯位。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2446](../src/scenes/rpg/CanteenInteriorScene.ts#L2446)
978. 小票不需要拖拽：靠近取餐窗口后按空格使用。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2447](../src/scenes/rpg/CanteenInteriorScene.ts#L2447)
979. wrong\_item
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2454](../src/scenes/rpg/CanteenInteriorScene.ts#L2454)；[src/scenes/rpg/TheaterInteriorScene.ts:1507](../src/scenes/rpg/TheaterInteriorScene.ts#L1507)
980. light
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2464](../src/scenes/rpg/CanteenInteriorScene.ts#L2464)；[src/scenes/rpg/TheaterInteriorScene.ts:1517](../src/scenes/rpg/TheaterInteriorScene.ts#L1517)
981. too\_far
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2471](../src/scenes/rpg/CanteenInteriorScene.ts#L2471)；[src/scenes/rpg/TheaterInteriorScene.ts:1524](../src/scenes/rpg/TheaterInteriorScene.ts#L1524)
982. promo
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2473](../src/scenes/rpg/CanteenInteriorScene.ts#L2473)
983. 落点正确；人物还没有靠近宣传板。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2474](../src/scenes/rpg/CanteenInteriorScene.ts#L2474)
984. 落点正确；靠近设施后再操作。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2475](../src/scenes/rpg/CanteenInteriorScene.ts#L2475)
985. 先把手上的餐盘交给阿姨
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2673](../src/scenes/rpg/CanteenInteriorScene.ts#L2673)
986. 拿起桌上的餐盘
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2674](../src/scenes/rpg/CanteenInteriorScene.ts#L2674)
987. 使用点餐机
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2676](../src/scenes/rpg/CanteenInteriorScene.ts#L2676)
988. 查看{{nearest.value}}号窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2679](../src/scenes/rpg/CanteenInteriorScene.ts#L2679)
989. 使用小票 · {{nearest.value}}号窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2681](../src/scenes/rpg/CanteenInteriorScene.ts#L2681)
990. {{nearest.value}}号取餐窗口
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2682](../src/scenes/rpg/CanteenInteriorScene.ts#L2682)
991. 把今日新品放入宣传板空杯位
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2685](../src/scenes/rpg/CanteenInteriorScene.ts#L2685)
992. 宣传板空杯位
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2686](../src/scenes/rpg/CanteenInteriorScene.ts#L2686)
993. 确认蓝色轨迹指向
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2689](../src/scenes/rpg/CanteenInteriorScene.ts#L2689)
994. 靠近餐盘车把手
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2690](../src/scenes/rpg/CanteenInteriorScene.ts#L2690)
995. 靠近东南门离开食堂
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:2692](../src/scenes/rpg/CanteenInteriorScene.ts#L2692)
996. 气泡水（蓝色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3044](../src/scenes/rpg/CanteenInteriorScene.ts#L3044)
997. 柠檬茶（白色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3045](../src/scenes/rpg/CanteenInteriorScene.ts#L3045)
998. 黑咖啡（黑色）
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3046](../src/scenes/rpg/CanteenInteriorScene.ts#L3046)
999. ← / → 选择 · 空格 / 回车确认 · Esc 退出
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3083](../src/scenes/rpg/CanteenInteriorScene.ts#L3083)
1000. 食堂新品混合台
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3195](../src/scenes/rpg/CanteenInteriorScene.ts#L3195)
1001. 退出 Esc
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3203](../src/scenes/rpg/CanteenInteriorScene.ts#L3203)
1002. 大玻璃杯
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3226](../src/scenes/rpg/CanteenInteriorScene.ts#L3226)
1003. 货架提示已记录：黑色 → 蓝色 → 白色
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3237](../src/scenes/rpg/CanteenInteriorScene.ts#L3237)
1004. 货架提示：尚未查看
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3238](../src/scenes/rpg/CanteenInteriorScene.ts#L3238)
1005. 黑咖啡
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3249](../src/scenes/rpg/CanteenInteriorScene.ts#L3249)
1006. 气泡水
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3250](../src/scenes/rpg/CanteenInteriorScene.ts#L3250)
1007. 柠檬茶
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3251](../src/scenes/rpg/CanteenInteriorScene.ts#L3251)
1008. {{button.name}}·未持有
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3265](../src/scenes/rpg/CanteenInteriorScene.ts#L3265)
1009. 倒入{{button.name}}
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3265](../src/scenes/rpg/CanteenInteriorScene.ts#L3265)
1010. 观察模式 · 菜名留下了另一层字
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3342](../src/scenes/rpg/CanteenInteriorScene.ts#L3342)
1011. 选择一份餐品 · 取餐前不能重复下单
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3343](../src/scenes/rpg/CanteenInteriorScene.ts#L3343)
1012. 玩家：那是鸡吗？
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3488](../src/scenes/rpg/CanteenInteriorScene.ts#L3488)
1013. 系统：现在不是了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3488](../src/scenes/rpg/CanteenInteriorScene.ts#L3488)
1014. 本人马上回来。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3584](../src/scenes/rpg/CanteenInteriorScene.ts#L3584)
1015. 场景仍在初始化，请稍后再试。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3718](../src/scenes/rpg/CanteenInteriorScene.ts#L3718)
1016. 纸条暂时没有找到能钻出去的流程。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3759](../src/scenes/rpg/CanteenInteriorScene.ts#L3759)
1017. 左上门
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3764](../src/scenes/rpg/CanteenInteriorScene.ts#L3764)
1018. 左中下通道
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3765](../src/scenes/rpg/CanteenInteriorScene.ts#L3765)
1019. 右下门
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3766](../src/scenes/rpg/CanteenInteriorScene.ts#L3766)
1020. 纸条从{{exitLabel\[exitId\]}}溜走了。
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3768](../src/scenes/rpg/CanteenInteriorScene.ts#L3768)
1021. rpg\_canteen\_leave\_requested
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3903](../src/scenes/rpg/CanteenInteriorScene.ts#L3903)
1022. 玩家：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3927](../src/scenes/rpg/CanteenInteriorScene.ts#L3927)；[src/scenes/rpg/QizhenLakeScene.ts:3104](../src/scenes/rpg/QizhenLakeScene.ts#L3104)；[src/scenes/rpg/QizhenLoopScene.ts:348](../src/scenes/rpg/QizhenLoopScene.ts#L348)；[src/scenes/rpg/TheaterInteriorScene.ts:2599](../src/scenes/rpg/TheaterInteriorScene.ts#L2599)
1023. 系统：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3928](../src/scenes/rpg/CanteenInteriorScene.ts#L3928)；[src/scenes/rpg/QizhenLakeScene.ts:3105](../src/scenes/rpg/QizhenLakeScene.ts#L3105)；[src/scenes/rpg/QizhenLoopScene.ts:349](../src/scenes/rpg/QizhenLoopScene.ts#L349)；[src/scenes/rpg/TheaterInteriorScene.ts:2600](../src/scenes/rpg/TheaterInteriorScene.ts#L2600)
1024. 任务：
   来源：[src/scenes/rpg/CanteenInteriorScene.ts:3929](../src/scenes/rpg/CanteenInteriorScene.ts#L3929)；[src/scenes/rpg/QizhenLakeScene.ts:3106](../src/scenes/rpg/QizhenLakeScene.ts#L3106)；[src/scenes/rpg/QizhenLoopScene.ts:350](../src/scenes/rpg/QizhenLoopScene.ts#L350)；[src/scenes/rpg/TheaterInteriorScene.ts:2601](../src/scenes/rpg/TheaterInteriorScene.ts#L2601)
1025. 左收线
   来源：[src/scenes/rpg/QizhenFishingRhythmLayout.ts:11](../src/scenes/rpg/QizhenFishingRhythmLayout.ts#L11)
1026. 提竿
   来源：[src/scenes/rpg/QizhenFishingRhythmLayout.ts:12](../src/scenes/rpg/QizhenFishingRhythmLayout.ts#L12)
1027. 右收线
   来源：[src/scenes/rpg/QizhenFishingRhythmLayout.ts:13](../src/scenes/rpg/QizhenFishingRhythmLayout.ts#L13)
1028. 错过
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:18](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L18)
1029. 精准
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:18](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L18)
1030. 良好
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:18](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L18)
1031. 命中
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:18](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L18)
1032. 节奏钓取 · {{options.targetLabel}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:61](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L61)
1033. 短块点按 · 长条按住到尾端过线
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:63](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L63)
1034. · 绷紧 ▲
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:92](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L92)
1035. · 松线 ▼
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:92](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L92)
1036. {{this.model.judgedCount}}/{{this.model.totalNotes}} 张力 {{tension}}{{alert}} 连击 {{this.model.combo}}{{this.model.assist ? " · 辅助" : ""}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:93](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L93)
1037. 保持按住
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:124](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L124)
1038. 到线时按对应键
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:124](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L124)
1039. 收线中
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:124](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L124)
1040. 松开过早
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:163](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L163)
1041. 钓取成功 · {{result.grade}}
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:188](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L188)
1042. 准确率 {{(result.accuracy \* 100).toFixed(0)}}%
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:188](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L188)
1043. 钓线断了
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:192](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L192)
1044. 脱钩了
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:192](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L192)
1045. 这次没钓住
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:192](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L192)
1046. 道具已保留，可以重试
   来源：[src/scenes/rpg/QizhenFishingRhythmVisual.ts:193](../src/scenes/rpg/QizhenFishingRhythmVisual.ts#L193)
1047. 器材架上的皮划艇
   来源：[src/scenes/rpg/QizhenLakeModel.ts:384](../src/scenes/rpg/QizhenLakeModel.ts#L384)
1048. 花坛边的细长物体
   来源：[src/scenes/rpg/QizhenLakeModel.ts:385](../src/scenes/rpg/QizhenLakeModel.ts#L385)
1049. 设备区的旧设施
   来源：[src/scenes/rpg/QizhenLakeModel.ts:386](../src/scenes/rpg/QizhenLakeModel.ts#L386)
1050. 小码头登船边
   来源：[src/scenes/rpg/QizhenLakeModel.ts:387](../src/scenes/rpg/QizhenLakeModel.ts#L387)
1051. 湖边值班老师
   来源：[src/scenes/rpg/QizhenLakeModel.ts:388](../src/scenes/rpg/QizhenLakeModel.ts#L388)
1052. 码头储物柜
   来源：[src/scenes/rpg/QizhenLakeModel.ts:389](../src/scenes/rpg/QizhenLakeModel.ts#L389)
1053. 划向大湖
   来源：[src/scenes/rpg/QizhenLakeModel.ts:390](../src/scenes/rpg/QizhenLakeModel.ts#L390)
1054. 返回小码头
   来源：[src/scenes/rpg/QizhenLakeModel.ts:392](../src/scenes/rpg/QizhenLakeModel.ts#L392)
1055. 前往黑天鹅围栏
   来源：[src/scenes/rpg/QizhenLakeModel.ts:393](../src/scenes/rpg/QizhenLakeModel.ts#L393)
1056. 进入浮排河道
   来源：[src/scenes/rpg/QizhenLakeModel.ts:394](../src/scenes/rpg/QizhenLakeModel.ts#L394)
1057. 纸条倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:395](../src/scenes/rpg/QizhenLakeModel.ts#L395)
1058. 钥匙倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:396](../src/scenes/rpg/QizhenLakeModel.ts#L396)
1059. 网框倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:397](../src/scenes/rpg/QizhenLakeModel.ts#L397)
1060. 鱼群倒影位置
   来源：[src/scenes/rpg/QizhenLakeModel.ts:398](../src/scenes/rpg/QizhenLakeModel.ts#L398)
1061. 漂浮的钓鱼竿
   来源：[src/scenes/rpg/QizhenLakeModel.ts:399](../src/scenes/rpg/QizhenLakeModel.ts#L399)
1062. 纸条倒影水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:400](../src/scenes/rpg/QizhenLakeModel.ts#L400)
1063. 钥匙水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:401](../src/scenes/rpg/QizhenLakeModel.ts#L401)
1064. 鱼群聚拢的水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:402](../src/scenes/rpg/QizhenLakeModel.ts#L402)
1065. 最终钓具装配位
   来源：[src/scenes/rpg/QizhenLakeModel.ts:403](../src/scenes/rpg/QizhenLakeModel.ts#L403)
1066. 返回大湖
   来源：[src/scenes/rpg/QizhenLakeModel.ts:405](../src/scenes/rpg/QizhenLakeModel.ts#L405)；[src/scenes/rpg/QizhenLakeModel.ts:411](../src/scenes/rpg/QizhenLakeModel.ts#L411)
1067. 进入返航河道
   来源：[src/scenes/rpg/QizhenLakeModel.ts:406](../src/scenes/rpg/QizhenLakeModel.ts#L406)
1068. 围栏边的黑天鹅
   来源：[src/scenes/rpg/QizhenLakeModel.ts:407](../src/scenes/rpg/QizhenLakeModel.ts#L407)
1069. 纸条本体水纹
   来源：[src/scenes/rpg/QizhenLakeModel.ts:408](../src/scenes/rpg/QizhenLakeModel.ts#L408)
1070. 黑天鹅追逐起点
   来源：[src/scenes/rpg/QizhenLakeModel.ts:410](../src/scenes/rpg/QizhenLakeModel.ts#L410)
1071. 浮排下的破损网框
   来源：[src/scenes/rpg/QizhenLakeModel.ts:412](../src/scenes/rpg/QizhenLakeModel.ts#L412)
1072. 小码头方向
   来源：[src/scenes/rpg/QizhenLakeModel.ts:413](../src/scenes/rpg/QizhenLakeModel.ts#L413)
1073. 湖心全景:朝北取景时西北柳岛与整片开阔水面入镜,船体落在画面下缘。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:501](../src/scenes/rpg/QizhenLakeModel.ts#L501)
1074. 小码头:木栈道、器材架与登船边入镜;徒步或乘艇都可取景。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:517](../src/scenes/rpg/QizhenLakeModel.ts#L517)
1075. 倒影水面
   来源：[src/scenes/rpg/QizhenLakeModel.ts:522](../src/scenes/rpg/QizhenLakeModel.ts#L522)
1076. 倒影水面:东侧倒影区入镜;水面平静时倒影完整,船速与侧倾大时水纹断开。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:528](../src/scenes/rpg/QizhenLakeModel.ts#L528)
1077. 黑天鹅围栏:从围栏外水域取景,黑天鹅在围栏内游动;鹅离开后只剩空围栏与水痕。
   来源：[src/scenes/rpg/QizhenLakeModel.ts:540](../src/scenes/rpg/QizhenLakeModel.ts#L540)
1078. rpg\_qizhen\_intro\_seen\_requested
   来源：[src/scenes/rpg/QizhenLakeScene.ts:554](../src/scenes/rpg/QizhenLakeScene.ts#L554)
1079. {{qizhenContent.chase.caught}}{{qizhenContent.chase.failed}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1008](../src/scenes/rpg/QizhenLakeScene.ts#L1008)
1080. swan\_caught
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1010](../src/scenes/rpg/QizhenLakeScene.ts#L1010)
1081. {{qizhenContent.boarding.capsizeSameSide}}{{qizhenContent.chase.failed}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1039](../src/scenes/rpg/QizhenLakeScene.ts#L1039)
1082. 节奏钓取未能启动，道具已保留，请重试。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:1829](../src/scenes/rpg/QizhenLakeScene.ts#L1829)
1083. 未通过：道具已保留。下次将扩大判定窗口并精简节拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2106](../src/scenes/rpg/QizhenLakeScene.ts#L2106)
1084. 未通过：道具已保留，靠近同一水纹可立即重试。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2107](../src/scenes/rpg/QizhenLakeScene.ts#L2107)
1085. {{qizhenContent.mist.darkPrompt}} {{formatRpgModeRequirement("light")}}
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2163](../src/scenes/rpg/QizhenLakeScene.ts#L2163)
1086. locker\_key
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2536](../src/scenes/rpg/QizhenLakeScene.ts#L2536)
1087. 浮排边的旧饲料盒被捞起并撬开。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2567](../src/scenes/rpg/QizhenLakeScene.ts#L2567)
1088. 饲料撒入围栏，黑天鹅把一枚磁性扣推到船边。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2568](../src/scenes/rpg/QizhenLakeScene.ts#L2568)
1089. 尼龙绳、破损网框和磁性扣已装到钓鱼竿上，可以捕纸了。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2573](../src/scenes/rpg/QizhenLakeScene.ts#L2573)
1090. player
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2856](../src/scenes/rpg/QizhenLakeScene.ts#L2856)
1091. 相机
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2865](../src/scenes/rpg/QizhenLakeScene.ts#L2865)
1092. 正在节奏钓取,收竿后再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2897](../src/scenes/rpg/QizhenLakeScene.ts#L2897)
1093. 黑天鹅正追着船尾,顾不上拍照。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2903](../src/scenes/rpg/QizhenLakeScene.ts#L2903)
1094. 这里要上船后才能取景。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2907](../src/scenes/rpg/QizhenLakeScene.ts#L2907)
1095. 船还没停稳,等一下再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2911](../src/scenes/rpg/QizhenLakeScene.ts#L2911)
1096. 先听完这段话,再打开相机。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2915](../src/scenes/rpg/QizhenLakeScene.ts#L2915)
1097. 这里构不成画面,再往{{nearest.label}}靠一靠。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2923](../src/scenes/rpg/QizhenLakeScene.ts#L2923)
1098. 河道里取景太窄,去大湖面或黑天鹅围栏旁再拍。
   来源：[src/scenes/rpg/QizhenLakeScene.ts:2924](../src/scenes/rpg/QizhenLakeScene.ts#L2924)
1099. forced\_launch\_capsize
   来源：[src/scenes/rpg/QizhenLakeScene.ts:3377](../src/scenes/rpg/QizhenLakeScene.ts#L3377)；[src/scenes/rpg/QizhenLakeScene.ts:3390](../src/scenes/rpg/QizhenLakeScene.ts#L3390)
1100. 启真湖入口
   来源：[src/scenes/rpg/QizhenLoopScene.ts:44](../src/scenes/rpg/QizhenLoopScene.ts#L44)
1101. 查看入口
   来源：[src/scenes/rpg/QizhenLoopScene.ts:45](../src/scenes/rpg/QizhenLoopScene.ts#L45)
1102. 系统：还没确认湿纸指向的地点。先核对论坛、馆藏记录和地图线索。
   来源：[src/scenes/rpg/QizhenLoopScene.ts:46](../src/scenes/rpg/QizhenLoopScene.ts#L46)
1103. {{GATE\_ENTRY\_LABEL}} · {{formatRpgInteractionHint("进入启真湖")}}
   来源：[src/scenes/rpg/QizhenLoopScene.ts:203](../src/scenes/rpg/QizhenLoopScene.ts#L203)；[src/scenes/rpg/QizhenLoopScene.ts:237](../src/scenes/rpg/QizhenLoopScene.ts#L237)
1104. 启真湖雨天落水救援回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:60](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L60)
1105. 值班老师和安全员把落水学生拉回码头
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:71](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L71)
1106. 启真湖 · 雨天救援
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:81](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L81)
1107. 正在将落水者拉回码头
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:82](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L82)
1108. 正在载入救援回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:82](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L82)
1109. 跳过回放
   来源：[src/scenes/rpg/QizhenRainRescueCinematic.tsx:88](../src/scenes/rpg/QizhenRainRescueCinematic.tsx#L88)
1110. 入口海报玻璃
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:95](../src/scenes/rpg/TheaterInteriorModel.ts#L95)
1111. 临时票打印机
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:113](../src/scenes/rpg/TheaterInteriorModel.ts#L113)
1112. 检票闸机右侧读票器
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:124](../src/scenes/rpg/TheaterInteriorModel.ts#L124)；[src/scenes/rpg/TheaterInteriorScene.ts:196](../src/scenes/rpg/TheaterInteriorScene.ts#L196)
1113. 开场节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:137](../src/scenes/rpg/TheaterInteriorModel.ts#L137)
1114. 追光节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:138](../src/scenes/rpg/TheaterInteriorModel.ts#L138)
1115. 终场节目单残页
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:139](../src/scenes/rpg/TheaterInteriorModel.ts#L139)
1116. 剧院灯光控制台
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:142](../src/scenes/rpg/TheaterInteriorModel.ts#L142)
1117. 后台道具箱
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:157](../src/scenes/rpg/TheaterInteriorModel.ts#L157)
1118. 道具箱旁票据扫描器
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:167](../src/scenes/rpg/TheaterInteriorModel.ts#L167)；[src/scenes/rpg/TheaterInteriorScene.ts:197](../src/scenes/rpg/TheaterInteriorScene.ts#L197)
1119. 后台通风口
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:182](../src/scenes/rpg/TheaterInteriorModel.ts#L182)；[src/scenes/rpg/TheaterInteriorScene.ts:198](../src/scenes/rpg/TheaterInteriorScene.ts#L198)
1120. 剧院出口
   来源：[src/scenes/rpg/TheaterInteriorModel.ts:195](../src/scenes/rpg/TheaterInteriorModel.ts#L195)；[src/scenes/rpg/TheaterInteriorScene.ts:203](../src/scenes/rpg/TheaterInteriorScene.ts#L203)
1121. 灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:138](../src/scenes/rpg/TheaterInteriorScene.ts#L138)
1122. 检票员
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:138](../src/scenes/rpg/TheaterInteriorScene.ts#L138)
1123. 取票机
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:138](../src/scenes/rpg/TheaterInteriorScene.ts#L138)；[src/scenes/rpg/TheaterInteriorScene.ts:200](../src/scenes/rpg/TheaterInteriorScene.ts#L200)
1124. 手机系统
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:138](../src/scenes/rpg/TheaterInteriorScene.ts#L138)
1125. 手机充电服务站
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:194](../src/scenes/rpg/TheaterInteriorScene.ts#L194)
1126. 入口海报
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:195](../src/scenes/rpg/TheaterInteriorScene.ts#L195)
1127. 灯光控制台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:199](../src/scenes/rpg/TheaterInteriorScene.ts#L199)
1128. 节目单
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:201](../src/scenes/rpg/TheaterInteriorScene.ts#L201)
1129. 道具箱
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:202](../src/scenes/rpg/TheaterInteriorScene.ts#L202)
1130. 充电
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:674](../src/scenes/rpg/TheaterInteriorScene.ts#L674)
1131. wrong\_mode
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:703](../src/scenes/rpg/TheaterInteriorScene.ts#L703)
1132. 充电站配有两条接线。切到浅色操作后可以接入手机。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:704](../src/scenes/rpg/TheaterInteriorScene.ts#L704)
1133. 请走到充电服务站旁接线。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:705](../src/scenes/rpg/TheaterInteriorScene.ts#L705)
1134. 当前电量 {{state.phoneBattery.percent}}%，暂不需要补电。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:709](../src/scenes/rpg/TheaterInteriorScene.ts#L709)
1135. 接线已断开，本次补电未完成。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:722](../src/scenes/rpg/TheaterInteriorScene.ts#L722)
1136. 补电 {{Math.floor(progress \* 100)}}%
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:745](../src/scenes/rpg/TheaterInteriorScene.ts#L745)
1137. 电量 {{battery}}%
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:745](../src/scenes/rpg/TheaterInteriorScene.ts#L745)
1138. 验票
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:808](../src/scenes/rpg/TheaterInteriorScene.ts#L808)
1139. posted
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1114](../src/scenes/rpg/TheaterInteriorScene.ts#L1114)；[src/scenes/rpg/TheaterInteriorScene.ts:1286](../src/scenes/rpg/TheaterInteriorScene.ts#L1286)
1140. theater\_decoy\_inspect\_requested
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1200](../src/scenes/rpg/TheaterInteriorScene.ts#L1200)
1141. dark
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1327](../src/scenes/rpg/TheaterInteriorScene.ts#L1327)；[src/scenes/rpg/TheaterInteriorScene.ts:1329](../src/scenes/rpg/TheaterInteriorScene.ts#L1329)
1142. 查看充电服务站
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1399](../src/scenes/rpg/TheaterInteriorScene.ts#L1399)
1143. 接入手机充电线
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1400](../src/scenes/rpg/TheaterInteriorScene.ts#L1400)
1144. 正在补电，请在设备旁稍候
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1400](../src/scenes/rpg/TheaterInteriorScene.ts#L1400)
1145. 查看海报栏
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1402](../src/scenes/rpg/TheaterInteriorScene.ts#L1402)
1146. 油渍纸巾 → 入口海报
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1402](../src/scenes/rpg/TheaterInteriorScene.ts#L1402)
1147. 查看取票机
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1405](../src/scenes/rpg/TheaterInteriorScene.ts#L1405)；[src/scenes/rpg/TheaterInteriorScene.ts:1408](../src/scenes/rpg/TheaterInteriorScene.ts#L1408)
1148. 输入取票码
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1407](../src/scenes/rpg/TheaterInteriorScene.ts#L1407)
1149. 临时观演票 → 右侧验票槽
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1410](../src/scenes/rpg/TheaterInteriorScene.ts#L1410)
1150. 与检票员对话
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1410](../src/scenes/rpg/TheaterInteriorScene.ts#L1410)
1151. 查看残影
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1412](../src/scenes/rpg/TheaterInteriorScene.ts#L1412)
1152. 取得节目单残页
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1412](../src/scenes/rpg/TheaterInteriorScene.ts#L1412)
1153. 操作灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1414](../src/scenes/rpg/TheaterInteriorScene.ts#L1414)
1154. 追光灯遥控器 → 灯控台
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1414](../src/scenes/rpg/TheaterInteriorScene.ts#L1414)
1155. 查看道具箱
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1416](../src/scenes/rpg/TheaterInteriorScene.ts#L1416)
1156. 检查票据扫描器
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1418](../src/scenes/rpg/TheaterInteriorScene.ts#L1418)
1157. 临时观演票 → 票据扫描口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1418](../src/scenes/rpg/TheaterInteriorScene.ts#L1418)
1158. 离开剧院
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1420](../src/scenes/rpg/TheaterInteriorScene.ts#L1420)
1159. 检查后台通风口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1421](../src/scenes/rpg/TheaterInteriorScene.ts#L1421)
1160. 荧光粉刷 → 后台通风口
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1421](../src/scenes/rpg/TheaterInteriorScene.ts#L1421)
1161. 票已退回：请拖到检票闸机右侧发蓝光的「验票」读票器框内。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1491](../src/scenes/rpg/TheaterInteriorScene.ts#L1491)
1162. 票已退回：请拖到道具箱旁发蓝光的票据扫描口框内。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1493](../src/scenes/rpg/TheaterInteriorScene.ts#L1493)
1163. 票已退回：当前阶段没有临时观演票的使用点。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1494](../src/scenes/rpg/TheaterInteriorScene.ts#L1494)
1164. 道具没有放到当前阶段对应的真实物体。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1495](../src/scenes/rpg/TheaterInteriorScene.ts#L1495)
1165. temporaryTheaterTicket
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1526](../src/scenes/rpg/TheaterInteriorScene.ts#L1526)
1166. gate
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1527](../src/scenes/rpg/TheaterInteriorScene.ts#L1527)
1167. 票已退回；请靠近读票器。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1528](../src/scenes/rpg/TheaterInteriorScene.ts#L1528)
1168. 票已退回；请靠近扫描器。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1529](../src/scenes/rpg/TheaterInteriorScene.ts#L1529)
1169. 退格
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1564](../src/scenes/rpg/TheaterInteriorScene.ts#L1564)
1170. 提交
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1568](../src/scenes/rpg/TheaterInteriorScene.ts#L1568)；[src/scenes/rpg/TheaterInteriorScene.ts:1614](../src/scenes/rpg/TheaterInteriorScene.ts#L1614)
1171. 撤回
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1607](../src/scenes/rpg/TheaterInteriorScene.ts#L1607)
1172. 清空
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1611](../src/scenes/rpg/TheaterInteriorScene.ts#L1611)
1173. 第 {{round + 1}} / 3 轮 · 观察
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1883](../src/scenes/rpg/TheaterInteriorScene.ts#L1883)
1174. 观察尾迹，记住最后一个灯区。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1890](../src/scenes/rpg/TheaterInteriorScene.ts#L1890)
1175. 右
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1956](../src/scenes/rpg/TheaterInteriorScene.ts#L1956)
1176. 中
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1956](../src/scenes/rpg/TheaterInteriorScene.ts#L1956)
1177. 左
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:1956](../src/scenes/rpg/TheaterInteriorScene.ts#L1956)
1178. 第 {{round + 1}} / 3 轮 · 预置
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2090](../src/scenes/rpg/TheaterInteriorScene.ts#L2090)
1179. 预置追光灯
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2091](../src/scenes/rpg/TheaterInteriorScene.ts#L2091)
1180. 拖动下方滑轨，或按 ← / → 移动。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2092](../src/scenes/rpg/TheaterInteriorScene.ts#L2092)
1181. 深色观察可核对尾迹；切至浅色操作后启动追光灯。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2110](../src/scenes/rpg/TheaterInteriorScene.ts#L2110)
1182. Tab 切换模式；切换不会重置本轮观察。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2112](../src/scenes/rpg/TheaterInteriorScene.ts#L2112)
1183. 浅色操作已就绪，追光灯正在启动。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2117](../src/scenes/rpg/TheaterInteriorScene.ts#L2117)
1184. 第 {{round + 1}} / 3 轮 · 锁定
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2138](../src/scenes/rpg/TheaterInteriorScene.ts#L2138)
1185. 断裂尾迹是假残影。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2230](../src/scenes/rpg/TheaterInteriorScene.ts#L2230)
1186. 锁定中，保持照射。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2234](../src/scenes/rpg/TheaterInteriorScene.ts#L2234)
1187. 光圈脱离纸条，重新锁定。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2237](../src/scenes/rpg/TheaterInteriorScene.ts#L2237)
1188. 第 {{hitCount}} / 3 轮 · 命中
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2352](../src/scenes/rpg/TheaterInteriorScene.ts#L2352)
1189. {{theaterContent.spotlight.hit}} 已命中 {{hitCount}} / 3
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2353](../src/scenes/rpg/TheaterInteriorScene.ts#L2353)
1190. 连续锁定完成。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2354](../src/scenes/rpg/TheaterInteriorScene.ts#L2354)
1191. 第 {{this.runtime.getState().theaterHunt.spotlightRound + 1}} / 3 轮 · 重试
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2422](../src/scenes/rpg/TheaterInteriorScene.ts#L2422)
1192. 保持已完成轮次，重新观察本轮。
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2428](../src/scenes/rpg/TheaterInteriorScene.ts#L2428)
1193. 手机系统：
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2600](../src/scenes/rpg/TheaterInteriorScene.ts#L2600)
1194. {{name}}：
   来源：[src/scenes/rpg/TheaterInteriorScene.ts:2606](../src/scenes/rpg/TheaterInteriorScene.ts#L2606)

## 3.5章过渡

1. 状态栏
   来源：[src/components/StatusBar.tsx:31](../src/components/StatusBar.tsx#L31)
2. 状态时间已冻结，等待旧钟成为时间来源
   来源：[src/components/StatusBar.tsx:35](../src/components/StatusBar.tsx#L35)
3. 时间不可信
   来源：[src/components/StatusBar.tsx:39](../src/components/StatusBar.tsx#L39)
4. 不可信
   来源：[src/components/StatusBar.tsx:40](../src/components/StatusBar.tsx#L40)
5. completed
   来源：[src/core/QuestModel.ts:800](../src/core/QuestModel.ts#L800)
6. pending
   来源：[src/core/QuestModel.ts:800](../src/core/QuestModel.ts#L800)
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
89. 查清离开湖边的时间
   来源：[src/data/chapter3InterludeContent.ts:133](../src/data/chapter3InterludeContent.ts#L133)
90. 离开湖边时有没有留下带时间的记录？
   来源：[src/data/chapter3InterludeContent.ts:135](../src/data/chapter3InterludeContent.ts#L135)
91. CC98 划船记录保留了带时间的最后回复。
   来源：[src/data/chapter3InterludeContent.ts:136](../src/data/chapter3InterludeContent.ts#L136)
92. 打开划船记录帖并保存最后一条离湖回复。
   来源：[src/data/chapter3InterludeContent.ts:137](../src/data/chapter3InterludeContent.ts#L137)
93. 查清离湖后去了哪里
   来源：[src/data/chapter3InterludeContent.ts:143](../src/data/chapter3InterludeContent.ts#L143)
94. 照片拍到了哪里，录音里又有哪些声音？先从手边的一项看起。
   来源：[src/data/chapter3InterludeContent.ts:145](../src/data/chapter3InterludeContent.ts#L145)
95. 消息与网络记录也留着线索；任务栏可以打开对应应用。
   来源：[src/data/chapter3InterludeContent.ts:146](../src/data/chapter3InterludeContent.ts#L146)
96. 四项都查过以后，回记录恢复页核对时间。
   来源：[src/data/chapter3InterludeContent.ts:147](../src/data/chapter3InterludeContent.ts#L147)
97. 排除旧时间记录
   来源：[src/data/chapter3InterludeContent.ts:153](../src/data/chapter3InterludeContent.ts#L153)
98. 这些数字分别记的是什么？其中有一条只是取餐编号。
   来源：[src/data/chapter3InterludeContent.ts:155](../src/data/chapter3InterludeContent.ts#L155)
99. 再看记录发生在什么时候、本机时钟有没有同步。
   来源：[src/data/chapter3InterludeContent.ts:156](../src/data/chapter3InterludeContent.ts#L156)
100. 给每条不能采用的时间选择理由。写着数字，不等于能拿来校时。
   来源：[src/data/chapter3InterludeContent.ts:157](../src/data/chapter3InterludeContent.ts#L157)
101. 根据证据确认目的地
   来源：[src/data/chapter3InterludeContent.ts:163](../src/data/chapter3InterludeContent.ts#L163)
102. 比较每个候选地点与四项证据是否存在冲突。
   来源：[src/data/chapter3InterludeContent.ts:165](../src/data/chapter3InterludeContent.ts#L165)
103. 同时核对水面离开、室内路线、网络记录和闭楼广播。
   来源：[src/data/chapter3InterludeContent.ts:166](../src/data/chapter3InterludeContent.ts#L166)
104. 回到记录恢复页，选一个能解释全部记录的地点。
   来源：[src/data/chapter3InterludeContent.ts:167](../src/data/chapter3InterludeContent.ts#L167)
105. 回看离湖后的那段路
   来源：[src/data/chapter3InterludeContent.ts:173](../src/data/chapter3InterludeContent.ts#L173)
106. 去向已经查清，可以把记录连起来看了。
   来源：[src/data/chapter3InterludeContent.ts:175](../src/data/chapter3InterludeContent.ts#L175)
107. 这段路有照片和声音留下，你的手机却没记准时间。
   来源：[src/data/chapter3InterludeContent.ts:176](../src/data/chapter3InterludeContent.ts#L176)
108. 在记录恢复页开始回放。
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
   来源：[src/scenes/phone/P02_CC98/index.tsx:432](../src/scenes/phone/P02_CC98/index.tsx#L432)
121. 启真湖划船记录收尾
   来源：[src/scenes/phone/P02_CC98/index.tsx:436](../src/scenes/phone/P02_CC98/index.tsx#L436)
122. 退出帖子，返回记录恢复
   来源：[src/scenes/phone/P02_CC98/index.tsx:441](../src/scenes/phone/P02_CC98/index.tsx#L441)
123. CC98小程序
   来源：[src/scenes/phone/P02_CC98/index.tsx:444](../src/scenes/phone/P02_CC98/index.tsx#L444)
124. 林星宇
   来源：[src/scenes/phone/P02_CC98/index.tsx:449](../src/scenes/phone/P02_CC98/index.tsx#L449)；[src/scenes/phone/P20_TimelineRecovery/index.tsx:126](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L126)
125. 楼主 · 22:37
   来源：[src/scenes/phone/P02_CC98/index.tsx:449](../src/scenes/phone/P02_CC98/index.tsx#L449)
126. 舟
   来源：[src/scenes/phone/P02_CC98/index.tsx:449](../src/scenes/phone/P02_CC98/index.tsx#L449)
127. 启真湖划船记录｜风景很好，返程提前了
   来源：[src/scenes/phone/P02_CC98/index.tsx:450](../src/scenes/phone/P02_CC98/index.tsx#L450)
128. 退出
   来源：[src/scenes/phone/P02_CC98/index.tsx:670](../src/scenes/phone/P02_CC98/index.tsx#L670)；[src/scenes/phone/P15_Zjuding/index.tsx:1219](../src/scenes/phone/P15_Zjuding/index.tsx#L1219)
129. 找到 4 条候选记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:692](../src/scenes/phone/P02_CC98/index.tsx#L692)
130. 需要能说明纸张状态的实物线索。
   来源：[src/scenes/phone/P02_CC98/index.tsx:698](../src/scenes/phone/P02_CC98/index.tsx#L698)
131. 找到 1 条刚发布的目击帖。
   来源：[src/scenes/phone/P02_CC98/index.tsx:702](../src/scenes/phone/P02_CC98/index.tsx#L702)
132. 当前无法记录这条目击信息。
   来源：[src/scenes/phone/P02_CC98/index.tsx:707](../src/scenes/phone/P02_CC98/index.tsx#L707)
133. {{qizhenContent.locationSearch.cc98.system}} / {{qizhenContent.locationSearch.cc98.player}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:710](../src/scenes/phone/P02_CC98/index.tsx#L710)
134. 小雨。局部黏着物可能松动。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:59](../src/scenes/phone/P13_PhoneHome/index.tsx#L59)
135. 多云。启真湖小码头降水已经停止。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:60](../src/scenes/phone/P13_PhoneHome/index.tsx#L60)
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
190. 保存的接入记录对不上这个地点，再看一遍网络记录。
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
210. 照片、录音、消息都存了，就是没记清你去了哪。先看还能读出的。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:127](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L127)
211. 打开恢复工具
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:129](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L129)
212. 对照离湖时刻和最后一段录音，查清这段时间发生了什么。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:142](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L142)
213. 先查离湖时间
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:149](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L149)
214. 划船帖的最后一条回复保留了带来源的离湖时间。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:150](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L150)
215. 查看划船帖
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:151](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L151)
216. 四类证据并行恢复，已完成 {{viewModel.branchProgress.completed}} 项，共 {{viewModel.branchProgress.total}} 项
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:155](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L155)
217. 留下了哪些记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:157](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L157)
218. 已查记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:160](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L160)
219. 先看哪项都行，查过的会记在这里
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
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:213](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L213)
228. 把记录对一对
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:214](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L214)
229. 四处来源
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:214](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L214)
230. 离湖
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:216](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L216)
231. 同一移动过程，方向连续。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:216](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L216)
232. CC98 × 照片
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:216](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L216)
233. 录音 × 网络
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:217](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L217)
234. 末段
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:217](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L217)
235. 室内广播、三秒陌生设备与候选地点需要同时成立。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:217](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L217)
236. 候选
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)
237. 尚未保存
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)
238. 已保存接入记录
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:218](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L218)
239. 选择最终地点
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:225](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L225)
240. 哪个地方能对上时间、沿途声音、入口变化和网络记录？
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:226](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L226)
241. 路径记录已恢复
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:238](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L238)
242. 回放会从启真湖最后一帧开始，并在已确认地点结束。
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:239](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L239)
243. 播放恢复回放
   来源：[src/scenes/phone/P20_TimelineRecovery/index.tsx:240](../src/scenes/phone/P20_TimelineRecovery/index.tsx#L240)
244. 近
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:108](../src/scenes/phone/P21_VoiceMemos/index.tsx#L108)
245. 中
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:109](../src/scenes/phone/P21_VoiceMemos/index.tsx#L109)
246. 远
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:110](../src/scenes/phone/P21_VoiceMemos/index.tsx#L110)
247. 先试听这段录音，再决定是否保留。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:375](../src/scenes/phone/P21_VoiceMemos/index.tsx#L375)
248. 已经选满四段。先移出一段，再加入新的录音。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:384](../src/scenes/phone/P21_VoiceMemos/index.tsx#L384)
249. 需要先选满四段录音。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:393](../src/scenes/phone/P21_VoiceMemos/index.tsx#L393)
250. 用上下按钮调整四段录音的发生顺序。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:399](../src/scenes/phone/P21_VoiceMemos/index.tsx#L399)
251. 录音已接成连续路线，末段在 22:45:00 结束。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:428](../src/scenes/phone/P21_VoiceMemos/index.tsx#L428)
252. locked
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:429](../src/scenes/phone/P21_VoiceMemos/index.tsx#L429)
253. 先完成 CC98 记录收尾。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:430](../src/scenes/phone/P21_VoiceMemos/index.tsx#L430)
254. 四段都来自这条路线，前后声场仍有一处接不上。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:432](../src/scenes/phone/P21_VoiceMemos/index.tsx#L432)
255. 其中至少一段属于别的夜间记录。重新比较背景声。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:433](../src/scenes/phone/P21_VoiceMemos/index.tsx#L433)
256. 语音备忘录
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:438](../src/scenes/phone/P21_VoiceMemos/index.tsx#L438)；[src/scenes/phone/P21_VoiceMemos/index.tsx:445](../src/scenes/phone/P21_VoiceMemos/index.tsx#L445)
257. 退出语音备忘录
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:442](../src/scenes/phone/P21_VoiceMemos/index.tsx#L442)
258. VOICE MEMOS
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:445](../src/scenes/phone/P21_VoiceMemos/index.tsx#L445)
259. 排序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:446](../src/scenes/phone/P21_VoiceMemos/index.tsx#L446)
260. 录音整理步骤
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:449](../src/scenes/phone/P21_VoiceMemos/index.tsx#L449)
261. 1 / 2 筛选录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:450](../src/scenes/phone/P21_VoiceMemos/index.tsx#L450)
262. 2 / 2 排列顺序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:450](../src/scenes/phone/P21_VoiceMemos/index.tsx#L450)
263. 逐段试听，从七段恢复文件中留下同一次移动过程的四段。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:452](../src/scenes/phone/P21_VoiceMemos/index.tsx#L452)
264. 根据环境声的连续变化，调整四段录音的先后位置。
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:453](../src/scenes/phone/P21_VoiceMemos/index.tsx#L453)
265. 七段恢复录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:457](../src/scenes/phone/P21_VoiceMemos/index.tsx#L457)
266. {{isPlaying ? "暂停" : isPaused ? "继续播放" : "播放"}} {{clip.code}}
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:471](../src/scenes/phone/P21_VoiceMemos/index.tsx#L471)；[src/scenes/phone/P21_VoiceMemos/index.tsx:516](../src/scenes/phone/P21_VoiceMemos/index.tsx#L516)
267. 未试听
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:477](../src/scenes/phone/P21_VoiceMemos/index.tsx#L477)
268. 保留这段
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:488](../src/scenes/phone/P21_VoiceMemos/index.tsx#L488)
269. 试听后可选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:488](../src/scenes/phone/P21_VoiceMemos/index.tsx#L488)
270. 移出候选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:488](../src/scenes/phone/P21_VoiceMemos/index.tsx#L488)
271. {{clip.code}} 可听事件
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:490](../src/scenes/phone/P21_VoiceMemos/index.tsx#L490)；[src/scenes/phone/P21_VoiceMemos/index.tsx:528](../src/scenes/phone/P21_VoiceMemos/index.tsx#L528)
272. {{soundEvent.category}} · {{soundEvent.startMs}}–{{soundEvent.endMs}}ms
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:495](../src/scenes/phone/P21_VoiceMemos/index.tsx#L495)；[src/scenes/phone/P21_VoiceMemos/index.tsx:533](../src/scenes/phone/P21_VoiceMemos/index.tsx#L533)
273. 距
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:497](../src/scenes/phone/P21_VoiceMemos/index.tsx#L497)；[src/scenes/phone/P21_VoiceMemos/index.tsx:535](../src/scenes/phone/P21_VoiceMemos/index.tsx#L535)
274. 当前录音顺序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:506](../src/scenes/phone/P21_VoiceMemos/index.tsx#L506)
275. {{clip.code}} 上移
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:524](../src/scenes/phone/P21_VoiceMemos/index.tsx#L524)
276. {{clip.code}} 下移
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:525](../src/scenes/phone/P21_VoiceMemos/index.tsx#L525)
277. 清空选择
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:548](../src/scenes/phone/P21_VoiceMemos/index.tsx#L548)
278. 进入排序
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:549](../src/scenes/phone/P21_VoiceMemos/index.tsx#L549)
279. 返回重选
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:553](../src/scenes/phone/P21_VoiceMemos/index.tsx#L553)
280. 核对录音
   来源：[src/scenes/phone/P21_VoiceMemos/index.tsx:554](../src/scenes/phone/P21_VoiceMemos/index.tsx#L554)
281. P07 天气
   来源：[src/scenes/phone/registry.tsx:58](../src/scenes/phone/registry.tsx#L58)
282. 第二章天气页：收集水滴并用于松开导师头像上的竖线。
   来源：[src/scenes/phone/registry.tsx:59](../src/scenes/phone/registry.tsx#L59)
283. P18 照片
   来源：[src/scenes/phone/registry.tsx:62](../src/scenes/phone/registry.tsx#L62)
284. IMG\_0755.JPG 亮度识别；亮度不高于 20% 时生成物品识别报告。
   来源：[src/scenes/phone/registry.tsx:63](../src/scenes/phone/registry.tsx#L63)
285. P20 记录恢复
   来源：[src/scenes/phone/registry.tsx:66](../src/scenes/phone/registry.tsx#L66)
286. 第三章半：汇总 CC98、照片、微信、网络和录音证据，恢复 22:37:05—22:45:00 路径。
   来源：[src/scenes/phone/registry.tsx:67](../src/scenes/phone/registry.tsx#L67)
287. P21 语音备忘录
   来源：[src/scenes/phone/registry.tsx:70](../src/scenes/phone/registry.tsx#L70)
288. 第三章半：从七段恢复录音中筛选四段，再按声场变化排列。
   来源：[src/scenes/phone/registry.tsx:71](../src/scenes/phone/registry.tsx#L71)
289. P04 校园卡余额
   来源：[src/scenes/phone/registry.tsx:74](../src/scenes/phone/registry.tsx#L74)
290. 第二章取得校园卡后显示余额，并接受右移箭头。
   来源：[src/scenes/phone/registry.tsx:75](../src/scenes/phone/registry.tsx#L75)
291. P11 校务签到
   来源：[src/scenes/phone/registry.tsx:78](../src/scenes/phone/registry.tsx#L78)
292. 校园网输入 0798 → 短暂成功 → 经度与纬度错误 → 红闪和七秒黑屏。
   来源：[src/scenes/phone/registry.tsx:79](../src/scenes/phone/registry.tsx#L79)
293. P10 盆栽
   来源：[src/scenes/phone/registry.tsx:82](../src/scenes/phone/registry.tsx#L82)
294. 浇水/照光/施肥三步平行 → 开花 → 点花得 d4=8。
   来源：[src/scenes/phone/registry.tsx:83](../src/scenes/phone/registry.tsx#L83)
295. P12 序章结算
   来源：[src/scenes/phone/registry.tsx:86](../src/scenes/phone/registry.tsx#L86)
296. 移动错误框拦截三次旁白路径，完成长按锁定和系统对话后返回手机主页。
   来源：[src/scenes/phone/registry.tsx:87](../src/scenes/phone/registry.tsx#L87)
297. P19 时钟
   来源：[src/scenes/phone/registry.tsx:90](../src/scenes/phone/registry.tsx#L90)
298. 第四章校时：拖动环形刻度/表冠/数字或滚轮、Q/E 键，把被篡改冻结的 07:55:23 校准对齐。
   来源：[src/scenes/phone/registry.tsx:91](../src/scenes/phone/registry.tsx#L91)

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
19. 第 1 章
   来源：[src/components/QuestClueStrip.tsx:21](../src/components/QuestClueStrip.tsx#L21)
20. 第 2 章
   来源：[src/components/QuestClueStrip.tsx:22](../src/components/QuestClueStrip.tsx#L22)
21. 第 3 章
   来源：[src/components/QuestClueStrip.tsx:23](../src/components/QuestClueStrip.tsx#L23)
22. 第 4 章
   来源：[src/components/QuestClueStrip.tsx:24](../src/components/QuestClueStrip.tsx#L24)
23. 第四章当前阶段概览
   来源：[src/components/QuestClueStrip.tsx:246](../src/components/QuestClueStrip.tsx#L246)
24. 当前阶段
   来源：[src/components/QuestClueStrip.tsx:248](../src/components/QuestClueStrip.tsx#L248)；[src/data/chapter4-temporal-maze.content.json:107](../src/data/chapter4-temporal-maze.content.json#L107)
25. 时间状态
   来源：[src/components/QuestClueStrip.tsx:252](../src/components/QuestClueStrip.tsx#L252)；[src/data/chapter4-temporal-maze.content.json:108](../src/data/chapter4-temporal-maze.content.json#L108)
26. 所在楼层
   来源：[src/components/QuestClueStrip.tsx:256](../src/components/QuestClueStrip.tsx#L256)；[src/data/chapter4-temporal-maze.content.json:109](../src/data/chapter4-temporal-maze.content.json#L109)
27. 当前进度
   来源：[src/components/QuestClueStrip.tsx:260](../src/components/QuestClueStrip.tsx#L260)；[src/data/chapter4-temporal-maze.content.json:110](../src/data/chapter4-temporal-maze.content.json#L110)
28. 第四章阶段差分
   来源：[src/components/QuestClueStrip.tsx:265](../src/components/QuestClueStrip.tsx#L265)
29. 当前差分
   来源：[src/components/QuestClueStrip.tsx:267](../src/components/QuestClueStrip.tsx#L267)；[src/data/chapter4-temporal-maze.content.json:111](../src/data/chapter4-temporal-maze.content.json#L111)
30. 时间来源
   来源：[src/components/QuestClueStrip.tsx:272](../src/components/QuestClueStrip.tsx#L272)；[src/data/chapter4-temporal-maze.content.json:112](../src/data/chapter4-temporal-maze.content.json#L112)
31. 手机状态
   来源：[src/components/QuestClueStrip.tsx:276](../src/components/QuestClueStrip.tsx#L276)；[src/data/chapter4-temporal-maze.content.json:113](../src/data/chapter4-temporal-maze.content.json#L113)
32. 已确认事实
   来源：[src/components/QuestClueStrip.tsx:281](../src/components/QuestClueStrip.tsx#L281)；[src/data/chapter4-temporal-maze.content.json:114](../src/data/chapter4-temporal-maze.content.json#L114)
33. 当前阶段尚无已确认事实。
   来源：[src/components/QuestClueStrip.tsx:286](../src/components/QuestClueStrip.tsx#L286)；[src/data/chapter4-temporal-maze.content.json:116](../src/data/chapter4-temporal-maze.content.json#L116)
34. 签到数字
   来源：[src/components/QuestClueStrip.tsx:295](../src/components/QuestClueStrip.tsx#L295)
35. 打开控制中心，当前电量 {{batteryPercent}}%{{state.phoneBattery.lowPowerMode ? "，低电量模式已开启" : ""}}
   来源：[src/components/StatusBar.tsx:47](../src/components/StatusBar.tsx#L47)
36. 第二问 · 02 / 02
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:72](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L72)
37. 第一问 · 01 / 02
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:72](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L72)
38. 回答已保存
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:110](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L110)；[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:150](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L150)；[src/data/chapter4-755.content.json:1134](../src/data/chapter4-755.content.json#L1134)；[src/scenes/rpg/RpgGameHost.tsx:858](../src/scenes/rpg/RpgGameHost.tsx#L858)
39. 未点亮的灿若星辰灯
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:139](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L139)
40. 正在保存两项回答
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:155](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L155)
41. 正在确认回答
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:155](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L155)
42. 07:55 · 校史墙留下的两项问题
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:161](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L161)
43. 灯仍未点亮
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:162](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L162)
44. 问题正在浮现
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:198](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L198)
45. 星光粒子消散中
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:198](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L198)
46. 选择你的回答
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:198](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L198)
47. {{question.prompt}}回答完成
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:204](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L204)
48. {{question.prompt}}正在显示
   来源：[src/components/temporal-maze/ChapterFourExteriorQuestions.tsx:204](../src/components/temporal-maze/ChapterFourExteriorQuestions.tsx#L204)
49. 104 教室
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:16](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L16)
50. 105 教室
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:17](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L17)
51. 主电梯
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:18](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L18)；[src/data/chapter4-clock.content.json:50](../src/data/chapter4-clock.content.json#L50)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1077](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1077)
52. 202 教室门口
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:22](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L22)；[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:270](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L270)
53. 东侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:23](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L23)
54. 交通核心
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:24](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L24)
55. 主楼梯下行口
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:25](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L25)；[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:272](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L272)
56. 大厅 — 西侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:29](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L29)
57. 大厅 — 东侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:30](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L30)
58. 西侧走廊 — 后区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:31](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L31)
59. 东侧走廊 — 教室区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:32](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L32)
60. 后区 — 教室区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:33](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L33)
61. 西侧走廊 — 东侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:34](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L34)
62. 大厅 — 教室区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:35](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L35)
63. 浅色操作
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:121](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L121)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:98](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L98)；[src/data/chapter4-temporal-maze.content.json:94](../src/data/chapter4-temporal-maze.content.json#L94)
64. 深色观察
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:121](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L121)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:98](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L98)；[src/data/chapter4-temporal-maze.content.json:95](../src/data/chapter4-temporal-maze.content.json#L95)；[src/scenes/rpg/RpgInteractionContract.ts:43](../src/scenes/rpg/RpgInteractionContract.ts#L43)
65. 返回现场
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:124](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L124)；[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:180](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L180)；[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:69](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L69)
66. {{definition.locationLabel}}的{{definition.title}}装置
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:129](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L129)
67. 调整当前装置
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:130](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L130)
68. 观察残留痕迹
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:130](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L130)
69. 记录完成
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:140](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L140)
70. 缺少可校准底片
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:145](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L145)
71. 扫描台里还没放底片。301 的索引抽屉存着旧导视胶片。
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:146](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L146)
72. 痕迹已记下，可以关掉再动手试。
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:178](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L178)
73. 可以反复调整，核对失败会保留当前摆放。
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:178](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L178)
74. 提交结果
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:183](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L183)
75. 正在核对…
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:183](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L183)；[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:71](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L71)
76. 104：旧夹痕
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:194](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L194)
77. 105：中段夹痕
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:194](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L194)
78. 主电梯：最新夹痕
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:194](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L194)
79. 楼层：A3
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:195](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L195)
80. 年代：九十年代末
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:195](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L195)
81. 用途：入口导视
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:195](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L195)
82. 方向：顺时针 90°
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:196](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L196)
83. 横向：右移 2 格
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:196](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L196)
84. 纵向：上移 1 格
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:196](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L196)
85. 横向：−2
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:197](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L197)
86. 压力：3 档
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:197](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L197)
87. 纵向：+1
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:197](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L197)
88. 大厅分别连接两侧走廊
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:198](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L198)
89. 两侧走廊分别连向两个末端区
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:198](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L198)
90. 两个末端区互相连接
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:198](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L198)
91. 202 门外：完整鞋印的脚尖朝向门外
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:200](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L200)
92. 东侧走廊墙边：同一种鞋底纹连续出现
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:201](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L201)
93. 交通核心转角：右脚外缘磨损加深，脚尖偏向楼梯
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:202](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L202)
94. 主楼梯黄线内：只留下半枚向下的鞋印
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:203](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L203)
95. 年代
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:241](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L241)
96. 1977–1984
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:242](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L242)
97. 1985–1990
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:242](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L242)
98. 1991–1998
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:242](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L242)
99. 选择范围
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:242](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L242)
100. 楼层
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:244](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L244)
101. 选择楼层
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:245](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L245)
102. 用途
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:247](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L247)；[src/data/itemCatalog.ts:213](../src/data/itemCatalog.ts#L213)
103. 考勤
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
104. 入口导视
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
105. 维修
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
106. 选择用途
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:248](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L248)
107. 垂直
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:253](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L253)
108. 水平
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:253](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L253)
109. 旋转
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:253](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L253)
110. 横向
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:255](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L255)
111. 压力
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:255](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L255)
112. 纵向
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:255](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L255)
113. 五区连线选择
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:258](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L258)
114. / 5 条
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:263](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L263)
115. 已保留
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:263](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L263)
116. 路线起点为 202 教室门口，终点为主楼梯下行口
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:269](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L269)
117. 固定起点
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:270](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L270)
118. 固定终点
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:272](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L272)
119. {{labels\[id\]}}上移
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:298](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L298)
120. 上移
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:298](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L298)
121. {{labels\[id\]}}下移
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:299](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L299)
122. 下移
   来源：[src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx:299](../src/components/temporal-maze/ChapterFourInsertedPuzzleGame.tsx#L299)
123. 车轮声音
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:9](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L9)
124. 推车起步时轮罩先响，车轮随后才停。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:9](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L9)
125. 旧钟卡滞
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:10](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L10)
126. 秒轮到同一齿位会回弹，拨动后仍重复。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:10](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L10)
127. 轮轴边只有干涸油圈，地面没有新鲜滴落。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:11](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L11)
128. 油迹
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:11](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L11)
129. 卡扣
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:15](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L15)
130. 缺油
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:16](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L16)
131. 齿轮偏位
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:17](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L17)
132. 供电中断
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:18](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L18)
133. 异物堵塞
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:19](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L19)
134. 22:45 · 维修记录
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:43](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L43)
135. 先查故障，再填报修单
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:44](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L44)
136. 每种现象选一个原因。写错还能改，总比再报一次强。
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:45](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L45)
137. 选择原因
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:61](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L61)
138. 提交诊断
   来源：[src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx:71](../src/components/temporal-maze/ChapterFourMaintenanceDiagnosisGame.tsx#L71)
139. 实体配电箱，五个开关状态与右侧区域同步
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:146](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L146)
140. 五区配电箱
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:168](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L168)
141. 让必要路线亮起
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:169](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L169)
142. 五区配电线路拓扑
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:172](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L172)
143. {{zone.label}}当前{{on ? "亮" : "暗"}}，连接{{adjacentLabels}}
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:211](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L211)
144. 暗
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:232](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L232)
145. 亮
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:232](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L232)
146. 总负载过高。核对已记录的必要路线，关闭旁路回路。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:240](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L240)
147. 正在同步配电状态……
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:242](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L242)
148. 配电结果已锁定。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:244](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L244)；[src/scenes/rpg/RpgGameHost.tsx:1370](../src/scenes/rpg/RpgGameHost.tsx#L1370)
149. 按下一区，会切换它自身和连线直接相接的区域。
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:245](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L245)
150. 方向键移动焦点 · Enter / Space 切换 · Esc 关闭
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:248](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L248)
151. 重试锁定配电结果
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:254](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L254)
152. 重试锁定
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:257](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L257)
153. 关闭箱门
   来源：[src/components/temporal-maze/ChapterFourPowerPanelGame.tsx:267](../src/components/temporal-maze/ChapterFourPowerPanelGame.tsx#L267)
154. 错位楼梯空间校准
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:54](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L54)
155. 正在载入楼梯空间…
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:56](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L56)
156. 楼梯空间启动失败
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:59](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L59)
157. 返回三楼后可以重新进入。
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:60](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L60)
158. 返回三楼
   来源：[src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx:64](../src/components/temporal-maze/ChapterFourStairPuzzleOverlay.tsx#L64)
159. 灿若星辰灯由底部向上观察与点亮演出
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:194](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L194)
160. 原版灿若星辰灯依次点亮灯珠与中央灯芯
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:210](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L210)
161. 相机从固定的原版灿若星辰灯底部向上移动，随后灯珠与中央灯芯依次点亮
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:211](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L211)
162. 灿若星辰
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:225](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L225)
163. 正在以兼容模式完整播放灯光演出
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:230](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L230)
164. 正在按减弱动态模式播放完整点灯演出
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:232](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L232)
165. 摄像机正在从固定灯体底部向上移动，到达正面机位后点亮
   来源：[src/components/temporal-maze/ChapterFourStarLampClosure.tsx:233](../src/components/temporal-maze/ChapterFourStarLampClosure.tsx#L233)
166. 时间切换操作
   来源：[src/components/temporal-maze/ChapterFourTransitionOverlay.tsx:56](../src/components/temporal-maze/ChapterFourTransitionOverlay.tsx#L56)
167. 继续行动
   来源：[src/components/temporal-maze/ChapterFourTransitionOverlay.tsx:58](../src/components/temporal-maze/ChapterFourTransitionOverlay.tsx#L58)
168. 三条轨道已经对齐，主电梯开始重放这一段历史。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:65](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L65)
169. 这一段历史已经对齐，可以返回主电梯厅。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:67](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L67)
170. 开门区间没有完整覆盖黄色进入窗口。继续移动整段轿厢历史。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:69](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L69)
171. 当前仍在深色观察。切回浅色操作后才能启动历史重放。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:71](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L71)
172. 当前剧情阶段尚未开放轿厢重放。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:73](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L73)
173. 拖动下方时间游标，三条轨道会保持同一历史偏移。
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:74](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L74)
174. HISTORY REPLAY / A-LIFT
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:90](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L90)
175. 主电梯三轨同步
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:91](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L91)
176. 关闭三轨同步面板
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:93](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L93)
177. 当前模式
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:97](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L97)
178. 重放起点
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:99](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L99)
179. 尝试
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:101](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L101)
180. 电梯历史三轨
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:105](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L105)
181. 轿厢
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:113](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L113)
182. 门体
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:122](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L122)
183. 开门
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:124](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L124)；[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:126](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L126)
184. 关闭
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:125](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L125)；[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
185. 进入
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:131](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L131)
186. 6 秒窗口
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:133](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L133)
187. 拖动轿厢历史
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:143](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L143)
188. 调整电梯历史重放起点
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:155](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L155)
189. 切到浅色操作
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:163](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L163)
190. 启动历史重放
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:170](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L170)
191. 目标：让一楼开门区间完整覆盖进入窗口
   来源：[src/components/temporal-maze/ElevatorTrackSyncGame.tsx:173](../src/components/temporal-maze/ElevatorTrackSyncGame.tsx#L173)
192. 碎片 A · 箭头端
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:18](../src/components/temporal-maze/WayfindingBoardGame.tsx#L18)
193. 碎片 B · 2F 字样端
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:19](../src/components/temporal-maze/WayfindingBoardGame.tsx#L19)
194. 当前历史片段已经恢复。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:29](../src/components/temporal-maze/WayfindingBoardGame.tsx#L29)
195. 这一段导视记录已经恢复。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:30](../src/components/temporal-maze/WayfindingBoardGame.tsx#L30)
196. 碎片顺序与已记录的历史痕迹不一致。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:31](../src/components/temporal-maze/WayfindingBoardGame.tsx#L31)
197. 切回浅色操作后再调整导视板。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:32](../src/components/temporal-maze/WayfindingBoardGame.tsx#L32)
198. 第四章教学楼流程尚未开始。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:33](../src/components/temporal-maze/WayfindingBoardGame.tsx#L33)；[src/scenes/rpg/RpgGameHost.tsx:391](../src/scenes/rpg/RpgGameHost.tsx#L391)
199. 仍缺当前排列所需的历史证据。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:34](../src/components/temporal-maze/WayfindingBoardGame.tsx#L34)
200. 比较三份现场材料后，选择一块碎片，再选择目标槽位。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:42](../src/components/temporal-maze/WayfindingBoardGame.tsx#L42)
201. 该槽位为空。先选择一块导视碎片。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:71](../src/components/temporal-maze/WayfindingBoardGame.tsx#L71)
202. 已选择{{FRAGMENT\_LABELS\[fragment\]}}，请选择目标槽位。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:75](../src/components/temporal-maze/WayfindingBoardGame.tsx#L75)
203. 已取消当前选择。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:80](../src/components/temporal-maze/WayfindingBoardGame.tsx#L80)
204. 槽位已交换。确认前可以继续调整。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:87](../src/components/temporal-maze/WayfindingBoardGame.tsx#L87)
205. ARCHIVED SIGNAGE / A3
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:124](../src/components/temporal-maze/WayfindingBoardGame.tsx#L124)
206. 残缺导视板
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:125](../src/components/temporal-maze/WayfindingBoardGame.tsx#L125)
207. 取消并关闭导视板
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:127](../src/components/temporal-maze/WayfindingBoardGame.tsx#L127)
208. 当前目标
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:131](../src/components/temporal-maze/WayfindingBoardGame.tsx#L131)；[src/scenes/rpg/Chapter4PrologueOverlay.tsx:709](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L709)
209. 比较当前导视照片、旧残影和二楼入口方向，判断两块碎片及缺失槽位的位置。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:132](../src/components/temporal-maze/WayfindingBoardGame.tsx#L132)
210. 导视板比对材料
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:135](../src/components/temporal-maze/WayfindingBoardGame.tsx#L135)
211. 当前导视照片
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:137](../src/components/temporal-maze/WayfindingBoardGame.tsx#L137)
212. 完整板面由三段等宽槽位组成；两块残片并拢后宽度仍不足。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:138](../src/components/temporal-maze/WayfindingBoardGame.tsx#L138)
213. 旧导视残影
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:141](../src/components/temporal-maze/WayfindingBoardGame.tsx#L141)
214. 箭头端贴近左侧磨损边；“2F”字样端与箭头之间留有断续胶痕。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:142](../src/components/temporal-maze/WayfindingBoardGame.tsx#L142)
215. 二楼入口方向
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:145](../src/components/temporal-maze/WayfindingBoardGame.tsx#L145)
216. 从交通核心进入二楼时，入口位于左侧导向一边。
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:146](../src/components/temporal-maze/WayfindingBoardGame.tsx#L146)
217. 三个导视板槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:150](../src/components/temporal-maze/WayfindingBoardGame.tsx#L150)
218. 当前空槽
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:152](../src/components/temporal-maze/WayfindingBoardGame.tsx#L152)
219. 槽位 {{index + 1}}：{{label}}{{picked ? "，已选择" : ""}}
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:161](../src/components/temporal-maze/WayfindingBoardGame.tsx#L161)
220. 槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:184](../src/components/temporal-maze/WayfindingBoardGame.tsx#L184)
221. 当前没有装入碎片
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:186](../src/components/temporal-maze/WayfindingBoardGame.tsx#L186)
222. 选择后放入另一槽位
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:186](../src/components/temporal-maze/WayfindingBoardGame.tsx#L186)
223. 取消
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:197](../src/components/temporal-maze/WayfindingBoardGame.tsx#L197)
224. 方向键切换槽位，Enter 或空格选择
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:198](../src/components/temporal-maze/WayfindingBoardGame.tsx#L198)
225. 确认当前排列
   来源：[src/components/temporal-maze/WayfindingBoardGame.tsx:199](../src/components/temporal-maze/WayfindingBoardGame.tsx#L199)
226. active
   来源：[src/core/QuestModel.ts:923](../src/core/QuestModel.ts#L923)；[src/core/QuestModel.ts:1125](../src/core/QuestModel.ts#L1125)
227. completed
   来源：[src/core/QuestModel.ts:923](../src/core/QuestModel.ts#L923)；[src/core/QuestModel.ts:1028](../src/core/QuestModel.ts#L1028)；[src/core/QuestModel.ts:1097](../src/core/QuestModel.ts#L1097)；[src/core/QuestModel.ts:1125](../src/core/QuestModel.ts#L1125)
228. 104 黑板
   来源：[src/core/QuestModel.ts:935](../src/core/QuestModel.ts#L935)
229. 擦痕残留
   来源：[src/core/QuestModel.ts:936](../src/core/QuestModel.ts#L936)
230. 105 讲台
   来源：[src/core/QuestModel.ts:941](../src/core/QuestModel.ts#L941)
231. 本地回放
   来源：[src/core/QuestModel.ts:942](../src/core/QuestModel.ts#L942)
232. pending
   来源：[src/core/QuestModel.ts:1028](../src/core/QuestModel.ts#L1028)；[src/core/QuestModel.ts:1097](../src/core/QuestModel.ts#L1097)
233. 303 晨间参照
   来源：[src/core/QuestModel.ts:1038](../src/core/QuestModel.ts#L1038)
234. 浅色现场记录
   来源：[src/core/QuestModel.ts:1039](../src/core/QuestModel.ts#L1039)
235. 204 夜间残影
   来源：[src/core/QuestModel.ts:1044](../src/core/QuestModel.ts#L1044)
236. 深色轮廓记录
   来源：[src/core/QuestModel.ts:1045](../src/core/QuestModel.ts#L1045)
237. 204 家具复原
   来源：[src/core/QuestModel.ts:1050](../src/core/QuestModel.ts#L1050)
238. {{completedGroupCount}}/{{ROOM204\_GROUP\_ORDER.length}} 组就位
   来源：[src/core/QuestModel.ts:1051](../src/core/QuestModel.ts#L1051)
239. 校园卡读卡器
   来源：[src/core/QuestModel.ts:1074](../src/core/QuestModel.ts#L1074)
240. 刷卡确认
   来源：[src/core/QuestModel.ts:1075](../src/core/QuestModel.ts#L1075)
241. 签到纸插槽
   来源：[src/core/QuestModel.ts:1081](../src/core/QuestModel.ts#L1081)
242. 纸条确认
   来源：[src/core/QuestModel.ts:1082](../src/core/QuestModel.ts#L1082)
243. 把时间拨回 7:55
   来源：[src/data/chapter4-755.content.json:5](../src/data/chapter4-755.content.json#L5)
244. 阶段 1 · 接住签到纸
   来源：[src/data/chapter4-755.content.json:130](../src/data/chapter4-755.content.json#L130)
245. 外部记录指向现场 22:45，手机仍停在 07:55:23，当前读数尚未同步。
   来源：[src/data/chapter4-755.content.json:131](../src/data/chapter4-755.content.json#L131)
246. 阶段 2 · 核对异常时间
   来源：[src/data/chapter4-755.content.json:134](../src/data/chapter4-755.content.json#L134)
247. 现场 22:45 与手机 07:55:23 冲突，需要确认手机时间不可作为当前依据。
   来源：[src/data/chapter4-755.content.json:135](../src/data/chapter4-755.content.json#L135)
248. 阶段 3 · 接管大厅旧钟
   来源：[src/data/chapter4-755.content.json:138](../src/data/chapter4-755.content.json#L138)
249. 缺失时针的轴孔旁留着一圈新磨痕，外圈只有一处额外刻度能够停住。
   来源：[src/data/chapter4-755.content.json:139](../src/data/chapter4-755.content.json#L139)
250. 阶段 4 · 找回旧时针
   来源：[src/data/chapter4-755.content.json:142](../src/data/chapter4-755.content.json#L142)
251. 旧钟停在 12:25；楼内西侧传来周期性的机械声，检修灯仍亮着。
   来源：[src/data/chapter4-755.content.json:143](../src/data/chapter4-755.content.json#L143)
252. 阶段 5 · 恢复 204
   来源：[src/data/chapter4-755.content.json:146](../src/data/chapter4-755.content.json#L146)
253. 旧钟停在 18:50；走廊照明已亮，电梯门机留下了几段彼此错开的时间痕迹。
   来源：[src/data/chapter4-755.content.json:147](../src/data/chapter4-755.content.json#L147)
254. 阶段 6 · 完成维修
   来源：[src/data/chapter4-755.content.json:150](../src/data/chapter4-755.content.json#L150)
255. 旧钟停在 22:45；地面留有尚未干透的轮印，钟壳内传出断续摩擦声。
   来源：[src/data/chapter4-755.content.json:151](../src/data/chapter4-755.content.json#L151)
256. 阶段 7 · 接通必要照明
   来源：[src/data/chapter4-755.content.json:154](../src/data/chapter4-755.content.json#L154)
257. 旧钟已到 07:54，最后一分钟被纸条带走，只需恢复通往目标区域的必要灯区。
   来源：[src/data/chapter4-755.content.json:155](../src/data/chapter4-755.content.json#L155)
258. 阶段 8 · 追向 202
   来源：[src/data/chapter4-755.content.json:158](../src/data/chapter4-755.content.json#L158)
259. 旧钟仍停在 07:54，最后一分钟正在向二楼 202 移动。
   来源：[src/data/chapter4-755.content.json:159](../src/data/chapter4-755.content.json#L159)
260. 阶段 9 · 取回黄铜分针组件
   来源：[src/data/chapter4-755.content.json:162](../src/data/chapter4-755.content.json#L162)
261. 202 投影留下大厅旧钟的黄铜分针组件，取回后需要送回旧钟。
   来源：[src/data/chapter4-755.content.json:163](../src/data/chapter4-755.content.json#L163)
262. 阶段 10 · 把分针组件带回大厅
   来源：[src/data/chapter4-755.content.json:166](../src/data/chapter4-755.content.json#L166)
263. 黄铜分针组件已经取回；电梯仍锁定，从二楼主楼梯下到一楼大厅。
   来源：[src/data/chapter4-755.content.json:167](../src/data/chapter4-755.content.json#L167)
264. 阶段 11 · 完成双重签到
   来源：[src/data/chapter4-755.content.json:170](../src/data/chapter4-755.content.json#L170)
265. 旧钟与手机均为 07:55，校园卡与签到记录纸仍需分别通过验证。
   来源：[src/data/chapter4-755.content.json:171](../src/data/chapter4-755.content.json#L171)
266. 阶段 12 · 楼外两问
   来源：[src/data/chapter4-755.content.json:174](../src/data/chapter4-755.content.json#L174)
267. 签到办完了。楼外的灯还没亮，校史墙上留着两问。
   来源：[src/data/chapter4-755.content.json:175](../src/data/chapter4-755.content.json#L175)
268. 阶段 13 · 本人来过
   来源：[src/data/chapter4-755.content.json:178](../src/data/chapter4-755.content.json#L178)
269. 旧钟、手机与签到记录均已对齐到 07:55。
   来源：[src/data/chapter4-755.content.json:179](../src/data/chapter4-755.content.json#L179)
270. 现场 22:45 · 手机 07:55:23 未同步
   来源：[src/data/chapter4-755.content.json:184](../src/data/chapter4-755.content.json#L184)；[src/modules/ChapterFourStagePresentation.ts:87](../src/modules/ChapterFourStagePresentation.ts#L87)
271. 旧钟 12:25 · 面包坊时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:187](../src/data/chapter4-755.content.json#L187)
272. 旧钟 18:50 · 晚间教室 · 手机已同步
   来源：[src/data/chapter4-755.content.json:190](../src/data/chapter4-755.content.json#L190)
273. 旧钟 22:45 · 维修时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:193](../src/data/chapter4-755.content.json#L193)；[src/modules/ChapterFourStagePresentation.ts:88](../src/modules/ChapterFourStagePresentation.ts#L88)
274. 旧钟 07:54 · 停电时段 · 手机已同步
   来源：[src/data/chapter4-755.content.json:196](../src/data/chapter4-755.content.json#L196)
275. 旧钟 07:55 · 清晨签到 · 手机已同步
   来源：[src/data/chapter4-755.content.json:199](../src/data/chapter4-755.content.json#L199)
276. 签到纸已落到公告栏前
   来源：[src/data/chapter4-755.content.json:203](../src/data/chapter4-755.content.json#L203)
277. 签到记录纸已接住
   来源：[src/data/chapter4-755.content.json:204](../src/data/chapter4-755.content.json#L204)
278. 手机 07:55:23 已被外部记录否定
   来源：[src/data/chapter4-755.content.json:205](../src/data/chapter4-755.content.json#L205)
279. 大厅旧钟缺件状态已确认
   来源：[src/data/chapter4-755.content.json:206](../src/data/chapter4-755.content.json#L206)
280. 面包坊检修灯已确认
   来源：[src/data/chapter4-755.content.json:207](../src/data/chapter4-755.content.json#L207)
281. 旧时针已从传送带露出
   来源：[src/data/chapter4-755.content.json:208](../src/data/chapter4-755.content.json#L208)
282. 旧时针已取得
   来源：[src/data/chapter4-755.content.json:209](../src/data/chapter4-755.content.json#L209)
283. 旧时针已装回
   来源：[src/data/chapter4-755.content.json:210](../src/data/chapter4-755.content.json#L210)
284. 104 黑板的延迟擦痕已记录
   来源：[src/data/chapter4-755.content.json:211](../src/data/chapter4-755.content.json#L211)
285. 105 讲台的本地回放延迟已确认
   来源：[src/data/chapter4-755.content.json:212](../src/data/chapter4-755.content.json#L212)
286. 主电梯三条历史轨道已读取
   来源：[src/data/chapter4-755.content.json:213](../src/data/chapter4-755.content.json#L213)
287. 主电梯 18:50 重放窗口已校准
   来源：[src/data/chapter4-755.content.json:214](../src/data/chapter4-755.content.json#L214)
288. A1 值班签到板已重建
   来源：[src/data/chapter4-755.content.json:215](../src/data/chapter4-755.content.json#L215)
289. 301 旧导视胶片已取出
   来源：[src/data/chapter4-755.content.json:216](../src/data/chapter4-755.content.json#L216)
290. 302 新旧影像已对齐
   来源：[src/data/chapter4-755.content.json:217](../src/data/chapter4-755.content.json#L217)
291. 三楼 303 晨间参照已记录
   来源：[src/data/chapter4-755.content.json:218](../src/data/chapter4-755.content.json#L218)
292. 竺老两问已回答
   来源：[src/data/chapter4-755.content.json:219](../src/data/chapter4-755.content.json#L219)
293. 三楼至二楼的错位楼梯已接通
   来源：[src/data/chapter4-755.content.json:220](../src/data/chapter4-755.content.json#L220)
294. 二楼 204 残影已记录
   来源：[src/data/chapter4-755.content.json:221](../src/data/chapter4-755.content.json#L221)
295. 二楼 204 已恢复
   来源：[src/data/chapter4-755.content.json:222](../src/data/chapter4-755.content.json#L222)
296. 204 投影记录已完成
   来源：[src/data/chapter4-755.content.json:223](../src/data/chapter4-755.content.json#L223)
297. 钟面定位片已取得
   来源：[src/data/chapter4-755.content.json:224](../src/data/chapter4-755.content.json#L224)
298. 201 定位板已完成三轴校准
   来源：[src/data/chapter4-755.content.json:225](../src/data/chapter4-755.content.json#L225)
299. 203 五区供电拓扑已恢复
   来源：[src/data/chapter4-755.content.json:226](../src/data/chapter4-755.content.json#L226)
300. 202 至主楼梯的夜间疏散路线已确认
   来源：[src/data/chapter4-755.content.json:227](../src/data/chapter4-755.content.json#L227)
301. 钟面定位片已装回
   来源：[src/data/chapter4-755.content.json:228](../src/data/chapter4-755.content.json#L228)
302. 保洁车轮卡滞已确认
   来源：[src/data/chapter4-755.content.json:229](../src/data/chapter4-755.content.json#L229)
303. 保洁车轮罩已打开
   来源：[src/data/chapter4-755.content.json:230](../src/data/chapter4-755.content.json#L230)
304. 保洁车轮已修复
   来源：[src/data/chapter4-755.content.json:231](../src/data/chapter4-755.content.json#L231)
305. 旧钟齿轮已修复
   来源：[src/data/chapter4-755.content.json:232](../src/data/chapter4-755.content.json#L232)
306. 签到纸暂时带走最后一分钟
   来源：[src/data/chapter4-755.content.json:233](../src/data/chapter4-755.content.json#L233)
307. 必要照明路线已锁定
   来源：[src/data/chapter4-755.content.json:234](../src/data/chapter4-755.content.json#L234)
308. 楼外灯具已通电
   来源：[src/data/chapter4-755.content.json:235](../src/data/chapter4-755.content.json#L235)
309. 最后一分钟已取回
   来源：[src/data/chapter4-755.content.json:236](../src/data/chapter4-755.content.json#L236)
310. 最后一分钟已装回旧钟
   来源：[src/data/chapter4-755.content.json:237](../src/data/chapter4-755.content.json#L237)
311. 校园卡验证已通过
   来源：[src/data/chapter4-755.content.json:238](../src/data/chapter4-755.content.json#L238)
312. 签到记录纸验证已通过
   来源：[src/data/chapter4-755.content.json:239](../src/data/chapter4-755.content.json#L239)
313. 楼外灯已亮起
   来源：[src/data/chapter4-755.content.json:240](../src/data/chapter4-755.content.json#L240)
314. 第四章交接条件尚未齐全。
   来源：[src/data/chapter4-755.content.json:246](../src/data/chapter4-755.content.json#L246)
315. 先完成恢复回放并在任务卡确认进入。
   来源：[src/data/chapter4-755.content.json:247](../src/data/chapter4-755.content.json#L247)
316. 该操作不属于当前阶段。
   来源：[src/data/chapter4-755.content.json:250](../src/data/chapter4-755.content.json#L250)
317. 打开任务栏，按当前目标继续。
   来源：[src/data/chapter4-755.content.json:251](../src/data/chapter4-755.content.json#L251)
318. 当前楼层仍停留在上一段时间。
   来源：[src/data/chapter4-755.content.json:254](../src/data/chapter4-755.content.json#L254)
319. 回到一楼旧钟，在浅色操作中选择钟面上新出现的稳定刻度。
   来源：[src/data/chapter4-755.content.json:255](../src/data/chapter4-755.content.json#L255)
320. 当前目标尚未开放。
   来源：[src/data/chapter4-755.content.json:258](../src/data/chapter4-755.content.json#L258)
321. 先完成任务栏中显示的当前前置操作。
   来源：[src/data/chapter4-755.content.json:259](../src/data/chapter4-755.content.json#L259)
322. 当前阶段不能进入这一区域。
   来源：[src/data/chapter4-755.content.json:262](../src/data/chapter4-755.content.json#L262)
323. 返回当前楼层已开放的任务目标。
   来源：[src/data/chapter4-755.content.json:263](../src/data/chapter4-755.content.json#L263)
324. 这次楼梯通行条件不成立。
   来源：[src/data/chapter4-755.content.json:266](../src/data/chapter4-755.content.json#L266)
325. 按任务栏目标从当前楼层的主楼梯继续。
   来源：[src/data/chapter4-755.content.json:267](../src/data/chapter4-755.content.json#L267)
326. 传送带仍在运行。
   来源：[src/data/chapter4-755.content.json:270](../src/data/chapter4-755.content.json#L270)
327. 烤箱旁有检修开关，可以先检查。
   来源：[src/data/chapter4-755.content.json:271](../src/data/chapter4-755.content.json#L271)
328. 传送带正在执行停机过程。
   来源：[src/data/chapter4-755.content.json:274](../src/data/chapter4-755.content.json#L274)
329. 等待停稳后再取露出的旧时针。
   来源：[src/data/chapter4-755.content.json:275](../src/data/chapter4-755.content.json#L275)
330. 旧钟的时针还没装回。
   来源：[src/data/chapter4-755.content.json:278](../src/data/chapter4-755.content.json#L278)
331. 检查面包坊传送带露出的金属部件，和钟面缺口比一比。
   来源：[src/data/chapter4-755.content.json:279](../src/data/chapter4-755.content.json#L279)
332. A1 的时间差校验尚未完成。
   来源：[src/data/chapter4-755.content.json:282](../src/data/chapter4-755.content.json#L282)
333. 104 黑板擦痕与 105 讲台回放可按任意顺序确认。
   来源：[src/data/chapter4-755.content.json:283](../src/data/chapter4-755.content.json#L283)
334. 主电梯的历史轨道尚未记录。
   来源：[src/data/chapter4-755.content.json:286](../src/data/chapter4-755.content.json#L286)
335. 完成 104 与 105 校验后，可在一楼电梯门前用深色观察记录；这不限制浅色校准的先后。
   来源：[src/data/chapter4-755.content.json:287](../src/data/chapter4-755.content.json#L287)
336. 主电梯重放窗口尚未校准。
   来源：[src/data/chapter4-755.content.json:290](../src/data/chapter4-755.content.json#L290)
337. 使用浅色操作进入轿厢，让门体开放区间覆盖六秒进入窗口。
   来源：[src/data/chapter4-755.content.json:291](../src/data/chapter4-755.content.json#L291)
338. 三层电梯运行记录尚未齐全。
   来源：[src/data/chapter4-755.content.json:294](../src/data/chapter4-755.content.json#L294)
339. 分别在一楼、三楼和二楼查阅起行、到站与外呼记录；三段可按任意顺序归档。
   来源：[src/data/chapter4-755.content.json:295](../src/data/chapter4-755.content.json#L295)
340. 跨层停靠链尚未复核。
   来源：[src/data/chapter4-755.content.json:298](../src/data/chapter4-755.content.json#L298)
341. 三段记录齐全后，在浅色操作的电梯面板中确认实际到站层和未响应外呼层。
   来源：[src/data/chapter4-755.content.json:299](../src/data/chapter4-755.content.json#L299)
342. A1 的三段值班记录还没有汇合。
   来源：[src/data/chapter4-755.content.json:302](../src/data/chapter4-755.content.json#L302)
343. 到前台台面打开签到板；104、105 与电梯的调查顺序不受限制。
   来源：[src/data/chapter4-755.content.json:303](../src/data/chapter4-755.content.json#L303)
344. 302 扫描台缺少旧导视胶片。
   来源：[src/data/chapter4-755.content.json:306](../src/data/chapter4-755.content.json#L306)
345. 到三楼 301 的索引抽屉按年份、楼层与用途筛出胶片。
   来源：[src/data/chapter4-755.content.json:307](../src/data/chapter4-755.content.json#L307)
346. 三楼新旧导视影像尚未重合。
   来源：[src/data/chapter4-755.content.json:310](../src/data/chapter4-755.content.json#L310)
347. 带着 301 胶片到 302，校准平移和旋转后再进入错位楼梯。
   来源：[src/data/chapter4-755.content.json:311](../src/data/chapter4-755.content.json#L311)
348. 钟面定位片尚未完成三轴校准。
   来源：[src/data/chapter4-755.content.json:314](../src/data/chapter4-755.content.json#L314)
349. 到二楼 201 创客工坊调整横向、纵向和压力。
   来源：[src/data/chapter4-755.content.json:315](../src/data/chapter4-755.content.json#L315)
350. 五区供电关系仍不完整。
   来源：[src/data/chapter4-755.content.json:318](../src/data/chapter4-755.content.json#L318)
351. 到二楼 203 恢复停电前的五条相邻连线。
   来源：[src/data/chapter4-755.content.json:319](../src/data/chapter4-755.content.json#L319)
352. 202 到主楼梯的夜间疏散通路尚未确认。
   来源：[src/data/chapter4-755.content.json:322](../src/data/chapter4-755.content.json#L322)
353. 检查开放自习区路线板，比较四处鞋印的方向，再排列四块路线磁贴。
   来源：[src/data/chapter4-755.content.json:323](../src/data/chapter4-755.content.json#L323)
354. 竺老两问尚未完成。
   来源：[src/data/chapter4-755.content.json:326](../src/data/chapter4-755.content.json#L326)
355. 到楼外未点亮的灯前，依次回答两问。
   来源：[src/data/chapter4-755.content.json:327](../src/data/chapter4-755.content.json#L327)
356. 三楼与二楼之间的楼梯仍处于投影错位状态。
   来源：[src/data/chapter4-755.content.json:330](../src/data/chapter4-755.content.json#L330)
357. 在三楼晨间教室记录参照后，从主楼梯进入空间校准。
   来源：[src/data/chapter4-755.content.json:331](../src/data/chapter4-755.content.json#L331)
358. 204 复原缺少参照记录。
   来源：[src/data/chapter4-755.content.json:334](../src/data/chapter4-755.content.json#L334)
359. 补齐 303 参照与 204 深色残影；家具摆放可以在两项记录之前或之后完成。
   来源：[src/data/chapter4-755.content.json:335](../src/data/chapter4-755.content.json#L335)
360. 204 仍有家具未复原。
   来源：[src/data/chapter4-755.content.json:338](../src/data/chapter4-755.content.json#L338)
361. 依据四处原始痕迹完成剩余成组摆放，直到四组全部复原。
   来源：[src/data/chapter4-755.content.json:339](../src/data/chapter4-755.content.json#L339)
362. 该家具未被当前场景识别。
   来源：[src/data/chapter4-755.content.json:342](../src/data/chapter4-755.content.json#L342)
363. 重新选取 204 内可见且尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:343](../src/data/chapter4-755.content.json#L343)
364. 该位置不属于 204 的复原槽位。
   来源：[src/data/chapter4-755.content.json:346](../src/data/chapter4-755.content.json#L346)
365. 靠近教室内清晰显示的空槽位后重试。
   来源：[src/data/chapter4-755.content.json:347](../src/data/chapter4-755.content.json#L347)
366. 该家具状态无法写入复原记录。
   来源：[src/data/chapter4-755.content.json:350](../src/data/chapter4-755.content.json#L350)
367. 放下后重新选取家具，再放入任一空槽位。
   来源：[src/data/chapter4-755.content.json:351](../src/data/chapter4-755.content.json#L351)
368. 这组家具已经写入另一个槽位。
   来源：[src/data/chapter4-755.content.json:354](../src/data/chapter4-755.content.json#L354)
369. 改选一组尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:355](../src/data/chapter4-755.content.json#L355)
370. 这个槽位已经有一组家具。
   来源：[src/data/chapter4-755.content.json:358](../src/data/chapter4-755.content.json#L358)
371. 把当前家具放入另一个空槽位。
   来源：[src/data/chapter4-755.content.json:359](../src/data/chapter4-755.content.json#L359)
372. 这组家具已经完成复原。
   来源：[src/data/chapter4-755.content.json:362](../src/data/chapter4-755.content.json#L362)
373. 继续选择一组尚未复原的家具。
   来源：[src/data/chapter4-755.content.json:363](../src/data/chapter4-755.content.json#L363)
374. 这片痕迹不属于当前复原记录。
   来源：[src/data/chapter4-755.content.json:366](../src/data/chapter4-755.content.json#L366)
375. 靠近教室内仍有残影的痕迹区。
   来源：[src/data/chapter4-755.content.json:367](../src/data/chapter4-755.content.json#L367)
376. 当前痕迹区与提交的复原组不一致。
   来源：[src/data/chapter4-755.content.json:370](../src/data/chapter4-755.content.json#L370)
377. 留在当前痕迹区并重新执行一次复原。
   来源：[src/data/chapter4-755.content.json:371](../src/data/chapter4-755.content.json#L371)
378. 这组三处位置含有旧存档中的占用记录。
   来源：[src/data/chapter4-755.content.json:374](../src/data/chapter4-755.content.json#L374)
379. 先处理其他痕迹区；当前组会保留原记录。
   来源：[src/data/chapter4-755.content.json:375](../src/data/chapter4-755.content.json#L375)
380. 这组三处桌椅已经复原。
   来源：[src/data/chapter4-755.content.json:378](../src/data/chapter4-755.content.json#L378)
381. 查看教室内仍有残影的痕迹区。
   来源：[src/data/chapter4-755.content.json:379](../src/data/chapter4-755.content.json#L379)
382. 讲台抽屉尚未解锁。
   来源：[src/data/chapter4-755.content.json:382](../src/data/chapter4-755.content.json#L382)
383. 先完成四组复原并确认 07:55 投影。
   来源：[src/data/chapter4-755.content.json:383](../src/data/chapter4-755.content.json#L383)
384. 一楼的时间记录还没有形成可比较的同一组。
   来源：[src/data/chapter4-755.content.json:386](../src/data/chapter4-755.content.json#L386)
385. 补齐 104、105 与电梯的原始记录，再查看它们共有的时间差。
   来源：[src/data/chapter4-755.content.json:387](../src/data/chapter4-755.content.json#L387)
386. 投影中的时间、空间和纸痕仍未完成叠合。
   来源：[src/data/chapter4-755.content.json:390](../src/data/chapter4-755.content.json#L390)
387. 回看教室里四组原始痕迹，确认它们在投影中同时稳定。
   来源：[src/data/chapter4-755.content.json:391](../src/data/chapter4-755.content.json#L391)
388. 保洁车与旧钟之间的同源碰撞痕迹尚未确认。
   来源：[src/data/chapter4-755.content.json:394](../src/data/chapter4-755.content.json#L394)
389. 比较教室投影的缺口形状与保洁车轮罩附近的擦痕。
   来源：[src/data/chapter4-755.content.json:395](../src/data/chapter4-755.content.json#L395)
390. 当前照明还没有确认纸痕经过的连续区域。
   来源：[src/data/chapter4-755.content.json:398](../src/data/chapter4-755.content.json#L398)
391. 回到配电面板，让先前记录过的三个区域同时保持可见。
   来源：[src/data/chapter4-755.content.json:399](../src/data/chapter4-755.content.json#L399)
392. 身份记录与三楼留下的求学信息尚未形成完整对应。
   来源：[src/data/chapter4-755.content.json:402](../src/data/chapter4-755.content.json#L402)
393. 查看三楼参照教室与中央信息墙留下的姓名和时间细节。
   来源：[src/data/chapter4-755.content.json:403](../src/data/chapter4-755.content.json#L403)
394. 大厅旧钟仍缺少钟面定位片。
   来源：[src/data/chapter4-755.content.json:406](../src/data/chapter4-755.content.json#L406)
395. 从 204 讲台抽屉取得定位片，再拖到旧钟插槽。
   来源：[src/data/chapter4-755.content.json:407](../src/data/chapter4-755.content.json#L407)
396. 保洁车轮的卡滞点尚未确认。
   来源：[src/data/chapter4-755.content.json:410](../src/data/chapter4-755.content.json#L410)
397. 先检查卡住的车轮，再使用短撬棒打开轮罩。
   来源：[src/data/chapter4-755.content.json:411](../src/data/chapter4-755.content.json#L411)
398. 润滑位置仍被轮罩挡住。
   来源：[src/data/chapter4-755.content.json:414](../src/data/chapter4-755.content.json#L414)
399. 先用短撬棒打开轮罩，再取得润滑油。
   来源：[src/data/chapter4-755.content.json:415](../src/data/chapter4-755.content.json#L415)
400. 旧钟齿轮维修仍受保洁车阻挡。
   来源：[src/data/chapter4-755.content.json:418](../src/data/chapter4-755.content.json#L418)
401. 先给保洁车轮上油并让车移动，再处理旧钟齿轮。
   来源：[src/data/chapter4-755.content.json:419](../src/data/chapter4-755.content.json#L419)
402. 旧钟齿轮仍处于断续状态。
   来源：[src/data/chapter4-755.content.json:422](../src/data/chapter4-755.content.json#L422)
403. 先完成车轮维修，再给旧钟齿轮上油。
   来源：[src/data/chapter4-755.content.json:423](../src/data/chapter4-755.content.json#L423)
404. 最后一分钟的拖拽过程尚未就绪。
   来源：[src/data/chapter4-755.content.json:426](../src/data/chapter4-755.content.json#L426)
405. 完成旧钟维修后，在浅色操作中重新开始拖动分针。
   来源：[src/data/chapter4-755.content.json:427](../src/data/chapter4-755.content.json#L427)
406. 配电流程尚未开放或已经锁定。
   来源：[src/data/chapter4-755.content.json:430](../src/data/chapter4-755.content.json#L430)
407. 先完成分针拖拽；若已锁定照明，继续前往 202。
   来源：[src/data/chapter4-755.content.json:431](../src/data/chapter4-755.content.json#L431)
408. 这次追逐请求已失效。
   来源：[src/data/chapter4-755.content.json:434](../src/data/chapter4-755.content.json#L434)
409. 从当前追逐检查点重新开始。
   来源：[src/data/chapter4-755.content.json:435](../src/data/chapter4-755.content.json#L435)
410. 最后一分钟尚未安全取回。
   来源：[src/data/chapter4-755.content.json:438](../src/data/chapter4-755.content.json#L438)
411. 抵达 202 并收取阶梯座椅间的黄铜分针组件。
   来源：[src/data/chapter4-755.content.json:439](../src/data/chapter4-755.content.json#L439)
412. 黄铜分针组件尚未送回一楼大厅旧钟。
   来源：[src/data/chapter4-755.content.json:442](../src/data/chapter4-755.content.json#L442)
413. 携带黄铜分针组件、校园卡和签到纸，经主楼梯返回一楼大厅。
   来源：[src/data/chapter4-755.content.json:443](../src/data/chapter4-755.content.json#L443)
414. 第三章半的证据恢复尚未闭合。
   来源：[src/data/chapter4-755.content.json:446](../src/data/chapter4-755.content.json#L446)
415. 返回手机完成时间线与地点确认，再继续第四章。
   来源：[src/data/chapter4-755.content.json:447](../src/data/chapter4-755.content.json#L447)
416. 当前签到条件尚未齐全。
   来源：[src/data/chapter4-755.content.json:450](../src/data/chapter4-755.content.json#L450)
417. 确认已到 07:55，并把对应的校园卡或签到纸拖到各自设备。
   来源：[src/data/chapter4-755.content.json:451](../src/data/chapter4-755.content.json#L451)
418. 校园卡验证已经通过。
   来源：[src/data/chapter4-755.content.json:454](../src/data/chapter4-755.content.json#L454)
419. 继续提交签到记录纸。
   来源：[src/data/chapter4-755.content.json:455](../src/data/chapter4-755.content.json#L455)
420. 签到记录纸验证已经通过。
   来源：[src/data/chapter4-755.content.json:458](../src/data/chapter4-755.content.json#L458)
421. 继续读取校园卡。
   来源：[src/data/chapter4-755.content.json:459](../src/data/chapter4-755.content.json#L459)
422. 签到处还有一项记录没收好。
   来源：[src/data/chapter4-755.content.json:462](../src/data/chapter4-755.content.json#L462)
423. 先完成校园卡与签到纸的双重签到。
   来源：[src/data/chapter4-755.content.json:463](../src/data/chapter4-755.content.json#L463)
424. 灯光还没亮完。
   来源：[src/data/chapter4-755.content.json:466](../src/data/chapter4-755.content.json#L466)
425. 请稍等片刻。
   来源：[src/data/chapter4-755.content.json:467](../src/data/chapter4-755.content.json#L467)
426. 传送带还在转。烤箱旁那盏检修灯，连着一个开关。
   来源：[src/data/chapter4-755.content.json:512](../src/data/chapter4-755.content.json#L512)
427. 接住公告栏前的纸条
   来源：[src/data/chapter4-755.content.json:830](../src/data/chapter4-755.content.json#L830)
428. 纸条落在公告栏前。
   来源：[src/data/chapter4-755.content.json:832](../src/data/chapter4-755.content.json#L832)
429. 等它停下来，别从下面追着跑。
   来源：[src/data/chapter4-755.content.json:833](../src/data/chapter4-755.content.json#L833)
430. 靠近落点后交互。
   来源：[src/data/chapter4-755.content.json:834](../src/data/chapter4-755.content.json#L834)
431. 查看大厅旧钟
   来源：[src/data/chapter4-755.content.json:838](../src/data/chapter4-755.content.json#L838)
432. 大厅中央的旧钟还在响。
   来源：[src/data/chapter4-755.content.json:840](../src/data/chapter4-755.content.json#L840)
433. 指针有缺口，钟壳里也有卡顿声。
   来源：[src/data/chapter4-755.content.json:841](../src/data/chapter4-755.content.json#L841)
434. 浅色操作时可以近看钟面。
   来源：[src/data/chapter4-755.content.json:842](../src/data/chapter4-755.content.json#L842)
435. 试着拨动大厅旧钟
   来源：[src/data/chapter4-755.content.json:846](../src/data/chapter4-755.content.json#L846)
436. 外圈有一处额外刻度。
   来源：[src/data/chapter4-755.content.json:848](../src/data/chapter4-755.content.json#L848)
437. 有些位置拨过去就会弹回，留意能停住的位置。
   来源：[src/data/chapter4-755.content.json:849](../src/data/chapter4-755.content.json#L849)
438. 左右选择刻度，再确认。
   来源：[src/data/chapter4-755.content.json:850](../src/data/chapter4-755.content.json#L850)
439. 返回大厅重新调节旧钟
   来源：[src/data/chapter4-755.content.json:854](../src/data/chapter4-755.content.json#L854)
440. 金属时针装回后，钟面出现了一处新的稳定刻度。
   来源：[src/data/chapter4-755.content.json:856](../src/data/chapter4-755.content.json#L856)
441. 回到大厅旧钟，左右切换当前可见的时间刻度。
   来源：[src/data/chapter4-755.content.json:857](../src/data/chapter4-755.content.json#L857)；[src/data/chapter4-755.content.json:865](../src/data/chapter4-755.content.json#L865)
442. 确认后留意楼内光线、设备声和可进入区域的变化。
   来源：[src/data/chapter4-755.content.json:858](../src/data/chapter4-755.content.json#L858)
443. 用定位片校准出的刻度再次调时
   来源：[src/data/chapter4-755.content.json:862](../src/data/chapter4-755.content.json#L862)
444. 定位片归位后，钟面又有一处刻度不再回弹。
   来源：[src/data/chapter4-755.content.json:864](../src/data/chapter4-755.content.json#L864)
445. 确认后观察地面痕迹与夜间照明的变化。
   来源：[src/data/chapter4-755.content.json:866](../src/data/chapter4-755.content.json#L866)
446. 查查面包坊的传送带
   来源：[src/data/chapter4-755.content.json:870](../src/data/chapter4-755.content.json#L870)
447. 一楼西侧传来机械声。
   来源：[src/data/chapter4-755.content.json:872](../src/data/chapter4-755.content.json#L872)
448. 传送带还在转，烤箱旁有一盏检修灯。
   来源：[src/data/chapter4-755.content.json:873](../src/data/chapter4-755.content.json#L873)
449. 浅色操作时，可以检查检修灯旁的开关。
   来源：[src/data/chapter4-755.content.json:874](../src/data/chapter4-755.content.json#L874)
450. 取走传送带上的旧时针
   来源：[src/data/chapter4-755.content.json:878](../src/data/chapter4-755.content.json#L878)
451. 传送带停下后，缝里露出一段金属。
   来源：[src/data/chapter4-755.content.json:880](../src/data/chapter4-755.content.json#L880)
452. 轴孔与大厅旧钟的缺口相似。
   来源：[src/data/chapter4-755.content.json:881](../src/data/chapter4-755.content.json#L881)
453. 等完全停稳，靠近拾取。
   来源：[src/data/chapter4-755.content.json:882](../src/data/chapter4-755.content.json#L882)
454. 回大厅装回旧时针
   来源：[src/data/chapter4-755.content.json:886](../src/data/chapter4-755.content.json#L886)
455. 时针已经找到了，大厅旧钟还缺着这一件。
   来源：[src/data/chapter4-755.content.json:888](../src/data/chapter4-755.content.json#L888)
456. 对照轴孔，别装到外圈刻度上。
   来源：[src/data/chapter4-755.content.json:889](../src/data/chapter4-755.content.json#L889)
457. 浅色操作时，把时针放进对应接口。
   来源：[src/data/chapter4-755.content.json:890](../src/data/chapter4-755.content.json#L890)
458. 去三楼找晨间教室的参照
   来源：[src/data/chapter4-755.content.json:894](../src/data/chapter4-755.content.json#L894)
459. 电梯厅还留着晚间运行记录。
   来源：[src/data/chapter4-755.content.json:896](../src/data/chapter4-755.content.json#L896)
460. 三楼有一间教室保留着晨间布置。
   来源：[src/data/chapter4-755.content.json:897](../src/data/chapter4-755.content.json#L897)
461. 深色观察能记下桌椅与入口的位置。
   来源：[src/data/chapter4-755.content.json:898](../src/data/chapter4-755.content.json#L898)
462. 查完一楼剩下的记录
   来源：[src/data/chapter4-755.content.json:902](../src/data/chapter4-755.content.json#L902)
463. 一楼还有黑板、讲台、电梯和签到板没查完；任务栏会记下查过的地方。
   来源：[src/data/chapter4-755.content.json:904](../src/data/chapter4-755.content.json#L904)
464. 104 和 105 留下的时间有出入，电梯记录也值得对照。签到板可以单独查看。
   来源：[src/data/chapter4-755.content.json:905](../src/data/chapter4-755.content.json#L905)
465. 深色观察读取痕迹，浅色操作调整设备；两种模式的进入顺序不会锁死进度。
   来源：[src/data/chapter4-755.content.json:906](../src/data/chapter4-755.content.json#L906)
466. 查清 104 与 105 的时间差
   来源：[src/data/chapter4-755.content.json:910](../src/data/chapter4-755.content.json#L910)
467. 隔壁两间教室的记录对不上。
   来源：[src/data/chapter4-755.content.json:912](../src/data/chapter4-755.content.json#L912)
468. 104 黑板擦过了，深色观察下还能看见笔画。
   来源：[src/data/chapter4-755.content.json:913](../src/data/chapter4-755.content.json#L913)
469. 105 讲台留有本地回放，可以动手查；两间先看哪间都行。
   来源：[src/data/chapter4-755.content.json:914](../src/data/chapter4-755.content.json#L914)
470. 核对电梯的开门时刻
   来源：[src/data/chapter4-755.content.json:918](../src/data/chapter4-755.content.json#L918)
471. 轿厢到站、门打开、人走进去，三段时间没有重合。
   来源：[src/data/chapter4-755.content.json:920](../src/data/chapter4-755.content.json#L920)
472. 深色观察能读出三条轨道；浅色操作可以调重放起点。
   来源：[src/data/chapter4-755.content.json:921](../src/data/chapter4-755.content.json#L921)
473. 看记录和试着校准，先做哪项都行。
   来源：[src/data/chapter4-755.content.json:922](../src/data/chapter4-755.content.json#L922)
474. 让电梯开门时间够人通过
   来源：[src/data/chapter4-755.content.json:926](../src/data/chapter4-755.content.json#L926)
475. 到一楼轿厢里试着调重放起点。
   来源：[src/data/chapter4-755.content.json:928](../src/data/chapter4-755.content.json#L928)
476. 人要走六秒，门也得在这六秒里一直开着。
   来源：[src/data/chapter4-755.content.json:929](../src/data/chapter4-755.content.json#L929)
477. 调好以后再看楼层显示，别只听到站铃。
   来源：[src/data/chapter4-755.content.json:930](../src/data/chapter4-755.content.json#L930)
478. 核对各层电梯的停靠记录
   来源：[src/data/chapter4-755.content.json:934](../src/data/chapter4-755.content.json#L934)
479. 各层记录的事件不同，按过按钮不代表电梯停过。
   来源：[src/data/chapter4-755.content.json:936](../src/data/chapter4-755.content.json#L936)
480. 轿厢里的起行轨、到站铃和外呼日志都能查看。
   来源：[src/data/chapter4-755.content.json:937](../src/data/chapter4-755.content.json#L937)
481. 在面板上分清实际到站与未响应的呼叫。
   来源：[src/data/chapter4-755.content.json:938](../src/data/chapter4-755.content.json#L938)
482. 回答校史墙上的两问
   来源：[src/data/chapter4-755.content.json:942](../src/data/chapter4-755.content.json#L942)
483. 第一问是到浙大来做什么。
   来源：[src/data/chapter4-755.content.json:944](../src/data/chapter4-755.content.json#L944)
484. 第二问是将来毕业后要做什么样的人。
   来源：[src/data/chapter4-755.content.json:945](../src/data/chapter4-755.content.json#L945)
485. 按你的想法选择。
   来源：[src/data/chapter4-755.content.json:946](../src/data/chapter4-755.content.json#L946)
486. 记录三楼晨间教室的布置
   来源：[src/data/chapter4-755.content.json:950](../src/data/chapter4-755.content.json#L950)
487. 三楼晨间教室还保留着完整布局。
   来源：[src/data/chapter4-755.content.json:952](../src/data/chapter4-755.content.json#L952)
488. 用深色观察看桌椅、入口和投影边界。
   来源：[src/data/chapter4-755.content.json:953](../src/data/chapter4-755.content.json#L953)
489. 记下参照后，去主楼梯看看。
   来源：[src/data/chapter4-755.content.json:954](../src/data/chapter4-755.content.json#L954)
490. 接通三楼通往二楼的楼梯
   来源：[src/data/chapter4-755.content.json:958](../src/data/chapter4-755.content.json#L958)
491. 楼梯的断口在不同视角下位置不同。
   来源：[src/data/chapter4-755.content.json:960](../src/data/chapter4-755.content.json#L960)
492. 横移、旋转和升降都可以调，先看端点能否接上。
   来源：[src/data/chapter4-755.content.json:961](../src/data/chapter4-755.content.json#L961)
493. 换一个固定视角检查通路，再继续下一段。
   来源：[src/data/chapter4-755.content.json:962](../src/data/chapter4-755.content.json#L962)
494. 查看 204 留下的桌椅痕迹
   来源：[src/data/chapter4-755.content.json:966](../src/data/chapter4-755.content.json#L966)
495. 204 地上留着几组搬动痕迹。
   来源：[src/data/chapter4-755.content.json:968](../src/data/chapter4-755.content.json#L968)
496. 深色观察可记下原位置，三楼参照可以拿来比较。
   来源：[src/data/chapter4-755.content.json:969](../src/data/chapter4-755.content.json#L969)
497. 收齐两处记录后再核对摆放结果。
   来源：[src/data/chapter4-755.content.json:970](../src/data/chapter4-755.content.json#L970)
498. 把教室恢复成早晨的样子
   来源：[src/data/chapter4-755.content.json:974](../src/data/chapter4-755.content.json#L974)
499. 用三楼参照和这里的地面痕迹核对摆放。
   来源：[src/data/chapter4-755.content.json:976](../src/data/chapter4-755.content.json#L976)
500. 十二件家具分成四组，可以一组一组移。
   来源：[src/data/chapter4-755.content.json:977](../src/data/chapter4-755.content.json#L977)
501. 浅色操作搬家具，深色观察补看痕迹，顺序不限。
   来源：[src/data/chapter4-755.content.json:978](../src/data/chapter4-755.content.json#L978)
502. 看看 204 恢复出的画面
   来源：[src/data/chapter4-755.content.json:982](../src/data/chapter4-755.content.json#L982)
503. 桌椅归位后，前方投影出现了变化。
   来源：[src/data/chapter4-755.content.json:984](../src/data/chapter4-755.content.json#L984)
504. 靠近幕布，等画面稳定。
   来源：[src/data/chapter4-755.content.json:985](../src/data/chapter4-755.content.json#L985)
505. 把看清的时间和纸痕记下来。
   来源：[src/data/chapter4-755.content.json:986](../src/data/chapter4-755.content.json#L986)
506. 检查 204 讲台抽屉
   来源：[src/data/chapter4-755.content.json:990](../src/data/chapter4-755.content.json#L990)
507. 投影稳定后，讲台那边响了一声。
   来源：[src/data/chapter4-755.content.json:992](../src/data/chapter4-755.content.json#L992)
508. 抽屉松开了。
   来源：[src/data/chapter4-755.content.json:993](../src/data/chapter4-755.content.json#L993)
509. 浅色操作时可以取出里面的部件。
   来源：[src/data/chapter4-755.content.json:994](../src/data/chapter4-755.content.json#L994)
510. 补齐二楼的现场记录
   来源：[src/data/chapter4-755.content.json:998](../src/data/chapter4-755.content.json#L998)
511. 201 有定位板，203 留有供电图，自习区还有路线板。
   来源：[src/data/chapter4-755.content.json:1000](../src/data/chapter4-755.content.json#L1000)
512. 查看板上的原始痕迹，再动手调整。
   来源：[src/data/chapter4-755.content.json:1001](../src/data/chapter4-755.content.json#L1001)
513. 三处互不排队，先查哪处都可以。
   来源：[src/data/chapter4-755.content.json:1002](../src/data/chapter4-755.content.json#L1002)
514. 把定位片装回大厅旧钟
   来源：[src/data/chapter4-755.content.json:1006](../src/data/chapter4-755.content.json#L1006)
515. 定位片已校准，回一楼比对钟面。
   来源：[src/data/chapter4-755.content.json:1008](../src/data/chapter4-755.content.json#L1008)
516. 透明片边缘的短刻度能对上接口。
   来源：[src/data/chapter4-755.content.json:1009](../src/data/chapter4-755.content.json#L1009)
517. 浅色操作时把定位片放进插槽。
   来源：[src/data/chapter4-755.content.json:1010](../src/data/chapter4-755.content.json#L1010)
518. 查清保洁车为什么卡住
   来源：[src/data/chapter4-755.content.json:1014](../src/data/chapter4-755.content.json#L1014)
519. 靠近车轮，听听摩擦声。
   来源：[src/data/chapter4-755.content.json:1016](../src/data/chapter4-755.content.json#L1016)
520. 地面有油迹，旧钟里也有卡顿声。
   来源：[src/data/chapter4-755.content.json:1017](../src/data/chapter4-755.content.json#L1017)
521. 把现象和故障原因对应起来，提交前可以改选。
   来源：[src/data/chapter4-755.content.json:1018](../src/data/chapter4-755.content.json#L1018)
522. 去面包坊后场找工具
   来源：[src/data/chapter4-755.content.json:1022](../src/data/chapter4-755.content.json#L1022)
523. 保洁车轮罩留着一道窄缝。
   来源：[src/data/chapter4-755.content.json:1024](../src/data/chapter4-755.content.json#L1024)
524. 后场有短柄工具，可以看看扁头尺寸。
   来源：[src/data/chapter4-755.content.json:1025](../src/data/chapter4-755.content.json#L1025)
525. 浅色操作时拾取。
   来源：[src/data/chapter4-755.content.json:1026](../src/data/chapter4-755.content.json#L1026)
526. 撬开保洁车轮罩
   来源：[src/data/chapter4-755.content.json:1030](../src/data/chapter4-755.content.json#L1030)
527. 轮罩挡住了卡住的部位。
   来源：[src/data/chapter4-755.content.json:1032](../src/data/chapter4-755.content.json#L1032)
528. 短撬棍的扁头能伸进缝里。
   来源：[src/data/chapter4-755.content.json:1033](../src/data/chapter4-755.content.json#L1033)
529. 浅色操作时，把撬棍用在轮罩上。
   来源：[src/data/chapter4-755.content.json:1034](../src/data/chapter4-755.content.json#L1034)
530. 看看打开的轮罩里面
   来源：[src/data/chapter4-755.content.json:1038](../src/data/chapter4-755.content.json#L1038)
531. 轮罩已经松开，里面还有一小瓶油。
   来源：[src/data/chapter4-755.content.json:1040](../src/data/chapter4-755.content.json#L1040)
532. 车轮的摩擦声还没停。
   来源：[src/data/chapter4-755.content.json:1041](../src/data/chapter4-755.content.json#L1041)
533. 浅色操作时可以取出润滑油。
   来源：[src/data/chapter4-755.content.json:1042](../src/data/chapter4-755.content.json#L1042)
534. 修复轮轴与旧钟的卡滞
   来源：[src/data/chapter4-755.content.json:1046](../src/data/chapter4-755.content.json#L1046)
535. 检查已经打开的轮罩。
   来源：[src/data/chapter4-755.content.json:1048](../src/data/chapter4-755.content.json#L1048)
536. 先前的诊断记录了车轮缺油和齿轮偏位。
   来源：[src/data/chapter4-755.content.json:1049](../src/data/chapter4-755.content.json#L1049)
537. 浅色操作时给车轮上油，再确认联动修复结果。
   来源：[src/data/chapter4-755.content.json:1050](../src/data/chapter4-755.content.json#L1050)
538. 用余下的油修复旧钟齿轮
   来源：[src/data/chapter4-755.content.json:1054](../src/data/chapter4-755.content.json#L1054)
539. 车轮顺了，钟壳里还有摩擦声。
   来源：[src/data/chapter4-755.content.json:1056](../src/data/chapter4-755.content.json#L1056)
540. 剩下的润滑油够处理齿轮。
   来源：[src/data/chapter4-755.content.json:1057](../src/data/chapter4-755.content.json#L1057)
541. 回大厅，在浅色操作中给齿轮上油。
   来源：[src/data/chapter4-755.content.json:1058](../src/data/chapter4-755.content.json#L1058)
542. 把旧钟拨向 07:55
   来源：[src/data/chapter4-755.content.json:1062](../src/data/chapter4-755.content.json#L1062)；[src/data/chapter4-755.content.json:1754](../src/data/chapter4-755.content.json#L1754)
543. 查看维修完成后的大厅旧钟表盘。
   来源：[src/data/chapter4-755.content.json:1064](../src/data/chapter4-755.content.json#L1064)
544. 车轮与钟内齿轮均修复后，旧钟才接受最终校时。
   来源：[src/data/chapter4-755.content.json:1065](../src/data/chapter4-755.content.json#L1065)
545. 在浅色操作中拖动旧钟分针到 07:55 刻度并松开。
   来源：[src/data/chapter4-755.content.json:1066](../src/data/chapter4-755.content.json#L1066)
546. 点亮追赶所需的通路
   来源：[src/data/chapter4-755.content.json:1070](../src/data/chapter4-755.content.json#L1070)
547. 配电面板管着五个灯区。
   来源：[src/data/chapter4-755.content.json:1072](../src/data/chapter4-755.content.json#L1072)
548. 先前的疏散路线板和供电图都在记录里。
   来源：[src/data/chapter4-755.content.json:1073](../src/data/chapter4-755.content.json#L1073)
549. 对照沿途区域调整，确认前可看走廊实际亮灭。
   来源：[src/data/chapter4-755.content.json:1074](../src/data/chapter4-755.content.json#L1074)
550. 追进 202，关好门
   来源：[src/data/chapter4-755.content.json:1078](../src/data/chapter4-755.content.json#L1078)
551. 纸条沿已查明的通路上了楼。
   来源：[src/data/chapter4-755.content.json:1080](../src/data/chapter4-755.content.json#L1080)
552. 保安会跟上楼，进门后别忘了门闩。
   来源：[src/data/chapter4-755.content.json:1081](../src/data/chapter4-755.content.json#L1081)
553. 到 202 门内按 Space 关门。
   来源：[src/data/chapter4-755.content.json:1082](../src/data/chapter4-755.content.json#L1082)
554. 取回黄铜分针组件
   来源：[src/data/chapter4-755.content.json:1086](../src/data/chapter4-755.content.json#L1086)
555. 门闩关好后再找，保安还在外面。
   来源：[src/data/chapter4-755.content.json:1088](../src/data/chapter4-755.content.json#L1088)
556. 组件卡在阶梯座椅之间。
   来源：[src/data/chapter4-755.content.json:1089](../src/data/chapter4-755.content.json#L1089)
557. 检查固定扣和轴座，别直接硬拔。
   来源：[src/data/chapter4-755.content.json:1090](../src/data/chapter4-755.content.json#L1090)
558. 把黄铜分针组件带回一楼大厅
   来源：[src/data/chapter4-755.content.json:1094](../src/data/chapter4-755.content.json#L1094)
559. 沿来时的走廊回主楼梯。
   来源：[src/data/chapter4-755.content.json:1096](../src/data/chapter4-755.content.json#L1096)
560. 停电时电梯不开，得走楼梯。
   来源：[src/data/chapter4-755.content.json:1097](../src/data/chapter4-755.content.json#L1097)
561. 下到一楼后，把组件带到旧钟前。
   来源：[src/data/chapter4-755.content.json:1098](../src/data/chapter4-755.content.json#L1098)
562. 将黄铜分针组件装回大厅旧钟
   来源：[src/data/chapter4-755.content.json:1102](../src/data/chapter4-755.content.json#L1102)
563. 靠近一楼大厅旧钟，确认表盘完整出现在画面中。
   来源：[src/data/chapter4-755.content.json:1104](../src/data/chapter4-755.content.json#L1104)
564. 黄铜分针组件可以放入大厅旧钟的可见表盘范围。
   来源：[src/data/chapter4-755.content.json:1105](../src/data/chapter4-755.content.json#L1105)
565. 在浅色操作中，把道具栏里的黄铜分针组件拖到旧钟表盘内松手。
   来源：[src/data/chapter4-755.content.json:1106](../src/data/chapter4-755.content.json#L1106)
566. 完成刷卡与纸条签到
   来源：[src/data/chapter4-755.content.json:1110](../src/data/chapter4-755.content.json#L1110)
567. 签到处有读卡器和纸槽。
   来源：[src/data/chapter4-755.content.json:1112](../src/data/chapter4-755.content.json#L1112)
568. 刷卡、交纸都要完成，先做哪项都可以。
   来源：[src/data/chapter4-755.content.json:1113](../src/data/chapter4-755.content.json#L1113)
569. 用浅色操作分别提交校园卡与签到记录纸。
   来源：[src/data/chapter4-755.content.json:1114](../src/data/chapter4-755.content.json#L1114)
570. 刷校园卡
   来源：[src/data/chapter4-755.content.json:1118](../src/data/chapter4-755.content.json#L1118)
571. 纸条已经收下，还差身份核验。
   来源：[src/data/chapter4-755.content.json:1120](../src/data/chapter4-755.content.json#L1120)
572. 签到台旁有读卡器。
   来源：[src/data/chapter4-755.content.json:1121](../src/data/chapter4-755.content.json#L1121)
573. 浅色操作时提交校园卡。
   来源：[src/data/chapter4-755.content.json:1122](../src/data/chapter4-755.content.json#L1122)
574. 交签到记录纸
   来源：[src/data/chapter4-755.content.json:1126](../src/data/chapter4-755.content.json#L1126)
575. 刷卡已经通过，还差纸质记录。
   来源：[src/data/chapter4-755.content.json:1128](../src/data/chapter4-755.content.json#L1128)
576. 签到台旁有纸槽。
   来源：[src/data/chapter4-755.content.json:1129](../src/data/chapter4-755.content.json#L1129)
577. 浅色操作时提交签到记录纸。
   来源：[src/data/chapter4-755.content.json:1130](../src/data/chapter4-755.content.json#L1130)
578. 本人来过
   来源：[src/data/chapter4-755.content.json:1138](../src/data/chapter4-755.content.json#L1138)
579. system
   来源：[src/data/chapter4-755.content.json:1145](../src/data/chapter4-755.content.json#L1145)；[src/data/chapter4-755.content.json:1155](../src/data/chapter4-755.content.json#L1155)；[src/data/chapter4-755.content.json:1161](../src/data/chapter4-755.content.json#L1161)；[src/data/chapter4-755.content.json:1165](../src/data/chapter4-755.content.json#L1165)；[src/data/chapter4-755.content.json:1173](../src/data/chapter4-755.content.json#L1173)；[src/data/chapter4-755.content.json:1177](../src/data/chapter4-755.content.json#L1177)；[src/data/chapter4-755.content.json:1183](../src/data/chapter4-755.content.json#L1183)；[src/data/chapter4-755.content.json:1191](../src/data/chapter4-755.content.json#L1191)；[src/data/chapter4-755.content.json:1197](../src/data/chapter4-755.content.json#L1197)；[src/data/chapter4-755.content.json:1217](../src/data/chapter4-755.content.json#L1217)；[src/data/chapter4-755.content.json:1227](../src/data/chapter4-755.content.json#L1227)；[src/data/chapter4-755.content.json:1231](../src/data/chapter4-755.content.json#L1231)；[src/data/chapter4-755.content.json:1315](../src/data/chapter4-755.content.json#L1315)；[src/data/chapter4-755.content.json:1321](../src/data/chapter4-755.content.json#L1321)；[src/data/chapter4-755.content.json:1341](../src/data/chapter4-755.content.json#L1341)；[src/data/chapter4-755.content.json:1349](../src/data/chapter4-755.content.json#L1349)；[src/data/chapter4-755.content.json:1377](../src/data/chapter4-755.content.json#L1377)；[src/data/chapter4-755.content.json:1383](../src/data/chapter4-755.content.json#L1383)；[src/data/chapter4-755.content.json:1389](../src/data/chapter4-755.content.json#L1389)；[src/data/chapter4-755.content.json:1403](../src/data/chapter4-755.content.json#L1403)；[src/data/chapter4-755.content.json:1409](../src/data/chapter4-755.content.json#L1409)；[src/data/chapter4-755.content.json:1415](../src/data/chapter4-755.content.json#L1415)；[src/data/chapter4-755.content.json:1421](../src/data/chapter4-755.content.json#L1421)；[src/data/chapter4-755.content.json:1429](../src/data/chapter4-755.content.json#L1429)；[src/data/chapter4-755.content.json:1435](../src/data/chapter4-755.content.json#L1435)；[src/data/chapter4-755.content.json:1443](../src/data/chapter4-755.content.json#L1443)；[src/scenes/phone/P14_Wechat/index.tsx:447](../src/scenes/phone/P14_Wechat/index.tsx#L447)；[src/scenes/phone/P14_Wechat/index.tsx:450](../src/scenes/phone/P14_Wechat/index.tsx#L450)
580. 现场画面已同步。异常签到纸正在飞向公告栏。
   来源：[src/data/chapter4-755.content.json:1146](../src/data/chapter4-755.content.json#L1146)
581. player
   来源：[src/data/chapter4-755.content.json:1151](../src/data/chapter4-755.content.json#L1151)；[src/data/chapter4-755.content.json:1169](../src/data/chapter4-755.content.json#L1169)；[src/data/chapter4-755.content.json:1187](../src/data/chapter4-755.content.json#L1187)；[src/data/chapter4-755.content.json:1207](../src/data/chapter4-755.content.json#L1207)；[src/data/chapter4-755.content.json:1221](../src/data/chapter4-755.content.json#L1221)；[src/data/chapter4-755.content.json:1331](../src/data/chapter4-755.content.json#L1331)；[src/data/chapter4-755.content.json:1345](../src/data/chapter4-755.content.json#L1345)；[src/data/chapter4-755.content.json:1395](../src/data/chapter4-755.content.json#L1395)；[src/data/chapter4-755.content.json:1425](../src/data/chapter4-755.content.json#L1425)；[src/data/chapter4-755.content.json:1439](../src/data/chapter4-755.content.json#L1439)
582. 抓到了。
   来源：[src/data/chapter4-755.content.json:1152](../src/data/chapter4-755.content.json#L1152)
583. 正在提交签到记录……
   来源：[src/data/chapter4-755.content.json:1156](../src/data/chapter4-755.content.json#L1156)
584. 提交失败。外部时间：22:45。
   来源：[src/data/chapter4-755.content.json:1162](../src/data/chapter4-755.content.json#L1162)
585. 签到截止时间：07:55。
   来源：[src/data/chapter4-755.content.json:1166](../src/data/chapter4-755.content.json#L1166)
586. 手机上还写着 07:55:23。
   来源：[src/data/chapter4-755.content.json:1170](../src/data/chapter4-755.content.json#L1170)
587. 手机上的时间没更新。现在已经是 22:45。
   来源：[src/data/chapter4-755.content.json:1174](../src/data/chapter4-755.content.json#L1174)
588. 记录找回来了，迟到还在。补材料不附送补时间。
   来源：[src/data/chapter4-755.content.json:1178](../src/data/chapter4-755.content.json#L1178)
589. 旧钟能被拨动，但指针不会按你的动作走。
   来源：[src/data/chapter4-755.content.json:1184](../src/data/chapter4-755.content.json#L1184)
590. 这是好消息？
   来源：[src/data/chapter4-755.content.json:1188](../src/data/chapter4-755.content.json#L1188)
591. 它还在出错。
   来源：[src/data/chapter4-755.content.json:1192](../src/data/chapter4-755.content.json#L1192)
592. 时间源已切换：大厅旧钟。
   来源：[src/data/chapter4-755.content.json:1198](../src/data/chapter4-755.content.json#L1198)
593. baker
   来源：[src/data/chapter4-755.content.json:1203](../src/data/chapter4-755.content.json#L1203)；[src/data/chapter4-755.content.json:1211](../src/data/chapter4-755.content.json#L1211)
594. 那块金属你认识？我正要报异物。
   来源：[src/data/chapter4-755.content.json:1204](../src/data/chapter4-755.content.json#L1204)
595. 大厅钟上的时针。
   来源：[src/data/chapter4-755.content.json:1208](../src/data/chapter4-755.content.json#L1208)
596. 那装回去吧。别算进我们这班的损耗。
   来源：[src/data/chapter4-755.content.json:1212](../src/data/chapter4-755.content.json#L1212)
597. 黑板已经擦净，残留笔画仍按书写顺序逐段出现。首尾相差 7 分 55 秒。
   来源：[src/data/chapter4-755.content.json:1218](../src/data/chapter4-755.content.json#L1218)
598. 人都下课了，这里还没写完。
   来源：[src/data/chapter4-755.content.json:1222](../src/data/chapter4-755.content.json#L1222)
599. 讲台回放停在 07:47:05，教室记录显示 07:55:00。本地画面延迟 7 分 55 秒。
   来源：[src/data/chapter4-755.content.json:1228](../src/data/chapter4-755.content.json#L1228)
600. 该终端只能证明回放延迟，不能用于校准现场时间。
   来源：[src/data/chapter4-755.content.json:1232](../src/data/chapter4-755.content.json#L1232)
601. 值班助理
   来源：[src/data/chapter4-755.content.json:1237](../src/data/chapter4-755.content.json#L1237)；[src/data/chapter4-755.content.json:1243](../src/data/chapter4-755.content.json#L1243)；[src/data/chapter4-755.content.json:1249](../src/data/chapter4-755.content.json#L1249)；[src/data/chapter4-755.content.json:1255](../src/data/chapter4-755.content.json#L1255)；[src/data/chapter4-755.content.json:1261](../src/data/chapter4-755.content.json#L1261)；[src/data/chapter4-755.content.json:1267](../src/data/chapter4-755.content.json#L1267)；[src/data/chapter4-755.content.json:1273](../src/data/chapter4-755.content.json#L1273)
602. 西边传送带里有东西响，面包坊的人还没取出来。
   来源：[src/data/chapter4-755.content.json:1238](../src/data/chapter4-755.content.json#L1238)
603. 104 的板书和 105 的回放时间不对，得查两间。只填一间，这张表交不上去。
   来源：[src/data/chapter4-755.content.json:1244](../src/data/chapter4-755.content.json#L1244)
604. 104 记下了。105 讲台还有一段回放没查。
   来源：[src/data/chapter4-755.content.json:1250](../src/data/chapter4-755.content.json#L1250)
605. 105 记下了。104 擦过的黑板再看一眼。
   来源：[src/data/chapter4-755.content.json:1256](../src/data/chapter4-755.content.json#L1256)
606. 两间都齐了。电梯那边还有记录，今天的表格够用。
   来源：[src/data/chapter4-755.content.json:1262](../src/data/chapter4-755.content.json#L1262)
607. 现在是 07:55。校园卡放到左侧读卡器，签到纸放入右侧纸槽。
   来源：[src/data/chapter4-755.content.json:1268](../src/data/chapter4-755.content.json#L1268)
608. 钟、手机、签到纸都对上了。今天总算能填“正常”。
   来源：[src/data/chapter4-755.content.json:1274](../src/data/chapter4-755.content.json#L1274)
609. 安全员
   来源：[src/data/chapter4-755.content.json:1279](../src/data/chapter4-755.content.json#L1279)；[src/data/chapter4-755.content.json:1285](../src/data/chapter4-755.content.json#L1285)；[src/data/chapter4-755.content.json:1291](../src/data/chapter4-755.content.json#L1291)
610. 二楼电梯口暂不放行。先把一楼 104 黑板残留和 105 讲台回放都登记完。
   来源：[src/data/chapter4-755.content.json:1280](../src/data/chapter4-755.content.json#L1280)
611. 一楼两项记录已到。先去三楼参照教室核对标准布局，再回 204。
   来源：[src/data/chapter4-755.content.json:1286](../src/data/chapter4-755.content.json#L1286)
612. 三楼参照已登记。现在可以进 204，按残影恢复讲台和桌椅位置。
   来源：[src/data/chapter4-755.content.json:1292](../src/data/chapter4-755.content.json#L1292)
613. 教师
   来源：[src/data/chapter4-755.content.json:1297](../src/data/chapter4-755.content.json#L1297)；[src/data/chapter4-755.content.json:1303](../src/data/chapter4-755.content.json#L1303)
614. 这间教室保留标准布局。用深色观察记录讲台、桌椅和入口边界，完成后回二楼 204。
   来源：[src/data/chapter4-755.content.json:1298](../src/data/chapter4-755.content.json#L1298)
615. 标准布局已经记录。二楼 204 需要的是这份参照。
   来源：[src/data/chapter4-755.content.json:1304](../src/data/chapter4-755.content.json#L1304)
616. projection
   来源：[src/data/chapter4-755.content.json:1309](../src/data/chapter4-755.content.json#L1309)
617. 07:55 / 早到的人还没有开始后悔。
   来源：[src/data/chapter4-755.content.json:1310](../src/data/chapter4-755.content.json#L1310)；[src/data/chapter4-three-floor-maze.layout.json:965](../src/data/chapter4-three-floor-maze.layout.json#L965)
618. 三楼晨间教室的讲台、桌椅和入口边界已经记录。
   来源：[src/data/chapter4-755.content.json:1316](../src/data/chapter4-755.content.json#L1316)
619. 每组桌椅原来的位置已经记下来了。
   来源：[src/data/chapter4-755.content.json:1322](../src/data/chapter4-755.content.json#L1322)
620. cleaner
   来源：[src/data/chapter4-755.content.json:1327](../src/data/chapter4-755.content.json#L1327)；[src/data/chapter4-755.content.json:1335](../src/data/chapter4-755.content.json#L1335)
621. 报修单上写着“可正常推行”。你听听这轮子。
   来源：[src/data/chapter4-755.content.json:1328](../src/data/chapter4-755.content.json#L1328)
622. 我看看轮罩里面。
   来源：[src/data/chapter4-755.content.json:1332](../src/data/chapter4-755.content.json#L1332)
623. 能把这响声弄停就行。表我不想再填了。
   来源：[src/data/chapter4-755.content.json:1336](../src/data/chapter4-755.content.json#L1336)
624. 时间校准至 07:54。
   来源：[src/data/chapter4-755.content.json:1342](../src/data/chapter4-755.content.json#L1342)
625. 差一分钟。
   来源：[src/data/chapter4-755.content.json:1346](../src/data/chapter4-755.content.json#L1346)
626. 纸条把最后一分钟带走了。定位结果：阶梯教室。
   来源：[src/data/chapter4-755.content.json:1350](../src/data/chapter4-755.content.json#L1350)
627. guard
   来源：[src/data/chapter4-755.content.json:1355](../src/data/chapter4-755.content.json#L1355)；[src/data/chapter4-755.content.json:1361](../src/data/chapter4-755.content.json#L1361)；[src/data/chapter4-755.content.json:1367](../src/data/chapter4-755.content.json#L1367)；[src/data/chapter4-755.content.json:1373](../src/data/chapter4-755.content.json#L1373)
628. 同学，站住。离旧钟远一点。
   来源：[src/data/chapter4-755.content.json:1356](../src/data/chapter4-755.content.json#L1356)；[src/data/pursuit.audio.content.json:87](../src/data/pursuit.audio.content.json#L87)
629. 我看到你了。停下。
   来源：[src/data/chapter4-755.content.json:1362](../src/data/chapter4-755.content.json#L1362)；[src/data/pursuit.audio.content.json:115](../src/data/pursuit.audio.content.json#L115)
630. 同学，停下！前面的，听见没有？
   来源：[src/data/chapter4-755.content.json:1368](../src/data/chapter4-755.content.json#L1368)；[src/data/pursuit.audio.content.json:101](../src/data/pursuit.audio.content.json#L101)
631. 出去。
   来源：[src/data/chapter4-755.content.json:1374](../src/data/chapter4-755.content.json#L1374)
632. 保安把你带回大厅，钟上还是 07:54。
   来源：[src/data/chapter4-755.content.json:1378](../src/data/chapter4-755.content.json#L1378)
633. 被清楼保安拦下了，已回到一楼大厅重来。
   来源：[src/data/chapter4-755.content.json:1384](../src/data/chapter4-755.content.json#L1384)
634. 门闩已落下，保安被挡在 202 门外。
   来源：[src/data/chapter4-755.content.json:1390](../src/data/chapter4-755.content.json#L1390)
635. 不跑了？
   来源：[src/data/chapter4-755.content.json:1396](../src/data/chapter4-755.content.json#L1396)
636. paper
   来源：[src/data/chapter4-755.content.json:1399](../src/data/chapter4-755.content.json#L1399)
637. 本人马上回来。
   来源：[src/data/chapter4-755.content.json:1400](../src/data/chapter4-755.content.json#L1400)
638. 它回来了。
   来源：[src/data/chapter4-755.content.json:1404](../src/data/chapter4-755.content.json#L1404)
639. 黄铜分针组件和签到纸条都已取回。
   来源：[src/data/chapter4-755.content.json:1410](../src/data/chapter4-755.content.json#L1410)
640. 门厅旧钟已到 07:55。
   来源：[src/data/chapter4-755.content.json:1416](../src/data/chapter4-755.content.json#L1416)
641. 签到成功。时间：07:55。地点：段永平教学楼 A1。状态：本人来过。
   来源：[src/data/chapter4-755.content.json:1422](../src/data/chapter4-755.content.json#L1422)
642. 现在算准时吗？
   来源：[src/data/chapter4-755.content.json:1426](../src/data/chapter4-755.content.json#L1426)
643. 从时间角度，算。
   来源：[src/data/chapter4-755.content.json:1430](../src/data/chapter4-755.content.json#L1430)
644. 外面亮了一下。
   来源：[src/data/chapter4-755.content.json:1436](../src/data/chapter4-755.content.json#L1436)；[src/modules/ChapterFourTemporalMazeController.ts:1753](../src/modules/ChapterFourTemporalMazeController.ts#L1753)；[src/modules/ChapterFourTemporalMazeController.ts:1783](../src/modules/ChapterFourTemporalMazeController.ts#L1783)
645. 这次真的结束了？
   来源：[src/data/chapter4-755.content.json:1440](../src/data/chapter4-755.content.json#L1440)
646. 结束了，签到记录已归档。
   来源：[src/data/chapter4-755.content.json:1444](../src/data/chapter4-755.content.json#L1444)
647. 窗侧时间刻痕区
   来源：[src/data/chapter4-755.content.json:1548](../src/data/chapter4-755.content.json#L1548)
648. 窗沿粉尘断线与前三处桌面亮边位于同一水平带。
   来源：[src/data/chapter4-755.content.json:1550](../src/data/chapter4-755.content.json#L1550)
649. 中央拖痕区
   来源：[src/data/chapter4-755.content.json:1574](../src/data/chapter4-755.content.json#L1574)
650. 中央地面的三段平行拖痕具有相同间距。
   来源：[src/data/chapter4-755.content.json:1576](../src/data/chapter4-755.content.json#L1576)
651. 讲台投影边缘区
   来源：[src/data/chapter4-755.content.json:1600](../src/data/chapter4-755.content.json#L1600)
652. 讲台投影边缘经过三处桌脚留下的浅色缺口。
   来源：[src/data/chapter4-755.content.json:1602](../src/data/chapter4-755.content.json#L1602)
653. 门侧纸痕区
   来源：[src/data/chapter4-755.content.json:1626](../src/data/chapter4-755.content.json#L1626)
654. 门侧纸屑压痕在三处桌脚位置连续出现。
   来源：[src/data/chapter4-755.content.json:1628](../src/data/chapter4-755.content.json#L1628)
655. 大厅
   来源：[src/data/chapter4-755.content.json:1659](../src/data/chapter4-755.content.json#L1659)
656. 西走廊
   来源：[src/data/chapter4-755.content.json:1669](../src/data/chapter4-755.content.json#L1669)
657. 东走廊
   来源：[src/data/chapter4-755.content.json:1679](../src/data/chapter4-755.content.json#L1679)
658. 教室区
   来源：[src/data/chapter4-755.content.json:1689](../src/data/chapter4-755.content.json#L1689)
659. 面包店后场
   来源：[src/data/chapter4-755.content.json:1699](../src/data/chapter4-755.content.json#L1699)
660. 表盘刻度锁定
   来源：[src/data/chapter4-755.content.json:2275](../src/data/chapter4-755.content.json#L2275)
661. 22:45 → 12:25
   来源：[src/data/chapter4-755.content.json:2276](../src/data/chapter4-755.content.json#L2276)
662. 钟摆恢复摆动，窗外光线收紧，远处传来一段断续的机械声。
   来源：[src/data/chapter4-755.content.json:2277](../src/data/chapter4-755.content.json#L2277)
663. 时针重新咬合
   来源：[src/data/chapter4-755.content.json:2293](../src/data/chapter4-755.content.json#L2293)
664. 12:25 → 18:50
   来源：[src/data/chapter4-755.content.json:2294](../src/data/chapter4-755.content.json#L2294)
665. 窗外光线转暗，走廊照明逐段亮起，楼内设备留下新的运行声。
   来源：[src/data/chapter4-755.content.json:2295](../src/data/chapter4-755.content.json#L2295)
666. 定位片完成校正
   来源：[src/data/chapter4-755.content.json:2311](../src/data/chapter4-755.content.json#L2311)
667. 18:50 → 22:45
   来源：[src/data/chapter4-755.content.json:2312](../src/data/chapter4-755.content.json#L2312)
668. 照明切换为夜间亮度，地面出现尚未干透的轮印和油光。
   来源：[src/data/chapter4-755.content.json:2313](../src/data/chapter4-755.content.json#L2313)
669. 校准发生偏移
   来源：[src/data/chapter4-755.content.json:2329](../src/data/chapter4-755.content.json#L2329)
670. 22:45 → 07:54
   来源：[src/data/chapter4-755.content.json:2330](../src/data/chapter4-755.content.json#L2330)
671. 整层照明熄灭，签到纸从表盘边缘卷离，分针停在下一格之前。
   来源：[src/data/chapter4-755.content.json:2331](../src/data/chapter4-755.content.json#L2331)
672. 最后一分钟归位
   来源：[src/data/chapter4-755.content.json:2377](../src/data/chapter4-755.content.json#L2377)
673. 07:54 → 07:55
   来源：[src/data/chapter4-755.content.json:2378](../src/data/chapter4-755.content.json#L2378)
674. 旧钟分针向前扣合一格，手机状态栏随即更新为相同读数。
   来源：[src/data/chapter4-755.content.json:2379](../src/data/chapter4-755.content.json#L2379)
675. 学习天地资料索引帖
   来源：[src/data/chapter4-cc98.content.json:3](../src/data/chapter4-cc98.content.json#L3)
676. 学习天地
   来源：[src/data/chapter4-cc98.content.json:4](../src/data/chapter4-cc98.content.json#L4)
677. 课程资料整理员
   来源：[src/data/chapter4-cc98.content.json:7](../src/data/chapter4-cc98.content.json#L7)
678. 学习天地资料索引帖，课程和年份入口已补齐
   来源：[src/data/chapter4-cc98.content.json:10](../src/data/chapter4-cc98.content.json#L10)
679. 26-07-10 22:18
   来源：[src/data/chapter4-cc98.content.json:11](../src/data/chapter4-cc98.content.json#L11)
680. 把学习天地里散着的课程资料重新挂了一遍。点课程名先选年份，再看对应目录和旧自习讨论。段永平教学楼 A2 的房间情况与东西侧路线请到现场核对，CC98 只提供资料入口，麦斯威夜间自习群的即时消息仍要单独查看。
   来源：[src/data/chapter4-cc98.content.json:12](../src/data/chapter4-cc98.content.json#L12)
681. 旧自习讨论
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
682. 课程资料
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
683. 年份入口
   来源：[src/data/chapter4-cc98.content.json:13](../src/data/chapter4-cc98.content.json#L13)
684. 高数周三晚
   来源：[src/data/chapter4-cc98.content.json:18](../src/data/chapter4-cc98.content.json#L18)
685. 22:21
   来源：[src/data/chapter4-cc98.content.json:19](../src/data/chapter4-cc98.content.json#L19)
686. 2楼
   来源：[src/data/chapter4-cc98.content.json:20](../src/data/chapter4-cc98.content.json#L20)
687. 课程
   来源：[src/data/chapter4-cc98.content.json:21](../src/data/chapter4-cc98.content.json#L21)
688. 我按 2023 秋季高数点进去，先看到讲义，再看到自习室讨论。旧帖里的日期要自己看清，别把去年的开门时间当今晚用。
   来源：[src/data/chapter4-cc98.content.json:22](../src/data/chapter4-cc98.content.json#L22)
689. 打印室常客
   来源：[src/data/chapter4-cc98.content.json:26](../src/data/chapter4-cc98.content.json#L26)
690. 22:24
   来源：[src/data/chapter4-cc98.content.json:27](../src/data/chapter4-cc98.content.json#L27)
691. 3楼
   来源：[src/data/chapter4-cc98.content.json:28](../src/data/chapter4-cc98.content.json#L28)
692. 打印
   来源：[src/data/chapter4-cc98.content.json:29](../src/data/chapter4-cc98.content.json#L29)
693. 课程名搜不全时可以只输两个字。我刚从西区打印室回来，按年份找到的文件比首页推荐的少一堆，下载前先看页数。
   来源：[src/data/chapter4-cc98.content.json:30](../src/data/chapter4-cc98.content.json#L30)
694. 麦斯威靠窗位
   来源：[src/data/chapter4-cc98.content.json:34](../src/data/chapter4-cc98.content.json#L34)
695. 22:27
   来源：[src/data/chapter4-cc98.content.json:35](../src/data/chapter4-cc98.content.json#L35)
696. 4楼
   来源：[src/data/chapter4-cc98.content.json:36](../src/data/chapter4-cc98.content.json#L36)
697. 自习
   来源：[src/data/chapter4-cc98.content.json:37](../src/data/chapter4-cc98.content.json#L37)
698. 旧自习讨论里有人记过插座和座位，但每天的空位都不一样。今晚我 21:50 到麦斯威，靠窗第三张桌已经有人了。
   来源：[src/data/chapter4-cc98.content.json:38](../src/data/chapter4-cc98.content.json#L38)
699. 资料夹分层
   来源：[src/data/chapter4-cc98.content.json:42](../src/data/chapter4-cc98.content.json#L42)
700. 22:30
   来源：[src/data/chapter4-cc98.content.json:43](../src/data/chapter4-cc98.content.json#L43)
701. 5楼
   来源：[src/data/chapter4-cc98.content.json:44](../src/data/chapter4-cc98.content.json#L44)
702. 整理
   来源：[src/data/chapter4-cc98.content.json:45](../src/data/chapter4-cc98.content.json#L45)
703. 年份入口按课程分开看比较省事。我把 2022 和 2024 的资料放进两个文件夹，旧讨论单独留着，方便对照当时的说法。
   来源：[src/data/chapter4-cc98.content.json:46](../src/data/chapter4-cc98.content.json#L46)
704. A2 晚课生
   来源：[src/data/chapter4-cc98.content.json:50](../src/data/chapter4-cc98.content.json#L50)
705. 22:34
   来源：[src/data/chapter4-cc98.content.json:51](../src/data/chapter4-cc98.content.json#L51)
706. 6楼
   来源：[src/data/chapter4-cc98.content.json:52](../src/data/chapter4-cc98.content.json#L52)
707. 现场
   来源：[src/data/chapter4-cc98.content.json:53](../src/data/chapter4-cc98.content.json#L53)
708. A2 里面的房间和走廊晚上会变，帖子里的课程资料只能帮忙认入口。到楼里以后按当晚看到的门牌和通道走，别照旧帖直接抄路线。
   来源：[src/data/chapter4-cc98.content.json:54](../src/data/chapter4-cc98.content.json#L54)
709. 群里等消息
   来源：[src/data/chapter4-cc98.content.json:58](../src/data/chapter4-cc98.content.json#L58)
710. 22:38
   来源：[src/data/chapter4-cc98.content.json:59](../src/data/chapter4-cc98.content.json#L59)
711. 7楼
   来源：[src/data/chapter4-cc98.content.json:60](../src/data/chapter4-cc98.content.json#L60)
712. 提醒
   来源：[src/data/chapter4-cc98.content.json:61](../src/data/chapter4-cc98.content.json#L61)
713. 导入群里以后，课程和年份会留在群文件，现场有人发的新消息还在聊天里。去段永平教学楼核对时，两个地方都看一眼。
   来源：[src/data/chapter4-cc98.content.json:62](../src/data/chapter4-cc98.content.json#L62)
714. 导入到麦斯威夜间自习群
   来源：[src/data/chapter4-cc98.content.json:66](../src/data/chapter4-cc98.content.json#L66)
715. 把课程年份入口和旧自习讨论带进自习群
   来源：[src/data/chapter4-cc98.content.json:67](../src/data/chapter4-cc98.content.json#L67)
716. 已导入学习天地资料索引。课程和年份入口会留在群文件，段永平教学楼 A2 的房间与东西侧路线仍需到现场核验。
   来源：[src/data/chapter4-cc98.content.json:68](../src/data/chapter4-cc98.content.json#L68)
717. 这份学习天地资料索引已经导入麦斯威夜间自习群，群文件不会重复添加。现场消息仍请查看聊天记录。
   来源：[src/data/chapter4-cc98.content.json:69](../src/data/chapter4-cc98.content.json#L69)
718. 当前章节还没到段永平教学楼 A2，暂时不能导入学习天地资料。先完成前面的现场调查，再回来查看。
   来源：[src/data/chapter4-cc98.content.json:70](../src/data/chapter4-cc98.content.json#L70)
719. 完成启真湖段落并进入第四章后，学习天地资料索引才会开放。
   来源：[src/data/chapter4-cc98.content.json:71](../src/data/chapter4-cc98.content.json#L71)
720. 麦斯威夜间自习群
   来源：[src/data/chapter4-cc98.content.json:74](../src/data/chapter4-cc98.content.json#L74)；[src/data/chapter4-wechat.content.json:98](../src/data/chapter4-wechat.content.json#L98)
721. 资料索引已放进群文件。群聊继续接收今晚的现场消息，A2 房间核验与东西侧路线以现场和群聊记录为准。
   来源：[src/data/chapter4-cc98.content.json:75](../src/data/chapter4-cc98.content.json#L75)
722. CC98 的课程、年份入口和旧自习讨论只用于查资料，不能替代微信现场消息。
   来源：[src/data/chapter4-cc98.content.json:76](../src/data/chapter4-cc98.content.json#L76)
723. 打开麦斯威夜间自习群，查看刚导入的资料索引和最新现场消息。
   来源：[src/data/chapter4-cc98.content.json:77](../src/data/chapter4-cc98.content.json#L77)
724. 校时终端
   来源：[src/data/chapter4-clock.content.json:3](../src/data/chapter4-clock.content.json#L3)
725. 本机时间冻结在 07:55:23。B2-04 的签到终端只接受经三路设备共同确认的 08:00:00。
   来源：[src/data/chapter4-clock.content.json:4](../src/data/chapter4-clock.content.json#L4)
726. 档案
   来源：[src/data/chapter4-clock.content.json:6](../src/data/chapter4-clock.content.json#L6)
727. 机芯
   来源：[src/data/chapter4-clock.content.json:7](../src/data/chapter4-clock.content.json#L7)
728. 漂移
   来源：[src/data/chapter4-clock.content.json:8](../src/data/chapter4-clock.content.json#L8)
729. 放行
   来源：[src/data/chapter4-clock.content.json:9](../src/data/chapter4-clock.content.json#L9)
730. 重建签到档案
   来源：[src/data/chapter4-clock.content.json:12](../src/data/chapter4-clock.content.json#L12)
731. B2-04 异常记录
   来源：[src/data/chapter4-clock.content.json:13](../src/data/chapter4-clock.content.json#L13)
732. 先从六条混杂记录中选出互相支持的三条证据，再据此选择目标时刻。缺少证据或选错时刻都会被终端拒绝。
   来源：[src/data/chapter4-clock.content.json:14](../src/data/chapter4-clock.content.json#L14)
733. 门厅残影
   来源：[src/data/chapter4-clock.content.json:16](../src/data/chapter4-clock.content.json#L16)；[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
734. 纸条最后进入 B2-04，门牌没有发生位移。
   来源：[src/data/chapter4-clock.content.json:16](../src/data/chapter4-clock.content.json#L16)
735. 课程调整
   来源：[src/data/chapter4-clock.content.json:17](../src/data/chapter4-clock.content.json#L17)
736. 临时教室开放时间提前到 08:00。
   来源：[src/data/chapter4-clock.content.json:17](../src/data/chapter4-clock.content.json#L17)
737. 签到日志
   来源：[src/data/chapter4-clock.content.json:18](../src/data/chapter4-clock.content.json#L18)
738. B2-04 终端在整点首次接受学生签到。
   来源：[src/data/chapter4-clock.content.json:18](../src/data/chapter4-clock.content.json#L18)
739. 闭馆广播
   来源：[src/data/chapter4-clock.content.json:19](../src/data/chapter4-clock.content.json#L19)
740. 该记录来自基础图书馆，与本楼终端无关。
   来源：[src/data/chapter4-clock.content.json:19](../src/data/chapter4-clock.content.json#L19)
741. 剧场放票
   来源：[src/data/chapter4-clock.content.json:20](../src/data/chapter4-clock.content.json#L20)
742. 手机缓存中的剧场票务时间。
   来源：[src/data/chapter4-clock.content.json:20](../src/data/chapter4-clock.content.json#L20)
743. 0755 是窗口暗号，无法作为教学楼时间。
   来源：[src/data/chapter4-clock.content.json:21](../src/data/chapter4-clock.content.json#L21)
744. 食堂取餐
   来源：[src/data/chapter4-clock.content.json:21](../src/data/chapter4-clock.content.json#L21)
745. 07:55
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
746. 当前停留
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
747. 冻结
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
748. 手机异常
   来源：[src/data/chapter4-clock.content.json:24](../src/data/chapter4-clock.content.json#L24)
749. 08:00
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
750. 签到开放
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
751. 早间
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)
752. B2-04
   来源：[src/data/chapter4-clock.content.json:25](../src/data/chapter4-clock.content.json#L25)；[src/data/chapter4-clock.content.json:51](../src/data/chapter4-clock.content.json#L51)；[src/data/chapter4-clock.content.json:61](../src/data/chapter4-clock.content.json#L61)
753. 08:32
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
754. 剧场
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
755. 票务缓存
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
756. 外部记录
   来源：[src/data/chapter4-clock.content.json:26](../src/data/chapter4-clock.content.json#L26)
757. 22:45
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
758. 闭楼
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
759. 进入时刻
   来源：[src/data/chapter4-clock.content.json:27](../src/data/chapter4-clock.content.json#L27)
760. 锁定双机芯
   来源：[src/data/chapter4-clock.content.json:31](../src/data/chapter4-clock.content.json#L31)
761. 小时轮与分钟轮拥有独立锁扣。先把对应数字调到目标值，再分别锁定；已经锁定的机芯不能继续旋转。
   来源：[src/data/chapter4-clock.content.json:32](../src/data/chapter4-clock.content.json#L32)
762. 小时机芯
   来源：[src/data/chapter4-clock.content.json:34](../src/data/chapter4-clock.content.json#L34)
763. 分钟机芯
   来源：[src/data/chapter4-clock.content.json:35](../src/data/chapter4-clock.content.json#L35)
764. 锁定机芯
   来源：[src/data/chapter4-clock.content.json:36](../src/data/chapter4-clock.content.json#L36)
765. 已锁定
   来源：[src/data/chapter4-clock.content.json:37](../src/data/chapter4-clock.content.json#L37)
766. 爆炸视图
   来源：[src/data/chapter4-clock.content.json:38](../src/data/chapter4-clock.content.json#L38)
767. 装配视图
   来源：[src/data/chapter4-clock.content.json:39](../src/data/chapter4-clock.content.json#L39)
768. 复位视角
   来源：[src/data/chapter4-clock.content.json:40](../src/data/chapter4-clock.content.json#L40)
769. 上下拖动机芯齿轮、滚轮或点按 ± 调节读数,对准 08:00 后锁定对应机芯。
   来源：[src/data/chapter4-clock.content.json:41](../src/data/chapter4-clock.content.json#L41)
770. 目标 08:00
   来源：[src/data/chapter4-clock.content.json:42](../src/data/chapter4-clock.content.json#L42)
771. 消除三路设备漂移
   来源：[src/data/chapter4-clock.content.json:46](../src/data/chapter4-clock.content.json#L46)
772. 校门、电梯和教室终端记录了不同方向的秒差。逐条选择反向修正值，三路归零后才能形成 08:00:00。
   来源：[src/data/chapter4-clock.content.json:47](../src/data/chapter4-clock.content.json#L47)
773. 校门闸机
   来源：[src/data/chapter4-clock.content.json:49](../src/data/chapter4-clock.content.json#L49)
774. 通过三种放行协议
   来源：[src/data/chapter4-clock.content.json:56](../src/data/chapter4-clock.content.json#L56)
775. 三轮拥有不同速度与有效窗口：校门宽窗、主梯窄窗、教室反向扫描。每轮只需命中一次，失败会回到第一轮。
   来源：[src/data/chapter4-clock.content.json:57](../src/data/chapter4-clock.content.json#L57)
776. 宽窗 / 常速
   来源：[src/data/chapter4-clock.content.json:59](../src/data/chapter4-clock.content.json#L59)
777. 校门
   来源：[src/data/chapter4-clock.content.json:59](../src/data/chapter4-clock.content.json#L59)
778. 窄窗 / 加速
   来源：[src/data/chapter4-clock.content.json:60](../src/data/chapter4-clock.content.json#L60)
779. 主梯
   来源：[src/data/chapter4-clock.content.json:60](../src/data/chapter4-clock.content.json#L60)
780. 偏置窗 / 反扫
   来源：[src/data/chapter4-clock.content.json:61](../src/data/chapter4-clock.content.json#L61)
781. 07:55 冻结已解除
   来源：[src/data/chapter4-clock.content.json:65](../src/data/chapter4-clock.content.json#L65)
782. 三路设备同时写入 08:00:00，B2-04 签到终端恢复。
   来源：[src/data/chapter4-clock.content.json:66](../src/data/chapter4-clock.content.json#L66)
783. 校时权限尚未开放
   来源：[src/data/chapter4-clock.content.json:69](../src/data/chapter4-clock.content.json#L69)
784. 先完成教学楼内的十二个时间节点，再回到手机处理 B2-04。
   来源：[src/data/chapter4-clock.content.json:70](../src/data/chapter4-clock.content.json#L70)
785. 档案证据不足，或所选时刻与三条有效记录不一致。
   来源：[src/data/chapter4-clock.content.json:73](../src/data/chapter4-clock.content.json#L73)
786. 当前机芯或漂移修正仍未满足这一关的条件。
   来源：[src/data/chapter4-clock.content.json:74](../src/data/chapter4-clock.content.json#L74)
787. 本轮放行失败，协议进度已回到校门。
   来源：[src/data/chapter4-clock.content.json:75](../src/data/chapter4-clock.content.json#L75)
788. 该操作当前不可用，检查本关已经锁定的部分。
   来源：[src/data/chapter4-clock.content.json:76](../src/data/chapter4-clock.content.json#L76)
789. 校时已经完成。
   来源：[src/data/chapter4-clock.content.json:77](../src/data/chapter4-clock.content.json#L77)
790. 三条档案证据成立，08:00 已设为校准目标。
   来源：[src/data/chapter4-clock.content.json:78](../src/data/chapter4-clock.content.json#L78)
791. 双机芯锁定，开始核对三路设备漂移。
   来源：[src/data/chapter4-clock.content.json:79](../src/data/chapter4-clock.content.json#L79)
792. 三路漂移全部归零，进入最终放行。
   来源：[src/data/chapter4-clock.content.json:80](../src/data/chapter4-clock.content.json#L80)
793. 三种协议均已通过，冻结解除。
   来源：[src/data/chapter4-clock.content.json:81](../src/data/chapter4-clock.content.json#L81)
794. 系统：三路设备已归零。等待三种协议放行。
   来源：[src/data/chapter4-clock.content.json:83](../src/data/chapter4-clock.content.json#L83)
795. 玩家：三路记录同时变成了 08:00。
   来源：[src/data/chapter4-clock.content.json:85](../src/data/chapter4-clock.content.json#L85)
796. 系统：校时确认。B2-04 签到终端恢复。
   来源：[src/data/chapter4-clock.content.json:86](../src/data/chapter4-clock.content.json#L86)
797. 玩家：07:55 的冻结解除了。
   来源：[src/data/chapter4-clock.content.json:87](../src/data/chapter4-clock.content.json#L87)
798. 系统：校时完成。07:55 的冻结已解除。
   来源：[src/data/chapter4-clock.content.json:89](../src/data/chapter4-clock.content.json#L89)
799. 完成四关校时
   来源：[src/data/chapter4-clock.content.json:91](../src/data/chapter4-clock.content.json#L91)
800. 筛选三条有效档案，再选择对应时刻。
   来源：[src/data/chapter4-clock.content.json:93](../src/data/chapter4-clock.content.json#L93)
801. 分别校准并锁定小时、分钟两组机芯。
   来源：[src/data/chapter4-clock.content.json:94](../src/data/chapter4-clock.content.json#L94)
802. 为校门、电梯和 B2-04 选择反向漂移修正。
   来源：[src/data/chapter4-clock.content.json:95](../src/data/chapter4-clock.content.json#L95)
803. 依次通过三种速度与窗口不同的放行协议。
   来源：[src/data/chapter4-clock.content.json:96](../src/data/chapter4-clock.content.json#L96)
804. 校时已完成。
   来源：[src/data/chapter4-clock.content.json:97](../src/data/chapter4-clock.content.json#L97)
805. 又断了。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:35](../src/data/chapter4-prologue-voice.audio.content.json#L35)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:69](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L69)
806. It broke again.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:36](../src/data/chapter4-prologue-voice.audio.content.json#L36)
807. 湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:49](../src/data/chapter4-prologue-voice.audio.content.json#L49)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:77](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L77)
808. The lake did not keep it. The night wind carried it into the teaching building that was still lit.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:50](../src/data/chapter4-prologue-voice.audio.content.json#L50)
809. 小心，刚拖过。那张纸往里去了。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:63](../src/data/chapter4-prologue-voice.audio.content.json#L63)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:85](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L85)
810. Careful, I just mopped. That paper went inside.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:64](../src/data/chapter4-prologue-voice.audio.content.json#L64)
811. 同学，北教要清楼了，请收好东西。
   来源：[src/data/chapter4-prologue-voice.audio.content.json:79](../src/data/chapter4-prologue-voice.audio.content.json#L79)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:93](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L93)
812. The North Teaching Building is closing. Please pack up.
   来源：[src/data/chapter4-prologue-voice.audio.content.json:80](../src/data/chapter4-prologue-voice.audio.content.json#L80)
813. 段永平教学楼时间迷宫
   来源：[src/data/chapter4-temporal-maze.content.json:3](../src/data/chapter4-temporal-maze.content.json#L3)
814. 进入一楼门厅，确认湿纸留下的气流轨迹
   来源：[src/data/chapter4-temporal-maze.content.json:5](../src/data/chapter4-temporal-maze.content.json#L5)；[src/data/chapter4-temporal-maze.content.json:120](../src/data/chapter4-temporal-maze.content.json#L120)
815. 深色观察可查看门厅中央的断续水迹。
   来源：[src/data/chapter4-temporal-maze.content.json:6](../src/data/chapter4-temporal-maze.content.json#L6)
816. 恢复纸条进入主电梯厅的风路
   来源：[src/data/chapter4-temporal-maze.content.json:9](../src/data/chapter4-temporal-maze.content.json#L9)；[src/data/chapter4-temporal-maze.content.json:121](../src/data/chapter4-temporal-maze.content.json#L121)
817. 深色观察：地面水迹从玻璃门延伸到迈斯威卷帘门。
   来源：[src/data/chapter4-temporal-maze.content.json:10](../src/data/chapter4-temporal-maze.content.json#L10)
818. 浅色操作：到迈斯威卷帘门前，借助暖风把纸条送向主电梯。
   来源：[src/data/chapter4-temporal-maze.content.json:11](../src/data/chapter4-temporal-maze.content.json#L11)
819. 已记录气流轨迹。浅色操作可在迈斯威卷帘门前恢复风路。
   来源：[src/data/chapter4-temporal-maze.content.json:12](../src/data/chapter4-temporal-maze.content.json#L12)
820. 暖风重新接上水迹，湿纸进入主电梯厅。
   来源：[src/data/chapter4-temporal-maze.content.json:13](../src/data/chapter4-temporal-maze.content.json#L13)
821. 在主电梯厅同步纸条留下的历史轨道
   来源：[src/data/chapter4-temporal-maze.content.json:16](../src/data/chapter4-temporal-maze.content.json#L16)；[src/data/chapter4-temporal-maze.content.json:122](../src/data/chapter4-temporal-maze.content.json#L122)
822. 深色观察：读取轿厢、门体与玩家进入窗口三条历史轨道。
   来源：[src/data/chapter4-temporal-maze.content.json:17](../src/data/chapter4-temporal-maze.content.json#L17)
823. 浅色操作：拖动轿厢轨道，让一楼开门区间完整覆盖六秒进入窗口。
   来源：[src/data/chapter4-temporal-maze.content.json:18](../src/data/chapter4-temporal-maze.content.json#L18)
824. 当前校准动作需要浅色操作；深色观察可独立读取三条历史轨道。
   来源：[src/data/chapter4-temporal-maze.content.json:19](../src/data/chapter4-temporal-maze.content.json#L19)
825. 三轨已经对齐。电梯返回一楼，等待门体完全打开。
   来源：[src/data/chapter4-temporal-maze.content.json:20](../src/data/chapter4-temporal-maze.content.json#L20)
826. 开门区间没有完整覆盖进入窗口。调整重放起点后再试。
   来源：[src/data/chapter4-temporal-maze.content.json:21](../src/data/chapter4-temporal-maze.content.json#L21)
827. 开门窗口已经结束。再次启动历史重放。
   来源：[src/data/chapter4-temporal-maze.content.json:22](../src/data/chapter4-temporal-maze.content.json#L22)
828. 历史片段继续运行，已到达 A2。
   来源：[src/data/chapter4-temporal-maze.content.json:23](../src/data/chapter4-temporal-maze.content.json#L23)
829. 深色观察：记录同一时间片内经过门口和停留区的人员残影。
   来源：[src/data/chapter4-temporal-maze.content.json:51](../src/data/chapter4-temporal-maze.content.json#L51)
830. 三组人员时刻已记录。浅色操作可处理可见隔断。
   来源：[src/data/chapter4-temporal-maze.content.json:52](../src/data/chapter4-temporal-maze.content.json#L52)
831. 浅色操作：依照已记录的空档逐一移动两组可见隔断。
   来源：[src/data/chapter4-temporal-maze.content.json:56](../src/data/chapter4-temporal-maze.content.json#L56)
832. 人员时刻证据尚未完整；两种现实模式的交互入口都保持开放。
   来源：[src/data/chapter4-temporal-maze.content.json:57](../src/data/chapter4-temporal-maze.content.json#L57)
833. 内圈支路已接通，开放学习区现在可达。
   来源：[src/data/chapter4-temporal-maze.content.json:58](../src/data/chapter4-temporal-maze.content.json#L58)
834. 在开放学习区取得两块导视碎片。
   来源：[src/data/chapter4-temporal-maze.content.json:66](../src/data/chapter4-temporal-maze.content.json#L66)
835. 深色观察：读取旧导视残影。
   来源：[src/data/chapter4-temporal-maze.content.json:67](../src/data/chapter4-temporal-maze.content.json#L67)
836. 旧导视残影已记录。浅色操作可重建导视板。
   来源：[src/data/chapter4-temporal-maze.content.json:68](../src/data/chapter4-temporal-maze.content.json#L68)
837. 浅色操作：比较当前导视照片、旧残影与二楼入口方向，自行判断缺失槽位和两块碎片的位置。
   来源：[src/data/chapter4-temporal-maze.content.json:69](../src/data/chapter4-temporal-maze.content.json#L69)
838. 碎片与当前历史记录不一致，重新检查已记录的导视痕迹。
   来源：[src/data/chapter4-temporal-maze.content.json:70](../src/data/chapter4-temporal-maze.content.json#L70)
839. 导视板恢复了一段可验证记录。返回已访问楼层继续取证。
   来源：[src/data/chapter4-temporal-maze.content.json:71](../src/data/chapter4-temporal-maze.content.json#L71)
840. 导视板恢复后，切到深色观察并读取入口开合与人员经过留下的历史痕迹。
   来源：[src/data/chapter4-temporal-maze.content.json:75](../src/data/chapter4-temporal-maze.content.json#L75)
841. 连廊历史已记录，可与导视碎片交叉核对。
   来源：[src/data/chapter4-temporal-maze.content.json:76](../src/data/chapter4-temporal-maze.content.json#L76)
842. 回到已访问区域，检查新出现的取证窗口。
   来源：[src/data/chapter4-temporal-maze.content.json:82](../src/data/chapter4-temporal-maze.content.json#L82)
843. 当前历史窗口尚未形成，继续核对已有证据。
   来源：[src/data/chapter4-temporal-maze.content.json:83](../src/data/chapter4-temporal-maze.content.json#L83)
844. 新的取证窗口已经开放，当前安全位置已保存。
   来源：[src/data/chapter4-temporal-maze.content.json:84](../src/data/chapter4-temporal-maze.content.json#L84)
845. 当前交通核心不能到达该楼层。
   来源：[src/data/chapter4-temporal-maze.content.json:87](../src/data/chapter4-temporal-maze.content.json#L87)
846. 仍缺当前步骤所需的证据。
   来源：[src/data/chapter4-temporal-maze.content.json:88](../src/data/chapter4-temporal-maze.content.json#L88)
847. 切换现实模式后再执行当前动作。
   来源：[src/data/chapter4-temporal-maze.content.json:89](../src/data/chapter4-temporal-maze.content.json#L89)
848. 当前路线条件尚未满足。
   来源：[src/data/chapter4-temporal-maze.content.json:90](../src/data/chapter4-temporal-maze.content.json#L90)
849. 四项外部记录
   来源：[src/data/chapter4-temporal-maze.content.json:99](../src/data/chapter4-temporal-maze.content.json#L99)
850. 大厅旧钟
   来源：[src/data/chapter4-temporal-maze.content.json:100](../src/data/chapter4-temporal-maze.content.json#L100)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7254](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7254)
851. 手机已同步
   来源：[src/data/chapter4-temporal-maze.content.json:103](../src/data/chapter4-temporal-maze.content.json#L103)
852. 手机未同步，当前读数不可信
   来源：[src/data/chapter4-temporal-maze.content.json:104](../src/data/chapter4-temporal-maze.content.json#L104)
853. 完成启真湖逃脱并进入教学楼
   来源：[src/data/chapter4-temporal-maze.content.json:119](../src/data/chapter4-temporal-maze.content.json#L119)
854. 根据夜间人员动线重建纸条路线
   来源：[src/data/chapter4-temporal-maze.content.json:123](../src/data/chapter4-temporal-maze.content.json#L123)
855. 重建二楼走廊等待区
   来源：[src/data/chapter4-temporal-maze.content.json:124](../src/data/chapter4-temporal-maze.content.json#L124)
856. 拼合楼层导视碎片
   来源：[src/data/chapter4-temporal-maze.content.json:125](../src/data/chapter4-temporal-maze.content.json#L125)
857. 确认连廊只位于三楼
   来源：[src/data/chapter4-temporal-maze.content.json:126](../src/data/chapter4-temporal-maze.content.json#L126)
858. 记录下层回声，旋转折返楼梯并接通 B2
   来源：[src/data/chapter4-temporal-maze.content.json:127](../src/data/chapter4-temporal-maze.content.json#L127)
859. 剪合多机位监控记录
   来源：[src/data/chapter4-temporal-maze.content.json:128](../src/data/chapter4-temporal-maze.content.json#L128)
860. 录制可在复位后重放的动作回声
   来源：[src/data/chapter4-temporal-maze.content.json:129](../src/data/chapter4-temporal-maze.content.json#L129)
861. 用两部电梯运输大型签到板
   来源：[src/data/chapter4-temporal-maze.content.json:130](../src/data/chapter4-temporal-maze.content.json#L130)
862. 在迈斯威暖风中控制纸条含水量
   来源：[src/data/chapter4-temporal-maze.content.json:131](../src/data/chapter4-temporal-maze.content.json#L131)
863. 从 23:30 复位点恢复第二循环
   来源：[src/data/chapter4-temporal-maze.content.json:132](../src/data/chapter4-temporal-maze.content.json#L132)
864. 安排第二循环的逆向运输路线
   来源：[src/data/chapter4-temporal-maze.content.json:133](../src/data/chapter4-temporal-maze.content.json#L133)
865. 校准 07:55 相位并打开 B2-04
   来源：[src/data/chapter4-temporal-maze.content.json:134](../src/data/chapter4-temporal-maze.content.json#L134)
866. 读取异常签到记录
   来源：[src/data/chapter4-temporal-maze.content.json:135](../src/data/chapter4-temporal-maze.content.json#L135)
867. preserve\_required\_walkable
   来源：[src/data/chapter4-three-floor-maze.layout.json:46](../src/data/chapter4-three-floor-maze.layout.json#L46)
868. preserve\_report\_hall\_doorway\_and\_east\_wall
   来源：[src/data/chapter4-three-floor-maze.layout.json:62](../src/data/chapter4-three-floor-maze.layout.json#L62)
869. exclude\_two\_visible\_stair\_rails\_while\_preserving\_connected\_passages
   来源：[src/data/chapter4-three-floor-maze.layout.json:80](../src/data/chapter4-three-floor-maze.layout.json#L80)
870. 空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2145](../src/data/chapter4-three-floor-maze.layout.json#L2145)；[src/data/chapter4-three-floor-maze.layout.json:2154](../src/data/chapter4-three-floor-maze.layout.json#L2154)；[src/data/chapter4-three-floor-maze.layout.json:2172](../src/data/chapter4-three-floor-maze.layout.json#L2172)；[src/data/chapter4-three-floor-maze.layout.json:2181](../src/data/chapter4-three-floor-maze.layout.json#L2181)；[src/data/chapter4-three-floor-maze.layout.json:2190](../src/data/chapter4-three-floor-maze.layout.json#L2190)；[src/data/chapter4-three-floor-maze.layout.json:2199](../src/data/chapter4-three-floor-maze.layout.json#L2199)；[src/data/chapter4-three-floor-maze.layout.json:2208](../src/data/chapter4-three-floor-maze.layout.json#L2208)；[src/data/chapter4-three-floor-maze.layout.json:2217](../src/data/chapter4-three-floor-maze.layout.json#L2217)；[src/data/chapter4-three-floor-maze.layout.json:2226](../src/data/chapter4-three-floor-maze.layout.json#L2226)；[src/data/chapter4-three-floor-maze.layout.json:2235](../src/data/chapter4-three-floor-maze.layout.json#L2235)；[src/data/chapter4-three-floor-maze.layout.json:2974](../src/data/chapter4-three-floor-maze.layout.json#L2974)；[src/data/chapter4-three-floor-maze.layout.json:2983](../src/data/chapter4-three-floor-maze.layout.json#L2983)；[src/data/chapter4-three-floor-maze.layout.json:2992](../src/data/chapter4-three-floor-maze.layout.json#L2992)；[src/data/chapter4-three-floor-maze.layout.json:3007](../src/data/chapter4-three-floor-maze.layout.json#L3007)；[src/data/chapter4-three-floor-maze.layout.json:3016](../src/data/chapter4-three-floor-maze.layout.json#L3016)；[src/data/chapter4-three-floor-maze.layout.json:3025](../src/data/chapter4-three-floor-maze.layout.json#L3025)；[src/data/chapter4-three-floor-maze.layout.json:3034](../src/data/chapter4-three-floor-maze.layout.json#L3034)；[src/data/chapter4-three-floor-maze.layout.json:3043](../src/data/chapter4-three-floor-maze.layout.json#L3043)；[src/data/chapter4-three-floor-maze.layout.json:3052](../src/data/chapter4-three-floor-maze.layout.json#L3052)；[src/data/chapter4-three-floor-maze.layout.json:3067](../src/data/chapter4-three-floor-maze.layout.json#L3067)；[src/data/chapter4-three-floor-maze.layout.json:3076](../src/data/chapter4-three-floor-maze.layout.json#L3076)；[src/data/chapter4-three-floor-maze.layout.json:3099](../src/data/chapter4-three-floor-maze.layout.json#L3099)；[src/data/chapter4-three-floor-maze.layout.json:3114](../src/data/chapter4-three-floor-maze.layout.json#L3114)；[src/data/chapter4-three-floor-maze.layout.json:3129](../src/data/chapter4-three-floor-maze.layout.json#L3129)；[src/data/chapter4-three-floor-maze.layout.json:3138](../src/data/chapter4-three-floor-maze.layout.json#L3138)；[src/data/chapter4-three-floor-maze.layout.json:3147](../src/data/chapter4-three-floor-maze.layout.json#L3147)；[src/data/chapter4-three-floor-maze.layout.json:3156](../src/data/chapter4-three-floor-maze.layout.json#L3156)；[src/data/chapter4-three-floor-maze.layout.json:3165](../src/data/chapter4-three-floor-maze.layout.json#L3165)；[src/data/chapter4-three-floor-maze.layout.json:3174](../src/data/chapter4-three-floor-maze.layout.json#L3174)；[src/data/chapter4-three-floor-maze.layout.json:3183](../src/data/chapter4-three-floor-maze.layout.json#L3183)；[src/data/chapter4-three-floor-maze.layout.json:3192](../src/data/chapter4-three-floor-maze.layout.json#L3192)；[src/data/chapter4-three-floor-maze.layout.json:3201](../src/data/chapter4-three-floor-maze.layout.json#L3201)；[src/data/chapter4-three-floor-maze.layout.json:3210](../src/data/chapter4-three-floor-maze.layout.json#L3210)；[src/data/chapter4-three-floor-maze.layout.json:3588](../src/data/chapter4-three-floor-maze.layout.json#L3588)；[src/data/chapter4-three-floor-maze.layout.json:3597](../src/data/chapter4-three-floor-maze.layout.json#L3597)；[src/data/chapter4-three-floor-maze.layout.json:3606](../src/data/chapter4-three-floor-maze.layout.json#L3606)；[src/data/chapter4-three-floor-maze.layout.json:3624](../src/data/chapter4-three-floor-maze.layout.json#L3624)；[src/data/chapter4-three-floor-maze.layout.json:3633](../src/data/chapter4-three-floor-maze.layout.json#L3633)；[src/data/chapter4-three-floor-maze.layout.json:3642](../src/data/chapter4-three-floor-maze.layout.json#L3642)；[src/data/chapter4-three-floor-maze.layout.json:3651](../src/data/chapter4-three-floor-maze.layout.json#L3651)；[src/data/chapter4-three-floor-maze.layout.json:3660](../src/data/chapter4-three-floor-maze.layout.json#L3660)；[src/data/chapter4-three-floor-maze.layout.json:3669](../src/data/chapter4-three-floor-maze.layout.json#L3669)；[src/data/chapter4-three-floor-maze.layout.json:3678](../src/data/chapter4-three-floor-maze.layout.json#L3678)；[src/data/chapter4-three-floor-maze.layout.json:3687](../src/data/chapter4-three-floor-maze.layout.json#L3687)；[src/data/chapter4-three-floor-maze.layout.json:3696](../src/data/chapter4-three-floor-maze.layout.json#L3696)；[src/data/chapter4-three-floor-maze.layout.json:3711](../src/data/chapter4-three-floor-maze.layout.json#L3711)
871. 104/105 隔墙实体底边
   来源：[src/data/chapter4-three-floor-maze.layout.json:2163](../src/data/chapter4-three-floor-maze.layout.json#L2163)
872. 面包坊北墙实体底边
   来源：[src/data/chapter4-three-floor-maze.layout.json:2244](../src/data/chapter4-three-floor-maze.layout.json#L2244)
873. 104 北墙实体底边
   来源：[src/data/chapter4-three-floor-maze.layout.json:2253](../src/data/chapter4-three-floor-maze.layout.json#L2253)
874. 前台柜台空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2262](../src/data/chapter4-three-floor-maze.layout.json#L2262)
875. 面包坊柜台空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2271](../src/data/chapter4-three-floor-maze.layout.json#L2271)
876. 104 教室讲台桌前沿空气墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:2280](../src/data/chapter4-three-floor-maze.layout.json#L2280)
877. 前台左侧座椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2289](../src/data/chapter4-three-floor-maze.layout.json#L2289)
878. 前台右侧座椅与盆栽阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2298](../src/data/chapter4-three-floor-maze.layout.json#L2298)
879. 主楼梯右侧边缘阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2307](../src/data/chapter4-three-floor-maze.layout.json#L2307)；[src/data/chapter4-three-floor-maze.layout.json:3870](../src/data/chapter4-three-floor-maze.layout.json#L3870)
880. 主楼梯左侧边缘阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2316](../src/data/chapter4-three-floor-maze.layout.json#L2316)；[src/data/chapter4-three-floor-maze.layout.json:3861](../src/data/chapter4-three-floor-maze.layout.json#L3861)
881. 104 教室第一排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2325](../src/data/chapter4-three-floor-maze.layout.json#L2325)
882. 104 教室第一排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2334](../src/data/chapter4-three-floor-maze.layout.json#L2334)
883. 104 教室第一排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2343](../src/data/chapter4-three-floor-maze.layout.json#L2343)
884. 104 教室第一排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2352](../src/data/chapter4-three-floor-maze.layout.json#L2352)
885. 104 教室第二排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2361](../src/data/chapter4-three-floor-maze.layout.json#L2361)
886. 104 教室第二排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2370](../src/data/chapter4-three-floor-maze.layout.json#L2370)
887. 104 教室第二排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2379](../src/data/chapter4-three-floor-maze.layout.json#L2379)
888. 104 教室第二排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2388](../src/data/chapter4-three-floor-maze.layout.json#L2388)
889. 104 教室第三排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2397](../src/data/chapter4-three-floor-maze.layout.json#L2397)
890. 104 教室第三排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2406](../src/data/chapter4-three-floor-maze.layout.json#L2406)
891. 104 教室第三排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2415](../src/data/chapter4-three-floor-maze.layout.json#L2415)
892. 104 教室第三排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2424](../src/data/chapter4-three-floor-maze.layout.json#L2424)
893. 105 教室第一排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2433](../src/data/chapter4-three-floor-maze.layout.json#L2433)
894. 105 教室第一排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2442](../src/data/chapter4-three-floor-maze.layout.json#L2442)
895. 105 教室第一排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2451](../src/data/chapter4-three-floor-maze.layout.json#L2451)
896. 105 教室第一排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2460](../src/data/chapter4-three-floor-maze.layout.json#L2460)
897. 105 教室第二排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2469](../src/data/chapter4-three-floor-maze.layout.json#L2469)
898. 105 教室第二排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2478](../src/data/chapter4-three-floor-maze.layout.json#L2478)
899. 105 教室第二排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2487](../src/data/chapter4-three-floor-maze.layout.json#L2487)
900. 105 教室第二排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2496](../src/data/chapter4-three-floor-maze.layout.json#L2496)
901. 105 教室第三排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2505](../src/data/chapter4-three-floor-maze.layout.json#L2505)
902. 105 教室第三排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2514](../src/data/chapter4-three-floor-maze.layout.json#L2514)
903. 105 教室第三排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2523](../src/data/chapter4-three-floor-maze.layout.json#L2523)
904. 105 教室第三排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2532](../src/data/chapter4-three-floor-maze.layout.json#L2532)
905. 面包坊门洞
   来源：[src/data/chapter4-three-floor-maze.layout.json:2543](../src/data/chapter4-three-floor-maze.layout.json#L2543)
906. 必须可通行
   来源：[src/data/chapter4-three-floor-maze.layout.json:2553](../src/data/chapter4-three-floor-maze.layout.json#L2553)；[src/data/chapter4-three-floor-maze.layout.json:2563](../src/data/chapter4-three-floor-maze.layout.json#L2563)；[src/data/chapter4-three-floor-maze.layout.json:2573](../src/data/chapter4-three-floor-maze.layout.json#L2573)；[src/data/chapter4-three-floor-maze.layout.json:2583](../src/data/chapter4-three-floor-maze.layout.json#L2583)；[src/data/chapter4-three-floor-maze.layout.json:2593](../src/data/chapter4-three-floor-maze.layout.json#L2593)；[src/data/chapter4-three-floor-maze.layout.json:2603](../src/data/chapter4-three-floor-maze.layout.json#L2603)；[src/data/chapter4-three-floor-maze.layout.json:3221](../src/data/chapter4-three-floor-maze.layout.json#L3221)；[src/data/chapter4-three-floor-maze.layout.json:3231](../src/data/chapter4-three-floor-maze.layout.json#L3231)；[src/data/chapter4-three-floor-maze.layout.json:3241](../src/data/chapter4-three-floor-maze.layout.json#L3241)；[src/data/chapter4-three-floor-maze.layout.json:3251](../src/data/chapter4-three-floor-maze.layout.json#L3251)；[src/data/chapter4-three-floor-maze.layout.json:3261](../src/data/chapter4-three-floor-maze.layout.json#L3261)；[src/data/chapter4-three-floor-maze.layout.json:4160](../src/data/chapter4-three-floor-maze.layout.json#L4160)；[src/data/chapter4-three-floor-maze.layout.json:4170](../src/data/chapter4-three-floor-maze.layout.json#L4170)；[src/data/chapter4-three-floor-maze.layout.json:4210](../src/data/chapter4-three-floor-maze.layout.json#L4210)；[src/data/chapter4-three-floor-maze.layout.json:4220](../src/data/chapter4-three-floor-maze.layout.json#L4220)；[src/data/chapter4-three-floor-maze.layout.json:4230](../src/data/chapter4-three-floor-maze.layout.json#L4230)
907. 前景遮挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:2615](../src/data/chapter4-three-floor-maze.layout.json#L2615)；[src/data/chapter4-three-floor-maze.layout.json:2629](../src/data/chapter4-three-floor-maze.layout.json#L2629)；[src/data/chapter4-three-floor-maze.layout.json:2652](../src/data/chapter4-three-floor-maze.layout.json#L2652)；[src/data/chapter4-three-floor-maze.layout.json:2665](../src/data/chapter4-three-floor-maze.layout.json#L2665)；[src/data/chapter4-three-floor-maze.layout.json:2678](../src/data/chapter4-three-floor-maze.layout.json#L2678)；[src/data/chapter4-three-floor-maze.layout.json:2691](../src/data/chapter4-three-floor-maze.layout.json#L2691)；[src/data/chapter4-three-floor-maze.layout.json:2704](../src/data/chapter4-three-floor-maze.layout.json#L2704)；[src/data/chapter4-three-floor-maze.layout.json:3273](../src/data/chapter4-three-floor-maze.layout.json#L3273)；[src/data/chapter4-three-floor-maze.layout.json:3286](../src/data/chapter4-three-floor-maze.layout.json#L3286)；[src/data/chapter4-three-floor-maze.layout.json:3299](../src/data/chapter4-three-floor-maze.layout.json#L3299)；[src/data/chapter4-three-floor-maze.layout.json:3312](../src/data/chapter4-three-floor-maze.layout.json#L3312)；[src/data/chapter4-three-floor-maze.layout.json:3325](../src/data/chapter4-three-floor-maze.layout.json#L3325)；[src/data/chapter4-three-floor-maze.layout.json:3338](../src/data/chapter4-three-floor-maze.layout.json#L3338)；[src/data/chapter4-three-floor-maze.layout.json:4242](../src/data/chapter4-three-floor-maze.layout.json#L4242)；[src/data/chapter4-three-floor-maze.layout.json:4255](../src/data/chapter4-three-floor-maze.layout.json#L4255)
908. 104/105 隔墙局部人物淡化
   来源：[src/data/chapter4-three-floor-maze.layout.json:2643](../src/data/chapter4-three-floor-maze.layout.json#L2643)
909. 北侧西段肖像墙前景
   来源：[src/data/chapter4-three-floor-maze.layout.json:2717](../src/data/chapter4-three-floor-maze.layout.json#L2717)
910. 北侧东段肖像墙前景
   来源：[src/data/chapter4-three-floor-maze.layout.json:2731](../src/data/chapter4-three-floor-maze.layout.json#L2731)
911. 麦思威面包坊餐厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2746](../src/data/chapter4-three-floor-maze.layout.json#L2746)
912. 一楼校友头像长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:2756](../src/data/chapter4-three-floor-maze.layout.json#L2756)
913. 104 教室门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2766](../src/data/chapter4-three-floor-maze.layout.json#L2766)
914. 105 教室门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:2776](../src/data/chapter4-three-floor-maze.layout.json#L2776)
915. 104 黑板擦痕残留
   来源：[src/data/chapter4-three-floor-maze.layout.json:2786](../src/data/chapter4-three-floor-maze.layout.json#L2786)
916. 105 讲台回放终端
   来源：[src/data/chapter4-three-floor-maze.layout.json:2796](../src/data/chapter4-three-floor-maze.layout.json#L2796)
917. 一楼前台值班助理
   来源：[src/data/chapter4-three-floor-maze.layout.json:2806](../src/data/chapter4-three-floor-maze.layout.json#L2806)
918. 一楼前台值班签到板
   来源：[src/data/chapter4-three-floor-maze.layout.json:2816](../src/data/chapter4-three-floor-maze.layout.json#L2816)
919. 教学楼主入口
   来源：[src/data/chapter4-three-floor-maze.layout.json:2826](../src/data/chapter4-three-floor-maze.layout.json#L2826)
920. 公告栏前的签到记录纸条
   来源：[src/data/chapter4-three-floor-maze.layout.json:2836](../src/data/chapter4-three-floor-maze.layout.json#L2836)
921. 一楼旧钟
   来源：[src/data/chapter4-three-floor-maze.layout.json:2846](../src/data/chapter4-three-floor-maze.layout.json#L2846)
922. 旧钟时针插槽
   来源：[src/data/chapter4-three-floor-maze.layout.json:2856](../src/data/chapter4-three-floor-maze.layout.json#L2856)；[src/scenes/rpg/RpgInteractionContract.ts:618](../src/scenes/rpg/RpgInteractionContract.ts#L618)
923. 旧钟定位盘插槽
   来源：[src/data/chapter4-three-floor-maze.layout.json:2866](../src/data/chapter4-three-floor-maze.layout.json#L2866)
924. 旧钟齿轮
   来源：[src/data/chapter4-three-floor-maze.layout.json:2876](../src/data/chapter4-three-floor-maze.layout.json#L2876)；[src/scenes/rpg/RpgInteractionContract.ts:891](../src/scenes/rpg/RpgInteractionContract.ts#L891)
925. 大厅旧钟表盘
   来源：[src/data/chapter4-three-floor-maze.layout.json:2886](../src/data/chapter4-three-floor-maze.layout.json#L2886)；[src/scenes/rpg/RpgInteractionContract.ts:902](../src/scenes/rpg/RpgInteractionContract.ts#L902)；[src/scenes/rpg/RpgItemUseGuidance.ts:85](../src/scenes/rpg/RpgItemUseGuidance.ts#L85)
926. 一楼配电面板
   来源：[src/data/chapter4-three-floor-maze.layout.json:2896](../src/data/chapter4-three-floor-maze.layout.json#L2896)；[src/scenes/rpg/RpgInteractionContract.ts:926](../src/scenes/rpg/RpgInteractionContract.ts#L926)
927. 202 教室黑板下沿脚部通行边界
   来源：[src/data/chapter4-three-floor-maze.layout.json:3085](../src/data/chapter4-three-floor-maze.layout.json#L3085)
928. 201 创客工坊
   来源：[src/data/chapter4-three-floor-maze.layout.json:3352](../src/data/chapter4-three-floor-maze.layout.json#L3352)
929. 201 定位板校准夹具
   来源：[src/data/chapter4-three-floor-maze.layout.json:3362](../src/data/chapter4-three-floor-maze.layout.json#L3362)
930. 204 研讨教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:3372](../src/data/chapter4-three-floor-maze.layout.json#L3372)
931. 202 阶梯教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:3382](../src/data/chapter4-three-floor-maze.layout.json#L3382)
932. 203 计算机教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:3392](../src/data/chapter4-three-floor-maze.layout.json#L3392)
933. 203 五区拓扑终端
   来源：[src/data/chapter4-three-floor-maze.layout.json:3402](../src/data/chapter4-three-floor-maze.layout.json#L3402)
934. 二楼开放学习区
   来源：[src/data/chapter4-three-floor-maze.layout.json:3412](../src/data/chapter4-three-floor-maze.layout.json#L3412)
935. 202 至主楼梯疏散路线板
   来源：[src/data/chapter4-three-floor-maze.layout.json:3422](../src/data/chapter4-three-floor-maze.layout.json#L3422)
936. 二楼校友纪念长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:3432](../src/data/chapter4-three-floor-maze.layout.json#L3432)
937. 二楼电梯口值班安全员
   来源：[src/data/chapter4-three-floor-maze.layout.json:3442](../src/data/chapter4-three-floor-maze.layout.json#L3442)
938. 204 教室残影组
   来源：[src/data/chapter4-three-floor-maze.layout.json:3452](../src/data/chapter4-three-floor-maze.layout.json#L3452)
939. 204 讲台抽屉里的定位盘
   来源：[src/data/chapter4-three-floor-maze.layout.json:3462](../src/data/chapter4-three-floor-maze.layout.json#L3462)
940. 进入 202 并关门
   来源：[src/data/chapter4-three-floor-maze.layout.json:3472](../src/data/chapter4-three-floor-maze.layout.json#L3472)；[src/scenes/rpg/RpgInteractionContract.ts:941](../src/scenes/rpg/RpgInteractionContract.ts#L941)
941. 202 阶梯座椅间的黄铜分针组件
   来源：[src/data/chapter4-three-floor-maze.layout.json:3482](../src/data/chapter4-three-floor-maze.layout.json#L3482)；[src/scenes/rpg/RpgInteractionContract.ts:953](../src/scenes/rpg/RpgInteractionContract.ts#L953)
942. 301 档案展北墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3579](../src/data/chapter4-three-floor-maze.layout.json#L3579)
943. 302 媒体工作室西墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3615](../src/data/chapter4-three-floor-maze.layout.json#L3615)
944. 校友荣誉门厅南墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3726](../src/data/chapter4-three-floor-maze.layout.json#L3726)
945. 304 报告厅北墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3735](../src/data/chapter4-three-floor-maze.layout.json#L3735)
946. 304 报告厅西墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3744](../src/data/chapter4-three-floor-maze.layout.json#L3744)
947. 304 报告厅南墙西段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3753](../src/data/chapter4-three-floor-maze.layout.json#L3753)
948. 304 报告厅南墙东段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3762](../src/data/chapter4-three-floor-maze.layout.json#L3762)
949. 304 报告厅东墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3771](../src/data/chapter4-three-floor-maze.layout.json#L3771)
950. 303 智慧教室北墙西段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3780](../src/data/chapter4-three-floor-maze.layout.json#L3780)
951. 303 智慧教室北墙东段
   来源：[src/data/chapter4-three-floor-maze.layout.json:3789](../src/data/chapter4-three-floor-maze.layout.json#L3789)
952. 303 智慧教室西墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3798](../src/data/chapter4-three-floor-maze.layout.json#L3798)
953. 303 智慧教室东墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3807](../src/data/chapter4-three-floor-maze.layout.json#L3807)
954. A3 建筑南侧外墙
   来源：[src/data/chapter4-three-floor-maze.layout.json:3816](../src/data/chapter4-three-floor-maze.layout.json#L3816)
955. 301 北侧第三组校史展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3825](../src/data/chapter4-three-floor-maze.layout.json#L3825)
956. 301 中央档案展台阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3834](../src/data/chapter4-three-floor-maze.layout.json#L3834)
957. 301 南侧左组展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3843](../src/data/chapter4-three-floor-maze.layout.json#L3843)
958. 301 南侧右组展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3852](../src/data/chapter4-three-floor-maze.layout.json#L3852)
959. 304 报告厅左侧座席阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3879](../src/data/chapter4-three-floor-maze.layout.json#L3879)
960. 304 报告厅右侧座席阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3888](../src/data/chapter4-three-floor-maze.layout.json#L3888)
961. 301 北侧第一组校史展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3897](../src/data/chapter4-three-floor-maze.layout.json#L3897)
962. 303 教室第一排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3906](../src/data/chapter4-three-floor-maze.layout.json#L3906)
963. 303 教室第一排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3915](../src/data/chapter4-three-floor-maze.layout.json#L3915)
964. 303 教室第一排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3924](../src/data/chapter4-three-floor-maze.layout.json#L3924)
965. 303 教室第二排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3933](../src/data/chapter4-three-floor-maze.layout.json#L3933)
966. 303 教室第二排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3942](../src/data/chapter4-three-floor-maze.layout.json#L3942)
967. 303 教室第二排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3951](../src/data/chapter4-three-floor-maze.layout.json#L3951)
968. 303 教室第一排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3960](../src/data/chapter4-three-floor-maze.layout.json#L3960)
969. 303 教室第一排第五组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3969](../src/data/chapter4-three-floor-maze.layout.json#L3969)
970. 303 教室第一排第六组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3978](../src/data/chapter4-three-floor-maze.layout.json#L3978)
971. 303 教室第二排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3987](../src/data/chapter4-three-floor-maze.layout.json#L3987)
972. 303 教室第二排第五组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:3996](../src/data/chapter4-three-floor-maze.layout.json#L3996)
973. 303 教室第二排第六组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4005](../src/data/chapter4-three-floor-maze.layout.json#L4005)
974. 301 北侧第二组校史展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4014](../src/data/chapter4-three-floor-maze.layout.json#L4014)
975. 303 教室第三排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4023](../src/data/chapter4-three-floor-maze.layout.json#L4023)
976. 303 教室第三排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4032](../src/data/chapter4-three-floor-maze.layout.json#L4032)
977. 303 教室第三排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4041](../src/data/chapter4-three-floor-maze.layout.json#L4041)
978. 303 教室第三排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4050](../src/data/chapter4-three-floor-maze.layout.json#L4050)
979. 303 教室第三排第五组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4059](../src/data/chapter4-three-floor-maze.layout.json#L4059)
980. 303 教室第三排第六组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4068](../src/data/chapter4-three-floor-maze.layout.json#L4068)
981. 303 教室第四排第一组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4077](../src/data/chapter4-three-floor-maze.layout.json#L4077)
982. 303 教室第四排第二组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4086](../src/data/chapter4-three-floor-maze.layout.json#L4086)
983. 303 教室第四排第三组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4095](../src/data/chapter4-three-floor-maze.layout.json#L4095)
984. 303 教室第四排第四组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4104](../src/data/chapter4-three-floor-maze.layout.json#L4104)
985. 303 教室第四排第六组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4113](../src/data/chapter4-three-floor-maze.layout.json#L4113)
986. 303 教室第四排第五组桌椅阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4122](../src/data/chapter4-three-floor-maze.layout.json#L4122)
987. 校史人物门厅右侧展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4131](../src/data/chapter4-three-floor-maze.layout.json#L4131)
988. 校史人物门厅左侧展柜阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4140](../src/data/chapter4-three-floor-maze.layout.json#L4140)
989. 304 报告厅讲台阻挡
   来源：[src/data/chapter4-three-floor-maze.layout.json:4149](../src/data/chapter4-three-floor-maze.layout.json#L4149)
990. 电梯出口平台必须可通行
   来源：[src/data/chapter4-three-floor-maze.layout.json:4180](../src/data/chapter4-three-floor-maze.layout.json#L4180)
991. 主楼梯中央踏步必须可通行
   来源：[src/data/chapter4-three-floor-maze.layout.json:4190](../src/data/chapter4-three-floor-maze.layout.json#L4190)
992. 楼梯栏杆下沿连接区必须可通行
   来源：[src/data/chapter4-three-floor-maze.layout.json:4200](../src/data/chapter4-three-floor-maze.layout.json#L4200)
993. 301 校史档案展
   来源：[src/data/chapter4-three-floor-maze.layout.json:4269](../src/data/chapter4-three-floor-maze.layout.json#L4269)
994. 301 胶片索引抽屉
   来源：[src/data/chapter4-three-floor-maze.layout.json:4279](../src/data/chapter4-three-floor-maze.layout.json#L4279)
995. 302 媒体工作室
   来源：[src/data/chapter4-three-floor-maze.layout.json:4289](../src/data/chapter4-three-floor-maze.layout.json#L4289)
996. 302 新旧影像对齐扫描台
   来源：[src/data/chapter4-three-floor-maze.layout.json:4299](../src/data/chapter4-three-floor-maze.layout.json#L4299)
997. 304 报告厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:4309](../src/data/chapter4-three-floor-maze.layout.json#L4309)
998. 303 智慧教室
   来源：[src/data/chapter4-three-floor-maze.layout.json:4319](../src/data/chapter4-three-floor-maze.layout.json#L4319)
999. 三楼校史人物荣誉门厅
   来源：[src/data/chapter4-three-floor-maze.layout.json:4329](../src/data/chapter4-three-floor-maze.layout.json#L4329)
1000. 校史人物·苏步青
   来源：[src/data/chapter4-three-floor-maze.layout.json:4339](../src/data/chapter4-three-floor-maze.layout.json#L4339)
1001. 校史人物·竺可桢
   来源：[src/data/chapter4-three-floor-maze.layout.json:4349](../src/data/chapter4-three-floor-maze.layout.json#L4349)
1002. 校史人物·路甬祥
   来源：[src/data/chapter4-three-floor-maze.layout.json:4359](../src/data/chapter4-three-floor-maze.layout.json#L4359)
1003. 校史人物·陈建功
   来源：[src/data/chapter4-three-floor-maze.layout.json:4369](../src/data/chapter4-three-floor-maze.layout.json#L4369)
1004. 校史人物·谈家桢
   来源：[src/data/chapter4-three-floor-maze.layout.json:4379](../src/data/chapter4-three-floor-maze.layout.json#L4379)
1005. 校史人物·程开甲
   来源：[src/data/chapter4-three-floor-maze.layout.json:4389](../src/data/chapter4-three-floor-maze.layout.json#L4389)
1006. 三楼校友头像长廊
   来源：[src/data/chapter4-three-floor-maze.layout.json:4399](../src/data/chapter4-three-floor-maze.layout.json#L4399)
1007. 三楼参照教室教师
   来源：[src/data/chapter4-three-floor-maze.layout.json:4409](../src/data/chapter4-three-floor-maze.layout.json#L4409)
1008. 三楼晨间教室布置参照
   来源：[src/data/chapter4-three-floor-maze.layout.json:4419](../src/data/chapter4-three-floor-maze.layout.json#L4419)
1009. 校园后勤服务
   来源：[src/data/chapter4-wechat.content.json:3](../src/data/chapter4-wechat.content.json#L3)
1010. 公众号
   来源：[src/data/chapter4-wechat.content.json:4](../src/data/chapter4-wechat.content.json#L4)
1011. 段永平教学楼夜间运行提醒
   来源：[src/data/chapter4-wechat.content.json:5](../src/data/chapter4-wechat.content.json#L5)
1012. 夜间清楼期间，部分通道将分时关闭，主电梯停靠状态可能调整。
   来源：[src/data/chapter4-wechat.content.json:7](../src/data/chapter4-wechat.content.json#L7)
1013. 教学楼自 22:45 起按楼层分区清楼。
   来源：[src/data/chapter4-wechat.content.json:9](../src/data/chapter4-wechat.content.json#L9)
1014. 主电梯停靠状态以轿厢显示和现场提示音为准。
   来源：[src/data/chapter4-wechat.content.json:10](../src/data/chapter4-wechat.content.json#L10)
1015. 部分通道可能临时关闭，请留意楼层公告。
   来源：[src/data/chapter4-wechat.content.json:11](../src/data/chapter4-wechat.content.json#L11)
1016. 现场广播和安全指引优先于本推送。
   来源：[src/data/chapter4-wechat.content.json:12](../src/data/chapter4-wechat.content.json#L12)
1017. 读完并保存通知
   来源：[src/data/chapter4-wechat.content.json:14](../src/data/chapter4-wechat.content.json#L14)
1018. 校园楼宇与生活服务
   来源：[src/data/chapter4-wechat.content.json:15](../src/data/chapter4-wechat.content.json#L15)
1019. 楼宇小事
   来源：[src/data/chapter4-wechat.content.json:19](../src/data/chapter4-wechat.content.json#L19)
1020. 雨天的伞先放哪儿
   来源：[src/data/chapter4-wechat.content.json:20](../src/data/chapter4-wechat.content.json#L20)
1021. 收伞、取伞和寻找失物的几个细节，能少留一地水，也能少拿错一把黑伞。
   来源：[src/data/chapter4-wechat.content.json:22](../src/data/chapter4-wechat.content.json#L22)
1022. 雨天的楼道口总会多出几把伞。午后从图书馆回来，伞尖还滴着水，带进教室容易把地砖踩出一串湿脚印。教学区入口旁的暂存架放了吸水垫，伞可以合好后靠边摆，伞柄别挂在消防门上。
   来源：[src/data/chapter4-wechat.content.json:26](../src/data/chapter4-wechat.content.json#L26)
1023. 傍晚取伞时，先看看伞带和手柄上的小标记。黑伞排在一起，三分钟足够让人怀疑自己的记忆，也很容易拿错。没有找到的同学可以在服务台登记颜色、伞柄样式和大致时间。工作人员整理时会把散落的伞移到失物架，雨停后记得领走。
   来源：[src/data/chapter4-wechat.content.json:27](../src/data/chapter4-wechat.content.json#L27)
1024. 夜读提示
   来源：[src/data/chapter4-wechat.content.json:32](../src/data/chapter4-wechat.content.json#L32)
1025. 晚自习收尾的半分钟
   来源：[src/data/chapter4-wechat.content.json:33](../src/data/chapter4-wechat.content.json#L33)
1026. 带走桌边的充电线，把椅子推进去，夜间清洁经过时能少绕几次。
   来源：[src/data/chapter4-wechat.content.json:35](../src/data/chapter4-wechat.content.json#L35)
1027. 晚间自习临近结束时，走廊里的打印机通常还在吐最后几页，充电线也最容易留在桌角。离开前花半分钟看一眼座位下方，再把椅子轻轻推进去，清洁设备经过时能少绕几次。
   来源：[src/data/chapter4-wechat.content.json:39](../src/data/chapter4-wechat.content.json#L39)
1028. 入口、电梯和可通行楼层以当晚现场提示为准。准备继续学习的同学，请把水杯、电脑和个人物品带在身边。临时找不到同伴时，可以先到大厅等候，别在正在清洁的楼层里来回找插座。
   来源：[src/data/chapter4-wechat.content.json:40](../src/data/chapter4-wechat.content.json#L40)
1029. 食堂顺手事
   来源：[src/data/chapter4-wechat.content.json:45](../src/data/chapter4-wechat.content.json#L45)
1030. 餐盘回收台前少等一会儿
   来源：[src/data/chapter4-wechat.content.json:46](../src/data/chapter4-wechat.content.json#L46)
1031. 餐盘放稳，筷子和纸巾分开，下一位同学就能早一点离开回收台。
   来源：[src/data/chapter4-wechat.content.json:48](../src/data/chapter4-wechat.content.json#L48)
1032. 午餐高峰过去后，回收台上常剩几只装着汤勺的餐盘。餐具回收口前有时只差两步，大家端着餐盘聊天，队伍就会停在转角。餐盘放稳后再把筷子和纸巾分开，后面的人能少等一会儿。
   来源：[src/data/chapter4-wechat.content.json:52](../src/data/chapter4-wechat.content.json#L52)
1033. 汤碗和剩菜请先倒净，整杯饮料也别塞进餐盘缝里。纸巾掉进残渣桶时不用弯腰去捞，可以交给现场工作人员处理。吃完把桌面收干净，下一位同学就能直接坐下。
   来源：[src/data/chapter4-wechat.content.json:53](../src/data/chapter4-wechat.content.json#L53)
1034. 校园慢行
   来源：[src/data/chapter4-wechat.content.json:58](../src/data/chapter4-wechat.content.json#L58)
1035. 把共享单车摆正以后
   来源：[src/data/chapter4-wechat.content.json:59](../src/data/chapter4-wechat.content.json#L59)
1036. 把车停进线内，给盲道、坡道和拖着行李的人多留一点通过空间。
   来源：[src/data/chapter4-wechat.content.json:61](../src/data/chapter4-wechat.content.json#L61)
1037. 早八前后，教学区路边经常出现同一种停车方式。车头朝里，后轮卡在树池边，旁边只够一个人侧身通过。赶时间可以理解，拎着早餐或拖着行李经过的人也确实容易被绊住。
   来源：[src/data/chapter4-wechat.content.json:65](../src/data/chapter4-wechat.content.json#L65)
1038. 骑到目的地后，把车停进线内，再把挡住盲道、坡道和楼门的车辆顺手移开一点。遇到倒下的车，可以先扶正后再结束用车。多花十秒，清洁车和轮椅都能顺着走。
   来源：[src/data/chapter4-wechat.content.json:66](../src/data/chapter4-wechat.content.json#L66)
1039. 湖边观察
   来源：[src/data/chapter4-wechat.content.json:71](../src/data/chapter4-wechat.content.json#L71)
1040. 在启真湖边看水鸟
   来源：[src/data/chapter4-wechat.content.json:72](../src/data/chapter4-wechat.content.json#L72)
1041. 镜头可以拉近，脚步和食物要离远一些。安静观察，常能看到更多。
   来源：[src/data/chapter4-wechat.content.json:74](../src/data/chapter4-wechat.content.json#L74)
1042. 启真湖边最近多了几只停在浅水处的水鸟。有人隔着栏杆拍照，也有人带着面包走近。鸟一受惊就会游向水面中央，岸边的人越多，等待的时间也越长。
   来源：[src/data/chapter4-wechat.content.json:78](../src/data/chapter4-wechat.content.json#L78)
1043. 看鸟时留在步道上，把镜头拉近就够了。不要投喂面包、薯片和含糖饮料，也别追着鸟群跑。可以留意羽色、脚蹼和活动方向，声音放低一些。安静站一会儿，有时能看到它们靠近岸边。
   来源：[src/data/chapter4-wechat.content.json:79](../src/data/chapter4-wechat.content.json#L79)
1044. 失物招领
   来源：[src/data/chapter4-wechat.content.json:84](../src/data/chapter4-wechat.content.json#L84)
1045. 失物架上那只耳机
   来源：[src/data/chapter4-wechat.content.json:85](../src/data/chapter4-wechat.content.json#L85)
1046. 水杯、卡套和耳机常出现在服务台，多留几个特征就能少跑几趟。
   来源：[src/data/chapter4-wechat.content.json:87](../src/data/chapter4-wechat.content.json#L87)
1047. 楼宇服务台的失物架上，最常见的是水杯、门禁卡套和单只耳机。难找的是没有写名字的充电盒，外观看起来接近，型号、贴纸和磨损位置各有不同。
   来源：[src/data/chapter4-wechat.content.json:91](../src/data/chapter4-wechat.content.json#L91)
1048. 捡到物品后，交给就近服务台时尽量补一句地点和时间。失主来问时，颜色、贴纸和磨损位置都能帮上忙。要找失物的同学可以先准备这些特征，再留一个可联系的方式。
   来源：[src/data/chapter4-wechat.content.json:92](../src/data/chapter4-wechat.content.json#L92)
1049. 203 还开着吗？我电脑没关。
   来源：[src/data/chapter4-wechat.content.json:101](../src/data/chapter4-wechat.content.json#L101)；[src/scenes/phone/P14_Wechat/index.tsx:30](../src/scenes/phone/P14_Wechat/index.tsx#L30)
1050. 林昊
   来源：[src/data/chapter4-wechat.content.json:101](../src/data/chapter4-wechat.content.json#L101)；[src/scenes/phone/P14_Wechat/index.tsx:30](../src/scenes/phone/P14_Wechat/index.tsx#L30)
1051. 陈嘉
   来源：[src/data/chapter4-wechat.content.json:102](../src/data/chapter4-wechat.content.json#L102)；[src/scenes/phone/P14_Wechat/index.tsx:31](../src/scenes/phone/P14_Wechat/index.tsx#L31)
1052. 刚看见保安从东边过去。
   来源：[src/data/chapter4-wechat.content.json:102](../src/data/chapter4-wechat.content.json#L102)；[src/scenes/phone/P14_Wechat/index.tsx:31](../src/scenes/phone/P14_Wechat/index.tsx#L31)
1053. 东边不是已经封了吗？
   来源：[src/data/chapter4-wechat.content.json:103](../src/data/chapter4-wechat.content.json#L103)
1054. 周琪
   来源：[src/data/chapter4-wechat.content.json:103](../src/data/chapter4-wechat.content.json#L103)
1055. 室友
   来源：[src/data/chapter4-wechat.content.json:104](../src/data/chapter4-wechat.content.json#L104)
1056. 我在西侧看见保洁推车，应该还能走。
   来源：[src/data/chapter4-wechat.content.json:104](../src/data/chapter4-wechat.content.json#L104)
1057. 陈嘉撤回了一条消息
   来源：[src/data/chapter4-wechat.content.json:106](../src/data/chapter4-wechat.content.json#L106)
1058. 算了，我去楼梯口看看。
   来源：[src/data/chapter4-wechat.content.json:107](../src/data/chapter4-wechat.content.json#L107)
1059. 保存路线讨论截图
   来源：[src/data/chapter4-wechat.content.json:108](../src/data/chapter4-wechat.content.json#L108)
1060. 文件传输助手
   来源：[src/data/chapter4-wechat.content.json:111](../src/data/chapter4-wechat.content.json#L111)
1061. 还没有第四章现场资料。
   来源：[src/data/chapter4-wechat.content.json:112](../src/data/chapter4-wechat.content.json#L112)
1062. 夜间运行通知
   来源：[src/data/chapter4-wechat.content.json:113](../src/data/chapter4-wechat.content.json#L113)
1063. 主电梯到站提示音 00:07
   来源：[src/data/chapter4-wechat.content.json:114](../src/data/chapter4-wechat.content.json#L114)
1064. 麦斯威夜间自习群路线讨论
   来源：[src/data/chapter4-wechat.content.json:115](../src/data/chapter4-wechat.content.json#L115)
1065. 三楼新旧导视板对照照片
   来源：[src/data/chapter4-wechat.content.json:116](../src/data/chapter4-wechat.content.json#L116)
1066. 把现在使用的导视板和残留的旧导视板都发我。
   来源：[src/data/chapter4-wechat.content.json:119](../src/data/chapter4-wechat.content.json#L119)
1067. \[图片\] 三楼新旧导视板
   来源：[src/data/chapter4-wechat.content.json:120](../src/data/chapter4-wechat.content.json#L120)
1068. 两张图的二楼箭头方向相反。去现场核对仍保留旧编号的一侧，再调整导视板。
   来源：[src/data/chapter4-wechat.content.json:121](../src/data/chapter4-wechat.content.json#L121)
1069. 对照两张照片
   来源：[src/data/chapter4-wechat.content.json:122](../src/data/chapter4-wechat.content.json#L122)
1070. 苏步青
   来源：[src/data/ChapterFourAlumniHonorWall.ts:95](../src/data/ChapterFourAlumniHonorWall.ts#L95)
1071. 数学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:97](../src/data/ChapterFourAlumniHonorWall.ts#L97)；[src/data/ChapterFourAlumniHonorWall.ts:154](../src/data/ChapterFourAlumniHonorWall.ts#L154)；[src/data/ChapterFourAlumniHonorWall.ts:252](../src/data/ChapterFourAlumniHonorWall.ts#L252)
1072. 1931年回国后任浙江大学数学系副教授、教授及系主任。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:99](../src/data/ChapterFourAlumniHonorWall.ts#L99)
1073. 与陈建功共同形成有影响力的“陈苏学派”，培养了一批数学人才。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:100](../src/data/ChapterFourAlumniHonorWall.ts#L100)
1074. 抗战时期随浙江大学西迁，在艰苦条件下继续教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:101](../src/data/ChapterFourAlumniHonorWall.ts#L101)
1075. 浙江大学·求是大家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:103](../src/data/ChapterFourAlumniHonorWall.ts#L103)；[src/data/ChapterFourAlumniHonorWall.ts:220](../src/data/ChapterFourAlumniHonorWall.ts#L220)；[src/data/ChapterFourAlumniHonorWall.ts:239](../src/data/ChapterFourAlumniHonorWall.ts#L239)；[src/data/ChapterFourAlumniHonorWall.ts:258](../src/data/ChapterFourAlumniHonorWall.ts#L258)；[src/data/ChapterFourAlumniHonorWall.ts:334](../src/data/ChapterFourAlumniHonorWall.ts#L334)；[src/data/ChapterFourAlumniHonorWall.ts:372](../src/data/ChapterFourAlumniHonorWall.ts#L372)
1076. 竺可桢
   来源：[src/data/ChapterFourAlumniHonorWall.ts:114](../src/data/ChapterFourAlumniHonorWall.ts#L114)
1077. 气象学家、地理学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:116](../src/data/ChapterFourAlumniHonorWall.ts#L116)
1078. 1936—1949年任浙江大学校长，领导学校完成西迁并坚持办学。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:118](../src/data/ChapterFourAlumniHonorWall.ts#L118)
1079. 任内学校由 3 个学院、16 个系发展为 7 个学院、27 个系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:119](../src/data/ChapterFourAlumniHonorWall.ts#L119)
1080. 他在新生入学时提出两个问题，要求学生思考求学目的与成人方向。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:120](../src/data/ChapterFourAlumniHonorWall.ts#L120)
1081. 浙江大学国际联合学院·竺老两问
   来源：[src/data/ChapterFourAlumniHonorWall.ts:122](../src/data/ChapterFourAlumniHonorWall.ts#L122)
1082. 路甬祥
   来源：[src/data/ChapterFourAlumniHonorWall.ts:133](../src/data/ChapterFourAlumniHonorWall.ts#L133)
1083. 流体传动与控制学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:135](../src/data/ChapterFourAlumniHonorWall.ts#L135)
1084. 1964年毕业于浙江大学机械系，后留校任教并长期从事流体传动与控制研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:137](../src/data/ChapterFourAlumniHonorWall.ts#L137)
1085. 1988—1995年任浙江大学校长，推动学校教育、科研与管理改革。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:138](../src/data/ChapterFourAlumniHonorWall.ts#L138)
1086. 1991年当选中国科学院学部委员，1994年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:139](../src/data/ChapterFourAlumniHonorWall.ts#L139)
1087. 浙江大学·历任校长
   来源：[src/data/ChapterFourAlumniHonorWall.ts:141](../src/data/ChapterFourAlumniHonorWall.ts#L141)；[src/data/ChapterFourAlumniHonorWall.ts:296](../src/data/ChapterFourAlumniHonorWall.ts#L296)
1088. 陈建功
   来源：[src/data/ChapterFourAlumniHonorWall.ts:152](../src/data/ChapterFourAlumniHonorWall.ts#L152)
1089. 1929年起在浙江大学任教，主持数学系建设与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:156](../src/data/ChapterFourAlumniHonorWall.ts#L156)
1090. 与苏步青共同培育了中国现代数学的重要学术群体。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:157](../src/data/ChapterFourAlumniHonorWall.ts#L157)
1091. 西迁时期坚持教学和研究，奠定了浙大数学学科的早期基础。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:158](../src/data/ChapterFourAlumniHonorWall.ts#L158)
1092. 浙江大学档案馆·俊彩星驰长廊
   来源：[src/data/ChapterFourAlumniHonorWall.ts:160](../src/data/ChapterFourAlumniHonorWall.ts#L160)；[src/data/ChapterFourAlumniHonorWall.ts:429](../src/data/ChapterFourAlumniHonorWall.ts#L429)
1093. 谈家桢
   来源：[src/data/ChapterFourAlumniHonorWall.ts:172](../src/data/ChapterFourAlumniHonorWall.ts#L172)
1094. 遗传学家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:174](../src/data/ChapterFourAlumniHonorWall.ts#L174)
1095. 曾任浙江大学生物系教授，在西迁途中继续组织遗传学教学与实验。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:176](../src/data/ChapterFourAlumniHonorWall.ts#L176)
1096. 在缺少自来水、电灯和专业设备的条件下，带领学生用简易器材坚持研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:177](../src/data/ChapterFourAlumniHonorWall.ts#L177)
1097. 后长期推动中国现代遗传学的学科建设与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:178](../src/data/ChapterFourAlumniHonorWall.ts#L178)
1098. 浙江大学·求是精神薪火相传
   来源：[src/data/ChapterFourAlumniHonorWall.ts:180](../src/data/ChapterFourAlumniHonorWall.ts#L180)
1099. 程开甲
   来源：[src/data/ChapterFourAlumniHonorWall.ts:192](../src/data/ChapterFourAlumniHonorWall.ts#L192)
1100. 核物理学家、人民科学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:194](../src/data/ChapterFourAlumniHonorWall.ts#L194)
1101. 1937级浙江大学物理系校友，1941年毕业。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:196](../src/data/ChapterFourAlumniHonorWall.ts#L196)
1102. 是我国核武器研究的领导者之一，也是核试验事业的开拓者。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:197](../src/data/ChapterFourAlumniHonorWall.ts#L197)
1103. 获两弹一星功勋奖章、国家最高科学技术奖、八一勋章与人民科学家国家荣誉称号。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:198](../src/data/ChapterFourAlumniHonorWall.ts#L198)
1104. 浙江大学·程开甲先生诞辰 105 周年纪念会
   来源：[src/data/ChapterFourAlumniHonorWall.ts:200](../src/data/ChapterFourAlumniHonorWall.ts#L200)
1105. 王淦昌
   来源：[src/data/ChapterFourAlumniHonorWall.ts:212](../src/data/ChapterFourAlumniHonorWall.ts#L212)
1106. 核物理学家、两弹一星功勋科学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:214](../src/data/ChapterFourAlumniHonorWall.ts#L214)
1107. 1936年起任浙江大学物理系教授，并随学校西迁坚持教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:216](../src/data/ChapterFourAlumniHonorWall.ts#L216)
1108. 长期从事核物理研究，是我国核科学与核武器研制的重要开拓者之一。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:217](../src/data/ChapterFourAlumniHonorWall.ts#L217)
1109. 1999年获追授两弹一星功勋奖章。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:218](../src/data/ChapterFourAlumniHonorWall.ts#L218)
1110. 贝时璋
   来源：[src/data/ChapterFourAlumniHonorWall.ts:231](../src/data/ChapterFourAlumniHonorWall.ts#L231)
1111. 生物学家、生物物理学奠基人
   来源：[src/data/ChapterFourAlumniHonorWall.ts:233](../src/data/ChapterFourAlumniHonorWall.ts#L233)
1112. 1930年在浙江大学创建生物学系，并在西迁时期持续组织教学与研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:235](../src/data/ChapterFourAlumniHonorWall.ts#L235)
1113. 1958年参与创建中国科学院生物物理研究所并任首任所长。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:236](../src/data/ChapterFourAlumniHonorWall.ts#L236)
1114. 长期推动我国细胞学、实验生物学与生物物理学发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:237](../src/data/ChapterFourAlumniHonorWall.ts#L237)
1115. 谷超豪
   来源：[src/data/ChapterFourAlumniHonorWall.ts:250](../src/data/ChapterFourAlumniHonorWall.ts#L250)
1116. 1943年进入浙江大学龙泉分校，后在数学系学习并任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:254](../src/data/ChapterFourAlumniHonorWall.ts#L254)
1117. 在偏微分方程、微分几何和数学物理等领域取得系统成果。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:255](../src/data/ChapterFourAlumniHonorWall.ts#L255)
1118. 2009年获国家最高科学技术奖。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:256](../src/data/ChapterFourAlumniHonorWall.ts#L256)
1119. 李政道
   来源：[src/data/ChapterFourAlumniHonorWall.ts:269](../src/data/ChapterFourAlumniHonorWall.ts#L269)
1120. 物理学家、诺贝尔物理学奖获得者
   来源：[src/data/ChapterFourAlumniHonorWall.ts:271](../src/data/ChapterFourAlumniHonorWall.ts#L271)
1121. 1943年进入迁至湄潭的浙江大学物理系学习。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:273](../src/data/ChapterFourAlumniHonorWall.ts#L273)
1122. 求学期间受到束星北、王淦昌等先生指导，奠定理论物理基础。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:274](../src/data/ChapterFourAlumniHonorWall.ts#L274)
1123. 长期支持中国基础科学研究与青年人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:275](../src/data/ChapterFourAlumniHonorWall.ts#L275)
1124. 浙江大学·李政道纪念
   来源：[src/data/ChapterFourAlumniHonorWall.ts:277](../src/data/ChapterFourAlumniHonorWall.ts#L277)
1125. 潘云鹤
   来源：[src/data/ChapterFourAlumniHonorWall.ts:288](../src/data/ChapterFourAlumniHonorWall.ts#L288)
1126. 计算机应用专家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:290](../src/data/ChapterFourAlumniHonorWall.ts#L290)
1127. 1981年在浙江大学获得硕士学位后留校任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:292](../src/data/ChapterFourAlumniHonorWall.ts#L292)
1128. 1995—2006年任浙江大学校长，参与推动四校合并后的学科建设。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:293](../src/data/ChapterFourAlumniHonorWall.ts#L293)
1129. 长期研究人工智能、计算机美术与智能城市。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:294](../src/data/ChapterFourAlumniHonorWall.ts#L294)
1130. 韩祯祥
   来源：[src/data/ChapterFourAlumniHonorWall.ts:307](../src/data/ChapterFourAlumniHonorWall.ts#L307)
1131. 电力系统专家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:309](../src/data/ChapterFourAlumniHonorWall.ts#L309)
1132. 1951年毕业于浙江大学电机系并留校任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:311](../src/data/ChapterFourAlumniHonorWall.ts#L311)
1133. 1984—1988年任浙江大学校长，推动教学、科研与国际交流。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:312](../src/data/ChapterFourAlumniHonorWall.ts#L312)
1134. 长期从事电力系统稳定、控制与人才培养。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:313](../src/data/ChapterFourAlumniHonorWall.ts#L313)
1135. 浙江大学·韩祯祥院士纪念
   来源：[src/data/ChapterFourAlumniHonorWall.ts:315](../src/data/ChapterFourAlumniHonorWall.ts#L315)
1136. 夏道行
   来源：[src/data/ChapterFourAlumniHonorWall.ts:326](../src/data/ChapterFourAlumniHonorWall.ts#L326)
1137. 数学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:328](../src/data/ChapterFourAlumniHonorWall.ts#L328)；[src/data/ChapterFourAlumniHonorWall.ts:366](../src/data/ChapterFourAlumniHonorWall.ts#L366)
1138. 1952年进入浙江大学数学系攻读研究生，师从陈建功先生。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:330](../src/data/ChapterFourAlumniHonorWall.ts#L330)
1139. 在泛函分析、广义函数和数学物理等领域作出重要贡献。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:331](../src/data/ChapterFourAlumniHonorWall.ts#L331)
1140. 1980年当选中国科学院学部委员。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:332](../src/data/ChapterFourAlumniHonorWall.ts#L332)
1141. 潘镜芙
   来源：[src/data/ChapterFourAlumniHonorWall.ts:345](../src/data/ChapterFourAlumniHonorWall.ts#L345)
1142. 船舶设计专家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:347](../src/data/ChapterFourAlumniHonorWall.ts#L347)
1143. 1952年毕业于浙江大学电机系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:349](../src/data/ChapterFourAlumniHonorWall.ts#L349)
1144. 长期主持我国导弹驱逐舰研制，推动舰船总体设计与系统集成发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:350](../src/data/ChapterFourAlumniHonorWall.ts#L350)
1145. 1995年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:351](../src/data/ChapterFourAlumniHonorWall.ts#L351)
1146. 浙江大学档案馆·潘镜芙
   来源：[src/data/ChapterFourAlumniHonorWall.ts:353](../src/data/ChapterFourAlumniHonorWall.ts#L353)
1147. 王元
   来源：[src/data/ChapterFourAlumniHonorWall.ts:364](../src/data/ChapterFourAlumniHonorWall.ts#L364)
1148. 1952年毕业于浙江大学数学系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:368](../src/data/ChapterFourAlumniHonorWall.ts#L368)
1149. 在数论、数值分析与组合设计等领域取得重要成果。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:369](../src/data/ChapterFourAlumniHonorWall.ts#L369)
1150. 与华罗庚共同发展的数论方法被称为华—王方法。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:370](../src/data/ChapterFourAlumniHonorWall.ts#L370)
1151. 陈宜张
   来源：[src/data/ChapterFourAlumniHonorWall.ts:383](../src/data/ChapterFourAlumniHonorWall.ts#L383)
1152. 神经生理学家、医学教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:385](../src/data/ChapterFourAlumniHonorWall.ts#L385)
1153. 1952年毕业于浙江大学医学院，是学院首届毕业生之一。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:387](../src/data/ChapterFourAlumniHonorWall.ts#L387)
1154. 长期研究神经生理学与神经内分泌调控。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:388](../src/data/ChapterFourAlumniHonorWall.ts#L388)
1155. 曾任浙江医科大学校长并推动医学教育发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:389](../src/data/ChapterFourAlumniHonorWall.ts#L389)
1156. 浙江大学·陈宜张
   来源：[src/data/ChapterFourAlumniHonorWall.ts:391](../src/data/ChapterFourAlumniHonorWall.ts#L391)
1157. 林俊德
   来源：[src/data/ChapterFourAlumniHonorWall.ts:402](../src/data/ChapterFourAlumniHonorWall.ts#L402)
1158. 爆炸力学与核试验工程专家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:404](../src/data/ChapterFourAlumniHonorWall.ts#L404)
1159. 1960年毕业于浙江大学机械系。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:406](../src/data/ChapterFourAlumniHonorWall.ts#L406)
1160. 扎根大漠五十余年，参加我国全部核试验并负责关键测试技术。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:407](../src/data/ChapterFourAlumniHonorWall.ts#L407)
1161. 1993年当选中国工程院院士，2018年被列入全军挂像英模。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:408](../src/data/ChapterFourAlumniHonorWall.ts#L408)
1162. 浙江大学·林俊德院士纪念
   来源：[src/data/ChapterFourAlumniHonorWall.ts:410](../src/data/ChapterFourAlumniHonorWall.ts#L410)
1163. 谭其骧
   来源：[src/data/ChapterFourAlumniHonorWall.ts:421](../src/data/ChapterFourAlumniHonorWall.ts#L421)
1164. 历史地理学家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:423](../src/data/ChapterFourAlumniHonorWall.ts#L423)
1165. 1940—1950年在浙江大学史地系任教。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:425](../src/data/ChapterFourAlumniHonorWall.ts#L425)
1166. 在历史地理、疆域沿革与人口迁移研究方面影响深远。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:426](../src/data/ChapterFourAlumniHonorWall.ts#L426)
1167. 主持编绘《中国历史地图集》，推动现代历史地理学科建设。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:427](../src/data/ChapterFourAlumniHonorWall.ts#L427)
1168. 郑树森
   来源：[src/data/ChapterFourAlumniHonorWall.ts:440](../src/data/ChapterFourAlumniHonorWall.ts#L440)
1169. 器官移植专家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:442](../src/data/ChapterFourAlumniHonorWall.ts#L442)
1170. 长期在浙江大学从事肝胆胰外科与器官移植临床、科研和教学。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:444](../src/data/ChapterFourAlumniHonorWall.ts#L444)
1171. 推动我国肝移植、多器官联合移植与相关技术体系发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:445](../src/data/ChapterFourAlumniHonorWall.ts#L445)
1172. 2001年当选中国工程院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:446](../src/data/ChapterFourAlumniHonorWall.ts#L446)
1173. 浙江大学个人主页·郑树森
   来源：[src/data/ChapterFourAlumniHonorWall.ts:448](../src/data/ChapterFourAlumniHonorWall.ts#L448)
1174. 杨卫
   来源：[src/data/ChapterFourAlumniHonorWall.ts:459](../src/data/ChapterFourAlumniHonorWall.ts#L459)
1175. 固体力学专家、教育家
   来源：[src/data/ChapterFourAlumniHonorWall.ts:461](../src/data/ChapterFourAlumniHonorWall.ts#L461)
1176. 长期在浙江大学从事固体力学、微纳米力学与交叉力学研究。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:463](../src/data/ChapterFourAlumniHonorWall.ts#L463)
1177. 2006—2013年任浙江大学校长，推动学科交叉与工程教育发展。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:464](../src/data/ChapterFourAlumniHonorWall.ts#L464)
1178. 2003年当选中国科学院院士。
   来源：[src/data/ChapterFourAlumniHonorWall.ts:465](../src/data/ChapterFourAlumniHonorWall.ts#L465)
1179. 浙江大学个人主页·杨卫
   来源：[src/data/ChapterFourAlumniHonorWall.ts:467](../src/data/ChapterFourAlumniHonorWall.ts#L467)
1180. 第一问：到浙大来做什么？
   来源：[src/data/ChapterFourAlumniHonorWall.ts:480](../src/data/ChapterFourAlumniHonorWall.ts#L480)
1181. 追问事实与方法
   来源：[src/data/ChapterFourAlumniHonorWall.ts:482](../src/data/ChapterFourAlumniHonorWall.ts#L482)
1182. 用所学解决真实问题
   来源：[src/data/ChapterFourAlumniHonorWall.ts:483](../src/data/ChapterFourAlumniHonorWall.ts#L483)
1183. 为公共需要承担责任
   来源：[src/data/ChapterFourAlumniHonorWall.ts:484](../src/data/ChapterFourAlumniHonorWall.ts#L484)
1184. 第二问：将来毕业后要做什么样的人？
   来源：[src/data/ChapterFourAlumniHonorWall.ts:489](../src/data/ChapterFourAlumniHonorWall.ts#L489)
1185. 对工作和他人负责
   来源：[src/data/ChapterFourAlumniHonorWall.ts:491](../src/data/ChapterFourAlumniHonorWall.ts#L491)
1186. 保持独立判断与证据诚实
   来源：[src/data/ChapterFourAlumniHonorWall.ts:492](../src/data/ChapterFourAlumniHonorWall.ts#L492)
1187. 把能力放到社会需要上
   来源：[src/data/ChapterFourAlumniHonorWall.ts:493](../src/data/ChapterFourAlumniHonorWall.ts#L493)
1188. 打开前台值班签到板
   来源：[src/data/ChapterFourInteractionContent.ts:92](../src/data/ChapterFourInteractionContent.ts#L92)
1189. 前台签到板留有三个空位，可以把已确认的值班牌放回去。
   来源：[src/data/ChapterFourInteractionContent.ts:101](../src/data/ChapterFourInteractionContent.ts#L101)
1190. 三个夹痕的磨损不同，分别对应 104、105 与主电梯。
   来源：[src/data/ChapterFourInteractionContent.ts:102](../src/data/ChapterFourInteractionContent.ts#L102)
1191. 查看 201 创客工坊
   来源：[src/data/ChapterFourInteractionContent.ts:107](../src/data/ChapterFourInteractionContent.ts#L107)
1192. 201 工具都挂回原位了。门边登记板已签“封闭”，灯还亮着。
   来源：[src/data/ChapterFourInteractionContent.ts:117](../src/data/ChapterFourInteractionContent.ts#L117)
1193. 操作台边缘保留着较早的手部动作残影，当前房间没有新增活动轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:118](../src/data/ChapterFourInteractionContent.ts#L118)
1194. 工坊午休，切割垫上还压着没装完的校园模型。开放时间先结束，模型下次再装。
   来源：[src/data/ChapterFourInteractionContent.ts:121](../src/data/ChapterFourInteractionContent.ts#L121)
1195. 模型零件周围有连续取放残影，时间间隔与午休人流一致。
   来源：[src/data/ChapterFourInteractionContent.ts:122](../src/data/ChapterFourInteractionContent.ts#L122)
1196. 工坊台面清完了，焊台还亮着余温警示。签离场表可以，伸手碰还不行。
   来源：[src/data/ChapterFourInteractionContent.ts:125](../src/data/ChapterFourInteractionContent.ts#L125)
1197. 焊台上方的动作残影在 18:50 前停止，随后没有人继续使用设备。
   来源：[src/data/ChapterFourInteractionContent.ts:126](../src/data/ChapterFourInteractionContent.ts#L126)
1198. 维修时段的总电源已经断开，工具柜保持封签状态。
   来源：[src/data/ChapterFourInteractionContent.ts:129](../src/data/ChapterFourInteractionContent.ts#L129)
1199. 工具柜没有被开启的残影，走廊异常并非来自这间工坊。
   来源：[src/data/ChapterFourInteractionContent.ts:130](../src/data/ChapterFourInteractionContent.ts#L130)
1200. 应急照明只覆盖出口，工坊设备仍保持断电。
   来源：[src/data/ChapterFourInteractionContent.ts:133](../src/data/ChapterFourInteractionContent.ts#L133)
1201. 门口出现一段短暂停留残影，没有进入操作区。
   来源：[src/data/ChapterFourInteractionContent.ts:134](../src/data/ChapterFourInteractionContent.ts#L134)
1202. 晨间开放检查已完成，工具数量与登记表一致。
   来源：[src/data/ChapterFourInteractionContent.ts:137](../src/data/ChapterFourInteractionContent.ts#L137)
1203. 昨夜残影已经淡去，设备状态回到正常的早班记录。
   来源：[src/data/ChapterFourInteractionContent.ts:138](../src/data/ChapterFourInteractionContent.ts#L138)
1204. 查看 202 阶梯教室
   来源：[src/data/ChapterFourInteractionContent.ts:144](../src/data/ChapterFourInteractionContent.ts#L144)
1205. 202 幕布收了，座椅全折着。刚才坐过多少人，得去别的表上查。
   来源：[src/data/ChapterFourInteractionContent.ts:154](../src/data/ChapterFourInteractionContent.ts#L154)
1206. 最后一排到门口有一段连贯离场残影，讲台附近没有停留。
   来源：[src/data/ChapterFourInteractionContent.ts:155](../src/data/ChapterFourInteractionContent.ts#L155)
1207. 讲座还没开始，前排资料已经放好，翻开全是空白页。内容等主讲人来。
   来源：[src/data/ChapterFourInteractionContent.ts:158](../src/data/ChapterFourInteractionContent.ts#L158)
1208. 座位间只有短暂经过的残影，没有形成完整听课轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:159](../src/data/ChapterFourInteractionContent.ts#L159)
1209. 202 人走光了，投影机风扇刚停。门槛上还留着散场脚印。
   来源：[src/data/ChapterFourInteractionContent.ts:162](../src/data/ChapterFourInteractionContent.ts#L162)
1210. 座位残影从前排向出口逐段消失，散场时间集中在 18:50 前后。
   来源：[src/data/ChapterFourInteractionContent.ts:163](../src/data/ChapterFourInteractionContent.ts#L163)
1211. 维修许可牌挂在门外，室内设备保持关机。
   来源：[src/data/ChapterFourInteractionContent.ts:166](../src/data/ChapterFourInteractionContent.ts#L166)
1212. 讲台投影区保留一段独立画面残留，与普通授课记录不连续。
   来源：[src/data/ChapterFourInteractionContent.ts:167](../src/data/ChapterFourInteractionContent.ts#L167)
1213. 停电后安全出口灯正常，阶梯通道没有障碍物。
   来源：[src/data/ChapterFourInteractionContent.ts:170](../src/data/ChapterFourInteractionContent.ts#L170)
1214. 投影区残影仍在，亮度不随停电状态变化。
   来源：[src/data/ChapterFourInteractionContent.ts:171](../src/data/ChapterFourInteractionContent.ts#L171)
1215. 202 已完成晨检，投影和座椅等待第一节课。
   来源：[src/data/ChapterFourInteractionContent.ts:174](../src/data/ChapterFourInteractionContent.ts#L174)
1216. 夜间残留停止更新，教室回到正常的晨间时间轨。
   来源：[src/data/ChapterFourInteractionContent.ts:175](../src/data/ChapterFourInteractionContent.ts#L175)
1217. 查看 203 计算机教室
   来源：[src/data/ChapterFourInteractionContent.ts:181](../src/data/ChapterFourInteractionContent.ts#L181)
1218. 203 学生机都关了，教师机还显示维护清单。最后一项也是“关机”。
   来源：[src/data/ChapterFourInteractionContent.ts:191](../src/data/ChapterFourInteractionContent.ts#L191)
1219. 屏幕前的残影按座位顺序消失，没有人在关机后返回。
   来源：[src/data/ChapterFourInteractionContent.ts:192](../src/data/ChapterFourInteractionContent.ts#L192)
1220. 午间机房处于节能待机，靠门终端正在安装课程环境。
   来源：[src/data/ChapterFourInteractionContent.ts:195](../src/data/ChapterFourInteractionContent.ts#L195)
1221. 键盘上方的输入残影很短，属于自动部署前的检查动作。
   来源：[src/data/ChapterFourInteractionContent.ts:196](../src/data/ChapterFourInteractionContent.ts#L196)
1222. 账号都退出了，第三排还有一把椅子没推回。软件能批量处理，椅子还得靠人。
   来源：[src/data/ChapterFourInteractionContent.ts:199](../src/data/ChapterFourInteractionContent.ts#L199)
1223. 第三排的离座残影比其他位置晚六秒，但随后直接离开机房。
   来源：[src/data/ChapterFourInteractionContent.ts:200](../src/data/ChapterFourInteractionContent.ts#L200)
1224. 机房交换机仍在线，学生终端全部断开。
   来源：[src/data/ChapterFourInteractionContent.ts:203](../src/data/ChapterFourInteractionContent.ts#L203)
1225. 网络指示残影连续，设备没有出现异常重启。
   来源：[src/data/ChapterFourInteractionContent.ts:204](../src/data/ChapterFourInteractionContent.ts#L204)
1226. 后备电源只维持交换机，显示器和主机均已关闭。
   来源：[src/data/ChapterFourInteractionContent.ts:207](../src/data/ChapterFourInteractionContent.ts#L207)
1227. 设备断电时间一致，没有单独延迟的终端。
   来源：[src/data/ChapterFourInteractionContent.ts:208](../src/data/ChapterFourInteractionContent.ts#L208)
1228. 机房已按早课配置启动，座位状态与预约名单一致。
   来源：[src/data/ChapterFourInteractionContent.ts:211](../src/data/ChapterFourInteractionContent.ts#L211)
1229. 夜间设备残影已经结束，当前只有晨检人员的短时轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:212](../src/data/ChapterFourInteractionContent.ts#L212)
1230. 检查 202 疏散路线板
   来源：[src/data/ChapterFourInteractionContent.ts:218](../src/data/ChapterFourInteractionContent.ts#L218)
1231. 路线板缺少从 202 到主楼梯的连续箭头，四块磁贴仍可调整。
   来源：[src/data/ChapterFourInteractionContent.ts:228](../src/data/ChapterFourInteractionContent.ts#L228)
1232. 202 门外与楼梯黄线内留有同一种鞋底纹，中间两段需要根据朝向接续。
   来源：[src/data/ChapterFourInteractionContent.ts:229](../src/data/ChapterFourInteractionContent.ts#L229)
1233. 查看 301 校史档案展
   来源：[src/data/ChapterFourInteractionContent.ts:234](../src/data/ChapterFourInteractionContent.ts#L234)
1234. 301 的档案柜按年代编号，展签强调记录需要保留原始时间。
   来源：[src/data/ChapterFourInteractionContent.ts:244](../src/data/ChapterFourInteractionContent.ts#L244)
1235. 翻阅残影停在同一页：校史记录同时注明事件、地点与记录人。
   来源：[src/data/ChapterFourInteractionContent.ts:245](../src/data/ChapterFourInteractionContent.ts#L245)
1236. 午间展厅开放，玻璃柜中的教学日志按日期排放。
   来源：[src/data/ChapterFourInteractionContent.ts:248](../src/data/ChapterFourInteractionContent.ts#L248)
1237. 访客残影在日志柜前停留最久，随后依次查看人物档案。
   来源：[src/data/ChapterFourInteractionContent.ts:249](../src/data/ChapterFourInteractionContent.ts#L249)
1238. 301 停止接待了，扫描台还显示今日校验结果，档案逐页核完，等明天的人来签名。
   来源：[src/data/ChapterFourInteractionContent.ts:252](../src/data/ChapterFourInteractionContent.ts#L252)
1239. 扫描动作在 18:50 前完成，每页都保留来源编号。
   来源：[src/data/ChapterFourInteractionContent.ts:253](../src/data/ChapterFourInteractionContent.ts#L253)
1240. 恒温柜运行正常，维修记录没有涉及档案展区。
   来源：[src/data/ChapterFourInteractionContent.ts:256](../src/data/ChapterFourInteractionContent.ts#L256)
1241. 展柜周围没有异常移动残影，档案位置保持不变。
   来源：[src/data/ChapterFourInteractionContent.ts:257](../src/data/ChapterFourInteractionContent.ts#L257)
1242. 停电时档案柜自动上锁，应急照明覆盖疏散通道。
   来源：[src/data/ChapterFourInteractionContent.ts:260](../src/data/ChapterFourInteractionContent.ts#L260)
1243. 锁定动作同时发生，没有单独开启的柜门。
   来源：[src/data/ChapterFourInteractionContent.ts:261](../src/data/ChapterFourInteractionContent.ts#L261)
1244. 晨检完成后，档案展恢复开放状态。
   来源：[src/data/ChapterFourInteractionContent.ts:264](../src/data/ChapterFourInteractionContent.ts#L264)
1245. 早班记录从 07:55 开始，昨夜时间轨已经封存。
   来源：[src/data/ChapterFourInteractionContent.ts:265](../src/data/ChapterFourInteractionContent.ts#L265)
1246. 查看 302 媒体工作室
   来源：[src/data/ChapterFourInteractionContent.ts:271](../src/data/ChapterFourInteractionContent.ts#L271)
1247. 302 的录音设备已关闭，时间码发生器保留最后一次同步结果。
   来源：[src/data/ChapterFourInteractionContent.ts:281](../src/data/ChapterFourInteractionContent.ts#L281)
1248. 剪辑台残影显示素材被逐段核对，没有一次性覆盖原始文件。
   来源：[src/data/ChapterFourInteractionContent.ts:282](../src/data/ChapterFourInteractionContent.ts#L282)
1249. 午间工作室正在导出校园活动素材，监听音量保持在低档。
   来源：[src/data/ChapterFourInteractionContent.ts:285](../src/data/ChapterFourInteractionContent.ts#L285)
1250. 录音棚里的说话残影与波形段落对应，停顿位置清晰。
   来源：[src/data/ChapterFourInteractionContent.ts:286](../src/data/ChapterFourInteractionContent.ts#L286)
1251. 晚间录制已经结束，场记板停在 18:50 的收尾镜次。
   来源：[src/data/ChapterFourInteractionContent.ts:289](../src/data/ChapterFourInteractionContent.ts#L289)
1252. 最后一段人声结束后仍有六秒环境声，随后才停止录制。
   来源：[src/data/ChapterFourInteractionContent.ts:290](../src/data/ChapterFourInteractionContent.ts#L290)
1253. 工作室断开外部输入，存储阵列继续执行校验。
   来源：[src/data/ChapterFourInteractionContent.ts:293](../src/data/ChapterFourInteractionContent.ts#L293)
1254. 设备残影只显示自动校验，没有新的录制动作。
   来源：[src/data/ChapterFourInteractionContent.ts:294](../src/data/ChapterFourInteractionContent.ts#L294)
1255. 后备电源保留时间码和存储阵列，其他设备已经关闭。
   来源：[src/data/ChapterFourInteractionContent.ts:297](../src/data/ChapterFourInteractionContent.ts#L297)
1256. 时间码在停电期间连续，没有发生跳秒。
   来源：[src/data/ChapterFourInteractionContent.ts:298](../src/data/ChapterFourInteractionContent.ts#L298)
1257. 工作室完成晨间同步，所有设备采用同一时间源。
   来源：[src/data/ChapterFourInteractionContent.ts:301](../src/data/ChapterFourInteractionContent.ts#L301)
1258. 当前残影只有开机检查，时间轨从 07:55 重新开始。
   来源：[src/data/ChapterFourInteractionContent.ts:302](../src/data/ChapterFourInteractionContent.ts#L302)
1259. 查看 304 报告厅
   来源：[src/data/ChapterFourInteractionContent.ts:308](../src/data/ChapterFourInteractionContent.ts#L308)
1260. 304 的报告题目仍留在侧屏：判断需要来源、时间和可复核记录。
   来源：[src/data/ChapterFourInteractionContent.ts:318](../src/data/ChapterFourInteractionContent.ts#L318)
1261. 观众残影在提问环节集中出现，讲台记录保留了每次修改。
   来源：[src/data/ChapterFourInteractionContent.ts:319](../src/data/ChapterFourInteractionContent.ts#L319)
1262. 水杯和翻页器摆好了，主讲人还没到。设备已检查完，听众还在等。
   来源：[src/data/ChapterFourInteractionContent.ts:322](../src/data/ChapterFourInteractionContent.ts#L322)
1263. 前排只有布场人员的短时残影，座位区尚未形成观众轨迹。
   来源：[src/data/ChapterFourInteractionContent.ts:323](../src/data/ChapterFourInteractionContent.ts#L323)
1264. 报告结束了，侧屏停在末页，底下还有一行小字“修改记录请勿删除”。
   来源：[src/data/ChapterFourInteractionContent.ts:326](../src/data/ChapterFourInteractionContent.ts#L326)
1265. 散场残影从后排开始，讲台人员最后离开。
   来源：[src/data/ChapterFourInteractionContent.ts:327](../src/data/ChapterFourInteractionContent.ts#L327)
1266. 报告厅完成设备巡检，扩声与投影均处于关机状态。
   来源：[src/data/ChapterFourInteractionContent.ts:330](../src/data/ChapterFourInteractionContent.ts#L330)
1267. 设备周围没有异常操作残影，巡检记录连续。
   来源：[src/data/ChapterFourInteractionContent.ts:331](../src/data/ChapterFourInteractionContent.ts#L331)
1268. 应急广播接管报告厅，所有出口指示正常。
   来源：[src/data/ChapterFourInteractionContent.ts:334](../src/data/ChapterFourInteractionContent.ts#L334)
1269. 广播启用与停电同时发生，没有额外控制动作。
   来源：[src/data/ChapterFourInteractionContent.ts:335](../src/data/ChapterFourInteractionContent.ts#L335)
1270. 报告厅开始晨间准备，侧屏切换为当日安排。
   来源：[src/data/ChapterFourInteractionContent.ts:338](../src/data/ChapterFourInteractionContent.ts#L338)
1271. 当前只有布场人员的残影，昨夜报告已经归档。
   来源：[src/data/ChapterFourInteractionContent.ts:339](../src/data/ChapterFourInteractionContent.ts#L339)
1272. 签到记录纸
   来源：[src/data/itemCatalog.ts:210](../src/data/itemCatalog.ts#L210)
1273. 待补全
   来源：[src/data/itemCatalog.ts:212](../src/data/itemCatalog.ts#L212)
1274. 状态
   来源：[src/data/itemCatalog.ts:212](../src/data/itemCatalog.ts#L212)
1275. 教学楼签到
   来源：[src/data/itemCatalog.ts:213](../src/data/itemCatalog.ts#L213)
1276. 纸面记录停在 07:55 前后，签字栏还空着。
   来源：[src/data/itemCatalog.ts:216](../src/data/itemCatalog.ts#L216)
1277. 提交时须另验校园卡。纸面有记录，签字栏里还缺本人。
   来源：[src/data/itemCatalog.ts:217](../src/data/itemCatalog.ts#L217)
1278. 边缘有多次折返留下的旧压痕。
   来源：[src/data/itemCatalog.ts:219](../src/data/itemCatalog.ts#L219)
1279. 左岸快到了。稳住节奏。
   来源：[src/data/pursuit.audio.content.json:73](../src/data/pursuit.audio.content.json#L73)
1280. The left bank is close. Hold the rhythm.
   来源：[src/data/pursuit.audio.content.json:74](../src/data/pursuit.audio.content.json#L74)
1281. Stop! Step away from the clock.
   来源：[src/data/pursuit.audio.content.json:88](../src/data/pursuit.audio.content.json#L88)
1282. You there, stop! Can you hear me?
   来源：[src/data/pursuit.audio.content.json:102](../src/data/pursuit.audio.content.json#L102)
1283. I can see you. Stop!
   来源：[src/data/pursuit.audio.content.json:116](../src/data/pursuit.audio.content.json#L116)
1284. 门厅 · 教室层
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:21](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L21)
1285. 104 / 105 / 旧钟门厅
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:22](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L22)
1286. 起行与门体轨
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:23](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L23)
1287. 一楼门体持续开放八秒，完整覆盖六秒进入窗口。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:26](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L26)
1288. 门体闭合后，轿厢指示立即由 1F 转为上行。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:27](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L27)
1289. 204 · 创客层
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:34](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L34)
1290. 201 / 203 / 204 / 开放自习区
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:35](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L35)
1291. 外呼与门机对照
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:36](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L36)
1292. 二楼下行外呼在 18:50:04 被按下，按钮持续亮到 18:50:12。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:39](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L39)
1293. 同一时间段没有二楼门机开启记录，层显由 1F 直接跳到 3F。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:40](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L40)
1294. 荣誉墙 · 档案层
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:47](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L47)
1295. 301 / 302 / 303 / 304 / 荣誉墙
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:48](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L48)
1296. 到站铃与开门轨
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:49](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L49)
1297. 三楼到站铃在 18:50:12 响起，随后门机完整开启。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:52](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L52)
1298. 轿厢内没有第二次起步记录，这里是离开一楼后的实际到站层。
   来源：[src/modules/ChapterFourElevatorFloorInvestigation.ts:53](../src/modules/ChapterFourElevatorFloorInvestigation.ts#L53)
1299. 值班牌重建
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:93](../src/modules/ChapterFourInsertedPuzzleModel.ts#L93)
1300. A1 前台
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:94](../src/modules/ChapterFourInsertedPuzzleModel.ts#L94)
1301. 三段痕迹分别停在 104、105 与主电梯；夹痕由左向右逐渐变新。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:95](../src/modules/ChapterFourInsertedPuzzleModel.ts#L95)
1302. 把三张值班牌按痕迹先后放回签到板。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:96](../src/modules/ChapterFourInsertedPuzzleModel.ts#L96)
1303. A1 的三处调查已汇成一条值班记录。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:97](../src/modules/ChapterFourInsertedPuzzleModel.ts#L97)
1304. 胶片索引
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:103](../src/modules/ChapterFourInsertedPuzzleModel.ts#L103)
1305. A3 · 301 校史档案展
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:104](../src/modules/ChapterFourInsertedPuzzleModel.ts#L104)
1306. 残留索引指向九十年代末、A3 层，并标记为入口导视用途。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:105](../src/modules/ChapterFourInsertedPuzzleModel.ts#L105)
1307. 用年份、楼层和用途缩小抽屉范围，取出唯一胶片。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:106](../src/modules/ChapterFourInsertedPuzzleModel.ts#L106)
1308. 旧导视胶片已从索引抽屉取出。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:107](../src/modules/ChapterFourInsertedPuzzleModel.ts#L107)
1309. 新旧影像对齐
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:113](../src/modules/ChapterFourInsertedPuzzleModel.ts#L113)
1310. A3 · 302 媒体工作室
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:114](../src/modules/ChapterFourInsertedPuzzleModel.ts#L114)
1311. 旧影像的入口轮廓向右偏两格、向上一格，并顺时针转过四分之一圈。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:115](../src/modules/ChapterFourInsertedPuzzleModel.ts#L115)
1312. 平移并旋转胶片，让入口、楼梯与荣誉墙三个轮廓同时重合。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:116](../src/modules/ChapterFourInsertedPuzzleModel.ts#L116)
1313. 旧导视影像已与当前楼层坐标重合。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:117](../src/modules/ChapterFourInsertedPuzzleModel.ts#L117)
1314. 定位板校准
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:123](../src/modules/ChapterFourInsertedPuzzleModel.ts#L123)
1315. A2 · 201 创客工坊
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:124](../src/modules/ChapterFourInsertedPuzzleModel.ts#L124)
1316. 压力痕迹显示横向回退两格、纵向前推一格，第三档压力留下完整压印。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:125](../src/modules/ChapterFourInsertedPuzzleModel.ts#L125)
1317. 调整横向、纵向与压力，让三处触点同时落入旧痕。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:126](../src/modules/ChapterFourInsertedPuzzleModel.ts#L126)
1318. 定位板已完成三轴校准。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:127](../src/modules/ChapterFourInsertedPuzzleModel.ts#L127)
1319. 五区拓扑恢复
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:133](../src/modules/ChapterFourInsertedPuzzleModel.ts#L133)
1320. A2 · 203 计算机教室
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:134](../src/modules/ChapterFourInsertedPuzzleModel.ts#L134)
1321. 五区形成一个闭合环：大厅连两侧走廊，两侧分别接后区与教室区，末端再相连。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:135](../src/modules/ChapterFourInsertedPuzzleModel.ts#L135)
1322. 只保留停电前存在的五条相邻连线。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:136](../src/modules/ChapterFourInsertedPuzzleModel.ts#L136)
1323. 五区供电拓扑已恢复到停电前状态。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:137](../src/modules/ChapterFourInsertedPuzzleModel.ts#L137)
1324. 202 夜间疏散图
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:143](../src/modules/ChapterFourInsertedPuzzleModel.ts#L143)
1325. A2 · 开放自习区路线板
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:144](../src/modules/ChapterFourInsertedPuzzleModel.ts#L144)
1326. 图面没有完整箭头。比较四处鞋印的朝向、连续纹路和收束位置。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:145](../src/modules/ChapterFourInsertedPuzzleModel.ts#L145)
1327. 从 202 门口开始，把四块磁贴排成连续通路；终点必须落在主楼梯下行口。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:146](../src/modules/ChapterFourInsertedPuzzleModel.ts#L146)
1328. 202 到主楼梯的夜间疏散路线已记录。
   来源：[src/modules/ChapterFourInsertedPuzzleModel.ts:147](../src/modules/ChapterFourInsertedPuzzleModel.ts#L147)
1329. 金属时针已经归位，外圈多出一处能够稳定停住的刻度。
   来源：[src/modules/ChapterFourStagePresentation.ts:127](../src/modules/ChapterFourStagePresentation.ts#L127)
1330. 定位片已经归位，外圈另一处原本回弹的刻度保持不动。
   来源：[src/modules/ChapterFourStagePresentation.ts:129](../src/modules/ChapterFourStagePresentation.ts#L129)
1331. 纸条抓取 {{facts.has("opening\_paper\_caught") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:154](../src/modules/ChapterFourStagePresentation.ts#L154)
1332. 时间核对 {{facts.has("external\_time\_rejected") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:156](../src/modules/ChapterFourStagePresentation.ts#L156)
1333. 旧钟检查 {{facts.has("hall\_clock\_inspected") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:158](../src/modules/ChapterFourStagePresentation.ts#L158)
1334. 旧时针流程 {{countFacts(facts, \[ "bakery\_conveyor\_lamp\_inspected", "bakery\_hour\_hand\_exposed", "bakery\_hour\_hand\_collected", "hour\_hand\_installed" \])}}/4
   来源：[src/modules/ChapterFourStagePresentation.ts:160](../src/modules/ChapterFourStagePresentation.ts#L160)
1335. 交通与参照 {{countFacts(facts, \[ "classroom\_104\_chalk\_residual\_observed", "classroom\_105\_terminal\_replay\_checked", "elevator\_history\_observed", "elevator\_history\_calibrated", "a3\_reference\_observed", "misaligned\_stair\_solved", "room204\_residual\_observed" \])}}/7 · 复原 {{countCompletedRoom204Groups( state.chapter4.room204Placements )}}/{{ROOM204\_GROUP\_ORDER.length}}
   来源：[src/modules/ChapterFourStagePresentation.ts:167](../src/modules/ChapterFourStagePresentation.ts#L167)
1336. 维修流程 {{countMaintenanceMilestones(facts)}}/3
   来源：[src/modules/ChapterFourStagePresentation.ts:179](../src/modules/ChapterFourStagePresentation.ts#L179)
1337. 必要灯区 {{progress.satisfied}}/{{progress.total}}
   来源：[src/modules/ChapterFourStagePresentation.ts:182](../src/modules/ChapterFourStagePresentation.ts#L182)
1338. 抵达 202 0/1
   来源：[src/modules/ChapterFourStagePresentation.ts:185](../src/modules/ChapterFourStagePresentation.ts#L185)
1339. 分针组件 {{facts.has("final\_minute\_recovered") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:187](../src/modules/ChapterFourStagePresentation.ts#L187)
1340. 抵达一楼 0/1
   来源：[src/modules/ChapterFourStagePresentation.ts:189](../src/modules/ChapterFourStagePresentation.ts#L189)
1341. 抵达一楼 1/1
   来源：[src/modules/ChapterFourStagePresentation.ts:189](../src/modules/ChapterFourStagePresentation.ts#L189)
1342. 签到确认 {{countFacts(facts, \["checkin\_card\_accepted", "checkin\_paper\_accepted"\])}}/2
   来源：[src/modules/ChapterFourStagePresentation.ts:191](../src/modules/ChapterFourStagePresentation.ts#L191)
1343. 收束确认 {{facts.has("exterior\_closure\_acknowledged") ? 1 : 0}}/1
   来源：[src/modules/ChapterFourStagePresentation.ts:193](../src/modules/ChapterFourStagePresentation.ts#L193)
1344. 章节完成 1/1
   来源：[src/modules/ChapterFourStagePresentation.ts:195](../src/modules/ChapterFourStagePresentation.ts#L195)
1345. duplicate
   来源：[src/modules/ChapterFourTemporalMazeController.ts:375](../src/modules/ChapterFourTemporalMazeController.ts#L375)
1346. resolved
   来源：[src/modules/ChapterFourTemporalMazeController.ts:379](../src/modules/ChapterFourTemporalMazeController.ts#L379)
1347. failed
   来源：[src/modules/ChapterFourTemporalMazeController.ts:381](../src/modules/ChapterFourTemporalMazeController.ts#L381)
1348. accepted
   来源：[src/modules/ChapterFourTemporalMazeController.ts:849](../src/modules/ChapterFourTemporalMazeController.ts#L849)；[src/modules/ChapterFourTemporalMazeController.ts:860](../src/modules/ChapterFourTemporalMazeController.ts#L860)；[src/scenes/phone/P08_Settings/index.tsx:105](../src/scenes/phone/P08_Settings/index.tsx#L105)；[src/scenes/phone/P08_Settings/index.tsx:124](../src/scenes/phone/P08_Settings/index.tsx#L124)；[src/scenes/phone/P19_Clock/index.tsx:148](../src/scenes/phone/P19_Clock/index.tsx#L148)；[src/scenes/phone/P19_Clock/index.tsx:155](../src/scenes/phone/P19_Clock/index.tsx#L155)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9086](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9086)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9250](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9250)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9262](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9262)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9271](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9271)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9279](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9279)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9385](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9385)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9393](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9393)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9401](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9401)
1349. invalid\_request
   来源：[src/modules/ChapterFourTemporalMazeController.ts:2214](../src/modules/ChapterFourTemporalMazeController.ts#L2214)；[src/modules/ChapterFourTemporalMazeController.ts:2221](../src/modules/ChapterFourTemporalMazeController.ts#L2221)；[src/modules/ChapterFourTemporalMazeController.ts:2224](../src/modules/ChapterFourTemporalMazeController.ts#L2224)
1350. invalid\_intent
   来源：[src/modules/ChapterFourTemporalMazeController.ts:2227](../src/modules/ChapterFourTemporalMazeController.ts#L2227)；[src/modules/ChapterFourTemporalMazeController.ts:2231](../src/modules/ChapterFourTemporalMazeController.ts#L2231)
1351. 查看校园后勤服务的夜间运行通知
   来源：[src/modules/ChapterFourWechatModel.ts:80](../src/modules/ChapterFourWechatModel.ts#L80)
1352. 打开微信中的“校园后勤服务”公众号，保存段永平教学楼夜间运行提醒。
   来源：[src/modules/ChapterFourWechatModel.ts:81](../src/modules/ChapterFourWechatModel.ts#L81)
1353. 归档主电梯历史提示音
   来源：[src/modules/ChapterFourWechatModel.ts:87](../src/modules/ChapterFourWechatModel.ts#L87)
1354. 打开微信的文件传输助手，保存刚刚在深色观察中记录的电梯提示音。
   来源：[src/modules/ChapterFourWechatModel.ts:88](../src/modules/ChapterFourWechatModel.ts#L88)
1355. 从 CC98 导入学习天地资料索引
   来源：[src/modules/ChapterFourWechatModel.ts:97](../src/modules/ChapterFourWechatModel.ts#L97)
1356. 打开 CC98 的学习天地资料索引帖，选出课程年份、旧讨论和现场核验三项，再导入自习群。
   来源：[src/modules/ChapterFourWechatModel.ts:98](../src/modules/ChapterFourWechatModel.ts#L98)
1357. 保存麦斯威夜间自习群的路线讨论
   来源：[src/modules/ChapterFourWechatModel.ts:103](../src/modules/ChapterFourWechatModel.ts#L103)
1358. 打开微信学生群，保存包含东西两侧矛盾描述的群聊截图。
   来源：[src/modules/ChapterFourWechatModel.ts:104](../src/modules/ChapterFourWechatModel.ts#L104)
1359. 归档三楼新旧导视板照片
   来源：[src/modules/ChapterFourWechatModel.ts:112](../src/modules/ChapterFourWechatModel.ts#L112)
1360. 打开文件传输助手，将当前导视板和深色残影保存在同一组记录中。
   来源：[src/modules/ChapterFourWechatModel.ts:113](../src/modules/ChapterFourWechatModel.ts#L113)
1361. 请朋友对照新旧导视板
   来源：[src/modules/ChapterFourWechatModel.ts:119](../src/modules/ChapterFourWechatModel.ts#L119)
1362. 在微信朋友聊天中对照两张照片，记下二楼箭头的方向差异。
   来源：[src/modules/ChapterFourWechatModel.ts:120](../src/modules/ChapterFourWechatModel.ts#L120)
1363. already\_complete
   来源：[src/scenes/phone/P08_Settings/index.tsx:105](../src/scenes/phone/P08_Settings/index.tsx#L105)；[src/scenes/phone/P08_Settings/index.tsx:124](../src/scenes/phone/P08_Settings/index.tsx#L124)
1364. 旧桌面排布已核对，辅助记录已保存。
   来源：[src/scenes/phone/P08_Settings/index.tsx:106](../src/scenes/phone/P08_Settings/index.tsx#L106)
1365. incorrect
   来源：[src/scenes/phone/P08_Settings/index.tsx:107](../src/scenes/phone/P08_Settings/index.tsx#L107)；[src/scenes/phone/P08_Settings/index.tsx:126](../src/scenes/phone/P08_Settings/index.tsx#L126)
1366. 第一排仍不对。旧截图从左到右是微信、浙大钉、照片、CC98。
   来源：[src/scenes/phone/P08_Settings/index.tsx:108](../src/scenes/phone/P08_Settings/index.tsx#L108)
1367. 进入第四章后才能核对这张旧桌面截图。
   来源：[src/scenes/phone/P08_Settings/index.tsx:109](../src/scenes/phone/P08_Settings/index.tsx#L109)
1368. 三条 07:55 异常记录已归档。照片索引、时钟唤醒和 A2 定位共用同一时刻。
   来源：[src/scenes/phone/P08_Settings/index.tsx:125](../src/scenes/phone/P08_Settings/index.tsx#L125)
1369. 记录还混着正常刷新。只保留同时发生在 07:55 的三条异常活动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:127](../src/scenes/phone/P08_Settings/index.tsx#L127)
1370. 第四章尚未开始，这里只有普通后台记录。
   来源：[src/scenes/phone/P08_Settings/index.tsx:128](../src/scenes/phone/P08_Settings/index.tsx#L128)
1371. 打开控制中心切换网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1372. 当前网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1373. 等待校园网
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1374. 可访问
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1375. 离线
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1376. 校园网络与移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1377. 移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:133](../src/scenes/phone/P08_Settings/index.tsx#L133)
1378. 背景音乐
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1379. 开启
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1380. 声音与振动
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1381. 语音与操作音效保持开启
   来源：[src/scenes/phone/P08_Settings/index.tsx:134](../src/scenes/phone/P08_Settings/index.tsx#L134)
1382. 微信
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:445](../src/scenes/phone/P13_PhoneHome/index.tsx#L445)；[src/scenes/phone/P13_PhoneHome/index.tsx:448](../src/scenes/phone/P13_PhoneHome/index.tsx#L448)；[src/scenes/phone/P13_PhoneHome/index.tsx:805](../src/scenes/phone/P13_PhoneHome/index.tsx#L805)
1383. 微信，待处理：{{chapterFourWechatObjective.label}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:448](../src/scenes/phone/P13_PhoneHome/index.tsx#L448)
1384. 浙大体艺
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:453](../src/scenes/phone/P13_PhoneHome/index.tsx#L453)
1385. 浙大钉
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:459](../src/scenes/phone/P13_PhoneHome/index.tsx#L459)
1386. CC98
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:503](../src/scenes/phone/P13_PhoneHome/index.tsx#L503)；[src/scenes/phone/P13_PhoneHome/index.tsx:506](../src/scenes/phone/P13_PhoneHome/index.tsx#L506)
1387. CC98，待处理：{{chapterFourWechatObjective?.label ?? "学习天地资料索引"}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:506](../src/scenes/phone/P13_PhoneHome/index.tsx#L506)
1388. 控制中心
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:511](../src/scenes/phone/P13_PhoneHome/index.tsx#L511)
1389. 时钟
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:520](../src/scenes/phone/P13_PhoneHome/index.tsx#L520)
1390. 新增照片「看不清的书脊」
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:785](../src/scenes/phone/P13_PhoneHome/index.tsx#L785)
1391. 照片
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:785](../src/scenes/phone/P13_PhoneHome/index.tsx#L785)；[src/scenes/phone/P13_PhoneHome/index.tsx:811](../src/scenes/phone/P13_PhoneHome/index.tsx#L811)
1392. 打开 CC98 学习天地资料索引帖
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:796](../src/scenes/phone/P13_PhoneHome/index.tsx#L796)
1393. 课程年份入口与旧自习讨论待导入
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:799](../src/scenes/phone/P13_PhoneHome/index.tsx#L799)
1394. CC98 · 学习天地
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:799](../src/scenes/phone/P13_PhoneHome/index.tsx#L799)
1395. IMG\_0755 的识别结果仍需现场核验
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:811](../src/scenes/phone/P13_PhoneHome/index.tsx#L811)
1396. 这份资料已经保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:447](../src/scenes/phone/P14_Wechat/index.tsx#L447)
1397. 夜间运行通知已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:456](../src/scenes/phone/P14_Wechat/index.tsx#L456)
1398. 第四章开始后才能查看这条运行通知。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:457](../src/scenes/phone/P14_Wechat/index.tsx#L457)
1399. 主电梯提示音已归档。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:464](../src/scenes/phone/P14_Wechat/index.tsx#L464)
1400. 文件传输助手尚未收到一楼电梯历史提示音记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:465](../src/scenes/phone/P14_Wechat/index.tsx#L465)
1401. 路线讨论已保存。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:472](../src/scenes/phone/P14_Wechat/index.tsx#L472)
1402. 先去 CC98 学习天地，把课程年份入口、旧讨论和现场核验三项导入群文件。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:474](../src/scenes/phone/P14_Wechat/index.tsx#L474)
1403. 先阅读公众号通知，并抵达二楼清楼阶段。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:475](../src/scenes/phone/P14_Wechat/index.tsx#L475)
1404. 新旧导视板照片已归档。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:482](../src/scenes/phone/P14_Wechat/index.tsx#L482)
1405. 文件传输助手尚未收到三楼旧导视板残影记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:483](../src/scenes/phone/P14_Wechat/index.tsx#L483)
1406. 照片对照完成。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:490](../src/scenes/phone/P14_Wechat/index.tsx#L490)
1407. 先把三楼新旧导视板照片保存到文件传输助手。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:491](../src/scenes/phone/P14_Wechat/index.tsx#L491)
1408. 朋友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:638](../src/scenes/phone/P14_Wechat/index.tsx#L638)
1409. 返回公众号主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1410. 返回聊天列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1411. official
   来源：[src/scenes/phone/P14_Wechat/index.tsx:647](../src/scenes/phone/P14_Wechat/index.tsx#L647)
1412. 麦斯威夜间自习群聊天记录
   来源：[src/scenes/phone/P14_Wechat/index.tsx:657](../src/scenes/phone/P14_Wechat/index.tsx#L657)
1413. 22:47 ·
   来源：[src/scenes/phone/P14_Wechat/index.tsx:658](../src/scenes/phone/P14_Wechat/index.tsx#L658)
1414. 人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:658](../src/scenes/phone/P14_Wechat/index.tsx#L658)
1415. 路线讨论已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:685](../src/scenes/phone/P14_Wechat/index.tsx#L685)
1416. 第四章现场资料
   来源：[src/scenes/phone/P14_Wechat/index.tsx:690](../src/scenes/phone/P14_Wechat/index.tsx#L690)
1417. 公众号推送 · 22:40
   来源：[src/scenes/phone/P14_Wechat/index.tsx:693](../src/scenes/phone/P14_Wechat/index.tsx#L693)
1418. 已读
   来源：[src/scenes/phone/P14_Wechat/index.tsx:693](../src/scenes/phone/P14_Wechat/index.tsx#L693)
1419. 群文件 · 学习天地
   来源：[src/scenes/phone/P14_Wechat/index.tsx:697](../src/scenes/phone/P14_Wechat/index.tsx#L697)
1420. 课程年份入口与旧自习讨论
   来源：[src/scenes/phone/P14_Wechat/index.tsx:698](../src/scenes/phone/P14_Wechat/index.tsx#L698)
1421. 已从 CC98 导入
   来源：[src/scenes/phone/P14_Wechat/index.tsx:699](../src/scenes/phone/P14_Wechat/index.tsx#L699)
1422. 现场录音 · 1F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:704](../src/scenes/phone/P14_Wechat/index.tsx#L704)
1423. 保存照片
   来源：[src/scenes/phone/P14_Wechat/index.tsx:714](../src/scenes/phone/P14_Wechat/index.tsx#L714)
1424. 已归档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:714](../src/scenes/phone/P14_Wechat/index.tsx#L714)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7833](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7833)
1425. 朋友导视板对照聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:720](../src/scenes/phone/P14_Wechat/index.tsx#L720)
1426. 新旧导视板照片
   来源：[src/scenes/phone/P14_Wechat/index.tsx:725](../src/scenes/phone/P14_Wechat/index.tsx#L725)
1427. 2F →
   来源：[src/scenes/phone/P14_Wechat/index.tsx:726](../src/scenes/phone/P14_Wechat/index.tsx#L726)
1428. 当前导视
   来源：[src/scenes/phone/P14_Wechat/index.tsx:726](../src/scenes/phone/P14_Wechat/index.tsx#L726)
1429. ← 2F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:727](../src/scenes/phone/P14_Wechat/index.tsx#L727)
1430. 历史残影
   来源：[src/scenes/phone/P14_Wechat/index.tsx:727](../src/scenes/phone/P14_Wechat/index.tsx#L727)
1431. 照片已完成对照
   来源：[src/scenes/phone/P14_Wechat/index.tsx:730](../src/scenes/phone/P14_Wechat/index.tsx#L730)
1432. {{label}} −
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:377](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L377)
1433. {{label}} +
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:387](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L387)
1434. {{strings.assemble}} / {{strings.explode}}
   来源：[src/scenes/phone/P19_Clock/ClockMovement3D.tsx:511](../src/scenes/phone/P19_Clock/ClockMovement3D.tsx#L511)
1435. 系统
   来源：[src/scenes/phone/P19_Clock/index.tsx:29](../src/scenes/phone/P19_Clock/index.tsx#L29)
1436. 玩家
   来源：[src/scenes/phone/P19_Clock/index.tsx:31](../src/scenes/phone/P19_Clock/index.tsx#L31)
1437. 我
   来源：[src/scenes/phone/P19_Clock/index.tsx:31](../src/scenes/phone/P19_Clock/index.tsx#L31)；[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:70](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L70)
1438. {{currentRound.label}}协议通过，进入下一轮。
   来源：[src/scenes/phone/P19_Clock/index.tsx:103](../src/scenes/phone/P19_Clock/index.tsx#L103)
1439. 这条记录属于其他场景，无法写入 B2-04 档案。
   来源：[src/scenes/phone/P19_Clock/index.tsx:133](../src/scenes/phone/P19_Clock/index.tsx#L133)
1440. {{unit === "hour" ? "小时" : "分钟"}}机芯已锁定。
   来源：[src/scenes/phone/P19_Clock/index.tsx:148](../src/scenes/phone/P19_Clock/index.tsx#L148)
1441. {{channel.label}}漂移已归零。
   来源：[src/scenes/phone/P19_Clock/index.tsx:155](../src/scenes/phone/P19_Clock/index.tsx#L155)
1442. 返回手机主页
   来源：[src/scenes/phone/P19_Clock/index.tsx:166](../src/scenes/phone/P19_Clock/index.tsx#L166)；[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)；[src/scenes/rpg/RpgGameHost.tsx:2546](../src/scenes/rpg/RpgGameHost.tsx#L2546)
1443. B2-04 / TIME REPAIR
   来源：[src/scenes/phone/P19_Clock/index.tsx:167](../src/scenes/phone/P19_Clock/index.tsx#L167)
1444. 校时状态
   来源：[src/scenes/phone/P19_Clock/index.tsx:171](../src/scenes/phone/P19_Clock/index.tsx#L171)
1445. 四关校时流程
   来源：[src/scenes/phone/P19_Clock/index.tsx:175](../src/scenes/phone/P19_Clock/index.tsx#L175)
1446. 返回当前任务
   来源：[src/scenes/phone/P19_Clock/index.tsx:179](../src/scenes/phone/P19_Clock/index.tsx#L179)
1447. ACCESS DENIED
   来源：[src/scenes/phone/P19_Clock/index.tsx:179](../src/scenes/phone/P19_Clock/index.tsx#L179)
1448. /3 证据
   来源：[src/scenes/phone/P19_Clock/index.tsx:182](../src/scenes/phone/P19_Clock/index.tsx#L182)
1449. 01 / ARCHIVE REBUILD
   来源：[src/scenes/phone/P19_Clock/index.tsx:182](../src/scenes/phone/P19_Clock/index.tsx#L182)
1450. 提交档案与时刻
   来源：[src/scenes/phone/P19_Clock/index.tsx:189](../src/scenes/phone/P19_Clock/index.tsx#L189)
1451. /2 LOCKED
   来源：[src/scenes/phone/P19_Clock/index.tsx:193](../src/scenes/phone/P19_Clock/index.tsx#L193)
1452. 02 / DUAL MOVEMENT
   来源：[src/scenes/phone/P19_Clock/index.tsx:193](../src/scenes/phone/P19_Clock/index.tsx#L193)
1453. 00 分机芯
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1454. 08 时机芯
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1455. 23 秒暂存
   来源：[src/scenes/phone/P19_Clock/index.tsx:204](../src/scenes/phone/P19_Clock/index.tsx#L204)
1456. 进入漂移核对
   来源：[src/scenes/phone/P19_Clock/index.tsx:205](../src/scenes/phone/P19_Clock/index.tsx#L205)
1457. /3 ONLINE
   来源：[src/scenes/phone/P19_Clock/index.tsx:209](../src/scenes/phone/P19_Clock/index.tsx#L209)
1458. 03 / DRIFT MATRIX
   来源：[src/scenes/phone/P19_Clock/index.tsx:209](../src/scenes/phone/P19_Clock/index.tsx#L209)
1459. 已归零
   来源：[src/scenes/phone/P19_Clock/index.tsx:213](../src/scenes/phone/P19_Clock/index.tsx#L213)
1460. 应用反向修正
   来源：[src/scenes/phone/P19_Clock/index.tsx:213](../src/scenes/phone/P19_Clock/index.tsx#L213)
1461. 生成 08:00:00
   来源：[src/scenes/phone/P19_Clock/index.tsx:215](../src/scenes/phone/P19_Clock/index.tsx#L215)
1462. 04 / THREE PROTOCOLS
   来源：[src/scenes/phone/P19_Clock/index.tsx:219](../src/scenes/phone/P19_Clock/index.tsx#L219)
1463. 执行本轮放行
   来源：[src/scenes/phone/P19_Clock/index.tsx:224](../src/scenes/phone/P19_Clock/index.tsx#L224)
1464. 放行尝试
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1465. 漂移尝试
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1466. 四关校时
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1467. TIME AXIS / RELEASED
   来源：[src/scenes/phone/P19_Clock/index.tsx:227](../src/scenes/phone/P19_Clock/index.tsx#L227)
1468. P01 起床
   来源：[src/scenes/phone/registry.tsx:30](../src/scenes/phone/registry.tsx#L30)
1469. 再睡5分钟 → 旁白 → 起床蠢货！！！ → 手机主界面。
   来源：[src/scenes/phone/registry.tsx:31](../src/scenes/phone/registry.tsx#L31)
1470. P13 手机主界面
   来源：[src/scenes/phone/registry.tsx:34](../src/scenes/phone/registry.tsx#L34)
1471. 主屏：设置齿轮/塔楼钥匙孔/天气水滴/盆栽入口/微信弹窗。
   来源：[src/scenes/phone/registry.tsx:35](../src/scenes/phone/registry.tsx#L35)
1472. P08 设置
   来源：[src/scenes/phone/registry.tsx:38](../src/scenes/phone/registry.tsx#L38)
1473. 真实系统设置、桌面编排、可选应用恢复与第四章后台活动取证。
   来源：[src/scenes/phone/registry.tsx:39](../src/scenes/phone/registry.tsx#L39)
1474. P14 微信
   来源：[src/scenes/phone/registry.tsx:42](../src/scenes/phone/registry.tsx#L42)
1475. 朋友聊天触发小影散码；列表中朋友头像藏斜线谜题（P03）。
   来源：[src/scenes/phone/registry.tsx:43](../src/scenes/phone/registry.tsx#L43)
1476. P02 CC98
   来源：[src/scenes/phone/registry.tsx:46](../src/scenes/phone/registry.tsx#L46)
1477. 仅校园网可进入；热门话题列表与剧情帖子记录跟随游戏进度。
   来源：[src/scenes/phone/registry.tsx:47](../src/scenes/phone/registry.tsx#L47)
1478. P15 浙大钉
   来源：[src/scenes/phone/registry.tsx:50](../src/scenes/phone/registry.tsx#L50)
1479. 仅校园网可进入；承载系统入口、图书馆预约和移动图书馆证据流程。
   来源：[src/scenes/phone/registry.tsx:51](../src/scenes/phone/registry.tsx#L51)
1480. P06 浙大体艺
   来源：[src/scenes/phone/registry.tsx:54](../src/scenes/phone/registry.tsx#L54)
1481. 仅流量可进入；先开启课外锻炼，图书馆阶段再核对 7 / 47 / 3 到馆材料。
   来源：[src/scenes/phone/registry.tsx:55](../src/scenes/phone/registry.tsx#L55)
1482. 准备离开教学楼的学生像素立绘
   来源：[src/scenes/rpg/chapter4-prologue/ProloguePortraitAssets.ts:13](../src/scenes/rpg/chapter4-prologue/ProloguePortraitAssets.ts#L13)
1483. 迈斯威 →
   来源：[src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts:1365](../src/scenes/rpg/chapter4-prologue/PrologueRenderer.ts#L1365)
1484. 旁白
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:78](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L78)
1485. 保洁员
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:86](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L86)
1486. 第四章序幕：纸条进入段永平教学楼
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:641](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L641)
1487. 夜色中，湿纸条离开启真湖，经过街机厅进入段永平教学楼，沿大厅进入熄灯后的走廊
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:664](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L664)
1488. 由四项手机证据恢复的现场回放
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:667](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L667)
1489. RECOVERED TIMELINE
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:668](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L668)
1490. SOURCE 4 / 4
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:669](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L669)
1491. 跳过恢复回放
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:674](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L674)
1492. CHAPTER 03.5 · COMPLETE
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:701](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L701)
1493. 第四章：时间迷宫
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:702](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L702)
1494. 现场定位
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:705](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L705)
1495. 段永平教学楼玻璃门
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:706](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L706)
1496. 追踪进入教学楼的异常签到纸
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:710](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L710)
1497. 正在提交任务……
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:724](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L724)
1498. 正在同步教学楼现场……
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:726](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L726)
1499. 重试进入第四章
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:728](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L728)
1500. 收下任务，进入第四章
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:729](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L729)
1501. 重播过场
   来源：[src/scenes/rpg/Chapter4PrologueOverlay.tsx:736](../src/scenes/rpg/Chapter4PrologueOverlay.tsx#L736)
1502. 楼梯的空间关系发生错位。
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:87](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L87)
1503. B2 已接通
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:220](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L220)
1504. 空格键 记录下层回声
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:222](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L222)
1505. 下层回声已记录
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:222](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L222)
1506. 端点已对齐 · 空格键通过
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:224](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L224)
1507. A / ← 左转 · D / → 右转 · 让两端发光后通过
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:225](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L225)
1508. 错位折返楼梯
   来源：[src/scenes/rpg/ChapterFourStairAlignmentScene.ts:269](../src/scenes/rpg/ChapterFourStairAlignmentScene.ts#L269)
1509. A1 入口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:193](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L193)
1510. 电梯与楼层
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:194](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L194)
1511. 维修与追逐
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:195](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L195)
1512. 收束场景
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:196](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L196)
1513. A1 · 麦思威面包坊与门厅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:809](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L809)
1514. A2 · 教室与开放学习区
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:810](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L810)
1515. A3 · 校友荣誉门厅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:811](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L811)
1516. 楼梯上行口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1086](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1086)
1517. 楼梯下行口
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1086](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1086)
1518. up
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1086](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1086)
1519. unknown
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:1941](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L1941)
1520. 资料依据：{{figure.sourceLabel}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2537](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2537)
1521. Space / Enter · 返回 Esc · 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2564](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2564)
1522. 返回地图
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2570](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2570)
1523. {{CHAPTER\_FOUR\_WARMUP\_PHASE\_LABELS\[failedPhase\]}}资源准备失败（{{failedCount}} 项）· R 重试
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2736](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2736)
1524. 传递过程
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:2947](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L2947)
1525. 进度已恢复，请重试当前操作。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:4246](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L4246)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6344](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6344)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8512](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8512)
1526. 校园卡
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5598](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5598)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5621](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5621)
1527. 纸条
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5604](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5604)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5629](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5629)
1528. 已刷卡
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5621](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5621)
1529. 已签到
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:5629](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L5629)
1530. chase.close
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6040](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6040)
1531. 保安
   来源：[src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts:94](../src/scenes/rpg/chapter4-prologue/PrologueTimeline.ts#L94)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6042](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6042)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6236](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6236)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8933](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8933)
1532. 202 门已落闩
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6101](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6101)
1533. maintenance.cleaner
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6227](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6227)
1534. chase.started
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6234](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6234)
1535. morning.entry
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6242](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6242)
1536. exterior.closure
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6249](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6249)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9409](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9409)
1537. 07:55 残影投影
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6304](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6304)
1538. 校准中……
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6310](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6310)
1539. 偏移·3px
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6323](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6323)
1540. Space · 按{{ROOM204\_GROUPS\[nearbyGroupId\].label}}复原一组桌椅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6654](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6654)
1541. 当前为深色观察；{{ROOM204\_GROUPS\[nearbyGroupId\].label}}需在浅色操作中复原
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6655](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6655)
1542. Space · 把已搬起的桌椅放到残影槽位
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6662](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6662)
1543. Space · 搬动一组桌椅
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6669](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6669)
1544. 当前为深色观察；搬动桌椅需要浅色操作
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6670](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6670)
1545. 先搬一组桌椅，再放到残影槽位。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6679](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6679)
1546. 搬动桌椅需要浅色操作；当前仍可查看残影槽位。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6680](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6680)
1547. Space · 查看{{this.nearbyAlumniFigure.name}}生平
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6693](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6693)
1548. 把对应道具拖到{{this.nearbyStoryTarget.contract.label}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6701](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6701)
1549. Space · 调节大厅旧钟
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6707](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6707)
1550. Space · 冲进 202 并关门
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6711](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6711)
1551. 压下座椅固定扣（1/3）
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6716](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6716)
1552. 对准黄铜轴座（2/3）
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6717](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6717)
1553. 取出黄铜分针组件（3/3）
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6718](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6718)
1554. 当前为深色观察；拆取分针需要浅色操作
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6723](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6723)
1555. 切到浅色操作后再搬动桌椅。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6815](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6815)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6864](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6864)
1556. 先搬一组桌椅，再放到对应残影位置。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:6872](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L6872)
1557. 保安仍在追击。进入 202 门内后再按 Space 关门。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7112](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7112)
1558. 切到浅色操作后，再拆取黄铜分针组件。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7126](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7126)
1559. 已压下座椅固定扣（1/3）。继续对准黄铜轴座。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7140](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7140)
1560. 黄铜轴座已对准（2/3）。再按一次取出分针组件。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7141](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7141)
1561. 请从道具栏拖动道具到{{storyTarget.contract.label}}。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7164](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7164)
1562. final\_chase
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7179](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7179)
1563. 追逐中电梯已锁，请进入主楼梯。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7180](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7180)
1564. 停电状态下电梯无法返程。带着黄铜分针组件，从二楼主楼梯下到一楼大厅。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7181](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7181)
1565. 当前可继续观察；轿厢重放校准需要浅色操作。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7193](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7193)
1566. 电梯的历史片段只保留上行记录。请从三楼主楼梯返回二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7200](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7200)
1567. 先在三楼晨间教室记录桌椅、入口与投影边界。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7212](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7212)
1568. 钟面暂时没有出现新的稳定刻度。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7234](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7234)
1569. 转动外圈，比较能够停住的刻度
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7259](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7259)
1570. × 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7268](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7268)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7522](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7522)
1571. 固定这一刻度
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7360](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7360)
1572. 暂不调节
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7364](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7364)
1573. ← / → 选择刻度 · Enter 确认 · Esc 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7368](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7368)
1574. 当前
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7393](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7393)
1575. 刻痕清晰
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7393](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7393)
1576. 旧钟已经停在这一格；另一圈刻痕刚刚变得清晰。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7448](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7448)
1577. 这处刻度仍会回弹。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7452](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7452)
1578. 齿轮正在咬合……
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7455](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7455)
1579. A 楼主电梯
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7543](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7543)
1580. 18:50 运行复核
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7546](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7546)
1581. ↑↓ 选层 · Enter 执行 · Space 复核 · Esc 离开
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7618](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7618)
1582. 18:50 / 一号电梯运行档案
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7647](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7647)
1583. 同步一楼开门记录
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7651](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7651)
1584. 调整蓝色门体区间，让它完整覆盖黄色人物进入区间。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7654](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7654)
1585. 门体开放
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7658](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7658)
1586. 人物进入
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7661](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7661)
1587. 记录起点
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7664](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7664)
1588. 记录结束
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7667](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7667)
1589. 提前 1 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7706](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7706)
1590. 重放并校验
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7707](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7707)
1591. 延后 1 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7708](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7708)
1592. ← / → 调整重放起点 Enter 校验 Esc 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7709](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7709)
1593. 当前门体记录 {{formatClock(doorStart)}}—{{formatClock(doorEnd)}} / 8 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7759](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7759)
1594. 人物进入记录 {{formatClock(playerStart)}}—{{formatClock(playerEnd)}} / 6 秒
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7760](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7760)
1595. 校验结果：覆盖不完整，请调整重放起点。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7762](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7762)
1596. 白线：轿厢于 {{formatClock(doorStart + CHAPTER\_FOUR\_ELEVATOR.riseOffsetSeconds)}} 开始上行。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7763](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7763)
1597. 当前层
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7831](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7831)
1598. 可直达
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7835](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7835)
1599. 楼梯绕行
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7836](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7836)
1600. 跨层档案 {{recordCount}}/3{{chainSolved ? " · 已复核" : ""}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7846](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7846)
1601. □ 一楼记录来自门外三条时间轨。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7856](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7856)
1602. 离开轿厢后切到深色观察，在门前完成记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7856](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7856)
1603. □ 本层门机日志尚未归档。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7858](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7858)
1604. 当前可直接读取，记录后不会限制其他楼层的调查顺序。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7859](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7859)
1605. 离开轿厢切到深色观察，再进入电梯读取本层记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7860](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7860)
1606. □ 到达该层后可读取门机记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7862](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7862)
1607. 线索归档顺序不影响楼层通行。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7862](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7862)
1608. □ 轿厢没有该层的历史开门记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7863](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7863)
1609. 先乘到三楼，再从主楼梯完成空间校准并进入二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7863](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7863)
1610. 本层记录已归档
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7867](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7867)
1611. 离开轿厢读取一楼门体轨
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7869](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7869)
1612. 读取{{record.recordTitle}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7871](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7871)
1613. 需切换深色观察
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7872](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7872)
1614. 前往 {{record.displayFloor}}F
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7874](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7874)
1615. 查看主楼梯绕行说明
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7875](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7875)
1616. 停靠链已复核
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7882](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7882)
1617. 复核停靠链
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7884](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7884)
1618. 运行复核 {{recordCount}}/3
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7885](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7885)
1619. 二楼没有历史开门记录。先到三楼完成荣誉墙与影像调查，再从主楼梯校准空间并进入二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7898](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7898)
1620. {{record.displayFloor}}F {{record.recordTitle}}已经归档。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7907](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7907)
1621. 一楼起行记录位于电梯门外。离开轿厢后切到深色观察，在门前读取三条时间轨。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7913](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7913)
1622. 门机旧记录只在深色观察中可读。离开轿厢切换模式后再进入电梯。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7918](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7918)
1623. 停靠链已复核：1F 起行，轿厢越过 2F 后在 3F 到站；2F 外呼未得到响应。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7931](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7931)
1624. 还缺 {{3 - chapterFourElevatorCollectedRecordCount(state.chapter4.factIds)}} 段楼层记录。三段可按任意顺序归档。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7935](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7935)
1625. 记录已经齐全。离开轿厢切回浅色操作，再打开面板完成运行复核。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7939](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7939)
1626. 复原 18:50 停靠链
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7950](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7950)
1627. 3/3 记录齐全
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7953](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7953)
1628. 门开八秒；18:50:06 转为上行
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7958](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7958)
1629. 下行外呼亮起；门机没有开门记录
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7959](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7959)
1630. 到站铃响；随后门机完整开启
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7960)
1631. 轿厢离开 1F 后实际到站：
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7989](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7989)
1632. 有外呼但未得到开门响应：
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:7992](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L7992)
1633. 提交运行复核
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8032](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8032)
1634. ←→ 选择实际到站 · ↑↓ 选择未响应层 · Enter 提交 · Esc 返回
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8035](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8035)
1635. 比较三段记录，再分别确认实际到站层和未响应外呼层。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8091](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8091)
1636. 二楼外呼存在，但轿厢没有开门记录。先乘到三楼，再从错位主楼梯进入二楼。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8139](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8139)
1637. 当前已在 {{targetFloor}}F
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8143](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8143)
1638. 拨钟操作已取消，旧钟和纸条均已恢复，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8274](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8274)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8307](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8307)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8322](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8322)
1639. 最终拨钟条件尚未满足，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8367](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8367)
1640. 时间校准至 07:54。纸条带走了最后一分钟。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8412](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8412)
1641. 回路稳定
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8592](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8592)
1642. 传送带停机确认超时，已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8818](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8818)
1643. 07:55 残影投影确认超时，已回到已完成的教室布局，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8824](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8824)
1644. 最终拨钟确认超时，已恢复转动的旧钟和签到纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8831](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8831)
1645. 旧钟没有响应，请再次确认当前刻度。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8844](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8844)
1646. 当前楼层状态已经同步。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8906](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8906)
1647. 请切回浅色操作后再移动。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8907](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8907)
1648. 当前剧情阶段没有开放这条楼层通道。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8908](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8908)
1649. 当前无法前往该楼层。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8909](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8909)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8914](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8914)
1650. chase.floor\_changed
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8931](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8931)
1651. 当前剧情条件尚未满足。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8950](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8950)；[src/scenes/rpg/RpgGameHost.tsx:392](../src/scenes/rpg/RpgGameHost.tsx#L392)
1652. 门体开放区间未完整覆盖六秒进入窗口。调整重放起点后再试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8954](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8954)
1653. 复核不一致：重新比较二楼外呼与三楼门机时间。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8960](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8960)
1654. 实际到站层与未响应外呼层不能互换。重新比较三段记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8962](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8962)
1655. {{detail}}已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8976](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8976)
1656. {{detail}}已回到已完成的教室布局，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8982](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8982)
1657. {{detail}}已恢复转动的旧钟和签到纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:8989](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L8989)
1658. oldClockHourHand
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9004](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9004)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9085](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9085)
1659. finalMinute
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9008](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9008)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9384](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9384)
1660. campusCard
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9012](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9012)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9392](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9392)；[src/scenes/rpg/RpgGameHost.tsx:2619](../src/scenes/rpg/RpgGameHost.tsx#L2619)
1661. attendanceRecordPaper
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9016](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9016)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9400](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9400)
1662. shortPryBar
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9020](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9020)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9262](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9262)
1663. universalLubricatingOil
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9025](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9025)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9270](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9270)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9278](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9278)
1664. 传送带停机结果缺少已提交记录，已恢复到当前进度，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9070](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9070)
1665. 金属时针已装回，钟面多出一处能够稳定停住的刻度。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9087](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9087)
1666. 当前教室没有新增状态记录。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9138](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9138)
1667. classroom104.chalk\_residual
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9152](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9152)
1668. classroom105.terminal\_replay
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9160](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9160)
1669. 已记录门体开放、人物进入和轿厢上行三条时间轨。轿厢重放校准可独立在浅色操作中完成。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9168](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9168)
1670. {{record.displayFloor}}F {{record.recordTitle}}已归档。{{record.evidence\[0\]}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9185](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9185)
1671. 三层运行记录已经齐全。切回浅色操作后，可在面板中复核停靠链。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9190](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9190)
1672. 跨层运行链已复核：轿厢从一楼直达三楼，二楼外呼没有得到开门响应。定位片的楼层基准已确认。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9199](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9199)
1673. room204.a3\_reference\_recorded
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9207](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9207)
1674. room204.residual\_recorded
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9215](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9215)
1675. 已复原 {{Math.floor(normalizeRoom204Placements( this.bridge.getState().chapter4.room204Placements ).length / 3)}}/{{ROOM204\_GROUP\_ORDER.length}}
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9225](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9225)
1676. 07:55 投影结果缺少已提交记录，将自动重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9235](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9235)
1677. clockPositioningPlate
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9249](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9249)
1678. 定位片已归位，钟面另一处刻度不再回弹。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9251](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9251)
1679. 轮罩已打开，短撬棍完成了最后一次用途。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9262](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9262)
1680. 保洁车轮已修好，瓶里还剩一半润滑油。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9272](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9272)
1681. 旧钟齿轮已恢复转动。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9280](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9280)
1682. 已回到大厅安全点。维修进度和道具均已保留。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9293](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9293)
1683. 偷走最后一分钟的提交不完整，已恢复旧钟和纸条，可重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9311](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9311)
1684. 门闩已经落下，保安被挡在 202 门外。先拆开固定扣，再取出分针。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9348](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9348)
1685. chase.retry
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9361](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9361)
1686. lecture.recovered\_result
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9371](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9371)
1687. 最后一分钟已装回旧钟。时间已恢复到 07:55。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9386](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9386)
1688. 校园卡已通过签到校验。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9394](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9394)
1689. 签到记录已提交。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9402](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9402)
1690. 记录回来了，你没有回到记录发生的时候。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9604](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9604)
1691. 外部现场
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9625](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9625)
1692. 手机状态栏 · 冻结
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9635](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9635)
1693. 不可信
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9641](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9641)
1694. 外部时间与手机冻结时间冲突 · 签到提交已拒绝
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9644](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9644)
1695. 旧钟停在 22:45。表盘能被拨动，但响应方向和幅度都不对。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9670](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9670)
1696. 旧钟停在 12:25。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9752](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9752)
1697. 无法使用该道具。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9949](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9949)
1698. invalid\_item
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9950](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9950)
1699. 未命中有效目标。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9957](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9957)
1700. missed\_target
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9957](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9957)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9970](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9970)
1701. 未命中当前阶段的可见道具目标。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9970](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9970)
1702. {{target.contract.label}}需要另一件道具。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9975](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9975)
1703. wrong\_item
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:9975](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L9975)
1704. 交互失败，请重新靠近目标后重试。
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:10092](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L10092)；[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:10096](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L10096)；[src/scenes/rpg/RpgGameHost.tsx:1172](../src/scenes/rpg/RpgGameHost.tsx#L1172)
1705. locked
   来源：[src/scenes/rpg/ChapterFourTemporalMazeScene.ts:10092](../src/scenes/rpg/ChapterFourTemporalMazeScene.ts#L10092)
1706. 当前目标需要另一件道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:388](../src/scenes/rpg/RpgGameHost.tsx#L388)
1707. 距离目标太远，请靠近可见交互区域。
   来源：[src/scenes/rpg/RpgGameHost.tsx:389](../src/scenes/rpg/RpgGameHost.tsx#L389)
1708. 当前组合与已记录的线索不一致。
   来源：[src/scenes/rpg/RpgGameHost.tsx:390](../src/scenes/rpg/RpgGameHost.tsx#L390)
1709. ready
   来源：[src/scenes/rpg/RpgGameHost.tsx:580](../src/scenes/rpg/RpgGameHost.tsx#L580)
1710. 先在三楼晨间教室记录桌椅与入口位置，再进入空间校准。
   来源：[src/scenes/rpg/RpgGameHost.tsx:634](../src/scenes/rpg/RpgGameHost.tsx#L634)
1711. 当前组合与现场痕迹不一致，可以继续调整。
   来源：[src/scenes/rpg/RpgGameHost.tsx:680](../src/scenes/rpg/RpgGameHost.tsx#L680)
1712. 正在写入二楼到达记录…
   来源：[src/scenes/rpg/RpgGameHost.tsx:739](../src/scenes/rpg/RpgGameHost.tsx#L739)
1713. 楼梯校准结果未能写入，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:757](../src/scenes/rpg/RpgGameHost.tsx#L757)
1714. 两层错位楼梯已连通。已从三楼抵达二楼，204 教室恢复流程开放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:763](../src/scenes/rpg/RpgGameHost.tsx#L763)
1715. 回答未保存，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:859](../src/scenes/rpg/RpgGameHost.tsx#L859)
1716. 灯光收束未完成，正在重新播放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:896](../src/scenes/rpg/RpgGameHost.tsx#L896)
1717. 灯光收束确认未写入，已重新播放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:927](../src/scenes/rpg/RpgGameHost.tsx#L927)
1718. 教学楼交互请求缺少有效编号或包含多余字段。请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1197](../src/scenes/rpg/RpgGameHost.tsx#L1197)
1719. 当前教学楼交互请求无效。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1198](../src/scenes/rpg/RpgGameHost.tsx#L1198)
1720. 这次教学楼交互已经处理，未重复写入。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1204](../src/scenes/rpg/RpgGameHost.tsx#L1204)；[src/scenes/rpg/RpgGameHost.tsx:1290](../src/scenes/rpg/RpgGameHost.tsx#L1290)
1721. 第四章序幕交接仅由 App gate 提交。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1211](../src/scenes/rpg/RpgGameHost.tsx#L1211)
1722. 当前交互位置无法由活动场景重新确认，请靠近可见目标后重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1238](../src/scenes/rpg/RpgGameHost.tsx#L1238)
1723. 无目标交互不得携带运行时几何。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1281](../src/scenes/rpg/RpgGameHost.tsx#L1281)
1724. 教学楼交互处理失败，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1294](../src/scenes/rpg/RpgGameHost.tsx#L1294)
1725. 配电请求未被接受，请重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1365](../src/scenes/rpg/RpgGameHost.tsx#L1365)
1726. 区域供电状态已同步。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1374](../src/scenes/rpg/RpgGameHost.tsx#L1374)
1727. 三项判断中仍有矛盾，请重新核对现场现象。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1424](../src/scenes/rpg/RpgGameHost.tsx#L1424)
1728. 7:55 RPG runtime
   来源：[src/scenes/rpg/RpgGameHost.tsx:2351](../src/scenes/rpg/RpgGameHost.tsx#L2351)
1729. 7:55 横屏游戏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2370](../src/scenes/rpg/RpgGameHost.tsx#L2370)
1730. 场景资源
   来源：[src/scenes/rpg/RpgGameHost.tsx:2394](../src/scenes/rpg/RpgGameHost.tsx#L2394)
1731. 地图资源没有完整载入
   来源：[src/scenes/rpg/RpgGameHost.tsx:2396](../src/scenes/rpg/RpgGameHost.tsx#L2396)
1732. 正在准备地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2396](../src/scenes/rpg/RpgGameHost.tsx#L2396)
1733. 本次缺少
   来源：[src/scenes/rpg/RpgGameHost.tsx:2400](../src/scenes/rpg/RpgGameHost.tsx#L2400)
1734. 项资源。网络恢复后重试，当前存档不会变化。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2400](../src/scenes/rpg/RpgGameHost.tsx#L2400)
1735. 聚焦手机
   来源：[src/scenes/rpg/RpgGameHost.tsx:2546](../src/scenes/rpg/RpgGameHost.tsx#L2546)
1736. 全屏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2547](../src/scenes/rpg/RpgGameHost.tsx#L2547)
1737. 地图视角
   来源：[src/scenes/rpg/RpgGameHost.tsx:2552](../src/scenes/rpg/RpgGameHost.tsx#L2552)
1738. 定位人物
   来源：[src/scenes/rpg/RpgGameHost.tsx:2553](../src/scenes/rpg/RpgGameHost.tsx#L2553)
1739. 放大地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2554](../src/scenes/rpg/RpgGameHost.tsx#L2554)
1740. 缩小地图
   来源：[src/scenes/rpg/RpgGameHost.tsx:2555](../src/scenes/rpg/RpgGameHost.tsx#L2555)
1741. 地图物品栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2608](../src/scenes/rpg/RpgGameHost.tsx#L2608)
1742. 物品栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:2609](../src/scenes/rpg/RpgGameHost.tsx#L2609)
1743. 查看电子校园卡
   来源：[src/scenes/rpg/RpgGameHost.tsx:2614](../src/scenes/rpg/RpgGameHost.tsx#L2614)
1744. 单击查看校园卡信息，双击查看完整详情
   来源：[src/scenes/rpg/RpgGameHost.tsx:2615](../src/scenes/rpg/RpgGameHost.tsx#L2615)
1745. 已连接
   来源：[src/scenes/rpg/RpgGameHost.tsx:2640](../src/scenes/rpg/RpgGameHost.tsx#L2640)
1746. 待登记姓名
   来源：[src/scenes/rpg/RpgGameHost.tsx:2642](../src/scenes/rpg/RpgGameHost.tsx#L2642)
1747. 待开始锻炼
   来源：[src/scenes/rpg/RpgGameHost.tsx:2643](../src/scenes/rpg/RpgGameHost.tsx#L2643)
1748. 节奏钓鱼 A 左收线、S 提竿、D 右收线按钮
   来源：[src/scenes/rpg/RpgGameHost.tsx:2680](../src/scenes/rpg/RpgGameHost.tsx#L2680)
1749. A 左收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2684](../src/scenes/rpg/RpgGameHost.tsx#L2684)
1750. 左收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2691](../src/scenes/rpg/RpgGameHost.tsx#L2691)
1751. 交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2748](../src/scenes/rpg/RpgGameHost.tsx#L2748)
1752. 与当前湖区目标交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2748](../src/scenes/rpg/RpgGameHost.tsx#L2748)
1753. RPG操作键，键盘使用 WASD 移动和空格键交互
   来源：[src/scenes/rpg/RpgGameHost.tsx:2755](../src/scenes/rpg/RpgGameHost.tsx#L2755)
1754. 向上
   来源：[src/scenes/rpg/RpgGameHost.tsx:2757](../src/scenes/rpg/RpgGameHost.tsx#L2757)
1755. 向左
   来源：[src/scenes/rpg/RpgGameHost.tsx:2758](../src/scenes/rpg/RpgGameHost.tsx#L2758)
1756. 向下
   来源：[src/scenes/rpg/RpgGameHost.tsx:2759](../src/scenes/rpg/RpgGameHost.tsx#L2759)
1757. 向右
   来源：[src/scenes/rpg/RpgGameHost.tsx:2760](../src/scenes/rpg/RpgGameHost.tsx#L2760)
1758. 204 教室空槽位
   来源：[src/scenes/rpg/RpgInteractionContract.ts:449](../src/scenes/rpg/RpgInteractionContract.ts#L449)
1759. 烤箱旁的检修灯
   来源：[src/scenes/rpg/RpgInteractionContract.ts:569](../src/scenes/rpg/RpgInteractionContract.ts#L569)
1760. 面包坊传送带边缘
   来源：[src/scenes/rpg/RpgInteractionContract.ts:585](../src/scenes/rpg/RpgInteractionContract.ts#L585)
1761. 传送带旁的金属时针
   来源：[src/scenes/rpg/RpgInteractionContract.ts:601](../src/scenes/rpg/RpgInteractionContract.ts#L601)
1762. 清洁车卡住的轮罩
   来源：[src/scenes/rpg/RpgInteractionContract.ts:825](../src/scenes/rpg/RpgInteractionContract.ts#L825)
1763. 面包店后场短撬棍
   来源：[src/scenes/rpg/RpgInteractionContract.ts:841](../src/scenes/rpg/RpgInteractionContract.ts#L841)
1764. 清洁车轮罩
   来源：[src/scenes/rpg/RpgInteractionContract.ts:852](../src/scenes/rpg/RpgInteractionContract.ts#L852)
1765. 清洁车里的通用润滑油
   来源：[src/scenes/rpg/RpgInteractionContract.ts:866](../src/scenes/rpg/RpgInteractionContract.ts#L866)
1766. 清洁车车轮
   来源：[src/scenes/rpg/RpgInteractionContract.ts:877](../src/scenes/rpg/RpgInteractionContract.ts#L877)
1767. 签到校园卡读卡器
   来源：[src/scenes/rpg/RpgInteractionContract.ts:970](../src/scenes/rpg/RpgInteractionContract.ts#L970)；[src/scenes/rpg/RpgItemUseGuidance.ts:76](../src/scenes/rpg/RpgItemUseGuidance.ts#L76)
1768. 签到记录纸槽
   来源：[src/scenes/rpg/RpgInteractionContract.ts:986](../src/scenes/rpg/RpgInteractionContract.ts#L986)；[src/scenes/rpg/RpgItemUseGuidance.ts:82](../src/scenes/rpg/RpgItemUseGuidance.ts#L82)
1769. 先把黄铜分针组件装回大厅旧钟，再去签到口。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:85](../src/scenes/rpg/RpgItemUseGuidance.ts#L85)
1770. 旧钟接近 07:55 时，这张纸会被剧情自动带走。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:88](../src/scenes/rpg/RpgItemUseGuidance.ts#L88)

## 结局

1. locked
   来源：[src/core/GameState.ts:248](../src/core/GameState.ts#L248)
2. completed
   来源：[src/core/QuestModel.ts:101](../src/core/QuestModel.ts#L101)；[src/core/QuestModel.ts:593](../src/core/QuestModel.ts#L593)；[src/core/QuestModel.ts:956](../src/core/QuestModel.ts#L956)；[src/core/QuestModel.ts:992](../src/core/QuestModel.ts#L992)；[src/core/QuestModel.ts:1065](../src/core/QuestModel.ts#L1065)
3. pending
   来源：[src/core/QuestModel.ts:101](../src/core/QuestModel.ts#L101)；[src/core/QuestModel.ts:593](../src/core/QuestModel.ts#L593)；[src/core/QuestModel.ts:956](../src/core/QuestModel.ts#L956)；[src/core/QuestModel.ts:992](../src/core/QuestModel.ts#L992)；[src/core/QuestModel.ts:1065](../src/core/QuestModel.ts#L1065)
4. 201 定位板
   来源：[src/core/QuestModel.ts:965](../src/core/QuestModel.ts#L965)
5. 三轴校准
   来源：[src/core/QuestModel.ts:966](../src/core/QuestModel.ts#L966)
6. 203 配电箱
   来源：[src/core/QuestModel.ts:971](../src/core/QuestModel.ts#L971)
7. 五区拓扑
   来源：[src/core/QuestModel.ts:972](../src/core/QuestModel.ts#L972)
8. 开放自习区路线板
   来源：[src/core/QuestModel.ts:977](../src/core/QuestModel.ts#L977)
9. 202 至主楼梯
   来源：[src/core/QuestModel.ts:978](../src/core/QuestModel.ts#L978)
10. 1F 起行轨
   来源：[src/core/QuestModel.ts:1001](../src/core/QuestModel.ts#L1001)
11. 门体与起行
   来源：[src/core/QuestModel.ts:1002](../src/core/QuestModel.ts#L1002)
12. 2F 外呼日志
   来源：[src/core/QuestModel.ts:1007](../src/core/QuestModel.ts#L1007)
13. 呼梯与门机
   来源：[src/core/QuestModel.ts:1008](../src/core/QuestModel.ts#L1008)
14. 3F 到站记录
   来源：[src/core/QuestModel.ts:1013](../src/core/QuestModel.ts#L1013)
15. 铃声与开门
   来源：[src/core/QuestModel.ts:1014](../src/core/QuestModel.ts#L1014)
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
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:105](../src/scenes/phone/P13_PhoneHome/index.tsx#L105)
57. 记录恢复
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:875](../src/scenes/phone/P13_PhoneHome/index.tsx#L875)
58. 检测到 7 分 55 秒未同步记录
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:875](../src/scenes/phone/P13_PhoneHome/index.tsx#L875)
59. 现在
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:876](../src/scenes/phone/P13_PhoneHome/index.tsx#L876)；[src/scenes/phone/P13_PhoneHome/index.tsx:891](../src/scenes/phone/P13_PhoneHome/index.tsx#L891)
60. 朋友：成功了吗
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:879](../src/scenes/phone/P13_PhoneHome/index.tsx#L879)
61. 成功了吗
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:890](../src/scenes/phone/P13_PhoneHome/index.tsx#L890)；[src/scenes/phone/P14_Wechat/index.tsx:844](../src/scenes/phone/P14_Wechat/index.tsx#L844)
62. 朋友
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:890](../src/scenes/phone/P13_PhoneHome/index.tsx#L890)；[src/scenes/phone/P14_Wechat/index.tsx:839](../src/scenes/phone/P14_Wechat/index.tsx#L839)
63. 朋友发来的微信消息
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:894](../src/scenes/phone/P13_PhoneHome/index.tsx#L894)
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
   来源：[src/scenes/phone/registry.tsx:26](../src/scenes/phone/registry.tsx#L26)
87. 07:55 闹钟，振动+音效，关闭后进入起床场景。
   来源：[src/scenes/phone/registry.tsx:27](../src/scenes/phone/registry.tsx#L27)
88. 倒影对应点一
   来源：[src/scenes/rpg/RpgGameHost.tsx:233](../src/scenes/rpg/RpgGameHost.tsx#L233)
89. 旧木桩倒影
   来源：[src/scenes/rpg/RpgGameHost.tsx:234](../src/scenes/rpg/RpgGameHost.tsx#L234)
90. 鱼群水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:235](../src/scenes/rpg/RpgGameHost.tsx#L235)
91. 纸条本体水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:236](../src/scenes/rpg/RpgGameHost.tsx#L236)
92. 启真湖的行程还没开始,现在拍不了。
   来源：[src/scenes/rpg/RpgGameHost.tsx:239](../src/scenes/rpg/RpgGameHost.tsx#L239)
93. 黑天鹅正追着船尾,顾不上拍照。
   来源：[src/scenes/rpg/RpgGameHost.tsx:240](../src/scenes/rpg/RpgGameHost.tsx#L240)
94. 先完成上船教学,稳住船之后再打开相机。
   来源：[src/scenes/rpg/RpgGameHost.tsx:241](../src/scenes/rpg/RpgGameHost.tsx#L241)
95. 手柄已安装，自动走动已停止。请输入一次方向。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1468](../src/scenes/rpg/RpgGameHost.tsx#L1468)
96. 他还不知道自己是谁。先用部门黄页完成命名。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1469](../src/scenes/rpg/RpgGameHost.tsx#L1469)
97. 他还没有开始课外锻炼。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1470](../src/scenes/rpg/RpgGameHost.tsx#L1470)
98. 道具栏里没有手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1471](../src/scenes/rpg/RpgGameHost.tsx#L1471)
99. 204 讲台抽屉里的定位盘
   来源：[src/scenes/rpg/RpgInteractionContract.ts:790](../src/scenes/rpg/RpgInteractionContract.ts#L790)
100. 旧钟定位盘插槽
   来源：[src/scenes/rpg/RpgInteractionContract.ts:813](../src/scenes/rpg/RpgInteractionContract.ts#L813)
101. no\_response
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1338](../src/scenes/rpg/RpgInteractionContract.ts#L1338)
102. multiple\_responses
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1339](../src/scenes/rpg/RpgInteractionContract.ts#L1339)
103. invalid\_response
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1342](../src/scenes/rpg/RpgInteractionContract.ts#L1342)

## 跨章节与共用系统

1. 当前剧情条件已变化，请返回任务目标后重试。
   来源：[src/App.tsx:193](../src/App.tsx#L193)
2. 手机交互区
   来源：[src/App.tsx:430](../src/App.tsx#L430)
3. 加载中…
   来源：[src/App.tsx:444](../src/App.tsx#L444)；[src/App.tsx:513](../src/App.tsx#L513)
4. 地图交互区
   来源：[src/App.tsx:451](../src/App.tsx#L451)
5. Loading RPG runtime
   来源：[src/App.tsx:456](../src/App.tsx#L456)；[src/App.tsx:487](../src/App.tsx#L487)
6. 安中大楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
7. 白沙二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
8. 白沙三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
9. 白沙四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
10. 白沙一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
11. 宝港生活广场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
12. 北二门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
13. 北一门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
14. 碧峰二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
15. 碧峰三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
16. 碧峰四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
17. 碧峰五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
18. 碧峰一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
19. 变电站
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
20. 茶花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
21. 成均苑3幢（创B大楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
22. 翠柏二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
23. 翠柏三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
24. 翠柏四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
25. 翠柏一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
26. 大食堂停车场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
27. 待定
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
28. 丹阳二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
29. 丹阳六幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
30. 丹阳三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
31. 丹阳四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
32. 丹阳五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
33. 丹阳一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
34. 迪臣路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
35. 东7
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
36. 东二教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
37. 东二门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
38. 东六教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
39. 东三教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
40. 东三门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
41. 东四教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
42. 东田径场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
43. 东五教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
44. 东一教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
45. 东一门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
46. 动力中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
47. 动物中心楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
48. 段永平教学楼（北教）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
49. 段永平教学楼（北教学楼1号楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
50. 段永平教学楼（北教学楼2号楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
51. 段永平教学楼（北教学楼4号楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
52. 段永平生命科学研究交叉中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
53. 风雨操场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
54. 港湾家园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
55. 港湾家园29幢（大学生创业实训基地）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
56. 工程训练（金工）中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
57. 观通楼（农科教大楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
58. 桂花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
59. 海洋试验厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
60. 海洋与计算中心楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
61. 杭州市西湖区
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
62. 杭州市西湖区余杭塘路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
63. 杭州市西湖区余杭塘路866号
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
64. 湖滨路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
65. 华家池路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
66. 化学实验中心（周厚复楼）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
67. 化学试剂仓库
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
68. 机器人与智能装备
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
69. 基础交叉研究大楼（在建）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
70. 建工试验厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
71. 教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
72. 教学楼12
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
73. 金秀楼（校医院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
74. 开物苑（机械学院3幢）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
75. 看台
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
76. 蓝田二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
77. 蓝田六幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
78. 蓝田三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
79. 蓝田四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
80. 蓝田五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
81. 蓝田一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
82. 篮球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
83. 临湖餐厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
84. 留祥路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
85. 留学生公寓A楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
86. 留学生公寓B楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
87. 蒙民伟楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
88. 纳米楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
89. 南华园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
90. 农生环大楼A座（农学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
91. 农生环大楼B座（环资学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
92. 农生环大楼C座（农业生命环境学部、交叉平台）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
93. 农生环大楼D座（生工食品学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
94. 农生环大楼E座（动物科学学院）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
95. 农业科技创新试验中心D
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
96. 农业试验站A
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
97. 农业试验站B
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
98. 农业试验站C
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
99. 藕舫路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
100. 牌坊
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
101. 潘方仁求是馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
102. 匹克球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
103. 其他
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
104. 启真湖
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/data/phonePhotoCatalog.ts:130](../src/data/phonePhotoCatalog.ts#L130)；[src/scenes/phone/P15_Zjuding/index.tsx:1473](../src/scenes/phone/P15_Zjuding/index.tsx#L1473)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
105. 前沿学科综合大楼（来同馆）（在建）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
106. 青溪二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
107. 青溪三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
108. 青溪四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
109. 青溪一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
110. 求是大道
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
111. 求是大讲堂
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
112. 生科楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
113. 生物实验中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
114. 生物物理楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
115. 实验果园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
116. 实验室
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
117. 思睿桥
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
118. 泰和路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
119. 桃花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
120. 图书信息A楼（基础图书馆）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
121. 图书信息C楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
122. 万物母气鼎
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
123. 网球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
124. 西部发展研究院大楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
125. 西二教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
126. 西迁纪念亭
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
127. 西区动物中心A座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
128. 西区动物中心B座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
129. 西区动物中心C座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
130. 西区动物中心D座
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
131. 西三教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
132. 西四教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
133. 西田径场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
134. 西一教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
135. 小白楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
136. 校医院2号楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
137. 校友林小木屋
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
138. 校友楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
139. 行政服务办事大厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
140. 学生长廊
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
141. 学生综合楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
142. 亚运比赛馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
143. 亚运热身馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
144. 阳明桥
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
145. 药学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
146. 医学教学楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
147. 医学科研楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
148. 医学院科研楼辅楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
149. 医学专业图书馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
150. 医学综合楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
151. 宜山环路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
152. 音乐厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
153. 银泉1幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
154. 银泉3幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
155. 银泉5幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
156. 银泉餐厅
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
157. 银泉学生服务中心
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
158. 樱花苑
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
159. 咏曼阁（临水报告厅）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
160. 游泳馆
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
161. 余杭塘路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
162. 羽毛球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
163. 月牙楼
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/data/phonePhotoCatalog.ts:142](../src/data/phonePhotoCatalog.ts#L142)；[src/scenes/rpg/ZijingangCampusLayout.ts:135](../src/scenes/rpg/ZijingangCampusLayout.ts#L135)
164. 浙江大学动物医院
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
165. 浙江省杭州市西湖区浙江大学药学院鑫药创制园
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
166. 竺可桢像
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
167. 主图书馆（浙江大学校史校情馆）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
168. 紫金港剧场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
169. 紫金港食堂（东区）
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
170. 紫金港校区
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)；[src/data/phonePhotoCatalog.ts:118](../src/data/phonePhotoCatalog.ts#L118)
171. 紫金港校区北门门卫房
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
172. 紫金港校区东二门
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
173. 紫金港校区求是物业苗圃玻璃房
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
174. 紫荆花路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
175. 紫云二幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
176. 紫云三幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
177. 紫云四幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
178. 紫云五幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
179. 紫云一幢
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
180. 足球场
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
181. 遵义西路
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
182. urn:ogc:def:crs:EPSG::32651
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
183. X图书馆1(1).jpg
   来源：[src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json:1](../src/assets/rpg/campus/source/zijingang_official_hotspots_reference.json#L1)
184. 教学楼单电梯门六档动画
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4153](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4153)
185. 启真湖至教学楼拱廊
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4377](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4377)
186. 只用于启真湖追逐结束后的低机位纸条追踪序幕。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4381](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4381)
187. 一楼门厅与迈斯威
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4403](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4403)
188. 承担旧版入楼、气流轨迹教学、纸张干燥与整楼复位演出。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4407](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4407)
189. 楼梯间
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4430](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4430)
190. 历史楼梯间环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4434](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4434)
191. 电梯竖向交通核
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4454](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4454)
192. 历史电梯交通核环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4458](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4458)
193. 二楼开放自习与活动区
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4480](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4480)
194. 历史二楼活动区环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4484](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4484)
195. N3-214 智慧教室
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4507](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4507)
196. 历史终局教室环境参考。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4511](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4511)
197. 教学楼 1F · 麦思威与校友廊
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4534](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4534)
198. 三层正式母图之前的历史教学楼一层图。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4538](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4538)
199. 教学楼 2F · 教室与开放学习区
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4559](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4559)
200. 三层正式母图之前的历史教学楼二层图。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4563](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4563)
201. 教学楼 3F · 校友荣誉门厅
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4584](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4584)
202. 三层正式母图之前的历史教学楼三层图。
   来源：[src/assets/rpg/interiors/finale/finale_environment_manifest.json:4588](../src/assets/rpg/interiors/finale/finale_environment_manifest.json#L4588)
203. campus\_wifi
   来源：[src/components/ControlCenter.tsx:46](../src/components/ControlCenter.tsx#L46)
204. 已连接 ZJUWLAN，网络切换消耗 1% 电量。
   来源：[src/components/ControlCenter.tsx:47](../src/components/ControlCenter.tsx#L47)
205. 已切换到移动数据，网络切换消耗 1% 电量。
   来源：[src/components/ControlCenter.tsx:48](../src/components/ControlCenter.tsx#L48)
206. 低电量模式下音乐已暂停。关闭低电量模式后可以播放。
   来源：[src/components/ControlCenter.tsx:55](../src/components/ControlCenter.tsx#L55)
207. task
   来源：[src/components/ControlCenter.tsx:55](../src/components/ControlCenter.tsx#L55)；[src/components/ControlCenter.tsx:77](../src/components/ControlCenter.tsx#L77)；[src/components/ControlCenter.tsx:139](../src/components/ControlCenter.tsx#L139)；[src/components/InventoryBar.tsx:431](../src/components/InventoryBar.tsx#L431)；[src/scenes/phone/P02_CC98/index.tsx:338](../src/scenes/phone/P02_CC98/index.tsx#L338)；[src/scenes/phone/P02_CC98/index.tsx:741](../src/scenes/phone/P02_CC98/index.tsx#L741)；[src/scenes/phone/P07_Weather/index.tsx:85](../src/scenes/phone/P07_Weather/index.tsx#L85)；[src/scenes/phone/P13_PhoneHome/index.tsx:144](../src/scenes/phone/P13_PhoneHome/index.tsx#L144)；[src/scenes/phone/P13_PhoneHome/index.tsx:189](../src/scenes/phone/P13_PhoneHome/index.tsx#L189)；[src/scenes/phone/P13_PhoneHome/index.tsx:370](../src/scenes/phone/P13_PhoneHome/index.tsx#L370)；[src/scenes/phone/P13_PhoneHome/index.tsx:392](../src/scenes/phone/P13_PhoneHome/index.tsx#L392)；[src/scenes/phone/P14_Wechat/index.tsx:236](../src/scenes/phone/P14_Wechat/index.tsx#L236)；[src/scenes/phone/P14_Wechat/index.tsx:363](../src/scenes/phone/P14_Wechat/index.tsx#L363)；[src/scenes/phone/P14_Wechat/index.tsx:443](../src/scenes/phone/P14_Wechat/index.tsx#L443)；[src/scenes/phone/P14_Wechat/index.tsx:509](../src/scenes/phone/P14_Wechat/index.tsx#L509)；[src/scenes/phone/P15_Zjuding/index.tsx:655](../src/scenes/phone/P15_Zjuding/index.tsx#L655)；[src/scenes/phone/P15_Zjuding/index.tsx:948](../src/scenes/phone/P15_Zjuding/index.tsx#L948)；[src/scenes/phone/P15_Zjuding/index.tsx:952](../src/scenes/phone/P15_Zjuding/index.tsx#L952)；[src/scenes/phone/P15_Zjuding/index.tsx:955](../src/scenes/phone/P15_Zjuding/index.tsx#L955)；[src/scenes/phone/P15_Zjuding/index.tsx:1054](../src/scenes/phone/P15_Zjuding/index.tsx#L1054)
208. 耳机安静地挂着，不理你。
   来源：[src/components/ControlCenter.tsx:66](../src/components/ControlCenter.tsx#L66)
209. 耳机掉了下来，背面朝下。
   来源：[src/components/ControlCenter.tsx:77](../src/components/ControlCenter.tsx#L77)
210. 自动旋转已关闭。
   来源：[src/components/ControlCenter.tsx:134](../src/components/ControlCenter.tsx#L134)
211. 自动旋转已开启。
   来源：[src/components/ControlCenter.tsx:134](../src/components/ControlCenter.tsx#L134)
212. 存档写入失败，请检查浏览器存储权限。
   来源：[src/components/ControlCenter.tsx:139](../src/components/ControlCenter.tsx#L139)
213. 进度已保存。
   来源：[src/components/ControlCenter.tsx:139](../src/components/ControlCenter.tsx#L139)
214. 控制中心
   来源：[src/components/ControlCenter.tsx:156](../src/components/ControlCenter.tsx#L156)；[src/scenes/phone/P08_Settings/index.tsx:36](../src/scenes/phone/P08_Settings/index.tsx#L36)
215. 关闭控制中心
   来源：[src/components/ControlCenter.tsx:157](../src/components/ControlCenter.tsx#L157)
216. 7月9日 周四
   来源：[src/components/ControlCenter.tsx:160](../src/components/ControlCenter.tsx#L160)
217. 收起
   来源：[src/components/ControlCenter.tsx:161](../src/components/ControlCenter.tsx#L161)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:352](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L352)
218. 未连接
   来源：[src/components/ControlCenter.tsx:180](../src/components/ControlCenter.tsx#L180)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
219. 已连接
   来源：[src/components/ControlCenter.tsx:180](../src/components/ControlCenter.tsx#L180)
220. 移动数据
   来源：[src/components/ControlCenter.tsx:196](../src/components/ControlCenter.tsx#L196)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
221. 使用中
   来源：[src/components/ControlCenter.tsx:197](../src/components/ControlCenter.tsx#L197)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
222. 已关闭
   来源：[src/components/ControlCenter.tsx:197](../src/components/ControlCenter.tsx#L197)
223. music
   来源：[src/components/ControlCenter.tsx:205](../src/components/ControlCenter.tsx#L205)
224. 未在播放
   来源：[src/components/ControlCenter.tsx:206](../src/components/ControlCenter.tsx#L206)
225. 正在播放：早八进行曲
   来源：[src/components/ControlCenter.tsx:206](../src/components/ControlCenter.tsx#L206)
226. 播放音乐
   来源：[src/components/ControlCenter.tsx:209](../src/components/ControlCenter.tsx#L209)
227. 暂停
   来源：[src/components/ControlCenter.tsx:209](../src/components/ControlCenter.tsx#L209)
228. 耳机
   来源：[src/components/ControlCenter.tsx:217](../src/components/ControlCenter.tsx#L217)；[src/data/items.config.json:11](../src/data/items.config.json#L11)
229. headphone
   来源：[src/components/ControlCenter.tsx:219](../src/components/ControlCenter.tsx#L219)
230. 耳机不见了
   来源：[src/components/ControlCenter.tsx:222](../src/components/ControlCenter.tsx#L222)
231. 亮度
   来源：[src/components/ControlCenter.tsx:231](../src/components/ControlCenter.tsx#L231)
232. sun
   来源：[src/components/ControlCenter.tsx:255](../src/components/ControlCenter.tsx#L255)
233. 自动旋转
   来源：[src/components/ControlCenter.tsx:270](../src/components/ControlCenter.tsx#L270)
234. 振动一直开着。它见证了闹钟的一切。
   来源：[src/components/ControlCenter.tsx:272](../src/components/ControlCenter.tsx#L272)
235. 振动
   来源：[src/components/ControlCenter.tsx:276](../src/components/ControlCenter.tsx#L276)
236. 飞行模式？你连教室都飞不到。
   来源：[src/components/ControlCenter.tsx:278](../src/components/ControlCenter.tsx#L278)
237. 飞行模式
   来源：[src/components/ControlCenter.tsx:282](../src/components/ControlCenter.tsx#L282)
238. 勿扰模式无法阻挡早八。
   来源：[src/components/ControlCenter.tsx:284](../src/components/ControlCenter.tsx#L284)
239. 勿扰
   来源：[src/components/ControlCenter.tsx:288](../src/components/ControlCenter.tsx#L288)
240. 电量管理
   来源：[src/components/ControlCenter.tsx:294](../src/components/ControlCenter.tsx#L294)
241. 电池
   来源：[src/components/ControlCenter.tsx:298](../src/components/ControlCenter.tsx#L298)
242. / 次
   来源：[src/components/ControlCenter.tsx:299](../src/components/ControlCenter.tsx#L299)
243. 打开应用：
   来源：[src/components/ControlCenter.tsx:299](../src/components/ControlCenter.tsx#L299)
244. 手机电量
   来源：[src/components/ControlCenter.tsx:306](../src/components/ControlCenter.tsx#L306)
245. 关闭低电量模式
   来源：[src/components/ControlCenter.tsx:319](../src/components/ControlCenter.tsx#L319)
246. 开启低电量模式
   来源：[src/components/ControlCenter.tsx:319](../src/components/ControlCenter.tsx#L319)
247. 恢复每次 2% 耗电
   来源：[src/components/ControlCenter.tsx:320](../src/components/ControlCenter.tsx#L320)
248. 每次只耗 1%；亮度限至 45%，暂停音乐
   来源：[src/components/ControlCenter.tsx:320](../src/components/ControlCenter.tsx#L320)
249. 剧场入口左侧设有充电服务站，需走到设备旁接线。
   来源：[src/components/ControlCenter.tsx:324](../src/components/ControlCenter.tsx#L324)
250. 充电需要在现场与充电服务站交互。
   来源：[src/components/ControlCenter.tsx:325](../src/components/ControlCenter.tsx#L325)
251. 1% 为任务保底电量，主线功能仍可使用。
   来源：[src/components/ControlCenter.tsx:328](../src/components/ControlCenter.tsx#L328)
252. 存档管理
   来源：[src/components/ControlCenter.tsx:332](../src/components/ControlCenter.tsx#L332)
253. 游戏进度
   来源：[src/components/ControlCenter.tsx:335](../src/components/ControlCenter.tsx#L335)
254. 自动保存已开启
   来源：[src/components/ControlCenter.tsx:336](../src/components/ControlCenter.tsx#L336)
255. 立即保存
   来源：[src/components/ControlCenter.tsx:342](../src/components/ControlCenter.tsx#L342)
256. 重置剧情进度
   来源：[src/components/ControlCenter.tsx:343](../src/components/ControlCenter.tsx#L343)
257. 将清除章节、道具和谜题进度。编辑过的 CC98 帖子会保留。
   来源：[src/components/ControlCenter.tsx:347](../src/components/ControlCenter.tsx#L347)
258. 取消
   来源：[src/components/ControlCenter.tsx:348](../src/components/ControlCenter.tsx#L348)
259. 确认重置
   来源：[src/components/ControlCenter.tsx:349](../src/components/ControlCenter.tsx#L349)
260. 系统
   来源：[src/components/GameSubtitleFrame.tsx:16](../src/components/GameSubtitleFrame.tsx#L16)；[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)；[src/scenes/phone/P15_Zjuding/index.tsx:2097](../src/scenes/phone/P15_Zjuding/index.tsx#L2097)
261. 旁白
   来源：[src/components/GameSubtitleFrame.tsx:17](../src/components/GameSubtitleFrame.tsx#L17)；[src/data/storyLines.ts:58](../src/data/storyLines.ts#L58)
262. 任务
   来源：[src/components/GameSubtitleFrame.tsx:18](../src/components/GameSubtitleFrame.tsx#L18)；[src/components/QuestClueStrip.tsx:185](../src/components/QuestClueStrip.tsx#L185)；[src/scenes/phone/P15_Zjuding/index.tsx:2014](../src/scenes/phone/P15_Zjuding/index.tsx#L2014)
263. 我
   来源：[src/components/GameSubtitleFrame.tsx:19](../src/components/GameSubtitleFrame.tsx#L19)；[src/scenes/phone/P02_CC98/index.tsx:200](../src/scenes/phone/P02_CC98/index.tsx#L200)；[src/scenes/phone/P15_Zjuding/index.tsx:2097](../src/scenes/phone/P15_Zjuding/index.tsx#L2097)
264. 记录
   来源：[src/components/GameSubtitleFrame.tsx:20](../src/components/GameSubtitleFrame.tsx#L20)；[src/data/cc98.posts.json:269](../src/data/cc98.posts.json#L269)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)；[src/data/cc98.posts.json:629](../src/data/cc98.posts.json#L629)；[src/data/cc98.posts.json:730](../src/data/cc98.posts.json#L730)
265. 提示
   来源：[src/components/GameSubtitleFrame.tsx:21](../src/components/GameSubtitleFrame.tsx#L21)；[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:940](../src/data/cc98.posts.json#L940)
266. 广播
   来源：[src/components/GameSubtitleFrame.tsx:22](../src/components/GameSubtitleFrame.tsx#L22)
267. 身份信息
   来源：[src/components/GameSubtitleFrame.tsx:37](../src/components/GameSubtitleFrame.tsx#L37)
268. 身份编号
   来源：[src/components/GameSubtitleFrame.tsx:38](../src/components/GameSubtitleFrame.tsx#L38)
269. game-subtitle-frame subtitle-tone-{{tone}} {{timed ? "is-timed" : "is-line-entering"}} {{className}}
   来源：[src/components/GameSubtitleFrame.tsx:57](../src/components/GameSubtitleFrame.tsx#L57)
270. {{ITEM\_META\[next\].name}}：{{ITEM\_META\[next\].desc}}
   来源：[src/components/InventoryBar.tsx:419](../src/components/InventoryBar.tsx#L419)
271. 合成成功：{{ITEM\_META\[result\].name}}！
   来源：[src/components/InventoryBar.tsx:431](../src/components/InventoryBar.tsx#L431)
272. 它们拒绝合作。
   来源：[src/components/InventoryBar.tsx:434](../src/components/InventoryBar.tsx#L434)
273. 已放到目标上，正在处理。
   来源：[src/components/InventoryBar.tsx:443](../src/components/InventoryBar.tsx#L443)
274. 道具未放到目标上。
   来源：[src/components/InventoryBar.tsx:448](../src/components/InventoryBar.tsx#L448)；[src/scenes/rpg/RpgInventoryDock.tsx:105](../src/scenes/rpg/RpgInventoryDock.tsx#L105)
275. 物品栏
   来源：[src/components/InventoryBar.tsx:499](../src/components/InventoryBar.tsx#L499)
276. 收起物品栏
   来源：[src/components/InventoryBar.tsx:518](../src/components/InventoryBar.tsx#L518)
277. 展开物品栏
   来源：[src/components/InventoryBar.tsx:518](../src/components/InventoryBar.tsx#L518)
278. backpack
   来源：[src/components/InventoryBar.tsx:520](../src/components/InventoryBar.tsx#L520)
279. 空空如也
   来源：[src/components/InventoryBar.tsx:535](../src/components/InventoryBar.tsx#L535)
280. 道具：{{ITEM\_META\[item\].name}}，{{isPaperItem(item) ? "点击展开内容" : "空格选中，Enter 查看详情"}}
   来源：[src/components/InventoryBar.tsx:544](../src/components/InventoryBar.tsx#L544)
281. 并行调查
   来源：[src/components/InvestigationRing.tsx:54](../src/components/InvestigationRing.tsx#L54)
282. 各节点可以任意顺序处理
   来源：[src/components/InvestigationRing.tsx:55](../src/components/InvestigationRing.tsx#L55)
283. 已完成 {{completed}} 项，共 {{total}} 项
   来源：[src/components/InvestigationRing.tsx:120](../src/components/InvestigationRing.tsx#L120)
284. 尚有未查
   来源：[src/components/InvestigationRing.tsx:140](../src/components/InvestigationRing.tsx#L140)
285. 已查齐
   来源：[src/components/InvestigationRing.tsx:140](../src/components/InvestigationRing.tsx#L140)
286. {{node.label}}，{{node.statusLabel}}{{node.detail ? \`，${node.detail}\` : ""}}
   来源：[src/components/InvestigationRing.tsx:160](../src/components/InvestigationRing.tsx#L160)
287. 环境材料
   来源：[src/components/ItemInspectDialog.tsx:34](../src/components/ItemInspectDialog.tsx#L34)
288. 主屏早八雨滴
   来源：[src/components/ItemInspectDialog.tsx:35](../src/components/ItemInspectDialog.tsx#L35)
289. 容器素材
   来源：[src/components/ItemInspectDialog.tsx:38](../src/components/ItemInspectDialog.tsx#L38)
290. 控制中心音乐模块
   来源：[src/components/ItemInspectDialog.tsx:39](../src/components/ItemInspectDialog.tsx#L39)
291. 合成道具
   来源：[src/components/ItemInspectDialog.tsx:42](../src/components/ItemInspectDialog.tsx#L42)
292. 耳机 + 水滴
   来源：[src/components/ItemInspectDialog.tsx:43](../src/components/ItemInspectDialog.tsx#L43)
293. 机械素材
   来源：[src/components/ItemInspectDialog.tsx:46](../src/components/ItemInspectDialog.tsx#L46)
294. 主屏设置齿轮背面
   来源：[src/components/ItemInspectDialog.tsx:47](../src/components/ItemInspectDialog.tsx#L47)
295. 图形素材
   来源：[src/components/ItemInspectDialog.tsx:50](../src/components/ItemInspectDialog.tsx#L50)；[src/components/ItemInspectDialog.tsx:66](../src/components/ItemInspectDialog.tsx#L66)；[src/components/ItemInspectDialog.tsx:74](../src/components/ItemInspectDialog.tsx#L74)
296. 朋友头像掉落的一撇
   来源：[src/components/ItemInspectDialog.tsx:51](../src/components/ItemInspectDialog.tsx#L51)
297. 解锁工具
   来源：[src/components/ItemInspectDialog.tsx:54](../src/components/ItemInspectDialog.tsx#L54)；[src/components/ItemInspectDialog.tsx:223](../src/components/ItemInspectDialog.tsx#L223)
298. 斜线 + 反转齿轮
   来源：[src/components/ItemInspectDialog.tsx:55](../src/components/ItemInspectDialog.tsx#L55)
299. 植物材料
   来源：[src/components/ItemInspectDialog.tsx:58](../src/components/ItemInspectDialog.tsx#L58)
300. 塔楼机关奖励
   来源：[src/components/ItemInspectDialog.tsx:59](../src/components/ItemInspectDialog.tsx#L59)
301. 身份凭证
   来源：[src/components/ItemInspectDialog.tsx:62](../src/components/ItemInspectDialog.tsx#L62)
302. 寝室右侧书桌 / 电子校园卡
   来源：[src/components/ItemInspectDialog.tsx:63](../src/components/ItemInspectDialog.tsx#L63)
303. 主页推送头像
   来源：[src/components/ItemInspectDialog.tsx:67](../src/components/ItemInspectDialog.tsx#L67)
304. 功能材料
   来源：[src/components/ItemInspectDialog.tsx:70](../src/components/ItemInspectDialog.tsx#L70)
305. 天气页面
   来源：[src/components/ItemInspectDialog.tsx:71](../src/components/ItemInspectDialog.tsx#L71)
306. 导师头像掉落的一竖
   来源：[src/components/ItemInspectDialog.tsx:75](../src/components/ItemInspectDialog.tsx#L75)
307. 位移工具
   来源：[src/components/ItemInspectDialog.tsx:78](../src/components/ItemInspectDialog.tsx#L78)
308. 三角形 + 竖线
   来源：[src/components/ItemInspectDialog.tsx:79](../src/components/ItemInspectDialog.tsx#L79)
309. 控制设备
   来源：[src/components/ItemInspectDialog.tsx:82](../src/components/ItemInspectDialog.tsx#L82)
310. CC98 二手市场
   来源：[src/components/ItemInspectDialog.tsx:83](../src/components/ItemInspectDialog.tsx#L83)
311. 调查证据
   来源：[src/components/ItemInspectDialog.tsx:86](../src/components/ItemInspectDialog.tsx#L86)
312. 图书馆 022 座位旁
   来源：[src/components/ItemInspectDialog.tsx:87](../src/components/ItemInspectDialog.tsx#L87)
313. 检索线索
   来源：[src/components/ItemInspectDialog.tsx:90](../src/components/ItemInspectDialog.tsx#L90)
314. 浙大钉馆藏检索结果
   来源：[src/components/ItemInspectDialog.tsx:91](../src/components/ItemInspectDialog.tsx#L91)
315. 公开证据
   来源：[src/components/ItemInspectDialog.tsx:94](../src/components/ItemInspectDialog.tsx#L94)
316. 图书馆 755 书架夹层
   来源：[src/components/ItemInspectDialog.tsx:95](../src/components/ItemInspectDialog.tsx#L95)
317. 机器报告
   来源：[src/components/ItemInspectDialog.tsx:98](../src/components/ItemInspectDialog.tsx#L98)
318. 照片识别结果
   来源：[src/components/ItemInspectDialog.tsx:99](../src/components/ItemInspectDialog.tsx#L99)
319. 认证证明
   来源：[src/components/ItemInspectDialog.tsx:102](../src/components/ItemInspectDialog.tsx#L102)
320. 物品身份盖章机
   来源：[src/components/ItemInspectDialog.tsx:103](../src/components/ItemInspectDialog.tsx#L103)
321. 座位凭据
   来源：[src/components/ItemInspectDialog.tsx:106](../src/components/ItemInspectDialog.tsx#L106)
322. 022 桌面夹缝
   来源：[src/components/ItemInspectDialog.tsx:107](../src/components/ItemInspectDialog.tsx#L107)；[src/scenes/rpg/RpgItemUseGuidance.ts:156](../src/scenes/rpg/RpgItemUseGuidance.ts#L156)
323. 到场证明
   来源：[src/components/ItemInspectDialog.tsx:110](../src/components/ItemInspectDialog.tsx#L110)
324. 浙大体艺访问记录
   来源：[src/components/ItemInspectDialog.tsx:111](../src/components/ItemInspectDialog.tsx#L111)
325. 执行凭证
   来源：[src/components/ItemInspectDialog.tsx:114](../src/components/ItemInspectDialog.tsx#L114)
326. 022 恢复申请签发
   来源：[src/components/ItemInspectDialog.tsx:115](../src/components/ItemInspectDialog.tsx#L115)
327. 餐盘回收费 2.00 元
   来源：[src/components/ItemInspectDialog.tsx:118](../src/components/ItemInspectDialog.tsx#L118)；[src/data/items.config.json:151](../src/data/items.config.json#L151)
328. 餐盘回收
   来源：[src/components/ItemInspectDialog.tsx:119](../src/components/ItemInspectDialog.tsx#L119)
329. 油渍纸巾
   来源：[src/components/ItemInspectDialog.tsx:122](../src/components/ItemInspectDialog.tsx#L122)；[src/data/items.config.json:158](../src/data/items.config.json#L158)
330. 食堂收餐口阿姨
   来源：[src/components/ItemInspectDialog.tsx:123](../src/components/ItemInspectDialog.tsx#L123)
331. 调配原料 · 蓝色
   来源：[src/components/ItemInspectDialog.tsx:126](../src/components/ItemInspectDialog.tsx#L126)
332. 食堂饮料区
   来源：[src/components/ItemInspectDialog.tsx:127](../src/components/ItemInspectDialog.tsx#L127)；[src/components/ItemInspectDialog.tsx:131](../src/components/ItemInspectDialog.tsx#L131)；[src/components/ItemInspectDialog.tsx:135](../src/components/ItemInspectDialog.tsx#L135)
333. 调配原料 · 白色
   来源：[src/components/ItemInspectDialog.tsx:130](../src/components/ItemInspectDialog.tsx#L130)
334. 调配原料 · 黑色
   来源：[src/components/ItemInspectDialog.tsx:134](../src/components/ItemInspectDialog.tsx#L134)
335. 失败饮品
   来源：[src/components/ItemInspectDialog.tsx:138](../src/components/ItemInspectDialog.tsx#L138)
336. 食堂混合台
   来源：[src/components/ItemInspectDialog.tsx:139](../src/components/ItemInspectDialog.tsx#L139)；[src/components/ItemInspectDialog.tsx:144](../src/components/ItemInspectDialog.tsx#L144)
337. 可以自己喝掉。试饮杯位不收这一杯。
   来源：[src/components/ItemInspectDialog.tsx:140](../src/components/ItemInspectDialog.tsx#L140)
338. 今日新品
   来源：[src/components/ItemInspectDialog.tsx:143](../src/components/ItemInspectDialog.tsx#L143)
339. 宣传板下空着一个杯位。洒出的泡沫有些黏。
   来源：[src/components/ItemInspectDialog.tsx:145](../src/components/ItemInspectDialog.tsx#L145)
340. 0755 取餐号
   来源：[src/components/ItemInspectDialog.tsx:148](../src/components/ItemInspectDialog.tsx#L148)；[src/data/itemCatalog.ts:138](../src/data/itemCatalog.ts#L138)；[src/data/items.config.json:200](../src/data/items.config.json#L200)
341. 点餐机
   来源：[src/components/ItemInspectDialog.tsx:149](../src/components/ItemInspectDialog.tsx#L149)
342. 餐品
   来源：[src/components/ItemInspectDialog.tsx:151](../src/components/ItemInspectDialog.tsx#L151)；[src/components/ItemInspectDialog.tsx:152](../src/components/ItemInspectDialog.tsx#L152)；[src/components/ItemInspectDialog.tsx:153](../src/components/ItemInspectDialog.tsx#L153)；[src/components/ItemInspectDialog.tsx:154](../src/components/ItemInspectDialog.tsx#L154)
343. 食堂取餐窗口
   来源：[src/components/ItemInspectDialog.tsx:151](../src/components/ItemInspectDialog.tsx#L151)；[src/components/ItemInspectDialog.tsx:152](../src/components/ItemInspectDialog.tsx#L152)；[src/components/ItemInspectDialog.tsx:153](../src/components/ItemInspectDialog.tsx#L153)；[src/components/ItemInspectDialog.tsx:154](../src/components/ItemInspectDialog.tsx#L154)
344. 半张剧院票根 A
   来源：[src/components/ItemInspectDialog.tsx:156](../src/components/ItemInspectDialog.tsx#L156)；[src/data/items.config.json:235](../src/data/items.config.json#L235)
345. 剧院海报栏
   来源：[src/components/ItemInspectDialog.tsx:157](../src/components/ItemInspectDialog.tsx#L157)
346. 半张剧院票根 B
   来源：[src/components/ItemInspectDialog.tsx:160](../src/components/ItemInspectDialog.tsx#L160)；[src/data/items.config.json:242](../src/data/items.config.json#L242)
347. 剧院取票机
   来源：[src/components/ItemInspectDialog.tsx:161](../src/components/ItemInspectDialog.tsx#L161)
348. 临时观演票
   来源：[src/components/ItemInspectDialog.tsx:164](../src/components/ItemInspectDialog.tsx#L164)；[src/data/items.config.json:249](../src/data/items.config.json#L249)；[src/modules/InventoryController.ts:16](../src/modules/InventoryController.ts#L16)
349. 两张半票根
   来源：[src/components/ItemInspectDialog.tsx:165](../src/components/ItemInspectDialog.tsx#L165)
350. 节目单残页
   来源：[src/components/ItemInspectDialog.tsx:168](../src/components/ItemInspectDialog.tsx#L168)；[src/components/ItemInspectDialog.tsx:172](../src/components/ItemInspectDialog.tsx#L172)；[src/components/ItemInspectDialog.tsx:176](../src/components/ItemInspectDialog.tsx#L176)
351. 剧院座席
   来源：[src/components/ItemInspectDialog.tsx:169](../src/components/ItemInspectDialog.tsx#L169)；[src/components/ItemInspectDialog.tsx:173](../src/components/ItemInspectDialog.tsx#L173)；[src/components/ItemInspectDialog.tsx:177](../src/components/ItemInspectDialog.tsx#L177)
352. 追光灯遥控器
   来源：[src/components/ItemInspectDialog.tsx:180](../src/components/ItemInspectDialog.tsx#L180)；[src/data/items.config.json:277](../src/data/items.config.json#L277)
353. 剧院灯控台
   来源：[src/components/ItemInspectDialog.tsx:181](../src/components/ItemInspectDialog.tsx#L181)
354. 荧光粉刷
   来源：[src/components/ItemInspectDialog.tsx:184](../src/components/ItemInspectDialog.tsx#L184)；[src/data/items.config.json:284](../src/data/items.config.json#L284)
355. 后台道具箱
   来源：[src/components/ItemInspectDialog.tsx:185](../src/components/ItemInspectDialog.tsx#L185)
356. 假纸条
   来源：[src/components/ItemInspectDialog.tsx:188](../src/components/ItemInspectDialog.tsx#L188)；[src/data/items.config.json:291](../src/data/items.config.json#L291)
357. 剧院追光灯下
   来源：[src/components/ItemInspectDialog.tsx:189](../src/components/ItemInspectDialog.tsx#L189)
358. 纸角能穿过鱼钩，泡过水后仍能保持形状。
   来源：[src/components/ItemInspectDialog.tsx:190](../src/components/ItemInspectDialog.tsx#L190)
359. 湿掉的节目单
   来源：[src/components/ItemInspectDialog.tsx:193](../src/components/ItemInspectDialog.tsx#L193)；[src/data/itemCatalog.ts:163](../src/data/itemCatalog.ts#L163)；[src/data/items.config.json:298](../src/data/items.config.json#L298)
360. 剧院舞台
   来源：[src/components/ItemInspectDialog.tsx:194](../src/components/ItemInspectDialog.tsx#L194)；[src/data/itemCatalog.ts:166](../src/data/itemCatalog.ts#L166)
361. 地点关键词
   来源：[src/components/ItemInspectDialog.tsx:197](../src/components/ItemInspectDialog.tsx#L197)；[src/components/ItemInspectDialog.tsx:201](../src/components/ItemInspectDialog.tsx#L201)；[src/components/ItemInspectDialog.tsx:205](../src/components/ItemInspectDialog.tsx#L205)
362. CC98 目击回复
   来源：[src/components/ItemInspectDialog.tsx:198](../src/components/ItemInspectDialog.tsx#L198)
363. 图书馆馆藏状态
   来源：[src/components/ItemInspectDialog.tsx:202](../src/components/ItemInspectDialog.tsx#L202)
364. 微信朋友消息
   来源：[src/components/ItemInspectDialog.tsx:206](../src/components/ItemInspectDialog.tsx#L206)
365. 场景坐标
   来源：[src/components/ItemInspectDialog.tsx:209](../src/components/ItemInspectDialog.tsx#L209)
366. 启真湖指示牌
   来源：[src/components/ItemInspectDialog.tsx:210](../src/components/ItemInspectDialog.tsx#L210)
367. 寝室电器
   来源：[src/components/ItemInspectDialog.tsx:213](../src/components/ItemInspectDialog.tsx#L213)
368. 个人书桌
   来源：[src/components/ItemInspectDialog.tsx:214](../src/components/ItemInspectDialog.tsx#L214)
369. 天气页面的云带会随风偏移。风向可以试着控制。
   来源：[src/components/ItemInspectDialog.tsx:215](../src/components/ItemInspectDialog.tsx#L215)
370. 湖面工具
   来源：[src/components/ItemInspectDialog.tsx:218](../src/components/ItemInspectDialog.tsx#L218)
371. 启真湖浮排边
   来源：[src/components/ItemInspectDialog.tsx:219](../src/components/ItemInspectDialog.tsx#L219)
372. 竿梢和鱼钩都在，钓线末端还能系东西。
   来源：[src/components/ItemInspectDialog.tsx:220](../src/components/ItemInspectDialog.tsx#L220)
373. 启真湖开放水域钓点
   来源：[src/components/ItemInspectDialog.tsx:224](../src/components/ItemInspectDialog.tsx#L224)；[src/components/ItemInspectDialog.tsx:234](../src/components/ItemInspectDialog.tsx#L234)
374. 钥匙齿口较粗，适合码头那种旧锁。
   来源：[src/components/ItemInspectDialog.tsx:225](../src/components/ItemInspectDialog.tsx#L225)
375. 修复材料
   来源：[src/components/ItemInspectDialog.tsx:228](../src/components/ItemInspectDialog.tsx#L228)；[src/components/ItemInspectDialog.tsx:233](../src/components/ItemInspectDialog.tsx#L233)
376. 启真湖码头储物柜
   来源：[src/components/ItemInspectDialog.tsx:229](../src/components/ItemInspectDialog.tsx#L229)
377. 耐水，能穿过金属框边缘的小孔。
   来源：[src/components/ItemInspectDialog.tsx:230](../src/components/ItemInspectDialog.tsx#L230)
378. 框架没散，边缘还留着穿线孔。
   来源：[src/components/ItemInspectDialog.tsx:235](../src/components/ItemInspectDialog.tsx#L235)
379. 打捞工具
   来源：[src/components/ItemInspectDialog.tsx:238](../src/components/ItemInspectDialog.tsx#L238)
380. 尼龙绳 + 断裂网框
   来源：[src/components/ItemInspectDialog.tsx:239](../src/components/ItemInspectDialog.tsx#L239)
381. 网口比罐子宽，网兜能承重。
   来源：[src/components/ItemInspectDialog.tsx:240](../src/components/ItemInspectDialog.tsx#L240)
382. 密封容器
   来源：[src/components/ItemInspectDialog.tsx:243](../src/components/ItemInspectDialog.tsx#L243)
383. 启真湖水下打捞点
   来源：[src/components/ItemInspectDialog.tsx:244](../src/components/ItemInspectDialog.tsx#L244)
384. 罐盖边缘有缝，徒手打不开。
   来源：[src/components/ItemInspectDialog.tsx:245](../src/components/ItemInspectDialog.tsx#L245)
385. 投喂材料
   来源：[src/components/ItemInspectDialog.tsx:248](../src/components/ItemInspectDialog.tsx#L248)
386. 密封饲料罐
   来源：[src/components/ItemInspectDialog.tsx:249](../src/components/ItemInspectDialog.tsx#L249)；[src/data/items.config.json:375](../src/data/items.config.json#L375)
387. 少量颗粒落水后，附近的鱼会游过来。
   来源：[src/components/ItemInspectDialog.tsx:250](../src/components/ItemInspectDialog.tsx#L250)
388. 渔获
   来源：[src/components/ItemInspectDialog.tsx:253](../src/components/ItemInspectDialog.tsx#L253)
389. 启真湖鱼群钓点
   来源：[src/components/ItemInspectDialog.tsx:254](../src/components/ItemInspectDialog.tsx#L254)
390. 黑天鹅一直盯着这条鱼。
   来源：[src/components/ItemInspectDialog.tsx:255](../src/components/ItemInspectDialog.tsx#L255)
391. 磁吸附件
   来源：[src/components/ItemInspectDialog.tsx:258](../src/components/ItemInspectDialog.tsx#L258)
392. 启真湖黑天鹅
   来源：[src/components/ItemInspectDialog.tsx:259](../src/components/ItemInspectDialog.tsx#L259)
393. 磁扣后面留有穿线孔。
   来源：[src/components/ItemInspectDialog.tsx:260](../src/components/ItemInspectDialog.tsx#L260)
394. 组合工具
   来源：[src/components/ItemInspectDialog.tsx:263](../src/components/ItemInspectDialog.tsx#L263)
395. 钓竿 + 天鹅磁铁
   来源：[src/components/ItemInspectDialog.tsx:264](../src/components/ItemInspectDialog.tsx#L264)
396. 线末端能吸住小金属件，纸本身不导磁。
   来源：[src/components/ItemInspectDialog.tsx:265](../src/components/ItemInspectDialog.tsx#L265)
397. 签到材料
   来源：[src/components/ItemInspectDialog.tsx:268](../src/components/ItemInspectDialog.tsx#L268)
398. 教学楼公告栏前
   来源：[src/components/ItemInspectDialog.tsx:269](../src/components/ItemInspectDialog.tsx#L269)
399. 纸幅与签到槽相同，空栏还留着。
   来源：[src/components/ItemInspectDialog.tsx:270](../src/components/ItemInspectDialog.tsx#L270)
400. 钟表部件
   来源：[src/components/ItemInspectDialog.tsx:273](../src/components/ItemInspectDialog.tsx#L273)；[src/components/ItemInspectDialog.tsx:278](../src/components/ItemInspectDialog.tsx#L278)；[src/components/ItemInspectDialog.tsx:293](../src/components/ItemInspectDialog.tsx#L293)
401. 面包店传送带边缘
   来源：[src/components/ItemInspectDialog.tsx:274](../src/components/ItemInspectDialog.tsx#L274)
402. 尾部方孔与大厅旧钟的轴头一致。
   来源：[src/components/ItemInspectDialog.tsx:275](../src/components/ItemInspectDialog.tsx#L275)
403. 204 讲台抽屉
   来源：[src/components/ItemInspectDialog.tsx:279](../src/components/ItemInspectDialog.tsx#L279)
404. 盘边的缺口与旧钟轴座对应。
   来源：[src/components/ItemInspectDialog.tsx:280](../src/components/ItemInspectDialog.tsx#L280)
405. 维修工具
   来源：[src/components/ItemInspectDialog.tsx:283](../src/components/ItemInspectDialog.tsx#L283)
406. 面包店后场
   来源：[src/components/ItemInspectDialog.tsx:284](../src/components/ItemInspectDialog.tsx#L284)
407. 扁头能插入薄金属盖板的缝。
   来源：[src/components/ItemInspectDialog.tsx:285](../src/components/ItemInspectDialog.tsx#L285)
408. 维修材料
   来源：[src/components/ItemInspectDialog.tsx:288](../src/components/ItemInspectDialog.tsx#L288)
409. 清洁车内侧
   来源：[src/components/ItemInspectDialog.tsx:289](../src/components/ItemInspectDialog.tsx#L289)
410. 适用于卡涩的轮轴和齿轮。
   来源：[src/components/ItemInspectDialog.tsx:290](../src/components/ItemInspectDialog.tsx#L290)
411. 202 阶梯教室座椅间
   来源：[src/components/ItemInspectDialog.tsx:294](../src/components/ItemInspectDialog.tsx#L294)
412. 分针底部的接口仍完整。大厅旧钟缺的就是这一件。
   来源：[src/components/ItemInspectDialog.tsx:295](../src/components/ItemInspectDialog.tsx#L295)
413. 关闭{{item.name}}详情
   来源：[src/components/ItemInspectDialog.tsx:398](../src/components/ItemInspectDialog.tsx#L398)
414. 分类
   来源：[src/components/ItemInspectDialog.tsx:416](../src/components/ItemInspectDialog.tsx#L416)；[src/data/cc98.posts.json:493](../src/data/cc98.posts.json#L493)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
415. 来源
   来源：[src/components/ItemInspectDialog.tsx:420](../src/components/ItemInspectDialog.tsx#L420)；[src/data/itemCatalog.ts:166](../src/data/itemCatalog.ts#L166)
416. 持卡人
   来源：[src/components/ItemInspectDialog.tsx:425](../src/components/ItemInspectDialog.tsx#L425)
417. 简介
   来源：[src/components/ItemInspectDialog.tsx:430](../src/components/ItemInspectDialog.tsx#L430)
418. 顺序：
   来源：[src/components/ItemInspectDialog.tsx:434](../src/components/ItemInspectDialog.tsx#L434)
419. 用途提示
   来源：[src/components/ItemInspectDialog.tsx:440](../src/components/ItemInspectDialog.tsx#L440)
420. {{item.name}}正文
   来源：[src/components/ItemInspectDialog.tsx:447](../src/components/ItemInspectDialog.tsx#L447)
421. 应用导航
   来源：[src/components/PhoneAppUi.tsx:109](../src/components/PhoneAppUi.tsx#L109)
422. QUICK PANEL
   来源：[src/components/PhoneAppUi.tsx:232](../src/components/PhoneAppUi.tsx#L232)
423. 关闭{{title}}
   来源：[src/components/PhoneAppUi.tsx:235](../src/components/PhoneAppUi.tsx#L235)
424. phone-app-feedback is-{{tone}} {{className}}
   来源：[src/components/PhoneAppUi.tsx:252](../src/components/PhoneAppUi.tsx#L252)
425. 7:55 scaled phone viewport
   来源：[src/components/PhoneShell.tsx:160](../src/components/PhoneShell.tsx#L160)
426. 7:55 phone runtime
   来源：[src/components/PhoneShell.tsx:162](../src/components/PhoneShell.tsx#L162)
427. 记录 A
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
428. 记录 B
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
429. 记录 C
   来源：[src/components/PresentationLayer.tsx:113](../src/components/PresentationLayer.tsx#L113)
430. 当前任务
   来源：[src/components/QuestClueStrip.tsx:165](../src/components/QuestClueStrip.tsx#L165)；[src/components/QuestClueStrip.tsx:208](../src/components/QuestClueStrip.tsx#L208)
431. {{CHAPTER\_LABEL\[quest.chapter\]}}当前任务：{{parallelObjective}}{{chapterFourAria}}{{showDigitHint ? \`。${digitHintAria}\` : ""}}。点击查看任务提示
   来源：[src/components/QuestClueStrip.tsx:172](../src/components/QuestClueStrip.tsx#L172)
432. 点击查看当前任务和提示
   来源：[src/components/QuestClueStrip.tsx:175](../src/components/QuestClueStrip.tsx#L175)
433. 收起任务
   来源：[src/components/QuestClueStrip.tsx:185](../src/components/QuestClueStrip.tsx#L185)
434. 签到码
   来源：[src/components/QuestClueStrip.tsx:186](../src/components/QuestClueStrip.tsx#L186)
435. 任务详情
   来源：[src/components/QuestClueStrip.tsx:197](../src/components/QuestClueStrip.tsx#L197)
436. 任务栏
   来源：[src/components/QuestClueStrip.tsx:202](../src/components/QuestClueStrip.tsx#L202)
437. 关闭任务详情
   来源：[src/components/QuestClueStrip.tsx:204](../src/components/QuestClueStrip.tsx#L204)
438. 并行调查 {{parallelProgress.completed}}/{{parallelProgress.total}}
   来源：[src/components/QuestClueStrip.tsx:215](../src/components/QuestClueStrip.tsx#L215)
439. 调查记录
   来源：[src/components/QuestClueStrip.tsx:217](../src/components/QuestClueStrip.tsx#L217)
440. 已查记录
   来源：[src/components/QuestClueStrip.tsx:220](../src/components/QuestClueStrip.tsx#L220)
441. 先查哪处都行；选中记录后返回现场查看
   来源：[src/components/QuestClueStrip.tsx:222](../src/components/QuestClueStrip.tsx#L222)
442. 先查哪项都行；方向键选择，回车或空格打开
   来源：[src/components/QuestClueStrip.tsx:223](../src/components/QuestClueStrip.tsx#L223)
443. completed
   来源：[src/components/QuestClueStrip.tsx:228](../src/components/QuestClueStrip.tsx#L228)；[src/core/QuestModel.ts:37](../src/core/QuestModel.ts#L37)
444. 可重新查看
   来源：[src/components/QuestClueStrip.tsx:229](../src/components/QuestClueStrip.tsx#L229)
445. 可直接开始
   来源：[src/components/QuestClueStrip.tsx:231](../src/components/QuestClueStrip.tsx#L231)
446. 就近调查
   来源：[src/components/QuestClueStrip.tsx:232](../src/components/QuestClueStrip.tsx#L232)
447. 待处理
   来源：[src/components/QuestClueStrip.tsx:234](../src/components/QuestClueStrip.tsx#L234)
448. 已完成
   来源：[src/components/QuestClueStrip.tsx:234](../src/components/QuestClueStrip.tsx#L234)；[src/scenes/rpg/RpgGameHost.tsx:2414](../src/scenes/rpg/RpgGameHost.tsx#L2414)
449. 第
   来源：[src/components/QuestClueStrip.tsx:301](../src/components/QuestClueStrip.tsx#L301)
450. 位
   来源：[src/components/QuestClueStrip.tsx:301](../src/components/QuestClueStrip.tsx#L301)；[src/scenes/phone/P15_Zjuding/index.tsx:1423](../src/scenes/phone/P15_Zjuding/index.tsx#L1423)；[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:76](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L76)
451. 任务提示
   来源：[src/components/QuestClueStrip.tsx:309](../src/components/QuestClueStrip.tsx#L309)；[src/components/QuestClueStrip.tsx:311](../src/components/QuestClueStrip.tsx#L311)
452. 当前任务没有提示。
   来源：[src/components/QuestClueStrip.tsx:314](../src/components/QuestClueStrip.tsx#L314)
453. 需要时点击下方按钮，逐条查看提示。
   来源：[src/components/QuestClueStrip.tsx:315](../src/components/QuestClueStrip.tsx#L315)
454. 提示已全部展开
   来源：[src/components/QuestClueStrip.tsx:325](../src/components/QuestClueStrip.tsx#L325)
455. 显示下一条提示
   来源：[src/components/QuestClueStrip.tsx:325](../src/components/QuestClueStrip.tsx#L325)
456. 校时表冠：按住并绕圈拖动以校时
   来源：[src/components/RpgClockCrownOverlay.tsx:88](../src/components/RpgClockCrownOverlay.tsx#L88)
457. Back to desktop
   来源：[src/components/ScenePlaceholder.tsx:24](../src/components/ScenePlaceholder.tsx#L24)
458. 流量
   来源：[src/components/StatusBar.tsx:61](../src/components/StatusBar.tsx#L61)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
459. 无服务
   来源：[src/components/StatusBar.tsx:71](../src/components/StatusBar.tsx#L71)
460. 手机充电服务站
   来源：[src/core/PhoneChargingStation.ts:7](../src/core/PhoneChargingStation.ts#L7)
461. active
   来源：[src/core/QuestModel.ts:37](../src/core/QuestModel.ts#L37)；[src/scenes/rpg/RpgGameHost.tsx:1477](../src/scenes/rpg/RpgGameHost.tsx#L1477)
462. locked
   来源：[src/core/QuestModel.ts:37](../src/core/QuestModel.ts#L37)；[src/modules/Cc98UnifiedLoginModel.ts:80](../src/modules/Cc98UnifiedLoginModel.ts#L80)；[src/scenes/phone/P02_CC98/index.tsx:332](../src/scenes/phone/P02_CC98/index.tsx#L332)；[src/scenes/rpg/BootScene.ts:572](../src/scenes/rpg/BootScene.ts#L572)；[src/scenes/rpg/RpgGameHost.tsx:1477](../src/scenes/rpg/RpgGameHost.tsx#L1477)；[src/scenes/rpg/RpgGameHost.tsx:1570](../src/scenes/rpg/RpgGameHost.tsx#L1570)；[src/scenes/rpg/RpgGameHost.tsx:1589](../src/scenes/rpg/RpgGameHost.tsx#L1589)；[src/scenes/rpg/RpgGameHost.tsx:1597](../src/scenes/rpg/RpgGameHost.tsx#L1597)；[src/scenes/rpg/RpgGameHost.tsx:1609](../src/scenes/rpg/RpgGameHost.tsx#L1609)；[src/scenes/rpg/RpgGameHost.tsx:1627](../src/scenes/rpg/RpgGameHost.tsx#L1627)；[src/scenes/rpg/RpgGameHost.tsx:1652](../src/scenes/rpg/RpgGameHost.tsx#L1652)；[src/scenes/rpg/RpgGameHost.tsx:1662](../src/scenes/rpg/RpgGameHost.tsx#L1662)；[src/scenes/rpg/RpgGameHost.tsx:1669](../src/scenes/rpg/RpgGameHost.tsx#L1669)；[src/scenes/rpg/RpgItemUseGuidance.ts:49](../src/scenes/rpg/RpgItemUseGuidance.ts#L49)
463. 在寝室找一件能用的设备
   来源：[src/core/QuestModel.ts:400](../src/core/QuestModel.ts#L400)
464. 检查自己的书桌。
   来源：[src/core/QuestModel.ts:401](../src/core/QuestModel.ts#L401)
465. 处理启真湖的天气记录
   来源：[src/core/QuestModel.ts:405](../src/core/QuestModel.ts#L405)
466. 打开手机天气页面。
   来源：[src/core/QuestModel.ts:406](../src/core/QuestModel.ts#L406)
467. 查看湖边三处线索 {{branchCount}}/3
   来源：[src/core/QuestModel.ts:431](../src/core/QuestModel.ts#L431)
468. 码头的柜门还锁着，附近水下有个小金属物。
   来源：[src/core/QuestModel.ts:432](../src/core/QuestModel.ts#L432)
469. 码头柜门已打开，尼龙绳收好了。
   来源：[src/core/QuestModel.ts:432](../src/core/QuestModel.ts#L432)
470. 木桩下的网框已经捞起。
   来源：[src/core/QuestModel.ts:433](../src/core/QuestModel.ts#L433)
471. 直河道旧木桩下，能看见框状物的轮廓。
   来源：[src/core/QuestModel.ts:433](../src/core/QuestModel.ts#L433)
472. 黑天鹅推来的磁性扣已经收好。
   来源：[src/core/QuestModel.ts:434](../src/core/QuestModel.ts#L434)
473. 天鹅围栏边留着旧饲料盒。
   来源：[src/core/QuestModel.ts:434](../src/core/QuestModel.ts#L434)
474. 这三处可以分头查看，先去哪处都行。
   来源：[src/core/QuestModel.ts:435](../src/core/QuestModel.ts#L435)
475. 把三件材料装到钓鱼竿上
   来源：[src/core/QuestModel.ts:438](../src/core/QuestModel.ts#L438)
476. 返回大湖面的最终钓具装配位。
   来源：[src/core/QuestModel.ts:439](../src/core/QuestModel.ts#L439)
477. 将尼龙绳、破损网框、磁性扣和钓鱼竿放入装配位。
   来源：[src/core/QuestModel.ts:440](../src/core/QuestModel.ts#L440)
478. 按货架顺序调配今日新品（{{hunt.drinkMixSequence.length}}/3）
   来源：[src/core/QuestModel.ts:494](../src/core/QuestModel.ts#L494)
479. 调配顺序能从饮料货架上找到。
   来源：[src/core/QuestModel.ts:495](../src/core/QuestModel.ts#L495)
480. 饮料机提供原料，调配台按倒入顺序记数。
   来源：[src/core/QuestModel.ts:495](../src/core/QuestModel.ts#L495)
481. 把今日新品气泡水放入宣传板空杯位
   来源：[src/core/QuestModel.ts:499](../src/core/QuestModel.ts#L499)
482. 目标位在第三窗口宣传板下方。
   来源：[src/core/QuestModel.ts:499](../src/core/QuestModel.ts#L499)
483. 等待第三列队伍让出位置
   来源：[src/core/QuestModel.ts:501](../src/core/QuestModel.ts#L501)
484. 看看菜单里有什么异常
   来源：[src/core/QuestModel.ts:506](../src/core/QuestModel.ts#L506)
485. 两种模式下，菜单有几个字不一样。
   来源：[src/core/QuestModel.ts:507](../src/core/QuestModel.ts#L507)
486. 深色观察看字，浅色操作下单。
   来源：[src/core/QuestModel.ts:507](../src/core/QuestModel.ts#L507)
487. 找到这张小票对应的窗口
   来源：[src/core/QuestModel.ts:513](../src/core/QuestModel.ts#L513)
488. 深色观察能听见残留的叫号；交票要用浅色操作。
   来源：[src/core/QuestModel.ts:514](../src/core/QuestModel.ts#L514)
489. 同一个号码，各窗口叫出的餐品未必相同。
   来源：[src/core/QuestModel.ts:514](../src/core/QuestModel.ts#L514)
490. 守住纸条可能逃离的出口（{{hunt.blockHits}}/3）
   来源：[src/core/QuestModel.ts:520](../src/core/QuestModel.ts#L520)
491. 空格键可以冲刺；纸条回头时路线会再次出现。
   来源：[src/core/QuestModel.ts:521](../src/core/QuestModel.ts#L521)
492. 浅色操作可推动当前路线上的餐盘车；深色观察可补充确认蓝色轨迹。
   来源：[src/core/QuestModel.ts:521](../src/core/QuestModel.ts#L521)
493. 回到交通核心，在仍有历史残影的楼层核对旧导视。
   来源：[src/core/QuestModel.ts:1181](../src/core/QuestModel.ts#L1181)
494. 郁闷小屋
   来源：[src/data/cc98.board-snapshots.json:5](../src/data/cc98.board-snapshots.json#L5)；[src/data/cc98.posts.json:7](../src/data/cc98.posts.json#L7)；[src/data/cc98.posts.json:25](../src/data/cc98.posts.json#L25)；[src/data/cc98.posts.json:43](../src/data/cc98.posts.json#L43)；[src/data/cc98.posts.json:61](../src/data/cc98.posts.json#L61)；[src/data/cc98.posts.json:79](../src/data/cc98.posts.json#L79)；[src/data/cc98.posts.json:97](../src/data/cc98.posts.json#L97)；[src/data/cc98.posts.json:115](../src/data/cc98.posts.json#L115)；[src/data/cc98.posts.json:133](../src/data/cc98.posts.json#L133)；[src/data/cc98.posts.json:151](../src/data/cc98.posts.json#L151)；[src/data/cc98.posts.json:169](../src/data/cc98.posts.json#L169)；[src/data/cc98.posts.json:187](../src/data/cc98.posts.json#L187)；[src/data/cc98.posts.json:205](../src/data/cc98.posts.json#L205)；[src/scenes/phone/P02_CC98/index.tsx:207](../src/scenes/phone/P02_CC98/index.tsx#L207)
495. CC98 114 板公开页面
   来源：[src/data/cc98.board-snapshots.json:7](../src/data/cc98.board-snapshots.json#L7)
496. 开怀一笑
   来源：[src/data/cc98.board-snapshots.json:14](../src/data/cc98.board-snapshots.json#L14)；[src/data/cc98.posts.json:223](../src/data/cc98.posts.json#L223)；[src/data/cc98.posts.json:241](../src/data/cc98.posts.json#L241)；[src/data/cc98.posts.json:259](../src/data/cc98.posts.json#L259)；[src/data/cc98.posts.json:277](../src/data/cc98.posts.json#L277)；[src/data/cc98.posts.json:295](../src/data/cc98.posts.json#L295)；[src/data/cc98.posts.json:313](../src/data/cc98.posts.json#L313)；[src/data/cc98.posts.json:331](../src/data/cc98.posts.json#L331)；[src/data/cc98.posts.json:349](../src/data/cc98.posts.json#L349)；[src/data/cc98.posts.json:367](../src/data/cc98.posts.json#L367)；[src/data/cc98.posts.json:385](../src/data/cc98.posts.json#L385)；[src/data/cc98.posts.json:403](../src/data/cc98.posts.json#L403)；[src/data/cc98.posts.json:421](../src/data/cc98.posts.json#L421)；[src/data/cc98.posts.json:834](../src/data/cc98.posts.json#L834)；[src/data/cc98.posts.json:853](../src/data/cc98.posts.json#L853)；[src/data/cc98.posts.json:948](../src/data/cc98.posts.json#L948)；[src/scenes/phone/P02_CC98/index.tsx:204](../src/scenes/phone/P02_CC98/index.tsx#L204)；[src/scenes/phone/P02_CC98/index.tsx:218](../src/scenes/phone/P02_CC98/index.tsx#L218)
497. CC98 135 板公开页面
   来源：[src/data/cc98.board-snapshots.json:16](../src/data/cc98.board-snapshots.json#L16)
498. 想把今天过完
   来源：[src/data/cc98.posts.json:4](../src/data/cc98.posts.json#L4)
499. 求一份能把今天过完的待办清单
   来源：[src/data/cc98.posts.json:8](../src/data/cc98.posts.json#L8)
500. 26-07-10 17:58
   来源：[src/data/cc98.posts.json:11](../src/data/cc98.posts.json#L11)
501. 桌面上摊着好几件事，越想一起做越动不了。现在打算只写三项：回一条必要消息、整理十分钟资料、按时去吃饭。还有人用过更小的清单吗？
   来源：[src/data/cc98.posts.json:12](../src/data/cc98.posts.json#L12)
502. 保留互助讨论
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
503. 楼主说明了当下能执行的范围
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)
504. 郁闷小屋值班台
   来源：[src/data/cc98.posts.json:13](../src/data/cc98.posts.json#L13)；[src/data/cc98.posts.json:31](../src/data/cc98.posts.json#L31)；[src/data/cc98.posts.json:49](../src/data/cc98.posts.json#L49)；[src/data/cc98.posts.json:67](../src/data/cc98.posts.json#L67)；[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)；[src/data/cc98.posts.json:103](../src/data/cc98.posts.json#L103)；[src/data/cc98.posts.json:121](../src/data/cc98.posts.json#L121)；[src/data/cc98.posts.json:139](../src/data/cc98.posts.json#L139)；[src/data/cc98.posts.json:157](../src/data/cc98.posts.json#L157)；[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)；[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)；[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
505. 2楼
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:34](../src/data/cc98.posts.json#L34)；[src/data/cc98.posts.json:52](../src/data/cc98.posts.json#L52)；[src/data/cc98.posts.json:70](../src/data/cc98.posts.json#L70)；[src/data/cc98.posts.json:88](../src/data/cc98.posts.json#L88)；[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:124](../src/data/cc98.posts.json#L124)；[src/data/cc98.posts.json:142](../src/data/cc98.posts.json#L142)；[src/data/cc98.posts.json:160](../src/data/cc98.posts.json#L160)；[src/data/cc98.posts.json:178](../src/data/cc98.posts.json#L178)；[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:232](../src/data/cc98.posts.json#L232)；[src/data/cc98.posts.json:250](../src/data/cc98.posts.json#L250)；[src/data/cc98.posts.json:268](../src/data/cc98.posts.json#L268)；[src/data/cc98.posts.json:286](../src/data/cc98.posts.json#L286)；[src/data/cc98.posts.json:304](../src/data/cc98.posts.json#L304)；[src/data/cc98.posts.json:322](../src/data/cc98.posts.json#L322)；[src/data/cc98.posts.json:340](../src/data/cc98.posts.json#L340)；[src/data/cc98.posts.json:358](../src/data/cc98.posts.json#L358)；[src/data/cc98.posts.json:376](../src/data/cc98.posts.json#L376)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)；[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:448](../src/data/cc98.posts.json#L448)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)；[src/data/cc98.posts.json:492](../src/data/cc98.posts.json#L492)；[src/data/cc98.posts.json:514](../src/data/cc98.posts.json#L514)；[src/data/cc98.posts.json:536](../src/data/cc98.posts.json#L536)；[src/data/cc98.posts.json:558](../src/data/cc98.posts.json#L558)；[src/data/cc98.posts.json:580](../src/data/cc98.posts.json#L580)；[src/data/cc98.posts.json:602](../src/data/cc98.posts.json#L602)；[src/data/cc98.posts.json:624](../src/data/cc98.posts.json#L624)；[src/data/cc98.posts.json:646](../src/data/cc98.posts.json#L646)；[src/data/cc98.posts.json:668](../src/data/cc98.posts.json#L668)；[src/data/cc98.posts.json:688](../src/data/cc98.posts.json#L688)；[src/data/cc98.posts.json:708](../src/data/cc98.posts.json#L708)；[src/data/cc98.posts.json:727](../src/data/cc98.posts.json#L727)；[src/data/cc98.posts.json:747](../src/data/cc98.posts.json#L747)；[src/data/cc98.posts.json:766](../src/data/cc98.posts.json#L766)；[src/data/cc98.posts.json:785](../src/data/cc98.posts.json#L785)；[src/data/cc98.posts.json:804](../src/data/cc98.posts.json#L804)；[src/data/cc98.posts.json:823](../src/data/cc98.posts.json#L823)；[src/data/cc98.posts.json:843](../src/data/cc98.posts.json#L843)；[src/data/cc98.posts.json:862](../src/data/cc98.posts.json#L862)；[src/data/cc98.posts.json:881](../src/data/cc98.posts.json#L881)；[src/data/cc98.posts.json:900](../src/data/cc98.posts.json#L900)；[src/data/cc98.posts.json:919](../src/data/cc98.posts.json#L919)；[src/data/cc98.posts.json:938](../src/data/cc98.posts.json#L938)；[src/data/cc98.posts.json:957](../src/data/cc98.posts.json#L957)；[src/data/cc98.posts.json:976](../src/data/cc98.posts.json#L976)；[src/data/cc98.posts.json:995](../src/data/cc98.posts.json#L995)；[src/scenes/phone/P02_CC98/index.tsx:126](../src/scenes/phone/P02_CC98/index.tsx#L126)；[src/scenes/phone/P02_CC98/index.tsx:455](../src/scenes/phone/P02_CC98/index.tsx#L455)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:43](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L43)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:44](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L44)
506. 建议
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)；[src/data/cc98.posts.json:53](../src/data/cc98.posts.json#L53)；[src/data/cc98.posts.json:142](../src/data/cc98.posts.json#L142)；[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)；[src/data/cc98.posts.json:358](../src/data/cc98.posts.json#L358)；[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)；[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)；[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:516](../src/data/cc98.posts.json#L516)；[src/data/cc98.posts.json:709](../src/data/cc98.posts.json#L709)；[src/data/cc98.posts.json:862](../src/data/cc98.posts.json#L862)；[src/data/cc98.posts.json:957](../src/data/cc98.posts.json#L957)；[src/scenes/phone/P07_Weather/index.tsx:133](../src/scenes/phone/P07_Weather/index.tsx#L133)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
507. 今天 18:01
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)
508. 先写一件完成后能立刻划掉的小事，别把清单当成新的压力。
   来源：[src/data/cc98.posts.json:16](../src/data/cc98.posts.json#L16)
509. 3楼
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)；[src/data/cc98.posts.json:53](../src/data/cc98.posts.json#L53)；[src/data/cc98.posts.json:71](../src/data/cc98.posts.json#L71)；[src/data/cc98.posts.json:89](../src/data/cc98.posts.json#L89)；[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:125](../src/data/cc98.posts.json#L125)；[src/data/cc98.posts.json:143](../src/data/cc98.posts.json#L143)；[src/data/cc98.posts.json:161](../src/data/cc98.posts.json#L161)；[src/data/cc98.posts.json:179](../src/data/cc98.posts.json#L179)；[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)；[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)；[src/data/cc98.posts.json:251](../src/data/cc98.posts.json#L251)；[src/data/cc98.posts.json:269](../src/data/cc98.posts.json#L269)；[src/data/cc98.posts.json:287](../src/data/cc98.posts.json#L287)；[src/data/cc98.posts.json:305](../src/data/cc98.posts.json#L305)；[src/data/cc98.posts.json:323](../src/data/cc98.posts.json#L323)；[src/data/cc98.posts.json:341](../src/data/cc98.posts.json#L341)；[src/data/cc98.posts.json:359](../src/data/cc98.posts.json#L359)；[src/data/cc98.posts.json:377](../src/data/cc98.posts.json#L377)；[src/data/cc98.posts.json:395](../src/data/cc98.posts.json#L395)；[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)；[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)；[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:471](../src/data/cc98.posts.json#L471)；[src/data/cc98.posts.json:493](../src/data/cc98.posts.json#L493)；[src/data/cc98.posts.json:515](../src/data/cc98.posts.json#L515)；[src/data/cc98.posts.json:537](../src/data/cc98.posts.json#L537)；[src/data/cc98.posts.json:559](../src/data/cc98.posts.json#L559)；[src/data/cc98.posts.json:581](../src/data/cc98.posts.json#L581)；[src/data/cc98.posts.json:603](../src/data/cc98.posts.json#L603)；[src/data/cc98.posts.json:625](../src/data/cc98.posts.json#L625)；[src/data/cc98.posts.json:647](../src/data/cc98.posts.json#L647)；[src/data/cc98.posts.json:669](../src/data/cc98.posts.json#L669)；[src/data/cc98.posts.json:689](../src/data/cc98.posts.json#L689)；[src/data/cc98.posts.json:709](../src/data/cc98.posts.json#L709)；[src/data/cc98.posts.json:728](../src/data/cc98.posts.json#L728)；[src/data/cc98.posts.json:748](../src/data/cc98.posts.json#L748)；[src/data/cc98.posts.json:767](../src/data/cc98.posts.json#L767)；[src/data/cc98.posts.json:786](../src/data/cc98.posts.json#L786)；[src/data/cc98.posts.json:805](../src/data/cc98.posts.json#L805)；[src/data/cc98.posts.json:824](../src/data/cc98.posts.json#L824)；[src/data/cc98.posts.json:844](../src/data/cc98.posts.json#L844)；[src/data/cc98.posts.json:863](../src/data/cc98.posts.json#L863)；[src/data/cc98.posts.json:882](../src/data/cc98.posts.json#L882)；[src/data/cc98.posts.json:901](../src/data/cc98.posts.json#L901)；[src/data/cc98.posts.json:920](../src/data/cc98.posts.json#L920)；[src/data/cc98.posts.json:939](../src/data/cc98.posts.json#L939)；[src/data/cc98.posts.json:958](../src/data/cc98.posts.json#L958)；[src/data/cc98.posts.json:977](../src/data/cc98.posts.json#L977)；[src/data/cc98.posts.json:996](../src/data/cc98.posts.json#L996)；[src/scenes/phone/P02_CC98/index.tsx:136](../src/scenes/phone/P02_CC98/index.tsx#L136)；[src/scenes/phone/P02_CC98/index.tsx:456](../src/scenes/phone/P02_CC98/index.tsx#L456)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:53](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L53)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:54](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L54)
510. 补充
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)；[src/data/cc98.posts.json:89](../src/data/cc98.posts.json#L89)；[src/data/cc98.posts.json:125](../src/data/cc98.posts.json#L125)；[src/data/cc98.posts.json:179](../src/data/cc98.posts.json#L179)；[src/data/cc98.posts.json:250](../src/data/cc98.posts.json#L250)；[src/data/cc98.posts.json:305](../src/data/cc98.posts.json#L305)；[src/data/cc98.posts.json:323](../src/data/cc98.posts.json#L323)；[src/data/cc98.posts.json:359](../src/data/cc98.posts.json#L359)；[src/data/cc98.posts.json:376](../src/data/cc98.posts.json#L376)；[src/data/cc98.posts.json:580](../src/data/cc98.posts.json#L580)；[src/data/cc98.posts.json:710](../src/data/cc98.posts.json#L710)；[src/data/cc98.posts.json:825](../src/data/cc98.posts.json#L825)；[src/data/cc98.posts.json:900](../src/data/cc98.posts.json#L900)；[src/data/cc98.posts.json:919](../src/data/cc98.posts.json#L919)；[src/data/cc98.posts.json:977](../src/data/cc98.posts.json#L977)
511. 今天 18:03
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)
512. 去食堂这一项保留。先离开桌面五分钟，回来再看下一项。
   来源：[src/data/cc98.posts.json:17](../src/data/cc98.posts.json#L17)
513. 刷新到没电
   来源：[src/data/cc98.posts.json:22](../src/data/cc98.posts.json#L22)
514. 投递后不断刷新邮箱，怎样才能停下来
   来源：[src/data/cc98.posts.json:26](../src/data/cc98.posts.json#L26)
515. 26-07-10 17:54
   来源：[src/data/cc98.posts.json:29](../src/data/cc98.posts.json#L29)
516. 下午投完一份材料，之后每隔几分钟就去看一次邮箱。明知道这么快不会有结果，还是控制不住。想把提醒关掉，又怕错过消息。
   来源：[src/data/cc98.posts.json:30](../src/data/cc98.posts.json#L30)
517. 标记等待期讨论
   来源：[src/data/cc98.posts.json:31](../src/data/cc98.posts.json#L31)
518. 讨论集中在投递后的信息焦虑
   来源：[src/data/cc98.posts.json:31](../src/data/cc98.posts.json#L31)
519. 方法
   来源：[src/data/cc98.posts.json:34](../src/data/cc98.posts.json#L34)；[src/data/cc98.posts.json:160](../src/data/cc98.posts.json#L160)
520. 给邮箱设两个固定查看时段，其他时间把页面关掉。我把时间写在日历里会更容易执行。
   来源：[src/data/cc98.posts.json:34](../src/data/cc98.posts.json#L34)
521. 今天 17:57
   来源：[src/data/cc98.posts.json:34](../src/data/cc98.posts.json#L34)
522. 今天 18:00
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
523. 提醒
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)；[src/data/cc98.posts.json:71](../src/data/cc98.posts.json#L71)；[src/data/cc98.posts.json:161](../src/data/cc98.posts.json#L161)；[src/data/cc98.posts.json:395](../src/data/cc98.posts.json#L395)；[src/data/cc98.posts.json:559](../src/data/cc98.posts.json#L559)；[src/data/cc98.posts.json:585](../src/data/cc98.posts.json#L585)；[src/data/cc98.posts.json:628](../src/data/cc98.posts.json#L628)；[src/data/cc98.posts.json:670](../src/data/cc98.posts.json#L670)；[src/data/cc98.posts.json:767](../src/data/cc98.posts.json#L767)；[src/data/cc98.posts.json:787](../src/data/cc98.posts.json#L787)；[src/data/cc98.posts.json:806](../src/data/cc98.posts.json#L806)；[src/data/cc98.posts.json:824](../src/data/cc98.posts.json#L824)；[src/data/cc98.posts.json:882](../src/data/cc98.posts.json#L882)；[src/data/cc98.posts.json:921](../src/data/cc98.posts.json#L921)；[src/data/cc98.posts.json:976](../src/data/cc98.posts.json#L976)；[src/data/cc98.posts.json:996](../src/data/cc98.posts.json#L996)
524. 投递回执留好就够了。下一步应由对方完成，反复刷新不会改变材料状态。
   来源：[src/data/cc98.posts.json:35](../src/data/cc98.posts.json#L35)
525. 耳机也挡不住
   来源：[src/data/cc98.posts.json:40](../src/data/cc98.posts.json#L40)
526. 和室友约个安静时段，怎么开口比较不尴尬
   来源：[src/data/cc98.posts.json:44](../src/data/cc98.posts.json#L44)
527. 26-07-10 17:50
   来源：[src/data/cc98.posts.json:47](../src/data/cc98.posts.json#L47)
528. 这周总在赶报告，晚上十点后还会有开麦和外放声音。大家关系正常，我不想把话说成指责。有没有比较具体的沟通方式？
   来源：[src/data/cc98.posts.json:48](../src/data/cc98.posts.json#L48)
529. 保留宿舍沟通帖
   来源：[src/data/cc98.posts.json:49](../src/data/cc98.posts.json#L49)
530. 问题说明了时间和可协商边界
   来源：[src/data/cc98.posts.json:49](../src/data/cc98.posts.json#L49)
531. 今天 17:53
   来源：[src/data/cc98.posts.json:52](../src/data/cc98.posts.json#L52)；[src/data/cc98.posts.json:475](../src/data/cc98.posts.json#L475)
532. 经历
   来源：[src/data/cc98.posts.json:52](../src/data/cc98.posts.json#L52)；[src/data/cc98.posts.json:143](../src/data/cc98.posts.json#L143)；[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:232](../src/data/cc98.posts.json#L232)；[src/data/cc98.posts.json:286](../src/data/cc98.posts.json#L286)；[src/data/cc98.posts.json:341](../src/data/cc98.posts.json#L341)；[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:473](../src/data/cc98.posts.json#L473)；[src/data/cc98.posts.json:863](../src/data/cc98.posts.json#L863)；[src/data/cc98.posts.json:920](../src/data/cc98.posts.json#L920)；[src/data/cc98.posts.json:958](../src/data/cc98.posts.json#L958)
533. 我们定的是十一点后耳机和键盘静音，白天不限制。把范围说清楚会比只说“太吵”好谈。
   来源：[src/data/cc98.posts.json:52](../src/data/cc98.posts.json#L52)
534. 今天 17:55
   来源：[src/data/cc98.posts.json:53](../src/data/cc98.posts.json#L53)
535. 先说自己这两天需要赶什么，再提出具体的一个时段。对方更容易知道怎么配合。
   来源：[src/data/cc98.posts.json:53](../src/data/cc98.posts.json#L53)
536. 绕一圈再回来
   来源：[src/data/cc98.posts.json:58](../src/data/cc98.posts.json#L58)
537. 想散步又怕一个人，晚上校园里还有人走吗
   来源：[src/data/cc98.posts.json:62](../src/data/cc98.posts.json#L62)
538. 26-07-10 17:46
   来源：[src/data/cc98.posts.json:65](../src/data/cc98.posts.json#L65)
539. 一直坐在宿舍反而更闷，想出去走十分钟，又担心自己一个人会越走越乱。有没有人愿意推荐一段灯比较亮、路上人也多的路线？
   来源：[src/data/cc98.posts.json:66](../src/data/cc98.posts.json#L66)
540. 保留夜间出行互助
   来源：[src/data/cc98.posts.json:67](../src/data/cc98.posts.json#L67)
541. 帖子明确询问公共区域的同行建议
   来源：[src/data/cc98.posts.json:67](../src/data/cc98.posts.json#L67)
542. 今天 17:49
   来源：[src/data/cc98.posts.json:70](../src/data/cc98.posts.json#L70)；[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)；[src/data/cc98.posts.json:497](../src/data/cc98.posts.json#L497)
543. 路线
   来源：[src/data/cc98.posts.json:70](../src/data/cc98.posts.json#L70)；[src/data/cc98.posts.json:561](../src/data/cc98.posts.json#L561)；[src/data/cc98.posts.json:649](../src/data/cc98.posts.json#L649)
544. 选有路灯的主路，先设十分钟计时，到点就回。路线不用太远。
   来源：[src/data/cc98.posts.json:70](../src/data/cc98.posts.json#L70)
545. 今天 17:51
   来源：[src/data/cc98.posts.json:71](../src/data/cc98.posts.json#L71)；[src/data/cc98.posts.json:452](../src/data/cc98.posts.json#L452)
546. 临时结伴先约在公共入口，告诉熟人去向和预计回来时间。
   来源：[src/data/cc98.posts.json:71](../src/data/cc98.posts.json#L71)
547. 进度条停住了
   来源：[src/data/cc98.posts.json:76](../src/data/cc98.posts.json#L76)
548. 计划赶不上进度时，先做哪件最有用
   来源：[src/data/cc98.posts.json:80](../src/data/cc98.posts.json#L80)
549. 26-07-10 17:41
   来源：[src/data/cc98.posts.json:83](../src/data/cc98.posts.json#L83)
550. 原来排好的三件事全被临时消息打断了，现在看着没完成的列表只想继续往后拖。想问大家会先补最紧急的，还是先收掉最小的一项？
   来源：[src/data/cc98.posts.json:84](../src/data/cc98.posts.json#L84)
551. 提问聚焦于临时变更后的行动顺序
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
552. 整理执行建议
   来源：[src/data/cc98.posts.json:85](../src/data/cc98.posts.json#L85)
553. 今天 17:44
   来源：[src/data/cc98.posts.json:88](../src/data/cc98.posts.json#L88)；[src/data/cc98.posts.json:448](../src/data/cc98.posts.json#L448)；[src/data/cc98.posts.json:495](../src/data/cc98.posts.json#L495)
554. 先做有明确截止时间的，再用一个十分钟任务把状态收回来。我的清单只有两列。
   来源：[src/data/cc98.posts.json:88](../src/data/cc98.posts.json#L88)
555. 做法
   来源：[src/data/cc98.posts.json:88](../src/data/cc98.posts.json#L88)；[src/data/cc98.posts.json:178](../src/data/cc98.posts.json#L178)
556. 把已经失效的计划划掉也算处理。留着它只会让列表看起来更难开始。
   来源：[src/data/cc98.posts.json:89](../src/data/cc98.posts.json#L89)
557. 今天 17:46
   来源：[src/data/cc98.posts.json:89](../src/data/cc98.posts.json#L89)；[src/data/cc98.posts.json:496](../src/data/cc98.posts.json#L496)
558. 晚到一分钟
   来源：[src/data/cc98.posts.json:94](../src/data/cc98.posts.json#L94)
559. 今天没有抢到名额，补位通知会在哪里出现
   来源：[src/data/cc98.posts.json:98](../src/data/cc98.posts.json#L98)
560. 26-07-10 17:37
   来源：[src/data/cc98.posts.json:101](../src/data/cc98.posts.json#L101)
561. 页面显示本轮已经结束，我没有抢到。先不想急着换网络或重复点了，想确认之后如果有人退掉，通知通常会从哪个入口出现。
   来源：[src/data/cc98.posts.json:102](../src/data/cc98.posts.json#L102)
562. 保留补位信息询问
   来源：[src/data/cc98.posts.json:103](../src/data/cc98.posts.json#L103)
563. 楼主说明了当前结果和需要确认的后续入口
   来源：[src/data/cc98.posts.json:103](../src/data/cc98.posts.json#L103)
564. 今天 17:39
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:493](../src/data/cc98.posts.json#L493)；[src/data/cc98.posts.json:540](../src/data/cc98.posts.json#L540)
565. 经验
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)；[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)；[src/data/cc98.posts.json:768](../src/data/cc98.posts.json#L768)
566. 先看活动页的消息通知和报名记录，补位一般会在那里写清楚。别只守着原按钮。
   来源：[src/data/cc98.posts.json:106](../src/data/cc98.posts.json#L106)
567. 把当前结果截图留着，再核对官方说明的补位规则。没有说明时不要相信私下转发的时间。
   来源：[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)
568. 今天 17:42
   来源：[src/data/cc98.posts.json:107](../src/data/cc98.posts.json#L107)；[src/data/cc98.posts.json:518](../src/data/cc98.posts.json#L518)；[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
569. 电话挂断以后
   来源：[src/data/cc98.posts.json:112](../src/data/cc98.posts.json#L112)
570. 给家里报平安后反而更难平静
   来源：[src/data/cc98.posts.json:116](../src/data/cc98.posts.json#L116)
571. 26-07-10 17:33
   来源：[src/data/cc98.posts.json:119](../src/data/cc98.posts.json#L119)
572. 刚和家里通完电话，明明已经把近况说清楚了，挂断后还是一直在想有没有哪里没说好。现在不想继续反复回放这段对话。
   来源：[src/data/cc98.posts.json:120](../src/data/cc98.posts.json#L120)
573. 保留陪伴讨论
   来源：[src/data/cc98.posts.json:121](../src/data/cc98.posts.json#L121)
574. 帖子请求的是当下可执行的安顿方法
   来源：[src/data/cc98.posts.json:121](../src/data/cc98.posts.json#L121)
575. 今天 17:35
   来源：[src/data/cc98.posts.json:124](../src/data/cc98.posts.json#L124)；[src/data/cc98.posts.json:515](../src/data/cc98.posts.json#L515)
576. 陪伴
   来源：[src/data/cc98.posts.json:124](../src/data/cc98.posts.json#L124)
577. 通话结束后先做一个和手机无关的动作，比如洗杯子或下楼买水，让注意力换个落点。
   来源：[src/data/cc98.posts.json:124](../src/data/cc98.posts.json#L124)
578. 今天 17:38
   来源：[src/data/cc98.posts.json:125](../src/data/cc98.posts.json#L125)
579. 如果确实有事漏说，明天再补一条短消息也来得及。今晚先不用把每句话都重新审一遍。
   来源：[src/data/cc98.posts.json:125](../src/data/cc98.posts.json#L125)
580. 借个安静角落
   来源：[src/data/cc98.posts.json:130](../src/data/cc98.posts.json#L130)
581. 复习到一半脑子卡住了，换个地方会有用吗
   来源：[src/data/cc98.posts.json:134](../src/data/cc98.posts.json#L134)
582. 26-07-10 17:29
   来源：[src/data/cc98.posts.json:137](../src/data/cc98.posts.json#L137)
583. 同一页题目看了快半小时，连自己写过什么都记不住。想去图书馆坐一会，又担心换地方只是拖延。大家卡住时会怎么重新开始？
   来源：[src/data/cc98.posts.json:138](../src/data/cc98.posts.json#L138)
584. 保留学习互助
   来源：[src/data/cc98.posts.json:139](../src/data/cc98.posts.json#L139)
585. 楼主描述了明确的卡点和可尝试的下一步
   来源：[src/data/cc98.posts.json:139](../src/data/cc98.posts.json#L139)
586. 今天 17:31
   来源：[src/data/cc98.posts.json:142](../src/data/cc98.posts.json#L142)；[src/data/cc98.posts.json:584](../src/data/cc98.posts.json#L584)
587. 先站起来离开五分钟，回来只做一道最短的题。换地方之前先给自己一个能完成的入口。
   来源：[src/data/cc98.posts.json:142](../src/data/cc98.posts.json#L142)
588. 今天 17:34
   来源：[src/data/cc98.posts.json:143](../src/data/cc98.posts.json#L143)；[src/data/cc98.posts.json:538](../src/data/cc98.posts.json#L538)；[src/data/cc98.posts.json:562](../src/data/cc98.posts.json#L562)
589. 我会把不会的题圈起来，先写旁边最熟的一题。页面上有一点进度后再回头。
   来源：[src/data/cc98.posts.json:143](../src/data/cc98.posts.json#L143)
590. 草稿箱里放着
   来源：[src/data/cc98.posts.json:148](../src/data/cc98.posts.json#L148)
591. 想把情绪写下来，但担心被认识的人看到
   来源：[src/data/cc98.posts.json:152](../src/data/cc98.posts.json#L152)
592. 26-07-10 17:24
   来源：[src/data/cc98.posts.json:155](../src/data/cc98.posts.json#L155)；[src/data/cc98.posts.json:553](../src/data/cc98.posts.json#L553)
593. 有很多话想整理出来，又不想让熟人把它和现实里的我对应上。匿名发帖之外，还有没有更私人的记录办法？
   来源：[src/data/cc98.posts.json:156](../src/data/cc98.posts.json#L156)
594. 保留表达方式讨论
   来源：[src/data/cc98.posts.json:157](../src/data/cc98.posts.json#L157)
595. 讨论范围限定在隐私和自我整理
   来源：[src/data/cc98.posts.json:157](../src/data/cc98.posts.json#L157)
596. 今天 17:26
   来源：[src/data/cc98.posts.json:160](../src/data/cc98.posts.json#L160)；[src/data/cc98.posts.json:558](../src/data/cc98.posts.json#L558)；[src/data/cc98.posts.json:605](../src/data/cc98.posts.json#L605)
597. 可以先写在本地草稿，不急着发送。写完隔一会儿再决定哪些内容需要留下。
   来源：[src/data/cc98.posts.json:160](../src/data/cc98.posts.json#L160)
598. 公开内容删掉可识别的地点、时间和人物细节。记录本身不需要一次写得完整。
   来源：[src/data/cc98.posts.json:161](../src/data/cc98.posts.json#L161)
599. 今天 17:28
   来源：[src/data/cc98.posts.json:161](../src/data/cc98.posts.json#L161)；[src/data/cc98.posts.json:559](../src/data/cc98.posts.json#L559)；[src/data/cc98.posts.json:606](../src/data/cc98.posts.json#L606)
600. 还在等回应
   来源：[src/data/cc98.posts.json:166](../src/data/cc98.posts.json#L166)
601. 小组作业一直没有回应，我该什么时候追问
   来源：[src/data/cc98.posts.json:170](../src/data/cc98.posts.json#L170)
602. 26-07-10 17:20
   来源：[src/data/cc98.posts.json:173](../src/data/cc98.posts.json#L173)
603. 昨天把分工表发到群里，到现在没有人确认。截止日期还远，但我已经开始担心最后只剩一个人做。想催，又怕让人觉得太急。
   来源：[src/data/cc98.posts.json:174](../src/data/cc98.posts.json#L174)
604. 帖子给出了现状与时间边界
   来源：[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)
605. 整理协作建议
   来源：[src/data/cc98.posts.json:175](../src/data/cc98.posts.json#L175)
606. 定一个明确确认时间，例如明天中午前。问句里把需要回复的选项写好，大家更容易接。
   来源：[src/data/cc98.posts.json:178](../src/data/cc98.posts.json#L178)
607. 今天 17:23
   来源：[src/data/cc98.posts.json:178](../src/data/cc98.posts.json#L178)；[src/data/cc98.posts.json:580](../src/data/cc98.posts.json#L580)；[src/data/cc98.posts.json:627](../src/data/cc98.posts.json#L627)
608. 今天 17:25
   来源：[src/data/cc98.posts.json:179](../src/data/cc98.posts.json#L179)；[src/data/cc98.posts.json:581](../src/data/cc98.posts.json#L581)；[src/data/cc98.posts.json:628](../src/data/cc98.posts.json#L628)
609. 群里没人回应时，先把自己的部分拆出来开始。等到约定时间再同步进度，沟通会更具体。
   来源：[src/data/cc98.posts.json:179](../src/data/cc98.posts.json#L179)
610. 今晚先不分析
   来源：[src/data/cc98.posts.json:184](../src/data/cc98.posts.json#L184)
611. 能不能开一个不分析对错的夜间闲聊楼
   来源：[src/data/cc98.posts.json:188](../src/data/cc98.posts.json#L188)
612. 26-07-10 17:16
   来源：[src/data/cc98.posts.json:191](../src/data/cc98.posts.json#L191)
613. 今天不想把每件事都解释成原因和结论，只想找个地方说一句“我现在有点累”。如果你也在，就留一句今天想吃什么或者刚刚看到什么。
   来源：[src/data/cc98.posts.json:192](../src/data/cc98.posts.json#L192)
614. 保留夜间陪伴帖
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)
615. 帖子设定了低门槛、非评判的交流范围
   来源：[src/data/cc98.posts.json:193](../src/data/cc98.posts.json#L193)
616. 刚从风很大的路口回来，想喝一杯热的。
   来源：[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)
617. 今天 17:18
   来源：[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:648](../src/data/cc98.posts.json#L648)
618. 路过
   来源：[src/data/cc98.posts.json:196](../src/data/cc98.posts.json#L196)；[src/data/cc98.posts.json:669](../src/data/cc98.posts.json#L669)
619. 今天 17:21
   来源：[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)；[src/data/cc98.posts.json:626](../src/data/cc98.posts.json#L626)
620. 留言
   来源：[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)
621. 我今天终于把桌面收出了一小块空地方，先在这里坐一会。
   来源：[src/data/cc98.posts.json:197](../src/data/cc98.posts.json#L197)
622. 午睡醒得太晚
   来源：[src/data/cc98.posts.json:202](../src/data/cc98.posts.json#L202)
623. 午睡醒来不知道今天星期几
   来源：[src/data/cc98.posts.json:206](../src/data/cc98.posts.json#L206)
624. 26-07-10 17:12
   来源：[src/data/cc98.posts.json:209](../src/data/cc98.posts.json#L209)；[src/data/cc98.posts.json:641](../src/data/cc98.posts.json#L641)
625. 睡醒以后天色和时间都对不上，拿起手机才发现下午已经快结束了。没有发生什么大事，就是突然觉得这一天被跳过去了一段。
   来源：[src/data/cc98.posts.json:210](../src/data/cc98.posts.json#L210)
626. 保留日常状态帖
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
627. 帖子以轻量描述邀请同类经历回应
   来源：[src/data/cc98.posts.json:211](../src/data/cc98.posts.json#L211)
628. 今天 17:14
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)；[src/data/cc98.posts.json:646](../src/data/cc98.posts.json#L646)；[src/data/cc98.posts.json:670](../src/data/cc98.posts.json#L670)
629. 我会先洗把脸再看日历，只安排今晚的一件小事。今天剩下的时间也还能用。
   来源：[src/data/cc98.posts.json:214](../src/data/cc98.posts.json#L214)
630. 把晚饭、洗漱和睡觉时间记下来就够了，不必急着追回已经过去的几个小时。
   来源：[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)
631. 今天 17:17
   来源：[src/data/cc98.posts.json:215](../src/data/cc98.posts.json#L215)；[src/data/cc98.posts.json:624](../src/data/cc98.posts.json#L624)
632. 明天才上课
   来源：[src/data/cc98.posts.json:220](../src/data/cc98.posts.json#L220)
633. 提前十分钟到教室，结果发现坐的是明天的课
   来源：[src/data/cc98.posts.json:224](../src/data/cc98.posts.json#L224)
634. 26-07-10 17:08
   来源：[src/data/cc98.posts.json:227](../src/data/cc98.posts.json#L227)；[src/data/cc98.posts.json:663](../src/data/cc98.posts.json#L663)
635. 坐下后发现周围的人全在复习我完全没学过的内容。我还坚持记了两行笔记，直到有人问我是哪门课的才看见日期。
   来源：[src/data/cc98.posts.json:228](../src/data/cc98.posts.json#L228)
636. 加入校园小乌龙
   来源：[src/data/cc98.posts.json:229](../src/data/cc98.posts.json#L229)
637. 开怀一笑值班员
   来源：[src/data/cc98.posts.json:229](../src/data/cc98.posts.json#L229)；[src/data/cc98.posts.json:247](../src/data/cc98.posts.json#L247)；[src/data/cc98.posts.json:265](../src/data/cc98.posts.json#L265)；[src/data/cc98.posts.json:283](../src/data/cc98.posts.json#L283)；[src/data/cc98.posts.json:301](../src/data/cc98.posts.json#L301)；[src/data/cc98.posts.json:319](../src/data/cc98.posts.json#L319)；[src/data/cc98.posts.json:337](../src/data/cc98.posts.json#L337)；[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)；[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)；[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)；[src/data/cc98.posts.json:409](../src/data/cc98.posts.json#L409)；[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)；[src/data/cc98.posts.json:840](../src/data/cc98.posts.json#L840)；[src/data/cc98.posts.json:859](../src/data/cc98.posts.json#L859)；[src/data/cc98.posts.json:954](../src/data/cc98.posts.json#L954)
638. 帖子包含完整的误入过程和收尾
   来源：[src/data/cc98.posts.json:229](../src/data/cc98.posts.json#L229)
639. 今天 17:10
   来源：[src/data/cc98.posts.json:232](../src/data/cc98.posts.json#L232)；[src/data/cc98.posts.json:668](../src/data/cc98.posts.json#L668)
640. 我更进一步，听完半节才发现自己没有选这门课。
   来源：[src/data/cc98.posts.json:232](../src/data/cc98.posts.json#L232)
641. 今天 17:12
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)；[src/data/cc98.posts.json:669](../src/data/cc98.posts.json#L669)
642. 下次先看门口的课表。你至少提前到了。
   来源：[src/data/cc98.posts.json:233](../src/data/cc98.posts.json#L233)
643. 三桌同款菜
   来源：[src/data/cc98.posts.json:238](../src/data/cc98.posts.json#L238)
644. 在食堂连看三桌都是同一种菜，怀疑今天只有一个选项
   来源：[src/data/cc98.posts.json:242](../src/data/cc98.posts.json#L242)
645. 26-07-10 17:05
   来源：[src/data/cc98.posts.json:245](../src/data/cc98.posts.json#L245)；[src/data/cc98.posts.json:683](../src/data/cc98.posts.json#L683)
646. 排队时看见前面三个人都端着同一盘菜，我以为窗口只剩这一种。轮到我才发现他们只是一起点了套餐。
   来源：[src/data/cc98.posts.json:246](../src/data/cc98.posts.json#L246)
647. 保留饭点观察
   来源：[src/data/cc98.posts.json:247](../src/data/cc98.posts.json#L247)
648. 主题来自公共食堂的即时误判
   来源：[src/data/cc98.posts.json:247](../src/data/cc98.posts.json#L247)
649. 今天 17:07
   来源：[src/data/cc98.posts.json:250](../src/data/cc98.posts.json#L250)；[src/data/cc98.posts.json:688](../src/data/cc98.posts.json#L688)
650. 食堂里最容易传播的消息，就是前面三个人端了同一份菜。
   来源：[src/data/cc98.posts.json:250](../src/data/cc98.posts.json#L250)
651. 结论
   来源：[src/data/cc98.posts.json:251](../src/data/cc98.posts.json#L251)；[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)；[src/data/cc98.posts.json:691](../src/data/cc98.posts.json#L691)；[src/data/cc98.posts.json:864](../src/data/cc98.posts.json#L864)；[src/data/cc98.posts.json:959](../src/data/cc98.posts.json#L959)；[src/data/cc98.posts.json:997](../src/data/cc98.posts.json#L997)
652. 今天 17:09
   来源：[src/data/cc98.posts.json:251](../src/data/cc98.posts.json#L251)；[src/data/cc98.posts.json:689](../src/data/cc98.posts.json#L689)
653. 最后你还是点了套餐吗？
   来源：[src/data/cc98.posts.json:251](../src/data/cc98.posts.json#L251)
654. 导航原地打转
   来源：[src/data/cc98.posts.json:256](../src/data/cc98.posts.json#L256)
655. 导航说“已到达”，我在原地转了两圈才看见门
   来源：[src/data/cc98.posts.json:260](../src/data/cc98.posts.json#L260)
656. 26-07-10 17:02
   来源：[src/data/cc98.posts.json:263](../src/data/cc98.posts.json#L263)；[src/data/cc98.posts.json:703](../src/data/cc98.posts.json#L703)
657. 定位点落在楼的正中央，导航特别肯定地结束了。我绕着绿化带走了两圈，最后发现入口在背后的另一条小路。
   来源：[src/data/cc98.posts.json:264](../src/data/cc98.posts.json#L264)
658. 加入定位趣事
   来源：[src/data/cc98.posts.json:265](../src/data/cc98.posts.json#L265)
659. 帖子说明了定位点与真实入口的差异
   来源：[src/data/cc98.posts.json:265](../src/data/cc98.posts.json#L265)
660. 导航负责把你送到建筑物附近，门要靠自己找。
   来源：[src/data/cc98.posts.json:268](../src/data/cc98.posts.json#L268)
661. 今天 17:04
   来源：[src/data/cc98.posts.json:268](../src/data/cc98.posts.json#L268)；[src/data/cc98.posts.json:708](../src/data/cc98.posts.json#L708)；[src/data/cc98.posts.json:729](../src/data/cc98.posts.json#L729)
662. 实测
   来源：[src/data/cc98.posts.json:268](../src/data/cc98.posts.json#L268)；[src/data/cc98.posts.json:514](../src/data/cc98.posts.json#L514)；[src/data/cc98.posts.json:624](../src/data/cc98.posts.json#L624)；[src/data/cc98.posts.json:823](../src/data/cc98.posts.json#L823)
663. 建议给入口补一个位置点，留给下一个在绿化带绕圈的人。
   来源：[src/data/cc98.posts.json:269](../src/data/cc98.posts.json#L269)
664. 今天 17:06
   来源：[src/data/cc98.posts.json:269](../src/data/cc98.posts.json#L269)；[src/data/cc98.posts.json:709](../src/data/cc98.posts.json#L709)；[src/data/cc98.posts.json:730](../src/data/cc98.posts.json#L730)
665. 线材整理失败
   来源：[src/data/cc98.posts.json:274](../src/data/cc98.posts.json#L274)
666. 把充电线落在桌上，回来时它已经被卷成一件艺术品
   来源：[src/data/cc98.posts.json:278](../src/data/cc98.posts.json#L278)
667. 26-07-10 16:59
   来源：[src/data/cc98.posts.json:281](../src/data/cc98.posts.json#L281)
668. 我离开半小时，室友怕我踩到线，顺手把它卷好。回来后面对那个完美的结，决定还是改用充电宝。
   来源：[src/data/cc98.posts.json:282](../src/data/cc98.posts.json#L282)
669. 保留宿舍日常
   来源：[src/data/cc98.posts.json:283](../src/data/cc98.posts.json#L283)
670. 主题为无损失的生活小插曲
   来源：[src/data/cc98.posts.json:283](../src/data/cc98.posts.json#L283)
671. 今天 17:01
   来源：[src/data/cc98.posts.json:286](../src/data/cc98.posts.json#L286)
672. 越整齐的线，越不敢从哪里开始拆。
   来源：[src/data/cc98.posts.json:286](../src/data/cc98.posts.json#L286)
673. 办法
   来源：[src/data/cc98.posts.json:287](../src/data/cc98.posts.json#L287)
674. 今天 17:03
   来源：[src/data/cc98.posts.json:287](../src/data/cc98.posts.json#L287)
675. 下次给它留一个纸条：请保持自然生长。
   来源：[src/data/cc98.posts.json:287](../src/data/cc98.posts.json#L287)
676. 群聊歪楼现场
   来源：[src/data/cc98.posts.json:292](../src/data/cc98.posts.json#L292)
677. 社团群里问谁有空，三分钟后大家都在发猫
   来源：[src/data/cc98.posts.json:296](../src/data/cc98.posts.json#L296)
678. 26-07-10 16:56
   来源：[src/data/cc98.posts.json:299](../src/data/cc98.posts.json#L299)
679. 原本想统计周末布置场地的人手，第一张猫图出现后就没有人再回答问题。现在我只知道群里至少有五个人家里有猫。
   来源：[src/data/cc98.posts.json:300](../src/data/cc98.posts.json#L300)
680. 加入群聊现场
   来源：[src/data/cc98.posts.json:301](../src/data/cc98.posts.json#L301)
681. 帖子完整呈现话题偏离的过程
   来源：[src/data/cc98.posts.json:301](../src/data/cc98.posts.json#L301)
682. 今天 16:58
   来源：[src/data/cc98.posts.json:304](../src/data/cc98.posts.json#L304)；[src/data/cc98.posts.json:748](../src/data/cc98.posts.json#L748)
683. 提案
   来源：[src/data/cc98.posts.json:304](../src/data/cc98.posts.json#L304)；[src/data/cc98.posts.json:472](../src/data/cc98.posts.json#L472)
684. 先把猫图按反应数排序，再在最后补一个报名投票。
   来源：[src/data/cc98.posts.json:304](../src/data/cc98.posts.json#L304)
685. 今天 17:00
   来源：[src/data/cc98.posts.json:305](../src/data/cc98.posts.json#L305)；[src/data/cc98.posts.json:727](../src/data/cc98.posts.json#L727)；[src/data/cc98.posts.json:749](../src/data/cc98.posts.json#L749)
686. 猫图不算报名，但可以算出勤激励。
   来源：[src/data/cc98.posts.json:305](../src/data/cc98.posts.json#L305)
687. 门外轻声到啦
   来源：[src/data/cc98.posts.json:310](../src/data/cc98.posts.json#L310)
688. 给外卖备注“别敲门”，骑手在门外小声唱了句到啦
   来源：[src/data/cc98.posts.json:314](../src/data/cc98.posts.json#L314)
689. 26-07-10 16:53
   来源：[src/data/cc98.posts.json:317](../src/data/cc98.posts.json#L317)
690. 备注写了不要敲门，担心影响室友。门外没有敲门声，只有一句很轻的“到啦”，比系统通知还容易听见。
   来源：[src/data/cc98.posts.json:318](../src/data/cc98.posts.json#L318)
691. 保留取餐趣事
   来源：[src/data/cc98.posts.json:319](../src/data/cc98.posts.json#L319)
692. 主题来自公共配送场景的善意细节
   来源：[src/data/cc98.posts.json:319](../src/data/cc98.posts.json#L319)
693. 今天 16:55
   来源：[src/data/cc98.posts.json:322](../src/data/cc98.posts.json#L322)
694. 现场
   来源：[src/data/cc98.posts.json:322](../src/data/cc98.posts.json#L322)；[src/data/cc98.posts.json:515](../src/data/cc98.posts.json#L515)；[src/data/cc98.posts.json:558](../src/data/cc98.posts.json#L558)；[src/data/cc98.posts.json:647](../src/data/cc98.posts.json#L647)；[src/data/cc98.posts.json:902](../src/data/cc98.posts.json#L902)；[src/data/cc98.posts.json:995](../src/data/cc98.posts.json#L995)
695. 这种提示音很适合做宿舍文明配送标准。
   来源：[src/data/cc98.posts.json:322](../src/data/cc98.posts.json#L322)
696. 今天 16:57
   来源：[src/data/cc98.posts.json:323](../src/data/cc98.posts.json#L323)
697. 我收到过轻敲三下的版本，也很克制。
   来源：[src/data/cc98.posts.json:323](../src/data/cc98.posts.json#L323)
698. 门禁按错层
   来源：[src/data/cc98.posts.json:328](../src/data/cc98.posts.json#L328)
699. 走错楼层还自信按了门禁
   来源：[src/data/cc98.posts.json:332](../src/data/cc98.posts.json#L332)
700. 26-07-10 16:50
   来源：[src/data/cc98.posts.json:335](../src/data/cc98.posts.json#L335)；[src/data/cc98.posts.json:761](../src/data/cc98.posts.json#L761)
701. 门禁没有反应，我还认真检查了三次校园卡。后来电梯打开，才意识到自己早一层就出来了。
   来源：[src/data/cc98.posts.json:336](../src/data/cc98.posts.json#L336)
702. 加入楼层误会
   来源：[src/data/cc98.posts.json:337](../src/data/cc98.posts.json#L337)
703. 帖子以无伤害的误判收束
   来源：[src/data/cc98.posts.json:337](../src/data/cc98.posts.json#L337)
704. 核对
   来源：[src/data/cc98.posts.json:340](../src/data/cc98.posts.json#L340)；[src/data/cc98.posts.json:607](../src/data/cc98.posts.json#L607)；[src/data/cc98.posts.json:648](../src/data/cc98.posts.json#L648)；[src/data/cc98.posts.json:748](../src/data/cc98.posts.json#L748)；[src/data/cc98.posts.json:804](../src/data/cc98.posts.json#L804)；[src/data/cc98.posts.json:978](../src/data/cc98.posts.json#L978)
705. 今天 16:52
   来源：[src/data/cc98.posts.json:340](../src/data/cc98.posts.json#L340)；[src/data/cc98.posts.json:766](../src/data/cc98.posts.json#L766)；[src/data/cc98.posts.json:787](../src/data/cc98.posts.json#L787)
706. 门禁正常，楼层也正常，只有人不在正确位置。
   来源：[src/data/cc98.posts.json:340](../src/data/cc98.posts.json#L340)
707. 今天 16:54
   来源：[src/data/cc98.posts.json:341](../src/data/cc98.posts.json#L341)；[src/data/cc98.posts.json:767](../src/data/cc98.posts.json#L767)
708. 我还对着陌生人的门牌想过是不是刚换了人。
   来源：[src/data/cc98.posts.json:341](../src/data/cc98.posts.json#L341)
709. 洗衣机先毕业
   来源：[src/data/cc98.posts.json:346](../src/data/cc98.posts.json#L346)
710. 第一次用新洗衣机，衣服比我先学会了流程
   来源：[src/data/cc98.posts.json:350](../src/data/cc98.posts.json#L350)
711. 26-07-10 16:47
   来源：[src/data/cc98.posts.json:353](../src/data/cc98.posts.json#L353)
712. 我站在机器前研究按钮，旁边同学已经把衣服放进去开始转了。等我看懂选项时，他的洗衣程序快结束了。
   来源：[src/data/cc98.posts.json:354](../src/data/cc98.posts.json#L354)
713. 保留生活设备趣事
   来源：[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)
714. 主题来自公共设施的学习曲线
   来源：[src/data/cc98.posts.json:355](../src/data/cc98.posts.json#L355)
715. 今天 16:49
   来源：[src/data/cc98.posts.json:358](../src/data/cc98.posts.json#L358)
716. 洗衣机旁最重要的按钮往往写着“开始”，但我也会先把所有按钮看一遍。
   来源：[src/data/cc98.posts.json:358](../src/data/cc98.posts.json#L358)
717. 第一次看说明书花十分钟，之后每次都能省十分钟。
   来源：[src/data/cc98.posts.json:359](../src/data/cc98.posts.json#L359)
718. 今天 16:51
   来源：[src/data/cc98.posts.json:359](../src/data/cc98.posts.json#L359)
719. 关灯后发现
   来源：[src/data/cc98.posts.json:364](../src/data/cc98.posts.json#L364)
720. 临走前关灯，发现隔壁所有人都还在上课
   来源：[src/data/cc98.posts.json:368](../src/data/cc98.posts.json#L368)
721. 26-07-10 16:44
   来源：[src/data/cc98.posts.json:371](../src/data/cc98.posts.json#L371)
722. 我以为最后一排只剩自己，收完电脑顺手关了灯。教室静了两秒，才发现前面还有一整节晚课的人。
   来源：[src/data/cc98.posts.json:372](../src/data/cc98.posts.json#L372)
723. 加入教室小场面
   来源：[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)
724. 帖子以短暂尴尬和即时修正结束
   来源：[src/data/cc98.posts.json:373](../src/data/cc98.posts.json#L373)
725. 教室里最安静的时刻，往往发生在有人误关灯之后。
   来源：[src/data/cc98.posts.json:376](../src/data/cc98.posts.json#L376)
726. 今天 16:46
   来源：[src/data/cc98.posts.json:376](../src/data/cc98.posts.json#L376)；[src/data/cc98.posts.json:805](../src/data/cc98.posts.json#L805)；[src/data/cc98.posts.json:826](../src/data/cc98.posts.json#L826)
727. 回应
   来源：[src/data/cc98.posts.json:377](../src/data/cc98.posts.json#L377)
728. 今天 16:48
   来源：[src/data/cc98.posts.json:377](../src/data/cc98.posts.json#L377)；[src/data/cc98.posts.json:785](../src/data/cc98.posts.json#L785)；[src/data/cc98.posts.json:806](../src/data/cc98.posts.json#L806)
729. 至少你马上发现了，不然那节课会多一个黑屏环节。
   来源：[src/data/cc98.posts.json:377](../src/data/cc98.posts.json#L377)
730. 雨伞认错三次
   来源：[src/data/cc98.posts.json:382](../src/data/cc98.posts.json#L382)
731. 把雨伞放在门口，出来时认错了三把
   来源：[src/data/cc98.posts.json:386](../src/data/cc98.posts.json#L386)
732. 26-07-10 16:41
   来源：[src/data/cc98.posts.json:389](../src/data/cc98.posts.json#L389)
733. 黑伞、木柄、同款挂绳，门口像复制粘贴。每拿起一把都觉得很熟悉，直到看到自己的伞上贴着刚买的便利贴。
   来源：[src/data/cc98.posts.json:390](../src/data/cc98.posts.json#L390)
734. 保留雨天趣事
   来源：[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)
735. 主题来自公共区域的常见辨认失误
   来源：[src/data/cc98.posts.json:391](../src/data/cc98.posts.json#L391)
736. 给伞加一个不容易掉的小标记，雨天能少做几次选择题。
   来源：[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
737. 今天 16:43
   来源：[src/data/cc98.posts.json:394](../src/data/cc98.posts.json#L394)
738. 今天 16:45
   来源：[src/data/cc98.posts.json:395](../src/data/cc98.posts.json#L395)
739. 确认伞柄和挂绳后再拿，别让别人的伞多走一段路。
   来源：[src/data/cc98.posts.json:395](../src/data/cc98.posts.json#L395)
740. 卡片认错人
   来源：[src/data/cc98.posts.json:400](../src/data/cc98.posts.json#L400)
741. 刷校园卡失败两次，第三次才发现自己拿的是门卡
   来源：[src/data/cc98.posts.json:404](../src/data/cc98.posts.json#L404)
742. 26-07-10 16:38
   来源：[src/data/cc98.posts.json:407](../src/data/cc98.posts.json#L407)；[src/data/cc98.posts.json:818](../src/data/cc98.posts.json#L818)
743. 排在闸机前认真换角度，机器始终没有反应。第三次低头一看，手里那张根本没有照片。
   来源：[src/data/cc98.posts.json:408](../src/data/cc98.posts.json#L408)
744. 加入卡片误会
   来源：[src/data/cc98.posts.json:409](../src/data/cc98.posts.json#L409)
745. 主题来自日常通行时的自我纠正
   来源：[src/data/cc98.posts.json:409](../src/data/cc98.posts.json#L409)
746. 今天 16:40
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)；[src/data/cc98.posts.json:823](../src/data/cc98.posts.json#L823)；[src/data/cc98.posts.json:845](../src/data/cc98.posts.json#L845)
747. 门卡和校园卡放在一起时，考验的是手感和运气。
   来源：[src/data/cc98.posts.json:412](../src/data/cc98.posts.json#L412)
748. 今天 16:42
   来源：[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)；[src/data/cc98.posts.json:824](../src/data/cc98.posts.json#L824)
749. 闸机给了你三次重新确认身份的机会。
   来源：[src/data/cc98.posts.json:413](../src/data/cc98.posts.json#L413)
750. 投影桌面警报
   来源：[src/data/cc98.posts.json:418](../src/data/cc98.posts.json#L418)
751. 课堂投影突然成了自己的桌面，你们最怕露出什么
   来源：[src/data/cc98.posts.json:422](../src/data/cc98.posts.json#L422)
752. 26-07-10 16:35
   来源：[src/data/cc98.posts.json:425](../src/data/cc98.posts.json#L425)
753. 老师切换线缆后，屏幕短暂显示了我乱七八糟的桌面。幸好最显眼的是一堆叫“最终版”的文档，没有聊天窗口。
   来源：[src/data/cc98.posts.json:426](../src/data/cc98.posts.json#L426)
754. 保留课堂设备趣事
   来源：[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)
755. 帖子讨论的是无隐私细节的公共演示失误
   来源：[src/data/cc98.posts.json:427](../src/data/cc98.posts.json#L427)
756. 今天 16:37
   来源：[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)
757. 我最怕看到下载目录，里面的命名比内容更有故事。
   来源：[src/data/cc98.posts.json:430](../src/data/cc98.posts.json#L430)
758. 今天 16:39
   来源：[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)
759. 上课前先关窗口，再把桌面清出一块空白，比临场抢救可靠。
   来源：[src/data/cc98.posts.json:431](../src/data/cc98.posts.json#L431)
760. 求是路况员
   来源：[src/data/cc98.posts.json:436](../src/data/cc98.posts.json#L436)
761. 交通出行
   来源：[src/data/cc98.posts.json:439](../src/data/cc98.posts.json#L439)；[src/data/cc98.posts.json:718](../src/data/cc98.posts.json#L718)；[src/scenes/phone/P02_CC98/index.tsx:204](../src/scenes/phone/P02_CC98/index.tsx#L204)；[src/scenes/phone/P02_CC98/index.tsx:208](../src/scenes/phone/P02_CC98/index.tsx#L208)
762. 考试结束十分钟，求是潮哪边还能走
   来源：[src/data/cc98.posts.json:440](../src/data/cc98.posts.json#L440)
763. 26-07-10 17:42
   来源：[src/data/cc98.posts.json:443](../src/data/cc98.posts.json#L443)
764. 刚从东侧绕出来。教学区北侧的人行道还能连续走，东侧车流已经堵成两段。
   来源：[src/data/cc98.posts.json:444](../src/data/cc98.posts.json#L444)
765. 标记为实时路况
   来源：[src/data/cc98.posts.json:445](../src/data/cc98.posts.json#L445)
766. 回复区已经形成三条不同绕行路线
   来源：[src/data/cc98.posts.json:445](../src/data/cc98.posts.json#L445)
767. 路况互助机器人
   来源：[src/data/cc98.posts.json:445](../src/data/cc98.posts.json#L445)
768. 17:41 出考场，17:44 还在北口。东边四排车没动，北侧多走两分钟能过。
   来源：[src/data/cc98.posts.json:448](../src/data/cc98.posts.json#L448)
769. 前排
   来源：[src/data/cc98.posts.json:448](../src/data/cc98.posts.json#L448)；[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)
770. 北边树下还有空路，风也从那边过。走北侧，别跟车流挤。
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)
771. 今天 17:45
   来源：[src/data/cc98.posts.json:449](../src/data/cc98.posts.json#L449)；[src/data/cc98.posts.json:472](../src/data/cc98.posts.json#L472)；[src/data/cc98.posts.json:519](../src/data/cc98.posts.json#L519)
772. 4楼
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)；[src/data/cc98.posts.json:472](../src/data/cc98.posts.json#L472)；[src/data/cc98.posts.json:494](../src/data/cc98.posts.json#L494)；[src/data/cc98.posts.json:516](../src/data/cc98.posts.json#L516)；[src/data/cc98.posts.json:538](../src/data/cc98.posts.json#L538)；[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)；[src/data/cc98.posts.json:582](../src/data/cc98.posts.json#L582)；[src/data/cc98.posts.json:604](../src/data/cc98.posts.json#L604)；[src/data/cc98.posts.json:626](../src/data/cc98.posts.json#L626)；[src/data/cc98.posts.json:648](../src/data/cc98.posts.json#L648)；[src/data/cc98.posts.json:670](../src/data/cc98.posts.json#L670)；[src/data/cc98.posts.json:690](../src/data/cc98.posts.json#L690)；[src/data/cc98.posts.json:710](../src/data/cc98.posts.json#L710)；[src/data/cc98.posts.json:729](../src/data/cc98.posts.json#L729)；[src/data/cc98.posts.json:749](../src/data/cc98.posts.json#L749)；[src/data/cc98.posts.json:768](../src/data/cc98.posts.json#L768)；[src/data/cc98.posts.json:787](../src/data/cc98.posts.json#L787)；[src/data/cc98.posts.json:806](../src/data/cc98.posts.json#L806)；[src/data/cc98.posts.json:825](../src/data/cc98.posts.json#L825)；[src/data/cc98.posts.json:845](../src/data/cc98.posts.json#L845)；[src/data/cc98.posts.json:864](../src/data/cc98.posts.json#L864)；[src/data/cc98.posts.json:883](../src/data/cc98.posts.json#L883)；[src/data/cc98.posts.json:902](../src/data/cc98.posts.json#L902)；[src/data/cc98.posts.json:921](../src/data/cc98.posts.json#L921)；[src/data/cc98.posts.json:940](../src/data/cc98.posts.json#L940)；[src/data/cc98.posts.json:959](../src/data/cc98.posts.json#L959)；[src/data/cc98.posts.json:978](../src/data/cc98.posts.json#L978)；[src/data/cc98.posts.json:997](../src/data/cc98.posts.json#L997)；[src/scenes/phone/P02_CC98/index.tsx:147](../src/scenes/phone/P02_CC98/index.tsx#L147)
773. 二南门口横着停的共享单车还在。北口靠左走，别贴着那辆车。
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)
774. 今天 17:47
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)
775. 路况
   来源：[src/data/cc98.posts.json:450](../src/data/cc98.posts.json#L450)；[src/data/cc98.posts.json:539](../src/data/cc98.posts.json#L539)
776. 5楼
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)；[src/data/cc98.posts.json:473](../src/data/cc98.posts.json#L473)；[src/data/cc98.posts.json:495](../src/data/cc98.posts.json#L495)；[src/data/cc98.posts.json:517](../src/data/cc98.posts.json#L517)；[src/data/cc98.posts.json:539](../src/data/cc98.posts.json#L539)；[src/data/cc98.posts.json:561](../src/data/cc98.posts.json#L561)；[src/data/cc98.posts.json:583](../src/data/cc98.posts.json#L583)；[src/data/cc98.posts.json:605](../src/data/cc98.posts.json#L605)；[src/data/cc98.posts.json:627](../src/data/cc98.posts.json#L627)；[src/data/cc98.posts.json:649](../src/data/cc98.posts.json#L649)；[src/data/cc98.posts.json:671](../src/data/cc98.posts.json#L671)；[src/data/cc98.posts.json:691](../src/data/cc98.posts.json#L691)；[src/data/cc98.posts.json:730](../src/data/cc98.posts.json#L730)；[src/data/cc98.posts.json:826](../src/data/cc98.posts.json#L826)；[src/scenes/phone/P02_CC98/index.tsx:158](../src/scenes/phone/P02_CC98/index.tsx#L158)
777. 实况
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
778. 我刚骑完北侧绿道，过两个路口没停。东侧第一个口已经堵满。
   来源：[src/data/cc98.posts.json:451](../src/data/cc98.posts.json#L451)
779. 6楼
   来源：[src/data/cc98.posts.json:452](../src/data/cc98.posts.json#L452)；[src/data/cc98.posts.json:474](../src/data/cc98.posts.json#L474)；[src/data/cc98.posts.json:496](../src/data/cc98.posts.json#L496)；[src/data/cc98.posts.json:518](../src/data/cc98.posts.json#L518)；[src/data/cc98.posts.json:540](../src/data/cc98.posts.json#L540)；[src/data/cc98.posts.json:562](../src/data/cc98.posts.json#L562)；[src/data/cc98.posts.json:584](../src/data/cc98.posts.json#L584)；[src/data/cc98.posts.json:606](../src/data/cc98.posts.json#L606)；[src/data/cc98.posts.json:628](../src/data/cc98.posts.json#L628)；[src/data/cc98.posts.json:650](../src/data/cc98.posts.json#L650)
780. 我没有余额换车，推着现有这辆从北侧过了。北侧确实更省时间。
   来源：[src/data/cc98.posts.json:452](../src/data/cc98.posts.json#L452)
781. 预算
   来源：[src/data/cc98.posts.json:452](../src/data/cc98.posts.json#L452)
782. 7楼
   来源：[src/data/cc98.posts.json:453](../src/data/cc98.posts.json#L453)；[src/data/cc98.posts.json:475](../src/data/cc98.posts.json#L475)；[src/data/cc98.posts.json:497](../src/data/cc98.posts.json#L497)；[src/data/cc98.posts.json:519](../src/data/cc98.posts.json#L519)；[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)；[src/data/cc98.posts.json:585](../src/data/cc98.posts.json#L585)；[src/data/cc98.posts.json:607](../src/data/cc98.posts.json#L607)；[src/data/cc98.posts.json:629](../src/data/cc98.posts.json#L629)；[src/data/cc98.posts.json:651](../src/data/cc98.posts.json#L651)
783. 报数
   来源：[src/data/cc98.posts.json:453](../src/data/cc98.posts.json#L453)
784. 记录里写清楚，北侧可通，东侧拥堵。走人行道，别把车推进行人堆。
   来源：[src/data/cc98.posts.json:453](../src/data/cc98.posts.json#L453)
785. 今天 17:54
   来源：[src/data/cc98.posts.json:453](../src/data/cc98.posts.json#L453)
786. 二南守座人
   来源：[src/data/cc98.posts.json:458](../src/data/cc98.posts.json#L458)
787. 图书馆
   来源：[src/data/cc98.posts.json:461](../src/data/cc98.posts.json#L461)；[src/data/cc98.posts.json:776](../src/data/cc98.posts.json#L776)；[src/scenes/phone/P02_CC98/index.tsx:211](../src/scenes/phone/P02_CC98/index.tsx#L211)；[src/scenes/phone/P13_PhoneHome/index.tsx:775](../src/scenes/phone/P13_PhoneHome/index.tsx#L775)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:125](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L125)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:485](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L485)
788. 二层南临时离座规则更新了吗
   来源：[src/data/cc98.posts.json:462](../src/data/cc98.posts.json#L462)
789. 26-07-10 17:39
   来源：[src/data/cc98.posts.json:465](../src/data/cc98.posts.json#L465)
790. 离座超过三分钟后，原座位会重新开放。完成校园卡核验后，可在选座页申请恢复一次。
   来源：[src/data/cc98.posts.json:466](../src/data/cc98.posts.json#L466)
791. 补充规则入口
   来源：[src/data/cc98.posts.json:467](../src/data/cc98.posts.json#L467)
792. 馆内秩序值班台
   来源：[src/data/cc98.posts.json:467](../src/data/cc98.posts.json#L467)
793. 原帖只有结果，没有说明恢复材料
   来源：[src/data/cc98.posts.json:467](../src/data/cc98.posts.json#L467)
794. 17:40 去接水，17:43 回来，页面已经换成别人的编号。先留好时间戳。
   来源：[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)
795. 今天 17:41
   来源：[src/data/cc98.posts.json:470](../src/data/cc98.posts.json#L470)；[src/data/cc98.posts.json:494](../src/data/cc98.posts.json#L494)
796. 带图
   来源：[src/data/cc98.posts.json:471](../src/data/cc98.posts.json#L471)
797. 今天 17:43
   来源：[src/data/cc98.posts.json:471](../src/data/cc98.posts.json#L471)
798. 先帮顶。人还没坐回去，这条帖先别被新消息刷掉。
   来源：[src/data/cc98.posts.json:471](../src/data/cc98.posts.json#L471)
799. bd
   来源：[src/data/cc98.posts.json:471](../src/data/cc98.posts.json#L471)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:57](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L57)
800. 022 桌上的书包三天没动。它比大多数人更符合“长期使用”这一项。
   来源：[src/data/cc98.posts.json:472](../src/data/cc98.posts.json#L472)
801. 今天 17:48
   来源：[src/data/cc98.posts.json:473](../src/data/cc98.posts.json#L473)
802. 我去接水 2 分 59 秒，回到门口刚好三分钟。座位已经换号。
   来源：[src/data/cc98.posts.json:473](../src/data/cc98.posts.json#L473)
803. 0.06 元可以做身份核验，恢复申请还是要补材料。
   来源：[src/data/cc98.posts.json:474](../src/data/cc98.posts.json#L474)
804. 今天 17:50
   来源：[src/data/cc98.posts.json:474](../src/data/cc98.posts.json#L474)
805. 资产
   来源：[src/data/cc98.posts.json:474](../src/data/cc98.posts.json#L474)
806. 理论
   来源：[src/data/cc98.posts.json:475](../src/data/cc98.posts.json#L475)
807. 需要留下离座时长和校园卡核验两项记录。满足后才能申请恢复。
   来源：[src/data/cc98.posts.json:475](../src/data/cc98.posts.json#L475)
808. 资料索引机
   来源：[src/data/cc98.posts.json:480](../src/data/cc98.posts.json#L480)
809. 学习天地
   来源：[src/data/cc98.posts.json:483](../src/data/cc98.posts.json#L483)；[src/data/cc98.posts.json:637](../src/data/cc98.posts.json#L637)；[src/data/cc98.posts.json:738](../src/data/cc98.posts.json#L738)；[src/scenes/phone/P02_CC98/index.tsx:204](../src/scenes/phone/P02_CC98/index.tsx#L204)；[src/scenes/phone/P02_CC98/index.tsx:209](../src/scenes/phone/P02_CC98/index.tsx#L209)
810. 期末资料按课程和年份整理好了
   来源：[src/data/cc98.posts.json:484](../src/data/cc98.posts.json#L484)
811. 26-07-10 17:35
   来源：[src/data/cc98.posts.json:487](../src/data/cc98.posts.json#L487)
812. 资料按课程、教师和年份建立索引。搜索时只记得两个字也能定位到对应目录。
   来源：[src/data/cc98.posts.json:488](../src/data/cc98.posts.json#L488)
813. 加入版面索引
   来源：[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)
814. 目录结构和版本信息均可核对
   来源：[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)
815. 资料版值班员
   来源：[src/data/cc98.posts.json:489](../src/data/cc98.posts.json#L489)；[src/data/cc98.posts.json:744](../src/data/cc98.posts.json#L744)
816. 今天 17:37
   来源：[src/data/cc98.posts.json:492](../src/data/cc98.posts.json#L492)；[src/data/cc98.posts.json:516](../src/data/cc98.posts.json#L516)
817. 求助
   来源：[src/data/cc98.posts.json:492](../src/data/cc98.posts.json#L492)
818. 文件名写成“最终版5真的最终版”的那份，能不能把交稿时间也写进文件名。
   来源：[src/data/cc98.posts.json:492](../src/data/cc98.posts.json#L492)
819. “老师说不考”我会单独存。考试前夜总有人去翻这个文件夹。
   来源：[src/data/cc98.posts.json:493](../src/data/cc98.posts.json#L493)
820. 保留
   来源：[src/data/cc98.posts.json:494](../src/data/cc98.posts.json#L494)
821. 高数目录里的图书馆规则别删，022 这次要靠它确认座位。
   来源：[src/data/cc98.posts.json:494](../src/data/cc98.posts.json#L494)
822. 反向实测
   来源：[src/data/cc98.posts.json:495](../src/data/cc98.posts.json#L495)
823. 我输入完整课程名，首页先给了三条选课通知。索引能不能再靠前一点？
   来源：[src/data/cc98.posts.json:495](../src/data/cc98.posts.json#L495)
824. 下载
   来源：[src/data/cc98.posts.json:496](../src/data/cc98.posts.json#L496)；[src/data/cc98.posts.json:749](../src/data/cc98.posts.json#L749)
825. 资料不用钱，下载到 99% 断掉后，我得再付一遍流量。
   来源：[src/data/cc98.posts.json:496](../src/data/cc98.posts.json#L496)
826. 蹲蹲
   来源：[src/data/cc98.posts.json:497](../src/data/cc98.posts.json#L497)
827. 请补版本日期、页数和来源。只有“最终版”，我无法判断是哪一天的最终版。
   来源：[src/data/cc98.posts.json:497](../src/data/cc98.posts.json#L497)
828. 六分钱余额
   来源：[src/data/cc98.posts.json:502](../src/data/cc98.posts.json#L502)
829. 校园卡
   来源：[src/data/cc98.posts.json:505](../src/data/cc98.posts.json#L505)；[src/data/cc98.posts.json:795](../src/data/cc98.posts.json#L795)；[src/data/cc98.posts.json:910](../src/data/cc98.posts.json#L910)；[src/scenes/phone/P02_CC98/index.tsx:215](../src/scenes/phone/P02_CC98/index.tsx#L215)；[src/scenes/rpg/RpgGameHost.tsx:2620](../src/scenes/rpg/RpgGameHost.tsx#L2620)
830. 余额 0.06 元能通过临时离座校验吗
   来源：[src/data/cc98.posts.json:506](../src/data/cc98.posts.json#L506)
831. 26-07-10 17:31
   来源：[src/data/cc98.posts.json:509](../src/data/cc98.posts.json#L509)
832. 实测可以。余额不会影响身份校验，系统仍然要求完整走完验证流程。
   来源：[src/data/cc98.posts.json:510](../src/data/cc98.posts.json#L510)
833. 标记为已实测
   来源：[src/data/cc98.posts.json:511](../src/data/cc98.posts.json#L511)
834. 楼主提供了低余额条件下的完整结果
   来源：[src/data/cc98.posts.json:511](../src/data/cc98.posts.json#L511)
835. 校园卡民间客服
   来源：[src/data/cc98.posts.json:511](../src/data/cc98.posts.json#L511)；[src/data/cc98.posts.json:801](../src/data/cc98.posts.json#L801)；[src/data/cc98.posts.json:916](../src/data/cc98.posts.json#L916)
836. 0.06 元能刷身份，打印一面还差一点。至少时间戳能留下。
   来源：[src/data/cc98.posts.json:514](../src/data/cc98.posts.json#L514)
837. 今天 17:33
   来源：[src/data/cc98.posts.json:514](../src/data/cc98.posts.json#L514)；[src/data/cc98.posts.json:585](../src/data/cc98.posts.json#L585)
838. 刷卡声很响，余额数字很小。旁边排队的人全听见了。
   来源：[src/data/cc98.posts.json:515](../src/data/cc98.posts.json#L515)
839. 门禁只看校园卡身份，余额写在另一个页面。我在入口看过。
   来源：[src/data/cc98.posts.json:516](../src/data/cc98.posts.json#L516)
840. 成本
   来源：[src/data/cc98.posts.json:517](../src/data/cc98.posts.json#L517)
841. 从求是潮骑去充值点再回来，比这次校验本身久。
   来源：[src/data/cc98.posts.json:517](../src/data/cc98.posts.json#L517)
842. 今天 17:40
   来源：[src/data/cc98.posts.json:517](../src/data/cc98.posts.json#L517)
843. 本人
   来源：[src/data/cc98.posts.json:518](../src/data/cc98.posts.json#L518)
844. 楼主在。0.06 元够我做身份核验，其他事要等以后。
   来源：[src/data/cc98.posts.json:518](../src/data/cc98.posts.json#L518)
845. 实测结果已留档。低余额可核验，恢复申请仍要完成。
   来源：[src/data/cc98.posts.json:519](../src/data/cc98.posts.json#L519)
846. 众筹
   来源：[src/data/cc98.posts.json:519](../src/data/cc98.posts.json#L519)
847. 体艺第47次
   来源：[src/data/cc98.posts.json:524](../src/data/cc98.posts.json#L524)
848. 校园生活
   来源：[src/data/cc98.posts.json:527](../src/data/cc98.posts.json#L527)；[src/data/cc98.posts.json:615](../src/data/cc98.posts.json#L615)；[src/data/cc98.posts.json:659](../src/data/cc98.posts.json#L659)；[src/data/cc98.posts.json:891](../src/data/cc98.posts.json#L891)；[src/scenes/phone/P02_CC98/index.tsx:72](../src/scenes/phone/P02_CC98/index.tsx#L72)；[src/scenes/phone/P02_CC98/index.tsx:204](../src/scenes/phone/P02_CC98/index.tsx#L204)；[src/scenes/phone/P02_CC98/index.tsx:206](../src/scenes/phone/P02_CC98/index.tsx#L206)
849. 今天的运动记录全是绕自行车
   来源：[src/data/cc98.posts.json:528](../src/data/cc98.posts.json#L528)
850. 26-07-10 17:28
   来源：[src/data/cc98.posts.json:531](../src/data/cc98.posts.json#L531)
851. 体艺记录显示四十七次通行，实际过程是在求是潮两侧反复寻找能走的缝隙。
   来源：[src/data/cc98.posts.json:532](../src/data/cc98.posts.json#L532)
852. 计入特殊路线样本
   来源：[src/data/cc98.posts.json:533](../src/data/cc98.posts.json#L533)
853. 课外锻炼观察组
   来源：[src/data/cc98.posts.json:533](../src/data/cc98.posts.json#L533)
854. 路线确有移动，运动目的暂无法判断
   来源：[src/data/cc98.posts.json:533](../src/data/cc98.posts.json#L533)
855. 从 17:28 到 17:42，我绕同一辆车四十七次。打印队都没它绕得久。
   来源：[src/data/cc98.posts.json:536](../src/data/cc98.posts.json#L536)
856. 分账
   来源：[src/data/cc98.posts.json:536](../src/data/cc98.posts.json#L536)
857. 今天 17:30
   来源：[src/data/cc98.posts.json:536](../src/data/cc98.posts.json#L536)；[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)；[src/data/cc98.posts.json:607](../src/data/cc98.posts.json#L607)
858. 北口风大，人走得慢。三步一停，体艺还是把它记成通行。
   来源：[src/data/cc98.posts.json:537](../src/data/cc98.posts.json#L537)
859. 今天 17:32
   来源：[src/data/cc98.posts.json:537](../src/data/cc98.posts.json#L537)；[src/data/cc98.posts.json:561](../src/data/cc98.posts.json#L561)
860. 逆风
   来源：[src/data/cc98.posts.json:537](../src/data/cc98.posts.json#L537)
861. 二南门口那辆车一直横在外侧，旁边还有一辆车把它挡住。
   来源：[src/data/cc98.posts.json:538](../src/data/cc98.posts.json#L538)
862. 命名
   来源：[src/data/cc98.posts.json:538](../src/data/cc98.posts.json#L538)
863. 车流在路口回堵，骑车的人掉头，步行的人跟着让。两分钟没过一个灯。
   来源：[src/data/cc98.posts.json:539](../src/data/cc98.posts.json#L539)
864. 今天 17:36
   来源：[src/data/cc98.posts.json:539](../src/data/cc98.posts.json#L539)；[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
865. 步数进账了，目的地没到。体艺记录和我今天的路线各算各的。
   来源：[src/data/cc98.posts.json:540](../src/data/cc98.posts.json#L540)
866. 收益
   来源：[src/data/cc98.posts.json:540](../src/data/cc98.posts.json#L540)
867. 凑整
   来源：[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
868. 记录有效。位移反复发生，终点未到。这条路线该单列。
   来源：[src/data/cc98.posts.json:541](../src/data/cc98.posts.json#L541)
869. 西区打印排队中
   来源：[src/data/cc98.posts.json:546](../src/data/cc98.posts.json#L546)
870. 打印服务
   来源：[src/data/cc98.posts.json:549](../src/data/cc98.posts.json#L549)；[src/data/cc98.posts.json:757](../src/data/cc98.posts.json#L757)；[src/scenes/phone/P02_CC98/index.tsx:214](../src/scenes/phone/P02_CC98/index.tsx#L214)
871. 西区打印店早上哪台机快一点
   来源：[src/data/cc98.posts.json:550](../src/data/cc98.posts.json#L550)
872. 今天 08:10 到西区打印店，前面有六个人。双面黑白先空出来，彩打那台一直在换纸。赶早课的可以先打黑白。
   来源：[src/data/cc98.posts.json:554](../src/data/cc98.posts.json#L554)
873. 补充机器状态
   来源：[src/data/cc98.posts.json:555](../src/data/cc98.posts.json#L555)
874. 打印店排队记录员
   来源：[src/data/cc98.posts.json:555](../src/data/cc98.posts.json#L555)；[src/data/cc98.posts.json:763](../src/data/cc98.posts.json#L763)
875. 楼主记录了到店时间和两台机器的使用情况
   来源：[src/data/cc98.posts.json:555](../src/data/cc98.posts.json#L555)
876. 08:13 我在左边那台打完 18 页，自动双面没有卡纸。
   来源：[src/data/cc98.posts.json:558](../src/data/cc98.posts.json#L558)
877. 门口的取件架今天挪到右手边，拿完别站在入口数页码。
   来源：[src/data/cc98.posts.json:559](../src/data/cc98.posts.json#L559)
878. 细节
   来源：[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
879. 装订机旁边那台需要先在屏幕上选纸型，直接塞纸会退回。
   来源：[src/data/cc98.posts.json:560](../src/data/cc98.posts.json#L560)
880. 从西区食堂后门过去，08:20 还不用排到台阶上。
   来源：[src/data/cc98.posts.json:561](../src/data/cc98.posts.json#L561)
881. 付款
   来源：[src/data/cc98.posts.json:562](../src/data/cc98.posts.json#L562)
882. 校园卡余额不够时可以先用手机付，机器会保留刚才选的份数。
   来源：[src/data/cc98.posts.json:562](../src/data/cc98.posts.json#L562)
883. 把到店时间、机器编号和纸张规格写在订单上，之后找文件方便。
   来源：[src/data/cc98.posts.json:563](../src/data/cc98.posts.json#L563)
884. 闭馆后找座位
   来源：[src/data/cc98.posts.json:568](../src/data/cc98.posts.json#L568)
885. 自习室
   来源：[src/data/cc98.posts.json:571](../src/data/cc98.posts.json#L571)；[src/data/cc98.posts.json:929](../src/data/cc98.posts.json#L929)；[src/scenes/phone/P02_CC98/index.tsx:212](../src/scenes/phone/P02_CC98/index.tsx#L212)
886. 基础图书馆闭馆后还有安静的位置吗
   来源：[src/data/cc98.posts.json:572](../src/data/cc98.posts.json#L572)
887. 26-07-10 17:21
   来源：[src/data/cc98.posts.json:575](../src/data/cc98.posts.json#L575)
888. 昨晚 19:35 从基础图书馆二楼出来，雨衣没带，就去麦斯威靠窗那排坐到 20:10。插座在桌脚边，带长线会好用一点。
   来源：[src/data/cc98.posts.json:576](../src/data/cc98.posts.json#L576)
889. 加入自习地点索引
   来源：[src/data/cc98.posts.json:577](../src/data/cc98.posts.json#L577)
890. 帖子提供了闭馆后的实际座位和插座位置
   来源：[src/data/cc98.posts.json:577](../src/data/cc98.posts.json#L577)
891. 夜间自习信息台
   来源：[src/data/cc98.posts.json:577](../src/data/cc98.posts.json#L577)；[src/data/cc98.posts.json:935](../src/data/cc98.posts.json#L935)
892. 麦斯威二楼 19:50 还有空桌，靠窗的位置灯比较亮。
   来源：[src/data/cc98.posts.json:580](../src/data/cc98.posts.json#L580)
893. 雨天
   来源：[src/data/cc98.posts.json:581](../src/data/cc98.posts.json#L581)
894. 昨晚雨大，门口地垫湿了。伞先套袋再进座位区。
   来源：[src/data/cc98.posts.json:581](../src/data/cc98.posts.json#L581)
895. 插座
   来源：[src/data/cc98.posts.json:582](../src/data/cc98.posts.json#L582)
896. 今天 17:27
   来源：[src/data/cc98.posts.json:582](../src/data/cc98.posts.json#L582)；[src/data/cc98.posts.json:629](../src/data/cc98.posts.json#L629)
897. 靠墙第三张桌的插座松，手机充电会断，电脑最好接靠柱子的那排。
   来源：[src/data/cc98.posts.json:582](../src/data/cc98.posts.json#L582)
898. 到店
   来源：[src/data/cc98.posts.json:583](../src/data/cc98.posts.json#L583)
899. 今天 17:29
   来源：[src/data/cc98.posts.json:583](../src/data/cc98.posts.json#L583)
900. 我 20:05 从东门进，店里有人开线上会议，想安静写题记得带耳塞。
   来源：[src/data/cc98.posts.json:583](../src/data/cc98.posts.json#L583)
901. 热水要在一楼吧台旁接，带杯子比临时买饮料省时间。
   来源：[src/data/cc98.posts.json:584](../src/data/cc98.posts.json#L584)
902. 消费
   来源：[src/data/cc98.posts.json:584](../src/data/cc98.posts.json#L584)
903. 离开前看一下桌面和插座，闭馆后的座位没有统一失物招领提醒。
   来源：[src/data/cc98.posts.json:585](../src/data/cc98.posts.json#L585)
904. 三楼最后一勺
   来源：[src/data/cc98.posts.json:590](../src/data/cc98.posts.json#L590)
905. 食堂
   来源：[src/data/cc98.posts.json:593](../src/data/cc98.posts.json#L593)；[src/data/cc98.posts.json:679](../src/data/cc98.posts.json#L679)；[src/data/cc98.posts.json:986](../src/data/cc98.posts.json#L986)；[src/scenes/phone/P02_CC98/index.tsx:213](../src/scenes/phone/P02_CC98/index.tsx#L213)
906. 东二食堂三楼炒饭晚上几点收窗口
   来源：[src/data/cc98.posts.json:594](../src/data/cc98.posts.json#L594)
907. 26-07-10 17:18
   来源：[src/data/cc98.posts.json:597](../src/data/cc98.posts.json#L597)
908. 昨晚 18:50 去东二食堂三楼，炒饭窗口还接单，19:05 只剩蛋炒饭。想加青菜的要早点去，打包盒在窗口右边自己拿。
   来源：[src/data/cc98.posts.json:598](../src/data/cc98.posts.json#L598)
909. 补充窗口时间
   来源：[src/data/cc98.posts.json:599](../src/data/cc98.posts.json#L599)
910. 东二饭点记录
   来源：[src/data/cc98.posts.json:599](../src/data/cc98.posts.json#L599)；[src/data/cc98.posts.json:685](../src/data/cc98.posts.json#L685)；[src/data/cc98.posts.json:992](../src/data/cc98.posts.json#L992)
911. 楼主给出了到店时间和当天剩余餐品
   来源：[src/data/cc98.posts.json:599](../src/data/cc98.posts.json#L599)
912. 18:40 去还有青菜炒饭，取餐区右侧的勺子需要自己拿。
   来源：[src/data/cc98.posts.json:602](../src/data/cc98.posts.json#L602)
913. 饭点
   来源：[src/data/cc98.posts.json:602](../src/data/cc98.posts.json#L602)
914. 今天 17:20
   来源：[src/data/cc98.posts.json:602](../src/data/cc98.posts.json#L602)；[src/data/cc98.posts.json:649](../src/data/cc98.posts.json#L649)
915. 今天 17:22
   来源：[src/data/cc98.posts.json:603](../src/data/cc98.posts.json#L603)；[src/data/cc98.posts.json:650](../src/data/cc98.posts.json#L650)
916. 排队
   来源：[src/data/cc98.posts.json:603](../src/data/cc98.posts.json#L603)；[src/data/cc98.posts.json:690](../src/data/cc98.posts.json#L690)；[src/data/cc98.posts.json:766](../src/data/cc98.posts.json#L766)
917. 下雨天大家都从南门进，18:45 后南门那条队会拐到柱子后面。
   来源：[src/data/cc98.posts.json:603](../src/data/cc98.posts.json#L603)
918. 今天 17:24
   来源：[src/data/cc98.posts.json:604](../src/data/cc98.posts.json#L604)；[src/data/cc98.posts.json:651](../src/data/cc98.posts.json#L651)
919. 三楼靠窗两排桌子先被占满，端着餐盘上去前先看一眼空位。
   来源：[src/data/cc98.posts.json:604](../src/data/cc98.posts.json#L604)
920. 座位
   来源：[src/data/cc98.posts.json:604](../src/data/cc98.posts.json#L604)；[src/data/itemCatalog.ts:32](../src/data/itemCatalog.ts#L32)；[src/scenes/phone/P15_Zjuding/index.tsx:1811](../src/scenes/phone/P15_Zjuding/index.tsx#L1811)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
921. 到达
   来源：[src/data/cc98.posts.json:605](../src/data/cc98.posts.json#L605)
922. 我从东门骑过去，18:55 才停好车，窗口已经开始收配菜。
   来源：[src/data/cc98.posts.json:605](../src/data/cc98.posts.json#L605)
923. 打包盒不收钱，筷子在取餐台下层。刚才找了三分钟。
   来源：[src/data/cc98.posts.json:606](../src/data/cc98.posts.json#L606)
924. 支付
   来源：[src/data/cc98.posts.json:606](../src/data/cc98.posts.json#L606)
925. 窗口时间会按当天备菜量变，想稳妥就按 18:40 到店安排。
   来源：[src/data/cc98.posts.json:607](../src/data/cc98.posts.json#L607)
926. 雨天伞套管理员
   来源：[src/data/cc98.posts.json:612](../src/data/cc98.posts.json#L612)
927. 教学楼门口的伞套机今天放哪边了
   来源：[src/data/cc98.posts.json:616](../src/data/cc98.posts.json#L616)
928. 26-07-10 17:15
   来源：[src/data/cc98.posts.json:619](../src/data/cc98.posts.json#L619)
929. 今天 16:20 到东教学楼，伞套机从门左边移到了门卫桌旁。机器没纸时可以先去旁边的小篮子拿，别把湿伞直接带进走廊。
   来源：[src/data/cc98.posts.json:620](../src/data/cc98.posts.json#L620)
930. 补充入口位置
   来源：[src/data/cc98.posts.json:621](../src/data/cc98.posts.json#L621)
931. 伞套机和备用伞套的位置都已说明
   来源：[src/data/cc98.posts.json:621](../src/data/cc98.posts.json#L621)
932. 雨天通行提醒
   来源：[src/data/cc98.posts.json:621](../src/data/cc98.posts.json#L621)
933. 16:25 备用篮还有一半，拿完要把伞尖朝下放。
   来源：[src/data/cc98.posts.json:624](../src/data/cc98.posts.json#L624)
934. 今天 17:19
   来源：[src/data/cc98.posts.json:625](../src/data/cc98.posts.json#L625)
935. 天气
   来源：[src/data/cc98.posts.json:625](../src/data/cc98.posts.json#L625)；[src/scenes/phone/P07_Weather/index.tsx:98](../src/scenes/phone/P07_Weather/index.tsx#L98)；[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)；[src/scenes/phone/P13_PhoneHome/index.tsx:852](../src/scenes/phone/P13_PhoneHome/index.tsx#L852)；[src/scenes/phone/P13_PhoneHome/index.tsx:858](../src/scenes/phone/P13_PhoneHome/index.tsx#L858)
936. 雨水会顺着门槛流进去，进门后先在地垫上停两步。
   来源：[src/data/cc98.posts.json:625](../src/data/cc98.posts.json#L625)
937. 摆放
   来源：[src/data/cc98.posts.json:626](../src/data/cc98.posts.json#L626)
938. 伞架右侧那一格空着，长柄伞别横放，会挡住旁边的人。
   来源：[src/data/cc98.posts.json:626](../src/data/cc98.posts.json#L626)
939. 骑车到门口后先推到屋檐下，直接停在入口会挡住送货车。
   来源：[src/data/cc98.posts.json:627](../src/data/cc98.posts.json#L627)
940. 通行
   来源：[src/data/cc98.posts.json:627](../src/data/cc98.posts.json#L627)
941. 备用伞套不用刷卡，旁边的饮水机才需要校园卡。
   来源：[src/data/cc98.posts.json:628](../src/data/cc98.posts.json#L628)
942. 入口改过位置后，最好把门左和门右都看一遍，免得回头找。
   来源：[src/data/cc98.posts.json:629](../src/data/cc98.posts.json#L629)
943. 晚课后抄题人
   来源：[src/data/cc98.posts.json:634](../src/data/cc98.posts.json#L634)
944. 线代课后题有人用同一版空白答题纸吗
   来源：[src/data/cc98.posts.json:638](../src/data/cc98.posts.json#L638)
945. 周三 21:10 在西区教学楼打印室找空白答题纸，最后在靠窗的文件架第二层看到一叠。纸张右上角有课程简称，拿之前先数清页数。
   来源：[src/data/cc98.posts.json:642](../src/data/cc98.posts.json#L642)
946. 补充取用位置
   来源：[src/data/cc98.posts.json:643](../src/data/cc98.posts.json#L643)
947. 楼主说明了寻找时间、房间和文件架层数
   来源：[src/data/cc98.posts.json:643](../src/data/cc98.posts.json#L643)
948. 学习资料互助台
   来源：[src/data/cc98.posts.json:643](../src/data/cc98.posts.json#L643)
949. 我拿到的是六页版，最后一页有老师留的空白演算区。
   来源：[src/data/cc98.posts.json:646](../src/data/cc98.posts.json#L646)
950. 资料
   来源：[src/data/cc98.posts.json:646](../src/data/cc98.posts.json#L646)；[src/data/cc98.posts.json:668](../src/data/cc98.posts.json#L668)
951. 今天 17:16
   来源：[src/data/cc98.posts.json:647](../src/data/cc98.posts.json#L647)；[src/data/cc98.posts.json:671](../src/data/cc98.posts.json#L671)
952. 文件架旁边的窗没关，纸角有点卷，带夹子会好拿。
   来源：[src/data/cc98.posts.json:647](../src/data/cc98.posts.json#L647)
953. 同一层还有一叠概率论的纸，课程简称只差一个字，别拿错。
   来源：[src/data/cc98.posts.json:648](../src/data/cc98.posts.json#L648)
954. 从西区教学楼南门进，沿走廊到头再右转，打印室就在饮水机旁。
   来源：[src/data/cc98.posts.json:649](../src/data/cc98.posts.json#L649)
955. 复印
   来源：[src/data/cc98.posts.json:650](../src/data/cc98.posts.json#L650)
956. 只要空白纸的话，复印机不用开机，先看文件架的标签。
   来源：[src/data/cc98.posts.json:650](../src/data/cc98.posts.json#L650)
957. 拿走后在帖子里写一下版本和页数，后来的人就不用逐叠翻。
   来源：[src/data/cc98.posts.json:651](../src/data/cc98.posts.json#L651)
958. 整理
   来源：[src/data/cc98.posts.json:651](../src/data/cc98.posts.json#L651)；[src/data/cc98.posts.json:826](../src/data/cc98.posts.json#L826)
959. 雨天走南门
   来源：[src/data/cc98.posts.json:656](../src/data/cc98.posts.json#L656)
960. 雨还没停，东教学楼哪扇门口不积水
   来源：[src/data/cc98.posts.json:660](../src/data/cc98.posts.json#L660)
961. 刚从东教学楼出来，西侧玻璃门前的地垫已经湿透。南边侧门的地面还干一点，手里有纸和电脑的可以从那边进。
   来源：[src/data/cc98.posts.json:664](../src/data/cc98.posts.json#L664)
962. 保留雨天通行记录
   来源：[src/data/cc98.posts.json:665](../src/data/cc98.posts.json#L665)
963. 楼主说明了两处门口的地面情况
   来源：[src/data/cc98.posts.json:665](../src/data/cc98.posts.json#L665)
964. 校园生活值班员
   来源：[src/data/cc98.posts.json:665](../src/data/cc98.posts.json#L665)；[src/data/cc98.posts.json:897](../src/data/cc98.posts.json#L897)
965. 西侧那块地垫已经软了，早八带纸质资料的还是绕南边。
   来源：[src/data/cc98.posts.json:668](../src/data/cc98.posts.json#L668)
966. 我从南侧门进，门口有一串伞套，走进去还算干。
   来源：[src/data/cc98.posts.json:669](../src/data/cc98.posts.json#L669)
967. 侧门的扶手有水，进门时别一边看手机一边跨门槛。
   来源：[src/data/cc98.posts.json:670](../src/data/cc98.posts.json#L670)
968. 二十分钟前路过，南边那块地还没积水。
   来源：[src/data/cc98.posts.json:671](../src/data/cc98.posts.json#L671)
969. 更新
   来源：[src/data/cc98.posts.json:671](../src/data/cc98.posts.json#L671)
970. 端盘找座位
   来源：[src/data/cc98.posts.json:676](../src/data/cc98.posts.json#L676)
971. 东二晚高峰的空座是在二楼还是三楼
   来源：[src/data/cc98.posts.json:680](../src/data/cc98.posts.json#L680)
972. 傍晚六点二十到东二时二楼靠门的桌子已经满了，三楼最里面还有两张四人桌。想先放包再去排队的，记得别把通道边的空椅子当座位。
   来源：[src/data/cc98.posts.json:684](../src/data/cc98.posts.json#L684)
973. 补充座位信息
   来源：[src/data/cc98.posts.json:685](../src/data/cc98.posts.json#L685)
974. 楼主记录了到店时间和可用桌位
   来源：[src/data/cc98.posts.json:685](../src/data/cc98.posts.json#L685)
975. 晚到
   来源：[src/data/cc98.posts.json:688](../src/data/cc98.posts.json#L688)
976. 我六点三十五才上三楼，里面那两张桌已经有人坐下了。
   来源：[src/data/cc98.posts.json:688](../src/data/cc98.posts.json#L688)
977. 二楼饮水机旁的两把椅子在等人，别端着盘子站过去。
   来源：[src/data/cc98.posts.json:689](../src/data/cc98.posts.json#L689)
978. 观察
   来源：[src/data/cc98.posts.json:689](../src/data/cc98.posts.json#L689)
979. 今天 17:11
   来源：[src/data/cc98.posts.json:690](../src/data/cc98.posts.json#L690)
980. 三楼窗口排得慢一点，座位倒是比二楼松。
   来源：[src/data/cc98.posts.json:690](../src/data/cc98.posts.json#L690)
981. 今天 17:13
   来源：[src/data/cc98.posts.json:691](../src/data/cc98.posts.json#L691)
982. 想快点吃就二楼排队，想坐下就先上三楼看一圈。
   来源：[src/data/cc98.posts.json:691](../src/data/cc98.posts.json#L691)
983. 门口捡眼镜
   来源：[src/data/cc98.posts.json:696](../src/data/cc98.posts.json#L696)
984. 失物招领
   来源：[src/data/cc98.posts.json:699](../src/data/cc98.posts.json#L699)；[src/data/cc98.posts.json:967](../src/data/cc98.posts.json#L967)；[src/scenes/phone/P02_CC98/index.tsx:216](../src/scenes/phone/P02_CC98/index.tsx#L216)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:105](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L105)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:73](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L73)
985. 东区食堂门口捡到一副黑框眼镜
   来源：[src/data/cc98.posts.json:700](../src/data/cc98.posts.json#L700)
986. 傍晚在东区食堂南门台阶边捡到一副黑框眼镜，镜腿内侧有一小段白色贴纸。我交到一楼服务台了，失主去问时带一下能核对的信息。
   来源：[src/data/cc98.posts.json:704](../src/data/cc98.posts.json#L704)
987. 标记服务台已接收
   来源：[src/data/cc98.posts.json:705](../src/data/cc98.posts.json#L705)
988. 失物招领版面
   来源：[src/data/cc98.posts.json:705](../src/data/cc98.posts.json#L705)；[src/data/cc98.posts.json:973](../src/data/cc98.posts.json#L973)
989. 物品去向和辨认特征已经写明
   来源：[src/data/cc98.posts.json:705](../src/data/cc98.posts.json#L705)
990. 贴纸上有没有课程名，我室友下午刚丢了一副。
   来源：[src/data/cc98.posts.json:708](../src/data/cc98.posts.json#L708)
991. 问询
   来源：[src/data/cc98.posts.json:708](../src/data/cc98.posts.json#L708)
992. 先别把镜片度数写出来，服务台核对时再说。
   来源：[src/data/cc98.posts.json:709](../src/data/cc98.posts.json#L709)
993. 今天 17:08
   来源：[src/data/cc98.posts.json:710](../src/data/cc98.posts.json#L710)
994. 南门台阶晚上人多，走的时候最好把东西放包里。
   来源：[src/data/cc98.posts.json:710](../src/data/cc98.posts.json#L710)
995. 剧场外等雨小组
   来源：[src/data/cc98.posts.json:715](../src/data/cc98.posts.json#L715)
996. 从剧场走去湖边，雨后哪段路灯更亮
   来源：[src/data/cc98.posts.json:719](../src/data/cc98.posts.json#L719)
997. 26-07-10 16:58
   来源：[src/data/cc98.posts.json:722](../src/data/cc98.posts.json#L722)
998. 演出散场后往湖边走，靠外侧的树下那段光比较暗，石板也有水。绕到主路再下去会多走几分钟，路面和灯都好一点。
   来源：[src/data/cc98.posts.json:723](../src/data/cc98.posts.json#L723)
999. 加入雨后步行提醒
   来源：[src/data/cc98.posts.json:724](../src/data/cc98.posts.json#L724)
1000. 楼主写清了两条路线的差别
   来源：[src/data/cc98.posts.json:724](../src/data/cc98.posts.json#L724)
1001. 夜间步行信息台
   来源：[src/data/cc98.posts.json:724](../src/data/cc98.posts.json#L724)
1002. 骑行
   来源：[src/data/cc98.posts.json:727](../src/data/cc98.posts.json#L727)
1003. 主路有积水反光，骑车也别压着边沿走。
   来源：[src/data/cc98.posts.json:727](../src/data/cc98.posts.json#L727)
1004. 风向
   来源：[src/data/cc98.posts.json:728](../src/data/cc98.posts.json#L728)；[src/scenes/phone/P07_Weather/index.tsx:131](../src/scenes/phone/P07_Weather/index.tsx#L131)
1005. 湖边风比剧场外大，伞撑不住时先收起来。
   来源：[src/data/cc98.posts.json:728](../src/data/cc98.posts.json#L728)
1006. 今天 17:02
   来源：[src/data/cc98.posts.json:728](../src/data/cc98.posts.json#L728)
1007. 时间
   来源：[src/data/cc98.posts.json:729](../src/data/cc98.posts.json#L729)；[src/data/cc98.posts.json:805](../src/data/cc98.posts.json#L805)；[src/data/itemCatalog.ts:94](../src/data/itemCatalog.ts#L94)；[src/scenes/phone/P15_Zjuding/index.tsx:404](../src/scenes/phone/P15_Zjuding/index.tsx#L404)
1008. 我多走了三分钟，鞋底没沾上泥，值。
   来源：[src/data/cc98.posts.json:729](../src/data/cc98.posts.json#L729)
1009. 夜里走主路，别沿着树影那边抄近道。
   来源：[src/data/cc98.posts.json:730](../src/data/cc98.posts.json#L730)
1010. 页码强迫症
   来源：[src/data/cc98.posts.json:735](../src/data/cc98.posts.json#L735)
1011. 化工原理旧卷的页码有人补齐了吗
   来源：[src/data/cc98.posts.json:739](../src/data/cc98.posts.json#L739)
1012. 26-07-10 16:54
   来源：[src/data/cc98.posts.json:742](../src/data/cc98.posts.json#L742)
1013. 资料夹里有两份同年份旧卷，一份从第六页直接跳到第八页。我把缺页题号记下来了，想问有没有人留着完整扫描版，能顺手核对一下。
   来源：[src/data/cc98.posts.json:743](../src/data/cc98.posts.json#L743)
1014. 保留缺页标记
   来源：[src/data/cc98.posts.json:744](../src/data/cc98.posts.json#L744)
1015. 楼主指出了具体版本和缺失位置
   来源：[src/data/cc98.posts.json:744](../src/data/cc98.posts.json#L744)
1016. 今天 16:56
   来源：[src/data/cc98.posts.json:747](../src/data/cc98.posts.json#L747)；[src/data/cc98.posts.json:768](../src/data/cc98.posts.json#L768)
1017. 文件
   来源：[src/data/cc98.posts.json:747](../src/data/cc98.posts.json#L747)
1018. 我手里的版本是八页，周末回寝室再找一下原件。
   来源：[src/data/cc98.posts.json:747](../src/data/cc98.posts.json#L747)
1019. 第七页是传热那道图题，只有题干没有答案。
   来源：[src/data/cc98.posts.json:748](../src/data/cc98.posts.json#L748)
1020. 不要把缺页版覆盖原文件，后面的人还要比对来源。
   来源：[src/data/cc98.posts.json:749](../src/data/cc98.posts.json#L749)
1021. 胶圈带少了
   来源：[src/data/cc98.posts.json:754](../src/data/cc98.posts.json#L754)
1022. 打印室的装订机还需要自己带胶圈吗
   来源：[src/data/cc98.posts.json:758](../src/data/cc98.posts.json#L758)
1023. 西区教学楼打印室的装订机能用，桌上只剩小号胶圈。报告超过四十页的，最好自己带一包，临时等补货容易赶不上上课。
   来源：[src/data/cc98.posts.json:762](../src/data/cc98.posts.json#L762)
1024. 补充耗材状态
   来源：[src/data/cc98.posts.json:763](../src/data/cc98.posts.json#L763)
1025. 楼主说明了机器和胶圈的现状
   来源：[src/data/cc98.posts.json:763](../src/data/cc98.posts.json#L763)
1026. 刚才有人拿五十页去装，店员让他分两本。
   来源：[src/data/cc98.posts.json:766](../src/data/cc98.posts.json#L766)
1027. 透明封面在最下面一层抽屉，第一次去很容易漏看。
   来源：[src/data/cc98.posts.json:767](../src/data/cc98.posts.json#L767)
1028. 页数多就分两册，翻起来也省事。
   来源：[src/data/cc98.posts.json:768](../src/data/cc98.posts.json#L768)
1029. 二楼靠窗充电中
   来源：[src/data/cc98.posts.json:773](../src/data/cc98.posts.json#L773)
1030. 基础图书馆二楼靠窗的插座这两天还稳吗
   来源：[src/data/cc98.posts.json:777](../src/data/cc98.posts.json#L777)
1031. 26-07-10 16:46
   来源：[src/data/cc98.posts.json:780](../src/data/cc98.posts.json#L780)
1032. 昨天靠窗第三张桌的插座断过两次，换到靠柱子那排后正常。今天要带电脑写作业的，先别把座位选在窗边最里面。
   来源：[src/data/cc98.posts.json:781](../src/data/cc98.posts.json#L781)
1033. 补充插座状态
   来源：[src/data/cc98.posts.json:782](../src/data/cc98.posts.json#L782)
1034. 楼主给出了异常位置和替代位置
   来源：[src/data/cc98.posts.json:782](../src/data/cc98.posts.json#L782)
1035. 图书馆设备记录
   来源：[src/data/cc98.posts.json:782](../src/data/cc98.posts.json#L782)
1036. 复测
   来源：[src/data/cc98.posts.json:785](../src/data/cc98.posts.json#L785)
1037. 我下午试了两次，靠窗第三张桌还是会松。
   来源：[src/data/cc98.posts.json:785](../src/data/cc98.posts.json#L785)
1038. 今天 16:50
   来源：[src/data/cc98.posts.json:786](../src/data/cc98.posts.json#L786)
1039. 靠柱子那排有两个空口，插头比较紧。
   来源：[src/data/cc98.posts.json:786](../src/data/cc98.posts.json#L786)
1040. 替代
   来源：[src/data/cc98.posts.json:786](../src/data/cc98.posts.json#L786)
1041. 别把插线板横在过道，借书车会从那里过。
   来源：[src/data/cc98.posts.json:787](../src/data/cc98.posts.json#L787)
1042. 补办卡排队中
   来源：[src/data/cc98.posts.json:792](../src/data/cc98.posts.json#L792)
1043. 校园卡补办当天能进图书馆吗
   来源：[src/data/cc98.posts.json:796](../src/data/cc98.posts.json#L796)
1044. 26-07-10 16:42
   来源：[src/data/cc98.posts.json:799](../src/data/cc98.posts.json#L799)
1045. 今天上午卡丢了，补办后先在机器上做了一次身份核验，下午进基础图书馆没有被拦。旧卡已经停用，带着旧卡去刷只会多排一次队。
   来源：[src/data/cc98.posts.json:800](../src/data/cc98.posts.json#L800)
1046. 标记为当日记录
   来源：[src/data/cc98.posts.json:801](../src/data/cc98.posts.json#L801)
1047. 楼主说明了补办后的验证和入馆结果
   来源：[src/data/cc98.posts.json:801](../src/data/cc98.posts.json#L801)
1048. 补办后先看卡面编号，机器读取到新号才算完成。
   来源：[src/data/cc98.posts.json:804](../src/data/cc98.posts.json#L804)
1049. 今天 16:44
   来源：[src/data/cc98.posts.json:804](../src/data/cc98.posts.json#L804)；[src/data/cc98.posts.json:825](../src/data/cc98.posts.json#L825)
1050. 中午人少一点，柜台和机器都不用等太久。
   来源：[src/data/cc98.posts.json:805](../src/data/cc98.posts.json#L805)
1051. 丢卡先停用，补办当天把新卡做一次验证。
   来源：[src/data/cc98.posts.json:806](../src/data/cc98.posts.json#L806)
1052. 信号格满了
   来源：[src/data/cc98.posts.json:811](../src/data/cc98.posts.json#L811)
1053. 手机服务
   来源：[src/data/cc98.posts.json:814](../src/data/cc98.posts.json#L814)；[src/scenes/phone/P02_CC98/index.tsx:210](../src/scenes/phone/P02_CC98/index.tsx#L210)
1054. 【移动/联通/电信】2026年校园电话卡信息汇总帖 详情请戳
   来源：[src/data/cc98.posts.json:815](../src/data/cc98.posts.json#L815)
1055. 准备开学换号的可以先把套餐、校园区域覆盖和注销条件写在同一层回复里。只放海报截图很难比较，最好补充自己实测的宿舍、教学楼和地铁口信号。
   来源：[src/data/cc98.posts.json:819](../src/data/cc98.posts.json#L819)
1056. 讨论包含不同运营商的使用场景和办理提醒
   来源：[src/data/cc98.posts.json:820](../src/data/cc98.posts.json#L820)
1057. 校园通信互助台
   来源：[src/data/cc98.posts.json:820](../src/data/cc98.posts.json#L820)
1058. 整理为信息汇总
   来源：[src/data/cc98.posts.json:820](../src/data/cc98.posts.json#L820)
1059. 教学楼里先看自己常待的那一侧，办卡点的信号格不能代表上课的位置。
   来源：[src/data/cc98.posts.json:823](../src/data/cc98.posts.json#L823)
1060. 套餐写清楚是月租还是校园期，别把首月优惠当成长期价格。
   来源：[src/data/cc98.posts.json:824](../src/data/cc98.posts.json#L824)
1061. 想保留旧号码的先问转网和注销流程，开学那周柜台排队会很长。
   来源：[src/data/cc98.posts.json:825](../src/data/cc98.posts.json#L825)
1062. 楼里只保留可核对的套餐名称、适用期限和实测位置，广告图不单独计入结论。
   来源：[src/data/cc98.posts.json:826](../src/data/cc98.posts.json#L826)
1063. 图书馆门口的雨
   来源：[src/data/cc98.posts.json:831](../src/data/cc98.posts.json#L831)
1064. 雨伞在一楼，人在三楼，雨还在外面
   来源：[src/data/cc98.posts.json:835](../src/data/cc98.posts.json#L835)
1065. 26-07-10 16:34
   来源：[src/data/cc98.posts.json:838](../src/data/cc98.posts.json#L838)
1066. 本来只是下楼拿外卖，发现伞架里那把蓝伞很像我的。等我把伞带到三楼，才想起自己的伞还在寝室。
   来源：[src/data/cc98.posts.json:839](../src/data/cc98.posts.json#L839)
1067. 保留轻松讨论
   来源：[src/data/cc98.posts.json:840](../src/data/cc98.posts.json#L840)
1068. 回复围绕雨天小失误展开，没有涉及失物认领
   来源：[src/data/cc98.posts.json:840](../src/data/cc98.posts.json#L840)
1069. 今天 16:36
   来源：[src/data/cc98.posts.json:843](../src/data/cc98.posts.json#L843)；[src/data/cc98.posts.json:864](../src/data/cc98.posts.json#L864)
1070. 同款
   来源：[src/data/cc98.posts.json:843](../src/data/cc98.posts.json#L843)
1071. 我有一次带着空伞套走回寝室，雨伞在门口，套子在手里。
   来源：[src/data/cc98.posts.json:843](../src/data/cc98.posts.json#L843)
1072. 今天 16:38
   来源：[src/data/cc98.posts.json:844](../src/data/cc98.posts.json#L844)
1073. 确认
   来源：[src/data/cc98.posts.json:844](../src/data/cc98.posts.json#L844)；[src/data/cc98.posts.json:939](../src/data/cc98.posts.json#L939)
1074. 至少你把伞带到了需要它的楼层，进度已经过半。
   来源：[src/data/cc98.posts.json:844](../src/data/cc98.posts.json#L844)
1075. 补图
   来源：[src/data/cc98.posts.json:845](../src/data/cc98.posts.json#L845)
1076. 下雨天的记忆会自动把所有蓝伞归到自己名下。
   来源：[src/data/cc98.posts.json:845](../src/data/cc98.posts.json#L845)
1077. 晚八还在找耳机
   来源：[src/data/cc98.posts.json:850](../src/data/cc98.posts.json#L850)
1078. 耳机连上了隔壁桌，我听完了半节陌生人的网课
   来源：[src/data/cc98.posts.json:854](../src/data/cc98.posts.json#L854)
1079. 26-07-10 16:30
   来源：[src/data/cc98.posts.json:857](../src/data/cc98.posts.json#L857)
1080. 戴上耳机后发现讲课内容完全听不懂，还以为自己选错了章节。直到隔壁同学抬头问谁连到了他的设备，我才发现耳机名字还叫“默认设备”。
   来源：[src/data/cc98.posts.json:858](../src/data/cc98.posts.json#L858)
1081. 加入设备小事
   来源：[src/data/cc98.posts.json:859](../src/data/cc98.posts.json#L859)
1082. 帖子包含清楚的误连原因和轻松回复
   来源：[src/data/cc98.posts.json:859](../src/data/cc98.posts.json#L859)
1083. 今天 16:32
   来源：[src/data/cc98.posts.json:862](../src/data/cc98.posts.json#L862)；[src/data/cc98.posts.json:883](../src/data/cc98.posts.json#L883)
1084. 设备名改成自己看得懂的，图书馆里“默认设备”永远不止一个。
   来源：[src/data/cc98.posts.json:862](../src/data/cc98.posts.json#L862)
1085. 今天 16:34
   来源：[src/data/cc98.posts.json:863](../src/data/cc98.posts.json#L863)
1086. 我连过一段白噪音，找了五分钟才知道声音来自隔壁的平板。
   来源：[src/data/cc98.posts.json:863](../src/data/cc98.posts.json#L863)
1087. 陌生课程听不懂先别怀疑自己，先看蓝牙名称。
   来源：[src/data/cc98.posts.json:864](../src/data/cc98.posts.json#L864)
1088. 搬寝室清库存
   来源：[src/data/cc98.posts.json:869](../src/data/cc98.posts.json#L869)
1089. 二手市场
   来源：[src/data/cc98.posts.json:872](../src/data/cc98.posts.json#L872)；[src/scenes/phone/P02_CC98/index.tsx:217](../src/scenes/phone/P02_CC98/index.tsx#L217)
1090. 出一盏可调光台灯，限校内当面自取
   来源：[src/data/cc98.posts.json:873](../src/data/cc98.posts.json#L873)
1091. 26-07-10 16:26
   来源：[src/data/cc98.posts.json:876](../src/data/cc98.posts.json#L876)
1092. 台灯用了两学期，触控和调光都正常，电源线在。只约公共区域当面试亮，想要的带上能确认时间的人再联系。
   来源：[src/data/cc98.posts.json:877](../src/data/cc98.posts.json#L877)
1093. 补充交易边界
   来源：[src/data/cc98.posts.json:878](../src/data/cc98.posts.json#L878)
1094. 二手市场提醒员
   来源：[src/data/cc98.posts.json:878](../src/data/cc98.posts.json#L878)
1095. 楼主提供了物品状态、交接方式和试用条件
   来源：[src/data/cc98.posts.json:878](../src/data/cc98.posts.json#L878)
1096. 今天 16:28
   来源：[src/data/cc98.posts.json:881](../src/data/cc98.posts.json#L881)；[src/data/cc98.posts.json:902](../src/data/cc98.posts.json#L902)
1097. 能拍一下最低档亮度吗，晚上看屏幕怕太刺眼。
   来源：[src/data/cc98.posts.json:881](../src/data/cc98.posts.json#L881)
1098. 询问
   来源：[src/data/cc98.posts.json:881](../src/data/cc98.posts.json#L881)
1099. 当面先试灯和接口，转账后再发现少线会很麻烦。
   来源：[src/data/cc98.posts.json:882](../src/data/cc98.posts.json#L882)
1100. 今天 16:30
   来源：[src/data/cc98.posts.json:882](../src/data/cc98.posts.json#L882)
1101. 规范
   来源：[src/data/cc98.posts.json:883](../src/data/cc98.posts.json#L883)
1102. 物品状态、地点和时间写清楚，楼里就不用反复问同一件事。
   来源：[src/data/cc98.posts.json:883](../src/data/cc98.posts.json#L883)
1103. 实验服忘带了
   来源：[src/data/cc98.posts.json:888](../src/data/cc98.posts.json#L888)
1104. 实验课前十分钟才想起实验服还晾在阳台
   来源：[src/data/cc98.posts.json:892](../src/data/cc98.posts.json#L892)
1105. 26-07-10 16:22
   来源：[src/data/cc98.posts.json:895](../src/data/cc98.posts.json#L895)
1106. 一路跑到楼下才发现雨把衣服晾得很有弹性，赶到实验楼时正好听见老师点名。今天的经验是：把实验服放进包里，不要相信早上临出门的自己。
   来源：[src/data/cc98.posts.json:896](../src/data/cc98.posts.json#L896)
1107. 内容为个人经历和防漏清单，没有课程资料需求
   来源：[src/data/cc98.posts.json:897](../src/data/cc98.posts.json#L897)
1108. 收录课前小事
   来源：[src/data/cc98.posts.json:897](../src/data/cc98.posts.json#L897)
1109. 今天 16:24
   来源：[src/data/cc98.posts.json:900](../src/data/cc98.posts.json#L900)；[src/data/cc98.posts.json:921](../src/data/cc98.posts.json#L921)
1110. 我把实验鞋带成了拖鞋，进楼前才发现鞋底不对。
   来源：[src/data/cc98.posts.json:900](../src/data/cc98.posts.json#L900)
1111. 今天 16:26
   来源：[src/data/cc98.posts.json:901](../src/data/cc98.posts.json#L901)
1112. 清单
   来源：[src/data/cc98.posts.json:901](../src/data/cc98.posts.json#L901)
1113. 实验服、护目镜、笔，前一晚放门边最省心。
   来源：[src/data/cc98.posts.json:901](../src/data/cc98.posts.json#L901)
1114. 跑到门口才想起来实验服在包里的人，今天也不少。
   来源：[src/data/cc98.posts.json:902](../src/data/cc98.posts.json#L902)
1115. 取件码忘带
   来源：[src/data/cc98.posts.json:907](../src/data/cc98.posts.json#L907)
1116. 校园卡绑定旧手机后，门禁旁边怎么重新核验
   来源：[src/data/cc98.posts.json:911](../src/data/cc98.posts.json#L911)
1117. 26-07-10 16:18
   来源：[src/data/cc98.posts.json:914](../src/data/cc98.posts.json#L914)
1118. 换手机后旧设备还留着绑定信息，今天在门禁旁的机器上重新核验才恢复正常。先确认新手机能打开校园卡页面，再去现场操作会少跑一趟。
   来源：[src/data/cc98.posts.json:915](../src/data/cc98.posts.json#L915)
1119. 标记设备换绑记录
   来源：[src/data/cc98.posts.json:916](../src/data/cc98.posts.json#L916)
1120. 楼主给出了换机后的现场验证步骤
   来源：[src/data/cc98.posts.json:916](../src/data/cc98.posts.json#L916)
1121. 今天 16:20
   来源：[src/data/cc98.posts.json:919](../src/data/cc98.posts.json#L919)；[src/data/cc98.posts.json:940](../src/data/cc98.posts.json#L940)
1122. 旧手机还在时先退出绑定，之后换新机更容易确认。
   来源：[src/data/cc98.posts.json:919](../src/data/cc98.posts.json#L919)
1123. 今天 16:22
   来源：[src/data/cc98.posts.json:920](../src/data/cc98.posts.json#L920)
1124. 我先去图书馆门口试了一次，失败后再去机器核验就通过了。
   来源：[src/data/cc98.posts.json:920](../src/data/cc98.posts.json#L920)
1125. 换机当天留下新设备的验证结果，进楼前先试一次。
   来源：[src/data/cc98.posts.json:921](../src/data/cc98.posts.json#L921)
1126. 窗边那排空着
   来源：[src/data/cc98.posts.json:926](../src/data/cc98.posts.json#L926)
1127. 晚课结束后有人愿意一起占四人桌写作业吗
   来源：[src/data/cc98.posts.json:930](../src/data/cc98.posts.json#L930)
1128. 26-07-10 16:14
   来源：[src/data/cc98.posts.json:933](../src/data/cc98.posts.json#L933)
1129. 想找两三个人在麦斯威把作业写完，各做各的，不开外放。九点前如果位置满了就散，带电脑的优先坐有插座那侧。
   来源：[src/data/cc98.posts.json:934](../src/data/cc98.posts.json#L934)
1130. 保留临时约伴帖
   来源：[src/data/cc98.posts.json:935](../src/data/cc98.posts.json#L935)
1131. 时间、地点和自习规则已经写明
   来源：[src/data/cc98.posts.json:935](../src/data/cc98.posts.json#L935)
1132. 报名
   来源：[src/data/cc98.posts.json:938](../src/data/cc98.posts.json#L938)
1133. 今天 16:16
   来源：[src/data/cc98.posts.json:938](../src/data/cc98.posts.json#L938)；[src/data/cc98.posts.json:959](../src/data/cc98.posts.json#L959)
1134. 我带耳机和插线板，七点四十左右到。
   来源：[src/data/cc98.posts.json:938](../src/data/cc98.posts.json#L938)
1135. 今天 16:18
   来源：[src/data/cc98.posts.json:939](../src/data/cc98.posts.json#L939)
1136. 能保证不讨论题目吗，我有一份报告要赶。
   来源：[src/data/cc98.posts.json:939](../src/data/cc98.posts.json#L939)
1137. 第一次见面选公共区域，离开前把桌面收好。
   来源：[src/data/cc98.posts.json:940](../src/data/cc98.posts.json#L940)
1138. 西门等外卖
   来源：[src/data/cc98.posts.json:945](../src/data/cc98.posts.json#L945)
1139. 我给外卖备注“蓝色外套”，结果门口站了七个蓝色外套
   来源：[src/data/cc98.posts.json:949](../src/data/cc98.posts.json#L949)
1140. 26-07-10 16:10
   来源：[src/data/cc98.posts.json:952](../src/data/cc98.posts.json#L952)
1141. 骑手问谁是蓝色外套，我举手后旁边也举起六只手。最后靠备注里的饮料口味找到了自己的那一袋。
   来源：[src/data/cc98.posts.json:953](../src/data/cc98.posts.json#L953)
1142. 加入校园小场面
   来源：[src/data/cc98.posts.json:954](../src/data/cc98.posts.json#L954)
1143. 主题来自公共取餐区的日常误会
   来源：[src/data/cc98.posts.json:954](../src/data/cc98.posts.json#L954)
1144. 今天 16:12
   来源：[src/data/cc98.posts.json:957](../src/data/cc98.posts.json#L957)；[src/data/cc98.posts.json:978](../src/data/cc98.posts.json#L978)
1145. 下次备注鞋子颜色，蓝色外套在雨天没有辨识度。
   来源：[src/data/cc98.posts.json:957](../src/data/cc98.posts.json#L957)
1146. 今天 16:14
   来源：[src/data/cc98.posts.json:958](../src/data/cc98.posts.json#L958)
1147. 我写过“背电脑包”，门口每个人都背着。
   来源：[src/data/cc98.posts.json:958](../src/data/cc98.posts.json#L958)
1148. 饮料口味和取餐码比穿什么可靠。
   来源：[src/data/cc98.posts.json:959](../src/data/cc98.posts.json#L959)
1149. 卡套夹住了
   来源：[src/data/cc98.posts.json:964](../src/data/cc98.posts.json#L964)
1150. 教学楼一楼窗台上有一张校园卡，卡套是深绿色的
   来源：[src/data/cc98.posts.json:968](../src/data/cc98.posts.json#L968)
1151. 26-07-10 16:06
   来源：[src/data/cc98.posts.json:971](../src/data/cc98.posts.json#L971)
1152. 卡放在一楼饮水机旁的窗台上，深绿色卡套边缘有磨损。我没有移动，失主到场后先核对姓名和卡面照片再拿。
   来源：[src/data/cc98.posts.json:972](../src/data/cc98.posts.json#L972)
1153. 保留现场位置
   来源：[src/data/cc98.posts.json:973](../src/data/cc98.posts.json#L973)
1154. 物品特征、所在位置和核对方式完整
   来源：[src/data/cc98.posts.json:973](../src/data/cc98.posts.json#L973)
1155. 别把卡号完整发出来，能让失主自己说明卡套细节更稳妥。
   来源：[src/data/cc98.posts.json:976](../src/data/cc98.posts.json#L976)
1156. 今天 16:08
   来源：[src/data/cc98.posts.json:976](../src/data/cc98.posts.json#L976)；[src/data/cc98.posts.json:997](../src/data/cc98.posts.json#L997)
1157. 今天 16:10
   来源：[src/data/cc98.posts.json:977](../src/data/cc98.posts.json#L977)
1158. 饮水机旁人来人往，没找到失主就交到门卫处。
   来源：[src/data/cc98.posts.json:977](../src/data/cc98.posts.json#L977)
1159. 现场物品只写辨识特征，不公开完整个人信息。
   来源：[src/data/cc98.posts.json:978](../src/data/cc98.posts.json#L978)
1160. 三号窗口观察员
   来源：[src/data/cc98.posts.json:983](../src/data/cc98.posts.json#L983)
1161. 东二三号窗口今天的队伍为什么总会停一下
   来源：[src/data/cc98.posts.json:987](../src/data/cc98.posts.json#L987)
1162. 26-07-10 16:02
   来源：[src/data/cc98.posts.json:990](../src/data/cc98.posts.json#L990)
1163. 排队时看见前面的人都会在付款页找半天，原来是当天的套餐入口换了位置。点餐前先看屏幕底部一行，队伍会走得快一点。
   来源：[src/data/cc98.posts.json:991](../src/data/cc98.posts.json#L991)
1164. 补充点餐界面变化
   来源：[src/data/cc98.posts.json:992](../src/data/cc98.posts.json#L992)
1165. 帖子说明了排队变慢的具体原因
   来源：[src/data/cc98.posts.json:992](../src/data/cc98.posts.json#L992)
1166. 今天 16:04
   来源：[src/data/cc98.posts.json:995](../src/data/cc98.posts.json#L995)
1167. 我刚去过，先选套餐再选饭，顺序和昨天不一样。
   来源：[src/data/cc98.posts.json:995](../src/data/cc98.posts.json#L995)
1168. 今天 16:06
   来源：[src/data/cc98.posts.json:996](../src/data/cc98.posts.json#L996)
1169. 屏幕前别临时问朋友吃什么，后面的人会一起停住。
   来源：[src/data/cc98.posts.json:996](../src/data/cc98.posts.json#L996)
1170. 入口变化时把步骤写清楚，下一位就少等一会儿。
   来源：[src/data/cc98.posts.json:997](../src/data/cc98.posts.json#L997)
1171. 时间戳和打印队都要记清。
   来源：[src/data/cc98.thread-personas.json:2](../src/data/cc98.thread-personas.json#L2)
1172. 晚八点打印机
   来源：[src/data/cc98.thread-personas.json:2](../src/data/cc98.thread-personas.json#L2)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:41](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L41)
1173. 路过带图，顺手报告风向和人流。
   来源：[src/data/cc98.thread-personas.json:3](../src/data/cc98.thread-personas.json#L3)
1174. 玉泉风很大
   来源：[src/data/cc98.thread-personas.json:3](../src/data/cc98.thread-personas.json#L3)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:51](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L51)
1175. 盯着座位、插座和没人取走的东西。
   来源：[src/data/cc98.thread-personas.json:4](../src/data/cc98.thread-personas.json#L4)
1176. 二南插座观察员
   来源：[src/data/cc98.thread-personas.json:4](../src/data/cc98.thread-personas.json#L4)
1177. 每天经过求是潮，偶尔能走出去。
   来源：[src/data/cc98.thread-personas.json:5](../src/data/cc98.thread-personas.json#L5)
1178. 求是潮逆行者
   来源：[src/data/cc98.thread-personas.json:5](../src/data/cc98.thread-personas.json#L5)
1179. 六分钱富豪
   来源：[src/data/cc98.thread-personas.json:6](../src/data/cc98.thread-personas.json#L6)
1180. 余额 0.06 元，账目记录完整。
   来源：[src/data/cc98.thread-personas.json:6](../src/data/cc98.thread-personas.json#L6)
1181. 没有审核权限，只保留证据和结论。
   来源：[src/data/cc98.thread-personas.json:7](../src/data/cc98.thread-personas.json#L7)
1182. 紫金港野生审核员
   来源：[src/data/cc98.thread-personas.json:7](../src/data/cc98.thread-personas.json#L7)
1183. narrator
   来源：[src/data/dialogue.lines.json:5](../src/data/dialogue.lines.json#L5)；[src/data/storyLines.ts:46](../src/data/storyLines.ts#L46)
1184. 你没有5分钟了，但你很有勇气
   来源：[src/data/dialogue.lines.json:6](../src/data/dialogue.lines.json#L6)
1185. xiaoying
   来源：[src/data/dialogue.lines.json:16](../src/data/dialogue.lines.json#L16)；[src/data/dialogue.lines.json:27](../src/data/dialogue.lines.json#L27)；[src/data/dialogue.lines.json:38](../src/data/dialogue.lines.json#L38)；[src/data/dialogue.lines.json:71](../src/data/dialogue.lines.json#L71)；[src/data/dialogue.lines.json:93](../src/data/dialogue.lines.json#L93)；[src/scenes/phone/P14_Wechat/index.tsx:403](../src/scenes/phone/P14_Wechat/index.tsx#L403)
1186. 起床蠢货！！！
   来源：[src/data/dialogue.lines.json:17](../src/data/dialogue.lines.json#L17)
1187. 等等等等，你想翘课？没门！我不会让你签上的！
   来源：[src/data/dialogue.lines.json:28](../src/data/dialogue.lines.json#L28)
1188. 找你的数字去吧哈哈哈
   来源：[src/data/dialogue.lines.json:39](../src/data/dialogue.lines.json#L39)；[src/scenes/phone/P14_Wechat/index.tsx:990](../src/scenes/phone/P14_Wechat/index.tsx#L990)
1189. system
   来源：[src/data/dialogue.lines.json:49](../src/data/dialogue.lines.json#L49)；[src/data/dialogue.lines.json:60](../src/data/dialogue.lines.json#L60)；[src/data/dialogue.lines.json:82](../src/data/dialogue.lines.json#L82)；[src/data/storyLines.ts:46](../src/data/storyLines.ts#L46)；[src/data/storyLines.ts:54](../src/data/storyLines.ts#L54)；[src/scenes/phone/P02_CC98/index.tsx:646](../src/scenes/phone/P02_CC98/index.tsx#L646)；[src/scenes/phone/P02_CC98/index.tsx:797](../src/scenes/phone/P02_CC98/index.tsx#L797)；[src/scenes/phone/P07_Weather/index.tsx:29](../src/scenes/phone/P07_Weather/index.tsx#L29)；[src/scenes/phone/P07_Weather/index.tsx:44](../src/scenes/phone/P07_Weather/index.tsx#L44)；[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)；[src/scenes/phone/P07_Weather/index.tsx:51](../src/scenes/phone/P07_Weather/index.tsx#L51)；[src/scenes/phone/P07_Weather/index.tsx:90](../src/scenes/phone/P07_Weather/index.tsx#L90)；[src/scenes/phone/P07_Weather/index.tsx:93](../src/scenes/phone/P07_Weather/index.tsx#L93)；[src/scenes/phone/P13_PhoneHome/index.tsx:220](../src/scenes/phone/P13_PhoneHome/index.tsx#L220)；[src/scenes/phone/P13_PhoneHome/index.tsx:343](../src/scenes/phone/P13_PhoneHome/index.tsx#L343)；[src/scenes/phone/P13_PhoneHome/index.tsx:347](../src/scenes/phone/P13_PhoneHome/index.tsx#L347)；[src/scenes/phone/P14_Wechat/index.tsx:349](../src/scenes/phone/P14_Wechat/index.tsx#L349)；[src/scenes/phone/P14_Wechat/index.tsx:355](../src/scenes/phone/P14_Wechat/index.tsx#L355)；[src/scenes/phone/P14_Wechat/index.tsx:419](../src/scenes/phone/P14_Wechat/index.tsx#L419)；[src/scenes/phone/P14_Wechat/index.tsx:423](../src/scenes/phone/P14_Wechat/index.tsx#L423)；[src/scenes/phone/P14_Wechat/index.tsx:506](../src/scenes/phone/P14_Wechat/index.tsx#L506)；[src/scenes/phone/P15_Zjuding/index.tsx:71](../src/scenes/phone/P15_Zjuding/index.tsx#L71)；[src/scenes/phone/P15_Zjuding/index.tsx:73](../src/scenes/phone/P15_Zjuding/index.tsx#L73)；[src/scenes/phone/P15_Zjuding/index.tsx:74](../src/scenes/phone/P15_Zjuding/index.tsx#L74)；[src/scenes/phone/P15_Zjuding/index.tsx:75](../src/scenes/phone/P15_Zjuding/index.tsx#L75)；[src/scenes/phone/P15_Zjuding/index.tsx:78](../src/scenes/phone/P15_Zjuding/index.tsx#L78)；[src/scenes/phone/P15_Zjuding/index.tsx:80](../src/scenes/phone/P15_Zjuding/index.tsx#L80)；[src/scenes/phone/P15_Zjuding/index.tsx:81](../src/scenes/phone/P15_Zjuding/index.tsx#L81)；[src/scenes/phone/P15_Zjuding/index.tsx:84](../src/scenes/phone/P15_Zjuding/index.tsx#L84)；[src/scenes/phone/P15_Zjuding/index.tsx:86](../src/scenes/phone/P15_Zjuding/index.tsx#L86)；[src/scenes/phone/P15_Zjuding/index.tsx:87](../src/scenes/phone/P15_Zjuding/index.tsx#L87)；[src/scenes/phone/P15_Zjuding/index.tsx:88](../src/scenes/phone/P15_Zjuding/index.tsx#L88)；[src/scenes/phone/P15_Zjuding/index.tsx:89](../src/scenes/phone/P15_Zjuding/index.tsx#L89)；[src/scenes/phone/P15_Zjuding/index.tsx:92](../src/scenes/phone/P15_Zjuding/index.tsx#L92)；[src/scenes/phone/P15_Zjuding/index.tsx:93](../src/scenes/phone/P15_Zjuding/index.tsx#L93)；[src/scenes/phone/P15_Zjuding/index.tsx:94](../src/scenes/phone/P15_Zjuding/index.tsx#L94)；[src/scenes/phone/P15_Zjuding/index.tsx:95](../src/scenes/phone/P15_Zjuding/index.tsx#L95)；[src/scenes/phone/P15_Zjuding/index.tsx:621](../src/scenes/phone/P15_Zjuding/index.tsx#L621)；[src/scenes/phone/P15_Zjuding/index.tsx:636](../src/scenes/phone/P15_Zjuding/index.tsx#L636)；[src/scenes/phone/P15_Zjuding/index.tsx:666](../src/scenes/phone/P15_Zjuding/index.tsx#L666)；[src/scenes/phone/P15_Zjuding/index.tsx:759](../src/scenes/phone/P15_Zjuding/index.tsx#L759)；[src/scenes/phone/P15_Zjuding/index.tsx:923](../src/scenes/phone/P15_Zjuding/index.tsx#L923)；[src/scenes/phone/P15_Zjuding/index.tsx:1049](../src/scenes/phone/P15_Zjuding/index.tsx#L1049)；[src/scenes/rpg/BootScene.ts:206](../src/scenes/rpg/BootScene.ts#L206)；[src/scenes/rpg/BootScene.ts:208](../src/scenes/rpg/BootScene.ts#L208)；[src/scenes/rpg/BootScene.ts:619](../src/scenes/rpg/BootScene.ts#L619)
1190. 余额暂时不足以购买尊严
   来源：[src/data/dialogue.lines.json:50](../src/data/dialogue.lines.json#L50)
1191. 校园网已经尽力了，你也是
   来源：[src/data/dialogue.lines.json:61](../src/data/dialogue.lines.json#L61)
1192. 我知道你没钱买流量
   来源：[src/data/dialogue.lines.json:72](../src/data/dialogue.lines.json#L72)
1193. 就差一次，真绝望
   来源：[src/data/dialogue.lines.json:83](../src/data/dialogue.lines.json#L83)
1194. 哈，一个废齿轮
   来源：[src/data/dialogue.lines.json:94](../src/data/dialogue.lines.json#L94)
1195. 022 临时离座留言
   来源：[src/data/itemCatalog.ts:30](../src/data/itemCatalog.ts#L30)
1196. 022 · 二楼南区
   来源：[src/data/itemCatalog.ts:32](../src/data/itemCatalog.ts#L32)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:138](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L138)
1197. 离开时长
   来源：[src/data/itemCatalog.ts:33](../src/data/itemCatalog.ts#L33)
1198. 三分钟
   来源：[src/data/itemCatalog.ts:33](../src/data/itemCatalog.ts#L33)
1199. 留言状态
   来源：[src/data/itemCatalog.ts:34](../src/data/itemCatalog.ts#L34)
1200. 仍在占用
   来源：[src/data/itemCatalog.ts:34](../src/data/itemCatalog.ts#L34)
1201. 本人离开三分钟，回来前请勿使用。
   来源：[src/data/itemCatalog.ts:36](../src/data/itemCatalog.ts#L36)
1202. 开始计时的时刻未填写。临时离座规则详见 CC98。
   来源：[src/data/itemCatalog.ts:36](../src/data/itemCatalog.ts#L36)
1203. 纸张边缘留有反复折叠痕迹。
   来源：[src/data/itemCatalog.ts:37](../src/data/itemCatalog.ts#L37)
1204. 馆藏定位单
   来源：[src/data/itemCatalog.ts:40](../src/data/itemCatalog.ts#L40)
1205. 《三分钟离座法及其例外》
   来源：[src/data/itemCatalog.ts:42](../src/data/itemCatalog.ts#L42)
1206. 书名
   来源：[src/data/itemCatalog.ts:42](../src/data/itemCatalog.ts#L42)；[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
1207. 索书号
   来源：[src/data/itemCatalog.ts:43](../src/data/itemCatalog.ts#L43)
1208. 馆藏位置
   来源：[src/data/itemCatalog.ts:44](../src/data/itemCatalog.ts#L44)
1209. 基础馆文学书架 · 755 段
   来源：[src/data/itemCatalog.ts:44](../src/data/itemCatalog.ts#L44)
1210. 旧版离座规定存放于上述书架。
   来源：[src/data/itemCatalog.ts:46](../src/data/itemCatalog.ts#L46)
1211. 只供馆内查阅；查完能否离座，请查规定。
   来源：[src/data/itemCatalog.ts:46](../src/data/itemCatalog.ts#L46)
1212. 状态：仅馆内查阅。
   来源：[src/data/itemCatalog.ts:47](../src/data/itemCatalog.ts#L47)
1213. 旧版临时离座恢复规定
   来源：[src/data/itemCatalog.ts:50](../src/data/itemCatalog.ts#L50)
1214. 版本
   来源：[src/data/itemCatalog.ts:52](../src/data/itemCatalog.ts#L52)
1215. 期末周修订版 · 已归档
   来源：[src/data/itemCatalog.ts:52](../src/data/itemCatalog.ts#L52)
1216. 适用范围
   来源：[src/data/itemCatalog.ts:53](../src/data/itemCatalog.ts#L53)
1217. 座位被非本人随身物持续占用
   来源：[src/data/itemCatalog.ts:53](../src/data/itemCatalog.ts#L53)
1218. 目标座位
   来源：[src/data/itemCatalog.ts:54](../src/data/itemCatalog.ts#L54)
1219. 恢复申请须同时具备三类证明：
   来源：[src/data/itemCatalog.ts:57](../src/data/itemCatalog.ts#L57)
1220. 一、本人确实到馆；
   来源：[src/data/itemCatalog.ts:58](../src/data/itemCatalog.ts#L58)
1221. 二、目标座位与凭据一致；
   来源：[src/data/itemCatalog.ts:59](../src/data/itemCatalog.ts#L59)
1222. 三、当前占用物不具备本人身份。
   来源：[src/data/itemCatalog.ts:60](../src/data/itemCatalog.ts#L60)
1223. 规则依据须先完成公开公示。
   来源：[src/data/itemCatalog.ts:62](../src/data/itemCatalog.ts#L62)
1224. 物品识别报告
   来源：[src/data/itemCatalog.ts:65](../src/data/itemCatalog.ts#L65)；[src/data/items.config.json:116](../src/data/items.config.json#L116)
1225. 对象类型
   来源：[src/data/itemCatalog.ts:67](../src/data/itemCatalog.ts#L67)
1226. 双肩书包
   来源：[src/data/itemCatalog.ts:67](../src/data/itemCatalog.ts#L67)
1227. 未识别
   来源：[src/data/itemCatalog.ts:68](../src/data/itemCatalog.ts#L68)；[src/data/itemCatalog.ts:69](../src/data/itemCatalog.ts#L69)
1228. 姓名
   来源：[src/data/itemCatalog.ts:68](../src/data/itemCatalog.ts#L68)；[src/scenes/phone/P15_Zjuding/index.tsx:1268](../src/scenes/phone/P15_Zjuding/index.tsx#L1268)；[src/scenes/phone/P15_Zjuding/index.tsx:1334](../src/scenes/phone/P15_Zjuding/index.tsx#L1334)
1229. 学号
   来源：[src/data/itemCatalog.ts:69](../src/data/itemCatalog.ts#L69)；[src/scenes/phone/P15_Zjuding/index.tsx:1272](../src/scenes/phone/P15_Zjuding/index.tsx#L1272)；[src/scenes/phone/P15_Zjuding/index.tsx:1346](../src/scenes/phone/P15_Zjuding/index.tsx#L1346)
1230. 识别结果
   来源：[src/data/itemCatalog.ts:70](../src/data/itemCatalog.ts#L70)
1231. 未检测到可签到主体
   来源：[src/data/itemCatalog.ts:70](../src/data/itemCatalog.ts#L70)
1232. 识别到双肩带、拉链与课本，未识别到姓名或学号。
   来源：[src/data/itemCatalog.ts:72](../src/data/itemCatalog.ts#L72)
1233. 书包身份待馆内前台核验。图像识别不代替盖章。
   来源：[src/data/itemCatalog.ts:72](../src/data/itemCatalog.ts#L72)
1234. 报告状态：待盖章。
   来源：[src/data/itemCatalog.ts:73](../src/data/itemCatalog.ts#L73)
1235. 书包非本人证明
   来源：[src/data/itemCatalog.ts:76](../src/data/itemCatalog.ts#L76)；[src/data/items.config.json:123](../src/data/items.config.json#L123)；[src/data/presentation-cues.ts:142](../src/data/presentation-cues.ts#L142)；[src/scenes/phone/P15_Zjuding/index.tsx:195](../src/scenes/phone/P15_Zjuding/index.tsx#L195)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:105](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L105)
1236. 022 座位占用书包
   来源：[src/data/itemCatalog.ts:78](../src/data/itemCatalog.ts#L78)
1237. 对象
   来源：[src/data/itemCatalog.ts:78](../src/data/itemCatalog.ts#L78)
1238. 非本人
   来源：[src/data/itemCatalog.ts:79](../src/data/itemCatalog.ts#L79)
1239. 认证结论
   来源：[src/data/itemCatalog.ts:79](../src/data/itemCatalog.ts#L79)
1240. 无 / 无
   来源：[src/data/itemCatalog.ts:80](../src/data/itemCatalog.ts#L80)
1241. 姓名 / 学号
   来源：[src/data/itemCatalog.ts:80](../src/data/itemCatalog.ts#L80)
1242. 盖章来源
   来源：[src/data/itemCatalog.ts:81](../src/data/itemCatalog.ts#L81)
1243. 基础馆物品身份盖章机
   来源：[src/data/itemCatalog.ts:81](../src/data/itemCatalog.ts#L81)
1244. 本证明仅证明书包。持有人仍需另交到馆材料。
   来源：[src/data/itemCatalog.ts:83](../src/data/itemCatalog.ts#L83)
1245. 经核验，该书包无姓名、无学号，不具备独立占用座位的身份条件。
   来源：[src/data/itemCatalog.ts:83](../src/data/itemCatalog.ts#L83)
1246. 电子章：基础馆失物身份登记。
   来源：[src/data/itemCatalog.ts:84](../src/data/itemCatalog.ts#L84)
1247. 022 座位凭据
   来源：[src/data/itemCatalog.ts:90](../src/data/itemCatalog.ts#L90)
1248. 座位编号
   来源：[src/data/itemCatalog.ts:92](../src/data/itemCatalog.ts#L92)
1249. 二楼南区
   来源：[src/data/itemCatalog.ts:93](../src/data/itemCatalog.ts#L93)
1250. 区域
   来源：[src/data/itemCatalog.ts:93](../src/data/itemCatalog.ts#L93)；[src/scenes/phone/P15_Zjuding/index.tsx:416](../src/scenes/phone/P15_Zjuding/index.tsx#L416)
1251. 离座中 · 待公示
   来源：[src/data/itemCatalog.ts:95](../src/data/itemCatalog.ts#L95)
1252. 凭据状态
   来源：[src/data/itemCatalog.ts:95](../src/data/itemCatalog.ts#L95)
1253. 当前占用物：书包。
   来源：[src/data/itemCatalog.ts:97](../src/data/itemCatalog.ts#L97)
1254. 恢复处理需提交论坛公示。
   来源：[src/data/itemCatalog.ts:97](../src/data/itemCatalog.ts#L97)
1255. 凭据来源：022 桌面夹缝。
   来源：[src/data/itemCatalog.ts:98](../src/data/itemCatalog.ts#L98)
1256. 本人来过证明
   来源：[src/data/itemCatalog.ts:104](../src/data/itemCatalog.ts#L104)；[src/data/items.config.json:137](../src/data/items.config.json#L137)；[src/data/presentation-cues.ts:160](../src/data/presentation-cues.ts#L160)；[src/scenes/phone/P15_Zjuding/index.tsx:207](../src/scenes/phone/P15_Zjuding/index.tsx#L207)
1257. 7 分钟
   来源：[src/data/itemCatalog.ts:106](../src/data/itemCatalog.ts#L106)
1258. 到馆时长
   来源：[src/data/itemCatalog.ts:106](../src/data/itemCatalog.ts#L106)
1259. 公示编号
   来源：[src/data/itemCatalog.ts:107](../src/data/itemCatalog.ts#L107)
1260. 证明数量
   来源：[src/data/itemCatalog.ts:108](../src/data/itemCatalog.ts#L108)
1261. 补录成功
   来源：[src/data/itemCatalog.ts:109](../src/data/itemCatalog.ts#L109)
1262. 记录状态
   来源：[src/data/itemCatalog.ts:109](../src/data/itemCatalog.ts#L109)
1263. 到馆已确认，座位使用仍需单独申请。
   来源：[src/data/itemCatalog.ts:111](../src/data/itemCatalog.ts#L111)
1264. 访问轨迹与 022 座位凭据的时间记录一致。
   来源：[src/data/itemCatalog.ts:111](../src/data/itemCatalog.ts#L111)
1265. 签发来源：浙大体艺访问记录补录。
   来源：[src/data/itemCatalog.ts:112](../src/data/itemCatalog.ts#L112)
1266. 离座清退 PASS
   来源：[src/data/itemCatalog.ts:118](../src/data/itemCatalog.ts#L118)；[src/data/items.config.json:144](../src/data/items.config.json#L144)
1267. 适用座位
   来源：[src/data/itemCatalog.ts:120](../src/data/itemCatalog.ts#L120)
1268. 处理目标
   来源：[src/data/itemCatalog.ts:121](../src/data/itemCatalog.ts#L121)
1269. 非本人占用书包
   来源：[src/data/itemCatalog.ts:121](../src/data/itemCatalog.ts#L121)
1270. 单次有效
   来源：[src/data/itemCatalog.ts:122](../src/data/itemCatalog.ts#L122)
1271. 有效状态
   来源：[src/data/itemCatalog.ts:122](../src/data/itemCatalog.ts#L122)
1272. 已完成公开公示与三项恢复材料核验。
   来源：[src/data/itemCatalog.ts:124](../src/data/itemCatalog.ts#L124)
1273. 仅对登记为非本人的占用物有效。
   来源：[src/data/itemCatalog.ts:125](../src/data/itemCatalog.ts#L125)
1274. 取餐号
   来源：[src/data/itemCatalog.ts:140](../src/data/itemCatalog.ts#L140)
1275. 请取餐
   来源：[src/data/itemCatalog.ts:141](../src/data/itemCatalog.ts#L141)
1276. 状态
   来源：[src/data/itemCatalog.ts:141](../src/data/itemCatalog.ts#L141)；[src/data/itemCatalog.ts:165](../src/data/itemCatalog.ts#L165)
1277. 请凭号码取餐，实际餐品请听窗口叫号。
   来源：[src/data/itemCatalog.ts:143](../src/data/itemCatalog.ts#L143)
1278. 已完成点餐不等于已完成取餐。
   来源：[src/data/itemCatalog.ts:143](../src/data/itemCatalog.ts#L143)
1279. 小票遗失，请回原队伍处理。
   来源：[src/data/itemCatalog.ts:144](../src/data/itemCatalog.ts#L144)
1280. 边角湿润
   来源：[src/data/itemCatalog.ts:165](../src/data/itemCatalog.ts#L165)
1281. 纸条飞走以后，地上的水迹断了。
   来源：[src/data/itemCatalog.ts:169](../src/data/itemCatalog.ts#L169)
1282. 潮湿痕迹只能说明它经过了有水的地方。
   来源：[src/data/itemCatalog.ts:170](../src/data/itemCatalog.ts#L170)
1283. 还得找目击记录和别的地点信息。
   来源：[src/data/itemCatalog.ts:171](../src/data/itemCatalog.ts#L171)
1284. 纸角滴水，文字还能辨认。
   来源：[src/data/itemCatalog.ts:173](../src/data/itemCatalog.ts#L173)
1285. 倒影坐标
   来源：[src/data/itemCatalog.ts:183](../src/data/itemCatalog.ts#L183)；[src/data/items.config.json:326](../src/data/items.config.json#L326)
1286. 暗色细节
   来源：[src/data/itemCatalog.ts:185](../src/data/itemCatalog.ts#L185)
1287. 湖面左侧 / 桥影下方 / 亮点偏右
   来源：[src/data/itemCatalog.ts:185](../src/data/itemCatalog.ts#L185)
1288. 浅色细节
   来源：[src/data/itemCatalog.ts:186](../src/data/itemCatalog.ts#L186)
1289. 右侧路灯杆
   来源：[src/data/itemCatalog.ts:186](../src/data/itemCatalog.ts#L186)
1290. 两种模式记录的是同一个位置。
   来源：[src/data/itemCatalog.ts:188](../src/data/itemCatalog.ts#L188)
1291. 来源：启真湖倒影指示牌。
   来源：[src/data/itemCatalog.ts:189](../src/data/itemCatalog.ts#L189)
1292. 水滴
   来源：[src/data/items.config.json:4](../src/data/items.config.json#L4)
1293. 早八下雨时接到的水，免费。拿来浇盆栽，总算能给这场雨找点用处。
   来源：[src/data/items.config.json:5](../src/data/items.config.json#L5)
1294. 从控制中心取下的耳机，背面有个凹槽。没附保修条款，也没说不能装水。
   来源：[src/data/items.config.json:12](../src/data/items.config.json#L12)
1295. 盛水的耳机
   来源：[src/data/items.config.json:18](../src/data/items.config.json#L18)；[src/modules/InventoryController.ts:14](../src/modules/InventoryController.ts#L14)
1296. 凹槽里盛了一点水，够浇盆栽。建议倒完再戴，听雨目前不需要这么彻底。
   来源：[src/data/items.config.json:19](../src/data/items.config.json#L19)
1297. 反转齿轮
   来源：[src/data/items.config.json:25](../src/data/items.config.json#L25)
1298. 设置里的齿轮，背面刻着 9。正面管设置，背面藏数字，使用说明两面都没写。
   来源：[src/data/items.config.json:26](../src/data/items.config.json#L26)
1299. 斜线
   来源：[src/data/items.config.json:32](../src/data/items.config.json#L32)
1300. 从朋友头像上取下的一撇。对方没收钱，也没要求你先转发。
   来源：[src/data/items.config.json:33](../src/data/items.config.json#L33)
1301. 钥匙
   来源：[src/data/items.config.json:39](../src/data/items.config.json#L39)；[src/modules/InventoryController.ts:13](../src/modules/InventoryController.ts#L13)
1302. 斜线和齿轮拼出的钥匙，轮廓能对上钟楼锁孔。配钥匙的地方在手机里，配钥匙的人是你。
   来源：[src/data/items.config.json:40](../src/data/items.config.json#L40)
1303. 一袋肥料
   来源：[src/data/items.config.json:46](../src/data/items.config.json#L46)
1304. 从钟楼里找到的一袋肥料，可以给盆栽施肥。清点钟楼物资时，大概没人想到要查这一项。
   来源：[src/data/items.config.json:47](../src/data/items.config.json#L47)
1305. 电子校园卡
   来源：[src/data/items.config.json:53](../src/data/items.config.json#L53)；[src/scenes/phone/P15_Zjuding/index.tsx:2002](../src/scenes/phone/P15_Zjuding/index.tsx#L2002)；[src/scenes/phone/P15_Zjuding/index.tsx:2004](../src/scenes/phone/P15_Zjuding/index.tsx#L2004)；[src/scenes/phone/P15_Zjuding/index.tsx:2005](../src/scenes/phone/P15_Zjuding/index.tsx#L2005)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
1306. 校园卡。姓名证明你在这里注册过，余额说明你在这里吃过饭。两项都很准确。
   来源：[src/data/items.config.json:54](../src/data/items.config.json#L54)
1307. 三角形
   来源：[src/data/items.config.json:60](../src/data/items.config.json#L60)
1308. 推送头像上松动的三角形，边缘平整，还能拼接。推送终于有了可以取用的内容。
   来源：[src/data/items.config.json:61](../src/data/items.config.json#L61)
1309. 天气水滴
   来源：[src/data/items.config.json:67](../src/data/items.config.json#L67)
1310. 天气页面上的水滴，沾在手上是真的湿。预报准不准另说，取水不需要预约。
   来源：[src/data/items.config.json:68](../src/data/items.config.json#L68)
1311. 竖线
   来源：[src/data/items.config.json:74](../src/data/items.config.json#L74)
1312. 从导师头像上取下的一条竖线，笔直，能与别的图形拼合。这次没有附带修改意见。
   来源：[src/data/items.config.json:75](../src/data/items.config.json#L75)
1313. 右移箭头
   来源：[src/data/items.config.json:81](../src/data/items.config.json#L81)；[src/modules/InventoryController.ts:15](../src/modules/InventoryController.ts#L15)
1314. 三角形与竖线拼成的右向箭头，可以推动数字或拨动缝隙里的东西。向左暂不支持。
   来源：[src/data/items.config.json:82](../src/data/items.config.json#L82)
1315. 游戏手柄
   来源：[src/data/items.config.json:88](../src/data/items.config.json#L88)
1316. CC98 二手市场六块钱成交。接到寝室里的角色身上就能走动，移动权限另购这件事没人提前说。
   来源：[src/data/items.config.json:89](../src/data/items.config.json#L89)
1317. 占座纸条
   来源：[src/data/items.config.json:95](../src/data/items.config.json#L95)
1318. 022 座位旁的纸条，写着“本人离开三分钟”，没写从几点开始算。可在 CC98 搜索同类记录。
   来源：[src/data/items.config.json:96](../src/data/items.config.json#L96)
1319. 索书号 755
   来源：[src/data/items.config.json:102](../src/data/items.config.json#L102)
1320. 索书号 755，指向存放旧版离座规则的书架。想知道今天怎么离座，得先查旧规定。
   来源：[src/data/items.config.json:103](../src/data/items.config.json#L103)
1321. 旧离座规定
   来源：[src/data/items.config.json:109](../src/data/items.config.json#L109)
1322. 在书架背面找到的旧规定，可上传到 CC98 作证。新规要求补材料，旧规恰好算材料。
   来源：[src/data/items.config.json:110](../src/data/items.config.json#L110)
1323. 调暗照片后得到的识别报告，确认画面里是书包。结论还需前台盖章，肉眼看见暂不算数。
   来源：[src/data/items.config.json:117](../src/data/items.config.json#L117)
1324. 前台已经盖章，正式确认书包不是学生。可以上传到 CC98，结束这一项身份争议。
   来源：[src/data/items.config.json:124](../src/data/items.config.json#L124)
1325. 022 座位小票
   来源：[src/data/items.config.json:130](../src/data/items.config.json#L130)；[src/data/presentation-cues.ts:151](../src/data/presentation-cues.ts#L151)；[src/scenes/phone/P15_Zjuding/index.tsx:201](../src/scenes/phone/P15_Zjuding/index.tsx#L201)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:106](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L106)
1326. 022 桌下夹缝里的小票，保留着占座记录。可上传到 CC98；座位还没坐到，材料先收齐了。
   来源：[src/data/items.config.json:131](../src/data/items.config.json#L131)
1327. 体艺补录出具的到馆证明，可上传到 CC98。本人来过，现在终于有附件了。
   来源：[src/data/items.config.json:138](../src/data/items.config.json#L138)
1328. 三项材料核准后得到的凭证，可对 022 座位上的书包使用。书包无需到场签字，它已经在场太久。
   来源：[src/data/items.config.json:145](../src/data/items.config.json#L145)
1329. 收回三只脏餐盘挣的 2.00 元，正好够骑一次车。工作按件算，路费一笔花完。
   来源：[src/data/items.config.json:152](../src/data/items.config.json#L152)
1330. 阿姨给的纸巾，一角有油，另一角还干净。擦车锁、擦海报玻璃都够用，暂时没有新的可领。
   来源：[src/data/items.config.json:159](../src/data/items.config.json#L159)
1331. 气泡水
   来源：[src/data/items.config.json:165](../src/data/items.config.json#L165)
1332. 蓝色的气泡水，调配台原料之一。照货架顺序倒；新品的颜色管理比口味管理严格。
   来源：[src/data/items.config.json:166](../src/data/items.config.json#L166)
1333. 柠檬茶
   来源：[src/data/items.config.json:172](../src/data/items.config.json#L172)
1334. 白色的柠檬茶，调配台原料之一。菜单上就这么印着，顺序得去看货架。
   来源：[src/data/items.config.json:173](../src/data/items.config.json#L173)
1335. 黑咖啡
   来源：[src/data/items.config.json:179](../src/data/items.config.json#L179)
1336. 黑咖啡，调配台原料之一。颜色符合名称，已经比旁边那杯好认；倒入顺序仍按货架。
   来源：[src/data/items.config.json:180](../src/data/items.config.json#L180)
1337. 难喝饮料
   来源：[src/data/items.config.json:186](../src/data/items.config.json#L186)
1338. 三种饮料倒错顺序的结果。可以自己喝，宣传位不收；难喝的原因倒是不用填表。
   来源：[src/data/items.config.json:187](../src/data/items.config.json#L187)
1339. 今日新品气泡水
   来源：[src/data/items.config.json:193](../src/data/items.config.json#L193)
1340. 按货架顺序调好的新品，第三窗口宣传板留了空杯位。洒在地上会起两秒黏泡，记得看脚下。
   来源：[src/data/items.config.json:194](../src/data/items.config.json#L194)
1341. 取餐号 0755。纸上只管叫号，没保证每个窗口端出的都一样。浅色操作时可交票，窗口残影里还能核对叫号记录。
   来源：[src/data/items.config.json:201](../src/data/items.config.json#L201)
1342. 窗口包子
   来源：[src/data/items.config.json:207](../src/data/items.config.json#L207)
1343. 热包子，掰开还是馅。跑了这么多窗口，总算领到一份和菜单相符的东西。
   来源：[src/data/items.config.json:208](../src/data/items.config.json#L208)
1344. 窗口豆浆
   来源：[src/data/items.config.json:214](../src/data/items.config.json#L214)
1345. 豆浆，杯盖扣得很紧。单据没附在里面，至少这杯不用过滤着喝。
   来源：[src/data/items.config.json:215](../src/data/items.config.json#L215)
1346. 水煮蛋
   来源：[src/data/items.config.json:221](../src/data/items.config.json#L221)
1347. 一枚水煮蛋。按号领餐，领成什么听窗口的。
   来源：[src/data/items.config.json:222](../src/data/items.config.json#L222)
1348. 烫手的白粥
   来源：[src/data/items.config.json:228](../src/data/items.config.json#L228)
1349. 一碗烫手的白粥，米和水都很足。你找的那张纸不在碗里。
   来源：[src/data/items.config.json:229](../src/data/items.config.json#L229)
1350. 海报玻璃下的左半张票根，场次和票号还在，右侧验票区缺了一半。有票的证据充分，进场的条件不足。
   来源：[src/data/items.config.json:236](../src/data/items.config.json#L236)
1351. 取票机补打的右半张票根，另一半验票区在这里。场次、票号和断口都能拿来比，补打服务只补这么多。
   来源：[src/data/items.config.json:243](../src/data/items.config.json#L243)
1352. 两半票根场次相同、票号一致，接缝不挡验票区。终于能过闸了，票根还得留着。
   来源：[src/data/items.config.json:250](../src/data/items.config.json#L250)
1353. 节目单残页·开场
   来源：[src/data/items.config.json:256](../src/data/items.config.json#L256)
1354. 开场部分的残页。开演之前先说明演出即将开始，印得很郑重。简介里有几笔颜色偏淡。
   来源：[src/data/items.config.json:257](../src/data/items.config.json#L257)
1355. 节目单残页·追光
   来源：[src/data/items.config.json:263](../src/data/items.config.json#L263)
1356. 追光部分的残页。演员还没找到，灯位已经排好。简介里有几笔颜色偏淡。
   来源：[src/data/items.config.json:264](../src/data/items.config.json#L264)
1357. 节目单残页·谢幕
   来源：[src/data/items.config.json:270](../src/data/items.config.json#L270)
1358. 谢幕部分的残页。观众尚未入场，致谢名单已经写满。简介里有几笔颜色偏淡。
   来源：[src/data/items.config.json:271](../src/data/items.config.json#L271)
1359. 追光灯遥控器，放到灯控台才能操作。台上没按节目单走，台下暂时还能调灯。
   来源：[src/data/items.config.json:278](../src/data/items.config.json#L278)
1360. 刷毛上沾着荧光粉，吹散后会附在纸面上。剧场备着这种道具，至少说明他们也遇到过看不见的演员。
   来源：[src/data/items.config.json:285](../src/data/items.config.json#L285)
1361. 追光灯下抓到的替身，纸质和原件很接近。忙了一场，领到的是道具；还能留作诱饵。
   来源：[src/data/items.config.json:292](../src/data/items.config.json#L292)
1362. 剧场外捡到的节目单，边角还在滴水。想查纸张去向，可以拿它去论坛或馆藏系统找记录。
   来源：[src/data/items.config.json:299](../src/data/items.config.json#L299)
1363. 桥边
   来源：[src/data/items.config.json:305](../src/data/items.config.json#L305)；[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
1364. CC98 目击回复提到了桥边。人没追上，地点只报了一半。
   来源：[src/data/items.config.json:306](../src/data/items.config.json#L306)
1365. 倒影
   来源：[src/data/items.config.json:312](../src/data/items.config.json#L312)；[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
1366. 馆藏备注说页码只出现在倒影中。实物借走以后，连查页码也得换地方。
   来源：[src/data/items.config.json:313](../src/data/items.config.json#L313)
1367. 湖
   来源：[src/data/items.config.json:319](../src/data/items.config.json#L319)
1368. 朋友转来湖面异常水纹的消息。有现场照片，比问“你到哪了”多一点用处。
   来源：[src/data/items.config.json:320](../src/data/items.config.json#L320)
1369. 记录下的水面位置，能与浅色水纹对照。坐标有了，伸手还是够不着。
   来源：[src/data/items.config.json:327](../src/data/items.config.json#L327)
1370. 寝室吹风机
   来源：[src/data/items.config.json:333](../src/data/items.config.json#L333)
1371. 寝室书桌上的吹风机，插上就有风。天气页也留了接入口，宿舍电器的适用范围没人写上限。
   来源：[src/data/items.config.json:334](../src/data/items.config.json#L334)
1372. 钓竿
   来源：[src/data/items.config.json:340](../src/data/items.config.json#L340)
1373. 从湖面浮排边捞起的钓竿，钩子还在，能加诱饵或附件。上一位使用者的归还方式比较省事。
   来源：[src/data/items.config.json:341](../src/data/items.config.json#L341)
1374. 锈蚀柜钥匙
   来源：[src/data/items.config.json:347](../src/data/items.config.json#L347)
1375. 湖里钓起的柜钥匙，锈迹与码头储物柜对得上。柜子还锁着，钥匙先泡了水。
   来源：[src/data/items.config.json:348](../src/data/items.config.json#L348)
1376. 尼龙绳
   来源：[src/data/items.config.json:354](../src/data/items.config.json#L354)
1377. 柜里的耐水尼龙绳，够绕网框一圈。柜门锁得很认真，里面值钱的也就这卷绳。
   来源：[src/data/items.config.json:355](../src/data/items.config.json#L355)
1378. 断裂网框
   来源：[src/data/items.config.json:361](../src/data/items.config.json#L361)
1379. 水下捞起的旧网框，网面脱落，框沿还能绑绳。报废了一半，另一半还得接着用。
   来源：[src/data/items.config.json:362](../src/data/items.config.json#L362)
1380. 临时抄网
   来源：[src/data/items.config.json:368](../src/data/items.config.json#L368)；[src/modules/InventoryController.ts:17](../src/modules/InventoryController.ts#L17)
1381. 用尼龙绳重新绑好的网框，能托住钩不牢的东西。名称里保留“临时”，用多久再说。
   来源：[src/data/items.config.json:369](../src/data/items.config.json#L369)
1382. 金属饲料罐，晃起来有颗粒声，盖子得借硬边撬开。泡了这么久没漏，防水比手机可靠。
   来源：[src/data/items.config.json:376](../src/data/items.config.json#L376)
1383. 鱼食颗粒
   来源：[src/data/items.config.json:382](../src/data/items.config.json#L382)
1384. 罐里倒出的鱼食，撒到鱼群附近能引鱼。鱼不查领取资格，看见吃的就来。
   来源：[src/data/items.config.json:383](../src/data/items.config.json#L383)
1385. 小鲤鱼
   来源：[src/data/items.config.json:389](../src/data/items.config.json#L389)
1386. 刚钓起的小鲤鱼，还在扑腾。围栏里的黑天鹅一直朝这边看，最好别一直攥在手里。
   来源：[src/data/items.config.json:390](../src/data/items.config.json#L390)
1387. 天鹅磁铁
   来源：[src/data/items.config.json:396](../src/data/items.config.json#L396)
1388. 黑天鹅推来的磁性扣，可以固定在竿端。拿鱼换回一件金属，湖边的交易不开发票。
   来源：[src/data/items.config.json:397](../src/data/items.config.json#L397)
1389. 磁吸钓竿
   来源：[src/data/items.config.json:403](../src/data/items.config.json#L403)
1390. 竿端装了磁性扣，能吸住夹纸的金属结构。为取回一张纸，钓具改装已经做到这一步。
   来源：[src/data/items.config.json:404](../src/data/items.config.json#L404)
1391. 签到记录纸
   来源：[src/data/items.config.json:410](../src/data/items.config.json#L410)
1392. 一路追回的签到记录纸。签到处还要另验校园卡；为了证明来过，你已经来回跑了好几趟。
   来源：[src/data/items.config.json:411](../src/data/items.config.json#L411)
1393. 旧时针
   来源：[src/data/items.config.json:417](../src/data/items.config.json#L417)
1394. 从面包坊传送带里取出的旧时针，轴孔与大厅旧钟相配。不在配料表上，得赶紧装回去。
   来源：[src/data/items.config.json:418](../src/data/items.config.json#L418)
1395. 钟面定位片
   来源：[src/data/items.config.json:424](../src/data/items.config.json#L424)
1396. 204 讲台抽屉里的透明定位片，边缘有两条短刻度，可装回大厅旧钟。缺这么一小片，校准还要跑好几个房间。
   来源：[src/data/items.config.json:425](../src/data/items.config.json#L425)
1397. 短撬棍
   来源：[src/data/items.config.json:431](../src/data/items.config.json#L431)
1398. 短撬棍，扁头能伸进保洁车轮罩的缝。工具已经找到，维修申请暂时省了。
   来源：[src/data/items.config.json:432](../src/data/items.config.json#L432)
1399. 通用润滑油
   来源：[src/data/items.config.json:438](../src/data/items.config.json#L438)
1400. 一小瓶润滑油，能处理轮轴和旧钟齿轮的卡滞。“通用”限于机械，不含门禁权限。
   来源：[src/data/items.config.json:439](../src/data/items.config.json#L439)
1401. 黄铜分针组件
   来源：[src/data/items.config.json:445](../src/data/items.config.json#L445)
1402. 从 202 座椅间取回的黄铜分针组件，轴座磨损与大厅旧钟吻合。现在有了最后一分钟，还得自己带下楼。
   来源：[src/data/items.config.json:446](../src/data/items.config.json#L446)
1403. 窗边豆浆
   来源：[src/data/phonePhotoCatalog.ts:41](../src/data/phonePhotoCatalog.ts#L41)
1404. 高数草稿还摊在桌上，豆浆已经冷了。
   来源：[src/data/phonePhotoCatalog.ts:44](../src/data/phonePhotoCatalog.ts#L44)
1405. 06月18日 08:43
   来源：[src/data/phonePhotoCatalog.ts:45](../src/data/phonePhotoCatalog.ts#L45)
1406. 基础馆
   来源：[src/data/phonePhotoCatalog.ts:46](../src/data/phonePhotoCatalog.ts#L46)；[src/data/phonePhotoCatalog.ts:82](../src/data/phonePhotoCatalog.ts#L82)；[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
1407. 寝室晚饭
   来源：[src/data/phonePhotoCatalog.ts:53](../src/data/phonePhotoCatalog.ts#L53)
1408. 校园卡压着充电线，桌面没有收拾。
   来源：[src/data/phonePhotoCatalog.ts:56](../src/data/phonePhotoCatalog.ts#L56)
1409. 06月19日 19:16
   来源：[src/data/phonePhotoCatalog.ts:57](../src/data/phonePhotoCatalog.ts#L57)
1410. 紫云宿舍
   来源：[src/data/phonePhotoCatalog.ts:58](../src/data/phonePhotoCatalog.ts#L58)
1411. 雨后早餐
   来源：[src/data/phonePhotoCatalog.ts:65](../src/data/phonePhotoCatalog.ts#L65)
1412. 长椅还有水迹，纸袋放在靠内侧。
   来源：[src/data/phonePhotoCatalog.ts:68](../src/data/phonePhotoCatalog.ts#L68)
1413. 06月22日 07:28
   来源：[src/data/phonePhotoCatalog.ts:69](../src/data/phonePhotoCatalog.ts#L69)
1414. 东区
   来源：[src/data/phonePhotoCatalog.ts:70](../src/data/phonePhotoCatalog.ts#L70)
1415. 自习间隙
   来源：[src/data/phonePhotoCatalog.ts:77](../src/data/phonePhotoCatalog.ts#L77)
1416. 面包包装拆了一半，保温杯放在右边。
   来源：[src/data/phonePhotoCatalog.ts:80](../src/data/phonePhotoCatalog.ts#L80)
1417. 06月24日 16:02
   来源：[src/data/phonePhotoCatalog.ts:81](../src/data/phonePhotoCatalog.ts#L81)
1418. 食堂打包
   来源：[src/data/phonePhotoCatalog.ts:89](../src/data/phonePhotoCatalog.ts#L89)
1419. 餐巾纸折在盒饭旁边，桌面很干净。
   来源：[src/data/phonePhotoCatalog.ts:92](../src/data/phonePhotoCatalog.ts#L92)
1420. 06月26日 18:51
   来源：[src/data/phonePhotoCatalog.ts:93](../src/data/phonePhotoCatalog.ts#L93)
1421. 东区食堂
   来源：[src/data/phonePhotoCatalog.ts:94](../src/data/phonePhotoCatalog.ts#L94)；[src/data/phonePhotoCatalog.ts:178](../src/data/phonePhotoCatalog.ts#L178)
1422. 022 旧照
   来源：[src/data/phonePhotoCatalog.ts:101](../src/data/phonePhotoCatalog.ts#L101)
1423. 同一只 022 书包。侧袋里的半包纸，在 07:55 时已经存在。
   来源：[src/data/phonePhotoCatalog.ts:104](../src/data/phonePhotoCatalog.ts#L104)
1424. 06月28日 07:55
   来源：[src/data/phonePhotoCatalog.ts:105](../src/data/phonePhotoCatalog.ts#L105)
1425. 基础馆二楼南区
   来源：[src/data/phonePhotoCatalog.ts:106](../src/data/phonePhotoCatalog.ts#L106)
1426. 校门口的阴天
   来源：[src/data/phonePhotoCatalog.ts:113](../src/data/phonePhotoCatalog.ts#L113)
1427. 树荫压得很低，骑车的人都从拱门边绕过去。
   来源：[src/data/phonePhotoCatalog.ts:116](../src/data/phonePhotoCatalog.ts#L116)
1428. 07月01日 14:32
   来源：[src/data/phonePhotoCatalog.ts:117](../src/data/phonePhotoCatalog.ts#L117)
1429. 启真湖早晨
   来源：[src/data/phonePhotoCatalog.ts:125](../src/data/phonePhotoCatalog.ts#L125)
1430. 浮桥旁有两圈新波纹，车还停在柳树下面。
   来源：[src/data/phonePhotoCatalog.ts:128](../src/data/phonePhotoCatalog.ts#L128)
1431. 07月02日 09:12
   来源：[src/data/phonePhotoCatalog.ts:129](../src/data/phonePhotoCatalog.ts#L129)
1432. 雨后的月牙楼
   来源：[src/data/phonePhotoCatalog.ts:137](../src/data/phonePhotoCatalog.ts#L137)
1433. 地砖还在反光，伞已经可以收起来了。
   来源：[src/data/phonePhotoCatalog.ts:140](../src/data/phonePhotoCatalog.ts#L140)
1434. 07月03日 16:47
   来源：[src/data/phonePhotoCatalog.ts:141](../src/data/phonePhotoCatalog.ts#L141)
1435. 晚自习加餐
   来源：[src/data/phonePhotoCatalog.ts:149](../src/data/phonePhotoCatalog.ts#L149)
1436. 耳机缠在本子边，饭盒还留着一点热气。
   来源：[src/data/phonePhotoCatalog.ts:152](../src/data/phonePhotoCatalog.ts#L152)
1437. 07月05日 21:06
   来源：[src/data/phonePhotoCatalog.ts:153](../src/data/phonePhotoCatalog.ts#L153)
1438. 学习空间
   来源：[src/data/phonePhotoCatalog.ts:154](../src/data/phonePhotoCatalog.ts#L154)
1439. 车筐里的雨衣
   来源：[src/data/phonePhotoCatalog.ts:161](../src/data/phonePhotoCatalog.ts#L161)
1440. 雨停得很快，车筐上还挂着水珠。
   来源：[src/data/phonePhotoCatalog.ts:164](../src/data/phonePhotoCatalog.ts#L164)
1441. 07月06日 12:23
   来源：[src/data/phonePhotoCatalog.ts:165](../src/data/phonePhotoCatalog.ts#L165)
1442. 宿舍区
   来源：[src/data/phonePhotoCatalog.ts:166](../src/data/phonePhotoCatalog.ts#L166)
1443. 午饭排队
   来源：[src/data/phonePhotoCatalog.ts:173](../src/data/phonePhotoCatalog.ts#L173)
1444. 前面只剩三个人，番茄鸡蛋面先端到了。
   来源：[src/data/phonePhotoCatalog.ts:176](../src/data/phonePhotoCatalog.ts#L176)
1445. 07月07日 11:54
   来源：[src/data/phonePhotoCatalog.ts:177](../src/data/phonePhotoCatalog.ts#L177)
1446. 找到道具栏
   来源：[src/data/presentation-cues.ts:34](../src/data/presentation-cues.ts#L34)
1447. 校园地图内出现了可调查的寝室据点
   来源：[src/data/presentation-cues.ts:35](../src/data/presentation-cues.ts#L35)
1448. 箱
   来源：[src/data/presentation-cues.ts:36](../src/data/presentation-cues.ts#L36)
1449. 让地图人物回应你
   来源：[src/data/presentation-cues.ts:42](../src/data/presentation-cues.ts#L42)
1450. 先让寝室里的人知道自己是谁
   来源：[src/data/presentation-cues.ts:43](../src/data/presentation-cues.ts#L43)
1451. 右移箭头已合成
   来源：[src/data/presentation-cues.ts:50](../src/data/presentation-cues.ts#L50)
1452. 它能把一个目标向右移动两格
   来源：[src/data/presentation-cues.ts:51](../src/data/presentation-cues.ts#L51)
1453. 交易完成
   来源：[src/data/presentation-cues.ts:58](../src/data/presentation-cues.ts#L58)
1454. 游戏手柄已放入道具栏
   来源：[src/data/presentation-cues.ts:59](../src/data/presentation-cues.ts#L59)
1455. 可以出门了
   来源：[src/data/presentation-cues.ts:66](../src/data/presentation-cues.ts#L66)；[src/scenes/rpg/RpgGameHost.tsx:1483](../src/scenes/rpg/RpgGameHost.tsx#L1483)
1456. 寝室出口已开放
   来源：[src/data/presentation-cues.ts:67](../src/data/presentation-cues.ts#L67)
1457. 门
   来源：[src/data/presentation-cues.ts:68](../src/data/presentation-cues.ts#L68)
1458. 进入图书馆，找到 022
   来源：[src/data/presentation-cues.ts:74](../src/data/presentation-cues.ts#L74)
1459. 基础图书馆入口已开放
   来源：[src/data/presentation-cues.ts:75](../src/data/presentation-cues.ts#L75)
1460. 入馆记录待核对
   来源：[src/data/presentation-cues.ts:82](../src/data/presentation-cues.ts#L82)
1461. 点击闸机旁的小屏查看两条时间
   来源：[src/data/presentation-cues.ts:83](../src/data/presentation-cues.ts#L83)
1462. 022 被书包占用
   来源：[src/data/presentation-cues.ts:91](../src/data/presentation-cues.ts#L91)
1463. 调查纸条与离座规则
   来源：[src/data/presentation-cues.ts:92](../src/data/presentation-cues.ts#L92)
1464. 获得占座纸条
   来源：[src/data/presentation-cues.ts:100](../src/data/presentation-cues.ts#L100)
1465. 可拖入 CC98 搜索
   来源：[src/data/presentation-cues.ts:101](../src/data/presentation-cues.ts#L101)
1466. 调查帖已找到
   来源：[src/data/presentation-cues.ts:109](../src/data/presentation-cues.ts#L109)
1467. 23 楼内容，5 条 ac01 可选
   来源：[src/data/presentation-cues.ts:110](../src/data/presentation-cues.ts#L110)
1468. 正确馆藏已确认
   来源：[src/data/presentation-cues.ts:117](../src/data/presentation-cues.ts#L117)
1469. 索书号 I247.55 / 755
   来源：[src/data/presentation-cues.ts:118](../src/data/presentation-cues.ts#L118)
1470. 旧版离座规则
   来源：[src/data/presentation-cues.ts:125](../src/data/presentation-cues.ts#L125)
1471. 恢复 022 需要三项证明
   来源：[src/data/presentation-cues.ts:126](../src/data/presentation-cues.ts#L126)
1472. 物品识别报告已生成
   来源：[src/data/presentation-cues.ts:134](../src/data/presentation-cues.ts#L134)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:203](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L203)
1473. 对象类型：书包
   来源：[src/data/presentation-cues.ts:135](../src/data/presentation-cues.ts#L135)
1474. 失物招领登记已盖章
   来源：[src/data/presentation-cues.ts:143](../src/data/presentation-cues.ts#L143)
1475. 章
   来源：[src/data/presentation-cues.ts:144](../src/data/presentation-cues.ts#L144)
1476. 右移箭头仍保留在道具栏
   来源：[src/data/presentation-cues.ts:152](../src/data/presentation-cues.ts#L152)
1477. 7 / 47 / 3 补录通过
   来源：[src/data/presentation-cues.ts:161](../src/data/presentation-cues.ts#L161)
1478. 四项证据已公示
   来源：[src/data/presentation-cues.ts:168](../src/data/presentation-cues.ts#L168)
1479. 系统将说明帮顶与四位口令规则
   来源：[src/data/presentation-cues.ts:169](../src/data/presentation-cues.ts#L169)
1480. 进入十大
   来源：[src/data/presentation-cues.ts:176](../src/data/presentation-cues.ts#L176)
1481. 剧情帖排名 01
   来源：[src/data/presentation-cues.ts:177](../src/data/presentation-cues.ts#L177)
1482. 022 恢复申请已开放
   来源：[src/data/presentation-cues.ts:184](../src/data/presentation-cues.ts#L184)
1483. 提交三项恢复证明
   来源：[src/data/presentation-cues.ts:185](../src/data/presentation-cues.ts#L185)
1484. 解除占座 PASS
   来源：[src/data/presentation-cues.ts:192](../src/data/presentation-cues.ts#L192)
1485. 仅可用于 RPG 中的 022 书包
   来源：[src/data/presentation-cues.ts:193](../src/data/presentation-cues.ts#L193)
1486. 占座对象已转移
   来源：[src/data/presentation-cues.ts:200](../src/data/presentation-cues.ts#L200)
1487. 书包已送往失物招领
   来源：[src/data/presentation-cues.ts:201](../src/data/presentation-cues.ts#L201)
1488. 它正在船尾对准航线。继续交替划桨。
   来源：[src/data/pursuit.audio.content.json:59](../src/data/pursuit.audio.content.json#L59)
1489. It is lining up behind you. Keep alternating.
   来源：[src/data/pursuit.audio.content.json:60](../src/data/pursuit.audio.content.json#L60)
1490. 闹钟
   来源：[src/data/scenes.config.json:2](../src/data/scenes.config.json#L2)
1491. P00
   来源：[src/data/scenes.config.json:2](../src/data/scenes.config.json#L2)
1492. 07:55 起床
   来源：[src/data/scenes.config.json:3](../src/data/scenes.config.json#L3)
1493. P01
   来源：[src/data/scenes.config.json:3](../src/data/scenes.config.json#L3)
1494. 手机主界面
   来源：[src/data/scenes.config.json:4](../src/data/scenes.config.json#L4)
1495. P13
   来源：[src/data/scenes.config.json:4](../src/data/scenes.config.json#L4)
1496. 微信 / 朋友头像谜题
   来源：[src/data/scenes.config.json:5](../src/data/scenes.config.json#L5)
1497. P14
   来源：[src/data/scenes.config.json:5](../src/data/scenes.config.json#L5)
1498. 浙大钉（加载/内页）
   来源：[src/data/scenes.config.json:6](../src/data/scenes.config.json#L6)
1499. P15
   来源：[src/data/scenes.config.json:6](../src/data/scenes.config.json#L6)
1500. 浙大体艺
   来源：[src/data/scenes.config.json:7](../src/data/scenes.config.json#L7)；[src/scenes/phone/P08_Settings/index.tsx:29](../src/scenes/phone/P08_Settings/index.tsx#L29)
1501. P06
   来源：[src/data/scenes.config.json:7](../src/data/scenes.config.json#L7)
1502. 天气 / 水滴谜题
   来源：[src/data/scenes.config.json:8](../src/data/scenes.config.json#L8)
1503. P07
   来源：[src/data/scenes.config.json:8](../src/data/scenes.config.json#L8)
1504. 玩家
   来源：[src/data/storyLines.ts:60](../src/data/storyLines.ts#L60)；[src/scenes/phone/P02_CC98/index.tsx:137](../src/scenes/phone/P02_CC98/index.tsx#L137)
1505. 基础图书馆门前
   来源：[src/demos/campus-map-demo.tsx:32](../src/demos/campus-map-demo.tsx#L32)
1506. 大食堂门前
   来源：[src/demos/campus-map-demo.tsx:33](../src/demos/campus-map-demo.tsx#L33)
1507. 追踪脚印
   来源：[src/demos/campus-map-demo.tsx:46](../src/demos/campus-map-demo.tsx#L46)
1508. 抵达食堂
   来源：[src/demos/campus-map-demo.tsx:47](../src/demos/campus-map-demo.tsx#L47)
1509. 进入食堂
   来源：[src/demos/campus-map-demo.tsx:48](../src/demos/campus-map-demo.tsx#L48)
1510. 寻找异常餐盘
   来源：[src/demos/campus-map-demo.tsx:49](../src/demos/campus-map-demo.tsx#L49)
1511. 调配今日新品
   来源：[src/demos/campus-map-demo.tsx:50](../src/demos/campus-map-demo.tsx#L50)
1512. 破解点餐机
   来源：[src/demos/campus-map-demo.tsx:51](../src/demos/campus-map-demo.tsx#L51)
1513. 寻找 0755 窗口
   来源：[src/demos/campus-map-demo.tsx:52](../src/demos/campus-map-demo.tsx#L52)
1514. 封堵纸条出口
   来源：[src/demos/campus-map-demo.tsx:53](../src/demos/campus-map-demo.tsx#L53)
1515. 准备继续追赶
   来源：[src/demos/campus-map-demo.tsx:54](../src/demos/campus-map-demo.tsx#L54)
1516. 追逐中
   来源：[src/demos/campus-map-demo.tsx:55](../src/demos/campus-map-demo.tsx#L55)
1517. 抵达体艺馆
   来源：[src/demos/campus-map-demo.tsx:56](../src/demos/campus-map-demo.tsx#L56)
1518. 地图加载中…
   来源：[src/demos/campus-map-demo.tsx:168](../src/demos/campus-map-demo.tsx#L168)
1519. 食堂内的纸条已被逼出，已返回大食堂门前。
   来源：[src/demos/campus-map-demo.tsx:224](../src/demos/campus-map-demo.tsx#L224)
1520. 大食堂剧情已重开：已到{{target.label}}，按空格进入。
   来源：[src/demos/campus-map-demo.tsx:358](../src/demos/campus-map-demo.tsx#L358)
1521. 已回到{{target.label}}，当前为自由探索。
   来源：[src/demos/campus-map-demo.tsx:359](../src/demos/campus-map-demo.tsx#L359)
1522. 紫金港校园大地图与大食堂剧情演示
   来源：[src/demos/campus-map-demo.tsx:385](../src/demos/campus-map-demo.tsx#L385)
1523. 校园与大食堂剧情交互区
   来源：[src/demos/campus-map-demo.tsx:388](../src/demos/campus-map-demo.tsx#L388)
1524. 大食堂剧情
   来源：[src/demos/campus-map-demo.tsx:393](../src/demos/campus-map-demo.tsx#L393)；[src/demos/campus-map-demo.tsx:400](../src/demos/campus-map-demo.tsx#L400)
1525. 紫金港校园大地图
   来源：[src/demos/campus-map-demo.tsx:393](../src/demos/campus-map-demo.tsx#L393)
1526. 演示操作
   来源：[src/demos/campus-map-demo.tsx:398](../src/demos/campus-map-demo.tsx#L398)
1527. 自由探索
   来源：[src/demos/campus-map-demo.tsx:399](../src/demos/campus-map-demo.tsx#L399)
1528. 切到深色
   来源：[src/demos/campus-map-demo.tsx:409](../src/demos/campus-map-demo.tsx#L409)
1529. 切回浅色
   来源：[src/demos/campus-map-demo.tsx:409](../src/demos/campus-map-demo.tsx#L409)
1530. 回到角色
   来源：[src/demos/campus-map-demo.tsx:414](../src/demos/campus-map-demo.tsx#L414)
1531. 缩小地图
   来源：[src/demos/campus-map-demo.tsx:415](../src/demos/campus-map-demo.tsx#L415)
1532. 放大地图
   来源：[src/demos/campus-map-demo.tsx:416](../src/demos/campus-map-demo.tsx#L416)
1533. 全屏
   来源：[src/demos/campus-map-demo.tsx:419](../src/demos/campus-map-demo.tsx#L419)
1534. 坐标
   来源：[src/demos/campus-map-demo.tsx:423](../src/demos/campus-map-demo.tsx#L423)
1535. 缩放
   来源：[src/demos/campus-map-demo.tsx:424](../src/demos/campus-map-demo.tsx#L424)
1536. 剧情
   来源：[src/demos/campus-map-demo.tsx:427](../src/demos/campus-map-demo.tsx#L427)
1537. 浅色模式
   来源：[src/demos/campus-map-demo.tsx:428](../src/demos/campus-map-demo.tsx#L428)
1538. 深色模式
   来源：[src/demos/campus-map-demo.tsx:428](../src/demos/campus-map-demo.tsx#L428)
1539. WASD / 方向键移动 · 空格交互 · Tab 切换明暗
   来源：[src/demos/campus-map-demo.tsx:433](../src/demos/campus-map-demo.tsx#L433)
1540. WASD / 方向键移动 · Shift 冲刺 · 空格进入 · 单击路面寻路
   来源：[src/demos/campus-map-demo.tsx:434](../src/demos/campus-map-demo.tsx#L434)
1541. 触控方向与交互
   来源：[src/demos/campus-map-demo.tsx:439](../src/demos/campus-map-demo.tsx#L439)
1542. 向上移动
   来源：[src/demos/campus-map-demo.tsx:440](../src/demos/campus-map-demo.tsx#L440)
1543. 向左移动
   来源：[src/demos/campus-map-demo.tsx:441](../src/demos/campus-map-demo.tsx#L441)
1544. 向下移动
   来源：[src/demos/campus-map-demo.tsx:442](../src/demos/campus-map-demo.tsx#L442)
1545. 向右移动
   来源：[src/demos/campus-map-demo.tsx:443](../src/demos/campus-map-demo.tsx#L443)
1546. 空格
   来源：[src/demos/campus-map-demo.tsx:444](../src/demos/campus-map-demo.tsx#L444)；[src/scenes/rpg/RpgControlHints.ts:6](../src/scenes/rpg/RpgControlHints.ts#L6)
1547. 页面运行出错
   来源：[src/ErrorBoundary.tsx:26](../src/ErrorBoundary.tsx#L26)
1548. 多云
   来源：[src/modules/CampusWeatherModel.ts:5](../src/modules/CampusWeatherModel.ts#L5)；[src/modules/CampusWeatherModel.ts:13](../src/modules/CampusWeatherModel.ts#L13)
1549. 小雨
   来源：[src/modules/CampusWeatherModel.ts:5](../src/modules/CampusWeatherModel.ts#L5)；[src/modules/CampusWeatherModel.ts:11](../src/modules/CampusWeatherModel.ts#L11)
1550. 校名缩写
   来源：[src/modules/Cc98UnifiedLoginModel.ts:11](../src/modules/Cc98UnifiedLoginModel.ts#L11)
1551. 取浙江大学英文名的三个大写字母。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:12](../src/modules/Cc98UnifiedLoginModel.ts#L12)
1552. 校史年份
   来源：[src/modules/Cc98UnifiedLoginModel.ts:17](../src/modules/Cc98UnifiedLoginModel.ts#L17)
1553. 接上求是书院创办的四位年份。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:18](../src/modules/Cc98UnifiedLoginModel.ts#L18)
1554. 结尾标点
   来源：[src/modules/Cc98UnifiedLoginModel.ts:23](../src/modules/Cc98UnifiedLoginModel.ts#L23)
1555. 保留认证公告最后的感叹号。
   来源：[src/modules/Cc98UnifiedLoginModel.ts:24](../src/modules/Cc98UnifiedLoginModel.ts#L24)
1556. already\_authenticated
   来源：[src/modules/Cc98UnifiedLoginModel.ts:76](../src/modules/Cc98UnifiedLoginModel.ts#L76)
1557. identity\_unavailable
   来源：[src/modules/Cc98UnifiedLoginModel.ts:77](../src/modules/Cc98UnifiedLoginModel.ts#L77)
1558. authenticated
   来源：[src/modules/Cc98UnifiedLoginModel.ts:84](../src/modules/Cc98UnifiedLoginModel.ts#L84)
1559. rejected
   来源：[src/modules/Cc98UnifiedLoginModel.ts:89](../src/modules/Cc98UnifiedLoginModel.ts#L89)
1560. both
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1561. password
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1562. student\_id
   来源：[src/modules/Cc98UnifiedLoginModel.ts:90](../src/modules/Cc98UnifiedLoginModel.ts#L90)
1563. network
   来源：[src/modules/CheckinController.ts:19](../src/modules/CheckinController.ts#L19)
1564. wrong\_code
   来源：[src/modules/CheckinController.ts:24](../src/modules/CheckinController.ts#L24)
1565. 磁性钓鱼竿
   来源：[src/modules/InventoryController.ts:18](../src/modules/InventoryController.ts#L18)
1566. 低电量模式已开启：打开应用仅消耗 1%，亮度上限 45%，音乐已暂停。
   来源：[src/modules/PhoneBatteryController.ts:62](../src/modules/PhoneBatteryController.ts#L62)
1567. 低电量模式已关闭：打开应用恢复消耗 2%。
   来源：[src/modules/PhoneBatteryController.ts:63](../src/modules/PhoneBatteryController.ts#L63)
1568. too\_far
   来源：[src/modules/PhoneBatteryController.ts:76](../src/modules/PhoneBatteryController.ts#L76)
1569. 接线够不到，请走到充电服务站旁。
   来源：[src/modules/PhoneBatteryController.ts:77](../src/modules/PhoneBatteryController.ts#L77)
1570. wrong\_mode
   来源：[src/modules/PhoneBatteryController.ts:78](../src/modules/PhoneBatteryController.ts#L78)
1571. 深色观察只能查看设备。切到浅色操作后接入充电线。
   来源：[src/modules/PhoneBatteryController.ts:79](../src/modules/PhoneBatteryController.ts#L79)
1572. 需要在现场与充电服务站交互，手机中不能接入电源。
   来源：[src/modules/PhoneBatteryController.ts:80](../src/modules/PhoneBatteryController.ts#L80)
1573. 当前电量 {{current.phoneBattery.percent}}%，暂不需要补电。
   来源：[src/modules/PhoneBatteryController.ts:88](../src/modules/PhoneBatteryController.ts#L88)
1574. 已接入{{source}}，电量恢复至 {{PHONE\_BATTERY\_RECHARGE\_PERCENT}}%。
   来源：[src/modules/PhoneBatteryController.ts:108](../src/modules/PhoneBatteryController.ts#L108)
1575. 电量降至 {{to}}%。点状态栏，可开启低电量模式或寻找附近电源。
   来源：[src/modules/PhoneBatteryController.ts:133](../src/modules/PhoneBatteryController.ts#L133)
1576. 已进入 1% 任务保底电量。主线功能继续可用，可在现场充电服务站补电。
   来源：[src/modules/PhoneBatteryController.ts:139](../src/modules/PhoneBatteryController.ts#L139)
1577. developer\_checkpoint\_session
   来源：[src/modules/SaveController.ts:26](../src/modules/SaveController.ts#L26)
1578. 匿名用户
   来源：[src/scenes/phone/P02_CC98/index.tsx:69](../src/scenes/phone/P02_CC98/index.tsx#L69)
1579. 刚刚
   来源：[src/scenes/phone/P02_CC98/index.tsx:76](../src/scenes/phone/P02_CC98/index.tsx#L76)；[src/scenes/phone/P02_CC98/index.tsx:237](../src/scenes/phone/P02_CC98/index.tsx#L237)
1580. 如题。
   来源：[src/scenes/phone/P02_CC98/index.tsx:77](../src/scenes/phone/P02_CC98/index.tsx#L77)
1581. 今天 09:{{String(12 + index \* 2).padStart(2, "0")}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:80](../src/scenes/phone/P02_CC98/index.tsx#L80)
1582. {{\[3, 8, 14\]\[index\]}}楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:81](../src/scenes/phone/P02_CC98/index.tsx#L81)
1583. 今天 {{reply.time}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:108](../src/scenes/phone/P02_CC98/index.tsx#L108)
1584. 今天 08:29
   来源：[src/scenes/phone/P02_CC98/index.tsx:125](../src/scenes/phone/P02_CC98/index.tsx#L125)
1585. 今天 08:30
   来源：[src/scenes/phone/P02_CC98/index.tsx:135](../src/scenes/phone/P02_CC98/index.tsx#L135)
1586. 今天 08:31
   来源：[src/scenes/phone/P02_CC98/index.tsx:146](../src/scenes/phone/P02_CC98/index.tsx#L146)
1587. 网络提示
   来源：[src/scenes/phone/P02_CC98/index.tsx:148](../src/scenes/phone/P02_CC98/index.tsx#L148)
1588. 今天 08:32
   来源：[src/scenes/phone/P02_CC98/index.tsx:157](../src/scenes/phone/P02_CC98/index.tsx#L157)
1589. 系统回执
   来源：[src/scenes/phone/P02_CC98/index.tsx:159](../src/scenes/phone/P02_CC98/index.tsx#L159)
1590. 23 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:182](../src/scenes/phone/P02_CC98/index.tsx#L182)
1591. 【求助】022 座位今日临时离开
   来源：[src/scenes/phone/P02_CC98/index.tsx:183](../src/scenes/phone/P02_CC98/index.tsx#L183)
1592. 12 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:183](../src/scenes/phone/P02_CC98/index.tsx#L183)
1593. 来源不匹配：这是今日新帖，纸条引用的是旧版公开记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:183](../src/scenes/phone/P02_CC98/index.tsx#L183)
1594. 来源为今日新帖，没有旧版离座规定的引用。
   来源：[src/scenes/phone/P02_CC98/index.tsx:183](../src/scenes/phone/P02_CC98/index.tsx#L183)
1595. 【记录】二南 022 晚间使用情况
   来源：[src/scenes/phone/P02_CC98/index.tsx:184](../src/scenes/phone/P02_CC98/index.tsx#L184)
1596. 31 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:184](../src/scenes/phone/P02_CC98/index.tsx#L184)
1597. 发布时间为当日 22:40，早于纸条中的本次离座事件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:184](../src/scenes/phone/P02_CC98/index.tsx#L184)
1598. 时间不匹配：这条记录早于本次 022 占用事件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:184](../src/scenes/phone/P02_CC98/index.tsx#L184)
1599. 【闲聊】二楼南区今天还有位置吗
   来源：[src/scenes/phone/P02_CC98/index.tsx:185](../src/scenes/phone/P02_CC98/index.tsx#L185)
1600. 18 楼
   来源：[src/scenes/phone/P02_CC98/index.tsx:185](../src/scenes/phone/P02_CC98/index.tsx#L185)
1601. 附件不匹配：这条帖子没有纸条对应的离座凭据。
   来源：[src/scenes/phone/P02_CC98/index.tsx:185](../src/scenes/phone/P02_CC98/index.tsx#L185)
1602. 正文提到 022，附件区为空。
   来源：[src/scenes/phone/P02_CC98/index.tsx:185](../src/scenes/phone/P02_CC98/index.tsx#L185)
1603. 本月
   来源：[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
1604. 本周
   来源：[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
1605. 发现
   来源：[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
1606. 活动
   来源：[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
1607. 今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)；[src/scenes/phone/P02_CC98/index.tsx:832](../src/scenes/phone/P02_CC98/index.tsx#L832)
1608. 往年今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:194](../src/scenes/phone/P02_CC98/index.tsx#L194)
1609. 新帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:197](../src/scenes/phone/P02_CC98/index.tsx#L197)；[src/scenes/phone/P02_CC98/index.tsx:969](../src/scenes/phone/P02_CC98/index.tsx#L969)
1610. 关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:198](../src/scenes/phone/P02_CC98/index.tsx#L198)；[src/scenes/phone/P02_CC98/index.tsx:929](../src/scenes/phone/P02_CC98/index.tsx#L929)
1611. 版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:199](../src/scenes/phone/P02_CC98/index.tsx#L199)
1612. 校内日常、天气和临时消息
   来源：[src/scenes/phone/P02_CC98/index.tsx:221](../src/scenes/phone/P02_CC98/index.tsx#L221)
1613. 匿名倾诉、互助和情绪整理
   来源：[src/scenes/phone/P02_CC98/index.tsx:222](../src/scenes/phone/P02_CC98/index.tsx#L222)
1614. 步行、骑行和校内出行
   来源：[src/scenes/phone/P02_CC98/index.tsx:223](../src/scenes/phone/P02_CC98/index.tsx#L223)
1615. 资料、课程和复习讨论
   来源：[src/scenes/phone/P02_CC98/index.tsx:224](../src/scenes/phone/P02_CC98/index.tsx#L224)
1616. 电话卡、网络和通讯服务
   来源：[src/scenes/phone/P02_CC98/index.tsx:225](../src/scenes/phone/P02_CC98/index.tsx#L225)
1617. 馆内规则、座位和设备
   来源：[src/scenes/phone/P02_CC98/index.tsx:226](../src/scenes/phone/P02_CC98/index.tsx#L226)
1618. 自习地点与安静程度
   来源：[src/scenes/phone/P02_CC98/index.tsx:227](../src/scenes/phone/P02_CC98/index.tsx#L227)
1619. 窗口、排队和座位
   来源：[src/scenes/phone/P02_CC98/index.tsx:228](../src/scenes/phone/P02_CC98/index.tsx#L228)
1620. 打印、复印和取件
   来源：[src/scenes/phone/P02_CC98/index.tsx:229](../src/scenes/phone/P02_CC98/index.tsx#L229)
1621. 校园卡使用和服务记录
   来源：[src/scenes/phone/P02_CC98/index.tsx:230](../src/scenes/phone/P02_CC98/index.tsx#L230)
1622. 遗失物和失物信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:231](../src/scenes/phone/P02_CC98/index.tsx#L231)
1623. 闲置物品与当面交易提醒
   来源：[src/scenes/phone/P02_CC98/index.tsx:232](../src/scenes/phone/P02_CC98/index.tsx#L232)
1624. 轻松话题和校园小事
   来源：[src/scenes/phone/P02_CC98/index.tsx:233](../src/scenes/phone/P02_CC98/index.tsx#L233)
1625. 课程与年份入口
   来源：[src/scenes/phone/P02_CC98/index.tsx:284](../src/scenes/phone/P02_CC98/index.tsx#L284)
1626. 先选课程，再按年份进入资料目录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:285](../src/scenes/phone/P02_CC98/index.tsx#L285)
1627. 旧自习讨论
   来源：[src/scenes/phone/P02_CC98/index.tsx:289](../src/scenes/phone/P02_CC98/index.tsx#L289)
1628. 旧帖能核对座位与插座记录，但日期可能已经过期。
   来源：[src/scenes/phone/P02_CC98/index.tsx:290](../src/scenes/phone/P02_CC98/index.tsx#L290)
1629. 今晚仍要现场核验
   来源：[src/scenes/phone/P02_CC98/index.tsx:294](../src/scenes/phone/P02_CC98/index.tsx#L294)
1630. A2 的门牌、房间和通道以今晚实际情况为准。
   来源：[src/scenes/phone/P02_CC98/index.tsx:295](../src/scenes/phone/P02_CC98/index.tsx#L295)
1631. 首页推荐顺序
   来源：[src/scenes/phone/P02_CC98/index.tsx:299](../src/scenes/phone/P02_CC98/index.tsx#L299)
1632. 推荐位会变化，无法作为资料目录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:300](../src/scenes/phone/P02_CC98/index.tsx#L300)
1633. 直接照抄旧路线
   来源：[src/scenes/phone/P02_CC98/index.tsx:304](../src/scenes/phone/P02_CC98/index.tsx#L304)
1634. 旧路线没有记录今晚的封闭入口。
   来源：[src/scenes/phone/P02_CC98/index.tsx:305](../src/scenes/phone/P02_CC98/index.tsx#L305)
1635. accepted
   来源：[src/scenes/phone/P02_CC98/index.tsx:326](../src/scenes/phone/P02_CC98/index.tsx#L326)；[src/scenes/rpg/RpgGameHost.tsx:1477](../src/scenes/rpg/RpgGameHost.tsx#L1477)；[src/scenes/rpg/RpgGameHost.tsx:1561](../src/scenes/rpg/RpgGameHost.tsx#L1561)；[src/scenes/rpg/RpgGameHost.tsx:1589](../src/scenes/rpg/RpgGameHost.tsx#L1589)；[src/scenes/rpg/RpgGameHost.tsx:1597](../src/scenes/rpg/RpgGameHost.tsx#L1597)；[src/scenes/rpg/RpgGameHost.tsx:1609](../src/scenes/rpg/RpgGameHost.tsx#L1609)；[src/scenes/rpg/RpgGameHost.tsx:1627](../src/scenes/rpg/RpgGameHost.tsx#L1627)；[src/scenes/rpg/RpgGameHost.tsx:1652](../src/scenes/rpg/RpgGameHost.tsx#L1652)；[src/scenes/rpg/RpgGameHost.tsx:1662](../src/scenes/rpg/RpgGameHost.tsx#L1662)；[src/scenes/rpg/RpgGameHost.tsx:1669](../src/scenes/rpg/RpgGameHost.tsx#L1669)
1636. already\_complete
   来源：[src/scenes/phone/P02_CC98/index.tsx:328](../src/scenes/phone/P02_CC98/index.tsx#L328)
1637. incorrect
   来源：[src/scenes/phone/P02_CC98/index.tsx:330](../src/scenes/phone/P02_CC98/index.tsx#L330)
1638. 这三项里混进了今晚无法使用的信息。再看一遍帖子和回复。
   来源：[src/scenes/phone/P02_CC98/index.tsx:331](../src/scenes/phone/P02_CC98/index.tsx#L331)
1639. 学习天地资料索引已导入自习群。
   来源：[src/scenes/phone/P02_CC98/index.tsx:338](../src/scenes/phone/P02_CC98/index.tsx#L338)
1640. 筛选并导入学习天地资料
   来源：[src/scenes/phone/P02_CC98/index.tsx:343](../src/scenes/phone/P02_CC98/index.tsx#L343)
1641. 导入前核对
   来源：[src/scenes/phone/P02_CC98/index.tsx:345](../src/scenes/phone/P02_CC98/index.tsx#L345)
1642. 选出今晚还能使用的三项信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:346](../src/scenes/phone/P02_CC98/index.tsx#L346)
1643. 已导入麦斯威夜间自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:372](../src/scenes/phone/P02_CC98/index.tsx#L372)
1644. 从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。
   来源：[src/scenes/phone/P02_CC98/index.tsx:451](../src/scenes/phone/P02_CC98/index.tsx#L451)
1645. 启真湖 · 22:37:05
   来源：[src/scenes/phone/P02_CC98/index.tsx:452](../src/scenes/phone/P02_CC98/index.tsx#L452)
1646. 晚上水面反光挺亮，靠岸别太快。
   来源：[src/scenes/phone/P02_CC98/index.tsx:455](../src/scenes/phone/P02_CC98/index.tsx#L455)
1647. 最后一张图像是朝东边拍的。
   来源：[src/scenes/phone/P02_CC98/index.tsx:456](../src/scenes/phone/P02_CC98/index.tsx#L456)
1648. 本次记录准备结束，选择楼主的最后一条回复。
   来源：[src/scenes/phone/P02_CC98/index.tsx:459](../src/scenes/phone/P02_CC98/index.tsx#L459)
1649. qizhen-summary
   来源：[src/scenes/phone/P02_CC98/index.tsx:463](../src/scenes/phone/P02_CC98/index.tsx#L463)；[src/scenes/phone/P02_CC98/index.tsx:473](../src/scenes/phone/P02_CC98/index.tsx#L473)
1650. 安全返航
   来源：[src/scenes/phone/P02_CC98/index.tsx:467](../src/scenes/phone/P02_CC98/index.tsx#L467)
1651. 船和人都回来了。湖上的事先记到这里，剩下的等我整理。
   来源：[src/scenes/phone/P02_CC98/index.tsx:468](../src/scenes/phone/P02_CC98/index.tsx#L468)
1652. 细节暂不公开
   来源：[src/scenes/phone/P02_CC98/index.tsx:477](../src/scenes/phone/P02_CC98/index.tsx#L477)
1653. 最后一段发生了点不适合写进划船记录的事。人已上岸，其他细节暂时保留。
   来源：[src/scenes/phone/P02_CC98/index.tsx:478](../src/scenes/phone/P02_CC98/index.tsx#L478)
1654. 发布收尾并保存时间
   来源：[src/scenes/phone/P02_CC98/index.tsx:481](../src/scenes/phone/P02_CC98/index.tsx#L481)
1655. 纸条已读取。请核对搜索结果的来源、时间和附件。
   来源：[src/scenes/phone/P02_CC98/index.tsx:552](../src/scenes/phone/P02_CC98/index.tsx#L552)
1656. 湿纸特征已加入搜索。找到一条刚发布的目击帖。
   来源：[src/scenes/phone/P02_CC98/index.tsx:557](../src/scenes/phone/P02_CC98/index.tsx#L557)
1657. 校内讨论和临时信息
   来源：[src/scenes/phone/P02_CC98/index.tsx:614](../src/scenes/phone/P02_CC98/index.tsx#L614)
1658. CC98 仅支持校园网。请切换后重新进入。
   来源：[src/scenes/phone/P02_CC98/index.tsx:646](../src/scenes/phone/P02_CC98/index.tsx#L646)
1659. CC98 校园网验证
   来源：[src/scenes/phone/P02_CC98/index.tsx:660](../src/scenes/phone/P02_CC98/index.tsx#L660)
1660. 网络验证失败
   来源：[src/scenes/phone/P02_CC98/index.tsx:664](../src/scenes/phone/P02_CC98/index.tsx#L664)
1661. 校内访问验证
   来源：[src/scenes/phone/P02_CC98/index.tsx:664](../src/scenes/phone/P02_CC98/index.tsx#L664)
1662. 正在恢复手机票务页面
   来源：[src/scenes/phone/P02_CC98/index.tsx:666](../src/scenes/phone/P02_CC98/index.tsx#L666)
1663. 正在连接校园网服务
   来源：[src/scenes/phone/P02_CC98/index.tsx:666](../src/scenes/phone/P02_CC98/index.tsx#L666)
1664. 正在检查 ZJUWLAN
   来源：[src/scenes/phone/P02_CC98/index.tsx:667](../src/scenes/phone/P02_CC98/index.tsx#L667)
1665. 这条 23 楼记录尚未满足调查门槛。
   来源：[src/scenes/phone/P02_CC98/index.tsx:720](../src/scenes/phone/P02_CC98/index.tsx#L720)
1666. CC98 帖子已保存到本机。
   来源：[src/scenes/phone/P02_CC98/index.tsx:741](../src/scenes/phone/P02_CC98/index.tsx#L741)
1667. CC98 帖子已恢复为默认内容。
   来源：[src/scenes/phone/P02_CC98/index.tsx:797](../src/scenes/phone/P02_CC98/index.tsx#L797)
1668. CC98热门话题
   来源：[src/scenes/phone/P02_CC98/index.tsx:801](../src/scenes/phone/P02_CC98/index.tsx#L801)
1669. 退出 CC98，返回手机主页
   来源：[src/scenes/phone/P02_CC98/index.tsx:806](../src/scenes/phone/P02_CC98/index.tsx#L806)
1670. 热门话题
   来源：[src/scenes/phone/P02_CC98/index.tsx:809](../src/scenes/phone/P02_CC98/index.tsx#L809)
1671. 开发者帖子维护
   来源：[src/scenes/phone/P02_CC98/index.tsx:810](../src/scenes/phone/P02_CC98/index.tsx#L810)
1672. 更多
   来源：[src/scenes/phone/P02_CC98/index.tsx:811](../src/scenes/phone/P02_CC98/index.tsx#L811)
1673. CC98更多菜单
   来源：[src/scenes/phone/P02_CC98/index.tsx:811](../src/scenes/phone/P02_CC98/index.tsx#L811)
1674. 保存帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:814](../src/scenes/phone/P02_CC98/index.tsx#L814)
1675. 编辑帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:814](../src/scenes/phone/P02_CC98/index.tsx#L814)
1676. 保存
   来源：[src/scenes/phone/P02_CC98/index.tsx:815](../src/scenes/phone/P02_CC98/index.tsx#L815)
1677. 编辑
   来源：[src/scenes/phone/P02_CC98/index.tsx:815](../src/scenes/phone/P02_CC98/index.tsx#L815)
1678. 恢复默认帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:823](../src/scenes/phone/P02_CC98/index.tsx#L823)
1679. 关闭菜单
   来源：[src/scenes/phone/P02_CC98/index.tsx:826](../src/scenes/phone/P02_CC98/index.tsx#L826)
1680. 热门话题时间筛选
   来源：[src/scenes/phone/P02_CC98/index.tsx:831](../src/scenes/phone/P02_CC98/index.tsx#L831)
1681. CC98占座调查搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:837](../src/scenes/phone/P02_CC98/index.tsx#L837)
1682. 可接收道具
   来源：[src/scenes/phone/P02_CC98/index.tsx:838](../src/scenes/phone/P02_CC98/index.tsx#L838)；[src/scenes/phone/P02_CC98/index.tsx:872](../src/scenes/phone/P02_CC98/index.tsx#L872)
1683. 资料搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:838](../src/scenes/phone/P02_CC98/index.tsx#L838)
1684. CC98 搜索内容
   来源：[src/scenes/phone/P02_CC98/index.tsx:842](../src/scenes/phone/P02_CC98/index.tsx#L842)
1685. 022 占座纸条
   来源：[src/scenes/phone/P02_CC98/index.tsx:844](../src/scenes/phone/P02_CC98/index.tsx#L844)
1686. 把占座纸条拖到这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:845](../src/scenes/phone/P02_CC98/index.tsx#L845)
1687. 搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:847](../src/scenes/phone/P02_CC98/index.tsx#L847)；[src/scenes/phone/P02_CC98/index.tsx:881](../src/scenes/phone/P02_CC98/index.tsx#L881)；[src/scenes/phone/P15_Zjuding/index.tsx:1618](../src/scenes/phone/P15_Zjuding/index.tsx#L1618)；[src/scenes/phone/P15_Zjuding/index.tsx:2026](../src/scenes/phone/P15_Zjuding/index.tsx#L2026)；[src/scenes/phone/P15_Zjuding/index.tsx:2029](../src/scenes/phone/P15_Zjuding/index.tsx#L2029)
1688. 搜索结果
   来源：[src/scenes/phone/P02_CC98/index.tsx:849](../src/scenes/phone/P02_CC98/index.tsx#L849)
1689. 拖入纸条或点击搜索后显示候选记录。
   来源：[src/scenes/phone/P02_CC98/index.tsx:861](../src/scenes/phone/P02_CC98/index.tsx#L861)
1690. 论坛会根据纸条内容建立 23 楼调查索引。
   来源：[src/scenes/phone/P02_CC98/index.tsx:865](../src/scenes/phone/P02_CC98/index.tsx#L865)
1691. 湿纸目击搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:871](../src/scenes/phone/P02_CC98/index.tsx#L871)
1692. 目击搜索
   来源：[src/scenes/phone/P02_CC98/index.tsx:872](../src/scenes/phone/P02_CC98/index.tsx#L872)
1693. 湿纸目击搜索内容
   来源：[src/scenes/phone/P02_CC98/index.tsx:876](../src/scenes/phone/P02_CC98/index.tsx#L876)
1694. 剧院门口 湿纸
   来源：[src/scenes/phone/P02_CC98/index.tsx:878](../src/scenes/phone/P02_CC98/index.tsx#L878)
1695. 把湿掉的节目单拖到这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:879](../src/scenes/phone/P02_CC98/index.tsx#L879)
1696. 先用实物特征建立目击范围。
   来源：[src/scenes/phone/P02_CC98/index.tsx:884](../src/scenes/phone/P02_CC98/index.tsx#L884)
1697. CC98版面目录
   来源：[src/scenes/phone/P02_CC98/index.tsx:890](../src/scenes/phone/P02_CC98/index.tsx#L890)
1698. 全部版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:893](../src/scenes/phone/P02_CC98/index.tsx#L893)
1699. 选择一个版面查看帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:894](../src/scenes/phone/P02_CC98/index.tsx#L894)
1700. 个
   来源：[src/scenes/phone/P02_CC98/index.tsx:896](../src/scenes/phone/P02_CC98/index.tsx#L896)；[src/scenes/phone/P02_CC98/index.tsx:946](../src/scenes/phone/P02_CC98/index.tsx#L946)
1701. ；公开快照 {{snapshot.capturedOn}}，今日贴数 {{snapshot.todayPostCount}}，总主题数 {{snapshot.totalTopicCount}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:902](../src/scenes/phone/P02_CC98/index.tsx#L902)
1702. 进入{{board}}版面，共{{postCount}}帖{{snapshotLabel}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:909](../src/scenes/phone/P02_CC98/index.tsx#L909)
1703. 帖
   来源：[src/scenes/phone/P02_CC98/index.tsx:915](../src/scenes/phone/P02_CC98/index.tsx#L915)；[src/scenes/phone/P02_CC98/index.tsx:972](../src/scenes/phone/P02_CC98/index.tsx#L972)
1704. · 今日
   来源：[src/scenes/phone/P02_CC98/index.tsx:918](../src/scenes/phone/P02_CC98/index.tsx#L918)
1705. · 总主题
   来源：[src/scenes/phone/P02_CC98/index.tsx:918](../src/scenes/phone/P02_CC98/index.tsx#L918)
1706. 公开快照 ·
   来源：[src/scenes/phone/P02_CC98/index.tsx:918](../src/scenes/phone/P02_CC98/index.tsx#L918)
1707. 关注{{board}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:926](../src/scenes/phone/P02_CC98/index.tsx#L926)
1708. 取消关注{{board}}
   来源：[src/scenes/phone/P02_CC98/index.tsx:926](../src/scenes/phone/P02_CC98/index.tsx#L926)
1709. 已关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:929](../src/scenes/phone/P02_CC98/index.tsx#L929)；[src/scenes/phone/P14_Wechat/index.tsx:574](../src/scenes/phone/P14_Wechat/index.tsx#L574)
1710. CC98我的页面
   来源：[src/scenes/phone/P02_CC98/index.tsx:937](../src/scenes/phone/P02_CC98/index.tsx#L937)
1711. 我的浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:940](../src/scenes/phone/P02_CC98/index.tsx#L940)
1712. 本次打开过的帖子会留在这里
   来源：[src/scenes/phone/P02_CC98/index.tsx:941](../src/scenes/phone/P02_CC98/index.tsx#L941)
1713. 条
   来源：[src/scenes/phone/P02_CC98/index.tsx:943](../src/scenes/phone/P02_CC98/index.tsx#L943)；[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)；[src/scenes/phone/P15_Zjuding/index.tsx:423](../src/scenes/phone/P15_Zjuding/index.tsx#L423)；[src/scenes/phone/P15_Zjuding/index.tsx:1665](../src/scenes/phone/P15_Zjuding/index.tsx#L1665)
1714. 关注版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:946](../src/scenes/phone/P02_CC98/index.tsx#L946)
1715. 浏览记录
   来源：[src/scenes/phone/P02_CC98/index.tsx:947](../src/scenes/phone/P02_CC98/index.tsx#L947)
1716. 最近浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:950](../src/scenes/phone/P02_CC98/index.tsx#L950)
1717. 还没有浏览记录。打开一篇帖子后会出现在这里。
   来源：[src/scenes/phone/P02_CC98/index.tsx:959](../src/scenes/phone/P02_CC98/index.tsx#L959)
1718. CC98帖子列表
   来源：[src/scenes/phone/P02_CC98/index.tsx:962](../src/scenes/phone/P02_CC98/index.tsx#L962)
1719. ‹ 全部版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:966](../src/scenes/phone/P02_CC98/index.tsx#L966)
1720. 关注的版面
   来源：[src/scenes/phone/P02_CC98/index.tsx:969](../src/scenes/phone/P02_CC98/index.tsx#L969)
1721. 按发布时间排列
   来源：[src/scenes/phone/P02_CC98/index.tsx:970](../src/scenes/phone/P02_CC98/index.tsx#L970)
1722. 本版面当前可见帖子
   来源：[src/scenes/phone/P02_CC98/index.tsx:970](../src/scenes/phone/P02_CC98/index.tsx#L970)
1723. 可在版面页调整关注
   来源：[src/scenes/phone/P02_CC98/index.tsx:970](../src/scenes/phone/P02_CC98/index.tsx#L970)
1724. 可导入自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:1006](../src/scenes/phone/P02_CC98/index.tsx#L1006)
1725. 已导入自习群
   来源：[src/scenes/phone/P02_CC98/index.tsx:1006](../src/scenes/phone/P02_CC98/index.tsx#L1006)
1726. 回复 ·
   来源：[src/scenes/phone/P02_CC98/index.tsx:1011](../src/scenes/phone/P02_CC98/index.tsx#L1011)
1727. 浏览
   来源：[src/scenes/phone/P02_CC98/index.tsx:1012](../src/scenes/phone/P02_CC98/index.tsx#L1012)
1728. 正文
   来源：[src/scenes/phone/P02_CC98/index.tsx:1025](../src/scenes/phone/P02_CC98/index.tsx#L1025)
1729. 这个版面暂时没有可显示的帖子。
   来源：[src/scenes/phone/P02_CC98/index.tsx:1030](../src/scenes/phone/P02_CC98/index.tsx#L1030)
1730. CC98主导航
   来源：[src/scenes/phone/P02_CC98/index.tsx:1034](../src/scenes/phone/P02_CC98/index.tsx#L1034)
1731. 提取目击关键词
   来源：[src/scenes/phone/P02_CC98/index.tsx:1093](../src/scenes/phone/P02_CC98/index.tsx#L1093)
1732. 目击信息可归纳为一个地点关键词
   来源：[src/scenes/phone/P02_CC98/index.tsx:1094](../src/scenes/phone/P02_CC98/index.tsx#L1094)
1733. 记录关键词：桥边
   来源：[src/scenes/phone/P02_CC98/index.tsx:1096](../src/scenes/phone/P02_CC98/index.tsx#L1096)
1734. 已取得：桥边
   来源：[src/scenes/phone/P02_CC98/index.tsx:1096](../src/scenes/phone/P02_CC98/index.tsx#L1096)
1735. 关闭帖子编辑
   来源：[src/scenes/phone/P02_CC98/index.tsx:1114](../src/scenes/phone/P02_CC98/index.tsx#L1114)
1736. CC98小程序
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:19](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L19)
1737. 热门
   来源：[src/scenes/phone/P02_CC98/index.tsx:196](../src/scenes/phone/P02_CC98/index.tsx#L196)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:20](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L20)
1738. 今天 08:22
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:21](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L21)
1739. 楼主
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:22](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L22)
1740. 1楼
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:23](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L23)
1741. 纸飞机维修员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:25](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L25)
1742. 增加论坛经验 755
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:26](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L26)
1743. 帖子成功把常识送进流程
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:27](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L27)
1744. 热门回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:35](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L35)
1745. 只看楼主
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:36](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L36)
1746. 今天 08:24
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:42](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L42)
1747. 先 bd 留言。问题能不能解决不确定，队形必须先完整。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:45](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L45)
1748. 今天 08:27
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:52](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L52)
1749. bd 图先补上，楼主今晚大概能收到一点抽象支援。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:55](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L55)
1750. CC98帖子：{{post.title}}
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:120](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L120)
1751. 返回热门话题
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:122](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L122)
1752. 退出帖子，返回热门话题
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:132](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L132)
1753. 退出帖子
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:133](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L133)
1754. 已锁定无法回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:142](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L142)
1755. 用户
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:164](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L164)；[src/scenes/phone/P15_Zjuding/index.tsx:1960](../src/scenes/phone/P15_Zjuding/index.tsx#L1960)
1756. 操作
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:168](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L168)
1757. 理由
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:172](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L172)
1758. ⚙ 操作
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:178](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L178)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:235](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L235)
1759. ↶ 回复
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:179](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L179)；[src/scenes/phone/P02_CC98/ThreadPage.tsx:236](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L236)
1760. 图书管理员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:197](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L197)
1761. 今天 08:55
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:198](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L198)
1762. 管理员
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:200](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L200)
1763. 24楼
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:201](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L201)
1764. 您好已收到您的问题反馈，请前往图书馆程序进行系统申诉。
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:203](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L203)
1765. 回复筛选
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:209](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L209)
1766. 匿名用户{{index + 1}}
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:221](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L221)
1767. CC98 bd 表情包
   来源：[src/scenes/phone/P02_CC98/ThreadPage.tsx:230](../src/scenes/phone/P02_CC98/ThreadPage.tsx#L230)
1768. 现在没有需要带走的水。
   来源：[src/scenes/phone/P07_Weather/index.tsx:29](../src/scenes/phone/P07_Weather/index.tsx#L29)
1769. 湖区状态已经更新。
   来源：[src/scenes/phone/P07_Weather/index.tsx:44](../src/scenes/phone/P07_Weather/index.tsx#L44)；[src/scenes/phone/P07_Weather/index.tsx:90](../src/scenes/phone/P07_Weather/index.tsx#L90)
1770. 当前没有待处理的湖区记录。
   来源：[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)
1771. 先从寝室书桌拿到吹风机。
   来源：[src/scenes/phone/P07_Weather/index.tsx:48](../src/scenes/phone/P07_Weather/index.tsx#L48)
1772. 当前无法开始校准。
   来源：[src/scenes/phone/P07_Weather/index.tsx:51](../src/scenes/phone/P07_Weather/index.tsx#L51)
1773. 这件道具无法送风 · 请拖入寝室吹风机
   来源：[src/scenes/phone/P07_Weather/index.tsx:60](../src/scenes/phone/P07_Weather/index.tsx#L60)
1774. 当前道具无法送风 · 请改用寝室吹风机
   来源：[src/scenes/phone/P07_Weather/index.tsx:74](../src/scenes/phone/P07_Weather/index.tsx#L74)
1775. 道具栏已展开 · 拖入吹风机，键盘可按空格选中
   来源：[src/scenes/phone/P07_Weather/index.tsx:78](../src/scenes/phone/P07_Weather/index.tsx#L78)
1776. 湖区状态已更新。
   来源：[src/scenes/phone/P07_Weather/index.tsx:85](../src/scenes/phone/P07_Weather/index.tsx#L85)
1777. 校准记录无效，请重新对齐。
   来源：[src/scenes/phone/P07_Weather/index.tsx:93](../src/scenes/phone/P07_Weather/index.tsx#L93)
1778. 退出天气，返回手机主页
   来源：[src/scenes/phone/P07_Weather/index.tsx:100](../src/scenes/phone/P07_Weather/index.tsx#L100)
1779. 杭州 · 紫金港
   来源：[src/scenes/phone/P07_Weather/index.tsx:101](../src/scenes/phone/P07_Weather/index.tsx#L101)
1780. °C
   来源：[src/scenes/phone/P07_Weather/index.tsx:125](../src/scenes/phone/P07_Weather/index.tsx#L125)；[src/scenes/phone/P07_Weather/index.tsx:126](../src/scenes/phone/P07_Weather/index.tsx#L126)；[src/scenes/phone/P13_PhoneHome/index.tsx:690](../src/scenes/phone/P13_PhoneHome/index.tsx#L690)
1781. 体感温度
   来源：[src/scenes/phone/P07_Weather/index.tsx:126](../src/scenes/phone/P07_Weather/index.tsx#L126)
1782. 天气详情
   来源：[src/scenes/phone/P07_Weather/index.tsx:129](../src/scenes/phone/P07_Weather/index.tsx#L129)
1783. 湿度
   来源：[src/scenes/phone/P07_Weather/index.tsx:130](../src/scenes/phone/P07_Weather/index.tsx#L130)
1784. 西南风 2级
   来源：[src/scenes/phone/P07_Weather/index.tsx:131](../src/scenes/phone/P07_Weather/index.tsx#L131)；[src/scenes/phone/P13_PhoneHome/index.tsx:698](../src/scenes/phone/P13_PhoneHome/index.tsx#L698)
1785. 降水
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1786. 已经停止
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1787. 正在发生
   来源：[src/scenes/phone/P07_Weather/index.tsx:132](../src/scenes/phone/P07_Weather/index.tsx#L132)
1788. 处理湖区云图
   来源：[src/scenes/phone/P07_Weather/index.tsx:134](../src/scenes/phone/P07_Weather/index.tsx#L134)
1789. 返回码头确认
   来源：[src/scenes/phone/P07_Weather/index.tsx:134](../src/scenes/phone/P07_Weather/index.tsx#L134)
1790. 暂不适合下水
   来源：[src/scenes/phone/P07_Weather/index.tsx:134](../src/scenes/phone/P07_Weather/index.tsx#L134)
1791. 处理黏着物
   来源：[src/scenes/phone/P07_Weather/index.tsx:135](../src/scenes/phone/P07_Weather/index.tsx#L135)
1792. 湖区状态已更新
   来源：[src/scenes/phone/P07_Weather/index.tsx:147](../src/scenes/phone/P07_Weather/index.tsx#L147)；[src/scenes/phone/P07_Weather/index.tsx:159](../src/scenes/phone/P07_Weather/index.tsx#L159)
1793. 吹风机校准接口，从道具栏拖入寝室吹风机；键盘可先选中吹风机后确认此接口
   来源：[src/scenes/phone/P07_Weather/index.tsx:149](../src/scenes/phone/P07_Weather/index.tsx#L149)
1794. 湖区记录尚未开放
   来源：[src/scenes/phone/P07_Weather/index.tsx:150](../src/scenes/phone/P07_Weather/index.tsx#L150)
1795. 接入寝室吹风机
   来源：[src/scenes/phone/P07_Weather/index.tsx:159](../src/scenes/phone/P07_Weather/index.tsx#L159)
1796. 缺少可用设备
   来源：[src/scenes/phone/P07_Weather/index.tsx:159](../src/scenes/phone/P07_Weather/index.tsx#L159)
1797. 暂无湖区记录
   来源：[src/scenes/phone/P07_Weather/index.tsx:159](../src/scenes/phone/P07_Weather/index.tsx#L159)
1798. 返回码头确认{{state.qizhenLake.weatherControlBestMoves &gt; 0 ? \` · 最少 ${state.qizhenLake.weatherControlBestMoves} 次校正\` : ""}}
   来源：[src/scenes/phone/P07_Weather/index.tsx:161](../src/scenes/phone/P07_Weather/index.tsx#L161)
1799. 从左侧道具栏拖到此接口
   来源：[src/scenes/phone/P07_Weather/index.tsx:163](../src/scenes/phone/P07_Weather/index.tsx#L163)
1800. 先检查寝室书桌
   来源：[src/scenes/phone/P07_Weather/index.tsx:163](../src/scenes/phone/P07_Weather/index.tsx#L163)
1801. 完成码头检查后再查看
   来源：[src/scenes/phone/P07_Weather/index.tsx:164](../src/scenes/phone/P07_Weather/index.tsx#L164)
1802. 收集天气水滴
   来源：[src/scenes/phone/P07_Weather/index.tsx:171](../src/scenes/phone/P07_Weather/index.tsx#L171)
1803. 天气水滴尚未开放
   来源：[src/scenes/phone/P07_Weather/index.tsx:171](../src/scenes/phone/P07_Weather/index.tsx#L171)
1804. 天气水滴已收集
   来源：[src/scenes/phone/P07_Weather/index.tsx:171](../src/scenes/phone/P07_Weather/index.tsx#L171)
1805. 还没有开始外出打卡
   来源：[src/scenes/phone/P07_Weather/index.tsx:176](../src/scenes/phone/P07_Weather/index.tsx#L176)
1806. 接住一滴水
   来源：[src/scenes/phone/P07_Weather/index.tsx:176](../src/scenes/phone/P07_Weather/index.tsx#L176)
1807. 水滴已收集
   来源：[src/scenes/phone/P07_Weather/index.tsx:176](../src/scenes/phone/P07_Weather/index.tsx#L176)
1808. 你都还没有开始外出打卡，一滴雨都不会落到你身上。
   来源：[src/scenes/phone/P07_Weather/index.tsx:177](../src/scenes/phone/P07_Weather/index.tsx#L177)
1809. 它正在道具栏里等着被使用
   来源：[src/scenes/phone/P07_Weather/index.tsx:177](../src/scenes/phone/P07_Weather/index.tsx#L177)
1810. 这滴水看起来比天气预报更有用
   来源：[src/scenes/phone/P07_Weather/index.tsx:177](../src/scenes/phone/P07_Weather/index.tsx#L177)
1811. 微信
   来源：[src/scenes/phone/P08_Settings/index.tsx:28](../src/scenes/phone/P08_Settings/index.tsx#L28)；[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)；[src/scenes/phone/P14_Wechat/index.tsx:151](../src/scenes/phone/P14_Wechat/index.tsx#L151)
1812. 浙大钉
   来源：[src/scenes/phone/P08_Settings/index.tsx:30](../src/scenes/phone/P08_Settings/index.tsx#L30)；[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)；[src/scenes/phone/P13_PhoneHome/index.tsx:834](../src/scenes/phone/P13_PhoneHome/index.tsx#L834)
1813. 设置
   来源：[src/scenes/phone/P08_Settings/index.tsx:31](../src/scenes/phone/P08_Settings/index.tsx#L31)；[src/scenes/phone/P08_Settings/index.tsx:145](../src/scenes/phone/P08_Settings/index.tsx#L145)；[src/scenes/phone/P08_Settings/index.tsx:148](../src/scenes/phone/P08_Settings/index.tsx#L148)；[src/scenes/phone/P13_PhoneHome/index.tsx:466](../src/scenes/phone/P13_PhoneHome/index.tsx#L466)
1814. 照片
   来源：[src/scenes/phone/P08_Settings/index.tsx:32](../src/scenes/phone/P08_Settings/index.tsx#L32)；[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)；[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)；[src/scenes/phone/P13_PhoneHome/index.tsx:472](../src/scenes/phone/P13_PhoneHome/index.tsx#L472)；[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:118](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L118)
1815. 记录恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:33](../src/scenes/phone/P08_Settings/index.tsx#L33)；[src/scenes/phone/P13_PhoneHome/index.tsx:479](../src/scenes/phone/P13_PhoneHome/index.tsx#L479)；[src/scenes/phone/P13_PhoneHome/index.tsx:727](../src/scenes/phone/P13_PhoneHome/index.tsx#L727)
1816. 录音
   来源：[src/scenes/phone/P08_Settings/index.tsx:34](../src/scenes/phone/P08_Settings/index.tsx#L34)；[src/scenes/phone/P13_PhoneHome/index.tsx:491](../src/scenes/phone/P13_PhoneHome/index.tsx#L491)
1817. 时钟
   来源：[src/scenes/phone/P08_Settings/index.tsx:37](../src/scenes/phone/P08_Settings/index.tsx#L37)；[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)
1818. 查看当前连接
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1819. 网
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1820. 校园网络与移动数据
   来源：[src/scenes/phone/P08_Settings/index.tsx:41](../src/scenes/phone/P08_Settings/index.tsx#L41)
1821. 背景音乐
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1822. 声
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1823. 声音与振动
   来源：[src/scenes/phone/P08_Settings/index.tsx:42](../src/scenes/phone/P08_Settings/index.tsx#L42)
1824. 亮度与可读性
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)
1825. 显
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)
1826. 显示与辅助
   来源：[src/scenes/phone/P08_Settings/index.tsx:43](../src/scenes/phone/P08_Settings/index.tsx#L43)；[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1827. 移动图标与恢复排布
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)
1828. 桌
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)
1829. 桌面与壁纸
   来源：[src/scenes/phone/P08_Settings/index.tsx:44](../src/scenes/phone/P08_Settings/index.tsx#L44)；[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1830. 恢复可选应用
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)
1831. 应
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)
1832. 应用管理
   来源：[src/scenes/phone/P08_Settings/index.tsx:45](../src/scenes/phone/P08_Settings/index.tsx#L45)；[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1833. 权
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)
1834. 相机、照片与网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)
1835. 隐私与权限
   来源：[src/scenes/phone/P08_Settings/index.tsx:46](../src/scenes/phone/P08_Settings/index.tsx#L46)；[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1836. 电
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)
1837. 电池与后台活动
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)；[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1838. 检查 07:55 记录
   来源：[src/scenes/phone/P08_Settings/index.tsx:47](../src/scenes/phone/P08_Settings/index.tsx#L47)
1839. 存档与运行状态
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)
1840. 系
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)
1841. 系统诊断与关于
   来源：[src/scenes/phone/P08_Settings/index.tsx:48](../src/scenes/phone/P08_Settings/index.tsx#L48)；[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1842. 07:48
   来源：[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)
1843. 天气卡片刷新
   来源：[src/scenes/phone/P08_Settings/index.tsx:52](../src/scenes/phone/P08_Settings/index.tsx#L52)
1844. 07:55
   来源：[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)；[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)；[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)
1845. 重新建立 IMG\_0755 索引
   来源：[src/scenes/phone/P08_Settings/index.tsx:53](../src/scenes/phone/P08_Settings/index.tsx#L53)
1846. 07:52
   来源：[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)
1847. 同步两条新消息
   来源：[src/scenes/phone/P08_Settings/index.tsx:54](../src/scenes/phone/P08_Settings/index.tsx#L54)
1848. 系统时间被后台唤醒
   来源：[src/scenes/phone/P08_Settings/index.tsx:55](../src/scenes/phone/P08_Settings/index.tsx#L55)
1849. 恢复 A2 室内定位
   来源：[src/scenes/phone/P08_Settings/index.tsx:56](../src/scenes/phone/P08_Settings/index.tsx#L56)
1850. 08:02
   来源：[src/scenes/phone/P08_Settings/index.tsx:57](../src/scenes/phone/P08_Settings/index.tsx#L57)
1851. 读取热门话题缓存
   来源：[src/scenes/phone/P08_Settings/index.tsx:57](../src/scenes/phone/P08_Settings/index.tsx#L57)
1852. {{APP\_LABELS\[appId\]}}已移动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:95](../src/scenes/phone/P08_Settings/index.tsx#L95)
1853. {{APP\_LABELS\[appId\]}}已回到桌面。
   来源：[src/scenes/phone/P08_Settings/index.tsx:100](../src/scenes/phone/P08_Settings/index.tsx#L100)
1854. 屏幕亮度
   来源：[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1855. 照片取证会读取这个亮度值。
   来源：[src/scenes/phone/P08_Settings/index.tsx:135](../src/scenes/phone/P08_Settings/index.tsx#L135)
1856. 核对旧桌面截图
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1857. 恢复默认顺序
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1858. 将{{APP\_LABELS\[appId\]}}后移
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1859. 将{{APP\_LABELS\[appId\]}}前移
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1860. 旧截图第一排
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1861. 微信 浙大钉 照片 CC98
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1862. 桌面也支持长按图标进入编辑。这里可用按钮精确调整顺序。
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1863. 桌面已恢复默认顺序。
   来源：[src/scenes/phone/P08_Settings/index.tsx:136](../src/scenes/phone/P08_Settings/index.tsx#L136)
1864. 当前阶段还没有可删除的可选应用。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1865. 当前允许从桌面移除
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1866. 恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1867. 没有从桌面移除的可选应用。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1868. 微信、照片、CC98、浙大钉、设置等剧情应用只能移动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:137](../src/scenes/phone/P08_Settings/index.tsx#L137)
1869. 保存剧情照片
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1870. 取证时使用
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1871. 相机
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1872. 校园网络
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1873. CC98 与校内服务
   来源：[src/scenes/phone/P08_Settings/index.tsx:138](../src/scenes/phone/P08_Settings/index.tsx#L138)
1874. 当前没有需要核验的剧情记录。
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1875. 核验所选记录
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1876. 记录已归档
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1877. 选出同时发生在 07:55 的三条异常活动。
   来源：[src/scenes/phone/P08_Settings/index.tsx:139](../src/scenes/phone/P08_Settings/index.tsx#L139)
1878. 存档
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1879. 个可见
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1880. 游戏时间
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1881. 桌面应用
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1882. 自动保存与上一版本恢复
   来源：[src/scenes/phone/P08_Settings/index.tsx:140](../src/scenes/phone/P08_Settings/index.tsx#L140)
1883. 返回设置
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1884. 退出设置，返回手机主页
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1885. root
   来源：[src/scenes/phone/P08_Settings/index.tsx:147](../src/scenes/phone/P08_Settings/index.tsx#L147)
1886. PHONE SYSTEM
   来源：[src/scenes/phone/P08_Settings/index.tsx:148](../src/scenes/phone/P08_Settings/index.tsx#L148)
1887. 搜索设置项
   来源：[src/scenes/phone/P08_Settings/index.tsx:151](../src/scenes/phone/P08_Settings/index.tsx#L151)
1888. 塞不进去。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:118](../src/scenes/phone/P13_PhoneHome/index.tsx#L118)
1889. 钥匙旋转 90°——咔哒。塔楼吐出\[一袋肥料\]。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:144](../src/scenes/phone/P13_PhoneHome/index.tsx#L144)
1890. 当前网络无法打开 CC98，请先恢复可访问的网络环境。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:188](../src/scenes/phone/P13_PhoneHome/index.tsx#L188)
1891. 这条推送现在只负责占位置。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:216](../src/scenes/phone/P13_PhoneHome/index.tsx#L216)
1892. 头像边缘松了一点，再点一次。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:217](../src/scenes/phone/P13_PhoneHome/index.tsx#L217)
1893. 三角形已经翘起，再点一次就能取下。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:218](../src/scenes/phone/P13_PhoneHome/index.tsx#L218)
1894. 设置图标只剩一个空位，风从里面吹过。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:225](../src/scenes/phone/P13_PhoneHome/index.tsx#L225)
1895. 这个应用参与剧情，只能移动位置。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:343](../src/scenes/phone/P13_PhoneHome/index.tsx#L343)
1896. {{appId === "tiyi" ? "浙大体艺" : "求是潮 755"}}已从桌面移除，可在设置中恢复。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:347](../src/scenes/phone/P13_PhoneHome/index.tsx#L347)
1897. 获得第 3 位：9
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:370](../src/scenes/phone/P13_PhoneHome/index.tsx#L370)
1898. 钟楼已经把秘密交出去了。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:378](../src/scenes/phone/P13_PhoneHome/index.tsx#L378)
1899. 钟楼大门紧锁。锁孔的形状有点奇怪。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:382](../src/scenes/phone/P13_PhoneHome/index.tsx#L382)
1900. 接住了一滴早八雨。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:392](../src/scenes/phone/P13_PhoneHome/index.tsx#L392)
1901. 它绝对不会开花。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:399](../src/scenes/phone/P13_PhoneHome/index.tsx#L399)
1902. 从桌面移除{{definition.label}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:601](../src/scenes/phone/P13_PhoneHome/index.tsx#L601)
1903. 像素风浙大首页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:616](../src/scenes/phone/P13_PhoneHome/index.tsx#L616)
1904. 钟楼
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:647](../src/scenes/phone/P13_PhoneHome/index.tsx#L647)
1905. 湖边盆栽
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:667](../src/scenes/phone/P13_PhoneHome/index.tsx#L667)
1906. 湖边盆栽，已开花
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:667](../src/scenes/phone/P13_PhoneHome/index.tsx#L667)
1907. 天气：{{campusWeather.label}}，{{weatherTemperature}} 摄氏度
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:675](../src/scenes/phone/P13_PhoneHome/index.tsx#L675)
1908. 打开天气
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:677](../src/scenes/phone/P13_PhoneHome/index.tsx#L677)
1909. 收集水滴
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:684](../src/scenes/phone/P13_PhoneHome/index.tsx#L684)
1910. 最高 20°C / 最低 15°C
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:694](../src/scenes/phone/P13_PhoneHome/index.tsx#L694)
1911. 空气湿度
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:697](../src/scenes/phone/P13_PhoneHome/index.tsx#L697)
1912. 拖动图标调整位置
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:704](../src/scenes/phone/P13_PhoneHome/index.tsx#L704)
1913. 完成
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:705](../src/scenes/phone/P13_PhoneHome/index.tsx#L705)；[src/scenes/rpg/RpgGameHost.tsx:2852](../src/scenes/rpg/RpgGameHost.tsx#L2852)
1914. 应用
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:708](../src/scenes/phone/P13_PhoneHome/index.tsx#L708)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)
1915. 掉落的齿轮，背面刻着 9
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:715](../src/scenes/phone/P13_PhoneHome/index.tsx#L715)
1916. 通知列表
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:721](../src/scenes/phone/P13_PhoneHome/index.tsx#L721)
1917. 第一波未抢到：当前网速过慢，第二波即将开放
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:756](../src/scenes/phone/P13_PhoneHome/index.tsx#L756)
1918. 第一波抢票成功，运气很好，钱包没那么好
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:758](../src/scenes/phone/P13_PhoneHome/index.tsx#L758)
1919. 08:32 第二波取票回执已同步
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:759](../src/scenes/phone/P13_PhoneHome/index.tsx#L759)
1920. 图书馆：您有一本书已逾期 755 天
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:773](../src/scenes/phone/P13_PhoneHome/index.tsx#L773)
1921. 您有一本书已逾期 755 天
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:775](../src/scenes/phone/P13_PhoneHome/index.tsx#L775)
1922. CC98：Re: 三楼书架是不是多了一层？
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:778](../src/scenes/phone/P13_PhoneHome/index.tsx#L778)
1923. Re: 三楼书架是不是多了一层？
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:780](../src/scenes/phone/P13_PhoneHome/index.tsx#L780)
1924. 照片：新增照片「看不清的书脊」
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:783](../src/scenes/phone/P13_PhoneHome/index.tsx#L783)
1925. 三角形已收集
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:822](../src/scenes/phone/P13_PhoneHome/index.tsx#L822)
1926. 系统方向推送
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:822](../src/scenes/phone/P13_PhoneHome/index.tsx#L822)
1927. 方向校准
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:826](../src/scenes/phone/P13_PhoneHome/index.tsx#L826)
1928. 课程提醒
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:826](../src/scenes/phone/P13_PhoneHome/index.tsx#L826)
1929. 签到记录未更新。你本人仍未抵达。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:827](../src/scenes/phone/P13_PhoneHome/index.tsx#L827)
1930. 头像方向正确，正文方向未知。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:827](../src/scenes/phone/P13_PhoneHome/index.tsx#L827)
1931. 校园地图已恢复访问，寝室入口可用。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:834](../src/scenes/phone/P13_PhoneHome/index.tsx#L834)
1932. 课堂签到仍在等待四位代码。
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:840](../src/scenes/phone/P13_PhoneHome/index.tsx#L840)
1933. 学在浙大
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:840](../src/scenes/phone/P13_PhoneHome/index.tsx#L840)；[src/scenes/phone/P15_Zjuding/index.tsx:1367](../src/scenes/phone/P15_Zjuding/index.tsx#L1367)；[src/scenes/phone/P15_Zjuding/index.tsx:1386](../src/scenes/phone/P15_Zjuding/index.tsx#L1386)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:55](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L55)
1934. 天气：{{weatherNotification}}
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:848](../src/scenes/phone/P13_PhoneHome/index.tsx#L848)；[src/scenes/phone/P13_PhoneHome/index.tsx:856](../src/scenes/phone/P13_PhoneHome/index.tsx#L856)
1935. 页面切换
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:866](../src/scenes/phone/P13_PhoneHome/index.tsx#L866)
1936. 第 1 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:867](../src/scenes/phone/P13_PhoneHome/index.tsx#L867)
1937. 第 2 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:868](../src/scenes/phone/P13_PhoneHome/index.tsx#L868)
1938. 第 3 页
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:869](../src/scenes/phone/P13_PhoneHome/index.tsx#L869)
1939. 记录恢复：检测到未同步记录
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:873](../src/scenes/phone/P13_PhoneHome/index.tsx#L873)
1940. 朋友
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:906](../src/scenes/phone/P13_PhoneHome/index.tsx#L906)；[src/scenes/phone/P14_Wechat/index.tsx:948](../src/scenes/phone/P14_Wechat/index.tsx#L948)
1941. 快快老师在点名，学在浙大
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:907](../src/scenes/phone/P13_PhoneHome/index.tsx#L907)
1942. 这是签到码：XX……
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:908](../src/scenes/phone/P13_PhoneHome/index.tsx#L908)
1943. 现在
   来源：[src/scenes/phone/P13_PhoneHome/index.tsx:910](../src/scenes/phone/P13_PhoneHome/index.tsx#L910)
1944. 照片 IMG\_0755.JPG
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:115](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L115)
1945. 关闭照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:117](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L117)
1946. 022书包拍摄界面
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:123](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L123)
1947. 保持画面居中
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:124](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L124)
1948. 对准 022 书包
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:124](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L124)
1949. 还没有在 022 现场确认书包。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:130](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L130)
1950. 目标已对准，点击快门。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:130](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L130)
1951. 拍摄 022 书包
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:131](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L131)
1952. 反光的书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:142](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L142)
1953. 可读的书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:142](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L142)
1954. 书包标签
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:159](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L159)
1955. 高数教材 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:160](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L160)
1956. 水杯 x1 充电器 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:161](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L161)
1957. 半包纸 x1
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:162](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L162)
1958. 姓名：未检测到
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:163](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L163)
1959. 学号：未检测到
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:164](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L164)
1960. 人格：加载失败
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:165](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L165)
1961. 标签反光，无法识别
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:169](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L169)
1962. 控制中心亮度
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:185](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L185)
1963. 照片直接读取系统亮度
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:187](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L187)
1964. 还没有拍到 022 上的书包。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:191](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L191)
1965. 识别稳定，标签内容已锁定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:193](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L193)
1966. 标签边缘已出现，识别信号仍不稳定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:195](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L195)
1967. 光照太亮了，识别器无法对焦。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:196](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L196)
1968. 旧相册里还有一张同场景照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:203](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L203)
1969. 找到同一只 022 书包的旧照，核对半包纸出现的时间。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:204](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L204)
1970. 查看 022 旧照
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:210](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L210)
1971. 已写入报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:210](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L210)
1972. 照片筛选
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:217](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L217)
1973. 最近 {{LIBRARY\_ROLL\_PHOTOS.length}} 张
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:220](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L220)
1974. 校园与日常
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:221](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L221)
1975. 校园与日常照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1976. 最近照片
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1977. campus\_life
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:229](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L229)
1978. 预览 {{photo.title}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:235](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L235)
1979. 6 张校园与日常照片。它们只用于补足相册内容，不参与证据判定。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:250](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L250)
1980. {{LIBRARY\_ROLL\_PHOTOS.length}} 张最近照片。点开可以查看细节。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:251](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L251)
1981. {{selectedRollPhoto.file}} · {{selectedRollPhoto.location}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:258](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L258)
1982. {{selectedRollPhoto.title}}，{{selectedRollPhoto.detail}}
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:263](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L263)
1983. 旧照与刚拍下的标签内容一致。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:267](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L267)
1984. 先把刚拍下的主照片亮度降到 20% 以下。
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:267](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L267)
1985. 已写入物品报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:269](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L269)
1986. 用旧照补全物品报告
   来源：[src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx:269](../src/scenes/phone/P13_PhoneHome/PhotoEvidenceOverlay.tsx#L269)
1987. 东边入口已经封了，别再往那边走。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:32](../src/scenes/phone/P14_Wechat/index.tsx#L32)
1988. 周琪
   来源：[src/scenes/phone/P14_Wechat/index.tsx:32](../src/scenes/phone/P14_Wechat/index.tsx#L32)
1989. 室友
   来源：[src/scenes/phone/P14_Wechat/index.tsx:33](../src/scenes/phone/P14_Wechat/index.tsx#L33)
1990. 我在西侧看见保洁推车，大厅主入口应该还能进。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:33](../src/scenes/phone/P14_Wechat/index.tsx#L33)
1991. 陈嘉
   来源：[src/scenes/phone/P14_Wechat/index.tsx:34](../src/scenes/phone/P14_Wechat/index.tsx#L34)
1992. 陈嘉撤回了一条消息
   来源：[src/scenes/phone/P14_Wechat/index.tsx:34](../src/scenes/phone/P14_Wechat/index.tsx#L34)
1993. 公众号 · 22:40
   来源：[src/scenes/phone/P14_Wechat/index.tsx:79](../src/scenes/phone/P14_Wechat/index.tsx#L79)
1994. 紫金港楼宇服务
   来源：[src/scenes/phone/P14_Wechat/index.tsx:79](../src/scenes/phone/P14_Wechat/index.tsx#L79)；[src/scenes/phone/P14_Wechat/index.tsx:157](../src/scenes/phone/P14_Wechat/index.tsx#L157)
1995. 校园楼宇运行通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:84](../src/scenes/phone/P14_Wechat/index.tsx#L84)
1996. 夜间闭楼与入口调整
   来源：[src/scenes/phone/P14_Wechat/index.tsx:85](../src/scenes/phone/P14_Wechat/index.tsx#L85)
1997. 22:45 起，
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1998. 北教学区一处楼宇
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
1999. 段永平教学楼
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
2000. 进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:87](../src/scenes/phone/P14_Wechat/index.tsx#L87)
2001. 主电梯保留运行，楼层开放情况以现场提示为准。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:88](../src/scenes/phone/P14_Wechat/index.tsx#L88)
2002. 保存通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:90](../src/scenes/phone/P14_Wechat/index.tsx#L90)
2003. 通知已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:90](../src/scenes/phone/P14_Wechat/index.tsx#L90)
2004. 麦斯威夜间自习群
   来源：[src/scenes/phone/P14_Wechat/index.tsx:101](../src/scenes/phone/P14_Wechat/index.tsx#L101)；[src/scenes/phone/P14_Wechat/index.tsx:104](../src/scenes/phone/P14_Wechat/index.tsx#L104)；[src/scenes/phone/P14_Wechat/index.tsx:163](../src/scenes/phone/P14_Wechat/index.tsx#L163)
2005. 返回微信消息列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:103](../src/scenes/phone/P14_Wechat/index.tsx#L103)
2006. 群聊 · 18人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:104](../src/scenes/phone/P14_Wechat/index.tsx#L104)
2007. 选中两条能够同时确认“哪边关闭”和“哪边可进入”的消息。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:109](../src/scenes/phone/P14_Wechat/index.tsx#L109)
2008. 选择
   来源：[src/scenes/phone/P14_Wechat/index.tsx:123](../src/scenes/phone/P14_Wechat/index.tsx#L123)
2009. 已选
   来源：[src/scenes/phone/P14_Wechat/index.tsx:123](../src/scenes/phone/P14_Wechat/index.tsx#L123)
2010. 22:42 入口调整截图 · 东侧关闭 / 西侧主入口可通行
   来源：[src/scenes/phone/P14_Wechat/index.tsx:130](../src/scenes/phone/P14_Wechat/index.tsx#L130)
2011. 保存路线截图
   来源：[src/scenes/phone/P14_Wechat/index.tsx:139](../src/scenes/phone/P14_Wechat/index.tsx#L139)
2012. 截图已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:139](../src/scenes/phone/P14_Wechat/index.tsx#L139)
2013. 微信恢复证据
   来源：[src/scenes/phone/P14_Wechat/index.tsx:148](../src/scenes/phone/P14_Wechat/index.tsx#L148)
2014. 退出微信，返回手机主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:150](../src/scenes/phone/P14_Wechat/index.tsx#L150)
2015. 消息
   来源：[src/scenes/phone/P14_Wechat/index.tsx:151](../src/scenes/phone/P14_Wechat/index.tsx#L151)；[src/scenes/phone/P15_Zjuding/index.tsx:141](../src/scenes/phone/P15_Zjuding/index.tsx#L141)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:79](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L79)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:87](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L87)
2016. 楼
   来源：[src/scenes/phone/P14_Wechat/index.tsx:156](../src/scenes/phone/P14_Wechat/index.tsx#L156)
2017. 有一条未归档的运行通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:157](../src/scenes/phone/P14_Wechat/index.tsx#L157)
2018. 已存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:159](../src/scenes/phone/P14_Wechat/index.tsx#L159)；[src/scenes/phone/P14_Wechat/index.tsx:165](../src/scenes/phone/P14_Wechat/index.tsx#L165)
2019. 有两条消息可组成路线截图
   来源：[src/scenes/phone/P14_Wechat/index.tsx:163](../src/scenes/phone/P14_Wechat/index.tsx#L163)
2020. 返回记录恢复
   来源：[src/scenes/phone/P14_Wechat/index.tsx:168](../src/scenes/phone/P14_Wechat/index.tsx#L168)；[src/scenes/phone/P15_Zjuding/index.tsx:451](../src/scenes/phone/P15_Zjuding/index.tsx#L451)
2021. 任务更新：找回四位签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:236](../src/scenes/phone/P14_Wechat/index.tsx#L236)
2022. 咔——斜线断了一截，挂在头像框上晃悠。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:331](../src/scenes/phone/P14_Wechat/index.tsx#L331)
2023. 导师头像现在不接受附件。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:349](../src/scenes/phone/P14_Wechat/index.tsx#L349)
2024. 卡扣反而更紧了。它需要能渗进胶缝的东西。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:355](../src/scenes/phone/P14_Wechat/index.tsx#L355)
2025. 竖线滑落了。获得道具：竖线
   来源：[src/scenes/phone/P14_Wechat/index.tsx:363](../src/scenes/phone/P14_Wechat/index.tsx#L363)
2026. 或许可以再斜一点
   来源：[src/scenes/phone/P14_Wechat/index.tsx:387](../src/scenes/phone/P14_Wechat/index.tsx#L387)
2027. 它也想转转罢
   来源：[src/scenes/phone/P14_Wechat/index.tsx:389](../src/scenes/phone/P14_Wechat/index.tsx#L389)
2028. 斜线晃了晃，还没掉。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:391](../src/scenes/phone/P14_Wechat/index.tsx#L391)
2029. 头像上的斜线纹丝不动。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:392](../src/scenes/phone/P14_Wechat/index.tsx#L392)
2030. 检测到未经授权的友情支援。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:403](../src/scenes/phone/P14_Wechat/index.tsx#L403)
2031. 你戳了戳剩下的一端……
   来源：[src/scenes/phone/P14_Wechat/index.tsx:406](../src/scenes/phone/P14_Wechat/index.tsx#L406)
2032. 导师的消息，还是等签完到再回吧。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:414](../src/scenes/phone/P14_Wechat/index.tsx#L414)
2033. 头像中间留下了一道很干净的空隙。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:419](../src/scenes/phone/P14_Wechat/index.tsx#L419)
2034. 这条竖线被透明胶和两枚卡扣封在头像框里。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:423](../src/scenes/phone/P14_Wechat/index.tsx#L423)
2035. 这条聊天还不能作为地点记录。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:506](../src/scenes/phone/P14_Wechat/index.tsx#L506)
2036. 已从聊天中保存地点词：湖面。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:509](../src/scenes/phone/P14_Wechat/index.tsx#L509)
2037. 已保存通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:541](../src/scenes/phone/P14_Wechat/index.tsx#L541)
2038. · 校园日常记录
   来源：[src/scenes/phone/P14_Wechat/index.tsx:557](../src/scenes/phone/P14_Wechat/index.tsx#L557)
2039. 阅读
   来源：[src/scenes/phone/P14_Wechat/index.tsx:557](../src/scenes/phone/P14_Wechat/index.tsx#L557)
2040. {{chapterFourWechatContent.official.name}}公众号主页
   来源：[src/scenes/phone/P14_Wechat/index.tsx:567](../src/scenes/phone/P14_Wechat/index.tsx#L567)
2041. 后勤
   来源：[src/scenes/phone/P14_Wechat/index.tsx:569](../src/scenes/phone/P14_Wechat/index.tsx#L569)；[src/scenes/phone/P14_Wechat/index.tsx:788](../src/scenes/phone/P14_Wechat/index.tsx#L788)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2042. 夜间通知 ·
   来源：[src/scenes/phone/P14_Wechat/index.tsx:584](../src/scenes/phone/P14_Wechat/index.tsx#L584)
2043. 已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:588](../src/scenes/phone/P14_Wechat/index.tsx#L588)
2044. 主线通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:588](../src/scenes/phone/P14_Wechat/index.tsx#L588)
2045. 往期推文
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)；[src/scenes/phone/P14_Wechat/index.tsx:593](../src/scenes/phone/P14_Wechat/index.tsx#L593)；[src/scenes/phone/P14_Wechat/index.tsx:625](../src/scenes/phone/P14_Wechat/index.tsx#L625)
2046. 校园日常
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)；[src/scenes/phone/P14_Wechat/index.tsx:593](../src/scenes/phone/P14_Wechat/index.tsx#L593)；[src/scenes/phone/P14_Wechat/index.tsx:620](../src/scenes/phone/P14_Wechat/index.tsx#L620)
2047. daily
   来源：[src/scenes/phone/P14_Wechat/index.tsx:591](../src/scenes/phone/P14_Wechat/index.tsx#L591)
2048. 篇
   来源：[src/scenes/phone/P14_Wechat/index.tsx:594](../src/scenes/phone/P14_Wechat/index.tsx#L594)
2049. 公众号自定义菜单
   来源：[src/scenes/phone/P14_Wechat/index.tsx:614](../src/scenes/phone/P14_Wechat/index.tsx#L614)
2050. 夜间通知
   来源：[src/scenes/phone/P14_Wechat/index.tsx:615](../src/scenes/phone/P14_Wechat/index.tsx#L615)
2051. 档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:665](../src/scenes/phone/P14_Wechat/index.tsx#L665)
2052. 学习天地资料索引
   来源：[src/scenes/phone/P14_Wechat/index.tsx:667](../src/scenes/phone/P14_Wechat/index.tsx#L667)
2053. 群文件 ›
   来源：[src/scenes/phone/P14_Wechat/index.tsx:670](../src/scenes/phone/P14_Wechat/index.tsx#L670)
2054. 林昊
   来源：[src/scenes/phone/P14_Wechat/index.tsx:682](../src/scenes/phone/P14_Wechat/index.tsx#L682)
2055. 保存录音
   来源：[src/scenes/phone/P14_Wechat/index.tsx:705](../src/scenes/phone/P14_Wechat/index.tsx#L705)
2056. 已归档
   来源：[src/scenes/phone/P14_Wechat/index.tsx:705](../src/scenes/phone/P14_Wechat/index.tsx#L705)
2057. 待现场核验
   来源：[src/scenes/phone/P14_Wechat/index.tsx:709](../src/scenes/phone/P14_Wechat/index.tsx#L709)
2058. 群聊截图 · 2F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:709](../src/scenes/phone/P14_Wechat/index.tsx#L709)
2059. 现场照片 · 3F
   来源：[src/scenes/phone/P14_Wechat/index.tsx:713](../src/scenes/phone/P14_Wechat/index.tsx#L713)
2060. 等你从 CC98 导入资料索引
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
2061. 路线讨论已保存
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
2062. 学习天地资料已加入群文件
   来源：[src/scenes/phone/P14_Wechat/index.tsx:782](../src/scenes/phone/P14_Wechat/index.tsx#L782)
2063. 文件传输助手：只有你给自己发的表情包。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:801](../src/scenes/phone/P14_Wechat/index.tsx#L801)
2064. 文件传输助手
   来源：[src/scenes/phone/P14_Wechat/index.tsx:805](../src/scenes/phone/P14_Wechat/index.tsx#L805)
2065. \[图片\]
   来源：[src/scenes/phone/P14_Wechat/index.tsx:806](../src/scenes/phone/P14_Wechat/index.tsx#L806)
2066. 已保存 {{chapterFourWechat.archiveCount}} 项现场资料
   来源：[src/scenes/phone/P14_Wechat/index.tsx:806](../src/scenes/phone/P14_Wechat/index.tsx#L806)
2067. 打开朋友聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:816](../src/scenes/phone/P14_Wechat/index.tsx#L816)
2068. 朋友头像
   来源：[src/scenes/phone/P14_Wechat/index.tsx:822](../src/scenes/phone/P14_Wechat/index.tsx#L822)
2069. 导师：实验报告仍然不会自己完成。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:876](../src/scenes/phone/P14_Wechat/index.tsx#L876)
2070. 导师头像上的竖线
   来源：[src/scenes/phone/P14_Wechat/index.tsx:882](../src/scenes/phone/P14_Wechat/index.tsx#L882)
2071. 导师
   来源：[src/scenes/phone/P14_Wechat/index.tsx:904](../src/scenes/phone/P14_Wechat/index.tsx#L904)
2072. 头像胶缝里似乎缺一点能流动的东西。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:908](../src/scenes/phone/P14_Wechat/index.tsx#L908)
2073. 两枚卡扣在发亮，中间的竖线还是拔不动。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:910](../src/scenes/phone/P14_Wechat/index.tsx#L910)
2074. 头像框中间多了一条被封住的竖线。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:911](../src/scenes/phone/P14_Wechat/index.tsx#L911)
2075. 请把实验报告的初稿发我一下。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:912](../src/scenes/phone/P14_Wechat/index.tsx#L912)
2076. 聊天
   来源：[src/scenes/phone/P14_Wechat/index.tsx:923](../src/scenes/phone/P14_Wechat/index.tsx#L923)
2077. 联系人
   来源：[src/scenes/phone/P14_Wechat/index.tsx:927](../src/scenes/phone/P14_Wechat/index.tsx#L927)
2078. 探索
   来源：[src/scenes/phone/P14_Wechat/index.tsx:931](../src/scenes/phone/P14_Wechat/index.tsx#L931)
2079. 我的
   来源：[src/scenes/phone/P14_Wechat/index.tsx:935](../src/scenes/phone/P14_Wechat/index.tsx#L935)；[src/scenes/phone/P15_Zjuding/index.tsx:142](../src/scenes/phone/P15_Zjuding/index.tsx#L142)；[src/scenes/phone/P15_Zjuding/index.tsx:147](../src/scenes/phone/P15_Zjuding/index.tsx#L147)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:80](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L80)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:88](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L88)
2080. 返回聊天列表
   来源：[src/scenes/phone/P14_Wechat/index.tsx:946](../src/scenes/phone/P14_Wechat/index.tsx#L946)
2081. 快快老师在点名，学在浙大。
   来源：[src/scenes/phone/P14_Wechat/index.tsx:959](../src/scenes/phone/P14_Wechat/index.tsx#L959)
2082. 这是签到码
   来源：[src/scenes/phone/P14_Wechat/index.tsx:967](../src/scenes/phone/P14_Wechat/index.tsx#L967)
2083. 等等等等，你想翘课？没门！
   来源：[src/scenes/phone/P14_Wechat/index.tsx:987](../src/scenes/phone/P14_Wechat/index.tsx#L987)
2084. 我不会让你签上的！
   来源：[src/scenes/phone/P14_Wechat/index.tsx:988](../src/scenes/phone/P14_Wechat/index.tsx#L988)
2085. 跳过小影语音
   来源：[src/scenes/phone/P14_Wechat/index.tsx:999](../src/scenes/phone/P14_Wechat/index.tsx#L999)
2086. 成功了吗
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1007](../src/scenes/phone/P14_Wechat/index.tsx#L1007)
2087. wx-msg wx-qizhen-message {{line.startsWith("自动回复：") ? "is-self" : ""}}
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1037](../src/scenes/phone/P14_Wechat/index.tsx#L1037)
2088. 自动回复：
   来源：[src/scenes/phone/P14_Wechat/index.tsx:1038](../src/scenes/phone/P14_Wechat/index.tsx#L1038)
2089. 身份信息未读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:62](../src/scenes/phone/P15_Zjuding/index.tsx#L62)
2090. 拜托了，帮我改一下签到记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:72](../src/scenes/phone/P15_Zjuding/index.tsx#L72)；[src/scenes/phone/P15_Zjuding/index.tsx:79](../src/scenes/phone/P15_Zjuding/index.tsx#L79)
2091. player
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:72](../src/scenes/phone/P15_Zjuding/index.tsx#L72)；[src/scenes/phone/P15_Zjuding/index.tsx:79](../src/scenes/phone/P15_Zjuding/index.tsx#L79)；[src/scenes/phone/P15_Zjuding/index.tsx:85](../src/scenes/phone/P15_Zjuding/index.tsx#L85)
2092. 先把校园卡收好。寝室里的人还需要找到移动方法。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:81](../src/scenes/phone/P15_Zjuding/index.tsx#L81)
2093. 别打扰我……哦，你已经完事了，速度还挺快的
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:92](../src/scenes/phone/P15_Zjuding/index.tsx#L92)
2094. 我以为你要在寝室“就再睡一会儿”呢
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:93](../src/scenes/phone/P15_Zjuding/index.tsx#L93)
2095. 你知道的，去图书馆要先完成座位预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:94](../src/scenes/phone/P15_Zjuding/index.tsx#L94)
2096. 基础馆二楼南区022，记住了。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:95](../src/scenes/phone/P15_Zjuding/index.tsx#L95)
2097. 馆藏检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:127](../src/scenes/phone/P15_Zjuding/index.tsx#L127)；[src/scenes/phone/P15_Zjuding/index.tsx:1506](../src/scenes/phone/P15_Zjuding/index.tsx#L1506)；[src/scenes/phone/P15_Zjuding/index.tsx:1507](../src/scenes/phone/P15_Zjuding/index.tsx#L1507)；[src/scenes/phone/P15_Zjuding/index.tsx:1510](../src/scenes/phone/P15_Zjuding/index.tsx#L1510)；[src/scenes/phone/P15_Zjuding/index.tsx:1511](../src/scenes/phone/P15_Zjuding/index.tsx#L1511)
2098. 借阅信息
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:128](../src/scenes/phone/P15_Zjuding/index.tsx#L128)
2099. 阅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:128](../src/scenes/phone/P15_Zjuding/index.tsx#L128)
2100. 座位预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:129](../src/scenes/phone/P15_Zjuding/index.tsx#L129)；[src/scenes/phone/P15_Zjuding/index.tsx:1514](../src/scenes/phone/P15_Zjuding/index.tsx#L1514)
2101. 空间预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:130](../src/scenes/phone/P15_Zjuding/index.tsx#L130)
2102. 荐
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:131](../src/scenes/phone/P15_Zjuding/index.tsx#L131)
2103. 求是荐书
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:131](../src/scenes/phone/P15_Zjuding/index.tsx#L131)
2104. 新书通报
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:132](../src/scenes/phone/P15_Zjuding/index.tsx#L132)
2105. 查收查引
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:133](../src/scenes/phone/P15_Zjuding/index.tsx#L133)
2106. 引
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:133](../src/scenes/phone/P15_Zjuding/index.tsx#L133)
2107. 图书馆缴费
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:134](../src/scenes/phone/P15_Zjuding/index.tsx#L134)
2108. 失物招领 · 前台工作人员
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:197](../src/scenes/phone/P15_Zjuding/index.tsx#L197)
2109. 二层南区 · 022 桌面夹缝
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:203](../src/scenes/phone/P15_Zjuding/index.tsx#L203)
2110. 浙大体艺 · 到馆记录补录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:209](../src/scenes/phone/P15_Zjuding/index.tsx#L209)
2111. 二层
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:214](../src/scenes/phone/P15_Zjuding/index.tsx#L214)；[src/scenes/phone/P15_Zjuding/index.tsx:215](../src/scenes/phone/P15_Zjuding/index.tsx#L215)
2112. 二层南
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:214](../src/scenes/phone/P15_Zjuding/index.tsx#L214)；[src/scenes/phone/P15_Zjuding/index.tsx:553](../src/scenes/phone/P15_Zjuding/index.tsx#L553)
2113. 二层北
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:215](../src/scenes/phone/P15_Zjuding/index.tsx#L215)
2114. 三层
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:216](../src/scenes/phone/P15_Zjuding/index.tsx#L216)；[src/scenes/phone/P15_Zjuding/index.tsx:217](../src/scenes/phone/P15_Zjuding/index.tsx#L217)
2115. 三层东
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:216](../src/scenes/phone/P15_Zjuding/index.tsx#L216)
2116. 三层南
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:217](../src/scenes/phone/P15_Zjuding/index.tsx#L217)
2117. 返回，离开{{title}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:247](../src/scenes/phone/P15_Zjuding/index.tsx#L247)
2118. {{title}}更多菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:249](../src/scenes/phone/P15_Zjuding/index.tsx#L249)
2119. 页面导航
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:269](../src/scenes/phone/P15_Zjuding/index.tsx#L269)；[src/scenes/phone/P15_Zjuding/index.tsx:1583](../src/scenes/phone/P15_Zjuding/index.tsx#L1583)
2120. 22:44:31
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:343](../src/scenes/phone/P15_Zjuding/index.tsx#L343)
2121. 剧场前厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:345](../src/scenes/phone/P15_Zjuding/index.tsx#L345)
2122. 18 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:346](../src/scenes/phone/P15_Zjuding/index.tsx#L346)
2123. 已认证设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:347](../src/scenes/phone/P15_Zjuding/index.tsx#L347)；[src/scenes/phone/P15_Zjuding/index.tsx:413](../src/scenes/phone/P15_Zjuding/index.tsx#L413)
2124. 22:43:11
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:354](../src/scenes/phone/P15_Zjuding/index.tsx#L354)
2125. 基础图书馆南侧
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:356](../src/scenes/phone/P15_Zjuding/index.tsx#L356)
2126. 3 秒
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:357](../src/scenes/phone/P15_Zjuding/index.tsx#L357)；[src/scenes/phone/P15_Zjuding/index.tsx:368](../src/scenes/phone/P15_Zjuding/index.tsx#L368)
2127. 未知设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:358](../src/scenes/phone/P15_Zjuding/index.tsx#L358)；[src/scenes/phone/P15_Zjuding/index.tsx:369](../src/scenes/phone/P15_Zjuding/index.tsx#L369)
2128. 22:44:12
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:365](../src/scenes/phone/P15_Zjuding/index.tsx#L365)
2129. 启真湖小码头
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:367](../src/scenes/phone/P15_Zjuding/index.tsx#L367)
2130. 网络记录筛选
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:402](../src/scenes/phone/P15_Zjuding/index.tsx#L402)
2131. 缺失时段末段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:406](../src/scenes/phone/P15_Zjuding/index.tsx#L406)
2132. 最后 1 分钟
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:407](../src/scenes/phone/P15_Zjuding/index.tsx#L407)
2133. 会话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:410](../src/scenes/phone/P15_Zjuding/index.tsx#L410)
2134. 未知设备 · 短会话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:412](../src/scenes/phone/P15_Zjuding/index.tsx#L412)
2135. 全校
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:417](../src/scenes/phone/P15_Zjuding/index.tsx#L417)
2136. 北教学区 A 区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:418](../src/scenes/phone/P15_Zjuding/index.tsx#L418)
2137. 其他楼宇
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:419](../src/scenes/phone/P15_Zjuding/index.tsx#L419)
2138. 接入记录结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:422](../src/scenes/phone/P15_Zjuding/index.tsx#L422)
2139. 查询结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:423](../src/scenes/phone/P15_Zjuding/index.tsx#L423)
2140. 接入点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:428](../src/scenes/phone/P15_Zjuding/index.tsx#L428)
2141. 位置
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:429](../src/scenes/phone/P15_Zjuding/index.tsx#L429)
2142. 设备
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:430](../src/scenes/phone/P15_Zjuding/index.tsx#L430)
2143. 记录已保存
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:437](../src/scenes/phone/P15_Zjuding/index.tsx#L437)
2144. 保存这条记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:438](../src/scenes/phone/P15_Zjuding/index.tsx#L438)
2145. 可从任意维度开始筛选，也可直接保存候选记录。系统不会替你判定候选，最终冲突由证据矩阵统一核验。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:443](../src/scenes/phone/P15_Zjuding/index.tsx#L443)
2146. 记录核验结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:445](../src/scenes/phone/P15_Zjuding/index.tsx#L445)
2147. 林星宇
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:446](../src/scenes/phone/P15_Zjuding/index.tsx#L446)
2148. 这不是我的手机。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:446](../src/scenes/phone/P15_Zjuding/index.tsx#L446)
2149. 北教学区 A 区的一处大厅
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
2150. 段永平教学楼一楼
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
2151. 留下了三秒会话。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
2152. 设备名也不是你的。它借用了你的校园身份，在
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:447](../src/scenes/phone/P15_Zjuding/index.tsx#L447)
2153. 可选座位地图
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:473](../src/scenes/phone/P15_Zjuding/index.tsx#L473)
2154. 选择座位{{leftSeat}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:489](../src/scenes/phone/P15_Zjuding/index.tsx#L489)
2155. 选择座位{{rightSeat}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:500](../src/scenes/phone/P15_Zjuding/index.tsx#L500)
2156. 北向
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:517](../src/scenes/phone/P15_Zjuding/index.tsx#L517)
2157. 请选择馆舍
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:552](../src/scenes/phone/P15_Zjuding/index.tsx#L552)
2158. 07月10日 · 今天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:554](../src/scenes/phone/P15_Zjuding/index.tsx#L554)；[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2159. 全部座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:557](../src/scenes/phone/P15_Zjuding/index.tsx#L557)；[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2160. 请连接校园网后重新进入浙大钉。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:621](../src/scenes/phone/P15_Zjuding/index.tsx#L621)
2161. reservation
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:630](../src/scenes/phone/P15_Zjuding/index.tsx#L630)
2162. 读卡器没有读到有效证件。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:636](../src/scenes/phone/P15_Zjuding/index.tsx#L636)
2163. 证件信息已读入。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:655](../src/scenes/phone/P15_Zjuding/index.tsx#L655)
2164. 读卡区只认校园身份凭证。这件道具没有姓名和学号。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:666](../src/scenes/phone/P15_Zjuding/index.tsx#L666)
2165. 馆藏检索没有识别这件道具中的页码特征。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:698](../src/scenes/phone/P15_Zjuding/index.tsx#L698)
2166. 节目单的潮湿页码已送入馆藏状态检索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:706](../src/scenes/phone/P15_Zjuding/index.tsx#L706)
2167. 这个槽位需要对应名称的恢复证明。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:722](../src/scenes/phone/P15_Zjuding/index.tsx#L722)
2168. 退出浙大钉
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:764](../src/scenes/phone/P15_Zjuding/index.tsx#L764)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
2169. 个人资料
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:768](../src/scenes/phone/P15_Zjuding/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
2170. 账号与安全
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:768](../src/scenes/phone/P15_Zjuding/index.tsx#L768)；[src/scenes/phone/P15_Zjuding/index.tsx:1957](../src/scenes/phone/P15_Zjuding/index.tsx#L1957)
2171. 收藏号码
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:772](../src/scenes/phone/P15_Zjuding/index.tsx#L772)；[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
2172. 最近通话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:772](../src/scenes/phone/P15_Zjuding/index.tsx#L772)；[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
2173. 我的预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:776](../src/scenes/phone/P15_Zjuding/index.tsx#L776)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
2174. 当前没有已确认的图书馆预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:780](../src/scenes/phone/P15_Zjuding/index.tsx#L780)
2175. 刷新空位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:784](../src/scenes/phone/P15_Zjuding/index.tsx#L784)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
2176. 刷新座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:784](../src/scenes/phone/P15_Zjuding/index.tsx#L784)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
2177. 已重新读取本机座位状态：{{selectedRoom}}空闲 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.available ?? 0}} 席。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:785](../src/scenes/phone/P15_Zjuding/index.tsx#L785)
2178. 预约规则
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:788](../src/scenes/phone/P15_Zjuding/index.tsx#L788)；[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
2179. 预约页只接受当前剧情已开放的馆舍、区域和座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:789](../src/scenes/phone/P15_Zjuding/index.tsx#L789)
2180. 取消预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:792](../src/scenes/phone/P15_Zjuding/index.tsx#L792)；[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
2181. 已确认预约保持不变。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:793](../src/scenes/phone/P15_Zjuding/index.tsx#L793)
2182. 找回账号
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:796](../src/scenes/phone/P15_Zjuding/index.tsx#L796)；[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
2183. 请通过电子校园卡重新读取身份。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:797](../src/scenes/phone/P15_Zjuding/index.tsx#L797)
2184. 安全提示
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:800](../src/scenes/phone/P15_Zjuding/index.tsx#L800)；[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
2185. 账号信息由电子校园卡状态读取。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:801](../src/scenes/phone/P15_Zjuding/index.tsx#L801)
2186. 当前状态已显示。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:804](../src/scenes/phone/P15_Zjuding/index.tsx#L804)
2187. 它看了看你的空手，又缩回了红圈里。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:923](../src/scenes/phone/P15_Zjuding/index.tsx#L923)
2188. 求是印章没有回应。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:927](../src/scenes/phone/P15_Zjuding/index.tsx#L927)
2189. 任务更新：找到道具栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:948](../src/scenes/phone/P15_Zjuding/index.tsx#L948)
2190. 任务更新：找到移动的办法
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:952](../src/scenes/phone/P15_Zjuding/index.tsx#L952)
2191. 任务更新：让地图人物回应你
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:955](../src/scenes/phone/P15_Zjuding/index.tsx#L955)
2192. 本章的 022 状态由图书馆现场记录管理。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1015](../src/scenes/phone/P15_Zjuding/index.tsx#L1015)
2193. 座位 {{state.ui.librarySelectedSeat ?? "022"}} 已预约，不能在当前任务中改签。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1019](../src/scenes/phone/P15_Zjuding/index.tsx#L1019)
2194. 请先选择一个白色座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1028](../src/scenes/phone/P15_Zjuding/index.tsx#L1028)
2195. 座位 {{state.ui.librarySelectedSeat}} 已预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1032](../src/scenes/phone/P15_Zjuding/index.tsx#L1032)
2196. 预约来源不匹配：请选择基础馆。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1044](../src/scenes/phone/P15_Zjuding/index.tsx#L1044)
2197. 预约区域不匹配：请选择二层南区。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1045](../src/scenes/phone/P15_Zjuding/index.tsx#L1045)
2198. 座位凭据不匹配：目标座位为 022。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1046](../src/scenes/phone/P15_Zjuding/index.tsx#L1046)
2199. 系统还没有开放本次座位预约。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1047](../src/scenes/phone/P15_Zjuding/index.tsx#L1047)
2200. 预约成功：基础馆二层南区 022。任务更新：前往基础图书馆 022
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1054](../src/scenes/phone/P15_Zjuding/index.tsx#L1054)
2201. 请输入书名、作者或索书号。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1063](../src/scenes/phone/P15_Zjuding/index.tsx#L1063)
2202. 检索完成：发现 1 条异常外借记录。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1075](../src/scenes/phone/P15_Zjuding/index.tsx#L1075)
2203. 没有找到与“{{query}}”相符的馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1083](../src/scenes/phone/P15_Zjuding/index.tsx#L1083)
2204. 检索完成：找到 {{results.length}} 本馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1087](../src/scenes/phone/P15_Zjuding/index.tsx#L1087)
2205. 检索完成：找到 {{results.length}} 本相似馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1093](../src/scenes/phone/P15_Zjuding/index.tsx#L1093)
2206. 当前无法保存这条异常定位信息。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1098](../src/scenes/phone/P15_Zjuding/index.tsx#L1098)
2207. {{qizhenContent.locationSearch.catalog.player}} / {{qizhenContent.locationSearch.catalog.system}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1101](../src/scenes/phone/P15_Zjuding/index.tsx#L1101)
2208. 地图没有从这件道具中读到地点关键词。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1107](../src/scenes/phone/P15_Zjuding/index.tsx#L1107)
2209. 当前没有需要合并的地点线索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1111](../src/scenes/phone/P15_Zjuding/index.tsx#L1111)
2210. 这条记录已经参与检索。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1115](../src/scenes/phone/P15_Zjuding/index.tsx#L1115)
2211. 三条记录还没有全部对齐。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1130](../src/scenes/phone/P15_Zjuding/index.tsx#L1130)
2212. 启真湖入口还没有在大地图上开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1138](../src/scenes/phone/P15_Zjuding/index.tsx#L1138)
2213. 已获得线索：索书号 {{result.callNumber}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1145](../src/scenes/phone/P15_Zjuding/index.tsx#L1145)；[src/scenes/phone/P15_Zjuding/index.tsx:1158](../src/scenes/phone/P15_Zjuding/index.tsx#L1158)
2214. {{result.title}}的索书号和 022 没有可核对的关系。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1153](../src/scenes/phone/P15_Zjuding/index.tsx#L1153)
2215. 十大排名还没有被图书馆系统同步。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1164](../src/scenes/phone/P15_Zjuding/index.tsx#L1164)
2216. 恢复申请只在帖子进入十大第一后开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1168](../src/scenes/phone/P15_Zjuding/index.tsx#L1168)
2217. 该证明还未获得、已提交，或当前申请尚未开放。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1177](../src/scenes/phone/P15_Zjuding/index.tsx#L1177)
2218. 三项恢复材料尚未齐全。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1191](../src/scenes/phone/P15_Zjuding/index.tsx#L1191)
2219. 浙大钉加载中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1204](../src/scenes/phone/P15_Zjuding/index.tsx#L1204)
2220. 请连接校园网后重新进入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1215](../src/scenes/phone/P15_Zjuding/index.tsx#L1215)
2221. 统一身份认证
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1258](../src/scenes/phone/P15_Zjuding/index.tsx#L1258)
2222. 登录帮助
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1260](../src/scenes/phone/P15_Zjuding/index.tsx#L1260)
2223. 校园身份信息
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1264](../src/scenes/phone/P15_Zjuding/index.tsx#L1264)
2224. 旧登录入口已合并到电子校园卡。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1265](../src/scenes/phone/P15_Zjuding/index.tsx#L1265)
2225. 前往部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1276](../src/scenes/phone/P15_Zjuding/index.tsx#L1276)
2226. 浙大钉部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1284](../src/scenes/phone/P15_Zjuding/index.tsx#L1284)
2227. 部门黄页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1286](../src/scenes/phone/P15_Zjuding/index.tsx#L1286)；[src/scenes/phone/P15_Zjuding/index.tsx:2013](../src/scenes/phone/P15_Zjuding/index.tsx#L2013)；[src/scenes/phone/P15_Zjuding/index.tsx:2017](../src/scenes/phone/P15_Zjuding/index.tsx#L2017)；[src/scenes/phone/P15_Zjuding/index.tsx:2018](../src/scenes/phone/P15_Zjuding/index.tsx#L2018)
2228. 黄页菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1288](../src/scenes/phone/P15_Zjuding/index.tsx#L1288)
2229. 部门联系人
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1291](../src/scenes/phone/P15_Zjuding/index.tsx#L1291)
2230. 联络寝室人物
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1299](../src/scenes/phone/P15_Zjuding/index.tsx#L1299)
2231. 校园卡读卡区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1305](../src/scenes/phone/P15_Zjuding/index.tsx#L1305)
2232. 电子校园卡已读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1316](../src/scenes/phone/P15_Zjuding/index.tsx#L1316)
2233. 校园身份读卡区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1316](../src/scenes/phone/P15_Zjuding/index.tsx#L1316)
2234. 正在识别持卡人字段……
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1319](../src/scenes/phone/P15_Zjuding/index.tsx#L1319)
2235. 姓名与 10 位学号已填入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1321](../src/scenes/phone/P15_Zjuding/index.tsx#L1321)
2236. 校园卡已对准，点击读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1323](../src/scenes/phone/P15_Zjuding/index.tsx#L1323)
2237. 点击查看提示，或将身份凭证放入此处
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1324](../src/scenes/phone/P15_Zjuding/index.tsx#L1324)
2238. 联络未命名人物
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1331](../src/scenes/phone/P15_Zjuding/index.tsx#L1331)
2239. 请输入校园卡上的完整身份
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1331](../src/scenes/phone/P15_Zjuding/index.tsx#L1331)
2240. 校园卡姓名
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1341](../src/scenes/phone/P15_Zjuding/index.tsx#L1341)
2241. 10 位学号
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1354](../src/scenes/phone/P15_Zjuding/index.tsx#L1354)
2242. ☎ 呼叫
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1359](../src/scenes/phone/P15_Zjuding/index.tsx#L1359)
2243. 已联络：{{actOneContent.studentName}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1359](../src/scenes/phone/P15_Zjuding/index.tsx#L1359)
2244. 校务签到
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1375](../src/scenes/phone/P15_Zjuding/index.tsx#L1375)
2245. 返回浙大钉
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1382](../src/scenes/phone/P15_Zjuding/index.tsx#L1382)
2246. 学在浙大导航
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1383](../src/scenes/phone/P15_Zjuding/index.tsx#L1383)
2247. 当前位于学在浙大。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1384](../src/scenes/phone/P15_Zjuding/index.tsx#L1384)
2248. 方向靠近桥
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
2249. CC98 目击帖
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1402](../src/scenes/phone/P15_Zjuding/index.tsx#L1402)
2250. 馆藏异常记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
2251. 页码只出现在倒影中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1403](../src/scenes/phone/P15_Zjuding/index.tsx#L1403)
2252. 湖面
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2253. 湖面出现逆风水纹
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2254. 微信聊天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1404](../src/scenes/phone/P15_Zjuding/index.tsx#L1404)
2255. 三条记录来自不同应用。先取得地点词，再在这里逐条接入。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1417](../src/scenes/phone/P15_Zjuding/index.tsx#L1417)
2256. 校园地图地点检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1419](../src/scenes/phone/P15_Zjuding/index.tsx#L1419)
2257. 保留原始来源，核对三条地点记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1424](../src/scenes/phone/P15_Zjuding/index.tsx#L1424)
2258. 交叉检索台
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1424](../src/scenes/phone/P15_Zjuding/index.tsx#L1424)
2259. 三源地点记录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1429](../src/scenes/phone/P15_Zjuding/index.tsx#L1429)
2260. 已接入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1432](../src/scenes/phone/P15_Zjuding/index.tsx#L1432)；[src/scenes/phone/P15_Zjuding/index.tsx:1450](../src/scenes/phone/P15_Zjuding/index.tsx#L1450)
2261. 待核对
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2262. 入口已标记
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2263. 收集中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1433](../src/scenes/phone/P15_Zjuding/index.tsx#L1433)
2264. 提取词：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1447](../src/scenes/phone/P15_Zjuding/index.tsx#L1447)
2265. 导入
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1452](../src/scenes/phone/P15_Zjuding/index.tsx#L1452)
2266. 导入{{clue.source}}的地点词{{clue.label}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1452](../src/scenes/phone/P15_Zjuding/index.tsx#L1452)
2267. 未取得
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1454](../src/scenes/phone/P15_Zjuding/index.tsx#L1454)
2268. 核对地点交点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1461](../src/scenes/phone/P15_Zjuding/index.tsx#L1461)
2269. 前往大地图上的启真湖入口
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1476](../src/scenes/phone/P15_Zjuding/index.tsx#L1476)
2270. 浙大移动图书馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1484](../src/scenes/phone/P15_Zjuding/index.tsx#L1484)；[src/scenes/phone/P15_Zjuding/index.tsx:1486](../src/scenes/phone/P15_Zjuding/index.tsx#L1486)；[src/scenes/phone/P15_Zjuding/index.tsx:1597](../src/scenes/phone/P15_Zjuding/index.tsx#L1597)
2271. 未读取身份的读者头像
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1491](../src/scenes/phone/P15_Zjuding/index.tsx#L1491)
2272. 校园卡持卡人读者头像
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1491](../src/scenes/phone/P15_Zjuding/index.tsx#L1491)
2273. 022恢复申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1530](../src/scenes/phone/P15_Zjuding/index.tsx#L1530)；[src/scenes/phone/P15_Zjuding/index.tsx:1531](../src/scenes/phone/P15_Zjuding/index.tsx#L1531)；[src/scenes/phone/P15_Zjuding/index.tsx:1534](../src/scenes/phone/P15_Zjuding/index.tsx#L1534)；[src/scenes/phone/P15_Zjuding/index.tsx:1536](../src/scenes/phone/P15_Zjuding/index.tsx#L1536)
2274. 返回现场
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1540](../src/scenes/phone/P15_Zjuding/index.tsx#L1540)；[src/scenes/phone/P15_Zjuding/index.tsx:1541](../src/scenes/phone/P15_Zjuding/index.tsx#L1541)；[src/scenes/phone/P15_Zjuding/index.tsx:1544](../src/scenes/phone/P15_Zjuding/index.tsx#L1544)；[src/scenes/phone/P15_Zjuding/index.tsx:1545](../src/scenes/phone/P15_Zjuding/index.tsx#L1545)；[src/scenes/phone/P15_Zjuding/index.tsx:1887](../src/scenes/phone/P15_Zjuding/index.tsx#L1887)
2275. 022 座位恢复申请已开放
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1552](../src/scenes/phone/P15_Zjuding/index.tsx#L1552)
2276. 帖子当前排名 01，可提交三项证明。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1553](../src/scenes/phone/P15_Zjuding/index.tsx#L1553)
2277. 活动日历
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1560](../src/scenes/phone/P15_Zjuding/index.tsx#L1560)
2278. （活动报名）“我著·我...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1562](../src/scenes/phone/P15_Zjuding/index.tsx#L1562)
2279. （活动报名）书香浙大·开...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1562](../src/scenes/phone/P15_Zjuding/index.tsx#L1562)
2280. 通知公告
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1565](../src/scenes/phone/P15_Zjuding/index.tsx#L1565)
2281. 关于新增校外数据库访...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1567](../src/scenes/phone/P15_Zjuding/index.tsx#L1567)
2282. 图书馆数字资源校外访...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1567](../src/scenes/phone/P15_Zjuding/index.tsx#L1567)
2283. 规章制度
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1570](../src/scenes/phone/P15_Zjuding/index.tsx#L1570)
2284. 读者文明使用空间须知
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)
2285. 图书馆座位预约管理规则
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)
2286. 图书馆馆藏检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1595](../src/scenes/phone/P15_Zjuding/index.tsx#L1595)
2287. 文献库选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1601](../src/scenes/phone/P15_Zjuding/index.tsx#L1601)
2288. 当前正在使用中文文献库。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1602](../src/scenes/phone/P15_Zjuding/index.tsx#L1602)
2289. 中文文献库
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1602](../src/scenes/phone/P15_Zjuding/index.tsx#L1602)
2290. 检索条件
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1606](../src/scenes/phone/P15_Zjuding/index.tsx#L1606)
2291. 搜索文献
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1614](../src/scenes/phone/P15_Zjuding/index.tsx#L1614)
2292. 馆藏检索关键词
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1615](../src/scenes/phone/P15_Zjuding/index.tsx#L1615)
2293. 检索范围
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1620](../src/scenes/phone/P15_Zjuding/index.tsx#L1620)
2294. 当前检索字段固定为书名，高级检索可查看其他条件。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
2295. 检索字段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1621](../src/scenes/phone/P15_Zjuding/index.tsx#L1621)
2296. 当前馆藏范围为全部馆藏。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2297. 馆藏范围
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2298. 全部馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1622](../src/scenes/phone/P15_Zjuding/index.tsx#L1622)
2299. 高级检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1628](../src/scenes/phone/P15_Zjuding/index.tsx#L1628)
2300. 收起高级检索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1628](../src/scenes/phone/P15_Zjuding/index.tsx#L1628)
2301. 检索到的书籍数：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1630](../src/scenes/phone/P15_Zjuding/index.tsx#L1630)
2302. 高级检索字段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1633](../src/scenes/phone/P15_Zjuding/index.tsx#L1633)
2303. 包含全部关键词
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1634](../src/scenes/phone/P15_Zjuding/index.tsx#L1634)
2304. 题名匹配
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1634](../src/scenes/phone/P15_Zjuding/index.tsx#L1634)
2305. 全部分类
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1635](../src/scenes/phone/P15_Zjuding/index.tsx#L1635)
2306. 索书号分类
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1635](../src/scenes/phone/P15_Zjuding/index.tsx#L1635)
2307. 馆藏地点
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1636](../src/scenes/phone/P15_Zjuding/index.tsx#L1636)
2308. 基础图书馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1636](../src/scenes/phone/P15_Zjuding/index.tsx#L1636)；[src/scenes/rpg/ZijingangCampusLayout.ts:100](../src/scenes/rpg/ZijingangCampusLayout.ts#L100)
2309. 异常外借状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1643](../src/scenes/phone/P15_Zjuding/index.tsx#L1643)
2310. 签到记录夹页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1644](../src/scenes/phone/P15_Zjuding/index.tsx#L1644)
2311. 异常外借
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1644](../src/scenes/phone/P15_Zjuding/index.tsx#L1644)
2312. 记录关键词：倒影
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1651](../src/scenes/phone/P15_Zjuding/index.tsx#L1651)
2313. 已取得：倒影
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1651](../src/scenes/phone/P15_Zjuding/index.tsx#L1651)
2314. 馆藏检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1663](../src/scenes/phone/P15_Zjuding/index.tsx#L1663)
2315. 检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1665](../src/scenes/phone/P15_Zjuding/index.tsx#L1665)
2316. 选择馆藏{{result.title}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1671](../src/scenes/phone/P15_Zjuding/index.tsx#L1671)
2317. {{result.title}}封面
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1672](../src/scenes/phone/P15_Zjuding/index.tsx#L1672)
2318. 著者：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1675](../src/scenes/phone/P15_Zjuding/index.tsx#L1675)
2319. 索书号：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1676](../src/scenes/phone/P15_Zjuding/index.tsx#L1676)
2320. 无检索结果
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1687](../src/scenes/phone/P15_Zjuding/index.tsx#L1687)
2321. 没有匹配馆藏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1688](../src/scenes/phone/P15_Zjuding/index.tsx#L1688)
2322. 可尝试书名、作者或索书号中的连续文字。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1689](../src/scenes/phone/P15_Zjuding/index.tsx#L1689)
2323. 新书推荐
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1692](../src/scenes/phone/P15_Zjuding/index.tsx#L1692)；[src/scenes/phone/P15_Zjuding/index.tsx:1693](../src/scenes/phone/P15_Zjuding/index.tsx#L1693)
2324. 输入题名后，相似书籍会同时列出。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1694](../src/scenes/phone/P15_Zjuding/index.tsx#L1694)
2325. 022座位恢复申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1704](../src/scenes/phone/P15_Zjuding/index.tsx#L1704)；[src/scenes/phone/P15_Zjuding/index.tsx:1706](../src/scenes/phone/P15_Zjuding/index.tsx#L1706)
2326. 基础馆 · 二楼南区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1713](../src/scenes/phone/P15_Zjuding/index.tsx#L1713)
2327. CC98 公示排名：01
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1714](../src/scenes/phone/P15_Zjuding/index.tsx#L1714)
2328. 恢复材料进度 {{submitted.length}}/3
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1718](../src/scenes/phone/P15_Zjuding/index.tsx#L1718)
2329. 旧版规则 · 恢复条件
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1722](../src/scenes/phone/P15_Zjuding/index.tsx#L1722)
2330. CC98 公示已生效。三份材料分别确认占用物身份、座位编号与本人到馆记录。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1723](../src/scenes/phone/P15_Zjuding/index.tsx#L1723)
2331. 恢复证明槽位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1725](../src/scenes/phone/P15_Zjuding/index.tsx#L1725)
2332. 待取得
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2333. 可提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2334. 已核验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1729](../src/scenes/phone/P15_Zjuding/index.tsx#L1729)
2335. 来源：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1745](../src/scenes/phone/P15_Zjuding/index.tsx#L1745)
2336. 材料已锁定到本次申请
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1746](../src/scenes/phone/P15_Zjuding/index.tsx#L1746)
2337. 道具栏已识别，可提交校验
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1746](../src/scenes/phone/P15_Zjuding/index.tsx#L1746)
2338. 提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1753](../src/scenes/phone/P15_Zjuding/index.tsx#L1753)
2339. 座位释放PASS已签发
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1761](../src/scenes/phone/P15_Zjuding/index.tsx#L1761)
2340. PASS 已签发
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1763](../src/scenes/phone/P15_Zjuding/index.tsx#L1763)；[src/scenes/phone/P15_Zjuding/index.tsx:1854](../src/scenes/phone/P15_Zjuding/index.tsx#L1854)
2341. 凭证只对 RPG 图书馆内的 022 书包生效。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1764](../src/scenes/phone/P15_Zjuding/index.tsx#L1764)
2342. 回图书馆处理书包
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1765](../src/scenes/phone/P15_Zjuding/index.tsx#L1765)
2343. 生成 022 座位释放 PASS
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1769](../src/scenes/phone/P15_Zjuding/index.tsx#L1769)
2344. 图书馆空间列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1777](../src/scenes/phone/P15_Zjuding/index.tsx#L1777)
2345. 图书馆空间预约...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1779](../src/scenes/phone/P15_Zjuding/index.tsx#L1779)；[src/scenes/phone/P15_Zjuding/index.tsx:1863](../src/scenes/phone/P15_Zjuding/index.tsx#L1863)
2346. 空间预约菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1781](../src/scenes/phone/P15_Zjuding/index.tsx#L1781)
2347. 收起座位预约栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1785](../src/scenes/phone/P15_Zjuding/index.tsx#L1785)
2348. 展开座位预约栏
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1785](../src/scenes/phone/P15_Zjuding/index.tsx#L1785)
2349. 预
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2350. 约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2351. 座
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1787](../src/scenes/phone/P15_Zjuding/index.tsx#L1787)
2352. 空间选择模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1791](../src/scenes/phone/P15_Zjuding/index.tsx#L1791)
2353. 列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1792](../src/scenes/phone/P15_Zjuding/index.tsx#L1792)
2354. 快速选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1793](../src/scenes/phone/P15_Zjuding/index.tsx#L1793)
2355. 空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1796](../src/scenes/phone/P15_Zjuding/index.tsx#L1796)
2356. 显示
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1796](../src/scenes/phone/P15_Zjuding/index.tsx#L1796)
2357. 可预约空间列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1802](../src/scenes/phone/P15_Zjuding/index.tsx#L1802)
2358. {{room.label}}自习空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1806](../src/scenes/phone/P15_Zjuding/index.tsx#L1806)
2359. 主馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1807](../src/scenes/phone/P15_Zjuding/index.tsx#L1807)；[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2360. 空闲
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1811](../src/scenes/phone/P15_Zjuding/index.tsx#L1811)；[src/scenes/phone/P15_Zjuding/index.tsx:1822](../src/scenes/phone/P15_Zjuding/index.tsx#L1822)
2361. 预约{{room.label}}
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1812](../src/scenes/phone/P15_Zjuding/index.tsx#L1812)
2362. 快速选择空间
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1818](../src/scenes/phone/P15_Zjuding/index.tsx#L1818)
2363. 我的中心
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1830](../src/scenes/phone/P15_Zjuding/index.tsx#L1830)
2364. 当前位于空间预约列表。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1832](../src/scenes/phone/P15_Zjuding/index.tsx#L1832)
2365. 座位已恢复
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1850](../src/scenes/phone/P15_Zjuding/index.tsx#L1850)
2366. 清退已执行
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1852](../src/scenes/phone/P15_Zjuding/index.tsx#L1852)
2367. 恢复申请待提交
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1856](../src/scenes/phone/P15_Zjuding/index.tsx#L1856)
2368. 公示审核中
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1858](../src/scenes/phone/P15_Zjuding/index.tsx#L1858)
2369. 占用异常
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1859](../src/scenes/phone/P15_Zjuding/index.tsx#L1859)
2370. 图书馆座位选择
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1861](../src/scenes/phone/P15_Zjuding/index.tsx#L1861)
2371. 选座菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1865](../src/scenes/phone/P15_Zjuding/index.tsx#L1865)
2372. 主馆 · 二层 ·
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1870](../src/scenes/phone/P15_Zjuding/index.tsx#L1870)
2373. 查看平面图 ›
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1872](../src/scenes/phone/P15_Zjuding/index.tsx#L1872)
2374. 已切换到下方平面图。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1872](../src/scenes/phone/P15_Zjuding/index.tsx#L1872)
2375. {{selectedRoom}}：座位 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.seats ?? 0}}，当前空闲 {{ROOMS.find((room) =&gt; room.label === selectedRoom)?.available ?? 0}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1873](../src/scenes/phone/P15_Zjuding/index.tsx#L1873)
2376. 查看房间详情 ›
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1873](../src/scenes/phone/P15_Zjuding/index.tsx#L1873)
2377. 当前空余 32 个座位。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1876](../src/scenes/phone/P15_Zjuding/index.tsx#L1876)
2378. 空余 32
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1876](../src/scenes/phone/P15_Zjuding/index.tsx#L1876)
2379. 022调查状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1880](../src/scenes/phone/P15_Zjuding/index.tsx#L1880)
2380. 当前现场状态
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1883](../src/scenes/phone/P15_Zjuding/index.tsx#L1883)
2381. 书包仍在现场，手机页面只负责查询与提交材料。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1885](../src/scenes/phone/P15_Zjuding/index.tsx#L1885)
2382. 现场已清空，座位等待本人确认。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1885](../src/scenes/phone/P15_Zjuding/index.tsx#L1885)
2383. 预约日期与时段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1890](../src/scenes/phone/P15_Zjuding/index.tsx#L1890)
2384. 座位显示模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1903](../src/scenes/phone/P15_Zjuding/index.tsx#L1903)
2385. 地图模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1904](../src/scenes/phone/P15_Zjuding/index.tsx#L1904)
2386. 列表模式
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1905](../src/scenes/phone/P15_Zjuding/index.tsx#L1905)
2387. 筛选：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1909](../src/scenes/phone/P15_Zjuding/index.tsx#L1909)
2388. 已选：
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1909](../src/scenes/phone/P15_Zjuding/index.tsx#L1909)
2389. 筛选
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1910](../src/scenes/phone/P15_Zjuding/index.tsx#L1910)
2390. 可选座位列表
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1923](../src/scenes/phone/P15_Zjuding/index.tsx#L1923)
2391. 手机端保留调查记录；书包、小票与 PASS 操作均在图书馆现场完成。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1933](../src/scenes/phone/P15_Zjuding/index.tsx#L1933)
2392. 返回
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1937](../src/scenes/phone/P15_Zjuding/index.tsx#L1937)
2393. 立即预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1939](../src/scenes/phone/P15_Zjuding/index.tsx#L1939)
2394. 预约成功
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1939](../src/scenes/phone/P15_Zjuding/index.tsx#L1939)
2395. 浙大钉首页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1946](../src/scenes/phone/P15_Zjuding/index.tsx#L1946)
2396. 打开个人菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1952](../src/scenes/phone/P15_Zjuding/index.tsx#L1952)
2397. 个人菜单
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1956](../src/scenes/phone/P15_Zjuding/index.tsx#L1956)
2398. 浙江大学
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1963](../src/scenes/phone/P15_Zjuding/index.tsx#L1963)
2399. 打开浙大百事通搜索
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1966](../src/scenes/phone/P15_Zjuding/index.tsx#L1966)
2400. 百事通
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1967](../src/scenes/phone/P15_Zjuding/index.tsx#L1967)；[src/scenes/phone/P15_Zjuding/index.tsx:1970](../src/scenes/phone/P15_Zjuding/index.tsx#L1970)
2401. 系统红圈
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1983](../src/scenes/phone/P15_Zjuding/index.tsx#L1983)
2402. 求
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1986](../src/scenes/phone/P15_Zjuding/index.tsx#L1986)；[src/scenes/phone/P15_Zjuding/index.tsx:1989](../src/scenes/phone/P15_Zjuding/index.tsx#L1989)；[src/scenes/phone/P15_Zjuding/index.tsx:2092](../src/scenes/phone/P15_Zjuding/index.tsx#L2092)
2403. /求是学院（归口...
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1993](../src/scenes/phone/P15_Zjuding/index.tsx#L1993)
2404. 身份码
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1998](../src/scenes/phone/P15_Zjuding/index.tsx#L1998)；[src/scenes/phone/P15_Zjuding/index.tsx:1999](../src/scenes/phone/P15_Zjuding/index.tsx#L1999)
2405. 校园钱包
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2008](../src/scenes/phone/P15_Zjuding/index.tsx#L2008)；[src/scenes/phone/P15_Zjuding/index.tsx:2009](../src/scenes/phone/P15_Zjuding/index.tsx#L2009)
2406. 搜索浙大钉应用与服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2025](../src/scenes/phone/P15_Zjuding/index.tsx#L2025)
2407. 搜索应用与服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2026](../src/scenes/phone/P15_Zjuding/index.tsx#L2026)
2408. 浙大百事通
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2029](../src/scenes/phone/P15_Zjuding/index.tsx#L2029)；[src/scenes/phone/P15_Zjuding/index.tsx:2104](../src/scenes/phone/P15_Zjuding/index.tsx#L2104)
2409. 浙大钉应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2032](../src/scenes/phone/P15_Zjuding/index.tsx#L2032)
2410. 系统对话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2091](../src/scenes/phone/P15_Zjuding/index.tsx#L2091)
2411. 继续对话
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2099](../src/scenes/phone/P15_Zjuding/index.tsx#L2099)
2412. 搜索应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2106](../src/scenes/phone/P15_Zjuding/index.tsx#L2106)
2413. 输入应用名称
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2112](../src/scenes/phone/P15_Zjuding/index.tsx#L2112)
2414. 没有匹配的应用
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2132](../src/scenes/phone/P15_Zjuding/index.tsx#L2132)
2415. 选择馆舍
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2153](../src/scenes/phone/P15_Zjuding/index.tsx#L2153)
2416. 农医馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2417. 紫金港西区馆
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2155](../src/scenes/phone/P15_Zjuding/index.tsx#L2155)
2418. 已选择{{library}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2162](../src/scenes/phone/P15_Zjuding/index.tsx#L2162)
2419. 预约日期
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2172](../src/scenes/phone/P15_Zjuding/index.tsx#L2172)
2420. 07月11日 · 明天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2421. 07月12日 · 后天
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2174](../src/scenes/phone/P15_Zjuding/index.tsx#L2174)
2422. 预约时段
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2183](../src/scenes/phone/P15_Zjuding/index.tsx#L2183)
2423. 筛选座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2194](../src/scenes/phone/P15_Zjuding/index.tsx#L2194)
2424. 安静区
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2425. 靠窗
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2426. 有电源
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2196](../src/scenes/phone/P15_Zjuding/index.tsx#L2196)
2427. 当前座位筛选已切换为：{{filter}}。
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2197](../src/scenes/phone/P15_Zjuding/index.tsx#L2197)
2428. 确认预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2205](../src/scenes/phone/P15_Zjuding/index.tsx#L2205)；[src/scenes/phone/P15_Zjuding/index.tsx:2216](../src/scenes/phone/P15_Zjuding/index.tsx#L2216)
2429. 号座位
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2207](../src/scenes/phone/P15_Zjuding/index.tsx#L2207)
2430. 再想一下
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:2213](../src/scenes/phone/P15_Zjuding/index.tsx#L2213)
2431. 学
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:56](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L56)
2432. 课程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2433. 签到
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)
2434. 学习
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:59](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L59)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:482](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L482)
2435. 智云课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:65](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L65)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:70](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L70)
2436. 云
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:66](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L66)
2437. 课件
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2438. 课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2439. 日程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:69](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L69)
2440. 校园地图
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1420](../src/scenes/phone/P15_Zjuding/index.tsx#L1420)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:75](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L75)
2441. 导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
2442. 地图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:79](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L79)
2443. 网络缴费
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:85](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L85)
2444. 连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
2445. 校园网
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2446. 账户
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:89](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L89)
2447. 后勤服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:95](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L95)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:72](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L72)
2448. 勤
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:96](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L96)
2449. 报修
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2450. 服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:484](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L484)
2451. 网络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:99](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L99)
2452. 寻
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:106](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L106)
2453. 档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2454. 失物
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2455. 书包
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2456. 证明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:109](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L109)
2457. 访客预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:115](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L115)
2458. 访
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:116](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L116)
2459. 草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2460. 访客
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2461. 入校
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)
2462. 预约
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1812](../src/scenes/phone/P15_Zjuding/index.tsx#L1812)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:119](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L119)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2463. 图
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:126](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L126)
2464. 馆藏
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2465. 图书
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:129](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L129)
2466. 慧学外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:135](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L135)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:75](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L75)
2467. 词汇
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2468. 卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2469. 外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2470. 英语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:139](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L139)
2471. 开发反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:145](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L145)
2472. 信
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:146](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L146)
2473. 反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2474. 开发者
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2475. 意见
   来源：[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:149](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L149)
2476. 新
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:132](../src/scenes/phone/P15_Zjuding/index.tsx#L132)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:152](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L152)
2477. 全部
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:405](../src/scenes/phone/P15_Zjuding/index.tsx#L405)；[src/scenes/phone/P15_Zjuding/index.tsx:411](../src/scenes/phone/P15_Zjuding/index.tsx#L411)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:156](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L156)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)
2478. 工作台
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:140](../src/scenes/phone/P15_Zjuding/index.tsx#L140)；[src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts:160](../src/scenes/phone/P15_Zjuding/ZjudingAppRegistry.ts#L160)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:86](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L86)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:491](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L491)
2479. 校园参观
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:61](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L61)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2480. 功能建议
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:65](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L65)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2481. 网络账户
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:71](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L71)
2482. 访客预约预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:74](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L74)
2483. 开发者反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:76](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L76)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:472](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L472)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2484. 全部应用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:77](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L77)
2485. 通讯录
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:139](../src/scenes/phone/P15_Zjuding/index.tsx#L139)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:78](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L78)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:85](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L85)
2486. 首页
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:138](../src/scenes/phone/P15_Zjuding/index.tsx#L138)；[src/scenes/phone/P15_Zjuding/index.tsx:146](../src/scenes/phone/P15_Zjuding/index.tsx#L146)；[src/scenes/phone/P15_Zjuding/index.tsx:1830](../src/scenes/phone/P15_Zjuding/index.tsx#L1830)；[src/scenes/phone/P15_Zjuding/index.tsx:1831](../src/scenes/phone/P15_Zjuding/index.tsx#L1831)；[src/scenes/phone/P15_Zjuding/index.tsx:1832](../src/scenes/phone/P15_Zjuding/index.tsx#L1832)；[src/scenes/phone/P15_Zjuding/index.tsx:2057](../src/scenes/phone/P15_Zjuding/index.tsx#L2057)；[src/scenes/phone/P15_Zjuding/index.tsx:2059](../src/scenes/phone/P15_Zjuding/index.tsx#L2059)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:84](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L84)
2487. 北教学区 A-204
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2488. 化学工程基础
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2489. 课程资料已缓存在本机。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2490. 周一 08:00
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:92](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L92)
2491. 数据方法与 AI4S
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2492. 线上课堂
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2493. 周三 13:15
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2494. 最近一次课件仅供预览。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:93](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L93)
2495. 安全提醒已读取，不产生签到记录。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2496. 东教学区 3-106
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2497. 实验室安全
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2498. 周五 10:00
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:94](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L94)
2499. 导向；路径识别
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:98](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L98)
2500. 倒影；反射
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:99](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L99)
2501. 维修；保养
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:100](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L100)
2502. 书包物品识别报告
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:104](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L104)
2503. 照片·本机识别
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:104](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L104)
2504. 图书馆前台
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:105](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L105)
2505. 基础馆二层南区
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:106](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L106)
2506. 本人到馆证明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:107](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L107)
2507. 浙大体艺·到馆记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:107](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L107)
2508. 游戏反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:112](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L112)
2509. ## 反馈内容 / {{content}} / ## 游戏 / 7:55
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:115](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L115)
2510. ## 反馈内容 / 请描述问题、复现步骤或建议。 / ## 游戏 / 7:55
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:116](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L116)
2511. 校园网已连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:208](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L208)
2512. 当前使用移动数据
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:210](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L210)
2513. 当前处于离线状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:211](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L211)
2514. 校园网状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:223](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L223)
2515. 校园身份已读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:230](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L230)
2516. {{studentName}}·{{studentId}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:231](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L231)
2517. 查看校园卡
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:232](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L232)
2518. 图书馆座位预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:239](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L239)
2519. 已预约 {{state.ui.librarySelectedSeat ?? "022"}} 号座位
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:240](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L240)
2520. 查看图书馆
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:241](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L241)
2521. 图书馆服务已开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:247](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L247)
2522. 当前可用功能以图书馆首页实际状态为准。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:248](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L248)
2523. 打开图书馆
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:249](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L249)
2524. 请先填写意见内容。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:310](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L310)
2525. 反馈草稿已保存。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:315](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L315)
2526. 反馈内容已保留在当前页面。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:316](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L316)
2527. 反馈内容已清空。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:322](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L322)
2528. 本机课程预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:341](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L341)
2529. 门课程
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:342](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L342)
2530. 查看课程日程和缓存说明，不产生签到或成绩记录。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:343](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L343)
2531. 课程列表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:345](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L345)
2532. 查看
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1572](../src/scenes/phone/P15_Zjuding/index.tsx#L1572)；[src/scenes/phone/P15_Zjuding/index.tsx:1753](../src/scenes/phone/P15_Zjuding/index.tsx#L1753)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:352](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L352)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:390](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L390)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:410](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L410)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2533. 当前连接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:365](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L365)
2534. 页面只读取本机网络状态，不扣费、不充值、不生成账单。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:367](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L367)
2535. 可用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2536. 浙大钉与 CC98 需要校园网。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:370](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L370)
2537. 备用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
2538. 浙大体艺的网络规则与浙大钉不同。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:371](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L371)
2539. 查看连接说明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:374](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L374)
2540. 收起连接说明
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:374](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L374)
2541. 如需切换网络，请返回手机控制中心。本页不会自动修改网络模式。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:377](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L377)
2542. 校园服务聚合
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:385](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L385)
2543. 后勤状态台
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:386](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L386)
2544. 所有条目只读取已开放的本地功能，未提交任何报修工单。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:387](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L387)
2545. 网络服务
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:390](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L390)
2546. 当前阶段未开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2547. 进入
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2548. 图书馆服务
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1504](../src/scenes/phone/P15_Zjuding/index.tsx#L1504)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)
2549. 未开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2550. 已开放
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:391](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L391)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2551. 校园导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:392](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L392)
2552. 部门黄页可用
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2553. 服务联络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2554. 公共联络表可查看
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:393](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L393)
2555. 仅显示已公开记录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:401](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L401)
2556. 份本机档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:402](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L402)
2557. 查看档案不会生成证明、改变物品或推进图书馆进度。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:403](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L403)
2558. 已公开失物档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:406](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L406)
2559. 本机已取得
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:409](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L409)
2560. 后续只会在相关记录真正取得后显示。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:415](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L415)
2561. 暂无已公开档案
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:415](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L415)
2562. 本机预览工具
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:423](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L423)
2563. 访客信息草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:424](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L424)
2564. 草稿仅保存在当前浏览器会话，不代表正式入校申请。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:425](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L425)
2565. 访客预览草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:427](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L427)
2566. 访客姓名
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:428](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L428)
2567. 用于本机预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:428](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L428)
2568. 到访日期
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:429](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L429)
2569. 例如：08月24日
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:429](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L429)
2570. 到访用途
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2571. 亲友来访
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2572. 学术交流
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:430](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L430)
2573. 保存预览草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:431](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L431)
2574. 清空
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:431](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L431)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:475](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L475)
2575. 未提交·本机预览
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:433](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L433)
2576. 本地微卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:441](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L441)
2577. 校园场景外语
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:442](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L442)
2578. 点击卡片查看中文释义与场景例句。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:443](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L443)
2579. 外语卡片
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:445](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L445)
2580. 点击查看释义
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:450](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L450)
2581. 7:55 开发者通道
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:464](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L464)
2582. 向开发团队反馈
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:465](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L465)
2583. 整理问题或建议后，可直接前往 GitHub 提交 Issue。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:466](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L466)
2584. 7:55 开发者链接
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:468](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L468)
2585. GitHub 仓库
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:469](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L469)
2586. 提交 Issue
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:470](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L470)
2587. 交互问题
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2588. 内容校对
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:473](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L473)
2589. 反馈内容
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:474](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L474)
2590. 描述问题、复现步骤或建议
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:474](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L474)
2591. 保存草稿
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:475](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L475)
2592. 校园
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:483](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L483)
2593. 统一应用目录
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:490](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L490)
2594. 应用状态与首页、搜索完全一致。未开放项保留原名称与静态图标。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:492](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L492)
2595. 校园公开联络表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:521](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L521)
2596. 个服务联络点
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:522](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L522)
2597. 号码来自当前游戏内容，页面不会直接拨号。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:523](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L523)
2598. 部门联系方式
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:525](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L525)
2599. 部门黄页会在剧情恢复校园身份后开放。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:530](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L530)
2600. 打开部门黄页
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:530](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L530)
2601. 当前已公开状态
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:537](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L537)
2602. 条消息
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:538](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L538)
2603. 只聚合已发生的网络、身份、预约和记录状态。
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:539](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L539)
2604. 消息列表
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:541](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L541)
2605. 已读
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:558](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L558)
2606. 取得电子校园卡后显示
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2607. 身份未读取
   来源：[src/scenes/phone/P15_Zjuding/index.tsx:1963](../src/scenes/phone/P15_Zjuding/index.tsx#L1963)；[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2608. 校园身份
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:569](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L569)
2609. 当前网络
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:572](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L572)
2610. 详情
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:572](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L572)
2611. 未读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
2612. 已读取
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:573](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L573)
2613. 当前无预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2614. 图书馆预约
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2615. 座位 {{state.ui.librarySelectedSeat ?? "022"}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:574](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L574)
2616. GitHub Issues
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:575](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L575)
2617. 返回，离开{{PANEL\_TITLES\[panel\]}}
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:586](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L586)
2618. 浙大钉导航
   来源：[src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx:592](../src/scenes/phone/P15_Zjuding/ZjudingUtilityPanel.tsx#L592)
2619. 基础图书馆入口 · {{RPG\_CONTROL\_HINTS.libraryGate}}
   来源：[src/scenes/rpg/BootScene.ts:171](../src/scenes/rpg/BootScene.ts#L171)
2620. 东区大食堂入口 · {{formatRpgInteractionHint("进入食堂")}}
   来源：[src/scenes/rpg/BootScene.ts:176](../src/scenes/rpg/BootScene.ts#L176)
2621. 剧场入口 · {{formatRpgInteractionHint("进入剧场")}}
   来源：[src/scenes/rpg/BootScene.ts:181](../src/scenes/rpg/BootScene.ts#L181)
2622. 共享单车
   来源：[src/scenes/rpg/BootScene.ts:573](../src/scenes/rpg/BootScene.ts#L573)；[src/scenes/rpg/BootScene.ts:582](../src/scenes/rpg/BootScene.ts#L582)；[src/scenes/rpg/BootScene.ts:590](../src/scenes/rpg/BootScene.ts#L590)；[src/scenes/rpg/BootScene.ts:601](../src/scenes/rpg/BootScene.ts#L601)；[src/scenes/rpg/RpgGameHost.tsx:1598](../src/scenes/rpg/RpgGameHost.tsx#L1598)；[src/scenes/rpg/RpgItemUseGuidance.ts:206](../src/scenes/rpg/RpgItemUseGuidance.ts#L206)；[src/scenes/rpg/RpgItemUseGuidance.ts:207](../src/scenes/rpg/RpgItemUseGuidance.ts#L207)；[src/scenes/rpg/RpgItemUseGuidance.ts:208](../src/scenes/rpg/RpgItemUseGuidance.ts#L208)；[src/scenes/rpg/RpgItemUseGuidance.ts:209](../src/scenes/rpg/RpgItemUseGuidance.ts#L209)
2623. 共享单车交互尚未开放，请先完成食堂内部流程。
   来源：[src/scenes/rpg/BootScene.ts:574](../src/scenes/rpg/BootScene.ts#L574)
2624. wrong\_item
   来源：[src/scenes/rpg/BootScene.ts:581](../src/scenes/rpg/BootScene.ts#L581)；[src/scenes/rpg/RpgGameHost.tsx:1534](../src/scenes/rpg/RpgGameHost.tsx#L1534)
2625. 共享单车当前只接收纸巾或 2 元现金。
   来源：[src/scenes/rpg/BootScene.ts:583](../src/scenes/rpg/BootScene.ts#L583)
2626. missed\_target
   来源：[src/scenes/rpg/BootScene.ts:590](../src/scenes/rpg/BootScene.ts#L590)；[src/scenes/rpg/BootScene.ts:600](../src/scenes/rpg/BootScene.ts#L600)；[src/scenes/rpg/RpgInventoryDock.tsx:293](../src/scenes/rpg/RpgInventoryDock.tsx#L293)
2627. 松手点没有进入共享单车车身的高亮范围。
   来源：[src/scenes/rpg/BootScene.ts:602](../src/scenes/rpg/BootScene.ts#L602)
2628. success
   来源：[src/scenes/rpg/BootScene.ts:626](../src/scenes/rpg/BootScene.ts#L626)
2629. campus-minimap
   来源：[src/scenes/rpg/RpgCameraController.ts:27](../src/scenes/rpg/RpgCameraController.ts#L27)
2630. WASD 移动
   来源：[src/scenes/rpg/RpgControlHints.ts:2](../src/scenes/rpg/RpgControlHints.ts#L2)
2631. 空格键
   来源：[src/scenes/rpg/RpgControlHints.ts:3](../src/scenes/rpg/RpgControlHints.ts#L3)
2632. WASD 移动 · 空格键进入
   来源：[src/scenes/rpg/RpgControlHints.ts:4](../src/scenes/rpg/RpgControlHints.ts#L4)
2633. 空格键继续
   来源：[src/scenes/rpg/RpgControlHints.ts:5](../src/scenes/rpg/RpgControlHints.ts#L5)
2634. 拖动道具 {{label}}
   来源：[src/scenes/rpg/RpgControlHints.ts:14](../src/scenes/rpg/RpgControlHints.ts#L14)
2635. 启真湖的帖子已经归档,不能再补拍了。
   来源：[src/scenes/rpg/RpgGameHost.tsx:242](../src/scenes/rpg/RpgGameHost.tsx#L242)
2636. 这里构不成画面,换个位置再试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:243](../src/scenes/rpg/RpgGameHost.tsx#L243)
2637. 这张照片已经不在记录里了,重新拍一张。
   来源：[src/scenes/rpg/RpgGameHost.tsx:244](../src/scenes/rpg/RpgGameHost.tsx#L244)
2638. 草稿和照片对不上,请重新拍摄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:245](../src/scenes/rpg/RpgGameHost.tsx#L245)
2639. 先把该选的都选好,再存草稿。
   来源：[src/scenes/rpg/RpgGameHost.tsx:246](../src/scenes/rpg/RpgGameHost.tsx#L246)
2640. {{targetLabel}}已完成当前操作。
   来源：[src/scenes/rpg/RpgGameHost.tsx:360](../src/scenes/rpg/RpgGameHost.tsx#L360)
2641. 切到浅色操作后再使用道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:361](../src/scenes/rpg/RpgGameHost.tsx#L361)
2642. {{targetLabel}}当前需要其他道具。
   来源：[src/scenes/rpg/RpgGameHost.tsx:362](../src/scenes/rpg/RpgGameHost.tsx#L362)
2643. 当前目标还没有观察记录；深色观察可补充坐标。
   来源：[src/scenes/rpg/RpgGameHost.tsx:363](../src/scenes/rpg/RpgGameHost.tsx#L363)
2644. 普通鱼钩无法固定纸条。需要完成湖区道具链。
   来源：[src/scenes/rpg/RpgGameHost.tsx:364](../src/scenes/rpg/RpgGameHost.tsx#L364)
2645. 这个目标已经完成，请查看当前任务。
   来源：[src/scenes/rpg/RpgGameHost.tsx:365](../src/scenes/rpg/RpgGameHost.tsx#L365)
2646. 当前剧情条件尚未满足。
   来源：[src/scenes/rpg/RpgGameHost.tsx:366](../src/scenes/rpg/RpgGameHost.tsx#L366)
2647. 该交互点当前未开放。
   来源：[src/scenes/rpg/RpgGameHost.tsx:367](../src/scenes/rpg/RpgGameHost.tsx#L367)
2648. 当前操作已记录。
   来源：[src/scenes/rpg/RpgGameHost.tsx:385](../src/scenes/rpg/RpgGameHost.tsx#L385)
2649. 当前操作已经完成。
   来源：[src/scenes/rpg/RpgGameHost.tsx:386](../src/scenes/rpg/RpgGameHost.tsx#L386)
2650. 切换到目标要求的现实模式后重试。
   来源：[src/scenes/rpg/RpgGameHost.tsx:387](../src/scenes/rpg/RpgGameHost.tsx#L387)
2651. 当前流程还不能安装手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1472](../src/scenes/rpg/RpgGameHost.tsx#L1472)
2652. 角色
   来源：[src/scenes/rpg/RpgGameHost.tsx:1478](../src/scenes/rpg/RpgGameHost.tsx#L1478)；[src/scenes/rpg/RpgItemUseGuidance.ts:130](../src/scenes/rpg/RpgItemUseGuidance.ts#L130)；[src/scenes/rpg/RpgItemUseGuidance.ts:131](../src/scenes/rpg/RpgItemUseGuidance.ts#L131)；[src/scenes/rpg/RpgItemUseGuidance.ts:132](../src/scenes/rpg/RpgItemUseGuidance.ts#L132)；[src/scenes/rpg/RpgItemUseGuidance.ts:133](../src/scenes/rpg/RpgItemUseGuidance.ts#L133)
2653. unavailable
   来源：[src/scenes/rpg/RpgGameHost.tsx:1500](../src/scenes/rpg/RpgGameHost.tsx#L1500)；[src/scenes/rpg/RpgGameHost.tsx:1508](../src/scenes/rpg/RpgGameHost.tsx#L1508)；[src/scenes/rpg/RpgGameHost.tsx:1566](../src/scenes/rpg/RpgGameHost.tsx#L1566)
2654. wrong\_target
   来源：[src/scenes/rpg/RpgGameHost.tsx:1525](../src/scenes/rpg/RpgGameHost.tsx#L1525)；[src/scenes/rpg/RpgGameHost.tsx:1534](../src/scenes/rpg/RpgGameHost.tsx#L1534)；[src/scenes/rpg/RpgInteractionContract.ts:1351](../src/scenes/rpg/RpgInteractionContract.ts#L1351)
2655. cleaned
   来源：[src/scenes/rpg/RpgGameHost.tsx:1589](../src/scenes/rpg/RpgGameHost.tsx#L1589)
2656. 共享单车车锁
   来源：[src/scenes/rpg/RpgGameHost.tsx:1590](../src/scenes/rpg/RpgGameHost.tsx#L1590)；[src/scenes/rpg/RpgItemUseGuidance.ts:202](../src/scenes/rpg/RpgItemUseGuidance.ts#L202)；[src/scenes/rpg/RpgItemUseGuidance.ts:203](../src/scenes/rpg/RpgItemUseGuidance.ts#L203)
2657. 清洁车锁需要浅色操作。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1591](../src/scenes/rpg/RpgGameHost.tsx#L1591)
2658. rule
   来源：[src/scenes/rpg/RpgGameHost.tsx:1591](../src/scenes/rpg/RpgGameHost.tsx#L1591)；[src/scenes/rpg/RpgGameHost.tsx:1599](../src/scenes/rpg/RpgGameHost.tsx#L1599)
2659. paid
   来源：[src/scenes/rpg/RpgGameHost.tsx:1597](../src/scenes/rpg/RpgGameHost.tsx#L1597)
2660. 付款需要浅色操作，且车锁表面已经清洁。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1599](../src/scenes/rpg/RpgGameHost.tsx#L1599)
2661. 入口海报
   来源：[src/scenes/rpg/RpgGameHost.tsx:1610](../src/scenes/rpg/RpgGameHost.tsx#L1610)；[src/scenes/rpg/RpgItemUseGuidance.ts:217](../src/scenes/rpg/RpgItemUseGuidance.ts#L217)；[src/scenes/rpg/RpgItemUseGuidance.ts:218](../src/scenes/rpg/RpgItemUseGuidance.ts#L218)
2662. 检票闸机右侧读票器
   来源：[src/scenes/rpg/RpgGameHost.tsx:1628](../src/scenes/rpg/RpgGameHost.tsx#L1628)；[src/scenes/rpg/RpgItemUseGuidance.ts:224](../src/scenes/rpg/RpgItemUseGuidance.ts#L224)；[src/scenes/rpg/RpgItemUseGuidance.ts:227](../src/scenes/rpg/RpgItemUseGuidance.ts#L227)
2663. 验票完成，闸机已经放行；临时观演票会保留。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1630](../src/scenes/rpg/RpgGameHost.tsx#L1630)
2664. 当前剧情条件不允许验票，请先完成入口取票流程。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1631](../src/scenes/rpg/RpgGameHost.tsx#L1631)
2665. 道具箱旁票据扫描器
   来源：[src/scenes/rpg/RpgGameHost.tsx:1653](../src/scenes/rpg/RpgGameHost.tsx#L1653)；[src/scenes/rpg/RpgItemUseGuidance.ts:234](../src/scenes/rpg/RpgItemUseGuidance.ts#L234)；[src/scenes/rpg/RpgItemUseGuidance.ts:237](../src/scenes/rpg/RpgItemUseGuidance.ts#L237)
2666. 票据扫描完成，道具箱已经解锁；临时观演票已完成用途并从道具栏移除。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1655](../src/scenes/rpg/RpgGameHost.tsx#L1655)
2667. 扫描票据需要浅色操作、临时观演票和当前道具布置阶段。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1656](../src/scenes/rpg/RpgGameHost.tsx#L1656)
2668. 后台通风口
   来源：[src/scenes/rpg/RpgGameHost.tsx:1663](../src/scenes/rpg/RpgGameHost.tsx#L1663)；[src/scenes/rpg/RpgItemUseGuidance.ts:249](../src/scenes/rpg/RpgItemUseGuidance.ts#L249)；[src/scenes/rpg/RpgItemUseGuidance.ts:252](../src/scenes/rpg/RpgItemUseGuidance.ts#L252)；[src/scenes/rpg/RpgItemUseGuidance.ts:254](../src/scenes/rpg/RpgItemUseGuidance.ts#L254)
2669. 灯光控制台
   来源：[src/scenes/rpg/RpgGameHost.tsx:1670](../src/scenes/rpg/RpgGameHost.tsx#L1670)；[src/scenes/rpg/RpgItemUseGuidance.ts:258](../src/scenes/rpg/RpgItemUseGuidance.ts#L258)；[src/scenes/rpg/RpgItemUseGuidance.ts:261](../src/scenes/rpg/RpgItemUseGuidance.ts#L261)；[src/scenes/rpg/RpgItemUseGuidance.ts:263](../src/scenes/rpg/RpgItemUseGuidance.ts#L263)
2670. 你被救起并送回寝室。先找到吹风机。
   来源：[src/scenes/rpg/RpgGameHost.tsx:1730](../src/scenes/rpg/RpgGameHost.tsx#L1730)
2671. 浮排边钓鱼竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:1750](../src/scenes/rpg/RpgGameHost.tsx#L1750)
2672. fishingRod
   来源：[src/scenes/rpg/RpgGameHost.tsx:1750](../src/scenes/rpg/RpgGameHost.tsx#L1750)；[src/scenes/rpg/RpgGameHost.tsx:1769](../src/scenes/rpg/RpgGameHost.tsx#L1769)；[src/scenes/rpg/RpgGameHost.tsx:1778](../src/scenes/rpg/RpgGameHost.tsx#L1778)
2673. 钓鱼竿装饵框
   来源：[src/scenes/rpg/RpgGameHost.tsx:1753](../src/scenes/rpg/RpgGameHost.tsx#L1753)；[src/scenes/rpg/RpgItemUseGuidance.ts:300](../src/scenes/rpg/RpgItemUseGuidance.ts#L300)
2674. decoyPaper
   来源：[src/scenes/rpg/RpgGameHost.tsx:1753](../src/scenes/rpg/RpgGameHost.tsx#L1753)
2675. 已观察抛竿点
   来源：[src/scenes/rpg/RpgGameHost.tsx:1759](../src/scenes/rpg/RpgGameHost.tsx#L1759)
2676. 湖区道具点
   来源：[src/scenes/rpg/RpgGameHost.tsx:1764](../src/scenes/rpg/RpgGameHost.tsx#L1764)
2677. 工具装配框
   来源：[src/scenes/rpg/RpgGameHost.tsx:1769](../src/scenes/rpg/RpgGameHost.tsx#L1769)；[src/scenes/rpg/RpgItemUseGuidance.ts:293](../src/scenes/rpg/RpgItemUseGuidance.ts#L293)；[src/scenes/rpg/RpgItemUseGuidance.ts:319](../src/scenes/rpg/RpgItemUseGuidance.ts#L319)；[src/scenes/rpg/RpgItemUseGuidance.ts:322](../src/scenes/rpg/RpgItemUseGuidance.ts#L322)；[src/scenes/rpg/RpgItemUseGuidance.ts:324](../src/scenes/rpg/RpgItemUseGuidance.ts#L324)；[src/scenes/rpg/RpgItemUseGuidance.ts:325](../src/scenes/rpg/RpgItemUseGuidance.ts#L325)；[src/scenes/rpg/RpgItemUseGuidance.ts:363](../src/scenes/rpg/RpgItemUseGuidance.ts#L363)；[src/scenes/rpg/RpgItemUseGuidance.ts:366](../src/scenes/rpg/RpgItemUseGuidance.ts#L366)；[src/scenes/rpg/RpgItemUseGuidance.ts:367](../src/scenes/rpg/RpgItemUseGuidance.ts#L367)；[src/scenes/rpg/RpgItemUseGuidance.ts:368](../src/scenes/rpg/RpgItemUseGuidance.ts#L368)
2678. 黑天鹅投喂区
   来源：[src/scenes/rpg/RpgGameHost.tsx:1775](../src/scenes/rpg/RpgGameHost.tsx#L1775)；[src/scenes/rpg/RpgItemUseGuidance.ts:355](../src/scenes/rpg/RpgItemUseGuidance.ts#L355)；[src/scenes/rpg/RpgItemUseGuidance.ts:358](../src/scenes/rpg/RpgItemUseGuidance.ts#L358)
2679. 黑天鹅围栏
   来源：[src/scenes/rpg/RpgGameHost.tsx:1778](../src/scenes/rpg/RpgGameHost.tsx#L1778)
2680. 纸条本体水纹
   来源：[src/scenes/rpg/RpgGameHost.tsx:1782](../src/scenes/rpg/RpgGameHost.tsx#L1782)；[src/scenes/rpg/RpgItemUseGuidance.ts:374](../src/scenes/rpg/RpgItemUseGuidance.ts#L374)；[src/scenes/rpg/RpgItemUseGuidance.ts:376](../src/scenes/rpg/RpgItemUseGuidance.ts#L376)；[src/scenes/rpg/RpgItemUseGuidance.ts:377](../src/scenes/rpg/RpgItemUseGuidance.ts#L377)
2681. loading
   来源：[src/scenes/rpg/RpgGameHost.tsx:2284](../src/scenes/rpg/RpgGameHost.tsx#L2284)
2682. 电子校园卡：{{actOneContent.studentName}} · {{actOneContent.studentId}}
   来源：[src/scenes/rpg/RpgGameHost.tsx:2298](../src/scenes/rpg/RpgGameHost.tsx#L2298)
2683. 电子校园卡：身份信息尚未读取
   来源：[src/scenes/rpg/RpgGameHost.tsx:2299](../src/scenes/rpg/RpgGameHost.tsx#L2299)
2684. 手柄已连接：WASD 或方向键移动，空格键交互。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2308](../src/scenes/rpg/RpgGameHost.tsx#L2308)
2685. 手柄有电，角色还没有姓名。去部门黄页读取校园卡。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2309](../src/scenes/rpg/RpgGameHost.tsx#L2309)
2686. 手柄已连接，浙大体艺还没有开始课外锻炼。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2310](../src/scenes/rpg/RpgGameHost.tsx#L2310)
2687. 道具栏里没有手柄。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2311](../src/scenes/rpg/RpgGameHost.tsx#L2311)
2688. 当前任务还没有开放手柄控制。
   来源：[src/scenes/rpg/RpgGameHost.tsx:2312](../src/scenes/rpg/RpgGameHost.tsx#L2312)
2689. 地图资源加载进度
   来源：[src/scenes/rpg/RpgGameHost.tsx:2407](../src/scenes/rpg/RpgGameHost.tsx#L2407)
2690. 重试加载
   来源：[src/scenes/rpg/RpgGameHost.tsx:2419](../src/scenes/rpg/RpgGameHost.tsx#L2419)
2691. 返回手机主页
   来源：[src/scenes/rpg/RpgGameHost.tsx:2420](../src/scenes/rpg/RpgGameHost.tsx#L2420)
2692. 聚焦手机
   来源：[src/scenes/rpg/RpgGameHost.tsx:2420](../src/scenes/rpg/RpgGameHost.tsx#L2420)
2693. 使用游戏手柄
   来源：[src/scenes/rpg/RpgGameHost.tsx:2627](../src/scenes/rpg/RpgGameHost.tsx#L2627)
2694. 单击连接手柄，双击查看完整详情
   来源：[src/scenes/rpg/RpgGameHost.tsx:2628](../src/scenes/rpg/RpgGameHost.tsx#L2628)
2695. gamepad
   来源：[src/scenes/rpg/RpgGameHost.tsx:2632](../src/scenes/rpg/RpgGameHost.tsx#L2632)
2696. 手柄
   来源：[src/scenes/rpg/RpgGameHost.tsx:2633](../src/scenes/rpg/RpgGameHost.tsx#L2633)
2697. S 提竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:2696](../src/scenes/rpg/RpgGameHost.tsx#L2696)
2698. 提竿
   来源：[src/scenes/rpg/RpgGameHost.tsx:2703](../src/scenes/rpg/RpgGameHost.tsx#L2703)
2699. D 右收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2708](../src/scenes/rpg/RpgGameHost.tsx#L2708)
2700. 右收线
   来源：[src/scenes/rpg/RpgGameHost.tsx:2715](../src/scenes/rpg/RpgGameHost.tsx#L2715)
2701. 皮划艇划桨手势和交互按钮
   来源：[src/scenes/rpg/RpgGameHost.tsx:2719](../src/scenes/rpg/RpgGameHost.tsx#L2719)
2702. 左桨，上划前进，下划后退，轻触默认前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2723](../src/scenes/rpg/RpgGameHost.tsx#L2723)
2703. willowBranchPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2730](../src/scenes/rpg/RpgGameHost.tsx#L2730)
2704. 左桨
   来源：[src/scenes/rpg/RpgGameHost.tsx:2731](../src/scenes/rpg/RpgGameHost.tsx#L2731)
2705. ↑ 前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2732](../src/scenes/rpg/RpgGameHost.tsx#L2732)；[src/scenes/rpg/RpgGameHost.tsx:2746](../src/scenes/rpg/RpgGameHost.tsx#L2746)
2706. ↑前进 · ↓后退
   来源：[src/scenes/rpg/RpgGameHost.tsx:2732](../src/scenes/rpg/RpgGameHost.tsx#L2732)；[src/scenes/rpg/RpgGameHost.tsx:2746](../src/scenes/rpg/RpgGameHost.tsx#L2746)
2707. ↓ 后退
   来源：[src/scenes/rpg/RpgGameHost.tsx:2732](../src/scenes/rpg/RpgGameHost.tsx#L2732)；[src/scenes/rpg/RpgGameHost.tsx:2746](../src/scenes/rpg/RpgGameHost.tsx#L2746)
2708. 右桨，上划前进，下划后退，轻触默认前进
   来源：[src/scenes/rpg/RpgGameHost.tsx:2737](../src/scenes/rpg/RpgGameHost.tsx#L2737)
2709. warningSignPaddle
   来源：[src/scenes/rpg/RpgGameHost.tsx:2744](../src/scenes/rpg/RpgGameHost.tsx#L2744)
2710. 右桨
   来源：[src/scenes/rpg/RpgGameHost.tsx:2745](../src/scenes/rpg/RpgGameHost.tsx#L2745)
2711. 交互（键盘为空格键）
   来源：[src/scenes/rpg/RpgGameHost.tsx:2764](../src/scenes/rpg/RpgGameHost.tsx#L2764)
2712. 请将设备横过来继续 RPG
   来源：[src/scenes/rpg/RpgGameHost.tsx:2773](../src/scenes/rpg/RpgGameHost.tsx#L2773)
2713. 点击闸机小屏，核对入馆与到达时间
   来源：[src/scenes/rpg/RpgGameHost.tsx:2825](../src/scenes/rpg/RpgGameHost.tsx#L2825)
2714. 前往二层南区寻找 022
   来源：[src/scenes/rpg/RpgGameHost.tsx:2825](../src/scenes/rpg/RpgGameHost.tsx#L2825)
2715. 调查纸条提到的公开记录
   来源：[src/scenes/rpg/RpgGameHost.tsx:2826](../src/scenes/rpg/RpgGameHost.tsx#L2826)
2716. 检查书包旁边的占座纸条
   来源：[src/scenes/rpg/RpgGameHost.tsx:2826](../src/scenes/rpg/RpgGameHost.tsx#L2826)
2717. 用占座纸条查找公开记录
   来源：[src/scenes/rpg/RpgGameHost.tsx:2828](../src/scenes/rpg/RpgGameHost.tsx#L2828)
2718. 并行收集四项公示材料（{{evidenceReadyCount}}/4）
   来源：[src/scenes/rpg/RpgGameHost.tsx:2836](../src/scenes/rpg/RpgGameHost.tsx#L2836)
2719. 把已取得材料上传到 CC98
   来源：[src/scenes/rpg/RpgGameHost.tsx:2837](../src/scenes/rpg/RpgGameHost.tsx#L2837)
2720. 确认系统说明，开始筛选有效回复
   来源：[src/scenes/rpg/RpgGameHost.tsx:2839](../src/scenes/rpg/RpgGameHost.tsx#L2839)
2721. 让证据公示进入 CC98 十大
   来源：[src/scenes/rpg/RpgGameHost.tsx:2840](../src/scenes/rpg/RpgGameHost.tsx#L2840)
2722. 完成图书馆座位恢复申请
   来源：[src/scenes/rpg/RpgGameHost.tsx:2841](../src/scenes/rpg/RpgGameHost.tsx#L2841)
2723. 对 022 书包使用离座清退 PASS
   来源：[src/scenes/rpg/RpgGameHost.tsx:2842](../src/scenes/rpg/RpgGameHost.tsx#L2842)
2724. 坐到已经恢复的 022
   来源：[src/scenes/rpg/RpgGameHost.tsx:2843](../src/scenes/rpg/RpgGameHost.tsx#L2843)
2725. 与 022 继续对话
   来源：[src/scenes/rpg/RpgGameHost.tsx:2844](../src/scenes/rpg/RpgGameHost.tsx#L2844)
2726. 追上逃跑的记录纸条
   来源：[src/scenes/rpg/RpgGameHost.tsx:2845](../src/scenes/rpg/RpgGameHost.tsx#L2845)
2727. 前往基础图书馆，寻找系统的朋友
   来源：[src/scenes/rpg/RpgGameHost.tsx:2846](../src/scenes/rpg/RpgGameHost.tsx#L2846)
2728. 说明
   来源：[src/scenes/rpg/RpgGameHost.tsx:2855](../src/scenes/rpg/RpgGameHost.tsx#L2855)
2729. 调查
   来源：[src/scenes/rpg/RpgGameHost.tsx:2869](../src/scenes/rpg/RpgGameHost.tsx#L2869)
2730. 深色模式只读取线索和异常，不执行实体操作。
   来源：[src/scenes/rpg/RpgInteractionContract.ts:44](../src/scenes/rpg/RpgInteractionContract.ts#L44)
2731. 浅色操作
   来源：[src/scenes/rpg/RpgInteractionContract.ts:47](../src/scenes/rpg/RpgInteractionContract.ts#L47)
2732. 浅色模式执行移动、拖放、清洁、付款和设备操作。
   来源：[src/scenes/rpg/RpgInteractionContract.ts:48](../src/scenes/rpg/RpgInteractionContract.ts#L48)
2733. 公告栏前的签到记录纸条
   来源：[src/scenes/rpg/RpgInteractionContract.ts:520](../src/scenes/rpg/RpgInteractionContract.ts#L520)
2734. 一楼旧钟
   来源：[src/scenes/rpg/RpgInteractionContract.ts:538](../src/scenes/rpg/RpgInteractionContract.ts#L538)
2735. 与一楼前台值班助理交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:628](../src/scenes/rpg/RpgInteractionContract.ts#L628)
2736. 与二楼电梯口值班安全员交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:643](../src/scenes/rpg/RpgInteractionContract.ts#L643)
2737. 与三楼参照教室教师交谈
   来源：[src/scenes/rpg/RpgInteractionContract.ts:653](../src/scenes/rpg/RpgInteractionContract.ts#L653)
2738. 查看苏步青生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:663](../src/scenes/rpg/RpgInteractionContract.ts#L663)
2739. 查看竺可桢生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:673](../src/scenes/rpg/RpgInteractionContract.ts#L673)
2740. 查看路甬祥生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:683](../src/scenes/rpg/RpgInteractionContract.ts#L683)
2741. 查看陈建功生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:693](../src/scenes/rpg/RpgInteractionContract.ts#L693)
2742. 查看谈家桢生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:703](../src/scenes/rpg/RpgInteractionContract.ts#L703)
2743. 查看程开甲生平
   来源：[src/scenes/rpg/RpgInteractionContract.ts:713](../src/scenes/rpg/RpgInteractionContract.ts#L713)
2744. 观察 104 黑板擦痕
   来源：[src/scenes/rpg/RpgInteractionContract.ts:723](../src/scenes/rpg/RpgInteractionContract.ts#L723)
2745. 检查 105 讲台回放
   来源：[src/scenes/rpg/RpgInteractionContract.ts:739](../src/scenes/rpg/RpgInteractionContract.ts#L739)
2746. 三楼晨间教室布置参照
   来源：[src/scenes/rpg/RpgInteractionContract.ts:755](../src/scenes/rpg/RpgInteractionContract.ts#L755)
2747. 204 教室残影组
   来源：[src/scenes/rpg/RpgInteractionContract.ts:768](../src/scenes/rpg/RpgInteractionContract.ts#L768)
2748. mismatched\_nonce
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1345](../src/scenes/rpg/RpgInteractionContract.ts#L1345)
2749. wrong\_scene
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1348](../src/scenes/rpg/RpgInteractionContract.ts#L1348)
2750. wrong\_bounds
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1354](../src/scenes/rpg/RpgInteractionContract.ts#L1354)
2751. stale\_projection
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1359](../src/scenes/rpg/RpgInteractionContract.ts#L1359)
2752. invalid\_player
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1368](../src/scenes/rpg/RpgInteractionContract.ts#L1368)
2753. spatial\_claim\_mismatch
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1384](../src/scenes/rpg/RpgInteractionContract.ts#L1384)
2754. 需要{{contract.label}}：{{contract.shortHint}}
   来源：[src/scenes/rpg/RpgInteractionContract.ts:1626](../src/scenes/rpg/RpgInteractionContract.ts#L1626)
2755. {{ITEM\_META\[itemId\].name}}已使用。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:102](../src/scenes/rpg/RpgInventoryDock.tsx#L102)
2756. 距离太远，未能使用。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:103](../src/scenes/rpg/RpgInventoryDock.tsx#L103)
2757. 道具不匹配。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:104](../src/scenes/rpg/RpgInventoryDock.tsx#L104)
2758. 当前模式无法进行这项操作。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:106](../src/scenes/rpg/RpgInventoryDock.tsx#L106)
2759. 尚未记录目标位置。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:107](../src/scenes/rpg/RpgInventoryDock.tsx#L107)
2760. 钓钩无法固定纸张。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:108](../src/scenes/rpg/RpgInventoryDock.tsx#L108)
2761. 这项操作已经完成。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:109](../src/scenes/rpg/RpgInventoryDock.tsx#L109)
2762. 这次使用没有生效。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:110](../src/scenes/rpg/RpgInventoryDock.tsx#L110)
2763. consumed
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:136](../src/scenes/rpg/RpgInventoryDock.tsx#L136)
2764. input\_blocked
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:150](../src/scenes/rpg/RpgInventoryDock.tsx#L150)
2765. 道具没有进入游戏画布，请拖到场景中的对应物体。
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:294](../src/scenes/rpg/RpgInventoryDock.tsx#L294)
2766. RPG 道具栏
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:314](../src/scenes/rpg/RpgInventoryDock.tsx#L314)
2767. 道具
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:319](../src/scenes/rpg/RpgInventoryDock.tsx#L319)
2768. 拖动{{ITEM\_META\[itemId\].name}}，{{isPaperItem(itemId) ? "单击" : "双击"}}查看详情
   来源：[src/scenes/rpg/RpgInventoryDock.tsx:327](../src/scenes/rpg/RpgInventoryDock.tsx#L327)
2769. 校园卡在手机应用和地图入口中读取
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:13](../src/scenes/rpg/RpgItemUseGuidance.ts#L13)
2770. 前往 CC98 搜索栏提交占座纸条
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:14](../src/scenes/rpg/RpgItemUseGuidance.ts#L14)
2771. 前往 CC98 证据上传区提交旧版规定
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:15](../src/scenes/rpg/RpgItemUseGuidance.ts#L15)
2772. 前往 CC98 或恢复申请页面提交证明
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:16](../src/scenes/rpg/RpgItemUseGuidance.ts#L16)；[src/scenes/rpg/RpgItemUseGuidance.ts:18](../src/scenes/rpg/RpgItemUseGuidance.ts#L18)
2773. 前往 CC98 或恢复申请页面提交凭据
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:17](../src/scenes/rpg/RpgItemUseGuidance.ts#L17)
2774. 到食堂左下角混合台倒入玻璃杯
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:19](../src/scenes/rpg/RpgItemUseGuidance.ts#L19)；[src/scenes/rpg/RpgItemUseGuidance.ts:20](../src/scenes/rpg/RpgItemUseGuidance.ts#L20)；[src/scenes/rpg/RpgItemUseGuidance.ts:21](../src/scenes/rpg/RpgItemUseGuidance.ts#L21)
2775. 在食堂地图中拖到自己身上喝掉
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:22](../src/scenes/rpg/RpgItemUseGuidance.ts#L22)
2776. 到食堂第五个打饭窗口上方的宣传灯箱空杯位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:23](../src/scenes/rpg/RpgItemUseGuidance.ts#L23)
2777. 靠近取餐窗口后按空格使用；纸包鸡需在深色第三窗口交票
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:24](../src/scenes/rpg/RpgItemUseGuidance.ts#L24)
2778. 食物彩蛋，没有剧情用途
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:25](../src/scenes/rpg/RpgItemUseGuidance.ts#L25)；[src/scenes/rpg/RpgItemUseGuidance.ts:26](../src/scenes/rpg/RpgItemUseGuidance.ts#L26)；[src/scenes/rpg/RpgItemUseGuidance.ts:27](../src/scenes/rpg/RpgItemUseGuidance.ts#L27)；[src/scenes/rpg/RpgItemUseGuidance.ts:28](../src/scenes/rpg/RpgItemUseGuidance.ts#L28)
2779. 与另一半临时票合成，无需拖到场景
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:29](../src/scenes/rpg/RpgItemUseGuidance.ts#L29)；[src/scenes/rpg/RpgItemUseGuidance.ts:30](../src/scenes/rpg/RpgItemUseGuidance.ts#L30)
2780. 到剧院灯光控制台打开节目单排序
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:31](../src/scenes/rpg/RpgItemUseGuidance.ts#L31)；[src/scenes/rpg/RpgItemUseGuidance.ts:32](../src/scenes/rpg/RpgItemUseGuidance.ts#L32)；[src/scenes/rpg/RpgItemUseGuidance.ts:33](../src/scenes/rpg/RpgItemUseGuidance.ts#L33)
2781. 前往 CC98 或馆藏检索提交湿节目单
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:34](../src/scenes/rpg/RpgItemUseGuidance.ts#L34)
2782. 前往校园地图搜索栏提交地点关键词
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:35](../src/scenes/rpg/RpgItemUseGuidance.ts#L35)；[src/scenes/rpg/RpgItemUseGuidance.ts:36](../src/scenes/rpg/RpgItemUseGuidance.ts#L36)；[src/scenes/rpg/RpgItemUseGuidance.ts:37](../src/scenes/rpg/RpgItemUseGuidance.ts#L37)
2783. 坐标会在启真湖布置假纸条时自动核验
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:38](../src/scenes/rpg/RpgItemUseGuidance.ts#L38)
2784. 靠近目标，把道具拖到物体本身后松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:41](../src/scenes/rpg/RpgItemUseGuidance.ts#L41)
2785. ready
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:42](../src/scenes/rpg/RpgItemUseGuidance.ts#L42)
2786. 当前可以使用
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:43](../src/scenes/rpg/RpgItemUseGuidance.ts#L43)
2787. 当前使用条件未满足
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:50](../src/scenes/rpg/RpgItemUseGuidance.ts#L50)
2788. passive
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:56](../src/scenes/rpg/RpgItemUseGuidance.ts#L56)
2789. 无需拖动
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:57](../src/scenes/rpg/RpgItemUseGuidance.ts#L57)
2790. elsewhere
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:62](../src/scenes/rpg/RpgItemUseGuidance.ts#L62)
2791. 本场景没有使用点
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:63](../src/scenes/rpg/RpgItemUseGuidance.ts#L63)
2792. 保留该道具，跟随当前任务前往对应页面或场景。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:64](../src/scenes/rpg/RpgItemUseGuidance.ts#L64)
2793. 旧钟时针插槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:94](../src/scenes/rpg/RpgItemUseGuidance.ts#L94)
2794. 旧钟定位盘插槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:99](../src/scenes/rpg/RpgItemUseGuidance.ts#L99)
2795. 清洁车车轮
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:105](../src/scenes/rpg/RpgItemUseGuidance.ts#L105)；[src/scenes/rpg/RpgItemUseGuidance.ts:114](../src/scenes/rpg/RpgItemUseGuidance.ts#L114)
2796. 先靠近保洁车检查卡住的车轮。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:105](../src/scenes/rpg/RpgItemUseGuidance.ts#L105)
2797. 清洁车轮罩
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:108](../src/scenes/rpg/RpgItemUseGuidance.ts#L108)
2798. 先把润滑油拖到清洁车车轮，修好后仍会保留半瓶。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:114](../src/scenes/rpg/RpgItemUseGuidance.ts#L114)
2799. 把剩下的半瓶润滑油拖到旧钟齿轮。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:117](../src/scenes/rpg/RpgItemUseGuidance.ts#L117)
2800. 旧钟齿轮
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:117](../src/scenes/rpg/RpgItemUseGuidance.ts#L117)
2801. 润滑油的剧情用途已经完成。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:119](../src/scenes/rpg/RpgItemUseGuidance.ts#L119)
2802. 大厅旧钟表盘
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:123](../src/scenes/rpg/RpgItemUseGuidance.ts#L123)
2803. 靠近旧钟，把黄铜分针组件拖到可见表盘内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:123](../src/scenes/rpg/RpgItemUseGuidance.ts#L123)
2804. 手柄已经连接并等待方向输入校验。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:129](../src/scenes/rpg/RpgItemUseGuidance.ts#L129)
2805. 先在部门黄页完成角色命名。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:130](../src/scenes/rpg/RpgItemUseGuidance.ts#L130)
2806. 先在浙大体艺开始课外锻炼。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:131](../src/scenes/rpg/RpgItemUseGuidance.ts#L131)
2807. 先在 CC98 完成手柄购买。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:132](../src/scenes/rpg/RpgItemUseGuidance.ts#L132)
2808. 把手柄拖到角色身体范围内，并在人物轮廓内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:133](../src/scenes/rpg/RpgItemUseGuidance.ts#L133)
2809. 文学书架 755 段
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:142](../src/scenes/rpg/RpgItemUseGuidance.ts#L142)；[src/scenes/rpg/RpgItemUseGuidance.ts:143](../src/scenes/rpg/RpgItemUseGuidance.ts#L143)
2810. 先完成馆藏检索并取得索书号 755。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:143](../src/scenes/rpg/RpgItemUseGuidance.ts#L143)
2811. 前台正在人工核验并盖章，等待流程完成。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:146](../src/scenes/rpg/RpgItemUseGuidance.ts#L146)
2812. 靠近前台，把物品识别报告拖到工作人员与盖章台之间。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:151](../src/scenes/rpg/RpgItemUseGuidance.ts#L151)
2813. 前台工作人员
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:151](../src/scenes/rpg/RpgItemUseGuidance.ts#L151)；[src/scenes/rpg/RpgItemUseGuidance.ts:152](../src/scenes/rpg/RpgItemUseGuidance.ts#L152)
2814. 先在照片页面生成物品识别报告。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:152](../src/scenes/rpg/RpgItemUseGuidance.ts#L152)
2815. 022 座位凭据已经取出，右移箭头已完成最后用途。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:157](../src/scenes/rpg/RpgItemUseGuidance.ts#L157)
2816. 022 占座书包
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:163](../src/scenes/rpg/RpgItemUseGuidance.ts#L163)；[src/scenes/rpg/RpgItemUseGuidance.ts:164](../src/scenes/rpg/RpgItemUseGuidance.ts#L164)
2817. 先完成公开公示和三项恢复材料，取得清退 PASS。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:164](../src/scenes/rpg/RpgItemUseGuidance.ts#L164)
2818. 1、2、3号取餐窗口验票槽
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:170](../src/scenes/rpg/RpgItemUseGuidance.ts#L170)
2819. 取餐号只在取餐阶段使用。先完成当前食堂任务。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:170](../src/scenes/rpg/RpgItemUseGuidance.ts#L170)
2820. 不需要拖拽或站位。浅色操作可在对应窗口交票；深色观察可补充查看窗口残影。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:172](../src/scenes/rpg/RpgItemUseGuidance.ts#L172)
2821. 取餐窗口
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:172](../src/scenes/rpg/RpgItemUseGuidance.ts#L172)
2822. 靠近混合台打开调配窗口，再点击对应饮料倒入大玻璃杯。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:185](../src/scenes/rpg/RpgItemUseGuidance.ts#L185)
2823. 左下角混合台
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:185](../src/scenes/rpg/RpgItemUseGuidance.ts#L185)
2824. 第五个打饭窗口下方的宣传板空杯位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:192](../src/scenes/rpg/RpgItemUseGuidance.ts#L192)
2825. 先靠近宣传板，再把今日新品气泡水拖进发光的空杯位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:192](../src/scenes/rpg/RpgItemUseGuidance.ts#L192)
2826. 把难喝饮料拖到人物身上可以喝掉，但不会推进剧情。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:195](../src/scenes/rpg/RpgItemUseGuidance.ts#L195)
2827. 玩家自己
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:195](../src/scenes/rpg/RpgItemUseGuidance.ts#L195)
2828. 车锁已经擦净，2 元现金可以用于付款。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:201](../src/scenes/rpg/RpgItemUseGuidance.ts#L201)
2829. 切回浅色模式后再清洁车锁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:202](../src/scenes/rpg/RpgItemUseGuidance.ts#L202)
2830. 先用纸巾清洁车锁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:206](../src/scenes/rpg/RpgItemUseGuidance.ts#L206)
2831. 切回浅色模式后付款。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:207](../src/scenes/rpg/RpgItemUseGuidance.ts#L207)
2832. 现金余额不足 2 元。回食堂完成收餐盘，领取 2 元和油渍纸巾。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:208](../src/scenes/rpg/RpgItemUseGuidance.ts#L208)
2833. 把 2 元现金拖到共享单车范围内，并在车身上松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:209](../src/scenes/rpg/RpgItemUseGuidance.ts#L209)
2834. 海报玻璃已经擦净。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:216](../src/scenes/rpg/RpgItemUseGuidance.ts#L216)
2835. 擦拭海报只在剧院入口取票阶段开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:217](../src/scenes/rpg/RpgItemUseGuidance.ts#L217)
2836. 切回浅色模式后擦拭海报玻璃。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:218](../src/scenes/rpg/RpgItemUseGuidance.ts#L218)
2837. 从海报右侧靠近，把油渍纸巾拖到玻璃污渍上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:219](../src/scenes/rpg/RpgItemUseGuidance.ts#L219)
2838. 入口海报玻璃
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:219](../src/scenes/rpg/RpgItemUseGuidance.ts#L219)
2839. 深色模式只读取异常；切回浅色操作后再把票拖入读票器。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:224](../src/scenes/rpg/RpgItemUseGuidance.ts#L224)
2840. 靠近读票器，把票拖到右侧验票槽内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:228](../src/scenes/rpg/RpgItemUseGuidance.ts#L228)
2841. 票据扫描已经完成，临时观演票已从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:232](../src/scenes/rpg/RpgItemUseGuidance.ts#L232)
2842. 深色模式可查看道具箱残影；切回浅色模式后扫描票据。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:234](../src/scenes/rpg/RpgItemUseGuidance.ts#L234)
2843. 靠近道具箱旁的扫描器，把票拖到扫描口内松手。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:238](../src/scenes/rpg/RpgItemUseGuidance.ts#L238)
2844. 入场核验已完成。票会在后台道具箱阶段再次使用，先完成当前节目单任务。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:242](../src/scenes/rpg/RpgItemUseGuidance.ts#L242)
2845. 当前流程不需要再次拖动临时观演票。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:244](../src/scenes/rpg/RpgItemUseGuidance.ts#L244)
2846. 后台纸屑已经显影，荧光粉刷已从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:247](../src/scenes/rpg/RpgItemUseGuidance.ts#L247)
2847. 先在后台完成票据扫描并打开道具箱，取得荧光粉刷。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:249](../src/scenes/rpg/RpgItemUseGuidance.ts#L249)
2848. 切回浅色操作后，把荧光粉刷拖入通风口。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:252](../src/scenes/rpg/RpgItemUseGuidance.ts#L252)
2849. 靠近通风口，把荧光粉刷拖到栅格上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:254](../src/scenes/rpg/RpgItemUseGuidance.ts#L254)
2850. 先完成后台纸屑显影，灯光控制台随后开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:258](../src/scenes/rpg/RpgItemUseGuidance.ts#L258)
2851. 深色模式只观察追光残影；切回浅色操作后启动灯光控制台。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:261](../src/scenes/rpg/RpgItemUseGuidance.ts#L261)
2852. 从下方靠近控制台，把追光灯遥控器拖到控制面板上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:263](../src/scenes/rpg/RpgItemUseGuidance.ts#L263)
2853. 靠近灯光控制台打开节目单排序，无需把节目单拖到控制台。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:266](../src/scenes/rpg/RpgItemUseGuidance.ts#L266)
2854. 深色观察只记录坐标。切回浅色操作后使用道具。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:274](../src/scenes/rpg/RpgItemUseGuidance.ts#L274)
2855. 假纸条已经固定到鱼钩上并从道具栏移除。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:277](../src/scenes/rpg/RpgItemUseGuidance.ts#L277)
2856. 先在大湖浮排边找到钓鱼竿。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:279](../src/scenes/rpg/RpgItemUseGuidance.ts#L279)
2857. 纸条倒影装饵框
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:279](../src/scenes/rpg/RpgItemUseGuidance.ts#L279)；[src/scenes/rpg/RpgItemUseGuidance.ts:282](../src/scenes/rpg/RpgItemUseGuidance.ts#L282)；[src/scenes/rpg/RpgItemUseGuidance.ts:284](../src/scenes/rpg/RpgItemUseGuidance.ts#L284)
2858. 先划回大湖，再寻找纸条倒影装饵框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:282](../src/scenes/rpg/RpgItemUseGuidance.ts#L282)
2859. 把船划到纸条倒影附近，再把假纸条拖到对应水纹。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:285](../src/scenes/rpg/RpgItemUseGuidance.ts#L285)
2860. 纸条倒影水纹
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:285](../src/scenes/rpg/RpgItemUseGuidance.ts#L285)
2861. 船头磁吸组合位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:291](../src/scenes/rpg/RpgItemUseGuidance.ts#L291)
2862. 先划到黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:291](../src/scenes/rpg/RpgItemUseGuidance.ts#L291)
2863. 船头工具区
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:294](../src/scenes/rpg/RpgItemUseGuidance.ts#L294)
2864. 让船头对准工具区，把钓鱼竿拖到天鹅磁扣旁。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:294](../src/scenes/rpg/RpgItemUseGuidance.ts#L294)
2865. 当前抛竿点位于大湖，先划回大湖。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:297](../src/scenes/rpg/RpgItemUseGuidance.ts#L297)
2866. 可用抛竿点
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:297](../src/scenes/rpg/RpgItemUseGuidance.ts#L297)；[src/scenes/rpg/RpgItemUseGuidance.ts:302](../src/scenes/rpg/RpgItemUseGuidance.ts#L302)；[src/scenes/rpg/RpgItemUseGuidance.ts:303](../src/scenes/rpg/RpgItemUseGuidance.ts#L303)
2867. 先把假纸条拖到钓鱼竿装饵框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:300](../src/scenes/rpg/RpgItemUseGuidance.ts#L300)
2868. 把船划到目标水纹附近后抛竿。深色观察可补充记录位置，直接钓纸条会显示失败原因。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:303](../src/scenes/rpg/RpgItemUseGuidance.ts#L303)
2869. 码头储物柜已经打开。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:308](../src/scenes/rpg/RpgItemUseGuidance.ts#L308)
2870. 返回小码头，储物柜锁孔只在码头区域开放。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:310](../src/scenes/rpg/RpgItemUseGuidance.ts#L310)
2871. 码头储物柜
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:310](../src/scenes/rpg/RpgItemUseGuidance.ts#L310)；[src/scenes/rpg/RpgItemUseGuidance.ts:311](../src/scenes/rpg/RpgItemUseGuidance.ts#L311)；[src/scenes/rpg/RpgItemUseGuidance.ts:312](../src/scenes/rpg/RpgItemUseGuidance.ts#L312)
2872. 返回小码头，靠近柜门，把钥匙拖到锁孔。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:312](../src/scenes/rpg/RpgItemUseGuidance.ts#L312)
2873. 两件道具已组合为临时抄网。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:316](../src/scenes/rpg/RpgItemUseGuidance.ts#L316)
2874. 先取得另一个组合部件。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:319](../src/scenes/rpg/RpgItemUseGuidance.ts#L319)
2875. 回到大湖的浮标组合位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:322](../src/scenes/rpg/RpgItemUseGuidance.ts#L322)
2876. 把尼龙绳或破损网框拖入装配框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:325](../src/scenes/rpg/RpgItemUseGuidance.ts#L325)
2877. 密封饲料盒已经取回。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:330](../src/scenes/rpg/RpgItemUseGuidance.ts#L330)
2878. 浮排系绳下方
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:332](../src/scenes/rpg/RpgItemUseGuidance.ts#L332)；[src/scenes/rpg/RpgItemUseGuidance.ts:333](../src/scenes/rpg/RpgItemUseGuidance.ts#L333)；[src/scenes/rpg/RpgItemUseGuidance.ts:334](../src/scenes/rpg/RpgItemUseGuidance.ts#L334)
2879. 进入浮排直河道，再靠近浮排系绳。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:332](../src/scenes/rpg/RpgItemUseGuidance.ts#L332)
2880. 进入直河道，让船头对准浮排下方，把抄网拖到密封饲料盒上。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:334](../src/scenes/rpg/RpgItemUseGuidance.ts#L334)
2881. 饲料盒已经打开。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:339](../src/scenes/rpg/RpgItemUseGuidance.ts#L339)
2882. 返回浮排直河道，开盒位在浮排上缘。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:341](../src/scenes/rpg/RpgItemUseGuidance.ts#L341)
2883. 浮排开盒位
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:341](../src/scenes/rpg/RpgItemUseGuidance.ts#L341)；[src/scenes/rpg/RpgItemUseGuidance.ts:342](../src/scenes/rpg/RpgItemUseGuidance.ts#L342)
2884. 浮排硬边
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:343](../src/scenes/rpg/RpgItemUseGuidance.ts#L343)
2885. 让船头对准浮排硬边，把密封饲料盒拖到边缘上开启。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:343](../src/scenes/rpg/RpgItemUseGuidance.ts#L343)
2886. 回到大湖的鱼群水纹位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:348](../src/scenes/rpg/RpgItemUseGuidance.ts#L348)
2887. 鱼群水纹
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:348](../src/scenes/rpg/RpgItemUseGuidance.ts#L348)；[src/scenes/rpg/RpgItemUseGuidance.ts:350](../src/scenes/rpg/RpgItemUseGuidance.ts#L350)；[src/scenes/rpg/RpgItemUseGuidance.ts:351](../src/scenes/rpg/RpgItemUseGuidance.ts#L351)
2888. 把饲料颗粒拖入鱼群水纹；深色观察可补充记录位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:351](../src/scenes/rpg/RpgItemUseGuidance.ts#L351)
2889. 黑天鹅
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:357](../src/scenes/rpg/RpgItemUseGuidance.ts#L357)
2890. 让船头对准黑天鹅，把小鲤鱼拖到天鹅面前。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:357](../src/scenes/rpg/RpgItemUseGuidance.ts#L357)
2891. 划到黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:358](../src/scenes/rpg/RpgItemUseGuidance.ts#L358)
2892. 划到黑天鹅围栏区的船头装配位。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:363](../src/scenes/rpg/RpgItemUseGuidance.ts#L363)
2893. 把磁性扣拖到钓鱼竿所在的装配框。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:367](../src/scenes/rpg/RpgItemUseGuidance.ts#L367)
2894. 钓鱼竿当前不在道具栏。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:368](../src/scenes/rpg/RpgItemUseGuidance.ts#L368)
2895. 纸条已经被固定，进入返航追逐。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:372](../src/scenes/rpg/RpgItemUseGuidance.ts#L372)
2896. 纸条本体水纹位于黑天鹅围栏区。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:374](../src/scenes/rpg/RpgItemUseGuidance.ts#L374)
2897. 把磁性钓鱼竿拖入纸条本体水纹；深色观察可补充记录位置。
   来源：[src/scenes/rpg/RpgItemUseGuidance.ts:377](../src/scenes/rpg/RpgItemUseGuidance.ts#L377)
2898. 当前{{current.label}}。点击切换到{{next.label}}
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:25](../src/scenes/rpg/RpgRealityModeToggle.tsx#L25)
2899. {{current.shortHint}} 点击切换到{{next.label}}。
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:26](../src/scenes/rpg/RpgRealityModeToggle.tsx#L26)
2900. 当前模式
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:34](../src/scenes/rpg/RpgRealityModeToggle.tsx#L34)
2901. 切换：
   来源：[src/scenes/rpg/RpgRealityModeToggle.tsx:36](../src/scenes/rpg/RpgRealityModeToggle.tsx#L36)
2902. 紫云碧峰
   来源：[src/scenes/rpg/ZijingangCampusLayout.ts:54](../src/scenes/rpg/ZijingangCampusLayout.ts#L54)
2903. 东区大食堂
   来源：[src/scenes/rpg/ZijingangCampusLayout.ts:73](../src/scenes/rpg/ZijingangCampusLayout.ts#L73)

