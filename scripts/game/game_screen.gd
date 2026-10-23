class_name GameScreen
extends Control
## One game session: HUD on top, the board in the middle, power-ups at the bottom,
## and the intro, pause and end-of-game dialogs.

const POWERS := [["hammer", "Hammer"], ["rotate", "Rotate"], ["swap", "Swap"], ["undo", "Undo"]]

var router
var mode := "run"
var level: Dictionary = {}
var view: GameView
var hud: HBoxContainer
var bar: HBoxContainer
var score_label: Label
var combo_pill: PanelContainer
var combo_label: Label
var side_title: Label
var side_value: Label
var power_buttons := {}
var dialog: Control
var dialog_kind := ""
var _dialog_labels: Array = []
var shown_score := 0.0
var pieces_label: Label
var round_label: Label
var snack_buttons: Array = []
## The snack whose tap-target tool is active (eaten when the tool is used).
var active_snack := -1

var c_green := Color("6a8a3a")
var c_purple := Color("a0603a")
var c_panel := Color("3a3028")
var c_gold := Color("f0d060")
var c_muted := Color("a09480")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	view = GameView.new()
	add_child(view)
	view.setup(mode, level)
	view.score_changed.connect(_on_score)
	view.goal_changed.connect(_on_goal)
	view.finished.connect(_on_finished)
	view.tool_used.connect(_on_tool_used)
	view.tool_cancelled.connect(_refresh_powers)
	view.orb_arrived.connect(_on_orb)
	_build_hud()
	_build_bar()
	resized.connect(_layout)
	_layout.call_deferred()
	_refresh_side()
	_refresh_powers()
	if mode == "run":
		_show_run_intro()
	elif mode == "squash":
		_show_squash_intro()


func _process(delta: float) -> void:
	# The counter only counts points that have landed; orbs still in flight are added on arrival.
	var target := view.shown_score()
	if absf(shown_score - target) > 0.01:
		shown_score = lerpf(shown_score, target, minf(1.0, delta * 12.0))
		if absf(shown_score - target) < 0.5:
			shown_score = target
		score_label.text = UI.fmt(roundi(shown_score))
	view.score_target = score_label.get_global_rect().get_center()
	view.goal_target = side_value.get_global_rect().get_center()


func _on_orb(target: String) -> void:
	var l := score_label if target == "score" else side_value
	l.pivot_offset = l.size / 2.0
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.08, 1.08), 0.05)
	tw.tween_property(l, "scale", Vector2.ONE, 0.08)


# ---------------------------------------------------------------- layout

