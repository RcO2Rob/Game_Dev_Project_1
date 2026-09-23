extends CharacterBody2D

@export var can_be_stomped := true
@export var horizontal_range := 45.0
@export var vertical_range := 52.0
@export var drift_speed := 1.35

var _start_position := Vector2.ZERO
var _time := 0.0
var _defeated := false
var _captured_in_bubble := false


func _ready() -> void:
	_start_position = global_position


func _physics_process(delta: float) -> void:
	if _defeated or _captured_in_bubble:
		return
	_time += delta * drift_speed
	global_position = _start_position + Vector2(
		sin(_time * 0.7) * horizontal_range,
		sin(_time) * vertical_range
	)


func hit_by_rock() -> void:
	_defeat()


func hit_by_weapon() -> void:
	_defeat()


func stomp() -> void:
	_defeat(true)


func capture_in_bubble() -> bool:
	if _defeated or _captured_in_bubble:
		return false
	_captured_in_bubble = true
	collision_layer = 0
	collision_mask = 0
	return true


func release_from_bubble() -> void:
	if _defeated:
		return
	_captured_in_bubble = false
	collision_layer = 4
	collision_mask = 0
	_start_position = global_position
	_time = 0.0


func _defeat(was_stomped := false) -> void:
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
	tween.tween_property(self, "scale", Vector2(0.2, 1.35), 0.14)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
