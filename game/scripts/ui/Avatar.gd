extends Control
## Аватар клиента: нарисованное лицо, внешность зависит от имени.

const Gfx := preload("res://scripts/ui/Gfx.gd")

var who := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(52, 52)


func _draw() -> void:
	var s: float = min(size.x, size.y)
	var c := Vector2(size.x / 2.0, size.y / 2.0)
	var h: int = absi(who.hash())
	var bgs := [Color("#ff8a1f"), Color("#4a9ff0"), Color("#66bb6a"), Color("#ab47bc"), Color("#ef5350"), Color("#26a69a"), Color("#ffca28")]
	var bg: Color = bgs[h % bgs.size()]
	Gfx.circle_grad(self, c, s * 0.5, bg.lightened(0.2), bg.darkened(0.25))
	var low := who.to_lower()
	if low.contains("офис") or low.contains("«"):
		# здание вместо лица
		Gfx.rr(self, Rect2(c + Vector2(-s * 0.2, -s * 0.28), Vector2(s * 0.4, s * 0.56)), Color("#eceff1"), 2)
		for i in 3:
			for j in 2:
				draw_rect(Rect2(c + Vector2(-s * 0.13 + j * s * 0.15, -s * 0.2 + i * s * 0.15), Vector2(s * 0.1, s * 0.09)), Color("#4a9ff0"))
		return
	var skins := [Color("#f2c9a0"), Color("#e0ac80"), Color("#c68a5e"), Color("#f5d6b8")]
	var skin: Color = skins[(h / 7) % skins.size()]
	var old := low.contains("бабушк") or low.contains("дядя") or low.contains("дед")
	var hair_cols := [Color("#3e2723"), Color("#6d4c41"), Color("#212121"), Color("#f9a825"), Color("#8d6e63")]
	var hair: Color = Color("#d7d7d7") if old else hair_cols[(h / 13) % hair_cols.size()]
	var girl := low.contains("бабушк") or low.contains("аня") or low.contains("ольга") or low.contains("марина") or low.ends_with("а") and not low.contains("дима") and not low.contains("гена") and not low.contains("серёга") and not low.contains("коля")
	# шея и плечи
	Gfx.rr(self, Rect2(c + Vector2(-s * 0.3, s * 0.22), Vector2(s * 0.6, s * 0.3)), bg.darkened(0.45), s * 0.15)
	# волосы сзади
	if girl:
		Gfx.rr(self, Rect2(c + Vector2(-s * 0.25, -s * 0.24), Vector2(s * 0.5, s * 0.5)), hair, s * 0.2)
	# лицо
	draw_circle(c + Vector2(0, -s * 0.02), s * 0.22, skin)
	# причёска
	draw_arc(c + Vector2(0, -s * 0.05), s * 0.22, PI * 1.05, PI * 1.95, 16, hair, s * 0.12, true)
	if old and girl:
		draw_circle(c + Vector2(0, -s * 0.28), s * 0.09, hair)
	# глаза
	for k in [-1, 1]:
		draw_circle(c + Vector2(k * s * 0.08, -s * 0.03), s * 0.025, Color("#222"))
	if old or low.contains("программист") or low.contains("бухгалтер") or low.contains("учитель"):
		for k in [-1, 1]:
			draw_arc(c + Vector2(k * s * 0.08, -s * 0.03), s * 0.055, 0, TAU, 12, Color("#333"), 1.5, true)
		draw_line(c + Vector2(-s * 0.025, -s * 0.03), c + Vector2(s * 0.025, -s * 0.03), Color("#333"), 1.5)
	# улыбка
	draw_arc(c + Vector2(0, s * 0.04), s * 0.08, PI * 0.15, PI * 0.85, 10, Color("#8d4a3a"), 2.0, true)
	if low.contains("геймер") or low.contains("стример") or low.contains("кибер"):
		# наушники
		draw_arc(c + Vector2(0, -s * 0.02), s * 0.25, PI * 1.0, PI * 2.0, 18, Color("#222"), s * 0.05, true)
		Gfx.rr(self, Rect2(c + Vector2(-s * 0.3, -s * 0.06), Vector2(s * 0.1, s * 0.14)), Color("#222"), 3)
		Gfx.rr(self, Rect2(c + Vector2(s * 0.2, -s * 0.06), Vector2(s * 0.1, s * 0.14)), Color("#ff8a1f"), 3)
