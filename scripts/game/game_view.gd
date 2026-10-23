class_name GameView
extends Node2D
## The board, the tray, drag-and-drop and every gameplay effect.
## Solid things are drawn in _draw; light (sparks, beams, glows) is drawn additively by FxLayer in _draw_fx.

signal score_changed(score: int, streak: int)
signal goal_changed(current: int, target: int)
signal finished(won: bool)
signal tool_used(tool_name: String)
signal tool_cancelled
signal orb_arrived(target: String)

const N := 8
const STONE := 9
const KIND_NORMAL := 0
const KIND_BOMB := 1
const KIND_GEM := 2
const GREY := Color(0.357, 0.341, 0.525)
const STONE_COLOR := Color(0.467, 0.447, 0.604)
const GOLD := Color(1.0, 0.84, 0.3)
const PRAISE := ["", "", "Great!", "Excellent!", "Amazing!", "Unbelievable!"]
const FEVER_STREAK := 5
# Particle look per theme.
const SPARK_STYLE := {"midnight": "star", "sunset": "petal", "ocean": "bubble", "candy": "heart", "neon": "glow"}

## Shared with the backdrop so the whole screen joins in during fever.
static var fever_amount := 0.0

var mode := "classic"
var level: Dictionary = {}
var palette: Array = []
## Paint Goblin's lucky colour this round (palette index), or -1.
var lucky_color := -1
var theme: Dictionary = {}
var spark_style := "star"
var reduced := false
var input_enabled := true

# Board state. color: 0 empty, 1..8 palette index + 1, STONE. ice: extra clears needed.
var color := PackedInt32Array()
var kind := PackedInt32Array()
var ice := PackedInt32Array()
var pop := PackedFloat32Array()

var tray: Array = [null, null, null]
var tray_t := 0.0
var tray_pop: Array = [-9.0, -9.0, -9.0]
var tray_return: Array = [null, null, null]
var dealer := Dealer.new()

var score := 0
var streak := 0
var missed := 0
var placements := 0
var goal_current := 0
var over := false
var lost := false
var over_t := 0.0
var pending_finish: Dictionary = {}
var revived := false
var undo_state: Dictionary = {}
var tool := ""

# Run mode: a score target within a piece budget; raid rounds send heroes down the board.
const HERO_TYPES := {"squire": {"hp": 1, "steps": 1}, "elf": {"hp": 1, "steps": 2}, "knight": {"hp": 2, "steps": 1}, "paladin": {"hp": 3, "steps": 1},
	"bomber": {"hp": 1, "steps": 1}, "healer": {"hp": 1, "steps": 1}, "thief": {"hp": 1, "steps": 1}, "mage": {"hp": 1, "steps": 1},
	# Bosses: big armour, walk every third piece, and each has a trick (see _hero_tricks).
	"boss_thief": {"hp": 2, "steps": 1, "name": "The Master Thief", "trick": "Steals a piece every 3 moves"},
	"boss_wizard": {"hp": 3, "steps": 1, "name": "The Grand Wizard", "trick": "Freezes two blocks every 2 moves"},
	"boss_champion": {"hp": 4, "steps": 1, "name": "The Champion", "trick": "Patches his armour every 3 moves"}}
const G_BOSS := ["A champion. In MY room.", "That one's big. Squash him.", "Oh no. Not him again."]
const G_BOSS_DOWN := ["Ha! Flat champion.", "Who's the hero now?", "Now THAT was satisfying."]
# Which heroes turn up, by night: [type, first night, weight].
const HERO_TABLE := [["squire", 1, 60], ["elf", 1, 25], ["knight", 2, 25], ["mage", 2, 12], ["thief", 2, 12],
	["healer", 3, 12], ["bomber", 3, 12], ["paladin", 4, 14]]
const YELPS := ["MY HAT!", "Not the face!", "Tell my mum!", "I had a prophecy!", "AAAAA", "Worth it!", "Oof.", "Unfair!", "My sword!"]
const PEEL := ["My armour!", "That was rented!", "Just a flesh wound."]
const G_START := ["Mm. Five more minutes.", "Don't wake me. Score points.", "Quiet blocks only, please.", "I'm resting my eyes."]
const G_RAID := ["Heroes. In my room. At this hour.", "Squash them before they reach the bed.", "Ugh. Adventurers again."]
const G_WAKE := ["Oi. I was sleeping.", "Who let him in?", "That's one nap ruined.", "Out. OUT."]
const G_BONK := ["Lovely.", "Flat as a crumpet.", "Goodnight, hero.", "Mm. Satisfying."]
const G_WIN := ["Bliss.", "Good. Now hush.", "*contented snore*"]
var round_n := 0
var target := 0
var pieces_left := 0
var raid := false
var heroes: Array = []
var flyers: Array = []
var spawn_in := 2
var next_hero_id := 1
var squashed := 0
var end_reason := ""
var angry_t := -9.0
var say_text := ""
var say_t := -9.0
var bed_rect := Rect2()
var clears := 0
## Honey Jar snack: the next clear scores x3.
var honey := false
var advanced_at := 0
## Boss raids: the round only ends once the boss is squashed too.
var boss_round := false
var boss_beaten := false
## Squash mode keeps its own naps (a saved run's naps stay untouched).
var squash_naps := 3
## Joker names that fired this move, shown as little pops over the board.
var joker_pops: Array = []

# Layout
var area := Rect2()
var cell := 60.0
var board_rect := Rect2()
var inner := Vector2.ZERO
var tray_y := 0.0
var tray_h := 0.0
var tray_size := 30.0
## Global positions of the HUD counters that score and gem orbs fly into (set by GameScreen).
var score_target := Vector2.ZERO
var goal_target := Vector2.ZERO

# Effects
var dying: Array = []
var particles: Array = []
var texts: Array = []
var beams: Array = []
var rings: Array = []
var glints: Array = []
var orbs: Array = []
var crumble: Array = []
var trail: Array = []
var near_lines: Array = []
var shake := 0.0
var flash := 0.0
var time := 0.0
var slowmo := 0.0
var pulse := 0.0
var fever := 0.0
var in_fever := false
var next_glint := 1.5
var sweep_t := -9.0
var next_sweep := 3.0
var crumble_at := -1.0
var crumbled := false
var tilt := 0.0
var snap_t := -9.0
var last_tick := -9.0
var fx_layer: FxLayer

var drag: Dictionary = {}
var preview_hl: Dictionary = {}
var preview_color := Color.WHITE
var font: Font
var is_mobile := false
var sb_board := StyleBoxFlat.new()
var sb_slot := StyleBoxFlat.new()
var sb_glow := StyleBoxFlat.new()


func setup(p_mode: String, p_level: Dictionary) -> void:
	mode = p_mode
	level = p_level
	theme = Save.theme()
	palette = theme["blocks"]
	spark_style = SPARK_STYLE.get(theme["id"], "glow")
	reduced = bool(Save.data.get("reduced_fx", false))
	fever_amount = 0.0
	font = UI.display_font()
	is_mobile = OS.has_feature("mobile")
	fx_layer = FxLayer.new()
	fx_layer.view = self
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx_layer.material = mat
	add_child(fx_layer)
	color.resize(N * N)
	color.fill(0)
	kind.resize(N * N)
	kind.fill(0)
	ice.resize(N * N)
	ice.fill(0)
	pop.resize(N * N)
	pop.fill(-9.0)
	if mode == "daily":
		dealer.rng.seed = hash("prism-daily-" + Save.today())
	else:
		dealer.rng.randomize()
	if mode == "adventure":
		dealer.base = level["base"]
		dealer.ramp = 0.2
		for c in level["cells"]:
			var i: int = c["i"]
			color[i] = STONE if c["kind"] == "stone" else int(c["color"]) + 1
			kind[i] = KIND_GEM if c["kind"] == "gem" else KIND_NORMAL
			ice[i] = int(c["ice"])
	if mode == "run":
		round_n = Run.round_n
		target = Run.target(round_n)
		pieces_left = Run.pieces(round_n)
		raid = Run.is_raid(round_n)
		dealer.base = Run.difficulty(round_n)
		dealer.ramp = 0.15
		spawn_in += _hero_delay()
		if _joker("moth"):
			score = int(Run.v("moth"))
		if _joker("paint"):
			lucky_color = randi_range(0, 7)
		if raid:
			_spawn_hero()
			_spawn_hero()
		boss_round = Run.is_boss(round_n)
		if boss_round:
			_spawn_boss(Run.boss_type(round_n))
			say(G_BOSS)
		else:
			say(G_RAID if raid else G_START)
	if mode == "squash":
		raid = true
		pieces_left = 999999
		dealer.base = 0.2
		dealer.ramp = 0.15
		spawn_in = 3
		# A few blocks already down at the bottom, so the first squashes are within reach.
		for y in [N - 2, N - 1]:
			var gaps := [randi_range(0, N - 1), randi_range(0, N - 1)]
			for x in N:
				if not gaps.has(x):
					color[y * N + x] = randi_range(1, 8)
		_spawn_hero()
		say(G_RAID)
	_deal()
	_update_near_lines()


func _exit_tree() -> void:
	fever_amount = 0.0


func set_area(r: Rect2) -> void:
	area = r
	var w := r.size.x
	var h := r.size.y
	# Run mode keeps the toad's nest between the board and the tray.
	var bed := 1.55 if lair() else 0.0
	cell = floorf(minf((w - 48.0) / (N + 0.4), (h - 20.0) / (N + 0.4 + 3.5 + bed)))
	cell = maxf(cell, 20.0)
	var pad := cell * 0.2
	var bs := cell * N + pad * 2.0
	var used := bs + cell * 0.3 + cell * 3.1 + cell * bed
	# Spare height (tall phones) goes to the toad's strip, so all of him and his hat fit
	# without the board getting any smaller.
	var bed_extra := 0.0
	if lair():
		bed_extra = clampf((h - 20.0 - used) / cell * 0.9, 0.0, 1.0)
		bed += bed_extra
		used += cell * bed_extra
	var top := r.position.y + maxf(6.0, (h - used) * 0.4)
	board_rect = Rect2(r.position.x + (w - bs) / 2.0, top, bs, bs)
	inner = board_rect.position + Vector2(pad, pad)
	bed_rect = Rect2(board_rect.position.x, board_rect.end.y + cell * 0.15, bs, cell * (1.35 + bed_extra))
	tray_y = board_rect.end.y + cell * 0.3 + cell * bed
	tray_h = cell * 3.1
	tray_size = minf(cell * 0.56, (w / 3.0 * 0.86) / 5.0)
	sb_board.bg_color = theme["board"]
	sb_board.set_corner_radius_all(int(cell * 0.35))
	sb_board.border_color = FmmArt.INK
	sb_board.set_border_width_all(5)
	sb_board.shadow_color = Color(0, 0, 0, 0.35)
	sb_board.shadow_size = 18
	sb_slot.bg_color = theme["slot"]
	sb_slot.set_corner_radius_all(int(cell * 0.16))
	sb_glow.set_corner_radius_all(int(cell * 0.18))


# ---------------------------------------------------------------- helpers

func occupancy() -> PackedByteArray:
	var o := PackedByteArray()
	o.resize(N * N)
	for i in N * N:
		o[i] = 1 if color[i] != 0 else 0
	for h in heroes:
		o[int(h["y"]) * N + int(h["x"])] = 1
	return o


func sticky() -> PackedByteArray:
	var o := PackedByteArray()
	o.resize(N * N)
	for i in N * N:
		o[i] = 1 if color[i] == STONE or ice[i] > 0 else 0
	for h in heroes:
		if int(h["hp"]) > 1:
			o[int(h["y"]) * N + int(h["x"])] = 1
	return o


