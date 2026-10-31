extends RefCounted
## Native-only room checkpoints. No scene changes, rewards or progression inference.
const VERSION:=1
const ROOT:="res://campuses/future_learning_center/scripts/"
const ROOMS:={
 "2:electrical":["workbench_model.gd",["gear", "belt", "tension", "reverse_target", "completed", "transfer_completed"]],
 "2:koala":["puzzles/koala_model.gd",["chain", "revision", "card", "custom", "receipts", "completed"]],
 "2:machinery":["puzzles/machinery_model.gd",["variant", "clamp_slot", "displacement", "progress", "kerfs", "completed", "extension_completed"]],
 "2:seminar":["puzzles/solid_projection_model.gd",["poses", "bar_turn", "observation", "extension", "revision", "receipts", "completed", "extension_completed"]],
 "2:platform":["puzzles/platform_model.gd",["board", "condition", "revision", "records", "history", "completed"]],
 "2:robotics":["puzzles/robotics_model.gd",["selector", "return_direction", "target", "revision", "run_id", "cargo_id", "completed", "transfer_completed", "receipts", "history"]],
 "2:team":["puzzles/signal_sync_model.gd",["cables", "revision", "source_pattern", "cache_pattern", "screens", "receipts", "history", "completed", "positions"]],
 "2:formula":["puzzles/formula_model.gd",["panel", "tilt", "gear", "scenario", "revision", "completed", "extension_completed", "records", "personal_best"]],
 "3:studio_2":["puzzles/coupled_model.gd",["positions", "angle", "connected", "revision", "completed"]],
 "3:studio_4":["puzzles/access_model.gd",["supports", "insertion", "cover", "angle", "loose", "side", "revision", "opened_revision", "completed", "extension_completed"]],
 "3:studio_3":["puzzles/sync_model.gd",["offsets", "dataset", "revision", "completed", "transfer_completed", "receipts"]],
 "3:studio_1":["puzzles/perspective_model.gd",["slots", "paper_turns", "observer", "extension", "revision", "receipts", "completed", "extension_completed"]],
 "3:recording":["puzzles/recording_model.gd",["x", "baffle_y", "round_id", "round_started", "reached_round", "photo_round", "revision", "completed", "history", "photo_kind"]],
 "3:pantry":["puzzles/balance_model.gd",["slots", "pivot", "revision", "completed", "extension_completed", "delivered"]],
 "3:seminar":["puzzles/schedule_model.gd",["slots", "tools", "cameras", "revision", "records", "completed", "extension_completed"]],
 "3:xlab_box":["puzzles/projection_model.gd",["depths", "heights", "geometry_revision", "receipts", "history", "extension", "completed", "extension_completed", "view_side", "angle"]],
 "3:xlab_south":["puzzles/fold_model.gd",["angles", "route", "connected", "attachment", "revision", "trial_revision", "operated", "completed", "extension_completed", "proofs"]],
 "3:xlab_north":["puzzles/logic_model.gd",["card", "swapped", "revision", "observation_revision", "block", "position", "receipts", "history", "completed", "transfer_completed"]],
 "4:flex_c":["puzzles/flex_model.gd",["station", "orientation", "connections", "outer", "short_cable", "revision", "pattern", "records", "station_proofs", "completed"]],
 "4:collab_b":["puzzles/collab_model.gd",["slots", "configuration_revision", "fixture_revision", "quarter_turn", "condition", "receipts", "history", "completed"]],
 "4:focus_a":["puzzles/focus_model.gd",["assignments", "extension", "revision", "mode", "receipts", "completed", "extension_completed"]],
 "4:storage":["puzzles/storage_model.gd",["positions", "door_angle", "taken", "returned", "completed", "revision"]],
 "4:seminar_3":["puzzles/assembly_model.gd",["slots", "configuration_revision", "fixture_revision", "quarter_turn", "condition", "receipts", "history", "completed", "bracket_x", "bracket_attached"]],
 "4:seminar_2":["puzzles/rail_model.gd",["positions", "lengths", "siding", "edge_to", "edge_fraction", "extension_trial_armed", "extension", "completed", "extension_completed"]],
 "4:seminar_1":["puzzles/rules_model.gd",["slots", "true_rule", "station", "revision", "informative", "evidence", "completed"]],
 "2:solar_bench":["solar_race_model.gd",["setup","sky","revision","earned","last_trial","best"]],
 "2:robot_delivery":["robot_delivery_model.gd",["tiles","outlet","revision","earned","last_trace"]],
 "2:signal_bench":["signal_sync_model.gd",["wires","revision","source_pattern","cached_pattern","displayed","verified_patterns","earned"]],
 "3:pantry_water":["pantry_tray_model.gd",["cups","water","dock_slot","dispensed_ml","support","revision","earned","advanced_earned","deliveries","attempts","last_moment"]],
}
const COUNTER_LIMIT:=1000000000.0
static func empty()->Dictionary:return {"version":VERSION,"rooms":{}}
# Fixed v1 schemas; no campus script/resource is loaded during save validation.
const SCHEMA:={
 "2:electrical":{"fields":{"belt":0,"completed":false,"gear":-1,"reverse_target":false,"tension":0,"transfer_completed":false},"reset":{"belt":0,"completed":false,"elapsed":0.0,"gear":-1,"gear_phase":0.0,"history":[],"motor_phase":0.0,"outcome":"","output_phase":0.0,"reverse_target":false,"running":false,"tension":0,"transfer_completed":false,"travel":0.12}},
 "2:formula":{"fields":{"completed":false,"extension_completed":false,"gear":2,"panel":0,"personal_best":[0.0,0.0],"records":[],"revision":0,"scenario":0,"tilt":0},"reset":{"accumulator":0.0,"cars":[{"@":"dict","v":[["v",0.0],["distance",0.0],["electrical_energy",0.0],["mechanical_energy",0.0],["peak_power_fraction",0.0],["energy_error",0.0]]},{"@":"dict","v":[["v",0.0],["distance",0.0],["electrical_energy",0.0],["mechanical_energy",0.0],["peak_power_fraction",0.0],["energy_error",0.0]]}],"completed":false,"extension_completed":false,"gear":2,"on_track":false,"outcome":"","panel":0,"personal_best":[0.0,0.0],"records":[],"revision":0,"running":false,"scenario":0,"segments":[],"ticks":0,"tilt":0,"trial_revision":-1}},
 "2:koala":{"fields":{"card":0,"chain":[],"completed":false,"custom":[0,2,4,6],"receipts":{"@":"dict","v":[]},"revision":0},"reset":{"card":0,"chain":[],"completed":false,"custom":[0,2,4,6],"elapsed":0.0,"frames":[],"history":[],"outcome":"","paused":false,"receipts":{"@":"dict","v":[]},"revision":0,"running":false,"step_index":0,"trial_card":0,"trial_revision":-1,"work":[]}},
 "2:machinery":{"fields":{"clamp_slot":0,"completed":false,"displacement":{"@":"v2","v":[0.0,0.0]},"extension_completed":false,"kerfs":[{"@":"pv2","v":[]},{"@":"pv2","v":[]},{"@":"pv2","v":[]}],"progress":[0.0,0.0,0.0],"variant":0},"reset":{"_gesture":{"@":"dict","v":[]},"active_cut":-1,"clamp_slot":0,"completed":false,"contact_kind":"","displacement":{"@":"v2","v":[0.0,0.0]},"extension_completed":false,"history":[],"kerfs":[{"@":"pv2","v":[]},{"@":"pv2","v":[]},{"@":"pv2","v":[]}],"outcome":"","progress":[0.0,0.0,0.0],"running":false,"variant":0}},
 "2:platform":{"fields":{"board":{"@":"v2","v":[740.0,210.0]},"completed":false,"condition":0,"history":[],"records":{"@":"dict","v":[]},"revision":0},"reset":{"board":{"@":"v2","v":[740.0,210.0]},"completed":false,"condition":0,"exposure":0.0,"history":[],"outcome":"","photographing":false,"records":{"@":"dict","v":[]},"revision":0,"shot":{"@":"dict","v":[]},"trial_condition":-1,"trial_revision":-1}},
 "2:robot_delivery":{"fields":{"earned":false,"last_trace":[],"outlet":2,"revision":0,"tiles":{"@":"dict","v":[[{"@":"v2i","v":[0,0]},{"@":"dict","v":[["kind","corner"],["rotation",3]]}],[{"@":"v2i","v":[1,0]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[2,0]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[3,0]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[4,0]},{"@":"dict","v":[["kind","corner"],["rotation",3]]}],[{"@":"v2i","v":[0,1]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[1,1]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[2,1]},{"@":"dict","v":[["kind","oneway"],["rotation",0]]}],[{"@":"v2i","v":[3,1]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[4,1]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[0,2]},{"@":"dict","v":[["kind","corner"],["rotation",0]]}],[{"@":"v2i","v":[1,2]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[2,2]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[3,2]},{"@":"dict","v":[["kind","straight"],["rotation",0]]}],[{"@":"v2i","v":[4,2]},{"@":"dict","v":[["kind","corner"],["rotation",0]]}]]}},"reset":{"cargo":"base","cell":{"@":"v2i","v":[0,1]},"complete":false,"delivered":false,"direction":0,"earned":false,"edge_stop_progress":1.0,"edge_valid":true,"fault":"","history":[],"incoming":-1,"last_trace":[],"moved":0.0,"next_cell":{"@":"v2i","v":[0,1]},"outlet":2,"phase":"ready","position":{"@":"v2","v":[0.0,1.0]},"progress":0.0,"returning":false,"revision":0,"run_revision":-1,"running":false,"trace":[{"@":"v2","v":[0.0,1.0]}],"visits":{"@":"dict","v":[]}}},
 "2:robotics":{"fields":{"cargo_id":0,"completed":false,"history":[],"receipts":[],"return_direction":0,"revision":0,"run_id":0,"selector":0,"target":2,"transfer_completed":false},"reset":{"blocked_edge":[],"cargo_id":0,"cargo_position":{"@":"v2","v":[130.0,310.0]},"completed":false,"history":[],"inward":[],"loaded":false,"next_node":-1,"node":0,"outcome":"","outward":[],"paused":false,"phase":"idle","position":{"@":"v2","v":[165.0,310.0]},"progress":0.0,"receipts":[],"return_direction":0,"revision":0,"run_id":0,"running":false,"selector":0,"target":2,"transfer_completed":false,"trial_revision":-1,"unloaded":false}},
 "2:seminar":{"fields":{"bar_turn":0,"completed":false,"extension":false,"extension_completed":false,"observation":0,"poses":[{"@":"v3i","v":[-1,-1,-1]},{"@":"v3i","v":[-1,-1,-1]},{"@":"v3i","v":[-1,-1,-1]}],"receipts":{"@":"dict","v":[]},"revision":0},"reset":{"bar_turn":0,"completed":false,"drag_elapsed":0.0,"drag_piece":-1,"drag_stage":"","drag_start":{"@":"v3","v":[0.0,0.0,0.0]},"drop_target":{"@":"v3i","v":[-1,-1,-1]},"elapsed":0.0,"extension":false,"extension_completed":false,"history":[],"lift_target":{"@":"v3","v":[0.0,0.0,0.0]},"lower_from":{"@":"v3","v":[0.0,0.0,0.0]},"observation":0,"outcome":"","paused":false,"poses":[{"@":"v3i","v":[-1,-1,-1]},{"@":"v3i","v":[-1,-1,-1]},{"@":"v3i","v":[-1,-1,-1]}],"preview_origin":{"@":"v3","v":[0.0,0.0,0.0]},"receipts":{"@":"dict","v":[]},"revision":0,"running":false,"trial_revision":-1}},
 "2:signal_bench":{"fields":{"cached_pattern":0,"displayed":{"@":"dict","v":[["left",1],["right",0]]},"earned":false,"revision":0,"source_pattern":1,"verified_patterns":[],"wires":{"@":"dict","v":[["split","live"],["left","split_a"],["right","cached"]]}},"reset":{"cached_pattern":0,"complete":false,"displayed":{"@":"dict","v":[["left",1],["right",0]]},"earned":false,"elapsed":0.0,"history":[],"outcome":"ready","received":{"@":"dict","v":[["left",false],["right",false]]},"revision":0,"run_revision":-1,"running":false,"source_pattern":1,"verified_patterns":[],"wires":{"@":"dict","v":[["split","live"],["left","split_a"],["right","cached"]]}}},
 "2:solar_bench":{"fields":{"best":{"@":"dict","v":[]},"earned":false,"last_trial":{"@":"dict","v":[]},"revision":0,"setup":{"@":"dict","v":[["panel",0],["tilt",0],["gear",2]]},"sky":0},"reset":{"accumulator":0.0,"best":{"@":"dict","v":[]},"cars":[{"@":"dict","v":[["distance",0.0],["speed",0.0]]},{"@":"dict","v":[["distance",0.0],["speed",0.0]]}],"complete":false,"earned":false,"history":[],"last_trial":{"@":"dict","v":[]},"outcome":"ready","revision":0,"run_revision":-1,"running":false,"setup":{"@":"dict","v":[["panel",0],["tilt",0],["gear",2]]},"sky":0,"ticks":0,"trace":[]}},
 "2:team":{"fields":{"cables":{"@":"dict","v":[["bus_in","source"],["screen_a","live_a"],["screen_b","cache"]]},"cache_pattern":2,"completed":false,"history":[],"positions":[{"@":"v2","v":[680.0,180.0]},{"@":"v2","v":[680.0,350.0]}],"receipts":{"@":"dict","v":[]},"revision":0,"screens":[0,2],"source_pattern":0},"reset":{"cables":{"@":"dict","v":[["bus_in","source"],["screen_a","live_a"],["screen_b","cache"]]},"cache_pattern":2,"completed":false,"delivered":[false,false],"elapsed":0.0,"history":[],"outcome":"","positions":[{"@":"v2","v":[680.0,180.0]},{"@":"v2","v":[680.0,350.0]}],"receipts":{"@":"dict","v":[]},"revision":0,"running":false,"screens":[0,2],"source_pattern":0,"trial_pattern":-1,"trial_revision":-1}},
 "3:pantry":{"fields":{"completed":false,"delivered":false,"extension_completed":false,"pivot":0.0,"revision":0,"slots":[0,1,2,3]},"reset":{"carry_origin":{"@":"v2","v":[315.0,310.0]},"carry_travel":0.0,"completed":false,"delivered":false,"drag_active":false,"dragged_center":{"@":"v2","v":[315.0,310.0]},"elapsed":0.0,"elevation":0.0,"extension_completed":false,"held":false,"history":[],"lift_revision":-1,"outcome":"","paused":false,"pivot":0.0,"revision":0,"running":false,"settle_origin":{"@":"v2","v":[315.0,310.0]},"slots":[0,1,2,3],"stage":"","tilt":0.0,"travel":0.0}},
 "3:pantry_water":{"fields":{"advanced_earned":false,"attempts":0,"cups":[0,1,2,3],"deliveries":0,"dispensed_ml":0.0,"dock_slot":-1,"earned":false,"last_moment":0.0,"revision":0,"support":0.0,"water":[0.0,0.0,0.0,0.0]},"reset":{"advanced_earned":false,"attempts":0,"cups":[0,1,2,3],"deliveries":0,"dispensed_ml":0.0,"dock_slot":-1,"draining":false,"earned":false,"elapsed":0.0,"last_moment":0.0,"phase":"table","revision":0,"support":0.0,"tap_open":false,"trial_revision":-1,"water":[0.0,0.0,0.0,0.0]}},
 "3:recording":{"fields":{"baffle_y":300.0,"completed":false,"history":[],"photo_kind":"","photo_round":-1,"reached_round":-1,"revision":0,"round_id":0,"round_started":false,"x":220.0},"reset":{"baffle_y":300.0,"completed":false,"direction":0,"exposure":0.0,"history":[],"outcome":"","paused":false,"photo_kind":"","photo_round":-1,"photographing":false,"reached_round":-1,"revision":0,"round_id":0,"round_started":false,"running":false,"x":220.0}},
 "3:seminar":{"fields":{"cameras":1,"completed":false,"extension_completed":false,"records":[],"revision":0,"slots":[0,0,0,1],"tools":[0,2,0,-1]},"reset":{"_invalid":false,"_trial_revision":-1,"_undo":[],"artifacts":[false,false,false,false],"beat":0,"cameras":1,"completed":false,"current_tasks":[],"errors":["","","",""],"extension_completed":false,"paused":false,"progress":0.0,"records":[],"revision":0,"running":false,"slots":[0,0,0,1],"tools":[0,2,0,-1]}},
 "3:studio_1":{"fields":{"completed":false,"extension":false,"extension_completed":false,"observer":0,"paper_turns":[0,0,0],"receipts":{"@":"dict","v":[]},"revision":0,"slots":[0,2,1,3]},"reset":{"completed":false,"elapsed":0.0,"extension":false,"extension_completed":false,"history":[],"observer":0,"outcome":"","paper_turns":[0,0,0],"paused":false,"receipts":{"@":"dict","v":[]},"revision":0,"running":false,"slots":[0,2,1,3],"trial_observer":0,"trial_revision":-1}},
 "3:studio_2":{"fields":{"angle":0.0,"completed":false,"connected":false,"positions":[{"@":"v2","v":[450.0,400.0]},{"@":"v2","v":[510.0,400.0]}],"revision":0},"reset":{"angle":0.0,"blocked_at":{"@":"v2","v":[0.0,0.0]},"completed":false,"connected":false,"history":[],"outcome":"","paused":false,"positions":[{"@":"v2","v":[450.0,400.0]},{"@":"v2","v":[510.0,400.0]}],"revision":0,"running":false}},
 "3:studio_3":{"fields":{"completed":false,"dataset":0,"offsets":[0.0,0.0],"receipts":[],"revision":0,"transfer_completed":false},"reset":{"completed":false,"dataset":0,"elapsed":0.0,"gate":0.0,"offsets":[0.0,0.0],"outcome":"","paused":false,"receipts":[],"revision":0,"running":false,"transfer_completed":false,"travel":0.0,"trial_revision":-1}},
 "3:studio_4":{"fields":{"angle":0.0,"completed":false,"cover":true,"extension_completed":false,"insertion":0.0,"loose":false,"revision":0,"side":0,"supports":[true,true],"opened_revision":-1},"reset":{"_gesture":{"@":"dict","v":[]},"angle":0.0,"completed":false,"contact_kind":"","cover":true,"extension_completed":false,"history":[],"insertion":0.0,"loose":false,"opened_revision":-1,"outcome":"","revision":0,"side":0,"supports":[true,true]}},
 "3:xlab_box":{"fields":{"angle":0.0,"completed":false,"depths":[0,0],"extension":false,"extension_completed":false,"geometry_revision":0,"heights":[0,0],"history":[],"receipts":{"@":"dict","v":[]},"view_side":0},"reset":{"angle":0.0,"completed":false,"depths":[0,0],"drag_piece":-1,"elapsed":0.0,"extension":false,"extension_completed":false,"geometry_revision":0,"heights":[0,0],"history":[],"outcome":"","paused":false,"preview_depth":0.0,"preview_height":0.0,"receipts":{"@":"dict","v":[]},"running":false,"trial_revision":-1,"trial_side":0,"view_side":0}},
 "3:xlab_north":{"fields":{"block":-1,"card":-1,"completed":false,"history":[],"observation_revision":0,"position":{"@":"v2","v":[500.0,300.0]},"receipts":{"@":"dict","v":[]},"revision":0,"swapped":false,"transfer_completed":false},"reset":{"block":-1,"card":-1,"completed":false,"elapsed":0.0,"history":[],"jaw":0.0,"observation_revision":0,"outcome":"","paused":false,"position":{"@":"v2","v":[500.0,300.0]},"receipts":{"@":"dict","v":[]},"revision":0,"running":false,"swapped":false,"transfer_completed":false,"trial":{"@":"dict","v":[]}}},
 "3:xlab_south":{"fields":{"angles":[0.0,0.0],"attachment":false,"completed":false,"connected":true,"extension_completed":false,"operated":false,"proofs":[],"revision":0,"route":0,"trial_revision":-1},"reset":{"_gesture":{"@":"dict","v":[]},"angles":[0.0,0.0],"attachment":false,"completed":false,"connected":true,"contact_kind":"","elapsed":0.0,"extension_completed":false,"history":[],"operated":false,"outcome":"","proofs":[],"revision":0,"route":0,"running":false,"trial_revision":-1}},
 "4:collab_b":{"fields":{"completed":false,"condition":0,"configuration_revision":0,"fixture_revision":0,"history":[],"quarter_turn":0,"receipts":{"@":"dict","v":[]},"slots":[-1,-1]},"reset":{"completed":false,"condition":0,"configuration_revision":0,"elapsed":0.0,"fixture_revision":0,"history":[],"outcome":"","paused":false,"quarter_turn":0,"receipts":{"@":"dict","v":[]},"running":false,"slots":[-1,-1],"travel":0.0,"trial":"","trial_condition":0,"trial_revision":{"@":"v2i","v":[0,0]}}},
 "4:flex_c":{"fields":{"completed":false,"connections":[0,1,2],"orientation":0,"outer":[true,true,true],"pattern":0,"records":[],"revision":0,"short_cable":false,"station":0,"station_proofs":[false,false]},"reset":{"_seen":{"@":"dict","v":[]},"_trial_revision":-1,"completed":false,"connections":[0,1,2],"orientation":0,"outcomes":["","",""],"outer":[true,true,true],"pattern":0,"paused":false,"progress":0.0,"received":[-1,-1,-1],"records":[],"revision":0,"running":false,"short_cable":false,"station":0,"station_proofs":[false,false]}},
 "4:focus_a":{"fields":{"assignments":[0,0,1,1,-1],"completed":false,"extension":false,"extension_completed":false,"mode":0,"receipts":{"@":"dict","v":[]},"revision":0},"reset":{"assignments":[0,0,1,1,-1],"completed":false,"elapsed":0.0,"extension":false,"extension_completed":false,"history":[],"mode":0,"outcome":"","paused":false,"receipts":{"@":"dict","v":[]},"revision":0,"running":false,"tested_device":-1,"tested_revision":-1,"undo_stack":[]}},
 "4:seminar_1":{"fields":{"completed":false,"evidence":[],"informative":false,"revision":0,"slots":[-1,-1,-1,-1],"station":0,"true_rule":0},"reset":{"completed":false,"elapsed":0.0,"evidence":[],"informative":false,"outcome":"","paused":false,"revision":0,"running":false,"slots":[-1,-1,-1,-1],"station":0,"trial_revision":-1,"true_rule":0,"undo_stack":[]}},
 "4:seminar_2":{"fields":{"completed":false,"extension":false,"extension_completed":false,"lengths":[1,1],"positions":[0,8],"siding":false,"edge_to":[-1,-1],"edge_fraction":[0.0,0.0],"extension_trial_armed":false},"reset":{"auto_return":false,"blocked":-1,"cart":-1,"completed":false,"destination":-1,"drag_cart":-1,"drag_snapshot":{"@":"dict","v":[]},"edge_fraction":[0.0,0.0],"edge_to":[-1,-1],"elapsed":0.0,"extension":false,"extension_completed":false,"extension_trial_armed":false,"history":[],"lengths":[1,1],"paused":false,"positions":[0,8],"running":false,"siding":false}},
 "4:seminar_3":{"fields":{"bracket_attached":true,"bracket_x":0.0,"completed":false,"condition":0,"configuration_revision":0,"fixture_revision":0,"history":[],"quarter_turn":0,"receipts":{"@":"dict","v":[]},"slots":[-1,-1]},"reset":{"bracket_attached":true,"bracket_x":0.0,"completed":false,"condition":0,"configuration_revision":0,"elapsed":0.0,"fixture_revision":0,"history":[],"outcome":"","paused":false,"quarter_turn":0,"receipts":{"@":"dict","v":[]},"running":false,"slots":[-1,-1],"travel":0.0,"trial":"","trial_condition":0,"trial_revision":{"@":"v2i","v":[0,0]}}},
 "4:storage":{"fields":{"completed":false,"door_angle":0.0,"positions":[{"@":"v2","v":[250.0,258.0]},{"@":"v2","v":[435.0,255.0]},{"@":"v2","v":[535.0,255.0]}],"returned":false,"revision":0,"taken":false},"reset":{"_gesture":{"@":"dict","v":[]},"completed":false,"contact_kind":"","door_angle":0.0,"history":[],"positions":[{"@":"v2","v":[250.0,258.0]},{"@":"v2","v":[435.0,255.0]},{"@":"v2","v":[535.0,255.0]}],"returned":false,"revision":0,"taken":false}}
}

