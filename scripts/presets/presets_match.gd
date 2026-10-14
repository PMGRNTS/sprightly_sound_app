class_name PresetsMatch
extends PresetsHelpers

# Competitive-match cues: objective events (hill / point / flag / bomb),
# round flow, combat feedback and map events. They have to read
# instantly over gunfire, so each has one clear identity — rising major
# for good news, falling minor for bad, dissonant pulses for "contested"
# — and a crisp transient so it cuts through a busy mix. Chord stingers
# play one channel per chord tone with a shared arp, so every voice
# changes chord on the same beat.


# ── Objectives ─────────────────────────────────────────────────────

static func preset_captured() -> Dictionary:
	# Hill / point captured: a quick brass run up the major chord, landing
	# on a bell and a cymbal at 0.3 s while a chord blooms underneath.
	var root: float = _pick([523.0, 587.0])
	var run: Dictionary = _layer({"mode": SAW, "pitch": root, "voice": 2, "detune": 0.006, "length": 0.42, "volume": 0.60, "level": 0.84},
		[_env(0.0, 0.0, 1.0, 0.15), _arp(13.3, 4, 7, 12), _filt(LP, 2400.0, 0.3, 0.3, 0.0, 0.6)])
	var bloom: Dictionary = _layer({"mode": SAW, "pitch": root, "voice": 3, "detune": 0.008, "length": 1.4, "volume": 0.50, "level": 0.50},
		[_env(0.22, 0.2, 0.6, 0.4), _chord(4, 7, 12, 0.6), _filt(LP, 1800.0, 0.3, 0.4, 0.25, 0.7)])
	var bell: Dictionary = _layer({"mode": SIN, "pitch": root * 4.0, "length": 1.4, "volume": 0.60, "level": 0.50},
		[_at(0.3, 1.4, 0.3), _chord(12, 19, 0, 0.3)])
	var crash: Dictionary = _layer({"mode": NSE, "length": 1.4, "volume": 0.60, "level": 0.37},
		[_at(0.3, 1.4, 0.3), _filt(HP, 5000.0, 0.2)])
	return _sound([run, bloom, bell, crash], 0.35, 0.55)


static func preset_capturing() -> Dictionary:
	# Capture in progress, one second long — loop it while the player
	# holds the point. Tremolo depth always fades, so the steady 8 Hz
	# pulse comes from elsewhere: a sub-audio saw pings a resonant
	# bandpass once per cycle, and two detuned voices beat at 8 Hz.
	var ticks: Dictionary = _layer({"mode": SAW, "pitch": 8.0, "length": 1.0, "volume": 0.80, "level": 0.40},
		[_env(0.01, 0.0, 1.0, 0.01), _filt(BP, 1320.0, 0.95)])
	var pad: Dictionary = _layer({"mode": SIN, "pitch": 330.0, "voice": 2, "detune": 0.0242, "length": 1.0, "volume": 0.60, "level": 0.36},
		[_env(0.01, 0.0, 1.0, 0.01)])
	# No chord on loop layers: its upward copies are time-compressed and
	# would drop out halfway through the loop.
	var hum: Dictionary = _layer({"mode": TRI, "pitch": 165.0, "length": 1.0, "volume": 0.50, "level": 0.20},
		[_env(0.01, 0.0, 1.0, 0.01), _filt(LP, 800.0, 0.2)])
	return _sound([ticks, pad, hum], 0.0, 0.3)


static func preset_contested() -> Dictionary:
	# Point contested: a tritone warble over a throbbing buzz, with a
	# ticking edge. One second long and loopable — every rate divides it.
	var warble: Dictionary = _layer({"mode": SQR, "pitch": 622.0, "length": 1.0, "volume": 0.60, "level": 0.40},
		[_env(0.01, 0.0, 1.0, 0.01), _arp(6.0, 6, 0, 6), _filt(BP, 1400.0, 0.4)])
	var buzz: Dictionary = _layer({"mode": SAW, "pitch": 155.0, "voice": 2, "detune": 0.0387, "length": 1.0, "volume": 0.60, "level": 0.36},
		[_env(0.01, 0.0, 1.0, 0.01), _filt(LP, 900.0, 0.4)])
	var edge: Dictionary = _layer({"mode": SAW, "pitch": 6.0, "length": 1.0, "volume": 0.80, "level": 0.30},
		[_env(0.01, 0.0, 1.0, 0.01), _filt(BP, 2500.0, 0.9)])
	return _sound([warble, buzz, edge], 0.0, 0.3)


