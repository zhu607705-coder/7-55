extends Control
signal completed(result: Dictionary)
signal cancelled
const Model = preload("res://scripts/games/chapter4_stair_model.gd")
const Assets = preload("res://scripts/games/chapter4_stair_assets.gd")
const PANEL_BACKGROUND := Color("121b29")
const PANEL_FOREGROUND := Color("e7f0ff")
var config: Dictionary = {}
var source: Dictionary = {}
var level: Dictionary = {}
var state: Dictionary = {}
var campaign: Array = []
var actions_log: Array = []
var level_index: int = 0
var view3d: SubViewport
var root3d: Node3D
var camera: Camera3D
var actor: Sprite3D
var surface: TextureRect
var caption: Label
var toolbar: GridContainer
var mechanism_nodes: Dictionary = {}
var busy: bool = false
var built: bool = false
var materials: Dictionary={}
var surface_textures: Dictionary={}
var frames: Dictionary={}
var walking: bool=false
var walk_ms: float=0
var facing: String="down"
var facing_left: bool=false
# Facing is a world-space intent, not the billboard plane or current camera.
var facing_world: Vector3=Vector3.BACK
var door_group: Node3D
var seam_overlay: Control
var reveal_done: bool=false
var door_panel: MeshInstance3D
var door_hinge: Node3D
var refined_assets: bool=false
func setup(value: Dictionary) -> void:
	config=value
	if is_inside_tree(): _build()
func _ready() -> void:
	if not config.is_empty(): _build()
func _build() -> void:
	if built: return
	built=true
	source=Model.data()
	_load_materials()
	_load_player()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size=Vector2(960,540)
	var bg: ColorRect=ColorRect.new(); bg.color=PANEL_BACKGROUND; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var box: VBoxContainer=VBoxContainer.new(); box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(box)
	caption=Label.new(); caption.add_theme_color_override("font_color",PANEL_FOREGROUND); caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; caption.custom_minimum_size.y=54; box.add_child(caption)
	var views: HBoxContainer=HBoxContainer.new(); box.add_child(views)
	for i in range(3):
		var b: Button=Button.new(); b.text=["东南视角","西南视角","上方视角"][i]; b.pressed.connect(_change_view.bind(Model.VIEWS[i])); views.add_child(b)
	var reset: Button=Button.new(); reset.text="重置本关"; reset.pressed.connect(_load_level); views.add_child(reset)
	var back: Button=Button.new(); back.text="返回"; back.pressed.connect(func(): cancelled.emit()); views.add_child(back)
	view3d=SubViewport.new(); view3d.size=Vector2i(960,540); view3d.own_world_3d=true; view3d.render_target_update_mode=SubViewport.UPDATE_ALWAYS; add_child(view3d)
	surface=TextureRect.new(); surface.texture=view3d.get_texture(); surface.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; surface.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; surface.size_flags_vertical=Control.SIZE_EXPAND_FILL; surface.custom_minimum_size=Vector2(480,270); surface.gui_input.connect(_click_surface); box.add_child(surface)
	seam_overlay=Control.new(); seam_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE; seam_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); seam_overlay.draw.connect(_draw_seams); surface.add_child(seam_overlay)
	toolbar=GridContainer.new(); toolbar.columns=2; toolbar.custom_minimum_size.y=96; box.add_child(toolbar)
	_load_level()
