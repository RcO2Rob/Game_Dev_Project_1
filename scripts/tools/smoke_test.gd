extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := (load("res://scenes/stage_1.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var tutorial_intro := stage.get_node("TutorialIntro")
	assert(paused and tutorial_intro.visible)
	assert("TUTORIAL LEVEL" in tutorial_intro.get_node("Content/Panel/Margin/VBox/Title").text)
	tutorial_intro.dismiss()
	assert(not paused and not tutorial_intro.visible)
	assert(InputMap.action_get_events("swim")[0].physical_keycode == KEY_SPACE)
	assert(stage.get_node("HUD/Panel/Level").text == "LEVEL 1")
	assert(stage.get_node_or_null("HUD/Panel/Controls") == null)
	assert(stage.get_node_or_null("MechanicTutorial/TutorialCurrent") == null)
	assert(stage.get_node("MechanicTutorial/TutorialMovingReef") != null)
	assert(stage.get_node("MechanicTutorial/TutorialVent") != null)
	var audio_manager := root.get_node("AudioManager")
	assert(audio_manager != null)
	assert(audio_manager._music_player.stream != null)
	assert(audio_manager._music_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(audio_manager._sfx_players.size() == 8)
	audio_manager.play_enemy_hit()
	audio_manager.play_enemy_stomp()
	audio_manager.play_player_hurt()
	audio_manager.play_coin_pickup()
	audio_manager.play_diamond_pickup()
	audio_manager.play_weapon_pickup()
	audio_manager.play_sword_swing()
	audio_manager.play_barrel_break()
	assert(audio_manager._next_sfx_player == 0)

	var player := stage.get_node("Player")
	assert(player.current_health == 3)
	assert(player._swim_jumps_remaining == 3)
	assert(player.get_node("Body/HelmetShell") != null)
	assert(player.get_node("Body/BackLeg") != null)
	assert(player.get_node("Body/FrontLeg") != null)

	player.global_position += Vector2(40, 0)
	var damaged_position: Vector2 = player.global_position
	player.take_damage()
	assert(player.current_health == 2)
	assert(player.global_position == damaged_position)
	player.add_coin()
	assert(player.coin_count == 1)
	player.add_diamond()
	assert(player.diamond_count == 1)
	player._invulnerability_left = 0.0
	player.take_damage(2)
	assert(player.current_health == 3)
	assert(player.global_position == player._spawn_position)
	assert(player.collision_mask == 13)

	assert(stage.get_node("Coin1") != null)
	assert(stage.get_node("Diamond1") != null)
	assert(stage.get_node("BubbleHole1") != null)
	assert(stage.get_node("PineappleHouse") != null)
	assert(stage.get_node("AmbientBubbles") != null)
	assert(stage.get_node("SeaweedDecoration1/SwayPivot") != null)
	assert(stage.get_node("StoneSwordPickup") != null)
	assert(stage.get_node("BreakableBarrel") != null)
	assert(stage.get_node("ConchExit") != null)
	assert(InputMap.has_action("attack"))
	assert(stage.get_node("ConchExit").next_scene == "res://scenes/stage_2.tscn")
	assert(ResourceLoader.exists("res://scenes/stage_2.tscn"))
	assert(stage.get_node("CrabOne").collision_mask & 2 != 0)

	var sword_pickup := stage.get_node("StoneSwordPickup")
	player.global_position = sword_pickup.global_position - Vector2(12, 0)
	player.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	assert(not player.has_sword)
	player.pick_up_nearest_item()
	assert(player.has_sword)
	var held_test_rock := stage.get_node("RockThree")
	held_test_rock.global_position = player.global_position
	await physics_frame
	player.pick_up_nearest_item()
	assert(not is_instance_valid(player._held_rock))
	assert(player.get_node("Body/SwordPivot").visible)
	held_test_rock.global_position = Vector2(990, 270)
	var dropped_sword: RigidBody2D = player.drop_sword()
	assert(dropped_sword != null)
	assert(not player.has_sword)
	assert(not player.get_node("Body/SwordPivot").visible)
	assert(dropped_sword.gravity_scale > 0.0)
	assert(dropped_sword.collision_mask & 1 != 0)
	var dropped_start_y := dropped_sword.global_position.y
	for _frame in range(90):
		await physics_frame
	assert(dropped_sword.global_position.y > dropped_start_y + 5.0)
	player.global_position = dropped_sword.global_position - Vector2(36, 0)
	player.velocity = Vector2.ZERO
	dropped_sword._pickup_delay = 0.0
	await physics_frame
	assert(not player.has_sword)
	assert(dropped_sword.collect_by(player))
	assert(player.has_sword)
	assert(player.get_node("Body/SwordPivot").visible)
	var barrel := stage.get_node("BreakableBarrel")
	assert(barrel.collision_layer & 2 != 0, "Barrels must occupy the obstacle layer used by crabs")
	var barrel_block_crab := (load("res://scenes/enemies/crab.tscn") as PackedScene).instantiate()
	barrel_block_crab.position = barrel.position + Vector2(-90, -24)
	stage.add_child(barrel_block_crab)
	await physics_frame
	barrel_block_crab._direction = 1.0
	barrel_block_crab._start_x = barrel_block_crab.global_position.x
	var furthest_crab_x: float = barrel_block_crab.global_position.x
	for _frame in range(100):
		await physics_frame
		furthest_crab_x = maxf(furthest_crab_x, barrel_block_crab.global_position.x)
	assert(furthest_crab_x < barrel.global_position.x - 30.0, "A crab must not pass through a barrel")
	barrel_block_crab.queue_free()
	await process_frame
	var barrel_test_rock := stage.get_node("RockTwo")
	barrel_test_rock._is_thrown = true
	barrel_test_rock._on_enemy_hitbox_body_entered(barrel)
	barrel_test_rock._is_thrown = false
	assert(not barrel._broken)
	barrel.global_position = player.global_position + Vector2(50, 0)
	player._facing = 1.0
	player.get_node("Body").scale.x = absf(player.get_node("Body").scale.x)
	barrel._reward_roll_override = 1.0
	var child_count_before_barrel := stage.get_child_count()
	player.attack_with_sword()
	for _frame in range(6):
		await physics_frame
	assert(barrel._broken)
	assert(stage.get_child_count() >= child_count_before_barrel + 7)

	var rescue_barrel := (load("res://scenes/props/breakable_barrel.tscn") as PackedScene).instantiate()
	rescue_barrel.position = player.position + Vector2(150, 0)
	stage.add_child(rescue_barrel)
	player.diamond_count = 2
	assert(rescue_barrel._should_drop_diamonds(player, 0.199))
	assert(not rescue_barrel._should_drop_diamonds(player, 0.2))
	player.diamond_count = 3
	assert(not rescue_barrel._should_drop_diamonds(player, 0.0))
	player.diamond_count = 2
	var diamonds_before_reward := 0
	for child in stage.get_children():
		if child.get_script() == load("res://scripts/diamond.gd"):
			diamonds_before_reward += 1
	rescue_barrel._reward_roll_override = 0.0
	rescue_barrel.hit_by_weapon()
	await process_frame
	var diamonds_after_reward := 0
	for child in stage.get_children():
		if child.get_script() == load("res://scripts/diamond.gd"):
			diamonds_after_reward += 1
	assert(diamonds_after_reward == diamonds_before_reward + 2, "A successful low-diamond reward must drop exactly two diamonds")
	for _frame in range(18):
		await physics_frame
	assert(not player._is_attacking)

	var sword_target := stage.get_node("CrabTwo")
	sword_target.move_speed = 0.0
	sword_target.global_position = player.global_position + Vector2(50, 0)
	player.attack_with_sword()
	for _frame in range(6):
		await physics_frame
	assert(sword_target._defeated)
	for _frame in range(18):
		await physics_frame

	var sword_bubble := (load("res://scenes/hazards/bubble.tscn") as PackedScene).instantiate()
	stage.add_child(sword_bubble)
	sword_bubble.global_position = player.global_position + Vector2(52, -12)
	await physics_frame
	player.attack_with_sword()
	for _frame in range(10):
		await physics_frame
	assert(not is_instance_valid(sword_bubble) or sword_bubble.is_queued_for_deletion())
	for _frame in range(14):
		await physics_frame

	var crab := stage.get_node_or_null("CrabOne")
	if not is_instance_valid(crab):
		crab = (load("res://scenes/enemies/crab.tscn") as PackedScene).instantiate()
		crab.name = "CrabCollisionTest"
		stage.add_child(crab)
	var rock := stage.get_node("RockOne")
	crab.global_position = Vector2(500, 520)
	crab._start_x = 500.0
	rock.global_position = Vector2(430, 520)
	for _frame in range(150):
		await physics_frame
	assert(crab.global_position.x > rock.global_position.x)
	var impact_rock := (load("res://scenes/rock.tscn") as PackedScene).instantiate()
	stage.add_child(impact_rock)
	impact_rock._is_thrown = true
	impact_rock._on_enemy_hitbox_body_entered(crab)
	await process_frame
	assert(not is_instance_valid(impact_rock), "A thrown rock must disappear after hitting an enemy")
	assert(crab._defeated)

	var bubble := (load("res://scenes/hazards/bubble.tscn") as PackedScene).instantiate()
	stage.add_child(bubble)
	bubble.global_position = rock.global_position
	await process_frame
	bubble._on_body_entered(rock)
	await process_frame
	assert(bubble._payload == rock)
	assert(not bubble.get_node("RidePlatform/CollisionShape2D").disabled)

	stage.get_node("ConchExit")._on_body_entered(player)
	await process_frame
	await process_frame
	var end_shop := root.get_node("EndShop")
	assert(paused and end_shop.opened)
	for button in end_shop.find_children("*", "Button", true, false):
		assert(button.text.is_empty(), "End shop must communicate with icons, not button text")
	end_shop.continue_run()
	for _frame in range(5):
		await process_frame
	assert(current_scene != null)
	assert(current_scene.scene_file_path == "res://scenes/stage_2.tscn")
	print("Gameplay smoke test passed, including Stage 1 mechanic tutorial and visual end shop")
	current_scene.queue_free()
	await process_frame
	quit()
