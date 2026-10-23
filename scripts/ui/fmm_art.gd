class_name FmmArt
extends RefCounted
## Five More Minutes artwork, ported from its main.gd: inked outlines over three flat cel tones.
## Heroes are little people about 50 units tall around their middle; the toad is about 200 wide.

const INK := Color("15100c")
const BONE := Color("efe6cc")
const SKIN := Color("c9ac94")
const C_TEXT := Color("f0e6d0")
const C_GOLD := Color("f0d060")
const C_HURT := Color("e0685c")
const C_TONGUE := Color("e88aa8")
const TOAD := Color("788a46")
const NEST := Color("6a4a34")
const FUR := Color("b9a184")
const PILLOW := Color("e0d8e4")

const TANK := 0
const ARCHER := 1
const HEALER := 2
const MAGE := 3
const PALADIN := 4
const BOMBER := 5
const ROGUE := 6
const BARD := 7
const DOG := 11
const C_HERO := {TANK: Color("5a7fc0"), ARCHER: Color("3fa094"), HEALER: Color("efe6d0"), MAGE: Color("a45ad0"),
	PALADIN: Color("e0c060"), BOMBER: Color("d05848"), ROGUE: Color("6a7080"), BARD: Color("e890b8"), DOG: Color("8a6a48")}


# ---------------------------------------------------------------- shape helpers

static func ink(ci: CanvasItem, pts: PackedVector2Array, w := 3.0, col := INK) -> void:
	var c := pts.duplicate()
	c.append(pts[0])
	ci.draw_polyline(c, col, w, true)


static func shape(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w := 3.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	ink(ci, pts, w)


static func _hash01(i: int, j: int) -> float:
	return float(((i * 73856093) ^ (j * 19349663) ^ 0x5bd1e995) & 1023) / 1023.0


static func blobp(c: Vector2, rx: float, ry: float, n: int, seed_: int, wob: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var k := 1.0 + (_hash01(seed_, i) * 2.0 - 1.0) * wob
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry) * k)
	return out


