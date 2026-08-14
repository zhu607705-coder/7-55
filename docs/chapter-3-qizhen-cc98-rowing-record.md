# 启真湖 98 划船记录

## 目标

完成上船教学并连续正确划桨后，玩家在湖心完成第一次拍照并发布一条 CC98 主帖。主帖发布后开放钓鱼探索。后续小码头、湖心倒影、黑天鹅区三处照片都追加到同一主题，不创建新帖。

论坛承担章节记录和环境反馈。主线条件继续由任务系统负责，普通回复不会泄露隐藏判定、奖励阈值或后续事件。

## 线程结构

```text
主帖：第一次湖心打卡
├─ 普通回复 1~2 条
├─ 楼主补图：小码头（可选）
│  └─ 普通回复 0~2 条
├─ 楼主补图：湖心倒影（可选）
│  └─ 普通回复 0~2 条
├─ 楼主补图：黑天鹅区（可选）
│  └─ 普通回复 0~2 条
└─ 楼主总结：追逐结束后开放
   └─ 普通回复 1~2 条
```

普通回复总量建议控制在 6~9 条。同一存档由 `threadSeed` 决定回复选择和顺序，重载后保持一致。

## 主帖

### 标题

默认：

> 【启真湖划船记录】第一次下水，船还在

备选：

> 启真湖第一次划船，拍到湖心了

> 今天学会一件事：船真的会转

### 状态

玩家三选一：

> 湖心风比岸上大一点。先发一张，等会儿再划。

> 教学过了，实际操作还在摸索。

> 目前人、手机、船都在。

标题和状态只影响回复语气，不改变任务结果。

## 照片公开标签

论坛只读取玩家已经公开展示出来的信息。

```ts
type RowingThreadTag =
  | "photo_stable"
  | "photo_shaky"
  | "capsized_once"
  | "capsized_multiple"
  | "glasses_lost"
  | "dock_photo"
  | "dock_collision_seen"
  | "reflection_clear"
  | "reflection_rippled"
  | "swan_far"
  | "swan_close"
  | "chase_finished"
  | "summary_safe"
  | "summary_private";
```

`capsized_once`、`capsized_multiple` 只有在论坛照片、楼主文字或已经公开的章节事件足以让回复者合理推断时才进入回复上下文。隐藏的精确翻船次数不直接提供给论坛。

## 回复数据结构

```ts
interface RowingForumReplyVariant {
  id: string;
  personaId: string;
  triggerAny?: RowingThreadTag[];
  triggerAll?: RowingThreadTag[];
  excludes?: RowingThreadTag[];
  intent: "react" | "ask" | "warn" | "share" | "correct" | "joke";
  text: string;
}
```

选择规则：

1. 仅在楼主新发布一层后计算一次。
2. 每次从满足标签的候选池抽取 0~2 条。
3. `threadSeed + ownerFloorId` 决定确定性顺序。
4. 同一文本在一个主题内最多出现一次。
5. 连续两层尽量不由同一账号首发。
6. 普通账号允许只问问题或只补一条现场信息，不要求每层都给结论。
7. 回复不得读取 `fishingAssistUnlocked`、`memoryCardUnlocked`、追逐触发阈值等隐藏状态。

## 人物来源

可以复用全局 CC98 账号，也允许加入只在启真湖主题出现的一次性账号。

### 全局账号

`late-printer`

偏实时追问，关注发帖时间和刚发生的变化。

`yuquan-wind`

路过型账号，愿意补现场观察和照片。

`socket-observer`

在湖区没有特殊知识，出现频率应低于图书馆主题。

`qiushi-rider`

熟悉校园移动，对船只操作只发表普通体验，不装成专业划船者。

`six-cent-rich`

可以自嘲，避免每条回复都围绕余额。

`wild-auditor`

会翻楼层、核对照片前后变化，适合追逐结束后的回看。

### 湖区一次性账号

建议增加：

```json
[
  { "id": "lake-walker", "nickname": "启真湖散步中" },
  { "id": "dock-passby", "nickname": "刚从小码头回来" },
  { "id": "swan-detour", "nickname": "黑天鹅绕行派" },
  { "id": "rowing-newbie", "nickname": "划船第二次" }
]
```

这些账号只提供合理的信息来源，不需要设计固定口癖。

## 主帖回复池

### 照片较稳定 `photo_stable`

```json
[
  {
    "id": "main-stable-01",
    "personaId": "lake-walker",
    "intent": "react",
    "text": "这个角度挺好，今天湖面也挺平。"
  },
  {
    "id": "main-stable-02",
    "personaId": "rowing-newbie",
    "intent": "ask",
    "text": "你这是划到哪一段拍的？我上次一直没敢去中间。"
  },
  {
    "id": "main-stable-03",
    "personaId": "qiushi-rider",
    "intent": "share",
    "text": "看起来比我第一次直多了，我当时拍出来船头一直在左边。"
  }
]
```

