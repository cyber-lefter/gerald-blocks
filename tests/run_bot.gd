extends Node
## Headless run bot: plays whole runs with a greedy player and prints how far it gets.
## Run: godot --headless --path . res://tests/run_bot.tscn -- --runs=10 [--verbose]

var router


func _ready() -> void:
	Save.data["sound"] = false
	Save.data["haptics_minor"] = false
	Save.data["haptics_major"] = false
	var runs := 10
	var verbose := false
	var calibrate := false
	var no_shop := false
	var squash := false
	var toad := "bog"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--runs="):
			runs = int(a.split("=")[1])
		elif a == "--verbose":
			verbose = true
		elif a == "--squash":
			squash = true
		elif a.begins_with("--toad="):
			toad = a.split("=")[1]
		elif a == "--no-shop":
			no_shop = true
		elif a == "--calibrate":
			# Plays every piece of every round with no target and reports the scores reached.
			calibrate = true
	router = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(router)
	await get_tree().process_frame
	await get_tree().process_frame
	if squash:
		await _squash_games(runs)
		return
	var reached: Array = []
	var fails := {}
	var per_round := {}
	for k in runs:
		Run.start_new(toad)
		while true:
			var r := Run.round_n
			router.start_game("run")
			await get_tree().process_frame
			var screen: GameScreen = router.current
			screen._close_dialog()
			var view := screen.view
			if calibrate:
				view.target = 1000000000
			var moves := 0
			while not view.over:
				moves += 1
				# Snacks get used now and then, so their code runs too.
				if moves % 4 == 0 and not Run.snacks.is_empty():
					screen._on_snack(0)
					if view.tool == "tongue":
						var h: Dictionary = view.heroes[0]
						view._eat_hero(Vector2i(int(h["x"]), int(h["y"])))
					elif view.tool == "pebble":
						for i in 64:
							if view.color[i] != 0:
								view._hammer(Vector2i(i % 8, i / 8))
								break
					if view.over:
						break
				_bot_move(view)
			var won := not view.lost
			if calibrate and view.end_reason != "space":
				won = true
				view.target = view.score
			if not per_round.has(r):
				per_round[r] = []
			per_round[r].append(view.score if won else -view.score)
			if verbose:
				print("run %d round %d target %d score %d left %d naps %d %s" % [k, r, view.target, view.score, view.pieces_left, Run.naps, "WIN" if won else view.end_reason])
			view.pending_finish = {}
			screen._on_finished(won)
			if won and r < Run.last_round() and not no_shop:
				_shop()
			if not won:
				reached.append(r)
				fails[view.end_reason] = int(fails.get(view.end_reason, 0)) + 1
				break
			if r >= Run.last_round():
				reached.append(r + 1)
				break
	reached.sort()
	print("rounds reached: ", reached)
	print("last run's jokers: ", Run.jokers, " gold ", Run.gold)
	print("fail reasons: ", fails)
	var keys := per_round.keys()
	keys.sort()
	for r in keys:
		var arr: Array = per_round[r]
		var wins := arr.filter(func(v): return v >= 0).size()
		print("round %2d target %5d: %d/%d won, scores %s" % [r, Run.target(r), wins, arr.size(), str(arr)])
	print("RUN BOT DONE")
	get_tree().quit()


## Squash mode: plays N games and prints score, heroes squashed and pieces placed.
func _squash_games(n: int) -> void:
	var scores: Array = []
	for k in n:
		router.start_game("squash")
		await get_tree().process_frame
		var screen: GameScreen = router.current
		screen._close_dialog()
		var view := screen.view
		while not view.over and view.placements < 3000:
			_bot_move(view)
		print("squash %d: score %d squashed %d pieces %d %s" % [k, view.score, view.squashed, view.placements, view.end_reason])
		scores.append(view.score)
		view.pending_finish = {}
		screen._on_finished(false)
	print("squash scores: ", scores)
	print("RUN BOT DONE")
	get_tree().quit()


## Buys what it can afford, in shop order: monsters (new or level-ups), totems, a snack, the sack
## (taking the first monster it has room for), then the charm.
func _shop() -> void:
	# The round's end already opened the shop (and a boss drop, if any).
	for j in Run.sack.size():
		if Run.pick_from_sack(j):
			break
	Run.sack = []
	for k in Run.offers.size():
		Run.buy(Run.offers[k])
		if not Run.sack.is_empty():
			for j in Run.sack.size():
				if Run.pick_from_sack(j):
					break
			Run.sack = []
	Run.offers = []
	Run.store()


## Greedy: clear lines (more if a hero is in them), keep the board open, keep heroes away from the bed.
func _bot_move(view: GameView) -> void:
	var best := []
	var best_score := -INF
	var occ := view.occupancy()
	var sticky := view.sticky()
	for slot in 3:
		var p = view.tray[slot]
		if p == null:
			continue
		for y in 8:
			for x in 8:
				if not BoardLogic.fits(occ, p["shape"], x, y):
					continue
				var g := occ.duplicate()
				for c in p["shape"]["cells"]:
					g[(y + c.y) * 8 + x + c.x] = 1
				var f := BoardLogic.full_lines(g)
				var lines: int = f["rows"].size() + f["cols"].size()
				var hero_hits := 0
				for h in view.heroes:
					if f["rows"].has(int(h["y"])) or f["cols"].has(int(h["x"])):
						hero_hits += (1 + int(h["y"])) * (4 if h.get("boss", false) else 1)
				var after := BoardLogic.sim_place(occ, sticky, p["shape"], x, y)
				var sc := lines * lines * 2.0 + hero_hits * 1.5 - BoardLogic.fill_ratio(after) * 10.0 + y * 0.01
				if sc > best_score:
					best_score = sc
					best = [slot, x, y]
	if best.is_empty():
		view._check_over()
		return
	view._place(best[0], best[1], best[2])
