class_name PresetsScifi
extends PresetsHelpers

# Science-fiction weapons and ship systems. The classic blaster "pew" is
# a fast, steep downward pitch sweep (a struck, tensioned wire); beams
# and fields are detuned saws with fast modulation; ship systems lean
# on hum, servo whine and pneumatics.


static func preset_blaster() -> Dictionary:
	var pew: Dictionary = _layer({"mode": SIN, "pitch": _rand(600.0, 800.0), "length": 0.3, "volume": 0.90, "level": 0.46},
		[_bend(1.0, 0.0, 0.4), _drive(0.3)])
	# Spring-like dispersive zing trailing off.
	var zing: Dictionary = _layer({"mode": SAW, "pitch": _rand(800.0, 1000.0), "length": 0.3, "volume": 0.60, "level": 0.23},
		[_bend(0.8, 0.0, 0.6), _filt(BP, 2000.0, 0.5, 0.5, 0.0, 0.5), _echo(45.0, 0.4, 0.4)])
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.90, "level": 0.27},
		[_filt(HP, 2500.0, 0.2)])
	var body: Dictionary = _layer({"mode": SIN, "pitch": 120.0, "length": 0.1, "volume": 0.80, "level": 0.23},
		[_bend(0.6, 0.0, 0.5)])
	return _sound([pew, zing, crack, body], 0.15, 0.35)


static func preset_laser() -> Dictionary:
	# A sustained beam: buzzing core, piercing whine, ionised sizzle.
	var core: Dictionary = _layer({"mode": SAW, "pitch": _rand(200.0, 240.0), "voice": 3, "detune": 0.03, "length": 0.7, "volume": 0.92, "level": 1.00},
		[_env(0.03, 0.2, 0.7, 0.2), _vib(0.02, 30.0), _trem(0.4, 30.0), _filt(BP, 1500.0, 0.5, 0.4, 0.0, 0.5)])
	var whine: Dictionary = _layer({"mode": SIN, "pitch": _rand(3200.0, 3800.0), "length": 0.7, "volume": 0.50, "level": 0.66},
		[_env(0.03, 0.2, 0.7, 0.2), _vib(0.01, 13.0)])
	var sizzle: Dictionary = _layer({"mode": NSE, "length": 0.7, "volume": 0.60, "level": 0.53},
		[_env(0.03, 0.2, 0.7, 0.2), _filt(HP, 5000.0, 0.2), _trem(0.8, 25.0, NSE)])
	var ignite: Dictionary = _layer({"mode": SIN, "pitch": 900.0, "length": 0.12, "volume": 0.70, "level": 0.66},
		[_bend(0.6, 0.0, 0.6)])
	return _sound([core, whine, sizzle, ignite], 0.15, 0.35)


static func preset_plasma() -> Dictionary:
	# Heavy plasma bolt: a thick "thoom", crackle and falling whine.
	var thoom: Dictionary = _layer({"mode": SIN, "pitch": _rand(70.0, 90.0), "length": 0.45, "volume": 1.00, "level": 0.36},
		[_bend(0.8, 0.0, 0.3), _drive(0.7)])
	var blast: Dictionary = _layer({"mode": NSE, "length": 0.3, "volume": 0.90, "level": 0.26},
		[_filt(LP, 1200.0, 0.4, 0.6, 0.0, 0.4), _drive(0.5)])
	var whine: Dictionary = _layer({"mode": SAW, "pitch": _rand(700.0, 900.0), "voice": 2, "detune": 0.03, "length": 0.5, "volume": 0.50, "level": 0.18},
		[_bend(0.7, 0.0, 1.0), _filt(LP, 2500.0, 0.4)])
	var sizzle: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 0.60, "level": 0.14},
		[_filt(HP, 4000.0, 0.3), _pulses(_rand(24.0, 30.0), 0.7)])
	return _sound([thoom, blast, whine, sizzle], 0.2, 0.45)


