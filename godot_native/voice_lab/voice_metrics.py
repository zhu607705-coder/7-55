"""Lightweight voiced-frame pitch diagnostics; never a speaker identity score."""
import math
import wave


def pitch_summary(path):
    import numpy as np
    from scipy.signal import resample_poly

    with wave.open(str(path), 'rb') as stream:
        if stream.getnchannels() != 1 or stream.getsampwidth() != 2:
            raise ValueError('Pitch analysis expects mono PCM16')
        rate = stream.getframerate()
        audio = np.frombuffer(stream.readframes(stream.getnframes()), dtype='<i2').astype(np.float64) / 32768
    divisor = math.gcd(rate, 16000)
    audio = resample_poly(audio, 16000 // divisor, rate // divisor)
    values = []
    # YIN-style normalized difference. Reject quiet/aperiodic frames, and use
    # the first strong local minimum to reduce octave errors from harmonics.
    frame_size, hop, low, high = 1024, 160, 40, 266
    for start in range(0, len(audio) - frame_size + 1, hop):
        frame = audio[start:start + frame_size]
        frame = frame - frame.mean()
        if np.sqrt(np.mean(frame * frame)) < 0.012:
            continue
        cumulative_power = np.concatenate(([0.0], np.cumsum(frame * frame)))
        spectrum = np.fft.rfft(frame, n=2048)
        correlation = np.fft.irfft(spectrum * spectrum.conjugate(), n=2048)[:high + 1]
        lag = np.arange(high + 1)
        difference = (cumulative_power[frame_size - lag]
                      + cumulative_power[frame_size] - cumulative_power[lag] - 2 * correlation)
        difference = np.maximum(difference, 0)
        normalized = np.ones(high + 1)
        normalized[1:] = difference[1:] * lag[1:] / np.maximum(np.cumsum(difference[1:]), 1e-12)
        candidates = np.flatnonzero(normalized[low:high] < 0.15)
        if not len(candidates):
            continue
        chosen = int(candidates[0]) + low
        while chosen + 1 < high and normalized[chosen + 1] < normalized[chosen]:
            chosen += 1
        left, center, right = normalized[chosen - 1:chosen + 2]
        denominator = left - 2 * center + right
        correction = np.clip((left - right) / (2 * denominator), -1, 1) if denominator else 0
        values.append(float(16000 / (chosen + correction)))
    return {
        'method': 'voiced-frame normalized difference, 60–400 Hz, diagnostic only',
        'reliableFrames': len(values),
        'medianHz': round(float(np.median(values)), 1) if len(values) >= 8 else None,
        'p10Hz': round(float(np.percentile(values, 10)), 1) if len(values) >= 8 else None,
        'p90Hz': round(float(np.percentile(values, 90)), 1) if len(values) >= 8 else None,
    }


def compare_pitch(candidate, reference):
    if not candidate['medianHz'] or not reference['medianHz']:
        return None
    return round(12 * math.log2(candidate['medianHz'] / reference['medianHz']), 2)
