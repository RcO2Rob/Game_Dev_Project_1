extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var floor := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var floor_rectangle := RectangleShape2D.new()
	floor_rectangle.size = Vector2(700, 40)
	floor_shape.shape = floor_rectangle
	floor.add_child(floor_shape)
	floor.position = Vector2(200, 600)
	arena.add_child(floor)
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(32, 160)
	wall_shape.shape = wall_rectangle
	wall.add_child(wall_shape)
	wall.position = Vector2(300, 500)
	arena.add_child(wall)

	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.position = Vector2(130, 556)
	arena.add_child(player)
	assert(player.collision_mask & 2 != 0, "Player must physically meet rocks")
	assert(player.collision_mask & 4 != 0, "Player must physically meet enemies")

	var crab := (load("res://scenes/enemies/crab.tscn") as PackedScene).instantiate() as CharacterBody2D
	crab.position = Vector2(248, 564)
	crab.move_speed = 0.0
	arena.add_child(crab)
	await physics_frame
	Input.action_press("move_right")
	for _frame in range(150):
		await physics_frame
		if player.current_health == 2:
			player._invulnerability_left = 100.0
	Input.action_release("move_right")
	assert(player.current_health == 2, "Touching a crab must cost one life")
	assert(crab.global_position.x < 263.0, "Crab was pushed through the wall")
	assert(player.global_position.x < crab.global_position.x, "Player passed through a crab")
	crab.queue_free()
	await process_frame
	assert(not is_instance_valid(crab))

	player.global_position = Vector2(130, 556)
	player.velocity = Vector2.ZERO
	player.current_health = 3
	player._invulnerability_left = 0.0
	var urchin := (load("res://scenes/enemies/urchin.tscn") as PackedScene).instantiate() as CharacterBody2D
	urchin.position = Vector2(263, 569)
	arena.add_child(urchin)
	await physics_frame
	Input.action_press("move_right")
	for _frame in range(150):
		await physics_frame
		if player.current_health == 2:
			player._invulnerability_left = 100.0
	Input.action_release("move_right")
	assert(player.current_health == 2, "Touching an urchin must cost one life")
	assert(urchin.global_position.x < 274.0, "Urchin was pushed through the wall")
	assert(player.global_position.x < urchin.global_position.x or player.global_position.y < 546.0, "Player passed through an urchin")
	urchin.queue_free()
	await process_frame
	assert(not is_instance_valid(urchin))
	for _frame in range(5):
		await physics_frame

	player.global_position = Vector2(130, 556)
	player.velocity = Vector2.ZERO
	var rock := (load("res://scenes/rock.tscn") as PackedScene).instantiate() as RigidBody2D
	rock.position = Vector2(205, 540)
	arena.add_child(rock)
	await physics_frame
	Input.action_press("move_right")
	for _frame in range(180):
		await physics_frame
	Input.action_release("move_right")
	assert(rock.global_position.x < 271.0, "Rock was pushed through the wall")
	assert(player.global_position.x < rock.global_position.x or player.global_position.y < 534.0, "Player passed through a rock")
	assert(rock.global_position.x > 247.0, "Player did not push the rock")
	assert(player.global_position.y >= 548.0, "Pushing a rock against a wall must not lift the player")
	print("Solid collisions passed: crab, urchin, and rock stay outside the wall")
	arena.queue_free()
	await process_frame
	quit()