func _load_level() -> void:
	if busy: return
	reveal_done=false
	level=source.levels[level_index]; state=Model.initial(level); actions_log=[]
	for child in view3d.get_children(): child.queue_free()
	for child in toolbar.get_children(): child.queue_free()
	mechanism_nodes={}
	door_group=null; door_panel=null; door_hinge=null
	refined_assets=level.id=="stair_b" and Assets.available()
	root3d=Node3D.new(); view3d.add_child(root3d)
	var env: WorldEnvironment=WorldEnvironment.new(); var environment: Environment=Environment.new(); environment.background_mode=Environment.BG_COLOR; environment.background_color=Color("121b29"); environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; environment.ambient_light_color=Color("a6bcdb"); environment.ambient_light_energy=0.75; env.environment=environment; root3d.add_child(env)
	var sun: DirectionalLight3D=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-40,-30,0); sun.light_energy=1.25; root3d.add_child(sun)
	camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=float(source.cameras[level.id].halfHeight)*2; camera.near=0.1; camera.far=100; root3d.add_child(camera); camera.current=true
	for m in level.mechanisms:
		var node: Node3D=Node3D.new(); root3d.add_child(node); mechanism_nodes[m.id]=node
		var row: HBoxContainer=HBoxContainer.new(); row.custom_minimum_size.x=400; toolbar.add_child(row)
		var label: Label=Label.new(); label.text=m.label; label.add_theme_color_override("font_color",PANEL_FOREGROUND); label.custom_minimum_size.x=180; row.add_child(label)
		for delta in [-1,1]:
			var b: Button=Button.new(); b.text=("逆转" if delta<0 else "顺转") if m.kind=="rotate" else (("下移" if delta<0 else "上移") if m.kind=="vertical" else ("左移" if delta<0 else "右移")); b.pressed.connect(_step.bind(m.id,delta)); row.add_child(b)
	for p in level.geometry.platforms:
		var asset_id: String=str(p.id) if p.ownerId=="level" else str(p.ownerId)
		if refined_assets and Assets.FILES.has(asset_id):
			_owner(p.ownerId).add_child(Assets.instantiate(asset_id)); continue
		_box(p.ownerId,Model.v3(p.center),Model.v3(p.size),p.material)
	for stairs in level.geometry.stairs:
		if refined_assets and Assets.FILES.has(stairs.ownerId):
			_owner(stairs.ownerId).add_child(Assets.instantiate(stairs.ownerId)); continue
		var start: Vector3=Model.v3(stairs.from); var finish: Vector3=Model.v3(stairs.to); var direction: Vector3=(finish-start); direction.y=0
		var count: int=int(stairs.steps)
		for i in range(count):
			var t: float=(float(i)+0.5)/count
			var center: Vector3=start.lerp(finish,t)
			var mesh: MeshInstance3D=_box(stairs.ownerId,center-Vector3(0,0.13,0),Vector3(direction.length()/count+0.07,0.26,float(stairs.width)),stairs.material)
			mesh.rotation.y=-atan2(direction.z,direction.x)
			var nosing: MeshInstance3D=_box(stairs.ownerId,Vector3.ZERO,Vector3(0.055,0.025,float(stairs.width)-0.08),"wall_lit"); nosing.reparent(mesh,false); nosing.position=Vector3(direction.length()/count/2-0.03,0.142,0)
		var run: Vector3=finish-start
		for side in [-1,1]:
			var offset: Vector3=Vector3(-run.z,0,run.x).normalized()*side*(float(stairs.width)/2-0.04)
			var beam: MeshInstance3D=_box(stairs.ownerId,start.lerp(finish,0.5)+offset-Vector3(0,0.24,0),Vector3(run.length(),0.14,0.09),"structure"); beam.quaternion=Quaternion(Vector3.RIGHT,run.normalized())
			for post_index in range(4): _box(stairs.ownerId,start.lerp(finish,0.12+post_index*0.25)+offset+Vector3(0,0.34,0),Vector3(0.045,0.68,0.045),"structure")
			var rail: MeshInstance3D=_box(stairs.ownerId,start.lerp(finish,0.495)+offset+Vector3(0,0.7,0),Vector3(run.length()*0.78,0.055,0.055),"structure"); rail.quaternion=beam.quaternion
	for n in level.nodes:
		var marker: MeshInstance3D=MeshInstance3D.new(); var sphere: SphereMesh=SphereMesh.new(); sphere.radius=0.10; sphere.height=0.2; marker.mesh=sphere; marker.position=Model.v3(n.position)+Vector3(0,0.08,0); marker.material_override=_mat(Color("d2b766")); _owner(n.ownerId).add_child(marker)
	for decoration in level.geometry.decorations: _decoration(decoration)
	actor=Sprite3D.new(); actor.billboard=BaseMaterial3D.BILLBOARD_ENABLED; actor.pixel_size=1.75/128.0; actor.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST; actor.no_depth_test=false; actor.shaded=false; actor.texture=frames.get("down_0"); root3d.add_child(actor)
	_update()
	_reveal_level.call_deferred()
