extends Control
## Весь интерфейс игры строится кодом. Всё помещается на экран без прокрутки и масштабируется.

## Стиль по эпохам: год, название, акцент, фон верх, панели, кнопки, наведение, фон низ
const ERAS := [
	[1995, "Эпоха Windows 95", "#2bc4c4", "#1d2a2c", "#223234", "#2c4042", "#3a5658", "#101818"],
	[2001, "Эпоха Windows XP", "#4aa3ff", "#17233a", "#1c2a42", "#253752", "#30486c", "#0b1220"],
	[2007, "Эпоха Aero", "#7fd6ff", "#132433", "#182c3c", "#22394d", "#2d4c66", "#081018"],
	[2012, "Эпоха плиток", "#ff6a3d", "#211b1e", "#272125", "#322a2f", "#4a3530", "#100c0e"],
	[2021, "Эпоха TechShop", "#ff8a1f", "#1d2026", "#23262d", "#2c3038", "#463627", "#0d0f12"],
]
var C_ACCENT := Color("#ff8a1f")
const SHORT := {"mobo": "Плата", "cpu": "Процессор", "cooler": "Кулер", "ram": "Память", "gpu": "Видео", "storage": "Диск", "psu": "БП"}
var era_idx := -1
const C_GOOD := Color("#66bb6a")
const C_BAD := Color("#ef5350")
const C_WARN := Color("#ffb74d")
const C_TEXT := Color("#e9edf2")
const C_DIM := Color("#9aa3ad")

const Gfx := preload("res://scripts/ui/Gfx.gd")
const ICON_BTN := preload("res://scripts/ui/IconButton.gd")
const ICONS := preload("res://scripts/ui/Icons.gd")
const BACKDROP := preload("res://scripts/ui/Backdrop.gd")
const BENCH := preload("res://scripts/ui/BenchScene.gd")
const CHIPS := preload("res://scripts/ui/StatusChips.gd")
const TOASTS := preload("res://scripts/ui/Toasts.gd")
const DIALOG := preload("res://scripts/ui/ChoiceDialog.gd")
const AVATAR := preload("res://scripts/ui/Avatar.gd")
const F_MED := preload("res://assets/fonts/Inter-Medium.otf")
const F_SEMI := preload("res://assets/fonts/Inter-SemiBold.otf")
const F_BOLD := preload("res://assets/fonts/Inter-Bold.otf")
const F_BLACK := preload("res://assets/fonts/InterDisplay-Black.otf")

var screen := "menu"
var shop_cat := "cpu"
var shop_page := 0
var inv_page := 0
var tray_page := 0
var busy := false

var ui_theme: Theme
var backdrop
var title_label: Label
var era_label: Label
var nav_buttons := {}
var chip_labels := {}
var content: VBoxContainer
var toasts
var progress: ProgressBar
var progress_label: Label
var progress_box: Control
var busya: Control
var log_history: Array = []


func _ready() -> void:
	backdrop = BACKDROP.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# --- верхняя панель ---
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.32), 16, Color(1, 1, 1, 0.07), 1, 10, 7))
	root.add_child(bar)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	bar.add_child(top)
	var logo := Control.new()
	logo.custom_minimum_size = Vector2(40, 40)
	logo.draw.connect(func(): _draw_logo(logo))
	top.add_child(logo)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -5)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tv)
	era_label = Label.new()
	era_label.text = "miron1126"
	era_label.add_theme_font_override("font", F_BOLD)
	era_label.add_theme_font_size_override("font_size", 11)
	era_label.add_theme_color_override("font_color", C_DIM)
	tv.add_child(era_label)
	title_label = Label.new()
	title_label.text = "TechShop"
	title_label.add_theme_font_override("font", F_BLACK)
	title_label.add_theme_font_size_override("font_size", 20)
	tv.add_child(title_label)
	var sp := Control.new()
	sp.custom_minimum_size.x = 4
	top.add_child(sp)
	for n in [["menu", "home", ""], ["career", "wrench", "Заказы"], ["mypc", "tower", "Мой ПК"], ["city", "map", "Город"], ["club", "gamepad", "Клуб"], ["business", "building", "Бизнес"], ["shop", "cart", "Магазин"], ["inventory", "box", "Склад"]]:
		var b = ICON_BTN.new()
		b.h_font = 13
		b.setup(n[1], n[2], C_TEXT, true)
		if n[2] == "":
			b.custom_minimum_size.x = 40
			b.tooltip_text = "Меню"
		var sid: String = n[0]
		b.pressed.connect(func(): go(sid))
		top.add_child(b)
		nav_buttons[sid] = b
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(fill)
	for c in [["date", "calendar", Color("#9ec9ff")], ["money", "coin", Color("#7bd88f")], ["rep", "star", Color("#ffd54f")], ["treats", "fish", Color("#ff9ec4")]]:
		chip_labels[c[0]] = _chip(top, c[1], c[2])
	var jb = ICON_BTN.new()
	jb.setup("journal", "Журнал", C_TEXT)
	jb.custom_minimum_size = Vector2(40, 40)
	jb.caption = ""
	jb.icon_size = 20
	jb.tooltip_text = "Журнал событий"
	jb.pressed.connect(_show_journal)
	top.add_child(jb)
	var svb = ICON_BTN.new()
	svb.setup("save", "", C_TEXT)
	svb.custom_minimum_size = Vector2(40, 40)
	svb.icon_size = 20
	svb.tooltip_text = "Сохранить игру"
	svb.pressed.connect(func():
		Game.save_game()
		Game.say("Игра сохранена."))
	top.add_child(svb)

	# --- основной контент (без прокрутки) ---
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	root.add_child(content)

	# --- полоска прогресса поверх ---
	progress_box = PanelContainer.new()
	progress_box.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.07, 0.09, 0.95), 14, Color(1, 1, 1, 0.1), 1, 16, 10))
	progress_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress_box.position = Vector2(-220, 70)
	progress_box.custom_minimum_size = Vector2(440, 0)
	progress_box.visible = false
	add_child(progress_box)
	var pv := VBoxContainer.new()
	progress_box.add_child(pv)
	progress_label = Label.new()
	progress_label.add_theme_font_override("font", F_SEMI)
	pv.add_child(progress_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 14
	progress.show_percentage = false
	pv.add_child(progress)

	# --- всплывающие сообщения ---
	toasts = TOASTS.new()
	toasts.anchor_left = 0.5
	toasts.anchor_right = 0.5
	toasts.anchor_top = 0.0
	toasts.anchor_bottom = 0.0
	toasts.offset_left = -240
	toasts.offset_right = 240
	toasts.offset_top = 72
	toasts.offset_bottom = 400
	add_child(toasts)

	Game.changed.connect(refresh)
	Game.new_era.connect(func(y, t):
		_info("Наступил %d год!" % y, "[font_size=34][b][color=#%s]%d[/color][/b][/font_size]\n\n%s\n\nВ магазине новое железо, у клиентов — новые запросы." % [C_ACCENT.to_html(false), y, t])
		busya.say("Мяу!", "смотри, %d год! Всё вокруг поменялось" % y, 5.0))
	Game.logged.connect(_on_log)
	for l in Game.log_lines:
		log_history.append(l)
	# --- Буся ---
	busya = preload("res://scripts/Busya.gd").new()
	busya.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	busya.position = Vector2(-124, -140)
	busya.size = Vector2(110, 130)
	add_child(busya)
	busya.petted.connect(func():
		Game.pets += 1
		if Game.pets % 100 == 0:
			Game.say("[color=#ff8a1f]Буся поглажена %d раз![/color]" % Game.pets))
	busya.tip_requested.connect(_busya_tip)
	apply_era()
	go("menu")
	busya.say("Мяу!", "привет, я Буся. Погладь меня по голове, а за подсказкой нажми на лапки", 6.0)


func _draw_logo(c: Control) -> void:
	var r := Rect2(Vector2(2, 2), c.size - Vector2(4, 4))
	for i in 4:
		var u := 0.22 + i * 0.19
		for side in [[Vector2(u, 0), Vector2(u, -0.1)], [Vector2(u, 1), Vector2(u, 1.1)], [Vector2(0, u), Vector2(-0.1, u)], [Vector2(1, u), Vector2(1.1, u)]]:
			c.draw_line(r.position + r.size * side[0], r.position + r.size * side[1], C_ACCENT.darkened(0.2), 2)
	Gfx.rr(c, r.grow(-3), C_ACCENT, 8)
	Gfx.vgrad(c, Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, r.size.y * 0.4)), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0))
	Gfx.text(c, Vector2(r.position.x, r.position.y + r.size.y * 0.72), "m", int(r.size.y * 0.62), Color("#1a1205"), r.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)


func _chip(parent: Control, icon: String, col: Color) -> Label:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(col, 0.1), 19, Color(col, 0.35), 1, 9, 6))
	parent.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(18, 18)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.draw.connect(func(): ICONS.draw(ic, icon, Rect2(Vector2.ZERO, ic.size), col))
	h.add_child(ic)
	var l := Label.new()
	l.add_theme_font_override("font", F_BOLD)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", col.lightened(0.3))
	h.add_child(l)
	return l


func _input(event: InputEvent) -> void:
	if busya and (event is InputEventMouseButton or event is InputEventKey):
		busya.wake()


func _busya_tip() -> void:
	var pc = null
	if screen == "career" and not Game.current_order.is_empty():
		pc = Game.current_order["pc"]
	elif screen == "mypc":
		pc = Game.my_pc
	elif screen == "clubpc" and Game.club_open() and club_idx < Game.club["seats"].size():
		pc = Game.club["seats"][club_idx]
	if pc == null:
		busya.say("Мяу?", "открой заказ или свой ПК, тогда подскажу", 4.0)
		return
	if Game.treats <= 0:
		busya.say("Мяу...", "вкусняшки кончились. Купи в магазине или выполни заказ", 4.0)
		return
	Game.treats -= 1
	busya.say("Мяу-мяу!", Game.busya_hint(pc), 8.0)
	Game.touch()


func _on_log(line: String) -> void:
	log_history.append(line)
	if log_history.size() > 200:
		log_history.pop_front()
	if toasts:
		toasts.push(line)


func _show_journal() -> void:
	var last := log_history.slice(max(0, log_history.size() - 18))
	last.reverse()
	_info("Журнал событий", "\n".join(last) if not last.is_empty() else "Пока ничего не произошло.")


func go(s: String) -> void:
	screen = s
	refresh()


func apply_era() -> void:
	var y := Game.year()
	var idx := 0
	for i in ERAS.size():
		if y >= int(ERAS[i][0]):
			idx = i
	if idx == era_idx:
		return
	era_idx = idx
	C_ACCENT = Color(ERAS[idx][2])
	ui_theme = _make_theme()
	theme = ui_theme
	backdrop.top = Color(ERAS[idx][3])
	backdrop.bottom = Color(ERAS[idx][7])
	backdrop.accent = C_ACCENT
	if toasts:
		toasts.accent = C_ACCENT
	title_label.add_theme_color_override("font_color", C_TEXT)


