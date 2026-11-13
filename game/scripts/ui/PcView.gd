extends Control
## Нарисованный ПК со снятой боковой стенкой. Детали видны внутри, сюда же перетаскиваются детали со склада.

signal part_clicked(slot: String)
signal part_dropped(slot: String, data: Dictionary)

const PartIcon := preload("res://scripts/ui/PartIcon.gd")
const Gfx := preload("res://scripts/ui/Gfx.gd")

var pc: Dictionary = {}
var year := 1995
var powered := false
var hover_slot := ""
var mouse_slot := ""
var t := 0.0
var regions := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(300, 320)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _part(slot: String) -> Dictionary:
	var p = pc.get("parts", {}).get(slot)
	return {} if p == null else Data.part(p["id"])


func _geom() -> Dictionary:
	## Корпус в объёме: боковая сторона (открыта), передняя панель справа, крышка сверху
	var d: float = size.x * 0.09
	var dz: float = d * 0.55
	var h: float = size.y - 16.0 - dz
	var w: float = min(size.x - 10.0 - d, h * 0.92)
	h = min(h, w / 0.92)
	var c := Rect2(Vector2((size.x - w - d) / 2.0, size.y - h - 10.0), Vector2(w, h))
	return {"side": c, "d": d, "dz": dz}


func _case_rect() -> Rect2:
	return _geom()["side"]


func _layout() -> Dictionary:
	var g := _geom()
	var c: Rect2 = g["side"]
	var opening := c.grow(-c.size.x * 0.035)
	var dd := opening.size.x * 0.055
	# задняя стенка (поддон платы) — глубже проёма: видны левая (задняя) и нижняя стенки
	var inner := Rect2(opening.position + Vector2(dd, 0), opening.size - Vector2(dd, dd * 0.6))
	var old_psu_top := year < 2008
	var L := {}
	L["case"] = c
	L["opening"] = opening
	L["dd"] = dd
	L["inner"] = inner
	L["d"] = g["d"]
	L["dz"] = g["dz"]
	var mb := Rect2(inner.position + inner.size * Vector2(0.05, 0.25 if old_psu_top else 0.06), inner.size * Vector2(0.62, 0.62 if old_psu_top else 0.66))
	L["mobo"] = mb
	L["cpu"] = Rect2(mb.position + mb.size * Vector2(0.3, 0.12), Vector2(mb.size.x * 0.24, mb.size.x * 0.24))
	L["cooler"] = L["cpu"].grow(mb.size.x * 0.05)
	L["ram"] = Rect2(mb.position + mb.size * Vector2(0.62, 0.06), mb.size * Vector2(0.17, 0.44))
	L["gpu"] = Rect2(mb.position + mb.size * Vector2(0.04, 0.52), mb.size * Vector2(0.92, 0.2))
	var st := _part("storage")
	if not st.is_empty() and st["iface"] == "nvme":
		L["storage"] = Rect2(mb.position + mb.size * Vector2(0.1, 0.84), mb.size * Vector2(0.36, 0.08))
	elif year >= 2013:
		L["storage"] = Rect2(inner.position + inner.size * Vector2(0.54, 0.8), inner.size * Vector2(0.22, 0.13))
	else:
		L["storage"] = Rect2(inner.position + inner.size * Vector2(0.72, 0.5 if old_psu_top else 0.42), inner.size * Vector2(0.25, 0.13))
	if old_psu_top:
		L["psu"] = Rect2(inner.position + inner.size * Vector2(0.02, 0.02), inner.size * Vector2(0.44, 0.19))
	else:
		L["psu"] = Rect2(inner.position + inner.size * Vector2(0.02, 0.79), inner.size * Vector2(0.44, 0.19))
	return L


func _fp(A: Vector2, B: Vector2, D: Vector2, u: float, v: float) -> Vector2:
	## Точка на передней панели (u — в глубину, v — вниз)
	return A + (B - A) * u + (D - A) * v


