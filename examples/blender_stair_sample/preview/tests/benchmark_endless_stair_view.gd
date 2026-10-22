extends "res://scripts/presentation/chapter4_endless_stair_view.gd"
var present_usec: Array[float] = []
var physics_usec: Array[float] = []
func _present(delta: float) -> void:
	var started:=Time.get_ticks_usec()
	super._present(delta)
	if model.tick>=120: present_usec.append(float(Time.get_ticks_usec()-started))
func _physics_process(delta: float) -> void:
	var started:=Time.get_ticks_usec()
	super._physics_process(delta)
	if model.tick>=120: physics_usec.append(float(Time.get_ticks_usec()-started))
var reveal_usec: Array[float]=[]
var broadphase_usec: Array[float]=[]
var beam_usec: Array[float]=[]
func _update_stage_reveal(delta:float)->void:
	var started:=Time.get_ticks_usec()
	super._update_stage_reveal(delta)
	if model.tick>=120:reveal_usec.append(float(Time.get_ticks_usec()-started))
func _update_near_blockers()->void:
	var started:=Time.get_ticks_usec()
	super._update_near_blockers()
	if model.tick>=120:broadphase_usec.append(float(Time.get_ticks_usec()-started))
func _update_beam_path()->void:
	var started:=Time.get_ticks_usec()
	super._update_beam_path()
	if model.tick>=120:beam_usec.append(float(Time.get_ticks_usec()-started))
