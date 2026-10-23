class_name RunShop
extends Control
## Between rounds: spend gold on monster jokers (kept and levelled up for the run), line totems
## (level up a kind of clear, no cap), toad snacks (one use each), mystery sacks and charms.

var router
var list: VBoxContainer
var gold_label: Label
var reroll_btn: Button
var next_btn: Button
var c_panel := Color("3a3028")
var c_muted := Color("a09480")
var c_gold := Color("f0d060")
var c_buy := Color("a0603a")


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
	next_btn = UI.button("Next round", Color("6a8a3a"), 34, 100)
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_btn.pressed.connect(func() -> void:
		Run.offers = []
		Run.rerolls = 0
		Run.sack = []
		Run.store()
		router.start_game("run"))
	buttons.add_child(next_btn)
	_rebuild()


## Offers come from a generator seeded by the run, so leaving and coming back shows the same shop.
static func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d-%d-%d-%s" % [Run.round_n, Run.rerolls, Run.total, ",".join(PackedStringArray(Run.jokers))])
	return rng


## Rolls the offers for the coming round. While offers exist the run is "in the shop", so Continue comes back here.
static func open_shop() -> void:
	Run.offers = Jokers.roll_offers(_rng(), Run.jokers, Run.jlevels, Run.charms, Run.toad)
	Run.rerolls = 0
	Run.sack = []
	_mark_seen()
	Run.store()


## After a boss: the shop opens with a pick of two rare monsters, free.
static func open_boss_drop() -> void:
	var rng := _rng()
	rng.seed += 77
	Run.sack = Jokers.roll_boss_drop(rng, Run.jokers, Run.jlevels)
	Run.sack_kind = "boss"
	for o in Run.sack:
		Meta.mark_seen(o)
	Run.store()


static func _mark_seen() -> void:
	for o in Run.offers:
		Meta.mark_seen(o)


func go_back() -> void:
	router.show_menu()


func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()
	gold_label.text = "%d gold" % Run.gold
	reroll_btn.text = "Reroll (%d gold)" % Run.reroll_cost()
	reroll_btn.disabled = Run.gold < Run.reroll_cost() or not Run.sack.is_empty()

	if not Run.sack.is_empty():
		# An open sack: pick one monster (or leave them all) before shopping on.
		list.add_child(_heading("Boss drop: pick one, free" if Run.sack_kind == "boss" else "Mystery Sack: pick one"))
		for k in Run.sack.size():
			var offer: String = Run.sack[k]
			var why := Run.blocked(offer)
			var slot := k
			list.add_child(_offer_row(offer, "Take" if why == "" else why, Color("6a8a3a"), why == "", func() -> void: _pick(slot)))
		var skip := UI.button("Leave them", c_panel, 28, 80)
		skip.pressed.connect(func() -> void:
			Run.sack = []
			Run.store()
			_rebuild())
		list.add_child(skip)
		if Run.jokers.size() >= Run.max_jokers():
			# A full den shouldn't waste the pick: sell one here to make room.
			list.add_child(_heading("Your den is full"))
			list.add_child(_note("Sell a monster to make room, then take one above."))
			_add_owned_monsters()
		return

	list.add_child(_heading("For sale"))
	var any := false
	for k in Run.offers.size():
		var offer: String = Run.offers[k]
		if offer == "":
			continue
		any = true
		var price := Run.price(offer)
		var why := Run.blocked(offer)
		var slot := k
		list.add_child(_offer_row(offer, why if why != "" else "%d gold" % price, c_buy, why == "" and Run.gold >= price, func() -> void: _buy(slot)))
	if not any:
		list.add_child(_note("Sold out. Reroll for more."))

	list.add_child(_heading("Your monsters (%d/%d)" % [Run.jokers.size(), Run.max_jokers()]))
	if Run.jokers.is_empty():
		list.add_child(_note("None yet. Monsters stay for the whole run. Buy one again to level it up."))
	_add_owned_monsters()

	if not Run.totems.is_empty():
		list.add_child(_heading("Your totems"))
		for id in Jokers.TOTEMS:
			if Run.totem(id) > 0:
				var info: Dictionary = Jokers.TOTEMS[id]
				list.add_child(_row(id, "%s  Lv %d" % [info["name"], Run.totem(id)], "Totem", Color("8fb04a"),
					"%s: +%d points" % [info["desc"], int(info["per"]) * Run.totem(id)], "", c_panel, false, Callable()))

	list.add_child(_heading("Snacks (%d/%d)" % [Run.snacks.size(), Run.max_snacks()]))
	if Run.snacks.is_empty():
		list.add_child(_note("Snacks are used once, from the buttons under the board."))
	for id in Run.snacks:
		list.add_child(_offer_row(id, "", c_panel, false, Callable()))

	if not Run.charms.is_empty():
		list.add_child(_heading("Charms"))
		for id in Run.charms:
			list.add_child(_offer_row(id, "", c_panel, false, Callable()))


## The run's monsters, each with a Sell button.
func _add_owned_monsters() -> void:
	for id in Run.jokers.duplicate():
		var jid: String = id
		var e := str(Run.editions.get(jid, ""))
		list.add_child(_row(jid if e == "" else "%s|%s" % [jid, e], _monster_title(jid, Run.level(jid)), _monster_tag(jid, e), _tag_color(jid, e),
			_owned_desc(jid, e), "Sell +%d" % Run.sell_price(jid), c_panel, true, func() -> void: _sell(jid)))


