class_name Playback
extends RefCounted

# Pure conversion of a synthesised float buffer into a Godot
# AudioStreamWAV that an AudioStreamPlayer can play. main.gd owns the
# AudioStreamPlayer and decides WHEN to play; this class just packages
# the bytes.
#
# Why a class and not a free function: keeping the AudioStreamWAV
# format/sample-rate/encoding decisions in one place makes future
# format changes (24-bit, stereo, OGG) one-file edits.


# Convert a normalised float buffer ([-1, 1]) into a 16-bit PCM
# AudioStreamWAV at SoundData.SAMPLE_RATE. Out-of-range samples are
# clamped (matches the WAV-export contract in SoundData.encode_wav).
static func build_stream(buf: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SoundData.SAMPLE_RATE
	stream.stereo = false
	# Raw little-endian PCM — AudioStreamWAV.data wants header-less bytes,
	# unlike SoundData.encode_wav() which prepends a RIFF header.
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v: float = clamp(buf[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	stream.data = bytes
	return stream
