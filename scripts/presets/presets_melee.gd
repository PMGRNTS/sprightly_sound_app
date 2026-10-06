class_name PresetsMelee
extends PresetsHelpers

# Blades, blunt hits and bows. Whooshes are bandpassed noise whose filter
# and level swell and fall together, the way air noise peaks as a blade
# passes the ear. Metal rings use chord-stacked sines at inharmonic
# intervals so they sound struck rather than played.


static func preset_swing() -> Dictionary:
	var air: Dictionary = _layer({"mode": NSE, "length": _rand(0.28, 0.36), "volume": 1.00, "level": 1.00},
		[_env(0.45, 0.55, 0.0, 0.0), _filt(BP, _rand(420.0, 560.0), 0.45, 0.55, 0.45, 0.55)])
	# The blade's edge whistling.
	var edge: Dictionary = _layer({"mode": NSE, "length": 0.32, "volume": 0.70, "level": 0.66},
		[_env(0.5, 0.5, 0.0, 0.0), _filt(BP, 2400.0, 0.7, 0.3, 0.5, 0.5)])
	var hum: Dictionary = _layer({"mode": TRI, "pitch": _rand(160.0, 200.0), "length": 0.32, "volume": 0.50, "level": 0.46},
		[_env(0.45, 0.55, 0.0, 0.0), _bend(0.25, 0.45, 0.55)])
	return _sound([air, edge, hum], 0.08, 0.25)


static func preset_slash() -> Dictionary:
	var whoosh: Dictionary = _layer({"mode": NSE, "length": 0.2, "volume": 0.90, "level": 0.47},
		[_env(0.6, 0.4, 0.0, 0.0), _filt(BP, 700.0, 0.45, 0.6, 0.6, 0.4)])
	# The cut lands at 0.13 s, as the whoosh peaks.
	var cut: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 1.00, "level": 0.59},
		[_at(0.13, 0.6, 0.1), _filt(BP, _rand(1500.0, 2100.0), 0.3), _drive(0.4)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": _rand(100.0, 125.0), "length": 0.6, "volume": 1.00, "level": 0.47},
		[_at(0.13, 0.6, 0.09), _bend(0.3, 0.2, 0.2)])
	var tear: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 0.80, "level": 0.29},
		[_at(0.13, 0.6, 0.13), _filt(HP, 2800.0, 0.2)])
	return _sound([whoosh, cut, thump, tear], 0.1, 0.3)


static func preset_clash() -> Dictionary:
	# Two steel blades: an impact crack plus two inharmonic, slightly
	# beating rings. Upper partials (chord copies) die first.
	var hit: Dictionary = _layer({"mode": NSE, "length": 0.04, "volume": 1.00, "level": 0.41},
		[_filt(HP, 2000.0, 0.2), _drive(0.5)])
	var ring1: Dictionary = _layer({"mode": SIN, "pitch": _rand(1750.0, 1950.0), "voice": 2, "detune": 0.008, "length": 1.2, "volume": 0.60, "level": 0.51},
		[_chord(7, 16, 23, 0.6)])
	var ring2: Dictionary = _layer({"mode": SIN, "pitch": _rand(2850.0, 3100.0), "length": 0.9, "volume": 0.50, "level": 0.36},
		[_chord(5, 14, 20, 0.5)])
	# Blades grinding apart.
	var scrape: Dictionary = _layer({"mode": NSE, "length": 0.15, "volume": 0.70, "level": 0.23},
		[_filt(BP, 5000.0, 0.6, -0.3, 0.0, 1.0)])
	return _sound([hit, ring1, ring2, scrape], 0.25, 0.5)


static func preset_draw() -> Dictionary:
	# Steel scraping out of the scabbard, rising, then ringing free.
	var scrape: Dictionary = _layer({"mode": NSE, "length": _rand(0.32, 0.38), "volume": 0.8},
		[_env(0.6, 0.4, 0.0, 0.0), _filt(BP, 3000.0, 0.7, 0.35, 0.85, 0.15)])
	var grind: Dictionary = _layer({"mode": SAW, "pitch": _rand(220.0, 260.0), "length": 0.35, "volume": 0.4, "level": 0.3},
		[_env(0.6, 0.4, 0.0, 0.0), _vib(0.04, 23.0, NSE), _filt(BP, 2500.0, 0.6), _bend(0.4, 1.0, 0.0)])
	var ring: Dictionary = _layer({"mode": SIN, "pitch": _rand(2500.0, 2800.0), "voice": 2, "detune": 0.006, "length": 1.5, "volume": 0.6, "level": 0.7},
		[_at(0.35, 1.5, 0.33), _chord(7, 15, 22, 0.5)])
	return _sound([scrape, grind, ring], 0.25, 0.45)


