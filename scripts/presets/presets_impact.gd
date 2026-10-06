class_name PresetsImpact
extends PresetsHelpers

# Breaks, crashes and collapses. Each one stacks the hit itself, the
# material's ring or body, and the debris that follows — irregular
# clicks (detuned sub-audio squares through a bandpass) tuned to the
# size of the pieces.


static func preset_smash() -> Dictionary:
	# Window shattering.
	var hit: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 1.00, "level": 0.46},
		[_filt(HP, 3000.0, 0.2), _drive(0.6)])
	var pane: Dictionary = _layer({"mode": SIN, "pitch": _rand(1600.0, 2000.0), "length": 0.3, "volume": 0.60, "level": 0.28},
		[_chord(5, 11, 17, 0.6)])
	# Shards: resonant pings at two sizes, scattering over a second.
	var shards: Dictionary = _layer({"mode": SQR, "pitch": _rand(12.0, 16.0), "voice": 4, "detune": 0.2, "length": 1.2, "volume": 1.00, "level": 0.46},
		[_vib(0.5, 1.7), _filt(BP, _rand(4000.0, 4600.0), 0.75)])
	var slivers: Dictionary = _layer({"mode": SQR, "pitch": _rand(18.0, 24.0), "voice": 4, "detune": 0.2, "length": 0.9, "volume": 1.00, "level": 0.37},
		[_vib(0.5, 2.3), _filt(BP, _rand(6500.0, 7500.0), 0.75)])
	return _sound([hit, pane, shards, slivers], 0.2, 0.4)


static func preset_splinter() -> Dictionary:
	# A plank snapping: crack, fibres tearing, the halves groaning.
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.06, "volume": 1.0},
		[_filt(BP, _rand(1000.0, 1400.0), 0.3), _drive(0.7)])
	var fibres: Dictionary = _layer({"mode": SQR, "pitch": _rand(30.0, 40.0), "voice": 4, "detune": 0.2, "length": 0.4, "volume": 1.0, "level": 0.8},
		[_env(0.0, 0.8, 0.0, 0.0), _vib(0.5, 3.0), _filt(BP, 2500.0, 0.3)])
	var groan: Dictionary = _layer({"mode": SAW, "pitch": _rand(60.0, 80.0), "length": 0.3, "volume": 0.6, "level": 0.5},
		[_vib(0.3, 7.0, NSE), _filt(BP, 400.0, 0.5)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 110.0, "length": 0.1, "volume": 0.9, "level": 0.7},
		[_bend(0.4, 0.0, 0.3)])
	return _sound([crack, fibres, groan, thump], 0.15, 0.35)


static func preset_clang() -> Dictionary:
	# Steel pipe struck: inharmonic partials (a free bar's modes sit far
	# from the harmonic series) with a slow beat between them.
	var hit: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 1.00, "level": 0.52},
		[_filt(HP, 1500.0, 0.2)])
	var low: Dictionary = _layer({"mode": SIN, "pitch": _rand(560.0, 680.0), "voice": 2, "detune": 0.005, "length": 2.0, "volume": 0.70, "level": 0.74},
		[_chord(10, 17, 24, 0.6)])
	var high: Dictionary = _layer({"mode": SIN, "pitch": _rand(1900.0, 2200.0), "voice": 2, "detune": 0.004, "length": 1.2, "volume": 0.50, "level": 0.45},
		[_chord(6, 13, 0, 0.5)])
	var thud: Dictionary = _layer({"mode": SIN, "pitch": 140.0, "length": 0.08, "volume": 0.80, "level": 0.45},
		[_bend(0.3, 0.0, 0.3)])
	return _sound([hit, low, high, thud], 0.3, 0.55)


