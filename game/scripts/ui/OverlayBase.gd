extends PanelContainer
## Основа для мини-игр и окон (Rufus, BIOS, установка). Окно по центру, сигнал done(result).

signal done(result: Dictionary)

var box: VBoxContainer
var bg_color := Color("#25282d")
var fg := Color.WHITE
var accent := Color("#ff8a1f")
var border := true
var min_size := Vector2(880, 540)
var font_override: Font = null
var _finished := false


func _ready() -> void:
	custom_minimum_size = min_size
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	if border:
		sb.border_color = accent
		sb.set_border_width_all(2)
	add_theme_stylebox_override("panel", sb)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	build()


func build() -> void:
	pass


func clear_box() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func title(t: String, parent: Control = null) -> Label:
	return label(t, 22, accent, parent)


func label(t: String, fsize: int = 16, col: Color = Color(-1, 0, 0), parent: Control = null) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", fg if col.r < 0 else col)
	if font_override:
		l.add_theme_font_override("font", font_override)
	(parent if parent else box).add_child(l)
	return l


func btn(parent: Control, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	if font_override:
		b.add_theme_font_override("font", font_override)
	parent.add_child(b)
	return b


func row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 10)
	box.add_child(r)
	return r


func view(h: float = 330.0) -> Control:
	var v := Control.new()
	v.custom_minimum_size = Vector2(min_size.x - 40, h)
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_child(v)
	return v


func finish(r: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	done.emit(r)


static func ellipse(ci: CanvasItem, c: Vector2, r: Vector2, col: Color, steps: int = 24) -> void:
	var pts := PackedVector2Array()
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	ci.draw_colored_polygon(pts, col)
