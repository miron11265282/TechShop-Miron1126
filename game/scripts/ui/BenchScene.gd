extends Control
## Рабочее место: комната своей эпохи, стол, открытый ПК, монитор, клавиатура и мышь.

const Gfx := preload("res://scripts/ui/Gfx.gd")
const PC_VIEW := preload("res://scripts/ui/PcView.gd")
const MONITOR := preload("res://scripts/ui/Monitor.gd")

var pc: Dictionary = {}
var year := 1995
var pv
var mon
var t := 0.0
var accent := Color("#ff8a1f")
var fx: Control
var stage := 0
var helpers := 0
var home := false


func setup(p: Dictionary, y: int) -> void:
	pc = p
	year = y
	stage = Game.stage
	helpers = Game.workers.size()
	home = Game.current_order.get("visit", false) and is_same(p, Game.current_order.get("pc"))
	if home:
		stage = 0
		helpers = 0
	pv = PC_VIEW.new()
	pv.pc = pc
	pv.year = y
	pv.powered = pc.get("on", false) and Game.boot_problems(pc).is_empty()
	add_child(pv)
	mon = MONITOR.new()
	mon.pc = pc
	mon.year = y
	var g: String = pc.get("playing", "")
	if g != "" and Data.games.has(g):
		mon.game_name = g
		mon.game_fps = Game.fps(pc, g)
	add_child(mon)
	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.draw.connect(_draw_fx)
	add_child(fx)


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	t += delta
	if Engine.get_process_frames() % 2 == 0:
		queue_redraw()
		if fx:
			fx.queue_redraw()


func _desk_y() -> float:
	return size.y * 0.8


func _layout() -> void:
	if pv == null:
		return
	var dy := _desk_y()
	var pw: float = min(size.x * 0.38, (dy - 10) * 0.95)
	pv.position = Vector2(size.x * 0.025, 8)
	pv.size = Vector2(pw, dy - 4)
	var mx: float = pv.position.x + pw + size.x * 0.025
	var mh: float = dy + size.y * 0.04 - 6
	var crt := year < 2004
	var ar := 4.0 / 3.0 if crt else 16.0 / 9.0
	var need_w: float = (mh - 120.0) * ar + 82.0 if crt else ((mh - (76.0 if year < 2018 else 58.0)) * ar + (36.0 if year < 2018 else 24.0))
	var mw: float = min(size.x - mx - size.x * 0.19, need_w)
	fx.position = Vector2.ZERO
	fx.size = size
	mon.position = Vector2(mx, 6)
	mon.size = Vector2(mw, mh)


