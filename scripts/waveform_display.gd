class_name WaveformDisplay
extends Control

# Renders a sample buffer into a horizontal waveform with a glow underlay
# and gridlines. Colours are pulled from Palette so the display tracks
# the active theme on rebuild — line + glow use the accent's complement
# so the waveform reads as "the signal" rather than "more accent".
#
# The polyline is cached and only recomputed when samples change or the
# control resizes. Redraws that only touch theme colours (rebuild_ui)
# skip the peak-finding pass entirely.

var samples: PackedFloat32Array = PackedFloat32Array()

# Cache — invalidated by set_samples() or size change.
var _cached_pts: PackedVector2Array = PackedVector2Array()
var _cached_peak: float = 0.0
var _cached_size: Vector2 = Vector2.ZERO
var _cache_dirty: bool = true


func set_samples(s: PackedFloat32Array) -> void:
	samples = s
	_cache_dirty = true
	queue_redraw()


func _draw() -> void:
	var sz: Vector2 = size
	if sz.x <= 0 or sz.y <= 0:
		return

	draw_rect(Rect2(Vector2.ZERO, sz), Palette.INSET, true)

	var grid: Color = Palette.SEPARATOR
	# Center line
	draw_line(Vector2(0, sz.y * 0.5), Vector2(sz.x, sz.y * 0.5), grid, 1.0)
	# Vertical gridlines (8 segments)
	for i in range(1, 8):
		var x: float = sz.x * float(i) / 8.0
		draw_line(Vector2(x, 0), Vector2(x, sz.y), grid, 1.0)

	if samples.is_empty():
		return

	if _cache_dirty or sz != _cached_size:
		_rebuild_cache(sz)

	draw_polyline(_cached_pts, Palette.waveform_glow(), 4.0, true)
	draw_polyline(_cached_pts, Palette.waveform_line(), 1.4, true)

	if _cached_peak > 0.9:
		var peak_col: Color = Color(1.0, 0.3, 0.3) if _cached_peak >= 1.0 else Palette.TEXT_MUTE
		var peak_text: String = "CLIP" if _cached_peak >= 1.0 else ("PEAK %.2f" % _cached_peak)
		draw_string(ThemeDB.fallback_font, Vector2(sz.x - 80, sz.y - 6), peak_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, peak_col)


func _rebuild_cache(sz: Vector2) -> void:
	var half: float = sz.y * 0.5 - 12.0
	var num_points: int = max(2, int(sz.x * 2.0))
	var n: int = samples.size()
	var step: int = max(1, n / num_points)

	var max_peak: float = 0.0
	_cached_pts.resize(num_points)
	for i in num_points:
		var start_idx: int = i * step
		var end_idx: int = mini((i + 1) * step, n)
		if start_idx >= n:
			start_idx = n - 1
			end_idx = n
		var peak: float = samples[start_idx]
		for j in range(start_idx + 1, end_idx):
			if absf(samples[j]) > absf(peak):
				peak = samples[j]
		if absf(peak) > max_peak:
			max_peak = absf(peak)
		var clamped_peak: float = clampf(peak, -1.0, 1.0)
		var x: float = float(i) / float(num_points) * sz.x
		var y: float = clampf(sz.y * 0.5 - clamped_peak * half, 2.0, sz.y - 2.0)
		_cached_pts[i] = Vector2(x, y)

	_cached_peak = max_peak
	_cached_size = sz
	_cache_dirty = false
