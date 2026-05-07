class_name WaveformDisplay
extends Control

# Renders a sample buffer into a horizontal waveform with a glow underlay
# and gridlines. Colours are pulled from Palette so the display tracks
# the active theme on rebuild — line + glow use the accent's complement
# so the waveform reads as "the signal" rather than "more accent".

var samples: PackedFloat32Array = PackedFloat32Array()


func set_samples(s: PackedFloat32Array) -> void:
	samples = s
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

	var half: float = sz.y * 0.5 - 12.0
	var num_points: int = max(2, int(sz.x * 2.0))
	var n: int = samples.size()
	var step: int = max(1, n / num_points)

	var pts: PackedVector2Array = PackedVector2Array()
	pts.resize(num_points)
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
		var x: float = float(i) / float(num_points) * sz.x
		var y: float = clampf(sz.y * 0.5 - peak * half, 2.0, sz.y - 2.0)
		pts[i] = Vector2(x, y)

	draw_polyline(pts, Palette.waveform_glow(), 4.0, true)
	draw_polyline(pts, Palette.waveform_line(), 1.4, true)
