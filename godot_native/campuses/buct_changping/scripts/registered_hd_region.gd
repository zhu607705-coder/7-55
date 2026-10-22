extends Node2D
## Bounded profile-driven region. Prepare everything before changing source owners.
## Residency is capped; automatic camera streaming is not implemented or claimed.
const SELF_SCRIPT := "res://campuses/buct_changping/scripts/registered_hd_region.gd"
const BODY_SCRIPT := preload("res://campuses/buct_changping/scripts/registered_hd_building.gd")
const GROUND_SHADER := preload("res://campuses/buct_changping/shaders/registered_hd_ground.gdshader")
const WEST_GROUND_SHADER := preload("res://campuses/buct_changping/shaders/registered_hd_west_ground.gdshader")
const SOURCE_SHA := "f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707"
const MAX_REGIONS := 6
const MAX_RESIDENT_REGION_LAYER_BYTES := 57597600
const MAX_REGION_LAYER_BYTES := 12000000
var profile: Dictionary = {}
var campus: Node2D
var ground_texture: Texture2D
var ownership_texture: ImageTexture
var seam_texture: Texture2D
var ground_sprite: Sprite2D
var shadow_texture: ImageTexture
var shadow_sprite: Sprite2D
var bodies: Dictionary = {}
var restore_items: Array[Dictionary] = []
var foliage_nodes: Array[Node2D] = []
var _body_gpu_bytes := 0
var _committed := false
var _gpu_bytes := 0
var _validation_rgba_bytes := 0
var _shared_enabled := false
var region_rect := Rect2()
var water_complement_texture: ImageTexture
var shared_edges: Dictionary = {}
var _group_members: Array[Node2D] = []
var _group_restoring := false
var _shared_state: Array = []
var world_shadow_nodes: Array[Dictionary] = []
var _world_shadow_owners: Array[CanvasItem] = []
var _world_shadow_signals_connected := false
# Optional v4 incoming owner. Inert until an exact authenticated owner binds.
var _external_top_owner: Node2D
var _external_top_owner_rect := Rect2()

static func install(map: Node2D, profile_path: String, options: Dictionary = {}) -> Node2D:
	if not is_instance_valid(map.world) or not is_instance_valid(map.objects): return null
	var parsed: Variant = _read_json(profile_path)
	if not parsed is Dictionary: return null
	# The multi-owner profile can only enter through an atomic group transaction.
	if parsed.get("schema","") == "buct_registered_hd_region_v3": return null
	var id: Variant = parsed.get("id",null)
	if not id is String or id.is_empty() or not id.is_valid_identifier(): return null
	var label: String = "RegisteredHDRegion_"+id
	var existing: Node = map.world.get_node_or_null(label)
	if existing != null:
		if existing.get("_committed") == true: return existing
		existing.get_parent().remove_child(existing);existing.queue_free()
	var estimate := _estimate_region_layer_bytes(parsed)
	if estimate < 0 or estimate > MAX_REGION_LAYER_BYTES: return null
	var resident_count := 0
	var resident_bytes := 0
	for sibling in map.world.get_children():
		if sibling.has_method("get_diagnostics"):
			var diagnostic: Dictionary = sibling.get_diagnostics()
			if diagnostic.get("active",false) and diagnostic.has("new_gpu_texture_bytes"):
				resident_count += 1;resident_bytes += int(diagnostic.new_gpu_texture_bytes)
	if resident_count >= MAX_REGIONS or resident_bytes+estimate > MAX_RESIDENT_REGION_LAYER_BYTES: return null
	var node: Node2D = load(SELF_SCRIPT).new()
	node.name = label;node.campus = map;node.profile = parsed
	if not node._prepare(options) or node._gpu_bytes != estimate: node.free();return null
	map.world.add_child(node)
	# Later region owns its shared strip, above the immutable legacy region.
	map.world.move_child(node,map.objects.get_index())
	node._commit()
	return node

