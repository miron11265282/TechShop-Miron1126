extends Control
const Gfx := preload("res://scripts/ui/Gfx.gd")
## Монитор на столе: показывает то, что реально происходит с ПК — POST, «Нет сигнала», синий экран,
## рабочий стол своей эпохи, вирусы и игры с настоящим FPS.

var pc: Dictionary = {}
var year := 1995
var booting := 0.0
var game_name := ""
var game_fps := 60.0
var t := 0.0
var scene_t := 0.0
var acc := 0.0
var bare := false      # только экран, без корпуса монитора (режим «сесть за компьютер»)
var no_shell := false  # explorer.exe завершён — нет панели задач и ярлыков


var C: Control  # экран (обрезает всё, что за его краями)
var G: Control  # блик на стекле


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(300, 240)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	C = Control.new()
	C.clip_contents = true
	C.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(C)
	C.draw.connect(_draw_screen)
	G = Control.new()
	G.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(G)
	G.draw.connect(_draw_glare)


func boot() -> void:
	booting = 1.4


func _process(delta: float) -> void:
	t += delta
	if booting > 0.0:
		booting -= delta
	if game_name != "":
		acc += delta
		var frame: float = 1.0 / max(1.0, game_fps)
		while acc >= frame:
			acc -= frame
			scene_t += frame
	var sr := _screen_rect()
	if C.position != sr.position or C.size != sr.size:
		C.position = sr.position
		C.size = sr.size
		G.position = sr.position
		G.size = sr.size
		queue_redraw()
	C.queue_redraw()
	if not bare:
		queue_redraw()
	G.visible = not bare


func mode() -> String:
	if pc.is_empty() or not pc.get("on", false):
		return "off"
	if booting > 0.0:
		return "post"
	var bp: Array = Game.boot_problems(pc)
	if not bp.is_empty():
		for p in bp:
			if p["kind"] in ["cable_atx", "cable_panel"] or (p["slot"] == "psu" and p["kind"] != "fit"):
				return "off"
		for p in bp:
			if p["slot"] == "gpu" or p["kind"] == "cable_pcie":
				return "nosignal"
		return "beep"
	if Game.temp(pc) > 100.0:
		return "off"
	var o: String = Game.os_state(pc)
	if o != "":
		if o.contains("BSOD"):
			return "bsod"
		if o.contains("вымогател"):
			return "ransom"
		return "text:" + o
	if game_name != "":
		return "game"
	return "desktop"


func _screen_rect() -> Rect2:
	if bare:
		return Rect2(Vector2.ZERO, size)
	var crt := year < 2004
	var ar := 4.0 / 3.0 if crt else 16.0 / 9.0
	var ml := 30.0 if crt else (16.0 if year < 2018 else 10.0)
	var mr := 52.0 if crt else ml + 4.0
	var top := 46.0 if crt else (16.0 if year < 2018 else 8.0)
	var bottom := 74.0 if crt else (60.0 if year < 2018 else 50.0)
	var w := size.x - ml - mr
	var h := size.y - top - bottom
	var sw: float = min(w, h * ar)
	var sh := sw / ar
	return Rect2(Vector2(ml + (w - sw) / 2.0, top + (h - sh)), Vector2(sw, sh))


func screen_tint() -> Color:
	## Каким светом экран освещает стену и стол
	var m := mode()
	match m:
		"off":
			return Color(0, 0, 0, 0)
		"bsod":
			return Color(0.15, 0.3, 1.0, 0.5)
		"ransom":
			return Color(1, 0.1, 0.1, 0.45)
		"game":
			return Color(0.5, 0.75, 1.0, 0.4)
		"desktop":
			var gen := int(Data.os_list.get(pc.get("os", ""), {}).get("gen", 1))
			if gen <= 3:
				return Color(0.1, 0.6, 0.6, 0.4)
			return Color(0.3, 0.55, 1.0, 0.42)
	return Color(0.8, 0.8, 0.8, 0.15)


