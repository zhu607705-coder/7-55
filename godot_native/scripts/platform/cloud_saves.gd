extends CanvasLayer
## The native coordinator owns profile selection. JavaScript is fixed HTTP/disk transport only.
signal status_changed
const Storage=preload("res://scripts/platform/profile_storage.gd")
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const CampusMaterial=preload("res://scripts/ui/campus_ui_material.gd")
class Request extends RefCounted:
	signal finished(result: Dictionary)
	var callback: JavaScriptObject
	func receive(arguments: Array) -> void:
		var result: Variant=JSON.parse_string(str(arguments[0])) if arguments.size()==1 else null
		finished.emit(result if result is Dictionary else {"ok":false,"error":"无法读取存档服务响应。"})

var member_id := ""
var ready_for_play := false
var has_save := false
var status_text := "正在读取账号和存档…"
var head: Dictionary={}
var _transport: JavaScriptObject
var _watch: JavaScriptObject
var _calls: Array=[]
var _epoch := 0
var _busy := false
var _checking := false
var _applying := false
var _dirty := false
var _dirty_age := 0.0
var _quiet := 0.0
var _heartbeat := 0.0
var _document_clock := 0.0
var _disk_clock := 0.0
var _document_digest := ""
var _last_local_digest := ""
var _pending: Dictionary={}
var _guest: Dictionary={}
var _cover: ColorRect
var _panel: PanelContainer
var _column: VBoxContainer
var _dialog_status := ""
var _status_label: Label
var _owns_pause := false

func _ready() -> void:
	if not OS.has_feature("web"): set_process(false); return
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=150
	_build_surface()
	State.snapshot_saved.connect(_mark_dirty)
	_transport=JavaScriptBridge.get_interface("__GODOT_755_CLOUD__")
	if _transport!=null:
		_watch=JavaScriptBridge.create_callback(_on_transport_notice)
		_transport.watch(_watch)
	_boot.call_deferred()

func _build_surface() -> void:
	_cover=ColorRect.new();_cover.color=Color(0.03,0.07,0.09,0.9)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_cover.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(_cover)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_cover.add_child(center)
	_panel=PanelContainer.new();_panel.theme=NativeUi.make_theme(Typography.body_font(),18,16)
	_panel.add_theme_stylebox_override("panel",CampusMaterial.panel_style("paper",{},Vector2(20,20)));center.add_child(_panel)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_panel.add_child(scroll)
	_column=VBoxContainer.new();_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_column.add_theme_constant_override("separation",12);scroll.add_child(_column)
	get_viewport().size_changed.connect(_fit_surface);_fit_surface()

func _fit_surface() -> void:
	var area:=get_viewport().get_visible_rect().size
	_panel.custom_minimum_size=Vector2(maxf(180,minf(480,area.x-32)),maxf(140,minf(600,area.y-32)))

func _show(message: String, choices: Array=[]) -> void:
	ready_for_play=false;_cover.show();_pause()
	for child in _column.get_children(): _column.remove_child(child);child.queue_free()
	var title:=Label.new();title.text="7:55 · 玩家存档";title.add_theme_color_override("font_color",CampusMaterial.NAVY);_column.add_child(title)
	_status_label=Label.new();_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_column.add_child(_status_label)
	var text:=Label.new();text.text=message;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_column.add_child(text)
	for choice: Array in choices:
		var button:=Button.new();button.text=str(choice[0]);button.custom_minimum_size.y=46
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		NativeUi.apply_button(button,CampusMaterial.PAPER,CampusMaterial.INK,CampusMaterial.PAPER_EDGE,0,1,16,Vector2(10,8))
		button.pressed.connect(choice[1]);_column.add_child(button)
	_dialog_status=message.get_slice("\n",0)
	_set_status(_dialog_status)

func _pause() -> void:
	if not get_tree().paused: _owns_pause=true;get_tree().paused=true

func _set_status(value: String) -> void:
	status_text=value;status_changed.emit()
	if is_instance_valid(_status_label):
		_status_label.text=value;_status_label.visible=value!=_dialog_status

