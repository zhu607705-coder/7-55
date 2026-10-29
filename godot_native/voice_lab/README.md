# 7:55 角色与场景配音试验

Built with Fish Audio.

本目录先完成角色、场景和表演边界，再用指定的 Drama 3 MLX 4-bit 生成候选录音。它是离线制作工具，`.gdignore` 将模型工具和试听素材隔离出游戏导入。模型权重放在用户缓存，不随游戏或 Git 分发。正式 `AudioDirector`、配音清单、故事控制器和存档均不由此工具修改。

2026-10-29 已完成本机首批：10 段、38.219 秒，16 项测试通过。九段自动转写逐词匹配；广播的 `East Canteen` 在原音和新音中均被识别为 `EastCantine`。重复喊词与疑似添词的两次候选已剔除。具体哈希、参数和剩余听审项见 [试音记录](trial_20261029.json)。素材位于本机忽略目录 `output/`，未替换正式音轨；尚未完成表演听审或游戏内验收。

## 声音设定

| 角色 | 音色与基础音高 | 可变化的表演 | 禁区 |
| --- | --- | --- | --- |
| 旁白 | 原低沉男声，原有 -4 音高已在参考片段内 | 日常冷幽默、被拽住时短暂失态、夜间过场回归克制 | 另换音色、重复降调、恐怖气声、句句大笑 |
| 系统／小影 | 原清晰女声，保持自然音区 | 克制不耐烦、观察时收敛、时机提醒短促有力 | 甜美客服腔、卖萌、一直尖叫、用重音提前给答案 |
| 主角 | 原自然男声，近场自语 | 轻微疲惫、短促回应 | 英雄宣言、额外解说、为所有玩家选项加声音 |
| 保洁员 | 原项目录音的自然生活感 | 友善、顺口提醒 | 神秘线索腔、播音腔、夸张口音 |
| 保安 | 原稳重男声，中低音区 | 正常正式提醒，字头清楚 | 威胁、追喊、额外命令 |
| 校园广播 | 原广播女声，窄幅起伏 | 中性、均匀、清晰断句 | 讽刺、笑声、念录音编号 |

这是表演设定，不是在原人设上新增年龄、经历、身份或场景事实。参考声音全部来自仓库已生成的合成配音，保留生成器、源路径、逐字稿和文件哈希；不用实拍照片推断声音，也不模仿照片中的真人。

项目现有语言规则是**英文配音、中文字幕**。`voiceTextEn` 与当前 native `subtitleZh` 分别保留原文，不能用朗读中文的方式偷偷替换英文音轨。声线名称中含 Mandarin 的保洁员参考，实际仍采用原项目英文录音及其英文逐字稿。

## 场景与情绪

`direction.json` 是人工维护的设定；`line_plan.json` 是从原台词生成的逐条清单。场景为：起床、系统阻拦、旁白被拽住、物品对话、食堂观察、骑行追逐、剧场推理与失误、湖边调查与捕捉时机、北教过场、保洁提醒、保安清楼、手机录音、公共广播。

强度采用 0–5 的制作标尺，首批限制在 1–3。每条场景情绪必须在角色允许集合内，不能超出该角色上限。强度和 WPM 区间是目标与听审依据，**不是模型已经实现的精确控制参数**。

Future Learning Center 的二楼大厅、三楼茶水休息区、机电操作台、楼梯／电梯也记录了声场方向。当前源码没有这些区域的已确认 NPC 英文台词；操作台反馈仍是文本。不能从“有交互区”推导出教师讲解，也不能把任务、报错、UI 提示全部改成旁白。后续新增 NPC 对白先绑定稳定角色、已有任务状态和已确认台词，再进入此清单。

## 模型实际支持的控制

