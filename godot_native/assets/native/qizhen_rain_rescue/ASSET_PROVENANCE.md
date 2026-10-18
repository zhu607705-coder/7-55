# Asset provenance

- `assets/lake_rain.png`: existing `src/assets/rpg/interiors/weather/qizhen_lake_dock_rain_concept_v01.png`, byte-for-byte copy
- `assets/player_down.png`, `player_side.png`: existing `src/assets/rpg/player/player_down_0.png` and `player_side_0.png`, byte-for-byte copies for the fallback/review reference
- `assets/officer.png`: existing `src/assets/rpg/npcs/finale/guard_check_watch_2frame.png`, byte-for-byte copy for fallback/reference
- `assets/font.ttf`: existing `src/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf`, unchanged Fusion Pixel 12px Proportional zh_hans v2024.05.12; full SIL OFL 1.1 and upstream component notices in `assets/licenses/`; details in ASSET_LICENSES.md
- `assets/kayak_hull.svg`: isolated hull shapes from the existing editable `src/assets/rpg/qizhen/source/kayak_overhead_frame_a.svg`; no player/paddle content
- `assets/kayak_upturned.svg`: new native vector underside using the same authored silhouette and palette
- `assets/generated/rescue_pose_atlas_v01.png`: OpenAI built-in image_gen, 1447×1087 RGBA, 12 separated poses/props, measured regions in companion JSON
- `assets/generated/rescue_pose_atlas_v02.png`: OpenAI built-in image_gen, 1774×887 RGBA, 8 additional relaxed/helper/walking poses, measured regions and mirroring flags in companion JSON

The generated PNGs remain intact. Runtime sampling and mirroring preserve the transparent background. Complete generation prompts are beside the images. No media was downloaded from unofficial sources.
- `assets/generated/officer_reach_up_right_v03.png`: OpenAI built-in image_gen, 1254×1254 RGBA, dedicated upward-reaching safety-officer pose. The measured region, torso pivot and palm midpoint are shared by rendering and ring-contact motion through `scripts/rescue_pose_geometry.gd`.