func refresh() -> void:
	apply_era()
	title_label.tooltip_text = ERAS[max(0, era_idx)][1]
	chip_labels["date"].text = "%d · день %d" % [Game.year(), Game.day_of_year()]
	chip_labels["money"].text = "$%d" % Game.money
	chip_labels["rep"].text = str(Game.rep)
	chip_labels["treats"].text = str(Game.treats)
	var wide := get_viewport_rect().size.x >= 1600
	for k in nav_buttons:
		var b: Button = nav_buttons[k]
		var sel: bool = k == screen or (k == "club" and screen == "clubpc")
		# на узком экране подпись только у выбранной вкладки
		if not b.has_meta("cap"):
			b.set_meta("cap", b.caption)
		var cap: String = b.get_meta("cap")
		b.caption = cap if (sel or wide) else ""
		b.tooltip_text = cap if cap != "" else "Меню"
		b.custom_minimum_size.x = (Gfx.text_w(b.caption, 13, true) + 44) if b.caption != "" else 40
		if sel:
			b.add_theme_stylebox_override("normal", _sb(Color(C_ACCENT, 0.22), 10, Color(C_ACCENT, 0.7), 1, 12, 6))
			b.add_theme_stylebox_override("hover", _sb(Color(C_ACCENT, 0.3), 10, C_ACCENT, 1, 12, 6))
			b.icon_color = C_ACCENT.lightened(0.3)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
			b.icon_color = C_TEXT
		b.queue_redraw()
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	bench_monitor = null
	match screen:
		"menu": _build_menu()
		"career": _build_career()
		"mypc": _build_mypc()
		"shop": _build_shop()
		"inventory": _build_inventory()
		"business": _build_business()
		"city": _build_city()
		"club": _build_club()
		"clubpc": _build_clubpc()


# ============================ хелперы UI ============================

func _sb(bg: Color, rad: int = 10, border: Color = Color(0, 0, 0, 0), bw: int = 0, mx: int = 12, my: int = 8, shadow: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(rad)
	sb.corner_detail = 8
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	sb.content_margin_left = mx
	sb.content_margin_right = mx
	sb.content_margin_top = my
	sb.content_margin_bottom = my
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_offset = Vector2(0, 3)
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = F_MED
	t.default_font_size = 16
	var e: Array = ERAS[max(0, era_idx)]
	var btn := Color(e[5])
	t.set_stylebox("normal", "Button", _sb(btn, 10, Color(1, 1, 1, 0.07), 1, 14, 8))
	t.set_stylebox("hover", "Button", _sb(Color(e[6]), 10, Color(C_ACCENT, 0.55), 1, 14, 8))
	t.set_stylebox("pressed", "Button", _sb(C_ACCENT.darkened(0.25), 10, C_ACCENT, 1, 14, 8))
	t.set_stylebox("disabled", "Button", _sb(Color(btn, 0.45), 10, Color(1, 1, 1, 0.03), 1, 14, 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(C_TEXT, 0.35))
	t.set_font("font", "Button", F_SEMI)
	t.set_stylebox("panel", "PanelContainer", _sb(Color(Color(e[4]), 0.92), 16, Color(1, 1, 1, 0.06), 1, 14, 12, 12))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_font("bold_font", "RichTextLabel", F_BOLD)
	t.set_font("normal_font", "RichTextLabel", F_MED)
	var pb_bg := _sb(Color(0, 0, 0, 0.4), 7, Color(0, 0, 0, 0), 0, 0, 0)
	var pb_fill := _sb(C_ACCENT, 7, Color(0, 0, 0, 0), 0, 0, 0)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)
	t.set_stylebox("panel", "TooltipPanel", _sb(Color("#0d0f12"), 8, Color(C_ACCENT, 0.5), 1, 10, 6))
	t.set_color("font_color", "TooltipLabel", C_TEXT)
	t.set_stylebox("normal", "LineEdit", _sb(Color(0, 0, 0, 0.35), 8, Color(1, 1, 1, 0.1), 1, 10, 6))
	t.set_stylebox("focus", "LineEdit", _sb(Color(0, 0, 0, 0.45), 8, C_ACCENT, 1, 10, 6))
	t.set_stylebox("panel", "PopupMenu", _sb(Color("#15171b"), 8, Color(1, 1, 1, 0.1), 1, 6, 6))
	t.set_stylebox("normal", "OptionButton", _sb(btn, 10, Color(1, 1, 1, 0.07), 1, 14, 8))
	t.set_stylebox("hover", "OptionButton", _sb(Color(e[6]), 10, Color(C_ACCENT, 0.55), 1, 14, 8))
	t.set_stylebox("grabber_area", "HSlider", _sb(C_ACCENT, 4, Color(0, 0, 0, 0), 0, 0, 3))
	return t


func _primary(b: Button, col: Color = Color(-1, 0, 0)) -> Button:
	var c := C_ACCENT if col.r < 0 else col
	b.add_theme_stylebox_override("normal", _sb(c.darkened(0.05), 11, c.lightened(0.2), 1, 18, 9, 6))
	b.add_theme_stylebox_override("hover", _sb(c.lightened(0.1), 11, c.lightened(0.35), 1, 18, 9, 8))
	b.add_theme_stylebox_override("pressed", _sb(c.darkened(0.2), 11, c, 1, 18, 9))
	var dark := c.get_luminance() > 0.55
	b.add_theme_color_override("font_color", Color("#14100a") if dark else Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color("#14100a") if dark else Color.WHITE)
	b.add_theme_font_override("font", F_BOLD)
	return b


func _danger(b: Button) -> Button:
	b.add_theme_stylebox_override("normal", _sb(Color(C_BAD, 0.08), 11, Color(C_BAD, 0.55), 1, 16, 9))
	b.add_theme_stylebox_override("hover", _sb(Color(C_BAD, 0.2), 11, C_BAD, 1, 16, 9))
	b.add_theme_color_override("font_color", C_BAD.lightened(0.3))
	return b


func _card(parent: Control, expand_v: bool = false) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand_v:
		pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	return v


func _panel(parent: Control) -> VBoxContainer:
	return _card(parent)


func _label(parent: Control, text: String, fsize: int = 16, color: Color = C_TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	parent.add_child(l)
	return l


func _rich(parent: Control, bb: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.text = bb
	parent.add_child(r)
	return r


func _button(parent: Control, text: String, cb: Callable, disabled: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _icon(parent: Control, name: String, col: Color, sz: float = 20.0) -> Control:
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(sz, sz)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.draw.connect(func(): ICONS.draw(ic, name, Rect2(Vector2.ZERO, ic.size), col))
	parent.add_child(ic)
	return ic


func _pill(parent: Control, text: String, col: Color, icon: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(col, 0.13), 14, Color(col, 0.45), 1, 10, 4))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	p.add_child(h)
	if icon != "":
		_icon(h, icon, col, 15)
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", F_BOLD)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", col.lightened(0.3))
	h.add_child(l)
	return p


func _spacer(parent: Control) -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return s


func _content_width() -> float:
	return get_viewport_rect().size.x - 24.0


func _content_height() -> float:
	return get_viewport_rect().size.y - 24.0 - 64.0


func _choose(title: String, options: Array) -> void:
	# options: [[текст, Callable, (необязательно) disabled]]
	var d = DIALOG.new()
	d.dlg_title = title
	d.options = options
	open_overlay(d, func(_r): pass)


func _info(title: String, bb: String) -> void:
	var d = DIALOG.new()
	d.dlg_title = title
	d.info_bb = bb
	if busy:
		# поверх другого окна — просто сообщение
		Game.say("[b]%s[/b]\n%s" % [title, bb])
		return
	open_overlay(d, func(_r): pass)


func _run_task(title: String, secs: float, done: Callable) -> void:
	if busy:
		Game.say("Подожди, идёт другая операция…")
		return
	busy = true
	progress_box.visible = true
	progress_box.position = Vector2(get_viewport_rect().size.x / 2.0 - 220, 70)
	progress_label.text = title + "…"
	progress.value = 0
	var steps: int = max(1, int(secs * 20.0))
	for i in steps:
		await get_tree().create_timer(0.05).timeout
		progress.value = 100.0 * float(i + 1) / float(steps)
	progress_box.visible = false
	busy = false
	done.call()


# ============================ экраны ============================

func _build_menu() -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	content.add_child(row)
	var left := _card(row, true)
	left.get_parent().size_flags_horizontal = Control.SIZE_FILL
	left.get_parent().custom_minimum_size.x = 430
	left.add_theme_constant_override("separation", 10)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(gap)
	var t1 := _label(left, "miron1126", 54, C_TEXT, F_BLACK)
	t1.add_theme_constant_override("line_spacing", -12)
	_label(left, "TechShop", 54, C_ACCENT, F_BLACK)
	_label(left, "Почини. Собери. Разгони.", 22, C_TEXT, F_BOLD)
	_label(left, "Сейчас %d год — %s. Начни с комнаты и Pentium 75, дойди до небоскрёба в 2026-м. Чини компьютеры клиентов, ставь системы своего времени, лови вирусы и собирай ПК, перетаскивая детали." % [Game.year(), ERAS[max(0, era_idx)][1].to_lower()], 15, C_DIM)
	var st := HFlowContainer.new()
	st.add_theme_constant_override("h_separation", 6)
	st.add_theme_constant_override("v_separation", 6)
	left.add_child(st)
	_pill(st, "Заказов: %d" % Game.jobs_done, C_GOOD, "check")
	_pill(st, "Инструментов: %d" % Game.tools.size(), Color("#9ec9ff"), "wrench")
	_pill(st, "Деталей: %d" % Game.inventory.size(), C_WARN, "box")
	var play := _primary(_button(left, "Играть — в мастерскую", func(): go("career")))
	play.custom_minimum_size.y = 54
	play.add_theme_font_size_override("font_size", 20)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 6)
	left.add_child(r2)
	for b in [["tower", "Мой ПК", func(): go("mypc")], ["help", "Как играть", func(): _info("Как играть", HELP_TEXT)],
			["new", "Новая игра", func(): _choose("Начать заново? Сохранение удалится.", [["Да, начать новую игру", func():
				Game.delete_save()
				log_history.clear()
				toasts.clear_all()
				Game.new_game()]])],
			["exit", "Выход", func():
				Game.save_game()
				get_tree().quit()]]:
		var ib = ICON_BTN.new()
		ib.setup(b[0], b[1], C_TEXT)
		ib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ib.pressed.connect(b[2])
		r2.add_child(ib)
	var gap2 := Control.new()
	gap2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(gap2)
	_label(left, "Сделано miron1126 · Буся — моя племянница", 12, Color(C_DIM, 0.7))
	var demo := Game.my_pc.duplicate(true)
	demo["on"] = true
	row.add_child(_scene_frame(demo, false))


const HELP_TEXT := """[b]Мастерская[/b] — бери заказ, выполняй требование клиента и жми «Отдать клиенту».
[b]Включить[/b] — смотри, что показывает ПК. [b]Диагностика[/b] — подробный отчёт. [b]Сесть за ПК[/b] — диспетчер задач, проводник, командная строка.
Сломанную деталь найдёт [b]POST-карта[/b], блок питания — [b]мультиметр[/b]. Без них — меняй детали по одной.
Детали покупай в [b]Магазине[/b], снятые лежат на [b]Складе[/b] (их можно продать).
Собирай [b]по порядку[/b]: плата → процессор → кулер; память и видеокарта — в плату. Детали со склада [b]перетаскивай[/b] в корпус.
Процессор должен подходить к [b]сокету[/b], память — к типу (EDO, SDRAM, DDR…DDR5), видеокарта — к шине (PCI, AGP, PCIe), диск — к разъёму (IDE, SATA, NVMe).
Время идёт: 20 дней = 1 год. Каждый год выходит новое железо, системы и игры, старое дешевеет.
Windows 11 требует новый процессор и TPM 2.0. На XP нет драйверов для новых видеокарт.
Антивирус Free не видит руткиты и шпионов — нужен PRO или ручное удаление. Вымогатель лечится только переустановкой ОС.
[b]Бизнес[/b] — переезжай: комната → гараж → магазин → офис → небоскрёб. Покупай верстаки, нанимай работников — они чинят компы сами каждый день. Следи за зарплатой и настроением, иначе уволятся. Раз в 5 дней — аренда и свет.
Не воруй детали клиентов — они заметят!"""


const ORDER_TYPES := {
	"broken": ["Ремонт", "wrench", Color("#ef5350")],
	"os": ["Установка ОС", "os", Color("#4aa3ff")],
	"virus": ["Вирусы", "bug", Color("#ab47bc")],
	"slow": ["Тормозит и греется", "temp", Color("#ffb74d")],
	"fps": ["Мало FPS", "bench", Color("#26c6da")],
	"games": ["Игры", "gamepad", Color("#66bb6a")],
}


func _build_career() -> void:
	if Game.current_order.is_empty():
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		content.add_child(head)
		var hv := VBoxContainer.new()
		hv.add_theme_constant_override("separation", 0)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hv)
		_label(hv, "Клиенты ждут", 30, C_TEXT, F_BLACK)
		_label(hv, "%d год, день %d из %d · выбери заказ" % [Game.year(), Game.day_of_year(), Data.DAYS_PER_YEAR], 15, C_DIM)
		if not Game.visits.is_empty():
			var vb = ICON_BTN.new()
			vb.setup("map", "Вызовы на дом: %d" % Game.visits.size(), C_ACCENT, true)
			vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			vb.pressed.connect(func(): go("city"))
			head.add_child(vb)
		var nb = ICON_BTN.new()
		nb.setup("next", "Следующий день", C_TEXT, true)
		nb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nb.pressed.connect(func(): Game.next_day())
		head.add_child(nb)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		content.add_child(grid)
		if Game.orders.is_empty():
			var e := _card(grid)
			_label(e, "Клиентов больше нет — переходи к следующему дню.", 18, C_DIM)
		for i in Game.orders.size():
			_order_card(grid, i)
		return
	var o: Dictionary = Game.current_order
	var hc := PanelContainer.new()
	content.add_child(hc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	hc.add_child(h)
	var av = AVATAR.new()
	av.who = o["client"]
	av.custom_minimum_size = Vector2(50, 50)
	h.add_child(av)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	_label(tv, o["client"], 17, C_TEXT, F_BOLD)
	var q := _label(tv, "«%s»" % o["text"], 14, C_DIM)
	q.max_lines_visible = 2
	var ot: Array = ORDER_TYPES.get(o["type"], ["Заказ", "wrench", C_ACCENT])
	if o.get("visit", false):
		var dd := Game.district(o["district"])
		_pill(h, "Выезд: " + dd["name"], dd["col"], "map")
	_pill(h, ot[0], ot[2], ot[1])
	var req := _pill(h, o["req"], C_GOOD, "check")
	req.custom_minimum_size.x = 0
	req.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	(req.get_child(0).get_child(1) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(req.get_child(0).get_child(1) as Label).custom_minimum_size.x = 200
	_pill(h, "$%d" % o["reward"], Color("#7bd88f"), "coin")
	var give := _primary(_button(h, "Отдать клиенту", func(): Game.complete_order()), C_GOOD)
	give.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ref := _danger(_button(h, "Отказаться", func(): _choose("Точно отказаться? Будет штраф к репутации.", [["Да, отказаться", func(): Game.refuse_order()]])))
	ref.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_build_bench(o["pc"], false)


func _order_card(grid: GridContainer, i: int) -> void:
	var o: Dictionary = Game.orders[i]
	var v := _card(grid, true)
	v.add_theme_constant_override("separation", 10)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	var av = AVATAR.new()
	av.who = o["client"]
	av.custom_minimum_size = Vector2(64, 64)
	top.add_child(av)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 4)
	top.add_child(tv)
	_label(tv, o["client"], 19, C_TEXT, F_BOLD)
	var ot: Array = ORDER_TYPES.get(o["type"], ["Заказ", "wrench", C_ACCENT])
	var pr := HBoxContainer.new()
	tv.add_child(pr)
	_pill(pr, ot[0], ot[2], ot[1])
	var money := Label.new()
	money.text = "$%d" % o["reward"]
	money.add_theme_font_override("font", F_BLACK)
	money.add_theme_font_size_override("font_size", 30)
	money.add_theme_color_override("font_color", Color("#7bd88f"))
	top.add_child(money)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _sb(Color(1, 1, 1, 0.06), 12, Color(1, 1, 1, 0.06), 1, 14, 10))
	v.add_child(bubble)
	var qt := _label(bubble, "«%s»" % o["text"], 16, C_TEXT)
	qt.max_lines_visible = 3
	var rq := HBoxContainer.new()
	rq.add_theme_constant_override("separation", 8)
	v.add_child(rq)
	_icon(rq, "check", C_GOOD, 18)
	_label(rq, o["req"], 14, C_GOOD)
	var g := Control.new()
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(g)
	var idx := i
	var b := _primary(_button(v, "Взять заказ", func(): Game.take_order(idx)))
	b.custom_minimum_size.y = 44


