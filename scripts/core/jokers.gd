class_name Jokers
extends RefCounted
## Monster jokers (kept for the whole run, they bend the rules), toad snacks (one use each)
## and toad charms (permanent upgrades for the run, one of each at most).
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
	"blob": {"name": "Hungry Blob", "desc": "+15 points for every line cleared", "price": 4, "rarity": COMMON, "color": "a262aa",
		"look": {"body": "blob", "eyes": 2, "mouth": "open", "extra": []}},
	"slime": {"name": "Snoring Slime", "desc": "+6 points for a piece that clears nothing", "price": 3, "rarity": COMMON, "color": "8fb04a",
		"look": {"body": "drip", "eyes": "sleepy", "mouth": "o", "extra": []}},
	"goblin": {"name": "Goblin Banker", "desc": "+3 gold after every round", "price": 5, "rarity": COMMON, "color": "6e7a4c",
		"look": {"body": "tall", "eyes": 2, "mouth": "grin", "extra": ["ears_pointy", "coin"]}},
	"grub": {"name": "Cellar Grub", "desc": "Rows cleared in the bottom two rows score x2", "price": 4, "rarity": COMMON, "color": "ecc6a2",
		"look": {"body": "grub", "eyes": "small", "mouth": "line", "extra": []}},
	"tadpole": {"name": "Tadpole Swarm", "desc": "+3 points for every block you place", "price": 4, "rarity": COMMON, "color": "5a8a9a",
		"look": {"body": "small", "eyes": 2, "mouth": "smile", "extra": ["tail", "tadpoles"]}},
	"rat": {"name": "Pack Rat", "desc": "+1 gold for every hero squashed", "price": 4, "rarity": COMMON, "color": "9a8a7a",
		"look": {"body": "blob", "eyes": 2, "mouth": "teeth", "extra": ["ears_round", "whiskers", "tail"]}},
	"spider": {"name": "Web Spider", "desc": "Heroes arrive one piece later", "price": 4, "rarity": COMMON, "color": "4a3a4a",
		"look": {"body": "small", "eyes": 4, "mouth": "fangs", "extra": ["legs"]}},
	"moth": {"name": "Lamp Moth", "desc": "Every round starts with +25 points", "price": 3, "rarity": COMMON, "color": "c8b890",
		"look": {"body": "small", "eyes": "big", "mouth": "line", "extra": ["moth_wings", "antennae"]}},
	# Uncommon
	"troll": {"name": "Old Troll", "desc": "+2 pieces every round", "price": 6, "rarity": UNCOMMON, "color": "8a6a4a",
		"look": {"body": "lump", "eyes": "small", "mouth": "tusks", "extra": ["brow"]}},
	"toadstool": {"name": "Rainbow Toadstool", "desc": "Same-colour lines score x3 instead of x2", "price": 5, "rarity": UNCOMMON, "color": "d05848",
		"look": {"body": "stalk", "eyes": 2, "mouth": "smile", "extra": ["cap"]}},
	"bones": {"name": "Bone Collector", "desc": "Squashed heroes pay x2", "price": 5, "rarity": UNCOMMON, "color": "efe6cc",
		"look": {"body": "skull", "eyes": "holes", "mouth": "teeth", "extra": ["bone"]}},
	"golem": {"name": "Rock Golem", "desc": "Lines hit heroes twice (cracks armour)", "price": 5, "rarity": UNCOMMON, "color": "8a8274",
		"look": {"body": "square", "eyes": "glow", "mouth": "line", "extra": ["cracks"]}},
	"snail": {"name": "Sleepy Snail", "desc": "Heroes only move every other piece", "price": 6, "rarity": UNCOMMON, "color": "c9a25a",
		"look": {"body": "snail", "eyes": "stalks", "mouth": "smile", "extra": ["shell"]}},
	"ghost": {"name": "Bedsheet Ghost", "desc": "Combos survive 5 misses instead of 3", "price": 5, "rarity": UNCOMMON, "color": "d8d4e0",
		"look": {"body": "ghost", "eyes": "holes", "mouth": "o", "extra": []}},
	"miser": {"name": "Miser Mole", "desc": "Savings pay up to +6 gold instead of +3", "price": 6, "rarity": UNCOMMON, "color": "7a5a48",
		"look": {"body": "blob", "eyes": "specs", "mouth": "line", "extra": ["nose", "claws"]}},
	"hedgehog": {"name": "Hedge Pig", "desc": "Heroes next to a cleared line get hit too", "price": 5, "rarity": UNCOMMON, "color": "a07a50",
		"look": {"body": "wide", "eyes": "small", "mouth": "smile", "extra": ["spikes", "nose"]}},
	"cyclops": {"name": "Little Cyclops", "desc": "Single-line clears score x2", "price": 6, "rarity": UNCOMMON, "color": "6aa0c0",
		"look": {"body": "tall", "eyes": 1, "mouth": "grin", "extra": ["horn"]}},
	# Rare
	"bat": {"name": "Combo Bat", "desc": "Combos grow twice as fast", "price": 7, "rarity": RARE, "color": "6a4a90",
		"look": {"body": "small", "eyes": 2, "mouth": "fangs", "extra": ["bat_wings", "ears_pointy"]}},
	"mouth": {"name": "Big Mouth", "desc": "Clearing 3+ lines at once scores x2", "price": 7, "rarity": RARE, "color": "c0584a",
		"look": {"body": "wide", "eyes": "small", "mouth": "huge", "extra": []}},
	"lucky": {"name": "Lucky Toad", "desc": "The first clear of each round scores x3", "price": 6, "rarity": RARE, "color": "788a46",
		"look": {"body": "wide", "eyes": "toad", "mouth": "smile", "extra": ["clover"]}},
	"mimic": {"name": "Treasure Mimic", "desc": "+1 gold for every clear of 2+ lines", "price": 7, "rarity": RARE, "color": "b07a3a",
		"look": {"body": "box", "eyes": 2, "mouth": "teeth", "extra": ["lid"]}},
	"octo": {"name": "Ink Octopus", "desc": "Clearing a row and a column at once scores x3", "price": 8, "rarity": RARE, "color": "8a5aa0",
		"look": {"body": "tall", "eyes": 2, "mouth": "o", "extra": ["tentacles"]}},
	"owl": {"name": "Night Owl", "desc": "Hero raids: every clear scores x1.5", "price": 7, "rarity": RARE, "color": "7a6a5a",
		"look": {"body": "blob", "eyes": "big", "mouth": "beak", "extra": ["tufts"]}},
	"crab": {"name": "Hermit Crab", "desc": "Unused pieces pay double gold", "price": 6, "rarity": RARE, "color": "d0704a",
		"look": {"body": "wide", "eyes": "stalks", "mouth": "line", "extra": ["pincers"]}},
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
	if JOKERS.has(id):
		return JOKERS[id]
	if SNACKS.has(id):
		return SNACKS[id]
	return CHARMS.get(id, {})


