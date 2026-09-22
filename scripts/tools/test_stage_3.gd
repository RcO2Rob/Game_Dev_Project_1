extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage2 := (load("res://scenes/stage_2.tscn") as PackedScene).instantiate()
	root.add_child(stage2)
	current_scene = stage2
	await process_frame
	stage2.get_node("Player").coin_count = 17
	stage2.get_node("Player").diamond_count = 15
	stage2.get_node("Player").current_health = 2
	stage2._finish(stage2.get_node("Player"))
	await process_frame
	await process_frame
	var end_shop := root.get_node("EndShop")
	assert(paused and end_shop.opened)
	for button in end_shop.find_children("*", "Button", true, false):
		assert(button.text.is_empty(), "The shop must be icon-only")
	var platform2 := stage2.get_node_or_null("MovingReef288")
	var stopped2: Vector2 = platform2.position if platform2 else Vector2.ZERO
	for frame in range(5):
		await process_frame
	if platform2:
		assert(platform2.position == stopped2, "Buying must pause moving hazards")
	assert(end_shop.purchase("heal"))
	var stage2_player: CharacterBody2D = stage2.get_node("Player")
	assert(stage2_player.current_health == 3 and stage2_player.diamond_count == 14)
	assert(not end_shop.purchase("heal"))
	assert(end_shop.purchase("heart"))
	assert(end_shop.purchase("heart"))
	assert(stage2_player.max_health == 5 and stage2_player.current_health == 5 and stage2_player.diamond_count == 8)
	assert(not end_shop.purchase("heart"))
	assert(end_shop.purchase("sword"))
	assert(stage2_player.has_sword and stage2_player.diamond_count == 6)
	assert(stage2_player.sword_kind == "stone")
	assert(stage2_player.sword_durability == 15 and stage2_player.sword_max_durability == 15)
	assert(not end_shop.purchase("sword"))
	assert(not end_shop.purchase("bogus"))
	end_shop.continue_run()
	for frame in range(5):
		await process_frame
	var stage := current_scene
	assert(stage.scene_file_path == "res://scenes/stage_3.tscn")
	var player: CharacterBody2D = stage.get_node("Player")
	assert(player.coin_count == 17 and player.diamond_count == 6)
	assert(player.current_health == 5 and player.max_health == 5 and player.has_sword)
	assert(player.sword_kind == "stone" and player.sword_durability == 15)
	assert(root.get_node("RunState").pending.is_empty())
	assert(player.get_node("Camera2D").limit_right == 21504)
	assert(stage.get_node("HUD/Panel/Level").text == "LEVEL 3")
	assert(stage.get_node_or_null("HUD/Panel/Controls") == null)
	assert(stage.find_children("Current*", "Area2D", true, false).is_empty())
	for shop_name in ["DiamondShop1", "DiamondShop2", "DiamondShop3"]:
		assert(stage.get_node_or_null(shop_name) == null, "In-level shops must be removed from Stage 3")
	var platform := stage.get_node("MovingReef288") as AnimatableBody2D
	assert(platform.get_node("TerrainTile1") != null)
	assert(platform.get_node_or_null("Rock") == null)
	player.take_damage()
	assert(player.current_health == 4 and not player.has_sword)
	# Ride a moving reef without directional input; retain contact as it moves.
	player.position = platform.position + Vector2(0, -36)
	player.velocity = Vector2.ZERO
	for frame in range(5):
		await physics_frame
	var relative_x: float = player.position.x - platform.position.x
	var old_x: float = platform.position.x
	for frame in range(60):
		await physics_frame
	assert(absf(platform.position.x - old_x) > 3)
	assert(absf(player.position.x - platform.position.x - relative_x) < 6, "Reef must carry its rider")
	assert(player.is_on_floor())
	# All five checkpoint overlap signals, and purchased capacity survives death.
	for beacon in stage.get_node("Checkpoints").get_children():
		player.position = beacon.position + Vector2(0, -32)
		player.velocity = Vector2.ZERO
		for frame in range(4):
			await physics_frame
		assert(stage.checkpoint_x == beacon.position.x)
	player.die()
	assert(player.current_health == 5 and player.max_health == 5)
	assert(player.position == Vector2(18080, 544))
	# Jet telegraph and active phase use the same clock as the real damage area.
	var vent := stage.get_node("Vent349")
	vent._time = 0
	vent._physics_process(0.1)
	assert(not vent.active)
	vent._time = 3.4
	vent._physics_process(0.1)
	assert(vent.active)
	player.position = Vector2(21240, 520)
	for frame in range(6):
		await physics_frame
	assert(stage.completed and end_shop.opened and paused)
	assert(not stage.get_node("Completion").visible)
	end_shop.continue_run()
	for frame in range(4):
		await process_frame
	assert(stage.get_node("Completion").visible)
	assert(player.process_mode == Node.PROCESS_MODE_DISABLED)
	print("Stage 3 passed: visual end shop, transfer, transactions, platform riding, checkpoints, vents and finish")
	stage.queue_free()
	await process_frame
	await process_frame
	# Let the audio mixer release in-flight pickup voices before ending the test.
	for audio in root.get_node("AudioManager").get_children():
		if audio is AudioStreamPlayer:
			audio.stop()
	await create_timer(0.2).timeout
	quit()
