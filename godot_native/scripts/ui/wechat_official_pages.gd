extends RefCounted

const Chrome = preload("res://scripts/ui/wechat_chrome.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")

const PAPER = Color.WHITE
const FEED = Color("ededed")
const INK = Color("191919")
const MUTED = Color("616161")
const LINK = Color("4d6185")
const GREEN = Color("087943")
const LINE = Color("e5e5e5")
const ORDER = ["campus", "tiyi", "campus-life"]
const PROFILE_ICONS = {"campus":"officials", "tiyi":"sport", "campus-life":"lake"}
const PROFILE_COLORS = {"campus":Color("355768"), "tiyi":Color("74513b"), "campus-life":Color("48684e")}

static func name_for(social, account: String) -> String:
	if account == "campus":
		return str(social.campus.name)
	return {"tiyi":"浙大体育与艺术", "campus-life":"紫金港拾光"}[account]

static func items(b, social, account: String) -> Array:
	match account:
		"campus":
			var archive: Array = social.campus_articles()
			if social.can_browse_night_notice(b):
				archive.push_front(social.night_notice())
			return archive
		"tiyi":
			return social.social_copy.tiyi_articles.slice(0, 2)
	return social.social_copy.campus_life_articles

static func avatar(parent: Control, account: String, diameter: int, unread: bool = false) -> void:
	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2.ONE * diameter
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", Ui.box(PROFILE_COLORS[account], Color.TRANSPARENT, 0, roundi(diameter * .5)))
	parent.add_child(badge)
	Chrome.icon(badge, PROFILE_ICONS[account], Rect2(Vector2.ONE * diameter * .22, Vector2.ONE * diameter * .56), PAPER)
	if unread:
		var dot := Panel.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.position = Vector2(diameter - 11, 0)
		dot.size = Vector2(12, 12)
		dot.add_theme_stylebox_override("panel", Ui.box(Color("12b86a"), FEED, 2, 6))
		badge.add_child(dot)

static func _action(parent: Control, text: String, id: String, run: Callable, font_size: int, fill: Color = PAPER, ink: Color = INK) -> Button:
	var action := Button.new()
	action.name = id
	action.text = text
	action.custom_minimum_size.y = 40
	action.mouse_filter = Control.MOUSE_FILTER_PASS
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action.set_meta("phone_button_role", "composite")
	Typography.apply_body(action)
	Ui.apply_button(action, fill, ink, Color.TRANSPARENT, 7, 0, font_size, Vector2(10, 6))
	action.pressed.connect(run)
	parent.add_child(action)
	return action

static func _icon_button(b, root: Control, kind: String, id: String, label: String, x: float, color: Color, run: Callable) -> void:
	var action: Button = b._button(root, "", Rect2(x,5,41,44), run, color, INK, 0, Color.TRANSPARENT)
	action.name = id
	action.tooltip_text = label
	action.accessibility_name = label
	action.set_meta("phone_button_role", "navigation")
	Chrome.icon(action, kind, Rect2(9,10,24,24))

static func _stack(parent: Control, padding: Vector2i, gap: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, padding.x)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding.y)
	parent.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", gap)
	margin.add_child(column)
	return column

static func _open_account(b, social, account: String) -> void:
	social.profile_articles_only = false
	if account == "tiyi":
		b.tiyi_official_open = true
		social.refresh(b)
	else:
		social.open_panel(b, account)

static func _open_article(b, social, account: String, item: Dictionary) -> void:
	social.article = str(item.id)
	social.article_parent = account
	social.official_read[item.id] = true
	social.refresh(b)

static func _account_id(account: String) -> String:
	return {"campus":"WechatCampusAccount", "tiyi":"TiyiOfficialAccount", "campus-life":"WechatLifeAccount"}[account]

static func _unread_count(b, social, account: String) -> int:
	if not social.official_following.get(account, true):
		return 0
	var articles := items(b, social, account)
	return int(not articles.is_empty() and not social.official_read.has(articles[0].id))

