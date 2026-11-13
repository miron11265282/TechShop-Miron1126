extends "res://scripts/ui/OverlayBase.gd"
## «Сесть за компьютер»: живой рабочий стол своей эпохи с программами —
## диспетчер задач, проводник, командная строка, корзина. Вирусы можно удалить руками.

const MONITOR := preload("res://scripts/ui/Monitor.gd")

var pc: Dictionary = {}
var gen := 4
var linux := false
var dos := false
var os_name := ""
var screen: Control
var mon
var icons_box: Control
var win: PanelContainer = null
var win_title: Label
var body: VBoxContainer
var shell_dead := false
var changed := false
var crash := ""
var P := {}
var mono: SystemFont
# консоль
var con_lines: Array = []
var con_label: Label
var con_input: LineEdit
var con_color := Color("#c0c0c0")
# диспетчер задач
var tm_tree: Tree
var tm_info: Label
# проводник
var ex_place := "docs"
var ex_list: ItemList
var ex_items: Array = []
var ex_msg: Label
var sys_warned := false


func _init() -> void:
	min_size = Vector2(1080, 640)
	bg_color = Color("#16181c")


func build() -> void:
	var o: Dictionary = Data.os_list.get(pc.get("os", ""), {})
	gen = int(o.get("gen", 1))
	linux = o.get("linux", false)
	dos = pc.get("os", "") == "dos"
	os_name = o.get("name", "?")
	P = _palette()
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Lucida Console", "Courier New", "DejaVu Sans Mono", "monospace"])
	var top := row()
	label("За компьютером: %s · пользователь %s" % [os_name, Game.pc_user(pc)], 17, accent, top)
	btn(top, "× Встать из-за компьютера", func(): _leave())
	screen = Control.new()
	screen.custom_minimum_size = Vector2(min_size.x - 32, min_size.y - 84)
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.clip_contents = true
	box.add_child(screen)
	mon = MONITOR.new()
	mon.pc = pc
	mon.year = Game.year()
	mon.bare = true
	mon.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(mon)
	if dos:
		_open_console()
		return
	_build_icons()


func _leave() -> void:
	finish({"changed": changed, "crash": crash})


# ---------------- внешний вид по эпохам ----------------

func _palette() -> Dictionary:
	if linux:
		if pc["os"] == "ubuntu":
			return {"title": Color("#2c2c2c"), "tfg": Color.WHITE, "body": Color("#fafafa"), "fg": Color("#222"), "r": 8, "sel": Color("#e95420")}
		return {"title": Color("#3c4b3a"), "tfg": Color.WHITE, "body": Color("#f4f4f2"), "fg": Color("#222"), "r": 6, "sel": Color("#8fbf5b")}
	if gen <= 3:
		return {"title": Color("#000080"), "tfg": Color.WHITE, "body": Color("#c0c0c0"), "fg": Color.BLACK, "r": 0, "sel": Color("#000080")}
	if gen == 4:
		return {"title": Color("#0a53d6"), "tfg": Color.WHITE, "body": Color("#ece9d8"), "fg": Color.BLACK, "r": 7, "sel": Color("#316ac5")}
	if gen <= 6:
		return {"title": Color("#5c8bb8"), "tfg": Color.WHITE, "body": Color("#f0f0f0"), "fg": Color.BLACK, "r": 7, "sel": Color("#3399ff")}
	if gen == 7:
		return {"title": Color("#2d89ef"), "tfg": Color.WHITE, "body": Color("#ffffff"), "fg": Color.BLACK, "r": 0, "sel": Color("#2d89ef")}
	return {"title": Color("#f3f3f3"), "tfg": Color.BLACK, "body": Color("#fbfbfb"), "fg": Color("#1b1b1b"), "r": 8 if gen >= 9 else 0, "sel": Color("#0067c0")}


func _sb(col: Color, r: int = 0, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(6)
	if border.a > 0:
		sb.border_color = border
		sb.set_border_width_all(1)
	return sb


func _style_btn(b: Button) -> void:
	var base: Color = P["body"].darkened(0.06)
	b.add_theme_stylebox_override("normal", _sb(base, min(4, P["r"]), P["body"].darkened(0.35)))
	b.add_theme_stylebox_override("hover", _sb(base.lightened(0.08), min(4, P["r"]), P["sel"]))
	b.add_theme_stylebox_override("pressed", _sb(base.darkened(0.1), min(4, P["r"]), P["sel"]))
	b.add_theme_color_override("font_color", P["fg"])
	b.add_theme_color_override("font_hover_color", P["fg"])
	b.add_theme_color_override("font_pressed_color", P["fg"])
	b.add_theme_font_size_override("font_size", 13)


# ---------------- ярлыки ----------------

func _build_icons() -> void:
	if icons_box:
		icons_box.queue_free()
	icons_box = VBoxContainer.new()
	icons_box.position = Vector2(14 + (40 if linux else 0), 12)
	icons_box.add_theme_constant_override("separation", 6)
	screen.add_child(icons_box)
	if shell_dead:
		var hint := Button.new()
		hint.text = "Рабочий стол пропал! Нажми Ctrl+Shift+Esc"
		hint.pressed.connect(_open_tasks)
		icons_box.add_child(hint)
		mon.no_shell = true
		return
	mon.no_shell = false
	var list := []
	if linux:
		list = [["files", "Файлы"], ["web", "Браузер"], ["mail", "Почта"], ["term", "Терминал"], ["tasks", "Системный монитор"], ["bin", "Корзина"]]
	else:
		list = [["files", "Мой компьютер" if gen < 8 else "Этот компьютер"], ["web", "Интернет"], ["mail", "Почта"], ["tasks", "Закрыть программу" if gen <= 3 else "Диспетчер задач"],
			["term", "MS-DOS" if gen <= 3 else "Командная строка"], ["bin", "Корзина"]]
	for it in list:
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(110, 74)
		b.text = "\n\n\n" + it[1]
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color("#fff59d"))
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		b.add_theme_constant_override("outline_size", 3)
		var ic := Control.new()
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.position = Vector2(37, 4)
		ic.size = Vector2(36, 36)
		var kind: String = it[0]
		ic.draw.connect(func(): _draw_icon(ic, kind))
		b.add_child(ic)
		b.pressed.connect(func(): _open(kind))
		icons_box.add_child(b)