static func preset_railgun() -> Dictionary:
	# Capacitors whining up, then the slug leaving with a crack at 0.6 s.
	var charge: Dictionary = _layer({"mode": SIN, "pitch": _rand(300.0, 400.0), "voice": 2, "detune": 0.01, "length": 0.6, "volume": 0.60, "level": 0.40},
		[_env(0.9, 0.1, 0.0, 0.0), _bend(0.8, 1.0, 0.0), _trem(0.4, 30.0)])
	var crack: Dictionary = _layer({"mode": NSE, "length": 2.2, "volume": 1.00, "level": 0.40},
		[_at(0.6, 2.2, 0.12), _filt(HP, 1500.0, 0.2), _drive(0.9)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": 55.0, "length": 2.2, "volume": 1.00, "level": 0.32},
		[_at(0.6, 2.2, 0.4), _drive(0.6)])
	var ring: Dictionary = _layer({"mode": SIN, "pitch": _rand(1100.0, 1300.0), "length": 2.2, "volume": 0.50, "level": 0.16},
		[_at(0.6, 2.2, 0.55), _chord(7, 17, 22, 0.5)])
	return _sound([charge, crack, boom, ring], 0.3, 0.6)


static func preset_forcefield() -> Dictionary:
	# Humming energy barrier with stray discharges.
	var hum: Dictionary = _layer({"mode": SAW, "pitch": _rand(55.0, 65.0), "voice": 3, "detune": 0.01, "length": 1.6, "volume": 1.00, "level": 1.00},
		[_env(0.15, 0.0, 1.0, 0.25), _chord(12, 19, 0, 0.5), _filt(BP, 400.0, 0.5), _trem(0.3, 7.0)])
	var shimmer: Dictionary = _layer({"mode": SIN, "pitch": _rand(1800.0, 2200.0), "voice": 4, "detune": 0.02, "length": 1.6, "volume": 0.40, "level": 0.64},
		[_env(0.2, 0.0, 1.0, 0.25), _trem(0.5, 11.0)])
	var discharge: Dictionary = _layer({"mode": SQR, "pitch": 5.0, "voice": 4, "detune": 0.2, "length": 1.6, "volume": 1.00, "level": 0.80},
		[_env(0.15, 0.0, 1.0, 0.25), _vib(0.6, 1.1), _filt(HP, 3000.0, 0.5)])
	return _sound([hum, shimmer, discharge], 0.2, 0.5)


static func preset_scanner() -> Dictionary:
	# Sweeping scan beam plus data chirps.
	var sweep: Dictionary = _layer({"mode": SIN, "pitch": _rand(1000.0, 1300.0), "length": 1.6, "volume": 0.60, "level": 0.72},
		[_env(0.1, 0.0, 1.0, 0.15), _vib(0.3, _rand(1.2, 1.8), TRI), _trem(0.3, 24.0)])
	var beam: Dictionary = _layer({"mode": SAW, "pitch": 160.0, "voice": 2, "detune": 0.01, "length": 1.6, "volume": 0.50, "level": 0.36},
		[_env(0.1, 0.0, 1.0, 0.15), _filt(BP, 900.0, 0.7, 0.5, 0.5, 0.5)])
	var data: Dictionary = _layer({"mode": SQR, "pitch": _rand(2000.0, 2400.0), "length": 1.6, "volume": 0.30, "level": 0.29},
		[_env(0.1, 0.0, 1.0, 0.15), _arp(14.0, 7, -5, 12), _pulses(14.0, 0.8), _filt(LP, 4000.0, 0.2)])
	return _sound([sweep, beam, data], 0.2, 0.45)


static func preset_power_down() -> Dictionary:
	# Relay clunk, then everything sags and dies.
	var clunk: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 1.00, "level": 0.57},
		[_filt(BP, 1200.0, 0.4), _drive(0.5)])
	var whine: Dictionary = _layer({"mode": SAW, "pitch": _rand(380.0, 440.0), "voice": 2, "detune": 0.01, "length": _rand(1.4, 1.8), "volume": 0.70, "level": 0.81},
		[_env(0.0, 0.3, 0.6, 0.7), _bend(1.0, 0.0, 1.0), _filt(LP, 900.0, 0.4, 1.0, 0.0, 1.0)])
	var hum: Dictionary = _layer({"mode": SAW, "pitch": 60.0, "voice": 2, "detune": 0.01, "length": 1.6, "volume": 0.70, "level": 0.49},
		[_bend(0.5, 0.0, 1.0), _filt(LP, 400.0, 0.3)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 45.0, "length": 1.0, "volume": 0.80, "level": 0.41},
		[_bend(0.5, 0.0, 1.0)])
	return _sound([clunk, whine, hum, sub], 0.25, 0.55)


static func preset_warp() -> Dictionary:
	# Hyperspace jump: a long rising roar, then the jump at 1 s.
	var roar: Dictionary = _layer({"mode": PNK, "length": 1.0, "volume": 1.00, "level": 0.46},
		[_env(0.9, 0.1, 0.0, 0.0), _filt(LP, 200.0, 0.4, 0.9, 1.0, 0.0), _flange(0.7, 1.5, 0.6, 0.5)])
	var rise: Dictionary = _layer({"mode": SAW, "pitch": _rand(55.0, 70.0), "voice": 3, "detune": 0.03, "length": 1.0, "volume": 0.60, "level": 0.27},
		[_env(0.9, 0.1, 0.0, 0.0), _bend(1.0, 1.0, 0.0), _filt(LP, 400.0, 0.4, 0.8, 1.0, 0.0)])
	var jump: Dictionary = _layer({"mode": SIN, "pitch": 50.0, "length": 3.0, "volume": 1.00, "level": 0.46},
		[_at(1.0, 3.0, 0.8), _drive(0.7)])
	var trail: Dictionary = _layer({"mode": NSE, "length": 3.0, "volume": 0.90, "level": 0.27},
		[_at(1.0, 3.0, 0.9), _filt(BP, 1500.0, 0.5, -0.2, 0.25, 0.25)])
	return _sound([roar, rise, jump, trail], 0.3, 0.6)


