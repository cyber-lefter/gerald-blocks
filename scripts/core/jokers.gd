class_name Jokers
extends RefCounted
## Everything the toad's shop sells: monster jokers (kept for the whole run, they bend the rules,
## level up to Lv 3, some grow, some come shiny), line totems (level up a kind of clear, no cap),
## toad snacks (one use each), mystery sacks, and toad charms (permanent upgrades, one of each).
## Bought in the shop between rounds with gold. Effects are applied by GameView and Run.

const MAX_JOKERS := 4
const MAX_SNACKS := 2

const COMMON := 0
const UNCOMMON := 1
const RARE := 2
const RARITY_NAMES := ["Common", "Uncommon", "Rare"]
const RARITY_COLORS := ["a09480", "6aa0c0", "e0a040"]
## How often each rarity turns up in the shop, relative to each other.
const RARITY_WEIGHT := [6.0, 3.0, 1.2]

## id -> name, what it does, price, rarity, colour, and its look for MonsterArt:
## body shape, eyes, mouth and extra parts (see MonsterArt.draw).
const JOKERS := {
	# Common
	"blob": {"name": "Hungry Blob", "desc": "+{v} points for every line cleared", "vals": [15, 30, 50], "price": 4, "rarity": COMMON, "color": "a262aa",
		"look": {"body": "blob", "eyes": 2, "mouth": "open", "extra": []}},
	"slime": {"name": "Snoring Slime", "desc": "+{v} points for a piece that clears nothing", "vals": [6, 12, 20], "price": 3, "rarity": COMMON, "color": "8fb04a",
		"look": {"body": "drip", "eyes": "sleepy", "mouth": "o", "extra": []}},
	"goblin": {"name": "Goblin Banker", "desc": "+{v} gold after every round", "vals": [3, 5, 8], "price": 5, "rarity": COMMON, "color": "6e7a4c",
		"look": {"body": "tall", "eyes": 2, "mouth": "grin", "extra": ["ears_pointy", "coin"]}},
	"grub": {"name": "Cellar Grub", "desc": "Rows cleared in the bottom two rows score x{v}", "vals": [2, 3, 4], "price": 4, "rarity": COMMON, "color": "ecc6a2",
		"look": {"body": "grub", "eyes": "small", "mouth": "line", "extra": []}},
	"tadpole": {"name": "Tadpole Swarm", "desc": "+{v} points for every block you place", "vals": [3, 5, 8], "price": 4, "rarity": COMMON, "color": "5a8a9a",
		"look": {"body": "small", "eyes": 2, "mouth": "smile", "extra": ["tail", "tadpoles"]}},
	"rat": {"name": "Pack Rat", "desc": "+{v} gold for every hero squashed", "vals": [1, 2, 3], "price": 4, "rarity": COMMON, "color": "9a8a7a",
		"look": {"body": "blob", "eyes": 2, "mouth": "teeth", "extra": ["ears_round", "whiskers", "tail"]}},
	"spider": {"name": "Web Spider", "desc": "Heroes arrive later (+{v} pieces between them)", "vals": [1, 2, 3], "price": 4, "rarity": COMMON, "color": "4a3a4a",
		"look": {"body": "small", "eyes": 4, "mouth": "fangs", "extra": ["legs"]}},
	"moth": {"name": "Lamp Moth", "desc": "Every round starts with +{v} points", "vals": [25, 50, 90], "price": 3, "rarity": COMMON, "color": "c8b890",
		"look": {"body": "small", "eyes": "big", "mouth": "line", "extra": ["moth_wings", "antennae"]}},
	# Uncommon
	"troll": {"name": "Old Troll", "desc": "+{v} pieces every round", "vals": [2, 3, 5], "price": 6, "rarity": UNCOMMON, "color": "8a6a4a",
		"look": {"body": "lump", "eyes": "small", "mouth": "tusks", "extra": ["brow"]}},
	"toadstool": {"name": "Rainbow Toadstool", "desc": "Same-colour lines score x{v} instead of x2", "vals": [3, 4, 6], "price": 5, "rarity": UNCOMMON, "color": "d05848",
		"look": {"body": "stalk", "eyes": 2, "mouth": "smile", "extra": ["cap"]}},
	"bones": {"name": "Bone Collector", "desc": "Squashed heroes pay x{v}", "vals": [2, 3, 4], "price": 5, "rarity": UNCOMMON, "color": "efe6cc",
		"look": {"body": "skull", "eyes": "holes", "mouth": "teeth", "extra": ["bone"]}},
	"golem": {"name": "Rock Golem", "desc": "Lines hit heroes {v} times (cracks armour)", "vals": [2, 3, 4], "price": 5, "rarity": UNCOMMON, "color": "8a8274",
		"look": {"body": "square", "eyes": "glow", "mouth": "line", "extra": ["cracks"]}},
	"snail": {"name": "Sleepy Snail", "desc": "Heroes move only once every {v} pieces", "vals": [2, 3, 4], "price": 6, "rarity": UNCOMMON, "color": "c9a25a",
		"look": {"body": "snail", "eyes": "stalks", "mouth": "smile", "extra": ["shell"]}},
	"ghost": {"name": "Bedsheet Ghost", "desc": "Combos survive {v} misses instead of 3", "vals": [5, 7, 10], "price": 5, "rarity": UNCOMMON, "color": "d8d4e0",
		"look": {"body": "ghost", "eyes": "holes", "mouth": "o", "extra": []}},
	"miser": {"name": "Miser Mole", "desc": "Savings pay up to +{v} gold instead of +3", "vals": [6, 9, 12], "price": 6, "rarity": UNCOMMON, "color": "7a5a48",
		"look": {"body": "blob", "eyes": "specs", "mouth": "line", "extra": ["nose", "claws"]}},
	"hedgehog": {"name": "Hedge Pig", "desc": "Heroes within {v} cells of a cleared line get hit too", "vals": [1, 2, 3], "price": 5, "rarity": UNCOMMON, "color": "a07a50",
		"look": {"body": "wide", "eyes": "small", "mouth": "smile", "extra": ["spikes", "nose"]}},
	"cyclops": {"name": "Little Cyclops", "desc": "Single-line clears score x{v}", "vals": [2, 3, 4], "price": 6, "rarity": UNCOMMON, "color": "6aa0c0",
		"look": {"body": "tall", "eyes": 1, "mouth": "grin", "extra": ["horn"]}},
	# Rare
	"bat": {"name": "Combo Bat", "desc": "Each combo step adds x{v} instead of x0.5", "vals": [1.0, 1.5, 2.0], "price": 7, "rarity": RARE, "color": "6a4a90",
		"look": {"body": "small", "eyes": 2, "mouth": "fangs", "extra": ["bat_wings", "ears_pointy"]}},
	"mouth": {"name": "Big Mouth", "desc": "Clearing 3+ lines at once scores x{v}", "vals": [2, 3, 4], "price": 7, "rarity": RARE, "color": "c0584a",
		"look": {"body": "wide", "eyes": "small", "mouth": "huge", "extra": []}},
	"lucky": {"name": "Lucky Toad", "desc": "The first clear of each round scores x{v}", "vals": [3, 4, 6], "price": 6, "rarity": RARE, "color": "788a46",
		"look": {"body": "wide", "eyes": "toad", "mouth": "smile", "extra": ["clover"]}},
	"mimic": {"name": "Treasure Mimic", "desc": "+{v} gold for every clear of 2+ lines", "vals": [1, 2, 3], "price": 7, "rarity": RARE, "color": "b07a3a",
		"look": {"body": "box", "eyes": 2, "mouth": "teeth", "extra": ["lid"]}},
	"octo": {"name": "Ink Octopus", "desc": "Clearing a row and a column at once scores x{v}", "vals": [3, 4, 6], "price": 8, "rarity": RARE, "color": "8a5aa0",
		"look": {"body": "tall", "eyes": 2, "mouth": "o", "extra": ["tentacles"]}},
	"owl": {"name": "Night Owl", "desc": "Hero raids: every clear scores x{v}", "vals": [1.5, 2.0, 2.5], "price": 7, "rarity": RARE, "color": "7a6a5a",
		"look": {"body": "blob", "eyes": "big", "mouth": "beak", "extra": ["tufts"]}},
	"crab": {"name": "Hermit Crab", "desc": "Unused pieces pay +{v} more gold each", "vals": [1, 2, 3], "price": 6, "rarity": RARE, "color": "d0704a",
		"look": {"body": "wide", "eyes": "stalks", "mouth": "line", "extra": ["pincers"]}},
	# Growing: they get stronger the longer you keep them (Run.grow counts for them).
	"worm": {"name": "Glutton Worm", "desc": "Grows +{v} points per line for every 5 lines you clear", "vals": [1, 2, 3], "grows": true,
		"price": 5, "rarity": UNCOMMON, "color": "d08a8a", "look": {"body": "grub", "eyes": 2, "mouth": "open", "extra": []}},
	"piggy": {"name": "Piggy Bank", "desc": "Pays gold after every round, +{v} more each round", "vals": [1, 2, 3], "grows": true,
		"price": 5, "rarity": UNCOMMON, "color": "e8a0a8", "look": {"body": "blob", "eyes": 2, "mouth": "smile", "extra": ["ears_pointy", "nose", "coin"]}},
	"hoarder": {"name": "Hero Hoarder", "desc": "Grows +{v} points per clear for every hero squashed", "vals": [5, 8, 12], "grows": true,
		"price": 6, "rarity": UNCOMMON, "color": "6a5a8a", "look": {"body": "square", "eyes": "glow", "mouth": "fangs", "extra": ["horn", "claws"]}},
	"yeti": {"name": "Snowball Yeti", "desc": "Grows x{v} on every clear for each round won", "vals": [0.1, 0.15, 0.2], "grows": true,
		"price": 7, "rarity": RARE, "color": "e8ecf0", "look": {"body": "tall", "eyes": "small", "mouth": "tusks", "extra": ["brow", "tufts"]}},
}

