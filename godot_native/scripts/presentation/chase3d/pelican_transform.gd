extends Control
## Original paper-feather choreography. Driven only by the transition source frame.
## No timers, sound requirement, story flags, saves or controller callbacks.
var phase: float=-1
var center:=Vector2.ZERO
var radius: float=70
var student: Sprite3D
var bird: Node3D
var student_frames: Array[Texture2D]=[]

func configure(viewport3d: SubViewport,avatar: Node3D) -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	bird=avatar
	student=Sprite3D.new();student.name="OriginalPixelProtagonist"
	for frame: int in range(8):student_frames.append(load("res://assets/rpg/player/player_side_%d.png"%frame))
	student.texture=student_frames[0]
	student.pixel_size=.025;student.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	student.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	student.shaded=false;student.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	viewport3d.add_child(student)

func update_pose(stage: String,source_at: float,camera: Camera3D,reduced: bool,joints: Dictionary={}) -> void:
	# The full feather veil at the midpoint conceals the form switch.
	var transforming: bool=false;var becoming_bird: bool=stage=="start"
	if stage=="start":phase=clampf(inverse_lerp(1,10,source_at),0,1);transforming=source_at>=1 and source_at<=10
	else:phase=clampf(inverse_lerp(112,122,source_at),0,1);transforming=source_at>=112 and source_at<=122
	var show_bird: bool=phase>=.5 if becoming_bird else phase<.5
	bird.visible=show_bird
	student.visible=not show_bird
	var hips: Vector3=bird.to_global(bird.joint_point("Hips"))
	student.position=Vector3(hips.x,1.48,hips.z)
	student.flip_h=stage=="finish"
	student.texture=student_frames[int(fposmod(float(joints.get("walk_phase",0)),1)*8)] if float(joints.get("walk_weight",0))>.01 and not reduced else student_frames[0]
	center=camera.unproject_position(Vector3(hips.x,1.8,hips.z))
	radius=clampf(center.distance_to(camera.unproject_position(Vector3(hips.x,3.25,hips.z))),40,170)
	visible=transforming and not reduced
	queue_redraw()

func _draw() -> void:
	if phase<=0 or phase>=1:return
	var cover: float=sin(PI*phase)
	# Discrete feather clusters retain a crisp silhouette at native film resolution.
	for i: int in range(24):
		var angle: float=i*2.39996+phase*TAU*1.2
		var distance: float=radius*(.12+(1-cover)*1.4)*(.45+float(i%5)*.14)
		var p: Vector2=(center+Vector2(cos(angle),sin(angle)) * distance).round()
		p+=Vector2(((i%3)-1)*radius*.23,((i%8)/7.0-.5)*radius*1.7)*cover
		var length: float=radius*(.30+cover*.22)*(1+float(i%3)*.12)
		var axis:=Vector2(cos(angle+.8),sin(angle+.8));var across:=axis.orthogonal()
		var points:=PackedVector2Array([p-axis*length*.55,p-axis*length*.2+across*length*.20,p+axis*length*.35+across*length*.12,p+axis*length*.58,p+axis*length*.15-across*length*.18,p-axis*length*.25-across*length*.13])
		for n: int in range(points.size()):points[n]=points[n].round()
		draw_colored_polygon(points,Color("F4EAD5") if i%4 else Color("D8C7A0"))
		draw_line((p-axis*length*.35).round(),(p+axis*length*.35).round(),Color("C5C1A9"),1,false)