static func preset_airlock() -> Dictionary:
	# Seal unlatching, a long pneumatic hiss, servos dragging the door.
	var latch: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 1.00, "level": 0.51},
		[_filt(BP, 900.0, 0.5), _drive(0.4)])
	var thunk: Dictionary = _layer({"mode": SIN, "pitch": 110.0, "length": 0.12, "volume": 0.90, "level": 0.51},
		[_bend(0.3, 0.0, 0.4)])
	var hiss: Dictionary = _layer({"mode": NSE, "length": _rand(1.1, 1.4), "volume": 0.90, "level": 0.73},
		[_env(0.02, 0.3, 0.5, 0.5), _filt(HP, 2500.0, 0.3, -0.3, 0.0, 1.0)])
	var servo: Dictionary = _layer({"mode": SAW, "pitch": _rand(160.0, 200.0), "voice": 2, "detune": 0.01, "length": 1.2, "volume": 0.50, "level": 0.29},
		[_env(0.2, 0.2, 0.6, 0.2), _bend(0.3, 0.3, 0.7), _filt(BP, 1200.0, 0.5)])
	return _sound([latch, thunk, hiss, servo], 0.3, 0.55)


static func preset_servo() -> Dictionary:
	# Robot joint moving: motor whine up and back down, gear chatter,
	# then a stop click at 0.4 s.
	var motor: Dictionary = _layer({"mode": SAW, "pitch": _rand(350.0, 450.0), "voice": 2, "detune": 0.01, "length": 0.4, "volume": 0.7},
		[_env(0.1, 0.0, 1.0, 0.1), _bend(0.3, 0.4, 0.6), _filt(BP, 1500.0, 0.5)])
	# Gear teeth: one click per saw cycle.
	var gears: Dictionary = _layer({"mode": SAW, "pitch": _rand(70.0, 90.0), "length": 0.4, "volume": 0.6, "level": 0.5},
		[_env(0.1, 0.0, 1.0, 0.1), _filt(BP, 3000.0, 0.4)])
	var stop: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.9, "level": 0.6},
		[_at(0.4, 1.6, 0.03), _filt(BP, 2200.0, 0.6)])
	return _sound([motor, gears, stop], 0.15, 0.3)


static func preset_computer() -> Dictionary:
	# Mainframe chatter: two streams of data blips over a low hum.
	var r1: float = _rand(10.0, 13.0)
	var r2: float = _rand(7.5, 9.5)
	var blips: Dictionary = _layer({"mode": SQR, "pitch": _rand(1000.0, 1300.0), "length": 1.6, "volume": 0.40, "level": 0.82},
		[_env(0.02, 0.0, 1.0, 0.1), _arp(r1, 7, -5, 12), _pulses(r1, 0.8), _filt(LP, 3000.0, 0.2)])
	var tones: Dictionary = _layer({"mode": SIN, "pitch": _rand(1800.0, 2200.0), "length": 1.6, "volume": 0.50, "level": 0.49},
		[_env(0.02, 0.0, 1.0, 0.1), _arp(r2, -3, 4, 9), _pulses(r2, 0.9)])
	var hum: Dictionary = _layer({"mode": SAW, "pitch": 60.0, "length": 1.6, "volume": 0.50, "level": 0.25},
		[_env(0.1, 0.0, 1.0, 0.1), _filt(LP, 300.0, 0.2)])
	return _sound([blips, tones, hum], 0.12, 0.3)


static func preset_klaxon() -> Dictionary:
	# Red alert: a whooping siren echoing down steel corridors.
	var rate: float = _rand(1.4, 1.8)
	var whoop: Dictionary = _layer({"mode": SAW, "pitch": _rand(450.0, 520.0), "voice": 2, "detune": 0.01, "length": 2.0, "volume": 0.60, "level": 0.83},
		[_env(0.02, 0.0, 1.0, 0.1), _vib(0.3, rate, SAW), _drive(0.4), _filt(BP, 1200.0, 0.4)])
	var horn: Dictionary = _layer({"mode": SQR, "pitch": 250.0, "length": 2.0, "volume": 0.40, "level": 0.41},
		[_env(0.02, 0.0, 1.0, 0.1), _vib(0.3, rate, SAW), _filt(LP, 1500.0, 0.3)])
	return _sound([whoop, horn], 0.4, 0.65)
