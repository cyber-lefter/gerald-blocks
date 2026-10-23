class_name WardrobeScreen
extends Control
## Hats for the toad. Earned across runs; the one he wears shows everywhere he sleeps.

var router
var preview: ToadPortrait
var list: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Screens.frame(self, "Wardrobe", func() -> void: router.show_menu())
	preview = ToadPortrait.new()
	preview.custom_minimum_size = Vector2(0, 260)
	preview.hat = Meta.hat()
	col.add_child(preview)
	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	_rebuild()


func go_back() -> void:
	router.show_menu()


func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()
	for id in Meta.HATS:
		list.add_child(_row(id))


func _row(id: String) -> PanelContainer:
	var info: Dictionary = Meta.HATS[id]
	var open := Meta.hat_unlocked(id)
	var wearing := Meta.hat() == id
	var card := PanelContainer.new()
	var sb := UI.panel_style(Color("2a241c"), 26)
	sb.border_color = Color("f0d060") if wearing else UI.INK
	sb.set_border_width_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	var pic := ToadPortrait.new()
	pic.custom_minimum_size = Vector2(120, 90)
	pic.hat = id
	pic.dim = not open
	h.add_child(pic)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var name_l := UI.label(str(info["name"]), 30, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name_l)
	if not open:
		var d := UI.label(Meta.req_text(info["req"]), 23, Color("e0a040"))
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
	var b := UI.button("Wearing" if wearing else ("Wear" if open else "Locked"), Color("6a8a3a") if open and not wearing else Color("3a3028"), 26, 72)
	b.custom_minimum_size = Vector2(130, 72)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not open or wearing
	b.pressed.connect(func() -> void:
		Meta.set_hat(id)
		preview.hat = id
		Sfx.play("coin")
		_rebuild())
	h.add_child(b)
	return card
