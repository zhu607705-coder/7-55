# Canteen defense recovery and mobile presentation

Leaving the paper-defense activity and reopening an ordinary save could strand the player in an empty canteen. On a narrow screen, the activity also scaled its entire desktop interface down to a small strip. Paused Retry restarted the game clock while its existing music player stayed paused.

The activity now has readable portrait controls, a whole-room overview and a larger action view. Both views render one simulation. Landscape uses a single full-room view with separate controls; desktop retains its source geometry. Mouse/touch ownership, released or cancelled gestures, focus loss, rotation, Pause, Retry and Exit are tested. Underlying phone/world hints are hidden while defense owns the screen.

Saved active canteen/exit_blocking state enters through the existing controller command on ordinary scene entry or explicit Return. There is no refresh polling loop: deliberate Exit remains exited. Admission retains world-return intent, including desktop entry followed by portrait rotation, so victory continues visibly in the world. The mounted journal similarly retains the destination promised by its Return button across rotation. The original pickup task title and both observation/operation hints are restored without revealing a window answer.

Pause/Resume and paused Retry retain the existing audio player and playback position. The two authored pickup subtitles keep their source display intervals through pause and resize. The model, collision geometry, RNG, 60-second requirement, source cue schedule and controller proof validator are unchanged.

## Verification boundary

The prior frozen revision passed one clean 183-stage aggregate and the export pipeline. Actual play then exposed the desktop-admission victory return issue. The final correction adds one runtime assignment at guarded admission. Against that final code, the complete 305-script graph and affected checks passed: world-return11, mobile198, ordinary-resume34, owners22, defense-smoke5, earned-pickup1,214 and gameplay-audio43. This is not a claim that a new 184-stage aggregate was run locally.

Fresh final Linux and Windows exports passed. The final PCK passed the 795-check campaign and native-only startup/reload25/21, without runtime overrides. Windows remains build-only. Runtime SHA-256: `055003b55f997927115f6751219643c4e513bfb0dc68e11684df90cf90fe9ee8`. Exact hashes and revision boundaries are in `CANTEEN_DEFENSE_RECOVERY_VALIDATION.json`.

Actual continuous cloud play completed the original 60-second defense with late active interceptions, then saved chase_ready on campus. A separate unchanged earned-save copy was replayed in the final standalone Linux release: it also won, displayed “守住了”, automatically reached the campus bicycle in the world, and saved normally. A second earned copy verified desktop Tasks → portrait rotation → Return reaches the promised world without changing items, canteen facts or player position. Both releases closed without script or ObjectDB errors; the cloud driver's unsupported V-Sync warning remains.

An independent short actual-input PCM review confirms paused Retry resumes the same music owner, including source waveform after Start and silence while paused. This does not claim human speaker listening. An earlier long recording was terminated during JSON save after writing its WAV; its empty JSON is retained and excluded from aligned acceptance.

## Remaining scope

Individual short victory lines were not captured in the sampled final GUI frames; their visible world ownership and source order are covered by the automated Main completion test. Physical-phone testing and full manual campaign acceptance remain open. The long pickup hint is legible but can leave final punctuation on a short wrapped line at430px. Three inherited silent prelude files, the source-only Retry-before-first-Start music edge, and isolated art/model prototypes remain outside this repair. Failed manual interceptions are not evidence of a difficulty defect, and no difficulty adjustment was made.
