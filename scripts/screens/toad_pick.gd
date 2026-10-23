class_name ToadPick
extends Control
## Before a new run: pick which toad sleeps tonight. One poster per toad ("A Guide to Richmaxxing"):
## the toad in his nest, his real perk in gold and five deadpan facts around him. Swipe or use the
## arrows to flip through; locked toads show as a shadow with what unlocks them.

var router
var ids: Array = []
var page := 0
var poster: Poster
var banner_label: Label
var play_btn: Button
var dots: Label
var drag_x := -1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ids = Meta.TOADS.keys()
	var col := Screens.frame(self, "Choose your toad", func() -> void: router.show_menu())
	poster = Poster.new()
	poster.size_flags_vertical = Control.SIZE_EXPAND_FILL
	poster.gui_input.connect(_on_poster_input)
	col.add_child(poster)

	# The wavy banner: the real perk in plain words (or the unlock goal).
	var banner := Banner.new()
	banner.custom_minimum_size = Vector2(0, 120)
	col.add_child(banner)
	banner_label = UI.label("", 30, Color("3a2a18"))
	banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_label.offset_left = 40
	banner_label.offset_right = -40
	banner.add_child(banner_label)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 14)
	col.add_child(nav)
	var prev := UI.button("<", Color("3a3028"), 36, 96)
	prev.custom_minimum_size = Vector2(96, 96)
	prev.pressed.connect(func() -> void: _flip(-1))
	nav.add_child(prev)
	play_btn = UI.button("", Color("6a8a3a"), 34, 96)
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_btn.pressed.connect(_play)
	nav.add_child(play_btn)
	var next := UI.button(">", Color("3a3028"), 36, 96)
	next.custom_minimum_size = Vector2(96, 96)
	next.pressed.connect(func() -> void: _flip(1))
	nav.add_child(next)
	dots = UI.label("", 24, Color("a09480"))
	col.add_child(dots)
	_show()


func go_back() -> void:
	router.show_menu()


func _on_poster_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		if e.pressed:
			drag_x = e.position.x
		elif drag_x >= 0.0:
			var dx: float = e.position.x - drag_x
			drag_x = -1.0
			if absf(dx) > 60.0:
				_flip(-1 if dx > 0.0 else 1)


func _flip(d: int) -> void:
	page = posmod(page + d, ids.size())
	Sfx.play("pick", 1.1)
	_show()


func _show() -> void:
	var id: String = ids[page]
	var open := Meta.toad_unlocked(id)
	poster.id = id
	poster.open = open
	poster.flip_t = 0.0
	poster.queue_redraw()
	var info: Dictionary = Meta.TOADS[id]
	banner_label.text = str(info["desc"]) if open else "Locked: " + Meta.req_text(info["req"])
	play_btn.text = "Play as the %s" % info["name"] if open else "Locked"
	play_btn.disabled = not open
	var d := ""
	for k in ids.size():
		d += "● " if k == page else "○ "
	dots.text = d.strip_edges()


func _play() -> void:
	var id: String = ids[page]
	if not Meta.toad_unlocked(id):
		return
	Run.start_new(id)
	router.start_game("run")


