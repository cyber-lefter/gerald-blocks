class_name Run
extends RefCounted
## One run of the toad's night: 8 nights of 3 rounds each. Every round has a score target
## and a piece budget on a fresh board; the third round of each night is a hero raid.
## Missing a target, running out of space, or losing every nap ends the run.

const NIGHTS := 8
const ROUNDS_PER_NIGHT := 3
const MAX_NAPS := 3
const ROUND_NAMES := ["Light snooze", "Deep sleep", "Hero raid"]
# Score needed in round 1 of each night; deep sleep asks 1.3x, and raids 1.6x because squashed
# heroes pay well (their danger is the naps). The first nights are gentle; later nights climb
# steeply because levelled monsters, totems and growing monsters snowball (like Balatro's antes).
# Tuned with tests/run_bot.gd, which buys everything it can afford.
const BASE_TARGET := [100, 140, 220, 340, 520, 820, 1300, 2100]
const TARGET_MULT := [1.0, 1.3, 1.6]
const PIECES := [18, 18, 22]

## The current run, mirrored to Save so it survives closing the app (resumes at round start).
static var round_n := 1
static var naps := MAX_NAPS
static var total := 0
static var squashed := 0
static var gold := 0
static var jokers: Array = []
static var snacks: Array = []
## Toad charms bought this run (permanent upgrades, see Jokers.CHARMS).
static var charms: Array = []
## Per monster: its level (1 to Jokers.MAX_LEVEL), its shine ("foil", "gold", "rainbow"),
## and what a growing monster has counted since it was bought.
static var jlevels := {}
static var editions := {}
static var grow := {}
## Line totem levels, by totem id.
static var totems := {}
## Three monsters to pick from after opening a mystery sack (empty when no sack is open).
static var sack: Array = []
## "sack" or "boss": where the open pick came from.
static var sack_kind := "sack"
## The toad picked for this run (Meta.TOADS), and whether the run went on past the last night.
static var toad := "bog"
static var endless := false
## Shop offers for the round about to start (kept so leaving the app can't reroll them).
static var offers: Array = []
static var rerolls := 0


static func start_new(p_toad := "bog") -> void:
	toad = p_toad
	endless = false
	round_n = 1
	total = 0
	squashed = 0
	gold = 12 if toad == "rich" else 4
	jokers = []
	snacks = []
	charms = []
	jlevels = {}
	editions = {}
	grow = {}
	totems = {}
	sack = []
	sack_kind = "sack"
	offers = []
	rerolls = 0
	if toad == "old":
		for id in Jokers.TOTEMS:
			totems[id] = 1
	naps = max_naps()
	store()


static func resume() -> bool:
	var r = Save.data.get("run", null)
	if not (r is Dictionary) or r.is_empty():
		return false
	round_n = int(r.get("round", 1))
	naps = int(r.get("naps", MAX_NAPS))
	total = int(r.get("total", 0))
	squashed = int(r.get("squashed", 0))
	gold = int(r.get("gold", 0))
	jokers = Array(r.get("jokers", []))
	snacks = Array(r.get("snacks", []))
	charms = Array(r.get("charms", []))
	jlevels = Dictionary(r.get("jlevels", {}))
	editions = Dictionary(r.get("editions", {}))
	grow = Dictionary(r.get("grow", {}))
	totems = Dictionary(r.get("totems", {}))
	sack = Array(r.get("sack", []))
	sack_kind = str(r.get("sack_kind", "sack"))
	toad = str(r.get("toad", "bog"))
	endless = bool(r.get("endless", false)) or round_n > last_round()
	offers = Array(r.get("offers", []))
	rerolls = int(r.get("rerolls", 0))
	return true


static func has_saved() -> bool:
	var r = Save.data.get("run", null)
	return r is Dictionary and not r.is_empty()


static func store() -> void:
	Save.data["run"] = {"round": round_n, "naps": naps, "total": total, "squashed": squashed,
		"gold": gold, "jokers": jokers, "snacks": snacks, "charms": charms, "jlevels": jlevels, "editions": editions, "grow": grow, "totems": totems, "sack": sack, "sack_kind": sack_kind, "toad": toad, "endless": endless, "offers": offers, "rerolls": rerolls}
	Save.save()


