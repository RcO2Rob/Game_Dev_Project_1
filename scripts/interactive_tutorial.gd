extends CanvasLayer

enum Step { MOVE_RIGHT, MOVE_LEFT, TRIPLE_JUMP, FIND_ROCK, PICK_UP_ROCK, THROW_ROCK, FIND_SWORD, PICK_UP_SWORD, SWING_SWORD, STOMP_HINT, BUBBLE_WARNING, DONE }

const PICKUP_PROMPT_DISTANCE := 64.0
const BUBBLE_HINT_LEAD := 150.0

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var bubble_hole: Node2D = get_parent().get_node("BubbleHole1")
@onready var prompt: Control = $Prompt
@onready var key_label: Label = $Prompt/Content/Rows/KeyBox/Key
@onready var instruction: Label = $Prompt/Content/Rows/Instruction

var step: int = Step.MOVE_RIGHT
var _last_jumps_remaining := 3
var _jump_count := 0
var _interact_key_pressed := false
var _attack_key_pressed := false
var _warning_time_left := 0.0
var _time := 0.0


func _ready() -> void:
	_last_jumps_remaining = player._swim_jumps_remaining
	_show_step()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or step == Step.DONE:
		return
	match step:
		Step.TRIPLE_JUMP:
			_track_jumps()
		Step.FIND_ROCK:
			if is_instance_valid(player._held_rock):
				_change_step(Step.THROW_ROCK)
			elif player.has_sword:
				key_label.text = "N"
				instruction.text = "Drop the sword to pick up a rock"
			else:
				var rock := _find_free_rock()
				if _target_is_nearest_pickup(rock):
					_change_step(Step.PICK_UP_ROCK)
				else:
					_show_direction(rock, "Move to a rock")
		Step.PICK_UP_ROCK:
			if is_instance_valid(player._held_rock):
				_change_step(Step.THROW_ROCK)
			elif player.has_sword or not _target_is_nearest_pickup(_find_free_rock()):
				_change_step(Step.FIND_ROCK)
		Step.THROW_ROCK:
			if _interact_key_pressed and not is_instance_valid(player._held_rock):
				_change_step(Step.FIND_SWORD)
			_interact_key_pressed = false
		Step.FIND_SWORD:
			if player.has_sword:
				_change_step(Step.SWING_SWORD)
			else:
				var sword := _find_wooden_sword()
				if _target_is_nearest_pickup(sword):
					_change_step(Step.PICK_UP_SWORD)
				else:
					_show_direction(sword, "Move to the wooden sword")
		Step.PICK_UP_SWORD:
			if player.has_sword:
				_change_step(Step.SWING_SWORD)
			elif is_instance_valid(player._held_rock):
				instruction.text = "Press N to release the rock first"
			elif not _target_is_nearest_pickup(_find_wooden_sword()):
				_change_step(Step.FIND_SWORD)
		Step.SWING_SWORD:
			if _attack_key_pressed and (player._is_attacking or not player.has_sword):
				_change_step(Step.STOMP_HINT)
			elif not player.has_sword:
				_change_step(Step.FIND_SWORD)
			_attack_key_pressed = false
		Step.STOMP_HINT:
			if player.global_position.x >= bubble_hole.global_position.x - BUBBLE_HINT_LEAD:
				_change_step(Step.BUBBLE_WARNING)
		Step.BUBBLE_WARNING:
			_warning_time_left -= delta
			if _warning_time_left <= 0.0:
				_change_step(Step.DONE)


