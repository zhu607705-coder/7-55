# 《7:55》中文文本修订审阅表（2026-10-18）

基线：`c47a8465bfea51310069979c79d7d0465d1eaed8`（PR149集成分支）。本PR只改正式Godot显示文本及其必需兼容。

共213项明确提议：172项直接采纳、17项适配采纳、4项原文一致保留、20项暂不采纳。对应195个source字段、3个native序幕字段和29个脚本显示目标（27组基础替换＋2处同一微信问答/回退同步）。

## 生成和音频边界

- `data/zh_text_revisions.json`按文件、路径和旧值严格匹配；`sync_source.mjs`每次从原src/data复制后自动应用，因此不会被下一次同步冲掉
- 原src/data、英文配音词、音频文件、voice/speaker ID、clip长度、timeline事件/offset/顺序保持不变
- 新旧第三章字幕均解析到原voice key；原37条别名保留
- 已配音的剧场保留原节拍。无配音图书馆/022长句采用原时长与阅读时间较大者，继续/暂停/跳过行为保留
- 页面显示作必要换行和字号适配；无新增谜题答案、条件、存档字段或权限

## 每项提议与决策

| 提议ID | 决策 | 附件原提议 | 实际采用句 | 理由/证据 |
|---|---|---|---|---|
| table-wake_narration | 适配采纳 | 距离早八点名只剩五分钟。不得不说，你还敢赖床，心理素质真硬。 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬。 | 只将“点名只剩五分钟”改为“早八快上课了”，避免把08:00上课与07:55签到截止混为一谈 |
| table-wake_flash | 采纳 | 还睡？！早八要迟到了！！ | 还睡？！早八要迟到了！！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-xy_attack | 采纳 | 等等——人还在被窝里就想隔空签到？想得美！这分我今天扣定了！ | 等等——人还在被窝里就想隔空签到？想得美！这分我今天扣定了！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-xy_laugh | 采纳 | 签到码给你拆碎咯，慢慢找去吧哈哈哈！ | 签到码给你拆碎咯，慢慢找去吧哈哈哈！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-sys_balance | 采纳 | 校园卡余额：0.06元。这点钱连起床气都买不起。 | 校园卡余额：0.06元。这点钱连起床气都买不起。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-sys_net_try | 采纳 | ZJUWLAN 正在疯狂转圈。它尽力了，你也尽力了。 | ZJUWLAN 正在疯狂转圈。它尽力了，你也尽力了。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-sys_no_money | 未采纳 | 别切移动数据了，你话费早停机了。 | 保留现稿 | 现体艺明确要求切换移动数据；新稿话费停机且禁止切移动数据会给出错误操作指导；godot_native/scripts/chapters/chapter1_2.gd _chapter_one |
| table-tiyi_47 | 采纳 | 体艺打卡：47/48次。离及格永远只差最后一次，经典的绝望。 | 体艺打卡：47/48次。离及格永远只差最后一次，经典的绝望。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-gear_pickup | 采纳 | 哟，从设置图标上抠下来一个生锈的齿轮？ | 哟，从设置图标上抠下来一个生锈的齿轮？ | 按稳定键与原文逐项对应；只改中文显示 |
| table-prologue_narrator_intro | 适配采纳 | 噗……不好意思啊，没忍住。07:55 已过，签到通道关闭！看来你只能认命爬起来去教室解释了。祝你好运咯，同学，我下班了！ | 噗……不好意思啊，没忍住。签到又报错了！看来你只能认命爬起来去教室解释了。祝你好运咯，同学，我下班了！ | 当前0798已提交成功后因经纬度报错进入拦截；改为“签到又报错了”，不把失败原因写成通道关闭 |
| table-prologue_narrator_caught | 采纳 | 喂！你拽我弹窗干什么？！快松手！要未响应了！ | 喂！你拽我弹窗干什么？！快松手！要未响应了！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-player-threat | 适配采纳 | 玩家：帮我把签到补上。 / 玩家：不然我就一直死按着不放，大家一起死机，跟我的平时分同归于尽。 | 玩家：帮我补签到！ / 玩家：不帮就一起死机！ | 两句玩家威胁各处于约1100ms固定无声窗口；压缩保留补签与死机威胁，避免移动后续既有bargain配音cue |
| table-prologue_narrator_bargain | 采纳 | 行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！ | 行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_found_intro | 采纳 | ……服了你了。为了不陪你一起蓝屏，我认栽。 | ……服了你了。为了不陪你一起蓝屏，我认栽。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_confession | 采纳 | 但丑话说在前头，我只是个前端提示音，没有直接篡改教务考勤的权限。 | 但丑话说在前头，我只是个前端提示音，没有直接篡改教务考勤的权限。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_friend | 采纳 | 不过……我在图书馆有个老熟人，她手里有底层接口，或许能帮你把时间改回去。 | 不过……我在图书馆有个老熟人，她手里有底层接口，或许能帮你把时间改回去。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_library | 采纳 | 想保住你的平时分，现在就得去基础馆一楼找她。 | 想保住你的平时分，现在就得去基础馆一楼找她。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_inventory_demand | 采纳 | 来，先把你的道具栏调出来，咱们准备动身。 | 来，先把你的道具栏调出来，咱们准备动身。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_inventory_missing | 采纳 | ……等等，你连道具栏都没加载？你不会指望我徒手给你黑进系统吧！ | ……等等，你连道具栏都没加载？你不会指望我徒手给你黑进系统吧！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_system_just_find_it | 未采纳 | 快去屏幕角落里把它翻出来！ | 保留现稿 | 新稿屏幕角落寻找与实际寝室右侧书桌拾取校园卡恢复道具栏不符；godot_native/scripts/chapters/chapter1_2.gd c2_recover_card |
| table-act2_system_departure | 采纳 | 总算找着了。行，那赶紧操作你床上的身体出门吧！ | 总算找着了。行，那赶紧操作你床上的身体出门吧！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-act1_locked_entry | 采纳 | ……好吧，看来你不仅没起床，连自己身体的控制权都还没登录。先去认证一下身份吧。 | ……好吧，看来你不仅没起床，连自己身体的控制权都还没登录。先去认证一下身份吧。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_character_cannot_hear | 采纳 | 别戳他了，他听不见。没绑定姓名和学号之前，他就是个没加载完的默认建模。 | 别戳他了，他听不见。没绑定姓名和学号之前，他就是个没加载完的默认建模。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act1_identity_verified | 适配采纳 | 学号核验通过。好消息：你想起自己叫什么了。坏消息：寝室还是断网。 | 学号核验通过。好消息：你想起自己叫什么了。坏消息：你的身体还没联网。 | 网络在手机上可切换；将“寝室断网”收窄为身体未联网，避免误导操作 |
| table-act1_phone_linked | 采纳 | 信号接通了。拿学号当手机号拨通自己，也就这破系统干得出来。 | 信号接通了。拿学号当手机号拨通自己，也就这破系统干得出来。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_push_triangle_collected | 采纳 | 拆下来一个播放键三角。再去天气页接滴雨水试试？ | 拆下来一个播放键三角。再去天气页接滴雨水试试？ | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_weather_water_collected | 采纳 | 雨水到手。去看看导师头像旁边那根卡死的竖线，泡软了应该能抠下来。 | 雨水到手。去看看导师头像旁边那根卡死的竖线，泡软了应该能抠下来。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_mentor_line_stuck | 采纳 | 这根分割线焊得死死的。毕竟是导师的对话框，连排版都透着一股压迫感。 | 这根分割线焊得死死的。毕竟是导师的对话框，连排版都透着一股压迫感。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_right_arrow_assembled | 采纳 | 三角加横杆，拼成右移箭头了。去看看你的余额小数点能不能往右挪挪？ | 三角加横杆，拼成右移箭头了。去看看你的余额小数点能不能往右挪挪？ | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_gamepad_purchase_rejected | 采纳 | 全身上下六分钱，还想跟98卖家分一百期买手柄？人家直接把你拒了。 | 全身上下六分钱，还想跟98卖家分一百期买手柄？人家直接把你拒了。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act2_balance_shifted | 采纳 | 小数点右移两位！0.06 秒变 6.00 元——趁财务系统还没反应过来，赶紧去98把二手手柄付了！ | 小数点右移两位！0.06 秒变 6.00 元——趁财务系统还没反应过来，赶紧去98把二手手柄付了！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-act1_controls_installed | 未采纳 | 二手手柄装好了，但腿还是迈不开——体艺App还没开启计步许可呢。 | 保留现稿 | 现顺序先启动体艺再买手柄；新稿手柄装好而体艺未开颠倒因果；godot_native/scripts/chapters/chapter1_2.gd:467-548 |
| table-act1_movement_enabled | 采纳 | 体艺打卡启动！恭喜，你终于获得了在自己寝室里合法走路的权限。 | 体艺打卡启动！恭喜，你终于获得了在自己寝室里合法走路的权限。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-act1_required_item_collected | 未采纳 | 《7:55》卡带到手。顺便把寝室四个角落的打卡点都踩完，不然体艺不让你出门。 | 保留现稿 | 卡带与四角开门不是当前正式门禁条件；现需手动一步和座位预约；godot_native/scripts/chapters/chapter1_2.gd:523-548 |
| table-act1_map_completed | 未采纳 | 四个打卡点踩满！菜单解锁，寝室门禁终于放行了。 | 保留现稿 | 四角踩满解锁门禁不是当前正式条件；godot_native/scripts/chapters/chapter1_2.gd:523-548 |
| table-act2_exit_ready | 采纳 | 走吧，去基础图书馆一楼，找 022 号座位！ | 走吧，去基础图书馆一楼，找 022 号座位！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_queue_system | 采纳 | 系统：连一张逃跑的异常纸条，进了浙大食堂都得老老实实排队。 | 系统：连一张逃跑的异常纸条，进了浙大食堂都得老老实实排队。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_labor_system | 未采纳 | 系统：毕竟你卡里只剩六分钱，而阿姨刚好缺个收盘子的苦力。 | 保留现稿 | 买手柄后600分扣600分，余额为0；新稿仍剩六分钱错误；godot_native/scripts/chapters/chapter1_2.gd c2_purchase_gamepad |
| table-c3_canteen_bun_system | 采纳 | 系统：这包子连馅儿都是实的，藏不进纸条。再说了，纸条也不吃碳水。 | 系统：这包子连馅儿都是实的，藏不进纸条。再说了，纸条也不吃碳水。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_breakfast_system | 采纳 | 系统：没有线索，只有碳水。恭喜你获得了一份平平无奇的早饭。 | 系统：没有线索，只有碳水。恭喜你获得了一份平平无奇的早饭。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_paper_chicken_system | 采纳 | 系统：“纸包鸡”。听名字，前两个字就跟我们的目标很有缘分。 | 系统：“纸包鸡”。听名字，前两个字就跟我们的目标很有缘分。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_packaging_system | 采纳 | 系统：我们要的是外面那层纸，里面的鸡肉纯属赠品。 | 系统：我们要的是外面那层纸，里面的鸡肉纯属赠品。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_cold_clue_system | 采纳 | 系统：粥还烫嘴，但线索已经断了。换个窗口找找吧。 | 系统：粥还烫嘴，但线索已经断了。换个窗口找找吧。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_worldview_system | 采纳 | 系统：打住，别在这种地方强行发散思维。 | 系统：打住，别在这种地方强行发散思维。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_paper_impact_narrator | 适配采纳 | 纸条撞在玻璃门上弹回食堂，抖落了一地蓝色的数据残影。 | 纸条撞回食堂，抖落了一地蓝色的数据残影。 | 食堂防守由餐车拦截纸条，删除未实现的玻璃门碰撞对象，保留蓝色残影描述 |
| table-c3_canteen_paper_angry_narrator | 采纳 | 纸条急眼了，决定直接插队硬闯取餐口！ | 纸条急眼了，决定直接插队硬闯取餐口！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_canteen_self_service_system | 采纳 | 系统：现在的食堂自助取餐，已经进化到全自动打架了吗？ | 系统：现在的食堂自助取餐，已经进化到全自动打架了吗？ | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_bike_human_speed_system | 采纳 | 系统：靠你这两条没吃早饭的腿，是追不上风的。找辆共享单车吧。 | 系统：靠你这两条没吃早饭的腿，是追不上风的。找辆共享单车吧。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_bike_gpa_system | 采纳 | 系统：人家只是一张纸，可没有挂科扣绩点的心理负担，当然飞得快。 | 系统：人家只是一张纸，可没有挂科扣绩点的心理负担，当然飞得快。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_bike_no_money_system | 采纳 | 系统：“余额不足”这四个字，今天真是刻进你DNA里了。先去帮阿姨收盘子赚钱吧。 | 系统：“余额不足”这四个字，今天真是刻进你DNA里了。先去帮阿姨收盘子赚钱吧。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_theater_failure_narrator | 采纳 | 旁白：摔得十分干脆，连体面都没留。 | 旁白：摔得十分干脆，连体面都没留。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_theater_logic_system | 采纳 | 系统：彩排临时改过场次顺序，纸质节目单早就过时了。得看现场的痕迹。 | 系统：彩排临时改过场次顺序，纸质节目单早就过时了。得看现场的痕迹。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_theater_celebrate_system | 采纳 | 系统：别高兴得太早，把纸条翻过来看看背面。 | 系统：别高兴得太早，把纸条翻过来看看背面。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_theater_substitute_system | 采纳 | 系统：背面印着剧社的道具编号。这是张舞台替身，真家伙早就趁乱溜出剧场了。 | 系统：背面印着剧社的道具编号。这是张舞台替身，真家伙早就趁乱溜出剧场了。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_no_trail_system | 采纳 | 系统：跟丢了。这次它学精了，沿路半点蓝光都没漏。 | 系统：跟丢了。这次它学精了，沿路半点蓝光都没漏。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_forum_system | 采纳 | 系统：遇事不决上 98。发个悬赏帖，让全校的夜猫子帮你找。 | 系统：遇事不决上 98。发个悬赏帖，让全校的夜猫子帮你找。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_cc98_system | 采纳 | 系统：98 老哥给出了极其严谨的排除法：至少没飞进厕所。 | 系统：98 老哥给出了极其严谨的排除法：至少没飞进厕所。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_catalog_system | 采纳 | 系统：馆藏线索指向湖岸与倒影……看来这张纸条还挺讲究意境。 | 系统：馆藏线索指向湖岸与倒影……看来这张纸条还挺讲究意境。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_map_system | 采纳 | 系统：三条线索拼齐——目标锁定，启真湖！ | 系统：三条线索拼齐——目标锁定，启真湖！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_reflection_system | 采纳 | 系统：它没泡在水里，是卡在湖面的倒影图层里了。 | 系统：它没泡在水里，是卡在湖面的倒影图层里了。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_swimming_system | 采纳 | 系统：别想不开往水里跳，你体艺游泳课还没修呢。找船过去。 | 系统：别想不开往水里跳，你体艺游泳课还没修呢。找船过去。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_gone_system | 采纳 | 系统：水波一晃，它又缩回深色倒影里了。 | 系统：水波一晃，它又缩回深色倒影里了。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_sign_system | 采纳 | 系统：岸边那块旧指示牌木头不错，拆下来正好当右船桨使。 | 系统：岸边那块旧指示牌木头不错，拆下来正好当右船桨使。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_hiding_system | 采纳 | 系统：锁定坐标了！它就猫在这片倒影底下。 | 系统：锁定坐标了！它就猫在这片倒影底下。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_display_system | 未采纳 | 系统：光靠捞是捞不着的，得下个套把它钓出来。 | 保留现稿 | 新稿把诱饵描述为直接钓出本体；当前诱饵用于钥匙/网框，本体另需组合竿和节奏钓取；godot_native/scripts/chapters/c3_lake.gd; src/data/chapter3-qizhen-lake.content.json toolChain |
| table-c3_qizhen_fake_system | 采纳 | 系统：把刚才在剧场抓到的那张假替身挂在鱼钩上！ | 系统：把刚才在剧场抓到的那张假替身挂在鱼钩上！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_ego_system | 采纳 | 系统：一个占了三天座位的老赖，绝对容不下冒牌货顶替它的位置。 | 系统：一个占了三天座位的老赖，绝对容不下冒牌货顶替它的位置。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_atmosphere_system | 采纳 | 系统：偏了！你这杆甩下去，除了惊起两圈水波啥也没钓着。 | 系统：偏了！你这杆甩下去，除了惊起两圈水波啥也没钓着。 | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_taunt_system | 采纳 | 系统：瞧见没，水底下的正主正隔着倒影看你笑话呢。对准点！ | 系统：瞧见没，水底下的正主正隔着倒影看你笑话呢。对准点！ | 按稳定键与原文逐项对应；只改中文显示 |
| table-c3_qizhen_now_system | 未采纳 | 系统：上钩了！它从倒影里炸出来了，快切回浅色模式！ | 保留现稿 | 新稿命令切全局浅色模式；当前句意是纸条进入浅色可抓状态，不能混同玩家模式；src/data/chapter3-qizhen-lake.content.json / godot_native/scripts/chapters/c3_lake.gd |
| table-c3_qizhen_grab_system | 采纳 | 系统：趁现在，按住它！ | 系统：趁现在，按住它！ | 按稳定键与原文逐项对应；只改中文显示 |
| chat-T00655 | 采纳 | 朋友：速来！老头突然开始点名了，学在浙大雷达签到！ | 朋友：速来！老头突然开始点名了，学在浙大雷达签到！ | 按稳定键与原文逐项对应；只改中文显示 |
| chat-T00531 | 采纳 | 朋友：签上了吗？？<br>玩家：没赶上。但我刚把弹窗卡死了，正在逼系统给我改后台。<br>朋友：？你没睡醒吧 | 朋友：签上了吗？？<br>玩家：没赶上。但我刚把弹窗卡死了，正在逼系统给我改后台。<br>朋友：？你没睡醒吧 | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-1 | 采纳 | 玩家：这就是基础馆？你说的那个朋友在哪？ | 玩家：这就是基础馆？你说的那个朋友在哪？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-2 | 采纳 | 系统：在入馆闸机最后的登记记录里。她一直待在一层书库。 | 系统：在入馆闸机最后的登记记录里。她一直待在一层书库。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-3 | 采纳 | 玩家：她是这里的图书管理员？ | 玩家：她是这里的图书管理员？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-4 | 采纳 | 系统：不是。她不管借书，也不在教职工名册里。 | 系统：不是。她不管借书，也不在教职工名册里。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-5 | 采纳 | 玩家：那是谁？总不能是馆长吧。 | 玩家：那是谁？总不能是馆长吧。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-6 | 采纳 | 系统：是一层书库的 022 号座位。 | 系统：是一层书库的 022 号座位。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-7 | 采纳 | 玩家：……你是说，你的朋友是一张桌子？ | 玩家：……你是说，你的朋友是一张桌子？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-8 | 采纳 | 系统：准确地说，是绑定在 022 号座位上的旧版选座终端。上次系统升级前，全校的考勤与选座时间戳都归她管。 | 系统：准确地说，是绑定在 022 号座位上的旧版选座终端。上次系统升级前，全校的考勤与选座时间戳都归她管。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-9 | 采纳 | 玩家：那直接过去找她就行？ | 玩家：那直接过去找她就行？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-entered-10 | 采纳 | 系统：她的入馆记录停在三天前，一直没签退。先刷闸机进去看看情况。 | 系统：她的入馆记录停在三天前，一直没签退。先刷闸机进去看看情况。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-occupied-1 | 原文一致保留 | 书包：…… | 书包：…… | 附件句子与当前正式原文完全一致，无需写入替换 |
| library-occupied-2 | 采纳 | 旁白：022 号座位上赫然盘踞着一个鼓鼓囊囊的书包，上面贴着一张便签纸：“本人离开三分钟，马上回来”。 | 旁白：022 号座位上赫然盘踞着一个鼓鼓囊囊的书包，上面贴着一张便签纸：“本人离开三分钟，马上回来”。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-occupied-3 | 采纳 | 玩家：……被占座了。而且一个书包怎么连选座终端的屏幕都挡死了？ | 玩家：……被占座了。而且一个书包怎么连选座终端的屏幕都挡死了？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-occupied-4 | 采纳 | 系统：别硬拽！馆内选座系统判定它还在“三分钟暂离保护期”内，强行挪动会触发警报。去 CC98 搜搜怎么破这个死循环。 | 系统：别硬拽！馆内选座系统判定它还在“三分钟暂离保护期”内，强行挪动会触发警报。去 CC98 搜搜怎么破这个死循环。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-rule-1 | 采纳 | 系统：755 号书架背面的旧版《三分钟离座法》找到了。 | 系统：755 号书架背面的旧版《三分钟离座法》找到了。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-rule-2 | 采纳 | 玩家：看你这语气，流程很阴间？ | 玩家：看你这语气，流程很阴间？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-rule-3 | 采纳 | 系统：非常官僚。要想强制清退超时占座物，必须集齐三份纸质证明： | 系统：非常官僚。要想强制清退超时占座物，必须集齐三份纸质证明： | 按稳定键与原文逐项对应；只改中文显示 |
| library-rule-4 | 采纳 | 系统：第一，你本人的到馆时间证明；第二，022 座位的小票；第三……“该书包不是人类”的身份核验公章。 | 系统：第一，你本人的到馆时间证明；第二，022 座位的小票；第三……“该书包不是人类”的身份核验公章。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-rule-5 | 采纳 | 玩家：……？我要去向图书馆证明一个双肩包不是人？！ | 玩家：……？我要去向图书馆证明一个双肩包不是人？！ | 按稳定键与原文逐项对应；只改中文显示 |
| library-rule-6 | 采纳 | 系统：因为在后台数据库里，这个书包已经连续刷了三天全勤，系统默认它是模范读者。 | 系统：因为在后台数据库里，这个书包已经连续刷了三天全勤，系统默认它是模范读者。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-frontdesk-1 | 采纳 | 前台：同学你好，办什么业务？ | 前台：同学你好，办什么业务？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-frontdesk-2 | 采纳 | 玩家：我想举报 022 号座位的占座书包。 | 玩家：我想举报 022 号座位的占座书包。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-frontdesk-3 | 采纳 | 前台：清退占座需先提交《占用物非本人证明》。 | 前台：清退占座需先提交《占用物非本人证明》。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-frontdesk-4 | 采纳 | 玩家：不是，它就是个帆布包，你抬头看一眼不就知道了？ | 玩家：不是，它就是个帆布包，你抬头看一眼不就知道了？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-frontdesk-5 | 采纳 | 前台：不好意思，选座系统只认公章，不认肉眼。在系统里它有合法占座权。 | 前台：不好意思，选座系统只认公章，不认肉眼。在系统里它有合法占座权。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-stamp-1 | 采纳 | 系统：公章盖好了。“书包不具备自然人学籍”核验通过。 | 系统：公章盖好了。“书包不具备自然人学籍”核验通过。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-stamp-2 | 采纳 | 玩家：为了赶一节早八，我今天办的证明比退学手续还全。 | 玩家：为了赶一节早八，我今天办的证明比退学手续还全。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-evidence-1 | 采纳 | 玩家：三份证明终于跑齐了，现在能把书包清走了吧？ | 玩家：三份证明终于跑齐了，现在能把书包清走了吧？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-evidence-2 | 适配采纳 | 系统：还差最后一步“舆论监督”。图书馆 App 的清退接口平时是锁死的，只有当曝光帖冲上 CC98 十大第一，才会自动触发受理口令。 | 系统：还差最后一步“舆论监督”。用四位受理口令完成确认，帖子冲上 CC98 十大第一，清退入口才会开放。 | 实际先用四位口令完成bd核验，再到十大第一并开放恢复入口；纠正附件倒置因果，不改3027 |
| library-evidence-3 | 采纳 | 玩家：还要我去发帖控评？那个“bd”又是什么？ | 玩家：还要我去发帖控评？那个“bd”又是什么？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-evidence-4 | 采纳 | 系统：98 黑话，“帮顶”的意思。你按证据栏的顺序给那几层带数字的楼层点 bd，楼层的数字就会拼成四位受理口令。 | 系统：98 黑话，“帮顶”的意思。你按证据栏的顺序给那几层带数字的楼层点 bd，楼层的数字就会拼成四位受理口令。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-evicted-1 | 采纳 | 图书馆提示：022 号座位清退申请已通过。请占座物品立即离开座位。 | 图书馆提示：022 号座位清退申请已通过。请占座物品立即离开座位。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-evicted-2 | 采纳 | 图书馆提示：逾期未领的书包将移交失物招领处。 | 图书馆提示：逾期未领的书包将移交失物招领处。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-evicted-3 | 采纳 | 书包：本人……马上回来。 | 书包：本人……马上回来。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-evicted-4 | 采纳 | 玩家：你到底什么时候回来？ | 玩家：你到底什么时候回来？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-evicted-5 | 原文一致保留 | 书包：三分钟。 | 书包：三分钟。 | 附件句子与当前正式原文完全一致，无需写入替换 |
| library-evicted-6 | 采纳 | 系统：别信它。这张纸条上的“三分钟”，已经在这儿卡了整整三天了。 | 系统：别信它。这张纸条上的“三分钟”，已经在这儿卡了整整三天了。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-1 | 采纳 | 022：……呼，压死我了。你终于坐下了。 | 022：……呼，压死我了。你终于坐下了。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-2 | 采纳 | 玩家：你就是系统说的那个朋友？ | 玩家：你就是系统说的那个朋友？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-3 | 采纳 | 系统：好久不见。你以前可不会被一个帆布包封印三天。 | 系统：好久不见。你以前可不会被一个帆布包封印三天。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-4 | 采纳 | 022：你以前也不会为了保一个迟到学生的平时分，亲自跑来求我。 | 022：你以前也不会为了保一个迟到学生的平时分，亲自跑来求我。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-5 | 采纳 | 系统：少叙旧了，快帮他查查今天早八的签到记录，还能从后台改回 07:55 吗？ | 系统：少叙旧了，快帮他查查今天早八的签到记录，还能从后台改回 07:55 吗？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-6 | 采纳 | 022：稍等，我调一下日志…… | 022：稍等，我调一下日志…… | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-7 | 采纳 | 玩家：有戏吗？ | 玩家：有戏吗？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-8 | 采纳 | 022：糟了。你的签到记录不在教务服务器里——它被刚才书包上那张便签纸粘走了！ | 022：糟了。你的签到记录不在教务服务器里——它被刚才书包上那张便签纸粘走了！ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-9 | 未采纳 | 玩家：被占座纸条粘走了？！ | 保留现稿 | 新增玩家插话无原槽位；不新增/移动对白或改变触发节拍；godot_native/scripts/presentation/c3_scene_session.gd fixed dialogue slices |
| library-022-10 | 采纳 | 022：那张写着“马上回来”的纸条在座位上卡了太久，变成了吞噬时间的异常缓存。它把你的签到时间锁死在 07:55，刚才趁书包被清退，顺着网线溜出去了。 | 022：那张写着“马上回来”的纸条在座位上卡了太久，变成了吞噬时间的异常缓存。它把你的签到时间锁死在 07:55，刚才趁书包被清退，顺着网线溜出去了。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-11 | 采纳 | 玩家：那它往哪跑了？我怎么一点没看见？ | 玩家：那它往哪跑了？我怎么一点没看见？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-12 | 采纳 | 022：在正常的浅色界面下，你当然看不见底层缓存的溢出轨迹。 | 022：在正常的浅色界面下，你当然看不见底层缓存的溢出轨迹。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-13 | 采纳 | 系统：直接把权限开给他吧，别卖关子了。 | 系统：直接把权限开给他吧，别卖关子了。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-14 | 采纳 | 022：我帮你解锁了“深色观察”模式。切到深色界面，你就能看见纸条残留的蓝光轨迹了。 | 022：我帮你解锁了“深色观察”模式。切到深色界面，你就能看见纸条残留的蓝光轨迹了。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-15 | 采纳 | 玩家：这不就是手机的暗黑模式吗？ | 玩家：这不就是手机的暗黑模式吗？ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-16 | 采纳 | 022：在你们眼里是护眼模式，在我们眼里是底层调试视图。 | 022：在你们眼里是护眼模式，在我们眼里是底层调试视图。 | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-17 | 采纳 | 系统：蓝光动了！快追，别让那张纸条跑出图书馆！ | 系统：蓝光动了！快追，别让那张纸条跑出图书馆！ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-18 | 原文一致保留 | 纸条：本人马上回来。 | 纸条：本人马上回来。 | 附件句子与当前正式原文完全一致，无需写入替换 |
| library-022-19 | 采纳 | 玩家：卧槽，纸条成精说话了？！ | 玩家：卧槽，纸条成精说话了？！ | 按稳定键与原文逐项对应；只改中文显示 |
| library-022-20 | 采纳 | 系统：那不是它在说话，是原主人三天前留下的语音残影！快追！ | 系统：那不是它在说话，是原主人三天前留下的语音残影！快追！ | 按稳定键与原文逐项对应；只改中文显示 |
| canteen-drink-1 | 采纳 | 玩家：呕……食堂这是把板蓝根倒进气泡水里了？！ | 玩家：呕……食堂这是把板蓝根倒进气泡水里了？！ | 按稳定键与原文逐项对应；只改中文显示 |
| canteen-drink-2 | 采纳 | 系统：恭喜你成为今日第一位勇士。试饮无工伤补贴。 | 系统：恭喜你成为今日第一位勇士。试饮无工伤补贴。 | 按稳定键与原文逐项对应；只改中文显示 |
| canteen-drink-3 | 采纳 | 玩家：前面排队的怎么全散了？ | 玩家：前面排队的怎么全散了？ | 按稳定键与原文逐项对应；只改中文显示 |
| canteen-drink-4 | 未采纳 | 系统：看到你喝完的表情，大家非常默契地放弃了尝鲜。路让出来了，快去点餐机！ | 保留现稿 | 队伍后退由宣传板摆放正确新品触发，不由喝错配饮料表情触发；src/data/chapter3-canteen.content.json drinks.promoDropHint; godot_native/scripts/chapters/c3_canteen.gd |
| canteen-chicken-1 | 适配采纳 | 玩家：刚才飞过去那团长翅膀的东西……是我点的纸包鸡？！ | 玩家：纸包鸡……飞了？！ | 该演出固定字幕窗口780ms；压缩中文表达，保留纸包鸡飞起意思及原时轴 |
| canteen-chicken-2 | 适配采纳 | 系统：鸡肉留着，外面的包装纸已经被纸条策反了！拦住它！ | 系统：包装纸被纸条策反了！ | 该演出固定字幕窗口780ms；压缩中文表达，保留包装纸被策反意思及原时轴 |
| lake-search-1 | 采纳 | 玩家：剧场外面连个鬼影都没有，它往哪边飞了？ | 玩家：剧场外面连个鬼影都没有，它往哪边飞了？ | 按稳定键与原文逐项对应；只改中文显示 |
| lake-search-2 | 未采纳 | 系统：地面干了，水迹到门口就断了。 | 保留现稿 | 水迹在湖畔一侧中断，不是剧场门口；src/data/chapter3-qizhen-lake.content.json locationSearch.approachTransition.visualBeats |
| lake-search-3 | 采纳 | 玩家：追了大半个校园，不会还要我发帖寻物吧？ | 玩家：追了大半个校园，不会还要我发帖寻物吧？ | 按稳定键与原文逐项对应；只改中文显示 |
| lake-search-4 | 未采纳 | 系统：别小看群众的力量。看看 98 路况帖，再查查刚才替身纸条背面的馆藏索书号。 | 保留现稿 | 定位线索道具是湿节目单；新稿替身纸背面索书号不符；godot_native/scripts/chapters/c3_lake.gd locationSearch |
| lake-search-5 | 采纳 | 系统：论坛目击帖缩小了范围：就在有桥的水域附近。 | 系统：论坛目击帖缩小了范围：就在有桥的水域附近。 | 按稳定键与原文逐项对应；只改中文显示 |
| lake-search-6 | 适配采纳 | 玩家：有桥有水……范围还是太大了，再去查查馆藏记录怎么说。 | 玩家：有桥有水……范围还是太大了，还得找点能对上地点的线索。 | CC98/馆藏/微信三证可任意顺序获取，去掉“再去查馆藏”的固定顺序指令 |
| lake-search-7 | 适配采纳 | 玩家：笔记上写着“唯有在静水倒影中可见真身”……看来得挑个能照出倒影的湖面。 | 玩家：馆藏记录写着“当前页码只出现在倒影中”……看来得找个能照出倒影的湖面。 | 将不存在的笔记引文换成真实馆藏备注“当前页码只出现在倒影中” |
| lake-search-8 | 未采纳 | 系统：线索对上了。再看看微信群里有没有最新动静。 | 保留现稿 | 三条线索可任意顺序取得；不能在馆藏后强制指向微信；godot_native/scripts/chapters/c3_lake.gd c3_lake_search_* |
| lake-search-9 | 采纳 | 玩家：逆风扩散的水纹……走，去启真湖！ | 玩家：逆风扩散的水纹……走，去启真湖！ | 按稳定键与原文逐项对应；只改中文显示 |
| lake-search-10 | 采纳 | 系统：已在地图上标出启真湖码头。 | 系统：已在地图上标出启真湖码头。 | 按稳定键与原文逐项对应；只改中文显示 |
| lake-search-11 | 采纳 | 玩家：码头边拴着一艘皮划艇，但船上连桨都没有。 | 玩家：码头边拴着一艘皮划艇，但船上连桨都没有。 | 按稳定键与原文逐项对应；只改中文显示 |
| lake-search-12 | 未采纳 | 系统：在附近找两件趁手的扁平物件当船桨。不过在这之前—— | 保留现稿 | 先找齐装备再登船；新句不过在这之前与后一句先上船组合颠倒顺序；src/data/chapter3-qizhen-lake.content.json dock.boardPrompt |
| lake-search-13 | 采纳 | 玩家：得先踩稳了跨上去，别一脚踩翻进湖里。 | 玩家：得先踩稳了跨上去，别一脚踩翻进湖里。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-prologue-1 | 未采纳 | 我：鱼线又断了！ | 保留现稿 | 实际断开磁性连接件，不是鱼线；godot_native/data/native/chapter4-native-source.json; godot_native/scripts/chapters/c3_lake.gd magneticAttachmentBroken |
| chapter4-prologue-2 | 采纳 | 旁白：湖水没有留住它。晚风裹着那张纸条，一路吹进了还亮着灯的段永平教学楼。 | 旁白：湖水没有留住它。晚风裹着那张纸条，一路吹进了还亮着灯的段永平教学楼。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-prologue-3 | 采纳 | 保洁员：哎同学当心脚下，刚拖的地！你追的那张纸片往大厅里头飞了。 | 保洁员：哎同学当心脚下，刚拖的地！你追的那张纸片往大厅里头飞了。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-prologue-4 | 采纳 | 保安：同学，北教马上二十三点清楼了啊，拿完东西赶紧出来！ | 保安：同学，北教马上二十三点清楼了啊，拿完东西赶紧出来！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-1 | 适配采纳 | 系统：视野已同步！那张签到纸条正往大厅公告栏上撞，快按住它！ | 系统：视野已同步！那张签到纸条正往大厅公告栏上撞，快抓住它！ | 纸条落公告栏后为单次交互抓取，不是长按机制；“按住”改“抓住” |
| chapter4-opening-2 | 采纳 | 玩家：——抓到了！这下看你还往哪跑！ | 玩家：——抓到了！这下看你还往哪跑！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-3 | 采纳 | 系统：正在将签到纸条写入教务考勤服务器…… | 系统：正在将签到纸条写入教务考勤服务器…… | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-4 | 采纳 | 系统：……提交失败。当前外部标准时间：22:45。 | 系统：……提交失败。当前外部标准时间：22:45。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-5 | 采纳 | 系统：早八考勤截止时间：07:55。超时 14 小时 50 分钟，系统拒绝接收。 | 系统：早八考勤截止时间：07:55。超时 14 小时 50 分钟，系统拒绝接收。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-6 | 采纳 | 玩家：怎么可能 22:45？！你看我手机屏幕，上面明明还停在 07:55:23！ | 玩家：怎么可能 22:45？！你看我手机屏幕，上面明明还停在 07:55:23！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-7 | 采纳 | 系统：那是你手机被纸条卡死的本地时间。为了追这张纸，你从早八一路跑到了熄灯清楼。 | 系统：那是你手机被纸条卡死的本地时间。为了追这张纸，你从早八一路跑到了熄灯清楼。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-8 | 采纳 | 系统：你的签到记录确实找回来了，但那节早八……十四个小时前就已经下课了。 | 系统：你的签到记录确实找回来了，但那节早八……十四个小时前就已经下课了。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-opening-9 | 未采纳 | 玩家：……所以我跑了一整天，最后还是算旷课？ | 保留现稿 | 新增问答没有原槽位；保持既有行数、角色与触发节拍；src/data/chapter4-755.content.json dialogues.opening.external_time_rejected |
| chapter4-opening-10 | 未采纳 | 系统：按教务处的时间源，是的。除非……我们不用教务处的时间源。 | 保留现稿 | 新增问答没有原槽位；保持既有行数、角色与触发节拍；src/data/chapter4-755.content.json dialogues.opening.external_time_rejected |
| chapter4-opening-11 | 适配采纳 | 系统：你看大厅墙上那座停摆的旧钟。它的机械齿轮卡死了，但还连着整栋教学楼的本地授时线。 | 系统：大厅这座旧钟还连着本楼的授时线。可它缺了指针，拨起来也不听使唤。 | 保留旧钟连授时线的新背景，同时明确缺指针、拨动不听使唤的现状 |
| chapter4-opening-12 | 适配采纳 | 玩家：你是说……只要把这座钟修好、拨回 07:55，教学楼就会以为现在还是早上？！ | 玩家：你是说……把它修好，再拨回 07:55，教学楼就会以为现在还是早上？ | 将修好并拨回07:55表述为计划；不承诺首次拨钟直接跳到终局 |
| chapter4-opening-13 | 适配采纳 | 系统：没错。既然补交材料不送时间，那我们就自己把这栋楼的时间拧回早八！ | 系统：既然补材料不送时间，咱们就试着把这栋楼的时间拧回早八！先看看它到底坏在哪。 | 保留回到早八的目标，补“先看坏在哪”以衔接既有12:25面包坊修复链 |
| chapter4-opening-14 | 采纳 | 系统：已将本楼时间源强制切换为：大厅旧钟！ | 系统：已将本楼时间源强制切换为：大厅旧钟！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-1 | 采纳 | 系统：104 教室的黑板明明擦干净了，但深色模式下，早八的粉笔字还在按笔画顺序重现……第一笔和最后一笔，刚好相差 7 分 55 秒。 | 系统：104 教室的黑板明明擦干净了，但深色模式下，早八的粉笔字还在按笔画顺序重现……第一笔和最后一笔，刚好相差 7 分 55 秒。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-2 | 采纳 | 玩家：人都走空了一整天，黑板上的时间还困在早八没下课。 | 玩家：人都走空了一整天，黑板上的时间还困在早八没下课。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-3 | 适配采纳 | 系统：105 讲台的录播终端停在 07:47:05，而教室挂钟显示 07:55:00。连监控视频都比现实慢了 7 分 55 秒。 | 系统：105 讲台的录播终端停在 07:47:05，教室记录却是 07:55:00。这段回放整整慢了 7 分 55 秒。 | 07:55来自教室记录，不是12:25/18:50现场挂钟；明确这是回放延迟 |
| chapter4-finale-4 | 未采纳 | 系统：把这两间教室的时空延迟参数记下来，去前台换取二楼的通行权。 | 保留现稿 | 105只证明回放延迟且不可校时；通行还需电梯/参照等既有条件，不能写成前台换二楼通行权；src/data/chapter4-755.content.json dialogues.classroom105.terminal_replay; godot_native/scripts/chapters/chapter4.gd |
| chapter4-finale-5 | 采纳 | 系统：时针与齿轮啮合完毕。当前大厅旧钟已回调至——07:54！ | 系统：时针与齿轮啮合完毕。当前大厅旧钟已回调至——07:54！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-6 | 采纳 | 玩家：等等，怎么停在 07:54 了？还差最后一分钟！ | 玩家：等等，怎么停在 07:54 了？还差最后一分钟！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-7 | 采纳 | 系统：是那张纸条！它趁刚才断电，把分针的黄铜卡簧和最后一分钟拆走，躲进二楼 202 阶梯教室了！ | 系统：是那张纸条！它趁刚才断电，把分针的黄铜卡簧和最后一分钟拆走，躲进二楼 202 阶梯教室了！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-8 | 采纳 | 保安：那边的同学，站住！大半夜趴在大厅钟底下干什么呢？！ | 保安：那边的同学，站住！大半夜趴在大厅钟底下干什么呢？！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-9 | 采纳 | 系统：防盗门闩落下了，保安暂时进不来。 | 系统：防盗门闩落下了，保安暂时进不来。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-10 | 采纳 | 玩家：（喘气）这下三面都是墙……你不跑了？ | 玩家：（喘气）这下三面都是墙……你不跑了？ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-11 | 原文一致保留 | 纸条：本人马上回来。 | 纸条：本人马上回来。 | 附件句子与当前正式原文完全一致，无需写入替换 |
| chapter4-finale-12 | 未采纳 | 玩家：少拿这句话糊弄我。那个占座的人三天都没回来，但我的早八今天必须签上。 | 保留现稿 | 新增玩家插话无原槽位，不能插入而改变202末段事件顺序；src/data/chapter4-755.content.json dialogues.lecture.final_minute_recovered |
| chapter4-finale-13 | 采纳 | 系统：它不挣扎了。这句“马上回来”困了它三天，现在终于有人替它把时间走完了。 | 系统：它不挣扎了。这句“马上回来”困了它三天，现在终于有人替它把时间走完了。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-14 | 采纳 | 系统：黄铜分针组件与 07:55 签到纸条，已全部收回！ | 系统：黄铜分针组件与 07:55 签到纸条，已全部收回！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-15 | 采纳 | 系统：分针归位——铛！大厅旧钟已精准停在 07:55！ | 系统：分针归位——铛！大厅旧钟已精准停在 07:55！ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-16 | 采纳 | 值班助理：同学早啊，现在是 07:55。刷卡放左边，纸质签到条塞右边槽里就行。 | 值班助理：同学早啊，现在是 07:55。刷卡放左边，纸质签到条塞右边槽里就行。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-17 | 适配采纳 | 系统：叮——签到成功！时间：07:55。地点：段永平教学楼 A1。考勤状态：本人准时到课。 | 系统：叮——签到成功！时间：07:55。地点：段永平教学楼 A1。状态：本人来过。 | 保留原记录状态“本人来过”，不只改字幕声称考勤状态已变成准时到课 |
| chapter4-finale-18 | 采纳 | 玩家：……折腾了一整天，我这到底算准时，还是算迟到了十四个小时？ | 玩家：……折腾了一整天，我这到底算准时，还是算迟到了十四个小时？ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-19 | 采纳 | 系统：只要教务系统写着 07:55，你就是准时的。恭喜你，保住了平时分。 | 系统：只要教务系统写着 07:55，你就是准时的。恭喜你，保住了平时分。 | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-20 | 未采纳 | 系统：看，外面的天亮了。 | 保留现稿 | 现终局画面是闪亮效果，未把夜景替换成黎明；字幕不能宣称外面已天亮；godot_native/scripts/world.gd chapter4 exterior closure presentation |
| chapter4-finale-21 | 采纳 | 玩家：这次……是真的结束了吧？不会再有纸条飞出来了吧？ | 玩家：这次……是真的结束了吧？不会再有纸条飞出来了吧？ | 按稳定键与原文逐项对应；只改中文显示 |
| chapter4-finale-22 | 采纳 | 系统：结束了。07:55 的异常记录已彻底归档——去吃早饭吧，同学。 | 系统：结束了。07:55 的异常记录已彻底归档——去吃早饭吧，同学。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p01-0 | 采纳 | 避雷！刚从东边杀出来，东侧车道已经堵成贪吃蛇了，赶时间的直接走教学区北侧人行道，那边一路通畅！ | 避雷！刚从东边杀出来，东侧车道已经堵成贪吃蛇了，赶时间的直接走教学区北侧人行道，那边一路通畅！ | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p01-1 | 采纳 | 17:41出考场，东边四排小黄车纹丝不动，果断绕北侧，多走两分钟但完全不卡。 | 17:41出考场，东边四排小黄车纹丝不动，果断绕北侧，多走两分钟但完全不卡。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p01-2 | 采纳 | 二南门口有辆横着停的共享单车挡道，过北口记得靠左绕行，别蹭上去！ | 二南门口有辆横着停的共享单车挡道，过北口记得靠左绕行，别蹭上去！ | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p02-0 | 采纳 | 逆天，现在基础馆选座离座超过三分钟直接释放座位？刚才去接个水回来号没了，还得刷校园卡重新申请恢复一次。 | 逆天，现在基础馆选座离座超过三分钟直接释放座位？刚才去接个水回来号没了，还得刷校园卡重新申请恢复一次。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p02-1 | 采纳 | 接水 2 分 59 秒，狂奔回门口刚好三分钟，眼睁睁看着屏幕换人，防不胜防。 | 接水 2 分 59 秒，狂奔回门口刚好三分钟，眼睁睁看着屏幕换人，防不胜防。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p02-2 | 采纳 | 笑死，普通人接水三分钟号没了，一层 022 那个书包贴张“离开三分钟”的条子硬是焊在座位上三天没动，建议直接给书包发毕业证。 | 笑死，普通人接水三分钟号没了，一层 022 那个书包贴张“离开三分钟”的条子硬是焊在座位上三天没动，建议直接给书包发毕业证。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p03-0 | 采纳 | 整理了一波历年课程资料索引，搜两个字就能出目录，求加精bd！ | 整理了一波历年课程资料索引，搜两个字就能出目录，求加精bd！ | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p03-1 | 采纳 | 求求大家交作业别再命名“最终版5打死不改版”了，找起来两眼一黑。 | 求求大家交作业别再命名“最终版5打死不改版”了，找起来两眼一黑。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p03-2 | 采纳 | 提醒一下，高数目录底下夹着的那份旧版《三分钟离座法》千万别删，听说治 022 那个钉子户书包全靠它了。 | 提醒一下，高数目录底下夹着的那份旧版《三分钟离座法》千万别删，听说治 022 那个钉子户书包全靠它了。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p04-0 | 采纳 | 实测汇报！校园卡只剩 0.06元 也能刷图书馆闸机做身份核验！只要不花钱打印，六分钱也是有合法身份的！ | 实测汇报！校园卡只剩 0.06元 也能刷图书馆闸机做身份核验！只要不花钱打印，六分钱也是有合法身份的！ | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p04-1 | 采纳 | 草，刚才在闸机前“滴”得超大声，屏幕蹦出个 0.06，后面排队的学妹憋笑憋得好辛苦。 | 草，刚才在闸机前“滴”得超大声，屏幕蹦出个 0.06，后面排队的学妹憋笑憋得好辛苦。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p04-2 | 采纳 | 六分钱战神，连去求是潮充值的电瓶车费都不够，但用来过门禁足够了。 | 六分钱战神，连去求是潮充值的电瓶车费都不够，但用来过门禁足够了。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p05-0 | 采纳 | 体艺App显示我今天通行了 47次，其实我只是在求是潮门口堵车，围着同一辆单车疯狂找缝钻…… | 体艺App显示我今天通行了 47次，其实我只是在求是潮门口堵车，围着同一辆单车疯狂找缝钻…… | 按稳定键与原文逐项对应；只改中文显示 |
| forum-p05-1 | 适配采纳 | 好家伙，原地鬼打墙十分钟，步数全进账了，人还在原地没挪窝。 | 好家伙，从 17:28 绕到 17:42，原地鬼打墙十来分钟，步数全进账了，人还在原地没挪窝。 | 原时间17:28–17:42为14分钟；改“十来分钟”并保留两个原时间戳 |
| forum-p05-2 | 采纳 | 还差最后一次满48次是吧？经典的卡47次定律。 | 还差最后一次满48次是吧？经典的卡47次定律。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-mood-room-01-0 | 采纳 | 三个DDL加一份实验报告同时糊脸上，盯着电脑发呆半小时一个字没敲出来……算了，今天能把早饭吃了、回导师一条消息就算成功，摆烂了家人们。 | 三个DDL加一份实验报告同时糊脸上，盯着电脑发呆半小时一个字没敲出来……算了，今天能把早饭吃了、回导师一条消息就算成功，摆烂了家人们。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-mood-room-01-1 | 采纳 | 先去食堂干饭！在寝室多坐五分钟只会多刷五分钟手机，别问我怎么知道的。 | 先去食堂干饭！在寝室多坐五分钟只会多刷五分钟手机，别问我怎么知道的。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-mood-room-01-2 | 采纳 | 我先把To-Do List第一条写成“打开Word”，划掉那一刻成就感拉满ac01。 | 我先把To-Do List第一条写成“打开Word”，划掉那一刻成就感拉满ac01。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-mood-room-02-0 | 采纳 | 下午刚给老师发完套磁/申请邮件，现在每隔三分钟就忍不住点开浙大邮箱刷一次，手机快被我刷没电了，救命，怎么戒掉这个毛病…… | 下午刚给老师发完套磁/申请邮件，现在每隔三分钟就忍不住点开浙大邮箱刷一次，手机快被我刷没电了，救命，怎么戒掉这个毛病…… | 按稳定键与原文逐项对应；只改中文显示 |
| forum-mood-room-02-1 | 采纳 | 把邮箱通知关了去睡一觉吧，薛定谔的回复，你不看它的时候老师才回得快。 | 把邮箱通知关了去睡一觉吧，薛定谔的回复，你不看它的时候老师才回得快。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-mood-room-02-2 | 采纳 | 只要已发送里有记录就稳了，你就算把F5按穿，老师该摸鱼还是在摸鱼。 | 只要已发送里有记录就稳了，你就算把F5按穿，老师该摸鱼还是在摸鱼。 | 按稳定键与原文逐项对应；只改中文显示 |
| forum-smile-room-01-0 | 采纳 | 人在大西区，刚坐下发现周围同学全在狂背我完全没见过的公式，我还硬着头皮抄了两行板书，结果旁边的老哥幽幽问我一句：“同学，你也来考微积分重修？”——低头一看课表，我的课是明天的…… | 人在大西区，刚坐下发现周围同学全在狂背我完全没见过的公式，我还硬着头皮抄了两行板书，结果旁边的老哥幽幽问我一句：“同学，你也来考微积分重修？”——低头一看课表，我的课是明天的…… | 按稳定键与原文逐项对应；只改中文显示 |
| forum-smile-room-01-1 | 采纳 | 哈哈哈哈哈哈甚至还认真记了两行笔记，感天动地！ | 哈哈哈哈哈哈甚至还认真记了两行笔记，感天动地！ | 按稳定键与原文逐项对应；只改中文显示 |
| forum-smile-room-01-2 | 采纳 | 不亏，四舍五入相当于提前一天预习了下学期的重修内容（逃。 | 不亏，四舍五入相当于提前一天预习了下学期的重修内容（逃。 | 按稳定键与原文逐项对应；只改中文显示 |