func _draw_icon(ci: Control, kind: String) -> void:
	match kind:
		"files":
			if gen < 8 and not linux:
				ci.draw_rect(Rect2(4, 2, 28, 22), Color("#d9d1b8"))
				ci.draw_rect(Rect2(7, 5, 22, 15), Color("#2a6fd6"))
				ci.draw_rect(Rect2(12, 26, 12, 4), Color("#cfc8b0"))
				ci.draw_rect(Rect2(6, 30, 24, 4), Color("#cfc8b0"))
			else:
				ci.draw_rect(Rect2(2, 8, 32, 24), Color("#f6c443"))
				ci.draw_rect(Rect2(2, 4, 14, 6), Color("#e0a92a"))
		"tasks":
			ci.draw_rect(Rect2(2, 2, 32, 32), Color("#1e2a1e") if gen < 8 else Color("#2b2b2b"))
			var hs := [10, 18, 8, 24, 14]
			for i in 5:
				ci.draw_rect(Rect2(5 + i * 6, 32 - hs[i], 4, hs[i]), Color("#4cd964"))
		"term":
			ci.draw_rect(Rect2(2, 4, 32, 28), Color.BLACK if not linux else Color("#300a24"))
			ci.draw_rect(Rect2(2, 4, 32, 5), Color("#9a9a9a"))
			ci.draw_string(get_theme_default_font(), Vector2(5, 26), ">_" if not linux else "$_", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c0c0c0"))
		"web":
			ci.draw_circle(Vector2(18, 18), 15, Color("#2f86e0"))
			ci.draw_arc(Vector2(18, 18), 15, 0, TAU, 28, Color("#bfe0ff"), 1.5, true)
			ci.draw_line(Vector2(3, 18), Vector2(33, 18), Color("#bfe0ff"), 1.2)
			ci.draw_arc(Vector2(18, 18), 7, -PI / 2, PI / 2, 14, Color("#bfe0ff"), 1.2, true)
			ci.draw_arc(Vector2(18, 18), 7, PI / 2, PI * 1.5, 14, Color("#bfe0ff"), 1.2, true)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 10), Vector2(16, 8), Vector2(14, 16), Vector2(9, 15)]), Color("#59c26a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(20, 20), Vector2(28, 18), Vector2(27, 27), Vector2(21, 28)]), Color("#59c26a"))
		"mail":
			ci.draw_rect(Rect2(3, 8, 30, 20), Color("#f5f5f5"))
			ci.draw_polyline(PackedVector2Array([Vector2(3, 8), Vector2(18, 20), Vector2(33, 8)]), Color("#9aa0a8"), 1.5)
			if _unread() > 0:
				ci.draw_circle(Vector2(31, 8), 6, Color("#ef5350"))
		"bin":
			ci.draw_rect(Rect2(8, 8, 20, 26), Color("#9fb3c8"))
			ci.draw_rect(Rect2(5, 5, 26, 4), Color("#7f93a8"))
			for i in 3:
				ci.draw_line(Vector2(13 + i * 5, 12), Vector2(13 + i * 5, 30), Color("#6a7f94"), 1.5)


func _open(kind: String) -> void:
	match kind:
		"files":
			_open_explorer("docs")
		"bin":
			_open_explorer("bin")
		"tasks":
			_open_tasks()
		"term":
			_open_console()
		"web":
			_open_browser("home")
		"mail":
			_open_mail()


# ---------------- окна ----------------

func _window(t: String, w: float, h: float, console: bool = false) -> VBoxContainer:
	if win:
		win.queue_free()
	win = PanelContainer.new()
	var sb := _sb(P["body"] if not console else Color.BLACK, P["r"], P["title"].darkened(0.2))
	sb.set_content_margin_all(0)
	win.add_theme_stylebox_override("panel", sb)
	var sz := Vector2(min(w, screen.custom_minimum_size.x - 160), min(h, screen.custom_minimum_size.y - 30))
	win.custom_minimum_size = sz
	win.position = Vector2(screen.custom_minimum_size.x - sz.x - 16, (screen.custom_minimum_size.y - sz.y) / 2.0)
	if dos:
		win.position = Vector2.ZERO
		win.custom_minimum_size = screen.custom_minimum_size
	screen.add_child(win)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	win.add_child(v)
	if not dos:
		var tp := PanelContainer.new()
		var tsb := _sb(P["title"], P["r"])
		tsb.corner_radius_bottom_left = 0
		tsb.corner_radius_bottom_right = 0
		tsb.content_margin_top = 4
		tsb.content_margin_bottom = 4
		tp.add_theme_stylebox_override("panel", tsb)
		v.add_child(tp)
		var th := HBoxContainer.new()
		tp.add_child(th)
		win_title = Label.new()
		win_title.text = t
		win_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		win_title.add_theme_color_override("font_color", P["tfg"])
		win_title.add_theme_font_size_override("font_size", 14)
		th.add_child(win_title)
		var x := Button.new()
		x.text = " × "
		x.add_theme_stylebox_override("normal", _sb(Color("#c42b1c") if gen >= 4 or linux else Color("#c0c0c0"), min(4, P["r"])))
		x.add_theme_color_override("font_color", Color.WHITE if gen >= 4 or linux else Color.BLACK)
		x.pressed.connect(func(): _close_win())
		th.add_child(x)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 8)
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(m)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	m.add_child(body)
	return body


func _close_win() -> void:
	if win:
		win.queue_free()
		win = null
	tm_tree = null
	con_label = null
	ex_list = null


func _lbl(parent: Control, t: String, fs: int = 13, col: Color = Color(-1, 0, 0)) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", P["fg"] if col.r < 0 else col)
	parent.add_child(l)
	return l


