extends Node
## Screenshots of the run mode into build/shots/: menu, round intro, a raid in progress, a squash, the end.
## Run windowed (not headless): xvfb-run godot --path . --resolution 720x1280 res://tests/run_shots.tscn

var router


func _ready() -> void:
	Save.data["sound"] = false
	Save.data["haptics_minor"] = false
	Save.data["haptics_major"] = false
	router = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(router)
	for i in 3:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/shots"))
	await _wait(0.5)
	await _shot("run_menu")

	Run.start_new()
	router.start_game("run")
	await _wait(0.6)
	await _shot("run_intro")
	var screen: GameScreen = router.current
	screen._close_dialog()
	await _wait(0.3)
	await _shot("run_round1")

	Run.jokers = ["blob", "worm", "bat"]
	Run.jlevels = {"blob": 2, "worm": 1, "bat": 3}
	Run.editions = {"bat": "foil"}
	Run.grow = {"worm": 23}
	Run.totems = {"t_one": 3, "t_squash": 1}
	Run.snacks = ["tongue", "slam"]
	Run.charms = ["dice"]
	Run.gold = 12
	Run.round_n = 11
	Run.offers = []
	router.show_run_shop()
	await _wait(0.6)
	await _shot("run_shop")
	var shop = router.current
	shop.list.get_parent().scroll_vertical = 900
	await _wait(0.3)
	await _shot("run_shop2")
	Run.offers = ["blob", "yeti|rainbow", "t_many", "sack"]
	Run.gold = 40
	shop._buy(3)
	await _wait(0.4)
	await _shot("run_sack")

	# A raid on night 4: some blocks down, heroes on their way, one about to be squashed.
	Run.round_n = 12
	Run.naps = 2
	router.start_game("run")
	await get_tree().process_frame
	screen = router.current
	screen._close_dialog()
	var view := screen.view
	view.heroes = []
	for i in [40, 41, 42, 44, 45, 46, 47, 50, 51, 58, 59, 60, 9, 17]:
		view.color[i] = 1 + i % 8
	for spec in [["knight", 3, 5], ["bomber", 6, 2], ["elf", 1, 3], ["paladin", 5, 1], ["mage", 0, 6], ["thief", 7, 4]]:
		var t: String = spec[0]
		view.heroes.append({"id": 0, "type": t, "kind": HeroArt.kind_for(t), "hp": int(GameView.HERO_TYPES[t]["hp"]),
			"x": spec[1], "y": spec[2], "px": float(spec[1]), "py": float(spec[2]), "bob": randf() * 6.0, "moves": 0})
	view._update_near_lines()
	view.say(["Heroes. In my room. At this hour."])
	await _wait(0.8)
	await _shot("run_raid")
	# Row 5 is full except column 3 (where the knight stands) and 2: drop a 1x1 at (2,5).
	var one: Dictionary = Shapes.by_cells([Vector2i(0, 0)])
	view.tray[0] = {"shape": one, "color": 3, "bomb": -1}
	view._place(0, 2, 5)
	await _wait(0.15)
	await _shot("run_squash")
	await _wait(0.5)
	await _shot("run_squash2")

	view.end_reason = "woke"
	view.angry_t = view.time
	Run.naps = 0
	view._lose()
	await _wait(2.4)
	await _shot("run_over")

	# Boss raid on night 2.
	Run.start_new("rich")
	Run.round_n = 6
	router.start_game("run")
	await get_tree().process_frame
	screen = router.current
	await _wait(0.4)
	await _shot("run_boss_intro")
	screen._close_dialog()
	view = screen.view
	for i in [48, 49, 50, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63]:
		view.color[i] = 1 + i % 8
	for h in view.heroes:
		if h.get("boss", false):
			h["y"] = 3
			h["py"] = 3.0
	await _wait(0.8)
	await _shot("run_boss")

	# Night 8 won: keep going into endless.
	Run.round_n = Run.last_round()
	view.score = 999999
	view.pending_finish = {}
	screen._on_finished(true)
	await _wait(0.5)
	await _shot("run_complete")

	# Squash mode.
	Meta.data()["stats"]["squash_best"] = 4200
	router.start_game("squash")
	await get_tree().process_frame
	screen = router.current
	screen._close_dialog()
	await _wait(0.8)
	await _shot("squash_mode")

	# Meta screens with some progress.
	var st: Dictionary = Meta.data()["stats"]
	st["rounds_won"] = 30
	st["squashed"] = 120
	st["best_night"] = 5
	st["runs"] = 6
	st["lines"] = 250
	for id in ["blob", "slime", "goblin", "grub", "rat", "troll", "bat", "mouth", "worm", "crab", "owl", "golem"]:
		Meta.mark_seen(id)
	Meta.data()["hat"] = "viking"
	router.show_menu()
	await _wait(0.6)
	await _shot("menu_hat")
	router.show_toad_pick()
	await _wait(0.8)
	await _shot("toad_pick")
	router.current._flip(1)
	await _wait(0.8)
	await _shot("toad_pick2")
	router.current._flip(3)
	await _wait(0.8)
	await _shot("toad_pick_locked")
	router.show_wardrobe()
	await _wait(0.6)
	await _shot("wardrobe")
	router.show_collection()
	await _wait(0.4)
	router.current._show("worm")
	await _wait(0.3)
	await _shot("collection")

	# Every monster, snack and charm on one sheet, to check they all look different.
	router.queue_free()
	var sheet := ItemSheet.new()
	get_tree().root.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _wait(0.3)
	await _shot("run_items")
	sheet.queue_free()

	# App icon: the sleeping toad on the lair floor, cropped square and saved as res://icon.png.
	var icon := IconArt.new()
	get_tree().root.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _wait(0.2)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var side := mini(img.get_width(), img.get_height())
	img = img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
	img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path("res://icon.png"))
	icon.queue_free()

	# Boot splash: the same toad and blocks with a small "by BDS Labs", saved as res://splash.png.
	var splash := SplashArt.new()
	get_tree().root.add_child(splash)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _wait(0.2)
	await RenderingServer.frame_post_draw
	img = get_viewport().get_texture().get_image()
	var sw := img.get_width()
	img = img.get_region(Rect2i(0, (img.get_height() - sw) / 2, sw, sw))
	img.resize(600, 600, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path("res://splash.png"))
	get_tree().quit()