func _buy(slot: int) -> void:
	var offer: String = Run.offers[slot]
	if not Run.buy(offer):
		return
	Run.offers[slot] = ""
	Run.store()
	Sfx.play("coin")
	Sfx.vibrate(20, false, 0.5)
	_rebuild()


func _pick(k: int) -> void:
	if not Run.pick_from_sack(k):
		return
	Run.store()
	Sfx.play("win")
	Sfx.vibrate(30, false, 0.6)
	_rebuild()


func _sell(id: String) -> void:
	Run.sell(id)
	Run.store()
	Sfx.play("drop")
	_rebuild()


func _reroll() -> void:
	var cost := Run.reroll_cost()
	if Run.gold < cost:
		return
	Run.gold -= cost
	Run.rerolls += 1
	Run.offers = Jokers.roll_offers(_rng(), Run.jokers, Run.jlevels, Run.charms, Run.toad)
	_mark_seen()
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


static func _monster_title(id: String, lv: int) -> String:
	var n := str(Jokers.JOKERS[id]["name"])
	return n if lv <= 1 else "%s  Lv %d" % [n, lv]


static func _monster_tag(id: String, e: String) -> String:
	var t := "%s monster" % Jokers.RARITY_NAMES[Jokers.rarity(id)]
	if Jokers.grows(id):
		t = "Growing · " + t
	if e != "":
		t = "%s · %s" % [Jokers.EDITIONS[e]["name"], t]
	return t


static func _tag_color(id: String, e := "") -> Color:
	if e != "":
		return Color(str(Jokers.EDITIONS[e]["color"]))
	if Jokers.is_monster(id):
		return Color(Jokers.RARITY_COLORS[Jokers.rarity(id)])
	if Jokers.is_snack(id):
		return Color("e88aa8")
	if Jokers.is_totem(id):
		return Color("8fb04a")
	return Color("f0d060")


## A monster the run owns: what it does now, what it has grown to, and its shine.
static func _owned_desc(id: String, e: String) -> String:
	var d := Jokers.desc(id, Run.level(id))
	if Jokers.grows(id):
		var g := Run.grown(id)
		d += "  (now %s%s)" % ["x" if id == "yeti" else "+", Jokers.fmt(1.0 + g if id == "yeti" else g)]
	if e != "":
		d += ". %s" % Jokers.EDITIONS[e]["desc"]
	return d


## One card for anything the shop shows: a fresh monster or a level-up, a totem, a snack,
## a charm or a sack.
func _offer_row(offer: String, btn_text: String, btn_color: Color, enabled: bool, on_press: Callable) -> PanelContainer:
	var id := Jokers.base(offer)
	var e := Jokers.edition(offer)
	var info := Jokers.info(id)
	var title := str(info["name"])
	var tag := ""
	var desc := str(info.get("desc", ""))
	if Jokers.is_monster(id):
		var lv := Run.level(id) + 1
		title = _monster_title(id, lv)
		tag = "Level up · " + _monster_tag(id, e) if Run.level(id) > 0 else _monster_tag(id, e)
		desc = Jokers.desc(id, lv)
		if e != "":
			desc += ". %s" % Jokers.EDITIONS[e]["desc"]
	elif Jokers.is_totem(id):
		var lv := Run.totem(id) + 1
		title = "%s  Lv %d" % [title, lv]
		tag = "Totem (no level cap)"
		desc = "%s: +%d points (+%d per level)" % [desc, int(info["per"]) * lv, int(info["per"])]
	elif Jokers.is_snack(id):
		tag = "Snack (one use)"
	elif Jokers.is_sack(id):
		tag = "Surprise"
	else:
		tag = "Charm (lasts the run)"
	return _row(offer, title, tag, _tag_color(id, e), desc, btn_text, btn_color, enabled, on_press)


## One card: the picture, name, a coloured tag, what it does, and a button (buy, sell, or none).
func _row(icon_id: String, title: String, tag: String, tag_color: Color, desc_text: String, btn_text: String, btn_color: Color,
		enabled: bool, on_press: Callable) -> PanelContainer:
	var id := Jokers.base(icon_id)
	var card := PanelContainer.new()
	var sb := UI.panel_style(Color("2a241c"), 26)
	# Rare and shiny monsters get a coloured frame.
	sb.border_color = UI.INK
	if Jokers.edition(icon_id) != "":
		sb.border_color = Color(str(Jokers.EDITIONS[Jokers.edition(icon_id)]["color"]))
	elif Jokers.is_monster(id) and Jokers.rarity(id) >= Jokers.RARE:
		sb.border_color = Color(Jokers.RARITY_COLORS[Jokers.rarity(id)])
		if Jokers.rarity(id) == Jokers.LEGENDARY:
			sb.bg_color = Color("3a3018")
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
	icon.id = icon_id
	icon.custom_minimum_size = Vector2(96, 96)
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var name_l := UI.label(title, 30, Color.WHITE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name_l)
	var tag_l := UI.label(tag, 20, tag_color)
	tag_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(tag_l)
	var desc := UI.label(desc_text, 23, c_muted)
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
