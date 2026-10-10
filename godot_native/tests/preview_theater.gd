extends Control
## Standalone real playable scene. Three acts validate through the source model;
## no save writes or controller progress is fabricated by this visual fixture.
var game:Control
var round_id:=0
var attempt:=0
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);resized.connect(_layout);_new_act()
func _new_act()->void:
	if is_instance_valid(game):remove_child(game);game.queue_free()
	game=preload("res://scripts/games/c3_spotlight.gd").new();game.setup({"round":round_id,"attempt":attempt});add_child(game)
	game.attempt_submitted.connect(func(proof:Dictionary):
		var accepted:Dictionary=game.rules.validate(proof,round_id,attempt)
		game.resolve(accepted.get("status","")=="won",round_id==2))
	game.finished.connect(func(_result:Dictionary):
		if game.approved:round_id=(round_id+1)%3;attempt=0
		else:attempt+=1
		_new_act.call_deferred())
	_layout()
func _layout()->void:
	if not is_instance_valid(game):return
	var factor:float=minf(size.x/960,size.y/540);game.scale=Vector2.ONE*factor;game.position=(size-Vector2(960,540)*factor)*.5
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_F9:
		var dir:String=ProjectSettings.globalize_path("res://../evidence");DirAccess.make_dir_recursive_absolute(dir)
		get_viewport().get_texture().get_image().save_png(dir+"/theater-live-"+str(Time.get_ticks_msec())+".png")
