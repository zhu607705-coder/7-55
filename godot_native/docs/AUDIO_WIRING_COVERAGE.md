# Audio reachability audit at the current freeze

This is a wiring audit, not an assertion that accepting 237 cue IDs makes all original scenes complete. The consumer supports every manifest beat. The following events have source-backed native producers/adapters. Tests exercise real players and representative controller paths; the complete original PresentationDirector derivation is checked against 4,096 original-source transition pairs.

## Reached C3 producers

- Scene lifecycle: canteen_interior_opened; theater_interior_opened; qizhen_lake_opened; canteen_dark_mode_enabled; canteen_light_mode_enabled; theater_dark_mode_enabled; theater_light_mode_enabled
- Successful physical tray pickup: canteen_tray_slide_started immediately, canteen_tray_slide_completed after source 360 ms (100 ms reduced motion), preserving trayId
- Accepted order/pickup: canteen_order_solved; canteen_order_wrong; canteen_wrong_meal_collected, including original optionId/itemId/windowId payloads
- Source-timed pickup prelude: canteen_pickup_ticket_handoff; canteen_pickup_cutscene_quiet; canteen_paper_package_wait; canteen_paper_package_shake; canteen_paper_burst_started; canteen_paper_camera_impact; then canteen_defense_started when actual defense begins
- Canteen return/bike/chase: canteen_returned_to_campus; canteen_bike_code_read; canteen_bike_glare_failed; canteen_bike_lock_cleaned; canteen_bike_payment_ready; canteen_chase_started; canteen_chase_collision; canteen_chase_finish; canteen_chase_completed
- Theater: theater_poster_cleaned; theater_ticket_first_wave_slow; theater_ticket_first_wave_cellular_success; theater_ticket_second_wave_success; theater_ticket_printed; theater_ticket_combined; theater_ticket_admitted; theater_program_collected; theater_program_order_wrong; theater_program_order_solved; theater_prop_box_opened; theater_paper_dusted; theater_spotlight_started; theater_spotlight_hit; theater_spotlight_third_hit; theater_spotlight_missed; theater_reversal_completed
- Lake clue/entry/exit: qizhen_bridge_clue_found; qizhen_reflection_clue_found; qizhen_location_solved; qizhen_lake_left
- Fishing session: qizhen_fishing_started; qizhen_fishing_warning; qizhen_fishing_completed; qizhen_fishing_catch_completed; qizhen_fishing_paper_completed; qizhen_fishing_failed; qizhen_fishing_cancelled
- Swan runtime: rpg_qizhen_chase_started; rpg_qizhen_chase_restarted; qizhen_swan_chase_telegraph; qizhen_swan_chase_telegraph_voice; qizhen_swan_chase_surge; qizhen_swan_chase_release; qizhen_swan_chase_final_bank; rpg_qizhen_chase_failed; rpg_qizhen_escape_completed_requested. These follow pressure/segment/terminal transitions, with source `final_bank` priority, and never grant completion themselves
- Recovery: chapter35_recovery_opened; memo audition/excerpt/stop handled by the dedicated proven media host
- Dynamic chapter3_story_line: exact canonical subtitle lookup; Theater source-timed wrong-order/reversal sequences and inspector-close continuation

Primary evidence: ChapterThreeCanteenController.ts, ChapterThreeTheaterController.ts, ChapterThreeQizhenLakeController.ts, ChapterThreePhoneInterludeController.ts, CanteenInteriorScene.ts, TheaterInteriorScene.ts, QizhenLakeScene.ts, CanteenChaseOverlay.tsx and RpgGameHost.tsx. The native compatibility maps name action and successful fact/list/phase changes; result.presentation is used where transient validated payloads would otherwise be lost.

## Reached C4 producers