func _build_mypc() -> void:
	var hc := PanelContainer.new()
	content.add_child(hc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	hc.add_child(h)
	_icon(h, "tower", C_ACCENT, 34)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	_label(tv, "Мой компьютер", 19, C_TEXT, F_BOLD)
	_label(tv, "Прокачивай железо, ставь игры, выбивай рекорды в бенчмарке", 14, C_DIM)
	_pill(h, "Бенчмарк: %d" % Game.bench_score(Game.my_pc), Color("#26c6da"), "bench")
	_pill(h, "Игр: %d" % Game.my_pc["games"].size(), C_GOOD, "gamepad")
	_build_bench(Game.my_pc, true)


const PC_VIEW := preload("res://scripts/ui/PcView.gd")
const MONITOR := preload("res://scripts/ui/Monitor.gd")
const PART_ICON := preload("res://scripts/ui/PartIcon.gd")
var bench_monitor: Control
var bench_pcview: Control


func _scene_frame(pc: Dictionary, interactive: bool) -> PanelContainer:
	## Комната со столом, ПК и монитором в рамке
	Game.ensure_pc(pc)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.45), 16, Color(1, 1, 1, 0.08), 1, 4, 4, 12))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc = BENCH.new()
	sc.accent = C_ACCENT
	sc.setup(pc, Game.year())
	sc.custom_minimum_size = Vector2(560, 300)
	frame.add_child(sc)
	if interactive:
		sc.pv.part_clicked.connect(func(sl): _part_menu(pc, sl))
		sc.pv.part_dropped.connect(func(sl, d): _drop_part(pc, sl, d))
		sc.pv.tooltip_text = "Перетащи деталь со склада в корпус · нажми на деталь, чтобы снять"
		bench_monitor = sc.mon
		bench_pcview = sc.pv
	return frame


func _build_bench(pc: Dictionary, mine: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	left.add_child(_scene_frame(pc, true))
	var chips = CHIPS.new()
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(chips)
	chips.setup(pc)

	# --- действия: иконки по группам ---
	var act := _card(row)
	act.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_END
	act.add_theme_constant_override("separation", 4)
	var on: bool = pc.get("on", false)
	var playing: bool = pc.get("playing", "") != ""
	var miss := Game.missing_cables(pc)
	var groups := [
		["Компьютер", [
			["power", "Выключить" if on else "Включить", func(): _power(pc), C_WARN if on else C_GOOD, false],
			["desk", "Сесть за ПК", func(): _desk(pc), Color("#9ec9ff"), false],
			["diag", "Диагностика", func(): _diagnose(pc), C_TEXT, false],
			["bench", "Бенчмарк", func(): _benchmark(pc), Color("#26c6da"), false],
		]],
		["Железо", [
			["cable", "Кабели", func(): _cables(pc), C_WARN if not miss.is_empty() else C_TEXT, not miss.is_empty()],
			["bios", "BIOS", func(): _bios(pc, ""), C_TEXT, false],
			["dust", "Чистка пыли", func(): _clean_dust(pc), C_TEXT, int(pc["dust"]) >= 40],
			["paste", "Термопаста", func(): _repaste(pc), C_TEXT, int(pc["paste"]) < 40],
		]],
		["Система", [
			["os", "Установить ОС", func(): _pick_os(pc), Color("#4aa3ff"), false],
			["drivers", "Драйверы", func(): _drivers(pc), C_TEXT, pc["os"] != "" and not pc["drivers"]],
			["backup", "Бэкап", func(): Game.say(Game.do_backup(pc)), C_TEXT, false],
			["broom", "Чистка диска", func(): _clean_disk(pc), C_TEXT, false],
			["shield", "Антивирус", func(): _scan(pc), C_GOOD, false],
			["bug", "Удалить вирусы", func(): _remove_viruses(pc), C_TEXT, false],
		]],
		["Игры", [
			["game_add", "Поставить игру", func(): _pick_game(pc, mine), C_TEXT, false],
			["game_del", "Удалить игру", func(): _uninstall_game(pc), C_TEXT, false],
			["stop" if playing else "play", "Выйти" if playing else "Играть", func(): _play(pc), C_ACCENT, false],
		]],
	]
	for g in groups:
		var hl := _label(act, String(g[0]).to_upper(), 11, C_DIM, F_BOLD)
		hl.add_theme_constant_override("line_spacing", 0)
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		act.add_child(grid)
		for it in g[1]:
			var b = ICON_BTN.new()
			b.setup(it[0], it[1], it[3])
			b.custom_minimum_size = Vector2(70, 62)
			b.font_size = 11
			b.badge = it[4]
			b.pressed.connect(it[2])
			grid.add_child(b)

	# --- склад: карточки с картинками, перетаскиваются в корпус ---
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", _sb(Color(Color(ERAS[max(0, era_idx)][4]), 0.92), 16, Color(1, 1, 1, 0.06), 1, 12, 8, 10))
	content.add_child(tp)
	var tray := HBoxContainer.new()
	tray.add_theme_constant_override("separation", 8)
	tp.add_child(tray)
	var tl := VBoxContainer.new()
	tl.custom_minimum_size.x = 118
	tl.add_theme_constant_override("separation", 0)
	tl.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_child(tl)
	_label(tl, "Склад", 17, C_TEXT, F_BOLD)
	_label(tl, "перетащи в корпус или нажми", 11, C_DIM)
	var per: int = max(1, int((_content_width() - 118 - 110 - 30) / 176.0))
	var n := Game.inventory.size()
	var pages: int = max(1, int(ceil(float(n) / per)))
	tray_page = clamp(tray_page, 0, pages - 1)
	if pages > 1:
		var pb := _button(tray, "‹", func():
			tray_page -= 1
			refresh(), tray_page == 0)
		pb.custom_minimum_size = Vector2(34, 60)
	var cards := HBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 8)
	tray.add_child(cards)
	if n == 0:
		_label(cards, "Пусто — купи детали в магазине.", 14, C_DIM).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in range(tray_page * per, min(n, (tray_page + 1) * per)):
		_tray_card(cards, pc, i)
	if pages > 1:
		var nb := _button(tray, "›", func():
			tray_page += 1
			refresh(), tray_page >= pages - 1)
		nb.custom_minimum_size = Vector2(34, 60)


func _tray_card(parent: Control, pc: Dictionary, i: int) -> void:
	var item: Dictionary = Game.inventory[i]
	var d := Data.part(item["id"])
	var ok := Game.can_place(pc, d["slot"], item["id"]) == ""
	var broken := float(item["health"]) <= 0.0
	var card := Button.new()
	card.custom_minimum_size = Vector2(168, 62)
	card.tooltip_text = Data.part_desc(item["id"]) + ("\nСЛОМАНО" if broken else "")
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_DRAG
	if ok:
		card.add_theme_stylebox_override("normal", _sb(Color(C_GOOD, 0.1), 10, Color(C_GOOD, 0.55), 1, 6, 4))
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 4
	hb.offset_right = -4
	hb.add_theme_constant_override("separation", 4)
	card.add_child(hb)
	var ic = PART_ICON.new()
	ic.part_id = item["id"]
	ic.broken = broken
	ic.custom_minimum_size = Vector2(58, 54)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(ic)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(tv)
	var sl := Label.new()
	sl.text = SHORT[d["slot"]].to_upper()
	sl.add_theme_font_override("font", F_BOLD)
	sl.add_theme_font_size_override("font_size", 9)
	sl.add_theme_color_override("font_color", C_GOOD if ok else C_DIM)
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(sl)
	var nl := Label.new()
	nl.text = d["name"]
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size.x = 96
	nl.max_lines_visible = 2
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", C_BAD if broken else C_TEXT)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(nl)
	var data := {"kind": "part", "idx": i, "id": item["id"]}
	card.set_drag_forwarding(func(_pos):
		var pv = PART_ICON.new()
		pv.part_id = item["id"]
		pv.custom_minimum_size = Vector2(96, 72)
		pv.size = Vector2(96, 72)
		card.set_drag_preview(pv)
		return data, Callable(), Callable())
	card.pressed.connect(func(): _drop_part(pc, d["slot"], data))
	parent.add_child(card)


