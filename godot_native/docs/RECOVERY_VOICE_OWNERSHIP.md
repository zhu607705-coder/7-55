# Recovery035 voice playback ownership

Switching recordings or replaying a finished clip could show “录音播放回执已失效。” even though the new recording played correctly. The controller had already issued a new session, while the media host reported retirement of the old session back to that controller. The controller correctly rejected the obsolete capability; the player saw an internal lifecycle rejection as a false error.

The host now retires replaced audio without publishing an obsolete receipt. The controller still samples the previous session before issuing its replacement. Explicit Stop also retires the host owner immediately, so leaving the page cannot emit a second terminal receipt on the next frame. Pause, Resume, natural completion, and valid page-exit notifications retain their existing behavior. Forged and stale externally submitted capabilities remain rejected.

The production change is confined to `scripts/media/c3_media_host.gd`. Audio files, gain, duration, excerpt boundaries, listening thresholds, puzzle answers and story state are unchanged.

## Validation

- New ownership regression: 20 checks pass. Baseline reproduced two switch/replay failures; the first correction separately reproduced a duplicate terminal receipt before the final fix.
- Existing actual-source playback progress: 7 checks pass.
- Native Control evidence-flow fixture: 215 checks pass.
- Complete script graph: 339 scripts parse with no failures.
- Actual cloud desktop pointer replay at 430×860 on an unchanged earned-save copy covers active replacement, finished replay, Pause/Resume, Back/reentry and excerpt replacement. The passive action trace contains no expired message and one terminal receipt on Back. The main campaign save is unchanged by this retest.

These are scoped lifecycle checks, not subjective audio or whole-game acceptance. Earlier ordinary playback captured all seven original recordings in the engine's mixed PCM. Their MP3 bytes match the originals and the PCM matches the decoded source at approximately unity gain without clipping. That capture used the Dummy backend and low-power mode with background music paused; speaker output, intelligibility and normal-mode masking remain unverified. No recording order has been submitted in the earned campaign.

The final Linux export passes the automated Chapter1–4 campaign, standalone initial/reload checks, and the packaged20-check ownership fixture. An actual430px standalone run also covers active replacement, finished replay, Pause/Continue, Back, and normal Save. No new Windows execution, physical-touch, full aggregate, or listening claim is implied.
