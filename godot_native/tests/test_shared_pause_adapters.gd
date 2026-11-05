extends SceneTree
## Resource-light adapter coverage. Does not claim cropped chapters are playable.
const SCRIPTS = [
 "res://scripts/ui/minigame_host.gd", "res://scripts/ui/lake_fishing_view.gd",
 "res://scripts/games/canteen_defense.gd", "res://scripts/games/progressive_transport.gd",
 "res://scripts/games/theater_shadow_rehearsal.gd", "res://scripts/games/c3_spotlight.gd",
 "res://scripts/games/c3_weather.gd", "res://scripts/presentation/chapter4_folded_chase_view.gd",
 "res://scripts/presentation/chapter4_endless_stair_view.gd", "res://scripts/presentation/chase_transition_clock.gd",
 "res://scripts/presentation/chase_transition_3d_presenter.gd", "res://scripts/presentation/liangzhu_performance.gd"
]
var failures := 0
var weather_exits := 0
var transport_help_requests := 0
func check(value: bool, message: String) -> void:
 if value: print("PASS: ", message)
 else: failures += 1; push_error(message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 for path: String in SCRIPTS:
  var script = load(path)
  check(script != null and script.can_instantiate(), "Adapter script compiles: " + path)
 # Policy/clock units use real models and minimal controls; cropped artwork
 # is not substituted and this does not claim a rendered later-game pass.
 var host=load("res://scripts/ui/minigame_host.gd").new()
 host.mode="kayak";host.model=load("res://scripts/games/kayak_model.gd").new()
 host.start_button=Button.new();host.pause_button=Button.new();host.add_child(host.start_button);host.add_child(host.pause_button)
 check(not host.supports_player_pause(), "Minigame intro does not offer player pause")
 host.running=true;host._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(host.paused and host.supports_player_pause(), "Live minigame still pauses on focus loss")
 host._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(host.paused, "Live minigame still requires explicit Continue")
 host.toggle_pause();host.model.status="lost"
 host._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);host._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(not host.paused and not host.supports_player_pause(), "Minigame result has no focus pause latch")
 host.free()
 var canteen=load("res://scripts/games/canteen_defense.gd").new()
 canteen.model=load("res://scripts/games/canteen_defense_model.gd").new()
 canteen.start_button=Button.new();canteen.add_child(canteen.start_button)
 canteen._pickup_active=true;canteen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);canteen._process(3600)
 check(not canteen.paused and canteen._pickup_elapsed==0 and not canteen.supports_player_pause(), "Pickup movie freezes silently in background")
 canteen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN);canteen._process(3600)
 check(canteen._pickup_elapsed==0, "Pickup movie drops return frame delta")
 canteen._process(.01);check(canteen._pickup_elapsed==10,"Pickup movie automatically resumes next ordinary frame")
 canteen._pickup_active=false;canteen.running=true;canteen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(canteen.paused and canteen.supports_player_pause(), "Canteen live interception retains player pause")
 canteen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN);check(canteen.paused,"Canteen live focus return retains explicit Continue")
 canteen.toggle_pause();canteen.sent=true;canteen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);canteen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(not canteen.paused and not canteen.supports_player_pause(), "Canteen terminal receipt has no player pause latch")
 canteen.free()
 var weather = load("res://scripts/games/c3_weather.gd").new()
 root.add_child(weather)
 weather.set_process(false)
 weather.started=true; weather._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(weather.shared_pause_overlay.is_open(), "Weather pause uses shared overlay")
 check(not weather.start_button.visible, "Weather legacy resume is hidden")
 weather.shared_pause_overlay.resume_button.pressed.emit()
 check(not weather.paused and not weather.shared_pause_overlay.is_open(), "Weather shared continue preserves existing resume state")
 weather.cancelled.connect(func(): weather_exits += 1)
 weather._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(weather.shared_pause_overlay.action_buttons.size()==1 and weather.shared_pause_overlay.action_buttons[0].text==weather.exit_button.text, "Weather retains its authored exit action")
 weather.exit_button.disabled=true; weather._sync_shared_pause()
 check(weather.shared_pause_overlay.action_buttons[0].disabled, "Secondary action mirrors authored disabled state")
 weather.shared_pause_overlay.action_buttons[0].pressed.emit()
 check(weather_exits==0, "Disabled secondary action cannot bypass authored guard")
 weather.exit_button.disabled=false; weather._sync_shared_pause()
 weather.shared_pause_overlay.action_buttons[0].pressed.emit()
 check(weather_exits==1, "Secondary exit follows original cancelled signal")
 weather.paused=true; weather.hide(); weather._sync_shared_pause()
 check(not weather.shared_pause_overlay.is_open(), "Hidden weather owner has no root overlay")
 var weather_overlay = weakref(weather.shared_pause_overlay)
 weather.queue_free()
 await process_frame
 await process_frame
 check(weather_overlay.get_ref()==null, "Overlay is removed with owner")
 var transport = load("res://scripts/games/progressive_transport.gd").new()
 root.add_child(transport)
 transport.set_process(false)
 transport._focus_out()
 check(not transport.controls.has("TransportPause"), "Turn-based transport has no pause entry")
 check(not transport.reading_panel.visible, "Focus loss does not invent a reading/pause panel")
 transport.help_open=true;transport._update_reading();transport._focus_out()
 check(transport.help_open and transport.reading_panel.visible, "Focus loss preserves the user's actual help sheet")
 transport.reading_close.pressed.emit()
 check(not transport.help_open and not transport.reading_panel.visible, "Original close reading remains reachable")
 check(transport.controls.has_all(["TransportRestart","TransportUndo","TransportHelp","TransportExit"]), "Turn-based original actions remain present")
 transport.queue_free()
 await process_frame
 await process_frame
 # Chapter 3 stage media is intentionally cropped. Test the real lifecycle
 # method without building a missing stage; this is not a scene/render pass.
 var rehearsal = load("res://scripts/games/theater_shadow_rehearsal.gd").new()
 rehearsal.setup({});rehearsal._focus_out()
 check(not rehearsal.menu_open and not rehearsal.help_open, "Rehearsal focus loss does not invent a menu")
 rehearsal.menu_open=true;rehearsal._focus_out()
 check(rehearsal.menu_open, "Explicit rehearsal menu state survives focus loss")
 var rehearsal_source=FileAccess.get_file_as_string("res://scripts/games/theater_shadow_rehearsal.gd")
 check(not rehearsal_source.contains("RehearsalMenuPause") and not rehearsal_source.contains("SharedPauseOverlay"), "Rehearsal source has no pause entry or surface")
 check(rehearsal_source.contains("RehearsalMenuUndo") and rehearsal_source.contains("RehearsalMenuRestart") and rehearsal_source.contains("RehearsalMenuExit"), "Rehearsal retains authored action factories")
 rehearsal.free()
 var performance=load("res://scripts/presentation/liangzhu_performance.gd").new()
 performance.model=load("res://scripts/presentation/liangzhu_performance_model.gd").new(false,"passive")
 check(not performance.supports_player_pause(), "Passive performance is not a pausable minigame")
 performance._focus_out();performance._focus_in()
 check(not performance.model.focus_paused, "Passive performance focus resumes automatically")
 var context={"runtimeMode":"rpg","rpgScene":"theater_interior","native":{"scene":"theater_interior","settings":{}},"theaterHunt":{"active":true,"admitted":true}}
 performance.bound_state=context;performance.bound_context=performance._context(context);performance.read_state=func():return context
 performance.tick(3600,true)
 check(performance.model.elapsed_ms==0,"Passive return discards accumulated background delta")
 performance.tick(.1,true)
 check(performance.model.elapsed_ms==100,"Passive presentation clock resumes on the next ordinary tick")
 performance._toggle_pause();check(not performance.model.manually_paused, "Passive performance has no keyboard pause latch")
 performance.model=load("res://scripts/presentation/liangzhu_performance_model.gd").new(false,"interactive")
 performance._focus_out();performance._focus_in()
 check(performance.supports_player_pause() and performance.model.focus_paused, "Live performance still awaits explicit Continue")
 performance.model.status="failure";performance._focus_in()
 check(not performance.supports_player_pause() and not performance.model.focus_paused, "Failed performance retry screen has no focus pause latch")
 performance.free()
 var film = load("res://scripts/presentation/chase_transition_clock.gd").new()
 root.add_child(film)
 film.set_process(false); film.manual_clock=true; film.play("start")
 film.advance(.1)
 var before: float=film.elapsed
 film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(film.find_children("*","Button",true,false).size()==2, "Noninteractive transition has only original skip and exit")
 film.advance(.1)
 check(film.elapsed==before, "Transition lifecycle clock stays frozen")
 film._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 film.advance(3600);check(film.elapsed==before, "Transition discards first background delta")
 film.advance(.1)
 check(not film.paused and film.elapsed>before, "Transition returns automatically without a pause panel")
 film.skip_button.pressed.emit()
 check(film.status=="complete" and film.skipped, "Transition original skip retains completion path")
 film.play("start");film.exit_button.pressed.emit()
 check(film.status=="cancelled", "Transition original exit retains cancellation path")
 film.queue_free()
 await process_frame
 await process_frame
 print("SHARED_PAUSE_ADAPTER_FAILURES=",failures)
 quit(1 if failures else 0)
