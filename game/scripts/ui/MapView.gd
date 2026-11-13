extends Control
## Карта Техноград: районы, дороги, река, мастерская и вызовы клиентов.

signal pin_clicked(i: int)
signal arrived

const Gfx := preload("res://scripts/ui/Gfx.gd")

var visits: Array = []
var selected := -1
var year := 1995
var stage := 0
var transport := 0
var accent := Color("#ff8a1f")
var t := 0.0
var anim := -1.0       # 0..1 — едем к клиенту
var anim_to := Vector2.ZERO
const SHOP := Vector2(0.42, 0.55)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _process(delta: float) -> void:
	t += delta
	if anim >= 0.0:
		anim += delta / (1.6 / float(Data.TRANSPORT[transport]["speed"]) + 0.6)
		if anim >= 1.0:
			anim = -1.0
			arrived.emit()
	queue_redraw()


func _p(v: Vector2) -> Vector2:
	return Vector2(v.x * size.x, v.y * size.y)


func pin_pos(i: int) -> Vector2:
	var o: Dictionary = visits[i]
	var d := Game.district(o["district"])
	var h := absi(String(o["client"]).hash() + i * 977)
	var off := Vector2(float(h % 100) / 100.0 - 0.5, float((h / 100) % 100) / 100.0 - 0.5) * 0.12
	return _p(d["pos"] + off)


func go_to(i: int) -> void:
	anim_to = pin_pos(i)
	anim = 0.0


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Gfx.rr(self, r, Color("#3f6b3a"), 14)
	Gfx.textured(self, r.grow(-2), "noise")
	# река
	var river := PackedVector2Array()
	for i in 21:
		var u := i / 20.0
		river.append(_p(Vector2(u, 0.86 - 0.18 * sin(u * 3.2) + 0.04 * sin(u * 11.0))))
	draw_polyline(river, Color("#3a7fc4"), size.y * 0.06, true)
	draw_polyline(river, Color("#5aa0e0"), size.y * 0.025, true)
	# районы
	for d in Data.DISTRICTS:
		var open: bool = year >= int(d["year"])
		var c := _p(d["pos"])
		var col: Color = d["col"]
		var rr := Vector2(size.x * 0.13, size.y * 0.12)
		var pts := PackedVector2Array()
		for i in 18:
			var a := TAU * i / 18.0
			var k := 1.0 + 0.12 * sin(a * 3.0 + c.x)
			pts.append(c + Vector2(cos(a) * rr.x, sin(a) * rr.y) * k)
		draw_colored_polygon(pts, Color(col, 0.22 if open else 0.06))
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(col, 0.6 if open else 0.15), 2.0, true)
		# домики района
		var rng := RandomNumberGenerator.new()
		rng.seed = String(d["id"]).hash()
		for k2 in 7:
			var hp := c + Vector2(rng.randf_range(-0.8, 0.8) * rr.x, rng.randf_range(-0.6, 0.6) * rr.y)
			var tall: float = (rng.randf_range(10, 26) if d["id"] in ["center", "city"] else rng.randf_range(6, 12))
			var bw := rng.randf_range(8, 14)
			Gfx.rr(self, Rect2(hp - Vector2(bw / 2, tall), Vector2(bw, tall)), Color("#e0d6c4") if open else Color("#6d7a68"), 2, Color(0, 0, 0, 0.25), 1, 2)
			if d["id"] in ["sleep", "cottage"]:
				draw_colored_polygon(PackedVector2Array([hp + Vector2(-bw / 2 - 2, -tall), hp + Vector2(0, -tall - 7), hp + Vector2(bw / 2 + 2, -tall)]), Color("#b0463a") if open else Color("#5a5a5a"))
		var lw := Gfx.text_w(d["name"], 13, true) + 16
		Gfx.rr(self, Rect2(c + Vector2(-lw / 2, rr.y * 0.75), Vector2(lw, 22)), Color(0, 0, 0, 0.6), 11)
		Gfx.text(self, c + Vector2(-lw / 2, rr.y * 0.75 + 16), d["name"] if open else d["name"] + " (" + str(d["year"]) + ")", 13, Color.WHITE if open else Color(1, 1, 1, 0.45), lw, HORIZONTAL_ALIGNMENT_CENTER, true)
	# дороги от мастерской к районам
	var shop := _p(SHOP)
	for d in Data.DISTRICTS:
		if year < int(d["year"]):
			continue
		var c := _p(d["pos"])
		var mid := Vector2(c.x, shop.y)
		var road := PackedVector2Array([shop, mid, c])
		draw_polyline(road, Color("#4a4d52"), 9.0, true)
		var reach: bool = int(d["dist"]) <= int(Data.TRANSPORT[transport]["reach"])
		draw_polyline(road, Color("#f5f5f5", 0.7) if reach else Color("#ef5350", 0.5), 1.5, true)
	# мастерская
	Gfx.glow(self, shop, 40, Color(accent, 0.35))
	Gfx.rr(self, Rect2(shop - Vector2(18, 22), Vector2(36, 30)), accent, 5, Color.WHITE, 2, 6)
	Gfx.text(self, shop + Vector2(-18, 0), "m", 20, Color("#1a1205"), 36, HORIZONTAL_ALIGNMENT_CENTER, true)
	Gfx.text(self, shop + Vector2(-60, 26), Data.STAGES[stage]["name"], 12, Color.WHITE, 120, HORIZONTAL_ALIGNMENT_CENTER, true)
	# вызовы
	for i in visits.size():
		var pp := pin_pos(i)
		var sel := i == selected
		var bob := sin(t * 3.0 + i) * 3.0
		var tip := pp + Vector2(0, bob)
		var col := accent if sel else Color("#ef5350")
		Gfx.glow(self, tip, 26 if sel else 18, Color(col, 0.35))
		draw_circle(tip - Vector2(0, 22), 14 if sel else 12, col)
		draw_colored_polygon(PackedVector2Array([tip - Vector2(9, 16), tip + Vector2(9, -16), tip]), col)
		draw_circle(tip - Vector2(0, 22), 9 if sel else 8, Color.WHITE)
		Gfx.text(self, tip - Vector2(10, 17), "$", 12, col.darkened(0.3), 20, HORIZONTAL_ALIGNMENT_CENTER, true)
	# машинка в пути
	if anim >= 0.0:
		var u: float = clamp(anim, 0.0, 1.0)
		var mid2 := Vector2(anim_to.x, shop.y)
		var p: Vector2 = shop.lerp(mid2, u * 2.0) if u < 0.5 else mid2.lerp(anim_to, (u - 0.5) * 2.0)
		_vehicle(p)