static func _familiar(b, social, column: VBoxContainer) -> void:
	social.copy(column, "常看", social.font_size(b, 13), MUTED)
	var accounts := HBoxContainer.new()
	accounts.add_theme_constant_override("separation", 5)
	column.add_child(accounts)
	var following_count := 0
	var unread_count := 0
	for account: String in ORDER:
		if not social.official_following.get(account, true):
			continue
		following_count += 1
		var count := _unread_count(b, social, account)
		unread_count += count
		var details: Dictionary = social.social_copy.official_profiles[account]
		var trigger := _action(accounts, "", _account_id(account), _open_account.bind(b, social, account), 15, FEED)
		trigger.custom_minimum_size.y = 87
		trigger.accessibility_name = name_for(social, account)
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_theme_constant_override("separation", 7)
		trigger.add_child(body)
		body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar(body, account, 50, count > 0)
		social.copy(body, details.short_name, social.font_size(b, 12), MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if following_count == 0:
		social.copy(column, "关注的公众号会显示在这里。", social.font_size(b, 14), MUTED)
	if unread_count > 0 or social.official_mode == "unread":
		var notice_text := "查看全部推文" if social.official_mode == "unread" else "%d 条新通知  ›" % unread_count
		var notice := _action(column, notice_text, "WechatOfficialUnread", func():
			social.official_mode = "feed" if social.official_mode == "unread" else "unread"
			social.scrolls.erase("official:" + social.official_mode)
			social.refresh(b), social.font_size(b, 14), Color("e2e2e2"))
		notice.custom_minimum_size.x = 158
		notice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

static func feed(b, social) -> Control:
	var root: Control = b._base(FEED, b.APP_HEIGHT)
	root.name = "WechatOfficialFeed"
	var mode: String = social.official_mode
	social.header(b, root, "公众号", func():
		if mode == "feed":
			social.open_panel(b, "")
		else:
			social.official_mode = "feed"
			social.refresh(b), "WechatLocalBack", FEED)
	_icon_button(b, root, "search", "WechatOfficialSearch", "搜索公众号和推文", 285, FEED, func():
		social.official_mode = "feed" if mode == "search" else "search"
		social.refresh(b))
	_icon_button(b, root, "me", "WechatOfficialFollowing", "查看关注的公众号", 330, FEED, func():
		social.official_mode = "feed" if mode == "following" else "following"
		social.refresh(b))
	var column: VBoxContainer = social.feed(b, root, 55, 0, "official:" + mode, 10)
	if mode == "search":
		var field := LineEdit.new()
		field.name = "WechatOfficialQuery"
		field.placeholder_text = "搜索公众号或文章"
		field.text = social.official_query
		field.custom_minimum_size.y = 44
		field.clear_button_enabled = true
		field.mouse_filter = Control.MOUSE_FILTER_PASS
		Typography.apply_body(field)
		Ui.apply_input(field, PAPER, INK, LINE, 7, social.font_size(b, 16))
		column.add_child(field)
		var results := VBoxContainer.new()
		results.add_theme_constant_override("separation", 12)
		column.add_child(results)
		field.text_changed.connect(func(value: String):
			social.official_query = value
			_search_results(b, social, results))
		_search_results(b, social, results)
		return root
	if mode == "following":
		social.copy(column, "关注的公众号", social.font_size(b, 16))
		for account: String in ORDER:
			if social.official_following.get(account, true):
				_account_row(b, social, column, account)
		return root
	_familiar(b, social, column)
	for account: String in ORDER:
		if mode == "unread" and _unread_count(b, social, account) == 0:
			continue
		var articles := items(b, social, account)
		var group := PanelContainer.new()
		group.add_theme_stylebox_override("panel", Ui.box(PAPER, Color.TRANSPARENT, 0, 8))
		group.clip_contents = true
		group.mouse_filter = Control.MOUSE_FILTER_PASS
		column.add_child(group)
		var entries := VBoxContainer.new()
		entries.add_theme_constant_override("separation", 1)
		group.add_child(entries)
		_account_row(b, social, entries, account, str(articles[0].get("publishedAt", "")))
		_article_row(b, social, entries, account, articles[0], "WechatFeedArticle_", true)
		if mode == "feed" and articles.size() > 1:
			_article_row(b, social, entries, account, articles[1], "WechatFeedArticle_")
	return root

static func _account_row(b, social, column: VBoxContainer, account: String, date: String = "") -> void:
	var row := Chrome.conversation(column, name_for(social, account), "", date, 1.0)
	row.name = "WechatFeedAccount_" + account
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.pressed.connect(_open_account.bind(b, social, account))
	row.find_child("ConversationPreview", true, false).hide()
	var badge_slot := row.find_child("AvatarSlot", true, false) as Control
	avatar(badge_slot, account, 40)
	badge_slot.get_child(0).position = Vector2(4, 4)

static func _search_results(b, social, results: VBoxContainer) -> void:
	for child in results.get_children():
		results.remove_child(child)
		child.queue_free()
	var query: String = social.official_query.strip_edges().to_lower()
	for account: String in ORDER:
		var name := name_for(social, account)
		if query.is_empty() or query in name.to_lower():
			_account_row(b, social, results, account)
		for item: Dictionary in items(b, social, account):
			if not query.is_empty() and (query in name.to_lower() or query in str(item.title).to_lower() or query in str(item.get("summary","")).to_lower()):
				_article_row(b, social, results, account, item, "WechatFeedArticle_")
	if results.get_child_count() == 0:
		social.copy(results, "没有找到相关的公众号或文章。", social.font_size(b, 15), MUTED)

static func _article_row(b, social, column: VBoxContainer, account: String, item: Dictionary, prefix: String, lead: bool = false) -> void:
	var id := str(item.id)
	var trigger := _action(column, "", prefix + id, _open_article.bind(b, social, account, item), 16)
	trigger.accessibility_name = str(item.title)
	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 0)
	trigger.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art: TextureRect = social.article_cover(item, Vector2(0, 156) if lead else Vector2(68, 48))
	if lead and art.texture:
		body.add_child(art)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	var details := _stack(body, Vector2i(14, 11), 4)
	details.add_child(row)
	var caption := VBoxContainer.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	social.copy(caption, str(item.title), social.font_size(b, 19 if lead else 16), INK)
	if lead and item.has("summary"):
		social.copy(caption, str(item.summary), social.font_size(b, 13), MUTED)
	var reading := str(item.get("readCount", ""))
	if lead and not reading.is_empty():
		social.copy(caption, "阅读 " + reading, social.font_size(b, 12), MUTED)
	if not lead and art.texture:
		art.size_flags_horizontal = Control.SIZE_SHRINK_END
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(art)
	if art.get_parent() == null:
		art.free()
	body.minimum_size_changed.connect(func(): trigger.custom_minimum_size.y = maxf(44, body.get_combined_minimum_size().y))
	trigger.custom_minimum_size.y = maxf(44, body.get_combined_minimum_size().y)

