extends Node2D

@export var area_size := Vector2(2304.0, 648.0)
@export_range(1, 100, 1) var bubble_count := 38
@export var min_rise_speed := 11.0
@export var max_rise_speed := 30.0

var _bubbles: Array[Dictionary] = []
var _time := 0.0
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.seed = 20260917
	for index in range(bubble_count):
		_bubbles.append(_new_bubble(true, index))
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	for index in range(_bubbles.size()):
		var bubble := _bubbles[index]
		var bubble_position: Vector2 = bubble.position
		bubble_position.y -= float(bubble.speed) * delta
		bubble_position.x += sin(_time * float(bubble.wobble_speed) + float(bubble.phase)) * float(bubble.drift) * delta
		if bubble_position.y < -area_size.y - 12.0:
			bubble = _new_bubble(false, index)
		else:
			bubble_position.x = wrapf(bubble_position.x, 0.0, area_size.x)
			bubble.position = bubble_position
		_bubbles[index] = bubble
	queue_redraw()


func _draw() -> void:
	for bubble in _bubbles:
		var bubble_position: Vector2 = bubble.position
		var radius := float(bubble.radius)
		draw_circle(bubble_position, radius, Color(0.55, 0.92, 1.0, 0.08))
		draw_arc(bubble_position, radius, 0.0, TAU, 18, Color(0.7, 0.96, 1.0, 0.42), 1.2, true)
		draw_circle(bubble_position + Vector2(-radius * 0.32, -radius * 0.34), maxf(0.8, radius * 0.16), Color(0.94, 1.0, 1.0, 0.62))


func _new_bubble(spread_vertically: bool, index: int) -> Dictionary:
	var vertical_position := _random.randf_range(-area_size.y, 0.0) if spread_vertically else _random.randf_range(-8.0, 4.0)
	return {
		"position": Vector2(_random.randf_range(20.0, area_size.x - 20.0), vertical_position),
		"radius": _random.randf_range(2.2, 6.2),
		"speed": _random.randf_range(min_rise_speed, max_rise_speed),
		"drift": _random.randf_range(2.0, 7.0),
		"wobble_speed": _random.randf_range(0.7, 1.8),
		"phase": float(index) * 0.71 + _random.randf_range(0.0, TAU),
	}
