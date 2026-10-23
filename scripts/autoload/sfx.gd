extends Node
## Sound effects synthesized at startup (no audio files needed), plus vibration.
## The palette is soft and low: wooden clicks, marimba-like notes, gentle tails through a small room reverb.
## Swap any entry in `sounds` for a real AudioStream later.

const RATE := 32000
# C major pentatonic from middle C: warm and never clashes, whatever order notes play in.
const SCALE := [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]

var sounds := {}
var players: Array = []
var next_player := 0


const BAKED_DIR := "res://sounds/"
# Recorded sounds from Kenney (kenney.nl, CC0). Each entry lists variations, one picked at random per play.
# Anything not listed here (line-clear notes, game over, win) uses the synthesized marimba sounds.
const KENNEY := {
	"place": ["impactWood_light_000", "impactWood_light_001", "impactWood_light_002", "impactWood_light_003", "impactWood_light_004"],
	"pick": ["pluck_001", "pluck_002"],
	"drop": ["drop_002"],
	"tap": ["click_002"],
	"coin": ["confirmation_001"],
	"power": ["maximize_004"],
	"bomb": ["impactSoft_heavy_001"],
	"ice": ["impactGlass_light_001", "impactGlass_light_003"],
	"toggle": ["toggle_002"],
}
# Per-sound loudness trim in dB, to sit the recorded sounds under the music-like notes.
const TRIM := {"place": -2.0, "pick": -8.0, "drop": -6.0, "tap": -6.0, "coin": -4.0, "power": -6.0, "bomb": 0.0, "ice": -6.0, "toggle": -6.0}
const NAMES := ["tap", "pick", "place", "drop", "coin", "power", "bomb", "ice", "over", "win",
	"note0", "note1", "note2", "note3", "note4", "note5", "note6", "note7", "note8", "note9", "note10"]


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		players.append(p)
	# Pre-rendered .wav files load instantly; synthesizing takes a second or more on a phone.
	if ResourceLoader.exists(BAKED_DIR + "place.wav"):
		for key in NAMES:
			sounds[key] = load(BAKED_DIR + key + ".wav")
	else:
		synthesize()
	synthesize_extra()
	load_recorded()


func load_recorded() -> void:
	for key in KENNEY:
		var variants: Array = []
		for file in KENNEY[key]:
			var path: String = BAKED_DIR + "kenney/" + file + ".ogg"
			if ResourceLoader.exists(path):
				variants.append(load(path))
		if not variants.is_empty():
			sounds[key] = variants


## Builds every sound in code (the baked copies in res://sounds/ were made from these).
func synthesize() -> void:
	# Each part is a dictionary; missing keys use the defaults in _make().
	sounds["tap"] = _make([
		{"f": 620.0, "f2": 480.0, "dur": 0.05, "vol": 0.22, "decay": 60.0, "lp": 2200.0},
		{"wave": "noise", "dur": 0.015, "vol": 0.08, "decay": 200.0, "lp": 2500.0},
	], 0.1)
	sounds["pick"] = _make([
		{"f": 330.0, "f2": 420.0, "dur": 0.09, "vol": 0.22, "attack": 0.008, "decay": 30.0, "lp": 1800.0},
	], 0.1)
	# A soft wooden "thock": low body, a hint of knock, and a tiny filtered click on top.
	sounds["place"] = _make([
		{"f": 150.0, "f2": 95.0, "dur": 0.16, "vol": 0.75, "attack": 0.002, "decay": 28.0, "lp": 900.0},
		{"f": 310.0, "f2": 260.0, "dur": 0.07, "vol": 0.18, "decay": 55.0, "lp": 1200.0},
		{"wave": "noise", "dur": 0.02, "vol": 0.12, "decay": 180.0, "lp": 1600.0},
	], 0.12)
	sounds["drop"] = _make([
		{"f": 210.0, "f2": 160.0, "dur": 0.14, "vol": 0.25, "attack": 0.01, "decay": 22.0, "lp": 900.0},
	], 0.1)
	sounds["coin"] = _make(_mallet(783.99, 0.0, 0.16) + _mallet(1046.5, 0.08, 0.16), 0.3)
	sounds["power"] = _make([
		{"f": 260.0, "f2": 520.0, "dur": 0.3, "vol": 0.16, "attack": 0.06, "decay": 6.0, "lp": 1400.0},
		{"wave": "noise", "dur": 0.3, "vol": 0.1, "attack": 0.08, "decay": 8.0, "lp": 900.0},
	], 0.25)
	# Deep, rounded boom rather than a harsh blast.
	sounds["bomb"] = _make([
		{"f": 75.0, "f2": 38.0, "dur": 0.6, "vol": 0.9, "attack": 0.004, "decay": 7.0, "lp": 500.0},
		{"wave": "noise", "dur": 0.4, "vol": 0.3, "attack": 0.003, "decay": 10.0, "lp": 450.0},
	], 0.3)
	# Glassy little crack, kept quiet.
	sounds["ice"] = _make(_mallet(1318.51, 0.0, 0.07) + [
		{"wave": "noise", "dur": 0.05, "vol": 0.06, "decay": 90.0, "lp": 3000.0},
	], 0.25)
	var over: Array = []
	for k in 4:
		over += _mallet([392.0, 329.63, 261.63, 196.0][k], k * 0.16, 0.3)
	sounds["over"] = _make(over, 0.45)
	var win: Array = []
	for k in 5:
		win += _mallet(SCALE[[0, 2, 4, 5, 7][k]], k * 0.1, 0.26)
	sounds["win"] = _make(win, 0.45)
	for i in SCALE.size():
		sounds["note%d" % i] = _make(_mallet(SCALE[i], 0.0, 0.3), 0.35)


