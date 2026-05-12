class_name SequenceRenderer
extends RefCounted

# Renders a piano roll sequence into an audio buffer by calling
# Synth.render_channel() per note with pitch/length overrides, then
# summing into a timeline buffer. Same pure-static pattern as Synth.


static func render_sequence(
	notes: Array[Dictionary],
	sound: Dictionary,
	bpm: int,
	total_beats: float
) -> PackedFloat32Array:
	var channels: Array = sound.get("channels", [])
	if channels.is_empty() or notes.is_empty():
		return PackedFloat32Array()

	var samples_per_beat: float = float(Synth.SAMPLE_RATE) * 60.0 / float(bpm)
	var tail_samples: int = int(0.5 * float(Synth.SAMPLE_RATE))
	var buf_len: int = int(total_beats * samples_per_beat) + tail_samples
	var output: PackedFloat32Array = PackedFloat32Array()
	output.resize(buf_len)

	for note in notes:
		var ch_idx: int = int(note.channel)
		if ch_idx < 0 or ch_idx >= channels.size():
			continue

		var params: Dictionary = channels[ch_idx].duplicate(true)
		params.pitch = PianoRollState.midi_to_hz(int(note.midi))
		params.length = float(note.length) * 60.0 / float(bpm)

		var rendered: PackedFloat32Array = Synth.render_channel(params)
		var offset: int = int(float(note.beat) * samples_per_beat)

		var copy_len: int = mini(rendered.size(), buf_len - offset)
		for i in copy_len:
			output[offset + i] += rendered[i]

	var master: Dictionary = sound.get("master", SoundData.clone_master())
	output = Synth.apply_reverb(output, master)
	output = Synth.apply_master_volume(output, master)
	output = Synth.apply_limiter(output)
	return output