func _part_menu(pc: Dictionary, slot: String) -> void:
	if busy:
		return
	var p = pc["parts"][slot]
	if p == null:
		_pick_part(pc, slot)
		return
	_choose("%s: %s" % [Data.SLOT_NAMES[slot], Data.part_desc(p["id"])], [
		["Снять деталь", func(): _remove_part(pc, slot)],
	])


func _power(pc: Dictionary) -> void:
	if busy:
		return
	if pc.get("on", false):
		pc["on"] = false
		pc["playing"] = ""
		Game.say("ПК выключен.")
		Game.touch()
		return
	pc["on"] = true
	var msg := Game.power_on(pc)
	Game.say("[b]Включение:[/b] " + msg)
	Game.touch()
	if bench_monitor:
		bench_monitor.boot()


func _play(pc: Dictionary) -> void:
	if pc.get("playing", "") != "":
		pc["playing"] = ""
		Game.touch()
		return
	var err := Game.check_running(pc)
	if err != "" or pc["games"].is_empty():
		Game.say(err if err != "" else "Сначала установи игру.")
		return
	var opts := []
	for gid in pc["games"]:
		var id: String = gid
		opts.append(["%s — %d FPS" % [Data.games[id]["name"], int(Game.fps(pc, id))], func():
			pc["on"] = true
			pc["playing"] = id
			Game.say("Запущена %s: %d FPS." % [Data.games[id]["name"], int(Game.fps(pc, id))])
			Game.touch()])
	_choose("Во что поиграть?", opts)


func _need_screwdriver() -> bool:
	if not Game.has_tool("screwdriver"):
		Game.say("Нужна отвёртка!")
		return false
	return true


func _remove_part(pc: Dictionary, slot: String) -> void:
	if busy or not _need_screwdriver():
		return
	var msg := Game.remove_part(pc, slot)
	Game.say(msg)
	if msg.begins_with("Сначала"):
		busya.say("Мяу!", msg.to_lower(), 3.0)


const MG_PINS := preload("res://scripts/ui/MgPins.gd")
const MG_PASTE := preload("res://scripts/ui/MgPaste.gd")
const MG_DUST := preload("res://scripts/ui/MgDust.gd")
const MG_RAM := preload("res://scripts/ui/MgRam.gd")
const MG_CABLES := preload("res://scripts/ui/MgCables.gd")
const MG_BUGS := preload("res://scripts/ui/MgBugs.gd")
const RUFUS := preload("res://scripts/ui/Rufus.gd")
const BIOS := preload("res://scripts/ui/Bios.gd")
const INSTALLER := preload("res://scripts/ui/Installer.gd")
const DESKTOP := preload("res://scripts/ui/Desktop.gd")


func open_overlay(ov: Control, cb: Callable) -> void:
	busy = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	if "accent" in ov:
		ov.accent = C_ACCENT
	cc.add_child(ov)
	ov.done.connect(func(r):
		dim.queue_free()
		busy = false
		cb.call(r), CONNECT_DEFERRED)


func _cables(pc: Dictionary) -> void:
	if busy:
		return
	var miss := Game.missing_cables(pc)
	if miss.is_empty():
		Game.say("Все кабели подключены." if pc["parts"]["psu"] != null else "Нет блока питания.")
		return
	var mg = MG_CABLES.new()
	mg.need = miss
	open_overlay(mg, func(r):
		for k in r["connected"]:
			pc["cables"][k] = true
		Game.say("Подключено кабелей: %d из %d." % [r["connected"].size(), miss.size()])
		Game.touch())


func _drop_part(pc: Dictionary, slot: String, data: Dictionary) -> void:
	if busy or not _need_screwdriver():
		return
	var idx: int = data["idx"]
	if idx >= Game.inventory.size() or Game.inventory[idx]["id"] != data["id"]:
		return
	var err := Game.can_place(pc, slot, data["id"])
	if err != "":
		Game.say("[color=#ef5350]%s[/color]" % err)
		busya.say("Мяу?", err.to_lower(), 4.0)
		return
	var d := Data.part(data["id"])
	match slot:
		"cpu":
			var mg = MG_PINS.new()
			mg.cpu_name = d["name"]
			mg.lga = String(d["socket"]).begins_with("LGA") or d["socket"] == "AM5"
			open_overlay(mg, func(r):
				Game.say(Game.place_part(pc, slot, idx))
				if r["bent"] and not r["fixed"]:
					var victim := "mobo" if mg.lga else "cpu"
					pc["parts"][victim]["health"] = 0
					pc["known_broken"].append(victim)
					Game.say("[color=#ef5350]Ножки погнуты насмерть: %s сломан(а).[/color]" % Data.SLOT_NAMES[victim])
					busya.say("Мяу…", "ой-ой, ножки погнулись", 4.0)
				elif r["bent"]:
					Game.say("Ножки выпрямлены — пронесло!")
				Game.touch())
		"cooler":
			if Game.has_tool("paste"):
				open_overlay(MG_PASTE.new(), func(r):
					Game.say(Game.place_part(pc, slot, idx))
					pc["paste"] = int(r["paste"])
					Game.say("Термопаста: %d%%%s" % [r["paste"], " — вылезла на плату!" if r["mess"] else ""])
					Game.touch())
			else:
				Game.say(Game.place_part(pc, slot, idx))
		"ram":
			var mg2 = MG_RAM.new()
			mg2.ram_name = d["name"]
			open_overlay(mg2, func(r):
				Game.say(Game.place_part(pc, slot, idx))
				pc["ram_seated"] = r["seated"]
				Game.touch())
		_:
			Game.say(Game.place_part(pc, slot, idx))
			if slot in ["psu", "mobo", "gpu", "storage"] and not Game.missing_cables(pc).is_empty():
				busya.say("Мяу!", "не забудь подключить кабели (кнопка «Кабели»)", 4.0)


func _pick_part(pc: Dictionary, slot: String) -> void:
	if busy or not _need_screwdriver():
		return
	var opts := []
	for i in Game.inventory.size():
		var item: Dictionary = Game.inventory[i]
		if Data.part(item["id"])["slot"] != slot:
			continue
		var idx := i
		var label := Data.part_desc(item["id"])
		if float(item["health"]) <= 0.0:
			label += "  [сломано]"
		opts.append([label, func(): Game.say(Game.place_part(pc, slot, idx))])
	if opts.is_empty():
		Game.say("На складе нет: %s. Купи в магазине." % Data.SLOT_NAMES[slot])
		return
	_choose("Поставить: " + Data.SLOT_NAMES[slot], opts)


func _diagnose(pc: Dictionary) -> void:
	_run_task("Диагностика", 1.0, func():
		var lines := Game.diagnose(pc)
		Game.say("[b]Диагностика:[/b]\n  " + "\n  ".join(lines))
		Game.touch())


func _clean_dust(pc: Dictionary) -> void:
	if busy:
		return
	if not Game.has_tool("brush") and not Game.has_tool("compressor"):
		Game.say("Нужна кисточка и сжатый воздух (магазин → инструменты).")
		return
	var mg = MG_DUST.new()
	mg.dust = int(pc["dust"])
	if Game.has_tool("compressor"):
		mg.radius = 55.0
		mg.tool_name = "Компрессор"
	open_overlay(mg, func(r):
		pc["dust"] = int(r["dust"])
		if r["fan_broke"] and pc["parts"]["cooler"] != null:
			pc["parts"]["cooler"]["health"] = 0
			pc["known_broken"].append("cooler")
			Game.say("[color=#ef5350]Вентилятор кулера сломан — раскрутил его воздухом. Нужен новый кулер.[/color]")
			busya.say("Мяу!", "надо было придержать вентилятор!", 4.0)
		Game.say("Чистка от пыли: осталось %d%% пыли." % int(pc["dust"]))
		Game.touch())

func _repaste(pc: Dictionary) -> void:
	if busy:
		return
	if not Game.has_tool("paste"):
		Game.say("Нужна термопаста (магазин → инструменты).")
		return
	if pc["parts"]["cpu"] == null:
		Game.say("Нет процессора.")
		return
	open_overlay(MG_PASTE.new(), func(r):
		pc["paste"] = int(r["paste"])
		Game.say("Термопаста нанесена: качество %d%%%s" % [r["paste"], " (вылезла на плату!)" if r["mess"] else ""])
		Game.touch())

func _pick_os(pc: Dictionary) -> void:
	if busy:
		return
	var opts := []
	for id in Data.os_available(Game.year()):
		var o: Dictionary = Data.os_list[id]
		var os_id: String = id
		var have := Game.keys.count(os_id)
		var key_txt := "бесплатно" if o["linux"] else ("ключей: %d" % have)
		opts.append(["%s  (%d) — %s, %s" % [o["name"], o["year"], Game.MEDIA_NAME[o["media"]], key_txt], func(): _install_flow(pc, os_id)])
	_choose("Какую ОС установить?", opts)


func _install_flow(pc: Dictionary, os_id: String) -> void:
	var err := Game.can_install_os(pc, os_id)
	if err != "":
		Game.say("[color=#ef5350]%s[/color]" % err)
		busya.say("Мяу…", err.to_lower(), 4.0)
		return
	var o: Dictionary = Data.os_list[os_id]
	if not o["linux"] and int(o["gen"]) < 5 and not Game.keys.has(os_id):
		Game.say("[color=#ef5350]Для %s нужен ключ — купи в Магазине → Ключи.[/color]" % o["name"])
		busya.say("Мяу!", "без ключа эту систему не поставить, купи в магазине", 4.0)
		return
	if o["media"] == "usb" and Game.flash.get("os", "") != os_id:
		Game.say("Сначала запиши загрузочную флешку в Rufus.")
		_rufus(os_id, func(): _bios(pc, os_id))
		return
	_bios(pc, os_id)


func _rufus(want: String, then: Callable) -> void:
	var r = RUFUS.new()
	r.year = Game.year()
	r.isos = Game.isos.duplicate()
	r.choices = Data.os_available(Game.year()).filter(func(id): return Data.os_list[id]["media"] == "usb")
	r.want = want
	r.os_list = Data.os_list
	open_overlay(r, func(res):
		Game.isos = res.get("isos", Game.isos)
		if res.has("os"):
			Game.flash = {"os": res["os"], "scheme": res["scheme"]}
			Game.say("Флешка записана: %s (%s)." % [Data.os_list[res["os"]]["name"], res["scheme"]])
			then.call()
		Game.touch())


func _bios(pc: Dictionary, os_id: String) -> void:
	if busy:
		return
	if not Game.boot_problems(pc).is_empty():
		Game.say("ПК не проходит POST — в BIOS не зайти. Сначала почини железо.")
		return
	Game.ensure_pc(pc)
	var b = BIOS.new()
	b.bios = pc["bios"].duplicate(true)
	b.uefi = Game.is_uefi(pc)
	var mb := Game.pdata(pc, "mobo")
	b.has_tpm = mb["tpm"]
	b.ram_type = Game.pdata(pc, "ram")["ram"]
	b.board_year = int(mb["year"])
	b.board_name = mb["name"]
	open_overlay(b, func(res):
		if res.has("bios"):
			pc["bios"] = res["bios"]
			Game.say("Настройки BIOS сохранены.")
		if os_id != "":
			var e := Game.boot_media_check(pc, os_id)
			if e != "":
				Game.say("[color=#ef5350]%s[/color]" % e)
				busya.say("Мяу!", e.to_lower(), 6.0)
			else:
				_installer(pc, os_id)
		Game.touch())


