extends "res://scripts/ui/OverlayBase.gd"
## Мини-игра: установка процессора. Совмести треугольник-ключ, иначе погнёшь ножки.

var cpu_name := ""
var lga := true          # ножки в сокете платы (Intel LGA) или на процессоре (старые AMD, Pentium)
var rot := 1
var phase := 0
var v: Control
var info: Label
var bent: Array = []
var timer := 0.0
const GRID := 9


func build() -> void:
	rot = randi_range(1, 3)
	title("Установка процессора: " + cpu_name)
	info = label("Совмести золотой треугольник на процессоре с меткой на сокете и опусти. " +
		("Ножки в сокете платы — неаккуратно поставишь, погнёшь плату!" if lga else "Ножки на самом процессоре — легко погнуть!"), 15)
	v = view(330)
	v.draw.connect(_draw_view)
	v.gui_input.connect(_input_view)
	var r := row()
	btn(r, "↻ Повернуть процессор", _rotate)
	btn(r, "⬇ Опустить в сокет", _drop)


func _rotate() -> void:
	if phase == 0:
		rot = (rot + 1) % 4
		v.queue_redraw()


func _corner(c: Vector2, half: float, idx: int) -> Vector2:
	return c + [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)][idx]


func _pin_pos(c: Vector2, i: int, j: int) -> Vector2:
	var step := 200.0 / float(GRID)
	return c + Vector2(-100.0 + step * (i + 0.5), -100.0 + step * (j + 0.5))


func _draw_view() -> void:
	var c := v.size / 2.0
	v.draw_rect(Rect2(c - Vector2(130, 130), Vector2(260, 260)), Color("#3b3f46"))
	v.draw_rect(Rect2(c - Vector2(112, 112), Vector2(224, 224)), Color("#2a2c31"))
	for i in GRID:
		for j in GRID:
			v.draw_circle(_pin_pos(c, i, j), 3.0, Color("#c9a24a"))
	var k := _corner(c, 112, 0)
	v.draw_colored_polygon(PackedVector2Array([k, k + Vector2(26, 0), k + Vector2(0, 26)]), Color("#ffd54a"))
	if phase == 0:
		var cc := c + Vector2(0, -6)
		v.draw_rect(Rect2(cc - Vector2(100, 100), Vector2(200, 200)), Color(0.55, 0.6, 0.65, 0.85))
		v.draw_rect(Rect2(cc - Vector2(70, 70), Vector2(140, 140)), Color(0.75, 0.78, 0.8, 0.9))
		var q := _corner(cc, 100, rot)
		var dir := (cc - q).normalized()
		var side := Vector2(-dir.y, dir.x)
		var a := q + dir * 6
		var p1 := a + (dir + side).normalized() * 0 + Vector2(sign(dir.x), 0) * 24
		var p2 := a + Vector2(0, sign(dir.y)) * 24
		v.draw_colored_polygon(PackedVector2Array([a, p1, p2]), Color("#ffd54a"))
		v.draw_string(get_theme_default_font(), cc + Vector2(-60, 6), cpu_name.substr(0, 16), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#1b1d21"))
	else:
		for b in bent:
			v.draw_circle(_pin_pos(c, b.x, b.y), 8.0, Color("#ef5350"))


func _drop() -> void:
	if phase != 0:
		return
	if rot == 0:
		info.text = "Щёлк! Процессор встал идеально. Защёлкни рычаг."
		v.queue_redraw()
		await get_tree().create_timer(0.7).timeout
		finish({"bent": false})
		return
	phase = 1
	timer = 10.0
	bent = []
	while bent.size() < 6:
		var p := Vector2i(randi_range(0, GRID - 1), randi_range(0, GRID - 1))
		if not bent.has(p):
			bent.append(p)
	v.queue_redraw()


func _process(delta: float) -> void:
	if phase == 1:
		timer -= delta
		info.text = "Хрусь! Погнулись ножки %s! Быстро выпрями все красные пинцетом — кликай по ним. Осталось %.1f с" % ["в сокете" if lga else "на процессоре", max(0.0, timer)]
		if timer <= 0.0:
			phase = 2
			finish({"bent": true, "fixed": false})


func _input_view(e: InputEvent) -> void:
	if phase != 1:
		return
	var pos := Vector2.INF
	if e is InputEventMouseButton and e.pressed:
		pos = e.position
	elif e is InputEventScreenTouch and e.pressed:
		pos = e.position
	if pos == Vector2.INF:
		return
	var c := v.size / 2.0
	for b in bent:
		if pos.distance_to(_pin_pos(c, b.x, b.y)) < 14.0:
			bent.erase(b)
			v.queue_redraw()
			break
	if bent.is_empty():
		phase = 2
		info.text = "Все ножки выпрямлены! Повезло."
		await get_tree().create_timer(0.7).timeout
		finish({"bent": true, "fixed": true})
