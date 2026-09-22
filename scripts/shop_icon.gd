extends Control

var kind := "sword"
var price := 0
var coin_price := 0
var coins := 0
var diamonds := 0
var health := 3
var max_health := 3

func configure(new_kind: String, new_price := 0, new_coin_price := 0) -> void:
	kind = new_kind
	price = new_price
	coin_price = new_coin_price
	queue_redraw()

func set_status(new_coins: int, new_diamonds: int, new_health: int, new_max_health: int) -> void:
	coins = new_coins
	diamonds = new_diamonds
	health = new_health
	max_health = new_max_health
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	if kind == "balance":
		_draw_balance()
	elif kind == "sword":
		_draw_sword(c + Vector2(0, -30), 1.15)
		_draw_price(c + Vector2(0, 30))
	elif kind == "heal":
		_draw_heart(c + Vector2(-12, -28), 1.25, true)
		draw_rect(Rect2(c + Vector2(18, -38), Vector2(8, 28)), Color("b7ffe1"))
		draw_rect(Rect2(c + Vector2(8, -28), Vector2(28, 8)), Color("b7ffe1"))
		_draw_price(c + Vector2(0, 30))
	elif kind == "heart_up":
		_draw_heart(c + Vector2(-14, -24), 1.08, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(22, -18), c + Vector2(39, -39), c + Vector2(56, -18)]), Color("8ef1d6"))
		draw_rect(Rect2(c + Vector2(34, -20), Vector2(10, 22)), Color("8ef1d6"))
		_draw_price(c + Vector2(0, 30))
	elif kind == "continue":
		_draw_shell(c + Vector2(-22, -10))
		draw_line(c + Vector2(28, -10), c + Vector2(70, -10), Color("d9fff7"), 8, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(70, -27), c + Vector2(93, -10), c + Vector2(70, 7)]), Color("d9fff7"))

func _draw_balance() -> void:
	var font := ThemeDB.fallback_font
	_draw_coin(Vector2(28, 35), 11)
	draw_string(font, Vector2(48, 43), str(coins), HORIZONTAL_ALIGNMENT_LEFT, 90, 22, Color("ffd98b"))
	_draw_diamond(Vector2(164, 35), 10)
	draw_string(font, Vector2(184, 43), str(diamonds), HORIZONTAL_ALIGNMENT_LEFT, 90, 22, Color("a9fbff"))
	draw_string(font, Vector2(302, 42), "1", HORIZONTAL_ALIGNMENT_LEFT, 18, 18, Color("d9fff7"))
	_draw_diamond(Vector2(326, 35), 8)
	draw_string(font, Vector2(340, 42), "=", HORIZONTAL_ALIGNMENT_LEFT, 18, 18, Color("d9fff7"))
	draw_string(font, Vector2(362, 42), "20", HORIZONTAL_ALIGNMENT_LEFT, 28, 18, Color("d9fff7"))
	_draw_coin(Vector2(400, 35), 8)
	for i in range(max_health):
		_draw_heart(Vector2(size.x - 145 + i * 28, 28), 0.55, i < health)

func _draw_price(center: Vector2) -> void:
	if coin_price > 0:
		var font := ThemeDB.fallback_font
		_draw_diamond(center + Vector2(-62, 0), 9)
		draw_string(font, center + Vector2(-48, 7), str(price), HORIZONTAL_ALIGNMENT_LEFT, 24, 18, Color("c9feff"))
		draw_string(font, center + Vector2(-20, 7), "/", HORIZONTAL_ALIGNMENT_LEFT, 16, 18, Color("d9fff7"))
		_draw_coin(center + Vector2(8, 0), 9)
		draw_string(font, center + Vector2(22, 7), str(coin_price), HORIZONTAL_ALIGNMENT_LEFT, 48, 18, Color("ffe3a3"))
		return
	var spacing := 28.0
	var start := center.x - float(price - 1) * spacing * 0.5
	for i in range(price):
		_draw_diamond(Vector2(start + i * spacing, center.y), 10)

func _draw_coin(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color("f6bd45"))
	draw_circle(center, radius * 0.67, Color("d98a24"))
	draw_arc(center, radius * 0.67, 0.0, TAU, 20, Color("ffe79a"), 2.0, true)

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