func _build_hud() -> void:
	hud = HBoxContainer.new()
	hud.add_theme_constant_override("separation", 12)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	var left := HBoxContainer.new()
	left.custom_minimum_size = Vector2(170, 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(left)
	var pause := UI.button("II", c_panel, 32, 84)
	pause.custom_minimum_size = Vector2(84, 84)
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause.pressed.connect(_show_pause)
	left.add_child(pause)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(mid)
	score_label = UI.label("0", 92, Color.WHITE, 16)
	mid.add_child(score_label)
	combo_pill = PanelContainer.new()
	combo_pill.add_theme_stylebox_override("panel", UI.pill_style(c_gold))
	combo_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	combo_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_pill.modulate.a = 0.0
	combo_label = UI.label("Combo x2", 26, UI.INK)
	combo_pill.add_child(combo_label)
	mid.add_child(combo_pill)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(170, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(right)
	side_title = UI.label("BEST", 22, c_muted)
	side_value = UI.label("0", 34, c_gold)
	right.add_child(side_title)
	right.add_child(side_value)


func _build_bar() -> void:
	bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	if mode == "squash":
		var info := VBoxContainer.new()
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(info)
		info.add_child(UI.label("Squash mode", 24, c_muted))
		pieces_label = UI.label("", 40, Color.WHITE, 10)
		info.add_child(pieces_label)
		_refresh_pieces()
		return
	if mode == "run":
		# Runs swap power-ups for the toad's snacks (one button per slot), with the round,
		# the pieces left and the monster jokers in the middle.
		bar.add_theme_constant_override("separation", 10)
		for k in Run.max_snacks():
			var sb := SnackButton.new()
			sb.slot = k
			var slot := k
			sb.pressed.connect(func() -> void: _on_snack(slot))
			snack_buttons.append(sb)
		bar.add_child(snack_buttons[0])
		# A third slot (Deep Pocket charm) sits next to the first; the buttons get a little narrower.
		if snack_buttons.size() > 2:
			bar.add_child(snack_buttons[2])
			for b in snack_buttons:
				b.custom_minimum_size = Vector2(112, 130)
		var info := VBoxContainer.new()
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		bar.add_child(info)
		var strip := JokerStrip.new()
		strip.custom_minimum_size = Vector2(0, 46)
		info.add_child(strip)
		round_label = UI.label("%s · %s" % [Run.label(Run.round_n), Run.round_name(Run.round_n)], 24, c_muted)
		info.add_child(round_label)
		pieces_label = UI.label("", 40, Color.WHITE, 10)
		info.add_child(pieces_label)
		bar.add_child(snack_buttons[1])
		_refresh_pieces()
		_refresh_snacks()
		return
	for p in POWERS:
		var b := Widgets.PowerButton.new(p[0], p[1])
		var kind: String = p[0]
		b.pressed.connect(func() -> void: _on_power(kind))
		bar.add_child(b)
		power_buttons[kind] = b


func _layout() -> void:
	var ins := UI.safe_insets(self)
	var top := 18.0 + ins.x
	hud.position = Vector2(24, top)
	hud.size = Vector2(size.x - 48, 160)
	var bar_h := 150.0
	bar.position = Vector2(24, size.y - bar_h - 24 - ins.y)
	bar.size = Vector2(size.x - 48, bar_h)
	var view_top := top + 168.0
	view.set_area(Rect2(0, view_top, size.x, bar.position.y - view_top - 8.0))
	score_label.pivot_offset = score_label.size / 2.0


# ---------------------------------------------------------------- HUD updates

func _on_score(score: int, streak: int) -> void:
	var show_combo := streak >= 2
	if show_combo:
		combo_label.text = "Combo x%d" % streak
	create_tween().tween_property(combo_pill, "modulate:a", 1.0 if show_combo else 0.0, 0.15)
	_refresh_side()
	_refresh_powers()
	_refresh_pieces()
	_refresh_snacks()


func _refresh_pieces() -> void:
	if pieces_label == null:
		return
	if mode == "squash":
		pieces_label.text = "%d hero%s squashed" % [view.squashed, "" if view.squashed == 1 else "es"]
		return
	var n := view.pieces_left
	pieces_label.text = "%d piece%s left" % [n, "" if n == 1 else "s"]
	pieces_label.label_settings.font_color = Color("ff6b6b") if n <= 3 else Color.WHITE


func _on_goal(current: int, target: int) -> void:
	_refresh_side()


func _refresh_side() -> void:
	match mode:
		"run":
			side_title.text = "GOAL"
			side_value.text = UI.fmt(view.target)
			side_value.label_settings.font_color = Color("3fdc8a") if view.score >= view.target else c_gold
			if view.boss_round and not view.boss_beaten and view.score >= view.target:
				side_title.text = "BONUS"
				side_value.text = "BOSS!"
				side_value.label_settings.font_color = Color("ff6b6b")
		"squash":
			side_title.text = "BEST"
			side_value.text = UI.fmt(maxi(Meta.stat("squash_best"), view.score))


func _refresh_powers() -> void:
	for k in power_buttons:
		var b: Widgets.PowerButton = power_buttons[k]
		b.count = Save.power_count(k)
		b.active = view.tool == k
		b.disabled = view.over or (k == "undo" and not view.can_undo())
		b.queue_redraw()


# ---------------------------------------------------------------- power-ups

func _on_power(kind: String) -> void:
	if view.over or dialog != null or Ads.busy:
		return
	if view.tool == kind:
		view.set_tool("")
		_refresh_powers()
		return
	if kind == "undo" and not view.can_undo():
		return
	if Save.power_count(kind) <= 0:
		Ads.show_rewarded(kind, func() -> void:
			Save.add_power(kind, 1)
			_activate(kind)
		)
		return
	_activate(kind)


func _activate(kind: String) -> void:
	match kind:
		"swap":
			if view.use_swap():
				Save.add_power(kind, -1)
		"undo":
			if view.use_undo():
				Save.add_power(kind, -1)
		_:
			view.set_tool(kind)
			Sfx.play("power")
	_refresh_powers()


func _on_tool_used(kind: String) -> void:
	if mode == "run":
		if active_snack >= 0 and active_snack < Run.snacks.size():
			Run.snacks.remove_at(active_snack)
		active_snack = -1
		_refresh_snacks()
		return
	Save.add_power(kind, -1)
	_refresh_powers()


func _on_snack(slot: int) -> void:
	if view.over or dialog != null or slot >= Run.snacks.size():
		return
	if view.tool != "":
		# Tapping again puts the snack back.
		view.set_tool("")
		active_snack = -1
		_refresh_snacks()
		return
	var id: String = Run.snacks[slot]
	if not view.use_snack(id):
		Sfx.play("drop")
		return
	Sfx.play("power")
	if view.tool == "":
		Run.snacks.remove_at(slot)
	else:
		active_snack = slot
	_refresh_snacks()
	_refresh_pieces()
	_refresh_side()


func _refresh_snacks() -> void:
	for k in snack_buttons.size():
		var b: SnackButton = snack_buttons[k]
		b.id = Run.snacks[k] if k < Run.snacks.size() else ""
		b.active = active_snack == k and view.tool != ""
		b.queue_redraw()


# ---------------------------------------------------------------- dialogs

## body: array of [text, size, color]. buttons: array of [text, color, callable].
func _dialog(kind: String, title: String, body: Array, buttons: Array, stars := -1) -> void:
	_close_dialog()
	dialog_kind = kind
	view.input_enabled = false
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.1, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog = shade
	var center := CenterContainer.new()
	shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.card_style())
	card.custom_minimum_size = Vector2(minf(580.0, get_viewport_rect().size.x - 64.0), 0)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	card.add_child(v)
	var t := UI.label(title, 58, Color.WHITE, 12)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if stars >= 0:
		var sr := Widgets.StarRow.new(stars)
		sr.custom_minimum_size = Vector2(0, 110)
		sr.slam = true
		v.add_child(sr)
	_dialog_labels = []
	for line in body:
		var l := UI.label(line[0], line[1], line[2])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		_dialog_labels.append(l)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	v.add_child(gap)
	for b in buttons:
		var btn := UI.button(b[0], b[1], 36, 100)
		var cb: Callable = b[2]
		btn.pressed.connect(func() -> void:
			if not Ads.busy:
				cb.call()
		)
		v.add_child(btn)
	card.pivot_offset = Vector2(card.custom_minimum_size.x / 2.0, 300)
	card.scale = Vector2(0.85, 0.85)
	card.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)