func _vehicle(p: Vector2) -> void:
	match transport:
		0:
			draw_arc(p + Vector2(-8, 0), 6, 0, TAU, 14, Color.WHITE, 2, true)
			draw_arc(p + Vector2(8, 0), 6, 0, TAU, 14, Color.WHITE, 2, true)
			draw_line(p + Vector2(-8, 0), p + Vector2(0, -8), accent, 2)
			draw_line(p + Vector2(0, -8), p + Vector2(8, 0), accent, 2)
			draw_circle(p + Vector2(0, -16), 4, Color("#f2c9a0"))
		1:
			Gfx.rr(self, Rect2(p - Vector2(14, 10), Vector2(28, 10)), Color("#4aa3ff"), 3)
			Gfx.rr(self, Rect2(p - Vector2(8, 16), Vector2(16, 7)), Color("#9fd0ff"), 2)
			draw_circle(p + Vector2(-8, 1), 3.5, Color("#111"))
			draw_circle(p + Vector2(8, 1), 3.5, Color("#111"))
		2:
			Gfx.rr(self, Rect2(p - Vector2(16, 18), Vector2(32, 18)), Color.WHITE, 3)
			draw_rect(Rect2(p - Vector2(16, 10), Vector2(32, 3)), accent)
			draw_circle(p + Vector2(-9, 1), 3.5, Color("#111"))
			draw_circle(p + Vector2(9, 1), 3.5, Color("#111"))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and anim < 0.0:
		for i in visits.size():
			if (pin_pos(i) - Vector2(0, 20)).distance_to(e.position) < 22:
				pin_clicked.emit(i)
				return
