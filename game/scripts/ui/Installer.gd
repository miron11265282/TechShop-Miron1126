extends "res://scripts/ui/OverlayBase.gd"
## Мастер установки ОС — как настоящий, свой вид для каждой эпохи.

var os_id := ""
var os_name := ""
var gen := 1
var linux := false
var keys := 0                 # сколько ключей для этой ОС есть у игрока
var has_files := false
var backup := false
var storage_name := ""
var old_os := ""
var copy_time := 3.0
var steps: Array = []
var step := 0
var key_used := false
var edition := ""
var username := "Master"
var lang := "Русский"
var t := 0.0
var bar: ProgressBar
var copying := false
var bypass_ok := false


func build() -> void:
	border = false
	_style()
	if os_id == "dos":
		steps = ["boot", "disk", "copy", "done_step"]
	elif linux:
		steps = ["boot", "lang", "disk", "user", "copy", "done_step"]
	else:
		steps = ["boot", "lang", "key"]
		if gen >= 6:
			steps.append("edition")
		steps += ["license", "disk", "copy", "user"]
		if gen >= 8:
			steps.append("account")
		steps.append("done_step")
	_show()


func _style() -> void:
	var c := ["#0000a8", "#c0c0c0", "#ffffff"]
	if linux:
		c = ["#2c001e", "#f2f2f2", "#e95420"] if os_id == "ubuntu" else ["#25301f", "#eeeeee", "#8fbf5b"]
	elif gen <= 1:
		c = ["#0000a8", "#c0c0c0", "#ffff55"]
	elif gen <= 3:
		c = ["#3a6ea5", "#ffffff", "#ffd54a"]
	elif gen == 4:
		c = ["#1c4ea7", "#ffffff", "#7ec850"]
	elif gen <= 6:
		c = ["#0e2a47", "#eaf6ff", "#8fd8ff"]
	elif gen == 7:
		c = ["#3a1c6e", "#ffffff", "#c78bff"]
	else:
		c = ["#1b2a44", "#ffffff", "#4cc2ff"]
	bg_color = Color(c[0])
	fg = Color(c[1])
	accent = Color(c[2])
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_content_margin_all(22)
	sb.set_corner_radius_all(0 if gen <= 1 and not linux else 10)
	add_theme_stylebox_override("panel", sb)


func _next() -> void:
	step += 1
	_show()


func _show() -> void:
	clear_box()
	copying = false
	var head := "Установка %s" % os_name
	if gen <= 1 and not linux:
		head = "%s Setup" % os_name
	title(head)
	call("_s_" + steps[step])


func _s_boot() -> void:
	label({"floppy": "Загрузка с дискеты A:… вставьте дискету 2 из %d" % (3 if os_id == "dos" else 13),
		"cd": "Press any key to boot from CD…", "usb": "Загрузка с USB-флешки…"}.get(_media(), "Загрузка…"), 16)
	label("Загрузка файлов установки…", 15)
	bar = ProgressBar.new()
	box.add_child(bar)
	copying = true
	t = 0.0


func _media() -> String:
	if os_id in ["dos", "win95"]:
		return "floppy"
	if gen <= 5 and not linux:
		return "cd"
	return "usb"


func _s_lang() -> void:
	label("Язык и регион:", 16)
	var o := OptionButton.new()
	for l in ["Русский", "English", "Українська", "Қазақ тілі"]:
		o.add_item(l)
	o.item_selected.connect(func(i): lang = o.get_item_text(i))
	box.add_child(o)
	label("Формат времени и денежных единиц: Россия · Раскладка: Русская", 14)
	var r := row()
	btn(r, "Далее", _next)
	btn(r, "Отмена", func(): finish({}))


func _s_key() -> void:
	label("Активация Windows — введите ключ продукта", 16)
	if keys > 0:
		label("У тебя есть купленный ключ: XXXXX-XXXXX-XXXXX-XXXXX-%05d" % randi_range(10000, 99999), 15, accent)
		var r := row()
		btn(r, "Ввести ключ", func():
			key_used = true
			_next())
		if gen >= 5:
			btn(r, "У меня нет ключа продукта", _next)
	else:
		label("Ключей для %s у тебя нет (Магазин → Ключи)." % os_name, 15)
		var r2 := row()
		if gen >= 5:
			label("Можно продолжить без ключа — будет надпись «Активируйте Windows».", 14)
			btn(r2, "У меня нет ключа продукта", _next)
		else:
			label("Без ключа эту версию установить нельзя.", 14, Color("#ff8a80"))
		btn(r2, "Отмена", func(): finish({}))


