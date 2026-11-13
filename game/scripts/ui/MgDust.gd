extends "res://scripts/ui/OverlayBase.gd"
const Gfx := preload("res://scripts/ui/Gfx.gd")
const PartIcon := preload("res://scripts/ui/PartIcon.gd")
## Мини-игра: чистка от пыли. Води мышкой/пальцем — сдуваешь пыль. Вентиляторы придерживай!

var dust := 50
var radius := 30.0
var tool_name := "Кисточка + сжатый воздух"
var parts: Array = []
var start_count := 0
var fans: Array = []
var hold_fan := false
var spin := 0
var broke := false
var timer := 30.0
var v: Control
var info: Label
var fan_btn: Button


func build() -> void:
	title("Чистка от пыли — " + tool_name)
	info = label("Води по пыли (зажав кнопку мыши или пальцем). Над вентиляторами включи «Держать вентилятор», иначе раскрутишь и сломаешь!", 15)
	v = view(340)
	v.draw.connect(_draw_view)
	v.gui_input.connect(_input_view)
	var r := row()
	fan_btn = btn(r, "Держать вентилятор: НЕТ", _toggle_fan)
	btn(r, "Готово", _finish)
	await get_tree().process_frame
	var sz := v.size
	fans = [Vector2(sz.x * 0.33, sz.y * 0.35), Vector2(sz.x * 0.6, sz.y * 0.72), Vector2(sz.x * 0.75, sz.y * 0.72), Vector2(sz.x * 0.9, sz.y * 0.3)]
	var n: int = max(6, dust * 3)
	for i in n:
		parts.append(Vector2(randf_range(20, sz.x - 20), randf_range(20, sz.y - 20)))
	start_count = n
	v.queue_redraw()


func _toggle_fan() -> void:
	hold_fan = not hold_fan
	fan_btn.text = "Держать вентилятор: " + ("ДА" if hold_fan else "НЕТ")


func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		_finish()
	elif int(timer * 10) % 5 == 0 and not broke:
		info.text = "Осталось пыли: %d%% · время %d с" % [_left_pct(), int(timer)]


func _left_pct() -> int:
	return 0 if start_count == 0 else int(100.0 * parts.size() / start_count)


func _input_view(e: InputEvent) -> void:
	var pos := Vector2.INF
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		pos = e.position
	elif e is InputEventScreenDrag:
		pos = e.position
	elif e is InputEventMouseButton and e.pressed:
		pos = e.position
	if pos == Vector2.INF:
		return
	var keep := []
	for p in parts:
		if p.distance_to(pos) > radius:
			keep.append(p)
	parts = keep
	for f in fans:
		if pos.distance_to(f) < 40.0 and not hold_fan:
			spin += 1
			if spin > 45 and not broke:
				broke = true
				info.text = "Вжжжжж… хрусь! Вентилятор раскрутился от воздуха и сломался."
	v.queue_redraw()
	if parts.size() <= start_count * 0.05:
		_finish()


func _finish() -> void:
	finish({"dust": int(dust * float(_left_pct()) / 100.0), "fan_broke": broke})


func _draw_view() -> void:
	var sz := v.size
	Gfx.rr(v, Rect2(Vector2.ZERO, sz), Color("#202226"), 12)
	Gfx.vgrad(v, Rect2(Vector2(4, 4), sz - Vector2(8, 8)), Color(0, 0, 0, 0), Color(0, 0, 0, 0.3))
	PartIcon.draw_part(v, {"slot": "mobo", "year": Game.year()}, Rect2(Vector2(sz.x * 0.12, sz.y * 0.08), Vector2(sz.x * 0.62, sz.y * 0.84)))
	Gfx.metal(v, Rect2(Vector2(sz.x * 0.45, sz.y * 0.62), Vector2(sz.x * 0.45, sz.y * 0.24)), Color("#3a3d44"), 6)
	for f in fans:
		Gfx.fan(v, f, 38.0, float(spin) * 0.6, Color("#16181b"), Color("#4a4e56"))
	for p in parts:
		v.draw_circle(p, 6.0, Color(0.66, 0.63, 0.57, 0.85))
		v.draw_circle(p + Vector2(3, 2), 3.5, Color(0.78, 0.75, 0.68, 0.7))
