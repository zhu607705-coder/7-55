# 7:55 MiniMax 候选素材库（未接入）

本目录是 2026-07-17 生成的候选素材，仅供后续筛选、裁切、重绘和接入评估。

## 隔离规则

- 本目录不属于 `src/assets`，任何 React、Phaser、音频清单或 Vite 入口都没有引用这里的文件。
- 图片、配音、配乐、音效、帖子、对白、任务文案、物品说明和小图标均保留为候选版本。
- 生成失败或被 CLI 拒绝的条目会写入 `reports/generation-failures.log`，不会用占位文件冒充成品。
- 文本候选遵循现有设定：中文界面与字幕，剧情语音源文本使用英文；男旁白和女系统分开保存。

## 目录

- `images/rpg/`：寝室、图书馆、校园地图、地标和俯视场景。
- `images/phone/`：手机主页、浙大钉、CC98、图书馆、天气和任务抽屉。
- `images/props/`：纸质证据、校园卡、手柄、票据、旧规则和线索物。
- `images/characters/`：学生、旁白球和系统头像候选。
- `images/ui/`：应用图标、像素组件和界面纹理。
- `images/posts/`：论坛附件、调查帖配图和小型宣传卡。
- `images/styles/<style>/`：三种主视觉风格的可选版本。
- `audio/music/`：剧情场景配乐候选。
- `audio/voice/`：男旁白与女系统候选配音。
- `audio/sfx/`：短音效与界面反馈候选。
- `audio/styles/<kind>/<style>/`：配乐、语音和音效的风格版本。
- `text/`：MiniMax 生成的对白、帖子、任务和微文案。
- `text/styles/<style>/`：文案三种呈现规则的独立版本。
- `reports/`：生成清单、SHA-256、媒体信息和失败记录。

## 三种风格覆盖

`style-matrix.json` 是唯一筛选入口；`reports/style-coverage.json` 是本轮覆盖核对。每个素材概念都列出三种主风格，未选中的版本仍留在本目录，不参与运行时。

| 类别 | 风格 1 | 风格 2 | 风格 3 | 概念数 | 主版本数 |
|---|---|---|---|---:|---:|
| 图片 | `classic_pixel` 经典像素校园 | `paper_archive` 档案纸张 | `rainy_scanline` 雨夜扫描线 | 26 | 78 |
| 配乐 | `classic_pixel` 像素脉冲 | `paper_ambient` 纸张环境 | `rainy_glitch` 雨夜故障 | 8 | 24 |
| 语音 | `baseline` 基准演绎 | `low_deadpan` 低沉克制 | `clipped_comic` 短促冷幽默 | 12 | 36 |
| 音效 | `clean_ui` 清晰界面 | `paper_mechanical` 纸张机械 | `radio_glitch` 无线电故障 | 6 | 18 |
| 文案 | `plain_case` 平实调查 | `dry_campus` 校园冷幽默 | `procedural_minimal` 系统短句 | 36 | 108 |

图片的 `classic_pixel` 使用原候选作为基准；部分概念还保留旧 `_candidate_b`，该版本在矩阵中标为 `legacyVariant`，不计入三种主风格。地图、地标和手机界面各自维持主题约束，风格差异体现在像素基准、档案印刷和雨夜扫描线三套视觉语言。

文案三种版本事实字段保持一致，差异通过语气、节奏、排版和展示组件规则表达；这样可以在不改变谜题答案的情况下筛选呈现方式。

## 生成状态

生成完成后，`reports/manifest.json` 会记录每个候选的 prompt、模型、输出路径、生成时间、文件大小和哈希。该清单不参与运行时加载。

## 本轮结果

- 图片：88 张文件；26 个概念各有三种主风格，共 78 个主版本，另保留 10 个旧 `_candidate_b`。
- 音频：24 条配乐、36 条语音、18 条音效，共 78 个文件。配音保留 `English_expressive_narrator` 与 `English_Graceful_Lady` 的角色分工；21 个语音变体和 7 个音效变体由 MiniMax 生成，3 个语音变体和 6 个音效变体在用量/频控后以同源音频做可追溯 derived 处理，详情见 `reports/style-audio-derived-manifest.json`。
- 文本：36 份可解析源文件各生成三种呈现变体，共 108 个 JSON；21 份超时或截断片段仍在 `text/partials/`，不进入主风格矩阵。
- 覆盖核对：`reports/style-coverage.json` 显示 264 个主版本、缺失数为 0；所有文件仍处于候选目录，未接入运行时。
- 隔离核对：`src/`、`src/data/`、`src/assets/`、`package.json` 和运行时配置没有新增候选素材引用。
