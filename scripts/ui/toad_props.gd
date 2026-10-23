class_name ToadProps
extends RefCounted
## The little drawings next to each silly line on the toad picker's posters ("Never Skip Dessert"
## gets a cake, "Own a Mirror (Several)" gets a pile of mirrors). Drawn in a 100x100 box around
## the centre, scaled to the radius asked for, in the same inked style as the monsters.

const INK := FmmArt.INK
const LW := 5.0
const CREAM := Color("f2ecd8")
const GOLD := Color("f0d060")
const PINK := Color("e88aa8")
const BLUE := Color("6aa0c0")
const GREEN := Color("6a9a4a")
const BROWN := Color("8a6a4a")
const GREY := Color("8a8274")
const RED := Color("d05848")


static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, t: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(r / 50.0, r / 50.0))
	match id:
		"puddle":
			_poly(ci, FmmArt.blobp(Vector2(0, 14), 44, 16, 14, 4, 0.12), BLUE)
			ci.draw_arc(Vector2(-10, 10), 10 + fmod(t * 8.0, 12.0), PI, TAU, 12, Color(1, 1, 1, 0.5), 3.0, true)
		"pillow":
			_poly(ci, FmmArt.blobp(Vector2(0, 6), 40, 24, 12, 5, 0.06), FmmArt.PILLOW)
			ci.draw_string(ThemeDB.fallback_font, Vector2(-8, 16), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK)
		"fav_pillow":
			_poly(ci, FmmArt.blobp(Vector2(0, 6), 40, 24, 12, 5, 0.06), FmmArt.PILLOW)
			_heart(ci, Vector2(0, 4), 12, PINK)
		"fly":
			_fly(ci, Vector2(0, 0) + Vector2(sin(t * 3.0) * 8, cos(t * 4.0) * 5), 1.4, t)
			ci.draw_arc(Vector2(0, 8), 26, 0.3, 2.6, 12, Color(INK, 0.5), 2.5, true)
		"no_sun":
			_circle(ci, Vector2.ZERO, 20, GOLD)
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(Vector2(cos(a), sin(a)) * 26, Vector2(cos(a), sin(a)) * 36, INK, 5.0, true)
			ci.draw_line(Vector2(-36, -36), Vector2(36, 36), RED, 8.0, true)
		"zzz":
			for k in 3:
				var p := Vector2(-22 + k * 18, 20 - k * 18 - fmod(t * 6.0, 6.0))
				ci.draw_string(ThemeDB.fallback_font, p, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 22 + k * 8, CREAM)
		"monocle":
			ci.draw_arc(Vector2(-6, -4), 22, 0, TAU, 24, INK, 9.0, true)
			ci.draw_arc(Vector2(-6, -4), 22, 0, TAU, 24, GOLD, 5.0, true)
			ci.draw_circle(Vector2(-6, -4), 18, Color(0.8, 0.9, 1.0, 0.3))
			ci.draw_line(Vector2(14, 6), Vector2(34, 40), GOLD, 3.0, true)
		"no_rent":
			_poly(ci, _rect(-28, -34, 28, 34), CREAM)
			ci.draw_string(ThemeDB.fallback_font, Vector2(-22, -8), "RENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
			for k in 2:
				ci.draw_line(Vector2(-18, 8 + k * 10), Vector2(18, 8 + k * 10), GREY, 3.0)
			ci.draw_line(Vector2(-34, -38), Vector2(34, 38), RED, 8.0, true)
		"fly_tip":
			_coin(ci, Vector2(-12, 18), 16)
			_fly(ci, Vector2(14, -16), 1.1, t)
		"coins":
			for p in [Vector2(-24, 26), Vector2(0, 26), Vector2(24, 26), Vector2(-12, 12), Vector2(12, 12), Vector2(0, -2)]:
				_coin(ci, p, 14)
		"heart":
			_heart(ci, Vector2(0, 4) + Vector2(0, sin(t * 3.0) * 3), 26, PINK)
		"hearts":
			for k in 3:
				_heart(ci, Vector2(-26 + k * 26, 8 - absf(k - 1) * -10 + sin(t * 3.0 + k) * 3), 14, PINK)
		"breakfast":
			_poly(ci, FmmArt.oval(Vector2(0, 10), 42, 18, 18), CREAM)
			_poly(ci, FmmArt.blobp(Vector2(0, 6), 24, 14, 10, 2, 0.12), Color.WHITE)
			_circle(ci, Vector2(2, 5), 8, GOLD)
			ci.draw_string(ThemeDB.fallback_font, Vector2(18, -18), "2nd", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
		"chair":
			_poly(ci, _rect(-20, -38, 20, -2), RED)
			_poly(ci, _rect(-26, -4, 26, 8), BROWN)
			for x in [-22.0, 18.0]:
				_poly(ci, _rect(x, 8, x + 5, 36), BROWN)
		"weather":
			_cloud(ci, Vector2(0, -8), Color("c8ccd8"))
			for k in 4:
				var y := fmod(t * 40.0 + k * 9.0, 26.0)
				ci.draw_line(Vector2(-18 + k * 12, 14 + y), Vector2(-21 + k * 12, 20 + y), BLUE, 4.0, true)
		"cake":
			for k in 2:
				var o := Vector2(-18 + k * 36, 22 - k * 4)
				_plate(ci, o)
			_poly(ci, PackedVector2Array([Vector2(-16, 14), Vector2(16, 14), Vector2(10, -14), Vector2(-10, -14)]), Color("e8c890"))
			_poly(ci, _rect(-12, -22, 12, -12), PINK)
			_circle(ci, Vector2(0, -28), 5, RED)
		"alarm":
			_circle(ci, Vector2(0, 4), 26, CREAM)
			for sx in [-1.0, 1.0]:
				_circle(ci, Vector2(sx * 20, -22), 8, GOLD)
			ci.draw_line(Vector2(0, 4), Vector2(0, -12), INK, 4.0, true)
			ci.draw_line(Vector2(0, 4), Vector2(12, 8), INK, 4.0, true)
			if fmod(t, 1.0) < 0.5:
				ci.draw_string(ThemeDB.fallback_font, Vector2(26, -26), "+5", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
		"notes":
			for k in 3:
				var p := Vector2(-26 + k * 24, 14 - k * 10 + sin(t * 3.0 + k) * 4)
				ci.draw_circle(p, 7, CREAM)
				ci.draw_line(p + Vector2(6, 0), p + Vector2(6, -24), CREAM, 3.0, true)
		"calendar":
			_poly(ci, _rect(-30, -28, 30, 30), CREAM)
			_poly(ci, _rect(-30, -28, 30, -12), RED)
			ci.draw_string(ThemeDB.fallback_font, Vector2(-24, 18), "2019", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
		"nest":
			_poly(ci, FmmArt.blobp(Vector2(0, 10), 42, 20, 14, 11, 0.12), FmmArt.NEST)
			_poly(ci, FmmArt.blobp(Vector2(-4, 4), 30, 12, 12, 12, 0.14), FmmArt.FUR)
		"polish":
			_poly(ci, FmmArt.blobp(Vector2(-6, 10), 26, 16, 10, 7, 0.12), BLUE)
			_spark(ci, Vector2(20, -18), 12 + sin(t * 5.0) * 3)
		"gems":
			for k in 3:
				var p := Vector2(-22 + k * 22, 16 - (k % 2) * 16)
				var col: Color = [Color("e070c0"), Color("70c0e0"), GOLD][k]
				_poly(ci, PackedVector2Array([p + Vector2(0, -14), p + Vector2(12, -2), p + Vector2(0, 14), p + Vector2(-12, -2)]), col)
		"blind":
			for k in 8:
				var a := TAU * k / 8.0 + t
				ci.draw_line(Vector2(cos(a), sin(a)) * 12, Vector2(cos(a), sin(a)) * (34 + 6 * sin(t * 6.0 + k)), Color(GOLD, 0.9), 5.0, true)
			_circle(ci, Vector2.ZERO, 12, Color("fff4c0"))
		"mirrors":
			for k in 3:
				var p := Vector2(-24 + k * 24, 6 - (k % 2) * 10)
				_poly(ci, FmmArt.oval(p, 12, 18, 14), Color("8a6a4a"))
				ci.draw_colored_polygon(FmmArt.oval(p, 8, 13, 14), Color("d0e0f0"))
				ci.draw_line(p + Vector2(-4, -6), p + Vector2(2, -10), Color.WHITE, 2.0, true)
		"sparkles":
			for k in 4:
				var p := Vector2(-24 + (k % 2) * 40, -20 + (k / 2) * 34)
				_spark(ci, p, 10 + 4 * sin(t * 4.0 + k * 1.7))
		"frame":
			_poly(ci, _rect(-32, -26, 32, 28), BROWN)
			ci.draw_colored_polygon(_rect(-24, -18, 24, 20), Color("4a6a3a"))
			ci.draw_colored_polygon(FmmArt.oval(Vector2(-4, 10), 16, 6, 12), Color("3a5a7a"))
		"angry_cloud":
			_cloud(ci, Vector2(0, -4), Color("8a8a9a"))
			ci.draw_line(Vector2(-12, -8), Vector2(-4, -4), INK, 4.0, true)
			ci.draw_line(Vector2(12, -8), Vector2(4, -4), INK, 4.0, true)
			ci.draw_string(ThemeDB.fallback_font, Vector2(24, -24), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, RED)
		"rock_guy":
			_poly(ci, FmmArt.blobp(Vector2(0, 6), 32, 26, 9, 11, 0.14), GREY)
			ci.draw_circle(Vector2(-10, 0), 4, INK)
			ci.draw_circle(Vector2(10, 0), 4, INK)
			ci.draw_line(Vector2(-6, 14), Vector2(6, 14), INK, 3.0)
		"totem":
			for k in 3:
				var y := 22 - k * 22
				_poly(ci, _rect(-16, y - 10, 16, y + 12), [GREEN, RED, BLUE][k])
				ci.draw_circle(Vector2(-6, y), 3, INK)
				ci.draw_circle(Vector2(6, y), 3, INK)
		"clock4":
			_circle(ci, Vector2.ZERO, 30, CREAM)
			ci.draw_line(Vector2.ZERO, Vector2(0, -20), INK, 4.0, true)
			ci.draw_line(Vector2.ZERO, Vector2(14, 8), INK, 5.0, true)
		"lick_block":
			BlockArt.draw_block(ci, Color("e0a040"), Vector2(-6, -4), 46, 1.0)
			_poly(ci, PackedVector2Array([Vector2(16, 10), Vector2(36, 2), Vector2(40, 14), Vector2(18, 20)]), PINK)
		"menu":
			_poly(ci, PackedVector2Array([Vector2(-24, -32), Vector2(24, -32), Vector2(24, 18), Vector2(14, 22), Vector2(10, 32), Vector2(-24, 32)]), CREAM)
			ci.draw_string(ThemeDB.fallback_font, Vector2(-18, -14), "MENU", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
			for k in 3:
				ci.draw_line(Vector2(-16, 0 + k * 9), Vector2(12, 0 + k * 9), GREY, 3.0)
		"moon_sun":
			_circle(ci, Vector2(14, -6), 18, GOLD)
			_circle(ci, Vector2(-12, 6), 18, Color("f0e8b0"))
			ci.draw_circle(Vector2(-4, 0), 15, Color("2a241c"))
		"fly_opinion":
			_fly(ci, Vector2(-10, 14), 1.1, t)
			_poly(ci, FmmArt.oval(Vector2(14, -18), 22, 14, 14), CREAM)
			ci.draw_string(ThemeDB.fallback_font, Vector2(4, -10), "8/10", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
		"helmet":
			_poly(ci, PackedVector2Array([Vector2(-26, 14), Vector2(-24, -10), Vector2(-10, -26), Vector2(10, -26), Vector2(24, -10), Vector2(26, 14)]), Color("b0b8c8"))
			ci.draw_line(Vector2(-16, 0), Vector2(16, 0), INK, 5.0)
			ci.draw_circle(Vector2(20 + sin(t * 2.0) * 2, 24 + fmod(t * 10.0, 10.0)), 5, Color(0.6, 0.85, 1.0, 0.9))
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	FmmArt.shape(ci, pts, col, LW)


static func _circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r + LW * 0.5, INK)
	ci.draw_circle(c, r - LW * 0.5, col)


static func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


static func _coin(ci: CanvasItem, p: Vector2, r: float) -> void:
	_circle(ci, p, r, GOLD)
	ci.draw_line(p + Vector2(0, -r * 0.5), p + Vector2(0, r * 0.5), Color("b08a30"), 3.0)


static func _plate(ci: CanvasItem, p: Vector2) -> void:
	_poly(ci, FmmArt.oval(p, 30, 10, 16), CREAM)
	ci.draw_arc(p, 18, 0, TAU, 16, Color(FmmArt.INK, 0.25), 2.0, true)


static func _heart(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	var k := s / 12.0
	var pts := PackedVector2Array()
	for v in [Vector2(0, 12), Vector2(-12, 0), Vector2(-11, -7), Vector2(-5, -10), Vector2(0, -5), Vector2(5, -10), Vector2(11, -7), Vector2(12, 0)]:
		pts.append(p + v * k)
	_poly(ci, pts, col)


static func _fly(ci: CanvasItem, p: Vector2, s: float, t: float) -> void:
	for sx in [-1.0, 1.0]:
		var flap := 0.7 + 0.3 * sin(t * 30.0)
		ci.draw_colored_polygon(FmmArt.oval(p + Vector2(sx * 9, -8) * s, 8 * s, 6 * s * flap, 10), Color(1, 1, 1, 0.6))
	ci.draw_circle(p, 8 * s, INK)
	ci.draw_circle(p + Vector2(4, -3) * s, 2.5 * s, Color("e05050"))


static func _cloud(ci: CanvasItem, p: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		var bump := 1.0 + 0.18 * absf(sin(a * 3.0))
		pts.append(p + Vector2(cos(a) * 36, sin(a) * 20) * bump)
	_poly(ci, pts, col)


static func _spark(ci: CanvasItem, p: Vector2, s: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.25, 0), p + Vector2(0, s), p + Vector2(-s * 0.25, 0)]), GOLD)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, s * 0.25), p + Vector2(s, 0), p + Vector2(0, -s * 0.25)]), GOLD)
