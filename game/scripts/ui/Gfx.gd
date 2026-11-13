extends RefCounted
## Общие функции рисования: скруглённые прямоугольники с тенью, градиенты, вентиляторы, текст.

const FONT := preload("res://assets/fonts/Inter-SemiBold.otf")
const FONT_BOLD := preload("res://assets/fonts/Inter-Bold.otf")
const FONT_MONO := preload("res://assets/fonts/DejaVuSansMono.ttf")


static func rr(ci: CanvasItem, r: Rect2, col: Color, rad: float = 4.0, bcol: Color = Color(0, 0, 0, 0), bw: int = 0, shadow: int = 0, shadow_col: Color = Color(0, 0, 0, 0.35)) -> void:
	if r.size.x <= 0.5 or r.size.y <= 0.5:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	var rad_i := int(min(rad, min(r.size.x, r.size.y) / 2.0))
	sb.set_corner_radius_all(rad_i)
	sb.corner_detail = 6
	if bw > 0:
		sb.border_color = bcol
		sb.set_border_width_all(bw)
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = shadow_col
		sb.shadow_offset = Vector2(0, shadow * 0.4)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


static func hgrad(ci: CanvasItem, r: Rect2, left: Color, right: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([left, right, right, left]))


static func metal(ci: CanvasItem, r: Rect2, base: Color, rad: float = 3.0) -> void:
	## Металлическая поверхность: скругление + блик сверху
	rr(ci, r, base, rad, base.darkened(0.35), 1)
	var hi := Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.42))
	if hi.size.x > 2 and hi.size.y > 2:
		vgrad(ci, hi, Color(1, 1, 1, 0.22), Color(1, 1, 1, 0.0))


static func circle_grad(ci: CanvasItem, c: Vector2, rad: float, inner: Color, outer: Color, steps: int = 28) -> void:
	var pts := PackedVector2Array([c])
	var cols := PackedColorArray([inner])
	for i in steps + 1:
		var a := TAU * float(i) / float(steps)
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
		cols.append(outer)
	ci.draw_polygon(pts, cols)