func _draw() -> void:
	if pc.is_empty():
		return
	var L := _layout()
	regions = L
	var c: Rect2 = L["case"]
	var inner: Rect2 = L["inner"]
	var opening: Rect2 = L["opening"]
	var d: float = L["d"]
	var dz: float = L["dz"]
	var dd: float = L["dd"]
	var beige := year < 2003
	var modern := year >= 2013
	var outer := Color("#ddd5bd") if beige else (Color("#3b3f46") if not modern else Color("#1a1b1f"))
	var back := Color("#bcb59e") if beige else (Color("#2a2d33") if not modern else Color("#101114"))
	var depth := Vector2(d, -dz)
	# тень на столе
	Gfx.glow(self, Vector2(c.get_center().x + d * 0.5, c.end.y + 2), (c.size.x + d) * 0.62, Color(0, 0, 0, 0.4))
	Gfx.quad(self, Vector2(c.position.x + 6, c.end.y), Vector2(c.end.x + d, c.end.y - dz + 2), Vector2(c.end.x + d + 10, c.end.y - dz + 10), Vector2(c.position.x + 12, c.end.y + 8), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.25), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0))
	# крышка
	var T0 := c.position
	var T1 := c.position + depth
	var T2 := Vector2(c.end.x, c.position.y) + depth
	var T3 := Vector2(c.end.x, c.position.y)
	Gfx.quad(self, T0, T1, T2, T3, outer.lightened(0.12), outer.lightened(0.05), outer.lightened(0.02), outer.lightened(0.1))
	if modern:
		var m := PackedVector2Array([T0.lerp(T1, 0.2) + Vector2(c.size.x * 0.12, 0), T0.lerp(T1, 0.8) + Vector2(c.size.x * 0.12, 0), T3.lerp(T2, 0.8) - Vector2(c.size.x * 0.12, 0), T3.lerp(T2, 0.2) - Vector2(c.size.x * 0.12, 0)])
		draw_polygon(m, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), PackedVector2Array([Vector2(0, 0), Vector2(0, 3), Vector2(12, 3), Vector2(12, 0)]), Gfx.tex("mesh"))
	# передняя панель
	var A := Vector2(c.end.x, c.position.y)
	var B := A + depth
	var D := c.end
	var C := D + depth
	var fcol := outer.darkened(0.12)
	Gfx.quad(self, A, B, C, D, fcol.lightened(0.04), fcol.darkened(0.08), fcol.darkened(0.2), fcol.darkened(0.06))
	if beige:
		# отсеки 5.25" и 3.5", кнопка Turbo и индикатор
		for i in 3:
			var v0 := 0.06 + i * 0.09
			Gfx.quad(self, _fp(A, B, D, 0.12, v0), _fp(A, B, D, 0.88, v0), _fp(A, B, D, 0.88, v0 + 0.07), _fp(A, B, D, 0.12, v0 + 0.07), Color("#d6cfb6"), Color("#c9c1a7"), Color("#bdb59b"), Color("#cfc8ae"))
			draw_line(_fp(A, B, D, 0.2, v0 + 0.035), _fp(A, B, D, 0.8, v0 + 0.035), Color(0, 0, 0, 0.25), 1.0)
		Gfx.quad(self, _fp(A, B, D, 0.25, 0.36), _fp(A, B, D, 0.75, 0.36), _fp(A, B, D, 0.75, 0.4), _fp(A, B, D, 0.25, 0.4), Color("#2a2a2a"))
		draw_circle(_fp(A, B, D, 0.35, 0.5), max(2.0, d * 0.09), Color("#bfb79e"))
		draw_circle(_fp(A, B, D, 0.65, 0.5), max(1.5, d * 0.05), Color("#66ff66") if powered else Color("#3d5c3d"))
		Gfx.quad(self, _fp(A, B, D, 0.3, 0.56), _fp(A, B, D, 0.7, 0.56), _fp(A, B, D, 0.7, 0.6), _fp(A, B, D, 0.3, 0.6), Color("#300") if not powered else Color("#ff3030"))
		for i in 6:
			draw_line(_fp(A, B, D, 0.2, 0.8 + i * 0.025), _fp(A, B, D, 0.8, 0.8 + i * 0.025), Color(0, 0, 0, 0.18), 1.0)
	elif not modern:
		for i in 2:
			var v0 := 0.06 + i * 0.09
			Gfx.quad(self, _fp(A, B, D, 0.1, v0), _fp(A, B, D, 0.9, v0), _fp(A, B, D, 0.9, v0 + 0.07), _fp(A, B, D, 0.1, v0 + 0.07), Color("#2a2d33"), Color("#23262b"), Color("#1e2025"), Color("#26292e"))
		draw_circle(_fp(A, B, D, 0.5, 0.32), max(3.0, d * 0.16), Color("#9aa0a8"))
		draw_circle(_fp(A, B, D, 0.5, 0.32), max(2.0, d * 0.1), Color("#4fc3f7") if powered else Color("#303338"))
		var m2 := PackedVector2Array([_fp(A, B, D, 0.15, 0.45), _fp(A, B, D, 0.85, 0.45), _fp(A, B, D, 0.85, 0.95), _fp(A, B, D, 0.15, 0.95)])
		draw_polygon(m2, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), PackedVector2Array([Vector2(0, 0), Vector2(2, 0), Vector2(2, 8), Vector2(0, 8)]), Gfx.tex("mesh"))
	else:
		var m3 := PackedVector2Array([_fp(A, B, D, 0.1, 0.04), _fp(A, B, D, 0.9, 0.04), _fp(A, B, D, 0.9, 0.96), _fp(A, B, D, 0.1, 0.96)])
		draw_polygon(m3, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), PackedVector2Array([Vector2(0, 0), Vector2(2, 0), Vector2(2, 12), Vector2(0, 12)]), Gfx.tex("mesh"))
		if year >= 2016:
			var rc := Color.from_hsv(fmod(t * 0.12, 1.0), 0.8, 1.0) if powered else Color("#2a2c31")
			draw_line(_fp(A, B, D, 0.05, 0.05), _fp(A, B, D, 0.05, 0.95), rc, 2.0, true)
			if powered:
				Gfx.glow(self, _fp(A, B, D, 0.1, 0.5), c.size.y * 0.25, Color(rc, 0.12))
	# кнопка питания на крышке/панели
	var pbtn := T3.lerp(T2, 0.5) + Vector2(-c.size.x * 0.08, 0) if modern else _fp(A, B, D, 0.5, 0.025)
	draw_circle(pbtn, 4.5, outer.darkened(0.3))
	draw_circle(pbtn, 2.5, Color("#66ff66") if powered else Color("#3a3a3a"))
	if powered:
		Gfx.glow(self, pbtn, 12, Color(0.4, 1, 0.4, 0.35))
	# боковая рамка
	Gfx.rr(self, c, outer, 6, outer.darkened(0.35), 1)
	Gfx.vgrad(self, Rect2(c.position + Vector2(2, 2), Vector2(c.size.x - 4, c.size.y * 0.25)), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0))
	Gfx.textured(self, c.grow(-2), "noise")
	# проём: задняя (левая) и нижняя стенки внутри
	var o0 := opening.position
	var o1 := Vector2(opening.end.x, opening.position.y)
	var o2 := opening.end
	var o3 := Vector2(opening.position.x, opening.end.y)
	var dv := Vector2(dd, -dd * 0.6)
	Gfx.quad(self, o0, o0 + Vector2(dd, 0), o3 + dv, o3, back.darkened(0.35), back.darkened(0.15), back.darkened(0.2), back.darkened(0.45))
	Gfx.quad(self, o3, o3 + dv, o2 + Vector2(0, -dd * 0.6), o2, back.darkened(0.25), back.darkened(0.1), back.darkened(0.15), back.darkened(0.3))
	draw_rect(inner, back)
	Gfx.textured(self, inner, "noise")
	Gfx.vgrad(self, Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.15)), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0))
	Gfx.hgrad(self, Rect2(inner.position, Vector2(inner.size.x * 0.06, inner.size.y)), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0))
	# заглушки слотов расширения на задней стенке
	var mbr: Rect2 = L["mobo"]
	for i in 7:
		var yy := mbr.position.y + mbr.size.y * (0.5 + i * 0.075)
		if yy > inner.end.y - 6:
			break
		var a1 := Vector2(o0.x + 1, yy)
		var a2 := a1 + Vector2(dd - 2, -2)
		Gfx.quad(self, a1, a2, a2 + Vector2(0, mbr.size.y * 0.05), a1 + Vector2(0, mbr.size.y * 0.05), Color("#9aa0a8") if not modern else Color("#3a3d44"), Color("#c3c8ce") if not modern else Color("#4a4e56"))
	# задний вентилятор (на задней стенке, в перспективе)
	if year >= 2001:
		var ef := Vector2(o0.x + dd * 0.5, inner.position.y + inner.size.y * (0.12 if year >= 2008 else 0.3))
		draw_set_transform(ef, 0.0, Vector2(0.38, 1.0))
		Gfx.fan(self, Vector2.ZERO, inner.size.x * 0.07, t * 10.0 if powered else 0.0, Color("#16171a"), Color("#30333a"), true, 7, powered)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# стойки под плату
	for pp in [Vector2(0.05, 0.25 if year < 2008 else 0.06), Vector2(0.67, 0.25 if year < 2008 else 0.06), Vector2(0.05, 0.87 if year < 2008 else 0.72), Vector2(0.67, 0.87 if year < 2008 else 0.72)]:
		draw_circle(inner.position + inner.size * pp + Vector2(4, 4), 2.5, Color("#c9a24a"))
	# отверстия кабель-менеджмента
	if modern:
		for i in 3:
			Gfx.rr(self, Rect2(inner.position + inner.size * Vector2(0.69, 0.1 + i * 0.2), Vector2(inner.size.x * 0.03, inner.size.y * 0.13)), Color("#030304"), 5, Color("#2f3238"), 2)
	# корзина для дисков
	if not modern:
		for i in 3:
			var br := Rect2(inner.position + inner.size * Vector2(0.72, 0.04 + i * 0.1), inner.size * Vector2(0.26, 0.085))
			Gfx.rr(self, br, back.lightened(0.06), 2, back.darkened(0.35), 1)
			if i == 0 and year >= 1997:
				Gfx.metal(self, br.grow(-3), Color("#d9d1b8") if beige else Color("#2c2f35"), 2)
				draw_line(br.position + Vector2(br.size.x * 0.2, br.size.y * 0.5), br.position + Vector2(br.size.x * 0.8, br.size.y * 0.5), Color(0, 0, 0, 0.35), 1.5)
		# крепления 3.5"
		for i in 2:
			draw_line(inner.position + inner.size * Vector2(0.71, 0.38 + i * 0.36), inner.position + inner.size * Vector2(0.99, 0.38 + i * 0.36), back.lightened(0.15), 2.0)
	# передние вентиляторы изнутри
	if modern:
		for i in 3:
			var fc := inner.position + Vector2(inner.size.x * 0.87, inner.size.y * (0.13 + i * 0.21))
			var fr := inner.size.x * 0.085
			var rc2 := Color.from_hsv(fmod(t * 0.12 + i * 0.1, 1.0), 0.8, 1.0)
			if year >= 2016 and powered:
				Gfx.glow(self, fc, fr * 2.4, Color(rc2, 0.22))
			Gfx.fan(self, fc, fr, t * 9.0 if powered else 0.0, Color("#141518"), Color("#2a2d33"), true, 9, powered)
			if year >= 2016:
				draw_arc(fc, fr * 1.02, 0, TAU, 40, rc2 if powered else Color("#2a2c31"), 2.5, true)
	# детали
	_slot_or_part(L, "psu")
	# кожух блока питания
	if year >= 2016:
		var shr := Rect2(inner.position + Vector2(0, inner.size.y * 0.76), Vector2(inner.size.x, inner.size.y * 0.24))
		# стекло-окошко над блоком питания слева, остальное — металл
		var win := Rect2(shr.position + Vector2(shr.size.x * 0.02, shr.size.y * 0.1), Vector2(shr.size.x * 0.46, shr.size.y * 0.8))
		var left_part := Rect2(shr.position, Vector2(win.position.x - shr.position.x, shr.size.y))
		var right_part := Rect2(Vector2(win.end.x, shr.position.y), Vector2(shr.end.x - win.end.x, shr.size.y))
		draw_rect(left_part, Color("#15161a"))
		draw_rect(Rect2(win.position.x, shr.position.y, win.size.x, win.position.y - shr.position.y), Color("#15161a"))
		draw_rect(Rect2(win.position.x, win.end.y, win.size.x, shr.end.y - win.end.y), Color("#15161a"))
		Gfx.rr(self, right_part, Color("#15161a"), 3)
		Gfx.textured(self, right_part.grow(-2), "brushed", Color(1, 1, 1, 0.35))
		Gfx.rr(self, win, Color(0.05, 0.06, 0.08, 0.45), 3, Color("#3a3d44"), 1)
		Gfx.vgrad(self, Rect2(win.position, Vector2(win.size.x, win.size.y * 0.4)), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0))
		draw_line(Vector2(shr.position.x, shr.position.y), Vector2(shr.end.x, shr.position.y), Color("#2e3137"), 2.0)
		Gfx.text(self, shr.position + Vector2(shr.size.x * 0.8, shr.size.y * 0.62), "miron1126", int(max(8, inner.size.y * 0.04)), Color(1, 0.55, 0.12, 0.7), -1, HORIZONTAL_ALIGNMENT_LEFT, true)
	_slot_or_part(L, "mobo")
	for s in ["storage", "ram", "gpu", "cpu", "cooler"]:
		if s == "cooler" and pc["parts"]["cpu"] == null and pc["parts"]["cooler"] == null:
			continue
		if s == "cpu" and pc["parts"]["cooler"] != null:
			continue
		if s in ["cpu", "ram", "gpu"] and pc["parts"]["mobo"] == null:
			continue
		if s == "storage" and _part("storage").get("iface", "") == "nvme" and pc["parts"]["mobo"] == null:
			continue
		_slot_or_part(L, s)
	_cables(L)
	_dust(inner)
	# мягкое затенение углов внутри
	Gfx.vgrad(self, Rect2(inner.position + Vector2(0, inner.size.y * 0.7), Vector2(inner.size.x, inner.size.y * 0.3)), Color(0, 0, 0, 0), Color(0, 0, 0, 0.18))
	# подсветка слота при перетаскивании и наведении
	var hs := hover_slot if hover_slot != "" else mouse_slot
	if hs != "" and L.has(hs):
		var hr: Rect2 = L[hs].grow(5)
		if hover_slot != "":
			Gfx.rr(self, hr, Color(0.4, 1.0, 0.5, 0.18 + 0.1 * sin(t * 8)), 6, Color("#66bb6a"), 2)
		else:
			Gfx.rr(self, hr, Color(1, 1, 1, 0.06), 6, Color(1, 1, 1, 0.5), 1)
			var nm: String = Data.SLOT_NAMES[hs]
			var hd := _part(hs)
			if not hd.is_empty():
				nm = hd["name"]
			var tw := Gfx.text_w(nm, 12) + 14
			var tp := Vector2(clamp(hr.position.x, 2.0, size.x - tw - 2), max(2.0, hr.position.y - 24))
			Gfx.rr(self, Rect2(tp, Vector2(tw, 20)), Color(0, 0, 0, 0.8), 6)
			Gfx.text(self, tp + Vector2(7, 14), nm, 12, Color.WHITE)


