extends VBoxContainer
## Всплывающие сообщения вместо журнала: появляются, держатся несколько секунд и исчезают.

var accent := Color("#ff8a1f")
var max_items := 3


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 6)


func push(bb: String) -> void:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.1, 0.94)
	sb.set_corner_radius_all(12)
	sb.border_color = Color(accent, 0.55)
	sb.border_width_left = 4
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.4)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size.x = 450
	r.add_theme_font_size_override("normal_font_size", 15)
	r.add_theme_font_size_override("bold_font_size", 15)
	r.text = bb
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(r)
	p.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			p.queue_free())
	add_child(p)
	while get_child_count() > max_items:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	p.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.18)
	tw.tween_interval(clamp(2.5 + bb.length() * 0.035, 3.5, 9.0))
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


func clear_all() -> void:
	for c in get_children():
		c.queue_free()