static func preset_point_lost() -> Dictionary:
	# Point lost: brass falling down the minor chord (5 → ♭3 → 1) over a
	# sinking low note.
	var root: float = _pick([784.0, 698.0])
	var fall: Dictionary = _layer({"mode": SAW, "pitch": root * 0.5, "voice": 2, "detune": 0.008, "length": 0.8, "volume": 0.70, "level": 0.65},
		[_env(0.0, 0.1, 0.7, 0.4), _arp(9.0, -4, -7, -7), _filt(LP, 1600.0, 0.3, -0.3, 0.0, 1.0)])
	var low: Dictionary = _layer({"mode": SAW, "pitch": root * 0.25, "voice": 2, "detune": 0.01, "length": 0.8, "volume": 0.60, "level": 0.48},
		[_env(0.02, 0.2, 0.6, 0.4), _bend(-0.15, 1.0, 0.0), _filt(LP, 700.0, 0.3)])
	var thud: Dictionary = _layer({"mode": SIN, "pitch": 70.0, "length": 0.25, "volume": 0.80, "level": 0.42},
		[_bend(0.4, 0.0, 0.4)])
	return _sound([fall, low, thud], 0.25, 0.45)


static func preset_flag_taken() -> Dictionary:
	# Flag taken: two scooping horn blasts — an alarm, not a fanfare.
	var horn: Dictionary = _layer({"mode": SAW, "pitch": 233.0, "voice": 3, "detune": 0.012, "length": 0.32, "volume": 0.70, "level": 0.55},
		[_env(0.03, 0.1, 0.8, 0.2), _bend(-0.12, 0.0, 0.3), _drive(0.3), _filt(LP, 1500.0, 0.3), _echo(380.0, 0.9)])
	var high: Dictionary = _layer({"mode": SQR, "pitch": 932.0, "length": 0.32, "volume": 0.50, "level": 0.25},
		[_env(0.03, 0.1, 0.8, 0.2), _bend(-0.12, 0.0, 0.3), _filt(BP, 1800.0, 0.5), _echo(380.0, 0.9)])
	var sub: Dictionary = _layer({"mode": SIN, "pitch": 58.0, "length": 0.32, "volume": 0.80, "level": 0.35},
		[_env(0.03, 0.1, 0.8, 0.2), _echo(380.0, 0.9)])
	return _sound([horn, high, sub], 0.2, 0.45)


static func preset_flag_dropped() -> Dictionary:
	# Flag dropped: cloth flutter, a thud, and a falling two-note chime.
	var chime: Dictionary = _layer({"mode": SIN, "pitch": 1319.0, "length": 0.45, "volume": 0.70, "level": 0.53},
		[_env(0.0, 0.15, 0.5, 0.5), _arp(8.0, -5, -5, -5), _chord(12, 19, 0, 0.3)])
	var thud: Dictionary = _layer({"mode": SIN, "pitch": 90.0, "length": 0.2, "volume": 0.90, "level": 0.50},
		[_bend(0.3, 0.0, 0.4)])
	var cloth: Dictionary = _layer({"mode": NSE, "length": 0.22, "volume": 0.70, "level": 0.35},
		[_env(0.1, 0.9, 0.0, 0.0), _filt(BP, 1500.0, 0.3), _trem(0.7, 24.0)])
	return _sound([chime, thud, cloth], 0.2, 0.4)