- Exact source PresentationDirector: clock_stutter_started; clock_stable_started; final_chase_started; final_chase_failed; final_chase_succeeded; chapter4_755_scene_closed
- Controller/state adapters: chapter4_time_swap_committed; room204_drawer_opened; maintenance_cart_wheel_repaired; clock_gear_repaired; blackout_committed; power_zone_toggled; power_grid_locked; final_minute_installed; morning_checkin_card_accepted; morning_checkin_paper_accepted; morning_checkin_completed
- Presentation transitions: chapter4_bakery_conveyor_stop uses the authored conveyor bounds and actual native player foot position; maintenance_cart_roll_started uses the source 900 ms repaired-push duration
- Connected Chapter4Activity forwards the full exported prologue timeline and finished/closed lifecycle to the global director. Skip cancels pending narration while retaining its score until source finish/close. Close is owner-scoped so it cannot stop a later clock/chase track
- The world guard adapter emits final_chase_pressure_catch_up, final_chase_pressure_tracking, final_chase_pressure_close, final_chase_close_voice and final_chase_floor_changed

## Procedural audio reached outside manifests

- Global useChiptune: original twelve square-wave notes, exponential amplitude envelope, audible playback/pause and focus suspend
- Canteen ChaseStunt event tones: bell, collision, jump, collect, item and finish, with original oscillator and pitch/gain ramps; source `stunt` events deliberately have no tone
- Fishing four-beat/count-in metronome: beat-pattern timing, layered source tones and judgment sounds; source warning follows judged-note tension rather than a guessed generic threshold timer

## Explicitly outstanding active native presentation milestones

1. canteen_entry_paper_spotted and canteen_entry_paper_escape_started. The source's proximity test is CanteenInteriorScene.ts around 705–710; discovery waits 820/160 ms, then escape begins another 2380/1120 ms later. Native c3_enter_canteen currently sets entryPaperEscaped immediately, and has no matching paper-discovery actor/callback. Do not play these two sounds at arbitrary scene-entry times or mutate progression from the audio director
2. ChapterThreeOpeningOverlay timeline: chapter_three_opening_started; chapter_three_opening_record_scan; chapter_three_opening_mode_unlock; chapter_three_opening_paper_burst; chapter_three_opening_exit_observation; chapter_three_opening_cart_clear; chapter_three_opening_route_confirm; chapter_three_opening_arrival. Source createOpeningBeats controls these events and causal completion. Native Library022 currently completes its dialogue and moves directly to campus. Restoring the native presentation/gate is the next pass
3. chapter4_environment_hint_pulse. Source ChapterFourTemporalMazeScene.ts around 2317 derives its pulse/pan from spatial environmental-hint presentation. It requires the corresponding native world callback
4. Specific early/library UI events still need explicit source-equivalent producers: act2_friend_reply_filled, act2_mentor_line_stuck, act2_gamepad_purchase_rejected, library_catalog_distractor_selected and tiyi_audit_value_changed. Unchanged success snapshots cannot prove these UI actions. Their playback beats are supported, but the action must supply its actual event/payload

## Retained manifests that do not describe current active source gameplay

No new native behavior is invented for these obsolete/unemitted beats:

- act1_locked_entry, act1_identity_verified, act1_phone_linked, act1_controls_installed, act1_movement_enabled, act1_required_item_collected, act1_area_visited, act1_map_completed have no active original emitter. act1_area_visited also references absent fx_route_checkpoint
- canteen_chase_countdown, canteen_chase_lane_changed, canteen_chase_near_miss and canteen_chase_paper_nearer are not emitted by the current continuous-steering ChaseStunt overlay
- canteen_cart_roll_started and canteen_paper_block_impact belong to retained old cart-block methods; the current sixty-second CanteenDefenseRuntime turnaround callback does not emit these sounds
- qizhen_dark_mode_enabled, qizhen_light_mode_enabled, qizhen_reflection_wrong, qizhen_reflection_correct, qizhen_reflection_completed, qizhen_sign_rotated, qizhen_signs_completed, qizhen_decoy_wrong, qizhen_decoy_placed, qizhen_decoy_revealed, qizhen_mist_music_started, qizhen_mist_wrong, qizhen_mist_rhythm_read and qizhen_mist_completed belong to the old reflection/sign/mist puzzle, not the current kayak/tool-chain runtime
- maintenance_cart_wheel_stuck has no current source emitter
- chapter_three_opening_route is retained in captions/manifest, but createOpeningBeats currently goes from route_confirm to arrival without a route beat

These distinctions preserve actual source behavior rather than activating every old sound merely because its manifest was retained.
