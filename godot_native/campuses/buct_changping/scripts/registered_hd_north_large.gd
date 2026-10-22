extends "res://campuses/buct_changping/scripts/registered_hd_region.gd"
## Bounded v4 display owner. Four-texel native ground; separately charged five-texel
## lower strips. Old building/road/character/physics owners remain authoritative.
const V4_SCRIPT := "res://campuses/buct_changping/scripts/registered_hd_north_large.gd"
const V4_SHADER := preload("res://campuses/buct_changping/shaders/registered_hd_north_large.gdshader")
const SOURCE_ASSET := "res://campuses/buct_changping/assets/approved-changping.png"
const SOURCE_VERIFIER := preload("res://campuses/buct_changping/scripts/verified_source_texture.gd")
const V4_ID := "north_large"
const V4_ROI := [350,167,384,256]
const V4_CORE := [362,179,360,232]
const V4_NATIVE_SIZE := [1536,1024]
const BODY_OWNER_IDS := ["hill_south_block","north_sports_west_shelter"]
const LOWER_SPECS := {
	"west":{"id":"west_north","schema":"buct_registered_hd_region_v3","roi":[398,399,256,240],"rect":[398,399,256,24],"sample_size":[1280,122],"ground_rgba_sha256":"8ec2e094a8221119baa5f724982ea396f421756254860c9a98a76787c3961ebd"},
	"east":{"id":"north_adjacent","schema":"buct_registered_hd_region_v2","roi":[630,399,240,240],"rect":[630,399,104,24],"sample_size":[520,122],"ground_rgba_sha256":"9cd2e3d9f4b11a957b1aa199466d359d5091e4989d584b7ac6c50624229d6213"}
}
var lower_strip_textures: Dictionary = {}
var _bound_lower_regions: Dictionary = {}
var _v4_prepared := false
var _last_lower_state: Array = []
var _binding_failure := false

static func install_region(map: Node2D, profile_path: String, options: Dictionary = {}) -> Node2D:
	if not is_instance_valid(map) or not map.is_inside_tree():return null
	if not is_instance_valid(map.get("world")) or not is_instance_valid(map.get("objects")):return null
	if not map.world.is_inside_tree() or not map.objects.is_inside_tree():return null
	var decoded: Variant=_read_json(profile_path)
	if not decoded is Dictionary or not _valid_v4_profile(decoded):return null
	# The accepted source must be the actual immutable original, not just a claim.
	var source: Variant=map.get("SOURCE")
	if not SOURCE_VERIFIER.matches(source):return null
	var old: Node=map.world.get_node_or_null("RegisteredHDRegion_"+V4_ID)
	if old!=null:
		if not old is Node2D or old.get_script()==null or old.get_script().resource_path!=V4_SCRIPT:return null
		if old.get("_committed")==true:return old if old.profile==decoded else null
	var estimate := _estimate_v4_layer_bytes(decoded)
	if estimate<0 or estimate>MAX_REGION_LAYER_BYTES:return null
	var count:=0;var resident_bytes:=0
	for sibling in map.world.get_children():
		if sibling.has_method("get_diagnostics"):
			var diagnostic: Dictionary=sibling.get_diagnostics()
			if diagnostic.get("active",false) and diagnostic.has("new_gpu_texture_bytes"):
				count+=1;resident_bytes+=int(diagnostic.new_gpu_texture_bytes)
	if count+1>MAX_REGIONS or resident_bytes+estimate>MAX_RESIDENT_REGION_LAYER_BYTES:return null
	var node: Node2D=load(V4_SCRIPT).new()
	node.name="RegisteredHDRegion_"+V4_ID;node.campus=map;node.profile=decoded
	if not node._prepare(options) or node._gpu_bytes!=estimate:
		node.free();return null
	if not node._precommit_safe():node.free();return null
	# Nothing fallible is loaded or awaited after this point. Bind/commit/rollback
	# occur synchronously, before a render frame can observe partial retirement.
	if old!=null:
		old._restore();map.world.remove_child(old);old.queue_free()
	map.world.add_child(node);map.world.move_child(node,map.objects.get_index())
	node._commit()
	if node._binding_failure:
		node._restore();map.world.remove_child(node);node.free();return null
	return node

