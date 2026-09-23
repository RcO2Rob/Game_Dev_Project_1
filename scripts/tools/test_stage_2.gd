extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage := (load("res://scenes/stage_2.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await physics_frame
	await physics_frame
	assert(stage.get_node("HUD/Panel/Level").text == "LEVEL 2")
	assert(stage.get_node_or_null("HUD/Panel/Controls") == null)
	var player: CharacterBody2D = stage.get_node("Player")
	assert(player.get_node("Camera2D").limit_right == 15360)
	var terrain: TileMapLayer = stage.get_node("Terrain")
	var terrain_bounds := terrain.get_used_rect()
	assert(terrain_bounds.size.x > 400 and terrain_bounds.size.y > 5)
	assert(stage.get_node("PrecisionChasm/KillShape").shape.size.x == 704.0)
	assert(stage.get_node("PrecisionDiamond") != null)
	assert(stage.get_node("Lobster42") != null)
	assert(stage.get_node("Lobster470") != null)
	assert(stage.find_children("Lobster*", "CharacterBody2D", true, false).size() == 8)
	# The first checkpoint was deliberately removed; the other three remain.
	var checkpoints := stage.get_node("Checkpoints")
	assert(checkpoints.get_child_count() == 3)
	assert(checkpoints.get_node_or_null("Beacon1") == null)
	for beacon in checkpoints.get_children():
		player.global_position = beacon.position + Vector2(0, -40)
		player.velocity = Vector2.ZERO
		for frame in range(4):
			await physics_frame
		assert(stage.checkpoint_x == beacon.position.x)
		player.die()
		assert(player.global_position == beacon.position + Vector2(60, -32))
		assert(player.current_health == 3)
	# Earlier beacons cannot overwrite the latest checkpoint.
	stage._checkpoint_entered(player, checkpoints.get_child(0))
	assert(stage.checkpoint_x == checkpoints.get_child(checkpoints.get_child_count() - 1).position.x)
	player.global_position = Vector2(13088, 650)
	player.velocity = Vector2.ZERO
	for frame in range(4):
		await physics_frame
	assert(is_equal_approx(player.global_position.x, player._spawn_position.x))
	assert(player.global_position.y >= player._spawn_position.y)
	player.global_position = stage.get_node("ConchExit").global_position + Vector2(0, -41)
	for frame in range(6):
		await physics_frame
	assert(current_scene == stage, "Finish must not reload Stage 2 via the old conch script")
	assert(stage.completed)
	var end_shop := root.get_node("EndShop")
	assert(paused and end_shop.opened)
	assert(end_shop.destination == "res://scenes/stage_3.tscn")
	end_shop.continue_run()
	for frame in range(6):
		await process_frame
	assert(current_scene.scene_file_path == "res://scenes/stage_3.tscn")
	print("Stage 2 spawn, camera and end-shop transition tests passed")
	quit()
