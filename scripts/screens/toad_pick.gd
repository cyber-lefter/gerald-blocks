class_name ToadPick
extends Control
## Before a new run: pick which toad sleeps tonight. Locked toads show what unlocks them.

var router


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Screens.frame(self, "Choose your toad", func() -> void: router.show_menu())
	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for id in Meta.TOADS:
		list.add_child(_card(id))


func go_back() -> void:
	router.show_menu()


func _card(id: String) -> PanelContainer:
	var info: Dictionary = Meta.TOADS[id]
	var open := Meta.toad_unlocked(id)
	var card := PanelContainer.new()
	var sb := UI.panel_style(Color("2a241c"), 26)
	sb.border_color = UI.INK
	sb.set_border_width_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	var pic := ToadPortrait.new()
	pic.custom_minimum_size = Vector2(150, 110)
	pic.skin = Color(str(info["color"]))
	pic.hat = Meta.hat()
	pic.dim = not open
	h.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var name_l := UI.label(str(info["name"]) if open else "Locked toad", 30, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name_l)
	var d := UI.label(str(info["desc"]) if open else Meta.req_text(info["req"]), 23, Color("a09480") if open else Color("e0a040"))
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var b := UI.button("Play" if open else "Locked", Color("6a8a3a") if open else Color("3a3028"), 28, 80)
	b.custom_minimum_size = Vector2(130, 80)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not open
	b.pressed.connect(func() -> void:
		Run.start_new(id)
		router.start_game("run"))
	h.add_child(b)
	return card
