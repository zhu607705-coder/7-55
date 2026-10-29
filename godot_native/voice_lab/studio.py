#!/usr/bin/env python3
"""Source-bound, offline Drama 3 auditions. Never writes a runtime manifest."""
from __future__ import annotations

import argparse
import hashlib
import html
import importlib.metadata
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import wave

LAB = Path(__file__).resolve().parent
ROOT = LAB.parents[1]
CATALOG = "godot_native/data/native/audio-director-source.json"
MEMOS = "src/data/chapter3-interlude-voice-memos.audio.content.json"
MEMO_ASSETS = "src/data/chapter3-interlude-voice-memos.audio.generated.json"
PROLOGUE = "src/data/chapter4-prologue-voice.audio.content.json"
SOURCES = [CATALOG, MEMOS, MEMO_ASSETS, PROLOGUE]


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def digest(value):
    if isinstance(value, Path):
        h = hashlib.sha256()
        with value.open("rb") as stream:
            for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b""):
                h.update(chunk)
        return h.hexdigest()
    if not isinstance(value, bytes):
        value = json.dumps(value, ensure_ascii=False, sort_keys=True).encode()
    return hashlib.sha256(value).hexdigest()


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def run(command):
    result = subprocess.run([str(x) for x in command], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr[-3000:] or result.stdout[-3000:])
    return result


def asset_file(asset):
    path = asset["path"]
    if not path.startswith("res://assets/audio/"):
        raise ValueError(f"Not an authored native audio path: {path}")
    absolute = (ROOT / "godot_native" / path.removeprefix("res://")).resolve()
    if not absolute.is_relative_to(ROOT / "godot_native/assets/audio") or not absolute.is_file():
        raise ValueError(f"Missing/unsafe reference: {path}")
    if asset.get("sha256") and digest(absolute) != asset["sha256"]:
        raise ValueError(f"Authored reference checksum changed: {path}")
    return absolute


def source_data():
    return tuple(read_json(ROOT / path) for path in SOURCES)


def source_line(kind, key, data):
    catalog, memos, memo_assets, prologue = data
    if kind == "catalog":
        line = catalog["storyLines"][key]
        if line["kind"] != "dialogue" or not line.get("voiceRole") or not line.get("voiceTextEn"):
            raise ValueError(f"This line must stay silent: {key}")
        cues = [cue for section in ("legacy", "events")
                for event in catalog[section].values() for cue in event.get("cues", [])
                if cue.get("channel") == "voice" and cue.get("subtitleKey") == key]
        assets = {cue["asset"] for cue in cues if cue.get("asset")}
        if line.get("voiceAsset"):
            assets.add(line["voiceAsset"])
        if len(assets) != 1:
            raise ValueError(f"Expected one exact authored voice asset for {key}, got {assets}")
        asset_id = next(iter(assets))
        asset = catalog["assets"][asset_id]
        specific = next((entry for entry in prologue["lines"] if entry["key"] == key), {})
        runtime_windows = [cue["durationMs"] for cue in cues if cue.get("durationMs")]
        role = line["voiceRole"]
        text = line["voiceTextEn"]
        subtitle = line["subtitleZh"]
        pointer = f"/{'storyLines'}/{key}"
        source = CATALOG
        budget = specific.get("maxDurationMs")
    elif kind == "memo":
        line = next(entry for entry in memos["speech"] if entry["id"] == key)
        asset_id = line["asset"]
        asset = {**memo_assets["assets"][asset_id]}
        asset["path"] = "res://assets/audio/" + asset["path"]
        role = "campus_broadcast" if key.endswith("_announcement") else line["voiceRole"]
        text, subtitle = line["voiceTextEn"], line["subtitleZh"]
        budget = line.get("maxDurationMs")
        runtime_windows = []
        source, pointer = MEMOS, f"/speech/{memos['speech'].index(line)}"
    else:
        raise ValueError(f"Unsupported source kind: {kind}")
    path = asset_file(asset)
    return {
        "kind": kind, "key": key, "role": role, "text": text, "subtitleZh": subtitle,
        "source": source, "pointer": pointer, "assetId": asset_id,
        "originalPath": str(path.relative_to(ROOT)), "originalSha256": digest(path),
        "originalGenerator": asset.get("source"), "originalDurationMs": asset.get("durationMs"),
        "sourceMaxDurationMs": budget,
        "runtimeCutoffMs": min(runtime_windows) if runtime_windows else None,
        "sourceLineSha256": digest(line),
    }