func _resume() -> void:
	ready_for_play=true;_cover.hide()
	if _owns_pause: _owns_pause=false;get_tree().paused=false
	status_changed.emit()

func can_enter() -> bool:
	return not OS.has_feature("web") or ready_for_play

func _request(operation: String,args: Dictionary) -> Dictionary:
	if _transport==null: return {"ok":false,"error":"此游戏尚未连接账号存档服务。"}
	var generation:=_epoch
	var call:=Request.new();call.callback=JavaScriptBridge.create_callback(call.receive);_calls.append(call)
	_transport.request(operation,JSON.stringify(args),call.callback)
	var result: Dictionary=await call.finished
	_calls.erase(call);call.callback=null
	if generation!=_epoch: return {"ok":false,"stale":true}
	if result.get("ok",false):
		var data: Variant=result.get("data")
		if operation in ["head","save","restart","restore"]:
			if not _valid_head(data,str(args.get("owner",""))): return {"ok":false,"error":"云存档目录无法读取，请重试；原存档未改变。"}
		elif operation=="session":
			if not data is Dictionary or not data.has("user") or (data.user!=null and not data.user is Dictionary): return {"ok":false,"error":"登录状态响应无效。"}
	return result

func _valid_head(value: Variant,member: String) -> bool:
	if not value is Dictionary or value.get("memberId")!=member or typeof(value.get("revision")) not in [TYPE_INT,TYPE_FLOAT] or float(value.revision)<0: return false
	for key: String in ["current","previous","beforeRestart"]:
		if not value.has(key): return false
		if value[key]==null: continue
		var item: Variant=value[key]
		if not item is Dictionary or not Storage.valid_key(str(item.get("id",""))) or str(item.get("digest","")).length()!=64: return false
	return true

func _id() -> String:
	var bytes:=Crypto.new().generate_random_bytes(16);bytes[6]=(bytes[6]&15)|64;bytes[8]=(bytes[8]&63)|128
	var text:=bytes.hex_encode();return text.substr(0,8)+"-"+text.substr(8,4)+"-"+text.substr(12,4)+"-"+text.substr(16,4)+"-"+text.substr(20)

func _digest(value: Dictionary) -> String:
	return JSON.stringify(value).sha256_text()

func _read_record(name: String) -> Dictionary:
	var path:=Storage.file(name)
	if not FileAccess.file_exists(path): return {}
	var handle:=FileAccess.open(path,FileAccess.READ)
	if handle==null or handle.get_length()>65536: return {}
	handle.close()
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path));return value if value is Dictionary else {}

func _record(name: String,value: Dictionary) -> bool:
	var path:=Storage.file(name)
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value));file.flush();var error:=file.get_error();file.close()
	return error==OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK

func _to_entry() -> void:
	var current:=get_tree().current_scene
	if current!=null and current.scene_file_path!="res://scenes/entry.tscn":
		get_tree().change_scene_to_file("res://scenes/entry.tscn")
		await get_tree().process_frame

