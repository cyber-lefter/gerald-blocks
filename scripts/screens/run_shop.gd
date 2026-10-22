class_name RunShop
extends Control
## Between rounds: spend gold on monster jokers (kept for the run) and toad snacks (one use each).

var router
var list: VBoxContainer
var gold_label: Label
var reroll_btn: Button
var c_panel := Color("3a3028")
var c_muted := Color("a09480")
var c_gold := Color("f0d060")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Run.offers.is_empty():
		open_shop()
	var col := Screens.frame(self, "The toad's shop", func() -> void: router.show_menu())
	gold_label = UI.label("", 44, c_gold, 10)
	col.add_child(gold_label)
	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	col.add_child(buttons)
	reroll_btn = UI.button("", c_panel, 30, 100)
	reroll_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll_btn.pressed.connect(_reroll)
	buttons.add_child(reroll_btn)
	var next := UI.button("Next round", Color("6a8a3a"), 34, 100)
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.pressed.connect(func() -> void:
		Run.offers = []
		Run.rerolls = 0
		Run.store()
		router.start_game("run"))
	buttons.add_child(next)
	_rebuild()


## Offers come from a generator seeded by the run, so leaving and coming back shows the same shop.
static func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d-%d-%d-%s" % [Run.round_n, Run.rerolls, Run.total, ",".join(PackedStringArray(Run.jokers))])
	return rng


## Rolls the offers for the coming round. While offers exist the run is "in the shop", so Continue comes back here.
static func open_shop() -> void:
	Run.offers = Jokers.roll_offers(_rng(), Run.jokers)
	Run.rerolls = 0
	Run.store()


func go_back() -> void:
	router.show_menu()


func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()
	gold_label.text = "%d gold" % Run.gold
	reroll_btn.text = "Reroll (%d gold)" % Run.reroll_cost()
	reroll_btn.disabled = Run.gold < Run.reroll_cost()

	list.add_child(_heading("For sale"))
	var any := false
	for k in Run.offers.size():
		var id: String = Run.offers[k]
		if id == "":
			continue
		any = true
		var price := int(Jokers.info(id)["price"])
		var full := (Jokers.is_snack(id) and Run.snacks.size() >= Jokers.MAX_SNACKS) or (not Jokers.is_snack(id) and Run.jokers.size() >= Jokers.MAX_JOKERS)
		var label := "Full" if full else "%d gold" % price
		var slot := k
		list.add_child(_row(id, label, Color("a0603a"), not full and Run.gold >= price, func() -> void: _buy(slot)))
	if not any:
		list.add_child(_note("Sold out. Reroll for more."))

	list.add_child(_heading("Your monsters (%d/%d)" % [Run.jokers.size(), Jokers.MAX_JOKERS]))
	if Run.jokers.is_empty():
		list.add_child(_note("None yet. Monsters stay with you for the whole run."))
	for id in Run.jokers.duplicate():
		var jid: String = id
		list.add_child(_row(jid, "Sell +%d" % _sell_price(jid), c_panel, true, func() -> void: _sell(jid)))

	list.add_child(_heading("Snacks (%d/%d)" % [Run.snacks.size(), Jokers.MAX_SNACKS]))
	if Run.snacks.is_empty():
		list.add_child(_note("Snacks are used once, from the buttons under the board."))
	for id in Run.snacks:
		list.add_child(_row(id, "", c_panel, false, Callable()))


static func _sell_price(id: String) -> int:
	return maxi(1, int(Jokers.info(id)["price"]) / 2)


func _buy(slot: int) -> void:
	var id: String = Run.offers[slot]
	var price := int(Jokers.info(id)["price"])
	if Run.gold < price:
		return
	Run.gold -= price
	if Jokers.is_snack(id):
		Run.snacks.append(id)
	else:
		Run.jokers.append(id)
	Run.offers[slot] = ""
	Run.store()
	Sfx.play("coin")
	Sfx.vibrate(20, false, 0.5)
	_rebuild()


func _sell(id: String) -> void:
	Run.jokers.erase(id)
	Run.gold += _sell_price(id)
	Run.store()
	Sfx.play("drop")
	_rebuild()


func _reroll() -> void:
	var cost := Run.reroll_cost()
	if Run.gold < cost:
		return
	Run.gold -= cost
	Run.rerolls += 1
	Run.offers = Jokers.roll_offers(_rng(), Run.jokers)
	Run.store()
	Sfx.play("power")
	_rebuild()


func _heading(text: String) -> Label:
	var l := UI.label(text, 32, Color.WHITE, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


func _note(text: String) -> Label:
	var l := UI.label(text, 24, c_muted)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## One card: the monster, its name and what it does, and a button (buy, sell, or none).
func _row(id: String, btn_text: String, btn_color: Color, enabled: bool, on_press: Callable) -> PanelContainer:
	var info := Jokers.info(id)
	var card := PanelContainer.new()
	var sb := UI.panel_style(Color("2a241c"), 26)
	sb.border_color = UI.INK
	sb.set_border_width_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	card.add_child(h)
	var icon := JokerIcon.new()
	icon.id = id
	icon.custom_minimum_size = Vector2(96, 96)
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var name_l := UI.label(str(info["name"]) + ("  (snack)" if Jokers.is_snack(id) else ""), 30, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name_l)
	var desc := UI.label(str(info["desc"]), 23, c_muted)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	if btn_text != "":
		var b := UI.button(btn_text, btn_color, 26, 80)
		b.custom_minimum_size = Vector2(150, 80)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = not enabled
		b.pressed.connect(on_press)
		h.add_child(b)
	return card


class JokerIcon extends Control:
	var id := ""
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		Jokers.draw_icon(self, id, size / 2.0, minf(size.x, size.y) * 0.42, t)
