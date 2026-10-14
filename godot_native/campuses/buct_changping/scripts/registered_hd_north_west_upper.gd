extends "res://campuses/buct_changping/scripts/registered_hd_region.gd"
## Bounded native4x ground owner; only explicitly registered original bodies retire their source visuals.
const REGION_SCRIPT := "res://campuses/buct_changping/scripts/registered_hd_north_west_upper.gd"
const REGION_SHADER := preload("res://campuses/buct_changping/shaders/registered_hd_north_west_upper.gdshader")
const SOURCE_ASSET := "res://campuses/buct_changping/assets/approved-changping.png"
const REGION_ID := "north_west_upper"
const ROI := [118,167,256,256]
const CORE := [130,179,232,232]
const BODY_OWNER_IDS := ["dorm_nw_01","dorm_nw_02","dorm_nw_03","dorm_nw_04","dorm_north_low_annex","dorm_w_01","dorm_w_02","hill_south_block"]
const BODY_ANCHORS := [[110,299],[181,304],[109,341],[186,350],[147,398],[107,473],[183,477],[390,343]]
const OWNER_MASK_SHA := "fd4a8ffbf9b930d7ed69005c14c6104b017236c59a7133650b2bce46eed61da8"
const NEIGHBOR_SCRIPT := "res://campuses/buct_changping/scripts/registered_hd_north_large.gd"
const NEIGHBOR_SHADER := preload("res://campuses/buct_changping/shaders/registered_hd_north_large.gdshader")
const NEIGHBOR_PROFILE := "res://campuses/buct_changping/data/north_large_hd_region.json"
const NEIGHBOR_PROFILE_SHA := "11f73273b005792f0951c7847e74944dd903c008c1dff3b8f69ad3287317c97d"
const NEIGHBOR_GROUND_SHA := "1e41812d1dac462577bb4b922704ee86d22283378277a639a197818de17a582a"
const STRIP_SHA := "09591e73547af1a46b22c3c9ae0a487080cbf666be2ec54e0ce9b44e81b9c5cb"
const SHARED_RECT := Rect2(350,167,24,256)
const LAYER_BYTES := 6204069
var east_strip_texture: Texture2D
var _expected_neighbor_profile: Dictionary = {}
var _bound_east: Node2D
var _prepared := false
var _east_active := false
var _binding_failure := false

static func install_region(map: Node2D, profile_path: String, options: Dictionary = {}) -> Node2D:
	if not is_instance_valid(map) or not map.is_inside_tree():return null
	if not is_instance_valid(map.get("world")) or not is_instance_valid(map.get("objects")):return null
	if not map.world.is_inside_tree() or map.objects.get_parent()!=map.world:return null
	var decoded: Variant=_read_json(profile_path)
	if not decoded is Dictionary or not _valid_profile(decoded):return null
	var source: Variant=map.get("SOURCE")
	if not source is Texture2D or source.resource_path!=SOURCE_ASSET:return null
	if FileAccess.get_sha256(SOURCE_ASSET)!=SOURCE_SHA:return null
	var old: Node=map.world.get_node_or_null("RegisteredHDRegion_"+REGION_ID)
	if old!=null:
		if not old is Node2D or old.get_script()==null or old.get_script().resource_path!=REGION_SCRIPT:return null
		if old.get("_committed")==true:return old if old.profile==decoded else null
	var count:=0;var resident_bytes:=0
	for sibling in map.world.get_children():
		if sibling.has_method("get_diagnostics"):
			var diagnostic: Dictionary=sibling.get_diagnostics()
			if diagnostic.get("active",false) and diagnostic.has("new_gpu_texture_bytes"):
				count+=1;resident_bytes+=int(diagnostic.new_gpu_texture_bytes)
	if LAYER_BYTES>MAX_REGION_LAYER_BYTES or count+1>MAX_REGIONS or resident_bytes+LAYER_BYTES>MAX_RESIDENT_REGION_LAYER_BYTES:return null
	var node: Node2D=load(REGION_SCRIPT).new()
	node.name="RegisteredHDRegion_"+REGION_ID;node.campus=map;node.profile=decoded
	if not node._prepare(options) or node._gpu_bytes!=LAYER_BYTES or not node._precommit_safe():node.free();return null
	if old!=null:old._restore();map.world.remove_child(old);old.queue_free()
	map.world.add_child(node);map.world.move_child(node,map.objects.get_index());node._commit()
	if node._binding_failure:node._restore();map.world.remove_child(node);node.free();return null
	return node

