class_name PresetsFirearm
extends PresetsHelpers

# Guns, ammo handling and explosives. A shot is built the way it is in a
# real recording: a broadband crack (the muzzle blast / supersonic snap),
# a low pitched boom, a filtered noise body that darkens as it dies, and
# a mechanical layer (slide, bolt, pump) that sells the weapon's action.


static func preset_pistol() -> Dictionary:
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.035, "volume": 1.00, "level": 0.37},
		[_filt(HP, _rand(1600.0, 2400.0), 0.15), _drive(0.5)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(50.0, 62.0), "length": 0.18, "volume": 0.90, "level": 0.41},
		[_bend(0.6, 0.0, 0.35), _drive(0.6)])
	# Body: noise whose lowpass slams shut — bright blast, dark decay.
	var body: Dictionary = _layer({"mode": NSE, "length": 0.3, "volume": 0.80, "level": 0.33},
		[_filt(LP, _rand(700.0, 1100.0), 0.2, 1.0, 0.0, 0.25)])
	# Slide cycling: a resonant metallic "ch-chk".
	var action: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.80, "level": 0.14},
		[_filt(BP, _rand(3200.0, 3800.0), 0.7), _echo(55.0, 1.0, 0.35)])
	return _sound([crack, boom, body, action], 0.18, 0.35)


static func preset_rifle() -> Dictionary:
	# Supersonic snap: shorter and brighter than a pistol's crack.
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.025, "volume": 1.00, "level": 0.35},
		[_filt(HP, _rand(2600.0, 3400.0), 0.1), _drive(0.7)])
	var blast: Dictionary = _layer({"mode": NSE, "length": 0.14, "volume": 0.90, "level": 0.28},
		[_filt(LP, 2200.0, 0.2, 0.6, 0.0, 0.3), _drive(0.5)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(44.0, 52.0), "length": 0.3, "volume": 0.90, "level": 0.35},
		[_bend(0.7, 0.0, 0.3), _drive(0.7), _filt(LP, 400.0, 0.1)])
	# Tail: the shot slapping back off nearby walls.
	var tail: Dictionary = _layer({"mode": NSE, "length": 0.9, "volume": 0.70, "level": 0.21},
		[_filt(LP, 500.0, 0.1, 0.8, 0.0, 0.3), _echo(_rand(100.0, 140.0), 0.35, 0.3)])
	return _sound([crack, blast, boom, tail], 0.22, 0.5)


static func preset_shotgun() -> Dictionary:
	var blast: Dictionary = _layer({"mode": NSE, "length": 0.09, "volume": 1.00, "level": 0.46},
		[_filt(LP, 3500.0, 0.1), _drive(0.8)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(38.0, 46.0), "length": 0.4, "volume": 1.00, "level": 0.46},
		[_bend(0.8, 0.0, 0.35), _drive(0.8)])
	var tail: Dictionary = _layer({"mode": NSE, "length": 0.7, "volume": 0.80, "level": 0.32},
		[_filt(LP, 450.0, 0.15, 0.9, 0.0, 0.25), _echo(140.0, 0.3, 0.25)])
	# Pump rack, delayed to land after the blast: two clicks 40 ms apart.
	var pump: Dictionary = _layer({"mode": NSE, "length": 0.09, "volume": 0.90, "level": 0.25},
		[_filt(BP, _rand(1900.0, 2400.0), 0.55), _pulses(25.0), _echo(_rand(430.0, 480.0), 1.0)])
	return _sound([blast, boom, tail, pump], 0.25, 0.45)


static func preset_sniper() -> Dictionary:
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.02, "volume": 1.00, "level": 0.39},
		[_filt(HP, 3500.0, 0.1), _drive(0.8)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(36.0, 42.0), "length": 0.5, "volume": 1.00, "level": 0.39},
		[_bend(0.9, 0.0, 0.3), _drive(0.8)])
	var body: Dictionary = _layer({"mode": NSE, "length": 0.25, "volume": 0.90, "level": 0.29},
		[_filt(LP, 1500.0, 0.15, 0.8, 0.0, 0.2)])
	# Distant echo off a far hillside: arrives ~0.4 s later, duller each pass.
	var echo: Dictionary = _layer({"mode": NSE, "length": 0.35, "volume": 0.80, "level": 0.19},
		[_filt(LP, 700.0, 0.1, 0.5, 0.0, 0.3), _echo(_rand(380.0, 460.0), 1.0, 0.35)])
	return _sound([crack, boom, body, echo], 0.3, 0.8)


