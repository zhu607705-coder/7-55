# 微信会话阶段、气泡与开场内容（2026-10-25）

## 本地候选范围

历史候选基线：`0c01f5c45a7efbc42b7759af9df86a0fea4932ec`（PR #172 合并后的 main）。用户后续明确整体合并，当前内容已纳入 [统一集成记录](INTEGRATION_20261025.md)；下列历史专项不单独代表最终集成发布。

- 微信朋友会话按当前章节/阶段选择内容。第二章不再依赖第一章 `codeScattered` 动画标记；第一章签到提醒默认收入可展开的旧记录。后续章节不显示过期的第一章任务。
- 消息由独立 `wechat_message_bubble.gd` 对象持有头像、内边距和正文。使用 Container 计算换行高度；页面用独立滚动区，避免固定高度气泡容纳多行文字。
- 微信、联系人、发现、我的均有真实页面。两个公众号、9 篇内容、4 条朋友圈、室友/导师会话从开场可读。点赞与浏览位置只属于本次浏览，不生成存档事实；“我赞过的动态”显示实际点赞集合。
- 体艺更新卡仍由既有章节、发现、联网、获取、安装顺序控制。开场阅读服务说明不能提前发现/安装更新。湖面地点词仍等原对话到齐后由玩家明确保存。
- 原主线台词、配音、数字动画时序、物品 ID、谜题答案和控制器不修改。保留 Web 源代码作为行为参考；本轮新增表现属于 Godot。

## 文案来源与审阅

使用 Computer Use 在 Gemini 网页确认并选中 **3.8 Flash / 低**。用户要求只提供场景后，重新打开空白对话，仅提交校园场景、人物关系、功能边界和存储字段；此前给过示例的草稿已弃用。

采用纯场景生成的最终 JSON，再按 [Humanizer-zh](https://github.com/op7418/Humanizer-zh/blob/main/SKILL.md)（2026-09-23 修订）审阅。去掉模板化句式；校正木盒/玻璃盒/塑料盒的自相矛盾和不应被当作地图坐标的具体楼层；去除擅自添加的服务承诺与操作规则。公众号日常、朋友圈和闲聊不充当新的解谜线索。

最终文案集中在 `data/native/wechat-social-content.json`。后勤文章沿用来源文章 ID、发布日期和其他元数据，展示正文单独维护；原第四章夜间通知及其证据字段不提前开放。原始模型回传、摘要与审阅差异保留在外部验证目录 `wechat-social-20261025`。

## 验证记录

- `sync_source.mjs`：通过，721 项来源资源同步。没有新媒体，构建仍使用已有媒体转换与校验。
- `validate:quick`：5/5 通过。
- `validate_native.mjs --filter ...`：10 个相关阶段通过。其中 7 个原生页面/流程测试共 1269 项，另含中文来源、音文约束及第一章时序来源核对。
- 新增测试覆盖早期浏览不改剧情、公众号完整返回链、点赞筛选与滚动位置、旧进度标记、最大字体、手机外部缩放、长中文及连续英文的气泡几何。已有湖区路线 617 项、体艺更新 61 项及第一章生命周期 208 项通过。
- 初次 release 的 4 个失败均因当前 shell 缺少 ffprobe；使用宿主已有媒体工具后重新执行，release 38/38 通过，包括保留 Web 的 4 个浏览器烟测场景。
- 最终文案校正后，新增气泡/社交测试再次通过 122 项；Godot 4.7.1 最终导出的 source-input SHA 为 `51ddbf7b1a2b3cae655f4fb8fc03ada45750fc6b21850a4703a7c7ef532e0072`。导出 PCK 中的文案 SHA 与本地 JSON 相同：`da7df96bde59aa0bcec23963e60065ab43151693a4979b1491159c34b5823d54`。
- 实际 Godot Web 的 Chrome 桌面 1280×720 与模拟触屏 390×844 / DPR3 各 882 项通过，浏览器无报错。普通点击/触摸验证开场公众号、朋友圈点赞与筛选、页面返回链，以及旧聊天展开/收起；浏览不会修改剧情事实。
- 使用线上第二章存档的副本，经正式导入入口复现 `friend_message_required` 且 `codeScattered=false` 的状态。当前朋友会话正确播放原第二章台词并进入 `system_required`；第一章提醒仅在手动展开历史时出现。另在 430×860 与缩放手机尺寸检查了实际气泡内边距和文字容纳；没有修改线上存档。
- 临时桌面/触屏截图已逐张检查并清理；保留外部测试记录及一张供用户查看的朋友圈预览。
- 未把这些针对性测试描述为全游戏验收或实体手机验收；Git 提交、云端检查及线上发布另行确认。

## 待提交清单

1. `godot_native/data/native/wechat-social-content.json`
2. `godot_native/scripts/ui/wechat_message_bubble.gd`
3. `godot_native/scripts/ui/wechat_social_pages.gd`
4. `godot_native/scripts/ui/phone_pages.gd`
5. `godot_native/scripts/ui/phone_entry_visual.gd`
6. `godot_native/scripts/ui/c3_lake_app_context.gd`
7. `godot_native/tests/test_wechat_social_pages.gd`
8. `godot_native/tests/test_phone_navigation.gd`
9. `godot_native/docs/WECHAT_SOCIAL_20261025.md`
10. `progress.md`

`node_modules` 是既有本地依赖链接，不提交。导出、下载草稿和验证产物均不加入 Git。

后续用户追加的体艺、连续定位、校园服务、课程参考和设置改造已合并为同一候选。当前完整范围以 [手机界面与校园服务清单](TIYI_VISUAL_20261025.md#当前完整待提交清单) 的 41 文件为准；上面的 10 文件是微信阶段记录，不作为新的提交授权。