def scene_for(line, direction):
    if line["kind"] == "memo":
        return "broadcast" if line["role"] == "campus_broadcast" else "phone_memo"
    for rule in direction["sceneRules"]:
        if line["key"] in rule.get("keys", []) or (rule.get("prefix") and line["key"].startswith(rule["prefix"])):
            return rule["scene"]
    raise ValueError(f"Voiced line needs an explicit scene classification: {line['key']}")


def build_plan(direction=None, data=None):
    direction = direction or read_json(LAB / "direction.json")
    data = data or source_data()
    all_lines, silent = [], []
    for key, line in data[0]["storyLines"].items():
        if line["kind"] == "dialogue" and line.get("voiceRole"):
            all_lines.append(source_line("catalog", key, data))
        else:
            silent.append({"key": key, "kind": line["kind"], "reason": "no_authored_voice_role"})
    all_lines.extend(source_line("memo", line["id"], data) for line in data[1]["speech"])
    for line in all_lines:
        line["scene"] = scene_for(line, direction)
        role, scene = direction["roles"][line["role"]], direction["scenes"][line["scene"]]
        if scene["emotion"] not in role["allowedEmotions"] or not 0 <= scene["intensity"] <= role["emotionCeiling"]:
            raise ValueError(f"Scene delivery exceeds character limits: {line['key']}")
    auditions = []
    ids = set()
    for audition in direction["auditions"]:
        if not re.fullmatch(r"[a-z0-9_]+", audition["id"]) or audition["id"] in ids:
            raise ValueError("Audition IDs must be unique safe filenames")
        ids.add(audition["id"])
        line = source_line(audition["kind"], audition["key"], data)
        line["scene"] = scene_for(line, direction)
        role = direction["roles"][line["role"]]
        reference = source_line(**role["reference"], data=data)
        cue = audition.get("inlineTag", "")
        if cue and cue not in direction["contract"]["allowedInlineTags"]:
            raise ValueError(f"Unsupported inline delivery tag: {cue}")
        if "[" in line["text"] or "<|speaker:" in line["text"]:
            raise ValueError("Authored text cannot inject generation control tags")
        # Direction prose is never injected into spoken text. Preserve exact words/punctuation.
        speech = f"{cue} {line['text']}" if cue else line["text"]
        sampling = {key: direction['model'][key] for key in ('temperature', 'topP', 'topK')}
        overrides = audition.get('sampling', {})
        if set(overrides) - set(sampling):
            raise ValueError('Unknown sampling control; pitch and emotion are not sampler parameters')
        sampling.update(overrides)
        if not 0 < sampling['temperature'] <= 2 or not 0 < sampling['topP'] <= 1:
            raise ValueError('Invalid sampling range')
        if sampling['topK'] is not None and (not isinstance(sampling['topK'], int) or sampling['topK'] < 1):
            raise ValueError('Invalid top-k cap')
        entry = {
            **line, "id": audition["id"], "prompt": speech, "inlineTag": cue,
            "reference": reference,
            "performanceTarget": {"role": role["timbreZh"], "pitch": role["pitchZh"],
                                  **direction["scenes"][line["scene"]]},
            "maxDurationMs": line["sourceMaxDurationMs"] or audition.get("maxDurationMs", 15000),
            "seed": direction["model"]["seed"] + len(auditions),
            "sampling": sampling,
        }
        entry["configurationSha256"] = digest({"entry": entry, "direction": direction})
        auditions.append(entry)
    return {
        "version": 1, "stage": "audition_only", "runtimeManifestWrites": False,
        "model": direction["model"], "sourceHashes": {p: digest(ROOT / p) for p in SOURCES},
        "directionSha256": digest(direction),
        "counts": {"catalog": len(data[0]["storyLines"]), "eligibleCatalog": len(all_lines) - len(data[1]["speech"]),
                   "directMemoSpeech": len(data[1]["speech"]), "silent": len(silent), "auditions": len(auditions)},
        "lines": all_lines, "silent": silent, "auditions": auditions,
        "unvoicedScenes": direction["unvoicedSceneDirections"],
    }


def ffmpeg_bin():
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def verify_model(model_path, expected_revision):
    """Authenticate downloaded bytes against the pinned HF file index."""
    model_path = Path(model_path)
    index = read_json(LAB / "model_files.json")
    if index["revision"] != expected_revision:
        raise ValueError("Model index revision differs from direction.json")
    for entry in index["files"]:
        path = model_path / entry["name"]
        if not path.is_file() or path.stat().st_size != entry["size"]:
            raise ValueError(f"Incomplete model file: {entry['name']}")
        if entry["sha256"]:
            valid = digest(path) == entry["sha256"]
        else:
            content = path.read_bytes()
            valid = hashlib.sha1(f"blob {len(content)}\0".encode() + content).hexdigest() == entry["blobId"]
        if not valid:
            raise ValueError(f"Model checksum mismatch: {entry['name']}")
        print("Verified model file " + entry["name"], flush=True)


