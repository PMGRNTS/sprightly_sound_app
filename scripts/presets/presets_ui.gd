class_name PresetsUi
extends PresetsHelpers

# Interface sounds: short, clean and quiet enough to repeat all day. Each
# pairs a tonal element with a tiny noise transient so it feels tactile
# rather than purely electronic. Two-note chimes use the arp: with the
# length set to about two arp steps, it plays one note, then holds the
# next (later steps repeat it).


static func preset_click() -> Dictionary:
	var tone: Dictionary = _layer({"mode": SIN, "pitch": _rand(2000.0, 2400.0), "length": 0.012, "volume": 0.80, "level": 0.48})
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.006, "volume": 0.60, "level": 0.29},
		[_filt(HP, 4000.0, 0.2)])
	var body: Dictionary = _layer({"mode": SIN, "pitch": 600.0, "length": 0.02, "volume": 0.60, "level": 0.19})
	return _sound([tone, tick, body], 0.0, 0.2)


static func preset_hover() -> Dictionary:
	var tone: Dictionary = _layer({"mode": SIN, "pitch": _rand(1700.0, 1900.0), "length": 0.03, "volume": 0.50, "level": 0.71},
		[_env(0.3, 0.7, 0.0, 0.0)])
	var air: Dictionary = _layer({"mode": TRI, "pitch": 3600.0, "length": 0.02, "volume": 0.40, "level": 0.21},
		[_env(0.3, 0.7, 0.0, 0.0)])
	return _sound([tone, air], 0.0, 0.2)


static func preset_confirm() -> Dictionary:
	var root: float = _pick([784.0, 880.0, 988.0])
	var chime: Dictionary = _layer({"mode": SIN, "pitch": root, "length": 0.25, "volume": 0.70, "level": 0.37},
		[_env(0.0, 0.2, 0.6, 0.6), _arp(12.0, 7, 7, 7), _chord(12, 0, 0, 0.2)])
	var under: Dictionary = _layer({"mode": TRI, "pitch": root * 0.5, "length": 0.25, "volume": 0.50, "level": 0.15},
		[_env(0.0, 0.2, 0.6, 0.6), _arp(12.0, 7, 7, 7)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.50, "level": 0.19},
		[_filt(HP, 3000.0, 0.2)])
	return _sound([chime, under, tick], 0.12, 0.3)


static func preset_back() -> Dictionary:
	var root: float = _pick([784.0, 880.0])
	var chime: Dictionary = _layer({"mode": SIN, "pitch": root, "length": 0.22, "volume": 0.70, "level": 0.37},
		[_env(0.0, 0.2, 0.5, 0.6), _arp(12.0, -5, -5, -5)])
	var under: Dictionary = _layer({"mode": TRI, "pitch": root * 0.5, "length": 0.22, "volume": 0.50, "level": 0.15},
		[_env(0.0, 0.2, 0.5, 0.6), _arp(12.0, -5, -5, -5)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.50, "level": 0.15},
		[_filt(HP, 3000.0, 0.2)])
	return _sound([chime, under, tick], 0.1, 0.3)


static func preset_error() -> Dictionary:
	# Two low, dissonant buzzes: "bonk-bonk".
	var buzz: Dictionary = _layer({"mode": SQR, "pitch": _rand(170.0, 190.0), "voice": 2, "detune": 0.06, "length": 0.28, "volume": 0.60, "level": 0.42},
		[_pulses(7.2), _filt(LP, 1200.0, 0.3)])
	var nasal: Dictionary = _layer({"mode": SAW, "pitch": 190.0, "length": 0.28, "volume": 0.50, "level": 0.21},
		[_pulses(7.2), _filt(BP, 600.0, 0.5)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 90.0, "length": 0.28, "volume": 0.60, "level": 0.21},
		[_pulses(7.2)])
	return _sound([buzz, nasal, thump], 0.05, 0.2)


static func preset_notify() -> Dictionary:
	# Bright rising arpeggio with a bell ring.
	var chime: Dictionary = _layer({"mode": SIN, "pitch": _pick([988.0, 1047.0, 1175.0]), "length": 0.3, "volume": 0.70, "level": 0.35},
		[_env(0.0, 0.2, 0.5, 0.6), _arp(16.0, 4, 7, 12)])
	var bell: Dictionary = _layer({"mode": SIN, "pitch": 2093.0, "length": 0.5, "volume": 0.40, "level": 0.14},
		[_chord(7, 12, 0, 0.3), _echo(120.0, 0.3, 0.3)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.50, "level": 0.11},
		[_filt(HP, 3500.0, 0.2)])
	return _sound([chime, bell, tick], 0.2, 0.35)


