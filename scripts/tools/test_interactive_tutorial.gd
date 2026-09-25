extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var stage := (load("res://scenes/stage_1.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var player: CharacterBody2D = stage.get_node("Player")
	var tutorial: CanvasLayer = stage.get_node("InteractiveTutorial")
	var key: Label = tutorial.get_node("Prompt/Content/Rows/KeyBox/Key")
	var instruction: Label = tutorial.get_node("Prompt/Content/Rows/Instruction")
	assert(not paused and tutorial.step == tutorial.Step.MOVE_RIGHT)
	assert(key.text == "D" and instruction.text == "Move right")
	assert(tutorial.get_node("Prompt").position.y < player.get_global_transform_with_canvas().origin.y)
	var first_prompt_y: float = tutorial.get_node("Prompt").position.y
	tutorial._process(0.2)
	assert(tutorial.get_node("Prompt").position.y != first_prompt_y, "The key prompt must bob above the player")

	var start_x: float = player.global_position.x
	_send_action("move_left", true)
	await process_frame
	assert(tutorial.step == tutorial.Step.MOVE_RIGHT, "Pressing A must not skip the D prompt")
	_send_action("move_left", false)
	_send_action("move_right", true)
	await process_frame
	assert(tutorial.step == tutorial.Step.MOVE_LEFT and key.text == "A")
	assert(player.global_position.x - start_x < 60.0, "D should advance immediately without a walking distance")
	_send_action("move_right", false)
	_send_action("move_left", true)
	await process_frame
	assert(tutorial.step == tutorial.Step.TRIPLE_JUMP and key.text == "SPACE")
	_send_action("move_left", false)
	assert("0/3" in instruction.text)
	Input.action_press("swim")
	await physics_frame
	await physics_frame
	Input.action_release("swim")
	await physics_frame
	assert(tutorial._jump_count == 1)
	for _frame in range(180):
		await physics_frame
		if player.is_on_floor() and player._swim_jumps_remaining == 3:
			break
	assert(tutorial.step == tutorial.Step.TRIPLE_JUMP and tutorial._jump_count == 0, "Landing before the third jump must restart the lesson")

	for jump in range(3):
		Input.action_press("swim")
		await physics_frame
		await physics_frame
		Input.action_release("swim")
		await physics_frame
		assert(player._swim_jumps_remaining == 2 - jump)
	assert(tutorial.step == tutorial.Step.FIND_ROCK)
	var rock: RigidBody2D = stage.get_node("RockOne")
	player.global_position = rock.global_position + Vector2(0, -45)
	player.velocity = Vector2.ZERO
	for _frame in range(5):
		await physics_frame
		if tutorial.step == tutorial.Step.PICK_UP_ROCK:
			break
	assert(tutorial.step == tutorial.Step.PICK_UP_ROCK and key.text == "N")

	_send_action("interact", true)
	await process_frame
	for _frame in range(4):
		await physics_frame
		if tutorial.step == tutorial.Step.THROW_ROCK:
			break
	assert(player._held_rock == rock and tutorial.step == tutorial.Step.THROW_ROCK)
	_send_action("interact", false)
	await process_frame
	player._facing = 1.0
	_send_action("interact", true)
	await process_frame
	for _frame in range(4):
		await physics_frame
		if tutorial.step == tutorial.Step.FIND_SWORD:
			break
	assert(not is_instance_valid(player._held_rock) and tutorial.step == tutorial.Step.FIND_SWORD)
	_send_action("interact", false)
	var sword: RigidBody2D = stage.get_node("StoneSwordPickup")
	player.global_position = sword.global_position + Vector2(-20, -16)
	player.velocity = Vector2.ZERO
	for _frame in range(10):
		await physics_frame
		if tutorial.step == tutorial.Step.PICK_UP_SWORD:
			break
	assert(tutorial.step == tutorial.Step.PICK_UP_SWORD and key.text == "N")
	_send_action("interact", true)
	await process_frame
	for _frame in range(4):
		await physics_frame
		if tutorial.step == tutorial.Step.SWING_SWORD:
			break
	assert(player.has_sword and player.sword_kind == "wood")
	assert(tutorial.step == tutorial.Step.SWING_SWORD and key.text == "M")
	_send_action("interact", false)
	await process_frame
	_send_action("attack", true)
	await process_frame
	for _frame in range(8):
		await physics_frame
		if tutorial.step == tutorial.Step.STOMP_HINT:
			break
	assert(tutorial.step == tutorial.Step.STOMP_HINT and key.text == "SPACE")
	assert("Stomp crabs or jellyfish" in instruction.text)
	assert("to bounce" in instruction.text)
	_send_action("attack", false)
	player.global_position.x = 650.0
	for _frame in range(5):
		await physics_frame
		if tutorial.step == tutorial.Step.BUBBLE_WARNING:
			break
	assert(tutorial.step == tutorial.Step.BUBBLE_WARNING)
	assert("bubbles can trap you" in instruction.text)
	print("Interactive tutorial passed: D, A, triple jump, rock N, sword N/M, stomp and bubble hints")
	stage.queue_free()
	await process_frame
	quit()


func _send_action(action_name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = pressed
	Input.parse_input_event(event)
