extends Control
## Фон всего интерфейса: мягкий градиент, свечение в цвет эпохи и тонкая сетка «печатной платы».

const Gfx := preload("res://scripts/ui/Gfx.gd")

var top := Color("#1b1f26")
var bottom := Color("#0f1115")
var accent := Color("#ff8a1f")
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	if Engine.get_process_frames() % 3 == 0:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Gfx.vgrad(self, r, top, bottom)
	Gfx.glow(self, Vector2(size.x * 0.82, size.y * 0.05), size.x * 0.45, Color(accent, 0.10))
	Gfx.glow(self, Vector2(size.x * 0.08, size.y * 0.95), size.x * 0.35, Color(accent.lerp(Color("#4a9ff0"), 0.6), 0.07))
	# дорожки платы
	var rng := RandomNumberGenerator.new()
	rng.seed = 1126
	var line := Color(1, 1, 1, 0.025)
	for i in 26:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var l1 := rng.randf_range(40, 180)
		var l2 := rng.randf_range(30, 120)
		var dir := 1.0 if rng.randf() < 0.5 else -1.0
		var pts := PackedVector2Array([p, p + Vector2(l1, 0), p + Vector2(l1 + l2 * 0.7, l2 * 0.7 * dir), p + Vector2(l1 + l2 * 0.7 + 60, l2 * 0.7 * dir)])
		draw_polyline(pts, line, 2.0, true)
		draw_circle(pts[3], 3.5, line)
		draw_circle(p, 3.5, line)
	# бегущий «сигнал» по одной дорожке
	var u := fmod(t * 0.12, 1.0)
	Gfx.glow(self, Vector2(size.x * u, size.y * 0.5 + sin(u * TAU) * 30), 60, Color(accent, 0.05))
