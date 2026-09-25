extends Area2D

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	$Visual.position.y = sin(_time * 2.1) * 5.0
	$Visual.scale = Vector2.ONE * (1.0 + sin(_time * 2.1) * 0.04)
