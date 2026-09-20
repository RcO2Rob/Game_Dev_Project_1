extends CharacterBody2D

@export var detection_range := 280.0
@export var vertical_vision_range := 105.0
@export var chase_speed := 82.0
@export var patrol_speed := 28.0
@export var patrol_distance := 74.0
@export var attack_range := 58.0
@export var attack_cooldown := 1.15
@export var gravity := 420.0
@export var can_be_stomped := true

var _player: CharacterBody2D
var _start_x := 0.0
var _direction := 1.0
var _cooldown_left := 0.0
var _walk_time := 0.0
var _attacking := false
var _defeated := false
var _captured_in_bubble := false
var _normal_collision_mask := 3


func _ready() -> void:
	_start_x = global_position.x
	_normal_collision_mask = collision_mask
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	if _defeated or _captured_in_bubble:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_walk_time += delta
	velocity.y = minf(velocity.y + gravity * delta, 300.0)

	var sees_player := _can_see_player()
	if _attacking:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	elif sees_player:
		var horizontal_distance := _player.global_position.x - global_position.x
		# Keep the current facing when both bodies are nearly aligned. Without this
		# dead zone, tiny position changes can mirror the lobster every frame.
		if absf(horizontal_distance) > 8.0:
			_face(signf(horizontal_distance))
		if absf(horizontal_distance) > attack_range:
			velocity.x = _direction * chase_speed
		elif _cooldown_left <= 0.0:
			velocity.x = 0.0
			_attack_player()
		else:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	else:
		# Only reverse at the boundary the lobster is currently walking toward.
		# An absolute-distance check would remain true for several frames and
		# repeatedly flip the sprite left/right.
		if _direction > 0.0 and global_position.x >= _start_x + patrol_distance:
			_face(-1.0)
		elif _direction < 0.0 and global_position.x <= _start_x - patrol_distance:
			_face(1.0)
		velocity.x = _direction * patrol_speed

	move_and_slide()
	if is_on_wall() and not sees_player and get_wall_normal().x * _direction < -0.1:
		_face(-_direction)
	_animate_walk(sees_player)


func _can_see_player() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(_player):
		return false
	var offset := _player.global_position - global_position
	if absf(offset.x) > detection_range or absf(offset.y) > vertical_vision_range:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position, 1, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player


func _face(direction: float) -> void:
	if is_zero_approx(direction):
		return
	var next_direction := signf(direction)
	if is_equal_approx(next_direction, _direction):
		return
	_direction = next_direction
	# Mirror only the artwork through an explicit basis. Flipping the root's
	# negative scale makes Godot decompose it into rotation/scale components,
	# which can produce visible snapping and also touches the physics transform.
	var visual_origin: Vector2 = $Visual.position
	$Visual.transform = Transform2D(
		Vector2(_direction, 0.0),
		Vector2(0.0, 1.0),
		visual_origin
	)


func _animate_walk(chasing: bool) -> void:
	var speed := 13.0 if chasing else 7.0
	var stride := sin(_walk_time * speed) * (0.2 if chasing else 0.11)
	$Visual/TopLegs.rotation = stride
	$Visual/BottomLegs.rotation = -stride
	if not _attacking:
		var claw_bob := sin(_walk_time * speed * 0.5) * 0.06
		$Visual/TopClaw.rotation = -0.08 + claw_bob
		$Visual/BottomClaw.rotation = 0.08 - claw_bob


func _attack_player() -> void:
	if _attacking:
		return
	_attacking = true
	_cooldown_left = attack_cooldown
	var snap := create_tween().set_parallel(true)
	snap.set_trans(Tween.TRANS_BACK)
	snap.set_ease(Tween.EASE_OUT)
	snap.tween_property($Visual/TopClaw, "rotation", 0.38, 0.16)
	snap.tween_property($Visual/BottomClaw, "rotation", -0.38, 0.16)
	snap.tween_property($Visual, "position:x", 7.0 * _direction, 0.16)
	await snap.finished
	if _defeated or _captured_in_bubble:
		return
	if is_instance_valid(_player):
		var offset := _player.global_position - global_position
		if absf(offset.x) <= attack_range + 24.0 and absf(offset.y) <= 62.0:
			_player.take_damage()
	var recover := create_tween().set_parallel(true)
	recover.set_trans(Tween.TRANS_QUAD)
	recover.set_ease(Tween.EASE_OUT)
	recover.tween_property($Visual/TopClaw, "rotation", -0.08, 0.2)
	recover.tween_property($Visual/BottomClaw, "rotation", 0.08, 0.2)
	recover.tween_property($Visual, "position:x", 0.0, 0.2)
	await recover.finished
	_attacking = false


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
	_attacking = false
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
	$Visual.position.x = 0.0


func _defeat(was_stomped: bool) -> void:
	if _defeated:
		return
	_defeated = true
	_attacking = false
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		if was_stomped:
			audio_manager.play_enemy_stomp()
		else:
			audio_manager.play_enemy_hit()
	collision_layer = 0
	collision_mask = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale:y", 0.08, 0.14)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