static func _valid_v4_geometry(data: Dictionary) -> bool:
	if data.get("schema","")!="buct_registered_hd_region_v4" or data.get("id","")!=V4_ID:return false
	if data.get("texels_per_source_pixel",null)!=4:return false
	return _same_numeric_array(data.get("roi_xywh",null),V4_ROI) and _same_numeric_array(data.get("core_xywh",null),V4_CORE) and _same_numeric_array(data.get("runtime_size",null),V4_NATIVE_SIZE)

static func _valid_v4_profile(data: Dictionary) -> bool:
	if not _valid_v4_geometry(data) or data.get("source_sha256","")!=SOURCE_SHA:return false
	if not data.get("quality_approved",null) is bool or data.quality_approved!=true:return false
	var ownership: Variant=data.get("source_body_ownership",null)
	if not ownership is Dictionary or ownership.get("encoding","")!="owner_index_u8":return false
	if ownership.get("owner_ids",null)!=BODY_OWNER_IDS or not _same_numeric_array(ownership.get("size",null),[384,256]):return false
	var edges: Variant=data.get("shared_lower_edges",null)
	if not edges is Array or edges.size()!=2:return false
	var keys: Array[String]=[]
	for edge in edges:
		if not edge is Dictionary or not edge.get("side",null) is String or not LOWER_SPECS.has(edge.side) or edge.side in keys:return false
		var expected: Dictionary=LOWER_SPECS[edge.side];keys.append(edge.side)
		if edge.get("neighbor_node","")!="RegisteredHDRegion_"+str(expected.id):return false
		if edge.get("source_ground_rgba_sha256","")!=expected.ground_rgba_sha256:return false
		if not _same_numeric_array(edge.get("rect",null),expected.rect) or not _same_numeric_array(edge.get("sample_size",null),expected.sample_size):return false
		if edge.get("sample_texels_per_source_pixel",null)!=5:return false
		if not edge.get("asset",null) is String or not edge.get("rgba_sha256",null) is String:return false
	if not data.get("independent_buildings",null) is Array or data.independent_buildings.size()>2:return false
	var body_ids: Array[String]=[]
	for body in data.independent_buildings:
		if not body is Dictionary or body.get("id","") not in BODY_OWNER_IDS or body.id in body_ids:return false
		body_ids.append(body.id)
	if data.get("shadow",null)!=null or not data.get("foreground",null) is Array or data.foreground.size()>12:return false
	if data.get("retire_world_visuals",[])!=[] or data.get("world_shadows",[])!=[] or data.get("water_complement",null)!=null:return false
	return true

static func _estimate_v4_layer_bytes(data: Dictionary) -> int:
	if not _valid_v4_profile(data):return -1
	var value:=_mip_bytes(Vector2i(1536,1024),4)+_mip_bytes(Vector2i(384,256),1)
	value+=_mip_bytes(Vector2i(1280,122),4)+_mip_bytes(Vector2i(520,122),4)
	for leaf in data.foreground:
		if not leaf is Dictionary or not _numeric_array(leaf.get("rect",null),4):return -1
		var r: Array=leaf.rect
		for number in r:
			if number!=floor(number):return -1
		if r[2]<=0 or r[3]<=0 or not Rect2(350,167,384,256).encloses(Rect2(r[0],r[1],r[2],r[3])):return -1
		value+=_mip_bytes(Vector2i(int(r[2]*4),int(r[3]*4)),1)
	return value