const MAX_LEVEL := 3

## Line totems level up one kind of clear. No cap: each level adds the same again.
const TOTEMS := {
	"t_one": {"name": "Totem of One", "desc": "Single-line clears", "per": 15, "color": "8fb04a"},
	"t_two": {"name": "Totem of Two", "desc": "Clears of exactly 2 lines", "per": 40, "color": "6aa0c0"},
	"t_many": {"name": "Totem of Many", "desc": "Clears of 3 or more lines", "per": 80, "color": "a262aa"},
	"t_colour": {"name": "Rainbow Totem", "desc": "Each same-colour line", "per": 30, "color": "d05848"},
	"t_squash": {"name": "Squash Totem", "desc": "Each squashed hero", "per": 30, "color": "c9a25a"},
	"t_combo": {"name": "Combo Totem", "desc": "Each clear in a combo (x2 and up)", "per": 20, "color": "e0a040"},
}

## Shiny monsters: rarer copies with a bonus on top.
const EDITIONS := {
	"foil": {"name": "Foil", "desc": "+30 points on every clear", "price": 2, "chance": 0.08, "color": "c8d8e8"},
	"gold": {"name": "Golden", "desc": "+2 gold after every round", "price": 3, "chance": 0.06, "color": "f0d060"},
	"rainbow": {"name": "Rainbow", "desc": "Every clear scores x1.5", "price": 5, "chance": 0.03, "color": "e070c0"},
}

