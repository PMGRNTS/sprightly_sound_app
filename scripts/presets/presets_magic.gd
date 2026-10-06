class_name PresetsMagic
extends PresetsHelpers

# Spells. Each one pairs a physical element (fire roar, ice crackle,
# electric arcing, air) with a musical one (chords, arpeggiated
# sparkles, choirs) so it reads as both a force and a piece of magic.


static func preset_fireball() -> Dictionary:
	var whoosh: Dictionary = _layer({"mode": PNK, "length": 1.2, "volume": 1.00, "level": 0.46},
		[_env(0.25, 0.75, 0.0, 0.0), _filt(LP, 300.0, 0.3, 0.8, 0.25, 0.75)])
	# The flames: driven noise with an uneven flutter.
	var roar: Dictionary = _layer({"mode": PNK, "length": 1.2, "volume": 1.00, "level": 0.37},
		[_env(0.15, 0.85, 0.0, 0.0), _filt(BP, _rand(600.0, 800.0), 0.3), _drive(0.6), _trem(0.6, _rand(10.0, 14.0), NSE)])
	var crackle: Dictionary = _layer({"mode": SQR, "pitch": 7.0, "voice": 4, "detune": 0.2, "length": 1.2, "volume": 1.00, "level": 0.23},
		[_env(0.1, 0.9, 0.0, 0.0), _vib(0.6, 1.5), _filt(BP, 3000.0, 0.4)])
	var launch: Dictionary = _layer({"mode": SIN, "pitch": _rand(70.0, 85.0), "length": 0.4, "volume": 1.00, "level": 0.37},
		[_env(0.1, 0.9, 0.0, 0.0), _bend(0.5, 0.1, 0.9), _drive(0.5)])
	return _sound([whoosh, roar, crackle, launch], 0.25, 0.5)


static func preset_frost() -> Dictionary:
	# Ice forming: crystalline arpeggio, crackling growth, a cold wind,
	# and a final crack as it locks solid at 0.55 s.
	var crystal: Dictionary = _layer({"mode": SIN, "pitch": _rand(2600.0, 3000.0), "length": 1.0, "volume": 0.60, "level": 0.57},
		[_env(0.05, 0.95, 0.0, 0.0), _arp(24.0, 5, 12, 7), _pulses(24.0, 0.7), _chord(7, 12, 19, 0.4)])
	var growth: Dictionary = _layer({"mode": SQR, "pitch": 18.0, "voice": 4, "detune": 0.2, "length": 1.0, "volume": 1.00, "level": 0.34},
		[_env(0.2, 0.8, 0.0, 0.0), _vib(0.5, 2.0), _filt(BP, 6000.0, 0.7)])
	var chill: Dictionary = _layer({"mode": NSE, "length": 1.0, "volume": 0.70, "level": 0.28},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(BP, 4000.0, 0.6, 0.3, 0.4, 0.6)])
	var lock: Dictionary = _layer({"mode": NSE, "length": 2.2, "volume": 1.00, "level": 0.45},
		[_at(0.55, 2.2, 0.08), _filt(HP, 2500.0, 0.3), _drive(0.5)])
	return _sound([crystal, growth, chill, lock], 0.35, 0.7)


static func preset_bolt() -> Dictionary:
	# Lightning from the hands: arcing buzz, ripping crack, thunder.
	var arc: Dictionary = _layer({"mode": SAW, "pitch": _rand(100.0, 140.0), "length": 0.7, "volume": 0.90, "level": 0.36},
		[_env(0.0, 0.8, 0.0, 0.0), _vib(0.5, 30.0, NSE), _drive(0.7), _filt(BP, 2500.0, 0.4, 0.4, 0.0, 0.6)])
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.4, "volume": 1.00, "level": 0.36},
		[_env(0.0, 0.7, 0.0, 0.0), _filt(HP, 1500.0, 0.2), _drive(0.8), _pulses(_rand(24.0, 30.0), 0.8)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(42.0, 50.0), "length": 0.6, "volume": 1.00, "level": 0.29},
		[_bend(0.6, 0.0, 0.3), _drive(0.5)])
	var sizzle: Dictionary = _layer({"mode": NSE, "length": 1.0, "volume": 0.60, "level": 0.14},
		[_env(0.05, 0.95, 0.0, 0.0), _filt(HP, 5000.0, 0.2), _trem(0.8, 20.0, NSE)])
	return _sound([arc, crack, boom, sizzle], 0.3, 0.6)


