extends Button
## Кнопка с нарисованной иконкой. Вертикальная (иконка + подпись снизу) или горизонтальная (иконка слева).

const Icons := preload("res://scripts/ui/Icons.gd")
const Gfx := preload("res://scripts/ui/Gfx.gd")

var icon_name := ""
var caption := ""
var icon_color := Color.WHITE
var horizontal := false
var badge := false
var font_size := 12
var icon_size := 26.0
var h_font := 14


func setup(ic: String, cap: String, col: Color = Color.WHITE, horiz: bool = false) -> Button:
	icon_name = ic
	caption = cap
	icon_color = col
	horizontal = horiz
	text = ""
	if horiz:
		custom_minimum_size = Vector2(Gfx.text_w(cap, h_font, true) + 44, 38)
	else:
		custom_minimum_size = Vector2(68, 66)
	tooltip_text = cap
	return self


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var col := icon_color
	if disabled:
		col = Color(col, 0.35)
	var fc := get_theme_color("font_color", "Button")
	if is_hovered() and not disabled:
		fc = Color.WHITE
	if horizontal:
		var isz: float = min(18.0, size.y - 14)
		Icons.draw(self, icon_name, Rect2(Vector2(11, (size.y - isz) / 2.0), Vector2(isz, isz)), col)
		Gfx.text(self, Vector2(18 + isz, size.y / 2.0 + h_font * 0.36), caption, h_font, fc if not disabled else Color(fc, 0.4), size.x - isz - 20, HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		var isz: float = min(icon_size, size.y * 0.42)
		Icons.draw(self, icon_name, Rect2(Vector2((size.x - isz) / 2.0, 8), Vector2(isz, isz)), col)
		# подпись в одну-две строки
		var words := caption.split(" ")
		var lines := [caption]
		if Gfx.text_w(caption, font_size) > size.x - 6 and words.size() > 1:
			var mid := int(ceil(words.size() / 2.0))
			lines = [" ".join(words.slice(0, mid)), " ".join(words.slice(mid))]
		var fs := font_size
		for ln in lines:
			while fs > 8 and Gfx.text_w(ln, fs) > size.x - 6:
				fs -= 1
		var y0 := 8 + isz + 15.0
		if lines.size() == 2:
			y0 -= 2
		for i in lines.size():
			Gfx.text(self, Vector2(2, y0 + i * (fs + 1)), lines[i], fs, fc if not disabled else Color(fc, 0.4), size.x - 4, HORIZONTAL_ALIGNMENT_CENTER)
	if badge:
		var bc := Vector2(size.x - 10, 10)
		draw_circle(bc, 6, Color("#ef5350"))
		Gfx.text(self, bc + Vector2(-6, 4), "!", 11, Color.WHITE, 12, HORIZONTAL_ALIGNMENT_CENTER, true)