static func preset_message() -> Dictionary:
	# Chat bubble: "bloop" then a higher "blip" at 0.09 s.
	var bloop: Dictionary = _layer({"mode": SIN, "pitch": _rand(480.0, 560.0), "length": 0.07, "volume": 0.80, "level": 0.39},
		[_bend(0.5, 1.0, 0.0)])
	var blip: Dictionary = _layer({"mode": SIN, "pitch": _rand(1000.0, 1100.0), "length": 0.5, "volume": 0.70, "level": 0.31},
		[_at(0.09, 0.5, 0.08)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.006, "volume": 0.50, "level": 0.12},
		[_filt(HP, 3000.0, 0.2)])
	return _sound([bloop, blip, tick], 0.08, 0.25)


static func preset_toggle() -> Dictionary:
	var snap: Dictionary = _layer({"mode": NSE, "length": 0.015, "volume": 0.70, "level": 0.60},
		[_filt(BP, 3000.0, 0.6)])
	var tone: Dictionary = _layer({"mode": SIN, "pitch": _rand(850.0, 950.0), "length": 0.06, "volume": 0.60, "level": 0.42},
		[_bend(0.3, 1.0, 0.0)])
	var body: Dictionary = _layer({"mode": SIN, "pitch": 250.0, "length": 0.02, "volume": 0.60, "level": 0.30})
	return _sound([snap, tone, body], 0.04, 0.2)


static func preset_key_type() -> Dictionary:
	# Mechanical keyboard: switch click, bottom-out "thock", then the
	# key's softer release.
	var release: float = _rand(60.0, 90.0)
	var click: Dictionary = _layer({"mode": NSE, "length": 0.01, "volume": 0.80, "level": 0.56},
		[_filt(BP, _rand(3000.0, 4000.0), 0.6), _echo(release, 0.4)])
	var thock: Dictionary = _layer({"mode": SIN, "pitch": _rand(350.0, 450.0), "length": 0.03, "volume": 0.80, "level": 0.45},
		[_bend(0.3, 0.0, 0.5)])
	var shell: Dictionary = _layer({"mode": PNK, "length": 0.04, "volume": 0.80, "level": 0.28},
		[_filt(BP, 900.0, 0.4)])
	return _sound([click, thock, shell], 0.04, 0.15)


static func preset_open() -> Dictionary:
	# Panel sliding open: upward swish and tone.
	var swish: Dictionary = _layer({"mode": NSE, "length": 0.22, "volume": 0.60, "level": 0.51},
		[_env(0.5, 0.5, 0.0, 0.0), _filt(BP, 800.0, 0.4, 0.6, 0.6, 0.4)])
	var tone: Dictionary = _layer({"mode": SIN, "pitch": _rand(380.0, 440.0), "length": 0.2, "volume": 0.60, "level": 0.35},
		[_env(0.3, 0.7, 0.0, 0.0), _bend(0.6, 1.0, 0.0)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.50, "level": 0.20},
		[_filt(HP, 3000.0, 0.2)])
	return _sound([swish, tone, tick], 0.1, 0.25)


static func preset_close() -> Dictionary:
	# Panel closing: downward swish, then a soft latch at 0.18 s.
	var swish: Dictionary = _layer({"mode": NSE, "length": 0.2, "volume": 0.60, "level": 0.55},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(BP, 800.0, 0.4, 0.6, 0.0, 0.8)])
	var tone: Dictionary = _layer({"mode": SIN, "pitch": _rand(380.0, 440.0), "length": 0.18, "volume": 0.60, "level": 0.38},
		[_env(0.1, 0.9, 0.0, 0.0), _bend(0.5, 0.0, 1.0)])
	var latch: Dictionary = _layer({"mode": NSE, "length": 0.8, "volume": 0.60, "level": 0.33},
		[_at(0.18, 0.8, 0.02), _filt(BP, 2500.0, 0.5)])
	return _sound([swish, tone, latch], 0.1, 0.25)