func _boot() -> void:
	_epoch+=1;_busy=true;_checking=false;_pending={};has_save=false;_show("正在读取账号和存档…")
	var generation:=_epoch
	if not State.persistence_ready:
		var initial: Dictionary=State.activate_profile("guest")
		if not initial.get("ok",false): _busy=false;_failure(initial);return
		if initial.get("hasSave",false) and not State.at_unstarted_opening(): _guest=State.capture_cloud_bundle()
	elif Storage.profile=="guest":
		_guest = {}
		if FileAccess.file_exists(State.SAVE_PATH) and not State.at_unstarted_opening():
			_guest = State.capture_cloud_bundle()
	var session: Dictionary=await _request("session",{})
	if session.get("stale",false): return
	if int(session.get("status",0))==404 and member_id.is_empty(): _busy=false;await _use_guest();return
	if not session.get("ok",false): _busy=false;_failure(session,true);return
	var user: Variant=session.get("data",{}).get("user")
	if user==null:
		_busy=false
		if not member_id.is_empty(): _failure({"error":"登录已失效或已退出，请重新登录后继续账号进度。"},true);return
		await _use_guest();return
	var member:=str(user.get("id",""))
	if not Storage.valid_key(member) or member in ["guest","legacy"]: _busy=false;_failure({"error":"玩家身份无法识别。"});return
	member_id=member
	await _to_entry()
	if generation!=_epoch: return
	_applying=true
	var activated: Dictionary=State.activate_profile(member_id)
	_applying=false
	if not activated.get("ok",false): _busy=false;_failure(activated);return
	if activated.get("corrupt",false): _busy=false;_failure({"error":"此账号的本机存档无法读取，原文件已保留。请先导出本机备份后检查。"});return
	var remote: Dictionary=await _request("head",{"owner":member_id})
	if remote.get("stale",false): return
	if not remote.get("ok",false): _busy=false;_failure(remote);return
	head=remote.data
	var local: Dictionary=State.capture_cloud_bundle() if activated.get("hasSave",false) else {}
	var acknowledged:=_read_record("cloud-sync.json")
	var pending_local: bool=local.get("ok",false) and _digest(local.bundle)!=str(acknowledged.get("localDigest",""))
	var guest_choice:=_read_record("guest-choice.json")
	var previous_guest_digest := str(guest_choice.get("digest", ""))
	var offer_guest: bool = _guest.get("ok", false) and previous_guest_digest not in [_guest_digest(), _digest(_guest.bundle)]
	_busy=false
	if pending_local or offer_guest:
		var choices: Array=[]
		var message:="请选择要继续的进度。选择前两份都保留。\n"+_summary(head.get("current"),"账号云存档")
		if head.get("current")!=null: choices.append(["使用账号云存档",_load_current])
		if pending_local:
			message+="\n"+_summary(local.bundle.summary,"本机尚未同步的账号进度")
			choices.append(["使用本机账号进度",_adopt.bind(local)])
		if offer_guest:
			message+="\n"+_summary(_guest.bundle.summary,"本机游客进度")
			choices.append(["把游客进度保存到此账号",_adopt.bind(_guest)])
		choices.append(["从头开始（保留旧进度备份）",request_restart])
		_show(message,choices)
	elif head.get("current")!=null: await _load_current()
	else:
		_show("这个账号还没有云存档。",[["开始新的校园故事",_start_fresh]])

func card_text() -> String:
	if not has_save: return status_text
	if State.at_unstarted_opening(): return status_text+"\n第 1 章 · 尚未离开开场"
	if head.get("current") is Dictionary: return status_text+"\n第 %s 章 · %s" % [str(int(head.current.chapter)),str(head.current.task)]
	return status_text+"\n第 %s 章 · %s" % [str(int(State.d.native.chapter)),State.objective()]

func _saved_time(value: String) -> String:
	if value.is_empty(): return ""
	var utc:=Time.get_unix_time_from_datetime_string(value.left(19))
	return Time.get_datetime_string_from_unix_time(utc+int(Time.get_time_zone_from_system().bias)*60,true)+"（本机时间）"

func _summary(value: Variant,label: String) -> String:
	if not value is Dictionary: return label+"：暂无"
	return "%s：第 %s 章 · %s\n%s" % [label,str(int(value.get("chapter",0))),str(value.get("task","")),_saved_time(str(value.get("savedAt","")))]

func _guest_digest() -> String:
	# Compare the saved bytes rather than transient runtime state captured before login.
	return JSON.stringify(_guest.get("files", [])).sha256_text()

func _mark_guest_choice() -> bool:
	return not _guest.get("ok", false) or _record("guest-choice.json", {"digest": _guest_digest()})

func _use_guest() -> void:
	_epoch+=1;_busy=false
	var generation:=_epoch
	await _to_entry()
	if generation!=_epoch: return
	member_id="";head={};_pending={};_applying=true
	var result: Dictionary=State.activate_profile("guest")
	_applying=false
	if not result.get("ok",false) or result.get("corrupt",false): _failure({"error":"本机游客存档无法读取，原文件已保留。请导出备份后检查。"},true);return
	has_save=bool(result.get("hasSave",false));_dirty=false
	if _transport!=null: _transport.pending(false)
	_set_status("游客试玩 · 进度仅保存在本机");_resume()