func hero_at(x: int, y: int) -> Dictionary:
	for h in heroes:
		if int(h["x"]) == x and int(h["y"]) == y:
			return h
	return {}


func _color_of(i: int) -> Color:
	var v := color[i]
	if v == STONE:
		return STONE_COLOR
	return palette[v - 1]


func _cell_center(x: float, y: float) -> Vector2:
	return inner + Vector2(x + 0.5, y + 0.5) * cell


func _slot_center(i: int) -> Vector2:
	return Vector2(area.position.x + area.size.x * (i + 0.5) / 3.0, tray_y + tray_h / 2.0)


func _cell_at(p: Vector2) -> Vector2i:
	var g := ((p - inner) / cell).floor()
	if g.x < 0 or g.y < 0 or g.x >= N or g.y >= N:
		return Vector2i(-1, -1)
	return Vector2i(g)


func _goal_type() -> String:
	return str(level.get("type", "")) if mode == "adventure" else ""


## Score the HUD should show: points still flying as orbs aren't counted yet.
func shown_score() -> int:
	var pending := 0
	for o in orbs:
		pending += int(o["value"])
	return score - pending


## Rows and columns missing exactly one block get a soft hint glow.
func _update_near_lines() -> void:
	near_lines = []
	var occ := occupancy()
	for line in 2 * N:
		var gap := -1
		var empty := 0
		for j in N:
			var i := line * N + j if line < N else j * N + (line - N)
			if occ[i] == 0:
				empty += 1
				gap = i
		if empty == 1:
			near_lines.append({"row": line < N, "i": line % N, "gap": gap})


static func _ease_out_back(k: float) -> float:
	var c := 1.9
	return 1.0 + (c + 1.0) * pow(k - 1.0, 3) + c * pow(k - 1.0, 2)


static func _ease_out_cubic(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3)


## Light vibration ticks are rate-limited so fast effects don't turn into a buzz.
func _tick(ms: int, amplitude: float) -> void:
	if time - last_tick > 0.05:
		last_tick = time
		Sfx.vibrate(ms, false, amplitude)


# ---------------------------------------------------------------- dealing

func _deal() -> void:
	dealer.trays += 1
	# In a run the score restarts every round, so difficulty follows pieces played instead.
	var shapes := dealer.deal(occupancy(), sticky(), placements * 60 if mode == "run" else score)
	var order := [0, 1, 2, 3, 4, 5, 6, 7]
	for i in range(7, 0, -1):
		var j := dealer.rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	var bombs: bool = level.get("bombs", false) if mode == "adventure" else (score >= 400 and mode != "run")
	for i in 3:
		if mode == "run" and i >= pieces_left:
			# The last tray of a round only holds the pieces still left in the budget.
			tray[i] = null
			continue
		var s: Dictionary = shapes[i]
		var b := -1
		var n: int = s["cells"].size()
		if bombs and n >= 2 and dealer.rng.randf() < 0.1:
			b = dealer.rng.randi_range(0, n - 1)
		tray[i] = {"shape": s, "color": order[i], "bomb": b}
	if _joker("chameleon"):
		var top := _top_color()
		if top >= 0:
			for i in mini(int(Run.v("chameleon")), 3):
				if tray[i] != null:
					tray[i]["color"] = top
	tray_t = time
	tray_return = [null, null, null]


## The palette index most blocks on the board have (-1 on an empty board).
func _top_color() -> int:
	var counts := {}
	for v in color:
		if v > 0 and v != STONE:
			counts[v - 1] = int(counts.get(v - 1, 0)) + 1
	var best := -1
	for c in counts:
		if best < 0 or int(counts[c]) > int(counts[best]):
			best = c
	return best


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if not input_enabled or over or Ads.busy or not is_visible_in_tree():
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		var local_b := make_input_local(mb) as InputEventMouseButton
		if mb.pressed:
			_press(local_b.position)
		else:
			_release()
		return
	var mm := event as InputEventMouseMotion
	if mm and not drag.is_empty():
		var local_m := make_input_local(mm) as InputEventMouseMotion
		drag["target"] = local_m.position - Vector2(0, float(drag["lift"]))
		_update_ghost()


func _press(p: Vector2) -> void:
	if tool == "tongue":
		var c := _cell_at(p)
		if c.x >= 0 and not hero_at(c.x, c.y).is_empty():
			_eat_hero(c)
		return
	if tool == "pebble":
		var c := _cell_at(p)
		if c.x >= 0 and color[c.y * N + c.x] != 0:
			_hammer(c)
		return
	if tool == "hammer":
		var c := _cell_at(p)
		if c.x >= 0:
			_hammer(c)
		return
	# The tray zone stops at the bottom of this view, so taps on the power-up bar never grab a piece.
	if p.y < tray_y - cell * 0.4 or p.y > minf(tray_y + tray_h + cell * 0.6, area.end.y):
		return
	var slot := clampi(int((p.x - area.position.x) / (area.size.x / 3.0)), 0, 2)
	if tray[slot] == null:
		return
	if tool == "rotate":
		_rotate(slot)
		return
	var sh: Dictionary = tray[slot]["shape"]
	var lift := 0.0
	if is_mobile:
		lift = float(sh["h"]) * cell / 2.0 + cell * 1.1
	drag = {"slot": slot, "pos": _slot_center(slot), "target": p - Vector2(0, lift),
		"lift": lift, "scale": tray_size / cell, "ghost": null, "cell": Vector2i(-99, -99)}
	trail = []
	tilt = 0.0
	_update_ghost()
	Sfx.play("pick", randf_range(0.96, 1.04))
	Sfx.vibrate(10, false, 0.4)


func _update_ghost() -> void:
	var p: Dictionary = tray[drag["slot"]]
	var sh: Dictionary = p["shape"]
	var t: Vector2 = drag["target"]
	var tl := t - Vector2(sh["w"], sh["h"]) * cell / 2.0
	var g := Vector2i(roundi((tl.x - inner.x) / cell), roundi((tl.y - inner.y) / cell))
	# A faint tick every time the piece crosses into a new cell, valid or not.
	if g != drag["cell"]:
		drag["cell"] = g
		if board_rect.grow(cell).has_point(t):
			_tick(5, 0.15)
	var occ := occupancy()
	var valid := BoardLogic.fits(occ, sh, g.x, g.y)
	var old = drag["ghost"]
	if valid and old != null and old == g:
		return
	if not valid and old == null:
		return
	preview_hl = {}
	if not valid:
		drag["ghost"] = null
		return
	drag["ghost"] = g
	snap_t = time
	_tick(9, 0.35)
	for c in sh["cells"]:
		occ[(g.y + c.y) * N + g.x + c.x] = 1
	var f := BoardLogic.full_lines(occ)
	for y in f["rows"]:
		for x in N:
			preview_hl[y * N + x] = true
	for x in f["cols"]:
		for y in N:
			preview_hl[y * N + x] = true
	preview_color = palette[p["color"]]
	if not preview_hl.is_empty():
		# A slightly stronger buzz says "this move clears something".
		Sfx.vibrate(14, false, 0.5)


func _release() -> void:
	if drag.is_empty():
		return
	var d := drag
	drag = {}
	preview_hl = {}
	var slot: int = d["slot"]
	if d["ghost"] != null:
		var g: Vector2i = d["ghost"]
		_place(slot, g.x, g.y)
	else:
		tray_return[slot] = {"pos": d["pos"], "scale": d["scale"], "t0": time}
		Sfx.play("drop")
		Sfx.vibrate(6, false, 0.2)


# ---------------------------------------------------------------- gameplay

func _place(slot: int, gx: int, gy: int) -> void:
	_save_undo()
	var p: Dictionary = tray[slot]
	var sh: Dictionary = p["shape"]
	var cells: Array = sh["cells"]
	var pc: Color = palette[p["color"]]
	for ci in cells.size():
		var c: Vector2i = cells[ci]
		var i := (gy + c.y) * N + gx + c.x
		color[i] = int(p["color"]) + 1
		kind[i] = KIND_BOMB if ci == int(p["bomb"]) else KIND_NORMAL
		pop[i] = time
	tray[slot] = null
	placements += 1
	if mode == "run":
		pieces_left -= 1
	score += cells.size()
	if _joker("tadpole"):
		score += cells.size() * int(Run.v("tadpole"))
	if _joker("ogre") and cells.size() >= 5:
		score += int(Run.v("ogre"))
		_joker_pop("ogre", "+%d" % int(Run.v("ogre")))
	# Small random pitch changes keep repeated placements from sounding mechanical; bigger pieces sound heavier.
	Sfx.play("place", randf_range(0.95, 1.05) * (1.08 - 0.02 * cells.size()))
	Sfx.vibrate(16, false, 0.6)
	for c in cells:
		_spark(_cell_center(gx + c.x, gy + c.y) + Vector2(0, cell * 0.35), pc, 1, 0.35)
	var piece_center := _cell_center(gx + (float(sh["w"]) - 1.0) / 2.0, gy + (float(sh["h"]) - 1.0) / 2.0)
	rings.append({"pos": piece_center, "t0": time, "color": pc, "r": cell * 1.8, "thin": true})
	pulse = maxf(pulse, 0.3)

	var lines := BoardLogic.full_lines(occupancy())
	var rows: Array = lines["rows"]
	var cols: Array = lines["cols"]
	var line_count := rows.size() + cols.size()
	if line_count > 0:
		streak += 1
		missed = 0
		var origin := Vector2(gx + (float(sh["w"]) - 1.0) / 2.0, gy + (float(sh["h"]) - 1.0) / 2.0)
		var mono := 0
		var hit := {}
		for y in rows:
			if _line_mono(true, y):
				mono += 1
			for x in N:
				hit[y * N + x] = true
			beams.append({"row": true, "i": y, "t0": time, "color": pc})
		for x in cols:
			if _line_mono(false, x):
				mono += 1
			for y in N:
				hit[y * N + x] = true
			beams.append({"row": false, "i": x, "t0": time, "color": pc})
		var line_cells := hit.size()
		var ctx := _clear_context(sh, rows, cols, hit)
		var bombs := _expand_bombs(hit)
		var blasted := hit.size() - line_cells
		var orb_from: Array = []
		for key in hit.keys():
			if color[int(key)] != 0:
				orb_from.append(_cell_center(int(key) % N, int(key) / N))
		var res := _destroy(hit, origin)

		var mult := 1.0 + (Run.v("bat") if _joker("bat") else 0.5) * (streak - 1)
		var mono_x := int(Run.v("toadstool")) - 1 if _joker("toadstool") else 1
		var pts := int(line_count * line_count * 20 * mult) * (1 + mono * mono_x)
		pts += blasted * 5 + int(res["gems"]) * 50
		pts = _joker_points(pts, line_count, rows, cols, mono, ctx)
		if honey:
			honey = false
			pts *= 3
			joker_pops.append("Honey Jar x3")
		pts += _hit_heroes(hit, mult)
		clears += 1
		if lair():
			Meta.add("lines", line_count)
		var board_clear := _board_empty()
		if board_clear:
			pts += 500
		score += pts
		_spawn_orbs(orb_from, pts, pc)
		match _goal_type():
			"lines":
				goal_current += line_count
			"gems":
				goal_current += int(res["gems"])
			"ice":
				goal_current += int(res["ice"])

		var started_fever := false
		if streak >= FEVER_STREAK and not in_fever:
			in_fever = true
			started_fever = true

		var word: String = PRAISE[mini(line_count, 5)]
		if board_clear:
			word = "Board clear!"
		elif bombs > 0:
			word = "Boom!"
		var mid := Vector2(area.position.x + area.size.x / 2.0, inner.y + cell * 3.0)
		var big := line_count >= 3 or streak >= 4 or board_clear or bombs > 0 or started_fever
		var oc := _cell_center(origin.x, origin.y)
		rings.append({"pos": oc, "t0": time, "color": pc, "r": cell * (3.0 + line_count * 1.6)})
		pulse = 1.0 if big else 0.7
		sweep_t = time + 0.2
		if big:
			# A beat of slow motion and a second white shockwave sell the big moments.
			if not reduced:
				slowmo = 0.22
			rings.append({"pos": oc, "t0": time + 0.06, "color": Color(1, 1, 1, 0.9), "r": cell * 10.0})
		if board_clear:
			for k in 40:
				_spark(board_rect.get_center() + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * cell * 3.0, palette[k % palette.size()], 1, 2.0)
		if started_fever:
			_text("FEVER!", mid - Vector2(0, cell * 1.3), cell * 1.4, true, 0.0, true)
			rings.append({"pos": board_rect.get_center(), "t0": time + 0.1, "color": GOLD, "r": cell * 12.0})
			Sfx.play_later("win", 0.15)
			Sfx.vibrate(120, true, 1.0)
		if word != "":
			_text(word, mid, cell * (1.3 if big else 1.0), true, 0.0, in_fever)
		_text("+" + UI.fmt(pts), oc, cell * 0.75, false, 0.06)
		if streak >= 2:
			_text("Combo x%d" % streak, mid + Vector2(0, cell * 1.2), cell * 0.7, true, 0.12)
		if mono > 0:
			_text("Same color x%d!" % (1 + mono), mid + Vector2(0, cell * 2.3), cell * 0.6, true, 0.2)
		if not reduced:
			shake = maxf(shake, 11.0 if big else (5.0 if line_count == 2 else 2.0))
			if big:
				flash = 0.3
		Sfx.clear_chord(line_count, streak, in_fever)
		if bombs > 0:
			Sfx.play("bomb")
		Sfx.vibrate(60 if big else 30, true, 1.0 if big else 0.7)
	else:
		if _joker("slime"):
			score += int(Run.v("slime"))
			_joker_pop("slime", "+%d" % int(Run.v("slime")))
		missed += 1
		if missed >= (int(Run.v("ghost")) if _joker("ghost") else 3):
			streak = 0
			if in_fever:
				in_fever = false
				_text("Fever over", Vector2(area.position.x + area.size.x / 2.0, inner.y + cell * 3.0), cell * 0.6, false)
	_update_near_lines()
	_show_joker_pops()
	score_changed.emit(score, streak)
	_after_move()


