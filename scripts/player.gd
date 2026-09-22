extends CharacterBody2D

const WOOD_SWORD_PICKUP_SCENE := preload("res://scenes/items/wood_sword_pickup.tscn")
const STONE_SWORD_PICKUP_SCENE := preload("res://scenes/items/stone_sword_pickup.tscn")
const WOOD_SWORD_DURABILITY := 5
const STONE_SWORD_DURABILITY := 15

@export_category("Horizontal movement")
@export var max_horizontal_speed := 210.0
@export var water_acceleration := 600.0
@export var water_deceleration := 420.0
@export var ground_acceleration := 1200.0
@export var ground_deceleration := 1600.0

@export_category("Vertical movement")
@export var sink_gravity := 340.0
@export var swim_impulse := 185.0
@export var max_rise_speed := 230.0
@export var max_fall_speed := 300.0
@export var dive_speed := 360.0

@export_category("Input feel")
@export var swim_buffer_time := 0.10

@export_category("Player stats")
@export var max_health := 3
@export var max_swim_jumps := 3
@export var damage_invulnerability_time := 1.0

@export_category("Rock interaction")
@export var throw_speed := 430.0
@export var throw_lift := 90.0

var _swim_buffer := 0.0
var _spawn_position := Vector2.ZERO
var _facing := 1.0
var _held_rock: RigidBody2D
var _captured_in_bubble := false
var _bubble_time_left := 0.0
var _swim_jumps_remaining := 3
var _invulnerability_left := 0.0
var _visual_time := 0.0
var _is_attacking := false
var _sword_hit_targets: Dictionary = {}

var current_health := 3
var coin_count := 0
var diamond_count := 0
var has_sword := false
var sword_kind := ""
var sword_durability := 0
var sword_max_durability := 0


func _ready() -> void:
	_spawn_position = global_position
	current_health = max_health
	_swim_jumps_remaining = max_swim_jumps
	$Body/SwordPivot/SwordHitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	$Body/SwordPivot/SwordHitbox.area_entered.connect(_on_sword_hitbox_area_entered)
	get_node("/root/RunState").restore(self)


func _physics_process(delta: float) -> void:
	_animate_character(delta)
	_update_invulnerability(delta)
	if _captured_in_bubble:
		_float_in_bubble(delta)
		return

	_update_swim_buffer(delta)
	_apply_horizontal_movement(delta)
	_apply_vertical_movement(delta)
	# A tall enemy can meet the player immediately after the upward arc ends,
	# while the underwater fall speed is still very small. Any downward motion
	# should count as a stomp when the collision normal confirms a top landing.
	var was_falling := velocity.y > 0.0
	move_and_slide()
	if is_on_floor():
		_swim_jumps_remaining = max_swim_jumps
	_handle_enemy_collisions(was_falling)
	if _is_attacking:
		_damage_sword_overlaps()

	if global_position.y > 760.0:
		die()