const SACKS := {
	"sack": {"name": "Mystery Sack", "desc": "Pick 1 of 3 monsters. Rare and shiny ones more likely", "price": 4, "color": "a07a50"},
}

const SNACKS := {
	"tongue": {"name": "Tongue", "desc": "The toad eats one hero you tap", "price": 3, "color": "e88aa8", "icon": "tongue"},
	"slam": {"name": "Slam", "desc": "Every hero is knocked back up 2 rows", "price": 3, "color": "c0584a", "icon": "fist"},
	"pie": {"name": "Fly Pie", "desc": "+3 pieces this round", "price": 2, "color": "c9a25a", "icon": "pie"},
	"pebble": {"name": "Pebble", "desc": "Smash one block you tap", "price": 2, "color": "8a8274", "icon": "pebble"},
	"brew": {"name": "Bog Brew", "desc": "Clears the fullest row, heroes and all", "price": 3, "color": "6a9a4a", "icon": "bottle"},
	"stir": {"name": "Stir Stick", "desc": "Swap the pieces in the tray for new ones", "price": 2, "color": "a07a50", "icon": "stick"},
	"honey": {"name": "Honey Jar", "desc": "Your next clear scores x3", "price": 3, "color": "e0a040", "icon": "jar"},
	"feather": {"name": "Feather Pillow", "desc": "+1 nap for the toad", "price": 3, "color": "e0d8e4", "icon": "feather"},
}