func _installer(pc: Dictionary, os_id: String) -> void:
	var o: Dictionary = Data.os_list[os_id]
	var w = INSTALLER.new()
	w.os_id = os_id
	w.os_name = o["name"]
	w.gen = int(o["gen"])
	w.linux = o["linux"]
	w.keys = Game.keys.count(os_id)
	w.has_files = pc.get("files", false)
	w.backup = pc.get("backup", false)
	w.storage_name = Game.pdata(pc, "storage")["name"]
	w.old_os = Data.os_list[pc["os"]]["name"] if pc["os"] != "" else ""
	w.copy_time = Game.os_install_time(pc, os_id)
	open_overlay(w, func(res):
		if not res.get("ok", false):
			Game.say("Установка отменена.")
			return
		var had_files: bool = pc.get("files", false)
		Game.say(Game.install_os(pc, os_id, false))
		if res["key"]:
			Game.keys.erase(os_id)
		pc["activated"] = res["key"] or o["linux"] or os_id == "dos"
		pc["user"] = String(res.get("user", "User"))
		pc["files"] = had_files and pc.get("backup", false)
		if had_files and not pc["files"]:
			Game.say("[color=#ef5350]Файлы клиента удалены при форматировании…[/color]")
		elif had_files:
			Game.say("Файлы клиента восстановлены из бэкапа.")
		if not pc["activated"]:
			Game.say("На экране надпись «Активируйте Windows».")
		Game.touch())

func _drivers(pc: Dictionary) -> void:
	var err := Game.can_drivers(pc)
	if err != "":
		Game.say(err)
		return
	_run_task("Установка драйверов", 1.5, func():
		pc["drivers"] = true
		Game.say("Драйверы установлены. Разрешение экрана нормальное!")
		Game.touch())


func _desk(pc: Dictionary) -> void:
	if busy:
		return
	if not pc.get("on", false):
		Game.say("Сначала включи ПК.")
		return
	var err := Game.check_running(pc)
	if err != "":
		Game.say(err)
		return
	if pc.get("playing", "") != "":
		pc["playing"] = ""
	var d = DESKTOP.new()
	d.pc = pc
	open_overlay(d, func(r):
		if r.get("crash", "") != "":
			Game.say("[color=#ef5350]" + r["crash"] + "[/color]")
		if r.get("changed", false):
			Game.say("Ты встал из-за компьютера." + (" Вирусов осталось: %d." % pc["viruses"].size() if pc["viruses"].size() > 0 and pc["scanned"] else ""))
		Game.touch())


func _scan(pc: Dictionary) -> void:
	if busy:
		return
	var err := Game.check_running(pc)
	if err != "":
		Game.say(err + (" Вымогателя лечит только переустановка ОС." if err.contains("вымогател") else ""))
		return
	pc["missed"] = []
	pc["scanned"] = true
	var vis := Game.visible_viruses(pc)
	if vis.is_empty():
		_run_task("Сканирование антивирусом", 1.5, func():
			Game.say("[b]Антивирус:[/b] " + Game.virus_text(pc))
			Game.touch())
		return
	var mg = MG_BUGS.new()
	mg.total = vis.size()
	open_overlay(mg, func(r):
		var caught: int = r["caught"]
		var miss := vis.slice(caught)
		pc["missed"] = miss
		Game.say("[b]Антивирус:[/b] %s%s" % [Game.virus_text(pc), (" — упущено угроз: %d, просканируй ещё раз" % miss.size()) if not miss.is_empty() else ""])
		Game.touch())

func _remove_viruses(pc: Dictionary) -> void:
	if not pc["scanned"]:
		Game.say("Сначала просканируй.")
		return
	var vis := Game.visible_viruses(pc)
	if vis.is_empty():
		Game.say("Антивирус ничего не нашёл." + ("" if Game.av_level() >= 2 else " (Free-версия видит не всё…)"))
		return
	_run_task("Удаление вирусов", 1.5, func():
		for v in vis:
			pc["viruses"].erase(v)
		Game.say("Удалено вирусов: %d." % vis.size())
		Game.touch())


func _clean_disk(pc: Dictionary) -> void:
	var err := Game.check_running(pc)
	if err != "":
		Game.say(err)
		return
	if Game.has_tool("cleaner"):
		_run_task("Очистка диска", 2.0, func():
			Game.say("Удалено %s мусора." % Data.gb_text(float(pc["junk"])))
			pc["junk"] = 0.0
			Game.touch())
	else:
		_run_task("Ручная чистка Temp", 2.0, func():
			var j := float(pc["junk"]) * 0.5
			pc["junk"] = float(pc["junk"]) - j
			Game.say("Вручную удалено %s. Программа очистки удалит всё." % Data.gb_text(j))
			Game.touch())


func _pick_game(pc: Dictionary, mine: bool) -> void:
	var opts := []
	var list: Array = Game.owned_games if mine else Data.games_available(Game.year())
	for gid in list:
		var g: Dictionary = Data.games[gid]
		var id: String = gid
		opts.append(["%s  (%d) — %s" % [g["name"], g["year"], Data.gb_text(g["gb"])], func():
			var err := Game.can_game(pc, id)
			if err != "":
				Game.say(err)
				return
			_run_task("Установка " + g["name"], Game.game_install_time(pc, id), func():
				pc["games"].append(id)
				pc["junk"] = float(pc["junk"]) + float(g["gb"]) * 0.02
				Game.say("Игра %s установлена." % g["name"])
				Game.touch())])
	if mine:
		opts.append(["Купить ещё игр…", func():
			shop_cat = "games"
			go("shop")])
	_choose("Какую игру установить?", opts)


func _uninstall_game(pc: Dictionary) -> void:
	var opts := []
	for gid in pc["games"]:
		var id: String = gid
		opts.append([Data.games[id]["name"], func():
			pc["games"].erase(id)
			Game.say("Удалена " + Data.games[id]["name"])
			Game.touch()])
	_choose("Какую игру удалить?", opts)


func _benchmark(pc: Dictionary) -> void:
	var err := Game.check_running(pc)
	if err != "":
		Game.say(err)
		return
	if not Game.psu_ok(pc):
		Game.say("[color=#ef5350]Под нагрузкой ПК резко выключился — слабый блок питания![/color]")
		return
	_run_task("Бенчмарк", 3.0, func():
		var bb := "[b]Очки бенчмарка: %d[/b]\nТемпература под нагрузкой: %d°C\n\n" % [Game.bench_score(pc), int(Game.temp(pc))]
		if pc["games"].is_empty():
			bb += "Установи игры, чтобы увидеть FPS."
		else:
			bb += "[table=5][cell][b]Игра[/b]  [/cell]"
			for q in Data.QUALITIES:
				bb += "[cell][b]%s[/b]  [/cell]" % q[1]
			for gid in pc["games"]:
				bb += "[cell]%s  [/cell]" % Data.games[gid]["name"]
				for q in Data.QUALITIES:
					var f := Game.fps(pc, gid, q[2])
					var col := "#66bb6a" if f >= 60 else ("#ffb74d" if f >= 30 else "#ef5350")
					bb += "[cell][color=%s]%d FPS[/color]  [/cell]" % [col, int(f)]
			bb += "[/table]"
		Game.say("Бенчмарк: %d очков." % Game.bench_score(pc))
		_info("Результаты бенчмарка", bb))


# ============================ магазин и склад ============================

const SHOP_CATS := [["cpu", "cpu", "Процессоры"], ["mobo", "mobo", "Платы"], ["ram", "ram", "Память"], ["gpu", "gpu", "Видеокарты"],
	["storage", "disk", "Диски"], ["psu", "psu", "Блоки питания"], ["cooler", "fan", "Кулеры"], ["tools", "wrench", "Инструменты"],
	["keys", "key", "Ключи Windows"], ["games", "gamepad", "Игры"]]


func _grid_pager(total: int, per: int, page_var: String) -> Array:
	## Возвращает [первый, последний, страниц] и чинит номер страницы
	var pages: int = max(1, int(ceil(float(total) / per)))
	var p: int = clamp(get(page_var), 0, pages - 1)
	set(page_var, p)
	return [p * per, min(total, (p + 1) * per), pages]


func _pager_row(parent: Control, pages: int, page_var: String) -> void:
	if pages <= 1:
		return
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", 10)
	parent.add_child(r)
	var p: int = get(page_var)
	_button(r, "‹ Назад", func():
		set(page_var, p - 1)
		refresh(), p == 0)
	var l := Label.new()
	l.text = "%d / %d" % [p + 1, pages]
	l.add_theme_color_override("font_color", C_DIM)
	r.add_child(l)
	_button(r, "Дальше ›", func():
		set(page_var, p + 1)
		refresh(), p >= pages - 1)


func _build_shop() -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var side := _card(row, true)
	side.get_parent().size_flags_horizontal = Control.SIZE_FILL
	side.get_parent().custom_minimum_size.x = 214
	side.add_theme_constant_override("separation", 4)
	_label(side, "Магазин", 24, C_TEXT, F_BLACK)
	_label(side, "%d год · цены падают со временем" % Game.year(), 12, C_DIM)
	for c in SHOP_CATS:
		var cid: String = c[0]
		var b = ICON_BTN.new()
		b.setup(c[1], c[2], C_ACCENT.lightened(0.3) if cid == shop_cat else C_TEXT, true)
		b.custom_minimum_size = Vector2(190, 38)
		if cid == shop_cat:
			b.add_theme_stylebox_override("normal", _sb(Color(C_ACCENT, 0.2), 10, Color(C_ACCENT, 0.7), 1, 12, 6))
		b.pressed.connect(func():
			shop_cat = cid
			shop_page = 0
			refresh())
		side.add_child(b)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 10)
	row.add_child(main)
	var cols: int = clamp(int((_content_width() - 226) / 250.0), 2, 6)
	var rows: int = clamp(int((_content_height() - 70) / 250.0), 1, 4)
	match shop_cat:
		"tools":
			_label(main, "Инструменты мастера", 24, C_TEXT, F_BLACK)
			var items := [["treat", "Вкусняшка для Буси", "За неё Буся даст подсказку. Сейчас: %d" % Game.treats, 5, false]]
			for id in Data.tools:
				if Game.tool_available(id):
					var t: Dictionary = Data.tools[id]
					items.append([id, t["name"], t["desc"], int(t["price"]), Game.has_tool(id)])
			var rng := _grid_pager(items.size(), cols * max(1, rows + 1), "shop_page")
			var grid := _shop_grid(main, cols)
			for k in range(rng[0], rng[1]):
				var it: Array = items[k]
				var tid: String = it[0]
				var v := _shop_card(grid, it[1], it[2], "fish" if tid == "treat" else "wrench", "")
				if it[4]:
					_pill(v, "Есть", C_GOOD, "check")
				else:
					var buy := (func(): Game.buy_treat()) if tid == "treat" else (func(): Game.buy_tool(tid))
					_primary(_button(v, "Купить · $%d" % it[3], buy, Game.money < it[3]))
			_pager_row(main, rng[2], "shop_page")
		"keys":
			_label(main, "Ключи активации", 24, C_TEXT, F_BLACK)
			_label(main, "Ключ тратится при установке Windows. Без ключа — надпись «Активируйте Windows». Linux — бесплатно.", 14, C_DIM)
			var ids := []
			for id in Data.os_available(Game.year()):
				if not Data.os_list[id]["linux"]:
					ids.append(id)
			var rng := _grid_pager(ids.size(), cols * max(1, rows + 1), "shop_page")
			var grid := _shop_grid(main, cols)
			for k in range(rng[0], rng[1]):
				var kid: String = ids[k]
				var o: Dictionary = Data.os_list[kid]
				var v := _shop_card(grid, o["name"], "Вышла в %d · у тебя ключей: %d" % [o["year"], Game.keys.count(kid)], "key", "")
				_primary(_button(v, "Купить · $%d" % o["price"], func(): Game.buy_key(kid), Game.money < int(o["price"])))
			_pager_row(main, rng[2], "shop_page")
		"games":
			_label(main, "Игры", 24, C_TEXT, F_BLACK)
			_label(main, "Для твоего ПК — %s. Клиентам игры ставишь бесплатно." % Game.game_source(), 14, C_DIM)
			var ids: Array = Data.games_available(Game.year())
			ids.reverse()
			var rng := _grid_pager(ids.size(), cols * max(1, rows + 1), "shop_page")
			var grid := _shop_grid(main, cols)
			for k in range(rng[0], rng[1]):
				var gid: String = ids[k]
				var g: Dictionary = Data.games[gid]
				var v := _shop_card(grid, g["name"], "%d · %s%s" % [g["year"], Data.gb_text(g["gb"]), " · Miron1126 Launcher" if g.has("miron") else ""], "gamepad", "НОВИНКА" if int(g["year"]) == Game.year() else "")
				if Game.owned_games.has(gid):
					_pill(v, "Куплена", C_GOOD, "check")
				else:
					_primary(_button(v, "Бесплатно" if int(g["price"]) == 0 else "Купить · $%d" % g["price"], func(): Game.buy_game(gid), Game.money < int(g["price"])))
			_pager_row(main, rng[2], "shop_page")
		_:
			var title := ""
			for c in SHOP_CATS:
				if c[0] == shop_cat:
					title = c[2]
			_label(main, title, 24, C_TEXT, F_BLACK)
			var av := Data.available(shop_cat, Game.year())
			av.reverse()
			var rng := _grid_pager(av.size(), cols * rows, "shop_page")
			var grid := _shop_grid(main, cols)
			for k in range(rng[0], rng[1]):
				var pid: String = av[k]
				var d := Data.part(pid)
				var age := Game.year() - int(d["year"])
				var v := _shop_card(grid, d["name"], Data.part_desc(pid).replace(d["name"] + " · ", ""), "", "НОВИНКА" if age == 0 else str(d["year"]), pid)
				var pr := Data.price_in(pid, Game.year())
				_primary(_button(v, "Купить · $%d" % pr, func(): Game.buy_part(pid), Game.money < pr))
			if av.is_empty():
				_label(main, "В этом году здесь пусто.", 16, C_DIM)
			_pager_row(main, rng[2], "shop_page")