func _prepare(options: Dictionary) -> bool:
	if profile.get("schema","") == "buct_registered_hd_region_v3": return _prepare_west(options)
	if profile.get("schema","") != "buct_registered_hd_region_v2": return false
	if profile.get("source_sha256","") != SOURCE_SHA: return false
	if not profile.get("quality_approved",false) is bool or profile.quality_approved != true: return false
	if not _numeric_array(profile.get("roi_xywh",null),4) or not _numeric_array(profile.get("runtime_size",null),2): return false
	var r: Array = profile.roi_xywh
	var size: Array = profile.runtime_size
	if r[2] != 240 or r[3] != 240 or size[0] != 1200 or size[1] != 1200: return false
	if r[0] < 0 or r[1] < 0 or r[0]+r[2] > 950 or r[1]+r[3] > 1656: return false
	region_rect = Rect2(r[0],r[1],r[2],r[3])
	ground_texture = _texture(options.get("ground_asset",profile.get("ground_asset",null)),Vector2i(1200,1200),profile.get("ground_rgba_sha256",""))
	if ground_texture == null: return false
	var ownership: Variant = profile.get("source_body_ownership",null)
	if not ownership is Dictionary or not _numeric_array(ownership.get("size",null),2): return false
	if ownership["size"][0] != 240 or ownership["size"][1] != 240: return false
	var mask: Variant = _r8(ownership.get("asset",null),Vector2i(240,240),ownership.get("sha256",""))
	if mask == null: return false
	ownership_texture = mask
	var seam: Variant = profile.get("shared_overlap",null)
	if not seam is Dictionary or not _numeric_array(seam.get("rect",null),4): return false
	if not seam.get("neighbor_node",null) is String or not seam.neighbor_node.is_valid_identifier(): return false
	if seam.rect[0] != r[0] or seam.rect[1]+seam.rect[3] != r[1]+r[3] or seam.rect[2] != r[2] or seam.rect[3] != 24: return false
	seam_texture = _texture(seam.get("unfeathered_strip_asset",null),Vector2i(1200,122),seam.get("rgba_sha256",""))
	if seam_texture == null: return false
	var material := ShaderMaterial.new();material.shader = GROUND_SHADER
	material.set_shader_parameter("original_source",campus.SOURCE)
	material.set_shader_parameter("source_rect",Vector4(r[0],r[1],r[2],r[3]))
	material.set_shader_parameter("body_ownership",ownership_texture)
	material.set_shader_parameter("shared_hd_strip",seam_texture)
	material.set_shader_parameter("shared_rect",Vector4(seam.rect[0],seam.rect[1],seam.rect[2],seam.rect[3]))
	ground_sprite = _sprite(ground_texture,"RegisteredCoherentGround",region_rect.position,.2)
	ground_sprite.material=material;add_child(ground_sprite)
	var specs: Variant = profile.get("independent_buildings",null)
	if not specs is Array or specs.is_empty() or specs.size()>8: return false
	for spec in specs:
		if not spec is Dictionary or not _prepare_body(spec): return false
	# An absent authored shadow is explicit. Never borrow another region's shadow.
	var shadow: Variant = profile.get("shadow",null)
	if shadow != null:
		if not shadow is Dictionary or not _number(shadow.get("opacity",null)): return false
		if shadow.opacity < 0 or shadow.opacity > 1 or not bodies.has(shadow.get("owner_id","")): return false
		shadow_texture = _r8(shadow.get("asset",null),Vector2i(1200,1200),shadow.get("sha256",""))
		if shadow_texture == null: return false
		shadow_sprite = _sprite(shadow_texture,"IndependentRegisteredCastShadow",region_rect.position,.2)
		var shadow_material := ShaderMaterial.new()
		shadow_material.shader = load("res://campuses/buct_changping/shaders/wenli_hd_shadow.gdshader")
		shadow_material.set_shader_parameter("shadow_opacity",float(shadow.opacity))
		shadow_sprite.material = shadow_material;add_child(shadow_sprite)
	if not profile.get("foreground",null) is Array: return false
	# New foreground masks are separately authored against this region's pixels.
	for leaf in profile.foreground:
		if not leaf is Dictionary or not _prepare_foliage(leaf): return false
	return _gpu_bytes <= MAX_REGION_LAYER_BYTES

func _prepare_body(spec: Dictionary) -> bool:
	var id: Variant = spec.get("id",null)
	if not id is String or id.is_empty() or bodies.has(id): return false
	var old: Node2D = campus.objects.get_node_or_null(id)
	if old == null: return false
	var decoded: Variant = _read_json(spec.get("registration",null))
	if not decoded is Dictionary or decoded.get("id","") != id or decoded.get("source_sha256","") != SOURCE_SHA: return false
	if not _valid_body_profile(decoded): return false
	if not spec.get("legacy_visual_names",null) is Array or not spec.get("underlay_names",null) is Array: return false
	var actual: Array = []
	for child in old.get_children():
		if child is StaticBody2D:
			if child.get_child_count()!=1 or not child.get_child(0) is CollisionPolygon2D: return false
			var points: Array = []
			for point in child.get_child(0).polygon:points.append([point.x+old.position.x,point.y+old.position.y])
			actual.append(points)
		elif str(child.name) not in spec.legacy_visual_names: return false
	if actual != decoded.get("collision_footprints_source_xy",null):
		# JSON may round binary64 display tails; physics is original Vector2 float32.
		# Explicit new registrations must round back to the exact engine vectors.
		if decoded.get("footprint_coordinate_precision","")!="original_Vector2_float32" or not _same_footprint_vectors(actual,decoded.get("collision_footprints_source_xy",null)):return false
	for label in spec.legacy_visual_names:
		if not label is String: return false
		var visual: Node = old.get_node_or_null(label)
		if not visual is CanvasItem: return false
		restore_items.append({"node":visual,"visible":visual.visible})
	for label in spec.underlay_names:
		if not label is String: return false
		var visual: Node = campus.world.get_node_or_null(label)
		if not visual is Polygon2D: return false
		restore_items.append({"node":visual,"visible":visual.visible})
	var body_texture: Resource = load(str(decoded.get("body_asset","")))
	if not body_texture is Texture2D or not body_texture.get_image().has_mipmaps(): return false
	var body := Node2D.new();body.set_script(BODY_SCRIPT);body.name=id+"_IndependentHD"
	if not body.configure(decoded,body_texture): body.free();return false
	# Remain detached until the whole region has validated.
	bodies[id]=body
	_body_gpu_bytes += _mip_bytes(body.raw_size,4) + body.raw_size.x*body.raw_size.y + body.raw_size.x*body.surface_count*4
	return true

func _prepare_foliage(spec: Dictionary) -> bool:
	if not spec.get("id",null) is String or not _numeric_array(spec.get("rect",null),4) or not _number(spec.get("baseline_y",null)): return false
	if campus.objects.get_node_or_null(spec.id) != null: return false
	var rect: Array = spec.rect
	if not region_rect.encloses(Rect2(rect[0],rect[1],rect[2],rect[3])): return false
	var size := Vector2i(int(rect[2]*5),int(rect[3]*5))
	var maximum := Vector2i(1200,1200)
	if profile.get("schema","") == "buct_registered_hd_region_v3": maximum=Vector2i(int(region_rect.size.x*5),int(region_rect.size.y*5))
	if size.x<1 or size.y<1 or size.x>maximum.x or size.y>maximum.y: return false
	var texture: ImageTexture = _r8(spec.get("alpha_asset",null),size,spec.get("alpha_sha256",""))
	if texture == null: return false
	var node := Node2D.new();node.name=spec.id;node.position=Vector2(0,float(spec.baseline_y))
	var sprite := _sprite(texture,"RegisteredLeafAlpha",Vector2(rect[0],rect[1])-node.position,.2)
	var shader: Shader = load("res://campuses/buct_changping/shaders/registered_hd_foliage.gdshader")
	if shader == null:node.free();sprite.free();return false
	var material := ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("region_rgb",ground_texture)
	material.set_shader_parameter("source_rect",Vector4(region_rect.position.x,region_rect.position.y,region_rect.size.x,region_rect.size.y))
	sprite.material=material;node.add_child(sprite);foliage_nodes.append(node)
	return true