## 逐路径旧 → 新

| 提议ID | 文件/路径 | 索引ID | 旧文 | 新文 |
|---|---|---|---|---|
| table-wake_narration | godot_native/data/source/vo.map.json ["lines", "wake_narration"] | T07773 | 你没有5分钟了，但你很有勇气 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬。 |
| table-wake_narration | godot_native/data/source/dialogue.lines.json [0, "subtitle_zh"] | T00458 | 你没有5分钟了，但你很有勇气 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬。 |
| table-wake_flash | godot_native/data/source/vo.map.json ["lines", "wake_flash"] | T07774 | 起床蠢货！！！ | 还睡？！早八要迟到了！！ |
| table-wake_flash | godot_native/data/source/dialogue.lines.json [1, "subtitle_zh"] | T00460 | 起床蠢货！！！ | 还睡？！早八要迟到了！！ |
| table-xy_attack | godot_native/data/source/vo.map.json ["lines", "xy_attack"] | T07775 | 等等等等，你想翘课？没门！我不会让你签上的！ | 等等——人还在被窝里就想隔空签到？想得美！这分我今天扣定了！ |
| table-xy_attack | godot_native/data/source/dialogue.lines.json [2, "subtitle_zh"] | T00462 | 等等等等，你想翘课？没门！我不会让你签上的！ | 等等——人还在被窝里就想隔空签到？想得美！这分我今天扣定了！ |
| table-xy_laugh | godot_native/data/source/vo.map.json ["lines", "xy_laugh"] | T07776 | 找你的数字去吧哈哈哈 | 签到码给你拆碎咯，慢慢找去吧哈哈哈！ |
| table-xy_laugh | godot_native/data/source/dialogue.lines.json [3, "subtitle_zh"] | T00464 | 找你的数字去吧哈哈哈 | 签到码给你拆碎咯，慢慢找去吧哈哈哈！ |
| table-sys_balance | godot_native/data/source/vo.map.json ["lines", "sys_balance"] | T07777 | 余额暂时不足以购买尊严 | 校园卡余额：0.06元。这点钱连起床气都买不起。 |
| table-sys_balance | godot_native/data/source/dialogue.lines.json [4, "subtitle_zh"] | T00466 | 余额暂时不足以购买尊严 | 校园卡余额：0.06元。这点钱连起床气都买不起。 |
| table-sys_net_try | godot_native/data/source/vo.map.json ["lines", "sys_net_try"] | T07778 | 校园网已经尽力了，你也是 | ZJUWLAN 正在疯狂转圈。它尽力了，你也尽力了。 |
| table-sys_net_try | godot_native/data/source/dialogue.lines.json [5, "subtitle_zh"] | T00468 | 校园网已经尽力了，你也是 | ZJUWLAN 正在疯狂转圈。它尽力了，你也尽力了。 |
| table-tiyi_47 | godot_native/data/source/vo.map.json ["lines", "tiyi_47"] | T07780 | 就差一次，真绝望 | 体艺打卡：47/48次。离及格永远只差最后一次，经典的绝望。 |
| table-tiyi_47 | godot_native/data/source/dialogue.lines.json [7, "subtitle_zh"] | T00472 | 就差一次，真绝望 | 体艺打卡：47/48次。离及格永远只差最后一次，经典的绝望。 |
| table-gear_pickup | godot_native/data/source/vo.map.json ["lines", "gear_pickup"] | T07781 | 哈，一个废齿轮 | 哟，从设置图标上抠下来一个生锈的齿轮？ |
| table-gear_pickup | godot_native/data/source/dialogue.lines.json [8, "subtitle_zh"] | T00474 | 哈，一个废齿轮 | 哟，从设置图标上抠下来一个生锈的齿轮？ |
| table-prologue_narrator_intro | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "prologue_narrator_intro", "subtitleZh"] | T00401 | 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。我想你只好乖乖起来滚去上课了。祝你好运，孩子！我要走了！ | 噗……不好意思啊，没忍住。签到又报错了！看来你只能认命爬起来去教室解释了。祝你好运咯，同学，我下班了！ |
| table-prologue_narrator_caught | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "prologue_narrator_caught", "subtitleZh"] | T00409 | 嘿！你到底在干什么？放开我！ | 喂！你拽我弹窗干什么？！快松手！要未响应了！ |
| table-prologue_narrator_bargain | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "prologue_narrator_bargain", "subtitleZh"] | T00411 | 哦，好吧，好吧！但你先把手放开！ | 行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！ |
| table-act2_system_found_intro | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_found_intro", "subtitleZh"] | T00413 | 哦，该死。你赢了，孩子。 | ……服了你了。为了不陪你一起蓝屏，我认栽。 |
| table-act2_system_confession | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_confession", "subtitleZh"] | T00423 | 我得说实话了，我没有修改记录权限 | 但丑话说在前头，我只是个前端提示音，没有直接篡改教务考勤的权限。 |
| table-act2_system_friend | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_friend", "subtitleZh"] | T00425 | 但我有一个朋友她或许能做到 | 不过……我在图书馆有个老熟人，她手里有底层接口，或许能帮你把时间改回去。 |
| table-act2_system_library | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_library", "subtitleZh"] | T03274 | 如果我们还想要平时分，就得去图书馆找她 | 想保住你的平时分，现在就得去基础馆一楼找她。 |
| table-act2_system_inventory_demand | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_inventory_demand", "subtitleZh"] | T00415 | 行。把你的道具栏拿出来。 | 来，先把你的道具栏调出来，咱们准备动身。 |
| table-act2_system_inventory_missing | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_inventory_missing", "subtitleZh"] | T00417 | 等等，你的道具栏呢？你总不能指望我空手干活！ | ……等等，你连道具栏都没加载？你不会指望我徒手给你黑进系统吧！ |
| table-act2_system_departure | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_system_departure", "subtitleZh"] | T00421 | 你找到了，那就太好了，我们出发吧！ | 总算找着了。行，那赶紧操作你床上的身体出门吧！ |
| table-act1_locked_entry | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act1_locked_entry", "subtitleZh"] | T00387 | 很好，你打开了游戏。现在请先去申请操作自己。 | ……好吧，看来你不仅没起床，连自己身体的控制权都还没登录。先去认证一下身份吧。 |
| table-act2_character_cannot_hear | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_character_cannot_hear", "subtitleZh"] | T00428 | 他听不到你说话。现在的他连一个能回应的名字都没有。 | 别戳他了，他听不见。没绑定姓名和学号之前，他就是个没加载完的默认建模。 |
| table-act1_identity_verified | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act1_identity_verified", "subtitleZh"] | T00389 | 登录成功。这个角色终于有名字了，仍然没联网。 | 学号核验通过。好消息：你想起自己叫什么了。坏消息：你的身体还没联网。 |
| table-act1_phone_linked | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act1_phone_linked", "subtitleZh"] | T00391 | 电话接通。用学号当电话号码，很有校园特色。 | 信号接通了。拿学号当手机号拨通自己，也就这破系统干得出来。 |
| table-act2_push_triangle_collected | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_push_triangle_collected", "subtitleZh"] | T00434 | 获得道具：三角形。 | 拆下来一个播放键三角。再去天气页接滴雨水试试？ |
| table-act2_weather_water_collected | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_weather_water_collected", "subtitleZh"] | T00436 | 获得道具：天气水滴。 | 雨水到手。去看看导师头像旁边那根卡死的竖线，泡软了应该能抠下来。 |
| table-act2_mentor_line_stuck | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_mentor_line_stuck", "subtitleZh"] | T00438 | 那条竖线粘住了。看来导师头像也有自己的排版要求。 | 这根分割线焊得死死的。毕竟是导师的对话框，连排版都透着一股压迫感。 |
| table-act2_right_arrow_assembled | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_right_arrow_assembled", "subtitleZh"] | T00440 | 一个三角形加一条竖线。现在你有了一支能把东西向右移的箭头。 | 三角加横杆，拼成右移箭头了。去看看你的余额小数点能不能往右挪挪？ |
| table-act2_gamepad_purchase_rejected | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_gamepad_purchase_rejected", "subtitleZh"] | T00444 | 你只有零点零六元。卖家拒绝了你分一百期付款的方案。 | 全身上下六分钱，还想跟98卖家分一百期买手柄？人家直接把你拒了。 |
| table-act2_balance_shifted | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_balance_shifted", "subtitleZh"] | T00442 | 小数点向右移动了两位。六分钱暂时获得了六元钱的尊严。 | 小数点右移两位！0.06 秒变 6.00 元——趁财务系统还没反应过来，赶紧去98把二手手柄付了！ |
| table-act1_movement_enabled | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act1_movement_enabled", "subtitleZh"] | T00395 | 锻炼开始。恭喜，你现在被允许步行。 | 体艺打卡启动！恭喜，你终于获得了在自己寝室里合法走路的权限。 |
| table-act2_exit_ready | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "act2_exit_ready", "subtitleZh"] | T00446 | 现在可以出门了。 | 走吧，去基础图书馆一楼，找 022 号座位！ |
| table-c3_canteen_queue_system | godot_native/data/source/chapter3-story-lines.json ["lines", 0, "subtitleZh"] | T02098 | 系统：它可能只是来体验一下排队，很多东西在食堂都会排队。 | 系统：连一张逃跑的异常纸条，进了浙大食堂都得老老实实排队。 |
| table-c3_canteen_bun_system | godot_native/data/source/chapter3-story-lines.json ["lines", 2, "subtitleZh"] | T02100 | 系统：它看起来不像纸条会吃的东西，虽然纸条也不该吃东西。 | 系统：这包子连馅儿都是实的，藏不进纸条。再说了，纸条也不吃碳水。 |
| table-c3_canteen_breakfast_system | godot_native/data/source/chapter3-story-lines.json ["lines", 3, "subtitleZh"] | T02101 | 系统：不是，是一份比较真实的早饭。 | 系统：没有线索，只有碳水。恭喜你获得了一份平平无奇的早饭。 |
| table-c3_canteen_paper_chicken_system | godot_native/data/source/chapter3-story-lines.json ["lines", 4, "subtitleZh"] | T02102 | 系统：纸包鸡。我知道的至少前两个字很有嫌疑。 | 系统：“纸包鸡”。听名字，前两个字就跟我们的目标很有缘分。 |
| table-c3_canteen_packaging_system | godot_native/data/source/chapter3-story-lines.json ["lines", 5, "subtitleZh"] | T02103 | 系统：一份线索。鸡只是包装。 | 系统：我们要的是外面那层纸，里面的鸡肉纯属赠品。 |
| table-c3_canteen_cold_clue_system | godot_native/data/source/chapter3-story-lines.json ["lines", 6, "subtitleZh"] | T02104 | 系统：这份粥很热，但线索很冷。 | 系统：粥还烫嘴，但线索已经断了。换个窗口找找吧。 |
| table-c3_canteen_worldview_system | godot_native/data/source/chapter3-story-lines.json ["lines", 7, "subtitleZh"] | T02105 | 系统：请不要拓展世界观。 | 系统：打住，别在这种地方强行发散思维。 |
| table-c3_canteen_paper_impact_narrator | godot_native/data/source/chapter3-story-lines.json ["lines", 8, "subtitleZh"] | T02106 | 纸条撞回食堂，掉下一点蓝光。 | 纸条撞回食堂，抖落了一地蓝色的数据残影。 |
| table-c3_canteen_paper_angry_narrator | godot_native/data/source/chapter3-story-lines.json ["lines", 9, "subtitleZh"] | T02107 | 纸条急了，它开始不尊重取餐流程。 | 纸条急眼了，决定直接插队硬闯取餐口！ |
| table-c3_canteen_self_service_system | godot_native/data/source/chapter3-story-lines.json ["lines", 10, "subtitleZh"] | T02108 | 系统：自助服务发展到这一步，我有点害怕。 | 系统：现在的食堂自助取餐，已经进化到全自动打架了吗？ |
| table-c3_bike_human_speed_system | godot_native/data/source/chapter3-story-lines.json ["lines", 12, "subtitleZh"] | T02112 | 系统：你正在以“没吃早饭的人类速度”移动。 | 系统：靠你这两条没吃早饭的腿，是追不上风的。找辆共享单车吧。 |
| table-c3_bike_gpa_system | godot_native/data/source/chapter3-story-lines.json ["lines", 13, "subtitleZh"] | T02114 | 系统：它没有绩点负担。 | 系统：人家只是一张纸，可没有挂科扣绩点的心理负担，当然飞得快。 |
| table-c3_bike_no_money_system | godot_native/data/source/chapter3-story-lines.json ["lines", 14, "subtitleZh"] | T02116 | 系统：这句话在本游戏里出现频率太高了。 | 系统：“余额不足”这四个字，今天真是刻进你DNA里了。先去帮阿姨收盘子赚钱吧。 |
| table-c3_theater_failure_narrator | godot_native/data/source/chapter3-story-lines.json ["lines", 15, "subtitleZh"] | T02117 | 旁白：失败得很慷慨。 | 旁白：摔得十分干脆，连体面都没留。 |
| table-c3_theater_logic_system | godot_native/data/source/chapter3-story-lines.json ["lines", 16, "subtitleZh"] | T02118 | 系统：台上的顺序改过，印刷版未必跟得上。 | 系统：彩排临时改过场次顺序，纸质节目单早就过时了。得看现场的痕迹。 |
| table-c3_theater_logic_system | godot_native/data/source/chapter3-theater.content.json ["program", "wrongDialogue", 1] | T01004 | 系统：台上的顺序改过，印刷版未必跟得上。 | 系统：彩排临时改过场次顺序，纸质节目单早就过时了。得看现场的痕迹。 |
| table-c3_theater_celebrate_system | godot_native/data/source/chapter3-story-lines.json ["lines", 17, "subtitleZh"] | T02119 | 系统：先翻过来看。 | 系统：别高兴得太早，把纸条翻过来看看背面。 |
| table-c3_theater_celebrate_system | godot_native/data/source/chapter3-theater.content.json ["spotlight", "endingDialogue", 1] | T01031 | 系统：先翻过来看。 | 系统：别高兴得太早，把纸条翻过来看看背面。 |
| table-c3_theater_substitute_system | godot_native/data/source/chapter3-story-lines.json ["lines", 18, "subtitleZh"] | T02120 | 系统：替身有编号。原件去向不在节目单里。 | 系统：背面印着剧社的道具编号。这是张舞台替身，真家伙早就趁乱溜出剧场了。 |
| table-c3_theater_substitute_system | godot_native/data/source/chapter3-theater.content.json ["spotlight", "endingDialogue", 4] | T01034 | 系统：替身有编号。原件去向不在节目单里。 | 系统：背面印着剧社的道具编号。这是张舞台替身，真家伙早就趁乱溜出剧场了。 |
| table-c3_qizhen_no_trail_system | godot_native/data/source/chapter3-story-lines.json ["lines", 19, "subtitleZh"] | T02121 | 系统：不知道。它这次没有沿路掉纸屑。 | 系统：跟丢了。这次它学精了，沿路半点蓝光都没漏。 |
| table-c3_qizhen_forum_system | godot_native/data/source/chapter3-story-lines.json ["lines", 20, "subtitleZh"] | T02122 | 系统：老办法，发个论坛问问。 | 系统：遇事不决上 98。发个悬赏帖，让全校的夜猫子帮你找。 |
| table-c3_qizhen_cc98_system | godot_native/data/source/chapter3-story-lines.json ["lines", 21, "subtitleZh"] | T02123 | 系统：CC98 提供了一个非常精确的范围：不是厕所。 | 系统：98 老哥给出了极其严谨的排除法：至少没飞进厕所。 |
| table-c3_qizhen_catalog_system | godot_native/data/source/chapter3-story-lines.json ["lines", 22, "subtitleZh"] | T02124 | 系统：意思是它现在比我们更艺术。 | 系统：馆藏线索指向湖岸与倒影……看来这张纸条还挺讲究意境。 |
| table-c3_qizhen_map_system | godot_native/data/source/chapter3-story-lines.json ["lines", 23, "subtitleZh"] | T02125 | 系统：恭喜，你完成了一次校园级猜谜。 | 系统：三条线索拼齐——目标锁定，启真湖！ |
| table-c3_qizhen_reflection_system | godot_native/data/source/chapter3-story-lines.json ["lines", 24, "subtitleZh"] | T02126 | 系统：准确来说，是在倒影里。 | 系统：它没泡在水里，是卡在湖面的倒影图层里了。 |
| table-c3_qizhen_swimming_system | godot_native/data/source/chapter3-story-lines.json ["lines", 25, "subtitleZh"] | T02127 | 系统：对不会游泳的人来说区别很大。 | 系统：别想不开往水里跳，你体艺游泳课还没修呢。找船过去。 |
| table-c3_qizhen_gone_system | godot_native/data/source/chapter3-story-lines.json ["lines", 26, "subtitleZh"] | T02128 | 系统：它又消失了。 | 系统：水波一晃，它又缩回深色倒影里了。 |
| table-c3_qizhen_sign_system | godot_native/data/source/chapter3-story-lines.json ["lines", 27, "subtitleZh"] | T02129 | 系统：通常这里不应该有给我们指指路的牌子吗？ | 系统：岸边那块旧指示牌木头不错，拆下来正好当右船桨使。 |
| table-c3_qizhen_hiding_system | godot_native/data/source/chapter3-story-lines.json ["lines", 28, "subtitleZh"] | T02130 | 系统：这就是它躲藏的地方，哈 | 系统：锁定坐标了！它就猫在这片倒影底下。 |
| table-c3_qizhen_fake_system | godot_native/data/source/chapter3-story-lines.json ["lines", 30, "subtitleZh"] | T02132 | 系统：就是这个假的 | 系统：把刚才在剧场抓到的那张假替身挂在鱼钩上！ |
| table-c3_qizhen_ego_system | godot_native/data/source/chapter3-story-lines.json ["lines", 31, "subtitleZh"] | T02133 | 系统：因为它不能接受别人替它逃跑。 | 系统：一个占了三天座位的老赖，绝对容不下冒牌货顶替它的位置。 |
| table-c3_qizhen_atmosphere_system | godot_native/data/source/chapter3-story-lines.json ["lines", 32, "subtitleZh"] | T02134 | 系统：你只是让湖更有氛围了。 | 系统：偏了！你这杆甩下去，除了惊起两圈水波啥也没钓着。 |
| table-c3_qizhen_taunt_system | godot_native/data/source/chapter3-story-lines.json ["lines", 33, "subtitleZh"] | T02135 | 系统：还在嘲笑你的倒影。 | 系统：瞧见没，水底下的正主正隔着倒影看你笑话呢。对准点！ |
| table-c3_qizhen_grab_system | godot_native/data/source/chapter3-story-lines.json ["lines", 36, "subtitleZh"] | T02138 | 系统：能抓了！ | 系统：趁现在，按住它！ |
| table-prologue_narrator_intro | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "prologue_narrator_intro", "subtitleSegmentsZh", 0] | T00402 | 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。 | 噗……不好意思啊，没忍住。签到又报错了！ |
| table-prologue_narrator_intro | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "prologue_narrator_intro", "subtitleSegmentsZh", 1] | T00403 | 我想你只好乖乖起来滚去上课了。 | 看来你只能认命爬起来去教室解释了。 |
| table-prologue_narrator_intro | godot_native/data/source/act-one-bootstrap.content.json ["audioNarration", "prologue_narrator_intro", "subtitleSegmentsZh", 2] | T00404 | 祝你好运，孩子！我要走了！ | 祝你好运咯，同学，我下班了！ |
| library-entered-1 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 0, "text"] | T03304 | 这里就是图书馆？ | 这就是基础馆？你说的那个朋友在哪？ |
| library-entered-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 1, "text"] | T03306 | 她最后留下入馆记录的地方。 | 在入馆闸机最后的登记记录里。她一直待在一层书库。 |
| library-entered-3 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 2, "text"] | T03308 | 你朋友是管理员？ | 她是这里的图书管理员？ |
| library-entered-4 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 3, "text"] | T03310 | 她不管馆内秩序。 | 不是。她不管借书，也不在教职工名册里。 |
| library-entered-5 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 4, "text"] | T03312 | 馆长？ | 那是谁？总不能是馆长吧。 |
| library-entered-6 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 7, "text"] | T03318 | 一个座位，一层书库 022。 | 是一层书库的 022 号座位。 |
| library-entered-7 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 8, "text"] | T03320 | …… | ……你是说，你的朋友是一张桌子？ |
| library-entered-8 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 9, "text"] | T03322 | 上次见面时，她就在 022。 | 准确地说，是绑定在 022 号座位上的旧版选座终端。上次系统升级前，全校的考勤与选座时间戳都归她管。 |
| library-entered-9 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 10, "text"] | T03324 | 以前？ | 那直接过去找她就行？ |
| library-entered-10 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_entered", 11, "text"] | T03326 | 这张记录没有固定时长。先去闸机核对入馆时间。 | 她的入馆记录停在三天前，一直没签退。先刷闸机进去看看情况。 |
| library-occupied-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_occupied_seat_found", 1, "text"] | T03330 | 022 被一个书包占着，桌上的纸条写着“主人马上回来”。 | 022 号座位上赫然盘踞着一个鼓鼓囊囊的书包，上面贴着一张便签纸：“本人离开三分钟，马上回来”。 |
| library-occupied-3 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_occupied_seat_found", 2, "text"] | T03332 | 它把座位占了。 | ……被占座了。而且一个书包怎么连选座终端的屏幕都挡死了？ |
| library-occupied-4 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_occupied_seat_found", 3, "text"] | T03334 | 先别碰。去 CC98 查三分钟离座的规则。 | 别硬拽！馆内选座系统判定它还在“三分钟暂离保护期”内，强行挪动会触发警报。去 CC98 搜搜怎么破这个死循环。 |
| library-rule-1 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_archived_rule_recovered", 0, "text"] | T03346 | 旧版离座规则找到了。 | 755 号书架背面的旧版《三分钟离座法》找到了。 |
| library-rule-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_archived_rule_recovered", 1, "text"] | T03348 | 坏消息？ | 看你这语气，流程很阴间？ |
| library-rule-3 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_archived_rule_recovered", 2, "text"] | T03350 | 它要求三项证明。 | 非常官僚。要想强制清退超时占座物，必须集齐三份纸质证明： |
| library-rule-4 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_archived_rule_recovered", 5, "text"] | T03356 | 座位小票、到馆证明、书包非本人证明。 | 第一，你本人的到馆时间证明；第二，022 座位的小票；第三……“该书包不是人类”的身份核验公章。 |
| library-rule-5 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_archived_rule_recovered", 3, "text"] | T03352 | 书包还要核验身份？ | ……？我要去向图书馆证明一个双肩包不是人？！ |
| library-rule-6 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_archived_rule_recovered", 4, "text"] | T03354 | 规则只认已经留下的材料。 | 因为在后台数据库里，这个书包已经连续刷了三天全勤，系统默认它是模范读者。 |
| library-frontdesk-1 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_front_desk_proof_request", 0, "text"] | T03360 | 请说明要处理的物品。 | 同学你好，办什么业务？ |
| library-frontdesk-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_front_desk_proof_request", 1, "text"] | T03362 | 022 的占座书包。 | 我想举报 022 号座位的占座书包。 |
| library-frontdesk-3 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_front_desk_proof_request", 2, "text"] | T03364 | 请先提交书包非本人证明。 | 清退占座需先提交《占用物非本人证明》。 |
| library-frontdesk-4 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_front_desk_proof_request", 3, "text"] | T03366 | 书包也要做身份核验？ | 不是，它就是个帆布包，你抬头看一眼不就知道了？ |
| library-frontdesk-5 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_front_desk_proof_request", 4, "text"] | T03368 | 系统里，它目前登记为座位使用者。 | 不好意思，选座系统只认公章，不认肉眼。在系统里它有合法占座权。 |
| library-stamp-1 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_bag_nonperson_proof_issued", 0, "text"] | T03370 | 盖章完成。书包不再算 022 的使用者。 | 公章盖好了。“书包不具备自然人学籍”核验通过。 |
| library-stamp-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_bag_nonperson_proof_issued", 1, "text"] | T03372 | 我今天跑的证明比上课还多。 | 为了赶一节早八，我今天办的证明比退学手续还全。 |
| library-evidence-1 | godot_native/data/source/library-finals.content.json ["storyDialogues", "cc98_evidence_set_completed", 0, "text"] | T03384 | 好了，证据齐了。现在图书馆会处理了吧？ | 三份证明终于跑齐了，现在能把书包清走了吧？ |
| library-evidence-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "cc98_evidence_set_completed", 1, "text"] | T03386 | 还差公开确认。图书馆 App 只读取十大帖的四位热度口令。 | 还差最后一步“舆论监督”。用四位受理口令完成确认，帖子冲上 CC98 十大第一，清退入口才会开放。 |
| library-evidence-3 | godot_native/data/source/library-finals.content.json ["storyDialogues", "cc98_evidence_set_completed", 2, "text"] | T03388 | bd 到底是什么？ | 还要我去发帖控评？那个“bd”又是什么？ |
| library-evidence-4 | godot_native/data/source/library-finals.content.json ["storyDialogues", "cc98_evidence_set_completed", 3, "text"] | T03390 | bd 是“帮顶”。在一条数字回复上点 bd，数字就会按顺序写入口令。 | 98 黑话，“帮顶”的意思。你按证据栏的顺序给那几层带数字的楼层点 bd，楼层的数字就会拼成四位受理口令。 |
| library-evicted-1 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_backpack_evicted", 0, "text"] | T03398 | 请占座物品离开 022。 | 022 号座位清退申请已通过。请占座物品立即离开座位。 |
| library-evicted-2 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_backpack_evicted", 1, "text"] | T03400 | 如需认领，请前往失物招领。 | 逾期未领的书包将移交失物招领处。 |
| library-evicted-3 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_backpack_evicted", 2, "text"] | T03402 | 主人马上回来。 | 本人……马上回来。 |
| library-evicted-4 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_backpack_evicted", 3, "text"] | T03404 | 什么时候？ | 你到底什么时候回来？ |
| library-evicted-6 | godot_native/data/source/library-finals.content.json ["storyDialogues", "library_backpack_evicted", 5, "text"] | T03408 | 纸条上的这句话已经留了三天。 | 别信它。这张纸条上的“三分钟”，已经在这儿卡了整整三天了。 |
| library-022-1 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 0, "text"] | T03542 | 你终于坐下了。 | ……呼，压死我了。你终于坐下了。 |
| library-022-2 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 1, "text"] | T03544 | 你就是系统的朋友？ | 你就是系统说的那个朋友？ |
| library-022-3 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 2, "text"] | T03546 | 她以前不在座位上。 | 好久不见。你以前可不会被一个帆布包封印三天。 |
| library-022-4 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 3, "text"] | T03548 | 你以前也不在红圈里。 | 你以前也不会为了保一个迟到学生的平时分，亲自跑来求我。 |
| library-022-5 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 4, "text"] | T03550 | 先查签到记录。能修改吗？ | 少叙旧了，快帮他查查今天早八的签到记录，还能从后台改回 07:55 吗？ |
| library-022-6 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 5, "text"] | T03552 | 我先查。 | 稍等，我调一下日志…… |
| library-022-7 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 6, "text"] | T03554 | 可以改吗？ | 有戏吗？ |
| library-022-8 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 7, "text"] | T03556 | 查完了。签到记录离开了原页面。 | 糟了。你的签到记录不在教务服务器里——它被刚才书包上那张便签纸粘走了！ |
| library-022-10 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 8, "text"] | T03558 | 它夹在一张纸条里，记录停在 07:55。 | 那张写着“马上回来”的纸条在座位上卡了太久，变成了吞噬时间的异常缓存。它把你的签到时间锁死在 07:55，刚才趁书包被清退，顺着网线溜出去了。 |
| library-022-11 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 9, "text"] | T03560 | 纸条往哪去了？ | 那它往哪跑了？我怎么一点没看见？ |
| library-022-12 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 10, "text"] | T03562 | 它不在浅色操作能看见的位置。 | 在正常的浅色界面下，你当然看不见底层缓存的溢出轨迹。 |
| library-022-13 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 12, "text"] | T03566 | 说明白一点。 | 直接把权限开给他吧，别卖关子了。 |
| library-022-14 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 13, "text"] | T03568 | 切到深色观察，能看见纸条留下的痕迹。 | 我帮你解锁了“深色观察”模式。切到深色界面，你就能看见纸条残留的蓝光轨迹了。 |
| library-022-15 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 14, "text"] | T03570 | 这就是暗色模式？ | 这不就是手机的暗黑模式吗？ |
| library-022-16 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 15, "text"] | T03572 | 这是它在系统里的名称。 | 在你们眼里是护眼模式，在我们眼里是底层调试视图。 |
| library-022-17 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 16, "text"] | T03574 | 先追痕迹，别让纸条离开视野。 | 蓝光动了！快追，别让那张纸条跑出图书馆！ |
| library-022-19 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 18, "text"] | T03578 | 它会说话了？！ | 卧槽，纸条成精说话了？！ |
| library-022-20 | godot_native/data/source/library-finals.content.json ["library", "dialogue022", 19, "text"] | T03580 | 它把原来的话留在纸条上了。 | 那不是它在说话，是原主人三天前留下的语音残影！快追！ |
| canteen-drink-1 | godot_native/data/source/chapter3-canteen.content.json ["drinks", "badDrinkConsumed", 0] | T02729 | 玩家：这也能卖？ | 玩家：呕……食堂这是把板蓝根倒进气泡水里了？！ |
| canteen-drink-2 | godot_native/data/source/chapter3-canteen.content.json ["drinks", "badDrinkConsumed", 1] | T02730 | 系统：你已完成试饮。无退款项目。 | 系统：恭喜你成为今日第一位勇士。试饮无工伤补贴。 |
| canteen-drink-3 | godot_native/data/source/chapter3-canteen.content.json ["drinks", "queueShiftDialogue", 0] | T02735 | 玩家：他们怎么都退了？ | 玩家：前面排队的怎么全散了？ |
| lake-search-1 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "dialogue", 0] | T01265 | 玩家：它去哪了？ | 玩家：剧场外面连个鬼影都没有，它往哪边飞了？ |
| lake-search-3 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "dialogue", 2] | T01267 | 玩家：追了一路，还得发帖寻物。 | 玩家：追了大半个校园，不会还要我发帖寻物吧？ |
| lake-search-5 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "cc98", "system"] | T01273 | 系统：论坛线索指向湖区和桥。 | 系统：论坛目击帖缩小了范围：就在有桥的水域附近。 |
| lake-search-6 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "cc98", "player"] | T01274 | 玩家：继续找能区分地点的信息。 | 玩家：有桥有水……范围还是太大了，还得找点能对上地点的线索。 |
| lake-search-7 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "catalog", "player"] | T01286 | 玩家：需要在湖面倒影里确认位置。 | 玩家：馆藏记录写着“当前页码只出现在倒影中”……看来得找个能照出倒影的湖面。 |
| lake-search-9 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "map", "player"] | T01297 | 玩家：前往启真湖。 | 玩家：逆风扩散的水纹……走，去启真湖！ |
| lake-search-10 | godot_native/data/source/chapter3-qizhen-lake.content.json ["locationSearch", "map", "system"] | T01298 | 系统：已建立湖区入口。 | 系统：已在地图上标出启真湖码头。 |
| lake-search-11 | godot_native/data/source/chapter3-qizhen-lake.content.json ["dock", "intro", 0] | T01299 | 玩家：小码头有一艘皮划艇。 | 玩家：码头边拴着一艘皮划艇，但船上连桨都没有。 |
| lake-search-13 | godot_native/data/source/chapter3-qizhen-lake.content.json ["dock", "intro", 2] | T01301 | 玩家：先完成上船平衡。 | 玩家：得先踩稳了跨上去，别一脚踩翻进湖里。 |
| chapter4-opening-1 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.paper_flight", 0, "text"] | T04833 | 现场画面已同步。异常签到纸正在飞向公告栏。 | 视野已同步！那张签到纸条正往大厅公告栏上撞，快抓住它！ |
| chapter4-opening-2 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.paper_caught", 0, "text"] | T04834 | 抓到了。 | ——抓到了！这下看你还往哪跑！ |
| chapter4-opening-3 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.paper_caught", 1, "text"] | T04835 | 正在提交签到记录…… | 正在将签到纸条写入教务考勤服务器…… |
| chapter4-opening-4 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.external_time_rejected", 0, "text"] | T04836 | 提交失败。外部时间：22:45。 | ……提交失败。当前外部标准时间：22:45。 |
| chapter4-opening-5 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.external_time_rejected", 1, "text"] | T04837 | 签到截止时间：07:55。 | 早八考勤截止时间：07:55。超时 14 小时 50 分钟，系统拒绝接收。 |
| chapter4-opening-6 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.external_time_rejected", 2, "text"] | T04838 | 手机上还写着 07:55:23。 | 怎么可能 22:45？！你看我手机屏幕，上面明明还停在 07:55:23！ |
| chapter4-opening-7 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.external_time_rejected", 3, "text"] | T04839 | 手机上的时间没更新。现在已经是 22:45。 | 那是你手机被纸条卡死的本地时间。为了追这张纸，你从早八一路跑到了熄灯清楼。 |
| chapter4-opening-8 | godot_native/data/source/chapter4-755.content.json ["dialogues", "opening.external_time_rejected", 4, "text"] | T04840 | 记录找回来了，迟到还在。补材料不附送补时间。 | 你的签到记录确实找回来了，但那节早八……十四个小时前就已经下课了。 |
| chapter4-opening-11 | godot_native/data/source/chapter4-755.content.json ["dialogues", "hall_clock.first_inspection", 0, "text"] | T04841 | 旧钟能被拨动，但指针不会按你的动作走。 | 大厅这座旧钟还连着本楼的授时线。可它缺了指针，拨起来也不听使唤。 |
| chapter4-opening-12 | godot_native/data/source/chapter4-755.content.json ["dialogues", "hall_clock.first_inspection", 1, "text"] | T04842 | 这是好消息？ | 你是说……把它修好，再拨回 07:55，教学楼就会以为现在还是早上？ |
| chapter4-opening-13 | godot_native/data/source/chapter4-755.content.json ["dialogues", "hall_clock.first_inspection", 2, "text"] | T04843 | 它还在出错。 | 既然补材料不送时间，咱们就试着把这栋楼的时间拧回早八！先看看它到底坏在哪。 |
| chapter4-opening-14 | godot_native/data/source/chapter4-755.content.json ["dialogues", "hall_clock.first_pull", 0, "text"] | T04844 | 时间源已切换：大厅旧钟。 | 已将本楼时间源强制切换为：大厅旧钟！ |
| chapter4-finale-1 | godot_native/data/source/chapter4-755.content.json ["dialogues", "classroom104.chalk_residual", 0, "text"] | T04848 | 黑板已经擦净，残留笔画仍按书写顺序逐段出现。首尾相差 7 分 55 秒。 | 104 教室的黑板明明擦干净了，但深色模式下，早八的粉笔字还在按笔画顺序重现……第一笔和最后一笔，刚好相差 7 分 55 秒。 |
| chapter4-finale-2 | godot_native/data/source/chapter4-755.content.json ["dialogues", "classroom104.chalk_residual", 1, "text"] | T04849 | 人都下课了，这里还没写完。 | 人都走空了一整天，黑板上的时间还困在早八没下课。 |
| chapter4-finale-3 | godot_native/data/source/chapter4-755.content.json ["dialogues", "classroom105.terminal_replay", 0, "text"] | T04850 | 讲台回放停在 07:47:05，教室记录显示 07:55:00。本地画面延迟 7 分 55 秒。 | 105 讲台的录播终端停在 07:47:05，教室记录却是 07:55:00。这段回放整整慢了 7 分 55 秒。 |
| chapter4-finale-5 | godot_native/data/source/chapter4-755.content.json ["dialogues", "blackout.minute_stolen", 0, "text"] | T04882 | 时间校准至 07:54。 | 时针与齿轮啮合完毕。当前大厅旧钟已回调至——07:54！ |
| chapter4-finale-6 | godot_native/data/source/chapter4-755.content.json ["dialogues", "blackout.minute_stolen", 1, "text"] | T04883 | 差一分钟。 | 等等，怎么停在 07:54 了？还差最后一分钟！ |
| chapter4-finale-7 | godot_native/data/source/chapter4-755.content.json ["dialogues", "blackout.minute_stolen", 2, "text"] | T04884 | 纸条把最后一分钟带走了。定位结果：阶梯教室。 | 是那张纸条！它趁刚才断电，把分针的黄铜卡簧和最后一分钟拆走，躲进二楼 202 阶梯教室了！ |
| chapter4-finale-8 | godot_native/data/source/chapter4-755.content.json ["dialogues", "chase.started", 0, "text"] | T04885 | 同学，站住。离旧钟远一点。 | 那边的同学，站住！大半夜趴在大厅钟底下干什么呢？！ |
| chapter4-finale-9 | godot_native/data/source/chapter4-755.content.json ["dialogues", "chase.arrived", 0, "text"] | T04891 | 门闩已落下，保安被挡在 202 门外。 | 防盗门闩落下了，保安暂时进不来。 |
| chapter4-finale-10 | godot_native/data/source/chapter4-755.content.json ["dialogues", "lecture.final_minute_recovered", 0, "text"] | T04892 | 不跑了？ | （喘气）这下三面都是墙……你不跑了？ |
| chapter4-finale-13 | godot_native/data/source/chapter4-755.content.json ["dialogues", "lecture.final_minute_recovered", 2, "text"] | T04894 | 它回来了。 | 它不挣扎了。这句“马上回来”困了它三天，现在终于有人替它把时间走完了。 |
| chapter4-finale-14 | godot_native/data/source/chapter4-755.content.json ["dialogues", "lecture.recovered_result", 0, "text"] | T04895 | 黄铜分针组件和签到纸条都已取回。 | 黄铜分针组件与 07:55 签到纸条，已全部收回！ |
| chapter4-finale-15 | godot_native/data/source/chapter4-755.content.json ["dialogues", "morning.entry", 0, "text"] | T04896 | 门厅旧钟已到 07:55。 | 分针归位——铛！大厅旧钟已精准停在 07:55！ |
| chapter4-finale-16 | godot_native/data/source/chapter4-755.content.json ["dialogues", "frontDesk.morning_checkin", 0, "text"] | T04863 | 现在是 07:55。校园卡放到左侧读卡器，签到纸放入右侧纸槽。 | 同学早啊，现在是 07:55。刷卡放左边，纸质签到条塞右边槽里就行。 |
| chapter4-finale-17 | godot_native/data/source/chapter4-755.content.json ["dialogues", "morning.checkin_success", 0, "text"] | T04897 | 签到成功。时间：07:55。地点：段永平教学楼 A1。状态：本人来过。 | 叮——签到成功！时间：07:55。地点：段永平教学楼 A1。状态：本人来过。 |
| chapter4-finale-18 | godot_native/data/source/chapter4-755.content.json ["dialogues", "morning.checkin_success", 1, "text"] | T04898 | 现在算准时吗？ | ……折腾了一整天，我这到底算准时，还是算迟到了十四个小时？ |
| chapter4-finale-19 | godot_native/data/source/chapter4-755.content.json ["dialogues", "morning.checkin_success", 2, "text"] | T04899 | 从时间角度，算。 | 只要教务系统写着 07:55，你就是准时的。恭喜你，保住了平时分。 |
| chapter4-finale-21 | godot_native/data/source/chapter4-755.content.json ["dialogues", "exterior.closure", 1, "text"] | T04901 | 这次真的结束了？ | 这次……是真的结束了吧？不会再有纸条飞出来了吧？ |
| chapter4-finale-22 | godot_native/data/source/chapter4-755.content.json ["dialogues", "exterior.closure", 2, "text"] | T04902 | 结束了，签到记录已归档。 | 结束了。07:55 的异常记录已彻底归档——去吃早饭吧，同学。 |
| forum-p01-0 | godot_native/data/source/cc98.posts.json [24, "body"] | T06604 | 刚从东侧绕出来。教学区北侧的人行道还能连续走，东侧车流已经堵成两段。 | 避雷！刚从东边杀出来，东侧车道已经堵成贪吃蛇了，赶时间的直接走教学区北侧人行道，那边一路通畅！ |
| forum-p01-1 | godot_native/data/source/cc98.posts.json [24, "threadReplies", 0, "text"] | T06611 | 17:41 出考场，17:44 还在北口。东边四排车没动，北侧多走两分钟能过。 | 17:41出考场，东边四排小黄车纹丝不动，果断绕北侧，多走两分钟但完全不卡。 |
| forum-p01-2 | godot_native/data/source/cc98.posts.json [24, "threadReplies", 2, "text"] | T06619 | 二南门口横着停的共享单车还在。北口靠左走，别贴着那辆车。 | 二南门口有辆横着停的共享单车挡道，过北口记得靠左绕行，别蹭上去！ |
| forum-p02-0 | godot_native/data/source/cc98.posts.json [25, "body"] | T06637 | 离座超过三分钟后，原座位会重新开放。完成校园卡核验后，可在选座页申请恢复一次。 | 逆天，现在基础馆选座离座超过三分钟直接释放座位？刚才去接个水回来号没了，还得刷校园卡重新申请恢复一次。 |
| forum-p02-1 | godot_native/data/source/cc98.posts.json [25, "threadReplies", 3, "text"] | T06652 | 我去接水 2 分 59 秒，回到门口刚好三分钟。座位已经换号。 | 接水 2 分 59 秒，狂奔回门口刚好三分钟，眼睁睁看着屏幕换人，防不胜防。 |
| forum-p02-2 | godot_native/data/source/cc98.posts.json [25, "threadReplies", 2, "text"] | T03279 | 022 桌上的书包三天没动。它比大多数人更符合“长期使用”这一项。 | 笑死，普通人接水三分钟号没了，一层 022 那个书包贴张“离开三分钟”的条子硬是焊在座位上三天没动，建议直接给书包发毕业证。 |
| forum-p03-0 | godot_native/data/source/cc98.posts.json [26, "body"] | T06666 | 资料按课程、教师和年份建立索引。搜索时只记得两个字也能定位到对应目录。 | 整理了一波历年课程资料索引，搜两个字就能出目录，求加精bd！ |
| forum-p03-1 | godot_native/data/source/cc98.posts.json [26, "threadReplies", 0, "text"] | T06673 | 文件名写成“最终版5真的最终版”的那份，能不能把交稿时间也写进文件名。 | 求求大家交作业别再命名“最终版5打死不改版”了，找起来两眼一黑。 |
| forum-p03-2 | godot_native/data/source/cc98.posts.json [26, "threadReplies", 2, "text"] | T03283 | 高数目录里的图书馆规则别删，022 这次要靠它确认座位。 | 提醒一下，高数目录底下夹着的那份旧版《三分钟离座法》千万别删，听说治 022 那个钉子户书包全靠它了。 |
| forum-p04-0 | godot_native/data/source/cc98.posts.json [27, "body"] | T06694 | 实测可以。余额不会影响身份校验，系统仍然要求完整走完验证流程。 | 实测汇报！校园卡只剩 0.06元 也能刷图书馆闸机做身份核验！只要不花钱打印，六分钱也是有合法身份的！ |
| forum-p04-1 | godot_native/data/source/cc98.posts.json [27, "threadReplies", 1, "text"] | T06705 | 刷卡声很响，余额数字很小。旁边排队的人全听见了。 | 草，刚才在闸机前“滴”得超大声，屏幕蹦出个 0.06，后面排队的学妹憋笑憋得好辛苦。 |
| forum-p04-2 | godot_native/data/source/cc98.posts.json [27, "threadReplies", 3, "text"] | T06713 | 从求是潮骑去充值点再回来，比这次校验本身久。 | 六分钱战神，连去求是潮充值的电瓶车费都不够，但用来过门禁足够了。 |
| forum-p05-0 | godot_native/data/source/cc98.posts.json [28, "body"] | T06727 | 体艺记录显示四十七次通行，实际过程是在求是潮两侧反复寻找能走的缝隙。 | 体艺App显示我今天通行了 47次，其实我只是在求是潮门口堵车，围着同一辆单车疯狂找缝钻…… |
| forum-p05-1 | godot_native/data/source/cc98.posts.json [28, "threadReplies", 0, "text"] | T06734 | 从 17:28 到 17:42，我绕同一辆车四十七次。打印队都没它绕得久。 | 好家伙，从 17:28 绕到 17:42，原地鬼打墙十来分钟，步数全进账了，人还在原地没挪窝。 |
| forum-p05-2 | godot_native/data/source/cc98.posts.json [28, "threadReplies", 5, "text"] | T06754 | 记录有效。位移反复发生，终点未到。这条路线该单列。 | 还差最后一次满48次是吧？经典的卡47次定律。 |
| forum-mood-room-01-0 | godot_native/data/source/cc98.posts.json [0, "body"] | T06196 | 桌面上摊着好几件事，越想一起做越动不了。现在打算只写三项：回一条必要消息、整理十分钟资料、按时去吃饭。还有人用过更小的清单吗？ | 三个DDL加一份实验报告同时糊脸上，盯着电脑发呆半小时一个字没敲出来……算了，今天能把早饭吃了、回导师一条消息就算成功，摆烂了家人们。 |
| forum-mood-room-01-1 | godot_native/data/source/cc98.posts.json [0, "threadReplies", 0, "text"] | T06203 | 先写一件完成后能立刻划掉的小事，别把清单当成新的压力。 | 先去食堂干饭！在寝室多坐五分钟只会多刷五分钟手机，别问我怎么知道的。 |
| forum-mood-room-01-2 | godot_native/data/source/cc98.posts.json [0, "threadReplies", 1, "text"] | T06207 | 去食堂这一项保留。先离开桌面五分钟，回来再看下一项。 | 我先把To-Do List第一条写成“打开Word”，划掉那一刻成就感拉满ac01。 |
| forum-mood-room-02-0 | godot_native/data/source/cc98.posts.json [1, "body"] | T06213 | 下午投完一份材料，之后每隔几分钟就去看一次邮箱。明知道这么快不会有结果，还是控制不住。想把提醒关掉，又怕错过消息。 | 下午刚给老师发完套磁/申请邮件，现在每隔三分钟就忍不住点开浙大邮箱刷一次，手机快被我刷没电了，救命，怎么戒掉这个毛病…… |
| forum-mood-room-02-1 | godot_native/data/source/cc98.posts.json [1, "threadReplies", 0, "text"] | T06220 | 给邮箱设两个固定查看时段，其他时间把页面关掉。我把时间写在日历里会更容易执行。 | 把邮箱通知关了去睡一觉吧，薛定谔的回复，你不看它的时候老师才回得快。 |
| forum-mood-room-02-2 | godot_native/data/source/cc98.posts.json [1, "threadReplies", 1, "text"] | T06224 | 投递回执留好就够了。下一步应由对方完成，反复刷新不会改变材料状态。 | 只要已发送里有记录就稳了，你就算把F5按穿，老师该摸鱼还是在摸鱼。 |
| forum-smile-room-01-0 | godot_native/data/source/cc98.posts.json [12, "body"] | T06400 | 坐下后发现周围的人全在复习我完全没学过的内容。我还坚持记了两行笔记，直到有人问我是哪门课的才看见日期。 | 人在大西区，刚坐下发现周围同学全在狂背我完全没见过的公式，我还硬着头皮抄了两行板书，结果旁边的老哥幽幽问我一句：“同学，你也来考微积分重修？”——低头一看课表，我的课是明天的…… |
| forum-smile-room-01-1 | godot_native/data/source/cc98.posts.json [12, "threadReplies", 0, "text"] | T06407 | 我更进一步，听完半节才发现自己没有选这门课。 | 哈哈哈哈哈哈甚至还认真记了两行笔记，感天动地！ |
| forum-smile-room-01-2 | godot_native/data/source/cc98.posts.json [12, "threadReplies", 1, "text"] | T06411 | 下次先看门口的课表。你至少提前到了。 | 不亏，四舍五入相当于提前一天预习了下学期的重修内容（逃。 |
| chapter4-prologue-2 | godot_native/data/native/chapter4-native-source.json ["prologue", "subtitles", 1, "text"] | T04266 | 湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。 | 湖水没有留住它。晚风裹着那张纸条，一路吹进了还亮着灯的段永平教学楼。 |
| chapter4-prologue-3 | godot_native/data/native/chapter4-native-source.json ["prologue", "subtitles", 2, "text"] | T04268 | 小心，刚拖过。那张纸往里去了。 | 哎同学当心脚下，刚拖的地！你追的那张纸片往大厅里头飞了。 |
| chapter4-prologue-4 | godot_native/data/native/chapter4-native-source.json ["prologue", "subtitles", 3, "text"] | T04270 | 同学，北教要清楼了，请收好东西。 | 同学，北教马上二十三点清楼了啊，拿完东西赶紧出来！ |
| table-wake_narration | godot_native/scripts/main.gd [] | T07989 | 你没有5分钟了，但你很有勇气 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬 |
| table-wake_narration | godot_native/scripts/ui/phone_pages.gd [] | T05690 | 你没有5分钟了，但你很有勇气 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬。 |
| table-wake_flash | godot_native/scripts/main.gd [] | T07988 | 起床蠢货！！！ | 还睡？！早八要迟到了！！ |
| table-wake_flash | godot_native/scripts/chapters/chapter1_2.gd [] | T00635 | 起床蠢货！！！ | 还睡？！早八要迟到了！！ |
| table-xy_laugh | godot_native/scripts/ui/phone_pages.gd [] | T05742 | 找你的数字去吧哈哈哈 | 签到码给你拆碎咯，慢慢找去吧哈哈哈！ |
| table-prologue_narrator_caught | godot_native/scripts/games/prologue_interception.gd [] | T00793 | 旁白：嘿！你到底在干什么？放开我！ | 旁白：喂！你拽我弹窗干什么？！快松手！要未响应了！ |
| table-player-threat | godot_native/scripts/games/prologue_interception.gd [] | T00794 | 玩家：不，除非你帮助我 | 玩家：帮我补签到！ |
| table-player-threat | godot_native/scripts/games/prologue_interception.gd [] | T00795 | 玩家：不然你就和我的绩点同归于尽吧 | 玩家：不帮就一起死机！ |
| table-prologue_narrator_bargain | godot_native/scripts/games/prologue_interception.gd [] | T00796 | 旁白：哦，好吧，好吧！但你先把手放开！ | 旁白：行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！ |
| table-act2_character_cannot_hear | godot_native/scripts/chapters/chapter1_2.gd [] | T00713 | 他听不到你说话。现在的他连一个能回应的名字都没有。 | 别戳他了，他听不见。没绑定姓名和学号之前，他就是个没加载完的默认建模。 |
| table-act2_mentor_line_stuck | godot_native/scripts/chapters/chapter1_2.gd [] | T00736 | 那条竖线粘住了。看来导师头像也有自己的排版要求。 | 这根分割线焊得死死的。毕竟是导师的对话框，连排版都透着一股压迫感。 |
| table-act2_gamepad_purchase_rejected | godot_native/scripts/chapters/chapter1_2.gd [] | T00744 | 你只有零点零六元。卖家拒绝了你分一百期付款的方案。 | 全身上下六分钱，还想跟98卖家分一百期买手柄？人家直接把你拒了。 |
| table-act2_balance_shifted | godot_native/scripts/chapters/chapter1_2.gd [] | T00740 | 小数点向右移动了两位。六分钱暂时获得了六元钱的尊严。 | 小数点右移两位！0.06 秒变 6.00 元——趁财务系统还没反应过来，赶紧去98把二手手柄付了！ |
| chat-T00655 | godot_native/scripts/chapters/chapter1_2.gd [] | T00655 | 朋友：快快老师在点名，学在浙大。 | 朋友：速来！老头突然开始点名了，学在浙大雷达签到！ |
| chat-T00531 | godot_native/scripts/chapters/chapter1_2.gd [] | T00531,T00703 | 朋友：成功了吗<br>玩家：没有，但我正试着威胁系统<br>朋友：？ | 朋友：签上了吗？？<br>玩家：没赶上。但我刚把弹窗卡死了，正在逼系统给我改后台。<br>朋友：？你没睡醒吧 |
| canteen-chicken-1 | godot_native/scripts/games/canteen_defense.gd [] | T02981,T02983,T02984 | 玩家：那是鸡吗？ | 玩家：纸包鸡……飞了？！ |
| canteen-chicken-1 | godot_native/scripts/presentation/c3_pickup_timeline.gd [] | T02244 | 玩家：那是鸡吗？ | 玩家：纸包鸡……飞了？！ |
| canteen-chicken-2 | godot_native/scripts/games/canteen_defense.gd [] | T02982,T02985,T02986 | 系统：现在不是了。 | 系统：包装纸被纸条策反了！ |
| canteen-chicken-2 | godot_native/scripts/presentation/c3_pickup_timeline.gd [] | T02245 | 系统：现在不是了。 | 系统：包装纸被纸条策反了！ |
| table-wake_narration | godot_native/scripts/chapters/chapter1_2.gd [] | T00636 | 你没有5分钟了，但你很有勇气。 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬。 |
| table-wake_flash | godot_native/scripts/ui/phone_pages.gd [] | T05692 | 起床蠢货<br>！！！ | 还睡？！<br>早八要迟到了！！ |
| chat-T00655 | godot_native/scripts/ui/phone_pages.gd [] | T00828,T05730 | 快快老师在点名，学在浙大。 | 速来！老头突然开始点名了，学在浙大雷达签到！ |
| chat-T00655 | godot_native/scripts/ui/phone_pages.gd [] | T02050 | 快快老师在点名，学在浙大 | 速来！老师开始雷达签到！ |
| chat-T00531 | godot_native/scripts/ui/phone_pages.gd [] | T00827,T02048,T05736 | 成功了吗 | 签上了吗？？ |
| chat-T00531 | godot_native/scripts/ui/phone_pages.gd [] | T05737 | 没有，但我正试着威胁系统 | 没赶上。但我刚把弹窗卡死了，正在逼系统给我改后台。 |
| table-xy_attack | godot_native/scripts/ui/phone_pages.gd [] | T05740 | 等等等等，你想翘课？没门！ | 等等——人还在被窝里就想隔空签到？ |
| table-xy_attack | godot_native/scripts/ui/phone_pages.gd [] | T05741 | 我不会让你签上的！ | 想得美！这分我今天扣定了！ |
| chat-T00531 | godot_native/scripts/ui/phone_pages.gd ["_friend_chat", "question"] | T00531 | ？ | ？你没睡醒吧 |
| chat-T00655 | godot_native/scripts/chapters/chapter1_2.gd ["view", "wechat", "body"] | T00655 | 朋友　07:55<br>快快老师在点名，学在浙大 | 朋友　07:55<br>速来！老头突然开始点名了，学在浙大雷达签到！ |