func _close_dialog() -> void:
	if dialog != null:
		dialog.queue_free()
		dialog = null
	dialog_kind = ""
	view.input_enabled = true
	_refresh_powers()


func _show_pause() -> void:
	if dialog != null or view.over:
		return
	view.set_tool("")
	if mode == "squash":
		_dialog("pause", "Paused", [], [
			["Resume", c_green, _close_dialog],
			["Restart", c_purple, func() -> void: router.start_game("squash")],
			["Menu", c_panel, func() -> void: router.show_menu()],
		])
		return
	if mode == "run":
		_dialog("pause", "Paused", [["Leaving keeps your run. You'll restart this round.", 26, c_muted]], [
			["Resume", c_green, _close_dialog],
			["Menu", c_panel, func() -> void: router.show_menu()],
		])
		return


## Android back button.
func go_back() -> void:
	if dialog_kind == "pause":
		_close_dialog()
	elif dialog_kind == "intro":
		# Backing out before the first move.
		router.show_menu()
	elif dialog_kind == "end":
		Ads.game_finished(func() -> void: router.show_menu())
	elif dialog == null:
		_show_pause()


# ---------------------------------------------------------------- endings

func _on_finished(won: bool) -> void:
	match mode:
		"run":
			if won:
				_end_round_win()
			else:
				_end_run_lost()
		"squash":
			_end_squash()


