class_name PresetsWeather
extends PresetsHelpers

# Weather, water and fire — mostly sustained beds and long gestures.
# Noise colour does most of the work: pink for body and roar, white
# through a resonant bandpass for whistles and fizz, and irregular click
# trains (detuned sub-audio squares) for drops, pops and crackles.


static func preset_rain() -> Dictionary:
	var hiss: Dictionary = _layer({"mode": NSE, "length": 2.0, "volume": 0.70, "level": 0.75},
		[_env(0.15, 0.0, 1.0, 0.2), _filt(LP, _rand(5000.0, 7000.0), 0.1)])
	var patter: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 0.80, "level": 0.45},
		[_env(0.15, 0.0, 1.0, 0.2), _filt(LP, 800.0, 0.2)])
	# Individual drops landing near the listener.
	var drops: Dictionary = _layer({"mode": SQR, "pitch": _rand(35.0, 45.0), "voice": 4, "detune": 0.2, "length": 2.0, "volume": 1.00, "level": 0.45},
		[_env(0.15, 0.0, 1.0, 0.2), _vib(0.5, 1.3), _filt(BP, _rand(3000.0, 4000.0), 0.4)])
	var big_drops: Dictionary = _layer({"mode": SQR, "pitch": _rand(7.0, 9.0), "voice": 4, "detune": 0.2, "length": 2.0, "volume": 1.00, "level": 0.37},
		[_env(0.15, 0.0, 1.0, 0.2), _vib(0.5, 0.7), _filt(BP, 1500.0, 0.6)])
	return _sound([hiss, patter, drops, big_drops], 0.12, 0.4)


static func preset_thunder() -> Dictionary:
	# Close strike: a tearing crack, the main boom, then a long roll.
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.35, "volume": 1.00, "level": 0.43},
		[_env(0.0, 0.8, 0.0, 0.0), _filt(HP, 900.0, 0.2), _drive(0.7), _pulses(_rand(25.0, 30.0), 0.8)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(36.0, 44.0), "length": 0.8, "volume": 1.00, "level": 0.43},
		[_bend(0.6, 0.0, 0.3), _drive(0.6)])
	var roll: Dictionary = _layer({"mode": PNK, "length": _rand(2.4, 2.8), "volume": 1.00, "level": 0.43},
		[_env(0.02, 0.98, 0.0, 0.0), _filt(LP, 220.0, 0.2, 0.5, 0.0, 0.3), _trem(0.5, _rand(1.1, 1.6))])
	var rumble: Dictionary = _layer({"mode": BRN, "length": 2.4, "volume": 0.50, "level": 0.34},
		[_env(0.1, 0.9, 0.0, 0.0), _filt(BP, 70.0, 0.2), _trem(0.4, 0.7, TRI)])
	return _sound([crack, boom, roll, rumble], 0.35, 0.7)


static func preset_wind() -> Dictionary:
	# Gusting wind: a resonant band that sweeps up and down, a thin
	# whistle, and a low buffeting rumble.
	var gust: Dictionary = _layer({"mode": PNK, "length": 2.5, "volume": 1.00, "level": 1.00},
		[_env(0.25, 0.0, 1.0, 0.3), _filt(BP, _rand(400.0, 550.0), 0.7, 0.6, 0.5, 0.5), _trem(0.5, _rand(0.3, 0.5))])
	var whistle: Dictionary = _layer({"mode": NSE, "length": 2.5, "volume": 0.60, "level": 0.58},
		[_env(0.3, 0.0, 1.0, 0.3), _filt(BP, _rand(1100.0, 1400.0), 0.88, 0.3, 0.6, 0.4), _trem(0.7, _rand(0.22, 0.32), TRI)])
	var rumble: Dictionary = _layer({"mode": PNK, "length": 2.5, "volume": 0.80, "level": 0.70},
		[_env(0.25, 0.0, 1.0, 0.3), _filt(LP, 250.0, 0.2), _trem(0.4, 0.6)])
	return _sound([gust, whistle, rumble], 0.12, 0.45)


static func preset_waves() -> Dictionary:
	# One ocean wave: the swell building, breaking, then the foam
	# fizzing as it drains back.
	var swell: Dictionary = _layer({"mode": PNK, "length": 2.5, "volume": 1.00, "level": 0.77},
		[_env(0.4, 0.6, 0.0, 0.0), _filt(LP, 400.0, 0.2, 0.5, 0.4, 0.6)])
	var crash: Dictionary = _layer({"mode": NSE, "length": 2.5, "volume": 0.80, "level": 0.54},
		[_env(0.35, 0.65, 0.0, 0.0), _filt(LP, 1500.0, 0.1, 0.5, 0.4, 0.6)])
	var foam: Dictionary = _layer({"mode": SQR, "pitch": 60.0, "voice": 4, "detune": 0.2, "length": 2.5, "volume": 1.00, "level": 0.39},
		[_env(0.45, 0.55, 0.0, 0.0), _vib(0.5, 2.0), _filt(BP, 5000.0, 0.3)])
	var drain: Dictionary = _layer({"mode": NSE, "length": 2.5, "volume": 0.60, "level": 0.31},
		[_env(0.5, 0.5, 0.0, 0.0), _filt(HP, 3000.0, 0.1)])
	return _sound([swell, crash, foam, drain], 0.18, 0.5)