static func capture(room_id:String,model:Object)->Dictionary:
 if not ROOMS.has(room_id) or model==null:return {}
 var fields:Dictionary={}
 for key:String in ROOMS[room_id][1]:
  var value:Variant=model.get(key)
  # Histories are evidence, not live undo stacks; keep newest bounded records.
  if value is Array and key in ["history","records","receipts","proofs","evidence"]:
   if room_id=="4:seminar_1" and key=="evidence":value=_rule_evidence(value)
   else:value=value.slice(maxi(0,value.size()-64))
  fields[key]=encode(value)
 var payload:Dictionary={"version":VERSION,"fields":fields}
 return payload if valid_room(room_id,payload) else {}
static func encode(value:Variant)->Variant:
 if value is Vector2:return {"@":"v2","v":[value.x,value.y]}
 if value is Vector2i:return {"@":"v2i","v":[value.x,value.y]}
 if value is Vector3:return {"@":"v3","v":[value.x,value.y,value.z]}
 if value is Vector3i:return {"@":"v3i","v":[value.x,value.y,value.z]}
 if value is Rect2:return {"@":"rect","v":[value.position.x,value.position.y,value.size.x,value.size.y]}
 if value is PackedVector2Array:
  var points:Array=[]
  for point:Vector2 in value:points.append([point.x,point.y])
  return {"@":"pv2","v":points}
 if value is Array:
  var result:Array=[]
  for item:Variant in value:result.append(encode(item))
  return result
 if value is Dictionary:
  var pairs:Array=[]
  for key:Variant in value:pairs.append([encode(key),encode(value[key])])
  return {"@":"dict","v":pairs}
 return value