## 已配音中文差异审稿

这些行仍播放原英文录音。中文新增的细节、吐槽和叙事解释不会自动出现在英文中；此表明确交付该差异，未生成或替换配音。

| 稳定voice key | 原中文 | 新中文 | 保留的英文 |
|---|---|---|---|
| wake_narration | 你没有5分钟了，但你很有勇气 | 早八快上课了。不得不说，你还敢赖床，心理素质真硬。 | You do not have five minutes. Still, the confidence is impressive. |
| wake_flash | 起床蠢货！！！ | 还睡？！早八要迟到了！！ | Wake up, idiot! |
| xy_attack | 等等等等，你想翘课？没门！我不会让你签上的！ | 等等——人还在被窝里就想隔空签到？想得美！这分我今天扣定了！ | Wait, wait, wait. You are trying to skip class? Absolutely not. I am not letting you check in. |
| xy_laugh | 找你的数字去吧哈哈哈 | 签到码给你拆碎咯，慢慢找去吧哈哈哈！ | Go find your digits. All four of them. Ha. |
| prologue_narrator_intro | 噗，哦抱歉，我没别的意思，只是……这看起来不像成功了对吧。我想你只好乖乖起来滚去上课了。祝你好运，孩子！我要走了！ | 噗……不好意思啊，没忍住。签到又报错了！看来你只能认命爬起来去教室解释了。祝你好运咯，同学，我下班了！ | Pfft, oh, sorry. I did not mean anything by it. It is just... this does not look like a success, does it? I suppose you will have to get up, drag yourself to class, and deal with it. Good luck, kid! I am leaving! |
| prologue_narrator_caught | 嘿！你到底在干什么？放开我！ | 喂！你拽我弹窗干什么？！快松手！要未响应了！ | Hey! What exactly do you think you are doing? Let go of me! |
| prologue_narrator_bargain | 哦，好吧，好吧！但你先把手放开！ | 行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！ | Oh, fine, fine! But first, take your hand off me! |
| act2_system_found_intro | 哦，该死。你赢了，孩子。 | ……服了你了。为了不陪你一起蓝屏，我认栽。 | Oh, damn it. You win, kid. |
| act2_system_inventory_demand | 行。把你的道具栏拿出来。 | 来，先把你的道具栏调出来，咱们准备动身。 | Fine. Bring out your inventory. |
| act2_system_inventory_missing | 等等，你的道具栏呢？你总不能指望我空手干活！ | ……等等，你连道具栏都没加载？你不会指望我徒手给你黑进系统吧！ | Wait. Where is your inventory? You cannot expect me to work empty-handed! |
| act2_system_departure | 你找到了，那就太好了，我们出发吧！ | 总算找着了。行，那赶紧操作你床上的身体出门吧！ | You found it. Great. Then let us get moving. |
| act2_system_confession | 我得说实话了，我没有修改记录权限 | 但丑话说在前头，我只是个前端提示音，没有直接篡改教务考勤的权限。 | I should be honest. I do not have permission to edit attendance records. |
| act2_system_friend | 但我有一个朋友她或许能做到 | 不过……我在图书馆有个老熟人，她手里有底层接口，或许能帮你把时间改回去。 | But I have a friend who might. |
| act2_system_library | 如果我们还想要平时分，就得去图书馆找她 | 想保住你的平时分，现在就得去基础馆一楼找她。 | If we still want your participation grade, we need to find her in the library. |
| c3_canteen_queue_system | 系统：它可能只是来体验一下排队，很多东西在食堂都会排队。 | 系统：连一张逃跑的异常纸条，进了浙大食堂都得老老实实排队。 | Maybe it only came to experience the queue. Many things end up queuing in a cafeteria. |
| c3_canteen_bun_system | 系统：它看起来不像纸条会吃的东西，虽然纸条也不该吃东西。 | 系统：这包子连馅儿都是实的，藏不进纸条。再说了，纸条也不吃碳水。 | That does not look like something a paper slip would eat. Admittedly, paper should not eat at all. |
| c3_canteen_breakfast_system | 系统：不是，是一份比较真实的早饭。 | 系统：没有线索，只有碳水。恭喜你获得了一份平平无奇的早饭。 | No. It is merely a disappointingly real breakfast. |
| c3_canteen_paper_chicken_system | 系统：纸包鸡。我知道的至少前两个字很有嫌疑。 | 系统：“纸包鸡”。听名字，前两个字就跟我们的目标很有缘分。 | Paper-wrapped chicken. At least the first word is suspicious. |
| c3_canteen_packaging_system | 系统：一份线索。鸡只是包装。 | 系统：我们要的是外面那层纸，里面的鸡肉纯属赠品。 | One clue. The chicken is only packaging. |
| c3_canteen_cold_clue_system | 系统：这份粥很热，但线索很冷。 | 系统：粥还烫嘴，但线索已经断了。换个窗口找找吧。 | The congee is hot. The clue is cold. |
| c3_canteen_worldview_system | 系统：请不要拓展世界观。 | 系统：打住，别在这种地方强行发散思维。 | Please do not expand the worldbuilding. |
| c3_canteen_paper_impact_narrator | 纸条撞回食堂，掉下一点蓝光。 | 纸条撞回食堂，抖落了一地蓝色的数据残影。 | The paper crashes back into the cafeteria and sheds a flicker of blue light. |
| c3_canteen_paper_angry_narrator | 纸条急了，它开始不尊重取餐流程。 | 纸条急眼了，决定直接插队硬闯取餐口！ | The paper is getting desperate. It has stopped respecting the pickup procedure. |
| c3_canteen_self_service_system | 系统：自助服务发展到这一步，我有点害怕。 | 系统：现在的食堂自助取餐，已经进化到全自动打架了吗？ | Self-service has advanced too far. I am mildly concerned. |
| c3_bike_human_speed_system | 系统：你正在以“没吃早饭的人类速度”移动。 | 系统：靠你这两条没吃早饭的腿，是追不上风的。找辆共享单车吧。 | You are moving at the speed of a human who skipped breakfast. |
| c3_bike_gpa_system | 系统：它没有绩点负担。 | 系统：人家只是一张纸，可没有挂科扣绩点的心理负担，当然飞得快。 | It carries no grade-point burden. |
| c3_bike_no_money_system | 系统：这句话在本游戏里出现频率太高了。 | 系统：“余额不足”这四个字，今天真是刻进你DNA里了。先去帮阿姨收盘子赚钱吧。 | That sentence occurs far too often in this game. |
| c3_theater_failure_narrator | 旁白：失败得很慷慨。 | 旁白：摔得十分干脆，连体面都没留。 | A remarkably generous failure. |
| c3_theater_logic_system | 系统：台上的顺序改过，印刷版未必跟得上。 | 系统：彩排临时改过场次顺序，纸质节目单早就过时了。得看现场的痕迹。 | They changed the running order. The printed program may be out of date. |
| c3_theater_celebrate_system | 系统：先翻过来看。 | 系统：别高兴得太早，把纸条翻过来看看背面。 | Turn it over first. |
| c3_theater_substitute_system | 系统：替身有编号。原件去向不在节目单里。 | 系统：背面印着剧社的道具编号。这是张舞台替身，真家伙早就趁乱溜出剧场了。 | The substitute has a serial number. The program says nothing about where the original went. |
| c3_qizhen_no_trail_system | 系统：不知道。它这次没有沿路掉纸屑。 | 系统：跟丢了。这次它学精了，沿路半点蓝光都没漏。 | No idea. This time it left no paper scraps along the road. |
| c3_qizhen_forum_system | 系统：老办法，发个论坛问问。 | 系统：遇事不决上 98。发个悬赏帖，让全校的夜猫子帮你找。 | Use the old method. Ask the campus forum. |
| c3_qizhen_cc98_system | 系统：CC98 提供了一个非常精确的范围：不是厕所。 | 系统：98 老哥给出了极其严谨的排除法：至少没飞进厕所。 | CC98 has provided a highly precise range: not the restroom. |
| c3_qizhen_catalog_system | 系统：意思是它现在比我们更艺术。 | 系统：馆藏线索指向湖岸与倒影……看来这张纸条还挺讲究意境。 | It means the paper is currently more artistic than we are. |
| c3_qizhen_map_system | 系统：恭喜，你完成了一次校园级猜谜。 | 系统：三条线索拼齐——目标锁定，启真湖！ | Congratulations. You have completed a campus-scale guessing game. |
| c3_qizhen_reflection_system | 系统：准确来说，是在倒影里。 | 系统：它没泡在水里，是卡在湖面的倒影图层里了。 | More precisely, it is inside the reflection. |
| c3_qizhen_swimming_system | 系统：对不会游泳的人来说区别很大。 | 系统：别想不开往水里跳，你体艺游泳课还没修呢。找船过去。 | For someone who cannot swim, the difference is substantial. |
| c3_qizhen_gone_system | 系统：它又消失了。 | 系统：水波一晃，它又缩回深色倒影里了。 | It disappeared again. |
| c3_qizhen_sign_system | 系统：通常这里不应该有给我们指指路的牌子吗？ | 系统：岸边那块旧指示牌木头不错，拆下来正好当右船桨使。 | Should there not be a sign around here to point us somewhere? |
| c3_qizhen_hiding_system | 系统：这就是它躲藏的地方，哈 | 系统：锁定坐标了！它就猫在这片倒影底下。 | So this is where it is hiding. Hah. |
| c3_qizhen_fake_system | 系统：就是这个假的 | 系统：把刚才在剧场抓到的那张假替身挂在鱼钩上！ | Use the fake one. |
| c3_qizhen_ego_system | 系统：因为它不能接受别人替它逃跑。 | 系统：一个占了三天座位的老赖，绝对容不下冒牌货顶替它的位置。 | Because it cannot tolerate someone else escaping in its place. |
| c3_qizhen_atmosphere_system | 系统：你只是让湖更有氛围了。 | 系统：偏了！你这杆甩下去，除了惊起两圈水波啥也没钓着。 | You have only made the lake more atmospheric. |
| c3_qizhen_taunt_system | 系统：还在嘲笑你的倒影。 | 系统：瞧见没，水底下的正主正隔着倒影看你笑话呢。对准点！ | It is still mocking your reflection. |
| c3_qizhen_grab_system | 系统：能抓了！ | 系统：趁现在，按住它！ | You can catch it now! |
| ch4_prologue_narrator_01 | 湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。 | 湖水没有留住它。晚风裹着那张纸条，一路吹进了还亮着灯的段永平教学楼。 | The lake did not keep it. The night wind carried it into the teaching building that was still lit. |
| ch4_prologue_cleaner_01 | 小心，刚拖过。那张纸往里去了。 | 哎同学当心脚下，刚拖的地！你追的那张纸片往大厅里头飞了。 | Careful, I just mopped. That paper went inside. |
| ch4_prologue_guard_01 | 同学，北教要清楼了，请收好东西。 | 同学，北教马上二十三点清楼了啊，拿完东西赶紧出来！ | The North Teaching Building is closing. Please pack up. |

## 未自动扩写的范围

附件只给诊断而未提供明确新句的其他CC98帖子及章节不批量重写；新增插话无原槽位的部分列待决。原React历史与独立样片保持原文。