static func is_snack(id: String) -> bool:
	return SNACKS.has(id)


static func is_charm(id: String) -> bool:
	return CHARMS.has(id)


static func rarity(id: String) -> int:
	return int(JOKERS.get(id, {}).get("rarity", COMMON))


## A visit's offers: three monsters the player doesn't own (rares turn up less), two different
## snacks, and one charm the run doesn't have yet (if any are left).
static func roll_offers(rng: RandomNumberGenerator, owned: Array, charms: Array = []) -> Array:
	var pool: Array = []
	for id in JOKERS:
		if not owned.has(id):
			pool.append(id)
	var out: Array = []
	for k in 3:
		if pool.is_empty():
			break
		var total := 0.0
		for id in pool:
			total += RARITY_WEIGHT[rarity(id)]
		var r := rng.randf() * total
		var pick: String = pool[pool.size() - 1]
		for id in pool:
			r -= RARITY_WEIGHT[rarity(id)]
			if r < 0.0:
				pick = id
				break
		out.append(pick)
		pool.erase(pick)
	var snacks := SNACKS.keys()
	for k in 2:
		var i := rng.randi_range(0, snacks.size() - 1)
		out.append(snacks[i])
		snacks.remove_at(i)
	var left: Array = []
	for id in CHARMS:
		if not charms.has(id):
			left.append(id)
	if not left.is_empty():
		out.append(left[rng.randi_range(0, left.size() - 1)])
	return out


## The little picture on a card or button: a monster, a snack, or a charm.
static func draw_icon(ci: CanvasItem, id: String, c: Vector2, r: float, t: float) -> void:
	var col := Color(str(info(id).get("color", "8a8274")))
	if JOKERS.has(id):
		MonsterArt.draw(ci, JOKERS[id]["look"], c, r, t, col, id.hash() & 255)
	elif SNACKS.has(id):
		MonsterArt.draw_snack(ci, str(SNACKS[id]["icon"]), c, r, col)
	else:
		MonsterArt.draw_charm(ci, id, c, r, t, col)