static func oval(c: Vector2, rx: float, ry: float, n := 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		out.append(c + Vector2(cos(TAU * i / n) * rx, sin(TAU * i / n) * ry))
	return out


static func moved(pts: PackedVector2Array, off: Vector2, s: float, about: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(about + (p - about) * s + off)
	return out


## Three flat tones: shadow, a hue-shifted band, light. Then the ink line.
static func cel(ci: CanvasItem, pts: PackedVector2Array, about: Vector2, lit: Color, band: Color, dark: Color, w := 3.0, shift := 6.0) -> void:
	ci.draw_colored_polygon(pts, dark)
	ci.draw_colored_polygon(moved(pts, Vector2(-shift * 0.45, -shift * 0.5), 0.93, about), band)
	ci.draw_colored_polygon(moved(pts, Vector2(-shift, -shift * 1.1), 0.84, about), lit)
	ink(ci, pts, w)


## The usual three tones worked out from one colour.
static func cel1(ci: CanvasItem, pts: PackedVector2Array, about: Vector2, col: Color, w := 3.0, shift := 5.0) -> void:
	cel(ci, pts, about, col, col.lerp(Color("b0506a"), 0.4).darkened(0.18), col.darkened(0.72), w, shift)


static func stick(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w := 2.6) -> void:
	ci.draw_line(a, b, INK, w + 3.0)
	ci.draw_line(a, b, col, w)


# ---------------------------------------------------------------- heroes

## One little person per kind. `t` drives the walk, `panic` raises the arms (0..1), `fx` faces left or right.
static func draw_hero(ci: CanvasItem, kind: int, pos: Vector2, s: float, t: float, panic := 0.0, rot := 0.0, fx := 1.0, walk := 0.4) -> void:
	ci.draw_set_transform_matrix(Transform2D(rot, Vector2(s, s), 0.0, pos))
	var col: Color = C_HERO.get(kind, C_HERO[TANK])
	var hc := Vector2(0, -15)
	var ph := t * 9.0
	match kind:
		TANK:
			_body(ci, col, fx, ph, walk, panic, t)
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-11, 0), hc + Vector2(-9, -9), hc + Vector2(0, -13), hc + Vector2(9, -9), hc + Vector2(11, 0), hc + Vector2(4, -2), hc + Vector2(0, 5), hc + Vector2(-4, -2)]), Color("aab0bc"))
			var sc := Vector2(fx * 12, 5)
			cel1(ci, oval(sc, 11, 11, 14), sc, col.lightened(0.1), 3.0, 3.6)
			ci.draw_circle(sc, 3.2, C_GOLD)
			ci.draw_arc(sc, 3.2, 0, TAU, 10, INK, 1.6)
		ARCHER:
			_body(ci, col, fx, ph, walk, panic, t)
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-11, 3), hc + Vector2(-8, -9), hc + Vector2(2, -15), hc + Vector2(10, -7), hc + Vector2(11, 3), hc + Vector2(5, -3), hc + Vector2(-5, -3)]), col.darkened(0.15))
			var a0 := -1.2 if fx > 0 else PI - 1.2
			ci.draw_arc(Vector2(fx * 14, 2), 12, a0, a0 + 2.4, 12, INK, 5.5)
			ci.draw_arc(Vector2(fx * 14, 2), 12, a0, a0 + 2.4, 12, Color("8a5a34"), 2.6)
			ci.draw_line(Vector2(fx * 18.3, -9), Vector2(fx * 18.3, 13), BONE, 1.2)
		HEALER:
			_body(ci, col, fx, ph, walk, panic, t, 9.0, 14.0)
			ci.draw_rect(Rect2(-3.5, 0, 7, 2.4), Color("d04040"))
			ci.draw_rect(Rect2(-1.2, -2.4, 2.4, 7), Color("d04040"))
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-11, 5), hc + Vector2(-9, -9), hc + Vector2(0, -13), hc + Vector2(9, -9), hc + Vector2(11, 5), hc + Vector2(6, -3), hc + Vector2(-6, -3)]), col)
			stick(ci, Vector2(fx * 15, -22), Vector2(fx * 15, 18), Color("b08a5a"))
			ci.draw_rect(Rect2(fx * 15 - 5.5, -31, 11, 3.6), Color("d04040"))
			ci.draw_rect(Rect2(fx * 15 - 1.8, -35, 3.6, 11), Color("d04040"))
		MAGE:
			_body(ci, col, fx, ph, walk, panic, t, 8.0, 15.0)
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-14, -3), hc + Vector2(-5, -8), hc + Vector2(fx * 3, -28), hc + Vector2(8, -8), hc + Vector2(14, -3), hc + Vector2(0, -1)]), col)
			ci.draw_circle(Vector2(fx * 15, -2), 7, INK)
			ci.draw_circle(Vector2(fx * 15, -2), 5, Color("ffd070"))
		PALADIN:
			_body(ci, col, fx, ph, walk, panic, t, 10.0, 13.0)
			ci.draw_rect(Rect2(-4, -5, 8, 18), Color("f0ead8"))
			ci.draw_rect(Rect2(-1.2, -3, 2.4, 12), Color("c04040"))
			ci.draw_rect(Rect2(-4, 0, 8, 2.4), Color("c04040"))
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-10, 7), hc + Vector2(-10, -8), hc + Vector2(0, -13), hc + Vector2(10, -8), hc + Vector2(10, 7)]), Color("c8ccd4"))
			ci.draw_line(hc + Vector2(-6, 0), hc + Vector2(6, 0), INK, 2.6)
			ci.draw_line(hc + Vector2(0, -8), hc + Vector2(0, 5), INK, 2.0)
			stick(ci, Vector2(fx * 15, -14), Vector2(fx * 15, 16), Color("8a6a48"))
			shape(ci, PackedVector2Array([Vector2(fx * 15 - 7, -22), Vector2(fx * 15 + 7, -22), Vector2(fx * 15 + 7, -13), Vector2(fx * 15 - 7, -13)]), Color("c8ccd4"), 2.4)
		ROGUE:
			cel1(ci, oval(Vector2(-fx * 11, 4), 8, 9, 10), Vector2(-fx * 11, 4), Color("9a7a50"), 2.4, 3.0)
			_body(ci, col, fx, ph, walk, panic, t)
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-11, 4), hc + Vector2(-9, -9), hc + Vector2(0, -13), hc + Vector2(9, -9), hc + Vector2(11, 4), hc + Vector2(6, -4), hc + Vector2(-6, -4)]), col.darkened(0.25))
			ci.draw_line(hc + Vector2(-9, 1), hc + Vector2(9, 1), INK, 5.0)
			ci.draw_circle(hc + Vector2(-3.6, 1), 1.3, BONE)
			ci.draw_circle(hc + Vector2(3.2, 1), 1.3, BONE)
		BARD:
			_body(ci, col, fx, ph, walk, panic, t)
			_head(ci)
			_hat(ci, PackedVector2Array([hc + Vector2(-12, -4), hc + Vector2(-6, -11), hc + Vector2(6, -12), hc + Vector2(13, -5), hc + Vector2(0, -3)]), col.darkened(0.2))
			stick(ci, hc + Vector2(fx * 6, -10), hc + Vector2(fx * 15, -22), Color("f0ead8"), 2.0)
			cel1(ci, oval(Vector2(fx * 11, 7), 8, 9.5, 12), Vector2(fx * 11, 7), Color("b07a40"), 2.4, 3.0)
			stick(ci, Vector2(fx * 11, 0), Vector2(fx * 20, -14), Color("6a4628"), 2.4)
			ci.draw_circle(Vector2(fx * 11, 8), 2.6, INK)
		BOMBER:
			var barrel := oval(Vector2(0, 5), 13, 13, 14)
			cel1(ci, barrel, Vector2(0, 5), Color("7a5232"), 2.6, 4.0)
			ci.draw_line(Vector2(-12, 0), Vector2(12, 0), INK, 2.2)
			ci.draw_line(Vector2(-12, 10), Vector2(12, 10), INK, 2.2)
			var bst := sin(ph) * walk
			ci.draw_line(Vector2(-6 + bst * 3.0, 18), Vector2(-6 + bst * 4.0, 21 - maxf(0.0, cos(ph) * walk) * 3.0), INK, 5.5)
			ci.draw_line(Vector2(6 - bst * 3.0, 18), Vector2(6 - bst * 4.0, 21 - maxf(0.0, -cos(ph) * walk) * 3.0), INK, 5.5)
			_head(ci)
			ci.draw_line(hc + Vector2(-9.5, -3), hc + Vector2(9.5, -3), col, 4.0)
			ci.draw_line(Vector2(6, -6), Vector2(13, -20), Color("d8c090"), 2.6)
			ci.draw_circle(Vector2(13, -20), 3.4 + sin(t * 20.0), C_GOLD)
		DOG:
			var di := 0
			for lx in [-9.0, -4.0, 5.0, 10.0]:
				var dsw := sin(ph * 1.6 + di * PI * 0.5 + (PI if di > 1 else 0.0)) * walk
				ci.draw_line(Vector2(lx, 6), Vector2(lx + dsw * 5.0, 14 - maxf(0.0, dsw) * 2.5), INK, 4.6)
				di += 1
			cel1(ci, oval(Vector2(0, 3), 14, 8, 12), Vector2(0, 3), col, 2.4, 3.0)
			stick(ci, Vector2(-fx * 13, 0), Vector2(-fx * (19.0 + 3.0 * sin(t * 15.0 + ph)), -8), col, 2.4)
			var dh := Vector2(fx * 14, -4)
			cel1(ci, oval(dh, 7.5, 6.5, 10), dh, col.lightened(0.08), 2.4, 2.4)
			shape(ci, PackedVector2Array([dh + Vector2(-5, -5), dh + Vector2(-2, -12), dh + Vector2(1, -5)]), col.darkened(0.3), 2.0)
			ci.draw_circle(dh + Vector2(fx * 2.5, -1), 1.3, INK)
			ci.draw_circle(dh + Vector2(fx * 7, 1.5), 1.8, INK)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _body(ci: CanvasItem, col: Color, fx: float, ph: float, mv: float, panic: float, t: float, wt := 9.0, wb := 13.0, y1 := 14.0) -> void:
	var st := sin(ph) * mv
	var ct := cos(ph) * mv
	var arm := col.darkened(0.32)
	# The free hand hangs and swings; both go up when there is something to panic about.
	var wave := sin(t * 16.0) * 2.0
	var hand := Vector2(-fx * (wb + 2.5), 7.0 - st * 3.0).lerp(Vector2(-fx * (wt + 6.0) + wave, -20.0), panic)
	stick(ci, Vector2(-fx * (wt - 1.5), -3.0), hand, arm, 2.4)
	var hand2 := Vector2(fx * 12.0, 5.0).lerp(Vector2(fx * (wt + 6.0) - wave, -20.0), panic * 0.5)
	stick(ci, Vector2(fx * (wt - 1.5), -3.0), hand2, arm, 2.4)
	var body := PackedVector2Array([Vector2(-wt, -6), Vector2(wt, -6), Vector2(wb, y1), Vector2(-wb, y1)])
	cel1(ci, body, Vector2(0, 4), col, 2.6, 4.0)
	# One foot steps while the other plants.
	ci.draw_line(Vector2(-6 + st * 3.0, y1 + 1), Vector2(-6 + st * 4.5, y1 + 5 - maxf(0.0, ct) * 3.5), INK, 5.5)
	ci.draw_line(Vector2(6 - st * 3.0, y1 + 1), Vector2(6 - st * 4.5, y1 + 5 - maxf(0.0, -ct) * 3.5), INK, 5.5)