static func preset_punch() -> Dictionary:
	var thud: Dictionary = _layer({"mode": SIN, "pitch": _rand(80.0, 100.0), "length": 0.15, "volume": 1.00, "level": 0.45},
		[_bend(0.5, 0.0, 0.3), _drive(0.4)])
	var slap: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 0.90, "level": 0.31},
		[_filt(BP, _rand(1000.0, 1400.0), 0.2)])
	var body: Dictionary = _layer({"mode": PNK, "length": 0.12, "volume": 1.00, "level": 0.31},
		[_filt(LP, 500.0, 0.2, 0.5, 0.0, 0.3)])
	# Clothing and knuckles crunching on contact.
	var crunch: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 0.60, "level": 0.16},
		[_filt(HP, 3000.0, 0.1)])
	return _sound([thud, slap, body, crunch], 0.06, 0.2)


static func preset_bowshot() -> Dictionary:
	# Bowstring release: a low, damped "thwum" with a wobble.
	var bowstring: Dictionary = _layer({"mode": SAW, "pitch": _rand(85.0, 105.0), "length": 0.35, "volume": 0.80, "level": 0.86},
		[_filt(LP, 900.0, 0.3, -0.4, 0.0, 0.6), _bend(0.15, 0.0, 0.2), _vib(0.04, 14.0)])
	var snap: Dictionary = _layer({"mode": NSE, "length": 0.02, "volume": 0.90, "level": 0.52},
		[_filt(HP, 2000.0, 0.2)])
	# Arrow leaving: air noise falling away.
	var arrow: Dictionary = _layer({"mode": NSE, "length": 0.4, "volume": 0.70, "level": 0.47},
		[_env(0.1, 0.9, 0.0, 0.0), _filt(BP, 1800.0, 0.5, -0.4, 0.0, 1.0)])
	return _sound([bowstring, snap, arrow], 0.1, 0.3)


static func preset_arrow_hit() -> Dictionary:
	var thunk: Dictionary = _layer({"mode": SIN, "pitch": _rand(150.0, 175.0), "length": 0.08, "volume": 1.00, "level": 0.73},
		[_bend(0.4, 0.0, 0.2)])
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 0.90, "level": 0.59},
		[_filt(BP, 900.0, 0.3), _drive(0.3)])
	# The shaft left quivering in the target.
	var quiver: Dictionary = _layer({"mode": SAW, "pitch": _rand(50.0, 60.0), "length": 0.6, "volume": 0.60, "level": 0.37},
		[_trem(0.8, _rand(20.0, 24.0)), _filt(LP, 900.0, 0.3)])
	return _sound([thunk, crack, quiver], 0.1, 0.3)


static func preset_block() -> Dictionary:
	# Wooden shield with an iron rim taking a hit.
	var thud: Dictionary = _layer({"mode": SIN, "pitch": _rand(110.0, 130.0), "length": 0.15, "volume": 1.00, "level": 0.46},
		[_bend(0.4, 0.0, 0.3), _drive(0.4)])
	var wood: Dictionary = _layer({"mode": NSE, "length": 0.1, "volume": 0.90, "level": 0.37},
		[_filt(BP, _rand(550.0, 700.0), 0.5)])
	var hit: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.90, "level": 0.28},
		[_filt(HP, 1500.0, 0.2)])
	var rim: Dictionary = _layer({"mode": SIN, "pitch": _rand(1250.0, 1450.0), "length": 0.5, "volume": 0.50, "level": 0.18},
		[_chord(5, 14, 21, 0.5)])
	return _sound([thud, wood, hit, rim], 0.12, 0.3)


static func preset_chop() -> Dictionary:
	# Axe biting into a log.
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.06, "volume": 1.00, "level": 0.57},
		[_filt(BP, _rand(1600.0, 2000.0), 0.3), _drive(0.5)])
	var thunk: Dictionary = _layer({"mode": SIN, "pitch": _rand(130.0, 150.0), "length": 0.12, "volume": 1.00, "level": 0.52},
		[_bend(0.4, 0.0, 0.25)])
	# Short hollow ring of the log itself.
	var log_ring: Dictionary = _layer({"mode": TRI, "pitch": _rand(320.0, 380.0), "length": 0.2, "volume": 0.60, "level": 0.29},
		[_chord(7, 12, 19, 0.4), _filt(LP, 1500.0, 0.2)])
	var splinter: Dictionary = _layer({"mode": NSE, "length": 0.1, "volume": 0.70, "level": 0.26},
		[_filt(HP, 3000.0, 0.2), _pulses(28.0)])
	return _sound([crack, thunk, log_ring, splinter], 0.12, 0.35)


static func preset_whip() -> Dictionary:
	# The lash swells through the air, then the tip breaks the sound
	# barrier with a sharp crack at ~0.2 s.
	var air: Dictionary = _layer({"mode": NSE, "length": 0.22, "volume": 0.80, "level": 0.27},
		[_env(0.9, 0.1, 0.0, 0.0), _filt(BP, 600.0, 0.4, 0.5, 0.9, 0.1)])
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.9, "volume": 1.00, "level": 0.45},
		[_at(0.2, 0.9, 0.025), _filt(HP, _rand(1400.0, 1800.0), 0.1), _drive(0.9)])
	var pop: Dictionary = _layer({"mode": SIN, "pitch": 180.0, "length": 0.9, "volume": 0.80, "level": 0.22},
		[_at(0.2, 0.9, 0.03), _drive(0.5)])
	return _sound([air, crack, pop], 0.2, 0.4)
