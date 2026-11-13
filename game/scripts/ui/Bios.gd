extends "res://scripts/ui/OverlayBase.gd"
## BIOS/UEFI: порядок загрузки, Secure Boot, TPM, XMP. Вид зависит от года платы.

var bios := {}
var uefi := false
var has_tpm := false
var ram_type := ""
var board_year := 1995
var board_name := ""
var list_box: VBoxContainer
const DEV_NAMES := {"hdd": "Жёсткий диск / SSD", "cd": "CD/DVD-привод", "usb": "USB-флешка", "floppy": "Дисковод 3.5\"", "net": "Сеть (PXE)"}


func build() -> void:
	border = false
	if uefi:
		bg_color = Color("#14161a")
		fg = Color("#e6e6e6")
		accent = Color("#e53935") if board_name.contains("ROG") or board_name.contains("MSI") else Color("#ff8a1f")
	else:
		bg_color = Color("#0000a8")
		fg = Color("#c0c0c0")
		accent = Color("#ffff55")
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_content_margin_all(18)
	sb.set_corner_radius_all(0 if not uefi else 10)
	add_theme_stylebox_override("panel", sb)
	if uefi:
		title("UEFI BIOS Utility — %s" % board_name)
		label("Режим: Advanced · мышь поддерживается", 13, Color("#9aa0a6"))
	else:
		title("CMOS Setup Utility — %s   (c) %d" % [board_name, board_year])
		label("↑↓ : Выбор   Enter : Изменить   F10 : Сохранить и выйти   Esc : Выход", 13)
	label("Порядок загрузки (Boot Priority) — первое устройство грузится первым:", 16, accent)
	list_box = VBoxContainer.new()
	box.add_child(list_box)
	_fill_list()
	if uefi:
		var grid := GridContainer.new()
		grid.columns = 2
		box.add_child(grid)
		_toggle(grid, "csm", "CSM (поддержка старых систем / MBR)")
		_toggle(grid, "secure_boot", "Secure Boot")
		if has_tpm:
			_toggle(grid, "tpm", "TPM 2.0 (fTPM / PTT)")
		if ram_type == "DDR4" or ram_type == "DDR5":
			_toggle(grid, "xmp", "XMP / EXPO профиль памяти (+скорость)")
	else:
		label("Boot Mode: Legacy BIOS (UEFI на этой плате нет)", 14)
	var r := row()
	btn(r, "F10  Сохранить и выйти", func(): finish({"bios": bios}))
	btn(r, "Esc  Выйти без сохранения", func(): finish({}))


func _toggle(parent: Control, key: String, text: String) -> void:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = bios.get(key, false)
	c.add_theme_color_override("font_color", fg)
	c.toggled.connect(func(on): bios[key] = on)
	parent.add_child(c)


func _fill_list() -> void:
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var order: Array = bios["boot"]
	for i in order.size():
		var r := HBoxContainer.new()
		list_box.add_child(r)
		label("%d. %s" % [i + 1, DEV_NAMES.get(order[i], order[i])], 16, accent if i == 0 else fg, r)
		var idx := i
		btn(r, "▲", func(): _move(idx, -1))
		btn(r, "▼", func(): _move(idx, 1))


func _move(i: int, d: int) -> void:
	var order: Array = bios["boot"]
	var j := i + d
	if j < 0 or j >= order.size():
		return
	var t = order[i]
	order[i] = order[j]
	order[j] = t
	_fill_list()
