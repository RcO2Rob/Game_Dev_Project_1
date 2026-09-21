extends Node2D

const WIDTH := 21504.0
const ZONES := ["TEMPLE GARDEN", "CORAL PASSAGE", "DRIFTING REEFS", "STEAM VAULT", "SILENT CHASM", "HEART OF THE SEA"]
var elapsed := 0.0
var checkpoint_x := 0.0
var completed := false

func _ready() -> void:
	$Player/Camera2D.limit_right = int(WIDTH)
	for marker in $Checkpoints.get_children():
		marker.body_entered.connect(_checkpoint.bind(marker))
	$ConchExit.body_entered.connect(_finish)
	$Completion/Panel/Replay.pressed.connect(func(): get_tree().reload_current_scene())

func _process(delta: float) -> void:
	if completed:
		return
	elapsed += delta
	var zone := clampi(int($Player.position.x / 3584.0), 0, 5)
	$HUD/Panel/Title.text = "3 · %s · %d%%" % [ZONES[zone], clampi(int($Player.position.x / (WIDTH - 200) * 100), 0, 99)]

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
	get_node("/root/EndShop").call_deferred("open_shop", $Player, "", Callable(self, "_show_result"))

func _show_result() -> void:
	for child in get_children():
		if child is Node2D:
			child.process_mode = Node.PROCESS_MODE_DISABLED
	$Completion/Panel/Result.text = "UNDERWATER WORLD — COMPLETE\n\nStage 3 time  %d:%02d\nCoins  %d     Diamonds remaining  %d\n\nYou reached the Heart of the Sea!" % [int(elapsed) / 60, int(elapsed) % 60, $Player.coin_count, $Player.diamond_count]
	$Completion.show()
	$Completion/Panel/Replay.grab_focus()