static func _valid_profile(data: Dictionary) -> bool:
	if data.get("schema","")!="buct_registered_hd_region_v5" or data.get("id","")!=REGION_ID:return false
	if not data.get("quality_approved",null) is bool or data.quality_approved!=true or data.get("source_sha256","")!=SOURCE_SHA:return false
	if data.get("texels_per_source_pixel",null)!=4 or not _same_numeric_array(data.get("roi_xywh",null),ROI) or not _same_numeric_array(data.get("core_xywh",null),CORE):return false
	if not _same_numeric_array(data.get("runtime_size",null),[1024,1024]):return false
	var ownership: Variant=data.get("source_body_ownership",null)
	if not ownership is Dictionary or ownership.get("encoding","")!="owner_index_u8" or ownership.get("owner_ids",null)!=BODY_OWNER_IDS:return false
	if not _same_numeric_array(ownership.get("size",null),[256,256]) or ownership.get("sha256","")!=OWNER_MASK_SHA:return false
	var edge: Variant=data.get("shared_east",null)
	if not edge is Dictionary or edge.get("neighbor_node","")!="RegisteredHDRegion_north_large":return false
	if edge.get("source_profile_sha256","")!=NEIGHBOR_PROFILE_SHA or edge.get("source_ground_rgba_sha256","")!=NEIGHBOR_GROUND_SHA:return false
	if not _same_numeric_array(edge.get("rect",null),[350,167,24,256]) or not _same_numeric_array(edge.get("sample_size",null),[96,1024]):return false
	if edge.get("sample_texels_per_source_pixel",null)!=4 or edge.get("rgba_sha256","")!=STRIP_SHA:return false
	var specs: Variant=data.get("independent_buildings",null)
	if not specs is Array or specs.size()>1:return false
	for spec in specs:
		if not spec is Dictionary or spec.get("id","")!="dorm_nw_02":return false
	return data.get("foreground",null)==[] and data.get("shadow",null)==null and data.get("retire_world_visuals",[])==[] and data.get("world_shadows",[])==[] and data.get("water_complement",null)==null

func _prepare(options: Dictionary) -> bool:
	if not _valid_profile(profile):return false
	for i in range(BODY_OWNER_IDS.size()):
		var original: Node=campus.objects.get_node_or_null(BODY_OWNER_IDS[i])
		if not original is Node2D or original.position!=Vector2(BODY_ANCHORS[i][0],BODY_ANCHORS[i][1]):return false
	if FileAccess.get_sha256(NEIGHBOR_PROFILE)!=NEIGHBOR_PROFILE_SHA:return false
	var neighbor_data: Variant=_read_json(NEIGHBOR_PROFILE)
	if not neighbor_data is Dictionary:return false
	_expected_neighbor_profile=neighbor_data
	region_rect=Rect2(118,167,256,256)
	ground_texture=_texture(options.get("ground_asset",profile.get("ground_asset",null)),Vector2i(1024,1024),profile.get("ground_rgba_sha256",""))
	if ground_texture==null:return false
	var spec: Dictionary=profile.source_body_ownership
	var bytes:=FileAccess.get_file_as_bytes(spec.get("asset",""))
	if bytes.size()!=256*256 or _sha(bytes)!=OWNER_MASK_SHA:return false
	ownership_texture=_r8(spec.get("asset",null),Vector2i(256,256),OWNER_MASK_SHA)
	if ownership_texture==null:return false
	east_strip_texture=_texture(profile.shared_east.get("asset",null),Vector2i(96,1024),STRIP_SHA)
	if east_strip_texture==null:return false
	var material:=ShaderMaterial.new();material.shader=REGION_SHADER
	material.set_shader_parameter("original_source",campus.SOURCE)
	material.set_shader_parameter("body_ownership",ownership_texture)
	material.set_shader_parameter("east_hd",east_strip_texture)
	ground_sprite=_sprite(ground_texture,"RegisteredNative4xNorthWestUpperGround",region_rect.position,.25)
	ground_sprite.material=material;add_child(ground_sprite)
	for body_spec in profile.independent_buildings:
		var original: Node2D=campus.objects.get_node_or_null(body_spec.id)
		var registration: Variant=_read_json(body_spec.get("registration",null))
		if original==null or not registration is Dictionary:return false
		if not _same_numeric_array(registration.get("source_anchor",null),[original.position.x,original.position.y]):return false
		if not _prepare_body(body_spec):return false
	material.set_shader_parameter("body_2_independent",bodies.has("dorm_nw_02"))
	_prepared=true
	if not visibility_changed.is_connected(_refresh_visibility):visibility_changed.connect(_refresh_visibility)
	return _gpu_bytes==LAYER_BYTES

