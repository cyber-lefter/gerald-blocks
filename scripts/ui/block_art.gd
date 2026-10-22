class_name BlockArt
extends RefCounted
## Gem-block artwork generated at startup: one shaded shape tinted per color, plus a gloss layer.
## Special overlays (bomb, gem, stone, ice) are drawn with primitives on top.

static var base_tex: ImageTexture
static var gloss_tex: ImageTexture
static var glow_tex: ImageTexture


static func ensure() -> void:
	if base_tex != null:
		return
	# Soft radial light, used additively for sparks, glows and the backdrop.
	var gs := 64
	var glow := Image.create(gs, gs, false, Image.FORMAT_RGBA8)
	for y in gs:
		for x in gs:
			var d := Vector2(x + 0.5 - gs / 2.0, y + 0.5 - gs / 2.0).length() / (gs / 2.0)
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.2)
			glow.set_pixel(x, y, Color(1, 1, 1, a))
	glow_tex = ImageTexture.create_from_image(glow)
	var s := 96
	var base := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var gloss := Image.create(s, s, false, Image.FORMAT_RGBA8)
	# Five More Minutes look: an ink outline around three flat cel tones (shadow, band, light),
	# each tone a smaller copy of the block nudged up and left, plus one hard white highlight.
	var inset := s * 0.04
	var w := s - 2.0 * inset
	var r := s * 0.2
	var ink_w := s * 0.075
	for y in s:
		for x in s:
			var px := x + 0.5
			var py := y + 0.5
			var d_out := _rr(px, py, inset, inset, w, w, r)
			var outer := clampf(0.5 - d_out, 0.0, 1.0)
			if outer <= 0.0:
				base.set_pixel(x, y, Color(0, 0, 0, 0))
				gloss.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var fill := clampf(0.5 - (d_out + ink_w), 0.0, 1.0)
			var v := lerpf(0.06, 0.52, fill)
			var bw := w - ink_w * 2.0
			var b0 := inset + ink_w
			var band := clampf(0.5 - _rr(px, py, b0 - s * 0.02, b0 - s * 0.025, bw * 0.95, bw * 0.92, r * 0.8), 0.0, 1.0)
			v = lerpf(v, 0.78, band * fill)
			var lit := clampf(0.5 - _rr(px, py, b0 - s * 0.035, b0 - s * 0.045, bw * 0.86, bw * 0.8, r * 0.7), 0.0, 1.0)
			v = lerpf(v, 1.0, lit * fill)
			base.set_pixel(x, y, Color(v, v, v, outer))
			var hx := (px - (b0 + bw * 0.24)) / (s * 0.11)
			var hy := (py - (b0 + bw * 0.2)) / (s * 0.06)
			var ga := clampf((1.0 - (hx * hx + hy * hy)) * 6.0, 0.0, 1.0) * 0.85
			gloss.set_pixel(x, y, Color(1, 1, 1, ga))
	base_tex = ImageTexture.create_from_image(base)
	gloss_tex = ImageTexture.create_from_image(gloss)


## Signed distance from a point to a rounded rectangle.
static func _rr(px: float, py: float, x: float, y: float, w: float, h: float, r: float) -> float:
	var qx := absf(px - (x + w * 0.5)) - (w * 0.5 - r)
	var qy := absf(py - (y + h * 0.5)) - (h * 0.5 - r)
	return Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - r


static func draw_block(ci: CanvasItem, col: Color, center: Vector2, size: float, scale := 1.0, alpha := 1.0) -> void:
	ensure()
	var s := size * scale
	var rect := Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s))
	var tint := col.lightened(0.15)
	tint.a = alpha
	ci.draw_texture_rect(base_tex, rect, false, tint)
	ci.draw_texture_rect(gloss_tex, rect, false, Color(1, 1, 1, alpha))


## Soft drop shadow under a block, so pieces sit on the board instead of floating.
static func draw_shadow(ci: CanvasItem, center: Vector2, size: float, alpha := 0.35) -> void:
	ensure()
	var rect := Rect2(center - Vector2(size, size) * 0.5 + Vector2(0, size * 0.08), Vector2(size, size))
	ci.draw_texture_rect(base_tex, rect, false, Color(0, 0, 0, alpha))