func _prepare(options: Dictionary) -> bool:
	if not _valid_v4_profile(profile):return false
	if campus.objects.get_parent()!=campus.world:return false
	for owner_id in BODY_OWNER_IDS:
		if not campus.objects.get_node_or_null(owner_id) is Node2D:return false
	region_rect=Rect2(350,167,384,256)
	ground_texture=_texture(options.get("ground_asset",profile.get("ground_asset",null)),Vector2i(1536,1024),profile.get("ground_rgba_sha256",""))
	if ground_texture==null:return false
	var mask_spec: Dictionary=profile.source_body_ownership
	if not _valid_owner_mask(mask_spec):return false
	ownership_texture=_r8(mask_spec.get("asset",null),Vector2i(384,256),mask_spec.get("sha256",""))
	if ownership_texture==null:return false
	for edge in profile.shared_lower_edges:
		var size:=Vector2i(int(edge.sample_size[0]),int(edge.sample_size[1]))
		var texture:=_texture(edge.asset,size,edge.rgba_sha256)
		if texture==null:return false
		lower_strip_textures[edge.side]=texture
	var material:=ShaderMaterial.new();material.shader=V4_SHADER
	material.set_shader_parameter("original_source",campus.SOURCE)
	material.set_shader_parameter("source_rect",Vector4(350,167,384,256))
	material.set_shader_parameter("body_ownership",ownership_texture)
	for side in ["west","east"]:
		var expected: Dictionary=LOWER_SPECS[side]
		material.set_shader_parameter(side+"_hd",lower_strip_textures[side])
		material.set_shader_parameter(side+"_sample_rect",Vector4(expected.rect[0],expected.rect[1],expected.sample_size[0]*.2,expected.sample_size[1]*.2))
	ground_sprite=_sprite(ground_texture,"RegisteredNative4xNorthernGround",region_rect.position,.25)
	ground_sprite.material=material;add_child(ground_sprite)
	for spec in profile.independent_buildings:
		# Preserve the exact legacy anchor as well as inherited footprint checks.
		var original: Node2D=campus.objects.get_node_or_null(spec.id)
		var registration: Variant=_read_json(spec.get("registration",null))
		if original==null or not registration is Dictionary:return false
		if not _same_numeric_array(registration.get("source_anchor",null),[original.position.x,original.position.y]):return false
		if not _prepare_body(spec):return false
	material.set_shader_parameter("body_1_independent",bodies.has(BODY_OWNER_IDS[0]))
	material.set_shader_parameter("body_2_independent",bodies.has(BODY_OWNER_IDS[1]))
	for leaf in profile.foreground:
		if not _prepare_foliage_v4(leaf):return false
	_v4_prepared=true
	if not visibility_changed.is_connected(_refresh_v4_visibility):visibility_changed.connect(_refresh_v4_visibility)
	return _gpu_bytes<=MAX_REGION_LAYER_BYTES

func _valid_owner_mask(spec: Dictionary) -> bool:
	var path: Variant=spec.get("asset",null)
	if not path is String or not FileAccess.file_exists(path):return false
	var bytes:=FileAccess.get_file_as_bytes(path)
	if bytes.size()!=384*256 or _sha(bytes)!=spec.get("sha256",""):return false
	var found: Array[bool]=[false,false]
	for value in bytes:
		if value>2:return false
		if value>0:found[value-1]=true
	return found[0] and found[1]

func _prepare_foliage_v4(spec: Dictionary) -> bool:
	if not spec.get("id",null) is String or not spec.id.is_valid_identifier() or not _numeric_array(spec.get("rect",null),4):return false
	if not _number(spec.get("baseline_y",null)) or campus.objects.get_node_or_null(spec.id)!=null:return false
	var r: Array=spec.rect
	for value in r:
		if value!=floor(value):return false
	if r[2]<=0 or r[3]<=0 or not region_rect.encloses(Rect2(r[0],r[1],r[2],r[3])):return false
	var texture:=_r8(spec.get("alpha_asset",null),Vector2i(int(r[2]*4),int(r[3]*4)),spec.get("alpha_sha256",""))
	if texture==null:return false
	var node:=Node2D.new();node.name=spec.id;node.position=Vector2(0,float(spec.baseline_y))
	var sprite:=_sprite(texture,"Native4xRegisteredLeafAlpha",Vector2(r[0],r[1])-node.position,.25)
	var material:=ShaderMaterial.new();material.shader=load("res://campuses/buct_changping/shaders/registered_hd_foliage.gdshader")
	if material.shader==null:node.free();sprite.free();return false
	material.set_shader_parameter("region_rgb",ground_texture)
	material.set_shader_parameter("source_rect",Vector4(350,167,384,256))
	sprite.material=material;node.add_child(sprite);foliage_nodes.append(node)
	return true

