class_name Meta
extends RefCounted
## Progress that lasts between runs: lifetime stats, what they unlock (toads, hats, monsters),
## which monsters the player has found, and the hat the toad wears.
## Everything lives in Save.data["meta"] and is saved along with the run.

## A requirement is [stat, amount]; [] means unlocked from the start.
const STAT_TEXT := {
	"runs": "Play %d runs",
	"wins": "Win %d whole run",
	"rounds_won": "Win %d rounds",
	"best_night": "Reach night %d",
	"squashed": "Squash %d heroes",
	"lines": "Clear %d lines",
	"gold": "Earn %d gold in total",
	"bosses": "Beat %d bosses",
	"shinies": "Buy %d shiny monsters",
	"endless_best": "Reach night %d in endless",
	"squash_best": "Score %d in Squash mode",
}

## Starting toads: each changes how a run begins. Picked before every new run.
const TOADS := {
	"bog": {"name": "Bog Toad", "desc": "No tricks. A good, sleepy toad.", "color": "788a46", "req": []},
	"rich": {"name": "Rich Toad", "desc": "Starts the run with 12 gold", "color": "b89a40", "req": ["rounds_won", 10]},
	"big": {"name": "Big Belly Toad", "desc": "Room for 5 monsters", "color": "8a6a4a", "req": ["best_night", 4]},
	"sleepy": {"name": "Sleepy Toad", "desc": "Starts with 4 naps and can keep 4", "color": "6a7aa0", "req": ["squashed", 50]},
	"shiny": {"name": "Shiny Toad", "desc": "Shiny monsters turn up 3x as often", "color": "7ab0b8", "req": ["shinies", 3]},
	"old": {"name": "Old Toad", "desc": "Starts with every totem at Lv 1", "color": "6a6a5a", "req": ["bosses", 3]},
	"hungry": {"name": "Hungry Toad", "desc": "The shop shows 4 monsters", "color": "b0584a", "req": ["wins", 1]},
}

## Hats for the toad (wardrobe). Looks only.
const HATS := {
	"none": {"name": "No hat", "req": []},
	"nightcap": {"name": "Nightcap", "req": []},
	"flower": {"name": "Flower", "req": ["runs", 3]},
	"tophat": {"name": "Top Hat", "req": ["gold", 300]},
	"viking": {"name": "Viking Helmet", "req": ["squashed", 200]},
	"wizard": {"name": "Wizard Hat", "req": ["bosses", 5]},
	"crown": {"name": "Crown", "req": ["wins", 1]},
	"party": {"name": "Party Hat", "req": ["endless_best", 10]},
	"mushroom": {"name": "Mushroom Cap", "req": ["squash_best", 5000]},
}

## Monsters that have to be earned before the shop sells them.
const MONSTER_REQ := {
	"crab": ["runs", 5],
	"worm": ["lines", 200],
	"mimic": ["gold", 150],
	"piggy": ["rounds_won", 25],
	"owl": ["squashed", 100],
	"hoarder": ["bosses", 1],
	"octo": ["lines", 600],
	"yeti": ["best_night", 6],
}


static func data() -> Dictionary:
	if not (Save.data.get("meta", null) is Dictionary):
		Save.data["meta"] = {}
	var m: Dictionary = Save.data["meta"]
	if not m.has("stats"):
		m["stats"] = {}
	if not m.has("seen"):
		m["seen"] = []
	if not m.has("hat"):
		m["hat"] = "nightcap"
	return m


static func stat(k: String) -> int:
	return int(data()["stats"].get(k, 0))


## Adds to a lifetime stat. Saved with the next Save.save() (round ends, shop, menus).
static func add(k: String, n := 1) -> void:
	var s: Dictionary = data()["stats"]
	s[k] = int(s.get(k, 0)) + n


## Raises a "best" stat if v beats it.
static func best(k: String, v: int) -> void:
	var s: Dictionary = data()["stats"]
	if v > int(s.get(k, 0)):
		s[k] = v


static func met(req: Array) -> bool:
	return req.is_empty() or stat(req[0]) >= int(req[1])


## "Squash 50 heroes (12/50)"
static func req_text(req: Array) -> String:
	if req.is_empty():
		return ""
	var n := int(req[1])
	var t := str(STAT_TEXT[req[0]]) % n
	if n != 1 and req[0] == "wins":
		t += "s"
	return "%s (%s/%s)" % [t, UI.fmt(mini(stat(req[0]), n)), UI.fmt(n)]


static func monster_unlocked(id: String) -> bool:
	return met(MONSTER_REQ.get(id, []))


static func toad_unlocked(id: String) -> bool:
	return met(TOADS[id]["req"])


static func hat_unlocked(id: String) -> bool:
	return met(HATS[id]["req"])


static func hat() -> String:
	var h := str(data()["hat"])
	return h if HATS.has(h) and hat_unlocked(h) else "nightcap"


static func set_hat(id: String) -> void:
	data()["hat"] = id
	Save.save()


static func mark_seen(id: String) -> void:
	var seen: Array = data()["seen"]
	if Jokers.is_monster(id) and not seen.has(Jokers.base(id)):
		seen.append(Jokers.base(id))


static func is_seen(id: String) -> bool:
	return data()["seen"].has(id)


## Everything unlocked right now, as "Monster: Name" lines, so a run's end can show what's new.
static func unlocked_names() -> Array:
	var out: Array = []
	for id in MONSTER_REQ:
		if monster_unlocked(id):
			out.append("New monster: %s" % Jokers.info(id)["name"])
	for id in TOADS:
		if not TOADS[id]["req"].is_empty() and toad_unlocked(id):
			out.append("New toad: %s" % TOADS[id]["name"])
	for id in HATS:
		if not HATS[id]["req"].is_empty() and hat_unlocked(id):
			out.append("New hat: %s" % HATS[id]["name"])
	return out


## Unlocks the player hasn't been told about yet; telling marks them as shown.
static func take_new() -> Array:
	var shown: Array = data().get("shown", [])
	var out := unlocked_names().filter(func(n): return not shown.has(n))
	shown.append_array(out)
	data()["shown"] = shown
	return out