def decode_reference(entry, output, ffmpeg):
    output.parent.mkdir(parents=True, exist_ok=True)
    run([ffmpeg, "-v", "error", "-y", "-i", ROOT / entry["originalPath"],
         "-ar", "44100", "-ac", "1", "-c:a", "pcm_s16le", output])
    return output


def wave_metrics(path):
    import numpy as np
    with wave.open(str(path), "rb") as stream:
        sr, ch, width = stream.getframerate(), stream.getnchannels(), stream.getsampwidth()
        if width != 2 or ch != 1:
            raise ValueError("Expected mono PCM16 audition")
        samples = np.frombuffer(stream.readframes(stream.getnframes()), dtype="<i2").astype(np.float64) / 32768
    if len(samples) == 0 or not np.isfinite(samples).all():
        raise ValueError("Empty or non-finite generated audio")
    rms = math.sqrt(float(np.mean(samples * samples)))
    return {
        "durationMs": round(len(samples) / sr * 1000), "sampleRate": sr, "channels": ch,
        "peakDbfs": round(20 * math.log10(max(float(np.max(np.abs(samples))), 1e-12)), 2),
        "rmsDbfs": round(20 * math.log10(max(rms, 1e-12)), 2),
        "clippedSamples": int(np.sum(np.abs(samples) >= 32767 / 32768)),
    }


def loudness(path, ffmpeg):
    log = run([ffmpeg, "-hide_banner", "-i", path, "-af", "loudnorm=I=-18:TP=-2:LRA=7:print_format=json", "-f", "null", "-"]).stderr
    found = re.findall(r'\{\s*"input_i"[\s\S]+?\}', log)
    if not found:
        raise ValueError("No loudness measurement")
    return json.loads(found[-1])


def normalize(raw, output, ffmpeg):
    measured = loudness(raw, ffmpeg)
    for field in ("input_i", "input_tp", "input_lra", "input_thresh", "target_offset"):
        if not math.isfinite(float(measured[field])):
            raise ValueError(f"Invalid audio loudness: {field}={measured[field]}")
    filter_text = ("loudnorm=I=-18:TP=-2:LRA=7:linear=true:"
                   f"measured_I={measured['input_i']}:measured_TP={measured['input_tp']}:"
                   f"measured_LRA={measured['input_lra']}:measured_thresh={measured['input_thresh']}:"
                   f"offset={measured['target_offset']}")
    run([ffmpeg, "-v", "error", "-y", "-i", raw, "-af", filter_text,
         "-ar", "44100", "-ac", "1", "-c:a", "pcm_s16le", output])
    return loudness(output, ffmpeg)


def check_record(entry, record, output):
    if record["configurationSha256"] != entry["configurationSha256"]:
        raise ValueError(f"Stale generation configuration: {entry['id']}")
    for field in ("audio", "rawAudio", "referenceAudio", "originalAudio"):
        path = (output / record[field]["path"]).resolve()
        if not path.is_relative_to(output.resolve()) or digest(path) != record[field]["sha256"]:
            raise ValueError(f"Missing/changed {field}: {entry['id']}")
    measured = wave_metrics(output / record["audio"]["path"])
    if measured != record["metrics"]:
        raise ValueError(f"Audio metadata mismatch: {entry['id']}")