func _precommit_safe() -> bool:
	var retired: Array=[];var created: Array[String]=[]
	for item in restore_items:
		if not is_instance_valid(item.node) or item.node in retired:return false
		retired.append(item.node)
	for owned in bodies.values()+foliage_nodes:
		var label:=str(owned.name)
		if label in created or campus.objects.get_node_or_null(label)!=null:return false
		created.append(label)
	for sibling in campus.world.get_children():
		if sibling.get("_committed")!=true:continue
		var items: Variant=sibling.get("restore_items")
		if items is Array:
			for item in items:
				if item is Dictionary and item.get("node",null) in retired:return false
	for side in ["west","east"]:
		var lower: Node2D=_lower_region(side)
		if lower!=null and not lower.can_set_external_top_owner(self,_lower_rect(side),false):return false
	return true

func _lower_rect(side: String) -> Rect2:
	var r: Array=LOWER_SPECS[side].rect
	return Rect2(r[0],r[1],r[2],r[3])

func _lower_region(side: String) -> Node2D:
	if not is_instance_valid(campus) or not is_instance_valid(campus.world):return null
	var expected: Dictionary=LOWER_SPECS[side]
	var node: Node=campus.world.get_node_or_null("RegisteredHDRegion_"+str(expected.id))
	if not node is Node2D or node.get_script()==null or node.get_script().resource_path!=SELF_SCRIPT:return null
	if node.get("_committed")!=true or not node.is_visible_in_tree():return null
	var data: Variant=node.get("profile")
	if not data is Dictionary or data.get("id","")!=expected.id or data.get("schema","")!=expected.schema:return null
	if data.get("source_sha256","")!=SOURCE_SHA or data.get("quality_approved",null)!=true:return null
	if data.get("ground_rgba_sha256","")!=expected.ground_rgba_sha256 or not _same_numeric_array(data.get("roi_xywh",null),expected.roi):return null
	if node.get("campus")!=campus or not node.get("ground_texture") is Texture2D:return null
	if node.get_index()>=campus.objects.get_index():return null
	var sprite: Variant=node.get("ground_sprite")
	if not sprite is Sprite2D or not sprite.material is ShaderMaterial:return null
	var expected_shader: Shader=WEST_GROUND_SHADER if side=="west" else GROUND_SHADER
	if sprite.material.shader!=expected_shader:return null
	if not node.has_method("can_set_external_top_owner"):return null
	return node

func _external_top_owner_matches(lower: Node2D, rect: Rect2) -> bool:
	if str(name)!="RegisteredHDRegion_"+V4_ID:return false
	if not _v4_prepared or not _valid_v4_profile(profile) or not is_instance_valid(campus):return false
	if ground_texture==null or lower_strip_textures.size()!=2:return false
	if _committed and (get_parent()!=campus.world or campus.world.get_node_or_null(str(name))!=self):return false
	for side in ["west","east"]:
		if rect==_lower_rect(side) and _lower_region(side)==lower:return true
	return false

func _external_top_owner_released(lower: Node2D) -> void:
	# Lower hide/restore/detach can occur after this frame's v4 process. Release
	# that local shader input immediately rather than waiting for a later frame.
	for side in ["west","east"]:
		if _bound_lower_regions.get(side,null)!=lower:continue
		_bound_lower_regions.erase(side)
		var state: Array=_last_lower_state.duplicate() if _last_lower_state.size()==2 else [false,false]
		state[0 if side=="west" else 1]=false
		_last_lower_state=state;_shared_enabled=state[0] or state[1]
		if is_instance_valid(ground_sprite) and ground_sprite.material is ShaderMaterial:
			ground_sprite.material.set_shader_parameter(side+"_neighbor_active",false)