static func preset_heal() -> Dictionary:
	# Warm major chord swelling up, sparkles rising through it.
	var root: float = _pick([392.0, 440.0, 523.0])
	var pad: Dictionary = _layer({"mode": SIN, "pitch": root, "voice": 2, "detune": 0.006, "length": 1.6, "volume": 0.6},
		[_env(0.3, 0.2, 0.6, 0.4), _chord(4, 7, 12, 0.6)])
	var sparkle: Dictionary = _layer({"mode": SIN, "pitch": root * 4.0, "length": 1.4, "volume": 0.5, "level": 0.5},
		[_env(0.2, 0.3, 0.5, 0.4), _arp(12.0, 4, 7, 12), _pulses(12.0, 0.8)])
	var air: Dictionary = _layer({"mode": PNK, "length": 1.6, "volume": 0.6, "level": 0.3},
		[_env(0.4, 0.6, 0.0, 0.0), _filt(BP, 1500.0, 0.4, 0.4, 0.5, 0.5)])
	var glow: Dictionary = _layer({"mode": TRI, "pitch": root * 0.5, "length": 1.6, "volume": 0.5, "level": 0.5},
		[_env(0.4, 0.2, 0.5, 0.4)])
	return _sound([pad, sparkle, air, glow], 0.45, 0.7)


static func preset_holy() -> Dictionary:
	# A choir "aah": detuned saws through two vowel formants, with a
	# bell to mark the moment.
	var choir: Dictionary = _layer({"mode": SAW, "pitch": _pick([220.0, 247.0, 262.0]), "voice": 4, "detune": 0.012, "length": 1.8, "volume": 1.00, "level": 1.00},
		[_env(0.3, 0.2, 0.7, 0.4), _chord(4, 7, 12, 0.6), _filt(BP, 800.0, 0.5), _vib(0.008, 5.0, SIN, 0.3, 0.7)])
	var vowel: Dictionary = _layer({"mode": SAW, "pitch": 262.0, "voice": 4, "detune": 0.01, "length": 1.8, "volume": 0.60, "level": 0.93},
		[_env(0.3, 0.2, 0.7, 0.4), _chord(4, 7, 12, 0.6), _filt(BP, 1200.0, 0.6)])
	var bell: Dictionary = _layer({"mode": SIN, "pitch": 1047.0, "length": 1.6, "volume": 0.50, "level": 0.93},
		[_chord(12, 19, 24, 0.5)])
	var shimmer: Dictionary = _layer({"mode": SIN, "pitch": 2093.0, "voice": 3, "detune": 0.01, "length": 1.6, "volume": 0.40, "level": 0.56},
		[_env(0.4, 0.2, 0.5, 0.4), _trem(0.5, 7.0)])
	return _sound([choir, vowel, bell, shimmer], 0.5, 0.7)


static func preset_curse() -> Dictionary:
	# Dark magic: a dissonant low drone (tritone and minor second)
	# swelling in, whispers, and a sinking tone.
	var drone: Dictionary = _layer({"mode": SAW, "pitch": _rand(50.0, 60.0), "voice": 3, "detune": 0.03, "length": 1.6, "volume": 0.90, "level": 0.63},
		[_env(0.5, 0.2, 0.5, 0.3), _chord(1, 6, 13, 0.6), _filt(LP, 300.0, 0.4, 0.5, 0.5, 0.5)])
	var whisper: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.70, "level": 0.26},
		[_env(0.4, 0.3, 0.4, 0.3), _filt(BP, 3000.0, 0.6, -0.3, 0.3, 0.7), _trem(0.8, 9.0, NSE)])
	var sink: Dictionary = _layer({"mode": SIN, "pitch": _rand(150.0, 180.0), "length": 1.6, "volume": 0.60, "level": 0.38},
		[_env(0.3, 0.7, 0.0, 0.0), _bend(1.0, 0.0, 1.0), _vib(0.03, 5.0)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 41.0, "length": 1.6, "volume": 0.80, "level": 0.38},
		[_env(0.5, 0.5, 0.0, 0.0), _trem(0.5, 3.0)])
	return _sound([drone, whisper, sink, sub], 0.4, 0.7)


static func preset_portal() -> Dictionary:
	# A swirling vortex tearing open.
	var vortex: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 1.00, "level": 0.86},
		[_env(0.3, 0.2, 0.6, 0.3), _filt(BP, 600.0, 0.6, 0.5, 0.5, 0.5), _flange(0.8, 0.4, 0.6, 0.6)])
	var rise: Dictionary = _layer({"mode": SAW, "pitch": _rand(75.0, 90.0), "voice": 3, "detune": 0.02, "length": 2.0, "volume": 0.60, "level": 0.52},
		[_env(0.3, 0.2, 0.6, 0.3), _bend(0.6, 0.6, 0.4), _chord(7, 12, 0, 0.5), _filt(LP, 900.0, 0.4), _vib(0.03, 6.0)])
	var hum: Dictionary = _layer({"mode": SIN, "pitch": 45.0, "length": 2.0, "volume": 0.90, "level": 0.52},
		[_env(0.3, 0.2, 0.7, 0.3), _trem(0.5, 8.0)])
	var sparks: Dictionary = _layer({"mode": SIN, "pitch": _rand(3000.0, 3500.0), "length": 2.0, "volume": 0.40, "level": 0.26},
		[_env(0.4, 0.2, 0.5, 0.3), _arp(15.0, 7, 3, 12), _pulses(15.0, 0.8)])
	return _sound([vortex, rise, hum, sparks], 0.35, 0.65)