## Sounds added for the toad game (hero tricks, traps, legendaries). Short, so they're
## always built in code at startup rather than baked.
func synthesize_extra() -> void:
	# An arrow: a quick airy swish with a falling whistle.
	sounds["arrow"] = _make([
		{"wave": "noise", "dur": 0.12, "vol": 0.22, "attack": 0.01, "decay": 22.0, "lp": 3500.0},
		{"f": 1500.0, "f2": 700.0, "dur": 0.1, "vol": 0.07, "decay": 18.0, "lp": 3000.0},
	], 0.1)
	# A hex: two slightly detuned notes sliding down together, a little queasy.
	sounds["hex"] = _make([
		{"f": 440.0, "f2": 220.0, "dur": 0.45, "vol": 0.14, "attack": 0.02, "decay": 4.0, "lp": 1300.0},
		{"f": 466.0, "f2": 233.0, "dur": 0.45, "vol": 0.12, "attack": 0.02, "decay": 4.0, "lp": 1300.0},
	], 0.3)
	# The Sticky Net: a soft rope swish and a pluck.
	sounds["net"] = _make([
		{"wave": "noise", "dur": 0.2, "vol": 0.18, "attack": 0.03, "decay": 12.0, "lp": 900.0},
		{"f": 300.0, "f2": 240.0, "dur": 0.12, "vol": 0.18, "decay": 25.0, "delay": 0.08, "lp": 1500.0},
	], 0.15)
	# A hero boxed in: two dull thuds.
	sounds["trap"] = _make([
		{"f": 180.0, "f2": 120.0, "dur": 0.12, "vol": 0.4, "decay": 30.0, "lp": 800.0},
		{"f": 160.0, "f2": 100.0, "dur": 0.14, "vol": 0.4, "decay": 26.0, "delay": 0.09, "lp": 800.0},
	], 0.12)
	# The Gargoyle flinging a hero back up: a springy boing.
	sounds["fling"] = _make([
		{"f": 180.0, "f2": 720.0, "dur": 0.28, "vol": 0.24, "attack": 0.004, "decay": 7.0, "lp": 2000.0},
	], 0.2)
	# A boss walks in: a low horn with a fifth on top.
	sounds["boss"] = _make([
		{"f": 110.0, "f2": 98.0, "dur": 0.7, "vol": 0.32, "attack": 0.06, "decay": 3.0, "lp": 600.0},
		{"f": 165.0, "f2": 147.0, "dur": 0.7, "vol": 0.18, "attack": 0.08, "decay": 3.0, "lp": 700.0},
	], 0.35)
	# A legendary in the drop: a bright rising arpeggio with a shimmer.
	var legend: Array = []
	for k in 5:
		legend += _mallet([523.25, 659.25, 783.99, 1046.5, 1318.51][k], k * 0.07, 0.22)
	legend.append({"wave": "noise", "dur": 0.6, "vol": 0.04, "attack": 0.2, "decay": 4.0, "lp": 6000.0, "delay": 0.1})
	sounds["legend"] = _make(legend, 0.45)


