extends Node2D

@export var sway_speed := 1.15
@export var sway_amount := 0.055

var _time := 0.0
var _phase := 0.0


func _ready() -> void:
	_phase = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	_time += delta
	var wave := sin(_time * sway_speed + _phase)
	$SwayPivot.rotation = wave * sway_amount
	$SwayPivot.scale.x = 1.0 + wave * 0.025
