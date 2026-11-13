extends Control
## Нарисованная деталь: магазин, склад, корпус ПК. Вид зависит от года выпуска детали.

const Gfx := preload("res://scripts/ui/Gfx.gd")

var part_id := ""
var broken := false
var t := 0.0
var spin := false


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(56, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if spin:
		t += delta
		queue_redraw()


static func _short(name: String) -> String:
	var w := name.split(" ")
	return w[w.size() - 1] if w.size() > 0 else name


static func _rot(ci: CanvasItem, r: Rect2) -> Rect2:
	## Поворачивает рисование на 90°, возвращает прямоугольник в повёрнутых координатах
	ci.draw_set_transform(r.get_center(), -PI / 2.0, Vector2.ONE)
	return Rect2(-Vector2(r.size.y, r.size.x) / 2.0, Vector2(r.size.y, r.size.x))


static func _unrot(ci: CanvasItem) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_part(ci: CanvasItem, d: Dictionary, r: Rect2, t: float = 0.0) -> void:
	if d.is_empty() or r.size.x < 4 or r.size.y < 4:
		return
	var y := int(d.get("year", 2000))
	match d["slot"]:
		"cpu":
			_cpu(ci, d, r, y)
		"mobo":
			_mobo(ci, d, r, y)
		"cooler":
			_cooler(ci, d, r, y, t)
		"ram":
			if r.size.y > r.size.x * 1.2:
				var rr := _rot(ci, r)
				_ram(ci, d, rr, y, t)
				_unrot(ci)
			else:
				_ram(ci, d, r, y, t)
		"gpu":
			_gpu(ci, d, r, y, t)
		"storage":
			_storage(ci, d, r, y)
		"psu":
			_psu(ci, d, r, y, t)


static func _cpu(ci: CanvasItem, d: Dictionary, r: Rect2, y: int) -> void:
	var s: float = min(r.size.x, r.size.y)
	var q := Rect2(r.get_center() - Vector2(s, s) / 2.0, Vector2(s, s))
	var sub := Color("#3f7a3a") if y < 2006 else Color("#1f4d2c")
	Gfx.rr(ci, q, sub, s * 0.06, sub.darkened(0.4), 1, 3)
	# контакты по краю (старые процессоры с ножками)
	if y < 2006:
		var n := 7
		for i in n:
			var u := (i + 0.5) / n
			for p in [Vector2(u, 0.05), Vector2(u, 0.95), Vector2(0.05, u), Vector2(0.95, u)]:
				ci.draw_circle(q.position + q.size * p, max(0.6, s * 0.012), Color("#d8b45a"))
	var ihs := q.grow(-s * (0.16 if y >= 1997 else 0.1))
	if y < 1997:
		Gfx.rr(ci, ihs, Color("#e9e4d6"), s * 0.03)
		Gfx.rr(ci, ihs.grow(-s * 0.14), Color("#c7c2b2"), s * 0.02)
	else:
		Gfx.metal(ci, ihs, Color("#c3c8ce"), s * 0.05)
	if s >= 34:
		var fs: int = clamp(int(s * 0.13), 7, 15)
		Gfx.text(ci, ihs.position + Vector2(0, ihs.size.y * 0.55), _short(String(d["name"])), fs, Color("#3a3d44"), ihs.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	ci.draw_colored_polygon(PackedVector2Array([q.position + Vector2(2, 2), q.position + Vector2(s * 0.2, 2), q.position + Vector2(2, s * 0.2)]), Color("#ffd54a"))


static func _mobo(ci: CanvasItem, d: Dictionary, r: Rect2, y: int) -> void:
	var pcb := Color("#2e7d3c") if y < 2004 else (Color("#1e3b2c") if y < 2010 else (Color("#232a30") if y < 2016 else Color("#17191d")))
	var sx := r.size.x
	var sy := r.size.y
	var P := r.position
	var big := sx > 120
	Gfx.rr(ci, r, pcb, 3, pcb.darkened(0.45), 1, 4)
	if big:
		Gfx.textured(ci, r.grow(-1), "pcb", Color(1, 1, 1, 0.8))
	var Q := func(x: float, yy: float, w: float, h: float) -> Rect2: return Rect2(P + Vector2(sx * x, sy * yy), Vector2(sx * w, sy * h))
	# дорожки
	var tr := Color(pcb.lightened(0.18), 0.7)
	for i in (9 if big else 5):
		var yy := P.y + sy * (0.16 + i * 0.075)
		var x0 := P.x + sx * (0.04 + fmod(i * 0.13, 0.2))
		ci.draw_polyline(PackedVector2Array([Vector2(x0, yy), Vector2(x0 + sx * 0.16, yy), Vector2(x0 + sx * 0.2, yy + sy * 0.035), Vector2(x0 + sx * 0.45, yy + sy * 0.035)]), tr, 1.0, true)
	# задние разъёмы (I/O)
	var io: Rect2 = Q.call(0.0, 0.02, 0.13, 0.42)
	Gfx.metal(ci, io, Color("#9ea4ab"), 2)
	if big:
		for i in 5:
			Gfx.rr(ci, Rect2(io.position + Vector2(io.size.x * 0.2, io.size.y * (0.08 + i * 0.18)), Vector2(io.size.x * 0.6, io.size.y * 0.1)), Color("#2a2c31") if i % 2 == 0 else Color("#3a6fd6"), 1)
	if y >= 2016:
		# кожух I/O с подсветкой
		var sh: Rect2 = Q.call(0.1, 0.03, 0.1, 0.4)
		Gfx.rr(ci, sh, Color("#24262c"), 3, Color("#3a3d44"), 1, 3)
		Gfx.textured(ci, sh.grow(-2), "brushed")
		ci.draw_line(sh.position + Vector2(sh.size.x - 3, 6), Vector2(sh.end.x - 3, sh.end.y - 6), Color("#ff8a1f"), 2.0)
	# сокет
	var sock: Rect2 = Q.call(0.3, 0.12, 0.24, 0.22)
	if y < 1998 or y >= 2000 and y < 2006:
		# ZIF-сокет с рычагом
		Gfx.rr(ci, sock, Color("#ece6d6"), 2, Color("#b7af98"), 1, 2)
		Gfx.rr(ci, sock.grow(-min(sock.size.x, sock.size.y) * 0.12), Color("#e0d9c6"), 1)
		ci.draw_line(Vector2(sock.end.x + 2, sock.position.y + 2), Vector2(sock.end.x + 2, sock.end.y), Color("#d9d1b8"), 3.0)
	elif y < 2000:
		# Slot 1
		Gfx.rr(ci, Rect2(sock.position + Vector2(0, sock.size.y * 0.4), Vector2(sock.size.x, sock.size.y * 0.2)), Color("#222"), 1)
	else:
		# LGA/AM с прижимной рамкой
		Gfx.rr(ci, sock.grow(sock.size.x * 0.06), Color("#5b6068"), 3, Color("#3a3d44"), 1, 3)
		Gfx.rr(ci, sock, Color("#2a2c31"), 2)
		Gfx.rr(ci, sock.grow(-sock.size.x * 0.14), Color("#b9a46a"), 1)
		ci.draw_line(Vector2(sock.end.x + sock.size.x * 0.1, sock.position.y), Vector2(sock.end.x + sock.size.x * 0.1, sock.end.y + 4), Color("#c3c8ce"), 2.0)
	# питание процессора: дроссели и конденсаторы
	if y >= 2005:
		var hs := Color("#4a4f58") if y < 2016 else Color("#2a2d33")
		Gfx.metal(ci, Q.call(0.17, 0.08, 0.1, 0.3), hs, 2)
		Gfx.metal(ci, Q.call(0.3, 0.035, 0.27, 0.065), hs, 2)
		if big:
			Gfx.textured(ci, Q.call(0.17, 0.08, 0.1, 0.3).grow(-2), "brushed")
			for i in 4:
				Gfx.rr(ci, Q.call(0.18 + (i % 2) * 0.045, 0.4 + (i / 2) * 0.05, 0.035, 0.035), Color("#6b6f77"), 1)
	else:
		for i in 6:
			var c := P + Vector2(sx * (0.2 + (i % 2) * 0.05), sy * (0.12 + (i / 2) * 0.08))
			var cr: float = max(1.5, sx * 0.018)
			ci.draw_circle(c, cr, Color("#2b2f6b") if y < 2001 else Color("#1b1b1b"))
			ci.draw_circle(c, cr * 0.55, Color("#b0b6c0"))
			ci.draw_line(c - Vector2(cr * 0.5, 0), c + Vector2(cr * 0.5, 0), Color("#555"), 1.0)
	# слоты памяти с защёлками
	var nslots := 4 if y >= 2003 else 2
	for i in nslots:
		var col: Color = Color("#222") if y < 2010 else (Color("#3a6fd6") if i % 2 == 0 and y < 2016 else (Color("#2c2f36") if y >= 2016 else Color("#222")))
		var sl: Rect2 = Q.call(0.62 + i * 0.045, 0.06, 0.026, 0.44)
		Gfx.rr(ci, sl, col, 1, col.lightened(0.2), 1)
		if big:
			ci.draw_rect(Rect2(sl.position - Vector2(1, 3), Vector2(sl.size.x + 2, 4)), Color("#e8e8e8") if y < 2016 else Color("#9aa0a8"))
			ci.draw_rect(Rect2(Vector2(sl.position.x - 1, sl.end.y - 1), Vector2(sl.size.x + 2, 4)), Color("#e8e8e8") if y < 2016 else Color("#9aa0a8"))
	# 24-pin
	if big:
		Gfx.rr(ci, Q.call(0.9, 0.22, 0.05, 0.2), Color("#e8e2d0") if y < 2008 else Color("#1a1b1e"), 1, Color(0, 0, 0, 0.4), 1)
	# чипсет
	var cs: Rect2 = Q.call(0.58, 0.6, 0.17, 0.15)
	if y >= 2004:
		Gfx.metal(ci, cs, Color("#5b6068") if y < 2016 else Color("#2c2f36"), 3)
		if big:
			Gfx.textured(ci, cs.grow(-2), "brushed")
		if y >= 2016:
			ci.draw_line(cs.position + Vector2(4, cs.size.y - 4), cs.end - Vector2(4, 4), Color("#ff8a1f"), 2)
			if big:
				Gfx.text(ci, cs.position + Vector2(0, cs.size.y * 0.55), "miron", int(max(6, cs.size.y * 0.3)), Color(1, 1, 1, 0.5), cs.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		Gfx.rr(ci, cs.grow(-2), Color("#16181b"), 1)
		if big:
			Gfx.text(ci, cs.position + Vector2(0, cs.size.y * 0.6), "INTEL" if y < 2001 else "VIA", int(max(6, cs.size.y * 0.25)), Color("#888"), cs.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	# слоты расширения
	var slot_col := Color("#ece6d6") if y < 2004 else Color("#222428")
	for i in 3:
		var ry := 0.52 + i * 0.11
		var first := i == 0
		var col2: Color = slot_col
		if first:
			col2 = Color("#6d4c2a") if y < 2004 and y >= 1997 else (Color("#151618") if y >= 2004 else slot_col)
		var srect: Rect2 = Q.call(0.08, ry, 0.46, 0.035)
		Gfx.rr(ci, srect, col2, 1, Color(0, 0, 0, 0.3), 1)
		if first and y >= 2016:
			Gfx.rr(ci, srect.grow(1), Color(0, 0, 0, 0), 1, Color("#c3c8ce"), 1)
	# M.2 с радиатором
	if y >= 2015:
		var m2: Rect2 = Q.call(0.1, 0.84, 0.34, 0.05)
		if y >= 2019:
			Gfx.metal(ci, m2.grow(2), Color("#2c2f36"), 2)
			if big:
				Gfx.textured(ci, m2, "brushed")
		else:
			Gfx.rr(ci, m2, Color("#2b2e35"), 1)
	# аудио-конденсаторы
	if y >= 2010 and big:
		for i in 4:
			var c2 := P + Vector2(sx * (0.06 + i * 0.03), sy * 0.93)
			ci.draw_circle(c2, sx * 0.011, Color("#d4a017"))
			ci.draw_circle(c2, sx * 0.006, Color("#8a6a10"))
	# батарейка
	var bc := P + Vector2(sx * 0.82, sy * 0.86)
	Gfx.circle_grad(ci, bc, max(2.0, sx * 0.035), Color("#eef0f2"), Color("#9aa0a8"))
	# SATA / IDE
	if y < 2006:
		Gfx.rr(ci, Q.call(0.9, 0.48, 0.05, 0.26), Color("#222"), 1)
		if big:
			for i in 8:
				ci.draw_circle(P + Vector2(sx * 0.925, sy * (0.5 + i * 0.03)), 0.8, Color("#d8b45a"))
	else:
		for i in 4:
			Gfx.rr(ci, Q.call(0.9, 0.5 + i * 0.06, 0.05, 0.035), Color("#2f6fd6") if y < 2016 else Color("#26282d"), 1)
	# винты по углам
	if big:
		for pp in [Vector2(0.03, 0.03), Vector2(0.97, 0.03), Vector2(0.03, 0.97), Vector2(0.97, 0.97), Vector2(0.55, 0.5)]:
			Gfx.screw(ci, P + Vector2(sx, sy) * pp, max(2.0, sx * 0.012))


static func _cooler(ci: CanvasItem, d: Dictionary, r: Rect2, y: int, t: float) -> void:
	var c := r.get_center()
	var s: float = min(r.size.x, r.size.y)
	var cool := int(d.get("cool", 30))
	var blur := t != 0.0
	if cool >= 85:
		# помпа водянки
		Gfx.rr(ci, Rect2(c - Vector2(s, s) * 0.44, Vector2(s, s) * 0.88), Color("#141518"), s * 0.22, Color("#2c2f35"), 2, 6)
		Gfx.textured(ci, Rect2(c - Vector2(s, s) * 0.36, Vector2(s, s) * 0.72), "brushed", Color(1, 1, 1, 0.5))
		var hue := fmod(t * 0.2, 1.0)
		var rc := Color.from_hsv(hue, 0.75, 1.0) if t != 0.0 else Color("#3a3d44")
		if t != 0.0:
			Gfx.glow(ci, c, s * 0.55, Color(rc, 0.3))
		ci.draw_arc(c, s * 0.3, 0, TAU, 48, rc, max(2.0, s * 0.05), true)
		Gfx.circle_grad(ci, c, s * 0.24, Color("#2a2d33"), Color("#0e0f11"))
		Gfx.text(ci, c + Vector2(-s * 0.3, s * 0.06), "AIO", int(max(7, s * 0.14)), Color("#cfd3d9"), s * 0.6, HORIZONTAL_ALIGNMENT_CENTER, true)
	elif cool >= 55:
		# башня: тепловые трубки, рёбра, вентилятор
		var hs := Rect2(c - Vector2(s * 0.52, s * 0.5), Vector2(s * 1.04, s))
		for k in 4:
			var px := hs.position.x + hs.size.x * (0.2 + k * 0.2)
			ci.draw_line(Vector2(px, hs.position.y - s * 0.06), Vector2(px, hs.position.y + s * 0.1), Color("#c98a3a"), max(2.0, s * 0.05))
			ci.draw_circle(Vector2(px, hs.position.y - s * 0.06), max(1.5, s * 0.03), Color("#e0a050"))
		Gfx.metal(ci, hs, Color("#b5bbc3"), 3)
		Gfx.textured(ci, hs.grow(-2), "brushed")
		for i in 14:
			var yy := hs.position.y + hs.size.y * (i + 0.5) / 14.0
			ci.draw_line(Vector2(hs.position.x + 2, yy), Vector2(hs.end.x - 2, yy), Color("#8e959e"), 1.0)
			ci.draw_line(Vector2(hs.position.x + 2, yy + 1), Vector2(hs.end.x - 2, yy + 1), Color(1, 1, 1, 0.25), 1.0)
		var fcol := Color("#202228") if y < 2016 else Color("#141518")
		Gfx.fan(ci, c, s * 0.4, t * 14.0, fcol, Color("#5a5f68") if y < 2016 else Color("#30333a"), true, 7, blur)
		if y >= 2018 and t != 0.0:
			ci.draw_arc(c, s * 0.4, 0, TAU, 40, Color.from_hsv(fmod(t * 0.15, 1.0), 0.8, 1.0), 2.0, true)
	else:
		# боксовый
		var hs := Rect2(c - Vector2(s * 0.48, s * 0.48), Vector2(s * 0.96, s * 0.96))
		if y >= 2006:
			Gfx.circle_grad(ci, c, s * 0.5, Color("#c8cdd3"), Color("#7e848c"))
			for i in 24:
				var a := TAU * i / 24.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * s * 0.3, c + Vector2(cos(a), sin(a)) * s * 0.5, Color(0, 0, 0, 0.18), 1.0)
			Gfx.fan(ci, c, s * 0.36, t * 16.0, Color("#16181b"), Color("#2a2d33"), false, 7, blur)
		else:
			Gfx.metal(ci, hs, Color("#a9afb7"), s * 0.06)
			Gfx.textured(ci, hs.grow(-2), "brushed")
			Gfx.fan(ci, c, s * 0.4, t * 16.0, Color("#16181b"), Color("#3f434b"), true, 7, blur)


static func _ram(ci: CanvasItem, d: Dictionary, r: Rect2, y: int, t: float) -> void:
	var stick := Rect2(r.position + Vector2(0, r.size.y * 0.2), Vector2(r.size.x, r.size.y * 0.6))
	var pcb := Color("#2e7d32") if y < 2008 else Color("#1f2a24")
	Gfx.rr(ci, stick, pcb, 2, pcb.darkened(0.4), 1, 2)
	var gy := stick.end.y - stick.size.y * 0.16
	Gfx.rr(ci, Rect2(Vector2(stick.position.x + 3, gy), Vector2(stick.size.x - 6, stick.size.y * 0.13)), Color("#d8b45a"), 1)
	var n2 := int(stick.size.x / 3.5)
	for i in n2:
		var xx := stick.position.x + 4 + i * 3.5
		ci.draw_line(Vector2(xx, gy + 1), Vector2(xx, gy + stick.size.y * 0.12), Color("#b8963c"), 1.0)
	ci.draw_rect(Rect2(Vector2(stick.position.x + stick.size.x * 0.42, gy - 1), Vector2(max(2.0, stick.size.x * 0.03), stick.size.y * 0.18)), Color(0, 0, 0, 0.9))
	if y >= 2008:
		var hs := Rect2(stick.position + Vector2(1, -stick.size.y * 0.08), Vector2(stick.size.x - 2, stick.size.y * 0.8))
		var col := Color("#3a3f48") if y < 2014 else (Color("#1c1e23") if y < 2019 else Color("#22242a"))
		Gfx.metal(ci, hs, col, 2)
		Gfx.textured(ci, hs.grow(-2), "brushed", Color(1, 1, 1, 0.6))
		# вырезы на радиаторе
		var cut := PackedVector2Array([hs.position + Vector2(hs.size.x * 0.55, 0), hs.position + Vector2(hs.size.x * 0.7, 0), hs.position + Vector2(hs.size.x * 0.6, hs.size.y * 0.5), hs.position + Vector2(hs.size.x * 0.45, hs.size.y * 0.5)])
		ci.draw_colored_polygon(cut, col.darkened(0.3))
		if hs.size.x > 50:
			Gfx.text(ci, hs.position + Vector2(hs.size.x * 0.06, hs.size.y * 0.75), String(d.get("ram", "")), int(clamp(hs.size.y * 0.3, 7, 13)), Color(1, 1, 1, 0.55), -1, HORIZONTAL_ALIGNMENT_LEFT, true)
		if y >= 2019:
			var top := Rect2(hs.position - Vector2(0, stick.size.y * 0.16), Vector2(hs.size.x, stick.size.y * 0.16))
			Gfx.rr(ci, top, Color("#e8e8e8"), 2)
			var h0 := fmod(t * 0.2, 1.0)
			var on := t != 0.0
			Gfx.hgrad(ci, top.grow(-1), Color.from_hsv(h0, 0.8, 1.0) if on else Color("#cfcfcf"), Color.from_hsv(fmod(h0 + 0.4, 1.0), 0.8, 1.0) if on else Color("#e0e0e0"))
			if on:
				Gfx.glow(ci, top.get_center(), top.size.x * 0.6, Color(Color.from_hsv(h0, 0.8, 1.0), 0.2))
	else:
		var n := 8 if r.size.x > 60 else 4
		for i in n:
			var cw := stick.size.x / n
			var chip := Rect2(stick.position + Vector2(cw * i + cw * 0.15, stick.size.y * 0.12), Vector2(cw * 0.7, stick.size.y * 0.5))
			Gfx.rr(ci, chip, Color("#15171a"), 1)
			ci.draw_line(chip.position + Vector2(1, 1), Vector2(chip.end.x - 1, chip.position.y + 1), Color(1, 1, 1, 0.15), 1.0)


static func _gpu(ci: CanvasItem, d: Dictionary, r: Rect2, y: int, t: float) -> void:
	var score := int(d.get("score", 1))
	var name := String(d.get("name", ""))
	var brand := Color("#76b900") if name.contains("NVIDIA") or name.contains("GeForce") or name.contains("RTX") or name.contains("GTX") else (Color("#e53935") if name.contains("AMD") or name.contains("ATI") or name.contains("Radeon") else Color("#4a9ff0"))
	var blur := t != 0.0
	var card := Rect2(r.position + Vector2(r.size.x * 0.06, r.size.y * 0.12), Vector2(r.size.x * 0.94, r.size.y * 0.7))
	# планка с разъёмами
	var br := Rect2(r.position + Vector2(0, r.size.y * 0.02), Vector2(r.size.x * 0.06, r.size.y * 0.96))
	Gfx.metal(ci, br, Color("#b5bbc3"), 1)
	if br.size.y > 30:
		for i in 3:
			Gfx.rr(ci, Rect2(br.position + Vector2(br.size.x * 0.25, br.size.y * (0.18 + i * 0.22)), Vector2(br.size.x * 0.5, br.size.y * 0.14)), Color("#1a1b1e") if y >= 2006 else Color("#2a5bd6"), 1)
	Gfx.rr(ci, Rect2(card.position + Vector2(card.size.x * 0.12, card.size.y), Vector2(card.size.x * 0.45, r.size.y * 0.1)), Color("#d8b45a"), 1)
	var pcb := Color("#2e7d32") if y < 2005 else Color("#1d2b22")
	if score < 15 or y < 2003:
		Gfx.rr(ci, card, pcb, 2, pcb.darkened(0.4), 1, 2)
		if card.size.x > 80:
			Gfx.textured(ci, card.grow(-1), "pcb")
		var chip := Rect2(card.get_center() - Vector2(card.size.y, card.size.y) * 0.3, Vector2(card.size.y, card.size.y) * 0.6)
		if y >= 1999:
			Gfx.metal(ci, chip.grow(card.size.y * 0.08), Color("#9aa0a8"), 2)
			if y >= 2000:
				Gfx.fan(ci, chip.get_center(), card.size.y * 0.32, t * 15.0, Color("#16181b"), Color("#3f434b"), false, 5, blur)
		else:
			Gfx.rr(ci, chip, Color("#16181b"), 1)
			Gfx.text(ci, chip.position + Vector2(0, chip.size.y * 0.6), "S3" if y < 1997 else "3D", int(max(6, chip.size.y * 0.35)), Color("#aaa"), chip.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		for i in 3:
			Gfx.rr(ci, Rect2(card.position + Vector2(card.size.x * (0.72 + i * 0.08), card.size.y * 0.2), Vector2(card.size.x * 0.05, card.size.y * 0.25)), Color("#15171a"), 1)
		return
	# кожух
	var shroud := card
	var sc := Color("#2a2d33") if y < 2016 else Color("#17181c")
	Gfx.rr(ci, Rect2(card.position + Vector2(0, card.size.y * 0.85), Vector2(card.size.x, card.size.y * 0.2)), Color("#222428"), 2)
	Gfx.rr(ci, shroud, sc, card.size.y * 0.16, sc.lightened(0.18), 1, 5)
	Gfx.textured(ci, shroud.grow(-3), "brushed", Color(1, 1, 1, 0.35))
	# угловатые грани дизайна
	ci.draw_line(shroud.position + Vector2(shroud.size.x * 0.02, shroud.size.y * 0.85), shroud.position + Vector2(shroud.size.x * 0.12, shroud.size.y * 0.15), sc.lightened(0.25), 1.5)
	ci.draw_line(shroud.position + Vector2(shroud.size.x * 0.98, shroud.size.y * 0.85), shroud.position + Vector2(shroud.size.x * 0.88, shroud.size.y * 0.15), sc.lightened(0.25), 1.5)
	var fans := 1 if y < 2012 or score < 40 else (2 if y < 2019 else 3)
	var fr: float = min(shroud.size.y * 0.42, shroud.size.x / (fans * 2.25))
	for k in fans:
		var fc := shroud.position + Vector2(shroud.size.x * (k + 0.5) / fans, shroud.size.y * 0.5)
		ci.draw_circle(fc, fr * 1.06, sc.darkened(0.5))
		Gfx.fan(ci, fc, fr, t * 14.0 + k, Color("#101113"), Color("#34373e"), false, 9, blur)
	ci.draw_line(shroud.position + Vector2(shroud.size.x * 0.05, 2), shroud.position + Vector2(shroud.size.x * 0.95, 2), brand, 2.0)
	# разъём доп. питания сверху
	if int(d.get("watt", 0)) > 75:
		Gfx.rr(ci, Rect2(shroud.position + Vector2(shroud.size.x * 0.78, -4), Vector2(shroud.size.x * 0.1, 5)), Color("#111"), 1)
	if y >= 2018 and t != 0.0:
		var rc := Color.from_hsv(fmod(t * 0.2, 1.0), 0.8, 1.0)
		Gfx.hgrad(ci, Rect2(shroud.position + Vector2(shroud.size.x * 0.25, shroud.size.y - 3), Vector2(shroud.size.x * 0.5, 2)), Color(rc, 0.0), rc)
		Gfx.glow(ci, shroud.position + Vector2(shroud.size.x * 0.5, shroud.size.y), shroud.size.x * 0.3, Color(rc, 0.15))


static func _storage(ci: CanvasItem, d: Dictionary, r: Rect2, y: int) -> void:
	match d.get("iface", "ide"):
		"nvme":
			var st := Rect2(r.position + Vector2(0, r.size.y * 0.3), Vector2(r.size.x, r.size.y * 0.4))
			Gfx.rr(ci, st, Color("#1f2a24"), 2)
			Gfx.textured(ci, st, "pcb")
			for i in 2:
				Gfx.rr(ci, Rect2(st.position + Vector2(st.size.x * (0.14 + i * 0.32), st.size.y * 0.15), Vector2(st.size.x * 0.26, st.size.y * 0.7)), Color("#15171a"), 1)
			Gfx.rr(ci, Rect2(st.position + Vector2(st.size.x * 0.78, st.size.y * 0.25), Vector2(st.size.x * 0.1, st.size.y * 0.5)), Color("#2b2e35"), 1)
			Gfx.rr(ci, Rect2(Vector2(st.end.x - st.size.x * 0.05, st.position.y), Vector2(st.size.x * 0.05, st.size.y)), Color("#d8b45a"), 1)
			if st.size.x > 50:
				Gfx.rr(ci, Rect2(st.position + Vector2(st.size.x * 0.14, st.size.y * 0.1), Vector2(st.size.x * 0.58, st.size.y * 0.8)), Color(1, 1, 1, 0.92), 1)
				Gfx.text(ci, st.position + Vector2(st.size.x * 0.14, st.size.y * 0.66), "NVMe SSD", int(max(7, st.size.y * 0.42)), Color("#ff8a1f"), st.size.x * 0.58, HORIZONTAL_ALIGNMENT_CENTER, true)
		_:
			var ssd: bool = int(d.get("speed", 5)) >= 50
			var body := r.grow(-1)
			if ssd:
				Gfx.rr(ci, body, Color("#2b2d33"), 4, Color("#45484f"), 1, 3)
				Gfx.textured(ci, body.grow(-2), "brushed", Color(1, 1, 1, 0.5))
				var lab := body.grow(-body.size.y * 0.18)
				Gfx.rr(ci, lab, Color("#ff8a1f") if y >= 2016 else Color("#4a9ff0"), 2)
				Gfx.text(ci, body.position + Vector2(0, body.size.y * 0.6), "SSD", int(max(7, body.size.y * 0.3)), Color.WHITE, body.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
			else:
				Gfx.metal(ci, body, Color("#b8bdc4"), 3)
				Gfx.textured(ci, body.grow(-2), "brushed")
				var cc := body.position + Vector2(body.size.x * 0.4, body.size.y * 0.5)
				var rad: float = min(body.size.x, body.size.y) * 0.38
				Gfx.circle_grad(ci, cc, rad, Color("#f0f2f5"), Color("#8e949c"))
				ci.draw_arc(cc, rad * 0.7, 0, TAU, 28, Color(0, 0, 0, 0.08), 1.0, true)
				ci.draw_circle(cc, rad * 0.22, Color("#7d838b"))
				ci.draw_line(body.position + Vector2(body.size.x * 0.86, body.size.y * 0.2), cc + Vector2(rad * 0.45, -rad * 0.1), Color("#4a4e54"), max(1.5, rad * 0.12))
				ci.draw_circle(body.position + Vector2(body.size.x * 0.86, body.size.y * 0.2), max(1.5, rad * 0.14), Color("#5d6168"))
				Gfx.rr(ci, Rect2(body.position + Vector2(body.size.x * 0.76, body.size.y * 0.52), Vector2(body.size.x * 0.2, body.size.y * 0.34)), Color("#ece6d6"), 1)
				for p in [Vector2(0.06, 0.12), Vector2(0.94, 0.12), Vector2(0.06, 0.88), Vector2(0.94, 0.88)]:
					Gfx.screw(ci, body.position + body.size * p, max(1.0, body.size.y * 0.04))


static func _psu(ci: CanvasItem, d: Dictionary, r: Rect2, y: int, t: float) -> void:
	var body := r.grow(-1)
	var col := Color("#cfc8b0") if y < 2003 else (Color("#3a3d44") if y < 2012 else Color("#1d1f23"))
	Gfx.metal(ci, body, col, 3)
	Gfx.textured(ci, body.grow(-2), "brushed", Color(1, 1, 1, 0.7))
	var fc := body.position + Vector2(body.size.x * 0.3, body.size.y * 0.5)
	var fr: float = min(body.size.y * 0.42, body.size.x * 0.25)
	Gfx.fan(ci, fc, fr, t * 12.0, col.darkened(0.55), col.darkened(0.3), false, 7, t != 0.0)
	Gfx.grill(ci, fc, fr, col.lightened(0.25) if y < 2003 else Color("#5a5e66"))
	var lab := Rect2(body.position + Vector2(body.size.x * 0.6, body.size.y * 0.18), Vector2(body.size.x * 0.34, body.size.y * 0.64))
	var cheap: bool = d.get("cheap", false)
	Gfx.rr(ci, lab, Color("#ffeb3b") if cheap else (Color("#ececec") if y < 2012 else Color("#2b2e35")), 2, Color(0, 0, 0, 0.3), 1)
	if lab.size.y > 14:
		Gfx.text(ci, lab.position + Vector2(0, lab.size.y * 0.5), "%d W" % int(d.get("watt", 0)), int(clamp(lab.size.y * 0.3, 7, 16)), Color("#b71c1c") if cheap else (Color("#333") if y < 2012 else Color("#ff8a1f")), lab.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		if lab.size.y > 26:
			var e := float(d.get("eff", 0.7))
			var eff := "СУПЕР-МОЩЬ" if cheap else ("80+ GOLD" if e >= 0.88 else ("80+" if e >= 0.8 else ""))
			Gfx.text(ci, lab.position + Vector2(0, lab.size.y * 0.82), eff, int(clamp(lab.size.y * 0.18, 6, 10)), Color("#c49a2a") if eff.begins_with("80") else Color("#b71c1c"), lab.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)


func _draw() -> void:
	draw_part(self, Data.part(part_id), Rect2(Vector2(3, 3), size - Vector2(6, 6)), t)
	if broken:
		draw_line(Vector2(4, 4), size - Vector2(4, 4), Color("#ef5350"), 3, true)
		draw_line(Vector2(size.x - 4, 4), Vector2(4, size.y - 4), Color("#ef5350"), 3, true)