static func _number(v:Variant,low:float=-COUNTER_LIMIT,high:float=COUNTER_LIMIT)->bool:
 return (v is int or v is float) and is_finite(float(v)) and float(v)>=low and float(v)<=high
static func _integer(v:Variant,low:float=-COUNTER_LIMIT,high:float=COUNTER_LIMIT)->bool:
 return _number(v,low,high) and float(v)==floorf(float(v))
static func _safe(v:Variant,depth:int=0)->bool:
 if depth>12:return false
 if v is bool or v==null:return true
 if v is String:
  if v.length()>512:return false
  for i:int in v.length():
   if v.unicode_at(i)==0:return false
  return true
 if v is int or v is float:return _number(v)
 if v is Array:
  if v.size()>2048:return false
  for item:Variant in v:
   if not _safe(item,depth+1):return false
  return true
 if not v is Dictionary or v.size()!=2 or not v.has("@") or not v.get("v") is Array:return false
 var tag:Variant=v["@"];var a:Array=v.v
 if tag in ["v2","v2i","v3","v3i","rect"]:
  if a.size()!=(4 if tag=="rect" else (3 if tag in ["v3","v3i"] else 2)):return false
  for n:Variant in a:
   if not _number(n) or (tag in ["v2i","v3i"] and not _integer(n)):return false
  return true
 if tag=="pv2":
  if a.size()>2048:return false
  for point:Variant in a:
   if not point is Array or point.size()!=2 or not _number(point[0]) or not _number(point[1]):return false
  return true
 if tag=="dict":
  if a.size()>128:return false
  var seen:Dictionary={}
  for pair:Variant in a:
   if not pair is Array or pair.size()!=2:return false
   var key:Variant=pair[0]
   if not (key is String or _integer(key) or (key is Dictionary and key.get("@") in ["v2i","v2"] and _safe(key,depth+1))):return false
   if seen.has(key):return false
   seen[key]=true
   if not _safe(key,depth+1) or not _safe(pair[1],depth+1):return false
  return true
 return false
