# 第四章 H3 场景配音修复提示词与生成合同

## 1. 目标与边界

本合同服务于 `43.833s` 的第三章半至第四章 H3 过场。H3 视频继续保持静音，运行时从 `chapter4-prologue.audio.json` 播放配音、音乐和音效。配音采用既有英文声轨与中文字幕规则，角色 voice ID 保持不变。

MiniMax `speech synthesize` 当前没有自由文本形式的表演指导参数。完整场景提示词记录在内容目录中，实际请求通过 voice ID、`emotion`、`speed`、`pitch`、英文台词和标点实现。环境混响、广播噪声、脚步与湿地面声继续由运行时音效负责，TTS 文件保持干声。

## 2. 全局一致性要求

- 模型：`speech-2.8-hd`。
- 输出：MP3、`32000 Hz`、mono、`128000 bps`。
- 归一化：去除首尾无效静音；既有长句保持 `loudnorm=I=-16:TP=-1.5:LRA=7`。短 NPC 台词先使用轻量动态压缩，再进入同一 loudness/true-peak 限制，缩小与主角、旁白的听感响度差。
- 主角：`English_Diligent_Man`，`pitch=0`。
- 旁白：`English_expressive_narrator`，`pitch=-4`。
- 保洁员：`Chinese (Mandarin)_Kind-hearted_Antie`，`pitch=0`。
- 保安：`English_Trustworthy_Man`，`pitch=0`。
- 不更换角色 voice ID，不在 TTS 中生成音乐、空间声、无线电底噪或额外人物。
- 每条生成后必须满足镜头时间预算，超时文件不得替换现有正式资源。

## 3. 六段画面与配音决策

| H3 阶段 | 画面内容 | 配音决策 |
| --- | --- | --- |
| `snap` | 磁性连接件断裂，纸条脱离 | 保留主角短句“又断了。” |
| `lake_exit` | 纸条越过湖边栏杆 | 不新增台词，保留水面、栏杆和风声节拍 |
| `arcade` | 纸条沿夜间拱廊飞行 | 保留旁白，交代纸条从湖到教学楼的结果 |
| `entrance` | 离楼学生开门，纸条进入 | 不新增人物对白，保留门与压差声，避免无口型角色突然说话 |
| `lobby` | 保洁员推车，纸条贴近湿地面掠过 | 重写并重新生成保洁员短句，必须在大厅镜头结束前说完 |
| `closing` | 外景转入熄灯走廊，手电扫过纸条 | 重写并重新生成保安清楼提醒，必须在广播静电和熄灯节拍前说完 |

## 4. 逐句场景提示词

### 4.1 主角 · `snap`

- 时间：`2950ms`。
- 场景提示词：磁性连接件断裂后，主角压低声音短促自语；保留克制和疲惫，不喊叫，不拖长尾音。
- 英文声轨：`It broke again.`
- 中文字幕：`又断了。`
- 参数：`English_Diligent_Man / speed 1.00 / pitch 0`。
- 音频上限：`1800ms`。

### 4.2 旁白 · `arcade`

- 时间：`13667ms`。
- 场景提示词：纸条离湖后进入夜间拱廊，旁白低沉、稳定、客观，只说明移动结果，不朗读任务，不制造惊悚腔。
- 英文声轨：`The lake did not keep it. The night wind carried it into the teaching building that was still lit.`
- 中文字幕：`湖面没有留下它。夜风把它送进了仍然亮着灯的教学楼。`
- 参数：`English_expressive_narrator / speed 0.95 / pitch -4`。
- 音频上限：`6400ms`。

### 4.3 保洁员 · `lobby`

- 时间：`29450ms`。
- 场景提示词：大厅保洁员推车经过湿地面时随口提醒，声音近、友善、自然；先提醒地滑，再用一句短话指出纸条往楼内去了，不停下讲解。
- 英文声轨：`Careful, I just mopped. That paper went inside.`
- 中文字幕：`小心，刚拖过。那张纸往里去了。`
- 参数：`Chinese (Mandarin)_Kind-hearted_Antie / emotion calm / speed 1.08 / pitch 0 / short_dialogue_consistent_v2`。
- 音频上限：`3600ms`；实际生成 `2841ms`。

### 4.4 保安 · `closing`

- 时间：`36000ms`。
- 场景提示词：教学楼外景切入熄灯走廊时，保安从远处进行一次正式清楼提醒；语速清楚、口气平稳、句子短，不追喊，不加入广播噪声。
- 英文声轨：`The North Teaching Building is closing. Please pack up.`
- 中文字幕：`同学，北教要清楼了，请收好东西。`
- 参数：`English_Trustworthy_Man / emotion calm / speed 1.06 / pitch 0 / short_dialogue_consistent_v2`。
- 音频上限：`3800ms`；实际生成 `2413ms`。

## 5. 时间验收

| 角色 | 开始 | 音频结束 | 下一关键节拍 | 余量 |
| --- | ---: | ---: | ---: | ---: |
| 保洁员 | `29450ms` | `32291ms` | 大厅镜头结束 `33417ms` | `1126ms` |
| 保安 | `36000ms` | `38413ms` | 广播静电 `41042ms` | `2629ms` |

两条修复语音均在对应角色画面和下一关键声效之前结束。中文字幕可比音频略长，保洁员显示至 `32850ms`，保安显示至 `39000ms`。