func _slot_or_part(L: Dictionary, s: String) -> void:
	var r: Rect2 = L[s]
	var d := _part(s)
	if d.is_empty():
		_dashed(r, Color(1, 1, 1, 0.35))
		Gfx.text(self, r.position + Vector2(0, r.size.y / 2.0 + 5), String(Data.SLOT_NAMES[s]).split(" ")[0], 11, Color(1, 1, 1, 0.55), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var spin := t if powered else 0.0
	if s == "cooler":
		_draw_cooler(r, d, spin, L)
	elif s == "ram":
		# две планки в двухканале
		var w := r.size.x * 0.44
		PartIcon.draw_part(self, d, Rect2(r.position, Vector2(w, r.size.y)), spin)
		PartIcon.draw_part(self, d, Rect2(r.position + Vector2(r.size.x * 0.52, 0), Vector2(w, r.size.y)), spin)
	else:
		PartIcon.draw_part(self, d, r, spin)
	if pc.get("known_broken", []).has(s):
		Gfx.rr(self, r.grow(2), Color(0.9, 0.2, 0.2, 0.25), 4, Color("#ef5350"), 2)
		draw_line(r.position, r.end, Color("#ef5350"), 3, true)
		draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Color("#ef5350"), 3, true)
	if s == "ram" and not pc.get("ram_seated", true):
		Gfx.rr(self, Rect2(r.position + Vector2(-6, -20), Vector2(98, 18)), Color("#ffb74d"), 5)
		Gfx.text(self, r.position + Vector2(-1, -7), "не до щелчка!", 11, Color("#3a2200"), -1, HORIZONTAL_ALIGNMENT_LEFT, true)


