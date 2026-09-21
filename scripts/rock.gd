extends RigidBody2D

var _world_parent: Node
var _is_thrown := false


func _ready() -> void:
	_world_parent = get_parent()
	$EnemyHitbox.body_entered.connect(_on_enemy_hitbox_body_entered)


func pick_up(holder: Node2D) -> void:
	_is_thrown = false
	$EnemyHitbox.set_deferred("monitoring", false)
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	reparent(holder)
	position = Vector2.ZERO
	rotation = 0.0


func throw_from_hand(throw_velocity: Vector2) -> void:
	var release_position := global_position
	reparent(_world_parent)
	global_position = release_position
	collision_layer = 2
	collision_mask = 1
	freeze = false
	linear_velocity = throw_velocity
	_is_thrown = throw_velocity.length() > 100.0
	$EnemyHitbox.set_deferred("monitoring", _is_thrown)


func drop_from_hand() -> void:
	throw_from_hand(Vector2.ZERO)


func capture_in_bubble() -> bool:
	if freeze:
		return false
	_is_thrown = false
	$EnemyHitbox.set_deferred("monitoring", false)
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	return true


func release_from_bubble() -> void:
	freeze = false
	collision_layer = 2
	collision_mask = 1
	linear_velocity = Vector2(0, 25)


func _on_enemy_hitbox_body_entered(body: Node) -> void:
	if not _is_thrown or not body.is_in_group("enemy"):
		return
	_is_thrown = false
	$EnemyHitbox.set_deferred("monitoring", false)
	if body.has_method("hit_by_rock"):
		body.hit_by_rock()
	queue_free()
