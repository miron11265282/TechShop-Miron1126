extends "res://scripts/ui/OverlayBase.gd"
## Rufus: запись загрузочной флешки. Скачай ISO, выбери схему разделов MBR/GPT, нажми СТАРТ.

var year := 1995
var isos: Array = []          # скачанные образы (id ОС)
var choices: Array = []       # какие ОС можно скачать (id)
var want := ""                # какую ОС пользователь хочет
var uefi_board := false
var os_list := {}
var iso_opt: OptionButton
var dl_opt: OptionButton
var scheme_opt: OptionButton
var target_l: Label
var bar: ProgressBar
var status: Label
var job := ""
var job_t := 0.0
var job_len := 1.0
var job_os := ""


func build() -> void:
	bg_color = Color("#f0f0f0")
	fg = Color("#1b1b1b")
	accent = Color("#2f6fd6")
	add_theme_stylebox_override("panel", _sb())
	title("Rufus %s — загрузочная флешка" % ("4.4" if year >= 2020 else ("3.x" if year >= 2018 else "1.x")))
	label("Устройство: Флешка (E:) 16 ГБ", 15)
	var r1 := row()
	label("Образ (ISO):", 15, Color(-1, 0, 0), r1)
	iso_opt = OptionButton.new()
	iso_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(iso_opt)
	var r2 := row()
	label("Скачать образ:", 15, Color(-1, 0, 0), r2)
	dl_opt = OptionButton.new()
	dl_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id in choices:
		dl_opt.add_item(os_list[id]["name"])
		dl_opt.set_item_metadata(dl_opt.item_count - 1, id)
		if id == want:
			dl_opt.select(dl_opt.item_count - 1)
	r2.add_child(dl_opt)
	btn(r2, "СКАЧАТЬ", _download)
	var r3 := row()
	label("Схема разделов:", 15, Color(-1, 0, 0), r3)
	scheme_opt = OptionButton.new()
	scheme_opt.add_item("MBR")
	scheme_opt.add_item("GPT")
	scheme_opt.item_selected.connect(func(_i): _upd_target())
	r3.add_child(scheme_opt)
	target_l = label("", 15, Color(-1, 0, 0), r3)
	label("Подсказка: старые платы (до ~2012) — только BIOS/MBR. Новые с UEFI — GPT. Windows 11 — только GPT + UEFI.", 13, Color("#555555"))
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 26
	box.add_child(bar)
	status = label("ГОТОВ", 15, Color("#2e7d32"))
	var r4 := row()
	btn(r4, "СТАРТ", _start)
	btn(r4, "Закрыть", func(): finish({"isos": isos}))
	_refresh_isos()
	_upd_target()


func _sb() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(16)
	sb.border_color = accent
	sb.set_border_width_all(2)
	return sb


func _refresh_isos() -> void:
	iso_opt.clear()
	for id in isos:
		iso_opt.add_item(os_list[id]["name"] + ".iso")
		iso_opt.set_item_metadata(iso_opt.item_count - 1, id)
		if id == want:
			iso_opt.select(iso_opt.item_count - 1)
	if isos.is_empty():
		iso_opt.add_item("— нет образов, скачай —")
		iso_opt.set_item_metadata(0, "")


func _upd_target() -> void:
	target_l.text = "Целевая система: " + ("BIOS (или UEFI-CSM)" if scheme_opt.selected == 0 else "UEFI (без CSM)")


func _download() -> void:
	if job != "" or dl_opt.item_count == 0:
		return
	job_os = dl_opt.get_item_metadata(dl_opt.selected)
	if isos.has(job_os):
		status.text = "Этот образ уже скачан."
		return
	job = "dl"
	job_t = 0.0
	job_len = 2.0 if year < 2010 else 3.0


func _start() -> void:
	if job != "":
		return
	var id = iso_opt.get_item_metadata(iso_opt.selected)
	if id == null or id == "":
		status.text = "Сначала скачай и выбери образ!"
		return
	job_os = id
	job = "write"
	job_t = 0.0
	job_len = 3.0


func _process(delta: float) -> void:
	if job == "":
		return
	job_t += delta
	bar.value = 100.0 * job_t / job_len
	status.text = ("Скачивание %s… %d%%" if job == "dl" else "Запись %s на флешку… %d%%") % [os_list[job_os]["name"], int(bar.value)]
	if job_t >= job_len:
		bar.value = 100
		if job == "dl":
			isos.append(job_os)
			want = job_os
			_refresh_isos()
			status.text = "Образ скачан!"
			job = ""
		else:
			job = ""
			status.text = "ГОТОВ — флешка записана"
			await get_tree().create_timer(0.6).timeout
			finish({"isos": isos, "os": job_os, "scheme": "MBR" if scheme_opt.selected == 0 else "GPT"})