static func decode(v:Variant)->Variant:
 if v is Array:
  var result:Array=[]
  for item:Variant in v:result.append(decode(item))
  return result
 if not v is Dictionary:return v
 var a:Array=v.v
 match v["@"]:
  "v2":return Vector2(a[0],a[1])
  "v2i":return Vector2i(int(a[0]),int(a[1]))
  "v3":return Vector3(a[0],a[1],a[2])
  "v3i":return Vector3i(int(a[0]),int(a[1]),int(a[2]))
  "rect":return Rect2(a[0],a[1],a[2],a[3])
  "pv2":
   var points:=PackedVector2Array()
   for point:Array in a:points.append(Vector2(point[0],point[1]))
   return points
  "dict":
   var d:Dictionary={}
   for pair:Array in a:
    var key:Variant=decode(pair[0])
    if key is float:key=int(key)
    d[key]=decode(pair[1])
   return d
 return null
static func _matches(value:Variant,template:Variant)->bool:
 if template is bool:return value is bool
 if template is int:return _integer(value)
 if template is float:return _number(value)
 if template is String:return value is String
 if template is Array:
  if not value is Array:return false
  if not template.is_empty() and value.size()!=template.size():return false
  for i:int in value.size():
   if not template.is_empty() and not _matches(value[i],template[i]):return false
   if template.is_typed():
    var kind:int=template.get_typed_builtin()
    if kind==TYPE_INT and not _integer(value[i]):return false
    elif kind==TYPE_FLOAT and not _number(value[i]):return false
    elif kind not in [TYPE_INT,TYPE_FLOAT] and typeof(value[i])!=kind:return false
  return true
 return typeof(value)==typeof(template)