func _mat(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D=StandardMaterial3D.new(); material.albedo_color=color; material.roughness=0.95; material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; return material
func _owner(id: String) -> Node3D:
	return root3d if id=="level" else mechanism_nodes[id]
func _box(owner: String,center: Vector3,dimensions: Vector3,kind: String) -> MeshInstance3D:
	var mesh: MeshInstance3D=MeshInstance3D.new(); var box: BoxMesh=BoxMesh.new(); box.size=dimensions; mesh.mesh=_box_uv(box,dimensions); mesh.position=center; mesh.material_override=materials.get(kind,_mat(Color("7d908e"))); _owner(owner).add_child(mesh)
	var lines: ImmediateMesh=ImmediateMesh.new(); lines.surface_begin(Mesh.PRIMITIVE_LINES,_mat(Color("17252d")))
	var half: Vector3=dimensions/2
	var vertices: Array=[]
	for x in [-1,1]:
		for y in [-1,1]:
			for z in [-1,1]: vertices.append(Vector3(x*half.x,y*half.y,z*half.z))
	for pair in [[0,1],[0,2],[0,4],[1,3],[1,5],[2,3],[2,6],[3,7],[4,5],[4,6],[5,7],[6,7]]:
		lines.surface_add_vertex(vertices[pair[0]]); lines.surface_add_vertex(vertices[pair[1]])
	lines.surface_end(); var outline: MeshInstance3D=MeshInstance3D.new(); outline.mesh=lines; mesh.add_child(outline)
	return mesh
func _box_uv(box: BoxMesh,dimensions: Vector3) -> ArrayMesh:
	var arrays: Array=box.get_mesh_arrays(); var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]; var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	for i in range(uvs.size()):
		var n: Vector3=normals[i]; var dimensions_uv: Vector2=Vector2(dimensions.z,dimensions.y) if absf(n.x)>0.5 else (Vector2(dimensions.x,dimensions.z) if absf(n.y)>0.5 else Vector2(dimensions.x,dimensions.y))
		uvs[i]*=dimensions_uv/2.4
	arrays[Mesh.ARRAY_TEX_UV]=uvs; var mesh: ArrayMesh=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays); return mesh
func _decoration(spec: Dictionary) -> void:
	if refined_assets and spec.kind=="fire_door":
		var asset: Node3D=Assets.instantiate(spec.id); root3d.add_child(asset)
		door_group=asset.find_child("b_deco_fire_door_base",true,false)
		door_hinge=asset.find_child("b_deco_fire_door_hinge",true,false)
		return
	var group: Node3D=Node3D.new(); group.position=Model.v3(spec.position); group.rotation.y=float(spec.get("rotationY",0)); root3d.add_child(group); mechanism_nodes[spec.id]=group
	match spec.kind:
		"fire_door":
			door_group=group
			_box(spec.id,Vector3(-0.74,1.15,0),Vector3(0.22,2.3,0.34),"outline"); _box(spec.id,Vector3(0.74,1.15,0),Vector3(0.22,2.3,0.34),"outline"); _box(spec.id,Vector3(0,2.3,0),Vector3(1.7,0.24,0.36),"outline")
			door_panel=_box(spec.id,Vector3(0,1.03,0),Vector3(1.24,2.06,0.14),"wall_side")
			var stripe: MeshInstance3D=_box(spec.id,Vector3.ZERO,Vector3(1.24,0.18,0.16),"warn"); stripe.reparent(door_panel,false); stripe.position=Vector3(0,0.34,0)
		"floor_plate":
			_box(spec.id,Vector3.ZERO,Vector3(1.05,0.72,0.08),"structure"); _box(spec.id,Vector3(0,0,0.04),Vector3(0.85,0.52,0.04),"wall_lit"); _box(spec.id,Vector3(-0.26,0,0.05),Vector3(0.2,0.2,0.05),"warn")
		"wall_lamp":
			_box(spec.id,Vector3.ZERO,Vector3(0.16,0.3,0.12),"outline"); _box(spec.id,Vector3(0,0.24,0.04),Vector3(0.34,0.2,0.14),"wall_lit")
		"window_frame":
			_box(spec.id,Vector3.ZERO,Vector3(1.3,1.6,0.1),"structure"); _box(spec.id,Vector3(0,0,0.03),Vector3(1.06,1.36,0.06),"night_glass"); _box(spec.id,Vector3(0,0,0.06),Vector3(0.08,1.36,0.08),"structure"); _box(spec.id,Vector3(0,0,0.06),Vector3(1.06,0.08,0.08),"structure")
		"potted_plant":
			var pot: MeshInstance3D=MeshInstance3D.new(); var cylinder: CylinderMesh=CylinderMesh.new(); cylinder.top_radius=0.2; cylinder.bottom_radius=0.26; cylinder.height=0.3; cylinder.radial_segments=16; pot.mesh=cylinder; pot.material_override=materials.warn; pot.position.y=0.15; group.add_child(pot)
			var foliage: MeshInstance3D=MeshInstance3D.new(); var sphere: SphereMesh=SphereMesh.new(); sphere.radius=0.3; sphere.height=0.6; sphere.radial_segments=8; sphere.rings=4; foliage.mesh=sphere; foliage.position.y=0.52; foliage.material_override=materials.stone_back; group.add_child(foliage)
