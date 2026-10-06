extends Node2D
## One original Room204 table. The scene transform owns appearance, foot and pick.
## Progression and drag intents remain with the existing World/Chapter4 controller.
@export var object_id := "group_table_1"
func source_polygon(shape: CollisionShape2D) -> PackedVector2Array:
	var half: Vector2=shape.shape.size/2
	var local_points:=PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
	return transform * shape.get_parent().transform * shape.transform * local_points
func footprint() -> PackedVector2Array:
	return source_polygon($Solid/Foot)
func footprint_bounds() -> Rect2:
	var points:=footprint()
	var bounds:=Rect2(points[0],Vector2.ZERO)
	for p in points: bounds=bounds.expand(p)
	return bounds
func interaction_polygon() -> PackedVector2Array:
	return source_polygon($Interaction/Bounds)
func contains_source_point(point: Vector2) -> bool:
	var shape: CollisionShape2D=$Interaction/Bounds
	var source_transform: Transform2D=transform*shape.get_parent().transform*shape.transform
	var half: Vector2=shape.shape.size/2
	return Rect2(-half,half*2).has_point(source_transform.affine_inverse()*point)

# Presentation only. The scene root, foot and interaction area never animate.
var _held:=false
var _return_elapsed:=1.0
var _reduced:=false
var art_position:=Vector2.ZERO
var art_scale:=Vector2.ONE
var art_half:=Vector2.ZERO
func _ready() -> void:
	art_position=$OriginalAppearance.position
	art_scale=$OriginalAppearance.scale
	art_half=($OriginalAppearance.offset+$OriginalAppearance.region_rect.size/2)*art_scale
func begin_drag(reduced: bool) -> void:
	_reduced=reduced;_held=true;_return_elapsed=1.0
	_reset_appearance()
	$OriginalAppearance.modulate.a=.42
func finish_drag(settle: bool=true) -> void:
	if not _held: return
	_held=false;_return_elapsed=0.0 if settle and not _reduced else 1.0
	_reset_appearance()
func _reset_appearance() -> void:
	$OriginalAppearance.position=art_position
	$OriginalAppearance.scale=art_scale
	$OriginalAppearance.modulate=Color.WHITE
func _process(delta: float) -> void:
	advance_feedback(delta)
func advance_feedback(delta: float) -> void:
	if _held or _return_elapsed>=.24: return
	_return_elapsed=minf(.24,_return_elapsed+maxf(delta,0))
	var t:=_return_elapsed/.24
	var squash:=sin(t*TAU)*pow(1-t,2)*.075
	var factor:=Vector2(1+squash,1-squash)
	# Keep the original image centre fixed while the visual child settles.
	var half:=art_half
	$OriginalAppearance.scale=art_scale*factor
	$OriginalAppearance.position=art_position+half-half*factor
	if t>=1: _reset_appearance()