static func preset_stream() -> Dictionary:
	# Babbling brook: two bubbling voices whose pitch hops around (arp)
	# and glides up on every blip (saw vibrato), out of step with each
	# other, over a bed of water noise.
	var r1: float = _rand(12.0, 14.0)
	var r2: float = _rand(16.5, 18.5)
	var babble1: Dictionary = _layer({"mode": SIN, "pitch": _rand(650.0, 800.0), "length": 2.0, "volume": 0.50, "level": 0.46},
		[_env(0.1, 0.0, 1.0, 0.15), _arp(r1, 7, -3, 10), _vib(0.3, r1, SAW), _trem(0.9, r1, SAW, 0.0, 1.0)])
	var babble2: Dictionary = _layer({"mode": SIN, "pitch": _rand(1000.0, 1200.0), "length": 2.0, "volume": 0.40, "level": 0.37},
		[_env(0.1, 0.0, 1.0, 0.15), _arp(r2, -5, 4, 9), _vib(0.25, r2, SAW), _trem(0.9, r2, SAW, 0.0, 1.0)])
	var water: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 0.90, "level": 0.27},
		[_env(0.1, 0.0, 1.0, 0.15), _filt(BP, 1500.0, 0.3), _trem(0.3, 3.0)])
	var trickle: Dictionary = _layer({"mode": SQR, "pitch": 30.0, "voice": 4, "detune": 0.2, "length": 2.0, "volume": 1.00, "level": 0.18},
		[_env(0.1, 0.0, 1.0, 0.15), _vib(0.5, 1.7), _filt(BP, 2500.0, 0.6)])
	return _sound([babble1, babble2, water, trickle], 0.15, 0.4)


static func preset_drip() -> Dictionary:
	# A single drop in a cave: the "plink" is a tiny air cavity ringing
	# and rising in pitch as it collapses.
	var plink: Dictionary = _layer({"mode": SIN, "pitch": _rand(800.0, 1100.0), "length": 0.06, "volume": 0.90, "level": 0.66},
		[_bend(0.45, 1.0, 0.0)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.60, "level": 0.26},
		[_filt(HP, 4000.0, 0.2)])
	var echo: Dictionary = _layer({"mode": SIN, "pitch": _rand(800.0, 1100.0), "length": 0.06, "volume": 0.50, "level": 0.33},
		[_bend(0.45, 1.0, 0.0), _filt(LP, 2000.0, 0.1), _echo(_rand(250.0, 330.0), 0.6, 0.4)])
	return _sound([plink, tick, echo], 0.4, 0.75)


static func preset_splash() -> Dictionary:
	# Something heavy falling into water.
	var impact: Dictionary = _layer({"mode": NSE, "length": _rand(0.35, 0.45), "volume": 1.00, "level": 0.44},
		[_filt(BP, 800.0, 0.2, 0.5, 0.05, 0.6)])
	# The cavity it leaves collapsing: a low "bloop".
	var bloop: Dictionary = _layer({"mode": SIN, "pitch": _rand(170.0, 220.0), "length": 0.15, "volume": 0.90, "level": 0.35},
		[_env(0.1, 0.9, 0.0, 0.0), _bend(0.6, 1.0, 0.0)])
	var droplets: Dictionary = _layer({"mode": SIN, "pitch": _rand(1300.0, 1700.0), "length": 0.03, "volume": 0.60, "level": 0.22},
		[_bend(0.4, 1.0, 0.0), _echo(_rand(70.0, 90.0), 0.8, 0.6)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 70.0, "length": 0.12, "volume": 1.00, "level": 0.31},
		[_bend(0.4, 0.0, 0.3)])
	return _sound([impact, bloop, droplets, thump], 0.2, 0.4)


