extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.position = Vector2(200, 240)
	arena.add_child(player)
	var jellyfish_scene := load("res://scenes/enemies/jellyfish.tscn") as PackedScene
	var top_jellyfish := jellyfish_scene.instantiate() as CharacterBody2D
	top_jellyfish.position = Vector2(200, 300)
	top_jellyfish.horizontal_range = 0.0
	top_jellyfish.vertical_range = 0.0
	arena.add_child(top_jellyfish)
	assert(top_jellyfish.can_be_stomped)

	var stomped := false
	for _frame in range(60):
		await physics_frame
		if not is_instance_valid(top_jellyfish) or top_jellyfish._defeated:
			stomped = true
			break
	assert(stomped, "Landing on a jellyfish must defeat it")
	assert(player.current_health == 3, "A successful stomp must not hurt the player")
	assert(player.velocity.y < 0.0, "A successful stomp must bounce the player")

	var side_jellyfish := jellyfish_scene.instantiate() as CharacterBody2D
	side_jellyfish.position = Vector2(500, 300)
	side_jellyfish.horizontal_range = 0.0
	side_jellyfish.vertical_range = 0.0
	arena.add_child(side_jellyfish)
	player.global_position = Vector2(400, 300)
	player.velocity = Vector2.ZERO
	player.sink_gravity = 0.0
	player._invulnerability_left = 0.0
	Input.action_press("move_right")
	for _frame in range(45):
		await physics_frame
	Input.action_release("move_right")
	assert(player.current_health == 2, "Touching a jellyfish from the side must still hurt")
	assert(is_instance_valid(side_jellyfish) and not side_jellyfish._defeated)
	print("Jellyfish stomp and side-contact tests passed")
	arena.queue_free()
	await process_frame
	quit()