## Ends the run: records the best and lifetime stats, and forgets the saved run.
static func finish() -> void:
	Meta.add("runs")
	if endless:
		Meta.best("endless_best", night_of(round_n))
	var best: Dictionary = Save.data.get("run_best", {"round": 0, "total": 0})
	if round_n > int(best.get("round", 0)) or (round_n == int(best.get("round", 0)) and total > int(best.get("total", 0))):
		Save.data["run_best"] = {"round": round_n, "total": total}
	Save.data["run"] = {}
	Save.data["runs_played"] = int(Save.data.get("runs_played", 0)) + 1
	Save.save()


static func best_round() -> int:
	var best: Dictionary = Save.data.get("run_best", {})
	return int(best.get("round", 0))


static func night_of(r: int) -> int:
	return (r - 1) / ROUNDS_PER_NIGHT + 1


static func slot_of(r: int) -> int:
	return (r - 1) % ROUNDS_PER_NIGHT


static func is_raid(r: int) -> bool:
	return slot_of(r) == ROUNDS_PER_NIGHT - 1


static func last_round() -> int:
	return NIGHTS * ROUNDS_PER_NIGHT


static func target(r: int) -> int:
	var night := night_of(r)
	var base: int = BASE_TARGET[mini(night, NIGHTS) - 1]
	if night > NIGHTS:
		base = int(base * pow(1.5, night - NIGHTS))
	return int(roundf(base * float(TARGET_MULT[slot_of(r)]) / 10.0) * 10.0)


## Every other night's raid is a boss raid: a champion with lots of armour and a trick of his own.
static func is_boss(r: int) -> bool:
	return is_raid(r) and night_of(r) % 2 == 0


const BOSSES := ["boss_thief", "boss_wizard", "boss_champion"]


static func boss_type(r: int) -> String:
	return BOSSES[(night_of(r) / 2 - 1) % BOSSES.size()]


static func pieces(r: int) -> int:
	return PIECES[slot_of(r)] + int(v("troll")) + (1 if charms.has("lantern") else 0) + (6 if is_boss(r) else 0)


static func has(joker: String) -> bool:
	return jokers.has(joker)


## A monster's level, or 0 when the run doesn't have it.
static func level(id: String) -> int:
	return int(jlevels.get(id, 1)) if jokers.has(id) else 0


## A monster's number at its current level (0 when the run doesn't have it).
static func v(id: String) -> float:
	return Jokers.val(id, level(id)) if jokers.has(id) else 0.0


static func totem(id: String) -> int:
	return int(totems.get(id, 0))


## How many owned monsters have this shine.
static func shiny(e: String) -> int:
	var n := 0
	for id in jokers:
		if editions.get(id, "") == e:
			n += 1
	return n


## What an offer costs: a monster you own costs more for each level it already has,
## shiny ones cost extra, and totems cost 2 more with every level.
static func price(offer: String) -> int:
	var id := Jokers.base(offer)
	var p := int(Jokers.info(id).get("price", 3))
	if Jokers.is_monster(id):
		if jokers.has(id):
			return p + 3 * level(id)
		var e := Jokers.edition(offer)
		if e != "":
			p += int(Jokers.EDITIONS[e]["price"])
		return p
	if Jokers.is_totem(id):
		return 3 + 2 * totem(id)
	return p


## Why an offer can't be bought right now ("Full", "Max level"), or "" when it can.
static func blocked(offer: String) -> String:
	var id := Jokers.base(offer)
	if Jokers.is_monster(id):
		if jokers.has(id):
			return "Max level" if level(id) >= Jokers.MAX_LEVEL else ""
		return "Full" if jokers.size() >= max_jokers() else ""
	if Jokers.is_snack(id):
		return "Full" if snacks.size() >= max_snacks() else ""
	return ""


static func buy(offer: String) -> bool:
	var cost := price(offer)
	if gold < cost or blocked(offer) != "":
		return false
	gold -= cost
	_take(offer)
	return true


