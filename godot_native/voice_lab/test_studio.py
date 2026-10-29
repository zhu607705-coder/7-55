"""Protect source/role/timing boundaries; no inference needed."""
import copy
import tempfile
import unittest
from pathlib import Path
import studio


class VoiceContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.direction = studio.read_json(studio.LAB / "direction.json")
        cls.data = studio.source_data()

    def test_every_eligible_line_has_scene_and_exact_source(self):
        plan = studio.build_plan(self.direction, self.data)
        self.assertEqual(plan["counts"], {"catalog": 152, "eligibleCatalog": 57,
                                        "directMemoSpeech": 4, "silent": 95, "auditions": 10})
        for take in plan["auditions"]:
            self.assertEqual(take["prompt"], take["text"])
            self.assertEqual(take["reference"]["role"], take["role"])
            self.assertTrue(take["originalSha256"])
            self.assertEqual(studio.source_line(take["kind"], take["key"], self.data)["text"], take["text"])

    def test_silent_lines_cannot_become_speech(self):
        for key in ("sys_balance", "tiyi_47", "gear_pickup"):
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "must stay silent"):
                studio.source_line("catalog", key, self.data)

    def test_new_voiced_lines_need_scene_direction(self):
        data = copy.deepcopy(self.data)
        data[0]["storyLines"]["unmapped_new_line"] = {**data[0]["storyLines"]["wake_narration"], "voiceAsset": "vo_legacy_wake_narration"}
        with self.assertRaisesRegex(ValueError, "scene classification"):
            studio.build_plan(self.direction, data)

    def test_character_emotional_limits(self):
        d = copy.deepcopy(self.direction)
        d["scenes"]["broadcast"]["intensity"] = 4
        with self.assertRaisesRegex(ValueError, "exceeds character limits"):
            studio.build_plan(d, self.data)

    def test_reject_invented_delivery_tags(self):
        d = copy.deepcopy(self.direction)
        d["auditions"][0]["inlineTag"] = "[pitch=-4]"
        with self.assertRaisesRegex(ValueError, "Unsupported inline"):
            studio.build_plan(d, self.data)

    def test_sampler_cannot_pretend_to_control_pitch(self):
        d = copy.deepcopy(self.direction)
        d['auditions'][0]['sampling'] = {'pitch': -4}
        with self.assertRaisesRegex(ValueError, 'Unknown sampling control'):
            studio.build_plan(d, self.data)

    def test_reject_duplicate_ids(self):
        d = copy.deepcopy(self.direction)
        d["auditions"][1]["id"] = d["auditions"][0]["id"]
        with self.assertRaisesRegex(ValueError, "unique safe"):
            studio.build_plan(d, self.data)

    def test_existing_cutoff_separate_from_audition_budget(self):
        plan = studio.build_plan(self.direction, self.data)
        take = next(t for t in plan["auditions"] if t["key"] == "ch4_prologue_player_01")
        self.assertEqual(take["maxDurationMs"], 1800)
        self.assertEqual(take["runtimeCutoffMs"], 547)

    def test_partial_batch_cannot_publish(self):
        plan = studio.build_plan(self.direction, self.data)
        with tempfile.TemporaryDirectory() as folder, self.assertRaisesRegex(ValueError, "Incomplete"):
            studio.validate_batch(plan, [], Path(folder))

    def test_runaway_generation_cannot_publish(self):
        plan = studio.build_plan(self.direction, self.data)
        records = [{'id': entry['id'], 'warnings': ['generation_token_cap_reached']}
                   for entry in plan['auditions']]
        with tempfile.TemporaryDirectory() as folder, self.assertRaisesRegex(ValueError, 'Rejected technical take'):
            studio.validate_batch(plan, records, Path(folder))

    def test_changed_reference_rejected(self):
        original = {**self.data[0]["assets"]["vo_ch4_prologue_cleaner_01"], "sha256": "0" * 64}
        with self.assertRaisesRegex(ValueError, "checksum changed"):
            studio.asset_file(original)

    def test_scene_control_cannot_be_spoken(self):
        data = copy.deepcopy(self.data)
        data[0]["storyLines"]["wake_narration"]["voiceTextEn"] = "<|speaker:1|> hello"
        with self.assertRaisesRegex(ValueError, "inject generation"):
            studio.build_plan(self.direction, data)


if __name__ == "__main__":
    unittest.main()
