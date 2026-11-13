extends Control
## Строка статуса ПК в виде «чипсов» с иконками: температура, пыль, паста, питание, диск, драйверы, вирусы.

const Gfx := preload("res://scripts/ui/Gfx.gd")
const Icons := preload("res://scripts/ui/Icons.gd")

var pc: Dictionary = {}
var chips: Array = []


func _ready() -> void:
	custom_minimum_size.y = 34
	mouse_filter = Control.MOUSE_FILTER_PASS


func setup(p: Dictionary) -> void:
	pc = p
	chips = []
	var good := Color("#66bb6a")
	var warn := Color("#ffb74d")
	var bad := Color("#ef5350")
	var tmp := int(Game.temp(pc))
	chips.append(["temp", "%d°C" % tmp, good if tmp < 80 else (warn if tmp <= 90 else bad), "Температура процессора"])
	var du := int(pc["dust"])
	chips.append(["dust", "Пыль %d%%" % du, good if du < 20 else (warn if du < 60 else bad), "Пыль внутри корпуса"])
	var pa := int(pc["paste"])
	chips.append(["paste", "Паста %d%%" % pa, good if pa >= 70 else (warn if pa >= 40 else bad), "Состояние термопасты"])
	var need := Game.power_need(pc)
	var psu := Game.pdata(pc, "psu")
	var pw := int(psu.get("watt", 0))
	chips.append(["bolt", "%d / %d Вт" % [need, pw], good if pw >= need else bad, "Потребление / мощность блока питания"])
	if pc["parts"]["storage"] != null:
		var free := Game.free_gb(pc)
		var junk := float(pc["junk"])
		chips.append(["disk", "Своб. " + Data.gb_text(max(0.0, free)), good if junk < Game.junk_limit(pc) else warn, "Свободно на диске · мусор " + Data.gb_text(junk)])
	if pc["os"] != "":
		chips.append(["drivers", "Драйверы" if pc["drivers"] else "Нет драйверов", good if pc["drivers"] else warn, "Драйверы видеокарты"])
	var vt := "?"
	var vc := Color("#9aa0a8")
	if pc["scanned"]:
		var n := Game.visible_viruses(pc).size()
		vt = "Чисто" if n == 0 else "Вирусы: %d" % n
		vc = good if n == 0 else bad
	elif pc["viruses"].has("ransom") or pc["viruses"].has("cry"):
		vt = "Вымогатель!"
		vc = bad
	else:
		vt = "Не проверен"
	chips.append(["shield", vt, vc, "Антивирус"])
	var tips := []
	for c in chips:
		tips.append("%s: %s" % [c[3], c[1]])
	tooltip_text = "\n".join(tips)
	queue_redraw()


func _draw() -> void:
	var x := 0.0
	var h := size.y
	var fs := 13
	for c in chips:
		var w := Gfx.text_w(c[1], fs, true) + 40
		if x + w > size.x:
			break
		var col: Color = c[2]
		Gfx.rr(self, Rect2(Vector2(x, 2), Vector2(w, h - 4)), Color(col, 0.13), (h - 4) / 2.0, Color(col, 0.45), 1)
		Icons.draw(self, c[0], Rect2(Vector2(x + 9, h / 2.0 - 8), Vector2(16, 16)), col)
		Gfx.text(self, Vector2(x + 30, h / 2.0 + 5), c[1], fs, col.lightened(0.25), -1, HORIZONTAL_ALIGNMENT_LEFT, true)
		x += w + 6