func _commit() -> void:
	for item in restore_items:item.node.hide()
	for body in bodies.values():campus.objects.add_child(body)
	for leaf in foliage_nodes:campus.objects.add_child(leaf)
	_committed=true
	_process(0)

func _process(_delta: float) -> void:
	if not _committed:return
	_refresh_external_top_owner()
	if profile.get("schema","") == "buct_registered_hd_region_v3":
		_process_west()
		return
	var neighbor: Node = campus.world.get_node_or_null(str(profile.shared_overlap.neighbor_node))
	if neighbor != null and get_index() < neighbor.get_index():
		campus.world.move_child(self,neighbor.get_index())
	var enabled: bool = neighbor != null and neighbor.get("_committed") == true and neighbor.is_visible_in_tree()
	if enabled != _shared_enabled:
		_shared_enabled=enabled
		ground_sprite.material.set_shader_parameter("shared_neighbor_active",enabled)
	if is_instance_valid(shadow_sprite):shadow_sprite.visible=bodies[str(profile.shadow.owner_id)].is_visible_in_tree()

func update_actor_foot(foot_y: float) -> void:
	if not _committed:return
	for body in bodies.values():body.update_actor_foot(foot_y)

func hit_test(point: Vector2) -> String:
	if not _committed:return ""
	for id in bodies:
		if bodies[id].hit_test_alpha(point):return id
	return ""

func select_body(id: String) -> void:
	for key in bodies:bodies[key].set_selected(key==id)

func uninstall() -> void:
	if not _group_members.is_empty():
		var members: Array[Node2D] = _group_members.duplicate()
		_restore()
		for member in members:
			if is_instance_valid(member):
				if member.get_parent()!=null:member.get_parent().remove_child(member)
				member.queue_free()
		return
	_restore()
	if get_parent()!=null:get_parent().remove_child(self)
	queue_free()

func _restore() -> void:
	clear_external_top_owner()
	# Removing either ground retires the entire pair before a frame can render.
	# During an ancestor's exit, leave peers attached but inert for safe re-entry.
	if not _group_restoring and not _group_members.is_empty():
		var members: Array[Node2D] = _group_members.duplicate()
		for member in members:
			if is_instance_valid(member):member._group_restoring=true
		for member in members:
			if is_instance_valid(member) and member!=self:member._restore()
	if _committed:
		for item in restore_items:
			if is_instance_valid(item.node) and not item.node.visible:item.node.visible=item.visible
	_committed=false;set_process(false);hide()
	var shadow_callback := Callable(self,"_refresh_world_shadows")
	for owner in _world_shadow_owners:
		if is_instance_valid(owner) and owner.visibility_changed.is_connected(shadow_callback):
			owner.visibility_changed.disconnect(shadow_callback)
	_world_shadow_signals_connected=false
	for entry in world_shadow_nodes:
		if is_instance_valid(entry.node):
			entry.node.hide();entry.node.queue_free()
	world_shadow_nodes.clear();_world_shadow_owners.clear()
	for body in bodies.values():
		if is_instance_valid(body):
			if body.get_parent()!=null:body.get_parent().remove_child(body)
			body.queue_free()
	for leaf in foliage_nodes:
		if is_instance_valid(leaf):
			if leaf.get_parent()!=null:leaf.get_parent().remove_child(leaf)
			leaf.queue_free()
	bodies.clear();foliage_nodes.clear();restore_items.clear()
	for sprite in [ground_sprite,shadow_sprite]:
		if is_instance_valid(sprite):sprite.texture=null;sprite.material=null
	ground_texture=null;ownership_texture=null;seam_texture=null;shadow_texture=null;_gpu_bytes=0;_body_gpu_bytes=0
	water_complement_texture=null;shared_edges.clear();_group_members=[];_shared_state.clear()

func _exit_tree() -> void:_restore()
func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE:
		# Direct free/queue_free of a committed but never-in-tree group has no
		# _exit_tree notification. Retire its peers and body before deletion too.
		if not _group_members.is_empty():_restore()
		# Failed preparation can leave detached children that never entered a tree.
		for body in bodies.values():
			if is_instance_valid(body) and body.get_parent()==null:body.free()
		for leaf in foliage_nodes:
			if is_instance_valid(leaf) and leaf.get_parent()==null:leaf.free()

func get_diagnostics() -> Dictionary:
	return {"active":_committed,"new_gpu_texture_bytes":_gpu_bytes,
		"region_ground_foreground_seam_ownership_gpu_bytes":_gpu_bytes,"independent_body_gpu_bytes":_body_gpu_bytes,
		"total_new_gpu_texture_bytes":_gpu_bytes+_body_gpu_bytes,
		"cap_scope":"region ground, shadow, shared strip, body-ownership mask and leaf masks; independent bodies are separately counted","stable_retained_new_cpu_rgba_bytes":0,
		"validation_rgba_buffer_bytes":_validation_rgba_bytes,"independent_bodies":bodies.size(),
		"new_foreground_owners":foliage_nodes.size(),"shared_hd_owner_active":_shared_enabled,
		"region_residency_limit":MAX_REGIONS,"automatic_camera_streaming":false,"new_collision_bodies":0,
		"world_shadow_polygon_count":world_shadow_nodes.size(),"world_shadow_owner_count":_world_shadow_owners.size()}