static func draw_glow(ci: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	ensure()
	ci.draw_texture_rect(glow_tex, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)


## Four-point twinkle.
static func draw_sparkle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if r < 1.0 or col.a <= 0.01:
		return
	draw_glow(ci, c, r * 1.4, Color(col, col.a * 0.6))
	var w := r * 0.16
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(w, 0), c + Vector2(0, r), c + Vector2(-w, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(0, -w), c + Vector2(r, 0), c + Vector2(0, w)]), col)


static func draw_bomb(ci: CanvasItem, c: Vector2, s: float, t: float, alpha := 1.0) -> void:
	var body := c + Vector2(0, s * 0.04)
	ci.draw_circle(body, s * 0.24, Color(0.12, 0.09, 0.2, alpha))
	ci.draw_circle(body + Vector2(-s * 0.08, -s * 0.08), s * 0.06, Color(1, 1, 1, 0.45 * alpha))
	ci.draw_line(body + Vector2(s * 0.12, -s * 0.18), body + Vector2(s * 0.22, -s * 0.3), Color(0.95, 0.85, 0.6, alpha), maxf(2.0, s * 0.05))
	var flick := 0.75 + 0.25 * sin(t * 18.0)
	var tip := body + Vector2(s * 0.24, -s * 0.32)
	ci.draw_circle(tip, s * 0.08 * flick, Color(1, 0.7, 0.2, alpha))
	ci.draw_circle(tip, s * 0.04 * flick, Color(1, 1, 0.8, alpha))


static func draw_gem(ci: CanvasItem, c: Vector2, s: float, t: float, alpha := 1.0) -> void:
	var o := c + Vector2(0, sin(t * 3.0) * s * 0.03)
	var pts := PackedVector2Array([
		o + Vector2(0, -0.27) * s, o + Vector2(0.24, -0.07) * s,
		o + Vector2(0, 0.28) * s, o + Vector2(-0.24, -0.07) * s,
	])
	ci.draw_colored_polygon(pts, Color(0.45, 0.92, 1.0, alpha))
	var top := PackedVector2Array([pts[0], pts[1], o + Vector2(0, -0.02) * s, pts[3]])
	ci.draw_colored_polygon(top, Color(0.85, 1.0, 1.0, alpha))
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, Color(0.05, 0.2, 0.35, alpha), maxf(1.5, s * 0.035))
	var tw := 0.5 + 0.5 * sin(t * 5.0)
	ci.draw_circle(o + Vector2(-0.08, -0.12) * s, s * 0.035 * tw, Color(1, 1, 1, alpha))


static func draw_stone(ci: CanvasItem, c: Vector2, s: float) -> void:
	var dark := Color(0.18, 0.16, 0.28, 0.55)
	ci.draw_circle(c + Vector2(-0.18, -0.08) * s, s * 0.07, dark)
	ci.draw_circle(c + Vector2(0.15, 0.12) * s, s * 0.09, dark)
	ci.draw_circle(c + Vector2(0.2, -0.2) * s, s * 0.04, dark)
	ci.draw_line(c + Vector2(-0.25, 0.22) * s, c + Vector2(-0.05, 0.06) * s, dark, maxf(1.5, s * 0.03))


static func draw_ice(ci: CanvasItem, c: Vector2, s: float, coats: int) -> void:
	ensure()
	var rect := Rect2(c - Vector2(s, s) * 0.48, Vector2(s, s) * 0.96)
	ci.draw_texture_rect(base_tex, rect, false, Color(0.82, 0.96, 1.0, 0.62 if coats >= 2 else 0.45))
	ci.draw_texture_rect(gloss_tex, rect, false, Color.WHITE)
	var lw := maxf(1.5, s * 0.03)
	if coats == 1:
		var lc := Color(1, 1, 1, 0.85)
		ci.draw_polyline(PackedVector2Array([
			c + Vector2(-0.3, -0.25) * s, c + Vector2(-0.05, -0.02) * s,
			c + Vector2(-0.12, 0.2) * s, c + Vector2(0.1, 0.32) * s]), lc, lw)
		ci.draw_line(c + Vector2(-0.05, -0.02) * s, c + Vector2(0.28, -0.12) * s, lc, lw)
	else:
		ci.draw_line(c + Vector2(-0.3, 0.3) * s, c + Vector2(0.3, -0.3) * s, Color(1, 1, 1, 0.4), lw * 2.0)
