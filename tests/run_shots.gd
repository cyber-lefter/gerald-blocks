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
	for spec in [["knight", 3, 5], ["squire", 6, 2], ["elf", 1, 3], ["paladin", 5, 1]]:
		var t: String = spec[0]
		view.heroes.append({"id": 0, "type": t, "kind": HeroArt.kind_for(t), "hp": int(GameView.HERO_TYPES[t]["hp"]),
			"x": spec[1], "y": spec[2], "px": float(spec[1]), "py": float(spec[2]), "bob": randf() * 6.0})
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

	# App icon: the sleeping toad on the lair floor, cropped square and saved as res://icon.png.
	router.queue_free()
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
	get_tree().quit()


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