func _texture(path: Variant, size: Vector2i, hash: Variant) -> Texture2D:
	if not path is String or not hash is String or not ResourceLoader.exists(path):return null
	var resource: Resource=load(path)
	if not resource is Texture2D or resource.get_size()!=Vector2(size):return null
	var image: Image=resource.get_image().duplicate()
	if not image.has_mipmaps():return null
	if image.is_compressed() and image.decompress()!=OK:return null
	image.clear_mipmaps();image.convert(Image.FORMAT_RGBA8)
	_validation_rgba_bytes=maxi(_validation_rgba_bytes,image.get_data_size())
	if _sha(image.get_data())!=hash:return null
	_gpu_bytes+=_mip_bytes(size,4)
	return resource
func _r8(path: Variant, size: Vector2i, hash: Variant) -> ImageTexture:
	if not path is String or not hash is String or not FileAccess.file_exists(path):return null
	var bytes:=FileAccess.get_file_as_bytes(path)
	if bytes.size()!=size.x*size.y or _sha(bytes)!=hash:return null
	var image:=Image.create_from_data(size.x,size.y,false,Image.FORMAT_R8,bytes)
	image.generate_mipmaps();_gpu_bytes+=_mip_bytes(size,1)
	return ImageTexture.create_from_image(image)
static func _sprite(texture: Texture2D,label: String,origin: Vector2,scale_value: float) -> Sprite2D:
	var sprite:=Sprite2D.new();sprite.name=label;sprite.centered=false;sprite.texture=texture
	sprite.position=origin;sprite.scale=Vector2.ONE*scale_value;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return sprite
static func _read_json(path: Variant) -> Variant:
	if not path is String or not FileAccess.file_exists(path):return null
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return null
	return parser.data
static func _numeric_array(value: Variant, count: int) -> bool:
	if not value is Array or value.size()!=count:return false
	for item in value:
		if not _number(item):return false
	return true
static func _number(value: Variant) -> bool:return (value is int or value is float) and is_finite(float(value))
static func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()
static func _mip_bytes(size: Vector2i,channels: int) -> int:
	var total:=0
	while true:
		total+=size.x*size.y*channels
		if size==Vector2i.ONE:return total
		size=Vector2i(maxi(1,size.x/2),maxi(1,size.y/2))
	return total

static func _estimate_region_layer_bytes(data: Dictionary) -> int:
	if data.get("schema","") == "buct_registered_hd_region_v3": return _estimate_west_layer_bytes(data)
	var value := _mip_bytes(Vector2i(1200,1200),4)+_mip_bytes(Vector2i(240,240),1)+_mip_bytes(Vector2i(1200,122),4)
	if data.get("shadow",null)!=null:value+=_mip_bytes(Vector2i(1200,1200),1)
	if not data.get("foreground",null) is Array:return -1
	for leaf in data.foreground:
		if not leaf is Dictionary or not _numeric_array(leaf.get("rect",null),4):return -1
		var rect: Array=leaf.rect
		if rect[2]<=0 or rect[3]<=0 or rect[2]>240 or rect[3]>240:return -1
		value+=_mip_bytes(Vector2i(int(rect[2]*5),int(rect[3]*5)),1)
	return value

static func _same_footprint_vectors(actual: Array, expected: Variant) -> bool:
	if not expected is Array or actual.size()!=expected.size():return false
	for i in range(actual.size()):
		if not expected[i] is Array or actual[i].size()!=expected[i].size():return false
		for j in range(actual[i].size()):
			if not _numeric_array(expected[i][j],2):return false
			if Vector2(actual[i][j][0],actual[i][j][1])!=Vector2(expected[i][j][0],expected[i][j][1]):return false
	return true

static func _valid_body_profile(data: Dictionary) -> bool:
	if not data.get("body_image_to_world",null) is Dictionary:return false
	var transform: Dictionary=data.body_image_to_world
	if not _number(transform.get("scale",null)) or transform.scale<=0:return false
	if not _numeric_array(transform.get("origin",null),2) or not _numeric_array(transform.get("raw_size",null),2):return false
	if transform.raw_size[0]<=0 or transform.raw_size[1]<=0 or transform.raw_size[0]>4096 or transform.raw_size[1]>4096:return false
	if not _numeric_array(data.get("source_anchor",null),2):return false
	if not _number(data.get("surface_count",null)) or data.surface_count<1 or data.surface_count>8:return false
	if not data.get("depth_rows_raw_y",null) is Array or data.depth_rows_raw_y.size()!=data.surface_count:return false
	for row in data.depth_rows_raw_y:
		if not _numeric_array(row,int(transform.raw_size[0])):return false
	for key in ["body_asset","body_sha256","body_rgba_sha256","surface_id_path","surface_id_sha256"]:
		if not data.get(key,null) is String:return false
	return true

