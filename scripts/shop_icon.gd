extends Control

var kind := "sword"
var price := 0
var diamonds := 0
var health := 3
var max_health := 3

func configure(new_kind: String, new_price := 0) -> void:
	kind = new_kind
	price = new_price
	queue_redraw()

func set_status(new_diamonds: int, new_health: int, new_max_health: int) -> void:
	diamonds = new_diamonds
	health = new_health
	max_health = new_max_health
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	if kind == "balance":
		_draw_balance()
	elif kind == "sword":
		_draw_sword(c + Vector2(0, -14), 1.25)
		_draw_price(c + Vector2(0, 54))
	elif kind == "heal":
		_draw_heart(c + Vector2(-12, -12), 1.4, true)
		draw_rect(Rect2(c + Vector2(20, -22), Vector2(8, 30)), Color("b7ffe1"))
		draw_rect(Rect2(c + Vector2(9, -11), Vector2(30, 8)), Color("b7ffe1"))
		_draw_price(c + Vector2(0, 54))
	elif kind == "heart_up":
		_draw_heart(c + Vector2(-14, -4), 1.2, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(25, 2), c + Vector2(44, -20), c + Vector2(63, 2)]), Color("8ef1d6"))
		draw_rect(Rect2(c + Vector2(39, 0), Vector2(10, 24)), Color("8ef1d6"))
		_draw_price(c + Vector2(0, 54))
	elif kind == "continue":
		_draw_shell(c + Vector2(-22, 0))
		draw_line(c + Vector2(28, 0), c + Vector2(70, 0), Color("d9fff7"), 8, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(70, -17), c + Vector2(93, 0), c + Vector2(70, 17)]), Color("d9fff7"))

func _draw_balance() -> void:
	for i in range(mini(diamonds, 34)):
		var column := i % 17
		var row := i / 17
		_draw_diamond(Vector2(22 + column * 25, 20 + row * 28), 8)
	for i in range(max_health):
		_draw_heart(Vector2(size.x - 145 + i * 28, 28), 0.55, i < health)

func _draw_price(center: Vector2) -> void:
	var spacing := 28.0
	var start := center.x - float(price - 1) * spacing * 0.5
	for i in range(price):
		_draw_diamond(Vector2(start + i * spacing, center.y), 10)

func _draw_diamond(center: Vector2, radius: float) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.8, 0), center + Vector2(0, radius), center + Vector2(-radius * 0.8, 0)]), Color("55edf2"))
	draw_line(center + Vector2(0, -radius), center, Color("d7ffff"), 2, true)
	draw_line(center, center + Vector2(radius * 0.8, 0), Color("1988cf"), 2, true)

func _draw_heart(center: Vector2, scale_value: float, filled: bool) -> void:
	var points := PackedVector2Array([Vector2(0, 17), Vector2(-17, 1), Vector2(-16, -10), Vector2(-9, -16), Vector2(0, -10), Vector2(9, -16), Vector2(16, -10), Vector2(17, 1)])
	for i in range(points.size()):
		points[i] = center + points[i] * scale_value
	var color := Color("ff647c") if filled else Color(0.27, 0.36, 0.4, 0.75)
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array(Array(points) + [points[0]]), Color("ffd5dc") if filled else Color("6e8790"), 2, true)

func _draw_sword(center: Vector2, scale_value: float) -> void:
	draw_line(center + Vector2(-28, 22) * scale_value, center + Vector2(23, -27) * scale_value, Color("bcd1d3"), 10 * scale_value, true)
	draw_line(center + Vector2(-22, 16) * scale_value, center + Vector2(21, -25) * scale_value, Color("efffff"), 2 * scale_value, true)
	draw_line(center + Vector2(-31, 3) * scale_value, center + Vector2(-11, 24) * scale_value, Color("536a6d"), 7 * scale_value, true)
	draw_line(center + Vector2(-34, 25) * scale_value, center + Vector2(-19, 40) * scale_value, Color("76502f"), 8 * scale_value, true)

func _draw_shell(center: Vector2) -> void:
	draw_circle(center, 45, Color("f0a449"))
	draw_arc(center, 28, 0, TAU * 1.75, 32, Color("923f25"), 6, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(12, 28), center + Vector2(58, 42), center + Vector2(42, 12)]), Color("d97535"))