func _animate_character(delta: float) -> void:
	_visual_time += delta
	var movement_amount := clampf(absf(velocity.x) / max_horizontal_speed, 0.0, 1.0)
	var grounded := is_on_floor()
	var leg_back_target := 0.0
	var leg_front_target := 0.0
	var arm_back_target := 0.16
	var arm_front_target := -0.18

	if grounded and movement_amount > 0.08:
		var walk_phase := sin(_visual_time * lerpf(7.0, 11.0, movement_amount))
		leg_back_target = walk_phase * 0.58
		leg_front_target = -walk_phase * 0.58
		arm_back_target = 0.16 - walk_phase * 0.22
		arm_front_target = -0.18 + walk_phase * 0.18
		$Body.position.y = absf(cos(_visual_time * 9.0)) * 1.3
	elif not grounded:
		$Body.position.y = sin(_visual_time * 3.0) * 0.45
		if velocity.y < -25.0:
			# 上浮时收腿并把双臂向前，形成清楚的跳跃轮廓。
			leg_back_target = -0.52
			leg_front_target = 0.38
			arm_back_target = 0.42
			arm_front_target = -0.42
		else:
			# 下落时重新伸展脚蹼，落地动作不会显得僵硬。
			leg_back_target = 0.16
			leg_front_target = -0.18
			arm_back_target = 0.05
			arm_front_target = -0.08
	else:
		$Body.position.y = sin(_visual_time * 2.2) * 0.7

	var pose_blend := minf(delta * 12.0, 1.0)
	$Body/BackLeg.rotation = lerp_angle($Body/BackLeg.rotation, leg_back_target, pose_blend)
	$Body/FrontLeg.rotation = lerp_angle($Body/FrontLeg.rotation, leg_front_target, pose_blend)
	$Body/BackArm.rotation = lerp_angle($Body/BackArm.rotation, arm_back_target, pose_blend)
	$Body/FrontArm.rotation = lerp_angle($Body/FrontArm.rotation, arm_front_target, pose_blend)

	var target_tilt := 0.0
	if velocity.y < -80.0:
		target_tilt = -0.1 * _facing
	elif velocity.y > 150.0:
		target_tilt = 0.13 * _facing
	$Body.rotation = lerp_angle($Body.rotation, target_tilt, minf(delta * 7.0, 1.0))


func _handle_enemy_collisions(was_falling: bool) -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var enemy := collision.get_collider()
		if not enemy.is_in_group("enemy"):
			continue

		var landed_on_top := was_falling and collision.get_normal().y < -0.55
		if landed_on_top and enemy.can_be_stomped:
			enemy.stomp()
			velocity.y = -145.0
		else:
			take_damage()
		return


func _unhandled_input(event: InputEvent) -> void:
	if _captured_in_bubble:
		return
	if event.is_action_pressed("interact"):
		if has_sword:
			drop_sword()
		elif is_instance_valid(_held_rock):
			throw_rock()
		else:
			pick_up_nearest_item()
	elif event.is_action_pressed("attack"):
		attack_with_sword()


func equip_sword(kind := "wood", durability := -1) -> bool:
	if has_sword:
		return false
	if is_instance_valid(_held_rock):
		_held_rock.drop_from_hand()
		_held_rock = null
	sword_kind = "stone" if kind == "stone" else "wood"
	sword_max_durability = STONE_SWORD_DURABILITY if sword_kind == "stone" else WOOD_SWORD_DURABILITY
	sword_durability = sword_max_durability if durability < 0 else clampi(durability, 1, sword_max_durability)
	has_sword = true
	_apply_sword_visual()
	$Body/SwordPivot.visible = true
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_weapon_pickup()
	return true


func drop_sword() -> RigidBody2D:
	if not has_sword or _is_attacking or _captured_in_bubble:
		return null
	var dropped_kind := sword_kind
	var dropped_durability := sword_durability
	_clear_sword_state()
	var sword_scene: PackedScene = STONE_SWORD_PICKUP_SCENE if dropped_kind == "stone" else WOOD_SWORD_PICKUP_SCENE
	var dropped_sword := sword_scene.instantiate() as RigidBody2D
	dropped_sword.set_weapon_state(dropped_kind, dropped_durability)
	dropped_sword.position = position + Vector2(_facing * 46.0, -10.0)
	get_parent().add_child(dropped_sword)
	dropped_sword.set_pickup_delay(0.55)
	dropped_sword.launch(Vector2(_facing * 105.0, -75.0))
	return dropped_sword


func lose_sword_on_damage() -> RigidBody2D:
	if not has_sword:
		return null
	var lost_kind := sword_kind
	var lost_durability := sword_durability
	_clear_sword_state()
	var sword_scene: PackedScene = STONE_SWORD_PICKUP_SCENE if lost_kind == "stone" else WOOD_SWORD_PICKUP_SCENE
	var lost_sword := sword_scene.instantiate() as RigidBody2D
	lost_sword.set_weapon_state(lost_kind, lost_durability)
	lost_sword.position = position + Vector2(_facing * 30.0, -12.0)
	get_parent().add_child(lost_sword)
	lost_sword.knock_away_and_disappear(Vector2(_facing * 180.0, -145.0))
	return lost_sword