func _joker(id: String) -> bool:
	return mode == "run" and Run.has(id)


## Monsters, totems and shiny monsters that change what a clear is worth. Points are added
## first, then the multipliers stack. Each monster that fires gets a pop.
func _joker_points(pts: int, line_count: int, rows: Array, cols: Array, mono: int, ctx := {}) -> int:
	if mode != "run":
		return pts
	# Totems: one pop for all of them.
	var tot := 0
	if line_count == 1:
		tot += Run.totem("t_one") * 15
	elif line_count == 2:
		tot += Run.totem("t_two") * 40
	else:
		tot += Run.totem("t_many") * 80
	tot += Run.totem("t_colour") * 30 * mono
	if streak >= 2:
		tot += Run.totem("t_combo") * 20
	if tot > 0:
		pts += tot
		joker_pops.append("Totems +%d" % tot)
	if _joker("blob"):
		var b := int(Run.v("blob")) * line_count
		pts += b
		_joker_pop("blob", "+%d" % b)
	if _joker("worm"):
		var w := int(Run.grown("worm")) * line_count
		Run.add_grow("worm", line_count)
		if w > 0:
			pts += w
			_joker_pop("worm", "+%d" % w)
	if _joker("hoarder") and Run.grown("hoarder") > 0:
		pts += int(Run.grown("hoarder"))
		_joker_pop("hoarder", "+%d" % int(Run.grown("hoarder")))
	if _joker("imp") and int(ctx.get("blocks", 0)) <= 2:
		pts += int(Run.v("imp"))
		_joker_pop("imp", "+%d" % int(Run.v("imp")))
	if _joker("heart") and ctx.get("middle", false):
		pts += int(Run.v("heart"))
		_joker_pop("heart", "+%d" % int(Run.v("heart")))
	if _joker("slug") and int(ctx.get("motley", 0)) > 0:
		var m := int(Run.v("slug")) * int(ctx["motley"])
		pts += m
		_joker_pop("slug", "+%d" % m)
	if _joker("paint") and int(ctx.get("lucky", 0)) > 0:
		var l := int(Run.v("paint")) * int(ctx["lucky"])
		pts += l
		_joker_pop("paint", "+%d" % l)
	if _joker("moss"):
		var empty := 0
		for v in color:
			if v == 0:
				empty += 1
		var e := int(Run.v("moss")) * empty
		if e > 0:
			pts += e
			_joker_pop("moss", "+%d" % e)
	var foil := Run.shiny("foil")
	if foil > 0:
		pts += 30 * foil
		joker_pops.append("Foil +%d" % (30 * foil))
	if _joker("mimic") and line_count >= 2:
		Run.gold += int(Run.v("mimic"))
		_joker_pop("mimic", "+%d gold" % int(Run.v("mimic")))
	var x := 1.0
	if _joker("cyclops") and line_count == 1:
		x *= Run.v("cyclops")
		_joker_pop("cyclops", "x" + Jokers.fmt(Run.v("cyclops")))
	if _joker("octo") and not rows.is_empty() and not cols.is_empty():
		x *= Run.v("octo")
		_joker_pop("octo", "x" + Jokers.fmt(Run.v("octo")))
	if _joker("owl") and raid:
		x *= Run.v("owl")
		_joker_pop("owl", "x" + Jokers.fmt(Run.v("owl")))
	if _joker("grub"):
		for y in rows:
			if int(y) >= N - 2:
				x *= Run.v("grub")
				_joker_pop("grub", "x" + Jokers.fmt(Run.v("grub")))
				break
	if _joker("eel") and ctx.get("straight", false):
		x *= Run.v("eel")
		_joker_pop("eel", "x" + Jokers.fmt(Run.v("eel")))
	if _joker("corner") and ctx.get("ell", false):
		x *= Run.v("corner")
		_joker_pop("corner", "x" + Jokers.fmt(Run.v("corner")))
	if _joker("lurker") and ctx.get("edge", false):
		x *= Run.v("lurker")
		_joker_pop("lurker", "x" + Jokers.fmt(Run.v("lurker")))
	if _joker("clean") and _board_empty():
		x *= Run.v("clean")
		_joker_pop("clean", "x" + Jokers.fmt(Run.v("clean")))
	if _joker("mouth") and line_count >= 3:
		x *= Run.v("mouth")
		_joker_pop("mouth", "x" + Jokers.fmt(Run.v("mouth")))
	if _joker("lucky") and clears == 0:
		x *= Run.v("lucky")
		_joker_pop("lucky", "x" + Jokers.fmt(Run.v("lucky")))
	if _joker("yeti") and Run.grown("yeti") > 0:
		var y := 1.0 + Run.grown("yeti")
		x *= y
		_joker_pop("yeti", "x" + Jokers.fmt(y))
	for k in Run.shiny("rainbow"):
		x *= 1.5
		joker_pops.append("Rainbow x1.5")
	return int(pts * x)


## What the shape-, board- and colour-minded monsters need to know about a clear, read before
## the blocks are gone: the piece that did it, where the lines were, and their colours.
func _clear_context(sh: Dictionary, rows: Array, cols: Array, hit: Dictionary) -> Dictionary:
	var g := int(sh.get("group", -1))
	var ctx := {"blocks": sh["cells"].size(), "straight": g in [2, 3, 4], "ell": g in [6, 7, 8, 13],
		"middle": false, "edge": false, "motley": 0, "lucky": 0}
	for k in rows + cols:
		if k == 0 or k == N - 1:
			ctx["edge"] = true
		if k == N / 2 - 1 or k == N / 2:
			ctx["middle"] = true
	for y in rows:
		if _line_colors(true, y) >= 4:
			ctx["motley"] += 1
	for x in cols:
		if _line_colors(false, x) >= 4:
			ctx["motley"] += 1
	if lucky_color >= 0:
		for i in hit:
			if color[int(i)] == lucky_color + 1:
				ctx["lucky"] += 1
	return ctx


## How many different colours a full row or column holds.
func _line_colors(is_row: bool, k: int) -> int:
	var seen := {}
	for j in N:
		var v := color[k * N + j if is_row else j * N + k]
		if v > 0 and v != STONE:
			seen[v] = true
	return seen.size()


func _joker_pop(id: String, what: String) -> void:
	joker_pops.append("%s %s" % [Jokers.info(id)["name"], what])


func _show_joker_pops() -> void:
	for k in joker_pops.size():
		_text(joker_pops[k], Vector2(area.position.x + area.size.x / 2.0, inner.y + cell * (0.6 + 0.7 * k)), cell * 0.5, true, 0.25 + 0.12 * k)
	joker_pops = []


func _line_mono(is_row: bool, k: int) -> bool:
	var first := -1
	for j in N:
		var i := k * N + j if is_row else j * N + k
		var v := color[i]
		if v == STONE:
			return false
		if first < 0:
			first = v
		elif v != first:
			return false
	return true


## Bombs inside the cleared area blast their 3x3 neighbourhood, and can chain.
func _expand_bombs(hit: Dictionary) -> int:
	var queue: Array = hit.keys()
	var fired := 0
	var qi := 0
	while qi < queue.size():
		var i: int = queue[qi]
		qi += 1
		if color[i] == 0 or kind[i] != KIND_BOMB:
			continue
		kind[i] = KIND_NORMAL
		fired += 1
		var x := i % N
		var y := i / N
		_burst(_cell_center(x, y), Color(1.0, 0.7, 0.2), 22)
		_spark(_cell_center(x, y), Color(1.0, 0.6, 0.2), 12, 1.6)
		rings.append({"pos": _cell_center(x, y), "t0": time, "color": Color(1.0, 0.6, 0.2), "r": cell * 2.6})
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx := x + dx
				var ny := y + dy
				if nx < 0 or ny < 0 or nx >= N or ny >= N:
					continue
				var j := ny * N + nx
				if not hit.has(j):
					hit[j] = true
					queue.append(j)
	return fired


## Applies a clear to every hit cell. Stones survive, ice loses a coat, the rest break.
func _destroy(hit: Dictionary, origin: Vector2) -> Dictionary:
	var gems := 0
	var ice_done := 0
	var ice_hit := false
	for key in hit.keys():
		var i: int = key
		if color[i] == 0 or color[i] == STONE:
			continue
		var x := i % N
		var y := i / N
		var delay := (absf(x - origin.x) + absf(y - origin.y)) * 0.026
		if ice[i] > 0:
			ice[i] -= 1
			ice_hit = true
			if ice[i] == 0:
				ice_done += 1
			_burst(_cell_center(x, y), Color(0.85, 0.97, 1.0), 9)
			continue
		var is_gem := kind[i] == KIND_GEM
		if is_gem:
			gems += 1
			if mode == "adventure":
				orbs.append({"from": _cell_center(x, y), "ctrl": _cell_center(x, y) + Vector2(randf_range(-2, 2), -3) * cell,
					"t0": time + 0.25 + delay, "dur": 0.7, "value": 0, "target": "goal", "color": Color(0.55, 0.95, 1.0)})
		dying.append({"x": x, "y": y, "color": _color_of(i), "t0": time + delay, "spawned": false, "gem": is_gem})
		color[i] = 0
		kind[i] = KIND_NORMAL
	if ice_hit:
		Sfx.play("ice")
	return {"gems": gems, "ice": ice_done}