func _download(snapshot: Dictionary) -> Dictionary:
	var generation:=_epoch
	var result: Dictionary=await _request("snapshot",{"owner":member_id,"id":snapshot.id})
	if not result.get("ok",false): return result
	if not result.get("data") is Dictionary or not result.data.get("bundle") is Dictionary: return {"ok":false,"error":"云存档封装无效。"}
	var bundle: Dictionary=result.data.bundle
	var envelope: Variant=JSON.parse_string(str(bundle.get("stateText","")))
	if not envelope is Dictionary or bundle.get("bundleVersion")!=1 or int(envelope.get("sourceVersion",0))>State.SOURCE_VERSION: return {"ok":false,"error":"此存档需要更新游戏版本；原云存档已保留。"}
	if not bundle.get("assets") is Array or bundle.assets.size()>4: return {"ok":false,"error":"存档照片清单无效。"}
	if str(result.data.get("digest",""))!=str(snapshot.get("digest","")): return {"ok":false,"error":"云存档已变化，请重新读取。"}
	var images: Dictionary={}
	for sha: String in bundle.get("assets",[]):
		var image: Dictionary=await _request("asset",{"owner":member_id,"sha":sha})
		if not image.get("ok",false): return image
		images[sha]=image.data
	if envelope is Dictionary and envelope.get("state") is Dictionary:
		if not await WebContent.ensure_state(envelope.state): return {"ok":false,"error":"章节资源尚未准备好，请重试。"}
	if generation!=_epoch: return {"ok":false,"stale":true}
	var prepared: Dictionary=State.prepare_cloud_bundle(bundle,images)
	if not prepared.get("ok",false): return prepared
	return {"ok":true,"prepared":prepared}

func _load_current() -> void:
	if _busy or head.get("current")==null: return
	var generation:=_epoch
	_busy=true;_show("正在读取并校验完整云存档和照片…")
	var result: Dictionary=await _download(head.current)
	if result.get("stale",false): return
	if not result.get("ok",false): _busy=false;_failure(result);return
	await _install(result.prepared)
	if generation!=_epoch: return
	_busy=false

func _persist(captured: Dictionary) -> bool:
	JavaScriptBridge.force_fs_sync()
	var result: Dictionary=await _request("persist",{"profile":Storage.profile,"files":captured.get("files",[])})
	return bool(result.get("ok",false))

func _install(prepared: Dictionary) -> void:
	var generation:=_epoch
	_applying=true;var result: Dictionary=State.install_cloud_bundle(prepared);_applying=false
	if not result.get("ok",false): _failure(result);return
	var local: Dictionary=State.capture_cloud_bundle()
	if not local.get("ok",false): _failure(local);return
	_last_local_digest=_digest(local.bundle)
	if not _record("cloud-sync.json",{"revision":head.revision,"cloudDigest":head.current.digest,"localDigest":_last_local_digest}) or not _mark_guest_choice():
		_failure({"error":"本机同步记录写入失败，云存档仍保留。"})
		return
	for name: String in ["cloud-sync.json", "guest-choice.json"]:
		var path := Storage.file(name)
		if FileAccess.file_exists(path):
			local.files.append({"path": ProjectSettings.globalize_path(path), "digest": FileAccess.get_sha256(path)})
	var persisted: bool=await _persist(local)
	if generation!=_epoch: return
	if not persisted: _failure({"error":"云存档仍在，但本机备份尚未确认，请重试；暂时不要刷新。"});return
	_pending={};_dirty=false;has_save=true
	_transport.pending(false);_set_status("云端已保存 · "+_saved_time(str(head.current.savedAt)));_resume()