func attack_with_sword() -> void:
	if not has_sword or _is_attacking or _captured_in_bubble:
		return
	_is_attacking = true
	_sword_hit_targets.clear()
	var sword_pivot := $Body/SwordPivot
	sword_pivot.rotation = -0.9
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_sword_swing()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_pivot, "rotation", 0.82, 0.11)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sword_pivot, "rotation", -0.78, 0.16)
	await tween.finished
	_is_attacking = false


func _on_sword_hitbox_body_entered(body: Node) -> void:
	_try_sword_hit(body)


func _on_sword_hitbox_area_entered(area: Area2D) -> void:
	_try_sword_hit(area)


func _damage_sword_overlaps() -> void:
	if not has_sword:
		return
	var hitbox := $Body/SwordPivot/SwordHitbox
	for body in hitbox.get_overlapping_bodies():
		_try_sword_hit(body)
	for area in hitbox.get_overlapping_areas():
		_try_sword_hit(area)

	var nearby_targets: Array[Node] = []
	nearby_targets.append_array(get_tree().get_nodes_in_group("enemy"))
	nearby_targets.append_array(get_tree().get_nodes_in_group("sword_target"))
	for target in nearby_targets:
		if not is_instance_valid(target) or not target is Node2D:
			continue
		var offset: Vector2 = target.global_position - global_position
		var is_in_front := offset.x * _facing >= -6.0
		if is_in_front and absf(offset.y) <= 48.0 and offset.length() <= 76.0:
			_try_sword_hit(target)


func _try_sword_hit(target: Node) -> void:
	if not has_sword or not _is_attacking or not target.has_method("hit_by_weapon"):
		return
	var target_id := target.get_instance_id()
	if _sword_hit_targets.has(target_id):
		return
	_sword_hit_targets[target_id] = true
	var uses_durability := false
	if target.is_in_group("enemy"):
		uses_durability = not bool(target.get("_defeated"))
	elif target.is_in_group("breakable_barrel"):
		uses_durability = not bool(target.get("_broken"))
	target.hit_by_weapon()
	if uses_durability:
		_consume_sword_durability()


func _consume_sword_durability() -> void:
	if not has_sword:
		return
	sword_durability = maxi(sword_durability - 1, 0)
	if sword_durability == 0:
		_clear_sword_state()


func _clear_sword_state() -> void:
	has_sword = false
	sword_kind = ""
	sword_durability = 0
	sword_max_durability = 0
	_is_attacking = false
	_sword_hit_targets.clear()
	$Body/SwordPivot.visible = false
	$Body/SwordPivot.rotation = -0.78


func _apply_sword_visual() -> void:
	if sword_kind == "wood":
		$Body/SwordPivot/Blade.color = Color("a96832")
		$Body/SwordPivot/BladeEdge.default_color = Color("e6b875")
		$Body/SwordPivot/Guard.color = Color("68401f")
		$Body/SwordPivot/Handle.color = Color("3f2819")
	else:
		$Body/SwordPivot/Blade.color = Color(0.58, 0.66, 0.69, 1)
		$Body/SwordPivot/BladeEdge.default_color = Color(0.88, 0.96, 0.97, 0.9)
		$Body/SwordPivot/Guard.color = Color(0.2, 0.27, 0.29, 1)
		$Body/SwordPivot/Handle.color = Color(0.39, 0.22, 0.12, 1)


func _update_swim_buffer(delta: float) -> void:
	_swim_buffer = maxf(_swim_buffer - delta, 0.0)
	if Input.is_action_just_pressed("swim") and _swim_jumps_remaining > 0:
		_swim_buffer = swim_buffer_time