### 照片晃动 `photo_shaky`

```json
[
  {
    "id": "main-shaky-01",
    "personaId": "lake-walker",
    "intent": "ask",
    "text": "照片有点糊，你拍的时候还在划吗？"
  },
  {
    "id": "main-shaky-02",
    "personaId": "rowing-newbie",
    "intent": "warn",
    "text": "先把船停一下再拍吧，船头已经偏过去了。"
  },
  {
    "id": "main-shaky-03",
    "personaId": "yuquan-wind",
    "intent": "react",
    "text": "这张看着就很忙。"
  }
]
```

### 已公开翻船一次 `capsized_once`

```json
[
  {
    "id": "main-cap-01",
    "personaId": "dock-passby",
    "intent": "ask",
    "text": "你这帖是不是中途湿过一次？"
  },
  {
    "id": "main-cap-02",
    "personaId": "wild-auditor",
    "intent": "react",
    "text": "现在回头看，标题里的“船还在”确实有必要。"
  }
]
```

### 已公开多次落水 `capsized_multiple`

```json
[
  {
    "id": "main-cap-many-01",
    "personaId": "dock-passby",
    "intent": "warn",
    "text": "先别补图了，救生衣穿好再说。"
  },
  {
    "id": "main-cap-many-02",
    "personaId": "lake-walker",
    "intent": "ask",
    "text": "你今天是不是已经回过几次码头了？"
  }
]
```

### 眼镜已丢失 `glasses_lost`

```json
[
  {
    "id": "main-glasses-01",
    "personaId": "yuquan-wind",
    "intent": "ask",
    "text": "等等，你眼镜呢？"
  }
]
```

## 小码头楼主补图

### 楼主文字

玩家三选一：

> 码头这边拍一张。救生圈位置先记住了。

> 回到岸边附近，顺便把船和警示牌拍进去。

> 这边转弯比我想的窄一点。

### 常规回复 `dock_photo`

```json
[
  {
    "id": "dock-01",
    "personaId": "dock-passby",
    "intent": "ask",
    "text": "码头那块牌子怎么少了一块？"
  },
  {
    "id": "dock-02",
    "personaId": "rowing-newbie",
    "intent": "share",
    "text": "救生圈位置拍清楚挺有用，我第一次下水前也先找这个。"
  },
  {
    "id": "dock-03",
    "personaId": "lake-walker",
    "intent": "warn",
    "text": "你离岸是不是有点近？看着都快贴上去了。"
  }
]
```

### 已公开撞码头 `dock_collision_seen`

```json
[
  {
    "id": "dock-hit-01",
    "personaId": "dock-passby",
    "intent": "ask",
    "text": "这张是在刚才那一下之后拍的吗？"
  },
  {
    "id": "dock-hit-02",
    "personaId": "lake-walker",
    "intent": "share",
    "text": "刚才岸边那声我都听见了。"
  }
]
```

## 湖心倒影楼主补图

### 楼主文字

完整倒影可选：

> 停了一会儿，水面平下来以后拍的。

> 这张等了几十秒，树影刚好出来。

水纹明显可选：

> 没完全停住就拍了，先留着。

> 水面还在晃，远岸倒是拍清楚了。

### 完整倒影 `reflection_clear`

```json
[
  {
    "id": "reflection-clear-01",
    "personaId": "yuquan-wind",
    "intent": "react",
    "text": "这张好看，树影刚好连上了。"
  },
  {
    "id": "reflection-clear-02",
    "personaId": "rowing-newbie",
    "intent": "share",
    "text": "等水面平下来再拍确实清楚很多。"
  }
]
```

### 水纹明显 `reflection_rippled`

```json
[
  {
    "id": "reflection-wave-01",
    "personaId": "lake-walker",
    "intent": "ask",
    "text": "水纹这么大，前一秒是不是刚划完？"
  },
  {
    "id": "reflection-wave-02",
    "personaId": "yuquan-wind",
    "intent": "react",
    "text": "远岸拍清楚了，水面还在晃。"
  }
]
```

## 黑天鹅区楼主补图

### 楼主文字

远距离：

> 黑天鹅在围栏那边。这个距离就不再往前了。

> 拍到了，先保持距离。

近距离：

> 它好像已经注意到我了。

> 拍完准备往后划。

### 远距离 `swan_far`

```json
[
  {
    "id": "swan-far-01",
    "personaId": "swan-detour",
    "intent": "warn",
    "text": "这个距离差不多，别再往前了。"
  },
  {
    "id": "swan-far-02",
    "personaId": "lake-walker",
    "intent": "share",
    "text": "我每次走到那边都绕开一点，它会盯人。"
  }
]
```

### 近距离 `swan_close`