func _shop_grid(parent: Control, cols: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	return grid


func _shop_card(grid: GridContainer, name: String, desc: String, icon: String, tag: String, part_id: String = "") -> VBoxContainer:
	var v := _card(grid)
	v.get_parent().custom_minimum_size = Vector2(230, 0)
	v.add_theme_constant_override("separation", 6)
	var pic := PanelContainer.new()
	pic.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.25), 12, Color(1, 1, 1, 0.04), 1, 6, 6))
	v.add_child(pic)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 86 if part_id != "" else 46)
	pic.add_child(holder)
	if part_id != "":
		var ic = PART_ICON.new()
		ic.part_id = part_id
		ic.spin = true
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 30
		ic.offset_right = -30
		holder.add_child(ic)
	elif icon == "gamepad":
		holder.custom_minimum_size.y = 64
		var nm := name
		holder.draw.connect(func(): _draw_cover(holder, nm))
	else:
		var ic := _icon(holder, icon, C_ACCENT, 34)
		ic.set_anchors_preset(Control.PRESET_CENTER)
		ic.position = Vector2(-17, -17)
	if tag != "":
		var tg := Label.new()
		tg.text = tag
		tg.add_theme_font_override("font", F_BOLD)
		tg.add_theme_font_size_override("font_size", 10)
		tg.add_theme_color_override("font_color", C_ACCENT if tag == "НОВИНКА" else C_DIM)
		tg.position = Vector2(6, 2)
		holder.add_child(tg)
	var nl := _label(v, name, 15, C_TEXT, F_BOLD)
	nl.max_lines_visible = 2
	var dl := _label(v, desc, 12, C_DIM)
	dl.max_lines_visible = 2
	dl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return v


func _draw_cover(c: Control, name: String) -> void:
	## Обложка игры: свой рисунок по названию (без настоящих логотипов)
	var r := Rect2(Vector2.ZERO, c.size)
	var h: int = absi(name.hash())
	var c1 := Color.from_hsv(fmod(h * 0.00013, 1.0), 0.7, 0.75)
	var c2 := Color.from_hsv(fmod(h * 0.00013 + 0.12, 1.0), 0.8, 0.3)
	Gfx.rr(c, r, c2, 8)
	Gfx.vgrad(c, r.grow(-1), c1, c2)
	var rng := RandomNumberGenerator.new()
	rng.seed = h
	for i in 5:
		var p := Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		Gfx.glow(c, p, rng.randf_range(20, 60), Color(1, 1, 1, 0.12))
	var pts := PackedVector2Array([Vector2(0, r.size.y)])
	for i in 9:
		pts.append(Vector2(r.size.x * i / 8.0, r.size.y * (0.55 + rng.randf() * 0.3)))
	pts.append(Vector2(r.size.x, r.size.y))
	c.draw_colored_polygon(pts, Color(0, 0, 0, 0.35))
	var words := name.replace(":", "").split(" ", false)
	var ab := ""
	for w in words:
		if ab.length() < 3 and w.length() > 0:
			ab += w.left(1).to_upper()
	Gfx.text(c, Vector2(0, r.size.y * 0.66), ab, int(r.size.y * 0.42), Color(1, 1, 1, 0.92), r.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)


func _build_inventory() -> void:
	var head := HBoxContainer.new()
	content.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	_label(hv, "Склад", 30, C_TEXT, F_BLACK)
	_label(hv, "Детали, снятые с компьютеров и купленные в магазине. Ненужное можно продать.", 14, C_DIM)
	_pill(head, "Деталей: %d" % Game.inventory.size(), C_WARN, "box")
	var cols: int = clamp(int(_content_width() / 240.0), 2, 7)
	var rows: int = clamp(int((_content_height() - 190) / 190.0), 1, 4)
	var rng := _grid_pager(Game.inventory.size(), cols * rows, "inv_page")
	var grid := _shop_grid(content, cols)
	if Game.inventory.is_empty():
		var e := _card(grid)
		_label(e, "Пусто. Покупай детали в магазине или снимай со своих ПК.", 16, C_DIM)
	for i in range(rng[0], rng[1]):
		var item: Dictionary = Game.inventory[i]
		var idx := i
		var broken := float(item["health"]) <= 0.0
		var d := Data.part(item["id"])
		var v := _shop_card(grid, d["name"], Data.part_desc(item["id"]).replace(d["name"] + " · ", ""), "", "СЛОМАНО" if broken else SHORT[d["slot"]].to_upper(), item["id"])
		_button(v, "Продать · $%d" % Game.sell_price(item), func(): Game.sell_item(idx))
	_pager_row(content, rng[2], "inv_page")
	var t := _card(content)
	var tr := HFlowContainer.new()
	tr.add_theme_constant_override("h_separation", 6)
	tr.add_theme_constant_override("v_separation", 6)
	t.add_child(tr)
	var tl := Label.new()
	tl.text = "Инструменты:"
	tl.add_theme_font_override("font", F_BOLD)
	tr.add_child(tl)
	for id in Game.tools:
		_pill(tr, Data.tools[id]["name"], Color("#9ec9ff"), "wrench")



# ============================ бизнес ============================
var worker_page := 0


func _draw_building(c: Control, st: int) -> void:
	var r := Rect2(Vector2.ZERO, c.size)
	Gfx.rr(c, r, Color("#0e1520"), 12)
	Gfx.vgrad(c, r.grow(-2), Color("#4f86d6"), Color("#c9e2ff"))
	var g := r.end.y - r.size.y * 0.16
	c.draw_rect(Rect2(Vector2(2, g), Vector2(r.size.x - 4, r.end.y - g - 2)), Color("#5d7a4a"))
	var cx := r.size.x / 2.0
	match st:
		0:
			# дом, светится окно комнаты
			Gfx.rr(c, Rect2(Vector2(cx - 50, g - 70), Vector2(100, 70)), Color("#d7c4a3"), 2)
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 60, g - 68), Vector2(cx, g - 108), Vector2(cx + 60, g - 68)]), Color("#a0432f"))
			Gfx.rr(c, Rect2(Vector2(cx - 34, g - 52), Vector2(26, 22)), Color("#ffd27a"), 2)
			Gfx.rr(c, Rect2(Vector2(cx + 10, g - 52), Vector2(26, 22)), Color("#6aa0d8"), 2)
			Gfx.rr(c, Rect2(Vector2(cx - 8, g - 30), Vector2(16, 30)), Color("#6d4c35"), 2)
		1:
			Gfx.rr(c, Rect2(Vector2(cx - 70, g - 76), Vector2(140, 76)), Color("#8a8f96"), 3)
			for i in 9:
				c.draw_line(Vector2(cx - 56, g - 60 + i * 7), Vector2(cx + 56, g - 60 + i * 7), Color("#6b7077"), 2)
			Gfx.rr(c, Rect2(Vector2(cx - 56, g - 64), Vector2(112, 22)), Color("#ffd27a"), 2)
			Gfx.text(c, Vector2(cx - 56, g - 48), "РЕМОНТ ПК", 12, Color("#5a3a00"), 112, HORIZONTAL_ALIGNMENT_CENTER, true)
		2:
			Gfx.rr(c, Rect2(Vector2(cx - 80, g - 90), Vector2(160, 90)), Color("#eae2d2"), 2)
			for i in 6:
				c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 80 + i * 26.6, g - 70), Vector2(cx - 80 + (i + 1) * 26.6, g - 70), Vector2(cx - 80 + (i + 0.5) * 26.6, g - 56)]), C_ACCENT if i % 2 == 0 else Color.WHITE)
			Gfx.rr(c, Rect2(Vector2(cx - 70, g - 52), Vector2(90, 46)), Color("#9fd0ff"), 2, Color("#555"), 2)
			Gfx.rr(c, Rect2(Vector2(cx + 30, g - 50), Vector2(30, 50)), Color("#6d4c35"), 2)
			Gfx.text(c, Vector2(cx - 80, g - 76), "miron1126", 13, C_ACCENT, 160, HORIZONTAL_ALIGNMENT_CENTER, true)
		3:
			Gfx.rr(c, Rect2(Vector2(cx - 60, g - 120), Vector2(120, 120)), Color("#7b93b3"), 3)
			for i in 5:
				for j in 4:
					Gfx.rr(c, Rect2(Vector2(cx - 50 + j * 26, g - 110 + i * 22), Vector2(20, 14)), Color("#cfe6ff") if (i + j) % 3 else Color("#ffd27a"), 1)
		4:
			Gfx.rr(c, Rect2(Vector2(cx - 30, r.position.y + 10), Vector2(60, g - 10)), Color("#2c3a55"), 3)
			c.draw_line(Vector2(cx, r.position.y + 2), Vector2(cx, r.position.y + 12), Color("#ccc"), 2)
			for i in 14:
				for j in 3:
					c.draw_rect(Rect2(Vector2(cx - 22 + j * 16, r.position.y + 20 + i * ((g - 34) / 14.0)), Vector2(10, 5)), Color("#9fd0ff") if (i * 3 + j) % 4 else Color("#ffd27a"))
			Gfx.text(c, Vector2(cx - 30, r.position.y + 30), "m", 16, C_ACCENT, 60, HORIZONTAL_ALIGNMENT_CENTER, true)