const CHARMS := {
	"den": {"name": "Bigger Den", "desc": "Room for one more monster (5)", "price": 8, "color": "a262aa"},
	"pocket": {"name": "Deep Pocket", "desc": "Room for one more snack (3)", "price": 5, "color": "e88aa8"},
	"pillow": {"name": "Thick Pillow", "desc": "The toad can keep one more nap, and gets it now", "price": 6, "color": "e0d8e4"},
	"purse": {"name": "Fat Purse", "desc": "Savings pay up to +2 more gold", "price": 5, "color": "f0d060"},
	"dice": {"name": "Loaded Dice", "desc": "Rerolls cost 1 gold less", "price": 4, "color": "efe6cc"},
	"lantern": {"name": "Toad Lantern", "desc": "+1 piece every round", "price": 5, "color": "e0a040"},
	"bell": {"name": "Cow Bell", "desc": "Raids send heroes one piece slower", "price": 6, "color": "c9a25a"},
}


static func info(id: String) -> Dictionary:
	id = base(id)
	for table in [JOKERS, SNACKS, CHARMS, TOTEMS, SACKS]:
		if table.has(id):
			return table[id]
	return {}


## Shop offers are plain ids, or "id|edition" for a shiny monster.
static func base(offer: String) -> String:
	return offer.get_slice("|", 0)


static func edition(offer: String) -> String:
	return offer.get_slice("|", 1) if offer.contains("|") else ""


static func is_monster(id: String) -> bool:
	return JOKERS.has(base(id))


static func is_snack(id: String) -> bool:
	return SNACKS.has(id)


static func is_charm(id: String) -> bool:
	return CHARMS.has(id)


static func is_totem(id: String) -> bool:
	return TOTEMS.has(id)


static func is_sack(id: String) -> bool:
	return SACKS.has(id)


static func grows(id: String) -> bool:
	return bool(JOKERS.get(id, {}).get("grows", false))


static func rarity(id: String) -> int:
	return int(JOKERS.get(base(id), {}).get("rarity", COMMON))


## A monster's number at a level (1 to MAX_LEVEL): +15/+30/+50 points, x2/x3/x4 and so on.
static func val(id: String, lv: int) -> float:
	var vals: Array = JOKERS[id]["vals"]
	return float(vals[clampi(lv, 1, MAX_LEVEL) - 1])