# ---------------------------------------------------------------- squash mode

func _show_squash_intro() -> void:
	var body: Array = [["No goal, no piece limit. Heroes keep coming, faster and faster. The first boss shows up at 40 pieces, then more and more often.", 28, c_muted]]
	body.append(["Squash as many as you can before the toad loses his 3 naps.", 28, c_muted])
	var best := Meta.stat("squash_best")
	if best > 0:
		body.append(["Best: %s" % UI.fmt(best), 32, c_gold])
	_dialog("intro", "Squash mode", body, [["Let's go", c_green, _close_dialog]])


func _end_squash() -> void:
	var s := view.score
	var is_best := s > Meta.stat("squash_best")
	Meta.best("squash_best", s)
	var body: Array = [["Score", 26, c_muted], [UI.fmt(s), 84, Color.WHITE]]
	body.append(["%d hero%s squashed" % [view.squashed, "" if view.squashed == 1 else "es"], 30, c_gold])
	if is_best and s > 0:
		body.append(["New best!", 34, c_gold])
	else:
		body.append(["Best " + UI.fmt(Meta.stat("squash_best")), 28, c_muted])
	_append_unlocks(body)
	_dialog("end", "The toad woke up" if view.end_reason == "woke" else "Out of space", body, [
		["Play again", c_purple, func() -> void: Ads.game_finished(func() -> void: router.start_game("squash"))],
		["Menu", c_panel, func() -> void: Ads.game_finished(func() -> void: router.show_menu())],
	])


# ---------------------------------------------------------------- run mode

func _round_goal_text(r: int) -> String:
	return "Score %s in %d pieces" % [UI.fmt(Run.target(r)), Run.pieces(r)]


func _show_run_intro() -> void:
	var r := Run.round_n
	var body: Array = [[Run.round_name(r), 34, Color.WHITE], [_round_goal_text(r), 38, c_gold]]
	if Run.is_boss(r):
		var b: Dictionary = GameView.HERO_TYPES[Run.boss_type(r)]
		body.append(["Boss raid: %s" % b["name"], 34, Color("ff6b6b")])
		body.append(["%s. Squash him for a rare monster. Reach the goal and you get bonus time to catch him." % b["trick"], 26, c_muted])
	elif Run.is_raid(r):
		body.append(["Heroes are coming! Fill a row or column through a hero to squash him. Every hero that reaches the bed costs the toad a nap.", 26, c_muted])
	body.append(["Naps left: %d of %d" % [Run.naps, Run.max_naps()], 26, c_muted])
	if r == 1 and Run.toad != "bog":
		body.push_front(["Playing as the %s" % Meta.TOADS[Run.toad]["name"], 24, c_muted])
	# First-run tips: each shows once, ever.
	var tip := ""
	if Meta.tip_once("first_round"):
		tip = "Drag pieces onto the board. Fill a whole row or column to clear it and score."
	elif not Run.jokers.is_empty() and Meta.tip_once("tap_monster"):
		tip = "Tap a monster under the board to see what it does."
	elif Run.is_boss(r) and Meta.tip_once("first_boss"):
		tip = "Bosses have armour: each clear through him cracks one piece of it."
	elif Run.is_raid(r) and Meta.tip_once("trap"):
		tip = "Box a hero in with blocks and he gets stuck. Stuck heroes pay double."
	if tip != "":
		body.append(["Tip: " + tip, 26, Color("8fd0a0")])
	_dialog("intro", "Night %d · Round %d" % [Run.night_of(r), Run.slot_of(r) + 1], body, [["Let's go", c_green, _close_dialog]])


