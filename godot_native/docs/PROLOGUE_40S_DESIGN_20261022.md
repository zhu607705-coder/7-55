# 2026-10-22 - Forty-second word-flow route

The user defines the interval as **first word flow to catching the narrator**, excluding the earlier receipt/blackout and the later dialogue. The goal is approximately40 active seconds on a smooth route. Reaction-critical word speed stays unchanged.

## Web consultation

The user requested ChatGPT web feedback first. Asked the existing Extra High web model with the complete authored fragments, six-target contract, original movement metrics, mobile controls, clean ASCII presentation, retained retry semantics, and this exact timing boundary. [The review conversation](https://chatgpt.com/c/6ad9da85-c178-83e8-9901-d78b93e2daa7) recommended discovery, coordinate recognition, then sentence reconstruction; continuous decoys between targets; immediate successful handoffs; and a natural duration rather than a40-second completion timer.

Adopted those pacing principles, not its implementation authority. The suggested four-direction target entry was not adopted: actual target trajectories and original reaction windows stay unchanged. Four-sided micro-glyph assembly remains presentation only. No new story wording, item, reward, save field or controller gate was added.

## Playable composition

Each stage retains its short original-clue lead-in. The subsequent0.95-second physical word stream uses target slots `[5]`, `[2,6]`, and `[2,6,13]`; the other slots use that stage's original decoy words. Left/right placement varies within the same source-space bounds. There are27 encounters on the clean route: six original targets and21 decoys, including the opening teaching rebound. No full-screen wait or end-of-stage countdown was introduced.

The first physical rebound demonstrates the solid window without charging an exploratory miss. All later wrong-word and wrong-order contacts still fail locally. Failure retains the authored deck position and earned collection. An already introduced missing target can retry on the next original700ms recovery; an early decoy mistake cannot force a not-yet-introduced answer into the stream. Actual contacts remain mandatory, and waiting alone never grants progress.

Successful stages hand off in280ms, with the next original clue immediately continuing in the same ASCII cloud. The last successful target enters the existing narrator lock immediately; there is no delay to make a timer reach40. The original1.4-second grip remains the final input gate, without exposing its answer in default UI.

| Milestone | Measured active time |
| --- | ---: |
| Word flow starts | 0.00s |
| First stage complete / coordinate stage begins | 9.34s |
| Sentence stage begins | 20.06s |
| Six real targets complete / narrator lock begins | 37.45s |
| Narrator caught | 38.85s |

These are measured with legal scene pointer intents, real swept collision and no misses. The test pauses for two additional seconds and excludes those frozen seconds from the active interval. Human recognition, missed words and cancelled grips can extend play; they cannot remove proof requirements. Reduced motion retains its longer original static-clue reading time.

The regression test is `tests/test_prologue_pacing.gd`: it verifies approximately40 active seconds, a zero-miss legal route, all six physical captures, original target transit times, no idle completion, no future-answer shortcut after an early failure, and a frozen encounter deck during pause. Final export, browser acceptance and evidence are recorded in `PROLOGUE_FORTY_SECOND_FLOW_20261022.json`.
