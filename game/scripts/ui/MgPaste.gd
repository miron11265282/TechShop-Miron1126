extends "res://scripts/ui/OverlayBase.gd"
const Gfx := preload("res://scripts/ui/Gfx.gd")
## Мини-игра: нанесение термопасты. Выбери способ и выдави нужное количество.

const PATTERNS := {"pea": ["Горошина", 35.0, 55.0], "cross": ["Крест", 45.0, 65.0], "spread": ["Размазать", 30.0, 50.0]}
var pattern := "pea"
var amount := 0.0
var holding := false
var done_press := false
var v: Control
var info: Label


func build() -> void:
	title("Термопаста")
	info = label("Выбери способ нанесения, потом зажми «Давить тюбик» и отпусти, когда пасты будет в самый раз (зелёная зона).", 15)
	var r := row()
	for k in PATTERNS:
		var key: String = k
		btn(r, PATTERNS[k][0], func(): _set_pattern(key))
	v = view(300)
	v.draw.connect(_draw_view)
	var r2 := row()
	var b := btn(r2, "Давить тюбик (держать)", func(): pass)
	b.button_down.connect(func(): holding = true)
	b.button_up.connect(_release)


func _set_pattern(k: String) -> void:
	if done_press:
		return
	pattern = k
	amount = 0.0
	v.queue_redraw()


func _process(delta: float) -> void:
	if holding and not done_press:
		amount = min(100.0, amount + 38.0 * delta)
		v.queue_redraw()


func _release() -> void:
	holding = false
	if done_press or amount <= 0.0:
		return
	done_press = true
	var lo: float = PATTERNS[pattern][1]
	var hi: float = PATTERNS[pattern][2]
	var q := 100
	var mess := false
	if amount < lo:
		q = int(50 + 50 * amount / lo)
		info.text = "Маловато пасты — кое-где сухо. Качество %d%%." % q
	elif amount > hi:
		q = 85
		mess = amount > hi + 15
		info.text = "Многовато!%s Качество %d%%." % [" Паста вылезла на плату — клиент посмеётся." if mess else "", q]
	else:
		info.text = "Идеально! Паста легла ровным слоем. Качество 100%."
	await get_tree().create_timer(1.4).timeout
	finish({"paste": q, "mess": mess})


func _draw_view() -> void:
	var c := Vector2(v.size.x / 2.0 - 120, v.size.y / 2.0)
	Gfx.rr(v, Rect2(c - Vector2(150, 150), Vector2(300, 300)), Color("#1e3b2c"), 12)
	for i in 8:
		v.draw_line(c + Vector2(-150, -120 + i * 34), c + Vector2(-120, -120 + i * 34), Color("#2f6b45"), 2)
	Gfx.rr(v, Rect2(c - Vector2(118, 118), Vector2(236, 236)), Color("#2f5e3a"), 8, Color("#16301f"), 2, 8)
	Gfx.metal(v, Rect2(c - Vector2(92, 92), Vector2(184, 184)), Color("#c3c8ce"), 12)
	v.draw_colored_polygon(PackedVector2Array([c - Vector2(116, 116), c - Vector2(86, 116), c - Vector2(116, 86)]), Color("#ffd54a"))
	var paste := Color("#d9dcdf")
	var a := amount / 100.0
	match pattern:
		"pea":
			Gfx.circle_grad(v, c, 10 + 70 * a, Color("#f4f5f6"), Color("#b9bdc2"))
		"cross":
			v.draw_line(c - Vector2(90, 90) * a, c + Vector2(90, 90) * a, paste, 6 + 22 * a)
			v.draw_line(c + Vector2(-90, 90) * a, c + Vector2(90, -90) * a, paste, 6 + 22 * a)
		"spread":
			v.draw_rect(Rect2(c - Vector2(90, 90), Vector2(180, 180)), Color(paste, 0.15 + 0.85 * a))
	# шкала
	var bx := Vector2(v.size.x / 2.0 + 60, 30)
	var w := 300.0
	Gfx.rr(v, Rect2(bx, Vector2(w, 26)), Color("#33363b"), 8)
	var lo: float = PATTERNS[pattern][1]
	var hi: float = PATTERNS[pattern][2]
	Gfx.rr(v, Rect2(bx + Vector2(w * lo / 100.0, 0), Vector2(w * (hi - lo) / 100.0, 26)), Color("#3f8f4a"), 6)
	Gfx.rr(v, Rect2(bx, Vector2(max(12.0, w * a), 26)), Color(accent, 0.85), 8)
	v.draw_string(get_theme_default_font(), bx + Vector2(0, 52), "Способ: %s · пасты %d%%" % [PATTERNS[pattern][0], int(amount)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, fg)
