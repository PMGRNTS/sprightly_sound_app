class_name PresetsMachine
extends PresetsHelpers

# Real machines and devices. Rotating machinery is a pulse train at the
# firing / blade rate (a sub-audio saw: one sharp edge per cycle) plus the
# resonances it excites; small mechanisms are tuned clicks.


static func preset_engine() -> Dictionary:
	# Four-cylinder idling: ~27 firings a second, a rough exhaust and a
	# ticking valve train.
	var fire: float = _rand(24.0, 30.0)
	var block: Dictionary = _layer({"mode": SAW, "pitch": fire, "length": 1.6, "volume": 1.00, "level": 0.28},
		[_env(0.1, 0.0, 1.0, 0.1), _vib(0.05, 8.0, NSE), _filt(LP, 400.0, 0.3), _drive(0.5)])
	var exhaust: Dictionary = _layer({"mode": BRN, "length": 1.6, "volume": 0.50, "level": 0.23},
		[_env(0.1, 0.0, 1.0, 0.1), _filt(BP, 150.0, 0.3), _trem(0.6, fire, SAW)])
	var valves: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.60, "level": 0.08},
		[_env(0.1, 0.0, 1.0, 0.1), _filt(BP, 3000.0, 0.4), _trem(0.6, fire * 0.5, SAW)])
	return _sound([block, exhaust, valves], 0.08, 0.3)


static func preset_rev_up() -> Dictionary:
	# Throttle blipped: revs climb, the intake roars, then fall back.
	var fire: float = _rand(24.0, 30.0)
	var block: Dictionary = _layer({"mode": SAW, "pitch": fire, "length": 1.8, "volume": 1.00, "level": 0.34},
		[_env(0.05, 0.0, 1.0, 0.15), _bend(0.9, 0.35, 0.65), _vib(0.04, 8.0, NSE), _filt(LP, 500.0, 0.3, 0.5, 0.35, 0.65), _drive(0.6)])
	var intake: Dictionary = _layer({"mode": PNK, "length": 1.8, "volume": 0.90, "level": 0.20},
		[_env(0.05, 0.0, 1.0, 0.15), _filt(BP, 600.0, 0.4, 0.6, 0.35, 0.65)])
	var whine: Dictionary = _layer({"mode": SIN, "pitch": fire * 20.0, "length": 1.8, "volume": 0.40, "level": 0.10},
		[_env(0.05, 0.0, 1.0, 0.15), _bend(0.9, 0.35, 0.65)])
	return _sound([block, intake, whine], 0.1, 0.35)


static func preset_heli() -> Dictionary:
	# Helicopter overhead: blade slaps, tail rotor buzz, turbine whine.
	var slaps: Dictionary = _layer({"mode": SAW, "pitch": _rand(5.0, 6.0), "length": 2.0, "volume": 1.00, "level": 0.76},
		[_env(0.15, 0.0, 1.0, 0.2), _filt(BP, 120.0, 0.5), _drive(0.6)])
	var wash: Dictionary = _layer({"mode": PNK, "length": 2.0, "volume": 1.00, "level": 0.46},
		[_env(0.15, 0.0, 1.0, 0.2), _filt(LP, 700.0, 0.2), _trem(0.6, 5.5, SAW)])
	var tail: Dictionary = _layer({"mode": SAW, "pitch": _rand(55.0, 65.0), "length": 2.0, "volume": 0.60, "level": 0.31},
		[_env(0.15, 0.0, 1.0, 0.2), _filt(BP, 600.0, 0.5)])
	var turbine: Dictionary = _layer({"mode": SIN, "pitch": _rand(2800.0, 3300.0), "voice": 2, "detune": 0.004, "length": 2.0, "volume": 0.30, "level": 0.23},
		[_env(0.15, 0.0, 1.0, 0.2)])
	return _sound([slaps, wash, tail, turbine], 0.15, 0.5)


static func preset_clock() -> Dictionary:
	# Tick-tock: a 1 Hz square clicks twice a cycle (tick, tock); a 1 Hz
	# saw adds a lower knock on every other one so they alternate.
	var ticks: Dictionary = _layer({"mode": SQR, "pitch": 1.0, "length": 2.2, "volume": 1.00, "level": 0.45},
		[_env(0.0, 0.0, 1.0, 0.05), _filt(BP, _rand(3200.0, 3800.0), 0.85)])
	var tocks: Dictionary = _layer({"mode": SAW, "pitch": 1.0, "length": 2.2, "volume": 1.00, "level": 0.36},
		[_env(0.0, 0.0, 1.0, 0.05), _filt(BP, _rand(1500.0, 1800.0), 0.85)])
	var housing: Dictionary = _layer({"mode": SQR, "pitch": 1.0, "length": 2.2, "volume": 1.00, "level": 0.23},
		[_env(0.0, 0.0, 1.0, 0.05), _filt(BP, 600.0, 0.7)])
	return _sound([ticks, tocks, housing], 0.15, 0.3)


static func preset_phone() -> Dictionary:
	# Old bell telephone: a hammer rattling between two gongs at ~20 Hz.
	# Each gong is two voices 20 Hz apart, so it beats at the hammer rate.
	var gong1: Dictionary = _layer({"mode": SIN, "pitch": 1100.0, "voice": 2, "detune": 0.018, "length": 1.5, "volume": 0.60, "level": 0.87},
		[_env(0.0, 0.0, 1.0, 0.12), _chord(7, 16, 0, 0.4)])
	var gong2: Dictionary = _layer({"mode": SIN, "pitch": 1400.0, "voice": 2, "detune": 0.0143, "length": 1.5, "volume": 0.50, "level": 0.70},
		[_env(0.0, 0.0, 1.0, 0.12), _chord(6, 15, 0, 0.4)])
	var hammer: Dictionary = _layer({"mode": NSE, "length": 1.5, "volume": 0.60, "level": 0.35},
		[_env(0.0, 0.0, 1.0, 0.12), _filt(BP, 3000.0, 0.5), _pulses(20.0)])
	return _sound([gong1, gong2, hammer], 0.2, 0.4)