def generate(args):
    import numpy as np
    import mlx.core as mx
    from mlx_audio.tts.utils import load_model
    from scipy.io.wavfile import write as write_wav
    from huggingface_hub import snapshot_download
    from voice_metrics import pitch_summary, compare_pitch

    if importlib.metadata.version("mlx-audio") != "0.6.0":
        raise ValueError("This audition pipeline is pinned to mlx-audio 0.6.0")
    direction, plan = read_json(LAB / "direction.json"), build_plan()
    output = args.output.resolve()
    if output.is_relative_to(ROOT / "godot_native/assets"):
        raise ValueError("Auditions cannot overwrite production assets")
    output.mkdir(parents=True, exist_ok=True)
    for name in ("raw", "audio", "references", "originals", ".checkpoints"):
        (output / name).mkdir(exist_ok=True)
    # Pin exact model revision; Hub recovers interrupted downloads in its cache.
    model_path = snapshot_download(plan["model"]["repo"], revision=plan["model"]["revision"],
                                   local_dir=str(args.model_dir), local_files_only=args.offline, max_workers=4)
    verify_model(model_path, plan["model"]["revision"])
    print("Loading pinned Drama 3 model", flush=True)
    loaded = time.monotonic()
    model = load_model(model_path)
    print(f"Model loaded in {time.monotonic() - loaded:.1f}s", flush=True)
    ffmpeg = ffmpeg_bin()
    records = []
    for entry in plan["auditions"]:
        checkpoint = output / ".checkpoints" / (entry["id"] + ".json")
        if checkpoint.exists() and not args.force:
            record = read_json(checkpoint)
            check_record(entry, record, output)
            records.append(record)
            print("Reusing verified audition " + entry["id"], flush=True)
            continue
        reference = output / "references" / (entry["role"] + ".wav")
        decode_reference(entry["reference"], reference, ffmpeg)
        original = output / "originals" / (entry["id"] + ".wav")
        decode_reference(entry, original, ffmpeg)
        with wave.open(str(reference), "rb") as stream:
            ref_samples = np.frombuffer(stream.readframes(stream.getnframes()), dtype="<i2").astype(np.float32) / 32768
        mx.random.seed(entry["seed"])
        started = time.monotonic()
        chunks, token_count = [], 0
        # No speed, pitch, instruct, language, or invented voice ID kwargs.
        for result in model.generate(text=entry["prompt"], ref_audio=ref_samples,
                                     ref_text=entry["reference"]["text"],
                                     temperature=entry["sampling"]["temperature"],
                                     top_p=entry["sampling"]["topP"], top_k=entry["sampling"]["topK"],
                                     max_tokens=plan["model"]["maxTokens"]):
            chunks.append(np.asarray(result.audio, dtype=np.float32))
            token_count += result.token_count
        if not chunks:
            raise ValueError(f"No audio returned for {entry['id']}")
        samples = np.concatenate(chunks)
        if samples.size == 0 or not np.isfinite(samples).all():
            raise ValueError(f"Invalid raw samples for {entry['id']}")
        raw = output / "raw" / (entry["id"] + ".wav")
        write_wav(raw, model.sample_rate, samples)
        final = output / "audio" / (entry["id"] + ".wav")
        measured_loudness = normalize(raw, final, ffmpeg)
        metrics = wave_metrics(final)
        words = len(re.findall(r"\b[\w']+\b", entry["text"]))
        pace = round(words * 60000 / metrics["durationMs"])
        pitch, reference_pitch = pitch_summary(final), pitch_summary(reference)
        pitch_delta = compare_pitch(pitch, reference_pitch)
        warnings = []
        if metrics["durationMs"] > entry["maxDurationMs"]:
            warnings.append("over_authored_duration_budget" if entry["sourceMaxDurationMs"] else "over_audition_duration_target")
        if entry["runtimeCutoffMs"] and metrics["durationMs"] > entry["runtimeCutoffMs"]:
            warnings.append("existing_runtime_cue_would_cut_off_audio")
        if token_count >= plan["model"]["maxTokens"]:
            warnings.append("generation_token_cap_reached")
        if metrics["rmsDbfs"] < -42 or metrics["clippedSamples"] or metrics["durationMs"] < 150:
            warnings.append("invalid_level_or_duration")
        pace_low, pace_high = entry["performanceTarget"]["paceWpm"]
        if not pace_low <= pace <= pace_high:
            warnings.append("pace_outside_scene_target")
        if pitch_delta is not None and abs(pitch_delta) > 3:
            warnings.append("pitch_differs_from_reference_listen")
        if abs(float(measured_loudness["input_i"]) + 18) > 2 or float(measured_loudness["input_tp"]) > -1.8:
            warnings.append("loudness_outside_target")
        def media(path):
            return {"path": str(path.relative_to(output)), "sha256": digest(path)}
        record = {
            "id": entry["id"], "configurationSha256": entry["configurationSha256"],
            "audio": media(final), "rawAudio": media(raw), "referenceAudio": media(reference),
            "originalAudio": media(original), "metrics": metrics,
            "loudness": measured_loudness, "paceWpm": pace,
            "pitch": pitch, "referencePitch": reference_pitch, "pitchDeltaSemitones": pitch_delta,
            "generationSeconds": round(time.monotonic() - started, 3),
            "peakMetalMemoryGb": round(mx.get_peak_memory() / 1e9, 3),
            "tokenCount": token_count, "warnings": warnings,
            "sampling": entry["sampling"], "seed": entry["seed"],
            "performanceReview": "pending_listening", "productionEligible": False,
        }
        atomic_json(checkpoint, record)
        records.append(record)
        print(json.dumps({"id": entry["id"], "seconds": record["generationSeconds"],
                          "durationMs": metrics["durationMs"], "warnings": warnings}), flush=True)
    # All-or-nothing review publication; checkpoints alone are never a complete batch.
    validate_batch(plan, records, output)
    atomic_json(output / "manifest.json", {
        "version": 1, "stage": "audition_only", "complete": True,
        "builtWith": "Fish Audio", "model": plan["model"], "sourceHashes": plan["sourceHashes"],
        "directionSha256": plan["directionSha256"], "records": records,
        "environment": {name: importlib.metadata.version(name) for name in ("mlx-audio", "mlx", "numpy", "transformers", "huggingface_hub")},
    })
    atomic_json(output / "plan.json", plan)
    render_review(plan, records, output)
    print(f"Complete review: {output / 'index.html'}", flush=True)