## Returns the canonical north/south pair, or [] with all active owners intact.
## options may contain per-region preparation overrides keyed by profile id.
static func install_group(map: Node2D, profile_paths: Array, options: Dictionary = {}) -> Array[Node2D]:
	var empty: Array[Node2D] = []
	if not is_instance_valid(map.world) or not is_instance_valid(map.objects) or profile_paths.size()!=2:return empty
	var profiles: Array[Dictionary] = []
	for path in profile_paths:
		var decoded: Variant = _read_json(path)
		if not decoded is Dictionary:return empty
		profiles.append(decoded)
	if not _valid_group_profiles(profiles):return empty
	if not profiles[0].has("shared_corner"):profiles.reverse()
	var existing: Array[Node2D] = []
	var stale: Array[Node2D] = []
	for data in profiles:
		var old: Node = map.world.get_node_or_null("RegisteredHDRegion_"+str(data.id))
		if old==null:continue
		if not old is Node2D or old.get_script()!=load(SELF_SCRIPT):return empty
		if old.get("_committed")==true:
			if old.profile.get("atomic_group_id","")!=data.atomic_group_id:return empty
			existing.append(old)
		else:stale.append(old)
	if not existing.is_empty():
		if existing.size()==2:return existing
		return empty
	var resident_count := 0
	var resident_bytes := 0
	for sibling in map.world.get_children():
		if sibling.has_method("get_diagnostics"):
			var diagnostic: Dictionary = sibling.get_diagnostics()
			if diagnostic.get("active",false) and diagnostic.has("new_gpu_texture_bytes"):
				resident_count+=1;resident_bytes+=int(diagnostic.new_gpu_texture_bytes)
	var estimates: Array[int] = []
	for data in profiles:
		var estimate := _estimate_region_layer_bytes(data)
		if estimate<0 or estimate>MAX_REGION_LAYER_BYTES:return empty
		estimates.append(estimate);resident_bytes+=estimate
	if resident_count+2>MAX_REGIONS or resident_bytes>MAX_RESIDENT_REGION_LAYER_BYTES:return empty
	var prepared: Array[Node2D] = []
	for i in range(profiles.size()):
		var data: Dictionary = profiles[i]
		var override: Variant = options.get(data.id,{})
		if not override is Dictionary:
			_free_prepared(prepared);return empty
		var node: Node2D = load(SELF_SCRIPT).new()
		node.name="RegisteredHDRegion_"+str(data.id);node.campus=map;node.profile=data
		prepared.append(node)
		if not node._prepare(override) or node._gpu_bytes!=estimates[i]:
			_free_prepared(prepared);return empty
	# Whole bodies remain detached and un-clipped; reject duplicate retirements.
	var owner_nodes: Array = []
	var new_names: Array[String] = []
	var body_count := 0
	for node in prepared:
		body_count+=node.bodies.size()
		for item in node.restore_items:
			if not is_instance_valid(item.node) or item.node in owner_nodes:
				_free_prepared(prepared);return empty
			owner_nodes.append(item.node)
		for owned in node.bodies.values()+node.foliage_nodes:
			var label := str(owned.name)
			if label in new_names or map.objects.get_node_or_null(label)!=null:
				_free_prepared(prepared);return empty
			new_names.append(label)
	if body_count!=1 or prepared[0].bodies.size()!=1 or not prepared[1].bodies.is_empty():
		_free_prepared(prepared);return empty
	for node in prepared:
		for entry in node.world_shadow_nodes:
			if not entry.legacy_node in owner_nodes:
				_free_prepared(prepared);return empty
	# Optional caller checks read-only identities (e.g. library and water material).
	if options.has("precommit_validator"):
		var validator: Variant = options.precommit_validator
		if not validator is Callable or not validator.is_valid() or validator.call()!=true:
			_free_prepared(prepared);return empty
	prepared[0]._bind_south_region(prepared[1])
	# All fallible work is complete. No await or resource loading occurs below.
	for old in stale:
		old._restore();map.world.remove_child(old);old.queue_free()
	for node in prepared:
		node._group_members=prepared
		map.world.add_child(node)
		map.world.move_child(node,map.objects.get_index())
	for node in prepared:node._commit()
	for node in prepared:node._process(0)
	return prepared

static func _free_prepared(nodes: Array[Node2D]) -> void:
	for node in nodes:
		if is_instance_valid(node):node.free()

static func _valid_group_profiles(profiles: Array[Dictionary]) -> bool:
	var ids: Array[String] = []
	var corner_count := 0
	for data in profiles:
		if data.get("schema","")!="buct_registered_hd_region_v3":return false
		if not data.get("id",null) is String or not data.id.is_valid_identifier() or data.id in ids:return false
		if not data.get("atomic_group_id",null) is String or not data.atomic_group_id.is_valid_identifier():return false
		if not data.get("atomic_region_ids",null) is Array or data.atomic_region_ids.size()!=2:return false
		if not _valid_west_geometry(data):return false
		ids.append(data.id)
		if data.has("shared_corner"):corner_count+=1
	if corner_count!=1 or profiles[0].atomic_group_id!=profiles[1].atomic_group_id:return false
	for data in profiles:
		if data.atomic_region_ids!=profiles[0].atomic_region_ids:return false
		if not data.id in data.atomic_region_ids:return false
	var north: Dictionary = profiles[0] if profiles[0].has("shared_corner") else profiles[1]
	var south: Dictionary = profiles[1] if profiles[0].has("shared_corner") else profiles[0]
	if north.roi_xywh[0]!=south.roi_xywh[0] or north.roi_xywh[2]!=south.roi_xywh[2]:return false
	if south.roi_xywh[1]!=north.roi_xywh[1]+north.roi_xywh[3]-24:return false
	if not north.get("shared_corner",null) is Dictionary:return false
	var corner: Dictionary = north.shared_corner
	var expected := [north.roi_xywh[0]+north.roi_xywh[2]-24,south.roi_xywh[1],24,24]
	if not _same_numeric_array(corner.get("rect",null),expected) or corner.get("owner_node","")!="RegisteredHDRegion_"+str(north.id):return false
	if not corner.get("southeast_neighbor_node",null) is String or not corner.southeast_neighbor_node.is_valid_identifier():return false
	var north_edges: Dictionary = _west_edge_specs(north)
	var south_edges: Dictionary = _west_edge_specs(south)
	if north_edges.is_empty() or south_edges.is_empty():return false
	if not north_edges.has("south") or not south_edges.has("north"):return false
	if north_edges.south.neighbor_node!="RegisteredHDRegion_"+str(south.id):return false
	if south_edges.north.neighbor_node!="RegisteredHDRegion_"+str(north.id):return false
	if south_edges.north.owner_node!=south_edges.north.neighbor_node:return false
	if corner.southeast_neighbor_node!=south_edges.east.neighbor_node:return false
	return true