static func profile_intro(b, social, column: VBoxContainer, account: String) -> void:
	var profile: Dictionary = social.social_copy.official_profiles[account]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	column.add_child(row)
	avatar(row, account, 68)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(identity)
	social.copy(identity, name_for(social, account), social.font_size(b, 23), INK)
	social.copy(identity, str(profile.meta), social.font_size(b, 13), MUTED)
	social.copy(column, str(profile.intro), social.font_size(b, 16), INK)
	social.copy(column, "%d 篇文章" % items(b, social, account).size(), social.font_size(b, 13), MUTED)
	var following: bool = social.official_following.get(account, true)
	_action(column, "已关注公众号" if following else "关注公众号", "WechatProfileFollow", func():
		social.official_following[account] = not following
		social.refresh(b), social.font_size(b, 16), FEED)

static func profile_articles(b, social, column: VBoxContainer, account: String) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	column.add_child(tabs)
	for tab: String in ["all", "articles"]:
		var selected: bool = (tab == "articles") == social.profile_articles_only
		var button := _action(tabs, "全部" if tab == "all" else "文章", "WechatProfileTab_" + tab, func():
			social.profile_articles_only = tab == "articles"
			social.refresh(b), social.font_size(b, 15), FEED if selected else PAPER, INK if selected else MUTED)
		button.set_meta("phone_button_selected", selected)
	var articles := items(b, social, account)
	if not social.profile_articles_only:
		social.copy(column, "置顶", social.font_size(b, 15), INK)
	for index in articles.size():
		_article_row(b, social, column, account, articles[index], "WechatArticle_", index == 0 and not social.profile_articles_only)