static func preset_smg() -> Dictionary:
	# Every layer shares the same pulse rate, so each round lines up.
	var rate: float = _rand(13.0, 16.0)
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.9, "volume": 1.00, "level": 0.41},
		[_env(0.0, 0.5, 0.0, 0.0), _filt(HP, 1800.0, 0.15), _drive(0.5), _pulses(rate)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": _rand(62.0, 72.0), "length": 0.9, "volume": 0.90, "level": 0.51},
		[_env(0.0, 0.5, 0.0, 0.0), _drive(0.7), _pulses(rate)])
	var bolt: Dictionary = _layer({"mode": NSE, "length": 0.9, "volume": 0.80, "level": 0.15},
		[_env(0.0, 0.5, 0.0, 0.0), _filt(BP, 3400.0, 0.7), _pulses(rate)])
	# Ungated low roar that builds under the burst, as reflections pile up.
	var roar: Dictionary = _layer({"mode": NSE, "length": 0.8, "volume": 0.70, "level": 0.28},
		[_env(0.1, 0.3, 0.4, 0.5), _filt(LP, 600.0, 0.2)])
	return _sound([crack, thump, bolt, roar], 0.22, 0.4)


static func preset_suppressed() -> Dictionary:
	# A suppressor leaves a soft "thwip" — the gun's action becomes the
	# loudest part of the shot.
	var thwip: Dictionary = _layer({"mode": NSE, "length": 0.06, "volume": 1.00, "level": 0.75},
		[_filt(BP, _rand(900.0, 1300.0), 0.35, -0.4, 0.0, 0.6)])
	var puff: Dictionary = _layer({"mode": SIN, "pitch": 90.0, "length": 0.07, "volume": 0.70, "level": 0.73},
		[_bend(0.5, 0.0, 0.5)])
	var slide: Dictionary = _layer({"mode": NSE, "length": 0.035, "volume": 1.00, "level": 0.75},
		[_filt(BP, _rand(3400.0, 4200.0), 0.75), _echo(45.0, 0.8, 0.2)])
	# Spent casing hitting the floor and bouncing.
	var casing: Dictionary = _layer({"mode": SIN, "pitch": _rand(2400.0, 2800.0), "length": 0.06, "volume": 0.50, "level": 0.30},
		[_chord(12, 17, 23, 0.6), _echo(_rand(340.0, 420.0), 1.0, 0.3)])
	return _sound([thwip, puff, slide, casing], 0.12, 0.3)


static func preset_empty() -> Dictionary:
	# Trigger pull, then the striker snapping forward on nothing.
	var trigger: Dictionary = _layer({"mode": NSE, "length": 0.02, "volume": 0.60, "level": 0.48},
		[_filt(BP, 1800.0, 0.5)])
	var striker: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.90, "level": 0.80},
		[_filt(BP, _rand(3800.0, 4600.0), 0.8), _echo(_rand(60.0, 80.0), 1.0)])
	var body: Dictionary = _layer({"mode": SIN, "pitch": 190.0, "length": 0.03, "volume": 0.70, "level": 0.41},
		[_echo(70.0, 1.0)])
	return _sound([trigger, striker, body], 0.06, 0.15)


static func preset_reload() -> Dictionary:
	# Mag release click, mag sliding out, new mag clacking home (~0.3 s),
	# slide racked (~0.5 s). Delayed layers also tick quietly at t=0,
	# under the release click.
	var release: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 1.00, "level": 0.86},
		[_filt(BP, 3000.0, 0.6)])
	var slide_out: Dictionary = _layer({"mode": NSE, "length": 0.18, "volume": 0.60, "level": 0.65},
		[_env(0.3, 0.7, 0.0, 0.0), _filt(BP, 1800.0, 0.3, 0.3, 0.3, 0.7)])
	var insert: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 1.00, "level": 0.86},
		[_filt(BP, _rand(1300.0, 1700.0), 0.4), _drive(0.5), _echo(_rand(280.0, 330.0), 1.0)])
	var rack: Dictionary = _layer({"mode": NSE, "length": 0.08, "volume": 1.00, "level": 0.86},
		[_filt(BP, _rand(2600.0, 3200.0), 0.6), _pulses(25.0), _echo(_rand(470.0, 500.0), 1.0)])
	return _sound([release, slide_out, insert, rack], 0.08, 0.2)


static func preset_casings() -> Dictionary:
	# Three brass casings with inharmonic partials, each bouncing on its
	# own rhythm so the pattern never sounds mechanical.
	var a: Dictionary = _layer({"mode": SIN, "pitch": _rand(2200.0, 2500.0), "length": 0.12, "volume": 0.60, "level": 0.81},
		[_chord(12, 18, 23, 0.7), _echo(_rand(150.0, 180.0), 0.9, 0.55)])
	var b: Dictionary = _layer({"mode": SIN, "pitch": _rand(2900.0, 3200.0), "length": 0.09, "volume": 0.60, "level": 0.65},
		[_chord(12, 17, 24, 0.7), _echo(_rand(210.0, 250.0), 0.9, 0.5)])
	var c: Dictionary = _layer({"mode": SIN, "pitch": _rand(3600.0, 4000.0), "length": 0.1, "volume": 0.60, "level": 0.57},
		[_chord(7, 10, 15, 0.7), _echo(_rand(110.0, 130.0), 0.8, 0.45)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.015, "volume": 0.60, "level": 0.40},
		[_filt(HP, 5000.0, 0.2), _echo(160.0, 0.8, 0.5)])
	return _sound([a, b, c, tick], 0.15, 0.3)


