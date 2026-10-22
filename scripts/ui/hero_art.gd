class_name HeroArt
extends RefCounted
## The strip under the board: the Bog Toad asleep in his nest, his naps, and what he mutters.
## Characters come from FmmArt (Five More Minutes' look).

const OUT := FmmArt.INK
const CREAM := FmmArt.C_TEXT
## Hero types (rules) to the FMM kinds that play them. Plain one-hit heroes come in two looks; the fast one is a dog.
const KINDS := {"squire": [FmmArt.ARCHER, FmmArt.BARD], "elf": [FmmArt.DOG], "knight": [FmmArt.TANK],
	"paladin": [FmmArt.PALADIN], "bomber": [FmmArt.BOMBER], "healer": [FmmArt.HEALER], "thief": [FmmArt.ROGUE], "mage": [FmmArt.MAGE],
	"boss_thief": [FmmArt.ROGUE], "boss_wizard": [FmmArt.MAGE], "boss_champion": [FmmArt.PALADIN]}


static func kind_for(type: String) -> int:
	return KINDS.get(type, KINDS["squire"]).pick_random()


## Drawn behind the board, so the toad's head tucks under its bottom edge.
static func draw_bed(ci: CanvasItem, r: Rect2, cell: float, t: float, mood: String, naps: int, font: Font, max_naps := 3,
		skin := FmmArt.TOAD, hat := "") -> void:
	var lw := maxf(2.0, cell * 0.05)
	var floor_sb := StyleBoxFlat.new()
	floor_sb.bg_color = Color("2a241c")
	floor_sb.set_corner_radius_all(int(cell * 0.3))
	floor_sb.border_color = OUT
	floor_sb.set_border_width_all(int(lw))
	ci.draw_style_box(floor_sb, r)
	var h := r.size.y
	FmmArt.draw_nest(ci, r.position + Vector2(cell * 2.0, h * 0.62), cell * 1.9, h * 0.36)
	var s := h * 1.15 / 165.0
	var wob := 1.0 if mood == "angry" else 0.0
	FmmArt.draw_toad(ci, r.position + Vector2(cell * 2.0, h * 0.42), s, t, mood, Vector2(0.6, -0.4), wob, skin, hat)
	if mood == "nap":
		var zk := fmod(t * 0.6, 1.0)
		ci.draw_string(font, r.position + Vector2(cell * (3.1 + zk * 0.4), h * (0.3 - zk * 0.5)), "z", HORIZONTAL_ALIGNMENT_LEFT, -1,
			int(cell * (0.3 + 0.18 * zk)), Color(CREAM, 0.85 * (1.0 - zk)))
	# Naps left this run: a row of little pillows on the right.
	for i in max_naps:
		var p := r.end - Vector2(cell * (0.55 + 0.75 * i), h * 0.5)
		var pts := FmmArt.blobp(p, cell * 0.3, cell * 0.2, 10, 3 + i, 0.08)
		if i < naps:
			FmmArt.cel(ci, pts, p, FmmArt.PILLOW, Color("b89ab0"), Color("5a4a5a"), lw * 0.8, cell * 0.06)
			ci.draw_string(font, p + Vector2(-cell * 0.08, cell * 0.1), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.28), OUT)
		else:
			ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.3))
			FmmArt.ink(ci, pts, lw * 0.6, Color(OUT, 0.6))


## What the toad mutters, in a bubble over the strip (drawn on top of everything).
static func draw_bubble(ci: CanvasItem, r: Rect2, cell: float, say: String, a: float, font: Font) -> void:
	if say == "" or a <= 0.0:
		return
	var lw := maxf(2.0, cell * 0.05)
	var h := r.size.y
	var fs := int(cell * 0.32)
	var tw := font.get_string_size(say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bw := minf(r.size.x - cell * 3.4, tw + cell * 0.5)
	var bubble := Rect2(r.position + Vector2(cell * 3.3, h * 0.08), Vector2(bw, h * 0.5))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(CREAM, a)
	sb.set_corner_radius_all(int(cell * 0.2))
	sb.border_color = Color(OUT, a)
	sb.set_border_width_all(int(lw * 0.8))
	ci.draw_colored_polygon(PackedVector2Array([bubble.position + Vector2(2, bubble.size.y * 0.3), bubble.position + Vector2(2, bubble.size.y * 0.75),
		bubble.position + Vector2(-cell * 0.45, bubble.size.y * 0.85)]), Color(CREAM, a))
	ci.draw_style_box(sb, bubble)
	ci.draw_string(font, bubble.position + Vector2(cell * 0.25, bubble.size.y * 0.5 + fs * 0.35), say, HORIZONTAL_ALIGNMENT_LEFT,
		bw - cell * 0.4, fs, Color(OUT, a))
