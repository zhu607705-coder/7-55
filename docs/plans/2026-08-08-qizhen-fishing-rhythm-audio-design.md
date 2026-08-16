# 启真湖钓鱼节奏系统与音乐先行设计

日期：2026-08-08  
状态：单曲方案《水纹 7:55》已确认，等待音乐生成与节拍分析

## 目标

四次抛竿统一进入音乐节奏界面。先生成一段可在不同落点结束的完整音乐，再从实际音频中提取拍点并人工复核，最后建立钥匙、网框、小鲤鱼和纸条四套判定节点。BPM 用于生成与谱面约束，运行时判定统一引用 `AudioContext.currentTime`。

## 音乐设计

新增一段 20 秒、96 BPM、4/4 拍、8 小节纯音乐素材 `music_qizhen_fishing`，曲名《水纹 7:55》。第 4、6、8 小节分别在 10、15、20 秒形成可结束的和声落点，因此钥匙使用前 4 小节，网框和小鲤鱼使用前 6 小节，纸条使用完整 8 小节。

调式为 D Dorian。木质收线轮点击承担四分音符脉冲；低音正弦落在每小节第 1、3 拍；轻柔马林巴与玻璃水滴承担八分音符装饰；短促拨弦承担主旋律；很薄的空气感合成器随张力上升。要求首拍立即进入、固定速度、明确重拍、无演唱、无自由速度、无淡入淡出和无超过 20 秒的混响尾音。生成后统一为 MP3、44.1 kHz、双声道，并做完整解码、响度和哈希验证。

## MiniMax 生成提示词

`Immediate-start modular rhythm-fishing cue for a top-down pixel RPG at a university lake, exactly 20.0 seconds, strict 96 BPM, 4/4, eight bars, D Dorian. A clear quarter-note pulse must begin immediately. Include clean musical landing points at exactly 10.0 seconds, 15.0 seconds, and 20.0 seconds. Use muted marimba water droplets, dry wooden fishing-reel clicks, soft plucked strings, low sine bass pulses, and a restrained airy synth layer. Bars 1 to 4 feel calm and instructional. Bars 5 to 6 add tighter reeling tension. Bars 7 to 8 build toward a magnetic paper catch and end cleanly. No vocals, no rubato, no tempo drift, no pickup, no fade-in, no fade-out, no cinematic drums, no dense lead melody, and no reverb tail beyond 20 seconds.`

旋律短句固定为 `D5 A4 C5 E5 D5 C5 A4`、`E5 G5 E5 D5 B4`、`A4 C5 E5 D5 A4`，以 7、5、5 的音符数量呼应标题。

## 节拍分析与谱面规则

- 每拍持续 `0.625s`。音乐预定开始后，第 `b_n` 个谱面位置的判定时间为 `t_n = t_0 + 0.625 × b_n`。
- `t_0` 必须取自同一个 `AudioContext.currentTime` 预定开始时刻；音乐、视觉环和输入判定共同引用该时间轴，禁止用连续 `setTimeout` 累积节拍。
- 解码音频后检测瞬态、重拍和小节起点，输出实际 `offsetMs`、`bpmEstimate`、`beatsMs`、`downbeatsMs` 和 `sourceSha256`。
- 自动结果必须通过波形、听感和节拍器叠加复核。生成提示中的 BPM 不能单独充当最终判定时间。
- 第一轮只生成候选节拍表，不接入剧情状态。
- 音乐确认后，从真实拍点选择四套节点：钥匙 6 个、网框 8 个、小鲤鱼 12 个、纸条 16 个。
- 初始判定窗：Perfect `±55ms`、Great `±110ms`、Good `±170ms`；最终数值在 Blink、Gecko、WebKit 和移动端实测后确定。
- Miss 只清空连击并扣除本轮容错；失败返回抛竿前状态，不消耗剧情道具。
- 进行中的歌曲位置、连击和临时分数不进入正式存档。存档只记录该次捕获是否完成。

## 画面与音效方向

- 场景镜头靠近水面，鱼漂保持在画面中心，水波承担判定圈显示。
- Perfect、Great、Good、Miss 分别使用青白、黄色、浅蓝和灰色反馈。
- 先生成音乐并确定拍点，再制作抛竿、鱼漂、咬钩、判定、收线和物品出水音效，避免音效遮挡拍点。
- 配音只用于首次教学、连续 Miss 和最终成功；继续使用英文语音与中文字幕。

## 本阶段验收

- 音乐能完整解码，持续 20.000 秒，44.1 kHz 双声道，配置哈希和文件哈希已记录。
- 音乐有可听辨的稳定拍点，第 4、6、8 小节有清晰结束点，节拍器叠加检查无持续漂移。
- 生成一份与音频哈希绑定的候选节拍 JSON。
- 音乐和候选节拍通过人工试听后，才进入钓鱼界面实现。
