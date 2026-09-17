extends StaticBody2D

@export_range(1, 20, 1) var coin_count := 7

const COIN_SCENE := preload("res://scenes/items/coin.tscn")

var _broken := false


func hit_by_weapon() -> void:
	if _broken:
		return
	_broken = true
	$CollisionShape2D.set_deferred("disabled", true)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_barrel_break()
	_spawn_coin_pile()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property($Body, "scale", Vector2(1.35, 0.25), 0.2)
	tween.tween_property($Body, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(queue_free)


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