static func valid_room(room_id:String,payload:Variant)->bool:
 if not ROOMS.has(room_id) or not payload is Dictionary or payload.size()!=2 or not _integer(payload.get("version"),VERSION,VERSION) or not payload.get("fields") is Dictionary:return false
 var fields:Dictionary=payload.fields
 if fields.size()!=ROOMS[room_id][1].size():return false
 if JSON.stringify(payload).to_utf8_buffer().size()>192*1024:return false
 for key:String in ROOMS[room_id][1]:
  if not fields.has(key) or not _safe(fields[key]):return false
  var value:Variant=decode(fields[key])
  if not _matches(value,decode(SCHEMA[room_id].fields[key])):return false
  if not _field_range(room_id,key,value) or not _contents_valid(room_id,key,value):return false
 return true
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.size() not in [2,3] or not _integer(value.get("version"),VERSION,VERSION) or not value.get("rooms") is Dictionary:return false
 if value.size()==3 and (not value.has("location") or not valid_location(value.location)):return false
 if value.rooms.size()>ROOMS.size():return false
 for id:Variant in value.rooms:
  if not id is String or not valid_room(id,value.rooms[id]):return false
 return JSON.stringify(value).to_utf8_buffer().size()<=2*1024*1024
static func restore(room_id:String,model:Object,payload:Dictionary)->bool:
 if model==null or not valid_room(room_id,payload):return false
 # All transient resets are fixed data. No model load, start, step or completion
 # method runs at the load boundary, including while the lazy pack is absent.
 for key:String in SCHEMA[room_id].reset:
  _assign(model,key,decode(SCHEMA[room_id].reset[key]))
 for key:String in ROOMS[room_id][1]:
  var value:Variant=decode(payload.fields[key])
  _assign(model,key,value)
 if room_id=="2:electrical":model.set("travel",.92 if model.get("reverse_target") else .12)
 if room_id=="3:pantry":model.set("travel",1.0 if model.get("delivered") else 0.0)
 return true
