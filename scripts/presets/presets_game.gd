class_name PresetsGame
extends PresetsHelpers

# Gameplay feedback: pickups, progression stingers and status cues.
# Musical, but built from real-sounding parts (struck bells, brass with
# a filter "bite", timpani, cymbal wash) rather than bare chip tones.


static func preset_coin() -> Dictionary:
	# B6 → E7: the two-note coin chime, rung like a small bell. The
	# length stops the arp before it wraps back to the first note.
	var chime: Dictionary = _layer({"mode": SIN, "pitch": 1976.0, "length": 0.32, "volume": 0.70, "level": 0.79},
		[_env(0.0, 0.15, 0.5, 0.5), _arp(12.5, 5, 5, 5), _chord(12, 19, 0, 0.3)])
	var body: Dictionary = _layer({"mode": TRI, "pitch": 988.0, "length": 0.32, "volume": 0.50, "level": 0.24},
		[_env(0.0, 0.15, 0.5, 0.5), _arp(12.5, 5, 5, 5)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.01, "volume": 0.60, "level": 0.31},
		[_filt(HP, 5000.0, 0.3)])
	return _sound([chime, body, tick], 0.2, 0.35)


static func preset_gems() -> Dictionary:
	# Crystal pickup: a fast glassy run and a shimmering tail.
	var run: Dictionary = _layer({"mode": SIN, "pitch": _pick([1760.0, 2093.0, 2349.0]), "length": 0.4, "volume": 0.6},
		[_env(0.0, 0.1, 0.6, 0.5), _arp(20.0, 7, 12, 19), _pulses(20.0, 0.6)])
	var shimmer: Dictionary = _layer({"mode": SIN, "pitch": 2093.0, "voice": 3, "detune": 0.006, "length": 0.8, "volume": 0.4, "level": 0.4},
		[_env(0.1, 0.9, 0.0, 0.0), _trem(0.5, 12.0), _chord(12, 24, 0, 0.6)])
	var glass: Dictionary = _layer({"mode": SIN, "pitch": 3136.0, "length": 0.4, "volume": 0.5, "level": 0.4},
		[_chord(5, 17, 0, 0.5)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.5, "level": 0.4},
		[_filt(HP, 5000.0, 0.3)])
	return _sound([run, shimmer, glass, tick], 0.25, 0.45)


static func preset_pickup() -> Dictionary:
	# Grabbing an item: soft upward "bwip" with a pluck.
	var bwip: Dictionary = _layer({"mode": TRI, "pitch": _rand(400.0, 480.0), "length": 0.12, "volume": 0.80, "level": 0.80},
		[_bend(0.5, 1.0, 0.0), _chord(12, 0, 0, 0.3)])
	var pluck: Dictionary = _layer({"mode": SAW, "pitch": 880.0, "length": 0.08, "volume": 0.50, "level": 0.32},
		[_filt(LP, 2500.0, 0.3, -0.5, 0.0, 1.0)])
	var grab: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.50, "level": 0.32},
		[_filt(BP, 2000.0, 0.3)])
	return _sound([bwip, pluck, grab], 0.1, 0.25)


static func preset_level_up() -> Dictionary:
	# Arpeggio up the major chord, landing on a swelling chord with a
	# sparkle and a kick under it.
	var root: float = _pick([523.0, 587.0, 659.0])
	var arpeggio: Dictionary = _layer({"mode": SQR, "pitch": root, "length": 0.34, "volume": 0.50, "level": 0.46},
		[_env(0.0, 0.0, 1.0, 0.1), _arp(12.0, 4, 7, 12), _filt(LP, 3000.0, 0.2)])
	var chord: Dictionary = _layer({"mode": SAW, "pitch": root * 2.0, "voice": 3, "detune": 0.008, "length": 1.2, "volume": 0.50, "level": 0.28},
		[_env(0.25, 0.2, 0.6, 0.4), _chord(4, 7, 12, 0.6), _filt(LP, 2000.0, 0.3, 0.4, 0.3, 0.7)])
	var sparkle: Dictionary = _layer({"mode": SIN, "pitch": root * 4.0, "length": 1.0, "volume": 0.40, "level": 0.14},
		[_env(0.3, 0.7, 0.0, 0.0), _arp(20.0, 4, 7, 12), _pulses(20.0, 0.7), _chord(12, 0, 0, 0.5)])
	var kick: Dictionary = _layer({"mode": SIN, "pitch": 60.0, "length": 0.2, "volume": 0.80, "level": 0.28},
		[_bend(0.6, 0.0, 0.3)])
	return _sound([arpeggio, chord, sparkle, kick], 0.3, 0.5)


