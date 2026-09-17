extends Area2D

@export var value := 1

var _start_y := 0.0
var _time := 0.0
var _collected := false


func _ready() -> void:
	_start_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	position.y = _start_y + sin(_time * 2.1) * 6.0
	rotation = sin(_time * 1.7) * 0.08


func _on_body_entered(body: Node) -> void:
	if _collected or not body.has_method("add_diamond"):
		return
	_collected = true
	monitoring = false
	body.add_diamond(value)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_diamond_pickup()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
