extends "res://scripts/ui/OverlayBase.gd"
const Gfx := preload("res://scripts/ui/Gfx.gd")
## Мини-игра: вставить память до щелчка защёлок.

var ram_name := ""
var pos := 0.0
var dir := 1.0
var tries := 3
var stopped := false
var v: Control
var info: Label


func build() -> void:
	min_size = Vector2(760, 360)
	custom_minimum_size = min_size
	title("Память: " + ram_name)
	info = label("Нажми, когда бегунок в зелёной зоне — планка встанет до щелчка обеих защёлок. Попыток: 3", 15)
	v = view(140)
	v.draw.connect(_draw_view)
	var r := row()
	btn(r, "Нажать на планку!", _press)


func _process(delta: float) -> void:
	if stopped:
		return
	pos += dir * delta * 1.3
	if pos > 1.0:
		pos = 1.0
		dir = -1.0
	elif pos < 0.0:
		pos = 0.0
		dir = 1.0
	v.queue_redraw()


func _press() -> void:
	if stopped:
		return
	if pos > 0.4 and pos < 0.6:
		stopped = true
		info.text = "Щёлк-щёлк! Обе защёлки закрылись."
		await get_tree().create_timer(0.6).timeout
		finish({"seated": true})
		return
	tries -= 1
	if tries <= 0:
		stopped = true
		info.text = "Планка села криво, не до щелчка… ПК будет пищать. Переставь память."
		await get_tree().create_timer(1.2).timeout
		finish({"seated": false})
	else:
		info.text = "Не до конца! Попробуй ещё. Попыток: %d" % tries


func _draw_view() -> void:
	var w := v.size.x - 40
	Gfx.rr(v, Rect2(Vector2(20, 50), Vector2(w, 30)), Color("#33363b"), 10)
	Gfx.rr(v, Rect2(Vector2(20 + w * 0.4, 50), Vector2(w * 0.2, 30)), Color("#3f8f4a"), 8)
	Gfx.rr(v, Rect2(Vector2(20 + w * pos - 6, 40), Vector2(12, 50)), accent, 5, Color.WHITE, 1, 4)