static func _assign(model:Object,key:String,value:Variant)->void:
 var template:Variant=model.get(key)
 if template is Array and template.is_typed():
  var typed:Array=template.duplicate();typed.assign(value);model.set(key,typed)
 elif template is int:model.set(key,int(value))
 elif template is float:model.set(key,float(value))
 else:model.set(key,value)
static func _field_range(room:String,key:String,value:Variant)->bool:
 # Fields that index authored arrays must never accept out-of-range values.
 var ranges:Dictionary={
  "2:electrical":{"gear":[-1,2],"belt":[0,2],"tension":[0,2]},
  "2:formula":{"panel":[-1,1],"tilt":[0,2],"gear":[-1,2],"scenario":[0,1]},
  "2:machinery":{"variant":[0,1],"clamp_slot":[-1,2]},
  "2:seminar":{"bar_turn":[0,1],"observation":[0,3]},
  "2:platform":{"condition":[0,1]},"2:robotics":{"selector":[0,1],"return_direction":[0,1],"target":[2,5]},
  "2:team":{"source_pattern":[0,2],"cache_pattern":[0,2]},"2:koala":{"card":[-1,1]},
  "3:studio_1":{"observer":[0,2]},"3:studio_3":{"dataset":[0,1]},
  "3:studio_4":{"side":[0,1],"insertion":[0,185],"angle":[0,PI/2]},
  "3:xlab_south":{"route":[0,2]},"3:xlab_north":{"card":[-1,2],"block":[-1,2]},
  "3:xlab_box":{"view_side":[0,1]},"3:seminar":{"cameras":[1,2]},
  "3:recording":{"x":[220,670],"baffle_y":[150,300]},
  "4:flex_c":{"station":[0,1],"orientation":[0,2],"pattern":[0,2]},
  "4:focus_a":{"mode":[0,1]},"4:storage":{"door_angle":[0,PI/2]},
  "4:collab_b":{"quarter_turn":[0,3],"condition":[0,1]},
  "4:seminar_3":{"quarter_turn":[0,3],"condition":[0,1],"bracket_x":[-138,138]},
  "2:solar_bench":{"sky":[0,2]},"2:robot_delivery":{"outlet":[1,3]},"2:signal_bench":{"source_pattern":[0,3],"cached_pattern":[0,3]},"3:pantry_water":{"dock_slot":[-1,3],"support":[-.25,.25],"dispensed_ml":[0,1000000]},
  "4:seminar_1":{"true_rule":[0,1],"station":[0,1]}}
 if ranges.get(room,{}).has(key):
  var limits:Array=ranges[room][key]
  var tolerance:float=.000001 if key in ["angle","insertion","door_angle","bracket_x","x","baffle_y"] else 0.0
  if not _number(value,limits[0]-tolerance,limits[1]+tolerance):return false
 if key in ["revision","configuration_revision","fixture_revision","geometry_revision","observation_revision","run_id","round_id","cargo_id"] and not _integer(value,0):return false
 if room=="2:robotics" and key=="target" and int(value) not in [2,5]:return false
 if key in ["history","records","receipts","proofs","evidence"] and value.size()>128:return false
 if value is Vector2 and (absf(value.x)>2000 or absf(value.y)>2000):return false
 if key=="slots" and value is Array:
  var max_slot:int=5 if room=="4:seminar_1" else (2 if room=="3:seminar" else 3)
  for n:Variant in value:
   if not _integer(n,-1,max_slot):return false
 if value is Array:
  for point:Variant in value:
   if point is Vector2 and (absf(point.x)>2000 or absf(point.y)>2000):return false
   if point is Vector3i and (point.x< -1 or point.y< -1 or point.z< -1 or point.x>1 or point.y>1 or point.z>1):return false
  var bounds:Dictionary={"slots":[-1,7],"tools":[-1,2],"assignments":[-1,1],"connections":[-1,2],"lengths":[1,2],"depths":[0,3],"heights":[0,1],"angles":[0,PI],"progress":[0,1],"paper_turns":[0,3],"screens":[0,2],"custom":[0,7],"chain":[0,7],"personal_best":[0,10000],"offsets":[-230,230],"edge_to":[-1,9],"edge_fraction":[0,1],"cups":[0,3],"water":[0,180],"verified_patterns":[0,3]}
  if bounds.has(key):
   for entry:Variant in value:
    var tolerance:float=.000001 if key in ["angles","progress","edge_fraction"] else 0.0
    if not _number(entry,bounds[key][0]-tolerance,bounds[key][1]+tolerance):return false
 return true