func _draw() -> void:
	var s := _screen_rect()
	if bare:
		return
	var on: bool = pc.get("on", false)
	var crt := year < 2004
	if crt:
		# ===== ЭЛТ: объёмный корпус =====
		var body := Rect2(s.position - Vector2(22, 22), s.size + Vector2(44, 62))
		var dep := Vector2(36, -26)
		Gfx.glow(self, Vector2(body.get_center().x + 14, body.end.y + 22), body.size.x * 0.6, Color(0, 0, 0, 0.4))
		# подставка
		var base := Rect2(Vector2(body.get_center().x - body.size.x * 0.26, body.end.y - 2), Vector2(body.size.x * 0.52, 18))
		Gfx.rr(self, base, Color("#c4bca3"), 8, Color("#a39b82"), 1, 4)
		Gfx.vgrad(self, Rect2(base.position + Vector2(4, 2), Vector2(base.size.x - 8, 6)), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0))
		# задняя часть кинескопа (видно сверху и справа)
		var bk0 := body.position + Vector2(body.size.x * 0.08, 0)
		var bk1 := Vector2(body.end.x - body.size.x * 0.08, body.position.y)
		Gfx.quad(self, bk0, bk0 + dep + Vector2(body.size.x * 0.1, 0), bk1 + dep - Vector2(body.size.x * 0.06, 0), bk1, Color("#e6dfc9"), Color("#cfc7ae"), Color("#c6bea4"), Color("#ddd5bd"))
		var r0 := Vector2(body.end.x, body.position.y + body.size.y * 0.06)
		var r1 := Vector2(body.end.x, body.end.y - body.size.y * 0.1)
		Gfx.quad(self, r0, r0 + dep - Vector2(body.size.x * 0.06, -body.size.y * 0.06), r1 + dep * 0.6 - Vector2(0, 0), r1, Color("#cbc3a9"), Color("#b3ab91"), Color("#a9a187"), Color("#c1b99f"))
		# вентиляционные прорези сверху
		for i in 7:
			var u := 0.2 + i * 0.09
			var p0 := bk0.lerp(bk1, u) + dep * 0.25
			draw_line(p0, p0 + dep * 0.5, Color(0, 0, 0, 0.18), 2.0)
		# лицевая рамка
		Gfx.rr(self, body, Color("#ddd5bd"), 16, Color("#b6ae95"), 2, 10)
		Gfx.vgrad(self, Rect2(body.position + Vector2(8, 4), Vector2(body.size.x - 16, body.size.y * 0.25)), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0))
		Gfx.textured(self, body.grow(-3), "noise")
		# углубление вокруг стекла с фаской
		var rec := s.grow(12)
		Gfx.rr(self, rec, Color("#c9c1a8"), 14)
		Gfx.quad(self, rec.position, Vector2(rec.end.x, rec.position.y), Vector2(s.end.x, s.position.y), s.position, Color("#b2aa90"), Color("#b2aa90"), Color("#9e967c"), Color("#9e967c"))
		Gfx.quad(self, rec.position, s.position, Vector2(s.position.x, s.end.y), Vector2(rec.position.x, rec.end.y), Color("#b8b096"), Color("#a59d83"), Color("#a59d83"), Color("#b8b096"))
		Gfx.quad(self, Vector2(rec.position.x, rec.end.y), Vector2(s.position.x, s.end.y), s.end, rec.end, Color("#e8e1cc"), Color("#e8e1cc"), Color("#e8e1cc"), Color("#e8e1cc"))
		Gfx.quad(self, Vector2(rec.end.x, rec.position.y), rec.end, s.end, Vector2(s.end.x, s.position.y), Color("#e2dbc5"), Color("#e2dbc5"), Color("#d6cfb8"), Color("#d6cfb8"))
		draw_rect(s.grow(2), Color("#1d1c19"))
		# нижняя панель: логотип, кнопки, индикатор
		var by := s.end.y + 26
		Gfx.rr(self, Rect2(Vector2(s.position.x, by - 9), Vector2(70, 16)), Color("#cfc7ae"), 3, Color("#b2aa90"), 1)
		Gfx.text(self, Vector2(s.position.x + 6, by + 3), "miron1126", 10, Color("#7a735e"), -1, HORIZONTAL_ALIGNMENT_LEFT, true)
		for i in 4:
			Gfx.rr(self, Rect2(Vector2(s.end.x - 100 + i * 18, by - 4), Vector2(13, 8)), Color("#cfc7ae"), 3, Color("#a39b82"), 1)
		draw_circle(Vector2(s.end.x - 14, by), 6, Color("#cfc7ae"))
		draw_arc(Vector2(s.end.x - 14, by), 6, 0, TAU, 20, Color("#a39b82"), 1.0, true)
		draw_circle(Vector2(s.end.x - 30, by), 2.5, Color("#66ff66") if on else Color("#e0a030"))
		if on:
			Gfx.glow(self, Vector2(s.end.x - 30, by), 9, Color(0.4, 1, 0.4, 0.45))
	else:
		var modern := year >= 2018
		var glossy := year < 2013
		var bez := s.grow(10 if not modern else 5)
		bez.size.y += (14 if not modern else 10)
		var cx := bez.get_center().x
		Gfx.glow(self, Vector2(cx, size.y - 4), bez.size.x * 0.4, Color(0, 0, 0, 0.45))
		# подставка
		if modern:
			# стойка и ножки-«V»
			var nk := Rect2(Vector2(cx - 10, bez.end.y - 10), Vector2(20, size.y - bez.end.y))
			Gfx.vgrad(self, nk, Color("#3a3d44"), Color("#1b1c20"))
			for k in [-1, 1]:
				var p0 := Vector2(cx, size.y - 8)
				var p1 := Vector2(cx + k * bez.size.x * 0.26, size.y - 2)
				draw_line(p0, p1, Color("#2c2f35"), 6.0, true)
				draw_line(p0 - Vector2(0, 1), p1 - Vector2(0, 1), Color(1, 1, 1, 0.12), 1.0, true)
			if on:
				var rc := Color.from_hsv(fmod(t * 0.08, 1.0), 0.8, 1.0)
				Gfx.glow(self, Vector2(cx, bez.get_center().y), bez.size.x * 0.75, Color(rc, 0.12))
		else:
			var nk2 := Rect2(Vector2(cx - 14, bez.end.y - 4), Vector2(28, max(10.0, size.y - bez.end.y - 8)))
			Gfx.vgrad(self, nk2, Color("#3a3d44") if not glossy else Color("#c8ccd1"), Color("#16171a") if not glossy else Color("#8c9198"))
			var bs := Rect2(Vector2(cx - bez.size.x * 0.2, size.y - 12), Vector2(bez.size.x * 0.4, 10))
			Gfx.rr(self, bs, Color("#1d1f23") if not glossy else Color("#202226"), 5, Color("#3a3d44"), 1, 5)
			Gfx.vgrad(self, Rect2(bs.position + Vector2(6, 1), Vector2(bs.size.x - 12, 3)), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0))
		# толщина корпуса справа
		Gfx.quad(self, Vector2(bez.end.x - 2, bez.position.y + 4), Vector2(bez.end.x + 5, bez.position.y + 9), Vector2(bez.end.x + 5, bez.end.y - 3), Vector2(bez.end.x - 2, bez.end.y - 6), Color("#1d1f23"), Color("#0b0c0e"))
		# рамка
		var bcol := Color("#0e0f12")
		Gfx.rr(self, bez, bcol, 10 if not modern else 6, Color("#2e3137"), 1, 12)
		if glossy:
			Gfx.vgrad(self, Rect2(bez.position + Vector2(3, 2), Vector2(bez.size.x - 6, bez.size.y * 0.45)), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.0))
			Gfx.rr(self, Rect2(Vector2(bez.position.x + 2, bez.end.y - 15), Vector2(bez.size.x - 4, 13)), Color("#b9bec5"), 4)
			Gfx.textured(self, Rect2(Vector2(bez.position.x + 4, bez.end.y - 14), Vector2(bez.size.x - 8, 11)), "brushed")
			Gfx.text(self, Vector2(bez.position.x, bez.end.y - 4), "miron1126", 9, Color("#4a4e55"), bez.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		else:
			Gfx.text(self, Vector2(bez.position.x, bez.end.y - 3), "miron1126", 8, Color("#5b5f67"), bez.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
		draw_rect(s.grow(1), Color("#050607"))
		var led := Vector2(bez.end.x - 12, bez.end.y - 7)
		draw_circle(led, 2.2, Color("#4fc3f7") if on else Color("#e0a030"))
		if on:
			Gfx.glow(self, led, 8, Color(0.3, 0.8, 1, 0.5))


func _draw_glare() -> void:
	var s := Rect2(Vector2.ZERO, G.size)
	var crt := year < 2004
	var on: bool = pc.get("on", false)
	var a := 0.08 if crt else 0.045
	G.draw_colored_polygon(PackedVector2Array([Vector2(s.size.x * 0.05, 0), Vector2(s.size.x * 0.42, 0), Vector2(s.size.x * 0.14, s.size.y), Vector2(0, s.size.y), Vector2(0, s.size.y * 0.3)]), Color(1, 1, 1, a))
	if not on:
		# выключенный экран отражает комнату
		Gfx.vgrad(G, s, Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.0))
	if crt:
		# выпуклое стекло: виньетка и скруглённые углы
		for i in 8:
			G.draw_rect(s.grow(-i * 2.0), Color(0, 0, 0, 0.08), false, 2.0)
		var rr := s.size.y * 0.06
		var fill := Color("#1d1c19")
		for k in 4:
			var corner: Vector2 = [Vector2(0, 0), Vector2(s.size.x, 0), s.size, Vector2(0, s.size.y)][k]
			var cen: Vector2 = corner + Vector2(rr if k in [0, 3] else -rr, rr if k in [0, 1] else -rr)
			var pts := PackedVector2Array([corner])
			var a0 := PI + k * PI / 2.0
			for j in 9:
				var ang := a0 + PI / 2.0 * j / 8.0
				pts.append(cen + Vector2(cos(ang), sin(ang)) * rr)
			G.draw_colored_polygon(pts, fill)
	elif year < 2013 and not on:
		Gfx.vgrad(G, Rect2(Vector2.ZERO, Vector2(s.size.x, s.size.y * 0.5)), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0))