func _apply_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := ground_acceleration if is_on_floor() else water_acceleration
	var deceleration := ground_deceleration if is_on_floor() else water_deceleration

	if not is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, direction * max_horizontal_speed, acceleration * delta)
		_facing = signf(direction)
		$Body.scale.x = absf($Body.scale.x) * _facing
		$HoldPoint.position.x = 34.0 * _facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _apply_vertical_movement(delta: float) -> void:
	velocity.y = minf(velocity.y + sink_gravity * delta, max_fall_speed)

	if Input.is_action_just_pressed("dive"):
		velocity.y = dive_speed
	elif _swim_buffer > 0.0:
		_swim_buffer = 0.0
		_swim_jumps_remaining -= 1
		velocity.y = maxf(velocity.y - swim_impulse, -max_rise_speed)


func _update_invulnerability(delta: float) -> void:
	if _invulnerability_left <= 0.0:
		return
	_invulnerability_left = maxf(_invulnerability_left - delta, 0.0)
	modulate.a = 0.45 if int(Time.get_ticks_msec() / 90) % 2 == 0 else 1.0
	if _invulnerability_left <= 0.0:
		collision_mask = 13
		modulate.a = 1.0


func pick_up_nearest_item() -> void:
	if has_sword:
		return
	var nearest_item: RigidBody2D
	var nearest_distance := INF

	var pickup_candidates: Array[Node] = []
	pickup_candidates.append_array(get_tree().get_nodes_in_group("pickup_rock"))
	pickup_candidates.append_array(get_tree().get_nodes_in_group("pickup_weapon"))
	for body in pickup_candidates:
		if body is RigidBody2D and (body.is_in_group("pickup_rock") or body.is_in_group("pickup_weapon")):
			var distance := global_position.distance_squared_to(body.global_position)
			if distance <= 72.0 * 72.0 and distance < nearest_distance:
				nearest_distance = distance
				nearest_item = body

	if not is_instance_valid(nearest_item):
		return
	if nearest_item.is_in_group("pickup_weapon"):
		nearest_item.collect_by(self)
	else:
		_held_rock = nearest_item
		_held_rock.pick_up($HoldPoint)


func pick_up_nearest_rock() -> void:
	pick_up_nearest_item()


func throw_rock() -> void:
	var rock := _held_rock
	_held_rock = null
	rock.throw_from_hand(Vector2(_facing * throw_speed, -throw_lift))


func reset_to_spawn() -> void:
	if is_instance_valid(_held_rock):
		_held_rock.drop_from_hand()
		_held_rock = null
	_captured_in_bubble = false
	_bubble_time_left = 0.0
	_invulnerability_left = 0.0
	_swim_jumps_remaining = max_swim_jumps
	collision_mask = 13
	modulate.a = 1.0
	$BubbleShell.visible = false
	global_position = _spawn_position
	velocity = Vector2.ZERO


func capture_in_bubble() -> void:
	if _captured_in_bubble:
		return
	if is_instance_valid(_held_rock):
		_held_rock.drop_from_hand()
		_held_rock = null
	_captured_in_bubble = true
	_bubble_time_left = 3.2
	collision_mask = 0
	velocity = Vector2.ZERO
	$BubbleShell.visible = true


func _float_in_bubble(delta: float) -> void:
	_bubble_time_left -= delta
	var wobble := sin(Time.get_ticks_msec() * 0.006) * 22.0
	global_position += Vector2(wobble, -115.0) * delta
	if _bubble_time_left <= 0.0 or global_position.y < 45.0:
		die()


func die() -> void:
	current_health = max_health
	reset_to_spawn()


func take_damage(amount: int = 1) -> void:
	if _invulnerability_left > 0.0 or _captured_in_bubble:
		return
	lose_sword_on_damage()
	current_health -= amount
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_player_hurt()
	if current_health <= 0:
		die()
		return
	_invulnerability_left = damage_invulnerability_time
	collision_mask = 1
	velocity = Vector2(-_facing * 150.0, -120.0)


func add_coin(amount: int = 1) -> void:
	coin_count += amount


func add_diamond(amount: int = 1) -> void:
	diamond_count += amount
