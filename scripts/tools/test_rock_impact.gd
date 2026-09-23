extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var crab_scene := load("res://scenes/enemies/crab.tscn") as PackedScene
	var rock_scene := load("res://scenes/rock.tscn") as PackedScene

	var falling_enemy := crab_scene.instantiate() as CharacterBody2D
	falling_enemy.position = Vector2(200, 420)
	falling_enemy.move_speed = 0.0
	falling_enemy.gravity = 0.0
	arena.add_child(falling_enemy)
	var falling_rock := rock_scene.instantiate() as RigidBody2D
	falling_rock.position = Vector2(200, 280)
	arena.add_child(falling_rock)

	var slow_enemy := crab_scene.instantiate() as CharacterBody2D
	slow_enemy.position = Vector2(500, 420)
	slow_enemy.move_speed = 0.0
	slow_enemy.gravity = 0.0
	arena.add_child(slow_enemy)
	var slow_rock := rock_scene.instantiate() as RigidBody2D
	slow_rock.position = Vector2(500, 350)
	slow_rock.gravity_scale = 0.0
	slow_rock.linear_velocity = Vector2(0, 50)
	arena.add_child(slow_rock)
	var side_enemy := crab_scene.instantiate() as CharacterBody2D
	side_enemy.position = Vector2(1400, 420)
	side_enemy.move_speed = 0.0
	side_enemy.gravity = 0.0
	arena.add_child(side_enemy)
	var side_rock := rock_scene.instantiate() as RigidBody2D
	side_rock.position = Vector2(1300, 420)
	side_rock.gravity_scale = 0.0
	side_rock.linear_velocity = Vector2(260, 0)
	arena.add_child(side_rock)

	var thrown_enemy := crab_scene.instantiate() as CharacterBody2D
	thrown_enemy.position = Vector2(800, 420)
	thrown_enemy.move_speed = 0.0
	thrown_enemy.gravity = 0.0
	arena.add_child(thrown_enemy)
	var thrown_rock := rock_scene.instantiate() as RigidBody2D
	thrown_rock.position = Vector2(700, 420)
	thrown_rock.gravity_scale = 0.0
	arena.add_child(thrown_rock)
	thrown_rock.throw_from_hand(Vector2(260, 0))

	var dropped_enemy := crab_scene.instantiate() as CharacterBody2D
	dropped_enemy.position = Vector2(1100, 420)
	dropped_enemy.move_speed = 0.0
	dropped_enemy.gravity = 0.0
	arena.add_child(dropped_enemy)
	var holder := Node2D.new()
	holder.position = Vector2(1100, 280)
	arena.add_child(holder)
	var dropped_rock := rock_scene.instantiate() as RigidBody2D
	arena.add_child(dropped_rock)
	dropped_rock.pick_up(holder)
	dropped_rock.drop_from_hand()
	assert(not dropped_rock._is_thrown)

	for _frame in range(120):
		await physics_frame

	assert(not is_instance_valid(falling_enemy), "A freely falling rock must crush an enemy")
	assert(not is_instance_valid(falling_rock), "The rock must disappear after crushing an enemy")
	assert(is_instance_valid(slow_enemy) and not slow_enemy._defeated, "A gentle touch must not crush an enemy")
	assert(is_instance_valid(slow_rock))
	assert(is_instance_valid(side_enemy) and not side_enemy._defeated, "Pushing a rock into an enemy's side must not count as a crush")
	assert(is_instance_valid(side_rock))
	assert(not is_instance_valid(thrown_enemy), "Thrown rocks must still defeat enemies")
	assert(not is_instance_valid(thrown_rock))
	assert(not is_instance_valid(dropped_enemy), "Dropping a rock from above must defeat an enemy")
	assert(not is_instance_valid(dropped_rock))
	print("Rock impact tests passed: falling, dropped, thrown, gentle contact, and side push")
	arena.queue_free()
	await process_frame
	quit()