static func preset_flag_captured() -> Dictionary:
	# Flag captured / scored: "ta-ta-ta-TAAA" — three brass pickups, then
	# the chord a fourth up with a cymbal crash. The arp's three equal
	# steps hold the top note; a saw tremolo that fades out by 0.45 s
	# articulates the pickups.
	var root: float = _pick([392.0, 440.0])
	var brass: Dictionary = _layer({"mode": SAW, "pitch": root, "voice": 3, "detune": 0.008, "length": 1.5, "volume": 0.60, "level": 0.64},
		[_env(0.01, 0.2, 0.7, 0.4), _arp(2.5, 5, 5, 5), _trem(1.0, 7.5, SAW, 0.0, 0.3), _filt(LP, 1400.0, 0.3, 0.5, 0.0, 0.3)])
	var third: Dictionary = _layer({"mode": SAW, "pitch": root * 1.26, "voice": 2, "detune": 0.008, "length": 1.5, "volume": 0.50, "level": 0.40},
		[_env(0.01, 0.2, 0.7, 0.4), _arp(2.5, 5, 5, 5), _trem(1.0, 7.5, SAW, 0.0, 0.3), _filt(LP, 1400.0, 0.3, 0.5, 0.0, 0.3)])
	var timpani: Dictionary = _layer({"mode": SIN, "pitch": root * 0.25, "length": 1.5, "volume": 0.90, "level": 0.48},
		[_env(0.0, 0.6, 0.0, 0.0), _arp(2.5, 5, 5, 5), _bend(0.15, 0.0, 0.1), _trem(1.0, 7.5, SAW, 0.0, 0.3)])
	var crash: Dictionary = _layer({"mode": NSE, "length": 1.6, "volume": 0.70, "level": 0.32},
		[_at(0.4, 1.6, 0.4), _filt(HP, 4500.0, 0.2)])
	return _sound([brass, third, timpani, crash], 0.35, 0.6)


static func preset_flag_returned() -> Dictionary:
	# Flag returned: a reverse whoosh pulling into a bright chime at 0.45 s.
	var whoosh: Dictionary = _layer({"mode": NSE, "length": 0.45, "volume": 0.70, "level": 0.59},
		[_env(0.9, 0.1, 0.0, 0.0), _filt(BP, 600.0, 0.5, 0.6, 1.0, 0.0)])
	var chime: Dictionary = _layer({"mode": SIN, "pitch": 1319.0, "length": 1.8, "volume": 0.70, "level": 0.71},
		[_at(0.45, 1.8, 0.45), _chord(7, 12, 0, 0.4)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 110.0, "length": 1.8, "volume": 0.80, "level": 0.50},
		[_at(0.45, 1.8, 0.15), _bend(0.3, 0.25, 0.1)])
	return _sound([whoosh, chime, thump], 0.3, 0.5)


static func preset_bomb_planted() -> Dictionary:
	# Bomb planted: a button press, two armed beeps, and a dark swell.
	var press: Dictionary = _layer({"mode": NSE, "length": 0.015, "volume": 0.70, "level": 0.25},
		[_filt(HP, 3000.0, 0.3)])
	var beeps: Dictionary = _layer({"mode": SQR, "pitch": 1976.0, "length": 0.07, "volume": 0.60, "level": 0.25},
		[_env(0.0, 0.2, 0.8, 0.2), _filt(BP, 2200.0, 0.4), _echo(140.0, 1.0)])
	var swell: Dictionary = _layer({"mode": SAW, "pitch": 55.0, "voice": 3, "detune": 0.02, "length": 1.4, "volume": 0.70, "level": 0.42},
		[_env(0.3, 0.0, 1.0, 0.4), _filt(LP, 250.0, 0.4, 0.35, 0.4, 0.6), _drive(0.3)])
	var tone: Dictionary = _layer({"mode": SIN, "pitch": 880.0, "length": 1.4, "volume": 0.50, "level": 0.20},
		[_env(0.15, 0.0, 1.0, 0.5), _arp(3.0, -1, 0, -1), _trem(0.5, 6.0)])
	return _sound([press, beeps, swell, tone], 0.25, 0.5)


static func preset_bomb_defused() -> Dictionary:
	# Bomb defused: a wire snip, the device powering down, and a relieved
	# two-note chime at 0.35 s. The arp's step 4 (a fourth down) is
	# playing when the gate opens; it wraps to the root at 0.44 s.
	var snip: Dictionary = _layer({"mode": NSE, "length": 0.025, "volume": 0.80, "level": 0.49},
		[_filt(HP, 4000.0, 0.3)])
	var tink: Dictionary = _layer({"mode": SIN, "pitch": 3100.0, "length": 0.05, "volume": 0.60, "level": 0.28},
		[_chord(7, 0, 0, 0.3)])
	var power: Dictionary = _layer({"mode": SQR, "pitch": 880.0, "length": 0.4, "volume": 0.50, "level": 0.40},
		[_env(0.0, 0.0, 1.0, 0.3), _bend(-0.6, 1.0, 0.0), _filt(LP, 2000.0, 0.3, -0.5, 0.0, 1.0)])
	var chime: Dictionary = _layer({"mode": SIN, "pitch": 988.0, "length": 1.4, "volume": 0.70, "level": 0.57},
		[_at(0.35, 1.4, 0.35), _arp(9.0, 0, 0, -5), _chord(12, 0, 0, 0.3)])
	return _sound([snip, tink, power, chime], 0.25, 0.45)