func _wbtn(parent: Control, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	_style_btn(b)
	parent.add_child(b)
	return b


func _system_crash(msg: String) -> void:
	crash = msg
	changed = true
	_close_win()
	var c := ColorRect.new()
	c.color = Color("#0000aa") if gen < 8 else Color("#0a64c8")
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(c)
	var l := Label.new()
	l.text = (":(\n\n" if gen >= 8 else "") + msg + "\n\nКомпьютер выключился. Нажми «Встать из-за компьютера»."
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.position = Vector2(40, 60)
	l.size = Vector2(screen.custom_minimum_size.x - 80, 300)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.add_child(l)


# ---------------- диспетчер задач ----------------

func _open_tasks() -> void:
	var t := "Системный монитор" if linux else ("Закрытие программы" if gen <= 3 else "Диспетчер задач Windows")
	var v := _window(t, 660, 500)
	if gen <= 3 and not linux:
		_lbl(v, "Выберите программу и нажмите «Снять задачу». Программа, которая не отвечает, будет закрыта.", 12)
	tm_tree = Tree.new()
	tm_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tm_tree.hide_root = true
	tm_tree.select_mode = Tree.SELECT_ROW
	var cols := 1 if (gen <= 3 and not linux) else 4
	tm_tree.columns = cols
	tm_tree.column_titles_visible = cols > 1
	if cols > 1:
		var titles := ["Имя образа", "Пользователь", "ЦП", "Память"]
		for i in 4:
			tm_tree.set_column_title(i, titles[i])
		tm_tree.set_column_expand(0, true)
		for i in [1, 2, 3]:
			tm_tree.set_column_expand(i, false)
		tm_tree.set_column_custom_minimum_width(1, 140)
		tm_tree.set_column_custom_minimum_width(2, 60)
		tm_tree.set_column_custom_minimum_width(3, 100)
	tm_tree.add_theme_stylebox_override("panel", _sb(Color.WHITE if gen > 3 or linux else Color("#ffffff"), 0, P["body"].darkened(0.3)))
	tm_tree.add_theme_color_override("font_color", Color("#111"))
	tm_tree.add_theme_color_override("font_selected_color", Color.WHITE)
	tm_tree.add_theme_stylebox_override("selected", _sb(P["sel"]))
	tm_tree.add_theme_stylebox_override("selected_focus", _sb(P["sel"]))
	tm_tree.add_theme_font_size_override("font_size", 12)
	tm_tree.add_theme_constant_override("v_separation", 3)
	v.add_child(tm_tree)
	tm_info = _lbl(v, "", 12)
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(r)
	if shell_dead:
		_wbtn(r, "Новая задача: explorer.exe", func():
			shell_dead = false
			_build_icons()
			_tm_fill())
	_wbtn(r, "kill" if linux else ("Снять задачу" if gen <= 3 else "Завершить процесс"), func(): _tm_kill())
	_tm_fill()


func _tm_fill() -> void:
	if tm_tree == null:
		return
	tm_tree.clear()
	var root := tm_tree.create_item()
	var procs: Array = Game.processes(pc)
	var total := 0
	for i in procs.size():
		var p: Dictionary = procs[i]
		if shell_dead and p["name"].to_lower() == "explorer.exe":
			continue
		var it := tm_tree.create_item(root)
		it.set_text(0, p["name"])
		it.set_metadata(0, i)
		if tm_tree.columns > 1:
			it.set_text(1, p["user"])
			it.set_text(2, "%02d" % int(p["cpu"]))
			it.set_text(3, "%d КБ" % (int(p["mem"]) * 1024) if gen <= 5 else "%d МБ" % int(p["mem"]))
		total += int(p["cpu"])
	if tm_info:
		tm_info.text = "Процессов: %d · Загрузка ЦП: %d%%" % [procs.size(), min(100, total)] + ("   ← что-то грузит процессор!" if total > 60 else "")


func _tm_kill() -> void:
	var it := tm_tree.get_selected()
	if it == null:
		tm_info.text = "Сначала выбери процесс в списке."
		return
	var procs: Array = Game.processes(pc)
	var idx: int = it.get_metadata(0)
	if idx >= procs.size():
		return
	var p: Dictionary = procs[idx]
	var res := Game.kill_process(pc, p)
	changed = true
	match res:
		"crash":
			_system_crash("Ты завершил системный процесс %s. Windows без него жить не может!" % p["name"] if not linux else "Ты убил %s — система упала." % p["name"])
			return
		"explorer":
			shell_dead = true
			_build_icons()
			_open_tasks()
			tm_info.text = "Пропали панель задач и ярлыки! Запусти explorer.exe заново кнопкой «Новая задача»."
			return
		"denied":
			tm_info.text = "Отказано в доступе. Это настоящий системный svchost.exe (пользователь СИСТЕМА)."
			return
	_tm_fill()
	if p["kind"] == "virus":
		tm_info.text = "Процесс %s завершён. Но он вернётся после перезагрузки — удали его файл из автозагрузки (Проводник)!" % p["name"]
	else:
		tm_info.text = "Процесс %s завершён." % p["name"]


# ---------------- проводник ----------------

func _places() -> Array:
	if linux:
		return [["docs", "Домашняя папка"], ["prog", "Программы"], ["temp", "/tmp"], ["startup", "Автозапуск"], ["bin", "Корзина"]]
	var L := [["docs", "Мои документы" if gen < 7 else "Документы"], ["prog", "Program Files"], ["temp", "Temp"], ["startup", "Автозагрузка"],
		["sys", "Windows\\System32"]]
	if gen <= 6:
		L.append(["tmpl", "Шаблоны Office"])
	L.append(["bin", "Корзина"])
	return L


func _open_explorer(place: String) -> void:
	ex_place = place
	var v := _window("Проводник" if not linux else "Файлы", 720, 470)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 170
	h.add_child(side)
	for pl in _places():
		var key: String = pl[0]
		var b := _wbtn(side, pl[1], func(): _ex_go(key))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if key == ex_place:
			b.add_theme_stylebox_override("normal", _sb(P["sel"], min(4, P["r"])))
			b.add_theme_color_override("font_color", Color.WHITE)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	_lbl(right, _place_path(), 12, P["fg"].lerp(Color("#777"), 0.5))
	ex_list = ItemList.new()
	ex_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ex_list.add_theme_stylebox_override("panel", _sb(Color.WHITE, 0, P["body"].darkened(0.3)))
	ex_list.add_theme_color_override("font_color", Color("#111"))
	ex_list.add_theme_stylebox_override("selected", _sb(P["sel"]))
	ex_list.add_theme_stylebox_override("selected_focus", _sb(P["sel"]))
	ex_list.add_theme_font_size_override("font_size", 13)
	right.add_child(ex_list)
	ex_msg = _lbl(right, "", 12)
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(r)
	match ex_place:
		"temp":
			_wbtn(r, "Удалить всё из Temp", func(): _ex_clear(0.5, "Temp очищен"))
		"bin":
			_wbtn(r, "Очистить корзину", func(): _ex_clear(0.7, "Корзина очищена"))
	_wbtn(r, "Удалить", func(): _ex_delete())
	_ex_fill()


func _ex_go(place: String) -> void:
	sys_warned = false
	_open_explorer(place)


func _place_path() -> String:
	var u := Game.pc_user(pc)
	if linux:
		return {"docs": "/home/" + u.to_lower(), "prog": "/usr/share/applications", "temp": "/tmp", "startup": "~/.config/autostart", "bin": "Корзина"}.get(ex_place, "/")
	var docs := "C:\\Мои документы" if gen <= 3 else ("C:\\Documents and Settings\\%s\\Мои документы" % u if gen == 4 else "C:\\Users\\%s\\Documents" % u)
	return {"docs": docs, "prog": "C:\\Program Files", "temp": "C:\\Windows\\Temp", "sys": "C:\\Windows\\System32",
		"startup": "Пуск → Программы → Автозагрузка", "tmpl": "…\\Application Data\\Microsoft\\Шаблоны", "bin": "Корзина"}.get(ex_place, "C:\\")


func _ex_fill() -> void:
	ex_items = []
	match ex_place:
		"docs":
			for f in Game.user_files(pc):
				ex_items.append({"name": f, "kind": "user"})
			if ex_items.is_empty():
				ex_msg.text = "Папка пуста." + (" Файлы клиента пропали…" if pc.get("files", false) == false else "")
		"prog":
			for g in pc["games"]:
				ex_items.append({"name": Data.games[g]["name"], "kind": "game"})
			if not linux:
				ex_items.append({"name": "Internet Explorer", "kind": "sysapp"})
				ex_items.append({"name": "Windows Media Player", "kind": "sysapp"})
			else:
				ex_items.append({"name": "Firefox", "kind": "sysapp"})
		"temp":
			var j := float(pc["junk"])
			var n: int = clamp(int(j / max(0.0001, Game.junk_limit(pc)) * 6.0), 0, 14)
			for i in n:
				ex_items.append({"name": "~tmp%04d.tmp" % (i * 37 + 11), "kind": "junk"})
			if j > Game.junk_limit(pc) * 3.0:
				ex_items.append({"name": "… и ещё %d файлов" % int(j * 900), "kind": "junk"})
			ex_msg.text = "Мусор на диске: %s (норма — меньше %s)" % [Data.gb_text(j), Data.gb_text(Game.junk_limit(pc))]
		"startup":
			for it in Game.startup_items(pc):
				ex_items.append(it)
		"sys":
			var files := ["hal.dll", "ntoskrnl.exe", "kernel32.dll", "user32.dll", "drivers", "config"]
			if gen >= 5:
				files.insert(2, "winload.exe")
			for f in files:
				ex_items.append({"name": f, "kind": "sys"})
		"tmpl":
			ex_items.append({"name": "Normal.dot" + ("   (изменён сегодня в 03:14!)" if pc["viruses"].has("macro") else ""), "kind": "tmpl"})
		"bin":
			var j := float(pc["junk"])
			if j > Game.junk_limit(pc) * 0.5:
				for f in ["старый_реферат.doc", "setup_old.exe", "фото_размыто.jpg", "кэш_браузера.zip"]:
					ex_items.append({"name": f, "kind": "junk"})
			else:
				ex_msg.text = "Корзина пуста."
	ex_list.clear()
	for it in ex_items:
		var prefix := "› [папка] " if it["kind"] in ["game", "sysapp"] or String(it["name"]) in ["drivers", "config", "Музыка_в_машину", "Сохранения игр"] else "   "
		ex_list.add_item(prefix + it["name"])


func _ex_clear(keep: float, msg: String) -> void:
	var before := float(pc["junk"])
	if before <= 0.0001:
		ex_msg.text = "Тут уже пусто."
		return
	pc["junk"] = before * keep
	changed = true
	_ex_fill()
	ex_msg.text = "%s: удалено %s. Программа очистки диска удалит ещё больше." % [msg, Data.gb_text(before - float(pc["junk"]))]


func _ex_delete() -> void:
	var sel := ex_list.get_selected_items()
	if sel.is_empty():
		ex_msg.text = "Выбери файл."
		return
	var it: Dictionary = ex_items[sel[0]]
	match it["kind"]:
		"user":
			ex_msg.text = "Это файлы клиента! Не трогай — он за ними и пришёл."
		"game":
			ex_msg.text = "Игры удаляй правильно — кнопкой «Удал. игру» (через «Установку и удаление программ»)."
		"sysapp":
			ex_msg.text = "Это часть системы, её так просто не удалить."
		"junk":
			_ex_clear(0.5 if ex_place == "temp" else 0.7, "Удалено")
		"startup", "app", "virus":
			var m := Game.delete_startup(pc, it)
			changed = true
			_ex_fill()
			ex_msg.text = m
		"tmpl":
			ex_msg.text = Game.delete_template(pc)
			changed = true
			_ex_fill()
		"sys":
			if not sys_warned:
				sys_warned = true
				ex_msg.text = "ВНИМАНИЕ: это системный файл %s! Без него Windows не загрузится. Нажми «Удалить» ещё раз, если ты точно уверен…" % it["name"]
				return
			pc["os_broken"] = true
			pc["on"] = false
			pc["playing"] = ""
			_system_crash("Удалён системный файл %s. Синий экран! Теперь поможет только переустановка Windows." % it["name"])


# ---------------- командная строка ----------------

func _prompt() -> String:
	if linux:
		return "%s@pc:~$ " % Game.pc_user(pc).to_lower()
	return "C:\\>" if gen <= 3 else "C:\\Users\\%s>" % Game.pc_user(pc) if gen >= 5 else "C:\\Documents and Settings\\%s>" % Game.pc_user(pc)


func _open_console() -> void:
	var t := "Терминал" if linux else ("MS-DOS" if gen <= 3 else "Командная строка")
	var v := _window(t, 700, 440, true)
	con_label = Label.new()
	con_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	con_label.add_theme_font_override("font", mono)
	con_label.add_theme_font_size_override("font_size", 14)
	con_label.add_theme_color_override("font_color", con_color)
	con_label.clip_text = true
	con_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	v.add_child(con_label)
	var h := HBoxContainer.new()
	v.add_child(h)
	var pl := Label.new()
	pl.text = _prompt()
	pl.add_theme_font_override("font", mono)
	pl.add_theme_font_size_override("font_size", 14)
	pl.add_theme_color_override("font_color", con_color)
	h.add_child(pl)
	con_input = LineEdit.new()
	con_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	con_input.add_theme_font_override("font", mono)
	con_input.add_theme_font_size_override("font_size", 14)
	con_input.add_theme_color_override("font_color", Color.WHITE)
	con_input.add_theme_stylebox_override("normal", _sb(Color("#111")))
	con_input.add_theme_stylebox_override("focus", _sb(Color("#1a1a1a")))
	con_input.placeholder_text = "введи команду, например help"
	con_input.text_submitted.connect(_on_cmd)
	h.add_child(con_input)
	if con_lines.is_empty():
		if linux:
			_out(["Добро пожаловать в %s!" % os_name, "Набери help, чтобы увидеть команды."])
		elif dos:
			_out(["Starting MS-DOS...", "", "HIMEM is testing extended memory...done.", "", "Набери help — список команд."])
		else:
			_out(["Microsoft Windows [%s]" % os_name, "(c) Корпорация Майкрософт. Все права защищены.", "", "Набери help — список команд."])
	else:
		_out([])
	con_input.call_deferred("grab_focus")


func _out(lines: Array) -> void:
	con_lines += lines
	while con_lines.size() > 80:
		con_lines.pop_front()
	_render_console.call_deferred()


func _render_console() -> void:
	if con_label == null or not is_instance_valid(con_label):
		return
	var lh: float = con_label.get_line_height() + float(con_label.get_theme_constant("line_spacing"))
	var hgt: float = con_label.size.y if con_label.size.y > 40 else 340.0
	var max_lines: int = max(3, int(hgt / max(8.0, lh)))
	con_label.text = "\n".join(con_lines.slice(max(0, con_lines.size() - max_lines)))
	con_label.add_theme_color_override("font_color", con_color)


func _on_cmd(text: String) -> void:
	con_input.text = ""
	var raw := text.strip_edges()
	_out([_prompt() + raw])
	if raw == "":
		return
	var parts := raw.split(" ", false)
	var cmd := parts[0].to_lower()
	var arg := raw.substr(parts[0].length()).strip_edges().to_lower()
	if linux:
		_linux_cmd(cmd, arg)
	else:
		_win_cmd(cmd, arg)
	_out([""])


func _win_cmd(cmd: String, arg: String) -> void:
	match cmd:
		"help", "?", "помощь":
			var L := ["dir        — файлы", "cls        — очистить экран", "ver        — версия системы", "mem        — память",
				"chkdsk     — проверить диск", "systeminfo — сведения о ПК", "tasklist   — процессы", "taskkill /im ИМЯ /f — завершить процесс",
				"ping АДРЕС — проверить сеть", "ipconfig   — сетевые настройки", "color 0a   — зелёный текст", "exit       — закрыть"]
			if gen <= 3:
				L.append("fdisk /mbr — перезаписать загрузочную запись")
			elif gen == 4:
				L.append("fixmbr     — перезаписать загрузочную запись")
			else:
				L.append("bootrec /fixmbr — перезаписать загрузочную запись")
			if gen >= 4:
				L += ["sfc /scannow — проверить системные файлы", "diskpart   — список дисков"]
			if gen >= 6:
				L.append("slmgr /xpr — состояние активации")
			L.append("…и пара секретных команд =^.^=")
			_out(L)
		"cls":
			con_lines = []
			_out([])
		"exit":
			if dos:
				_out(["В DOS выходить некуда :)"])
			else:
				_close_win()
		"ver":
			_out([os_name])
		"dir", "ls":
			var L := [" Содержимое папки " + _prompt().trim_suffix(">"), ""]
			L.append("  <DIR>   Windows" if not dos else "  <DIR>   DOS")
			for g in pc["games"]:
				L.append("  <DIR>   " + String(Data.games[g]["name"]).to_upper().replace(" ", "_").left(12))
			for f in Game.user_files(pc):
				L.append("          " + f)
			L.append("  Свободно: " + Data.gb_text(max(0.0, Game.free_gb(pc))))
			_out(L)
		"mem":
			_out(["Всего памяти: " + Data.gb_text(float(Game.pdata(pc, "ram").get("gb", 0))), "Свободно обычной памяти: 612 КБ" if gen <= 3 else "Используйте диспетчер задач :)"])
		"chkdsk":
			_out(Game.chkdsk_text(pc))
		"systeminfo", "msinfo32":
			_out(Game.systeminfo(pc))
		"tasklist":
			var L := ["Имя образа            Пользователь     ЦП"]
			for p in Game.processes(pc):
				L.append("%-21s %-16s %d" % [p["name"], p["user"], int(p["cpu"])])
			_out(L)
		"taskkill", "kill":
			var nm := arg.replace("/f", "").replace("/im", "").strip_edges()
			if nm == "":
				_out(["Использование: taskkill /im имя.exe /f"])
				return
			var found := false
			for p in Game.processes(pc):
				if String(p["name"]).to_lower() == nm:
					found = true
					var r := Game.kill_process(pc, p)
					changed = true
					if r == "crash":
						_system_crash("taskkill %s — это был критический процесс. Система упала!" % p["name"])
						return
					if r == "explorer":
						shell_dead = true
						_build_icons()
						_out(["УСПЕШНО: процесс explorer.exe завершён. Ой, пропал рабочий стол."])
						return
					if r == "denied":
						_out(["ОШИБКА: отказано в доступе (системный svchost.exe)."])
						continue
					_out(["УСПЕШНО: процесс \"%s\" завершён." % p["name"]])
					return
			if not found:
				_out(["ОШИБКА: процесс \"%s\" не найден." % nm])
		"ping":
			if arg == "":
				_out(["Использование: ping адрес"])
			else:
				var ip := "%d.%d.%d.%d" % [93, 184, 216, (arg.hash() % 200 + 200) % 200 + 10]
				var L := ["Обмен пакетами с %s [%s]:" % [arg, ip]]
				var vs := Game.active_viruses(pc)
				for i in 4:
					L.append("Ответ от %s: байт=32 время=%dмс TTL=56" % [ip, (180 if vs.has("worm") or vs.has("miner") else 24) + i * 3])
				if vs.has("worm"):
					L.append("(сеть сильно загружена — кто-то рассылает пакеты…)")
				_out(L)
		"ipconfig":
			_out(["Настройка протокола IP", "", "  IPv4-адрес . . . . : 192.168.1.%d" % (hash(Game.pc_user(pc)) % 200 + 20), "  Маска подсети . . .: 255.255.255.0", "  Основной шлюз . . .: 192.168.1.1"])
		"fdisk", "fixmbr", "bootrec":
			var ok := (cmd == "fdisk" and arg.contains("/mbr") and gen <= 3) or (cmd == "fixmbr" and gen == 4) or (cmd == "bootrec" and arg.contains("/fixmbr") and gen >= 5)
			if not ok:
				_out(["Команда не подходит для этой системы. Подсказка в help."])
			else:
				_out([Game.fix_mbr(pc)])
				changed = true
		"sfc":
			if gen <= 3:
				_out(["Неизвестная команда."])
			else:
				_out(["Начато сканирование системы…", "Проверка 100% завершена.", "Защита ресурсов Windows не обнаружила нарушений целостности."])
		"diskpart":
			var st := Game.pdata(pc, "storage")
			_out(["DISKPART> list disk", "  Диск ###  Состояние  Размер   Свободно", "  Диск 0    В сети     %-8s %s" % [Data.gb_text(float(st.get("gb", 0))), Data.gb_text(max(0.0, Game.free_gb(pc)))],
				"(не вздумай набирать clean — сотрёшь всё!)"])
		"slmgr":
			_out(["Windows активирована навсегда." if pc.get("activated", true) else "Windows не активирована! Нужен ключ."])
		"color":
			con_color = Color("#33ff66") if arg.begins_with("0a") or arg == "a" else (Color("#ffeb3b") if arg.begins_with("0e") else Color("#c0c0c0"))
			_out([])
		"shutdown":
			pc["on"] = false
			pc["playing"] = ""
			changed = true
			_leave()
		"miron1126":
			_out(["  ███ miron1126 TechShop ███", "  Привет, мастер! Ты нашёл секрет.", "  Буся передаёт: мур."])
		"busya", "буся":
			_out(["   /\\_/\\", "  ( o.o )   мяу!", "   > ^ <    (перевод: «где вкусняшка?»)"])
		"format":
			_out(["Ты серьёзно? Файлы клиента пропадут. Для переустановки используй «Установить ОС»."])
		_:
			_out(["\"%s\" не является внутренней или внешней командой." % cmd])


func _linux_cmd(cmd: String, arg: String) -> void:
	match cmd:
		"help":
			_out(["ls, clear, neofetch, top, ps, kill ИМЯ, df -h, sudo apt update, ping АДРЕС, ip a, exit", "…и секреты =^.^="])
		"ls":
			var L := []
			for f in Game.user_files(pc):
				L.append(f)
			_out(L if not L.is_empty() else ["(пусто)"])
		"clear", "cls":
			con_lines = []
			_out([])
		"exit":
			_close_win()
		"neofetch":
			var si := Game.systeminfo(pc)
			_out(["   .-.      " + Game.pc_user(pc).to_lower() + "@pc", "  (o o)     " + si[0], "  | O \\     " + si[1], "   \\   \\    " + si[2], "    `~~~'   " + si[3]])
		"top", "ps":
			var L := ["  PID USER      %CPU COMMAND"]
			var pid := 1
			for p in Game.processes(pc):
				L.append("%5d %-9s %4d %s" % [pid, p["user"], int(p["cpu"]), p["name"]])
				pid += 37
			_out(L)
		"kill", "killall":
			for p in Game.processes(pc):
				if String(p["name"]).to_lower() == arg:
					var r := Game.kill_process(pc, p)
					changed = true
					if r == "crash":
						_system_crash("Ты убил %s — система упала!" % p["name"])
						return
					_out(["Процесс %s завершён." % p["name"]])
					return
			_out(["kill: процесс не найден"])
		"df":
			_out(["Файл.система  Размер  Своб", "/dev/sda1     %s   %s" % [Data.gb_text(float(Game.pdata(pc, "storage").get("gb", 0))), Data.gb_text(max(0.0, Game.free_gb(pc)))]])
		"sudo":
			if arg.begins_with("rm -rf"):
				_out(["Хорошая попытка. Буся спрятала эту команду под диван =^.^="])
			elif arg.contains("apt"):
				_out(["[sudo] пароль для %s: ********" % Game.pc_user(pc).to_lower(), "Чтение списков пакетов… Готово", "Все пакеты имеют последние версии."])
			else:
				_out(["sudo: команда выполнена"])
		"ping":
			_out(["64 bytes from %s: icmp_seq=1 ttl=56 time=23 ms" % (arg if arg != "" else "localhost")])
		"ip":
			_out(["2: eth0: inet 192.168.1.%d/24" % (hash(Game.pc_user(pc)) % 200 + 20)])
		"miron1126":
			_out(["miron1126 TechShop — привет из терминала!"])
		"busya", "буся":
			_out(["   /\\_/\\", "  ( o.o )   мяу! (перевод: «Linux — это хорошо, а вкусняшка лучше»)", "   > ^ <"])
		_:
			_out(["%s: команда не найдена" % cmd])


# ---------------- интернет ----------------
var web_page := "home"
var web_hist: Array = []
var web_rt: RichTextLabel
var web_addr: Label
var web_busy := false
var mail_read := {}
var mail_list: ItemList
var mail_body: RichTextLabel
var mail_items: Array = []


func _net_speed() -> String:
	var y := Game.year()
	if y < 1998:
		return "модем 28.8 кбит/с"
	if y < 2002:
		return "модем 56 кбит/с"
	if y < 2008:
		return "ADSL 1 Мбит/с"
	if y < 2015:
		return "кабель 30 Мбит/с"
	return "оптика 500 Мбит/с"


func _browser_name() -> String:
	var y := Game.year()
	if linux:
		return "Firefox"
	if y < 2001:
		return "Navigator 3000"
	if y < 2009:
		return "Интернет-Обозреватель"
	return "Браузер"


func _open_browser(page: String) -> void:
	web_page = page
	var v := _window(_browser_name(), 760, 500)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	v.add_child(bar)
	_wbtn(bar, "←", func():
		if not web_hist.is_empty():
			web_page = web_hist.pop_back()
			_web_render()).custom_minimum_size.x = 36
	_wbtn(bar, "Домой", func(): _go("home"))
	var ap := PanelContainer.new()
	ap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ap.add_theme_stylebox_override("panel", _sb(Color.WHITE, min(4, P["r"]), P["body"].darkened(0.3)))
	bar.add_child(ap)
	web_addr = Label.new()
	web_addr.add_theme_color_override("font_color", Color("#333"))
	web_addr.add_theme_font_size_override("font_size", 13)
	ap.add_child(web_addr)
	var pg := PanelContainer.new()
	pg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pg.add_theme_stylebox_override("panel", _sb(Color("#ffffff"), 0, P["body"].darkened(0.3)))
	v.add_child(pg)
	web_rt = RichTextLabel.new()
	web_rt.bbcode_enabled = true
	web_rt.scroll_active = false
	web_rt.add_theme_color_override("default_color", Color("#1b1b1b"))
	web_rt.add_theme_font_size_override("normal_font_size", 14)
	web_rt.add_theme_font_size_override("bold_font_size", 15)
	web_rt.meta_clicked.connect(func(m): _web_link(str(m)))
	pg.add_child(web_rt)
	_lbl(v, "Подключение: " + _net_speed(), 11, P["fg"].lerp(Color("#888"), 0.5))
	_web_render()


func _go(page: String) -> void:
	if web_busy:
		return
	web_hist.append(web_page)
	web_page = page
	_web_render()


func _link(target: String, text: String) -> String:
	return "[url=%s][color=#1a56c8][u]%s[/u][/color][/url]" % [target, text]


func _web_render() -> void:
	if web_rt == null or not is_instance_valid(web_rt):
		return
	var y := Game.year()
	var gpu := Game.pdata(pc, "gpu")
	var bb := ""
	var addr := ""
	match web_page:
		"home":
			addr = "http://www.miron-poisk.ru/" if y < 2010 else "https://miron-poisk.ru"
			bb = "[center][font_size=30][b][color=#ff8a1f]Мирон[/color]-[color=#2f86e0]Поиск[/color][/b][/font_size]\n[color=#777]найдётся всё (почти)[/color][/center]\n\n"
			bb += "[b]Популярное сегодня:[/b]\n"
			bb += "• " + _link("page:news", "Новости %d года" % y) + "\n"
			bb += "• " + _link("page:drivers", "Драйверы для видеокарты %s" % gpu.get("name", "")) + "\n"
			bb += "• " + _link("page:miron", "miron1126 — игры и приложения") + "\n"
			if y >= 2006:
				bb += "• " + _link("page:social", "Миронет — соцсеть для своих") + "\n"
			bb += "• " + _link("page:free", "СКАЧАТЬ ИГРЫ БЕСПЛАТНО БЕЗ СМС!!!") + " [color=#999](реклама)[/color]\n"
		"news":
			addr = "http://news.miron-poisk.ru/%d" % y
			bb = "[font_size=22][b]Новости — %d год[/b][/font_size]\n\n" % y
			for yy in [y, y - 1, y - 2]:
				if Data.EVENTS.has(yy):
					bb += "[b]%d:[/b] %s\n\n" % [yy, Data.EVENTS[yy]]
			bb += _link("page:home", "← на главную")
		"drivers":
			addr = "http://drivers.miron-poisk.ru/"
			bb = "[font_size=22][b]Центр драйверов[/b][/font_size]\n\n"
			bb += "Ваша видеокарта: [b]%s[/b]\nСистема: [b]%s[/b]\n\n" % [gpu.get("name", "?"), os_name]
			var err := Game.can_drivers(pc)
			if pc["drivers"]:
				bb += "[color=#2e7d32]Драйвер уже установлен. Всё отлично![/color]"
			elif err != "":
				bb += "[color=#c62828]%s[/color]" % err
			else:
				bb += _link("act:drivers", "▶ Скачать и установить драйвер") + "  [color=#777](%s)[/color]" % _net_speed()
		"miron":
			addr = "https://github.com/miron11265282" if y >= 2008 else "http://miron1126.narod.ru/"
			bb = "[font_size=24][b]miron1126[/b][/font_size]\n[color=#777]игры и приложения[/color]\n\n"
			bb += "• [b]miron1126 TechShop[/b] — мастерская по ремонту компьютеров (вы здесь!)\n"
			bb += "• [b]miron1126 TechVerse[/b] — открывай кейсы с системами\n"
			bb += "• [b]miron1126 Flash Lab[/b] — прошивка телефонов\n\n"
			bb += "Кошка Буся — моя племянница. Привет ей!"
		"social":
			addr = "https://mironet.ru/feed"
			bb = "[font_size=22][b][color=#2f86e0]Миронет[/color][/b][/font_size]  лента друзей\n\n"
			var posts := [["Буся", "Мяу. Опять мастер весь день чинит компы, а вкусняшку кто даст?"],
				[Game.pc_user(pc), "Отнёс комп в мастерскую. Надеюсь, фотки не потеряют…"],
				["Сосед Серёга", "Кто знает, почему вентилятор воет как самолёт?"],
				["miron1126", "Вышло обновление TechShop! Теперь можно сесть за ПК клиента."]]
			for pst in posts:
				bb += "[b]%s[/b]\n%s\n[color=#999]%d лайков · комментарии[/color]\n\n" % [pst[0], pst[1], absi(String(pst[1]).hash()) % 90 + 3]
		"free":
			addr = "http://free-games-bez-sms.xyz/download"
			bb = "[bgcolor=#ffeb3b][font_size=22][b][color=#d50000]ПОЗДРАВЛЯЕМ!!! ВЫ 1 000 000-Й ПОСЕТИТЕЛЬ![/color][/b][/font_size][/bgcolor]\n\n"
			bb += "Все игры мира БЕСПЛАТНО! Нажми и качай:\n\n"
			bb += _link("act:trap", "[font_size=20][b]>>> СКАЧАТЬ ВСЁ.exe <<<[/b][/font_size]") + "\n\n"
			bb += "[color=#999]Нажимая, вы соглашаетесь на всё.[/color]"
	web_addr.text = "  " + addr
	web_rt.text = bb


func _web_link(m: String) -> void:
	if m.begins_with("page:"):
		_go(m.substr(5))
	elif m == "act:drivers":
		if web_busy or Game.can_drivers(pc) != "":
			return
		web_busy = true
		var secs := 3.0 if Game.year() < 2002 else 1.5
		var steps := 10
		for i in steps:
			if not is_instance_valid(web_rt):
				web_busy = false
				return
			web_rt.text = "[b]Загрузка драйвера…[/b]\n\n%s %d%%\n\n[color=#777]%s[/color]" % ["■".repeat(i + 1) + "□".repeat(steps - i - 1), (i + 1) * 10, _net_speed()]
			await get_tree().create_timer(secs / steps).timeout
		pc["drivers"] = true
		changed = true
		web_busy = false
		if is_instance_valid(web_rt):
			web_rt.text = "[color=#2e7d32][b]Драйвер установлен![/b][/color]\nРазрешение экрана теперь нормальное.\n\n" + _link("page:home", "← на главную")
	elif m == "act:trap":
		var y := Game.year()
		var v := "macro" if y < 2000 else ("worm" if y < 2003 else ("adware" if y < 2011 else "miner"))
		if not pc["viruses"].has(v):
			pc["viruses"].append(v)
		pc["scanned"] = false
		changed = true
		web_rt.text = "[color=#c62828][font_size=20][b]Упс…[/b][/font_size][/color]\n\nФайл «СКАЧАТЬ ВСЁ.exe» оказался вирусом [b]%s[/b]!\nНикогда не качай с таких сайтов. Теперь придётся лечить ПК." % Data.viruses[v]["name"]


func _sb2(col: Color) -> StyleBoxFlat:
	return _sb(col, 0)


# ---------------- почта ----------------

func _mails() -> Array:
	var y := Game.year()
	var L := []
	L.append({"id": "w", "from": "miron1126", "subj": "Добро пожаловать!", "body": "Привет! Это почта внутри TechShop. Тут клиенты пишут, а мошенники — шлют вирусы. Не открывай подозрительные вложения!"})
	var who := Game.pc_user(pc)
	if not is_same(pc, Game.my_pc):
		L.append({"id": "c", "from": who, "subj": "Про мой компьютер", "body": "Здравствуйте! Пожалуйста, не удаляйте мои фотографии и документы. Если надо переставить систему — сначала сделайте бэкап. Спасибо!"})
	L.append({"id": "b", "from": "Буся", "subj": "мяу", "body": "Мяу мяу. Мяу? (перевод: если компьютер тормозит — загляни в диспетчер задач. Там может сидеть майнер под чужим именем.)"})
	L.append({"id": "s", "from": "Лотерея «Миллион»", "subj": "ВЫ ВЫИГРАЛИ 1 000 000!!!", "body": "Для получения выигрыша отправьте SMS на короткий номер… [color=#999](это спам — просто удали)[/color]"})
	if y >= 2000:
		L.append({"id": "love", "from": "Незнакомец", "subj": "ILOVEYOU", "body": "Пожалуйста, посмотри письмо любви во вложении.", "attach": "LOVE-LETTER-FOR-YOU.TXT.vbs", "virus": "romance"})
	if y >= 2005:
		L.append({"id": "bank", "from": "Сlужба безопасности банка", "subj": "Срочно подтвердите пароль", "body": "Ваша карта заблокирована. Скачайте программу проверки во вложении.", "attach": "bank_check.exe", "virus": "spy" if y >= 2006 else "worm"})
	return L


func _unread() -> int:
	var n := 0
	for m in _mails():
		if not mail_read.has(m["id"]):
			n += 1
	return n


func _open_mail() -> void:
	var v := _window("Почта — " + Game.pc_user(pc), 760, 480)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 8)
	v.add_child(h)
	mail_list = ItemList.new()
	mail_list.custom_minimum_size.x = 250
	mail_list.add_theme_stylebox_override("panel", _sb(Color.WHITE, 0, P["body"].darkened(0.3)))
	mail_list.add_theme_color_override("font_color", Color("#111"))
	mail_list.add_theme_stylebox_override("selected", _sb(P["sel"]))
	mail_list.add_theme_stylebox_override("selected_focus", _sb(P["sel"]))
	mail_list.add_theme_font_size_override("font_size", 13)
	h.add_child(mail_list)
	var bp := PanelContainer.new()
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bp.add_theme_stylebox_override("panel", _sb(Color.WHITE, 0, P["body"].darkened(0.3)))
	h.add_child(bp)
	mail_body = RichTextLabel.new()
	mail_body.bbcode_enabled = true
	mail_body.scroll_active = false
	mail_body.add_theme_color_override("default_color", Color("#1b1b1b"))
	mail_body.add_theme_font_size_override("normal_font_size", 14)
	mail_body.meta_clicked.connect(func(m): _mail_link(str(m)))
	bp.add_child(mail_body)
	mail_body.text = "[color=#777]Выбери письмо слева.[/color]"
	mail_list.item_selected.connect(func(i): _mail_show(i))
	_mail_fill()


