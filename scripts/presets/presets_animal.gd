class_name PresetsAnimal
extends PresetsHelpers

# Real animals. Voices are a buzzy source (saw or a slow pulse train)
# through bandpass "formants" that move with the call, plus a breath
# layer. Birds and insects are fast patterns: saw vibrato makes each
# pulse a chirp, and two detuned voices beat against each other to
# chop a tone into insect-wing pulses.


static func preset_birds() -> Dictionary:
	# A songbird phrase: every chirp sweeps up, and the arp moves each
	# one to a new pitch.
	var r1: float = _rand(10.0, 12.0)
	var song: Dictionary = _layer({"mode": SIN, "pitch": _rand(3000.0, 3600.0), "length": _rand(1.0, 1.3), "volume": 0.70, "level": 0.53},
		[_env(0.0, 0.0, 1.0, 0.15), _arp(r1, 3, -2, 5), _vib(0.22, r1, SAW), _pulses(r1)])
	# A second bird answering with slower up-down calls.
	var r2: float = _rand(5.5, 7.0)
	var answer: Dictionary = _layer({"mode": SIN, "pitch": _rand(3500.0, 4000.0), "length": 1.2, "volume": 0.50, "level": 0.32},
		[_env(0.0, 0.0, 1.0, 0.2), _arp(r2, -4, 2, -7), _vib(0.15, r2, TRI), _pulses(r2)])
	# A trill: fast warble on a held note.
	var trill: Dictionary = _layer({"mode": SIN, "pitch": _rand(3400.0, 3800.0), "length": 0.5, "volume": 0.50, "level": 0.27},
		[_env(0.2, 0.5, 0.3, 0.3), _vib(0.06, 28.0), _trem(0.8, 28.0)])
	return _sound([song, answer, trill], 0.15, 0.5)


static func preset_crow() -> Dictionary:
	# Two harsh, nasal "caw"s.
	var gap: float = _rand(330.0, 420.0)
	var caw: Dictionary = _layer({"mode": SAW, "pitch": _rand(480.0, 560.0), "length": 0.28, "volume": 0.9},
		[_env(0.05, 0.3, 0.5, 0.3), _bend(0.15, 0.1, 0.9), _vib(0.04, 30.0, NSE), _drive(0.5), _filt(BP, 1400.0, 0.6), _echo(gap, 0.66)])
	var formant: Dictionary = _layer({"mode": SAW, "pitch": _rand(480.0, 560.0), "length": 0.28, "volume": 0.7, "level": 0.6},
		[_env(0.05, 0.3, 0.5, 0.3), _bend(0.15, 0.1, 0.9), _filt(BP, 2600.0, 0.5), _echo(gap, 0.66)])
	var breath: Dictionary = _layer({"mode": NSE, "length": 0.28, "volume": 0.6, "level": 0.35},
		[_env(0.05, 0.3, 0.5, 0.3), _filt(BP, 2000.0, 0.3), _echo(gap, 0.66)])
	return _sound([caw, formant, breath], 0.2, 0.5)


static func preset_owl() -> Dictionary:
	# Soft "hoo — hoo-hoo" in a forest.
	var gap: float = _rand(320.0, 380.0)
	var hoot: Dictionary = _layer({"mode": SIN, "pitch": _rand(360.0, 400.0), "length": 0.3, "volume": 0.90, "level": 0.73},
		[_env(0.25, 0.35, 0.4, 0.4), _bend(0.06, 0.3, 0.7), _vib(0.01, 6.0), _echo(gap, 0.6, 0.35)])
	var hollow: Dictionary = _layer({"mode": TRI, "pitch": _rand(360.0, 400.0), "length": 0.3, "volume": 0.50, "level": 0.29},
		[_env(0.25, 0.35, 0.4, 0.4), _filt(LP, 700.0, 0.2), _echo(gap, 0.6, 0.35)])
	var breath: Dictionary = _layer({"mode": PNK, "length": 0.3, "volume": 0.60, "level": 0.18},
		[_env(0.25, 0.35, 0.4, 0.4), _filt(BP, 400.0, 0.4), _echo(gap, 0.6, 0.35)])
	return _sound([hoot, hollow, breath], 0.3, 0.6)


static func preset_crickets() -> Dictionary:
	# Each cricket is four sines a few Hz apart. Equally spaced voices
	# beat into a sharp pulse train at that spacing — steady chirps for
	# the whole bed, unlike tremolo, whose depth fades. A fast saw
	# tremolo adds the wing-stroke texture inside each chirp.
	var a: Dictionary = _layer({"mode": SIN, "pitch": 3900.0, "voice": 4, "detune": _rand(0.0021, 0.0025), "length": 2.0, "volume": 0.60, "level": 0.42},
		[_env(0.05, 0.0, 1.0, 0.1), _trem(0.7, 30.0, SAW)])
	var b: Dictionary = _layer({"mode": SIN, "pitch": 3500.0, "voice": 4, "detune": _rand(0.0031, 0.0037), "length": 2.0, "volume": 0.50, "level": 0.30},
		[_env(0.05, 0.0, 1.0, 0.1), _trem(0.7, 28.0, SAW)])
	var c: Dictionary = _layer({"mode": SIN, "pitch": 3200.0, "voice": 4, "detune": _rand(0.0019, 0.0022), "length": 2.0, "volume": 0.40, "level": 0.21},
		[_env(0.05, 0.0, 1.0, 0.1), _trem(0.6, 26.0, SAW)])
	var night: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 0.40, "level": 0.11},
		[_env(0.1, 0.0, 1.0, 0.1), _filt(LP, 600.0, 0.1)])
	return _sound([a, b, c, night], 0.2, 0.6)