static func preset_checkpoint() -> Dictionary:
	# Checkpoint reached / time extended: a bright "ding-DING" a fourth up.
	var chime: Dictionary = _layer({"mode": SIN, "pitch": 1319.0, "length": 0.6, "volume": 0.70, "level": 0.71},
		[_env(0.0, 0.15, 0.6, 0.5), _arp(6.0, 5, 5, 5), _chord(12, 19, 0, 0.3)])
	var under: Dictionary = _layer({"mode": TRI, "pitch": 659.0, "length": 0.6, "volume": 0.50, "level": 0.34},
		[_env(0.0, 0.15, 0.6, 0.5), _arp(6.0, 5, 5, 5)])
	var tick: Dictionary = _layer({"mode": NSE, "length": 0.01, "volume": 0.50, "level": 0.42},
		[_filt(HP, 5000.0, 0.3), _echo(167.0, 1.0)])
	return _sound([chime, under, tick], 0.3, 0.5)


# ── Round flow ─────────────────────────────────────────────────────

static func preset_match_start() -> Dictionary:
	# Stadium air horn: a dissonant, overdriven blast with a scoop up.
	var horn: Dictionary = _layer({"mode": SAW, "pitch": 370.0, "voice": 4, "detune": 0.02, "length": 1.0, "volume": 0.70, "level": 0.34},
		[_env(0.03, 0.1, 0.85, 0.15), _bend(-0.06, 0.0, 0.12), _drive(0.5), _filt(LP, 2800.0, 0.3)])
	var second: Dictionary = _layer({"mode": SAW, "pitch": 440.0, "voice": 2, "detune": 0.015, "length": 1.0, "volume": 0.60, "level": 0.24},
		[_env(0.03, 0.1, 0.85, 0.15), _bend(-0.06, 0.0, 0.12), _drive(0.5), _filt(LP, 2800.0, 0.3)])
	var low: Dictionary = _layer({"mode": SQR, "pitch": 185.0, "voice": 2, "detune": 0.02, "length": 1.0, "volume": 0.60, "level": 0.22},
		[_env(0.03, 0.1, 0.85, 0.15), _bend(-0.06, 0.0, 0.12), _filt(LP, 1200.0, 0.3)])
	var breath: Dictionary = _layer({"mode": NSE, "length": 1.0, "volume": 0.50, "level": 0.10},
		[_env(0.03, 0.1, 0.85, 0.15), _filt(BP, 2500.0, 0.3)])
	return _sound([horn, second, low, breath], 0.3, 0.6)


static func preset_round_win() -> Dictionary:
	# Victory: brass climbing I → IV → V → I, one chord tone per channel,
	# with timpani hits on each change.
	var root: float = _pick([262.0, 294.0])
	var bass: Dictionary = _layer({"mode": SAW, "pitch": root, "voice": 2, "detune": 0.008, "length": 1.8, "volume": 0.60, "level": 0.42},
		[_env(0.01, 0.0, 1.0, 0.3), _arp(2.5, 5, 7, 12), _pulses(2.5, 0.4), _filt(LP, 1500.0, 0.3)])
	var third: Dictionary = _layer({"mode": SAW, "pitch": root * 1.26, "voice": 2, "detune": 0.008, "length": 1.8, "volume": 0.50, "level": 0.30},
		[_env(0.01, 0.0, 1.0, 0.3), _arp(2.5, 5, 7, 12), _pulses(2.5, 0.4), _filt(LP, 1800.0, 0.3)])
	var fifth: Dictionary = _layer({"mode": TRI, "pitch": root * 2.997, "length": 1.8, "volume": 0.60, "level": 0.30},
		[_env(0.01, 0.0, 1.0, 0.3), _arp(2.5, 5, 7, 12), _pulses(2.5, 0.4), _chord(12, 0, 0, 0.3)])
	var timpani: Dictionary = _layer({"mode": SIN, "pitch": root * 0.25, "length": 1.8, "volume": 0.90, "level": 0.36},
		[_arp(2.5, 5, 7, 12), _bend(0.1, 0.0, 0.05), _pulses(2.5)])
	return _sound([bass, third, fifth, timpani], 0.35, 0.6)


