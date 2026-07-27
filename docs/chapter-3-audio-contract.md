# Chapter 3 Audio Contract

## Ownership

- Gameplay controllers emit domain events.
- `AudioDirector` resolves those events through JSON timelines.
- Scene dialogue owns its Chinese subtitle whenever `subtitleSurface` is `scene`.
- Audio completion never advances gameplay.

## Voice continuity

- Narrator: `English_expressive_narrator`, English source text, base pitch `-4`.
- System: `English_Graceful_Lady`, English source text.
- Player and scene NPC lines remain text-only unless the story contract explicitly assigns a `voiceRole`.
- `src/data/chapter3-story-lines.json` is the Chapter 3 voice catalog.
- `src/data/chapter3-story.audio.generated.json` records generated file hashes and source hashes.

## Scene sound ownership

- Canteen cues use only `music_canteen_*` and `fx_canteen_*`.
- Theater cues use only `music_theater_*` and `fx_theater_*`.
- Qizhen Lake cues use only `music_qizhen_*` and `fx_qizhen_*`.
- A scene may not borrow another scene's effect as a temporary substitute.

## Commands

```bash
npm run audio:chapter3
npm run audio:chapter3:status
npm run audio:chapter3:verify
```

- `audio:chapter3` incrementally generates missing or stale assets through MiniMax CLI.
- `audio:chapter3:status` performs a local, API-free inventory and contract report.
- `audio:chapter3:verify` requires every expected asset, generated-manifest record, file hash, voice profile, and timeline ownership check to pass.
- After a MiniMax quota or network interruption, rerun the incremental command. Valid files with matching manifests remain reusable.

## Completion gate

Chapter 3 audio is complete only when `audio:chapter3:verify` exits with status `0`. A successful build with missing audio does not satisfy this gate; runtime audio remains non-blocking so story progression can still be tested.
