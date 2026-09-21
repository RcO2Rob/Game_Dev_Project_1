extends StaticBody2D

@export_range(1, 20, 1) var coin_count := 7
@export_range(0.0, 1.0, 0.01) var low_diamond_drop_chance := 0.2
@export_range(0, 10, 1) var low_diamond_threshold := 2
@export_range(1, 5, 1) var diamond_drop_count := 2

const COIN_SCENE := preload("res://scenes/items/coin.tscn")
const DIAMOND_SCENE := preload("res://scenes/items/diamond.tscn")

var _broken := false
var _reward_roll_override := -1.0


func hit_by_weapon() -> void:
	if _broken:
		return
	_broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_barrel_break()
	var player := get_tree().get_first_node_in_group("player")
	var reward_roll := _reward_roll_override if _reward_roll_override >= 0.0 else randf()
	_reward_roll_override = -1.0
	if _should_drop_diamonds(player, reward_roll):
		_spawn_diamond_pair()
	else:
		_spawn_coin_pile()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property($Body, "scale", Vector2(1.35, 0.25), 0.2)
	tween.tween_property($Body, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(queue_free)


func _should_drop_diamonds(player: Node, reward_roll: float) -> bool:
	return is_instance_valid(player) and player.diamond_count <= low_diamond_threshold and reward_roll < low_diamond_drop_chance


func _spawn_diamond_pair() -> void:
	var center := (diamond_drop_count - 1) * 0.5
	for index in range(diamond_drop_count):
		var diamond := DIAMOND_SCENE.instantiate()
		get_parent().add_child(diamond)
		diamond.global_position = global_position + Vector2(0.0, -22.0)
		var horizontal_offset := (float(index) - center) * 40.0
		var target_x := global_position.x + horizontal_offset
		var target_y := _find_ground_y(target_x)
		diamond.launch_to(Vector2(target_x, target_y), 0.32 + index * 0.035)


func _spawn_coin_pile() -> void:
	var center := (coin_count - 1) * 0.5
	for index in range(coin_count):
		var coin := COIN_SCENE.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(0.0, -18.0)
		var horizontal_offset := (float(index) - center) * 21.0
		var target_x := global_position.x + horizontal_offset
		var target_y := _find_ground_y(target_x)
		coin.launch_to(Vector2(target_x, target_y), 0.3 + index * 0.018)


func _find_ground_y(world_x: float) -> float:
	var ray_start := Vector2(world_x, global_position.y - 55.0)
	var ray_end := Vector2(world_x, global_position.y + 220.0)
	var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return float(hit.position.y) - 18.0
	return global_position.y + 24.0