static func _head(ci: CanvasItem) -> void:
	var hc := Vector2(0, -15)
	cel(ci, oval(hc, 9.5, 9.5, 16), hc, SKIN, SKIN.lerp(Color("b0606a"), 0.45), SKIN.darkened(0.68), 2.6, 3.6)
	ci.draw_circle(hc + Vector2(-3.6, 1), 1.5, INK)
	ci.draw_circle(hc + Vector2(3.2, 1), 1.5, INK)


static func _hat(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	cel1(ci, pts, Vector2(0, -21), col, 2.4, 2.8)


# ---------------------------------------------------------------- the Bog Toad

static func _toad_eye(ci: CanvasItem, c: Vector2, r: float, look: Vector2, lid_col: Color, shut: bool, droop := 0.3) -> void:
	ci.draw_circle(c, r + 2.6, INK)
	if shut:
		ci.draw_circle(c, r, lid_col)
		ci.draw_line(c + Vector2(-r * 0.8, r * 0.2), c + Vector2(r * 0.8, r * 0.2), INK, 2.6)
		return
	ci.draw_circle(c, r, Color("f2ecd8"))
	ci.draw_circle(c + look * r * 0.3 + Vector2(0, r * 0.15), r * 0.52, Color("d0a030"))
	ci.draw_circle(c + look * r * 0.38 + Vector2(0, r * 0.15), r * 0.27, INK)
	ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.2), r * 0.16, Color.WHITE)
	var lid := PackedVector2Array()
	var a0 := PI - droop
	var a1 := TAU + droop
	for i in 11:
		var a := a0 + (a1 - a0) * i / 10.0
		lid.append(c + Vector2(cos(a), sin(a)) * (r + 1.0))
	ci.draw_colored_polygon(lid, lid_col)
	ci.draw_line(lid[0], lid[10], INK, 2.6)


