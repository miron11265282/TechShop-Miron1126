extends Control
## Кошка Буся — талисман и помощница. Рисуется кодом (серая с белой грудкой, как на фото).

signal petted
signal tip_requested

const GRAY := Color("#6b6f78")
const GRAY_DARK := Color("#555963")
const WHITE := Color("#f2f2f0")
const PINK := Color("#e8a3a8")
const EYE := Color("#c99a3c")

var sleeping := false
var blink := 0.0
var purr := 0.0
var idle_time := 0.0
var bubble: PanelContainer
var bubble_label: Label
var bubble_timer := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(110, 130)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Буся — погладь меня!"
	bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#fff4e6")
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	bubble.add_theme_stylebox_override("panel", sb)
	bubble_label = Label.new()
	bubble_label.add_theme_color_override("font_color", Color("#2a2420"))
	bubble_label.add_theme_font_size_override("font_size", 14)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.custom_minimum_size.x = 230
	bubble.add_child(bubble_label)
	bubble.visible = false
	bubble.top_level = true
	add_child(bubble)


func say(meow: String, translation: String, secs: float = 5.0) -> void:
	sleeping = false
	idle_time = 0.0
	bubble_label.text = "%s\n(перевод: %s)" % [meow, translation]
	bubble.visible = true
	bubble_timer = secs
	bubble.reset_size()
	queue_redraw()


func wake() -> void:
	idle_time = 0.0
	if sleeping:
		sleeping = false
		queue_redraw()


func _process(delta: float) -> void:
	idle_time += delta
	if not sleeping and idle_time > 60.0:
		sleeping = true
		bubble.visible = false
		queue_redraw()
	blink -= delta
	if blink < -3.5:
		blink = 0.15
	if purr > 0.0:
		purr -= delta
	if bubble_timer > 0.0:
		bubble_timer -= delta
		if bubble_timer <= 0.0:
			bubble.visible = false
	if bubble.visible:
		var gp := global_position
		bubble.global_position = Vector2(gp.x - bubble.size.x - 6, gp.y + size.y - bubble.size.y - 8)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y < size.y * 0.45:
			petted.emit()
			purr = 1.2
			say("Мурррр~", "мне приятно, гладь ещё", 2.5)
		else:
			tip_requested.emit()
	elif event is InputEventScreenTouch and event.pressed:
		petted.emit()
		purr = 1.2
		say("Мурррр~", "мне приятно, гладь ещё", 2.5)


func _ellipse(c: Vector2, r: Vector2, col: Color, steps: int = 28) -> void:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var s: float = min(size.x / 110.0, size.y / 130.0)
	draw_set_transform(Vector2((size.x - 110.0 * s) / 2.0, size.y - 130.0 * s), 0.0, Vector2(s, s))
	var wob := sin(Time.get_ticks_msec() / 90.0) * 1.2 if purr > 0.0 else 0.0
	# хвост
	var tail := PackedVector2Array()
	for i in 12:
		var t := float(i) / 11.0
		tail.append(Vector2(78 + t * 22, 118 - sin(t * PI) * 26 - t * 10))
	draw_polyline(tail, GRAY_DARK, 9.0, true)
	# тело
	_ellipse(Vector2(55, 96), Vector2(30, 30), GRAY)
	_ellipse(Vector2(55, 92), Vector2(14, 24), WHITE)
	# лапки
	_ellipse(Vector2(44, 124), Vector2(9, 6), WHITE)
	_ellipse(Vector2(66, 124), Vector2(9, 6), WHITE)
	# голова
	var hc := Vector2(55, 50 + wob)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-24, -8), hc + Vector2(-20, -36), hc + Vector2(-4, -20)]), GRAY)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(24, -8), hc + Vector2(20, -36), hc + Vector2(4, -20)]), GRAY)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-19, -12), hc + Vector2(-17, -29), hc + Vector2(-8, -19)]), PINK)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(19, -12), hc + Vector2(17, -29), hc + Vector2(8, -19)]), PINK)
	_ellipse(hc, Vector2(26, 23), GRAY)
	# белая полоска на мордочке и щёчки
	_ellipse(hc + Vector2(0, -4), Vector2(3.5, 10), WHITE)
	_ellipse(hc + Vector2(0, 11), Vector2(12, 9), WHITE)
	# глаза
	if sleeping or blink > 0.0 or purr > 0.0:
		draw_arc(hc + Vector2(-10, 0), 5, 0.2, PI - 0.2, 8, Color("#2b2b2b"), 2.0)
		draw_arc(hc + Vector2(10, 0), 5, 0.2, PI - 0.2, 8, Color("#2b2b2b"), 2.0)
	else:
		_ellipse(hc + Vector2(-10, 0), Vector2(5.5, 6), EYE)
		_ellipse(hc + Vector2(10, 0), Vector2(5.5, 6), EYE)
		_ellipse(hc + Vector2(-10, 0), Vector2(1.8, 5), Color("#151515"))
		_ellipse(hc + Vector2(10, 0), Vector2(1.8, 5), Color("#151515"))
	# нос и рот
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-3, 7), hc + Vector2(3, 7), hc + Vector2(0, 10)]), PINK)
	draw_line(hc + Vector2(0, 10), hc + Vector2(-3, 13), Color("#555555"), 1.2)
	draw_line(hc + Vector2(0, 10), hc + Vector2(3, 13), Color("#555555"), 1.2)
	# усы
	for k in [-1, 1]:
		draw_line(hc + Vector2(6 * k, 11), hc + Vector2(26 * k, 7), Color(1, 1, 1, 0.6), 1.0)
		draw_line(hc + Vector2(6 * k, 13), hc + Vector2(26 * k, 14), Color(1, 1, 1, 0.6), 1.0)
	if sleeping:
		draw_string(get_theme_default_font(), Vector2(82, 18), "Zzz", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ff8a1f"))
	draw_set_transform(Vector2.ZERO)