static func preset_blink() -> Dictionary:
	# Teleport: a fast upward zip, then a pop where you reappear.
	var zip: Dictionary = _layer({"mode": SIN, "pitch": _rand(250.0, 320.0), "length": 0.25, "volume": 0.80, "level": 0.66},
		[_env(0.2, 0.8, 0.0, 0.0), _bend(0.8, 0.9, 0.1)])
	var swoosh: Dictionary = _layer({"mode": NSE, "length": 0.25, "volume": 0.80, "level": 0.40},
		[_env(0.6, 0.4, 0.0, 0.0), _filt(HP, 800.0, 0.3, 0.6, 0.9, 0.1)])
	var pop: Dictionary = _layer({"mode": SIN, "pitch": _rand(800.0, 1000.0), "length": 1.2, "volume": 1.00, "level": 0.53},
		[_at(0.25, 1.2, 0.08), _bend(0.4, 0.0, 0.06)])
	var shimmer: Dictionary = _layer({"mode": SIN, "pitch": 2400.0, "length": 1.2, "volume": 0.50, "level": 0.26},
		[_at(0.25, 1.2, 0.2), _chord(7, 12, 19, 0.5), _echo(90.0, 0.5, 0.4)])
	return _sound([zip, swoosh, pop, shimmer], 0.3, 0.5)


static func preset_summon() -> Dictionary:
	# Rumbling build, a rising choir, and the creature arriving with a
	# boom at 0.7 s.
	var build: Dictionary = _layer({"mode": PNK, "length": 0.8, "volume": 1.00, "level": 0.35},
		[_env(0.9, 0.1, 0.0, 0.0), _filt(LP, 200.0, 0.3, 0.6, 0.9, 0.1)])
	var choir: Dictionary = _layer({"mode": SAW, "pitch": _rand(130.0, 150.0), "voice": 4, "detune": 0.015, "length": 2.0, "volume": 0.60, "level": 0.21},
		[_env(0.3, 0.2, 0.5, 0.5), _bend(0.25, 1.0, 0.0), _chord(7, 12, 15, 0.5), _filt(BP, 900.0, 0.5)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(40.0, 48.0), "length": 2.4, "volume": 1.00, "level": 0.35},
		[_at(0.7, 2.4, 0.6), _drive(0.7)])
	var blast: Dictionary = _layer({"mode": NSE, "length": 2.4, "volume": 1.00, "level": 0.25},
		[_at(0.7, 2.4, 0.4), _filt(LP, 400.0, 0.2)])
	return _sound([build, choir, boom, blast], 0.4, 0.7)


static func preset_potion() -> Dictionary:
	# Three glugs, then a magical "ting" as it takes effect.
	var glug: Dictionary = _layer({"mode": SIN, "pitch": _rand(260.0, 320.0), "length": 0.5, "volume": 0.90, "level": 0.51},
		[_env(0.0, 0.0, 1.0, 0.1), _vib(0.4, 6.0, SAW), _pulses(6.0), _filt(LP, 900.0, 0.3)])
	var liquid: Dictionary = _layer({"mode": PNK, "length": 0.5, "volume": 0.70, "level": 0.25},
		[_env(0.0, 0.0, 1.0, 0.1), _filt(BP, 700.0, 0.5), _pulses(6.0)])
	var ting: Dictionary = _layer({"mode": SIN, "pitch": _rand(1500.0, 1800.0), "length": 2.2, "volume": 0.60, "level": 0.30},
		[_at(0.55, 2.2, 0.5), _chord(7, 12, 16, 0.5)])
	var sparkle: Dictionary = _layer({"mode": SIN, "pitch": 3500.0, "length": 2.2, "volume": 0.40, "level": 0.20},
		[_at(0.55, 2.2, 0.5), _arp(16.0, 4, 7, 12)])
	return _sound([glug, liquid, ting, sparkle], 0.3, 0.5)