static func preset_frog() -> Dictionary:
	# "Rib-bit": a slow glottal pulse train ringing a throat resonance,
	# split into two bursts.
	var croak: Dictionary = _layer({"mode": SAW, "pitch": _rand(26.0, 32.0), "length": 0.3, "volume": 1.00, "level": 0.64},
		[_env(0.0, 0.0, 1.0, 0.15), _pulses(_rand(6.5, 7.5)), _bend(0.15, 1.0, 0.0), _filt(BP, _rand(600.0, 750.0), 0.85)])
	var nasal: Dictionary = _layer({"mode": SAW, "pitch": _rand(26.0, 32.0), "length": 0.3, "volume": 0.80, "level": 0.38},
		[_env(0.0, 0.0, 1.0, 0.15), _pulses(7.0), _filt(BP, 1500.0, 0.75)])
	var throat: Dictionary = _layer({"mode": SIN, "pitch": 140.0, "length": 0.3, "volume": 0.60, "level": 0.26},
		[_env(0.0, 0.0, 1.0, 0.15), _pulses(7.0)])
	return _sound([croak, nasal, throat], 0.25, 0.55)


static func preset_buzz() -> Dictionary:
	# A fly circling past: wavering wing buzz, swelling as it nears.
	var wings: Dictionary = _layer({"mode": SAW, "pitch": _rand(200.0, 240.0), "voice": 2, "detune": 0.02, "length": 2.0, "volume": 0.80, "level": 0.79},
		[_env(0.3, 0.0, 1.0, 0.4), _vib(0.06, _rand(2.5, 3.5)), _trem(0.6, _rand(1.5, 2.2)), _filt(BP, 1200.0, 0.3), _flange(0.4, 0.5, 0.3, 0.4)])
	var hum: Dictionary = _layer({"mode": SAW, "pitch": _rand(200.0, 240.0), "length": 2.0, "volume": 0.60, "level": 0.39},
		[_env(0.3, 0.0, 1.0, 0.4), _vib(0.05, 3.0), _filt(LP, 600.0, 0.3)])
	return _sound([wings, hum], 0.05, 0.3)


static func preset_dog() -> Dictionary:
	# Medium dog, two barks: the pitch kicks up then drops, the mouth
	# opens (filter swells) — "wuh-OOF".
	var gap: float = _rand(240.0, 300.0)
	var bark: Dictionary = _layer({"mode": SAW, "pitch": _rand(290.0, 350.0), "length": 0.18, "volume": 1.00, "level": 1.00},
		[_env(0.03, 0.4, 0.3, 0.4), _bend(0.25, 0.2, 0.8), _drive(0.6), _filt(BP, 800.0, 0.5, 0.5, 0.2, 0.8), _echo(gap, 0.66)])
	var chest: Dictionary = _layer({"mode": SAW, "pitch": _rand(150.0, 170.0), "length": 0.18, "volume": 0.80, "level": 0.76},
		[_env(0.03, 0.4, 0.3, 0.4), _bend(0.25, 0.2, 0.8), _filt(LP, 500.0, 0.3), _echo(gap, 0.66)])
	var breath: Dictionary = _layer({"mode": NSE, "length": 0.18, "volume": 0.80, "level": 0.58},
		[_env(0.03, 0.4, 0.3, 0.4), _filt(BP, 1600.0, 0.3, 0.4, 0.2, 0.8), _echo(gap, 0.66)])
	return _sound([bark, chest, breath], 0.15, 0.4)


static func preset_cat() -> Dictionary:
	# "Mi-aaa-ow": pitch rises and falls while the formants open from a
	# closed "mm/ee" to "aa" and close to "ow".
	var dur: float = _rand(0.6, 0.8)
	var voice: Dictionary = _layer({"mode": SAW, "pitch": _rand(480.0, 560.0), "length": dur, "volume": 0.90, "level": 0.69},
		[_env(0.15, 0.3, 0.6, 0.4), _bend(0.35, 0.3, 0.7), _vib(0.02, 6.0), _filt(BP, 900.0, 0.6, 0.6, 0.4, 0.6)])
	var upper: Dictionary = _layer({"mode": SAW, "pitch": _rand(480.0, 560.0), "length": dur, "volume": 0.70, "level": 0.35},
		[_env(0.15, 0.3, 0.6, 0.4), _bend(0.35, 0.3, 0.7), _filt(BP, 2700.0, 0.6, 0.4, 0.4, 0.6)])
	var breath: Dictionary = _layer({"mode": NSE, "length": dur, "volume": 0.50, "level": 0.14},
		[_env(0.15, 0.3, 0.6, 0.4), _filt(BP, 3000.0, 0.3)])
	return _sound([voice, upper, breath], 0.15, 0.4)