func _load_materials() -> void:
	var files: Dictionary={"plaster":"Plaster001_1K-JPG_Color.jpg","concrete":"Concrete010_1K-JPG_Color.jpg","metal":"Metal012_1K-JPG_Color.jpg"}
	for family in files:
		var path: String="res://assets/rpg/chapter4-stair/materials/"+files[family]
		if not ResourceLoader.exists(path): continue
		var original: Texture2D=load(path); var image: Image=original.get_image()
		if image.is_compressed(): image.decompress()
		image.resize(256,256,Image.INTERPOLATE_BILINEAR)
		var mean: float=0
		for y in range(256):
			for x in range(256):
				var pixel: Color=image.get_pixel(x,y); mean+=(pixel.r*0.2126+pixel.g*0.7152+pixel.b*0.0722)*255
		mean/=65536.0
		var contrast: float=1.0 if family=="plaster" else (2.2 if family=="concrete" else 2.1)
		var center: float=252.0 if family=="plaster" else 204.0
		for y in range(256):
			for x in range(256):
				var pixel: Color=image.get_pixel(x,y); var luminance: float=(pixel.r*0.2126+pixel.g*0.7152+pixel.b*0.0722)*255
				var normalized: float=clampf(center+(luminance-mean)*contrast,132,255)
				var quantized: float=clampf(round(normalized/4)*4,248,255) if family=="plaster" else round(normalized/51)*51
				image.set_pixel(x,y,Color(quantized/255,quantized/255,quantized/255,pixel.a))
		image.generate_mipmaps(); surface_textures[family]=ImageTexture.create_from_image(image)
	var palette: Dictionary={"wall_lit":"e7d9b9","wall_side":"bfaf91","stone_lit":"cbd4cb","stone_back":"7d908e","structure":"31444b","outline":"17252d","night_glass":"173c5a","warn":"d89262"}
	for key in palette:
		var material: StandardMaterial3D=_mat(Color(palette[key])); var family: String={"wall_lit":"plaster","wall_side":"plaster","stone_lit":"concrete","stone_back":"concrete","structure":"metal"}.get(key,"")
		if surface_textures.has(family): material.albedo_texture=surface_textures[family]; material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		materials[key]=material
func _load_player() -> void:
	for direction in ["up","down","side"]:
		for index in range(8):
			var path: String="res://assets/rpg/player/player_%s_%d.png"%[direction,index]
			if ResourceLoader.exists(path): frames[direction+"_"+str(index)]=load(path)
	var path: String="res://assets/rpg/player/player_side_idle.png"
	if ResourceLoader.exists(path): frames.side_idle=load(path)
func _process(delta: float) -> void:
	if not actor: return
	_sync_actor_facing()
	if walking: walk_ms+=delta*1000
	var key: String=facing+"_"+str(int(fmod(walk_ms,880)/110)) if walking else ("side_idle" if facing=="side" else facing+"_0")
	actor.texture=frames.get(key,frames.get("down_0")); actor.flip_h=facing=="side" and facing_left
	if seam_overlay: seam_overlay.queue_redraw()

static func facing_for_heading(heading: Vector3,view_basis: Basis) -> Dictionary:
	var right: Vector3=view_basis.x;right.y=0;right=right.normalized()
	var away: Vector3=-view_basis.z;away.y=0;away=away.normalized()
	var horizontal: float=heading.dot(right)
	var depth: float=heading.dot(away)
	return {"facing":"side" if absf(horizontal)>absf(depth) else ("up" if depth>0 else "down"),"left":horizontal<0}

func _sync_actor_facing() -> void:
	if not is_instance_valid(camera):return
	var direction: Dictionary=facing_for_heading(facing_world,camera.global_transform.basis)
	facing=str(direction.facing);facing_left=bool(direction.left)

