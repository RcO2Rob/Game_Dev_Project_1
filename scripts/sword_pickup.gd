extends RigidBody2D

@export_enum("wood", "stone", "diamond") var weapon_kind := "wood"
@export_range(1, 50, 1) var durability := 5

var _pickup_delay := 0.0
var _collected := false


func _ready() -> void:
	_apply_weapon_visual()


func _physics_process(delta: float) -> void:
	_pickup_delay = maxf(_pickup_delay - delta, 0.0)


func set_pickup_delay(duration: float) -> void:
	_pickup_delay = maxf(duration, 0.0)


func launch(launch_velocity: Vector2) -> void:
	linear_velocity = launch_velocity
	angular_velocity = 0.0


func set_weapon_state(kind: String, remaining_durability: int) -> void:
	weapon_kind = kind if ["wood", "stone", "diamond"].has(kind) else "wood"
	var maximum: int = {"wood": 5, "stone": 15, "diamond": 50}[weapon_kind]
	durability = clampi(remaining_durability, 1, maximum)
	_apply_weapon_visual()


func _apply_weapon_visual() -> void:
	if not has_node("Blade"):
		return
	if weapon_kind == "wood":
		$Blade.color = Color("a96832")
		$BladeEdge.default_color = Color("e6b875")
		$Guard.color = Color("68401f")
		$Handle.color = Color("3f2819")
		$Pommel.color = Color("5a371f")
	elif weapon_kind == "stone":
		$Blade.color = Color(0.58, 0.66, 0.69, 1)
		$BladeEdge.default_color = Color(0.85, 0.94, 0.95, 0.9)
		$Guard.color = Color(0.2, 0.27, 0.29, 1)
		$Handle.color = Color(0.39, 0.22, 0.12, 1)
		$Pommel.color = Color(0.22, 0.29, 0.31, 1)
	else:
		$Blade.color = Color("48cbe6")
		$BladeEdge.default_color = Color("e3ffff")
		$Guard.color = Color("286d99")
		$Handle.color = Color("20516e")
		$Pommel.color = Color("9cefff")


func knock_away_and_disappear(launch_velocity: Vector2) -> void:
	# Damage loss is intentionally different from pressing N: this sword cannot
	# be recovered and fades shortly after it is knocked from the player's hand.
	_collected = true
	_pickup_delay = INF
	collision_layer = 0
	collision_mask = 1
	lock_rotation = false
	linear_velocity = launch_velocity
	angular_velocity = 8.0
	var tween := create_tween()
	tween.tween_interval(0.55)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.32)
	tween.tween_property(self, "scale", Vector2(0.35, 0.35), 0.32)
	tween.chain().tween_callback(queue_free)


func collect_by(body: Node) -> bool:
	if _collected or _pickup_delay > 0.0 or not body.has_method("equip_sword"):
		return false
	if not body.equip_sword(weapon_kind, durability):
		return false
	_collected = true
	collision_layer = 0
	collision_mask = 0
	freeze = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.45, 1.45), 0.13)
	tween.tween_property(self, "modulate:a", 0.0, 0.13)
	tween.chain().tween_callback(queue_free)
	return true
