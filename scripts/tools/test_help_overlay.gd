extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var stage := (load("res://scenes/stage_1.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	var help := root.get_node("HelpOverlay")
	var panel := help.get_node("Overlay/HelpPanel") as Control
	var badge := help.get_node("Badge") as Button
	var player := stage.get_node("Player") as CharacterBody2D
	assert(not help.overlay.visible and badge.text == "H  HELP")
	assert(panel.position.y >= stage.get_node("HUD/Panel").position.y + stage.get_node("HUD/Panel").size.y)
	assert(InputMap.action_get_events("help")[0].physical_keycode == KEY_H)
	assert(help.rows.get_child_count() == 6)
	assert("Pick up / throw a rock" in help.rows.get_child(3).get_child(1).text)

	_press_help()
	await process_frame
	assert(help.overlay.visible and paused and badge.text == "H  CLOSE")
	var stopped_position: Vector2 = player.global_position
	Input.action_press("move_right")
	for _frame in range(5):
		await physics_frame
	Input.action_release("move_right")
	assert(player.global_position == stopped_position, "The game should pause while help is open")
	_release_help()
	await process_frame
	_press_help()
	await process_frame
	assert(not help.overlay.visible and not paused and badge.text == "H  HELP")
	_release_help()
	await process_frame

	var shop := root.get_node("EndShop")
	shop.open_shop(player)
	assert(paused)
	_press_help()
	await process_frame
	assert(help.overlay.visible and paused)
	_release_help()
	await process_frame
	_press_help()
	await process_frame
	assert(not help.overlay.visible and paused, "Closing help must not unpause an open shop")
	shop._hide_shop()
	_release_help()
	assert(not paused)
	print("Help overlay passed: H toggle, pause, controls and shop pause restoration")
	stage.queue_free()
	await process_frame
	quit()


func _press_help() -> void:
	var event := InputEventAction.new()
	event.action = "help"
	event.pressed = true
	Input.parse_input_event(event)


func _release_help() -> void:
	var event := InputEventAction.new()
	event.action = "help"
	event.pressed = false
	Input.parse_input_event(event)
