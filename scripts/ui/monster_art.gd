class_name MonsterArt
extends RefCounted
## The shop's little monsters, snacks and charms, drawn in the inked, cel-shaded FMM style.
## Everything is drawn in a 100x100 box around the centre, then scaled to the radius asked for.

const INK := FmmArt.INK
const WHITE := Color("f2ecd8")
const LW := 5.0


static func _begin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(r / 50.0, r / 50.0))


static func _end(ci: CanvasItem) -> void:
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _fill(ci: CanvasItem, pts: PackedVector2Array, col: Color, about := Vector2.ZERO) -> void:
	FmmArt.cel1(ci, pts, about, col, LW, 6.0)


static func _flat(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	FmmArt.shape(ci, pts, col, LW)


static func _circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r + LW * 0.5, INK)
	ci.draw_circle(c, r - LW * 0.5, col)


static func _tri(a: Vector2, b: Vector2, c: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c])


static func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


## look: {"body", "eyes", "mouth", "extra": [...]} from Jokers.JOKERS.
static func draw(ci: CanvasItem, look: Dictionary, c: Vector2, r: float, t: float, col: Color, seed_: int) -> void:
	var bob := sin(t * 2.5 + c.x * 0.01) * 2.5
	_begin(ci, c + Vector2(0, bob * r / 50.0), r)
	var extra: Array = look.get("extra", [])
	var body := str(look.get("body", "blob"))
	var dark := col.darkened(0.35)
	var face := Vector2(0, 0)
	match body:
		"tall", "box":
			face = Vector2(0, -6)
		"small":
			face = Vector2(0, 6)
		"wide":
			face = Vector2(0, 8)
		"grub":
			face = Vector2(-18, 0)
		"stalk":
			face = Vector2(0, 22)
		"snail":
			face = Vector2(-26, 0)
		"skull":
			face = Vector2(0, -4)
		"ghost":
			face = Vector2(0, -8)
		"eel":
			face = Vector2(-28, -8)
		"slug":
			face = Vector2(-26, 0)

	# Behind the body.
	if extra.has("bat_wings"):
		for sx in [-1.0, 1.0]:
			var w := PackedVector2Array([Vector2(sx * 14, -6), Vector2(sx * 50, -30 + sin(t * 9.0) * 6), Vector2(sx * 44, -8),
				Vector2(sx * 50, 4), Vector2(sx * 38, 6), Vector2(sx * 40, 18), Vector2(sx * 18, 12)])
			_flat(ci, w, dark)
	if extra.has("moth_wings"):
		for sx in [-1.0, 1.0]:
			var flap := 1.0 + sin(t * 7.0) * 0.08
			_fill(ci, FmmArt.oval(Vector2(sx * 34 * flap, -6), 24, 30, 16), col.lightened(0.2), Vector2(sx * 34, -6))
			ci.draw_circle(Vector2(sx * 34 * flap, -4), 7, dark)
	if extra.has("legs"):
		for sx in [-1.0, 1.0]:
			for k in 4:
				var a := Vector2(sx * 18, 2 + k * 6)
				var kn := Vector2(sx * (38 + k * 2), -14 + k * 12 + sin(t * 8.0 + k) * 2)
				var ft := Vector2(sx * 48, 18 + k * 9)
				ci.draw_polyline(PackedVector2Array([a, kn, ft]), INK, 6.0, true)
	if extra.has("tentacles"):
		for k in 5:
			var x0 := -28.0 + k * 14
			var pts := PackedVector2Array()
			for j in 7:
				var y := 22.0 + j * 5
				pts.append(Vector2(x0 + sin(t * 4.0 + k + j * 0.7) * 5 + (x0 * 0.04) * j * 3, y))
			ci.draw_polyline(pts, INK, 13.0, true)
			ci.draw_polyline(pts, col.darkened(0.15), 7.0, true)
	if extra.has("tail"):
		var pts := PackedVector2Array()
		for j in 9:
			pts.append(Vector2(30 + j * 3, 22 - j * 3 + sin(t * 5.0 + j * 0.8) * 3))
		ci.draw_polyline(pts, INK, 9.0, true)
		ci.draw_polyline(pts, col.lightened(0.15), 4.0, true)
	if extra.has("tadpoles"):
		for k in 2:
			var p := Vector2(-38 + k * 70, -30 + k * 8 + sin(t * 3.0 + k * 2.0) * 4)
			ci.draw_line(p, p + Vector2(10, 6), INK, 5.0, true)
			_circle(ci, p, 7, col.lightened(0.1))
	if extra.has("spikes"):
		for k in 9:
			var a := PI + PI * (k + 0.5) / 9.0
			var base := Vector2(cos(a), sin(a) * 0.75) * 40 + Vector2(0, 8)
			var tip := Vector2(cos(a), sin(a) * 0.75) * 58 + Vector2(0, 8)
			var side := Vector2(-sin(a), cos(a)) * 8
			_flat(ci, _tri(base - side, tip, base + side), dark)
	if extra.has("ears_pointy"):
		for sx in [-1.0, 1.0]:
			var top := face.y - 34
			_flat(ci, _tri(Vector2(sx * 14, top + 10), Vector2(sx * 44, top - 14), Vector2(sx * 32, top + 22)), col)
	if extra.has("ears_round"):
		for sx in [-1.0, 1.0]:
			_circle(ci, Vector2(sx * 30, -30), 15, col)
			ci.draw_circle(Vector2(sx * 30, -30), 7, Color("e0a0a0"))
	if extra.has("horn"):
		_flat(ci, _tri(Vector2(-9, face.y - 38), Vector2(0, face.y - 62), Vector2(9, face.y - 38)), FmmArt.BONE)
	if extra.has("tufts"):
		for sx in [-1.0, 1.0]:
			_flat(ci, _tri(Vector2(sx * 12, -30), Vector2(sx * 36, -52), Vector2(sx * 34, -22)), dark)
	if extra.has("antennae"):
		for sx in [-1.0, 1.0]:
			var tip := Vector2(sx * 20 + sin(t * 3.0 + sx) * 3, face.y - 52)
			ci.draw_line(Vector2(sx * 8, face.y - 22), tip, INK, 4.0, true)
			_circle(ci, tip, 5, col.lightened(0.3))
	if extra.has("heads"):
		for sx in [-1.0, 1.0]:
			var hp := Vector2(sx * 40, -40 + sin(t * 2.5 + sx) * 4)
			ci.draw_line(Vector2(sx * 16, -10), hp, INK, 18.0, true)
			ci.draw_line(Vector2(sx * 16, -10), hp, col, 10.0, true)
			_fill(ci, FmmArt.oval(hp, 14, 12, 12), col, hp)
			ci.draw_circle(hp + Vector2(sx * 4, -3), 3.5, INK)
	if extra.has("flames"):
		for k in 3:
			var fx := -20.0 + k * 20.0
			var fh := 26.0 + sin(t * 9.0 + k * 2.0) * 6.0
			_flat(ci, PackedVector2Array([Vector2(fx - 9, -20), Vector2(fx, -20 - fh), Vector2(fx + 9, -20)]), Color("f0a030"))
	if extra.has("moon"):
		var mc := Vector2(-40, -44)
		_circle(ci, mc, 13, Color("f0e8b0"))
		ci.draw_circle(mc + Vector2(6, -4), 10, Color("3a3040"))
	if extra.has("curl_tail"):
		var pts := PackedVector2Array()
		for j in 22:
			var a := j * 0.42 + sin(t * 2.0) * 0.1
			var rad := 18.0 - j * 0.7
			pts.append(Vector2(36, 20) + Vector2(cos(a), sin(a)) * rad)
		ci.draw_polyline(pts, INK, 12.0, true)
		ci.draw_polyline(pts, col, 6.0, true)
	if extra.has("club"):
		var tip := Vector2(56, -52 + sin(t * 3.0) * 3)
		ci.draw_line(Vector2(34, 18), tip, INK, 14.0, true)
		ci.draw_line(Vector2(34, 18), tip, Color("a07a50"), 8.0, true)
		_fill(ci, FmmArt.oval(tip, 15, 17, 12), Color("a07a50"), tip)
	if extra.has("corner_shell"):
		var sh := PackedVector2Array([Vector2(-44, -4), Vector2(-44, -58), Vector2(-18, -58), Vector2(-18, -34), Vector2(44, -34), Vector2(44, -4)])
		_fill(ci, sh, Color("e0c890"), Vector2(-18, -34))
	if extra.has("pincers"):
		for sx in [-1.0, 1.0]:
			var p := Vector2(sx * 50, -8 + sin(t * 4.0 + sx) * 3)
			ci.draw_line(Vector2(sx * 34, 12), p, INK, 9.0, true)
			var claw := PackedVector2Array([p + Vector2(-10, 4), p + Vector2(-12, -14), p + Vector2(0, -6), p + Vector2(12, -16), p + Vector2(10, 6)])
			_flat(ci, claw, col)

	# The body.
	match body:
		"blob":
			_fill(ci, FmmArt.blobp(Vector2.ZERO, 42, 36, 16, seed_, 0.08), col)
		"drip":
			for k in 3:
				_flat(ci, FmmArt.oval(Vector2(-22 + k * 22, 30 + (k % 2) * 6), 8, 12, 10), col)
			_fill(ci, FmmArt.blobp(Vector2(0, -2), 44, 34, 16, seed_, 0.08), col)
		"tall":
			_fill(ci, FmmArt.oval(Vector2(0, 2), 32, 44, 18), col)
		"small":
			_fill(ci, FmmArt.oval(Vector2(0, 6), 30, 28, 16), col)
		"wide":
			_fill(ci, FmmArt.oval(Vector2(0, 8), 46, 30, 18), col)
		"lump":
			_fill(ci, FmmArt.blobp(Vector2.ZERO, 44, 38, 12, seed_, 0.16), col)
		"grub":
			for k in [2, 1]:
				var sc := Vector2(-18 + k * 24, 6 + k * 3)
				_fill(ci, FmmArt.oval(sc, 26 - k * 3, 24 - k * 3, 14), col.darkened(0.06 * k), sc)
			_fill(ci, FmmArt.oval(face, 28, 26, 16), col, face)
		"stalk":
			_fill(ci, FmmArt.oval(Vector2(0, 20), 24, 26, 14), FmmArt.BONE, Vector2(0, 20))
		"skull":
			_fill(ci, _rect(-20, 14, 20, 34), col)
			_fill(ci, FmmArt.oval(Vector2(0, -6), 38, 34, 18), col)
		"square":
			_fill(ci, FmmArt.blobp(Vector2.ZERO, 44, 42, 8, seed_, 0.1), col)
		"snail":
			var foot := FmmArt.oval(Vector2(-4, 22), 46, 14, 16)
			_fill(ci, foot, col.lightened(0.3), Vector2(-4, 22))
			_fill(ci, FmmArt.oval(face, 18, 20, 12), col.lightened(0.3), face)
		"ghost":
			var g := PackedVector2Array()
			for k in 11:
				var a := PI + PI * k / 10.0
				g.append(Vector2(cos(a) * 36, -8 + sin(a) * 36))
			for k in 9:
				var x := 36.0 - k * 9.0
				g.append(Vector2(x, 34 + (6 if k % 2 == 0 else -2) + sin(t * 4.0 + k) * 2))
			_fill(ci, g, col)
		"box":
			_fill(ci, _rect(-40, -10, 40, 36), col)
			ci.draw_line(Vector2(-40, 12), Vector2(40, 12), C_TRIM, 5.0)
		"eel":
			var pts := PackedVector2Array()
			for j in 12:
				var x := -26.0 + j * 7.0
				pts.append(Vector2(x, 2 + sin(t * 4.0 - j * 0.7) * 9 * j / 11.0))
			ci.draw_polyline(pts, INK, 30.0, true)
			ci.draw_polyline(pts, col, 20.0, true)
			ci.draw_polyline(pts, col.lightened(0.25), 6.0, true)
			_fill(ci, FmmArt.oval(face, 22, 20, 14), col, face)
		"slug":
			_fill(ci, FmmArt.oval(Vector2(8, 16), 48, 20, 18), col, Vector2(8, 16))
			_fill(ci, FmmArt.oval(face, 22, 22, 14), col, face)
		_:
			_fill(ci, FmmArt.oval(Vector2.ZERO, 40, 36, 16), col)

	# In front of the body.
	if extra.has("shell"):
		var sc := Vector2(14, -4)
		_fill(ci, FmmArt.oval(sc, 30, 28, 18), col.darkened(0.2), sc)
		var sp := PackedVector2Array()
		for k in 26:
			var a := k * 0.5
			sp.append(sc + Vector2(cos(a), sin(a)) * (3.0 + k * 0.85))
		ci.draw_polyline(sp, INK, 4.0, true)
	if extra.has("cap"):
		var cap := PackedVector2Array()
		for k in 15:
			var a := PI + PI * k / 14.0
			cap.append(Vector2(cos(a) * 48, 4 + sin(a) * 40))
		_fill(ci, cap, col, Vector2(0, -10))
		for p in [Vector2(-24, -14), Vector2(4, -26), Vector2(26, -10), Vector2(-4, -6)]:
			ci.draw_circle(p, 6, WHITE)
	if extra.has("lid"):
		_fill(ci, PackedVector2Array([Vector2(-44, -12), Vector2(-38, -44), Vector2(38, -44), Vector2(44, -12)]), col.darkened(0.08))
		ci.draw_line(Vector2(-41, -28), Vector2(41, -28), C_TRIM, 5.0)
		_flat(ci, _rect(-7, -18, 7, -4), C_TRIM)
	if extra.has("brow"):
		ci.draw_line(face + Vector2(-26, -20), face + Vector2(26, -20), col.darkened(0.45), 10.0, true)
	if extra.has("cracks"):
		ci.draw_polyline(PackedVector2Array([Vector2(-30, -26), Vector2(-20, -16), Vector2(-26, -6)]), INK, 3.0, true)
		ci.draw_polyline(PackedVector2Array([Vector2(28, 14), Vector2(18, 22), Vector2(24, 32)]), INK, 3.0, true)
	if extra.has("claws"):
		for sx in [-1.0, 1.0]:
			var p := Vector2(sx * 30, 28)
			_fill(ci, FmmArt.oval(p, 13, 9, 10), FmmArt.SKIN, p)
			for k in 3:
				ci.draw_line(p + Vector2(-6 + k * 6, 4), p + Vector2(-7 + k * 6, 13), FmmArt.BONE, 3.0, true)
	if extra.has("coin"):
		_circle(ci, Vector2(30, 28), 12, FmmArt.C_GOLD)
		ci.draw_line(Vector2(30, 21), Vector2(30, 35), Color("b08a30"), 3.0)
	if extra.has("clover"):
		for k in 4:
			var a := TAU * k / 4.0 + PI / 4.0
			_circle(ci, Vector2(18, -34) + Vector2(cos(a), sin(a)) * 7, 7, Color("5aa04a"))
	if extra.has("bone"):
		ci.draw_line(Vector2(-34, 34), Vector2(34, 24), INK, 13.0, true)
		ci.draw_line(Vector2(-34, 34), Vector2(34, 24), WHITE, 7.0, true)
		for p in [Vector2(-34, 34), Vector2(34, 24)]:
			for d in [Vector2(-2, -5), Vector2(2, 5)]:
				_circle(ci, p + d, 5, WHITE)

	if extra.has("bud"):
		var bp := Vector2(0, face.y - 30)
		ci.draw_line(bp + Vector2(0, 14), bp, Color("5aa04a"), 5.0, true)
		_fill(ci, FmmArt.oval(bp, 10, 13, 12), Color("e090c0"), bp)
	if extra.has("shine"):
		ci.draw_line(Vector2(-30, -24), Vector2(-14, -36), Color(1, 1, 1, 0.7), 5.0, true)
		ci.draw_line(Vector2(-30, -12), Vector2(-24, -17), Color(1, 1, 1, 0.7), 4.0, true)
	if extra.has("party_hat"):
		var top := face.y - 32
		_flat(ci, _tri(Vector2(-16, top + 4), Vector2(4, top - 36), Vector2(18, top + 2)), Color("f0d060"))
		ci.draw_circle(Vector2(4, top - 38), 6, Color("4a8ae0"))
	if extra.has("bag"):
		_fill(ci, FmmArt.oval(Vector2(30, 28), 14, 12, 12), Color("a07a50"), Vector2(30, 28))
		ci.draw_circle(Vector2(30, 18), 4, FmmArt.C_GOLD)
	if extra.has("mirror"):
		_fill(ci, FmmArt.oval(Vector2(-40, 0), 13, 18, 14), Color("d0e0f0"), Vector2(-40, 0))
		ci.draw_line(Vector2(-44, -8), Vector2(-38, -14), WHITE, 3.0, true)
	if extra.has("fuse"):
		var bc := Vector2(30, -26)
		_circle(ci, bc, 13, Color("2a2a30"))
		ci.draw_line(bc + Vector2(6, -11), bc + Vector2(14, -22), INK, 3.0, true)
		ci.draw_circle(bc + Vector2(14, -22), 4.0 + sin(t * 14.0) * 1.5, Color("f0a030"))
	if extra.has("drum"):
		var dc := Vector2(0, 30)
		_fill(ci, _rect(-20, 22, 20, 42), Color("c05040"), dc)
		ci.draw_line(Vector2(-20, 22), Vector2(20, 22), WHITE, 5.0)
		for sx in [-1.0, 1.0]:
			var st := Vector2(sx * 26, 6 + absf(sin(t * 6.0 + sx)) * -8)
			ci.draw_line(Vector2(sx * 14, 22), st, INK, 5.0, true)
	if extra.has("coins"):
		for k in 3:
			var cp := Vector2(30, 34 - k * 8)
			_fill(ci, FmmArt.oval(cp, 12, 5, 12), FmmArt.C_GOLD, cp)
	if extra.has("tophat"):
		var top := face.y - 40
		_flat(ci, _rect(-26, top + 6, 26, top + 12), INK)
		_flat(ci, _rect(-16, top - 26, 16, top + 8), Color("2a2a34"))
		ci.draw_line(Vector2(-16, top + 2), Vector2(16, top + 2), Color("a04040"), 5.0)
	if extra.has("tag"):
		var tg := Vector2(30, 24)
		_flat(ci, PackedVector2Array([tg + Vector2(-8, -10), tg + Vector2(14, -10), tg + Vector2(14, 10), tg + Vector2(-8, 10), tg + Vector2(-16, 0)]), WHITE)
		ci.draw_circle(tg + Vector2(-8, 0), 2.5, INK)
		ci.draw_string(ThemeDB.fallback_font, tg + Vector2(-2, 6), "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	if extra.has("crown"):
		var top := face.y - 36
		var cr := PackedVector2Array([Vector2(-22, top + 8), Vector2(-24, top - 16), Vector2(-12, top - 4), Vector2(0, top - 22),
			Vector2(12, top - 4), Vector2(24, top - 16), Vector2(22, top + 8)])
		_flat(ci, cr, FmmArt.C_GOLD)
		ci.draw_circle(Vector2(0, top - 2), 4, Color("d04848"))
	if extra.has("halo"):
		var hy := face.y - 46 + sin(t * 2.0) * 2
		ci.draw_arc(Vector2(0, hy), 18, 0, TAU, 24, INK, 9.0, true)
		ci.draw_arc(Vector2(0, hy), 18, 0, TAU, 24, Color("f0d060"), 5.0, true)
	if extra.has("rings"):
		for k in 2:
			var rr := 10.0 + fmod(t * 20.0 + k * 12.0, 24.0)
			ci.draw_arc(Vector2(0, face.y + 18), rr + 16, PI * 0.25, PI * 0.75, 10, Color(WHITE, 1.0 - rr / 34.0), 3.0, true)
	if extra.has("zzz"):
		for k in 3:
			var zp := Vector2(28 + k * 9, -40 - k * 12 - fmod(t * 8.0, 8.0))
			ci.draw_string(ThemeDB.fallback_font, zp, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 14 + k * 4, WHITE)
	if extra.has("rock"):
		_fill(ci, FmmArt.blobp(Vector2(26, 26), 15, 12, 8, 3, 0.15), Color("8a8274"), Vector2(26, 26))
	if extra.has("leaves"):
		for k in 3:
			var a := -PI / 2.0 + (k - 1) * 0.6
			var b := Vector2(0, face.y - 22) + Vector2(cos(a), sin(a)) * 6
			var tip := Vector2(0, face.y - 22) + Vector2(cos(a), sin(a)) * 30
			var side := Vector2(-sin(a), cos(a)) * 8
			_flat(ci, PackedVector2Array([b, (b + tip) / 2.0 + side, tip, (b + tip) / 2.0 - side]), Color("5aa04a"))
	if extra.has("heart"):
		var hc := Vector2(10, 18)
		_flat(ci, PackedVector2Array([hc + Vector2(0, 12), hc + Vector2(-12, 0), hc + Vector2(-10, -8), hc + Vector2(-4, -9),
			hc + Vector2(0, -4), hc + Vector2(4, -9), hc + Vector2(10, -8), hc + Vector2(12, 0)]), Color("e04a5a"))
	if extra.has("bubbles"):
		for k in 4:
			var bp := Vector2(-38 + k * 24, -40 - fmod(t * 14.0 + k * 9.0, 18.0))
			ci.draw_arc(bp, 6.0 + k % 2 * 3.0, 0, TAU, 14, INK, 3.0, true)
			ci.draw_circle(bp, 4.0 + k % 2 * 3.0, Color(1, 1, 1, 0.35))
	if extra.has("splats"):
		var cols := [Color("e04a5a"), Color("4a8ae0"), Color("f0d060")]
		for k in 3:
			_circle(ci, Vector2(-22 + k * 20, 26 - (k % 2) * 6), 6, cols[k])
	if extra.has("patches"):
		var cols := [Color("e04a5a"), Color("4a8ae0"), Color("f0d060"), Color("6ab04a")]
		for k in 4:
			_flat(ci, _rect(-4 + k * 12, 6 + (k % 2) * 6, 6 + k * 12, 16 + (k % 2) * 6), cols[k])

	if extra.has("mask"):
		_flat(ci, _rect(face.x - 30, face.y - 12, face.x + 30, face.y + 6), Color("2a2420"))
	_eyes(ci, look.get("eyes", 2), face, t, col)
	if extra.has("nose"):
		_circle(ci, face + Vector2(0, 8), 7, Color("d07a8a"))
	if extra.has("whiskers"):
		for sx in [-1.0, 1.0]:
			for k in 2:
				ci.draw_line(face + Vector2(sx * 16, 10 + k * 6), face + Vector2(sx * 40, 6 + k * 10), INK, 2.5, true)
	_mouth(ci, str(look.get("mouth", "line")), face + Vector2(0, 18))
	if extra.has("ledge"):
		# Peeking over the edge of the board.
		_flat(ci, _rect(-50, 22, 50, 46), Color("4a3a2c"))
		for k in 4:
			ci.draw_line(Vector2(-50 + k * 33, 22), Vector2(-50 + k * 33, 46), INK, 3.0)
		for sx in [-1.0, 1.0]:
			_fill(ci, FmmArt.oval(Vector2(sx * 22, 22), 9, 6, 10), col, Vector2(sx * 22, 22))
	_end(ci)


const C_TRIM := Color("e0b040")


static func _eye(ci: CanvasItem, p: Vector2, r: float, look: Vector2) -> void:
	ci.draw_circle(p, r + 3.0, INK)
	ci.draw_circle(p, r, WHITE)
	ci.draw_circle(p + look * r * 0.3, r * 0.48, INK)
	ci.draw_circle(p + look * r * 0.3 + Vector2(-r * 0.15, -r * 0.2), r * 0.16, Color(1, 1, 1, 0.9))


static func _eyes(ci: CanvasItem, kind, face: Vector2, t: float, col: Color) -> void:
	var look := Vector2(sin(t * 0.9) * 0.6, 0.2)
	var blink := fmod(t + face.x, 4.0) < 0.12
	var e := face + Vector2(0, -10)
	match kind:
		1:
			if blink:
				ci.draw_line(e + Vector2(-14, 0), e + Vector2(14, 0), INK, 5.0, true)
			else:
				_eye(ci, e, 15, look)
		4:
			for k in 4:
				ci.draw_circle(e + Vector2(-15 + k * 10, (k % 2) * -6), 5.0, Color("e04848"))
				ci.draw_circle(e + Vector2(-15 + k * 10, (k % 2) * -6), 2.0, INK)
		"sleepy":
			for sx in [-1.0, 1.0]:
				ci.draw_arc(e + Vector2(sx * 15, 0), 8, 0.2, PI - 0.2, 8, INK, 4.0, true)
		"small":
			for sx in [-1.0, 1.0]:
				ci.draw_circle(e + Vector2(sx * 13, 0), 5.0, INK)
				ci.draw_circle(e + Vector2(sx * 13 - 1.5, -1.5), 1.6, WHITE)
		"holes":
			for sx in [-1.0, 1.0]:
				ci.draw_colored_polygon(FmmArt.oval(e + Vector2(sx * 14, 0), 9, 11, 12), Color("2a1e18"))
		"big":
			for sx in [-1.0, 1.0]:
				ci.draw_circle(e + Vector2(sx * 17, 0), 16.0, INK)
				ci.draw_circle(e + Vector2(sx * 17, 0), 13.0, Color("f0c040"))
				ci.draw_circle(e + Vector2(sx * 17, 0) + look * 3.0, 7.0, INK)
		"specs":
			for sx in [-1.0, 1.0]:
				ci.draw_circle(e + Vector2(sx * 14, 0), 3.5, INK)
				ci.draw_arc(e + Vector2(sx * 14, 0), 11, 0, TAU, 18, FmmArt.C_GOLD, 3.0, true)
			ci.draw_line(e + Vector2(-3, 0), e + Vector2(3, 0), FmmArt.C_GOLD, 3.0)
		"glow":
			for sx in [-1.0, 1.0]:
				ci.draw_line(e + Vector2(sx * 6, -2), e + Vector2(sx * 22, 2), Color("f0d060"), 6.0, true)
		"stalks":
			for sx in [-1.0, 1.0]:
				var tip := e + Vector2(sx * 14 + sin(t * 2.0 + sx) * 3, -28)
				ci.draw_line(e + Vector2(sx * 8, 0), tip, INK, 7.0, true)
				ci.draw_line(e + Vector2(sx * 8, 0), tip, col.lightened(0.3), 3.0, true)
				_eye(ci, tip, 8, look)
		"toad":
			for sx in [-1.0, 1.0]:
				var p := e + Vector2(sx * 22, -14)
				_fill(ci, FmmArt.oval(p, 14, 12, 12), col, p)
				_eye(ci, p, 8, look)
		_:
			for sx in [-1.0, 1.0]:
				if blink:
					ci.draw_line(e + Vector2(sx * 14 - 8, 0), e + Vector2(sx * 14 + 8, 0), INK, 4.0, true)
				else:
					_eye(ci, e + Vector2(sx * 14, 0), 10, look)


static func _mouth(ci: CanvasItem, kind: String, m: Vector2) -> void:
	match kind:
		"open":
			_flat(ci, FmmArt.oval(m + Vector2(0, 2), 12, 8, 12), Color("4a1e1e"))
		"o":
			_flat(ci, FmmArt.oval(m, 6, 7, 10), Color("4a1e1e"))
		"smile":
			ci.draw_arc(m + Vector2(0, -8), 12, 0.4, PI - 0.4, 10, INK, 4.0, true)
		"grin":
			_flat(ci, PackedVector2Array([m + Vector2(-18, -4), m + Vector2(18, -4), m + Vector2(10, 8), m + Vector2(-10, 8)]), Color("4a1e1e"))
			ci.draw_line(m + Vector2(-14, -2), m + Vector2(14, -2), WHITE, 3.0)
		"teeth":
			ci.draw_line(m + Vector2(-16, 0), m + Vector2(16, 0), INK, 4.0, true)
			for k in 3:
				_flat(ci, _rect(-11 + k * 8, 1, -5 + k * 8, 8), WHITE)
		"fangs":
			ci.draw_line(m + Vector2(-14, 0), m + Vector2(14, 0), INK, 4.0, true)
			for sx in [-1.0, 1.0]:
				_flat(ci, _tri(m + Vector2(sx * 9 - 4, 1), m + Vector2(sx * 9, 11), m + Vector2(sx * 9 + 4, 1)), WHITE)
		"tusks":
			ci.draw_line(m + Vector2(-16, 2), m + Vector2(16, 2), INK, 4.0, true)
			for sx in [-1.0, 1.0]:
				_flat(ci, _tri(m + Vector2(sx * 12 - 4, 4), m + Vector2(sx * 14, -12), m + Vector2(sx * 12 + 4, 4)), FmmArt.BONE)
		"huge":
			var pts := PackedVector2Array()
			for k in 13:
				var a := PI * k / 12.0
				pts.append(m + Vector2(-cos(a) * 32, -6 + sin(a) * 22))
			_flat(ci, pts, Color("4a1e1e"))
			for k in 5:
				_flat(ci, _tri(m + Vector2(-26 + k * 12, -6), m + Vector2(-20 + k * 12, 4), m + Vector2(-14 + k * 12, -6)), WHITE)
			_flat(ci, FmmArt.oval(m + Vector2(0, 10), 12, 5, 10), Color("e88aa8"))
		"beak":
			_flat(ci, _tri(m + Vector2(-8, -12), m + Vector2(8, -12), m + Vector2(0, 2)), Color("e0a040"))
		_:
			ci.draw_line(m + Vector2(-12, 0), m + Vector2(12, 0), INK, 4.0, true)


## Snack treats, one picture each.
static func draw_snack(ci: CanvasItem, icon: String, c: Vector2, r: float, col: Color) -> void:
	_begin(ci, c, r)
	match icon:
		"tongue":
			_fill(ci, FmmArt.oval(Vector2(0, 4), 40, 30, 18), col)
			ci.draw_line(Vector2(0, -16), Vector2(0, 20), col.darkened(0.4), 4.0, true)
		"fist":
			# A big impact star.
			var star := PackedVector2Array()
			for k in 16:
				var a := TAU * k / 16.0 - PI / 2.0
				star.append(Vector2(cos(a), sin(a)) * (44.0 if k % 2 == 0 else 24.0))
			_fill(ci, star, col)
			_flat(ci, _rect(-5, -20, 5, 6), WHITE)
			_circle(ci, Vector2(0, 16), 5, WHITE)
		"pie":
			var pts := PackedVector2Array()
			for k in 13:
				var a := PI * k / 12.0
				pts.append(Vector2(-cos(a) * 42, 14 - sin(a) * 34))
			_fill(ci, pts, col, Vector2(0, 0))
			_flat(ci, _rect(-46, 12, 46, 24), col.darkened(0.25))
			for k in 3:
				ci.draw_line(Vector2(-20 + k * 20, -10), Vector2(-14 + k * 20, 4), INK, 4.0, true)
			ci.draw_circle(Vector2(8, -26), 5, INK)
		"pebble":
			_fill(ci, FmmArt.blobp(Vector2(0, 4), 40, 30, 10, 3, 0.12), col)
			ci.draw_circle(Vector2(-12, -6), 5, Color(1, 1, 1, 0.5))
		"bottle":
			_fill(ci, FmmArt.oval(Vector2(0, 14), 32, 30, 16), col, Vector2(0, 14))
			_flat(ci, _rect(-10, -36, 10, -14), col.lightened(0.2))
			_flat(ci, _rect(-13, -46, 13, -36), Color("a07a50"))
			for p in [Vector2(-10, 10), Vector2(8, 20), Vector2(4, 2)]:
				_circle(ci, p, 4, col.lightened(0.4))
		"stick":
			ci.draw_line(Vector2(-34, 40), Vector2(30, -38), INK, 16.0, true)
			ci.draw_line(Vector2(-34, 40), Vector2(30, -38), col, 9.0, true)
			_fill(ci, FmmArt.oval(Vector2(-28, 30), 22, 10, 12), Color("6a9a4a"), Vector2(-28, 30))
		"jar":
			_fill(ci, _rect(-30, -22, 30, 40), col)
			_flat(ci, _rect(-34, -36, 34, -22), Color("a07a50"))
			_flat(ci, _rect(-18, 0, 18, 22), WHITE)
			ci.draw_circle(Vector2(0, 11), 5, col.darkened(0.3))
		"feather":
			var f := PackedVector2Array([Vector2(-30, 40), Vector2(-26, 0), Vector2(0, -36), Vector2(30, -44), Vector2(22, -12), Vector2(-6, 24)])
			_fill(ci, f, col)
			ci.draw_line(Vector2(-34, 46), Vector2(24, -38), INK, 4.0, true)
		"net":
			for k in 4:
				var o := -18.0 + k * 12.0
				ci.draw_line(Vector2(o, -24), Vector2(o + 6, 26), Color("c8c0a0"), 5.0, true)
				ci.draw_line(Vector2(-26, o + 2), Vector2(26, o - 2), Color("c8c0a0"), 5.0, true)
			ci.draw_arc(Vector2.ZERO, 30, 0, TAU, 24, INK, 5.0, true)
		"sack":
			var bag := PackedVector2Array([Vector2(-14, -30), Vector2(14, -30), Vector2(10, -22), Vector2(38, 4), Vector2(40, 30),
				Vector2(24, 42), Vector2(-24, 42), Vector2(-40, 30), Vector2(-38, 4), Vector2(-10, -22)])
			_fill(ci, bag, col)
			ci.draw_line(Vector2(-14, -22), Vector2(14, -22), Color("e0b040"), 6.0, true)
			_flat(ci, _tri(Vector2(-12, -30), Vector2(-22, -44), Vector2(0, -34)), col)
			_flat(ci, _tri(Vector2(12, -30), Vector2(22, -44), Vector2(0, -34)), col)
			var f := UI.display_font()
			ci.draw_string(f, Vector2(-12, 30), "?", HORIZONTAL_ALIGNMENT_CENTER, 24, 40, FmmArt.C_GOLD)
		_:
			_fill(ci, FmmArt.oval(Vector2.ZERO, 40, 31, 18), col)
	_end(ci)


## A shiny monster's glow: a soft halo and a few twinkles in the shine's colour.
static func draw_shine(ci: CanvasItem, e: String, c: Vector2, r: float, t: float) -> void:
	var col := Color(str(Jokers.EDITIONS[e]["color"]))
	for k in 4:
		ci.draw_circle(c, r * (1.25 - k * 0.1), Color(col, 0.08 + 0.05 * k))
	for k in 5:
		var a := TAU * k / 5.0 + t * 0.8
		var hue := fmod(k / 5.0 + t * 0.2, 1.0)
		var tw := col if e != "rainbow" else Color.from_hsv(hue, 0.6, 1.0)
		var p := c + Vector2(cos(a), sin(a)) * r * 1.12
		var s := r * (0.1 + 0.05 * sin(t * 4.0 + k))
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 2), p + Vector2(s * 0.5, 0), p + Vector2(0, s * 2), p + Vector2(-s * 0.5, 0)]), tw)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 2, 0), p + Vector2(0, s * 0.5), p + Vector2(s * 2, 0), p + Vector2(0, -s * 0.5)]), tw)