class ItemSheet extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("2a2219"))
		var ids: Array = Jokers.JOKERS.keys() + Jokers.TOTEMS.keys() + ["sack", "blob|foil", "lucky|gold", "owl|rainbow"] + Jokers.SNACKS.keys() + Jokers.CHARMS.keys()
		var cols := 5
		var w := size.x / cols
		var h := 96.0
		var font := UI.display_font()
		for k in ids.size():
			var c := Vector2((k % cols + 0.5) * w, 50 + (k / cols) * h)
			Jokers.draw_icon(self, ids[k], c, 30, 0.5)
			draw_string(font, c + Vector2(-w / 2, 46), str(Jokers.info(ids[k])["name"]), HORIZONTAL_ALIGNMENT_CENTER, w, 15, Color.WHITE)


class SplashArt extends Control:
	func _draw() -> void:
		var side := size.x
		var c := size / 2.0 + Vector2(0, -side * 0.08)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.165, 0.133, 0.098))
		var pal: Array = Themes.get_theme("lair")["blocks"]
		var u := side / 10.0
		for i in 3:
			BlockArt.draw_block(self, pal[[0, 2, 4][i]], c + Vector2((i - 1) * u * 1.04, -u * 2.6), u)
		FmmArt.draw_nest(self, c + Vector2(0, u * 1.5), u * 3.4, u * 1.1)
		FmmArt.draw_toad(self, c + Vector2(0, u * 0.6), u * 2.6 / 110.0, 0.3, "nap")
		draw_string(UI.display_font(), Vector2(0, c.y + u * 3.6), "by BDS Labs", HORIZONTAL_ALIGNMENT_CENTER, side, int(u * 0.55), Color(1, 1, 1, 0.55))


class IconArt extends Control:
	func _draw() -> void:
		var side := minf(size.x, size.y)
		var c := size / 2.0
		draw_rect(Rect2(Vector2.ZERO, size), Color("2a2219"))
		BlockArt.draw_glow(self, c + Vector2(0, -side * 0.1), side * 0.6, Color(1.0, 0.6, 0.25, 0.35))
		var pal: Array = Themes.get_theme("lair")["blocks"]
		var u := side / 8.0
		for i in 3:
			BlockArt.draw_block(self, pal[[0, 2, 4][i]], c + Vector2((i - 1) * u * 1.04, -u * 2.6), u)
		FmmArt.draw_nest(self, c + Vector2(0, u * 1.5), u * 3.4, u * 1.1)
		FmmArt.draw_toad(self, c + Vector2(0, u * 0.6), u * 2.6 / 110.0, 0.3, "nap")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://build/shots/%s.png" % name))
