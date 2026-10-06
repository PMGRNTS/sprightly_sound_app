class_name PresetsFoley
extends PresetsHelpers

# Everyday foley: footsteps, doors, cloth and small objects. Footsteps are
# heel + toe (an echo ~60 ms behind the heel) over a surface texture.
# Crunchy textures (gravel, snow, splinters) come from a few detuned,
# very low square waves through a bandpass: every edge becomes a click,
# and the detuned voices drift in and out of step, so the clicks land
# irregularly.


static func preset_step_wood() -> Dictionary:
	var toe: float = _rand(55.0, 75.0)
	var heel: Dictionary = _layer({"mode": SIN, "pitch": _rand(110.0, 135.0), "length": 0.06, "volume": 1.00, "level": 0.75},
		[_bend(0.3, 0.0, 0.3), _echo(toe, 0.6)])
	var board: Dictionary = _layer({"mode": NSE, "length": 0.08, "volume": 0.90, "level": 0.60},
		[_filt(BP, _rand(400.0, 520.0), 0.5), _echo(toe, 0.6)])
	var scuff: Dictionary = _layer({"mode": NSE, "length": 0.04, "volume": 0.60, "level": 0.26},
		[_filt(HP, 3000.0, 0.1), _echo(toe, 0.6)])
	# Old floorboard squeaking under the weight.
	var squeak: Dictionary = _layer({"mode": SAW, "pitch": _rand(330.0, 420.0), "length": 0.16, "volume": 0.50, "level": 0.15},
		[_env(0.3, 0.7, 0.0, 0.0), _vib(0.06, 9.0), _filt(BP, 1200.0, 0.7)])
	return _sound([heel, board, scuff, squeak], 0.12, 0.25)


static func preset_step_gravel() -> Dictionary:
	var toe: float = _rand(60.0, 85.0)
	var crunch: Dictionary = _layer({"mode": SQR, "pitch": _rand(26.0, 34.0), "voice": 4, "detune": 0.2, "length": 0.2, "volume": 1.0},
		[_env(0.08, 0.92, 0.0, 0.0), _vib(0.6, 2.3), _filt(BP, 3000.0, 0.2), _echo(toe, 0.7)])
	var grind: Dictionary = _layer({"mode": NSE, "length": 0.16, "volume": 0.7, "level": 0.6},
		[_env(0.1, 0.9, 0.0, 0.0), _filt(BP, 1800.0, 0.2), _pulses(_rand(24.0, 30.0), 0.7), _echo(toe, 0.7)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 90.0, "length": 0.05, "volume": 0.8, "level": 0.6},
		[_bend(0.3, 0.0, 0.4)])
	return _sound([crunch, grind, thump], 0.06, 0.2)


static func preset_step_grate() -> Dictionary:
	# Boot on a steel grate: thump, a hollow ring and a loose rattle.
	var toe: float = _rand(55.0, 70.0)
	var thump: Dictionary = _layer({"mode": SIN, "pitch": _rand(95.0, 115.0), "length": 0.07, "volume": 1.00, "level": 0.65},
		[_bend(0.3, 0.0, 0.3), _echo(toe, 0.55)])
	var ring: Dictionary = _layer({"mode": SIN, "pitch": _rand(480.0, 560.0), "voice": 2, "detune": 0.01, "length": 0.4, "volume": 0.60, "level": 0.39},
		[_chord(6, 13, 19, 0.6), _echo(toe, 0.55)])
	var rattle: Dictionary = _layer({"mode": NSE, "length": 0.14, "volume": 0.80, "level": 0.32},
		[_filt(BP, 2500.0, 0.4), _pulses(_rand(25.0, 30.0))])
	var clank: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.90, "level": 0.32},
		[_filt(BP, 3500.0, 0.6), _echo(toe, 0.55)])
	return _sound([thump, ring, rattle, clank], 0.2, 0.4)