static func glow(ci: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	circle_grad(ci, c, rad, col, Color(col.r, col.g, col.b, 0.0))


static func fan(ci: CanvasItem, c: Vector2, rad: float, t: float, frame: Color = Color("#1b1c20"), blade: Color = Color("#3b3e45"), square: bool = true, blades: int = 7, blur: bool = false) -> void:
	## Вентилятор с изогнутыми лопастями. t — угол поворота. blur — размытие при вращении.
	if rad < 3.0:
		return
	if square:
		rr(ci, Rect2(c - Vector2(rad, rad) * 1.08, Vector2(rad, rad) * 2.16), frame, rad * 0.18, frame.lightened(0.12), 1)
		for k in 4:
			var a := PI / 4.0 + k * PI / 2.0
			ci.draw_circle(c + Vector2(cos(a), sin(a)) * rad * 1.28, max(1.0, rad * 0.09), frame.lightened(0.3))
			ci.draw_circle(c + Vector2(cos(a), sin(a)) * rad * 1.28, max(0.6, rad * 0.04), frame.darkened(0.4))
	circle_grad(ci, c, rad, frame.darkened(0.55), frame.darkened(0.2))
	var passes := 2 if blur else 1
	var alpha := 0.55 if blur else 1.0
	if blur:
		circle_grad(ci, c, rad * 0.94, Color(blade, 0.15), Color(blade.lightened(0.15), 0.55))
	for pss in passes:
		for i in blades:
			var a0 := t + pss * 0.22 + TAU * float(i) / float(blades)
			var pts := PackedVector2Array()
			var hub := rad * 0.3
			for k in 6:
				var u := float(k) / 5.0
				var rr_: float = lerp(hub, rad * 0.94, u)
				pts.append(c + Vector2(cos(a0 + u * 0.55), sin(a0 + u * 0.55)) * rr_)
			for k in 6:
				var u := 1.0 - float(k) / 5.0
				var rr_: float = lerp(hub, rad * 0.94, u)
				pts.append(c + Vector2(cos(a0 + u * 0.55 + 0.42 - u * 0.12), sin(a0 + u * 0.55 + 0.42 - u * 0.12)) * rr_)
			ci.draw_colored_polygon(pts, Color(blade, alpha))
			if not blur and rad > 10:
				ci.draw_polyline(pts.slice(0, 6), Color(1, 1, 1, 0.12), 1.0, true)
	circle_grad(ci, c, rad * 0.34, frame.lightened(0.35), frame.lightened(0.05))
	ci.draw_circle(c, rad * 0.16, frame.lightened(0.45))
	ci.draw_arc(c, rad, 0, TAU, 40, frame.lightened(0.15), max(1.0, rad * 0.06), true)


# ---------- процедурные текстуры (создаются один раз) ----------
static var _tex := {}


static func tex(kind: String) -> Texture2D:
	if _tex.has(kind):
		return _tex[kind]
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.hash()
	match kind:
		"brushed":
			# шлифованный металл: горизонтальные штрихи
			for y in n:
				var row := rng.randf_range(-0.09, 0.09)
				for x in n:
					var v := 0.5 + row + rng.randf_range(-0.03, 0.03)
					img.set_pixel(x, y, Color(v, v, v, 0.28))
		"pcb":
			# стеклотекстолит: мелкое зерно + точки пайки
			for y in n:
				for x in n:
					var v := rng.randf_range(-0.06, 0.06)
					img.set_pixel(x, y, Color(0.5 + v, 0.5 + v, 0.5 + v, 0.18))
			for i in 60:
				var px := rng.randi_range(1, n - 2)
				var py := rng.randi_range(1, n - 2)
				img.set_pixel(px, py, Color(0.95, 0.85, 0.5, 0.7))
		"noise":
			for y in n:
				for x in n:
					var v := rng.randf()
					img.set_pixel(x, y, Color(v, v, v, 0.06))
		"mesh":
			# сетка-перфорация
			for y in n:
				for x in n:
					var hole := (x % 6 < 3 and y % 6 < 3) or ((x + 3) % 6 < 3 and (y + 3) % 6 < 3)
					img.set_pixel(x, y, Color(0, 0, 0, 0.55) if hole else Color(1, 1, 1, 0.04))
	var t := ImageTexture.create_from_image(img)
	_tex[kind] = t
	return t


static func textured(ci: CanvasItem, r: Rect2, kind: String, mod: Color = Color.WHITE) -> void:
	if r.size.x < 2 or r.size.y < 2:
		return
	ci.draw_texture_rect(tex(kind), r, true, mod)


static func bevel(ci: CanvasItem, r: Rect2, light: Color, dark: Color, w: float = 2.0) -> void:
	## Фаска: светлая сверху-слева, тёмная снизу-справа
	ci.draw_line(r.position, Vector2(r.end.x, r.position.y), light, w)
	ci.draw_line(r.position, Vector2(r.position.x, r.end.y), light, w)
	ci.draw_line(Vector2(r.position.x, r.end.y), r.end, dark, w)
	ci.draw_line(Vector2(r.end.x, r.position.y), r.end, dark, w)


static func quad(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color = Color(-1, 0, 0), cc: Color = Color(-1, 0, 0), cd: Color = Color(-1, 0, 0)) -> void:
	## Четырёхугольник с цветами в углах (для объёма)
	var cols := PackedColorArray([ca, cb if cb.r >= 0 else ca, cc if cc.r >= 0 else ca, cd if cd.r >= 0 else ca])
	ci.draw_polygon(PackedVector2Array([a, b, c, d]), cols)


static func braid(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	## Оплётка кабеля: основа + диагональные штрихи
	ci.draw_polyline(pts, col.darkened(0.3), w + 1.0, true)
	ci.draw_polyline(pts, col, w, true)
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var d := (b - a)
		var ln := d.length()
		if ln < 1.0:
			continue
		var nrm := Vector2(-d.y, d.x) / ln * w * 0.5
		var k := 0.0
		while k < ln:
			var p := a + d * (k / ln)
			ci.draw_line(p - nrm, p + nrm + d / ln * 2.0, col.lightened(0.25), 1.0)
			k += 4.0
	ci.draw_polyline(pts, Color(1, 1, 1, 0.12), max(1.0, w * 0.25), true)


static func grill(ci: CanvasItem, c: Vector2, rad: float, col: Color) -> void:
	for k in 4:
		ci.draw_arc(c, rad * (0.3 + k * 0.23), 0, TAU, 28, col, 1.2, true)
	for k in 4:
		var a := k * PI / 4.0
		ci.draw_line(c - Vector2(cos(a), sin(a)) * rad, c + Vector2(cos(a), sin(a)) * rad, col, 1.2, true)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float = -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, bold := false) -> void:
	ci.draw_string(FONT_BOLD if bold else FONT, pos, s, align, width, size, col)


static func text_w(s: String, size: int, bold := false) -> float:
	return (FONT_BOLD if bold else FONT).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func screw(ci: CanvasItem, c: Vector2, rad: float = 2.5) -> void:
	ci.draw_circle(c, rad, Color("#9aa0a8"))
	ci.draw_line(c - Vector2(rad * 0.7, 0), c + Vector2(rad * 0.7, 0), Color("#5d6168"), 1.0)