static func preset_bubbles() -> Dictionary:
	# Underwater bubbles: each pulse is a sine gliding upward as a bubble
	# rises; three streams at unrelated rates.
	var a: Dictionary = _layer({"mode": SIN, "pitch": _rand(350.0, 450.0), "length": 1.5, "volume": 0.70, "level": 0.39},
		[_env(0.0, 0.0, 1.0, 0.3), _vib(0.5, 9.0, SAW), _pulses(9.0)])
	var b: Dictionary = _layer({"mode": SIN, "pitch": _rand(600.0, 700.0), "length": 1.5, "volume": 0.60, "level": 0.31},
		[_env(0.0, 0.0, 1.0, 0.3), _vib(0.45, 13.7, SAW), _pulses(13.7)])
	var c: Dictionary = _layer({"mode": SIN, "pitch": _rand(240.0, 300.0), "length": 1.5, "volume": 0.70, "level": 0.31},
		[_env(0.0, 0.0, 1.0, 0.3), _vib(0.5, 6.1, SAW), _pulses(6.1)])
	var murk: Dictionary = _layer({"mode": PNK, "length": 1.5, "volume": 0.70, "level": 0.19},
		[_env(0.1, 0.0, 1.0, 0.3), _filt(LP, 500.0, 0.3)])
	return _sound([a, b, c, murk], 0.25, 0.5)


static func preset_campfire() -> Dictionary:
	# Crackling wood fire: sparse pops, finer crackle and a soft roar.
	var pops: Dictionary = _layer({"mode": SQR, "pitch": _rand(3.5, 4.5), "voice": 4, "detune": 0.2, "length": 2.0, "volume": 1.00, "level": 0.99},
		[_env(0.1, 0.0, 1.0, 0.2), _vib(0.6, 0.9), _filt(BP, _rand(2200.0, 2800.0), 0.4)])
	var crackle: Dictionary = _layer({"mode": SQR, "pitch": _rand(7.0, 9.0), "voice": 4, "detune": 0.2, "length": 2.0, "volume": 1.00, "level": 0.60},
		[_env(0.1, 0.0, 1.0, 0.2), _vib(0.6, 1.4), _filt(BP, 5000.0, 0.4)])
	var roar: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 1.00, "level": 0.70},
		[_env(0.1, 0.0, 1.0, 0.2), _filt(LP, 500.0, 0.2), _trem(0.4, 0.5)])
	var hiss: Dictionary = _layer({"mode": NSE, "length": 2.0, "volume": 0.50, "level": 0.29},
		[_env(0.1, 0.0, 1.0, 0.2), _filt(BP, 3500.0, 0.2), _trem(0.5, 0.8, TRI)])
	return _sound([pops, crackle, roar, hiss], 0.1, 0.3)


static func preset_ignite() -> Dictionary:
	# Torch or gas burner catching: a whoosh that settles into a roar.
	var whoosh: Dictionary = _layer({"mode": PNK, "length": 1.6, "volume": 1.00, "level": 0.44},
		[_env(0.08, 0.3, 0.5, 0.3), _filt(LP, 300.0, 0.3, 0.7, 0.1, 0.3), _drive(0.4)])
	var flare: Dictionary = _layer({"mode": NSE, "length": 0.5, "volume": 0.80, "level": 0.26},
		[_env(0.2, 0.8, 0.0, 0.0), _filt(BP, 1500.0, 0.3, 0.5, 0.2, 0.8)])
	var flutter: Dictionary = _layer({"mode": PNK, "length": 1.6, "volume": 0.80, "level": 0.26},
		[_env(0.15, 0.2, 0.6, 0.3), _filt(BP, 900.0, 0.3), _trem(0.6, _rand(9.0, 13.0), NSE)])
	var crackle: Dictionary = _layer({"mode": SQR, "pitch": 6.0, "voice": 4, "detune": 0.2, "length": 1.6, "volume": 1.00, "level": 0.18},
		[_env(0.2, 0.2, 0.6, 0.3), _vib(0.6, 1.2), _filt(BP, 3000.0, 0.4)])
	return _sound([whoosh, flare, flutter, crackle], 0.15, 0.4)


static func preset_rustle() -> Dictionary:
	# Brushing through a leafy bush: crisp, irregular and bright.
	var leaves: Dictionary = _layer({"mode": SQR, "pitch": _rand(45.0, 55.0), "voice": 4, "detune": 0.2, "length": _rand(0.7, 0.9), "volume": 1.00, "level": 0.60},
		[_env(0.25, 0.75, 0.0, 0.0), _vib(0.6, 3.3), _filt(BP, 4500.0, 0.2)])
	var brush: Dictionary = _layer({"mode": NSE, "length": 0.8, "volume": 1.00, "level": 1.00},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(BP, 2000.0, 0.2), _trem(0.6, _rand(8.0, 10.0))])
	var twigs: Dictionary = _layer({"mode": SQR, "pitch": 9.0, "voice": 4, "detune": 0.2, "length": 0.8, "volume": 1.00, "level": 0.53},
		[_env(0.3, 0.7, 0.0, 0.0), _vib(0.5, 1.9), _filt(BP, 1800.0, 0.5)])
	return _sound([leaves, brush, twigs], 0.08, 0.3)