func _s_edition() -> void:
	label("Выберите выпуск:", 16)
	var r := row()
	for e in ["Домашняя (Home)", "Профессиональная (Pro)"]:
		var ed: String = e
		btn(r, ed, func():
			edition = ed
			_next())


func _s_license() -> void:
	label("Условия лицензии", 16)
	label("…Корпорация… предоставляет вам право установить одну копию… (никто это не читает)…", 13)
	var c := CheckBox.new()
	c.text = "Я принимаю условия лицензии"
	box.add_child(c)
	var r := row()
	btn(r, "Далее", func():
		if c.button_pressed:
			_next())


func _s_disk() -> void:
	label("Куда установить %s?" % os_name, 16)
	var info := "Диск 0 · Раздел 1 · %s · %s" % [storage_name, ("установлена " + old_os) if old_os != "" else "неразмеченное пространство"]
	if has_files:
		info += " · файлы клиента: фото, документы"
	label(info, 15, accent)
	if has_files and not backup:
		label("! Форматирование удалит фото и документы клиента! Без бэкапа клиент будет в ярости. (Отмени и сделай «Бэкап» в действиях.)", 14, Color("#ff8a80"))
	elif has_files and backup:
		label("✓ Бэкап файлов клиента сделан — после установки вернём их.", 14, Color("#9ccc65"))
	var r := row()
	btn(r, "Форматировать и установить", _next)
	btn(r, "Отмена", func(): finish({}))


func _s_copy() -> void:
	label("Копирование файлов %s…" % os_name, 16)
	label(["Расширение файлов…", "Установка компонентов…", "Установка обновлений…"].pick_random(), 14)
	if gen <= 2 and not linux:
		label("Совет: Windows %s сделает ваш компьютер быстрее! (ну почти)" % os_name.replace("Windows ", ""), 13)
	bar = ProgressBar.new()
	box.add_child(bar)
	copying = true
	t = 0.0


func _s_user() -> void:
	label("Как вас зовут? (имя пользователя)", 16)
	var le := LineEdit.new()
	le.text = username
	le.text_changed.connect(func(s): username = s)
	box.add_child(le)
	var r := row()
	btn(r, "Далее", _next)


func _s_account() -> void:
	label("Войдите с помощью учётной записи Microsoft", 16)
	var r := row()
	btn(r, "Войти в аккаунт Microsoft", func(): label("Клиент не помнит пароль от почты… Лучше локальная учётная запись.", 14, Color("#ffcc80")))
	if gen == 8 or bypass_ok:
		btn(r, "У меня нет интернета → локальная учётная запись", _next)
	else:
		label("Windows 11 не даёт пропустить вход… Мастера знают трюк: Shift+F10 и команда.", 14)
		var r2 := row()
		var le := LineEdit.new()
		le.placeholder_text = "Shift+F10 → введи команду"
		le.custom_minimum_size.x = 380
		r2.add_child(le)
		btn(r2, "Enter", func():
			if le.text.strip_edges().to_lower().replace("/", "\\") == "oobe\\bypassnro":
				bypass_ok = true
				label("Перезагрузка… теперь есть «У меня нет интернета»!", 14, accent)
				await get_tree().create_timer(0.8).timeout
				_show()
			else:
				label("Команда не найдена.", 14, Color("#ff8a80")))
		label("Подсказка: OOBE\\BYPASSNRO", 12, Color(fg, 0.5))


func _s_done_step() -> void:
	label("Установка завершена!", 18, accent)
	if not linux and os_id != "dos" and not key_used:
		label("На экране надпись «Активируйте Windows» — клиент может заметить.", 14, Color("#ffcc80"))
	label("Не забудь поставить драйверы и вынуть установочный носитель.", 15)
	var r := row()
	btn(r, "Перезагрузить → рабочий стол", func():
		finish({"ok": true, "key": key_used, "edition": edition, "user": username, "files_lost": has_files and not backup}))


func _process(delta: float) -> void:
	if not copying:
		return
	t += delta
	var dur := 1.2 if steps[step] == "boot" else copy_time
	bar.value = 100.0 * t / dur
	if t >= dur:
		copying = false
		_next()