## The toad around `pos` (his middle), `s` = scale of his ~200x150 body.
## mood: "nap" (eyes shut, snoring), "awake" (grumpy, looking at `look`), "angry" (red, mouth open).
static func draw_toad(ci: CanvasItem, pos: Vector2, s: float, t: float, mood := "nap", look := Vector2(0, 1), wob := 0.0,
		p_skin := TOAD, hat := "") -> void:
	var skin := p_skin
	if mood == "angry":
		skin = Color("c0584a")
	var band := skin.lerp(Color("9a8440"), 0.6).darkened(0.1)
	var dark := Color("1a1e0e")
	var napping := mood == "nap"
	var talk := absf(sin(t * 13.0)) if mood == "angry" else 0.0
	var blink := fmod(t * 0.29, 1.0) < 0.04
	var wsx := 1.0 + 0.07 * wob * sin(t * 38.0)
	var wsy := 1.0 - 0.07 * wob * sin(t * 38.0)
	ci.draw_set_transform_matrix(Transform2D(0.05 * wob * sin(t * 31.0), Vector2(wsx, wsy) * s, 0.0, pos))
	var breathe := 1.0 + (0.035 if napping else 0.02) * sin(t * (1.6 if napping else 2.2))
	# Back legs folded at his sides.
	for sx in [-1.0, 1.0]:
		var lc := Vector2(sx * 78.0, 30.0)
		cel(ci, blobp(lc, 34, 30, 12, 60, 0.1), lc, skin.darkened(0.12), band, dark, 4.0, 6.0)
	var body := blobp(Vector2.ZERO, 100.0 * breathe, 64.0 / breathe, 22, 9, 0.06)
	cel(ci, body, Vector2.ZERO, skin, band, dark, 5.0, 14.0)
	# Pale belly, warts and his two mushrooms.
	ci.draw_colored_polygon(oval(Vector2(-6, 34), 60, 22, 16), Color("c8c08a"))
	for w in [Vector2(-70, -18), Vector2(52, -34), Vector2(74, -8)]:
		ci.draw_circle(w, 7, INK)
		ci.draw_circle(w + Vector2(-1, -1), 5, skin.lightened(0.18))
	for mp in [Vector2(-34, -60), Vector2(50, -54)]:
		ci.draw_line(mp + Vector2(0, 14), mp, BONE, 6.0)
		shape(ci, PackedVector2Array([mp + Vector2(-13, 2), mp + Vector2(-8, -9), mp + Vector2(8, -9), mp + Vector2(13, 2)]), Color("b04a3a"), 3.0)
	_draw_hat(ci, hat, Vector2(0, -66), t)
	# Eyes on their bumps.
	for sx in [-1.0, 1.0]:
		var ec := Vector2(sx * 40, -58)
		ci.draw_circle(ec, 27, INK)
		ci.draw_circle(ec, 23.5, skin)
		_toad_eye(ci, ec + Vector2(0, 3), 17, look, skin.darkened(0.2), napping or blink, 0.3 if mood == "awake" else (-0.2 if mood == "angry" else 0.3))
	# The mouth: the whole front of him.
	if napping:
		ci.draw_polyline(PackedVector2Array([Vector2(-80, 0), Vector2(-40, 8), Vector2(40, 8), Vector2(80, 0)]), INK, 5.0, true)
	else:
		var gape := 0.35 + 0.65 * talk if mood == "angry" else 0.25
		var mouth := PackedVector2Array([Vector2(-86, -6), Vector2(-40, -16), Vector2(40, -16), Vector2(86, -6), Vector2(60, 26 * gape), Vector2(0, 36 * gape), Vector2(-60, 26 * gape)])
		shape(ci, mouth, Color("3a1420"), 4.5)
		ci.draw_colored_polygon(oval(Vector2(0, 22 * gape - 4), 38, 8 * gape + 2, 12), C_TONGUE.darkened(0.15))
		for i in 7:
			var p0 := Vector2(60, 26 * gape).lerp(Vector2(0, 36 * gape), minf(1.0, i / 3.5)) if i < 4 else Vector2(0, 36 * gape).lerp(Vector2(-60, 26 * gape), (i - 3.5) / 3.5)
			ci.draw_colored_polygon(PackedVector2Array([p0 + Vector2(-8, 0), p0 + Vector2(8, 0), p0 + Vector2(0, -13)]), BONE)
	# Little front hands.
	for sx in [-1.0, 1.0]:
		shape(ci, moved(PackedVector2Array([Vector2(sx * 44, 52), Vector2(sx * 62, 64), Vector2(sx * 56, 74), Vector2(sx * 34, 70)]), Vector2(0, 3.0 * sin(t * 2.2 + sx)), 1.0, Vector2.ZERO), skin.darkened(0.12), 3.5)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## The toad's hat (wardrobe), drawn in his own coordinates with the brim at `b`.
