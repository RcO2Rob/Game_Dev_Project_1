extends RigidBody2D

var _pickup_delay := 0.0
var _collected := false


func _physics_process(delta: float) -> void:
	_pickup_delay = maxf(_pickup_delay - delta, 0.0)


func set_pickup_delay(duration: float) -> void:
	_pickup_delay = maxf(duration, 0.0)


func launch(launch_velocity: Vector2) -> void:
	linear_velocity = launch_velocity
	angular_velocity = 0.0


func collect_by(body: Node) -> bool:
	if _collected or _pickup_delay > 0.0 or not body.has_method("equip_sword"):
		return false
	if not body.equip_sword():
		return false
	_collected = true
	collision_layer = 0
	collision_mask = 0
	freeze = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.45, 1.45), 0.13)
	tween.tween_property(self, "modulate:a", 0.0, 0.13)
	tween.chain().tween_callback(queue_free)
	return true