func _draw() -> void:
	var dy := _desk_y()
	var r := Rect2(Vector2.ZERO, size)
	var wall_top: Color
	var wall_bot: Color
	if year < 2001:
		wall_top = Color("#cdbf9c")
		wall_bot = Color("#a8996f")
	elif year < 2007:
		wall_top = Color("#7f93a8")
		wall_bot = Color("#5d6f82")
	elif year < 2013:
		wall_top = Color("#3d4652")
		wall_bot = Color("#2a313a")
	else:
		wall_top = Color("#22252c")
		wall_bot = Color("#15171b")
	match stage:
		1:
			wall_top = Color("#8a8f96")
			wall_bot = Color("#5f646b")
		2:
			wall_top = Color("#e9e4da") if year < 2010 else Color("#2b2f36")
			wall_bot = Color("#cfc8bb") if year < 2010 else Color("#1d2026")
		3:
			wall_top = Color("#dfe6ee") if year < 2010 else Color("#262a31")
			wall_bot = Color("#b9c4d0") if year < 2010 else Color("#181b20")
		4:
			wall_top = Color("#0f1a2e")
			wall_bot = Color("#0a0f1a")
	if home:
		wall_top = Color("#d9c7a8")
		wall_bot = Color("#b89f7a")
	Gfx.vgrad(self, Rect2(0, 0, size.x, dy), wall_top, wall_bot)
	if home:
		# обои в цветочек у клиента дома
		var rngh := RandomNumberGenerator.new()
		rngh.seed = 77
		for yy in range(14, int(dy), 34):
			for xx in range(10 + (yy / 34 % 2) * 17, int(size.x), 34):
				draw_circle(Vector2(xx, yy), 3, Color(0.75, 0.4, 0.35, 0.25))
				draw_circle(Vector2(xx, yy), 1.2, Color(1, 0.9, 0.6, 0.35))
		draw_rect(Rect2(0, dy - 10, size.x, 10), Color("#8d6e4a"))
	if stage == 1:
		# гофрированный металл гаража
		var k1 := 0.0
		while k1 < size.x:
			Gfx.hgrad(self, Rect2(k1, 0, 9, dy), Color(1, 1, 1, 0.08), Color(0, 0, 0, 0.1))
			k1 += 18
	elif stage == 2:
		draw_rect(Rect2(0, dy * 0.62, size.x, dy * 0.06), Color(accent, 0.6))
	elif stage == 3:
		for i in 8:
			draw_line(Vector2(size.x * i / 8.0, 0), Vector2(size.x * i / 8.0, dy), Color(1, 1, 1, 0.06), 2)
	elif stage == 4:
		# панорамное окно во всю стену: небо и город далеко внизу
		Gfx.vgrad(self, Rect2(0, 0, size.x, dy), Color("#3a6cc8"), Color("#f2b27a"))
		var rng4 := RandomNumberGenerator.new()
		rng4.seed = 4
		for i in 40:
			var bw := size.x / 40.0
			var bh := dy * rng4.randf_range(0.05, 0.22)
			draw_rect(Rect2(Vector2(i * bw, dy - bh), Vector2(bw * 0.9, bh)), Color("#2a3550"))
		for i in 5:
			Gfx.glow(self, Vector2(size.x * (0.1 + i * 0.2), dy * (0.15 + 0.05 * (i % 2))), 60, Color(1, 1, 1, 0.25))
		for i in 6:
			draw_line(Vector2(size.x * i / 6.0, 0), Vector2(size.x * i / 6.0, dy), Color("#1b2233"), 5)
	# обои в полоску в 90-е
	if year < 2001 and stage == 0:
		var k := 0.0
		while k < size.x:
			draw_rect(Rect2(k, 0, 10, dy), Color(1, 1, 1, 0.05))
			k += 34
	var fx0: float = (mon.position.x + mon.size.x + 12) if mon else size.x * 0.8
	var fw: float = size.x - fx0 - 12
	if fw >= 70 and home:
		# ковёр на стене и телевизор с диваном
		var rug := Rect2(Vector2(fx0 + fw * 0.08, size.y * 0.06), Vector2(fw * 0.84, size.y * 0.32))
		Gfx.rr(self, rug, Color("#8e2a2a"), 4, Color("#5a1515"), 3)
		Gfx.rr(self, rug.grow(-8), Color(0, 0, 0, 0), 3, Color("#d4a24a"), 2)
		var rc := rug.get_center()
		draw_colored_polygon(PackedVector2Array([rc + Vector2(0, -rug.size.y * 0.3), rc + Vector2(rug.size.x * 0.3, 0), rc + Vector2(0, rug.size.y * 0.3), rc + Vector2(-rug.size.x * 0.3, 0)]), Color("#c27c2c"))
		draw_circle(rc, rug.size.y * 0.1, Color("#1f4f8a"))
		var tv := Rect2(Vector2(fx0 + fw * 0.2, dy - size.y * 0.24), Vector2(fw * 0.6, size.y * 0.16))
		Gfx.rr(self, Rect2(Vector2(fx0 + fw * 0.1, dy - size.y * 0.08), Vector2(fw * 0.8, size.y * 0.08)), Color("#6d4c35"), 2)
		Gfx.rr(self, tv, Color("#1a1b1e"), 4 if year >= 2006 else 10, Color("#3a3d44"), 1, 4)
		Gfx.vgrad(self, tv.grow(-4), Color("#2e5a8a"), Color("#16304d"))
		Gfx.text(self, Vector2(fx0, size.y * 0.45), "Вызов на дом", 12, Color(0.3, 0.2, 0.1, 0.8), fw, HORIZONTAL_ALIGNMENT_CENTER, true)
	elif fw >= 70 and stage == 1:
		# перфорированная доска с инструментами
		var pb := Rect2(Vector2(fx0, size.y * 0.06), Vector2(fw, size.y * 0.42))
		Gfx.rr(self, pb, Color("#c9a77a"), 3, Color("#8d6e4a"), 2, 4)
		for yy in range(int(pb.position.y) + 8, int(pb.end.y) - 4, 12):
			for xx in range(int(pb.position.x) + 8, int(pb.end.x) - 4, 12):
				draw_circle(Vector2(xx, yy), 1.5, Color("#7a5a38"))
		for i in 4:
			var tx := pb.position.x + pb.size.x * (0.15 + i * 0.22)
			draw_line(Vector2(tx, pb.position.y + 16), Vector2(tx, pb.position.y + pb.size.y * 0.7), [Color("#d32f2f"), Color("#9aa0a8"), Color("#1976d2"), Color("#fbc02d")][i], 4)
			draw_circle(Vector2(tx, pb.position.y + 16), 6, Color("#9aa0a8"))
	elif fw >= 70 and stage == 2:
		# витрина магазина: улица и прохожие
		var win2 := Rect2(Vector2(fx0, size.y * 0.04), Vector2(fw, size.y * 0.5))
		Gfx.rr(self, win2.grow(4), Color("#3a3d44"), 3)
		Gfx.vgrad(self, win2, Color("#8ec5ff"), Color("#d8ecff"))
		for i in 4:
			draw_rect(Rect2(win2.position + Vector2(win2.size.x * (i * 0.26), win2.size.y * 0.35), Vector2(win2.size.x * 0.22, win2.size.y * 0.5)), Color("#c7b8a3").darkened(i * 0.08))
		draw_rect(Rect2(win2.position + Vector2(0, win2.size.y * 0.85), Vector2(win2.size.x, win2.size.y * 0.15)), Color("#7d8288"))
		var px: float = win2.position.x + fmod(t * 25.0, win2.size.x)
		draw_circle(Vector2(px, win2.end.y - win2.size.y * 0.24), 5, Color("#f2c9a0"))
		draw_rect(Rect2(Vector2(px - 5, win2.end.y - win2.size.y * 0.2), Vector2(10, 16)), Color("#3949ab"))
		Gfx.text(self, win2.position + Vector2(0, 16), "РЕМОНТ ПК", 12, Color(accent, 0.9), win2.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	elif fw >= 70 and stage == 3:
		# стеклянная перегородка и город
		var win3 := Rect2(Vector2(fx0, size.y * 0.04), Vector2(fw, size.y * 0.46))
		Gfx.vgrad(self, win3, Color("#5c8fd6"), Color("#cfe2f7"))
		for i in 10:
			var bh3 := win3.size.y * (0.3 + fmod(i * 0.41, 0.5))
			draw_rect(Rect2(Vector2(win3.position.x + win3.size.x * i / 10.0, win3.end.y - bh3), Vector2(win3.size.x / 11.0, bh3)), Color("#6f7f96"))
		Gfx.rr(self, win3, Color(0, 0, 0, 0), 2, Color("#9aa7b8"), 3)
		draw_circle(Vector2(fx0 + fw * 0.5, dy - 30), 18, Color("#2e7d32"))
		Gfx.rr(self, Rect2(Vector2(fx0 + fw * 0.5 - 12, dy - 18), Vector2(24, 18)), Color("#eceff1"), 3)
	elif fw >= 70 and stage == 4:
		Gfx.text(self, Vector2(fx0, size.y * 0.1), "100 ЭТАЖ", 14, Color(1, 1, 1, 0.8), fw, HORIZONTAL_ALIGNMENT_CENTER, true)
		Gfx.text(self, Vector2(fx0, size.y * 0.1 + 18), "Техноград", 11, Color(1, 1, 1, 0.6), fw, HORIZONTAL_ALIGNMENT_CENTER)
	elif fw >= 70:
		# окно с небом
		var win := Rect2(Vector2(fx0 + fw * 0.08, size.y * 0.07), Vector2(fw * 0.84, size.y * 0.3))
		var frame := Color("#e8e2d0") if year < 2007 else Color("#4a515c")
		Gfx.rr(self, win.grow(5), frame, 4, Color(0, 0, 0, 0), 0, 4)
		if year < 2013:
			Gfx.vgrad(self, win, Color("#6fb4ff"), Color("#cfe8ff"))
			draw_circle(win.position + Vector2(win.size.x * 0.72, win.size.y * 0.3), win.size.y * 0.1, Color("#fff4b0"))
		else:
			Gfx.vgrad(self, win, Color("#0b1530"), Color("#26365e"))
			for i in 12:
				var bxx := win.position.x + win.size.x * (i / 12.0)
				var bh := win.size.y * (0.25 + fmod(i * 0.37, 0.5))
				draw_rect(Rect2(Vector2(bxx, win.end.y - bh), Vector2(win.size.x / 13.0, bh)), Color("#0e1222"))
				if i % 3 == 0:
					draw_rect(Rect2(Vector2(bxx + 2, win.end.y - bh + 6), Vector2(3, 3)), Color("#ffd27a"))
		draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), frame, 3)
		draw_line(Vector2(win.position.x, win.get_center().y), Vector2(win.end.x, win.get_center().y), frame, 3)
		# полка с мелочами
		var sh := Rect2(Vector2(fx0, size.y * 0.5), Vector2(fw, 6))
		Gfx.rr(self, sh, Color("#6d4c35") if year < 2013 else Color("#2b2e35"), 2, Color(0, 0, 0, 0), 0, 4)
		var bx := sh.position.x + 4
		var book_cols := [Color("#c0392b"), Color("#2e86c1"), Color("#27ae60"), Color("#f1c40f"), Color("#8e44ad")]
		for i in 5:
			if bx + 8 > sh.end.x - 30:
				break
			var bh := 18.0 + (i * 7) % 12
			Gfx.rr(self, Rect2(Vector2(bx, sh.position.y - bh), Vector2(8, bh)), book_cols[i], 1)
			bx += 10
		draw_circle(Vector2(sh.end.x - 14, sh.position.y - 12), 10, Color("#4caf50"))
		draw_circle(Vector2(sh.end.x - 20, sh.position.y - 16), 6, Color("#66bb6a"))
		Gfx.rr(self, Rect2(Vector2(sh.end.x - 21, sh.position.y - 7), Vector2(14, 7)), Color("#8d6e63"), 1)
		# постер
		var post := Rect2(Vector2(fx0 + fw * 0.15, size.y * 0.56), Vector2(fw * 0.7, size.y * 0.2))
		if post.size.y > 30:
			Gfx.rr(self, post.grow(3), Color("#111"), 3, Color(0, 0, 0, 0), 0, 6)
			Gfx.vgrad(self, post, accent.darkened(0.15), accent.darkened(0.7))
			Gfx.text(self, post.position + Vector2(0, post.size.y * 0.45), "miron1126", int(clamp(post.size.x * 0.16, 9, 18)), Color.WHITE, post.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
			Gfx.text(self, post.position + Vector2(0, post.size.y * 0.78), str(year), int(clamp(post.size.x * 0.13, 8, 15)), Color(1, 1, 1, 0.6), post.size.x, HORIZONTAL_ALIGNMENT_CENTER, true)
	# коллеги за соседними столами
	if helpers > 0 and fw >= 70:
		for i in min(helpers, 3):
			var hx: float = fx0 + fw * (0.18 + i * 0.3)
			var hy := dy - 6
			Gfx.rr(self, Rect2(Vector2(hx - 16, hy - 26), Vector2(32, 20)), Color("#111"), 2)
			Gfx.rr(self, Rect2(Vector2(hx - 14, hy - 24), Vector2(28, 16)), Color(0.3, 0.6, 1.0, 0.7), 1)
			draw_circle(Vector2(hx + 4, hy - 34), 6, Color("#1b1d22"))
			Gfx.rr(self, Rect2(Vector2(hx - 4, hy - 28), Vector2(16, 22)), Color("#1b1d22"), 5)
	# свет экрана на стене
	if mon and pc.get("on", false):
		var tint: Color = mon.screen_tint()
		if tint.a > 0:
			var sc: Vector2 = mon.position + mon.size * Vector2(0.5, 0.4)
			Gfx.glow(self, sc, mon.size.x * 0.75, Color(tint, tint.a * 0.35))
	# LED-подсветка в новых
	if year >= 2013:
		Gfx.hgrad(self, Rect2(0, dy - 3, size.x, 3), Color(accent, 0.0), Color(accent, 0.9))
		Gfx.vgrad(self, Rect2(0, dy - 60, size.x, 57), Color(accent, 0.0), Color(accent, 0.12))
	# стол
	var top_col := Color("#a9784f") if year < 2007 else (Color("#6b4e3a") if year < 2013 else Color("#24262b"))
	var surface := Rect2(Vector2(0, dy), Vector2(size.x, size.y * 0.13))
	Gfx.vgrad(self, surface, top_col.darkened(0.1), top_col.lightened(0.08))
	if year < 2013:
		# текстура дерева
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in 8:
			var yy := dy + rng.randf() * surface.size.y
			draw_line(Vector2(0, yy), Vector2(size.x, yy + rng.randf_range(-4, 4)), Color(0, 0, 0, 0.06), 1.5)
	else:
		# коврик на стол
		Gfx.rr(self, Rect2(Vector2(size.x * 0.42, dy + 4), Vector2(size.x * 0.56, surface.size.y - 8)), Color("#111216"), 6, Color(accent, 0.5), 1)
	draw_rect(Rect2(Vector2(0, surface.end.y), Vector2(size.x, size.y - surface.end.y)), top_col.darkened(0.45))
	draw_line(Vector2(0, surface.end.y), Vector2(size.x, surface.end.y), top_col.lightened(0.2), 2)
	# клавиатура и мышь перед монитором
	if mon:
		var kx: float = mon.position.x + mon.size.x * 0.5
		var kw: float = min(mon.size.x * 0.56, 300.0)
		var kb := Rect2(Vector2(kx - kw / 2.0, dy + surface.size.y * 0.32), Vector2(kw, surface.size.y * 0.5))
		var kcol := Color("#d9d1b8") if year < 2004 else Color("#1b1c20")
		Gfx.rr(self, kb, kcol, 5, kcol.darkened(0.3), 1, 4)
		var rows := 4
		for rr in rows:
			var n := 14
			for k in n:
				var kw2 := (kb.size.x - 12) / n
				Gfx.rr(self, Rect2(kb.position + Vector2(6 + k * kw2, 4 + rr * (kb.size.y - 8) / rows), Vector2(kw2 - 2, (kb.size.y - 8) / rows - 2)), kcol.lightened(0.12) if year < 2004 else Color("#2a2c31"), 1)
		if year >= 2016 and pc.get("on", false):
			Gfx.vgrad(self, Rect2(kb.position + Vector2(6, kb.size.y - 4), Vector2(kb.size.x - 12, 3)), Color.from_hsv(fmod(t * 0.1, 1.0), 0.8, 1.0), Color.from_hsv(fmod(t * 0.1 + 0.5, 1.0), 0.8, 1.0))
		var ms := Rect2(Vector2(kb.end.x + 18, kb.position.y + 2), Vector2(20, 30))
		Gfx.rr(self, ms, kcol, 10, kcol.darkened(0.3), 1, 3)
		draw_line(ms.position + Vector2(10, 2), ms.position + Vector2(10, 12), kcol.darkened(0.3), 1)
		# кружка
		var mug := Rect2(Vector2(kb.position.x - 46, kb.position.y - 6), Vector2(22, 26))
		Gfx.rr(self, mug, Color("#eeeeee") if year < 2013 else accent, 4)
		draw_arc(mug.position + Vector2(mug.size.x, mug.size.y * 0.5), 6, -PI / 2, PI / 2, 10, Color("#eeeeee") if year < 2013 else accent, 3)
		if pc.get("on", false):
			for i in 2:
				var sx := mug.position.x + 6 + i * 8
				var pts := PackedVector2Array()
				for j in 6:
					pts.append(Vector2(sx + sin(t * 2 + j + i) * 3, mug.position.y - 4 - j * 4))
				draw_polyline(pts, Color(1, 1, 1, 0.2), 2, true)


func _draw_fx() -> void:
	## Свет экрана на столе, виньетка по краям
	var dy := _desk_y()
	if mon and pc.get("on", false):
		var tint: Color = mon.screen_tint()
		if tint.a > 0:
			var cx: float = mon.position.x + mon.size.x * 0.5
			fx.draw_set_transform(Vector2(cx, dy + size.y * 0.06), 0.0, Vector2(1.0, 0.25))
			Gfx.glow(fx, Vector2.ZERO, mon.size.x * 0.55, Color(tint, tint.a * 0.45))
			fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if pv and pv.powered and year >= 2016:
		var rc := Color.from_hsv(fmod(t * 0.12, 1.0), 0.8, 1.0)
		var px: float = pv.position.x + pv.size.x * 0.5
		fx.draw_set_transform(Vector2(px, dy + 4), 0.0, Vector2(1.0, 0.22))
		Gfx.glow(fx, Vector2.ZERO, pv.size.x * 0.6, Color(rc, 0.25))
		fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# виньетка
	var e := 40.0
	Gfx.hgrad(fx, Rect2(0, 0, e, size.y), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0))
	Gfx.hgrad(fx, Rect2(size.x - e, 0, e, size.y), Color(0, 0, 0, 0), Color(0, 0, 0, 0.3))
	Gfx.vgrad(fx, Rect2(0, 0, size.x, e), Color(0, 0, 0, 0.25), Color(0, 0, 0, 0))