static func valid_location(value:Variant)->bool:
 if not value is Dictionary or value.size()!=3:return false
 if not _integer(value.get("floor"),2,4) or not _number(value.get("hour"),0,24):return false
 var point:Variant=value.get("player")
 return point is Array and point.size()==2 and _number(point[0],-10000,10000) and _number(point[1],-10000,10000)
static func _object_shape(value:Variant,shape:Dictionary)->bool:
 if not value is Dictionary:return false
 for key:String in shape:
  if not value.has(key) or not _matches(value[key],shape[key]):return false
 return true
static func _record_valid(room:String,row:Variant)->bool:
 var shapes:Dictionary={
 "2:team":{"revision":0,"pattern":0,"screens":[0,0],"passed":false},
 "2:platform":{"clear":false,"blocked":false,"visible_corners":0,"success":false,"condition":0,"board":Vector2.ZERO,"revision":0},
 "3:recording":{"round":0,"arrived":false,"shaded":false,"passed":false,"kind":""},
 "3:xlab_north":{"revision":0,"state":"","output":false,"passed":false,"stable":false},
 "3:studio_3":{"revision":0,"dataset":0,"aligned":false,"passed":false},
 "3:seminar":{"revision":0,"cameras":0,"slots":[0,0,0,0],"tools":[0,0,0,0],"artifacts":[false,false,false,false],"errors":["","","", ""],"success":false},
 "3:xlab_south":{"revision":0,"attachment":false,"angles":[0.0,0.0],"route":0},
 "4:flex_c":{"station":0,"revision":0,"pattern":0,"valid":false,"received":[0,0,0],"outcomes":["","",""]},
 "4:seminar_1":{"a":0,"b":0,"station":0,"accepted":false,"discriminates":false,"revision":0},
 "4:collab_b":{"kind":"","passed":false,"configuration_revision":0,"fixture_revision":0,"condition":0,"camera_clear":false,"light_blocked":false}}
 if room=="4:seminar_3":room="4:collab_b"
 if shapes.has(room):return _object_shape(row,shapes[room])
 if room=="2:robotics":
  if not _object_shape(row,{"run_id":0,"cargo_id":0,"revision":0,"target":0,"outward":[],"inward":[]}):return false
  for key:String in ["outward","inward"]:
   for point:Variant in row[key]:
    if not point is Vector2:return false
  return true
 if room=="2:formula":
  if not _object_shape(row,{"scenario":0,"configuration":[0,0,0],"revision":0,"cars":[{},{}],"segments":[],"won":false}):return false
  if int(row.scenario) not in [0,1]:return false
  for i:int in 3:
   if not _integer(row.configuration[i],0,1 if i==0 else 2):return false
  for car:Variant in row.cars:
   if not _object_shape(car,{"distance":0.0,"v":0.0}):return false
  for segment:Variant in row.segments:
   if not _object_shape(segment,{"time":0.0,"player":0.0,"baseline":0.0}):return false
  return true
 return row is Dictionary