static func preset_charge() -> Dictionary:
	# Power building: everything rises and brightens; vibrato intensifies.
	var tone: Dictionary = _layer({"mode": SAW, "pitch": _rand(100.0, 120.0), "voice": 3, "detune": 0.02, "length": 1.5, "volume": 0.70, "level": 0.65},
		[_env(0.8, 0.0, 1.0, 0.1), _bend(0.6, 1.0, 0.0), _vib(0.03, 9.0, SIN, 1.0, 0.0), _filt(LP, 300.0, 0.6, 0.7, 1.0, 0.0)])
	var air: Dictionary = _layer({"mode": NSE, "length": 1.5, "volume": 0.70, "level": 0.32},
		[_env(0.9, 0.0, 1.0, 0.1), _filt(BP, 800.0, 0.6, 0.6, 1.0, 0.0)])
	var sparks: Dictionary = _layer({"mode": SIN, "pitch": _rand(1800.0, 2200.0), "length": 1.5, "volume": 0.50, "level": 0.26},
		[_env(0.9, 0.0, 1.0, 0.1), _arp(20.0, 7, 12, 5), _pulses(20.0, 0.7), _bend(0.4, 1.0, 0.0)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 50.0, "length": 1.5, "volume": 0.70, "level": 0.32},
		[_env(0.9, 0.0, 1.0, 0.1), _bend(0.3, 1.0, 0.0)])
	return _sound([tone, air, sparks, sub], 0.25, 0.5)


static func preset_fizzle() -> Dictionary:
	# The spell fails: a sputtering, sagging, crunchy collapse.
	var sag: Dictionary = _layer({"mode": SAW, "pitch": _rand(150.0, 190.0), "length": 0.6, "volume": 0.70, "level": 0.76},
		[_bend(0.6, 0.0, 1.0), _crush(4, 6), _filt(LP, 1200.0, 0.3, -0.4, 0.0, 1.0)])
	var sputter: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 0.90, "level": 0.53},
		[_filt(BP, 2000.0, 0.4), _pulses(_rand(16.0, 20.0), 0.9)])
	var womp: Dictionary = _layer({"mode": SIN, "pitch": 110.0, "length": 0.3, "volume": 0.80, "level": 0.46},
		[_bend(0.5, 0.0, 1.0)])
	return _sound([sag, sputter, womp], 0.12, 0.3)


static func preset_enchant() -> Dictionary:
	# Twinkling sparkles at two speeds over a shimmering chord.
	var twinkle1: Dictionary = _layer({"mode": SIN, "pitch": _rand(3200.0, 3700.0), "length": 1.4, "volume": 0.5},
		[_env(0.05, 0.3, 0.5, 0.4), _arp(18.0, 7, 12, 19), _pulses(18.0)])
	var twinkle2: Dictionary = _layer({"mode": SIN, "pitch": _rand(3500.0, 4000.0), "length": 1.4, "volume": 0.4, "level": 0.7},
		[_env(0.15, 0.3, 0.4, 0.4), _arp(13.3, 5, 12, 17), _pulses(13.3)])
	var pad: Dictionary = _layer({"mode": SIN, "pitch": 1760.0, "voice": 2, "detune": 0.005, "length": 1.4, "volume": 0.5, "level": 0.5},
		[_env(0.2, 0.2, 0.5, 0.4), _chord(7, 12, 19, 0.5), _trem(0.4, 6.0)])
	var ting: Dictionary = _layer({"mode": SIN, "pitch": 2637.0, "length": 1.2, "volume": 0.6, "level": 0.5},
		[_chord(12, 19, 0, 0.4)])
	return _sound([twinkle1, twinkle2, pad, ting], 0.4, 0.7)


static func preset_barrier() -> Dictionary:
	# A magic shield snapping up: whoosh in, humming field, bright ring.
	var whoosh: Dictionary = _layer({"mode": NSE, "length": 0.3, "volume": 0.80, "level": 0.72},
		[_env(0.7, 0.3, 0.0, 0.0), _filt(BP, 700.0, 0.5, 0.6, 0.7, 0.3)])
	var field: Dictionary = _layer({"mode": SAW, "pitch": _rand(100.0, 120.0), "voice": 3, "detune": 0.02, "length": 1.6, "volume": 0.72, "level": 1.00},
		[_env(0.15, 0.2, 0.6, 0.4), _chord(7, 12, 0, 0.5), _filt(BP, 800.0, 0.6), _trem(0.5, 9.0)])
	var ring: Dictionary = _layer({"mode": SIN, "pitch": _rand(1400.0, 1600.0), "length": 1.2, "volume": 0.60, "level": 0.72},
		[_at(0.25, 1.2, 0.25), _chord(12, 19, 24, 0.5)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 55.0, "length": 1.6, "volume": 0.80, "level": 0.60},
		[_env(0.15, 0.2, 0.5, 0.4)])
	return _sound([whoosh, field, ring, sub], 0.35, 0.6)
