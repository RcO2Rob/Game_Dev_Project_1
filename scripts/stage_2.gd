extends Node2D

const WIDTH := 15360.0
const ZONES := ["CORAL STEPS", "BUBBLE RIFTS", "REEF CROSSROADS", "SUNKEN RUINS", "LAST CROSSING"]
var checkpoint_x := 0.0
var elapsed := 0.0
var completed := false


func _ready() -> void:
	$Player/Camera2D.limit_right = int(WIDTH)
	for marker in $Checkpoints.get_children():
		marker.body_entered.connect(_checkpoint_entered.bind(marker))
	$PrecisionChasm.body_entered.connect(_chasm_entered)
	$ConchExit.body_entered.connect(_finish)
	$Completion/Panel/Retry.pressed.connect(func(): get_tree().reload_current_scene())


func _process(delta: float) -> void:
	if completed:
		return
	elapsed += delta
	var zone := clampi(int($Player.position.x / 3072.0), 0, 4)
	var progress := clampi(int($Player.position.x / (WIDTH - 200.0) * 100.0), 0, 99)
	$HUD/Panel/Title.text = "2 · %s · %d%%" % [ZONES[zone], progress]


func _checkpoint_entered(body: Node2D, marker: Area2D) -> void:
	if body != $Player or marker.position.x <= checkpoint_x or completed:
		return
	checkpoint_x = marker.position.x
	body._spawn_position = marker.position + Vector2(60, -32)
	body.current_health = body.max_health
	marker.get_node("Lamp").modulate = Color(0.45, 1.0, 0.65)
	marker.get_node("Label").text = "SAVED"


func _chasm_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()


func _finish(body: Node2D) -> void:
	if body != $Player or completed:
		return
	completed = true
	_show_completion.call_deferred(body)


func _show_completion(body: Node2D) -> void:
	# Freeze the completed level so hazards cannot hit the player behind the result.
	for child in get_children():
		if child is Node2D:
			child.process_mode = Node.PROCESS_MODE_DISABLED
	$Completion/Panel/Result.text = "STAGE 2 COMPLETE\n%d:%02d   |   COINS %d   |   DIAMONDS %d / 5\nStage 3 is not built yet." % [int(elapsed) / 60, int(elapsed) % 60, body.coin_count, body.diamond_count]
	$Completion.show()
	$Completion/Panel/Retry.grab_focus()