static func preset_round_lost() -> Dictionary:
	# Defeat: slow minor descent i → ♭VI → iv → i, voiced in three parts,
	# over a dark low boom.
	var root: float = _pick([262.0, 247.0])
	var low: Dictionary = _layer({"mode": SAW, "pitch": root, "voice": 2, "detune": 0.01, "length": 2.0, "volume": 0.60, "level": 0.30},
		[_env(0.02, 0.0, 1.0, 0.35), _arp(2.0, -4, -7, -12), _pulses(2.0, 0.3), _filt(LP, 1100.0, 0.3, -0.3, 0.0, 1.0)])
	var mid: Dictionary = _layer({"mode": SAW, "pitch": root * 1.189, "voice": 2, "detune": 0.01, "length": 2.0, "volume": 0.50, "level": 0.22},
		[_env(0.02, 0.0, 1.0, 0.35), _arp(2.0, -3, -7, -12), _pulses(2.0, 0.3), _filt(LP, 1100.0, 0.3, -0.3, 0.0, 1.0)])
	var top: Dictionary = _layer({"mode": TRI, "pitch": root * 1.498, "length": 2.0, "volume": 0.60, "level": 0.21},
		[_env(0.02, 0.0, 1.0, 0.35), _arp(2.0, -4, -7, -12), _pulses(2.0, 0.3)])
	var boom: Dictionary = _layer({"mode": SIN, "pitch": 49.0, "length": 1.0, "volume": 0.90, "level": 0.21},
		[_bend(0.3, 0.0, 0.3), _drive(0.2)])
	return _sound([low, mid, top, boom], 0.35, 0.65)


static func preset_overtime() -> Dictionary:
	# Overtime: a bass whose filter opens over two seconds, a slow siren
	# above it and hats — tension that keeps climbing. The tremolos use
	# attack 1.0 so the 8 Hz pulse grows tighter toward the end.
	var pulse: Dictionary = _layer({"mode": SAW, "pitch": 110.0, "voice": 2, "detune": 0.02, "length": 2.0, "volume": 0.70, "level": 0.45},
		[_env(0.0, 0.0, 1.0, 0.1), _trem(0.9, 8.0, SAW, 1.0, 0.0), _bend(0.12, 1.0, 0.0), _filt(LP, 300.0, 0.5, 0.6, 1.0, 0.0)])
	var siren: Dictionary = _layer({"mode": SIN, "pitch": 700.0, "length": 2.0, "volume": 0.50, "level": 0.21},
		[_env(0.2, 0.0, 1.0, 0.15), _vib(0.12, 1.0, TRI), _bend(0.15, 1.0, 0.0)])
	var hats: Dictionary = _layer({"mode": NSE, "length": 2.0, "volume": 0.50, "level": 0.16},
		[_env(0.3, 0.0, 1.0, 0.1), _filt(HP, 7000.0, 0.2), _trem(1.0, 8.0, SAW, 1.0, 0.0)])
	var hit: Dictionary = _layer({"mode": SIN, "pitch": 55.0, "length": 0.5, "volume": 0.90, "level": 0.22},
		[_bend(0.4, 0.0, 0.3), _drive(0.3)])
	return _sound([pulse, siren, hats, hit], 0.2, 0.5)


static func preset_time_tick() -> Dictionary:
	# Final-seconds tick: woodblock plus a short high beep. Fire once a
	# second as the clock runs out.
	var block: Dictionary = _layer({"mode": SIN, "pitch": _rand(1150.0, 1250.0), "length": 0.06, "volume": 0.80, "level": 0.71},
		[_bend(0.1, 0.0, 0.3)])
	var click: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.70, "level": 0.48},
		[_filt(BP, 3000.0, 0.4)])
	var beep: Dictionary = _layer({"mode": SQR, "pitch": 1760.0, "length": 0.09, "volume": 0.50, "level": 0.35},
		[_env(0.0, 0.3, 0.6, 0.3), _filt(BP, 2400.0, 0.4)])
	return _sound([block, click, beep], 0.05, 0.25)