static func _valid_west_geometry(data: Dictionary) -> bool:
	if data.get("texels_per_source_pixel",null)!=5:return false
	for entry in [["roi_xywh",4],["runtime_size",2],["core_xywh",4]]:
		if not _numeric_array(data.get(entry[0],null),entry[1]):return false
		for value in data[entry[0]]:
			if value!=floor(value):return false
	var r: Array = data.roi_xywh
	var size: Array = data.runtime_size
	if r[0]<0 or r[1]<0 or r[2]<240 or r[3]!=240 or r[0]+r[2]>950 or r[1]+r[3]>1656:return false
	if not _same_numeric_array(size,[r[2]*5,r[3]*5]):return false
	# A wider context collar does not enlarge the 216x216 logical coverage core.
	if not _same_numeric_array(data.core_xywh,[r[0]+r[2]-228,r[1]+12,216,216]):return false
	return true

static func _west_edge_specs(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if not data.get("shared_edges",null) is Array or data.shared_edges.size()!=2:return result
	var r: Array = data.roi_xywh
	for edge in data.shared_edges:
		if not edge is Dictionary or not edge.get("edge",null) is String:return {}
		if result.has(edge.edge) or not edge.edge in ["east","south","north"]:return {}
		if not edge.get("neighbor_node",null) is String or not edge.neighbor_node.is_valid_identifier():return {}
		var expected: Array
		if edge.edge=="east":
			expected=[r[0]+r[2]-24,r[1],24,r[3]]
			if not _same_numeric_array(edge.get("sample_size",null),[122,r[3]*5]):return {}
			if not edge.get("unfeathered_strip_asset",null) is String or not edge.get("rgba_sha256",null) is String:return {}
		elif edge.edge=="south":expected=[r[0],r[1]+r[3]-24,r[2],24]
		else:
			expected=[r[0],r[1],r[2],24]
			if not edge.get("owner_node",null) is String or edge.owner_node!=edge.neighbor_node:return {}
		if not _same_numeric_array(edge.get("rect",null),expected):return {}
		result[edge.edge]=edge
	if not result.has("east"):return {}
	return result

func _prepare_west(options: Dictionary) -> bool:
	if profile.get("source_sha256","")!=SOURCE_SHA or profile.get("quality_approved",false)!=true:return false
	if not profile.get("quality_approved",false) is bool or not _valid_west_geometry(profile):return false
	shared_edges=_west_edge_specs(profile)
	if shared_edges.is_empty():return false
	var r: Array = profile.roi_xywh
	var size := Vector2i(int(profile.runtime_size[0]),int(profile.runtime_size[1]))
	var source_size := Vector2i(int(r[2]),int(r[3]))
	region_rect=Rect2(r[0],r[1],r[2],r[3])
	ground_texture=_texture(options.get("ground_asset",profile.get("ground_asset",null)),size,profile.get("ground_rgba_sha256",""))
	if ground_texture==null:return false
	var ownership: Variant = profile.get("source_body_ownership",null)
	if not ownership is Dictionary or not _same_numeric_array(ownership.get("size",null),[r[2],r[3]]):return false
	ownership_texture=_r8(ownership.get("asset",null),source_size,ownership.get("sha256",""))
	if ownership_texture==null:return false
	var east: Dictionary = shared_edges.east
	seam_texture=_texture(east.unfeathered_strip_asset,Vector2i(int(east.sample_size[0]),int(east.sample_size[1])),east.rgba_sha256)
	if seam_texture==null:return false
	var material := ShaderMaterial.new();material.shader=WEST_GROUND_SHADER
	material.set_shader_parameter("original_source",campus.SOURCE)
	material.set_shader_parameter("source_rect",Vector4(r[0],r[1],r[2],r[3]))
	material.set_shader_parameter("body_ownership",ownership_texture)
	material.set_shader_parameter("east_hd",seam_texture)
	material.set_shader_parameter("east_sample_rect",Vector4(east.rect[0],east.rect[1],east.sample_size[0]*.2,east.sample_size[1]*.2))
	if shared_edges.has("south"):
		var south: Array = shared_edges.south.rect
		material.set_shader_parameter("south_rect",Vector4(south[0],south[1],south[2],south[3]))
	if shared_edges.has("north"):
		var north: Array = shared_edges.north.rect
		material.set_shader_parameter("north_rect",Vector4(north[0],north[1],north[2],north[3]))
	if profile.has("shared_corner"):
		var corner: Array = profile.shared_corner.rect
		material.set_shader_parameter("corner_rect",Vector4(corner[0],corner[1],corner[2],corner[3]))
	var water: Variant = profile.get("water_complement",null)
	if water!=null:
		if not water is Dictionary or not _same_numeric_array(water.get("size",null),[r[2],r[3]]):return false
		water_complement_texture=_binary_r8(water.get("asset",null),source_size,water.get("sha256",""))
		if water_complement_texture==null:return false
		material.set_shader_parameter("water_complement",water_complement_texture)
		material.set_shader_parameter("water_complement_active",true)
	ground_sprite=_sprite(ground_texture,"RegisteredCoherentGround",region_rect.position,.2)
	ground_sprite.material=material;add_child(ground_sprite)
	var specs: Variant = profile.get("independent_buildings",null)
	if not specs is Array or specs.size()>1:return false
	for spec in specs:
		if not spec is Dictionary or not _prepare_body(spec):return false
	var retired: Variant = profile.get("retire_world_visuals",[])
	if not retired is Array:return false
	for label in retired:
		if not label is String:return false
		var visual: Node = campus.world.get_node_or_null(label)
		if not visual is Polygon2D:return false
		restore_items.append({"node":visual,"visible":visual.visible})
	# Texture shadows remain absent. Optional exact authored world polygons are
	# independent of both ground ROIs and use no source-RGB or added texture.
	if profile.get("shadow",null)!=null:return false
	if not _prepare_world_shadows(profile.get("world_shadows",[])):return false
	if not profile.get("foreground",null) is Array:return false
	for leaf in profile.foreground:
		if not leaf is Dictionary or not _prepare_foliage(leaf):return false
	return _gpu_bytes<=MAX_REGION_LAYER_BYTES

func _binary_r8(path: Variant, size: Vector2i, hash: Variant) -> ImageTexture:
	if not path is String or not FileAccess.file_exists(path):return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size()!=size.x*size.y:return null
	for value in bytes:
		if value!=0 and value!=255:return null
	return _r8(path,size,hash)

func _bind_south_region(south: Node2D) -> void:
	var material: ShaderMaterial = ground_sprite.material
	var r: Rect2 = south.region_rect
	material.set_shader_parameter("south_hd",south.ground_texture)
	material.set_shader_parameter("south_sample_rect",Vector4(r.position.x,r.position.y,r.size.x,r.size.y))
	var edge: Dictionary = south.shared_edges.east
	# Reuse already-accounted RGB resources, never allocate a third corner image.
	material.set_shader_parameter("southeast_hd",south.seam_texture)
	material.set_shader_parameter("southeast_sample_rect",Vector4(edge.rect[0],edge.rect[1],edge.sample_size[0]*.2,edge.sample_size[1]*.2))

func _process_west() -> void:
	if not _world_shadow_signals_connected:
		var callback := Callable(self,"_refresh_world_shadows")
		for owner in _world_shadow_owners:
			if is_instance_valid(owner) and not owner.visibility_changed.is_connected(callback):owner.visibility_changed.connect(callback)
		_world_shadow_signals_connected=true
	_refresh_world_shadows()
	var east: Dictionary = shared_edges.east
	var east_active := _neighbor_active(east)
	var south_active := shared_edges.has("south") and _neighbor_active(shared_edges.south)
	var north_active := shared_edges.has("north") and _neighbor_active(shared_edges.north)
	var southeast_active := false
	var dependencies: Array[Dictionary] = [east]
	if shared_edges.has("south"):dependencies.append(shared_edges.south)
	if profile.has("shared_corner"):
		var corner: Dictionary = profile.shared_corner
		var diagonal := {"edge":"southeast","neighbor_node":corner.southeast_neighbor_node,"rect":corner.rect}
		southeast_active=_neighbor_active(diagonal)
		dependencies.append(diagonal)
	# Directed owner order: east legacy < SW < NW. Insertion order has no effect.
	for dependency in dependencies:
		if not _neighbor_active(dependency):continue
		var neighbor: Node = campus.world.get_node_or_null(str(dependency.neighbor_node))
		if neighbor!=null and neighbor!=self and get_index()<neighbor.get_index():
			campus.world.move_child(self,neighbor.get_index())
	var state: Array = [east_active,south_active,north_active,southeast_active]
	if state!=_shared_state:
		_shared_state=state;_shared_enabled=east_active or south_active or north_active
		ground_sprite.material.set_shader_parameter("east_neighbor_active",east_active)
		ground_sprite.material.set_shader_parameter("south_neighbor_active",south_active)
		ground_sprite.material.set_shader_parameter("north_owner_active",north_active)
		ground_sprite.material.set_shader_parameter("southeast_neighbor_active",southeast_active)

func _neighbor_active(edge: Dictionary) -> bool:
	var neighbor: Node = campus.world.get_node_or_null(str(edge.neighbor_node))
	if not neighbor is CanvasItem or neighbor.get("_committed")!=true or not neighbor.is_visible_in_tree():return false
	var data: Variant = neighbor.get("profile")
	if not data is Dictionary or data.get("source_sha256","")!=SOURCE_SHA or not _numeric_array(data.get("roi_xywh",null),4):return false
	var r: Array = data.roi_xywh
	var overlap: Array = edge.rect
	# A broad or coincident unrelated region cannot activate this neighbor slot.
	if edge.get("edge","") in ["east","south","southeast"]:
		if r[0]!=overlap[0] or r[1]!=overlap[1]:return false
	elif edge.get("edge","")=="north":
		if r[0]!=overlap[0] or r[1]+r[3]!=overlap[1]+overlap[3]:return false
	else:return false
	return Rect2(r[0],r[1],r[2],r[3]).encloses(Rect2(overlap[0],overlap[1],overlap[2],overlap[3]))

static func _estimate_west_layer_bytes(data: Dictionary) -> int:
	if not _valid_west_geometry(data):return -1
	var edges := _west_edge_specs(data)
	if edges.is_empty():return -1
	var r: Array = data.roi_xywh
	var size := Vector2i(int(data.runtime_size[0]),int(data.runtime_size[1]))
	var source_size := Vector2i(int(r[2]),int(r[3]))
	var east: Dictionary = edges.east
	var value := _mip_bytes(size,4)+_mip_bytes(source_size,1)+_mip_bytes(Vector2i(int(east.sample_size[0]),int(east.sample_size[1])),4)
	if data.get("water_complement",null)!=null:value+=_mip_bytes(source_size,1)
	if data.get("shadow",null)!=null or not data.get("foreground",null) is Array:return -1
	for leaf in data.foreground:
		if not leaf is Dictionary or not _numeric_array(leaf.get("rect",null),4):return -1
		var rect: Array = leaf.rect
		if rect[2]<=0 or rect[3]<=0 or rect[2]>r[2] or rect[3]>r[3]:return -1
		value+=_mip_bytes(Vector2i(int(rect[2]*5),int(rect[3]*5)),1)
	return value

func _prepare_world_shadows(specs: Variant) -> bool:
	if not specs is Array or specs.size()>2:return false
	if specs.is_empty():return true
	# The north component is above both tile grounds. The shadow stays whole,
	# including authored vertices beyond this component's own ground rectangle.
	if not profile.has("shared_corner") or not shared_edges.has("south"):return false
	var layers: Variant = _read_json("res://campuses/buct_changping/data/layers.json")
	if not layers is Dictionary or not layers.get("objects",null) is Array:return false
	var seen: Array[String] = []
	for spec in specs:
		if not spec is Dictionary or not spec.get("owner_id",null) is String:return false
		var owner_id: String = spec.owner_id
		if owner_id in seen or campus.objects.get_node_or_null(owner_id)==null:return false
		if not _number(spec.get("opacity",null)) or spec.opacity<0 or spec.opacity>1:return false
		var authored: Dictionary = {}
		for item in layers.objects:
			if item is Dictionary and item.get("id","")==owner_id:authored=item;break
		var polygons: Variant = spec.get("polygons_source_xy",null)
		if not polygons is Array or polygons.is_empty() or polygons!=authored.get("shadow_polygons",null):return false
		var owner: CanvasItem
		if bodies.has(owner_id):owner=bodies[owner_id]
		elif owner_id=="library" and is_instance_valid(campus.library_layer):owner=campus.library_layer
		else:return false
		if not is_instance_valid(owner):return false
		seen.append(owner_id);_world_shadow_owners.append(owner)
		for i in range(polygons.size()):
			var polygon: Variant = polygons[i]
			if not polygon is Array or polygon.size()<3:return false
			var points := PackedVector2Array()
			for point in polygon:
				if not _numeric_array(point,2) or point[0]<0 or point[0]>950 or point[1]<0 or point[1]>1656:return false
				points.append(Vector2(point[0],point[1]))
			var legacy_path := "StaticSourceGroundShadows/%s_GroundShadow_%d" % [owner_id,polygons.size()-i]
			var legacy: Node = campus.world.get_node_or_null(legacy_path)
			if not legacy is Polygon2D:return false
			var shadow := Polygon2D.new()
			shadow.name="RegisteredWorldShadow_%s_%d" % [owner_id,i+1]
			shadow.polygon=points;shadow.color=Color(0,0,0,float(spec.opacity))
			shadow.visible=false;add_child(shadow)
			world_shadow_nodes.append({"node":shadow,"owner":owner,"legacy_node":legacy})
	return true

func _refresh_world_shadows() -> void:
	for entry in world_shadow_nodes:
		if is_instance_valid(entry.node):
			entry.node.visible=_committed and is_instance_valid(entry.owner) and entry.owner.is_visible_in_tree()

static func _same_numeric_array(value: Variant, expected: Array) -> bool:
	# JSON numbers decode as floats; geometry equality must not depend on Variant int/float tags.
	if not _numeric_array(value,expected.size()):return false
	for i in range(expected.size()):
		if float(value[i])!=float(expected[i]):return false
	return true


# This setter changes display ownership only. It cannot change route/physics data.
func can_set_external_top_owner(owner: Node2D, rect: Rect2, require_active := true) -> bool:
	if not _committed or not is_instance_valid(ground_sprite) or not ground_sprite.material is ShaderMaterial:return false
	if not is_instance_valid(owner) or owner.get_script()==null:return false
	if owner.get_script().resource_path!="res://campuses/buct_changping/scripts/registered_hd_north_large.gd":return false
	if require_active and (owner.get("_committed")!=true or not owner.is_visible_in_tree()):return false
	if is_instance_valid(_external_top_owner) and _external_top_owner!=owner:return false
	if not owner.has_method("_external_top_owner_matches"):return false
	return owner._external_top_owner_matches(self,rect)

func set_external_top_owner(owner: Node2D, rect: Rect2) -> bool:
	if not can_set_external_top_owner(owner,rect):return false
	_external_top_owner=owner;_external_top_owner_rect=rect
	var material: ShaderMaterial=ground_sprite.material
	material.set_shader_parameter("external_top_owner_rect",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
	material.set_shader_parameter("external_top_owner_active",true)
	return true

func clear_external_top_owner(owner: Node2D = null) -> bool:
	# A foreign caller may not clear another incoming owner's guard.
	if owner!=null and is_instance_valid(_external_top_owner) and owner!=_external_top_owner:return false
	if is_instance_valid(ground_sprite) and ground_sprite.material is ShaderMaterial:
		ground_sprite.material.set_shader_parameter("external_top_owner_active",false)
	var released: Node2D=_external_top_owner
	_external_top_owner=null;_external_top_owner_rect=Rect2()
	if is_instance_valid(released) and released.has_method("_external_top_owner_released"):released._external_top_owner_released(self)
	return true

func _refresh_external_top_owner() -> void:
	if not is_instance_valid(_external_top_owner):
		clear_external_top_owner();return
	if not can_set_external_top_owner(_external_top_owner,_external_top_owner_rect):clear_external_top_owner()