func _update() -> void:
	var spec: Dictionary=source.cameras[level.id]; camera.position=Model.v3(spec.views[state.view].position); camera.look_at(Model.v3(spec.center))
	for m in level.mechanisms:
		var node: Node3D=mechanism_nodes[m.id]
		node.transform=Assets.mechanism_transform(m,float(state.values[m.id]))
	actor.position=Model.position(level,state,state.node)+Vector3(0,0.875,0)
	caption.text="%d / 4 · %s\n%s"%[level_index+1,level.title,level.feedback.objective]
func _draw_seams() -> void:
	if busy or level.is_empty(): return
	var scale_factor: float=minf(surface.size.x/480.0,surface.size.y/270.0); var origin: Vector2=(surface.size-Vector2(480,270)*scale_factor)*0.5
	for edge in Model.edges(level,state,source.cameras[level.id],true):
		if edge.kind!="perspective": continue
		var a: Vector2=origin+Model.project(Model.position(level,state,edge.a),source.cameras[level.id],state.view)*scale_factor
		var b: Vector2=origin+Model.project(Model.position(level,state,edge.b),source.cameras[level.id],state.view)*scale_factor
		var color: Color=Color("5fe2c2") if edge.valid else Color("d89262")
		if edge.valid: seam_overlay.draw_line(a-Vector2(5,0),b+Vector2(5,0),color,2)
		else:
			seam_overlay.draw_line(a-Vector2(5,0),a-Vector2(1,0),color,2); seam_overlay.draw_line(b+Vector2(1,0),b+Vector2(5,0),color,2)
func _change_view(view: String) -> void:
	if busy: return
	var action: Dictionary={"type":"view","value":view}
	if Model.apply(level,state,source.cameras[level.id],action):
		actions_log.append(action)
		var before: Vector3=camera.position
		_update()
		var after: Vector3=camera.position
		camera.position=before; camera.look_at(Model.v3(source.cameras[level.id].center)); busy=true
		var tween: Tween=create_tween()
		tween.tween_method(func(t): camera.position=before.lerp(after,t); camera.look_at(Model.v3(source.cameras[level.id].center)),0.0,1.0,0.48)
		await tween.finished
		busy=false
func _apply_mechanism_frame(id: String,start_value: int,delta: int,t: float) -> void:
	for spec in level.mechanisms:
		if spec.id!=id: continue
		var value: float=float(start_value)+delta*t
		# Linear mechanisms wrap between legal endpoints, never past their bounds.
		if spec.kind!="rotate": value=lerpf(float(start_value),float(posmod(start_value+delta,int(spec.stateCount))),t)
		var transform_at: Transform3D=Assets.mechanism_transform(spec,value)
		mechanism_nodes[id].transform=transform_at
		# Keep the rider at its source-local station throughout the real pivot arc.
		for n in level.nodes:
			if n.id==state.node and n.ownerId==id:
				actor.position=transform_at*Model.v3(n.position)+Vector3(0,0.875,0)
		return
func _step(id: String,delta: int) -> void:
	if busy: return
	var start_value: int=int(state.values.get(id,0))
	var action: Dictionary={"type":"step","id":id,"delta":delta}
	if Model.apply(level,state,source.cameras[level.id],action):
		actions_log.append(action)
		busy=true
		var tween: Tween=create_tween()
		# Use the requested signed quarter-turn, including 3→0 and 0→3 wraps.
		# Interpolating matrix origins would move the external pivot off its axis.
		tween.tween_method(func(t): _apply_mechanism_frame(id,start_value,delta,t),0.0,1.0,0.48)
		await tween.finished
		_update()
		busy=false
func _click_surface(event: InputEvent) -> void:
	if busy or not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
	var scale_factor: float=minf(surface.size.x/960.0,surface.size.y/540.0)
	var origin: Vector2=(surface.size-Vector2(960,540)*scale_factor)*0.5
	var point: Vector2=(event.position-origin)/scale_factor*0.5
	var best: String=""; var distance: float=22.0
	for n in level.nodes:
		if n.id==state.node: continue
		var p: Vector2=Model.project(Model.position(level,state,n.id),source.cameras[level.id],state.view)
		var current: float=p.distance_to(point)
		if current<distance: distance=current; best=n.id
	if not best.is_empty(): _walk(best)