def validate_batch(plan, records, output):
    by_id = {entry["id"]: entry for entry in plan["auditions"]}
    if len(records) != len(by_id) or {record["id"] for record in records} != set(by_id):
        raise ValueError("Incomplete or duplicate audition batch")
    hashes = set()
    for record in records:
        if {"generation_token_cap_reached", "invalid_level_or_duration", "loudness_outside_target"}.intersection(record["warnings"]):
            raise ValueError(f"Rejected technical take must be regenerated before publication: {record['id']}")
        check_record(by_id[record["id"]], record, output)
        if record["audio"]["sha256"] in hashes:
            raise ValueError("Duplicate audio bytes across different auditions")
        hashes.add(record["audio"]["sha256"])
        if record["productionEligible"] is not False:
            raise ValueError("A lab audition cannot grant production approval")


def render_review(plan, records, output):
    direction = read_json(LAB / "direction.json")
    by_id = {r["id"]: r for r in records}
    esc = lambda value: html.escape(str(value), quote=True)
    cards = []
    for entry in plan["auditions"]:
        role = direction["roles"][entry["role"]]
        scene = direction["scenes"][entry["scene"]]
        record = by_id[entry["id"]]
        warnings = "；".join({"over_authored_duration_budget": "超过原场景时长预算",
                             "over_audition_duration_target": "超过本轮试听时长目标",
                             "existing_runtime_cue_would_cut_off_audio": "原播放截点会截断，接入前需调整呈现时长",
                             "generation_token_cap_reached": "达到生成上限，可能未读完",
                             "invalid_level_or_duration": "音量或时长异常",
                             "pace_outside_scene_target": "语速超出场景目标，需试听",
                             "pitch_differs_from_reference_listen": "音高中位数与参考相差超过 3 半音，需听审",
                             "loudness_outside_target": "响度偏离制作目标"}.get(w, w) for w in record["warnings"])
        pitch_note = (f"音高中位数相对参考 {record['pitchDeltaSemitones']:+.2f} 半音（仅测量）"
                      if record.get('pitchDeltaSemitones') is not None else "有效有声帧不足，音高待试听")
        cards.append(f'''<article data-role="{esc(entry['role'])}">
<p class="eyebrow">{esc(entry['id'])} · {esc(scene['labelZh'])}</p><h2>{esc(role['labelZh'])}</h2>
<p class="line">{esc(entry['subtitleZh'])}</p><p lang="en">{esc(entry['text'])}</p>
<p class="direction">{esc(scene['directionZh'])}</p>
<div class="ab"><label>原配音<audio controls preload="none" src="{esc(record['originalAudio']['path'])}"></audio></label>
<label>Drama 3 试音<audio controls preload="none" src="{esc(record['audio']['path'])}"></audio></label></div>
<p class="meta">{record['metrics']['durationMs']/1000:.2f} 秒 · {record['paceWpm']} 词/分钟 · 情绪强度 {scene['intensity']}/5（目标）<br>{esc(pitch_note)} · 无后期变调</p>
<p class="warning">{esc(warnings or '待听审：逐字完整性、音色连续性、情绪与场景适配')}</p>
<details><summary>人设与声音约束</summary><p>{esc(role['timbreZh'])}</p><p>{esc(role['pitchZh'])}</p>
<p>避免：{esc('、'.join(role['forbiddenZh']))}</p><code>{esc(entry['source'])}{esc(entry['pointer'])}</code></details></article>''')
    options = ''.join(f'<option value="{esc(k)}">{esc(v["labelZh"])}</option>' for k,v in direction['roles'].items())
    page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>7:55 · 角色试音室</title><style>
