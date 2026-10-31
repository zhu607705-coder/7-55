extends Sprite2D
## A generated PNG object, not a gameplay controller. The owning view supplies
## every pose. Picking, gesture ownership, cancellation and model writes stay there.
const SETTLE_SECONDS:=0.12
const MAX_LIFT_SCALE:=1.04
var reduced_motion:=false
var manual_advance:=false
var logical_box_size:=Vector2.ZERO
var _configured:=false
var _has_pose:=false
var _base_scale:=1.0
var _target_position:=Vector2.ZERO
var _target_scale:=Vector2.ONE
var _start_position:=Vector2.ZERO
var _start_scale:=Vector2.ONE
var _elapsed:=SETTLE_SECONDS

## logical_box is a size, not a position. Region cropping retains original pixels;
## uniform containment never stretches one axis or changes the center pivot.
func configure(source:Texture2D,source_rect:Rect2,logical_box:Vector2)->bool:
 if source==null or not source_rect.position.is_finite() or not source_rect.size.is_finite() or not logical_box.is_finite():return false
 if source_rect.size.x<=0 or source_rect.size.y<=0 or logical_box.x<=0 or logical_box.y<=0:return false
 if not Rect2(Vector2.ZERO,source.get_size()).encloses(source_rect):return false
 logical_box_size=logical_box
 texture=source;region_enabled=true;region_rect=source_rect;region_filter_clip_enabled=true
 centered=true;offset=Vector2.ZERO
 _base_scale=minf(logical_box.x/source_rect.size.x,logical_box.y/source_rect.size.y)
 _configured=true;_has_pose=false;_elapsed=SETTLE_SECONDS
 scale=Vector2.ONE*_base_scale;_target_scale=scale;_start_scale=scale
 set_process(false)
 return true

## direct follows the owner's current visible hand position exactly. lift only
## changes scale about that same pivot; it never shifts the pointer anchor.
func present(at:Vector2,direct:bool=false,lift:float=0.0)->void:
 if not _configured or not at.is_finite() or not is_finite(lift):return
 var next_scale:=Vector2.ONE*_base_scale*lerpf(1.0,MAX_LIFT_SCALE,clampf(lift,0.0,1.0))
 if not _has_pose or direct or reduced_motion or not visible:
  _target_position=at;_target_scale=next_scale;_has_pose=true;_snap();return
 if at==_target_position and next_scale==_target_scale:return
 _start_position=position;_start_scale=scale
 _target_position=at;_target_scale=next_scale;_elapsed=0.0
 set_process(not manual_advance)

func set_reduced_motion(enabled:bool)->void:
 reduced_motion=enabled
 if enabled and _has_pose:_snap()

## Optional convenience for recycled pool objects. Hidden objects never resume an
## old settling animation on their next appearance.
func set_presented(enabled:bool)->void:
 visible=enabled
 if not enabled:
  if _has_pose:_snap()
  _has_pose=false
  set_process(false)

func _snap()->void:
 position=_target_position;scale=_target_scale;_elapsed=SETTLE_SECONDS
 set_process(false)

func _process(delta:float)->void:
 advance_visual(delta)

func rendered_size()->Vector2:
 return region_rect.size*scale.abs()

## Manual drivers set manual_advance=true once, then step all card bodies before
## presenting their independently contained artifact/tool sprites.
func advance_pose(delta:float)->void:
 advance_visual(delta)

## Deterministic stepping also permits focused tests without a graphical server.
func advance_visual(delta:float)->void:
 if not _has_pose or _elapsed>=SETTLE_SECONDS or not is_finite(delta) or delta<=0:return
 if reduced_motion or not visible:_snap();return
 _elapsed=minf(SETTLE_SECONDS,_elapsed+delta)
 var fraction:=_elapsed/SETTLE_SECONDS
 var eased:=1.0-pow(1.0-fraction,3.0)
 position=_start_position.lerp(_target_position,eased)
 scale=_start_scale.lerp(_target_scale,eased)
 if _elapsed>=SETTLE_SECONDS:_snap()
