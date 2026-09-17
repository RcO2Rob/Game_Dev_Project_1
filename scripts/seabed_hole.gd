extends Node2D

@export var min_bubble_delay := 2.8
@export var max_bubble_delay := 6.5

const BUBBLE_SCENE := preload("res://scenes/hazards/bubble.tscn")

@onready var bubble_timer: Timer = $BubbleTimer


func _ready() -> void:
	bubble_timer.timeout.connect(_spawn_bubble)
	$KillZone.body_entered.connect(_on_kill_zone_body_entered)
	_schedule_next_bubble()


func _schedule_next_bubble() -> void:
	var next_delay := randf_range(min_bubble_delay, max_bubble_delay)
	if randf() < 0.28:
		next_delay *= randf_range(1.45, 2.0)
	bubble_timer.start(next_delay)


func _spawn_bubble() -> void:
	var bubble := BUBBLE_SCENE.instantiate()
	bubble.position = global_position + Vector2(randf_range(-24.0, 24.0), -12.0)
	get_parent().call_deferred("add_child", bubble)
	_schedule_next_bubble()


func _on_kill_zone_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()
