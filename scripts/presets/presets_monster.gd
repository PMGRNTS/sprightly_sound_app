class_name PresetsMonster
extends PresetsHelpers

# Creatures that don't exist. The raw material is a detuned, driven saw
# made rough with noise vibrato (a torn, irregular voice) or chopped by
# a fast saw tremolo (vocal fry), shaped by moving formant filters, and
# backed by breath noise and a sub layer for size.


static func preset_roar() -> Dictionary:
	var throat: Dictionary = _layer({"mode": SAW, "pitch": _rand(80.0, 100.0), "voice": 3, "detune": 0.04, "length": _rand(1.4, 1.8), "volume": 1.00, "level": 0.82},
		[_env(0.1, 0.3, 0.5, 0.4), _bend(0.2, 0.2, 0.8), _vib(0.05, 25.0, NSE), _drive(0.8), _filt(BP, 600.0, 0.4, 0.5, 0.3, 0.7)])
	var upper: Dictionary = _layer({"mode": SAW, "pitch": 90.0, "voice": 2, "detune": 0.03, "length": 1.6, "volume": 0.70, "level": 0.41},
		[_env(0.1, 0.3, 0.5, 0.4), _bend(0.2, 0.2, 0.8), _filt(BP, 1600.0, 0.5, 0.3, 0.3, 0.7)])
	var breath: Dictionary = _layer({"mode": PNK, "length": 1.6, "volume": 1.00, "level": 0.49},
		[_env(0.1, 0.3, 0.5, 0.4), _filt(BP, 800.0, 0.3), _drive(0.5), _trem(0.6, 30.0, SAW)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 50.0, "length": 1.6, "volume": 0.80, "level": 0.49},
		[_env(0.1, 0.3, 0.5, 0.4), _drive(0.4)])
	return _sound([throat, upper, breath, sub], 0.3, 0.6)


static func preset_growl() -> Dictionary:
	# Low, close and threatening: slow swell, heavy vocal fry.
	var fry: float = _rand(22.0, 28.0)
	var voice: Dictionary = _layer({"mode": SAW, "pitch": _rand(50.0, 60.0), "voice": 2, "detune": 0.03, "length": _rand(1.3, 1.7), "volume": 1.0},
		[_env(0.25, 0.2, 0.6, 0.3), _trem(0.7, fry, SAW), _vib(0.04, 20.0, NSE), _filt(LP, 500.0, 0.4, 0.3, 0.4, 0.6)])
	var rasp: Dictionary = _layer({"mode": NSE, "length": 1.5, "volume": 0.8, "level": 0.5},
		[_env(0.25, 0.2, 0.6, 0.3), _filt(BP, 700.0, 0.5), _trem(0.8, fry, SAW)])
	var chest: Dictionary = _layer({"mode": BRN, "length": 1.5, "volume": 0.4, "level": 0.7},
		[_env(0.25, 0.2, 0.6, 0.3), _filt(BP, 150.0, 0.4), _trem(0.6, fry, SAW)])
	return _sound([voice, rasp, chest], 0.15, 0.4)


static func preset_dragon() -> Dictionary:
	# Huge roar with a gout of fire breath underneath.
	var roar: Dictionary = _layer({"mode": SAW, "pitch": _rand(60.0, 75.0), "voice": 3, "detune": 0.05, "length": 1.8, "volume": 1.00, "level": 0.53},
		[_env(0.1, 0.3, 0.5, 0.4), _bend(0.25, 0.15, 0.85), _vib(0.06, 25.0, NSE), _drive(0.9), _filt(BP, 500.0, 0.4, 0.6, 0.2, 0.8)])
	var formant: Dictionary = _layer({"mode": SAW, "pitch": 68.0, "voice": 2, "detune": 0.04, "length": 1.8, "volume": 0.70, "level": 0.27},
		[_env(0.1, 0.3, 0.5, 0.4), _bend(0.25, 0.15, 0.85), _filt(BP, 1300.0, 0.5, 0.4, 0.2, 0.8)])
	var breath: Dictionary = _layer({"mode": PNK, "length": 1.8, "volume": 1.00, "level": 0.37},
		[_env(0.3, 0.2, 0.5, 0.4), _filt(LP, 1000.0, 0.2, 0.4, 0.3, 0.7), _drive(0.6), _trem(0.5, 12.0, NSE)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 38.0, "length": 1.8, "volume": 1.00, "level": 0.32},
		[_env(0.1, 0.3, 0.5, 0.4), _drive(0.5)])
	return _sound([roar, formant, breath, sub], 0.35, 0.65)