## Adds a bought (or picked) item to the run.
static func _take(offer: String) -> void:
	var id := Jokers.base(offer)
	if Jokers.is_monster(id):
		if jokers.has(id):
			jlevels[id] = level(id) + 1
		else:
			jokers.append(id)
			jlevels[id] = 1
			grow[id] = 0
			var e := Jokers.edition(offer)
			if e != "":
				editions[id] = e
				Meta.add("shinies")
		Meta.mark_seen(id)
	elif Jokers.is_totem(id):
		totems[id] = totem(id) + 1
	elif Jokers.is_charm(id):
		add_charm(id)
	elif Jokers.is_sack(id):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("sack-%d-%d-%d-%d" % [round_n, rerolls, gold, total])
		sack = Jokers.roll_sack(rng, jokers, jlevels)
		sack_kind = "sack"
		for o in sack:
			Meta.mark_seen(o)
	elif Jokers.is_snack(id):
		snacks.append(id)


## Picks one monster out of the open sack (false if there's no room for it).
static func pick_from_sack(k: int) -> bool:
	if k < 0 or k >= sack.size() or blocked(sack[k]) != "":
		return false
	_take(sack[k])
	sack = []
	return true


static func sell_price(id: String) -> int:
	var p := int(Jokers.info(id)["price"]) * level(id)
	var e := str(editions.get(id, ""))
	if e != "":
		p += int(Jokers.EDITIONS[e]["price"])
	return maxi(1, p / 2)


static func sell(id: String) -> void:
	gold += sell_price(id)
	jokers.erase(id)
	jlevels.erase(id)
	editions.erase(id)
	grow.erase(id)


## A growing monster's count, and what it adds now.
static func grown(id: String) -> float:
	var n := float(grow.get(id, 0))
	match id:
		"worm":
			return floorf(n / 5.0) * v(id)
		"piggy", "hoarder", "yeti":
			return n * v(id)
	return 0.0


static func add_grow(id: String, n := 1) -> void:
	if jokers.has(id):
		grow[id] = int(grow.get(id, 0)) + n


## Called once when a round is won, before its gold is paid out.
static func round_won() -> void:
	Meta.add("rounds_won")
	Meta.best("best_night", night_of(round_n))
	add_grow("piggy")
	add_grow("yeti")


static func max_jokers() -> int:
	var dens := 0
	for d in ["den", "den2", "den3"]:
		if charms.has(d):
			dens += 1
	return Jokers.MAX_JOKERS + dens + (1 if toad == "big" else 0)


static func max_snacks() -> int:
	return Jokers.MAX_SNACKS + (1 if charms.has("pocket") else 0)


static func max_naps() -> int:
	return MAX_NAPS + (1 if charms.has("pillow") else 0) + (1 if toad == "sleepy" else 0)


## Buys a charm: it lasts for the rest of the run (the pillow also hands over its nap at once).
static func add_charm(id: String) -> void:
	charms.append(id)
	if id == "pillow":
		naps = mini(naps + 1, max_naps())


## Gold for winning a round: 3, +1 per unused piece, +1 per 5 gold saved (up to +3; more with
## the Miser Mole or the Fat Purse), plus the Goblin Banker and the Hermit Crab.
## Returns the parts so the round-end screen can list them.
static func round_reward(pieces_left: int) -> Array:
	var parts: Array = [["Round cleared", 3]]
	if pieces_left > 0:
		parts.append(["Unused pieces", pieces_left])
		if has("crab"):
			parts.append(["Hermit Crab", pieces_left * int(v("crab"))])
	var cap := (int(v("miser")) if has("miser") else 3) + (2 if charms.has("purse") else 0)
	var interest := mini(cap, gold / 5)
	if interest > 0:
		parts.append(["Savings", interest])
	if has("goblin"):
		parts.append(["Goblin Banker", int(v("goblin"))])
	if has("piggy"):
		parts.append(["Piggy Bank", int(grown("piggy"))])
	if shiny("gold") > 0:
		parts.append(["Golden monsters", 2 * shiny("gold")])
	return parts


static func reroll_cost() -> int:
	return maxi(0, 2 + rerolls - (1 if charms.has("dice") else 0))


static func round_name(r: int) -> String:
	return ROUND_NAMES[slot_of(r)]


## "Night 2 · 3/3"
static func label(r: int) -> String:
	return "Night %d · %d/%d" % [night_of(r), slot_of(r) + 1, ROUNDS_PER_NIGHT]


## Dealer difficulty for a round: harder shapes each night.
static func difficulty(r: int) -> float:
	return minf(0.75, 0.2 + 0.07 * (night_of(r) - 1))
