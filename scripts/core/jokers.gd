class_name Jokers
extends RefCounted
## Monster jokers (kept for the whole run, they bend the rules) and toad snacks (one use each).
## Bought in the shop between rounds with gold. Effects are applied by GameView and Run.

const MAX_JOKERS := 4
const MAX_SNACKS := 2

## id -> name, what it does, price, colour of the little monster on its card.
const JOKERS := {
	"blob": {"name": "Hungry Blob", "desc": "+15 points for every line cleared", "price": 4, "color": "a262aa"},
	"grub": {"name": "Cellar Grub", "desc": "Rows cleared in the bottom two rows score x2", "price": 5, "color": "ecc6a2"},
	"troll": {"name": "Old Troll", "desc": "+2 pieces every round", "price": 6, "color": "8a6a4a"},
	"slime": {"name": "Snoring Slime", "desc": "+6 points for a piece that clears nothing", "price": 4, "color": "8fb04a"},
	"bat": {"name": "Combo Bat", "desc": "Combos grow twice as fast", "price": 6, "color": "6a4a90"},
	"toadstool": {"name": "Rainbow Toadstool", "desc": "Same-colour lines score x3 instead of x2", "price": 5, "color": "d05848"},
	"bones": {"name": "Bone Collector", "desc": "Squashed heroes pay x2", "price": 5, "color": "efe6cc"},
	"goblin": {"name": "Goblin Banker", "desc": "+3 gold after every round", "price": 5, "color": "6e7a4c"},
	"mouth": {"name": "Big Mouth", "desc": "Clearing 3+ lines at once scores x2", "price": 6, "color": "c0584a"},
	"snail": {"name": "Sleepy Snail", "desc": "Heroes only move every other piece", "price": 6, "color": "c9a25a"},
	"golem": {"name": "Rock Golem", "desc": "Lines hit heroes twice (cracks armour)", "price": 5, "color": "8a8274"},
	"lucky": {"name": "Lucky Toad", "desc": "The first clear of each round scores x3", "price": 5, "color": "788a46"},
}

const SNACKS := {
	"tongue": {"name": "Tongue", "desc": "The toad eats one hero you tap", "price": 3, "color": "e88aa8"},
	"slam": {"name": "Slam", "desc": "Every hero is knocked back up 2 rows", "price": 3, "color": "c0584a"},
	"pie": {"name": "Fly Pie", "desc": "+3 pieces this round", "price": 2, "color": "c9a25a"},
	"pebble": {"name": "Pebble", "desc": "Smash one block you tap", "price": 2, "color": "8a8274"},
}


static func info(id: String) -> Dictionary:
	return JOKERS.get(id, SNACKS.get(id, {}))


static func is_snack(id: String) -> bool:
	return SNACKS.has(id)


## Three offers for the shop: two jokers the player doesn't own yet and one snack.
static func roll_offers(rng: RandomNumberGenerator, owned: Array) -> Array:
	var pool: Array = []
	for id in JOKERS:
		if not owned.has(id):
			pool.append(id)
	var out: Array = []
	for k in 2:
		if pool.is_empty():
			break
		var i := rng.randi_range(0, pool.size() - 1)
		out.append(pool[i])
		pool.remove_at(i)
	var snacks := SNACKS.keys()
	out.append(snacks[rng.randi_range(0, snacks.size() - 1)])
	return out


## The little monster on a card: an inked, cel-shaded blob with eyes, in the joker's colour.
## Snacks get a round treat instead.
static func draw_icon(ci: CanvasItem, id: String, c: Vector2, r: float, t: float) -> void:
	var col := Color(str(info(id).get("color", "8a8274")))
	var lw := maxf(2.0, r * 0.08)
	if is_snack(id):
		var pts := FmmArt.oval(c, r * 0.8, r * 0.62, 18)
		FmmArt.cel1(ci, pts, c, col, lw, r * 0.12)
		ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.18), r * 0.1, Color(1, 1, 1, 0.8))
		return
	var bob := sin(t * 2.5 + c.x * 0.01) * r * 0.05
	var body := FmmArt.blobp(c + Vector2(0, bob), r * 0.9, r * 0.72, 16, id.hash() & 255, 0.1)
	FmmArt.cel1(ci, body, c, col, lw, r * 0.14)
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * r * 0.32, -r * 0.15 + bob)
		ci.draw_circle(e, r * 0.2, FmmArt.INK)
		ci.draw_circle(e, r * 0.15, Color("f2ecd8"))
		ci.draw_circle(e + Vector2(0, r * 0.03), r * 0.07, FmmArt.INK)
	ci.draw_line(c + Vector2(-r * 0.3, r * 0.3 + bob), c + Vector2(r * 0.3, r * 0.26 + bob), FmmArt.INK, lw, true)
