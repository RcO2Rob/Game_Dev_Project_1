extends Control

var weapon_kind := "wood"
var durability := 0
var maximum := 1


func set_weapon_status(kind: String, current: int, max_value: int) -> void:
	weapon_kind = kind
	durability = current
	maximum = maxi(max_value, 1)
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(0, 0, 46, 40)
	draw_rect(frame, Color(0.015, 0.09, 0.14, 0.94), true)
	draw_rect(frame, Color(0.35, 0.82, 0.88, 0.95), false, 2.0)
	var blade_color := Color("a96832") if weapon_kind == "wood" else (Color("48cbe6") if weapon_kind == "diamond" else Color("94a8b0"))
	var edge_color := Color("e6b875") if weapon_kind == "wood" else Color("ecffff")
	draw_line(Vector2(12, 29), Vector2(34, 8), blade_color, 7.0, true)
	draw_line(Vector2(14, 26), Vector2(33, 8), edge_color, 1.5, true)
	draw_line(Vector2(9, 20), Vector2(18, 30), Color("5b3b24"), 4.0, true)
	draw_line(Vector2(8, 31), Vector2(13, 36), Color("3f2819"), 5.0, true)

	var bar_background := Rect2(0, 45, 70, 8)
	draw_rect(bar_background, Color(0.02, 0.12, 0.12, 0.95), true)
	draw_rect(bar_background, Color(0.3, 0.58, 0.55, 0.9), false, 1.0)
	var ratio := clampf(float(durability) / float(maximum), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(2, 47, 66.0 * ratio, 4), Color("55df75"), true)
