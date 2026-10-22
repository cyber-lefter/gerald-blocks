class_name Run
extends RefCounted
## One run of the toad's night: 8 nights of 3 rounds each. Every round has a score target
## and a piece budget on a fresh board; the third round of each night is a hero raid.
## Missing a target, running out of space, or losing every nap ends the run.

const NIGHTS := 8
const ROUNDS_PER_NIGHT := 3
const MAX_NAPS := 3
const ROUND_NAMES := ["Light snooze", "Deep sleep", "Hero raid"]
# Score needed in round 1 of each night; deep sleep asks 1.3x, and raids 1.5x because squashed
# heroes pay well (their danger is the naps). Tuned with tests/run_bot.gd (--calibrate).
const BASE_TARGET := [120, 160, 200, 250, 300, 360, 430, 500]
const TARGET_MULT := [1.0, 1.3, 1.5]
const PIECES := [15, 15, 18]

## The current run, mirrored to Save so it survives closing the app (resumes at round start).
static var round_n := 1
static var naps := MAX_NAPS
static var total := 0
static var squashed := 0


static func start_new() -> void:
	round_n = 1
	naps = MAX_NAPS
	total = 0
	squashed = 0
	store()


static func resume() -> bool:
	var r = Save.data.get("run", null)
	if not (r is Dictionary) or r.is_empty():
		return false
	round_n = int(r.get("round", 1))
	naps = int(r.get("naps", MAX_NAPS))
	total = int(r.get("total", 0))
	squashed = int(r.get("squashed", 0))
	return true


static func has_saved() -> bool:
	var r = Save.data.get("run", null)
	return r is Dictionary and not r.is_empty()


static func store() -> void:
	Save.data["run"] = {"round": round_n, "naps": naps, "total": total, "squashed": squashed}
	Save.save()


## Ends the run: records the best and forgets the saved run.
static func finish() -> void:
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
		base = int(base * pow(1.35, night - NIGHTS))
	return int(roundf(base * float(TARGET_MULT[slot_of(r)]) / 10.0) * 10.0)


static func pieces(r: int) -> int:
	return PIECES[slot_of(r)]


static func round_name(r: int) -> String:
	return ROUND_NAMES[slot_of(r)]


## "Night 2 · 3/3"
static func label(r: int) -> String:
	return "Night %d · %d/%d" % [night_of(r), slot_of(r) + 1, ROUNDS_PER_NIGHT]


## Dealer difficulty for a round: harder shapes each night.
static func difficulty(r: int) -> float:
	return minf(0.75, 0.2 + 0.07 * (night_of(r) - 1))