# ── Combat feedback ────────────────────────────────────────────────

static func preset_hitmarker() -> Dictionary:
	# Hit confirm: a tiny, dry metallic "tk".
	var click: Dictionary = _layer({"mode": NSE, "length": 0.012, "volume": 0.80, "level": 0.40},
		[_filt(HP, 3500.0, 0.3)])
	var tone: Dictionary = _layer({"mode": SQR, "pitch": _rand(2500.0, 2700.0), "length": 0.03, "volume": 0.50, "level": 0.30},
		[_filt(BP, 3000.0, 0.5)])
	var ping: Dictionary = _layer({"mode": SIN, "pitch": 4100.0, "length": 0.04, "volume": 0.50, "level": 0.24})
	return _sound([click, tone, ping], 0.0, 0.2)


static func preset_elimination() -> Dictionary:
	# Kill confirmed: a punchy thunk under a bright bell.
	var bell: Dictionary = _layer({"mode": SIN, "pitch": _pick([1568.0, 1760.0]), "length": 0.5, "volume": 0.70, "level": 0.42},
		[_chord(12, 19, 0, 0.3)])
	var punch: Dictionary = _layer({"mode": SIN, "pitch": 120.0, "length": 0.12, "volume": 0.90, "level": 0.42},
		[_bend(0.4, 0.0, 0.4), _drive(0.3)])
	var snap: Dictionary = _layer({"mode": NSE, "length": 0.03, "volume": 0.80, "level": 0.30},
		[_filt(BP, 2500.0, 0.4)])
	return _sound([bell, punch, snap], 0.12, 0.3)


static func preset_headshot() -> Dictionary:
	# Headshot: helmet "tink" — an inharmonic metal ring and a crunch.
	var ring: Dictionary = _layer({"mode": SIN, "pitch": _rand(2900.0, 3200.0), "length": 0.45, "volume": 0.70, "level": 0.51},
		[_chord(6, 13, 18, 0.5)])
	var crunch: Dictionary = _layer({"mode": NSE, "length": 0.05, "volume": 0.90, "level": 0.51},
		[_filt(BP, 1800.0, 0.4), _drive(0.5), _crush(6, 2)])
	var body: Dictionary = _layer({"mode": TRI, "pitch": 1200.0, "length": 0.08, "volume": 0.60, "level": 0.34},
		[_bend(0.2, 0.0, 0.4)])
	return _sound([ring, crunch, body], 0.1, 0.25)


static func preset_streak() -> Dictionary:
	# Multi-kill / streak: a fast rising triple ding over a riser and a
	# sub drop.
	var root: float = _pick([1047.0, 1175.0])
	var dings: Dictionary = _layer({"mode": SIN, "pitch": root, "length": 0.55, "volume": 0.70, "level": 0.42},
		[_env(0.0, 0.1, 0.6, 0.5), _arp(11.0, 4, 7, 12), _pulses(11.0, 0.6), _chord(12, 0, 0, 0.3)])
	var lead: Dictionary = _layer({"mode": SQR, "pitch": root * 0.5, "length": 0.55, "volume": 0.40, "level": 0.18},
		[_env(0.0, 0.1, 0.6, 0.5), _arp(11.0, 4, 7, 12), _filt(LP, 2500.0, 0.3)])
	var riser: Dictionary = _layer({"mode": NSE, "length": 0.4, "volume": 0.60, "level": 0.24},
		[_env(0.6, 0.4, 0.0, 0.0), _filt(BP, 1500.0, 0.5, 0.6, 1.0, 0.0)])
	var drop: Dictionary = _layer({"mode": SIN, "pitch": 60.0, "length": 0.3, "volume": 0.90, "level": 0.36},
		[_bend(0.6, 0.0, 0.4)])
	return _sound([dings, lead, riser, drop], 0.25, 0.45)