func _upload(captured: Dictionary,kind: String="save") -> Dictionary:
	var generation:=_epoch
	var active_member:=member_id
	# Retries must upload the frozen operation's photos, even if play created a later photo.
	var upload_bundle: Dictionary=captured.bundle if _pending.is_empty() else _pending.input.bundle
	var upload_images: Dictionary=captured.images if _pending.is_empty() else _pending.images
	for sha: String in upload_bundle.assets:
		var exists: Dictionary=await _request("assetExists",{"owner":active_member,"sha":sha})
		if generation!=_epoch: return {"ok":false,"stale":true}
		if not exists.get("ok",false):
			if int(exists.get("status",0))!=404: return exists
			var asset: Dictionary=await _request("upload",{"owner":active_member,"sha":sha,"data":upload_images[sha].data})
			if not asset.get("ok",false): return asset
			if generation!=_epoch: return {"ok":false,"stale":true}
	if _pending.is_empty():
		_pending={"kind":kind,"images":captured.images,"input":{"expectedMemberId":member_id,"expectedRevision":int(head.get("revision",0)),"operationId":_id(),"bundle":captured.bundle}}
	return await _request(str(_pending.kind),{"owner":member_id,"input":_pending.input})

func _adopt(captured: Dictionary) -> void:
	if _busy: return
	var generation:=_epoch
	_busy=true;_show("正在把选定进度保存到当前账号…")
	var prepared: Dictionary=State.prepare_cloud_bundle(captured.bundle,captured.images)
	if not prepared.get("ok",false): _busy=false;_failure(prepared);return
	_pending={}
	var result: Dictionary=await _upload(captured)
	if generation!=_epoch: return
	if result.get("ok",false): head=result.data;await _install(prepared)
	else: _failure(result)
	if generation!=_epoch: return
	_busy=false

func _start_fresh() -> void:
	if _busy: return
	var generation:=_epoch
	_busy=true;_show("正在建立新进度并保留旧档…")
	var captured: Dictionary=State.capture_cloud_bundle(true)
	if not captured.get("ok",false): _busy=false;_failure(captured);return
	_pending={}
	var result: Dictionary=await _upload(captured,"restart")
	if generation!=_epoch: return
	if result.get("ok",false):
		head=result.data
		var prepared: Dictionary=State.prepare_cloud_bundle(captured.bundle,captured.images)
		await _install(prepared)
	else: _failure(result)
	if generation!=_epoch: return
	_busy=false

func request_restart() -> void:
	_show("将从头开始主线，当前进度会保留为重新开始前的备份。\n游戏内个人编辑内容会保留。",[["确认重新开始",_restart_confirmed],["取消",show_manager]])

func _restart_confirmed() -> void:
	var generation:=_epoch
	if member_id.is_empty():
		State.new_game();has_save=true;_set_status("游客新进度 · 仅本机");_resume();_enter_if_entry();return
	if _dirty:
		await flush()
		if generation!=_epoch or _dirty: return
	await _start_fresh()
	if generation==_epoch and ready_for_play:
		_enter_if_entry()

func restart_confirmed() -> void:
	if _busy: return
	_show("正在保存重新开始前的进度…")
	await _restart_confirmed()

func _enter_if_entry() -> void:
	var current:=get_tree().current_scene
	if current!=null and current.has_method("open_story"): current.open_story.call_deferred()

func _mark_dirty() -> void:
	if _applying or State.developer_mode: return
	if member_id.is_empty():
		JavaScriptBridge.force_fs_sync()
		return
	if not _dirty: _dirty_age=0
	_dirty=true;_quiet=0
	if _transport!=null: _transport.pending(true)
	_set_status("已写入本机 · 云端同步中…")