func _draw_screen() -> void:
	var s := Rect2(Vector2.ZERO, C.size)
	var crt := year < 2004
	var f := get_theme_default_font()
	var m := mode()
	C.draw_rect(s, Color("#050607"))
	match m:
		"off":
			C.draw_rect(s, Color("#08090b"))
			C.draw_line(s.position + Vector2(s.size.x * 0.1, s.size.y * 0.15), s.position + Vector2(s.size.x * 0.35, s.size.y * 0.05), Color(1, 1, 1, 0.06), 10)
		"post":
			var lines := ["Award Modular BIOS v4.51PG" if year < 2005 else "American Megatrends", "CPU: " + Game.pdata(pc, "cpu").get("name", "?"),
				"Memory Test: %s OK" % Data.gb_text(float(Game.pdata(pc, "ram").get("gb", 0))), "Detecting drives…", "Press DEL to enter SETUP"]
			for i in lines.size():
				C.draw_string(f, s.position + Vector2(10, 22 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 20, 13, Color("#c0c0c0"))
		"nosignal":
			C.draw_rect(Rect2(s.get_center() - Vector2(90, 22), Vector2(180, 44)), Color("#1d3a8a"))
			C.draw_string(f, s.get_center() + Vector2(-70, 6), "Нет сигнала", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
		"beep":
			C.draw_string(f, s.get_center() + Vector2(-80, 0), "* бип… бип-бип *", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#888"))
		"bsod":
			_bsod(s, f)
		"ransom":
			C.draw_rect(s, Color("#7a0000"))
			C.draw_string(f, s.position + Vector2(14, 34), "ВАШИ ФАЙЛЫ ЗАШИФРОВАНЫ!", HORIZONTAL_ALIGNMENT_LEFT, s.size.x, 18, Color.WHITE)
			C.draw_string(f, s.position + Vector2(14, 60), "Заплатите, или файлы будут удалены", HORIZONTAL_ALIGNMENT_LEFT, s.size.x, 13, Color("#ffcdd2"))
			C.draw_string(f, s.position + Vector2(14, 84), "Осталось: %02d:%02d:%02d" % [23, 59 - int(t / 60) % 60, 59 - int(t) % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ffeb3b"))
		"desktop":
			_desktop(s, f)
		"game":
			_game(s, f)
		_:
			C.draw_string(f, s.position + Vector2(10, 24), m.substr(5), HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 20, 13, Color("#c0c0c0"))
			if int(t * 2) % 2 == 0:
				C.draw_string(f, s.position + Vector2(10, 46), "_", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c0c0c0"))
	if crt and m != "off":
		for i in int(s.size.y / 3):
			C.draw_line(s.position + Vector2(0, i * 3), s.position + Vector2(s.size.x, i * 3), Color(0, 0, 0, 0.12))


func _bsod(s: Rect2, f: Font) -> void:
	var gen := int(Data.os_list.get(pc.get("os", ""), {}).get("gen", 4))
	if gen >= 8:
		C.draw_rect(s, Color("#0a64c8") if gen == 8 else Color("#000000"))
		C.draw_string(f, s.position + Vector2(18, 56), ":(", HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color.WHITE)
		C.draw_string(f, s.position + Vector2(18, 96), "На вашем ПК возникла проблема.", HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 30, 14, Color.WHITE)
		C.draw_string(f, s.position + Vector2(18, 118), "Код остановки: CRITICAL_PROCESS_DIED", HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 30, 12, Color.WHITE)
		var q := Rect2(s.position + Vector2(18, s.size.y - 64), Vector2(46, 46))
		C.draw_rect(q, Color.WHITE)
		var rng := RandomNumberGenerator.new()
		rng.seed = 404
		for i in 7:
			for j in 7:
				if rng.randf() < 0.5:
					C.draw_rect(Rect2(q.position + Vector2(3 + i * 6, 3 + j * 6), Vector2(6, 6)), Color.BLACK)
	else:
		C.draw_rect(s, Color("#0000aa"))
		C.draw_string(f, s.position + Vector2(12, 30), "Windows", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#0000aa"))
		C.draw_rect(Rect2(s.position + Vector2(10, 16), Vector2(80, 18)), Color("#aaaaaa"))
		C.draw_string(f, s.position + Vector2(14, 30), "Windows", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#0000aa"))
		C.draw_string(f, s.position + Vector2(12, 60), "A fatal exception 0E has occurred at 0028:C0011E36.", HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 20, 12, Color.WHITE)
		C.draw_string(f, s.position + Vector2(12, 80), "*  Press any key to continue _", HORIZONTAL_ALIGNMENT_LEFT, s.size.x - 20, 12, Color.WHITE)


func _desktop(s: Rect2, f: Font) -> void:
	var os_id: String = pc.get("os", "")
	var o: Dictionary = Data.os_list.get(os_id, {})
	var gen := int(o.get("gen", 1))
	var vs: Array = Game.active_viruses(pc)
	var flip: bool = vs.has("flip")
	if flip:
		C.draw_set_transform(s.get_center() * 2.0, PI, Vector2.ONE)
	if os_id == "dos":
		C.draw_rect(s, Color.BLACK)
		C.draw_string(f, s.position + Vector2(8, 20), "C:\\>" + ("_" if int(t * 2) % 2 == 0 else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c0c0c0"))
		C.draw_set_transform(Vector2.ZERO)
		return
	var tb_h: float = max(16.0, s.size.y * 0.08)
	if o.get("linux", false):
		var a := Color("#77216f") if os_id == "ubuntu" else Color("#2f4a2a")
		var b := Color("#e95420") if os_id == "ubuntu" else Color("#8fbf5b")
		_grad(s, a, b)
		C.draw_rect(Rect2(s.position, Vector2(s.size.x, tb_h * 0.8)), Color(0, 0, 0, 0.8))
		C.draw_rect(Rect2(s.position + Vector2(0, tb_h * 0.8), Vector2(tb_h * 1.4, s.size.y - tb_h * 0.8)), Color(0, 0, 0, 0.55))
	elif gen <= 3:
		C.draw_rect(s, Color("#008080"))
		C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - tb_h), Vector2(s.size.x, tb_h)), Color("#c0c0c0"))
		C.draw_rect(Rect2(Vector2(s.position.x + 3, s.end.y - tb_h + 3), Vector2(52, tb_h - 6)), Color("#d4d0c8"))
		C.draw_string(f, Vector2(s.position.x + 8, s.end.y - 5), "Пуск", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.BLACK)
	elif gen == 4:
		_grad(s, Color("#3b78d8"), Color("#9fd0ff"))
		for i in 3:
			C.draw_arc(Vector2(s.position.x + s.size.x * 0.5, s.end.y + s.size.y * (0.4 + i * 0.12)), s.size.x * (0.7 + i * 0.1), PI * 1.15, PI * 1.85, 32, Color(1, 1, 1, 0.18), 6)
		C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - tb_h), Vector2(s.size.x, tb_h)), Color("#245edb"))
		C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - tb_h), Vector2(60, tb_h)), Color("#3c9a3c"))
		C.draw_string(f, Vector2(s.position.x + 8, s.end.y - 5), "пуск", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	elif gen <= 6:
		_grad(s, Color("#0b2a4a"), Color("#2a8fb0"))
		for i in 4:
			C.draw_line(s.position + Vector2(0, s.size.y * (0.3 + i * 0.1)), s.position + Vector2(s.size.x, s.size.y * (0.1 + i * 0.12)), Color(1, 1, 1, 0.08), 8)
		C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - tb_h), Vector2(s.size.x, tb_h)), Color(0, 0, 0, 0.6))
		C.draw_circle(Vector2(s.position.x + tb_h * 0.7, s.end.y - tb_h / 2), tb_h * 0.42, Color("#3aa0e0"))
	elif gen == 7:
		C.draw_rect(s, Color("#3a1c6e"))
		var cols := [Color("#00a300"), Color("#2d89ef"), Color("#ee1111"), Color("#ffc40d"), Color("#9f00a7"), Color("#00aba9")]
		for i in 6:
			C.draw_rect(Rect2(s.position + Vector2(20 + (i % 3) * (s.size.x * 0.22), 40 + (i / 3) * (s.size.y * 0.3)), Vector2(s.size.x * 0.2, s.size.y * 0.26)), cols[i])
		C.draw_string(f, s.position + Vector2(20, 26), "Пуск", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	else:
		if gen == 8:
			_grad(s, Color("#00163a"), Color("#0a4fa0"))
			C.draw_colored_polygon(PackedVector2Array([s.get_center() + Vector2(-20, -60), s.get_center() + Vector2(40, -50), s.get_center() + Vector2(30, 40), s.get_center() + Vector2(-30, 30)]), Color(0.4, 0.7, 1, 0.35))
			C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - tb_h), Vector2(s.size.x, tb_h)), Color(0.05, 0.05, 0.08, 0.95))
			C.draw_rect(Rect2(Vector2(s.position.x + 6, s.end.y - tb_h + 4), Vector2(tb_h - 8, tb_h - 8)), Color("#4cc2ff"))
		else:
			_grad(s, Color("#8fb8ef"), Color("#2c5cc7"))
			ellipse(s.get_center() + Vector2(0, 10), Vector2(s.size.x * 0.25, s.size.y * 0.25), Color(1, 1, 1, 0.25))
			C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - tb_h), Vector2(s.size.x, tb_h)), Color(0.95, 0.96, 1.0, 0.85))
			for i in 5:
				C.draw_rect(Rect2(Vector2(s.get_center().x - tb_h * 2.5 + i * tb_h, s.end.y - tb_h + 4), Vector2(tb_h - 8, tb_h - 8)), Color("#2c7be5") if i == 0 else Color("#888"))
	if no_shell:
		C.draw_rect(s, Color("#008080") if gen <= 3 else (Color("#3b78d8") if gen == 4 else Color("#06101e")))
	# ярлыки игр
	var icons := ["Мой ПК"]
	for g in pc.get("games", []):
		icons.append(Data.games[g]["name"])
	if bare:
		icons = []
	var isz: float = clamp(s.size.y * 0.085, 14.0, 34.0)
	var per_col: int = max(1, int((s.size.y - tb_h - 10) / (isz + 16)))
	for i in min(icons.size(), per_col * 2):
		var p := s.position + Vector2(12 + (i / per_col) * (isz + 46), 8 + (i % per_col) * (isz + 16))
		if o.get("linux", false):
			p.x += tb_h * 1.6
		var ir := Rect2(p + Vector2(16, 0), Vector2(isz, isz))
		if i == 0:
			# «Мой компьютер»
			Gfx.rr(C, Rect2(ir.position + Vector2(ir.size.x * 0.1, ir.size.y * 0.05), Vector2(ir.size.x * 0.8, ir.size.y * 0.6)), Color("#d9d1b8") if gen <= 4 else Color("#2b2e35"), 2)
			Gfx.vgrad(C, Rect2(ir.position + Vector2(ir.size.x * 0.18, ir.size.y * 0.12), Vector2(ir.size.x * 0.64, ir.size.y * 0.44)), Color("#4aa3ff"), Color("#1e5fbf"))
			C.draw_rect(Rect2(ir.position + Vector2(ir.size.x * 0.3, ir.size.y * 0.72), Vector2(ir.size.x * 0.4, ir.size.y * 0.12)), Color("#cfc8b0") if gen <= 4 else Color("#444"))
		else:
			var hue := fmod(absi(String(icons[i]).hash()) * 0.0001, 1.0)
			var c1 := Color.from_hsv(hue, 0.65, 0.95)
			Gfx.rr(C, ir, c1, isz * (0.12 if gen <= 4 else 0.22), c1.darkened(0.4), 1)
			Gfx.vgrad(C, Rect2(ir.position + Vector2(2, 2), Vector2(ir.size.x - 4, ir.size.y * 0.45)), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0))
			C.draw_string(Gfx.FONT_BOLD, ir.position + Vector2(0, ir.size.y * 0.7), String(icons[i]).left(1).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, ir.size.x, int(isz * 0.55), Color.WHITE)
		var lw := isz + 32
		C.draw_string(Gfx.FONT, p + Vector2(0, isz + 11), String(icons[i]), HORIZONTAL_ALIGNMENT_CENTER, lw, int(clamp(isz * 0.32, 8, 11)), Color(0, 0, 0, 0.6))
		C.draw_string(Gfx.FONT, p + Vector2(-1, isz + 10), String(icons[i]), HORIZONTAL_ALIGNMENT_CENTER, lw, int(clamp(isz * 0.32, 8, 11)), Color.WHITE)
	# вирусы
	if vs.has("adware"):
		for i in 3:
			var r := Rect2(s.position + Vector2(s.size.x * (0.3 + i * 0.12), s.size.y * (0.2 + i * 0.13)), Vector2(s.size.x * 0.32, s.size.y * 0.22))
			C.draw_rect(r, Color("#fff176"))
			C.draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), Color("#d32f2f"))
			C.draw_string(f, r.position + Vector2(6, 30), "ВЫ ВЫИГРАЛИ iPhone!!!", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 8, 10, Color("#b71c1c"))
	if vs.has("kitty"):
		for i in 6:
			var c := s.position + Vector2(fmod(t * 40 + i * 70, s.size.x), s.size.y * (0.2 + 0.1 * i) + sin(t * 3 + i) * 8)
			C.draw_circle(c, 8, Color("#9e9e9e"))
			C.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -3), c + Vector2(-6, -12), c + Vector2(-1, -6)]), Color("#9e9e9e"))
			C.draw_colored_polygon(PackedVector2Array([c + Vector2(8, -3), c + Vector2(6, -12), c + Vector2(1, -6)]), Color("#9e9e9e"))
	if vs.has("loud"):
		C.draw_string(f, s.position + Vector2(s.size.x * 0.6, s.size.y * 0.3 + sin(t * 6) * 10), "ТУЦ-ТУЦ!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffeb3b"))
	if vs.has("cursor"):
		var cp := s.position + Vector2(fmod(t * 300, s.size.x), fmod(t * 170, s.size.y))
		C.draw_colored_polygon(PackedVector2Array([cp, cp + Vector2(0, 14), cp + Vector2(9, 10)]), Color.WHITE)
	C.draw_set_transform(Vector2.ZERO)
	if not pc.get("drivers", true):
		C.draw_rect(s, Color(0, 0, 0, 0.25))
		C.draw_string(f, s.position + Vector2(s.size.x - 170, 16), "640×480 · 16 цветов", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffeb3b"))
	if not pc.get("activated", true) and not o.get("linux", false):
		C.draw_string(f, s.end - Vector2(190, tb_h + 22), "Активация Windows", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.55))
		C.draw_string(f, s.end - Vector2(190, tb_h + 8), "Перейдите в параметры…", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.45))


