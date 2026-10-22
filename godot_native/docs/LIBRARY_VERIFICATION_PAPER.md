# Library verification form

Small visual follow-up on PR109 (`0f3fedcae9c4f3ab85380b4e33e291f825ec58e5`). Only the existing identity-stamp view and a focused UI test change; its controller and result payload remain unchanged.

The original React `src/styles/shell.css` item-document uses `#eee7d5` paper, `#29251e` ink and `#8b3f35` document accent. The scene's physical report is `#f2ead5`. The old native scanner's full-height blue block did not use these materials. This view restores that established paper vocabulary with subtle stationary fibres, aligned document rows and one consistent stamp action. It does not add a parchment/scroll bitmap or change global UI.

The bag drawing reuses the exact authored Library backpack geometry from `library-world-source.json`. The stamp is the existing `library_front_desk_stamp_v01.png` at uniform scale. Name, student number and personality remain three explicit “未通过” results with red crosses; the object remains “书包”. The ready badge says “待盖章”, not approved or already stamped. The original “盖章：非本人” action still waits at least720ms and emits once. No inventory, proof, save or dialogue authority moves into this view.

Tests: `test_library_stamp_paper.gd`83 checks; `test_early_games.gd`15; `test_library_stamp_facing.gd`15, all zero failures. Paper tests inherit the real Main theme and cover all six button states, text extents and actual Main layouts at390×844 and1152×760. Actual review uses the same real-Main scene from PR109 and physical report drag/button. New captures must include the paper panel in the pre-roll so the page7 movie and right-hand still match.