## The poster: title, the toad in his nest with a bit of sparkle, the labels around him.
class Poster extends Control:
	var id := "bog"
	var open := true
	var t := 0.0
	var flip_t := 0.0
	const CREAM := Color("f0e6d0")
	const GOLD := Color("f0d060")
	# Where the six labels sit, as fractions of the poster: three down each side.
	const SPOTS := [Vector2(0.15, 0.30), Vector2(0.15, 0.56), Vector2(0.15, 0.82),
		Vector2(0.85, 0.30), Vector2(0.85, 0.56), Vector2(0.85, 0.82)]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		t += delta
		flip_t += delta
		queue_redraw()

	func _draw() -> void:
		var font := UI.display_font()
		var w := size.x
		var h := size.y
		var info: Dictionary = Meta.TOADS[id]
		var guide: Dictionary = Meta.TOAD_GUIDE[id]
		var pop := clampf(flip_t / 0.25, 0.0, 1.0)

		# Title: "A Guide to" small, the -maxxing word big.
		draw_string(font, Vector2(0, h * 0.06), "A GUIDE TO", HORIZONTAL_ALIGNMENT_CENTER, w, int(w * 0.045), Color(CREAM, 0.8))
		var title := str(guide["maxx"]) if open else "????maxxing"
		var ts := int(w * 0.11)
		draw_string_outline(font, Vector2(0, h * 0.06 + ts * 1.05), title, HORIZONTAL_ALIGNMENT_CENTER, w, ts, 10, FmmArt.INK)
		draw_string(font, Vector2(0, h * 0.06 + ts * 1.05), title, HORIZONTAL_ALIGNMENT_CENTER, w, ts, Color(info["color"]).lightened(0.35) if open else Color("6a6050"))

		# The toad, big, in his nest, with sparkles (in the middle third, between the labels).
		var u := minf(w * 0.24, h * 0.22)
		var c := Vector2(w / 2.0, h * 0.62)
		for k in 7:
			var a := TAU * k / 7.0 + t * 0.2
			var p := c + Vector2(cos(a) * u * 1.25, sin(a) * u * 0.95 - u * 0.25)
			var s := u * (0.05 + 0.03 * sin(t * 3.0 + k))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 2), p + Vector2(s * 0.45, 0), p + Vector2(0, s * 2), p + Vector2(-s * 0.45, 0)]), Color(GOLD, 0.7))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 2, 0), p + Vector2(0, s * 0.45), p + Vector2(s * 2, 0), p + Vector2(0, -s * 0.45)]), Color(GOLD, 0.7))
		FmmArt.draw_nest(self, c + Vector2(0, u * 0.55), u * 1.25, u * 0.42)
		var skin := Color(str(info["color"])) if open else Color("2a2620")
		var sc := u * 0.95 / 110.0 * (0.85 + 0.15 * _ease(pop))
		FmmArt.draw_toad(self, c + Vector2(0, u * 0.12), sc, t, "nap", Vector2(0, 1), 0.0, skin, Meta.hat() if open else "")

		# The labels: the real perk (gold, with a star) first, then the five that do nothing.
		var lines: Array = [str(guide["perk"])] + Array(guide["silly"])
		var fs := int(w * 0.042)
		var lw := w * 0.28
		for k in SPOTS.size():
			var spot: Vector2 = SPOTS[k] * size
			var real := k == 0
			var text: String = lines[k] if open else "???"
			var a := clampf((flip_t - 0.05 * k) / 0.2, 0.0, 1.0)
			var col := GOLD if real and open else CREAM
			var tl := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, lw, fs)
			var pos := spot - Vector2(lw / 2.0, tl.y / 2.0 - fs)
			if not real and open:
				# The silly line's little drawing, just above it.
				var pr := fs * 2.0 * a
				if pr > 1.0:
					ToadProps.draw(self, str(guide["props"][k - 1]), spot - Vector2(0, tl.y / 2.0 + pr * 0.95), pr, t + k)
			draw_multiline_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, lw, fs, -1, 8, Color(FmmArt.INK, a))
			draw_multiline_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, lw, fs, -1, Color(col, a))
			if real and open:
				_star(spot + Vector2(0, -tl.y / 2.0 - fs * 0.2), fs * 0.45, Color(GOLD, a))

	func _star(p: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI / 2.0 + PI * k / 5.0
			pts.append(p + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
		draw_colored_polygon(pts, col)

	static func _ease(k: float) -> float:
		return 1.0 + 2.70158 * pow(k - 1.0, 3) + 1.70158 * pow(k - 1.0, 2)


## A cream ribbon with wavy ends, like the bottom of the poster.
class Banner extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# Clockwise: wavy top edge, notched right end, wavy bottom edge, notched left end.
		var pts := PackedVector2Array()
		var n := 14
		for k in n + 1:
			pts.append(Vector2(w * k / n, h * 0.12 + (5.0 if k % 2 == 0 else -5.0)))
		for k in range(1, 4):
			pts.append(Vector2(w - (14.0 if k % 2 == 0 else 0.0), h * (0.12 + 0.76 * k / 4.0)))
		for k in range(n, -1, -1):
			pts.append(Vector2(w * k / n, h * 0.88 + (5.0 if k % 2 == 0 else -5.0)))
		for k in range(3, 0, -1):
			pts.append(Vector2(14.0 if k % 2 == 0 else 0.0, h * (0.12 + 0.76 * k / 4.0)))
		draw_colored_polygon(pts, Color("f0d890"))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, FmmArt.INK, 5.0, true)