static func preset_achievement() -> Dictionary:
	# "Ta-DA!": a brass pickup note, then the full chord a fourth up,
	# over timpani and a cymbal.
	var brass: Dictionary = _layer({"mode": SAW, "pitch": 392.0, "voice": 3, "detune": 0.008, "length": 1.0, "volume": 0.60, "level": 0.51},
		[_env(0.02, 0.2, 0.6, 0.5), _arp(5.0, 5, 5, 5), _chord(4, 7, 12, 0.5), _filt(LP, 1200.0, 0.3, 0.5, 0.0, 0.3)])
	var timpani: Dictionary = _layer({"mode": SIN, "pitch": 98.0, "length": 1.0, "volume": 0.90, "level": 0.35},
		[_arp(5.0, 5, 5, 5), _bend(0.15, 0.0, 0.1), _pulses(5.0, 0.6)])
	var cymbal: Dictionary = _layer({"mode": NSE, "length": 1.4, "volume": 0.60, "level": 0.20},
		[_filt(HP, 6000.0, 0.2)])
	var sparkle: Dictionary = _layer({"mode": SIN, "pitch": 3136.0, "length": 1.0, "volume": 0.40, "level": 0.15},
		[_env(0.2, 0.8, 0.0, 0.0), _arp(16.0, 5, 9, 12), _pulses(16.0, 0.7)])
	return _sound([brass, timpani, cymbal, sparkle], 0.35, 0.6)


static func preset_quest() -> Dictionary:
	# Quest-complete jingle: four rising notes and a bell.
	var root: float = _pick([523.0, 587.0])
	var melody: Dictionary = _layer({"mode": TRI, "pitch": root, "length": 0.8, "volume": 0.70, "level": 0.65},
		[_env(0.0, 0.1, 0.8, 0.3), _arp(5.0, 4, 7, 12), _pulses(5.0, 0.5)])
	var harmony: Dictionary = _layer({"mode": SQR, "pitch": root * 0.5, "length": 0.8, "volume": 0.40, "level": 0.26},
		[_env(0.0, 0.1, 0.8, 0.3), _arp(5.0, 4, 7, 12), _filt(LP, 1500.0, 0.2)])
	var bell: Dictionary = _layer({"mode": SIN, "pitch": root * 4.0, "length": 0.8, "volume": 0.50, "level": 0.26},
		[_env(0.0, 0.1, 0.8, 0.3), _arp(5.0, 4, 7, 12), _chord(12, 19, 0, 0.3), _pulses(5.0)])
	return _sound([melody, harmony, bell], 0.3, 0.5)


static func preset_game_over() -> Dictionary:
	# "Wah, wah, wah, waaah": a muted horn sinking a semitone at a time,
	# the last note wobbling.
	var horn: Dictionary = _layer({"mode": SAW, "pitch": _rand(300.0, 330.0), "voice": 2, "detune": 0.006, "length": 1.5, "volume": 0.89, "level": 1.00},
		[_env(0.02, 0.1, 0.8, 0.2), _arp(2.6, -1, -2, -3), _trem(0.6, 2.6, SAW), _vib(0.03, 6.0, SIN, 1.0, 0.0), _filt(BP, 900.0, 0.6)])
	var low: Dictionary = _layer({"mode": SAW, "pitch": 158.0, "length": 1.5, "volume": 0.50, "level": 0.64},
		[_env(0.02, 0.1, 0.8, 0.2), _arp(2.6, -1, -2, -3), _trem(0.6, 2.6, SAW), _filt(LP, 600.0, 0.3)])
	var mute: Dictionary = _layer({"mode": SAW, "pitch": 316.0, "length": 1.5, "volume": 0.40, "level": 0.51},
		[_env(0.02, 0.1, 0.8, 0.2), _arp(2.6, -1, -2, -3), _filt(BP, 1800.0, 0.6)])
	return _sound([horn, low, mute], 0.25, 0.45)


static func preset_countdown() -> Dictionary:
	# Beep, beep, beep, GO — at 0, 0.5, 1.0 and 1.5 s. The second beep is
	# the first one's echo; the third and GO are late-onset layers. Their
	# gates leak a little before opening, so each sits two octaves down
	# (cut by a highpass) until an arp step lifts it into place on cue.
	var beeps: Dictionary = _layer({"mode": SIN, "pitch": 880.0, "length": 0.12, "volume": 0.80, "level": 0.38},
		[_env(0.0, 0.3, 0.7, 0.3), _echo(500.0, 0.66)])
	var third: Dictionary = _layer({"mode": SIN, "pitch": 220.0, "length": 2.2, "volume": 0.80, "level": 0.46},
		[_at(1.0, 2.2, 0.12), _arp(2.0, 0, 24, 0), _filt(HP, 600.0, 0.1)])
	var go: Dictionary = _layer({"mode": TRI, "pitch": 440.0, "length": 2.2, "volume": 0.80, "level": 0.69},
		[_at(1.5, 2.2, 0.6), _arp(2.0, 0, 0, 24), _filt(HP, 1200.0, 0.1)])
	return _sound([beeps, third, go], 0.1, 0.3)