static func _contents_valid(room:String,key:String,value:Variant)->bool:
 if key in ["records","history","proofs","evidence"] and value is Array:
  # A few histories are undo poses, not trial records.
  if room=="3:xlab_box":
   for row:Variant in value:
    if not _object_shape(row,{"depths":[0,0],"heights":[0,0]}):return false
   return true
  if room=="2:robotics" and key=="history":
   for row:Variant in value:
    if not _object_shape(row,{"selector":0,"return_direction":0,"target":0}):return false
   return true
  for row:Variant in value:
   if not _record_valid(room,row):return false
 if key=="receipts":
  if value is Array:
   for row:Variant in value:
    if not _record_valid(room,row):return false
  elif value is Dictionary:
   for id:Variant in value:
    var row:Variant=value[id]
    if room=="2:team":
     if not _integer(id,0,2) or not _integer(row,0):return false
    elif room in ["4:collab_b","4:seminar_3","3:xlab_north"]:
     if not id is String or not _record_valid(room,row):return false
    else:
     if not _integer(id,0,3) or not _object_shape(row,{"revision":0,"passed":false}):return false
     if room=="4:focus_a" and not _object_shape(row,{"loads":[0,0]}):return false
 if room=="2:platform" and key=="records":
  for id:Variant in value:
   if not _integer(id,0,1) or not _record_valid(room,value[id]):return false
 if room=="2:solar_bench":
  if key=="setup" or key=="last_trial" and not value.is_empty():
   var setup:Variant=value if key=="setup" else value.get("setup")
   if not _object_shape(setup,{"panel":0,"tilt":0,"gear":0}):return false
   if not _integer(setup.panel,0,1) or not _integer(setup.tilt,0,2) or not _integer(setup.gear,0,2):return false
  if key=="last_trial" and not value.is_empty() and not _object_shape(value,{"sky":0,"distance":0.0,"reference":0.0,"trace":[]}):return false
 if room=="2:robot_delivery" and key=="last_trace":
  for point:Variant in value:
   if not point is Vector2:return false
 if room=="2:solar_bench" and key=="best":
  for sky:Variant in value:
   if not _integer(sky,0,2) or not _number(value[sky],0,10000):return false
 if room=="4:seminar_2" and key=="positions":
  for cell:Variant in value:
   if not _integer(cell,0,9):return false
 if (room in ["3:pantry","3:studio_1"] and key=="slots") or (room=="3:pantry_water" and key=="cups"):
  var seen:Dictionary={}
  for id:Variant in value:
   if not _integer(id,0,3) or seen.has(int(id)):return false
   seen[int(id)]=true
 if (room in ["4:seminar_1","4:collab_b","4:seminar_3"] and key=="slots") or (room=="4:flex_c" and key=="connections"):
  var occupied:Dictionary={}
  for id:Variant in value:
   if id>=0:
    if occupied.has(int(id)):return false
    occupied[int(id)]=true
 if room=="2:koala" and key=="chain":
  var seen:Dictionary={}
  for id:Variant in value:
   if not _integer(id,0,7) or seen.has(int(id)):return false
   seen[int(id)]=true
 if room=="2:robot_delivery" and key=="tiles":
  if value.size()!=15:return false
  for point:Variant in value:
   if not point is Vector2i or point.x<0 or point.x>4 or point.y<0 or point.y>2:return false
   if not _object_shape(value[point],{"kind":"","rotation":0}):return false
   if value[point].kind not in ["straight","corner","oneway"] or not _integer(value[point].rotation,0,3):return false
 if key in ["cables","wires"]:
  var inputs:Array=["bus_in","screen_a","screen_b"] if key=="cables" else ["split","left","right"]
  var outputs:Array=["source","live_a","live_b","cache"] if key=="cables" else ["live","cached","split_a","split_b"]
  for id:Variant in value:
   if id not in inputs or value[id] not in outputs:return false
 if room=="2:signal_bench" and key=="displayed":
  if not _object_shape(value,{"left":0,"right":0}):return false
  for id:String in ["left","right"]:
   if not _integer(value[id],-1,3):return false
 return true

static func _rule_evidence(rows:Array)->Array:
 # Earlier station-0 pairs remain exclusion evidence, even after long play.
 var result:Array=[];var seen:Dictionary={}
 var split:=maxi(0,rows.size()-64)
 for row:Dictionary in rows.slice(0,split):
  if row.get("station")==0:
   var pair:="%d:%d"%[mini(row.a,row.b),maxi(row.a,row.b)]
   if not seen.has(pair):result.append(row);seen[pair]=true
 result.append_array(rows.slice(split))
 return result