func flush() -> void:
	if _busy or member_id.is_empty() or not State.persistence_ready: return
	var generation:=_epoch
	_busy=true
	var captured: Dictionary=State.capture_cloud_bundle()
	if not captured.get("ok",false): _busy=false;_failure(captured);return
	var captured_digest:=_digest(captured.bundle)
	if _pending.is_empty() and captured_digest==_last_local_digest:
		_dirty=false;_busy=false;_transport.pending(false);return
	var persisted: bool=await _persist(captured)
	if generation!=_epoch: return
	if not persisted: _busy=false;_failure({"error":"本机存档尚未确认写入，暂时不要刷新，请重试。"});return
	_set_status("正在上传账号进度…")
	var result: Dictionary=await _upload(captured)
	if generation!=_epoch: return
	if result.get("ok",false):
		head=result.data
		# A retry receipt acknowledges only its original frozen bytes.
		var acknowledged: Dictionary=_pending.input.bundle
		_last_local_digest=_digest(acknowledged)
		_record("cloud-sync.json",{"revision":head.revision,"cloudDigest":head.current.digest,"localDigest":_last_local_digest})
		_pending={}
		var latest: Dictionary=State.capture_cloud_bundle()
		_dirty=latest.get("ok",false) and _digest(latest.bundle)!=_last_local_digest
		if not _dirty: _transport.pending(false);_set_status("云端已保存 · "+_saved_time(str(head.current.savedAt)))
		else: _quiet=0;_dirty_age=0;_set_status("正在同步后续进度…")
	else: _failure(result)
	_busy=false

func save_now() -> void:
	if member_id.is_empty():
		var scene:=get_tree().current_scene
		if scene!=null and scene.get("web_platform")!=null: scene.web_platform.request_save()
		return
	if not State.save_game(): _failure({"error":"当前进度不能保存。"});return
	await flush()
	status_changed.emit()

func show_manager() -> void:
	if _busy: return
	var choices: Array=[]
	if has_save: choices.append(["继续游戏",_continue_current])
	choices.append(["立即保存",save_now])
	if not member_id.is_empty():
		for key: String in ["previous","beforeRestart"]:
			if head.get(key)!=null: choices.append(["恢复上一份有效存档" if key=="previous" else "恢复重新开始前的存档",_confirm_restore.bind(head[key])])
	choices.append(["重新开始",request_restart])
	choices.append(["导出个人备份",_export])
	choices.append(["重新连接 / 检查账号",_boot])
	_show(status_text+"\n"+_summary(head.get("current"),"账号云存档"),choices)

func _continue_current() -> void:
	if member_id.is_empty(): _resume();return
	var generation:=_epoch
	var session: Dictionary=await _request("session",{})
	if generation!=_epoch: return
	var user: Variant=session.get("data",{}).get("user")
	if not session.get("ok",false) or not user is Dictionary or str(user.get("id",""))!=member_id: _failure({"error":"请重新登录后继续账号进度。"});return
	if head.get("current")==null: _show("账号尚未建立云存档。",[["开始新的校园故事",_start_fresh]]);return
	_resume()

func _confirm_restore(snapshot: Dictionary) -> void:
	_show("恢复这份备份？当前主进度会转为上一份备份。\n"+_summary(snapshot,"选择的备份"),[["确认恢复",_restore.bind(snapshot)],["取消",show_manager]])

func _restore(snapshot: Dictionary) -> void:
	if _busy: return
	var generation:=_epoch
	_busy=true;_show("正在校验备份内容…")
	var prepared: Dictionary=await _download(snapshot)
	if generation!=_epoch: return
	if not prepared.get("ok",false): _busy=false;_failure(prepared);return
	var result: Dictionary=await _request("restore",{"owner":member_id,"input":{"expectedMemberId":member_id,"expectedRevision":head.revision,"operationId":_id(),"snapshotId":snapshot.id}})
	if generation!=_epoch: return
	if result.get("ok",false): head=result.data;await _install(prepared.prepared)
	else: _failure(result)
	if generation!=_epoch: return
	_busy=false

func _export() -> void:
	var raw_path:=State.SAVE_PATH
	if not State.persistence_ready:
		for candidate: String in [State.SAVE_PATH,State.BACKUP_PATH]:
			if not FileAccess.file_exists(candidate): continue
			var probe:=FileAccess.open(candidate,FileAccess.READ)
			if probe==null: continue
			var envelope: Variant=JSON.parse_string(probe.get_as_text()) if probe.get_length()<=8*1024*1024 else null
			probe.close()
			if envelope is Dictionary and float(envelope.get("sourceVersion",0))>State.SOURCE_VERSION: raw_path=candidate;break
	if FileAccess.file_exists(raw_path) and (not State.persistence_ready or State._read_native_save(raw_path).is_empty()):
		var handle:=FileAccess.open(raw_path,FileAccess.READ)
		# Export exact original bytes, never a freshly initialized replacement.
		if handle!=null and handle.get_length()<=48*1024*1024:
			JavaScriptBridge.download_buffer(handle.get_buffer(handle.get_length()),"7-55-unreadable-original.json","application/json");handle.close()
		return
	var scene:=get_tree().current_scene
	if scene!=null and scene.get("web_platform")!=null: scene.web_platform.export_save()
	else:
		var path:=Storage.file("portable-export.json")
		if State.export_save(path)==OK: JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),"7-55-save.json","application/json")