func _mail_fill() -> void:
	mail_items = _mails()
	mail_list.clear()
	for m in mail_items:
		var unread := not mail_read.has(m["id"])
		mail_list.add_item(("● " if unread else "   ") + "%s — %s" % [m["from"], m["subj"]])


func _mail_show(i: int) -> void:
	var m: Dictionary = mail_items[i]
	mail_read[m["id"]] = true
	var bb := "[b]От:[/b] %s\n[b]Тема:[/b] %s\n\n%s" % [m["from"], m["subj"], m["body"]]
	if m.has("attach"):
		bb += "\n\n[b]Вложение:[/b] " + _link("att:" + m["id"], m["attach"])
	mail_body.text = bb
	mail_list.set_item_text(i, "   %s — %s" % [m["from"], m["subj"]])
	_build_icons()


func _mail_link(m: String) -> void:
	if not m.begins_with("att:"):
		return
	var id := m.substr(4)
	for it in mail_items:
		if it["id"] == id and it.has("virus"):
			var v: String = it["virus"]
			if not pc["viruses"].has(v):
				pc["viruses"].append(v)
			pc["scanned"] = false
			changed = true
			mail_body.text = "[color=#c62828][font_size=20][b]Это был вирус![/b][/font_size][/color]\n\nВложение «%s» запустило [b]%s[/b] — %s.\nУрок: не открывай вложения от незнакомцев." % [it["attach"], Data.viruses[v]["name"], Data.viruses[v]["desc"]]