static func _draw_hat(ci: CanvasItem, hat: String, b: Vector2, t: float) -> void:
	match hat:
		"nightcap":
			var tip := b + Vector2(-58, -6 + sin(t * 1.5) * 3)
			shape(ci, PackedVector2Array([b + Vector2(-32, 4), b + Vector2(-8, -42), b + Vector2(20, -40), b + Vector2(32, 4)]), Color("5a7fc0"), 4.0)
			shape(ci, PackedVector2Array([b + Vector2(-8, -42), b + Vector2(20, -40), tip + Vector2(10, 4), tip + Vector2(6, -6)]), Color("5a7fc0"), 4.0)
			ci.draw_circle(tip, 11, INK)
			ci.draw_circle(tip, 8, BONE)
			shape(ci, PackedVector2Array([b + Vector2(-36, 0), b + Vector2(36, 0), b + Vector2(36, 12), b + Vector2(-36, 12)]), BONE, 4.0)
		"flower":
			for k in 6:
				var a := TAU * k / 6.0 + t * 0.3
				var p := b + Vector2(0, -16) + Vector2(cos(a), sin(a)) * 14
				ci.draw_circle(p, 12, INK)
				ci.draw_circle(p, 9, Color("e88aa8"))
			ci.draw_circle(b + Vector2(0, -16), 10, INK)
			ci.draw_circle(b + Vector2(0, -16), 7, C_GOLD)
		"tophat":
			shape(ci, PackedVector2Array([b + Vector2(-24, 2), b + Vector2(-22, -56), b + Vector2(22, -56), b + Vector2(24, 2)]), Color("2a2430"), 4.0)
			ci.draw_rect(Rect2(b + Vector2(-23, -16), Vector2(46, 9)), Color("b04a3a"))
			shape(ci, PackedVector2Array([b + Vector2(-40, 0), b + Vector2(40, 0), b + Vector2(40, 10), b + Vector2(-40, 10)]), Color("2a2430"), 4.0)
		"viking":
			for sx in [-1.0, 1.0]:
				shape(ci, PackedVector2Array([b + Vector2(sx * 26, -10), b + Vector2(sx * 58, -40), b + Vector2(sx * 50, -4)]), BONE, 4.0)
			var dome := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				dome.append(b + Vector2(cos(a) * 34, sin(a) * 34 + 4))
			shape(ci, dome, Color("8a8a9a"), 4.0)
			ci.draw_line(b + Vector2(0, -28), b + Vector2(0, 4), Color("5a5a6a"), 5.0)
		"wizard":
			shape(ci, PackedVector2Array([b + Vector2(-30, 2), b + Vector2(6, -76), b + Vector2(30, 2)]), Color("6a4a90"), 4.0)
			for p in [Vector2(-6, -24), Vector2(8, -44), Vector2(12, -12)]:
				ci.draw_circle(b + p, 4, C_GOLD)
			shape(ci, PackedVector2Array([b + Vector2(-44, 0), b + Vector2(44, 0), b + Vector2(44, 10), b + Vector2(-44, 10)]), Color("6a4a90"), 4.0)
		"crown":
			shape(ci, PackedVector2Array([b + Vector2(-30, 4), b + Vector2(-34, -30), b + Vector2(-16, -12), b + Vector2(0, -38),
				b + Vector2(16, -12), b + Vector2(34, -30), b + Vector2(30, 4)]), C_GOLD, 4.0)
			ci.draw_circle(b + Vector2(0, -8), 6, Color("c0584a"))
		"party":
			shape(ci, PackedVector2Array([b + Vector2(-26, 2), b + Vector2(0, -64), b + Vector2(26, 2)]), Color("e070c0"), 4.0)
			for k in 3:
				var y := -14.0 - k * 16.0
				var w := 22.0 - k * 7.0
				ci.draw_line(b + Vector2(-w, y), b + Vector2(w, y + 6), C_GOLD, 4.0)
			ci.draw_circle(b + Vector2(0, -66), 9, INK)
			ci.draw_circle(b + Vector2(0, -66), 6, Color("6aa0c0"))
		"mushroom":
			ci.draw_rect(Rect2(b + Vector2(-8, -16), Vector2(16, 18)), BONE)
			var cap := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				cap.append(b + Vector2(cos(a) * 42, sin(a) * 34 - 12))
			shape(ci, cap, Color("c0443a"), 4.0)
			for p in [Vector2(-18, -26), Vector2(6, -36), Vector2(24, -20)]:
				ci.draw_circle(b + p, 6, BONE)


## His nest of furs, with a pillow and somebody's shield for a headboard (from FMM's lair).
static func draw_nest(ci: CanvasItem, c: Vector2, rx: float, ry: float) -> void:
	var sx := rx / 62.0
	var sy := ry / 28.0
	ci.draw_set_transform_matrix(Transform2D(0.0, Vector2(sx, sy), 0.0, c))
	cel(ci, blobp(Vector2.ZERO, 62, 28, 16, 11, 0.12), Vector2.ZERO, NEST, Color("7a3a3a"), Color("2a1a14"), 3.0 / sx, 7.0)
	cel(ci, blobp(Vector2(-6, -5), 46, 18, 14, 12, 0.14), Vector2.ZERO, FUR, Color("a86a5a"), Color("4a3828"), 2.5 / sx, 5.0)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
