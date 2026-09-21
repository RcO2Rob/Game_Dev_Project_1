extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage := (load("res://scenes/stage_2.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await physics_frame
	await physics_frame
	var player: CharacterBody2D = stage.get_node("Player")
	assert(player.get_node("Camera2D").limit_right == 15360)
	var terrain: TileMapLayer = stage.get_node("Terrain")
	assert(terrain.get_cell_source_id(Vector2i(398, 18)) == -1)
	assert(terrain.get_cell_source_id(Vector2i(399, 17)) == 0)
	assert(terrain.get_cell_source_id(Vector2i(404, 15)) == 0)
	assert(terrain.get_cell_source_id(Vector2i(414, 14)) == 0)
	assert(stage.get_node("PrecisionChasm/KillShape").shape.size.x == 704.0)
	assert(stage.get_node("PrecisionDiamond") != null)
	assert(stage.get_node("Lobster42") != null)
	assert(stage.get_node("Lobster470") != null)
	assert(stage.find_children("Lobster*", "CharacterBody2D", true, false).size() == 8)
	# Enter each beacon through its real overlap signal, then test death recovery.
	for beacon in stage.get_node("Checkpoints").get_children():
		player.global_position = beacon.position + Vector2(0, -40)
		player.velocity = Vector2.ZERO
		for frame in range(4):
			await physics_frame
		assert(stage.checkpoint_x == beacon.position.x)
		player.die()
		assert(player.global_position == beacon.position + Vector2(60, -32))
		assert(player.current_health == 3)
	# Earlier beacons cannot accidentally overwrite progress on a return trip.
	stage._checkpoint_entered(player, stage.get_node("Checkpoints/Beacon1"))
	assert(stage.checkpoint_x == 12368)
	player.global_position = Vector2(13088, 650)
	player.velocity = Vector2.ZERO
	for frame in range(4):
		await physics_frame
	assert(is_equal_approx(player.global_position.x, 12428.0))
	assert(player.global_position.y >= 544.0 and player.global_position.y <= 554.0)
	player.global_position = Vector2(15160, 520)
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
	print("Stage 2 checkpoint, camera and end-shop transition tests passed")
	quit()
