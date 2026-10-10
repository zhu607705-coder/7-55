# Original web theater → current Godot object audit

Scope: the spotlight mini-game, not the full theater exploration room.
Original: `src/scenes/rpg/TheaterImpossibleShow.ts`, `TheaterSpotlightModel.ts`.
Original shows are Graphics-drawn inside Phaser, not a pre-existing 3D model.
The exploration room's artwork remains separately preserved.

| Original visible object | Original source | Current Godot representation | Status |
|---|---|---|---|
| Theater stage floor | `paint` stage rectangles/seams | Batched physical floorboard surfaces; atlas material from existing theater plate | Real mesh reconstruction; optical warp shared |
| Curtain legs / valance | `paint` repeated rectangular folds | Three layers of pleated curtain meshes; scalloped top border | Real mesh reconstruction |
| Stage apron / front edge | `paint` floor lip | Thick visible front face, brass bands and footlights | Real mesh reconstruction |
| Lamp/light creature | `paint` circle, hat, face | Original circle/hat/face remains a planar ink layer; an independent tracking projector was added | Creature itself is not yet a 3D rebuild |
| Projector housing / yoke / fins / lens / doors | No independent object in source mini-game; original room plate depicts hanging lights | Named `IndependentFollowspot` + `TiltPivot`, separate articulated mesh parts, SpotLight3D | New actual modeled fixture, not a claim of source-object parity |
| Two moving chairs | `chair`, source hazard positions | Upholstered chair meshes with legs/seat/back/eyes; positions from the shared revised hazard model | Real mesh reconstruction |
| Chair moon scrim | `paint` decorative moon and chair | Not yet separately reconstructed in the current slice | Open visual parity item |
| Punctuation food | `foodLabels` | Planar pixel-font glyphs: moving paths in acts 1/2; fixed act-3 anchors; pair colors, focus rings, locked states and ray/occlusion feedback from the revised model | Revised functional art; not 3D rebuilt |
| Retreat mouth | `paint`, source mouth position | Original lips/teeth/inner mouth as planar ink | Preserved functional art; not 3D rebuilt |
| Delayed shadow hazard | `paint`, source history at 60 ticks | Planar dark silhouette and eyes; damaging shadow retained in act 2 only | Preserved act-2 hazard art; not 3D rebuilt |
| Third-act cooperative echo | Revised `getTheaterEcho` / native `echo`, exact 60-tick-old position | Planar cyan light-creature/hat, historical trail and target rays; harmless cooperative light | New planar rule feedback; not a 3D actor or a damage hazard |
| Third-act eye hazard | `eye`, source moving-eye path | Original planar eye and ring | Preserved functional art; not 3D rebuilt |
| Audience eyes | `paint` / `eye` | Planar front-row silhouettes | Partial; third-act original upper-row placement needs reconciliation |
| Light trail | source `trail` | Original planar polylines | Preserved rule-linked art; not 3D rebuilt |
| Third-act rain-like streaks | source `paint` | Not reconstructed in current slice | Open visual parity item |
| HUD / intro / result / buttons | original controls/copy | Native labels and buttons outside lens | Deliberately unwarped; source UI flow retained |

This is an actual integrated first slice plus an independent playable review fixture.
`main.gd` still mounts `c3_spotlight.gd`; the presentation inside that game has
been replaced. The separate preview uses the same game class but never writes
story progress. It is not a full per-object parity claim.

## Rule and evidence boundary

The current model uses moving interception in act 1, 20-tick endpoint handoffs in act 2 (`[0,2]`, `[4,3]`, 75-pixel reach, exclusive 110-tick window, ID 1 last), and 16 consecutive ticks of live/60-tick-echo cooperation at fixed act-3 pairs (`[0,2]`, `[4,3]`, `[5,1]`). The act-3 echo is harmless. Chair occlusion uses the light-to-target segment with a 26-pixel threshold. Damage cancels temporary charge before new progress while preserving completed groups and history. See `THEATER_MODEL_PREVIEW.md` for full semantics.

The nine source-generated QA routes establish reachability only. They are not evidence of player difficulty, completion time or per-object visual fidelity. Limited manual mouse input completed one act-3 pair (0/6 to 2/6); later naive paths failed under chairs/eye hazards. This observation is not a completed usability evaluation.
