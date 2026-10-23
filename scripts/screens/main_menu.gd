class_name MainMenu
extends Control
## Title screen: modes, shop and settings.

var router


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ins := UI.safe_insets(self)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", int(28 + ins.x))
	margin.add_theme_constant_override("margin_bottom", int(36 + ins.y))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var settings := UI.button("Settings", Color("3a3028"), 26, 72)
	settings.pressed.connect(func() -> void: router.show_settings())
	top.add_child(settings)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	top.add_theme_constant_override("separation", 12)
	var book := UI.button("Collection", Color("3a3028"), 26, 72)
	book.pressed.connect(func() -> void: router.show_collection())
	top.add_child(book)
	var hats := UI.button("Wardrobe", Color("3a3028"), 26, 72)
	hats.pressed.connect(func() -> void: router.show_wardrobe())
	top.add_child(hats)

	var logo := MenuLogo.new()
	logo.custom_minimum_size = Vector2(0, 300)
	logo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(logo)
	col.add_child(UI.label("Gerald Blocks", 88, Color("f0d060"), 20))
	col.add_child(UI.label("Let him sleep. Squash the heroes.", 30, Color(1, 1, 1, 0.7)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	col.add_child(gap)

	if Run.has_saved():
		Run.resume()
		var cont := UI.menu_button("Continue run", "%s · %d nap%s · %d gold" % [Run.label(Run.round_n), Run.naps, "" if Run.naps == 1 else "s", Run.gold], Color("6a8a3a"))
		cont.pressed.connect(func() -> void:
			Run.resume()
			if Run.offers.is_empty():
				router.start_game("run")
			else:
				router.show_run_shop())
		col.add_child(cont)
	var best := Run.best_round()
	var new_sub := "Best: %s" % Run.label(best) if best > 0 else "8 nights, 3 rounds each"
	var new_run := UI.menu_button("New run", new_sub, Color("a0603a"))
	new_run.pressed.connect(func() -> void: router.show_toad_pick())
	col.add_child(new_run)
	var sq_best := Meta.stat("squash_best")
	var squash := UI.menu_button("Squash mode", "Best: %s" % UI.fmt(sq_best) if sq_best > 0 else "Endless heroes. How many can you flatten?", Color("6a4a90"))
	squash.pressed.connect(func() -> void: router.start_game("squash"))
	col.add_child(squash)
	col.add_child(UI.label("by BDS Labs", 24, Color(1, 1, 1, 0.45)))


## The Bog Toad asleep in his nest while a few heroes tiptoe in, with blocks bobbing above.
class MenuLogo extends Control:
	var t := 0.0
	const CELLS := [Vector2(-1.5, -1), Vector2(-0.5, -1), Vector2(0.5, -1), Vector2(0.5, 0), Vector2(1.5, 0)]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var pal: Array = Save.palette()
		var u := minf(size.x / 8.0, size.y / 4.4)
		var c := Vector2(size.x / 2.0, size.y * 0.7)
		for i in CELLS.size():
			var bob := sin(t * 2.2 + i * 0.7) * u * 0.06
			var p: Vector2 = CELLS[i]
			BlockArt.draw_block(self, pal[i % pal.size()], c + Vector2(-u * 1.0, -u * 2.4) + p * u * 0.62 + Vector2(0, bob), u * 0.6)
		FmmArt.draw_nest(self, c + Vector2(0, u * 0.75), u * 2.9, u * 0.95)
		FmmArt.draw_toad(self, c, u * 1.8 / 110.0, t, "nap", Vector2(0, 1), 0.0, FmmArt.TOAD, Meta.hat())
		var zk := fmod(t * 0.5, 1.0)
		draw_string(UI.display_font(), c + Vector2(u * (1.3 + zk * 0.5), -u * (1.1 + zk * 1.0)), "z", HORIZONTAL_ALIGNMENT_LEFT, -1,
			int(u * (0.45 + 0.3 * zk)), Color(FmmArt.C_TEXT, 1.0 - zk))
		var kinds := [FmmArt.TANK, FmmArt.MAGE, FmmArt.ARCHER]
		for i in 3:
			var hp := c + Vector2(u * (2.6 + 0.75 * i), -u * (0.2 + 0.5 * (i % 2)))
			FmmArt.draw_hero(self, kinds[i], hp, u / 60.0, t + i, 0.0, 0.0, -1.0, 0.6)