func _build_business() -> void:
	var st := Game.stage_info()
	# --- шапка: где мы и куда дальше ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)
	var hc := _card(top)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 14)
	hc.add_child(hh)
	var pic := Control.new()
	pic.custom_minimum_size = Vector2(190, 120)
	var stn := Game.stage
	pic.draw.connect(func(): _draw_building(pic, stn))
	hh.add_child(pic)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 4)
	hh.add_child(tv)
	_label(tv, "ЭТАП %d ИЗ %d" % [Game.stage + 1, Data.STAGES.size()], 11, C_DIM, F_BOLD)
	_label(tv, st["name"], 30, C_TEXT, F_BLACK)
	_label(tv, st["desc"], 14, C_DIM)
	var pills := HFlowContainer.new()
	pills.add_theme_constant_override("h_separation", 6)
	pills.add_theme_constant_override("v_separation", 6)
	tv.add_child(pills)
	_pill(pills, "Верстаков: %d / %d" % [Game.benches, st["benches"]], Color("#9ec9ff"), "wrench")
	_pill(pills, "Работников: %d / %d" % [Game.workers.size(), st["workers"]], C_GOOD, "person")
	_pill(pills, "Аренда: $%d / 5 дней" % st["rent"], C_WARN, "calendar")
	var est := Game.worker_day_estimate()
	_pill(pills, ("Работники: +$%d в день" if est >= 0 else "Работники: −$%d в день") % absi(est), C_GOOD if est >= 0 else C_BAD, "coin")
	# переезд
	var mv := _card(top)
	mv.get_parent().custom_minimum_size.x = 330
	mv.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_END
	if Game.stage < Data.STAGES.size() - 1:
		var nx := Game.stage_info(Game.stage + 1)
		_label(mv, "СЛЕДУЮЩИЙ ПЕРЕЕЗД", 11, C_DIM, F_BOLD)
		_label(mv, nx["name"], 24, C_ACCENT, F_BLACK)
		var rq := HBoxContainer.new()
		rq.add_theme_constant_override("separation", 6)
		mv.add_child(rq)
		_pill(rq, "★ %d" % nx["rep"], C_GOOD if Game.rep >= int(nx["rep"]) else C_BAD, "star")
		_pill(rq, "$%d" % nx["cost"], C_GOOD if Game.money >= int(nx["cost"]) else C_BAD, "coin")
		_label(mv, nx["desc"], 12, C_DIM)
		var e := Game.can_move()
		var b := _primary(_button(mv, "Переехать!", _do_move, e != ""))
		b.tooltip_text = e if e != "" else "Всё готово к переезду"
		b.custom_minimum_size.y = 44
	else:
		_label(mv, "Вершина!", 24, C_ACCENT, F_BLACK)
		_label(mv, "Ты построил империю miron1126. Дальше — бренд Busya Force и BusyaBox.", 14, C_DIM)
	# --- работники и кандидаты ---
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	var lh := HBoxContainer.new()
	left.add_child(lh)
	_label(lh, "Команда", 22, C_TEXT, F_BLACK)
	if Game.stage >= 2:
		var mk := HBoxContainer.new()
		mk.add_theme_constant_override("separation", 8)
		lh.add_child(mk)
		var ml := Label.new()
		ml.text = "Цены в мастерской: ×%.2f" % Game.markup
		ml.add_theme_color_override("font_color", C_DIM)
		mk.add_child(ml)
		var sl := HSlider.new()
		sl.min_value = 0.8
		sl.max_value = 1.5
		sl.step = 0.05
		sl.value = Game.markup
		sl.custom_minimum_size = Vector2(160, 20)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.tooltip_text = "Дороже — больше денег, но меньше клиентов"
		sl.drag_ended.connect(func(_c):
			Game.markup = sl.value
			Game.say("Цены ×%.2f. Дороже — больше денег, но меньше клиентов (со следующего дня)." % Game.markup)
			Game.touch())
		mk.add_child(sl)
	if Game.workers.is_empty():
		var e2 := _card(left, true)
		if int(st["workers"]) == 0:
			_label(e2, "В комнате работать можно только одному. Переезжай в гараж, чтобы нанимать помощников!", 17, C_DIM)
		else:
			_label(e2, "Пока никого. Найми кандидата справа — работники сами чинят компьютеры каждый день, пока ты занят своими заказами.", 17, C_DIM)
	else:
		var cols: int = clamp(int((_content_width() - 380) / 260.0), 1, 5)
		var rows: int = clamp(int((_content_height() - 260) / 168.0), 1, 4)
		var rng := _grid_pager(Game.workers.size(), cols * rows, "worker_page")
		var grid := _shop_grid(left, cols)
		for i in range(rng[0], rng[1]):
			_worker_card(grid, i)
		_pager_row(left, rng[2], "worker_page")
	# правая колонка: кандидаты и верстаки
	var right := _card(row, true)
	right.get_parent().custom_minimum_size.x = 330
	right.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_END
	_label(right, "Кандидаты", 20, C_TEXT, F_BLACK)
	if Game.candidates.is_empty():
		_label(right, "Сюда никто не придёт работать — места нет. Нужен гараж или больше.", 14, C_DIM)
	for i in Game.candidates.size():
		var c: Dictionary = Game.candidates[i]
		var ch := HBoxContainer.new()
		ch.add_theme_constant_override("separation", 8)
		right.add_child(ch)
		var av = AVATAR.new()
		av.who = c["name"]
		av.custom_minimum_size = Vector2(40, 40)
		ch.add_child(av)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", -2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ch.add_child(cv)
		_label(cv, c["name"], 15, C_TEXT, F_BOLD)
		_label(cv, "%s · $%d/день" % ["★".repeat(int(c["skill"])) + "☆".repeat(5 - int(c["skill"])), c["salary"]], 12, C_WARN)
		var hb := _primary(_button(ch, "Нанять", _do_hire.bind(i), Game.workers.size() >= Game.worker_slots()))
		hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var g := Control.new()
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(g)
	_label(right, "Верстаки", 20, C_TEXT, F_BLACK)
	_label(right, "Один верстак твой, на остальных работают сотрудники. Свободно: %d" % max(0, Game.benches - 1 - Game.workers.size()), 13, C_DIM)
	var can_bench := Game.benches < int(st["benches"])
	_button(right, ("Купить верстак · $%d" % Game.bench_price()) if can_bench else "Нет места — нужен переезд", func(): Game.say(Game.buy_bench()), not can_bench or Game.money < Game.bench_price())
	if not Game.last_report.is_empty():
		_label(right, "Вчера:", 13, C_DIM, F_BOLD)
		_rich(right, "[font_size=12]" + "\n".join(Game.last_report.slice(0, 3)) + "[/font_size]")


func _worker_card(grid: GridContainer, i: int) -> void:
	var w: Dictionary = Game.workers[i]
	var v := _card(grid)
	v.get_parent().custom_minimum_size = Vector2(250, 0)
	v.add_theme_constant_override("separation", 5)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var av = AVATAR.new()
	av.who = w["name"]
	av.custom_minimum_size = Vector2(46, 46)
	h.add_child(av)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	_label(tv, w["name"], 16, C_TEXT, F_BOLD)
	_label(tv, "%s  ур. %d · починил %d" % ["★".repeat(int(w["skill"])) + "☆".repeat(5 - int(w["skill"])), w["level"], w["jobs"]], 12, C_WARN)
	var mood := int(w["mood"])
	var wexp := Game.worker_expect(w)
	var mr := HBoxContainer.new()
	v.add_child(mr)
	_label(mr, "Настроение", 12, C_DIM)
	var bar := ProgressBar.new()
	bar.value = mood
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(110, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("fill", _sb(C_GOOD if mood >= 50 else (C_WARN if mood >= 25 else C_BAD), 5, Color(0, 0, 0, 0), 0, 0, 0))
	mr.add_child(bar)
	_label(v, "Зарплата $%d/день (хочет $%d)" % [w["salary"], wexp], 12, C_GOOD if int(w["salary"]) >= int(wexp * 0.9) else C_BAD)
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 4)
	v.add_child(br)
	var idx := i
	for b in [["+$5", func(): Game.raise_salary(idx, 5)], ["−$5", func(): Game.raise_salary(idx, -5)], ["Премия", _do_bonus.bind(idx)],
			["Уволить", func(): _choose("Уволить %s?" % w["name"], [["Да, уволить", func(): Game.fire(idx)]])]]:
		var bt := _button(br, b[0], b[1])
		bt.add_theme_font_size_override("font_size", 12)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if b[0] == "Уволить":
			_danger(bt)


func _do_move() -> void:
	var r := Game.move_up()
	if r != "":
		Game.say(r)
		return
	var st := Game.stage_info()
	_info("Переезд: " + st["name"], "[font_size=26][b]%s[/b][/font_size]\n\n%s\n\nТеперь можно купить больше верстаков и нанять работников во вкладке «Бизнес»." % [st["name"], st["desc"]])
	busya.say("Мяу!", "новое место! Тут столько коробок…", 5.0)


func _do_hire(i: int) -> void:
	var r := Game.hire(i)
	if r != "":
		Game.say(r)


func _do_bonus(i: int) -> void:
	var r := Game.give_bonus(i)
	if r != "":
		Game.say(r)



# ============================ Техноград ============================
const MAP_VIEW := preload("res://scripts/ui/MapView.gd")
var city_sel := 0
var city_map


func _build_city() -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var mapf := PanelContainer.new()
	mapf.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.4), 16, Color(1, 1, 1, 0.08), 1, 4, 4, 12))
	mapf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mapf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(mapf)
	city_map = MAP_VIEW.new()
	city_map.visits = Game.visits
	city_map.year = Game.year()
	city_map.stage = Game.stage
	city_map.transport = Game.transport
	city_map.accent = C_ACCENT
	city_sel = clamp(city_sel, 0, max(0, Game.visits.size() - 1))
	city_map.selected = city_sel if not Game.visits.is_empty() else -1
	city_map.pin_clicked.connect(func(i):
		city_sel = i
		refresh())
	mapf.add_child(city_map)
	var side := _card(row, true)
	side.get_parent().custom_minimum_size.x = 360
	side.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_END
	side.add_theme_constant_override("separation", 8)
	_label(side, "Техноград", 28, C_TEXT, F_BLACK)
	_label(side, "Вызовы на дом: %d · нажми на метку на карте" % Game.visits.size(), 13, C_DIM)
	if Game.visits.is_empty():
		_label(side, "Сегодня вызовов больше нет. Завтра будут новые!", 16, C_DIM)
	else:
		var o: Dictionary = Game.visits[city_sel]
		var d := Game.district(o["district"])
		var vc := PanelContainer.new()
		vc.add_theme_stylebox_override("panel", _sb(Color(1, 1, 1, 0.05), 12, Color(d["col"], 0.5), 1, 12, 10))
		side.add_child(vc)
		var vv := VBoxContainer.new()
		vv.add_theme_constant_override("separation", 6)
		vc.add_child(vv)
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 10)
		vv.add_child(hh)
		var av = AVATAR.new()
		av.who = o["client"]
		av.custom_minimum_size = Vector2(52, 52)
		hh.add_child(av)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.add_child(tv)
		_label(tv, o["client"], 17, C_TEXT, F_BOLD)
		_label(tv, "%s · %s" % [d["name"], ["рядом", "средне", "далеко"][int(d["dist"])]], 12, d["col"])
		var money := Label.new()
		money.text = "$%d" % o["reward"]
		money.add_theme_font_override("font", F_BLACK)
		money.add_theme_font_size_override("font_size", 26)
		money.add_theme_color_override("font_color", Color("#7bd88f"))
		hh.add_child(money)
		var q := _label(vv, "«%s»" % String(o["text"]).replace("(вызов на дом) ", ""), 14, C_TEXT)
		q.max_lines_visible = 3
		var rq := HBoxContainer.new()
		vv.add_child(rq)
		_icon(rq, "check", C_GOOD, 16)
		_label(rq, o["req"], 13, C_GOOD)
		var reach := Game.can_reach(int(d["dist"]))
		var busy_now := not Game.current_order.is_empty()
		var go_b := _primary(_button(side, "Поехать самому" if reach else "Не доехать на велосипеде", _city_go.bind(city_sel), not reach or busy_now))
		go_b.custom_minimum_size.y = 44
		if busy_now:
			go_b.tooltip_text = "Сначала закончи текущий заказ"
		var free := []
		for wi in Game.workers.size():
			if not Game.workers[wi].get("away", false):
				free.append(wi)
		if not free.is_empty():
			_label(side, "Или отправить работника (получишь 80%):", 12, C_DIM)
			var wr := HFlowContainer.new()
			wr.add_theme_constant_override("h_separation", 6)
			wr.add_theme_constant_override("v_separation", 6)
			side.add_child(wr)
			for wi in free.slice(0, 4):
				var w: Dictionary = Game.workers[wi]
				var wb := _button(wr, "%s %s" % [w["name"], "★".repeat(int(w["skill"]))], _city_send.bind(city_sel, wi), not reach)
				wb.add_theme_font_size_override("font_size", 13)
	var g := Control.new()
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(g)
	# транспорт
	var tr: Dictionary = Data.TRANSPORT[Game.transport]
	_label(side, "ТРАНСПОРТ", 11, C_DIM, F_BOLD)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	side.add_child(th)
	_icon(th, "map", C_ACCENT, 26)
	_label(th, tr["name"], 17, C_TEXT, F_BOLD)
	_label(side, "Доезжает: %s" % ["только рядом", "до средних районов", "по всему городу"][int(tr["reach"])], 12, C_DIM)
	if Game.transport < Data.TRANSPORT.size() - 1:
		var nt: Dictionary = Data.TRANSPORT[Game.transport + 1]
		var avail := Game.year() >= int(nt["year"])
		_button(side, ("Купить: %s · $%d" % [nt["name"], nt["price"]]) if avail else "%s — с %d года" % [nt["name"], nt["year"]], func(): Game.say(Game.buy_transport(Game.transport + 1)), not avail or Game.money < int(nt["price"]))


