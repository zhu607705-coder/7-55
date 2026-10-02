extends "res://scripts/world.gd"
var interactions: Array=[]
var run_controller: bool=false
func _try_interact(target: Dictionary={}) -> void:
	interactions.append(str(target.get("id","")))
	if run_controller: super._try_interact(target)
