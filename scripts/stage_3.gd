extends Node2D

const WIDTH := 21504.0
const EXIT_MARGIN := 48.0
var elapsed := 0.0
var checkpoint_x := 0.0
var completed := false
var result_shown := false
var restart_button: Button

func _ready() -> void:
	$Player/Camera2D.limit_right = int(WIDTH)
	for marker in $Checkpoints.get_children():
		marker.body_entered.connect(_checkpoint.bind(marker))
	$OceanHeart.body_entered.connect(_finish)
	# Godot may keep the original scene-tree name after editing the button label.
	restart_button = get_node_or_null("Completion/Panel/Restart") as Button
	if restart_button == null:
		restart_button = $Completion/Panel/Replay
	restart_button.pressed.connect(_restart_adventure)

func _process(delta: float) -> void:
	if completed:
		if not result_shown and $Player.global_position.x >= WIDTH + EXIT_MARGIN:
			_show_result()
		return
	elapsed += delta

func _checkpoint(body: Node2D, marker: Area2D) -> void:
	if body != $Player or marker.position.x <= checkpoint_x or completed:
		return
	checkpoint_x = marker.position.x
	body._spawn_position = marker.position + Vector2(64, -32)
	body.current_health = body.max_health
	marker.get_node("Lamp").modulate = Color("71ffc8")
	marker.get_node("Label").text = "SAVED"

func _finish(body: Node2D) -> void:
	if body != $Player or completed:
		return
	completed = true
	$OceanHeart.set_deferred("monitoring", false)
	$OceanHeart.hide()
	$VictoryBanner.show()
	body.begin_victory_walk()
	get_node("/root/AudioManager").play_diamond_pickup()

func _show_result() -> void:
	if result_shown:
		return
	result_shown = true
	$VictoryBanner.hide()
	get_tree().paused = true
	$Completion/Panel/Result.text = "CONGRATULATIONS!\nYOU COMPLETED THE ADVENTURE\n\nYou found the Heart of the Sea.\nTime  %d:%02d\nCoins  %d     Diamonds  %d" % [int(elapsed) / 60, int(elapsed) % 60, $Player.coin_count, $Player.diamond_count]
	$Completion.show()
	restart_button.grab_focus()


func _restart_adventure() -> void:
	get_node("/root/RunState").pending.clear()
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/stage_1.tscn")