func _draw_cooler(r: Rect2, d: Dictionary, spin: float, L: Dictionary) -> void:
	var cool := int(d["cool"])
	var cc := r.get_center()
	if cool >= 85:
		# водянка: помпа на процессоре, шланги к радиатору сверху
		var inner: Rect2 = L["inner"]
		var rad := Rect2(inner.position + inner.size * Vector2(0.14, 0.012), inner.size * Vector2(0.5, 0.075))
		if year < 2008:
			rad.position.y = L["psu"].end.y + 4
		for k in [-1, 1]:
			var a := cc + Vector2(k * r.size.x * 0.2, 0)
			var b := rad.get_center() + Vector2(k * rad.size.x * 0.3, rad.size.y * 0.4)
			var pts := PackedVector2Array()
			for i in 13:
				var u := i / 12.0
				var m := Vector2(a.x, (a.y + b.y) / 2.0)
				pts.append(a.lerp(m, u).lerp(m.lerp(b, u), u))
			draw_polyline(pts, Color("#0d0e10"), max(4.0, r.size.x * 0.08), true)
		Gfx.rr(self, rad, Color("#1c1d21"), 4, Color("#33363d"), 1, 3)
		for i in 3:
			Gfx.fan(self, rad.position + Vector2(rad.size.x * (i + 0.5) / 3.0, rad.size.y * 0.5), rad.size.y * 0.42, spin * 12.0 + i, Color("#121316"), Color("#2b2e35"), false, 7)
	PartIcon.draw_part(self, d, r, spin)


