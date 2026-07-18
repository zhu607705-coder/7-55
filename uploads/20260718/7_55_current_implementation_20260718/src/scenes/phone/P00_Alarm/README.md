# P00 Alarm

- Scene ID: `alarm`
- Entry: app start
- Reads: `currentScene`
- Writes: route to `desktop`
- Events: `enter_scene`, `dialogue_played`
- Assets: `ui_alarm_normal`, alarm sounds
- Tests: closing alarm reaches `desktop`; snooze feedback does not break P0