static func preset_ding() -> Dictionary:
	# Elevator arrival chime: a soft vibraphone-like note.
	var note: float = _pick([1175.0, 1319.0, 1397.0])
	var bar: Dictionary = _layer({"mode": SIN, "pitch": note, "length": 1.6, "volume": 0.70, "level": 0.74},
		[_trem(0.3, 5.0), _chord(12, 0, 0, 0.3)])
	var body: Dictionary = _layer({"mode": TRI, "pitch": note * 0.5, "length": 1.2, "volume": 0.50, "level": 0.37},
		[_trem(0.3, 5.0)])
	var mallet: Dictionary = _layer({"mode": NSE, "length": 0.01, "volume": 0.50, "level": 0.22},
		[_filt(BP, 3000.0, 0.3)])
	return _sound([bar, body, mallet], 0.3, 0.5)


static func preset_shutter() -> Dictionary:
	# SLR camera: mirror slap and shutter, "ka-chk", then the film
	# advance whirr.
	var slap: Dictionary = _layer({"mode": NSE, "length": 0.02, "volume": 1.00, "level": 1.00},
		[_filt(BP, _rand(2200.0, 2800.0), 0.5), _echo(_rand(40.0, 55.0), 0.8)])
	var body: Dictionary = _layer({"mode": SIN, "pitch": 300.0, "length": 0.03, "volume": 0.80, "level": 0.92},
		[_echo(48.0, 0.8)])
	var spring: Dictionary = _layer({"mode": SIN, "pitch": _rand(3500.0, 4000.0), "length": 0.08, "volume": 0.40, "level": 0.45},
		[_chord(5, 11, 0, 0.5)])
	var winder: Dictionary = _layer({"mode": SAW, "pitch": 180.0, "length": 1.2, "volume": 0.60, "level": 0.60},
		[_at(0.15, 1.2, 0.14), _filt(BP, 2000.0, 0.5), _vib(0.05, 30.0, NSE)])
	return _sound([slap, body, spring, winder], 0.06, 0.2)


static func preset_switch() -> Dictionary:
	# Wall light switch: plastic snap with a spring ping.
	var snap: Dictionary = _layer({"mode": NSE, "length": 0.015, "volume": 1.00, "level": 0.66},
		[_filt(BP, _rand(1900.0, 2500.0), 0.6)])
	var click: Dictionary = _layer({"mode": SIN, "pitch": 1600.0, "length": 0.01, "volume": 0.70, "level": 0.40})
	var body: Dictionary = _layer({"mode": SIN, "pitch": 180.0, "length": 0.025, "volume": 0.80, "level": 0.40})
	var ping: Dictionary = _layer({"mode": SIN, "pitch": _rand(3500.0, 4000.0), "length": 0.08, "volume": 0.40, "level": 0.16},
		[_chord(6, 13, 0, 0.5)])
	return _sound([snap, click, body, ping], 0.08, 0.15)


static func preset_drill() -> Dictionary:
	# Cordless drill: spins up, whines, gears chattering.
	var motor: Dictionary = _layer({"mode": SAW, "pitch": _rand(260.0, 300.0), "voice": 2, "detune": 0.008, "length": 1.6, "volume": 0.70, "level": 0.85},
		[_env(0.03, 0.0, 1.0, 0.15), _bend(-0.6, 0.0, 0.25), _filt(BP, 1800.0, 0.4)])
	# Gear teeth: one click per saw cycle, spinning up with the motor.
	var gears: Dictionary = _layer({"mode": SAW, "pitch": 140.0, "length": 1.6, "volume": 0.60, "level": 0.42},
		[_env(0.03, 0.0, 1.0, 0.15), _bend(-0.6, 0.0, 0.25), _filt(BP, 3500.0, 0.4)])
	var brushes: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.50, "level": 0.25},
		[_env(0.03, 0.0, 1.0, 0.15), _filt(HP, 6000.0, 0.2)])
	var body: Dictionary = _layer({"mode": SQR, "pitch": _rand(130.0, 150.0), "length": 1.6, "volume": 0.40, "level": 0.34},
		[_env(0.03, 0.0, 1.0, 0.15), _bend(-0.6, 0.0, 0.25), _filt(LP, 500.0, 0.3)])
	return _sound([motor, gears, brushes, body], 0.1, 0.3)


static func preset_steam() -> Dictionary:
	# A valve venting steam: hard hiss, rumbling pipe, a thin whistle.
	var hiss: Dictionary = _layer({"mode": NSE, "length": _rand(1.3, 1.7), "volume": 1.00, "level": 0.68},
		[_env(0.02, 0.2, 0.6, 0.5), _filt(HP, 2000.0, 0.3, -0.2, 0.0, 1.0), _trem(0.3, 15.0, NSE)])
	var rumble: Dictionary = _layer({"mode": PNK, "length": 1.5, "volume": 0.80, "level": 0.41},
		[_env(0.02, 0.2, 0.6, 0.5), _filt(BP, 700.0, 0.3)])
	var whistle: Dictionary = _layer({"mode": SIN, "pitch": _rand(2400.0, 2900.0), "length": 1.5, "volume": 0.40, "level": 0.21},
		[_env(0.05, 0.2, 0.5, 0.5), _vib(0.01, 7.0)])
	return _sound([hiss, rumble, whistle], 0.2, 0.45)