func _bezier(a: Vector2, b: Vector2, c1: Vector2, c2: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 17:
		var u := i / 16.0
		var p := a * pow(1 - u, 3) + c1 * 3 * pow(1 - u, 2) * u + c2 * 3 * (1 - u) * u * u + b * pow(u, 3)
		pts.append(p)
	return pts


func _cables(L: Dictionary) -> void:
	if pc["parts"]["psu"] == null:
		return
	var cab: Dictionary = pc.get("cables", {})
	var psu: Rect2 = L["psu"]
	var mb: Rect2 = L["mobo"]
	var old_top := year < 2008
	var start := Vector2(psu.end.x - psu.size.x * 0.15, psu.end.y if old_top else psu.position.y)
	var targets := {
		"atx": mb.position + mb.size * Vector2(0.97, 0.38),
		"cpu": mb.position + mb.size * Vector2(0.12, 0.04),
		"pcie": L["gpu"].position + Vector2(L["gpu"].size.x * 0.82, 2),
		"disk": L["storage"].position + Vector2(0, L["storage"].size.y * 0.5),
		"panel": mb.position + mb.size * Vector2(0.92, 0.97),
	}
	var need: Array = Game.cables_needed(pc)
	var sleeve := Color("#121214") if year >= 2008 else Color("#e0c040")
	for k in need:
		var to: Vector2 = targets[k]
		if cab.get(k, false):
			if year >= 2013 and k != "disk":
				# аккуратно: кабель выходит из отверстия кабель-менеджмента
				var inner: Rect2 = L["inner"]
				var gx: float = inner.position.x + inner.size.x * 0.7
				var gy: float = clamp(to.y, inner.position.y + inner.size.y * 0.12, inner.position.y + inner.size.y * 0.6)
				var g := Vector2(gx, gy)
				var pts2 := _bezier(g, to, g + Vector2(-20, 0), to + Vector2(18 if k in ["atx", "panel"] else 0, -20 if k in ["cpu", "pcie"] else 0))
				draw_polyline(pts2, sleeve, max(3.0, size.x * 0.01), true)
				draw_polyline(pts2, Color(1, 1, 1, 0.1), 1.0, true)
				Gfx.rr(self, Rect2(to - Vector2(5, 4), Vector2(10, 8)), Color("#222"), 2)
				continue
			var c1 := start + Vector2(0, 40 if old_top else -40)
			var c2 := to + Vector2(30, 0) if k in ["atx", "panel", "disk"] else to + Vector2(0, -30 if k == "cpu" else -25)
			var pts := _bezier(start, to, c1, c2)
			var w: float = 2.0 if k == "panel" else max(3.0, size.x * 0.009)
			if year < 2008 and k != "panel":
				# пучок разноцветных проводов
				for j in 3:
					var off := Vector2(0, (j - 1) * 2.0)
					var p2 := PackedVector2Array()
					for p in pts:
						p2.append(p + off)
					draw_polyline(p2, [Color("#e0c040"), Color("#d33"), Color("#111")][j], 1.6, true)
			else:
				draw_polyline(pts, sleeve, w, true)
				draw_polyline(pts, Color(1, 1, 1, 0.08), max(1.0, w * 0.3), true)
			Gfx.rr(self, Rect2(to - Vector2(5, 4), Vector2(10, 8)), Color("#222") if year >= 2008 else Color("#eee"), 2)
		else:
			var pulse := 7.0 + sin(t * 6.0) * 1.5
			Gfx.glow(self, to, pulse * 2.4, Color(1, 0.2, 0.2, 0.35))
			draw_circle(to, pulse, Color("#ef5350"))
			Gfx.text(self, to + Vector2(-pulse, 4.5), "!", 13, Color.WHITE, pulse * 2, HORIZONTAL_ALIGNMENT_CENTER, true)


func _dust(c: Rect2) -> void:
	var d := float(pc.get("dust", 0))
	if d <= 0:
		return
	# серая дымка + комочки пыли, больше внизу и у вентиляторов
	Gfx.vgrad(self, c, Color(0.62, 0.6, 0.55, d / 900.0), Color(0.62, 0.6, 0.55, d / 380.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1126
	for i in int(d * 1.5):
		var p := c.position + Vector2(rng.randf() * c.size.x, pow(rng.randf(), 0.6) * c.size.y)
		var rr := rng.randf_range(0.8, 2.4)
		draw_circle(p, rr, Color(0.78, 0.75, 0.68, 0.35))


func _dashed(r: Rect2, col: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ln := a.distance_to(b)
		var k := 0.0
		while k < ln:
			draw_line(a.lerp(b, k / ln), a.lerp(b, min(ln, k + 6) / ln), col, 1.5)
			k += 11


func slot_at(pos: Vector2) -> String:
	for s in ["cooler", "cpu", "ram", "gpu", "storage", "psu", "mobo"]:
		if regions.has(s) and regions[s].grow(4).has_point(pos):
			if s == "cpu" and pc["parts"]["cooler"] != null:
				continue
			if s in ["cpu", "ram", "gpu"] and pc["parts"]["mobo"] == null:
				continue
			return s
	return ""


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		mouse_slot = slot_at(e.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if mouse_slot != "" else Control.CURSOR_ARROW
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var s := slot_at(e.position)
		if s != "":
			part_clicked.emit(s)


func _can_drop_data(_pos: Vector2, data) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("kind", "") == "part":
		hover_slot = Data.part(data["id"])["slot"]
		return true
	return false


func _drop_data(_pos: Vector2, data) -> void:
	hover_slot = ""
	part_dropped.emit(Data.part(data["id"])["slot"], data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		hover_slot = ""
		mouse_slot = ""