static func preset_step_snow() -> Dictionary:
	# Packed snow squeaks and crunches as it compresses.
	var crunch: Dictionary = _layer({"mode": NSE, "length": _rand(0.2, 0.26), "volume": 1.00, "level": 1.00},
		[_env(0.15, 0.85, 0.0, 0.0), _filt(LP, 1800.0, 0.3), _pulses(_rand(22.0, 28.0), 0.7)])
	var squeak: Dictionary = _layer({"mode": SQR, "pitch": _rand(36.0, 44.0), "voice": 4, "detune": 0.2, "length": 0.22, "volume": 1.00, "level": 0.69},
		[_env(0.15, 0.85, 0.0, 0.0), _vib(0.5, 3.1), _filt(BP, 1200.0, 0.5)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 80.0, "length": 0.08, "volume": 0.60, "level": 0.57},
		[_bend(0.2, 0.0, 0.5)])
	return _sound([crunch, squeak, thump], 0.04, 0.2)


static func preset_puddle() -> Dictionary:
	var splash: Dictionary = _layer({"mode": NSE, "length": _rand(0.2, 0.26), "volume": 0.90, "level": 0.83},
		[_filt(BP, _rand(1300.0, 1700.0), 0.3, 0.3, 0.1, 0.9)])
	var slap: Dictionary = _layer({"mode": SIN, "pitch": 150.0, "length": 0.05, "volume": 0.80, "level": 0.50},
		[_bend(0.4, 0.0, 0.3)])
	# Droplets: short upward "plips", scattered by the delay.
	var drops: Dictionary = _layer({"mode": SIN, "pitch": _rand(1200.0, 1600.0), "length": 0.035, "volume": 0.60, "level": 0.42},
		[_bend(0.4, 1.0, 0.0), _echo(_rand(60.0, 80.0), 0.7, 0.5)])
	var drops2: Dictionary = _layer({"mode": SIN, "pitch": _rand(1900.0, 2400.0), "length": 0.03, "volume": 0.50, "level": 0.33},
		[_bend(0.4, 1.0, 0.0), _echo(_rand(95.0, 120.0), 0.7, 0.45)])
	return _sound([splash, slap, drops, drops2], 0.1, 0.25)


static func preset_creak() -> Dictionary:
	# Stick-slip friction: a slow pulse train exciting the door's
	# resonances. The pulse rate wanders as the hinge drags.
	var hinge: Dictionary = _layer({"mode": SAW, "pitch": _rand(24.0, 32.0), "length": _rand(1.0, 1.4), "volume": 0.90, "level": 0.70},
		[_env(0.1, 0.3, 0.6, 0.3), _vib(0.35, _rand(1.2, 1.8)), _bend(0.3, 1.0, 0.0), _filt(BP, _rand(800.0, 1000.0), 0.85)])
	var groan: Dictionary = _layer({"mode": SAW, "pitch": _rand(38.0, 46.0), "length": 1.2, "volume": 0.70, "level": 0.42},
		[_env(0.15, 0.3, 0.5, 0.3), _vib(0.25, 0.9), _filt(BP, 1700.0, 0.8)])
	var body: Dictionary = _layer({"mode": SAW, "pitch": 30.0, "length": 1.2, "volume": 0.60, "level": 0.28},
		[_env(0.1, 0.3, 0.6, 0.3), _vib(0.3, 1.5), _filt(BP, 300.0, 0.7)])
	return _sound([hinge, groan, body], 0.2, 0.45)


static func preset_slam() -> Dictionary:
	var thud: Dictionary = _layer({"mode": SIN, "pitch": _rand(62.0, 75.0), "length": 0.25, "volume": 1.00, "level": 0.46},
		[_bend(0.5, 0.0, 0.2), _drive(0.5)])
	var panel: Dictionary = _layer({"mode": NSE, "length": 0.2, "volume": 1.00, "level": 0.37},
		[_filt(BP, _rand(260.0, 340.0), 0.4)])
	var latch: Dictionary = _layer({"mode": NSE, "length": 0.02, "volume": 0.90, "level": 0.27},
		[_filt(BP, 3000.0, 0.6), _echo(25.0, 0.7)])
	# The frame and hinges rattling after the hit.
	var rattle: Dictionary = _layer({"mode": NSE, "length": 0.2, "volume": 0.60, "level": 0.16},
		[_filt(BP, 1200.0, 0.4), _pulses(28.0)])
	return _sound([thud, panel, latch, rattle], 0.35, 0.5)