## Points leave the cleared blocks as glowing orbs and fly into the score.
func _spawn_orbs(from: Array, pts: int, col: Color) -> void:
	if from.is_empty():
		return
	from.shuffle()
	var n := mini(from.size(), 3 if reduced else mini(12, 3 + pts / 60))
	var each := pts / n
	for k in n:
		var start: Vector2 = from[k]
		var v := each if k < n - 1 else pts - each * (n - 1)
		orbs.append({"from": start, "ctrl": start + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, -1.0)) * cell,
			"t0": time + 0.15 + k * 0.035, "dur": randf_range(0.45, 0.65), "value": v, "target": "score",
			"color": col.lerp(GOLD, 0.5) if in_fever else col.lightened(0.3)})


func _orb_pos(o: Dictionary, k: float) -> Vector2:
	var target := to_local(goal_target if o["target"] == "goal" else score_target)
	if (goal_target if o["target"] == "goal" else score_target) == Vector2.ZERO:
		target = Vector2(area.get_center().x, area.position.y - cell * 2.0)
	var a: Vector2 = o["from"]
	var c: Vector2 = o["ctrl"]
	var e := k * k
	return a.lerp(c, e).lerp(c.lerp(target, e), e)


func _board_empty() -> bool:
	for v in color:
		if v != 0 and v != STONE:
			return false
	return true


## Run and Squash mode both happen in the toad's lair: the bed, the heroes, the naps.
func lair() -> bool:
	return mode == "run" or mode == "squash"


func naps() -> int:
	return Run.naps if mode == "run" else squash_naps


func max_naps() -> int:
	return Run.max_naps() if mode == "run" else Run.MAX_NAPS


func _add_naps(n: int) -> void:
	if mode == "run":
		Run.naps += n
	else:
		squash_naps += n


## How far into the night it is, for which heroes come and how fast. Squash mode gets later as you play.
func _night() -> int:
	if mode == "squash":
		return mini(12, 1 + placements / 25)
	return Run.night_of(round_n)


func _after_move() -> void:
	if lair():
		_after_run_move()
		return
	if mode == "adventure":
		if _goal_type() == "score":
			goal_current = score
		goal_changed.emit(goal_current, int(level["target"]))
		if goal_current >= int(level["target"]):
			over = true
			drag = {}
			tool = ""
			pending_finish = {"at": time + 1.0, "won": true}
			Sfx.play("win")
			Sfx.vibrate(80, true, 1.0)
			return
	var empty := true
	for p in tray:
		if p != null:
			empty = false
	if empty:
		_deal()
	_check_over()


## A boss round with the goal reached plays on (bonus time) while the boss is on the board and
## pieces are left: squashing him drops a rare monster. Otherwise the round ends as a win.
## Squash mode bosses: the first comes at 40 pieces, the second 30 later, then one every 20.
## Returns which boss (0, 1, 2...) arrives at piece n, or -1 if none does.
static func _squash_boss_no(n: int) -> int:
	if n == 40:
		return 0
	if n >= 70 and (n - 70) % 20 == 0:
		return 1 + (n - 70) / 20
	return -1


func _boss_chase() -> bool:
	if not boss_round or boss_beaten:
		return false
	for h in heroes:
		if h.get("boss", false):
			return true
	return false


func _win_round() -> void:
	over = true
	drag = {}
	tool = ""
	pending_finish = {"at": time + 1.2, "won": true}
	say(G_WIN)
	# Whoever is still on the board legs it.
	for h in heroes:
		flyers.append({"look": _look(h), "p": _cell_center(h["px"], h["py"]), "v": Vector2(randf_range(-200, 200), randf_range(-700, -500)) * cell / 60.0,
			"r": 0.0, "vr": randf_range(-6, 6), "t0": time, "yelp": "RUN!"})
	heroes = []
	Sfx.play("win")
	Sfx.vibrate(80, true, 1.0)


func _after_run_move() -> void:
	if mode == "run" and score >= target and _boss_chase():
		# Goal reached: the other heroes run for it and only the boss is left to squash.
		if say_text != "Get the boss!":
			say(["Get the boss!"])
		for h in heroes.duplicate():
			if not h.get("boss", false):
				heroes.erase(h)
				flyers.append({"look": _look(h), "p": _cell_center(h["px"], h["py"]), "v": Vector2(randf_range(-200, 200), randf_range(-700, -500)) * cell / 60.0,
					"r": 0.0, "vr": randf_range(-6, 6), "t0": time, "yelp": "RUN!"})
	elif mode == "run" and score >= target:
		_win_round()
		return
	if raid and placements != advanced_at:
		advanced_at = placements
		# Squash mode starts slow: heroes step every other piece for the first 50 pieces.
		var slow := mode == "squash" and placements < 50 and placements % 2 == 1
		if not slow and not (_joker("snail") and placements % int(Run.v("snail")) != 0):
			_advance_heroes()
			_hero_tricks()
		spawn_in -= 1
		if mode == "squash" and _squash_boss_no(placements) >= 0:
			_spawn_boss(Run.BOSSES[_squash_boss_no(placements) % Run.BOSSES.size()])
			say(G_BOSS)
		if spawn_in <= 0 and not (boss_round and score >= target):
			var night := _night()
			_spawn_hero()
			if night >= 4 and randf() < 0.25:
				_spawn_hero()
			spawn_in = maxi(1, 3 - (night - 1) / 3) + _hero_delay()
			if mode == "squash":
				spawn_in = maxi(2, 5 - placements / 40)
		_update_near_lines()
		if naps() <= 0:
			end_reason = "woke"
			_lose()
			return
		if mode == "run" and score >= target and not _boss_chase():
			# The boss walked into the bed (or out of the round): the goal still stands.
			_win_round()
			return
	var empty := true
	for p in tray:
		if p != null:
			empty = false
	if empty:
		if mode == "run" and pieces_left <= 0 and score >= target:
			_win_round()
			return
		if mode == "run" and pieces_left <= 0:
			end_reason = "pieces"
			_lose()
			return
		_deal()
	_check_over()


func _check_over() -> void:
	var occ := occupancy()
	for p in tray:
		if p != null and BoardLogic.fits_anywhere(occ, p["shape"]):
			return
	if mode == "run" and score >= target:
		_win_round()
		return
	end_reason = "space"
	_lose()


func _lose() -> void:
	over = true
	lost = true
	over_t = time
	tool = ""
	in_fever = false
	crumble_at = time + 0.6
	pending_finish = {"at": time + 1.4, "won": false}
	Sfx.play("over")
	Sfx.vibrate(90, true, 0.8)


## The board shakes apart: blocks fall away row by row, bottom first.
func _start_crumble() -> void:
	crumbled = true
	crumble = []
	for i in N * N:
		if color[i] == 0:
			continue
		var y := i / N
		crumble.append({"p": _cell_center(i % N, y), "v": Vector2(randf_range(-160, 160), randf_range(-420, -120)) * cell / 60.0,
			"r": 0.0, "vr": randf_range(-6.0, 6.0), "color": _color_of(i), "t0": time + (N - 1 - y) * 0.07 + randf() * 0.04})
	shake = maxf(shake, 6.0 if not reduced else 0.0)
	Sfx.play("bomb", 0.7)
	Sfx.vibrate(140, true, 0.6)


## Second chance after a rewarded ad: clears the three fullest rows and deals a fresh tray.
func revive() -> void:
	revived = true
	over = false
	lost = false
	crumbled = false
	crumble = []
	crumble_at = -1.0
	var counts: Array = []
	for y in N:
		var n := 0
		for x in N:
			var v := color[y * N + x]
			if v != 0 and v != STONE:
				n += 1
		counts.append(Vector2i(n, y))
	counts.sort_custom(func(a, b): return a.x > b.x)
	var goal := _goal_type()
	for k in 3:
		var y: int = counts[k].y
		beams.append({"row": true, "i": y, "t0": time + k * 0.06, "color": Color.WHITE})
		for x in N:
			var i := y * N + x
			if color[i] == 0 or color[i] == STONE:
				continue
			if goal == "ice" and ice[i] > 0:
				goal_current += 1
			if goal == "gems" and kind[i] == KIND_GEM:
				goal_current += 1
			color[i] = 0
			kind[i] = KIND_NORMAL
			ice[i] = 0
	# The surviving blocks pop back into place one by one.
	for i in N * N:
		if color[i] != 0:
			pop[i] = time + randf() * 0.25
	Sfx.clear_chord(3, 1)
	Sfx.vibrate(60, true, 0.8)
	shake = 8.0 if not reduced else 0.0
	undo_state = {}
	_deal()
	_update_near_lines()
	_after_move()


# ---------------------------------------------------------------- heroes (raid rounds)

func say(lines: Array) -> void:
	say_text = lines.pick_random()
	say_t = time


func _hero_type() -> String:
	var night := _night()
	var total := 0
	for e in HERO_TABLE:
		if night >= int(e[1]):
			total += int(e[2])
	var r := randi_range(0, total - 1)
	for e in HERO_TABLE:
		if night >= int(e[1]):
			r -= int(e[2])
			if r < 0:
				return e[0]
	return "squire"


static func _look(h: Dictionary) -> int:
	return int(h["kind"])


func _spawn_hero() -> void:
	var occ := occupancy()
	var free: Array = []
	for x in N:
		if occ[x] == 0:
			free.append(x)
	if free.is_empty():
		return
	var x: int = free.pick_random()
	var t := _hero_type()
	heroes.append({"id": next_hero_id, "type": t, "kind": HeroArt.kind_for(t), "hp": int(HERO_TYPES[t]["hp"]), "x": x, "y": 0,
		"px": float(x), "py": -1.2, "bob": randf() * 6.0, "moves": 0})
	next_hero_id += 1


func _spawn_boss(t: String) -> void:
	var occ := occupancy()
	var x := 3 if occ[3] == 0 else (4 if occ[4] == 0 else -1)
	if x < 0:
		for k in N:
			if occ[k] == 0:
				x = k
		if x < 0:
			return
	heroes.append({"id": next_hero_id, "type": t, "kind": HeroArt.kind_for(t), "hp": int(HERO_TYPES[t]["hp"]), "x": x, "y": 0,
		"px": float(x), "py": -1.2, "bob": randf() * 6.0, "moves": 0, "boss": true})
	next_hero_id += 1
	_text(str(HERO_TYPES[t]["name"]) + "!", _cell_center(3.5, 1.0), cell * 0.7, true)
	Sfx.play("bomb", 0.5)


## Each hero walks toward the bed: straight down when free, sideways around blocks, or waits.
func _advance_heroes() -> void:
	var order := heroes.duplicate()
	order.sort_custom(func(a, b): return int(a["y"]) > int(b["y"]))
	for h in order:
		if not heroes.has(h):
			continue
		h["moves"] = int(h.get("moves", 0)) + 1
		if h.get("boss", false) and int(h["moves"]) % 3 != 0:
			continue
		for s in int(HERO_TYPES[h["type"]]["steps"]):
			var x: int = h["x"]
			var y: int = h["y"]
			if y == N - 1:
				_reach_bed(h)
				break
			if _walkable(x, y + 1):
				h["y"] = y + 1
				continue
			var dirs := [-1, 1] if randf() < 0.5 else [1, -1]
			var moved := false
			for d in dirs:
				if _walkable(x + d, y):
					h["x"] = x + d
					moved = true
					break
			if not moved:
				break


func _hero_near_bed() -> bool:
	for h in heroes:
		if int(h["y"]) >= N - 3:
			return true
	return false


