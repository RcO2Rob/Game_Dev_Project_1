extends Area2D

@export var value := 1

var _start_y := 0.0
var _time := 0.0
var _collected := false
var _launching := false


func _ready() -> void:
	_start_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if _launching:
		return
	position.y = _start_y + sin(_time * 2.8) * 4.0
	rotation = sin(_time * 3.5) * 0.12


func launch_to(target_global_position: Vector2, duration: float = 0.24) -> void:
	_launching = true
	monitoring = false
	scale = Vector2(0.25, 0.25)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_global_position, duration)
	tween.tween_property(self, "scale", Vector2.ONE, duration * 0.75)
	await tween.finished
	_start_y = position.y
	_launching = false
	monitoring = true


func _on_body_entered(body: Node) -> void:
	if _collected or not body.has_method("add_coin"):
		return
	_collected = true
	set_deferred("monitoring", false)
	body.add_coin(value)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_coin_pickup()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.13)
	tween.tween_property(self, "modulate:a", 0.0, 0.13)
	tween.chain().tween_callback(queue_free)
