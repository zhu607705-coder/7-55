extends SceneTree
## Actual Main/input integration. Fixtures never replace the earned manual save.
const Art = preload("res://scripts/ui/native_zjuding_loading_art.gd")
var shell: Control
var state: Node
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("PHONE LOADING/NOTICE: "+message)
func find_named(node: Node, target: String) -> Node:
	if node.name == target: return node
	for child: Node in node.get_children():
		var found := find_named(child, target)
		if found != null: return found
	return null
func click(button: Control) -> void:
	check(button != null,"real pointer target exists")
	if button == null: return
	var point := button.get_global_transform_with_canvas()*(button.size/2)
	var motion := InputEventMouseMotion.new(); motion.position=point; root.push_input(motion)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event)
	await frames()
func fixture(network: String="campus_wifi",percent: int=100) -> void:
	shell.audio_director.reset(); shell.battery_prank.reset()
	state.d=state.initial(); state.developer_mode=true; state.d.native.page="phone_home"
	state.d.networkMode=network; state.d.phoneBattery.percent=percent
	shell._refresh(); await frames()
func tick(milliseconds: float) -> void:
	shell._process(milliseconds/1000.0); await frames()
func contained(inner: Rect2,outer: Rect2) -> bool:
	return outer.grow(0.1).encloses(inner)
func check_loading_art() -> void:
	var art: Control=find_named(shell.page_body,"ZjudingLoadingArt")
	check(art!=null,"blocked/accepted loading mounts decorative cropped art")
	if art==null: return
	var fitted: Rect2=art.fitted_art_rect()
	check(is_equal_approx(fitted.size.x/Art.SOURCE_REGION.size.x,fitted.size.y/Art.SOURCE_REGION.size.y),"source art keeps uniform aspect ratio")
	check(fitted.grow(0.1).encloses(Rect2(Vector2.ZERO,art.size)),"cropped blue art covers the app without gaps")
	check(Art.SOURCE_REGION.position.y>=224 and Art.SOURCE_REGION.end.y<=1632,"crop excludes baked status/back/ellipsis/home indicator")
	check(art.clip_contents and art.mouse_filter==Control.MOUSE_FILTER_IGNORE,"decorative art is clipped and never owns input")
	check(art.material is ShaderMaterial,"baked-dot mask belongs only to decorative source art")
	var native_dots: Array=art.get_parent().get_children().filter(func(node): return str(node.name).begins_with("EntryLoadingDot"))
	var expected: int=3
	check(native_dots.size()==expected,"one native three-dot indicator is live for both accepted and blocked loading")
	check(shell.phone_chrome.time_label.text=="07:55","real phone clock remains07:55")
func check_notice_geometry() -> void:
	var prank: Control=shell.battery_prank
	var card: Control=prank.panel
	var phone_rect: Rect2=shell.phone.get_global_rect()
	var status_rect: Rect2=shell.phone_chrome.status_bar.get_global_rect()
	check(prank.visible and not prank.notice.text.is_empty(),"reserve warning is visible with its complete text")
	check(contained(card.get_global_rect(),phone_rect),"notice card remains inside phone at current scale")
	check(card.position.y>=112,"notice clears status and app navigation")
	check(card.get_global_rect().position.y>status_rect.end.y,"notice does not overlap actual chrome bounds")
	check(prank.z_index>shell.phone_chrome.pixel_grid.z_index,"notice text is not painted behind chrome/grid")
	check(contained(prank.notice.get_global_rect(),card.get_global_rect()),"wrapped source notice fits its card")
	check(prank.notice.get_line_count()==prank.notice.get_visible_line_count(),"all countdown lines are visible")
	check(prank.mouse_filter==Control.MOUSE_FILTER_IGNORE and card.mouse_filter==Control.MOUSE_FILTER_IGNORE and prank.notice.mouse_filter==Control.MOUSE_FILTER_IGNORE,"notice remains pointer transparent")
	check(shell.phone.size==Vector2(430,860),"notice never resizes canonical phone")
	check(prank.scale==shell.phone.scale,"notice uses Main's single phone scale")