func _walkable(x: int, y: int) -> bool:
	return x >= 0 and x < N and y >= 0 and y < N and color[y * N + x] == 0 and hero_at(x, y).is_empty()


func _reach_bed(h: Dictionary) -> void:
	heroes.erase(h)
	var lost := 2 if h["type"] == "bomber" or h.get("boss", false) else 1
	_add_naps(-lost)
	var c := _cell_center(float(h["x"]), float(N - 1)) + Vector2(0, cell)
	flyers.append({"look": _look(h), "p": c, "v": Vector2(randf_range(-150, 150), -900) * cell / 60.0,
		"r": 0.0, "vr": randf_range(-20, 20), "t0": time, "yelp": "Boing!"})
	angry_t = time
	if not reduced:
		shake = maxf(shake, 10.0)
	say(G_WAKE)
	_text("-%d NAP%s" % [lost, "S" if lost > 1 else ""], bed_rect.get_center() - Vector2(0, cell * 0.8), cell * 0.8, false)
	Sfx.play("over", 1.2)
	Sfx.vibrate(120, true, 1.0)


## Pieces between hero arrivals in a raid: the Web Spider and the Cow Bell each add one.
func _hero_delay() -> int:
	return int(Run.v("spider")) + (1 if Run.charms.has("bell") else 0)


## Heroes standing in cleared lines take a hit; the ones that run out of armour get flung off screen.
func _hit_heroes(hit: Dictionary, mult: float) -> int:
	var pts := 0
	var k := 0
	for h in heroes.duplicate():
		var i := int(h["y"]) * N + int(h["x"])
		if not hit.has(i) and not (_joker("hedgehog") and _next_to_hit(hit, int(h["x"]), int(h["y"]))):
			continue
		h["hp"] = int(h["hp"]) - (int(Run.v("golem")) if _joker("golem") else 1)
		k += 1
		var c := _cell_center(float(h["x"]), float(h["y"]))
		if int(h["hp"]) <= 0:
			heroes.erase(h)
			squashed += 1
			flyers.append({"look": _look(h), "p": c,
				"v": Vector2(randf_range(-500, 500), randf_range(-1100, -700)) * cell / 60.0,
				"r": 0.0, "vr": randf_range(-24, 24), "t0": time, "yelp": YELPS.pick_random()})
			pts += _squash_bonus(int(60 * mult * k))
			if h.get("boss", false):
				pts += _boss_down(c)
			if h["type"] == "bomber":
				pts += _bomber_blast(int(h["x"]), int(h["y"]))
			_text("BONK!", c - Vector2(0, cell * 0.4), cell * 0.85, true, 0.04)
			_spark(c, Color(1.0, 0.84, 0.3), 10, 1.4)
		else:
			_text(PEEL.pick_random(), c - Vector2(0, cell * 0.6), cell * 0.45, false, 0.04)
			_burst(c, Color("9aa3ad"), 10)
	if k > 0:
		Sfx.play("bomb", 1.4)
		Sfx.play_later("pick", 0.09, 0.6)
		if randf() < 0.45:
			say(G_BONK)
		if not reduced:
			shake = maxf(shake, 6.0 + k * 3.0)
		Sfx.vibrate(50, true, 0.9)
	return pts


