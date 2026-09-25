extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := (load("res://scenes/stage_1.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var tutorial := stage.get_node("InteractiveTutorial")
	assert(not paused and tutorial.visible)
	assert(tutorial.get_node("Prompt/Content/Rows/KeyBox/Key").text == "D")
	assert(tutorial.get_node("Prompt/Content/Rows/Instruction").text == "Move right")
	assert(InputMap.action_get_events("swim")[0].physical_keycode == KEY_SPACE)
	assert(stage.get_node("HUD/Panel/Level").text == "LEVEL 1")
	assert(stage.get_node_or_null("HUD/Panel/Controls") == null)
	assert(stage.get_node_or_null("MechanicTutorial") == null)
	var audio_manager := root.get_node("AudioManager")
	assert(audio_manager != null)
	assert(audio_manager._music_player.stream != null)
	assert(audio_manager._music_player.playing)
	assert(audio_manager._music_player.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert(audio_manager._music_player.volume_db == audio_manager.MUSIC_VOLUME_DB)
	assert(audio_manager._music_player.finished.is_connected(audio_manager._on_music_finished))
	assert(audio_manager._sfx_players.size() == 8)
	audio_manager.play_enemy_hit()
	audio_manager.play_enemy_stomp()
	audio_manager.play_player_hurt()
	audio_manager.play_coin_pickup()
	audio_manager.play_diamond_pickup()
	audio_manager.play_weapon_pickup()
	audio_manager.play_sword_swing()
	audio_manager.play_barrel_break()
	audio_manager.play_conch_enter()
	assert(audio_manager._next_sfx_player == 1)

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
	assert(player.collision_mask == 15)

	assert(stage.get_node("Coin1") != null)
	assert(stage.get_node("Diamond1") != null)
	assert(stage.get_node("BubbleHole1") != null)
	assert(stage.get_node("PineappleHouse") != null)
	assert(stage.get_node("AmbientBubbles") != null)
	assert(stage.get_node("SeaweedDecoration1/SwayPivot") != null)
	assert(stage.get_node("StoneSwordPickup") != null)
	assert(stage.get_node("BreakableBarrel") != null)
	assert(stage.get_node("ConchExit") != null)
	assert(stage.get_node("ConchExit/EntryHint/Message").text == "ENTER THE SHELL\nNEXT LEVEL")
	assert(InputMap.has_action("attack"))
	assert(stage.get_node("ConchExit").next_scene == "res://scenes/stage_2.tscn")
	assert(ResourceLoader.exists("res://scenes/stage_2.tscn"))
	assert(stage.get_node("CrabOne").collision_mask & 2 != 0)

	var sword_pickup := stage.get_node("StoneSwordPickup")
	assert(sword_pickup.weapon_kind == "wood" and sword_pickup.durability == 5)
	var weapon_status := stage.get_node("HUD/Panel/WeaponStatus")
	assert(not weapon_status.visible)
	assert(weapon_status.position.y > stage.get_node("HUD/Panel").size.y, "Weapon durability HUD must sit below the main panel")
	player.global_position = sword_pickup.global_position - Vector2(12, 0)
	player.velocity = Vector2.ZERO
	for _frame in range(3):
		await physics_frame
	assert(not player.has_sword)
	player.pick_up_nearest_item()
	assert(player.has_sword)
	assert(player.sword_kind == "wood")
	assert(player.sword_durability == 5 and player.sword_max_durability == 5)
	stage.get_node("HUD")._process(0.0)
	assert(weapon_status.visible)
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
	assert(dropped_sword.weapon_kind == "wood" and dropped_sword.durability == 5)
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
	assert(player.sword_kind == "wood" and player.sword_durability == 5)
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
	assert(player.sword_durability == 4, "Breaking one barrel must use one durability")

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
	assert(player.sword_durability == 3, "Hitting one enemy must use one durability")
	for _frame in range(18):
		await physics_frame

	var sword_bubble := (load("res://scenes/hazards/bubble.tscn") as PackedScene).instantiate()
	stage.add_child(sword_bubble)
	sword_bubble.global_position = player.global_position + Vector2(52, -12)
	await physics_frame
	player._is_attacking = true
	player._sword_hit_targets.clear()
	player._try_sword_hit(sword_bubble)
	player._is_attacking = false
	for _frame in range(10):
		await physics_frame
	assert(not is_instance_valid(sword_bubble) or sword_bubble.is_queued_for_deletion())
	assert(player.sword_durability == 3, "Popping a bubble must not use sword durability")

	var final_durability_target := (load("res://scenes/enemies/crab.tscn") as PackedScene).instantiate()
	final_durability_target.move_speed = 0.0
	final_durability_target.global_position = player.global_position + Vector2(50, 0)
	stage.add_child(final_durability_target)
	player.sword_durability = 1
	player._is_attacking = true
	player._sword_hit_targets.clear()
	player._try_sword_hit(final_durability_target)
	assert(final_durability_target._defeated)
	assert(not player.has_sword and player.sword_durability == 0)
	assert(not player.get_node("Body/SwordPivot").visible)
	stage.get_node("HUD")._process(0.0)
	assert(not weapon_status.visible)

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

	var bubble_rock := (load("res://scenes/rock.tscn") as PackedScene).instantiate()
	stage.add_child(bubble_rock)
	bubble_rock.global_position = Vector2(2500, 250)
	var bubble := (load("res://scenes/hazards/bubble.tscn") as PackedScene).instantiate()
	stage.add_child(bubble)
	bubble.global_position = bubble_rock.global_position
	await process_frame
	bubble._on_body_entered(bubble_rock)
	await process_frame
	assert(bubble._payload == bubble_rock)
	assert(not bubble.get_node("RidePlatform/CollisionShape2D").disabled)

	stage.get_node("ConchExit")._on_body_entered(player)
	await process_frame
	await process_frame
	var end_shop := root.get_node("EndShop")
	assert(paused and end_shop.opened)
	assert(end_shop.balance_icon.coins == player.coin_count)
	assert(end_shop.balance_icon.coins_per_diamond == 30)
	assert(end_shop.cards.size() == 4)
	assert(end_shop.cards[0].get_child(0).coin_price == 60)
	assert(end_shop.cards[1].get_child(0).coin_price == 180)
	assert(end_shop.cards[2].get_child(0).coin_price == 30)
	assert(end_shop.cards[3].get_child(0).coin_price == 0)
	for button in end_shop.find_children("*", "Button", true, false):
		assert(button.text.is_empty(), "End shop must communicate with icons, not button text")
	assert(end_shop.cards[0].get_node("Description").text == "STONE SWORD · 15 HITS")
	assert(end_shop.cards[1].get_node("Description").text == "DIAMOND SWORD · 50 HITS")
	assert(end_shop.cards[2].get_node("Description").text == "RESTORE 1 LIFE")
	assert(end_shop.cards[3].get_node("Description").text == "PERMANENT +1 MAX LIFE")
	assert(end_shop.find_child("NextLabel", true, false).text == "NEXT")
	assert(player.equip_sword("wood"))
	player.coin_count = 60
	end_shop._refresh()
	assert(not end_shop.cards[0].disabled)
	assert(end_shop.purchase("sword"), "A shop weapon should replace the held wooden sword")
	assert(player.sword_kind == "stone" and player.sword_durability == 15)
	assert(player.coin_count == 0)
	var next_button := end_shop.find_child("NextLabel", true, false).get_parent() as Button
	next_button.pressed.emit()
	for _frame in range(5):
		await process_frame
	assert(current_scene != null)
	assert(current_scene.scene_file_path == "res://scenes/stage_2.tscn")
	print("Gameplay smoke test passed, including Stage 1 flow, audio and visual end shop")
	current_scene.queue_free()
	await process_frame
	quit()