```json
[
  {
    "id": "swan-close-01",
    "personaId": "swan-detour",
    "intent": "ask",
    "text": "这么近？你开变焦了吧。"
  },
  {
    "id": "swan-close-02",
    "personaId": "dock-passby",
    "intent": "warn",
    "text": "如果没开变焦，现在可以往后划了。"
  },
  {
    "id": "swan-close-03",
    "personaId": "lake-walker",
    "intent": "react",
    "text": "它已经在看你了，真的。"
  }
]
```

黑天鹅距离只影响公开回复标签和后续追逐开场状态。论坛回复不会告诉玩家具体警觉值。

## 黑天鹅追逐期间

追逐开始后：

- 相机锁定。
- CC98 锁定。
- 新回复通知暂停。
- 草稿和已发布楼层继续保存在本地。
- 尝试打开手机时仅显示：`现在不适合看手机。`

追逐失败后从检查点恢复，不新增论坛楼层。

## 章节总结楼层

追逐结束后开放一次楼主总结。

### 选项 A

> 已经回到码头，人和手机都在。其他情况晚点再说。

公开标签：`summary_safe`

候选回复：

```json
[
  {
    "id": "summary-safe-01",
    "personaId": "lake-walker",
    "intent": "react",
    "text": "能回来发这层就行。"
  },
  {
    "id": "summary-safe-02",
    "personaId": "wild-auditor",
    "intent": "ask",
    "text": "人和手机都在。船呢？"
  },
  {
    "id": "summary-safe-03",
    "personaId": "swan-detour",
    "intent": "ask",
    "text": "黑天鹅最后追到哪了？"
  }
]
```

若 `glasses_lost` 已公开，可优先插入：

```json
{
  "id": "summary-glasses-01",
  "personaId": "yuquan-wind",
  "intent": "ask",
  "text": "人和手机都在，那眼镜呢？"
}
```

### 选项 B

> 回来了。中间那段先不写了。

公开标签：`summary_private`

候选回复：

```json
[
  {
    "id": "summary-private-01",
    "personaId": "lake-walker",
    "intent": "react",
    "text": "懂了，过程跳过。"
  },
  {
    "id": "summary-private-02",
    "personaId": "swan-detour",
    "intent": "joke",
    "text": "你不说我就默认黑天鹅赢了。"
  },
  {
    "id": "summary-private-03",
    "personaId": "wild-auditor",
    "intent": "ask",
    "text": "等一个当时在岸边的人补充。"
  }
]
```

总结发布后主题归档，楼主不再增加新照片。

## 奖励

主帖发布：开放钓鱼探索。

完成任意两处补图：下一次钓鱼主线获得一次轻量辅助。辅助只影响一轮，使用后消耗。

三处补图全部发布：获得 `启真湖划船记录` 纪念卡。

奖励状态不写入普通用户回复上下文。

## 深色模式

深色模式可以显示三处补拍区域的反光方向，不显示名称和奖励数量。

相机在深色模式下可以继续取景，但正式归档快门不可用。提示：

> 切回浅色模式后再拍。

切换模式时保持相机方向、取景比例和船只位置。

## 网络错误

发布失败时保存：

```ts
interface RowingForumDraft {
  threadId: string;
  ownerFloorId: string;
  photoId: string;
  photoTags: RowingThreadTag[];
  titleOption?: string;
  statusOption: string;
  createdAtGameTime: number;
  publishNonce: string;
}
```

提示：

> 没发出去。照片和文字已经存到本地。

玩家切换到 `ZJUWLAN` 后主动点击 `继续发布`。`publishNonce` 保证同一草稿只产生一层楼主回复。

## 持久状态

```ts
interface RowingThreadState {
  threadSeed: number;
  mainPostPublished: boolean;
  mainPostTitle?: string;
  mainPostStatus?: string;
  dockReplyPublished: boolean;
  reflectionReplyPublished: boolean;
  swanReplyPublished: boolean;
  publicTags: RowingThreadTag[];
  emittedReplyIds: string[];
  localDraft?: RowingForumDraft;
  fishingAssistUnlocked: boolean;
  fishingAssistConsumed: boolean;
  summaryAvailable: boolean;
  summaryChoice?: "safe" | "private";
  summaryPublished: boolean;
  memoryCardUnlocked: boolean;
  threadArchived: boolean;
}
```

## 必须满足的实现约束

1. 主帖最多发布一次。
2. 三处补图每处最多产生一层楼主回复。
3. 网络重试不得重复发楼层。
4. 普通回复只读取公开标签。
5. 同一存档重载后回复文本与顺序保持一致。
6. 追逐期间手机锁定，失败重试不产生论坛副作用。
7. 两处补图奖励最多发放一次，辅助最多消耗一次。
8. 三处补图纪念卡最多发放一次。
9. 总结发布后主题不可继续追加。
10. 未完成补图不阻塞主线结束。
11. 论坛回复不承担按键、模式切换和隐藏阈值教学。
12. 新增或修改回复时必须按 `docs/human-writing-copy-policy.md` 复审。