func _next_to_hit(hit: Dictionary, x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		for r in range(1, int(Run.v("hedgehog")) + 1):
			var nx: int = x + d.x * r
			var ny: int = y + d.y * r
			if nx >= 0 and ny >= 0 and nx < N and ny < N and hit.has(ny * N + nx):
				return true
	return false


## A boss goes flat: a big payout, and in a run, a rare monster waits in the shop.
func _boss_down(c: Vector2) -> int:
	boss_beaten = true
	Meta.add("bosses")
	say(G_BOSS_DOWN)
	_text("BOSS DOWN!", c - Vector2(0, cell), cell * 1.1, true, 0.1, true)
	rings.append({"pos": c, "t0": time, "color": GOLD, "r": cell * 8.0})
	Sfx.play_later("win", 0.1)
	if not reduced:
		slowmo = 0.3
		shake = 16.0
	return 300


## What a squashed (or eaten) hero pays, with everything that cares about squashing.
func _squash_bonus(base: int) -> int:
	Meta.add("squashed")
	var pts := base
	if mode != "run":
		# Squash mode: every 6 heroes flattened win back a nap.
		if mode == "squash" and squashed % 6 == 0 and squash_naps < Run.MAX_NAPS:
			squash_naps += 1
			_text("+1 NAP", bed_rect.get_center() - Vector2(0, cell * 0.8), cell * 0.8, true, 0.2)
		return pts
	if _joker("bones"):
		pts = int(pts * Run.v("bones"))
		_joker_pop("bones", "x" + Jokers.fmt(Run.v("bones")))
	var tot := Run.totem("t_squash") * 30
	if tot > 0:
		pts += tot
		joker_pops.append("Squash Totem +%d" % tot)
	if _joker("rat"):
		Run.gold += int(Run.v("rat"))
		_joker_pop("rat", "+%d gold" % int(Run.v("rat")))
	Run.add_grow("hoarder")
	return pts


## A squashed bomber goes off: the blocks around him are blown away (5 points each).
func _bomber_blast(x: int, y: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or ny < 0 or nx >= N or ny >= N:
				continue
			var i := ny * N + nx
			if color[i] == 0 or color[i] == STONE:
				continue
			dying.append({"x": nx, "y": ny, "color": _color_of(i), "t0": time + 0.05, "spawned": false, "gem": false})
			color[i] = 0
			kind[i] = KIND_NORMAL
			ice[i] = 0
			n += 1
	var c := _cell_center(float(x), float(y))
	_burst(c, Color(1.0, 0.7, 0.2), 22)
	rings.append({"pos": c, "t0": time, "color": Color(1.0, 0.6, 0.2), "r": cell * 2.6})
	Sfx.play_later("bomb", 0.05, 0.8)
	_text("KABOOM!", c + Vector2(0, cell * 0.5), cell * 0.7, true, 0.1)
	return n * 5


## After the heroes step: healers patch up neighbours, mages freeze a block, thieves pinch a piece.
func _hero_tricks() -> void:
	for h in heroes.duplicate():
		var hx: int = h["x"]
		var hy: int = h["y"]
		var c := _cell_center(float(hx), float(hy))
		match str(h["type"]):
			"boss_thief":
				if int(h["moves"]) % 3 == 0:
					_steal_piece(c)
			"boss_wizard":
				if int(h["moves"]) % 2 == 0:
					for k in 2:
						_freeze_near(hx, hy, 3, c)
			"boss_champion":
				if int(h["moves"]) % 3 == 0 and int(h["hp"]) < int(HERO_TYPES["boss_champion"]["hp"]):
					h["hp"] = int(h["hp"]) + 1
					_text("+1 armour", c - Vector2(0, cell * 0.7), cell * 0.5, false)
			"healer":
				for o in heroes:
					if o == h or absi(int(o["x"]) - hx) > 1 or absi(int(o["y"]) - hy) > 1:
						continue
					var max_hp := int(HERO_TYPES[o["type"]]["hp"])
					if int(o["hp"]) < max_hp:
						o["hp"] = int(o["hp"]) + 1
						_text("+1 armour", _cell_center(float(o["x"]), float(o["y"])) - Vector2(0, cell * 0.6), cell * 0.4, false)
			"mage":
				if int(h["moves"]) % 3 == 0:
					_freeze_near(hx, hy, 2, c)
			"thief":
				if int(h["moves"]) % 5 == 0:
					_steal_piece(c)


## A mage's spell: one block near him (within r cells) freezes over.
func _freeze_near(hx: int, hy: int, r: int, c: Vector2) -> void:
	var near: Array = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var nx := hx + dx
			var ny := hy + dy
			if nx >= 0 and ny >= 0 and nx < N and ny < N:
				var i := ny * N + nx
				if color[i] != 0 and color[i] != STONE and ice[i] == 0:
					near.append(i)
	if near.is_empty():
		return
	var i: int = near.pick_random()
	ice[i] = 1
	_burst(_cell_center(float(i % N), float(i / N)), Color(0.85, 0.97, 1.0), 10)
	_text("Freeze!", c - Vector2(0, cell * 0.6), cell * 0.45, false)
	Sfx.play("ice")


## A thief pinches a piece from the tray (it counts as used).
func _steal_piece(c: Vector2) -> void:
	var full: Array = []
	for k in 3:
		if tray[k] != null:
			full.append(k)
	if full.is_empty():
		return
	var k: int = full.pick_random()
	tray[k] = null
	tray_pop[k] = time
	pieces_left -= 1
	_text("Yoink!", _slot_center(k) - Vector2(0, cell * 0.8), cell * 0.6, true)
	Sfx.play("drop", 1.3)


# ---------------------------------------------------------------- toad snacks

## Tongue and Pebble wait for a tap (tool); Slam and Fly Pie work at once. Returns false if it can't be used now.
func use_snack(id: String) -> bool:
	if over:
		return false
	match id:
		"tongue":
			if heroes.is_empty():
				return false
			tool = "tongue"
		"pebble":
			tool = "pebble"
		"slam":
			if heroes.is_empty():
				return false
			for h in heroes:
				for k in 2:
					var y := int(h["y"]) - 1
					if y < 0 or not _walkable(int(h["x"]), y):
						break
					h["y"] = y
			angry_t = time
			say(["HUP!", "Back you go.", "Everybody up."])
			if not reduced:
				shake = 14.0
			Sfx.play("bomb", 0.6)
			Sfx.vibrate(80, true, 1.0)
			_update_near_lines()
		"pie":
			pieces_left += 3
			say(["Mm. Fly pie.", "Crunchy."])
			Sfx.play("coin")
			_text("+3 pieces", Vector2(area.position.x + area.size.x / 2.0, inner.y + cell * 3.0), cell * 0.8, true)
			if tray[0] == null and tray[1] == null and tray[2] == null:
				_deal()
		"brew":
			_brew()
		"stir":
			undo_state = {}
			_deal()
			say(["*stir stir*", "New ones. Fine."])
			Sfx.play("power")
			_check_over()
		"honey":
			if honey:
				return false
			honey = true
			say(["Sticky.", "Mm. Honey."])
			_text("Next clear x3", Vector2(area.position.x + area.size.x / 2.0, inner.y + cell * 3.0), cell * 0.7, true)
		"feather":
			if naps() >= max_naps():
				return false
			_add_naps(1)
			say(["Ahh. Fluffy.", "Five more minutes."])
			_text("+1 NAP", bed_rect.get_center() - Vector2(0, cell * 0.8), cell * 0.8, true)
			Sfx.play("coin")
		_:
			return false
	return true


## Bog Brew: the fullest row melts away like a cleared line (heroes in it are hit too).
func _brew() -> void:
	var best := -1
	var most := 0
	for y in N:
		var n := 0
		for x in N:
			if color[y * N + x] != 0 or not hero_at(x, y).is_empty():
				n += 1
		if n > most:
			most = n
			best = y
	if best < 0:
		return
	var hit := {}
	for x in N:
		hit[best * N + x] = true
	beams.append({"row": true, "i": best, "t0": time, "color": Color("6a9a4a")})
	_destroy(hit, Vector2(N / 2.0, best))
	var pts := 20 + _hit_heroes(hit, 1.0)
	score += pts
	_text("+%d" % pts, _cell_center(N / 2.0, best), cell * 0.75, false)
	say(["*glug*", "Bubbles!"])
	Sfx.clear_chord(1, 1)
	_update_near_lines()
	_show_joker_pops()
	score_changed.emit(score, streak)
	_after_move()


func _eat_hero(c: Vector2i) -> void:
	var h := hero_at(c.x, c.y)
	if h.is_empty():
		return
	heroes.erase(h)
	squashed += 1
	var p := _cell_center(float(c.x), float(c.y))
	var pts := _squash_bonus(60)
	score += pts
	_show_joker_pops()
	_text("GULP! +%d" % pts, p - Vector2(0, cell * 0.4), cell * 0.7, true)
	# The hero is yanked down into the nest.
	flyers.append({"look": _look(h), "p": p, "v": (bed_rect.position + Vector2(cell * 2.0, cell * 0.5) - p) * 2.2,
		"r": 0.0, "vr": 18.0, "t0": time, "yelp": "NOOO"})
	say(["Mm. Crunchy.", "Tastes of tin.", "*chewing*"])
	Sfx.play("pick", 0.5)
	Sfx.vibrate(60, true, 0.9)
	tool = ""
	tool_used.emit("tongue")
	_update_near_lines()
	score_changed.emit(score, streak)
	_after_move()


# ---------------------------------------------------------------- power-ups

func set_tool(t: String) -> void:
	tool = t


func can_undo() -> bool:
	return not undo_state.is_empty() and not over


func use_swap() -> bool:
	if over:
		return false
	undo_state = {}
	_deal()
	Sfx.play("power")
	Sfx.vibrate(20, false, 0.5)
	_check_over()
	return true


func use_undo() -> bool:
	if not can_undo():
		return false
	var u := undo_state
	color = u["color"]
	kind = u["kind"]
	ice = u["ice"]
	tray = u["tray"]
	score = u["score"]
	streak = u["streak"]
	missed = u["missed"]
	placements = u["placements"]
	goal_current = u["goal"]
	dealer.rng.state = u["rng"]
	dealer.recent_groups = u["recent"]
	dealer.trays = u["trays"]
	in_fever = streak >= FEVER_STREAK
	undo_state = {}
	tray_return = [null, null, null]
	dying = []
	orbs = []
	pop.fill(-9.0)
	tray_pop = [time, time, time]
	Sfx.play("power")
	Sfx.vibrate(20, false, 0.5)
	_update_near_lines()
	score_changed.emit(score, streak)
	if mode == "adventure":
		goal_changed.emit(goal_current, int(level["target"]))
	return true


func _save_undo() -> void:
	var t: Array = []
	for p in tray:
		t.append(null if p == null else p.duplicate())
	undo_state = {
		"color": color.duplicate(), "kind": kind.duplicate(), "ice": ice.duplicate(), "tray": t,
		"score": score, "streak": streak, "missed": missed, "placements": placements, "goal": goal_current,
		"rng": dealer.rng.state, "recent": dealer.recent_groups.duplicate(), "trays": dealer.trays,
	}


func _hammer(c: Vector2i) -> void:
	var i := c.y * N + c.x
	if color[i] == 0:
		return
	_save_undo()
	var goal := _goal_type()
	if goal == "gems" and kind[i] == KIND_GEM:
		goal_current += 1
	if goal == "ice" and ice[i] > 0:
		goal_current += 1
	var center := _cell_center(c.x, c.y)
	dying.append({"x": c.x, "y": c.y, "color": _color_of(i), "t0": time, "spawned": false, "gem": kind[i] == KIND_GEM})
	_burst(center, Color.WHITE, 12)
	rings.append({"pos": center, "t0": time, "color": Color.WHITE, "r": cell * 2.2})
	color[i] = 0
	kind[i] = KIND_NORMAL
	ice[i] = 0
	shake = 7.0 if not reduced else 0.0
	Sfx.play("bomb")
	Sfx.vibrate(45, true, 0.9)
	tool = ""
	tool_used.emit("hammer")
	_update_near_lines()
	_after_move()


func _rotate(slot: int) -> void:
	if tray[slot] == null:
		return
	var p: Dictionary = tray[slot]
	var old_shape: Dictionary = p["shape"]
	var raw := Shapes.rotate_raw(old_shape["cells"])
	var ns := Shapes.by_cells(raw)
	if ns.is_empty() or ns["id"] == old_shape["id"]:
		_text("Can't rotate this one", _slot_center(slot) - Vector2(0, cell * 1.4), cell * 0.45, false)
		tool = ""
		tool_cancelled.emit()
		return
	var b := -1
	if int(p["bomb"]) >= 0:
		var bc: Vector2i = raw[int(p["bomb"])] - Shapes.min_corner(raw)
		b = ns["cells"].find(bc)
	tray[slot] = {"shape": ns, "color": p["color"], "bomb": b}
	tray_pop[slot] = time
	Sfx.play("power")
	Sfx.vibrate(18, false, 0.5)
	tool = ""
	tool_used.emit("rotate")


# ---------------------------------------------------------------- effects

func _text(t: String, pos: Vector2, size: float, gold: bool, delay := 0.0, rainbow := false) -> void:
	texts.append({"text": t, "pos": pos, "size": size, "gold": gold, "t0": time + delay, "rainbow": rainbow})


## Solid shards that tumble and fall (drawn normally).
func _burst(pos: Vector2, col: Color, n: int) -> void:
	if reduced:
		n = n / 2
	for i in n:
		if particles.size() > 600:
			return
		var a := randf() * TAU
		var sp := randf_range(140.0, 480.0) * cell / 60.0
		particles.append({
			"p": pos, "v": Vector2(cos(a), sin(a)) * sp - Vector2(0, 280.0 * cell / 60.0),
			"s": cell * randf_range(0.12, 0.26), "color": Color.WHITE if randf() < 0.2 else col,
			"life": randf_range(0.5, 0.9), "r": randf() * 6.0, "vr": randf_range(-8.0, 8.0), "spark": false,
		})


## Glowing sparks that float and fade (drawn additively in the theme's particle style).
func _spark(pos: Vector2, col: Color, n: int, power := 1.0) -> void:
	if reduced:
		n = maxi(1, n / 2)
	for i in n:
		if particles.size() > 600:
			return
		var a := randf() * TAU
		var sp := randf_range(60.0, 360.0) * power * cell / 60.0
		var c := col.lightened(0.25)
		if in_fever and randf() < 0.5:
			c = GOLD
		particles.append({
			"p": pos, "v": Vector2(cos(a), sin(a)) * sp - Vector2(0, 120.0 * cell / 60.0),
			"s": cell * randf_range(0.18, 0.4), "color": c,
			"life": randf_range(0.35, 0.8), "r": randf() * TAU, "vr": randf_range(-4.0, 4.0), "spark": true,
		})


func _process(delta: float) -> void:
	# Slow motion stretches time briefly after big clears; input and dragging stay real-time.
	var d := delta
	if slowmo > 0.0:
		slowmo -= delta
		d = delta * 0.3
	time += d

	if not drag.is_empty():
		var prev: Vector2 = drag["pos"]
		var now_pos := prev.lerp(drag["target"], minf(1.0, delta * 22.0))
		drag["pos"] = now_pos
		drag["scale"] = lerpf(drag["scale"], 1.0, minf(1.0, delta * 16.0))
		# The held piece leans into the direction it's moving.
		var vx := (now_pos.x - prev.x) / maxf(delta, 0.001)
		tilt = lerpf(tilt, clampf(vx * 0.00035, -0.22, 0.22), minf(1.0, delta * 12.0))
		if not reduced:
			trail.push_front({"p": now_pos, "t": time})
	else:
		tilt = lerpf(tilt, 0.0, minf(1.0, delta * 12.0))
	trail = trail.filter(func(e): return time - float(e["t"]) < 0.16)

	shake *= pow(0.0015, delta)
	if shake < 0.2:
		shake = 0.0
	pulse = maxf(0.0, pulse - delta * 3.5)
	# The whole board "thumps" outward and settles; shake rides on top.
	var s := 1.0 + 0.03 * sin(pulse * PI)
	scale = Vector2(s, s)
	position = board_rect.get_center() * (1.0 - s) + Vector2(randf() - 0.5, randf() - 0.5) * shake
	flash = maxf(0.0, flash - delta * 1.6)
	fever = move_toward(fever, 1.0 if in_fever else 0.0, delta * 1.5)
	fever_amount = 0.0 if reduced else fever

	var keep: Array = []
	for dd in dying:
		# Each block swells for a moment, then pops into shards and sparks.
		if not dd["spawned"] and time >= float(dd["t0"]) + 0.07:
			dd["spawned"] = true
			var c := _cell_center(dd["x"], dd["y"])
			_burst(c, dd["color"], 6)
			_spark(c, dd["color"], 4)
			if dd["gem"]:
				_spark(c, Color(0.6, 0.97, 1.0), 10, 1.4)
		if time < float(dd["t0"]) + 0.36:
			keep.append(dd)
	dying = keep

	keep = []
	var gravity := 1500.0 * cell / 60.0
	for q in particles:
		q["life"] = float(q["life"]) - d
		if q["life"] <= 0.0:
			continue
		var g := gravity * (0.25 if q["spark"] else 1.0)
		q["v"] = q["v"] * (0.97 if q["spark"] else 1.0) + Vector2(0, g * d)
		q["p"] = q["p"] + q["v"] * d
		q["r"] = float(q["r"]) + float(q["vr"]) * d
		keep.append(q)
	particles = keep

	for h in heroes:
		h["px"] = lerpf(float(h["px"]), float(h["x"]), minf(1.0, d * 12.0))
		h["py"] = lerpf(float(h["py"]), float(h["y"]), minf(1.0, d * 12.0))
	keep = []
	for f in flyers:
		f["v"] = f["v"] + Vector2(0, gravity * 1.05 * d)
		f["p"] = f["p"] + f["v"] * d
		f["r"] = float(f["r"]) + float(f["vr"]) * d
		if f["p"].y < area.end.y + cell * 4.0 and time - float(f["t0"]) < 4.0:
			keep.append(f)
	flyers = keep

	keep = []
	for o in orbs:
		if time >= float(o["t0"]) + float(o["dur"]):
			orb_arrived.emit(o["target"])
			_tick(4, 0.12)
			Sfx.play("tap", randf_range(1.6, 2.0))
			continue
		keep.append(o)
	orbs = keep

	if crumble_at > 0.0 and lost and not crumbled and time >= crumble_at:
		_start_crumble()
	for b in crumble:
		if time < float(b["t0"]):
			continue
		b["v"] = b["v"] + Vector2(0, gravity * d)
		b["p"] = b["p"] + b["v"] * d
		b["r"] = float(b["r"]) + float(b["vr"]) * d

	# Idle twinkles and a light sweep keep the board alive; fever speeds both up.
	next_glint -= delta
	if next_glint <= 0.0:
		next_glint = randf_range(0.15, 0.4) if in_fever else randf_range(0.6, 1.6)
		var filled: Array = []
		for i in N * N:
			if color[i] != 0 and color[i] != STONE:
				filled.append(i)
		if not filled.is_empty():
			glints.append({"i": filled[randi() % filled.size()], "t0": time})
	next_sweep -= delta
	if next_sweep <= 0.0:
		next_sweep = 1.4 if in_fever else 4.0
		if not reduced:
			sweep_t = time

	beams = beams.filter(func(b): return time - float(b["t0"]) < 0.45)
	rings = rings.filter(func(r): return time - float(r["t0"]) < 0.5)
	glints = glints.filter(func(gl): return time - float(gl["t0"]) < 0.6)
	texts = texts.filter(func(f): return time - float(f["t0"]) < 1.0)
	for i in 3:
		if tray_return[i] != null and time - float(tray_return[i]["t0"]) > 0.2:
			tray_return[i] = null

	if not pending_finish.is_empty() and time >= float(pending_finish["at"]):
		var won: bool = pending_finish["won"]
		pending_finish = {}
		finished.emit(won)
	queue_redraw()
	fx_layer.queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if area.size.x <= 0.0:
		return
	if lair():
		var mood := "nap"
		if time - angry_t < 1.4 or end_reason == "woke":
			mood = "angry"
		elif raid and _hero_near_bed():
			mood = "awake"
		var skin := Color(str(Meta.TOADS.get(Run.toad if mode == "run" else "bog", Meta.TOADS["bog"])["color"]))
		HeroArt.draw_bed(self, bed_rect, cell, time, mood, naps(), font, max_naps(), skin, Meta.hat())
	draw_style_box(sb_board, board_rect)
	for y in N:
		for x in N:
			draw_style_box(sb_slot, Rect2(inner + Vector2(x, y) * cell + Vector2.ONE * cell * 0.06, Vector2.ONE * cell * 0.88))

	if crumbled:
		_draw_crumble()
	else:
		_draw_blocks()
	if lair():
		_draw_heroes()

	# Ghost of the dragged piece, and pulsing light on the lines it would clear.
	if not drag.is_empty() and drag["ghost"] != null:
		var p: Dictionary = tray[drag["slot"]]
		var g: Vector2i = drag["ghost"]
		for c in p["shape"]["cells"]:
			BlockArt.draw_block(self, palette[p["color"]], _cell_center(g.x + c.x, g.y + c.y), cell, 1.0, 0.42)
		if not preview_hl.is_empty():
			sb_glow.bg_color = Color(1, 1, 1, 0.24 + 0.16 * sin(time * 11.0))
			for key in preview_hl.keys():
				var i: int = key
				if color[i] == 0:
					continue
				var cc := _cell_center(i % N, i / N)
				draw_style_box(sb_glow, Rect2(cc - Vector2.ONE * cell * 0.42, Vector2.ONE * cell * 0.84))

	# Clearing blocks: swell with a white flash, then spin away and shrink.
	for dd in dying:
		var k: float = (time - float(dd["t0"])) / 0.36
		var c := _cell_center(dd["x"], dd["y"])
		if k < 0.0:
			BlockArt.draw_block(self, dd["color"], c, cell)
			if dd["gem"]:
				BlockArt.draw_gem(self, c, cell, time)
			continue
		if k >= 1.0:
			continue
		var sc := 1.0
		var rot := 0.0
		var alpha := 1.0
		if k < 0.2:
			sc = 1.0 + 0.28 * (k / 0.2)
		else:
			var e := pow((k - 0.2) / 0.8, 1.6)
			sc = 1.28 * (1.0 - e)
			rot = e * 1.2 * (1.0 if (int(dd["x"]) + int(dd["y"])) % 2 == 0 else -1.0)
			alpha = 1.0 - e * 0.4
		draw_set_transform(c, rot, Vector2.ONE)
		BlockArt.draw_block(self, dd["color"], Vector2.ZERO, cell, sc, alpha)
		if k < 0.3:
			sb_glow.bg_color = Color(1, 1, 1, (0.3 - k) * 3.0)
			var hs := cell * 0.45 * sc
			draw_style_box(sb_glow, Rect2(-Vector2.ONE * hs, Vector2.ONE * hs * 2.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Tray
	var occ := occupancy()
	for i in 3:
		var p = tray[i]
		if p == null:
			continue
		if not drag.is_empty() and int(drag["slot"]) == i:
			continue
		var c := _slot_center(i)
		var size := tray_size
		var k := clampf((time - tray_t - i * 0.08) / 0.38, 0.0, 1.0)
		c.x += (1.0 - _ease_out_back(k)) * area.size.x * 0.7
		var alpha := clampf(k * 2.0, 0.0, 1.0)
		var ret = tray_return[i]
		if ret != null:
			var e := _ease_out_cubic(clampf((time - float(ret["t0"])) / 0.2, 0.0, 1.0))
			var from: Vector2 = ret["pos"]
			c = from.lerp(c, e)
			size = cell * lerpf(ret["scale"], tray_size / cell, e)
		var pk := clampf((time - float(tray_pop[i])) / 0.25, 0.0, 1.0)
		if pk < 1.0:
			size *= 1.0 + 0.25 * sin(pk * PI)
		if tool == "rotate":
			size *= 1.0 + 0.05 * sin(time * 8.0)
		# Pieces bob gently while they wait.
		c.y += sin(time * 2.0 + i * 1.3) * cell * 0.04
		var playable := over or BoardLogic.fits_anywhere(occ, p["shape"])
		var col: Color = palette[p["color"]] if playable else GREY
		_draw_piece(p, c, size, alpha * (1.0 if playable else 0.45), col)
	if not drag.is_empty():
		var dp: Dictionary = tray[drag["slot"]]
		var dpos: Vector2 = drag["pos"]
		var dsize := cell * float(drag["scale"])
		_draw_piece(dp, dpos + Vector2(0, cell * 0.18), dsize * 1.04, 0.0, Color.BLACK, true, tilt)
		_draw_piece(dp, dpos, dsize, 1.0, palette[dp["color"]], false, tilt)

	for q in particles:
		if q["spark"]:
			continue
		var col: Color = q["color"]
		col.a = minf(1.0, float(q["life"]) * 2.5)
		var ps: float = q["s"]
		draw_set_transform(q["p"], q["r"], Vector2.ONE)
		draw_rect(Rect2(-ps / 2.0, -ps / 2.0, ps, ps), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for f in flyers:
		FmmArt.draw_hero(self, f["look"], f["p"], cell / 40.0, time, 1.0, f["r"], 1.0, 0.0)
		if time - float(f["t0"]) < 0.9:
			_draw_yelp(f["yelp"], f["p"] - Vector2(0, cell * 0.9))

	for f in texts:
		_draw_text(f)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if lair():
		HeroArt.draw_bubble(self, bed_rect, cell, say_text, clampf((3.2 - (time - say_t)) / 0.4, 0.0, 1.0), font)

	var hint := ""
	if tool == "hammer" or tool == "pebble":
		hint = "Tap a block to smash it"
	elif tool == "tongue":
		hint = "Tap a hero for the toad to eat"
	elif tool == "rotate":
		hint = "Tap a piece to rotate it"
	elif placements == 0 and mode == "classic":
		hint = "Drag a piece onto the board"
	elif placements < 2 and lair() and raid:
		hint = "Fill a line through a hero to squash him"
	if hint != "":
		draw_string(font, Vector2(area.position.x, tray_y + tray_h + cell * 0.1), hint, HORIZONTAL_ALIGNMENT_CENTER,
			area.size.x, int(cell * 0.4), Color(0.88, 0.85, 1.0, 0.85))

	if flash > 0.0:
		draw_rect(Rect2(-2000, -2000, 6000, 6000), Color(1, 1, 1, flash))


func _draw_blocks() -> void:
	var grey_rows := int((time - over_t) / 0.07) if lost else -1
	for i in N * N:
		if color[i] != 0:
			BlockArt.draw_shadow(self, _cell_center(i % N, i / N), cell * 0.94, 0.3)
	for i in N * N:
		var v := color[i]
		if v == 0:
			continue
		var x := i % N
		var y := i / N
		var k := clampf((time - pop[i]) / 0.28, 0.0, 1.0)
		var sc := 1.0
		if k < 1.0:
			sc = 0.7 + 0.3 * _ease_out_back(k)
		var col := _color_of(i)
		if preview_hl.has(i) and v != STONE:
			col = preview_color
		if lost and y < grey_rows:
			col = col.lerp(GREY, 0.75)
		var c := _cell_center(x, y)
		if lost:
			# Nervous jitter just before the board breaks apart.
			c += Vector2(randf() - 0.5, randf() - 0.5) * cell * 0.04
		BlockArt.draw_block(self, col, c, cell, sc)
		if v == STONE:
			BlockArt.draw_stone(self, c, cell)
		if kind[i] == KIND_BOMB:
			BlockArt.draw_bomb(self, c, cell * sc, time)
		elif kind[i] == KIND_GEM:
			BlockArt.draw_gem(self, c, cell * sc, time)
		if ice[i] > 0:
			BlockArt.draw_ice(self, c, cell, ice[i])
		if v == lucky_color + 1 and lucky_color >= 0 and not lost:
			_draw_lucky(c + Vector2(cell * 0.22, -cell * 0.22), cell * 0.13 * sc)


## Paint Goblin's mark on lucky-colour blocks: a little twinkling star.
func _draw_lucky(p: Vector2, r: float) -> void:
	r *= 1.0 + 0.15 * sin(time * 5.0 + p.x * 0.05)
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + PI * k / 5.0
		pts.append(p + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, Color("fff4c0"))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.15, 0.1, 0.05, 0.7), 1.5, true)


func _draw_heroes() -> void:
	for h in heroes:
		var c := _cell_center(float(h["px"]), float(h["py"]))
		var i := int(h["y"]) * N + int(h["x"])
		var doomed := preview_hl.has(i)
		if doomed:
			sb_glow.bg_color = Color(1.0, 0.3, 0.3, 0.35 + 0.1 * sin(time * 12.0))
			draw_style_box(sb_glow, Rect2(c - Vector2.ONE * cell * 0.44, Vector2.ONE * cell * 0.88))
		var bob := sin(time * 5.5 + float(h["bob"])) * cell * 0.03
		var walking := absf(float(h["py"]) - float(h["y"])) + absf(float(h["px"]) - float(h["x"])) > 0.05
		var fx := -1.0 if int(h["x"]) >= N / 2 else 1.0
		var boss: bool = h.get("boss", false)
		var hs := cell / (34.0 if boss else 46.0)
		if boss:
			# A red glow under the boss so he reads as the big one.
			draw_circle(c + Vector2(0, cell * 0.3), cell * 0.42, Color(0.75, 0.2, 0.15, 0.35))
		FmmArt.draw_hero(self, _look(h), c + Vector2(0, cell * 0.06 + bob), hs, time + float(h["bob"]), 1.0 if doomed else 0.0, 0.0, fx, 0.6 if walking else 0.0)
		if boss:
			var cp := c + Vector2(0, -cell * 0.62 + bob)
			var crown := PackedVector2Array([cp + Vector2(-0.2, 0.08) * cell, cp + Vector2(-0.22, -0.1) * cell, cp + Vector2(-0.1, -0.02) * cell,
				cp + Vector2(0, -0.14) * cell, cp + Vector2(0.1, -0.02) * cell, cp + Vector2(0.22, -0.1) * cell, cp + Vector2(0.2, 0.08) * cell])
			draw_colored_polygon(crown, GOLD)
			draw_polyline(crown + PackedVector2Array([crown[0]]), HeroArt.OUT, cell * 0.04, true)
		var hp := int(h["hp"])
		if hp > 1:
			for k in hp:
				var pp := c + Vector2(-cell * 0.1 * (hp - 1) + k * cell * 0.2, -cell * (0.8 if boss else 0.46))
				draw_circle(pp, cell * 0.075, HeroArt.OUT)
				draw_circle(pp, cell * 0.055, GOLD)


func _draw_yelp(t: String, pos: Vector2) -> void:
	var fs := int(cell * 0.36)
	var w := 1200.0
	var base := pos + Vector2(-w / 2.0, fs * 0.35)
	draw_string_outline(font, base, t, HORIZONTAL_ALIGNMENT_CENTER, w, fs, maxi(4, fs / 4), HeroArt.OUT)
	draw_string(font, base, t, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color.WHITE)


func _draw_crumble() -> void:
	for b in crumble:
		var waiting := time < float(b["t0"])
		var col: Color = b["color"]
		col = col.lerp(GREY, 0.6)
		draw_set_transform(b["p"], b["r"], Vector2.ONE)
		BlockArt.draw_block(self, col, Vector2.ZERO, cell, 1.0, 1.0)
		if waiting:
			# Cracks appear on each block just before it falls.
			var lc := Color(0.1, 0.06, 0.2, 0.7)
			draw_polyline(PackedVector2Array([Vector2(-0.35, -0.3) * cell, Vector2(-0.05, 0.0) * cell, Vector2(0.1, 0.32) * cell]), lc, maxf(1.5, cell * 0.04))
			draw_line(Vector2(-0.05, 0.0) * cell, Vector2(0.3, -0.15) * cell, lc, maxf(1.5, cell * 0.04))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_text(f: Dictionary) -> void:
	var k: float = (time - float(f["t0"])) / 1.0
	if k < 0.0 or k >= 1.0:
		return
	var fs := int(f["size"])
	var big: bool = float(f["size"]) > cell * 1.1
	# Pop in with overshoot; big words land oversized, then settle to normal size.
	var peak := 1.15 if big else 1.0
	var sc := 1.0
	if k < 0.2:
		sc = _ease_out_back(k / 0.2) * peak
	else:
		sc = lerpf(peak, 1.0, minf(1.0, (k - 0.2) / 0.2))
	# Never wider than the board.
	var tw := font.get_string_size(f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var fit := board_rect.size.x * 0.94 / maxf(tw, 1.0)
	if sc > fit:
		sc = fit
	var pos: Vector2 = f["pos"] - Vector2(0, _ease_out_cubic(k) * cell * 1.4)
	var a := (1.0 - k) / 0.25 if k > 0.75 else 1.0
	var rot := sin(time * 24.0) * 0.06 * maxf(0.0, 1.0 - k * 3.0) if big else 0.0
	var col := Color(1.0, 0.84, 0.28, a) if f["gold"] else Color(1, 1, 1, a)
	if f.get("rainbow", false):
		col = Color.from_hsv(fmod(time * 0.8, 1.0), 0.55, 1.0, a)
	var w := 1400.0
	var base := Vector2(-w / 2.0, fs * 0.35)
	draw_set_transform(pos, rot, Vector2(sc, sc))
	draw_string_outline(font, base + Vector2(0, fs * 0.09), f["text"], HORIZONTAL_ALIGNMENT_CENTER, w, fs, maxi(6, int(fs / 4.0)), Color(0, 0, 0, 0.35 * a))
	draw_string_outline(font, base, f["text"], HORIZONTAL_ALIGNMENT_CENTER, w, fs, maxi(5, int(fs / 4.5)), Color(0.12, 0.05, 0.26, a))
	draw_string(font, base, f["text"], HORIZONTAL_ALIGNMENT_CENTER, w, fs, col)


## Everything that should glow: drawn on top with additive blending.
func _draw_fx(ci: CanvasItem) -> void:
	if area.size.x <= 0.0:
		return
	# Combo aura: the board edge glows brighter and shifts color as the streak grows; rainbow in fever.
	if streak >= 2 and not over:
		var hue_col: Color = palette[streak % palette.size()]
		if fever > 0.0:
			hue_col = hue_col.lerp(Color.from_hsv(fmod(time * 0.3, 1.0), 0.75, 1.0), fever)
		var strength := minf(1.0, 0.25 + 0.12 * streak) * (0.75 + 0.25 * sin(time * 7.0))
		for k in 3:
			var sb := StyleBoxFlat.new()
			sb.draw_center = false
			sb.set_corner_radius_all(int(cell * 0.35) + k * 6)
			sb.set_border_width_all(4 + k * 5)
			sb.border_color = Color(hue_col, strength * 0.45 / (k + 1))
			ci.draw_style_box(sb, board_rect.grow(3.0 + k * 7.0))

	# Hint: lines missing a single block glow softly, brightest at the gap.
	if not over:
		var ha := 0.05 + 0.035 * sin(time * 3.0)
		for line in near_lines:
			var idx: int = line["i"]
			var r := Rect2(inner.x, inner.y + idx * cell, cell * N, cell) if line["row"] else Rect2(inner.x + idx * cell, inner.y, cell, cell * N)
			ci.draw_rect(r.grow(-cell * 0.08), Color(1, 1, 1, ha))
			var gap: int = line["gap"]
			BlockArt.draw_glow(ci, _cell_center(gap % N, gap / N), cell * 0.75, Color(1, 1, 1, ha * 2.5))

	# Light sweep: a diagonal shine glides over the blocks like light across glass.
	var sk := (time - sweep_t) / 0.9
	if sk >= 0.0 and sk < 1.0 and not crumbled:
		var front := lerpf(-3.0, 2.0 * N + 3.0, sk)
		for i in N * N:
			if color[i] == 0:
				continue
			var dist := absf(float(i % N + i / N) - front)
			if dist < 1.8:
				var a := pow(1.0 - dist / 1.8, 2.0) * 0.32
				var c := _cell_center(i % N, i / N)
				ci.draw_texture_rect(BlockArt.base_tex, Rect2(c - Vector2.ONE * cell * 0.5, Vector2.ONE * cell), false, Color(1, 1, 1, a))

	if not drag.is_empty():
		var p: Dictionary = tray[drag["slot"]]
		var dcol: Color = palette[p["color"]]
		# Soft light trail behind the held piece.
		for e in trail:
			var age := (time - float(e["t"])) / 0.16
			BlockArt.draw_glow(ci, e["p"], cell * 1.3 * float(drag["scale"]), Color(dcol, 0.1 * (1.0 - age)))
		if drag["ghost"] != null:
			var g: Vector2i = drag["ghost"]
			var snap := maxf(0.0, 1.0 - (time - snap_t) / 0.22)
			for c in p["shape"]["cells"]:
				BlockArt.draw_glow(ci, _cell_center(g.x + c.x, g.y + c.y), cell * (0.8 + 0.4 * snap), Color(dcol, 0.22 + 0.45 * snap))

	for b in beams:
		var k: float = (time - float(b["t0"])) / 0.45
		if k < 0.0 or k >= 1.0:
			continue
		var col: Color = b["color"]
		var th := cell * (0.9 + k * 1.2)
		var idx: int = b["i"]
		var span := cell * N + cell * 0.6
		var a := (1.0 - k) * (1.0 - k)
		if b["row"]:
			var yy := inner.y + (idx + 0.5) * cell
			ci.draw_rect(Rect2(inner.x - cell * 0.3, yy - th / 2.0, span, th), Color(col, 0.55 * a))
			ci.draw_rect(Rect2(inner.x - cell * 0.3, yy - th * 0.12, span, th * 0.24), Color(1, 1, 1, 0.8 * a))
		else:
			var xx := inner.x + (idx + 0.5) * cell
			ci.draw_rect(Rect2(xx - th / 2.0, inner.y - cell * 0.3, th, span), Color(col, 0.55 * a))
			ci.draw_rect(Rect2(xx - th * 0.12, inner.y - cell * 0.3, th * 0.24, span), Color(1, 1, 1, 0.8 * a))

	for r in rings:
		var k: float = (time - float(r["t0"])) / 0.5
		if k < 0.0 or k >= 1.0:
			continue
		var col: Color = r["color"]
		var rad: float = float(r["r"]) * _ease_out_cubic(k)
		var width := cell * (0.12 if r.get("thin", false) else 0.35) * (1.0 - k)
		ci.draw_arc(r["pos"], rad, 0.0, TAU, 64, Color(col, (1.0 - k) * 0.8), maxf(2.0, width), true)
		if not r.get("thin", false):
			BlockArt.draw_glow(ci, r["pos"], rad * 0.6, Color(col, (1.0 - k) * 0.25))

	for dd in dying:
		var k: float = (time - float(dd["t0"])) / 0.36
		if k < 0.0 or k >= 0.5:
			continue
		var dcol: Color = dd["color"]
		BlockArt.draw_glow(ci, _cell_center(dd["x"], dd["y"]), cell * (0.9 + k), Color(dcol, 0.6 * (1.0 - k * 2.0)))

	for q in particles:
		if q["spark"]:
			_draw_spark(ci, q)

	for o in orbs:
		var k: float = (time - float(o["t0"])) / float(o["dur"])
		if k < 0.0:
			continue
		var col: Color = o["color"]
		for j in 4:
			var kk := maxf(0.0, k - j * 0.04)
			var a := 1.0 - j * 0.25
			BlockArt.draw_glow(ci, _orb_pos(o, kk), cell * (0.42 - j * 0.07), Color(col, 0.7 * a))
		BlockArt.draw_glow(ci, _orb_pos(o, k), cell * 0.16, Color(1, 1, 1, 0.9))

	for gl in glints:
		var k: float = (time - float(gl["t0"])) / 0.6
		var i: int = gl["i"]
		if color[i] == 0 or crumbled:
			continue
		var c := _cell_center(i % N, i / N) + Vector2(-0.22, -0.24) * cell
		BlockArt.draw_sparkle(ci, c, cell * 0.28 * sin(k * PI), Color(1, 1, 1, 0.9 * sin(k * PI)))


## Spark drawn in the current theme's style: stars, petals, bubbles, hearts or plain glow.
func _draw_spark(ci: CanvasItem, q: Dictionary) -> void:
	var life: float = q["life"]
	var col: Color = q["color"]
	var a := minf(1.0, life * 2.0)
	var sz: float = float(q["s"]) * a
	if sz < 1.5:
		return
	var p: Vector2 = q["p"]
	match spark_style:
		"star":
			BlockArt.draw_sparkle(ci, p, sz * 0.9, Color(col, a))
		"petal":
			ci.draw_set_transform(p, q["r"], Vector2(1.0, 0.5))
			ci.draw_circle(Vector2.ZERO, sz * 0.45, Color(col, a * 0.85))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bubble":
			ci.draw_arc(p, sz * 0.45, 0.0, TAU, 16, Color(col, a * 0.9), maxf(1.5, sz * 0.08), true)
			ci.draw_circle(p + Vector2(-0.15, -0.15) * sz, sz * 0.08, Color(1, 1, 1, a))
		"heart":
			var h := sz * 0.28
			ci.draw_circle(p + Vector2(-h * 0.5, -h * 0.2), h * 0.55, Color(col, a))
			ci.draw_circle(p + Vector2(h * 0.5, -h * 0.2), h * 0.55, Color(col, a))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-h, 0), p + Vector2(h, 0), p + Vector2(0, h * 1.1)]), Color(col, a))
		_:
			BlockArt.draw_glow(ci, p, sz, Color(col, a))
			BlockArt.draw_glow(ci, p, sz * 0.35, Color(1, 1, 1, a))


func _draw_piece(p: Dictionary, center: Vector2, size: float, alpha: float, col: Color, shadow := false, rot := 0.0) -> void:
	var sh: Dictionary = p["shape"]
	var cells: Array = sh["cells"]
	var off := Vector2((float(sh["w"]) - 1.0) / 2.0, (float(sh["h"]) - 1.0) / 2.0)
	draw_set_transform(center, rot, Vector2.ONE)
	for ci in cells.size():
		var c: Vector2i = cells[ci]
		var pos := (Vector2(c) - off) * size
		if shadow:
			BlockArt.draw_shadow(self, pos, size, 0.28)
			continue
		BlockArt.draw_block(self, col, pos, size, 1.0, alpha)
		if ci == int(p["bomb"]):
			BlockArt.draw_bomb(self, pos, size, time, alpha)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Additive light layer drawn above the board; GameView fills it in _draw_fx.
class FxLayer extends Node2D:
	var view: GameView

	func _draw() -> void:
		if view != null:
			view._draw_fx(self)