static func preset_knock() -> Dictionary:
	# Knuckles on a wooden door, two or three times.
	var gap: float = _rand(170.0, 230.0)
	var fb: float = _pick([0.0, 0.7])
	var knuckle: Dictionary = _layer({"mode": SIN, "pitch": _rand(200.0, 240.0), "length": 0.06, "volume": 1.00, "level": 0.72},
		[_bend(0.3, 0.0, 0.3), _echo(gap, 0.66, fb)])
	var wood: Dictionary = _layer({"mode": NSE, "length": 0.04, "volume": 0.80, "level": 0.51},
		[_filt(BP, 1000.0, 0.5), _echo(gap, 0.66, fb)])
	var panel: Dictionary = _layer({"mode": SIN, "pitch": 110.0, "length": 0.1, "volume": 0.70, "level": 0.43},
		[_echo(gap, 0.66, fb)])
	return _sound([knuckle, wood, panel], 0.18, 0.3)


static func preset_latch() -> Dictionary:
	# Key in, tumblers clicking, then the bolt clacking open at 0.3 s.
	var key: Dictionary = _layer({"mode": NSE, "length": 0.15, "volume": 0.60, "level": 0.48},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(BP, 4000.0, 0.5)])
	var tumblers: Dictionary = _layer({"mode": NSE, "length": 0.2, "volume": 0.80, "level": 0.48},
		[_filt(BP, 3000.0, 0.7), _pulses(_rand(14.0, 18.0))])
	var bolt: Dictionary = _layer({"mode": NSE, "length": 1.2, "volume": 1.00, "level": 0.94},
		[_at(0.3, 1.2, 0.05), _filt(BP, _rand(1300.0, 1700.0), 0.5), _drive(0.5)])
	var thunk: Dictionary = _layer({"mode": SIN, "pitch": 300.0, "length": 1.2, "volume": 0.80, "level": 0.48},
		[_at(0.3, 1.2, 0.04)])
	return _sound([key, tumblers, bolt, thunk], 0.12, 0.25)


static func preset_zipper() -> Dictionary:
	# Teeth clicking past the slider: a buzz whose rate speeds up.
	var teeth: Dictionary = _layer({"mode": SQR, "pitch": _rand(150.0, 200.0), "length": _rand(0.4, 0.55), "volume": 0.80, "level": 0.49},
		[_env(0.08, 0.2, 0.7, 0.2), _bend(0.35, 1.0, 0.0), _filt(HP, 2500.0, 0.3), _vib(0.1, 7.0, NSE)])
	var hiss: Dictionary = _layer({"mode": NSE, "length": 0.5, "volume": 0.60, "level": 0.24},
		[_env(0.08, 0.2, 0.7, 0.2), _filt(BP, 5000.0, 0.3)])
	var fabric: Dictionary = _layer({"mode": PNK, "length": 0.5, "volume": 0.60, "level": 0.20},
		[_env(0.1, 0.2, 0.6, 0.2), _filt(BP, 1200.0, 0.2), _trem(0.6, 11.0)])
	return _sound([teeth, hiss, fabric], 0.05, 0.2)


static func preset_cloth() -> Dictionary:
	# Jacket rustle: two noise bands with uneven, fluttering levels.
	var rustle: Dictionary = _layer({"mode": PNK, "length": _rand(0.45, 0.6), "volume": 0.90, "level": 0.79},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(BP, _rand(2200.0, 2800.0), 0.2), _trem(0.6, _rand(11.0, 15.0))])
	var swish: Dictionary = _layer({"mode": NSE, "length": 0.5, "volume": 0.70, "level": 0.39},
		[_env(0.35, 0.65, 0.0, 0.0), _filt(HP, 4000.0, 0.1), _trem(0.7, _rand(6.5, 8.5), TRI)])
	var body: Dictionary = _layer({"mode": PNK, "length": 0.4, "volume": 0.60, "level": 0.31},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(LP, 600.0, 0.2)])
	return _sound([rustle, swish, body], 0.05, 0.2)


