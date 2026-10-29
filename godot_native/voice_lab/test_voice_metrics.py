import tempfile
import unittest
import wave
from pathlib import Path
import numpy as np
from voice_metrics import pitch_summary, compare_pitch


class PitchDiagnostics(unittest.TestCase):
    def analyze(self, samples):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'signal.wav'
            with wave.open(str(path), 'wb') as output:
                output.setnchannels(1)
                output.setsampwidth(2)
                output.setframerate(16000)
                output.writeframes((samples * 32767).astype('<i2').tobytes())
            return pitch_summary(path)

    def test_fundamental_survives_louder_second_harmonic(self):
        t = np.arange(16000) / 16000
        result = self.analyze(0.12 * np.sin(2 * np.pi * 130 * t) + 0.2 * np.sin(2 * np.pi * 260 * t))
        self.assertAlmostEqual(result['medianHz'], 130, delta=1)

    def test_silence_cannot_report_a_voice_pitch(self):
        self.assertIsNone(self.analyze(np.zeros(16000))['medianHz'])

    def test_white_noise_is_not_a_stable_voice(self):
        result = self.analyze(np.random.default_rng(755).normal(0, 0.08, 16000))
        self.assertIsNone(result['medianHz'])

    def test_comparison_is_relative_not_a_voice_identity_verdict(self):
        self.assertEqual(compare_pitch({'medianHz': 240}, {'medianHz': 120}), 12)
        self.assertIsNone(compare_pitch({'medianHz': None}, {'medianHz': 120}))


if __name__ == '__main__':
    unittest.main()