static func preset_respawn() -> Dictionary:
	# Respawn: an energy whoosh rising into a landing thump and shimmer.
	var rise: Dictionary = _layer({"mode": SIN, "pitch": 220.0, "voice": 2, "detune": 0.01, "length": 0.7, "volume": 0.60, "level": 0.48},
		[_env(0.6, 0.1, 0.3, 0.3), _bend(0.5, 0.6, 0.0), _chord(7, 12, 0, 0.4)])
	var whoosh: Dictionary = _layer({"mode": NSE, "length": 0.6, "volume": 0.60, "level": 0.40},
		[_env(0.7, 0.3, 0.0, 0.0), _filt(BP, 500.0, 0.5, 0.6, 0.7, 0.3)])
	var thump: Dictionary = _layer({"mode": SIN, "pitch": 70.0, "length": 1.6, "volume": 0.90, "level": 0.48},
		[_at(0.4, 1.6, 0.25), _bend(0.4, 0.25, 0.1)])
	var shimmer: Dictionary = _layer({"mode": SIN, "pitch": 1760.0, "length": 1.6, "volume": 0.50, "level": 0.29},
		[_at(0.4, 1.6, 0.4), _arp(20.0, 7, 12, 19)])
	return _sound([rise, whoosh, thump, shimmer], 0.3, 0.5)


# ── Map events ─────────────────────────────────────────────────────

static func preset_ping() -> Dictionary:
	# Team map ping: a clean sonar "bip" with a short spatial echo.
	var bip: Dictionary = _layer({"mode": SIN, "pitch": _rand(1350.0, 1450.0), "length": 0.12, "volume": 0.70, "level": 0.76},
		[_bend(0.05, 0.0, 0.3), _chord(12, 0, 0, 0.25), _echo(140.0, 0.35, 0.35)])
	var click: Dictionary = _layer({"mode": NSE, "length": 0.008, "volume": 0.50, "level": 0.40},
		[_filt(HP, 4000.0, 0.3)])
	return _sound([bip, click], 0.2, 0.4)


static func preset_airdrop() -> Dictionary:
	# Supply drop: a falling whistle, then the crate slams down at 0.7 s.
	var whistle: Dictionary = _layer({"mode": SIN, "pitch": 1800.0, "length": 0.7, "volume": 0.50, "level": 0.24},
		[_env(0.2, 0.0, 1.0, 0.05), _bend(-0.5, 1.0, 0.0), _vib(0.01, 7.0)])
	var thud: Dictionary = _layer({"mode": SIN, "pitch": 50.0, "length": 2.8, "volume": 1.00, "level": 0.22},
		[_at(0.7, 2.8, 0.6), _bend(0.5, 0.25, 0.1), _drive(0.3)])
	var clank: Dictionary = _layer({"mode": NSE, "length": 2.8, "volume": 0.80, "level": 0.13},
		[_at(0.7, 2.8, 0.25), _filt(BP, 1200.0, 0.5), _drive(0.4)])
	var dust: Dictionary = _layer({"mode": BRN, "length": 2.8, "volume": 0.80, "level": 0.13},
		[_at(0.7, 2.8, 0.6), _filt(LP, 500.0, 0.2)])
	return _sound([whistle, thud, clank, dust], 0.25, 0.5)


static func preset_zone() -> Dictionary:
	# Zone / storm closing: a rising, flanged drone under a two-tone
	# warning pulse that dissolves into it — the map is shrinking.
	var drone: Dictionary = _layer({"mode": SAW, "pitch": 55.0, "voice": 4, "detune": 0.03, "length": 2.5, "volume": 0.70, "level": 0.50},
		[_env(0.3, 0.0, 1.0, 0.25), _bend(0.25, 1.0, 0.0), _filt(LP, 200.0, 0.4, 0.5, 1.0, 0.0), _flange(0.6, 0.3, 0.5, 0.5)])
	var wind: Dictionary = _layer({"mode": NSE, "length": 2.5, "volume": 0.60, "level": 0.30},
		[_env(0.4, 0.0, 1.0, 0.25), _filt(BP, 400.0, 0.6, 0.5, 1.0, 0.0), _trem(0.4, 0.8)])
	var warn: Dictionary = _layer({"mode": SIN, "pitch": 440.0, "length": 2.5, "volume": 0.50, "level": 0.24},
		[_env(0.05, 0.0, 1.0, 0.2), _arp(2.0, -1, 0, -1), _pulses(2.0)])
	return _sound([drone, wind, warn], 0.3, 0.6)