func _refresh_v4_visibility() -> void:
	if _committed:_process(0.0)

func _process(_delta: float) -> void:
	if not _committed:return
	_refresh_external_top_owner()
	if not is_visible_in_tree():
		for bound in _bound_lower_regions.values():
			if is_instance_valid(bound):bound.clear_external_top_owner(self)
		_bound_lower_regions.clear();_last_lower_state=[false,false];_shared_enabled=false
		ground_sprite.material.set_shader_parameter("west_neighbor_active",false)
		ground_sprite.material.set_shader_parameter("east_neighbor_active",false)
		return
	var state: Array=[]
	for side in ["west","east"]:
		var previous: Variant=_bound_lower_regions.get(side,null)
		var lower: Node2D=_lower_region(side)
		if is_instance_valid(previous) and previous!=lower:previous.clear_external_top_owner(self)
		var active:=false
		if lower!=null:
			active=lower.set_external_top_owner(self,_lower_rect(side))
			if active:
				_bound_lower_regions[side]=lower
				# One DAG: legacy east < west pair < upper v4 < independent objects.
				if get_index()<lower.get_index():campus.world.move_child(self,lower.get_index())
			else:_binding_failure=true
		if not active:_bound_lower_regions.erase(side)
		state.append(active)
	if state!=_last_lower_state:
		_last_lower_state=state;_shared_enabled=state[0] or state[1]
		ground_sprite.material.set_shader_parameter("west_neighbor_active",state[0])
		ground_sprite.material.set_shader_parameter("east_neighbor_active",state[1])
	# Keep all independent depth-sort objects after all ground owners.
	if get_index()>campus.objects.get_index():campus.world.move_child(self,campus.objects.get_index())

func _restore() -> void:
	for lower in _bound_lower_regions.values():
		if is_instance_valid(lower):lower.clear_external_top_owner(self)
	_bound_lower_regions.clear();_last_lower_state.clear();_v4_prepared=false
	lower_strip_textures.clear()
	super._restore()

func _notification(what: int) -> void:
	# Defensive counterpart to live-tree admission: even a manually committed
	# detached v4 must restore before direct free, without relying on a group.
	if what==NOTIFICATION_PREDELETE and (_committed or not _bound_lower_regions.is_empty()):_restore()
	super._notification(what)

func get_diagnostics() -> Dictionary:
	var result:=super.get_diagnostics()
	result["runtime_grid_texels_per_source_pixel"]=4
	var provenance: Variant=profile.get("provenance",{})
	result["native_original_detail_density"]=provenance.get("effective_native_detail_density",null) if provenance is Dictionary else null
	result["owned_lower_strip_texels_per_source_pixel"]=5
	result["owned_lower_strip_gpu_bytes"]=_mip_bytes(Vector2i(1280,122),4)+_mip_bytes(Vector2i(520,122),4) if _committed else 0
	result["unverified_original_body_ids"]=BODY_OWNER_IDS.filter(func(id):return not bodies.has(id))
	result["automatic_camera_streaming"]=false
	result["lower_neighbors_active"]=_last_lower_state.duplicate()
	return result

# One exact incoming western display owner; reuse BASE setter/clear/release protocol.
func can_set_external_top_owner(owner: Node2D, rect: Rect2, require_active := true) -> bool:
	if not _committed or not is_instance_valid(ground_sprite) or not ground_sprite.material is ShaderMaterial:return false
	if not is_instance_valid(owner) or owner.get_script()==null:return false
	if owner.get_script().resource_path!="res://campuses/buct_changping/scripts/registered_hd_north_west_upper.gd" or rect!=Rect2(350,167,24,256):return false
	if require_active and (owner.get("_committed")!=true or not owner.is_visible_in_tree()):return false
	if is_instance_valid(_external_top_owner) and _external_top_owner!=owner:return false
	return owner.has_method("_external_top_owner_matches") and owner._external_top_owner_matches(self,rect)
