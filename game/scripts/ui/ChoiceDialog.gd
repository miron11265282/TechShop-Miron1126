extends "res://scripts/ui/OverlayBase.gd"
## Красивое окно выбора / сообщения. Без прокрутки: варианты раскладываются в колонки и по страницам.

const Gfx := preload("res://scripts/ui/Gfx.gd")

var dlg_title := ""
var options: Array = []   # [[текст, Callable, disabled?]]
var info_bb := ""
var page := 0
const PER_PAGE := 40


func _init() -> void:
	min_size = Vector2(560, 160)
	bg_color = Color("#1a1d22")


func build() -> void:
	clear_box()
	var head := row()
	title(dlg_title, head)
	var x := btn(head, "×", func(): finish({}))
	x.custom_minimum_size = Vector2(40, 36)
	x.size_flags_horizontal = Control.SIZE_SHRINK_END
	if info_bb != "":
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.scroll_active = false
		r.custom_minimum_size.x = 760
		r.add_theme_font_size_override("normal_font_size", 16)
		r.add_theme_font_size_override("bold_font_size", 16)
		r.text = info_bb
		box.add_child(r)
		var ok := btn(row(), "Понятно", func(): finish({}))
		ok.custom_minimum_size = Vector2(160, 40)
		return
	if options.is_empty():
		label("Здесь пока пусто.", 16, Color("#9aa0a8"))
		return
	var n := options.size()
	var pages := int(ceil(float(n) / PER_PAGE))
	page = clamp(page, 0, pages - 1)
	var items := options.slice(page * PER_PAGE, min(n, (page + 1) * PER_PAGE))
	var cols: int = clamp(int(ceil(items.size() / 10.0)), 1, 4)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var bw := 860.0 / cols if cols > 1 else 520.0
	for o in items:
		var b := Button.new()
		b.text = o[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = o.size() > 2 and o[2]
		b.custom_minimum_size = Vector2(bw, 36 if cols <= 2 else 32)
		b.clip_text = true
		b.tooltip_text = o[0]
		b.add_theme_font_size_override("font_size", 15 if cols <= 2 else 13)
		var cb: Callable = o[1]
		b.pressed.connect(func():
			finish({})
			cb.call_deferred())
		grid.add_child(b)
	if pages > 1:
		var nav := row()
		nav.alignment = BoxContainer.ALIGNMENT_CENTER
		btn(nav, "◀", func():
			page -= 1
			build()).disabled = page == 0
		label("Страница %d из %d" % [page + 1, pages], 14, Color("#9aa0a8"), nav).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn(nav, "▶", func():
			page += 1
			build()).disabled = page >= pages - 1
