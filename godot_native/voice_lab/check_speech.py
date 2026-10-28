#!/usr/bin/env python3
"""Unprompted local transcription as a second check, never performance approval."""
import argparse
from pathlib import Path
import re
import wave
import numpy as np
from scipy.signal import resample_poly
from mlx_audio.stt import load
from studio import atomic_json, build_plan, read_json, validate_batch, digest


def words(text):
    return re.findall(r"[a-z0-9]+(?:'[a-z]+)?", text.lower().replace('’', "'"))


def distance(expected, actual):
    row = list(range(len(actual) + 1))
    for i, a in enumerate(expected, 1):
        current = [i]
        for j, b in enumerate(actual, 1):
            current.append(min(current[-1] + 1, row[j] + 1, row[j-1] + (a != b)))
        row = current
    return row[-1]


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--asr-model', type=Path, required=True)
    args = p.parse_args()
    plan = build_plan()
    manifest = read_json(args.output / 'manifest.json')
    validate_batch(plan, manifest['records'], args.output)
    model = load(str(args.asr_model))
    rows = []
    for entry, record in zip(plan['auditions'], manifest['records']):
        if entry['id'] != record['id']:
            raise ValueError('Unexpected batch order')
        row = {'id': entry['id'], 'expected': entry['text'], 'performanceApproval': False}
        for key in ('originalAudio', 'audio'):
            with wave.open(str(args.output / record[key]['path']), 'rb') as f:
                samples = np.frombuffer(f.readframes(f.getnframes()), dtype='<i2').astype(np.float32) / 32768
                rate = f.getframerate()
            samples = resample_poly(samples, 160, 441) if rate == 44100 else samples
            if rate not in (16000, 44100):
                raise ValueError('Unexpected audition sample rate')
            # Never prime ASR with the target script or its keywords.
            result = model.generate(samples, language='en', temperature=0.0,
                                    condition_on_previous_text=False,
                                    return_timestamps=True, word_timestamps=True,
                                    hallucination_silence_threshold=0.5,
                                    clip_timestamps=[0, len(samples) / 16000], verbose=None)
            recognized = result.text.strip()
            errors = distance(words(entry['text']), words(recognized))
            row[key] = {'transcript': recognized, 'wordEditDistance': errors,
                        'wordErrorRate': round(errors / max(1, len(words(entry['text']))), 3),
                        'segments': [{k: s[k] for k in ('start', 'end', 'text', 'avg_logprob')}
                                     for s in result.segments if s['text'].strip()],
                        'sha256': record[key]['sha256']}
        rows.append(row)
        print(row, flush=True)
    atomic_json(args.output / 'speech_check.json', {
        'asrModel': 'mlx-community/whisper-tiny-asr-fp16',
        'revision': '77fa3f52b482ec80d086df55f893065a9baab172',
        'modelSha256': digest(args.asr_model / 'model.safetensors'),
        'method': 'Unprompted English ASR on original and candidate, word timestamps and 0.5s silence hallucination filtering; no target text supplied to recognizer.',
        'limitation': 'Small ASR can make mistakes; word matches do not approve tone, identity, or emotional fit.',
        'rows': rows,
    })


if __name__ == '__main__':
    main()