static func fmt(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return str(snappedf(v, 0.01))


static func desc(id: String, lv := 1) -> String:
	var d := str(info(id).get("desc", ""))
	if JOKERS.has(id):
		d = d.replace("{v}", fmt(val(id, lv)))
	return d


static func _weighted_monster(rng: RandomNumberGenerator, pool: Array, weights: Array) -> String:
	var total := 0.0
	for w in weights:
		total += float(w)
	var r := rng.randf() * total
	for k in pool.size():
		r -= float(weights[k])
		if r < 0.0:
			return pool[k]
	return pool[pool.size() - 1]


static func _roll_edition(rng: RandomNumberGenerator, boost: float) -> String:
	var r := rng.randf()
	for e in ["rainbow", "gold", "foil"]:
		r -= float(EDITIONS[e]["chance"]) * boost
		if r < 0.0:
			return e
	return ""


## n monsters for an offer: new ones (sometimes shiny), or ones the player owns below the top
## level (buying those levels them up). rarity_weight decides how often rares show up.
static func roll_monsters(rng: RandomNumberGenerator, n: int, owned: Array, levels: Dictionary, rarity_weight: Array, shiny_boost: float) -> Array:
	var pool: Array = []
	var weights: Array = []
	for id in JOKERS:
		if not Meta.monster_unlocked(id):
			continue
		var w: float = rarity_weight[rarity(id)]
		if owned.has(id):
			if int(levels.get(id, 1)) >= MAX_LEVEL:
				continue
			w *= 0.6
		pool.append(id)
		weights.append(w)
	var out: Array = []
	for k in n:
		if pool.is_empty():
			break
		var id := _weighted_monster(rng, pool, weights)
		var i := pool.find(id)
		pool.remove_at(i)
		weights.remove_at(i)
		var e := "" if owned.has(id) else _roll_edition(rng, shiny_boost)
		out.append(id if e == "" else "%s|%s" % [id, e])
	return out


## A visit's offers: three monsters, two totems, a snack, a mystery sack, and a charm the run
## doesn't have yet (while any are left).
## The Hungry Toad's shops show a fourth monster; the Shiny Toad's turn up shiny three times as often.
static func roll_offers(rng: RandomNumberGenerator, owned: Array, levels: Dictionary, charms: Array, toad := "bog") -> Array:
	var out := roll_monsters(rng, 4 if toad == "hungry" else 3, owned, levels, RARITY_WEIGHT, 3.0 if toad == "shiny" else 1.0)
	var totems := TOTEMS.keys()
	for k in 2:
		var i := rng.randi_range(0, totems.size() - 1)
		out.append(totems[i])
		totems.remove_at(i)
	var snacks := SNACKS.keys()
	out.append(snacks[rng.randi_range(0, snacks.size() - 1)])
	out.append("sack")
	var left: Array = []
	for id in CHARMS:
		if not charms.has(id):
			left.append(id)
	if not left.is_empty():
		out.append(left[rng.randi_range(0, left.size() - 1)])
	return out


## The three monsters inside a mystery sack: rares and shinies turn up far more often.
static func roll_sack(rng: RandomNumberGenerator, owned: Array, levels: Dictionary) -> Array:
	return roll_monsters(rng, 3, owned, levels, [2.0, 3.0, 3.0], 3.0)


## A beaten boss drops a choice of two rare monsters (or level-ups of ones the player has).
static func roll_boss_drop(rng: RandomNumberGenerator, owned: Array, levels: Dictionary) -> Array:
	return roll_monsters(rng, 2, owned, levels, [0.0, 0.3, 3.0], 2.0)


## The little picture on a card or button: a monster (with its shine), snack, charm, totem or sack.
static func draw_icon(ci: CanvasItem, offer: String, c: Vector2, r: float, t: float) -> void:
	var id := base(offer)
	var col := Color(str(info(id).get("color", "8a8274")))
	if JOKERS.has(id):
		var e := edition(offer)
		if e != "":
			MonsterArt.draw_shine(ci, e, c, r, t)
		MonsterArt.draw(ci, JOKERS[id]["look"], c, r, t, col, id.hash() & 255)
	elif SNACKS.has(id):
		MonsterArt.draw_snack(ci, str(SNACKS[id]["icon"]), c, r, col)
	elif TOTEMS.has(id):
		MonsterArt.draw_totem(ci, id, c, r, col)
	elif SACKS.has(id):
		MonsterArt.draw_snack(ci, "sack", c, r, col)
	else:
		MonsterArt.draw_charm(ci, id, c, r, t, col)