func _city_go(i: int) -> void:
	if busy:
		return
	busy = true
	city_map.go_to(i)
	await city_map.arrived
	busy = false
	var r := Game.take_visit(i)
	if r != "":
		Game.say(r)
		return
	busya.say("Мяу?", "ты куда без меня? Ладно, я посторожу мастерскую", 4.0)
	go("career")


func _city_send(i: int, wi: int) -> void:
	var r := Game.send_worker(i, wi)
	if r != "":
		Game.say(r)



# ============================ компьютерный клуб ============================
const CLUB_VIEW := preload("res://scripts/ui/ClubView.gd")
var club_idx := 0
var seat_page := 0


func _club_view(states: Array, max_seats: int) -> PanelContainer:
	var f := PanelContainer.new()
	f.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.4), 16, Color(1, 1, 1, 0.08), 1, 4, 4, 12))
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cv = CLUB_VIEW.new()
	cv.states = states
	cv.max_seats = max_seats
	cv.visitors = int(Game.club.get("visitors", 0))
	cv.extras = Game.club.get("extras", [])
	cv.year = Game.year()
	cv.accent = C_ACCENT
	cv.custom_minimum_size = Vector2(400, 260)
	f.add_child(cv)
	return f


func _build_club() -> void:
	var hit := Game.club_hit()
	if not Game.club_open():
		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		content.add_child(row)
		row.add_child(_club_view([], 4))
		var c := _card(row, true)
		c.get_parent().custom_minimum_size.x = 380
		c.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_END
		_label(c, "Компьютерный клуб", 28, C_TEXT, F_BLACK)
		_label(c, "Свой клуб: школьники после уроков, турниры по сети, газировка и чипсы. Клуб приносит деньги каждый день — если компы не тормозят.", 15, C_DIM)
		_pill(c, "Хит эпохи: %s" % Data.games[hit]["name"], C_ACCENT, "gamepad")
		var lv: Dictionary = Data.CLUB_LEVELS[0]
		var need_stage := Game.stage < int(lv["stage"])
		var g := Control.new()
		g.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.add_child(g)
		if need_stage:
			_label(c, "Нужен этап мастерской «%s» (вкладка «Бизнес»)." % Data.STAGES[int(lv["stage"])]["name"], 14, C_WARN)
		var b := _primary(_button(c, "Открыть клуб · $%d" % lv["cost"], func(): Game.say(Game.club_upgrade()), need_stage or Game.money < int(lv["cost"])))
		b.custom_minimum_size.y = 48
		return
	var seats: Array = Game.club["seats"]
	var lvl: Dictionary = Data.CLUB_LEVELS[int(Game.club["level"])]
	var states := []
	for pc in seats:
		states.append(Game.seat_state(pc)["state"])
	var top := HBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)
	top.add_child(_club_view(states, int(lvl["seats"])))
	var side := _card(top, true)
	side.get_parent().custom_minimum_size.x = 380
	side.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_END
	side.add_theme_constant_override("separation", 6)
	_label(side, lvl["name"], 22, C_TEXT, F_BLACK)
	var pf := HFlowContainer.new()
	pf.add_theme_constant_override("h_separation", 6)
	pf.add_theme_constant_override("v_separation", 6)
	side.add_child(pf)
	_pill(pf, "Мест: %d / %d" % [seats.size(), lvl["seats"]], Color("#9ec9ff"), "tower")
	_pill(pf, "Вчера: %d чел." % int(Game.club.get("visitors", 0)), C_GOOD, "person")
	var inc := int(Game.club.get("income", 0))
	_pill(pf, ("+$%d" if inc >= 0 else "−$%d") % absi(inc), C_GOOD if inc >= 0 else C_BAD, "coin")
	_label(side, "Хит эпохи: [%s] — нужно %d FPS для турнира" % [Data.games[hit]["name"], int(Game.club_target_fps())], 13, C_ACCENT)
	var pr := HBoxContainer.new()
	pr.add_theme_constant_override("separation", 8)
	side.add_child(pr)
	var pl := Label.new()
	pl.text = "Цена: $%d/час" % int(Game.club["price"])
	pl.add_theme_color_override("font_color", C_TEXT)
	pr.add_child(pl)
	var sl := HSlider.new()
	sl.min_value = 1
	sl.max_value = max(4, Game.club_default_price() * 3)
	sl.step = 1
	sl.value = int(Game.club["price"])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.tooltip_text = "Обычная цена сейчас: $%d. Дороже — меньше посетителей." % Game.club_default_price()
	sl.drag_ended.connect(func(_c):
		Game.club["price"] = int(sl.value)
		Game.touch())
	pr.add_child(sl)
	var full := seats.size() >= int(lvl["seats"])
	_primary(_button(side, "Купить игровое место · $%d" % Game.club_seat_price(), func(): Game.say(Game.club_buy_seat()), full or Game.money < Game.club_seat_price()))
	var nx := Game.club_next_level()
	if not nx.is_empty():
		var ns := Game.stage < int(nx["stage"])
		var ub := _button(side, ("Расширить: %s · $%d" % [nx["name"], nx["cost"]]) if not ns else "Расширение — с этапа «%s»" % Data.STAGES[int(nx["stage"])]["name"], func(): Game.say(Game.club_upgrade()), ns or Game.money < int(nx["cost"]))
		ub.clip_text = true
	var tb := _button(side, "Провести турнир", _club_tour)
	tb.add_theme_color_override("font_color", C_ACCENT)
	_label(side, "ДОП. ЗОНЫ", 11, C_DIM, F_BOLD)
	var exg := GridContainer.new()
	exg.columns = 2
	exg.add_theme_constant_override("h_separation", 6)
	exg.add_theme_constant_override("v_separation", 6)
	side.add_child(exg)
	for id in Data.CLUB_EXTRAS:
		var ex: Dictionary = Data.CLUB_EXTRAS[id]
		var has: bool = Game.club["extras"].has(id)
		var avail := Game.year() >= int(ex["year"])
		var t: String = ("✓ " + ex["name"]) if has else (("%s · $%d" % [ex["name"], ex["price"]]) if avail else "%s (%d)" % [ex["name"], ex["year"]])
		var eb := _button(exg, t, _club_extra.bind(id), has or not avail or Game.money < int(ex["price"]))
		eb.tooltip_text = ex["desc"]
		eb.add_theme_font_size_override("font_size", 12)
		eb.clip_text = true
		eb.custom_minimum_size.x = 170
	# места
	var sp := PanelContainer.new()
	sp.add_theme_stylebox_override("panel", _sb(Color(Color(ERAS[max(0, era_idx)][4]), 0.92), 16, Color(1, 1, 1, 0.06), 1, 12, 8, 10))
	content.add_child(sp)
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 8)
	sp.add_child(srow)
	var sv := VBoxContainer.new()
	sv.custom_minimum_size.x = 110
	sv.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_child(sv)
	_label(sv, "Места", 17, C_TEXT, F_BOLD)
	_label(sv, "нажми, чтобы обслужить", 11, C_DIM)
	if seats.is_empty():
		_label(srow, "Пока ни одного места — купи первое справа.", 14, C_DIM).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return
	var per: int = max(1, int((_content_width() - 110 - 100) / 168.0))
	var pages: int = max(1, int(ceil(float(seats.size()) / per)))
	seat_page = clamp(seat_page, 0, pages - 1)
	if pages > 1:
		_button(srow, "‹", func():
			seat_page -= 1
			refresh(), seat_page == 0).custom_minimum_size = Vector2(34, 56)
	var cards := HBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 8)
	srow.add_child(cards)
	for i in range(seat_page * per, min(seats.size(), (seat_page + 1) * per)):
		var st := Game.seat_state(seats[i])
		var col := C_GOOD if st["state"] == "ok" else (C_WARN if st["state"] == "slow" else C_BAD)
		var b := Button.new()
		b.custom_minimum_size = Vector2(160, 56)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", _sb(Color(col, 0.1), 10, Color(col, 0.6), 1, 8, 4))
		b.add_theme_stylebox_override("hover", _sb(Color(col, 0.22), 10, col, 1, 8, 4))
		b.text = "№%d\n%s" % [i + 1, st["text"]]
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", col.lightened(0.35))
		b.tooltip_text = st["text"]
		b.pressed.connect(_open_seat.bind(i))
		cards.add_child(b)
	if pages > 1:
		_button(srow, "›", func():
			seat_page += 1
			refresh(), seat_page >= pages - 1).custom_minimum_size = Vector2(34, 56)


func _club_tour() -> void:
	var r := Game.club_tournament()
	if r != "":
		Game.say(r)


func _club_extra(id: String) -> void:
	Game.say(Game.club_buy_extra(id))


func _open_seat(i: int) -> void:
	club_idx = i
	go("clubpc")


func _build_clubpc() -> void:
	if not Game.club_open() or club_idx >= Game.club["seats"].size():
		go("club")
		return
	var pc: Dictionary = Game.club["seats"][club_idx]
	var hc := PanelContainer.new()
	content.add_child(hc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	hc.add_child(h)
	var back = ICON_BTN.new()
	back.setup("prev", "В клуб", C_TEXT, true)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): go("club"))
	h.add_child(back)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	_label(tv, "Клубный ПК №%d" % (club_idx + 1), 19, C_TEXT, F_BOLD)
	_label(tv, "Хит эпохи %s должен идти без лагов. Чисти пыль, лечи вирусы, меняй сломанное и апгрейдь." % Data.games[Game.club_hit()]["name"], 13, C_DIM)
	var st := Game.seat_state(pc)
	_pill(h, st["text"], C_GOOD if st["state"] == "ok" else (C_WARN if st["state"] == "slow" else C_BAD), "gamepad")
	if club_idx + 1 < Game.club["seats"].size():
		var nx = ICON_BTN.new()
		nx.setup("next", "Следующий", C_TEXT, true)
		nx.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nx.pressed.connect(_open_seat.bind(club_idx + 1))
		h.add_child(nx)
	_build_bench(pc, false)