static func preset_page() -> Dictionary:
	# Page lifted and flipped, landing with a soft slap at 0.3 s.
	var flutter: Dictionary = _layer({"mode": NSE, "length": 0.32, "volume": 0.80, "level": 0.75},
		[_env(0.5, 0.5, 0.0, 0.0), _filt(BP, _rand(2600.0, 3400.0), 0.3), _pulses(_rand(22.0, 28.0), 0.5)])
	var air: Dictionary = _layer({"mode": PNK, "length": 0.32, "volume": 0.70, "level": 0.38},
		[_env(0.5, 0.5, 0.0, 0.0), _filt(LP, 1500.0, 0.2)])
	var land: Dictionary = _layer({"mode": NSE, "length": 1.2, "volume": 0.90, "level": 0.52},
		[_at(0.3, 1.2, 0.04), _filt(HP, 2500.0, 0.1)])
	return _sound([flutter, air, land], 0.06, 0.2)


static func preset_keys() -> Dictionary:
	# A bunch of keys shaken: small steel rings, re-struck in time with
	# the shake.
	var shake: float = _rand(8.0, 11.0)
	var a: Dictionary = _layer({"mode": SIN, "pitch": _rand(3600.0, 4000.0), "length": 1.4, "volume": 0.60, "level": 0.48},
		[_env(0.0, 0.45, 0.0, 0.0), _chord(6, 11, 17, 0.6), _pulses(shake)])
	var b: Dictionary = _layer({"mode": SIN, "pitch": _rand(2600.0, 2900.0), "length": 1.4, "volume": 0.50, "level": 0.38},
		[_env(0.0, 0.45, 0.0, 0.0), _chord(12, 17, 24, 0.6), _pulses(shake * 2.0, 0.8)])
	var c: Dictionary = _layer({"mode": SIN, "pitch": _rand(2900.0, 3300.0), "length": 1.4, "volume": 0.50, "level": 0.33},
		[_env(0.0, 0.45, 0.0, 0.0), _chord(7, 10, 16, 0.5), _pulses(shake)])
	var clatter: Dictionary = _layer({"mode": NSE, "length": 1.4, "volume": 0.60, "level": 0.23},
		[_env(0.0, 0.45, 0.0, 0.0), _filt(HP, 4500.0, 0.3), _pulses(shake * 2.0)])
	return _sound([a, b, c, clatter], 0.1, 0.25)


static func preset_bodyfall() -> Dictionary:
	var thud: Dictionary = _layer({"mode": SIN, "pitch": _rand(55.0, 65.0), "length": 0.3, "volume": 1.00, "level": 0.47},
		[_bend(0.5, 0.0, 0.25), _drive(0.5), _echo(_rand(80.0, 110.0), 0.5)])
	var weight: Dictionary = _layer({"mode": PNK, "length": 0.3, "volume": 1.00, "level": 0.38},
		[_filt(LP, 400.0, 0.2, 0.4, 0.0, 0.3)])
	var cloth: Dictionary = _layer({"mode": NSE, "length": 0.08, "volume": 0.80, "level": 0.24},
		[_filt(BP, 1500.0, 0.2), _echo(95.0, 0.5)])
	# Gear and limbs settling a beat later.
	var settle: Dictionary = _layer({"mode": NSE, "length": 1.0, "volume": 0.70, "level": 0.19},
		[_at(0.22, 1.0, 0.12), _filt(BP, 900.0, 0.3)])
	return _sound([thud, weight, cloth, settle], 0.15, 0.35)


static func preset_clink() -> Dictionary:
	# Two wine glasses touching: thin, long, slightly beating rings.
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.01, "volume": 0.70, "level": 0.33},
		[_filt(HP, 5000.0, 0.2)])
	var glass1: Dictionary = _layer({"mode": SIN, "pitch": _rand(2300.0, 2500.0), "voice": 2, "detune": 0.004, "length": 1.4, "volume": 0.60, "level": 0.67},
		[_chord(17, 21, 0, 0.4)])
	var glass2: Dictionary = _layer({"mode": SIN, "pitch": _rand(2600.0, 2800.0), "voice": 2, "detune": 0.003, "length": 1.1, "volume": 0.50, "level": 0.53},
		[_chord(16, 22, 0, 0.4)])
	return _sound([tick, glass1, glass2], 0.15, 0.35)