指定模型：[mlx-community/fish-audio-drama-3-4bit](https://huggingface.co/mlx-community/fish-audio-drama-3-4bit)，锁定 revision `1ac1b2108b63c2ef5bade463a121569363e293ce`，`mlx-audio==0.6.0`。

本地核对了已安装的 `mlx_audio/tts/models/fish_drama3/drama3.py`：

- `ref_audio` 加逐字对应的 `ref_text` 决定参考声音。每个角色固定同一片段和哈希；广播使用同一原声身份下已有的广播参考。
- `temperature`、`top_p`、`top_k` 是采样参数，不能解释成情绪强度或音高。
- 首轮发现短句重复与疑似添词后，保留失败记录并重试。默认使用模型建议的采样设置，逐条 `sampling` 覆盖记录所选候选的实际参数；这只是录音质量重试，不是情绪控制。
- `[whispers]`、`[sighs]`、`[laughs]` 可作为行内表演提示；首批默认不插标签，以检验原声迁移本身。指令段落绝不送进朗读文本。
- `speed != 1.0` 会报错；非空 `instruct` 会报错。没有实现的 `pitch`/`voice` 参数不能伪装成有效控制。
- 同角色跨句保持固定参考；若表演不合适，重新试录并听审。不要随机改音高、混响或把句子强制压缩进时间槽。
- 源参考文件为 32 kHz；解码到模型的 44.1 kHz 是采样率适配，不能称为恢复了高频细节。

干声原始 WAV 与统一响度后的 WAV 分开保留。规范化只改电平，不裁字、不变速、不变调。目标 -18 LUFS、真峰值不高于 -2 dBTP、44.1 kHz 单声道 PCM16。播放时再由现有 Voice 总线、环境声与 Music ducking 实现远近和声场，不能把大厅混响固化在所有角色录音里。参考了 [audio-design](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/38a4c2500eeb5ff9ac084336b8f66108069d2f8d/skills/disciplines/audio-design/SKILL.md)。

## 运行

需要 Apple Silicon、Python 3.12 和足够空闲内存。模型卡估计约 22 GB 权重与 26 GB 生成峰值；实际资源情况以本机记录为准。

```sh
python3.12 -m venv ~/.cache/755-voice-drama3/venv
~/.cache/755-voice-drama3/venv/bin/python -m pip install -r godot_native/voice_lab/requirements.txt
~/.cache/755-voice-drama3/venv/bin/python godot_native/voice_lab/studio.py plan
~/.cache/755-voice-drama3/venv/bin/python godot_native/voice_lab/studio.py generate
~/.cache/755-voice-drama3/venv/bin/python godot_native/voice_lab/studio.py verify
```

已缓存权重时加 `--offline`。网络代理使用调用者环境，不写系统或 Git 全局代理。重复运行会核对配置和媒体哈希后复用已完成条目。失败只保留 `.checkpoints`，十段齐全且通过结构、解码和文件一致性检查后才发布试听 `manifest.json` 与 `index.html`。

生成达到 token 上限、无有效声音或规范化响度不合格的候选不能发布。场景语速、音高偏差与现有过场截点则单独标为听审／接入问题，不能以技术检查通过代替表演合格。

```sh
~/.cache/755-voice-drama3/venv/bin/python -m unittest discover -s godot_native/voice_lab -p 'test_*.py'
~/.cache/755-voice-drama3/venv/bin/python godot_native/voice_lab/studio.py plan --check
```

## 接入前检查

试听成功不代表正式替换完成。听审要逐项确认：原文无漏读／添词、角色音色跨场景连续、基础音高一致、强度和空间合理、数字与关键名称清晰、无多余笑声喘息。自动检测记录时长、峰值、响度、重复字节和源一致性，不能代替表演听审。

试听记录附带相对参考片段的有声帧音高中位数、10–90% 区间和语速。音高检测范围为 60–400 Hz，超过 3 半音只提示听审；短句、气声、倍频误判和表演变化都可能影响测量，不能据此宣称是同一个声音。没有后期变调。语速区间与情绪强度是制作目标，不作为“模型已精确执行”的结论。

可另外运行本地转写校对。识别器不接收目标台词或关键词提示；启用词级时间戳与静音幻觉过滤，并把原配音也送入同一个识别器。`speech_check.json` 保留识别结果和词差异，仍须听审，尤其是专名和数字。

```sh
~/.cache/755-voice-drama3/venv/bin/python godot_native/voice_lab/check_speech.py \
  --output godot_native/voice_lab/output \
  --asr-model ~/.cache/755-voice-drama3/whisper-tiny
```

过场有两种时长：内容文件里的 `maxDurationMs` 和现有 cue 的 `durationMs`。例如主角 “It broke again.” 的内容预算是 1800 ms，但原播放截点只有 547 ms。新录音即便在内容预算内，也可能被旧 cue 截断。工具同时报告这两项，不裁掉词尾以制造通过。正式替换时必须检查原场景时间线、单一字幕归属、取消／失焦、缺音频降级与无进度写入；不能用音频播完来解锁剧情。

许可原文：[Fish Audio Community License](https://huggingface.co/mlx-community/fish-audio-drama-3-4bit/blob/1ac1b2108b63c2ef5bade463a121569363e293ce/LICENSE)。本轮为本机测试；后续发布保留 Built with Fish Audio 与来源记录，按适用用途核对许可。不提供面向外部用户的自助 TTS 服务，也不随游戏分发模型。