func _end_round_win() -> void:
	var r := Run.round_n
	Run.total += view.score
	Run.squashed += view.squashed
	var body: Array = [["Score", 26, c_muted], [UI.fmt(view.score), 76, Color.WHITE]]
	body.append(["Goal %s · %d piece%s to spare" % [UI.fmt(view.target), view.pieces_left, "" if view.pieces_left == 1 else "s"], 26, c_muted])
	if view.squashed > 0:
		body.append(["%d hero%s squashed" % [view.squashed, "" if view.squashed == 1 else "es"], 28, c_gold])
	if Run.is_raid(r) and Run.naps < Run.max_naps():
		Run.naps += 1
		body.append(["Raid survived: +1 nap", 28, c_gold])
	if view.boss_beaten:
		body.append(["Boss squashed! A rare monster waits in the shop.", 28, c_gold])
	Run.round_won()
	if Run.broke != "":
		body.append(["Your %s shattered!" % Run.broke, 28, Color("e07070")])
	Run.round_n = r + 1
	if r == Run.last_round() and not Run.endless:
		_dialog_run_complete()
		return
	var earned := 0
	var parts: Array = []
	for part in Run.round_reward(view.pieces_left):
		earned += int(part[1])
		parts.append("%s +%d" % [part[0], int(part[1])])
	Run.gold += earned
	Meta.add("gold", earned)
	body.append(["+%d gold  (%s)" % [earned, ", ".join(PackedStringArray(parts))], 26, c_gold])
	RunShop.open_shop()
	if view.boss_beaten:
		RunShop.open_boss_drop()
	_append_unlocks(body)
	var nr := Run.round_n
	body.append(["Next: %s, %s" % [Run.round_name(nr), _round_goal_text(nr).to_lower()], 26, c_muted])
	_dialog("end", "Round cleared!", body, [
		["Shop (%d gold)" % Run.gold, c_green, func() -> void: router.show_run_shop()],
		["Menu", c_panel, func() -> void: router.show_menu()],
	])
	var confetti := Widgets.Confetti.new()
	confetti.palette = Save.palette()
	add_child(confetti)
	confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Night 8 done: the run is won. Keep going turns it into an endless run (nights 9, 10, ...).
func _dialog_run_complete() -> void:
	Meta.add("wins")
	var body: Array = [["The toad slept through all %d nights." % Run.NIGHTS, 30, Color.WHITE]]
	body.append(["Total score %s" % UI.fmt(Run.total), 34, c_gold])
	body.append(["Heroes squashed: %d" % Run.squashed, 28, c_muted])
	body.append(["Keep going to see how far the toad can sleep. The nights only get longer.", 26, c_muted])
	_append_unlocks(body)
	Run.store()
	_dialog("end", "Full night's sleep!", body, [
		["Keep going", c_green, func() -> void:
			Run.endless = true
			var earned := 0
			for part in Run.round_reward(view.pieces_left):
				earned += int(part[1])
			Run.gold += earned
			Meta.add("gold", earned)
			RunShop.open_shop()
			router.show_run_shop()],
		["End run", c_panel, func() -> void:
			Run.round_n = Run.last_round()
			Run.finish()
			Ads.game_finished(func() -> void: router.show_menu())],
	])


## "New monster: Glutton Worm" lines for anything unlocked since the player was last told.
func _append_unlocks(body: Array) -> void:
	for n in Meta.take_new():
		body.append([n + "!", 28, Color("8fd06a")])
	Save.save()


func _end_run_lost() -> void:
	var r := Run.round_n
	Run.total += view.score
	Run.squashed += view.squashed
	var prev_best := Run.best_round()
	Run.finish()
	var title := "Out of space"
	var why := "No room left for the pieces."
	match view.end_reason:
		"woke":
			title = "The toad woke up"
			why = "\"Three heroes in my bed. Three.\""
		"pieces":
			title = "Out of pieces"
			why = "Scored %s of %s." % [UI.fmt(view.score), UI.fmt(view.target)]
		_:
			why = "Scored %s of %s. \"Nowhere to put anything. Typical.\"" % [UI.fmt(view.score), UI.fmt(view.target)]
	var body: Array = [[why, 28, c_muted]]
	body.append(["Reached %s" % Run.label(r), 34, Color.WHITE])
	body.append(["Run score %s · %d hero%s squashed" % [UI.fmt(Run.total), Run.squashed, "" if Run.squashed == 1 else "es"], 26, c_muted])
	if r > prev_best:
		body.append(["New best run!", 34, c_gold])
	_append_unlocks(body)
	_dialog("end", title, body, [
		["New run", c_green, func() -> void: Ads.game_finished(func() -> void: router.show_toad_pick())],
		["Menu", c_panel, func() -> void: Ads.game_finished(func() -> void: router.show_menu())],
	])