static func preset_ricochet() -> Dictionary:
	var hit: Dictionary = _layer({"mode": NSE, "length": 0.04, "volume": 1.00, "level": 0.71},
		[_filt(BP, 1400.0, 0.3), _drive(0.5)])
	# Whine: a tumbling slug falling in pitch as it flies off.
	var whine: Dictionary = _layer({"mode": SIN, "pitch": _rand(2600.0, 3400.0), "length": _rand(0.5, 0.7), "volume": 0.60, "level": 0.89},
		[_env(0.0, 1.0, 0.0, 0.0), _bend(0.4, 0.0, 1.0), _vib(0.03, 28.0)])
	var air: Dictionary = _layer({"mode": NSE, "length": 0.5, "volume": 0.60, "level": 0.36},
		[_filt(BP, 3000.0, 0.6, 0.4, 0.0, 1.0)])
	return _sound([hit, whine, air], 0.25, 0.6)


static func preset_flyby() -> Dictionary:
	# Near miss: the supersonic snap arrives first, then the whiz of the
	# slug passing, falling in pitch (Doppler).
	var snap: Dictionary = _layer({"mode": NSE, "length": 0.015, "volume": 0.90, "level": 0.37},
		[_filt(HP, 3000.0, 0.1)])
	var whiz: Dictionary = _layer({"mode": NSE, "length": 0.32, "volume": 0.90, "level": 0.53},
		[_env(0.45, 0.55, 0.0, 0.0), _filt(BP, 2400.0, 0.6, 0.5, 0.45, 0.55)])
	var tone: Dictionary = _layer({"mode": SIN, "pitch": _rand(1300.0, 1700.0), "length": 0.32, "volume": 0.50, "level": 0.24},
		[_env(0.45, 0.55, 0.0, 0.0), _bend(0.3, 0.0, 1.0)])
	return _sound([snap, whiz, tone], 0.1, 0.3)


static func preset_grenade() -> Dictionary:
	var crack: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 1.00, "level": 0.36},
		[_filt(HP, 1200.0, 0.1), _drive(0.8)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": _rand(34.0, 42.0), "length": 0.7, "volume": 1.00, "level": 0.40},
		[_bend(0.9, 0.0, 0.25), _drive(0.9), _filt(LP, 300.0, 0.1)])
	# Fireball: noise that starts wide open and darkens.
	var blast: Dictionary = _layer({"mode": PNK, "length": 1.6, "volume": 1.00, "level": 0.36},
		[_filt(LP, 300.0, 0.1, 1.0, 0.0, 0.2), _drive(0.5)])
	# Debris raining down: sparse, irregular clicks that fade in after.
	var debris: Dictionary = _layer({"mode": SQR, "pitch": 6.0, "voice": 4, "detune": 0.2, "length": 1.4, "volume": 1.00, "level": 0.24},
		[_env(0.15, 0.85, 0.0, 0.0), _vib(0.5, 1.3), _filt(BP, 1800.0, 0.3)])
	return _sound([crack, boom, blast, debris], 0.3, 0.7)


static func preset_distant() -> Dictionary:
	# Far-off explosion or artillery: highs gone, a long rolling rumble.
	var thump: Dictionary = _layer({"mode": SIN, "pitch": _rand(32.0, 38.0), "length": 0.9, "volume": 1.00, "level": 0.50},
		[_env(0.02, 0.98, 0.0, 0.0), _bend(0.5, 0.0, 0.4), _drive(0.4), _filt(LP, 150.0, 0.1)])
	var rumble: Dictionary = _layer({"mode": PNK, "length": 2.2, "volume": 1.00, "level": 0.50},
		[_env(0.03, 0.97, 0.0, 0.0), _filt(LP, 160.0, 0.2, 0.6, 0.05, 0.4)])
	# Terrain echoes rolling back in.
	var roll: Dictionary = _layer({"mode": PNK, "length": 0.8, "volume": 0.90, "level": 0.35},
		[_filt(LP, 250.0, 0.1), _echo(_rand(400.0, 480.0), 0.8, 0.45)])
	return _sound([thump, rumble, roll], 0.4, 0.75)


static func preset_pin_pull() -> Dictionary:
	# Pin dragged out of the fuse, then the spoon flying off with a ping.
	var scrape: Dictionary = _layer({"mode": NSE, "length": 0.1, "volume": 0.82, "level": 0.60},
		[_env(0.4, 0.6, 0.0, 0.0), _filt(BP, 4200.0, 0.6, 0.2, 0.5, 0.5)])
	var pull: Dictionary = _layer({"mode": NSE, "length": 0.025, "volume": 1.00, "level": 0.60},
		[_filt(BP, 2600.0, 0.6), _echo(110.0, 1.0)])
	var ping: Dictionary = _layer({"mode": SIN, "pitch": _rand(2800.0, 3300.0), "length": 0.35, "volume": 0.70, "level": 0.60},
		[_chord(6, 13, 19, 0.6), _vib(0.01, 20.0), _echo(_rand(260.0, 320.0), 1.0)])
	return _sound([scrape, pull, ping], 0.12, 0.3)