## A carved stone totem with its sign: 1, 2, 3 stacked bars, a rainbow, a hero, a chain.
static func draw_totem(ci: CanvasItem, id: String, c: Vector2, r: float, col: Color) -> void:
	_begin(ci, c, r)
	var stone := Color("8a8274")
	_fill(ci, PackedVector2Array([Vector2(-26, -44), Vector2(26, -44), Vector2(30, 38), Vector2(-30, 38)]), stone)
	_flat(ci, _rect(-38, 34, 38, 46), stone.darkened(0.3))
	_flat(ci, FmmArt.oval(Vector2(0, -6), 20, 26, 14), col)
	match id:
		"t_one", "t_two", "t_many":
			var n: int = {"t_one": 1, "t_two": 2, "t_many": 3}[id]
			for k in n:
				var y: float = -6.0 + (k - (n - 1) / 2.0) * 12.0
				ci.draw_line(Vector2(-10, y), Vector2(10, y), INK, 6.0)
		"t_colour":
			for k in 3:
				ci.draw_arc(Vector2(0, 6), 14.0 - k * 5.0, PI, TAU, 10, [Color("d05848"), Color("e0a040"), Color("6aa0c0")][k], 4.0)
		"t_squash":
			ci.draw_circle(Vector2(0, -14), 6, INK)
			ci.draw_line(Vector2(0, -8), Vector2(0, 8), INK, 5.0)
			ci.draw_line(Vector2(-10, 12), Vector2(10, 12), INK, 5.0)
		"t_combo":
			ci.draw_polyline(PackedVector2Array([Vector2(-10, -20), Vector2(4, -6), Vector2(-6, -2), Vector2(10, 14)]), INK, 5.0)
	# Carved eyes on the totem's head.
	for sx in [-1.0, 1.0]:
		ci.draw_line(Vector2(sx * 6 - 6, -36), Vector2(sx * 6 + 6, -36), INK, 4.0)
	_end(ci)