static func preset_crash() -> Dictionary:
	# Heavy metal-on-metal collision: car wreck territory.
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(50.0, 60.0), "length": 0.5, "volume": 1.00, "level": 0.51},
		[_bend(0.6, 0.0, 0.25), _drive(0.7)])
	# Sheet metal crumpling.
	var crumple: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 1.00, "level": 0.46},
		[_env(0.0, 0.7, 0.0, 0.0), _filt(BP, 1400.0, 0.3), _drive(0.6), _pulses(_rand(22.0, 28.0), 0.8)])
	var clang: Dictionary = _layer({"mode": SIN, "pitch": _rand(340.0, 420.0), "voice": 2, "detune": 0.01, "length": 1.4, "volume": 0.60, "level": 0.30},
		[_chord(7, 17, 22, 0.6)])
	var glass: Dictionary = _layer({"mode": SQR, "pitch": 14.0, "voice": 4, "detune": 0.2, "length": 1.0, "volume": 1.00, "level": 0.30},
		[_vib(0.5, 1.9), _filt(BP, 5500.0, 0.7)])
	return _sound([boom, crumple, clang, glass], 0.3, 0.55)


static func preset_rubble() -> Dictionary:
	# Rockfall / collapsing masonry.
	var rumble: Dictionary = _layer({"mode": PNK, "length": _rand(1.4, 1.8), "volume": 1.00, "level": 0.42},
		[_env(0.05, 0.95, 0.0, 0.0), _filt(LP, 300.0, 0.2)])
	var rocks: Dictionary = _layer({"mode": SQR, "pitch": _rand(8.0, 10.0), "voice": 4, "detune": 0.2, "length": 1.4, "volume": 1.00, "level": 0.42},
		[_env(0.02, 0.98, 0.0, 0.0), _vib(0.5, 1.1), _filt(BP, 900.0, 0.3)])
	var stones: Dictionary = _layer({"mode": SQR, "pitch": _rand(15.0, 18.0), "voice": 4, "detune": 0.2, "length": 1.6, "volume": 1.00, "level": 0.30},
		[_env(0.1, 0.9, 0.0, 0.0), _vib(0.5, 1.6), _filt(BP, 2200.0, 0.3)])
	var thud: Dictionary = _layer({"mode": SIN, "pitch": 58.0, "length": 0.35, "volume": 1.00, "level": 0.42},
		[_bend(0.4, 0.0, 0.3), _drive(0.4)])
	return _sound([rumble, rocks, stones, thud], 0.25, 0.6)


static func preset_plate() -> Dictionary:
	# Ceramic plate hitting the floor and breaking.
	var hit: Dictionary = _layer({"mode": NSE, "length": 0.04, "volume": 1.00, "level": 0.40},
		[_filt(HP, 2200.0, 0.2), _drive(0.5)])
	# Ceramic is damped: a short, bright ring.
	var ring: Dictionary = _layer({"mode": SIN, "pitch": _rand(1900.0, 2300.0), "length": 0.25, "volume": 0.70, "level": 0.28},
		[_chord(5, 9, 14, 0.6)])
	var shards: Dictionary = _layer({"mode": SQR, "pitch": _rand(16.0, 20.0), "voice": 4, "detune": 0.2, "length": 0.6, "volume": 1.00, "level": 0.36},
		[_vib(0.5, 2.1), _filt(BP, 3500.0, 0.5)])
	var thud: Dictionary = _layer({"mode": SIN, "pitch": 170.0, "length": 0.06, "volume": 0.80, "level": 0.24},
		[_bend(0.3, 0.0, 0.3)])
	return _sound([hit, ring, shards, thud], 0.15, 0.35)


static func preset_box_drop() -> Dictionary:
	# Cardboard box landing, its contents shifting inside.
	var thud: Dictionary = _layer({"mode": SIN, "pitch": _rand(85.0, 105.0), "length": 0.12, "volume": 1.00, "level": 0.64},
		[_bend(0.4, 0.0, 0.3)])
	var hollow: Dictionary = _layer({"mode": NSE, "length": 0.15, "volume": 1.00, "level": 0.51},
		[_filt(BP, _rand(220.0, 280.0), 0.6)])
	var flap: Dictionary = _layer({"mode": NSE, "length": 0.06, "volume": 0.80, "level": 0.32},
		[_filt(BP, 1500.0, 0.2)])
	var contents: Dictionary = _layer({"mode": SQR, "pitch": 40.0, "voice": 4, "detune": 0.2, "length": 0.25, "volume": 1.00, "level": 0.38},
		[_env(0.05, 0.95, 0.0, 0.0), _vib(0.5, 4.0), _filt(BP, 1800.0, 0.4)])
	return _sound([thud, hollow, flap, contents], 0.12, 0.3)