:root{color-scheme:light;font:16px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#eeeae3;color:#25302e}
body{margin:0}main{max-width:1050px;margin:auto;padding:44px 24px 80px}header{border-bottom:2px solid #293c38;padding-bottom:25px;margin-bottom:26px}
.eyebrow{font-size:12px;letter-spacing:.07em;color:#65736e}h1{font-size:clamp(30px,6vw,52px);font-weight:600;line-height:1.25;margin:8px 0 18px}
header p{max-width:780px}select{font:inherit;padding:8px 14px;background:#fff;border:1px solid #aab6ae;border-radius:6px;max-width:100%}
article{background:#faf9f6;border:1px solid #d8ddd6;border-radius:8px;padding:24px;margin-top:22px}h2{font-size:23px;margin:4px 0 16px}
.line{font-size:20px;font-weight:550;margin-bottom:5px}.direction{border-left:3px solid #799889;padding-left:12px;color:#476053}
.ab{display:grid;grid-template-columns:1fr 1fr;gap:24px;margin-top:24px}audio{width:100%;display:block;margin:8px 0}label{font-size:13px;font-weight:600}
.meta{font-size:13px;color:#65736e}.warning{font-size:13px;color:#7a5b2f}summary{cursor:pointer}code{overflow-wrap:anywhere;font-size:11px}
footer{margin-top:40px;color:#65736e;font-size:12px}a{color:#315d4c}@media(max-width:650px){main{padding:24px 15px}.ab{grid-template-columns:1fr;gap:10px}article{padding:18px}}
</style><main><header><p class="eyebrow">7:55 / VOICE DIRECTION / 01</p><h1>先听见角色，再听见情绪。</h1>
<p>十段现有台词，六类表演设定。英文配音与中文字幕沿用项目规则；每个角色固定参考声音，场景决定重音、停顿和情绪上限。</p>
<p>本页为候选试听，尚未替换正式游戏音轨。原配音与新试音可逐条对照；按播放即可试听，切换时自动停止上一段。</p>
<label for="role">选择角色 </label><select id="role"><option value="all">全部角色</option>''' + options + '</select></header>' + '\n'.join(cards) + '''
<footer>Built with Fish Audio · mlx-community/fish-audio-drama-3-4bit · 本地离线生成<br>
<a href="plan.json">台词与场景清单</a> · <a href="manifest.json">生成与检测记录</a> ·
<a href="speech_check.json">逐句转写校对</a> ·
<a href="https://huggingface.co/mlx-community/fish-audio-drama-3-4bit">模型来源与许可</a></footer></main>
<script>const players=[...document.querySelectorAll('audio')];
players.forEach(p=>p.addEventListener('play',()=>players.forEach(q=>{if(q!==p)q.pause()})));
document.addEventListener('visibilitychange',()=>{if(document.hidden)players.forEach(p=>p.pause())});
document.querySelector('#role').addEventListener('change',e=>{players.forEach(p=>p.pause());document.querySelectorAll('article').forEach(a=>a.hidden=e.target.value!=='all'&&a.dataset.role!==e.target.value)});
</script></html>'''
    (output / 'index.html').write_text(page, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "generate", "verify"))
    parser.add_argument("--output", type=Path, default=LAB / "output")
    parser.add_argument("--model-dir", type=Path, default=Path.home() / ".cache/755-voice-drama3/model")
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.command == "plan":
        plan = build_plan()
        if args.check:
            if read_json(LAB / "line_plan.json") != plan:
                raise ValueError("Source or direction changed: regenerate line_plan.json")
        else:
            atomic_json(LAB / "line_plan.json", plan)
        print(json.dumps(plan["counts"]))
    elif args.command == "generate":
        generate(args)
    else:
        plan = build_plan()
        manifest = read_json(args.output / "manifest.json")
        if not manifest["complete"] or manifest["sourceHashes"] != plan["sourceHashes"] or manifest["directionSha256"] != plan["directionSha256"]:
            raise ValueError("Batch/source manifest is incomplete or stale")
        validate_batch(plan, manifest["records"], args.output)
        print(json.dumps({"verifiedAuditions": len(manifest["records"]), "runtimeModified": False}))


if __name__ == "__main__":
    main()
