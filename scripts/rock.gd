extends RigidBody2D

const FALLING_HIT_SPEED := 75.0
const MIN_HEIGHT_ABOVE_ENEMY := 10.0

var _world_parent: Node
var _is_thrown := false


func _ready() -> void:
	_world_parent = get_parent()
	$EnemyHitbox.body_entered.connect(_on_enemy_hitbox_body_entered)
	$EnemyHitbox.set_deferred("monitoring", true)


func _physics_process(_delta: float) -> void:
	if freeze or _is_thrown or linear_velocity.y < FALLING_HIT_SPEED:
		return
	# The rock may already overlap an enemy before it reaches impact speed.
	for body in $EnemyHitbox.get_overlapping_bodies():
		_on_enemy_hitbox_body_entered(body)
		if is_queued_for_deletion():
			return


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
	$EnemyHitbox.set_deferred("monitoring", true)


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
	$EnemyHitbox.set_deferred("monitoring", true)


func _on_enemy_hitbox_body_entered(body: Node) -> void:
	if is_queued_for_deletion() or freeze or not body.is_in_group("enemy"):
		return
	var falling_onto_enemy: bool = linear_velocity.y >= FALLING_HIT_SPEED and global_position.y <= body.global_position.y - MIN_HEIGHT_ABOVE_ENEMY
	if not _is_thrown and not falling_onto_enemy:
		return
	_is_thrown = false
	$EnemyHitbox.set_deferred("monitoring", false)
	if body.has_method("hit_by_rock"):
		body.hit_by_rock()
	queue_free()
