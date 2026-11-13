extends "res://scripts/ui/OverlayBase.gd"
## Мини-игра: поймай вирус. Жучки бегают по файлам — кликай по ним.

var total := 1
var names: Array = []
var bugs: Array = []    # [pos, vel]
var caught := 0
var timer := 12.0
var v: Control
var info: Label
const FILES := ["system32", "фото.jpg", "домашка.docx", "игры", "autorun.inf", "svchost.exe", "музыка", "temp", "boot.ini", "cat.png"]


func build() -> void:
	title("Антивирус: поймай вирусы!")
	info = label("Жучки бегают по файлам — кликай по ним, пока не сбежали. Найдено угроз: %d" % total, 15)
	v = view(340)
	v.draw.connect(_draw_view)
	v.gui_input.connect(_input_view)
	await get_tree().process_frame
	for i in total:
		bugs.append([Vector2(randf_range(40, v.size.x - 40), randf_range(40, v.size.y - 40)), Vector2.from_angle(randf() * TAU) * randf_range(120, 200)])


func _process(delta: float) -> void:
	timer -= delta
	for b in bugs:
		b[0] += b[1] * delta
		if b[0].x < 15 or b[0].x > v.size.x - 15:
			b[1].x *= -1
		if b[0].y < 15 or b[0].y > v.size.y - 15:
			b[1].y *= -1
		if randf() < 0.02:
			b[1] = b[1].rotated(randf_range(-1.2, 1.2))
	info.text = "Поймано: %d из %d · время %.1f с" % [caught, total, max(0.0, timer)]
	v.queue_redraw()
	if timer <= 0.0 or bugs.is_empty():
		set_process(false)
		finish({"caught": caught})


func _input_view(e: InputEvent) -> void:
	var pos := Vector2.INF
	if e is InputEventMouseButton and e.pressed:
		pos = e.position
	elif e is InputEventScreenTouch and e.pressed:
		pos = e.position
	if pos == Vector2.INF:
		return
	for b in bugs:
		if b[0].distance_to(pos) < 26.0:
			bugs.erase(b)
			caught += 1
			break


func _draw_view() -> void:
	var sz := v.size
	v.draw_rect(Rect2(Vector2.ZERO, sz), Color("#1d2026"))
	for i in FILES.size():
		var p := Vector2(30 + (i % 5) * (sz.x - 60) / 5.0, 30 + (i / 5) * 150)
		v.draw_rect(Rect2(p, Vector2(60, 70)), Color("#e8c05a") if i % 3 else Color("#7fb2e5"))
		v.draw_string(get_theme_default_font(), p + Vector2(0, 92), FILES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c9ccd1"))
	for b in bugs:
		var c: Vector2 = b[0]
		for k in 3:
			v.draw_line(c + Vector2(-16, -8 + k * 8), c + Vector2(16, 8 - k * 8), Color("#2b0000"), 2.0)
		v.draw_circle(c, 12.0, Color("#e53935"))
		v.draw_circle(c + Vector2(0, -10), 6.0, Color("#b71c1c"))
