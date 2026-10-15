# Native rain rescue, hull geometry, and portable journal photos

Source: `QizhenLakeScene.ts`, `QizhenRainRescuePresentation.ts`, `QizhenRainRescueCinematic.tsx`, `QizhenKayakTextures.ts`, `QizhenRecipeFrame.tsx`, `qizhen-recipe-frame.css`.

## Rain recovery

The forced rainy launch now requests a controller-issued native world presentation. It no longer accepts the old four-stroke generic minigame result. Source approach, launch, six strokes (three with reduced motion), gust, capsize, actual Ogg/Theora rescue video, and deterministic dock hold run before the chapter controller settles the recovery. Reduced motion follows the source static/video fallback. The source skip button skips only the replay; the dock hold remains. Video is muted, matching the source. Missing video falls back visibly and never pretends playback occurred.

Completion requires the retained session, live registered presenter, actual elapsed source timing, and unchanged eligible state. Dictionaries, early callbacks, stale state/reset receipts, canceled hosts, and duplicate completion do not grant recovery. Focus loss pauses route/video/hold. Closing or replacing the world effect restores actor visibility and leaves the dock state retryable. The transaction returns to the dorm with the source phone-home route, clears transient UI, resets tutorial stroke state, and increments capsize once.

`test_rain_rescue.gd`: 17 checks, including real native Theora decoding/playback and source skip/hold, passed in the cloud. The model/controller fixture is distinct from a manually played chapter.

## Hull geometry and rendering

The world uses the source heading-dependent 83×67 hull AABB while kayaking, plus the authored zone water areas. Walking still uses the shared character foot rectangle. Boat-wall contact stops translation without creating a capsize or rotating the boat. Rendering now preserves the original 128×160 two-frame art at source scale0.52 with heading+π/2, rather than stretching it to110×70. Source forward/reverse wake layers and alternating frame presentation are native drawing.

`test_lake_world_geometry.gd`: 9 checks verify the reported island, dock/water boundary and diagonal-heading cases.

## Photo portability

Browser-origin photos have no original image bytes: the source saves a recipe and renders the composition. `ui/qizhen_recipe_frame.gd` reconstructs that exact saved recipe using the original zone map/kayak assets, source crop clamping, zoom steps1/1.5/2.2, eight heading buckets, ripple and swan silhouette rules. These are saved-source compositions, not fabricated framebuffer captures. Native photos continue to show their hash-verified actual PNG first. Missing old native PNGs get an explicitly labeled recipe reconstruction.

New native JSON exports embed journal PNG bytes once per SHA-256. Imports validate canonical base64, digest, PNG signature and bounded dimensions before decoding. Files install only under content-addressed local paths, never an archive-selected destination. Corrupt/partial media rejects the import; failed story-save installation rolls back newly created attachments. Existing files are never overwritten by mismatched bytes. Ordinary autosaves retain lightweight local paths.

Portable export limits are48MiB JSON,32MiB total image bytes and12MiB per image. Browser imports and native autosave limits stay8MiB. Oversized or missing native photo bytes cause explicit export failure rather than a silently incomplete portable export.

`test_journal_portability.gd`: 14 checks verify actual export→remove original PNG→import→display, duplicate-reference remapping, corrupt attachment nonmutation, source-only recipes and projection equations. Test pixels are synthetic transport fixtures, not gameplay screenshots.