func _process(delta: float) -> void:
	if not is_instance_valid(player) or step == Step.DONE:
		return
	_time += delta
	var screen_position: Vector2 = player.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	prompt.position = Vector2(
		clampf(screen_position.x - prompt.size.x * 0.5, 12.0, viewport_size.x - prompt.size.x - 12.0),
		clampf(screen_position.y - 162.0 + sin(_time * 5.0) * 7.0, 12.0, viewport_size.y - prompt.size.y - 12.0)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if step == Step.MOVE_RIGHT and event.is_action_pressed("move_right"):
		_change_step(Step.MOVE_LEFT)
	elif step == Step.MOVE_LEFT and event.is_action_pressed("move_left"):
		_last_jumps_remaining = player._swim_jumps_remaining
		_jump_count = 0
		_change_step(Step.TRIPLE_JUMP)
	elif step == Step.THROW_ROCK and event.is_action_pressed("interact"):
		_interact_key_pressed = true
	elif step == Step.SWING_SWORD and event.is_action_pressed("attack") and player.has_sword and not player._captured_in_bubble:
		_attack_key_pressed = true


func _track_jumps() -> void:
	var remaining: int = player._swim_jumps_remaining
	if remaining > _last_jumps_remaining:
		_jump_count = 0
		_show_step()
	elif remaining < _last_jumps_remaining:
		_jump_count += _last_jumps_remaining - remaining
		if _jump_count >= 3:
			_change_step(Step.FIND_ROCK)
		else:
			_show_step()
	_last_jumps_remaining = remaining


func _find_free_rock() -> RigidBody2D:
	var nearest: RigidBody2D
	var best_distance := INF
	for body in get_tree().get_nodes_in_group("pickup_rock"):
		if body is RigidBody2D and not body.freeze and not body.is_queued_for_deletion():
			var distance: float = player.global_position.distance_squared_to(body.global_position)
			if distance < best_distance:
				nearest = body
				best_distance = distance
	return nearest


func _find_wooden_sword() -> RigidBody2D:
	var nearest: RigidBody2D
	var best_distance := INF
	for body in get_tree().get_nodes_in_group("pickup_weapon"):
		if body is RigidBody2D and body.weapon_kind == "wood" and not body._collected and not body.is_queued_for_deletion():
			var distance: float = player.global_position.distance_squared_to(body.global_position)
			if distance < best_distance:
				nearest = body
				best_distance = distance
	return nearest


func _target_is_nearest_pickup(target: RigidBody2D) -> bool:
	if not is_instance_valid(target):
		return false
	var distance_squared: float = player.global_position.distance_squared_to(target.global_position)
	if distance_squared > PICKUP_PROMPT_DISTANCE * PICKUP_PROMPT_DISTANCE:
		return false
	var candidates: Array[Node] = get_tree().get_nodes_in_group("pickup_rock") + get_tree().get_nodes_in_group("pickup_weapon")
	for body in candidates:
		if body is RigidBody2D and body != target and not body.is_queued_for_deletion():
			if body.global_position.distance_squared_to(player.global_position) < distance_squared:
				return false
	return true


func _show_direction(target: RigidBody2D, message: String) -> void:
	if not is_instance_valid(target):
		return
	key_label.text = "A" if player.global_position.x > target.global_position.x else "D"
	instruction.text = message


func _change_step(next_step: int) -> void:
	step = next_step
	if step == Step.BUBBLE_WARNING:
		_warning_time_left = 5.0
	_show_step()


func _show_step() -> void:
	prompt.visible = step != Step.DONE
	match step:
		Step.MOVE_RIGHT:
			key_label.text = "D"
			instruction.text = "Move right"
		Step.MOVE_LEFT:
			key_label.text = "A"
			instruction.text = "Move left"
		Step.TRIPLE_JUMP:
			key_label.text = "SPACE"
			instruction.text = "Jump 3 times before landing  %d/3" % _jump_count
		Step.FIND_ROCK:
			key_label.text = "D"
			instruction.text = "Move to a rock"
		Step.PICK_UP_ROCK:
			key_label.text = "N"
			instruction.text = "Press N to pick up the rock"
		Step.THROW_ROCK:
			key_label.text = "N"
			instruction.text = "Press N again to throw the rock"
		Step.FIND_SWORD:
			key_label.text = "A"
			instruction.text = "Move to the wooden sword"
		Step.PICK_UP_SWORD:
			key_label.text = "N"
			instruction.text = "Press N to pick up the sword"
		Step.SWING_SWORD:
			key_label.text = "M"
			instruction.text = "Press M to swing the sword"
		Step.STOMP_HINT:
			key_label.text = "SPACE"
			instruction.text = "Stomp crabs or jellyfish to bounce! Avoid urchins."
		Step.BUBBLE_WARNING:
			key_label.text = "!"
			instruction.text = "Big bubbles can trap you; water jets hurt too"
