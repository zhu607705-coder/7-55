# Human Writing 文案审查规范

## 来源与用途

游戏中的论坛回复、NPC 对白、玩家可选发言和叙事短句，统一参考 `KKKKhazix/human-writing` 的 `human-writing/SKILL.md` 及其 `fiction.md`、`forum-prose.md`、`revision.md` 规则进行创作和修订。

该仓库提供的是写作与修订工作流。游戏运行时读取已经通过审查的本地文案池，不把在线模型生成放进主线逻辑。这样可以保留离线单文件、固定存档重放、自动化测试和跨浏览器一致性。

## 文案分层

### social

适用于 CC98 主帖、楼主回帖、普通用户回复、群聊消息。

要求：

- 先回答“这个人为什么现在要回复”。
- 只说发帖者当前知道的事，不替任务系统解释隐藏条件。
- 允许短句、省略、追问、补充、纠正和不完整表达。
- 同一楼层不要求承担笑点，也不要求每条回复都完整收束。
- 回复长度、标点和语气要有差异。
- 角色差异来自身份、经历、关系和当下处境，不靠重复口癖。

### dialogue

适用于系统、玩家、阿姨、检票员、朋友等有明确说话者的对白。

每条对白写作前至少确定：

- speaker：谁在说。
- objective：他此刻想得到什么。
- knowledge：他实际知道什么。
- relationship：他和玩家是什么关系。
- pressure：当前有没有时间、危险、尴尬或利益压力。

对白不承担完整教程。需要操作说明时，由 task / hint / feedback 层补充。

### narration

只描述玩家此刻能够观察到的变化，或提供必要的叙事节奏。避免替角色解释动机，也避免连续使用作者式评价。

### system / task / feedback

操作正确性优先。

- 明确说明下一步动作、失败原因和恢复方式。
- 不为了口语化删除关键按键、模式、坐标、距离或状态条件。
- 可以简短，但不能含糊。
- 同一信息不在对白和任务提示中重复解释两遍。

## 禁止倾向

以下情况默认进入重写：

1. 每个 NPC 都像在写一句完整段子。
2. 大量使用“剧情、世界观、证据链、流程完整性、系统判定”等角色无法自然说出的元叙事词。
3. 一句话同时解释机制、评价玩家并给下一步任务。
4. 所有回复长度相近，句式都由“陈述 + 转折 + punchline”组成。
5. 角色在没有信息来源时准确说出隐藏条件。
6. 论坛用户轮流替设计者复述任务目标。
7. 为了显得自然而故意加入大量网络梗、错别字或固定口癖。
8. UI 错误提示被改得有趣却无法判断失败原因。

## CC98 回复数据约定

新动态论坛回复建议按以下语义字段设计，再映射到现有运行时结构：

```ts
interface ForumReplyVariant {
  personaId: string;
  trigger: string;
  intent: "react" | "ask" | "correct" | "warn" | "share" | "joke";
  knowledge: string[];
  text: string;
  excludes?: string[];
}
```

运行时根据 `threadSeed + 已公开状态标签` 确定性选择回复。禁止把隐藏任务变量直接暴露给回复生成器。

推荐公开标签示例：

- `photo_stable`
- `photo_shaky`
- `dock_photo`
- `dock_collision_seen`
- `reflection_clear`
- `reflection_rippled`
- `swan_far`
- `swan_close`
- `capsized_once`
- `capsized_multiple`
- `chase_finished`
- `summary_safe`
- `summary_private`

## 人设检查

删除昵称后再读一遍回复：

- 如果六个人说出来都完全成立，角色区分不足。
- 如果只能靠口癖判断是谁，角色设计过度依赖表面风格。
- 如果角色每次出现都在做同一种笑点，人设已经变成模板。

CC98 现有六个常驻账号的区别应主要体现在信息来源：

- `late-printer`：时间敏感，常问实时状态。
- `yuquan-wind`：路过型，愿意补现场照片和即时观察。
- `socket-observer`：图书馆和固定地点经验较多。
- `qiushi-rider`：校园通行与骑行经验较多。
- `six-cent-rich`：校园卡和低余额经历较多，偶尔自嘲。
- `wild-auditor`：会翻前楼、核时间戳、补充可验证信息。

这只是知识来源和行为倾向，不要求每次发言都强化标签。

## 交付前四问

每条 social / dialogue 文案至少检查：

1. 这个人为什么现在开口？
2. 他凭什么知道这件事？
3. 这句话删掉后，任务信息是否仍由正确的 UI 层承担？
4. 这句话听起来像一个人在回应眼前情况，还是像作者在展示文案能力？

任一问题无法回答，就继续改。

## 当前审查策略

本次文案修订先覆盖：

- `src/data/cc98.posts.json`
- `src/data/cc98.thread-personas.json`
- `src/data/act-one-bootstrap.content.json`
- `src/data/dialogue.lines.json`
- `src/data/chapter3-canteen.content.json`
- `src/data/chapter3-theater.content.json`
- `src/data/chapter3-qizhen-lake.content.json`
- `src/data/chapter3-story-lines.json`

第四章以功能性提示和官方通知为主，当前仅做审查，不为追求口语化强行修改。后续新增论坛、群聊、NPC 和玩家发言继续按本文件执行。