static func preset_ghost() -> Dictionary:
	# A hollow "oooOOooo" wail with an unsettling fifth above it.
	var wail: Dictionary = _layer({"mode": SIN, "pitch": _rand(450.0, 550.0), "length": 1.8, "volume": 0.80, "level": 0.44},
		[_env(0.3, 0.2, 0.6, 0.4), _bend(0.25, 0.4, 0.6), _vib(0.05, 4.0), _flange(0.5, 0.3, 0.5, 0.4)])
	var fifth: Dictionary = _layer({"mode": TRI, "pitch": 750.0, "length": 1.8, "volume": 0.50, "level": 0.17},
		[_env(0.4, 0.2, 0.5, 0.4), _bend(0.25, 0.4, 0.6), _vib(0.06, 3.3)])
	var breath: Dictionary = _layer({"mode": NSE, "length": 1.8, "volume": 0.60, "level": 0.17},
		[_env(0.3, 0.2, 0.5, 0.4), _filt(BP, 1200.0, 0.8, 0.4, 0.4, 0.6)])
	return _sound([wail, fifth, breath], 0.45, 0.7)


static func preset_zombie() -> Dictionary:
	# Wet, creaky groan: "uuuhhh" with a gurgle in the throat.
	var groan: Dictionary = _layer({"mode": SAW, "pitch": _rand(75.0, 95.0), "voice": 2, "detune": 0.03, "length": _rand(1.2, 1.5), "volume": 1.00, "level": 1.00},
		[_env(0.2, 0.2, 0.6, 0.3), _vib(0.08, 15.0, NSE), _trem(0.6, 18.0, SAW), _filt(BP, 500.0, 0.5, 0.4, 0.4, 0.6), _bend(0.1, 0.4, 0.6)])
	var gurgle: Dictionary = _layer({"mode": SIN, "pitch": _rand(180.0, 220.0), "length": 1.4, "volume": 0.60, "level": 0.96},
		[_env(0.2, 0.2, 0.6, 0.3), _vib(0.5, 7.0, SAW), _pulses(7.0)])
	var breath: Dictionary = _layer({"mode": PNK, "length": 1.4, "volume": 0.70, "level": 0.96},
		[_env(0.2, 0.2, 0.6, 0.3), _filt(BP, 900.0, 0.4)])
	return _sound([groan, gurgle, breath], 0.2, 0.45)


static func preset_slime() -> Dictionary:
	# Squelching, bubbling ooze.
	var squelch: Dictionary = _layer({"mode": SIN, "pitch": _rand(260.0, 340.0), "length": 0.7, "volume": 0.90, "level": 0.72},
		[_env(0.05, 0.95, 0.0, 0.0), _vib(0.6, 13.0, SAW), _pulses(13.0), _filt(LP, 1200.0, 0.4)])
	var wet: Dictionary = _layer({"mode": NSE, "length": 0.5, "volume": 0.80, "level": 0.43},
		[_filt(BP, 900.0, 0.5, -0.4, 0.0, 1.0), _pulses(9.0, 0.7)])
	var plop: Dictionary = _layer({"mode": SIN, "pitch": _rand(110.0, 130.0), "length": 0.15, "volume": 0.90, "level": 0.50},
		[_bend(0.5, 1.0, 0.0)])
	return _sound([squelch, wet, plop], 0.15, 0.35)


static func preset_goblin() -> Dictionary:
	# Nasty little cackle: "heh-heh-heh-heh", falling.
	var rate: float = _rand(6.5, 8.0)
	var cackle: Dictionary = _layer({"mode": SAW, "pitch": _rand(360.0, 420.0), "length": 0.6, "volume": 0.80, "level": 0.83},
		[_env(0.0, 0.0, 1.0, 0.2), _pulses(rate), _arp(rate, -2, -4, -6), _vib(0.04, 25.0, NSE), _filt(BP, 1500.0, 0.6)])
	var nasal: Dictionary = _layer({"mode": SAW, "pitch": 390.0, "length": 0.6, "volume": 0.60, "level": 0.42},
		[_env(0.0, 0.0, 1.0, 0.2), _pulses(rate), _arp(rate, -2, -4, -6), _filt(BP, 2800.0, 0.6)])
	var huff: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 0.70, "level": 0.42},
		[_env(0.0, 0.0, 1.0, 0.2), _filt(BP, 2500.0, 0.3), _pulses(rate)])
	return _sound([cackle, nasal, huff], 0.15, 0.35)


static func preset_swarm() -> Dictionary:
	# Bats or insects: dense high chittering over fluttering wings.
	var chitter1: Dictionary = _layer({"mode": SIN, "pitch": _rand(3000.0, 3500.0), "voice": 4, "detune": 0.08, "length": 1.6, "volume": 0.87, "level": 1.00},
		[_env(0.2, 0.0, 1.0, 0.3), _vib(0.2, 23.0, SAW), _pulses(23.0), _chord(12, 0, 0, 0.5)])
	var chitter2: Dictionary = _layer({"mode": SIN, "pitch": _rand(3500.0, 4000.0), "voice": 4, "detune": 0.08, "length": 1.6, "volume": 0.49, "level": 1.00},
		[_env(0.3, 0.0, 1.0, 0.3), _vib(0.2, 29.0, SAW), _pulses(29.0), _chord(12, 0, 0, 0.5)])
	var wings: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.84, "level": 1.00},
		[_env(0.2, 0.0, 1.0, 0.3), _filt(BP, 1500.0, 0.3), _trem(0.7, 30.0), _flange(0.6, 0.7, 0.4, 0.5)])
	return _sound([chitter1, chitter2, wings], 0.25, 0.5)