## Marimba-like note: a round fundamental plus a quickly fading overtone near 4x, as a wooden bar has.
func _mallet(f: float, delay: float, vol: float) -> Array:
	return [
		{"f": f, "dur": 0.9, "vol": vol, "attack": 0.003, "decay": 5.5, "delay": delay, "lp": 2400.0},
		{"f": f * 3.93, "dur": 0.25, "vol": vol * 0.18, "attack": 0.002, "decay": 28.0, "delay": delay, "lp": 4000.0},
		{"f": f * 2.0, "dur": 0.5, "vol": vol * 0.1, "attack": 0.003, "decay": 9.0, "delay": delay, "lp": 3000.0},
	]


func _make(parts: Array, reverb := 0.2) -> AudioStreamWAV:
	var total := 0.0
	for p in parts:
		total = maxf(total, float(p.get("dur", 0.1)) + float(p.get("delay", 0.0)))
	var tail := 0.35 if reverb > 0.0 else 0.0
	var n := int((total + tail) * RATE) + 2
	var buf := PackedFloat32Array()
	buf.resize(n)
	buf.fill(0.0)
	for p in parts:
		var f0: float = p.get("f", 0.0)
		var f1: float = p.get("f2", f0)
		var dur: float = p.get("dur", 0.1)
		var wave: String = p.get("wave", "sine")
		var vol: float = p.get("vol", 0.2)
		var attack: float = p.get("attack", 0.002)
		var decay: float = p.get("decay", 10.0)
		var lp: float = p.get("lp", 3000.0)
		var start := int(float(p.get("delay", 0.0)) * RATE)
		var count := int(dur * RATE)
		var a := 1.0 - exp(-TAU * lp / RATE)
		var y := 0.0
		var phase := 0.0
		for s in count:
			var t := float(s) / RATE
			var k := float(s) / count
			var f := f0
			if f0 > 0.0 and f1 > 0.0 and f1 != f0:
				f = f0 * pow(f1 / f0, k)
			phase += f / RATE
			var x := 0.0
			if wave == "noise":
				x = randf() * 2.0 - 1.0
			else:
				x = sin(phase * TAU)
			y += a * (x - y)
			var env := minf(1.0, t / maxf(attack, 0.0005)) * exp(-decay * t)
			if k > 0.9:
				env *= (1.0 - k) * 10.0
			buf[start + s] += y * vol * env
	if reverb > 0.0:
		_room(buf, reverb)
	# Soft saturation keeps loud stacks round instead of clipping.
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(tanh(buf[i] * 1.2) * 26000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


## Small, dark room: a few damped echoes that soften every sound's tail.
func _room(buf: PackedFloat32Array, mix: float) -> void:
	var taps := [[0.023, 0.5], [0.037, 0.4], [0.051, 0.32], [0.071, 0.25], [0.097, 0.18]]
	var src := buf.duplicate()
	var smooth := 0.0
	for i in buf.size():
		var wet := 0.0
		for tap in taps:
			var j := i - int(float(tap[0]) * RATE)
			if j >= 0:
				wet += buf[j] * float(tap[1])
		smooth += 0.35 * (wet - smooth)
		buf[i] = src[i] + smooth * mix


func play(sound: String, pitch := 1.0) -> void:
	if not Save.data["sound"] or not sounds.has(sound):
		return
	var p: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	var s = sounds[sound]
	p.stream = s.pick_random() if s is Array else s
	p.pitch_scale = pitch
	p.volume_db = -4.0 + float(TRIM.get(sound, 0.0))
	p.play()


## Rising marimba notes for a clear; the start note climbs with the combo streak.
func clear_chord(lines: int, streak: int, fever := false) -> void:
	var start := clampi(streak - 1, 0, 5)
	for i in lines + 1:
		var idx := mini(start + i, SCALE.size() - 1)
		if i == 0:
			play("note%d" % idx)
		else:
			play_later("note%d" % idx, i * 0.07)
	if fever:
		# Fever adds a bright top layer an octave above the chord.
		play_later("note%d" % mini(start + lines + 3, SCALE.size() - 1), (lines + 1) * 0.07, 2.0)


## Minor: taps, picking up, dragging, placing. Major: clears, combos, bombs, fever, game over.
## Each has its own switch in Settings. amplitude is 0..1 (-1 = device default).
func vibrate(ms: int, major := false, amplitude := -1.0) -> void:
	var key := "haptics_major" if major else "haptics_minor"
	if Save.data.get(key, true):
		Input.vibrate_handheld(ms, amplitude)


func play_later(sound: String, delay: float, pitch := 1.0) -> void:
	get_tree().create_timer(delay).timeout.connect(play.bind(sound, pitch))
