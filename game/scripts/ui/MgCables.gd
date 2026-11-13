extends "res://scripts/ui/OverlayBase.gd"
## Мини-игра: подключение кабелей. Перетащи каждый кабель на свой разъём.

var need: Array = []          # ключи кабелей
var connected: Array = []
const CABLES := {
	"atx": ["Питание платы (20/24-pin)", "Разъём питания платы"],
	"cpu": ["Питание процессора (4/8-pin)", "Разъём CPU у сокета"],
	"pcie": ["Доп. питание видеокарты (PCIe 6/8-pin)", "Разъём на видеокарте"],
	"disk": ["Питание диска (Molex/SATA)", "Разъём на диске"],
	"panel": ["Передняя панель (Power SW, Reset, LED)", "Пины F_PANEL на плате"],
}
var info: Label
var sockets_box: VBoxContainer
var cables_box: VBoxContainer


func build() -> void:
	title("Подключение кабелей")
	info = label("Перетаскивай кабели слева на правильные разъёмы справа (или нажми на кабель, потом на разъём).", 15)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 30)
	box.add_child(h)
	cables_box = VBoxContainer.new()
	cables_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sockets_box = VBoxContainer.new()
	sockets_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(cables_box)
	h.add_child(sockets_box)
	label("Кабели", 17, accent, cables_box)
	label("Разъёмы", 17, accent, sockets_box)
	var order := need.duplicate()
	order.shuffle()
	for k in need:
		var key: String = k
		var b := Button.new()
		b.text = CABLES[key][0]
		b.name = "cable_" + key
		b.set_drag_forwarding(func(_p):
			var pv := Label.new()
			pv.text = CABLES[key][0]
			b.set_drag_preview(pv)
			return {"cable": key}, Callable(), Callable())
		b.pressed.connect(func(): _selected = key)
		cables_box.add_child(b)
	for k in order:
		var key: String = k
		var pc := PanelContainer.new()
		var l := Label.new()
		l.text = "◯  " + CABLES[key][1]
		pc.add_child(l)
		pc.custom_minimum_size.y = 40
		pc.mouse_filter = Control.MOUSE_FILTER_STOP
		pc.set_drag_forwarding(Callable(), func(_p, d): return typeof(d) == TYPE_DICTIONARY and d.has("cable"),
			func(_p, d): _plug(d["cable"], key, l))
		pc.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and _selected != "":
				_plug(_selected, key, l))
		sockets_box.add_child(pc)
	var r := row()
	btn(r, "Закончить", func(): finish({"connected": connected}))


var _selected := ""


func _plug(cable: String, socket: String, l: Label) -> void:
	_selected = ""
	if connected.has(cable):
		return
	if cable != socket:
		info.text = "Не подходит! «%s» сюда не воткнуть." % CABLES[cable][0]
		return
	connected.append(cable)
	l.text = "✓  " + CABLES[socket][1]
	l.add_theme_color_override("font_color", Color("#66bb6a"))
	var b := cables_box.get_node_or_null("cable_" + cable)
	if b:
		b.disabled = true
	info.text = "Щёлк! Подключено: %s" % CABLES[cable][0]
	if connected.size() == need.size():
		await get_tree().create_timer(0.6).timeout
		finish({"connected": connected})
