extends RefCounted
## Векторные иконки интерфейса. draw(ci, имя, прямоугольник, цвет).

const Gfx := preload("res://scripts/ui/Gfx.gd")


static func draw(ci: CanvasItem, name: String, r: Rect2, col: Color) -> void:
	var s: float = min(r.size.x, r.size.y)
	var o := r.get_center() - Vector2(s, s) / 2.0
	var w: float = max(1.6, s * 0.085)
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	match name:
		"power":
			ci.draw_arc(P.call(0.5, 0.55), s * 0.32, -PI * 0.3, PI * 1.3, 24, col, w, true)
			ci.draw_line(P.call(0.5, 0.12), P.call(0.5, 0.5), col, w, true)
		"desk":
			Gfx.rr(ci, Rect2(P.call(0.1, 0.16), Vector2(s * 0.8, s * 0.52)), Color(0, 0, 0, 0), s * 0.06, col, int(w))
			ci.draw_line(P.call(0.5, 0.68), P.call(0.5, 0.82), col, w)
			ci.draw_line(P.call(0.3, 0.84), P.call(0.7, 0.84), col, w, true)
			ci.draw_line(P.call(0.25, 0.32), P.call(0.42, 0.42), col, w * 0.7, true)
			ci.draw_line(P.call(0.25, 0.52), P.call(0.42, 0.42), col, w * 0.7, true)
			ci.draw_line(P.call(0.48, 0.54), P.call(0.66, 0.54), col, w * 0.7, true)
		"diag":
			ci.draw_arc(P.call(0.42, 0.42), s * 0.26, 0, TAU, 28, col, w, true)
			ci.draw_line(P.call(0.62, 0.62), P.call(0.86, 0.86), col, w * 1.3, true)
			ci.draw_polyline(PackedVector2Array([P.call(0.24, 0.44), P.call(0.34, 0.44), P.call(0.4, 0.3), P.call(0.47, 0.56), P.call(0.53, 0.4), P.call(0.6, 0.44)]), col, w * 0.6, true)
		"cable":
			Gfx.rr(ci, Rect2(P.call(0.3, 0.1), Vector2(s * 0.4, s * 0.34)), col, s * 0.06)
			ci.draw_line(P.call(0.4, 0.1), P.call(0.4, 0.0), col, w)
			ci.draw_line(P.call(0.6, 0.1), P.call(0.6, 0.0), col, w)
			ci.draw_polyline(PackedVector2Array([P.call(0.5, 0.44), P.call(0.5, 0.6), P.call(0.3, 0.75), P.call(0.5, 0.92)]), col, w, true)
		"bios":
			Gfx.rr(ci, Rect2(P.call(0.24, 0.24), Vector2(s * 0.52, s * 0.52)), Color(0, 0, 0, 0), s * 0.06, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.38, 0.38), Vector2(s * 0.24, s * 0.24)), col, s * 0.03)
			for i in 3:
				var u := 0.34 + i * 0.16
				ci.draw_line(P.call(u, 0.08), P.call(u, 0.24), col, w * 0.7)
				ci.draw_line(P.call(u, 0.76), P.call(u, 0.92), col, w * 0.7)
				ci.draw_line(P.call(0.08, u), P.call(0.24, u), col, w * 0.7)
				ci.draw_line(P.call(0.76, u), P.call(0.92, u), col, w * 0.7)
		"dust":
			for i in 3:
				var yy := 0.3 + i * 0.2
				ci.draw_polyline(PackedVector2Array([P.call(0.12, yy), P.call(0.55, yy), P.call(0.7, yy - 0.08), P.call(0.6, yy - 0.16)]), col, w * 0.8, true)
			ci.draw_circle(P.call(0.82, 0.62), s * 0.05, col)
			ci.draw_circle(P.call(0.75, 0.82), s * 0.04, col)
		"paste":
			var pts := PackedVector2Array([P.call(0.2, 0.75), P.call(0.6, 0.35), P.call(0.72, 0.47), P.call(0.32, 0.87)])
			ci.draw_colored_polygon(pts, col)
			ci.draw_line(P.call(0.66, 0.41), P.call(0.82, 0.25), col, w * 1.4)
			ci.draw_circle(P.call(0.86, 0.14), s * 0.06, col)
		"backup":
			ci.draw_arc(P.call(0.5, 0.5), s * 0.34, PI * 0.15, PI * 1.85, 28, col, w, true)
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.72, 0.22), P.call(0.92, 0.3), P.call(0.74, 0.42)]), col)
			ci.draw_line(P.call(0.5, 0.32), P.call(0.5, 0.52), col, w, true)
			ci.draw_line(P.call(0.5, 0.52), P.call(0.64, 0.6), col, w, true)
		"os":
			ci.draw_arc(P.call(0.5, 0.5), s * 0.38, 0, TAU, 32, col, w, true)
			ci.draw_arc(P.call(0.5, 0.5), s * 0.12, 0, TAU, 20, col, w, true)
			ci.draw_arc(P.call(0.5, 0.5), s * 0.26, -PI * 0.9, -PI * 0.55, 10, col, w * 0.6, true)
		"drivers":
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.26, P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.4, col, w * 1.3)
			ci.draw_arc(P.call(0.5, 0.5), s * 0.24, 0, TAU, 24, col, w, true)
			ci.draw_arc(P.call(0.5, 0.5), s * 0.09, 0, TAU, 16, col, w, true)
		"shield":
			var sp := PackedVector2Array([P.call(0.5, 0.08), P.call(0.86, 0.2), P.call(0.8, 0.6), P.call(0.5, 0.92), P.call(0.2, 0.6), P.call(0.14, 0.2), P.call(0.5, 0.08)])
			ci.draw_polyline(sp, col, w, true)
			ci.draw_polyline(PackedVector2Array([P.call(0.34, 0.5), P.call(0.46, 0.62), P.call(0.68, 0.36)]), col, w, true)
		"bug":
			Gfx.rr(ci, Rect2(P.call(0.32, 0.28), Vector2(s * 0.36, s * 0.52)), col, s * 0.18)
			ci.draw_circle(P.call(0.5, 0.24), s * 0.1, col)
			for k in [-1, 1]:
				for j in 3:
					var yy := 0.4 + j * 0.14
					ci.draw_line(P.call(0.5 + k * 0.16, yy), P.call(0.5 + k * 0.34, yy - 0.06 + j * 0.06), col, w * 0.7, true)
			ci.draw_line(P.call(0.12, 0.12), P.call(0.88, 0.88), Color("#ef5350"), w * 1.1, true)
		"broom":
			ci.draw_line(P.call(0.78, 0.1), P.call(0.48, 0.52), col, w, true)
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.4, 0.46), P.call(0.6, 0.6), P.call(0.42, 0.9), P.call(0.12, 0.72)]), col)
		"game_add", "game_del", "gamepad":
			Gfx.rr(ci, Rect2(P.call(0.08, 0.36), Vector2(s * 0.84, s * 0.4)), Color(0, 0, 0, 0), s * 0.2, col, int(w))
			ci.draw_line(P.call(0.24, 0.56), P.call(0.4, 0.56), col, w * 0.8)
			ci.draw_line(P.call(0.32, 0.48), P.call(0.32, 0.64), col, w * 0.8)
			ci.draw_circle(P.call(0.66, 0.52), s * 0.045, col)
			ci.draw_circle(P.call(0.76, 0.6), s * 0.045, col)
			if name != "gamepad":
				var bc := Color("#66bb6a") if name == "game_add" else Color("#ef5350")
				ci.draw_circle(P.call(0.8, 0.22), s * 0.17, bc)
				ci.draw_line(P.call(0.72, 0.22), P.call(0.88, 0.22), Color.WHITE, w * 0.8)
				if name == "game_add":
					ci.draw_line(P.call(0.8, 0.14), P.call(0.8, 0.3), Color.WHITE, w * 0.8)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.3, 0.18), P.call(0.82, 0.5), P.call(0.3, 0.82)]), col)
		"stop":
			Gfx.rr(ci, Rect2(P.call(0.24, 0.24), Vector2(s * 0.52, s * 0.52)), col, s * 0.08)
		"bench":
			ci.draw_arc(P.call(0.5, 0.62), s * 0.38, PI, TAU, 28, col, w, true)
			ci.draw_line(P.call(0.5, 0.62), P.call(0.72, 0.36), col, w, true)
			ci.draw_circle(P.call(0.5, 0.62), s * 0.06, col)
			for i in 5:
				var a := PI + PI * i / 4.0
				ci.draw_line(P.call(0.5, 0.62) + Vector2(cos(a), sin(a)) * s * 0.3, P.call(0.5, 0.62) + Vector2(cos(a), sin(a)) * s * 0.38, col, w * 0.6)
		"save":
			Gfx.rr(ci, Rect2(P.call(0.14, 0.14), Vector2(s * 0.72, s * 0.72)), Color(0, 0, 0, 0), s * 0.06, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.3, 0.14), Vector2(s * 0.36, s * 0.22)), col, 1)
			Gfx.rr(ci, Rect2(P.call(0.28, 0.54), Vector2(s * 0.44, s * 0.24)), col, 2)
		"journal":
			for i in 4:
				ci.draw_line(P.call(0.3, 0.22 + i * 0.19), P.call(0.86, 0.22 + i * 0.19), col, w, true)
				ci.draw_circle(P.call(0.16, 0.22 + i * 0.19), s * 0.05, col)
		"home":
			ci.draw_polyline(PackedVector2Array([P.call(0.1, 0.5), P.call(0.5, 0.14), P.call(0.9, 0.5)]), col, w, true)
			Gfx.rr(ci, Rect2(P.call(0.22, 0.46), Vector2(s * 0.56, s * 0.4)), Color(0, 0, 0, 0), 2, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.43, 0.62), Vector2(s * 0.14, s * 0.24)), col, 1)
		"wrench":
			ci.draw_line(P.call(0.2, 0.8), P.call(0.6, 0.4), col, w * 1.6, true)
			ci.draw_arc(P.call(0.68, 0.32), s * 0.18, PI * 0.9, PI * 2.6, 20, col, w * 1.2, true)
		"tower":
			Gfx.rr(ci, Rect2(P.call(0.26, 0.08), Vector2(s * 0.48, s * 0.84)), Color(0, 0, 0, 0), s * 0.07, col, int(w))
			ci.draw_line(P.call(0.36, 0.24), P.call(0.64, 0.24), col, w * 0.8)
			ci.draw_line(P.call(0.36, 0.36), P.call(0.64, 0.36), col, w * 0.8)
			ci.draw_circle(P.call(0.5, 0.74), s * 0.07, col)
		"cart":
			ci.draw_polyline(PackedVector2Array([P.call(0.06, 0.18), P.call(0.2, 0.18), P.call(0.3, 0.64), P.call(0.8, 0.64), P.call(0.9, 0.3), P.call(0.24, 0.3)]), col, w, true)
			ci.draw_circle(P.call(0.36, 0.82), s * 0.07, col)
			ci.draw_circle(P.call(0.74, 0.82), s * 0.07, col)
		"box":
			ci.draw_polyline(PackedVector2Array([P.call(0.1, 0.3), P.call(0.5, 0.12), P.call(0.9, 0.3), P.call(0.9, 0.74), P.call(0.5, 0.92), P.call(0.1, 0.74), P.call(0.1, 0.3), P.call(0.5, 0.48), P.call(0.9, 0.3)]), col, w, true)
			ci.draw_line(P.call(0.5, 0.48), P.call(0.5, 0.92), col, w, true)
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + PI * i / 5.0
				var rad := s * (0.44 if i % 2 == 0 else 0.19)
				pts.append(P.call(0.5, 0.54) + Vector2(cos(a), sin(a)) * rad)
			ci.draw_colored_polygon(pts, col)
		"coin":
			ci.draw_circle(P.call(0.5, 0.5), s * 0.42, col)
			ci.draw_circle(P.call(0.5, 0.5), s * 0.32, col.darkened(0.2))
			Gfx.text(ci, P.call(0.0, 0.68), "$", int(s * 0.5), col.lightened(0.5), s, HORIZONTAL_ALIGNMENT_CENTER, true)
		"fish":
			var pts := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				pts.append(P.call(0.44, 0.5) + Vector2(cos(a) * s * 0.3, sin(a) * s * 0.18))
			ci.draw_colored_polygon(pts, col)
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.7, 0.5), P.call(0.94, 0.28), P.call(0.94, 0.72)]), col)
			ci.draw_circle(P.call(0.3, 0.46), s * 0.04, Color(0, 0, 0, 0.7))
		"calendar":
			Gfx.rr(ci, Rect2(P.call(0.12, 0.2), Vector2(s * 0.76, s * 0.66)), Color(0, 0, 0, 0), s * 0.08, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.12, 0.2), Vector2(s * 0.76, s * 0.18)), col, s * 0.06)
			ci.draw_line(P.call(0.32, 0.1), P.call(0.32, 0.28), col, w)
			ci.draw_line(P.call(0.68, 0.1), P.call(0.68, 0.28), col, w)
		"temp":
			Gfx.rr(ci, Rect2(P.call(0.4, 0.08), Vector2(s * 0.2, s * 0.6)), Color(0, 0, 0, 0), s * 0.1, col, int(w * 0.8))
			ci.draw_circle(P.call(0.5, 0.76), s * 0.16, col)
		"bolt":
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.58, 0.06), P.call(0.22, 0.56), P.call(0.48, 0.56), P.call(0.4, 0.94), P.call(0.78, 0.42), P.call(0.52, 0.42)]), col)
		"disk":
			Gfx.rr(ci, Rect2(P.call(0.12, 0.2), Vector2(s * 0.76, s * 0.6)), Color(0, 0, 0, 0), s * 0.08, col, int(w))
			ci.draw_arc(P.call(0.44, 0.5), s * 0.18, 0, TAU, 20, col, w * 0.8, true)
			ci.draw_circle(P.call(0.76, 0.7), s * 0.04, col)
		"check":
			ci.draw_polyline(PackedVector2Array([P.call(0.18, 0.52), P.call(0.42, 0.76), P.call(0.84, 0.28)]), col, w * 1.2, true)
		"next":
			ci.draw_polyline(PackedVector2Array([P.call(0.3, 0.16), P.call(0.66, 0.5), P.call(0.3, 0.84)]), col, w * 1.2, true)
		"prev":
			ci.draw_polyline(PackedVector2Array([P.call(0.7, 0.16), P.call(0.34, 0.5), P.call(0.7, 0.84)]), col, w * 1.2, true)
		"sun":
			ci.draw_circle(P.call(0.5, 0.5), s * 0.2, col)
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.3, P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.42, col, w * 0.8, true)
		"help":
			ci.draw_arc(P.call(0.5, 0.36), s * 0.18, PI, TAU + PI * 0.35, 20, col, w, true)
			ci.draw_line(P.call(0.56, 0.52), P.call(0.5, 0.64), col, w, true)
			ci.draw_circle(P.call(0.5, 0.82), s * 0.06, col)
		"exit":
			Gfx.rr(ci, Rect2(P.call(0.14, 0.14), Vector2(s * 0.44, s * 0.72)), Color(0, 0, 0, 0), s * 0.05, col, int(w))
			ci.draw_line(P.call(0.42, 0.5), P.call(0.9, 0.5), col, w, true)
			ci.draw_polyline(PackedVector2Array([P.call(0.74, 0.34), P.call(0.9, 0.5), P.call(0.74, 0.66)]), col, w, true)
		"new":
			ci.draw_line(P.call(0.5, 0.16), P.call(0.5, 0.84), col, w * 1.2, true)
			ci.draw_line(P.call(0.16, 0.5), P.call(0.84, 0.5), col, w * 1.2, true)
		"cpu":
			Gfx.rr(ci, Rect2(P.call(0.18, 0.18), Vector2(s * 0.64, s * 0.64)), Color(0, 0, 0, 0), s * 0.08, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.34, 0.34), Vector2(s * 0.32, s * 0.32)), col, s * 0.04)
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.18, 0.18), P.call(0.34, 0.18), P.call(0.18, 0.34)]), col)
		"mobo":
			Gfx.rr(ci, Rect2(P.call(0.1, 0.1), Vector2(s * 0.8, s * 0.8)), Color(0, 0, 0, 0), s * 0.06, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.24, 0.22), Vector2(s * 0.24, s * 0.24)), col, 2)
			ci.draw_line(P.call(0.62, 0.2), P.call(0.62, 0.52), col, w * 0.8)
			ci.draw_line(P.call(0.74, 0.2), P.call(0.74, 0.52), col, w * 0.8)
			ci.draw_line(P.call(0.22, 0.66), P.call(0.7, 0.66), col, w)
			ci.draw_line(P.call(0.22, 0.78), P.call(0.6, 0.78), col, w * 0.7)
		"ram":
			Gfx.rr(ci, Rect2(P.call(0.06, 0.3), Vector2(s * 0.88, s * 0.34)), Color(0, 0, 0, 0), s * 0.04, col, int(w))
			for i in 4:
				Gfx.rr(ci, Rect2(P.call(0.14 + i * 0.19, 0.37), Vector2(s * 0.12, s * 0.16)), col, 1)
			for i in 6:
				ci.draw_line(P.call(0.12 + i * 0.14, 0.66), P.call(0.12 + i * 0.14, 0.76), col, w * 0.6)
		"gpu":
			Gfx.rr(ci, Rect2(P.call(0.08, 0.26), Vector2(s * 0.84, s * 0.44)), Color(0, 0, 0, 0), s * 0.08, col, int(w))
			ci.draw_arc(P.call(0.34, 0.48), s * 0.13, 0, TAU, 18, col, w * 0.8, true)
			ci.draw_arc(P.call(0.66, 0.48), s * 0.13, 0, TAU, 18, col, w * 0.8, true)
			ci.draw_line(P.call(0.26, 0.74), P.call(0.6, 0.74), col, w)
		"psu":
			Gfx.rr(ci, Rect2(P.call(0.08, 0.2), Vector2(s * 0.84, s * 0.6)), Color(0, 0, 0, 0), s * 0.06, col, int(w))
			ci.draw_arc(P.call(0.4, 0.5), s * 0.18, 0, TAU, 20, col, w * 0.8, true)
			ci.draw_line(P.call(0.28, 0.5), P.call(0.52, 0.5), col, w * 0.6)
			ci.draw_line(P.call(0.4, 0.38), P.call(0.4, 0.62), col, w * 0.6)
			ci.draw_colored_polygon(PackedVector2Array([P.call(0.74, 0.3), P.call(0.66, 0.52), P.call(0.74, 0.52), P.call(0.7, 0.7), P.call(0.82, 0.44), P.call(0.74, 0.44)]), col)
		"fan":
			ci.draw_arc(P.call(0.5, 0.5), s * 0.4, 0, TAU, 28, col, w, true)
			for i in 4:
				var a := TAU * i / 4.0
				ci.draw_colored_polygon(PackedVector2Array([P.call(0.5, 0.5), P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.32, P.call(0.5, 0.5) + Vector2(cos(a + 0.7), sin(a + 0.7)) * s * 0.26]), col)
		"key":
			ci.draw_arc(P.call(0.3, 0.5), s * 0.16, 0, TAU, 20, col, w, true)
			ci.draw_line(P.call(0.46, 0.5), P.call(0.9, 0.5), col, w, true)
			ci.draw_line(P.call(0.78, 0.5), P.call(0.78, 0.66), col, w)
			ci.draw_line(P.call(0.66, 0.5), P.call(0.66, 0.62), col, w)
		"building":
			Gfx.rr(ci, Rect2(P.call(0.2, 0.12), Vector2(s * 0.36, s * 0.78)), Color(0, 0, 0, 0), s * 0.04, col, int(w))
			Gfx.rr(ci, Rect2(P.call(0.56, 0.4), Vector2(s * 0.26, s * 0.5)), Color(0, 0, 0, 0), s * 0.04, col, int(w))
			for i in 3:
				ci.draw_line(P.call(0.3, 0.26 + i * 0.16), P.call(0.46, 0.26 + i * 0.16), col, w * 0.7)
			ci.draw_line(P.call(0.62, 0.55), P.call(0.76, 0.55), col, w * 0.7)
		"map":
			ci.draw_polyline(PackedVector2Array([P.call(0.08, 0.24), P.call(0.36, 0.12), P.call(0.64, 0.24), P.call(0.92, 0.12), P.call(0.92, 0.76), P.call(0.64, 0.88), P.call(0.36, 0.76), P.call(0.08, 0.88), P.call(0.08, 0.24)]), col, w, true)
			ci.draw_line(P.call(0.36, 0.12), P.call(0.36, 0.76), col, w * 0.7)
			ci.draw_line(P.call(0.64, 0.24), P.call(0.64, 0.88), col, w * 0.7)
		"person":
			ci.draw_circle(P.call(0.5, 0.3), s * 0.17, col)
			Gfx.rr(ci, Rect2(P.call(0.22, 0.52), Vector2(s * 0.56, s * 0.38)), col, s * 0.18)
		"close":
			ci.draw_line(P.call(0.24, 0.24), P.call(0.76, 0.76), col, w * 1.2, true)
			ci.draw_line(P.call(0.76, 0.24), P.call(0.24, 0.76), col, w * 1.2, true)
		_:
			ci.draw_circle(P.call(0.5, 0.5), s * 0.3, col)
