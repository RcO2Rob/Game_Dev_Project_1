extends Area2D

@export var rise_speed := 105.0
@export var lifetime := 7.0
@export var payload_hold_time := 5.5

var _drift_speed := 0.0
var _wave_offset := 0.0
var _age := 0.0
var _payload_age := 0.0
var _payload: PhysicsBody2D


func _ready() -> void:
	_drift_speed = randf_range(-12.0, 12.0)
	_wave_offset = randf_range(0.0, TAU)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	global_position.y -= rise_speed * delta
	global_position.x += (_drift_speed + sin(_age * 2.4 + _wave_offset) * 8.0) * delta
	if is_instance_valid(_payload):
		_payload_age += delta
		_payload.global_position = global_position
		if _payload_age >= payload_hold_time:
			_release_payload()
			queue_free()
			return
	if _age >= lifetime or global_position.y < -60.0:
		_release_payload()
		queue_free()


func _on_body_entered(body: Node) -> void:
	if is_instance_valid(_payload) or not body.has_method("capture_in_bubble"):
		return
	if body.is_in_group("player"):
		body.capture_in_bubble()
		queue_free()
		return

	if body.capture_in_bubble():
		_payload = body
		_payload_age = 0.0
		set_deferred("monitoring", false)
		$RidePlatform/CollisionShape2D.set_deferred("disabled", false)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.14)


func hit_by_weapon() -> void:
	set_deferred("monitoring", false)
	_release_payload()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(queue_free)


func _release_payload() -> void:
	if not is_instance_valid(_payload):
		return
	var payload := _payload
	_payload = null
	$RidePlatform/CollisionShape2D.set_deferred("disabled", true)
	payload.global_position = global_position
	if payload.has_method("release_from_bubble"):
		payload.release_from_bubble()