func _neighbor_region() -> Node2D:
	if not is_instance_valid(campus) or not is_instance_valid(campus.world):return null
	var node: Node=campus.world.get_node_or_null("RegisteredHDRegion_north_large")
	if not node is Node2D or node.get_script()==null or node.get_script().resource_path!=NEIGHBOR_SCRIPT:return null
	if node.get("_committed")!=true or not node.is_visible_in_tree() or node.get("campus")!=campus:return null
	var data: Variant=node.get("profile")
	if not data is Dictionary or data!=_expected_neighbor_profile:return null
	if data.get("source_sha256","")!=SOURCE_SHA or data.get("quality_approved",null)!=true or data.get("ground_rgba_sha256","")!=NEIGHBOR_GROUND_SHA:return null
	if node.get_index()>=campus.objects.get_index() or not node.get("ground_texture") is Texture2D:return null
	var sprite: Variant=node.get("ground_sprite")
	if not sprite is Sprite2D or not sprite.material is ShaderMaterial or sprite.material.shader!=NEIGHBOR_SHADER:return null
	return node if node.has_method("can_set_external_top_owner") else null

func _precommit_safe() -> bool:
	var east: Node2D=_neighbor_region()
	return east==null or east.can_set_external_top_owner(self,SHARED_RECT,false)

func _external_top_owner_matches(lower: Node2D, rect: Rect2) -> bool:
	if str(name)!="RegisteredHDRegion_"+REGION_ID or not _prepared or not _valid_profile(profile):return false
	if ground_texture==null or east_strip_texture==null or rect!=SHARED_RECT:return false
	if _committed and (get_parent()!=campus.world or campus.world.get_node_or_null(str(name))!=self):return false
	return _neighbor_region()==lower

func _set_east_active(active: bool) -> void:
	_east_active=active;_shared_enabled=active
	if is_instance_valid(ground_sprite) and ground_sprite.material is ShaderMaterial:ground_sprite.material.set_shader_parameter("east_neighbor_active",active)

func _external_top_owner_released(lower: Node2D) -> void:
	if _bound_east==lower:_bound_east=null;_set_east_active(false)

func _refresh_visibility() -> void:
	if _committed:_process(0.0)

func _process(_delta: float) -> void:
	if not _committed:return
	var east: Node2D=_neighbor_region() if is_visible_in_tree() else null
	if is_instance_valid(_bound_east) and _bound_east!=east:_bound_east.clear_external_top_owner(self)
	var active:=false
	if east!=null:
		active=east.set_external_top_owner(self,SHARED_RECT)
		if active:
			_bound_east=east
			if get_index()<east.get_index():campus.world.move_child(self,east.get_index())
		else:_binding_failure=true
	if not active:_bound_east=null
	if active!=_east_active:_set_east_active(active)
	if get_index()>campus.objects.get_index():campus.world.move_child(self,campus.objects.get_index())

func _restore() -> void:
	var released: Node2D=_bound_east;_bound_east=null
	if is_instance_valid(released):released.clear_external_top_owner(self)
	_prepared=false;_east_active=false;east_strip_texture=null;_expected_neighbor_profile.clear()
	super._restore()

func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE and (_committed or is_instance_valid(_bound_east)):_restore()
	super._notification(what)

func get_diagnostics() -> Dictionary:
	var result:=super.get_diagnostics()
	result["runtime_grid_texels_per_source_pixel"]=4
	var provenance: Variant=profile.get("provenance",{})
	result["native_original_detail_density"]=provenance.get("effective_native_detail_density",provenance.get("raw_original_native_density",null)) if provenance is Dictionary else null
	result["owned_east_strip_gpu_bytes"]=_mip_bytes(Vector2i(96,1024),4) if _committed else 0
	result["unverified_original_body_ids"]=[]
	for owner_id in BODY_OWNER_IDS:
		if not bodies.has(owner_id):result["unverified_original_body_ids"].append(owner_id)
	result["east_neighbor_active"]=_east_active
	return result
