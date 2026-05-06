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
	var step: int = max(1, samples.size() / num_points)

	# Build the polyline once, draw twice (glow underlay + crisp top line).
	var pts: PackedVector2Array = PackedVector2Array()
	pts.resize(num_points)
	var n: int = samples.size()
	for i in num_points:
		var idx: int = i * step
		if idx >= n:
			idx = n - 1
		var x: float = float(i) / float(num_points) * sz.x
		var y: float = sz.y * 0.5 - samples[idx] * half
		pts[i] = Vector2(x, y)

	draw_polyline(pts, Palette.waveform_glow(), 4.0, true)
	draw_polyline(pts, Palette.waveform_line(), 1.4, true)
