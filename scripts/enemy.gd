extends CharacterBody2D

@export var move_speed := 45.0
@export var patrol_distance := 110.0
@export var can_be_stomped := true
@export var gravity := 420.0

var _start_x := 0.0
var _direction := -1.0
var _defeated := false
var _captured_in_bubble := false
var _normal_collision_mask := 1


func _ready() -> void:
	_start_x = global_position.x
	_normal_collision_mask = collision_mask


func _physics_process(delta: float) -> void:
	if _defeated or _captured_in_bubble:
		return

	velocity.y = minf(velocity.y + gravity * delta, 300.0)
	velocity.x = _direction * move_speed
	move_and_slide()

	if move_speed > 0.0 and (is_on_wall() or absf(global_position.x - _start_x) >= patrol_distance):
		_direction *= -1.0
		scale.x = absf(scale.x) * _direction


func hit_by_rock() -> void:
	_defeat(false)


func hit_by_weapon() -> void:
	_defeat(false)


func stomp() -> void:
	if can_be_stomped:
		_defeat(true)


func capture_in_bubble() -> bool:
	if _defeated or _captured_in_bubble:
		return false
	_captured_in_bubble = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	return true


func release_from_bubble() -> void:
	if _defeated:
		return
	_captured_in_bubble = false
	collision_layer = 4
	collision_mask = _normal_collision_mask
	_start_x = global_position.x
	velocity = Vector2.ZERO


func _defeat(was_stomped: bool) -> void:
	if _defeated:
		return
	_defeated = true
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		if was_stomped:
			audio_manager.play_enemy_stomp()
		else:
			audio_manager.play_enemy_hit()
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(scale.x * 1.25, 0.1), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)