func _failure(result: Dictionary,allow_guest: bool=false) -> void:
	if result.get("stale",false): return
	var choices: Array=[["重新连接 / 重试",_retry],["登录 / 注册",_login],["导出本机备份",_export]]
	if int(result.get("status",0))==409: choices.push_front(["比较云端和本机进度",_boot])
	if allow_guest: choices.append(["返回游客入口（账号进度保留）",_use_guest])
	_show(str(result.get("error",result.get("message","存档操作未完成。")))+"\n原存档已保留，不会自动覆盖。",choices)

func _retry() -> void:
	if _busy: return
	var generation:=_epoch
	if not _pending.is_empty() and _dirty:
		await flush()
		if generation!=_epoch: return
		if _dirty and _pending.is_empty(): await flush()
		if generation==_epoch and not _dirty: _resume()
	else: await _boot()

func _login() -> void:
	var portal=JavaScriptBridge.get_interface("__GODOT_755_ACCOUNT__")
	if portal!=null: portal.showAccount()

func _on_transport_notice(arguments: Array) -> void:
	if arguments.size()==1 and str(arguments[0])=="offline" and not member_id.is_empty(): _stop_connection.call_deferred("网络已断开，账号游戏已暂停。")
	else: _check_session.call_deferred()

func _stop_connection(message: String) -> void:
	_epoch+=1;_busy=false;_checking=false
	_failure({"error":message},true)

func _check_session() -> void:
	if _checking or (_busy and member_id.is_empty()): return
	var generation:=_epoch
	_checking=true
	var result: Dictionary=await _request("session",{})
	if generation!=_epoch: return
	_checking=false
	if result.get("stale",false): return
	if not result.get("ok",false):
		if not member_id.is_empty(): _stop_connection("连接无法确认，账号游戏已暂停。")
		return
	var user: Variant=result.get("data",{}).get("user")
	var next_owner:=str(user.id) if user is Dictionary else ""
	if next_owner!=member_id:
		if next_owner.is_empty() and not member_id.is_empty(): _stop_connection("登录已失效或已退出，请重新登录。")
		else: await _boot()
	elif not member_id.is_empty() and not _busy:
		var remote: Dictionary=await _request("head",{"owner":member_id})
		if generation!=_epoch: return
		if not remote.get("ok",false): _stop_connection("云存档连接无法确认，账号游戏已暂停。");return
		if int(remote.data.revision)!=int(head.get("revision",0)): await _boot()

func _process(delta: float) -> void:
	if _cover.visible and not get_tree().paused: _pause()
	if not member_id.is_empty() and _busy:
		_disk_clock+=delta
		if _disk_clock>=0.5: _disk_clock=0;JavaScriptBridge.force_fs_sync()
	_heartbeat+=delta
	if _heartbeat>=15: _heartbeat=0;_check_session()
	if not ready_for_play or member_id.is_empty() or _busy: return
	_document_clock+=delta
	if _document_clock>=1:
		_document_clock=0
		var service=load("res://scripts/data/cc98_store.gd")
		var digest:=FileAccess.get_sha256(service.posts_path)+FileAccess.get_sha256(service.quest_path)
		if not _document_digest.is_empty() and digest!=_document_digest: _mark_dirty()
		_document_digest=digest
	if _dirty:
		_quiet+=delta;_dirty_age+=delta
		if _quiet>=2 or _dirty_age>=10: flush()