func _walk(target: String) -> void:
	if busy or target==state.node: return
	var route: Array=Model.path(level,state,source.cameras[level.id],target)
	if route.is_empty(): caption.text=level.feedback.blocked; return
	busy=true; walking=true; walk_ms=0
	for next in route:
		var end: Vector3=Model.position(level,state,next)+Vector3(0,0.875,0)
		var movement: Vector3=end-actor.position
		movement.y=0
		if movement.length_squared()>.00001:facing_world=movement.normalized()
		_sync_actor_facing()
		var tween: Tween=create_tween(); tween.tween_property(actor,"position",end,clampf(actor.position.distance_to(end)*0.16,0.2,0.8)); await tween.finished
	state.node=target; actions_log.append({"type":"walk","node":target}); busy=false; walking=false; _update()
	if target==level.exitNodeId:
		busy=true
		caption.text="通路已接通。"
		var door_tween: Tween=create_tween()
		if is_instance_valid(door_hinge): door_tween.tween_property(door_hinge,"rotation:y",PI/2,0.36)
		else: door_tween.tween_property(door_panel,"position:x",1.32,0.36)
		await door_tween.finished
		var door_origin: Vector3=root3d.to_local(door_group.global_position)
		var direction: Vector3=(door_origin-Model.position(level,state,level.exitNodeId)); direction.y=0
		if direction.length_squared()>.00001:facing_world=direction.normalized()
		_sync_actor_facing()
		var exit_tween: Tween=create_tween(); exit_tween.tween_property(actor,"position",door_origin+direction.normalized()*0.6+Vector3(0,0.875,0),0.6); await exit_tween.finished
		campaign.append({"id":level.id,"actions":actions_log.duplicate(true)})
		if level_index==3: completed.emit({"kind":"chapter4_stair_campaign","session":config.get("session",""),"levels":campaign,"doorTraversed":true}); return
		await _break_level()
		level_index+=1; busy=false; _load_level()
func _reveal_level() -> void:
	busy=true
	var tween: Tween=create_tween(); tween.set_parallel(true)
	var index: int=0
	for child in root3d.get_children():
		if not child is Node3D or child is Camera3D or child is Light3D or child is WorldEnvironment: continue
		var destination: Vector3=child.position
		child.position=destination+Vector3(0,-0.45-fmod(index*0.11,0.8),0)
		tween.tween_property(child,"position",destination,0.7).set_delay(fmod(index*0.035,0.3)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		index+=1
	await tween.finished
	busy=false; reveal_done=true
func _break_level() -> void:
	busy=true
	var tween: Tween=create_tween(); tween.set_parallel(true)
	var index: int=0
	for child in root3d.get_children():
		if not child is Node3D or child is Camera3D or child is Light3D or child is WorldEnvironment: continue
		var heading: float=index*2.399963
		var target: Vector3=child.position+Vector3(cos(heading)*1.2,-0.8-fmod(index*0.19,1.3),sin(heading)*1.2)
		tween.tween_property(child,"position",target,0.62).set_delay(fmod(index*0.025,0.16)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(child,"scale",child.scale*0.72,0.62).set_delay(fmod(index*0.025,0.16))
		index+=1
	await tween.finished
func _unhandled_key_input(event: InputEvent) -> void:
	if busy or not event.is_pressed() or event.is_echo(): return
	if event.keycode==KEY_Q: _change_view(Model.VIEWS[posmod(Model.VIEWS.find(state.view)-1,3)]); return
	if event.keycode==KEY_E: _change_view(Model.VIEWS[posmod(Model.VIEWS.find(state.view)+1,3)]); return
	var direction: Vector2=Vector2.ZERO
	match event.keycode:
		KEY_W,KEY_UP: direction=Vector2.UP
		KEY_S,KEY_DOWN: direction=Vector2.DOWN
		KEY_A,KEY_LEFT: direction=Vector2.LEFT
		KEY_D,KEY_RIGHT: direction=Vector2.RIGHT
	if direction==Vector2.ZERO: return
	var best: String=""; var score: float=0.15; var base: Vector2=Model.project(Model.position(level,state,state.node),source.cameras[level.id],state.view)
	for e in Model.edges(level,state,source.cameras[level.id]):
		var other: String=e.b if e.a==state.node else (e.a if e.b==state.node else "")
		if other.is_empty(): continue
		var offset: Vector2=Model.project(Model.position(level,state,other),source.cameras[level.id],state.view)-base
		if offset.length()<0.1:
			if e.kind=="perspective": offset=Vector2.UP if e.a==state.node else Vector2.DOWN
		var current: float=offset.normalized().dot(direction)
		if current>score: score=current; best=other
	if not best.is_empty(): _walk(best)