## A snack slot under the board: the treat's icon and name, glowing while it waits for a tap.
class SnackButton extends Button:
	var slot := 0
	var id := ""
	var active := false
	var t := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(130, 130)
		focus_mode = Control.FOCUS_NONE
		flat = true

	func _process(delta: float) -> void:
		t += delta
		if active:
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(4, 4), size - Vector2(8, 8))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("4a3a22") if active else Color("2a241c")
		sb.set_corner_radius_all(24)
		sb.border_color = Color("f0d060") if active else UI.INK
		sb.set_border_width_all(4)
		draw_style_box(sb, r)
		var font := UI.display_font()
		if id == "":
			draw_string(font, Vector2(0, size.y * 0.56), "snack", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(1, 1, 1, 0.25))
			return
		Jokers.draw_icon(self, id, Vector2(size.x / 2.0, size.y * 0.4 + (sin(t * 8.0) * 3.0 if active else 0.0)), size.x * 0.24, t)
		draw_string(font, Vector2(0, size.y * 0.86), str(Jokers.info(id)["name"]), HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color.WHITE)


## The run's monster jokers as a row of little faces. Tap one to see what it does.
class JokerStrip extends Control:
	var t := 0.0
	var info_k := -1
	var info_t := -9.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _step() -> float:
		return minf(size.y * 1.15, size.x / maxf(1.0, Run.jokers.size()))

	func _gui_input(e: InputEvent) -> void:
		if not ((e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed):
			return
		var n := Run.jokers.size()
		if n == 0:
			return
		var k := int(roundf((e.position.x - size.x / 2.0) / _step() + (n - 1) / 2.0))
		if k < 0 or k >= n:
			return
		# Tapping the same face again hides the card.
		if k == info_k and t - info_t < 4.0:
			info_k = -1
		else:
			info_k = k
			info_t = t
			Sfx.play("pick", 1.2)
		accept_event()

	func _draw() -> void:
		var n := Run.jokers.size()
		var step := _step()
		for k in n:
			var id: String = Run.jokers[k]
			var c := Vector2(size.x / 2.0 + (k - (n - 1) / 2.0) * step, size.y / 2.0)
			var e := str(Run.editions.get(id, ""))
			var r := minf(size.y * 0.42, step * 0.4) * (1.15 if k == info_k else 1.0)
			Jokers.draw_icon(self, id if e == "" else "%s|%s" % [id, e], c, r, t + k)
			# Level pips under the face.
			for j in Run.level(id) - 1:
				var p := c + Vector2((j - (Run.level(id) - 2) / 2.0) * 9.0, size.y * 0.46)
				draw_circle(p, 4.5, FmmArt.INK)
				draw_circle(p, 3.0, FmmArt.C_GOLD)
		if info_k >= 0 and info_k < n and t - info_t < 4.0:
			_draw_card(Run.jokers[info_k], clampf(1.0 - (t - info_t - 3.6) / 0.4, 0.0, 1.0))

	## The tapped monster's card, floating just above the strip.
	func _draw_card(id: String, a: float) -> void:
		var font := UI.display_font()
		var w := minf(get_viewport_rect().size.x - 32.0, 560.0)
		var x0 := size.x / 2.0 - w / 2.0
		var gx := get_global_transform().origin.x
		x0 = clampf(x0, 16.0 - gx, get_viewport_rect().size.x - 16.0 - gx - w)
		var desc := RunShop._owned_desc(id, str(Run.editions.get(id, "")))
		var ds := font.get_multiline_string_size(desc, HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 22)
		var h := 52.0 + ds.y
		var r := Rect2(x0, -h - 12.0, w, h)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("2a241c", 0.96 * a)
		sb.border_color = Color(FmmArt.INK, a)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		draw_style_box(sb, r)
		var title := "%s  Lv %d" % [Jokers.info(id)["name"], Run.level(id)]
		draw_string(font, r.position + Vector2(14, 34), title, HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 26, Color(1, 1, 1, a))
		draw_multiline_string(font, r.position + Vector2(14, 64), desc, HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 22, -1, Color(0.85, 0.8, 0.7, a))