## Charms: an amulet on a string, each with its own sign.
## Legendaries: a slow golden glow with rays behind the monster.
static func draw_aura(ci: CanvasItem, c: Vector2, r: float, t: float) -> void:
	for k in 8:
		var a := TAU * k / 8.0 + t * 0.4
		var d := Vector2(cos(a), sin(a))
		var side := Vector2(-d.y, d.x) * r * 0.12
		ci.draw_colored_polygon(PackedVector2Array([c + side, c + d * r * 1.25, c - side]), Color(1.0, 0.85, 0.35, 0.22))
	ci.draw_circle(c, r * (0.95 + 0.05 * sin(t * 3.0)), Color(1.0, 0.85, 0.35, 0.18))


static func draw_charm(ci: CanvasItem, id: String, c: Vector2, r: float, t: float, col: Color) -> void:
	_begin(ci, c, r)
	var sway := sin(t * 1.6) * 0.08
	ci.draw_set_transform(c, sway, Vector2(r / 50.0, r / 50.0))
	ci.draw_polyline(PackedVector2Array([Vector2(-26, -48), Vector2(0, -24), Vector2(26, -48)]), INK, 4.0, true)
	var gem := PackedVector2Array()
	for k in 6:
		var a := TAU * k / 6.0 + PI / 6.0
		gem.append(Vector2(cos(a), sin(a)) * 34 + Vector2(0, 8))
	_fill(ci, gem, C_TRIM, Vector2(0, 8))
	_circle(ci, Vector2(0, 8), 22, col)
	var s := Vector2(0, 8)
	match id:
		"den":
			_flat(ci, PackedVector2Array([s + Vector2(-14, 10), s + Vector2(-14, -2), s + Vector2(0, -14), s + Vector2(14, -2), s + Vector2(14, 10)]), Color("6a4a34"))
		"den2", "den3":
			var n := 2 if id == "den2" else 3
			for k in n:
				var o := s + Vector2((k - (n - 1) / 2.0) * 10.0, 2)
				_flat(ci, PackedVector2Array([o + Vector2(-7, 8), o + Vector2(-7, -1), o + Vector2(0, -9), o + Vector2(7, -1), o + Vector2(7, 8)]), Color("6a4a34"))
		"pocket":
			_flat(ci, PackedVector2Array([s + Vector2(-12, -10), s + Vector2(12, -10), s + Vector2(10, 10), s + Vector2(-10, 10)]), Color("a07a50"))
		"pillow":
			_flat(ci, FmmArt.blobp(s, 15, 10, 10, 5, 0.08), FmmArt.PILLOW)
		"purse":
			_circle(ci, s + Vector2(0, 3), 11, Color("a07a50"))
			ci.draw_circle(s + Vector2(0, -9), 4, FmmArt.C_GOLD)
		"dice":
			_flat(ci, _rect(s.x - 12, s.y - 12, s.x + 12, s.y + 12), WHITE)
			for p in [Vector2(-6, -6), Vector2(0, 0), Vector2(6, 6)]:
				ci.draw_circle(s + p, 2.6, INK)
		"lantern":
			_flat(ci, _rect(s.x - 9, s.y - 10, s.x + 9, s.y + 12), Color("f0d060"))
			ci.draw_line(s + Vector2(-9, -12), s + Vector2(9, -12), INK, 4.0)
		"bell":
			_flat(ci, PackedVector2Array([s + Vector2(-13, 10), s + Vector2(-8, -10), s + Vector2(8, -10), s + Vector2(13, 10)]), Color("c9a25a"))
			ci.draw_circle(s + Vector2(0, 13), 4, INK)
	_end(ci)
