# 7:55 UI reference comparison — 2026-10-21

Evidence: all 10 games below were visually inspected in browser screenshots. These are visual-reference observations, not tests of each game's input behavior or Chinese localization. Preserve 7:55's existing Space / P / Esc controls. Touch and Chinese recommendations below are adaptations to validate, not claims about reference-game support.

Game UI Database: https://gameuidatabase.com/ was opened in actual cloud Chrome. The rendered page showed “Your request was blocked.” Web fetch independently returned robots denial. No local-user computer operation or denial bypass was attempted.

## Broad comparison

| Game / verified image | Observed visual pattern | Useful for 7:55 | Do not transfer |
|---|---|---|---|
| [A Short Hike](https://interfaceingame.com/wp-content/uploads/a-short-hike/a-short-hike-interaction.png) | One button glyph in a pointer-shaped bubble above a nearby character; world remains dominant | Spatially anchored Space action prompt; minimal HUD | Giant English pixel letters; unrelated feather meters |
| [Stardew Valley](https://interfaceingame.com/wp-content/uploads/stardew-valley/stardew-valley-dialogue.png) | Bottom dialogue with framed portrait/name; scene still visible | Dialogue hierarchy and speaker identity; [illustrated map](https://interfaceingame.com/wp-content/uploads/stardew-valley/stardew-valley-pelican-town.png) | Heavy orange wooden borders, green completion labels |
| [Moonlighter](https://interfaceingame.com/wp-content/uploads/moonlighter/moonlighter-notebook.png) | Open book with spine, layered pages, bookmark, protruding category tabs; left item list/right selected-item detail; controller glyph footer | Primary clue-book reference; unmistakable physical form instead of flat cream rectangle | Shop price/reaction complexity, mint-green semantic system, tiny body text |
| [The Final Station](https://interfaceingame.com/wp-content/uploads/the-final-station/the-final-station-note.png) | Irregular-edged paper with printed title, sparse text, handwritten code and cyan stamp over scene | Physical evidence inspection: school notice, timetable, access note | Its dark survival palette; unscalable tiny baked-in text |
| [Minit](https://interfaceingame.com/wp-content/uploads/minit/minit-items-500x281.png) | Small item icon row; one selected name and brief explanation on black | Ruthless selection hierarchy for few meaningful objects | Black void replacing campus; monochrome aesthetic; small items |
| [Fez](https://interfaceingame.com/wp-content/uploads/fez/fez-world-map-500x281.png) | Connected spatial room thumbnails; selected room enlarged; separate legend and controls | Show connections/locked routes as spatial relationships | 3D node complexity for a simple campus map |
| [Into the Breach](https://interfaceingame.com/wp-content/uploads/into-the-breach/into-the-breach-pilot-500x281.png) | Separated portrait, equipment, storage and attributes; compact aligned sections | Consistent alignment and distinct item/function regions | Combat dashboard density, sci-fi chrome, tiny stats |
| [Graveyard Keeper](https://interfaceingame.com/wp-content/uploads/graveyard-keeper/graveyard-keeper-known-npcs-500x281.jpg) | Known-NPC cards have portraits/names and short progress descriptions in a panel over world | Tie clues/requests to people instead of anonymous text tasks | Two-column microtext and crowded quest details |
| [Forager](https://interfaceingame.com/wp-content/uploads/forager/forager-items-500x281.png) | Big readable item icons, count badges, category tabs, corner-bracket selection | Object-recognition-first inventory and visible selection | Gold/yellow frame overload; numerous resources and stacked HUD layers |
| [Wargroove](https://interfaceingame.com/wp-content/uploads/wargroove/wargroove-codex.jpg) | Portrait list + selected biography + large illustration; categories on top; page count below | Character dossier / clue detail with artwork anchoring reading | Full-width dense codex as ordinary exploration screen |

## Four main references and adaptation judgement

| Main reference | Scene integration | Chinese reading adaptation | Keyboard/controller/touch adaptation | Clue hierarchy |
|---|---|---|---|---|
| A Short Hike | Strongest for exploration; almost all world | Prompt only; use clean Chinese UI font | Replace source A glyph with existing Space; touch action >=44px | Only one current contextual action |
| Stardew Valley | Strong for conversation/map; world visibly surrounds panel | 16px/1.55 body, 2–3 lines; avoid English pixel font | Retain existing narrative timing/pause/advance behavior; do not add Space advance; explicit choices and proposed 44px touch rows | Portrait/name/body/action separated |
| Moonlighter | Strong modal object identity; background dims | Independent crisp Chinese layer; 16px text, do not shrink book to fit | Source shows controller glyphs, not proof of touch; retain existing controller entry/return behavior (P opens phone only); narrow view list -> detail | Best for left selection/right object evidence; tabs are physical and purposeful |
| The Final Station | Strongest evidence-in-world visual | Art includes document marks; readable transcript/zoom must be available | Clear close and hotspot targets; no hover-only clues | Actual object first, clue annotation second |

## Synthesis

Do not combine ten visual skins. Use A Short Hike's spatial restraint, Stardew's conversation hierarchy, Moonlighter's clue-book form and Final Station's physical-evidence inspection. Keep cream/navy/wood/coral project palette. Treat shape, layout and state as component-specific: book for archive, portrait frame for conversation, paper object for evidence, small pointer for nearby interaction. Never use one generic cream rectangle for all four.

Chinese and touch recommendations remain design/test targets, not completed acceptance results: aim for no body text below 15px, no baked-in essential Chinese text, no clipped choices across the scaling range actually supported by code (200% is an optional test target, not an asserted capability), and 44px targets, focus visible beyond color, no input leaking to world through modal, existing Space/P/Esc consistent. No green gems/check badges, no pure-text replacement of gameplay scene.

## User-supplied exact Game UI Database references

Both specific URLs were separately opened in the browser, not inferred from the homepage failure:

- https://gameuidatabase.com/gameData.php?id=243 — 2026-10-21 06:51 UTC; Rendered result: “Your request was blocked.” Exact-URL index search found no identifying result.
- https://gameuidatabase.com/gameData.php?id=1704 — 2026-10-21 06:52 UTC; Rendered result: “Your request was blocked.” Exact-URL and site-name/ID index searches found no results.

The game names behind these IDs remain unverified. They must not be attributed to any of the ten inspected games. No bypass or local-user computer operation was attempted. User-provided screenshots or game titles would allow independent visual comparison. The implementation should not claim that it reproduces either inaccessible reference.
