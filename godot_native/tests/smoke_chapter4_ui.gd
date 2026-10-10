extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
const Stairs=preload("res://scripts/games/chapter4_stairs.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var holder: Control=Control.new(); holder.size=Vector2(960,700); root.add_child(holder)
	var timeline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-temporal-maze.content.json")).elevator.timeline
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-native-source.json"))
	var stairs: Control=Stairs.new(); holder.add_child(stairs); stairs.setup({"session":"test"}); await process_frame; await process_frame; print("STAIRS_UI_BUILT ",stairs.level.id)
	await create_timer(1.2).timeout
	for index in range(1,4):
		stairs.level_index=index; stairs._load_level(); await process_frame; await process_frame; print("STAIRS_UI_BUILT ",stairs.level.id); await create_timer(1.2).timeout
	stairs.queue_free(); await process_frame
	for kind in ["star_lamp_closure","chase_stairwell","elevator_alignment","prologue"]:
		var game: Control=Activity.new(); holder.add_child(game)
		var config: Dictionary={"kind":kind,"session":"test","questions":source.questions,"timeline":timeline,"video":"res://assets/rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition.ogv"}
		game.setup(config); await process_frame; await process_frame; print("ACTIVITY_UI_BUILT ",kind); game.queue_free(); await process_frame
	holder.queue_free(); await process_frame; await create_timer(0.3).timeout; quit()
