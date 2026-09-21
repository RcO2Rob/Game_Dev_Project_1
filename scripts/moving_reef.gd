extends AnimatableBody2D

@export var travel := Vector2(85, 0)
@export var period := 5.5
@export var phase := 0.0
var _origin := Vector2.ZERO
var _time := 0.0

func _ready() -> void:
	_origin = position

func _physics_process(delta: float) -> void:
	_time += delta
	position = _origin + travel * sin(_time * TAU / period + phase)