static func preset_wolf() -> Dictionary:
	# A long howl gliding up and slowly sinking, vibrato arriving late.
	var howl: Dictionary = _layer({"mode": SIN, "pitch": _rand(400.0, 450.0), "length": _rand(1.8, 2.1), "volume": 0.80, "level": 0.45},
		[_env(0.2, 0.2, 0.7, 0.4), _bend(0.3, 0.25, 0.75), _vib(0.015, 5.0, SIN, 0.4, 0.6)])
	var overtone: Dictionary = _layer({"mode": TRI, "pitch": _rand(800.0, 900.0), "length": 2.0, "volume": 0.50, "level": 0.15},
		[_env(0.2, 0.2, 0.7, 0.4), _bend(0.3, 0.25, 0.75), _filt(BP, 1200.0, 0.4)])
	var breath: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 0.50, "level": 0.09},
		[_env(0.2, 0.2, 0.6, 0.4), _filt(BP, 1000.0, 0.4)])
	return _sound([howl, overtone, breath], 0.35, 0.7)


static func preset_cow() -> Dictionary:
	# "Mmm-ooo": a low buzzy voice with the mouth slowly opening.
	var voice: Dictionary = _layer({"mode": SAW, "pitch": _rand(100.0, 120.0), "length": _rand(1.2, 1.5), "volume": 1.00, "level": 0.75},
		[_env(0.15, 0.2, 0.7, 0.3), _bend(0.12, 0.3, 0.7), _vib(0.01, 5.0), _filt(BP, 400.0, 0.6, 0.5, 0.5, 0.5)])
	var formant: Dictionary = _layer({"mode": SAW, "pitch": _rand(100.0, 120.0), "length": 1.4, "volume": 0.80, "level": 0.38},
		[_env(0.2, 0.2, 0.6, 0.3), _bend(0.12, 0.3, 0.7), _filt(BP, 900.0, 0.5, 0.4, 0.5, 0.5)])
	var breath: Dictionary = _layer({"mode": PNK, "length": 1.4, "volume": 0.60, "level": 0.19},
		[_env(0.15, 0.2, 0.6, 0.3), _filt(BP, 700.0, 0.3)])
	return _sound([voice, formant, breath], 0.2, 0.5)


static func preset_rattler() -> Dictionary:
	# Rattlesnake: two click trains ~50 a second (one click per saw
	# cycle, ringing a bright bandpass), slightly out of step so the
	# rattle never settles into a tone, over a pulsing hiss.
	var rate: float = _rand(45.0, 55.0)
	var rattle: Dictionary = _layer({"mode": SAW, "pitch": rate, "length": 1.6, "volume": 0.60, "level": 0.75},
		[_env(0.1, 0.0, 1.0, 0.2), _vib(0.08, 6.0, NSE), _filt(BP, _rand(4500.0, 5500.0), 0.6)])
	var segments: Dictionary = _layer({"mode": SAW, "pitch": rate * 1.07, "length": 1.6, "volume": 0.50, "level": 0.52},
		[_env(0.1, 0.0, 1.0, 0.2), _vib(0.08, 4.5, NSE), _filt(BP, 7500.0, 0.6)])
	var hiss: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.80, "level": 0.60},
		[_env(0.15, 0.0, 1.0, 0.2), _filt(BP, 4500.0, 0.3), _pulses(25.0, 0.6)])
	return _sound([rattle, segments, hiss], 0.08, 0.3)


static func preset_gull() -> Dictionary:
	# Seagull "kee-ah" calls, three in a falling run.
	var gap: float = _rand(230.0, 280.0)
	var cry: Dictionary = _layer({"mode": SAW, "pitch": _rand(850.0, 1000.0), "length": 0.22, "volume": 0.8},
		[_env(0.05, 0.3, 0.5, 0.3), _bend(0.3, 0.2, 0.8), _drive(0.3), _filt(BP, 2200.0, 0.6), _echo(gap, 0.66, 0.45)])
	var nasal: Dictionary = _layer({"mode": SAW, "pitch": _rand(850.0, 1000.0), "length": 0.22, "volume": 0.6, "level": 0.5},
		[_env(0.05, 0.3, 0.5, 0.3), _bend(0.3, 0.2, 0.8), _filt(BP, 3800.0, 0.5), _echo(gap, 0.66, 0.45)])
	var surf: Dictionary = _layer({"mode": PNK, "length": 1.4, "volume": 0.5, "level": 0.25},
		[_env(0.2, 0.0, 1.0, 0.3), _filt(LP, 900.0, 0.1)])
	return _sound([cry, nasal, surf], 0.2, 0.6)
