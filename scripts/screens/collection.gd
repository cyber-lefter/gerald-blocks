class_name CollectionScreen
extends Control
## Every monster in the game: the ones found so far in colour, the rest as shadows,
## and locked ones with what earns them. Tap one to read about it. Lifetime stats below.

var router
var detail_name: Label
var detail_desc: Label
var detail_icon: RunShop.JokerIcon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Legendaries stay out of the list (and the count) until one has been found.
	var found := 0
	var total := 0
	for id in Jokers.JOKERS:
		if _hidden(id):
			continue
		total += 1
		if Meta.is_seen(id):
			found += 1
	var col := Screens.frame(self, "Collection", func() -> void: router.show_menu())
	col.add_child(UI.label("Monsters found: %d of %d" % [found, total], 30, Color("f0d060")))

	# The tapped monster.
	var card := PanelContainer.new()
	var sb := UI.panel_style(Color("2a241c"), 26)
	sb.border_color = UI.INK
	sb.set_border_width_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(0, 130)
	col.add_child(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	card.add_child(h)
	detail_icon = RunShop.JokerIcon.new()
	detail_icon.custom_minimum_size = Vector2(100, 100)
	h.add_child(detail_icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	detail_name = UI.label("Tap a monster", 30, Color.WHITE)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(detail_name)
	detail_desc = UI.label("", 23, Color("a09480"))
	detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(detail_desc)

	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 16)
	scroll.add_child(inner)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	inner.add_child(grid)
	for id in Jokers.JOKERS:
		if not _hidden(id):
			grid.add_child(_cell(id))

	inner.add_child(UI.label("Your toad's records", 30, Color.WHITE, 8))
	var stats := [["Runs played", "runs"], ["Runs won", "wins"], ["Best night", "best_night"], ["Rounds won", "rounds_won"],
		["Heroes squashed", "squashed"], ["Bosses beaten", "bosses"], ["Lines cleared", "lines"], ["Gold earned", "gold"],
		["Best endless night", "endless_best"], ["Squash mode best", "squash_best"]]
	for st in stats:
		var row := HBoxContainer.new()
		var a := UI.label(st[0], 24, Color("a09480"))
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(a)
		row.add_child(UI.label(UI.fmt(Meta.stat(st[1])), 26, Color.WHITE))
		inner.add_child(row)


static func _hidden(id: String) -> bool:
	return Jokers.rarity(id) == Jokers.LEGENDARY and not Meta.is_seen(id)


func go_back() -> void:
	router.show_menu()


func _cell(id: String) -> Control:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(118, 118)
	var icon := RunShop.JokerIcon.new()
	icon.id = id
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(icon)
	var locked := not Meta.monster_unlocked(id)
	var seen := Meta.is_seen(id)
	if locked or not seen:
		# A shadow: the shape shows, the colours don't.
		icon.modulate = Color(0, 0, 0, 0.75) if not locked else Color(0, 0, 0, 0.45)
	if locked:
		var lock := UI.label("?", 44, Color(1, 1, 1, 0.5))
		lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lock)
	b.pressed.connect(func() -> void: _show(id))
	return b


func _show(id: String) -> void:
	var info: Dictionary = Jokers.JOKERS[id]
	detail_icon.id = id
	if not Meta.monster_unlocked(id):
		detail_icon.modulate = Color(0, 0, 0, 0.45)
		detail_name.text = "Locked monster"
		detail_desc.text = "Unlock: " + Meta.req_text(Meta.MONSTER_REQ[id])
	elif not Meta.is_seen(id):
		detail_icon.modulate = Color(0, 0, 0, 0.75)
		detail_name.text = "Not found yet"
		detail_desc.text = "A %s monster. Keep an eye on the shop." % Jokers.RARITY_NAMES[Jokers.rarity(id)].to_lower()
	else:
		detail_icon.modulate = Color.WHITE
		detail_name.text = str(info["name"])
		detail_desc.text = "%s monster. %s. Lv 3: %s." % [Jokers.RARITY_NAMES[Jokers.rarity(id)], Jokers.desc(id, 1), Jokers.desc(id, 3)]
