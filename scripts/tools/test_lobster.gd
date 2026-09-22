extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var arena := Node2D.new()
	arena.name = "LobsterTestArena"
	root.add_child(arena)
	current_scene = arena

	var floor := StaticBody2D.new()
	floor.position = Vector2(400, 300)
	floor.collision_layer = 1
	var floor_shape := CollisionShape2D.new()
	floor_shape.shape = RectangleShape2D.new()
	floor_shape.shape.size = Vector2(800, 40)
	floor.add_child(floor_shape)
	arena.add_child(floor)

	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.position = Vector2(130, 256)
	arena.add_child(player)
	var lobster := (load("res://scenes/enemies/lobster.tscn") as PackedScene).instantiate() as CharacterBody2D
	lobster.position = Vector2(340, 258)
	arena.add_child(lobster)
	await physics_frame
	await physics_frame

	# Crossing a patrol boundary must cause one stable turn, not alternating
	# left/right mirror changes on successive frames.
	player.global_position = Vector2(0, 256)
	lobster.global_position.x = lobster._start_x + lobster.patrol_distance + 2.0
	lobster._direction = 1.0
	lobster.get_node("Visual").transform = Transform2D.IDENTITY
	lobster.velocity = Vector2.ZERO
	await physics_frame
	assert(lobster._direction == -1.0)
	assert(lobster.get_node("Visual").transform.x.x < 0.0)
	for frame in range(8):
		await physics_frame
		assert(lobster._direction == -1.0)
		assert(lobster.get_node("Visual").transform.x.x < 0.0)

	lobster.global_position = Vector2(340, 258)
	lobster.velocity = Vector2.ZERO
	lobster._direction = 1.0
	lobster.get_node("Visual").transform = Transform2D.IDENTITY
	player.global_position = Vector2(130, 256)
	await physics_frame
	await physics_frame
	assert(lobster._can_see_player())
	var chase_start_x: float = lobster.global_position.x
	for frame in range(24):
		await physics_frame
	assert(lobster.global_position.x < chase_start_x - 12.0)

	# Keep the bodies just outside contact range so damage must come from the
	# animated claw attack rather than the player's generic collision handler.
	player.global_position = lobster.global_position + Vector2(-55, 0)
	player.velocity = Vector2.ZERO
	assert(player.equip_sword())
	var health_before: int = player.current_health
	for frame in range(35):
		await physics_frame
	assert(player.current_health == health_before - 1)
	assert(not player.has_sword)
	assert(not player.get_node("Body/SwordPivot").visible)
	var lost_sword: RigidBody2D
	for child in arena.get_children():
		if child is RigidBody2D and child.is_in_group("pickup_weapon") and child._collected:
			lost_sword = child
			break
	assert(is_instance_valid(lost_sword))
	assert(lost_sword.weapon_kind == "wood" and lost_sword.durability == 5)
	assert(lost_sword._collected)
	assert(lost_sword.collision_layer == 0)
	lobster._captured_in_bubble = true
	for frame in range(65):
		await physics_frame
	assert(not is_instance_valid(lost_sword))

	# A gentle underwater descent must still count as a stomp. The lobster is
	# taller than the crab, so the player can touch its top before reaching the
	# old minimum fall-speed threshold.
	var stomp_lobster := (load("res://scenes/enemies/lobster.tscn") as PackedScene).instantiate() as CharacterBody2D
	stomp_lobster.position = Vector2(620, 258)
	stomp_lobster.detection_range = 0.0
	stomp_lobster.patrol_speed = 0.0
	arena.add_child(stomp_lobster)
	player.global_position = Vector2(620, 221)
	player.velocity = Vector2(0, 8)
	player._invulnerability_left = 0.0
	var health_before_stomp: int = player.current_health
	for frame in range(8):
		await physics_frame
	assert(stomp_lobster._defeated, "A low-speed top landing must stomp the lobster")
	assert(player.current_health == health_before_stomp, "A successful lobster stomp must not hurt the player")
	assert(player.velocity.y < 0.0, "A successful stomp must bounce the player upward")
	print("Lobster chase, claw attack, sword-loss and stomp tests passed")
	quit()