static func preset_heartbeat() -> Dictionary:
	# One "lub-dub" — loop it for a low-health warning.
	var dub: float = _rand(260.0, 300.0)
	var lub: Dictionary = _layer({"mode": SIN, "pitch": _rand(50.0, 58.0), "length": 0.14, "volume": 1.00, "level": 0.68},
		[_bend(0.5, 0.0, 0.3), _drive(0.3), _echo(dub, 0.55)])
	var thump: Dictionary = _layer({"mode": PNK, "length": 0.1, "volume": 1.00, "level": 0.41},
		[_filt(LP, 150.0, 0.3), _echo(dub, 0.55)])
	var body: Dictionary = _layer({"mode": SIN, "pitch": 38.0, "length": 0.18, "volume": 0.80, "level": 0.41},
		[_echo(dub, 0.55)])
	return _sound([lub, thump, body], 0.1, 0.3)


static func preset_purchase() -> Dictionary:
	# Cash register "ka-ching": drawer clunk, then the bell.
	var clunk: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 1.0, "level": 0.8},
		[_filt(BP, 900.0, 0.4), _drive(0.5)])
	var drawer: Dictionary = _layer({"mode": SIN, "pitch": 150.0, "length": 0.08, "volume": 0.8, "level": 0.6},
		[_bend(0.3, 0.0, 0.4)])
	var bell: Dictionary = _layer({"mode": SIN, "pitch": _rand(2500.0, 2750.0), "length": 1.0, "volume": 0.8, "level": 0.8},
		[_at(0.12, 1.0, 0.12), _chord(5, 12, 17, 0.5)])
	var coins: Dictionary = _layer({"mode": SQR, "pitch": 30.0, "voice": 4, "detune": 0.2, "length": 0.3, "volume": 1.0, "level": 0.4},
		[_vib(0.5, 4.0), _filt(BP, 5000.0, 0.6)])
	return _sound([clunk, drawer, bell, coins], 0.3, 0.4)


static func preset_jump() -> Dictionary:
	var spring: Dictionary = _layer({"mode": SQR, "pitch": _rand(180.0, 220.0), "length": 0.2, "volume": 0.50, "level": 0.56},
		[_bend(0.5, 1.0, 0.0), _filt(LP, 1800.0, 0.3)])
	var whoosh: Dictionary = _layer({"mode": NSE, "length": 0.15, "volume": 0.70, "level": 0.33},
		[_env(0.2, 0.8, 0.0, 0.0), _filt(BP, 800.0, 0.4, 0.5, 0.2, 0.8)])
	var scuff: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.60, "level": 0.28},
		[_filt(HP, 2500.0, 0.2)])
	return _sound([spring, whoosh, scuff], 0.05, 0.2)


static func preset_powerup() -> Dictionary:
	# Rising arpeggio that bends upward, a chord blooming behind it.
	var root: float = _pick([262.0, 294.0, 330.0])
	var rise: Dictionary = _layer({"mode": SAW, "pitch": root, "length": 0.7, "volume": 0.60, "level": 0.65},
		[_env(0.0, 0.0, 1.0, 0.25), _arp(16.0, 4, 7, 12), _bend(0.5, 1.0, 0.0), _filt(LP, 2000.0, 0.3, 0.5, 1.0, 0.0)])
	var bloom: Dictionary = _layer({"mode": SIN, "pitch": root * 2.0, "voice": 2, "detune": 0.006, "length": 1.0, "volume": 0.60, "level": 0.39},
		[_env(0.5, 0.2, 0.5, 0.3), _chord(4, 7, 12, 0.6)])
	var sparkle: Dictionary = _layer({"mode": SIN, "pitch": root * 12.0, "length": 1.0, "volume": 0.40, "level": 0.20},
		[_env(0.4, 0.6, 0.0, 0.0), _arp(24.0, 7, 12, 4), _pulses(24.0, 0.7)])
	var whoosh: Dictionary = _layer({"mode": NSE, "length": 0.7, "volume": 0.50, "level": 0.20},
		[_env(0.8, 0.2, 0.0, 0.0), _filt(BP, 1000.0, 0.5, 0.6, 1.0, 0.0)])
	return _sound([rise, bloom, sparkle, whoosh], 0.3, 0.5)


static func preset_hurt() -> Dictionary:
	# Taking a hit: a body blow, a crunch and a pained grunt.
	var thud: Dictionary = _layer({"mode": SIN, "pitch": _rand(80.0, 100.0), "length": 0.15, "volume": 1.00, "level": 0.32},
		[_bend(0.5, 0.0, 0.3), _drive(0.5)])
	var crunch: Dictionary = _layer({"mode": NSE, "length": 0.06, "volume": 0.90, "level": 0.19},
		[_filt(BP, 1500.0, 0.3), _drive(0.5), _crush(5, 3)])
	var grunt: Dictionary = _layer({"mode": SAW, "pitch": _rand(180.0, 220.0), "length": 0.22, "volume": 0.80, "level": 0.19},
		[_env(0.02, 0.3, 0.4, 0.4), _bend(0.3, 0.0, 1.0), _drive(0.4), _filt(BP, 800.0, 0.5)])
	return _sound([thud, crunch, grunt], 0.1, 0.25)