func run() -> void:
	var source: Image=Art.ART.get_image()
	check(source.get_size()==Vector2i(941,1672),"mask coordinates match actual checked-in source dimensions")
	var pale_baked := 0
	var pale_replacement := 0
	for y in range(int(Art.BAKED_DOT_REGION.position.y),int(Art.BAKED_DOT_REGION.end.y)):
		for x in range(int(Art.BAKED_DOT_REGION.position.x),int(Art.BAKED_DOT_REGION.end.x)):
			var original:=source.get_pixel(x,y)
			if minf(original.r,minf(original.g,original.b))>.6: pale_baked+=1
			var clean:=source.get_pixel(x+int(Art.CLEAN_DOT_OFFSET.x),y)
			if minf(clean.r,minf(clean.g,clean.b))>.06: pale_replacement+=1
	check(pale_baked>4000,"actual source has five baked dot marks in calibrated mask bounds")
	check(pale_replacement==0,"neighboring source pixels are clean blue art, with no copied controls/dots")
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=viewport; shell.size=Vector2(viewport); await frames()
		await fixture("cellular")
		await click(find_named(shell.page_body,"HomeApp_zjuding"))
		check(state.d.native.page=="zjuding","real home click enters Zjuding")
		check_loading_art()
		await tick(2999)
		check(find_named(shell.page_body,"ZjudingReentryHint")==null,"blocked hint remains gated before3000ms")
		await tick(1)
		var hint: Control=find_named(shell.page_body,"ZjudingReentryHint")
		var exit_button: Control=find_named(shell.page_body,"ZjudingLoadingExit")
		check(hint!=null,"blocked hint appears at3000ms")
		check(hint.get_global_rect().end.y<=exit_button.get_global_rect().position.y,"hint and exit remain separate")
		check_loading_art()
		await click(exit_button)
		check(state.d.native.page=="phone_home","real exit remains clickable through art")
		await fixture()
		await click(find_named(shell.page_body,"HomeApp_zjuding"))
		check_loading_art()
		await tick(1499)
		check(state.get_phone_entry_session().phase=="loading","accepted entry stays loading before1500ms")
		await tick(1)
		check(state.get_phone_entry_session().phase=="ready" and find_named(shell.page_body,"ZjudingLoadingArt")==null,"accepted entry opens at1500ms")
		await fixture("campus_wifi",1)
		await click(find_named(shell.page_body,"HomeApp_wechat"))
		var prank: Control=shell.battery_prank
		check(state.d.native.page=="wechat" and prank.used,"real WeChat entry at1percent triggers owned prank")
		check_notice_geometry()
		var deadline: int=prank.deadline
		check(prank.view(deadline-10000).seconds==10 and prank.view(deadline-1).seconds==1,"source countdown spans exact10000ms")
		check(prank.view(deadline).kind=="joke" and prank.view(deadline).text=="吓吓你的","source punchline starts at deadline unchanged")
		check(prank.view(deadline+3499).kind=="joke" and prank.view(deadline+3500).is_empty(),"source punchline lasts exact3500ms")
		await click(find_named(shell.page_body,"WechatFriendAvatar"))
		check(state.get_phone_entry_session().friend_open,"notice allows real app input underneath")
		check(prank.deadline==deadline,"page navigation never restarts prank")
		await fixture("campus_wifi",1)
		await click(find_named(shell.page_body,"HomeApp_wechat"))
		deadline=prank.deadline; prank.consume_reserve(1)
		check(prank.deadline==deadline,"duplicate reserve event never stacks warning")
		state.d.phoneBattery.percent=45; prank._process(0); await frames()
		check(not prank.visible and prank.deadline==-1 and not prank.used,"recharge cancels and rearms source prank")
	# Main's landscape destination remains a bounded top-left notice.
	var prank: Control=shell.battery_prank
	prank.size=Vector2(960,540); await frames()
	check(prank.panel.position==Vector2(20,20) and prank.panel.size.x==360,"world notice retains20px source offset and bounded width")
	check(contained(prank.panel.get_rect(),Rect2(Vector2.ZERO,prank.size)),"world card remains contained")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Phone loading/notice layout: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