const GENRE := {
	"fps": ["doom2", "quake", "halflife", "ut99", "maxpayne", "cs16", "hl2", "farcry", "doom3", "stalker", "crysis", "cod4", "l4d2", "bf3", "csgo", "pubg", "fortnite", "apex", "valorant", "cs2", "stalker2"],
	"top": ["warcraft2", "diablo", "redalert", "fallout", "starcraft", "sims", "diablo2", "warcraft3", "dota2", "stardew", "amongus"],
	"race": ["nfs4", "nfsmw"],
	"city": ["gta3", "vicecity", "gtasa", "gta4", "gta5", "cyberpunk"],
	"blocks": ["minecraft", "roblox"],
	"side": ["terraria", "hollowknight"],
	"neon": ["techverse", "flashlab"],
}


func _genre(g: String) -> String:
	for k in GENRE:
		if GENRE[k].has(g):
			return k
	return "open"


func _game(s: Rect2, f: Font) -> void:
	var gd: Dictionary = Data.games.get(game_name, {})
	var y := int(gd.get("year", 2000))
	var px := 6.0 if y < 1997 else (3.0 if y < 2002 else 1.0)  # старые игры — крупные пиксели
	var T := scene_t
	var h := absi(game_name.hash())
	match _genre(game_name):
		"fps":
			# коридор, враг, оружие, прицел
			var wall := Color.from_hsv(fmod(h * 0.013, 1.0), 0.35, 0.45)
			_grad(Rect2(s.position, Vector2(s.size.x, s.size.y * 0.5)), Color("#20252d") if y < 2004 else Color("#5d7fa8"), Color("#3a4250") if y < 2004 else Color("#c9d8e8"))
			C.draw_rect(Rect2(s.position + Vector2(0, s.size.y * 0.5), Vector2(s.size.x, s.size.y * 0.5)), wall.darkened(0.5))
			var vp := s.get_center() + Vector2(sin(T * 0.7) * s.size.x * 0.04, 0)
			for k in [-1, 1]:
				var x0 := s.position.x if k < 0 else s.end.x
				C.draw_colored_polygon(PackedVector2Array([Vector2(x0, s.position.y), vp + Vector2(k * s.size.x * 0.12, -s.size.y * 0.16), vp + Vector2(k * s.size.x * 0.12, s.size.y * 0.16), Vector2(x0, s.end.y)]), wall if k < 0 else wall.darkened(0.15))
				for j in 4:
					var u := fmod(j / 4.0 + T * 0.3, 1.0)
					var xx: float = lerp(vp.x + k * s.size.x * 0.12, x0, u * u)
					var hh: float = lerp(s.size.y * 0.16, s.size.y * 0.5, u * u)
					C.draw_line(_snap(Vector2(xx, vp.y - hh), px), _snap(Vector2(xx, vp.y + hh), px), wall.darkened(0.35), max(1.0, u * 4))
			C.draw_rect(Rect2(vp - Vector2(s.size.x * 0.12, s.size.y * 0.16), Vector2(s.size.x * 0.24, s.size.y * 0.32)), wall.darkened(0.6))
			# враг
			var ex := vp.x + sin(T * 1.6) * s.size.x * 0.08
			var es := s.size.y * (0.09 + 0.02 * sin(T * 3))
			C.draw_rect(_snapr(Rect2(Vector2(ex - es * 0.35, vp.y - es * 0.4), Vector2(es * 0.7, es * 1.2)), px), Color("#8d2a2a") if y < 2004 else Color("#4b5b3a"))
			C.draw_circle(Vector2(ex, vp.y - es * 0.6), es * 0.3, Color("#c98a6a"))
			# оружие
			var bob := sin(T * 6.0) * 4.0
			var gun := Rect2(Vector2(s.get_center().x + s.size.x * 0.06, s.end.y - s.size.y * 0.3 + bob), Vector2(s.size.x * 0.16, s.size.y * 0.34))
			C.draw_rect(_snapr(gun, px), Color("#2b2d31"))
			C.draw_rect(_snapr(Rect2(gun.position + Vector2(gun.size.x * 0.3, -gun.size.y * 0.25), Vector2(gun.size.x * 0.25, gun.size.y * 0.4)), px), Color("#3c3f45"))
			if fmod(T, 0.9) < 0.08:
				C.draw_circle(gun.position + Vector2(gun.size.x * 0.42, -gun.size.y * 0.28), s.size.y * 0.05, Color("#ffd54f"))
			var cc := s.get_center()
			C.draw_line(cc - Vector2(10, 0), cc - Vector2(3, 0), Color("#7CFC00"), 2)
			C.draw_line(cc + Vector2(3, 0), cc + Vector2(10, 0), Color("#7CFC00"), 2)
			C.draw_line(cc - Vector2(0, 10), cc - Vector2(0, 3), Color("#7CFC00"), 2)
			C.draw_line(cc + Vector2(0, 3), cc + Vector2(0, 10), Color("#7CFC00"), 2)
			C.draw_rect(Rect2(s.position + Vector2(10, s.size.y - 30), Vector2(90, 20)), Color(0, 0, 0, 0.5))
			C.draw_string(f, s.position + Vector2(16, s.size.y - 15), "HP 100   AMMO 30", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffeb3b"))
		"top":
			# вид сверху: трава, дорожки, юниты, здания
			var grass := Color("#3f7d3a") if game_name != "amongus" else Color("#5a6470")
			C.draw_rect(s, grass)
			var tile := s.size.x / 12.0
			var rng := RandomNumberGenerator.new()
			rng.seed = h
			for i in 12:
				for j in 8:
					if rng.randf() < 0.18:
						C.draw_rect(Rect2(s.position + Vector2(i * tile, j * tile), Vector2(tile, tile)), grass.darkened(0.12))
			for i in 4:
				var bp := s.position + Vector2(rng.randf() * s.size.x * 0.8, rng.randf() * s.size.y * 0.7)
				C.draw_rect(Rect2(bp, Vector2(tile * 1.6, tile * 1.2)), Color("#8d6e63"))
				C.draw_colored_polygon(PackedVector2Array([bp, bp + Vector2(tile * 0.8, -tile * 0.6), bp + Vector2(tile * 1.6, 0)]), Color("#b23b3b"))
			for i in 7:
				var ang := T * 0.6 + i * 0.9
				var up := s.get_center() + Vector2(cos(ang) * s.size.x * 0.3, sin(ang * 1.3) * s.size.y * 0.3)
				C.draw_circle(_snap(up, px), tile * 0.22, Color("#3d6fd6") if i % 2 == 0 else Color("#d64545"))
			# рамка выделения
			var sel := Rect2(s.get_center() - Vector2(tile * 1.5, tile), Vector2(tile * 3, tile * 2))
			C.draw_rect(sel, Color("#7CFC00"), false, 1.5)
			C.draw_rect(Rect2(Vector2(s.position.x, s.end.y - s.size.y * 0.18), Vector2(s.size.x, s.size.y * 0.18)), Color(0.1, 0.08, 0.06, 0.9))
			C.draw_rect(Rect2(Vector2(s.position.x + 6, s.end.y - s.size.y * 0.16), Vector2(s.size.y * 0.14, s.size.y * 0.14)), Color("#2e5d2a"))
		"race":
			_grad(Rect2(s.position, Vector2(s.size.x, s.size.y * 0.5)), Color("#ff9a5a"), Color("#ffd27a"))
			C.draw_rect(Rect2(s.position + Vector2(0, s.size.y * 0.5), Vector2(s.size.x, s.size.y * 0.5)), Color("#2e4d2a"))
			for i in 8:
				var bx := s.position.x + fmod(i * s.size.x * 0.15 - T * 6.0, s.size.x + 40)
				C.draw_rect(Rect2(Vector2(bx, s.position.y + s.size.y * 0.5 - 20 - (i * 13) % 30), Vector2(26, 20 + (i * 13) % 30)), Color("#3a2b40"))
			var c := Vector2(s.get_center().x + sin(T * 0.8) * 30, s.position.y + s.size.y * 0.5)
			C.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(4, 0), Vector2(s.end.x - s.size.x * 0.05, s.end.y), Vector2(s.position.x + s.size.x * 0.05, s.end.y)]), Color("#38383d"))
			for i in 10:
				var u := fmod(T * 1.4 + i / 10.0, 1.0)
				var py := c.y + u * u * s.size.y * 0.5
				var w := 2.0 + u * 14.0
				C.draw_rect(_snapr(Rect2(Vector2(c.x + (s.get_center().x - c.x) * u - w / 2, py), Vector2(w, 3 + u * 16)), px), Color("#f5f5f5"))
			# машина
			var car := Rect2(Vector2(s.get_center().x - s.size.x * 0.12, s.end.y - s.size.y * 0.26), Vector2(s.size.x * 0.24, s.size.y * 0.16))
			C.draw_rect(_snapr(car, px), Color("#d32f2f"))
			C.draw_rect(_snapr(Rect2(car.position + Vector2(car.size.x * 0.18, -car.size.y * 0.4), Vector2(car.size.x * 0.64, car.size.y * 0.5)), px), Color("#b71c1c"))
			C.draw_rect(Rect2(car.position + Vector2(car.size.x * 0.06, car.size.y * 0.3), Vector2(car.size.x * 0.16, car.size.y * 0.22)), Color("#ffeb3b"))
			C.draw_rect(Rect2(car.position + Vector2(car.size.x * 0.78, car.size.y * 0.3), Vector2(car.size.x * 0.16, car.size.y * 0.22)), Color("#ffeb3b"))
			C.draw_string(f, s.position + Vector2(s.size.x - 120, s.size.y - 14), "%d км/ч" % int(180 + sin(T) * 40), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		"city":
			var night := game_name == "cyberpunk" or game_name == "vicecity"
			_grad(Rect2(s.position, Vector2(s.size.x, s.size.y * 0.55)), Color("#120a2a") if night else Color("#5aa0e0"), Color("#ff3d8b") if night else Color("#cde6ff"))
			var rng := RandomNumberGenerator.new()
			rng.seed = h
			for i in 14:
				var bw := s.size.x / 10.0
				var bx := s.position.x + fmod(i * bw * 0.9 - T * 10.0, s.size.x + bw) - bw * 0.5
				var bh := s.size.y * rng.randf_range(0.2, 0.5)
				var bcol := Color("#1b1430") if night else Color("#7d8a99").darkened(rng.randf() * 0.3)
				C.draw_rect(Rect2(Vector2(bx, s.position.y + s.size.y * 0.55 - bh), Vector2(bw * 0.85, bh)), bcol)
				for wy in int(bh / 12):
					if (wy + i) % 3 != 0:
						C.draw_rect(Rect2(Vector2(bx + 4, s.position.y + s.size.y * 0.55 - bh + 6 + wy * 12), Vector2(bw * 0.85 - 8, 4)), Color("#ffd27a", 0.7) if night else Color("#bcd7f0"))
			C.draw_rect(Rect2(s.position + Vector2(0, s.size.y * 0.55), Vector2(s.size.x, s.size.y * 0.45)), Color("#2b2b30"))
			for i in 8:
				var lx := s.position.x + fmod(i * s.size.x / 6.0 - T * 120.0, s.size.x + 60)
				C.draw_rect(Rect2(Vector2(lx, s.position.y + s.size.y * 0.76), Vector2(36, 5)), Color("#f5f5f5"))
			var car := Rect2(Vector2(s.position.x + s.size.x * 0.35, s.position.y + s.size.y * 0.66), Vector2(s.size.x * 0.22, s.size.y * 0.1))
			C.draw_rect(_snapr(car, px), Color("#ffca28") if not night else Color("#00e5ff"))
			C.draw_rect(_snapr(Rect2(car.position + Vector2(car.size.x * 0.2, -car.size.y * 0.6), Vector2(car.size.x * 0.55, car.size.y * 0.6)), px), Color("#263238"))
			C.draw_circle(car.position + Vector2(car.size.x * 0.2, car.size.y), car.size.y * 0.35, Color("#111"))
			C.draw_circle(car.position + Vector2(car.size.x * 0.8, car.size.y), car.size.y * 0.35, Color("#111"))
			# мини-карта
			C.draw_circle(s.position + Vector2(40, s.size.y - 40), 30, Color(0, 0, 0, 0.55))
			C.draw_arc(s.position + Vector2(40, s.size.y - 40), 30, 0, TAU, 24, Color.WHITE, 2)
			C.draw_circle(s.position + Vector2(40, s.size.y - 40), 4, Color("#ff5252"))
		"blocks":
			_grad(Rect2(s.position, Vector2(s.size.x, s.size.y * 0.55)), Color("#79b8ff"), Color("#cde6ff"))
			var bs := s.size.x / 16.0
			var off := fmod(T * 20.0, bs)
			for i in 18:
				var hh := 3 + int(abs(sin((i + floor(T * 20.0 / bs)) * 0.7)) * 3)
				for j in hh:
					var bx := s.position.x + i * bs - off
					var by := s.end.y - (j + 1) * bs
					var col := Color("#5d9e3a") if j == hh - 1 else (Color("#8b5a2b") if j > hh - 4 else Color("#7d7d7d"))
					C.draw_rect(Rect2(Vector2(bx, by), Vector2(bs - 1, bs - 1)), col)
			C.draw_rect(Rect2(s.position + Vector2(s.size.x * 0.7, s.size.y * 0.1), Vector2(bs * 1.4, bs * 1.4)), Color("#fff59d"))
			C.draw_rect(Rect2(s.get_center() - Vector2(bs * 0.4, bs * 2.5), Vector2(bs * 0.8, bs * 2)), Color("#3f51b5"))
			C.draw_rect(Rect2(s.get_center() - Vector2(bs * 0.4, bs * 3.3), Vector2(bs * 0.8, bs * 0.8)), Color("#c98a6a"))
			for i in 9:
				C.draw_rect(Rect2(Vector2(s.get_center().x - bs * 4.5 + i * bs, s.end.y - bs * 0.9), Vector2(bs * 0.9, bs * 0.8)), Color(0, 0, 0, 0.45))
		"side":
			var dark := game_name == "hollowknight"
			_grad(s, Color("#0c1424") if dark else Color("#6fb4ff"), Color("#1e2c48") if dark else Color("#d6ecff"))
			for k in 3:
				var par := 0.3 + k * 0.3
				for i in 8:
					var mx := s.position.x + fmod(i * s.size.x * 0.2 - T * 30.0 * par, s.size.x + 120) - 60
					var mh := s.size.y * (0.15 + 0.1 * k) * (1.0 + 0.3 * sin(i * 1.7))
					C.draw_colored_polygon(PackedVector2Array([Vector2(mx - 60, s.end.y), Vector2(mx, s.end.y - mh), Vector2(mx + 60, s.end.y)]), (Color("#1b2742") if dark else Color("#4f7b3a")).darkened(0.25 - k * 0.1))
			var ground := s.end.y - s.size.y * 0.15
			C.draw_rect(Rect2(Vector2(s.position.x, ground), Vector2(s.size.x, s.size.y * 0.15)), Color("#2b3550") if dark else Color("#6d4c2a"))
			var jump: float = abs(sin(T * 2.5)) * s.size.y * 0.2
			var hero := Vector2(s.position.x + s.size.x * 0.35, ground - jump)
			C.draw_rect(_snapr(Rect2(hero - Vector2(8, 26), Vector2(16, 26)), px), Color("#eceff1") if dark else Color("#1e88e5"))
			C.draw_circle(hero - Vector2(0, 32), 9, Color("#f5f5f5") if dark else Color("#f2c9a0"))
		"neon":
			_grad(s, Color("#0a0820"), Color("#1d0a3a"))
			for i in 12:
				var yy := s.position.y + s.size.y * 0.55 + i * i * 2.0 + fmod(T * 40.0, 8)
				C.draw_line(Vector2(s.position.x, yy), Vector2(s.end.x, yy), Color(1, 0.3, 0.9, 0.35), 1.0)
			for i in 9:
				var xx: float = s.get_center().x + (i - 4) * s.size.x * 0.14
				C.draw_line(Vector2(s.get_center().x + (i - 4) * 8, s.position.y + s.size.y * 0.55), Vector2(xx, s.end.y), Color(1, 0.3, 0.9, 0.35), 1.0)
			C.draw_circle(s.get_center() - Vector2(0, s.size.y * 0.12), s.size.y * 0.16, Color("#ff8a1f"))
			for i in 4:
				C.draw_rect(Rect2(Vector2(s.position.x, s.get_center().y - s.size.y * 0.12 + i * 7), Vector2(s.size.x, 3)), Color("#0a0820"))
			C.draw_string(f, s.position + Vector2(0, s.size.y * 0.3), gd.get("name", ""), HORIZONTAL_ALIGNMENT_CENTER, s.size.x, 22, Color.WHITE)
			var spin := fmod(T * 3.0, TAU)
			C.draw_arc(s.get_center() + Vector2(0, s.size.y * 0.2), 20, spin, spin + 4.0, 16, Color("#00e5ff"), 4)
		_:
			# открытый мир: горы, лес, герой со спины
			var dusk := game_name in ["eldenring", "wukong", "witcher3", "starfield"]
			_grad(Rect2(s.position, Vector2(s.size.x, s.size.y * 0.6)), Color("#1a2340") if dusk else Color("#4a86d0"), Color("#e8a26a") if dusk else Color("#cfe6ff"))
			if game_name == "starfield":
				for i in 30:
					C.draw_circle(s.position + Vector2(fmod(i * 97.0, s.size.x), fmod(i * 53.0, s.size.y * 0.5)), 1.2, Color.WHITE)
			for k in 3:
				var col := Color("#6a7fa0").lerp(Color("#2f4a2a"), k / 2.0)
				var pts := PackedVector2Array([Vector2(s.position.x, s.end.y)])
				for i in 13:
					var xx := s.position.x + s.size.x * i / 12.0
					var ph := sin(i * (1.3 + k) + h * 0.001 + T * 0.05 * (k + 1)) * 0.08 + 0.35 + k * 0.1
					pts.append(Vector2(xx, s.position.y + s.size.y * ph + (0.25 if k == 0 else 0.15)))
				pts.append(Vector2(s.end.x, s.end.y))
				C.draw_colored_polygon(pts, col)
			for i in 10:
				var tx := s.position.x + fmod(i * s.size.x * 0.12 - T * 18.0, s.size.x + 40) - 20
				var ty := s.end.y - s.size.y * (0.12 + (i % 3) * 0.05)
				C.draw_colored_polygon(PackedVector2Array([Vector2(tx - 10, ty), Vector2(tx, ty - 34), Vector2(tx + 10, ty)]), Color("#1f3d1c"))
			var hero := Vector2(s.get_center().x, s.end.y - s.size.y * 0.08)
			var step := sin(T * 5.0) * 3.0
			C.draw_rect(_snapr(Rect2(hero - Vector2(12, 46 + step), Vector2(24, 34)), px), Color("#4e342e"))
			C.draw_circle(hero - Vector2(0, 52 + step), 10, Color("#3e2723"))
			C.draw_line(hero - Vector2(-12, 40), hero - Vector2(-30, 70), Color("#cfd8dc"), 3)
			C.draw_rect(Rect2(s.position + Vector2(10, 10), Vector2(120, 8)), Color(0, 0, 0, 0.5))
			C.draw_rect(Rect2(s.position + Vector2(10, 10), Vector2(96, 8)), Color("#e53935"))
	# FPS и название
	var col := Color("#66bb6a") if game_fps >= 60 else (Color("#ffb74d") if game_fps >= 30 else Color("#ef5350"))
	Gfx.rr(C, Rect2(s.position + Vector2(s.size.x - 92, 8), Vector2(84, 24)), Color(0, 0, 0, 0.65), 6)
	C.draw_string(Gfx.FONT_BOLD, s.position + Vector2(s.size.x - 86, 26), "%d FPS" % int(game_fps), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
	if game_fps < 25:
		C.draw_string(Gfx.FONT_BOLD, s.position + Vector2(0, s.size.y * 0.5), "лагает…", HORIZONTAL_ALIGNMENT_CENTER, s.size.x, 18, Color(1, 0.4, 0.4, 0.5 + 0.5 * sin(t * 4)))


func _snap(v: Vector2, px: float) -> Vector2:
	return (v / px).floor() * px if px > 1.0 else v


func _snapr(r: Rect2, px: float) -> Rect2:
	if px <= 1.0:
		return r
	return Rect2(_snap(r.position, px), (r.size / px).round() * px)


func _grad(r: Rect2, a: Color, b: Color) -> void:
	var cols := PackedColorArray([a, a, b, b])
	C.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), cols)


func ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	C.draw_colored_polygon(pts, col)
