extends Control
## Вид компьютерного клуба: неоновая вывеска, ряды мест, посетители, бар, консоли, VR.

const Gfx := preload("res://scripts/ui/Gfx.gd")

var states: Array = []      # "ok" / "slow" / "broken" для каждого места
var max_seats := 4
var visitors := 0
var extras: Array = []
var year := 1995
var accent := Color("#ff8a1f")
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Gfx.rr(self, r, Color("#0c0b14"), 14)
	Gfx.vgrad(self, Rect2(2, 2, size.x - 4, size.y * 0.6), Color("#1a1430"), Color("#0e0c18"))
	# пол
	var floor_y := size.y * 0.62
	Gfx.vgrad(self, Rect2(2, floor_y, size.x - 4, size.y - floor_y - 2), Color("#1d1b26"), Color("#0b0a10"))
	for i in 12:
		draw_line(Vector2(size.x * i / 11.0, floor_y), Vector2(size.x * 0.5 + (size.x * i / 11.0 - size.x * 0.5) * 1.8, size.y), Color(1, 1, 1, 0.03), 1)
	# неоновая вывеска
	var sign_txt := "miron1126 CLUB"
	var flick := 0.85 + 0.15 * sin(t * 13.0) * (1.0 if fmod(t, 4.0) < 0.3 else 0.0)
	Gfx.glow(self, Vector2(size.x * 0.5, 30), 160, Color(accent, 0.18 * flick))
	Gfx.text(self, Vector2(0, 40), sign_txt, 26, Color(accent.lightened(0.3), flick), size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	# места рядами
	var n := max_seats
	var per_row: int = n if n <= 4 else (5 if n <= 10 else 10)
	var rows: int = int(ceil(float(n) / per_row))
	var area := Rect2(Vector2(size.x * 0.04, size.y * 0.2), Vector2(size.x * (0.62 if not extras.is_empty() else 0.92), size.y * 0.72))
	var sw := area.size.x / per_row
	var sh: float = min(area.size.y / max(1, rows), sw * 1.1)
	var occupied := visitors
	for i in n:
		var row := i / per_row
		var col := i % per_row
		var p := area.position + Vector2(col * sw + sw * 0.5, row * sh + sh * 0.35)
		var mw := sw * 0.66
		var mh := mw * 0.6
		# стол
		Gfx.rr(self, Rect2(p + Vector2(-sw * 0.45, mh * 0.55), Vector2(sw * 0.9, mh * 0.18)), Color("#2b2733"), 2)
		if i >= states.size():
			# пустое место
			Gfx.rr(self, Rect2(p - Vector2(mw / 2, mh / 2), Vector2(mw, mh)), Color(0, 0, 0, 0), 3, Color(1, 1, 1, 0.15), 1)
			Gfx.text(self, p + Vector2(-mw / 2, 5), "+", int(mh * 0.6), Color(1, 1, 1, 0.2), mw, HORIZONTAL_ALIGNMENT_CENTER, true)
			continue
		var st: String = states[i]
		var sc := Color("#4aa3ff") if st == "ok" else (Color("#ffb74d") if st == "slow" else Color("#ef5350"))
		Gfx.glow(self, p, mw * 0.9, Color(sc, 0.18 if st != "broken" else 0.08))
		Gfx.rr(self, Rect2(p - Vector2(mw / 2, mh / 2), Vector2(mw, mh)), Color("#0a0a0c"), 3, Color("#2c2f35"), 1)
		var scr := Rect2(p - Vector2(mw / 2 - 2, mh / 2 - 2), Vector2(mw - 4, mh - 4))
		if st == "broken":
			draw_rect(scr, Color("#1a0d0d"))
			Gfx.text(self, scr.position + Vector2(0, scr.size.y * 0.7), "×", int(scr.size.y * 0.8), Color("#ef5350"), scr.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		else:
			Gfx.vgrad(self, scr, sc.darkened(0.2), sc.darkened(0.7))
			var u := fmod(t * (1.0 if st == "ok" else 0.3) + i * 0.37, 1.0)
			draw_rect(Rect2(scr.position + Vector2(scr.size.x * u, scr.size.y * 0.55), Vector2(3, 3)), Color.WHITE)
		# посетитель (вид со спины)
		if occupied > 0 and st != "broken":
			occupied -= 1
			var hp := p + Vector2(0, mh * 0.9)
			draw_circle(hp - Vector2(0, 6), mw * 0.16, Color("#2a2433"))
			Gfx.rr(self, Rect2(hp + Vector2(-mw * 0.25, 2), Vector2(mw * 0.5, mh * 0.5)), Color("#3a2f4a"), 6)
			if year >= 2005:
				draw_arc(hp - Vector2(0, 6), mw * 0.18, PI, TAU, 10, Color("#111"), 3.0, true)
	# доп. зоны справа
	var ex := Rect2(Vector2(size.x * 0.7, size.y * 0.2), Vector2(size.x * 0.27, size.y * 0.72))
	var yy := ex.position.y
	if extras.has("bar"):
		Gfx.rr(self, Rect2(Vector2(ex.position.x, yy + ex.size.y * 0.18), Vector2(ex.size.x, ex.size.y * 0.12)), Color("#5a3a26"), 4, Color("#8d6e4a"), 1)
		for i in 5:
			Gfx.rr(self, Rect2(Vector2(ex.position.x + 8 + i * 16, yy + ex.size.y * 0.06), Vector2(10, 18)), [Color("#e53935"), Color("#43a047"), Color("#fbc02d"), Color("#1e88e5"), Color("#8e24aa")][i], 2)
		Gfx.text(self, Vector2(ex.position.x, yy + ex.size.y * 0.27), "БАР", 12, Color("#ffd27a"), ex.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		yy += ex.size.y * 0.36
	if extras.has("console"):
		var tv := Rect2(Vector2(ex.position.x + ex.size.x * 0.15, yy), Vector2(ex.size.x * 0.7, ex.size.y * 0.16))
		Gfx.rr(self, tv, Color("#111"), 4, Color("#333"), 1)
		Gfx.vgrad(self, tv.grow(-3), Color("#43a047"), Color("#1b5e20"))
		Gfx.rr(self, Rect2(Vector2(ex.position.x + ex.size.x * 0.05, yy + ex.size.y * 0.2), Vector2(ex.size.x * 0.9, ex.size.y * 0.08)), Color("#6a1b9a"), 8)
		Gfx.text(self, Vector2(ex.position.x, yy + ex.size.y * 0.34), "КОНСОЛИ", 11, Color("#ce93d8"), ex.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		yy += ex.size.y * 0.38
	if extras.has("vr"):
		var vp := Vector2(ex.get_center().x, yy + ex.size.y * 0.12)
		draw_circle(vp, 10, Color("#f2c9a0"))
		Gfx.rr(self, Rect2(vp + Vector2(-11, -5), Vector2(22, 8)), Color("#111"), 3)
		Gfx.rr(self, Rect2(vp + Vector2(-9, 10), Vector2(18, 26)), Color("#00acc1"), 5)
		draw_line(vp + Vector2(-9, 16), vp + Vector2(-22, 6 + sin(t * 3) * 6), Color("#00acc1"), 4)
		draw_line(vp + Vector2(9, 16), vp + Vector2(22, 6 - sin(t * 3) * 6), Color("#00acc1"), 4)
		Gfx.text(self, Vector2(ex.position.x, yy + ex.size.y * 0.3), "VR", 12, Color("#80deea"), ex.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
