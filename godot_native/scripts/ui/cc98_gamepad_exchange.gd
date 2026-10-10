extends RefCounted
## Source: P02_CC98/ControlExchangePuzzle.tsx and cc98-control-exchange CSS.
## This surface only renders state and emits the existing chapter intents.
const SOURCE = preload("res://scripts/data/cc98_store.gd")

func build(b, view: Dictionary) -> Control:
	var source: Dictionary = SOURCE.source("act-one-bootstrap.content")
	var post: Dictionary = view.get("post", source.cc98ExchangePost)
	var purchased: bool = b.s.actOne.gamepadPurchased
	var balance: String = "¥%.2f" % (maxi(0, int(b.s.wallet.campusCardCents)) / 100.0)
	var root: Control = b._base(Color("f2f3f5"), b.APP_HEIGHT)
	root.name = "Cc98GamepadExchange"
	root.set_meta("handles_all_actions", true)
	b._panel(root, Rect2(0, 0, 378, 57), Color("297b9b"))
	b._label(root, "CC98", Rect2(17, 4, 154, 48), 33, Color.WHITE)
	b._label(root, "热门话题　　校园生活　　二手市场", Rect2(13, 67, 352, 36), 15, Color("457d94"), HORIZONTAL_ALIGNMENT_CENTER)
	b._panel(root, Rect2(0, 111, 378, 3), Color("50a0b5"))
	# Long or edited post text scrolls inside the app. The transaction stays visible.
	var scroll := ScrollContainer.new()
	scroll.name = "Cc98GamepadScroll"
	scroll.position = Vector2(0, 115)
	scroll.size = Vector2(378, b.APP_HEIGHT - 213)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	scroll.add_child(margin)
	var feed := VBoxContainer.new()
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed.add_theme_constant_override("separation", 12)
	margin.add_child(feed)
	var article := _box(b, feed, Color("d1d6dc"), 1)
	_text(article, str(post.get("author", "手柄毕业生")) + "　·　" + str(post.get("board", "二手市场")), 14, Color("2e88a7"))
	_text(article, str(post.get("title", source.cc98ExchangePost.title)), 21, b.INK).name = "Cc98GamepadPostTitle"
	_text(article, str(post.get("body", source.cc98ExchangePost.body)), 16, b.INK).name = "Cc98GamepadPostBody"
	_text(article, "%s 回复　%s 浏览　%s" % [post.get("replies", "19"), post.get("views", "982"), post.get("time", "07:55")], 12, b.MUTED)
	var card := _box(b, feed, Color("1f713d") if purchased else Color("174d9d"), 3)
	card.get_parent().name = "Cc98GamepadProduct"
	_preview(b, card)
	_row(b, card, "商品", "二手游戏手柄 × 1")
	_row(b, card, "售价", "¥6.00，不议价")
	_row(b, card, "你的余额", balance, Color("1f713d") if int(b.s.wallet.campusCardCents) >= 600 else Color("b32424")).name = "Cc98GamepadBalance"
	var identity_readable: bool = b.s.actOne.inventoryRecovered and b.s.items.campusCard
	_row(b, card, "收货人", "%s · %s" % [source.studentName, source.studentId] if identity_readable else "身份信息尚未读取").name = "Cc98GamepadRecipient"
	b._panel(root, Rect2(0, b.APP_HEIGHT - 98, 378, 98), Color.WHITE, Color("ccd2d9"), 0, 1)
	var status: String = "支付成功：游戏手柄已放入道具栏。" if purchased else "售价 ¥6.00，不议价　·　你的余额 " + balance
	if purchased and b.s.actOne.controlsInstalled: status = "手柄已经连接。"
	b._label(root, status, Rect2(12, b.APP_HEIGHT - 93, 354, 30), 14, Color("1f713d") if purchased else b.MUTED, HORIZONTAL_ALIGNMENT_CENTER).name = "Cc98GamepadFeedback"
	var action: String = "c2_enter_dorm" if purchased else "c2_purchase_gamepad"
	var caption: String = "回寝室试用手柄" if purchased else str(source.cc98ExchangePost.action)
	var button: Button = b._act(root, caption, Rect2(12, b.APP_HEIGHT - 57, 354, 48), action, null, Color("2165ae"), Color.WHITE, 0, Color("123f70"))
	button.name = "Cc98GamepadReturn" if purchased else "Cc98GamepadPurchase"
	button.add_theme_font_size_override("font_size", 17)
	return root

func _box(b, parent: Control, border: Color, width: int) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = b._style(Color.WHITE, border, 0, width)
	style.content_margin_left = 11; style.content_margin_right = 11
	style.content_margin_top = 11; style.content_margin_bottom = 11
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	return content

func _text(parent: Control, value: String, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ink)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _row(b, parent: Control, title: String, value: String, ink: Color = Color("222322")) -> Label:
	var panel := PanelContainer.new()
	var style: StyleBoxFlat = b._style(Color.WHITE, Color("ccd2d9"), 0, 2)
	style.content_margin_left = 8; style.content_margin_right = 8
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var key := _text(row, title, 14, Color("174d9d"))
	key.custom_minimum_size.x = 62
	key.size_flags_horizontal = Control.SIZE_FILL
	return _text(row, value, 15, ink)

func _preview(b, parent: Control) -> void:
	var preview := PanelContainer.new()
	preview.name = "Cc98GamepadIllustration"
	preview.custom_minimum_size.y = 84
	preview.add_theme_stylebox_override("panel", b._style(Color("20272f"), Color("0c1218"), 0, 3))
	parent.add_child(preview)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(holder)
	var pad := Control.new()
	pad.name = "Cc98GamepadDrawing"
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pad.position = Vector2(-98, -30)
	pad.size = Vector2(196, 60)
	b._panel(pad, Rect2(0, 4, 34, 54), Color("e8edf1"), Color("78838e"), 4, 3)
	b._panel(pad, Rect2(162, 4, 34, 54), Color("e8edf1"), Color("78838e"), 4, 3)
	b._panel(pad, Rect2(34, 0, 128, 54), Color("e8edf1"), Color("78838e"), 0, 3)
	b._label(pad, "＋", Rect2(43, 11, 31, 31), 26, Color("17212a"), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(2):
		b._panel(pad, Rect2(85 + i * 36, 15, 25, 25), Color("f0d54e"), Color("8b6a09"), 0, 2)
		b._label(pad, "A" if i == 0 else "B", Rect2(85 + i * 36, 15, 25, 25), 15, Color("17212a"), HORIZONTAL_ALIGNMENT_CENTER)
